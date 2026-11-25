# IMPR1210 – Logic Extraction (step 02)

- **Form:** IMPR1210 (module `IMPR1210`): "صيانة تفاويض الشركات الوسيطة" – authorizations of an importer to a broker company in the user's port (`AGNTS`)
- **Package:** `IMPR1210` version 001 – `plsql/IMPR1210/impr1210_spec.sql`, `plsql/IMPR1210/impr1210_body.sql` (NOT COMPILED)
- **Shared packages changed:** none (`LOV_APX` and `FORMS_APX` unchanged; LOVs `LOV_IMPR` and `LOV_ALLOWED_EXPORT` of the IMPR1110 export are reused)
- **Inventory:** `analysis/IMPR1210/IMPR1210_inventory.md` (Forms code quoted in sections 6 and 9)
- **Produced:** 2026-11-25 by Claude Code
- **Rollback:** new package, there is no previous version (rollback = `DROP PACKAGE LIB_APX_USR.IMPR1210; DROP PUBLIC SYNONYM IMPR1210;`).

## 1. Decisions

| # | Decision | Reason |
|---|---|---|
| 1 | Page key `P0_PAGE_PK` = ROWID of `AGNTS` (URL-safe on the search page); `P0_PAGE_PK_CHECK` also applies the block WHERE clause `PORT_CD = P_CURR_PORT_CD` | as IMPR1160 / IMPR1140; the Designer key is (PORT_CD, ATHRZTN_SEQ_NBR) |
| 2 | Insert and update through the native Form DML; delete refused (`PRE_DELETE`) | WHEN-NEW-RECORD-INSTANCE makes every queried record non-deletable; KEY-DELREC is the NIB frame |
| 3 | The update rule of WHEN-NEW-RECORD-INSTANCE (`MAKE_BLOCK_FULL_OPERATION`) is the BOOLEAN `AGNTS_IS_READ_ONLY` (item Read Only conditions) and is checked again in `PRE_UPDATE` | CLAUDE.md §4c rule 1; a request can be sent from the browser by hand |
| 4 | The two functions write in `EXEC_FUNS` with the Forms COMMIT (one UPDATE + activity + COMMIT); the confirmations are DA Confirm actions | PU EXEC_FUNS commits; IMPR1150 decision 4 |
| 5 | Typing an existing ATHRZTN_SEQ_NBR = check (9-40) + Submit `EXECUTE_QUERY`; `PRE_QUERY` returns the ROWID for `P0_PAGE_PK` | ATHRZTN_SEQ_NBR.WHEN-VALIDATE-ITEM + PRE-QUERY + IMPR_NBR.WHEN-NEW-ITEM-INSTANCE (IMPR1150 / IMPR1170 pattern) |
| 6 | The LOV form `LOV_AGNT_ATHR_IMPR` of IMPR_NBR.WHEN-VALIDATE-ITEM becomes a read-only grid of the importer's authorizations (rows open the authorization) | Forms only copies the values back (the EXEC_QUERY global is never read); to confirm (inventory §15 #4) |
| 7 | The status radio stays enterable under the same rule as the other items | behaviour first (inventory §14 #3, §15 #3); `-- SUGGESTION:` display only |
| 8 | `IMPR.IMPR_SUSPENDED`, `DCLTN.IMPR_IMPR_AUTH_USED`, `STR_DB.GETARBMSG` are called unchanged | MISSING SOURCE (DB packages); same calls as Forms / IMPR1110 |
| 9 | Common helpers from `FORMS_APX` 004 (`ARABIC_MESSAGE`, `CHECK_ERROR`, `CUR_HIJ_DATE`, `HIJRI_TEXT`, `FORM_TRIGGER_FAILURE`, `ROWID_FROM_URL`); no local copy | CLAUDE.md §4a rule 3 |
| 10 | Hijri dates ATHRZTN_CRET_DT / ATHRZTN_CNCLD_DT are display only with the mask `FORMS_APX.HIJRI_DATE_FORMAT`; their WHEN-VALIDATE-ITEM (HIJDATE.VALID_HIJ_DATE) is dropped | the items are never enterable (Insert / Update Allowed = false) |

## 2. Classification of the Forms code

| Forms object | Group | Target |
|---|---|---|
| AGNTS.PRE-QUERY + IMPR_NBR.WHEN-NEW-ITEM-INSTANCE | QUERY | `PRE_QUERY` (process EXECUTE-QUERY) |
| AGNTS.POST-QUERY + CGFK$QRY_AGNTS_AG_SDP_FK / _IMP_FK / _IMP_AGENT_ID | QUERY | `POST_QUERY` (messages without RAISE dropped: the FKs guarantee the rows; `-- SUGGESTION:`) |
| AGNTS.WHEN-CREATE-RECORD | INITIALISATION | `WHEN_CREATE_RECORD` (Before Header, new record) |
| AGNTS.WHEN-NEW-RECORD-INSTANCE | INITIALISATION / UI | `WHEN_NEW_RECORD_INSTANCE` (UPDATE_STATUS text) + `AGNTS_IS_READ_ONLY` (item rule) |
| AGNTS.ATHRZTN_SEQ_NBR.WHEN-VALIDATE-ITEM | VALIDATION + NAVIGATION | `ATHRZTN_SEQ_NBR_VALIDATION` + DA Submit EXECUTE_QUERY |
| AGNTS.IMPR_NBR.WHEN-VALIDATE-ITEM (+ PU CHECK_SUSPENSION, CGFK$CHK_AGNTS_AG_IMP_FK) | VALIDATION (split) | `IMPR_NBR_VALIDATION` (9-20, 9-70, 9-10) + `IMPR_NBR_WHEN_VALIDATE_ITEM` (name, activity); CALL_FORM LOV_AGNT_ATHR_IMPR → region refresh (decision 6) |
| AGNTS.IMPR_NBR_AG.WHEN-VALIDATE-ITEM (+ CHECK_SUSPENSION, CGFK$CHK_AGNTS_AG_IMP_AGENT_ID) | VALIDATION (split) | `IMPR_NBR_AG_VALIDATION` + `IMPR_NBR_AG_WHEN_VALIDATE_ITEM` |
| AGNTS.IMPR_NBR_AG.WHEN-NEW-ITEM-INSTANCE | NAVIGATION | dropped: reads `:GLOBAL.EXEC_QUERY`, only set after the LOV form (decision 6) |
| AGNTS.PRE-INSERT | PRE DML | `PRE_INSERT` (MAX+1, status 1, Hijri date, activity 1) |
| AGNTS.PRE-UPDATE | PRE DML | `PRE_UPDATE` (update rule + activity 2) |
| FORM.KEY-DELREC (NIB) | PRE DML | `PRE_DELETE` (refused) |
| PU EXEC_FUNS (CD1_STOPIMPRAUTH, CD2_REUSEIMPRAUTH) | BUTTON ACTIONS (split) | `EXEC_FUNS` (server) + DA Confirm on the FUNCS custom events (UI) |
| PU EXECUTE_FUNCTION, MOUSE_CLICK, LSIDE, KEY-F9 | frame | page 0 FUNCS drawer (f345 Page Functions) |
| PU ADJ_FUNS | – | dropped (`NULL;`) |
| PU CGDV$POPULATE_DYNAMIC_LISTS | lists | LOV `LOV_ALLOWED_EXPORT` (IMPR1110, CG_REF_CODES `ALLOWED EXPORT`) on ALLOW_EXPORT, IMPR_EXPR_TYPE, IMPR_EXPR_TYPE_AG |
| AGNTS.ON-ERROR + PU CGTE$CHECK_CONSTRAINT_VIO | constraint messages | Text Messages `AG_PK`, `AG_SDP_FK`, `AG_IMP_FK`, `AG_IMP_AGENT_ID_FK` (FORMS_APX.apex_error_handler); ORA-01031 texts and the SDP_PK / IMP_PK / IMP_BUSID_UK branches (other tables) dropped |
| KEY-LISTVAL of PORT_CD, IMPR_NBR, IMPR_NBR_AG (CALL_FORM LOV_SD_PORTS / LOV_IMPR) + buttons PORT_CD2, IMP_LOV, AGNT_LOV | LOV | PORT_CD never enterable (LOV dropped); Popup LOV `LOV_IMPR` on IMPR_NBR and IMPR_NBR_AG |
| KEY-LISTVAL ×6 of non-LOV items (Designer "may the LOV be shown" check) | boilerplate | dropped |
| ATHRZTN_CRET_DT / ATHRZTN_CNCLD_DT / TITLE.SYSTEM_DATE WHEN-VALIDATE-ITEM | Hijri check | dropped (decision 10) |
| PU CGNV$AI_CGSO$WINDOW_1_IMP_NEW (button CGSO$WINDOW_1_IMP_NEW) | navigation | page button `IMP_NEW` → page 1130 (to confirm, inventory §15 #5) |
| AGNTS.KEY-HELP, FORM.KEY-HELP | boilerplate | dropped (empty help file) |
| FORM.PRE-FORM (versions, NLS, help globals), WHEN-NEW-FORM-INSTANCE, timers, NIB / TMPLT frame | frame | dropped / f345 page template, page 0 toolbar, FUNCS |

## 3. Built-in replacements

| Trigger | Built-in | Replacement | Where |
|---|---|---|---|
| ATHRZTN_SEQ_NBR.WHEN-VALIDATE-ITEM, PRE-QUERY | `:GLOBAL.Port_CD / ATHRZTN_SEQ_NBR / Exec_Query_Now` | request `EXECUTE_QUERY` + `P0_PAGE_PK` | DA + process |
| IMPR_NBR.WHEN-NEW-ITEM-INSTANCE | `CLEAR_BLOCK`, `EXECUTE_QUERY` | branch to the page with the new `P0_PAGE_PK` | branch EXECUTE-QUERY |
| KEY-LISTVAL (PORT_CD, IMPR_NBR, IMPR_NBR_AG) | `CALL_FORM` LOV forms, parameter lists, `:GLOBAL.IMPR_NBR / IMPR_NAME` | Popup LOV `LOV_IMPR` | item |
| IMPR_NBR.WHEN-VALIDATE-ITEM | `CALL_FORM('LOV_AGNT_ATHR_IMPR')` | read-only IG `LOV_AGNT_ATHR_IMPR` + DA Refresh | region / DA |
| KEY-LISTVAL, buttons | `GO_ITEM`, `DO_KEY('LIST_VALUES')` | Set Focus / Popup LOV button | DA |
| many | `STR.DispArbMsg(s, n) + RAISE FORM_TRIGGER_FAILURE` | `FORMS_APX.ARABIC_MESSAGE(s, n)` (validation text) | package |
| WHEN-NEW-RECORD-INSTANCE, EXEC_FUNS | `INTRFACE.MAKE_BLOCK_FULL_OPERATION` | `AGNTS_IS_READ_ONLY` + `PRE_UPDATE` / `PRE_DELETE` | item conditions / package |
| EXEC_FUNS | `STR.DispArbMsg(9, 50, 'CONFIRM')`, `STR.DispALERT(..., 'CONFIRM')` | DA Confirm (text item `P1210_CONFIRM_STOP` = message 9-50; literal) | DA |
| EXEC_FUNS | `COMMIT` | `COMMIT` kept (Forms commit point) | package |
| EXEC_FUNS, PRE-UPDATE | `:PARAMETER.P_FUNCTION_CD` | not needed (functions never pass through SAVE) | – |
| POST-QUERY | `NAME_IN`, `SET_RECORD_PROPERTY(QUERY_STATUS)` | parameters; not needed | package |
| PRE-INSERT, EXEC_FUNS, ACTIVITY | `HIJDATE.Cur_Hij_Date`, `ACTIVITY.ADD_ACTIVITY` (`:PARAMETER.P_CURR_PORT_CD / P_USER_ID / P_WS_ID`) | `FORMS_APX.CUR_HIJ_DATE`, `ACTIVITY_DB.ADD_ACTIVITY` with `P_CURR_PORT_CD`, `SSO_APP_USER`, `P_GLOBAL_V_WS_ID` | package |
| CGNV$AI_CGSO$WINDOW_1_IMP_NEW | `OPEN_FORM('IMP_NEW')` | button redirect to page 1130 | button |

## 4. Package members

| Member | Source | APEX caller |
|---|---|---|
| `P0_PAGE_PK_CHECK` | f345 key check (ROWID, block WHERE clause) | Before Header 20 |
| `PRE_QUERY` | PRE-QUERY + IMPR_NBR.WHEN-NEW-ITEM-INSTANCE | After Submit EXECUTE-QUERY |
| `POST_QUERY` | POST-QUERY (+ CGFK$QRY_*) | Before Header 82 |
| `WHEN_CREATE_RECORD` | WHEN-CREATE-RECORD | Before Header 84 |
| `WHEN_NEW_RECORD_INSTANCE` | WHEN-NEW-RECORD-INSTANCE | Before Header 86 |
| `AGNTS_IS_READ_ONLY` | WHEN-NEW-RECORD-INSTANCE (MAKE_BLOCK_FULL_OPERATION) | item Read Only conditions; `PRE_UPDATE` |
| `ATHRZTN_SEQ_NBR_VALIDATION` | ATHRZTN_SEQ_NBR.WHEN-VALIDATE-ITEM | validation + DA |
| `IMPR_NBR_VALIDATION` / `IMPR_NBR_WHEN_VALIDATE_ITEM` | IMPR_NBR.WHEN-VALIDATE-ITEM (+ CHECK_SUSPENSION, CGFK$CHK) | validation / DA |
| `IMPR_NBR_AG_VALIDATION` / `IMPR_NBR_AG_WHEN_VALIDATE_ITEM` | IMPR_NBR_AG.WHEN-VALIDATE-ITEM | validation / DA |
| `PRE_INSERT` | PRE-INSERT | After Submit 10 (CREATE) |
| `PRE_UPDATE` | PRE-UPDATE | After Submit 20 (SAVE) |
| `PRE_DELETE` | KEY-DELREC / WHEN-NEW-RECORD-INSTANCE | After Submit 30 (DELETE) |
| `EXEC_FUNS` | PU EXEC_FUNS | After Submit CD1_STOPIMPRAUTH / CD2_REUSEIMPRAUTH EXECUTE-FUNCTION |

Private: `add_activity` (ACTIVITY.ADD_ACTIVITY(9, 1, …) → `ACTIVITY_DB`), `importer_suspended` (PU CHECK_SUSPENSION),
`importer_row` (C_P_NAME / CGFK look-ups), `importer_error` (the checks shared by IMPR_NBR and IMPR_NBR_AG),
`stored_status`, `authorization_used` (DCLTN.IMPR_IMPR_AUTH_USED). No member is longer than 80 lines.

## 5. Messages

| Message | Text source | Where |
|---|---|---|
| 9-10 | STR_DB (importer = broker company) | `importer_error` |
| 9-20 | STR_DB (importer / broker company not in the port) | `importer_error` |
| 9-40 | STR_DB (authorization number not found) | `ATHRZTN_SEQ_NBR_VALIDATION` |
| 9-50 | STR_DB (confirm cancel) | DA Confirm through item `P1210_CONFIRM_STOP` |
| 9-70 | STR_DB (suspended) | `importer_error` |
| 8-30 / 8-80 | STR_DB, bare text (UPDATE_STATUS: used / cancelled) | `WHEN_NEW_RECORD_INSTANCE`, `PRE_UPDATE` |
| 'سيتم إسترجاع التفويض - هل ترغب في إستكمال الإسترجاع' | Forms literal | DA Confirm |
| 'لا يمكن حذف بيانات من هذه الشاشة' | = IMPR1150 / IMPR1116 (to agree) | `PRE_DELETE` |
| AG_PK 'هذا السجل مدخل سابقاً - أعد ادخال البيانات', AG_SDP_FK, AG_IMP_FK, AG_IMP_AGENT_ID_FK | CGTE$CHECK_CONSTRAINT_VIO / ON-ERROR | Text Messages |

No `-20xxx` codes of its own: errors go through `FORMS_APX.FORM_TRIGGER_FAILURE` / validation texts.

## 6. Globals and parameters

| Forms | APEX |
|---|---|
| `:PARAMETER.P_CURR_PORT_CD`, `P_USER_ID`, `P_WS_ID` | f345 items `P_CURR_PORT_CD`, `SSO_APP_USER`, `P_GLOBAL_V_WS_ID` |
| `:PARAMETER.P_MODULE_ID` | `P1210_MODULE_ID` (FORMS_APX.GET_MODULE_ID) |
| `:PARAMETER.P_FUNCTION_CD` | not needed (§3) |
| `:GLOBAL.PORT_CD`, `ATHRZTN_SEQ_NBR`, `EXEC_QUERY_NOW`, `IMPR_NBR_AGENT_ID` | request EXECUTE_QUERY + `P0_PAGE_PK` |
| `:GLOBAL.EXEC_QUERY`, `IMPR_NBR`, `IMPR_NAME` (LOV forms) | Popup LOV / grid (decision 6) |
| `:GLOBAL.current_ver / current_DT / current_version`, `CG$HP_*` | dropped (frame) |

## 7. Grants needed by LIB_APX_USR (definer rights)

`SELECT`, `UPDATE` on `AGNTS`; `SELECT` on `IMPORTERS`, `SD_PORTS`; `EXECUTE` on `LIB_USR.ACTIVITY_DB`, `LIB_USR.IMPR`,
`DCLTN` (owner to confirm), `STR_DB`, `HIJDATE_DB`. The parsing schema CUSTOMS needs `SELECT`, `INSERT`, `UPDATE` on `AGNTS`
(Form region) and `SELECT` on `IMPORTERS`, `CG_REF_CODES`, `SD_PORTS` (LOVs, search page, authorizations grid).

## 8. Dropped logic and TODOs

- MISSING SOURCE: `LIB_USR.IMPR.IMPR_SUSPENDED`, `DCLTN.IMPR_IMPR_AUTH_USED`, `STR_DB.GETARBMSG` (called), form `IMP_NEW`.
- Dropped: the POST-QUERY "not found" PUSH messages (FK-guaranteed), SDP_PORT_STATUS, the MSGGETTEXT(78) branches
  (no table row without PORT_CD), the Hijri checks of display items, ORA-01031 texts, help, frame.
- Open: inventory §15 #3 (status radio), #4 (authorization list), #5 (IMP_NEW).
