# IMPR2110 – Import notes (report page, f345 standard + report standard 13-b)

> ⚠️ **REVIEW BEFORE IMPORT.** Generated `wwv_flow_api` code is not an officially supported way to build APEX
> applications. Import into a **DEV** workspace first, back up application 202530, and review the page in
> Page Designer. **Not imported yet.**

Form `IMPR2110.fmb` «طباعة بيانات المستوردين» → page **2110** `IMPR2110` (report parameters; no search page).
Design: [IMPR2110_apex_page_spec.md](../../analysis/IMPR2110/IMPR2110_apex_page_spec.md). Generator: `scripts/gen_apex_impr2110.py`.

## 1. Files

| File | Content |
|---|---|
| `apex/IMPR2110/f345_impr2110.sql` | component export with the 4 placeholders |
| `apex/IMPR2110/f202530_impr2110_import.sql` | the same with workspace 23232323, application 202530, offset 460632461717563830, schema CUSTOMS |
| `plsql/IMPR2110/impr2110_spec.sql`, `impr2110_body.sql` | package `LIB_APX_USR.IMPR2110` 001 |
| `plsql_templates/lov_apx.sql` | package `LOV_APX` **003** (`IMPORTERS` + optional `P_DEFAULT_PORT_ITEM`; previous `rollback/LOV_APX/v002/`) |
| `registry/IMPR2110_registry.sql` | MIG_FORM_REGISTRY / MIG_OBJECT_MAP rows |

Contents: 1 page, 3 regions (hero `TITLE`, static `CALLING_PARAMETERS`, read-only IG `CTR_BLK`), 10 items, 5 processes
(Before Header), 5 dynamic actions (5 FOS actions, **2 one-line JavaScript actions** that open the report URL), 1 LOV.

Regenerate: `python3 -I scripts/gen_apex_impr2110.py --workspace-id=23232323 --app-id=202530 --id-offset=460632461717563830 --schema=CUSTOMS`
(the self-check must print `problems: none`).

## 2. Prerequisites

1. Application 202530 holds the **IMPR1110** export: page group IMPR `id(900001000010)`, LOV `LOV_SD_PORTS`.
2. **FORMS_APX 004** (`CHECK_ERROR`, `GET_MODULE_ID`, `HEADER_TITLE`).
3. **LOV_APX 003** compiled (`SELECT LOV_APX.PKG_VERSION FROM dual`). `CUSTOMS` needs SELECT on `IMPORTERS`, `SD_PORTS`.
   **003 renames the 8 functions used by one LOV only to the LOV name** (user decision 2026-11-25): `PORTS` → `LOV_SD_PORTS`,
   `PORTS_WITH_TYPES` → `LOV_SD_PORTS_TYPES`, `COUNTRIES` → `LOV_COUNTRIES`, `IMPORTER_TYPES` → `LOV_IMPR_TYPE`,
   `CITIES_OF_BUSINESS_ID` → `LOV_CITIES_IMP_ID`, `SINGLE_IMPORTERS` → `LOV_SINGLE_IMPORTERS`, `HARMONIZED_TARIFF` →
   `LOV_HARMONIZED_TARIFF`, `SUPPORT_TITLES` → `LOV_SUPP_TITLES`. The old names are gone, so an application that still holds
   the earlier IMPR1110 / IMPR1140 / SUPPORT_ENTRY exports gets "PLS-00302" in those LOVs. **Compile 003 and re-import
   those exports (or `apex/f202530_full.sql`) together.** All exports in `apex/` already call the new names.
4. **Package IMPR2110 001** as `LIB_APX_USR.IMPR2110` (spec, then body). `LIB_APX_USR` needs direct grants:
   SELECT on `IMPORTERS`, `HQ_IMPRS`, `SD_PORTS`, `SC_PORT_SETTING`; EXECUTE on **`SC_PORT_SETTINGS_PKG`**.
   That package has no source in this repository. Check that `GET_SC_PORT_REPORT_URL(port, 23, text)` exists, as in
   the WVR packages of Forms_to_APEX, or the body does not compile.
5. **`IMPR2110.rdf` deployed on the Reports Server** that `GET_SC_PORT_REPORT_URL` points to.
6. `SC_PORT_SETTING` rows for the module (SYSOBJ_ID = `P2110_MODULE_ID`): `P_SYS_ID`, `P_REP_NO` (report number in the
   hero; without them it shows `-`), and optionally `P_REPORT_FILE` (default `IMPR2110`).

## 3. Import

App Builder → Import → *Page or Component Export* → `apex/IMPR2110/f202530_impr2110_import.sql`. It removes and re-creates
page 2110 and creates `LOV_REP_IMPR` (IDs `2110…`, `9210…`, checked against f345 and every other export).
Full application: add `apex/IMPR2110/f345_impr2110.sql` to the `scripts/build_full_app.py` command of
`apex/IMPR1140/import_notes.md` §4 B (not run).

## 4. After import – tests

1. Page 0 toolbar on 2110: **عرض** and **طباعة** shown, **الوظائف** hidden, SAVE / DELETE hidden. CREATE and SEARCH stay
   (f345 page 0 conditions only look at `P0_PAGE_PK`): SEARCH says «لا توجد شاشة بحث لهذه الشاشة», and CREATE reloads the page.
   To hide them, the page 0 conditions would have to change (a shell decision, not made here).
2. Port user (P_CURR_PORT_CD ≠ 99): no port item; the hero shows the port name.
3. Head office (99): wrong port code → «رمز الجمرك غير صحيح»; a valid one fills the name.
4. Pick importers in «اختيار مستورد»: each one is added to «رقم المستورد» once, and the grid lists numbers and names.
   Typing `1, 2,` works; typing letters → list error; an unknown number shows «هذا المستورد غير موجود».
5. عرض / طباعة with no matching importer → «لا يوجد سجلات تحقق المطلوب», and no tab opens.
6. عرض with matches → new tab with the RDF (`DESTYPE=SCREEN`). طباعة → `DESTYPE=PRINTER` (Reports Server printer).
   **The browser may block the tab**: `window.open` runs after the AJAX call, as on f202604 page 2100. Allow
   pop-ups for the APEX host.
7. **Expected finding**: the RDF in the repository filters `HQ_IMPR_NBR = :P_IMPR_NBR`, which the form does not send →
   empty report. See spec §12.1 before raising it as a conversion bug.

## 5. Uncertain parameters (not in f345; check after import)

- DA on a custom event of `document`: `p_triggering_element_type JAVASCRIPT_EXPRESSION`, `p_triggering_element document`,
  `p_bind_event_type custom` + `p_bind_event_type_custom` (as the real 21.2 export f202604, page 2100).
- Static content region (control block) with the Form-region template *Interactive Report*.
- Read-only IG for the non-database multi-record block `CTR_BLK`, `p_rows_per_page` 5.
- Item display condition `p_display_when` / `p_display_when2 PLSQL` / `p_display_when_type EXPRESSION` (IMPR1110 uses it).
- `NATIVE_CLEAR` on an item (IMPR1120 uses it); DA client condition `NOT_NULL` (IMPR1110 uses it).
- Shared LOV `FUNC_BODY_RETURNING_SQL` (as every LOV_APX LOV).
