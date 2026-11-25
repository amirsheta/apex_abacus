# IMPR2170 – Import notes (report page, f345 standard + report standard 13-b)

> ⚠️ **REVIEW BEFORE IMPORT.** Generated `wwv_flow_api` code is not an officially supported way to build APEX
> applications. Import into a **DEV** workspace first, back up application 202530, and review the page in
> Page Designer. **Not imported yet.**

Form `IMPR2170.fmb` «تقرير حالة مستورد» becomes page **2170** `IMPR2170`. It is a report parameter page with no search
page, and it prints IMPR2170.
Design: [IMPR2170_apex_page_spec.md](../../analysis/IMPR2170/IMPR2170_apex_page_spec.md). Generator: `scripts/gen_apex_impr2170.py`.

## 1. Files

| File | Content |
|---|---|
| `apex/IMPR2170/f345_impr2170.sql` | component export with the 4 placeholders |
| `apex/IMPR2170/f202530_impr2170_import.sql` | the same with workspace 23232323, application 202530, offset 460632461717563830, schema CUSTOMS |
| `plsql/IMPR2170/impr2170_spec.sql`, `impr2170_body.sql` | screen package `LIB_APX_USR.IMPR2170` **001** |
| `plsql/IMPR2170/IMPR2170_ARD.*` | report package 001 (`scripts/gen_ard_impr_reports.py`; only the caller note changed) |
| `registry/IMPR2170_registry.sql` | MIG_FORM_REGISTRY / MIG_OBJECT_MAP rows |
| `apex/f202530_full.sql` | full application, rebuilt 2026-11-25 with every export including IMPR2170 |

Contents:
- 1 page with 2 regions (hero `TITLE`, static `CALLING_PARAMETERS`) and 13 items;
- 5 processes (Before Header);
- 5 dynamic actions, with 4 FOS actions and **1 one-line JavaScript action** that opens the ardpdf link;
- 1 LOV (`LOV_IMPR2170_LOV_IMPR_NBR`).

Regenerate: `python3 -I scripts/gen_apex_impr2170.py --workspace-id=23232323 --app-id=202530 --id-offset=460632461717563830 --schema=CUSTOMS`
(the self-check must print `problems: none`).

## 2. Prerequisites

1. Application 202530 already holds the **IMPR1110** export (page group IMPR `id(900001000010)`, LOV `LOV_SD_PORTS`) and the
   **IMPR2150** export (LOV `LOV_IMPORT_HQ_NBR`).
2. **FORMS_APX 004** and **LOV_APX 005** are compiled (no LOV_APX change in this conversion).
3. Compile the report package `IMPR2170_ARD` 001 (`.pks` first, then `.pkb`). It depends on `ARD_LOGO` (static file
   `LOGO1.jpg`, DEC-034), `HIJDATE_DB` and `IMPR_UTILITIES`. The ARD data source user (`ARD_DSNAME`) needs EXECUTE on it.
4. Compile the screen package `IMPR2170` 001 (`impr2170_spec.sql`, then `impr2170_body.sql`). `LIB_APX_USR` needs:
   - SELECT on `SD_PORTS`, `SC_PORT_SETTING`, `IMPORTERS`, `SINGLE_IMPORTERS`, `IMPR_SUSPNS`, `IMPORTER_SEIZURES`, `HQ_IMPRS`,
     `BUS_ID_TYPES`, `CSTMS_INSTS`, `IMPR_DUTY_DIFF_BLKS`, `IMPR_ACCUR_INSPCTNS`, `CASE_ACCUSEDS`, `CUSTOMS_CASES`,
     `IMPR_CNTRL_SUSPNS`, `WAIVERS`, `WVR_ITEMS`, `IMPORTER_EXCLUDEDS`, `EXCLUSION_DECREES`, `WVR_ITEMS_GLOBALS`;
   - EXECUTE on `FORMS_APX`.

   The `COUNT_SUSP1` checks are static SQL, so a missing grant shows as a compile error (`SHOW ERRORS`), not as a silent
   "clean" result at run time.
5. `SC_PORT_SETTING` needs these rows:
   - for the module (SYSOBJ_ID = `P2170_MODULE_ID`): `P_SYS_ID` and `P_REP_NO`;
   - ARD settings from `migration/001_ard_settings.sql` (SYSOBJ_ID 999, PORT_CD 99): `ARD_URL` and `ARD_DSNAME`.

   Without the ARD settings, طباعة stops with «إعداد خادم التقارير غير موجود ...».
6. **Page 0 toolbar:** the change is already in `apex/f202530_full.sql`. A component-only import needs it once by hand, as
   described in `apex/IMPR2130/import_notes.md` §2.7.

## 3. Import

Go to App Builder → Import → *Page or Component Export* and choose `apex/IMPR2170/f202530_impr2170_import.sql`. The import
removes and re-creates page 2170 and creates `LOV_IMPR2170_LOV_IMPR_NBR` (ids `2170…` and `9217…`).

## 4. After import – tests

1. The page 0 toolbar on page 2170 shows **only طباعة, مسح, رجوع**.
2. **Head-office user (port 99):** the radio group shows «جمرك محدد» selected; the unified-number item is disabled.
   - Pick a port: its name appears. A wrong port gives «رمز الجمرك غير صحيح».
   - The importer LOV lists the importers of that port; a pick or a typed number fills the name. An unknown number is
     cleared without a message (Forms behaviour).
   - Switch to «جميع الجمارك»: port, importer and names are cleared and disabled; the unified number is enabled. Switching
     back clears the unified number.
3. **Port user (port ≠ 99):** no radio group, no port, no unified number; only «رقم المستورد / المصدر». The LOV lists the
   importers of the user's port.
4. طباعة with no number: «الرجاء تحديد رقم المستورد» / «الرجاء تحديد رقم المستورد الموحد». Head office, choice 1, no port:
   «يجب إدخال رمز الجمرك» (new check, spec §12 item 3).
5. An importer with no suspension, block, waiver … : «حالة المستورد سليمة» and no tab opens.
6. An importer with an open suspension (IMPR_SUSPNS): a new tab opens with the PDF (A4 landscape). **The browser may block
   the tab**; if so, allow pop-ups for the APEX host.
7. Direct check: `SELECT IMPR2170_ARD.ARD_IMPR2170('30', '30', '1', '<impr_nbr>', NULL, 'تقرير حالة مستورد', '24-1111') FROM dual;`
   returns the HTML.

## 5. Open item

`TITLE.SHOW_USER` («اضافة اسم المستخدم») ran `IMPR2170n.rep`, which is not in the repository. The check box is not on the
page (spec §12 item 1). Supply the RDF or confirm it can be dropped.

## 6. Uncertain parameters (not in f345; check after import)

- DA on a custom event of `document` (as the real 21.2 export f202604, page 2100).
- Radio group with an inline `STATIC2` LOV, `p_attribute_01` = 2 columns (as IMPR1210), static default 1.
- DA with an EQUALS client-side condition, TRUE / FALSE actions run on page load, `NATIVE_ENABLE` / `NATIVE_DISABLE` (as IMPR1130).
- Static content region with the Form-region template *Interactive Report*.
- `NATIVE_CLEAR` on items (IMPR1120 uses it).
- Shared LOV `FUNC_BODY_RETURNING_SQL` (as every LOV_APX LOV).
