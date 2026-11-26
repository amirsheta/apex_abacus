-- =============================================================================
-- Package body: IMPR2310   (matches impr2310_spec.sql - f345 standard)
-- Source form : IMPR2310.fmb   Target: APEX 21.2 / DB 12.1.0.2   Version: 001
-- Author      : Claude Code     Created: 2026-11-26   (see the spec history)
-- Rules: no Forms built-ins (FORMS_APX instead), no COMMIT / ROLLBACK, no V('...'),
--        parameters named after their binds without I_ / IO_ / O_; page items P<page>_X -> P_X;
--        inside SQL every parameter is qualified with its member name; identifiers <= 30 bytes.
-- Common helpers: FORMS_APX (version 004), called as FORMS_APX.<NAME>.
-- Layout (docs/f345_reference_standard.md §10): PRIVATE HELPERS (+ the PRINT_CHECK_VAL count) -> VERSION -> FORM LEVEL
-- -> BLOCK CALLING_PARAMETERS -> BLOCK TOOLBAR -> PROGRAM UNITS.
-- Status: NOT COMPILED. The report: IMPR2310_ARD (plsql/IMPR2310).
-- =============================================================================
SET DEFINE OFF

CREATE OR REPLACE PACKAGE BODY LIB_APX_USR.IMPR2310
AS
    c_all_ports        CONSTANT VARCHAR2(2)  := '99';         -- P_CURR_PORT_CD 99 = head office (all ports)
    -- ARD server settings in SC_PORT_SETTING (user decision 2026-11-25): SYSOBJ_ID 999, PORT_CD 99, VAR_NAME ARD_URL / ARD_DSNAME
    c_settings_object  CONSTANT VARCHAR2(10) := '999';
    c_msg_ard_setting  CONSTANT VARCHAR2(200) := 'إعداد خادم التقارير غير موجود في SC_PORT_SETTING (SYSOBJ_ID 999، PORT_CD 99): ';
    c_ard_function     CONSTANT VARCHAR2(60) := 'LIB_APX_USR.IMPR2310_ARD.ARD_IMPR2310';
    c_ard_date_format  CONSTANT VARCHAR2(20) := 'YYYY-MM-MI';  -- date text read by IMPR2310_ARD (as DCLN3300_ARD)
    c_number_pattern   CONSTANT VARCHAR2(20) := '^[0-9]+$';

    -- SELECT1 / REPORT values (Radio Group elements of the XML)
    c_select_importer  CONSTANT VARCHAR2(1) := '1';   -- حسب رقم المستورد
    c_select_letter    CONSTANT VARCHAR2(1) := '2';   -- حسب الخطاب
    c_report_modified  CONSTANT VARCHAR2(1) := '0';   -- تعديلات بيانات المستوردين
    c_report_added     CONSTANT VARCHAR2(1) := '1';   -- إضافة مستوردين جدد

    -- Forms texts
    c_msg_port         CONSTANT VARCHAR2(100) := 'رمز الجمرك غير صحيح';
    c_msg_importer     CONSTANT VARCHAR2(100) := 'الرجاء تحديد رقم المستورد';
    c_msg_letter       CONSTANT VARCHAR2(100) := 'الرجاء إدخال بيانات الخطاب أو الفترة';
    c_msg_no_rows      CONSTANT VARCHAR2(100) := 'لا يوجد سجلات تحقق المطلوب';
    c_label_select1    CONSTANT VARCHAR2(50)  := 'نوع الاستعلام';
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
    -- P_CURR_PORT_CD), else the port item, else P_CURR_PORT_CD (as IMPR2130 NVL(P_PORT_CD, P_CURR_PORT_CD))
    FUNCTION report_port (p_port_cd IN VARCHAR2, p_curr_port_cd IN VARCHAR2)
       RETURN VARCHAR2
    IS
    BEGIN
        RETURN CASE WHEN NVL(p_curr_port_cd, c_all_ports) <> c_all_ports THEN p_curr_port_cd
                    ELSE NVL(TRIM(p_port_cd), NVL(p_curr_port_cd, c_all_ports)) END;
    END report_port;

    -- a Hijri date as the text IMPR2310_ARD reads (NULL stays NULL)
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

    -- Source: PU PRINT_CHECK_VAL / CHECK_VAL, the count before REP.Run_Product (kept as in Forms, as the IMPR2140 user
    -- decision of 2026-11-25). Original Forms code:
    --   SELECT COUNT(IMP.IMPR_NBR) INTO V_COUNT FROM JOURNAL.IMPORTERS_JN IMP
    --   --(:P_CURR_PORT_CD IS NULL OR IMP.PORT_CD = :P_CURR_PORT_CD )
    --   WHERE ((:REPORT=0 AND IMP.JN_OPERATION<> 'INS') OR (:REPORT=1 AND IMP.JN_OPERATION= 'INS')) AND
    --   ((:SELECT1=1 AND IMP.IMPR_NBR = :IMPR_NBR)
    --    OR (:SELECT1=2 AND
    --        ((IMP.SUPP_LETR_NO =:LTR_NBR
    --          AND (TO_CHAR(IMP.SUPP_LETR_DT,'RRRR-MM-MI')=TO_CHAR(:LTR_DATE,'RRRR-MM-MI') OR :LTR_DATE IS NULL)
    --          AND (SUPP_SRCE_CD=:SUPP_SRCE_CD OR :SUPP_SRCE_CD IS NULL) AND (:LTR_NBR IS NOT NULL))
    --         OR (:LTR_NBR IS NULL AND :START_DT IS NOT NULL AND :END_DT IS NOT NULL AND
    --             ((SUPP_LETR_DT BETWEEN :START_DT AND :END_DT)
    --              OR (:START_DT IS NULL AND :END_DT IS NULL AND :LTR_NBR IS NOT NULL))))));
    -- The port line is commented out in Forms: the count runs on every port, the report on one (spec 12, SUGGESTION).
    -- SUPP_SRCE_CD / SUPP_LETR_DT were unqualified (one table: IMP.).
    FUNCTION journal_count (p_select1      IN VARCHAR2,
                            p_report       IN VARCHAR2,
                            p_impr_nbr     IN NUMBER,
                            p_ltr_nbr      IN VARCHAR2,
                            p_ltr_date     IN DATE,
                            p_supp_srce_cd IN NUMBER,
                            p_start_dt     IN DATE,
                            p_end_dt       IN DATE)
       RETURN NUMBER
    IS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(imp.impr_nbr)
          INTO v_count
          FROM journal.importers_jn imp
         WHERE (   (journal_count.p_report = c_report_modified AND imp.jn_operation <> 'INS')
                OR (journal_count.p_report = c_report_added    AND imp.jn_operation =  'INS'))
           AND (   (journal_count.p_select1 = c_select_importer AND imp.impr_nbr = journal_count.p_impr_nbr)
                OR (    journal_count.p_select1 = c_select_letter
                    AND (   (    imp.supp_letr_no = journal_count.p_ltr_nbr
                             AND (   TO_CHAR(imp.supp_letr_dt, 'RRRR-MM-MI') = TO_CHAR(journal_count.p_ltr_date, 'RRRR-MM-MI')
                                  OR journal_count.p_ltr_date IS NULL)
                             AND (imp.supp_srce_cd = journal_count.p_supp_srce_cd OR journal_count.p_supp_srce_cd IS NULL)
                             AND journal_count.p_ltr_nbr IS NOT NULL)
                         OR (    journal_count.p_ltr_nbr IS NULL
                             AND journal_count.p_start_dt IS NOT NULL
                             AND journal_count.p_end_dt IS NOT NULL
                             AND (   imp.supp_letr_dt BETWEEN journal_count.p_start_dt AND journal_count.p_end_dt
                                  OR (    journal_count.p_start_dt IS NULL       -- never true here; kept as in Forms
                                      AND journal_count.p_end_dt IS NULL
                                      AND journal_count.p_ltr_nbr IS NOT NULL))))));
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
    --   :SELECT1:=2;  SET_ITEM_PROPERTY(IMPR_NBR / IMPR_NAME / LOV_IMPR, ENABLED, FALSE); (letter items ENABLED TRUE)
    --   IF :PARAMETER.P_CURR_PORT_CD != 99 THEN
    --      SELECT PORT_NAME INTO :P_CURR_PORT_NAME FROM SD_PORTS WHERE PORT_CD = :PARAMETER.P_CURR_PORT_CD;
    --      NEXT_ITEM; :P_PORT_CD := :PARAMETER.P_CURR_PORT_CD;
    --      SET_ITEM_PROPERTY(P_LOV_PORT / P_PORT_NAME / P_PORT_CD, VISIBLE, FALSE);
    --   ELSE :P_CURR_PORT_NAME := NULL; END IF;
    --   (title / date / window / logo lines -> f345 shell; SELECT1 -> item default; Enable / Disable -> DA on page load;
    --    P_PORT_CD -> report_port; VISIBLE -> P_PORT_CD_IS_VISIBLE)
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

    -- Source: CALLING_PARAMETERS.P_PORT_CD.WHEN-VALIDATE-ITEM
    -- Original Forms code:
    --   IF :P_PORT_CD IS NOT NULL THEN SELECT PORT_NAME INTO :P_PORT_NAME FROM SD_PORTS WHERE PORT_CD = :P_PORT_CD; END IF;
    FUNCTION P_PORT_CD_VALIDATION (P_PORT_CD IN VARCHAR2)
       RETURN VARCHAR2
    IS
        v_port_cd NUMBER := number_or_null(P_PORT_CD);
        v_count   NUMBER;
    BEGIN
        IF TRIM(P_PORT_CD) IS NULL THEN
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
    END P_PORT_CD_VALIDATION;

    -- Source: CALLING_PARAMETERS.P_PORT_CD.WHEN-VALIDATE-ITEM (see P_PORT_CD_VALIDATION)
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

    -- Source: CALLING_PARAMETERS.SELECT1 (Radio Group; see the spec)
    FUNCTION SELECT1_VALIDATION (P_SELECT1 IN VARCHAR2)
       RETURN VARCHAR2
    IS
    BEGIN
        IF P_SELECT1 IN (c_select_importer, c_select_letter) THEN
            RETURN NULL;
        END IF;
        RETURN FORMS_APX.REQUIRED_VALIDATION(ITEM_VALUE => NULL, ITEM_LABEL => c_label_select1);
    END SELECT1_VALIDATION;

    -- Source: CALLING_PARAMETERS.IMPR_NBR.WHEN-VALIDATE-ITEM (see the spec)
    -- SUGGESTION: Forms opened the LOV on TOO_MANY_ROWS (the number in several ports); here the first name (MIN) is
    --   shown. Forms cleared IMPR_NBR without a message when no importer matched; kept.
    PROCEDURE IMPR_NBR_WHEN_VALIDATE_ITEM (P_IMPR_NBR  IN OUT VARCHAR2,
                                           P_IMPR_NAME OUT    VARCHAR2)
    IS
        v_impr_nbr NUMBER := number_or_null(P_IMPR_NBR);
        v_count    NUMBER;
    BEGIN
        P_IMPR_NAME := NULL;
        IF TRIM(P_IMPR_NBR) IS NULL THEN
            RETURN;
        END IF;
        SELECT MIN(i.arbc_impr_name), COUNT(*)
          INTO IMPR_NBR_WHEN_VALIDATE_ITEM.P_IMPR_NAME, v_count
          FROM importers i
         WHERE i.impr_nbr = v_impr_nbr;
        IF v_count = 0 THEN                         -- WHEN OTHERS (NO_DATA_FOUND, not a number): :IMPR_NBR := NULL
            P_IMPR_NBR := NULL;
        END IF;
    END IMPR_NBR_WHEN_VALIDATE_ITEM;

    -- =========================================================================
    -- BLOCK TOOLBAR
    -- =========================================================================

    -- Source: PU PRINT_CHECK_VAL (ITEM303 «طباعة», KEY-F5) and PU CHECK_VAL (ITEM304 «عرض», KEY-F4) - see the spec.
    -- The item checks run again here (the DAs may not have run). Forms only showed MESSAGE for the two "missing" texts
    -- (no FORM_TRIGGER_FAILURE, nothing printed); here they stop with the same text.
    PROCEDURE PRINT_CHECK_VAL (P_SELECT1        IN  VARCHAR2,
                               P_REPORT         IN  VARCHAR2,
                               P_PORT_CD        IN  VARCHAR2,
                               P_IMPR_NBR       IN  VARCHAR2,
                               P_LTR_NBR        IN  VARCHAR2,
                               P_LTR_DATE       IN  VARCHAR2,
                               P_SUPP_SRCE_CD   IN  VARCHAR2,
                               P_START_DT       IN  VARCHAR2,
                               P_END_DT         IN  VARCHAR2,
                               P_REPORT_NO      IN  VARCHAR2,
                               P_HERO_TITLE     IN  VARCHAR2,
                               P_CURR_PORT_CD   IN  VARCHAR2,
                               P_REPORT_URL     OUT VARCHAR2)
    IS
        v_impr_nbr     NUMBER;
        v_ltr_nbr      VARCHAR2(60);
        v_ltr_date     DATE;
        v_supp_srce_cd NUMBER;
        v_start_dt     DATE;
        v_end_dt       DATE;
        v_port_cd      VARCHAR2(30) := report_port(P_PORT_CD, P_CURR_PORT_CD);
    BEGIN
        FORMS_APX.CHECK_ERROR(SELECT1_VALIDATION(P_SELECT1 => P_SELECT1));
        FORMS_APX.CHECK_ERROR(REPORT_VALIDATION(P_REPORT => P_REPORT));
        FORMS_APX.CHECK_ERROR(P_PORT_CD_VALIDATION(P_PORT_CD => v_port_cd));
        IF P_SELECT1 = c_select_importer THEN          -- SELECT1.WHEN-RADIO-CHANGED cleared the letter / period items
            v_impr_nbr := number_or_null(P_IMPR_NBR);
            IF v_impr_nbr IS NULL THEN
                FORMS_APX.CHECK_ERROR(c_msg_importer);
            END IF;
        ELSE                                           -- SELECT1.WHEN-RADIO-CHANGED cleared IMPR_NBR
            FORMS_APX.CHECK_ERROR(FORMS_APX.HIJRI_DATE_ERROR(P_LTR_DATE));
            FORMS_APX.CHECK_ERROR(FORMS_APX.HIJRI_DATE_ERROR(P_START_DT));
            FORMS_APX.CHECK_ERROR(FORMS_APX.HIJRI_DATE_ERROR(P_END_DT));
            v_ltr_nbr      := TRIM(P_LTR_NBR);
            v_ltr_date     := CASE WHEN P_LTR_DATE IS NOT NULL THEN FORMS_APX.HIJRI_TEXT_TO_DATE(P_LTR_DATE) END;
            v_supp_srce_cd := number_or_null(P_SUPP_SRCE_CD);
            v_start_dt     := CASE WHEN P_START_DT IS NOT NULL THEN FORMS_APX.HIJRI_TEXT_TO_DATE(P_START_DT) END;
            v_end_dt       := CASE WHEN P_END_DT IS NOT NULL THEN FORMS_APX.HIJRI_TEXT_TO_DATE(P_END_DT) END;
            IF v_ltr_nbr IS NULL AND (v_start_dt IS NULL OR v_end_dt IS NULL) THEN
                FORMS_APX.CHECK_ERROR(c_msg_letter);
            END IF;
        END IF;
        IF journal_count(P_SELECT1, P_REPORT, v_impr_nbr, v_ltr_nbr, v_ltr_date, v_supp_srce_cd,
                         v_start_dt, v_end_dt) = 0 THEN
            FORMS_APX.CHECK_ERROR(c_msg_no_rows);
        END IF;
        P_REPORT_URL := PRINT_IMPR2310_ARD(p_curr_port_cd => v_port_cd,
                                           p_select1      => P_SELECT1,
                                           p_report1      => P_REPORT,
                                           p_impr_nbr     => TO_CHAR(v_impr_nbr),
                                           p_ltr_nbr      => v_ltr_nbr,
                                           p_ltr_date     => ard_date(v_ltr_date),
                                           p_supp_srce_cd => TO_CHAR(v_supp_srce_cd),
                                           p_start_dt     => ard_date(v_start_dt),
                                           p_end_dt       => ard_date(v_end_dt),
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
    FUNCTION PRINT_IMPR2310_ARD (p_curr_port_cd IN VARCHAR2,
                                 p_select1      IN VARCHAR2,
                                 p_report1      IN VARCHAR2,
                                 p_impr_nbr     IN VARCHAR2,
                                 p_ltr_nbr      IN VARCHAR2,
                                 p_ltr_date     IN VARCHAR2,
                                 p_supp_srce_cd IN VARCHAR2,
                                 p_start_dt     IN VARCHAR2,
                                 p_end_dt       IN VARCHAR2,
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
               || ard_parameter(2, p_select1)
               || ard_parameter(3, p_report1)
               || ard_parameter(4, p_impr_nbr)
               || ard_parameter(5, p_ltr_nbr)
               || ard_parameter(6, p_ltr_date)
               || ard_parameter(7, p_supp_srce_cd)
               || ard_parameter(8, p_start_dt)
               || ard_parameter(9, p_end_dt)
               || ard_parameter(10, p_module_name)
               || ard_parameter(11, p_report_no)
               || CHR(38) || 'DsName=' || UTL_URL.ESCAPE(v_dsname, TRUE, 'UTF-8');
    END PRINT_IMPR2310_ARD;

END IMPR2310;
/
SHOW ERRORS
