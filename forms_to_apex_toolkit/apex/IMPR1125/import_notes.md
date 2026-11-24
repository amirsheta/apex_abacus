# IMPR1125 – Import notes (step 04, revision 1, f345 standard)

> ⚠️ **REVIEW BEFORE IMPORT.** `f345_impr1125.sql` is generated `wwv_flow_api` code, which is **not** an officially supported way to build APEX applications.
> - Import it into a **DEV** workspace only.
> - Export (back up) the target application first.
> - Open every page in Page Designer afterwards.

| Item | Value |
|---|---|
| Form | IMPR1125 (`IMPR1125_CENTRAL`) – "صيانة توقيفات المستوردين" (central suspensions) |
| Standard | f345 reference application, `CLAUDE.md` §4b / §4c / §4d, `docs/f345_reference_standard.md` |
| Target | Oracle APEX 21.2 (export version `2021.10.15`), Oracle Database 12.1.0.2 |
| Pages | 1125 `IMPR1125`, 112501 `IMPR1125_SEARCH`, 112502 `IMPR1125_DELETED_SUSPENSIONS`; page group `IMPR` (from IMPR1110) |
| Design | `analysis/IMPR1125/IMPR1125_apex_page_spec.md` (step 03) |
| Status | **NOT IMPORTED**, package **NOT COMPILED** |

## 1. Files

| File | What it is |
|---|---|
| `apex/IMPR1125/f345_impr1125.sql` | The export: 1960-line component export with the four `__…__` placeholders |
| `apex/IMPR1125/f202530_impr1125_import.sql` | Import-ready copy for application 202530 (workspace 23232323, offset 460632461717563830, schema `CUSTOMS`) |
| `apex/f202530_full.sql` | Full application export of 202530, rebuilt with IMPR1110 + IMPR1120 + SUPPORT_ENTRY + IMPR1116 + IMPR1125: `python3 -I scripts/build_full_app.py --app-id=202530 --shift-ids=460632461717563830 apex/IMPR1110/f345_impr1110.sql apex/IMPR1120/f345_impr1120.sql apex/SUPPORT_ENTRY/f345_support_entry.sql apex/IMPR1116/f345_impr1116.sql apex/IMPR1125/f345_impr1125.sql`. Compared with the previous build, only additions (plus the header line) |
| `plsql/IMPR1125/impr1125_spec.sql` + `impr1125_body.sql` | Package `IMPR1125` version **001** |
| `scripts/gen_apex_impr1125.py` | The generator (design data in the script, sections "spec N"). Re-run after a spec change; do not edit the `.sql` by hand |

Generator summary (`python3 -I scripts/gen_apex_impr1125.py`):

```
create_page 3, create_page_plug 7, create_page_item 20, create_page_button 3,
create_page_validation 4, create_page_process 12, create_page_da_event 11,
create_page_da_action 15, create_page_computation 1, create_page_branch 2,
create_region_column 21, create_interactive_grid 3, create_ig_report_column 21,
create_list_of_values 0, create_flow_item 0, create_message 0, create_security_scheme 0, create_page_group 0
NATIVE_JAVASCRIPT_CODE actions 1, FOS actions 4
problems: none
```

The self-check is the IMPR1120 one plus three checks:
- no ID clash with the IMPR1120 export;
- `LOV_SUSPN_SIDE_CD` has the referenced ID in the IMPR1120 export;
- the only JavaScript action is the one-line dialog opener (spec §10).

## 2. Placeholders

Same four tokens and values as IMPR1120 (`__WORKSPACE_ID__` 23232323, `__APP_ID__` 202530, `__SCHEMA_NAME__` CUSTOMS, `__ID_OFFSET__` 460632461717563830). The offset must match the installed application. See `apex/IMPR1120/import_notes.md` §2 for the queries.

## 3. Prerequisites

1. **Application 202530 contains the IMPR1110 and IMPR1120 exports.** This export reuses:
   - the page group `IMPR` (`wwv_flow_api.id(900001000010)`);
   - `LOV_ALLOWED_EXPORT` (by name);
   - `LOV_SUSPN_SIDE_CD` (`wwv_flow_api.id(912005000020)`, grid column `SUSPN_SIDE_CD`).

   The full-application file has them all.
2. **`FORMS_APX` 004 and `LOV_APX`** compiled (`plsql_templates/forms_apx.sql`, `plsql_templates/lov_apx.sql`), as for IMPR1120.
3. **Package `IMPR1125` 001** compiled as `LIB_APX_USR.IMPR1125`. Run the spec, then the body. The spec ends with the public synonym and the 4 grants. `SELECT IMPR1125.PKG_VERSION FROM dual` must show `VERSION NO. IS:001`. Grants for `LIB_APX_USR` are listed in the extraction report §7:
   - SELECT on `HQ_IMPRS`, `SINGLE_IMPORTERS`, `BUS_ID_TYPES`, `COUNTRIES`, `CITIES`, `IMPR_TYPES`, `CG_REF_CODES`, `IMPORTER_BASIC_DATA`;
   - SELECT / INSERT / UPDATE on `IMPR_CNTRL_SUSPNS`;
   - EXECUTE on `ACTIVITY_DB`, `HIJDATE_DB`, `GNRL`, `SMS_MESSAGE`.

   `GNRL`, `SMS_MESSAGE` and `APEX_NOTIFICATIONS` have no source in the repository.
4. **`CUSTOMS` needs SELECT** for the region queries on `HQ_IMPRS`, `IMPR_CNTRL_SUSPNS`, `SINGLE_IMPORTERS` and `CG_REF_CODES`. The grid DML runs in the package (definer rights).
5. Plug-in `COM.FOS.EXECUTE_PLSQL_CODE` (f345).

## 4. Import

**A. Component import into 202530:** App Builder → Import → *Page or Component Export* → `apex/IMPR1125/f202530_impr1125_import.sql`. It removes and re-creates pages 1125, 112501 and 112502 and creates no shared component. After a component-only import, page 0 needs the `NUMBER ONLY` DA and the `FUNCS` region once by hand, as described in the IMPR1120 notes.

**B. Full application:** `apex/f202530_full.sql`. It **replaces** application 202530 completely.

**JavaScript (needs approval, CLAUDE.md §4c):** DA `HQ_IMPRS POST-QUERY` has one *Execute JavaScript Code* line, `apex.navigation.redirect($v('P1125_DELETED_SUSPENSIONS_URL'));`. It runs after the native Confirm, as for IMPR1110's dialog 111002. If you do not approve it, a button that opens the same URL can replace the question.

## 5. Parameters not seen in f345 (check after the import)

- DA event server-side condition: `p_display_when_type => 'EXPRESSION'`, `p_display_when_cond`, `p_display_when_cond2 => 'PLSQL'` (`HQ_IMPRS POST-QUERY`).
- Page Load DA actions with `p_execute_on_page_init => 'N'` (Confirm + JavaScript): confirm that they run on page load.
- IG column `p_readonly_condition_type => 'ALWAYS'` (`SUSPN_SIDE_CD`).
- `create_ig_report p_rows_per_page => 9`.
- As in IMPR1120:
  - IG select list on a shared LOV;
  - IG column default from an item;
  - IG DML Target Type PL/SQL Code;
  - read-only Form region;
  - Display Only based on LOV;
  - Submit Page attributes;
  - DA client conditions `NOT_NULL` / Enter key.

## 6. Test after the import (smoke test)

1. Open page 1125 and type a known unified number in الرقم الموحد → the page reloads with the importer and its active central suspensions. Type an unknown number → "الرقم الموحد للمستورد المدخل غير صحيح…".
2. Leave the number empty and type a business id in الرقم الاستدلالى → the first matching HQ_IMPRS row opens.
3. Open an importer that has released suspensions → the question "توجد إيقافات محذوفة…" appears. OK opens dialog 112502 with the released rows. Close returns to 1125 and the importer is still open.
4. Add a suspension: start date (Hijri), notes. The side shows 5 and is read only. SAVE → `SUSPN_SEQ` = MAX + 1, row in `IMPR_CNTRL_SUSPNS` with reason 1 and side 5, activity `(9, 7, 1)`.
5. End date before start date → " لا يمكن ان يكون تاريخ نهاية الأيقاف أصغر من تاريخ بداية الأيقاف".
6. Delete a row + SAVE → the row disappears; in the table `SUSPN_RLSE_DT` = today (Hijri) and it shows on 112502.
7. Page 0 DELETE → refused (`PRE_DELETE`).
8. Search page (page 0 SEARCH) → type part of a name → click the unified number → 1125 opens on that importer.
