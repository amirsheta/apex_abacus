> **Block notes**
> - `TITLE`, `EDI_MSG`, `LSIDE`, `TOOLBAR` are control blocks subclassed entirely from `CIC_OLB.olb`; their properties (records displayed, navigation, canvas) are **MISSING SOURCE**.
> - `IMPORTERS` has `DeleteAllowed=false` but `IMPORTERS.KEY-DELREC` performs a delete (`Delete_record` + DB `COMMIT`) when the `REMOVE` item is visible/enabled — see risk #13.
> - The WHERE clause binds to `:PARAMETER.P_CURR_PORT_CD`; `PRE-QUERY` additionally appends `CG$IMPR1110_PROD_CENTRL_GLOBAL.IMPORTERS_WHERE` via SET_BLOCK_PROPERTY.

