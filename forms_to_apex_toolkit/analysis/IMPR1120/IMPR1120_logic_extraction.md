# IMPR1120 — Logic extraction (step 02, revision 1)

| Item | Value |
|---|---|
| Form | `IMPR1120.fmb` — "صيانة توقيفات المستوردين" (Importer Suspension Maintenance) |
| Date | 2026-11-23 |
| Input | `analysis/IMPR1120/IMPR1120_inventory.md` (step 01), `forms/IMPR/IMPR1120_fmb.xml`, `forms/COMMON/libraries/CIC_LIB.pld`, `forms/SC/APPS_fmb.xml` |
| Standard | CLAUDE.md §3.2, §4, §4a–§4c, §6, §7; `docs/f345_reference_standard.md` §5, §6, §9, §10; prompt 02 rules 1–15 |
| Package | `LIB_APX_USR.IMPR1120`, version **001** described here (kept in `rollback/IMPR1120/step02_v001/`). The current files [impr1120_spec.sql](../../plsql/IMPR1120/impr1120_spec.sql) / [impr1120_body.sql](../../plsql/IMPR1120/impr1120_body.sql) are **002**: step 03 changed the dates to MI-MM-RRRR text, made the column validations skip unchanged values, and added `PRE_DELETE`, `IMPR_SUSPN_SAVE_ROW` and `SUSPN_RSN_TEXT_DEFAULT` ([page spec §16](IMPR1120_apex_page_spec.md)) |
| Pages (assumed) | main page **1120** (`IMPR1120`), search page **112001** (`IMPR1120_SEARCH`), the same numbering as IMPR1110 → 1110. To be registered in `MIG_FORM_REGISTRY` in step 03 |
| Status | **NOT COMPILED** (no 12.1.0.2 / APEX 21.2 instance in this session). The structural self-check passed (§9) |

## 0. Summary

- **33 public members** (5 f345 helpers, 2 form level, 7 IMPORTERS, 14 IMPR_SUSPN, 4 program units) and **7 private helpers**. The longest member is 65 lines.
- **APEX page shape (input for step 03):**
  - Form region `IMPORTERS`, read only, keyed by the importer ROWID in `P0_PAGE_PK` (as IMPR1110).
  - Editable IG `IMPR_SUSPN` on `IMPR_SUSPNS WHERE SUSPN_RLSE_DT IS NULL`, master key `PORT_CD` + `IMPR_NBR`.
  - Search page 112001.
- **Business rules kept:**
  - Defaults, allowed reasons and allowed sides per site (`CURRENT_SIDE`).
  - Rows of another site are read only.
  - `SUSPN_SIDE_CD` is fixed once stored.
  - Start date ≥ today and end date ≥ start (Hijri, messages 9-100 / 9-110).
  - Importer must exist in the port (9-150).
  - `SUSPN_SEQ` = MAX + 1.
  - Activity log on insert / update / delete.
  - PRE-UPDATE release-date rule.
  - Soft delete.
  - SMS / notification after insert.
- **Changed, and why:**

| Change | Reason |
|---|---|
| `STANDARD.COMMIT` in POST-INSERT removed; the COMMITs of `TMPLT.KEY_DELETE_RECORD` and TOOLBAR.SAVE are not carried over | CLAUDE.md §6 / prompt rule 10: APEX commits at the end of the request. **HIGH**: see §8 #1 |
| Rejections of a reason or side now return an error text, and the value is no longer reset | An APEX validation needs a text. The texts are placeholders to agree (§8 #3) |
| New server check `check_row_of_current_site` in PRE-UPDATE / ON-DELETE | Forms made these rows unreachable with `NEXT_RECORD`. A browser request is not limited by navigation, so the same restriction is enforced on the server |
| `:GLOBAL.Exec_Query_Now / PORT_CD / IMPR_NBR` replaced by `P0_PAGE_PK` | f345 page key standard |
| Designer dynamic WHERE (string concatenation) replaced by bind filters | CLAUDE.md §6 #9 |

## 1. Trigger classification

Group names from prompt 02. "Member / target" is the package member, the APEX component, or *dropped* with the reason.

### 1.1 Form level (33 triggers)

| Trigger | Group | Member / target |
|---|---|---|
| PRE-FORM | INITIALISATION | **dropped**: `NIB.PRE_FORM` (f345 shell), `SET_APPLICATION_PROPERTY` / `FORMS_DDL('ALTER SESSION SET NLS_DATE_FORMAT…')` → f345 Globalization attributes, `CGHP$PRE_FORM` help path (obsolete) |
| WHEN-NEW-FORM-INSTANCE | INITIALISATION | split: the site check → `INIT_FORM` (process `WHEN-NEW-FORM-INSTANCE`); PORT_CD insert / update for port 99 → `PORT_CD_IS_READ_ONLY`; PORT_CD value → `IMPORTERS_WHEN_CREATE_RECORD`; `:global.current_ver / current_DT` (version stamps), `Exec_Query_Now / PORT_CD / IMPR_NBR := NULL` → dropped (replaced by `P0_PAGE_PK`); `NIB.WHEN_NEW_FORM_INSTANCE`, `CGBS2$.SET_COORD_STYLE / SET_QRY_ON_ENTRY`, `CG$WHEN_NEW_FORM_INSTANCE` (lists from CG_REF_CODES, block-sync startup) → f345 shell / shared LOVs / native master-detail |
| WHEN-NEW-BLOCK-INSTANCE, ON-CLEAR-DETAILS, ON-POPULATE-DETAILS | NAVIGATION | **dropped**: Designer master-detail coordination (`CGBS$`) → native Form + IG master-detail |
| KEY-CQUERY, KEY-CLRREC, KEY-NXTKEY, KEY-MENU, KEY-CLRFRM | NAVIGATION | **dropped**: Designer count-query, clear-record commit dialogue, "key not valid", query-mode toggle, clear form → page 0 toolbar `CLEAR` / IG |
| KEY-HELP | UI-ONLY | **dropped**: MS-Help (`CGHP$CALL_MS_HELP`) |
| KEY-F9 | UI-ONLY | **dropped**: side-menu toggle (`TMPLT.POPULATE_FUNCTIONS`, `ADJ_FUNS` empty) → page 0 `FUNCS` |
| ON-ERROR, ON-MESSAGE | UI-ONLY | **dropped**: `NIB.ON_ERROR / ON_MESSAGE` → f345 `APP_ERROR_HANDLER` |
| WHEN-TIMER-EXPIRED, WHEN-WINDOW-ACTIVATED, WHEN-MOUSE-DOWN | UI-ONLY | **dropped**: timers / window (IMPR1110 decision of 2026-11-19, to confirm for IMPR1120) |
| KEY-EDIT, KEY-DUPREC, KEY-ENTQRY, KEY-CLRBLK, KEY-DELREC, KEY-F5, KEY-NXTREC, KEY-PRVREC, KEY-DOWN, KEY-UP, KEY-SCRUP, KEY-SCRDOWN, KEY-PRINT, KEY-EXIT, KEY-EXEQRY (15) | NAVIGATION | **dropped**: one-line `NIB.KEY_*` delegations → page 0 toolbar (`SEARCH`, `CLEAR`, `DELETE`, `BACK`) and IG keyboard |
| KEY-F4 (OLB) | NAVIGATION | **dropped**: OLB frame |

### 1.2 Block TOOLBAR, TITLE, EDI_MSG, LSIDE (OLB frame)

| Triggers | Group | Member / target |
|---|---|---|
| TOOLBAR KEY-DOWN / KEY-UP / KEY-NEXT-ITEM, FUN_BUT WHEN-MOUSE-UP / DOWN | NAVIGATION | **dropped**: side-menu keyboard (`TMPLT`, `EXECUTE_FUNCTION`) → f345 Page Functions |
| TOOLBAR.SAVE / EXIT / EXIT1 / LAST_REC / RE_ENTER_QUERY / PAGE_DOWN WHEN-BUTTON-PRESSED, + 13 OLB toolbar buttons | BUTTON ACTIONS | **dropped** → page 0 toolbar (`SAVE` commits through APEX; `EXIT` → `BACK`; `RE_ENTER_QUERY` → `SEARCH`); title refresh is the f345 header |
| TITLE.SYSTEM_DATE WHEN-VALIDATE-ITEM, TITLE 5 KEY-LISTVAL, EDI_MSG 1, LSIDE 150 mouse triggers | UI-ONLY | **dropped**: screen frame (inventory §6 notes) |

### 1.3 Block IMPORTERS (master)

| Trigger | Group | Member / target |
|---|---|---|
| IMPORTERS.PRE-QUERY | QUERY | `IMPORTERS_PRE_QUERY_PORT_CD`, `IMPORTERS_PRE_QUERY_NAME_STD` in the search page SQL. The `Exec_Query_Now` part is replaced by `P0_PAGE_PK`; `CGFK$DEFAULT_WHERE` (PORT_NAME) → bind filter |
| IMPORTERS.POST-QUERY | QUERY | `IMPORTERS_POST_QUERY` (process `POST-QUERY`), with program units `CGFK$QRY_*`; `CGFK$RESET_BLOCK_WHERE_CLAUSE` and `SET_RECORD_PROPERTY` dropped |
| IMPORTERS.WHEN-CREATE-RECORD | INITIALISATION | `IMPORTERS_WHEN_CREATE_RECORD` (process `IMPORTERS WHEN-CREATE-RECORD`) |
| IMPORTERS.ON-ERROR | UI-ONLY | **dropped** → `APP_ERROR_HANDLER` + Text Messages by constraint (§5) |
| IMPORTERS.KEY-HELP | UI-ONLY | **dropped** (MS-Help) |
| IMPORTERS.IMPR_NBR WHEN-VALIDATE-ITEM | VALIDATION | `IMPR_NBR_VALIDATION` + `IMPR_NBR_WHEN_VALIDATE_ITEM` |
| IMPORTERS.IMPR_TYPE_CD WHEN-VALIDATE-ITEM | VALIDATION | **dropped**: the item is not insertable or updatable; the Designer FK check (`CGFK$CHK_IMPORTERS_IMP_ITIDT_F`, warning only) only fills names, which `IMPORTERS_POST_QUERY` already returns |
| IMPORTERS.IMPR_TYPE_CD WHEN-NEW-ITEM-INSTANCE | NAVIGATION | **dropped**: `CLEAR_BLOCK` + `EXECUTE_QUERY` → submit `EXECUTE_QUERY` after `IMPR_NBR WHEN-VALIDATE-ITEM` (§6) |
| KEY-LISTVAL on PORT_CD, IMPR_TYPE_CD, CTRY_CD, CITY_CODE_OF_ID (CALL_FORM to LOV forms) | NAVIGATION | **dropped** → popup LOVs on search page 112001 (step 03) |
| 16 other KEY-LISTVAL (PORT_NAME, HQ_IMPR_NBR, IMPR_NBR, SDP_PORT_STATUS, IMPR_TYPE_NAME, CRTY_ARBC_NAME, ID_CITY_NAME, BUS_ID, BUS_ID_TYPE_CD, BUS_ID_TYPE_NAME, BUS_ID_BRNCH, CTRY_CTRY_STATUS, ARBC_IMPR_NAME, ENG_IMPR_NAME, IMPR_CNTCT_NAME, CTRY_CD_OF_ID) | UI-ONLY | **dropped**: only the Designer "may the LOV be shown" check; it is the item's read-only state |
| PORT_CD2, IMPR_TYPE_CD2, CTRY_CD2, CITY_CODE_OF_ID2, BUTT WHEN-BUTTON-PRESSED | BUTTON ACTIONS | **dropped**: LOV buttons (`GO_ITEM` + `DO_KEY('LIST_VALUES')`) → popup LOV icon |

### 1.4 Block IMPR_SUSPN (detail)

| Trigger | Group | Member / target |
|---|---|---|
| IMPR_SUSPN.WHEN-NEW-RECORD-INSTANCE | NAVIGATION | split: `NEXT_RECORD` part → `IMPR_SUSPN_IS_READ_ONLY` (+ server check `check_row_of_current_site`); stored-side part → `SUSPN_SIDE_CD_IS_READ_ONLY`; `GO_ITEM` dropped |
| IMPR_SUSPN.POST-QUERY | UI-ONLY | `SUSPN_SIDE_CD_IS_READ_ONLY` |
| IMPR_SUSPN.PRE-INSERT | PRE/POST DML | `IMPR_SUSPN_PRE_INSERT` (process `IMPR_SUSPN PRE-INSERT`) |
| IMPR_SUSPN.POST-INSERT | PRE/POST DML | first block → `IMPR_SUSPN_POST_INSERT` (process `IMPR_SUSPN POST-INSERT`); second block → `SUSPN_SIDE_CD_IS_READ_ONLY` |
| IMPR_SUSPN.PRE-UPDATE | PRE/POST DML | `IMPR_SUSPN_PRE_UPDATE` (process `IMPR_SUSPN PRE-UPDATE`) |
| IMPR_SUSPN.ON-DELETE | PRE/POST DML | `IMPR_SUSPN_ON_DELETE` (process `IMPR_SUSPN ON-DELETE`) |
| IMPR_SUSPN.KEY-DELREC (`TMPLT.KEY_DELETE_RECORD`) | NAVIGATION | **dropped** → IG delete with native confirm; the soft delete is `IMPR_SUSPN_ON_DELETE` |
| IMPR_SUSPN.ON-ERROR | UI-ONLY | **dropped** → `APP_ERROR_HANDLER` + Text Messages `IS_1_IMP_FK`, FRM-41105 / 41106 texts (§5) |
| IMPR_SUSPN.KEY-HELP | UI-ONLY | **dropped** (MS-Help) |
| SUSPN_STRT_DT WHEN-NEW-ITEM-INSTANCE | INITIALISATION | `SUSPN_STRT_DT_DEFAULT` (IG column default) |
| SUSPN_STRT_DT WHEN-VALIDATE-ITEM | VALIDATION | `SUSPN_STRT_DT_VALIDATION` |
| SUSPN_END_DT WHEN-VALIDATE-ITEM | VALIDATION | `SUSPN_END_DT_VALIDATION` |
| SUSPN_RLSE_DT WHEN-VALIDATE-ITEM | VALIDATION | **dropped**: hidden, non-navigable column, so the trigger can never fire; the value is set by the server (PRE-UPDATE / ON-DELETE) |
| SUSPN_STRT_DT / SUSPN_END_DT / SUSPN_RLSE_DT KEY-LISTVAL and KEY-F4 (6) | UI-ONLY | **dropped**: Hijri calendar forms (`INTRFACE.DISP_CALENDAR / DISP_DATE_CON`) → APEX date column |
| SUSPN_RSN_CD WHEN-NEW-ITEM-INSTANCE | INITIALISATION | `SUSPN_RSN_CD_DEFAULT` (IG column default) |
| SUSPN_RSN_CD WHEN-VALIDATE-ITEM | VALIDATION | `SUSPN_RSN_CD_VALIDATION` + `SUSPN_RSN_CD_VALIDATE_ITEM` (fills `SUSPN_RSN_TEXT`) |
| SUSPN_RSN_CD KEY-LISTVAL, SUSPN_RSN_TEXT KEY-LISTVAL | UI-ONLY | **dropped**: Designer LOV check; the reason is a select list |
| SUSPN_RSN_TEXT WHEN-NEW-ITEM-INSTANCE | NAVIGATION | **dropped**: body is `NULL` (GO_ITEM commented out) |
| SUSPN_SIDE_CD WHEN-NEW-ITEM-INSTANCE | INITIALISATION | `SUSPN_SIDE_CD_DEFAULT` (IG column default) |
| SUSPN_SIDE_CD WHEN-LIST-CHANGED, WHEN-VALIDATE-ITEM | VALIDATION | `SUSPN_SIDE_CD_VALIDATION` |

### 1.5 Program units (33)

| Program unit | Member / target |
|---|---|
| CGFK$QRY_IMPORTERS_IMP_SDP_FK, CGFK$QRY_IMPORTERS_IMP_ITIDT_F, CGFK$QRY_IMPORTERS_IMP_CTRY_FK, CGFK$QRY_IMPORTERS_IMP_BUS_ID_ | same names (PROGRAM UNITS) |
| CGFK$CHK_IMPORTERS_IMP_SDP_FK, CGFK$CHK_IMPORTERS_IMP_CTRY_FK, CGFK$CHK_IMPORTERS_IMP_BUS_ID_, CGFK$CHK_IMPR_SUSPN_IS_1_IMP_F, CGUV$CHK_IS_1_PK | **dropped**: not called by any active code (the FK and PK are enforced by the database) |
| CGFK$CHK_IMPORTERS_IMP_ITIDT_F | **dropped** with IMPR_TYPE_CD WHEN-VALIDATE-ITEM (§1.3) |
| CG$WHEN_NEW_FORM_INSTANCE, CGDV$POPULATE_DYNAMIC_LISTS | **dropped** → shared LOVs on `CG_REF_CODES` (domains `ALLOWED EXPORT`, `IMPR_SUSPN_RSN_CD`, `SUSPN SIDE CD`) |
| CG$IMPR1120_GLOBALS | **dropped**: Designer dynamic WHERE holder |
| CGTE$CHECK_CONSTRAINT_VIO | **dropped** → `APP_ERROR_HANDLER` |
| CGBS$TOGGLE, CGBS$SET_QUERY_MODE, CGBS$MESSAGE_QUERY_MODE | **dropped**: Designer query-mode toggle |
| EXECUTE_FUNCTION, MOUSE_CLICK | **dropped** → f345 Page Functions list (`FUNCS`); the module's functions are unknown (inventory §15 #9) |
| ADJ_FUNS, EXEC_FUNS | **dropped**: empty (`NULL;`) |
| CHECK_TIMEOUT, TOGGEL_WND, PRINT_REPORT, TERMINATE_FUN, CHECK_EDI_MSG_LOV, CHECK_EDI_MSG_TIMER, CHECK_EDI_ROLE_ID, EDI_MSG_LOV, FOR_EDI_MSG, RETURN_MSG, TURN_MSG, WHEN_TIMER_EXPIRED_MSG | **dropped**: `NIB` wrappers not called by active code (timers, EDI ticker, window) |

## 2. Built-in replacements

| Trigger | Built-in | Replacement | Where |
|---|---|---|---|
| WHEN-NEW-FORM-INSTANCE | `MESSAGE` + `EXIT_FORM` | `FORMS_APX.FORM_TRIGGER_FAILURE('ليس لديك الصلاحية للدخول على الشاشة')` | `INIT_FORM` |
| WHEN-NEW-FORM-INSTANCE | `SET_ITEM_PROPERTY(PORT_CD, INSERT / UPDATE_ALLOWED)` | `PORT_CD_IS_READ_ONLY` in the item Read Only condition | PL/SQL + item |
| PRE-FORM | `FORMS_DDL('ALTER SESSION …')`, `SET_APPLICATION_PROPERTY` | f345 Globalization (date format) | application |
| IMPORTERS.PRE-QUERY | `SET_BLOCK_PROPERTY(DEFAULT_WHERE)`, `NAME_IN`, `FIND_BLOCK`, `GET_BLOCK_PROPERTY` | search page SQL with binds | region SQL |
| IMPORTERS.PRE-QUERY | `:GLOBAL.Exec_Query_Now / PORT_CD / IMPR_NBR` | `P0_PAGE_PK` (ROWID) | `IMPR_NBR_WHEN_VALIDATE_ITEM` |
| IMPORTERS.POST-QUERY | `SET_RECORD_PROPERTY(QUERY_STATUS)`, `NAME_IN`, `Des$Form_errors.PUSH` | not needed / `FORMS_APX.MESSAGE`, `FORMS_APX.FORM_TRIGGER_FAILURE` | `IMPORTERS_POST_QUERY` |
| IMPR_NBR WVI | `STR.DispArbMsg(9,150)` + `RAISE FORM_TRIGGER_FAILURE` | returned text `arabic_message(9, 150)` | `IMPR_NBR_VALIDATION` |
| IMPR_TYPE_CD WNII | `CLEAR_BLOCK` + `EXECUTE_QUERY` | submit request `EXECUTE_QUERY` | DA |
| KEY-LISTVAL (4) | `CALL_FORM`, `CREATE_PARAMETER_LIST`, `ADD_PARAMETER`, `:GLOBAL.*` return | popup LOV | page 112001 |
| KEY-LISTVAL (20) | `GET_RECORD_PROPERTY`, `GET_BLOCK_PROPERTY`, `GET_ITEM_PROPERTY`, `:SYSTEM.MODE / CURSOR_*` | item read-only state | item |
| LOV buttons | `GO_ITEM` + `DO_KEY('LIST_VALUES')` | popup LOV icon | item |
| IMPR_SUSPN.WNRI | `NEXT_RECORD` | `IMPR_SUSPN_IS_READ_ONLY` + `check_row_of_current_site` | IG + PL/SQL |
| IMPR_SUSPN.WNRI / POST-QUERY / POST-INSERT | `SET_ITEM_PROPERTY(SUSPN_SIDE_CD, ENABLED / NAVIGABLE)`, `GO_ITEM` | `SUSPN_SIDE_CD_IS_READ_ONLY` / dropped | IG column |
| IMPR_SUSPN.POST-INSERT | `STANDARD.COMMIT` | removed (APEX commits) | — |
| IMPR_SUSPN.PRE-INSERT / PRE-UPDATE / ON-DELETE | `ACTIVITY.ADD_ACTIVITY` + `RAISE FORM_TRIGGER_FAILURE` | private `add_activity` → `ACTIVITY_DB.ADD_ACTIVITY` (8-argument overload) + `FORMS_APX.FORM_TRIGGER_FAILURE` | PL/SQL |
| date items WVI | `:System.TRIGGER_ITEM / CURSOR_ITEM / Cursor_Value`, `HIJDATE.VALID_HIJ_DATE` + FTF | `hijri_date_error(date)` → `HIJDATE_DB.VALID_HIJ_DATE` | `SUSPN_*_DT_VALIDATION` |
| date items WVI | `HIJDATE.COMPARE_HIJ_DATES`, `HIJDATE.Cur_Hij_Date` | `HIJDATE_DB.COMPARE_HIJ_DATES`, private `cur_hij_date` | PL/SQL |
| SUSPN_RSN_CD / SIDE_CD WVI / WLC | value reset + `RAISE FORM_TRIGGER_FAILURE` | returned error text (no reset) | validation functions |
| date KEY-LISTVAL / KEY-F4 | `INTRFACE.DISP_CALENDAR / DISP_DATE_CON` (CALL_FORM) | APEX date column | IG |
| KEY-DELREC | `TMPLT.KEY_DELETE_RECORD` (`STR.DispAlert … 'WARNING'`, `Delete_record`, `COMMIT`) | IG delete + native confirm; `IMPR_SUSPN_ON_DELETE` | IG + process |
| ON-ERROR (2) | `ERROR_CODE / ERROR_TYPE / DBMS_ERROR_*`, `CGTE$*`, `Des$Form_errors.*` | `APP_ERROR_HANDLER` + Text Messages | application |
| :PARAMETER.* | `P_CURR_PORT_CD`, `CURRENT_SIDE`, `P_USER_ID`, `P_WS_ID` | `P_CURR_PORT_CD`, `P1120_P_CURRENT_SIDE`, `SSO_APP_USER`, `P_GLOBAL_V_WS_ID` | parameters (§7) |

## 3. Package members and the f345 component that calls them

| # | Member | Source | APEX component (page 1120 unless noted) |
|---|---|---|---|
| 1 | `CHECK_ERROR` | f345 helper | every FOS dynamic action |
| 2 | `REQUIRED_VALIDATION` | f345 helper | validations `<COLUMN> REQUIRED` (e.g. `IMPR_SUSPN SUSPN_RSN_TEXT REQUIRED`) |
| 3 | `P0_PAGE_PK_CHECK` | f345 helper | process `P0_PAGE_PK CHECK` (Before Header 20) |
| 4 | `GET_MODULE_ID` | f345 helper | process `PARAMETERS` (Before Header 40) |
| 5 | `HEADER_TITLE` | f345 helper | process `HEADER TITLE` (Before Header 100) |
| 6 | `GET_CURRENT_SIDE` | parameter CURRENT_SIDE (launcher) | process `PARAMETERS` (Before Header 40, after GET_MODULE_ID) |
| 7 | `INIT_FORM` | WHEN-NEW-FORM-INSTANCE | process `WHEN-NEW-FORM-INSTANCE` (Before Header 60, always) |
| 8 | `IMPORTERS_PRE_QUERY_PORT_CD` | IMPORTERS.PRE-QUERY | search page 112001 region SQL |
| 9 | `IMPORTERS_PRE_QUERY_NAME_STD` | IMPORTERS.PRE-QUERY | search page 112001 region SQL |
| 10 | `IMPORTERS_POST_QUERY` | IMPORTERS.POST-QUERY | process `POST-QUERY` (Before Header, after `Initialize form`, P0_PAGE_PK not null) |
| 11 | `IMPORTERS_WHEN_CREATE_RECORD` | IMPORTERS.WHEN-CREATE-RECORD | process `IMPORTERS WHEN-CREATE-RECORD` (Before Header, P0_PAGE_PK null) |
| 12 | `PORT_CD_IS_READ_ONLY` | WHEN-NEW-FORM-INSTANCE | Read Only of `P1120_PORT_CD`, `P112001_PORT_CD` |
| 13 | `IMPR_NBR_VALIDATION` | IMPR_NBR.WHEN-VALIDATE-ITEM | validation `IMPR_NBR VALIDATION` |
| 14 | `IMPR_NBR_WHEN_VALIDATE_ITEM` | IMPR_NBR.WHEN-VALIDATE-ITEM | DA `IMPR_NBR WHEN-VALIDATE-ITEM` (FOS, returns `P0_PAGE_PK`) |
| 15 | `IMPR_SUSPN_IS_READ_ONLY` | IMPR_SUSPN.WHEN-NEW-RECORD-INSTANCE | Read Only of every IG column (For Each Row) |
| 16 | `SUSPN_STRT_DT_DEFAULT` | SUSPN_STRT_DT.WHEN-NEW-ITEM-INSTANCE | IG column `SUSPN_STRT_DT` default |
| 17 | `SUSPN_STRT_DT_VALIDATION` | SUSPN_STRT_DT.WHEN-VALIDATE-ITEM | validation `IMPR_SUSPN SUSPN_STRT_DT VALIDATION` + DA `IMPR_SUSPN SUSPN_STRT_DT WHEN-VALIDATE-ITEM` |
| 18 | `SUSPN_END_DT_VALIDATION` | SUSPN_END_DT.WHEN-VALIDATE-ITEM | validation `IMPR_SUSPN SUSPN_END_DT VALIDATION` + DA `IMPR_SUSPN SUSPN_END_DT WHEN-VALIDATE-ITEM` |
| 19 | `SUSPN_RSN_CD_DEFAULT` | SUSPN_RSN_CD.WHEN-NEW-ITEM-INSTANCE | IG column `SUSPN_RSN_CD` default |
| 20 | `SUSPN_RSN_CD_VALIDATION` | SUSPN_RSN_CD.WHEN-VALIDATE-ITEM | validation `IMPR_SUSPN SUSPN_RSN_CD VALIDATION` |
| 21 | `SUSPN_RSN_CD_VALIDATE_ITEM` | SUSPN_RSN_CD.WHEN-VALIDATE-ITEM | DA `IMPR_SUSPN SUSPN_RSN_CD WHEN-VALIDATE-ITEM` (FOS, returns `SUSPN_RSN_TEXT`) |
| 22 | `SUSPN_SIDE_CD_DEFAULT` | SUSPN_SIDE_CD.WHEN-NEW-ITEM-INSTANCE | IG column `SUSPN_SIDE_CD` default |
| 23 | `SUSPN_SIDE_CD_VALIDATION` | SUSPN_SIDE_CD.WHEN-LIST-CHANGED + WVI | validation `IMPR_SUSPN SUSPN_SIDE_CD VALIDATION` + DA `IMPR_SUSPN SUSPN_SIDE_CD WHEN-LIST-CHANGED` |
| 24 | `SUSPN_SIDE_CD_IS_READ_ONLY` | WNRI / POST-QUERY / POST-INSERT | Read Only of IG column `SUSPN_SIDE_CD` (For Each Row) |
| 25 | `IMPR_SUSPN_PRE_INSERT` | IMPR_SUSPN.PRE-INSERT | process `IMPR_SUSPN PRE-INSERT` (row status C) |
| 26 | `IMPR_SUSPN_POST_INSERT` | IMPR_SUSPN.POST-INSERT | process `IMPR_SUSPN POST-INSERT` (row status C, after the IG DML) |
| 27 | `IMPR_SUSPN_PRE_UPDATE` | IMPR_SUSPN.PRE-UPDATE | process `IMPR_SUSPN PRE-UPDATE` (row status U) |
| 28 | `IMPR_SUSPN_ON_DELETE` | IMPR_SUSPN.ON-DELETE | process `IMPR_SUSPN ON-DELETE` (row status D; the IG DML must not delete the row) |
| 29–32 | `CGFK$QRY_IMPORTERS_IMP_SDP_FK`, `…_ITIDT_F`, `…_CTRY_FK`, `…_BUS_ID_` | program units | called by `IMPORTERS_POST_QUERY` |
| — | `PKG_VERSION` | version block | `SELECT IMPR1120.PKG_VERSION FROM dual` |

The master-key copy into new grid rows is the f345 process `IMPR_SUSPN MASTER KEYS` (`:PORT_CD := :P1120_PORT_CD; :IMPR_NBR := :P1120_IMPR_NBR;`, row status C). It replaces the Forms `CopyValueFromItem` and needs no member.

**Private helpers** (body top): `arabic_message` (STR.DispArbMsg text, same as IMPR1110), `cur_hij_date`, `hijri_date_error`, `add_activity`, `importer_row_id`, `side_of_another_site` (the side rule shared by WHEN-LIST-CHANGED and WNRI), `check_row_of_current_site`.

**Name shortening** (CLAUDE.md §4): the IG column members drop the `IMPR_SUSPN_` block prefix. For example, `IMPR_SUSPN_SUSPN_STRT_DT_VALIDATION` would be 35 bytes. `SUSPN_RSN_CD_WHEN_VALIDATE_ITEM` (31 bytes) drops `WHEN_` to become `SUSPN_RSN_CD_VALIDATE_ITEM`. WHEN-NEW-ITEM-INSTANCE defaults are named `<COLUMN>_DEFAULT`, because `<COLUMN>_NEW_ITEM_INSTANCE` is still over 30 bytes. The full names are in the comments.

## 4. Read-only and required rules

| Function | Rule (from Forms) | Used by |
|---|---|---|
| `PORT_CD_IS_READ_ONLY(P_CURR_PORT_CD)` | read only unless port 99 | `P1120_PORT_CD`, `P112001_PORT_CD` |
| `IMPR_SUSPN_IS_READ_ONLY(SUSPN_SIDE_CD, CURRENT_SIDE, P_CURR_PORT_CD)` | site 1 (port ≠ 99): side ≠ 1 · site 2 (port ≠ 99): side 1 or 5 · site 3 (port 99): side ≠ 5. An empty side (new row) is never read only | every IG column |
| `SUSPN_SIDE_CD_IS_READ_ONLY(PORT_CD, IMPR_NBR, SUSPN_SEQ)` | a side is stored for the row | IG column `SUSPN_SIDE_CD` |
| static | all IMPORTERS items: Insert / Update Allowed = false in Forms | Read Only (Always), except `P1120_IMPR_NBR` while `P0_PAGE_PK` is null |
| required (static Forms property) | `SUSPN_STRT_DT`, `SUSPN_END_DT`, `SUSPN_RSN_TEXT` (Required = true); `SUSPN_RSN_CD` / `SUSPN_SIDE_CD` through their validations | IG column "Value Required" or `<COLUMN> REQUIRED` with `REQUIRED_VALIDATION` |

## 5. Messages and errors

| Code / name | Text | Source | Where |
|---|---|---|---|
| -20001 (`c_err`) | any text passed to `CHECK_ERROR` | f345 | FOS DAs |
| `FORMS_APX.FORM_TRIGGER_FAILURE` | 'ليس لديك الصلاحية للدخول على الشاشة' | WHEN-NEW-FORM-INSTANCE | `INIT_FORM` |
| 9-150 | `STR_DB.GetArbMsg(9, 150)` (importer not in this port) | IMPR_NBR WVI | `IMPR_NBR_VALIDATION` |
| 9-100 | `STR_DB.GetArbMsg(9, 100)` (start date before today) | SUSPN_STRT_DT WVI | `SUSPN_STRT_DT_VALIDATION` |
| 9-110 | `STR_DB.GetArbMsg(9, 110)` (end date before start) | SUSPN_END_DT WVI | `SUSPN_END_DT_VALIDATION` |
| HIJDATE_DB message | text returned by `HIJDATE_DB.VALID_HIJ_DATE` / `CUR_HIJ_DATE` | HIJDATE library | date validations, `cur_hij_date` |
| ACTIVITY_DB message | text returned by `ACTIVITY_DB.ADD_ACTIVITY` when it returns 0 | ACTIVITY library | `add_activity` |
| `c_msg_reason_not_allowed` | 'سبب الإيقاف غير مسموح به لهذه الجهة' — **placeholder, to agree** | SUSPN_RSN_CD WVI (Forms: no message) | `SUSPN_RSN_CD_VALIDATION` |
| `c_msg_side_not_allowed` | 'الجهة غير مسموح بها لهذه الجهة' — **placeholder, to agree** | SUSPN_SIDE_CD WLC (Forms: no message) | `SUSPN_SIDE_CD_VALIDATION` |
| `c_msg_other_side_row` | 'لا يمكن تعديل أو حذف توقيف خاص بجهة أخرى' — **placeholder, to agree** | WNRI NEXT_RECORD (Forms: row unreachable) | `check_row_of_current_site` |
| required | 'يجب إدخال السبب' / 'يجب إدخال الجهة' | FRM-40202 equivalent | `REQUIRED_VALIDATION` |
| POST-QUERY lookups | 'رمز الجمرك غير صحيح - أعد إدخال البيانات', 'رمز النشاط التجاري غير صحيح - أعد إدخال البيانات', 'رمز الدولة غير صحيح - أعد ادخال البيانات', 'خطأ في رمز مدينة مصدر الرقم الإستدلالي' (non-fatal), '<p1> must be entered' (رمز النشاط التجارى, fatal) | IMPORTERS.POST-QUERY | `IMPORTERS_POST_QUERY` |
| Text Message `IS_1_IMP_FK` (to create) | 'بيانات الربط مع ملف المستوردين غير صحيحة - أعد إدخال البيانات' | IMPR_SUSPN.ON-ERROR (ORA-02291) | `APP_ERROR_HANDLER` |
| Text Messages for FRM-41105 / 41106 | no APEX equivalent (no master-less query or insert in an APEX master-detail) | IMPR_SUSPN.ON-ERROR | not created |
| Delete confirm | 'هل أنت متأكد من عملية الحذف' | `TMPLT.KEY_DELETE_RECORD` | IG delete confirm (step 03) |

## 6. UI logic for dynamic actions (input for step 03)

The full list is in the body section *UI LOGIC FOR APEX DYNAMIC ACTIONS*. In short:

1. `IMPR_NBR WHEN-VALIDATE-ITEM`: FOS `IMPR_NBR_WHEN_VALIDATE_ITEM` returns `P0_PAGE_PK`, then Submit Page with request `EXECUTE_QUERY`.
2. Read Only of `P1120_PORT_CD` / `P112001_PORT_CD`: `PORT_CD_IS_READ_ONLY`. All other IMPORTERS items are always read only.
3. IG row read only: `IMPR_SUSPN_IS_READ_ONLY` on every column, For Each Row.
4. IG column `SUSPN_SIDE_CD` read only: `SUSPN_SIDE_CD_IS_READ_ONLY`, For Each Row.
5. IG column defaults: `SUSPN_STRT_DT_DEFAULT`, `SUSPN_RSN_CD_DEFAULT`, `SUSPN_SIDE_CD_DEFAULT`.
6. `IMPR_SUSPN SUSPN_STRT_DT WHEN-VALIDATE-ITEM`, `IMPR_SUSPN SUSPN_END_DT WHEN-VALIDATE-ITEM`, `IMPR_SUSPN SUSPN_SIDE_CD WHEN-LIST-CHANGED`: FOS `CHECK_ERROR(<COLUMN>_VALIDATION(...))`.
7. `IMPR_SUSPN SUSPN_RSN_CD WHEN-VALIDATE-ITEM`: FOS `SUSPN_RSN_CD_VALIDATE_ITEM`, Items to Return `SUSPN_RSN_TEXT`.
8. Date columns: Forms format mask, Hijri picker per the IMPR1110 decision.
9. IG delete: native confirm with the Forms text. The soft delete runs in process `IMPR_SUSPN ON-DELETE`.
10. **Not repeated:** the Forms resets of a rejected value (start date → today, reason / side → the site's default), and `GO_ITEM`. Step 03 to confirm.

No JavaScript is needed by the package.

## 7. Parameters and globals → APEX items

| Forms | APEX | Notes |
|---|---|---|
| `:PARAMETER.P_CURR_PORT_CD` | application item `P_CURR_PORT_CD` (f345) | port scope, defaults, activity port |
| `:PARAMETER.P_USER_ID` | `SSO_APP_USER` (f345) | `ACTIVITY_DB` user (as IMPR1110) |
| `:PARAMETER.P_WS_ID` | `P_GLOBAL_V_WS_ID` (f345, `'APEX-WS'`) | `ACTIVITY_DB` workstation, to confirm (IMPR1110 §15 #13) |
| `:PARAMETER.CURRENT_SIDE` | page item `P1120_P_CURRENT_SIDE`, filled by `GET_CURRENT_SIDE` | source to confirm (inventory §15 #1). No application item, because it is not passed between pages |
| `:PARAMETER.P_MODULE_ID` | `P1120_MODULE_ID` (f345) | |
| `:PARAMETER.P_PORT_TYPE` | `P_PORT_TYPE` (f345) | only passed to LOV_SD_PORTS → search page LOV (step 03) |
| other `P_*` (P_USER_NAME, P_MODULE_NAME, P_CLASS_CD, …) | not used by business code | f345 header / Page Functions |
| `:GLOBAL.Exec_Query_Now`, `PORT_CD`, `IMPR_NBR` | `P0_PAGE_PK` | no `G_` items |
| `:GLOBAL.PORT_NAME`, `CTRY_CD`, `CRTY_ARBC_NAME`, `CITY_CD`, `CITY_ARB_NAME`, `IMPR_TYPE_CD`, `IMPR_TYPE_NAME` | popup LOV return values | no `G_` items |
| `:GLOBAL.CG$*`, `CURRENT_VER`, `CURRENT_DT`, `EXIT`, `SYSTEM_OBJ` | dropped | Designer internals / version stamps / function menu |

No `:GLOBAL` survives, so the package does not use `FORMS_APX.get_global`.

## 8. Dropped logic, TODOs, assumptions and missing sources

| # | Item | Level | Status |
|---|---|---|---|
| 1 | `STANDARD.COMMIT` in IMPR_SUSPN.POST-INSERT removed. In Forms each new suspension (and its SMS) was committed before the next row was processed. In APEX the SMS is sent inside the transaction and the save is committed at the end; if a later row fails, the rows are rolled back but the SMS has already gone | **HIGH** | decision needed (inventory §15 #4). An option for step 03 is a process after the IG DML that sends the notifications only when the save succeeds |
| 2 | `CURRENT_SIDE` read from `SC_PORT_SETTING (VAR_NAME = 'CURRENT_SIDE')` per port and module | HIGH | assumption (inventory §15 #1) |
| 3 | Error texts for rejected reason / side / other-site row are placeholders | Medium | to agree (inventory §15 #12) |
| 4 | `check_row_of_current_site` is new server-side enforcement of a Forms navigation rule | Medium | to confirm |
| 5 | `SUSPN_SEQ = MAX + 1` kept | Medium | SUGGESTION: sequence (inventory §15 #5) |
| 6 | ON-DELETE UPDATE has no `PORT_CD` in its WHERE clause (kept) | Low | SUGGESTION in the code |
| 7 | `WHEN OTHERS THEN NULL` kept in POST-INSERT and PRE-UPDATE | Medium | SUGGESTION: log |
| 8 | `IMPORTERS_PRE_QUERY_NAME_STD`: whether `STR_DB.StrFormat(x, 1)` adds `%` wildcards (LIKE vs =) | Low | TODO: MISSING SOURCE STR_DB |
| 9 | Designer message 78 used with its English default text | Low | TODO (CIC_AMSG message table) |
| 10 | Master never inserts an importer from this page | Medium | assumption (inventory §15 #6) |
| 11 | Pages 1120 / 112001 | Low | assumption; register in step 03 |
| 12 | Resets of rejected values and `GO_ITEM` not repeated | Low | step 03 to confirm |
| 13 | IG DML for status D must not delete (soft delete) | Medium | step 03: the native IG DML deletes, so use custom PL/SQL DML for D rows, or another pattern |

**MISSING SOURCE** (calls copied unchanged from the Forms code, so their signatures are those Forms compiled against):

| Package | Used in | Call |
|---|---|---|
| `STR_DB` | `arabic_message`, `IMPORTERS_PRE_QUERY_NAME_STD` | `GETARBMSG(sys, nbr)`, `STRFORMAT(text, 1)` |
| `GNRL` | `IMPR_SUSPN_POST_INSERT` | `GET_CUSTOMS_SETTING(port, 'NE_INTEGRATION', 21)` |
| `LIB_APX_USR.APEX_NOTIFICATIONS` | `IMPR_SUSPN_POST_INSERT` | `SEND_SMS_EMAIL_NOTIFY(…)` (named, 15 arguments) |
| `SMS_MESSAGE` | `IMPR_SUSPN_POST_INSERT` | `SEND_SMS_MESSAGE(9, 3, 1, port, NULL, mobile, body, key)` |

**Grants needed by `LIB_APX_USR`** (definer rights, direct grants):

- **Tables:** `IMPORTERS`, `IMPR_SUSPNS` (SELECT, UPDATE), `IMPORTER_BASIC_DATA`, `SD_PORTS`, `CG_REF_CODES`, `COUNTRIES`, `CITIES`, `IMPR_TYPES`, `IMPR_TYPE_ID_TYPES`, `BUS_ID_TYPES`, `SC_SYSTEM_OBJECTS`, `SC_PORT_SETTING`. All are SELECT unless noted. `INSERT` / `UPDATE` / `DELETE` on `IMPR_SUSPNS` go to the APEX parsing schema `CUSTOMS` for the IG DML.
- **Packages (EXECUTE):** `ACTIVITY_DB`, `HIJDATE_DB`, `STR_DB`, `GNRL`, `SMS_MESSAGE`, `FORMS_APX`. `APEX_NOTIFICATIONS` is in the same schema.

## 9. How the package was built and checked

Written by hand from the decoded trigger code in the inventory (which `scripts/gen_inv.py` builds from the XML) and the library texts. This is unlike IMPR1110, which used a generator, because IMPR1120's business code is small. Self-check run on 2026-11-23:

| Check | Result |
|---|---|
| Forms built-ins (`GO_BLOCK`, `GO_ITEM`, `SET_ITEM_PROPERTY`, `SHOW_ALERT`, `EXECUTE_QUERY`, `RAISE FORM_TRIGGER_FAILURE`, `:SYSTEM.`, `:GLOBAL.`, `:PARAMETER`, `NAME_IN`, `COPY(`, `NEXT_RECORD`, `COMMIT`, `ROLLBACK`) outside comments | none |
| `v('P…')`, `get_session_state`, `pkg_impr1120`, `AI_` | none |
| Identifiers > 30 bytes | none |
| Spec members present in the body with the same signature, in the same order | 33 / 33 |
| Members > 80 lines | none (longest `IMPR_SUSPN_POST_INSERT` 65) |
| Owner `LIB_APX_USR`, version block, `PKG_VERSION`, synonym and the 4 grants | present |
| `CHECK_ERROR`, `REQUIRED_VALIDATION` | present |
| Every inventory trigger in §1 | yes (boilerplate groups listed with counts) |
| Compilation on 12.1.0.2 | **not done**: no database in this session |
