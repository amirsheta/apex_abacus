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

