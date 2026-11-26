# IMPR2140 – Import notes (report page, f345 standard + report standard 13-b)

> ⚠️ **REVIEW BEFORE IMPORT.** Generated `wwv_flow_api` code is not an officially supported way to build APEX
> applications. Import into a **DEV** workspace first, back up application 202530, and review the page in
> Page Designer. **Not imported yet.**

Form `IMPR2140.fmb` «خطاب للمستورد» becomes page **2140** `IMPR2140`. It is a report parameter page with no search page,
and it prints the letters IMPR2141, IMPR2142 or IMPR2143.
Design: [IMPR2140_apex_page_spec.md](../../analysis/IMPR2140/IMPR2140_apex_page_spec.md). Generator: `scripts/gen_apex_impr2140.py`.

## 1. Files

| File | Content |
|---|---|
| `apex/IMPR2140/f345_impr2140.sql` | component export with the 4 placeholders |
| `apex/IMPR2140/f202530_impr2140_import.sql` | the same with workspace 23232323, application 202530, offset 460632461717563830, schema CUSTOMS |
| `plsql/IMPR2140/impr2140_spec.sql`, `impr2140_body.sql` | screen package `LIB_APX_USR.IMPR2140` **001** |
| `plsql/IMPR2140/IMPR2141_ARD_*.sql`, `IMPR2142_ARD_*.sql`, `IMPR2143_ARD_*.sql` | letter packages 001 (`scripts/gen_ard_impr_reports.py`) |
| `registry/IMPR2140_registry.sql` | MIG_FORM_REGISTRY / MIG_OBJECT_MAP rows |
| `apex/f202530_full.sql` | full application, rebuilt 2026-11-25 with every export including IMPR2140 |

Contents:
- 1 page with 2 regions (hero `TITLE`, static `CALLING_PARAMETERS`) and 11 items;
- 5 processes (Before Header);
- 3 dynamic actions, with 3 FOS actions and **1 one-line JavaScript action** that opens the ardpdf link;
- 1 LOV (`LOV_IMPR2140_REP_IMPR`).

Regenerate: `python3 -I scripts/gen_apex_impr2140.py --workspace-id=23232323 --app-id=202530 --id-offset=460632461717563830 --schema=CUSTOMS`
(the self-check must print `problems: none`).

## 2. Prerequisites

1. Application 202530 already holds the **IMPR1110** export (page group IMPR `id(900001000010)`, LOV `LOV_SD_PORTS`).
2. **FORMS_APX 004** and **LOV_APX 003** are compiled. This form needs no LOV_APX change.
3. Compile the letter packages `IMPR2141_ARD`, `IMPR2142_ARD` and `IMPR2143_ARD` 001 (each `_spec.sql` first, then `_body.sql`).
   They depend on `ARD_LOGO` (static file `LOGO1.jpg`, DEC-034), `HIJDATE_DB` and `SC_PORT_SETTING` (PORT_MANAGER_NAME).
   The ARD data source user (`ARD_DSNAME`) needs EXECUTE on them.
4. Compile the screen package `IMPR2140` 001 (`impr2140_spec.sql`, then `impr2140_body.sql`). `LIB_APX_USR` needs:
   - SELECT on `IMPORTERS`, `SD_PORTS`, `SC_USERS`, `CITIES`, `SMPL_LABS`, `SMPL_REQUESTS`, `SMPL_ITEMS` and `SC_PORT_SETTING`;
   - EXECUTE on `FORMS_APX`.
5. `SC_PORT_SETTING` needs these rows:
   - for the module (SYSOBJ_ID = `P2140_MODULE_ID`): `P_SYS_ID` and `P_REP_NO`;
   - ARD settings from `migration/001_ard_settings.sql` (SYSOBJ_ID 999, PORT_CD 99): `ARD_URL` and `ARD_DSNAME`.

   Without the ARD settings, طباعة stops with «إعداد خادم التقارير غير موجود ...».
6. **Page 0 toolbar:** the change is already in `apex/f202530_full.sql`. A component-only import needs it once by hand, as
   described in `apex/IMPR2130/import_notes.md` §2.7.

## 3. Import

Go to App Builder → Import → *Page or Component Export* and choose `apex/IMPR2140/f202530_impr2140_import.sql`. The import
removes and re-creates page 2140 and creates `LOV_IMPR2140_REP_IMPR` (ids `2140…` and `9214…`).

## 4. After import – tests

1. The page 0 toolbar on page 2140 shows **only طباعة, مسح, رجوع**.
2. As a port user (P_CURR_PORT_CD ≠ 99): there is no port item, and the hero shows the port name.
3. As the head office (99): a wrong port code gives «NO_DATA_FOUND» (Forms text); a valid one fills in the name.
4. «توجيه الخطاب» shows the 3 values and defaults to خطابات ديوان المراقبة.
5. «رقم المستورد»: the LOV lists the importers of the port. A pick or a typed number fills in the name, and an unknown
   number gives «رمزالمستورد غير موجود».
6. طباعة with no importer gives «لا يمكن ترك حقل المستورد خاليا».
7. طباعة for each letter:
   - when the letter's Forms count is zero, it shows «لا يوجد سجلات تحقق المطلوب» and opens no tab;
   - letter 2 needs failed samples (RESULT_CD 3/4) at the port;
   - letter 3 needs a class-12 user at the port.
8. When the count is not zero, a new tab opens with the letter PDF (A4 portrait). **The browser may block the tab**; if
   so, allow pop-ups for the APEX host.
9. Direct check: `SELECT IMPR2141_ARD.ARD_IMPR2141('30', '<importer>') FROM dual;` returns the HTML (same for 2142 and 2143).

## 5. Uncertain parameters (not in f345; check after import)

- DA on a custom event of `document` (as the real 21.2 export f202604, page 2100).
- Select List with an inline `STATIC2` LOV (`p_lov`) and no null entry.
- Static content region with the Form-region template *Interactive Report*.
- Item display condition `p_display_when` / `PLSQL` / `EXPRESSION` (IMPR1110 uses it).
- `NATIVE_CLEAR` on an item (IMPR1120 uses it).
- Shared LOV `FUNC_BODY_RETURNING_SQL` (as every LOV_APX LOV).
