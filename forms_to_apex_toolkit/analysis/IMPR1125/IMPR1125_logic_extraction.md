# IMPR1125 — Logic extraction (step 02, revision 1)

| Item | Value |
|---|---|
| Form | `IMPR1125.fmb` (module `IMPR1125_CENTRAL`) — "صيانة توقيفات المستوردين" (central suspensions) |
| Date | 2026-11-24 |
| Input | `analysis/IMPR1125/IMPR1125_inventory.md` (step 01), `forms/IMPR/IMPR1125_fmb.xml`, `forms/COMMON/libraries/CIC_LIB.pld`, LOV forms `LOV_IMPORT_HQ_NBR`, `LOV_DELETE_IMP_SUSP` |
| Standard | CLAUDE.md §3.2, §4, §4a–§4d, §6, §7; `docs/f345_reference_standard.md` §5, §6, §9, §10; prompt 02 rules 1–15 |
| Package | `LIB_APX_USR.IMPR1125`, version **001**: [impr1125_spec.sql](../../plsql/IMPR1125/impr1125_spec.sql) / [impr1125_body.sql](../../plsql/IMPR1125/impr1125_body.sql) |
| Pages (assumed) | main page **1125** (`IMPR1125`), search page **112501** (`IMPR1125_SEARCH`), dialog **112502** (`IMPR1125_DELETED_SUSPENSIONS`): same numbering as IMPR1120 → 1120. Registered in step 03 |
| Status | **NOT COMPILED** (no 12.1.0.2 / APEX 21.2 instance in this session). Structural self-check passed (§9) |

## 0. Summary

- **15 public members**: 1 f345 helper (`P0_PAGE_PK_CHECK`) + `PKG_VERSION`, 7 HQ_IMPRS, 7 IMPR_CNTRL_SUSPNS. **3 private helpers** (`stored_suspension`, `add_activity`, `hq_importer_row_id`). The longest member is `IMPR_CNTRL_SUSPNS_POST_INSERT` (~65 lines).
- **APEX page shape (input for step 03):**
  - Form region `HQ_IMPRS`, read only except the two search keys, keyed by the HQ_IMPRS ROWID in `P0_PAGE_PK`. No DML on the master (Forms ON-INSERT / ON-UPDATE / ON-DELETE are `NULL`).
  - Editable IG `IMPR_CNTRL_SUSPNS` on `IMPR_CNTRL_SUSPNS WHERE SUSPN_RLSE_DT IS NULL`, master key `HQ_IMPR_NBR`, DML through `IMPR_CNTRL_SUSPNS_SAVE_ROW`.
  - Search page 112501 (replaces `LOV_IMPORT_HQ_NBR`), read-only dialog 112502 (replaces `LOV_DELETE_IMP_SUSP`).
- **Business rules kept:** unified number / business id must exist in `HQ_IMPRS` (literal texts); lookups of POST-QUERY; "released suspensions exist" question; start / end dates valid Hijri, end ≥ start (literal text); reason fixed to 1 and side fixed to 5; `SUSPN_SEQ` = MAX + 1 (always recalculated); activity log `(9, 7, 1/2/3)`; soft delete; SMS / notification after insert (both channels, errors hidden, NULL mobile in the new channel).
- **Changed, and why:**

| Change | Reason |
|---|---|
| `STANDARD.COMMIT` in POST-INSERT removed; COMMITs of `TMPLT.KEY_DELETE_RECORD` and TOOLBAR.SAVE not carried over | CLAUDE.md §6 / prompt rule 10: APEX commits at the end of the request. **HIGH**: §8 #1 |
| `:GLOBAL.HQ_IMPR_NBR / BUS_NBR` + block WHEN-NEW-ITEM-INSTANCE `EXECUTE_QUERY` replaced by `P0_PAGE_PK` (ROWID of the first matching HQ_IMPRS row) | f345 page-key standard; "first row" = `MIN(ROWID)` (Forms showed the first row of the query) |
| "Number not found" no longer opens the LOV form automatically | An APEX validation stops the request; the error text already says to use the list (page 0 SEARCH) |

## 1. Trigger classification

### 1.1 Form level (33 triggers)

| Trigger | Group | Member / target |
|---|---|---|
| PRE-FORM | INITIALISATION | **dropped**: `NIB.PRE_FORM`, `SET_APPLICATION_PROPERTY` / `FORMS_DDL('ALTER SESSION …')` → f345 Globalization, `CGHP$PRE_FORM` (obsolete) |
| WHEN-NEW-FORM-INSTANCE | INITIALISATION | **dropped**: `NIB.WHEN_NEW_FORM_INSTANCE`, `CGBS2$.*`, `CG$WHEN_NEW_FORM_INSTANCE` (lists → shared LOVs, block sync → native master-detail); `:GLOBAL.HQ_IMPR_NBR / BUS_NBR := NULL`, `current_ver := 2` → not needed (`P0_PAGE_PK`). The commented-out block is inactive |
| WHEN-NEW-BLOCK-INSTANCE, ON-CLEAR-DETAILS, ON-POPULATE-DETAILS | NAVIGATION | **dropped** → native Form + IG master-detail |
| KEY-CQUERY, KEY-CLRREC, KEY-NXTKEY, KEY-MENU, KEY-CLRFRM | NAVIGATION | **dropped** → page 0 toolbar `CLEAR` / IG |
| KEY-HELP | UI-ONLY | **dropped**: MS-Help |
| KEY-F9 | UI-ONLY | **dropped** → page 0 `FUNCS` drawer |
| ON-ERROR, ON-MESSAGE | UI-ONLY | **dropped** → f345 error handler |
| WHEN-TIMER-EXPIRED, WHEN-WINDOW-ACTIVATED, WHEN-MOUSE-DOWN | UI-ONLY | **dropped**: timers / window (IMPR1110 decision 2026-11-19) |
| KEY-EDIT, KEY-DUPREC, KEY-ENTQRY, KEY-CLRBLK, KEY-DELREC, KEY-F5, KEY-NXTREC, KEY-PRVREC, KEY-DOWN, KEY-UP, KEY-SCRUP, KEY-SCRDOWN, KEY-PRINT, KEY-EXIT, KEY-EXEQRY (15) | NAVIGATION | **dropped**: `NIB.KEY_*` → page 0 toolbar and IG keyboard |
| KEY-F4 (OLB) | NAVIGATION | **dropped**: OLB frame |

### 1.2 OLB frame blocks (TOOLBAR, TITLE, EDI_MSG, LSIDE)

| Triggers | Group | Member / target |
|---|---|---|
| TOOLBAR KEY-DOWN / KEY-UP / KEY-NEXT-ITEM, FUN_BUT WHEN-MOUSE-UP / DOWN | NAVIGATION | **dropped** → f345 Page Functions |
| TOOLBAR SAVE, CLEAR_ALL, EXIT, EXIT1, ENTER, EXECUTE, REMOVE, LIST_VALUE, HELP, LAST_REC, RE_ENTER_QUERY, FIRST_REC, PAGE_UP, PAGE_DOWN WHEN-BUTTON-PRESSED | BUTTON ACTIONS | **dropped** → page 0 toolbar (`SAVE`, `CLEAR`, `DELETE`, `SEARCH`, `BACK`) |
| TITLE.SYSTEM_DATE WVI, TITLE 5 KEY-LISTVAL, EDI_MSG 1, LSIDE 150 mouse triggers | UI-ONLY | **dropped**: screen frame |

### 1.3 Block HQ_IMPRS (master)

| Trigger | Group | Member / target |
|---|---|---|
| HQ_IMPRS.PRE-QUERY | QUERY | **dropped**: copies `:GLOBAL.HQ_IMPR_NBR / BUS_NBR` into the criterion → replaced by `P0_PAGE_PK` (set by `*_WHEN_VALIDATE_ITEM` or the search page) |
| HQ_IMPRS.POST-QUERY | QUERY | split: globals := NULL → dropped; lookups → `HQ_IMPRS_POST_QUERY` (process `POST-QUERY`); released-suspension count → `RELEASED_SUSPENSIONS_EXIST`; CONFIRM + `DELETE_SUSPS_LOV` → DA `HQ_IMPRS POST-QUERY` (Confirm → dialog 112502) |
| HQ_IMPRS.WHEN-NEW-ITEM-INSTANCE (block level) | NAVIGATION | **dropped**: `CLEAR_BLOCK` + `EXECUTE_QUERY` → submit `EXECUTE_QUERY` after the item DA (§5) |
| HQ_IMPRS.ON-INSERT / ON-UPDATE / ON-DELETE (`NULL`) | PRE/POST DML | **dropped**: no DML on the master region; page 0 DELETE → `PRE_DELETE` (block Delete Allowed = false) |
| HQ_IMPRS.ON-ERROR, KEY-HELP | UI-ONLY | **dropped** → error handler / obsolete help |
| HQ_IMPRS.BUS_ID WHEN-VALIDATE-ITEM | VALIDATION | `BUS_ID_VALIDATION` + `BUS_ID_WHEN_VALIDATE_ITEM` |
| HQ_IMPRS.HQ_IMPR_NBR WHEN-VALIDATE-ITEM | VALIDATION | `HQ_IMPR_NBR_VALIDATION` + `HQ_IMPR_NBR_WHEN_VALIDATE_ITEM` |
| HQ_IMPRS.BUS_ID KEY-LISTVAL, BUT_SH_HQNUM WHEN-BUTTON-PRESSED (`SINGLE_IMP_LOV`) | NAVIGATION | **dropped** → search page 112501 |
| 12 other KEY-LISTVAL (BUS_ID_TYPE_CD, BUS_ID_TYPE_NAME, BUS_ID_BRNCH, HQ_IMPR_NBR, CITY_CODE_OF_ID, CITY_CODE_OF_NAME, IMPR_TYPE_CD, IMPR_TYPE_NAME, CTRY_CD, CRTY_ARBC_NAME, ARBC_IMPR_NAME, ENG_IMPR_NAME) | UI-ONLY | **dropped**: Designer "may the LOV be shown" check = item read-only state |

### 1.4 Block IMPR_CNTRL_SUSPNS (detail)

| Trigger | Group | Member / target |
|---|---|---|
| PRE-INSERT | PRE/POST DML | `IMPR_CNTRL_SUSPNS_PRE_INSERT` (via `IMPR_CNTRL_SUSPNS_SAVE_ROW`) |
| POST-INSERT | PRE/POST DML | `IMPR_CNTRL_SUSPNS_POST_INSERT` (via `SAVE_ROW`) |
| PRE-UPDATE | PRE/POST DML | `IMPR_CNTRL_SUSPNS_PRE_UPDATE` (via `SAVE_ROW`) |
| ON-DELETE | PRE/POST DML | `IMPR_CNTRL_SUSPNS_ON_DELETE` (via `SAVE_ROW`, soft delete) |
| KEY-DELREC (`TMPLT.KEY_DELETE_RECORD`) | NAVIGATION | **dropped** → IG delete with native confirm |
| ON-ERROR, KEY-HELP | UI-ONLY | **dropped** → error handler (FK `ICS_HI_FK` text, §4) / obsolete help |
| SUSPN_STRT_DT WHEN-VALIDATE-ITEM | VALIDATION | `SUSPN_STRT_DT_VALIDATION` |
| SUSPN_END_DT WHEN-VALIDATE-ITEM | VALIDATION | `SUSPN_END_DT_VALIDATION` |
| SUSPN_STRT_DT / SUSPN_END_DT KEY-LISTVAL, KEY-F4 (4) | UI-ONLY | **dropped**: Hijri calendar forms → Hijri text column (f345 picker) |
| SUSPN_SEQ, SUSPN_RSN_TEXT KEY-LISTVAL | UI-ONLY | **dropped**: Designer LOV check only |

### 1.5 Program units (26)

| Program unit | Member / target |
|---|---|
| SINGLE_IMP_LOV | **dropped** → search page 112501 (filters on `SINGLE_IMPORTERS`: Arabic name, `HQ_IMPR_NBR`, `BUS_ID`, `BUS_ID_BRNCH`) |
| DELETE_SUSPS_LOV | **dropped** → dialog page 112502 |
| CGUV$CHK_HI_PK, CGFK$CHK_IMPR_CNTRL_SUSPNS_ICS | **dropped**: not called by active code (PK / FK enforced by the database) |
| CG$WHEN_NEW_FORM_INSTANCE, CGDV$POPULATE_DYNAMIC_LISTS | **dropped** → shared LOVs through `LOV_APX` (CG_REF_CODES domains) |
| CGTE$CHECK_CONSTRAINT_VIO | **dropped** → f345 error handler |
| CGBS$TOGGLE, CGBS$SET_QUERY_MODE, CGBS$MESSAGE_QUERY_MODE | **dropped**: Designer query-mode toggle |
| EXECUTE_FUNCTION, MOUSE_CLICK, EXEC_FUNS, ADJ_FUNS | **dropped** → page 0 FUNCS drawer (f345 Page Functions) |
| CHECK_TIMEOUT, TOGGEL_WND, PRINT_REPORT, TERMINATE_FUN, CHECK_EDI_MSG_LOV, CHECK_EDI_MSG_TIMER, CHECK_EDI_ROLE_ID, EDI_MSG_LOV, FOR_EDI_MSG, RETURN_MSG, TURN_MSG, WHEN_TIMER_EXPIRED_MSG | **dropped**: `NIB` wrappers, not called |

## 2. Built-in replacements

| Trigger | Built-in | Replacement | Where |
|---|---|---|---|
| BUS_ID / HQ_IMPR_NBR WVI, POST-QUERY, WNFI | `:GLOBAL.HQ_IMPR_NBR`, `:GLOBAL.BUS_NBR`, `:GLOBAL.BUS_ID` | `P0_PAGE_PK` (ROWID) | `*_WHEN_VALIDATE_ITEM`, search page link |
| HQ_IMPRS.WHEN-NEW-ITEM-INSTANCE | `CLEAR_BLOCK`, `GO_BLOCK`, `EXECUTE_QUERY` | Submit `EXECUTE_QUERY` → Form region reload | DA + process |
| BUS_ID / HQ_IMPR_NBR / SUSPN_END_DT WVI | `STR.DISPALERT(…, 'ERROR')` + `FORM_TRIGGER_FAILURE` | error text of `<ITEM>_VALIDATION` + `FORMS_APX.CHECK_ERROR` | package / FOS DA |
| HQ_IMPRS.POST-QUERY | `STR.DispALERT(…, 'CONFIRM')`, `alert_button1` | native Confirm | DA |
| SINGLE_IMP_LOV, DELETE_SUSPS_LOV, EXECUTE_FUNCTION | `CALL_FORM`, `CREATE_PARAMETER_LIST`, `ADD_PARAMETER` | link to modal page 112501 / 112502, page 0 FUNCS | page / DA |
| BUT_SH_HQNUM | `GO_ITEM`, `DO_KEY('LIST_VALUES')` | link to page 112501 | page |
| date WVI | `:System.TRIGGER_ITEM / CURSOR_ITEM / Cursor_Value`, `HIJDATE.VALID_HIJ_DATE` | column value, `FORMS_APX.HIJRI_DATE_ERROR` | package |
| ON-DELETE | `HIJDATE.CUR_HIJ_DATE` | `FORMS_APX.CUR_HIJ_DATE` | package |
| PRE-INSERT / PRE-UPDATE / ON-DELETE | `ACTIVITY.ADD_ACTIVITY` + `RAISE FORM_TRIGGER_FAILURE` | `ACTIVITY_DB.ADD_ACTIVITY` + `FORMS_APX.FORM_TRIGGER_FAILURE` | private `add_activity` |
| POST-INSERT | `STANDARD.COMMIT` | removed | – |
| PRE-INSERT / UPDATE / ON-DELETE | `:PARAMETER.P_CURR_PORT_CD`, `P_USER_ID`, `P_WS_ID` | `P_CURR_PORT_CD`, `SSO_APP_USER`, `P_GLOBAL_V_WS_ID` (f345 items) | parameters |
| KEY-DELREC | `TMPLT.KEY_DELETE_RECORD` (confirm, `Delete_record`, COMMIT) | IG delete | IG |
| CGDV$POPULATE_DYNAMIC_LISTS | `CREATE_GROUP_FROM_QUERY`, `POPULATE_GROUP`, `POPULATE_LIST` | shared LOVs (`LOV_APX`) | step 03 |
| PRE-FORM | `FORMS_DDL`, `SET_APPLICATION_PROPERTY` | f345 Globalization | – |

## 3. Package members and the APEX components that call them

| Member | Source | APEX component (step 03) |
|---|---|---|
| `P0_PAGE_PK_CHECK` | f345 key check | process `P0_PAGE_PK CHECK` (Before Header) |
| `HQ_IMPRS_POST_QUERY` | HQ_IMPRS.POST-QUERY | process `POST-QUERY` (Before Header) |
| `RELEASED_SUSPENSIONS_EXIST` | HQ_IMPRS.POST-QUERY | condition of DA `HQ_IMPRS POST-QUERY` |
| `BUS_ID_VALIDATION` | BUS_ID.WVI | validation `BUS_ID VALIDATION`, DA `BUS_ID WHEN-VALIDATE-ITEM` |
| `BUS_ID_WHEN_VALIDATE_ITEM` | BUS_ID.WVI | process `BUS_ID EXECUTE-QUERY` |
| `HQ_IMPR_NBR_VALIDATION` | HQ_IMPR_NBR.WVI | validation `HQ_IMPR_NBR VALIDATION`, DA `HQ_IMPR_NBR WHEN-VALIDATE-ITEM` |
| `HQ_IMPR_NBR_WHEN_VALIDATE_ITEM` | HQ_IMPR_NBR.WVI | process `HQ_IMPR_NBR EXECUTE-QUERY` |
| `PRE_DELETE` | block Delete Allowed = false | process `PRE-DELETE` (request DELETE) |
| `SUSPN_STRT_DT_VALIDATION` | SUSPN_STRT_DT.WVI | validation / DA `IMPR_CNTRL_SUSPNS SUSPN_STRT_DT …` |
| `SUSPN_END_DT_VALIDATION` | SUSPN_END_DT.WVI | validation / DA `IMPR_CNTRL_SUSPNS SUSPN_END_DT …` |
| `IMPR_CNTRL_SUSPNS_PRE_INSERT`, `_POST_INSERT`, `_PRE_UPDATE`, `_ON_DELETE` | block DML triggers | called by `IMPR_CNTRL_SUSPNS_SAVE_ROW` |
| `IMPR_CNTRL_SUSPNS_SAVE_ROW` | Forms row posting | IG process `IMPR_CNTRL_SUSPNS - Save Interactive Grid Data` (PL/SQL Code) |

## 4. Error texts

| Text | Raised by | Source |
|---|---|---|
| رقم الاستدلالي للمستورد المدخل غير صحيح، أدخل الرقم الصحيح أو استخدم القائمة المرفقة | `BUS_ID_VALIDATION` | BUS_ID.WVI |
| الرقم الموحد للمستورد المدخل غير صحيح، أدخل الرقم الصحيح أو استخدم القائمة المرفقة | `HQ_IMPR_NBR_VALIDATION` | HQ_IMPR_NBR.WVI |
| لا يمكن ان يكون تاريخ نهاية الأيقاف أصغر من تاريخ بداية الأيقاف | `SUSPN_END_DT_VALIDATION` | SUSPN_END_DT.WVI |
| Hijri date format / validity message | `FORMS_APX.HIJRI_DATE_ERROR` | `HIJDATE.VALID_HIJ_DATE` |
| `ACTIVITY_DB` message (V_MSG_TXT) | `add_activity` | `ACTIVITY.ADD_ACTIVITY` |
| لا يمكن حذف بيانات المستورد من هذه الشاشة - احذف التوقيف من الجدول | `PRE_DELETE` | FRM-41049 (text as IMPR1120, TODO confirm) |
| توجد إيقافات محذوفة من على هذا المستورد , هل تود أستعراضها ؟ | DA Confirm text | POST-QUERY |

All errors go through `FORMS_APX.FORM_TRIGGER_FAILURE` / `CHECK_ERROR` (no own -20xxx codes).

## 5. UI logic for Dynamic Actions (input for step 03)

| DA / setting | Source | Implementation |
|---|---|---|
| `HQ_IMPR_NBR WHEN-VALIDATE-ITEM` | HQ_IMPR_NBR.WVI + block WNII | change → FOS `FORMS_APX.CHECK_ERROR(IMPR1125.HQ_IMPR_NBR_VALIDATION(...))` → Submit `EXECUTE_QUERY` |
| `BUS_ID WHEN-VALIDATE-ITEM` | BUS_ID.WVI + block WNII | same with `BUS_ID_VALIDATION` |
| `HQ_IMPRS POST-QUERY` | POST-QUERY CONFIRM | Page Load, condition `RELEASED_SUSPENSIONS_EXIST` → Confirm → open 112502 |
| Read-only master items | OLB classes `_DO`, insert / update false | all HQ_IMPRS items Read Only; `BUS_ID`, `HQ_IMPR_NBR` editable only while `P0_PAGE_PK` is null |
| `SUSPN_RSN_CD` hidden, default 1; `SUSPN_SIDE_CD` display only, default 5 | item properties | IG column settings |
| `IMPR_CNTRL_SUSPNS SUSPN_STRT_DT / SUSPN_END_DT WHEN-VALIDATE-ITEM` | WVI | column change → FOS `CHECK_ERROR(...)` |
| Hijri date columns | `CGSO$HDATE_ARB`, calendar forms | Text Field, HIJRI_DATE_FORMAT, class `hijri-date-default` |
| IG delete | KEY-DELREC | native IG delete; soft delete in `SAVE_ROW` |

## 6. Globals and parameters

| Forms | APEX |
|---|---|
| `:PARAMETER.P_CURR_PORT_CD` | f345 application item `P_CURR_PORT_CD` |
| `:PARAMETER.P_USER_ID` | `SSO_APP_USER` |
| `:PARAMETER.P_WS_ID` | `P_GLOBAL_V_WS_ID` |
| `:PARAMETER.P_MODULE_ID` | page item of the f345 header (`FORMS_APX.GET_MODULE_ID`) |
| `:PARAMETER.CURRENT_SIDE` | **not migrated** (read nowhere) |
| `:GLOBAL.HQ_IMPR_NBR`, `BUS_NBR`, `BUS_ID`, `ARBC_IMPR_NAME` | `P0_PAGE_PK` (no application item) |
| `:GLOBAL.CURRENT_VER`, `EXIT`, `SYSTEM_OBJ`, `CG$*` | dropped (frame / Designer) |
| `LOV_DELETE_IMP_SUSP :PARAMETER.P_HQ_IMPR_NBR` | page item `P112502_P_HQ_IMPR_NBR` (set by the link) |

## 7. Grants needed by LIB_APX_USR (definer rights)

SELECT on `HQ_IMPRS`, `SINGLE_IMPORTERS`, `BUS_ID_TYPES`, `COUNTRIES`, `CITIES`, `IMPR_TYPES`, `CG_REF_CODES`, `IMPORTER_BASIC_DATA`; SELECT / INSERT / UPDATE on `IMPR_CNTRL_SUSPNS`; EXECUTE on `ACTIVITY_DB`, `HIJDATE_DB`, `FORMS_APX`, `GNRL`, `SMS_MESSAGE`, `LIB_APX_USR.APEX_NOTIFICATIONS` (own schema).

## 8. Dropped logic, HIGH items and TODOs

| # | Item | Status |
|---|---|---|
| 1 | **HIGH**: `STANDARD.COMMIT` in POST-INSERT (per inserted row) removed | APEX commits once; the SMS may now be sent for a row whose save later fails (inventory §15 #4) |
| 2 | **HIGH**: notification errors hidden (`WHEN OTHERS THEN NULL`); NULL mobile in the `NE_INTEGRATION = 1` branch | preserved; `-- SUGGESTION:` in the body |
| 3 | `SINGLE_IMPORTERS` TOO_MANY_ROWS in POST-QUERY | preserved (error); `-- SUGGESTION:` ROWNUM = 1 after data-owner answer (§15 #3) |
| 4 | `MAX + 1` key | preserved; `-- SUGGESTION:` sequence |
| 5 | TODO: MISSING SOURCE `GNRL`, `SMS_MESSAGE`, `LIB_APX_USR.APEX_NOTIFICATIONS` | signatures copied from the Forms code |
| 6 | TODO: Arabic text of FRM-41049 (`PRE_DELETE`) | same as IMPR1120 |
| 7 | TODO: lost-update check in `SAVE_ROW` | decide in step 04 (as IMPR1120) |

## 9. Self-check

| Check | Result |
|---|---|
| Forms built-ins / `:SYSTEM.` / `:GLOBAL.` / COMMIT / ROLLBACK outside comments | none |
| `pkg_impr1125`, `AI_`, `IMPR1125_APX` | none |
| Common helpers defined locally (`scripts/forms_apx_helpers.py leftovers`, `unknown_calls`) | none |
| Unqualified parameters in SQL, private functions in SQL (`scripts/parameter_names.py`) | none |
| Identifiers > 30 bytes | only in comments (full names of shortened members) |
| Owner `LIB_APX_USR`, version block, `PKG_VERSION`, synonym + 4 grants | present |
| Every trigger of the inventory classified | yes (§1) |
