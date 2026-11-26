# IMPR1116 – Import notes (step 04, revision 1, f345 standard)

> ⚠️ **REVIEW BEFORE IMPORT.** Generated `wwv_flow_api` code is not an officially supported way to build APEX
> applications. Import into a **DEV** workspace first, back up application 202530, and inspect pages 1116 / 111601
> in Page Designer after the import.

| Item | Value |
|---|---|
| Form | IMPR1116 (`forms/IMPR/IMPR1116_fmb.xml`) – "شاشة استعراض بيانات رقم المنشأة 700 المدخلة من البوابة" |
| Export (placeholders) | `apex/IMPR1116/f345_impr1116.sql` |
| Import-ready copy | `apex/IMPR1116/f202530_impr1116_import.sql` (workspace 23232323, app 202530, offset 460632461717563830, schema CUSTOMS) |
| Full application | `apex/f202530_full.sql`, rebuilt 2026-11-24 with every component export in the repository: IMPR1110 + IMPR1120 + SUPPORT_ENTRY + IMPR1116 + IMPR1125 + IMPR1130 + IMPR1140 (`python3 -I scripts/build_full_app.py --app-id=202530 --shift-ids=460632461717563830 apex/IMPR1110/f345_impr1110.sql apex/IMPR1120/f345_impr1120.sql apex/SUPPORT_ENTRY/f345_support_entry.sql apex/IMPR1116/f345_impr1116.sql apex/IMPR1125/f345_impr1125.sql apex/IMPR1130/f345_impr1130.sql apex/IMPR1140/f345_impr1140.sql`). Compared with the previous build there are only additions (IMPR1130, IMPR1140); the header comment is the one line that changed. Checked: 111,630 lines, 2531 IDs, no duplicate ID, no undefined ID, no placeholder, no duplicate page / LOV name / application item, begin / end balanced |
| Generator | `scripts/gen_apex_impr1116.py` (helpers and self-check copied from `gen_apex_impr1120.py`; deterministic ids `1116…`, `111601…`, `9116…`) |
| Design | `analysis/IMPR1116/IMPR1116_apex_page_spec.md` (step 03 rev 1) |
| Package | `LIB_APX_USR.IMPR1116` **001** (`plsql/IMPR1116/`) – NOT COMPILED yet |
| Status | NOT IMPORTED |

## 1. Contents

| Component | Name | Count |
|---|---|---|
| Pages | 1116 `IMPR1116` (main), 111601 `IMPR1116_SEARCH` (modal 1800 × 800); page group `IMPR` (IMPR1110) | 2 |
| Regions | 1116: `IMPR_PRTL_NAT_HERO`, `IMPR_PRTL_NAT` (Form, ROWID, update only), `IMPORTERS` (read-only IG); 111601: `IMPR_PRTL_NAT_SEARCH_CRITERIA`, `IMPR_PRTL_NAT_SEARCH` (read-only IG) | 5 |
| Items | 1116: `P1116_ROW_ID`, `PRTL_NAT_ISN`, `IMPR_TYPE_CD`, `CTRY_CD`, `BUS_ID_TYPE_CD`, `BUS_ID`, `BUS_ID_BRNCH`, `ID_TYPE_GZT`, `BUS_ID_NEW`, `GAZT_NAME`, `REVIEW_FLAG`, `HERO_TITLE`, `MODULE_ID`; 111601: `P111601_SEARCH` | 14 |
| Grid columns | `IMPORTERS` 11, `IMPR_PRTL_NAT_SEARCH` 6 (link column `PRTL_NAT_ISN`) | 17 |
| Processes (1116) | Before Header `New` (Never), `P0_PAGE_PK CHECK`, `PARAMETERS`, `P0_PAGE_PK`, `Initialize form`, `HEADER TITLE`; After Submit `PRE-INSERT`, `PRE-UPDATE`, `PRE-DELETE`, `Process form` | 10 |
| Branch | `IMPR1116 - stay in the form` | 1 |
| Buttons / DAs (111601) | `SEARCH`, `CLEAR`; DAs `SEARCH WHEN-BUTTON-PRESSED`, `SEARCH KEY-ENTER`, `CLEAR WHEN-BUTTON-PRESSED`, `Hide` | 2 / 4 |
| Validations, computations, FOS actions, JavaScript actions | none (the form has no item trigger with business code) | 0 |
| Shared | LOVs `LOV_ID_TYPE_GZT`, `LOV_PRTL_NAT_FLAG` (function body: `LOV_APX.REFERENCE_CODES`) | 2 |

Never generated: theme, templates, page 0, plug-ins, application items, application processes, Text Messages,
Authorization Schemes (CLAUDE.md §8).

## 2. Placeholders

| Token | Value for 202530 | How to get it |
|---|---|---|
| `__WORKSPACE_ID__` | 23232323 | `select workspace_id from apex_workspaces where workspace = '<NAME>';` |
| `__APP_ID__` | 202530 | the application installed from f345 |
| `__SCHEMA_NAME__` | CUSTOMS | parsing schema |
| `__ID_OFFSET__` | 460632461717563830 | `select template_id - 11621850520475869674 from apex_application_temp_page where application_id = 202530 and template_name = 'Standard';` |

Regenerate the import-ready copy with
`python3 -I scripts/gen_apex_impr1116.py --workspace-id=… --app-id=… --id-offset=… --schema=…` if any value changes.

## 3. Prerequisites (in this order)

1. **Application 202530 contains the IMPR1110 export** (or the full file): this export reuses its page group `IMPR`
   (`wwv_flow_api.id(900001000010)`). Without it the component import fails with ORA-02291.
2. **`FORMS_APX` 004** compiled (`FORM_TRIGGER_FAILURE`, `ROWID_FROM_URL`, `GET_MODULE_ID`, `HEADER_TITLE`).
3. **`LOV_APX`** compiled (`plsql_templates/lov_apx.sql`, function `REFERENCE_CODES`; version 001 or later; the work
   tree holds 002, raised by another conversion while IMPR1116 was built, with `REFERENCE_CODES` unchanged). IMPR1116 does not change it.
4. **Package `IMPR1116` 001** compiled as `LIB_APX_USR.IMPR1116`: run `plsql/IMPR1116/impr1116_spec.sql`, then
   `impr1116_body.sql`, as a user allowed to create public synonyms. `SELECT IMPR1116.PKG_VERSION FROM dual` must show
   `VERSION NO. IS:001`. Direct grants to `LIB_APX_USR`: SELECT on `IMPR_PRTL_NAT`, EXECUTE on `ACTIVITY_DB` and `FORMS_APX`.
5. **Grants to `CUSTOMS`** (region SQL and `Process form` run as the parsing schema): SELECT, UPDATE on `IMPR_PRTL_NAT`;
   SELECT on `IMPORTERS`, `IMPR_TYPE_ID_TYPES`, `IMPR_TYPES`, `BUS_ID_TYPES`, `CG_REF_CODES`.

## 4. Import

Choose **one** option.

**A. Component import into 202530:** App Builder → Import → *Page or Component Export* →
`apex/IMPR1116/f202530_impr1116_import.sql`, or `sql CUSTOMS@<tns> @apex/IMPR1116/f202530_impr1116_import.sql`.
It removes and re-creates pages 1116 and 111601 only, and creates the two LOVs with fixed IDs. If a second import reports
a duplicate LOV name, delete `LOV_ID_TYPE_GZT` and `LOV_PRTL_NAT_FLAG` first (not verified).

**B. Full application** `apex/f202530_full.sql` (App Builder → Import → *Database Application*, reuse application ID
202530). This **replaces the whole application** with this repository's version (IMPR1110, IMPR1120, SUPPORT_ENTRY,
IMPR1116, plus the page 0 `NUMBER ONLY` DA and `FUNCS` drawer).

## 5. After import – review and tests

1. Page Designer, page 1116: region `IMPR_PRTL_NAT` → Attributes: *Allowed Operations* = Update only; *Primary Key* = ROWID.
   `P1116_REVIEW_FLAG` is a Select List on `LOV_PRTL_NAT_FLAG` with Read Only *Item is NULL* `P0_PAGE_PK`.
2. Shared Components → LOVs → `LOV_PRTL_NAT_FLAG`: type *PL/SQL Function Body returning SQL Query*, body
   `return LOV_APX.REFERENCE_CODES(P_DOMAIN => 'PRTL_NAT_FLAG');`, Return `R` / Display `D`.
3. Run page 1116 → page 0 `SEARCH` → page 111601 lists the rows with `REVIEW_FLAG = 0` and a Gazette name (Forms
   Execute Query). Type part of a name, then press Enter → the list is filtered. Press **مسح البحث** → all rows again.
   Close the dialog after a search and open it again → the search text is empty and all rows are shown (`CLEAR SEARCH`).
4. Click a `مسلسل` link → page 1116 shows the record; the importers grid lists the importers with the same commercial
   activity, country, identification type, number and branch (compare with Forms for one row whose branch is empty).
5. Set `حالة المراجعة` to 1 → `SAVE` → "تم الحفظ بنجاح"; the record stays open; `ACTIVITY` log has a row
   (system 9, subject 8, type 2, key = `PRTL_NAT_ISN`, port / user / workstation of the session); the row is gone from 111601.
6. `DELETE` on a record → "لا يمكن حذف بيانات من هذه الشاشة"; `CLEAR` then `CREATE` → "لا يمكن إضافة بيانات من هذه الشاشة".
   Nothing is changed in the database.
7. Open page 1116 with a forged `P0_PAGE_PK` (e.g. `ABC`) → empty form, no error (`P0_PAGE_PK_CHECK`).

## 6. Uncertain parameters (not in f345; check after import)

- Form region `p_edit_operations => 'u'` (update only; IMPR1110 uses `'i:u'`, which imported).
- ROWID primary key of the Form region: `p_include_rowid_column`, item source ROWID / `p_source_data_type` ROWID (as IMPR1110).
- Display Only based on LOV: `p_attribute_02 => 'LOV'` with `p_named_lov` (`P1116_ID_TYPE_GZT`; as IMPR1120 `P1120_IMPR_EXPR_TYPE`).
- `create_ig_report p_rows_per_page => 10` (Forms Records Displayed; IMPR1120 uses 5).
- Search grid: `p_lazy_loading` true, toolbar `ACTIONS_MENU:RESET` (as IMPR1120 112001).
- `NATIVE_CLEAR` with `p_affected_elements`; button DA `p_triggering_button_id`; client condition
  `JAVASCRIPT_EXPRESSION this.browserEvent.which === 13` (all as IMPR1120 112001).
- Shared LOV `p_source_type => 'FUNC_BODY_RETURNING_SQL'` (as every LOV since LOV_APX).

If the import rejects one of these, tell Claude Code which one: each is one place in `scripts/gen_apex_impr1116.py`.

## 7. Notes, deviations and open items

- **Design decision (to confirm):** the Forms screen shows 5 portal rows at once. Here the list is page 111601 and
  page 1116 reviews one row at a time (spec §0 #1). If the reviewers need to set many flags in one save, the
  alternative is an editable grid of all pending rows on page 1116; tell Claude Code and step 03 / 04 are redone.
- `Process form` writes back the hidden / display-only key columns with the values Initialize form fetched (unchanged).
  A DB trigger `BEFORE UPDATE OF <column>` on those columns would fire; the DDL is not available (inventory §15 #1).
- `USER_ID` / `LST_TRAN_DT` / `UPDATE_DT` are not set (as in Forms); see `-- SUGGESTION:` in `IMPR1116.PRE_UPDATE`.
- The CREATE / DELETE refusal texts are placeholders to agree with the business owner.
- The Forms POST-QUERY message "رمز النشاط التجاري غير صحيح" for an unknown type is not shown (names stay empty).
- Functions of the module (`SC_SYSTEM_OBJECTS`) and the screen's launcher are unknown; the page 0 `FUNCS` drawer shows
  whatever *Page Functions* lists for the module.
