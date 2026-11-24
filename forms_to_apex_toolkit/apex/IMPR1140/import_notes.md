# IMPR1140 – Import notes (step 04, f345 standard)

> ⚠️ **REVIEW BEFORE IMPORT.** Generated `wwv_flow_api` code is not an officially supported way to build APEX
> applications. Import into a **DEV** workspace first, back up application 202530, and review both pages in
> Page Designer. **Not imported yet.**

Form `IMPR1140.fmb` "قواعد التعامل مع المستوردين" → pages **1140** `IMPR1140` (main) and **114001** `IMPR1140_SEARCH`.
Design: [IMPR1140_apex_page_spec.md](../../analysis/IMPR1140/IMPR1140_apex_page_spec.md). Generator: `scripts/gen_apex_impr1140.py`.

## 1. Files

| File | Content |
|---|---|
| `apex/IMPR1140/f345_impr1140.sql` | component export with the 4 placeholders (§2); 2,450 lines |
| `apex/IMPR1140/f202530_impr1140_import.sql` | the same with workspace 23232323, application 202530, offset 460632461717563830, schema CUSTOMS (ready for App Builder) |
| `plsql/IMPR1140/impr1140_spec.sql`, `impr1140_body.sql` | package `LIB_APX_USR.IMPR1140` 001 |
| `plsql_templates/lov_apx.sql` | package `LOV_APX` **002** (new `SINGLE_IMPORTERS`, `HARMONIZED_TARIFF`; previous `rollback/LOV_APX/v001/`) |
| `registry/IMPR1140_registry.sql` | MIG_FORM_REGISTRY / MIG_OBJECT_MAP rows |

Contents: 2 pages, 7 regions (hero, Form `IMPR_RULES`, Tabs Container `CG$M_TAB_1`, IGs `IMPR_RULE_PORTS` / `IMPR_RULE_TARIFF`, search criteria, search IG), 14 page items, 30 grid columns, 5 validations, 20 processes, 10 dynamic actions (5 FOS actions, **0 JavaScript actions**), 1 branch, 2 buttons (search page), 5 LOVs, 5 Text Messages. No application item, no authorization scheme, no page group.

Regenerate: `python3 -I scripts/gen_apex_impr1140.py --workspace-id=23232323 --app-id=202530 --id-offset=460632461717563830 --schema=CUSTOMS` (the self-check must print `problems: none`).

## 2. Placeholders (file `f345_impr1140.sql` only)

| Token | Value / how to get it |
|---|---|
| `__WORKSPACE_ID__` | `SELECT workspace_id FROM apex_workspaces WHERE workspace = '<NAME>';` (23232323) |
| `__APP_ID__` | target application, installed from f345 (202530) |
| `__SCHEMA_NAME__` | parsing schema (CUSTOMS) |
| `__ID_OFFSET__` | `SELECT template_id - 11621850520475869674 FROM apex_application_temp_page WHERE application_id = 202530 AND template_name = 'Standard';` (460632461717563830). Template IDs resolve only when the offset matches the installed application |

## 3. Prerequisites

1. **Application 202530 holds the IMPR1110 export** (page group `IMPR` `wwv_flow_api.id(900001000010)` and LOV `LOV_SD_PORTS` `wwv_flow_api.id(900005000010)` are reused). Without them the import fails (ORA-02291) or the ports column has no LOV.
2. **`FORMS_APX` 004** compiled (`plsql_templates/forms_apx.sql`): the pages and the package call `FORMS_APX.CHECK_ERROR`, `REQUIRED_VALIDATION`, `GET_MODULE_ID`, `HEADER_TITLE`, `ROWID_FROM_URL`, `ARABIC_MESSAGE`, `CG_MESSAGE`, `MESSAGE`, `FORM_TRIGGER_FAILURE`.
3. **`LOV_APX` 002** compiled (`plsql_templates/lov_apx.sql`): `SELECT LOV_APX.PKG_VERSION FROM dual` shows 002. The LOVs `LOV_SINGLE_IMPORTERS` and `LOV_HARMONIZED_TARIFF` call the two new functions. `CUSTOMS` needs SELECT on `SINGLE_IMPORTERS`, `IMPORTERS`, `HARMONIZED_TARIFF`, `CG_REF_CODES` (the returned query runs as the parsing schema).
4. **Package `IMPR1140` 001** compiled as `LIB_APX_USR.IMPR1140` (spec, then body; the spec ends with the public synonym and the 4 grants). Direct grants for `LIB_APX_USR` are listed in the extraction report §7. **`LIB_USR.SMS_MESSAGE` has no source in the repository**: check that `SEND_SMS_MESSAGE` exists with the 8 arguments of the Forms call, or the body does not compile.
5. **`CUSTOMS` grants:** SELECT, INSERT, UPDATE, DELETE on `IMPR_RULES` (native `Process form`); SELECT on `IMPR_RULE_PORTS`, `IMPR_RULE_TARIFF`, `SD_PORTS`, `HARMONIZED_TARIFF`, `BUS_ID_TYPES`, `IMPORTERS`, `SINGLE_IMPORTERS`, `CG_REF_CODES` (region queries). The grid DML runs inside `IMPR1140` (definer rights), so no DML grant on the detail tables for `CUSTOMS`.
6. **FOS *Execute PL/SQL Code*** plug-in of f345 and the page 0 DA `NUMBER ONLY` (`scripts/number_only.py`; present when the full application file was imported, otherwise add it once by hand as described in `apex/IMPR1120/import_notes.md` §4) for the `number_only` class of `EXEPTION_QTY`.

## 4. Import

**A. Component import into 202530** (recommended): App Builder → Import → *Page or Component Export* → `apex/IMPR1140/f202530_impr1140_import.sql`, or `sql CUSTOMS@<tns> @apex/IMPR1140/f202530_impr1140_import.sql`. It removes and re-creates pages 1140 and 114001 and creates the 5 LOVs and 5 Text Messages with fixed IDs (IDs `1140…`, `114001…`, `9140…`, checked against f345 and every other export in `apex/`). If APEX reports a duplicate LOV or message name on a re-import, delete them first (not verified).

**B. Full application:** `python3 -I scripts/build_full_app.py --app-id=202530 --shift-ids=460632461717563830 apex/IMPR1110/f345_impr1110.sql apex/IMPR1120/f345_impr1120.sql apex/SUPPORT_ENTRY/f345_support_entry.sql apex/IMPR1116/f345_impr1116.sql apex/IMPR1125/f345_impr1125.sql apex/IMPR1140/f345_impr1140.sql` and import `apex/f202530_full.sql` (replaces the whole application). Not run in this step: `apex/f202530_full.sql` was being changed by another session.

## 5. After import – review and tests

1. Page Designer 1140 / 114001: no "invalid template" warnings; the two IGs are inside the Tabs Container and show as tabs "جمارك الإستثناء" / "بنود التعريفة المستثاه"; run Advisor.
2. Page 0 toolbar: CREATE / SEARCH with no rule open; SAVE / DELETE with a rule open.
3. Search 114001: no rows until a text is entered; search by rule number, importer number, type name; the link opens the rule (ROWID with `+` / `/` works).
4. CREATE: type 9 refused at once; unified importer number fills the business id, branch, type and name (type 12: importer of the user's port); type 13 / 14 without role `IMP_EXCEPTION_FASH` refused; `RULE_ISN` = MAX + 1; activity log row (9, 4, 1); type 14 active → SMS.
5. ALL_BRNCH_FLAG = 1 clears and disables the branch (also on page load of such a rule); a port row added then is refused with the placeholder text.
6. Ports tab: only the user's port rows; port code checked (name filled), not editable after save; activity log (9, 5, 1/2/3).
7. Tariff tab: unknown item / item already excepted for the same importer refused; description and international unit filled; quantity copies to the remaining quantity and shows the information alert; `ITEM_SEQUENCE` = MAX + 1 in the rule; no delete (no delete in the row menu); activity log (9, 6, 1/2).
8. DELETE: refused while the rule has a port row (message 1-270 / Designer text) or tariff rows; otherwise deleted, activity log (9, 4, 3), page empty.
9. SAVE of a type-14 rule sends the SMS again (Forms behaviour, inventory §15 #2).

## 6. Uncertain parameters (not in f345; check after import)

- DA client-side condition `JAVASCRIPT_EXPRESSION` `this.browserEvent.which === 13` (Enter key).
- DA client-side condition `EQUALS` + `p_triggering_expression`, with FALSE actions (`ALL_BRNCH_FLAG WHEN-VALIDATE-ITEM`).
- DA client-side condition `NOT_NULL` (IMPR1110 uses it).
- FOS Items to Return = IG columns (`PORT_NAME`, `HT_ITEM_ARBC_DESC`, `INTL_UNIT`, `REMAINED_QTY`).
- IG column default from a page item: `p_default_type => ITEM` (`RULE_ISN` ← `P1140_RULE_ISN`).
- IG select list / popup LOV column on a shared LOV: `p_lov_type => SHARED` + `p_lov_id`.
- `NATIVE_ALERT` with the text in `p_attribute_01`.
- `NATIVE_CLEAR` / `NATIVE_ENABLE` / `NATIVE_DISABLE` with `p_affected_elements_type => ITEM`.
- Form region `p_edit_operations => 'i:u:d'`; second `NATIVE_FORM_DML` process for DELETE.
- `NATIVE_IG_DML` with Target Type PL/SQL Code (`p_attribute_01 => PLSQL_CODE`, code in `p_attribute_04`); the code sets `:ROW_ID` / `:ITEM_SEQUENCE` of a new row (IN OUT parameters).
- ROWID primary key of the Form region (as IMPR1110).
- Tabs Container region with the IGs as sub-regions (`p_parent_plug_id`).
- Button DA `p_triggering_button_id`; `create_ig_report p_rows_per_page` (8); search IG lazy loading / no total row count.
- `p_item_default` static on the Select Lists (1 / 0 / 1).
- Shared LOV `FUNC_BODY_RETURNING_SQL`; `create_message` (ar-sa).

## 7. Notes, deviations and open items

- Display Only items `BUS_ID_TYPE_CD` / `BUS_ID` are saved by `Process form` from session state (FOS returns them; *Send On Page Submit* = No, as IMPR1110). Check after import that an insert stores them; if not, set *Send On Page Submit* = Yes.
- `HQ_IMPR_NBR VALIDATION` also runs on SAVE of an unchanged rule (page spec §16 #2).
- New texts to agree: ports insert with all ports, tariff delete, rule with tariff rows (extraction report §4).
- The non-blocking message "الوحدة الدولية غير معرفة" is not shown (inventory §15 #7).
- `LOV_APX` 002 changes a shared package: other forms keep working (functions only added), but sessions converting other forms in parallel must start from version 002.
