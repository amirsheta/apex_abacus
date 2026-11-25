# IMPR1170 – Import notes (step 04, f345 standard)

> ⚠️ **REVIEW BEFORE IMPORT.** `f345_impr1170.sql` is generated `wwv_flow_api` code. That is **not** an officially
> supported way to build APEX applications. Import it into a **DEV** workspace only, export (back up) the target
> application first, and open both pages in Page Designer afterwards. **Status: NOT IMPORTED, package NOT COMPILED.**

| Item | Value |
|---|---|
| Form | IMPR1170 (module `IMPR1170_CNTRL`) – بيانات السجل التجارى من وزارة التجارة (MCI_DATA + MCI_OWNERS) |
| Standard | f345 (`apex/Reference/f345.sql`), `CLAUDE.md` §4b–§4d, `docs/f345_reference_standard.md` |
| Target | Oracle APEX 21.2 (export version `2021.10.15`), Oracle Database 12.1.0.2, application 202530 |
| Pages | 1170 `IMPR1170`, 117001 `IMPR1170_SEARCH` (page group `IMPR` of the IMPR1110 export) |

## 1. Files

| File | What it is |
|---|---|
| `apex/IMPR1170/f345_impr1170.sql` | The component export (1,513 lines) with the four `__…__` placeholders |
| `apex/IMPR1170/f202530_impr1170_import.sql` | Import-ready copy: workspace 23232323, application 202530, ID offset 460632461717563830, schema `CUSTOMS` |
| `apex/f202530_full.sql` | Full application (f345 + all converted forms, IMPR1170 included) built by `scripts/build_full_app.py` |
| `scripts/gen_apex_impr1170.py` | The generator **and** the design data (ITEMS, PROCESSES, DAS …). Re-run after a design change; do not edit the `.sql` |
| `work/IMPR1170/step03/build_spec.py`, `build_trace.py` | Render the page spec and `registry/IMPR1170_registry.sql` |
| `work/IMPR1170/step04/generator_output.txt`, `uncertain.json` | Last generator run (`problems: none`) |
| `plsql/IMPR1170/impr1170_spec.sql`, `impr1170_body.sql` | Package `IMPR1170` 001 |

Generator counts: 2 pages, 5 regions, 20 items, 2 buttons, 0 validations, 11 processes, 5 DAs / 6 actions (0 FOS,
**0 JavaScript actions**), 1 computation, 2 branches, 2 IGs (owners 8 columns, search 8 columns); no shared LOV, Text Message,
application item, page group or authorization scheme is created.

## 2. Prerequisites (in this order)

1. **IMPR1110 export imported** (page group `IMPR`, Application Setting `HIJRI_DATE_FORMAT`) and **IMPR1130 export imported**
   (`LOV_COMM_RGSTRTN_TYPE`, used by CR_TYPE by name).
2. Packages compiled as `LIB_APX_USR`: `FORMS_APX` 004, **`IMPR1170` 001** (no change to `LOV_APX`).
3. Grants to LIB_APX_USR (definer rights): `SELECT` on `MCI_DATA`, `MCI_BUS_ID_STATUS`; `EXECUTE` on
   `LIB_USR.PRTL_NEBRAS_SERVICES` (**MISSING SOURCE**: `CALL_WEB_SERVICE`, called as in Forms; its network ACL to
   `10.0.0.214:8080` belongs to its owner and is unchanged).
   The parsing schema CUSTOMS needs `SELECT` on `MCI_DATA`, `MCI_OWNERS`, `MCI_RELATION_TYPES`, `MCI_BUS_ID_STATUS`, `CG_REF_CODES`.
4. Page 0 `NUMBER ONLY` DA and `FUNCS` drawer: present in `apex/f202530_full.sql`; for a component-only import add them
   to page 0 once by hand (as for the other forms).

## 3. Import

Full application (recommended, as 2026-11-18): App Builder → Import `apex/f202530_full.sql` (replaces application 202530).
Component only: SQL Workshop / SQLcl, `@apex/IMPR1170/f202530_impr1170_import.sql`.

## 4. Parameters f345 does not show (check in Page Designer after the import)

See `work/IMPR1170/step04/uncertain.json`. The ones that matter most:

| Parameter | Why it is uncertain | What to check |
|---|---|---|
| Form region on table `MCI_DATA`, not editable, primary key item `P1170_CR_NBR` (VARCHAR2) | IMPR1150 used an SQL source | a record opened from the search page or after the look-up shows every column |
| Submit Page `EXECUTE_QUERY` from the change DA + branch with request condition | IMPR1150 pattern | typing a number and leaving the field loads the record; a wrong number shows the service error |
| `p_read_only_when` PL/SQL expression `:P0_PAGE_PK IS NOT NULL` on CR_NBR | f345 shows the pattern only for display conditions | CR_NBR cannot be changed on a shown record; CLEAR makes it enterable again |
| read-only IG MCI_OWNERS with Page Items to Submit `P1170_CR_NBR` | as IMPORTER_DOCS of page 1150 | the owners of the shown registration are listed with the relation name |
| CR_TYPE default `1` on an always read-only Select List | Forms initial value | the empty page shows "رئيسي"; a shown record shows its own type |

## 5. Test after the import (UAT)

1. Open page 1170: empty record, CR_NBR enterable.
2. Type a CR number **loaded today** (MCI_DATA.LST_TRAN_DT = today) and leave the field → the record and its owners are shown
   without a service call (check the service log).
3. Type a CR number not in MCI_DATA, or loaded on an earlier day → the service is called (`.../mciImp/99/<CR_NBR>`); on
   `success` the refreshed record is shown; otherwise "بيانات السجل التجارى رقم … حالتة غير فعال أو بياناتة غير متاحة …".
4. A cached row with LST_TRAN_DT empty → nothing is shown and the service is not called (as Forms; `-- SUGGESTION:` in the package).
5. Status description (MCI_BUS_ID_STATUS), CR_TYPE text, Hijri issue date in the application format, owners with relation names.
6. Page 0 CREATE / SAVE / DELETE → refusal messages (decision to confirm, inventory §15 #1). SEARCH → find by number or name
   → open: the record is shown from the cache (no service call). CLEAR → new look-up.

## 6. Open points

Inventory §15: insert from the form (refused, to confirm), web-service package source and address per environment, table DDL,
module title.
