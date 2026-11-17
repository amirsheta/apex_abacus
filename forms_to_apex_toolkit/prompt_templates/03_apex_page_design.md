# Prompt 03 — APEX 21.2 Page Design

**When to use:** After `02_logic_extraction` — the package compiles and the extraction report is reviewed.
**Input:** inventory, logic extraction report, package spec
**Output:** `analysis/<form_name>/<form_name>_apex_page_spec.md`

---

```text
You are working on the Oracle Forms 12c → Oracle APEX 21.2 migration project.
Follow all rules in CLAUDE.md. Use ONLY features available in APEX 21.2.

TASK: Design the complete APEX page structure for ONE form.

FORM NAME:       {{FORM_NAME}}
INVENTORY:       analysis/{{FORM_NAME}}/{{FORM_NAME}}_inventory.md
EXTRACTION:      analysis/{{FORM_NAME}}/{{FORM_NAME}}_logic_extraction.md
PACKAGE SPEC:    plsql/{{FORM_NAME}}/pkg_{{FORM_NAME}}_spec.sql
APPLICATION ID:  {{APP_ID}}
FIRST PAGE NO.:  {{START_PAGE_NUMBER}}       (range of 10 from MIG_FORM_REGISTRY, e.g. 120 → 120-129)
PAGE GROUP:      {{SUBSYSTEM}}               (Forms subsystem / menu group)
THEME:           Universal Theme (42)
AUTH SCHEME:     {{AUTHORIZATION_SCHEME_NAME}}
OUTPUT:          analysis/{{FORM_NAME}}/{{FORM_NAME}}_apex_page_spec.md
                 registry/{{FORM_NAME}}_registry.sql

## 0. Forms-mirror standard (MANDATORY — docs/apex_structure_standard.md)
- Main page = N0 (main canvas), alias {{FORM_NAME}} in upper case; dialogs N1–N5 (alias <FORM>_<CANVAS>).
- Region Static ID = Forms block name; region order = Forms block order; title = block/frame title.
- Item names keep the Forms item name: P<page>_<FORMS_ITEM>; IG column = Forms item name.
  Duplicate names across blocks → P<page>_<BLOCK_ABBR>_<ITEM>. Item order = Forms tab order.
- Validations / processes / DAs are NAMED with Forms trigger notation
  (<BLOCK>[.<ITEM>].<TRIGGER>) and call pkg_{{FORM_NAME}}.<object>_<trigger_abbr>.
- Every component's Comments = "Source: {{FORM_NAME}}.<BLOCK>.<ITEM>.<TRIGGER>".
- LOVs keep Forms LOV names; alerts → Text Messages with the alert name; :GLOBAL → AI_<NAME>;
  menu roles → Authorization Schemes ROLE_<ROLE>.
- Standard toolbar buttons in this order: SAVE · CREATE · DELETE · QUERY · CLEAR · EXIT.

## 1. Page type decision per block
Apply this decision table and document the reasoning per block:
| Forms block characteristics | APEX 21.2 choice |
|---|---|
| Single-record, base table, edit | Form region (native "Form", Automatic Row Processing) on a normal or Modal Dialog page |
| Multi-record, base table, inline editing, < ~30 columns | Interactive Grid (editable) |
| Multi-record, read-only / query and drill | Interactive Report (+ link to Form modal) |
| Simple list + edit, users prefer dialogs | Report + Form (Interactive Report page + Modal Dialog Form page) |
| Master single-record + detail multi-record | Master-Detail: Form region + editable IG on same page |
| Master multi-record + detail multi-record | Master-Detail: IG + IG (master-detail IG, "Master Region" set on detail) |
| 3-level master-detail | Stacked IGs or drill-down to a second page — justify |
| Control block (no base table) | Static Content region with page items (non-database) |
| Procedure-based / FROM-clause query block | IG/IR on a view or "SQL Query"; custom PL/SQL DML process |
| Stacked canvas / popup | Modal Dialog page or Inline Dialog region |
| Tab canvas | Regions in a "Tabs Container" template, or Region Display Selector |

## 2. Pages
For every page:
| Page No | Name | Page mode (Normal / Modal Dialog) | Source Forms canvas/window | Authorization | Navigation menu entry |

## 3. Regions (per page)
| Region | Type (Form / Interactive Grid / Interactive Report / Classic Report / Static Content / Faceted Search) |
  Source (table, view, or SQL — write the full SQL) | Primary key | Template | Parent region / position |
  Master region (for detail IGs) | Edit enabled (Add/Update/Delete) | Source Forms block |

## 4. Items (per region)
| Page item / IG column | Source column | Type (Text Field, Number Field, Date Picker, Select List,
  Popup LOV, Radio Group, Checkbox, Switch, Display Only, Hidden, Textarea, File Browse) |
  Label | Required | Format mask | Default (type + value) | LOV | Maximum length |
  Session State Protection | Source Forms item |
Rules: item names P<page>_<FORMS_ITEM_NAME> (see §0); Forms checkbox → Switch or Checkbox; Forms list item
→ Select List (static or shared LOV); Forms display item → Display Only; hidden/
non-displayed items → Hidden (Value Protected = Yes).

## 5. Buttons
| Button | Region | Position | Action (Submit Page / Redirect / Defined by DA) | Database action (SQL INSERT/UPDATE/DELETE) |
  Server-side condition | Authorization | Confirm message | Source (WHEN-BUTTON-PRESSED / KEY-*) |
Include standard CREATE / SAVE / DELETE / CANCEL as applicable.

## 6. LOVs
Map every Forms LOV/record group:
| Forms LOV | APEX LOV name (Shared Component LOV_<NAME>) or inline | Type (SQL / Static) |
  SQL (display_value, return_value) | Used by items | Item type (Select List / Popup LOV) |
  Cascading parent item(s) | Notes (multi-column return → set additional items via DA) |
Rule: < ~50 rows and no search → Select List; otherwise Popup LOV. Forms LOVs that
return more than one column: Popup LOV returns one value; set the extra items via a
DA "Set Value" (SQL) on change — document the DA.

## 7. Validations
Map every WHEN-VALIDATE-ITEM and WHEN-VALIDATE-RECORD:
| Validation name | Level (item / page / IG row) | Type (PL/SQL Function Body returning Error Text / Item is NOT NULL / ...) |
  Code (call to pkg_{{FORM_NAME}}.<item>_wvi / <block>_wvr) | Associated item | Error display location |
  Condition (When button pressed / server-side) | Source trigger |
For IG validations use :COLUMN bind syntax and "Editable Region" set to the IG.

## 8. Processes
| Process | Point (Before Header / After Submit / Processing) | Sequence | Type |
  Code | Condition (button / request) | Success / error message | Source trigger |
Mapping rules:
- PRE-INSERT / PRE-UPDATE / PRE-DELETE → "Execute Code" process BEFORE the
  "Automatic Row Processing (DML)" / "Interactive Grid - Automatic Row Processing" process,
  calling pkg_{{FORM_NAME}}.<block>_pre_ins/_pre_upd/_pre_del. For IGs, use a
  process with "Editable Region" set (runs per row, :APEX$ROW_STATUS = 'C'/'U'/'D').
  Alternatively set the DML process "Target Type" = PL/SQL Code — justify the choice.
- POST-INSERT / POST-UPDATE → process AFTER the DML process.
- POST-QUERY → preferably a column computed in the region SQL / view; else an
  "After Header" computation or process calling pkg_{{FORM_NAME}}.<block>_post_qry
  (single-record forms only). Never per-row PL/SQL in reports.
- WHEN-NEW-FORM-INSTANCE / PRE-FORM → Before Header process "WHEN-NEW-FORM-INSTANCE"
  calling pkg_{{FORM_NAME}}.wnfi / pre_form.
- WHEN-CREATE-RECORD defaults → item Default values or Before Header computation.

## 9. Computations
| Item | Point | Type | Expression | Condition | Source |

## 10. Dynamic Actions
From the "UI logic for Dynamic Actions" section of the extraction report:
| DA name | Event (Change / Click / Page Load / Dialog Closed) | Selection (item/button/region/jQuery) |
  Client-side condition | True actions (Show / Hide / Enable / Disable / Set Value /
  Refresh / Execute Server-side Code / Execute JavaScript Code / Confirm / Set Focus) |
  False actions | Items to submit / return | Fire on initialization | Source trigger |
Use the patterns in plsql_templates/dynamic_action_patterns.sql.

## 11. Alerts and messages
| Forms alert | Usage | APEX equivalent | Text |
Rules:
- Informational (Note) after success → process Success Message.
- Stop alert + FORM_TRIGGER_FAILURE → pkg_forms_compat.alert('<ALERT>') (Text Message with the alert name).
- Caution with Yes/No deciding an action → button "Confirm" behaviour or DA "Confirm"
  action / apex.message.confirm, followed by the server action.
- Text messages → Shared Components > Text Messages (for translation) where reused.

## 12. Branches and navigation
| Branch | Point | Target page | Condition | Items set | Source (CALL_FORM / NEW_FORM / GO_BLOCK) |
CALL_FORM with parameters → link/branch setting target page items (with checksum);
modal dialog → "Dialog Closed" DA to refresh the calling region.

## 13. Shared components required
Application items (from :GLOBAL), application processes, authorization schemes,
LOVs, lists (navigation menu), static application files, text messages.

## 14. Traceability matrix
| Forms object (block/item/trigger/LOV/alert) | APEX component | Status (mapped / dropped / TODO) |
EVERY object from the inventory must appear.

## 15. Registry script
Write registry/{{FORM_NAME}}_registry.sql: one INSERT into MIG_FORM_REGISTRY for the form and
one INSERT into MIG_OBJECT_MAP per row of the traceability matrix (columns as in
scripts/create_migration_registry.sql; status MAPPED / DROPPED / TODO / MANUAL), ending with COMMIT.

## Constraints
- APEX 21.2 features only (see CLAUDE.md §2). No generated export code in this step.
- Do not duplicate business logic: validations/processes call pkg_{{FORM_NAME}}.
- When finished, print: pages, regions, items, validations, processes, DAs, and TODOs.
```
