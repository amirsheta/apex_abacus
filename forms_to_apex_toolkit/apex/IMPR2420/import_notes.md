# IMPR2420 – Import notes (report page, f345 standard + report standard 13-b)

> ⚠️ **REVIEW BEFORE IMPORT.** Generated `wwv_flow_api` code is not an officially supported way to build APEX
> applications. Import into a **DEV** workspace first, back up application 202530, and review the page in
> Page Designer. **Not imported yet.**

Form `IMPR2420.fmb` «تقرير أخطاء المستوردين» becomes page **2420** `IMPR2420`. It is a report parameter page with no
search page, and it prints IMPR2420.
Design: [IMPR2420_apex_page_spec.md](../../analysis/IMPR2420/IMPR2420_apex_page_spec.md). Generator: `scripts/gen_apex_impr2420.py`.

## 1. Files

| File | Content |
|---|---|
| `apex/IMPR2420/f345_impr2420.sql` | component export with the 4 placeholders |
| `apex/IMPR2420/f202530_impr2420_import.sql` | the same with workspace 23232323, application 202530, offset 460632461717563830, schema CUSTOMS |
| `plsql/IMPR2420/impr2420_spec.sql`, `impr2420_body.sql` | screen package `LIB_APX_USR.IMPR2420` **001** |
| `plsql/IMPR2420/IMPR2420_ARD_*.sql` | report package 001 (`scripts/gen_ard_impr_reports.py`; caller note updated, `_body.sql` unchanged) |
| `registry/IMPR2420_registry.sql` | MIG_FORM_REGISTRY / MIG_OBJECT_MAP rows |
| `apex/f202530_full.sql` | full application, rebuilt 2026-11-26 with every export including IMPR2420 |

Contents:
- 1 page with 2 regions (hero `TITLE`, static `CALLING_PARAMETERS`) and 7 items;
- 5 processes (Before Header);
- 1 dynamic action (`REPORT_PRINT`), with 1 FOS action and **1 one-line JavaScript action** that opens the ardpdf link;
- no LOV, no other shared component.

Regenerate: `python3 -I scripts/gen_apex_impr2420.py --workspace-id=23232323 --app-id=202530 --id-offset=460632461717563830 --schema=CUSTOMS`
(the self-check must print `problems: none`).

## 2. Prerequisites

1. Application 202530 already holds the **IMPR1110** export (page group IMPR `id(900001000010)`).
2. **FORMS_APX 004** is compiled.
3. Compile the report package `IMPR2420_ARD` 001 (`_spec.sql` first, then `_body.sql`). It depends on `ARD_LOGO` (static file
   `LOGO1.jpg`, DEC-034) and `HIJDATE_DB`. The ARD data source user (`ARD_DSNAME`) needs EXECUTE on it.
4. Compile the screen package `IMPR2420` 001 (`impr2420_spec.sql`, then `impr2420_body.sql`). `LIB_APX_USR` needs:
   - SELECT on `SD_PORTS` and `SC_PORT_SETTING`;
   - EXECUTE on `FORMS_APX`.
5. `SC_PORT_SETTING` needs these rows:
   - for the module (SYSOBJ_ID = `P2420_MODULE_ID`): `P_SYS_ID` and `P_REP_NO`;
   - ARD settings from `migration/001_ard_settings.sql` (SYSOBJ_ID 999, PORT_CD 99): `ARD_URL` and `ARD_DSNAME`.

   Without the ARD settings, طباعة stops with «إعداد خادم التقارير غير موجود ...».
6. **Page 0 toolbar:** the change is already in `apex/f202530_full.sql`. A component-only import needs it once by hand, as
   described in `apex/IMPR2130/import_notes.md` §2.7.

## 3. Import

Go to App Builder → Import → *Page or Component Export* and choose `apex/IMPR2420/f202530_impr2420_import.sql`. The import
removes and re-creates page 2420 (ids `2420…`).

## 4. After import – tests

1. The page 0 toolbar on page 2420 shows **only طباعة, مسح, رجوع**.
2. «حالة الصلاحية» lists غير منتهي الصلاحية, منتهي الصلاحية, الجميع, with الجميع (3) selected.
3. طباعة opens the PDF (A4 landscape) in a new tab, for the user's port (head office 99: every port). **The browser may
   block the tab**; if so, allow pop-ups for the APEX host.
4. Each of the three values gives a different PDF (1 expired only, 2 not expired only, 3 all).
5. Direct check: `SELECT IMPR2420_ARD.ARD_IMPR2420('99', '3', 'تقرير أخطاء المستوردين', '9-13') FROM dual;` returns the HTML.

## 5. Uncertain parameters (not in f345; check after import)

- DA on a custom event of `document` (as the real 21.2 export f202604, page 2100).
- `NATIVE_CLEAR` with `p_affected_elements_type` ITEM.
- `NATIVE_SELECT_LIST` with an inline `STATIC2` LOV (`p_lov`), no null entry (as IMPR2120 `P_TYPE`).
- Static content region with the Form-region template *Interactive Report*.
