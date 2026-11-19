> **Item notes**
> - Items of the 4 OLB control blocks have no attributes in the form XML; they are inherited from `CIC_OLB.olb` (`CIC_OLB_OLB.xml`) and are not migrated (screen frame).
> - In `IMPORTERS`, 75 items have no ItemType (Text Item via OLB property class, e.g. `CGSO$CHAR`, `CGSO$LOV_BUT`) and 3 are List Items populated at runtime by `CGDV$POPULATE_DYNAMIC_LISTS` (CG_REF_CODES).
> - Items whose name ends in `2` / `_LOV` (e.g. `PORT_CD2`, `BRNH_CITY_CD_LOV`) are LOV buttons calling `DO_KEY('LIST_VALUES')`.
> - Hijri date items (`BUS_ID_EXPRD_DT`, `BUS_ID_ISSUE_DT`) are passed as `TO_CHAR(...,'MI-MM-YYYY')` and validated by `HIJDATE.VALID_HIJ_DATE` (`CIC_LIB.pld` → DB `HIJDATE_DB.VALID_HIJ_DATE`, `plsql/Shared`).

