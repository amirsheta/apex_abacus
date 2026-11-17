# Getting Started — Forms 12c → APEX 21.2 with Claude Code

## 1. Set up the toolkit
1. Copy this folder into a Git repository; keep `CLAUDE.md` at the root (Claude Code reads it automatically).
2. Put sources in `input/fmb/`. On the Forms host:
   ```bash
   export FORMS_PATH=/path/input/fmb
   ./scripts/convert_forms_to_xml.sh input/fmb ./output      # -> output/xml/<form>_fmb.xml
   ```
3. Ask the DBA to run `scripts/setup_apex_workspace.sql` (Oracle 12.1.0.2 + APEX 21.2).
4. As the parsing schema, run once: `scripts/create_migration_registry.sql` and
   `plsql_templates/pkg_forms_compat.sql`. In the APEX app set
   Error Handling Function = `pkg_forms_compat.apex_error_handler`.
5. Read `docs/apex_structure_standard.md` (Forms-mirror naming: pages, regions, items, triggers).
6. Start Claude Code in the repository root: `claude`.

## 2. Workflow per form
| Step | Prompt template | Input | Output | Review gate |
|---|---|---|---|---|
| 1 | `prompt_templates/01_inventory_analysis.md` | `output/xml/<form>_fmb.xml` | `analysis/<form>/<form>_inventory.md` | Answer open questions, check counts |
| 2 | `02_logic_extraction.md` | inventory + XML | `pkg_<form>` spec/body + extraction report | Compile in DEV, fix errors |
| 3 | `03_apex_page_design.md` | inventory + extraction + spec | `<form>_apex_page_spec.md` | Business/lead approval |
| 4 | `04_apex_export_generation.md` | page spec (+ reference export) | `f<appid>_<form>.sql` | Import in DEV, review in Page Designer |
| 5 | `05_test_generation.md` | package + page spec | utPLSQL, UAT checklist, data compare | Tests green, UAT signed |

Open the template, replace the `{{...}}` fields, paste the content of the fenced block into Claude Code.
Commit after each step (`git commit -m "<form>: step N"`).

## 3. Managing context in Claude Code
- **One form per session**; run `/clear` between forms and between steps for large forms.
- Every step writes to files — the next step reads files, not chat history.
- Use `/compact` when a session grows; ask Claude to grep the XML instead of reading it whole.
- For very large forms, run step 1 per block ("analyse blocks ORDERS and LINES only") and merge.
- Keep `CLAUDE.md` short-lived rules there; per-form decisions go in `analysis/<form>/<form>_review_notes.md`.
- Ask for a summary of TODOs at the end of every step and record it in the review notes.

## 4. Forms that call other forms
- Inventory lists `CALL_FORM/OPEN_FORM/NEW_FORM` with parameters. Migrate **called (child) forms first** or reserve their page numbers in advance.
- `CALL_FORM` (modal return) → Modal Dialog page + "Dialog Closed" DA refreshing the caller.
- `NEW_FORM`/`OPEN_FORM` → branch/link to a normal page.
- Parameter lists → target page items set in the link (Session State Protection with checksum).
- `:GLOBAL` shared between forms → Application Items (document them once in `analysis/_shared/application_items.md`).

## 5. Libraries (.pll) and object libraries (.olb)
- Convert `.pll` to text: `frmcmp_batch module=lib.pll module_type=LIBRARY script=YES` → `lib.pld`.
- Migrate each library once as `pkg_lib_<name>` (spec/body) using prompt 02 adapted to the `.pld`
  file; strip Forms built-ins (UI parts become JS/DA guidelines).
- Migrate shared libraries **before** the forms that use them; forms prompts reference them via `SHARED PACKAGES`.
- `.olb` objects (property classes, visual attributes, standard toolbars) are not migrated as code:
  map them once to Theme/Template Options and a standard page template (buttons, regions), recorded in
  `analysis/_shared/olb_mapping.md`.
- `FORMS_PATH` must contain the `.olb/.pll` when running `frmf2xml`, or subclassed properties are missing.

## 6. Reference
- `docs/forms_to_apex_mapping.md` — object/built-in/trigger mapping
- `docs/migration_checklist.md` — gates and risk register
- `plsql_templates/` — package templates and Dynamic Action patterns
