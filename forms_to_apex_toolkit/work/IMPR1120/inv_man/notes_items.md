> **Item notes**
> - Items of the 4 OLB control blocks have no attributes in the form XML; they come from `CIC_OLB_OLB.xml` and are not migrated.
> - `IMPORTERS` items are display / query criteria (`Insert/Update allowed = false`); `*_NAME` items are filled by the POST-QUERY lookups (Designer `CGFK$QRY_*`). `PORT_CD2`, `IMPR_TYPE_CD2`, `CTRY_CD2`, `CITY_CODE_OF_ID2`, `BUTT` are LOV buttons (`GO_ITEM` + `DO_KEY('LIST_VALUES')`).
> - `IMPORTERS.IMPR_EXPR_TYPE`, `IMPR_SUSPN.SUSPN_RSN_CD` and `IMPR_SUSPN.SUSPN_SIDE_CD` are list items. The static values in the XML are overwritten at startup by `CGDV$POPULATE_DYNAMIC_LISTS` from `CG_REF_CODES` (domains `ALLOWED EXPORT`, `IMPR_SUSPN_RSN_CD`, `SUSPN SIDE CD`).
> - `SUSPN_STRT_DT`, `SUSPN_END_DT`, `SUSPN_RLSE_DT` are Hijri dates (OLB class `CGSO$HDATE_ARB`), validated by `HIJDATE.VALID_HIJ_DATE` (→ `HIJDATE_DB`), with a calendar on KEY-LISTVAL (`INTRFACE.DISP_CALENDAR`) and KEY-F4 (`INTRFACE.DISP_DATE_CON`).
> - `SUSPN_SEQ`, `SUSPN_RLSE_DT`, `IMPR_NBR`, `PORT_CD` of `IMPR_SUSPN` are hidden. `SUSPN_SEQ` is set in PRE-INSERT (`MAX(SUSPN_SEQ)+1` over the **whole** table) and `SUSPN_RLSE_DT` in PRE-UPDATE / ON-DELETE.
> - Item rules by `:PARAMETER.CURRENT_SIDE` (with `P_CURR_PORT_CD` = 99 or not):
>
> | CURRENT_SIDE / port | Default `SUSPN_RSN_CD` (WNII) | Rejected `SUSPN_RSN_CD` (WVI) | Default `SUSPN_SIDE_CD` (WNII) | Rejected `SUSPN_SIDE_CD` (WLC) | Rows skipped (WNRI `NEXT_RECORD`) |
> |---|---|---|---|---|---|
> | 1, port ≠ 99 | 1 | 2 → reset to 1 | 1 | ≠ 1 → reset to 1 | side ≠ 1 |
> | 2, port ≠ 99 | 2 | 1 → reset to 2 | 2 | 1 or 5 → reset to 2 | side 1 or 5 |
> | 3, port = 99 | 3 | 1, 2 → reset to 3 | 5 | ≠ 5 → reset to 5 | side ≠ 5 |
> | 3, port ≠ 99 | – | 1, 2 → reset to 3 | – | – | – (WNFI exits the form: "ليس لديك الصلاحية للدخول على الشاشة") |
>
> The rejections raise `FORM_TRIGGER_FAILURE` **without a message**. `SUSPN_RSN_CD.WHEN-VALIDATE-ITEM` then copies the `CG_REF_CODES` meaning into `SUSPN_RSN_TEXT` (the user may change it).
> - `SUSPN_SIDE_CD` is enabled only while it is empty (new row); once set (POST-QUERY, POST-INSERT, WNRI) it is disabled.
