# تحويل الشاشة IMPR1110 – إضافة وتعديل بيانات مستورد (تطبيق IMPR)

> ⚠️ **الحالة:** كل الملفات مكتوبة فقط، **ولم يُترجم أي منها (compile) أو يُختبر على قاعدة بيانات أو على APEX**. لم تتوفر لدينا قاعدة 12.1.0.2 ولا بيئة APEX 21.2. يجب ترجمة الحزمة ومراجعة الأخطاء أولًا.

## 1. خريطة الملفات
| الملف | المحتوى |
|---|---|
| `analysis/IMPR1110/IMPR1110_inventory.md` | جرد الشاشة: الكتل والحقول والتريجرات والمكتبات والقوائم والوظائف والرسائل، وتحديد ما يُحوَّل وما يُحذف |
| `plsql/IMPR1110/pkg_impr1110_spec.sql` | مواصفة الحزمة `PKG_IMPR1110`، وأسماء الإجراءات فيها بأسماء تريجرات Forms نفسها |
| `plsql/IMPR1110/pkg_impr1110_body.sql` | جسم الحزمة: كل منطق WHEN-VALIDATE-ITEM و PRE/POST-INSERT/UPDATE/DELETE و POST-QUERY والوظائف |
| `plsql/IMPR1110/impr1110_shared_lovs.sql` | استعلامات القوائم المشتركة (LOVs) |
| `apex/IMPR1110/IMPR1110_page_spec.md` | مواصفات بناء الصفحة 1110: المناطق والحقول والتحققات والعمليات والأزرار و Dynamic Actions |
| `registry/IMPR1110_registry.sql` | تسجيل الشاشة وخريطة كائناتها في جداول متابعة الترحيل |
| `tests/IMPR1110/test_pkg_impr1110.sql` | اختبارات utPLSQL للمنطق الذي لا يعدّل البيانات |
| `tests/IMPR1110/uat_IMPR1110_ar.md` | قائمة اختبار القبول للمستخدمين (25 حالة) |

## 2. ترتيب التثبيت
1. `plsql_templates/pkg_forms_compat.sql`، إن لم يكن مثبتًا من قبل.
2. `scripts/create_migration_registry.sql` ثم `registry/IMPR1110_registry.sql`.
3. تأكد من وجود الحزم الخارجية وصلاحياتها في مخطط التطبيق: GNRL, STR_DB, HIJDATE_DB, ACTIVITY, DB_JOURNAL, IMPR, IMPR_CENTRAL، إضافة إلى المرادفات (synonyms) أو صلاحيات `EXECUTE`.
4. `pkg_impr1110_spec.sql` ثم `pkg_impr1110_body.sql`، ثم أصلح أخطاء الترجمة.
5. أنشئ عناصر التطبيق `AI_*` والقوائم من `impr1110_shared_lovs.sql` ورسائل النص (Text Messages).
6. ابنِ الصفحة 1110 حسب `IMPR1110_page_spec.md`.
7. شغّل `test_pkg_impr1110`، ثم نفّذ قائمة UAT بالمقارنة مع Forms.

## 3. قرارات التصميم الأساسية
- الكتلة `IMPORTERS` صارت تقريرًا تفاعليًا للبحث (بديل Enter/Execute Query)، ومعه منطقة نموذج لسجل واحد.
- الحفظ لا يعتمد Automatic Row Processing. يتم عبر `page_dml` حتى تبقى تريجرات PRE/POST بترتيب Forms نفسه. **أُزيلت كل أوامر COMMIT**، فـ APEX يحفظ في نهاية المعالجة أو يتراجع عند الخطأ.
- تمكين الحقول وتعطيلها وجعلها إلزامية (INTRFACE.Make_Field_Entrable) يتم بدالة `ui_state_json`، وهي تُرجع JSON يطبّقه Dynamic Action. استخدمنا APEX_JSON لأن قاعدة 12.1 لا تدعم JSON_OBJECT_T.
- `:PARAMETER.P_*` و `:GLOBAL.*` صارت عناصر تطبيق `AI_*`.
- التواريخ الهجرية بقيت حقول نص بقناع `MI-MM-YYYY` كما في Forms.
- الكتل TITLE و EDI_MSG و LSIDE و TOOLBAR والمكتبات الخاصة بواجهة Windows حُذفت، وحلّت محلها مكونات APEX الأصلية.

## 4. أسئلة مفتوحة (تحتاج قرارًا قبل البناء)
1. **`IMPR_CENTRAL.CREATE_UNI_IMPR_NEBRAS`**: هل يُدرج سجل IMPORTERS بنفسه؟ الحزمة الحالية تُدرج السجل بـ INSERT عادي ثم تستدعي الإجراء في POST-INSERT. إذا كان الإجراء يُدرج السجل أيضًا فسيحدث تكرار.
2. **مكان الحزم الخارجية** (STR/STR_DB, HIJDATE_DB, INTRFACE, GNRL, ACTIVITY, DB_JOURNAL, IMPR_UTILITIES, MCISERVICE في LIB_USR) وصلاحياتها على مخطط APEX.
3. **سياسة الحذف:** الكتلة معرّفة بـ DeleteAllowed=false، لكن تريجر KEY-DELREC يحذف. هل نُبقي الحذف، وما الصلاحية المطلوبة له؟
4. **التاريخ الهجري:** هل العمود من نوع DATE ويحمل أرقامًا هجرية؟ وهل القناع `MI-MM-YYYY` مقصود أم خطأ قديم، علمًا أن MI تعني الدقائق وليس اليوم؟
5. **شاشات القوائم المستدعاة** (LOV Forms) وشاشة تحديث الجوال `LOV_UPDATE_IMPR_MOBILE`: ما الصفحات البديلة لها؟
6. **مسار خطاب الدعم (SUPPORT_ENTRY / LETTER_NBR)**: من أين يأتي رقم الخطاب في APEX؟
7. **خدمة وزارة التجارة (GET_CR_DATA)** و**تفويض المخلص (CREATE_BRKR_IMPR_AUTH)**: صُنّفتا MANUAL ولم تُحوَّلا بعد.
8. **استدعاءات IMPR1115** (IMPR1115_GZT) وF4 وSF6: ستُربط عند تحويل تلك الشاشات.
9. **رقم التطبيق (app_id):** استخدمنا 2000 مؤقتًا في السجل والاختبارات.
10. **رسائل TODO-VERIFY:** في جسم الحزمة 19 موضعًا لرسائل أُعيدت صياغتها ولم تُنقل حرفيًا. يجب مطابقتها مع نصوص Forms الأصلية، ومثلها نصوص قيود FK في ON-ERROR.
11. **قيمة 0 في نوع السجل التجاري:** تظهر في القائمة باسم "فرعي" إلى جانب القيمة 2. هل هي بيانات قديمة فقط؟

## 5. الخطوة التالية
بعد ترجمة الحزمة وبناء الصفحة وتنفيذ UAT، غيّر الحالة في `MIG_FORM_REGISTRY` من DESIGN إلى BUILD ثم TEST، وانتقل إلى الشاشة التالية في تطبيق IMPR.
