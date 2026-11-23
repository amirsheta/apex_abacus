> **Canvas/Window notes**
> - `LSIDE`, `EDI_MSG`, `TITLE`, `TOOLBAR` and window `CGSO$WINDOW_1` (title "بيانات المستورد") come from `CIC_OLB.olb`: the screen frame, not migrated.
> - One content canvas `CG$PAGE_1` (no tab pages) holds the importer header (23 items) and the suspension grid (5 columns × 5 rows). In APEX: one main page with a Form region `IMPORTERS` and an IG `IMPR_SUSPN`.
