# IMPR1110 – Import notes (Step 04)

> ⚠️ **REVIEW BEFORE IMPORT.** `f2000_impr1110.sql` is generated `wwv_flow_api` code. This is
> **not** an officially supported way to build APEX applications.
> **No reference export of the target instance was available** (`apex/reference/` is empty).
> Parameter names and plug-in attribute values therefore come from APEX 21.2 exports in
> general, not from your instance.
> Before you import:
> * Use a **DEV** workspace only.
> * Back up the target application (export it) first.
> * After the import, open every page in Page Designer.

| Item | Value |
|---|---|
| Form | IMPR1110 – "إضافة وتعديل بيانات مستورد" |
| Input | `analysis/IMPR1110/IMPR1110_apex_page_spec.md` (step 03) |
| Generator | `scripts/gen_apex_impr1110.py`. Re-run it after a spec change. Do not edit the `.sql` by hand. It reads spec §4 (items) and holds §5–§13 as data. Its self-check: placeholders, defined ids, begin/end balance, no `wwv_flow_imp`, no passwords. |
| Files | `apex/IMPR1110/f2000_impr1110.sql` (export), `apex/IMPR1110/impr1110.js` (static file), this file |
| App id | **2000 = placeholder** (spec §16 Q1). It is used in the file name only. Inside the file the id is `__APP_ID__`. |
| Status | Generated 2026-11-18 by Claude Code. **Not imported, not compiled, JavaScript not run.** |

## 1. Contents

| Component | Count | Notes |
|---|---|---|
| Pages | 3 | 1110 `IMPR1110` (Normal), 1111 `IMPR1110_QUERY` (Modal), 1112 `IMPR1110_MOBILE` (Modal). **1113 (SUPPORT_ENTRY) is not generated** – see §7 |
| Regions | 7 | 1110: `TOOLBAR`, `IMPORTERS`, `IMPORTERS_FUNS` (List / Menu Popup). 1111: `IMPORTERS_QRY`, `IMPORTERS` (IR). 1112: `BLK`, `CTRL_BLK` |
| Page items | 81 | 1110: 77 (76 from spec §4 + `P1110_URL_MOB`). 1111: 2. 1112: 2 |
| Buttons | 10 | 1110: SAVE · CREATE · DELETE · QUERY · CLEAR · EXIT · FUNCTIONS. 1111: SEARCH. 1112: PB_OK, PB_CANCEL |
| Validations | 26 | 25 item validations + `IMPORTERS.REQUIRED-ITEMS`. All run only for request `SAVE` |
| Processes | 13 | 1110: 3 Before Header, 4 After Submit, 3 Ajax Callback. 1112: 2 PL/SQL + Close Dialog |
| Dynamic Actions | 40 events / 40 actions | 1110: 38. 1111: 2 |
| Computations | 2 | `P1110_URL_MOB` (After Header), `P1112_MOBILE_NO` (Before Header) |
| Branch | 1 | 1110 → 1110 after processing |
| Shared LOVs | 13 | 11 SQL (with 13 Popup LOV columns) + 2 static (5 values) |
| Application items | 37 | 9 `AI_P_*` + 28 from `:GLOBAL.*`. All *Restricted – may not be set from browser* |
| Authorization schemes | 13 | `IMPR1110_ACCESS`, 11 × `FUN_<CODE>`, `FUN_REMOVE`. **All return FALSE** – see §6 |
| List | 1 | `LIST_IMPR1110_FUNS` with 11 entries (labels **proposed**, spec §13.4) |
| Page group | 1 | `IMPR` |

## 2. Placeholders

The script has `set define off`. Replace every token before the import, for example:
`sed -i 's/__APP_ID__/2000/g; s/__WORKSPACE_ID__/1234567890/g' f2000_impr1110.sql`.

| Token | Value | How to get it |
|---|---|---|
| `__WORKSPACE_ID__` | workspace id | `SELECT workspace_id FROM apex_workspaces WHERE workspace = '<NAME>';` |
| `__APP_ID__` | IMPR application id (must already exist) | App Builder, or `SELECT application_id FROM apex_applications WHERE workspace = '<NAME>';` |
| `__SCHEMA_NAME__` | parsing schema of the application | `SELECT owner FROM apex_applications WHERE application_id = <APP_ID>;` |
| `__USER_INTERFACE_ID__` | Desktop user interface of the application. Extra token: `create_page` needs it, and it is not a template | `SELECT user_interface_id FROM apex_appl_user_interfaces WHERE application_id = <APP_ID>;` |
| `__TEMPLATE_ID_PAGE_STANDARD__` | page template *Standard* | `SELECT template_name, template_id FROM apex_application_temp_page WHERE application_id = <APP_ID>;` |
| `__TEMPLATE_ID_PAGE_MODAL__` | page template *Modal Dialog* | same view |
| `__TEMPLATE_ID_REGION_STANDARD__` | region template *Standard* | `SELECT template_name, template_id FROM apex_application_temp_region WHERE application_id = <APP_ID>;` |
| `__TEMPLATE_ID_REGION_BUTTONS__` | region template *Buttons Container* | same view |
| `__TEMPLATE_ID_REGION_BLANK__` | region template *Blank with Attributes* | same view |
| `__TEMPLATE_ID_BUTTON_TEXT__` | button template *Text* | `… FROM apex_application_temp_button …` |
| `__TEMPLATE_ID_LABEL_OPTIONAL__` | label template *Optional* | `… FROM apex_application_temp_label …` |
| `__TEMPLATE_ID_LABEL_REQUIRED__` | label template *Required* | same view |
| `__TEMPLATE_ID_LIST_MENU_POPUP__` | list template *Menu Popup* | `… FROM apex_application_temp_list …` |

Check that nothing is left: `grep -n '__[A-Z_]*__' f2000_impr1110.sql` must print nothing.

**Offset:** the file uses `p_default_id_offset => 0` and `wwv_flow_api.id(...)` for every id,
including the template ids. If you import with `apex_application_install.generate_offset`,
APEX adds the offset to the template ids too, and the template references break. Either:
* import without an offset (the generated ids start with 1110…, 1111…, 1112…, 9000… and do
  not clash with normal APEX ids), or
* subtract the offset from each template id before you put it into the placeholder.

## 3. Prerequisites (in `__SCHEMA_NAME__`)

1. Compile, in this order:
   * `pkg_forms_compat` (`plsql_templates/pkg_forms_compat.sql`);
   * `pkg_impr1110` spec + body (`plsql/IMPR1110/`, body **1.0.1**);
   * `pkg_impr1110_apx` spec + body (1.1.0).

   None of them have been compiled yet. Open step 02/03 TODOs remain: `STR_DB`, `INTRFACE`, `TMPLT`, `LIB_USR` …
2. The parsing schema needs SELECT on:
   * `IMPORTERS`, `IMPR_TYPES`, `IMPR_TYPE_ID_TYPES`, `BUS_ID_TYPES`, `CITIES`, `COUNTRIES`;
   * `SD_PORTS`, `CG_REF_CODES`.

   It also needs EXECUTE on `STR_DB`. These are used by the LOVs and by the IR of page 1111.
3. Application attribute *Error Handling Function* = `pkg_forms_compat.apex_error_handler`
   (spec §11). This is not part of the component export, so set it by hand.
4. Upload `impr1110.js` as a Static Application File.
   * The page references `#APP_FILES#impr1110#MIN#.js`, so upload a minified `impr1110.min.js`
     as well.
   * Alternatively, change *JavaScript File URLs* of page 1110 to `#APP_FILES#impr1110.js`.
5. Application process `IMPR_SET_SESSION_PARAMS` (After Authentication) must fill the `AI_P_*`
   items. It is **MISSING SOURCE** (spec §13.2). Without it, `AI_P_CURR_PORT_CD` is NULL and the
   block WHERE clause finds no rows.
6. Application language Arabic + text direction RTL (spec header), set in the application
   attributes.

## 4. Import

```
sql __SCHEMA_NAME__@<tns> @apex/IMPR1110/f2000_impr1110.sql
```
or App Builder → Import → File Type **"Page or Component Export"**.

Alternative with a workspace / application override (read the offset note in §2 first):
```
begin
  apex_application_install.set_workspace('<WORKSPACE>');
  apex_application_install.set_application_id(<APP_ID>);
  apex_application_install.generate_offset;   -- breaks template ids, see §2
  apex_application_install.set_schema('<SCHEMA>');
end;
/
@apex/IMPR1110/f2000_impr1110.sql
```
Re-import:
* Pages 1110–1112 are removed first (`remove_page`).
* Shared components (LOVs, application items, schemes, list, page group) keep the same ids.
  A component import is expected to replace them.
* If a component with the **same name but another id** already exists in the application, the
  import fails. Delete it or rename it first.

## 5. Uncertain parameters and settings left out (check in Page Designer)

| Where | What was generated | Why uncertain / what to check |
|---|---|---|
| Popup LOV items (8) | `p_attribute_01 = 'DIALOG'`, `_02 = 'FIRST_ROWSET'`, `_03 = 'N'` | **Manual entry** (spec: "manual entry allowed") was not set: I am not sure which attribute number it is in 21.2. Set *Manual Entry = Yes* by hand. Display = code (column `D`); the name columns are search/display columns |
| `create_list_of_values_cols` | `p_query_column_name, p_heading, p_display_sequence, p_data_type` | visibility/searchable flags not set → defaults. Check the column list of each LOV |
| Display Only items | `p_attribute_01 = 'Y'` (escape), `_02 = 'VALUE'`, `_04 = 'N'`, `_05 = 'PLAIN'` | `_04` is meant to be **Send On Page Submit = No** (spec §0.4). Check it on 2–3 items. If it is wrong, server values can be overwritten by stale page values |
| Text Field | `_01 'N'`, `_02 'N'`, `_04` subtype (`TEXT`/`EMAIL`/`PHONE`), `_05 'BOTH'` (trim) | check the subtype on `B_EMAIL`, `B_MOBILE_NO`, `P1112_MOBILE_NO` |
| Number Field | `_03 = 'left'` | alignment only |
| Buttons | `p_button_position = 'REGION_TEMPLATE_NEXT'` for all toolbar buttons | the 21.2 position name. The order SAVE · CREATE · DELETE · QUERY · CLEAR · EXIT comes from the sequence |
| Button FUNCTIONS | `p_button_css_classes = 'js-menuButton'`, `data-menu="IMPORTERS_FUNS_menu"` | Universal Theme menu-button pattern. The list region static id `IMPORTERS_FUNS` gives the menu id `IMPORTERS_FUNS_menu` |
| Layout | `p_colspan` from spec §4 (at least 2 for labelled items), no `p_grid_column` | the spec's start columns were not used, so APEX places the items. **Review the layout** against the Forms canvas |
| Hidden server items | Display Only + Column CSS class `u-hidden` (`p_grid_column_css_classes`) | check that the empty columns do not leave gaps |
| `create_worksheet` (1111) | `p_show_detail_link = 'C'`, detail link `javascript:apex.navigation.dialog.close(true,{IMPR_NBR:'#IMPR_NBR#'})` | check that the link returns the number to page 1110 (DA "IMPR1110_QUERY dialog closed") |
| `create_security_scheme` | `p_scheme_type = 'NATIVE_FUNCTION_BODY'`, `p_caching = 'BY_USER_BY_PAGE_VIEW'` | comments are inside the PL/SQL code (no comment parameter was used) |
| Processes / validations | `p_process_when_type = 'EXPRESSION'` + `p_process_when2 = 'PLSQL'` (WHEN-CREATE-RECORD), `'VAL_OF_ITEM_IN_COND_EQ_COND2'` (POST-QUERY) | check the condition of the 3 Before Header processes |
| Process "Close Dialog" (1112) | `NATIVE_CLOSE_WINDOW` without attributes | no items returned. Page 1110 then calls `IMPR1110_FUN('IMPR1110_MOB_RET')` |
| Page 1110 *Warn on Unsaved Changes* | default (Yes) | buttons CREATE/CLEAR ask in `impr1110.clear()`. QUERY ignores the warning (dialog) |
| `apex.item().setRequired` | used only if it exists | I am not sure it exists in 21.2. The fallback sets the `required` attribute and the `is-required` class. **The server check (`REQUIRED-ITEMS`) is what counts** |
| `apex.item().refresh()` on the select list `P1110_BUS_ID_TYPE_CD` | after IMPR_TYPE_CD is validated | no cascading parent is set: the LOVs read the session state, which `IMPR1110_ITEM` updates on every change. Check that the list refreshes |

## 6. Security – must be done before any user test

* **All 13 authorization schemes return `FALSE`** (`-- TODO: MISSING SOURCE`).
  * Nobody can open pages 1110–1112 until the real rules are written.
  * The rules come from `CIC_MENU` / `SEC_LIB` (`IMPR1110_ACCESS`) and `TMPLT.LOAD_FUNCTIONS` (`FUN_*`).
  * These sources are now in the repository (`forms/COMMON/menus/CIC_MENU_MMB.xml`,
    `forms/COMMON/libraries/`); they are to be analysed in a revision of steps 02/03.
  * For a DEV smoke test only, you may temporarily change the body to `RETURN TRUE;`.
    **Never import that into TEST/PROD.**
* Session State Protection:
  * pages are *Arguments Must Have Checksum* (`p_protection_level 'C'`);
  * server items are *Restricted* (`'I'`);
  * URL items (`P1110_PRSNL_IMPR`, `P1110_LETTER_NBR`, `P1111_PRSNL_IMPR`, `P1112_IMPR_NBR`) are *Checksum Required – Session* (`'S'`).
* No credentials, host names or passwords are in the files (self-check).

## 7. Known gaps (carried from step 03 §16 or found while generating)

| # | Gap | Effect | Next step |
|---|---|---|---|
| 1 | Page 1113 SUPPORT_ENTRY not generated | functions IMPR1110F1/F2/F3/F5 show "لم تُنشأ بعد" | `forms/SC/Support_Entry_fmb.xml` now exists → design 1113 (revise step 03) |
| 2 | Authorization rules (§6) | pages closed | analyse CIC_MENU / SEC_LIB / TMPLT |
| 3 | Function titles (`LIST_IMPR1110_FUNS`) proposed | wrong labels possible | TMPLT / SC_SYSTEM_OBJECTS |
| 4 | Alert 9-120 ("prefix the commercial code?") in BUS_ID / BUS_ID_BRNCH validation is **not asked**; the server uses button 1 (yes) | user cannot answer "no" | add `CR` to `ajax_confirm`, then ask it in `impr1110.validate` (x03) |
| 5 | Popup LOV pick detection (`x05 = LOV`, sets `:GLOBAL.MINS_COMM_CD`) uses a mousedown/keydown on the LOV button | a typed value after the LOV button was pressed counts as an LOV pick | acceptable. Check in UAT |
| 6 | Hijri date entry (KEY-F4 calendar) | plain text with mask `MI-MM-YYYY` | spec §16 Q5 |
| 7 | FRM-40202/40350/40654 Arabic texts | English/technical text | spec §16 Q7 |
| 8 | `IMPR1115_SCR` function | message only | when IMPR1115 is converted |
| 9 | Spec DA 3 (BUS_ID confirm), DA 4 (IMPR_NBR re-query), DA 11 (function click) | implemented inside `impr1110.validate` / `applyUi(REQUERY)` / list links `javascript:impr1110.fun(...)`, not as separate DAs | Forms-mirror name kept on the item DA |
| 10 | `P1110_UI_STATE` is **Hidden** (spec: Display Only) | `$v()` must read it on page load. The server only writes it; the page-load code clears it, so a later submit cannot send it back stale | none |
| 11 | `P1110_URL_MOB` (new hidden item + After Header computation `apex_page.get_url`) | page 1112 is opened with a server-built checksum URL | added to spec §4 at the next revision |
| 12 | Static LOV `LOV_COUNTRIES_GULF` replaces the "inline LOV" of `P1110_CTRY_CD` | a Popup LOV needs a shared LOV for its extra columns | none |

## 8. Code change made in this step

`plsql/IMPR1110/pkg_impr1110_body.sql` 1.0.0 → **1.0.1** (previous version:
`rollback/IMPR1110/pkg_impr1110_body_v1.sql`):
* The real `STR.StrFormat` source is in `forms/COMMON/libraries/CIC_LIB.pld`:
  `STR_DB.StrFormat(strInput, V_SRCH)` with `V_SRCH = 1` for TRUE, else `0`.
* The three calls translated from `STR.StrFormat` now pass `1` / `0` instead of `TRUE` / nothing.
  `TRUE` would not compile against a NUMBER parameter.
* The IR of page 1111 uses `str_db.strformat(:P1111_ARBC_IMPR_NAME, 1)` (no BOOLEAN in SQL on 12.1).
* `scripts/expand_orig.py` self-check: 0 problems.

## 9. Post-import checklist

1. Page Designer, pages 1110, 1111, 1112:
   * no "invalid template" warnings;
   * check every item marked in §5.
2. Utilities → Advisor on pages 1110–1112.
3. Shared Components:
   * the 13 LOVs return rows for a sample port;
   * the list has 11 entries;
   * the 37 application items are *Restricted*.
4. Replace the authorization bodies (§6).
5. Test each path. These are the UAT steps (step 05):
   1. open the page (WNFI, PORT_CD disabled);
   2. search with QUERY → 1111 → choose a row (POST-QUERY);
   3. change each validated item (AJAX error inline, focus stays);
   4. new record + SAVE (confirm for class 1 / user type 3, number message);
   5. update + SAVE;
   6. DELETE (confirm);
   7. CLEAR / CREATE with unsaved changes;
   8. functions F4, IMPR_CAR_AGENT (WNRI confirm), IMPR_MCI_SERVICE, IMPR1110_MOB (→ 1112 → mobile written back), IMPR1115_GZT, CREATE_BRKR_IMPR_AUTH.
6. Debug (`&DEBUG.=YES`): every AJAX call returns `{"items":…,"ui":…}` or `{"error":…}`.
