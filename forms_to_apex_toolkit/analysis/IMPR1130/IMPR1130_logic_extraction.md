# IMPR1130 — Logic extraction (step 02, revision 1)

- **Form:** IMPR1130 (XML module `IMPR1110_PROD_CENTRL`) – "إضافة وتعديل بيانات مستورد"
- **Package:** `LIB_APX_USR.IMPR1130` version **001** – `plsql/IMPR1130/impr1130_spec.sql`, `plsql/IMPR1130/impr1130_body.sql`
  (**NOT COMPILED**: no database in this session, CLAUDE.md §6.10)
- **Inputs:** `forms/IMPR/IMPR1130_fmb.xml`, inventory `analysis/IMPR1130/IMPR1130_inventory.md` (step 01), IMPR1110
  package 013 (members whose Forms code is identical), `plsql_templates/forms_apx.sql` (FORMS_APX 004),
  SUPPORT_ENTRY contract (`analysis/SUPPORT_ENTRY/SUPPORT_ENTRY_apex_page_spec.md` §0.4)
- **Standard:** CLAUDE.md §3.2, §4, §4a–§4c; `docs/f345_reference_standard.md` §5, §9, §10
- **Produced:** 2026-11-24 by Claude Code

## 0. Summary

| Item | Value |
|---|---|
| Code units in the form | 178 (136 triggers, 42 program units) – classification of every unit: `work/IMPR1130/step02/classification.md` |
| Converted into the package | 53 units (+1 unit whose only content is read-only rules) |
| Replaced by APEX components | 30 units (popup LOVs, date pickers, search page, page reload, Page Functions list) |
| Dropped | 94 units: the OLB screen frame (NIB / TMPLT / toolbar / timers / windows), 38 Designer "may the LOV be shown" KEY-LISTVAL checks, MS-Help, unused code |
| Public members | 59 (spec order: f345 helpers 4 → form level 1 → query 1 → record 2 → items 46 → DML 4 → functions 3) |
| Package size | spec 630 lines, body 2,687 lines (of which 420 generated: the 36 delete checks and 32 delete messages) |
| Reuse of IMPR1110 | members of identical units copied from IMPR1110 013 (`P0_PAGE_PK_CHECK`, `IMPORTER_ROW_ID`, `PARAMETERS_ENTRY`, ON-ERROR text, CITY_CODE, e-mail, English name, add_activity, strip_constraint); the changed and new units converted from the IMPR1130 code |
| Checks | `work/IMPR1130/step02/build_body.py`: 0 problems (members of the spec have a body, names ≤ 30 bytes, no Forms built-ins, parameters qualified in SQL, no private function in SQL, no copy of a FORMS_APX helper) |

Design (as IMPR1110, CLAUDE.md §4c): one package named after the form; no record of all items, no session-state
adapter, no UI recorder. Each public member takes only the items it uses; the SQL is in private members or qualified
with the member name. The read-only rules are BOOLEAN functions plus the flag procedure `READ_ONLY_FLAGS`.

## 1. How APEX calls the package (page 1130 main, 113001 search)

| Moment | APEX component | Package member |
|---|---|---|
| Before Header | `PARAMETERS ENTRY`, `P0_PAGE_PK CHECK` | `PARAMETERS_ENTRY`, `P0_PAGE_PK_CHECK` |
| Before Header, new record | `WHEN-CREATE-RECORD`, then `WHEN-NEW-FORM-INSTANCE` | `WHEN_CREATE_RECORD`, `WHEN_NEW_FORM_INSTANCE` (Forms fires WCR of the first record before WNFI) |
| Before Header, saved record | `WHEN-NEW-FORM-INSTANCE` (settings), `POST-QUERY`, `PRE-RECORD` | `WHEN_NEW_FORM_INSTANCE`, `POST_QUERY`, `PRE_RECORD` |
| Before Header, last | `READ ONLY FLAGS`, computation `P1130_ADJ_FUNS` | `READ_ONLY_FLAGS`, `ADJ_FUNS` |
| Page load (first view) | DA `SUPPORT_ENTRY`: FOS `SUPPORT_ENTRY.OPEN_DIALOG(P_MODE => 0, …)` + redirect; Dialog Closed → `P1130_P_LETTER_NBR := G_LETTER_NBR`; edit on demand with `P_MODE => 1` | – (SUPPORT_ENTRY package) |
| Item change | DA `<ITEM> WHEN-VALIDATE-ITEM`: FOS `FORMS_APX.CHECK_ERROR(IMPR1130.<ITEM>_VALIDATION(...))` or the side-effect procedure, then `READ_ONLY_FLAGS` for the state items | `<ITEM>_VALIDATION`, `<ITEM>_WHEN_VALIDATE_ITEM` / `<ITEM>_VALIDATE_ITEM` |
| Confirm in the middle of a trigger | FOS returns `P1130_CONFIRM_TEXT`; native Confirm; answer in `P1130_ANSWER` (1 yes / 2 no); second FOS | `CITY_CODE_OF_ID_CONFIRM_TEXT`, `UPDATE_IMPORTER_CONFIRM_TEXT` |
| IMPR_NBR typed on a new record | DA: CHECK_ERROR(`IMPR_NBR_VALIDATION`), submit request `EXECUTE_QUERY` → process sets `P0_PAGE_PK` | `IMPR_NBR_VALIDATION`, `IMPORTER_ROW_ID` |
| CREATE (page 0) | validations → `PRE-INSERT` → Process form IMPORTERS → `POST-INSERT` | `PRE_INSERT`, `POST_INSERT` |
| SAVE (page 0) | validations → `PRE-UPDATE` → Process form IMPORTERS | `PRE_UPDATE` |
| DELETE (page 0, confirm 'هل أنت متأكد من عملية الحذف') | process `KEY-DELREC` (no native delete) | `KEY_DELREC` |
| Function IMPR_MCI_SERVICE (FUNCS drawer) | FOS confirm text → Confirm → FOS → page reload with the same `P0_PAGE_PK` | `UPDATE_IMPORTER_CONFIRM_TEXT`, `EXEC_FUNS` |

Validation functions never change a value and never read a sequence. Validations attached to items that are
read-only on a saved record (IMPR_TYPE_CD, CTRY_CD, CITY_CODE_OF_ID, BUS_ID_TYPE_CD) run on request CREATE only
(Forms fires their WVI only when the value changes; their UpdateAllowed is false). EMAIL, BUS_ID_EXPRD_DT and
BUS_ID_ISSUE_DT keep the Forms condition `:SYSTEM.TRIGGER_ITEM = :SYSTEM.CURSOR_ITEM`: checked by the DA; the dates
are also checked by the page validation (format), the e-mail is not (step 03 decides the conditions).

## 2. Entry points (spec order)

| Member | Kind | Forms source | Notes |
|---|---|---|---|
| `READ_ONLY_FLAGS` | P | Make_Field_Entrable / SET_ITEM_PROPERTY of WNFI, WCR, WNRI, POST-QUERY, item WVI | 8 Y / N flags (§3) |
| `P0_PAGE_PK_CHECK`, `IMPORTER_ROW_ID`, `PARAMETERS_ENTRY` | P / F / P | f345 key, IMPR_NBR WVI, :PARAMETER | = IMPR1110 |
| `WHEN_NEW_FORM_INSTANCE` | P | WNFI | `G_ALLOW_MCI` / `G_ALLOW_MOI` from SC_PORT_SETTING (one block: a missing MCI row leaves MOI 0, as Forms); new record: ADD_CTRY_CD 100, CTRY_CD 100 for type 4 / identity 3, 5; 18-15 |
| `POST_QUERY` | P | POST-QUERY | suspension (`LIB_USR.IMPR.IMPR_SUSPENDED` with `FORMS_APX.CUR_HIJ_DATE`), MCI status text, 5 FK lookups; "must be entered" errors kept |
| `WHEN_CREATE_RECORD`, `PRE_RECORD` | P | WCR, PRE-RECORD | port, personal importer type 4; parent name (9-150 message) |
| `PORT_CD_*`, `IMPR_NBR_*` | F / P | item WVI | PORT_CD always read-only (P_CURR_PORT_CD) |
| `IMPR_TYPE_CD_VALIDATION` / `_VALIDATE_ITEM` / `_IS_READ_ONLY` | F / P / F | IMPR_TYPE_CD WVI (+ KEY-LISTVAL return) | STOP_IMPR_CR_TYPE (9-331), type table (CTRY 100), KING_IMPR_SEQ / IMPORTERS_SEQ only in the DA, identity type (1 → set, > 1 → empty + focus, 0 → 2-170), Gulf rule, names |
| `BUS_ID_EXPRD_DT_*`, `BUS_ID_ISSUE_DT_VALIDATION` | F | date WVI | `FORMS_APX.HIJRI_DATE_ERROR` (format + `HIJDATE_DB`) |
| `BUS_ID_TYPE_CD_*` | F / P / F | BUS_ID_TYPE_CD WVI (new) + KEY-LISTVAL | 9-170, identity type name |
| `COMM_RGSTRTN_TYPE_LIST_CHANGED`, `_IS_READ_ONLY`, `_IS_REQUIRED` | P / F / F | WLC, IMPR_TYPE_CD WVI | type 1 clears the branch |
| `CTRY_CD_*` | F / P / F | CTRY_CD WVI + KEY-LISTVAL | Gulf rule for type 12, country name |
| `CITY_CODE_OF_ID_CONFIRM_TEXT` / `_VALIDATION` / `_VALIDATE_ITEM` / `_IS_READ_ONLY` | F / F / P / F | CITY_CODE_OF_ID WVI + WNII, CTRY_CD_OF_ID WVI | CTRY_CD_OF_ID default (100 / CTRY_CD for type 20), full number with the 9-120 **Confirm**, 9-130, city lookups |
| `NATIONAL_NBR_VALIDATION` / `_VALIDATE_ITEM` | F / P | NATIONAL_NBR WVI (new), GET_MAIN_CR_DATA, GET_BRANCH_CR_DATA, GET_CR_DATA | starts with 7; web service fills 16 items and CREATION_FLAG 3; errors ignored as in Forms (`-- SUGGESTION`) |
| `BUS_ID_VALIDATION` / `_WHEN_VALIDATE_ITEM` / `_IS_READ_ONLY` | F / P / F | BUS_ID WVI | lengths, "700", trim, full number (9-120 **information**: one-button alert), 9-130, duplicates, commercial register (fill / 9-190) |
| `BUS_ID_BRNCH_VALIDATION` / `_VALIDATE_ITEM` / `_IS_READ_ONLY` | F / P / F | BUS_ID_BRNCH WVI + KEY-NEXT-ITEM | CHK_IMPR_DUPL (DA only; PRE-INSERT runs it again), 1-220, register, 9-190 / 9-210 |
| `ARBC_IMPR_NAME_IS_READ_ONLY`, `ENG_IMPR_NAME_*` | F / P | WNRI, ENG_IMPR_NAME WVI | names locked with declarations; RemoveRepeat + English letters |
| `IMPR_NBR_PARENT_VALIDATE_ITEM` | P | WVI + KEY-LISTVAL | name; 9-160 message (FETCH leaves the old name) |
| `ADD_CTRY_CD_WHEN_VALIDATE_ITEM`, `_IS_READ_ONLY` | P / F | WVI + KEY-LISTVAL | country name, city warning |
| `CITY_CODE_*` | F / P | CITY_CODE WVI | = IMPR1110 |
| `REGISTER_ITEMS_IS_READ_ONLY` | F | IMPR_TYPE_CD / BUS_ID / BUS_ID_BRNCH WVI | POB, ZIP, FAX, TELEX |
| `IMPR_TEL_NBR_VALIDATION`, `EMAIL_VALIDATION`, `MOBILE_NO_VALIDATION` | F | item WVI | `MOBILE_NO` new in IMPR1130 |
| `PRE_INSERT` | P | PRE-INSERT | 9-220, phone and mobile required, CHK_IMPR_DUPL, `DB_JOURNAL.JOURNALING_ON` with the SUPPORT_ENTRY `G_` items, activity 1, **`CREATE_UNI_IMPR_NEBRAS` with 44 arguments** in the Forms order, `HQ_IMPR_NBR := V_IMPR_NBR`, CGFK$CLR_FK_ON_INS; journaling switched off when it fails |
| `POST_INSERT` | P | POST-INSERT | audit row from the inserted row (ROWID), IMPR_NBR of the row (TODO-VERIFY), journaling off |
| `PRE_UPDATE` | P | PRE-UPDATE | IMPR_NAME_STD, audit row with the record values, HQ number, activity 2, trims |
| `KEY_DELREC` | P | KEY-DELREC, PRE-DELETE, CGRI$CHK_IMPORTERS, ON-ERROR | §4 |
| `ADJ_FUNS`, `UPDATE_IMPORTER_CONFIRM_TEXT`, `EXEC_FUNS` | F / F / P | ADJ_FUNS, EXEC_FUNS, UPDATE_IMPORTER | one function `IMPR_MCI_SERVICE` |

## 3. Read-only and required rules

Full table and the interpretations: `work/IMPR1130/step02/read_only_rules.md`. The rules are **IMPR1130's own**
(IMPR1110's function modes F1–F5 / SF6 do not exist here; the type tables of IMPR_TYPE_CD WVI and POST-QUERY differ
in IMPR1130). `READ_ONLY_FLAGS` returns `P1130_<ITEM>_LOCKED` for the 8 items whose rule changes while the page is
open (COMM_RGSTRTN_TYPE, CTRY_CD, ADD_CTRY_CD, CITY_CODE_OF_ID, BUS_ID, BUS_ID_BRNCH, BUS_ID_EXPRD_DT, REGISTER_ITEMS);
IMPR_NBR, IMPR_TYPE_CD, BUS_ID_TYPE_CD and the two names use Read Only conditions. Three interpretations need review (rules file, "Interpretations" 1–4): the session-long
PRE-INSERT locks, COMM_RGSTRTN_TYPE on a saved record, CREATION_FLAG = 3 as the "data fetched" marker.

## 4. Delete (KEY-DELREC)

Order as in Forms, in one transaction: delete `IMPR_KNWNS` and `IMPR_UPDTS` → `CGRI$CHK_IMPORTERS` (36 checks on 33
tables, generated from the Forms text by `work/IMPR1130/step02/gen_delete_check.py`; first table with rows → its
Designer message) → activity 5 (PRE-DELETE) → `DELETE importers WHERE ROWID = …`. The check of PRE-DELETE
(`CGRI$CASCADE_DELETE`) is the same function and is run once. Database errors are translated by
`importers_on_error('D', …)` (ON-ERROR FRM-40510: 32 constraint messages). The two COMMITs are removed: a refused
delete now keeps the child rows (inventory §15 #4).

## 5. Built-in replacements

| Forms | Where | Replacement |
|---|---|---|
| `INTRFACE.Make_Field_Entrable`, `SET_ITEM_PROPERTY(ENABLED / REQUIRED / INSERT_ALLOWED / UPDATE_ALLOWED)` | 9 + 10 units | rule functions + `READ_ONLY_FLAGS`; calls kept as `-- APEX-DA:` comments |
| `STR.DispAlert` / `DispArbMsg` ERROR, INFORMATION + RAISE | 27 + 12 units | `FORMS_APX.FORM_TRIGGER_FAILURE(text)` / `DISPLAY_ARABIC_ERROR`; in a validation the text is returned |
| `STR.DispAlert` / `DispArbMsg` without RAISE | GET_CR_DATA, PRE-RECORD, IMPR_NBR_PARENT, CGFK warnings, PRE-INSERT result | `FORMS_APX.MESSAGE` / `DISPLAY_ARABIC_INFO` |
| `STR.DispAlert(..., 'CONFIRM')` | CITY_CODE_OF_ID WVI, UPDATE_IMPORTER | confirm-text function + native Confirm + answer parameter |
| `STR.StrFormat(x)`, `STR_DB.*` | PRE-UPDATE, GET_CR_DATA | `STR_DB.StrFormat(x, 0)` (CIC_LIB: SRCH FALSE = 0) |
| `HIJDATE.Cur_Hij_Date` / `Valid_Hij_Date` | POST-QUERY, date WVI | `FORMS_APX.CUR_HIJ_DATE`, `FORMS_APX.HIJRI_DATE_ERROR` |
| `ACTIVITY.ADD_ACTIVITY` | PRE-INSERT / UPDATE / DELETE | `ACTIVITY_DB.ADD_ACTIVITY` with `P_CURR_PORT_CD`, `SSO_APP_USER`, `P_GLOBAL_V_WS_ID` |
| `Des$Form_errors.PUSH / MSGGETTEXT / RAISE_FAILURE`, `CGTE$OTHER_EXCEPTIONS` | Designer code | `FORMS_APX.CG_MESSAGE` (+ `<p2>` for message 5); errors raised or shown as in Forms |
| `CALL_FORM` LOV forms, `DO_KEY('LIST_VALUES')`, `GO_ITEM` | KEY-LISTVAL, buttons, KEY-NEXT-ITEM | popup LOVs (LOV_APX), LOV return values from the item procedures, DA Set Focus |
| `CALL_FORM` / `OPEN_FORM('SUPPORT_ENTRY.FMX')` | WNFI | page 9001 via `SUPPORT_ENTRY.OPEN_DIALOG` (P_MODE 0 / 1) |
| `EXECUTE_QUERY`, `:GLOBAL.EXEC_QUERY_NOW`, `CLEAR_BLOCK` | WNII ×3, IMPR_NBR WVI, UPDATE_IMPORTER | request `EXECUTE_QUERY` / page reload with `P0_PAGE_PK` |
| `SET_BLOCK_PROPERTY(DEFAULT_WHERE / UPDATE_ALLOWED)`, `SET_RECORD_PROPERTY` | PRE-QUERY, POST-QUERY, PRE-INSERT | search-page SQL; not needed |
| `FORMS_DDL('COMMIT')`, `COMMIT`, `:SYSTEM.MESSAGE_LEVEL` | KEY-DELREC, UPDATE_IMPORTER | removed (APEX commits at the end of the request) |
| `SYNCHRONIZE`, `FIRST_RECORD`, `NEXT_ITEM` | CHK_IMPR_DUPL, GET_CR_DATA, KEY-NEXT-ITEM | not needed |
| `:PARAMETER.P_*`, `:PARAMETER.PRSNL_IMPR` / `LETTER_NBR` | many | f345 application items; page items `P1130_P_PRSNL_IMPR`, `P1130_P_LETTER_NBR` |
| `:GLOBAL.ALLOW_MCI` / `ALLOW_MOI`, `LETTER_NBR` / `LETTER_DT` / `SUPP_TITLE_CD` / `PORT_CD` | WNFI, PRE-INSERT, ADJ_FUNS, EXEC_FUNS | application items `G_ALLOW_MCI`, `G_ALLOW_MOI`, `G_LETTER_NBR`, `G_LETTER_DT`, `G_SUPP_TITLE_CD`, `G_PORT_CD` (passed as parameters) |
| `:GLOBAL.VALID`, `SET`, `INS`, `EXEC_QUERY_NOW`, `IMPR_NBR`, LOV return globals | item triggers | VALID → "pair already valid"; SET → local; INS never read (dropped); the others → page items / requests |

## 6. Messages and errors

All texts are the Arabic literals of the Forms code (or message numbers through `FORMS_APX.ARABIC_MESSAGE`). New
compared with IMPR1110: 9-170 (identity type 4/5 vs country), 9-331 (STOP_IMPR_CR_TYPE), "رقم المنشأة" must start
with 7, mobile number checks, the delete messages. The Designer message 5 "Cannot delete <p1> while dependent <p2>
exists" is the English default text with both parameters replaced (TODO as in FORMS_APX.CG_MESSAGE: the Arabic text
of the message library, OFGTEL / CIC_AMSG, is not verified).

## 7. Dropped logic

The OLB frame (FORM KEY-* / ON-* / timers / mouse / window triggers, TOOLBAR, TITLE, LSIDE, EDI_MSG, PUs CHECK_TIMEOUT,
EDI_MSG_*, TOGGEL_WND, MOUSE_CLICK, PRINT_REPORT, RETURN_MSG, TURN_MSG, TERMINATE_FUN, WHEN_TIMER_EXPIRED_MSG,
EXECUTE_FUNCTION) → f345 page template, page 0 toolbar, FUNCS drawer, session timeout (IMPR1110 decisions §15 #9).
PRE-FORM (NLS ALTER SESSION, help path), KEY-HELP, 38 Designer KEY-LISTVAL checks, the LOV buttons of the non-displayed CREATION_FLAG / CUSTOMS_ENTERED, `ARBC_IMPR_NAME.KEY-NEXT-ITEM`
(temporary values restored at once), `CGFK$CHK_IMPORTERS_IMP_MB_FK` (no caller), `DEV_VERSIONS`,
`CG$IMPR1130_PROD_CENTRL_GLOBAL`, the non-displayed lookup items `L_CT_CITY_STATUS`, `L_CT_CITY_STATUS2`,
`CTRY_CTRY_STATUS`, `ITIDT_NOTE`, `STATUS` (filled by the lookups, read by no code). Full list:
`work/IMPR1130/step02/classification.md`.

## 8. Open items, assumptions and deviations

| # | Item | Kind | Where |
|---|---|---|---|
| 1 | Package not compiled (DB 12.1.0.2 needed); grants to `LIB_APX_USR` for GNRL, IMPR, IMPR_CENTRAL, IMPR_UTILITIES, MCISERVICE, STR_DB, DB_JOURNAL, ACTIVITY_DB and the tables (inventory §15 #12) | TODO | all |
| 2 | `CREATE_UNI_IMPR_NEBRAS`: 44 arguments as IMPR1130 passes them; does it insert IMPORTERS itself? (inventory §15 #5) | TODO-VERIFY | `PRE_INSERT` |
| 3 | `IMPR_NBR` after insert read from the inserted row (inventory §15 #15) | TODO-VERIFY | `POST_INSERT` |
| 4 | `GET_CUSTOMS_SETTING('COMM_TABLE_UNCHECK', 9)` without the port, as Forms and IMPR1110 (inventory §15 #6) | TODO-VERIFY | `bus_id_brnch_logic` |
| 5 | Journaling switched off when PRE-INSERT / POST-INSERT fail (pooled sessions) | deviation (safety) | `PRE_INSERT`, `POST_INSERT` |
| 6 | Delete in one transaction (inventory §15 #4) | deviation (proposed) | `KEY_DELREC` |
| 7 | Identity type with several choices: the type validation empties BUS_ID_TYPE_CD and the user chooses it in its LOV (Forms opened the LOV automatically; cancelling it emptied the activity type too) | deviation (§4c) | `impr_type_cd_logic` |
| 8 | Read-only interpretations 1–4 | assumption | `read_only_rules.md` |
| 9 | Web-service errors ignored (`WHEN OTHERS THEN NULL`) | kept + SUGGESTION | `get_cr_data`, `NATIONAL_NBR_VALIDATE_ITEM` |
| 10 | Arabic text of Designer message 5 | TODO | `delete_message` |
| 11 | `PRE-RECORD` / `IMPR_NBR_PARENT`: DispArbMsg 'ERROR' without RAISE shown as information (as IMPR1110) | assumption | `PRE_RECORD`, `IMPR_NBR_PARENT_VALIDATE_ITEM` |

## 9. How the package was built and checked

1. `python3 -I work/IMPR1130/compare_impr1110.py` – unit-by-unit comparison with IMPR1110 (`work/IMPR1130/compare_impr1110.md`).
2. Hand-written body source `work/IMPR1130/step02/impr1130_body.src.sql` and spec `plsql/IMPR1130/impr1130_spec.sql`.
3. `python3 -I work/IMPR1130/step02/build_body.py` – generates the delete check (`gen_delete_check.py`), writes
   `plsql/IMPR1130/impr1130_body.sql` and runs the checks: **0 problems**.
4. `python3 -I work/IMPR1130/step02/classify.py` – classification of the 178 units; every converted target must be a
   member of the spec.
5. First version of the package: no previous version to keep under `rollback/` (CLAUDE.md §6.2 applies from 002 on).
