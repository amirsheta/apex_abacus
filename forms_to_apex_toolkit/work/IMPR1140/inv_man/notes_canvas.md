> **Canvas/Window notes**
> - `LSIDE`, `EDI_MSG`, `TITLE`, `TOOLBAR` and window `CGSO$WINDOW_1` (title "قواعد التعامل مع المستوردين") come from `CIC_OLB.olb`: the screen frame, not migrated.
> - `CG$PAGE_1` holds the rule (12 items). The tab canvas `CG$M_TAB_1` has the tab pages `CG$M_TAB_1_PAGE_1` "جمارك الإستثناء" (block IMPR_RULE_PORTS) and `CG$M_TAB_1_PAGE_2` "بنود التعريفة المستثاه" (block IMPR_RULE_TARIFF). In APEX: one main page, a Form region `IMPR_RULES` and a Tabs Container with the two IGs.
