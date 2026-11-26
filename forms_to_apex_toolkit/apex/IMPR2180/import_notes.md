# IMPR2180 – Import notes (report page, f345 standard + report standard 13-b)

> ⚠️ **REVIEW BEFORE IMPORT.** Generated `wwv_flow_api` code is not an officially supported way to build APEX
> applications. Import into a **DEV** workspace first, back up application 202530, and review the page in
> Page Designer. **Not imported yet.**

Form `IMPR2180.fmb` «تقرير ازدواجية مهنتي الإستيراد والتخليص الجمركي» becomes page **2180** `IMPR2180`. It is a report
parameter page with no search page, and it prints IMPR2180.
Design: [IMPR2180_apex_page_spec.md](../../analysis/IMPR2180/IMPR2180_apex_page_spec.md). Generator: `scripts/gen_apex_impr2180.py`.

## 1. Files

| File | Content |
|---|---|
| `apex/IMPR2180/f345_impr2180.sql` | component export with the 4 placeholders |
| `apex/IMPR2180/f202530_impr2180_import.sql` | the same with workspace 23232323, application 202530, offset 460632461717563830, schema CUSTOMS |
| `plsql/IMPR2180/impr2180_spec.sql`, `impr2180_body.sql` | screen package `LIB_APX_USR.IMPR2180` **001** |
| `plsql/IMPR2180/IMPR2180_ARD_*.sql` | report package 001 (`scripts/gen_ard_impr_reports.py`; caller note updated, `_body.sql` unchanged) |
| `plsql_templates/lov_apx.sql` | **LOV_APX 006**: `REFERENCE_CODES` gets the optional `P_EXCLUDED_VALUE` (previous: `rollback/LOV_APX/v005/`) |
| `registry/IMPR2180_registry.sql` | MIG_FORM_REGISTRY / MIG_OBJECT_MAP rows |
| `apex/f202530_full.sql` | full application, rebuilt 2026-11-25 with every export including IMPR2180 |

Contents:
- 1 page with 2 regions (hero `TITLE`, static `CONTROL`) and 9 items;
- 5 processes (Before Header);
- 2 dynamic actions, with 2 FOS actions and **1 one-line JavaScript action** that opens the ardpdf link;
- 1 LOV (`LOV_LIC_TYPE`, Select List).

Regenerate: `python3 -I scripts/gen_apex_impr2180.py --workspace-id=23232323 --app-id=202530 --id-offset=460632461717563830 --schema=CUSTOMS`
(the self-check must print `problems: none`).

## 2. Prerequisites

1. Application 202530 already holds the **IMPR1110** export (page group IMPR `id(900001000010)`, LOV `LOV_SD_PORTS`).
2. **FORMS_APX 004** and **LOV_APX 006** are compiled. LOV_APX 006 only adds an optional parameter: every existing LOV
   keeps working.
3. Compile the report package `IMPR2180_ARD` 001 (`_spec.sql` first, then `_body.sql`). It depends on `ARD_LOGO` (static file
   `LOGO1.jpg`, DEC-034) and `HIJDATE_DB`. The ARD data source user (`ARD_DSNAME`) needs EXECUTE on it.
4. Compile the screen package `IMPR2180` 001 (`impr2180_spec.sql`, then `impr2180_body.sql`). `LIB_APX_USR` needs:
   - SELECT on `SD_PORTS`, `CG_REF_CODES` and `SC_PORT_SETTING`;
   - EXECUTE on `FORMS_APX` (it uses `ARABIC_MESSAGE`, which reads `STR_DB`).
5. `SC_PORT_SETTING` needs these rows:
   - for the module (SYSOBJ_ID = `P2180_MODULE_ID`): `P_SYS_ID` and `P_REP_NO` (Forms defaults 9 and 13);
   - ARD settings from `migration/001_ard_settings.sql` (SYSOBJ_ID 999, PORT_CD 99): `ARD_URL` and `ARD_DSNAME`.

   Without the ARD settings, طباعة stops with «إعداد خادم التقارير غير موجود ...».
6. **Page 0 toolbar:** the change is already in `apex/f202530_full.sql`. A component-only import needs it once by hand, as
   described in `apex/IMPR2130/import_notes.md` §2.7.

## 3. Import

Go to App Builder → Import → *Page or Component Export* and choose `apex/IMPR2180/f202530_impr2180_import.sql`. The import
removes and re-creates page 2180 and creates `LOV_LIC_TYPE` (ids `2180…` and `9218…`).

## 4. After import – tests

1. The page 0 toolbar on page 2180 shows **only طباعة, مسح, رجوع**.
2. As a head-office user (port 99): «رمز الجمرك» is shown. A valid port fills the name; an unknown port shows message 1-120.
   As a port user the port items are hidden.
3. «نوع الرخصة» lists `CG_REF_CODES` LIC_TYPE without value 3, plus an empty entry.
4. طباعة with no port and no type opens the PDF for every port and type (A4 landscape) in a new tab. **The browser may
   block the tab**; if so, allow pop-ups for the APEX host.
5. طباعة with a port and a type: the PDF shows only that port / type.
6. Direct check: `SELECT IMPR2180_ARD.ARD_IMPR2180(NULL, NULL, 'تقرير ازدواجية مهنتي الإستيراد والتخليص الجمركي', '9-13') FROM dual;`
   returns the HTML.

## 5. Uncertain parameters (not in f345; check after import)

- DA on a custom event of `document` (as the real 21.2 export f202604, page 2100).
- `NATIVE_CLEAR` with `p_affected_elements_type` ITEM.
- Shared LOV `p_source_type` `FUNC_BODY_RETURNING_SQL` (function body in `p_lov_query`).
- Static content region with the Form-region template *Interactive Report*.
