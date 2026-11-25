-- =============================================================================
-- Package body: IMPR2180   (matches impr2180_spec.sql - f345 standard)
-- Source form : IMPR2180.fmb   Target: APEX 21.2 / DB 12.1.0.2   Version: 001
-- Author      : Claude Code     Created: 2026-11-25   (see the spec history)
-- Rules: no Forms built-ins (FORMS_APX instead), no COMMIT / ROLLBACK, no V('...'),
--        parameters named after their binds without I_ / IO_ / O_; page items P<page>_X -> P_X;
--        inside SQL every parameter is qualified with its member name; identifiers <= 30 bytes.
-- Common helpers: FORMS_APX (version 004), called as FORMS_APX.<NAME>.
-- Layout (docs/f345_reference_standard.md §10): PRIVATE HELPERS -> VERSION -> FORM LEVEL -> BLOCK CONTROL
-- -> BLOCK TOOLBAR -> PROGRAM UNITS.
-- Status: NOT COMPILED. The report: IMPR2180_ARD (plsql/IMPR2180).
-- =============================================================================
SET DEFINE OFF

CREATE OR REPLACE PACKAGE BODY LIB_APX_USR.IMPR2180
AS
    c_all_ports        CONSTANT VARCHAR2(2)  := '99';         -- P_CURR_PORT_CD 99 = head office (all ports)
    -- ARD server settings in SC_PORT_SETTING (user decision 2026-11-25): SYSOBJ_ID 999, PORT_CD 99, VAR_NAME ARD_URL / ARD_DSNAME
    c_settings_object  CONSTANT VARCHAR2(10) := '999';
    c_msg_ard_setting  CONSTANT VARCHAR2(200) := 'إعداد خادم التقارير غير موجود في SC_PORT_SETTING (SYSOBJ_ID 999، PORT_CD 99): ';
    c_ard_function     CONSTANT VARCHAR2(60) := 'LIB_APX_USR.IMPR2180_ARD.ARD_IMPR2180';
    c_number_pattern   CONSTANT VARCHAR2(20) := '^[0-9]+$';

    -- PU LOAD_LIST: CG_REF_CODES domain LIC_TYPE without RV_LOW_VALUE 3
    c_lic_type_domain  CONSTANT VARCHAR2(30) := 'LIC_TYPE';
    c_lic_type_skipped CONSTANT VARCHAR2(1)  := '3';
    c_msg_lic_type     CONSTANT VARCHAR2(100) := 'نوع الرخصة غير صحيح';   -- SUGGESTION: new text (no Forms message)

    -- =========================================================================
    -- PRIVATE HELPERS
    -- =========================================================================

    -- A menu parameter of the module (:PARAMETER.<p_name> in Forms): SC_PORT_SETTING of the user's
    -- port and the module (SYSOBJ_ID), else p_default (the Forms ParameterInitializeValue). As IMPR2110.
    -- SUGGESTION: the same lookup exists in every converted report screen; a candidate for FORMS_APX.
    FUNCTION parameter_value (p_name         IN VARCHAR2,
                              p_module_id    IN VARCHAR2,
                              p_curr_port_cd IN VARCHAR2,
                              p_default      IN VARCHAR2)
       RETURN VARCHAR2
    IS
        v_value VARCHAR2(4000);
    BEGIN
        SELECT MAX(s.var_value)
          INTO v_value
          FROM sc_port_setting s
         WHERE s.port_cd   = p_curr_port_cd
           AND s.sysobj_id = p_module_id
           AND s.var_name  = p_name;
        RETURN NVL(v_value, p_default);
    EXCEPTION
        WHEN OTHERS THEN               -- module id / port not numeric
            RETURN p_default;
    END parameter_value;

    -- a typed number (Forms Number item): the number, or NULL when it is empty or not digits only
    FUNCTION number_or_null (p_value IN VARCHAR2)
       RETURN NUMBER
    IS
    BEGIN
        RETURN CASE WHEN REGEXP_LIKE(TRIM(p_value), c_number_pattern) THEN TO_NUMBER(TRIM(p_value)) END;
    END number_or_null;

    -- ardpdf parameter: &P_PARAMETER<n>=<value>, URL-escaped (UTF-8), as PRINT_IMPR2110_ARD
    FUNCTION ard_parameter (p_n IN PLS_INTEGER, p_value IN VARCHAR2)
       RETURN VARCHAR2
    IS
    BEGIN
        RETURN CHR(38) || 'P_PARAMETER' || p_n || '=' || UTL_URL.ESCAPE(p_value, TRUE, 'UTF-8');
    END ard_parameter;

    -- =========================================================================
    -- VERSION
    -- =========================================================================
    FUNCTION PKG_VERSION
       RETURN VARCHAR2
    IS
    BEGIN
       RETURN V_INFO;
    END PKG_VERSION;

    -- =========================================================================
    -- FORM LEVEL
    -- =========================================================================

    -- Source: WHEN-NEW-FORM-INSTANCE
    -- Original Forms code (business part):
    --   :REPORT_NO := (:PARAMETER.P_SYS_ID ||'-'|| :PARAMETER.P_REP_NO);
    --   LOAD_LIST;
    --   SELECT port_name INTO :P_CURR_PORT_NAME FROM SD_PORTS WHERE PORT_CD = :parameter.P_CURR_PORT_CD;
    --   (repeated in a block with EXCEPTION WHEN NO_DATA_FOUND THEN NULL; then the VISIBLE lines -> P_PORT_CD_IS_VISIBLE)
    --   (title / date / window / logo lines -> f345 shell; LOAD_LIST -> LOV_LIC_TYPE)
    -- SUGGESTION: the first SELECT has no handler, so an unknown P_CURR_PORT_CD stopped the form with ORA-01403; here
    --   the port name is left empty (the handler of the second, identical SELECT).
    PROCEDURE WHEN_NEW_FORM_INSTANCE (P_REPORT_NO        OUT VARCHAR2,
                                      P_CURR_PORT_NAME   OUT VARCHAR2,
                                      P_MODULE_ID        IN  VARCHAR2,
                                      P_CURR_PORT_CD     IN  VARCHAR2)
    IS
        v_curr_port_cd NUMBER := number_or_null(P_CURR_PORT_CD);
    BEGIN
        P_REPORT_NO := parameter_value('P_SYS_ID', P_MODULE_ID, P_CURR_PORT_CD, NULL)
                       || '-' || parameter_value('P_REP_NO', P_MODULE_ID, P_CURR_PORT_CD, NULL);
        P_CURR_PORT_NAME := NULL;
        SELECT p.port_name
          INTO WHEN_NEW_FORM_INSTANCE.P_CURR_PORT_NAME
          FROM sd_ports p
         WHERE p.port_cd = v_curr_port_cd;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            NULL;
    END WHEN_NEW_FORM_INSTANCE;

    -- Source: WHEN-NEW-FORM-INSTANCE, IF :PARAMETER.P_CURR_PORT_CD != 99 THEN ... VISIBLE PROPERTY_FALSE (see the spec)
    FUNCTION P_PORT_CD_IS_VISIBLE (P_CURR_PORT_CD IN VARCHAR2)
       RETURN BOOLEAN
    IS
    BEGIN
        RETURN NVL(P_CURR_PORT_CD, c_all_ports) = c_all_ports;
    END P_PORT_CD_IS_VISIBLE;

    -- =========================================================================
    -- BLOCK CONTROL
    -- =========================================================================

    -- Source: CONTROL.P_PORT_CD.WHEN-VALIDATE-ITEM (see the spec)
    FUNCTION P_PORT_CD_VALIDATION (P_PORT_CD IN VARCHAR2)
       RETURN VARCHAR2
    IS
        v_port_cd NUMBER := number_or_null(P_PORT_CD);
        v_count   NUMBER;
    BEGIN
        IF TRIM(P_PORT_CD) IS NULL THEN
            RETURN NULL;
        END IF;
        IF v_port_cd IS NULL THEN                  -- not a number (Forms Number item): unknown port
            RETURN FORMS_APX.ARABIC_MESSAGE(1, 120);
        END IF;
        SELECT COUNT(*)
          INTO v_count
          FROM sd_ports p
         WHERE p.port_cd = v_port_cd;
        RETURN CASE WHEN v_count = 0 THEN FORMS_APX.ARABIC_MESSAGE(1, 120) END;
    END P_PORT_CD_VALIDATION;

    -- Source: CONTROL.P_PORT_CD.WHEN-VALIDATE-ITEM (see P_PORT_CD_VALIDATION)
    PROCEDURE P_PORT_CD_WHEN_VALIDATE_ITEM (P_PORT_CD   IN  VARCHAR2,
                                            P_PORT_NAME OUT VARCHAR2)
    IS
        v_port_cd NUMBER := number_or_null(P_PORT_CD);
    BEGIN
        P_PORT_NAME := NULL;
        FORMS_APX.CHECK_ERROR(P_PORT_CD_VALIDATION(P_PORT_CD => P_PORT_CD));
        IF v_port_cd IS NOT NULL THEN
            SELECT p.port_name
              INTO P_PORT_CD_WHEN_VALIDATE_ITEM.P_PORT_NAME
              FROM sd_ports p
             WHERE p.port_cd = v_port_cd;
        END IF;
    END P_PORT_CD_WHEN_VALIDATE_ITEM;

    -- Source: CONTROL.P_LIC_TYPE (List Item filled by PU LOAD_LIST; see the spec)
    -- Original Forms code (PU LOAD_LIST):
    --   CREATE_GROUP_FROM_QUERY('GROUP_TYPE', 'SELECT RV_MEANING, TO_CHAR(RV_LOW_VALUE) FROM CG_REF_CODES
    --                                          WHERE RV_DOMAIN = ''LIC_TYPE'' AND RV_LOW_VALUE != 3');
    --   POPULATE_LIST('P_LIC_TYPE', V_RG_ID);
    FUNCTION P_LIC_TYPE_VALIDATION (P_LIC_TYPE IN VARCHAR2)
       RETURN VARCHAR2
    IS
        v_count NUMBER;
    BEGIN
        IF P_LIC_TYPE IS NULL THEN                 -- not Required: empty = every licence type
            RETURN NULL;
        END IF;
        SELECT COUNT(*)
          INTO v_count
          FROM cg_ref_codes c
         WHERE c.rv_domain     = c_lic_type_domain
           AND c.rv_low_value  = P_LIC_TYPE_VALIDATION.P_LIC_TYPE
           AND c.rv_low_value != c_lic_type_skipped;
        RETURN CASE WHEN v_count = 0 THEN c_msg_lic_type END;
    END P_LIC_TYPE_VALIDATION;

    -- =========================================================================
    -- BLOCK TOOLBAR
    -- =========================================================================

    -- Source: PU PRINT_CHECK_VAL (PRINT «طباعة», KEY-PRINT, KEY-F4) and PU CHECK_VALUE (VIEW «عرض», KEY-F5) - see the spec.
    -- Original Forms code (port rule):
    --   IF :PARAMETER.P_CURR_PORT_CD = 99 THEN
    --      IF :P_PORT_CD IS NULL THEN P_CURR_PORT_CD := NULL; ELSE P_CURR_PORT_CD := :P_PORT_CD; END IF;
    --   ELSE P_CURR_PORT_CD := :PARAMETER.P_CURR_PORT_CD; END IF;
    -- The item checks run again here (the DAs may not have run). V_COUNT := 1: no "no data" message as in Forms.
    PROCEDURE PRINT_CHECK_VAL (P_PORT_CD        IN  VARCHAR2,
                               P_LIC_TYPE       IN  VARCHAR2,
                               P_REPORT_NO      IN  VARCHAR2,
                               P_HERO_TITLE     IN  VARCHAR2,
                               P_CURR_PORT_CD   IN  VARCHAR2,
                               P_REPORT_URL     OUT VARCHAR2)
    IS
        v_port_cd VARCHAR2(10);
    BEGIN
        IF NVL(P_CURR_PORT_CD, c_all_ports) = c_all_ports THEN
            FORMS_APX.CHECK_ERROR(P_PORT_CD_VALIDATION(P_PORT_CD => P_PORT_CD));
            v_port_cd := TO_CHAR(number_or_null(P_PORT_CD));      -- empty = every port
        ELSE
            v_port_cd := P_CURR_PORT_CD;
        END IF;
        FORMS_APX.CHECK_ERROR(P_LIC_TYPE_VALIDATION(P_LIC_TYPE => P_LIC_TYPE));
        P_REPORT_URL := PRINT_IMPR2180_ARD(p_curr_port_cd => v_port_cd,
                                           p_lic_type     => P_LIC_TYPE,
                                           p_module_name  => P_HERO_TITLE,
                                           p_report_no    => P_REPORT_NO);
    END PRINT_CHECK_VAL;

    -- =========================================================================
    -- PROGRAM UNITS
    -- =========================================================================

    -- Source: REP.Run_Product(REPORTS, V_REPORT_FILE, SYNCHRONOUS, RUNTIME, FILESYSTEM, pl_id, NULL)
    -- Pattern: PRINT_<FORM>_ARD of the approved standard 13-b / 13-c (as PRINT_IMPR2170_ARD); no server link in the
    -- code: ARD_URL and ARD_DSNAME are settings (SC_PORT_SETTING, SYSOBJ_ID 999, PORT_CD 99 -
    -- migration/001_ard_settings.sql); a missing setting stops with a message.
    FUNCTION PRINT_IMPR2180_ARD (p_curr_port_cd IN VARCHAR2,
                                 p_lic_type     IN VARCHAR2,
                                 p_module_name  IN VARCHAR2,
                                 p_report_no    IN VARCHAR2)
       RETURN VARCHAR2
    IS
        v_url    VARCHAR2(4000) := parameter_value('ARD_URL', c_settings_object, c_all_ports, NULL);
        v_dsname VARCHAR2(200)  := parameter_value('ARD_DSNAME', c_settings_object, c_all_ports, NULL);
    BEGIN
        IF v_url IS NULL THEN
            FORMS_APX.CHECK_ERROR(c_msg_ard_setting || 'ARD_URL');
        END IF;
        IF v_dsname IS NULL THEN
            FORMS_APX.CHECK_ERROR(c_msg_ard_setting || 'ARD_DSNAME');
        END IF;
        RETURN v_url || CASE WHEN INSTR(v_url, '?') > 0 THEN CHR(38) ELSE '?' END
               || 'func_name=' || c_ard_function
               || ard_parameter(1, p_curr_port_cd)
               || ard_parameter(2, p_lic_type)
               || ard_parameter(3, p_module_name)
               || ard_parameter(4, p_report_no)
               || CHR(38) || 'DsName=' || UTL_URL.ESCAPE(v_dsname, TRUE, 'UTF-8');
    END PRINT_IMPR2180_ARD;

END IMPR2180;
/
SHOW ERRORS
