-- =============================================================================
-- Package body: IMPR2110   (matches impr2110_spec.sql - f345 standard)
-- Source form : IMPR2110.fmb   Target: APEX 21.2 / DB 12.1.0.2   Version: 001
-- Author      : Claude Code     Created: 2026-11-25   (see the spec history)
-- Rules: no Forms built-ins (FORMS_APX instead), no COMMIT / ROLLBACK, no V('...'),
--        parameters named after their binds without I_ / IO_ / O_; page items P<page>_X -> P_X;
--        inside SQL every parameter is qualified with its member name; identifiers <= 30 bytes.
-- Common helpers: FORMS_APX (version 004), called as FORMS_APX.<NAME>.
-- Layout (docs/f345_reference_standard.md §10): PRIVATE HELPERS -> VERSION -> FORM LEVEL
-- -> BLOCK CALLING_PARAMETERS -> BLOCK TOOLBAR -> PROGRAM UNITS.
-- Status: NOT COMPILED. External DB package without source here: SC_PORT_SETTINGS_PKG.
-- =============================================================================
SET DEFINE OFF

CREATE OR REPLACE PACKAGE BODY LIB_APX_USR.IMPR2110
AS
    c_all_ports        CONSTANT VARCHAR2(2)  := '99';         -- P_CURR_PORT_CD 99 = head office (all ports)
    c_report_file      CONSTANT VARCHAR2(30) := 'IMPR2110';   -- :PARAMETER.P_REPORT_FILE default
    c_report_server    CONSTANT NUMBER       := 23;           -- 2nd argument of GET_SC_PORT_REPORT_URL (standard 13-b)
    c_list_pattern     CONSTANT VARCHAR2(60) := '^[0-9]+(,[0-9]+)*$';

    -- Forms texts
    c_msg_port         CONSTANT VARCHAR2(100) := 'رمز الجمرك غير صحيح';
    c_msg_no_rows      CONSTANT VARCHAR2(100) := 'لا يوجد سجلات تحقق المطلوب';
    c_msg_list         CONSTANT VARCHAR2(200) := 'أرقام المستوردين يجب أن تكون أرقاماً تفصل بينها فاصلة (,)';

    -- =========================================================================
    -- PRIVATE HELPERS
    -- =========================================================================

    -- LICE_NO without blanks and without a last comma ('1, 2,' -> '1,2'); the form of the list the
    -- report lexical and the count query use.
    FUNCTION normalized_list (p_lice_no IN VARCHAR2)
       RETURN VARCHAR2
    IS
    BEGIN
        RETURN RTRIM(REGEXP_REPLACE(p_lice_no, '\s', ''), ',');
    END normalized_list;

    -- A menu parameter of the module (:PARAMETER.<p_name> in Forms): SC_PORT_SETTING of the user's
    -- port and the module (SYSOBJ_ID), else p_default (the Forms ParameterInitializeValue).
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
    --   Forms branches: LICE_NO and CTR_BLK records -> loop over CTR_BLK.P_AGR_NBR, stop at the first
    --   importer found; LICE_NO without records -> IMPR_NBR = :LICE_NO; no LICE_NO -> every importer of
    --   the port. Port = :P_PORT_CD, else :PARAMETER.P_CURR_PORT_CD. CTR_BLK holds exactly the numbers of
    --   LICE_NO, so all branches are "how many importers of the port are in the list (or any)".
    FUNCTION importers_count (p_lice_no IN VARCHAR2, p_port_cd IN VARCHAR2)
       RETURN NUMBER
    IS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(imp.impr_nbr)
          INTO v_count
          FROM hq_imprs hi, importers imp
         WHERE imp.hq_impr_nbr = hi.hq_impr_nbr (+)
           AND imp.port_cd = p_port_cd
           AND (   p_lice_no IS NULL
                OR imp.impr_nbr IN (SELECT TO_NUMBER(REGEXP_SUBSTR(p_lice_no, '[^,]+', 1, LEVEL))
                                      FROM dual
                                   CONNECT BY REGEXP_SUBSTR(p_lice_no, '[^,]+', 1, LEVEL) IS NOT NULL));
        RETURN v_count;
    END importers_count;

    -- CHECK_VAL and PRINT_CHECK_VAL: the item checks again (the DAs may not have run), the count check
    -- and the report URL (standard 13-b). p_destype SCREEN = VIEW, PRINTER = PRINT.
    PROCEDURE run_report (p_destype      IN  VARCHAR2,
                          p_lice_no      IN  VARCHAR2,
                          p_port_cd      IN  VARCHAR2,
                          p_report_no    IN  VARCHAR2,
                          p_module_name  IN  VARCHAR2,
                          p_module_id    IN  VARCHAR2,
                          p_curr_port_cd IN  VARCHAR2,
                          p_report_url   OUT VARCHAR2)
    IS
        v_list   VARCHAR2(4000);
        v_port   VARCHAR2(30) := NVL(p_port_cd, p_curr_port_cd);
        v_select VARCHAR2(4000);
    BEGIN
        FORMS_APX.CHECK_ERROR(P_PORT_CD_VALIDATION(P_PORT_CD => p_port_cd));
        FORMS_APX.CHECK_ERROR(LICE_NO_VALIDATION(P_LICE_NO => p_lice_no));
        v_list := normalized_list(p_lice_no);
        -- Forms: :parameter.TRAN_SELECT (report lexical CG$P_impr_nbr)
        IF v_list IS NULL THEN
            v_select := ' AND IMP.IMPR_NBR IS NOT NULL';
        ELSE
            v_select := ' AND  IMP.IMPR_NBR in ( ' || v_list || ')';
        END IF;
        IF importers_count(v_list, v_port) = 0 THEN
            FORMS_APX.CHECK_ERROR(c_msg_no_rows);
        END IF;
        p_report_url := PRINT_IMPR2110(p_destype      => p_destype,
                                       p_desname      => NULL,      -- Forms P_NAME: printer dialog commented out
                                       p_report_no    => p_report_no,
                                       p_module_name  => p_module_name,
                                       p_impr_nbr     => v_select,
                                       p_curr_port_cd => v_port,
                                       p_v_order      => NULL,      -- :parameter.V_ORDER, never set (PU P_ORDER is empty)
                                       p_module_id    => p_module_id,
                                       p_user_port_cd => p_curr_port_cd);
    END run_report;

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
    --   CALL_FORM('REP_LOV_IMPR.fmx', ..., P_CURR_PORT_CD = NVL(:P_PORT_CD, :PARAMETER.P_CURR_PORT_CD));
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

    -- Source: PU CHECK_VAL (VIEW, KEY-F5)
    -- Original Forms code: see the spec; parameter list DESTYPE=SCREEN, PARAMFORM=NO, PRINTJOB=YES,
    --   CG$P_impr_nbr, P_CURR_PORT_CD, P_MODULE_NAME, P_REPORT_NO, V_ORDER, MAXIMIZE, ORACLE_SHUTDOWN.
    PROCEDURE CHECK_VAL (P_LICE_NO        IN  VARCHAR2,
                         P_PORT_CD        IN  VARCHAR2,
                         P_REPORT_NO      IN  VARCHAR2,
                         P_HERO_TITLE     IN  VARCHAR2,
                         P_MODULE_ID      IN  VARCHAR2,
                         P_CURR_PORT_CD   IN  VARCHAR2,
                         P_REPORT_URL     OUT VARCHAR2)
    IS
    BEGIN
        run_report('SCREEN', P_LICE_NO, P_PORT_CD, P_REPORT_NO, P_HERO_TITLE, P_MODULE_ID, P_CURR_PORT_CD, P_REPORT_URL);
    END CHECK_VAL;

    -- Source: PU PRINT_CHECK_VAL (PRINT, KEY-PRINT, KEY-F4)
    -- Original Forms code: as CHECK_VAL; parameter list PRINTJOB=YES, DESTYPE=PRINTER, DESNAME=P_NAME (NULL:
    --   WIN_API_DIALOG.SELECT_PRINTER is commented out), PARAMFORM=NO, P_REPORT_NO, P_MODULE_NAME,
    --   CG$P_impr_nbr, P_CURR_PORT_CD, MAXIMIZE, ORACLE_SHUTDOWN (no V_ORDER).
    PROCEDURE PRINT_CHECK_VAL (P_LICE_NO        IN  VARCHAR2,
                               P_PORT_CD        IN  VARCHAR2,
                               P_REPORT_NO      IN  VARCHAR2,
                               P_HERO_TITLE     IN  VARCHAR2,
                               P_MODULE_ID      IN  VARCHAR2,
                               P_CURR_PORT_CD   IN  VARCHAR2,
                               P_REPORT_URL     OUT VARCHAR2)
    IS
    BEGIN
        run_report('PRINTER', P_LICE_NO, P_PORT_CD, P_REPORT_NO, P_HERO_TITLE, P_MODULE_ID, P_CURR_PORT_CD, P_REPORT_URL);
    END PRINT_CHECK_VAL;

    -- =========================================================================
    -- PROGRAM UNITS
    -- =========================================================================

    -- Source: REP.Run_Product(REPORTS, V_REPORT_FILE, SYNCHRONOUS, RUNTIME, FILESYSTEM, pl_id, NULL)
    -- Pattern: approved standard 13-b (PRINT_<FORM>), values sent as in the other report screens.
    FUNCTION PRINT_IMPR2110 (p_destype        IN VARCHAR2,
                             p_desname        IN VARCHAR2,
                             p_report_no      IN VARCHAR2,
                             p_module_name    IN VARCHAR2,
                             p_impr_nbr       IN VARCHAR2,
                             p_curr_port_cd   IN VARCHAR2,
                             p_v_order        IN VARCHAR2,
                             p_module_id      IN VARCHAR2,
                             p_user_port_cd   IN VARCHAR2)
       RETURN VARCHAR2
    IS
        v_other_parameter VARCHAR2(32000);
        report_name       VARCHAR2(200);
        show_parameters   VARCHAR2(50);
        send_parameter1   VARCHAR2(4000);
        send_parameter2   VARCHAR2(4000);
        send_parameter3   VARCHAR2(4000);
        send_parameter4   VARCHAR2(4000);
        send_parameter5   VARCHAR2(4000);
        send_parameter6   VARCHAR2(4000);
        send_parameter7   VARCHAR2(4000);
    BEGIN
        -- :PARAMETER.P_REPORT_FILE (file name without path; P_REPORT_PATH is the Reports Server's business)
        report_name     := REGEXP_REPLACE(REGEXP_SUBSTR(parameter_value('P_REPORT_FILE', p_module_id, p_user_port_cd,
                                                                        c_report_file), '[^\\/]+$'), '\.[^.]*$')
                           || '.rdf';
        show_parameters := CHR(38) || 'paramform=no';
        send_parameter1 := CASE WHEN p_destype IS NOT NULL THEN CHR(38) || 'DESTYPE=' || p_destype END;
        send_parameter2 := CASE WHEN p_desname IS NOT NULL THEN CHR(38) || 'DESNAME=' || p_desname END;
        send_parameter3 := CASE WHEN p_report_no IS NOT NULL THEN CHR(38) || 'P_REPORT_NO=' || p_report_no END;
        send_parameter4 := CASE WHEN p_module_name IS NOT NULL THEN CHR(38) || 'P_MODULE_NAME=' || p_module_name END;
        send_parameter5 := CASE WHEN p_impr_nbr IS NOT NULL THEN CHR(38) || 'CG$P_impr_nbr=' || p_impr_nbr END;
        send_parameter6 := CASE WHEN p_curr_port_cd IS NOT NULL THEN CHR(38) || 'P_CURR_PORT_CD=' || p_curr_port_cd END;
        send_parameter7 := CASE WHEN p_v_order IS NOT NULL THEN CHR(38) || 'V_ORDER=' || p_v_order END;
        v_other_parameter := report_name
                             || show_parameters
                             || send_parameter1
                             || send_parameter2
                             || send_parameter3
                             || send_parameter4
                             || send_parameter5
                             || send_parameter6
                             || send_parameter7;
        RETURN SC_PORT_SETTINGS_PKG.GET_SC_PORT_REPORT_URL(p_user_port_cd, c_report_server, v_other_parameter);
    END PRINT_IMPR2110;

END IMPR2110;
/
SHOW ERRORS
