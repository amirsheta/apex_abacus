# IMPR1160 – Import notes (step 04, f345 standard)

> ⚠️ **REVIEW BEFORE IMPORT.** `f345_impr1160.sql` is generated `wwv_flow_api` code. That is **not** an officially
> supported way to build APEX applications. Import it into a **DEV** workspace only, export (back up) the target
> application first, and open both pages in Page Designer afterwards. **Status: NOT IMPORTED, packages NOT COMPILED.**

| Item | Value |
|---|---|
| Form | IMPR1160 (title `IMPR1160_ND_CNTRL`) – استثناء المستوردين الافراد للسيارات |
| Standard | f345 (`apex/Reference/f345.sql`), `CLAUDE.md` §4b–§4d, `docs/f345_reference_standard.md` |
| Target | Oracle APEX 21.2 (export version `2021.10.15`), Oracle Database 12.1.0.2, application 202530 |
| Pages | 1160 `IMPR1160`, 116001 `IMPR1160_SEARCH` (page group `IMPR` of the IMPR1110 export) |

## 1. Files

| File | What it is |
|---|---|
| `apex/IMPR1160/f345_impr1160.sql` | The component export (1,777 lines) with the four `__…__` placeholders |
| `apex/IMPR1160/f202530_impr1160_import.sql` | Import-ready copy: workspace 23232323, application 202530, ID offset 460632461717563830, schema `CUSTOMS` |
| `apex/f202530_full.sql` | Full application (f345 + all converted forms, IMPR1160 included) built by `scripts/build_full_app.py` |
| `scripts/gen_apex_impr1160.py` | The generator **and** the design data (ITEMS, PROCESSES, DAS …). Re-run after a design change; do not edit the `.sql` |
| `work/IMPR1160/step03/build_spec.py`, `build_trace.py` | Render the page spec and `registry/IMPR1160_registry.sql` |
| `work/IMPR1160/step04/generator_output.txt`, `uncertain.json` | Last generator run (`problems: none`) |
| `plsql/IMPR1160/impr1160_spec.sql`, `impr1160_body.sql` | Package `IMPR1160` 001 |
| `plsql_templates/lov_apx.sql` | Package `LOV_APX` **004** (previous: `rollback/LOV_APX/v003/lov_apx.sql`) |

Generator counts: 2 pages, 4 regions, 23 items, 2 buttons, 4 validations, 14 processes, 9 DAs / 12 actions (5 FOS,
**0 JavaScript actions**), 1 computation, 1 branch, 1 IG (search, 11 columns), 3 shared LOVs, 5 Text Messages; no application
item, page group or authorization scheme is created.

## 2. Prerequisites (in this order)

1. **IMPR1110 export imported** (page group `IMPR`, Application Setting `HIJRI_DATE_FORMAT`) and **IMPR1140 export imported**
   (`LOV_REC_STATUS`, used by STATUS by name).
2. Packages compiled as `LIB_APX_USR`: `FORMS_APX` 004, **`LOV_APX` 004** (new `IMPORTERS` parameters, new `LOV_IMPR_DCLTN`;
   existing calls are unchanged), **`IMPR1160` 001**.
3. Grants to LIB_APX_USR (definer rights): `SELECT` on `IMPR_CAR_EXCEPTION`, `IMPORTERS`, `IMPR_SUSPNS`, `SD_PORTS`,
   `DECLARATIONS`, `DCLTN_ITEMS`, `STATS_DCLTNS`, `STATS_ITEMS`, `GROUP_ITEMS`; `EXECUTE` on `GNRL` (**MISSING SOURCE**:
   `GET_SEQUENCE_VALUE`, `GET_CUSTOMS_SETTING`, called as in Forms) and `HIJDATE_DB`.
   The parsing schema CUSTOMS needs `SELECT, INSERT, UPDATE, DELETE` on `IMPR_CAR_EXCEPTION` and `SELECT` on `IMPORTERS`,
   `DECLARATIONS`, `STATS_DCLTNS`, `CG_REF_CODES` (LOVs, search page) – Forms users already had these through their roles.
4. Page 0 `NUMBER ONLY` DA and `FUNCS` drawer: present in `apex/f202530_full.sql`; for a component-only import add them
   to page 0 once by hand (as for the other forms).

## 3. Import

Full application (recommended, as 2026-11-18): App Builder → Import `apex/f202530_full.sql` (replaces application 202530).
Component only: SQL Workshop / SQLcl, `@apex/IMPR1160/f202530_impr1160_import.sql`.

## 4. Parameters f345 does not show (check in Page Designer after the import)

See `work/IMPR1160/step04/uncertain.json`. The ones that matter most:

| Parameter | Why it is uncertain | What to check |
|---|---|---|
| Form region ROWID key, `i:u:d` | as IMPR1140 | a new exception is saved and re-opened; DELETE works after opening one |
| `p_read_only_when` PL/SQL expression `:P0_PAGE_PK IS NOT NULL` | f345 shows the pattern only for display conditions | on an opened exception only STATUS can be changed |
| not displayed DATE columns as Display Only + `u-hidden` + format mask | as IMPR1110 LST_TRAN_DT | ENTRY_DT (date and time) and EXPTN_START_DT (today, Hijri) are stored |
| Popup LOV `LOV_IMPR_DCLTN` with Items to Submit `P1160_DCLTN_TYPE, P1160_IMPR_NBR` | function-body LOV | the list shows the importer's declarations of the chosen type |
| FOS returning into Display Only / Hidden items | IMPR1140 pattern | IMPR_NAME, DCLTN_DT, DCLTN_ISN / STATS_ISN, NO_OF_CARS filled after the choice |

## 5. Test after the import (UAT)

1. New record: PORT_CD / name of the user's port are shown. Pick an importer of type 4 from the list → name shown, focus on
   نوع البيان. A suspended importer → "هذا المستورد موقوف " (also refused at CREATE).
2. نوع البيان 1, pick a declaration → date, number of cars (tariff group 76) filled. A number that does not exist →
   "رقم البيان او  تاريخه ... غير معرف ...". Repeat with type 2 (statistical declaration).
3. رقم المراسلة 0 or negative → message; text that is not a number → Oracle error text (as Forms). Wrong Hijri date → message.
   عدد السيارات 0 → message.
4. CREATE → exception number from `IMPR_CAR_EXPTN_SEQ`, ENTRY_DT now, EXPTN_START_DT today (Hijri), DCLTN_ISN / STATS_ISN set.
   Same declaration again → "لقد تم استثناء هذا البيان من قبل ".
5. SEARCH → open the exception: only STATUS enterable. Set 0 → SAVE works. Open it again, SAVE → "غير مسموح بتعديل الحالة ...".
6. DELETE an exception (confirmation of page 0) – decide whether this must stay (inventory §15 #2).

## 6. Open points

Inventory §15: suspension check at save (decided, to confirm), delete, query scope (all ports), declaration type 3, table DDL,
GNRL source, constraint texts.
