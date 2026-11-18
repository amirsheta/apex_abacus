# Forms 12c → APEX 21.2 Mapping Reference

## 1. Object types
| Forms object | APEX 21.2 equivalent |
|---|---|
| Form module (.fmb) | Page(s) in an application |
| Menu module (.mmb) | Navigation Menu list; roles → application privileges (no Authorization Schemes) |
| PL/SQL library (.pll) | Database package `LIB_<name>` |
| Object library (.olb) / Property class | Theme, Template Options, Shared Components |
| Data block – single record | Form region (NATIVE_FORM) + Form Initialization / Automatic Row Processing |
| Data block – multi record editable | Interactive Grid (editable) |
| Data block – read only | Interactive Report / Classic Report |
| Control block | Static Content region with page items |
| Relation (master-detail) | Master-Detail page; IG "Master Region" |
| Item: Text / Display | Text Field / Number Field / Date Picker / Display Only |
| Item: List / Radio / Checkbox | Select List / Radio Group / Switch or Checkbox |
| Item: Button | Button |
| Item: Image | Display Image / File Browse |
| Canvas content / stacked / tab | Page / Inline or Modal Dialog / Tabs Container or Region Display Selector |
| Window (modal) | Modal Dialog page |
| LOV + Record Group (static query) | Shared LOV, Popup LOV, Select List |
| Record Group (runtime) | `APEX_COLLECTION` |
| Alert | Confirm DA, `apex.message.confirm`, validation error, success message |
| Visual attribute | CSS class / Template Option / IG highlight |
| Parameter | Page item set via URL |
| Program unit | Package procedure/function |
| Timer | JavaScript `setInterval` + DA / scheduler job |

## 2. Built-ins
| Forms built-in | APEX 21.2 replacement |
|---|---|
| `MESSAGE` | Process success message; `apex.message.showPageSuccess` |
| `SHOW_ALERT` | Confirm DA / `apex.message.confirm` / `apex.message.alert` |
| `RAISE FORM_TRIGGER_FAILURE` | `raise_application_error` / `apex_error.add_error` |
| `GO_BLOCK`, `GO_ITEM` | DA Set Focus; `apex.item('P1_X').setFocus()` |
| `GO_RECORD`, `NEXT_RECORD`, `FIRST_RECORD` | IG navigation; Form region pagination buttons |
| `EXECUTE_QUERY` | DA Refresh region / page submit |
| `ENTER_QUERY` | IR/IG search, Faceted Search, filter items |
| `COMMIT_FORM` | Submit + Automatic Row Processing (APEX commits at end of request) |
| `ROLLBACK`/`CLEAR_FORM` | Cancel button + Clear Cache branch |
| `CLEAR_BLOCK`, `CLEAR_ITEM` | DA Clear; Clear Cache for items/region |
| `SET_ITEM_PROPERTY` (VISIBLE/ENABLED/REQUIRED) | DA Show/Hide/Enable/Disable; server-side conditions; validations |
| `SET_BLOCK_PROPERTY(DEFAULT_WHERE/ORDER_BY)` | Region SQL with page-item binds |
| `GET_ITEM_PROPERTY`, `NAME_IN` | `:P1_ITEM`, `v('P1_ITEM')`, `apex_util.get_session_state` |
| `COPY` | `apex_util.set_session_state`; DA Set Value |
| `CALL_FORM`, `OPEN_FORM`, `NEW_FORM` | Branch / link / Modal Dialog, `apex_page.get_url` |
| `CREATE_GROUP`, `POPULATE_GROUP`, `ADD_GROUP_ROW` | `apex_collection.create_collection_from_query_b`, `add_member` |
| `GET_GROUP_CHAR_CELL` etc. | `SELECT c001.. FROM apex_collections` |
| `HOST` | `DBMS_SCHEDULER` external/program job |
| `WEB.SHOW_DOCUMENT` | Redirect / link URL; `apex_util.redirect_url` |
| `TEXT_IO`/`CLIENT_TEXT_IO` | File Browse + `apex_application_temp_files`; `UTL_FILE`; download via `apex_util`/process |
| `RUN_REPORT_OBJECT` | BI Publisher / Report Query / APEX Office Print / PL/PDF |
| `DO_KEY` | Call the equivalent process/DA |
| `SYNCHRONIZE`, `SET_APPLICATION_PROPERTY(CURSOR_STYLE)` | Not needed / `apex.util.showSpinner` |
| `GET_APPLICATION_PROPERTY(USERNAME)` | `:APP_USER` |

## 3. Triggers
| Forms trigger | APEX 21.2 equivalent |
|---|---|
| PRE-FORM, WHEN-NEW-FORM-INSTANCE | Before Header process / computation |
| WHEN-NEW-BLOCK/RECORD/ITEM-INSTANCE | DA (Page Load, IG Selection Change, Get Focus) |
| WHEN-VALIDATE-ITEM | Item validation (+ optional DA Change for instant feedback) |
| WHEN-VALIDATE-RECORD | Page / IG row validation |
| WHEN-CREATE-RECORD | Item default values; IG column defaults |
| PRE-QUERY | Region SQL WHERE with binds |
| POST-QUERY | JOIN / view column / function in SQL; After Header computation (single-record) |
| PRE-INSERT/UPDATE/DELETE | Process before Automatic Row Processing (per row for IG) |
| POST-INSERT/UPDATE/DELETE | Process after Automatic Row Processing |
| ON-INSERT/UPDATE/DELETE | DML process Target Type = PL/SQL Code |
| PRE-COMMIT / POST-FORMS-COMMIT | Processes before / after DML processes |
| ON-LOCK | Optimistic locking (built-in checksum) |
| WHEN-BUTTON-PRESSED | Button → Submit + process, or DA Click |
| WHEN-LIST-CHANGED, WHEN-RADIO-CHANGED, WHEN-CHECKBOX-CHANGED | DA Change |
| KEY-COMMIT, KEY-EXIT, KEY-* | Buttons; JS keyboard shortcuts if needed |
| ON-ERROR, ON-MESSAGE | Application Error Handling Function |
| WHEN-TIMER-EXPIRED | JS timer + DA / scheduler job |
| WHEN-MOUSE-* | DA (Click/Mouse events) — usually dropped |

## 4. System variables
| Forms | APEX 21.2 |
|---|---|
| `:SYSTEM.CURRENT_FORM` | `:APP_PAGE_ID`, `:APP_ALIAS` |
| `:SYSTEM.CURSOR_BLOCK/ITEM`, `:SYSTEM.TRIGGER_ITEM` | DA `this.triggeringElement` (JS) |
| `:SYSTEM.RECORD_STATUS` | IG `:APEX$ROW_STATUS` (C/U/D); Form: PK null = new |
| `:SYSTEM.MODE` (NORMAL/ENTER-QUERY) | Not applicable |
| `:SYSTEM.FORM_STATUS`, `BLOCK_STATUS` | `apex.page.isChanged()` (JS) |
| `:SYSTEM.CURRENT_DATETIME`, `$$DATE$$` | `SYSDATE` / `LOCALTIMESTAMP` |
| `:SYSTEM.MESSAGE_LEVEL` | Not applicable |
| `:SYSTEM.LAST_QUERY` | Region SQL / `apex_region` APIs |
| `USER` (in Forms) | `:APP_USER` |
| `:PARAMETER.<name>` | Page item `P<page>_P_<NAME>`; a caller passes it in application item `P_<NAME>` (process `PARAMETERS ENTRY`). Menu parameters reuse the f345 items (`P_CURR_PORT_CD`, `SSO_APP_USER` …) |
| `:GLOBAL.<name>` | Application Item `G_<NAME>` (f345) |

## 5. Record Group → APEX Collection
```sql
-- Forms: rg := CREATE_GROUP_FROM_QUERY('RG_PRICES','SELECT ...'); POPULATE_GROUP(rg);
apex_collection.create_collection_from_query_b(
    p_collection_name => 'COLLECTION_RG_PRICES',
    p_query           => 'SELECT product_id, price FROM prices WHERE active = ''Y''');
-- Forms: GET_GROUP_NUMBER_CELL('RG_PRICES.PRICE', i)
SELECT TO_NUMBER(c002) FROM apex_collections WHERE collection_name = 'COLLECTION_RG_PRICES' AND seq_id = :i;
-- (create_collection_from_query_b stores query columns in c001..c050 as text)
-- ADD_GROUP_ROW / SET_GROUP_CHAR_CELL -> apex_collection.add_member / update_member_attribute
-- DELETE_GROUP -> apex_collection.delete_collection
```
Collections are per APEX session; for multi-user shared data use a real table.

## 6. Global variables → Application Items
| Forms | APEX |
|---|---|
| `:GLOBAL.company_id := 10;` | Shared Components → Application Items → `G_COMPANY_ID` (Session State Protection: Restricted); set in the f345 Application Process "After Auth" or `FORMS_COMPAT.set_global('COMPANY_ID', 10)` |
| `x := :GLOBAL.company_id;` | `:G_COMPANY_ID` in SQL/PLSQL; `FORMS_COMPAT.get_global('COMPANY_ID')` in packages |
| `ERASE('GLOBAL.x')` | `FORMS_COMPAT.erase_global('X')` (application item `G_X`) |
| `DEFAULT_VALUE('x','GLOBAL.y')` | Application computation (On New Instance) |
