> **LOV notes**
> - All 5 record groups are Designer FK lookups attached to an LOV; none is orphaned. `CGFK$IMPORTERS_CTRY_CD` and `CGFK$IMPORTERS_IMPR_TYPE_CD` filter on `STATUS = 1` only in NORMAL mode (all rows in ENTER-QUERY).
> - The LOVs are bypassed: KEY-LISTVAL on PORT_CD, IMPR_TYPE_CD, CTRY_CD and CITY_CODE_OF_ID calls the LOV forms `LOV_SD_PORTS`, `LOV_Impr_Type`, `LOV_COUNTRIES`, `LOV_CITIES` (all available in `forms/COMMON/lov_forms/`), which return values through `:GLOBAL.*`. Because the master items are not insertable or updatable, these LOVs are only usable as **query criteria**. In APEX they become filters on the search page.
> - Runtime record group `CGDV$DLRG` (`CREATE_GROUP_FROM_QUERY` / `POPULATE_LIST`) fills 3 list items from `CG_REF_CODES` → shared LOVs on `CG_REF_CODES`.
> - Domain names differ: the list uses `IMPR_SUSPN_RSN_CD`, and the commented-out code in `SUSPN_RSN_CD.WHEN-NEW-ITEM-INSTANCE` used `SUSPN RSN CD`. Only `IMPR_SUSPN_RSN_CD` is active.
