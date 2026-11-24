> **Parameter/global notes**
> - The 20 `P_*` parameters are inherited from the OLB; they map to the f345 items as in IMPR1110 §12 (`P_USER_ID` → `SSO_APP_USER`, `P_CURR_PORT_CD`, `P_WS_ID` → `P_GLOBAL_V_WS_ID`, …). `P_CURR_PORT_CD` is used for the notification channel setting and as the port of the SMS.
> - **`CURRENT_SIDE`** is declared but **no code reads it** (no side rules in this form; the side is fixed to 5). Not migrated.
> - Globals: `HQ_IMPR_NBR`, `BUS_NBR` drive the "type the number → query" flow; `BUS_ID` (and `ARBC_IMPR_NAME`, not read) are return channels of `LOV_IMPORT_HQ_NBR`; `CG$*` are Designer internals; `CURRENT_VER = 2` is a version stamp; `EXIT`, `SYSTEM_OBJ` belong to the frame. None needs an application item.
