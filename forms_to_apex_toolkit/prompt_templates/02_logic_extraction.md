# Prompt 02 — PL/SQL Logic Extraction

**When to use:** After `01_inventory_analysis` is complete and reviewed.
**Input:** `analysis/<form_name>/<form_name>_inventory.md` + `output/xml/<FORM_NAME>_fmb.xml`
**Output:**
- `plsql/<form_name>/pkg_<form_name>_spec.sql`
- `plsql/<form_name>/pkg_<form_name>_body.sql`
- `analysis/<form_name>/<form_name>_logic_extraction.md`

---

```text
You are working on the Oracle Forms 12c → Oracle APEX 21.2 migration project.
Follow all rules in CLAUDE.md.

TASK: Extract all portable business logic from ONE form into a PL/SQL package.

FORM NAME:       {{FORM_NAME}}
INVENTORY:       analysis/{{FORM_NAME}}/{{FORM_NAME}}_inventory.md
XML FILE:        output/xml/{{FORM_NAME}}_fmb.xml
PACKAGE NAME:    pkg_{{FORM_NAME}}
TEMPLATES:       plsql_templates/pkg_template_spec.sql, plsql_templates/pkg_template_body.sql
SHARED PACKAGES: {{LIST_OF_EXISTING_PKG_LIB_PACKAGES_OR_NONE}}

## Step 1 — Collect trigger code
Read the inventory first. Then, from the XML, re-extract the full decoded code of every
trigger and program unit (TriggerText / ProgramUnitText attributes; decode &#10; &apos;
&quot; &lt; &gt; &amp;). Do not rely on summaries.

## Step 2 — Classify every trigger
Put each trigger in exactly one group (split a trigger if it mixes concerns and say so):

| Group | Typical triggers | Target |
|---|---|---|
| VALIDATION | WHEN-VALIDATE-ITEM, WHEN-VALIDATE-RECORD, KEY-COMMIT checks | Package function returning error text / raising; APEX Validation |
| PRE/POST DML | PRE-INSERT, PRE-UPDATE, PRE-DELETE, POST-INSERT, POST-UPDATE, POST-DELETE, ON-INSERT/UPDATE/DELETE, PRE-COMMIT, POST-FORMS-COMMIT | Package procedures; APEX processes |
| QUERY | PRE-QUERY, POST-QUERY, ON-SELECT, ON-FETCH | View / SQL function / package function |
| INITIALISATION | WHEN-NEW-FORM-INSTANCE, PRE-FORM, WHEN-CREATE-RECORD | wnfi / pre_form / <block>_wcr; Before Header process |
| NAVIGATION | WHEN-NEW-BLOCK-INSTANCE, WHEN-NEW-RECORD-INSTANCE, WHEN-NEW-ITEM-INSTANCE, KEY-NEXT-ITEM, KEY-* | APEX-DA comments |
| UI-ONLY | SET_ITEM_PROPERTY, SET_WINDOW_PROPERTY, SHOW_VIEW, visual attributes, MESSAGE | APEX-DA comments |
| BUTTON ACTIONS | WHEN-BUTTON-PRESSED | Split: business part → procedure; UI part → APEX-DA |

## Step 3 — Identify Forms built-ins to replace
Produce a table: | Trigger | Line | Built-in | Replacement (per CLAUDE.md §7) | Where it goes (PL/SQL / DA / Process / Branch) |
Cover at least: GO_BLOCK, GO_ITEM, GO_RECORD, SET_ITEM_PROPERTY, SET_BLOCK_PROPERTY,
GET_ITEM_PROPERTY, SHOW_ALERT, MESSAGE, EXECUTE_QUERY, ENTER_QUERY, COMMIT_FORM,
CLEAR_BLOCK, CLEAR_FORM, CALL_FORM, OPEN_FORM, NEW_FORM, NAME_IN, COPY,
CREATE_GROUP, POPULATE_GROUP, GET_GROUP_*_CELL, HOST, TEXT_IO, RUN_REPORT_OBJECT,
FORM_TRIGGER_FAILURE, :SYSTEM.*, :GLOBAL.*, :PARAMETER.*.

## Step 4 — Generate the package
Start from plsql_templates/pkg_template_spec.sql and pkg_template_body.sql.
Follow docs/apex_structure_standard.md (Forms-mirror):
- Package layout mirrors the form: FORM LEVEL section → one section per BLOCK (in Forms
  block order) → PROGRAM UNITS (same names as in Forms) → UI LOGIC comments.
- Member names = <object>_<trigger_abbr> (customer_id_wvi, orders_wvr, orders_pre_ins,
  orders_post_qry, btn_post_wbp, wnfi ...). Every name ≤ 30 bytes (DB 12.1.0.2).
- Keep the original Forms trigger code as a comment above each member ("Original Forms code:").
- Use pkg_forms_compat for MESSAGE / FORM_TRIGGER_FAILURE / stop alerts / :GLOBAL / USER
  so the converted code reads like the original.

Rules:
1. Remove every Forms built-in. Item references (:BLOCK.ITEM) become parameters
   (p_<item>) or record fields (t_<block>_rec) — NEVER bind variables to page items
   inside the package. The package must be testable without an APEX session.
   Exception: pkg_forms_compat.app_user / get_global may be used anywhere (they also work
   outside APEX, so tests still run).
2. Validation procedures: either
   a) FUNCTION <item>_wvi(p_value ...) RETURN VARCHAR2 — returns NULL if OK or the
      error message (maps to APEX "PL/SQL Function Body (returning Error Text)"), or
   b) PROCEDURE <block>_wvr(p_rec IN t_<block>_rec) that calls pkg_forms_compat.ftf / alert.
   Choose (a) for item-level checks, (b) for record-level checks.
3. MESSAGE + RAISE FORM_TRIGGER_FAILURE → pkg_forms_compat.ftf('<text>');
   SHOW_ALERT (stop) + FTF → pkg_forms_compat.alert('<ALERT_NAME>') and list the alert as a
   Text Message to create (name = alert name, text = alert message).
4. SHOW_ALERT whose result drives logic (e.g. "Are you sure?") → split: the question
   becomes "-- APEX-DA: Confirm ..." and the branch after the answer becomes a procedure.
5. :GLOBAL.x → pkg_forms_compat.get_global('X') / set_global('X', v); record in the
   extraction doc that it becomes Application Item AI_X.
6. POST-QUERY lookups → prefer a function usable in SQL (fnc_ / pkg function marked
   for use in the region query or a view v_<form>_<block>). Flag N+1 patterns.
7. Sequences in PRE-INSERT → keep in <block>_pre_ins (p_rec.id := seq.NEXTVAL is valid on
   12.1), or note "use identity / DEFAULT seq.NEXTVAL — confirm with DBA". Do not change the table.
8. Every procedure has a header comment: purpose, `-- Source: <LEVEL.OWNER.TRIGGER>`,
   parameters, errors raised.
9. Every UI-only/navigation fragment is preserved as a comment block:
     -- APEX-DA: [Source: BLOCK.ITEM.WHEN-LIST-CHANGED]
     -- Original: SET_ITEM_PROPERTY('ORDERS.DISCOUNT', ENABLED, PROPERTY_FALSE);
     -- Implement as: Dynamic Action on P10_ORDER_TYPE change → Disable P10_DISCOUNT
   Collect these in a dedicated section at the END of the body named
   "UI LOGIC FOR APEX DYNAMIC ACTIONS" (no executable code there).
10. No COMMIT/ROLLBACK inside the package (APEX manages the transaction), unless the
    original code explicitly commits in an autonomous context — then flag it HIGH.
11. Library calls → call pkg_lib_<library>.<proc>; if that package doesn't exist yet,
    add "-- TODO: MISSING SOURCE pkg_lib_<library>.<proc>" and list it.
12. Must compile on Oracle **12.1.0.2** (CLAUDE.md §2a): identifiers ≤ 30 bytes, no qualified
    expressions, no JSON_OBJECT/JSON_OBJECT_T, no LISTAGG ON OVERFLOW, no 12.2+/18c+ syntax.
13. Spec and body must be consistent (same signatures, same order).

## Step 5 — Write the extraction report
analysis/{{FORM_NAME}}/{{FORM_NAME}}_logic_extraction.md containing:
1. Trigger classification table (trigger → group → package member / DA / dropped + reason)
2. Built-in replacement table (Step 3)
3. Package member list with source trigger
4. Error code table (-20xxx → message → source)
5. UI logic list for Dynamic Actions (feeds prompt 03)
6. Globals/parameters → Application Items / page items
7. Dropped logic (with justification) and TODOs / missing sources

## Output
- plsql/{{FORM_NAME}}/pkg_{{FORM_NAME}}_spec.sql
- plsql/{{FORM_NAME}}/pkg_{{FORM_NAME}}_body.sql
- analysis/{{FORM_NAME}}/{{FORM_NAME}}_logic_extraction.md

## Self-check before finishing
- grep the generated .sql files for: GO_BLOCK|GO_ITEM|SET_ITEM_PROPERTY|SHOW_ALERT|
  EXECUTE_QUERY|FORM_TRIGGER_FAILURE|:SYSTEM\.|:GLOBAL\.|NAME_IN|COPY\( — matches are
  only allowed inside comments.
- Every trigger from the inventory appears in the classification table.
- Print a summary: members created, triggers mapped, DA items, TODO count.
```
