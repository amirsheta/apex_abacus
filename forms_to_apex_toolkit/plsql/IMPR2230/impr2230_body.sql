-- =============================================================================
-- Package body: IMPR2230   (matches impr2230_spec.sql - f345 standard)
-- Source form : IMPR2230.fmb   Target: APEX 21.2 / DB 12.1.0.2   Version: 001
-- Author      : Claude Code     Created: 2026-11-26   (see the spec history)
-- Rules: no Forms built-ins (FORMS_APX instead), no COMMIT / ROLLBACK, no V('...'),
--        parameters named after their binds without I_ / IO_ / O_; page items P<page>_X -> P_X;
--        inside SQL every parameter is qualified with its member name; identifiers <= 30 bytes.
-- Common helpers: FORMS_APX (version 004), called as FORMS_APX.<NAME>.
-- Layout (docs/f345_reference_standard.md §10): PRIVATE HELPERS -> VERSION -> FORM LEVEL
-- -> BLOCK CALLING_PARAMETERS -> BLOCK TOOLBAR -> PROGRAM UNITS.
-- Status: NOT COMPILED. The report itself: IMPR2230_ARD (IMPR2230_ARD_spec.sql / _body.sql).
-- =============================================================================
SET DEFINE OFF

CREATE OR REPLACE PACKAGE BODY LIB_APX_USR.IMPR2230
AS
    c_all_ports        CONSTANT VARCHAR2(2)  := '99';         -- P_CURR_PORT_CD 99 = head office (all ports)
    c_ard_function     CONSTANT VARCHAR2(60) := 'LIB_APX_USR.IMPR2230_ARD.ARD_IMPR2230';
    -- ARD server settings in SC_PORT_SETTING (user decision 2026-11-25): SYSOBJ_ID 999, PORT_CD 99, VAR_NAME ARD_URL / ARD_DSNAME
    c_settings_object  CONSTANT VARCHAR2(10) := '999';
    c_msg_ard_setting  CONSTANT VARCHAR2(200) := 'إعداد خادم التقارير غير موجود في SC_PORT_SETTING (SYSOBJ_ID 999، PORT_CD 99): ';
    c_list_pattern     CONSTANT VARCHAR2(60) := '^[0-9]+(,[0-9]+)*$';

    -- Forms texts
    c_msg_port         CONSTANT VARCHAR2(100) := 'رمز الجمرك غير صحيح';
    c_msg_no_rows      CONSTANT VARCHAR2(100) := 'لا يوجد سجلات تحقق المطلوب';
    c_msg_list         CONSTANT VARCHAR2(200) := 'أرقام المستوردين يجب أن تكون أرقاماً تفصل بينها فاصلة (,)';

    -- =========================================================================
    -- PRIVATE HELPERS
    -- =========================================================================

    -- LICE_NO without blanks and without a last comma ('1, 2,' -> '1,2'); the form of the list the
    -- report and the count query use.
    FUNCTION normalized_list (p_lice_no IN VARCHAR2)
       RETURN VARCHAR2
    IS
    BEGIN
        RETURN RTRIM(REGEXP_REPLACE(p_lice_no, '\s', ''), ',');
    END normalized_list;

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

    -- Source: the count queries of CHECK_VAL / PRINT_CHECK_VAL (identical in both).
    -- Original Forms code (one of the 6 branches, the others differ only in port and importer filter):
    --   SELECT COUNT(IMP.IMPR_NBR) INTO V_COUNT
    --     FROM IMPORTERS IMP, IMPORTERS L_IMP, AGNTS AG
    --    WHERE AG.PORT_CD = L_IMP.PORT_CD AND AG.IMPR_NBR = L_IMP.IMPR_NBR
    --      AND AG.PORT_CD = IMP.PORT_CD AND AG.IMPR_NBR_AGENT_ID = IMP.IMPR_NBR
    --      AND (IMP.PORT_CD = :P_PORT_CD)            -- :PARAMETER.P_CURR_PORT_CD when :P_PORT_CD is null
    --      AND L_IMP.IMPR_NBR = :P_AGR_NBR;          -- loop over CTR_BLK, EXIT at the first count > 0
    --   Branches: LICE_NO and CTR_BLK records -> loop over CTR_BLK.P_AGR_NBR, stop at the first importer found;
    --   LICE_NO without records -> L_IMP.IMPR_NBR = :LICE_NO; no LICE_NO -> every authorization of the port. CTR_BLK
    --   holds exactly the numbers of LICE_NO, so all branches are "how many authorizations of the port have an
    --   importer (AGNTS.IMPR_NBR, alias L_IMP) in the list (or any)" - only zero / not zero is used. The list filters
    --   L_IMP here; IMPR2220 filters the brokerage company IMP (the only change in the Forms code).
    --   In every branch the port is NVL(:P_PORT_CD, :PARAMETER.P_CURR_PORT_CD), as here. Same joins as the report
    --   query (IMPR2230_ARD), so the check and the PDF see the same rows.
    FUNCTION agents_count (p_lice_no IN VARCHAR2, p_port_cd IN VARCHAR2)
       RETURN NUMBER
    IS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(imp.impr_nbr)
          INTO v_count
          FROM importers imp, importers l_imp, agnts ag
         WHERE ag.port_cd           = l_imp.port_cd
           AND ag.impr_nbr          = l_imp.impr_nbr
           AND ag.port_cd           = imp.port_cd
           AND ag.impr_nbr_agent_id = imp.impr_nbr
           AND imp.port_cd          = p_port_cd
           AND l_imp.impr_nbr IS NOT NULL                       -- TRAN_SELECT without LICE_NO
           AND (   p_lice_no IS NULL
                OR l_imp.impr_nbr IN (SELECT TO_NUMBER(REGEXP_SUBSTR(p_lice_no, '[^,]+', 1, LEVEL))
                                        FROM dual
                                     CONNECT BY REGEXP_SUBSTR(p_lice_no, '[^,]+', 1, LEVEL) IS NOT NULL));
        RETURN v_count;
    END agents_count;

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
    --      GO_ITEM('LICE_NO'); SET_ITEM_PROPERTY('P_LOV_PORT' / 'P_PORT_NAME' / 'P_PORT_CD', VISIBLE, FALSE);
    --   ELSE :P_CURR_PORT_NAME := NULL; END IF;
    --   EXCEPTION WHEN NO_DATA_FOUND THEN NULL;
    --   (:GLOBAL.CHPT_CODE / CHPT_ARB := NULL - LOV globals, not needed; window / title lines -> f345 shell)
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

    -- Source: WHEN-NEW-FORM-INSTANCE (SET_ITEM_PROPERTY VISIBLE FALSE when P_CURR_PORT_CD != 99)
    FUNCTION P_PORT_CD_IS_VISIBLE (P_CURR_PORT_CD IN VARCHAR2)
       RETURN BOOLEAN
    IS
    BEGIN
        RETURN NVL(P_CURR_PORT_CD, c_all_ports) = c_all_ports;
    END P_PORT_CD_IS_VISIBLE;

    -- Source: CALLING_PARAMETERS.P_PORT_CD.WHEN-VALIDATE-ITEM
    -- Original Forms code:
    --   IF :P_PORT_CD IS NOT NULL THEN SELECT PORT_NAME INTO :P_PORT_NAME FROM SD_PORTS WHERE PORT_CD = :P_PORT_CD; END IF;
    --   EXCEPTION WHEN NO_DATA_FOUND THEN MESSAGE('رمز الجمرك غير صحيح'); RAISE FORM_TRIGGER_FAILURE;
    FUNCTION P_PORT_CD_VALIDATION (P_PORT_CD IN VARCHAR2)
       RETURN VARCHAR2
    IS
        v_count NUMBER;
    BEGIN
        IF P_PORT_CD IS NULL THEN
            RETURN NULL;
        END IF;
        SELECT COUNT(*)
          INTO v_count
          FROM sd_ports p
         WHERE p.port_cd = P_PORT_CD_VALIDATION.P_PORT_CD;
        RETURN CASE WHEN v_count = 0 THEN c_msg_port END;
    EXCEPTION
        WHEN INVALID_NUMBER OR VALUE_ERROR THEN
            RETURN c_msg_port;
    END P_PORT_CD_VALIDATION;

    -- Source: CALLING_PARAMETERS.P_PORT_CD.WHEN-VALIDATE-ITEM (see P_PORT_CD_VALIDATION)
    PROCEDURE P_PORT_CD_WHEN_VALIDATE_ITEM (P_PORT_CD   IN  VARCHAR2,
                                            P_PORT_NAME OUT VARCHAR2)
    IS
    BEGIN
        P_PORT_NAME := NULL;
        FORMS_APX.CHECK_ERROR(P_PORT_CD_VALIDATION(P_PORT_CD => P_PORT_CD));
        IF P_PORT_CD IS NOT NULL THEN
            SELECT p.port_name
              INTO P_PORT_CD_WHEN_VALIDATE_ITEM.P_PORT_NAME
              FROM sd_ports p
             WHERE p.port_cd = P_PORT_CD_WHEN_VALIDATE_ITEM.P_PORT_CD;
        END IF;
    END P_PORT_CD_WHEN_VALIDATE_ITEM;

    -- Source: CALLING_PARAMETERS.LICE_NO (list format; see the spec)
    FUNCTION LICE_NO_VALIDATION (P_LICE_NO IN VARCHAR2)
       RETURN VARCHAR2
    IS
        v_list VARCHAR2(4000) := normalized_list(P_LICE_NO);
    BEGIN
        IF v_list IS NOT NULL AND NOT REGEXP_LIKE(v_list, c_list_pattern) THEN
            RETURN c_msg_list;
        END IF;
        RETURN NULL;
    END LICE_NO_VALIDATION;

    -- Source: CALLING_PARAMETERS.SECT_LOV.WHEN-BUTTON-PRESSED, LICE_NO.KEY-LISTVAL
    -- Original Forms code (business part):
    --   CALL_FORM('REP_LOV_IMPR.fmx', no_hide, no_replace, no_query_only, pl_id);   -- no P_CURR_PORT_CD in pl_id
    --   (the LOV form then lists the importers of its default port 30; the APEX LOV uses the report port, see the spec)
    --   IF :GLOBAL.CHPT_CODE IS NOT NULL THEN :LICE_NO := :GLOBAL.CHPT_CODE; :GLOBAL.SECT_ARB := :GLOBAL.CHPT_ARB; END IF;
    --   NEXT_BLOCK; GO_ITEM('P_AGR_NBR');   -> CTR_BLK refresh (DA)
    -- The LOV form (source not here) returns the picked importers as one comma list; the Popup LOV picks
    -- one importer at a time, so each pick is added to the list.
    PROCEDURE SECT_LOV_WHEN_BUTTON_PRESSED (P_SECT_LOV IN OUT VARCHAR2,
                                            P_LICE_NO  IN OUT VARCHAR2)
    IS
        v_list VARCHAR2(4000) := normalized_list(P_LICE_NO);
    BEGIN
        IF P_SECT_LOV IS NOT NULL
           AND INSTR(',' || v_list || ',', ',' || TRIM(P_SECT_LOV) || ',') = 0 THEN
            v_list := v_list || CASE WHEN v_list IS NOT NULL THEN ',' END || TRIM(P_SECT_LOV);
        END IF;
        P_LICE_NO  := v_list;
        P_SECT_LOV := NULL;
    END SECT_LOV_WHEN_BUTTON_PRESSED;

    -- =========================================================================
    -- BLOCK TOOLBAR
    -- =========================================================================

    -- Source: PU PRINT_CHECK_VAL (PRINT, KEY-PRINT, KEY-F4) and PU CHECK_VAL (VIEW, KEY-F5) - same code:
    --   item checks again (the DAs may not have run), :parameter.TRAN_SELECT (importer list), the count
    --   (no rows -> 'لا يوجد سجلات تحقق المطلوب' + FTF), then REP.Run_Product -> the ardpdf link.
    --   Report parameters: L_IMPR_NBR = :parameter.TRAN_SELECT (the lexical ' AND L_IMP.IMPR_NBR in (<LICE_NO>)' /
    --   ' AND L_IMP.IMPR_NBR IS NOT NULL'; IMPR_NBR is not sent), P_CURR_PORT_CD = NVL(:P_PORT_CD, :PARAMETER.P_CURR_PORT_CD),
    --   P_REPORT_NO, P_MODULE_NAME (both program units).
    PROCEDURE PRINT_CHECK_VAL (P_LICE_NO        IN  VARCHAR2,
                               P_PORT_CD        IN  VARCHAR2,
                               P_REPORT_NO      IN  VARCHAR2,
                               P_HERO_TITLE     IN  VARCHAR2,
                               P_MODULE_ID      IN  VARCHAR2,
                               P_CURR_PORT_CD   IN  VARCHAR2,
                               P_REPORT_URL     OUT VARCHAR2)
    IS
        v_list VARCHAR2(4000);
        v_port VARCHAR2(30) := NVL(P_PORT_CD, P_CURR_PORT_CD);
    BEGIN
        FORMS_APX.CHECK_ERROR(P_PORT_CD_VALIDATION(P_PORT_CD => P_PORT_CD));
        FORMS_APX.CHECK_ERROR(LICE_NO_VALIDATION(P_LICE_NO => P_LICE_NO));
        v_list := normalized_list(P_LICE_NO);
        IF agents_count(v_list, v_port) = 0 THEN
            FORMS_APX.CHECK_ERROR(c_msg_no_rows);
        END IF;
        P_REPORT_URL := PRINT_IMPR2230_ARD(p_impr_list    => v_list,
                                           p_curr_port_cd => v_port,
                                           p_module_name  => P_HERO_TITLE,
                                           p_report_no    => P_REPORT_NO);
    END PRINT_CHECK_VAL;

    -- =========================================================================
    -- PROGRAM UNITS
    -- =========================================================================

    -- Source: REP.Run_Product(REPORTS, V_REPORT_FILE, SYNCHRONOUS, RUNTIME, FILESYSTEM, pl_id, NULL)
    -- Pattern: PRINT_<FORM>_ARD of the approved standard 13-b / 13-c (as PRINT_IMPR2110_ARD); no server link in the
    -- code: ARD_URL and ARD_DSNAME are settings (SC_PORT_SETTING, SYSOBJ_ID 999, PORT_CD 99 -
    -- migration/001_ard_settings.sql); a missing setting stops with a message.
    FUNCTION PRINT_IMPR2230_ARD (p_impr_list      IN VARCHAR2,
                                 p_curr_port_cd   IN VARCHAR2,
                                 p_module_name    IN VARCHAR2,
                                 p_report_no      IN VARCHAR2)
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
               || ard_parameter(2, p_impr_list)       -- L_IMPR_NBR (:parameter.TRAN_SELECT): importer list
               || ard_parameter(3, NULL)              -- IMPR_NBR: not sent by the form
               || ard_parameter(4, p_module_name)
               || ard_parameter(5, p_report_no)
               || CHR(38) || 'DsName=' || UTL_URL.ESCAPE(v_dsname, TRUE, 'UTF-8');
    END PRINT_IMPR2230_ARD;

END IMPR2230;
/
SHOW ERRORS
