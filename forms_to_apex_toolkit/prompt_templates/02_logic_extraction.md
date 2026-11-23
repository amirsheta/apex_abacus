# Prompt 02 — PL/SQL Logic Extraction

**When to use:** After `01_inventory_analysis` is complete and reviewed.
**Input:** `analysis/<form_name>/<form_name>_inventory.md` + `output/xml/<FORM_NAME>_fmb.xml`
**Standard:** f345 reference application (`CLAUDE.md` §4b, `docs/f345_reference_standard.md` §5):
the package is named after the form, in upper case and with no prefix.
**Output:**
- `plsql/<form_name>/<form_name>_spec.sql` (package `<FORM>`)
- `plsql/<form_name>/<form_name>_body.sql`
- `analysis/<form_name>/<form_name>_logic_extraction.md`

---

```text
You are working on the Oracle Forms 12c → Oracle APEX 21.2 migration project.
Follow all rules in CLAUDE.md (especially §4b, the f345 reference standard).

TASK: Extract all portable business logic from ONE form into a PL/SQL package.

FORM NAME:       {{FORM_NAME}}
INVENTORY:       analysis/{{FORM_NAME}}/{{FORM_NAME}}_inventory.md
XML FILE:        output/xml/{{FORM_NAME}}_fmb.xml
PACKAGE NAME:    {{FORM_NAME_UC}}      (upper-case form name, no pkg_ prefix - f345: AGR1100)
MAIN PAGE NO.:   {{PAGE_ID}}           (from MIG_FORM_REGISTRY; page items P<page>_<ITEM>, passed as parameters P_<ITEM>)
TEMPLATES:       plsql_templates/pkg_template_spec.sql, plsql_templates/pkg_template_body.sql
                 (rename the template package to {{FORM_NAME_UC}})
NAMING RULES:    docs/f345_reference_standard.md §5 and §6
SHARED PACKAGES: {{LIST_OF_EXISTING_LIB_PACKAGES_OR_NONE}}

## Step 1 — Collect trigger code
Read the inventory first. Then, from the XML, re-extract the full decoded code of every
trigger and program unit (TriggerText / ProgramUnitText attributes; decode &#10; &apos;
&quot; &lt; &gt; &amp;). Do not rely on summaries.

## Step 2 — Classify every trigger
Put each trigger in exactly one group (split a trigger if it mixes concerns and say so):

| Group | Typical triggers | Target |
|---|---|---|
| VALIDATION | WHEN-VALIDATE-ITEM, WHEN-VALIDATE-RECORD, KEY-COMMIT checks | `<ITEM>_VALIDATION` function returning error text; APEX validation `<ITEM> VALIDATION` + DA `<ITEM> WHEN-VALIDATE-ITEM` |
| PRE/POST DML | PRE-INSERT, PRE-UPDATE, PRE-DELETE, POST-INSERT, POST-UPDATE, POST-DELETE, ON-INSERT/UPDATE/DELETE, PRE-COMMIT, POST-FORMS-COMMIT | `PRE_INSERT` … (master) / `<BLOCK>_PRE_INSERT` … (detail); APEX processes `PRE-INSERT` / `<BLOCK> PRE-INSERT` |
| QUERY | PRE-QUERY, POST-QUERY, ON-SELECT, ON-FETCH | View / SQL function / package function |
| INITIALISATION | WHEN-NEW-FORM-INSTANCE, PRE-FORM, WHEN-CREATE-RECORD | `INIT_FORM` / `PRE_FORM` / `<BLOCK>_WHEN_CREATE_RECORD`; Before Header processes |
| NAVIGATION | WHEN-NEW-BLOCK-INSTANCE, WHEN-NEW-RECORD-INSTANCE, WHEN-NEW-ITEM-INSTANCE, KEY-NEXT-ITEM, KEY-* | APEX-DA comments |
| UI-ONLY | SET_ITEM_PROPERTY, SET_WINDOW_PROPERTY, SHOW_VIEW, visual attributes, MESSAGE | APEX-DA comments |
| BUTTON ACTIONS | WHEN-BUTTON-PRESSED | Split: business part → procedure; UI part → APEX-DA. Toolbar buttons (SAVE, REMOVE, ENTER-QUERY, EXIT …) map to the **page 0 toolbar** of f345, not to page buttons |

## Step 3 — Identify Forms built-ins to replace
Produce a table: | Trigger | Line | Built-in | Replacement (per CLAUDE.md §7) | Where it goes (PL/SQL / DA / Process / Branch) |
Cover at least: GO_BLOCK, GO_ITEM, GO_RECORD, SET_ITEM_PROPERTY, SET_BLOCK_PROPERTY,
GET_ITEM_PROPERTY, SHOW_ALERT, MESSAGE, EXECUTE_QUERY, ENTER_QUERY, COMMIT_FORM,
CLEAR_BLOCK, CLEAR_FORM, CALL_FORM, OPEN_FORM, NEW_FORM, NAME_IN, COPY,
CREATE_GROUP, POPULATE_GROUP, GET_GROUP_*_CELL, HOST, TEXT_IO, RUN_REPORT_OBJECT,
FORM_TRIGGER_FAILURE, :SYSTEM.*, :GLOBAL.*, :PARAMETER.*.

## Step 4 — Generate the package {{FORM_NAME_UC}}
Start from plsql_templates/pkg_template_spec.sql and pkg_template_body.sql.
Package header and installation (CLAUDE.md §3.2), exactly as in the template:
- Owner LIB_APX_USR: CREATE OR REPLACE PACKAGE LIB_APX_USR.{{FORM_NAME_UC}} AS ...
- The spec starts with the version block (V_PKG_VERSION / _QC / _DEV = 'VERSION NO. IS:' || '001',
  FUNCTION PKG_VERSION, V_PACKAGE_NAME = '{{FORM_NAME_UC}}', V_LAST_MODIFY_DT = today DD-MM-YYYY,
  V_MODIFIED_BY, V_INFO). The body ends with PKG_VERSION returning V_INFO.
- The spec file ends with the public synonym {{FORM_NAME_UC}} and GRANT EXECUTE to LIB_USR,
  SECURITY_DEFAULT, SECURITY_PROD and CUSTOMS.
- List in the extraction report every table / package the code uses: LIB_APX_USR needs a direct
  grant on each (definer rights).
Layout (docs/f345_reference_standard.md §10), one banner comment per section, same order in spec and body:
VERSION → f345 HELPERS → FORM LEVEL → one section per BLOCK in Forms block order (query → record →
items in Forms navigation order, each with POST_CHANGE / VALIDATION / WHEN_VALIDATE_ITEM /
IS_READ_ONLY / IS_REQUIRED → DML → buttons) → PROGRAM UNITS (Forms names, Forms order) →
PRIVATE HELPERS (body, top) → UI LOGIC FOR APEX DYNAMIC ACTIONS (body end, comments only).
Write the code for a reader: one Forms trigger = one member, about 80 lines at most; shared code
goes into a private helper named by what it does.

Member names (f345 standard §5; every name ≤ 30 bytes, DB 12.1.0.2; upper case like AGR1100):
| Forms source | Member | Example |
|---|---|---|
| master-block DML trigger | `<TRIGGER>` with `_` for `-` | `PRE_INSERT`, `POST_UPDATE`, `PRE_DELETE` |
| detail-block DML trigger | `<BLOCK>_<TRIGGER>` | `AGRMNT_MEMBERS_PRE_INSERT` |
| WHEN-VALIDATE-ITEM check | FUNCTION `<ITEM>_VALIDATION` (detail: `<BLOCK>_<ITEM>_VALIDATION`) returning error text or NULL | `CTRY_CD_VALIDATION`, `MEMBERS_CTRY_CD_VALIDATION` |
| WHEN-VALIDATE-ITEM side effects (derived values) | PROCEDURE `<ITEM>_WHEN_VALIDATE_ITEM` with IO_ parameters | `AGRMNT_NO_WHEN_VALIDATE_ITEM` |
| WHEN-VALIDATE-RECORD | FUNCTION `<BLOCK>_WHEN_VALIDATE_RECORD` returning error text | `AGRMNT_MEMBERS_VALIDATE_RECORD` |
| WHEN-NEW-FORM-INSTANCE / PRE-FORM | `INIT_FORM` / `PRE_FORM` | |
| program unit | same name as in Forms | `CALC_TOTAL` |
| f345 helpers (always generate) | `CHECK_ERROR(ERROR_TEXT)` raises when not null; `REQUIRED_VALIDATION(ITEM_VALUE, ITEM_LABEL)`; `P0_PAGE_PK_CHECK(P_PAGE_PK)`; `GET_MODULE_ID`; `HEADER_TITLE` | |
`<BLOCK>` = the FULL block name. Never abbreviate names (CLAUDE.md §4): no _wvi, _pre_ins, _post_chg,
CHK, _VAL, block short forms. Only a name longer than 30 bytes is shortened (drop WHEN_, then the
block part), and its full name goes in the member's comment. Forms program-unit and item names stay
exactly as in Forms.

Parameter names:
- Members called by APEX: the parameter is named after its bind, without an `I_` / `IO_` / `O_` prefix
  (the mode is IN / IN OUT / OUT). Page items P{{PAGE_ID}}_<ITEM> -> `P_<ITEM>`; the page item of a Forms
  parameter P{{PAGE_ID}}_P_<PARAM> -> `P_<PARAM>` (no doubled `P_P_`; when the member also takes the application
  item `P_<PARAM>`, that one is `APP_P_<PARAM>`); P0_PAGE_PK -> `P_PAGE_PK`; IG columns -> `<COLUMN>`;
  application items keep their name (e.g. `SSO_APP_USER => :SSO_APP_USER`, `P_CURR_PORT_CD => :P_CURR_PORT_CD`).
  Names that would be keywords get a full word (`ERROR_TEXT`, `ITEM_VALUE`, `ITEM_LABEL`). Inside every SQL
  statement qualify the parameter with its member name (`PRE_DELETE.P_<ITEM>`): an unqualified name that
  matches a column resolves to the column. The page passes every value as a named bind, so each APEX process
  stays a one-line call. Rule and checks: `scripts/parameter_names.py`.
- Internal-only members: `p_<name>`; local variables `v_`, constants `c_`, globals `g_`.

Keep the original Forms trigger code as a comment above each member ("Original Forms code:").
Use FORMS_APX for MESSAGE / FORM_TRIGGER_FAILURE / stop alerts / :GLOBAL / USER so the
converted code reads like the original.

Rules:
1. Remove every Forms built-in. Item references (:BLOCK.ITEM) become IN / IN OUT parameters (APEX
   entry points) or p_ parameters / record fields (internal) — NEVER v('P..') or bind variables
   to page items inside the package. The package must be testable without an APEX session.
   Exception: FORMS_APX.app_user / get_global may be used anywhere (they also work
   outside APEX, so tests still run).
2. Validations: `<ITEM>_VALIDATION` returns NULL if OK or the error message (APEX "PL/SQL Function
   Body returning Error Text", and `{{FORM_NAME_UC}}.CHECK_ERROR({{FORM_NAME_UC}}.<ITEM>_VALIDATION(...))` in
   the FOS dynamic action). Values the trigger derives go into `<ITEM>_WHEN_VALIDATE_ITEM` with IO_ params.
3. MESSAGE + RAISE FORM_TRIGGER_FAILURE → FORMS_APX.FORM_TRIGGER_FAILURE('<text>');
   SHOW_ALERT (stop) + FTF → FORMS_APX.alert('<ALERT_NAME>') and list the alert as a
   Text Message to create (name = alert name, text = alert message).
4. SHOW_ALERT whose result drives logic (e.g. "Are you sure?") → split: the question
   becomes "-- APEX-DA: Confirm ..." and the branch after the answer becomes a procedure.
5. :GLOBAL.x → FORMS_APX.get_global('X') / set_global('X', v); it becomes Application
   Item **G_X** (f345). :PARAMETER.P_X of the menu → reuse the f345 item when it exists
   (P_CURR_PORT_CD, P_CLASS_CD, P_PORT_TYPE, P_BRKR_NBR, SSO_APP_USER, V_USR_TYPE …), otherwise
   a new P_X. Never AI_. Record the mapping in the extraction doc.
6. POST-QUERY lookups → prefer a function usable in SQL (package function marked
   for use in the region query, or a view <FORM>_<BLOCK>_VIEW). Flag N+1 patterns.
7. Sequences in PRE-INSERT → keep in PRE_INSERT (IO_ key := seq.NEXTVAL is valid on 12.1),
   or note "use identity / DEFAULT seq.NEXTVAL — confirm with DBA". Do not change the table.
8. Every procedure has a header comment: purpose, `-- Source: <LEVEL.OWNER.TRIGGER>`,
   parameters, errors raised.
9. Every UI-only/navigation fragment is preserved as a comment block:
     -- APEX-DA: [Source: BLOCK.ITEM.WHEN-LIST-CHANGED] -> DA "ORDER_TYPE WHEN-LIST-CHANGED"
     -- Original: SET_ITEM_PROPERTY('ORDERS.DISCOUNT', ENABLED, PROPERTY_FALSE);
     -- Implement as: Dynamic Action on P{{PAGE_ID}}_ORDER_TYPE change → Disable P{{PAGE_ID}}_DISCOUNT
   Collect these in a dedicated section at the END of the body named
   "UI LOGIC FOR APEX DYNAMIC ACTIONS" (no executable code there).
10. No COMMIT/ROLLBACK inside the package (APEX manages the transaction), unless the
    original code explicitly commits in an autonomous context — then flag it HIGH.
11. Library calls → call LIB_<library>.<proc>; if that package doesn't exist yet,
    add "-- TODO: MISSING SOURCE LIB_<library>.<proc>" and list it.
12. Must compile on Oracle **12.1.0.2** (CLAUDE.md §2a): identifiers ≤ 30 bytes, no qualified
    expressions, no JSON_OBJECT/JSON_OBJECT_T, no LISTAGG ON OVERFLOW, no 12.2+/18c+ syntax.
13. Spec and body must be consistent (same signatures, same order).
14. One package per form, nothing else: no adapter package (no <FORM>_APX), no record of all
    block items read from / written to session state. Each member's signature lists exactly the
    items it reads (I_) and changes (IO_ / O_).
15. No UI state in PL/SQL: do not collect item properties (enabled / required / visible) in lists or
    JSON. Every Make_Field_Entrable / SET_ITEM_PROPERTY rule becomes a BOOLEAN function
    <ITEM>_IS_READ_ONLY / <ITEM>_IS_REQUIRED (or one per group of items that share the rule:
    <GROUP>_IS_READ_ONLY, full words) that APEX conditions call, plus an "-- APEX-DA:" comment
    saying which DA action uses it (docs/f345_reference_standard.md §9).

## Step 5 — Write the extraction report
analysis/{{FORM_NAME}}/{{FORM_NAME}}_logic_extraction.md containing:
1. Trigger classification table (trigger → group → package member / DA / dropped + reason)
2. Built-in replacement table (Step 3)
3. Package member list with source trigger and the f345 APEX component that will call it
   (`PRE-INSERT`, `CTRY_CD VALIDATION`, `CTRY_CD WHEN-VALIDATE-ITEM` …)
4. Error code table (-20xxx → message → source)
5. UI logic list for Dynamic Actions (feeds prompt 03)
6. Globals/parameters → Application Items (G_ / P_ / reused f345 items) / page items
7. Dropped logic (with justification) and TODOs / missing sources

## Output
- plsql/{{FORM_NAME}}/{{FORM_NAME}}_spec.sql   (package {{FORM_NAME_UC}})
- plsql/{{FORM_NAME}}/{{FORM_NAME}}_body.sql
- analysis/{{FORM_NAME}}/{{FORM_NAME}}_logic_extraction.md

## Self-check before finishing
- grep the generated .sql files for: GO_BLOCK|GO_ITEM|SET_ITEM_PROPERTY|SHOW_ALERT|
  EXECUTE_QUERY|FORM_TRIGGER_FAILURE|:SYSTEM\.|:GLOBAL\.|NAME_IN|COPY\( — matches are
  only allowed inside comments.
- grep for `pkg_{{FORM_NAME}}` and `AI_` — no matches (f345 naming).
- CHECK_ERROR and REQUIRED_VALIDATION exist; every name ≤ 30 bytes.
- No <FORM>_APX package, no v('P..') / apex_util.get_session_state in the package, no JSON / UI lists;
  every Make_Field_Entrable / SET_ITEM_PROPERTY has its _IS_READ_ONLY / _IS_REQUIRED function.
- Section banners present in the §10 order; report members longer than 80 lines.
- Owner LIB_APX_USR in spec and body; version block and PKG_VERSION present; synonym and the
  4 grants (LIB_USR, SECURITY_DEFAULT, SECURITY_PROD, CUSTOMS) at the end of the spec file.
- Every trigger from the inventory appears in the classification table.
- Print a summary: members created, triggers mapped, DA items, TODO count.
```
