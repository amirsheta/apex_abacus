# IMPR2110 – Import notes (report page, f345 standard + report standard 13-b)

> ⚠️ **REVIEW BEFORE IMPORT.** Generated `wwv_flow_api` code is not an officially supported way to build APEX
> applications. Import into a **DEV** workspace first, back up application 202530, and review the page in
> Page Designer. **Not imported yet.**

Form `IMPR2110.fmb` «طباعة بيانات المستوردين» → page **2110** `IMPR2110` (report parameters; no search page).
Design: [IMPR2110_apex_page_spec.md](../../analysis/IMPR2110/IMPR2110_apex_page_spec.md). Generator: `scripts/gen_apex_impr2110.py`.

## 1. Files

| File | Content |
|---|---|
| `apex/IMPR2110/f345_impr2110.sql` | component export with the 4 placeholders |
| `apex/IMPR2110/f202530_impr2110_import.sql` | the same with workspace 23232323, application 202530, offset 460632461717563830, schema CUSTOMS |
| `plsql/IMPR2110/impr2110_spec.sql`, `impr2110_body.sql` | screen package `LIB_APX_USR.IMPR2110` **002** (previous: `rollback/IMPR2110/v001/`) |
| `plsql/IMPR2110/IMPR2110_ARD.pks`, `IMPR2110_ARD.pkb` | report package `LIB_APX_USR.IMPR2110_ARD` 001 (the RDF as an ARD report) |
| `scripts/report_toolbar.py` | page 0 buttons on report pages: PRINT, CLEAR, BACK (applied by `build_full_app.py`) |
| `plsql_templates/lov_apx.sql` | package `LOV_APX` **003** (`IMPORTERS` + optional `P_DEFAULT_PORT_ITEM`; previous `rollback/LOV_APX/v002/`) |
| `registry/IMPR2110_registry.sql` | MIG_FORM_REGISTRY / MIG_OBJECT_MAP rows |

Contents: 1 page, 3 regions (hero `TITLE`, static `CALLING_PARAMETERS`, read-only IG `CTR_BLK`), 10 items, 5 processes
(Before Header), 3 dynamic actions (3 FOS actions, **1 one-line JavaScript action** that opens the ardpdf link), 1 LOV.

Regenerate: `python3 -I scripts/gen_apex_impr2110.py --workspace-id=23232323 --app-id=202530 --id-offset=460632461717563830 --schema=CUSTOMS`
(the self-check must print `problems: none`).

## 2. Prerequisites

1. Application 202530 holds the **IMPR1110** export: page group IMPR `id(900001000010)`, LOV `LOV_SD_PORTS`.
2. **FORMS_APX 004** (`CHECK_ERROR`, `GET_MODULE_ID`, `HEADER_TITLE`).
3. **LOV_APX 003** compiled (`SELECT LOV_APX.PKG_VERSION FROM dual`). `CUSTOMS` needs SELECT on `IMPORTERS`, `SD_PORTS`.
   **003 renames the 8 functions used by one LOV only to the LOV name** (user decision 2026-11-25): `PORTS` → `LOV_SD_PORTS`,
   `PORTS_WITH_TYPES` → `LOV_SD_PORTS_TYPES`, `COUNTRIES` → `LOV_COUNTRIES`, `IMPORTER_TYPES` → `LOV_IMPR_TYPE`,
   `CITIES_OF_BUSINESS_ID` → `LOV_CITIES_IMP_ID`, `SINGLE_IMPORTERS` → `LOV_SINGLE_IMPORTERS`, `HARMONIZED_TARIFF` →
   `LOV_HARMONIZED_TARIFF`, `SUPPORT_TITLES` → `LOV_SUPP_TITLES`. The old names are gone, so an application that still holds
   the earlier IMPR1110 / IMPR1140 / SUPPORT_ENTRY exports gets "PLS-00302" in those LOVs. **Compile 003 and re-import
   those exports (or `apex/f202530_full.sql`) together.** All exports in `apex/` already call the new names.
4. **Report package `IMPR2110_ARD` 001** (`.pks`, then `.pkb`). It uses `ARD_LOGO` (static file `LOGO1.jpg` in the
   application, DEC-034; without it the ARD server logo link is used) and `HIJDATE_DB`. `LIB_APX_USR` needs SELECT on
   `IMPORTERS`, `HQ_IMPRS`, `IMPR_TYPES`, `PRIVILEGED_IMPORTERS`, `BUS_ID_TYPES`, `CITIES`, `SD_PORTS`. The ARD data source
   user (setting `ARD_DSNAME`) needs EXECUTE on `IMPR2110_ARD` (grants as `DCLN3300_ARD`; add the ARD user if it is not one of them).
5. **Screen package `IMPR2110` 002** (spec, then body). `LIB_APX_USR` needs SELECT on `IMPORTERS`, `HQ_IMPRS`,
   `SD_PORTS`, `SC_PORT_SETTING`. It no longer uses `SC_PORT_SETTINGS_PKG`.
6. `SC_PORT_SETTING` rows for the module (SYSOBJ_ID = `P2110_MODULE_ID`): `P_SYS_ID`, `P_REP_NO` (report number in the
   hero and the footer; without them it shows `-`).
   **ARD server settings** (required, no default in the code): run `migration/001_ard_settings.sql` - `SC_PORT_SETTING`
   rows SYSOBJ_ID 999, PORT_CD 99: `ARD_URL` = `http://stgnibrasapx01.myzatca.gov.sa:8001/ard/ardpdf`, `ARD_DSNAME` = `hqqaDS`
   (staging values; change `VAR_VALUE` per environment). Without them طباعة stops with «إعداد خادم التقارير غير موجود ...».
7. **Page 0 toolbar (PRINT, CLEAR, BACK on report pages):** included in `apex/f202530_full.sql` (`scripts/report_toolbar.py`).
   A component-only import has no page 0, so change it once by hand in Page Designer, page 0 → buttons:
   `REPORT_SHOW` Server-side Condition = *Never*; `CREATE` and `SEARCH` condition = the PL/SQL function body
   `report_toolbar.NOT_REPORT_PAGE` (P0_PAGE_PK null and the page has no `P<page>_REPORT` item).

## 3. Import

App Builder → Import → *Page or Component Export* → `apex/IMPR2110/f202530_impr2110_import.sql`. It removes and re-creates
page 2110 and creates `LOV_REP_IMPR` (IDs `2110…`, `9210…`, checked against f345 and every other export).
Full application (includes the page 0 toolbar change): `apex/f202530_full.sql`, rebuilt 2026-11-25 with
`python3 -I scripts/build_full_app.py --app-id=202530 --shift-ids=460632461717563830 apex/IMPR1110/f345_impr1110.sql apex/IMPR1120/f345_impr1120.sql apex/SUPPORT_ENTRY/f345_support_entry.sql apex/IMPR1116/f345_impr1116.sql apex/IMPR1125/f345_impr1125.sql apex/IMPR1130/f345_impr1130.sql apex/IMPR1140/f345_impr1140.sql apex/IMPR2110/f345_impr2110.sql`.
Importing it replaces application 202530.

## 4. After import – tests

1. Page 0 toolbar on 2110: **only طباعة, مسح, رجوع**. On a normal form page (e.g. 1110), CREATE and SEARCH still show with no record open.
2. Port user (P_CURR_PORT_CD ≠ 99): no port item; the hero shows the port name.
3. Head office (99): wrong port code → «رمز الجمرك غير صحيح»; a valid one fills the name.
4. One Popup LOV «رقم المستورد»: each importer picked is added once to the table «المستوردون المختارون» (number + name),
   and the LOV is empty again for the next pick. No picks → the report covers every importer of the port. CLEAR empties the table.
5. طباعة with no matching importer → «لا يوجد سجلات تحقق المطلوب», and no tab opens.
6. طباعة with matches → new tab with the PDF from ardpdf: landscape, header on every page (port, logo, title), one block
   per importer (مسلسل, نوع المستورد, نوع الاقامة + the 8 columns), footer with report number and dates, «صفحة X من Y».
   The rows must be exactly the listed importers (all importers of the port when the list is empty).
   **The browser may block the tab**: `window.open` runs after the AJAX call, as on f202604 page 2100. Allow
   pop-ups for the APEX host.
7. Direct check without APEX: `SELECT IMPR2110_ARD.ARD_IMPR2110('30', '1,2', 'test', '1-1') FROM dual;` returns the HTML.

## 5. Uncertain parameters (not in f345; check after import)

- DA on a custom event of `document`: `p_triggering_element_type JAVASCRIPT_EXPRESSION`, `p_triggering_element document`,
  `p_bind_event_type custom` + `p_bind_event_type_custom` (as the real 21.2 export f202604, page 2100).
- Static content region (control block) with the Form-region template *Interactive Report*.
- Read-only IG for the non-database multi-record block `CTR_BLK`, `p_rows_per_page` 5.
- Item display condition `p_display_when` / `p_display_when2 PLSQL` / `p_display_when_type EXPRESSION` (IMPR1110 uses it).
- `NATIVE_CLEAR` on an item (IMPR1120 uses it); DA client condition `NOT_NULL` (IMPR1110 uses it).
- Shared LOV `FUNC_BODY_RETURNING_SQL` (as every LOV_APX LOV).
