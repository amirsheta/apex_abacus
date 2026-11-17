> **LOV notes**
> - All 8 record groups are attached to an LOV; none are orphaned.
> - `CGDV$IMPORTERS_CUSTOMS_ENTERED` is a **static** RG (4 rows).
> - Runtime record group: `CGDV$DLRG` created with `CREATE_GROUP_FROM_QUERY` / `POPULATE_GROUP` / `POPULATE_LIST` in PU `CGDV$POPULATE_DYNAMIC_LISTS` (called from `CG$WHEN_NEW_FORM_INSTANCE` ← WHEN-NEW-FORM-INSTANCE, KEY-CLRFRM).
> - LOV *Validate from list* / *Auto display* properties are not in the XML (inherited from OLB) → **MISSING SOURCE**.
> - In practice most items bypass these LOVs: KEY-LISTVAL calls LOV forms (`LOV_SD_PORTS`, `LOV_Impr_Type`, `LOV_CITIES_IMP`, `LOV_IMPR`, `LOV_COUNTRIES`, `LOV_CITIES`, `LOV_COUNTRIES_GULF`) — see §10.4.

