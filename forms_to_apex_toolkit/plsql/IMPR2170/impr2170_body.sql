-- =============================================================================
-- Package body: IMPR2170   (matches impr2170_spec.sql - f345 standard)
-- Source form : IMPR2170.fmb   Target: APEX 21.2 / DB 12.1.0.2   Version: 001
-- Author      : Claude Code     Created: 2026-11-25   (see the spec history)
-- Rules: no Forms built-ins (FORMS_APX instead), no COMMIT / ROLLBACK, no V('...'),
--        parameters named after their binds without I_ / IO_ / O_; page items P<page>_X -> P_X;
--        inside SQL every parameter is qualified with its member name; identifiers <= 30 bytes.
-- Common helpers: FORMS_APX (version 004), called as FORMS_APX.<NAME>.
-- Layout (docs/f345_reference_standard.md §10): PRIVATE HELPERS (+ PU COUNT_SUSP1) -> VERSION -> FORM LEVEL
-- -> BLOCK CALLING_PARAMETERS -> BLOCK TOOLBAR -> PROGRAM UNITS.
-- Status: NOT COMPILED. The report: IMPR2170_ARD (plsql/IMPR2170).
-- =============================================================================
SET DEFINE OFF

CREATE OR REPLACE PACKAGE BODY LIB_APX_USR.IMPR2170
AS
    c_all_ports        CONSTANT VARCHAR2(2)  := '99';         -- P_CURR_PORT_CD 99 = head office (all ports)
    -- ARD server settings in SC_PORT_SETTING (user decision 2026-11-25): SYSOBJ_ID 999, PORT_CD 99, VAR_NAME ARD_URL / ARD_DSNAME
    c_settings_object  CONSTANT VARCHAR2(10) := '999';
    c_msg_ard_setting  CONSTANT VARCHAR2(200) := 'إعداد خادم التقارير غير موجود في SC_PORT_SETTING (SYSOBJ_ID 999، PORT_CD 99): ';
    c_ard_function     CONSTANT VARCHAR2(60) := 'LIB_APX_USR.IMPR2170_ARD.ARD_IMPR2170';
    c_number_pattern   CONSTANT VARCHAR2(20) := '^[0-9]+$';

    -- SELECT1 values (Radio Group elements of the XML)
    c_select_port      CONSTANT VARCHAR2(1) := '1';   -- جمرك محدد: importer number of one port
    c_select_unified   CONSTANT VARCHAR2(1) := '2';   -- جميع الجمارك: unified importer number

    -- Forms texts
    c_msg_port         CONSTANT VARCHAR2(100) := 'رمز الجمرك غير صحيح';
    c_msg_importer     CONSTANT VARCHAR2(100) := 'الرجاء تحديد رقم المستورد';
    c_msg_unified      CONSTANT VARCHAR2(100) := 'الرجاء تحديد رقم المستورد الموحد';
    c_msg_no_suspension CONSTANT VARCHAR2(100) := 'حالة المستورد سليمة';
    c_label_port       CONSTANT VARCHAR2(50)  := 'رمز الجمرك';
    c_label_select1    CONSTANT VARCHAR2(50)  := 'نوع الاستعلام';

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

    -- the port of the user outside head office, else the port item (PU ENB_DISP_FLDS: :P_PORT_CD := P_CURR_PORT_CD)
    FUNCTION effective_port (p_port_cd IN VARCHAR2, p_curr_port_cd IN VARCHAR2)
       RETURN VARCHAR2
    IS
    BEGIN
        RETURN CASE WHEN NVL(p_curr_port_cd, c_all_ports) <> c_all_ports THEN p_curr_port_cd ELSE p_port_cd END;
    END effective_port;

    -- ardpdf parameter: &P_PARAMETER<n>=<value>, URL-escaped (UTF-8), as PRINT_IMPR2110_ARD
    FUNCTION ard_parameter (p_n IN PLS_INTEGER, p_value IN VARCHAR2)
       RETURN VARCHAR2
    IS
    BEGIN
        RETURN CHR(38) || 'P_PARAMETER' || p_n || '=' || UTL_URL.ESCAPE(p_value, TRUE, 'UTF-8');
    END ard_parameter;

    -- -------------------------------------------------------------------------
    -- PU COUNT_SUSP1 (kept as in Forms, as the IMPR2140 user decision of 2026-11-25), in three parts.
    -- Forms runs the checks one after the other; each runs only while every earlier one found nothing, each is
    -- SELECT COUNT(1) FROM DUAL WHERE EXISTS (...) (0 or 1) with its own EXCEPTION WHEN OTHERS THEN NULL, and the
    -- function returns their sum. So the result is 1 at the first check that finds a row, else 0; a check that fails
    -- counts 0. Every check ends with the same importer condition (the importer's business id):
    --   EXISTS (SELECT 1 FROM IMPORTERS I WHERE ((I.IMPR_NBR = :IMPR_NBR AND PORT_CD = :P_PORT_CD)
    --                                            OR I.HQ_IMPR_NBR = :HQ_IMPR_NBR) AND IMP.BUS_ID = I.BUS_ID)
    -- (unqualified PORT_CD = I.PORT_CD; checks 7 and 8 read IMP.IMPR_NBR / IMP.HQ_IMPR_NBR there - kept).
    -- The date rules are copied as written: TO_CHAR(..., 'YYYY-MM-MI') compares year, month and MINUTE (not day), and
    -- DCRE_EXPR_DATE > TO_CHAR(XDT, 'YYYY-MM-MI') converts the text with the session NLS_DATE_FORMAT (Forms PRE-FORM set
    -- 'YYYY/MM/DD HH24:MI:SS'). SUGGESTION: probably meant 'YYYY-MM-DD'; to confirm with the business owner (spec 12).
    -- -------------------------------------------------------------------------

    -- COUNT_SUSP1 checks XBUF1 .. XBUF8 (every user)
    FUNCTION count_susp1_common (p_impr_nbr IN NUMBER, p_port_cd IN NUMBER, p_hq_impr_nbr IN NUMBER,
                                 p_select1  IN NUMBER, p_xdt     IN DATE)
       RETURN NUMBER
    IS
        v_found NUMBER := 0;
    BEGIN
        -- XBUF1: open suspension in the port (IMPR_SUSPNS)
        BEGIN
            SELECT COUNT(1) INTO v_found FROM dual
             WHERE EXISTS (SELECT 1 FROM importers imp, impr_suspns is_1
                            WHERE is_1.port_cd = imp.port_cd AND is_1.impr_nbr = imp.impr_nbr
                              AND TO_CHAR(is_1.suspn_strt_dt, 'YYYY-MM-MI') <= TO_CHAR(p_xdt, 'YYYY-MM-MI')
                              AND TO_CHAR(is_1.suspn_end_dt, 'YYYY-MM-MI') >= TO_CHAR(p_xdt, 'YYYY-MM-MI')
                              AND is_1.suspn_rlse_dt IS NULL
                              AND EXISTS (SELECT 1 FROM importers i
                                           WHERE ((i.impr_nbr = p_impr_nbr AND i.port_cd = p_port_cd) OR i.hq_impr_nbr = p_hq_impr_nbr)
                                             AND imp.bus_id = i.bus_id));
        EXCEPTION WHEN OTHERS THEN v_found := 0;
        END;
        IF v_found > 0 THEN RETURN v_found; END IF;
        -- XBUF2: business id without expiry date or expired
        BEGIN
            SELECT COUNT(1) INTO v_found FROM dual
             WHERE EXISTS (SELECT 1 FROM importers imp
                            WHERE (imp.bus_id_exprd_dt IS NULL OR imp.bus_id_exprd_dt < p_xdt)
                              AND EXISTS (SELECT 1 FROM importers i
                                           WHERE ((i.impr_nbr = p_impr_nbr AND i.port_cd = p_port_cd) OR i.hq_impr_nbr = p_hq_impr_nbr)
                                             AND imp.bus_id = i.bus_id));
        EXCEPTION WHEN OTHERS THEN v_found := 0;
        END;
        IF v_found > 0 THEN RETURN v_found; END IF;
        -- XBUF3: open seizure (IMPORTER_SEIZURES, SZR_STATUS 1)
        BEGIN
            SELECT COUNT(1) INTO v_found FROM dual
             WHERE EXISTS (SELECT 1 FROM importers imp, importer_seizures is_1, hq_imprs hi, bus_id_types l_bit
                            WHERE is_1.hq_impr_nbr = imp.hq_impr_nbr AND is_1.hq_impr_nbr = hi.hq_impr_nbr
                              AND is_1.szr_status = 1 AND hi.bus_id_type_cd = l_bit.bus_id_type_cd
                              AND EXISTS (SELECT 1 FROM importers i
                                           WHERE ((i.impr_nbr = p_impr_nbr AND i.port_cd = p_port_cd) OR i.hq_impr_nbr = p_hq_impr_nbr)
                                             AND imp.bus_id = i.bus_id));
        EXCEPTION WHEN OTHERS THEN v_found := 0;
        END;
        IF v_found > 0 THEN RETURN v_found; END IF;
        -- XBUF4: open customs instruction (CSTMS_INSTS type 1, status 1)
        BEGIN
            SELECT COUNT(1) INTO v_found FROM dual
             WHERE EXISTS (SELECT 1 FROM importers imp, cstms_insts ci
                            WHERE ci.port_cd = imp.port_cd AND ci.impr_nbr = imp.impr_nbr
                              AND ci.inst_type = 1 AND ci.inst_status = 1
                              AND EXISTS (SELECT 1 FROM importers i
                                           WHERE ((i.impr_nbr = p_impr_nbr AND i.port_cd = p_port_cd) OR i.hq_impr_nbr = p_hq_impr_nbr)
                                             AND imp.bus_id = i.bus_id));
        EXCEPTION WHEN OTHERS THEN v_found := 0;
        END;
        IF v_found > 0 THEN RETURN v_found; END IF;
        -- XBUF5: duty difference block not released (IMPR_DUTY_DIFF_BLKS)
        BEGIN
            SELECT COUNT(1) INTO v_found FROM dual
             WHERE EXISTS (SELECT 1 FROM importers imp, impr_duty_diff_blks blk
                            WHERE blk.hq_impr_nbr = imp.hq_impr_nbr AND blk.blk_rls_dt IS NULL
                              AND EXISTS (SELECT 1 FROM importers i
                                           WHERE ((i.impr_nbr = p_impr_nbr AND i.port_cd = p_port_cd) OR i.hq_impr_nbr = p_hq_impr_nbr)
                                             AND imp.bus_id = i.bus_id));
        EXCEPTION WHEN OTHERS THEN v_found := 0;
        END;
        IF v_found > 0 THEN RETURN v_found; END IF;
        -- XBUF6: accuracy inspection (IMPR_ACCUR_INSPCTNS with a SINGLE_IMPORTERS row)
        BEGIN
            SELECT COUNT(1) INTO v_found FROM dual
             WHERE EXISTS (SELECT 1 FROM importers imp, impr_accur_inspctns ins, single_importers s
                            WHERE ins.hq_impr_nbr = imp.hq_impr_nbr AND s.hq_impr_nbr = ins.hq_impr_nbr
                              AND EXISTS (SELECT 1 FROM importers i
                                           WHERE ((i.impr_nbr = p_impr_nbr AND i.port_cd = p_port_cd) OR i.hq_impr_nbr = p_hq_impr_nbr)
                                             AND imp.bus_id = i.bus_id));
        EXCEPTION WHEN OTHERS THEN v_found := 0;
        END;
        IF v_found > 0 THEN RETURN v_found; END IF;
        -- XBUF7: accused in a customs case (type not 21), only for SELECT1 = 1
        BEGIN
            SELECT COUNT(1) INTO v_found FROM dual
             WHERE EXISTS (SELECT 1 FROM importers imp, case_accuseds ca, customs_cases cc
                            WHERE ca.port_cd = imp.port_cd AND ca.impr_nbr = imp.impr_nbr
                              AND accused_type = 1                 -- unqualified, as in Forms
                              AND ca.port_cd = cc.port_cd AND ca.case_seq = cc.case_seq AND ca.case_date = cc.case_date
                              AND case_type != 21                  -- unqualified, as in Forms
                              AND p_select1 = 1
                              AND EXISTS (SELECT 1 FROM importers i
                                           WHERE ((imp.impr_nbr = p_impr_nbr AND i.port_cd = p_port_cd) OR imp.hq_impr_nbr = p_hq_impr_nbr)
                                             AND imp.bus_id = i.bus_id));
        EXCEPTION WHEN OTHERS THEN v_found := 0;
        END;
        IF v_found > 0 THEN RETURN v_found; END IF;
        -- XBUF8: open control suspension (IMPR_CNTRL_SUSPNS)
        BEGIN
            SELECT COUNT(1) INTO v_found FROM dual
             WHERE EXISTS (SELECT 1 FROM importers imp, impr_cntrl_suspns is_1
                            WHERE is_1.hq_impr_nbr = imp.hq_impr_nbr
                              AND TO_CHAR(is_1.suspn_strt_dt, 'YYYY-MM-MI') <= TO_CHAR(p_xdt, 'YYYY-MM-MI')
                              AND TO_CHAR(is_1.suspn_end_dt, 'YYYY-MM-MI') >= TO_CHAR(p_xdt, 'YYYY-MM-MI')
                              AND is_1.suspn_rlse_dt IS NULL
                              AND EXISTS (SELECT 1 FROM importers i
                                           WHERE ((imp.impr_nbr = p_impr_nbr AND i.port_cd = p_port_cd) OR imp.hq_impr_nbr = p_hq_impr_nbr)
                                             AND imp.bus_id = i.bus_id));
        EXCEPTION WHEN OTHERS THEN v_found := 0;
        END;
        RETURN v_found;
    END count_susp1_common;

    -- COUNT_SUSP1 checks XBUF11 .. XBUF16 (P_CURR_PORT_CD != 99) and XBUF21 .. XBUF26 (P_CURR_PORT_CD = 99).
    -- The two groups differ only in the user's port rule and in XBUF16 / XBUF26 (see below); they run the same
    -- waiver / exclusion checks in the same order.
    FUNCTION count_susp1_waivers (p_impr_nbr IN NUMBER, p_port_cd IN NUMBER, p_hq_impr_nbr IN NUMBER,
                                  p_curr_port_cd IN NUMBER, p_xdt IN DATE)
       RETURN NUMBER
    IS
        v_found NUMBER := 0;
    BEGIN
        -- XBUF11 / XBUF21 (item type 1) and XBUF12 / XBUF22 (item type 2): expired waiver item issued after 1427-02-26
        FOR t IN (SELECT 1 item_type_cd FROM dual UNION ALL SELECT 2 FROM dual ORDER BY 1) LOOP
            BEGIN
                SELECT COUNT(1) INTO v_found FROM dual
                 WHERE EXISTS (SELECT 1 FROM importers imp, waivers wvr, wvr_items wi
                                WHERE wi.wvr_port_cd = wvr.wvr_port_cd AND wi.wvr_seq_nbr = wvr.wvr_seq_nbr
                                  AND wi.issued_dt = wvr.issued_dt AND wi.item_type_cd = t.item_type_cd
                                  AND wvr.wvr_status = 1
                                  AND wvr.wvr_port_cd = imp.port_cd (+) AND wvr.impr_nbr = imp.impr_nbr (+)
                                  AND (wi.item_status IS NULL OR wi.item_status = '0')
                                  AND TO_CHAR(wi.item_end_dt, 'YYYY-MM-MI') < TO_CHAR(p_xdt, 'YYYY-MM-MI')
                                  AND TO_CHAR(wi.item_issue_dt, 'YYYY-MM-MI') > '1427-02-26'
                                  AND EXISTS (SELECT 1 FROM importers i
                                               WHERE ((i.impr_nbr = p_impr_nbr AND i.port_cd = p_port_cd) OR i.hq_impr_nbr = p_hq_impr_nbr)
                                                 AND imp.bus_id = i.bus_id));
            EXCEPTION WHEN OTHERS THEN v_found := 0;
            END;
            IF v_found > 0 THEN RETURN v_found; END IF;
        END LOOP;
        -- XBUF13 / XBUF23: excluded importer, decree type 1
        BEGIN
            SELECT COUNT(1) INTO v_found FROM dual
             WHERE EXISTS (SELECT 1 FROM importers imp, importer_excludeds ex
                            WHERE imp.hq_impr_nbr = ex.hq_impr_nbr AND ex.dcre_type = 1
                              AND EXISTS (SELECT 1 FROM importers i
                                           WHERE ((i.impr_nbr = p_impr_nbr AND i.port_cd = p_port_cd) OR i.hq_impr_nbr = p_hq_impr_nbr)
                                             AND imp.bus_id = i.bus_id));
        EXCEPTION WHEN OTHERS THEN v_found := 0;
        END;
        IF v_found > 0 THEN RETURN v_found; END IF;
        -- XBUF14 / XBUF24: excluded importer, decree type 2 not expired (Forms alias DEC -> dcr)
        BEGIN
            SELECT COUNT(1) INTO v_found FROM dual
             WHERE EXISTS (SELECT 1 FROM importers imp, importer_excludeds ex, exclusion_decrees dcr
                            WHERE imp.hq_impr_nbr = ex.hq_impr_nbr AND ex.dcre_type = 2
                              AND ex.ed_dcre_nbr = dcr.dcre_nbr AND ex.ed_dcre_date = dcr.dcre_date
                              AND dcr.dcre_expr_date > TO_CHAR(p_xdt, 'YYYY-MM-MI')
                              AND EXISTS (SELECT 1 FROM importers i
                                           WHERE ((i.impr_nbr = p_impr_nbr AND i.port_cd = p_port_cd) OR i.hq_impr_nbr = p_hq_impr_nbr)
                                             AND imp.bus_id = i.bus_id));
        EXCEPTION WHEN OTHERS THEN v_found := 0;
        END;
        IF v_found > 0 THEN RETURN v_found; END IF;
        -- XBUF15 / XBUF25: expired waiver item type 9
        BEGIN
            SELECT COUNT(1) INTO v_found FROM dual
             WHERE EXISTS (SELECT 1 FROM importers imp, waivers wvr, wvr_items wi
                            WHERE wi.wvr_port_cd = wvr.wvr_port_cd AND wi.wvr_seq_nbr = wvr.wvr_seq_nbr
                              AND wi.issued_dt = wvr.issued_dt AND wi.item_type_cd = 9 AND wvr.wvr_status = 1
                              AND wvr.wvr_port_cd = imp.port_cd (+) AND wvr.impr_nbr = imp.impr_nbr (+)
                              AND (wi.item_status IS NULL OR wi.item_status = '0')
                              AND TO_CHAR(wi.item_end_dt, 'YYYY-MM-MI') < TO_CHAR(p_xdt, 'YYYY-MM-MI')
                              AND EXISTS (SELECT 1 FROM importers i
                                           WHERE ((i.impr_nbr = p_impr_nbr AND i.port_cd = p_port_cd) OR i.hq_impr_nbr = p_hq_impr_nbr)
                                             AND imp.bus_id = i.bus_id));
        EXCEPTION WHEN OTHERS THEN v_found := 0;
        END;
        IF v_found > 0 THEN RETURN v_found; END IF;
        -- item type 7 issued from 1430-02-01, status not 9
        BEGIN
            IF p_curr_port_cd != 99 THEN
                -- XBUF16 (port user): WVR_ITEMS_GLOBALS of the same business id
                SELECT COUNT(1) INTO v_found FROM dual
                 WHERE EXISTS (SELECT 1 FROM importers imp, wvr_items_globals wvr
                                WHERE wvr.wvr_port_cd = imp.port_cd (+) AND wvr.impr_nbr = imp.impr_nbr (+)
                                  AND wvr.item_type_cd = 7 AND wvr.bus_id = imp.bus_id
                                  AND (wvr.item_status <> 9 OR wvr.item_status IS NULL)
                                  AND TO_CHAR(wvr.item_issue_dt, 'RRRR-MM-MI') >= '1430-02-01'
                                  AND EXISTS (SELECT 1 FROM importers i
                                               WHERE ((i.impr_nbr = p_impr_nbr AND i.port_cd = p_port_cd) OR i.hq_impr_nbr = p_hq_impr_nbr)
                                                 AND imp.bus_id = i.bus_id));
            ELSE
                -- XBUF26 (head office): WAIVERS / WVR_ITEMS (no WVR_STATUS rule)
                SELECT COUNT(1) INTO v_found FROM dual
                 WHERE EXISTS (SELECT 1 FROM importers imp, waivers wvr, wvr_items wi
                                WHERE wi.wvr_port_cd = wvr.wvr_port_cd AND wi.wvr_seq_nbr = wvr.wvr_seq_nbr
                                  AND wi.issued_dt = wvr.issued_dt AND wi.item_type_cd = 7
                                  AND wvr.wvr_port_cd = imp.port_cd (+) AND wvr.impr_nbr = imp.impr_nbr (+)
                                  AND (wi.item_status <> 9 OR wi.item_status IS NULL)
                                  AND TO_CHAR(wi.item_issue_dt, 'YYYY-MM-MI') >= '1430-02-01'
                                  AND EXISTS (SELECT 1 FROM importers i
                                               WHERE ((i.impr_nbr = p_impr_nbr AND i.port_cd = p_port_cd) OR i.hq_impr_nbr = p_hq_impr_nbr)
                                                 AND imp.bus_id = i.bus_id));
            END IF;
        EXCEPTION WHEN OTHERS THEN v_found := 0;
        END;
        RETURN v_found;
    END count_susp1_waivers;

    -- Source: PU COUNT_SUSP1 (see the note above count_susp1_common)
    --   XDT := HIJDATE.Cur_Hij_Date; XBUF1 .. XBUF8; IF their sum = 0 THEN
    --     IF :PARAMETER.P_CURR_PORT_CD != 99 THEN XBUF11 .. XBUF16 ELSE XBUF21 .. XBUF26 END IF; END IF;
    --   RETURN the sum; EXCEPTION WHEN OTHERS THEN RETURN 0.
    -- (COUNT_SUSP1_OLD is an unused earlier copy: not converted.)
    FUNCTION COUNT_SUSP1 (p_impr_nbr IN NUMBER, p_port_cd IN NUMBER, p_hq_impr_nbr IN NUMBER,
                          p_select1  IN NUMBER, p_curr_port_cd IN NUMBER)
       RETURN NUMBER
    IS
        v_xdt   DATE := FORMS_APX.CUR_HIJ_DATE;
        v_count NUMBER;
    BEGIN
        v_count := count_susp1_common(p_impr_nbr, p_port_cd, p_hq_impr_nbr, p_select1, v_xdt);
        IF v_count = 0 THEN
            v_count := count_susp1_waivers(p_impr_nbr, p_port_cd, p_hq_impr_nbr, p_curr_port_cd, v_xdt);
        END IF;
        RETURN NVL(v_count, 0);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 0;
    END COUNT_SUSP1;

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
    --   :SELECT1 := 1;
    --   IF :PARAMETER.P_CURR_PORT_CD != 99 THEN
    --      SELECT PORT_NAME INTO :P_CURR_PORT_NAME FROM SD_PORTS WHERE PORT_CD = :PARAMETER.P_CURR_PORT_CD;
    --      :P_PORT_CD := :PARAMETER.P_CURR_PORT_CD;
    --   ELSE :P_CURR_PORT_NAME := NULL; END IF;
    --   (title / date / window / logo lines -> f345 shell; SELECT1 -> item default; P_PORT_CD -> effective_port)
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

    -- Source: PU ENB_DISP_FLDS, branch :PARAMETER.P_CURR_PORT_CD != 99 (see the spec)
    FUNCTION P_PORT_CD_IS_VISIBLE (P_CURR_PORT_CD IN VARCHAR2)
       RETURN BOOLEAN
    IS
    BEGIN
        RETURN NVL(P_CURR_PORT_CD, c_all_ports) = c_all_ports;
    END P_PORT_CD_IS_VISIBLE;

    -- =========================================================================
    -- BLOCK CALLING_PARAMETERS
    -- =========================================================================

    -- Source: CALLING_PARAMETERS.SELECT1 (Radio Group; see the spec)
    FUNCTION SELECT1_VALIDATION (P_SELECT1 IN VARCHAR2)
       RETURN VARCHAR2
    IS
    BEGIN
        IF P_SELECT1 IN (c_select_port, c_select_unified) THEN
            RETURN NULL;
        END IF;
        RETURN FORMS_APX.REQUIRED_VALIDATION(ITEM_VALUE => NULL, ITEM_LABEL => c_label_select1);
    END SELECT1_VALIDATION;

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

    -- Source: CALLING_PARAMETERS.IMPR_NBR.WHEN-VALIDATE-ITEM (see the spec)
    -- SUGGESTION: Forms opened the LOV on TOO_MANY_ROWS (the number in several ports, no port chosen); here the first
    --   name (MIN) is shown. Forms cleared IMPR_NBR without a message when no importer matched; kept.
    PROCEDURE IMPR_NBR_WHEN_VALIDATE_ITEM (P_IMPR_NBR       IN OUT VARCHAR2,
                                           P_PORT_CD        IN     VARCHAR2,
                                           P_CURR_PORT_CD   IN     VARCHAR2,
                                           P_IMPR_NAME      OUT    VARCHAR2)
    IS
        v_impr_nbr NUMBER := number_or_null(P_IMPR_NBR);
        v_port_cd  NUMBER := number_or_null(effective_port(P_PORT_CD, P_CURR_PORT_CD));
        v_count    NUMBER;
    BEGIN
        P_IMPR_NAME := NULL;
        IF TRIM(P_IMPR_NBR) IS NULL THEN
            RETURN;
        END IF;
        SELECT MIN(i.arbc_impr_name), COUNT(*)
          INTO IMPR_NBR_WHEN_VALIDATE_ITEM.P_IMPR_NAME, v_count
          FROM importers i
         WHERE (i.port_cd = v_port_cd OR v_port_cd IS NULL)
           AND i.impr_nbr = v_impr_nbr;
        IF v_count = 0 THEN                         -- WHEN OTHERS (NO_DATA_FOUND, not a number): :IMPR_NBR := NULL
            P_IMPR_NBR := NULL;
        END IF;
    END IMPR_NBR_WHEN_VALIDATE_ITEM;

    -- Source: CALLING_PARAMETERS.HQ_IMPR_NBR.WHEN-VALIDATE-ITEM + PU GET_HQ_IMPR_NAME (see the spec)
    -- SUGGESTION: GET_HQ_IMPR_NAME wrote the IMPORTERS name into :IMPR_NAME (the field of the other choice, cleared and
    --   disabled for SELECT1 = 2); here it goes to HQ_IMPR_NAME, next to the number. TOO_MANY_ROWS opened the LOV in Forms;
    --   here the first name (MIN) is shown. An unknown number is accepted without a message, as in Forms.
    PROCEDURE HQ_IMPR_NBR_WHEN_VALIDATE_ITEM (P_HQ_IMPR_NBR  IN  VARCHAR2,
                                              P_HQ_IMPR_NAME OUT VARCHAR2)
    IS
        v_hq_impr_nbr NUMBER := number_or_null(P_HQ_IMPR_NBR);
        v_count       NUMBER;
    BEGIN
        P_HQ_IMPR_NAME := NULL;
        IF v_hq_impr_nbr IS NULL THEN
            RETURN;
        END IF;
        SELECT MIN(s.arbc_impr_name), COUNT(*)
          INTO HQ_IMPR_NBR_WHEN_VALIDATE_ITEM.P_HQ_IMPR_NAME, v_count
          FROM single_importers s
         WHERE s.hq_impr_nbr = v_hq_impr_nbr;
        IF v_count = 0 THEN                            -- NO_DATA_FOUND -> WHEN OTHERS THEN GET_HQ_IMPR_NAME
            SELECT MIN(i.arbc_impr_name)
              INTO HQ_IMPR_NBR_WHEN_VALIDATE_ITEM.P_HQ_IMPR_NAME
              FROM importers i
             WHERE i.hq_impr_nbr = v_hq_impr_nbr;
        END IF;
    END HQ_IMPR_NBR_WHEN_VALIDATE_ITEM;

    -- =========================================================================
    -- BLOCK TOOLBAR
    -- =========================================================================

    -- Source: PU PRINT_CHECK_VAL (ITEM303 «طباعة», KEY-F5) and PU CHECK_VAL (ITEM304 «عرض», KEY-F4) - see the spec.
    -- The item checks run again here (the DAs may not have run).
    -- SUGGESTION: the port is required for SELECT1 = 1 (new check). In Forms an empty port made every importer
    --   condition false, so COUNT_SUSP1 returned 0 and the form wrongly said «حالة المستورد سليمة».
    PROCEDURE PRINT_CHECK_VAL (P_SELECT1        IN  VARCHAR2,
                               P_PORT_CD        IN  VARCHAR2,
                               P_IMPR_NBR       IN  VARCHAR2,
                               P_HQ_IMPR_NBR    IN  VARCHAR2,
                               P_REPORT_NO      IN  VARCHAR2,
                               P_HERO_TITLE     IN  VARCHAR2,
                               P_CURR_PORT_CD   IN  VARCHAR2,
                               P_REPORT_URL     OUT VARCHAR2)
    IS
        v_select1     VARCHAR2(1) := P_SELECT1;
        v_port_cd     NUMBER;
        v_impr_nbr    NUMBER;
        v_hq_impr_nbr NUMBER;
    BEGIN
        IF NVL(P_CURR_PORT_CD, c_all_ports) <> c_all_ports THEN
            v_select1 := c_select_port;                -- ENB_DISP_FLDS: :SELECT1 := 1 outside head office
        END IF;
        FORMS_APX.CHECK_ERROR(SELECT1_VALIDATION(P_SELECT1 => v_select1));
        IF v_select1 = c_select_port THEN              -- ENB_DISP_FLDS clears HQ_IMPR_NBR
            v_impr_nbr := number_or_null(P_IMPR_NBR);
            IF v_impr_nbr IS NULL THEN
                FORMS_APX.CHECK_ERROR(c_msg_importer);
            END IF;
            FORMS_APX.CHECK_ERROR(FORMS_APX.REQUIRED_VALIDATION(ITEM_VALUE => effective_port(P_PORT_CD, P_CURR_PORT_CD),
                                                                ITEM_LABEL => c_label_port));
            FORMS_APX.CHECK_ERROR(P_PORT_CD_VALIDATION(P_PORT_CD => effective_port(P_PORT_CD, P_CURR_PORT_CD)));
            v_port_cd  := number_or_null(effective_port(P_PORT_CD, P_CURR_PORT_CD));
        ELSE                                           -- ENB_DISP_FLDS clears P_PORT_CD and IMPR_NBR
            v_hq_impr_nbr := number_or_null(P_HQ_IMPR_NBR);
            IF v_hq_impr_nbr IS NULL THEN
                FORMS_APX.CHECK_ERROR(c_msg_unified);
            END IF;
        END IF;
        IF COUNT_SUSP1(v_impr_nbr, v_port_cd, v_hq_impr_nbr, TO_NUMBER(v_select1),
                       number_or_null(NVL(P_CURR_PORT_CD, c_all_ports))) = 0 THEN
            FORMS_APX.CHECK_ERROR(c_msg_no_suspension);
        END IF;
        P_REPORT_URL := PRINT_IMPR2170_ARD(p_curr_port_cd => P_CURR_PORT_CD,
                                           p_pport_cd     => TO_CHAR(v_port_cd),
                                           p_pselect1     => v_select1,
                                           p_pimpr_nbr    => TO_CHAR(v_impr_nbr),
                                           p_phq_impr_nbr => TO_CHAR(v_hq_impr_nbr),
                                           p_module_name  => P_HERO_TITLE,
                                           p_report_no    => P_REPORT_NO);
    END PRINT_CHECK_VAL;

    -- =========================================================================
    -- PROGRAM UNITS
    -- =========================================================================

    -- Source: REP.Run_Product(REPORTS, V_REPORT_FILE, SYNCHRONOUS, RUNTIME, FILESYSTEM, pl_id, NULL)
    -- Pattern: PRINT_<FORM>_ARD of the approved standard 13-b / 13-c (as PRINT_IMPR2150_ARD); no server link in the
    -- code: ARD_URL and ARD_DSNAME are settings (SC_PORT_SETTING, SYSOBJ_ID 999, PORT_CD 99 -
    -- migration/001_ard_settings.sql); a missing setting stops with a message.
    FUNCTION PRINT_IMPR2170_ARD (p_curr_port_cd IN VARCHAR2,
                                 p_pport_cd     IN VARCHAR2,
                                 p_pselect1     IN VARCHAR2,
                                 p_pimpr_nbr    IN VARCHAR2,
                                 p_phq_impr_nbr IN VARCHAR2,
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
               || ard_parameter(2, p_pport_cd)
               || ard_parameter(3, p_pselect1)
               || ard_parameter(4, p_pimpr_nbr)
               || ard_parameter(5, p_phq_impr_nbr)
               || ard_parameter(6, p_module_name)
               || ard_parameter(7, p_report_no)
               || CHR(38) || 'DsName=' || UTL_URL.ESCAPE(v_dsname, TRUE, 'UTF-8');
    END PRINT_IMPR2170_ARD;

END IMPR2170;
/
SHOW ERRORS
