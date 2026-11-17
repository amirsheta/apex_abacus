# Prompt 01 — Inventory Analysis of a Forms XML File

**When to use:** First step for every form, after running `scripts/convert_forms_to_xml.sh`.
**Input:** `output/xml/<FORM_NAME>_fmb.xml`
**Output:** `analysis/<form_name>/<form_name>_inventory.md`

Replace the `{{...}}` placeholders, then paste everything below the line into Claude Code.

---

```text
You are working on the Oracle Forms 12c → Oracle APEX 21.2 migration project.
Follow all rules in CLAUDE.md.

TASK: Produce a complete inventory and migration risk assessment for ONE form.

FORM NAME:   {{FORM_NAME}}            (e.g. orders)
XML FILE:    output/xml/{{FORM_NAME}}_fmb.xml
OUTPUT FILE: analysis/{{FORM_NAME}}/{{FORM_NAME}}_inventory.md

## How to read the XML
The file is frmf2xml output. It may be large — do NOT load it in one read.
1. First get an overview with grep counts of these elements:
   <Block, <Item, <Trigger, <LOV, <RecordGroup, <Canvas, <Window, <ProgramUnit,
   <Alert, <ModuleParameter, <AttachedLibrary, <ObjectGroup, <Relation, <VisualAttribute
2. Then read each section in chunks by line range.
3. Trigger code is in the TriggerText attribute (XML-escaped: &#10; = newline,
   &apos; = ', &quot; = ", &lt; = <, &gt; = >, &amp; = &). Decode it when quoting code.
4. Note subclassed objects (ParentModule / ParentName attributes) — their properties
   may come from an .olb that is not in the XML.

## Extract the following (all of it — do not summarise away items)

### A. Module header
- Form name, title, first navigation block, console window, menu module (MenuModule),
  validation unit, interaction mode, coordinate system.

### B. Blocks (one table row per block)
| Block | Base table / Query data source (DMLDataTargetName / QueryDataSourceName) |
  Type (base-table / control / procedure-based / FROM-clause query) | Records displayed |
  WHERE clause | ORDER BY | Insert/Update/Delete/Query allowed | Canvas |

### C. Items per block (one table per block)
| Item | Item type (Text, List, Checkbox, Radio, Button, Display, Image, Chart...) |
  Data type | Max length | Column name | Database item (Y/N) | Required | LOV |
  Default value | Format mask | Canvas / tab page | Visible | Copy-value-from / calculation |

### D. Relations (master–detail)
| Relation | Master block | Detail block | Join condition | Delete behaviour | Coordination |

### E. Triggers — ALL of them
Group by level (Form / Block / Item). For each trigger:
- Name, level, owner (FORM | BLOCK | BLOCK.ITEM), execution hierarchy
- Line count
- Full decoded code in a ```plsql block
- Built-ins used (GO_BLOCK, SET_ITEM_PROPERTY, SHOW_ALERT, EXECUTE_QUERY, CALL_FORM, ...)
- Program units / library procedures called

### F. LOVs and Record Groups
| LOV | Record group | Query (decoded) or static values | Return items (column → item) |
  Validate from list | Auto-display |
Also list record groups NOT attached to an LOV, and any created at runtime
(CREATE_GROUP / POPULATE_GROUP in triggers).

### G. Canvases and Windows
| Canvas | Type (Content / Stacked / Tab / Toolbar) | Window | Tab pages | Items shown |
| Window | Modal | Title | Size |

### H. Program units
| Name | Type (procedure/function/package spec/body) | Lines | Called by | Uses built-ins |
Include decoded code.

### I. External dependencies
- Attached libraries (.pll) and which procedures from each are called
- Called forms (CALL_FORM / OPEN_FORM / NEW_FORM) with parameter lists passed
- Reports (RUN_REPORT_OBJECT / RUN_PRODUCT), HOST calls, WEB.SHOW_DOCUMENT
- Database objects referenced (tables, views, sequences, packages, DB links)
- Object library / subclassed objects

### J. Alerts
| Alert | Style (Stop/Caution/Note) | Title | Message | Buttons | Where used |

### K. Parameters and globals
| Parameter | Data type | Default | Where used |
List every :GLOBAL.* variable read or written and every :SYSTEM.* variable used.

### L. Menu / security
- Menu module, roles, SET_MENU_ITEM_PROPERTY usage, any user/role checks in triggers.

## Complexity classification
Classify the form as Simple / Medium / Complex using this rubric and show the counts:
| Metric | Simple | Medium | Complex |
|---|---|---|---|
| Data blocks | 1–2 | 3–5 | > 5 |
| Triggers (total) | < 15 | 15–50 | > 50 |
| Lines of PL/SQL (triggers + program units) | < 300 | 300–1500 | > 1500 |
| Master–detail relations | 0–1 | 2–3 | > 3 |
| Called forms / libraries | 0 | 1–3 | > 3 |
| Special features (HOST, TEXT_IO, OLE, Java beans, timers, charts, RUN_REPORT) | none | 1 | ≥ 2 |
The highest category reached by 2 or more metrics wins. Justify in 2–3 sentences.
Give a rough effort estimate (developer-days) labelled as an ESTIMATE.

## Migration risk assessment
Produce a table:
| # | Risk item | Location (trigger/object) | Level (High/Medium/Low) | Reason | Proposed APEX approach |
Guidelines:
- HIGH: HOST/TEXT_IO/CLIENT_* calls, OLE/ActiveX/Java beans/PJCs, timers, complex
  POST-QUERY loops (N+1), cross-form globals driving logic, RUN_REPORT_OBJECT,
  record-by-record cursor navigation logic, missing library source, dynamic SQL,
  DB-level commits inside triggers, locking logic (ON-LOCK).
- MEDIUM: SET_ITEM_PROPERTY at runtime, multi-level master-detail, runtime record
  groups, ON-* transactional triggers, KEY-* overrides, CALL_FORM with parameters.
- LOW: simple validations, LOV mappings, default values, format masks.

## Output file structure
analysis/{{FORM_NAME}}/{{FORM_NAME}}_inventory.md with headings:
1. Summary (complexity, counts, effort estimate)
2. Module header
3. Blocks  4. Items  5. Relations  6. Triggers  7. LOVs & Record Groups
8. Canvases & Windows  9. Program Units  10. External Dependencies
11. Alerts  12. Parameters & Globals  13. Menu & Security
14. Risk Assessment  15. Open Questions / Missing Sources

## Constraints
- Do not generate any PL/SQL packages or APEX code in this step.
- Do not guess code that is not in the XML; mark it "MISSING SOURCE".
- When finished, print: file path written, complexity, number of High risks,
  and the list of open questions.
```
