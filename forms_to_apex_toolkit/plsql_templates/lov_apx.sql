-- =============================================================================
-- Owner       : LIB_APX_USR (public synonym LOV_APX; EXECUTE granted to LIB_USR, SECURITY_DEFAULT, SECURITY_PROD, CUSTOMS)
-- Package     : LOV_APX
-- Purpose     : The SQL of every shared List of Values, common to all systems (IMPR, SC, ...).
--               Each APEX shared LOV has the type "PL/SQL Function Body returning SQL Query" and only calls
--               one function here, for example:
--                   return LOV_APX.CITIES(P_COUNTRY_ITEM => 'P1110_ADD_CTRY_CD');
--               so a list (ports, countries, cities ...) is written once and every page of every system uses
--               the same query.
-- Target      : Oracle APEX 21.2 / Oracle Database 12.1.0.2
-- Author      : Claude Code
-- Created     : 2026-11-24
-- Version     : 002
-- Contract    : every function returns the text of a SELECT with the columns  D (display), R (return), then the
--               columns shown in the list. The shared LOV sets Return Column R, Display Column D.
--               Page or application items are NOT read here: the caller passes the NAME of the item
--               (P_..._ITEM => 'P1110_CTRY_CD') and the query keeps it as a bind variable (:P1110_CTRY_CD),
--               so APEX binds the session value, the cursor is shared and cascading LOVs keep working.
--               Item names are checked with DBMS_ASSERT.SIMPLE_SQL_NAME, literals with DBMS_ASSERT.ENQUOTE_LITERAL
--               (no SQL injection through the parameters).
-- Grants      : APEX runs the returned query as the parsing schema (CUSTOMS), not as LIB_APX_USR: the table
--               names stay unqualified as in the old LOV queries, and LIB_APX_USR needs no grant on the tables.
-- Names       : full words (CLAUDE.md §4); the Forms LOV / record group is named in each function's Source.
-- Rules       : every identifier <= 30 bytes (DB 12.1.0.2); no COMMIT / ROLLBACK.
-- Status      : NOT COMPILED (no database in this session). Install before importing the APEX exports.
-- History     : 2026-11-24 Claude Code 001 Initial version (user request: LOV type function body returning SQL
--                          query, code in the common package LOV_APX)
--               2026-11-24 Claude Code 002 IMPR1140: SINGLE_IMPORTERS (unified importer numbers, by rule type) and
--                          HARMONIZED_TARIFF (tariff items). Previous version: rollback/LOV_APX/v001/
-- =============================================================================
SET DEFINE OFF

CREATE OR REPLACE PACKAGE LIB_APX_USR.LOV_APX AS
   V_PKG_VERSION       VARCHAR2 (100) := 'VERSION NO. IS:' || '002';
   V_PKG_VERSION_QC    VARCHAR2 (100) := 'VERSION NO. IS:' || '002';
   V_PKG_VERSION_DEV   VARCHAR2 (100) := 'VERSION NO. IS:' || '002';
   FUNCTION PKG_VERSION
      RETURN VARCHAR2;
   V_PACKAGE_NAME      VARCHAR2 (50) := 'LOV_APX';
   V_LAST_MODIFY_DT    VARCHAR2 (10) := '24-11-2026';
   V_MODIFIED_BY       VARCHAR2 (50) := 'Claude Code';
   V_INFO              VARCHAR2 (500)
      :=    'PACKAGE NAME :  '
         || V_PACKAGE_NAME
         || CHR (10)
         || CHR (13)
         || V_PKG_VERSION
         || CHR (10)
         || CHR (13)
         || 'MODIFIED DATE : '
         || V_LAST_MODIFY_DT
         || CHR (10)
         || CHR (13)
         || 'MODIFIED BY : '
         || V_MODIFIED_BY;

    -- =========================================================================
    -- CODE TABLES (CG_REF_CODES)
    -- =========================================================================
    -- Source: CGDV$POPULATE_DYNAMIC_LISTS (list items / pop lists on a CG_REF_CODES domain)
    -- Columns: D = RV_MEANING, R = RV_LOW_VALUE.  Used as a Select List.
    FUNCTION REFERENCE_CODES (P_DOMAIN IN VARCHAR2)
       RETURN VARCHAR2;

    -- =========================================================================
    -- PORTS (SD_PORTS)
    -- =========================================================================
    -- Source: LOV form LOV_SD_PORTS / CGFK$<BLOCK>_PORT_CD
    -- Columns: D = R = PORT_CD, PORT_NAME.  Active ports of the user's port type (f345 item P_PORT_TYPE).
    FUNCTION PORTS (P_PORT_TYPE_ITEM IN VARCHAR2 DEFAULT 'P_PORT_TYPE')
       RETURN VARCHAR2;

    -- Source: SUPPORT_ENTRY record group LOV_SD_PORTS (SD_PORTS + CG_REF_CODES domain PORT_TYPE_CD)
    -- Columns: D = R = PORT_CD, RV_MEANING (port type), PORT_NAME.
    FUNCTION PORTS_WITH_TYPES
       RETURN VARCHAR2;

    -- =========================================================================
    -- COUNTRIES AND CITIES
    -- =========================================================================
    -- Source: LOV form LOV_COUNTRIES / CGFK$<BLOCK>_<ITEM>_CTRY_CD
    -- Columns: D = R = CTRY_CD, CRTY_ARBC_NAME.
    FUNCTION COUNTRIES
       RETURN VARCHAR2;

    -- Source: IMPR1110 PU CALL_LOV_COUNTRIES / CALL_LOV_COUN_GULF
    -- Columns: D = R = CTRY_CD, CRTY_ARBC_NAME.  Importer type 4 with business id type 16: the gulf countries
    -- only; otherwise every active country.
    FUNCTION GULF_COUNTRIES (P_IMPORTER_TYPE_ITEM      IN VARCHAR2,
                             P_BUSINESS_ID_TYPE_ITEM   IN VARCHAR2)
       RETURN VARCHAR2;

    -- Source: LOV form LOV_CITIES / LOV_CITIES_IMP
    -- Columns: D = R = CITY_CD, CITY_ARB_NAME (+ MINS_COMM_CD when P_WITH_MINISTRY_CODE).
    -- Active cities of the country in item P_COUNTRY_ITEM (all countries when it is empty).
    FUNCTION CITIES (P_COUNTRY_ITEM         IN VARCHAR2,
                     P_WITH_MINISTRY_CODE   IN BOOLEAN DEFAULT FALSE)
       RETURN VARCHAR2;

    -- Source: LOV form LOV_CITIES_IMP on IMPORTERS.CITY_CODE_OF_ID
    -- Columns: D = R = CITY_CD, CITY_ARB_NAME, MINS_COMM_CD.  As CITIES, but importer type 3 with business id
    -- type 2 always uses country 100.
    FUNCTION CITIES_OF_BUSINESS_ID (P_COUNTRY_ITEM            IN VARCHAR2,
                                    P_IMPORTER_TYPE_ITEM      IN VARCHAR2,
                                    P_BUSINESS_ID_TYPE_ITEM   IN VARCHAR2)
       RETURN VARCHAR2;

    -- =========================================================================
    -- IMPORTERS
    -- =========================================================================
    -- Source: LOV form LOV_Impr_Type (type part) / CGFK$IMPORTERS_IMPR_TYPE_CD
    -- Columns: D = R = IMPR_TYPE_CD, IMPR_TYPE_NAME.  Item P_ALL_STATUSES_ITEM = '1' (Forms :GLOBAL.CHK_IMP_TYP)
    -- also lists the inactive types.
    FUNCTION IMPORTER_TYPES (P_ALL_STATUSES_ITEM IN VARCHAR2)
       RETURN VARCHAR2;

    -- Source: LOV form LOV_Impr_Type (business id type part)
    -- Columns: D = BUS_ID_TYPE_NAME, R = BUS_ID_TYPE_CD.  Business id types of the importer type in
    -- P_IMPORTER_TYPE_ITEM.  Used as a Select List.
    FUNCTION BUSINESS_ID_TYPES (P_IMPORTER_TYPE_ITEM   IN VARCHAR2,
                                P_ALL_STATUSES_ITEM    IN VARCHAR2)
       RETURN VARCHAR2;

    -- Source: LOV form LOV_IMPR
    -- Columns: D = R = IMPR_NBR, ARBC_IMPR_NAME, BUS_ID, BUS_ID_BRNCH, IMPR_TEL_NBR.  Importers of the port in
    -- item P_PORT_ITEM (default: the f345 item P_CURR_PORT_CD, the user's port).
    FUNCTION IMPORTERS (P_PORT_ITEM IN VARCHAR2 DEFAULT 'P_CURR_PORT_CD')
       RETURN VARCHAR2;

    -- Source: IMPR1140 PU SINGLE_IMP_LOV -> LOV forms LOV_IMPORT_HQ_NBR (SINGLE_IMPORTERS) and LOV_IMPORT_HQ_N12
    --         (IMPORTERS, used when the rule type is 12)
    -- Columns: D = R = HQ_IMPR_NBR, ARBC_IMPR_NAME, BUS_ID.  P_RULE_TYPE_ITEM = item holding the rule type;
    --          rule type 12 lists the importers of the port in P_PORT_ITEM (default: the user's port).
    FUNCTION SINGLE_IMPORTERS (P_RULE_TYPE_ITEM IN VARCHAR2,
                               P_PORT_ITEM      IN VARCHAR2 DEFAULT 'P_CURR_PORT_CD')
       RETURN VARCHAR2;

    -- =========================================================================
    -- TARIFF
    -- =========================================================================
    -- Source: IMPR1140 record group CGFK$IMPR_RULE_TARIFF_HRMNZD_C (LOV form LOV_TRF_ITEMS)
    -- Columns: D = R = HRMNZD_CODE, ITEM_ARBC_DESC.
    FUNCTION HARMONIZED_TARIFF
       RETURN VARCHAR2;

    -- =========================================================================
    -- SUPPORT LETTERS
    -- =========================================================================
    -- Source: SUPPORT_ENTRY record group LOV_SUPP_TITLES
    -- Columns: D = R = SUPP_TITLE_CD, SUPP_TITLE_NM.  Active titles.
    FUNCTION SUPPORT_TITLES
       RETURN VARCHAR2;
END LOV_APX;
/
SHOW ERRORS

CREATE OR REPLACE PACKAGE BODY LIB_APX_USR.LOV_APX
AS
    -- =========================================================================
    -- HELPERS
    -- =========================================================================
    -- ':<ITEM>' - a bind variable for an APEX page or application item; raises ORA-44003 for anything that is
    -- not a simple name.
    FUNCTION BIND_VARIABLE (P_ITEM_NAME IN VARCHAR2)
       RETURN VARCHAR2
    IS
    BEGIN
       RETURN ':' || DBMS_ASSERT.SIMPLE_SQL_NAME (UPPER (TRIM (P_ITEM_NAME)));
    END BIND_VARIABLE;

    -- =========================================================================
    -- CODE TABLES (CG_REF_CODES)
    -- =========================================================================
    FUNCTION REFERENCE_CODES (P_DOMAIN IN VARCHAR2)
       RETURN VARCHAR2
    IS
    BEGIN
       RETURN    'SELECT rv_meaning d, rv_low_value r FROM cg_ref_codes'
              || ' WHERE rv_domain = ' || DBMS_ASSERT.ENQUOTE_LITERAL (P_DOMAIN)
              || ' ORDER BY 2';
    END REFERENCE_CODES;

    -- =========================================================================
    -- PORTS (SD_PORTS)
    -- =========================================================================
    FUNCTION PORTS (P_PORT_TYPE_ITEM IN VARCHAR2 DEFAULT 'P_PORT_TYPE')
       RETURN VARCHAR2
    IS
    BEGIN
       RETURN    'SELECT port_cd d, port_cd r, port_name FROM sd_ports'
              || ' WHERE port_status = 1'
              || ' AND port_type = NVL(' || BIND_VARIABLE (P_PORT_TYPE_ITEM) || ', port_type)'
              || ' ORDER BY port_cd';
    END PORTS;

    FUNCTION PORTS_WITH_TYPES
       RETURN VARCHAR2
    IS
    BEGIN
       RETURN    'SELECT sd_ports.port_cd d, sd_ports.port_cd r, cg_ref_codes.rv_meaning, sd_ports.port_name'
              || ' FROM cg_ref_codes, sd_ports'
              || ' WHERE cg_ref_codes.rv_low_value = sd_ports.port_type'
              || ' AND cg_ref_codes.rv_domain = ''PORT_TYPE_CD'''
              || ' ORDER BY sd_ports.port_cd';
    END PORTS_WITH_TYPES;

    -- =========================================================================
    -- COUNTRIES AND CITIES
    -- =========================================================================
    FUNCTION COUNTRIES
       RETURN VARCHAR2
    IS
    BEGIN
       RETURN    'SELECT ctry_cd d, ctry_cd r, crty_arbc_name FROM countries'
              || ' WHERE ctry_status = 1 AND ctry_cd NOT IN (-1)'
              || ' ORDER BY ctry_cd';
    END COUNTRIES;

    FUNCTION GULF_COUNTRIES (P_IMPORTER_TYPE_ITEM      IN VARCHAR2,
                             P_BUSINESS_ID_TYPE_ITEM   IN VARCHAR2)
       RETURN VARCHAR2
    IS
       V_IMPORTER_TYPE      VARCHAR2 (40) := BIND_VARIABLE (P_IMPORTER_TYPE_ITEM);
       V_BUSINESS_ID_TYPE   VARCHAR2 (40) := BIND_VARIABLE (P_BUSINESS_ID_TYPE_ITEM);
    BEGIN
       RETURN    'SELECT ctry_cd d, ctry_cd r, crty_arbc_name FROM countries'
              || ' WHERE (' || V_IMPORTER_TYPE || ' = 4 AND ' || V_BUSINESS_ID_TYPE || ' = 16'
              ||        ' AND ctry_cd IN (113, 116, 117, 119, 120, 100))'
              || ' OR (NOT (NVL(' || V_IMPORTER_TYPE || ', 0) = 4 AND NVL(' || V_BUSINESS_ID_TYPE || ', 0) = 16)'
              ||        ' AND ctry_status = 1)'
              || ' ORDER BY ctry_cd';
    END GULF_COUNTRIES;

    FUNCTION CITIES (P_COUNTRY_ITEM         IN VARCHAR2,
                     P_WITH_MINISTRY_CODE   IN BOOLEAN DEFAULT FALSE)
       RETURN VARCHAR2
    IS
       V_MINISTRY_CODE   VARCHAR2 (20);
    BEGIN
       IF P_WITH_MINISTRY_CODE
       THEN
          V_MINISTRY_CODE := ', mins_comm_cd';
       END IF;

       RETURN    'SELECT city_cd d, city_cd r, city_arb_name' || V_MINISTRY_CODE || ' FROM cities'
              || ' WHERE city_status = 1'
              || ' AND ctry_cd = NVL(' || BIND_VARIABLE (P_COUNTRY_ITEM) || ', ctry_cd)'
              || ' ORDER BY ctry_cd, city_cd';
    END CITIES;

    FUNCTION CITIES_OF_BUSINESS_ID (P_COUNTRY_ITEM            IN VARCHAR2,
                                    P_IMPORTER_TYPE_ITEM      IN VARCHAR2,
                                    P_BUSINESS_ID_TYPE_ITEM   IN VARCHAR2)
       RETURN VARCHAR2
    IS
    BEGIN
       RETURN    'SELECT city_cd d, city_cd r, city_arb_name, mins_comm_cd FROM cities'
              || ' WHERE city_status = 1'
              || ' AND ctry_cd = NVL(CASE WHEN ' || BIND_VARIABLE (P_IMPORTER_TYPE_ITEM) || ' = 3'
              ||                    ' AND ' || BIND_VARIABLE (P_BUSINESS_ID_TYPE_ITEM) || ' = 2 THEN 100'
              ||                    ' ELSE TO_NUMBER(' || BIND_VARIABLE (P_COUNTRY_ITEM) || ') END, ctry_cd)'
              || ' ORDER BY ctry_cd, city_cd';
    END CITIES_OF_BUSINESS_ID;

    -- =========================================================================
    -- IMPORTERS
    -- =========================================================================
    FUNCTION IMPORTER_TYPES (P_ALL_STATUSES_ITEM IN VARCHAR2)
       RETURN VARCHAR2
    IS
    BEGIN
       RETURN    'SELECT DISTINCT itidt.impr_type_cd d, itidt.impr_type_cd r, it.impr_type_name'
              || ' FROM impr_type_id_types itidt, impr_types it'
              || ' WHERE it.impr_type_cd = itidt.impr_type_cd'
              || ' AND itidt.impr_type_cd > 0'
              || ' AND (' || BIND_VARIABLE (P_ALL_STATUSES_ITEM) || ' = ''1'' OR itidt.status = 1)'
              || ' ORDER BY 2';
    END IMPORTER_TYPES;

    FUNCTION BUSINESS_ID_TYPES (P_IMPORTER_TYPE_ITEM   IN VARCHAR2,
                                P_ALL_STATUSES_ITEM    IN VARCHAR2)
       RETURN VARCHAR2
    IS
    BEGIN
       RETURN    'SELECT bit.bus_id_type_name d, itidt.bus_id_type_cd r'
              || ' FROM impr_type_id_types itidt, bus_id_types bit'
              || ' WHERE bit.bus_id_type_cd = itidt.bus_id_type_cd'
              || ' AND itidt.impr_type_cd = ' || BIND_VARIABLE (P_IMPORTER_TYPE_ITEM)
              || ' AND itidt.impr_type_cd > 0'
              || ' AND (' || BIND_VARIABLE (P_ALL_STATUSES_ITEM) || ' = ''1'' OR itidt.status = 1)'
              || ' ORDER BY itidt.bus_id_type_cd';
    END BUSINESS_ID_TYPES;

    FUNCTION IMPORTERS (P_PORT_ITEM IN VARCHAR2 DEFAULT 'P_CURR_PORT_CD')
       RETURN VARCHAR2
    IS
    BEGIN
       RETURN    'SELECT impr_nbr d, impr_nbr r, arbc_impr_name, bus_id, bus_id_brnch, impr_tel_nbr'
              || ' FROM importers'
              || ' WHERE port_cd = ' || BIND_VARIABLE (P_PORT_ITEM);
    END IMPORTERS;

    FUNCTION SINGLE_IMPORTERS (P_RULE_TYPE_ITEM IN VARCHAR2,
                               P_PORT_ITEM      IN VARCHAR2 DEFAULT 'P_CURR_PORT_CD')
       RETURN VARCHAR2
    IS
    BEGIN
       RETURN    'SELECT hq_impr_nbr d, hq_impr_nbr r, arbc_impr_name, bus_id FROM single_importers'
              || ' WHERE NVL(' || BIND_VARIABLE (P_RULE_TYPE_ITEM) || ', 0) <> 12'
              || ' UNION ALL'
              || ' SELECT hq_impr_nbr d, hq_impr_nbr r, MAX(arbc_impr_name), MAX(bus_id) FROM importers'
              || ' WHERE ' || BIND_VARIABLE (P_RULE_TYPE_ITEM) || ' = 12'
              || ' AND port_cd = ' || BIND_VARIABLE (P_PORT_ITEM)
              || ' AND hq_impr_nbr IS NOT NULL'
              || ' GROUP BY hq_impr_nbr';
    END SINGLE_IMPORTERS;

    -- =========================================================================
    -- TARIFF
    -- =========================================================================
    FUNCTION HARMONIZED_TARIFF
       RETURN VARCHAR2
    IS
    BEGIN
       RETURN    'SELECT hrmnzd_code d, hrmnzd_code r, item_arbc_desc FROM harmonized_tariff'
              || ' ORDER BY hrmnzd_code';
    END HARMONIZED_TARIFF;

    -- =========================================================================
    -- SUPPORT LETTERS
    -- =========================================================================
    FUNCTION SUPPORT_TITLES
       RETURN VARCHAR2
    IS
    BEGIN
       RETURN    'SELECT supp_title_cd d, supp_title_cd r, supp_title_nm FROM supp_titles'
              || ' WHERE title_status = 1'
              || ' ORDER BY supp_title_cd';
    END SUPPORT_TITLES;

    -- =========================================================================
    -- PACKAGE VERSION   (SELECT LOV_APX.PKG_VERSION FROM dual;)
    -- =========================================================================
    FUNCTION PKG_VERSION
       RETURN VARCHAR2
    IS
    BEGIN
       RETURN V_INFO;
    END PKG_VERSION;

END LOV_APX;
/
SHOW ERRORS

-- -----------------------------------------------------------------------------
-- Synonym and grants (run as a user allowed to create public synonyms / grant on LIB_APX_USR).
-- CUSTOMS = parsing schema of the APEX application: APEX needs the direct grant.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PUBLIC SYNONYM LOV_APX FOR LIB_APX_USR.LOV_APX;

GRANT EXECUTE ON LIB_APX_USR.LOV_APX TO LIB_USR;

GRANT EXECUTE ON LIB_APX_USR.LOV_APX TO SECURITY_DEFAULT;

GRANT EXECUTE ON LIB_APX_USR.LOV_APX TO SECURITY_PROD;

GRANT EXECUTE ON LIB_APX_USR.LOV_APX TO CUSTOMS;
