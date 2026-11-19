# Prompt 03 — APEX 21.2 Page Design

**When to use:** After `02_logic_extraction`, once the package compiles and the extraction report is reviewed.
**Input:** inventory, logic extraction report, package spec, reference application `apex/Reference/f345.sql`
**Standard:** f345 (`CLAUDE.md` §4b, `docs/f345_reference_standard.md`)
**Output:** `analysis/<form_name>/<form_name>_apex_page_spec.md` + `registry/<form_name>_registry.sql`

---

```text
You are working on the Oracle Forms 12c → Oracle APEX 21.2 migration project.
Follow all rules in CLAUDE.md (especially §4b). Use ONLY features available in APEX 21.2.

TASK: Design the complete APEX page structure for ONE form, to the f345 reference standard.

FORM NAME:       {{FORM_NAME}}             (upper case for names: {{FORM_NAME_UC}})
INVENTORY:       analysis/{{FORM_NAME}}/{{FORM_NAME}}_inventory.md
EXTRACTION:      analysis/{{FORM_NAME}}/{{FORM_NAME}}_logic_extraction.md
PACKAGE SPEC:    plsql/{{FORM_NAME}}/{{FORM_NAME}}_spec.sql   (package {{FORM_NAME_UC}})
REFERENCE:       apex/Reference/f345.sql + docs/f345_reference_standard.md
APPLICATION ID:  {{APP_ID}}                (the application installed from f345)
MAIN PAGE NO.:   {{PAGE_ID}}               (from MIG_FORM_REGISTRY, e.g. AGR1100 → 11100)
PAGE GROUP:      {{SUBSYSTEM}}             (Forms subsystem / menu group)
OUTPUT:          analysis/{{FORM_NAME}}/{{FORM_NAME}}_apex_page_spec.md
                 registry/{{FORM_NAME}}_registry.sql

## 0. f345 / Forms-mirror standard (MANDATORY)
Pages
- Main page {{PAGE_ID}}: name and alias {{FORM_NAME_UC}}, page template Zatca-Minimal_No_Navigation,
  title &SYS_ANAME., CSS class zf, protection C.
- Search page {{PAGE_ID}}01: name {{FORM_NAME_UC}}_SEARCH, alias {{FORM_NAME_UC}}-SEARCH, modal 1800 × 800.
  Page 0 finds it by this number, so the number is not optional.
- Other modal pages (stacked canvases, called LOV forms): {{PAGE_ID}}02 … {{PAGE_ID}}09.
  Each needs a process `G_LAST_PAGE KEEP` (After Header, `:G_LAST_PAGE := {{PAGE_ID}};`), or
  f345 SCREEN ENTRY RESET clears the open record when the user returns. List these pages.
Toolbar
- Do NOT design toolbar buttons. The f345 page 0 toolbar supplies CREATE · SAVE · DELETE ·
  SEARCH · CLEAR · FUNCS · BACK. The main page keeps its record key in P0_PAGE_PK and handles
  the requests CREATE (insert, P0_PAGE_PK null), SAVE (update) and DELETE.
- Functions (TMPLT / side menu): inline-dialog region FUNCS with the f345 list "Page Functions";
  one DA per function on the custom event named after SC_SYSTEM_OBJECTS.SYS_OS_FILE_NAME.
- Reports: an item P{{PAGE_ID}}_REPORT switches FUNCS to REPORT_SHOW / REPORT_PRINT (custom events).
Behaviour (docs/f345_reference_standard.md §9 - declarative first)
- Build every Forms behaviour from native components: validations, FOS Execute PL/SQL Code (Items to
  Submit / Return), native DA actions, item Read Only / server-side conditions calling BOOLEAN package
  functions. No JavaScript file, no AJAX callbacks, no client UI-state engine. An Execute JavaScript
  Code action has at most 3 lines; list every one in §10 with the reason.
Names
- Region Static ID = Forms block name; region order = Forms block order; title = block/frame title (Arabic).
- Items keep the Forms item name: P<page>_<FORMS_ITEM>; IG column = Forms item name.
  Duplicate names across blocks → P<page>_<BLOCK>_<ITEM>. Item order = Forms tab order.
  Forms parameters → P<page>_P_<PARAM> (+ application item P_<PARAM> when a caller passes it).
- Processes `<TRIGGER>` (master block) / `<BLOCK> <TRIGGER>` (detail); validations
  `<ITEM> VALIDATION` / `<ITEM> REQUIRED`; DAs `<ITEM> WHEN-VALIDATE-ITEM` /
  `<BLOCK> <COLUMN> WHEN-VALIDATE-ITEM`. Space separated, no dots.
- Every process / validation / DA is a ONE-LINE call to {{FORM_NAME_UC}} with I_/IO_ named
  parameters (key copies such as `:P0_PAGE_PK := :P<page>_<PK>;` are the only exception).
- Every component's Comments = "Source: {{FORM_NAME}}.<BLOCK>.<ITEM>.<TRIGGER>".
- LOVs keep Forms LOV names (do not re-create LOVs that f345 has); alerts → Text Messages with
  the alert name; :GLOBAL.X → application item G_X; menu parameters → the f345 items
  (P_CURR_PORT_CD, SSO_APP_USER …); menu roles → documented only: page access comes from the
  application's privileges, so NO Authorization Schemes (CLAUDE.md §8).
  Never re-create an application item, LOV, plug-in or template that f345 already has.

## 1. Page type decision per block
Apply this decision table and document the reasoning per block (templates from standard §3):
| Forms block characteristics | APEX 21.2 choice | f345 template / classes |
|---|---|---|
| Single-record, base table, edit | Form region (native "Form") on the main page | Interactive Report template, `zatca-forms cg-form cg-card` |
| Multi-record, base table, inline editing, < ~30 columns | Interactive Grid (editable) | Standard, `#DEFAULT#:t-Region--noPadding`, `cg-card cg-grid` |
| Multi-record, read-only / query and drill | Interactive Grid (read-only) or Interactive Report | Standard, `cg-card cg-grid` |
| Master single-record + detail multi-record | Form region + editable IG on the same page (AGR1100 pattern) | as above |
| Master multi-record + detail multi-record | IG + IG ("Master Region" set on detail) | as above |
| 3-level master-detail | Stacked IGs or drill-down to a {{PAGE_ID}}0n page — justify | |
| Control block (no base table) | Static Content region with page items | Blank with Attributes |
| Procedure-based / FROM-clause query block | IG/IR on a view or "SQL Query"; custom PL/SQL DML process | |
| Enter-Query / Execute-Query | Search page {{PAGE_ID}}01: criteria region + read-only IG with link column → `f?p=&APP_ID.:{{PAGE_ID}}:&SESSION.::&DEBUG.:{{PAGE_ID}}:P0_PAGE_PK:&PK.` | Blank with Attributes `zatca-forms cg-form` + Standard IG |
| Stacked canvas / popup | Inline Dialog region or modal page {{PAGE_ID}}0n | Inline Dialog |
| Tab canvas | Regions in a "Tabs Container" template, or Region Display Selector | Tabs Container |
Add a hero region (Blank with Attributes, class `cg-hero`) with the screen title (HEADER TITLE).

## 2. Pages
For every page:
| Page No | Name / alias | Page mode (Normal / Modal Dialog) | Page template | Source Forms canvas/window | Forms menu role (documentation only) | Navigation menu entry |

## 3. Regions (per page)
| Region | Static ID | Type (Form / Interactive Grid / Interactive Report / Classic Report / Static Content) |
  Source (table, view, or SQL — write the full SQL) | Primary key | f345 template + template options + CSS classes |
  Parent region / position | Master region (for detail IGs) | Edit enabled (Add/Update/Delete) | Source Forms block |

## 4. Items (per region)
| Page item / IG column | Source column | Type (Text Field, Number Field, Date Picker, Select List,
  Popup LOV, Radio Group, Checkbox, Switch, Display Only, Hidden, Textarea, File Browse) |
  Label | Required | Format mask | Default (type + value) | LOV | Maximum length |
  Read Only condition (`{{FORM_NAME_UC}}.<ITEM>_IS_READ_ONLY(...)`, from Make_Field_Entrable) |
  Session State Protection | Source Forms item |
Rules: item names per §0; label templates Required - Above / Optional - Above with
`t-Form-fieldContainer--stretchInputs`; Forms checkbox → Switch or Checkbox; Forms list item
→ Select List (static or shared LOV); Forms display item → Display Only; hidden/non-displayed
items → Hidden (Value Protected = Yes). Always add P{{PAGE_ID}}_MODULE_ID (Hidden): SCREEN ENTRY
RESET keeps it.

## 5. Buttons
Only buttons that the page 0 toolbar does not cover (form-specific WHEN-BUTTON-PRESSED):
| Button | Region | Position (NEXT) | Action (Submit Page / Redirect / Defined by DA) | Server-side condition |
  Confirm message | CSS class (cg-b-*) + icon | Source (WHEN-BUTTON-PRESSED / KEY-*) |
Template Text with Icon, `#DEFAULT#:t-Button--iconLeft`. Map every Forms toolbar button to its
page 0 equivalent in the traceability matrix instead of designing it.

## 6. LOVs
Map every Forms LOV/record group:
| Forms LOV | APEX LOV name (Shared Component LOV_<NAME>, or existing f345 LOV) or inline | Type (SQL / Static) |
  SQL (display_value, return_value) | Used by items | Item type (Select List / Popup LOV) |
  Cascading parent item(s) | Notes (multi-column return → set additional items via DA) |
Rule: < ~50 rows and no search → Select List; otherwise Popup LOV. Forms LOVs that
return more than one column: Popup LOV returns one value; set the extra items via a
DA "Set Value" (SQL) on change — document the DA. Binds use f345 item names (:P_CURR_PORT_CD, :G_X).

## 7. Validations
Map every WHEN-VALIDATE-ITEM and WHEN-VALIDATE-RECORD:
| Validation name (`<ITEM> VALIDATION` / `<ITEM> REQUIRED`) | Level (item / page / IG row) | Type (PL/SQL Function Body returning Error Text / ...) |
  Code (`return {{FORM_NAME_UC}}.<ITEM>_VALIDATION(I_P<page>_<ITEM> => :P<page>_<ITEM>);`) | Associated item |
  Error display location | Condition (request CREATE / SAVE) | Source trigger |
Plus the matching DA `<ITEM> WHEN-VALIDATE-ITEM` (change → FOS Execute PL/SQL Code:
`{{FORM_NAME_UC}}.CHECK_ERROR({{FORM_NAME_UC}}.<ITEM>_VALIDATION(...));`) so the user sees the error at once.
For IG validations use :COLUMN bind syntax and "Editable Region" set to the IG.

## 8. Processes
| Process | Point (Before Header / After Submit) | Sequence | Type |
  Code | Condition (request / :APEX$ROW_STATUS) | Success / error message | Source trigger |
Use the order of docs/f345_reference_standard.md §6:
- Before Header: 20 `P0_PAGE_PK CHECK` · 40 `PARAMETERS` · 50 `PARAMETERS ENTRY` ·
  60 `WHEN-NEW-FORM-INSTANCE` · 70 `P0_PAGE_PK` · 80 `Initialize form` · 90 `PRE-FORM` · 100 `HEADER TITLE`.
- After Submit (master): 10 `PRE-INSERT` (`:P0_PAGE_PK is null and :REQUEST = 'CREATE'`) ·
  20 `PRE-UPDATE` (`:P0_PAGE_PK is not null and :REQUEST = 'SAVE'`) · 30 `PRE-DELETE` (DELETE) ·
  40/41 `Process form` / `Process form - DELETE` · 50–70 `POST-INSERT/UPDATE/DELETE` ·
  80/85 `P0_PAGE_PK AFTER INSERT` / `AFTER DELETE`.
- After Submit (each detail block, 1xx, 2xx …): `<BLOCK> MASTER KEYS` · `<BLOCK> PRE-INSERT/UPDATE/DELETE` ·
  `<BLOCK> - Save Interactive Grid Data` · `<BLOCK> POST-*`, with :APEX$ROW_STATUS = 'C'/'U'/'D'.
- POST-QUERY → preferably a column computed in the region SQL / view; else a Before Header
  process calling {{FORM_NAME_UC}}. Never per-row PL/SQL in reports.
- WHEN-CREATE-RECORD defaults → item Default values or a Before Header process.

## 9. Computations
| Item | Point | Type | Expression | Condition | Source |

## 10. Dynamic Actions
From the "UI logic for Dynamic Actions" section of the extraction report:
| DA name (f345: `<ITEM> <TRIGGER>`) | Event (Change / Click / Page Load / Custom / Dialog Closed / Before Page Submit) |
  Selection (item/region/jQuery) | Client-side condition | True actions (Show / Hide / Enable / Disable /
  Set Value / Refresh / FOS Execute PL/SQL Code / Execute JavaScript Code / Confirm / Set Focus) |
  False actions | Items to submit / return | Fire on initialization | Source trigger |
Use the patterns in plsql_templates/dynamic_action_patterns.sql, in this order of preference:
1. FOS Execute PL/SQL Code (validation / derived values via Items to Return);
2. native Enable / Disable / Show / Hide / Set Value / Set Focus / Refresh / Confirm, with
   client-side conditions (Item = Value, or a flag item returned by FOS);
3. only if 1-2 cannot do it: Execute JavaScript Code, at most 3 lines, with the reason.
The one known case for 3: a confirm before page 0's CREATE / SAVE (they submit directly), a DA on
"Before Page Submit" whose code sets apex.event.gCancelFlag and re-submits after the answer.
Count the JavaScript actions at the end of the section (target: as close to 0 as possible).

## 11. Alerts and messages
| Forms alert | Usage | APEX equivalent | Text |
Rules:
- Informational (Note) after success → process Success Message.
- Stop alert + FORM_TRIGGER_FAILURE → FORMS_COMPAT.alert('<ALERT>') (Text Message with the alert name).
- Caution with Yes/No deciding an action → DA "Confirm" action / apex.message.confirm (or the
  page 0 ASK_DLG dialog), followed by the server action.
- Text messages → Shared Components > Text Messages (for translation) where reused.

## 12. Branches and navigation
| Branch | Point | Target page | Condition | Items set | Source (CALL_FORM / NEW_FORM / GO_BLOCK) |
CALL_FORM with parameters → the caller sets application items P_<PARAM> (server side) and links
to the page; PARAMETERS ENTRY copies them. Modal dialog → "Dialog Closed" DA to refresh.

## 13. Shared components required
Only what f345 does not have: new application items (G_ / P_), LOVs,
static application files, text messages. List the f345 components that are reused.

## 14. Traceability matrix
| Forms object (block/item/trigger/LOV/alert) | APEX component (f345 name) | Page | Status (mapped / dropped / TODO) |
EVERY object from the inventory must appear. Toolbar buttons map to page 0 (page 0, e.g.
"SAVE / CREATE (page 0 toolbar)").

## 15. Registry script
Write registry/{{FORM_NAME}}_registry.sql: one INSERT into MIG_FORM_REGISTRY for the form
(page_from = page_to = {{PAGE_ID}}, package_name = {{FORM_NAME_UC}}) and one INSERT into
MIG_OBJECT_MAP per row of the traceability matrix (columns as in
scripts/create_migration_registry.sql; status MAPPED / DROPPED / TODO / MANUAL), ending with COMMIT.

## Constraints
- APEX 21.2 features only (see CLAUDE.md §2). No generated export code in this step.
- Do not duplicate business logic: validations/processes call {{FORM_NAME_UC}}.
- No `pkg_`, `AI_`, dot-notation component names or page-level toolbar buttons in the spec.
- When finished, print: pages, regions, items, validations, processes, DAs, and TODOs.
```
