-- =============================================================================
-- Package body: IMPR3100   (matches impr3100_spec.sql - f345 standard)
-- Source form : IMPR3100.fmb   Target: APEX 21.2 / DB 12.1.0.2   Version: 001
-- Author      : Claude Code     Created: 2026-11-26   (see the spec history)
-- Rules: no Forms built-ins (FORMS_APX instead), no COMMIT / ROLLBACK, no V('...'),
--        parameters named after their binds without I_ / IO_ / O_; page items P<page>_X -> P_X;
--        inside SQL every parameter is qualified with its member name; identifiers <= 30 bytes.
-- Common helpers: FORMS_APX (version 004), called as FORMS_APX.<NAME>.
-- Layout (docs/f345_reference_standard.md §10): PRIVATE HELPERS (+ the CHECK_VAL count) -> VERSION -> FORM LEVEL
-- -> BLOCK CALLING_PARAMETERS -> BLOCK TOOLBAR -> PROGRAM UNITS.
-- Status: NOT COMPILED. The report: IMPR3100_ARD (plsql/IMPR3100).
-- =============================================================================
SET DEFINE OFF

CREATE OR REPLACE PACKAGE BODY LIB_APX_USR.IMPR3100
AS
    c_all_ports        CONSTANT VARCHAR2(2)  := '99';         -- P_CURR_PORT_CD 99 = head office (all ports)
    -- ARD server settings in SC_PORT_SETTING (user decision 2026-11-25): SYSOBJ_ID 999, PORT_CD 99, VAR_NAME ARD_URL / ARD_DSNAME
    c_settings_object  CONSTANT VARCHAR2(10) := '999';
    c_msg_ard_setting  CONSTANT VARCHAR2(200) := 'إعداد خادم التقارير غير موجود في SC_PORT_SETTING (SYSOBJ_ID 999، PORT_CD 99): ';
    c_ard_function     CONSTANT VARCHAR2(60) := 'LIB_APX_USR.IMPR3100_ARD.ARD_IMPR3100';
    c_ard_date_format  CONSTANT VARCHAR2(20) := 'YYYY-MM-MI';  -- date text of Forms CHECK_VAL, read by IMPR3100_ARD
    c_number_pattern   CONSTANT VARCHAR2(20) := '^[0-9]+$';

    -- REPORT values (Radio Group elements of the XML)
    c_report_modified  CONSTANT VARCHAR2(1) := '0';   -- تعديلات بيانات المستوردين
    c_report_added     CONSTANT VARCHAR2(1) := '1';   -- إضافة مستوردين جدد

    -- Forms texts
    c_msg_port         CONSTANT VARCHAR2(100) := 'رمز الجمرك غير صحيح';
    c_msg_supp_title   CONSTANT VARCHAR2(100) := 'رمز جهة الخطاب غير موجود';     -- SUPPORT_ENTRY text (Forms: no text)
    c_msg_letter_dates CONSTANT VARCHAR2(100) := 'يجب إدخال تاريخ الخطاب أو الفترة وليس كليهما';
    c_msg_period       CONSTANT VARCHAR2(100) := 'تاريخ النهاية يجب أن يكون أكبر من تاريخ البداية';
    c_msg_no_rows      CONSTANT VARCHAR2(100) := 'لا يوجد سجلات تحقق المطلوب';
    c_label_report     CONSTANT VARCHAR2(50)  := 'نوع التقرير';

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

    -- the port sent to the report: the user's port outside head office (WHEN-NEW-FORM-INSTANCE :P_PORT_CD :=
    -- P_CURR_PORT_CD), else the port item, else P_CURR_PORT_CD (as IMPR2310)
    FUNCTION report_port (p_port_cd IN VARCHAR2, p_curr_port_cd IN VARCHAR2)
       RETURN VARCHAR2
    IS
    BEGIN
        RETURN CASE WHEN NVL(p_curr_port_cd, c_all_ports) <> c_all_ports THEN p_curr_port_cd
                    ELSE NVL(TRIM(p_port_cd), NVL(p_curr_port_cd, c_all_ports)) END;
    END report_port;

    -- a port code that exists in SD_PORTS (empty is allowed: NULL = OK)
    FUNCTION port_error (p_port_cd IN VARCHAR2)
       RETURN VARCHAR2
    IS
        v_port_cd NUMBER := number_or_null(p_port_cd);
        v_count   NUMBER;
    BEGIN
        IF TRIM(p_port_cd) IS NULL THEN
            RETURN NULL;
        END IF;
        IF v_port_cd IS NULL THEN
            RETURN c_msg_port;
        END IF;
        SELECT COUNT(*)
          INTO v_count
          FROM sd_ports p
         WHERE p.port_cd = v_port_cd;
        RETURN CASE WHEN v_count = 0 THEN c_msg_port END;
    END port_error;

    -- the name of a port (NULL when empty or unknown)
    FUNCTION port_name (p_port_cd IN VARCHAR2)
       RETURN VARCHAR2
    IS
        v_port_cd NUMBER := number_or_null(p_port_cd);
        v_name    sd_ports.port_name%TYPE;
    BEGIN
        SELECT MAX(p.port_name)
          INTO v_name
          FROM sd_ports p
         WHERE p.port_cd = v_port_cd;
        RETURN v_name;
    END port_name;

    -- a Hijri date text of the page as a DATE (NULL stays NULL)
    FUNCTION page_date (p_text IN VARCHAR2)
       RETURN DATE
    IS
    BEGIN
        RETURN CASE WHEN p_text IS NOT NULL THEN FORMS_APX.HIJRI_TEXT_TO_DATE(p_text) END;
    END page_date;

    -- a Hijri date as the text IMPR3100_ARD reads (NULL stays NULL)
    FUNCTION ard_date (p_date IN DATE)
       RETURN VARCHAR2
    IS
    BEGIN
        RETURN TO_CHAR(p_date, c_ard_date_format);
    END ard_date;

    -- ardpdf parameter: &P_PARAMETER<n>=<value>, URL-escaped (UTF-8), as PRINT_IMPR2110_ARD
    FUNCTION ard_parameter (p_n IN PLS_INTEGER, p_value IN VARCHAR2)
       RETURN VARCHAR2
    IS
    BEGIN
        RETURN CHR(38) || 'P_PARAMETER' || p_n || '=' || UTL_URL.ESCAPE(p_value, TRUE, 'UTF-8');
    END ard_parameter;

    -- Source: PU CHECK_VAL, the count before REP.Run_Product (kept as in Forms, as the IMPR2140 user decision of
    -- 2026-11-25). Original Forms code:
    --   SELECT COUNT(1) INTO V_COUNT FROM DUAL WHERE EXISTS
    --   (SELECT 1 FROM JOURNAL.IMPORTERS_JN IMP
    --    --(:P_CURR_PORT_CD IS NULL OR IMP.PORT_CD = :P_CURR_PORT_CD )
    --    WHERE IMP.IMPR_NBR = NVL(:IMPR_NBR1,IMP.IMPR_NBR) AND SUPP_SRCE_CD = NVL(:SUP_PORT_CD,SUPP_SRCE_CD) AND
    --    SUPP_TITLE_CD = NVL(:SUPP_TITLE_CD,SUPP_TITLE_CD) AND SUPP_LETR_NO = NVL(:LETTER_NBR,SUPP_LETR_NO) AND
    --    JN_ORACLE_USER = NVL(:USER_ID,JN_ORACLE_USER) AND
    --    TO_CHAR(SUPP_LETR_DT,'RRRR-MM-MI') = TO_CHAR(NVL(:LETTER_DT,SUPP_LETR_DT),'RRRR-MM-MI') AND
    --    TO_CHAR(SUPP_LETR_DT,'RRRR-MM-MI') >= TO_CHAR(NVL(:START_DT,SUPP_LETR_DT),'RRRR-MM-MI') AND
    --    TO_CHAR(SUPP_LETR_DT,'RRRR-MM-MI') <= TO_CHAR(NVL(:END_DT,SUPP_LETR_DT),'RRRR-MM-MI') AND
    --    ((IMP.JN_OPERATION IN('UPB','UPA') AND :REPORT= 0) OR (IMP.JN_OPERATION ='INS' AND :REPORT=1)));
    -- The port line is commented out in Forms: the count runs on every port, the report on one (spec 12, SUGGESTION).
    -- The unqualified columns are qualified (one table: IMP.).
    FUNCTION journal_count (p_report        IN VARCHAR2,
                            p_impr_nbr      IN NUMBER,
                            p_supp_srce_cd  IN NUMBER,
                            p_supp_title_cd IN NUMBER,
                            p_letter_nbr    IN VARCHAR2,
                            p_user_id       IN VARCHAR2,
                            p_letter_dt     IN DATE,
                            p_start_dt      IN DATE,
                            p_end_dt        IN DATE)
       RETURN NUMBER
    IS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(1)
          INTO v_count
          FROM dual
         WHERE EXISTS
               (SELECT 1
                  FROM journal.importers_jn imp
                 WHERE imp.impr_nbr       = NVL(journal_count.p_impr_nbr, imp.impr_nbr)
                   AND imp.supp_srce_cd   = NVL(journal_count.p_supp_srce_cd, imp.supp_srce_cd)
                   AND imp.supp_title_cd  = NVL(journal_count.p_supp_title_cd, imp.supp_title_cd)
                   AND imp.supp_letr_no   = NVL(journal_count.p_letter_nbr, imp.supp_letr_no)
                   AND imp.jn_oracle_user = NVL(journal_count.p_user_id, imp.jn_oracle_user)
                   AND TO_CHAR(imp.supp_letr_dt, 'RRRR-MM-MI')
                       =  TO_CHAR(NVL(journal_count.p_letter_dt, imp.supp_letr_dt), 'RRRR-MM-MI')
                   AND TO_CHAR(imp.supp_letr_dt, 'RRRR-MM-MI')
                       >= TO_CHAR(NVL(journal_count.p_start_dt, imp.supp_letr_dt), 'RRRR-MM-MI')
                   AND TO_CHAR(imp.supp_letr_dt, 'RRRR-MM-MI')
                       <= TO_CHAR(NVL(journal_count.p_end_dt, imp.supp_letr_dt), 'RRRR-MM-MI')
                   AND (   (imp.jn_operation IN ('UPB', 'UPA') AND journal_count.p_report = c_report_modified)
                        OR (imp.jn_operation = 'INS'           AND journal_count.p_report = c_report_added)));
        RETURN v_count;
    END journal_count;

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
    --   :REPORT_NO := :parameter.p_sys_id ||'-'||:parameter.p_rep_no;
    --   IF :PARAMETER.P_CURR_PORT_CD != 99 THEN
    --      SELECT PORT_NAME INTO :P_CURR_PORT_NAME FROM SD_PORTS WHERE PORT_CD = :PARAMETER.P_CURR_PORT_CD;
    --      NEXT_ITEM; :P_PORT_CD := :PARAMETER.P_CURR_PORT_CD;
    --      SET_ITEM_PROPERTY(P_LOV_PORT / P_PORT_NAME / P_PORT_CD, VISIBLE, FALSE);
    --   ELSE :P_CURR_PORT_NAME := NULL; END IF;
    --   GO_ITEM('START_DT');
    --   (title / date / window / logo lines -> f345 shell; P_PORT_CD -> report_port; VISIBLE -> P_PORT_CD_IS_VISIBLE)
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

    -- Source: WHEN-NEW-FORM-INSTANCE, branch :PARAMETER.P_CURR_PORT_CD != 99 (see the spec)
    FUNCTION P_PORT_CD_IS_VISIBLE (P_CURR_PORT_CD IN VARCHAR2)
       RETURN BOOLEAN
    IS
    BEGIN
        RETURN NVL(P_CURR_PORT_CD, c_all_ports) = c_all_ports;
    END P_PORT_CD_IS_VISIBLE;

    -- =========================================================================
    -- BLOCK CALLING_PARAMETERS
    -- =========================================================================

    -- Source: CALLING_PARAMETERS.WHEN-NEW-RECORD-INSTANCE
    -- Original Forms code:
    --   IF :PARAMETER.P_CURR_PORT_CD != 99 THEN :SUP_PORT_CD := :PARAMETER.P_CURR_PORT_CD; END IF;
    PROCEDURE PARAMETERS_NEW_RECORD_INSTANCE (P_SUP_PORT_CD    OUT VARCHAR2,
                                              P_SUP_PORT_NAME  OUT VARCHAR2,
                                              P_CURR_PORT_CD   IN  VARCHAR2)
    IS
    BEGIN
        P_SUP_PORT_CD   := NULL;
        P_SUP_PORT_NAME := NULL;
        IF P_CURR_PORT_CD <> c_all_ports THEN
            P_SUP_PORT_CD   := P_CURR_PORT_CD;
            P_SUP_PORT_NAME := port_name(P_CURR_PORT_CD);          -- SUGGESTION (see the spec)
        END IF;
    END PARAMETERS_NEW_RECORD_INSTANCE;

    -- Source: CALLING_PARAMETERS.REPORT (Radio Group; see the spec)
    FUNCTION REPORT_VALIDATION (P_REPORT IN VARCHAR2)
       RETURN VARCHAR2
    IS
    BEGIN
        IF P_REPORT IN (c_report_modified, c_report_added) THEN
            RETURN NULL;
        END IF;
        RETURN FORMS_APX.REQUIRED_VALIDATION(ITEM_VALUE => NULL, ITEM_LABEL => c_label_report);
    END REPORT_VALIDATION;

    -- Source: CALLING_PARAMETERS.P_PORT_CD.WHEN-VALIDATE-ITEM
    -- Original Forms code:
    --   IF :P_PORT_CD IS NOT NULL THEN SELECT PORT_NAME INTO :P_PORT_NAME FROM SD_PORTS WHERE PORT_CD = :P_PORT_CD; END IF;
    FUNCTION P_PORT_CD_VALIDATION (P_PORT_CD IN VARCHAR2)
       RETURN VARCHAR2
    IS
    BEGIN
        RETURN port_error(P_PORT_CD);
    END P_PORT_CD_VALIDATION;

    -- Source: CALLING_PARAMETERS.P_PORT_CD.WHEN-VALIDATE-ITEM (see P_PORT_CD_VALIDATION)
    PROCEDURE P_PORT_CD_WHEN_VALIDATE_ITEM (P_PORT_CD   IN  VARCHAR2,
                                            P_PORT_NAME OUT VARCHAR2)
    IS
    BEGIN
        P_PORT_NAME := NULL;
        FORMS_APX.CHECK_ERROR(P_PORT_CD_VALIDATION(P_PORT_CD => P_PORT_CD));
        P_PORT_NAME := port_name(P_PORT_CD);
    END P_PORT_CD_WHEN_VALIDATE_ITEM;

    -- Source: CALLING_PARAMETERS.SUP_PORT_CD.WHEN-VALIDATE-ITEM (see the spec)
    FUNCTION SUP_PORT_CD_VALIDATION (P_SUP_PORT_CD IN VARCHAR2)
       RETURN VARCHAR2
    IS
    BEGIN
        RETURN port_error(P_SUP_PORT_CD);                    -- NO_DATA_FOUND -> RAISE FORM_TRIGGER_FAILURE
    END SUP_PORT_CD_VALIDATION;

    -- Source: CALLING_PARAMETERS.SUP_PORT_CD.WHEN-VALIDATE-ITEM (see the spec)
    PROCEDURE SUP_PORT_CD_WHEN_VALIDATE_ITEM (P_SUP_PORT_CD   IN  VARCHAR2,
                                              P_SUP_PORT_NAME OUT VARCHAR2)
    IS
    BEGIN
        P_SUP_PORT_NAME := NULL;
        FORMS_APX.CHECK_ERROR(SUP_PORT_CD_VALIDATION(P_SUP_PORT_CD => P_SUP_PORT_CD));
        P_SUP_PORT_NAME := port_name(P_SUP_PORT_CD);
    END SUP_PORT_CD_WHEN_VALIDATE_ITEM;

    -- Source: CALLING_PARAMETERS.SUPP_TITLE_CD.WHEN-VALIDATE-ITEM (see the spec)
    FUNCTION SUPP_TITLE_CD_VALIDATION (P_SUPP_TITLE_CD IN VARCHAR2)
       RETURN VARCHAR2
    IS
        v_supp_title_cd NUMBER := number_or_null(P_SUPP_TITLE_CD);
        v_count         NUMBER;
    BEGIN
        IF TRIM(P_SUPP_TITLE_CD) IS NULL THEN
            RETURN NULL;
        END IF;
        IF v_supp_title_cd IS NULL THEN
            RETURN c_msg_supp_title;
        END IF;
        SELECT COUNT(*)
          INTO v_count
          FROM supp_titles t
         WHERE t.supp_title_cd = v_supp_title_cd;
        RETURN CASE WHEN v_count = 0 THEN c_msg_supp_title END;   -- NO_DATA_FOUND -> RAISE FORM_TRIGGER_FAILURE
    END SUPP_TITLE_CD_VALIDATION;

    -- Source: CALLING_PARAMETERS.SUPP_TITLE_CD.WHEN-VALIDATE-ITEM (see the spec)
    PROCEDURE SUPP_TITLE_CD_VALIDATE_ITEM (P_SUPP_TITLE_CD IN  VARCHAR2,
                                           P_SUPP_TITLE_NM OUT VARCHAR2)
    IS
        v_supp_title_cd NUMBER := number_or_null(P_SUPP_TITLE_CD);
    BEGIN
        P_SUPP_TITLE_NM := NULL;
        FORMS_APX.CHECK_ERROR(SUPP_TITLE_CD_VALIDATION(P_SUPP_TITLE_CD => P_SUPP_TITLE_CD));
        IF v_supp_title_cd IS NOT NULL THEN
            SELECT t.supp_title_nm
              INTO SUPP_TITLE_CD_VALIDATE_ITEM.P_SUPP_TITLE_NM
              FROM supp_titles t
             WHERE t.supp_title_cd = v_supp_title_cd;
        END IF;
    END SUPP_TITLE_CD_VALIDATE_ITEM;

    -- Source: CALLING_PARAMETERS.USER_ID.WHEN-VALIDATE-ITEM (see the spec)
    FUNCTION USER_ID_VALIDATION (P_USER_ID      IN VARCHAR2,
                                 P_PORT_CD      IN VARCHAR2,
                                 P_CURR_PORT_CD IN VARCHAR2)
       RETURN VARCHAR2
    IS
        v_port_cd NUMBER := number_or_null(report_port(P_PORT_CD, P_CURR_PORT_CD));
        v_count   NUMBER;
    BEGIN
        IF P_USER_ID IS NULL THEN
            RETURN NULL;
        END IF;
        SELECT COUNT(*)
          INTO v_count
          FROM sc_users u
         WHERE u.port_cd = v_port_cd
           AND u.user_id = USER_ID_VALIDATION.P_USER_ID;
        RETURN CASE WHEN v_count = 0 THEN FORMS_APX.ARABIC_MESSAGE(1, 80) END;   -- STR.DISPARBMSG(1, 80) + FTF
    END USER_ID_VALIDATION;

    -- Source: CALLING_PARAMETERS.USER_ID.WHEN-VALIDATE-ITEM (see the spec)
    PROCEDURE USER_ID_WHEN_VALIDATE_ITEM (P_USER_ID       IN  VARCHAR2,
                                          P_PORT_CD       IN  VARCHAR2,
                                          P_CURR_PORT_CD  IN  VARCHAR2,
                                          P_USR_USR_ANAME OUT VARCHAR2)
    IS
        v_port_cd NUMBER := number_or_null(report_port(P_PORT_CD, P_CURR_PORT_CD));
    BEGIN
        P_USR_USR_ANAME := NULL;
        FORMS_APX.CHECK_ERROR(USER_ID_VALIDATION(P_USER_ID      => P_USER_ID,
                                                 P_PORT_CD      => P_PORT_CD,
                                                 P_CURR_PORT_CD => P_CURR_PORT_CD));
        IF P_USER_ID IS NOT NULL THEN
            SELECT MAX(u.usr_aname)
              INTO USER_ID_WHEN_VALIDATE_ITEM.P_USR_USR_ANAME
              FROM sc_users u
             WHERE u.port_cd = v_port_cd
               AND u.user_id = USER_ID_WHEN_VALIDATE_ITEM.P_USER_ID;
        END IF;
    END USER_ID_WHEN_VALIDATE_ITEM;

    -- Source: CALLING_PARAMETERS.IMPR_NBR1.WHEN-VALIDATE-ITEM (see the spec)
    -- SUGGESTION: Forms opened the LOV on TOO_MANY_ROWS (the number in several ports); here the first name (MIN) is
    --   shown. Forms cleared IMPR_NBR1 without a message when no importer matched; kept.
    PROCEDURE IMPR_NBR1_WHEN_VALIDATE_ITEM (P_IMPR_NBR1 IN OUT VARCHAR2,
                                            P_IMPR_NAME OUT    VARCHAR2)
    IS
        v_impr_nbr NUMBER := number_or_null(P_IMPR_NBR1);
        v_count    NUMBER;
    BEGIN
        P_IMPR_NAME := NULL;
        IF TRIM(P_IMPR_NBR1) IS NULL THEN
            RETURN;
        END IF;
        SELECT MIN(i.arbc_impr_name), COUNT(*)
          INTO IMPR_NBR1_WHEN_VALIDATE_ITEM.P_IMPR_NAME, v_count
          FROM importers i
         WHERE i.impr_nbr = v_impr_nbr;
        IF v_count = 0 THEN                         -- WHEN OTHERS (NO_DATA_FOUND, not a number): :IMPR_NBR1 := NULL
            P_IMPR_NBR1 := NULL;
        END IF;
    END IMPR_NBR1_WHEN_VALIDATE_ITEM;

    -- =========================================================================
    -- BLOCK TOOLBAR
    -- =========================================================================

    -- Source: PU CHECK_VAL (ITEM304 «عرض», KEY-F4 / KEY-F5) - see the spec (user decision 2026-11-26).
    -- The item checks run again here (the DAs may not have run); then the two date rules and the count of CHECK_VAL.
    PROCEDURE PRINT_CHECK_VAL (P_REPORT         IN  VARCHAR2,
                               P_PORT_CD        IN  VARCHAR2,
                               P_START_DT       IN  VARCHAR2,
                               P_END_DT         IN  VARCHAR2,
                               P_SUP_PORT_CD    IN  VARCHAR2,
                               P_SUPP_TITLE_CD  IN  VARCHAR2,
                               P_LETTER_NBR     IN  VARCHAR2,
                               P_LETTER_DT      IN  VARCHAR2,
                               P_USER_ID        IN  VARCHAR2,
                               P_IMPR_NBR1      IN  VARCHAR2,
                               P_REPORT_NO      IN  VARCHAR2,
                               P_HERO_TITLE     IN  VARCHAR2,
                               P_CURR_PORT_CD   IN  VARCHAR2,
                               P_REPORT_URL     OUT VARCHAR2)
    IS
        v_port_cd   VARCHAR2(30) := report_port(P_PORT_CD, P_CURR_PORT_CD);
        v_start_dt  DATE;
        v_end_dt    DATE;
        v_letter_dt DATE;
    BEGIN
        FORMS_APX.CHECK_ERROR(REPORT_VALIDATION(P_REPORT => P_REPORT));
        FORMS_APX.CHECK_ERROR(P_PORT_CD_VALIDATION(P_PORT_CD => v_port_cd));
        FORMS_APX.CHECK_ERROR(FORMS_APX.HIJRI_DATE_ERROR(P_START_DT));
        FORMS_APX.CHECK_ERROR(FORMS_APX.HIJRI_DATE_ERROR(P_END_DT));
        FORMS_APX.CHECK_ERROR(FORMS_APX.HIJRI_DATE_ERROR(P_LETTER_DT));
        FORMS_APX.CHECK_ERROR(SUP_PORT_CD_VALIDATION(P_SUP_PORT_CD => P_SUP_PORT_CD));
        FORMS_APX.CHECK_ERROR(SUPP_TITLE_CD_VALIDATION(P_SUPP_TITLE_CD => P_SUPP_TITLE_CD));
        FORMS_APX.CHECK_ERROR(USER_ID_VALIDATION(P_USER_ID      => P_USER_ID,
                                                 P_PORT_CD      => P_PORT_CD,
                                                 P_CURR_PORT_CD => P_CURR_PORT_CD));
        v_start_dt  := page_date(P_START_DT);
        v_end_dt    := page_date(P_END_DT);
        v_letter_dt := page_date(P_LETTER_DT);
        -- IF :LETTER_DT IS NOT NULL AND (:START_DT IS NOT NULL OR :END_DT IS NOT NULL) THEN MESSAGE(...); FTF;
        IF v_letter_dt IS NOT NULL AND (v_start_dt IS NOT NULL OR v_end_dt IS NOT NULL) THEN
            FORMS_APX.CHECK_ERROR(c_msg_letter_dates);
        END IF;
        -- IF TO_CHAR(:END_DT,'RRRR-MM-MI') < TO_CHAR(:START_DT,'RRRR-MM-MI') THEN MESSAGE(...); FTF;
        IF v_start_dt IS NOT NULL AND v_end_dt IS NOT NULL
           AND TO_CHAR(v_end_dt, 'RRRR-MM-MI') < TO_CHAR(v_start_dt, 'RRRR-MM-MI') THEN
            FORMS_APX.CHECK_ERROR(c_msg_period);
        END IF;
        IF journal_count(P_REPORT, number_or_null(P_IMPR_NBR1), number_or_null(P_SUP_PORT_CD),
                         number_or_null(P_SUPP_TITLE_CD), TRIM(P_LETTER_NBR), P_USER_ID,
                         v_letter_dt, v_start_dt, v_end_dt) = 0 THEN
            FORMS_APX.CHECK_ERROR(c_msg_no_rows);
        END IF;
        P_REPORT_URL := PRINT_IMPR3100_ARD(p_curr_port_cd  => v_port_cd,
                                           p_start_dt      => ard_date(v_start_dt),
                                           p_end_dt        => ard_date(v_end_dt),
                                           p_supp_srce_cd  => TO_CHAR(number_or_null(P_SUP_PORT_CD)),
                                           p_impr_nbr      => TO_CHAR(number_or_null(P_IMPR_NBR1)),
                                           p_supp_title_cd => TO_CHAR(number_or_null(P_SUPP_TITLE_CD)),
                                           p_letter_nbr    => TRIM(P_LETTER_NBR),
                                           p_letter_dt     => ard_date(v_letter_dt),
                                           p_user_id       => P_USER_ID,
                                           p_report1       => P_REPORT,
                                           p_module_name   => P_HERO_TITLE,
                                           p_report_no     => P_REPORT_NO);
    END PRINT_CHECK_VAL;

    -- =========================================================================
    -- PROGRAM UNITS
    -- =========================================================================

    -- Source: REP.Run_Product(REPORTS, V_REPORT_FILE, SYNCHRONOUS, RUNTIME, FILESYSTEM, pl_id, NULL)
    -- Pattern: PRINT_<FORM>_ARD of the approved standard 13-b / 13-c (as PRINT_IMPR2310_ARD); no server link in the
    -- code: ARD_URL and ARD_DSNAME are settings (SC_PORT_SETTING, SYSOBJ_ID 999, PORT_CD 99 -
    -- migration/001_ard_settings.sql); a missing setting stops with a message.
    FUNCTION PRINT_IMPR3100_ARD (p_curr_port_cd  IN VARCHAR2,
                                 p_start_dt      IN VARCHAR2,
                                 p_end_dt        IN VARCHAR2,
                                 p_supp_srce_cd  IN VARCHAR2,
                                 p_impr_nbr      IN VARCHAR2,
                                 p_supp_title_cd IN VARCHAR2,
                                 p_letter_nbr    IN VARCHAR2,
                                 p_letter_dt     IN VARCHAR2,
                                 p_user_id       IN VARCHAR2,
                                 p_report1       IN VARCHAR2,
                                 p_module_name   IN VARCHAR2,
                                 p_report_no     IN VARCHAR2)
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
               || ard_parameter(2, p_start_dt)
               || ard_parameter(3, p_end_dt)
               || ard_parameter(4, p_supp_srce_cd)
               || ard_parameter(5, p_impr_nbr)
               || ard_parameter(6, p_supp_title_cd)
               || ard_parameter(7, p_letter_nbr)
               || ard_parameter(8, p_letter_dt)
               || ard_parameter(9, p_user_id)
               || ard_parameter(10, p_report1)
               || ard_parameter(11, p_module_name)
               || ard_parameter(12, p_report_no)
               || CHR(38) || 'DsName=' || UTL_URL.ESCAPE(v_dsname, TRUE, 'UTF-8');
    END PRINT_IMPR3100_ARD;

END IMPR3100;
/
SHOW ERRORS
