-- =============================================================================
-- IMPR1110 - Shared Components > List of Values (SQL sources)
-- Create each LOV in App Builder (Shared Components > LOVs > Create > From scratch
-- > Dynamic / Static) with the name and query below. Display column first, return
-- column second (APEX 21.2 legacy format), or set Return/Display in the new LOV editor.
-- Source record groups: CGFK$IMPORTERS_* in IMPR1110.fmb
-- Status: NOT executed against the database - verify column names/status values.
-- =============================================================================

-- LOV_SD_PORTS  (Source: CGFK$IMPORTERS_PORT_CD)
SELECT port_name || ' (' || port_cd || ')' AS d, port_cd AS r
  FROM sd_ports
 WHERE port_status = 1
 ORDER BY port_cd;

-- LOV_IMPR_TYPE  (Source: CGFK$IMPORTERS_IMPR_TYPE_CD)
-- Popup LOV, additional return columns via "Additional Outputs" (APEX 21.2):
--   BUS_ID_TYPE_CD:P1110_BUS_ID_TYPE_CD, IMPR_TYPE_NAME:P1110_IMPR_TYPE_NAME,
--   BUS_ID_TYPE_NAME:P1110_BUS_ID_TYPE_NAME
SELECT DISTINCT it.impr_type_name || ' (' || itidt.impr_type_cd || ')' AS d,
       itidt.impr_type_cd                                            AS r
  FROM impr_type_id_types itidt
  JOIN impr_types   it  ON it.impr_type_cd    = itidt.impr_type_cd
 WHERE itidt.status = 1
 ORDER BY 2;

-- LOV_BUS_ID_TYPE  (cascading on P1110_IMPR_TYPE_CD)
SELECT bit.bus_id_type_name || ' (' || itidt.bus_id_type_cd || ')' AS d,
       itidt.bus_id_type_cd                                         AS r
  FROM impr_type_id_types itidt
  JOIN bus_id_types bit ON bit.bus_id_type_cd = itidt.bus_id_type_cd
 WHERE itidt.impr_type_cd = :P1110_IMPR_TYPE_CD
   AND itidt.status = 1
 ORDER BY 2;

-- LOV_COUNTRIES  (Source: CGFK$IMPORTERS_CTRY_CD / ADD_CTRY_CD)
SELECT crty_arbc_name || ' (' || ctry_cd || ')' AS d, ctry_cd AS r
  FROM countries
 WHERE ctry_status = 1
 ORDER BY crty_arbc_name;

-- LOV_COUNTRIES_GULF  (Source: PU CALL_LOV_COUN_GULF - GCC countries, group 1)
SELECT c.crty_arbc_name || ' (' || c.ctry_cd || ')' AS d, c.ctry_cd AS r
  FROM countries c
  JOIN ctry_group_details g ON g.ctry_cd = c.ctry_cd
 WHERE g.grp_cd = 1          -- TODO-VERIFY column names of CTRY_GROUP_DETAILS
   AND g.status = 1
 ORDER BY c.crty_arbc_name;

-- LOV_CITIES  (Source: CGFK$IMPORTERS_CITY_CODE_OF_ID; cascading on P1110_CTRY_CD_OF_ID)
SELECT city_arb_name || ' (' || city_cd || ')' AS d, city_cd AS r
  FROM cities
 WHERE ctry_cd = NVL(:P1110_CTRY_CD_OF_ID, 100)
   AND city_status = 1
 ORDER BY city_arb_name;

-- LOV_CITIES_IMP  (Source: CGFK$IMPORTERS_ADD_CTRY_CD; cascading on P1110_ADD_CTRY_CD)
SELECT ci.city_arb_name || ' (' || ci.city_cd || ')' AS d, ci.city_cd AS r
  FROM cities ci
 WHERE ci.ctry_cd = NVL(:P1110_ADD_CTRY_CD, 100)
   AND ci.city_status = 1
 ORDER BY ci.city_arb_name;

-- LOV_IMPR  (IMPR_NBR_PARENT - importers of the current port)
SELECT arbc_impr_name || ' (' || impr_nbr || ')' AS d, impr_nbr AS r
  FROM importers
 WHERE port_cd = :AI_P_CURR_PORT_CD
 ORDER BY impr_nbr DESC;

-- LOV_COMM_RGSTRTN_TYPE  (static - list item values in the form)
--   رئيسي ; 1
--   فرعي  ; 2      (the form also has value 0 labelled فرعي - legacy rows; TODO-VERIFY)

-- -----------------------------------------------------------------------------
-- Optional: Text Messages for constraint names (pkg_forms_compat.apex_error_handler)
-- Run as the APEX parsing schema inside an APEX session (apex_util.set_workspace)
-- or create them in Shared Components > Text Messages.
-- -----------------------------------------------------------------------------
-- BEGIN
--   apex_util.set_workspace('<WORKSPACE>');
--   wwv_flow_api is NOT public - create via App Builder:
--     IMP_PK              : هذا السجل مدخل سابقاً - أعد ادخال البيانات
--     IMP_BUSID_UK        : هذا السجل مدخل سابقاً - أعد ادخال البيانات
--     IMP_ITIDT_FK        : TODO-VERIFY (copy from Forms ON-ERROR)
--     IMP_CTRY_FK         : TODO-VERIFY
--     IMP_BUS_ID_CITY_FK  : TODO-VERIFY
--     IMP_ADD_CITY_FK     : TODO-VERIFY
-- END;
