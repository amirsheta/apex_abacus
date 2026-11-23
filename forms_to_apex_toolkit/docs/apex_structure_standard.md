# APEX Structure Standard — "Forms-Mirror" on the f345 reference application

Target: APEX 21.2 on Oracle Database 12.1.0.2.
Purpose: organise APEX so it looks like the original Forms application. A developer who knows
the `.fmb` can find every block, item, trigger, LOV and alert in APEX **by the same name**, so later
changes are as easy as in Forms Builder.

The concrete rules (template IDs, ID offset, process order, page 0 toolbar) come from the reference
application **f345** (`apex/Reference/f345.sql`) and are listed in **`docs/f345_reference_standard.md`**.
This document explains the structure; where the two differ, the f345 standard wins.

---

## 1. Applications and workspaces
| Forms | APEX |
|---|---|
| One Forms application (main `.mmb` + its forms) | One APEX application **installed from f345**: theme 42 (style *ZATCA Forms*, RTL, `ar-sa`), page 0 toolbar, login, plug-ins, application items and app processes come with it |
| Several Forms applications | One workspace with one application per Forms application, each installed from f345, sharing one parsing schema |
| Shared `.pll` / `.olb` | DB packages `LIB_<name>`; the `.olb` look is already in f345 (templates, CSS classes `zf`, `cg-*`, `zatca-forms`) |

Generated exports are **component exports into that application** (`wwv_flow_api.component_begin`
with the application's ID offset). They never re-create f345's shared components.

## 2. Pages — main page + `<page>0n` child pages
- The main page number comes from `MIG_FORM_REGISTRY` (example: AGR1100 → 11100, IMPR1110 → 1110).
- Child pages are numbered after the main page:

  | Page | Use |
  |---|---|
  | `<page>` (e.g. 11100) | Main page = main content canvas. Template *Zatca-Minimal_No_Navigation* |
  | `<page>01` (e.g. 1110001) | **Search page** (Enter Query / Execute Query). The page 0 SEARCH button opens exactly this number |
  | `<page>02` … `<page>09` | Other modal dialogs: stacked canvases, popup windows, called LOV forms |

- Page **Name** and **Alias** = form name (`AGR1100`); search page `<FORM>_SEARCH` / `<FORM>-SEARCH`;
  other dialogs `<FORM>_<CANVAS>`. **Title** = `&SYS_ANAME.`. **CSS class** = `zf`. Protection `C`.
- Page **Group** = Forms subsystem or menu group. It works like folders in App Builder.
- Page **Comments** = `Source: ORDERS.fmb (window WIN_MAIN, canvas CV_MAIN)`.
- Page 0 (Global Page) is f345's: toolbar region `P0_ACTIONS`, confirm dialog `ASK_DLG`, items
  `P0_PAGE_PK` (key of the open record), `P0_SEARCH_URL`. Do not add form logic to it.
- f345's app process `SCREEN ENTRY RESET` clears `P0_PAGE_PK` and the page items when the user comes
  from another screen. It keeps them only between `<page>` and `<page>01`. A dialog `<page>02…09`
  therefore needs a process `G_LAST_PAGE KEEP` (After Header, `:G_LAST_PAGE := <page>;`).

## 3. Regions = blocks
| Forms | APEX region | f345 template / classes |
|---|---|---|
| Base-table block, single record | Form region | *Interactive Report* template, `zatca-forms cg-form cg-card` |
| Base-table block, multi record | Interactive Grid | *Standard*, `#DEFAULT#:t-Region--noPadding`, `cg-card cg-grid` |
| Read-only block | Interactive Grid (read-only) or Interactive Report | *Standard*, `cg-card cg-grid` |
| Control block | Static Content region (`CONTROL` block → Static ID `CONTROL`) | *Blank with Attributes* |
| Tab canvas | "Tabs Container" region; each tab page = sub-region whose Static ID is the tab page name | *Tabs Container* |
| Stacked canvas | Inline Dialog region, or a modal page `<page>02…09` | *Inline Dialog* |
| Screen header | Hero region with the screen title (process `HEADER TITLE`) | *Blank with Attributes*, `cg-hero` |
| Function side menu (TMPLT / LSIDE) | Inline Dialog `FUNCS` with the f345 list *Page Functions* | *Inline Dialog*, `cg-funcs` |

Rules:
- Region **Static ID** = Forms block name (UPPERCASE). JavaScript and DAs refer to the region by this ID,
  like `GO_BLOCK('ORDERS')`.
- Region **Title** = block prompt / frame title (Arabic). **Sequence** = Forms block navigation order × 10.
- Region **Comments** = `Source: ORDERS.<BLOCK>`.
- Master-detail relation → the detail IG's "Master Region" = master region. Relation name goes in Comments.

## 4. Items = Forms items (keep the name)
- Page item = `P<page>_<FORMS_ITEM_NAME>`, e.g. `ORDERS.CUSTOMER_ID` → `P120_CUSTOMER_ID`.
- IG column name = Forms item name, e.g. `LINES.QTY` → column `QTY` in IG `LINES`.
- Two blocks on one page have the same item name → `P<page>_<BLOCK>_<ITEM>` (e.g. `P120_HEADER_STATUS`).
- Forms parameter → `P<page>_P_<PARAM>`; when a caller passes it, also application item `P_<PARAM>`
  (copied by process `PARAMETERS ENTRY`).
- Item **Label** = Forms prompt. **Sequence** = Forms item order (tab order) × 10. Label template
  *Required - Above* / *Optional - Above*, options `#DEFAULT#:t-Form-fieldContainer--stretchInputs`.
- Item type follows Forms: Text Item → Text/Number/Date; List Item → Select List; Check Box → Checkbox/Switch;
  Radio Group → Radio Group; Display Item → Display Only; non-displayed → Hidden (Value Protected = Yes).
- Format mask, max length and required flag are copied from the Forms item properties.
- Every main page has `P<page>_MODULE_ID` (kept by SCREEN ENTRY RESET, used by the function list).

## 5. Triggers = named APEX components + named package members
The package is named after the form: **`ORDERS`** (upper case, no prefix). APEX component names use
the Forms trigger name, space separated: `<TRIGGER>` for the master block, `<BLOCK> <TRIGGER>` for a
detail block, `<ITEM> <TRIGGER>` for item triggers.

| Forms trigger | APEX component (name) | Package member (`ORDERS`) |
|---|---|---|
| Form WHEN-NEW-FORM-INSTANCE | Process (Before Header) `WHEN-NEW-FORM-INSTANCE` | `INIT_FORM` |
| Form PRE-FORM | Process (Before Header) `PRE-FORM` | `PRE_FORM` |
| `ORDERS.CUSTOMER_ID` WHEN-VALIDATE-ITEM | Validation `CUSTOMER_ID VALIDATION` + DA `CUSTOMER_ID WHEN-VALIDATE-ITEM` (FOS: `ORDERS.CHECK_ERROR(ORDERS.CUSTOMER_ID_VALIDATION(...))`) | `CUSTOMER_ID_VALIDATION` (error text); `CUSTOMER_ID_WHEN_VALIDATE_ITEM` when it derives values |
| Required item | Validation `CUSTOMER_ID REQUIRED` | `REQUIRED_VALIDATION` |
| `LINES.QTY` WHEN-VALIDATE-ITEM (detail IG) | DA `LINES QTY WHEN-VALIDATE-ITEM` | `LINES_QTY_VALIDATION` |
| `ORDERS` WHEN-VALIDATE-RECORD | Validation `ORDERS WHEN-VALIDATE-RECORD` | `ORDERS_WHEN_VALIDATE_RECORD` |
| `ORDERS` WHEN-CREATE-RECORD | Item defaults / process `WHEN-CREATE-RECORD` | `WHEN_CREATE_RECORD` |
| master PRE-INSERT / PRE-UPDATE / PRE-DELETE | Process `PRE-INSERT` … (request CREATE / SAVE / DELETE) | `PRE_INSERT` / `PRE_UPDATE` / `PRE_DELETE` |
| master POST-INSERT / POST-UPDATE / POST-DELETE | Process `POST-INSERT` … | `POST_INSERT` / `POST_UPDATE` / `POST_DELETE` |
| detail `LINES` PRE-INSERT … | Process `LINES PRE-INSERT` … (`:APEX$ROW_STATUS`) | `LINES_PRE_INSERT` … |
| `ORDERS` POST-QUERY | Column in region SQL or a view; else process `POST-QUERY` | `POST_QUERY` (only if needed) |
| `ORDERS` PRE-QUERY | WHERE clause of region / search-page SQL | — |
| Form PRE-COMMIT / POST-FORMS-COMMIT | Process `PRE-COMMIT` / `POST-FORMS-COMMIT` | `PRE_COMMIT` / `POST_FORMS_COMMIT` |
| `ORDERS.BTN_POST` WHEN-BUTTON-PRESSED | Button `BTN_POST` + Process `BTN_POST WHEN-BUTTON-PRESSED` | `BTN_POST_WHEN_BUTTON_PRESSED` |
| `ORDERS.ORDER_TYPE` WHEN-LIST-CHANGED | Dynamic Action `ORDER_TYPE WHEN-LIST-CHANGED` | `ORDER_TYPE_WHEN_LIST_CHANGED` (only if server logic) |
| Toolbar KEY-COMMIT / KEY-DELREC / ENTER-QUERY / KEY-EXIT | page 0 buttons CREATE·SAVE / DELETE / SEARCH / BACK | — |
| Function (TMPLT `EXECUTE_FUNCTION`) | DA on the custom event `<SYS_OS_FILE_NAME>` fired by the *Page Functions* list | `EXEC_FUNS` |
| Program unit `CALC_TOTAL` | — | `CALC_TOTAL` (same name) |

Always present: `CHECK_ERROR(ERROR_TEXT)` (raises the error text), `REQUIRED_VALIDATION`, `P0_PAGE_PK_CHECK`,
`GET_MODULE_ID`, `HEADER_TITLE`.

Parameters of members called by APEX: the bind name without an `I_` / `IO_` / `O_` prefix; a page item
`P<page>_X` is passed as `P_X` (`P_AGRMNT_NO => :P11100_AGRMNT_NO`, `MEMBER_ISN => :MEMBER_ISN`,
`SSO_APP_USER => :SSO_APP_USER`); inside SQL the parameter is qualified with the member name
(`docs/f345_reference_standard.md` §5, `scripts/parameter_names.py`). Every process body is one line calling the package.

Name length: package members ≤ **30 bytes** (DB 12.1.0.2). If a name is longer, shorten the item part
and keep the full Forms name in the member's header comment and in `MIG_OBJECT_MAP`.

Every APEX component has **Comments** = `Source: <FORM>.<BLOCK>.<ITEM>.<TRIGGER>`. Every package member
has a header comment with the same `Source:` line and the original trigger code kept as a comment block when
the logic changed during conversion.

## 6. Converted code should read like the original code
Use `FORMS_APX` (in `plsql_templates/`) inside the form package:

| Forms code | Converted code |
|---|---|
| `MESSAGE('Saved');` | `FORMS_APX.message('Saved');` |
| `MESSAGE('Error'); RAISE FORM_TRIGGER_FAILURE;` | `FORMS_APX.FORM_TRIGGER_FAILURE('Error');` |
| `SHOW_ALERT('AL_STOP')` (stop alert) | `FORMS_APX.alert('AL_STOP');` (text from Text Messages) |
| `:GLOBAL.company_id` | `FORMS_APX.get_global('COMPANY_ID')` → application item `G_COMPANY_ID` |
| `:GLOBAL.x := v;` | `FORMS_APX.set_global('X', v);` |
| `NAME_IN('ORDERS.STATUS')` / `COPY(v,'ORDERS.STATUS')` | `FORMS_APX.name_in('P120_STATUS')` / `FORMS_APX.copy(v, 'P120_STATUS')` (page processes only) |
| `USER` / `GET_APPLICATION_PROPERTY(USERNAME)` | `FORMS_APX.app_user` (or the f345 item `SSO_APP_USER`) |
| `:SYSTEM.CURRENT_FORM` | `FORMS_APX.current_form` (page alias) |

Inside the package prefer **parameters** for item values (testable code). Use `name_in`/`copy` only in thin
page-level code.

UI-only built-ins (`GO_BLOCK`, `SET_ITEM_PROPERTY`, `SHOW_VIEW`…) are not server code → Dynamic Actions
(see `plsql_templates/dynamic_action_patterns.sql`).

## 7. Shared Components = Forms shared objects
Reuse what f345 already has; create only what is missing.

| Forms | APEX Shared Component name |
|---|---|
| LOV `LOV_CUSTOMERS` + record group `RG_CUSTOMERS` | List of Values `LOV_CUSTOMERS` (SQL from the record group query) |
| Record group populated at runtime | Collection `COLLECTION_<RG_NAME>` |
| Alert `AL_CONFIRM_DEL` | Text Message `AL_CONFIRM_DEL` (text = alert message; use with `apex_lang.message`) |
| `:GLOBAL.COMPANY_ID` | Application Item `G_COMPANY_ID` (Session State Protection: Restricted) |
| Menu parameter `:PARAMETER.P_CURR_PORT_CD` … | f345 items `P_CURR_PORT_CD`, `P_CLASS_CD`, `P_PORT_TYPE`, `P_BRKR_NBR`, `SSO_APP_USER`, `V_USR_TYPE` (filled by f345 `After Auth`); new `P_<NAME>` otherwise |
| Menu `.mmb` | Navigation Menu list. Same hierarchy, labels and order. Each entry → page alias |
| Menu item role / `SET_MENU_ITEM_PROPERTY` | Application privileges - no Authorization Scheme is generated; the role is documented in the page spec |
| Function rights (TMPLT) | f345 list *Page Functions* (`SC_SYSOBJ_ROLE_PRIVS`), no per-function schemes |
| Visual attribute / property class | f345 CSS classes and Template Options (`docs/f345_reference_standard.md` §3) |
| Forms `.pll` `COMMON_LIB` | Package `LIB_COMMON_LIB` |
| ON-ERROR / error display | f345 error handling function `APP_ERROR_HANDLER` (already set) |

## 8. Standard page layout (Forms toolbar feel)
- The toolbar is **page 0** (region `P0_ACTIONS`), the same on every screen. Pages do not create their
  own toolbar buttons:
  `CREATE` (new record, `P0_PAGE_PK` empty) · `SAVE` (update) · `DELETE` (confirm) · `SEARCH` (opens
  `<page>01`) · `CLEAR` · `FUNCS` (or `REPORT_SHOW` / `REPORT_PRINT` when the page has `P<page>_REPORT`) · `BACK`.
- A page keeps its record key in `P0_PAGE_PK` and handles the requests `CREATE`, `SAVE` and `DELETE`.
- Page-specific buttons use the *Text with Icon* template, `#DEFAULT#:t-Button--iconLeft` and a `cg-b-*` class.
- Messages: success at top (Forms status line), errors inline + notification.
- Theme style *ZATCA Forms* (set in f345).

## 9. Registry tables (where is everything?)
`scripts/create_migration_registry.sql` creates:
- `MIG_FORM_REGISTRY`: one row per form (`form_name`, `app_id`, `page_from` = `page_to` = main page,
  `page_alias`, `package_name` = form name, `status`, `owner`, dates).
- `MIG_OBJECT_MAP`: one row per Forms object (`form_name`, `forms_object_type`, `forms_object_name`
  e.g. `ORDERS.CUSTOMER_ID.WHEN-VALIDATE-ITEM`, `apex_comp_type`, `apex_comp_name` e.g.
  `CUSTOMER_ID VALIDATION`, `page_id`, `plsql_member` e.g. `ORDERS.CUSTOMER_ID_VALIDATION`, `status`, `notes`).
  Toolbar buttons map to page 0.
- View `MIG_V_WHERE_IS`: search by Forms name → where it is in APEX and PL/SQL.

Example: "Where is the validation of CUSTOMER_ID in ORDERS now?"
```sql
SELECT * FROM mig_v_where_is
 WHERE form_name = 'ORDERS' AND forms_object_name LIKE '%CUSTOMER_ID%';
```

## 10. Repository folders mirror the forms
```
analysis/<form>/   plsql/<form>/   apex/<form>/   registry/<form>_registry.sql   tests/<form>/
apex/Reference/f345.sql   (reference application)
```
One Git commit per step per form. The commit message starts with the form name.
