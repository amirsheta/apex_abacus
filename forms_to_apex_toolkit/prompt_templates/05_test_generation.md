# Prompt 05 — Test Generation (utPLSQL, UAT, Data Comparison)

**When to use:** After the package compiles (step 02) — can run in parallel with steps 03/04.
**Input:** inventory, extraction report, package spec/body, page spec
**Output:**
- `tests/<form_name>/test_pkg_<form_name>.sql`
- `tests/<form_name>/uat_checklist_<form_name>.md`
- `tests/<form_name>/data_compare_<form_name>.sql`

Prerequisite: utPLSQL v3 installed in the test database (`ut.version()` returns 3.x).

---

```text
You are working on the Oracle Forms 12c → Oracle APEX 21.2 migration project.
Follow all rules in CLAUDE.md.

TASK: Generate tests for ONE migrated form.

FORM NAME:     {{FORM_NAME}}
INVENTORY:     analysis/{{FORM_NAME}}/{{FORM_NAME}}_inventory.md
EXTRACTION:    analysis/{{FORM_NAME}}/{{FORM_NAME}}_logic_extraction.md
PACKAGE:       plsql/{{FORM_NAME}}/pkg_{{FORM_NAME}}_spec.sql / _body.sql
PAGE SPEC:     analysis/{{FORM_NAME}}/{{FORM_NAME}}_apex_page_spec.md
LEGACY SCHEMA: {{LEGACY_SCHEMA}}     (schema used by the Forms application)
NEW SCHEMA:    {{NEW_SCHEMA}}        (parsing schema of the APEX application)
DB LINK:       {{DB_LINK_OR_NONE}}   (if legacy and new data are in different DBs)

## Part 1 — utPLSQL unit tests: tests/{{FORM_NAME}}/test_pkg_{{FORM_NAME}}.sql
Generate a utPLSQL v3 test package test_pkg_{{FORM_NAME}} (spec + body in one file):
- Spec annotations: --%suite(pkg_{{FORM_NAME}} – migrated from Forms {{FORM_NAME}})
  --%suitepath(forms_migration.{{FORM_NAME}}), --%rollback(auto)
- --%beforeall / --%beforeeach setup procedures that insert minimal test data
  (use negative or high-range IDs, never touch real rows); --%aftereach cleanup is
  not needed with --%rollback(auto) but document it.
- For EVERY public procedure/function in the spec, at least:
  * one happy-path test
  * one test per validation rule / error code in the error-code table, using
    --%throws(-20xxx) for expected exceptions
  * boundary tests (NULL inputs, max length, zero/negative numbers, date boundaries)
- <block>_pre_ins/<block>_pre_upd tests assert derived columns (sequence values, audit
  columns, defaults) with ut.expect(...).to_equal(...).
- <block>_post_qry/lookup functions: assert returned descriptions for known and unknown keys.
- pkg_forms_compat.ftf / alert raise -20000 → use --%throws(-20000).
- Tests must compile on DB 12.1.0.2 (no qualified expressions; identifiers ≤ 30 bytes).
  Check that the installed utPLSQL v3 release supports 12.1 before installing.
- Tests must not depend on an APEX session; if a procedure reads APP_USER, set it with
  apex_session.create_session only in a clearly marked optional test, or pass the user
  as a parameter.
- Name each test with --%test(<description referencing the original Forms trigger>).
- Finish the file with:
    -- Run: exec ut.run('test_pkg_{{FORM_NAME}}');
    -- CI:  utplsql run user/***@db -p=test_pkg_{{FORM_NAME}} -f=ut_junit_reporter -o=junit.xml
  (no real passwords).

## Part 2 — UAT checklist: tests/{{FORM_NAME}}/uat_checklist_{{FORM_NAME}}.md
Written for BUSINESS USERS (no technical jargon). Structure:
1. Header: form name, APEX page(s), tester, date, environment, build version
2. Preconditions (test users/roles, test data needed)
3. Test cases table:
   | # | Area | Steps (numbered, plain language) | Old Forms behaviour | Expected APEX behaviour | Result (Pass/Fail) | Comments |
   Cover, for every block:
   - Open screen / initial values (WHEN-NEW-FORM-INSTANCE)
   - Query/search (Forms Enter Query → Execute Query vs APEX search/filter)
   - Create, update, delete records (incl. master-detail)
   - Every validation message (show the exact old message and the new one)
   - Every LOV (values, filtering, returned fields)
   - Every button and every alert/confirmation
   - Navigation to/from called forms
   - Security: user without privilege cannot see/do the action
   - Keyboard/usability differences (F7/F8, Ctrl+S → APEX buttons) — list explicitly
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
