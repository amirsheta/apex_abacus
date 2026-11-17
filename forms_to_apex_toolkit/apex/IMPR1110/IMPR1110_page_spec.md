# IMPR1110 – APEX Page Specification (مواصفات صفحة APEX)

Target: APEX 21.2 / DB 12.1.0.2 · Theme: Universal Theme (RTL, Arabic) · Package: `PKG_IMPR1110`

> Build the page by hand (or through the App Builder) from this spec. **No APEX export was generated.**
> The app ID is unknown, so the registry uses placeholder **2000**. Change it to the real IMPR application ID.

## 1. Page properties
| Property | Value |
|---|---|
| Page number / alias | 1110 / `IMPR1110` |
| Name / title | `IMPR1110 - إضافة وتعديل بيانات مستورد` |
| Page mode | Normal |
| Page group | IMPR |
| Authorization | `IMPR1110_ACCESS` (maps to the Forms module security in SEC_LIB) |
| Comments | `Source: IMPR1110.fmb (IMPR1110_PROD_CENTRL)` |
| Deep-link params | `P1110_IMPR_NBR`, `P1110_PRSNL_IMPR`, `P1110_LETTER_NBR` (replace Forms PARAMETERs PRSNL_IMPR / LETTER_NBR) |
| Warn on unsaved changes | Yes |

## 2. Regions
| Seq | Static ID | Type | Source / notes |
|---|---|---|---|
| 10 | `TOOLBAR` | Buttons container (Breadcrumb bar) | buttons in section 6 |
| 20 | `IMPORTERS_QRY` | Interactive Report (collapsible "بحث") | SQL below. Replaces Enter-Query / Execute-Query. Link column → same page with `P1110_IMPR_NBR` |
| 30 | `IMPORTERS` | Static content with items (Form-like region; DML done by `page_dml`, **not** Automatic Row Processing, because Forms PRE/POST logic is in the package) | Comments: `Source: block IMPORTERS` |
| 40 | `IMPORTERS_ADDR` | Sub-region of IMPORTERS "العنوان والاتصال" | address / contact items |
| 50 | `IMPORTERS_OTHER` | Sub-region "بيانات أخرى" | IBAN, ID, flags, activity |

`IMPORTERS_QRY` SQL (block WHERE + ORDER BY + PRE-QUERY name search):
```sql
SELECT i.impr_nbr, i.arbc_impr_name, i.eng_impr_name, i.bus_id, i.bus_id_brnch,
       i.impr_type_cd, t.impr_type_name, i.bus_id_status
  FROM importers i
  LEFT JOIN impr_types t ON t.impr_type_cd = i.impr_type_cd
 WHERE i.port_cd = :AI_P_CURR_PORT_CD
   AND (:P1110_Q_NAME IS NULL
        OR i.impr_name_std LIKE pkg_impr1110.impr_name_std_qry(:P1110_Q_NAME))
 ORDER BY i.impr_nbr DESC
```
Search item `P1110_Q_NAME` (Text, label "بحث بالاسم"). IR searchable columns: IMPR_NBR, BUS_ID.

## 3. Items (region IMPORTERS). Each t_rec field is one page item `P1110_<FIELD>`
Hijri dates are **Text Field** with format `MI-MM-YYYY` (placeholder `dd-mm-yyyy هـ`). They are not Date Pickers because the column holds Hijri digits, as in Forms. Conversion happens in `to_hijri` / `fmt_hijri`.

| Seq | Item | Label | Type | LOV / list | Req | Server-side condition / notes |
|---|---|---|---|---|---|---|
| 10 | P1110_PORT_CD | رمز الجمرك | Popup LOV (display+return) | LOV_SD_PORTS | Y | default `&AI_P_CURR_PORT_CD.`, read-only |
| 20 | P1110_PORT_NAME | – | Display only | | | |
| 30 | P1110_HQ_IMPR_NBR | الرقم الموحد بالمصلحة | Display only | | | |
| 40 | P1110_IMPR_NBR | الرقم الجمركي | Display only (Primary key) | | | set from IR link / after CREATE |
| 50 | P1110_SUSPN_STATUS | حالة المستورد بالمصلحة | Display only | | | |
| 60 | P1110_STATUS_DESC | حالة المستورد بالوزارة | Display only | | | |
| 70 | P1110_IMPR_TYPE_CD | رمز النشاط التجاري | Popup LOV | LOV_IMPR_TYPE | Y | read-only when IMPR_NBR not null |
| 80 | P1110_IMPR_TYPE_NAME | – | Display only | | | |
| 90 | P1110_BUS_ID_TYPE_CD | نوع الرقم الإستدلالي | Select list (cascade P1110_IMPR_TYPE_CD) | LOV_BUS_ID_TYPE | Y | |
| 100 | P1110_BUS_ID_TYPE_NAME | – | Display only | | | |
| 110 | P1110_BUS_ID_EXPRD_DT | إنتهاء النشاط | Text (10) | | | mask MI-MM-YYYY |
| 120 | P1110_COMM_RGSTRTN_TYPE | نوع السجل التجاري | Radio group | LOV_COMM_RGSTRTN_TYPE | dyn. | |
| 130 | P1110_CITY_CODE_OF_ID | مصدر الرقم الإستدلالي | Popup LOV | LOV_CITIES (P1110_CTRY_CD_OF_ID) | dyn. | |
| 140 | P1110_ID_CITY_NAME | – | Display only | | | |
| 150 | P1110_BUS_ID | الرقم الإستدلالي | Text (15) | | Y | |
| 160 | P1110_BRNH_CITY_CD | مصدر الرقم الفرعي | Popup LOV | LOV_CITIES | dyn. | non-DB |
| 170 | P1110_BRNH_CITY_NAME | – | Display only | | | |
| 180 | P1110_BUS_ID_BRNCH | الرقم الفرعي | Text (10) | | | |
| 190 | P1110_CTRY_CD | دولة الرقم الإستدلالي | Popup LOV | LOV_COUNTRIES | Y | |
| 200 | P1110_CRTY_ARBC_NAME | – | Display only | | | |
| 210 | P1110_IMPR_EXPR_TYPE | النشاط الجمركي | Select list | static: `تصدير;0,إستيراد;1,إستيراد-تصدير;2` | Y | default 2 |
| 220 | P1110_ARBC_IMPR_NAME | الاسم العربي | Text (200) | | Y | |
| 230 | P1110_ENG_IMPR_NAME | الاسم الأجنبي | Text (200) | | | `dir="ltr"` |
| 240 | P1110_IMPR_CNTCT_NAME | الوكيل المفوض | Text | | | |
| 250 | P1110_BUS_ID_ISSUE_DT | تاريخ انشاء النشاط | Text (10) | | | mask MI-MM-YYYY |
| 260 | P1110_IMPR_NBR_PARENT | تابع الى | Popup LOV | LOV_IMPR | | |
| 270 | P1110_IMPR_NAME_PARENT | – | Display only | | | |
| 300 | P1110_ADD_CTRY_CD | دولة الإقامة | Popup LOV | LOV_COUNTRIES | Y | default 100, read-only |
| 310 | P1110_ADD_CRTY_ARBC_NAME | – | Display only | | | |
| 320 | P1110_CITY_CODE | المدينة | Popup LOV (cascade P1110_ADD_CTRY_CD) | LOV_CITIES_IMP | | |
| 330 | P1110_CITY_NAME | – | Display only | | | |
| 335 | P1110_WASL_CITY_NAME | المدينة (واصل) | Display only | | | |
| 340 | P1110_IMPR_ADDRESS | العنوان | Textarea (2000) | | | |
| 350 | P1110_IMPR_POB_NBR | صندوق بريد | Number (9) | | | |
| 360 | P1110_IMPR_ZIP_CD | رمز بريدي | Number (11) | | | |
| 370 | P1110_IMPR_TEL_NBR | تليفون | Text (15) | | | |
| 380 | P1110_IMPR_FAX_NBR | فاكس | Text (15) | | | |
| 390 | P1110_IMPR_TELEX_NBR | تلكس | Text (16) | | | |
| 400 | P1110_B_EMAIL | بريد إلكتروني | Text (Email subtype) | | | |
| 410 | P1110_B_MOBILE_NO | رقم الجوال | Text (Tel subtype) | | | |
| 500 | P1110_BANK_IBAN | رقم حساب آيبان | Text (34) | | | upper case |
| 510 | P1110_B_ID_NBR | رقم هوية المستورد | Text (10) | | | |
| 520 | P1110_CAR_AGENT_FLAG | وكيل سيارات؟ | Select list | static: `ليس وكيل سيارات;0,وكيل سيارات;1` | | default 0, read-only (Forms: SEL only) |
| 530 | P1110_EXPRESS_POST | بريد سريع | Select list | static: `لا;0,نعم;1,تم انشاءه بواسطة البريد السريع;2` | | default 0 |
| 540 | P1110_IMPR_ID_TYPE | نوع الاقامة | Display only | | | |
| 550 | P1110_ACTIVITY | نشاط المستورد | Textarea (1000) | | | |

Hidden items (value protected = No for items written by the package): P1110_BUS_ID_STATUS, P1110_IMPR_NAME_STD, P1110_LST_TRAN_DT, P1110_IMPD_STMT_NBR, P1110_IMPR_DATA_SRCE, P1110_EMAIL, P1110_MOBILE_NO, P1110_ID_NBR, P1110_CTRY_CD_OF_ID (default 100), P1110_ID_MINS_COMM_CD, P1110_EXPD_STMT_NBR, P1110_WVR_ENTRY_NBR, P1110_CUSTOMS_ENTERED, P1110_CREATION_FLAG (default 1), P1110_PRSNL_IMPR (default 0), P1110_LETTER_NBR, **P1110_UI_STATE** (JSON from `ui_state_json`), P1110_F1_NAME (Confirm text for F1).

## 4. Processes
| Point | Name | Code | Condition |
|---|---|---|---|
| Before Header | `IMPR1110.WHEN-NEW-FORM-INSTANCE` | `pkg_impr1110.page_wnfi;` | – |
| Before Header | `IMPORTERS.POST-QUERY / WHEN-CREATE-RECORD` | `pkg_impr1110.page_fetch;` | – (fetch when P1110_IMPR_NBR set, otherwise defaults) |
| Processing | `IMPORTERS.PRE/ON/POST-INSERT` | `pkg_impr1110.page_dml('CREATE');` | Request = CREATE |
| Processing | `IMPORTERS.PRE/ON/POST-UPDATE` | `pkg_impr1110.page_dml('SAVE');` | Request = SAVE |
| Processing | `IMPORTERS.KEY-DELREC` | `pkg_impr1110.page_dml('DELETE');` | Request = DELETE |
| Processing | `FUN.IMPR1110F3` | `pkg_impr1110.page_dml('IMPR1110F3');` | Request = IMPR1110F3 |
| Processing | `FUN.IMPR1110F1` | `:P1110_ARBC_IMPR_NAME := NVL(:P1110_F1_NAME, :P1110_ARBC_IMPR_NAME);` then SAVE | Request = IMPR1110F1 |
| Processing | Clear cache | Clear page 1110 | Request = CLEAR |
| After processing | Branch | page 1110, `P1110_IMPR_NBR=&P1110_IMPR_NBR.` | Success message `&AI_MSG.` / "تم الحفظ" |

The package does not COMMIT. APEX commits at the end of page processing, or rolls back on error. This matches Forms COMMIT_FORM behaviour.

## 5. Validations (on submit, one per WHEN-VALIDATE-ITEM)
Type: *PL/SQL Function Body returning Error Text*, error location *Inline with field*, "Always execute" = No. Run when Request in (CREATE, SAVE).

| Name | Code | Associated item |
|---|---|---|
| `IMPORTERS.IMPR_TYPE_CD.WHEN-VALIDATE-ITEM` | `RETURN pkg_impr1110.validate_item('IMPR_TYPE_CD');` | P1110_IMPR_TYPE_CD |
| `IMPORTERS.BUS_ID.WHEN-VALIDATE-ITEM` | `RETURN pkg_impr1110.validate_item('BUS_ID');` | P1110_BUS_ID |
| … one row per item: IMPR_NBR, BUS_ID_EXPRD_DT, COMM_RGSTRTN_TYPE, CITY_CODE_OF_ID, BRNH_CITY_CD, BUS_ID_BRNCH, CTRY_CD, ARBC_IMPR_NAME, ENG_IMPR_NAME, BUS_ID_ISSUE_DT, IMPR_NBR_PARENT, ADD_CTRY_CD, CITY_CODE, IMPR_TEL_NBR, B_EMAIL, B_MOBILE_NO, BANK_IBAN, B_ID_NBR | same pattern | P1110_<ITEM> |

Order the validations in the same sequence as the Forms navigation order (section 3).

## 6. Buttons (region TOOLBAR)
| Button | Label | Action | Server condition | Authorization (fun_allowed) |
|---|---|---|---|---|
| SAVE | حفظ | Submit, request SAVE | P1110_IMPR_NBR not null | – |
| CREATE | إضافة | Submit, request CREATE | P1110_IMPR_NBR null | – |
| DELETE | حذف | Submit, request DELETE + confirm "هل تريد حذف السجل؟" | P1110_IMPR_NBR not null | open question (delete policy) |
| QUERY | استعلام | expand IMPORTERS_QRY | – | – |
| CLEAR | جديد | Submit, request CLEAR | – | – |
| EXIT | خروج | Redirect to home / IMPR menu | – | – |
| IMPR1110F1 | تعديل الاسم من السجل التجاري | DA (section 7.3) | P1110_IMPR_NBR not null | `fun_allowed('IMPR1110F1')` |
| IMPR1110F3 | تعديل النشاط لمؤسسة/شركة | Submit + confirm | | `fun_allowed('IMPR1110F3')` |
| IMPR_MCI_SERVICE | خدمة وزارة التجارة | **MANUAL** (disabled until service is ready) | | `fun_allowed('IMPR_MCI_SERVICE')` |
| CREATE_BRKR_IMPR_AUTH | تفويض مخلص | **MANUAL** | | `fun_allowed('CREATE_BRKR_IMPR_AUTH')` |
| IMPR1115_GZT | IMPR1115 | Redirect to page of IMPR1115 (when migrated) | | `fun_allowed('IMPR1115_GZT')` |
| IMPR1110_MOB | تحديث الجوال | Redirect to mobile-update page (TODO) | | `fun_allowed('IMPR1110_MOB')` |

Function-button condition is a *PL/SQL Function Body returning Boolean*. Use one helper so every button reads the same page record:
```sql
RETURN pkg_impr1110.fun_allowed('IMPR1110F3', pkg_impr1110.get_page_rec, pkg_impr1110.get_ctx);
```

## 7. Dynamic Actions
1. **`IMPORTERS.UI_STATE` (Page Load + after refresh)**. Execute JavaScript:
   ```js
   (function(){
     var s = JSON.parse($v('P1110_UI_STATE') || '{"disabled":[],"required":[]}');
     $('#IMPORTERS :input[id^="P1110_"]').each(function(){ /* reset */ });
     s.disabled.forEach(function(i){ apex.item(i).disable(); });
     s.required.forEach(function(i){
       $('#'+i).prop('required', true);
       $('#'+i+'_CONTAINER').addClass('is-required');
     });
   })();
   ```
   (Replaces INTRFACE.Make_Field_Entrable / SET_ITEM_PROPERTY REQUIRED.) Disabled items are **not submitted**. The package re-reads them from the DB on SAVE, as Forms does for non-updatable items.
2. **`IMPORTERS.<ITEM>.WHEN-VALIDATE-ITEM` (Change on each item in section 5)**:
   - Execute Server-side Code.
     - Code: `:P1110_ERR := pkg_impr1110.validate_item('<ITEM>');`
     - Items to submit: all `P1110_*` items of IMPORTERS.
     - Items to return: the derived items (names, P1110_UI_STATE, P1110_IMPR_NAME_STD, P1110_BANK_IBAN…).
   - If `P1110_ERR` is not null: `apex.message.showErrors([{type:'error',location:'inline',pageItem:'P1110_<ITEM>',message:$v('P1110_ERR')}])`.
   - Then re-run DA 1.
   - Hidden helper item: `P1110_ERR`.
3. **`FUN.IMPR1110F1` (Click)**:
   - Server code `:P1110_F1_NAME := pkg_impr1110.f1_comm_name(pkg_impr1110.get_page_rec);`.
   - Confirm `' سيتم تعديل الإسم إلى ( ' || name || ' )'`.
   - Submit request IMPR1110F1.
4. **Confirm 9-120**: the warning/confirm messages raised as `pkg_forms_compat.message` show through `apex_application.g_print_success_message` / Notification region.
5. **`IMPORTERS.COMM_RGSTRTN_TYPE.WHEN-LIST-CHANGED`**: same as #2 with `COMM_RGSTRTN_TYPE`.

## 8. Shared components needed
- LOVs: see `plsql/IMPR1110/impr1110_shared_lovs.sql` (LOV_SD_PORTS, LOV_IMPR_TYPE, LOV_BUS_ID_TYPE, LOV_COUNTRIES, LOV_COUNTRIES_GULF, LOV_CITIES, LOV_CITIES_IMP, LOV_IMPR, LOV_COMM_RGSTRTN_TYPE).
- Application items: AI_P_CURR_PORT_CD, AI_P_USER_ID, AI_P_WS_ID, AI_P_CLASS_CD, AI_P_USER_TYPE, AI_ALLOW_MCI, AI_ALLOW_MOI, AI_CHK_DUP_BUSID, AI_CHK_IMP_TYP, AI_FLAGUPDATE, AI_FUNS_IMP, AI_IMPR_NAME_B, AI_IMPR_NBR_B, AI_LETTER_DT, AI_LETTER_NBR, AI_OLD_IMPR_TYPE_CD, AI_OLD_PORT_CD, AI_PORT_CD, AI_SUPP_TITLE_CD (session state protection: Restricted, not settable from browser).
- Text Messages, which `pkg_forms_compat.apex_error_handler` maps by constraint name: IMP_PK, IMP_BUSID_UK = `هذا السجل مدخل سابقاً - أعد ادخال البيانات`. IMP_ITIDT_FK, IMP_CTRY_FK, IMP_BUS_ID_CITY_FK, IMP_ADD_CITY_FK need texts copied from the Forms ON-ERROR trigger (TODO-VERIFY).
- Error handling function (Application → Error handling): `pkg_forms_compat.apex_error_handler`.
- Authorization scheme `IMPR1110_ACCESS`.
