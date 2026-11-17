> **Parameter/global notes**
> - 20 `P_*` parameters (user id/name, port, class, user type, job, module id …) are inherited from the OLB without defaults; they are passed in by the calling menu/launcher (`CIC_MENU` / `EXECUTE_FUNCTION` of the caller) — **MISSING SOURCE** for their origin.
> - :GLOBAL variables are used as return channels from the LOV forms (CITY_CD, CTRY_CD, IMPR_NBR, PORT_CD, PORT_NAME, MOBILE_NO …) and as control flags (FLAGUPDATE, CHK_DUP_BUSID, FUNS_BUSID, ALLOW_MCI, ALLOW_MOI …). `CURRENT_VER=22` and `CURRENT_DT='29-03-2025'` are version stamps.
> - `:SYSTEM.MESSAGE_LEVEL` is forced to 25 around `FORMS_DDL('COMMIT')` in UPDATE_IMPORTER to suppress messages.

