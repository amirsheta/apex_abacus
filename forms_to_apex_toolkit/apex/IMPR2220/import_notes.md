# IMPR2220 – Import notes (report page, f345 standard + report standard 13-b)

> ⚠️ **REVIEW BEFORE IMPORT.** Generated `wwv_flow_api` code is not an officially supported way to build APEX
> applications. Import into a **DEV** workspace first, back up application 202530, and review the page in
> Page Designer. **Not imported yet.**

Form `IMPR2220.fmb` «تفويضات الشركات الوسيطة حسب الشركة» → page **2220** `IMPR2220` (report parameters; no search page).
Design: [IMPR2220_apex_page_spec.md](../../analysis/IMPR2220/IMPR2220_apex_page_spec.md). Generator: `scripts/gen_apex_impr2220.py`.

## 1. Files

| File | Content |
|---|---|
| `apex/IMPR2220/f345_impr2220.sql` | component export with the 4 placeholders |
| `apex/IMPR2220/f202530_impr2220_import.sql` | the same with workspace 23232323, application 202530, offset 460632461717563830, schema CUSTOMS |
| `plsql/IMPR2220/impr2220_spec.sql`, `impr2220_body.sql` | screen package `LIB_APX_USR.IMPR2220` **001** |
| `plsql/IMPR2220/IMPR2220_ARD_spec.sql`, `IMPR2220_ARD_body.sql` | report package `LIB_APX_USR.IMPR2220_ARD` 001 (the RDF as an ARD report, `scripts/gen_ard_impr_reports.py`) |
| `scripts/report_toolbar.py` | page 0 buttons on report pages: PRINT, CLEAR, BACK (applied by `build_full_app.py`) |
| `registry/IMPR2220_registry.sql` | MIG_FORM_REGISTRY / MIG_OBJECT_MAP rows |

Contents: 1 page, 3 regions (hero `TITLE`, static `CALLING_PARAMETERS`, read-only IG `CTR_BLK`), 10 items, 5 processes
(Before Header), 3 dynamic actions (3 FOS actions, **1 one-line JavaScript action** that opens the ardpdf link), 1 LOV (`LOV_IMPR2220_REP_IMPR`).

Regenerate: `python3 -I scripts/gen_apex_impr2220.py --workspace-id=23232323 --app-id=202530 --id-offset=460632461717563830 --schema=CUSTOMS`
(the self-check must print `problems: none`).

## 2. Prerequisites

1. Application 202530 holds the **IMPR1110** export: page group IMPR `id(900001000010)`, LOV `LOV_SD_PORTS`.
2. **FORMS_APX 004** (`CHECK_ERROR`, `GET_MODULE_ID`, `HEADER_TITLE`).
3. **LOV_APX 006** compiled (`SELECT LOV_APX.PKG_VERSION FROM dual`); no change for this form. `CUSTOMS` needs SELECT on `IMPORTERS`, `SD_PORTS`.
4. **Report package `IMPR2220_ARD` 001** (`_spec.sql`, then `_body.sql`). It uses `ARD_LOGO` (static file `LOGO1.jpg` in the
   application, DEC-034; without it the ARD server logo link is used) and `HIJDATE_DB`. `LIB_APX_USR` needs SELECT on `AGNTS`, `IMPORTERS`, `IMPR_TYPES`, `SD_PORTS` (see `IMPR2220_ARD_body.sql`). The ARD data source
   user (setting `ARD_DSNAME`) needs EXECUTE on `IMPR2220_ARD` (grants as `DCLN3300_ARD`; add the ARD user if it is not one of them).
5. **Screen package `IMPR2220` 001** (`impr2220_spec.sql`, then `impr2220_body.sql`). `LIB_APX_USR` needs SELECT on the same tables
   as `IMPR2220_ARD` plus `SC_PORT_SETTING`, and EXECUTE on `FORMS_APX`.
6. `SC_PORT_SETTING` rows for the module (SYSOBJ_ID = `P2220_MODULE_ID`): `P_SYS_ID`, `P_REP_NO` (report number in the
   hero and the footer; without them it shows `-`).
   **ARD server settings** (required, no default in the code): run `migration/001_ard_settings.sql` - `SC_PORT_SETTING`
   rows SYSOBJ_ID 999, PORT_CD 99: `ARD_URL` = `http://stgnibrasapx01.myzatca.gov.sa:8001/ard/ardpdf`, `ARD_DSNAME` = `hqqaDS`
   (staging values; change `VAR_VALUE` per environment). Without them طباعة stops with «إعداد خادم التقارير غير موجود ...».
7. **Page 0 toolbar (PRINT, CLEAR, BACK on report pages):** included in `apex/f202530_full.sql` (`scripts/report_toolbar.py`).
   A component-only import has no page 0, so change it once by hand in Page Designer, page 0 → buttons:
   `REPORT_SHOW` Server-side Condition = *Never*; `CREATE` and `SEARCH` condition = the PL/SQL function body
   `report_toolbar.NOT_REPORT_PAGE` (P0_PAGE_PK null and the page has no `P<page>_REPORT` item).

## 3. Import

App Builder → Import → *Page or Component Export* → `apex/IMPR2220/f202530_impr2220_import.sql`. It removes and re-creates
page 2220 and creates `LOV_IMPR2220_REP_IMPR` (IDs `2220…`, `9222…`, checked against f345 and every other export).
Full application (includes the page 0 toolbar change): `apex/f202530_full.sql`, rebuilt 2026-11-26 with every export in `apex/*/f345_*.sql` including `apex/IMPR2220/f345_impr2220.sql` (command in the file header).
Importing it replaces application 202530.

## 4. After import – tests

1. Page 0 toolbar on 2220: **only طباعة, مسح, رجوع**. On a normal form page (e.g. 1110), CREATE and SEARCH still show with no record open.
2. Port user (P_CURR_PORT_CD ≠ 99): no port item; the hero shows the port name.
3. Head office (99): wrong port code → «رمز الجمرك غير صحيح»; a valid one fills the name.
4. One Popup LOV «رقم الشركة الوسيطة» (importers of the report port - not port 30 as in Forms, spec §12 finding 2):
   each company picked is added once to «الشركات الوسيطة المختارة» (number + name); the LOV is empty again for the
   next pick. No picks → the report covers every brokerage company of the port. CLEAR empties the table.
5. طباعة for a company that is no agent in `AGNTS` (no row with `IMPR_NBR_AGENT_ID` = the company for the port)
   → «لا يوجد سجلات تحقق المطلوب», no tab.
6. طباعة with authorizations → new tab with the PDF from ardpdf: landscape, header on every page, one group per brokerage
   company (مسلسل الشركة, اسم الشركة الوسيطه, نوع الشركة الوسيطه) with its table (مسلسل التفويض, تاريخ انشاء التفويض, حالة التفويض,
   تاريخ حذف التفويض, مسلسل المستورد, اسم المستورد, نوع المستورد), footer with report number, dates and «صفحة X من Y».
   **The browser may block the tab** (window.open after AJAX): allow pop-ups for the APEX host.
7. Direct check without APEX: `SELECT IMPR2220_ARD.ARD_IMPR2220('30', '1,2', NULL, 'test', '1-1') FROM dual;` returns the HTML.

## 5. Uncertain parameters (not in f345; check after import)

- DA on a custom event of `document`: `p_triggering_element_type JAVASCRIPT_EXPRESSION`, `p_triggering_element document`,
  `p_bind_event_type custom` + `p_bind_event_type_custom` (as the real 21.2 export f202604, page 2100).
- Static content region (control block) with the Form-region template *Interactive Report*.
- Read-only IG for the non-database multi-record block `CTR_BLK`, `p_rows_per_page` 5.
- Item display condition `p_display_when` / `p_display_when2 PLSQL` / `p_display_when_type EXPRESSION` (IMPR1110 uses it).
- `NATIVE_CLEAR` on an item (IMPR1120 uses it); DA client condition `NOT_NULL` (IMPR1110 uses it).
- Shared LOV `FUNC_BODY_RETURNING_SQL` (as every LOV_APX LOV).
