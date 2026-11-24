
---

## 5. Buttons

Page 1110 has **no buttons of its own**. Every Forms toolbar button maps to page 0 (§14):

| Forms | Page 0 (f345) | What happens on page 1110 |
|---|---|---|
| TOOLBAR.SAVE (COMMIT) on a new record | `CREATE` (P0_PAGE_PK null) | DA `PRE-INSERT CONFIRM` (brokers), validations, PRE-INSERT → Process form → POST-INSERT → `P0_PAGE_PK AFTER INSERT` |
| TOOLBAR.SAVE on a queried record | `SAVE` | validations, PRE-UPDATE → Process form → POST-UPDATE |
| TOOLBAR.REMOVE / KEY-DELREC | `DELETE` (confirm on page 0) | process `KEY-DELREC` → `P0_PAGE_PK AFTER DELETE` |
| TOOLBAR.RE_ENTER_QUERY / ENTER / EXECUTE | `SEARCH` → page 111001 | – |
| KEY-CLRFRM / TOOLBAR.CLEAR | `CLEAR` (redirect, clear cache) | – (WHEN-CLEAR-BLOCK only sets `:GLOBAL.STAT_CLR`, which no code reads) |
| KEY-F9 / TOOLBAR.FUN_BUT | `FUNCS` → region `FUNCS` | DAs `<CODE> EXECUTE-FUNCTION` (§10.3) |
| TOOLBAR.EXIT | `BACK` | – |

Page 111002 buttons: §3.

## 6. LOVs

**Type (CLAUDE.md §4d, 2026-11-24):** every SQL LOV below is a *PL/SQL Function Body returning SQL Query* that calls the common package `LOV_APX` (`plsql_templates/lov_apx.sql`); the SQL column is the query the function returns. `LOV_SD_PORTS` → `PORTS(P_PORT_TYPE_ITEM => 'P_PORT_TYPE')`; `LOV_IMPR_TYPE` → `IMPORTER_TYPES(P_ALL_STATUSES_ITEM => 'G_CHK_IMP_TYP')`; `LOV_IMPR_TYPE_BUS_ID` → `BUSINESS_ID_TYPES`; `LOV_CITIES_IMP_ID` → `CITIES_OF_BUSINESS_ID`; `LOV_CITIES_IMP_BRNH` → `CITIES(P_COUNTRY_ITEM => 'P1110_CTRY_CD', P_WITH_MINISTRY_CODE => TRUE)`; `LOV_CITIES` → `CITIES(P_COUNTRY_ITEM => 'P1110_ADD_CTRY_CD')`; `LOV_COUNTRIES` → `COUNTRIES`; `LOV_COUNTRIES_GULF` → `GULF_COUNTRIES`; `LOV_IMPR` → `IMPORTERS(P_PORT_ITEM => 'P_CURR_PORT_CD')`; `LOV_COMM_RGSTRTN_TYPE` / `LOV_ALLOWED_EXPORT` → `REFERENCE_CODES(P_DOMAIN => ...)`.

Built from the LOV forms' block query (`forms/COMMON/lov_forms/*.xml`) with the parameters IMPR1110 passes,
as in revision 1. Binds now use the f345 items. Popup LOVs show the code in the field (Display = return
value, as in Forms); the name is shown by the separate display item, which the item's WHEN-VALIDATE-ITEM
DA fills (FOS *Items to Return*). No Popup LOV "additional outputs" are needed.

| Forms LOV | APEX LOV (Shared Component) | Type | SQL (display, return, …) | Used by | Item type | Cascading parent(s) | Notes |
|---|---|---|---|---|---|---|---|
| `LOV_SD_PORTS` (form) / `CGFK$IMPORTERS_PORT_CD` | `LOV_SD_PORTS` | SQL | `SELECT port_cd d, port_cd r, port_name FROM sd_ports WHERE port_status = 1 AND port_type = NVL(:P_PORT_TYPE, port_type) ORDER BY port_cd` | P1110_PORT_CD | Popup LOV | – | item is always read-only |
| `LOV_Impr_Type` (form), type part / `CGFK$IMPORTERS_IMPR_TYPE_CD` | `LOV_IMPR_TYPE` | SQL | `SELECT DISTINCT itidt.impr_type_cd d, itidt.impr_type_cd r, it.impr_type_name FROM impr_type_id_types itidt, impr_types it WHERE it.impr_type_cd = itidt.impr_type_cd AND itidt.impr_type_cd > 0 AND (:G_CHK_IMP_TYP = '1' OR itidt.status = 1) ORDER BY 2` | P1110_IMPR_TYPE_CD | Popup LOV | – | |
| `LOV_Impr_Type` (form), bus-id-type part | `LOV_IMPR_TYPE_BUS_ID` | SQL | `SELECT bit.bus_id_type_name d, itidt.bus_id_type_cd r FROM impr_type_id_types itidt, bus_id_types bit WHERE bit.bus_id_type_cd = itidt.bus_id_type_cd AND itidt.impr_type_cd = :P1110_IMPR_TYPE_CD AND itidt.impr_type_cd > 0 AND (:G_CHK_IMP_TYP = '1' OR itidt.status = 1) ORDER BY itidt.bus_id_type_cd` | P1110_BUS_ID_TYPE_CD | Select List | P1110_IMPR_TYPE_CD | the LOV form returns the pair; APEX: type, then bus-id type |
| `LOV_CITIES_IMP` (form) for CITY_CODE_OF_ID / `CGFK$IMPORTERS_CITY_CODE_OF_ID` | `LOV_CITIES_IMP_ID` | SQL | `SELECT city_cd d, city_cd r, city_arb_name, mins_comm_cd FROM cities WHERE city_status = 1 AND ctry_cd = NVL(CASE WHEN :P1110_IMPR_TYPE_CD = 3 AND :P1110_BUS_ID_TYPE_CD = 2 THEN 100 ELSE TO_NUMBER(:P1110_CTRY_CD) END, ctry_cd) ORDER BY ctry_cd, city_cd` | P1110_CITY_CODE_OF_ID | Popup LOV | IMPR_TYPE_CD, BUS_ID_TYPE_CD, CTRY_CD | `:GLOBAL.MINS_COMM_CD` of the LOV form: set by CITY_CODE_OF_ID WHEN-VALIDATE-ITEM (TODO-VERIFY) |
| `LOV_CITIES_IMP` (form) for BRNH_CITY_CD | `LOV_CITIES_IMP_BRNH` | SQL | `SELECT city_cd d, city_cd r, city_arb_name, mins_comm_cd FROM cities WHERE city_status = 1 AND ctry_cd = NVL(:P1110_CTRY_CD, ctry_cd) ORDER BY ctry_cd, city_cd` | P1110_BRNH_CITY_CD | Popup LOV | CTRY_CD | |
| `LOV_CITIES` (form) / `CGFK$IMPORTERS_ADD_CTRY_CD` (city part) | `LOV_CITIES` | SQL | `SELECT city_cd d, city_cd r, city_arb_name FROM cities WHERE city_status = 1 AND ctry_cd = NVL(:P1110_ADD_CTRY_CD, ctry_cd) ORDER BY ctry_cd, city_cd` | P1110_CITY_CODE | Popup LOV | ADD_CTRY_CD | |
| `LOV_COUNTRIES` (form) / `CGFK$IMPORTERS_ADD_CTRY_CD` | `LOV_COUNTRIES` | SQL | `SELECT ctry_cd d, ctry_cd r, crty_arbc_name FROM countries WHERE ctry_status = 1 AND ctry_cd NOT IN (-1) ORDER BY ctry_cd` | P1110_ADD_CTRY_CD | Popup LOV | – | item always read-only (value 100) |
| `LOV_COUNTRIES` / `LOV_COUNTRIES_GULF` (PU CALL_LOV_COUNTRIES / CALL_LOV_COUN_GULF) / `CGFK$IMPORTERS_CTRY_CD` | `LOV_COUNTRIES_GULF` | SQL | `SELECT ctry_cd d, ctry_cd r, crty_arbc_name FROM countries WHERE (:P1110_IMPR_TYPE_CD = 4 AND :P1110_BUS_ID_TYPE_CD = 16 AND ctry_cd IN (113,116,117,119,120,100)) OR (NOT (NVL(:P1110_IMPR_TYPE_CD,0) = 4 AND NVL(:P1110_BUS_ID_TYPE_CD,0) = 16) AND ctry_status = 1) ORDER BY ctry_cd` | P1110_CTRY_CD | Popup LOV | IMPR_TYPE_CD, BUS_ID_TYPE_CD | Gulf list hard-coded in LOV_COUNTRIES_GULF |
| `LOV_IMPR` (form) | `LOV_IMPR` | SQL | `SELECT impr_nbr d, impr_nbr r, arbc_impr_name, bus_id, bus_id_brnch, impr_tel_nbr FROM importers WHERE port_cd = :P_CURR_PORT_CD` | P1110_IMPR_NBR_PARENT | Popup LOV | – | |
| list item COMM_RGSTRTN_TYPE (`CGDV$POPULATE_DYNAMIC_LISTS`) | `LOV_COMM_RGSTRTN_TYPE` | SQL | `SELECT rv_meaning d, rv_low_value r FROM cg_ref_codes WHERE rv_domain = 'COMM_RGSTRTN_TYPE' ORDER BY 2` | P1110_COMM_RGSTRTN_TYPE | Select List | – | |
| list item IMPR_EXPR_TYPE (`CGDV$POPULATE_DYNAMIC_LISTS`) | `LOV_ALLOWED_EXPORT` | SQL | `SELECT rv_meaning d, rv_low_value r FROM cg_ref_codes WHERE rv_domain = 'ALLOWED EXPORT' ORDER BY 2` | P1110_IMPR_EXPR_TYPE | Select List | – | |
| list item EXPRESS_POST | `LOV_EXPRESS_POST` | Static | `0` لا · `1` نعم · `2` تم انشاءه بواسطة البريد السريع | P1110_EXPRESS_POST | Select List | – | |
| pop list CAR_AGENT_FLAG | `LOV_CAR_AGENT_FLAG` | Static | `0` ليس وكيل سيارات · `1` وكيل سيارات | P1110_CAR_AGENT_FLAG | Select List | – | |
| `CGFK$IMPORTERS_HQ_IMPR_NBR`, `CGDV$IMPORTERS_CREATION_FLAG`, `CGDV$IMPORTERS_CUSTOMS_ENTERED` | – | – | – | – | – | – | not needed (display-only / hidden items) |

Before creating them, check f345 for an existing LOV with the same query (f345 rule: never re-create a
shared component). f345 has none of these names today.

## 7. Validations (page 1110)

Every item validation calls the item's `<ITEM>_VALIDATION` function, which runs the converted POST-CHANGE +
WHEN-VALIDATE-ITEM code and returns the error text (NULL = OK). Error display: inline with field and in
notification. Condition: request `CREATE` or `SAVE`. The `<ITEM> REQUIRED` validations add the required
rules that change at runtime. The static Forms *Required* items use the item attribute Value Required = Yes.
TODO-VERIFY in step 05: an item disabled by a `READ ONLY` DA is not submitted, so check that its Value
Required check does not fire on an empty locked item (Forms does not ask for a non-enterable item).

