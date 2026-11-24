# CLAUDE.md — Oracle Forms 12c → Oracle APEX 21.2 Migration Project

> Claude Code reads this file automatically when a session starts in this repository.
> Every rule here is **mandatory** unless a prompt explicitly overrides it for a single task.

---

## 1. Project Context

| Item | Value |
|---|---|
| Source technology | Oracle Forms **12c** (12.2.1.x) — `.fmb`, `.pll`, `.olb`, `.mmb` |
| Source format Claude works with | XML produced by `frmf2xml` (`<form>_fmb.xml`), text libraries (`.pld`) |
| Target technology | Oracle APEX **21.2** (release 21.2.x) |
| Database | Oracle Database **12.1.0.2** (exactly). Standard Oracle SQL and PL/SQL only — see §2a |
| Structure | **Forms-mirror** standard — see §4a and `docs/apex_structure_standard.md` |
| Reference application | **f345** — `apex/Reference/f345.sql`. Its templates and naming are mandatory — see §4b and `docs/f345_reference_standard.md` |
| Goal | Re-implement each Form as an APEX page set, moving all business logic into PL/SQL packages in the database |

Claude Code **cannot open `.fmb` files**. Always work from the XML exported by
`scripts/convert_forms_to_xml.sh` (folder `output/xml/`).

---

## 2. Target Version Lock — APEX 21.2 ONLY

Generate only features that exist in APEX 21.2. **Never** use or suggest:

| Do NOT use (introduced later) | Version | Use instead in 21.2 |
|---|---|---|
| `wwv_flow_imp` / `wwv_flow_imp_page` export API | 22.1+ | `wwv_flow_api` |
| Task Definitions / Approvals component, `APEX_APPROVAL` | 22.1 | Custom status table + PL/SQL package |
| "Invoke API" page process type | 22.2 | "Execute Code" (PL/SQL) process calling the package |
| Smart Filters region | 22.2 | Faceted Search (19.2+) or Interactive Report |
| Template Components | 23.1 | Classic Report with custom template / Cards region |
| Workflow component, `APEX_WORKFLOW` | 23.2 | Scheduler jobs + PL/SQL state machine |
| Combobox item type | 23.2 | Popup LOV (multi-select) / Select List |
| AI services, `APEX_AI`, vector search | 24.1+ | Not applicable |
| `apex_page.get_url` extensions / features documented only after 21.2 | — | Check 21.2 API reference before use |

If you are unsure whether a feature exists in 21.2, say so explicitly and propose a
21.2-safe alternative. Export headers must declare
`p_version_yyyy_mm_dd => '2021.10.15'` and `p_release => '21.2.x'`.

---

## 2a. Database Version Lock — Oracle 12.1.0.2 ONLY

All SQL and PL/SQL must compile on **12.1.0.2**. Never use:

| Do NOT use | Introduced | Use instead on 12.1.0.2 |
|---|---|---|
| Identifiers longer than **30 bytes** (tables, columns, packages, procedures, variables, constraints, indexes) | 12.2 | Abbreviate; keep ≤ 30 — check every generated name |
| `LISTAGG ... ON OVERFLOW TRUNCATE` | 12.2 | Plain `LISTAGG` (watch 4000-byte limit) or `XMLAGG` |
| `CAST(... DEFAULT ... ON CONVERSION ERROR)`, `VALIDATE_CONVERSION` | 12.2 | PL/SQL function with exception handler |
| `JSON_OBJECT`, `JSON_ARRAY`, `JSON_OBJECTAGG`, `JSON_ARRAYAGG` (SQL) | 12.2 | `APEX_JSON` package |
| `JSON_OBJECT_T`, `JSON_ARRAY_T`, `JSON_ELEMENT_T` (PL/SQL) | 12.2 | `APEX_JSON` |
| Qualified expressions `t_rec(a => 1, b => 2)` for records / assoc. arrays | 18c | Assign fields one by one |
| Private temporary tables (`ORA$PTT_`), polymorphic table functions | 18c | Global temporary tables / APEX collections |
| SQL macros, `JSON_MERGEPATCH`, `TO_UTC_TIMESTAMP_TZ`, `CHECKSUM` aggregate, `BOOLEAN` in SQL | 18c–23ai | Classic SQL / PL/SQL equivalents |
| `APPROX_PERCENTILE`, `APPROX_*_DETAIL` | 12.2 | Exact functions |

Allowed on 12.1.0.2 (use freely): identity columns, `DEFAULT seq.NEXTVAL`, `DEFAULT ON NULL`,
`FETCH FIRST n ROWS`, `WITH FUNCTION` in SQL, `CROSS/OUTER APPLY`, `LATERAL`,
`JSON_VALUE/JSON_QUERY/JSON_TABLE/IS JSON`, `PRAGMA UDF`, `ACCESSIBLE BY`, `STANDARD_HASH`.

APEX 21.2 supports DB 12.1.0.2 (minimum version). Newer APEX releases (23.1+) need a newer
database — keep this in mind before suggesting an APEX upgrade.

---

## 3. Output Format Rules

1. **SQL / PL/SQL** — plain `.sql` files runnable in SQL*Plus / SQLcl.
   - Start with a header comment (purpose, form, author `Claude Code`, date, version).
   - Use `SET DEFINE OFF` unless substitution variables are intentionally used.
   - Terminate every PL/SQL unit with `/` on its own line.
   - End DDL scripts with `SHOW ERRORS` for each compiled unit.
2. **PL/SQL packages** — always two files: `<pkg>_spec.sql` and `<pkg>_body.sql`, built from
   `plsql_templates/pkg_template_spec.sql` / `_body.sql`:
   - Owner **`LIB_APX_USR`**: `CREATE OR REPLACE PACKAGE LIB_APX_USR.<FORM> AS` /
     `CREATE OR REPLACE PACKAGE BODY LIB_APX_USR.<FORM>`.
   - The spec starts with the version block: `V_PKG_VERSION`, `V_PKG_VERSION_QC`, `V_PKG_VERSION_DEV`
     (`'VERSION NO. IS:' || '001'`), `FUNCTION PKG_VERSION RETURN VARCHAR2`, `V_PACKAGE_NAME`,
     `V_LAST_MODIFY_DT` (`DD-MM-YYYY`), `V_MODIFIED_BY` and `V_INFO`. The body ends with
     `PKG_VERSION` returning `V_INFO`. Raise the version and the date on every change.
   - The spec file ends with `CREATE OR REPLACE PUBLIC SYNONYM <FORM> FOR LIB_APX_USR.<FORM>;` and
     `GRANT EXECUTE ON LIB_APX_USR.<FORM> TO` `LIB_USR`, `SECURITY_DEFAULT`, `SECURITY_PROD` and
     `CUSTOMS` (the APEX parsing schema needs a direct grant, not one through a role).
   - `LIB_APX_USR` needs direct grants on every table and package the code uses (definer rights).
3. **APEX exports** — `f<appid>_<formname>.sql` built with `wwv_flow_api` calls: a **component
   export** into the application built from f345, wrapped in `wwv_flow_api.component_begin` /
   `component_end`, using f345's ID offset and template IDs (§4b). Mark as `-- REVIEW BEFORE IMPORT`.
4. **Analysis & design** — Markdown (`.md`) only. Never leave analysis only in the chat.
5. **Schema changes** — paired scripts: `NNN_<desc>.sql` and `NNN_<desc>_rollback.sql`.
6. Use UTF-8, Unix line endings, 4-space indentation in PL/SQL, UPPERCASE SQL keywords.

---

## 4. Naming Conventions

| Object | Pattern | Example |
|---|---|---|
| Package per form | `<FORM>` — upper-case form name, no prefix (f345) | `AGR1100` |
| Shared/library package | `LIB_<library_name>` | `LIB_COMMON` |
| Standalone procedure | `<VERB>_<OBJECT>` in full words, no prefix | `RECALCULATE_TOTALS` |
| Standalone function | `GET_<OBJECT>` / `<VERB>_<OBJECT>` in full words, no prefix | `GET_DISCOUNT` |
| Local variables | `v_<name>` | `v_customer_id` |
| Parameters of members called from APEX | bind name without `:` and **without** an `I_` / `IO_` / `O_` prefix (the mode is IN / IN OUT / OUT). A page item `P<page>_X` is passed as `P_X` (`P_AGRMNT_NO => :P11100_AGRMNT_NO`); the page item of a Forms parameter `P<page>_P_X` as `P_X` too (no doubled `P_P_`; if the same member also receives the application item `P_X`, that parameter is `APP_P_X`); `P0_PAGE_PK` as `P_PAGE_PK`; application items and IG columns keep their name. Inside SQL a parameter is qualified with its member name (`PRE_DELETE.P_AGRMNT_NO`), because an unqualified name that matches a column resolves to the column. Rule and checks: `scripts/parameter_names.py`. (Project rule of 2026-11-23; f345's AGR1100 still used `I_` / `IO_`.) | `P_AGRMNT_NO`, `MEMBER_ISN`, `SSO_APP_USER`, `P_PAGE_PK` |
| Parameters of internal-only members | `p_<name>` | `p_order_id` |
| Constants | `c_<name>` | `c_status_open` |
| Global (package) variables | `g_<name>` | `g_user_name` |
| Cursors | `cur_<name>` | `cur_order_lines` |
| Records / types | `t_<name>` / `tt_<name>` (collection) | `t_customer_rec` |
| Exceptions | `e_<name>` | `e_credit_limit` |
| Views for APEX | `<FORM>_<BLOCK>_VIEW` | `ORDERS_LINES_VIEW` |
| APEX page items | `P<page>_<FORMS_ITEM_NAME>` (see §4a) | `P120_CUSTOMER_ID` |
| APEX application items | Reuse the f345 item if one exists (`SSO_APP_USER`, `P_CURR_PORT_CD`, …); otherwise `:GLOBAL.X` → `G_X`, cross-page `:PARAMETER.X` → `P_X` (f345 convention). No `AI_` prefix | `G_LAST_PAGE`, `P_AGRMNT_NO` |
| APEX LOVs (shared) | `LOV_<NAME>` | `LOV_COUNTRIES` |
| APEX collections | `COLLECTION_<RECORD_GROUP>` | `COLLECTION_RG_PRICES` |
| Migration scripts | `NNN_<description>.sql` | `001_add_audit_columns.sql` |

Form name = the `.fmb` file name in lower case without extension.
All database identifiers ≤ 30 bytes (DB 12.1.0.2).

**Never abbreviate** object, package, procedure, function, type or APEX component names: write the
full words (`IMPORTERS_PRE_INSERT`, `BUS_ID_WHEN_VALIDATE_ITEM`, `CHECK_ERROR`, `<ITEM>_VALIDATION`,
full block names). This also replaces the abbreviated names of the f345 reference app (`CHK`, `_VAL`).
Only a name that would exceed 30 bytes is shortened: drop `WHEN_` first, then shorten the block part,
and keep the full name in the comment. Original Forms names (program units, items, columns, Forms
trigger names such as `KEY-DELREC`) stay exactly as in Forms; standard acronyms (`UI`, `DML`, `LOV`,
`JSON`, `AJAX`, `APEX`) are allowed. Variable prefixes (`v_`, `p_`, `c_`, `g_`) are not affected.

---

## 4a. Forms-Mirror Structure (MANDATORY)

Goal: a Forms developer must find every Forms object in APEX **by its original name**.
Full rules: `docs/apex_structure_standard.md`. Summary:

| Forms | APEX 21.2 — named / organised as |
|---|---|
| Forms application (main `.mmb`) | One APEX application; Navigation Menu mirrors the menu tree and labels |
| Form module `ORDERS.fmb` | Main page ID from `MIG_FORM_REGISTRY`, name and alias `ORDERS`; search modal page `<main page>01`, name `ORDERS_SEARCH`, alias `ORDERS-SEARCH`; Page Group = Forms subsystem |
| Block `ORDERS` | Region with Static ID `ORDERS`, title = block/canvas title (Arabic), same display order |
| Item `ORDERS.CUSTOMER_ID` | Page item `P<page>_CUSTOMER_ID` (IG column `CUSTOMER_ID`) — keep the Forms item name |
| Duplicate item names across blocks | `P<page>_<BLOCK>_<ITEM>` |
| Trigger `ORDERS.CUSTOMER_ID` WHEN-VALIDATE-ITEM | Dynamic Action `CUSTOMER_ID WHEN-VALIDATE-ITEM` (FOS plug-in: `FORMS_APX.CHECK_ERROR(ORDERS.CUSTOMER_ID_VALIDATION(...))`) + validation `CUSTOMER_ID VALIDATION` (`return ORDERS.CUSTOMER_ID_VALIDATION(...)`) |
| Trigger PRE-INSERT on the master block | Process `PRE-INSERT` calling `ORDERS.PRE_INSERT(...)` |
| Trigger PRE-INSERT on detail block `ORDER_LINES` | Process `ORDER_LINES PRE-INSERT` calling `ORDERS.LINES_PRE_INSERT(...)` |
| UI trigger (WHEN-LIST-CHANGED…) | Dynamic Action `ORDER_TYPE WHEN-LIST-CHANGED` (detail block: `<BLOCK> <ITEM> <TRIGGER>`) |
| Program unit `CALC_TOTAL` | `<FORM>.CALC_TOTAL` (same name) |
| LOV `LOV_CUSTOMERS` / record group `RG_X` | Shared LOV `LOV_CUSTOMERS` / collection `COLLECTION_RG_X` |
| Alert `AL_CONFIRM_DEL` | Text Message `AL_CONFIRM_DEL` (Shared Components) |
| `:GLOBAL.X` / `:PARAMETER.X` | Application Item `G_X` (reuse f345's if it exists) / page item `P<page>_P_X` (+ app item `P_X` when passed between pages) |
| Menu role `CLERK` | Application privileges (no Authorization Scheme generated, §8) |

Rules:
1. Every APEX component's **Comments** attribute = `Source: <FORM>.<BLOCK>.<ITEM>.<TRIGGER>`.
2. Package member names (full words, see §4): master-block trigger `PRE_INSERT`, detail block
   `<BLOCK>_PRE_INSERT`, validation function `<ITEM>_VALIDATION` (returns error text), side-effect
   procedure `<ITEM>_WHEN_VALIDATE_ITEM`; all ≤ 30 bytes. Details: `docs/f345_reference_standard.md` §5.
3. Use `FORMS_APX` (Forms-like server built-ins: `message`, `FORM_TRIGGER_FAILURE`, `alert`, `get_global`, …)
   so converted code reads like the original trigger code. **Common helpers live only in `FORMS_APX`**
   (version 004, user decision 2026-11-24): `CHECK_ERROR`, `REQUIRED_VALIDATION`, `GET_MODULE_ID(P_MODULE_ID,
   FORM_NAME)`, `HEADER_TITLE(P_MODULE_ID, P_HERO_TITLE, DEFAULT_TITLE)`, `ROWID_FROM_URL`, `HIJRI_DATE_FORMAT`,
   `HIJRI_TEXT_TO_DATE`, `HIJRI_TEXT`, `HIJRI_DATE_ERROR`, `CUR_HIJ_DATE`, `ARABIC_MESSAGE`,
   `DISPLAY_ARABIC_ERROR` / `_INFO`, `CG_MESSAGE`. A form package never defines its own copy (or a one-line alias
   of a `FORMS_APX` built-in); it calls `FORMS_APX.<NAME>`, and pages call them directly
   (`FORMS_APX.CHECK_ERROR(<FORM>.<ITEM>_VALIDATION(...))`). Form-specific helpers (key check, activity log)
   stay in the form package. Check: `scripts/forms_apx_helpers.py` (`leftovers`, `unknown_calls`).
4. Register every form and every mapped object in `MIG_FORM_REGISTRY` / `MIG_OBJECT_MAP`
   (`scripts/create_migration_registry.sql`) — produce the INSERT script per form.
5. Standard buttons come from the **page 0 toolbar** of f345 (`CREATE` · `SAVE` · `DELETE` ·
   `SEARCH` · `CLEAR` · `FUNCS` / `REPORT_SHOW` · `REPORT_PRINT` · `BACK`). Form pages do **not**
   define their own copies; they keep the current record key in `P0_PAGE_PK` and handle the
   requests `CREATE`, `SAVE` and `DELETE`.

---

## 4b. f345 Reference Application (MANDATORY for every APEX export)

`apex/Reference/f345.sql` is the target application's shell: theme 42 (style **ZATCA Forms**,
RTL, `ar-sa`), page 0 toolbar, login, plug-ins, application items and app processes.
Full rules with every template ID: **`docs/f345_reference_standard.md`**. Summary:

1. Generate component exports **into** this application. Never regenerate its shared components
   (theme, templates, page 0, plug-ins, existing application items).
2. Copy template IDs exactly from f345 (`wwv_flow_api.id(<n>)`), with the same
   `p_default_id_offset` as the installed target app (f345: `64111868204433090374`).
   No `__TEMPLATE_ID_*__` placeholders.
3. Main page: name/alias `<FORM>`, page template *Zatca-Minimal_No_Navigation*
   (`11622270914969205733`), `p_step_title=>'&SYS_ANAME.'`, CSS class `zf`, protection `C`.
   Search page `<main page>01`, modal 1800×800. Page 0 finds the search page by that number.
4. Regions: master block = Form region with template *Interactive Report*
   (`11621909206693869707`) and classes `zatca-forms cg-form cg-card`; detail blocks = IG with
   template *Standard* (`11621913486616869708`), `t-Region--noPadding`, `cg-card cg-grid`.
   Items: *Required - Above* / *Optional - Above* with `t-Form-fieldContainer--stretchInputs`.
5. Processes, validations and DAs use space-separated Forms trigger names (`PRE-INSERT`,
   `AGRMNT_MEMBERS PRE-UPDATE`, `CTRY_CD WHEN-VALIDATE-ITEM`, `CTRY_CD VALIDATION`), each a
   one-line call into `<FORM>`, following the process order in the standard doc §6.
6. If f345 and `docs/apex_structure_standard.md` disagree, f345 wins.

---

## 4c. Declarative APEX, readable PL/SQL (MANDATORY)

Full rules: `docs/f345_reference_standard.md` §9 and §10. Summary:

1. **Declarative first.** Item triggers become a validation plus a DA built from the FOS plug-in
   (*Execute PL/SQL Code*, Items to Submit / Return) and native actions (Enable/Disable, Show/Hide,
   Set Value, Set Focus, Confirm, Refresh). Read-only and required rules are APEX conditions that call
   BOOLEAN package functions (`<ITEM>_IS_READ_ONLY`, `<ITEM>_IS_REQUIRED`).
2. **Minimal JavaScript.** No JavaScript file per form, no AJAX-callback "engine", no client-side UI
   state. An *Execute JavaScript Code* action may have at most 3 lines; anything more needs a reason in
   the page spec and the user's approval. Number Field items get the CSS class `number_only`, and editable grid number columns (Text / Number Field
   on NUMBER data) get it as column CSS class; the page has one DA `NUMBER ONLY` (Page Load, one-line
   *Execute JavaScript Code*, `scripts/number_only.py`): while typing or pasting only digits stay (Arabic-Indic digits
   become 0-9); user request 2026-11-24. f345 has no class-based handler (FTEX.js `pageItemOnlyNumber` is per item).
3. **One readable package per form.** No adapter packages and no all-items record copied through
   session state: each member takes only the items it uses (IN / IN OUT parameters named by §4). Fixed section order
   (version → helpers → form level → each block: query, record, items in navigation order, DML,
   buttons → program units → private helpers → UI comments). One Forms trigger = one member,
   about 80 lines at most.

---

## 5. Key Mapping (Forms → APEX 21.2)

Full reference: `docs/forms_to_apex_mapping.md`.

| Oracle Forms | APEX 21.2 equivalent |
|---|---|
| Form module | Application page(s) (one main page + modal dialogs) |
| Menu module (`.mmb`) | Navigation Menu (list); roles → application privileges (§8) |
| Data block (single record) | Form region (native Form, 19.1+) |
| Data block (multi record, editable) | Interactive Grid |
| Data block (multi record, read-only) | Interactive / Classic Report |
| Master–detail relation | Master-Detail page (Form + IG, or IG + IG) |
| Control block (non-base-table) | Static Content region with page items |
| Canvas (content) | Page / region |
| Tab canvas | Region Display Selector or Tabs Container template |
| Stacked canvas / popup window | Inline Dialog or Modal Dialog page |
| LOV + Record Group | Shared Component LOV / Popup LOV / Select List |
| Record Group (runtime) | `APEX_COLLECTION` |
| Alert | Native Confirm action / `apex_error` / page message (JavaScript only as a one-line exception, §4c) |
| Parameter list / `:PARAMETER` | Page items set via URL (`apex_page.get_url`) |
| `:GLOBAL.*` | Application Items |
| Program unit | Package procedure/function in `<FORM>` |
| PL/SQL library (`.pll`) | Shared database package `LIB_<name>` |
| Object library (`.olb`) | Theme templates, Shared Components, Template Options |
| Visual attributes | Template Options / CSS classes |
| WHEN-VALIDATE-ITEM | Validation (item-level) |
| WHEN-VALIDATE-RECORD | Validation (page/row-level) |
| PRE-INSERT / PRE-UPDATE / PRE-DELETE | Process before Automatic Row Processing, or IG/Form custom DML |
| POST-QUERY | SQL in view / computed column, or After Header computation |
| WHEN-NEW-FORM-INSTANCE | Before Header process / computations |
| WHEN-BUTTON-PRESSED | Button + Process or Dynamic Action |
| WHEN-LIST-CHANGED / WHEN-RADIO-CHANGED | Dynamic Action (Change) |
| KEY-* triggers | Page 0 toolbar buttons / page buttons (no keyboard-shortcut scripts) |

---

## 6. Rules Claude Code MUST Follow

1. **Never alter the schema without a migration script.** No ad-hoc `ALTER`/`CREATE TABLE`.
   Every DDL change goes into `migration/NNN_<desc>.sql`.
2. **Always produce a rollback script** (`migration/NNN_<desc>_rollback.sql`) for every
   migration script, and for every package (keep the previous version under `rollback/`).
3. **One form per session.** Do not analyse or convert more than one form in a single
   Claude Code session. Start a new session (`/clear`) for the next form.
4. **Save analysis as Markdown** in `analysis/<form_name>/`. Every step writes its result to a file.
5. **Business logic lives in the database.** APEX pages call `<FORM>` package procedures;
   no business logic duplicated in page-level anonymous blocks longer than ~5 lines.
6. **Preserve behaviour first, improve second.** Flag improvements as `-- SUGGESTION:` comments;
   do not silently change business rules.
7. **Never invent missing code.** If a trigger references a program unit or library not
   present in the XML, mark it `-- TODO: MISSING SOURCE <name>` and list it in the inventory.
8. **Mark UI-only logic** as `-- APEX-DA:` comments (to become Dynamic Actions), not PL/SQL.
9. **Bind variables only** — never concatenate user input into dynamic SQL; use
   `DBMS_ASSERT` for unavoidable identifiers.
10. **Do not run DDL/DML against any database** unless the user explicitly asks in that session.
11. **Cite the source.** Every generated procedure includes a comment naming the Forms
    trigger/program unit it came from (`-- Source: BLOCK.ITEM.WHEN-VALIDATE-ITEM`).
12. Keep file sizes manageable: read large XML files in chunks (grep for
    `<Trigger`, `<Block`, `<Item`, `<ProgramUnit`) rather than loading them whole.

---

## 7. Forms Built-ins to Avoid → APEX Replacements

Forms built-ins **must not appear** in generated PL/SQL (they do not exist in the database).

| Forms built-in | APEX 21.2 replacement |
|---|---|
| `MESSAGE('...')` | `apex_application.g_print_success_message` / Success Message of process |
| `SHOW_ALERT` / `SET_ALERT_PROPERTY` | Native Confirm action, `FORMS_APX.CHECK_ERROR` / `apex_error.add_error` |
| `RAISE FORM_TRIGGER_FAILURE` | `apex_error.add_error(...)` or `raise_application_error(-20xxx, ...)` |
| `GO_BLOCK` / `GO_ITEM` / `GO_RECORD` | Native DA action "Set Focus" / region navigation |
| `NEXT_RECORD` / `PREVIOUS_RECORD` | IG navigation, or Form region "Next/Previous" buttons |
| `EXECUTE_QUERY` | Region refresh (DA "Refresh") / page submit |
| `ENTER_QUERY` | Faceted Search, IR/IG search, or filter page items |
| `COMMIT_FORM` / `DO_KEY('COMMIT_FORM')` | Page submit + Automatic Row Processing (APEX commits) |
| `CLEAR_FORM` / `CLEAR_BLOCK` | "Clear Cache" on branch / DA "Clear" |
| `SET_ITEM_PROPERTY(..., ENABLED/VISIBLE)`, `Make_Field_Entrable` | Item Read Only condition (`<FORM>.<ITEM>_IS_READ_ONLY`), native DA Enable/Disable / Show/Hide, server-side conditions |
| `SET_ITEM_PROPERTY(..., REQUIRED)` | Validation `<ITEM> REQUIRED` with a server-side condition (`<FORM>.<ITEM>_IS_REQUIRED`) — see `plsql_templates/dynamic_action_patterns.sql` |
| `SET_BLOCK_PROPERTY(..., DEFAULT_WHERE)` | Region SQL with bind filters on page items |
| `GET_ITEM_PROPERTY` | Read item value via `:P1_ITEM` / `apex_util.get_session_state` |
| `CALL_FORM` / `OPEN_FORM` / `NEW_FORM` | Branch / link to page, Modal Dialog page, `apex_page.get_url` |
| `CREATE_RECORD_GROUP` / `POPULATE_GROUP` | `apex_collection.create_collection_from_query_b` |
| `GET_GROUP_CHAR_CELL` etc. | `SELECT c001 ... FROM apex_collections WHERE collection_name = ...` |
| `HOST` / `WEB.SHOW_DOCUMENT` | `DBMS_SCHEDULER` job / URL redirect / `apex_util.redirect_url` |
| `RUN_REPORT_OBJECT` (Reports) | BI Publisher / Report Query / PL/PDF / APEX Office Print (flag for decision) |
| `TEXT_IO` / `CLIENT_TEXT_IO` | File Browse item + `apex_application_temp_files`, `UTL_FILE` |
| `SYNCHRONIZE` | Not needed |
| `:SYSTEM.CURSOR_ITEM`, `:SYSTEM.MODE` etc. | See mapping doc (§System Variables) |
| `USER` / `GET_APPLICATION_PROPERTY(USERNAME)` | `:APP_USER` / `v('APP_USER')` (not DB `USER`) |
| `DEFAULT_VALUE`, `COPY`, `NAME_IN` | Item Default, `apex_util.set_session_state`, `v('ITEM')` |

---

## 8. Security Rules

- **No hardcoded credentials** anywhere: no passwords, wallet passwords, API keys, or
  connect strings in code, comments, or Markdown. Use SQL*Plus substitution variables
  (`&password`), Web Credentials, or DBA-managed wallets.
- Authentication: APEX Authentication Schemes (DB accounts / LDAP / SSO). Never port
  custom Forms login screens that compare plaintext passwords.
- Authorization: **do not generate Authorization Schemes** for pages, buttons or menu entries.
  Who may open a page is controlled by the application's existing privileges (f345 login /
  user privileges, decision 2026-11-18); function rights come from the f345 *Page Functions*
  list. Record the Forms menu roles / `SET_MENU_ITEM_PROPERTY` logic in the page spec so the
  privilege administrators can grant them. Add a scheme only if the user asks for one.
- Use `:APP_USER` for auditing, not `USER` (the parsing schema).
- Escape output: keep "Escape special characters" = Yes on report columns; use
  `apex_escape.html` in PL/SQL-generated HTML.
- Session State Protection: enable on pages; items set via URL must use checksums.
- Least privilege: the parsing schema gets only object grants it needs.

---

## 9. Expected Output File Structure

```
forms_to_apex_toolkit/
├── CLAUDE.md
├── input/fmb/                      # original .fmb/.pll/.olb (read-only, not edited)
├── output/xml/                     # frmf2xml output (<form>_fmb.xml)
├── analysis/<form_name>/
│   ├── <form_name>_inventory.md            # step 01
│   ├── <form_name>_logic_extraction.md     # step 02
│   ├── <form_name>_apex_page_spec.md       # step 03
│   └── <form_name>_review_notes.md
├── plsql/<form_name>/
│   ├── <form_name>_spec.sql                # step 02 (package <FORM>)
│   └── <form_name>_body.sql                # step 02
├── apex/Reference/f345.sql         # reference application (templates + naming, §4b)
├── apex/<form_name>/
│   └── f<appid>_<form_name>.sql            # step 04 (REVIEW BEFORE IMPORT)
├── registry/<form_name>_registry.sql       # step 03: INSERTs into MIG_FORM_REGISTRY / MIG_OBJECT_MAP
├── tests/<form_name>/
│   ├── test_<form_name>.sql                # step 05 (utPLSQL package TEST_<FORM>)
│   ├── uat_checklist_<form_name>.md
│   └── data_compare_<form_name>.sql
├── migration/
│   ├── NNN_<desc>.sql
│   └── NNN_<desc>_rollback.sql
├── rollback/                       # previous package versions
├── prompt_templates/               # prompts 01–05
├── plsql_templates/                # package + DA pattern templates
├── scripts/                        # helper scripts
└── docs/                           # checklist, mapping, getting started
```

---

## 10. Workflow per Form (summary)

1. `prompt_templates/01_inventory_analysis.md` → inventory + risk assessment
2. `prompt_templates/02_logic_extraction.md` → package `<FORM>` spec/body
3. `prompt_templates/03_apex_page_design.md` → page spec
4. `prompt_templates/04_apex_export_generation.md` → APEX export (review before import)
5. `prompt_templates/05_test_generation.md` → utPLSQL, UAT, data compare

Before finishing any step: list the files written, open TODOs, and assumptions made.
