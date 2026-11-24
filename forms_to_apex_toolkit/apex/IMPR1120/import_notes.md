# IMPR1120 – Import notes (step 04, revision 1, f345 standard)

> ⚠️ **REVIEW BEFORE IMPORT.** `f345_impr1120.sql` is generated `wwv_flow_api` code, which is **not** an officially supported way to build APEX applications.
> - Import it into a **DEV** workspace only.
> - Export (back up) the target application first.
> - Open every page in Page Designer afterwards.

| Item | Value |
|---|---|
| Form | IMPR1120 – "صيانة توقيفات المستوردين" |
| Standard | f345 reference application (`apex/Reference/f345.sql`), `CLAUDE.md` §4b / §4c, `docs/f345_reference_standard.md` |
| Target | Oracle APEX 21.2 (export version `2021.10.15`, release `21.2.0`), Oracle Database 12.1.0.2 |
| Pages | 1120 `IMPR1120`, 112001 `IMPR1120_SEARCH`; page group `IMPR` (from IMPR1110) |
| Design | `analysis/IMPR1120/IMPR1120_apex_page_spec.md` (step 03) |
| Status | **NOT IMPORTED**, package **NOT COMPILED** |

## 1. Files

| File | What it is |
|---|---|
| `apex/IMPR1120/f345_impr1120.sql` | The export: a 2237-line `wwv_flow_api` component export with the four `__…__` placeholders and the `-- REVIEW BEFORE IMPORT` header |
| `apex/IMPR1120/f202530_impr1120_import.sql` | Import-ready copy for application **202530**: the same export with workspace 23232323, application 202530, ID offset 460632461717563830 and schema `CUSTOMS` filled in. For any other application, regenerate it |
| `apex/f202530_full.sql` | Full application export of 202530: f345 + IMPR1110 + IMPR1120, IDs shifted by 460632461717563830, header offset 0 (the way the IMPR1110 import succeeded on 2026-11-18). Rebuilt with `python3 -I scripts/build_full_app.py --app-id=202530 --shift-ids=460632461717563830 apex/IMPR1110/f345_impr1110.sql apex/IMPR1120/f345_impr1120.sql`. Checked: 1833 IDs, no duplicate, no undefined ID, no placeholder. Rebuilding from IMPR1110 alone reproduces the previous file byte for byte |
| `plsql/IMPR1120/impr1120_spec.sql` + `impr1120_body.sql` | Package `IMPR1120` version **009**, which holds the logic of this form (009 = common helpers moved to `FORMS_APX` 004; 008 = Hijri date format from the Application Setting `HIJRI_DATE_FORMAT`; 007 = URL-safe ROWID key from the search page; 006 = compile fix: no private function inside SQL; 003 = 002 without the `I_` / `IO_` / `O_` prefix; 004 = page items passed as `P_<ITEM>`, e.g. `P_PORT_CD => :P1120_PORT_CD`; 005 = no doubled `P_P_` (`P_CURRENT_SIDE => :P1120_P_CURRENT_SIDE`) and helper `hijri_text_to_date`; rule in `scripts/parameter_names.py`) |
| `scripts/gen_apex_impr1120.py` | The generator. The design data is in the script (sections marked "spec N"). Re-run it after a spec change; do not edit the `.sql` by hand |

Generator summary (`python3 -I scripts/gen_apex_impr1120.py`):

```
create_page 2, create_page_plug 6, create_page_item 26, create_page_button 1,
create_page_validation 5, create_page_process 14, create_page_da_event 7,
create_page_da_action 8, create_page_computation 1, create_page_branch 2,
create_region_column 27, create_interactive_grid 2, create_ig_report_column 27,
create_list_of_values 2, create_message 1,
create_flow_item 0, create_security_scheme 0, create_page_group 0
NATIVE_JAVASCRIPT_CODE actions 0, FOS actions 5
placeholders: __APP_ID__, __ID_OFFSET__, __SCHEMA_NAME__, __WORKSPACE_ID__
problems: none
```

The self-check covers:
- template IDs present in f345;
- no ID clash with f345 or the IMPR1110 export, and every referenced ID defined;
- every `IMPR1120.<member>` present in the package spec, with **exactly** its parameter names;
- every bind an existing page item, grid column or f345 application item;
- every FOS item to submit / return exists;
- no JavaScript, AJAX callback, security scheme, `pkg_` or `AI_` names.

A test with a wrong parameter name, an unknown member and an unknown bind confirmed that the check reports each of them.

### Shared LOVs in LOV_APX (2026-11-24, CLAUDE.md §4d)

Every SQL shared LOV of this export now has the type *PL/SQL Function Body returning SQL Query* and calls the
common package `LOV_APX` (`plsql_templates/lov_apx.sql`, version 001), e.g.
`return LOV_APX.CITIES(P_COUNTRY_ITEM => 'P1110_ADD_CTRY_CD');`. The queries are the same as before.
Static LOVs are unchanged.

- **Install `plsql_templates/lov_apx.sql` before the import** (package, public synonym `LOV_APX`, EXECUTE to
  `CUSTOMS` and the other grantees). Without it every LOV of these pages fails with PLS-00201.
- **Verify after the import (one LOV is enough):** Shared Components → List of Values → `LOV_SUSPN_SIDE_CD` → Source:
  *Type* = PL/SQL Function Body returning SQL Query, the body shows the `LOV_APX` call, Return `R` /
  Display `D`. `p_source_type => 'FUNC_BODY_RETURNING_SQL'` is not in f345 or in the real 21.2 export
  `f202604.sql`. If the import rejects it, tell Claude Code: the value is one constant in `scripts/lov_apx.py`.
- At runtime: open the grid column `SUSPN_SIDE_CD` (الجهة) of region IMPR_SUSPN; the select list shows the same rows as before.

## 2. Placeholders

The script has `set define off`. There are four tokens:

| Token | Value for 202530 | How to get it |
|---|---|---|
| `__WORKSPACE_ID__` | 23232323 | `SELECT workspace_id FROM apex_workspaces WHERE workspace = '<NAME>';` |
| `__APP_ID__` | 202530 | the application installed from f345 |
| `__SCHEMA_NAME__` | `CUSTOMS` | `SELECT owner FROM apex_applications WHERE application_id = <APP_ID>;` |
| `__ID_OFFSET__` | 460632461717563830 | `SELECT template_id - 11621850520475869674 FROM apex_application_temp_page WHERE application_id = <APP> AND template_name = 'Standard';` |

**The offset must match the installed application.** Templates, the user interface, the page 0 toolbar region, the *Page Functions* list and the IMPR1110 page group are referenced as `wwv_flow_api.id(<number>)`. They resolve only with the right offset. A component import with offset 0 into 202530 failed with ORA-02291 on 2026-11-18. Do **not** import with `apex_application_install.generate_offset`.

## 3. Prerequisites

1. **Application 202530 contains the IMPR1110 export.** This export reuses its page group `IMPR` (`wwv_flow_api.id(900001000010)`) and its LOVs `LOV_SD_PORTS` and `LOV_ALLOWED_EXPORT` (by name). Without them the component import fails (page group: ORA-02291) or the items have no LOV. The full-application file (option B) contains both forms, so it has no such dependency.
2. **Package `FORMS_APX` version 004 compiled first** (`plsql_templates/forms_apx.sql`, owner `LIB_APX_USR`, public synonym and grants at the end): since 2026-11-24 it holds the helpers common to every form (`CHECK_ERROR`, `REQUIRED_VALIDATION`, `GET_MODULE_ID`, `HEADER_TITLE`, `ROWID_FROM_URL`, `HIJRI_DATE_FORMAT` and the Hijri date helpers, `ARABIC_MESSAGE`, `CG_MESSAGE`, `CUR_HIJ_DATE` ...); the form packages and the pages call `FORMS_APX.<NAME>`. It now needs `STR_DB`, `HIJDATE_DB` and `SC_SYSTEM_OBJECTS` (as the form packages did). `SELECT FORMS_APX.PKG_VERSION FROM dual` shows `004`.
3. **Package `IMPR1120` version 009 compiled** as `LIB_APX_USR.IMPR1120`:
   - Run `plsql/IMPR1120/impr1120_spec.sql`, then `impr1120_body.sql`.
   - The spec ends with the public synonym and `GRANT EXECUTE` to `LIB_USR`, `SECURITY_DEFAULT`, `SECURITY_PROD` and `CUSTOMS`; run it as a user allowed to create public synonyms.
   - `SELECT IMPR1120.PKG_VERSION FROM dual` must show `VERSION NO. IS:009`.
   - The body needs the direct grants listed in the extraction report §8 (tables `IMPR_SUSPNS` (SELECT, UPDATE), `IMPORTERS`, `IMPORTER_BASIC_DATA`, `SD_PORTS`, `CG_REF_CODES`, lookup tables, `SC_SYSTEM_OBJECTS`, `SC_PORT_SETTING`; packages `ACTIVITY_DB`, `HIJDATE_DB`, `STR_DB`, `GNRL`, `SMS_MESSAGE`, `FORMS_APX`).
   - `STR_DB`, `GNRL`, `SMS_MESSAGE` and `LIB_APX_USR.APEX_NOTIFICATIONS` have no source in the repository, so check that they exist with the signatures the Forms code used.
4. **Grid DML runs as the package**, so `CUSTOMS` needs no DML grant on `IMPR_SUSPNS`. The grid process calls `IMPR1120.IMPR_SUSPN_SAVE_ROW`, which inserts and updates with definer rights (`LIB_APX_USR`). The two region queries do need SELECT for `CUSTOMS` on `IMPR_SUSPNS`, `IMPORTERS`, `SD_PORTS`, `IMPR_TYPES` and `COUNTRIES`.
5. **FOS *Execute PL/SQL Code*** plug-in from f345 (`COM.FOS.EXECUTE_PLSQL_CODE`), used by the 5 FOS actions.
6. **Shared components this export creates:** LOVs `LOV_IMPR_SUSPN_RSN_CD` and `LOV_SUSPN_SIDE_CD`, and Text Message `IS_1_IMP_FK` (ar-sa). No application item, no security scheme, no page group.

## 4. Import

Choose **one** option.

**A. Component import into 202530** (recommended while IMPR1110 is installed and unchanged):
- App Builder → Import → File Type *Page or Component Export* → `apex/IMPR1120/f202530_impr1120_import.sql`, or
- `sql CUSTOMS@<tns> @apex/IMPR1120/f202530_impr1120_import.sql`.

It removes and re-creates pages 1120 and 112001 only (`remove_page`). It also creates the two LOVs and the Text Message with fixed IDs. On a second import they normally replace the same components. If APEX reports a duplicate LOV or message name instead, delete `LOV_IMPR_SUSPN_RSN_CD`, `LOV_SUSPN_SIDE_CD` and `IS_1_IMP_FK` first (not verified).

**Page 0 handler (required for `number_only`):** the full application file `apex/f202530_full.sql` already adds the DA `NUMBER ONLY` to page 0. After a component-only import, add it once by hand if page 0 does not have it: Page Designer → page 0 → Dynamic Actions → Create: Name `NUMBER ONLY`, Event *Page Load*; True action *Execute JavaScript Code*, Fire on Initialization = Yes, Code = the line `JS` of `scripts/number_only.py`. Without it the class has no effect.

Change 2026-11-24 (user request): Number Field items accept only digits. They carry the CSS class `number_only`, and page 0 has one DA `NUMBER ONLY` (Page Load, one line of *Execute JavaScript Code*, `scripts/number_only.py`; the form pages have no copy): while typing or pasting, every character that is not a digit is removed, and Arabic-Indic / Persian digits become 0-9. Not on popup LOVs (they keep the name search) or phone fields. Editable grid number columns get the same class (column *CSS Classes*); none exists today: the grid number columns are hidden, select lists or read-only (pages 1120 / 112001). Check: type a letter, `-` or `.` in `P1120_IMPR_NBR` → nothing appears; type ١٢٣ → 123; paste `12ab3` → 123.

Change 2026-11-24 (user request): the common helpers are in `FORMS_APX` 004 only. Page 1120 calls `FORMS_APX.CHECK_ERROR(IMPR1120.<ITEM>_VALIDATION(...))` in the FOS dynamic actions, `FORMS_APX.GET_MODULE_ID(..., FORM_NAME => 'IMPR1120')`, `FORMS_APX.HEADER_TITLE(..., DEFAULT_TITLE => 'صيانة توقيفات المستوردين')` and `FORMS_APX.HIJRI_DATE_FORMAT` in the grid SQL. Package 009 has no logic change (previous: `rollback/IMPR1120/step04_v008/`).

Change 2026-11-23 (user request): the Hijri date format comes from one place, the APEX **Application Setting `HIJRI_DATE_FORMAT`** (Shared Components > Application Settings), value `YYYY-MM-MI`: the output of the f345 Hijri picker (`hijri-date-default`, iYYYY-iMM-iDD), with the day kept in the minutes. The IMPR1110 export creates the setting; `IMPR1110.HIJRI_DATE_FORMAT` and `IMPR1120.HIJRI_DATE_FORMAT` read it (default `YYYY-MM-MI` when it is missing). To change the format, change the setting (or `APEX_APP_SETTING.SET_VALUE`), no recompile; it must stay a mask that the picker writes. Existing data needs no change (only the text form changes). The grid SQL uses `(SELECT IMPR1120.HIJRI_DATE_FORMAT FROM dual)`. Import IMPR1110 (or the full app) first, so that the setting exists; without it the default is used.

Fix 2026-11-23: "cannot insert NULL" when a new suspension was saved. The master keys of a new grid row were copied by a separate row process (`IMPR_SUSPN MASTER KEYS`) and did not reach the save process. They now come from the master form directly: the hidden columns `PORT_CD` / `IMPR_NBR` default to the items `P1120_PORT_CD` / `P1120_IMPR_NBR`, and the save call passes `PORT_CD => NVL(:PORT_CD, :P1120_PORT_CD)`, `IMPR_NBR => NVL(:IMPR_NBR, :P1120_IMPR_NBR)`. The `IMPR_SUSPN MASTER KEYS` process is removed. No package change.

Fix 2026-11-23: the error "The checksum computed on the request … did not match the checksum passed into the show procedure" when an importer was opened from the search page. Its ROWID contained `+`, which arrives in an `f?p` value as a space. The search page now passes the ROWID URL-safe (`+` → `-`, `/` → `_`) and `IMPR1120.P0_PAGE_PK_CHECK` (package 007) translates it back. Compile package 007 before this import.

Change 2026-11-23 (user request): search page 112001 has one search text `P112001_SEARCH` over all columns (replacing the port, port name and Arabic name criteria and the grid's toolbar search), a CLEAR button, search on Enter (DA `SEARCH KEY-ENTER`), and opens fast: no query until a search, no total row count, no sort clause; focus on the search field; بحث and Enter refresh the grid (the loading overlay was removed: it did not work). Package comments of the PRE-QUERY members still name the old search items.

Fix 2026-11-23: the import error "Interactive Grid Column 'SUSPN_STRT_DT' specified for Dynamic Action 'IMPR_SUSPN SUSPN_STRT_DT WHEN-VALIDATE-ITEM' does not exist". `create_region_column` has no region parameter; APEX attaches a column to the region created last. The IG columns came after the FUNCS region, so they belonged to FUNCS. The generator now writes the IG columns and grid right after region `IMPR_SUSPN`, as f345 AGR1100 does, and the self-check reports any column that does not follow an IG region and any column DA whose column is not in its region.

**B. Full application** `apex/f202530_full.sql` (App Builder → Import → *Database Application*, reuse application ID 202530). This **replaces the whole application**, including the IMPR1110 pages, with this repository's version.

## 5. After import – review and tests

1. **Page Designer, both pages:** no "invalid template" warning; the region templates are *Interactive Report* (IMPORTERS), *Standard* (grids) and *Blank with Attributes* (hero, criteria).
2. **Advisor** on pages 1120 and 112001.
3. **Verify the uncertain parameters** (§6) in Page Designer. Each one is a setting to look at: for example, `SUSPN_RSN_CD` must show *List of Values: Shared Component LOV_IMPR_SUSPN_RSN_CD*, and the grid process must show *Target Type: PL/SQL Code* with the `IMPR_SUSPN_SAVE_ROW` call.
4. **Functional tests**, as in Forms, for each site (`CURRENT_SIDE` 1, 2, 3):
   - **Entry:** site 3 outside port 99 gets "ليس لديك الصلاحية للدخول على الشاشة".
   - **Open an importer:** type `IMPR_NBR` (unknown number → message 9-150; known number → the page shows the importer and its active suspensions); also open one from SEARCH (page 112001, filters, link). Page 0 CREATE with a number does the same.
   - **Search page 112001:** it opens at once with an empty grid (no query yet). Type any part of a port code or name, importer number, unified number, Arabic or English name, agent, activity, ID number, branch or country in the one search field and press بحث or Enter: every column is searched (typing other keys does not search). When the dialog opens, the cursor is in the search field. Open several importers from the link column, including ones whose ROWID contains `+` or `/` (no checksum error). Outside port 99 only the user's port is found. Press مسح البحث: the field and the grid are emptied. Time the opening and one search on port 99 (all importers).
   - **Add a suspension:**
     - start date defaults to today in the format `YYYY-MM-MI` (e.g. 1447-05-22), the picker writes the same format, and a date typed as 22-05-1447 gives "يجب إدخال التاريخ بالصيغة سنة-شهر-يوم (YYYY-MM-MI)";
     - the reason, text and side default for the site;
     - a start date before today gives 9-100, and an end date before the start gives 9-110;
     - a reason or side not allowed for the site gives the placeholder message;
     - SAVE inserts with `SUSPN_SEQ = MAX + 1`, writes the activity log (type 1) and sends the SMS / notification (check the notification tables);
     - add two rows in one SAVE and check that the numbers differ;
     - check that the new rows carry the importer's port and number (`SELECT port_cd, impr_nbr FROM impr_suspns WHERE suspn_seq = …`), with no "cannot insert NULL" error.
   - **Edit a suspension:** change only the end date of an older suspension and check that there is **no** 9-100 error. An end date ≤ today releases the row (it disappears after SAVE). Activity log type 2.
   - **Delete a suspension:** the row disappears, the table row still exists with `SUSPN_RLSE_DT` = today, activity log type 3.
   - **Rows of another site:** read only. A delete or update forced in the browser is refused by the server.
   - **`SUSPN_SIDE_CD`** is read only on saved rows.
   - **Page 0 DELETE** with an importer open gives the PRE-DELETE message, and nothing is deleted.
5. **`CURRENT_SIDE`:** check that `P1120_P_CURRENT_SIDE` gets a value. It comes from `SC_PORT_SETTING`, VAR_NAME `CURRENT_SIDE` (inventory §15 #1). If it stays empty, every site rule is off.

## 6. Uncertain parameters (not in f345; check after import)

| # | Parameter / pattern | Where | If wrong |
|---|---|---|---|
| 1 | `NATIVE_IG_DML` with `p_attribute_01 => 'PLSQL_CODE'` and the code in `p_attribute_04`; `p_attribute_05 'Y'` (lost update), `06 'N'` (lock row), `08 'Y'` | process `IMPR_SUSPN - Save Interactive Grid Data` | set *Target Type = PL/SQL Code* and paste the call by hand. **Key point of this page** |
| 2 | IG select list column on a shared LOV: `p_lov_type => 'SHARED'` + `p_lov_id` | columns `SUSPN_RSN_CD`, `SUSPN_SIDE_CD` | choose the shared LOV in Page Designer |
| 3 | IG column default `p_default_type => 'EXPRESSION'` + `p_default_language => 'PLSQL'` | `SUSPN_STRT_DT`, `SUSPN_RSN_CD`, `SUSPN_RSN_TEXT`, `SUSPN_SIDE_CD` | Default → PL/SQL Expression, paste the expression |
| 4 | FOS *Items to Return* = grid column `SUSPN_RSN_TEXT` | DA `IMPR_SUSPN SUSPN_RSN_CD WHEN-VALIDATE-ITEM` | if FOS does not set columns: return into a hidden page item and add a native *Set Value* on the column |
| 5 | read-only `NATIVE_FORM` region `p_is_editable => false` | region `IMPORTERS` | turn *Edit Enabled* off by hand |
| 6 | ROWID primary key (`p_include_rowid_column`, item source ROWID) | `P1120_ROW_ID` | as IMPR1110 |
| 7 | item `p_read_only_when2 => 'PLSQL'` with type `EXPRESSION` | `P1120_PORT_CD` | as IMPR1110 |
| 8 | Display Only based on LOV (`p_attribute_02 => 'LOV'` + `p_named_lov`) | `P1120_IMPR_EXPR_TYPE` | set *Based On: Display Value of List of Values* |
| 9 | `create_ig_report p_rows_per_page => 5` | grid `IMPR_SUSPN` | set 5 rows in the saved report |
| 10 | branch `REQUEST_IN_CONDITION` | branch `EXECUTE-QUERY` | – |
| 11 | DA client condition `NOT_NULL`, `NATIVE_SUBMIT_PAGE` attributes, button DA `p_triggering_button_id`, `create_message` | as IMPR1110 | as IMPR1110 |
| 12 | search grid: `p_lazy_loading => true`, `p_show_total_row_count => false`, toolbar `ACTIONS_MENU:RESET` (no toolbar search field); native `NATIVE_CLEAR` action with `p_affected_elements` | page 112001 grid `IMPORTERS_SEARCH`, DA `CLEAR WHEN-BUTTON-PRESSED` | set them by hand if APEX ignores them |
| 13 | IG column default from a page item: `p_default_type => 'ITEM'` + `p_default_expression` | columns `PORT_CD` (`P1120_PORT_CD`), `IMPR_NBR` (`P1120_IMPR_NBR`) | in Page Designer the column shows *Default: Item*; the save call has `NVL(...)` as a second safeguard |

## 7. Notes, deviations and open items

- **No modal child page** other than 112001, so SCREEN ENTRY RESET keeps `P0_PAGE_PK` and no `G_LAST_PAGE KEEP` is needed.
- **Not generated:** Popup LOV *Additional Outputs* for the port name. It is not in f345 and could not be confirmed for 21.2 (spec §16 #11). For a port 99 user, `P1120_PORT_NAME` stays empty after choosing another port until the importer is queried (cosmetic).
- **Security (SUGGESTION).** `P1120_HQ_IMPR_NBR`, `P1120_PORT_NAME` and `P1120_BUS_ID` are Display Only with *Send On Page Submit* so the SAVE can pass them to the POST-INSERT notification, as Forms did with the screen values. A changed request could therefore send the SMS to another importer's mobile number. A safer version reads these three values from `IMPORTERS` inside the package by `PORT_CD` / `IMPR_NBR`. That changes the package (not done: preserve behaviour first).
- **Carried over from step 03** (spec §16 #6–#13):
  - *Prevent Lost Updates* with PL/SQL DML;
  - per-row read-only for new rows;
  - LOV status filter in Enter-Query;
  - no reset of rejected values;
  - no delete confirmation;
  - placeholder texts;
  - HIGH: notification inside the transaction (no COMMIT), and the source of `CURRENT_SIDE`.
