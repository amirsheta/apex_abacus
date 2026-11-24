> **Canvas/Window notes**
> - `LSIDE`, `EDI_MSG`, `TITLE`, `TOOLBAR` and window `CGSO$WINDOW_1` (title "صيانة توقيفات المستوردين") come from `CIC_OLB.olb`: the screen frame, not migrated.
> - One content canvas `CG$PAGE_1` (no tab pages) holds the importer header (15 items) and the suspension grid (4 visible columns × 9 rows: start, end, notes, side). In APEX: one main page with a Form region `HQ_IMPRS` and an IG `IMPR_CNTRL_SUSPNS`.
