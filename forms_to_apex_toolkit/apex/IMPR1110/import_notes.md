# IMPR1110 – Import notes (Step 04, f345 standard)

> ⚠️ **REVIEW BEFORE IMPORT.** `f345_impr1110.sql` is generated `wwv_flow_api` code. This is
> **not** an officially supported way to build APEX applications. Import it into a **DEV**
> workspace only, export (back up) the target application first, and open every page in Page
> Designer after the import.

| Item | Value |
|---|---|
| Form | IMPR1110 – "إضافة وتعديل بيانات مستورد" |
| Standard | f345 reference application (`apex/Reference/f345.sql`), `CLAUDE.md` §4b, `docs/f345_reference_standard.md` |
| Input | `analysis/IMPR1110/IMPR1110_apex_page_spec.md` (step 03) |
| Generator | `python3 -I scripts/gen_apex_impr1110.py`. Re-run it after a spec change; do not edit the `.sql` by hand |
| Files | `apex/IMPR1110/f345_impr1110.sql` (export), `apex/IMPR1110/impr1110.js` 1.1.0 (static file), `plsql/IMPR1110/impr1110_spec.sql` + `impr1110_body.sql` (package `IMPR1110`), this file |
| Replaces | `f2000_impr1110.sql` (removed; still in git history) and the previous notes (`rollback/IMPR1110/import_notes_v1.md`) |
| Status | Generated 2026-11-18. **Not imported, not compiled, JavaScript not run** (no `node` on the build machine, so not even syntax-checked). |

## 1. What changed compared with the previous export

| Topic | Before (f2000) | Now (f345 standard) |
|---|---|---|
| Target | any application, `__TEMPLATE_ID_*__` and `__USER_INTERFACE_ID__` placeholders | the application installed from f345; real f345 template and UI ids, `__ID_OFFSET__` |
| Pages | 1110, 1111 (search), 1112 (mobile) | **1110** `IMPR1110`, **111001** `IMPR1110_SEARCH`, **111002** `IMPR1110_MOBILE` |
| Page template | Standard | **Zatca-Minimal_No_Navigation** (main), theme default Modal Dialog (modals); CSS class `zf`, title `&SYS_ANAME.` |
| Toolbar | 7 buttons on page 1110 | **none on the page**: page 0 `CREATE` · `SAVE` · `DELETE` · `SEARCH` · `CLEAR` · `FUNCS` · `BACK` |
| Record key | `P1110_IMPR_NBR` only | `P0_PAGE_PK` (= `IMPR_NBR`) drives the toolbar; processes `P0_PAGE_PK CHECK`, `P0_PAGE_PK`, `P0_PAGE_PK AFTER INSERT/DELETE` |
| Search | IR dialog, closed with `{IMPR_NBR}` | IG page 111001 (opened by page 0 `SEARCH`), link column → `f?p=…:1110:…:P0_PAGE_PK:&PK.` (as AGR1100) |
| Functions | list `LIST_IMPR1110_FUNS` + 11 `FUN_*` schemes (all FALSE) | inline dialog `FUNCS` with the f345 list **Page Functions** (rights from `SC_SYSOBJ_ROLE_PRIVS`); one custom-event DA per function code |
| PL/SQL called by the pages | `pkg_impr1110_apx.*` | **`IMPR1110.*` only**: package `IMPR1110` holds the logic and the APEX entry points; it uses the session-state adapter `IMPR1110_APX` |
| Component names | `IMPORTERS.BUS_ID.WHEN-VALIDATE-ITEM` | `BUS_ID VALIDATION`, `BUS_ID WHEN-VALIDATE-ITEM`, `ON-INSERT`, `WHEN-NEW-FORM-INSTANCE` |
| Application items | 37 `AI_*` | f345 items reused (`P_CURR_PORT_CD`, `P_CLASS_CD`, `P_PORT_TYPE`, `P_BRKR_NBR`, `SSO_APP_USER`, `V_USR_TYPE`, `P_GLOBAL_V_WS_ID`); new: 28 × `G_<GLOBAL>` + `P_BRKR_PORT_CD`, `P_LIC_TYPE`, `P_PRSNL_IMPR`, `P_LETTER_NBR` |
| Authorization | 13 schemes | **none**: page access comes from the application's own privileges (§6) |

## 2. Placeholders

The script has `set define off`. Replace the four tokens before the import:
`sed -i '' 's/__APP_ID__/345/g; s/__WORKSPACE_ID__/<id>/g; s/__SCHEMA_NAME__/CUSTOMS/g; s/__ID_OFFSET__/<offset>/g' f345_impr1110.sql`

| Token | Value | How to get it |
|---|---|---|
| `__WORKSPACE_ID__` | workspace id | `SELECT workspace_id FROM apex_workspaces WHERE workspace = '<NAME>';` |
| `__APP_ID__` | id of the application installed from f345 (f345 itself: 345) | App Builder |
| `__SCHEMA_NAME__` | parsing schema (f345: `CUSTOMS`) | `SELECT owner FROM apex_applications WHERE application_id = <APP_ID>;` |
| `__ID_OFFSET__` | ID offset of the installed application (f345 export: `64111868204433090374`) | `SELECT template_id - 11621850520475869674 FROM apex_application_temp_page WHERE application_id = <APP_ID> AND template_name = 'Standard';` |

**The offset must be right.** Every template, the user interface, the page 0 toolbar region and
the *Page Functions* list are referenced as `wwv_flow_api.id(<f345 number>)`. They resolve only if
`__ID_OFFSET__` equals the offset of the installed application. Do **not** import with
`apex_application_install.generate_offset`.

Check: `grep -n '__[A-Z_]*__' f345_impr1110.sql` must print nothing.

## 3. Prerequisites

1. Compile **as `LIB_APX_USR`** (every package is created as `LIB_APX_USR.<name>`), in this order. Each
   spec file ends with its public synonym and the EXECUTE grants to `LIB_USR`, `SECURITY_DEFAULT`,
   `SECURITY_PROD` and `CUSTOMS` (the parsing schema: APEX needs a direct grant). Run those as a user
   allowed to create public synonyms. `SELECT <package>.PKG_VERSION FROM dual` shows the version.
   None of them has been compiled yet:
   1. `plsql_templates/forms_compat.sql` (package `FORMS_COMPAT`, was `pkg_forms_compat`): `:GLOBAL.X` is application item `G_X`.
   2. `plsql/IMPR1110/impr1110_spec.sql` (package `IMPR1110`: the logic, formerly `pkg_impr1110`, plus the
      APEX entry points, formerly the separate package `IMPR1110`).
   3. `plsql/IMPR1110/impr1110_apx_spec.sql` (package `IMPR1110_APX`, was `pkg_impr1110_apx`). Its spec uses
      the record types of `IMPR1110`, so it comes after step 2.
   4. `plsql/IMPR1110/impr1110_body.sql`, then `impr1110_apx_body.sql`. Each body calls the other package, so
      both specs must exist first.
   Previous versions: `rollback/IMPR1110/*_before_rename.sql`, `rollback/COMMON/pkg_forms_compat_before_rename.sql`.
2. Grants, given **directly** (not through a role) to `LIB_APX_USR`, because the packages are definer-rights:
   SELECT, INSERT, UPDATE, DELETE on `IMPORTERS`; SELECT on `IMPR_TYPES`, `IMPR_TYPE_ID_TYPES`, `BUS_ID_TYPES`,
   `CITIES`, `COUNTRIES`, `SD_PORTS`, `CG_REF_CODES`, `SC_SYSTEM_OBJECTS`; EXECUTE on `LIB_USR.ACTIVITY_DB` and
   `LIB_USR.HIJDATE_DB` (sources in `plsql/Shared/`; `ACTIVITY_DB` is not yet granted to `LIB_APX_USR`), `STR_DB` and the other
   libraries the package calls. The LOVs and the search page run as `CUSTOMS`, which needs SELECT on the same tables.
3. Upload `impr1110.js` (and a minified `impr1110.min.js`) as Static Application Files. The page references `#APP_FILES#impr1110#MIN#.js`.
4. Nothing else is needed in the application. Error handling (`APP_ERROR_HANDLER`), RTL / Arabic, login, `After Auth` (fills `P_CURR_PORT_CD`, `SSO_APP_USER`, …) and the page 0 toolbar all come from f345.

## 4. Import

```
sql __SCHEMA_NAME__@<tns> @apex/IMPR1110/f345_impr1110.sql
```
or App Builder → Import → File Type **"Page or Component Export"**. Pages 1110, 111001 and 111002 are
removed first (`remove_page`), so a re-import is safe. Shared components keep their ids. A
component with the same name but another id makes the import fail: delete or rename it first.

## 5. Deviations from the f345 standard (on purpose)

| # | Deviation | Why |
|---|---|---|
| 1 | Item triggers run through `impr1110.js` + the AJAX callbacks `IMPR1110_ITEM / _CONFIRM / _FUN`, not through the FOS *Execute PL/SQL* plug-in | the Forms triggers ask Confirm questions (alert 9-120, WNRI, UPD_IMPR) between server calls and change enable/required state of many items; the FOS plug-in cannot do that. The DA **names** follow f345 (`<ITEM> WHEN-VALIDATE-ITEM`) |
| 2 | Master block `IMPORTERS` is a Static region (template *Interactive Report*, classes `zatca-forms cg-form cg-card`), not `NATIVE_FORM` | DML is done in the package (`ON-INSERT` / `ON-UPDATE` / `KEY-DELREC` → `page_dml`), with the Forms PRE/POST logic in between |
| 3 | DML processes are named `ON-INSERT` / `ON-UPDATE` instead of separate `PRE-INSERT` / `Process form` / `POST-INSERT` | one call runs PRE → DML → POST in the order of the Forms commit (`IMPR1110_APX.page_dml`) |
| 4 | Forms parameters keep the item names `P1110_PRSNL_IMPR` / `P1110_LETTER_NBR` (standard: `P1110_P_<PARAM>`) | `IMPR1110_APX` reads these names; renaming is a step-02 change |
| 5 | `IMPR1110.<ITEM>_VALIDATION` ignores its `I_` parameter | the adapter reads the whole record from session state; the parameter documents the item |
| 6 | Page 111002 sets `:G_LAST_PAGE := 1110` (process `G_LAST_PAGE KEEP`, After Header) | f345 `SCREEN ENTRY RESET` keeps the record only for `<page>` and `<page>01`. Without it, the next load of page 1110 after the mobile dialog would clear `P0_PAGE_PK` and the record |
| 7 | No `P1110_ADJ_FUNS` item | the *Page Functions* list then shows every function the user's roles allow. Functions that the form switches off (TMPLT.DISABLE_FUN) are refused at click time by `impr1110.js` (`funOff`) |

## 6. Security (must be done before any user test)

* No authorization scheme is generated (decision 2026-11-18): who may open pages 1110 / 111001 / 111002 is controlled by the application's existing privileges. If `IMPR1110_ACCESS` is still in app 202530 from an earlier import, re-import the pages (they no longer reference it) and delete it in Shared Components → Authorization Schemes.
* Function rights now come from f345 *Page Functions* (`SC_SYSOBJ_ROLE_PRIVS`, `SC_USER_ROLES`, `SC_GROUP_ROLES`, `SC_USER_EXCLUDED_ROLES`).
* Session State Protection: pages `C`; server items `I`; `P111002_IMPR_NBR` `S`; all new application items *Restricted*.

## 7. Open points / TODO-VERIFY

| # | Point | Effect | Next step |
|---|---|---|---|
| 1 | Function custom-event names = function codes (`IMPR1110F1` … `IMPR1110_MOB`). The list fires `SC_SYSTEM_OBJECTS.SYS_OS_FILE_NAME` | if the file names differ (for example `IMPR1110F1.fmx`), the click shows nothing | `SELECT sys_os_file_name FROM sc_system_objects WHERE mainsysobj_id = <IMPR1110 id>` and rename the DAs |
| 2 | Menu-parameter mapping in `IMPR1110_APX.ai()`: `P_USER_ID` → `SSO_APP_USER`, `P_WS_ID` → `P_GLOBAL_V_WS_ID` | wrong user id / workstation in the Forms logic | confirm with the Forms menu `CIC_MENU` |
| 3 | `P_BRKR_PORT_CD`, `P_LIC_TYPE` are new and **nobody fills them** (f345 `After Auth` does not) | broker logic sees NULL | add them to f345 `After Auth` |
| 4 | Callers must set `P_PRSNL_IMPR` / `P_LETTER_NBR` (server side) before opening page 1110 | otherwise the page opens without them, like Forms without parameters | change the callers when they are converted |
| 5 | `&SYS_ANAME.` (page title) is not set by this export | browser tab title is empty if no other code sets it | check how f345 fills `SYS_ANAME` |
| 6 | `apexbeforepagesubmit` + `apex.event.gCancelFlag` used to stop CREATE / SAVE for the PRE-INSERT confirm and invalid items | if it does not cancel in 21.2, the record is saved without the question (the server still validates) | UAT step 5.4 |
| 7 | Page SUPPORT_ENTRY (IMPR1110F1/F2/F3/F5) not generated | those functions show "لم تُنشأ بعد" | convert `forms/SC/Support_Entry_fmb.xml` as `<page>02` |
| 8 | `registry/IMPR1110_registry.sql` (step 03) still lists pages 1111 / 1112 and the old component names | registry out of date | regenerate in a step-03 revision |
| 9 | Items carried from the previous notes: Popup LOV *Manual Entry*, Display Only *Send On Page Submit*, layout spans, Hijri date entry (spec §16 Q5), FRM-40202 texts | see `rollback/IMPR1110/import_notes_v1.md` §5 / §7 | Page Designer review |

## 8. Post-import checklist

1. Page Designer on 1110, 111001, 111002: no "invalid template" warnings, and the hero / form / dialog regions show the f345 look.
2. The page 0 toolbar on 1110 shows `CREATE` · `SEARCH` · `CLEAR` · `FUNCS` · `BACK` for a new record, and `SAVE` · `DELETE` · `CLEAR` · `FUNCS` · `BACK` for a queried one. It is hidden inside both dialogs.
3. Utilities → Advisor on the three pages.
4. Shared Components: 13 LOVs return rows for a sample port; 32 new application items are *Restricted*; none duplicates an f345 item.
5. UAT paths:
   1. open the page (WHEN_NEW_FORM_INSTANCE, PORT_CD disabled);
   2. `SEARCH` → 111001 → search by name / number → click the number → page 1110 shows the importer, toolbar switches to SAVE / DELETE;
   3. change each validated item (AJAX error inline, focus stays);
   4. `CLEAR` → new record → `CREATE` (PRE-INSERT confirm for class 1 / user type 3, number message, toolbar switches to SAVE);
   5. update → `SAVE`;
   6. `DELETE` (page 0 confirm) → empty record, toolbar back to CREATE;
   7. `FUNCS` → each function (F4, IMPR_CAR_AGENT, IMPR_MCI_SERVICE, IMPR1110_MOB → 111002 → mobile written back, then `SAVE` keeps the record: deviation 6), IMPR1115_GZT, CREATE_BRKR_IMPR_AUTH.
6. Debug (`&DEBUG.=YES`): every AJAX call returns `{"items":…,"ui":…}` or `{"error":…}`.
