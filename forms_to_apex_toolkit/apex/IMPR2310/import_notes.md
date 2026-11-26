# IMPR2310 – Import notes (report page, f345 standard + report standard 13-b)

> ⚠️ **REVIEW BEFORE IMPORT.** Generated `wwv_flow_api` code is not an officially supported way to build APEX
> applications. Import into a **DEV** workspace first, back up application 202530, and review the page in
> Page Designer. **Not imported yet.**

Form `IMPR2310.fmb` «بيانات المستوردين المعدلة / المضافة» becomes page **2310** `IMPR2310`. It is a report parameter page
with no search page, and it prints IMPR2310.
Design: [IMPR2310_apex_page_spec.md](../../analysis/IMPR2310/IMPR2310_apex_page_spec.md). Generator: `scripts/gen_apex_impr2310.py`.

## 1. Files

| File | Content |
|---|---|
| `apex/IMPR2310/f345_impr2310.sql` | component export with the 4 placeholders |
| `apex/IMPR2310/f202530_impr2310_import.sql` | the same with workspace 23232323, application 202530, offset 460632461717563830, schema CUSTOMS |
| `plsql/IMPR2310/impr2310_spec.sql`, `impr2310_body.sql` | screen package `LIB_APX_USR.IMPR2310` **001** |
| `plsql/IMPR2310/IMPR2310_ARD_*.sql` | report package 001 (`scripts/gen_ard_impr_reports.py`; only the caller note changed) |
| `registry/IMPR2310_registry.sql` | MIG_FORM_REGISTRY / MIG_OBJECT_MAP rows |
| `apex/f202530_full.sql` | full application, rebuilt 2026-11-26 with every export including IMPR2310 |

Contents:
- 1 page with 2 regions (hero `TITLE`, static `CALLING_PARAMETERS`) and 17 items;
- 1 computation and 5 processes (Before Header);
- 7 dynamic actions, with 6 FOS actions and **1 one-line JavaScript action** that opens the ardpdf link;
- 1 LOV (`LOV_IMPR2310_LOV_IMPR`).

Regenerate: `python3 -I scripts/gen_apex_impr2310.py --workspace-id=23232323 --app-id=202530 --id-offset=460632461717563830 --schema=CUSTOMS`
(the self-check must print `problems: none`).

## 2. Prerequisites

1. Application 202530 already holds the **IMPR1110** export: page group IMPR `id(900001000010)`, LOV `LOV_SD_PORTS` and
   the Application Setting `HIJRI_DATE_FORMAT`.
2. **FORMS_APX 004** and **LOV_APX 005** are compiled (no LOV_APX change in this conversion).
3. Compile the report package `IMPR2310_ARD` 001 (`_spec.sql` first, then `_body.sql`). It depends on `ARD_LOGO` (static file
   `LOGO1.jpg`, DEC-034) and `HIJDATE_DB`. The ARD data source user (`ARD_DSNAME`) needs EXECUTE on it and SELECT on
   `JOURNAL.IMPORTERS_JN`.
4. Compile the screen package `IMPR2310` 001 (`impr2310_spec.sql`, then `impr2310_body.sql`). `LIB_APX_USR` needs:
   - SELECT on `SD_PORTS`, `SC_PORT_SETTING`, `IMPORTERS` and **`JOURNAL.IMPORTERS_JN`** (a direct grant from JOURNAL);
   - EXECUTE on `FORMS_APX`.
5. `SC_PORT_SETTING` needs these rows:
   - for the module (SYSOBJ_ID = `P2310_MODULE_ID`): `P_SYS_ID` and `P_REP_NO`;
   - ARD settings from `migration/001_ard_settings.sql` (SYSOBJ_ID 999, PORT_CD 99): `ARD_URL` and `ARD_DSNAME`.

   Without the ARD settings, طباعة stops with «إعداد خادم التقارير غير موجود ...».
6. **Page 0 toolbar:** the change is already in `apex/f202530_full.sql`. A component-only import needs it once by hand, as
   described in `apex/IMPR2130/import_notes.md` §2.7. Here the flag item is the radio group `P2310_REPORT` itself (spec §2).

## 3. Import

Go to App Builder → Import → *Page or Component Export* and choose `apex/IMPR2310/f202530_impr2310_import.sql`. The import
removes and re-creates page 2310 and creates `LOV_IMPR2310_LOV_IMPR` (ids `2310…` and `9231…`).

## 4. After import – tests

1. The page 0 toolbar on page 2310 shows **only طباعة, مسح, رجوع**.
2. The page opens with «تعديلات بيانات المستوردين» and «حسب الخطاب» selected. The letter / period items are enabled and
   the importer number is disabled.
3. Switch to «حسب رقم المستورد»: the letter / period items are cleared and disabled, and the importer number is enabled.
   Switching back clears the importer.
4. A date picked with the Hijri picker is accepted. A typed wrong date (e.g. `1445-13-01`) gives the FORMS_APX date
   message.
5. **Head-office user (port 99):** the port item is shown. A wrong port gives «رمز الجمرك غير صحيح». The importer LOV lists
   the importers of the chosen port (or of port 99 when none is chosen).
   **Port user (port ≠ 99):** no port item; the LOV lists the user's importers.
6. A typed importer number fills the name. An unknown number is cleared without a message (Forms behaviour).
7. طباعة with «حسب رقم المستورد» and no number: «الرجاء تحديد رقم المستورد». With «حسب الخطاب», no letter number and an
   incomplete period: «الرجاء إدخال بيانات الخطاب أو الفترة».
8. No matching journal rows: «لا يوجد سجلات تحقق المطلوب» and no tab opens.
9. A matching letter number: a new tab opens with the PDF (A4 landscape), titled «بيانات المستوردين المعدلة» or
   «… المضافة» by the report type. **The browser may block the tab**; if so, allow pop-ups for the APEX host.
   A match in another port passes the check but prints an empty report (spec §12 item 1).
10. Direct check: `SELECT IMPR2310_ARD.ARD_IMPR2310('30', '2', '0', NULL, '<letter no>', NULL, NULL, NULL, NULL, 'بيانات المستوردين', '24-1111') FROM dual;`
    returns the HTML.

## 5. Open points (spec §12)

- The count runs on every port while the report filters one port (kept as in Forms).
- `LTR_NBR` / `SUPP_SRCE_CD` KEY-LISTVAL open the importer LOV in Forms; not converted. Should `SUPP_SRCE_CD` get a port LOV?

## 6. Uncertain parameters (not in f345; check after import)

- DA on a custom event of `document` (as the real 21.2 export f202604, page 2100).
- Radio groups with an inline `STATIC2` LOV, `p_attribute_01` = 2 columns (as IMPR1210), static defaults 2 / 0.
- DA with an EQUALS client-side condition, TRUE / FALSE actions run on page load, `NATIVE_ENABLE` / `NATIVE_DISABLE` (as IMPR1130 / IMPR2170).
- DA client-side condition `NOT_NULL` on the date items (as IMPR1110 / IMPR1160).
- Hijri date Text Fields in a static region with format mask `&P2310_HIJRI_DATE_FORMAT.` (as IMPR1160 AWARD_DATE).
- Static content region with the Form-region template *Interactive Report*.
- `NATIVE_CLEAR` on items (IMPR1120 uses it).
- Shared LOV `FUNC_BODY_RETURNING_SQL` (as every LOV_APX LOV).
