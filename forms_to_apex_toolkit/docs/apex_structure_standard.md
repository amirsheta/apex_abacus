# APEX Structure Standard — "Forms-Mirror"

Target: APEX 21.2 on Oracle Database 12.1.0.2.
Purpose: organise APEX so it looks like the original Forms application. A developer who knows
the `.fmb` can find every block, item, trigger, LOV and alert in APEX **by the same name**, so later
changes are as easy as in Forms Builder.

---

## 1. Applications and workspaces
| Forms | APEX |
|---|---|
| One Forms application (main `.mmb` + its forms) | One APEX application. Name = Forms application name; alias = short code (e.g. `HR`, `INV`) |
| Several Forms applications | One workspace (`FORMS_MIGRATION`) with one APEX app per Forms application, sharing one parsing schema |
| Shared `.pll` / `.olb` | DB packages `pkg_lib_<name>` + one "Master" app holding shared Theme, templates and Authorization Schemes. Other apps **subscribe** to it (Shared Components → Subscription) |

Application ID ranges (example): HR = 1000, INV = 2000, FIN = 3000. Record them in `MIG_FORM_REGISTRY`.

## 2. Pages — one page range per form
- Every form gets a **range of 10 page numbers**, allocated in order in `MIG_FORM_REGISTRY`:

  | Page | Use |
  |---|---|
  | `N0` (e.g. 120) | Main page = main content canvas |
  | `N1`–`N5` | Modal dialogs = stacked canvases / popup windows / called forms used as dialogs |
  | `N6`–`N8` | Extra tab or detail pages, when needed |
  | `N9` | Reserved |

- Page **Name** = Forms window title. Page **Alias** = form name (`ORDERS`); dialogs = `ORDERS_<CANVAS>`.
- Page **Group** = Forms subsystem or menu group (e.g. `Sales`). It works like folders in App Builder.
- Page **Comments** = `Source: ORDERS.fmb (window WIN_MAIN, canvas CV_MAIN)`.
- Page 0 (Global Page) holds only things that are on every page (e.g. a footer). No business logic.
- Page 9999 = Login. Page 1 = Home (shows the menu as cards, like the Forms main menu screen).

## 3. Regions = blocks
| Forms | APEX region |
|---|---|
| Base-table block, single record | Form region |
| Base-table block, multi record | Interactive Grid |
| Read-only block | Interactive Report |
| Control block | Static Content region (`CONTROL` block → Static ID `CONTROL`) |
| Tab canvas | "Tabs Container" region. Each tab page = sub-region whose Static ID is the tab page name |
| Stacked canvas | Inline Dialog region, or a modal page `N1`–`N5` |

Rules:
- Region **Static ID** = Forms block name (UPPERCASE). JavaScript and DAs refer to the region by this ID,
  like `GO_BLOCK('ORDERS')`.
- Region **Title** = block prompt / frame title. **Sequence** = Forms block navigation order × 10.
- Region **Comments** = `Source: ORDERS.<BLOCK>`.
- Master-detail relation → the detail IG's "Master Region" = master region. Relation name goes in Comments.

## 4. Items = Forms items (keep the name)
- Page item = `P<page>_<FORMS_ITEM_NAME>`, e.g. `ORDERS.CUSTOMER_ID` → `P120_CUSTOMER_ID`.
- IG column name = Forms item name, e.g. `LINES.QTY` → column `QTY` in IG `LINES`.
- Two blocks on one page have the same item name → `P<page>_<BLOCK_ABBR>_<ITEM>` (e.g. `P120_HDR_STATUS`).
- Item **Label** = Forms prompt. **Sequence** = Forms item order (tab order) × 10.
- Item type follows Forms: Text Item → Text/Number/Date; List Item → Select List; Check Box → Checkbox/Switch;
  Radio Group → Radio Group; Display Item → Display Only; non-displayed → Hidden (Value Protected = Yes).
- Format mask, max length and required flag are copied from the Forms item properties.

## 5. Triggers = named APEX components + named package members
APEX component **names** use Forms trigger notation: `<BLOCK>[.<ITEM>].<TRIGGER-NAME>`.

| Forms trigger | APEX component (name) | Package member (`pkg_<form>`) |
|---|---|---|
| Form WHEN-NEW-FORM-INSTANCE | Process (Before Header) `WHEN-NEW-FORM-INSTANCE` | `wnfi` |
| Form PRE-FORM | Process (Before Header) `PRE-FORM` | `pre_form` |
| `ORDERS.CUSTOMER_ID` WHEN-VALIDATE-ITEM | Validation `ORDERS.CUSTOMER_ID.WHEN-VALIDATE-ITEM` | `customer_id_wvi` |
| `ORDERS` WHEN-VALIDATE-RECORD | Validation `ORDERS.WHEN-VALIDATE-RECORD` | `orders_wvr` |
| `ORDERS` WHEN-CREATE-RECORD | Item defaults / computation `ORDERS.WHEN-CREATE-RECORD` | `orders_wcr` |
| `ORDERS` PRE-INSERT / PRE-UPDATE / PRE-DELETE | Process `ORDERS.PRE-INSERT` … | `orders_pre_ins` / `_pre_upd` / `_pre_del` |
| `ORDERS` POST-INSERT / POST-UPDATE / POST-DELETE | Process `ORDERS.POST-INSERT` … | `orders_post_ins` / `_post_upd` / `_post_del` |
| `ORDERS` POST-QUERY | Column in region SQL (`pkg_orders.orders_post_qry(...)`) or a view | `orders_post_qry` |
| `ORDERS` PRE-QUERY | WHERE clause of region SQL | `orders_pre_qry` (only if logic is complex) |
| Form PRE-COMMIT / POST-FORMS-COMMIT | Process `PRE-COMMIT` / `POST-FORMS-COMMIT` | `pre_commit` / `post_commit` |
| `ORDERS.BTN_POST` WHEN-BUTTON-PRESSED | Button `BTN_POST` + Process `ORDERS.BTN_POST.WHEN-BUTTON-PRESSED` | `btn_post_wbp` |
| `ORDERS.ORDER_TYPE` WHEN-LIST-CHANGED | Dynamic Action `ORDERS.ORDER_TYPE.WHEN-LIST-CHANGED` | `order_type_wlc` (only if server logic) |
| WHEN-CHECKBOX-CHANGED / WHEN-RADIO-CHANGED | Dynamic Action `…WHEN-CHECKBOX-CHANGED` | `<item>_wcc` / `<item>_wrc` |
| KEY-COMMIT / KEY-EXIT / KEY-xxx | Button `SAVE` / `EXIT` + process `KEY-COMMIT` | `key_commit` … |
| Program unit `CALC_TOTAL` | — | `calc_total` (same name) |

Trigger abbreviations: `wnfi`, `pre_form`, `wvi`, `wvr`, `wcr`, `pre_ins`, `pre_upd`, `pre_del`, `post_ins`,
`post_upd`, `post_del`, `post_qry`, `pre_qry`, `wbp`, `wlc`, `wcc`, `wrc`, `wnbi` (when-new-block-instance),
`wnri` (when-new-record-instance), `wnii` (when-new-item-instance), `key_<name>`.

Name length: package members ≤ **30 bytes** (DB 12.1.0.2). If `<item>_<abbr>` is longer, shorten the item part
and keep the full Forms name in the member's header comment and in `MIG_OBJECT_MAP`.

Every APEX component has **Comments** = `Source: <FORM>.<BLOCK>.<ITEM>.<TRIGGER>`. Every package member
has a header comment with the same `Source:` line and the original trigger code kept as a comment block when
the logic changed during conversion.

## 6. Converted code should read like the original code
Use `pkg_forms_compat` (in `plsql_templates/`) inside `pkg_<form>`:

| Forms code | Converted code |
|---|---|
| `MESSAGE('Saved');` | `pkg_forms_compat.message('Saved');` |
| `MESSAGE('Error'); RAISE FORM_TRIGGER_FAILURE;` | `pkg_forms_compat.ftf('Error');` |
| `SHOW_ALERT('AL_STOP')` (stop alert) | `pkg_forms_compat.alert('AL_STOP');` (text from Text Messages) |
| `:GLOBAL.company_id` | `pkg_forms_compat.get_global('COMPANY_ID')` → `AI_COMPANY_ID` |
| `:GLOBAL.x := v;` | `pkg_forms_compat.set_global('X', v);` |
| `NAME_IN('ORDERS.STATUS')` / `COPY(v,'ORDERS.STATUS')` | `pkg_forms_compat.name_in('P120_STATUS')` / `pkg_forms_compat.copy(v, 'P120_STATUS')` (page processes only) |
| `USER` / `GET_APPLICATION_PROPERTY(USERNAME)` | `pkg_forms_compat.app_user` |
| `:SYSTEM.CURRENT_FORM` | `pkg_forms_compat.current_form` (page alias) |

Inside `pkg_<form>` prefer **parameters** for item values (testable code). Use `name_in`/`copy` only in thin
page-level wrapper code.

UI-only built-ins (`GO_BLOCK`, `SET_ITEM_PROPERTY`, `SHOW_VIEW`…) are not server code → Dynamic Actions
(see `plsql_templates/dynamic_action_patterns.sql`).

## 7. Shared Components = Forms shared objects
| Forms | APEX Shared Component name |
|---|---|
| LOV `LOV_CUSTOMERS` + record group `RG_CUSTOMERS` | List of Values `LOV_CUSTOMERS` (SQL from the record group query) |
| Record group populated at runtime | Collection `COL_<RG_NAME>` |
| Alert `AL_CONFIRM_DEL` | Text Message `AL_CONFIRM_DEL` (text = alert message; use with `apex_lang.message`) |
| `:GLOBAL.COMPANY_ID` | Application Item `AI_COMPANY_ID` (Session State Protection: Restricted) |
| Menu `.mmb` | Navigation Menu list. Same hierarchy, labels and order. Each entry → page alias |
| Menu item role / `SET_MENU_ITEM_PROPERTY` | Authorization Scheme `ROLE_<ROLE>` on menu entry + page + buttons |
| Visual attribute `VA_CURRENT_RECORD` | CSS class `va-current-record` (Theme Roller / application CSS file) |
| Property class `PC_BUTTON` | Template Options standard (documented once in `analysis/_shared/olb_mapping.md`) |
| Forms `.pll` `COMMON_LIB` | Package `pkg_lib_common_lib` |

## 8. Standard page layout (Forms toolbar feel)
- Buttons region at the top of every main page, in this order and with these names:
  `SAVE` (Ctrl+S) · `CREATE` · `DELETE` · `QUERY` (refresh region) · `CLEAR` (clear cache) · `EXIT` (back to menu).
- Hot keys are optional. If needed, add them once in the Master app JavaScript file.
- Messages: success at top (Forms status line), errors inline + notification.
- Same theme style for all apps (Universal Theme 42, one style chosen once in the Master app).

## 9. Registry tables (where is everything?)
`scripts/create_migration_registry.sql` creates:
- `MIG_FORM_REGISTRY`: one row per form (`form_name`, `app_id`, `page_from`, `page_to`, `page_alias`,
  `package_name`, `status`, `owner`, dates).
- `MIG_OBJECT_MAP`: one row per Forms object (`form_name`, `forms_object_type`, `forms_object_name`
  e.g. `ORDERS.CUSTOMER_ID.WHEN-VALIDATE-ITEM`, `apex_comp_type`, `apex_comp_name`, `page_id`,
  `plsql_member`, `status`, `notes`).
- View `MIG_V_WHERE_IS`: search by Forms name → where it is in APEX and PL/SQL.

Example: "Where is the validation of CUSTOMER_ID in ORDERS now?"
```sql
SELECT * FROM mig_v_where_is
 WHERE form_name = 'ORDERS' AND forms_object_name LIKE '%CUSTOMER_ID%';
```

## 10. Repository folders mirror the forms
```
analysis/<form>/   plsql/<form>/   apex/<form>/   registry/<form>_registry.sql   tests/<form>/
```
One Git commit per step per form. The commit message starts with the form name.
