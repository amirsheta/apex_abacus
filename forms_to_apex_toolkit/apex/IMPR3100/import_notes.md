# IMPR3100 – Import notes (report page, f345 standard + report standard 13-b)

> ⚠️ **REVIEW BEFORE IMPORT.** Generated `wwv_flow_api` code is not an officially supported way to build APEX
> applications. Import into a **DEV** workspace first, back up application 202530, and review the page in
> Page Designer. **Not imported yet.**

Form `IMPR3100.fmb` «تقرير إضافات وتعديلات بيانات المستوردين (مساندة فنية)» becomes page **3100** `IMPR3100`. It is a
report parameter page with no search page, and it prints IMPR3100.
Design: [IMPR3100_apex_page_spec.md](../../analysis/IMPR3100/IMPR3100_apex_page_spec.md). Generator: `scripts/gen_apex_impr3100.py`.

## 1. Files

| File | Content |
|---|---|
| `apex/IMPR3100/f345_impr3100.sql` | component export with the 4 placeholders |
| `apex/IMPR3100/f202530_impr3100_import.sql` | the same with workspace 23232323, application 202530, offset 460632461717563830, schema CUSTOMS |
| `plsql/IMPR3100/impr3100_spec.sql`, `impr3100_body.sql` | screen package `LIB_APX_USR.IMPR3100` **001** |
| `plsql/IMPR3100/IMPR3100_ARD_*.sql` | report package 001 (`scripts/gen_ard_impr_reports.py`, entry IMPR3100) |
| `plsql_templates/lov_apx.sql` | **LOV_APX 007** (new `LOV_USER`; previous version `rollback/LOV_APX/v006/`) |
| `forms/IMPR/reports/IMPR3100.xml` | the RDF XML, copied from `Downloads/apex_abacus-main/forms/IMPR/REP_XML/` |
| `registry/IMPR3100_registry.sql` | MIG_FORM_REGISTRY / MIG_OBJECT_MAP rows |
| `apex/f202530_full.sql` | full application, rebuilt 2026-11-26 with every export including IMPR3100 |

Contents:
- 1 page with 2 regions (hero `TITLE`, static `CALLING_PARAMETERS`) and 21 items;
- 1 computation and 6 processes (Before Header);
- 9 dynamic actions, with 9 FOS actions and **1 one-line JavaScript action** that opens the ardpdf link;
- 2 LOVs (`LOV_IMPR3100_LOV_IMPR`, `LOV_IMPR3100_LOV_USER`).

Regenerate: `python3 -I scripts/gen_apex_impr3100.py --workspace-id=23232323 --app-id=202530 --id-offset=460632461717563830 --schema=CUSTOMS`
(the self-check must print `problems: none`).

## 2. Prerequisites

1. Application 202530 already holds the **IMPR1110** export (page group IMPR `id(900001000010)`, LOV `LOV_SD_PORTS`,
   Application Setting `HIJRI_DATE_FORMAT`) and the **SUPPORT_ENTRY** export (LOV `LOV_SUPP_TITLES`).
2. **FORMS_APX 004** is compiled. Compile **LOV_APX 007** (`plsql_templates/lov_apx.sql`) before the import: the LOV
   `LOV_IMPR3100_LOV_USER` calls the new `LOV_APX.LOV_USER`.
3. Compile the report package `IMPR3100_ARD` 001 (`_spec.sql` first, then `_body.sql`). It depends on `ARD_LOGO` (static file
   `LOGO1.jpg`, DEC-034) and `HIJDATE_DB`. The ARD data source user (`ARD_DSNAME`) needs EXECUTE on it and SELECT on
   `JOURNAL.IMPORTERS_JN`, `SD_PORTS`, `SUPP_TITLES`, `SC_USERS`, `IMPR_TYPES`, `BUS_ID_TYPES`, `CITIES`.
4. Compile the screen package `IMPR3100` 001 (`impr3100_spec.sql`, then `impr3100_body.sql`). `LIB_APX_USR` needs:
   - SELECT on `SD_PORTS`, `SC_PORT_SETTING`, `SC_USERS`, `SUPP_TITLES`, `IMPORTERS` and **`JOURNAL.IMPORTERS_JN`** (a
     direct grant from JOURNAL);
   - EXECUTE on `FORMS_APX`.
5. `SC_PORT_SETTING` needs these rows:
   - for the module (SYSOBJ_ID = `P3100_MODULE_ID`): `P_SYS_ID` and `P_REP_NO`;
   - ARD settings from `migration/001_ard_settings.sql` (SYSOBJ_ID 999, PORT_CD 99): `ARD_URL` and `ARD_DSNAME`.
6. **Page 0 toolbar:** the change is already in `apex/f202530_full.sql`. A component-only import needs it once by hand
   (`apex/IMPR2130/import_notes.md` §2.7). Here the flag item is the radio group `P3100_REPORT` itself.

## 3. Import

Go to App Builder → Import → *Page or Component Export* and choose `apex/IMPR3100/f202530_impr3100_import.sql`. The import
removes and re-creates page 3100 and creates the two LOVs (ids `3100…` and `9310…`).

## 4. After import – tests

1. The page 0 toolbar on page 3100 shows **only طباعة, مسح, رجوع**.
2. The page opens with «تعديلات بيانات المستوردين» selected. Outside head office, «جمرك الخطاب» shows the user's port and
   its name, and there is no port item.
3. Every lookup fills its name: port, letter port, letter department, user, importer. A wrong letter port gives
   «رمز الجمرك غير صحيح», a wrong department «رمز جهة الخطاب غير موجود», a wrong user the Arabic message 1-80. An unknown
   importer number is cleared without a message.
4. The user LOV lists the users of the chosen port (or of the user's port); the importer LOV the importers of the same port.
5. A typed wrong date (e.g. `1445-13-01`) gives the FORMS_APX date message.
6. طباعة with a letter date and a period: «يجب إدخال تاريخ الخطاب أو الفترة وليس كليهما». A period whose end is before its
   start: «تاريخ النهاية يجب أن يكون أكبر من تاريخ البداية».
7. No matching journal rows: «لا يوجد سجلات تحقق المطلوب» and no tab opens.
8. A matching letter number: a new tab opens with the PDF (A4 landscape), titled «بيانات المستوردين المعدلة» or
   «… المضافة». With a letter date, only rows of that date are printed (spec §12 item 2). **The browser may block the tab**;
   if so, allow pop-ups for the APEX host.
9. Direct check: `SELECT IMPR3100_ARD.ARD_IMPR3100('30', NULL, NULL, NULL, NULL, NULL, '<letter no>', NULL, NULL, '0', 'تقرير', '9-8') FROM dual;`
   returns the HTML.

## 5. Open points (spec §12)

- The count runs on every port while the report filters one port (kept as in Forms).
- TODO: MISSING SOURCE `LOV_USER.fmb`. `LOV_APX.LOV_USER` was built from `USER_ID.WHEN-VALIDATE-ITEM`; compare it with the
  real LOV form when it is found.

## 6. Uncertain parameters (not in f345; check after import)

- DA on a custom event of `document` (as the real 21.2 export f202604, page 2100).
- Radio group with an inline `STATIC2` LOV, `p_attribute_01` = 2 columns (as IMPR1210), static default 0.
- DA client-side condition `NOT_NULL` on the date items (as IMPR1110 / IMPR1160).
- Hijri date Text Fields in a static region with format mask `&P3100_HIJRI_DATE_FORMAT.` (as IMPR1160 AWARD_DATE).
- Static content region with the Form-region template *Interactive Report*.
- `NATIVE_CLEAR` on items (IMPR1120 uses it).
- Shared LOV `FUNC_BODY_RETURNING_SQL` (as every LOV_APX LOV).
