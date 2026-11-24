> **Canvas/Window notes**
> - `LSIDE`, `EDI_MSG`, `TITLE`, `TOOLBAR` and window `CGSO$WINDOW_1` come from `CIC_OLB.olb`: the screen frame, not migrated.
> - One content canvas `CG$PAGE_1` (no tab pages) holds the portal grid (5 columns × 5 rows) above the importer grid (5 columns + 2 hidden LOV buttons × 10 rows). In APEX: one main page with two Interactive Grids, `IMPR_PRTL_NAT` (editable, update only) and `IMPORTERS` (read only, detail of the selected row).
