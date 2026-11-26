# IMPR2150 – Import notes (report page, f345 standard + report standard 13-b)

> ⚠️ **REVIEW BEFORE IMPORT.** Generated `wwv_flow_api` code is not an officially supported way to build APEX
> applications. Import into a **DEV** workspace first, back up application 202530, and review the page in
> Page Designer. **Not imported yet.**

Form `IMPR2150.fmb` «استثناءات المستوردين» becomes page **2150** `IMPR2150`. It is a report parameter page with no search
page, and it prints IMPR2150.
Design: [IMPR2150_apex_page_spec.md](../../analysis/IMPR2150/IMPR2150_apex_page_spec.md). Generator: `scripts/gen_apex_impr2150.py`.

## 1. Files

| File | Content |
|---|---|
| `apex/IMPR2150/f345_impr2150.sql` | component export with the 4 placeholders |
| `apex/IMPR2150/f202530_impr2150_import.sql` | the same with workspace 23232323, application 202530, offset 460632461717563830, schema CUSTOMS |
| `plsql/IMPR2150/impr2150_spec.sql`, `impr2150_body.sql` | screen package `LIB_APX_USR.IMPR2150` **001** |
| `plsql/IMPR2150/IMPR2150_ARD_*.sql` | report package 001 (`scripts/gen_ard_impr_reports.py`; caller note updated) |
| `plsql_templates/lov_apx.sql` | **LOV_APX 005**: `LOV_SINGLE_IMPORTERS` renamed `SINGLE_IMPORTERS`, `P_RULE_TYPE_ITEM` optional (previous: `rollback/LOV_APX/v004/`) |
| `apex/IMPR1140/f345_impr1140.sql`, `f202530_impr1140_import.sql` | regenerated: `LOV_SINGLE_IMPORTERS` now calls `LOV_APX.SINGLE_IMPORTERS` (one line) |
| `registry/IMPR2150_registry.sql` | MIG_FORM_REGISTRY / MIG_OBJECT_MAP rows |
| `apex/f202530_full.sql` | full application, rebuilt 2026-11-25 with every export including IMPR2150 |

Contents:
- 1 page with 2 regions (hero `TITLE`, static `CALLING_PARAMETERS`) and 14 items;
- 5 processes (Before Header);
- 2 dynamic actions, with 2 FOS actions and **1 one-line JavaScript action** that opens the ardpdf link;
- 1 LOV (`LOV_IMPORT_HQ_NBR`).

Regenerate: `python3 -I scripts/gen_apex_impr2150.py --workspace-id=23232323 --app-id=202530 --id-offset=460632461717563830 --schema=CUSTOMS`
(the self-check must print `problems: none`).

## 2. Prerequisites

1. Application 202530 already holds the **IMPR1110** export (page group IMPR `id(900001000010)`) and the **IMPR1140**
   export (LOV `LOV_RULE_TYPE`).
2. **FORMS_APX 004** and **LOV_APX 005** are compiled. **Order matters:** after LOV_APX 005 the old function
   `LOV_SINGLE_IMPORTERS` no longer exists, so the IMPR1140 LOV `LOV_SINGLE_IMPORTERS` must be the regenerated one
   (re-import `apex/IMPR1140/f202530_impr1140_import.sql`, or use the rebuilt `apex/f202530_full.sql`, or change its
   query by hand to `return LOV_APX.SINGLE_IMPORTERS(P_RULE_TYPE_ITEM => 'P1140_RULE_TYPE');`).
3. Compile the report package `IMPR2150_ARD` 001 (`_spec.sql` first, then `_body.sql`). It depends on `ARD_LOGO` (static file
   `LOGO1.jpg`, DEC-034) and `HIJDATE_DB`. The ARD data source user (`ARD_DSNAME`) needs EXECUTE on it.
4. Compile the screen package `IMPR2150` 001 (`impr2150_spec.sql`, then `impr2150_body.sql`). `LIB_APX_USR` needs:
   - SELECT on `SINGLE_IMPORTERS`, `BUS_ID_TYPES`, `IMPR_RULES`, `IMPR_RULE_PORTS`, `CG_REF_CODES`, `SD_PORTS` and
     `SC_PORT_SETTING`;
   - EXECUTE on `FORMS_APX`.
5. `SC_PORT_SETTING` needs these rows:
   - for the module (SYSOBJ_ID = `P2150_MODULE_ID`): `P_SYS_ID` and `P_REP_NO`;
   - ARD settings from `migration/001_ard_settings.sql` (SYSOBJ_ID 999, PORT_CD 99): `ARD_URL` and `ARD_DSNAME`.

   Without the ARD settings, طباعة stops with «إعداد خادم التقارير غير موجود ...».
6. **Page 0 toolbar:** the change is already in `apex/f202530_full.sql`. A component-only import needs it once by hand, as
   described in `apex/IMPR2130/import_notes.md` §2.7.

## 3. Import

Go to App Builder → Import → *Page or Component Export* and choose `apex/IMPR2150/f202530_impr2150_import.sql`. The import
removes and re-creates page 2150 and creates `LOV_IMPORT_HQ_NBR` (ids `2150…` and `9215…`).

## 4. After import – tests

1. The page 0 toolbar on page 2150 shows **only طباعة, مسح, رجوع**.
2. «حالة السجل» defaults to فعال and «نوع الاستثناء» to code 1.
3. «الرقم الموحد للمستورد»: the LOV lists `SINGLE_IMPORTERS`. A pick or a typed number fills in the name, business id
   type, business id and branch. An unknown number gives «رقم المستورد المدخل غير صحيح، أدخل الرقم الصحيح أو استخدم
   القائمة المرفقة» and clears the four items. Clearing the number clears them too.
4. Page 1140 still works: its HQ LOV lists `SINGLE_IMPORTERS`, or the port importers when the rule type is 12.
5. طباعة without a number: when no rule matches the status / branch, it shows «لا يوجد سجلات تحقق المطلوب» and opens no tab.
6. طباعة with a number: the Forms count passes as soon as the importer has any rule (spec §12 item 1), so the PDF may be
   empty for the chosen status or rule type. This is the Forms behaviour.
7. When the count is not zero, a new tab opens with the PDF (A4 landscape). **The browser may block the tab**; if so,
   allow pop-ups for the APEX host.
8. Direct check: `SELECT IMPR2150_ARD.ARD_IMPR2150('30', NULL, '1', '1', 'استثناءات المستوردين', '1-1') FROM dual;`
   returns the HTML.

## 5. Uncertain parameters (not in f345; check after import)

- DA on a custom event of `document` (as the real 21.2 export f202604, page 2100).
- Select List with an inline `STATIC2` LOV (`p_lov`) and no null entry.
- `p_item_default` with a static value on Select List items (REC_STATUS 1, RULE_TYPE 1).
- Static content region with the Form-region template *Interactive Report*.
- `NATIVE_CLEAR` on items (IMPR1120 uses it).
- Shared LOV `FUNC_BODY_RETURNING_SQL` (as every LOV_APX LOV).
