# IMPR1116 — Logic extraction (step 02, revision 1)

| Item | Value |
|---|---|
| Form | `IMPR1116.fmb` — "شاشة استعراض بيانات رقم المنشأة 700 المدخلة من البوابة" (review of the portal establishment-number-700 data) |
| Date | 2026-11-24 |
| Input | `analysis/IMPR1116/IMPR1116_inventory.md` (step 01), `forms/IMPR/IMPR1116_fmb.xml`, `forms/COMMON/libraries/CIC_LIB.pld`, `plsql/Shared/ACTIVITY_DB.pks`, `plsql_templates/lov_apx.sql` |
| Standard | CLAUDE.md §3.2, §4, §4a–§4d, §6, §7; `docs/f345_reference_standard.md` §5, §6, §9, §10; prompt 02 rules 1–15 |
| Package | `LIB_APX_USR.IMPR1116` version **001**: [impr1116_spec.sql](../../plsql/IMPR1116/impr1116_spec.sql), [impr1116_body.sql](../../plsql/IMPR1116/impr1116_body.sql). First version, so no rollback copy |
| Pages | main page **1116** (`IMPR1116`), search page **111601** (`IMPR1116_SEARCH`); same numbering as IMPR1110 → 1110, IMPR1120 → 1120 |
| Status | **NOT COMPILED** (no database in this session). The structural self-check passed (§9) |

## 0. Summary

- **6 public members:**
  - f345 helper `P0_PAGE_PK_CHECK`.
  - `IMPR_PRTL_NAT_IS_PENDING`.
  - `PRE_INSERT`, `PRE_UPDATE`, `PRE_DELETE`.
  - `PKG_VERSION`.
- **1 private helper:** `add_activity`.
- The longest member has 15 lines. Common helpers are called from `FORMS_APX` 004 (`FORM_TRIGGER_FAILURE`, `ROWID_FROM_URL`; the page calls `CHECK_ERROR`, `GET_MODULE_ID` and `HEADER_TITLE`).
- **Why the package is so small.** Of the 230 triggers, 65 contain code and 59 of those are the CIC_OLB frame or Designer boilerplate, identical to IMPR1120. The rest of the form is:
  - 3 activity-log triggers;
  - 1 detail requery;
  - 1 FK lookup;
  - 2 dynamic lists.
  The requery, the lookup and the lists become region SQL and shared LOVs, not PL/SQL (prompt rule 6).
- **APEX page shape (input for step 03).** This is a design decision, see §8 #1:
  - Search page 111601 = Forms Enter Query / Execute Query on `IMPR_PRTL_NAT`. It lists the pending rows (`IMPR_PRTL_NAT_IS_PENDING = 'Y'`) (all on opening; the search text narrows them, user request 2026-11-26); a row link sets `P0_PAGE_PK` to the URL-safe ROWID.
  - Main page 1116 has a Form region `IMPR_PRTL_NAT` (one record, every item read only except `REVIEW_FLAG`) and below it a read-only IG `IMPORTERS`, queried with the Forms WHERE on the five identification items of the record.
  - Page 0 `SAVE` → `PRE-UPDATE` (activity log) → `Process form`. `CREATE` / `DELETE` are refused by `PRE_INSERT` / `PRE_DELETE`, because the Forms block forbids insert and delete.
- **Business rules kept:**
  - the pending-row filter;
  - only `REVIEW_FLAG` is editable;
  - activity log `ACTIVITY_DB.ADD_ACTIVITY(9, 8, 2, PRTL_NAT_ISN)` on update, raising the `ACTIVITY_DB` message on failure;
  - the importers grid uses the exact Forms join, including `NVL(BUS_ID_BRNCH, 0)`;
  - type names come from `IMPR_TYPE_ID_TYPES` / `IMPR_TYPES` / `BUS_ID_TYPES`;
  - list values come from `CG_REF_CODES` domains `ID_TYPE_GZT` and `PRTL_NAT_FLAG`;
  - no port filter.
- **Changed, and why:**

| Change | Reason |
|---|---|
| Five portal rows shown at once → one record per page, chosen from the list on page 111601 | f345 master standard: Form region + `P0_PAGE_PK`; the page 0 toolbar works on one key (§8 #1) |
| PRE-INSERT / PRE-DELETE (activity log 1 / 3) → `PRE_INSERT` / `PRE_DELETE` refuse the request with a text | The Forms triggers cannot fire (block Insert / Delete Allowed = false), but the page 0 toolbar offers CREATE / DELETE. Texts to agree (§8 #4) |
| WHEN-NEW-RECORD-INSTANCE requery (`GO_BLOCK` / `CLEAR_BLOCK` / `EXECUTE_QUERY`, errors ignored) → IG region SQL with the master page items as binds | Declarative master-detail (§6) |
| POST-QUERY message "رمز النشاط التجاري غير صحيح" when the type pair is unknown → names left empty (outer join) | One SQL query instead of N lookups; the message did not stop the query in Forms either |
| `COMMIT` of TOOLBAR.SAVE not carried over | APEX commits at the end of the request (rule 10) |

## 1. Trigger classification

Group names come from prompt 02. "Member / target" is the package member, the APEX component, or *dropped* with the reason. Every trigger of inventory §6 appears below.

### 1.1 Form level (26 triggers)

| Trigger | Group | Member / target |
|---|---|---|
| PRE-FORM | INITIALISATION | **dropped**: `NIB.PRE_FORM` (f345 shell), `SET_APPLICATION_PROPERTY` / `FORMS_DDL('ALTER SESSION SET NLS_DATE_FORMAT…')` → f345 Globalization attributes, `CGHP$PRE_FORM` help path (obsolete) |
| WHEN-NEW-FORM-INSTANCE | INITIALISATION + UI-ONLY | split: `NIB.WHEN_NEW_FORM_INSTANCE` → f345 shell; `CG$WHEN_NEW_FORM_INSTANCE` (lists) → shared LOVs; form-specific tail (hide `PORT_CD2` / `L_BIT_BUS_ID_TYPE_NAME2`, item widths, message level) → **UI only**, no component (body UI LOGIC) |
| KEY-EDIT, KEY-DUPREC, KEY-ENTQRY, KEY-CLRBLK, KEY-DELREC, KEY-F5, KEY-NXTREC, KEY-PRVREC, KEY-DOWN, KEY-UP, KEY-SCRUP, KEY-SCRDOWN, KEY-PRINT, KEY-EXIT, KEY-EXEQRY (15) | NAVIGATION | **dropped**: one-line `NIB.KEY_*` delegations → page 0 toolbar (`SEARCH` = Enter / Execute Query, `CLEAR`, `DELETE`, `BACK`) |
| KEY-CLRFRM | NAVIGATION | **dropped**: Designer clear-form commit dialogue → page 0 `CLEAR` + APEX unsaved-changes warning |
| KEY-HELP | UI-ONLY | **dropped**: MS-Help (`CGHP$CALL_MS_HELP`) |
| KEY-F9 | UI-ONLY | **dropped**: side-menu toggle (`TMPLT.POPULATE_FUNCTIONS`, `ADJ_FUNS` empty) → page 0 `FUNCS` |
| ON-ERROR, ON-MESSAGE | UI-ONLY | **dropped**: `NIB.ON_ERROR / ON_MESSAGE` → f345 `APP_ERROR_HANDLER` |
| WHEN-TIMER-EXPIRED, WHEN-WINDOW-ACTIVATED, WHEN-MOUSE-DOWN | UI-ONLY | **dropped**: timers / window (IMPR1110 decision of 2026-11-19; inventory §15 #8) |
| KEY-F4 (OLB) | NAVIGATION | **dropped**: OLB frame |

### 1.2 Blocks TOOLBAR, TITLE, EDI_MSG, LSIDE (OLB frame)

| Triggers | Group | Member / target |
|---|---|---|
| TOOLBAR KEY-DOWN / KEY-UP / KEY-NEXT-ITEM, FUN_BUT WHEN-MOUSE-UP / DOWN | NAVIGATION | **dropped**: side-menu keyboard → f345 Page Functions |
| TOOLBAR.SAVE / EXIT / EXIT1 / LAST_REC / RE_ENTER_QUERY / PAGE_DOWN WHEN-BUTTON-PRESSED, + 13 OLB toolbar buttons | BUTTON ACTIONS | **dropped** → page 0 toolbar (`SAVE` commits through APEX; `EXIT` → `BACK`; `RE_ENTER_QUERY` → `SEARCH`); title refresh is the f345 header |
| TITLE.SYSTEM_DATE WHEN-VALIDATE-ITEM, TITLE 5 KEY-LISTVAL, EDI_MSG 1, LSIDE 150 mouse triggers | UI-ONLY | **dropped**: screen frame |

### 1.3 Block IMPR_PRTL_NAT (master)

| Trigger | Group | Member / target |
|---|---|---|
| block WHERE clause (property) | QUERY | `IMPR_PRTL_NAT_IS_PENDING` in the search page 111601 SQL |
| ON-ERROR | UI-ONLY | **dropped**: Designer `CGTE$` error trap with generic texts → `APP_ERROR_HANDLER` |
| KEY-HELP | UI-ONLY | **dropped**: MS-Help |
| PRE-INSERT | PRE/POST DML | `PRE_INSERT` (refuses the request: Insert Allowed = false; the log of type 1 cannot happen) → process `PRE-INSERT` (request CREATE) |
| PRE-UPDATE | PRE/POST DML | `PRE_UPDATE` → process `PRE-UPDATE` (request SAVE) |
| PRE-DELETE | PRE/POST DML | `PRE_DELETE` (refuses: Delete Allowed = false) → process `PRE-DELETE` (request DELETE) |
| WHEN-NEW-RECORD-INSTANCE | NAVIGATION | **no member**: requery of `IMPORTERS` → IG region SQL with master page-item binds (§6) |
| PRTL_NAT_ISN, BUS_ID, BUS_ID_BRNCH, TIN_NBR, ID_TYPE_GZT, BUS_ID_NEW, USER_ID, GAZT_NAME, REVIEW_FLAG KEY-LISTVAL (9) | NAVIGATION | **dropped**: Designer "may the LOV be shown" check → item read-only state (§4) |

### 1.4 Block IMPORTERS (detail, query only)

| Trigger | Group | Member / target |
|---|---|---|
| POST-QUERY | QUERY | **no member**: `CGFK$QRY_IMPORTERS_IMP_ITIDT_F` → outer joins in the IG region SQL |
| ON-ERROR | UI-ONLY | **dropped** → `APP_ERROR_HANDLER` |
| KEY-HELP | UI-ONLY | **dropped**: MS-Help |
| PORT_CD, IMPR_NBR, HQ_IMPR_NBR, BUS_ID, BUS_ID_BRNCH, L_IT1_IMPR_TYPE_NAME, ARBC_IMPR_NAME, L_BIT_BUS_ID_TYPE_NAME KEY-LISTVAL (8) | NAVIGATION | **dropped**: Designer check; IG not editable |
| PORT_CD2, L_BIT_BUS_ID_TYPE_NAME2 WHEN-BUTTON-PRESSED | BUTTON ACTIONS | **dropped**: LOV buttons, hidden by WHEN-NEW-FORM-INSTANCE |

### 1.5 Program units (20)

| Program unit | Member / target |
|---|---|
| CGFK$QRY_IMPORTERS_IMP_ITIDT_F | **SQL**: outer joins in the IG `IMPORTERS` region (no PL/SQL member: nothing else calls it) |
| CG$WHEN_NEW_FORM_INSTANCE, CGDV$POPULATE_DYNAMIC_LISTS | **dropped** → shared LOVs `LOV_ID_TYPE_GZT`, `LOV_PRTL_NAT_FLAG` = `LOV_APX.REFERENCE_CODES(P_DOMAIN => 'ID_TYPE_GZT' / 'PRTL_NAT_FLAG')` (existing function, LOV_APX unchanged) |
| CGTE$CHECK_CONSTRAINT_VIO | **dropped** → `APP_ERROR_HANDLER` (generic text only in this form) |
| EXECUTE_FUNCTION, MOUSE_CLICK | **dropped** → f345 Page Functions list (`FUNCS`); module functions unknown (inventory §15 #6) |
| ADJ_FUNS, EXEC_FUNS | **dropped**: empty (`NULL;`) |
| CHECK_TIMEOUT, TOGGEL_WND, PRINT_REPORT, TERMINATE_FUN, CHECK_EDI_MSG_LOV, CHECK_EDI_MSG_TIMER, CHECK_EDI_ROLE_ID, EDI_MSG_LOV, FOR_EDI_MSG, RETURN_MSG, TURN_MSG, WHEN_TIMER_EXPIRED_MSG | **dropped**: `NIB` wrappers (timers, EDI ticker, window) |

## 2. Built-in replacements

| Trigger | Built-in | Replacement | Where |
|---|---|---|---|
| PRE-FORM | `FORMS_DDL('ALTER SESSION …')`, `SET_APPLICATION_PROPERTY` | f345 Globalization | application |
| WHEN-NEW-FORM-INSTANCE | `SET_ITEM_PROPERTY(VISIBLE / WIDTH)`, `:SYSTEM.MESSAGE_LEVEL` | buttons not created, IG column widths | page |
| IMPR_PRTL_NAT.WNRI | `GO_BLOCK`, `CLEAR_BLOCK`, `EXECUTE_QUERY`, `:SYSTEM.MESSAGE_LEVEL` | IG region SQL with binds `P1116_IMPR_TYPE_CD`, `P1116_CTRY_CD`, `P1116_BUS_ID_TYPE_CD`, `P1116_BUS_ID`, `P1116_BUS_ID_BRNCH` | region |
| IMPR_PRTL_NAT PRE-INSERT / PRE-UPDATE / PRE-DELETE | `ACTIVITY.ADD_ACTIVITY` + `RAISE FORM_TRIGGER_FAILURE` | private `add_activity` → `ACTIVITY_DB.ADD_ACTIVITY` (8-argument overload) + `FORMS_APX.FORM_TRIGGER_FAILURE`; insert / delete refused | PL/SQL |
| IMPORTERS.POST-QUERY | `NAME_IN`, `SET_RECORD_PROPERTY(QUERY_STATUS)`, `Des$Form_errors.PUSH`, `CGTE$OTHER_EXCEPTIONS` | outer joins; not needed | region SQL |
| KEY-LISTVAL (17) | `GET_RECORD_PROPERTY`, `GET_BLOCK_PROPERTY`, `GET_ITEM_PROPERTY`, `:SYSTEM.MODE / CURSOR_*` | item read-only state | items |
| LOV buttons | `GO_ITEM` + `DO_KEY('List_values')` | not created | – |
| CGDV$POPULATE_DYNAMIC_LISTS | `CREATE_GROUP_FROM_QUERY`, `POPULATE_GROUP`, `POPULATE_LIST`, `DELETE_GROUP` | `LOV_APX.REFERENCE_CODES` shared LOVs | Shared Components |
| ON-ERROR (2) | `ERROR_CODE / ERROR_TYPE / DBMS_ERROR_*`, `CGTE$*`, `Des$Form_errors.*` | `APP_ERROR_HANDLER` | application |
| TOOLBAR.SAVE | `COMMIT` | APEX commit at end of request | – |
| :PARAMETER.* | `P_CURR_PORT_CD`, `P_USER_ID`, `P_WS_ID` (inside `ACTIVITY.ADD_ACTIVITY`) | `P_CURR_PORT_CD`, `SSO_APP_USER`, `P_GLOBAL_V_WS_ID` | parameters (§7) |

## 3. Package members and the f345 component that calls them

| # | Member | Source | APEX component (page 1116 unless noted) |
|---|---|---|---|
| 1 | `P0_PAGE_PK_CHECK(P_PAGE_PK)` | f345 helper | process `P0_PAGE_PK CHECK` (Before Header 20) |
| 2 | `IMPR_PRTL_NAT_IS_PENDING(REVIEW_FLAG, GAZT_NAME)` | block WHERE clause | page 111601 region SQL |
| 3 | `PRE_INSERT` | IMPR_PRTL_NAT.PRE-INSERT + Insert Allowed = false | process `PRE-INSERT` (After Submit 10, request CREATE) |
| 4 | `PRE_UPDATE(P_PRTL_NAT_ISN, P_CURR_PORT_CD, SSO_APP_USER, P_GLOBAL_V_WS_ID)` | IMPR_PRTL_NAT.PRE-UPDATE | process `PRE-UPDATE` (After Submit 20, request SAVE, `P0_PAGE_PK` not null) |
| 5 | `PRE_DELETE` | IMPR_PRTL_NAT.PRE-DELETE + Delete Allowed = false | process `PRE-DELETE` (After Submit 30, request DELETE) |
| 6 | `PKG_VERSION` | standard | – |
| – | `FORMS_APX.GET_MODULE_ID` / `FORMS_APX.HEADER_TITLE` | f345 (common) | processes `PARAMETERS` (40) / `HEADER TITLE` (100) |

## 4. Read-only and required rules

| Rule (Forms) | APEX |
|---|---|
| All `IMPR_PRTL_NAT` items `UpdateAllowed=false` except `REVIEW_FLAG`; `InsertAllowed=false` everywhere | Form region items Read Only = Always, except `P1116_REVIEW_FLAG` (Select List). No `_IS_READ_ONLY` function is needed: the rule is static |
| `REVIEW_FLAG` read only while no record is loaded (Forms: no record) | `P1116_REVIEW_FLAG` Read Only when `P0_PAGE_PK` is null (declarative condition) |
| `IMPORTERS` Insert / Update / Delete = false | IG not editable |
| Required items | none in the XML (every `Required` is false or absent) |

## 5. Messages and errors

| Source | Text | Raised by |
|---|---|---|
| `ACTIVITY_DB.ADD_ACTIVITY` returns 0 | `V_MSG_TXT` from `ACTIVITY_DB` (Forms alert `CFG_SYSTEM_ERROR`) | `add_activity` → `FORMS_APX.FORM_TRIGGER_FAILURE` |
| Block Insert Allowed = false (new text) | لا يمكن إضافة بيانات من هذه الشاشة | `PRE_INSERT` |
| Block Delete Allowed = false (new text) | لا يمكن حذف بيانات من هذه الشاشة | `PRE_DELETE` |
| IMPORTERS.POST-QUERY NO_DATA_FOUND | رمز النشاط التجاري غير صحيح - أعد إدخال البيانات | **dropped** (outer join, names empty) |

No `-20xxx` codes of its own: `FORMS_APX.FORM_TRIGGER_FAILURE` raises its standard code.

## 6. UI logic for dynamic actions (input for step 03)

| # | Source | Target |
|---|---|---|
| 1 | IMPR_PRTL_NAT.WHEN-NEW-RECORD-INSTANCE (requery `IMPORTERS`) | no DA: IG `IMPORTERS` region SQL with `:P1116_IMPR_TYPE_CD`, `:P1116_CTRY_CD`, `:P1116_BUS_ID_TYPE_CD`, `:P1116_BUS_ID`, `NVL(:P1116_BUS_ID_BRNCH, 0)`; items in *Page Items to Submit* |
| 2 | WHEN-NEW-FORM-INSTANCE: hide two LOV buttons, set widths | no DA: buttons not created, IG column widths |
| 3 | 17 KEY-LISTVAL Designer checks | static Read Only (§4) |
| 4 | CGDV$POPULATE_DYNAMIC_LISTS | `P1116_ID_TYPE_GZT` (display only, LOV `LOV_ID_TYPE_GZT`), `P1116_REVIEW_FLAG` (Select List, `LOV_PRTL_NAT_FLAG`); the same LOVs as display columns on page 111601 |

No JavaScript is needed.

## 7. Parameters and globals → APEX items

| Forms | APEX | Used by |
|---|---|---|
| `:PARAMETER.P_CURR_PORT_CD` | f345 application item `P_CURR_PORT_CD` | `PRE_UPDATE` (activity log only) |
| `:PARAMETER.P_USER_ID` | f345 `SSO_APP_USER` | `PRE_UPDATE` |
| `:PARAMETER.P_WS_ID` | f345 `P_GLOBAL_V_WS_ID` | `PRE_UPDATE` |
| `:PARAMETER.P_MODULE_ID` / `P_MODULE_NAME` / `P_USER_NAME` | `P1116_MODULE_ID` (`FORMS_APX.GET_MODULE_ID`), f345 header | page |
| other `P_*` (OLB) | not used by business code | – |
| `:GLOBAL.CG$HP_HFILE`, `CG$HP_HPATH`, `EXIT`, `SYSTEM_OBJ` | **dropped** (help, frame) | – |
| Current record key | `P0_PAGE_PK` = ROWID of `IMPR_PRTL_NAT` | page 0 toolbar |

No new application item.

## 8. Dropped logic, TODOs, assumptions and missing sources

| # | Item | Status |
|---|---|---|
| 1 | **Design decision: one record per page instead of the 5-row grid.** The Forms master block shows 5 portal rows. The f345 standard has one master record per page (`P0_PAGE_PK`, page 0 SAVE only when it is set), so the 5-row list moves to the search page 111601 and the main page reviews one row. Alternative: an editable IG of all pending rows on page 1116 with the importers grid as its detail, but then the page 0 SAVE / CREATE / SEARCH logic does not fit (no key in `P0_PAGE_PK`) | ASSUMPTION, to confirm with the user |
| 2 | `IMPR_PRTL_NAT` DDL (key, column types, DB triggers): `PRTL_NAT_ISN` is used only for the activity log; the page key is the ROWID | MISSING SOURCE (inventory §15 #1) |
| 3 | `USER_ID` / `LST_TRAN_DT` / `UPDATE_DT` not set by the form | `-- SUGGESTION:` in `PRE_UPDATE` (inventory §15 #2) |
| 4 | Texts of the insert / delete refusals | TODO: agree (constants in the body) |
| 5 | Grants to `LIB_APX_USR`: SELECT on `IMPR_PRTL_NAT`, EXECUTE on `ACTIVITY_DB` and `FORMS_APX`. The region SQL runs as `CUSTOMS`: SELECT / UPDATE on `IMPR_PRTL_NAT`, SELECT on `IMPORTERS`, `IMPR_TYPE_ID_TYPES`, `IMPR_TYPES`, `BUS_ID_TYPES`, `CG_REF_CODES` | TODO: DBA |
| 6 | Library calls without source | none used by the business code (`OFGTEL` only in the dropped ON-ERROR) |
| 7 | HIGH-risk items (DB COMMIT inside triggers, HOST, dynamic SQL from user input) | none |

## 9. How the package was built and checked

- Hand-written from the decoded trigger code; every trigger was compared with IMPR1120 by `work/IMPR1116/tmp/diff_trg.py` to separate the frame from the form's own code.
- `scripts/parameter_names.py`:
  - `mapping_from_spec` → no renames needed;
  - `unqualified_in_sql` → none;
  - `private_functions_in_sql` → none.
- `scripts/forms_apx_helpers.py`: `leftovers` → none, `unknown_calls` → none (only `FORMS_APX.FORM_TRIGGER_FAILURE` and `FORMS_APX.ROWID_FROM_URL`).
- Code without comments, searched for `GO_BLOCK`, `GO_ITEM`, `SET_ITEM_PROPERTY`, `SHOW_ALERT`, `EXECUTE_QUERY`, `:SYSTEM.`, `:GLOBAL.`, `NAME_IN`, `COPY(`, `v('P`, `COMMIT` and `ROLLBACK`: no match.
- No identifier is longer than 30 bytes. No `pkg_` / `AI_` names, and no `IMPR1116_APX` adapter.
- Owner `LIB_APX_USR` in both files; version block and `PKG_VERSION` present; synonym and the 4 grants are at the end of the spec.
