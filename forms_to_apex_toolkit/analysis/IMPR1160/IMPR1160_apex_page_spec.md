# IMPR1160 – APEX 21.2 Page Specification (step 03)

- **Form:** IMPR1160 (title `IMPR1160_ND_CNTRL`) – استثناء المستوردين الافراد للسيارات
- **Package:** `IMPR1160` version 001 (`plsql/IMPR1160/`), logic report `analysis/IMPR1160/IMPR1160_logic_extraction.md`;
  shared `LOV_APX` 004 (`plsql_templates/lov_apx.sql`)
- **Standard:** f345 (`apex/Reference/f345.sql`), CLAUDE.md §4a–§4d, `docs/f345_reference_standard.md`
- **Design data:** `scripts/gen_apex_impr1160.py` (ITEMS, PROCESSES, DAS …); this file is rendered from it by
  `work/IMPR1160/step03/build_spec.py`, the traceability (§14) and `registry/IMPR1160_registry.sql` by `build_trace.py`.
- **Produced:** 2026-11-25 by Claude Code.

## 0. Decisions that shape the page

| # | Decision | Reason / source |
|---|---|---|
| 1 | Main page **1160** `IMPR1160`, search page **116001** `IMPR1160_SEARCH` (modal 1800×800), page group `IMPR` (IMPR1110 export) | f345 standard §3 |
| 2 | Block IMPR_CAR_EXCEPTION = native **Form** region on the table, key **ROWID** (= `P0_PAGE_PK`, URL-safe from the search page), operations `i:u:d` | PRE-QUERY `MAKE_BLOCK_FULL_OPERATION(TRUE, TRUE, TRUE)` overrides the Designer Update / Delete = false |
| 3 | New record (`P0_PAGE_PK` null): IMPR_NBR, DCLTN_TYPE, DCLTN_NBR, DCLTN_DT, AWARD_*, NO_OF_CARS, STATUS enterable. Queried record: **only STATUS** (read-only condition `:P0_PAGE_PK IS NOT NULL` on every other item) | Update Allowed = false on every item; PRE-QUERY / POST-QUERY enable STATUS |
| 4 | The suspension check ("هذا المستورد موقوف") runs in the DA `IMPR_NBR KEY-NEXT-ITEM` (on change) **and** the validation `IMPR_NBR VALIDATION` (CREATE) | WHEN-VALIDATE-ITEM never raises; KEY-NEXT-ITEM holds the check (inventory §14 #1, §15 #1 to confirm) |
| 5 | LOV forms → Popup LOVs: `LOV_IMPR_P` (LOV_APX.IMPORTERS, port of the user, type 4, business id type 5) and `LOV_IMPR_DCLTN` (LOV_APX.LOV_IMPR_DCLTN, by DCLTN_TYPE and IMPR_NBR). The DAs on change do what the form did after the LOV (name; declaration date, ISN, cars) | PU CALL_IMPR_LOV / CALL_IMPR_DCLTN_LOV |
| 6 | Hijri dates as text in `FORMS_APX.HIJRI_DATE_FORMAT` (Application Setting, default YYYY-MM-MI), class `hijri-date-default` (f345 Hijri picker) | IMPR1110 / IMPR1120 decision; Forms mask MI-MM-RRRR |
| 7 | Defaults of the new record (PORT_CD / PORT_NAME, EXPTN_START_DT) by process `WHEN-NEW-FORM-INSTANCE` **after** `Initialize form` | WHEN-NEW-FORM-INSTANCE; Initialize form would clear them |
| 8 | Constraint errors → Text Messages named after the constraints (APEX error handler of FORMS_APX) | block ON-ERROR / CGTE$CHECK_CONSTRAINT_VIO |
| 9 | No functions (EXEC_FUNS / ADJ_FUNS are empty); no JavaScript action (Set Focus / Refresh / Clear are native) | CLAUDE.md §4c |

## 1. Page type decision per block

| Block | Forms | APEX |
|---|---|---|
| IMPR_CAR_EXCEPTION | base table, one record shown, insert (+ STATUS update, delete after a query) | Form region on page 1160 + search IG on page 116001 |
| TITLE, EDI_MSG, LSIDE, TOOLBAR | OLB frame | f345 page template, hero region, page 0 toolbar, FUNCS drawer |

## 2. Pages

| Page | Name / alias | Mode | Template / class | Source |
|---|---|---|---|---|
| 1160 | IMPR1160 / IMPR1160 | Normal, protection C, Warn on Unsaved Changes = Yes | Zatca-Minimal_No_Navigation, `zf` | window CGSO$WINDOW_1, canvas CG$PAGE_1 |
| 116001 | IMPR1160_SEARCH / IMPR1160-SEARCH | Modal 1800×800, protection C | theme dialog, `zf` | Enter-Query / Execute-Query (page 0 SEARCH) |

## 3. Regions

| Page | Region (static id) | Type / template | Source |
|---|---|---|---|
| 1160 | الهيدر (`IMPR_CAR_EXCEPTION_HERO`) | Static HTML, Blank with Attributes, `cg-hero`, title `&P1160_HERO_TITLE.` | OLB block TITLE |
| 1160 | استثناء المستوردين الافراد للسيارات (`IMPR_CAR_EXCEPTION`) | Form, table `IMPR_CAR_EXCEPTION`, ROWID, `i:u:d`, Interactive Report template, `zatca-forms cg-form cg-card` | block IMPR_CAR_EXCEPTION |
| 116001 | بحث (`IMPR_CAR_EXCEPTION_SEARCH_CRITERIA`) | Static, text `P116001_SEARCH` + buttons SEARCH / CLEAR | Enter-Query criteria |
| 116001 | استثناءات السيارات (`IMPR_CAR_EXCEPTION_SEARCH`) | read-only IG, lazy loading, every row on opening (search text optional, user request 2026-11-26); link `EXCPT_ISN` → page 1160 with `P0_PAGE_PK = ROW_ID` | block query (no WHERE clause: all ports) + POST-QUERY names |

## 4. Items (page 1160)

Canvas order (rows by Y, then X). Read only = `:P0_PAGE_PK IS NOT NULL` unless noted.

| Item | Type | Label | Column | Required | LOV / mask | Read only | Source |
|---|---|---|---|---|---|---|---|
| `P1160_PORT_CD` | DISPLAY_ONLY | رقم المنفذ | PORT_CD | – | – | always | IMPR_CAR_EXCEPTION.PORT_CD (CGSO$CHAR_ARB_DO, Required, never enterable; WHEN-NEW-FORM-INSTANCE := P_CURR_PORT_CD; LOV CGFK$IMPR_CAR_EXCEPTION_PORT_C / button PORT_CD2 dropped) |
| `P1160_PORT_NAME` | DISPLAY_ONLY | – | – | – | – | always | IMPR_CAR_EXCEPTION.PORT_NAME (non-database; WHEN-NEW-FORM-INSTANCE / POST-QUERY) |
| `P1160_EXCPT_ISN` | DISPLAY_ONLY | مسلسل الإستثناء | IMPR_CAR_EXPTN_ISN | – | – | always | IMPR_CAR_EXCEPTION.EXCPT_ISN (column IMPR_CAR_EXPTN_ISN, CGSO$NUMBER_ARB_WT_DO; PRE-INSERT sequence) |
| `P1160_IMPR_NBR` | POPUP_LOV | رقم المستورد | IMPR_NBR | Yes | LOV_IMPR_P | record | IMPR_CAR_EXCEPTION.IMPR_NBR (CGSO$NUMBER_MD Required, Update Allowed = false; KEY-LISTVAL / IMPR_BUT -> CALL_IMPR_LOV: LOV form LOV_IMPR_P) |
| `P1160_IMPR_NAME` | DISPLAY_ONLY | – | – | – | – | always | IMPR_CAR_EXCEPTION.IMPR_NAME (non-database; IMPR_NBR KEY-NEXT-ITEM / POST-QUERY) |
| `P1160_DCLTN_TYPE` | SELECT_LIST | نوع البيان | DCLTN_TYPE | Yes | LOV_DCL_STA_FLAG | record | IMPR_CAR_EXCEPTION.DCLTN_TYPE (List Item, Required, default 1, Update Allowed = false; CGDV$POPULATE_DYNAMIC_LISTS CG_REF_CODES DCL_STA_FLAG) |
| `P1160_DCLTN_NBR` | POPUP_LOV | رقم البيان | – | – | LOV_IMPR_DCLTN | record | IMPR_CAR_EXCEPTION.DCLTN_NBR (non-database, enterable on a new record (WHEN-NEW-FORM-INSTANCE); KEY-LISTVAL / DCLTN_LOV -> CALL_IMPR_DCLTN_LOV: LOV form LOV_IMPR_DCLTN) |
| `P1160_DCLTN_DT` | TEXT_FIELD | تاريخ البيان | – | – | Hijri text | record | IMPR_CAR_EXCEPTION.DCLTN_DT (non-database Hijri date MI-MM-RRRR, enterable on a new record; DCLTN_NBR POST-CHANGE / POST-QUERY; KEY-NEXT-ITEM and WHEN-VALIDATE-ITEM are NULL;) |
| `P1160_AWARD_NBR` | TEXT_FIELD | رقم المراسلة | EXPTN_AWARD_NBR | – | – | record | IMPR_CAR_EXCEPTION.AWARD_NBR (column EXPTN_AWARD_NBR, Update Allowed = false) |
| `P1160_AWARD_DATE` | TEXT_FIELD | تاريخ المراسلة | EXPTN_AWARD_DATE | – | &P1160_HIJRI_DATE_FORMAT. | record | IMPR_CAR_EXCEPTION.AWARD_DATE (column EXPTN_AWARD_DATE, CGSO$HDATE_ARB Hijri MI-MM-RRRR; KEY-F4 / KEY-LISTVAL Hijri picker -> hijri-date-default) |
| `P1160_NO_OF_CARS` | NUMBER_FIELD | عدد السيارات المستثناة | NO_OF_CARS | – | – | record | IMPR_CAR_EXCEPTION.NO_OF_CARS (Insert Allowed = true, Update Allowed = false (CGSO$CHAR_ARB_DO); DCLTN_NBR POST-CHANGE) |
| `P1160_STATUS` | SELECT_LIST | حالة السجل | STATUS | – | LOV_REC_STATUS | no | IMPR_CAR_EXCEPTION.STATUS (List Item 1 / 0, CG_REF_CODES REC_STATUS; PRE-QUERY / POST-QUERY SET_ITEM_PROPERTY UPDATE_ALLOWED TRUE: the one item a queried record can change) |
| `P1160_AWARD_REMARKS` | TEXTAREA | ملاحظات | EXPTN_AWARD_REMARKS | – | – | record | IMPR_CAR_EXCEPTION.AWARD_REMARKS (column EXPTN_AWARD_REMARKS, multi-line, Update Allowed = false) |

Not displayed:

| Item | Type | Column | Mask | Source |
|---|---|---|---|---|
| `P1160_ROW_ID` | HIDDEN | ROWID | – | IMPR_CAR_EXCEPTION ROWID (Form region primary key, = P0_PAGE_PK) |
| `P1160_ENTRY_DT` | DISPLAY_ONLY | ENTRY_DT | YYYY/MM/DD HH24:MI:SS | IMPR_CAR_EXCEPTION.ENTRY_DT (CGSO$DATETIME, not displayed; PRE-INSERT SYSDATE) |
| `P1160_EXPTN_START_DT` | DISPLAY_ONLY | EXPTN_START_DT | &P1160_HIJRI_DATE_FORMAT. | IMPR_CAR_EXCEPTION.EXPTN_START_DT (Hijri, not displayed; WHEN-NEW-FORM-INSTANCE current Hijri date) |
| `P1160_EXPTN_END_DT` | DISPLAY_ONLY | EXPTN_END_DT | &P1160_HIJRI_DATE_FORMAT. | IMPR_CAR_EXCEPTION.EXPTN_END_DT (Hijri, not displayed, never set by the form) |
| `P1160_DCLTN_ISN` | HIDDEN | DCLTN_ISN | – | IMPR_CAR_EXCEPTION.DCLTN_ISN (not displayed; DCLTN_NBR POST-CHANGE, PRE-INSERT) |
| `P1160_STATS_ISN` | HIDDEN | STATS_ISN | – | IMPR_CAR_EXCEPTION.STATS_ISN (not displayed; DCLTN_NBR POST-CHANGE, PRE-INSERT) |
| `P1160_MODULE_ID` | HIDDEN | – | – | f345 Page Functions: P<page>_MODULE_ID |
| `P1160_HIJRI_DATE_FORMAT` | HIDDEN | – | – | FORMS_APX.HIJRI_DATE_FORMAT (format mask of the Hijri dates) |
| `P1160_HERO_TITLE` | HIDDEN | – | – | f345 hero title (FORMS_APX.HEADER_TITLE) |

## 5. Buttons

Page 1160 has none: CREATE / SAVE / DELETE / SEARCH / CLEAR / BACK come from the page 0 toolbar (f345). Page 116001:
SEARCH and CLEAR (Text with Icon, `cg-b-search` / `cg-b-clear`, Defined by Dynamic Action).

## 6. LOVs (*PL/SQL Function Body returning SQL Query*, R / D)

| LOV | Function body | Popup columns | Source |
|---|---|---|---|
| `LOV_DCL_STA_FLAG` | `return LOV_APX.REFERENCE_CODES(P_DOMAIN => 'DCL_STA_FLAG');` | Select List | IMPR_CAR_EXCEPTION.DCLTN_TYPE list (CGDV$POPULATE_DYNAMIC_LISTS, CG_REF_CODES domain DCL_STA_FLAG; XML values 1, 2, 3) |
| `LOV_IMPR_P` | `return LOV_APX.IMPORTERS(P_PORT_ITEM => 'P_CURR_PORT_CD', P_IMPR_TYPE_CD => '4', P_BUS_ID_TYPE_CD => '5');` | D (رقم مستورد), ARBC_IMPR_NAME (اسم المستورد), BUS_ID (رقم إستدلالي), BUS_ID_BRNCH (فرع), IMPR_TEL_NBR (تليفون) | PU CALL_IMPR_LOV -> LOV form LOV_IMPR_P (PORT_CD = P_CURR_PORT_CD, IMPR_TYPE_CD 4, BUS_ID_TYPE_CD 5) |
| `LOV_IMPR_DCLTN` | `return LOV_APX.LOV_IMPR_DCLTN(P_DCLTN_TYPE_ITEM => 'P1160_DCLTN_TYPE', P_IMPR_NBR_ITEM => 'P1160_IMPR_NBR');` | D (رقم البيان), DCLTN_DT (تاريخ البيان) | PU CALL_IMPR_DCLTN_LOV -> LOV form LOV_IMPR_DCLTN (declarations / statistical declarations of the importer) |
| `LOV_REC_STATUS` | reused (IMPR1140 export) | Select List | STATUS list (CG_REF_CODES REC_STATUS) |

## 7. Validations (page 1160)

| Validation | Item | Code | Condition | Source |
|---|---|---|---|---|
| IMPR_NBR VALIDATION | `P1160_IMPR_NBR` | `RETURN IMPR1160.IMPR_NBR_VALIDATION(P_PORT_CD => :P1160_PORT_CD, P_IMPR_NBR => :P1160_IMPR_NBR);` | `:REQUEST = 'CREATE'` | IMPR_CAR_EXCEPTION.IMPR_NBR.WHEN-VALIDATE-ITEM + KEY-NEXT-ITEM (suspension check) |
| AWARD_NBR VALIDATION | `P1160_AWARD_NBR` | `RETURN IMPR1160.AWARD_NBR_VALIDATION(P_AWARD_NBR => :P1160_AWARD_NBR);` | `:REQUEST = 'CREATE'` | IMPR_CAR_EXCEPTION.AWARD_NBR.WHEN-VALIDATE-ITEM |
| AWARD_DATE VALIDATION | `P1160_AWARD_DATE` | `RETURN FORMS_APX.HIJRI_DATE_ERROR(:P1160_AWARD_DATE);` | `:REQUEST = 'CREATE'` | IMPR_CAR_EXCEPTION.AWARD_DATE.WHEN-VALIDATE-ITEM (HIJDATE.VALID_HIJ_DATE) |
| NO_OF_CARS VALIDATION | `P1160_NO_OF_CARS` | `RETURN IMPR1160.NO_OF_CARS_VALIDATION(P_NO_OF_CARS => :P1160_NO_OF_CARS);` | `:REQUEST = 'CREATE'` | IMPR_CAR_EXCEPTION.NO_OF_CARS.WHEN-VALIDATE-ITEM |
| (native) Value Required | `P1160_IMPR_NBR`, `P1160_DCLTN_TYPE` | – | – | Required = true (CGSO$NUMBER_MD / list item) |

## 8. Processes (page 1160, f345 standard §6)

| Point | Seq | Name | Code | Condition | Source |
|---|---|---|---|---|---|
| BEFORE_HEADER | 10 | New | – | NEVER | f345 session setup copied from AGR1100 (condition Never) / standard 6 |
| BEFORE_HEADER | 20 | P0_PAGE_PK CHECK | `IMPR1160.P0_PAGE_PK_CHECK(P_PAGE_PK => :P0_PAGE_PK);` | – | f345 key (ROWID of IMPR_CAR_EXCEPTION, URL-safe from page 116001) |
| BEFORE_HEADER | 40 | PARAMETERS | `:P1160_MODULE_ID := FORMS_APX.GET_MODULE_ID(P_MODULE_ID => :P1160_MODULE_ID, FORM_NAME => 'IMPR1160');` | – | f345 module id of the Page Functions list |
| BEFORE_HEADER | 70 | P0_PAGE_PK | `:P1160_ROW_ID := :P0_PAGE_PK;` | – | f345 (key = ROWID) |
| BEFORE_HEADER | 80 | Initialize form | NATIVE_FORM_INIT | – | block IMPR_CAR_EXCEPTION fetch |
| BEFORE_HEADER | 82 | POST-QUERY | `IMPR1160.POST_QUERY(P_IMPR_NBR => :P1160_IMPR_NBR, P_DCLTN_TYPE => :P1160_DCLTN_TYPE, P_DCLTN_ISN => :P1160_DCLTN_ISN, P_STATS_ISN => :P1160_STATS_ISN, P_CURR_PORT_CD => :P_CURR_PORT_CD, P_IMPR_NAME => :P1160_IMPR_NAME, P_PORT_NAME => :P1160_PORT_NAME, P_DCLTN_NBR => :P1160_DCLTN_NBR, P_DCLTN_DT => :P1160_DCLTN_DT);` | :P1160_ROW_ID IS NOT NULL | IMPR_CAR_EXCEPTION.POST-QUERY |
| BEFORE_HEADER | 84 | WHEN-NEW-FORM-INSTANCE | `IMPR1160.WHEN_NEW_FORM_INSTANCE(P_CURR_PORT_CD => :P_CURR_PORT_CD, P_PORT_CD => :P1160_PORT_CD, P_PORT_NAME => :P1160_PORT_NAME, P_EXPTN_START_DT => :P1160_EXPTN_START_DT);` | :P1160_ROW_ID IS NULL | FORM.WHEN-NEW-FORM-INSTANCE (defaults of the new record: PORT_CD, PORT_NAME, EXPTN_START_DT; after Initialize form, which would clear them) |
| BEFORE_HEADER | 100 | HEADER TITLE | `FORMS_APX.HEADER_TITLE(P_MODULE_ID => :P1160_MODULE_ID, P_HERO_TITLE => :P1160_HERO_TITLE, DEFAULT_TITLE => 'استثناء المستوردين الافراد للسيارات');` | – | f345 hero title (OLB block TITLE) |
| AFTER_SUBMIT | 10 | PRE-INSERT | `IMPR1160.PRE_INSERT(P_DCLTN_TYPE => :P1160_DCLTN_TYPE, P_DCLTN_NBR => :P1160_DCLTN_NBR, P_DCLTN_DT => :P1160_DCLTN_DT, P_IMPR_NBR => :P1160_IMPR_NBR, P_CURR_PORT_CD => :P_CURR_PORT_CD, P_EXCPT_ISN => :P1160_EXCPT_ISN, P_ENTRY_DT => :P1160_ENTRY_DT, P_DCLTN_ISN => :P1160_DCLTN_ISN, P_STATS_ISN => :P1160_STATS_ISN);` | :P0_PAGE_PK IS NULL AND :REQUEST = 'CREATE' | IMPR_CAR_EXCEPTION.PRE-INSERT (+ CGUI$GET_UNIQUE_ID_MODIFIED) |
| AFTER_SUBMIT | 20 | PRE-UPDATE | `IMPR1160.PRE_UPDATE(P_PORT_CD => :P1160_PORT_CD, P_EXCPT_ISN => :P1160_EXCPT_ISN);` | :P0_PAGE_PK IS NOT NULL AND :REQUEST = 'SAVE' | IMPR_CAR_EXCEPTION.PRE-UPDATE |
| AFTER_SUBMIT | 40 | Process form | NATIVE_FORM_DML | :REQUEST IN ('CREATE', 'SAVE') | block IMPR_CAR_EXCEPTION DML – success "تم الحفظ بنجاح" |
| AFTER_SUBMIT | 41 | Process form - DELETE | NATIVE_FORM_DML | :REQUEST = 'DELETE' | block IMPR_CAR_EXCEPTION DML (delete: NIB.KEY_DELREC after PRE-QUERY MAKE_BLOCK_FULL_OPERATION) – success "تم الحذف بنجاح" |
| AFTER_SUBMIT | 80 | P0_PAGE_PK AFTER INSERT | `:P0_PAGE_PK := :P1160_ROW_ID;` | :REQUEST = 'CREATE' | f345 |
| AFTER_SUBMIT | 85 | P0_PAGE_PK AFTER DELETE | `:P0_PAGE_PK := NULL;` | :REQUEST = 'DELETE' | f345 |

## 9. Computations

| Item | Point | Expression | Source |
|---|---|---|---|
| `P1160_HIJRI_DATE_FORMAT` | BEFORE_HEADER | `FORMS_APX.HIJRI_DATE_FORMAT` | Hijri date format from one place: Application Setting HIJRI_DATE_FORMAT (Forms mask MI-MM-RRRR) |

## 10. Dynamic Actions (page 1160)

| DA | Event | Element | Condition | Actions | Source |
|---|---|---|---|---|---|
| IMPR_NBR KEY-NEXT-ITEM | change | P1160_IMPR_NBR | NOT_NULL | FOS `IMPR1160.IMPR_NBR_KEY_NEXT_ITEM(P_PORT_CD => :P1160_PORT_CD, P_IMPR_NBR => :P1160_IMPR_NBR, P_IMPR_NAME => :P1160_IMPR_NAME);` (submit P1160_PORT_CD, P1160_IMPR_NBR, return P1160_IMPR_NAME); NATIVE_SET_FOCUS P1160_DCLTN_TYPE | IMPR_CAR_EXCEPTION.IMPR_NBR.KEY-NEXT-ITEM (name of the importer, suspension check, go_item DCLTN_TYPE); also after the Popup LOV LOV_IMPR_P (CALL_IMPR_LOV) |
| DCLTN_NBR POST-CHANGE | change | P1160_DCLTN_NBR | NOT_NULL | FOS `IMPR1160.DCLTN_NBR_POST_CHANGE(P_DCLTN_TYPE => :P1160_DCLTN_TYPE, P_DCLTN_NBR => :P1160_DCLTN_NBR, P_IMPR_NBR => :P1160_IMPR_NBR, P_CURR_PORT_CD => :P_CURR_PORT_CD, P_DCLTN_ISN => :P1160_DCLTN_ISN, P_STATS_ISN => :P1160_STATS_ISN, P_DCLTN_DT => :P1160_DCLTN_DT, P_NO_OF_CARS => :P1160_NO_OF_CARS);` (submit P1160_DCLTN_TYPE, P1160_DCLTN_NBR, P1160_IMPR_NBR, return P1160_DCLTN_ISN, P1160_STATS_ISN, P1160_DCLTN_DT, P1160_NO_OF_CARS); NATIVE_SET_FOCUS P1160_AWARD_NBR | IMPR_CAR_EXCEPTION.DCLTN_NBR.POST-CHANGE (+ CALL_IMPR_DCLTN_LOV GO_ITEM AWARD_NBR) |
| AWARD_NBR WHEN-VALIDATE-ITEM | change | P1160_AWARD_NBR | NOT_NULL | FOS `FORMS_APX.CHECK_ERROR(IMPR1160.AWARD_NBR_VALIDATION(P_AWARD_NBR => :P1160_AWARD_NBR));` (submit P1160_AWARD_NBR, return –) | IMPR_CAR_EXCEPTION.AWARD_NBR.WHEN-VALIDATE-ITEM |
| AWARD_DATE WHEN-VALIDATE-ITEM | change | P1160_AWARD_DATE | NOT_NULL | FOS `FORMS_APX.CHECK_ERROR(FORMS_APX.HIJRI_DATE_ERROR(:P1160_AWARD_DATE));` (submit P1160_AWARD_DATE, return –) | IMPR_CAR_EXCEPTION.AWARD_DATE.WHEN-VALIDATE-ITEM (HIJDATE.VALID_HIJ_DATE) |
| NO_OF_CARS WHEN-VALIDATE-ITEM | change | P1160_NO_OF_CARS | NOT_NULL | FOS `FORMS_APX.CHECK_ERROR(IMPR1160.NO_OF_CARS_VALIDATION(P_NO_OF_CARS => :P1160_NO_OF_CARS));` (submit P1160_NO_OF_CARS, return –) | IMPR_CAR_EXCEPTION.NO_OF_CARS.WHEN-VALIDATE-ITEM |

JavaScript: none on page 1160; page 116001 only the f345 `this.browserEvent.which === 13` condition of SEARCH KEY-ENTER.

## 11. Alerts and messages

| Text Message / text | Where | Source |
|---|---|---|
| `ICE_PK` = "Row exists already with same رقم المنفذ,مسلسل الإستثناء" | APEX error handler (constraint) | CGTE$CHECK_CONSTRAINT_VIO (ORA-00001) |
| `ICE_SD_FK` = "This رقم المنفذ does not exist" | APEX error handler (constraint) | IMPR_CAR_EXCEPTION.ON-ERROR (ORA-02291) |
| `ICE_SDP_FK` = "This رقم المنفذ does not exist" | APEX error handler (constraint) | IMPR_CAR_EXCEPTION.ON-ERROR (ORA-02291) |
| `ICE_IMP_FK` = "This رقم المستورد does not exist" | APEX error handler (constraint) | IMPR_CAR_EXCEPTION.ON-ERROR (ORA-02291) |
| `ICE_DCLTN_FK` = "This رقم المنفذ does not exist" | APEX error handler (constraint) | IMPR_CAR_EXCEPTION.ON-ERROR (ORA-02291; label as in Forms) |
| "هذا المستورد موقوف " | `IMPR_NBR_VALIDATION`, `IMPR_NBR_KEY_NEXT_ITEM` | IMPR_NBR KEY-NEXT-ITEM |
| "رقم البيان او  تاريخه الذى تم ادخاله غير معرف فى انظمة البيان " | `DCLTN_NBR_POST_CHANGE`, `PRE_INSERT` | POST-CHANGE / PRE-INSERT |
| "لقد تم استثناء هذا البيان من قبل " | `PRE_INSERT` | PRE-INSERT |
| "لا يمكن ادخال رقم قرار اقل من او يساوي صفر" | `AWARD_NBR_VALIDATION` | AWARD_NBR WHEN-VALIDATE-ITEM |
| "لا يمكن ادخال عدد سيارات اقل من او يساوي صفر" | `NO_OF_CARS_VALIDATION` | NO_OF_CARS WHEN-VALIDATE-ITEM |
| "غير مسموح بتعديل الحالة من غير فعال الى فعال" | `PRE_UPDATE` | PRE-UPDATE |
| NIB.KEY_DELREC "هل أنت متأكد من عملية الحذف" | page 0 DELETE confirmation (f345 `ASK_DLG`) | KEY-DELREC |

## 12. Branches and navigation

| Branch | Point | Target | Source |
|---|---|---|---|
| IMPR1160 - stay in the form | After Processing | page 1160 with the success message (`P0_PAGE_PK` kept; after DELETE it is null = new record) | Forms stays on the record after COMMIT |
| search link | – | `f?p=&APP_ID.:1160:&SESSION.::&DEBUG.:1160:P0_PAGE_PK:&ROW_ID.` (ROW_ID URL-safe) | Execute-Query |

## 13. Shared components

Reused from f345: theme 42 / ZATCA Forms, page 0 (`P0_ACTIONS`, `P0_PAGE_PK`, `P0_SEARCH_URL`, `ASK_DLG`), application items
`P_CURR_PORT_CD`, `SSO_APP_USER`, `SYS_ANAME`, app process `SCREEN ENTRY RESET`, `APP_ERROR_HANDLER`, plug-in
`COM.FOS.EXECUTE_PLSQL_CODE`, the Hijri picker class `hijri-date-default`. From IMPR1110: page group `IMPR`, Application Setting
`HIJRI_DATE_FORMAT`. From IMPR1140: `LOV_REC_STATUS`. New: LOVs `LOV_DCL_STA_FLAG`, `LOV_IMPR_P`, `LOV_IMPR_DCLTN`; Text Messages
`ICE_PK`, `ICE_SD_FK`, `ICE_SDP_FK`, `ICE_IMP_FK`, `ICE_DCLTN_FK`. No application item, authorization scheme or page 0 change.

Security (CLAUDE.md §8): page access by the application's privileges; Forms used the table grants (ORA-01031 messages of ON-ERROR)
and the REMOVE toolbar button (TMPLT) – the privilege administrators decide who may delete.

## 14. Traceability (every Forms object)

442 objects: DROPPED 373, MAPPED 69.

| # | Type | Forms object | APEX component | Page | Package member | Status | Notes |
|---|---|---|---|---|---|---|---|
| 1 | BLOCK | `TITLE` | REGION | IMPR_CAR_EXCEPTION_HERO | 1160 | - | MAPPED | OLB title bar -> f345 hero region (FORMS_APX.HEADER_TITLE) |
| 2 | BLOCK | `EDI_MSG` | - | - | - | - | DROPPED | OLB EDI message ticker - dropped (timers, IMPR1110 decision 2026-11-19) |
| 3 | BLOCK | `LSIDE` | REGION | FUNCS (page 0 drawer) | 0 | - | MAPPED | OLB side function menu -> page 0 FUNCS, f345 list Page Functions |
| 4 | BLOCK | `TOOLBAR` | REGION | P0_ACTIONS (page 0 toolbar, f345) | 0 | - | MAPPED | OLB toolbar -> f345 page 0 toolbar |
| 5 | BLOCK | `IMPR_CAR_EXCEPTION` | REGION | IMPR_CAR_EXCEPTION (Form, i:u:d, key ROWID) | 1160 | - | MAPPED | PRE-QUERY MAKE_BLOCK_FULL_OPERATION(TRUE, TRUE, TRUE): queried record STATUS update + delete |
| 6 | ITEM | `TITLE.CGSO$CHECK_BOX_U` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 7 | ITEM | `TITLE.CGSO$CHAR_ARB_ED` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 8 | ITEM | `TITLE.CGSO$CHAR_ARB_DO_MLINE` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 9 | ITEM | `TITLE.CGSO$CHAR_ARB_ORA_LOV` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 10 | ITEM | `TITLE.CGSO$CHAR_ARB_DO_ENB_Y` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 11 | ITEM | `TITLE.CGSO$CHAR_ARB_MLINE` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 12 | ITEM | `TITLE.CGSO$CHAR_ARB` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 13 | ITEM | `TITLE.CGSO$CHAR_ARB_DO` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 14 | ITEM | `TITLE.SCREEN_NAME` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 15 | ITEM | `TITLE.USER_NAME` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 16 | ITEM | `TITLE.SYSTEM_DATE` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 17 | ITEM | `TITLE.VERSION` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 18 | ITEM | `EDI_MSG.EDI_MSG_TXT` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 19 | ITEM | `EDI_MSG.EDI_MSG_LOVE_BUT` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 20 | ITEM | `LSIDE.FN1` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 21 | ITEM | `LSIDE.FN50` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 22 | ITEM | `LSIDE.FN2` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 23 | ITEM | `LSIDE.FN49` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 24 | ITEM | `LSIDE.FN3` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 25 | ITEM | `LSIDE.FN48` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 26 | ITEM | `LSIDE.FN4` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 27 | ITEM | `LSIDE.FN47` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 28 | ITEM | `LSIDE.FN5` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 29 | ITEM | `LSIDE.FN46` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 30 | ITEM | `LSIDE.FN6` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 31 | ITEM | `LSIDE.FN45` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 32 | ITEM | `LSIDE.FN7` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 33 | ITEM | `LSIDE.FN44` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 34 | ITEM | `LSIDE.FN8` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 35 | ITEM | `LSIDE.FN43` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 36 | ITEM | `LSIDE.FN9` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 37 | ITEM | `LSIDE.FN42` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 38 | ITEM | `LSIDE.FN10` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 39 | ITEM | `LSIDE.FN41` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 40 | ITEM | `LSIDE.FN11` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 41 | ITEM | `LSIDE.FN40` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 42 | ITEM | `LSIDE.FN12` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 43 | ITEM | `LSIDE.FN39` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 44 | ITEM | `LSIDE.FN13` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 45 | ITEM | `LSIDE.FN38` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 46 | ITEM | `LSIDE.FN14` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 47 | ITEM | `LSIDE.FN37` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 48 | ITEM | `LSIDE.FN15` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 49 | ITEM | `LSIDE.FN36` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 50 | ITEM | `LSIDE.FN16` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 51 | ITEM | `LSIDE.FN17` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 52 | ITEM | `LSIDE.FN34` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 53 | ITEM | `LSIDE.FN35` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 54 | ITEM | `LSIDE.FN18` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 55 | ITEM | `LSIDE.FN33` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 56 | ITEM | `LSIDE.FN19` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 57 | ITEM | `LSIDE.FN32` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 58 | ITEM | `LSIDE.FN20` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 59 | ITEM | `LSIDE.FN31` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 60 | ITEM | `LSIDE.FN21` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 61 | ITEM | `LSIDE.FN30` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 62 | ITEM | `LSIDE.FN22` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 63 | ITEM | `LSIDE.FN29` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 64 | ITEM | `LSIDE.FN23` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 65 | ITEM | `LSIDE.FN28` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 66 | ITEM | `LSIDE.FN24` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 67 | ITEM | `LSIDE.FN27` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 68 | ITEM | `LSIDE.FN25` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 69 | ITEM | `LSIDE.FN26` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 70 | ITEM | `TOOLBAR.DUMMY` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 71 | ITEM | `TOOLBAR.SAVE` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 72 | ITEM | `TOOLBAR.CLEAR_ALL` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 73 | ITEM | `TOOLBAR.EXIT` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 74 | ITEM | `TOOLBAR.EXIT1` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 75 | ITEM | `TOOLBAR.ENTER` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 76 | ITEM | `TOOLBAR.EXECUTE` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 77 | ITEM | `TOOLBAR.REMOVE` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 78 | ITEM | `TOOLBAR.LIST_VALUE` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 79 | ITEM | `TOOLBAR.HELP` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 80 | ITEM | `TOOLBAR.LAST_REC` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 81 | ITEM | `TOOLBAR.RE_ENTER_QUERY` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 82 | ITEM | `TOOLBAR.FIRST_REC` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 83 | ITEM | `TOOLBAR.PAGE_UP` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 84 | ITEM | `TOOLBAR.PAGE_DOWN` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 85 | ITEM | `TOOLBAR.FUN_BUT` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 86 | ITEM | `IMPR_CAR_EXCEPTION.ENTRY_DT` | PAGE_ITEM | P1160_ENTRY_DT | 1160 | - | MAPPED | not displayed |
| 87 | ITEM | `IMPR_CAR_EXCEPTION.PORT_CD` | PAGE_ITEM | P1160_PORT_CD | 1160 | - | MAPPED | spec section 4 |
| 88 | ITEM | `IMPR_CAR_EXCEPTION.PORT_CD2` | - | - | - | - | DROPPED | LOV button of PORT_CD, an item that is never enterable |
| 89 | ITEM | `IMPR_CAR_EXCEPTION.PORT_NAME` | PAGE_ITEM | P1160_PORT_NAME | 1160 | - | MAPPED | spec section 4 |
| 90 | ITEM | `IMPR_CAR_EXCEPTION.EXCPT_ISN` | PAGE_ITEM | P1160_EXCPT_ISN | 1160 | - | MAPPED | spec section 4 |
| 91 | ITEM | `IMPR_CAR_EXCEPTION.IMPR_NBR` | PAGE_ITEM | P1160_IMPR_NBR | 1160 | - | MAPPED | spec section 4 |
| 92 | ITEM | `IMPR_CAR_EXCEPTION.IMPR_BUT` | - | - | - | - | DROPPED | LOV button -> the Popup LOV button of P1160_IMPR_NBR |
| 93 | ITEM | `IMPR_CAR_EXCEPTION.IMPR_NAME` | PAGE_ITEM | P1160_IMPR_NAME | 1160 | - | MAPPED | spec section 4 |
| 94 | ITEM | `IMPR_CAR_EXCEPTION.DCLTN_TYPE` | PAGE_ITEM | P1160_DCLTN_TYPE | 1160 | - | MAPPED | spec section 4 |
| 95 | ITEM | `IMPR_CAR_EXCEPTION.DCLTN_NBR` | PAGE_ITEM | P1160_DCLTN_NBR | 1160 | - | MAPPED | spec section 4 |
| 96 | ITEM | `IMPR_CAR_EXCEPTION.DCLTN_LOV` | - | - | - | - | DROPPED | LOV button -> the Popup LOV button of P1160_DCLTN_NBR |
| 97 | ITEM | `IMPR_CAR_EXCEPTION.DCLTN_DT` | PAGE_ITEM | P1160_DCLTN_DT | 1160 | - | MAPPED | spec section 4 |
| 98 | ITEM | `IMPR_CAR_EXCEPTION.AWARD_NBR` | PAGE_ITEM | P1160_AWARD_NBR | 1160 | - | MAPPED | spec section 4 |
| 99 | ITEM | `IMPR_CAR_EXCEPTION.AWARD_DATE` | PAGE_ITEM | P1160_AWARD_DATE | 1160 | - | MAPPED | spec section 4 |
| 100 | ITEM | `IMPR_CAR_EXCEPTION.NO_OF_CARS` | PAGE_ITEM | P1160_NO_OF_CARS | 1160 | - | MAPPED | spec section 4 |
| 101 | ITEM | `IMPR_CAR_EXCEPTION.STATUS` | PAGE_ITEM | P1160_STATUS | 1160 | - | MAPPED | spec section 4 |
| 102 | ITEM | `IMPR_CAR_EXCEPTION.DCLTN_ISN` | PAGE_ITEM | P1160_DCLTN_ISN | 1160 | - | MAPPED | not displayed |
| 103 | ITEM | `IMPR_CAR_EXCEPTION.STATS_ISN` | PAGE_ITEM | P1160_STATS_ISN | 1160 | - | MAPPED | not displayed |
| 104 | ITEM | `IMPR_CAR_EXCEPTION.EXPTN_START_DT` | PAGE_ITEM | P1160_EXPTN_START_DT | 1160 | - | MAPPED | not displayed |
| 105 | ITEM | `IMPR_CAR_EXCEPTION.EXPTN_END_DT` | PAGE_ITEM | P1160_EXPTN_END_DT | 1160 | - | MAPPED | not displayed |
| 106 | ITEM | `IMPR_CAR_EXCEPTION.AWARD_REMARKS` | PAGE_ITEM | P1160_AWARD_REMARKS | 1160 | - | MAPPED | spec section 4 |
| 107 | TRIGGER | `FORM.KEY-EDIT` | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| 108 | TRIGGER | `FORM.KEY-DUPREC` | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| 109 | TRIGGER | `FORM.PRE-FORM` | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| 110 | TRIGGER | `FORM.WHEN-NEW-FORM-INSTANCE` | PROCESS | WHEN-NEW-FORM-INSTANCE | 1160 | IMPR1160.WHEN_NEW_FORM_INSTANCE | MAPPED | defaults of a new record (PORT_CD, PORT_NAME, EXPTN_START_DT); NIB / versions dropped |
| 111 | TRIGGER | `FORM.WHEN-WINDOW-ACTIVATED` | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| 112 | TRIGGER | `FORM.KEY-ENTQRY` | PAGE | IMPR1160_SEARCH | 116001 | - | MAPPED | NIB.KEY_ENTQRY -> page 0 SEARCH |
| 113 | TRIGGER | `FORM.ON-ERROR` | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| 114 | TRIGGER | `FORM.ON-MESSAGE` | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| 115 | TRIGGER | `FORM.KEY-CLRBLK` | BUTTON | CLEAR (page 0 toolbar) | 0 | - | MAPPED | NIB.KEY_CLRBLK |
| 116 | TRIGGER | `FORM.KEY-DELREC` | PROCESS | Process form - DELETE | 1160 | - | MAPPED | NIB.KEY_DELREC (confirmation) -> page 0 DELETE |
| 117 | TRIGGER | `FORM.KEY-F5` | PROCESS | Process form | 1160 | - | MAPPED | NIB.KEY_F5 (commit) -> page 0 CREATE / SAVE |
| 118 | TRIGGER | `FORM.KEY-F4` | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| 119 | TRIGGER | `FORM.KEY-NXTREC` | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| 120 | TRIGGER | `FORM.KEY-PRVREC` | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| 121 | TRIGGER | `FORM.KEY-DOWN` | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| 122 | TRIGGER | `FORM.KEY-UP` | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| 123 | TRIGGER | `FORM.KEY-SCRUP` | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| 124 | TRIGGER | `FORM.KEY-SCRDOWN` | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| 125 | TRIGGER | `FORM.KEY-PRINT` | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| 126 | TRIGGER | `FORM.KEY-EXIT` | BUTTON | BACK (page 0 toolbar) | 0 | - | MAPPED | NIB.KEY_EXIT |
| 127 | TRIGGER | `FORM.WHEN-MOUSE-DOWN` | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| 128 | TRIGGER | `FORM.KEY-EXEQRY` | PAGE | IMPR1160_SEARCH | 116001 | - | MAPPED | NIB.KEY_EXEQRY -> search grid |
| 129 | TRIGGER | `FORM.KEY-F9` | REGION | FUNCS (page 0) | 0 | - | MAPPED | functions menu; ADJ_FUNS is empty |
| 130 | TRIGGER | `FORM.WHEN-TIMER-EXPIRED` | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| 131 | TRIGGER | `FORM.KEY-HELP` | - | - | - | - | DROPPED | Designer help file (empty CG$HP_HFILE) |
| 132 | TRIGGER | `FORM.KEY-CLRFRM` | BUTTON | CLEAR (page 0 toolbar) | 0 | - | MAPPED | clear_form + CG$WHEN_NEW_FORM_INSTANCE (lists: shared LOVs) |
| 133 | TRIGGER | `TITLE.CGSO$CHAR_ARB_ED.KEY-LISTVAL` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 134 | TRIGGER | `TITLE.CGSO$CHAR_ARB_DO_ENB_Y.KEY-LISTVAL` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 135 | TRIGGER | `TITLE.CGSO$CHAR_ARB_MLINE.KEY-LISTVAL` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 136 | TRIGGER | `TITLE.CGSO$CHAR_ARB.KEY-LISTVAL` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 137 | TRIGGER | `TITLE.CGSO$CHAR_ARB_DO.KEY-LISTVAL` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 138 | TRIGGER | `TITLE.SYSTEM_DATE.WHEN-VALIDATE-ITEM` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 139 | TRIGGER | `EDI_MSG.EDI_MSG_LOVE_BUT.WHEN-BUTTON-PRESSED` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 140 | TRIGGER | `LSIDE.FN1.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 141 | TRIGGER | `LSIDE.FN1.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 142 | TRIGGER | `LSIDE.FN1.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 143 | TRIGGER | `LSIDE.FN50.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 144 | TRIGGER | `LSIDE.FN50.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 145 | TRIGGER | `LSIDE.FN50.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 146 | TRIGGER | `LSIDE.FN2.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 147 | TRIGGER | `LSIDE.FN2.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 148 | TRIGGER | `LSIDE.FN2.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 149 | TRIGGER | `LSIDE.FN49.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 150 | TRIGGER | `LSIDE.FN49.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 151 | TRIGGER | `LSIDE.FN49.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 152 | TRIGGER | `LSIDE.FN3.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 153 | TRIGGER | `LSIDE.FN3.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 154 | TRIGGER | `LSIDE.FN3.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 155 | TRIGGER | `LSIDE.FN48.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 156 | TRIGGER | `LSIDE.FN48.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 157 | TRIGGER | `LSIDE.FN48.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 158 | TRIGGER | `LSIDE.FN4.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 159 | TRIGGER | `LSIDE.FN4.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 160 | TRIGGER | `LSIDE.FN4.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 161 | TRIGGER | `LSIDE.FN47.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 162 | TRIGGER | `LSIDE.FN47.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 163 | TRIGGER | `LSIDE.FN47.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 164 | TRIGGER | `LSIDE.FN5.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 165 | TRIGGER | `LSIDE.FN5.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 166 | TRIGGER | `LSIDE.FN5.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 167 | TRIGGER | `LSIDE.FN46.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 168 | TRIGGER | `LSIDE.FN46.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 169 | TRIGGER | `LSIDE.FN46.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 170 | TRIGGER | `LSIDE.FN6.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 171 | TRIGGER | `LSIDE.FN6.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 172 | TRIGGER | `LSIDE.FN6.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 173 | TRIGGER | `LSIDE.FN45.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 174 | TRIGGER | `LSIDE.FN45.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 175 | TRIGGER | `LSIDE.FN45.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 176 | TRIGGER | `LSIDE.FN7.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 177 | TRIGGER | `LSIDE.FN7.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 178 | TRIGGER | `LSIDE.FN7.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 179 | TRIGGER | `LSIDE.FN44.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 180 | TRIGGER | `LSIDE.FN44.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 181 | TRIGGER | `LSIDE.FN44.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 182 | TRIGGER | `LSIDE.FN8.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 183 | TRIGGER | `LSIDE.FN8.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 184 | TRIGGER | `LSIDE.FN8.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 185 | TRIGGER | `LSIDE.FN43.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 186 | TRIGGER | `LSIDE.FN43.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 187 | TRIGGER | `LSIDE.FN43.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 188 | TRIGGER | `LSIDE.FN9.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 189 | TRIGGER | `LSIDE.FN9.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 190 | TRIGGER | `LSIDE.FN9.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 191 | TRIGGER | `LSIDE.FN42.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 192 | TRIGGER | `LSIDE.FN42.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 193 | TRIGGER | `LSIDE.FN42.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 194 | TRIGGER | `LSIDE.FN10.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 195 | TRIGGER | `LSIDE.FN10.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 196 | TRIGGER | `LSIDE.FN10.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 197 | TRIGGER | `LSIDE.FN41.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 198 | TRIGGER | `LSIDE.FN41.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 199 | TRIGGER | `LSIDE.FN41.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 200 | TRIGGER | `LSIDE.FN11.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 201 | TRIGGER | `LSIDE.FN11.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 202 | TRIGGER | `LSIDE.FN11.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 203 | TRIGGER | `LSIDE.FN40.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 204 | TRIGGER | `LSIDE.FN40.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 205 | TRIGGER | `LSIDE.FN40.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 206 | TRIGGER | `LSIDE.FN12.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 207 | TRIGGER | `LSIDE.FN12.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 208 | TRIGGER | `LSIDE.FN12.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 209 | TRIGGER | `LSIDE.FN39.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 210 | TRIGGER | `LSIDE.FN39.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 211 | TRIGGER | `LSIDE.FN39.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 212 | TRIGGER | `LSIDE.FN13.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 213 | TRIGGER | `LSIDE.FN13.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 214 | TRIGGER | `LSIDE.FN13.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 215 | TRIGGER | `LSIDE.FN38.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 216 | TRIGGER | `LSIDE.FN38.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 217 | TRIGGER | `LSIDE.FN38.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 218 | TRIGGER | `LSIDE.FN14.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 219 | TRIGGER | `LSIDE.FN14.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 220 | TRIGGER | `LSIDE.FN14.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 221 | TRIGGER | `LSIDE.FN37.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 222 | TRIGGER | `LSIDE.FN37.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 223 | TRIGGER | `LSIDE.FN37.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 224 | TRIGGER | `LSIDE.FN15.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 225 | TRIGGER | `LSIDE.FN15.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 226 | TRIGGER | `LSIDE.FN15.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 227 | TRIGGER | `LSIDE.FN36.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 228 | TRIGGER | `LSIDE.FN36.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 229 | TRIGGER | `LSIDE.FN36.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 230 | TRIGGER | `LSIDE.FN16.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 231 | TRIGGER | `LSIDE.FN16.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 232 | TRIGGER | `LSIDE.FN16.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 233 | TRIGGER | `LSIDE.FN17.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 234 | TRIGGER | `LSIDE.FN17.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 235 | TRIGGER | `LSIDE.FN17.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 236 | TRIGGER | `LSIDE.FN34.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 237 | TRIGGER | `LSIDE.FN34.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 238 | TRIGGER | `LSIDE.FN34.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 239 | TRIGGER | `LSIDE.FN35.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 240 | TRIGGER | `LSIDE.FN35.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 241 | TRIGGER | `LSIDE.FN35.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 242 | TRIGGER | `LSIDE.FN18.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 243 | TRIGGER | `LSIDE.FN18.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 244 | TRIGGER | `LSIDE.FN18.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 245 | TRIGGER | `LSIDE.FN33.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 246 | TRIGGER | `LSIDE.FN33.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 247 | TRIGGER | `LSIDE.FN33.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 248 | TRIGGER | `LSIDE.FN19.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 249 | TRIGGER | `LSIDE.FN19.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 250 | TRIGGER | `LSIDE.FN19.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 251 | TRIGGER | `LSIDE.FN32.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 252 | TRIGGER | `LSIDE.FN32.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 253 | TRIGGER | `LSIDE.FN32.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 254 | TRIGGER | `LSIDE.FN20.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 255 | TRIGGER | `LSIDE.FN20.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 256 | TRIGGER | `LSIDE.FN20.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 257 | TRIGGER | `LSIDE.FN31.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 258 | TRIGGER | `LSIDE.FN31.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 259 | TRIGGER | `LSIDE.FN31.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 260 | TRIGGER | `LSIDE.FN21.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 261 | TRIGGER | `LSIDE.FN21.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 262 | TRIGGER | `LSIDE.FN21.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 263 | TRIGGER | `LSIDE.FN30.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 264 | TRIGGER | `LSIDE.FN30.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 265 | TRIGGER | `LSIDE.FN30.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 266 | TRIGGER | `LSIDE.FN22.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 267 | TRIGGER | `LSIDE.FN22.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 268 | TRIGGER | `LSIDE.FN22.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 269 | TRIGGER | `LSIDE.FN29.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 270 | TRIGGER | `LSIDE.FN29.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 271 | TRIGGER | `LSIDE.FN29.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 272 | TRIGGER | `LSIDE.FN23.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 273 | TRIGGER | `LSIDE.FN23.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 274 | TRIGGER | `LSIDE.FN23.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 275 | TRIGGER | `LSIDE.FN28.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 276 | TRIGGER | `LSIDE.FN28.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 277 | TRIGGER | `LSIDE.FN28.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 278 | TRIGGER | `LSIDE.FN24.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 279 | TRIGGER | `LSIDE.FN24.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 280 | TRIGGER | `LSIDE.FN24.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 281 | TRIGGER | `LSIDE.FN27.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 282 | TRIGGER | `LSIDE.FN27.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 283 | TRIGGER | `LSIDE.FN27.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 284 | TRIGGER | `LSIDE.FN25.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 285 | TRIGGER | `LSIDE.FN25.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 286 | TRIGGER | `LSIDE.FN25.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 287 | TRIGGER | `LSIDE.FN26.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 288 | TRIGGER | `LSIDE.FN26.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 289 | TRIGGER | `LSIDE.FN26.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 290 | TRIGGER | `TOOLBAR.KEY-DOWN` | - | - | - | - | DROPPED | OLB frame block trigger (toolbar keys) |
| 291 | TRIGGER | `TOOLBAR.KEY-UP` | - | - | - | - | DROPPED | OLB frame block trigger (toolbar keys) |
| 292 | TRIGGER | `TOOLBAR.KEY-NEXT-ITEM` | - | - | - | - | DROPPED | OLB frame block trigger (toolbar keys) |
| 293 | TRIGGER | `TOOLBAR.SAVE.WHEN-BUTTON-PRESSED` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 294 | TRIGGER | `TOOLBAR.CLEAR_ALL.WHEN-BUTTON-PRESSED` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 295 | TRIGGER | `TOOLBAR.EXIT.WHEN-BUTTON-PRESSED` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 296 | TRIGGER | `TOOLBAR.EXIT1.WHEN-BUTTON-PRESSED` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 297 | TRIGGER | `TOOLBAR.ENTER.WHEN-BUTTON-PRESSED` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 298 | TRIGGER | `TOOLBAR.EXECUTE.WHEN-BUTTON-PRESSED` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 299 | TRIGGER | `TOOLBAR.REMOVE.WHEN-BUTTON-PRESSED` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 300 | TRIGGER | `TOOLBAR.LIST_VALUE.WHEN-BUTTON-PRESSED` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 301 | TRIGGER | `TOOLBAR.HELP.WHEN-BUTTON-PRESSED` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 302 | TRIGGER | `TOOLBAR.LAST_REC.WHEN-BUTTON-PRESSED` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 303 | TRIGGER | `TOOLBAR.RE_ENTER_QUERY.WHEN-BUTTON-PRESSED` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 304 | TRIGGER | `TOOLBAR.FIRST_REC.WHEN-BUTTON-PRESSED` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 305 | TRIGGER | `TOOLBAR.PAGE_UP.WHEN-BUTTON-PRESSED` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 306 | TRIGGER | `TOOLBAR.PAGE_DOWN.WHEN-BUTTON-PRESSED` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 307 | TRIGGER | `TOOLBAR.FUN_BUT.WHEN-MOUSE-UP` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 308 | TRIGGER | `TOOLBAR.FUN_BUT.WHEN-MOUSE-DOWN` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 309 | TRIGGER | `IMPR_CAR_EXCEPTION.ON-ERROR` | TEXT_MESSAGE | ICE_PK, ICE_SD_FK, ICE_SDP_FK, ICE_IMP_FK, ICE_DCLTN_FK | - | - | MAPPED | constraint texts via the APEX error handler (FORMS_APX.apex_error_handler); ORA-01031 texts dropped |
| 310 | TRIGGER | `IMPR_CAR_EXCEPTION.PRE-INSERT` | PROCESS | PRE-INSERT | 1160 | IMPR1160.PRE_INSERT | MAPPED | sequence, entry date, declaration ISN, duplicate check |
| 311 | TRIGGER | `IMPR_CAR_EXCEPTION.KEY-DUPREC` | - | - | - | - | DROPPED | duplicate record (keep the UID) - no duplicate record in APEX |
| 312 | TRIGGER | `IMPR_CAR_EXCEPTION.KEY-HELP` | - | - | - | - | DROPPED | Designer help file (empty CG$HP_HFILE) |
| 313 | TRIGGER | `IMPR_CAR_EXCEPTION.POST-QUERY` | PROCESS | POST-QUERY | 1160 | IMPR1160.POST_QUERY | MAPPED | Before Header after Initialize form; STATUS enterable |
| 314 | TRIGGER | `IMPR_CAR_EXCEPTION.PRE-QUERY` | REGION | IMPR_CAR_EXCEPTION (i:u:d, STATUS enterable) | 1160 | - | MAPPED | MAKE_BLOCK_FULL_OPERATION + SET_ITEM_PROPERTY STATUS -> region edit operations / read-only rules |
| 315 | TRIGGER | `IMPR_CAR_EXCEPTION.PRE-UPDATE` | PROCESS | PRE-UPDATE | 1160 | IMPR1160.PRE_UPDATE | MAPPED | inactive exception cannot be changed |
| 316 | TRIGGER | `IMPR_CAR_EXCEPTION.PORT_CD.KEY-LISTVAL` | - | - | - | - | DROPPED | Designer "may the LOV be shown" check: APEX shows a list only on an enterable item |
| 317 | TRIGGER | `IMPR_CAR_EXCEPTION.PORT_CD2.WHEN-BUTTON-PRESSED` | - | - | - | - | DROPPED | LOV of PORT_CD, never enterable |
| 318 | TRIGGER | `IMPR_CAR_EXCEPTION.PORT_NAME.KEY-LISTVAL` | - | - | - | - | DROPPED | Designer "may the LOV be shown" check: APEX shows a list only on an enterable item |
| 319 | TRIGGER | `IMPR_CAR_EXCEPTION.EXCPT_ISN.KEY-LISTVAL` | - | - | - | - | DROPPED | Designer "may the LOV be shown" check: APEX shows a list only on an enterable item |
| 320 | TRIGGER | `IMPR_CAR_EXCEPTION.IMPR_NBR.KEY-LISTVAL` | LOV | LOV_IMPR_P (Popup LOV) | 1160 | - | MAPPED | CALL_IMPR_LOV -> LOV form LOV_IMPR_P |
| 321 | TRIGGER | `IMPR_CAR_EXCEPTION.IMPR_NBR.KEY-NEXT-ITEM` | DA | IMPR_NBR KEY-NEXT-ITEM | 1160 | IMPR1160.IMPR_NBR_KEY_NEXT_ITEM | MAPPED | importer name, suspension check, Set Focus DCLTN_TYPE |
| 322 | TRIGGER | `IMPR_CAR_EXCEPTION.IMPR_NBR.WHEN-VALIDATE-ITEM` | VALIDATION | IMPR_NBR VALIDATION | 1160 | IMPR1160.IMPR_NBR_VALIDATION | MAPPED | the Forms IF never raises; the validation runs the KEY-NEXT-ITEM check (spec 7) |
| 323 | TRIGGER | `IMPR_CAR_EXCEPTION.IMPR_BUT.WHEN-BUTTON-PRESSED` | LOV | LOV_IMPR_P (Popup LOV button) | 1160 | - | MAPPED | go_item + do_key(List_values) |
| 324 | TRIGGER | `IMPR_CAR_EXCEPTION.IMPR_NAME.KEY-LISTVAL` | - | - | - | - | DROPPED | Designer "may the LOV be shown" check: APEX shows a list only on an enterable item |
| 325 | TRIGGER | `IMPR_CAR_EXCEPTION.DCLTN_TYPE.KEY-LISTVAL` | - | - | - | - | DROPPED | Designer "may the LOV be shown" check: APEX shows a list only on an enterable item |
| 326 | TRIGGER | `IMPR_CAR_EXCEPTION.DCLTN_NBR.KEY-LISTVAL` | LOV | LOV_IMPR_DCLTN (Popup LOV) | 1160 | - | MAPPED | CALL_IMPR_DCLTN_LOV -> LOV form LOV_IMPR_DCLTN |
| 327 | TRIGGER | `IMPR_CAR_EXCEPTION.DCLTN_NBR.POST-CHANGE` | DA | DCLTN_NBR POST-CHANGE | 1160 | IMPR1160.DCLTN_NBR_POST_CHANGE | MAPPED | declaration ISN, date, number of cars |
| 328 | TRIGGER | `IMPR_CAR_EXCEPTION.DCLTN_LOV.WHEN-BUTTON-PRESSED` | LOV | LOV_IMPR_DCLTN (Popup LOV button) | 1160 | - | MAPPED | go_item + do_key(List_values) |
| 329 | TRIGGER | `IMPR_CAR_EXCEPTION.DCLTN_DT.KEY-LISTVAL` | - | - | - | - | DROPPED | Designer "may the LOV be shown" check: APEX shows a list only on an enterable item |
| 330 | TRIGGER | `IMPR_CAR_EXCEPTION.DCLTN_DT.KEY-NEXT-ITEM` | - | - | - | - | DROPPED | NULL; (code commented out in Forms) |
| 331 | TRIGGER | `IMPR_CAR_EXCEPTION.DCLTN_DT.WHEN-VALIDATE-ITEM` | - | - | - | - | DROPPED | NULL; (code commented out in Forms) |
| 332 | TRIGGER | `IMPR_CAR_EXCEPTION.AWARD_NBR.WHEN-VALIDATE-ITEM` | VALIDATION | AWARD_NBR VALIDATION + DA AWARD_NBR WHEN-VALIDATE-ITEM | 1160 | IMPR1160.AWARD_NBR_VALIDATION | MAPPED | number <= 0 refused |
| 333 | TRIGGER | `IMPR_CAR_EXCEPTION.AWARD_DATE.KEY-LISTVAL` | PAGE_ITEM | P1160_AWARD_DATE (hijri-date-default) | 1160 | - | MAPPED | Hijri calendar (f345 app-wide) |
| 334 | TRIGGER | `IMPR_CAR_EXCEPTION.AWARD_DATE.KEY-F4` | PAGE_ITEM | P1160_AWARD_DATE (hijri-date-default) | 1160 | - | MAPPED | Hijri date picker (f345 app-wide) |
| 335 | TRIGGER | `IMPR_CAR_EXCEPTION.AWARD_DATE.WHEN-VALIDATE-ITEM` | VALIDATION | AWARD_DATE VALIDATION + DA AWARD_DATE WHEN-VALIDATE-ITEM | 1160 | FORMS_APX.HIJRI_DATE_ERROR | MAPPED | HIJDATE.VALID_HIJ_DATE |
| 336 | TRIGGER | `IMPR_CAR_EXCEPTION.NO_OF_CARS.KEY-LISTVAL` | - | - | - | - | DROPPED | Designer "may the LOV be shown" check: APEX shows a list only on an enterable item |
| 337 | TRIGGER | `IMPR_CAR_EXCEPTION.NO_OF_CARS.WHEN-VALIDATE-ITEM` | VALIDATION | NO_OF_CARS VALIDATION + DA NO_OF_CARS WHEN-VALIDATE-ITEM | 1160 | IMPR1160.NO_OF_CARS_VALIDATION | MAPPED | number <= 0 refused |
| 338 | TRIGGER | `IMPR_CAR_EXCEPTION.STATUS.KEY-LISTVAL` | - | - | - | - | DROPPED | Designer "may the LOV be shown" check: APEX shows a list only on an enterable item |
| 339 | TRIGGER | `IMPR_CAR_EXCEPTION.DCLTN_ISN.KEY-LISTVAL` | - | - | - | - | DROPPED | Designer "may the LOV be shown" check: APEX shows a list only on an enterable item |
| 340 | TRIGGER | `IMPR_CAR_EXCEPTION.STATS_ISN.KEY-LISTVAL` | - | - | - | - | DROPPED | Designer "may the LOV be shown" check: APEX shows a list only on an enterable item |
| 341 | TRIGGER | `IMPR_CAR_EXCEPTION.EXPTN_START_DT.KEY-LISTVAL` | - | - | - | - | DROPPED | item not displayed (Visible = false): the trigger cannot fire |
| 342 | TRIGGER | `IMPR_CAR_EXCEPTION.EXPTN_START_DT.KEY-F4` | - | - | - | - | DROPPED | item not displayed (Visible = false): the trigger cannot fire |
| 343 | TRIGGER | `IMPR_CAR_EXCEPTION.EXPTN_START_DT.WHEN-VALIDATE-ITEM` | - | - | - | - | DROPPED | item not displayed (Visible = false): the trigger cannot fire |
| 344 | TRIGGER | `IMPR_CAR_EXCEPTION.EXPTN_END_DT.KEY-LISTVAL` | - | - | - | - | DROPPED | item not displayed (Visible = false): the trigger cannot fire |
| 345 | TRIGGER | `IMPR_CAR_EXCEPTION.EXPTN_END_DT.KEY-F4` | - | - | - | - | DROPPED | item not displayed (Visible = false): the trigger cannot fire |
| 346 | TRIGGER | `IMPR_CAR_EXCEPTION.EXPTN_END_DT.WHEN-VALIDATE-ITEM` | - | - | - | - | DROPPED | item not displayed (Visible = false): the trigger cannot fire |
| 347 | TRIGGER | `IMPR_CAR_EXCEPTION.AWARD_REMARKS.KEY-LISTVAL` | - | - | - | - | DROPPED | Designer "may the LOV be shown" check: APEX shows a list only on an enterable item |
| 348 | PROGRAM_UNIT | `CHECK_TIMEOUT` | - | - | - | - | DROPPED | NIB wrapper not called by active code (timers, EDI ticker, window, print) |
| 349 | PROGRAM_UNIT | `MOUSE_CLICK` | REGION | FUNCS (page 0) | 0 | - | MAPPED | function list click |
| 350 | PROGRAM_UNIT | `TOGGEL_WND` | - | - | - | - | DROPPED | NIB wrapper not called by active code (timers, EDI ticker, window, print) |
| 351 | PROGRAM_UNIT | `PRINT_REPORT` | - | - | - | - | DROPPED | NIB wrapper not called by active code (timers, EDI ticker, window, print) |
| 352 | PROGRAM_UNIT | `EXECUTE_FUNCTION` | REGION | FUNCS (page 0) | 0 | - | MAPPED | f345 Page Functions (the form has no function of its own) |
| 353 | PROGRAM_UNIT | `TERMINATE_FUN` | - | - | - | - | DROPPED | NIB wrapper not called by active code (timers, EDI ticker, window, print) |
| 354 | PROGRAM_UNIT | `CHECK_EDI_MSG_LOV` | - | - | - | - | DROPPED | NIB wrapper not called by active code (timers, EDI ticker, window, print) |
| 355 | PROGRAM_UNIT | `CHECK_EDI_MSG_TIMER` | - | - | - | - | DROPPED | NIB wrapper not called by active code (timers, EDI ticker, window, print) |
| 356 | PROGRAM_UNIT | `CHECK_EDI_ROLE_ID` | - | - | - | - | DROPPED | NIB wrapper not called by active code (timers, EDI ticker, window, print) |
| 357 | PROGRAM_UNIT | `EDI_MSG_LOV` | - | - | - | - | DROPPED | NIB wrapper not called by active code (timers, EDI ticker, window, print) |
| 358 | PROGRAM_UNIT | `FOR_EDI_MSG` | - | - | - | - | DROPPED | NIB wrapper not called by active code (timers, EDI ticker, window, print) |
| 359 | PROGRAM_UNIT | `RETURN_MSG` | - | - | - | - | DROPPED | NIB wrapper not called by active code (timers, EDI ticker, window, print) |
| 360 | PROGRAM_UNIT | `TURN_MSG` | - | - | - | - | DROPPED | NIB wrapper not called by active code (timers, EDI ticker, window, print) |
| 361 | PROGRAM_UNIT | `WHEN_TIMER_EXPIRED_MSG` | - | - | - | - | DROPPED | NIB wrapper not called by active code (timers, EDI ticker, window, print) |
| 362 | PROGRAM_UNIT | `CG$WHEN_NEW_FORM_INSTANCE` | - | - | - | - | DROPPED | lists -> shared LOVs |
| 363 | PROGRAM_UNIT | `CGDV$POPULATE_DYNAMIC_LISTS` | LOV | LOV_DCL_STA_FLAG, LOV_REC_STATUS | 1160 | - | MAPPED | LOV_APX.REFERENCE_CODES(DCL_STA_FLAG / REC_STATUS) |
| 364 | PROGRAM_UNIT | `CGUI$GET_NEXT_IMPR_CAR_EXPTN_S` | - | - | - | - | DROPPED | not called (same code as GET_NEXT_IMPR_CAR_EXPTN_CNTRL) |
| 365 | PROGRAM_UNIT | `CGTE$CHECK_CONSTRAINT_VIO` | TEXT_MESSAGE | ICE_PK | - | - | MAPPED | APEX error handler; other tables' constraints cannot occur |
| 366 | PROGRAM_UNIT | `POPULATE_DYNAMIC_LISTS` | - | - | - | - | DROPPED | body NULL; (code commented out) |
| 367 | PROGRAM_UNIT | `GET_NEXT_IMPR_CAR_EXPTN_CNTRL` | PROCESS | PRE-INSERT | 1160 | IMPR1160.GET_NEXT_IMPR_CAR_EXPTN_CNTRL | MAPPED | central sequence |
| 368 | PROGRAM_UNIT | `EXEC_FUNS` | - | - | - | - | DROPPED | body NULL; |
| 369 | PROGRAM_UNIT | `DEV_VERSIONS` | - | - | - | - | DROPPED | version comment only |
| 370 | PROGRAM_UNIT | `CALL_IMPR_LOV` | LOV | LOV_IMPR_P | 1160 | - | MAPPED | LOV_APX.IMPORTERS (type 4, business id type 5) + DA IMPR_NBR KEY-NEXT-ITEM |
| 371 | PROGRAM_UNIT | `CALL_IMPR_DCLTN_LOV` | LOV | LOV_IMPR_DCLTN | 1160 | - | MAPPED | LOV_APX.LOV_IMPR_DCLTN + DA DCLTN_NBR POST-CHANGE |
| 372 | PROGRAM_UNIT | `ADJ_FUNS` | - | - | - | - | DROPPED | body NULL; |
| 373 | LOV | `CGFK$IMPR_CAR_EXCEPTION_PORT_C` | - | - | - | - | DROPPED | LOV of PORT_CD (ports from DECLARATIONS): PORT_CD is never enterable |
| 374 | RECORD_GROUP | `CGFK$IMPR_CAR_EXCEPTION_PORT_C` | - | - | - | - | DROPPED | record group of the dropped PORT_CD LOV |
| 375 | RECORD_GROUP | `CGDV$DLRG (runtime, DCLTN_TYPE)` | LOV | LOV_DCL_STA_FLAG | 1160 | - | MAPPED | CG_REF_CODES DCL_STA_FLAG |
| 376 | RECORD_GROUP | `CGDV$DLRG (runtime, STATUS)` | LOV | LOV_REC_STATUS (IMPR1140) | 1160 | - | MAPPED | CG_REF_CODES REC_STATUS |
| 377 | CALLED_FORM | `LOV_IMPR_P` | LOV | LOV_IMPR_P | 1160 | - | MAPPED | Popup LOV of P1160_IMPR_NBR |
| 378 | CALLED_FORM | `LOV_IMPR_DCLTN` | LOV | LOV_IMPR_DCLTN | 1160 | - | MAPPED | Popup LOV of P1160_DCLTN_NBR |
| 379 | ALERT | `USR_CONFIRM_B` | - | - | - | - | DROPPED | OLB alert not referenced by this form |
| 380 | ALERT | `USR_CONFIRM` | - | - | - | - | DROPPED | OLB alert not referenced by this form |
| 381 | ALERT | `USR_WARNING_C` | - | - | - | - | DROPPED | OLB alert not referenced by this form |
| 382 | ALERT | `USR_WARNING_B` | - | - | - | - | DROPPED | OLB alert not referenced by this form |
| 383 | ALERT | `CFG_WARNING_A` | - | - | - | - | DROPPED | OLB alert not referenced by this form |
| 384 | ALERT | `CFG_INFORMATION` | APP_ITEM | page messages (FORMS_APX.FORM_TRIGGER_FAILURE) | - | - | MAPPED | STR.DISPALERT |
| 385 | ALERT | `CFG_ERROR` | APP_ITEM | page messages (FORMS_APX.FORM_TRIGGER_FAILURE) | - | - | MAPPED | STR.DISPALERT |
| 386 | ALERT | `CFG_SYSTEM_ERROR` | - | - | - | - | DROPPED | OLB alert not referenced by this form |
| 387 | ALERT | `CFG_ASK_COMMIT` | - | - | - | - | DROPPED | OLB alert not referenced by this form |
| 388 | PARAMETER | `P_SHPG_AGNT_NBR` | - | - | - | - | DROPPED | used only by the OLB frame (EXECUTE_FUNCTION parameter list, print, EDI) |
| 389 | PARAMETER | `P_CTRL_LAST_EXEC_CD` | - | - | - | - | DROPPED | used only by the OLB frame (EXECUTE_FUNCTION parameter list, print, EDI) |
| 390 | PARAMETER | `P_BANK_CD` | - | - | - | - | DROPPED | used only by the OLB frame (EXECUTE_FUNCTION parameter list, print, EDI) |
| 391 | PARAMETER | `P_BANK_BRNCH_CD` | - | - | - | - | DROPPED | used only by the OLB frame (EXECUTE_FUNCTION parameter list, print, EDI) |
| 392 | PARAMETER | `P_BRKR_PORT_CD` | - | - | - | - | DROPPED | used only by the OLB frame (EXECUTE_FUNCTION parameter list, print, EDI) |
| 393 | PARAMETER | `P_LIC_TYPE` | - | - | - | - | DROPPED | used only by the OLB frame (EXECUTE_FUNCTION parameter list, print, EDI) |
| 394 | PARAMETER | `P_BRKR_NBR` | - | - | - | - | DROPPED | used only by the OLB frame (EXECUTE_FUNCTION parameter list, print, EDI) |
| 395 | PARAMETER | `P_CLASS_CD` | - | - | - | - | DROPPED | used only by the OLB frame (EXECUTE_FUNCTION parameter list, print, EDI) |
| 396 | PARAMETER | `P_JOB_ID` | - | - | - | - | DROPPED | used only by the OLB frame (EXECUTE_FUNCTION parameter list, print, EDI) |
| 397 | PARAMETER | `P_CURRENT_ITEM` | - | - | - | - | DROPPED | used only by the OLB frame (EXECUTE_FUNCTION parameter list, print, EDI) |
| 398 | PARAMETER | `P_GROUP_CD` | - | - | - | - | DROPPED | used only by the OLB frame (EXECUTE_FUNCTION parameter list, print, EDI) |
| 399 | PARAMETER | `P_USER_TYPE` | - | - | - | - | DROPPED | used only by the OLB frame (EXECUTE_FUNCTION parameter list, print, EDI) |
| 400 | PARAMETER | `P_PORT_TYPE` | - | - | - | - | DROPPED | used only by the OLB frame (EXECUTE_FUNCTION parameter list, print, EDI) |
| 401 | PARAMETER | `P_CURR_PORT_CD` | APP_ITEM | P_CURR_PORT_CD (f345) | - | - | MAPPED | port of the new record and of the look-ups |
| 402 | PARAMETER | `P_MODULE_ID` | PAGE_ITEM | P1160_MODULE_ID | 1160 | - | MAPPED | FORMS_APX.GET_MODULE_ID |
| 403 | PARAMETER | `P_MODULE_NAME` | - | - | - | - | DROPPED | used only by the OLB frame (EXECUTE_FUNCTION parameter list, print, EDI) |
| 404 | PARAMETER | `P_APPLICATION_NAME` | - | - | - | - | DROPPED | used only by the OLB frame (EXECUTE_FUNCTION parameter list, print, EDI) |
| 405 | PARAMETER | `P_USER_ID` | - | - | - | - | DROPPED | used only by the OLB frame (EXECUTE_FUNCTION parameter list, print, EDI) |
| 406 | PARAMETER | `P_WS_ID` | - | - | - | - | DROPPED | used only by the OLB frame (EXECUTE_FUNCTION parameter list, print, EDI) |
| 407 | PARAMETER | `P_USER_NAME` | - | - | - | - | DROPPED | used only by the OLB frame (EXECUTE_FUNCTION parameter list, print, EDI) |
| 408 | PARAMETER | `CG$STARTUP_MODE` | - | - | - | - | DROPPED | used only by the OLB frame (EXECUTE_FUNCTION parameter list, print, EDI) |
| 409 | CANVAS | `LSIDE` | - | - | - | - | DROPPED | OLB frame canvas |
| 410 | CANVAS | `EDI_MSG` | - | - | - | - | DROPPED | OLB frame canvas |
| 411 | CANVAS | `TITLE` | - | - | - | - | DROPPED | OLB frame canvas |
| 412 | CANVAS | `TOOLBAR` | - | - | - | - | DROPPED | OLB frame canvas |
| 413 | CANVAS | `CG$PAGE_1` | PAGE | IMPR1160 | 1160 | - | MAPPED | region IMPR_CAR_EXCEPTION |
| 414 | WINDOW | `CGSO$WINDOW_1` | PAGE | IMPR1160 | 1160 | - | MAPPED | one page |
| 415 | LIBRARY | `OFGTEL` | - | - | - | - | DROPPED | frame / client library (windows, timers, help, DLLs) |
| 416 | LIBRARY | `OFGMES` | - | - | - | - | DROPPED | frame / client library (windows, timers, help, DLLs) |
| 417 | LIBRARY | `OFGHPL` | - | - | - | - | DROPPED | frame / client library (windows, timers, help, DLLs) |
| 418 | LIBRARY | `CIC_AMSG` | - | - | - | - | DROPPED | frame / client library (windows, timers, help, DLLs) |
| 419 | LIBRARY | `SEC_LIB` | - | - | - | - | DROPPED | frame / client library (windows, timers, help, DLLs) |
| 420 | LIBRARY | `CAPTION` | - | - | - | - | DROPPED | frame / client library (windows, timers, help, DLLs) |
| 421 | LIBRARY | `OFGBSL` | - | - | - | - | DROPPED | frame / client library (windows, timers, help, DLLs) |
| 422 | LIBRARY | `D2KWUTIL` | - | - | - | - | DROPPED | frame / client library (windows, timers, help, DLLs) |
| 423 | LIBRARY | `CUSTOMDLL` | - | - | - | - | DROPPED | frame / client library (windows, timers, help, DLLs) |
| 424 | LIBRARY | `D2KWUTIL_PDF` | - | - | - | - | DROPPED | frame / client library (windows, timers, help, DLLs) |
| 425 | LIBRARY | `GETCOMP` | - | - | - | - | DROPPED | frame / client library (windows, timers, help, DLLs) |
| 426 | LIBRARY | `OFGTAB` | - | - | - | - | DROPPED | frame / client library (windows, timers, help, DLLs) |
| 427 | LIBRARY | `PICKLIST` | - | - | - | - | DROPPED | frame / client library (windows, timers, help, DLLs) |
| 428 | LIBRARY | `POS` | - | - | - | - | DROPPED | frame / client library (windows, timers, help, DLLs) |
| 429 | LIBRARY | `SCDLL` | - | - | - | - | DROPPED | frame / client library (windows, timers, help, DLLs) |
| 430 | LIBRARY | `VCDLL` | - | - | - | - | DROPPED | frame / client library (windows, timers, help, DLLs) |
| 431 | LIBRARY | `CIC_LIB` | PACKAGE | FORMS_APX | - | - | MAPPED | STR -> FORMS_APX, HIJDATE -> FORMS_APX Hijri helpers, TMPLT -> FUNCS |
| 432 | GLOBAL | `IMPR_NBR` | LOV | LOV_IMPR_P | 1160 | - | MAPPED | value returned by the LOV form -> Popup LOV return value |
| 433 | GLOBAL | `DCLTN_NBR` | LOV | LOV_IMPR_DCLTN | 1160 | - | MAPPED | value returned by the LOV form -> Popup LOV return value |
| 434 | GLOBAL | `DCLTN_DT` | DA | DCLTN_NBR POST-CHANGE | 1160 | IMPR1160.DCLTN_NBR_POST_CHANGE | MAPPED | date re-read from the declaration |
| 435 | GLOBAL | `CG$HP_HFILE` | - | - | - | - | DROPPED | help / screen version / duplicate record / frame |
| 436 | GLOBAL | `CG$HP_HPATH` | - | - | - | - | DROPPED | help / screen version / duplicate record / frame |
| 437 | GLOBAL | `CG$TEMP_0` | - | - | - | - | DROPPED | help / screen version / duplicate record / frame |
| 438 | GLOBAL | `CURRENT_DT` | - | - | - | - | DROPPED | help / screen version / duplicate record / frame |
| 439 | GLOBAL | `CURRENT_VER` | - | - | - | - | DROPPED | help / screen version / duplicate record / frame |
| 440 | GLOBAL | `CURRENT_VERSION` | - | - | - | - | DROPPED | help / screen version / duplicate record / frame |
| 441 | GLOBAL | `EXIT` | - | - | - | - | DROPPED | help / screen version / duplicate record / frame |
| 442 | GLOBAL | `SYSTEM_OBJ` | - | - | - | - | DROPPED | help / screen version / duplicate record / frame |
