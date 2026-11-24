# IMPR1130 – Import notes (step 04, revision 1, f345 standard)

> ⚠️ **REVIEW BEFORE IMPORT.** `f345_impr1130.sql` is generated `wwv_flow_api` code. That is **not** an officially
> supported way to build APEX applications. Import it into a **DEV** workspace only, export (back up) the target
> application first, and open both pages in Page Designer afterwards. **Status: NOT IMPORTED, package NOT COMPILED.**

| Item | Value |
|---|---|
| Form | IMPR1130 (XML module `IMPR1110_PROD_CENTRL`) – "إضافة وتعديل بيانات مستورد" |
| Standard | f345 (`apex/Reference/f345.sql`), `CLAUDE.md` §4b–§4d, `docs/f345_reference_standard.md` |
| Target | Oracle APEX 21.2 (export version `2021.10.15`), Oracle Database 12.1.0.2, application 202530 |
| Pages | 1130 `IMPR1130`, 113001 `IMPR1130_SEARCH` (page group `IMPR` of the IMPR1110 export) |

## 1. Files

| File | What it is |
|---|---|
| `apex/IMPR1130/f345_impr1130.sql` | The component export (3,756 lines) with the four `__…__` placeholders, `-- REVIEW BEFORE IMPORT` header |
| `apex/IMPR1130/f202530_impr1130_import.sql` | Import-ready copy: workspace 23232323, application 202530, ID offset 460632461717563830, schema `CUSTOMS` (values of the 2026-11-18 IMPR1110 import) |
| `scripts/gen_apex_impr1130.py` | The generator; written by `work/IMPR1130/step04/make_generator.py` from the IMPR1110 generator (same helpers and checks). Re-run after a design change; do not edit the `.sql` |
| `work/IMPR1130/step03/page_design.json` | The design (step 03) the export implements; spec `analysis/IMPR1130/IMPR1130_apex_page_spec.md` |
| `work/IMPR1130/step04/generator_output.txt`, `uncertain.json` | Last generator run (counts, uncertain parameters, `problems: none`) |
| `plsql/IMPR1130/impr1130_spec.sql`, `impr1130_body.sql` | Package `IMPR1130` 001 called by the pages |

Generator counts: 2 pages, 4 regions, 76 items, 3 buttons, 15 validations, 21 processes, 36 DAs / 58 actions
(31 FOS, 4 JavaScript of 1–2 lines), 3 computations, 2 branches, search IG with 8 columns, 4 shared LOVs
(10 column definitions); no application item, message, page group or authorization scheme is created.

## 2. Prerequisites (in this order)

1. **IMPR1110 export imported** (application 202530): page group `IMPR` (id 900001000010), application items
   `G_ALLOW_MCI`, `G_ALLOW_MOI`, `G_LETTER_NBR`, `G_LETTER_DT`, `G_PORT_CD`, `G_SUPP_TITLE_CD`, `G_CHK_IMP_TYP`,
   `P_PRSNL_IMPR`, `P_LETTER_NBR`, Application Setting `HIJRI_DATE_FORMAT`, LOVs `LOV_SD_PORTS`, `LOV_IMPR_TYPE`,
   `LOV_COUNTRIES`, `LOV_IMPR`, `LOV_COMM_RGSTRTN_TYPE`, `LOV_ALLOWED_EXPORT`, `LOV_EXPRESS_POST`, `LOV_CAR_AGENT_FLAG`.
   The generator checks they are in `apex/IMPR1110/f345_impr1110.sql`.
2. **SUPPORT_ENTRY export imported** (page 9001, application item `G_SUPPORT_ENTRY_CALLER`) and package
   `SUPPORT_ENTRY` 002 compiled (`OPEN_DIALOG`).
3. Packages compiled as `LIB_APX_USR` with synonyms / grants: `FORMS_APX` 004, `LOV_APX` (current version),
   **`IMPR1130` 001**. `LIB_APX_USR` needs the grants of the inventory §15 #12 (GNRL, IMPR, IMPR_CENTRAL,
   IMPR_UTILITIES, MCISERVICE, STR_DB, DB_JOURNAL, ACTIVITY_DB, HIJDATE_DB and the tables of the inventory §10.5).
4. Page 0 has the DA `NUMBER ONLY` (in `apex/f202530_full.sql`; after a component-only import add it once by hand,
   see `apex/IMPR1110/import_notes.md` §5).
5. The FOS plug-in *Execute PL/SQL Code* (`COM.FOS.EXECUTE_PLSQL_CODE`) is installed (f345 has it).

## 3. Import

```
sql CUSTOMS@<tns> @apex/IMPR1130/f202530_impr1130_import.sql
```

or App Builder → Import → File Type **"Page or Component Export"**. Pages 1130 and 113001 are removed first
(`remove_page`), so a re-import is safe; the 4 LOVs keep their ids (a LOV with the same name and another id makes the
import fail: delete it first).

If the component import fails on 202530 as the IMPR1110 one did on 2026-11-18 (`WWV_FLOW_STEP_UI_FK` /
`WWV_FLOW_LISTS_PK`), rebuild the full application file instead:
`python3 -I scripts/build_full_app.py --app-id=202530 --shift-ids=460632461717563830 apex/IMPR1110/f345_impr1110.sql
apex/SUPPORT_ENTRY/f345_support_entry.sql apex/IMPR1130/f345_impr1130.sql [other exports]` (not run in this session:
`apex/f202530_full.sql` had uncommitted changes of another session).

## 4. Page 9001 and `P0_PAGE_PK`

f345 `SCREEN ENTRY RESET` keeps the open record only for `<page>` and `<page>01`. Page 9001 is protected by
`SUPPORT_ENTRY.OPEN_DIALOG` (it keeps 1130 in `G_SUPPORT_ENTRY_CALLER`) and its own `G_LAST_PAGE KEEP`. Page 113001 needs
no protection.

## 5. JavaScript actions (4)

| DA | Lines | Why |
|---|---|---|
| `CITY_CODE_OF_ID WHEN-VALIDATE-ITEM` | 2 | question 9-120 with a server text, answer to `P1130_ANSWER`, custom event for the second FOS |
| `IMPR_MCI_SERVICE EXECUTE-FUNCTION` | 2 | question of UPDATE_IMPORTER with a server text |
| `SUPPORT_ENTRY WHEN-NEW-FORM-INSTANCE`, `SUPPORT_ENTRY WHEN-BUTTON-PRESSED` | 1 each | `apex.navigation.redirect` to the URL of `SUPPORT_ENTRY.OPEN_DIALOG` (as IMPR1110) |

## 6. Uncertain parameters — verify after import

Parameters not shown by f345; the same ones IMPR1110 uses (its export was imported 2026-11-18), except that IMPR1130
adds a DA on Page Load without a triggering element (`p_bind_event_type 'ready'`, JavaScript client condition):

- DA client-side conditions `JAVASCRIPT_EXPRESSION` / `EQUALS` / `NOT_NULL` (`p_triggering_condition_type`, `p_triggering_expression`)
- `NATIVE_ENABLE` / `NATIVE_DISABLE`, `NATIVE_SUBMIT_PAGE`, `NATIVE_CLEAR` attributes
- ROWID primary key of the Form region (`p_include_rowid_column`, item source ROWID)
- `p_query_where` on the NATIVE_FORM region
- `p_read_only_when2 => PLSQL` with `p_read_only_when_type => EXPRESSION`
- button DA `p_triggering_button_id`
- cascading Select List parent (`p_lov_cascade_parent_items`, `p_ajax_optimize_refresh`) of BUS_ID_TYPE_CD
- shared LOV `FUNC_BODY_RETURNING_SQL` with the body in `p_lov_query`
- search IG: lazy loading, no total row count, toolbar `ACTIONS_MENU:RESET`

## 7. Post-import review checklist

1. Page 1130 opens empty (new record): PORT_CD = current port, ADD_CTRY_CD = 100, the SUPPORT_ENTRY dialog opens once.
2. Personal importer call (`P_PRSNL_IMPR = 1`): IMPR_TYPE_CD = 4 and read-only; the search shows type 4 only.
3. Type the activity type: identity type filled (one choice) or empty with its list (several); country / address
   country 100 and locked by type; KING / IMPORTERS sequences fill BUS_ID for types 9 / 16–20 only on the change.
4. Identity type 2, ALLOW_MCI = 1, NATIONAL_NBR starting with 7: the Ministry of Commerce data fills the record,
   BUS_ID / BUS_ID_BRNCH become read-only (CREATION_FLAG 3).
5. CITY_CODE_OF_ID with a short BUS_ID: the 9-120 question; yes → full number, no → the change is refused.
6. CREATE: 9-220 / phone / mobile messages, duplicate check, journaling with a SUPPORT_ENTRY letter, the importer
   number message, audit row in IMPR_UPDTS (inventory §15 #15: IMPR_NBR of the new row).
7. SAVE on a saved record: IMPR_NAME_STD, HQ number, audit row 'U', trimmed names; names locked when the importer has
   declarations.
8. DELETE: a refused delete (dependent rows) shows the Designer message and keeps IMPR_KNWNS / IMPR_UPDTS.
9. Function IMPR_MCI_SERVICE in the FUNCS drawer only for identity type 2 (MCI) or type 4 / identity 3, 5 (MOI); the
   question, the update, the re-query.
10. Search page 113001: one search text, Enter searches, the link opens the importer (URL-safe ROWID).

## 8. Open items

| # | Item |
|---|---|
| 1 | LOV_APX change request (Gulf list for type 12): `work/IMPR1130/step03/lov_apx_change_request.md` |
| 2 | Not compiled / not imported (no database in this session) |
| 3 | Open questions of the inventory §15 and the logic report §8 |
