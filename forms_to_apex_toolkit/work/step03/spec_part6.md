
### 10.3 JavaScript actions (9, each 1–3 lines)

| # | DA | Lines | Why native actions are not enough |
|---|---|---|---|
| 1 | `BUS_ID WHEN-VALIDATE-ITEM` | 2 | WARNING alert "يوجد مستورد … موقوف له نفس الرقم الإستدلالي" with the importer number computed on the server; the answer must be known before the WHEN-VALIDATE-ITEM code runs. Native *Confirm* has a fixed text |
| 2–5 | `IMPR1110F1` / `F2` / `F3` / `F5 EXECUTE-FUNCTION` | 1 each | open the SUPPORT_ENTRY dialog (`apex.navigation.redirect` of a modal-page URL); there is no native "open dialog" action in 21.2 |
| 6 | `IMPR_MCI_SERVICE EXECUTE-FUNCTION` | 2 | question text computed by `UPDATE_IMPORTER_MSG` |
| 7 | `IMPR1110_MOB EXECUTE-FUNCTION` | 1 | open dialog page 111002 after the server check |
| 8 | `EXEC_FUNS` | 2 | CONFIRM of IMPR1110F1 / F5 "سيتم تعديل الإسم إلى …" with the new name computed on the server, then the WHEN-NEW-RECORD-INSTANCE DA |
| 9 | `PRE-INSERT CONFIRM` | 2 | the f345 known case: page 0 CREATE submits directly, so the broker question must cancel and resubmit (`apex.event.gCancelFlag`) |

No JavaScript file, no AJAX callback process, no client UI-state engine. Revision 1 had `impr1110.js`
(about 300 lines) and 3 AJAX callbacks.

### 10.4 Order of events after a function (example IMPR1110F4)

1. FUNCS list → custom event `IMPR1110F4` → DA `IMPR1110F4 EXECUTE-FUNCTION`: `P1110_FUNCTION_CODE` := NULL
   (no event), then := `IMPR1110F4` → change event.
2. DA `EXEC_FUNS`: FOS `EXEC_FUNS` (returns `P1110_P_CODE` = IMPR1110F4) → FOS `NEW_RECORD_CONFIRM_TEXT`
   (NULL for F4) → JS: no question → `P1110_ANSWER` := 1 → event `impr1110-new-record-instance`.
3. DA `WHEN-NEW-RECORD-INSTANCE`: FOS `WHEN_NEW_RECORD_INSTANCE` → FOS `READ_ONLY_FLAGS` (BUS_ID_EXPRD_DT
   now unlocked) → change of `P1110_BUS_ID_EXPRD_DT_LOCKED` → DA `BUS_ID_EXPRD_DT READ ONLY` enables the item.
4. SAVE → PRE-UPDATE / Process form / POST-UPDATE → `P_CODE RESET` → the page renders with the item locked again.

## 11. Alerts and messages

| Forms alert / message | Usage | APEX equivalent | Text |
|---|---|---|---|
| `USR_CONFIRM_B`, `USR_CONFIRM`, `USR_WARNING_C`, `USR_WARNING_B`, `CFG_WARNING_A`, `CFG_INFORMATION`, `CFG_ERROR`, `CFG_SYSTEM_ERROR`, `CFG_ASK_COMMIT` (CIC_OLB, resolved in step 01) | only through `STR.DispAlert` / `STR.DispArbMsg` | no Text Message: the texts are in the package (verbatim from the form) | – |
| `STR.DispAlert(text, 'ERROR')` + FORM_TRIGGER_FAILURE | stop | `FORMS_APX.FORM_TRIGGER_FAILURE` → validation error text / FOS error / process error | verbatim |
| `STR.DispAlert(text, 'INFORMATION')` without failure | note | `FORMS_APX.MESSAGE` → success message of the process / FOS | verbatim |
| CONFIRM of PRE-INSERT (brokers) | caution | Text Message **`IMPR1110_PRE_INSERT_CONFIRM`** → computation `P1110_PRE_INSERT_QUESTION` (`APEX_LANG.MESSAGE`) → DA `PRE-INSERT CONFIRM` | يجب مراجعة البيانات والتأكد من صحتها قبل التخزين، لايمكن التعديل إلا من قبل شئون المستوردين! هل ترغب بالاستمرار؟ |
| WARNING suspended importer (BUS_ID), CONFIRM new name (F1 / F5), CONFIRM MCI update | caution, text computed | `*_CONFIRM_TEXT` functions + `apex.message.confirm` (§10.3) | from the package |
| page 0 DELETE question | caution | page 0 `DELETE` confirm (f345) | f345 text (Forms: "هل أنت متأكد من عملية الحذف") |
| FRM-40202 / 40350 | Forms runtime | Value Required / `FORMS_APX.REQUIRED_VALIDATION` ("يجب إدخال <label>", common helper since FORMS_APX 004; was CG_MESSAGE "<p1> must be entered"); no-row-found is not possible (key from the search page) | **TODO** Arabic texts of `NIB.ON_ERROR` (MISSING SOURCE) |

Error handling function: the f345 `APP_ERROR_HANDLER` (application attribute, not changed).

## 12. Branches and navigation

| Branch / link | Point | Target | Condition | Items set | Source |
|---|---|---|---|---|---|
| After processing | After Processing | 1110 | always (EXECUTE_QUERY: clear cache 1110) | – | Forms stays in the form after COMMIT |
| page 0 SEARCH | – | 111001 (dialog) | `P0_PAGE_PK` is null | – | ENTER_QUERY / EXECUTE_QUERY |
| link column of 111001 | – | 1110 | – | `P0_PAGE_PK` = ROWID (checksum) | EXECUTE_QUERY result |
| function `IMPR1110_MOB` | – | 111002 (dialog) | `IMPR_NBR > 3000000` (checked by `EXEC_FUNS`) | `P111002_IMPR_NBR` (checksum, `P1110_MOBILE_URL`) | `CALL_FORM('LOV_UPDATE_IMPR_MOBILE.fmx')` |
| functions IMPR1110F1 / F2 / F3 / F5 | – | SUPPORT_ENTRY page (dialog) | – | P_MODE = 0, P_CURR_PORT_CD = PORT_CD | `CALL_FORM('SUPPORT_ENTRY.FMX')` – **TODO** |
| function `IMPR1115_SCR` | – | page IMPR1115 when converted (the f345 list links to a page named after the file) | – | `P_IMPR_NO` = IMPR_NBR | TMPLT CALL_FORM – **TODO** |
| other forms that open IMPR1110 | – | 1110 | – | application items `P_PRSNL_IMPR`, `P_LETTER_NBR` (read once by `PARAMETERS ENTRY`) | CALL_FORM with PRSNL_IMPR / LETTER_NBR |
| page 0 BACK | – | home application | – | – | EXIT_FORM |

## 13. Shared components

### 13.1 Reused from f345 (do not create)

Theme 42 / ZATCA Forms templates (§1–§3), page 0 (`P0_ACTIONS`, `ASK_DLG`, `P0_PAGE_PK`, `P0_SEARCH_URL`),
list *Page Functions*, plug-in `COM.FOS.EXECUTE_PLSQL_CODE`, application process `SCREEN ENTRY RESET`,
`APP_ERROR_HANDLER`, the Hijri picker (`Hijri_init.js`, class `hijri-date-default`), and the application items
`SSO_APP_USER`, `P_CURR_PORT_CD`, `P_GLOBAL_V_WS_ID`, `P_CLASS_CD`, `V_USR_TYPE`, `P_BRKR_NBR`, `P_PORT_TYPE`,
`SYS_ANAME`, `G_LAST_PAGE`.

### 13.2 New application items (Session State Protection: Restricted)

| Item | Source | Notes |
|---|---|---|
| `P_BRKR_PORT_CD`, `P_LIC_TYPE` | `:PARAMETER.P_BRKR_PORT_CD` / `P_LIC_TYPE` of the menu | not filled by the f345 login yet: **TODO**, the f345 After Authentication process must set them (CIC_MENU source missing) |
| `P_PRSNL_IMPR`, `P_LETTER_NBR` | parameters callers pass to IMPR1110 | read once by `PARAMETERS ENTRY` |
| 28 globals `G_<NAME>` | `:GLOBAL.<NAME>` through `FORMS_APX.GET_GLOBAL` / `SET_GLOBAL` | `G_ALLOW_MCI`, `G_ALLOW_MOI`, `G_BRKR_ATHRZTN_NBR_B`, `G_CHEK`, `G_CHK_DUP_BUSID`, `G_CHK_IMP_TYP`, `G_EXEC_QUERY_NOW`, `G_EXE_DETAIL_QUERY`, `G_FLAGUPDATE`, `G_FUNS_BUSID`, `G_FUNS_IMP`, `G_IMP0F4`, `G_IMPR_NAME_B`, `G_IMPR_NBR`, `G_IMPR_NBR_B`, `G_INS`, `G_LETTER_DT`, `G_LETTER_NBR`, `G_MINS_COMM_CD`, `G_MOBILE_NO`, `G_OLD_IMPR_TYPE_CD`, `G_OLD_PORT_CD`, `G_PORT_CD`, `G_SET`, `G_STAT_CLR`, `G_STAT_QUE`, `G_SUPP_TITLE_CD`, `G_VALID`. Several are written but never read by IMPR1110 (kept until the other IMPR forms are analysed) |

### 13.3 Other new components

- 13 shared LOVs (§6).
- Text Message `IMPR1110_PRE_INSERT_CONFIRM` (§11).
- Navigation menu entry for page 1110 (§2).
- **Not created:** Authorization Schemes (CLAUDE.md §8: page access from the application privileges;
  function rights from the *Page Functions* list, SC_SYSOBJ_ROLE_PRIVS), JavaScript files, AJAX callbacks,
  collections.

---

## 14. Traceability matrix (every object of the XML)

The rows of revision 1, re-mapped to the components and package members of this revision (generated). 5
blocks, 158 items, 323 triggers, 53 program units, 8 LOVs, 9 record groups (+ runtime CGDV$DLRG), 9 alerts, 5
canvases, 1 window, 24 parameters, 45 globals, 17 libraries and the called forms.
`DROPPED` = no APEX component (reason in *Notes*). `TODO` = depends on a missing source or a form not yet
converted. *IMPR1110 (private X)* = converted Forms code inside the package, reached through the entry
points of §7–§10.

