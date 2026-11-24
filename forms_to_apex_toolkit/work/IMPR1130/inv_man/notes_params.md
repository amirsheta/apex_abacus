> **Parameter/global notes**
> - 23 module parameters: 20 `P_*` inherited from the OLB without defaults (passed by the launchers `APPS` / `BUTTON_LAST_TREE`), the Designer `CG$STARTUP_MODE`, and the form's own `LETTER_NBR` and `PRSNL_IMPR` (no defaults). IMPR1110's `CODE` parameter (function modes F1–F5, SF6) **does not exist** in IMPR1130.
> - Mapping to f345 items as decided for IMPR1110: `P_USER_ID` → `SSO_APP_USER`, `P_WS_ID` → `P_GLOBAL_V_WS_ID`, `P_USER_TYPE` → `V_USR_TYPE`; `P_CURR_PORT_CD`, `P_CLASS_CD`, `P_PORT_TYPE` keep their names.
> - :GLOBAL variables are return channels of the LOV forms (CITY_CD, CTRY_CD, IMPR_TYPE_CD, BUS_ID_TYPE_CD …), SUPPORT_ENTRY's letter (LETTER_NBR, LETTER_DT, SUPP_TITLE_CD, PORT_CD), control flags (ALLOW_MCI, ALLOW_MOI, VALID, EXEC_QUERY_NOW, SET, INS) and version stamps (`CURRENT_VER=11`, `CURRENT_DT='12-12-2023'`).
> - `:SYSTEM.MESSAGE_LEVEL` is forced to 25 around `FORMS_DDL('COMMIT')` in UPDATE_IMPORTER.
