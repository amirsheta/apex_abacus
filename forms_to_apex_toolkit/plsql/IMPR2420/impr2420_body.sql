-- =============================================================================
-- Package body: IMPR2420   (matches impr2420_spec.sql - f345 standard)
-- Source form : IMPR2420.fmb   Target: APEX 21.2 / DB 12.1.0.2   Version: 001
-- Author      : Claude Code     Created: 2026-11-26   (see the spec history)
-- Rules: no Forms built-ins (FORMS_APX instead), no COMMIT / ROLLBACK, no V('...'),
--        parameters named after their binds without I_ / IO_ / O_; page items P<page>_X -> P_X;
--        inside SQL every parameter is qualified with its member name; identifiers <= 30 bytes.
-- Common helpers: FORMS_APX (version 004), called as FORMS_APX.<NAME>.
-- Layout (docs/f345_reference_standard.md §10): PRIVATE HELPERS -> VERSION -> FORM LEVEL -> BLOCK TOOLBAR
-- -> PROGRAM UNITS.
-- Status: NOT COMPILED. The report: IMPR2420_ARD (plsql/IMPR2420).
-- =============================================================================
SET DEFINE OFF

CREATE OR REPLACE PACKAGE BODY LIB_APX_USR.IMPR2420
AS
    c_all_ports        CONSTANT VARCHAR2(2)  := '99';         -- head office (all ports)
    -- ARD server settings in SC_PORT_SETTING (user decision 2026-11-25): SYSOBJ_ID 999, PORT_CD 99, VAR_NAME ARD_URL / ARD_DSNAME
    c_settings_object  CONSTANT VARCHAR2(10) := '999';
    c_msg_ard_setting  CONSTANT VARCHAR2(200) := 'إعداد خادم التقارير غير موجود في SC_PORT_SETTING (SYSOBJ_ID 999، PORT_CD 99): ';
    c_ard_function     CONSTANT VARCHAR2(60) := 'LIB_APX_USR.IMPR2420_ARD.ARD_IMPR2420';
    c_number_pattern   CONSTANT VARCHAR2(20) := '^[0-9]+$';

    -- CALLING_PARAMETERS.P_TYPE list elements
    c_type_expired     CONSTANT VARCHAR2(1) := '1';           -- منتهي الصلاحية
    c_type_valid       CONSTANT VARCHAR2(1) := '2';           -- غير منتهي الصلاحية
    c_type_all         CONSTANT VARCHAR2(1) := '3';           -- الجميع (InitializeValue / OtherValues)

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
    --   :REPORT_NO := :PARAMETER.P_SYS_ID ||'-'||:PARAMETER.P_REP_NO ;
    --   :GLOBAL.CHPT_CODE := NULL ; :GLOBAL.CHPT_ARB := NULL ;       (no LOV form here -> not needed)
    --   /* IF :PARAMETER.P_CURR_PORT_CD != 99 THEN SELECT PORT_NAME INTO :P_CURR_PORT_NAME FROM SD_PORTS ... */
    --   (title / date / window / logo lines -> f345 shell)
    -- SUGGESTION: the port-name SELECT is commented out in Forms (TITLE.P_CURR_PORT_NAME stayed empty); the f345 hero
    --   shows the user's port name as on the other report pages. Display only; nothing is sent to the report.
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

    -- =========================================================================
    -- BLOCK TOOLBAR
    -- =========================================================================

    -- Source: PU PRINT_CHECK_VAL (PRINT «طباعة», KEY-PRINT, KEY-F4) and PU CHECK_VAL (VIEW «عرض», KEY-F5) - see the spec.
    -- Original Forms code (CHECK_VAL):
    --   IF :P_TYPE IS NULL OR :P_TYPE NOT IN (1,2,3) THEN
    --       :P_TYPE := 3;
    --   END IF;
    --   V_COUNT := 1;
    --   IF V_COUNT > 0 THEN ... Add_Parameter P_TYPE, P_CURR_PORT_CD (= :PARAMETER.P_CURR_PORT_CD), P_REPORT_NO,
    --       P_MODULE_NAME, V_ORDER ... REP.Run_Product ...
    --   ELSE MESSAGE('لا يوجد سجلات تحقق المطلوب'); RAISE FORM_TRIGGER_FAILURE; END IF;   (dead code: V_COUNT = 1)
    -- PRINT_CHECK_VAL is the same without the P_TYPE line; VIEW and PRINT are one button here (DEC-018), so the
    -- CHECK_VAL rule is kept for both. P_TYPE is IN OUT: the page shows the value sent, as Forms did.
    PROCEDURE PRINT_CHECK_VAL (P_TYPE           IN OUT VARCHAR2,
                               P_REPORT_NO      IN  VARCHAR2,
                               P_HERO_TITLE     IN  VARCHAR2,
                               P_CURR_PORT_CD   IN  VARCHAR2,
                               P_REPORT_URL     OUT VARCHAR2)
    IS
    BEGIN
        IF P_TYPE IS NULL OR P_TYPE NOT IN (c_type_expired, c_type_valid, c_type_all) THEN
            P_TYPE := c_type_all;
        END IF;
        P_REPORT_URL := PRINT_IMPR2420_ARD(p_curr_port_cd => P_CURR_PORT_CD,
                                           p_type         => P_TYPE,
                                           p_module_name  => P_HERO_TITLE,
                                           p_report_no    => P_REPORT_NO);
    END PRINT_CHECK_VAL;

    -- =========================================================================
    -- PROGRAM UNITS
    -- =========================================================================

    -- Source: REP.Run_Product(REPORTS, V_REPORT_FILE, SYNCHRONOUS, RUNTIME, FILESYSTEM, pl_id, NULL)
    -- Pattern: PRINT_<FORM>_ARD of the approved standard 13-b / 13-c (as PRINT_IMPR2180_ARD); no server link in the
    -- code: ARD_URL and ARD_DSNAME are settings (SC_PORT_SETTING, SYSOBJ_ID 999, PORT_CD 99 -
    -- migration/001_ard_settings.sql); a missing setting stops with a message.
    FUNCTION PRINT_IMPR2420_ARD (p_curr_port_cd IN VARCHAR2,
                                 p_type         IN VARCHAR2,
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
               || ard_parameter(2, p_type)
               || ard_parameter(3, p_module_name)
               || ard_parameter(4, p_report_no)
               || CHR(38) || 'DsName=' || UTL_URL.ESCAPE(v_dsname, TRUE, 'UTF-8');
    END PRINT_IMPR2420_ARD;

END IMPR2420;
/
SHOW ERRORS
