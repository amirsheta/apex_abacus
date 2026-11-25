# IMPR1140 — Logic extraction (step 02)

| Item | Value |
|---|---|
| Form | `IMPR1140.fmb` — "قواعد التعامل مع المستوردين" (importer handling rules: excepted ports and tariff items) |
| Date | 2026-11-24 |
| Input | [IMPR1140_inventory.md](IMPR1140_inventory.md) (step 01), `forms/IMPR/IMPR1140_fmb.xml`, `forms/COMMON/libraries/CIC_LIB.pld`, `plsql/Shared/ACTIVITY_DB.*` |
| Standard | CLAUDE.md §3.2, §4, §4a–§4d, §6, §7; `docs/f345_reference_standard.md` §5, §6, §9, §10; prompt 02 rules 1–15 |
| Package | `LIB_APX_USR.IMPR1140` version **001**: [impr1140_spec.sql](../../plsql/IMPR1140/impr1140_spec.sql), [impr1140_body.sql](../../plsql/IMPR1140/impr1140_body.sql) |
| Shared package changed | `LOV_APX` 001 → **002** (`SINGLE_IMPORTERS`, `HARMONIZED_TARIFF`); previous version `rollback/LOV_APX/v001/lov_apx.sql` |
| Pages | main page **1140** (`IMPR1140`), search page **114001** (`IMPR1140_SEARCH`), the numbering of IMPR1110 → 1110 / IMPR1120 → 1120 |
| Status | **NOT COMPILED** (no 12.1.0.2 instance in this session). The structural self-check passed (§9) |

## 0. Summary

- **30 public members** (1 f345 helper, 0 form level, 10 IMPR_RULES, 7 IMPR_RULE_PORTS, 7 IMPR_RULE_TARIFF, 5 program units) and **5 private helpers** (`add_activity`, `importer_mobile`, `send_rule_sms`, `read_importer`, `check_rule_type_role`). The longest member is `CHECK_FASH_ROLE_ID` (≈ 40 lines); none exceeds 80.
- **APEX page shape (input for step 03):** Form region `IMPR_RULES` keyed by the rule's ROWID in `P0_PAGE_PK` (as IMPR1110 / IMPR1120); Tabs Container with editable IG `IMPR_RULE_PORTS` (rows of the user's port) and IG `IMPR_RULE_TARIFF` (insert / update, no delete), both with PL/SQL row DML (`*_SAVE_ROW`); search page 114001.
- **Business rules kept:** RULE_TYPE 9 refused; importer data by unified number (IMPORTERS of the port for type 12, else SINGLE_IMPORTERS); `RULE_ISN = MAX + 1`; role `IMP_EXCEPTION_FASH` for types 13 / 14; SMS for active type-14 rules after insert and update; activity log on every DML (master update in POST-UPDATE); delete refused while the rule has a port row in the user's port (message 1-270) or any port row (CGRI); ports insert refused when the rule applies to all ports; `BUS_ID_BRNCH` cleared when the flag is 1; tariff item must exist (`STA_CODE = 0`) and not be excepted twice for the same importer; `REMAINED_QTY := EXEPTION_QTY`; `ITEM_SEQUENCE = MAX + 1` in the rule; tariff `REC_STATUS` default 1.
- **Changed, and why:**

| Change | Reason |
|---|---|
| COMMIT of `TMPLT.KEY_DELETE_RECORD` and TOOLBAR.SAVE not carried over | CLAUDE.md §6 / prompt rule 10: APEX commits at the end of the request |
| The CGRI delete check runs **before** the delete (Forms: after the COMMIT of `TMPLT.KEY_DELETE_RECORD`) | The Forms order cannot be kept without a commit inside the trigger (inventory §15 #5) |
| New check in `KEY_DELREC`: no delete while tariff rows exist | Relation `CGFK$IRT_IR_FK` is Non-Isolated: Forms refuses that delete itself (FRM-40202). Text to agree (§15 #8) |
| New check in `IMPR_RULE_PORTS_PRE_INSERT` (flag = 1) and in `IMPR_RULE_TARIFF_SAVE_ROW` (delete) | Forms refused those rows through block properties (`INSERT_ALLOWED`, Delete Allowed = false); a browser request is not limited by them, so the server checks. Texts to agree (§15 #6) |
| Non-blocking alert "الوحدة الدولية غير معرفة" not shown | FOS shows errors only; `INTL_UNIT` stays empty (inventory §15 #7) |
| Designer dynamic WHERE (string concatenation) replaced by bind filters | CLAUDE.md §6 #9 |
| LOV-form globals (`:GLOBAL.HQ_IMPR_NBR` …) replaced by Popup LOVs + FOS Items to Return | f345 standard §9 |

## 1. Trigger classification

### 1.1 Form level (34 triggers)

| Trigger | Group | Member / target |
|---|---|---|
| PRE-FORM | INITIALISATION | **dropped**: `NIB.PRE_FORM` (f345 shell); version stamps `:global.current_ver / current_DT / current_version` (frame); `SET_ITEM_PROPERTY('D', VISIBLE, FALSE)` → item D not created; `SET_APPLICATION_PROPERTY` / `FORMS_DDL('ALTER SESSION SET NLS_DATE_FORMAT…')` → f345 Globalization (the form has no date item); `CGHP$PRE_FORM` help path (obsolete) |
| WHEN-NEW-FORM-INSTANCE | INITIALISATION | **dropped**: `NIB.WHEN_NEW_FORM_INSTANCE`, `CGBS2$.SET_COORD_STYLE / SET_QRY_ON_ENTRY`, `CG$WHEN_NEW_FORM_INSTANCE` (lists from CG_REF_CODES, block-sync start-up) → f345 shell / shared LOVs / native master-detail. No business code |
| WHEN-NEW-BLOCK-INSTANCE, ON-CLEAR-DETAILS, ON-POPULATE-DETAILS, WHEN-TAB-PAGE-CHANGED | NAVIGATION | **dropped**: Designer master-detail and tab coordination (`CGBS$`, `CGLT$TAB_BLOCKS`) → native Form + IGs in a Tabs Container |
| KEY-CQUERY, KEY-CLRREC, KEY-NXTKEY, KEY-MENU, KEY-CLRFRM | NAVIGATION | **dropped**: Designer count-query, commit dialogue, key not valid, query-mode toggle, clear form → page 0 toolbar `CLEAR` / IG |
| KEY-HELP | UI-ONLY | **dropped**: MS-Help |
| KEY-F9 | UI-ONLY | **dropped**: side-menu toggle (`TMPLT.POPULATE_FUNCTIONS`, `ADJ_FUNS` empty) → page 0 `FUNCS` |
| ON-ERROR, ON-MESSAGE | UI-ONLY | **dropped**: `NIB.ON_ERROR / ON_MESSAGE` → f345 `APP_ERROR_HANDLER` |
| WHEN-TIMER-EXPIRED, WHEN-WINDOW-ACTIVATED, WHEN-MOUSE-DOWN | UI-ONLY | **dropped**: timers / window (IMPR1110 decision of 2026-11-19, inventory §15 #10) |
| KEY-EDIT, KEY-DUPREC, KEY-ENTQRY, KEY-CLRBLK, KEY-DELREC, KEY-F5, KEY-NXTREC, KEY-PRVREC, KEY-DOWN, KEY-UP, KEY-SCRUP, KEY-SCRDOWN, KEY-PRINT, KEY-EXIT, KEY-EXEQRY (15) | NAVIGATION | **dropped**: one-line `NIB.KEY_*` delegations → page 0 toolbar (`SEARCH`, `CLEAR`, `DELETE`, `BACK`) and IG keyboard |

### 1.2 Blocks TOOLBAR, TITLE, EDI_MSG, LSIDE, CG$CTRL (OLB / Designer frame)

| Triggers | Group | Member / target |
|---|---|---|
| TOOLBAR KEY-DOWN / KEY-UP / KEY-NEXT-ITEM, FUN_BUT WHEN-MOUSE-UP / DOWN | NAVIGATION | **dropped**: side-menu keyboard → f345 Page Functions |
| TOOLBAR.SAVE / EXIT / EXIT1 / LAST_REC / RE_ENTER_QUERY / PAGE_DOWN WHEN-BUTTON-PRESSED and the OLB toolbar buttons | BUTTON ACTIONS | **dropped** → page 0 toolbar (`SAVE` / `CREATE` commit through APEX; `EXIT` → `BACK`; `RE_ENTER_QUERY` → `SEARCH`) |
| TITLE.SYSTEM_DATE WHEN-VALIDATE-ITEM, TITLE / EDI_MSG item triggers, LSIDE mouse triggers | UI-ONLY | **dropped**: screen frame; title → hero region (`HEADER TITLE`) |
| CG$CTRL (no triggers) | — | **dropped**: Designer tab bookkeeping items |

### 1.3 Block IMPR_RULES (master)

| Trigger | Group | Member / target |
|---|---|---|
| IMPR_RULES.PRE-QUERY | QUERY | **dropped**: `CGFK$DEFAULT_WHERE` sub-query for a `BUS_ID_TYPE_NAME` criterion → search page 114001 text search over the joined `BUS_ID_TYPES` name (binds only) |
| IMPR_RULES.POST-QUERY | QUERY | `POST_QUERY` (process `POST-QUERY`); `CGFK$RESET_BLOCK_WHERE_CLAUSE` and `SET_RECORD_PROPERTY` dropped |
| IMPR_RULES.WHEN-NEW-RECORD-INSTANCE | UI-ONLY | `ADJ_BRANCH` (server part) + DA `ALL_BRNCH_FLAG WHEN-VALIDATE-ITEM` fired on page load (enable part) |
| IMPR_RULES.ON-ERROR | UI-ONLY | **dropped** → `APP_ERROR_HANDLER` + Text Messages by constraint name (step 03) |
| IMPR_RULES.KEY-HELP | UI-ONLY | **dropped** (MS-Help) |
| IMPR_RULES.KEY-DELREC | VALIDATION | split: port-row check + CGRI → `KEY_DELREC` (process `KEY-DELREC`); `TMPLT.KEY_DELETE_RECORD` confirm → page 0 DELETE confirm; delete + COMMIT → `Process form - DELETE` |
| IMPR_RULES.PRE-INSERT | PRE/POST DML | `PRE_INSERT` (process `PRE-INSERT`) |
| IMPR_RULES.POST-INSERT | PRE/POST DML | `POST_INSERT` (process `POST-INSERT`) |
| IMPR_RULES.PRE-UPDATE | PRE/POST DML | `PRE_UPDATE` (process `PRE-UPDATE`) |
| IMPR_RULES.POST-UPDATE | PRE/POST DML | `POST_UPDATE` (process `POST-UPDATE`) |
| IMPR_RULES.PRE-DELETE | PRE/POST DML | `PRE_DELETE` (process `PRE-DELETE`) |
| RULE_TYPE WHEN-LIST-CHANGED, WHEN-VALIDATE-ITEM | VALIDATION | `RULE_TYPE_VALIDATION` (validation `RULE_TYPE VALIDATION`, DA `RULE_TYPE WHEN-LIST-CHANGED`) |
| ALL_BRNCH_FLAG WHEN-VALIDATE-ITEM | UI-ONLY + value | `ADJ_BRANCH` (process `ALL_BRNCH_FLAG WHEN-VALIDATE-ITEM`) + DA `ALL_BRNCH_FLAG WHEN-VALIDATE-ITEM` (Enable / Clear + Disable) |
| HQ_IMPR_NBR WHEN-VALIDATE-ITEM | VALIDATION | `HQ_IMPR_NBR_VALIDATION` + `HQ_IMPR_NBR_VALIDATE_ITEM` (full name `HQ_IMPR_NBR_WHEN_VALIDATE_ITEM`, 31 bytes) |
| HQ_IMPR_NBR KEY-LISTVAL (→ `SINGLE_IMP_LOV`), B_IMP WHEN-BUTTON-PRESSED | NAVIGATION | **dropped** → Popup LOV `LOV_SINGLE_IMPORTERS` (`LOV_APX.LOV_SINGLE_IMPORTERS`) |
| KEY-LISTVAL on RULE_ISN, D, L_SI_ARBC_IMPR_NAME, BUS_ID_TYPE_CD, BUS_ID_TYPE_NAME, BUS_ID (6) | UI-ONLY | **dropped**: only the Designer "may the LOV be shown" check → item read-only state |

### 1.4 Block IMPR_RULE_PORTS (detail)

| Trigger | Group | Member / target |
|---|---|---|
| POST-QUERY | QUERY + UI | `PORT_NAME` → join in the grid SQL (`CGFK$QRY_IMPR_RULE_PORTS_IRP_S` replaced by the join); `SET_BLOCK_PROPERTY(INSERT_ALLOWED)` → `IMPR_RULE_PORTS_INSERT_ALLOWED` |
| PRE-RECORD, WHEN-NEW-RECORD-INSTANCE | UI-ONLY | `IMPR_RULE_PORTS_INSERT_ALLOWED` (same code as POST-QUERY) |
| PRE-INSERT | PRE/POST DML | `IMPR_RULE_PORTS_PRE_INSERT`, called by `IMPR_RULE_PORTS_SAVE_ROW` (process `IMPR_RULE_PORTS - Save Interactive Grid Data`) |
| PRE-UPDATE | PRE/POST DML | `IMPR_RULE_PORTS_PRE_UPDATE` (same process) |
| PRE-DELETE | PRE/POST DML | `IMPR_RULE_PORTS_PRE_DELETE` (same process) |
| ON-ERROR, KEY-HELP | UI-ONLY | **dropped** (as IMPR_RULES) |
| PORT_CD WHEN-VALIDATE-ITEM | VALIDATION | `PORT_CD_VALIDATION` + `PORT_CD_WHEN_VALIDATE_ITEM` (block prefix dropped: `IMPR_RULE_PORTS_PORT_CD_VALIDATION` = 34 bytes) |
| PORT_CD KEY-LISTVAL (→ `CALL_SD_PORTS`), PORT_CD2 WHEN-BUTTON-PRESSED | NAVIGATION | **dropped** → Popup LOV column on the existing `LOV_SD_PORTS` |
| PORT_NAME KEY-LISTVAL | UI-ONLY | **dropped** (Designer check) |

### 1.5 Block IMPR_RULE_TARIFF (detail)

| Trigger | Group | Member / target |
|---|---|---|
| POST-QUERY | QUERY | `IMPR_RULE_TARIFF_POST_QUERY` (function used in the grid SQL for `INTL_UNIT`); description → join on `HARMONIZED_TARIFF` |
| PRE-INSERT | PRE/POST DML | `IMPR_RULE_TARIFF_PRE_INSERT`, called by `IMPR_RULE_TARIFF_SAVE_ROW` |
| PRE-UPDATE | PRE/POST DML | `IMPR_RULE_TARIFF_PRE_UPDATE` (same) |
| PRE-DELETE | PRE/POST DML | **dropped**: Delete Allowed = false, the trigger can never fire; a deleted grid row is refused in `IMPR_RULE_TARIFF_SAVE_ROW` |
| ON-ERROR, KEY-HELP | UI-ONLY | **dropped** |
| HRMNZD_CODE WHEN-VALIDATE-ITEM | VALIDATION | `HRMNZD_CODE_VALIDATION` + `HRMNZD_CODE_VALIDATE_ITEM` (block prefix and `WHEN_` dropped: 39 / 45 bytes in full) |
| HRMNZD_CODE POST-CHANGE | VALIDATION (derived) | merged into `HRMNZD_CODE_VALIDATE_ITEM` (same description lookup; on query the join gives it) |
| HRMNZD_CODE KEY-LISTVAL (→ `DSP_TRF_ITEMS_LOV`), HRMNZD_CODE2 WHEN-BUTTON-PRESSED | NAVIGATION | **dropped** → Popup LOV column `LOV_HARMONIZED_TARIFF` (`LOV_APX.LOV_HARMONIZED_TARIFF`) |
| EXEPTION_QTY WHEN-VALIDATE-ITEM | VALIDATION (derived) + UI | `EXEPTION_QTY_VALIDATE_ITEM` (returns `REMAINED_QTY`) + native Alert (INFORMATION text) |
| KEY-LISTVAL on HT_ITEM_ARBC_DESC, REMAINED_QTY, INTL_UNIT, ITEM_SEQUENCE (4) | UI-ONLY | **dropped** (Designer check) |

### 1.6 Program units (39)

| Program unit | Member / target |
|---|---|
| CGFK$QRY_IMPR_RULES_IR_BIT_FK | same name (used by `POST_QUERY`) |
| CGFK$CHK_IMPR_RULE_PORTS_IRP_S | same name (used by `PORT_CD_VALIDATION` / `PORT_CD_WHEN_VALIDATE_ITEM`) |
| CGRI$CHK_IMPR_RULES | same name (used by `KEY_DELREC`; parameter `P_CHECK_BOTH` dropped, always TRUE) |
| CHECK_FASH_ROLE_ID | same name (used by `PRE_INSERT` / `PRE_UPDATE`) |
| ADJ_BRANCH | same name (value part); `MAKE_FIELD_ENTRABLE` → DA |
| CGFK$CHK_IMPR_RULES_IR_BIT_FK, CGFK$QRY_IMPR_RULE_PORTS_IRP_S, CGFK$CHK_IMPR_RULE_PORTS_IRP_I | **dropped**: not called by active code (IR_BIT_FK check), replaced by the grid join (IRP_S query), or enforced by the FK and the master key (IRP_I) |
| SINGLE_IMP_LOV, DSP_TRF_ITEMS_LOV, CALL_SD_PORTS | **dropped** → Popup LOVs (§1.3–1.5) |
| CALL_IMPR_TYPE | **dropped**: called by no trigger |
| CG$WHEN_NEW_FORM_INSTANCE, CGDV$POPULATE_DYNAMIC_LISTS | **dropped** → shared LOVs on `CG_REF_CODES` (`RULE_TYPE`, `REC_STATUS`) |
| CG$IMPR1140_CNTRL_GLOBALS | **dropped**: Designer dynamic WHERE holder |
| CGTE$CHECK_CONSTRAINT_VIO | **dropped** → `APP_ERROR_HANDLER` |
| CGLY$DISPLAY_CANVASES, CGLY$GET_RELATED_CANVASES, CGLY$RAISE_CANVAS, CGLY$CANVAS_MANAGEMENT | **dropped**: Designer canvas layout |
| CGBS$TOGGLE, CGBS$SET_QUERY_MODE, CGBS$MESSAGE_QUERY_MODE | **dropped**: query-mode toggle |
| EXECUTE_FUNCTION, MOUSE_CLICK | **dropped** → f345 Page Functions (module functions unknown, inventory §15 #9) |
| ADJ_FUNS, EXEC_FUNS | **dropped**: empty (`NULL;`) |
| CHECK_TIMEOUT, TOGGEL_WND, PRINT_REPORT, TERMINATE_FUN, CHECK_EDI_MSG_LOV, CHECK_EDI_MSG_TIMER, CHECK_EDI_ROLE_ID, EDI_MSG_LOV, FOR_EDI_MSG, RETURN_MSG, TURN_MSG, WHEN_TIMER_EXPIRED_MSG | **dropped**: `NIB` wrappers (timers, EDI ticker, window, reports) not called by active business code |

## 2. Built-in replacements

| Trigger | Built-in | Replacement | Where |
|---|---|---|---|
| PRE-FORM | `SET_ITEM_PROPERTY('D', VISIBLE)` | item not created | page |
| PRE-FORM | `FORMS_DDL('ALTER SESSION …')`, `SET_APPLICATION_PROPERTY` | f345 Globalization | application |
| IMPR_RULES.PRE-QUERY | `SET_BLOCK_PROPERTY(DEFAULT_WHERE)`, `GET_BLOCK_PROPERTY`, `FIND_BLOCK`, `NAME_IN` | search page SQL with binds | region SQL |
| IMPR_RULES.POST-QUERY / IMPR_RULE_PORTS.POST-QUERY | `SET_RECORD_PROPERTY(QUERY_STATUS)`, `NAME_IN`, `Des$Form_errors.PUSH` | not needed / `FORMS_APX.MESSAGE`, `FORMS_APX.CG_MESSAGE` | `POST_QUERY` |
| IMPR_RULE_PORTS POST-QUERY / PRE-RECORD / WNRI | `SET_BLOCK_PROPERTY(INSERT_ALLOWED)` | `IMPR_RULE_PORTS_INSERT_ALLOWED` + server check | PL/SQL |
| IMPR_RULES.KEY-DELREC | `STR.DispArbMsg(1,270)` + `RAISE FORM_TRIGGER_FAILURE` | `FORMS_APX.FORM_TRIGGER_FAILURE(FORMS_APX.ARABIC_MESSAGE(1, 270))` | `KEY_DELREC` |
| IMPR_RULES.KEY-DELREC | `TMPLT.KEY_DELETE_RECORD` (confirm, `Delete_record`, COMMIT), `delete_record`, `CG$CHK_PACKAGE_FAILURE` | page 0 DELETE confirm → `Process form - DELETE` | page |
| CGRI$CHK_IMPR_RULES, PORT_CD WVI | `Des$Form_errors.PUSH` + `RAISE_FAILURE` | `FORMS_APX.FORM_TRIGGER_FAILURE` / returned error text (`FORMS_APX.CG_MESSAGE`) | PL/SQL |
| all `STR.DispAlert(…,'ERROR')` + FTF | stop alert | returned error text / `FORMS_APX.FORM_TRIGGER_FAILURE` | validations, DML members |
| EXEPTION_QTY WVI | `STR.DispAlert(…,'INFORMATION')` | native Alert action | DA |
| HRMNZD_CODE WVI | `STR.DispAlert` + `RAISE NO_DATA_FOUND` | error text | `HRMNZD_CODE_VALIDATION` |
| ADJ_BRANCH | `INTRFACE.MAKE_FIELD_ENTRABLE` | native Enable / Disable | DA |
| DML triggers | `ACTIVITY.ADD_ACTIVITY` + `RAISE FORM_TRIGGER_FAILURE` | private `add_activity` → `ACTIVITY_DB.ADD_ACTIVITY` (8-argument overload) + `FORMS_APX.FORM_TRIGGER_FAILURE` | PL/SQL |
| KEY-LISTVAL ×3, LOV buttons ×3 | `CALL_FORM`, `CREATE_PARAMETER_LIST`, `ADD_PARAMETER`, `GO_ITEM`, `DO_KEY('LIST_VALUES')`, `:GLOBAL.*` return | Popup LOV + FOS Items to Return | page |
| KEY-LISTVAL ×14 | `GET_RECORD_PROPERTY`, `GET_BLOCK_PROPERTY`, `GET_ITEM_PROPERTY`, `:SYSTEM.MODE / CURSOR_*` | item read-only state | page |
| CGDV$POPULATE_DYNAMIC_LISTS | `CREATE_GROUP_FROM_QUERY`, `POPULATE_GROUP`, `POPULATE_LIST` | shared LOVs `LOV_RULE_TYPE`, `LOV_REC_STATUS` | shared components |
| ON-ERROR ×3 | `ERROR_CODE / DBMS_ERROR_*`, `CGTE$*` | `APP_ERROR_HANDLER` | application |
| :PARAMETER.* | `P_CURR_PORT_CD`, `P_USER_ID`, `P_WS_ID`, `P_PORT_TYPE` | `P_CURR_PORT_CD`, `SSO_APP_USER`, `P_GLOBAL_V_WS_ID`, `P_PORT_TYPE` (f345 items) | parameters |
| — | `COMMIT_FORM`, `EXECUTE_QUERY`, `ENTER_QUERY`, `CLEAR_BLOCK`, `HOST`, `TEXT_IO`, `RUN_REPORT_OBJECT` | not in the business code (only in frame / NIB code, dropped) | — |

## 3. Package members and the APEX component that calls them

| Member | Source trigger | APEX component (page 1140) |
|---|---|---|
| `P0_PAGE_PK_CHECK` | f345 | Before Header `P0_PAGE_PK CHECK` |
| `POST_QUERY` | IMPR_RULES.POST-QUERY | Before Header `POST-QUERY` |
| `RULE_TYPE_VALIDATION` | RULE_TYPE WLC / WVI | validation `RULE_TYPE VALIDATION`, DA `RULE_TYPE WHEN-LIST-CHANGED` |
| `HQ_IMPR_NBR_VALIDATION` | HQ_IMPR_NBR WVI | validation `HQ_IMPR_NBR VALIDATION` |
| `HQ_IMPR_NBR_VALIDATE_ITEM` | HQ_IMPR_NBR WVI | DA `HQ_IMPR_NBR WHEN-VALIDATE-ITEM` (FOS) |
| `KEY_DELREC` | IMPR_RULES.KEY-DELREC | After Submit `KEY-DELREC` |
| `PRE_INSERT` / `POST_INSERT` | IMPR_RULES PRE / POST-INSERT | After Submit `PRE-INSERT` / `POST-INSERT` |
| `PRE_UPDATE` / `POST_UPDATE` | IMPR_RULES PRE / POST-UPDATE | After Submit `PRE-UPDATE` / `POST-UPDATE` |
| `PRE_DELETE` | IMPR_RULES.PRE-DELETE | After Submit `PRE-DELETE` |
| `ADJ_BRANCH` | PU ADJ_BRANCH (ALL_BRNCH_FLAG WVI, WNRI) | After Submit `ALL_BRNCH_FLAG WHEN-VALIDATE-ITEM` |
| `IMPR_RULE_PORTS_INSERT_ALLOWED` | IMPR_RULE_PORTS POST-QUERY / PRE-RECORD / WNRI | inside `IMPR_RULE_PORTS_PRE_INSERT` |
| `PORT_CD_VALIDATION` / `PORT_CD_WHEN_VALIDATE_ITEM` | PORT_CD WVI | IG validation `IMPR_RULE_PORTS PORT_CD VALIDATION` / DA `IMPR_RULE_PORTS PORT_CD WHEN-VALIDATE-ITEM` |
| `IMPR_RULE_PORTS_PRE_INSERT / _PRE_UPDATE / _PRE_DELETE` | IMPR_RULE_PORTS PRE-* | inside `IMPR_RULE_PORTS_SAVE_ROW` |
| `IMPR_RULE_PORTS_SAVE_ROW` | block DML | `IMPR_RULE_PORTS - Save Interactive Grid Data` |
| `IMPR_RULE_TARIFF_POST_QUERY` | IMPR_RULE_TARIFF.POST-QUERY | grid SQL column `INTL_UNIT` |
| `HRMNZD_CODE_VALIDATION` / `HRMNZD_CODE_VALIDATE_ITEM` | HRMNZD_CODE WVI (+ POST-CHANGE) | IG validation `IMPR_RULE_TARIFF HRMNZD_CODE VALIDATION` / DA `IMPR_RULE_TARIFF HRMNZD_CODE WHEN-VALIDATE-ITEM` |
| `EXEPTION_QTY_VALIDATE_ITEM` | EXEPTION_QTY WVI | DA `IMPR_RULE_TARIFF EXEPTION_QTY WHEN-VALIDATE-ITEM` |
| `IMPR_RULE_TARIFF_PRE_INSERT / _PRE_UPDATE` | IMPR_RULE_TARIFF PRE-* | inside `IMPR_RULE_TARIFF_SAVE_ROW` |
| `IMPR_RULE_TARIFF_SAVE_ROW` | block DML | `IMPR_RULE_TARIFF - Save Interactive Grid Data` |
| `CGFK$QRY_IMPR_RULES_IR_BIT_FK`, `CGFK$CHK_IMPR_RULE_PORTS_IRP_S`, `CGRI$CHK_IMPR_RULES`, `CHECK_FASH_ROLE_ID` | program units | internal (called by the members above) |
| `PKG_VERSION` | version block | — |

## 4. Error texts

No `-20xxx` codes are raised directly: errors go through `FORMS_APX.FORM_TRIGGER_FAILURE` / `FORMS_APX.CHECK_ERROR` (their codes are in `plsql_templates/forms_apx.sql`) or are returned by `<ITEM>_VALIDATION`.

| Text | Source | Member |
|---|---|---|
| هذا النوع غير مستخدم | RULE_TYPE WLC / WVI | `RULE_TYPE_VALIDATION` |
| رقم المستورد المدخل غير صحيح، أدخل الرقم الصحيح أو استخدم القائمة المرفقة | HQ_IMPR_NBR WVI | `HQ_IMPR_NBR_VALIDATION` |
| رقم المستورد المدخل غير صحيح (message, no failure) | IMPR_RULES.POST-QUERY | `POST_QUERY` |
| This Bus Id Type Name does not exist (message) | POST-QUERY CGFK | `POST_QUERY` |
| message 1-270 (text from the message table, MISSING SOURCE) | KEY-DELREC | `KEY_DELREC` |
| Cannot delete استثناءات المستوردين while dependent جمارك الاستثناء exists | CGRI$CHK_IMPR_RULES | `CGRI$CHK_IMPR_RULES` |
| لا يمكن حذف الاستثناء لوجود بنود تعريفة مستثناة (**new**, to agree) | relation CGFK$IRT_IR_FK (Non-Isolated) | `KEY_DELREC` |
| ` لا يوجد صلاحيات كافية للمستخدم<user>لإنشاء هذا النوع من الاستثناءات ` | PRE-INSERT / PRE-UPDATE | `check_rule_type_role` |
| ACTIVITY_DB `V_MSG_TXT` | DML triggers | `add_activity` |
| This رمز الجمرك does not exist | PORT_CD WVI | `PORT_CD_VALIDATION` |
| لا يمكن إضافة جمارك للاستثناء المطبق على جميع الجمارك (**new**, to agree) | block INSERT_ALLOWED | `IMPR_RULE_PORTS_PRE_INSERT` |
| رمز بند التعرفة غير موجود | HRMNZD_CODE WVI | `HRMNZD_CODE_VALIDATION` |
| هذا البند تم ادخاله من قبل لنفس المستورد | HRMNZD_CODE WVI | `HRMNZD_CODE_VALIDATION` |
| لا يسمح بحذف بنود التعريفة المستثناة (**new**, to agree) | Delete Allowed = false | `IMPR_RULE_TARIFF_SAVE_ROW` |

## 5. UI logic for Dynamic Actions (feeds step 03)

| DA | Source | Implementation |
|---|---|---|
| `RULE_TYPE WHEN-LIST-CHANGED` | RULE_TYPE WLC | change → FOS `FORMS_APX.CHECK_ERROR(IMPR1140.RULE_TYPE_VALIDATION(P_RULE_TYPE => :P1140_RULE_TYPE));` |
| `ALL_BRNCH_FLAG WHEN-VALIDATE-ITEM` | ALL_BRNCH_FLAG WVI, IMPR_RULES WNRI (ADJ_BRANCH) | change, fire on initialization; condition `P1140_ALL_BRNCH_FLAG` not equal 1 → Enable `P1140_BUS_ID_BRNCH`; else Clear + Disable |
| `HQ_IMPR_NBR WHEN-VALIDATE-ITEM` | HQ_IMPR_NBR WVI (+ LOV return) | change → FOS `IMPR1140.HQ_IMPR_NBR_VALIDATE_ITEM(...)`, Items to Return BUS_ID, BUS_ID_BRNCH, BUS_ID_TYPE_CD, L_SI_ARBC_IMPR_NAME, BUS_ID_TYPE_NAME |
| `IMPR_RULE_PORTS PORT_CD WHEN-VALIDATE-ITEM` | PORT_CD WVI | column change → FOS, Items to Return PORT_NAME |
| `IMPR_RULE_TARIFF HRMNZD_CODE WHEN-VALIDATE-ITEM` | HRMNZD_CODE WVI + POST-CHANGE | column change → FOS, Items to Return HT_ITEM_ARBC_DESC, INTL_UNIT |
| `IMPR_RULE_TARIFF EXEPTION_QTY WHEN-VALIDATE-ITEM` | EXEPTION_QTY WVI | column change → FOS (Items to Return REMAINED_QTY), then native Alert |
| (no DA) | PORT_CD / HRMNZD_CODE not updatable | IG column read-only for stored rows (`:ROW_ID IS NOT NULL`) |
| (no DA) | tab canvas | Tabs Container |

JavaScript actions needed: **0**.

## 6. Globals / parameters → application items / page items

| Forms | APEX | Note |
|---|---|---|
| `:PARAMETER.P_CURR_PORT_CD` | f345 application item `P_CURR_PORT_CD` | port filter of the ports grid, delete check, SMS, type-12 importers, role check, activity log |
| `:PARAMETER.P_USER_ID` | f345 `SSO_APP_USER` | role check, activity log |
| `:PARAMETER.P_WS_ID` | f345 `P_GLOBAL_V_WS_ID` | activity log (through `ACTIVITY.ADD_ACTIVITY`) |
| `:PARAMETER.P_PORT_TYPE` | f345 `P_PORT_TYPE` | `LOV_SD_PORTS` |
| `:PARAMETER.P_MODULE_ID` | `P1140_MODULE_ID` | f345 standard |
| other `P_*` parameters | not used by business code | — |
| `:GLOBAL.HQ_IMPR_NBR / BUS_ID / ARBC_IMPR_NAME / PORT_CD / PORT_NAME / HRMNZD_CODE / IMPR_TYPE_CD / BUS_ID_TYPE_CD / BUS_ID_TYPE_NAME` | none | LOV-form return channels → Popup LOV + FOS |
| `:GLOBAL.CURRENT_VER / CURRENT_DT / CURRENT_VERSION / EXIT / SYSTEM_OBJ / CG$*` | none | frame / Designer |

No new application item.

## 7. Dropped logic and TODOs

- Dropped with reason: §1 (frame, Designer, keyboard, help, timers, LOV forms), `IMPR_RULE_TARIFF.PRE-DELETE` (cannot fire), the non-blocking "unit not defined" alert (§15 #7).
- **TODO: MISSING SOURCE `LIB_USR.SMS_MESSAGE.SEND_SMS_MESSAGE`** (`send_rule_sms`), message 1-270 text (`STR_DB`, read through `FORMS_APX.ARABIC_MESSAGE`).
- **TODO:** agree the three new texts (§4), SMS timing / resend (inventory §15 #2), `RULE_ISN` sequence (§15 #3).
- **Grants for `LIB_APX_USR`** (definer rights): SELECT on `IMPR_RULES`, `IMPORTERS`, `SINGLE_IMPORTERS`, `IMPORTER_BASIC_DATA`, `BUS_ID_TYPES`, `SD_PORTS`, `HARMONIZED_TARIFF`, `TARIFF_DETAILS`, `INTL_MSR_UNITS`, `SC_USER_ROLES`, `SC_USER_GROUPS`, `SC_GROUP_ROLES`, `SC_USER_EXCLUDED_ROLES`; SELECT, INSERT, UPDATE, DELETE on `IMPR_RULE_PORTS`; SELECT, INSERT, UPDATE on `IMPR_RULE_TARIFF`; EXECUTE on `ACTIVITY_DB`, `LIB_USR.SMS_MESSAGE`, `FORMS_APX`. The master DML (`Process form`) runs as the parsing schema `CUSTOMS`, which needs SELECT, INSERT, UPDATE, DELETE on `IMPR_RULES`.

## 8. Assumptions

1. Pages 1140 / 114001 (registry numbering as IMPR1110 / IMPR1120).
2. `P0_PAGE_PK` = ROWID of the rule (as IMPR1110 / IMPR1120); the master DML is the native Form process on `IMPR_RULES`.
3. The detail grids use ROWID (`ROW_ID`) as the grid key and PL/SQL row DML; the table primary keys are not needed.
4. `IMPORTERS` may return several rows for one `HQ_IMPR_NBR` in a port; Forms takes `ROWNUM = 1`, kept.

## 9. Self-check (2026-11-24)

| Check | Result |
|---|---|
| Forms built-ins / `:SYSTEM.` / `:GLOBAL.` / `NAME_IN` / `COPY(` / `COMMIT` / `ROLLBACK` / `v('P` outside comments | none |
| `pkg_`, `AI_`, `<FORM>_APX` package | none |
| Common helpers defined in the form package (`forms_apx_helpers.leftovers`) / unknown `FORMS_APX` calls | none / none |
| Parameters unqualified inside SQL / private functions inside SQL (`parameter_names.py`) | none / none |
| Identifiers > 30 bytes | none |
| Spec and body members (30) | consistent |
| Owner `LIB_APX_USR`, version block, `PKG_VERSION`, synonym + 4 grants | present |
| Every inventory trigger in §1 | yes (form 34, frame blocks, IMPR_RULES 23, IMPR_RULE_PORTS 12, IMPR_RULE_TARIFF 14, program units 39) |
