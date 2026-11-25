# IMPR1150 – APEX 21.2 Page Specification (step 03, revision 1)

- **Form:** IMPR1150 (XML module `IMPR1150_PROD_CENTRL`) – تفعيل المستوردين من منصة فسح
- **Package:** `IMPR1150` version 001 (`plsql/IMPR1150/`), logic report `analysis/IMPR1150/IMPR1150_logic_extraction.md`
- **Standard:** f345 (`apex/Reference/f345.sql`), CLAUDE.md §4a–§4d, `docs/f345_reference_standard.md`
- **Design data:** `scripts/gen_apex_impr1150.py` (ITEMS, PROCESSES, DAS …); this file is rendered from it by
  `work/IMPR1150/step03/build_spec.py`, the traceability (§14) and `registry/IMPR1150_registry.sql` by `build_trace.py`.
- **Produced:** 2026-11-25 by Claude Code.

## 0. Decisions that shape the page

| # | Decision | Reason / source |
|---|---|---|
| 1 | Main page **1150** `IMPR1150`, search page **115001** `IMPR1150_SEARCH` (modal 1800×800), page group `IMPR` (IMPR1110 export) | f345 standard §3 |
| 2 | Block IMPORTERS_CENTRAL = native **Form** region, **read-only** (Editable = No), SQL source on `CUSTOMS.IMPORTERS_CENTRAL@HQPRD.HQ.CUSTOMS.GOV`, scope `PORT_CD = 99 AND PORT_CD = :P_CURR_PORT_CD`, key **IMPR_NBR** (= `P0_PAGE_PK`) | user decision 2026-11-25 (keep the database link); block Update / Delete Allowed = false; a remote ROWID is not used |
| 3 | A new page is the Forms "new record": only `IMPR_NBR` and `BUS_ID` are enterable (read-only once a record is shown). Their change runs the check (message 9-150) and submits `EXECUTE_QUERY`; process EXECUTE-QUERY sets `P0_PAGE_PK` | WHEN-VALIDATE-ITEM + :GLOBAL.EXEC_QUERY_NOW + WHEN-NEW-ITEM-INSTANCE EXECUTE_QUERY |
| 4 | Query by BUS_ID: one record per page, the pending one of that BUS_ID (else the first by IMPR_NBR); others through the search page | Forms scrolls several records (KEY-DOWN / UP) |
| 5 | Functions `IMPR1150_ACTIVATE` / `IMPR1150_REJECT` come from the f345 Page Functions list (page 0 FUNCS drawer), filtered by `P1150_ADJ_FUNS`; each raises its custom event; the DA submits the request of the same name; an After Submit process calls `EXEC_FUNS` and shows the Forms message as success message | PU EXECUTE_FUNCTION / EXEC_FUNS / ADJ_FUNS |
| 6 | REJECT without a reason (first press in Forms): client-side condition of the DA: REJCT_RESON shown, IMPR_REJCT_RESON hidden, alert "برجاء إدخال سبب الرفض", focus. With a reason: request IMPR1150_REJECT | EXEC_FUNS CR-7234 (no server round trip needed; the server refuses an empty reason again) |
| 7 | CREATE / DELETE of page 0 are refused with a message (`PRE_INSERT` / `PRE_DELETE`); SAVE only gives PRE-UPDATE's message | as IMPR1116; no DML on this block |
| 8 | Documents: read-only IG `IMPORTER_DOCS` (local `IMPORTERS_DOCS`); the button OPEN_DEC (HOST START on the client PC) becomes the column `DOC_FULL_NAME`: **TODO** how to open the file | inventory §15 #1 |
| 9 | No JavaScript action at all (Hide / Show / Alert / Set Focus / Submit Page are native) | CLAUDE.md §4c |

## 1. Page type decision per block

| Block | Forms | APEX |
|---|---|---|
| IMPORTERS_CENTRAL | base table (query source = HQ table over the link), one record shown, query only | Form region (read-only) on page 1150 + search IG on page 115001 |
| IMPORTER_DOCS | base table, 6 records, query only, WHERE IMPR_NBR = master | read-only IG on page 1150 |
| TITLE, EDI_MSG, LSIDE, TOOLBAR | OLB frame | f345 page template, hero region, page 0 toolbar, FUNCS drawer |

## 2. Pages

| Page | Name / alias | Mode | Template / class | Source |
|---|---|---|---|---|
| 1150 | IMPR1150 / IMPR1150 | Normal, protection C, Warn on Unsaved Changes = No (nothing to save) | Zatca-Minimal_No_Navigation, `zf` | window CGSO$WINDOW_1, canvas CG$PAGE_1 |
| 115001 | IMPR1150_SEARCH / IMPR1150-SEARCH | Modal 1800×800, protection C | theme dialog, `zf` | Enter-Query / Execute-Query (page 0 SEARCH) |

## 3. Regions

| Page | Region (Static ID) | Type | Template / classes | Source |
|---|---|---|---|---|
| 1150 | `IMPORTERS_CENTRAL_HERO` "الهيدر" | Static HTML, `&P1150_HERO_TITLE.` | f345 hero, `cg-hero` | TITLE (OLB) |
| 1150 | `IMPORTERS_CENTRAL` "المستوردين من منصة فسح" | Form, SQL on the HQ table, read-only, key IMPR_NBR | Interactive Report, `zatca-forms cg-form cg-card` | block IMPORTERS_CENTRAL |
| 1150 | `IMPORTER_DOCS` "وثائق المستورد" | IG read-only, `WHERE impr_nbr = :P1150_IMPR_NBR` (Page Items to Submit P1150_IMPR_NBR) | Standard, `t-Region--noPadding`, `cg-card cg-grid` | block IMPORTER_DOCS + DETIL_DATA |
| 115001 | `IMPORTERS_CENTRAL_SEARCH_CRITERIA` "بحث" | Static, item `P115001_SEARCH`, buttons SEARCH / CLEAR | f345 hero | query criteria |
| 115001 | `IMPORTERS_CENTRAL_SEARCH` "المستوردون" | IG read-only, one search text over all columns, no rows before a search, all statuses, link IMPR_NBR → page 1150 (`P0_PAGE_PK`) | Standard | block query (HQ table) |

## 4. Items (page 1150)

Layout from canvas CG$PAGE_1 (rows by Y, right to left by X, 12 columns).

| Item | Column | Type | Label | LOV | New row / span | Read only | Source |
|---|---|---|---|---|---|---|---|
| P1150_PENDING_ACTIVE | PENDING_ACTIVE | Select List | حالة المستورد | LOV_PENDING_ACTIVE | Yes / 4 | Always | IMPORTERS_CENTRAL.PENDING_ACTIVE (List Item; values of CG_REF_CODES domain PENDING_ACTIVE, CGDV$POPULATE_DYNAMIC_LISTS) |
| P1150_BUS_ID | BUS_ID | Text Field | الـرقم الإستدلالي | - | No / 4 | `:P0_PAGE_PK IS NOT NULL` | IMPORTERS_CENTRAL.BUS_ID (query key of a new record; Update Allowed = false) |
| P1150_IMPR_NBR | IMPR_NBR | Number Field (number_only) (PK) | الرقم الجمركي | - | No / 4 | `:P0_PAGE_PK IS NOT NULL` | IMPORTERS_CENTRAL.IMPR_NBR (query key of a new record; Form region primary key = P0_PAGE_PK) |
| P1150_IMPR_TYPE_CD | IMPR_TYPE_CD | Display Only (Send On Page Submit = No) | رمز النشاط التجارى | - | Yes / 2 | - | IMPORTERS_CENTRAL.IMPR_TYPE_CD |
| P1150_IMPR_TYPE_NAME | - | Display Only (Send On Page Submit = No) | - | - | No / 6 | - | IMPORTERS_CENTRAL.IMPR_TYPE_NAME (POST-QUERY) |
| P1150_BUS_ID_BRNCH | BUS_ID_BRNCH | Display Only (Send On Page Submit = No) | الـرقم الــفــرعي | - | No / 4 | - | IMPORTERS_CENTRAL.BUS_ID_BRNCH |
| P1150_HQ_IMPR_NBR | HQ_IMPR_NBR | Display Only (Send On Page Submit = No) | الرقم الموحد بالمصلحة | - | Yes / 8 | - | IMPORTERS_CENTRAL.HQ_IMPR_NBR |
| P1150_BUS_ID_EXPRD_DT | BUS_ID_EXPRD_DT | Display Only (Send On Page Submit = No) | إنتهاء النشاط | - | No / 4 | - | IMPORTERS_CENTRAL.BUS_ID_EXPRD_DT (CGSO$HDATE_ARB_DO; WHEN-VALIDATE-ITEM unreachable: not enterable) |
| P1150_BUS_ID_TYPE_CD | BUS_ID_TYPE_CD | Display Only (Send On Page Submit = No) | نوع الرقم الإستدلالي | - | Yes / 2 | - | IMPORTERS_CENTRAL.BUS_ID_TYPE_CD |
| P1150_BUS_ID_TYPE_NAME | - | Display Only (Send On Page Submit = No) | - | - | No / 6 | - | IMPORTERS_CENTRAL.BUS_ID_TYPE_NAME (POST-QUERY) |
| P1150_CTRY_CD | CTRY_CD | Display Only (Send On Page Submit = No) | الجنسيــــــــــه | - | No / 2 | - | IMPORTERS_CENTRAL.CTRY_CD |
| P1150_CRTY_ARBC_NAME | - | Display Only (Send On Page Submit = No) | - | - | No / 2 | - | IMPORTERS_CENTRAL.CRTY_ARBC_NAME (POST-QUERY) |
| P1150_ARBC_IMPR_NAME | ARBC_IMPR_NAME | Display Only (Send On Page Submit = No) | اسم المستورد | - | Yes / 12 | - | IMPORTERS_CENTRAL.ARBC_IMPR_NAME |
| P1150_IMPR_ADDRESS | IMPR_ADDRESS | Display Only (Send On Page Submit = No) | العنوان | - | Yes / 12 | - | IMPORTERS_CENTRAL.IMPR_ADDRESS |
| P1150_ADD_CTRY_CD | ADD_CTRY_CD | Display Only (Send On Page Submit = No) | دولة الأقامه | - | Yes / 2 | - | IMPORTERS_CENTRAL.ADD_CTRY_CD |
| P1150_ADD_CRTY_ARBC_NAME | - | Display Only (Send On Page Submit = No) | - | - | No / 6 | - | IMPORTERS_CENTRAL.ADD_CRTY_ARBC_NAME (POST-QUERY) |
| P1150_CITY_CODE | CITY_CODE | Display Only (Send On Page Submit = No) | المدينه | - | No / 2 | - | IMPORTERS_CENTRAL.CITY_CODE |
| P1150_CITY_NAME | - | Display Only (Send On Page Submit = No) | - | - | No / 2 | - | IMPORTERS_CENTRAL.CITY_NAME (POST-QUERY) |
| P1150_IMPR_TEL_NBR | IMPR_TEL_NBR | Display Only (Send On Page Submit = No) | تليفون | - | Yes / 8 | - | IMPORTERS_CENTRAL.IMPR_TEL_NBR |
| P1150_MOBILE_NO | MOBILE_NO | Display Only (Send On Page Submit = No) | رقم الجوال | - | No / 4 | - | IMPORTERS_CENTRAL.MOBILE_NO |
| P1150_ACTIVITY | ACTIVITY | Display Only (Send On Page Submit = No) | نشاط المستورد | - | Yes / 12 | - | IMPORTERS_CENTRAL.ACTIVITY (CGSO$CHAR_ARB_MLINE; make_field_entrable FALSE / TRUE in EXEC_FUNS: never enterable) |
| P1150_IMPR_REJCT_RESON | IMPR_REJCT_RESON_CD | Select List | سبب رفض التفعيل | LOV_IMPR_REJCT_RESON | Yes / 12 | Always | IMPORTERS_CENTRAL.IMPR_REJCT_RESON (column IMPR_REJCT_RESON_CD, LOV CGDV$IMPORTERS_CENTRAL_IMPR_RE; Insert / Update / Query Allowed = false; button IMPR_REJCT_RESON2 dropped) |
| P1150_REJCT_RESON | - | Text Field | سبب رفض التفعيل | - | Yes / 12 | - | IMPORTERS_CENTRAL.REJCT_RESON (non-database item, hidden by PRE-FORM; shown by function IMPR1150_REJECT - DA "IMPR1150_REJECT EXECUTE-FUNCTION") |
| P1150_PORT_CD | PORT_CD | Hidden (Value Protected = Yes) | - | - | hidden | - | IMPORTERS_CENTRAL.PORT_CD (not displayed; 99 after the query) |
| P1150_BIRTH_DT | BIRTH_DT | Hidden (Value Protected = Yes) | - | - | hidden | - | IMPORTERS_CENTRAL.BIRTH_DT (not displayed) |
| P1150_MODULE_ID | - | Hidden (Value Protected = Yes) | - | - | hidden | - | f345 Page Functions: P<page>_MODULE_ID |
| P1150_HIJRI_DATE_FORMAT | - | Hidden (Value Protected = Yes) | - | - | hidden | - | FORMS_APX.HIJRI_DATE_FORMAT (format mask of BUS_ID_EXPRD_DT) |
| P1150_HERO_TITLE | - | Hidden (Value Protected = Yes) | - | - | hidden | - | f345 hero title (FORMS_APX.HEADER_TITLE) |
| P1150_ADJ_FUNS | - | Hidden (Value Protected = Yes) | - | - | hidden | - | PU ADJ_FUNS: enabled functions of the Page Functions list |

Every Text / Number Field has its `cg-ic` icon (`scripts/item_icons.py`). `REJCT_RESON` is not *Value Required* (it would block
every other submit); `EXEC_FUNS` refuses an empty reason. Its maximum length is not in the XML (TODO with inventory §15 #2).

## 5. Buttons

| Page | Button | Action | Source |
|---|---|---|---|
| 0 | CREATE / SAVE / DELETE / SEARCH / CLEAR / FUNCS / BACK | f345 page 0 toolbar: CREATE, SAVE, DELETE handled by processes §8; SEARCH opens 115001 | TOOLBAR (OLB), KEY-* |
| 115001 | `SEARCH`, `CLEAR` | refresh the grid / clear the text | EXECUTE_QUERY, CLEAR |

## 6. LOVs (new, *PL/SQL Function Body returning SQL Query*, R / D)

| LOV | Body | Source |
|---|---|---|
| LOV_PENDING_ACTIVE | `return LOV_APX.REFERENCE_CODES(P_DOMAIN => 'PENDING_ACTIVE');` | IMPORTERS_CENTRAL.PENDING_ACTIVE list (CGDV$POPULATE_DYNAMIC_LISTS, CG_REF_CODES domain PENDING_ACTIVE) |
| LOV_IMPR_REJCT_RESON | `return LOV_APX.REFERENCE_CODES(P_DOMAIN => 'IMPR_REJCT_RESON');` | LOV CGDV$IMPORTERS_CENTRAL_IMPR_RE / record group CGDV$IMPR_REJCT_RESON (CG_REF_CODES domain IMPR_REJCT_RESON) |

## 7. Validations (page 1150, request EXECUTE_QUERY)

| Name | Item | PL/SQL Function Body returning Error Text | Source |
|---|---|---|---|
| IMPR_NBR VALIDATION | P1150_IMPR_NBR | `RETURN IMPR1150.IMPR_NBR_VALIDATION(P_PORT_CD => :P1150_PORT_CD, P_IMPR_NBR => :P1150_IMPR_NBR);` | IMPORTERS_CENTRAL.IMPR_NBR.WHEN-VALIDATE-ITEM |
| BUS_ID VALIDATION | P1150_BUS_ID | `RETURN IMPR1150.BUS_ID_VALIDATION(P_BUS_ID => :P1150_BUS_ID);` | IMPORTERS_CENTRAL.BUS_ID.WHEN-VALIDATE-ITEM |

## 8. Processes

| Point | Seq | Name | Code | Condition | Success message | Source |
|---|---|---|---|---|---|---|
| Before Header | 10 | New | f345 session setup (AGR1100) | `Never` | - | f345 session setup copied from AGR1100 (condition Never) / standard 6 |
| Before Header | 20 | P0_PAGE_PK CHECK | `IMPR1150.P0_PAGE_PK_CHECK(P_PAGE_PK => :P0_PAGE_PK, P_CURR_PORT_CD => :P_CURR_PORT_CD);` | - | - | f345 key (IMPR_NBR of the HQ importer, block WHERE clause) |
| Before Header | 40 | PARAMETERS | `:P1150_MODULE_ID := FORMS_APX.GET_MODULE_ID(P_MODULE_ID => :P1150_MODULE_ID, FORM_NAME => 'IMPR1150');` | - | - | f345 module id of the Page Functions list |
| Before Header | 70 | P0_PAGE_PK | `:P1150_IMPR_NBR := :P0_PAGE_PK;` | - | - | f345 (key = IMPR_NBR) |
| Before Header | 80 | Initialize form IMPORTERS_CENTRAL | NATIVE_FORM_INIT, region IMPORTERS_CENTRAL | - | - | block IMPORTERS_CENTRAL query (QUERY_DATA_SOURCE_NAME = CUSTOMS.IMPORTERS_CENTRAL@HQPRD.HQ.CUSTOMS.GOV) |
| Before Header | 82 | POST-QUERY | `IMPR1150.POST_QUERY(P_IMPR_TYPE_CD => :P1150_IMPR_TYPE_CD, P_IMPR_TYPE_NAME => :P1150_IMPR_TYPE_NAME, P_BUS_ID_TYPE_CD => :P1150_BUS_ID_TYPE_CD, P_BUS_ID_TYPE_NAME => :P1150_BUS_ID_TYPE_NAME, P_CTRY_CD => :P1150_CTRY_CD, P_CRTY_ARBC_NAME => :P1150_CRTY_ARBC_NAME, P_ADD_CTRY_CD => :P1150_ADD_CTRY_CD, P_ADD_CRTY_ARBC_NAME => :P1150_ADD_CRTY_ARBC_NAME, P_CITY_CODE => :P1150_CITY_CODE, P_CITY_NAME => :P1150_CITY_NAME);` | `:P0_PAGE_PK IS NOT NULL` | - | IMPORTERS_CENTRAL.POST-QUERY |
| Before Header | 100 | HEADER TITLE | `FORMS_APX.HEADER_TITLE(P_MODULE_ID => :P1150_MODULE_ID, P_HERO_TITLE => :P1150_HERO_TITLE, DEFAULT_TITLE => 'تفعيل المستوردين من منصة فسح');` | - | - | f345 hero title (module title) |
| After Submit | 10 | EXECUTE-QUERY | `:P0_PAGE_PK := IMPR1150.IMPORTER_KEY(P_IMPR_NBR => :P1150_IMPR_NBR, P_BUS_ID => :P1150_BUS_ID, P_CURR_PORT_CD => :P_CURR_PORT_CD);` | `:REQUEST = 'EXECUTE_QUERY'` | - | IMPORTERS_CENTRAL.PRE-QUERY + WHEN-NEW-ITEM-INSTANCE (EXEC_QUERY_NOW -> EXECUTE_QUERY) |
| After Submit | 20 | PRE-INSERT | `IMPR1150.PRE_INSERT;` | `:REQUEST = 'CREATE'` | - | block IMPORTERS_CENTRAL: no insert from this form (page 0 CREATE refused) |
| After Submit | 30 | PRE-UPDATE | `IMPR1150.PRE_UPDATE(P_REJCT_RESON => :P1150_REJCT_RESON);` | `:REQUEST = 'SAVE'` | - | IMPORTERS_CENTRAL.PRE-UPDATE (block Update Allowed = false: no DML) |
| After Submit | 40 | PRE-DELETE | `IMPR1150.PRE_DELETE;` | `:REQUEST = 'DELETE'` | - | block IMPORTERS_CENTRAL Delete Allowed = false (KEY-DELREC) |
| After Submit | 50 | IMPR1150_ACTIVATE EXECUTE-FUNCTION | `IMPR1150.EXEC_FUNS(P_FUNCTION_CODE => 'IMPR1150_ACTIVATE', P_PORT_CD => :P1150_PORT_CD, P_IMPR_NBR => :P1150_IMPR_NBR, P_REJCT_RESON => :P1150_REJCT_RESON, P_CURR_PORT_CD => :P_CURR_PORT_CD, SSO_APP_USER => :SSO_APP_USER, P_GLOBAL_V_WS_ID => :P_GLOBAL_V_WS_ID);` | `:REQUEST = 'IMPR1150_ACTIVATE'` | تم تفعيل المستورد | PU EXECUTE_FUNCTION -> EXEC_FUNS(IMPR1150_ACTIVATE) |
| After Submit | 60 | IMPR1150_REJECT EXECUTE-FUNCTION | `IMPR1150.EXEC_FUNS(P_FUNCTION_CODE => 'IMPR1150_REJECT', P_PORT_CD => :P1150_PORT_CD, P_IMPR_NBR => :P1150_IMPR_NBR, P_REJCT_RESON => :P1150_REJCT_RESON, P_CURR_PORT_CD => :P_CURR_PORT_CD, SSO_APP_USER => :SSO_APP_USER, P_GLOBAL_V_WS_ID => :P_GLOBAL_V_WS_ID);` | `:REQUEST = 'IMPR1150_REJECT'` | تم إيقاف تفعيل المستورد | PU EXECUTE_FUNCTION -> EXEC_FUNS(IMPR1150_REJECT), CR-7234 |

## 9. Computations

| Item | Point | Expression | Source |
|---|---|---|---|
| P1150_HIJRI_DATE_FORMAT | Before Header | `FORMS_APX.HIJRI_DATE_FORMAT` | Hijri date format from one place: Application Setting HIJRI_DATE_FORMAT |
| P1150_ADJ_FUNS | After Header | `IMPR1150.ADJ_FUNS(P_PENDING_ACTIVE => :P1150_PENDING_ACTIVE)` | PU ADJ_FUNS (IMPORTERS_CENTRAL.WHEN-NEW-RECORD-INSTANCE, KEY-F9): filter of the f345 Page Functions list |

## 10. Dynamic Actions (page 1150)

| DA | Event | Selection | Client condition | Fire on init | Actions (True / False) | Source |
|---|---|---|---|---|---|---|
| PRE-FORM | Page Load | - | - | Yes | T: Hide P1150_REJCT_RESON | FORM.PRE-FORM SET_ITEM_PROPERTY('REJCT_RESON', VISIBLE, PROPERTY_FALSE) |
| IMPR_NBR WHEN-VALIDATE-ITEM | Change | Item P1150_IMPR_NBR | not null | No | T: FOS `FORMS_APX.CHECK_ERROR(IMPR1150.IMPR_NBR_VALIDATION(P_PORT_CD => :P1150_PORT_CD, P_IMPR_NBR => :P1150_IMPR_NBR));` (submit P1150_IMPR_NBR, P1150_PORT_CD)<br>T: Submit Page request EXECUTE_QUERY | IMPORTERS_CENTRAL.IMPR_NBR.WHEN-VALIDATE-ITEM (+ :GLOBAL.EXEC_QUERY_NOW -> WHEN-NEW-ITEM-INSTANCE EXECUTE_QUERY) |
| BUS_ID WHEN-VALIDATE-ITEM | Change | Item P1150_BUS_ID | not null | No | T: FOS `FORMS_APX.CHECK_ERROR(IMPR1150.BUS_ID_VALIDATION(P_BUS_ID => :P1150_BUS_ID));` (submit P1150_BUS_ID)<br>T: Submit Page request EXECUTE_QUERY | IMPORTERS_CENTRAL.BUS_ID.WHEN-VALIDATE-ITEM (+ :GLOBAL.EXEC_QUERY_NOW -> WHEN-NEW-ITEM-INSTANCE EXECUTE_QUERY) |
| IMPR1150_ACTIVATE EXECUTE-FUNCTION | Custom: IMPR1150_ACTIVATE | document | - | No | T: Submit Page request IMPR1150_ACTIVATE | PU EXECUTE_FUNCTION / EXEC_FUNS(IMPR1150_ACTIVATE) - event of the f345 Page Functions list |
| IMPR1150_REJECT EXECUTE-FUNCTION | Custom: IMPR1150_REJECT | document | `$v('P1150_REJCT_RESON') === ''` | No | T: Hide P1150_IMPR_REJCT_RESON<br>T: Show P1150_REJCT_RESON<br>T: Alert "برجاء إدخال سبب الرفض"<br>T: Set Focus P1150_REJCT_RESON<br>F: Submit Page request IMPR1150_REJECT | PU EXEC_FUNS(IMPR1150_REJECT) CR-7234: no reason -> message + REJCT_RESON shown (true actions); reason entered -> request IMPR1150_REJECT (false action) |

Page 115001: DAs `SEARCH` (click → Refresh), `SEARCH KEY-ENTER` (keyup Enter → Refresh), `CLEAR WHEN-BUTTON-PRESSED`
(Clear + Refresh) and `Hide` (page 0 toolbar hidden in the dialog), as the other search pages. JavaScript actions: **0**.

## 11. Alerts and messages

| Forms | APEX |
|---|---|
| `STR.DispArbMsg(9, 150)` + RAISE (IMPR_NBR / BUS_ID) | error text of the validation / FOS (`FORMS_APX.ARABIC_MESSAGE(9, 150)`) |
| 'هذا السجل مدخل سابقاً - أعد ادخال البيانات' (CGUV$CHK_IMP_CNTRL_PK) | `IMPR_NBR_VALIDATION` |
| 'تم تفعيل المستورد' / 'تم إيقاف تفعيل المستورد' (DISPALERT ERROR, no raise) | success message of the function processes |
| 'برجاء إدخال سبب الرفض' (DISPALERT INFORMATION) | native Alert of the REJECT DA; error of `EXEC_FUNS` when sent without reason |
| 'برجاء استخدام وظيفة رفض تفعيل المستورد' (PRE-UPDATE) | `FORMS_APX.MESSAGE` in process PRE-UPDATE |
| refused CREATE / DELETE, disabled function | `PRE_INSERT` / `PRE_DELETE` / `EXEC_FUNS` (texts to agree) |

## 12. Branches and navigation

| Branch | Condition | Target |
|---|---|---|
| `EXECUTE-QUERY` (seq 10) | request EXECUTE_QUERY | page 1150, clear cache 1150, `P0_PAGE_PK` kept (set by process EXECUTE-QUERY) |
| `IMPR1150 - stay in the form` (seq 20) | – | page 1150, clear cache 1150 (REJCT_RESON reset), success message; Forms re-queries the record after REJECT |
| search grid link | – | page 1150, `P0_PAGE_PK` = IMPR_NBR (`P0_PAGE_PK_CHECK` checks it) |

## 13. Shared components

Reused: f345 theme, templates, page 0 (toolbar, FUNCS, NUMBER ONLY), application items `SSO_APP_USER`, `P_CURR_PORT_CD`,
`P_GLOBAL_V_WS_ID`; IMPR1110 export: page group `IMPR`, Application Setting `HIJRI_DATE_FORMAT`. New: LOVs
`LOV_PENDING_ACTIVE`, `LOV_IMPR_REJCT_RESON` (`LOV_APX.REFERENCE_CODES`, no LOV_APX change). The functions
`IMPR1150_ACTIVATE` / `IMPR1150_REJECT` must exist in `SC_SYSTEM_OBJECTS` under the screen IMPR1150 with
`SYS_OS_FILE_NAME` = the event name (f345 Page Functions list).

## 14. Traceability (every Forms object)


449 objects: DROPPED 367, MAPPED 79, TODO 3.

| # | Type | Forms object | APEX component | Page | Package member | Status | Notes |
|---|---|---|---|---|---|---|---|
| 1 | BLOCK | `TITLE` | REGION | IMPORTERS_CENTRAL_HERO | 1150 | - | MAPPED | OLB title bar -> f345 hero region (FORMS_APX.HEADER_TITLE) |
| 2 | BLOCK | `EDI_MSG` | - | - | - | - | DROPPED | OLB EDI message ticker - dropped (timers, IMPR1110 decision 2026-11-19) |
| 3 | BLOCK | `LSIDE` | REGION | FUNCS (page 0 drawer) | 0 | - | MAPPED | OLB side function menu -> page 0 FUNCS, f345 list Page Functions |
| 4 | BLOCK | `TOOLBAR` | REGION | P0_ACTIONS (page 0 toolbar, f345) | 0 | - | MAPPED | OLB toolbar -> f345 page 0 toolbar |
| 5 | BLOCK | `IMPORTERS_CENTRAL` | REGION | IMPORTERS_CENTRAL (Form, read-only, HQ table over the database link) | 1150 | - | MAPPED | QUERY_DATA_SOURCE_NAME CUSTOMS.IMPORTERS_CENTRAL@HQPRD.HQ.CUSTOMS.GOV, key IMPR_NBR |
| 6 | BLOCK | `IMPORTER_DOCS` | REGION | IMPORTER_DOCS (read-only IG) | 1150 | - | MAPPED | IMPORTERS_DOCS WHERE IMPR_NBR = :P1150_IMPR_NBR |
| 7 | ITEM | `TITLE.CGSO$CHECK_BOX_U` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 8 | ITEM | `TITLE.CGSO$CHAR_ARB_ED` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 9 | ITEM | `TITLE.CGSO$CHAR_ARB_DO_MLINE` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 10 | ITEM | `TITLE.CGSO$CHAR_ARB_ORA_LOV` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 11 | ITEM | `TITLE.CGSO$CHAR_ARB_DO_ENB_Y` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 12 | ITEM | `TITLE.CGSO$CHAR_ARB_MLINE` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 13 | ITEM | `TITLE.CGSO$CHAR_ARB` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 14 | ITEM | `TITLE.CGSO$CHAR_ARB_DO` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 15 | ITEM | `TITLE.SCREEN_NAME` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 16 | ITEM | `TITLE.USER_NAME` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 17 | ITEM | `TITLE.SYSTEM_DATE` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 18 | ITEM | `TITLE.VERSION` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 19 | ITEM | `EDI_MSG.EDI_MSG_TXT` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 20 | ITEM | `EDI_MSG.EDI_MSG_LOVE_BUT` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 21 | ITEM | `LSIDE.FN1` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 22 | ITEM | `LSIDE.FN50` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 23 | ITEM | `LSIDE.FN2` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 24 | ITEM | `LSIDE.FN49` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 25 | ITEM | `LSIDE.FN3` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 26 | ITEM | `LSIDE.FN48` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 27 | ITEM | `LSIDE.FN4` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 28 | ITEM | `LSIDE.FN47` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 29 | ITEM | `LSIDE.FN5` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 30 | ITEM | `LSIDE.FN46` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 31 | ITEM | `LSIDE.FN6` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 32 | ITEM | `LSIDE.FN45` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 33 | ITEM | `LSIDE.FN7` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 34 | ITEM | `LSIDE.FN44` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 35 | ITEM | `LSIDE.FN8` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 36 | ITEM | `LSIDE.FN43` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 37 | ITEM | `LSIDE.FN9` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 38 | ITEM | `LSIDE.FN42` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 39 | ITEM | `LSIDE.FN10` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 40 | ITEM | `LSIDE.FN41` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 41 | ITEM | `LSIDE.FN11` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 42 | ITEM | `LSIDE.FN40` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 43 | ITEM | `LSIDE.FN12` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 44 | ITEM | `LSIDE.FN39` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 45 | ITEM | `LSIDE.FN13` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 46 | ITEM | `LSIDE.FN38` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 47 | ITEM | `LSIDE.FN14` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 48 | ITEM | `LSIDE.FN37` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 49 | ITEM | `LSIDE.FN15` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 50 | ITEM | `LSIDE.FN36` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 51 | ITEM | `LSIDE.FN16` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 52 | ITEM | `LSIDE.FN17` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 53 | ITEM | `LSIDE.FN34` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 54 | ITEM | `LSIDE.FN35` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 55 | ITEM | `LSIDE.FN18` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 56 | ITEM | `LSIDE.FN33` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 57 | ITEM | `LSIDE.FN19` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 58 | ITEM | `LSIDE.FN32` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 59 | ITEM | `LSIDE.FN20` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 60 | ITEM | `LSIDE.FN31` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 61 | ITEM | `LSIDE.FN21` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 62 | ITEM | `LSIDE.FN30` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 63 | ITEM | `LSIDE.FN22` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 64 | ITEM | `LSIDE.FN29` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 65 | ITEM | `LSIDE.FN23` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 66 | ITEM | `LSIDE.FN28` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 67 | ITEM | `LSIDE.FN24` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 68 | ITEM | `LSIDE.FN27` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 69 | ITEM | `LSIDE.FN25` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 70 | ITEM | `LSIDE.FN26` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 71 | ITEM | `TOOLBAR.DUMMY` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 72 | ITEM | `TOOLBAR.SAVE` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 73 | ITEM | `TOOLBAR.CLEAR_ALL` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 74 | ITEM | `TOOLBAR.EXIT` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 75 | ITEM | `TOOLBAR.EXIT1` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 76 | ITEM | `TOOLBAR.ENTER` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 77 | ITEM | `TOOLBAR.EXECUTE` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 78 | ITEM | `TOOLBAR.REMOVE` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 79 | ITEM | `TOOLBAR.LIST_VALUE` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 80 | ITEM | `TOOLBAR.HELP` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 81 | ITEM | `TOOLBAR.LAST_REC` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 82 | ITEM | `TOOLBAR.RE_ENTER_QUERY` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 83 | ITEM | `TOOLBAR.FIRST_REC` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 84 | ITEM | `TOOLBAR.PAGE_UP` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 85 | ITEM | `TOOLBAR.PAGE_DOWN` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 86 | ITEM | `TOOLBAR.FUN_BUT` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 87 | ITEM | `IMPORTERS_CENTRAL.BIRTH_DT` | PAGE_ITEM | P1150_BIRTH_DT | 1150 | - | MAPPED | hidden |
| 88 | ITEM | `IMPORTERS_CENTRAL.PORT_CD` | PAGE_ITEM | P1150_PORT_CD | 1150 | - | MAPPED | hidden |
| 89 | ITEM | `IMPORTERS_CENTRAL.PENDING_ACTIVE` | PAGE_ITEM | P1150_PENDING_ACTIVE | 1150 | - | MAPPED | spec section 4 |
| 90 | ITEM | `IMPORTERS_CENTRAL.BUS_ID` | PAGE_ITEM | P1150_BUS_ID | 1150 | - | MAPPED | spec section 4 |
| 91 | ITEM | `IMPORTERS_CENTRAL.IMPR_NBR` | PAGE_ITEM | P1150_IMPR_NBR | 1150 | - | MAPPED | spec section 4 |
| 92 | ITEM | `IMPORTERS_CENTRAL.IMPR_TYPE_CD` | PAGE_ITEM | P1150_IMPR_TYPE_CD | 1150 | - | MAPPED | spec section 4 |
| 93 | ITEM | `IMPORTERS_CENTRAL.IMPR_TYPE_NAME` | PAGE_ITEM | P1150_IMPR_TYPE_NAME | 1150 | - | MAPPED | spec section 4 |
| 94 | ITEM | `IMPORTERS_CENTRAL.BUS_ID_BRNCH` | PAGE_ITEM | P1150_BUS_ID_BRNCH | 1150 | - | MAPPED | spec section 4 |
| 95 | ITEM | `IMPORTERS_CENTRAL.HQ_IMPR_NBR` | PAGE_ITEM | P1150_HQ_IMPR_NBR | 1150 | - | MAPPED | spec section 4 |
| 96 | ITEM | `IMPORTERS_CENTRAL.BUS_ID_EXPRD_DT` | PAGE_ITEM | P1150_BUS_ID_EXPRD_DT | 1150 | - | MAPPED | spec section 4 |
| 97 | ITEM | `IMPORTERS_CENTRAL.BUS_ID_TYPE_CD` | PAGE_ITEM | P1150_BUS_ID_TYPE_CD | 1150 | - | MAPPED | spec section 4 |
| 98 | ITEM | `IMPORTERS_CENTRAL.BUS_ID_TYPE_NAME` | PAGE_ITEM | P1150_BUS_ID_TYPE_NAME | 1150 | - | MAPPED | spec section 4 |
| 99 | ITEM | `IMPORTERS_CENTRAL.CTRY_CD` | PAGE_ITEM | P1150_CTRY_CD | 1150 | - | MAPPED | spec section 4 |
| 100 | ITEM | `IMPORTERS_CENTRAL.CRTY_ARBC_NAME` | PAGE_ITEM | P1150_CRTY_ARBC_NAME | 1150 | - | MAPPED | spec section 4 |
| 101 | ITEM | `IMPORTERS_CENTRAL.ARBC_IMPR_NAME` | PAGE_ITEM | P1150_ARBC_IMPR_NAME | 1150 | - | MAPPED | spec section 4 |
| 102 | ITEM | `IMPORTERS_CENTRAL.IMPR_ADDRESS` | PAGE_ITEM | P1150_IMPR_ADDRESS | 1150 | - | MAPPED | spec section 4 |
| 103 | ITEM | `IMPORTERS_CENTRAL.ADD_CTRY_CD` | PAGE_ITEM | P1150_ADD_CTRY_CD | 1150 | - | MAPPED | spec section 4 |
| 104 | ITEM | `IMPORTERS_CENTRAL.ADD_CRTY_ARBC_NAME` | PAGE_ITEM | P1150_ADD_CRTY_ARBC_NAME | 1150 | - | MAPPED | spec section 4 |
| 105 | ITEM | `IMPORTERS_CENTRAL.CITY_CODE` | PAGE_ITEM | P1150_CITY_CODE | 1150 | - | MAPPED | spec section 4 |
| 106 | ITEM | `IMPORTERS_CENTRAL.CITY_NAME` | PAGE_ITEM | P1150_CITY_NAME | 1150 | - | MAPPED | spec section 4 |
| 107 | ITEM | `IMPORTERS_CENTRAL.IMPR_TEL_NBR` | PAGE_ITEM | P1150_IMPR_TEL_NBR | 1150 | - | MAPPED | spec section 4 |
| 108 | ITEM | `IMPORTERS_CENTRAL.MOBILE_NO` | PAGE_ITEM | P1150_MOBILE_NO | 1150 | - | MAPPED | spec section 4 |
| 109 | ITEM | `IMPORTERS_CENTRAL.ACTIVITY` | PAGE_ITEM | P1150_ACTIVITY | 1150 | - | MAPPED | spec section 4 |
| 110 | ITEM | `IMPORTERS_CENTRAL.IMPR_REJCT_RESON` | PAGE_ITEM | P1150_IMPR_REJCT_RESON | 1150 | - | MAPPED | spec section 4 |
| 111 | ITEM | `IMPORTERS_CENTRAL.IMPR_REJCT_RESON2` | - | - | - | - | DROPPED | LOV button of IMPR_REJCT_RESON, an item that is never enterable |
| 112 | ITEM | `IMPORTERS_CENTRAL.REJCT_RESON` | PAGE_ITEM | P1150_REJCT_RESON | 1150 | - | MAPPED | spec section 4 |
| 113 | ITEM | `IMPORTER_DOCS.IMPR_NBR` | IG_COLUMN | IMPR_NBR (hidden) | 1150 | - | MAPPED | IMPORTER_DOCS grid |
| 114 | ITEM | `IMPORTER_DOCS.IMPR_DOC_SEQ` | IG_COLUMN | IMPR_DOC_ISN (primary key, hidden) | 1150 | - | MAPPED | IMPORTER_DOCS grid |
| 115 | ITEM | `IMPORTER_DOCS.DOC_NAME` | IG_COLUMN | DOC_NAME | 1150 | - | MAPPED | IMPORTER_DOCS grid |
| 116 | ITEM | `IMPORTER_DOCS.DOC_DESC` | IG_COLUMN | DOC_DESC | 1150 | - | MAPPED | IMPORTER_DOCS grid |
| 117 | ITEM | `IMPORTER_DOCS.DOC_PATH` | IG_COLUMN | DOC_PATH | 1150 | - | MAPPED | IMPORTER_DOCS grid |
| 118 | ITEM | `IMPORTER_DOCS.OPEN_DEC` | IG_COLUMN | DOC_FULL_NAME | 1150 | - | TODO | HOST(cmd /c START path\name) on the client PC has no web equivalent: full name shown; how to open the file to agree |
| 119 | TRIGGER | `FORM.KEY-EDIT` | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| 120 | TRIGGER | `FORM.KEY-DUPREC` | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| 121 | TRIGGER | `FORM.PRE-FORM` | DA | PRE-FORM | 1150 | - | MAPPED | REJCT_RESON hidden on page load; NIB / NLS date formats dropped |
| 122 | TRIGGER | `FORM.WHEN-NEW-FORM-INSTANCE` | REGION | IMPORTERS_CENTRAL region SQL (HQ table) | 1150 | - | MAPPED | SET_BLOCK_PROPERTY(QUERY_DATA_SOURCE_NAME) -> region source; globals reset = new page; NIB / versions dropped |
| 123 | TRIGGER | `FORM.WHEN-WINDOW-ACTIVATED` | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| 124 | TRIGGER | `FORM.KEY-ENTQRY` | PAGE | IMPR1150_SEARCH | 115001 | - | MAPPED | NIB.KEY_ENTQRY -> page 0 SEARCH |
| 125 | TRIGGER | `FORM.ON-ERROR` | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| 126 | TRIGGER | `FORM.ON-MESSAGE` | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| 127 | TRIGGER | `FORM.KEY-CLRBLK` | BUTTON | CLEAR (page 0 toolbar) | 0 | - | MAPPED | NIB.KEY_CLRBLK |
| 128 | TRIGGER | `FORM.KEY-DELREC` | PROCESS | PRE-DELETE | 1150 | IMPR1150.PRE_DELETE | MAPPED | Delete Allowed = false: request DELETE refused |
| 129 | TRIGGER | `FORM.KEY-F5` | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| 130 | TRIGGER | `FORM.KEY-F4` | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| 131 | TRIGGER | `FORM.KEY-NXTREC` | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| 132 | TRIGGER | `FORM.KEY-PRVREC` | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| 133 | TRIGGER | `FORM.KEY-DOWN` | REGION | IMPORTER_DOCS (query with the page) | 1150 | - | MAPPED | NIB.KEY_DOWN + DETIL_DATA: one record per page |
| 134 | TRIGGER | `FORM.KEY-UP` | REGION | IMPORTER_DOCS (query with the page) | 1150 | - | MAPPED | NIB.KEY_UP + DETIL_DATA: one record per page |
| 135 | TRIGGER | `FORM.KEY-SCRUP` | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| 136 | TRIGGER | `FORM.KEY-SCRDOWN` | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| 137 | TRIGGER | `FORM.KEY-PRINT` | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| 138 | TRIGGER | `FORM.KEY-EXIT` | BUTTON | BACK (page 0 toolbar) | 0 | - | MAPPED | NIB.KEY_EXIT |
| 139 | TRIGGER | `FORM.WHEN-MOUSE-DOWN` | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| 140 | TRIGGER | `FORM.KEY-EXEQRY` | REGION | IMPORTER_DOCS (query with the page) | 1150 | - | MAPPED | NIB.KEY_EXEQRY + DETIL_DATA |
| 141 | TRIGGER | `FORM.KEY-F9` | REGION | FUNCS (page 0) | 0 | ADJ_FUNS | MAPPED | functions menu; ADJ_FUNS -> P1150_ADJ_FUNS |
| 142 | TRIGGER | `FORM.WHEN-TIMER-EXPIRED` | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| 143 | TRIGGER | `FORM.KEY-HELP` | - | - | - | - | DROPPED | Designer help file (empty CG$HP_HFILE) |
| 144 | TRIGGER | `FORM.KEY-CLRFRM` | BUTTON | CLEAR (page 0 toolbar) | 0 | - | MAPPED | clear_form + CG$WHEN_NEW_FORM_INSTANCE (lists: shared LOVs) |
| 145 | TRIGGER | `TITLE.CGSO$CHAR_ARB_ED.KEY-LISTVAL` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 146 | TRIGGER | `TITLE.CGSO$CHAR_ARB_DO_ENB_Y.KEY-LISTVAL` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 147 | TRIGGER | `TITLE.CGSO$CHAR_ARB_MLINE.KEY-LISTVAL` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 148 | TRIGGER | `TITLE.CGSO$CHAR_ARB.KEY-LISTVAL` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 149 | TRIGGER | `TITLE.CGSO$CHAR_ARB_DO.KEY-LISTVAL` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 150 | TRIGGER | `TITLE.SYSTEM_DATE.WHEN-VALIDATE-ITEM` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 151 | TRIGGER | `EDI_MSG.EDI_MSG_LOVE_BUT.WHEN-BUTTON-PRESSED` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 152 | TRIGGER | `LSIDE.FN1.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 153 | TRIGGER | `LSIDE.FN1.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 154 | TRIGGER | `LSIDE.FN1.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 155 | TRIGGER | `LSIDE.FN50.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 156 | TRIGGER | `LSIDE.FN50.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 157 | TRIGGER | `LSIDE.FN50.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 158 | TRIGGER | `LSIDE.FN2.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 159 | TRIGGER | `LSIDE.FN2.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 160 | TRIGGER | `LSIDE.FN2.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 161 | TRIGGER | `LSIDE.FN49.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 162 | TRIGGER | `LSIDE.FN49.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 163 | TRIGGER | `LSIDE.FN49.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 164 | TRIGGER | `LSIDE.FN3.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 165 | TRIGGER | `LSIDE.FN3.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 166 | TRIGGER | `LSIDE.FN3.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 167 | TRIGGER | `LSIDE.FN48.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 168 | TRIGGER | `LSIDE.FN48.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 169 | TRIGGER | `LSIDE.FN48.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 170 | TRIGGER | `LSIDE.FN4.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 171 | TRIGGER | `LSIDE.FN4.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 172 | TRIGGER | `LSIDE.FN4.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 173 | TRIGGER | `LSIDE.FN47.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 174 | TRIGGER | `LSIDE.FN47.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 175 | TRIGGER | `LSIDE.FN47.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 176 | TRIGGER | `LSIDE.FN5.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 177 | TRIGGER | `LSIDE.FN5.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 178 | TRIGGER | `LSIDE.FN5.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 179 | TRIGGER | `LSIDE.FN46.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 180 | TRIGGER | `LSIDE.FN46.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 181 | TRIGGER | `LSIDE.FN46.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 182 | TRIGGER | `LSIDE.FN6.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 183 | TRIGGER | `LSIDE.FN6.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 184 | TRIGGER | `LSIDE.FN6.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 185 | TRIGGER | `LSIDE.FN45.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 186 | TRIGGER | `LSIDE.FN45.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 187 | TRIGGER | `LSIDE.FN45.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 188 | TRIGGER | `LSIDE.FN7.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 189 | TRIGGER | `LSIDE.FN7.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 190 | TRIGGER | `LSIDE.FN7.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 191 | TRIGGER | `LSIDE.FN44.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 192 | TRIGGER | `LSIDE.FN44.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 193 | TRIGGER | `LSIDE.FN44.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 194 | TRIGGER | `LSIDE.FN8.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 195 | TRIGGER | `LSIDE.FN8.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 196 | TRIGGER | `LSIDE.FN8.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 197 | TRIGGER | `LSIDE.FN43.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 198 | TRIGGER | `LSIDE.FN43.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 199 | TRIGGER | `LSIDE.FN43.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 200 | TRIGGER | `LSIDE.FN9.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 201 | TRIGGER | `LSIDE.FN9.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 202 | TRIGGER | `LSIDE.FN9.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 203 | TRIGGER | `LSIDE.FN42.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 204 | TRIGGER | `LSIDE.FN42.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 205 | TRIGGER | `LSIDE.FN42.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 206 | TRIGGER | `LSIDE.FN10.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 207 | TRIGGER | `LSIDE.FN10.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 208 | TRIGGER | `LSIDE.FN10.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 209 | TRIGGER | `LSIDE.FN41.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 210 | TRIGGER | `LSIDE.FN41.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 211 | TRIGGER | `LSIDE.FN41.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 212 | TRIGGER | `LSIDE.FN11.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 213 | TRIGGER | `LSIDE.FN11.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 214 | TRIGGER | `LSIDE.FN11.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 215 | TRIGGER | `LSIDE.FN40.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 216 | TRIGGER | `LSIDE.FN40.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 217 | TRIGGER | `LSIDE.FN40.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 218 | TRIGGER | `LSIDE.FN12.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 219 | TRIGGER | `LSIDE.FN12.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 220 | TRIGGER | `LSIDE.FN12.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 221 | TRIGGER | `LSIDE.FN39.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 222 | TRIGGER | `LSIDE.FN39.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 223 | TRIGGER | `LSIDE.FN39.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 224 | TRIGGER | `LSIDE.FN13.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 225 | TRIGGER | `LSIDE.FN13.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 226 | TRIGGER | `LSIDE.FN13.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 227 | TRIGGER | `LSIDE.FN38.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 228 | TRIGGER | `LSIDE.FN38.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 229 | TRIGGER | `LSIDE.FN38.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 230 | TRIGGER | `LSIDE.FN14.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 231 | TRIGGER | `LSIDE.FN14.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 232 | TRIGGER | `LSIDE.FN14.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 233 | TRIGGER | `LSIDE.FN37.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 234 | TRIGGER | `LSIDE.FN37.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 235 | TRIGGER | `LSIDE.FN37.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 236 | TRIGGER | `LSIDE.FN15.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 237 | TRIGGER | `LSIDE.FN15.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 238 | TRIGGER | `LSIDE.FN15.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 239 | TRIGGER | `LSIDE.FN36.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 240 | TRIGGER | `LSIDE.FN36.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 241 | TRIGGER | `LSIDE.FN36.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 242 | TRIGGER | `LSIDE.FN16.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 243 | TRIGGER | `LSIDE.FN16.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 244 | TRIGGER | `LSIDE.FN16.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 245 | TRIGGER | `LSIDE.FN17.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 246 | TRIGGER | `LSIDE.FN17.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 247 | TRIGGER | `LSIDE.FN17.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 248 | TRIGGER | `LSIDE.FN34.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 249 | TRIGGER | `LSIDE.FN34.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 250 | TRIGGER | `LSIDE.FN34.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 251 | TRIGGER | `LSIDE.FN35.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 252 | TRIGGER | `LSIDE.FN35.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 253 | TRIGGER | `LSIDE.FN35.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 254 | TRIGGER | `LSIDE.FN18.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 255 | TRIGGER | `LSIDE.FN18.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 256 | TRIGGER | `LSIDE.FN18.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 257 | TRIGGER | `LSIDE.FN33.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 258 | TRIGGER | `LSIDE.FN33.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 259 | TRIGGER | `LSIDE.FN33.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 260 | TRIGGER | `LSIDE.FN19.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 261 | TRIGGER | `LSIDE.FN19.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 262 | TRIGGER | `LSIDE.FN19.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 263 | TRIGGER | `LSIDE.FN32.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 264 | TRIGGER | `LSIDE.FN32.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 265 | TRIGGER | `LSIDE.FN32.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 266 | TRIGGER | `LSIDE.FN20.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 267 | TRIGGER | `LSIDE.FN20.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 268 | TRIGGER | `LSIDE.FN20.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 269 | TRIGGER | `LSIDE.FN31.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 270 | TRIGGER | `LSIDE.FN31.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 271 | TRIGGER | `LSIDE.FN31.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 272 | TRIGGER | `LSIDE.FN21.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 273 | TRIGGER | `LSIDE.FN21.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 274 | TRIGGER | `LSIDE.FN21.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 275 | TRIGGER | `LSIDE.FN30.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 276 | TRIGGER | `LSIDE.FN30.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 277 | TRIGGER | `LSIDE.FN30.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 278 | TRIGGER | `LSIDE.FN22.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 279 | TRIGGER | `LSIDE.FN22.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 280 | TRIGGER | `LSIDE.FN22.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 281 | TRIGGER | `LSIDE.FN29.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 282 | TRIGGER | `LSIDE.FN29.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 283 | TRIGGER | `LSIDE.FN29.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 284 | TRIGGER | `LSIDE.FN23.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 285 | TRIGGER | `LSIDE.FN23.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 286 | TRIGGER | `LSIDE.FN23.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 287 | TRIGGER | `LSIDE.FN28.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 288 | TRIGGER | `LSIDE.FN28.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 289 | TRIGGER | `LSIDE.FN28.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 290 | TRIGGER | `LSIDE.FN24.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 291 | TRIGGER | `LSIDE.FN24.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 292 | TRIGGER | `LSIDE.FN24.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 293 | TRIGGER | `LSIDE.FN27.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 294 | TRIGGER | `LSIDE.FN27.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 295 | TRIGGER | `LSIDE.FN27.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 296 | TRIGGER | `LSIDE.FN25.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 297 | TRIGGER | `LSIDE.FN25.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 298 | TRIGGER | `LSIDE.FN25.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 299 | TRIGGER | `LSIDE.FN26.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 300 | TRIGGER | `LSIDE.FN26.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 301 | TRIGGER | `LSIDE.FN26.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 302 | TRIGGER | `TOOLBAR.KEY-DOWN` | - | - | - | - | DROPPED | OLB frame block trigger (toolbar keys) |
| 303 | TRIGGER | `TOOLBAR.KEY-UP` | - | - | - | - | DROPPED | OLB frame block trigger (toolbar keys) |
| 304 | TRIGGER | `TOOLBAR.KEY-NEXT-ITEM` | - | - | - | - | DROPPED | OLB frame block trigger (toolbar keys) |
| 305 | TRIGGER | `TOOLBAR.SAVE.WHEN-BUTTON-PRESSED` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 306 | TRIGGER | `TOOLBAR.CLEAR_ALL.WHEN-BUTTON-PRESSED` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 307 | TRIGGER | `TOOLBAR.EXIT.WHEN-BUTTON-PRESSED` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 308 | TRIGGER | `TOOLBAR.EXIT1.WHEN-BUTTON-PRESSED` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 309 | TRIGGER | `TOOLBAR.ENTER.WHEN-BUTTON-PRESSED` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 310 | TRIGGER | `TOOLBAR.EXECUTE.WHEN-BUTTON-PRESSED` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 311 | TRIGGER | `TOOLBAR.REMOVE.WHEN-BUTTON-PRESSED` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 312 | TRIGGER | `TOOLBAR.LIST_VALUE.WHEN-BUTTON-PRESSED` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 313 | TRIGGER | `TOOLBAR.HELP.WHEN-BUTTON-PRESSED` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 314 | TRIGGER | `TOOLBAR.LAST_REC.WHEN-BUTTON-PRESSED` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 315 | TRIGGER | `TOOLBAR.RE_ENTER_QUERY.WHEN-BUTTON-PRESSED` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 316 | TRIGGER | `TOOLBAR.FIRST_REC.WHEN-BUTTON-PRESSED` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 317 | TRIGGER | `TOOLBAR.PAGE_UP.WHEN-BUTTON-PRESSED` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 318 | TRIGGER | `TOOLBAR.PAGE_DOWN.WHEN-BUTTON-PRESSED` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 319 | TRIGGER | `TOOLBAR.FUN_BUT.WHEN-MOUSE-UP` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 320 | TRIGGER | `TOOLBAR.FUN_BUT.WHEN-MOUSE-DOWN` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 321 | TRIGGER | `IMPORTERS_CENTRAL.ON-ERROR` | APP_ITEM | APEX error handling (FORMS_APX / f345) | - | - | MAPPED | no DML from the page: FRM-40508/9/10 messages and IC_NATIONALITY_FK cannot occur |
| 322 | TRIGGER | `IMPORTERS_CENTRAL.KEY-HELP` | - | - | - | - | DROPPED | Designer help file (empty CG$HP_HFILE) |
| 323 | TRIGGER | `IMPORTERS_CENTRAL.POST-QUERY` | PROCESS | POST-QUERY | 1150 | IMPR1150.POST_QUERY | MAPPED | Before Header after Initialize form |
| 324 | TRIGGER | `IMPORTERS_CENTRAL.PRE-QUERY` | PROCESS | EXECUTE-QUERY | 1150 | IMPR1150.IMPORTER_KEY | MAPPED | query key IMPR_NBR / BUS_ID, PORT_CD 99 |
| 325 | TRIGGER | `IMPORTERS_CENTRAL.PRE-UPDATE` | PROCESS | PRE-UPDATE | 1150 | IMPR1150.PRE_UPDATE | MAPPED | request SAVE: message only (no DML) |
| 326 | TRIGGER | `IMPORTERS_CENTRAL.WHEN-NEW-ITEM-INSTANCE` | BRANCH | EXECUTE-QUERY | 1150 | - | MAPPED | EXEC_QUERY_NOW -> DA Submit Page EXECUTE_QUERY + branch; docs grid queried with the page |
| 327 | TRIGGER | `IMPORTERS_CENTRAL.WHEN-NEW-RECORD-INSTANCE` | COMPUTATION | P1150_ADJ_FUNS | 1150 | IMPR1150.ADJ_FUNS | MAPPED | ADJ_FUNS |
| 328 | TRIGGER | `IMPORTERS_CENTRAL.PORT_CD.KEY-LISTVAL` | - | - | - | - | DROPPED | Designer "may the LOV be shown" check: APEX shows a list only on an enterable item |
| 329 | TRIGGER | `IMPORTERS_CENTRAL.PENDING_ACTIVE.KEY-LISTVAL` | - | - | - | - | DROPPED | Designer "may the LOV be shown" check: APEX shows a list only on an enterable item |
| 330 | TRIGGER | `IMPORTERS_CENTRAL.BUS_ID.KEY-LISTVAL` | - | - | - | - | DROPPED | Designer "may the LOV be shown" check: APEX shows a list only on an enterable item |
| 331 | TRIGGER | `IMPORTERS_CENTRAL.BUS_ID.WHEN-VALIDATE-ITEM` | VALIDATION | BUS_ID VALIDATION + DA BUS_ID WHEN-VALIDATE-ITEM | 1150 | IMPR1150.BUS_ID_VALIDATION | MAPPED | message 9-150 |
| 332 | TRIGGER | `IMPORTERS_CENTRAL.IMPR_NBR.KEY-LISTVAL` | - | - | - | - | DROPPED | Designer "may the LOV be shown" check: APEX shows a list only on an enterable item |
| 333 | TRIGGER | `IMPORTERS_CENTRAL.IMPR_NBR.WHEN-VALIDATE-ITEM` | VALIDATION | IMPR_NBR VALIDATION + DA IMPR_NBR WHEN-VALIDATE-ITEM | 1150 | IMPR1150.IMPR_NBR_VALIDATION | MAPPED | message 9-150; CGUV$CHK_IMP_CNTRL_PK |
| 334 | TRIGGER | `IMPORTERS_CENTRAL.IMPR_TYPE_CD.KEY-LISTVAL` | - | - | - | - | DROPPED | Designer "may the LOV be shown" check: APEX shows a list only on an enterable item |
| 335 | TRIGGER | `IMPORTERS_CENTRAL.IMPR_TYPE_NAME.KEY-LISTVAL` | - | - | - | - | DROPPED | Designer "may the LOV be shown" check: APEX shows a list only on an enterable item |
| 336 | TRIGGER | `IMPORTERS_CENTRAL.BUS_ID_BRNCH.KEY-LISTVAL` | - | - | - | - | DROPPED | Designer "may the LOV be shown" check: APEX shows a list only on an enterable item |
| 337 | TRIGGER | `IMPORTERS_CENTRAL.HQ_IMPR_NBR.KEY-LISTVAL` | - | - | - | - | DROPPED | Designer "may the LOV be shown" check: APEX shows a list only on an enterable item |
| 338 | TRIGGER | `IMPORTERS_CENTRAL.BUS_ID_EXPRD_DT.WHEN-VALIDATE-ITEM` | - | - | - | - | DROPPED | item never enterable (Insert / Update Allowed = false): the check cannot fire |
| 339 | TRIGGER | `IMPORTERS_CENTRAL.BUS_ID_TYPE_CD.KEY-LISTVAL` | - | - | - | - | DROPPED | Designer "may the LOV be shown" check: APEX shows a list only on an enterable item |
| 340 | TRIGGER | `IMPORTERS_CENTRAL.BUS_ID_TYPE_NAME.KEY-LISTVAL` | - | - | - | - | DROPPED | Designer "may the LOV be shown" check: APEX shows a list only on an enterable item |
| 341 | TRIGGER | `IMPORTERS_CENTRAL.CTRY_CD.KEY-LISTVAL` | - | - | - | - | DROPPED | Designer "may the LOV be shown" check: APEX shows a list only on an enterable item |
| 342 | TRIGGER | `IMPORTERS_CENTRAL.CRTY_ARBC_NAME.KEY-LISTVAL` | - | - | - | - | DROPPED | Designer "may the LOV be shown" check: APEX shows a list only on an enterable item |
| 343 | TRIGGER | `IMPORTERS_CENTRAL.ARBC_IMPR_NAME.KEY-LISTVAL` | - | - | - | - | DROPPED | Designer "may the LOV be shown" check: APEX shows a list only on an enterable item |
| 344 | TRIGGER | `IMPORTERS_CENTRAL.IMPR_ADDRESS.KEY-LISTVAL` | - | - | - | - | DROPPED | Designer "may the LOV be shown" check: APEX shows a list only on an enterable item |
| 345 | TRIGGER | `IMPORTERS_CENTRAL.ADD_CTRY_CD.KEY-LISTVAL` | - | - | - | - | DROPPED | Designer "may the LOV be shown" check: APEX shows a list only on an enterable item |
| 346 | TRIGGER | `IMPORTERS_CENTRAL.ADD_CRTY_ARBC_NAME.KEY-LISTVAL` | - | - | - | - | DROPPED | Designer "may the LOV be shown" check: APEX shows a list only on an enterable item |
| 347 | TRIGGER | `IMPORTERS_CENTRAL.CITY_CODE.KEY-LISTVAL` | - | - | - | - | DROPPED | Designer "may the LOV be shown" check: APEX shows a list only on an enterable item |
| 348 | TRIGGER | `IMPORTERS_CENTRAL.CITY_NAME.KEY-LISTVAL` | - | - | - | - | DROPPED | Designer "may the LOV be shown" check: APEX shows a list only on an enterable item |
| 349 | TRIGGER | `IMPORTERS_CENTRAL.IMPR_TEL_NBR.KEY-LISTVAL` | - | - | - | - | DROPPED | Designer "may the LOV be shown" check: APEX shows a list only on an enterable item |
| 350 | TRIGGER | `IMPORTERS_CENTRAL.MOBILE_NO.KEY-LISTVAL` | - | - | - | - | DROPPED | Designer "may the LOV be shown" check: APEX shows a list only on an enterable item |
| 351 | TRIGGER | `IMPORTERS_CENTRAL.ACTIVITY.KEY-LISTVAL` | - | - | - | - | DROPPED | Designer "may the LOV be shown" check: APEX shows a list only on an enterable item |
| 352 | TRIGGER | `IMPORTERS_CENTRAL.IMPR_REJCT_RESON.KEY-LISTVAL` | - | - | - | - | DROPPED | Designer "may the LOV be shown" check: APEX shows a list only on an enterable item |
| 353 | TRIGGER | `IMPORTERS_CENTRAL.IMPR_REJCT_RESON2.WHEN-BUTTON-PRESSED` | - | - | - | - | DROPPED | LOV of a non-enterable item (do_key LIST_VALUES) |
| 354 | TRIGGER | `IMPORTERS_CENTRAL.REJCT_RESON.KEY-LISTVAL` | - | - | - | - | DROPPED | Designer "may the LOV be shown" check: APEX shows a list only on an enterable item |
| 355 | TRIGGER | `IMPORTER_DOCS.ON-ERROR` | APP_ITEM | APEX error handling (FORMS_APX / f345) | - | - | MAPPED | query only |
| 356 | TRIGGER | `IMPORTER_DOCS.KEY-HELP` | - | - | - | - | DROPPED | Designer help file (empty CG$HP_HFILE) |
| 357 | TRIGGER | `IMPORTER_DOCS.DOC_NAME.KEY-LISTVAL` | - | - | - | - | DROPPED | Designer "may the LOV be shown" check: APEX shows a list only on an enterable item |
| 358 | TRIGGER | `IMPORTER_DOCS.DOC_DESC.KEY-LISTVAL` | - | - | - | - | DROPPED | Designer "may the LOV be shown" check: APEX shows a list only on an enterable item |
| 359 | TRIGGER | `IMPORTER_DOCS.DOC_PATH.KEY-LISTVAL` | - | - | - | - | DROPPED | Designer "may the LOV be shown" check: APEX shows a list only on an enterable item |
| 360 | TRIGGER | `IMPORTER_DOCS.OPEN_DEC.WHEN-BUTTON-PRESSED` | IG_COLUMN | DOC_FULL_NAME | 1150 | - | TODO | OPEN_FILE_DOS: HOST on the client PC; open the document - to agree |
| 361 | PROGRAM_UNIT | `CHECK_TIMEOUT` | - | - | - | - | DROPPED | NIB wrapper not called by active code (timers, EDI ticker, window, print) |
| 362 | PROGRAM_UNIT | `MOUSE_CLICK` | REGION | FUNCS (page 0) | 0 | - | MAPPED | function list click |
| 363 | PROGRAM_UNIT | `TOGGEL_WND` | - | - | - | - | DROPPED | NIB wrapper not called by active code (timers, EDI ticker, window, print) |
| 364 | PROGRAM_UNIT | `PRINT_REPORT` | - | - | - | - | DROPPED | NIB wrapper not called by active code (timers, EDI ticker, window, print) |
| 365 | PROGRAM_UNIT | `EXECUTE_FUNCTION` | REGION | FUNCS (page 0) | 0 | - | MAPPED | f345 Page Functions -> custom events IMPR1150_ACTIVATE / IMPR1150_REJECT |
| 366 | PROGRAM_UNIT | `TERMINATE_FUN` | - | - | - | - | DROPPED | NIB wrapper not called by active code (timers, EDI ticker, window, print) |
| 367 | PROGRAM_UNIT | `CHECK_EDI_MSG_LOV` | - | - | - | - | DROPPED | NIB wrapper not called by active code (timers, EDI ticker, window, print) |
| 368 | PROGRAM_UNIT | `CHECK_EDI_MSG_TIMER` | - | - | - | - | DROPPED | NIB wrapper not called by active code (timers, EDI ticker, window, print) |
| 369 | PROGRAM_UNIT | `CHECK_EDI_ROLE_ID` | - | - | - | - | DROPPED | NIB wrapper not called by active code (timers, EDI ticker, window, print) |
| 370 | PROGRAM_UNIT | `EDI_MSG_LOV` | - | - | - | - | DROPPED | NIB wrapper not called by active code (timers, EDI ticker, window, print) |
| 371 | PROGRAM_UNIT | `FOR_EDI_MSG` | - | - | - | - | DROPPED | NIB wrapper not called by active code (timers, EDI ticker, window, print) |
| 372 | PROGRAM_UNIT | `RETURN_MSG` | - | - | - | - | DROPPED | NIB wrapper not called by active code (timers, EDI ticker, window, print) |
| 373 | PROGRAM_UNIT | `TURN_MSG` | - | - | - | - | DROPPED | NIB wrapper not called by active code (timers, EDI ticker, window, print) |
| 374 | PROGRAM_UNIT | `WHEN_TIMER_EXPIRED_MSG` | - | - | - | - | DROPPED | NIB wrapper not called by active code (timers, EDI ticker, window, print) |
| 375 | PROGRAM_UNIT | `CG$WHEN_NEW_FORM_INSTANCE` | - | - | - | - | DROPPED | lists -> shared LOVs |
| 376 | PROGRAM_UNIT | `CGDV$POPULATE_DYNAMIC_LISTS` | LOV | LOV_PENDING_ACTIVE | 1150 | - | MAPPED | LOV_APX.REFERENCE_CODES(PENDING_ACTIVE) |
| 377 | PROGRAM_UNIT | `CGUV$CHK_IMP_CNTRL_PK` | VALIDATION | IMPR_NBR VALIDATION | 1150 | IMPR1150.IMPR_NBR_VALIDATION | MAPPED | local key check |
| 378 | PROGRAM_UNIT | `CGTE$CHECK_CONSTRAINT_VIO` | APP_ITEM | APEX error handling (FORMS_APX / f345) | - | - | MAPPED | no DML from the page |
| 379 | PROGRAM_UNIT | `OPEN_FILE_DOS` | IG_COLUMN | DOC_FULL_NAME | 1150 | - | TODO | HOST on the client PC: to agree |
| 380 | PROGRAM_UNIT | `EXEC_FUNS` | PROCESS | IMPR1150_ACTIVATE / IMPR1150_REJECT EXECUTE-FUNCTION | 1150 | IMPR1150.EXEC_FUNS | MAPPED | HQ UPDATE over the database link + ACTIVITY_DB; REJECT first press = DA |
| 381 | PROGRAM_UNIT | `DETIL_DATA` | REGION | IMPORTER_DOCS | 1150 | - | MAPPED | grid query WHERE IMPR_NBR = :P1150_IMPR_NBR (empty without importer) |
| 382 | PROGRAM_UNIT | `ADJ_FUNS` | COMPUTATION | P1150_ADJ_FUNS | 1150 | IMPR1150.ADJ_FUNS | MAPPED | TMPLT.ENABLE_FUN / DISABLE_FUN |
| 383 | LOV | `CGDV$IMPORTERS_CENTRAL_IMPR_RE` | LOV | LOV_IMPR_REJCT_RESON | 1150 | - | MAPPED | LOV_APX.REFERENCE_CODES(IMPR_REJCT_RESON) |
| 384 | RECORD_GROUP | `CGDV$IMPR_REJCT_RESON` | LOV | LOV_IMPR_REJCT_RESON | 1150 | - | MAPPED | CG_REF_CODES domain IMPR_REJCT_RESON |
| 385 | RECORD_GROUP | `CGDV$DLRG (runtime)` | LOV | LOV_PENDING_ACTIVE | 1150 | - | MAPPED | CREATE_GROUP_FROM_QUERY CG_REF_CODES PENDING_ACTIVE |
| 386 | ALERT | `USR_CONFIRM_B` | - | - | - | - | DROPPED | OLB alert not referenced by this form |
| 387 | ALERT | `USR_CONFIRM` | - | - | - | - | DROPPED | OLB alert not referenced by this form |
| 388 | ALERT | `USR_WARNING_C` | - | - | - | - | DROPPED | OLB alert not referenced by this form |
| 389 | ALERT | `USR_WARNING_B` | - | - | - | - | DROPPED | OLB alert not referenced by this form |
| 390 | ALERT | `CFG_WARNING_A` | - | - | - | - | DROPPED | OLB alert not referenced by this form |
| 391 | ALERT | `CFG_INFORMATION` | APP_ITEM | page messages (FORMS_APX.FORM_TRIGGER_FAILURE / MESSAGE) | - | - | MAPPED | STR.DISPALERT |
| 392 | ALERT | `CFG_ERROR` | APP_ITEM | page messages (FORMS_APX.FORM_TRIGGER_FAILURE / MESSAGE) | - | - | MAPPED | STR.DISPALERT |
| 393 | ALERT | `CFG_SYSTEM_ERROR` | - | - | - | - | DROPPED | OLB alert not referenced by this form |
| 394 | ALERT | `CFG_ASK_COMMIT` | - | - | - | - | DROPPED | OLB alert not referenced by this form |
| 395 | PARAMETER | `P_SHPG_AGNT_NBR` | - | - | - | - | DROPPED | used only by the OLB frame (EXECUTE_FUNCTION parameter list, print, EDI) |
| 396 | PARAMETER | `P_CTRL_LAST_EXEC_CD` | - | - | - | - | DROPPED | used only by the OLB frame (EXECUTE_FUNCTION parameter list, print, EDI) |
| 397 | PARAMETER | `P_BANK_CD` | - | - | - | - | DROPPED | used only by the OLB frame (EXECUTE_FUNCTION parameter list, print, EDI) |
| 398 | PARAMETER | `P_BANK_BRNCH_CD` | - | - | - | - | DROPPED | used only by the OLB frame (EXECUTE_FUNCTION parameter list, print, EDI) |
| 399 | PARAMETER | `P_BRKR_PORT_CD` | - | - | - | - | DROPPED | used only by the OLB frame (EXECUTE_FUNCTION parameter list, print, EDI) |
| 400 | PARAMETER | `P_LIC_TYPE` | - | - | - | - | DROPPED | used only by the OLB frame (EXECUTE_FUNCTION parameter list, print, EDI) |
| 401 | PARAMETER | `P_BRKR_NBR` | - | - | - | - | DROPPED | used only by the OLB frame (EXECUTE_FUNCTION parameter list, print, EDI) |
| 402 | PARAMETER | `P_CLASS_CD` | - | - | - | - | DROPPED | used only by the OLB frame (EXECUTE_FUNCTION parameter list, print, EDI) |
| 403 | PARAMETER | `P_JOB_ID` | - | - | - | - | DROPPED | used only by the OLB frame (EXECUTE_FUNCTION parameter list, print, EDI) |
| 404 | PARAMETER | `P_CURRENT_ITEM` | - | - | - | - | DROPPED | used only by the OLB frame (EXECUTE_FUNCTION parameter list, print, EDI) |
| 405 | PARAMETER | `P_GROUP_CD` | - | - | - | - | DROPPED | used only by the OLB frame (EXECUTE_FUNCTION parameter list, print, EDI) |
| 406 | PARAMETER | `P_USER_TYPE` | - | - | - | - | DROPPED | used only by the OLB frame (EXECUTE_FUNCTION parameter list, print, EDI) |
| 407 | PARAMETER | `P_PORT_TYPE` | - | - | - | - | DROPPED | used only by the OLB frame (EXECUTE_FUNCTION parameter list, print, EDI) |
| 408 | PARAMETER | `P_CURR_PORT_CD` | APP_ITEM | P_CURR_PORT_CD (f345) | - | - | MAPPED | block WHERE clause, activity port |
| 409 | PARAMETER | `P_MODULE_ID` | PAGE_ITEM | P1150_MODULE_ID | 1150 | - | MAPPED | FORMS_APX.GET_MODULE_ID |
| 410 | PARAMETER | `P_MODULE_NAME` | - | - | - | - | DROPPED | used only by the OLB frame (EXECUTE_FUNCTION parameter list, print, EDI) |
| 411 | PARAMETER | `P_APPLICATION_NAME` | - | - | - | - | DROPPED | used only by the OLB frame (EXECUTE_FUNCTION parameter list, print, EDI) |
| 412 | PARAMETER | `P_USER_ID` | APP_ITEM | SSO_APP_USER (f345) | - | - | MAPPED | activity log |
| 413 | PARAMETER | `P_WS_ID` | APP_ITEM | P_GLOBAL_V_WS_ID (f345) | - | - | MAPPED | activity log |
| 414 | PARAMETER | `P_USER_NAME` | - | - | - | - | DROPPED | used only by the OLB frame (EXECUTE_FUNCTION parameter list, print, EDI) |
| 415 | PARAMETER | `CG$STARTUP_MODE` | - | - | - | - | DROPPED | used only by the OLB frame (EXECUTE_FUNCTION parameter list, print, EDI) |
| 416 | CANVAS | `LSIDE` | - | - | - | - | DROPPED | OLB frame canvas |
| 417 | CANVAS | `EDI_MSG` | - | - | - | - | DROPPED | OLB frame canvas |
| 418 | CANVAS | `TITLE` | - | - | - | - | DROPPED | OLB frame canvas |
| 419 | CANVAS | `TOOLBAR` | - | - | - | - | DROPPED | OLB frame canvas |
| 420 | CANVAS | `CG$PAGE_1` | PAGE | IMPR1150 | 1150 | - | MAPPED | regions IMPORTERS_CENTRAL, IMPORTER_DOCS |
| 421 | WINDOW | `CGSO$WINDOW_1` | PAGE | IMPR1150 | 1150 | - | MAPPED | one page |
| 422 | LIBRARY | `OFGTEL` | - | - | - | - | DROPPED | frame / client library (windows, timers, help, DLLs) |
| 423 | LIBRARY | `OFGMES` | - | - | - | - | DROPPED | frame / client library (windows, timers, help, DLLs) |
| 424 | LIBRARY | `OFGHPL` | - | - | - | - | DROPPED | frame / client library (windows, timers, help, DLLs) |
| 425 | LIBRARY | `CIC_AMSG` | - | - | - | - | DROPPED | frame / client library (windows, timers, help, DLLs) |
| 426 | LIBRARY | `SEC_LIB` | - | - | - | - | DROPPED | frame / client library (windows, timers, help, DLLs) |
| 427 | LIBRARY | `CAPTION` | - | - | - | - | DROPPED | frame / client library (windows, timers, help, DLLs) |
| 428 | LIBRARY | `OFGBSL` | - | - | - | - | DROPPED | frame / client library (windows, timers, help, DLLs) |
| 429 | LIBRARY | `D2KWUTIL` | - | - | - | - | DROPPED | frame / client library (windows, timers, help, DLLs) |
| 430 | LIBRARY | `CUSTOMDLL` | - | - | - | - | DROPPED | frame / client library (windows, timers, help, DLLs) |
| 431 | LIBRARY | `D2KWUTIL_PDF` | - | - | - | - | DROPPED | frame / client library (windows, timers, help, DLLs) |
| 432 | LIBRARY | `GETCOMP` | - | - | - | - | DROPPED | frame / client library (windows, timers, help, DLLs) |
| 433 | LIBRARY | `OFGTAB` | - | - | - | - | DROPPED | frame / client library (windows, timers, help, DLLs) |
| 434 | LIBRARY | `PICKLIST` | - | - | - | - | DROPPED | frame / client library (windows, timers, help, DLLs) |
| 435 | LIBRARY | `POS` | - | - | - | - | DROPPED | frame / client library (windows, timers, help, DLLs) |
| 436 | LIBRARY | `SCDLL` | - | - | - | - | DROPPED | frame / client library (windows, timers, help, DLLs) |
| 437 | LIBRARY | `VCDLL` | - | - | - | - | DROPPED | frame / client library (windows, timers, help, DLLs) |
| 438 | LIBRARY | `CIC_LIB` | PACKAGE | FORMS_APX / ACTIVITY_DB | - | - | MAPPED | STR -> FORMS_APX, ACTIVITY -> ACTIVITY_DB, TMPLT -> FUNCS |
| 439 | GLOBAL | `BUS_ID` | PROCESS | EXECUTE-QUERY | 1150 | IMPR1150.IMPORTER_KEY | MAPPED | query key passed by the request EXECUTE_QUERY |
| 440 | GLOBAL | `IMPR_NBR` | PROCESS | EXECUTE-QUERY | 1150 | IMPR1150.IMPORTER_KEY | MAPPED | query key passed by the request EXECUTE_QUERY |
| 441 | GLOBAL | `PORT_CD` | PROCESS | EXECUTE-QUERY | 1150 | IMPR1150.IMPORTER_KEY | MAPPED | query key passed by the request EXECUTE_QUERY |
| 442 | GLOBAL | `EXEC_QUERY_NOW` | PROCESS | EXECUTE-QUERY | 1150 | IMPR1150.IMPORTER_KEY | MAPPED | query key passed by the request EXECUTE_QUERY |
| 443 | GLOBAL | `CG$HP_HFILE` | - | - | - | - | DROPPED | help / screen version / frame |
| 444 | GLOBAL | `CG$HP_HPATH` | - | - | - | - | DROPPED | help / screen version / frame |
| 445 | GLOBAL | `CURRENT_DT` | - | - | - | - | DROPPED | help / screen version / frame |
| 446 | GLOBAL | `CURRENT_VER` | - | - | - | - | DROPPED | help / screen version / frame |
| 447 | GLOBAL | `CURRENT_VERSION` | - | - | - | - | DROPPED | help / screen version / frame |
| 448 | GLOBAL | `EXIT` | - | - | - | - | DROPPED | help / screen version / frame |
| 449 | GLOBAL | `SYSTEM_OBJ` | - | - | - | - | DROPPED | help / screen version / frame |
