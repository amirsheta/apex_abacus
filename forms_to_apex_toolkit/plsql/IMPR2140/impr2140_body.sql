-- =============================================================================
-- Package body: IMPR2140   (matches impr2140_spec.sql - f345 standard)
-- Source form : IMPR2140.fmb   Target: APEX 21.2 / DB 12.1.0.2   Version: 001
-- Author      : Claude Code     Created: 2026-11-25   (see the spec history)
-- Rules: no Forms built-ins (FORMS_APX instead), no COMMIT / ROLLBACK, no V('...'),
--        parameters named after their binds without I_ / IO_ / O_; page items P<page>_X -> P_X;
--        inside SQL every parameter is qualified with its member name; identifiers <= 30 bytes.
-- Common helpers: FORMS_APX (version 004), called as FORMS_APX.<NAME>.
-- Layout (docs/f345_reference_standard.md §10): PRIVATE HELPERS -> VERSION -> FORM LEVEL
-- -> BLOCK CALLING_PARAMETERS -> BLOCK TOOLBAR -> PROGRAM UNITS.
-- Status: NOT COMPILED. The letters: IMPR2141_ARD, IMPR2142_ARD, IMPR2143_ARD (plsql/IMPR2140).
-- =============================================================================
SET DEFINE OFF

CREATE OR REPLACE PACKAGE BODY LIB_APX_USR.IMPR2140
AS
    c_all_ports        CONSTANT VARCHAR2(2)  := '99';         -- P_CURR_PORT_CD 99 = head office (all ports)
    -- ARD server settings in SC_PORT_SETTING (user decision 2026-11-25): SYSOBJ_ID 999, PORT_CD 99, VAR_NAME ARD_URL / ARD_DSNAME
    c_settings_object  CONSTANT VARCHAR2(10) := '999';
    c_msg_ard_setting  CONSTANT VARCHAR2(200) := 'إعداد خادم التقارير غير موجود في SC_PORT_SETTING (SYSOBJ_ID 999، PORT_CD 99): ';
    c_number_pattern   CONSTANT VARCHAR2(20) := '^[0-9]+$';

    -- LETTER_DIRCTION values (List Item elements of the XML)
    c_letter_audit_bureau  CONSTANT VARCHAR2(1) := '1';   -- خطابات ديوان المراقبة     -> IMPR2141
    c_letter_audit_dept    CONSTANT VARCHAR2(1) := '2';   -- خطابات إدارة التدقيق      -> IMPR2142
    c_letter_port_audit    CONSTANT VARCHAR2(1) := '3';   -- خطابات قسم التدقيق بالجمرك -> IMPR2143

    -- Forms texts
    -- SUGGESTION: the Forms port message is the literal 'NO_DATA_FOUND'; IMPR2110 / IMPR2130 say 'رمز الجمرك غير صحيح'.
    c_msg_port         CONSTANT VARCHAR2(100) := 'NO_DATA_FOUND';
    c_msg_importer     CONSTANT VARCHAR2(100) := 'رمزالمستورد غير موجود';
    c_msg_impr_empty   CONSTANT VARCHAR2(100) := 'لا يمكن ترك حقل المستورد خاليا';
    c_msg_no_rows      CONSTANT VARCHAR2(100) := 'لا يوجد سجلات تحقق المطلوب';
    c_msg_letter       CONSTANT VARCHAR2(100) := 'يجب اختيار توجيه الخطاب';

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

    -- Source: the count queries of PU PRINT_CHECK_VAL, one per LETTER_DIRCTION (kept as in Forms, user decision
    -- 2026-11-25). Original Forms code:
    --   IF :LETTER_DIRCTION = 1 THEN
    --      SELECT COUNT(1) INTO V_COUNT FROM DUAL WHERE EXISTS (SELECT IMP.PORT_CD FROM IMPORTERS IMP, SD_PORTS SDP
    --       WHERE SDP.PORT_CD = IMP.PORT_CD AND (IMP.IMPR_NBR = :IMPR_NO OR :IMPR_NO IS NULL));
    --   ELSIF :LETTER_DIRCTION = 2 THEN
    --      ... FROM CITIES SDC, IMPORTERS IMP, SD_PORTS SDP, SMPL_LABS SLC, SMPL_REQUESTS SR, SMPL_ITEMS SI
    --       WHERE ((SI.RESULT_CD IN (3,4)) AND SI.ACTION_CD <> 1) AND SI.RQST_PORT_CD = SR.RQST_PORT_CD
    --         AND SI.RQST_NMR = SR.RQST_NMR AND SI.RQST_DT = SR.RQST_DT AND SR.LAB_CD = SLC.LAB_CD (+)
    --         AND SR.RQST_PORT_CD = SDP.PORT_CD AND SR.RQST_PORT_CD = IMP.PORT_CD AND SR.IMPR_NBR = IMP.IMPR_NBR
    --         AND IMP.ADD_CTRY_CD = SDC.CTRY_CD AND IMP.CITY_CODE = SDC.CITY_CD
    --         AND SDP.PORT_CD = P_CURR_PORT_CD AND (IMP.IMPR_NBR = :IMPR_NO OR :IMPR_NO IS NULL));
    --   ELSE
    --      ... FROM IMPORTERS IMP, SD_PORTS SDP, SC_USERS sc WHERE (IMP.IMPR_NBR = :IMPR_NO OR :IMPR_NO IS NULL)
    --       AND imp.port_cd = sdp.port_cd AND sc.port_cd = sdp.port_cd AND sc.CLASS_CD = 12
    --       AND (SDP.PORT_CD = P_CURR_PORT_CD));
    --   END IF;
    -- (IMPR_NO is never NULL here: PRINT_CHECK_VAL stops before.)
    -- SUGGESTION: the letter reports select only IMPORTERS + SD_PORTS of the port (IMPR214<n>_ARD): letter 1 counts
    --   the importer in any port (the PDF can be empty when he is not in the report's port); letters 2 / 3 add the
    --   failed-samples / class-12-user rules the reports do not have. PU CHECK_VAL (VIEW) had for letter 2 a cross
    --   join of IMPORTERS and SD_PORTS (no sample rule). To confirm with the business owner.
    FUNCTION letter_count (p_letter_dirction IN VARCHAR2,
                           p_impr_no         IN VARCHAR2,
                           p_port_cd         IN VARCHAR2)
       RETURN NUMBER
    IS
        v_count NUMBER;
    BEGIN
        IF p_letter_dirction = c_letter_audit_bureau THEN
            SELECT COUNT(1)
              INTO v_count
              FROM dual
             WHERE EXISTS (SELECT imp.port_cd
                             FROM importers imp, sd_ports sdp
                            WHERE sdp.port_cd  = imp.port_cd
                              AND imp.impr_nbr = p_impr_no);
        ELSIF p_letter_dirction = c_letter_audit_dept THEN
            SELECT COUNT(1)
              INTO v_count
              FROM dual
             WHERE EXISTS (SELECT imp.port_cd
                             FROM cities sdc, importers imp, sd_ports sdp, smpl_labs slc, smpl_requests sr, smpl_items si
                            WHERE si.result_cd IN (3, 4)
                              AND si.action_cd    <> 1
                              AND si.rqst_port_cd = sr.rqst_port_cd
                              AND si.rqst_nmr     = sr.rqst_nmr
                              AND si.rqst_dt      = sr.rqst_dt
                              AND sr.lab_cd       = slc.lab_cd (+)
                              AND sr.rqst_port_cd = sdp.port_cd
                              AND sr.rqst_port_cd = imp.port_cd
                              AND sr.impr_nbr     = imp.impr_nbr
                              AND imp.add_ctry_cd = sdc.ctry_cd
                              AND imp.city_code   = sdc.city_cd
                              AND sdp.port_cd     = p_port_cd
                              AND imp.impr_nbr    = p_impr_no);
        ELSE
            SELECT COUNT(1)
              INTO v_count
              FROM dual
             WHERE EXISTS (SELECT imp.port_cd
                             FROM importers imp, sd_ports sdp, sc_users sc
                            WHERE imp.impr_nbr = p_impr_no
                              AND imp.port_cd  = sdp.port_cd
                              AND sc.port_cd   = sdp.port_cd
                              AND sc.class_cd  = 12
                              AND sdp.port_cd  = p_port_cd);
        END IF;
        RETURN v_count;
    END letter_count;

    -- ardpdf parameter: &P_PARAMETER<n>=<value>, URL-escaped (UTF-8), as PRINT_IMPR2110_ARD
    FUNCTION ard_parameter (p_n IN PLS_INTEGER, p_value IN VARCHAR2)
       RETURN VARCHAR2
    IS
    BEGIN
        RETURN CHR(38) || 'P_PARAMETER' || p_n || '=' || UTL_URL.ESCAPE(p_value, TRUE, 'UTF-8');
    END ard_parameter;

    -- Source: REP.Run_Product (see the spec): the ardpdf link of one letter function (LIB_APX_USR.IMPR214<n>_ARD.ARD_IMPR214<n>)
    FUNCTION ard_link (p_function     IN VARCHAR2,
                       p_curr_port_cd IN VARCHAR2,
                       p_impr_no      IN VARCHAR2)
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
               || 'func_name=' || p_function
               || ard_parameter(1, p_curr_port_cd)
               || ard_parameter(2, p_impr_no)
               || CHR(38) || 'DsName=' || UTL_URL.ESCAPE(v_dsname, TRUE, 'UTF-8');
    END ard_link;

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
    --   IF :PARAMETER.P_CURR_PORT_CD <> 99 THEN :P_PORT_CD := :PARAMETER.P_CURR_PORT_CD;
    --      SELECT PORT_NAME INTO :P_PORT_NAME FROM SD_PORTS WHERE PORT_CD = :P_PORT_CD; END IF;
    --   IF :PARAMETER.P_CURR_PORT_CD != 99 THEN
    --      SELECT PORT_NAME INTO :P_CURR_PORT_NAME FROM SD_PORTS WHERE PORT_CD = :PARAMETER.P_CURR_PORT_CD;
    --      GO_ITEM('LETTER_DIRCTION'); SET_ITEM_PROPERTY('P_LOV_PORT' / 'P_PORT_NAME' / 'P_PORT_CD', VISIBLE, FALSE);
    --   ELSE :P_CURR_PORT_NAME := NULL; END IF;
    --   EXCEPTION WHEN NO_DATA_FOUND THEN NULL;
    --   (:GLOBAL.CHPT_CODE / CHPT_ARB / SEC_CODE / IMPR_NBR / ARBC_IMPR_NAME := NULL - LOV globals, not needed;
    --    window / title lines -> f345 shell)
    -- :P_PORT_CD := P_CURR_PORT_CD for a port user is not copied: the item is hidden for him and every member uses
    -- NVL(P_PORT_CD, P_CURR_PORT_CD), which gives the same port.
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
    --   SELECT PORT_NAME INTO :P_PORT_NAME FROM SD_PORTS WHERE PORT_CD = :P_PORT_CD;
    --   EXCEPTION WHEN OTHERS THEN MESSAGE('NO_DATA_FOUND'); MESSAGE('NO_DATA_FOUND'); RAISE FORM_TRIGGER_FAILURE;
    -- An empty port is accepted (Forms raised when a typed port was cleared; the report then runs for P_CURR_PORT_CD).
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

    -- Source: CALLING_PARAMETERS.LETTER_DIRCTION (List Item, Required; see the spec)
    FUNCTION LETTER_DIRCTION_VALIDATION (P_LETTER_DIRCTION IN VARCHAR2)
       RETURN VARCHAR2
    IS
    BEGIN
        IF P_LETTER_DIRCTION IS NULL
           OR P_LETTER_DIRCTION NOT IN (c_letter_audit_bureau, c_letter_audit_dept, c_letter_port_audit) THEN
            RETURN c_msg_letter;
        END IF;
        RETURN NULL;
    END LETTER_DIRCTION_VALIDATION;

    -- Source: CALLING_PARAMETERS.IMPR_NO.WHEN-VALIDATE-ITEM
    -- Original Forms code:
    --   SELECT DISTINCT(ARBC_IMPR_NAME) INTO :IMPR_NAME FROM IMPORTERS WHERE IMPR_NBR = :CALLING_PARAMETERS.IMPR_NO;
    --   EXCEPTION WHEN NO_DATA_FOUND THEN MESSAGE('رمزالمستورد غير موجود'); RAISE FORM_TRIGGER_FAILURE;
    --   (port filter and the broker check P_BRKR_NBR / BRKIMPS are commented out in Forms)
    -- IMPR_NO is a CHAR item: a value that is not a number got ORA-01722 in Forms; here it gets the same message
    -- as an unknown importer.
    FUNCTION IMPR_NO_VALIDATION (P_IMPR_NO IN VARCHAR2)
       RETURN VARCHAR2
    IS
        v_count NUMBER;
    BEGIN
        IF P_IMPR_NO IS NULL THEN
            RETURN NULL;
        END IF;
        IF NOT REGEXP_LIKE(TRIM(P_IMPR_NO), c_number_pattern) THEN
            RETURN c_msg_importer;
        END IF;
        SELECT COUNT(*)
          INTO v_count
          FROM importers i
         WHERE i.impr_nbr = TO_NUMBER(TRIM(IMPR_NO_VALIDATION.P_IMPR_NO));
        RETURN CASE WHEN v_count = 0 THEN c_msg_importer END;
    END IMPR_NO_VALIDATION;

    -- Source: CALLING_PARAMETERS.IMPR_NO.WHEN-VALIDATE-ITEM (see IMPR_NO_VALIDATION)
    -- SUGGESTION: Forms raised TOO_MANY_ROWS (unhandled) when the importer number has different names in different
    --   ports; here the first name (MIN) is shown.
    PROCEDURE IMPR_NO_WHEN_VALIDATE_ITEM (P_IMPR_NO   IN  VARCHAR2,
                                          P_IMPR_NAME OUT VARCHAR2)
    IS
    BEGIN
        P_IMPR_NAME := NULL;
        FORMS_APX.CHECK_ERROR(IMPR_NO_VALIDATION(P_IMPR_NO => P_IMPR_NO));
        IF P_IMPR_NO IS NOT NULL THEN
            SELECT MIN(i.arbc_impr_name)
              INTO IMPR_NO_WHEN_VALIDATE_ITEM.P_IMPR_NAME
              FROM importers i
             WHERE i.impr_nbr = TO_NUMBER(TRIM(IMPR_NO_WHEN_VALIDATE_ITEM.P_IMPR_NO));
        END IF;
    END IMPR_NO_WHEN_VALIDATE_ITEM;

    -- =========================================================================
    -- BLOCK TOOLBAR
    -- =========================================================================

    -- Source: PU PRINT_CHECK_VAL (PRINT, KEY-PRINT, KEY-F4) and PU CHECK_VAL (VIEW, KEY-F5)
    -- Original Forms code (business part):
    --   IF :P_PORT_CD IS NULL THEN P_CURR_PORT_CD := :PARAMETER.P_CURR_PORT_CD; ELSE P_CURR_PORT_CD := :P_PORT_CD; END IF;
    --   IF :IMPR_NO IS NULL THEN MESSAGE('لا يمكن ترك حقل المستورد خاليا'); RAISE FORM_TRIGGER_FAILURE; END IF;
    --   <count of the letter>; :PARAMETER.P_REPORT_FILE := 'IMPR2141.REP' / 'IMPR2142.REP' / 'IMPR2143.REP';
    --   IF V_COUNT > 0 THEN ... REP.Run_Product(...) ELSE MESSAGE('لا يوجد سجلات تحقق المطلوب'); RAISE FORM_TRIGGER_FAILURE;
    --   Report parameters: IMPR_NO, 'P_CURR_PORT_CD ' (name with a trailing blank in Forms), P_REPORT_NO, P_MODULE_NAME.
    --   (C_DATE := HIJDATE.CUR_HIJ_DATE is assigned but never used; WIN_API_DIALOG.SELECT_PRINTER -> browser print.)
    -- The item checks run again here (the DAs may not have run).
    PROCEDURE PRINT_CHECK_VAL (P_IMPR_NO         IN  VARCHAR2,
                               P_PORT_CD         IN  VARCHAR2,
                               P_LETTER_DIRCTION IN  VARCHAR2,
                               P_CURR_PORT_CD    IN  VARCHAR2,
                               P_REPORT_URL      OUT VARCHAR2)
    IS
        v_port    VARCHAR2(30) := NVL(P_PORT_CD, P_CURR_PORT_CD);
        v_impr_no VARCHAR2(100) := TRIM(P_IMPR_NO);
    BEGIN
        FORMS_APX.CHECK_ERROR(P_PORT_CD_VALIDATION(P_PORT_CD => P_PORT_CD));
        IF v_impr_no IS NULL THEN
            FORMS_APX.CHECK_ERROR(c_msg_impr_empty);
        END IF;
        FORMS_APX.CHECK_ERROR(IMPR_NO_VALIDATION(P_IMPR_NO => v_impr_no));
        FORMS_APX.CHECK_ERROR(LETTER_DIRCTION_VALIDATION(P_LETTER_DIRCTION => P_LETTER_DIRCTION));
        IF letter_count(P_LETTER_DIRCTION, v_impr_no, v_port) = 0 THEN
            FORMS_APX.CHECK_ERROR(c_msg_no_rows);
        END IF;
        P_REPORT_URL := CASE P_LETTER_DIRCTION
                            WHEN c_letter_audit_bureau THEN PRINT_IMPR2141_ARD(p_curr_port_cd => v_port, p_impr_no => v_impr_no)
                            WHEN c_letter_audit_dept   THEN PRINT_IMPR2142_ARD(p_curr_port_cd => v_port, p_impr_no => v_impr_no)
                            ELSE                            PRINT_IMPR2143_ARD(p_curr_port_cd => v_port, p_impr_no => v_impr_no)
                        END;
    END PRINT_CHECK_VAL;

    -- =========================================================================
    -- PROGRAM UNITS
    -- =========================================================================

    -- Source: REP.Run_Product of IMPR2141.REP (LETTER_DIRCTION 1)
    FUNCTION PRINT_IMPR2141_ARD (p_curr_port_cd IN VARCHAR2,
                                 p_impr_no      IN VARCHAR2)
       RETURN VARCHAR2
    IS
    BEGIN
        RETURN ard_link('LIB_APX_USR.IMPR2141_ARD.ARD_IMPR2141', p_curr_port_cd, p_impr_no);
    END PRINT_IMPR2141_ARD;

    -- Source: REP.Run_Product of IMPR2142.REP (LETTER_DIRCTION 2)
    FUNCTION PRINT_IMPR2142_ARD (p_curr_port_cd IN VARCHAR2,
                                 p_impr_no      IN VARCHAR2)
       RETURN VARCHAR2
    IS
    BEGIN
        RETURN ard_link('LIB_APX_USR.IMPR2142_ARD.ARD_IMPR2142', p_curr_port_cd, p_impr_no);
    END PRINT_IMPR2142_ARD;

    -- Source: REP.Run_Product of IMPR2143.REP (LETTER_DIRCTION else)
    FUNCTION PRINT_IMPR2143_ARD (p_curr_port_cd IN VARCHAR2,
                                 p_impr_no      IN VARCHAR2)
       RETURN VARCHAR2
    IS
    BEGIN
        RETURN ard_link('LIB_APX_USR.IMPR2143_ARD.ARD_IMPR2143', p_curr_port_cd, p_impr_no);
    END PRINT_IMPR2143_ARD;

END IMPR2140;
/
SHOW ERRORS
