-- =============================================================================
-- Package body: IMPR1130 (version 001, 24-11-2026) - see the spec header. NOT COMPILED.
-- Layout      : 1 private constants, 2 private helpers (messages, activity log, lookups, rules),
--               3 converted Forms logic (private, one member per trigger / program unit, Forms UI calls kept
--               as "-- APEX-DA:" comments), 4 APEX entry points (spec order), 5 version.
-- Built       : by work/IMPR1130/step02/build_body.py from work/IMPR1130/step02/impr1130_body.src.sql and the
--               generated work/IMPR1130/step02/delete_check.sql (edit the source, then rebuild).
-- Forms code  : the original trigger text is quoted in analysis/IMPR1130/IMPR1130_inventory.md section 6 / 9;
--               every member names its source. Members marked "= IMPR1110" follow the IMPR1110 package 013.
-- =============================================================================
SET DEFINE OFF

CREATE OR REPLACE PACKAGE BODY LIB_APX_USR.IMPR1130
AS

    -- =========================================================================
    -- 1 PRIVATE CONSTANTS
    -- =========================================================================
    c_date_time_mask CONSTANT VARCHAR2(30) := 'YYYY/MM/DD HH24:MI:SS';   -- Forms PLSQL_DATE_FORMAT (PRE-FORM), LST_TRAN_DT
    c_service_mask   CONSTANT VARCHAR2(10) := 'MI-MM-YYYY';   -- date text of the web service and of CREATE_UNI_IMPR_NEBRAS (DB contract)
    c_functions      CONSTANT VARCHAR2(100) := 'IMPR_MCI_SERVICE';   -- functions switched by ADJ_FUNS

    -- =========================================================================
    -- 2 PRIVATE HELPERS
    -- =========================================================================

    FUNCTION new_record (p_row_id IN VARCHAR2) RETURN BOOLEAN
    IS
    BEGIN
        RETURN p_row_id IS NULL;               -- Forms :SYSTEM.RECORD_STATUS NEW / INSERT (key mode ROWID)
    END new_record;

    FUNCTION flag (p_on IN BOOLEAN) RETURN VARCHAR2
    IS
    BEGIN
        RETURN CASE WHEN p_on THEN 'Y' ELSE 'N' END;
    END flag;

    -- Hijri DATE item (text in FORMS_APX.HIJRI_DATE_FORMAT) -> DATE
    FUNCTION hijri (p_text IN VARCHAR2) RETURN DATE
    IS
    BEGIN
        RETURN FORMS_APX.HIJRI_TEXT_TO_DATE(p_text);
    END hijri;

    -- = IMPR1110 strip_constraint (CGTE$STRIP_CONSTRAINT, OFGTEL: MISSING SOURCE): owner.name from "(owner.name)"
    FUNCTION strip_constraint (p_msg IN VARCHAR2) RETURN VARCHAR2
    IS
        v VARCHAR2(200);
    BEGIN
        v := REGEXP_SUBSTR(p_msg, '\(([^)]+)\)', 1, 1, NULL, 1);
        RETURN SUBSTR(v, INSTR(v, '.') + 1);
    END strip_constraint;

    -- Des$Form_errors.MSGGETTEXT(5, 'Cannot delete <p1> while dependent <p2> exists', p1, p2)
    -- (FORMS_APX.CG_MESSAGE replaces <p1>; <p2> is replaced here). TODO: verify the Arabic text of message 5.
    FUNCTION delete_message (p1 IN VARCHAR2, p2 IN VARCHAR2) RETURN VARCHAR2
    IS
    BEGIN
        RETURN REPLACE(FORMS_APX.CG_MESSAGE('Cannot delete <p1> while dependent <p2> exists', p1), '<p2>', p2);
    END delete_message;

    -- Source: PU CGRI$CHK_IMPORTERS (Designer referential check, called by IMPORTERS.KEY-DELREC with
    -- P_CHECK_BOTH TRUE and by IMPORTERS.PRE-DELETE with FALSE; the flag is not read by the code).
    -- Returns the Forms message of the first dependent table that still has rows, NULL when the delete
    -- is allowed. Generated from the Forms text by work/IMPR1130/step02/gen_delete_check.py (36 checks,
    -- same order). Des$Form_errors.PUSH + RAISE_FAILURE -> the caller raises the returned text.
    FUNCTION CGRI$CHK_IMPORTERS (p_impr_nbr IN NUMBER, p_port_cd IN NUMBER) RETURN VARCHAR2
    IS
        v_found NUMBER;
    BEGIN
        -- AGNTS (AG_IMP_AGENT_ID_FK)
        SELECT COUNT(*) INTO v_found FROM agnts ag
         WHERE AG.IMPR_NBR_AGENT_ID = p_impr_nbr AND AG.PORT_CD = p_port_cd
           AND ROWNUM = 1;
        IF v_found > 0 THEN
            RETURN delete_message('IMPORTERS', 'AGNTS');
        END IF;
        -- AGNTS (AG_IMP_FK)
        SELECT COUNT(*) INTO v_found FROM agnts ag
         WHERE AG.IMPR_NBR = p_impr_nbr AND AG.PORT_CD = p_port_cd
           AND ROWNUM = 1;
        IF v_found > 0 THEN
            RETURN delete_message('IMPORTERS', 'AGNTS');
        END IF;
        -- PASSENGER_TRIPS (PT_IMP_FK)
        SELECT COUNT(*) INTO v_found FROM passenger_trips ptr
         WHERE (PTR.IMPR_NBR = p_impr_nbr OR (PTR.IMPR_NBR IS NULL AND p_impr_nbr IS NULL )) AND PTR.PORT_CD = p_port_cd
           AND ROWNUM = 1;
        IF v_found > 0 THEN
            RETURN delete_message('جدول المستوردين', 'جدول  رحلات الركاب');
        END IF;
        -- DELAY_AIR_DLVY_ORDERS (DA_IMP_FK)
        SELECT COUNT(*) INTO v_found FROM delay_air_dlvy_orders da
         WHERE (DA.IMPR_NBR = p_impr_nbr OR (DA.IMPR_NBR IS NULL AND p_impr_nbr IS NULL )) AND DA.PORT_CD = p_port_cd
           AND ROWNUM = 1;
        IF v_found > 0 THEN
            RETURN delete_message('IMPORTERS', 'DELAY_AIR_DLVY_ORDERS');
        END IF;
        -- IMPR_SUSPNS (IS_1_IMP_FK)
        SELECT COUNT(*) INTO v_found FROM impr_suspns is_1
         WHERE IS_1.PORT_CD = p_port_cd AND IS_1.IMPR_NBR = p_impr_nbr
           AND ROWNUM = 1;
        IF v_found > 0 THEN
            RETURN delete_message('جدول المستوردين', 'توقيفات المستوردين');
        END IF;
        -- BL_OWNER_HIST (BLOH_IMP_FK)
        SELECT COUNT(*) INTO v_found FROM bl_owner_hist bloh
         WHERE BLOH.PORT_CD = p_port_cd AND (BLOH.IMPR_NBR = p_impr_nbr OR (BLOH.IMPR_NBR IS NULL AND p_impr_nbr IS NULL ))
           AND ROWNUM = 1;
        IF v_found > 0 THEN
            RETURN delete_message('جدول المستوردين', 'Bl Owner Hist');
        END IF;
        -- REV_SECTIONS_CASH_DTLS (RCDS_IMP_FK)
        SELECT COUNT(*) INTO v_found FROM rev_sections_cash_dtls rsdc
         WHERE RSDC.PORT_CD = p_port_cd AND (RSDC.IMPR_NBR = p_impr_nbr OR (RSDC.IMPR_NBR IS NULL AND p_impr_nbr IS NULL ))
           AND ROWNUM = 1;
        IF v_found > 0 THEN
            RETURN delete_message('IMPORTERS', 'REV_SECTIONS_CASH_DTLS');
        END IF;
        -- SEA_DLVY_ORDERS (SDO_IMP_FK)
        SELECT COUNT(*) INTO v_found FROM sea_dlvy_orders sdo
         WHERE (SDO.IMPR_NBR = p_impr_nbr OR (SDO.IMPR_NBR IS NULL AND p_impr_nbr IS NULL )) AND SDO.PORT_CD = p_port_cd
           AND ROWNUM = 1;
        IF v_found > 0 THEN
            RETURN delete_message('جدول المستوردين', 'اذن التسليم');
        END IF;
        -- IMPR_KNWNS (IK_IMP_FK)
        SELECT COUNT(*) INTO v_found FROM impr_knwns ik
         WHERE IK.PORT_CD = p_port_cd AND IK.IMPR_NBR = p_impr_nbr
           AND ROWNUM = 1;
        IF v_found > 0 THEN
            RETURN delete_message('جدول المستوردين', 'الكلمات المميزه');
        END IF;
        -- BRKR_UPDTS (BU_IMP_FK)
        SELECT COUNT(*) INTO v_found FROM brkr_updts bu
         WHERE (BU.IMPR_NBR = p_impr_nbr OR (BU.IMPR_NBR IS NULL AND p_impr_nbr IS NULL )) AND BU.PORT_CD = p_port_cd
           AND ROWNUM = 1;
        IF v_found > 0 THEN
            RETURN delete_message('جدول المستوردين', 'ملف الأنشطة للمخلصين');
        END IF;
        -- BA_OWNERSHIPS (BOW_IMP_FK)
        SELECT COUNT(*) INTO v_found FROM ba_ownerships bow
         WHERE (BOW.IMPR_NBR = p_impr_nbr OR (BOW.IMPR_NBR IS NULL AND p_impr_nbr IS NULL )) AND BOW.PORT_CD = p_port_cd
           AND ROWNUM = 1;
        IF v_found > 0 THEN
            RETURN delete_message('IMPORTERS', 'BA_OWNERSHIPS');
        END IF;
        -- BRKR_MSTR (BKM_IMP_FK)
        SELECT COUNT(*) INTO v_found FROM brkr_mstr bkm
         WHERE BKM.IMPR_NBR = p_impr_nbr AND BKM.PORT_CD = p_port_cd
           AND ROWNUM = 1;
        IF v_found > 0 THEN
            RETURN delete_message('جدول المستوردين', 'المخلصين');
        END IF;
        -- EXMTN_DECREES (XD_IMP_FK)
        SELECT COUNT(*) INTO v_found FROM exmtn_decrees xd
         WHERE (XD.IMP_IMPR_NBR = p_impr_nbr OR (XD.IMP_IMPR_NBR IS NULL AND p_impr_nbr IS NULL )) AND (XD.IMP_PORT_CD = p_port_cd OR (XD.IMP_PORT_CD IS NULL AND p_port_cd IS NULL ))
           AND ROWNUM = 1;
        IF v_found > 0 THEN
            RETURN delete_message('جدول المستوردين', 'قرارات الإعفاء');
        END IF;
        -- IMPR_UPDTS (IU_IMP_FK)
        SELECT COUNT(*) INTO v_found FROM impr_updts iu
         WHERE IU.PORT_CD = p_port_cd AND IU.IMPR_NBR = p_impr_nbr
           AND ROWNUM = 1;
        IF v_found > 0 THEN
            RETURN delete_message('جدول المستوردين', 'تعديلات المستوردين');
        END IF;
        -- LFT_SALES (LS_IMP_FK)
        SELECT COUNT(*) INTO v_found FROM lft_sales ls
         WHERE (LS.IMPR_NBR = p_impr_nbr OR (LS.IMPR_NBR IS NULL AND p_impr_nbr IS NULL )) AND LS.PORT_CD = p_port_cd
           AND ROWNUM = 1;
        IF v_found > 0 THEN
            RETURN delete_message('IMPORTERS', 'LFT_SALES');
        END IF;
        -- DPLMTC_APLCTNS (DAP_IMP_FK)
        SELECT COUNT(*) INTO v_found FROM dplmtc_aplctns dap
         WHERE (DAP.IMP_IMPR_NBR = p_impr_nbr OR (DAP.IMP_IMPR_NBR IS NULL AND p_impr_nbr IS NULL )) AND (DAP.IMP_PORT_CD = p_port_cd OR (DAP.IMP_PORT_CD IS NULL AND p_port_cd IS NULL ))
           AND ROWNUM = 1;
        IF v_found > 0 THEN
            RETURN delete_message('IMPORTERS', 'DPLMTC_APLCTNS');
        END IF;
        -- CSTMS_CLNTS (CSTMS_CLNT_IMP_FK)
        SELECT COUNT(*) INTO v_found FROM cstms_clnts cstms_clnt
         WHERE (CSTMS_CLNT.IMP_IMPR_NBR = p_impr_nbr OR (CSTMS_CLNT.IMP_IMPR_NBR IS NULL AND p_impr_nbr IS NULL )) AND (CSTMS_CLNT.IMP_PORT_CD = p_port_cd OR (CSTMS_CLNT.IMP_PORT_CD IS NULL AND p_port_cd IS NULL ))
           AND ROWNUM = 1;
        IF v_found > 0 THEN
            RETURN delete_message('جدول المستوردين', 'Cstms Clnts');
        END IF;
        -- VHCL_AUCTION (VAU_IMP_FK)
        SELECT COUNT(*) INTO v_found FROM vhcl_auction vau
         WHERE VAU.PORT_CD = p_port_cd AND VAU.IMPR_NBR = p_impr_nbr
           AND ROWNUM = 1;
        IF v_found > 0 THEN
            RETURN delete_message('جدول المستوردين', 'ملف مزادات السيارات');
        END IF;
        -- BRKIMPS (BI_IMP_FK)
        SELECT COUNT(*) INTO v_found FROM brkimps bi
         WHERE BI.PORT_CD = p_port_cd AND BI.IMPR_NBR = p_impr_nbr
           AND ROWNUM = 1;
        IF v_found > 0 THEN
            RETURN delete_message('جدول المستوردين', 'تفاويض المخلصين');
        END IF;
        -- SMPL_20_DECLERATIONS (S2D_IMP_FK)
        SELECT COUNT(*) INTO v_found FROM smpl_20_declerations s2d
         WHERE S2D.IMPR_NBR = p_impr_nbr AND S2D.PORT_CD = p_port_cd
           AND ROWNUM = 1;
        IF v_found > 0 THEN
            RETURN delete_message('IMPORTERS', 'SMPL_20_DECLERATIONS');
        END IF;
        -- DECLARATIONS (DCLTN_MNFCT_IMPR_FK)
        SELECT COUNT(*) INTO v_found FROM declarations dcltn
         WHERE DCLTN.PORT_CD = p_port_cd AND (DCLTN.MNFCT_NBR = p_impr_nbr OR (DCLTN.MNFCT_NBR IS NULL AND p_impr_nbr IS NULL ))
           AND ROWNUM = 1;
        IF v_found > 0 THEN
            RETURN delete_message('IMPORTERS', 'DECLARATIONS');
        END IF;
        -- CLIENT_PAY_ACCTS (CPAS_IMP_FK)
        SELECT COUNT(*) INTO v_found FROM client_pay_accts cpas
         WHERE (CPAS.IMPR_NBR = p_impr_nbr OR (CPAS.IMPR_NBR IS NULL AND p_impr_nbr IS NULL )) AND CPAS.PORT_CD = p_port_cd
           AND ROWNUM = 1;
        IF v_found > 0 THEN
            RETURN delete_message('جدول المستوردين', 'Client pay accts');
        END IF;
        -- DCLTN_DOCS (DCL_DOC_IMP_FK)
        SELECT COUNT(*) INTO v_found FROM dcltn_docs dcl_doc
         WHERE (DCL_DOC.CARRIER_NBR = p_impr_nbr OR (DCL_DOC.CARRIER_NBR IS NULL AND p_impr_nbr IS NULL )) AND DCL_DOC.PORT_CD = p_port_cd
           AND ROWNUM = 1;
        IF v_found > 0 THEN
            RETURN delete_message('جدول المستوردين', 'مرفقات البيان');
        END IF;
        -- DECLARATIONS (DCLTN_IMP_FK)
        SELECT COUNT(*) INTO v_found FROM declarations dcltn
         WHERE DCLTN.PORT_CD = p_port_cd AND (DCLTN.IMPR_NBR = p_impr_nbr OR (DCLTN.IMPR_NBR IS NULL AND p_impr_nbr IS NULL ))
           AND ROWNUM = 1;
        IF v_found > 0 THEN
            RETURN delete_message('IMPORTERS', 'DECLARATIONS');
        END IF;
        -- DELAY_SEA_DLVY_ORDERS (DSD_IMP_FK)
        SELECT COUNT(*) INTO v_found FROM delay_sea_dlvy_orders dsd
         WHERE (DSD.IMPR_NBR = p_impr_nbr OR (DSD.IMPR_NBR IS NULL AND p_impr_nbr IS NULL )) AND DSD.PORT_CD = p_port_cd
           AND ROWNUM = 1;
        IF v_found > 0 THEN
            RETURN delete_message('جدول المستوردين', 'اذن التسليم');
        END IF;
        -- CREDIT_LETTERS (CL_IMP_FK)
        SELECT COUNT(*) INTO v_found FROM credit_letters cl
         WHERE CL.PORT_CD = p_port_cd AND (CL.IMPR_NBR = p_impr_nbr OR (CL.IMPR_NBR IS NULL AND p_impr_nbr IS NULL ))
           AND ROWNUM = 1;
        IF v_found > 0 THEN
            RETURN delete_message('جدول المستوردين', 'Credit Letters');
        END IF;
        -- MISSING_DCLTNS (MD_IMP_FK)
        SELECT COUNT(*) INTO v_found FROM missing_dcltns md
         WHERE MD.IMPR_NBR = p_impr_nbr AND MD.DCLTN_PORT_CD = p_port_cd
           AND ROWNUM = 1;
        IF v_found > 0 THEN
            RETURN delete_message('IMPORTERS', 'MISSING_DCLTNS');
        END IF;
        -- DECLARATIONS (DCLTN_AGNT_IMPR_FK)
        SELECT COUNT(*) INTO v_found FROM declarations dcltn
         WHERE DCLTN.PORT_CD = p_port_cd AND DCLTN.AGENT_NBR = p_impr_nbr
           AND ROWNUM = 1;
        IF v_found > 0 THEN
            RETURN delete_message('IMPORTERS', 'DECLARATIONS');
        END IF;
        -- WAIVERS (WVR_IMP_FK)
        SELECT COUNT(*) INTO v_found FROM waivers wvr
         WHERE (WVR.IMPR_NBR = p_impr_nbr OR (WVR.IMPR_NBR IS NULL AND p_impr_nbr IS NULL )) AND WVR.WVR_PORT_CD = p_port_cd
           AND ROWNUM = 1;
        IF v_found > 0 THEN
            RETURN delete_message('جدول المستوردين', 'التعهدات');
        END IF;
        -- EXMTN_A_FORMS (AFRM_IMP_FK)
        SELECT COUNT(*) INTO v_found FROM exmtn_a_forms afrm
         WHERE AFRM.PORT_CD = p_port_cd AND AFRM.IMPR_NBR = p_impr_nbr
           AND ROWNUM = 1;
        IF v_found > 0 THEN
            RETURN delete_message('IMPORTERS', 'EXMTN_A_FORMS');
        END IF;
        -- ELIMINATE_REQUESTS (ER_IMP_FK)
        SELECT COUNT(*) INTO v_found FROM eliminate_requests er
         WHERE (ER.IMPR_PORT_CD = p_port_cd OR (ER.IMPR_PORT_CD IS NULL AND p_port_cd IS NULL )) AND (ER.IMPR_NBR = p_impr_nbr OR (ER.IMPR_NBR IS NULL AND p_impr_nbr IS NULL ))
           AND ROWNUM = 1;
        IF v_found > 0 THEN
            RETURN delete_message('IMPORTERS', 'ELIMINATE_REQUESTS');
        END IF;
        -- SANDY_EXPORTS (SE_IMP_FK)
        SELECT COUNT(*) INTO v_found FROM sandy_exports se
         WHERE SE.PORT_CD = p_port_cd AND SE.EXPR_NBR = p_impr_nbr
           AND ROWNUM = 1;
        IF v_found > 0 THEN
            RETURN delete_message('جدول المستوردين', 'Sandy Exports');
        END IF;
        -- VHCL_CAR_EXPTON (VCE_IMP_FK)
        SELECT COUNT(*) INTO v_found FROM vhcl_car_expton vce
         WHERE VCE.IMPR_NBR = p_impr_nbr AND VCE.PORT_CD = p_port_cd
           AND ROWNUM = 1;
        IF v_found > 0 THEN
            RETURN delete_message('جدول المستوردين', 'ملف استثناء السيارات');
        END IF;
        -- BL_OWNERS (BO_IMP_FK)
        SELECT COUNT(*) INTO v_found FROM bl_owners bo
         WHERE BO.PORT_CD = p_port_cd AND (BO.IMPR_NBR = p_impr_nbr OR (BO.IMPR_NBR IS NULL AND p_impr_nbr IS NULL ))
           AND ROWNUM = 1;
        IF v_found > 0 THEN
            RETURN delete_message('جدول المستوردين', 'مالك البوليصة');
        END IF;
        -- BA_WAREHOUSES (BW_IMP_FK)
        SELECT COUNT(*) INTO v_found FROM ba_warehouses bw
         WHERE (BW.IMPR_NBR = p_impr_nbr OR (BW.IMPR_NBR IS NULL AND p_impr_nbr IS NULL )) AND BW.PORT_CD = p_port_cd
           AND ROWNUM = 1;
        IF v_found > 0 THEN
            RETURN delete_message('IMPORTERS', 'BA_WAREHOUSES');
        END IF;
        -- MASS_DUTY_DEF_STLMNTS (MDDS_IMP_FK)
        SELECT COUNT(*) INTO v_found FROM mass_duty_def_stlmnts mdds
         WHERE MDDS.IMPR_NBR = p_impr_nbr AND MDDS.IMP_PORT_CD = p_port_cd
           AND ROWNUM = 1;
        IF v_found > 0 THEN
            RETURN delete_message('IMPORTERS', 'MASS_DUTY_DEF_STLMNTS');
        END IF;
        RETURN NULL;
    END CGRI$CHK_IMPORTERS;

    -- Source: IMPORTERS.ON-ERROR, branch FRM-40510 (ORA-02292 child record found on DELETE):
    -- constraint name -> Forms message (32 constraints). Generated by gen_delete_check.py.
    FUNCTION delete_constraint_message (p_constraint IN VARCHAR2) RETURN VARCHAR2
    IS
    BEGIN
        RETURN CASE p_constraint
                   WHEN 'AG_IMP_AGENT_ID_FK' THEN delete_message('IMPORTERS', 'AGNTS')
                   WHEN 'AG_IMP_FK' THEN delete_message('IMPORTERS', 'AGNTS')
                   WHEN 'DA_IMP_FK' THEN delete_message('IMPORTERS', 'DELAY_AIR_DLVY_ORDERS')
                   WHEN 'IS_1_IMP_FK' THEN delete_message('جدول المستوردين', 'توقيفات المستوردين')
                   WHEN 'BLOH_IMP_FK' THEN delete_message('جدول المستوردين', 'Bl Owner Hist')
                   WHEN 'RCDS_IMP_FK' THEN delete_message('IMPORTERS', 'REV_SECTIONS_CASH_DTLS')
                   WHEN 'SDO_IMP_FK' THEN delete_message('جدول المستوردين', 'اذن التسليم')
                   WHEN 'IK_IMP_FK' THEN delete_message('جدول المستوردين', 'الكلمات المميزه')
                   WHEN 'BU_IMP_FK' THEN delete_message('جدول المستوردين', 'ملف الأنشطة للمخلصين')
                   WHEN 'BOW_IMP_FK' THEN delete_message('IMPORTERS', 'BA_OWNERSHIPS')
                   WHEN 'BKM_IMP_FK' THEN delete_message('جدول المستوردين', 'المخلصين')
                   WHEN 'XD_IMP_FK' THEN delete_message('جدول المستوردين', 'قرارات الإعفاء')
                   WHEN 'LS_IMP_FK' THEN delete_message('IMPORTERS', 'LFT_SALES')
                   WHEN 'DAP_IMP_FK' THEN delete_message('IMPORTERS', 'DPLMTC_APLCTNS')
                   WHEN 'CSTMS_CLNT_IMP_FK' THEN delete_message('جدول المستوردين', 'Cstms Clnts')
                   WHEN 'BI_IMP_FK' THEN delete_message('جدول المستوردين', 'تفاويض المخلصين')
                   WHEN 'S2D_IMP_FK' THEN delete_message('IMPORTERS', 'SMPL_20_DECLERATIONS')
                   WHEN 'DCLTN_MNFCT_IMPR_FK' THEN delete_message('IMPORTERS', 'DECLARATIONS')
                   WHEN 'CPAS_IMP_FK' THEN delete_message('جدول المستوردين', 'Client pay accts')
                   WHEN 'DCL_DOC_IMP_FK' THEN delete_message('جدول المستوردين', 'مرفقات البيان')
                   WHEN 'DCLTN_IMP_FK' THEN delete_message('IMPORTERS', 'DECLARATIONS')
                   WHEN 'DSD_IMP_FK' THEN delete_message('جدول المستوردين', 'اذن التسليم')
                   WHEN 'CL_IMP_FK' THEN delete_message('جدول المستوردين', 'Credit Letters')
                   WHEN 'MD_IMP_FK' THEN delete_message('IMPORTERS', 'MISSING_DCLTNS')
                   WHEN 'DCLTN_AGNT_IMPR_FK' THEN delete_message('IMPORTERS', 'DECLARATIONS')
                   WHEN 'WVR_IMP_FK' THEN delete_message('جدول المستوردين', 'التعهدات')
                   WHEN 'AFRM_IMP_FK' THEN delete_message('IMPORTERS', 'EXMTN_A_FORMS')
                   WHEN 'ER_IMP_FK' THEN delete_message('IMPORTERS', 'ELIMINATE_REQUESTS')
                   WHEN 'SE_IMP_FK' THEN delete_message('جدول المستوردين', 'Sandy Exports')
                   WHEN 'VCE_IMP_FK' THEN delete_message('جدول المستوردين', 'ملف استثناء السيارات')
                   WHEN 'BO_IMP_FK' THEN delete_message('جدول المستوردين', 'مالك البوليصة')
                   WHEN 'BW_IMP_FK' THEN delete_message('IMPORTERS', 'BA_WAREHOUSES')
               END;
    END delete_constraint_message;


    -- Source: IMPORTERS.ON-ERROR (+ PU CGTE$CHECK_CONSTRAINT_VIO); = IMPR1110 importers_on_error, plus the
    -- FRM-40510 branch of IMPR1130 (ORA-02292 on DELETE -> delete_constraint_message).
    -- p_op = 'I' / 'U' / 'D' (FRM-40508 / 40509 / 40510). Returns the text Forms shows.
    FUNCTION importers_on_error (p_op IN VARCHAR2, p_sqlcode IN NUMBER, p_sqlerrm IN VARCHAR2)
        RETURN VARCHAR2
    IS
        server_err      NUMBER := ABS(p_sqlcode);
        constraint_name VARCHAR2(61);
    BEGIN
        IF server_err = 1031 THEN
            IF p_op = 'I' THEN RETURN 'ليس لديك صلاحية الادخال '; END IF;
            IF p_op = 'U' THEN RETURN 'ليس لديك صلاحية التعديل'; END IF;
            IF p_op = 'D' THEN RETURN 'ليس لديك صلاحية الحذف'; END IF;
        END IF;
        -- CGTE$CHECK_CONSTRAINT_VIO
        IF server_err BETWEEN 20000 AND 20999 THEN
            -- CGTE$STRIP_FIRST_ERROR (MISSING SOURCE): text without the "ORA-2xxxx: " prefix
            RETURN REGEXP_REPLACE(REGEXP_SUBSTR(p_sqlerrm, '[^' || CHR(10) || ']+'), '^ORA-[0-9]+: ');
        END IF;
        constraint_name := strip_constraint(p_sqlerrm);
        IF server_err = 1 THEN
            IF constraint_name IN ('IMP_PK', 'IMP_BUSID_UK', 'ITIDT_PK', 'IT_PK', 'BIT_PK') THEN
                RETURN 'هذا السجل مدخل سابقاً - أعد ادخال البيانات';
            ELSIF constraint_name = 'SDP_PK' THEN
                RETURN FORMS_APX.CG_MESSAGE('Row exists already with same <p1>', 'رمز الجمرك');
            ELSIF constraint_name = 'CT_PK' THEN
                RETURN FORMS_APX.CG_MESSAGE('Row exists already with same <p1>', 'City Cd,رمز الدولة');
            ELSIF constraint_name = 'CTRY_PK' THEN
                RETURN FORMS_APX.CG_MESSAGE('Row exists already with same <p1>', 'رمز الدولة');
            END IF;
            RETURN p_sqlerrm;
        ELSIF server_err = 2290 THEN
            RETURN p_sqlerrm;
        END IF;
        -- FK - parent key not found
        IF server_err = 2291 THEN
            IF constraint_name = 'IMP_SDP_FK' THEN
                RETURN FORMS_APX.CG_MESSAGE('This <p1> does not exist', 'رمز الجمــــــــــــــرك');
            ELSIF constraint_name = 'IMP_NATIONALITY_FK' THEN
                RETURN FORMS_APX.CG_MESSAGE('This <p1> does not exist', 'NATIONALITY');
            ELSIF constraint_name = 'IMP_ITIDT_FK' THEN
                RETURN 'رمز النشاط التجاري غير صحيح - أعد إدخال البيانات';
            ELSIF constraint_name = 'IMP_IMP_FK' THEN
                RETURN FORMS_APX.CG_MESSAGE('This <p1> does not exist', 'IMPR_NBR_PARENT,PORT_CD');
            ELSIF constraint_name = 'IMP_CTRY_FK' THEN
                RETURN 'رمز الدولة غير صحيح - أعد ادخال البيانات';
            ELSIF constraint_name = 'IMP_BUS_ID_CITY_FK' THEN
                RETURN 'خطأ في رمز مدينة مصدر الرقم الإستدلالي';
            ELSIF constraint_name = 'IMP_ADD_CITY_FK' THEN
                RETURN 'خطأ في رمز مدينة عنوان المستورد';
            END IF;
            RETURN p_sqlerrm;
        END IF;
        -- FK - child record found (FRM-40510: delete)
        IF server_err = 2292 THEN
            IF p_op = 'D' THEN
                RETURN NVL(delete_constraint_message(constraint_name), p_sqlerrm);
            END IF;
            RETURN p_sqlerrm;
        END IF;
        RETURN p_sqlerrm;
    END importers_on_error;

    -- Text of a failure raised inside a VALIDATION function (= IMPR1110 PRIVATE_ERROR_TEXT)
    FUNCTION error_text (p_sqlcode IN NUMBER, p_sqlerrm IN VARCHAR2, p_op IN VARCHAR2) RETURN VARCHAR2
    IS
    BEGIN
        IF p_sqlcode BETWEEN -20999 AND -20000 THEN
            RETURN REGEXP_REPLACE(p_sqlerrm, '^ORA-[0-9]+: ');
        END IF;
        RETURN importers_on_error(p_op, p_sqlcode, p_sqlerrm);
    END error_text;

    -- ACTIVITY.ADD_ACTIVITY(9, 2, p_act, port!impr) of CIC_LIB.pld -> ACTIVITY_DB with the f345 items
    -- (= IMPR1110 add_activity). Failure: STR.DISPALERT(V_MSG_TXT) + RAISE FORM_TRIGGER_FAILURE.
    PROCEDURE add_activity (p_act          IN NUMBER,
                            p_port_cd      IN NUMBER,
                            p_impr_nbr     IN NUMBER,
                            p_curr_port_cd IN NUMBER,
                            p_user_id      IN VARCHAR2,
                            p_ws_id        IN VARCHAR2)
    IS
        v_msg VARCHAR2(2000);
    BEGIN
        IF activity_db.add_activity(9, 2, p_act, p_port_cd || '!' || p_impr_nbr,
                                    p_curr_port_cd, p_user_id, p_ws_id, v_msg) = 0 THEN
            FORMS_APX.FORM_TRIGGER_FAILURE(v_msg);
        END IF;
    END add_activity;

    -- HIJDATE.VALID_HIJ_DATE of a typed date: the format and HIJDATE_DB check, raised as an error
    PROCEDURE check_hijri_date (p_text IN VARCHAR2)
    IS
        v_error VARCHAR2(2000);
    BEGIN
        v_error := FORMS_APX.HIJRI_DATE_ERROR(p_text);
        IF v_error IS NOT NULL THEN
            FORMS_APX.FORM_TRIGGER_FAILURE(v_error);
        END IF;
    END check_hijri_date;

    -- SELECT CRTY_ARBC_NAME INTO ... FROM COUNTRIES WHERE CTRY_CD = ... (NO_DATA_FOUND is raised as in Forms)
    FUNCTION country_name (p_ctry_cd IN NUMBER) RETURN VARCHAR2
    IS
        v_name countries.crty_arbc_name%TYPE;
    BEGIN
        SELECT crty_arbc_name INTO v_name
          FROM countries
         WHERE ctry_cd = p_ctry_cd;
        RETURN v_name;
    END country_name;

    -- IMPORTERS.WHEN-NEW-RECORD-INSTANCE: does the importer appear in a declaration (as importer or agent)?
    FUNCTION declarations_exist (p_curr_port_cd IN NUMBER, p_impr_nbr IN NUMBER) RETURN BOOLEAN
    IS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*)
          INTO v_count
          FROM declarations
         WHERE port_cd = p_curr_port_cd
           AND ((agent_nbr = p_impr_nbr)
                OR
                (impr_nbr IS NOT NULL AND impr_nbr = p_impr_nbr))
           AND ROWNUM = 1;
        RETURN v_count > 0;
    END declarations_exist;

    -- Rows of the commercial register COMM_IMPR_RGSTR for the number entered
    -- (BUS_ID / BUS_ID_BRNCH WHEN-VALIDATE-ITEM: type 1 = main register BRNCHREG = 0, type 2 = branch)
    FUNCTION register_row_count (p_comm_rgstrtn_type IN NUMBER,
                                 p_bus_id            IN VARCHAR2,
                                 p_bus_id_brnch      IN VARCHAR2) RETURN NUMBER
    IS
        v_count NUMBER := 0;
    BEGIN
        IF p_comm_rgstrtn_type = 1 AND p_bus_id IS NOT NULL THEN
            SELECT COUNT(bus_id) INTO v_count
              FROM comm_impr_rgstr
             WHERE bus_id   = p_bus_id
               AND brnchreg = 0;
        ELSIF p_comm_rgstrtn_type = 2 AND p_bus_id IS NOT NULL AND p_bus_id_brnch IS NOT NULL THEN
            SELECT COUNT(bus_id) INTO v_count
              FROM comm_impr_rgstr
             WHERE bus_id       = p_bus_id
               AND brnch_bus_id = p_bus_id_brnch;
        END IF;
        RETURN v_count;
    END register_row_count;

    -- The values the register gives for the number entered (SELECT ... INTO of BUS_ID / BUS_ID_BRNCH WVI;
    -- TOO_MANY_ROWS is raised as in Forms)
    PROCEDURE fill_from_register (p_comm_rgstrtn_type IN     NUMBER,
                                  p_bus_id            IN     VARCHAR2,
                                  p_bus_id_brnch      IN     VARCHAR2,
                                  p_arbc_impr_name    IN OUT VARCHAR2,
                                  p_impr_name_std     IN OUT VARCHAR2,
                                  p_bus_id_exprd_dt   IN OUT VARCHAR2,
                                  p_impr_tel_nbr      IN OUT VARCHAR2,
                                  p_impr_pob_nbr      IN OUT NUMBER,
                                  p_impr_zip_cd       IN OUT NUMBER,
                                  p_impr_fax_nbr      IN OUT VARCHAR2,
                                  p_impr_telex_nbr    IN OUT VARCHAR2)
    IS
        v_exprd_dt DATE;
    BEGIN
        IF p_comm_rgstrtn_type = 1 THEN
            SELECT arbc_impr_name, arbc_name_std, bus_id_exprd_dt,
                   impr_tel_nbr, impr_pob_nbr, impr_zip_cd, impr_fax_nbr, impr_telex_nbr
              INTO p_arbc_impr_name, p_impr_name_std, v_exprd_dt,
                   p_impr_tel_nbr, p_impr_pob_nbr, p_impr_zip_cd, p_impr_fax_nbr, p_impr_telex_nbr
              FROM comm_impr_rgstr
             WHERE bus_id   = p_bus_id
               AND brnchreg = 0;
        ELSE
            SELECT arbc_impr_name, arbc_name_std, bus_id_exprd_dt,
                   impr_tel_nbr, impr_pob_nbr, impr_zip_cd, impr_fax_nbr, impr_telex_nbr
              INTO p_arbc_impr_name, p_impr_name_std, v_exprd_dt,
                   p_impr_tel_nbr, p_impr_pob_nbr, p_impr_zip_cd, p_impr_fax_nbr, p_impr_telex_nbr
              FROM comm_impr_rgstr
             WHERE bus_id       = p_bus_id
               AND brnch_bus_id = p_bus_id_brnch;
        END IF;
        p_bus_id_exprd_dt := FORMS_APX.HIJRI_TEXT(v_exprd_dt);
    END fill_from_register;

    -- Ministry of Commerce data (IMPR_TYPE_CD WVI first branch): identity type 2, not a Gulf importer, ALLOW_MCI = 1
    FUNCTION ministry_data (p_impr_type_cd IN NUMBER, p_bus_id_type_cd IN NUMBER, p_allow_mci IN VARCHAR2)
        RETURN BOOLEAN
    IS
    BEGIN
        RETURN p_bus_id_type_cd = 2 AND p_impr_type_cd <> 12 AND NVL(p_allow_mci, '0') = '1';
    END ministry_data;

    -- BUS_ID / BUS_ID_BRNCH WVI, branch COMM_TABLE_UNCHECK: the number is not in the register (and the setting
    -- allows it, otherwise the validation failed with 9-190) -> the register items are enabled again
    FUNCTION register_unlocked (p_impr_type_cd      IN NUMBER,
                                p_bus_id_type_cd    IN NUMBER,
                                p_comm_rgstrtn_type IN NUMBER,
                                p_bus_id            IN VARCHAR2,
                                p_bus_id_brnch      IN VARCHAR2) RETURN BOOLEAN
    IS
    BEGIN
        IF NOT (p_bus_id_type_cd = 2 AND p_impr_type_cd <> 12) THEN
            RETURN FALSE;
        END IF;
        IF NOT ((p_comm_rgstrtn_type = 1 AND p_bus_id IS NOT NULL)
                OR (p_comm_rgstrtn_type = 2 AND p_bus_id IS NOT NULL AND p_bus_id_brnch IS NOT NULL)) THEN
            RETURN FALSE;
        END IF;
        RETURN register_row_count(p_comm_rgstrtn_type, p_bus_id, p_bus_id_brnch) = 0;
    END register_unlocked;

    -- BUS_ID / CITY_CODE_OF_ID WVI: the 10-digit number = ministry city code (4) || number (6); fills
    -- ID_MINS_COMM_CD (SELECT MINS_COMM_CD INTO :ID_MINS_COMM_CD; NO_DATA_FOUND is raised as in Forms)
    FUNCTION full_bus_id (p_bus_id          IN     VARCHAR2,
                          p_city_code_of_id IN     NUMBER,
                          p_ctry_cd_of_id   IN     NUMBER,
                          p_id_mins_comm_cd IN OUT NUMBER) RETURN VARCHAR2
    IS
    BEGIN
        SELECT mins_comm_cd
          INTO p_id_mins_comm_cd
          FROM cities
         WHERE city_cd = p_city_code_of_id
           AND ctry_cd = p_ctry_cd_of_id;
        RETURN LPAD(TO_CHAR(p_id_mins_comm_cd), 4, '0') || LPAD(p_bus_id, 6, '0');
    END full_bus_id;

    -- Message 9-120 + the full number; NULL when the message is missing (Forms then shows
    -- 'خطأ فى رقم الرسالة ...' and does not change the number)
    FUNCTION message_9_120 (p_full_bus_id IN VARCHAR2) RETURN VARCHAR2
    IS
        v_txt VARCHAR2(4000);
    BEGIN
        v_txt := str_db.getarbmsg(9, 120);
        IF v_txt = '-1' THEN
            RETURN NULL;
        END IF;
        RETURN 9 || '-' || 120 || ' : ' || v_txt || ' ' || p_full_bus_id;
    END message_9_120;

    -- Source: PU CHK_IMPR_DUPL (the BUS_ID / BUS_ID_BRNCH pair must not belong to another importer of the port)
    PROCEDURE chk_impr_dupl (p_port_cd        IN     NUMBER,
                             p_ctry_cd        IN     NUMBER,
                             p_bus_id_type_cd IN     NUMBER,
                             p_bus_id         IN     VARCHAR2,
                             p_bus_id_brnch   IN OUT VARCHAR2,
                             p_impr_nbr       IN     NUMBER)
    IS
        v_count    NUMBER;
        v_impr_nbr NUMBER;
    BEGIN
        IF p_bus_id_brnch IS NOT NULL THEN
            p_bus_id_brnch := TO_NUMBER(p_bus_id_brnch);   -- :IMPORTERS.BUS_ID_BRNCH := TO_NUMBER(...); SYNCHRONIZE (not needed)
            SELECT COUNT(*), MAX(impr_nbr)
              INTO v_count, v_impr_nbr
              FROM importers
             WHERE port_cd        = p_port_cd
               AND ctry_cd        = NVL(p_ctry_cd, ctry_cd)
               AND bus_id_type_cd = p_bus_id_type_cd
               AND bus_id         = p_bus_id
               AND bus_id_brnch   = p_bus_id_brnch
               AND ((p_impr_nbr IS NULL) OR (p_impr_nbr IS NOT NULL AND impr_nbr <> p_impr_nbr));
        ELSE
            SELECT COUNT(*), MAX(impr_nbr)
              INTO v_count, v_impr_nbr
              FROM importers
             WHERE port_cd        = p_port_cd
               AND ctry_cd        = NVL(p_ctry_cd, ctry_cd)
               AND bus_id_type_cd = p_bus_id_type_cd
               AND bus_id         = p_bus_id
               AND bus_id_brnch IS NULL
               AND ((p_impr_nbr IS NULL) OR (p_impr_nbr IS NOT NULL AND impr_nbr <> p_impr_nbr));
        END IF;
        -- Forms: COUNT(*) then a second SELECT MAX(IMPR_NBR) with the same WHERE clause (one query here)
        IF v_count > 0 THEN
            FORMS_APX.FORM_TRIGGER_FAILURE(' لا يمكن تكرار الرقم الإستدلالي - الرقم الإستدلالي مستخدم لمستورد آخر مسلسله بالجمرك رقم : ' || v_impr_nbr);
        END IF;
    END chk_impr_dupl;

    -- Source: PU INSERT_AUDIT_RECORD (row of IMPR_UPDTS with the record values; message 9-140 without IMPR_NBR)
    PROCEDURE insert_audit_record (p_row      IN importers%ROWTYPE,
                                   p_act_type IN VARCHAR2,
                                   p_user_id  IN VARCHAR2)
    IS
    BEGIN
        IF p_row.impr_nbr IS NULL THEN
            FORMS_APX.DISPLAY_ARABIC_ERROR(9, 140);
        END IF;
        INSERT INTO impr_updts (port_cd, impr_nbr, hq_impr_nbr, impr_type_cd, bus_id_type_cd, bus_id, bus_id_brnch,
                                bus_id_exprd_dt, ctry_cd_of_id, city_code_of_id, impr_expr_type, arbc_impr_name,
                                eng_impr_name, impr_name_std, impr_nbr_parent, impr_cntct_name, impr_tel_nbr,
                                impr_pob_nbr, impr_zip_cd, impr_fax_nbr, impr_telex_nbr, email, ctry_cd, add_ctry_cd,
                                city_code, lst_tran_dt, impd_stmt_nbr, impr_data_srce, act_dt, act_type, usr_id,
                                comm_rgstrtn_type, id_nbr, bus_id_issue_dt, bus_id_status, creation_flag, impr_address)
        VALUES (p_row.port_cd, p_row.impr_nbr, p_row.hq_impr_nbr, p_row.impr_type_cd, p_row.bus_id_type_cd,
                p_row.bus_id, p_row.bus_id_brnch, p_row.bus_id_exprd_dt, p_row.ctry_cd_of_id, p_row.city_code_of_id,
                p_row.impr_expr_type, p_row.arbc_impr_name, p_row.eng_impr_name, p_row.impr_name_std,
                p_row.impr_nbr_parent, p_row.impr_cntct_name, p_row.impr_tel_nbr, p_row.impr_pob_nbr,
                p_row.impr_zip_cd, p_row.impr_fax_nbr, p_row.impr_telex_nbr, p_row.email, p_row.ctry_cd,
                p_row.add_ctry_cd, p_row.city_code, p_row.lst_tran_dt, p_row.impd_stmt_nbr, p_row.impr_data_srce,
                SYSDATE, p_act_type, p_user_id, p_row.comm_rgstrtn_type, p_row.id_nbr, p_row.bus_id_issue_dt,
                p_row.bus_id_status, p_row.creation_flag, p_row.impr_address);
    END insert_audit_record;

    -- PRE-UPDATE cursors C1_HQ_NBR / C2_HQ_NBR: number of the importer in HQ_IMPRS (NULL when not found)
    FUNCTION hq_number (p_bus_id_type_cd IN NUMBER, p_bus_id IN VARCHAR2, p_bus_id_brnch IN VARCHAR2)
        RETURN NUMBER
    IS
        v_hq_nbr NUMBER;
    BEGIN
        SELECT hq_impr_nbr
          INTO v_hq_nbr
          FROM hq_imprs
         WHERE bus_id_type_cd = p_bus_id_type_cd
           AND bus_id         = p_bus_id
           AND ((p_bus_id_brnch IS NULL AND bus_id_brnch IS NULL) OR bus_id_brnch = p_bus_id_brnch)
           AND ROWNUM = 1;                     -- the Forms cursor FETCH takes the first row
        RETURN v_hq_nbr;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;                       -- V_HQ_NBR NUMBER := NULL; FETCH finds nothing
    END hq_number;

    -- Switch journaling off (POST-INSERT; also on a failure after JOURNALING_ON: APEX pools the DB sessions,
    -- SUPPORT_ENTRY inventory risk R10)
    PROCEDURE journaling_off
    IS
    BEGIN
        IF db_journal.is_journaling_on THEN
            db_journal.journaling_off;
        END IF;
    END journaling_off;

    -- =========================================================================
    -- 3 CONVERTED FORMS LOGIC (private)
    -- =========================================================================

    -- Source: IMPORTERS.PORT_CD.WHEN-VALIDATE-ITEM (first block is NULL; CGFK$CHK_IMPORTERS_IMP_SDP_FK)
    PROCEDURE port_cd_logic (p_port_cd IN NUMBER, p_port_name IN OUT VARCHAR2)
    IS
    BEGIN
        IF p_port_cd IS NOT NULL THEN
            SELECT l_sdp.port_name INTO p_port_name
              FROM sd_ports l_sdp
             WHERE l_sdp.port_cd = p_port_cd;
        END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            FORMS_APX.FORM_TRIGGER_FAILURE(FORMS_APX.CG_MESSAGE('This <p1> does not exist', 'رمز الجمــــــــــــــرك'));
    END port_cd_logic;

    -- Source: IMPORTERS.IMPR_TYPE_CD.WHEN-VALIDATE-ITEM (converted from IMPR1130; differs from IMPR1110)
    -- p_from_item = FALSE (page validation): no sequence is read, so BUS_ID is not generated again.
    -- The Make_Field_Entrable / SET_ITEM_PROPERTY calls are rules (READ_ONLY_FLAGS, read_only_rules.md).
    PROCEDURE impr_type_cd_logic (p_from_item          IN     BOOLEAN,
                                  p_curr_port_cd       IN     NUMBER,
                                  p_impr_type_cd       IN OUT NUMBER,
                                  p_impr_type_name     IN OUT VARCHAR2,
                                  p_bus_id_type_cd     IN OUT NUMBER,
                                  p_bus_id_type_name   IN OUT VARCHAR2,
                                  p_bus_id             IN OUT VARCHAR2,
                                  p_ctry_cd            IN OUT NUMBER,
                                  p_crty_arbc_name     IN OUT VARCHAR2,
                                  p_add_ctry_cd        IN OUT NUMBER,
                                  p_add_crty_arbc_name IN OUT VARCHAR2)
    IS
        v_count         NUMBER;
        v_type_count    NUMBER;
        v_valid_pair    NUMBER;
        v_seq           VARCHAR2(6);
    BEGIN
        -- APEX-DA: Make_Field_Entrable CTRY_CD TRUE, ADD_CTRY_CD / CITY_CODE_OF_ID FALSE, BUS_ID_BRNCH / BUS_ID TRUE
        IF NVL(gnrl.get_customs_setting(p_curr_port_cd, 'STOP_IMPR_CR_TYPE', 9), 0) = 1 THEN
            SELECT COUNT(*) INTO v_count
              FROM impr_type_id_types
             WHERE impr_type_cd   = p_impr_type_cd
               AND bus_id_type_cd = 2
               AND status         = 1;
            IF v_count > 0 THEN
                FORMS_APX.DISPLAY_ARABIC_ERROR(9, 331);            -- DispArbMsg(9, 331, 'INFORMATION') + FORM_TRIGGER_FAILURE
            END IF;
        END IF;

        IF p_impr_type_cd IN (1, 2, 5, 8, 11) THEN
            p_ctry_cd     := 100;
            p_add_ctry_cd := 100;
        ELSIF p_impr_type_cd = 4 THEN
            IF p_bus_id_type_cd = 5 THEN
                p_ctry_cd     := 100;
                p_add_ctry_cd := 100;
            END IF;
        ELSIF p_impr_type_cd = 9 THEN
            p_ctry_cd     := 100;
            p_add_ctry_cd := 100;
            IF p_bus_id_type_cd IS NULL THEN
                p_bus_id_type_cd := 6;
            END IF;
            IF p_bus_id_type_cd = 6 AND p_from_item THEN
                SELECT LPAD(gnrl.get_sequence_value(p_curr_port_cd, 'KING_IMPR_SEQ'), 6, '0')
                  INTO v_seq
                  FROM dual;
                p_bus_id := 'ملكى' || v_seq;
            END IF;
        ELSIF p_impr_type_cd = 12 THEN
            IF p_ctry_cd IS NOT NULL THEN
                SELECT COUNT(*) INTO v_count
                  FROM ctry_group_details
                 WHERE ctry_cd       = p_ctry_cd
                   AND ctry_grp_stat = 1
                   AND ctry_grp_nbr  = 1;
                IF v_count = 0 THEN
                    FORMS_APX.FORM_TRIGGER_FAILURE('لابد أن تكون دولة المستورد الخليجي تابعة لدول مجلس التعاون');
                END IF;
            END IF;
        ELSIF p_impr_type_cd IN (16, 17, 18, 20) THEN
            IF p_from_item THEN
                SELECT gnrl.get_sequence_value(p_curr_port_cd, 'IMPORTERS_SEQ') INTO p_bus_id FROM dual;
                IF p_bus_id IS NULL THEN
                    p_bus_id := 1;
                END IF;
            END IF;
            p_ctry_cd     := 100;
            p_add_ctry_cd := 100;
        END IF;                                -- types 7 and 10: read-only rules only
        IF p_impr_type_cd = 14 THEN
            p_ctry_cd     := 100;
            p_add_ctry_cd := 100;
        END IF;

        IF p_ctry_cd IS NOT NULL THEN
            p_crty_arbc_name := country_name(p_ctry_cd);
        END IF;
        IF p_add_ctry_cd IS NOT NULL THEN
            p_add_crty_arbc_name := country_name(p_add_ctry_cd);
        END IF;

        -- :GLOBAL.VALID = 0 (the type was typed, not chosen as a pair in LOV_Impr_Type): find the identity type.
        -- APEX: a pair already valid for the type counts as chosen in the LOV (VALID = 1).
        IF p_impr_type_cd IS NOT NULL THEN
            SELECT COUNT(*) INTO v_type_count
              FROM impr_type_id_types
             WHERE impr_type_cd = p_impr_type_cd;
            SELECT COUNT(*) INTO v_valid_pair
              FROM impr_type_id_types
             WHERE impr_type_cd   = p_impr_type_cd
               AND bus_id_type_cd = p_bus_id_type_cd;
            IF v_type_count = 1 THEN
                SELECT it.bus_id_type_cd, idt.bus_id_type_name
                  INTO p_bus_id_type_cd, p_bus_id_type_name
                  FROM impr_type_id_types it, bus_id_types idt
                 WHERE it.impr_type_cd   = p_impr_type_cd
                   AND it.bus_id_type_cd = idt.bus_id_type_cd;
                -- APEX-DA: Make_Field_Entrable('IMPORTERS.BUS_ID_TYPE_CD', FALSE)
            ELSIF v_type_count > 1 THEN
                IF v_valid_pair = 0 THEN
                    -- DO_KEY('LIST_VALUES'): the user chooses the identity type in the LOV of BUS_ID_TYPE_CD
                    -- APEX-DA: Set Focus P1130_BUS_ID_TYPE_CD
                    p_bus_id_type_cd   := NULL;
                    p_bus_id_type_name := NULL;
                END IF;
            ELSE
                p_impr_type_cd := NULL;
                FORMS_APX.DISPLAY_ARABIC_ERROR(2, 170);
            END IF;
        END IF;
        IF p_impr_type_cd IS NOT NULL THEN
            SELECT impr_type_name INTO p_impr_type_name
              FROM impr_types
             WHERE impr_type_cd = p_impr_type_cd;
        END IF;
        -- APEX-DA: COMM_RGSTRTN_TYPE / register items / BUS_ID_EXPRD_DT / ARBC_IMPR_NAME enabling and the
        --          COMM_RGSTRTN_TYPE REQUIRED property by BUS_ID_TYPE_CD, IMPR_TYPE_CD, :GLOBAL.ALLOW_MCI;
        --          ADD_CTRY_CD enabled only for type 21 / identity type 19 (rules)

        -- CGFK$VALDIDATE_FK (CGFK$CHK_IMPORTERS_IMP_ITIDT_F)
        IF p_impr_type_cd IS NOT NULL AND p_bus_id_type_cd IS NOT NULL THEN
            BEGIN
                SELECT it.impr_type_name, bit.bus_id_type_name
                  INTO p_impr_type_name, p_bus_id_type_name
                  FROM impr_type_id_types itidt, impr_types it, bus_id_types bit
                 WHERE itidt.bus_id_type_cd = p_bus_id_type_cd
                   AND itidt.impr_type_cd   = p_impr_type_cd
                   AND it.impr_type_cd      = itidt.impr_type_cd
                   AND bit.bus_id_type_cd   = itidt.bus_id_type_cd
                   AND ROWNUM = 1;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    FORMS_APX.FORM_TRIGGER_FAILURE('رمز النشاط التجاري غير صحيح - أعد إدخال البيانات');
            END;
        END IF;
    END impr_type_cd_logic;

    -- Source: IMPORTERS.BUS_ID_TYPE_CD.WHEN-VALIDATE-ITEM (new in IMPR1130)
    PROCEDURE bus_id_type_cd_logic (p_impr_type_cd IN NUMBER, p_ctry_cd IN NUMBER, p_bus_id_type_cd IN NUMBER)
    IS
    BEGIN
        IF (p_impr_type_cd = 4 AND p_ctry_cd = 100 AND p_bus_id_type_cd <> 5)
           OR
           (p_impr_type_cd = 4 AND p_ctry_cd <> 100 AND p_bus_id_type_cd = 5)
        THEN
            FORMS_APX.DISPLAY_ARABIC_ERROR(9, 170);
        END IF;
    END bus_id_type_cd_logic;

    -- Source: IMPORTERS.CTRY_CD.WHEN-VALIDATE-ITEM (Gulf rule; CGFK$CHK_IMPORTERS_IMP_CTRY_FK)
    PROCEDURE ctry_cd_logic (p_impr_type_cd IN NUMBER, p_ctry_cd IN NUMBER, p_crty_arbc_name IN OUT VARCHAR2)
    IS
        v_count NUMBER;
    BEGIN
        IF p_impr_type_cd = 12 THEN
            SELECT COUNT(*) INTO v_count
              FROM ctry_group_details
             WHERE ctry_cd       = p_ctry_cd
               AND ctry_grp_stat = 1
               AND ctry_grp_nbr  = 1;
            IF v_count = 0 THEN
                FORMS_APX.FORM_TRIGGER_FAILURE('لابد أن تكون دولة المستورد الخليجي تابعة لدول مجلس التعاون');
            END IF;
        END IF;
        IF p_ctry_cd IS NOT NULL THEN
            BEGIN
                SELECT ctry.crty_arbc_name INTO p_crty_arbc_name
                  FROM countries ctry
                 WHERE ctry.ctry_cd     = p_ctry_cd
                   AND ctry.ctry_status = 1;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    FORMS_APX.FORM_TRIGGER_FAILURE('رمز الدولة غير صحيح - أعد ادخال البيانات');
            END;
        END IF;
    END ctry_cd_logic;

    -- CITY_CODE_OF_ID.WHEN-NEW-ITEM-INSTANCE (CTRY_CD_OF_ID := CTRY_CD for type 20, else 100, while the city is
    -- empty) followed by the first block of CITY_CODE_OF_ID.WHEN-VALIDATE-ITEM (type <> 20: 100 / NULL)
    FUNCTION ctry_cd_of_id_value (p_impr_type_cd    IN NUMBER,
                                  p_ctry_cd         IN NUMBER,
                                  p_city_code_of_id IN NUMBER,
                                  p_ctry_cd_of_id   IN NUMBER) RETURN NUMBER
    IS
    BEGIN
        IF NVL(p_impr_type_cd, 0) <> 20 THEN
            RETURN CASE WHEN p_city_code_of_id IS NOT NULL THEN 100 END;
        END IF;
        RETURN NVL(p_ctry_cd_of_id, p_ctry_cd);
    END ctry_cd_of_id_value;

    -- Source: IMPORTERS.CITY_CODE_OF_ID.WHEN-VALIDATE-ITEM (converted from IMPR1130) + CTRY_CD_OF_ID.WHEN-VALIDATE-ITEM
    -- p_from_item = FALSE (page validation): the BUS_ID part (only when :SYSTEM.TRIGGER_ITEM = CURSOR_ITEM)
    -- and the warning message are skipped.
    PROCEDURE city_code_of_id_logic (p_from_item       IN     BOOLEAN,
                                     p_impr_type_cd    IN     NUMBER,
                                     p_ctry_cd         IN     NUMBER,
                                     p_bus_id_type_cd  IN     NUMBER,
                                     p_answer          IN     NUMBER,
                                     p_city_code_of_id IN     NUMBER,
                                     p_ctry_cd_of_id   IN OUT NUMBER,
                                     p_bus_id          IN OUT VARCHAR2,
                                     p_id_mins_comm_cd IN OUT NUMBER,
                                     p_id_city_name    IN OUT VARCHAR2)
    IS
        v_full_bus_id VARCHAR2(10);
        v_mins        NUMBER := p_id_mins_comm_cd;
    BEGIN
        p_ctry_cd_of_id := ctry_cd_of_id_value(p_impr_type_cd, p_ctry_cd, p_city_code_of_id, p_ctry_cd_of_id);

        IF p_from_item AND p_bus_id_type_cd = 2 THEN
            IF LENGTH(p_bus_id) <= 6 THEN
                v_full_bus_id := full_bus_id(p_bus_id, p_city_code_of_id, p_ctry_cd_of_id, v_mins);
                p_id_mins_comm_cd := v_mins;
                IF message_9_120(v_full_bus_id) IS NULL THEN
                    FORMS_APX.MESSAGE('خطأ فى رقم الرسالة ' || 9 || '-' || 120 || 'إتصل بالمسانده الفنيه');
                ELSIF NVL(p_answer, c_yes) = c_yes THEN         -- STR.DispAlert(..., 'CONFIRM') = ALERT_BUTTON1
                    p_bus_id := v_full_bus_id;
                ELSE
                    FORMS_APX.FORM_TRIGGER_FAILURE;             -- ALERT_BUTTON2
                END IF;
            ELSIF LENGTH(p_bus_id) = 10 THEN
                IF TO_NUMBER(SUBSTR(p_bus_id, 1, 4)) <> p_id_mins_comm_cd THEN
                    FORMS_APX.DISPLAY_ARABIC_ERROR(9, 130);
                END IF;
            END IF;
        END IF;

        BEGIN
            SELECT city_arb_name INTO p_id_city_name
              FROM cities
             WHERE city_cd = p_city_code_of_id
               AND ctry_cd = p_ctry_cd_of_id;
        EXCEPTION
            WHEN OTHERS THEN NULL;
        END;

        -- CGFK$WVI_CLR_DEPS_OVF / CTRY_CD_OF_ID.WHEN-VALIDATE-ITEM (CGSF$CLRLU_IMPORTERS_IMP_BUS_I)
        IF p_city_code_of_id IS NULL AND p_ctry_cd_of_id IS NULL THEN
            p_id_city_name    := NULL;
            p_id_mins_comm_cd := NULL;
        END IF;

        -- CGFK$VALDIDATE_FK_OVF (CGFK$CHK_IMPORTERS_IMP_BUS_ID_) - warning only
        IF p_city_code_of_id IS NOT NULL AND p_ctry_cd_of_id IS NOT NULL THEN
            BEGIN
                SELECT id_city.city_arb_name, id_city.mins_comm_cd
                  INTO p_id_city_name, p_id_mins_comm_cd
                  FROM cities id_city
                 WHERE id_city.city_cd     = p_city_code_of_id
                   AND id_city.ctry_cd     = p_ctry_cd_of_id
                   AND id_city.city_status = 1
                   AND ROWNUM = 1;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    IF p_from_item THEN
                        FORMS_APX.MESSAGE('خطأ في رمز مدينة مصدر الرقم الإستدلالي');
                    END IF;
            END;
        END IF;
    END city_code_of_id_logic;

    -- Source: PU GET_CR_DATA (converted from IMPR1130: 16 fields; WHEN OTHERS THEN NULL kept)
    -- SUGGESTION: errors of the web service are ignored as in Forms; a message would tell the user why
    --             nothing was filled.
    PROCEDURE get_cr_data (p_string_result   IN     VARCHAR2,
                           p_bus_id          IN OUT VARCHAR2,
                           p_bus_id_brnch    IN OUT VARCHAR2,
                           p_bus_id_exprd_dt IN OUT VARCHAR2,
                           p_bus_id_issue_dt IN OUT VARCHAR2,
                           p_arbc_impr_name  IN OUT VARCHAR2,
                           p_impr_name_std   IN OUT VARCHAR2,
                           p_impr_address    IN OUT VARCHAR2,
                           p_impr_tel_nbr    IN OUT VARCHAR2,
                           p_impr_fax_nbr    IN OUT VARCHAR2,
                           p_impr_telex_nbr  IN OUT VARCHAR2,
                           p_activity        IN OUT VARCHAR2,
                           p_bus_id_status   IN OUT importers.bus_id_status%TYPE,
                           p_city_code_of_id IN OUT importers.city_code_of_id%TYPE,
                           p_lst_tran_dt     IN OUT VARCHAR2,
                           p_creation_flag   IN OUT importers.creation_flag%TYPE)
    IS
        TYPE t_text IS TABLE OF VARCHAR2(500) INDEX BY PLS_INTEGER;
        v_txt             t_text;
        v_string          VARCHAR2(5000);
        v_start           PLS_INTEGER := 1;
        v_pos             PLS_INTEGER;
        v_bus_id_exprd_dt DATE;
        v_bus_id_issue_dt DATE;
        v_impr_tel_nbr    importers.impr_tel_nbr%TYPE;
        v_impr_fax_nbr    importers.impr_fax_nbr%TYPE;
        v_bus_id_status   importers.bus_id_status%TYPE;
        v_city_code_of_id importers.city_code_of_id%TYPE;
    BEGIN
        FORMS_APX.MESSAGE('سيتم الحصول على بيانات المستورد من وزارة التجارة.....الرجاء الإنتظار');   -- DISPALERT(..., 'ERROR'), no raise
        v_string := p_string_result;
        IF v_string IS NOT NULL THEN
            -- 21 x ' |' appended, then the text between the first 16 '|' (V_POS_1 .. V_POS_16 / V_TXT_1 .. V_TXT_16)
            v_string := LTRIM(RTRIM(v_string)) || ' |' || ' |' || ' |' || ' |' || ' |' || ' |' || ' |' || ' |' || ' |'
                        || ' |' || ' |' || ' |' || ' |' || ' |' || ' |' || ' |' || ' |' || ' |' || ' |' || ' |' || ' |' || ' |';
            FOR i IN 1 .. 16 LOOP
                v_pos    := INSTR(v_string, '|', v_start);
                v_txt(i) := UPPER(LTRIM(RTRIM(SUBSTR(v_string, v_start, v_pos - v_start))));
                v_start  := v_pos + 1;
            END LOOP;
            IF v_txt(1) IS NOT NULL THEN
                p_bus_id       := v_txt(1);
                p_bus_id_brnch := v_txt(2);
                IF p_bus_id_brnch = 0 THEN
                    p_bus_id_brnch := NULL;
                END IF;
                v_bus_id_exprd_dt := TO_DATE(v_txt(3), c_service_mask);
                v_bus_id_issue_dt := TO_DATE(v_txt(4), c_service_mask);
                IF v_txt(9) > '0000000' THEN
                    v_impr_tel_nbr := v_txt(9);
                ELSIF v_txt(10) > '0000000' THEN
                    v_impr_tel_nbr := v_txt(10);
                END IF;
                IF v_txt(11) > '0000000' THEN
                    v_impr_fax_nbr := v_txt(11);
                ELSIF v_txt(12) > '0000000' THEN
                    v_impr_fax_nbr := v_txt(12);
                END IF;
                IF UPPER(v_txt(15)) = 'ACTIVE' THEN
                    v_bus_id_status := 1;
                ELSIF UPPER(v_txt(15)) = 'EXPIRED' THEN
                    v_bus_id_status := 2;
                ELSIF UPPER(v_txt(15)) = 'SUSPENDED' THEN
                    v_bus_id_status := 3;
                ELSIF UPPER(v_txt(15)) LIKE 'WRITTEN%OFF' THEN
                    v_bus_id_status := 4;
                ELSE
                    v_bus_id_status := 5;
                END IF;
                BEGIN
                    SELECT city_cd INTO v_city_code_of_id
                      FROM cities
                     WHERE mins_comm_cd = v_txt(16);
                EXCEPTION
                    WHEN OTHERS THEN NULL;
                END;
                p_bus_id_exprd_dt := FORMS_APX.HIJRI_TEXT(v_bus_id_exprd_dt);
                p_bus_id_issue_dt := FORMS_APX.HIJRI_TEXT(v_bus_id_issue_dt);
                p_arbc_impr_name  := v_txt(6);
                p_impr_name_std   := str_db.strformat(v_txt(6));
                p_impr_address    := v_txt(8);
                p_impr_tel_nbr    := v_impr_tel_nbr;
                p_impr_fax_nbr    := v_impr_fax_nbr;
                p_impr_telex_nbr  := v_txt(13);
                p_activity        := v_txt(14);
                p_bus_id_status   := v_bus_id_status;
                p_city_code_of_id := v_city_code_of_id;
                p_lst_tran_dt     := TO_CHAR(SYSDATE, c_date_time_mask);
                p_creation_flag   := 3;
                -- APEX-DA: SET_ITEM_PROPERTY BUS_ID / BUS_ID_BRNCH INSERT_ALLOWED / UPDATE_ALLOWED FALSE
                --          (rule: CREATION_FLAG = 3 on a new record)
            END IF;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN NULL;
    END get_cr_data;

    -- Source: IMPORTERS.BUS_ID.WHEN-VALIDATE-ITEM (converted from IMPR1130)
    PROCEDURE bus_id_logic (p_from_item         IN     BOOLEAN,
                            p_port_cd           IN     NUMBER,
                            p_impr_nbr          IN     NUMBER,
                            p_impr_type_cd      IN     NUMBER,
                            p_bus_id_type_cd    IN     NUMBER,
                            p_comm_rgstrtn_type IN     NUMBER,
                            p_city_code_of_id   IN     NUMBER,
                            p_ctry_cd_of_id     IN     NUMBER,
                            p_bus_id_brnch      IN     VARCHAR2,
                            p_curr_port_cd      IN     NUMBER,
                            p_bus_id            IN OUT VARCHAR2,
                            p_id_mins_comm_cd   IN OUT NUMBER,
                            p_arbc_impr_name    IN OUT VARCHAR2,
                            p_impr_name_std     IN OUT VARCHAR2,
                            p_bus_id_exprd_dt   IN OUT VARCHAR2,
                            p_impr_tel_nbr      IN OUT VARCHAR2,
                            p_impr_pob_nbr      IN OUT NUMBER,
                            p_impr_zip_cd       IN OUT NUMBER,
                            p_impr_fax_nbr      IN OUT VARCHAR2,
                            p_impr_telex_nbr    IN OUT VARCHAR2)
    IS
        v_full_bus_id VARCHAR2(10);
        v_message     VARCHAR2(4000);
        v_mins        NUMBER := p_id_mins_comm_cd;
        v_count       NUMBER;
        v_impr_nbr    NUMBER;
        v_ret         VARCHAR2(5);
    BEGIN
        IF p_impr_type_cd IN (1, 3, 5, 6, 8, 19) AND LENGTH(p_bus_id) != 10 THEN
            FORMS_APX.FORM_TRIGGER_FAILURE(' يجب أن يكون الرقم الاستدلالي مكونا من عشرة ارقام ');
        END IF;
        IF p_impr_type_cd IN (13, 14) THEN
            IF SUBSTR(p_bus_id, 1, 3) <> '700' THEN
                FORMS_APX.FORM_TRIGGER_FAILURE('يجب أن يبدأ الرقم الإستدلالي برقم "700"');   -- DISPALERT INFORMATION + raise
            END IF;
        END IF;
        IF p_bus_id_type_cd IN (5, 3) AND p_impr_type_cd = 4 THEN
            p_bus_id := LTRIM(RTRIM(p_bus_id));
            IF LENGTH(p_bus_id) != 10 THEN
                FORMS_APX.FORM_TRIGGER_FAILURE(' يجب أن يكون الرقم الاستدلالي مكونا من عشرة ارقام ');
            END IF;
        END IF;

        IF p_bus_id_type_cd = 2 AND p_impr_type_cd != 12 THEN
            IF NOT (LENGTH(p_bus_id) <= 6 OR LENGTH(p_bus_id) = 10) THEN
                FORMS_APX.FORM_TRIGGER_FAILURE;                 -- RAISE form_trigger_failure without a message
            END IF;
            IF p_city_code_of_id IS NOT NULL THEN
                IF LENGTH(p_bus_id) <= 6 THEN
                    v_full_bus_id := full_bus_id(p_bus_id, p_city_code_of_id, p_ctry_cd_of_id, v_mins);
                    p_id_mins_comm_cd := v_mins;
                    v_message := message_9_120(v_full_bus_id);
                    IF v_message IS NULL THEN
                        IF p_from_item THEN
                            FORMS_APX.MESSAGE('خطأ فى رقم الرسالة ' || 9 || '-' || 120 || 'إتصل بالمسانده الفنيه');
                        END IF;
                    ELSE
                        -- STR.DispAlert(Alert_Txt, 'ERROR'): one button = ALERT_BUTTON1 -> the full number is taken
                        IF p_from_item THEN
                            FORMS_APX.MESSAGE(v_message);
                        END IF;
                        p_bus_id := v_full_bus_id;
                    END IF;
                ELSIF LENGTH(p_bus_id) = 10 THEN
                    IF TO_NUMBER(SUBSTR(p_bus_id, 1, 4)) <> p_id_mins_comm_cd THEN
                        FORMS_APX.DISPLAY_ARABIC_ERROR(9, 130);
                    END IF;
                END IF;
            END IF;
        ELSIF p_bus_id_type_cd <> 2 THEN
            SELECT COUNT(*), MAX(impr_nbr)
              INTO v_count, v_impr_nbr
              FROM importers
             WHERE port_cd        = p_port_cd
               AND bus_id_type_cd = p_bus_id_type_cd
               AND bus_id         = p_bus_id
               AND bus_id_brnch IS NULL
               AND ((p_impr_nbr IS NULL) OR (p_impr_nbr IS NOT NULL AND impr_nbr <> p_impr_nbr));
            IF v_count > 0 THEN
                FORMS_APX.FORM_TRIGGER_FAILURE(' لا يمكن تكرار الرقم الإستدلالي - الرقم الإستدلالي مستخدم لمستورد آخر مسلسله بالجمرك رقم : ' || v_impr_nbr);
            END IF;
        END IF;

        -- commercial register COMM_IMPR_RGSTR (main register / branch)
        IF p_bus_id_type_cd = 2 AND p_impr_type_cd != 12 THEN
            IF (p_comm_rgstrtn_type = 1 AND p_bus_id IS NOT NULL)
               OR (p_comm_rgstrtn_type = 2 AND p_bus_id IS NOT NULL AND p_bus_id_brnch IS NOT NULL) THEN
                IF register_row_count(p_comm_rgstrtn_type, p_bus_id, p_bus_id_brnch) > 0 THEN
                    fill_from_register(p_comm_rgstrtn_type, p_bus_id, p_bus_id_brnch, p_arbc_impr_name, p_impr_name_std,
                                       p_bus_id_exprd_dt, p_impr_tel_nbr, p_impr_pob_nbr, p_impr_zip_cd,
                                       p_impr_fax_nbr, p_impr_telex_nbr);
                ELSE
                    v_ret := lib_usr.gnrl.get_customs_setting(p_curr_port_cd, 'COMM_TABLE_UNCHECK', 9);
                    IF NVL(v_ret, 0) = 0 THEN
                        FORMS_APX.DISPLAY_ARABIC_ERROR(9, 190);
                    END IF;
                    -- APEX-DA: register items, BUS_ID_EXPRD_DT, ARBC_IMPR_NAME, COMM_RGSTRTN_TYPE enabled,
                    --          COMM_RGSTRTN_TYPE REQUIRED (rule register_unlocked)
                END IF;
            END IF;
        END IF;
    END bus_id_logic;

    -- Source: IMPORTERS.BUS_ID_BRNCH.WHEN-VALIDATE-ITEM (converted from IMPR1130) + KEY-NEXT-ITEM
    -- p_from_item = FALSE (page validation): CHK_IMPR_DUPL is skipped (PRE-INSERT runs it).
    PROCEDURE bus_id_brnch_logic (p_from_item         IN     BOOLEAN,
                                  p_port_cd           IN     NUMBER,
                                  p_impr_nbr          IN     NUMBER,
                                  p_impr_type_cd      IN     NUMBER,
                                  p_bus_id_type_cd    IN     NUMBER,
                                  p_comm_rgstrtn_type IN     NUMBER,
                                  p_ctry_cd           IN     NUMBER,
                                  p_bus_id            IN     VARCHAR2,
                                  p_bus_id_brnch      IN OUT VARCHAR2,
                                  p_arbc_impr_name    IN OUT VARCHAR2,
                                  p_impr_name_std     IN OUT VARCHAR2,
                                  p_bus_id_exprd_dt   IN OUT VARCHAR2,
                                  p_impr_tel_nbr      IN OUT VARCHAR2,
                                  p_impr_pob_nbr      IN OUT NUMBER,
                                  p_impr_zip_cd       IN OUT NUMBER,
                                  p_impr_fax_nbr      IN OUT VARCHAR2,
                                  p_impr_telex_nbr    IN OUT VARCHAR2)
    IS
        v_ret VARCHAR2(5);
    BEGIN
        IF p_from_item THEN                    -- :System.TRIGGER_ITEM = :System.CURSOR_ITEM
            chk_impr_dupl(p_port_cd, p_ctry_cd, p_bus_id_type_cd, p_bus_id, p_bus_id_brnch, p_impr_nbr);
        END IF;
        IF p_bus_id_brnch = 0 THEN
            FORMS_APX.DISPLAY_ARABIC_ERROR(1, 220);
        ELSIF p_bus_id_type_cd = 2 AND p_impr_type_cd != 12 AND p_comm_rgstrtn_type = 2
              AND p_bus_id IS NOT NULL AND p_bus_id_brnch IS NOT NULL THEN
            IF register_row_count(2, p_bus_id, p_bus_id_brnch) > 0 THEN
                fill_from_register(2, p_bus_id, p_bus_id_brnch, p_arbc_impr_name, p_impr_name_std, p_bus_id_exprd_dt,
                                   p_impr_tel_nbr, p_impr_pob_nbr, p_impr_zip_cd, p_impr_fax_nbr, p_impr_telex_nbr);
            ELSE
                -- TODO-VERIFY: Forms calls the setting without the port here (inventory §15 #6, same in IMPR1110)
                v_ret := lib_usr.gnrl.get_customs_setting('COMM_TABLE_UNCHECK', 9);
                IF NVL(v_ret, 0) = 0 THEN
                    FORMS_APX.DISPLAY_ARABIC_ERROR(9, 190);
                ELSIF LENGTH(p_bus_id_brnch) <> 10 THEN
                    FORMS_APX.DISPLAY_ARABIC_ERROR(9, 210);
                END IF;
                -- APEX-DA: register items enabled, COMM_RGSTRTN_TYPE REQUIRED (rule register_unlocked)
            END IF;
        END IF;
    END bus_id_brnch_logic;

    -- Source: IMPORTERS.ENG_IMPR_NAME.WHEN-VALIDATE-ITEM (= IMPR1110 apart from a blank line)
    PROCEDURE eng_impr_name_logic (p_eng_impr_name IN OUT VARCHAR2)
    IS
        v VARCHAR2(1);
    BEGIN
        IF p_eng_impr_name IS NOT NULL THEN
            p_eng_impr_name := str_db.removerepeat(p_eng_impr_name);
            FOR i IN 1 .. LENGTH(p_eng_impr_name) LOOP
                v := SUBSTR(p_eng_impr_name, i, 1);
                IF (v BETWEEN '0' AND '9') OR (v BETWEEN 'A' AND 'Z') OR (v BETWEEN 'a' AND 'z') OR (v = ' ') THEN
                    NULL;
                ELSE
                    FORMS_APX.FORM_TRIGGER_FAILURE('فضلا .. يجب إدخال اسم المستورد باللغة الانجليزية');
                END IF;
            END LOOP;
        END IF;
    END eng_impr_name_logic;

    -- CGFK$VALDIDATE_FK_OVF (CGFK$CHK_IMPORTERS_IMP_ADD_CIT) of ADD_CTRY_CD / CITY_CODE WVI - warning only
    PROCEDURE address_city_lookup (p_from_item          IN     BOOLEAN,
                                   p_add_ctry_cd        IN     NUMBER,
                                   p_city_code          IN     NUMBER,
                                   p_city_name          IN OUT VARCHAR2,
                                   p_add_crty_arbc_name IN OUT VARCHAR2)
    IS
    BEGIN
        IF p_add_ctry_cd IS NOT NULL AND p_city_code IS NOT NULL THEN
            SELECT add_city.city_arb_name, l_ctry.crty_arbc_name
              INTO p_city_name, p_add_crty_arbc_name
              FROM cities add_city, countries l_ctry
             WHERE add_city.ctry_cd     = p_add_ctry_cd
               AND add_city.city_cd     = p_city_code
               AND add_city.city_status = 1
               AND l_ctry.ctry_cd       = add_city.ctry_cd
               AND ROWNUM = 1;
        END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            IF p_from_item THEN
                FORMS_APX.MESSAGE('خطأ في رمز مدينة عنوان المستورد');
            END IF;
    END address_city_lookup;

    -- Source: IMPORTERS.CITY_CODE.WHEN-VALIDATE-ITEM (= IMPR1110 CITY_CODE_WHEN_VALIDATE_ITEM)
    PROCEDURE city_code_logic (p_from_item          IN     BOOLEAN,
                               p_add_ctry_cd        IN     NUMBER,
                               p_city_code          IN     NUMBER,
                               p_city_name          IN OUT VARCHAR2,
                               p_add_crty_arbc_name IN OUT VARCHAR2)
    IS
    BEGIN
        BEGIN
            IF p_city_code IS NULL THEN
                FORMS_APX.FORM_TRIGGER_FAILURE('يجب إدخال المدينة');
            END IF;
            SELECT city_arb_name INTO p_city_name
              FROM cities
             WHERE ctry_cd = p_add_ctry_cd
               AND city_cd = p_city_code;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                FORMS_APX.DISPLAY_ARABIC_ERROR(18, 282);
        END;
        address_city_lookup(p_from_item, p_add_ctry_cd, p_city_code, p_city_name, p_add_crty_arbc_name);
    END city_code_logic;

    -- Source: PU UPDATE_IMPORTER (converted from IMPR1130; FORMS_DDL('COMMIT') and MESSAGE_LEVEL removed:
    -- APEX commits at the end of the request; WHEN OTHERS THEN NULL kept)
    PROCEDURE update_importer (p_port_cd IN NUMBER, p_impr_nbr IN NUMBER, p_answer IN NUMBER)
    IS
        v_msg    VARCHAR2(500);
        v_msg_cd NUMBER;
    BEGIN
        IF p_port_cd IS NOT NULL AND p_impr_nbr IS NOT NULL THEN
            IF NVL(p_answer, c_no) = c_yes THEN                    -- RET = ALERT_BUTTON1
                BEGIN
                    lib_usr.impr_utilities.update_importers_names(p_port_cd, p_impr_nbr, v_msg_cd, v_msg);
                    FORMS_APX.MESSAGE(v_msg);
                EXCEPTION
                    WHEN OTHERS THEN NULL;
                END;
            END IF;
        END IF;
        -- :GLOBAL.PORT_CD / IMPR_NBR / EXEC_QUERY_NOW -> APEX: reload of the page with the same P0_PAGE_PK
    END update_importer;

    -- =========================================================================
    -- 4 APEX ENTRY POINTS (spec order)
    -- =========================================================================

    -- ------------------------------------------------------------------ f345 HELPERS
    PROCEDURE READ_ONLY_FLAGS (P_ROW_ID                   IN  VARCHAR2,
                               P_PRSNL_IMPR               IN  NUMBER,
                               P_IMPR_TYPE_CD             IN  NUMBER,
                               P_BUS_ID_TYPE_CD           IN  NUMBER,
                               P_COMM_RGSTRTN_TYPE        IN  NUMBER,
                               P_BUS_ID                   IN  VARCHAR2,
                               P_BUS_ID_BRNCH             IN  VARCHAR2,
                               P_BUS_ID_EXPRD_DT          IN  VARCHAR2,
                               P_CREATION_FLAG            IN  NUMBER,
                               G_ALLOW_MCI                IN  VARCHAR2,
                               P_COMM_RGSTRTN_TYPE_LOCKED OUT VARCHAR2,
                               P_CTRY_CD_LOCKED           OUT VARCHAR2,
                               P_ADD_CTRY_CD_LOCKED       OUT VARCHAR2,
                               P_CITY_CODE_OF_ID_LOCKED   OUT VARCHAR2,
                               P_BUS_ID_LOCKED            OUT VARCHAR2,
                               P_BUS_ID_BRNCH_LOCKED      OUT VARCHAR2,
                               P_BUS_ID_EXPRD_DT_LOCKED   OUT VARCHAR2,
                               P_REGISTER_ITEMS_LOCKED    OUT VARCHAR2)
    IS
    BEGIN
        P_COMM_RGSTRTN_TYPE_LOCKED := flag(COMM_RGSTRTN_TYPE_IS_READ_ONLY(P_ROW_ID, P_IMPR_TYPE_CD, P_BUS_ID_TYPE_CD));
        P_CTRY_CD_LOCKED           := flag(CTRY_CD_IS_READ_ONLY(P_ROW_ID, P_IMPR_TYPE_CD, P_BUS_ID_TYPE_CD));
        P_ADD_CTRY_CD_LOCKED       := flag(ADD_CTRY_CD_IS_READ_ONLY(P_ROW_ID, P_IMPR_TYPE_CD, P_BUS_ID_TYPE_CD));
        P_CITY_CODE_OF_ID_LOCKED   := flag(CITY_CODE_OF_ID_IS_READ_ONLY(P_ROW_ID, P_IMPR_TYPE_CD, P_BUS_ID_TYPE_CD));
        P_BUS_ID_LOCKED            := flag(BUS_ID_IS_READ_ONLY(P_ROW_ID, P_IMPR_TYPE_CD, P_BUS_ID_TYPE_CD, P_CREATION_FLAG));
        P_BUS_ID_BRNCH_LOCKED      := flag(BUS_ID_BRNCH_IS_READ_ONLY(P_ROW_ID, P_PRSNL_IMPR, P_IMPR_TYPE_CD, P_BUS_ID_TYPE_CD,
                                                                     P_COMM_RGSTRTN_TYPE, P_CREATION_FLAG));
        P_BUS_ID_EXPRD_DT_LOCKED   := flag(BUS_ID_EXPRD_DT_IS_READ_ONLY(P_ROW_ID, P_IMPR_TYPE_CD, P_BUS_ID_TYPE_CD,
                                                                        P_COMM_RGSTRTN_TYPE, P_BUS_ID, P_BUS_ID_BRNCH,
                                                                        P_BUS_ID_EXPRD_DT, G_ALLOW_MCI));
        P_REGISTER_ITEMS_LOCKED    := flag(REGISTER_ITEMS_IS_READ_ONLY(P_ROW_ID, P_IMPR_TYPE_CD, P_BUS_ID_TYPE_CD,
                                                                       P_COMM_RGSTRTN_TYPE, P_BUS_ID, P_BUS_ID_BRNCH,
                                                                       G_ALLOW_MCI));
    END READ_ONLY_FLAGS;

    -- = IMPR1110 P0_PAGE_PK_CHECK
    PROCEDURE P0_PAGE_PK_CHECK (P_PAGE_PK      IN OUT VARCHAR2,
                                P_CURR_PORT_CD IN     NUMBER)
    IS
        v_cnt NUMBER;
    BEGIN
        IF P_PAGE_PK IS NULL THEN
            RETURN;
        END IF;
        P_PAGE_PK := FORMS_APX.ROWID_FROM_URL(P_PAGE_PK);   -- URL-safe ROWID of page 113001 -> ROWID
        SELECT COUNT(*)
          INTO v_cnt
          FROM importers i
         WHERE i.ROWID   = CHARTOROWID(P0_PAGE_PK_CHECK.P_PAGE_PK)
           AND i.port_cd = P0_PAGE_PK_CHECK.P_CURR_PORT_CD;
        IF v_cnt = 0 THEN
            P_PAGE_PK := NULL;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN               -- ORA-01410 invalid ROWID, ORA-01445 ...: not a key of this page
            P_PAGE_PK := NULL;
    END P0_PAGE_PK_CHECK;

    -- = IMPR1110 IMPORTER_ROW_ID
    FUNCTION IMPORTER_ROW_ID (P_IMPR_NBR     IN NUMBER,
                              P_CURR_PORT_CD IN NUMBER) RETURN VARCHAR2
    IS
        v_row_id VARCHAR2(18);
    BEGIN
        SELECT MAX(ROWIDTOCHAR(i.ROWID))
          INTO v_row_id
          FROM importers i
         WHERE i.port_cd  = IMPORTER_ROW_ID.P_CURR_PORT_CD
           AND i.impr_nbr = IMPORTER_ROW_ID.P_IMPR_NBR;
        RETURN v_row_id;
    END IMPORTER_ROW_ID;

    -- = IMPR1110 PARAMETERS_ENTRY
    PROCEDURE PARAMETERS_ENTRY (APP_P_PRSNL_IMPR IN OUT VARCHAR2,
                                APP_P_LETTER_NBR IN OUT VARCHAR2,
                                P_PRSNL_IMPR     IN OUT VARCHAR2,
                                P_LETTER_NBR     IN OUT VARCHAR2)
    IS
    BEGIN
        P_PRSNL_IMPR     := NVL(APP_P_PRSNL_IMPR, P_PRSNL_IMPR);
        P_LETTER_NBR     := NVL(APP_P_LETTER_NBR, P_LETTER_NBR);
        APP_P_PRSNL_IMPR := NULL;
        APP_P_LETTER_NBR := NULL;
    END PARAMETERS_ENTRY;

    -- ------------------------------------------------------------------ FORM LEVEL
    PROCEDURE WHEN_NEW_FORM_INSTANCE (P_ROW_ID             IN     VARCHAR2,
                                      P_IMPR_TYPE_CD       IN     importers.impr_type_cd%TYPE,
                                      P_BUS_ID_TYPE_CD     IN     importers.bus_id_type_cd%TYPE,
                                      P_CTRY_CD            IN OUT importers.ctry_cd%TYPE,
                                      P_CRTY_ARBC_NAME     IN OUT VARCHAR2,
                                      P_ADD_CTRY_CD        IN OUT importers.add_ctry_cd%TYPE,
                                      P_ADD_CRTY_ARBC_NAME IN OUT VARCHAR2,
                                      P_CURR_PORT_CD       IN     NUMBER,
                                      G_ALLOW_MCI          OUT    VARCHAR2,
                                      G_ALLOW_MOI          OUT    VARCHAR2)
    IS
    BEGIN
        -- :GLOBAL.allow_mci / allow_moi from SC_PORT_SETTING (one block: a missing ALLOW_MCI row skips ALLOW_MOI)
        G_ALLOW_MCI := '0';
        G_ALLOW_MOI := '0';
        BEGIN
            SELECT var_value INTO WHEN_NEW_FORM_INSTANCE.G_ALLOW_MCI
              FROM sc_port_setting
             WHERE sysobj_id = 24 AND var_name = 'ALLOW_MCI'
               AND port_cd   = WHEN_NEW_FORM_INSTANCE.P_CURR_PORT_CD;
            SELECT var_value INTO WHEN_NEW_FORM_INSTANCE.G_ALLOW_MOI
              FROM sc_port_setting
             WHERE sysobj_id = 24 AND var_name = 'ALLOW_MOI'
               AND port_cd   = WHEN_NEW_FORM_INSTANCE.P_CURR_PORT_CD;
        EXCEPTION
            WHEN OTHERS THEN NULL;
        END;
        G_ALLOW_MCI := NVL(G_ALLOW_MCI, '0');
        G_ALLOW_MOI := NVL(G_ALLOW_MOI, '0');
        -- APEX-DA: Make_Field_Entrable BUS_ID_EXPRD_DT / CITY_CODE_OF_ID FALSE (rules)
        -- :global.Exec_Query_Now / PORT_CD / IMPR_NBR / VALID reset: not needed (no globals in APEX)
        -- SUPPORT_ENTRY CALL_FORM (P_MODE 0) and, with a letter, OPEN_FORM (edit mode): page 9001 opened by the
        -- page DAs "SUPPORT_ENTRY" (SUPPORT_ENTRY.OPEN_DIALOG); PORT_CD is always read-only in APEX
        IF new_record(P_ROW_ID) THEN
            BEGIN
                IF P_IMPR_TYPE_CD = 4 AND P_BUS_ID_TYPE_CD IN (3, 5) THEN
                    P_CTRY_CD        := 100;
                    -- APEX-DA: SET_ITEM_PROPERTY('CTRY_CD', ENABLED, PROPERTY_FALSE) (rule CTRY_CD_IS_READ_ONLY)
                    P_CRTY_ARBC_NAME := country_name(100);
                END IF;
                P_ADD_CTRY_CD        := 100;
                -- APEX-DA: SET_ITEM_PROPERTY('ADD_CTRY_CD', ENABLED, PROPERTY_FALSE) (rule ADD_CTRY_CD_IS_READ_ONLY)
                P_ADD_CRTY_ARBC_NAME := country_name(100);
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    FORMS_APX.DISPLAY_ARABIC_ERROR(18, 15);
            END;
        END IF;
    END WHEN_NEW_FORM_INSTANCE;

    -- ------------------------------------------------------------------ BLOCK IMPORTERS - query
    PROCEDURE POST_QUERY (P_PORT_CD            IN     importers.port_cd%TYPE,
                          P_IMPR_NBR           IN     importers.impr_nbr%TYPE,
                          P_BUS_ID_STATUS      IN     importers.bus_id_status%TYPE,
                          P_IMPR_TYPE_CD       IN     importers.impr_type_cd%TYPE,
                          P_BUS_ID_TYPE_CD     IN     importers.bus_id_type_cd%TYPE,
                          P_CTRY_CD            IN     importers.ctry_cd%TYPE,
                          P_CITY_CODE_OF_ID    IN     importers.city_code_of_id%TYPE,
                          P_CTRY_CD_OF_ID      IN     importers.ctry_cd_of_id%TYPE,
                          P_ADD_CTRY_CD        IN     importers.add_ctry_cd%TYPE,
                          P_CITY_CODE          IN     importers.city_code%TYPE,
                          P_SUSPN_STATUS       OUT    VARCHAR2,
                          P_STATUS_DESC        OUT    VARCHAR2,
                          P_PORT_NAME          OUT    VARCHAR2,
                          P_IMPR_TYPE_NAME     OUT    VARCHAR2,
                          P_BUS_ID_TYPE_NAME   OUT    VARCHAR2,
                          P_CRTY_ARBC_NAME     OUT    VARCHAR2,
                          P_ID_CITY_NAME       OUT    VARCHAR2,
                          P_ID_MINS_COMM_CD    OUT    NUMBER,
                          P_ADD_CRTY_ARBC_NAME OUT    VARCHAR2,
                          P_CITY_NAME          OUT    VARCHAR2)
    IS
    BEGIN
        IF P_IMPR_NBR IS NOT NULL THEN
            IF lib_usr.impr.impr_suspended(P_PORT_CD, P_IMPR_NBR, FORMS_APX.CUR_HIJ_DATE) = 1 THEN
                P_SUSPN_STATUS := 'موقوف';
            ELSE
                P_SUSPN_STATUS := 'غير موقوف';
            END IF;
        END IF;
        -- APEX-DA: Make_Field_Entrable by IMPR_TYPE_CD (rules: CTRY_CD, ADD_CTRY_CD, CITY_CODE_OF_ID,
        --          BUS_ID_BRNCH, BUS_ID _IS_READ_ONLY on a saved record)
        BEGIN
            SELECT status_desc
              INTO POST_QUERY.P_STATUS_DESC
              FROM mci_bus_id_status
             WHERE bus_id_status LIKE POST_QUERY.P_BUS_ID_STATUS;
        EXCEPTION
            WHEN OTHERS THEN NULL;
        END;

        -- CGFK$QRY_LOOKUP_DATA. Des$Form_errors.PUSH without RAISE_FAILURE -> message; "<p1> must be entered"
        -- with RAISE_FAILURE -> error. SET_RECORD_PROPERTY(QUERY_STATUS): not needed.
        IF P_PORT_CD IS NOT NULL THEN
            BEGIN
                SELECT l_sdp.port_name INTO POST_QUERY.P_PORT_NAME
                  FROM sd_ports l_sdp
                 WHERE l_sdp.port_cd = POST_QUERY.P_PORT_CD;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    FORMS_APX.MESSAGE(FORMS_APX.CG_MESSAGE('This <p1> does not exist', 'رمز الجمــــــــــــــرك'));
            END;
        END IF;
        IF P_IMPR_TYPE_CD IS NOT NULL OR P_BUS_ID_TYPE_CD IS NOT NULL THEN
            BEGIN
                SELECT it.impr_type_name, bit.bus_id_type_name
                  INTO POST_QUERY.P_IMPR_TYPE_NAME, POST_QUERY.P_BUS_ID_TYPE_NAME
                  FROM impr_type_id_types itidt, impr_types it, bus_id_types bit
                 WHERE itidt.bus_id_type_cd = POST_QUERY.P_BUS_ID_TYPE_CD
                   AND itidt.impr_type_cd   = POST_QUERY.P_IMPR_TYPE_CD
                   AND it.impr_type_cd      = itidt.impr_type_cd
                   AND bit.bus_id_type_cd   = itidt.bus_id_type_cd
                   AND ROWNUM = 1;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    FORMS_APX.MESSAGE('رمز النشاط التجاري غير صحيح - أعد إدخال البيانات');
            END;
        ELSE
            FORMS_APX.FORM_TRIGGER_FAILURE(FORMS_APX.CG_MESSAGE('<p1> must be entered', 'رمز النشاط التجارى'));
        END IF;
        IF P_CTRY_CD IS NOT NULL THEN
            BEGIN
                SELECT ctry.crty_arbc_name INTO POST_QUERY.P_CRTY_ARBC_NAME
                  FROM countries ctry
                 WHERE ctry.ctry_cd = POST_QUERY.P_CTRY_CD;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    FORMS_APX.MESSAGE('رمز الدولة غير صحيح - أعد ادخال البيانات');
            END;
        END IF;
        IF P_CITY_CODE_OF_ID IS NOT NULL OR P_CTRY_CD_OF_ID IS NOT NULL THEN
            BEGIN
                SELECT id_city.city_arb_name, id_city.mins_comm_cd
                  INTO POST_QUERY.P_ID_CITY_NAME, POST_QUERY.P_ID_MINS_COMM_CD
                  FROM cities id_city
                 WHERE (id_city.city_cd = POST_QUERY.P_CITY_CODE_OF_ID
                        OR (id_city.city_cd IS NULL AND POST_QUERY.P_CITY_CODE_OF_ID IS NULL))
                   AND (id_city.ctry_cd = POST_QUERY.P_CTRY_CD_OF_ID
                        OR (id_city.ctry_cd IS NULL AND POST_QUERY.P_CTRY_CD_OF_ID IS NULL))
                   AND ROWNUM = 1;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    FORMS_APX.MESSAGE('خطأ في رمز مدينة مصدر الرقم الإستدلالي');
            END;
        END IF;
        IF P_ADD_CTRY_CD IS NOT NULL OR P_CITY_CODE IS NOT NULL THEN
            BEGIN
                SELECT add_city.city_arb_name, l_ctry.crty_arbc_name
                  INTO POST_QUERY.P_CITY_NAME, POST_QUERY.P_ADD_CRTY_ARBC_NAME
                  FROM cities add_city, countries l_ctry
                 WHERE add_city.ctry_cd = POST_QUERY.P_ADD_CTRY_CD
                   AND (add_city.city_cd = POST_QUERY.P_CITY_CODE
                        OR (add_city.city_cd IS NULL AND POST_QUERY.P_CITY_CODE IS NULL))
                   AND l_ctry.ctry_cd = add_city.ctry_cd
                   AND ROWNUM = 1;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    FORMS_APX.MESSAGE('خطأ في رمز مدينة عنوان المستورد');
            END;
        ELSE
            FORMS_APX.FORM_TRIGGER_FAILURE(FORMS_APX.CG_MESSAGE('<p1> must be entered',
                                                                'دولــــــــة الإقامـــــة,المدينـــــــــــــــــــــة'));
        END IF;
        -- CGFK$RESET_BLOCK_WHERE_CLAUSE: not needed (the search page has its own SQL)
    END POST_QUERY;

    -- ------------------------------------------------------------------ BLOCK IMPORTERS - record
    PROCEDURE WHEN_CREATE_RECORD (P_PRSNL_IMPR     IN     NUMBER,
                                  P_PORT_CD        OUT    importers.port_cd%TYPE,
                                  P_PORT_NAME      OUT    VARCHAR2,
                                  P_IMPR_TYPE_CD   IN OUT importers.impr_type_cd%TYPE,
                                  P_IMPR_TYPE_NAME IN OUT VARCHAR2,
                                  P_CURR_PORT_CD   IN     NUMBER)
    IS
    BEGIN
        P_PORT_CD := P_CURR_PORT_CD;
        SELECT port_name
          INTO WHEN_CREATE_RECORD.P_PORT_NAME
          FROM sd_ports
         WHERE port_cd = WHEN_CREATE_RECORD.P_CURR_PORT_CD;
        IF P_PRSNL_IMPR = 1 THEN
            P_IMPR_TYPE_CD := 4;
            SELECT impr_type_name
              INTO WHEN_CREATE_RECORD.P_IMPR_TYPE_NAME
              FROM impr_types
             WHERE impr_type_cd = WHEN_CREATE_RECORD.P_IMPR_TYPE_CD;
        END IF;
        -- APEX-DA: Make_Field_Entrable (IMPR_TYPE_CD, CITY_CODE_OF_ID, BUS_ID_BRNCH, CTRY_CD, ADD_CTRY_CD, BUS_ID,
        --          COMM_RGSTRTN_TYPE, register items, BUS_ID_EXPRD_DT, ARBC_IMPR_NAME) -> rules
        -- :Global.Ins := 0: never read (dropped)
    END WHEN_CREATE_RECORD;

    PROCEDURE PRE_RECORD (P_IMPR_NBR_PARENT  IN     importers.impr_nbr_parent%TYPE,
                          P_IMPR_NAME_PARENT IN OUT VARCHAR2,
                          P_CURR_PORT_CD     IN     NUMBER)
    IS
        CURSOR cur_parent_name IS
            SELECT arbc_impr_name
              FROM importers
             WHERE impr_nbr = PRE_RECORD.P_IMPR_NBR_PARENT
               AND port_cd  = PRE_RECORD.P_CURR_PORT_CD;
    BEGIN
        IF P_IMPR_NBR_PARENT IS NOT NULL THEN
            OPEN cur_parent_name;
            FETCH cur_parent_name INTO P_IMPR_NAME_PARENT;    -- not found: the item keeps its value (FETCH)
            IF cur_parent_name%NOTFOUND THEN
                FORMS_APX.DISPLAY_ARABIC_INFO(9, 150);        -- DispArbMsg(9, 150, 'ERROR') without raise
            END IF;
            CLOSE cur_parent_name;
        END IF;
    END PRE_RECORD;

    -- ------------------------------------------------------------------ PORT_CD
    FUNCTION PORT_CD_VALIDATION (P_PORT_CD IN importers.port_cd%TYPE) RETURN VARCHAR2
    IS
        v_port_name VARCHAR2(100);
    BEGIN
        port_cd_logic(P_PORT_CD, v_port_name);
        RETURN NULL;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN error_text(SQLCODE, SQLERRM, 'I');
    END PORT_CD_VALIDATION;

    PROCEDURE PORT_CD_WHEN_VALIDATE_ITEM (P_PORT_CD   IN     importers.port_cd%TYPE,
                                          P_PORT_NAME IN OUT VARCHAR2)
    IS
    BEGIN
        port_cd_logic(P_PORT_CD, P_PORT_NAME);
    END PORT_CD_WHEN_VALIDATE_ITEM;

    -- ------------------------------------------------------------------ IMPR_NBR (= IMPR1110)
    FUNCTION IMPR_NBR_VALIDATION (P_ROW_ID   IN VARCHAR2,
                                  P_PORT_CD  IN importers.port_cd%TYPE,
                                  P_IMPR_NBR IN importers.impr_nbr%TYPE) RETURN VARCHAR2
    IS
        rec_count NUMBER;
    BEGIN
        IF new_record(P_ROW_ID) AND P_IMPR_NBR IS NOT NULL THEN
            SELECT COUNT(*) INTO rec_count
              FROM importers
             WHERE port_cd  = IMPR_NBR_VALIDATION.P_PORT_CD
               AND impr_nbr = IMPR_NBR_VALIDATION.P_IMPR_NBR;
            IF rec_count = 0 THEN
                RETURN FORMS_APX.ARABIC_MESSAGE(9, 150);     -- DispArbMsg(9, 150, 'INFORMATION') + FORM_TRIGGER_FAILURE
            END IF;
            -- found: :global.PORT_CD / IMPR_NBR / Exec_Query_Now -> request EXECUTE_QUERY (IMPORTER_ROW_ID)
        END IF;
        RETURN NULL;
    END IMPR_NBR_VALIDATION;

    FUNCTION IMPR_NBR_IS_READ_ONLY (P_ROW_ID IN VARCHAR2) RETURN BOOLEAN
    IS
    BEGIN
        RETURN NOT new_record(P_ROW_ID);
    END IMPR_NBR_IS_READ_ONLY;

    -- ------------------------------------------------------------------ IMPR_TYPE_CD
    FUNCTION IMPR_TYPE_CD_VALIDATION (P_IMPR_TYPE_CD   IN importers.impr_type_cd%TYPE,
                                      P_BUS_ID_TYPE_CD IN importers.bus_id_type_cd%TYPE,
                                      P_CTRY_CD        IN importers.ctry_cd%TYPE,
                                      P_CURR_PORT_CD   IN NUMBER) RETURN VARCHAR2
    IS
        v_impr_type_cd       NUMBER        := P_IMPR_TYPE_CD;
        v_impr_type_name     VARCHAR2(100);
        v_bus_id_type_cd     NUMBER        := P_BUS_ID_TYPE_CD;
        v_bus_id_type_name   VARCHAR2(100);
        v_bus_id             VARCHAR2(15);
        v_ctry_cd            NUMBER        := P_CTRY_CD;
        v_crty_arbc_name     VARCHAR2(100);
        v_add_ctry_cd        NUMBER;
        v_add_crty_arbc_name VARCHAR2(100);
    BEGIN
        impr_type_cd_logic(FALSE, P_CURR_PORT_CD, v_impr_type_cd, v_impr_type_name, v_bus_id_type_cd, v_bus_id_type_name,
                           v_bus_id, v_ctry_cd, v_crty_arbc_name, v_add_ctry_cd, v_add_crty_arbc_name);
        RETURN NULL;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN error_text(SQLCODE, SQLERRM, 'I');
    END IMPR_TYPE_CD_VALIDATION;

    PROCEDURE IMPR_TYPE_CD_VALIDATE_ITEM (P_IMPR_TYPE_CD       IN OUT importers.impr_type_cd%TYPE,
                                          P_IMPR_TYPE_NAME     IN OUT VARCHAR2,
                                          P_BUS_ID_TYPE_CD     IN OUT importers.bus_id_type_cd%TYPE,
                                          P_BUS_ID_TYPE_NAME   IN OUT VARCHAR2,
                                          P_BUS_ID             IN OUT importers.bus_id%TYPE,
                                          P_CTRY_CD            IN OUT importers.ctry_cd%TYPE,
                                          P_CRTY_ARBC_NAME     IN OUT VARCHAR2,
                                          P_ADD_CTRY_CD        IN OUT importers.add_ctry_cd%TYPE,
                                          P_ADD_CRTY_ARBC_NAME IN OUT VARCHAR2,
                                          P_CURR_PORT_CD       IN     NUMBER)
    IS
    BEGIN
        impr_type_cd_logic(TRUE, P_CURR_PORT_CD, P_IMPR_TYPE_CD, P_IMPR_TYPE_NAME, P_BUS_ID_TYPE_CD, P_BUS_ID_TYPE_NAME,
                           P_BUS_ID, P_CTRY_CD, P_CRTY_ARBC_NAME, P_ADD_CTRY_CD, P_ADD_CRTY_ARBC_NAME);
    END IMPR_TYPE_CD_VALIDATE_ITEM;

    FUNCTION IMPR_TYPE_CD_IS_READ_ONLY (P_ROW_ID     IN VARCHAR2,
                                        P_PRSNL_IMPR IN NUMBER) RETURN BOOLEAN
    IS
    BEGIN
        -- UpdateAllowed = false; WHEN-CREATE-RECORD locks it for personal importers (PRSNL_IMPR = 1)
        RETURN NOT new_record(P_ROW_ID) OR NVL(P_PRSNL_IMPR, 0) = 1;
    END IMPR_TYPE_CD_IS_READ_ONLY;

    -- ------------------------------------------------------------------ BUS_ID_EXPRD_DT
    FUNCTION BUS_ID_EXPRD_DT_VALIDATION (P_BUS_ID_EXPRD_DT IN VARCHAR2) RETURN VARCHAR2
    IS
    BEGIN
        check_hijri_date(P_BUS_ID_EXPRD_DT);
        RETURN NULL;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN error_text(SQLCODE, SQLERRM, 'I');
    END BUS_ID_EXPRD_DT_VALIDATION;

    FUNCTION BUS_ID_EXPRD_DT_IS_READ_ONLY (P_ROW_ID            IN VARCHAR2,
                                           P_IMPR_TYPE_CD      IN NUMBER,
                                           P_BUS_ID_TYPE_CD    IN NUMBER,
                                           P_COMM_RGSTRTN_TYPE IN NUMBER,
                                           P_BUS_ID            IN VARCHAR2,
                                           P_BUS_ID_BRNCH      IN VARCHAR2,
                                           P_BUS_ID_EXPRD_DT   IN VARCHAR2,
                                           G_ALLOW_MCI         IN VARCHAR2) RETURN BOOLEAN
    IS
    BEGIN
        IF NOT new_record(P_ROW_ID) OR P_IMPR_TYPE_CD IS NULL THEN
            RETURN TRUE;                       -- WHEN-NEW-RECORD-INSTANCE (FALSE until IMPR_TYPE_CD is validated)
        END IF;
        -- Ministry data: stays read-only while it has a value (PRE-INSERT enables it again when it is empty)
        RETURN ministry_data(P_IMPR_TYPE_CD, P_BUS_ID_TYPE_CD, G_ALLOW_MCI)
               AND P_BUS_ID_EXPRD_DT IS NOT NULL
               AND NOT register_unlocked(P_IMPR_TYPE_CD, P_BUS_ID_TYPE_CD, P_COMM_RGSTRTN_TYPE, P_BUS_ID, P_BUS_ID_BRNCH);
    END BUS_ID_EXPRD_DT_IS_READ_ONLY;

    -- ------------------------------------------------------------------ BUS_ID_TYPE_CD
    FUNCTION BUS_ID_TYPE_CD_VALIDATION (P_IMPR_TYPE_CD   IN importers.impr_type_cd%TYPE,
                                        P_BUS_ID_TYPE_CD IN importers.bus_id_type_cd%TYPE,
                                        P_CTRY_CD        IN importers.ctry_cd%TYPE) RETURN VARCHAR2
    IS
    BEGIN
        bus_id_type_cd_logic(P_IMPR_TYPE_CD, P_CTRY_CD, P_BUS_ID_TYPE_CD);
        RETURN NULL;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN error_text(SQLCODE, SQLERRM, 'I');
    END BUS_ID_TYPE_CD_VALIDATION;

    PROCEDURE BUS_ID_TYPE_CD_VALIDATE_ITEM (P_IMPR_TYPE_CD     IN     importers.impr_type_cd%TYPE,
                                            P_CTRY_CD          IN     importers.ctry_cd%TYPE,
                                            P_BUS_ID_TYPE_CD   IN     importers.bus_id_type_cd%TYPE,
                                            P_BUS_ID_TYPE_NAME IN OUT VARCHAR2)
    IS
    BEGIN
        bus_id_type_cd_logic(P_IMPR_TYPE_CD, P_CTRY_CD, P_BUS_ID_TYPE_CD);
        -- KEY-LISTVAL: :BUS_ID_TYPE_NAME := :GLOBAL.BUS_ID_TYPE_NAME (LOV_Impr_Type)
        IF P_BUS_ID_TYPE_CD IS NULL THEN
            P_BUS_ID_TYPE_NAME := NULL;
        ELSE
            BEGIN
                SELECT bus_id_type_name INTO BUS_ID_TYPE_CD_VALIDATE_ITEM.P_BUS_ID_TYPE_NAME
                  FROM bus_id_types
                 WHERE bus_id_type_cd = BUS_ID_TYPE_CD_VALIDATE_ITEM.P_BUS_ID_TYPE_CD;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    P_BUS_ID_TYPE_NAME := NULL;
            END;
        END IF;
    END BUS_ID_TYPE_CD_VALIDATE_ITEM;

    FUNCTION BUS_ID_TYPE_CD_IS_READ_ONLY (P_ROW_ID IN VARCHAR2) RETURN BOOLEAN
    IS
    BEGIN
        RETURN NOT new_record(P_ROW_ID);
    END BUS_ID_TYPE_CD_IS_READ_ONLY;

    -- ------------------------------------------------------------------ COMM_RGSTRTN_TYPE
    PROCEDURE COMM_RGSTRTN_TYPE_LIST_CHANGED (P_COMM_RGSTRTN_TYPE IN     importers.comm_rgstrtn_type%TYPE,
                                              P_BUS_ID_BRNCH      IN OUT importers.bus_id_brnch%TYPE)
    IS
    BEGIN
        IF P_COMM_RGSTRTN_TYPE = 1 THEN
            P_BUS_ID_BRNCH := NULL;
            -- APEX-DA: Make_Field_Entrable('IMPORTERS.BUS_ID_BRNCH', FALSE)
        END IF;
        -- 2: APEX-DA: Make_Field_Entrable('IMPORTERS.BUS_ID_BRNCH', TRUE)
    END COMM_RGSTRTN_TYPE_LIST_CHANGED;

    FUNCTION COMM_RGSTRTN_TYPE_IS_READ_ONLY (P_ROW_ID         IN VARCHAR2,
                                             P_IMPR_TYPE_CD   IN NUMBER,
                                             P_BUS_ID_TYPE_CD IN NUMBER) RETURN BOOLEAN
    IS
    BEGIN
        -- new record: WHEN-CREATE-RECORD TRUE, then IMPR_TYPE_CD WVI TRUE only for identity type 2;
        -- saved record: editable (no trigger of POST-QUERY / WHEN-NEW-RECORD-INSTANCE changes it)
        RETURN new_record(P_ROW_ID) AND P_IMPR_TYPE_CD IS NOT NULL AND NVL(P_BUS_ID_TYPE_CD, 0) <> 2;
    END COMM_RGSTRTN_TYPE_IS_READ_ONLY;

    FUNCTION COMM_RGSTRTN_TYPE_IS_REQUIRED (P_ROW_ID         IN VARCHAR2,
                                            P_BUS_ID_TYPE_CD IN NUMBER) RETURN BOOLEAN
    IS
    BEGIN
        RETURN new_record(P_ROW_ID) AND P_BUS_ID_TYPE_CD = 2;
    END COMM_RGSTRTN_TYPE_IS_REQUIRED;

    -- ------------------------------------------------------------------ CTRY_CD
    FUNCTION CTRY_CD_VALIDATION (P_IMPR_TYPE_CD IN importers.impr_type_cd%TYPE,
                                 P_CTRY_CD      IN importers.ctry_cd%TYPE) RETURN VARCHAR2
    IS
        v_crty_arbc_name VARCHAR2(100);
    BEGIN
        ctry_cd_logic(P_IMPR_TYPE_CD, P_CTRY_CD, v_crty_arbc_name);
        RETURN NULL;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN error_text(SQLCODE, SQLERRM, 'I');
    END CTRY_CD_VALIDATION;

    PROCEDURE CTRY_CD_WHEN_VALIDATE_ITEM (P_IMPR_TYPE_CD   IN     importers.impr_type_cd%TYPE,
                                          P_CTRY_CD        IN     importers.ctry_cd%TYPE,
                                          P_CRTY_ARBC_NAME IN OUT VARCHAR2)
    IS
    BEGIN
        ctry_cd_logic(P_IMPR_TYPE_CD, P_CTRY_CD, P_CRTY_ARBC_NAME);
    END CTRY_CD_WHEN_VALIDATE_ITEM;

    FUNCTION CTRY_CD_IS_READ_ONLY (P_ROW_ID         IN VARCHAR2,
                                   P_IMPR_TYPE_CD   IN NUMBER,
                                   P_BUS_ID_TYPE_CD IN NUMBER) RETURN BOOLEAN
    IS
    BEGIN
        IF new_record(P_ROW_ID) THEN           -- IMPR_TYPE_CD.WHEN-VALIDATE-ITEM
            RETURN P_IMPR_TYPE_CD IN (1, 2, 5, 8, 11, 14, 16, 17, 18, 20)
                   OR (P_IMPR_TYPE_CD = 9 AND NVL(P_BUS_ID_TYPE_CD, 6) = 6);
        END IF;
        RETURN P_IMPR_TYPE_CD IN (1, 2, 5, 8, 11, 13, 14)   -- POST-QUERY (13 also, 16-20 not listed: kept)
               OR (P_IMPR_TYPE_CD = 9 AND P_BUS_ID_TYPE_CD = 6);
    END CTRY_CD_IS_READ_ONLY;

    -- ------------------------------------------------------------------ CITY_CODE_OF_ID
    FUNCTION CITY_CODE_OF_ID_CONFIRM_TEXT (P_IMPR_TYPE_CD    IN importers.impr_type_cd%TYPE,
                                           P_CTRY_CD         IN importers.ctry_cd%TYPE,
                                           P_BUS_ID_TYPE_CD  IN importers.bus_id_type_cd%TYPE,
                                           P_BUS_ID          IN importers.bus_id%TYPE,
                                           P_CITY_CODE_OF_ID IN importers.city_code_of_id%TYPE,
                                           P_CTRY_CD_OF_ID   IN importers.ctry_cd_of_id%TYPE) RETURN VARCHAR2
    IS
        v_mins NUMBER;
    BEGIN
        IF P_BUS_ID_TYPE_CD = 2 AND LENGTH(P_BUS_ID) <= 6 THEN
            RETURN message_9_120(full_bus_id(P_BUS_ID, P_CITY_CODE_OF_ID,
                                             ctry_cd_of_id_value(P_IMPR_TYPE_CD, P_CTRY_CD, P_CITY_CODE_OF_ID, P_CTRY_CD_OF_ID),
                                             v_mins));
        END IF;
        RETURN NULL;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;                       -- the second FOS action raises the Forms error
    END CITY_CODE_OF_ID_CONFIRM_TEXT;

    FUNCTION CITY_CODE_OF_ID_VALIDATION (P_ROW_ID          IN VARCHAR2,
                                         P_IMPR_TYPE_CD    IN importers.impr_type_cd%TYPE,
                                         P_CTRY_CD         IN importers.ctry_cd%TYPE,
                                         P_CITY_CODE_OF_ID IN importers.city_code_of_id%TYPE,
                                         P_CTRY_CD_OF_ID   IN importers.ctry_cd_of_id%TYPE) RETURN VARCHAR2
    IS
        v_ctry_cd_of_id NUMBER := P_CTRY_CD_OF_ID;
        v_bus_id        VARCHAR2(15);
        v_mins          NUMBER;
        v_city_name     VARCHAR2(100);
    BEGIN
        city_code_of_id_logic(FALSE, P_IMPR_TYPE_CD, P_CTRY_CD, NULL, c_yes, P_CITY_CODE_OF_ID,
                              v_ctry_cd_of_id, v_bus_id, v_mins, v_city_name);
        RETURN NULL;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN error_text(SQLCODE, SQLERRM, CASE WHEN new_record(P_ROW_ID) THEN 'I' ELSE 'U' END);
    END CITY_CODE_OF_ID_VALIDATION;

    PROCEDURE CITY_CODE_OF_ID_VALIDATE_ITEM (P_ROW_ID          IN     VARCHAR2,
                                             P_IMPR_TYPE_CD    IN     importers.impr_type_cd%TYPE,
                                             P_CTRY_CD         IN     importers.ctry_cd%TYPE,
                                             P_BUS_ID_TYPE_CD  IN     importers.bus_id_type_cd%TYPE,
                                             P_ANSWER          IN     NUMBER,
                                             P_CITY_CODE_OF_ID IN     importers.city_code_of_id%TYPE,
                                             P_CTRY_CD_OF_ID   IN OUT importers.ctry_cd_of_id%TYPE,
                                             P_BUS_ID          IN OUT importers.bus_id%TYPE,
                                             P_ID_MINS_COMM_CD IN OUT NUMBER,
                                             P_ID_CITY_NAME    IN OUT VARCHAR2)
    IS
    BEGIN
        -- P_ROW_ID: kept for the CGSF$CLRLU rule of CTRY_CD_OF_ID.WHEN-VALIDATE-ITEM (status NEW returns; an
        -- APEX record being edited is always INSERT / CHANGED, so the lookups are cleared)
        city_code_of_id_logic(TRUE, P_IMPR_TYPE_CD, P_CTRY_CD, P_BUS_ID_TYPE_CD, P_ANSWER, P_CITY_CODE_OF_ID,
                              P_CTRY_CD_OF_ID, P_BUS_ID, P_ID_MINS_COMM_CD, P_ID_CITY_NAME);
    END CITY_CODE_OF_ID_VALIDATE_ITEM;

    FUNCTION CITY_CODE_OF_ID_IS_READ_ONLY (P_ROW_ID         IN VARCHAR2,
                                           P_IMPR_TYPE_CD   IN NUMBER,
                                           P_BUS_ID_TYPE_CD IN NUMBER) RETURN BOOLEAN
    IS
    BEGIN
        -- WHEN-NEW-RECORD-INSTANCE FALSE; IMPR_TYPE_CD WVI TRUE only for type 9 with an identity type other than 6
        RETURN NOT (new_record(P_ROW_ID) AND P_IMPR_TYPE_CD = 9 AND NVL(P_BUS_ID_TYPE_CD, 6) <> 6);
    END CITY_CODE_OF_ID_IS_READ_ONLY;

    -- ------------------------------------------------------------------ NATIONAL_NBR
    FUNCTION NATIONAL_NBR_VALIDATION (P_NATIONAL_NBR IN importers.national_nbr%TYPE) RETURN VARCHAR2
    IS
    BEGIN
        IF P_NATIONAL_NBR IS NOT NULL AND SUBSTR(P_NATIONAL_NBR, 1, 1) <> '7' THEN
            RETURN 'يجب أن يبدأ رقم المنشأة برقم "7"';          -- DISPALERT INFORMATION + FORM_TRIGGER_FAILURE
        END IF;
        RETURN NULL;
    END NATIONAL_NBR_VALIDATION;

    PROCEDURE NATIONAL_NBR_VALIDATE_ITEM (P_ROW_ID            IN     VARCHAR2,
                                          P_IMPR_TYPE_CD      IN     importers.impr_type_cd%TYPE,
                                          P_BUS_ID_TYPE_CD    IN     importers.bus_id_type_cd%TYPE,
                                          P_COMM_RGSTRTN_TYPE IN     importers.comm_rgstrtn_type%TYPE,
                                          P_NATIONAL_NBR      IN     importers.national_nbr%TYPE,
                                          P_BUS_ID            IN OUT importers.bus_id%TYPE,
                                          P_BUS_ID_BRNCH      IN OUT importers.bus_id_brnch%TYPE,
                                          P_BUS_ID_EXPRD_DT   IN OUT VARCHAR2,
                                          P_BUS_ID_ISSUE_DT   IN OUT VARCHAR2,
                                          P_ARBC_IMPR_NAME    IN OUT importers.arbc_impr_name%TYPE,
                                          P_IMPR_NAME_STD     IN OUT importers.impr_name_std%TYPE,
                                          P_IMPR_ADDRESS      IN OUT importers.impr_address%TYPE,
                                          P_IMPR_TEL_NBR      IN OUT importers.impr_tel_nbr%TYPE,
                                          P_IMPR_FAX_NBR      IN OUT importers.impr_fax_nbr%TYPE,
                                          P_IMPR_TELEX_NBR    IN OUT importers.impr_telex_nbr%TYPE,
                                          P_ACTIVITY          IN OUT importers.activity%TYPE,
                                          P_BUS_ID_STATUS     IN OUT importers.bus_id_status%TYPE,
                                          P_CITY_CODE_OF_ID   IN OUT importers.city_code_of_id%TYPE,
                                          P_LST_TRAN_DT       IN OUT VARCHAR2,
                                          P_CREATION_FLAG     IN OUT importers.creation_flag%TYPE,
                                          G_ALLOW_MCI         IN     VARCHAR2)
    IS
        v_result VARCHAR2(5000);
    BEGIN
        FORMS_APX.CHECK_ERROR(NATIONAL_NBR_VALIDATION(P_NATIONAL_NBR));
        IF P_NATIONAL_NBR IS NOT NULL
           AND new_record(P_ROW_ID)
           AND P_IMPR_TYPE_CD IN (1, 3, 5, 6, 19) AND P_BUS_ID_TYPE_CD = 2
           AND NVL(G_ALLOW_MCI, '0') = '1'
           AND P_COMM_RGSTRTN_TYPE IN (1, 2)
        THEN
            -- PU GET_MAIN_CR_DATA (type 1) / GET_BRANCH_CR_DATA (type 2): key NATIONAL_NBR when it starts with 7,
            -- else BUS_ID / BUS_ID_BRNCH; errors ignored (WHEN OTHERS THEN NULL)
            BEGIN
                IF P_COMM_RGSTRTN_TYPE = 1 THEN
                    IF SUBSTR(P_NATIONAL_NBR, 1, 1) = '7' THEN
                        v_result := mciservice.getmaincrinfocall(P_NATIONAL_NBR, 'MCIService');
                    ELSE
                        v_result := mciservice.getmaincrinfocall(P_BUS_ID, 'MCIService');
                    END IF;
                ELSE
                    IF SUBSTR(P_NATIONAL_NBR, 1, 1) = '7' THEN
                        v_result := mciservice.getbranchcrinfocall(P_NATIONAL_NBR, 'MCIService');
                    ELSE
                        v_result := mciservice.getbranchcrinfocall(P_BUS_ID_BRNCH, 'MCIService');
                    END IF;
                END IF;
                get_cr_data(v_result, P_BUS_ID, P_BUS_ID_BRNCH, P_BUS_ID_EXPRD_DT, P_BUS_ID_ISSUE_DT, P_ARBC_IMPR_NAME,
                            P_IMPR_NAME_STD, P_IMPR_ADDRESS, P_IMPR_TEL_NBR, P_IMPR_FAX_NBR, P_IMPR_TELEX_NBR,
                            P_ACTIVITY, P_BUS_ID_STATUS, P_CITY_CODE_OF_ID, P_LST_TRAN_DT, P_CREATION_FLAG);
            EXCEPTION
                WHEN OTHERS THEN NULL;
            END;
        END IF;
    END NATIONAL_NBR_VALIDATE_ITEM;

    -- ------------------------------------------------------------------ BUS_ID
    FUNCTION BUS_ID_VALIDATION (P_PORT_CD           IN importers.port_cd%TYPE,
                                P_IMPR_NBR          IN importers.impr_nbr%TYPE,
                                P_IMPR_TYPE_CD      IN importers.impr_type_cd%TYPE,
                                P_BUS_ID_TYPE_CD    IN importers.bus_id_type_cd%TYPE,
                                P_COMM_RGSTRTN_TYPE IN importers.comm_rgstrtn_type%TYPE,
                                P_CITY_CODE_OF_ID   IN importers.city_code_of_id%TYPE,
                                P_CTRY_CD_OF_ID     IN importers.ctry_cd_of_id%TYPE,
                                P_BUS_ID            IN importers.bus_id%TYPE,
                                P_BUS_ID_BRNCH      IN importers.bus_id_brnch%TYPE,
                                P_ID_MINS_COMM_CD   IN NUMBER,
                                P_CURR_PORT_CD      IN NUMBER) RETURN VARCHAR2
    IS
        v_bus_id         VARCHAR2(15)  := P_BUS_ID;
        v_mins           NUMBER        := P_ID_MINS_COMM_CD;
        v_arbc_impr_name VARCHAR2(200);
        v_impr_name_std  VARCHAR2(200);
        v_exprd_dt       VARCHAR2(30);
        v_tel            VARCHAR2(15);
        v_pob            NUMBER;
        v_zip            NUMBER;
        v_fax            VARCHAR2(15);
        v_telex          VARCHAR2(16);
    BEGIN
        bus_id_logic(FALSE, P_PORT_CD, P_IMPR_NBR, P_IMPR_TYPE_CD, P_BUS_ID_TYPE_CD, P_COMM_RGSTRTN_TYPE,
                     P_CITY_CODE_OF_ID, P_CTRY_CD_OF_ID, P_BUS_ID_BRNCH, P_CURR_PORT_CD,
                     v_bus_id, v_mins, v_arbc_impr_name, v_impr_name_std, v_exprd_dt, v_tel, v_pob, v_zip, v_fax, v_telex);
        RETURN NULL;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN error_text(SQLCODE, SQLERRM, CASE WHEN P_IMPR_NBR IS NULL THEN 'I' ELSE 'U' END);
    END BUS_ID_VALIDATION;

    PROCEDURE BUS_ID_WHEN_VALIDATE_ITEM (P_PORT_CD           IN     importers.port_cd%TYPE,
                                         P_IMPR_NBR          IN     importers.impr_nbr%TYPE,
                                         P_IMPR_TYPE_CD      IN     importers.impr_type_cd%TYPE,
                                         P_BUS_ID_TYPE_CD    IN     importers.bus_id_type_cd%TYPE,
                                         P_COMM_RGSTRTN_TYPE IN     importers.comm_rgstrtn_type%TYPE,
                                         P_CITY_CODE_OF_ID   IN     importers.city_code_of_id%TYPE,
                                         P_CTRY_CD_OF_ID     IN     importers.ctry_cd_of_id%TYPE,
                                         P_BUS_ID_BRNCH      IN     importers.bus_id_brnch%TYPE,
                                         P_BUS_ID            IN OUT importers.bus_id%TYPE,
                                         P_ID_MINS_COMM_CD   IN OUT NUMBER,
                                         P_ARBC_IMPR_NAME    IN OUT importers.arbc_impr_name%TYPE,
                                         P_IMPR_NAME_STD     IN OUT importers.impr_name_std%TYPE,
                                         P_BUS_ID_EXPRD_DT   IN OUT VARCHAR2,
                                         P_IMPR_TEL_NBR      IN OUT importers.impr_tel_nbr%TYPE,
                                         P_IMPR_POB_NBR      IN OUT importers.impr_pob_nbr%TYPE,
                                         P_IMPR_ZIP_CD       IN OUT importers.impr_zip_cd%TYPE,
                                         P_IMPR_FAX_NBR      IN OUT importers.impr_fax_nbr%TYPE,
                                         P_IMPR_TELEX_NBR    IN OUT importers.impr_telex_nbr%TYPE,
                                         P_CURR_PORT_CD      IN     NUMBER)
    IS
    BEGIN
        bus_id_logic(TRUE, P_PORT_CD, P_IMPR_NBR, P_IMPR_TYPE_CD, P_BUS_ID_TYPE_CD, P_COMM_RGSTRTN_TYPE,
                     P_CITY_CODE_OF_ID, P_CTRY_CD_OF_ID, P_BUS_ID_BRNCH, P_CURR_PORT_CD,
                     P_BUS_ID, P_ID_MINS_COMM_CD, P_ARBC_IMPR_NAME, P_IMPR_NAME_STD, P_BUS_ID_EXPRD_DT,
                     P_IMPR_TEL_NBR, P_IMPR_POB_NBR, P_IMPR_ZIP_CD, P_IMPR_FAX_NBR, P_IMPR_TELEX_NBR);
    END BUS_ID_WHEN_VALIDATE_ITEM;

    FUNCTION BUS_ID_IS_READ_ONLY (P_ROW_ID         IN VARCHAR2,
                                  P_IMPR_TYPE_CD   IN NUMBER,
                                  P_BUS_ID_TYPE_CD IN NUMBER,
                                  P_CREATION_FLAG  IN NUMBER) RETURN BOOLEAN
    IS
    BEGIN
        IF new_record(P_ROW_ID) THEN
            RETURN P_CREATION_FLAG = 3                               -- GET_CR_DATA (Ministry data fetched)
                   OR (P_IMPR_TYPE_CD = 9 AND NVL(P_BUS_ID_TYPE_CD, 6) = 6)
                   OR P_IMPR_TYPE_CD IN (16, 17, 18, 20);            -- IMPR_TYPE_CD WVI (number from a sequence)
        END IF;
        RETURN (P_IMPR_TYPE_CD = 9 AND P_BUS_ID_TYPE_CD = 6) OR P_IMPR_TYPE_CD IN (13, 14);   -- POST-QUERY
    END BUS_ID_IS_READ_ONLY;

    -- ------------------------------------------------------------------ BUS_ID_BRNCH
    FUNCTION BUS_ID_BRNCH_VALIDATION (P_PORT_CD           IN importers.port_cd%TYPE,
                                      P_IMPR_NBR          IN importers.impr_nbr%TYPE,
                                      P_IMPR_TYPE_CD      IN importers.impr_type_cd%TYPE,
                                      P_BUS_ID_TYPE_CD    IN importers.bus_id_type_cd%TYPE,
                                      P_COMM_RGSTRTN_TYPE IN importers.comm_rgstrtn_type%TYPE,
                                      P_CTRY_CD           IN importers.ctry_cd%TYPE,
                                      P_BUS_ID            IN importers.bus_id%TYPE,
                                      P_BUS_ID_BRNCH      IN importers.bus_id_brnch%TYPE) RETURN VARCHAR2
    IS
        v_bus_id_brnch   VARCHAR2(10)  := P_BUS_ID_BRNCH;
        v_arbc_impr_name VARCHAR2(200);
        v_impr_name_std  VARCHAR2(200);
        v_exprd_dt       VARCHAR2(30);
        v_tel            VARCHAR2(15);
        v_pob            NUMBER;
        v_zip            NUMBER;
        v_fax            VARCHAR2(15);
        v_telex          VARCHAR2(16);
    BEGIN
        bus_id_brnch_logic(FALSE, P_PORT_CD, P_IMPR_NBR, P_IMPR_TYPE_CD, P_BUS_ID_TYPE_CD, P_COMM_RGSTRTN_TYPE, P_CTRY_CD,
                           P_BUS_ID, v_bus_id_brnch, v_arbc_impr_name, v_impr_name_std, v_exprd_dt, v_tel, v_pob, v_zip,
                           v_fax, v_telex);
        RETURN NULL;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN error_text(SQLCODE, SQLERRM, CASE WHEN P_IMPR_NBR IS NULL THEN 'I' ELSE 'U' END);
    END BUS_ID_BRNCH_VALIDATION;

    PROCEDURE BUS_ID_BRNCH_VALIDATE_ITEM (P_PORT_CD           IN     importers.port_cd%TYPE,
                                          P_IMPR_NBR          IN     importers.impr_nbr%TYPE,
                                          P_IMPR_TYPE_CD      IN     importers.impr_type_cd%TYPE,
                                          P_BUS_ID_TYPE_CD    IN     importers.bus_id_type_cd%TYPE,
                                          P_COMM_RGSTRTN_TYPE IN     importers.comm_rgstrtn_type%TYPE,
                                          P_CTRY_CD           IN     importers.ctry_cd%TYPE,
                                          P_BUS_ID            IN     importers.bus_id%TYPE,
                                          P_BUS_ID_BRNCH      IN OUT importers.bus_id_brnch%TYPE,
                                          P_ARBC_IMPR_NAME    IN OUT importers.arbc_impr_name%TYPE,
                                          P_IMPR_NAME_STD     IN OUT importers.impr_name_std%TYPE,
                                          P_BUS_ID_EXPRD_DT   IN OUT VARCHAR2,
                                          P_IMPR_TEL_NBR      IN OUT importers.impr_tel_nbr%TYPE,
                                          P_IMPR_POB_NBR      IN OUT importers.impr_pob_nbr%TYPE,
                                          P_IMPR_ZIP_CD       IN OUT importers.impr_zip_cd%TYPE,
                                          P_IMPR_FAX_NBR      IN OUT importers.impr_fax_nbr%TYPE,
                                          P_IMPR_TELEX_NBR    IN OUT importers.impr_telex_nbr%TYPE)
    IS
    BEGIN
        bus_id_brnch_logic(TRUE, P_PORT_CD, P_IMPR_NBR, P_IMPR_TYPE_CD, P_BUS_ID_TYPE_CD, P_COMM_RGSTRTN_TYPE, P_CTRY_CD,
                           P_BUS_ID, P_BUS_ID_BRNCH, P_ARBC_IMPR_NAME, P_IMPR_NAME_STD, P_BUS_ID_EXPRD_DT, P_IMPR_TEL_NBR,
                           P_IMPR_POB_NBR, P_IMPR_ZIP_CD, P_IMPR_FAX_NBR, P_IMPR_TELEX_NBR);
    END BUS_ID_BRNCH_VALIDATE_ITEM;

    FUNCTION BUS_ID_BRNCH_IS_READ_ONLY (P_ROW_ID            IN VARCHAR2,
                                        P_PRSNL_IMPR        IN NUMBER,
                                        P_IMPR_TYPE_CD      IN NUMBER,
                                        P_BUS_ID_TYPE_CD    IN NUMBER,
                                        P_COMM_RGSTRTN_TYPE IN NUMBER,
                                        P_CREATION_FLAG     IN NUMBER) RETURN BOOLEAN
    IS
    BEGIN
        IF NOT new_record(P_ROW_ID) THEN       -- WHEN-NEW-RECORD-INSTANCE
            RETURN NOT (P_BUS_ID_TYPE_CD = 2 AND P_IMPR_TYPE_CD = 1);
        END IF;
        IF P_CREATION_FLAG = 3 THEN            -- GET_CR_DATA
            RETURN TRUE;
        END IF;
        IF P_COMM_RGSTRTN_TYPE = 1 THEN        -- COMM_RGSTRTN_TYPE.WHEN-LIST-CHANGED (after the type in navigation order)
            RETURN TRUE;
        ELSIF P_COMM_RGSTRTN_TYPE = 2 THEN
            RETURN FALSE;
        END IF;
        RETURN NVL(P_PRSNL_IMPR, 0) = 1        -- WHEN-CREATE-RECORD, IMPR_TYPE_CD WVI
               OR P_IMPR_TYPE_CD IN (2, 4, 7, 9, 10, 11, 16, 17, 18, 20);
    END BUS_ID_BRNCH_IS_READ_ONLY;

    -- ------------------------------------------------------------------ ARBC_IMPR_NAME / ENG_IMPR_NAME
    FUNCTION ARBC_IMPR_NAME_IS_READ_ONLY (P_ROW_ID       IN VARCHAR2,
                                          P_IMPR_NBR     IN NUMBER,
                                          P_CURR_PORT_CD IN NUMBER) RETURN BOOLEAN
    IS
    BEGIN
        RETURN NOT new_record(P_ROW_ID) AND P_IMPR_NBR IS NOT NULL AND declarations_exist(P_CURR_PORT_CD, P_IMPR_NBR);
    END ARBC_IMPR_NAME_IS_READ_ONLY;

    FUNCTION ENG_IMPR_NAME_VALIDATION (P_ENG_IMPR_NAME IN importers.eng_impr_name%TYPE) RETURN VARCHAR2
    IS
        v_eng_impr_name VARCHAR2(200) := P_ENG_IMPR_NAME;
    BEGIN
        eng_impr_name_logic(v_eng_impr_name);
        RETURN NULL;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN error_text(SQLCODE, SQLERRM, 'I');
    END ENG_IMPR_NAME_VALIDATION;

    PROCEDURE ENG_IMPR_NAME_VALIDATE_ITEM (P_ENG_IMPR_NAME IN OUT importers.eng_impr_name%TYPE)
    IS
    BEGIN
        eng_impr_name_logic(P_ENG_IMPR_NAME);
    END ENG_IMPR_NAME_VALIDATE_ITEM;

    FUNCTION ENG_IMPR_NAME_IS_READ_ONLY (P_ROW_ID       IN VARCHAR2,
                                         P_IMPR_NBR     IN NUMBER,
                                         P_CURR_PORT_CD IN NUMBER) RETURN BOOLEAN
    IS
    BEGIN
        RETURN ARBC_IMPR_NAME_IS_READ_ONLY(P_ROW_ID, P_IMPR_NBR, P_CURR_PORT_CD);
    END ENG_IMPR_NAME_IS_READ_ONLY;

    -- ------------------------------------------------------------------ BUS_ID_ISSUE_DT
    FUNCTION BUS_ID_ISSUE_DT_VALIDATION (P_BUS_ID_ISSUE_DT IN VARCHAR2) RETURN VARCHAR2
    IS
    BEGIN
        check_hijri_date(P_BUS_ID_ISSUE_DT);
        RETURN NULL;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN error_text(SQLCODE, SQLERRM, 'I');
    END BUS_ID_ISSUE_DT_VALIDATION;

    -- ------------------------------------------------------------------ IMPR_NBR_PARENT
    PROCEDURE IMPR_NBR_PARENT_VALIDATE_ITEM (P_IMPR_NBR_PARENT  IN     importers.impr_nbr_parent%TYPE,
                                             P_IMPR_NAME_PARENT IN OUT VARCHAR2,
                                             P_CURR_PORT_CD     IN     NUMBER)
    IS
        CURSOR cur_parent_name IS
            SELECT arbc_impr_name
              FROM importers
             WHERE impr_nbr = IMPR_NBR_PARENT_VALIDATE_ITEM.P_IMPR_NBR_PARENT
               AND port_cd  = IMPR_NBR_PARENT_VALIDATE_ITEM.P_CURR_PORT_CD;
    BEGIN
        IF P_IMPR_NBR_PARENT IS NOT NULL THEN
            OPEN cur_parent_name;
            FETCH cur_parent_name INTO P_IMPR_NAME_PARENT;
            IF cur_parent_name%NOTFOUND THEN
                FORMS_APX.DISPLAY_ARABIC_INFO(9, 160);        -- DispArbMsg(9, 160, 'ERROR') without raise
            END IF;
            CLOSE cur_parent_name;
        END IF;
    END IMPR_NBR_PARENT_VALIDATE_ITEM;

    -- ------------------------------------------------------------------ ADD_CTRY_CD
    PROCEDURE ADD_CTRY_CD_WHEN_VALIDATE_ITEM (P_ADD_CTRY_CD        IN     importers.add_ctry_cd%TYPE,
                                              P_CITY_CODE          IN     importers.city_code%TYPE,
                                              P_ADD_CRTY_ARBC_NAME IN OUT VARCHAR2,
                                              P_CITY_NAME          IN OUT VARCHAR2)
    IS
    BEGIN
        -- KEY-LISTVAL (LOV_COUNTRIES): :ADD_CRTY_ARBC_NAME := :GLOBAL.CRTY_ARBC_NAME
        IF P_ADD_CTRY_CD IS NOT NULL THEN
            BEGIN
                P_ADD_CRTY_ARBC_NAME := country_name(P_ADD_CTRY_CD);
            EXCEPTION
                WHEN NO_DATA_FOUND THEN NULL;
            END;
        END IF;
        address_city_lookup(TRUE, P_ADD_CTRY_CD, P_CITY_CODE, P_CITY_NAME, P_ADD_CRTY_ARBC_NAME);
    END ADD_CTRY_CD_WHEN_VALIDATE_ITEM;

    FUNCTION ADD_CTRY_CD_IS_READ_ONLY (P_ROW_ID         IN VARCHAR2,
                                       P_IMPR_TYPE_CD   IN NUMBER,
                                       P_BUS_ID_TYPE_CD IN NUMBER) RETURN BOOLEAN
    IS
    BEGIN
        IF new_record(P_ROW_ID) THEN
            -- WHEN-NEW-FORM-INSTANCE disables it (value 100); IMPR_TYPE_CD WVI enables it only for type 21 /
            -- identity type 19
            RETURN NOT (P_IMPR_TYPE_CD = 21 AND P_BUS_ID_TYPE_CD = 19);
        END IF;
        RETURN P_IMPR_TYPE_CD IN (1, 2, 5, 8, 11, 13, 14)   -- POST-QUERY
               OR (P_IMPR_TYPE_CD = 9 AND P_BUS_ID_TYPE_CD = 6);
    END ADD_CTRY_CD_IS_READ_ONLY;

    -- ------------------------------------------------------------------ CITY_CODE
    FUNCTION CITY_CODE_VALIDATION (P_ADD_CTRY_CD IN importers.add_ctry_cd%TYPE,
                                   P_CITY_CODE   IN importers.city_code%TYPE) RETURN VARCHAR2
    IS
        v_city_name          VARCHAR2(100);
        v_add_crty_arbc_name VARCHAR2(100);
    BEGIN
        city_code_logic(FALSE, P_ADD_CTRY_CD, P_CITY_CODE, v_city_name, v_add_crty_arbc_name);
        RETURN NULL;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN error_text(SQLCODE, SQLERRM, 'I');
    END CITY_CODE_VALIDATION;

    PROCEDURE CITY_CODE_WHEN_VALIDATE_ITEM (P_ADD_CTRY_CD        IN     importers.add_ctry_cd%TYPE,
                                            P_CITY_CODE          IN     importers.city_code%TYPE,
                                            P_CITY_NAME          IN OUT VARCHAR2,
                                            P_ADD_CRTY_ARBC_NAME IN OUT VARCHAR2)
    IS
    BEGIN
        city_code_logic(TRUE, P_ADD_CTRY_CD, P_CITY_CODE, P_CITY_NAME, P_ADD_CRTY_ARBC_NAME);
    END CITY_CODE_WHEN_VALIDATE_ITEM;

    -- ------------------------------------------------------------------ register items
    FUNCTION REGISTER_ITEMS_IS_READ_ONLY (P_ROW_ID            IN VARCHAR2,
                                          P_IMPR_TYPE_CD      IN NUMBER,
                                          P_BUS_ID_TYPE_CD    IN NUMBER,
                                          P_COMM_RGSTRTN_TYPE IN NUMBER,
                                          P_BUS_ID            IN VARCHAR2,
                                          P_BUS_ID_BRNCH      IN VARCHAR2,
                                          G_ALLOW_MCI         IN VARCHAR2) RETURN BOOLEAN
    IS
    BEGIN
        RETURN new_record(P_ROW_ID)
               AND ministry_data(P_IMPR_TYPE_CD, P_BUS_ID_TYPE_CD, G_ALLOW_MCI)
               AND NOT register_unlocked(P_IMPR_TYPE_CD, P_BUS_ID_TYPE_CD, P_COMM_RGSTRTN_TYPE, P_BUS_ID, P_BUS_ID_BRNCH);
    END REGISTER_ITEMS_IS_READ_ONLY;

    -- ------------------------------------------------------------------ IMPR_TEL_NBR
    FUNCTION IMPR_TEL_NBR_VALIDATION (P_IMPR_TEL_NBR IN importers.impr_tel_nbr%TYPE) RETURN VARCHAR2
    IS
        v VARCHAR2(1);
    BEGIN
        IF P_IMPR_TEL_NBR IS NULL THEN
            RETURN 'يجب إدخال الهاتف';
        END IF;
        IF LENGTH(P_IMPR_TEL_NBR) < 10 OR LENGTH(P_IMPR_TEL_NBR) > 10 THEN
            RETURN 'رقم الهاتف يجب أن يتكون من 10 أرقام';
        END IF;
        FOR i IN 1 .. LENGTH(P_IMPR_TEL_NBR) LOOP
            v := SUBSTR(P_IMPR_TEL_NBR, i, 1);
            IF NOT (v BETWEEN '0' AND '9') THEN
                RETURN 'يجب أن يكون رقم الهاتف المدخل أرقام';
            END IF;
        END LOOP;
        RETURN NULL;
    END IMPR_TEL_NBR_VALIDATION;

    -- ------------------------------------------------------------------ EMAIL (= IMPR1110 check_email)
    FUNCTION EMAIL_VALIDATION (P_EMAIL IN importers.email%TYPE) RETURN VARCHAR2
    IS
        at_pos NUMBER;
    BEGIN
        IF LENGTH(P_EMAIL) > 0 THEN
            at_pos := INSTR(P_EMAIL, '@');
            IF (at_pos <= 0 OR at_pos = 1) THEN
                RETURN 'خطأ فى صيغة البريد الالكتروني';
            END IF;
        END IF;
        RETURN NULL;
    END EMAIL_VALIDATION;

    -- ------------------------------------------------------------------ MOBILE_NO
    FUNCTION MOBILE_NO_VALIDATION (P_MOBILE_NO IN importers.mobile_no%TYPE) RETURN VARCHAR2
    IS
        v VARCHAR2(1);
    BEGIN
        IF P_MOBILE_NO IS NULL THEN
            RETURN 'يجب إدخال رقم المحمول';
        END IF;
        FOR i IN 1 .. LENGTH(P_MOBILE_NO) LOOP
            v := SUBSTR(P_MOBILE_NO, i, 1);
            IF NOT (v BETWEEN '0' AND '9') THEN
                RETURN 'يجب أن يكون رقم الجوال المدخل أرقام';
            END IF;
        END LOOP;
        IF LENGTH(P_MOBILE_NO) != 9 OR SUBSTR(P_MOBILE_NO, 1, 1) != 5 THEN
            RETURN 'رقم الجوال المدخل غير صحيح .. الرجاء اعادة الادخال ';
        END IF;
        RETURN NULL;
    END MOBILE_NO_VALIDATION;

    -- ------------------------------------------------------------------ BLOCK IMPORTERS - DML
    PROCEDURE PRE_INSERT (P_PORT_CD           IN     importers.port_cd%TYPE,
                          P_IMPR_NBR          IN     importers.impr_nbr%TYPE,
                          P_HQ_IMPR_NBR       IN OUT importers.hq_impr_nbr%TYPE,
                          P_IMPR_TYPE_CD      IN     importers.impr_type_cd%TYPE,
                          P_BUS_ID_EXPRD_DT   IN     VARCHAR2,
                          P_BUS_ID_TYPE_CD    IN     importers.bus_id_type_cd%TYPE,
                          P_COMM_RGSTRTN_TYPE IN     importers.comm_rgstrtn_type%TYPE,
                          P_CTRY_CD           IN     importers.ctry_cd%TYPE,
                          P_CITY_CODE_OF_ID   IN     importers.city_code_of_id%TYPE,
                          P_CTRY_CD_OF_ID     IN     importers.ctry_cd_of_id%TYPE,
                          P_IMPR_EXPR_TYPE    IN     importers.impr_expr_type%TYPE,
                          P_NATIONAL_NBR      IN     importers.national_nbr%TYPE,
                          P_BUS_ID            IN     importers.bus_id%TYPE,
                          P_BUS_ID_BRNCH      IN OUT importers.bus_id_brnch%TYPE,
                          P_ARBC_IMPR_NAME    IN     importers.arbc_impr_name%TYPE,
                          P_ENG_IMPR_NAME     IN     importers.eng_impr_name%TYPE,
                          P_IMPR_CNTCT_NAME   IN     importers.impr_cntct_name%TYPE,
                          P_IMPR_ADDRESS      IN     importers.impr_address%TYPE,
                          P_BUS_ID_ISSUE_DT   IN     VARCHAR2,
                          P_IMPR_NBR_PARENT   IN     importers.impr_nbr_parent%TYPE,
                          P_ADD_CTRY_CD       IN     importers.add_ctry_cd%TYPE,
                          P_CITY_CODE         IN     importers.city_code%TYPE,
                          P_IMPR_POB_NBR      IN     importers.impr_pob_nbr%TYPE,
                          P_IMPR_ZIP_CD       IN     importers.impr_zip_cd%TYPE,
                          P_IMPR_TEL_NBR      IN     importers.impr_tel_nbr%TYPE,
                          P_IMPR_FAX_NBR      IN     importers.impr_fax_nbr%TYPE,
                          P_IMPR_TELEX_NBR    IN     importers.impr_telex_nbr%TYPE,
                          P_EMAIL             IN     importers.email%TYPE,
                          P_MOBILE_NO         IN     importers.mobile_no%TYPE,
                          P_CAR_AGENT_FLAG    IN     importers.car_agent_flag%TYPE,
                          P_EXPRESS_POST      IN     importers.express_post%TYPE,
                          P_ID_NBR            IN     importers.id_nbr%TYPE,
                          P_IMPD_STMT_NBR     IN     importers.impd_stmt_nbr%TYPE,
                          P_IMPR_DATA_SRCE    IN     importers.impr_data_srce%TYPE,
                          P_EXPD_STMT_NBR     IN     importers.expd_stmt_nbr%TYPE,
                          P_WVR_ENTRY_NBR     IN     importers.wvr_entry_nbr%TYPE,
                          P_ACTIVITY          IN     importers.activity%TYPE,
                          P_BANK_IBAN         IN     importers.bank_iban%TYPE,
                          P_ID_CITY_NAME      IN OUT VARCHAR2,
                          P_ID_MINS_COMM_CD   IN OUT NUMBER,
                          G_PORT_CD           IN     VARCHAR2,
                          G_SUPP_TITLE_CD     IN     VARCHAR2,
                          G_LETTER_NBR        IN     VARCHAR2,
                          G_LETTER_DT         IN     VARCHAR2,
                          P_CURR_PORT_CD      IN     NUMBER,
                          SSO_APP_USER        IN     VARCHAR2,
                          P_GLOBAL_V_WS_ID    IN     VARCHAR2)
    IS
        v_impr_nbr     VARCHAR2(50);
        v_msg_txt      VARCHAR2(500);
        v_result       NUMBER;
        v_impr_tel_nbr NUMBER;
    BEGIN
        -- SET_BLOCK_PROPERTY('IMPORTERS', UPDATE_ALLOWED, PROPERTY_FALSE): not converted (inventory §15 #16)
        IF P_BUS_ID_EXPRD_DT IS NULL THEN
            -- APEX-DA: Make_Field_Entrable('IMPORTERS.BUS_ID_EXPRD_DT', TRUE) (rule: editable while empty)
            FORMS_APX.DISPLAY_ARABIC_ERROR(9, 220);
        END IF;
        IF P_IMPR_TEL_NBR IS NULL THEN
            FORMS_APX.FORM_TRIGGER_FAILURE('يجب ادخال رقم الهاتف');
        END IF;
        IF P_MOBILE_NO IS NULL THEN
            FORMS_APX.FORM_TRIGGER_FAILURE('يجب إدخال رقم المحمول');
        END IF;
        chk_impr_dupl(P_PORT_CD, P_CTRY_CD, P_BUS_ID_TYPE_CD, P_BUS_ID, P_BUS_ID_BRNCH, P_IMPR_NBR);

        -- letter of SUPPORT_ENTRY (page 9001 sets the G_ items; G_LETTER_DT is Hijri text, spec 0.4 / D3)
        IF G_LETTER_NBR IS NOT NULL THEN
            db_journal.journaling_on(G_PORT_CD, G_SUPP_TITLE_CD, G_LETTER_NBR, FORMS_APX.HIJRI_TEXT_TO_DATE(G_LETTER_DT));
        END IF;
        add_activity(1, P_PORT_CD, P_IMPR_NBR, P_CURR_PORT_CD, SSO_APP_USER, P_GLOBAL_V_WS_ID);

        -- CREATED BY BASSAM MANSOUR 09/01/2019: record the importer in HQ and port.
        -- TODO-VERIFY (inventory §15 #5): 44 arguments (IMPR1110: 42); whether the procedure inserts IMPORTERS itself.
        IF P_IMPR_TEL_NBR = 'NULL' THEN
            v_impr_tel_nbr := 0;
        ELSE
            v_impr_tel_nbr := NVL(P_IMPR_TEL_NBR, 0);
        END IF;
        lib_usr.impr_central.create_uni_impr_nebras(P_PORT_CD,
                                                    P_BUS_ID,
                                                    P_BUS_ID_BRNCH,
                                                    P_BUS_ID_TYPE_CD,
                                                    P_IMPR_TYPE_CD,
                                                    P_CTRY_CD,
                                                    P_CITY_CODE,
                                                    P_IMPR_CNTCT_NAME,
                                                    v_impr_tel_nbr,
                                                    P_EMAIL,
                                                    P_BANK_IBAN,
                                                    NVL(P_IMPR_POB_NBR, 0),
                                                    TO_CHAR(hijri(P_BUS_ID_EXPRD_DT), c_service_mask),
                                                    P_ACTIVITY,
                                                    P_ARBC_IMPR_NAME,
                                                    P_ENG_IMPR_NAME,
                                                    NVL(P_MOBILE_NO, 0),
                                                    NVL(P_IMPR_ZIP_CD, 0),
                                                    0,                                -- NVL(:BRNH_CITY_CD,0)
                                                    P_IMPR_EXPR_TYPE,
                                                    P_IMPR_ADDRESS,
                                                    TO_CHAR(hijri(P_BUS_ID_ISSUE_DT), c_service_mask),
                                                    P_ID_NBR,
                                                    NVL(P_COMM_RGSTRTN_TYPE, 0),
                                                    0,                                -- NVL(:CTRY_CD_OF_ID,0)
                                                    NVL(P_CITY_CODE_OF_ID, 0),
                                                    NVL(P_IMPR_NBR_PARENT, 0),
                                                    NVL(P_IMPR_FAX_NBR, 0),
                                                    NVL(P_IMPR_TELEX_NBR, 0),
                                                    NVL(P_ADD_CTRY_CD, 0),
                                                    NVL(P_IMPD_STMT_NBR, 0),
                                                    NVL(P_IMPR_DATA_SRCE, 0),
                                                    0,                                -- NVL(:CUSTOMS_ENTERED,0)
                                                    NVL(P_EXPD_STMT_NBR, 0),
                                                    NVL(P_WVR_ENTRY_NBR, 0),
                                                    NVL(P_CAR_AGENT_FLAG, 0),
                                                    NVL(P_EXPRESS_POST, 0),
                                                    v_impr_nbr,
                                                    v_msg_txt,
                                                    v_result,
                                                    SSO_APP_USER,
                                                    P_GLOBAL_V_WS_ID,
                                                    NULL,                             -- birth date no need for commercial
                                                    P_NATIONAL_NBR);
        IF v_result = 1 THEN
            FORMS_APX.MESSAGE(v_msg_txt);
            FORMS_APX.MESSAGE('رقم المستورد' || ' = ' || v_impr_nbr);
            IF v_impr_nbr IS NOT NULL THEN     -- :GLOBAL.SET := V_IMPR_NBR
                P_HQ_IMPR_NBR := v_impr_nbr;
                -- APEX-DA: Make_Field_Entrable BUS_ID, BUS_ID_BRNCH, BUS_ID_EXPRD_DT, ARBC_IMPR_NAME, COMM_RGSTRTN_TYPE,
                --          CITY_CODE_OF_ID, BUS_ID_TYPE_CD, IMPR_EXPR_TYPE, IMPR_TYPE_CD FALSE (saved-record rules)
            END IF;
        ELSE
            FORMS_APX.FORM_TRIGGER_FAILURE(v_msg_txt);   -- DISPALERT(V_msg_txt) + RAISE FORM_TRIGGER_FAILURE
        END IF;

        -- CGFK$CLR_FK_ON_INS (CGSF$CLRLU_IMPORTERS_IMP_BUS_I)
        IF P_CITY_CODE_OF_ID IS NULL AND P_CTRY_CD_OF_ID IS NULL THEN
            P_ID_CITY_NAME    := NULL;
            P_ID_MINS_COMM_CD := NULL;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            journaling_off;                    -- not in Forms: pooled APEX sessions (SUPPORT_ENTRY risk R10)
            RAISE;
    END PRE_INSERT;

    PROCEDURE POST_INSERT (P_ROW_ID       IN     VARCHAR2,
                           P_IMPR_NBR     IN OUT importers.impr_nbr%TYPE,
                           SSO_APP_USER   IN     VARCHAR2)
    IS
        v_row importers%ROWTYPE;
    BEGIN
        -- The audit row is written from the row just inserted (= the Forms record values).
        -- TODO-VERIFY (inventory §15 #15): IMPR_NBR is not set by the Forms code; it is read from the row
        -- (a trigger or CREATE_UNI_IMPR_NEBRAS fills it), otherwise INSERT_AUDIT_RECORD raises 9-140 as in Forms.
        SELECT *
          INTO v_row
          FROM importers
         WHERE ROWID = CHARTOROWID(POST_INSERT.P_ROW_ID);
        v_row.impr_nbr := NVL(P_IMPR_NBR, v_row.impr_nbr);
        P_IMPR_NBR     := v_row.impr_nbr;
        insert_audit_record(v_row, 'I', SSO_APP_USER);
        journaling_off;                        -- IF DB_JOURNAL.IS_JOURNALING_ON THEN DB_JOURNAL.JOURNALING_OFF
    EXCEPTION
        WHEN OTHERS THEN
            journaling_off;
            RAISE;
    END POST_INSERT;

    PROCEDURE PRE_UPDATE (P_PORT_CD           IN     importers.port_cd%TYPE,
                          P_IMPR_NBR          IN     importers.impr_nbr%TYPE,
                          P_HQ_IMPR_NBR       IN OUT importers.hq_impr_nbr%TYPE,
                          P_BUS_ID_STATUS     IN     importers.bus_id_status%TYPE,
                          P_IMPR_TYPE_CD      IN     importers.impr_type_cd%TYPE,
                          P_BUS_ID_EXPRD_DT   IN     VARCHAR2,
                          P_BUS_ID_TYPE_CD    IN     importers.bus_id_type_cd%TYPE,
                          P_COMM_RGSTRTN_TYPE IN     importers.comm_rgstrtn_type%TYPE,
                          P_CTRY_CD           IN     importers.ctry_cd%TYPE,
                          P_CITY_CODE_OF_ID   IN     importers.city_code_of_id%TYPE,
                          P_CTRY_CD_OF_ID     IN     importers.ctry_cd_of_id%TYPE,
                          P_IMPR_EXPR_TYPE    IN     importers.impr_expr_type%TYPE,
                          P_BUS_ID            IN     importers.bus_id%TYPE,
                          P_BUS_ID_BRNCH      IN     importers.bus_id_brnch%TYPE,
                          P_ARBC_IMPR_NAME    IN OUT importers.arbc_impr_name%TYPE,
                          P_IMPR_NAME_STD     IN OUT importers.impr_name_std%TYPE,
                          P_LST_TRAN_DT       IN     VARCHAR2,
                          P_IMPD_STMT_NBR     IN     importers.impd_stmt_nbr%TYPE,
                          P_IMPR_DATA_SRCE    IN     importers.impr_data_srce%TYPE,
                          P_ENG_IMPR_NAME     IN OUT importers.eng_impr_name%TYPE,
                          P_IMPR_CNTCT_NAME   IN OUT importers.impr_cntct_name%TYPE,
                          P_IMPR_ADDRESS      IN     importers.impr_address%TYPE,
                          P_BUS_ID_ISSUE_DT   IN     VARCHAR2,
                          P_IMPR_NBR_PARENT   IN     importers.impr_nbr_parent%TYPE,
                          P_ADD_CTRY_CD       IN     importers.add_ctry_cd%TYPE,
                          P_CITY_CODE         IN     importers.city_code%TYPE,
                          P_IMPR_POB_NBR      IN     importers.impr_pob_nbr%TYPE,
                          P_IMPR_ZIP_CD       IN     importers.impr_zip_cd%TYPE,
                          P_IMPR_TEL_NBR      IN     importers.impr_tel_nbr%TYPE,
                          P_IMPR_FAX_NBR      IN     importers.impr_fax_nbr%TYPE,
                          P_IMPR_TELEX_NBR    IN     importers.impr_telex_nbr%TYPE,
                          P_EMAIL             IN     importers.email%TYPE,
                          P_ID_NBR            IN     importers.id_nbr%TYPE,
                          P_CREATION_FLAG     IN     importers.creation_flag%TYPE,
                          P_CURR_PORT_CD      IN     NUMBER,
                          SSO_APP_USER        IN     VARCHAR2,
                          P_GLOBAL_V_WS_ID    IN     VARCHAR2)
    IS
        v_row importers%ROWTYPE;
    BEGIN
        P_IMPR_NAME_STD := str_db.strformat(P_ARBC_IMPR_NAME, 0);      -- STR.StrFormat(:ARBC_IMPR_NAME)

        -- Insert_Audit_Record('U') with the record values at this point (before HQ_IMPR_NBR and the trims)
        v_row.port_cd           := P_PORT_CD;
        v_row.impr_nbr          := P_IMPR_NBR;
        v_row.hq_impr_nbr       := P_HQ_IMPR_NBR;
        v_row.impr_type_cd      := P_IMPR_TYPE_CD;
        v_row.bus_id_type_cd    := P_BUS_ID_TYPE_CD;
        v_row.bus_id            := P_BUS_ID;
        v_row.bus_id_brnch      := P_BUS_ID_BRNCH;
        v_row.bus_id_exprd_dt   := hijri(P_BUS_ID_EXPRD_DT);
        v_row.ctry_cd_of_id     := P_CTRY_CD_OF_ID;
        v_row.city_code_of_id   := P_CITY_CODE_OF_ID;
        v_row.impr_expr_type    := P_IMPR_EXPR_TYPE;
        v_row.arbc_impr_name    := P_ARBC_IMPR_NAME;
        v_row.eng_impr_name     := P_ENG_IMPR_NAME;
        v_row.impr_name_std     := P_IMPR_NAME_STD;
        v_row.impr_nbr_parent   := P_IMPR_NBR_PARENT;
        v_row.impr_cntct_name   := P_IMPR_CNTCT_NAME;
        v_row.impr_tel_nbr      := P_IMPR_TEL_NBR;
        v_row.impr_pob_nbr      := P_IMPR_POB_NBR;
        v_row.impr_zip_cd       := P_IMPR_ZIP_CD;
        v_row.impr_fax_nbr      := P_IMPR_FAX_NBR;
        v_row.impr_telex_nbr    := P_IMPR_TELEX_NBR;
        v_row.email             := P_EMAIL;
        v_row.ctry_cd           := P_CTRY_CD;
        v_row.add_ctry_cd       := P_ADD_CTRY_CD;
        v_row.city_code         := P_CITY_CODE;
        v_row.lst_tran_dt       := TO_DATE(P_LST_TRAN_DT, c_date_time_mask);
        v_row.impd_stmt_nbr     := P_IMPD_STMT_NBR;
        v_row.impr_data_srce    := P_IMPR_DATA_SRCE;
        v_row.comm_rgstrtn_type := P_COMM_RGSTRTN_TYPE;
        v_row.id_nbr            := P_ID_NBR;
        v_row.bus_id_issue_dt   := hijri(P_BUS_ID_ISSUE_DT);
        v_row.bus_id_status     := P_BUS_ID_STATUS;
        v_row.creation_flag     := P_CREATION_FLAG;
        v_row.impr_address      := P_IMPR_ADDRESS;
        insert_audit_record(v_row, 'U', SSO_APP_USER);

        P_HQ_IMPR_NBR := hq_number(P_BUS_ID_TYPE_CD, P_BUS_ID, P_BUS_ID_BRNCH);   -- C1_HQ_NBR / C2_HQ_NBR
        add_activity(2, P_PORT_CD, P_IMPR_NBR, P_CURR_PORT_CD, SSO_APP_USER, P_GLOBAL_V_WS_ID);

        -- anas: trimmed names
        P_ARBC_IMPR_NAME  := LTRIM(RTRIM(P_ARBC_IMPR_NAME));
        P_ENG_IMPR_NAME   := LTRIM(RTRIM(P_ENG_IMPR_NAME));
        P_IMPR_CNTCT_NAME := LTRIM(RTRIM(P_IMPR_CNTCT_NAME));
    END PRE_UPDATE;

    PROCEDURE KEY_DELREC (P_ROW_ID         IN VARCHAR2,
                          P_PORT_CD        IN importers.port_cd%TYPE,
                          P_IMPR_NBR       IN importers.impr_nbr%TYPE,
                          P_CURR_PORT_CD   IN NUMBER,
                          SSO_APP_USER     IN VARCHAR2,
                          P_GLOBAL_V_WS_ID IN VARCHAR2)
    IS
        v_message VARCHAR2(4000);
    BEGIN
        -- STAT != 'NEW' and the toolbar item REMOVE visible / enabled: page 0 DELETE (shown by the privileges)
        IF new_record(P_ROW_ID) THEN
            RETURN;
        END IF;
        -- RET = ALERT_BUTTON1 (page 0 DELETE confirm)
        DELETE impr_knwns
         WHERE port_cd  = KEY_DELREC.P_PORT_CD
           AND impr_nbr = KEY_DELREC.P_IMPR_NBR;
        DELETE impr_updts
         WHERE port_cd  = KEY_DELREC.P_PORT_CD
           AND impr_nbr = KEY_DELREC.P_IMPR_NBR;
        -- FORMS_DDL('COMMIT') removed: one transaction, a refused delete keeps the rows (inventory §15 #4)

        -- CGRI$CHECK_ON_DELETE (KEY-DELREC) = CGRI$CASCADE_DELETE (PRE-DELETE): the same check, run once
        v_message := CGRI$CHK_IMPORTERS(P_IMPR_NBR, P_PORT_CD);
        IF v_message IS NOT NULL THEN
            FORMS_APX.FORM_TRIGGER_FAILURE(v_message);
        END IF;
        add_activity(5, P_PORT_CD, P_IMPR_NBR, P_CURR_PORT_CD, SSO_APP_USER, P_GLOBAL_V_WS_ID);   -- PRE-DELETE
        DELETE importers                       -- Delete_record (Forms default DELETE, key mode ROWID)
         WHERE ROWID = CHARTOROWID(KEY_DELREC.P_ROW_ID);
        -- COMMIT removed: APEX commits at the end of the request
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE BETWEEN -20999 AND -20000 THEN
                RAISE;
            END IF;
            FORMS_APX.FORM_TRIGGER_FAILURE(importers_on_error('D', SQLCODE, SQLERRM));   -- IMPORTERS.ON-ERROR (FRM-40510)
    END KEY_DELREC;

    -- ------------------------------------------------------------------ FUNCTIONS
    FUNCTION ADJ_FUNS (P_IMPR_TYPE_CD   IN importers.impr_type_cd%TYPE,
                       P_BUS_ID_TYPE_CD IN importers.bus_id_type_cd%TYPE,
                       G_ALLOW_MCI      IN VARCHAR2,
                       G_ALLOW_MOI      IN VARCHAR2) RETURN VARCHAR2
    IS
    BEGIN
        IF (NVL(P_BUS_ID_TYPE_CD, 0) = 2 AND NVL(G_ALLOW_MCI, '0') = '1')
           OR (P_IMPR_TYPE_CD = 4 AND P_BUS_ID_TYPE_CD IN (3, 5) AND NVL(G_ALLOW_MOI, '0') = '1') THEN
            RETURN c_functions;                -- TMPLT.ENABLE_FUN('IMPR_MCI_SERVICE')
        END IF;
        RETURN NULL;                           -- TMPLT.DISABLE_FUN('IMPR_MCI_SERVICE')
    END ADJ_FUNS;

    FUNCTION UPDATE_IMPORTER_CONFIRM_TEXT (P_PORT_CD        IN importers.port_cd%TYPE,
                                           P_IMPR_NBR       IN importers.impr_nbr%TYPE,
                                           P_IMPR_TYPE_CD   IN importers.impr_type_cd%TYPE,
                                           P_BUS_ID_TYPE_CD IN importers.bus_id_type_cd%TYPE,
                                           P_BUS_ID         IN importers.bus_id%TYPE,
                                           P_BUS_ID_BRNCH   IN importers.bus_id_brnch%TYPE) RETURN VARCHAR2
    IS
        v_msg VARCHAR2(500);
    BEGIN
        IF P_PORT_CD IS NULL OR P_IMPR_NBR IS NULL THEN
            RETURN NULL;
        END IF;
        IF P_BUS_ID_TYPE_CD = 2 THEN
            v_msg := 'السجل الرئيسي =  ' || P_BUS_ID || 'السجل الفرعي = ' || P_BUS_ID_BRNCH || ' تأكيد التحديث؟';
        END IF;
        IF P_IMPR_TYPE_CD = 4 AND P_BUS_ID_TYPE_CD = 5 THEN
            v_msg := 'رقم مدني =  ' || P_BUS_ID || ' تأكيد التحديث؟';
        END IF;
        IF P_IMPR_TYPE_CD = 4 AND P_BUS_ID_TYPE_CD = 3 THEN
            v_msg := ' رقم الاقامة =  ' || P_BUS_ID || ' تأكيد التحديث؟';
        END IF;
        -- ADJ_FUNS enables the function only for these three cases, so V_MSG is never empty when it runs
        RETURN v_msg;
    END UPDATE_IMPORTER_CONFIRM_TEXT;

    PROCEDURE EXEC_FUNS (P_FUNCTION_CODE IN VARCHAR2,
                         P_PORT_CD       IN importers.port_cd%TYPE,
                         P_IMPR_NBR      IN importers.impr_nbr%TYPE,
                         P_ANSWER        IN NUMBER,
                         G_ALLOW_MCI     IN VARCHAR2,
                         G_ALLOW_MOI     IN VARCHAR2)
    IS
    BEGIN
        IF P_FUNCTION_CODE IN ('IMPR_MCI_SERVICE')
           AND (NVL(G_ALLOW_MCI, '0') = '1' OR NVL(G_ALLOW_MOI, '0') = '1') THEN
            update_importer(P_PORT_CD, P_IMPR_NBR, P_ANSWER);
        END IF;
    END EXEC_FUNS;

    -- =========================================================================
    -- 5 VERSION
    -- =========================================================================
    FUNCTION PKG_VERSION
       RETURN VARCHAR2
    IS
    BEGIN
       RETURN V_INFO;
    END PKG_VERSION;

END IMPR1130;
/
SHOW ERRORS
