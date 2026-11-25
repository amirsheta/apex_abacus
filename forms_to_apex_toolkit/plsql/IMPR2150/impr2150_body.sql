-- =============================================================================
-- Package body: IMPR2150   (matches impr2150_spec.sql - f345 standard)
-- Source form : IMPR2150.fmb   Target: APEX 21.2 / DB 12.1.0.2   Version: 001
-- Author      : Claude Code     Created: 2026-11-25   (see the spec history)
-- Rules: no Forms built-ins (FORMS_APX instead), no COMMIT / ROLLBACK, no V('...'),
--        parameters named after their binds without I_ / IO_ / O_; page items P<page>_X -> P_X;
--        inside SQL every parameter is qualified with its member name; identifiers <= 30 bytes.
-- Common helpers: FORMS_APX (version 004), called as FORMS_APX.<NAME>.
-- Layout (docs/f345_reference_standard.md §10): PRIVATE HELPERS -> VERSION -> FORM LEVEL
-- -> BLOCK CALLING_PARAMETERS -> BLOCK TOOLBAR -> PROGRAM UNITS.
-- Status: NOT COMPILED. The report: IMPR2150_ARD (plsql/IMPR2150).
-- =============================================================================
SET DEFINE OFF

CREATE OR REPLACE PACKAGE BODY LIB_APX_USR.IMPR2150
AS
    c_all_ports        CONSTANT VARCHAR2(2)  := '99';         -- P_CURR_PORT_CD 99 = head office (all ports)
    -- ARD server settings in SC_PORT_SETTING (user decision 2026-11-25): SYSOBJ_ID 999, PORT_CD 99, VAR_NAME ARD_URL / ARD_DSNAME
    c_settings_object  CONSTANT VARCHAR2(10) := '999';
    c_msg_ard_setting  CONSTANT VARCHAR2(200) := 'إعداد خادم التقارير غير موجود في SC_PORT_SETTING (SYSOBJ_ID 999، PORT_CD 99): ';
    c_ard_function     CONSTANT VARCHAR2(60) := 'LIB_APX_USR.IMPR2150_ARD.ARD_IMPR2150';
    c_number_pattern   CONSTANT VARCHAR2(20) := '^[0-9]+$';

    -- REC_STATUS values (List Item elements of the XML)
    c_status_active    CONSTANT VARCHAR2(1) := '1';   -- فعال
    c_status_inactive  CONSTANT VARCHAR2(1) := '0';   -- غير فعال

    -- Forms texts
    c_msg_importer     CONSTANT VARCHAR2(200) := 'رقم المستورد المدخل غير صحيح، أدخل الرقم الصحيح أو استخدم القائمة المرفقة';
    c_msg_no_rows      CONSTANT VARCHAR2(100) := 'لا يوجد سجلات تحقق المطلوب';
    -- labels of the required list items (the Forms prompt of RULE_TYPE is a copy of REC_STATUS: «نوع الاستثناء» is used)
    c_label_rec_status CONSTANT VARCHAR2(50) := 'حالة السجل';
    c_label_rule_type  CONSTANT VARCHAR2(50) := 'نوع الاستثناء';

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

    -- Source: the count query of PU PRINT_CHECK_VAL / CHECK_VAL (kept as in Forms, as the IMPR2140 user decision of
    -- 2026-11-25). Original Forms code:
    --   SELECT COUNT(*) INTO V_COUNT
    --   FROM   IMPR_RULES IR,IMPR_RULE_PORTS IRP
    --   WHERE  IR.HQ_IMPR_NBR = :HQ_IMPR_NBR OR :HQ_IMPR_NBR IS NULL
    --     AND  IR.RULE_ISN = IRP.RULE_ISN
    --     AND  ((:REC_STATUS = 1 AND IR.REC_STATUS = 1 AND IRP.REC_STATUS = 1) OR
    --           (:REC_STATUS = 0 AND IR.REC_STATUS = 0))
    --     AND  (BUS_ID_BRNCH = :BUS_ID_BRNCH OR :BUS_ID_BRNCH IS NULL);
    -- AND binds before OR, so Oracle reads it as written below (the parentheses only make it visible).
    -- BUS_ID_BRNCH is IMPR_RULES.BUS_ID_BRNCH (the column the report reads).
    -- SUGGESTION: with an importer number the count is every IMPR_RULES row of that importer times every
    --   IMPR_RULE_PORTS row, without the status / branch rules, so the check passes as soon as the importer has any rule
    --   and the PDF can be empty. The count also ignores RULE_TYPE, which the report filters on. The probable intent is
    --   (IR.HQ_IMPR_NBR = :HQ_IMPR_NBR OR :HQ_IMPR_NBR IS NULL) AND ... AND IR.RULE_TYPE = :RULE_TYPE. To confirm with
    --   the business owner.
    FUNCTION rules_count (p_hq_impr_nbr  IN NUMBER,
                          p_rec_status   IN VARCHAR2,
                          p_bus_id_brnch IN VARCHAR2)
       RETURN NUMBER
    IS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*)
          INTO v_count
          FROM impr_rules ir, impr_rule_ports irp
         WHERE ir.hq_impr_nbr = p_hq_impr_nbr
            OR (    p_hq_impr_nbr IS NULL
                AND ir.rule_isn = irp.rule_isn
                AND (   (p_rec_status = c_status_active AND ir.rec_status = 1 AND irp.rec_status = 1)
                     OR (p_rec_status = c_status_inactive AND ir.rec_status = 0))
                AND (ir.bus_id_brnch = p_bus_id_brnch OR p_bus_id_brnch IS NULL));
        RETURN v_count;
    END rules_count;

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
    --   IF :PARAMETER.P_CURR_PORT_CD != 99 THEN
    --      SELECT PORT_NAME INTO :P_CURR_PORT_NAME FROM SD_PORTS WHERE PORT_CD = :PARAMETER.P_CURR_PORT_CD;
    --   ELSE :P_CURR_PORT_NAME := NULL; END IF;
    --   EXCEPTION WHEN NO_DATA_FOUND THEN NULL;
    --   (:GLOBAL.CHPT_CODE / CHPT_ARB / SEC_CODE / IMPR_NBR / ARBC_IMPR_NAME := NULL - LOV globals, not needed;
    --    window / title lines -> f345 shell; the port item lines are commented out in Forms)
    PROCEDURE WHEN_NEW_FORM_INSTANCE (P_REPORT_NO        OUT VARCHAR2,
                                      P_CURR_PORT_NAME   OUT VARCHAR2,
                                      P_MODULE_ID        IN  VARCHAR2,
                                      P_CURR_PORT_CD     IN  VARCHAR2)
    IS
    BEGIN
        P_REPORT_NO := parameter_value('P_SYS_ID', P_MODULE_ID, P_CURR_PORT_CD, NULL)
                       || '-' || parameter_value('P_REP_NO', P_MODULE_ID, P_CURR_PORT_CD, NULL);
        P_CURR_PORT_NAME := NULL;
        IF P_CURR_PORT_CD <> c_all_ports THEN
            SELECT p.port_name
              INTO WHEN_NEW_FORM_INSTANCE.P_CURR_PORT_NAME
              FROM sd_ports p
             WHERE p.port_cd = WHEN_NEW_FORM_INSTANCE.P_CURR_PORT_CD;
        END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            NULL;
    END WHEN_NEW_FORM_INSTANCE;

    -- =========================================================================
    -- BLOCK CALLING_PARAMETERS
    -- =========================================================================

    -- Source: CALLING_PARAMETERS.HQ_IMPR_NBR.WHEN-VALIDATE-ITEM
    -- Original Forms code:
    --   IF :HQ_IMPR_NBR IS NOT NULL THEN
    --      SELECT BUS_ID, BUS_ID_BRNCH, BUS_ID_TYPE_CD, ARBC_IMPR_NAME
    --      INTO   :BUS_ID, :BUS_ID_BRNCH, :BUS_ID_TYPE_CD, :L_SI_ARBC_IMPR_NAME
    --      FROM   SINGLE_IMPORTERS WHERE HQ_IMPR_NBR = :HQ_IMPR_NBR;
    --      SELECT BUS_ID_TYPE_NAME INTO :BUS_ID_TYPE_NAME FROM BUS_ID_TYPES WHERE BUS_ID_TYPE_CD = :BUS_ID_TYPE_CD;
    --   END IF;
    --   EXCEPTION WHEN OTHERS THEN <clear the five items>;
    --      STR.DISPALERT('رقم المستورد المدخل غير صحيح، أدخل الرقم الصحيح أو استخدم القائمة المرفقة','ERROR'); FTF;
    -- The same failures give the message here: not a number (a Number item in Forms), no or several SINGLE_IMPORTERS
    -- rows, no BUS_ID_TYPES row.
    FUNCTION HQ_IMPR_NBR_VALIDATION (P_HQ_IMPR_NBR IN VARCHAR2)
       RETURN VARCHAR2
    IS
        v_count NUMBER;
    BEGIN
        IF TRIM(P_HQ_IMPR_NBR) IS NULL THEN
            RETURN NULL;
        END IF;
        IF NOT REGEXP_LIKE(TRIM(P_HQ_IMPR_NBR), c_number_pattern) THEN
            RETURN c_msg_importer;
        END IF;
        SELECT COUNT(*)
          INTO v_count
          FROM single_importers si, bus_id_types bt
         WHERE si.hq_impr_nbr    = TO_NUMBER(TRIM(HQ_IMPR_NBR_VALIDATION.P_HQ_IMPR_NBR))
           AND bt.bus_id_type_cd = si.bus_id_type_cd;
        -- exactly one importer row with one business id type, as the two SELECT ... INTO
        IF v_count <> 1 THEN
            RETURN c_msg_importer;
        END IF;
        SELECT COUNT(*)
          INTO v_count
          FROM single_importers si
         WHERE si.hq_impr_nbr = TO_NUMBER(TRIM(HQ_IMPR_NBR_VALIDATION.P_HQ_IMPR_NBR));
        RETURN CASE WHEN v_count <> 1 THEN c_msg_importer END;
    END HQ_IMPR_NBR_VALIDATION;

    -- Source: CALLING_PARAMETERS.HQ_IMPR_NBR.WHEN-VALIDATE-ITEM (see HQ_IMPR_NBR_VALIDATION)
    PROCEDURE HQ_IMPR_NBR_WHEN_VALIDATE_ITEM (P_HQ_IMPR_NBR         IN  VARCHAR2,
                                              P_BUS_ID              OUT VARCHAR2,
                                              P_BUS_ID_BRNCH        OUT VARCHAR2,
                                              P_BUS_ID_TYPE_CD      OUT VARCHAR2,
                                              P_BUS_ID_TYPE_NAME    OUT VARCHAR2,
                                              P_L_SI_ARBC_IMPR_NAME OUT VARCHAR2)
    IS
    BEGIN
        P_BUS_ID              := NULL;
        P_BUS_ID_BRNCH        := NULL;
        P_BUS_ID_TYPE_CD      := NULL;
        P_BUS_ID_TYPE_NAME    := NULL;
        P_L_SI_ARBC_IMPR_NAME := NULL;
        FORMS_APX.CHECK_ERROR(HQ_IMPR_NBR_VALIDATION(P_HQ_IMPR_NBR => P_HQ_IMPR_NBR));
        IF TRIM(P_HQ_IMPR_NBR) IS NOT NULL THEN
            SELECT si.bus_id, si.bus_id_brnch, si.bus_id_type_cd, si.arbc_impr_name, bt.bus_id_type_name
              INTO HQ_IMPR_NBR_WHEN_VALIDATE_ITEM.P_BUS_ID,
                   HQ_IMPR_NBR_WHEN_VALIDATE_ITEM.P_BUS_ID_BRNCH,
                   HQ_IMPR_NBR_WHEN_VALIDATE_ITEM.P_BUS_ID_TYPE_CD,
                   HQ_IMPR_NBR_WHEN_VALIDATE_ITEM.P_L_SI_ARBC_IMPR_NAME,
                   HQ_IMPR_NBR_WHEN_VALIDATE_ITEM.P_BUS_ID_TYPE_NAME
              FROM single_importers si, bus_id_types bt
             WHERE si.hq_impr_nbr    = TO_NUMBER(TRIM(HQ_IMPR_NBR_WHEN_VALIDATE_ITEM.P_HQ_IMPR_NBR))
               AND bt.bus_id_type_cd = si.bus_id_type_cd;
        END IF;
    END HQ_IMPR_NBR_WHEN_VALIDATE_ITEM;

    -- Source: CALLING_PARAMETERS.REC_STATUS (List Item, Required; see the spec)
    FUNCTION REC_STATUS_VALIDATION (P_REC_STATUS IN VARCHAR2)
       RETURN VARCHAR2
    IS
    BEGIN
        IF P_REC_STATUS IS NULL THEN
            RETURN FORMS_APX.REQUIRED_VALIDATION(ITEM_VALUE => P_REC_STATUS, ITEM_LABEL => c_label_rec_status);
        END IF;
        IF P_REC_STATUS NOT IN (c_status_active, c_status_inactive) THEN
            RETURN FORMS_APX.REQUIRED_VALIDATION(ITEM_VALUE => NULL, ITEM_LABEL => c_label_rec_status);
        END IF;
        RETURN NULL;
    END REC_STATUS_VALIDATION;

    -- Source: CALLING_PARAMETERS.RULE_TYPE (Required; LOV319 on CG_REF_CODES domain RULE_TYPE; see the spec)
    FUNCTION RULE_TYPE_VALIDATION (P_RULE_TYPE IN VARCHAR2)
       RETURN VARCHAR2
    IS
        v_count NUMBER;
    BEGIN
        IF TRIM(P_RULE_TYPE) IS NULL THEN
            RETURN FORMS_APX.REQUIRED_VALIDATION(ITEM_VALUE => P_RULE_TYPE, ITEM_LABEL => c_label_rule_type);
        END IF;
        SELECT COUNT(*)
          INTO v_count
          FROM cg_ref_codes c
         WHERE c.rv_domain    = 'RULE_TYPE'
           AND c.rv_low_value = TRIM(RULE_TYPE_VALIDATION.P_RULE_TYPE);
        RETURN CASE WHEN v_count = 0
                    THEN FORMS_APX.REQUIRED_VALIDATION(ITEM_VALUE => NULL, ITEM_LABEL => c_label_rule_type) END;
    END RULE_TYPE_VALIDATION;

    -- =========================================================================
    -- BLOCK TOOLBAR
    -- =========================================================================

    -- Source: PU PRINT_CHECK_VAL (PRINT, KEY-PRINT, KEY-F4) and PU CHECK_VAL (VIEW, KEY-F5) - same code except DESTYPE:
    --   <count> (see rules_count); IF V_COUNT > 0 THEN ... Add_Parameter P_REPORT_NO, P_MODULE_NAME, V_ORDER,
    --   P_HQ_IMPR_NBR, P_REC_STATUS, P_RULE_TYPE (P_BUS_ID_BRNCH commented out); REP.Run_Product('IMPR2150.REP')
    --   ELSE STR.DISPALERT('لا يوجد سجلات تحقق المطلوب','ERROR'); RAISE FORM_TRIGGER_FAILURE; END IF;
    -- The item checks run again here (the DAs may not have run). BUS_ID_BRNCH = SINGLE_IMPORTERS.BUS_ID_BRNCH of the
    -- importer, as HQ_IMPR_NBR WHEN-VALIDATE-ITEM sets it (the item cannot be changed: Insert / Update Allowed No).
    PROCEDURE PRINT_CHECK_VAL (P_HQ_IMPR_NBR    IN  VARCHAR2,
                               P_REC_STATUS     IN  VARCHAR2,
                               P_RULE_TYPE      IN  VARCHAR2,
                               P_REPORT_NO      IN  VARCHAR2,
                               P_HERO_TITLE     IN  VARCHAR2,
                               P_CURR_PORT_CD   IN  VARCHAR2,
                               P_REPORT_URL     OUT VARCHAR2)
    IS
        v_hq_impr_nbr  NUMBER;
        v_bus_id_brnch VARCHAR2(30);
    BEGIN
        FORMS_APX.CHECK_ERROR(HQ_IMPR_NBR_VALIDATION(P_HQ_IMPR_NBR => P_HQ_IMPR_NBR));
        FORMS_APX.CHECK_ERROR(REC_STATUS_VALIDATION(P_REC_STATUS => P_REC_STATUS));
        FORMS_APX.CHECK_ERROR(RULE_TYPE_VALIDATION(P_RULE_TYPE => P_RULE_TYPE));
        IF TRIM(P_HQ_IMPR_NBR) IS NOT NULL THEN
            v_hq_impr_nbr := TO_NUMBER(TRIM(P_HQ_IMPR_NBR));
            SELECT si.bus_id_brnch
              INTO v_bus_id_brnch
              FROM single_importers si
             WHERE si.hq_impr_nbr = v_hq_impr_nbr;
        END IF;
        IF rules_count(v_hq_impr_nbr, P_REC_STATUS, v_bus_id_brnch) = 0 THEN
            FORMS_APX.CHECK_ERROR(c_msg_no_rows);
        END IF;
        P_REPORT_URL := PRINT_IMPR2150_ARD(p_curr_port_cd => P_CURR_PORT_CD,
                                           p_hq_impr_nbr  => TO_CHAR(v_hq_impr_nbr),
                                           p_rec_status   => P_REC_STATUS,
                                           p_rule_type    => TRIM(P_RULE_TYPE),
                                           p_module_name  => P_HERO_TITLE,
                                           p_report_no    => P_REPORT_NO);
    END PRINT_CHECK_VAL;

    -- =========================================================================
    -- PROGRAM UNITS
    -- =========================================================================

    -- Source: REP.Run_Product(REPORTS, V_REPORT_FILE, SYNCHRONOUS, RUNTIME, FILESYSTEM, pl_id, NULL)
    -- Pattern: PRINT_<FORM>_ARD of the approved standard 13-b / 13-c (as PRINT_IMPR2130_ARD); no server link in the
    -- code: ARD_URL and ARD_DSNAME are settings (SC_PORT_SETTING, SYSOBJ_ID 999, PORT_CD 99 -
    -- migration/001_ard_settings.sql); a missing setting stops with a message.
    FUNCTION PRINT_IMPR2150_ARD (p_curr_port_cd IN VARCHAR2,
                                 p_hq_impr_nbr  IN VARCHAR2,
                                 p_rec_status   IN VARCHAR2,
                                 p_rule_type    IN VARCHAR2,
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
               || ard_parameter(2, p_hq_impr_nbr)
               || ard_parameter(3, p_rec_status)
               || ard_parameter(4, p_rule_type)
               || ard_parameter(5, p_module_name)
               || ard_parameter(6, p_report_no)
               || CHR(38) || 'DsName=' || UTL_URL.ESCAPE(v_dsname, TRUE, 'UTF-8');
    END PRINT_IMPR2150_ARD;

END IMPR2150;
/
SHOW ERRORS
