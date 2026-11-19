> **Block notes**
> - `TITLE`, `EDI_MSG`, `LSIDE`, `TOOLBAR` are control blocks subclassed entirely from `CIC_OLB.olb`; their properties are in `forms/COMMON/olb/CIC_OLB_OLB.xml` (revision 2). They are the screen frame and are replaced by the f345 page template, page 0 toolbar and `FUNCS` region.
> - `IMPORTERS` has `DeleteAllowed=false` but `IMPORTERS.KEY-DELREC` performs a delete (`Delete_record` + DB `COMMIT`) when the `REMOVE` item is visible/enabled — see risk #13.
> - The WHERE clause binds to `:PARAMETER.P_CURR_PORT_CD`; `PRE-QUERY` additionally appends `CG$IMPR1110_PROD_CENTRL_GLOBAL.IMPORTERS_WHERE` via SET_BLOCK_PROPERTY.

