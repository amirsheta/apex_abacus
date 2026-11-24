# SUPPORT_ENTRY — Logic extraction (step 02, revision 1)

- **Form:** SUPPORT_ENTRY (`forms/SC/Support_Entry_fmb.xml`), window "بيانات المساندة الفنية"
- **Inventory:** `analysis/SUPPORT_ENTRY/SUPPORT_ENTRY_inventory.md` (revision 2, decisions D1–D3)
- **Package:** `LIB_APX_USR.SUPPORT_ENTRY` version 001 — `plsql/SUPPORT_ENTRY/support_entry_spec.sql` (172 lines),
  `plsql/SUPPORT_ENTRY/support_entry_body.sql` (340 lines)
- **Produced:** 2026-11-24, Claude Code. **Status: NOT COMPILED** (no database in this session).
- **Revised by step 03 (2026-11-24):** page **9001**; package **002** adds `OPEN_DIALOG` (caller side, f345 SCREEN ENTRY RESET);
  the page never submits, so the APEX *Validations* named in §3 / §4 are not created – the same calls run in the
  `<ITEM> WHEN-VALIDATE-ITEM` DAs and inside `AGREE_WHEN_BUTTON_PRESSED`. Details: `SUPPORT_ENTRY_apex_page_spec.md` §0.2, §16.
- **Page number:** (step 02) was still open (inventory §15 Q4). The package does not depend on it: page items are passed as
  `P_<ITEM>`; the APEX calls below write `P<page>_…`.

## 0. Summary

| | Count |
|---|---|
| Forms triggers | 11 → 7 package members, 3 UI-only (DA / page attributes), 1 dropped (PRE-FORM) |
| Public members | 10 (incl. `PKG_VERSION`) |
| Private helpers | 3 (`find_port`, `find_supp_title`, `clear_letter_globals`) |
| Longest member | `INIT_FORM`, 22 lines of code (all members well under 80) |
| New message texts | 2 (unknown codes, marked `SUGGESTION`) + 4 required messages through `FORMS_APX.REQUIRED_VALIDATION` |
| TODOs | page number (Q4); compile and test in the DB; IMPR1110 follow-ups (§8.3) |

## 1. Trigger classification

| # | Trigger | Group | Target |
|---|---|---|---|
| 1 | SUPPORT_ENTRY.WHEN-NEW-FORM-INSTANCE | INITIALISATION (+ UI) | `INIT_FORM` → Process `WHEN-NEW-FORM-INSTANCE` (Before Header); mode test `IS_NEW_LETTER`; labels / GO_ITEM → UI logic |
| 2 | SUPPORT_ENTRY.PRE-FORM | UI-ONLY | dropped: window position (modal dialog is centred) |
| 3 | RP.AGREE.WHEN-BUTTON-PRESSED | BUTTON ACTION | `AGREE_WHEN_BUTTON_PRESSED` → Process `AGREE WHEN-BUTTON-PRESSED`; required checks → Validations `<ITEM> REQUIRED`; EXIT_FORM (mode 0) → Close Dialog |
| 4 | RP.CANCEL.WHEN-BUTTON-PRESSED | BUTTON ACTION | `CANCEL_WHEN_BUTTON_PRESSED` → Process `CANCEL WHEN-BUTTON-PRESSED`; EXIT_FORM → Close Dialog |
| 5 | RP.P_PORT_CD.WHEN-VALIDATE-ITEM | VALIDATION | `P_PORT_CD_VALIDATION` (Validation `P_PORT_CD VALIDATION`) + `P_PORT_CD_WHEN_VALIDATE_ITEM` (DA `P_PORT_CD WHEN-VALIDATE-ITEM`, fills `P_PORT_NAME`) |
| 6 | RP.P_LOV_PORT.WHEN-BUTTON-PRESSED | UI-ONLY | Popup LOV `LOV_SD_PORTS_TYPES` on `P<page>_P_PORT_CD` (decision D2); commented CALL_FORM not converted |
| 7 | RP.SUPP_TITLE_CD.WHEN-VALIDATE-ITEM | VALIDATION | `SUPP_TITLE_CD_VALIDATION` + `SUPP_TITLE_CD_VALIDATE_ITEM` (full name `SUPP_TITLE_CD_WHEN_VALIDATE_ITEM`, 32 bytes) |
| 8 | RP.P_LOV_SUPP_TITLES.WHEN-BUTTON-PRESSED | UI-ONLY | Popup LOV `LOV_SUPP_TITLES` on `P<page>_SUPP_TITLE_CD` |
| 9 | RP.LETTER_DT.KEY-LISTVAL | UI-ONLY (empty) | no LOV on the date; the f345 Hijri picker |
| 10 | RP.LETTER_DT.KEY-F4 | UI-ONLY (empty) | nothing |
| 11 | RP.LETTER_DT.WHEN-VALIDATE-ITEM | VALIDATION (empty) | nothing from the trigger; the item's **format mask** check → `LETTER_DT_VALIDATION` (Validation `LETTER_DT VALIDATION`) |

## 2. Built-in replacements

| Trigger | Built-in | Replacement | Where |
|---|---|---|---|
| WNFI, CANCEL | `:GLOBAL.X := NULL` | `FORMS_APX.SET_GLOBAL('X', NULL)` (private `clear_letter_globals`) | PL/SQL |
| WNFI (edit) | `:X := :GLOBAL.X` | `FORMS_APX.GET_GLOBAL('X')` into the IN OUT parameter | PL/SQL |
| AGREE | `:GLOBAL.X := :ITEM` | `FORMS_APX.SET_GLOBAL('X', P_ITEM)` | PL/SQL |
| WNFI | `:PARAMETER.P_MODE`, `:PARAMETER.P_CURR_PORT_CD` | parameters `P_MODE`, `P_CURR_PORT_CD` (page items `P<page>_P_MODE`, `P<page>_P_CURR_PORT_CD`) | PL/SQL / URL |
| WNFI | `SET_ITEM_PROPERTY(…, LABEL, …)` | two button pairs with conditions on `IS_NEW_LETTER` | page (step 03) |
| WNFI | `GO_ITEM('P_PORT_CD')` | page Cursor Focus = first item | page |
| WNFI | `VALIDATE(ITEM_SCOPE / FORM_SCOPE)` | `INIT_FORM` calls the `…_WHEN_VALIDATE_ITEM` members | PL/SQL |
| PRE-FORM | `SET_WINDOW_PROPERTY(POSITION)` | dropped | – |
| AGREE | `GO_ITEM` + `RAISE FORM_TRIGGER_FAILURE` | Validations `<ITEM> REQUIRED` (message at the item); in the package `FORMS_APX.CHECK_ERROR(FORMS_APX.REQUIRED_VALIDATION(…))` | Validation / PL/SQL |
| AGREE, CANCEL | `EXIT_FORM(NO_VALIDATE)` | Process *Close Dialog* (CANCEL: button without validations) | page |
| WVIs | `RAISE FORM_TRIGGER_FAILURE` (NO_DATA_FOUND) | `<ITEM>_VALIDATION` returns an error text | PL/SQL |
| LOV buttons | `GO_ITEM` + `DO_KEY('LIST_VALUES')` | Popup LOV item | page |

Not used in this form: GO_BLOCK, GO_RECORD, SET_BLOCK_PROPERTY, GET_ITEM_PROPERTY, SHOW_ALERT, MESSAGE, EXECUTE_QUERY,
ENTER_QUERY, COMMIT_FORM, CLEAR_*, CALL_FORM / OPEN_FORM / NEW_FORM (only commented out), NAME_IN, COPY, record groups at
runtime, HOST, TEXT_IO, RUN_REPORT_OBJECT, `:SYSTEM.*`.

## 3. Package members and the APEX component that calls them

| Member | Source | APEX component (step 03) | Call |
|---|---|---|---|
| `IS_NEW_LETTER (P_MODE) RETURN BOOLEAN` | `:PARAMETER.P_MODE = 0` in WNFI / AGREE / CANCEL | server-side conditions: buttons AGREE / CANCEL (mode 0) vs AGREE_EDIT / CANCEL_EDIT, Close Dialog after AGREE | `SUPPORT_ENTRY.IS_NEW_LETTER(P_MODE => :P<page>_P_MODE)` |
| `INIT_FORM` | WNFI | Process `WHEN-NEW-FORM-INSTANCE` (Before Header) | `SUPPORT_ENTRY.INIT_FORM(P_MODE => :P<page>_P_MODE, P_CURR_PORT_CD => :P<page>_P_CURR_PORT_CD, P_PORT_CD => :P<page>_P_PORT_CD, P_PORT_NAME => :P<page>_P_PORT_NAME, P_SUPP_TITLE_CD => :P<page>_SUPP_TITLE_CD, P_SUPP_TITLE_NM => :P<page>_SUPP_TITLE_NM, P_LETTER_NBR => :P<page>_LETTER_NBR, P_LETTER_DT => :P<page>_LETTER_DT);` |
| `P_PORT_CD_VALIDATION (P_PORT_CD) RETURN VARCHAR2` | P_PORT_CD WVI | Validation `P_PORT_CD VALIDATION`; DA `P_PORT_CD WHEN-VALIDATE-ITEM` line 1 | `return SUPPORT_ENTRY.P_PORT_CD_VALIDATION(P_PORT_CD => :P<page>_P_PORT_CD);` |
| `P_PORT_CD_WHEN_VALIDATE_ITEM (P_PORT_CD, P_PORT_NAME IN OUT)` | P_PORT_CD WVI (INTO) | DA `P_PORT_CD WHEN-VALIDATE-ITEM` line 2 (Items to Return `P<page>_P_PORT_NAME`) | |
| `SUPP_TITLE_CD_VALIDATION (P_SUPP_TITLE_CD) RETURN VARCHAR2` | SUPP_TITLE_CD WVI | Validation `SUPP_TITLE_CD VALIDATION`; DA line 1 | |
| `SUPP_TITLE_CD_VALIDATE_ITEM (P_SUPP_TITLE_CD, P_SUPP_TITLE_NM IN OUT)` | SUPP_TITLE_CD WVI (INTO) | DA `SUPP_TITLE_CD WHEN-VALIDATE-ITEM` line 2 | |
| `LETTER_DT_VALIDATION (P_LETTER_DT) RETURN VARCHAR2` | LETTER_DT format mask | Validation `LETTER_DT VALIDATION` | `return SUPPORT_ENTRY.LETTER_DT_VALIDATION(P_LETTER_DT => :P<page>_LETTER_DT);` |
| – (FORMS_APX directly) | AGREE required checks | Validations `P_PORT_CD REQUIRED`, `SUPP_TITLE_CD REQUIRED`, `LETTER_NBR REQUIRED`, `LETTER_DT REQUIRED` (When Button Pressed AGREE / AGREE_EDIT) | `return FORMS_APX.REQUIRED_VALIDATION(ITEM_VALUE => :P<page>_P_PORT_CD, ITEM_LABEL => 'جمرك الخطاب');` (labels in §5) |
| `AGREE_WHEN_BUTTON_PRESSED (P_PORT_CD, P_SUPP_TITLE_CD, P_LETTER_NBR, P_LETTER_DT)` | AGREE WBP | Process `AGREE WHEN-BUTTON-PRESSED`, then Close Dialog | |
| `CANCEL_WHEN_BUTTON_PRESSED (P_MODE)` | CANCEL WBP | Process `CANCEL WHEN-BUTTON-PRESSED`, then Close Dialog | |
| `PKG_VERSION` | – | – | `SELECT SUPPORT_ENTRY.PKG_VERSION FROM dual` |

No `P0_PAGE_PK_CHECK`: control block without a table, the dialog has no record key (template helper not applicable).
Shared LOVs (APEX, step 04, not in the package):

| LOV | Query | Return / display |
|---|---|---|
| `LOV_SD_PORTS_TYPES` (new, D2) | `SELECT sd_ports.port_cd, sd_ports.port_name, cg_ref_codes.rv_meaning FROM cg_ref_codes, sd_ports WHERE cg_ref_codes.rv_low_value = sd_ports.port_type AND cg_ref_codes.rv_domain = 'PORT_TYPE_CD' ORDER BY port_cd` | return / display `PORT_CD`; columns رمز الجمرك, نوع الجمرك, اسم الجمرك |
| `LOV_SUPP_TITLES` (new) | `SELECT supp_title_cd, supp_title_nm FROM supp_titles WHERE title_status = 1` | return / display `SUPP_TITLE_CD`; columns رمز معتمد الخطاب, معتمد الخطاب |

## 4. Read-only and required rules

| Rule | Source | APEX |
|---|---|---|
| `P_PORT_NAME`, `SUPP_TITLE_NM` not enterable | item property Enabled = false | Display Only items (static, no function needed) |
| four letter items required on AGREE | AGREE WBP | Validations `<ITEM> REQUIRED` (When Button Pressed); items stay *Optional - Above* in the layout because Forms did not mark them required, only AGREE checks them — step 03 may show them as *Required - Above* (visual only) |

No `SET_ITEM_PROPERTY(ENABLED / REQUIRED)` and no `Make_Field_Entrable` in the form → no `_IS_READ_ONLY` / `_IS_REQUIRED` functions.

## 5. Messages and errors

| Code | Raised by | Text | Source |
|---|---|---|---|
| -20001 | `FORMS_APX.CHECK_ERROR` | `يجب إدخال جمرك الخطاب` / `يجب إدخال جهة الخطاب` / `يجب إدخال رقم الخطاب` / `يجب إدخال تاريخ الخطاب` (`FORMS_APX.REQUIRED_VALIDATION`) | AGREE (silent FTF in Forms) |
| -20001 | `FORMS_APX.CHECK_ERROR` / validation text | `رمز الجمرك غير موجود` — **new text, SUGGESTION, approve** | P_PORT_CD WVI (silent FTF) |
| -20001 | idem | `رمز جهة الخطاب غير موجود` — **new text, SUGGESTION, approve** | SUPP_TITLE_CD WVI (silent FTF) |
| -20001 | idem | `FORMS_APX.DATE_FORMAT_MESSAGE` / `HIJDATE_DB.VALID_HIJ_DATE` message | LETTER_DT format mask (FRM-40209-like in Forms) |

No alerts are used (inventory §11) → no Text Messages to create.

## 6. UI logic for dynamic actions (input for step 03)

| # | Source | APEX |
|---|---|---|
| 1 | WNFI labels موافق/تراجع vs تعديل/إغلاق | button pairs AGREE + CANCEL (condition `IS_NEW_LETTER`) and AGREE_EDIT + CANCEL_EDIT (`NOT IS_NEW_LETTER`) |
| 2 | WNFI `GO_ITEM('P_PORT_CD')` | Cursor Focus = first item |
| 3 | P_LOV_PORT / P_LOV_SUPP_TITLES | Popup LOV items (the LOV buttons are not created) |
| 4 | P_PORT_CD / SUPP_TITLE_CD WVI | DA `<ITEM> WHEN-VALIDATE-ITEM` (change, FOS Execute PL/SQL: CHECK_ERROR(validation) + `…_WHEN_VALIDATE_ITEM`, Items to Return = the name item) |
| 5 | LETTER_DT | f345 Hijri date picker as in IMPR1110 (`HIJRI_DATE_FORMAT` text); KEY-LISTVAL / KEY-F4 empty → no LOV |
| 6 | AGREE EXIT_FORM (mode 0) | Close Dialog after the AGREE process when `IS_NEW_LETTER`; for "تعديل" (mode 1, Forms stayed open) step 03 decides — with D1 (dialog opened on demand) closing is the natural choice |
| 7 | CANCEL EXIT_FORM | Close Dialog, button with *Execute Validations = No* |
| 8 | dialog X | no process; mode 0 globals already cleared by INIT_FORM → same as CANCEL for the caller |

## 7. Parameters and globals → APEX items

| Forms | APEX | Notes |
|---|---|---|
| `:PARAMETER.P_MODE` (Number, default 1) | page item `P<page>_P_MODE` (Hidden, default 1, set in the URL) | D1: caller passes 0 (new) or 1 (edit on demand) |
| `:PARAMETER.P_CURR_PORT_CD` | page item `P<page>_P_CURR_PORT_CD` (Hidden, URL) | not the f345 application item `P_CURR_PORT_CD` (the user's port); IMPR1110 passes the importer's `PORT_CD` |
| `:PARAMETER.WINDOW_X_POS` / `WINDOW_Y_POS` | – | dropped |
| `:GLOBAL.PORT_CD` | `G_PORT_CD` (exists, IMPR1110 export) | |
| `:GLOBAL.SUPP_TITLE_CD` | `G_SUPP_TITLE_CD` (exists) | |
| `:GLOBAL.LETTER_NBR` | `G_LETTER_NBR` (exists) | callers test it after Dialog Closed |
| `:GLOBAL.LETTER_DT` | `G_LETTER_DT` (exists) | text in `FORMS_APX.HIJRI_DATE_FORMAT`; callers pass `FORMS_APX.HIJRI_TEXT_TO_DATE(G_LETTER_DT)` to `DB_JOURNAL.JOURNALING_ON` (DATE) |
| `:GLOBAL.PORT_NAME`, `:GLOBAL.SUPP_TITLE_NAME` | – (not created) | no reader (Q5, proposal applied; reversible: two `SET_GLOBAL` lines) |
| items `RP.P_PORT_CD`, `P_PORT_NAME`, `SUPP_TITLE_CD`, `SUPP_TITLE_NM`, `LETTER_NBR`, `LETTER_DT` | `P<page>_P_PORT_CD`, `P<page>_P_PORT_NAME`, `P<page>_SUPP_TITLE_CD`, `P<page>_SUPP_TITLE_NM`, `P<page>_LETTER_NBR`, `P<page>_LETTER_DT` | Forms item names kept (§4a) |

Since the globals are application items, the items to set them need no page-item submit: `FORMS_APX.SET_GLOBAL` uses
`apex_util.set_session_state`.

## 8. Dropped logic, TODOs, assumptions

### 8.1 Dropped

| What | Why |
|---|---|
| PRE-FORM window position, `WINDOW_X_POS` / `WINDOW_Y_POS` | modal dialog |
| commented-out CALL_FORM of `REP_LOV_SD_PORTS.FMX` / `LOV_SUPP_TITLES.FMX` | inactive code; Popup LOVs instead |
| `:GLOBAL.PORT_NAME`, `:GLOBAL.SUPP_TITLE_NAME` | no reader (Q5) |
| Edit mode "stays open after تعديل" and the toolbar `CLOSE_FORM('SUPPORT_ENTRY')` of the callers | D1: the dialog is opened on demand, there is no second open window to close |

### 8.2 Behaviour kept on purpose (with SUGGESTION comments)

- A cleared code keeps the old name on screen (Forms `RETURN` before the INTO).
- A typed inactive supplier title is accepted (the WVI has no `TITLE_STATUS = 1`; only the LOV filters).
- Silent failures got messages (needed in APEX): 2 new texts to approve (§5).
- Codes are compared through `TO_NUMBER`; a non-numeric text is "not found" (Forms: implicit conversion error).

### 8.3 Follow-ups outside this form (for the IMPR1110 / IMPR1130 sessions, not changed here)

1. IMPR1110 `IMPORTERS_PRE_UPDATE` (`plsql/IMPR1110/impr1110_body.sql` line 2160): pass
   `FORMS_APX.HIJRI_TEXT_TO_DATE(FORMS_APX.GET_GLOBAL('LETTER_DT'))`, not the text (implicit TO_DATE with the session format).
2. IMPR1110: switch `DB_JOURNAL` off on the error path as well (inventory §14 R10).
3. IMPR1110 TODOs once the page number is known: `P1110_SUPPORT_URL`
   (`APEX_PAGE.GET_URL(p_page => <page>, p_items => 'P<page>_P_MODE,P<page>_P_CURR_PORT_CD', p_values => '0,' || :P1110_PORT_CD)`),
   registry row `CALLED_FORM SUPPORT_ENTRY`, spec §12 branch row.
4. `GRANT EXECUTE ON JOURNAL.DB_JOURNAL TO LIB_APX_USR` for the callers' packages.

### 8.4 Assumptions and missing sources

- `SD_PORTS.PORT_CD` and `SUPP_TITLES.SUPP_TITLE_CD` are NUMBER, names VARCHAR2 (record-group types; DDL is MISSING SOURCE, Q6).
  The package uses `%TYPE` for the names, so only the codes' type matters.
- Tables unqualified (`sd_ports`, `supp_titles`), as in IMPR1110 (public synonyms assumed).
- Page number: TODO (Q4).

### 8.5 Grants needed by `LIB_APX_USR` (definer rights, direct grants)

| Object | Privilege | Used by |
|---|---|---|
| `SD_PORTS` | SELECT | `find_port`, `%TYPE` |
| `SUPP_TITLES` | SELECT | `find_supp_title`, `%TYPE` |
| `FORMS_APX` (same owner) | – | all members |
| `HIJDATE_DB` | EXECUTE | through `FORMS_APX.HIJRI_DATE_ERROR` (already needed by FORMS_APX) |
| `CG_REF_CODES` | SELECT **for the parsing schema CUSTOMS** | shared LOV `LOV_SD_PORTS_TYPES` (APEX, not the package) |

## 9. How the package was built and checked

- Built by hand from `plsql_templates/pkg_template_*.sql`, layout as IMPR1120 009 (version block, sections, Original Forms code
  above each member).
- Constants placed before the first subprogram body (PL/SQL requires declarations before bodies).
- Checks run on the generated files (all clean):

| Check | Result |
|---|---|
| Forms built-ins / `:GLOBAL.` / `:SYSTEM.` / `NAME_IN` / `COPY(` / `EXIT_FORM` / `DO_KEY` outside comments | none |
| bare `FORM_TRIGGER_FAILURE`, `COMMIT` / `ROLLBACK`, `v('P…')`, `get_session_state`, `AI_`, `I_` / `IO_` / `O_` | none |
| identifiers > 30 bytes | none |
| `scripts/parameter_names.py`: `unqualified_in_sql`, `private_functions_in_sql` | empty |
| `scripts/forms_apx_helpers.py`: `leftovers`, `unknown_calls` | empty |
| spec and body: same members in the same order | yes |
| owner `LIB_APX_USR`, version block, `PKG_VERSION`, synonym + 4 grants | present |
| compile on 12.1.0.2 | **not done** (no database) |
