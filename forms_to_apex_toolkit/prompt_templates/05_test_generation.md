# Prompt 05 — Test Generation (utPLSQL, UAT, Data Comparison)

**When to use:** After the package compiles (step 02) — can run in parallel with steps 03/04.
**Input:** inventory, extraction report, package spec/body, page spec
**Output:**
- `tests/<form_name>/test_<form_name>.sql` (utPLSQL package `TEST_<FORM>`)
- `tests/<form_name>/uat_checklist_<form_name>.md`
- `tests/<form_name>/data_compare_<form_name>.sql`

Prerequisite: utPLSQL v3 installed in the test database (`ut.version()` returns 3.x).
Standard: the package under test is `<FORM>` (f345, `CLAUDE.md` §4b); its APEX entry points take
`I_` / `IO_` parameters named after the page binds.

---

```text
You are working on the Oracle Forms 12c → Oracle APEX 21.2 migration project.
Follow all rules in CLAUDE.md (especially §4b, the f345 reference standard).

TASK: Generate tests for ONE migrated form.

FORM NAME:     {{FORM_NAME}}
INVENTORY:     analysis/{{FORM_NAME}}/{{FORM_NAME}}_inventory.md
EXTRACTION:    analysis/{{FORM_NAME}}/{{FORM_NAME}}_logic_extraction.md
PACKAGE:       plsql/{{FORM_NAME}}/{{FORM_NAME}}_spec.sql / _body.sql   (package {{FORM_NAME_UC}})
PAGE SPEC:     analysis/{{FORM_NAME}}/{{FORM_NAME}}_apex_page_spec.md
LEGACY SCHEMA: {{LEGACY_SCHEMA}}     (schema used by the Forms application)
NEW SCHEMA:    {{NEW_SCHEMA}}        (parsing schema of the APEX application)
DB LINK:       {{DB_LINK_OR_NONE}}   (if legacy and new data are in different DBs)

## Part 1 — utPLSQL unit tests: tests/{{FORM_NAME}}/test_{{FORM_NAME}}.sql
Generate a utPLSQL v3 test package TEST_{{FORM_NAME_UC}} (spec + body in one file):
- Spec annotations: --%suite({{FORM_NAME_UC}} – migrated from Forms {{FORM_NAME}})
  --%suitepath(forms_migration.{{FORM_NAME}}), --%rollback(auto)
- --%beforeall / --%beforeeach setup procedures that insert minimal test data
  (use negative or high-range IDs, never touch real rows); --%aftereach cleanup is
  not needed with --%rollback(auto) but document it.
- For EVERY public procedure/function in the spec, at least:
  * one happy-path test
  * one test per validation rule / error code in the error-code table, using
    --%throws(-20xxx) for expected exceptions
  * boundary tests (NULL inputs, max length, zero/negative numbers, date boundaries)
- PRE_INSERT / PRE_UPDATE (and <BLOCK_ABBR>_PRE_INSERT …) tests assert the IO_ values they
  return (sequence values, audit columns, defaults) with ut.expect(...).to_equal(...).
- <ITEM>_VAL functions: one test returning NULL (valid) and one per error text; CHK raises
  when given an error text (--%throws(-20001)); REQUIRED_VAL for NULL / blank / value.
- <ITEM>_WVI procedures: assert every IO_ / O_ value they derive.
- POST-QUERY / lookup functions: assert returned descriptions for known and unknown keys.
- FORMS_COMPAT.ftf / alert raise -20000 → use --%throws(-20000).
- Tests must compile on DB 12.1.0.2 (no qualified expressions; identifiers ≤ 30 bytes).
  Check that the installed utPLSQL v3 release supports 12.1 before installing.
- Tests must not depend on an APEX session: call the members with literal I_ values (e.g.
  I_SSO_APP_USER => 'TEST_USER', I_P_CURR_PORT_CD => 1); use apex_session.create_session only
  in a clearly marked optional test. Globals (G_<NAME>) work outside APEX through
  FORMS_COMPAT.get_global / set_global.
- Name each test with --%test(<description referencing the original Forms trigger>).
- Finish the file with:
    -- Run: exec ut.run('test_{{FORM_NAME}}');
    -- CI:  utplsql run user/***@db -p=test_{{FORM_NAME}} -f=ut_junit_reporter -o=junit.xml
  (no real passwords).

## Part 2 — UAT checklist: tests/{{FORM_NAME}}/uat_checklist_{{FORM_NAME}}.md
Written for BUSINESS USERS (no technical jargon). Structure:
1. Header: form name, APEX page(s), tester, date, environment, build version
2. Preconditions (test users/roles, test data needed)
3. Test cases table:
   | # | Area | Steps (numbered, plain language) | Old Forms behaviour | Expected APEX behaviour | Result (Pass/Fail) | Comments |
   Cover, for every block:
   - Open screen / initial values (WHEN-NEW-FORM-INSTANCE)
   - Query/search (Forms Enter Query → Execute Query vs the toolbar SEARCH button and the
     search page <page>01: type, click the number, the record opens)
   - Create, update, delete records with the toolbar buttons CREATE / SAVE / DELETE (incl.
     master-detail); the toolbar switches between CREATE and SAVE / DELETE
   - Every validation message (show the exact old message and the new one)
   - Every LOV (values, filtering, returned fields)
   - Every button, every function in the FUNCS list, and every alert/confirmation
   - Navigation to/from called forms
   - Security: user without privilege cannot see/do the action
   - Keyboard/usability differences (F7/F8 → SEARCH, Ctrl+S / F10 → CREATE or SAVE, F9 → FUNCS,
     Clear Form → CLEAR, Exit → BACK) — list explicitly
   - Printing/reports if any
4. Known intentional differences (from extraction "dropped logic" and page spec)
5. Sign-off block (business owner, date, decision: Accepted / Accepted with issues / Rejected)

## Part 3 — Data comparison: tests/{{FORM_NAME}}/data_compare_{{FORM_NAME}}.sql
A SQL*Plus/SQLcl script that validates the new system produces the same data:
- Header with substitution variables (&legacy_schema, &new_schema, &db_link) — no
  credentials.
- For each base table of the form:
  * row counts in both systems
  * MINUS in both directions on business columns (exclude technical/audit columns,
    list exclusions in a comment)
  * aggregate checks (SUM/COUNT per status, per key date) for numeric/monetary columns
  * ORA_HASH/STANDARD_HASH-based checksum per row grouped by primary key for large tables
- "Same input → same output" scenario: a section that runs the legacy logic (if it
  exists as DB code) and the new package for the same inputs into a temp table, then
  compares results (template — mark TODO where legacy logic lived only in Forms).
- Results written to a table migration_compare_results(run_id, form_name, check_name,
  status, legacy_value, new_value, run_date) — include its CREATE TABLE in a commented
  "one-time setup" section with matching rollback DROP.
- Final query summarising PASS/FAIL counts.

## Constraints
- Do not modify application tables; tests insert data only inside rolled-back transactions.
- No credentials anywhere.
- Print summary: number of unit tests, UAT cases, comparison checks, and TODOs.
```
