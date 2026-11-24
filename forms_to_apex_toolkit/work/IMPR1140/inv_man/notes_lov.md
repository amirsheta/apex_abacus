> **LOV notes**
> - `CGFK$IMPR_RULE_PORTS_PORT_CD` (SD_PORTS) and `CGFK$IMPR_RULE_TARIFF_HRMNZD_C` (HARMONIZED_TARIFF) are Designer FK lookups attached to their items, but KEY-LISTVAL replaces them with the LOV forms `LOV_SD_PORTS` (active ports, `PORT_TYPE = :P_PORT_TYPE`, `STATUS = 1`) and `LOV_TRF_ITEMS` (tariff dictionary search, returns `:GLOBAL.HRMNZD_CODE`).
> - `HQ_IMPR_NBR` has no Forms LOV; `SINGLE_IMP_LOV` calls `LOV_IMPORT_HQ_NBR` (block on `SINGLE_IMPORTERS`) or, for rule type 12, `LOV_IMPORT_HQ_N12` (block on `IMPORTERS`); both return `HQ_IMPR_NBR`, `BUS_ID`, `ARBC_IMPR_NAME` through globals.
> - `CALL_IMPR_TYPE` (`LOV_Impr_Type`) is defined but called by no trigger.
> - Runtime record group `CGDV$DLRG` fills 4 list items from `CG_REF_CODES` (`RULE_TYPE`, and `REC_STATUS` three times) → shared LOVs on `CG_REF_CODES`. `CGLT$CVS_DATA` is Designer tab metadata, not a list.
