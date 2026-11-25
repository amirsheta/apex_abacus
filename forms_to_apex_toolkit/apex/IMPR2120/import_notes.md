# IMPR2120 – Import notes (report page, f345 standard + report standard 13-b)

> ⚠️ **REVIEW BEFORE IMPORT.** Generated `wwv_flow_api` code is not an officially supported way to build APEX
> applications. Import into a **DEV** workspace first, back up application 202530, and review the page in
> Page Designer. **Not imported yet.**

Form `IMPR2120.fmb` «توقيفات المستوردين» → page **2120** `IMPR2120` (report parameters; no search page).
Design: [IMPR2120_apex_page_spec.md](../../analysis/IMPR2120/IMPR2120_apex_page_spec.md). Generator: `scripts/gen_apex_impr2120.py`.

## 1. Files

| File | Content |
|---|---|
| `apex/IMPR2120/f345_impr2120.sql` | component export with the 4 placeholders |
| `apex/IMPR2120/f202530_impr2120_import.sql` | the same with workspace 23232323, application 202530, offset 460632461717563830, schema CUSTOMS |
| `plsql/IMPR2120/impr2120_spec.sql`, `impr2120_body.sql` | screen package `LIB_APX_USR.IMPR2120` **001** |
| `plsql/IMPR2120/IMPR2120_ARD.pks`, `IMPR2120_ARD.pkb` | report package `LIB_APX_USR.IMPR2120_ARD` 001 (the RDF as an ARD report, `scripts/gen_ard_impr_reports.py`) |
| `scripts/report_toolbar.py` | page 0 buttons on report pages: PRINT, CLEAR, BACK (applied by `build_full_app.py`) |
| `registry/IMPR2120_registry.sql` | MIG_FORM_REGISTRY / MIG_OBJECT_MAP rows |

Contents: 1 page, 3 regions (hero `TITLE`, static `CALLING_PARAMETERS`, read-only IG `CTR_BLK`), 11 items (incl. Select List `P2120_P_TYPE`), 5 processes
(Before Header), 3 dynamic actions (3 FOS actions, **1 one-line JavaScript action** that opens the ardpdf link), 1 LOV (`LOV_IMPR2120_REP_IMPR`).

Regenerate: `python3 -I scripts/gen_apex_impr2120.py --workspace-id=23232323 --app-id=202530 --id-offset=460632461717563830 --schema=CUSTOMS`
(the self-check must print `problems: none`).

## 2. Prerequisites

1. Application 202530 holds the **IMPR1110** export: page group IMPR `id(900001000010)`, LOV `LOV_SD_PORTS`.
2. **FORMS_APX 004** (`CHECK_ERROR`, `GET_MODULE_ID`, `HEADER_TITLE`).
3. **LOV_APX 003** compiled (`SELECT LOV_APX.PKG_VERSION FROM dual`); no change for this form. `CUSTOMS` needs SELECT on `IMPORTERS`, `SD_PORTS`.
4. **Report package `IMPR2120_ARD` 001** (`.pks`, then `.pkb`). It uses `ARD_LOGO` (static file `LOGO1.jpg` in the
   application, DEC-034; without it the ARD server logo link is used) and `HIJDATE_DB`. `LIB_APX_USR` needs SELECT on `IMPORTERS`, `IMPR_SUSPNS`, `SD_PORTS` (see `IMPR2120_ARD.pkb`). The ARD data source
   user (setting `ARD_DSNAME`) needs EXECUTE on `IMPR2120_ARD` (grants as `DCLN3300_ARD`; add the ARD user if it is not one of them).
5. **Screen package `IMPR2120` 001** (`impr2120_spec.sql`, then `impr2120_body.sql`). `LIB_APX_USR` needs SELECT on `IMPORTERS`,
   `IMPR_SUSPNS`, `SD_PORTS`, `SC_PORT_SETTING` and EXECUTE on `FORMS_APX` (`CUR_HIJ_DATE` → `HIJDATE_DB`).
6. `SC_PORT_SETTING` rows for the module (SYSOBJ_ID = `P2120_MODULE_ID`): `P_SYS_ID`, `P_REP_NO` (report number in the
   hero and the footer; without them it shows `-`).
   **ARD server settings** (required, no default in the code): run `migration/001_ard_settings.sql` - `SC_PORT_SETTING`
   rows SYSOBJ_ID 999, PORT_CD 99: `ARD_URL` = `http://stgnibrasapx01.myzatca.gov.sa:8001/ard/ardpdf`, `ARD_DSNAME` = `hqqaDS`
   (staging values; change `VAR_VALUE` per environment). Without them طباعة stops with «إعداد خادم التقارير غير موجود ...».
7. **Page 0 toolbar (PRINT, CLEAR, BACK on report pages):** included in `apex/f202530_full.sql` (`scripts/report_toolbar.py`).
   A component-only import has no page 0, so change it once by hand in Page Designer, page 0 → buttons:
   `REPORT_SHOW` Server-side Condition = *Never*; `CREATE` and `SEARCH` condition = the PL/SQL function body
   `report_toolbar.NOT_REPORT_PAGE` (P0_PAGE_PK null and the page has no `P<page>_REPORT` item).

## 3. Import

App Builder → Import → *Page or Component Export* → `apex/IMPR2120/f202530_impr2120_import.sql`. It removes and re-creates
page 2120 and creates `LOV_IMPR2120_REP_IMPR` (IDs `2120…`, `9212…`, checked against f345 and every other export).
Full application (includes the page 0 toolbar change): `apex/f202530_full.sql`, rebuilt 2026-11-25 with every export in `apex/*/f345_*.sql` including `apex/IMPR2120/f345_impr2120.sql` (command in the file header).
Importing it replaces application 202530.

## 4. After import – tests

1. Page 0 toolbar on 2120: **only طباعة, مسح, رجوع**. On a normal form page (e.g. 1110), CREATE and SEARCH still show with no record open.
2. Port user (P_CURR_PORT_CD ≠ 99): no port item; the hero shows the port name.
3. Head office (99): wrong port code → «رمز الجمرك غير صحيح»; a valid one fills the name.
4. One Popup LOV «رقم المستورد»: each importer picked is added once to «المستوردون المختارون» (number + name); the LOV is
   empty again for the next pick. No picks → the report covers every importer of the port. CLEAR empties the table.
5. «حالة التوقيف» shows ساري / غير ساري / ساري وغير ساري, default «ساري وغير ساري» (3).
6. طباعة with no matching suspension (e.g. ساري for an importer with only released suspensions) → «لا يوجد سجلات تحقق المطلوب», no tab.
7. طباعة with matches → new tab with the PDF from ardpdf: landscape, header on every page, one block per importer
   (جهة التوقيف, مسلسل, الرقم الاستدلالى, رقم الفرع, اسم المستورد) with its suspensions (بداية / نهاية التوقيف, حالة التوقيف,
   تاريخ الحذف, السبب), footer with report number, dates and «صفحة X من Y». Rows must match the status chosen.
   **The browser may block the tab** (window.open after AJAX): allow pop-ups for the APEX host.
8. Direct check without APEX: `SELECT IMPR2120_ARD.ARD_IMPR2120('30', '1,2', '3', 'test', '1-1') FROM dual;` returns the HTML.

## 5. Uncertain parameters (not in f345; check after import)

- DA on a custom event of `document`: `p_triggering_element_type JAVASCRIPT_EXPRESSION`, `p_triggering_element document`,
  `p_bind_event_type custom` + `p_bind_event_type_custom` (as the real 21.2 export f202604, page 2100).
- Select List `P2120_P_TYPE` with an inline `STATIC2` LOV (`p_lov`), no null entry.
- Static content region (control block) with the Form-region template *Interactive Report*.
- Read-only IG for the non-database multi-record block `CTR_BLK`, `p_rows_per_page` 5.
- Item display condition `p_display_when` / `p_display_when2 PLSQL` / `p_display_when_type EXPRESSION` (IMPR1110 uses it).
- `NATIVE_CLEAR` on an item (IMPR1120 uses it); DA client condition `NOT_NULL` (IMPR1110 uses it).
- Shared LOV `FUNC_BODY_RETURNING_SQL` (as every LOV_APX LOV).
