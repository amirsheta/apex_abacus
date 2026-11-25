# IMPR1210 – Import notes (step 04, f345 standard)

> ⚠️ **REVIEW BEFORE IMPORT.** `f345_impr1210.sql` is generated `wwv_flow_api` code. That is **not** an officially
> supported way to build APEX applications. Import it into a **DEV** workspace only, export (back up) the target
> application first, and open both pages in Page Designer afterwards. **Status: NOT IMPORTED, package NOT COMPILED.**

| Item | Value |
|---|---|
| Form | IMPR1210 – صيانة تفاويض الشركات الوسيطة (table AGNTS) |
| Standard | f345 (`apex/Reference/f345.sql`), `CLAUDE.md` §4b–§4d, `docs/f345_reference_standard.md` |
| Target | Oracle APEX 21.2 (export version `2021.10.15`), Oracle Database 12.1.0.2, application 202530 |
| Pages | 1210 `IMPR1210`, 121001 `IMPR1210_SEARCH` (page group `IMPR` of the IMPR1110 export) |

## 1. Files

| File | What it is |
|---|---|
| `apex/IMPR1210/f345_impr1210.sql` | The component export (1,970 lines) with the four `__…__` placeholders |
| `apex/IMPR1210/f202530_impr1210_import.sql` | Import-ready copy: workspace 23232323, application 202530, ID offset 460632461717563830, schema `CUSTOMS` |
| `apex/f202530_full.sql` | Full application (f345 + all converted forms, IMPR1210 included) built by `scripts/build_full_app.py --shift-ids=460632461717563830` |
| `scripts/gen_apex_impr1210.py` | The generator **and** the design data (ITEMS, PROCESSES, DAS …). Re-run after a design change; do not edit the `.sql` |
| `work/IMPR1210/step03/build_spec.py`, `build_trace.py` | Render the page spec and `registry/IMPR1210_registry.sql` |
| `work/IMPR1210/step04/generator_output.txt`, `uncertain.json` | Last generator run (`problems: none`) |
| `plsql/IMPR1210/impr1210_spec.sql`, `impr1210_body.sql` | Package `IMPR1210` 001 |

Generator counts: 2 pages, 5 regions, 21 items, 3 buttons, 3 validations, 17 processes, 9 DAs / 16 actions (3 FOS,
**0 JavaScript actions**), 2 computations, 1 branch, 2 IGs (authorizations 7 columns, search 11 columns), 4 Text Messages;
no shared LOV, application item, page group or authorization scheme is created.

Placeholders of `f345_impr1210.sql`: `__WORKSPACE_ID__` (`select workspace_id from apex_workspaces where workspace = '<NAME>'`),
`__APP_ID__` (202530), `__SCHEMA_NAME__` (CUSTOMS), `__ID_OFFSET__` (`select template_id - 11621850520475869674 from
apex_application_temp_page where application_id = <app> and template_name = 'Standard'`; template IDs resolve only when the
offset matches the installed application). Regenerate the ready copy with
`python3 -I scripts/gen_apex_impr1210.py --workspace-id=23232323 --app-id=202530 --id-offset=460632461717563830 --schema=CUSTOMS`.

## 2. Prerequisites (in this order)

1. **IMPR1110 export imported** (page group `IMPR`, Application Setting `HIJRI_DATE_FORMAT`, LOVs `LOV_IMPR` and
   `LOV_ALLOWED_EXPORT`, used by name) and **IMPR1130 imported** (page 1130, target of the IMP_NEW button).
2. Packages compiled as `LIB_APX_USR`: `FORMS_APX` 004, `LOV_APX` (unchanged), **`IMPR1210` 001**.
3. Grants to LIB_APX_USR (definer rights): `SELECT`, `UPDATE` on `AGNTS`; `SELECT` on `IMPORTERS`, `SD_PORTS`; `EXECUTE` on
   `LIB_USR.ACTIVITY_DB`, `LIB_USR.IMPR` (**MISSING SOURCE**: `IMPR_SUSPENDED`), `DCLTN` (**MISSING SOURCE**:
   `IMPR_IMPR_AUTH_USED`, owner to confirm), `STR_DB`, `HIJDATE_DB`.
   The parsing schema CUSTOMS needs `SELECT`, `INSERT`, `UPDATE` on `AGNTS` and `SELECT` on `IMPORTERS`, `CG_REF_CODES`, `SD_PORTS`.
4. Page Functions list (f345): the module of IMPR1210 must list `CD1_STOPIMPRAUTH` and `CD2_REUSEIMPRAUTH`
   (SC_SYSTEM_OBJECTS.SYS_OS_FILE_NAME = the custom event names the page listens for).
5. Page 0 `NUMBER ONLY` DA and `FUNCS` drawer: present in `apex/f202530_full.sql`; for a component-only import add them
   to page 0 once by hand (as for the other forms).

## 3. Import

Full application (recommended, as 2026-11-18): App Builder → Import `apex/f202530_full.sql` (replaces application 202530).
Component only: SQL Workshop / SQLcl, `@apex/IMPR1210/f202530_impr1210_import.sql`, or App Builder → Import, File Type
"Page or Component Export". No child modal page other than 121001, so no page loses `P0_PAGE_PK` on return.

## 4. Parameters f345 does not show (check in Page Designer after the import)

All of `work/IMPR1210/step04/uncertain.json`. The ones that matter most:

| Parameter | Why it is uncertain | What to check |
|---|---|---|
| `NATIVE_RADIOGROUP` P1210_ATHRZTN_STA_CD with `p_lov => 'STATIC2:ساري;1,غير ساري;2'`, attributes 01 = 2 columns, 02 = NONE | no radio group in f345 or the real export f202604 | the radio shows ساري / غير ساري; a cancelled authorization shows غير ساري read only |
| Read Only `p_read_only_when` = `IMPR1210.AGNTS_IS_READ_ONLY(...)`, `p_read_only_when2 => 'PLSQL'`, type EXPRESSION | f345 shows the pattern only for display conditions | a used / cancelled authorization cannot be changed; UPDATE_STATUS tells why |
| `NATIVE_CONFIRM` text `&P1210_CONFIRM_STOP.` | substitution of a page item in the confirm text | the cancel function asks with message 9-50, not the literal `&P1210_CONFIRM_STOP.` |
| DAs on the custom events `CD1_STOPIMPRAUTH` / `CD2_REUSEIMPRAUTH` with JavaScript client conditions | IMPR1150 pattern | the FUNCS drawer entries fire the events; nothing happens on a new record |
| Form region `i:u`, ROWID key | as IMPR1110 / IMPR1140 / IMPR1160 | CREATE inserts with the next number; SAVE updates; page 0 DELETE shows the refusal |
| Display Only DATE items with `&P1210_HIJRI_DATE_FORMAT.`, set by PRE_INSERT | as IMPR1160 ENTRY_DT | a new authorization has today's Hijri date; the format matches the Application Setting |
| read-only IG `LOV_AGNT_ATHR_IMPR` refreshed by the IMPR_NBR DA | new for this form | after choosing an importer its authorizations are listed; a row opens that authorization |
| Display Only items with LOV (`IMPR_EXPR_TYPE`, `_AG`) set through FOS Items to Return | the returned value is the code | after the DA the activity may show the code until the page reloads (Forms showed the list label) |

## 5. Test after the import (UAT)

1. Open page 1210: new record, PORT_CD / PORT_NAME = the user's port, UPDATE_STATUS " يمكن التعديل", status ساري, use = 0.
2. Pick an importer (Popup LOV `LOV_IMPR`) → name and activity shown, grid "تفاويض المستورد" lists its authorizations.
   Suspended importer → message 9-70; unknown number → 9-20.
3. Pick a broker company → name / activity; the same number as the importer → 9-10.
4. CREATE → new ATHRZTN_SEQ_NBR = MAX + 1 of the port, creation date today (Hijri), activity log `(9, 1, 1)`.
5. On a new record type an existing ATHRZTN_SEQ_NBR → that authorization is shown; a number that does not exist → 9-40.
6. A valid, unused authorization: change broker / note → SAVE → activity `(9, 1, 2)`. A used one (declaration) → items read only,
   UPDATE_STATUS = message 8-30; a cancelled one → 8-80. A crafted SAVE on them is refused with that text.
7. FUNCS → "إيقاف التفويض" (CD1_STOPIMPRAUTH) on a valid authorization → confirmation 9-50 → status غير ساري, cancel date today,
   activity `(9, 1, 3)`, committed. "إسترجاع التفويض" (CD2_REUSEIMPRAUTH) on a cancelled one → confirmation → status ساري, no cancel
   date, activity `(9, 1, 4)`.
8. Page 0 DELETE → "لا يمكن حذف بيانات من هذه الشاشة". SEARCH → find by number / name → open. Button IMP_NEW → page 1130.
9. Duplicate number (two sessions saving at once) → Text Message `AG_PK`.

## 6. Open points

Inventory §15: `LIB_USR.IMPR` / `DCLTN` sources and owner (#1), AGNTS DDL and constraint names (#2), the status radio on SAVE (#3),
the authorization list instead of the LOV form copy-back (#4), the IMP_NEW target form (#5).
