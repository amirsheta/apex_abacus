# IMPR1150 – Import notes (step 04, revision 1, f345 standard)

> ⚠️ **REVIEW BEFORE IMPORT.** `f345_impr1150.sql` is generated `wwv_flow_api` code. That is **not** an officially
> supported way to build APEX applications. Import it into a **DEV** workspace only, export (back up) the target
> application first, and open both pages in Page Designer afterwards. **Status: NOT IMPORTED, package NOT COMPILED.**

| Item | Value |
|---|---|
| Form | IMPR1150 (XML module `IMPR1150_PROD_CENTRL`) – تفعيل المستوردين من منصة فسح |
| Standard | f345 (`apex/Reference/f345.sql`), `CLAUDE.md` §4b–§4d, `docs/f345_reference_standard.md` |
| Target | Oracle APEX 21.2 (export version `2021.10.15`), Oracle Database 12.1.0.2, application 202530 |
| Pages | 1150 `IMPR1150`, 115001 `IMPR1150_SEARCH` (page group `IMPR` of the IMPR1110 export) |

## 1. Files

| File | What it is |
|---|---|
| `apex/IMPR1150/f345_impr1150.sql` | The component export (1,849 lines) with the four `__…__` placeholders |
| `apex/IMPR1150/f202530_impr1150_import.sql` | Import-ready copy: workspace 23232323, application 202530, ID offset 460632461717563830, schema `CUSTOMS` |
| `apex/f202530_full.sql` | Full application (f345 + all converted forms, IMPR1150 included) built by `scripts/build_full_app.py` |
| `scripts/gen_apex_impr1150.py` | The generator **and** the design data (ITEMS, PROCESSES, DAS …). Re-run after a design change; do not edit the `.sql` |
| `work/IMPR1150/step03/build_spec.py`, `build_trace.py` | Render the page spec and `registry/IMPR1150_registry.sql` |
| `work/IMPR1150/step04/generator_output.txt`, `uncertain.json` | Last generator run (`problems: none`) |
| `plsql/IMPR1150/impr1150_spec.sql`, `impr1150_body.sql` | Package `IMPR1150` 001 |

Generator counts: 2 pages, 5 regions, 30 items, 2 buttons, 2 validations, 13 processes, 9 DAs / 16 actions (2 FOS,
**0 JavaScript**), 2 computations, 2 branches, 2 IGs (documents 6 columns, search 7 columns), 2 shared LOVs; no application
item, page group or authorization scheme is created.

## 2. Prerequisites (in this order)

1. **IMPR1110 export imported** (page group `IMPR`, Application Setting `HIJRI_DATE_FORMAT`).
2. **Database link `HQPRD.HQ.CUSTOMS.GOV`** (user decision 2026-11-25: the form keeps reading and updating the HQ table
   through the link):
   - the parsing schema **CUSTOMS** must be able to query `CUSTOMS.IMPORTERS_CENTRAL@HQPRD.HQ.CUSTOMS.GOV` (Form region of
     page 1150, search grid of 115001) – Forms used the same link, so it probably exists;
   - **LIB_APX_USR** (definer-rights package) needs its own or a public link of that name; a private link owned by CUSTOMS
     is **not** usable by LIB_APX_USR. The remote user must have `SELECT` and `UPDATE` on `CUSTOMS.IMPORTERS_CENTRAL`.
   - DBA task: check `ALL_DB_LINKS` as both users before compiling.
3. Packages compiled as `LIB_APX_USR`: `FORMS_APX` 004, `LOV_APX` (current, `REFERENCE_CODES`), **`IMPR1150` 001**.
   Grants to LIB_APX_USR: `SELECT` on `IMPR_TYPES`, `BUS_ID_TYPES`, `COUNTRIES`, `CITIES`, `IMPORTERS_CENTRAL`; `EXECUTE` on
   `LIB_USR.ACTIVITY_DB`. CUSTOMS needs `SELECT` on `IMPORTERS_DOCS`, `IMPR_TYPES`, `CG_REF_CODES`.
4. **Functions in the security system:** `IMPR1150_ACTIVATE` and `IMPR1150_REJECT` must be rows of `SC_SYSTEM_OBJECTS`
   under the screen IMPR1150 with `SYS_OS_FILE_NAME` = the event name (that is how the f345 Page Functions list raises
   the custom event the page listens to). Check that the existing Forms rows use these codes.
5. Page 0 `NUMBER ONLY` DA and `FUNCS` drawer: present in `apex/f202530_full.sql`; for a component-only import add them
   to page 0 once by hand (as for the other forms).

## 3. Import

Full application (recommended, as 2026-11-18): App Builder → Import `apex/f202530_full.sql` (replaces application 202530).
Component only: SQL Workshop / SQLcl, `@apex/IMPR1150/f202530_impr1150_import.sql`.

## 4. Parameters f345 does not show (check in Page Designer after the import)

See `work/IMPR1150/step04/uncertain.json`. The ones that matter most:

| Parameter | Why it is uncertain | What to check |
|---|---|---|
| Form region `p_query_type` SQL over a database link, `p_is_editable` false | AGR1100 uses TABLE / editable | the page opens a record from the search page; items IMPR_NBR / BUS_ID are enterable on an empty page |
| `p_read_only_when` PL/SQL expression `:P0_PAGE_PK IS NOT NULL` | f345 shows the pattern only for display conditions | IMPR_NBR / BUS_ID read-only when a record is shown |
| DA client condition `$v('P1150_REJCT_RESON') === ''` with True / False actions | not in f345 | first REJECT: field shown + alert; second REJECT with a reason: request IMPR1150_REJECT |
| `NATIVE_SHOW` / `NATIVE_HIDE` / `NATIVE_SET_FOCUS` / `NATIVE_ALERT` | f345 hides a region only | REJCT_RESON hidden on load |
| search IG without a primary-key column | IMPR_NBR is unique at PORT_CD 99 | the grid loads |

## 5. Test after the import (UAT)

1. As a user of port 99: type an importer number that is pending at HQ → the record and its documents are shown;
   a number that is not pending → message 9-150.
2. Same with a business id (BUS_ID).
3. FUNCS → تفعيل المستورد: status becomes 1, message "تم تفعيل المستورد", the functions disappear; activity row type 1.
4. FUNCS → رفض: first press shows "سبب رفض التفعيل" and the alert; type a reason, press again → status 2, message
   "تم إيقاف تفعيل المستورد"; activity row type 2. **Check the column written** (inventory §15 #2).
5. SAVE with a reason typed → "برجاء استخدام وظيفة رفض تفعيل المستورد"; CREATE / DELETE → refused.
6. As a user of another port: the page shows no record (block WHERE PORT_CD = P_CURR_PORT_CD), as in Forms.

## 6. Open points

TODO open a document (OPEN_DEC / HOST), rejection reason column, functions on an empty record, message texts – inventory §15.
