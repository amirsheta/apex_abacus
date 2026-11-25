-- =============================================================================
-- Package body: IMPR2170_ARD   (matches IMPR2170_ARD.pks)   Version: 001
-- Layout of IMPR2170.rdf (Landscape, right to left, 2024 design):
--   margin : title P_MODULE_NAME and port name (V_PORT_NAME_SEC1 on PPORT_CD) right, logo left,
--            رقم التقرير + التاريخ (Hijri / Gregorian) line; footer the address line and the page counter
--   R_CG$G_MZS_G2 (Q_2, G_X0_IMPR_NAME): اسم المستورد, الرقم الاستدلالى, الرقم الفرعي
--   R_2 (G_PORT_F0): header row per group (M_HEADER) + R_1 rows: #, مستوى الإيقاف, رقم المستورد, الرقم
--   الاستدلالي الرئيسي, الرقم الفرعي, اسم المستورد, الحالة, الإدارة. PORT_F0 = 0 (format triggers): no
--   رقم المستورد column, مستوى الإيقاف takes its place (colspan 2).
-- =============================================================================
SET DEFINE OFF

CREATE OR REPLACE PACKAGE BODY LIB_APX_USR.IMPR2170_ARD
AS

    FUNCTION PKG_VERSION RETURN VARCHAR2 IS
    BEGIN
        RETURN (V_PKG_VERSION);
    END PKG_VERSION;

    -- خلية جدول: القيمة escaped، والـ style اختياري
    FUNCTION HTML_CELL (P_VALUE VARCHAR2, P_STYLE VARCHAR2 DEFAULT NULL) RETURN VARCHAR2 IS
    BEGIN
        RETURN '<td' || CASE WHEN P_STYLE IS NOT NULL THEN ' style="' || P_STYLE || '"' END || '>'
               || APEX_ESCAPE.HTML (P_VALUE) || '</td>';
    END HTML_CELL;

    -- عنوان وقيمة (زي boilerplate + field في الـ RDF)
    FUNCTION LABEL_VALUE (P_LABEL VARCHAR2, P_VALUE VARCHAR2) RETURN VARCHAR2 IS
    BEGIN
        RETURN '<span class="lbl">' || P_LABEL || ' </span><span class="val">' || APEX_ESCAPE.HTML (P_VALUE) || '</span>';
    END LABEL_VALUE;

    -- CF_CURR_DTFormula من الـ RDF (HIJDATE -> HIJDATE_DB)
    FUNCTION CF_CURR_DTFormula RETURN DATE IS
    begin
      RETURN(HIJDATE_DB.Cur_Hij_Date);
    end;

    -- CF_X1Formula بالحرف من الـ RDF
    FUNCTION CF_X1Formula (P_PORT_CD_F1 NUMBER) RETURN VARCHAR2 IS
    X_PORT_NAME VARCHAR2(100);
    begin
      SELECT PORT_NAME
      INTO   X_PORT_NAME
      FROM   SD_PORTS
      WHERE  PORT_CD = P_PORT_CD_F1 ;
        RETURN X_PORT_NAME;
    EXCEPTION
    	WHEN NO_DATA_FOUND THEN
    	RETURN 'جميع الجمارك';
    end;

    -- CF_IMPR_NBR_XFormula بالحرف من الـ RDF
    FUNCTION CF_IMPR_NBR_XFormula (P_IMPR_NBR_F1 NUMBER) RETURN VARCHAR2 IS
    BEGIN
    	IF P_IMPR_NBR_F1 IS NULL OR P_IMPR_NBR_F1 = 0
    		THEN RETURN(' ');
    	ELSE RETURN(P_IMPR_NBR_F1);
    	END IF;
    END;

    -- impr_name_dumFormula بالحرف من الـ RDF
    FUNCTION impr_name_dumFormula (P_PORT_F0 NUMBER, P_BUS_ID VARCHAR2, P_PORT_CD_F1 NUMBER, P_IMPR_NBR_F1 NUMBER) RETURN VARCHAR2 IS
    dummy varchar2(150);
    begin
    	IF P_PORT_F0 = 0 THEN
      	select ARBC_IMPR_NAME into dummy from importers where BUS_ID=P_BUS_ID AND ROWNUM<=1 AND ARBC_IMPR_NAME IS NOT NULL;
    	ELSE
      	select ARBC_IMPR_NAME into dummy
      	from importers
      	where PORT_CD = P_PORT_CD_F1 AND IMPR_NBR = P_IMPR_NBR_F1;
    	END IF;
      RETURN DUMMY;
    EXCEPTION WHEN OTHERS THEN
    	RETURN NULL;
    end;

    -- V_PORT_NAME_SEC1FormatTrigger من الـ RDF: SRW.SET_FIELD_CHAR(0, V_NAME) -> بترجع الاسم؛ جمرك 99 من غير اسم
    FUNCTION V_PORT_NAME_SEC1FormatTrigger (P_CURR_PORT_CD NUMBER) RETURN VARCHAR2 IS
    V_NAME VARCHAR2(100);
    BEGIN
    	IF P_CURR_PORT_CD = 99 THEN
    	RETURN(NULL);
    	ELSE

      SELECT PORT_NAME
      INTO   V_NAME
      FROM   SD_PORTS
      WHERE  PORT_CD = P_CURR_PORT_CD ;
     	RETURN(V_NAME);
     END IF;
    EXCEPTION
    	WHEN NO_DATA_FOUND THEN
    	RETURN(NULL);
    END;

    FUNCTION ARD_IMPR2170 (P_PARAMETER1   IN VARCHAR2 DEFAULT NULL,
                           P_PARAMETER2   IN VARCHAR2 DEFAULT NULL,
                           P_PARAMETER3   IN VARCHAR2 DEFAULT NULL,
                           P_PARAMETER4   IN VARCHAR2 DEFAULT NULL,
                           P_PARAMETER5   IN VARCHAR2 DEFAULT NULL,
                           P_PARAMETER6   IN VARCHAR2 DEFAULT NULL,
                           P_PARAMETER7   IN VARCHAR2 DEFAULT NULL)
        RETURN CLOB
    IS
        retVal                 CLOB;
        v_p_curr_port_cd       NUMBER := TO_NUMBER (P_PARAMETER1);
        v_pport_cd             NUMBER := TO_NUMBER (P_PARAMETER2);
        v_pselect1             NUMBER := TO_NUMBER (P_PARAMETER3);
        v_pimpr_nbr            NUMBER := TO_NUMBER (P_PARAMETER4);
        v_phq_impr_nbr         NUMBER := TO_NUMBER (P_PARAMETER5);
        v_p_module_name        VARCHAR2 (4000) := P_PARAMETER6;
        v_p_report_no          VARCHAR2 (4000) := P_PARAMETER7;
        v_p_bus_id             VARCHAR2 (100);   -- P_BUS_ID (BeforeReport)
        v_cf_curr_dt           DATE;             -- CF_CURR_DT
        v_port_name            VARCHAR2 (100);   -- V_PORT_NAME_SEC1
        v_prev_port_f0         NUMBER;           -- G_PORT_F0 اللي فات
        v_count                NUMBER := 0;      -- CS_1
    BEGIN
        DBMS_LOB.createtemporary (retVal, TRUE);

        -- BeforeReport
        BEGIN
            SELECT BUS_ID INTO v_p_bus_id
              FROM IMPORTERS
             WHERE ((IMPR_NBR = v_pimpr_nbr AND PORT_CD = v_pport_cd) OR HQ_IMPR_NBR = v_phq_impr_nbr) AND ROWNUM <= 1;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_p_bus_id := NULL;
        END;
        IF v_p_curr_port_cd IS NULL THEN v_p_curr_port_cd := 99; END IF;

        v_cf_curr_dt := CF_CURR_DTFormula;
        v_port_name := V_PORT_NAME_SEC1FormatTrigger (v_pport_cd);
        dbms_lob.append (retVal, '<head><style>
.MRD-Header{ display:none; }
.MRDFooter{ position: fixed; bottom: 0px; width: 100%; }
th{ text-align:center; }
.MRD-Body tr{ -fs-page-break-min-height:5mm; }
.ARDHeader{ width:100%; }
body, table, td, p { font-family: Somar; }
.grp{ width:100%; margin:12px 0 2px 0; page-break-inside: avoid; }
.grp td{ font-size:11px; padding:2px 4px; }
.data{ border-collapse:collapse; width:100%; table-layout:fixed; -fs-table-paginate: paginate; }
.data td{ border:1px solid #a5a5a5; padding:3px 6px; text-align:center; font-size:11px; color:#707070; }
.data th{ border:1px solid #a5a5a5; padding:4px 6px; font-size:11px; color:#ffffff; background:#0e0f50; font-weight:normal; }
.data tr{ page-break-inside: avoid; }
.lbl{ color:#0e0f50; font-size:11px; }
.val{ color:#707070; font-size:11px; }
@page {
   background: white;
   margin-top: 20px;
   margin-bottom: 40px;
   margin-left: 30px;
   margin-right: 30px;
   size: A4 landscape;
   @bottom-center { content: "صفحة " counter(page) " من " counter(pages); direction: rtl; font-family: Somar; font-size: 10px; color: #0e0f50; }
}
</style></head>');

        -- الهيدر في كل صفحة: العنوان واسم الجمرك يمين واللوجو شمال، وتحتهم رقم التقرير والتاريخ؛ الفوتر سطر العنوان
        dbms_lob.append (retVal, '
<div class="MRD-BODYMaster" dir="rtl">
<div class="MRD-Header"><table border="0" cellpadding="1" cellspacing="1" style="width:100%;"><tbody><tr><td></td></tr></tbody></table></div>
<div class="MRD-Body">
<table class="main-table" style="width: 100%;">
<thead>
  <tr>
    <td><div class="ARDHeader">
      <table border="0" cellpadding="1" cellspacing="1" dir="rtl" style="width:100%;table-layout:fixed;">
        <tbody>
          <tr>
            <td style="width:60%;vertical-align:bottom;">
              <p style="margin:2px;"><span style="color:#0e0f50;font-size:12px;font-weight:bold;">' || APEX_ESCAPE.HTML (v_port_name) || '</span></p>
              <p style="margin:2px;"><span style="color:#0e0f50;font-size:14px;font-weight:bold;">' || APEX_ESCAPE.HTML (v_p_module_name) || '</span></p>
            </td>
            <td style="width:40%;text-align:left;">');
        dbms_lob.append (retVal, ARD_LOGO.IMG (85, 335, NULL, 'LOGO1.jpg'));   -- اللوجو Static File في الأبلكيشن (DEC-034)
        dbms_lob.append (retVal, '</td>
          </tr>
          <tr>
            <td style="font-size:11px;color:#0e0f50;">رقم التقرير: <span style="color:#707070;">' || APEX_ESCAPE.HTML (v_p_report_no) || '</span></td>
            <td style="font-size:11px;color:#0e0f50;">التاريــخ: <span style="color:#707070;">' || TO_CHAR (HIJDATE_DB.CUR_HIJ_DATE, 'MI-MM-YYYY') || '</span> هـ
               / <span style="color:#707070;">' || TO_CHAR (SYSDATE, 'DD-MM-YYYY') || '</span> م</td>
          </tr>
        </tbody>
      </table>
    </div></td>
  </tr>
</thead>
<tfoot>
  <tr>
    <td><div class="MRDFooter">
      <p style="margin:2px;font-size:10px;color:#0e0f50;">المملكة العربية السعودية | الهيئة العامة للجمارك | ص.ب 3483 الرياض 11197</p>
    </div></td>
  </tr>
</tfoot>
<tbody>
  <tr>
    <td>');

        -- R_CG$G_MZS_G2 (Q_2)
        FOR x IN (SELECT SI.ARBC_IMPR_NAME X0_IMPR_NAME,
                         HI.HQ_IMPR_NBR    X0_HQ_IMPR_NBR,
                         HI.BUS_ID         X0_BUS_ID,
                         HI.BUS_ID_BRNCH   X0_BUS_ID_BRNCH
                    FROM IMPORTERS IMP, HQ_IMPRS HI, SINGLE_IMPORTERS SI
                   WHERE     (   (v_pselect1 = 1 AND IMP.PORT_CD = v_pport_cd AND IMP.IMPR_NBR = v_pimpr_nbr)
                              OR (v_pselect1 = 2 AND IMP.HQ_IMPR_NBR = v_phq_impr_nbr))
                         AND HI.HQ_IMPR_NBR = IMP.HQ_IMPR_NBR
                         AND IMP.HQ_IMPR_NBR = SI.HQ_IMPR_NBR
                GROUP BY SI.ARBC_IMPR_NAME, HI.HQ_IMPR_NBR, HI.BUS_ID, HI.BUS_ID_BRNCH
                ORDER BY SI.ARBC_IMPR_NAME, HI.HQ_IMPR_NBR, HI.BUS_ID, HI.BUS_ID_BRNCH)
        LOOP
            dbms_lob.append (retVal, '
              <table class="grp" dir="rtl"><tbody><tr>
                <td style="width:50%;">' || LABEL_VALUE ('اسم المستورد:', x.X0_IMPR_NAME) || '</td>
                <td style="width:25%;">' || LABEL_VALUE ('الرقم الاستدلالى :', x.X0_BUS_ID) || '</td>
                <td style="width:25%;">' || LABEL_VALUE ('الرقم الفرعي:', x.X0_BUS_ID_BRNCH) || '</td>
              </tr></tbody></table>');
        END LOOP;

        -- M_ALL: CG$Q_IMPR_SUSPNS بالحرف (الـ bind variables بقت متغيرات)
        FOR q IN (-- --> 22/04/2009 AHMED A-MONIM

                    SELECT imp.bus_id,
                           imp.bus_id_brnch,
                           1          port_f0,
                           1          sts_f0,
                           imp.port_cd port_cd_f1,
                           imp.impr_nbr impr_nbr_f1,
                              ' إيقاف '
                           || ' من تاريخ '
                           || TO_CHAR (is_1.suspn_strt_dt, 'MI-MM-YYYY')
                           || ' إلى تاريخ '
                           || TO_CHAR (is_1.suspn_end_dt, 'MI-MM-YYYY')
                           || ' بسبب '
                           || is_1.suspn_rsn_text
                              txt_f1,
                              ' '
                           || DECODE (
                                 is_1.port_cd,
                                 99, DECODE (9,
                                             1, 'القيود',
                                             2, 'الإيرادات',
                                             4, 'الادارة القانونية',
                                             'المصلحة'),
                                 'الجمرك')
                              txt_f9
                      FROM importers imp, impr_suspns is_1
                     WHERE     imp.bus_id = v_p_bus_id
                           AND imp.PORT_CD = v_p_curr_port_cd
                           AND is_1.port_cd = imp.port_cd
                           AND is_1.impr_nbr = imp.impr_nbr
                           AND TO_CHAR (is_1.suspn_strt_dt, 'YYYY-MM-MI') <=
                                  TO_CHAR (v_cf_curr_dt, 'YYYY-MM-MI')
                           AND TO_CHAR (is_1.suspn_end_dt, 'YYYY-MM-MI') >=
                                  TO_CHAR (v_cf_curr_dt, 'YYYY-MM-MI')
                           AND is_1.suspn_rlse_dt IS NULL
                  GROUP BY imp.bus_id,
                           imp.bus_id_brnch,
                           1,
                           1,
                           imp.port_cd,
                           imp.impr_nbr,
                              ' إيقاف '
                           || ' من تاريخ '
                           || TO_CHAR (is_1.suspn_strt_dt, 'MI-MM-YYYY')
                           || ' إلى تاريخ '
                           || TO_CHAR (is_1.suspn_end_dt, 'MI-MM-YYYY')
                           || ' بسبب '
                           || is_1.suspn_rsn_text,
                              ' '
                           || DECODE (
                                 is_1.port_cd,
                                 99, DECODE (9,
                                             1, 'القيود',
                                             2, 'الإيرادات',
                                             4, 'الادارة القانونية',
                                             'المصلحة'),
                                 'الجمرك')
                  ---------------------------------------------------------------------------------------
                  UNION ALL
                    SELECT imp.bus_id,
                           imp.bus_id_brnch,
                           1,
                           2,
                           imp.port_cd,
                           imp.impr_nbr,
                           DECODE (
                              imp.bus_id_exprd_dt,
                              NULL, 'تاريخ إنتهاء النشاط غير مدخل',
                                 'السجل منتهي في '
                              || TO_CHAR (imp.bus_id_exprd_dt, 'MI-MM-YYYY')),
                           'الجمرك'
                      FROM importers imp
                     WHERE     imp.bus_id = v_p_bus_id
                           AND imp.PORT_CD = v_p_curr_port_cd
                           AND (imp.bus_id_exprd_dt IS NULL OR imp.bus_id_exprd_dt < v_cf_curr_dt)
                  GROUP BY imp.bus_id,
                           imp.bus_id_brnch,
                           1,
                           2,
                           imp.port_cd,
                           imp.impr_nbr,
                           DECODE (
                              imp.bus_id_exprd_dt,
                              NULL, 'تاريخ إنتهاء النشاط غير مدخل',
                                 'السجل منتهي في '
                              || TO_CHAR (imp.bus_id_exprd_dt, 'MI-MM-YYYY')),
                           'الجمرك'
                  ---------------------------------------------------------------------------------------
                  UNION ALL
                    SELECT imp.bus_id,
                           imp.bus_id_brnch,
                           0,
                           0,
                           0,
                           0,
                              ' حجز المستوردات'
                           || ' بالقرار رقم '
                           || is_1.seizure_nbr
                           || ' وتاريخ '
                           || TO_CHAR (is_1.seizure_date, 'MI-MM-YYYY')
                           || DECODE (9, 4, '', ' ومبلغ الحجز ' || is_1.szr_amount)
                           || ' وتاريخ بداية الحجز '
                           || TO_CHAR (is_1.szr_strt_date, 'MI-MM-YYYY')
                           || ' '
                           || 'وسبب الحجز الرئيسي'
                           || ' '
                           || decode(is_1.IMPR_SZR_M_RSN_CD,null,'لا يوجد',IMPR_UTILITIES.get_main_szr_rsn(is_1.IMPR_SZR_M_RSN_CD))
                           || ' '
                           ||'وسبب الحجز الفرعي'
                           || ' '
                           || decode(is_1.IMPR_SZR_S_RSN_CD,null,'لا يوجد',IMPR_UTILITIES.get_sub_szr_rsn(is_1.IMPR_SZR_M_RSN_CD,is_1.IMPR_SZR_S_RSN_CD))
                           || ' '
                           || is_1.rmrks status_txt,
                              ' '
                           || DECODE (9,
                                      1, 'القيود',
                                      2, 'الإيرادات',
                                      4, 'الادارة القانونية',
                                      'المصلحة')
                      FROM importers imp, importer_seizures is_1
                     WHERE     imp.bus_id = v_p_bus_id
                           AND imp.PORT_CD = v_p_curr_port_cd
                           AND is_1.hq_impr_nbr = imp.hq_impr_nbr
                           AND is_1.szr_status = 1
                  GROUP BY imp.bus_id,
                           imp.bus_id_brnch,
                           0,
                           0,
                           0,
                           0,
                              ' حجز المستوردات'
                           || ' بالقرار رقم '
                           || is_1.seizure_nbr
                           || ' وتاريخ '
                           || TO_CHAR (is_1.seizure_date, 'MI-MM-YYYY')
                           || DECODE (9, 4, '', ' ومبلغ الحجز ' || is_1.szr_amount)
                           || ' وتاريخ بداية الحجز '
                           || TO_CHAR (is_1.szr_strt_date, 'MI-MM-YYYY')
                           || ' '
                           || 'وسبب الحجز الرئيسي'
                           || ' '
                           || decode(is_1.IMPR_SZR_M_RSN_CD,null,'لا يوجد',IMPR_UTILITIES.get_main_szr_rsn(is_1.IMPR_SZR_M_RSN_CD))
                           || ' '
                           ||'وسبب الحجز الفرعي'
                           || ' '
                           || decode(is_1.IMPR_SZR_S_RSN_CD,null,'لا يوجد',IMPR_UTILITIES.get_sub_szr_rsn(is_1.IMPR_SZR_M_RSN_CD,is_1.IMPR_SZR_S_RSN_CD))
                           || ' '
                           || is_1.rmrks,
                              ' '
                           || DECODE (9,
                                      1, 'القيود',
                                      2, 'الإيرادات',
                                      4, 'الادارة القانونية',
                                      'المصلحة')
                  ---------------------------------------------------------------------------------------
                  UNION ALL
                    SELECT imp.bus_id,
                           imp.bus_id_brnch,
                           1,
                           4,
                           ci.port_cd,
                           ci.impr_nbr,
                              ' تعليمة جمركية رقم '
                           || ci.inst_isn
                           || ' وتاريخ '
                           || TO_CHAR (ci.inst_dt, 'MI-MM-YYYY')
                           || ' مصدرها '
                           || ci.inst_source
                           || ' رقم القرار '
                           || ci.dcre_nbr
                           || ' وتاريخ القرار '
                           || TO_CHAR (ci.dcre_dt, 'MI-MM-YYYY')
                           || '  '
                           || ci.notes,
                           'الجمرك'
                      FROM importers imp, cstms_insts ci
                     WHERE     imp.bus_id = v_p_bus_id
                           AND imp.PORT_CD = v_p_curr_port_cd
                           AND ci.port_cd = imp.port_cd
                           AND ci.impr_nbr = imp.impr_nbr
                           AND ci.inst_type = 1
                           AND ci.inst_status = 1
                  GROUP BY imp.bus_id,
                           imp.bus_id_brnch,
                           1,
                           4,
                           ci.port_cd,
                           ci.impr_nbr,
                              ' تعليمة جمركية رقم '
                           || ci.inst_isn
                           || ' وتاريخ '
                           || TO_CHAR (ci.inst_dt, 'MI-MM-YYYY')
                           || ' مصدرها '
                           || ci.inst_source
                           || ' رقم القرار '
                           || ci.dcre_nbr
                           || ' وتاريخ القرار '
                           || TO_CHAR (ci.dcre_dt, 'MI-MM-YYYY')
                           || '  '
                           || ci.notes,
                           'الجمرك'
                  ---------------------------------------------------------------------------------------
                  UNION ALL
                    SELECT imp.bus_id,
                           imp.bus_id_brnch,
                           DECODE (blk_deploy_dt, NULL, 1, 0),
                           5,
                           DECODE (blk.port_cd, NULL, blk.port_cd, 0),
                           0,
                              ' عدم تسديد فروقات الرسوم الجمركية يمسلسل '
                           || blk.blk_isn
                           || ' وتاريخ '
                           || TO_CHAR (blk.blk_start_dt, 'MI-MM-YYYY')
                           || DECODE (blk.diff_duty_amount,
                                      0, '',
                                      ' ومبلغ الفرق ' || blk.diff_duty_amount)
                           || DECODE (
                                 blk.blk_deploy_dt,
                                 NULL, '',
                                    ' وتاريخ تعميم الإيقاف '
                                 || TO_CHAR (blk.blk_deploy_dt, 'MI-MM-YYYY'))
                           || DECODE (blk.BLK_PORT_CD,
                                      NULL, '',
                                      ' ورمز جمرك الإيقاف ' || blk.BLK_PORT_CD)
                           || DECODE (blk.DIFFERENCE_ISN,
                                      NULL, '',
                                      ' ورقم مسلسل الفرق  ' || blk.DIFFERENCE_ISN)
                           || ' '
                           || blk.blk_rls_rmrks,
                           'التدقيق العام'
                      FROM importers         imp,
                           impr_duty_diff_blks blk,
                           cg_ref_codes      cg1,
                           cg_ref_codes      cg2,
                           cg_ref_codes      cg3
                     WHERE     imp.bus_id = v_p_bus_id
                           AND imp.PORT_CD = v_p_curr_port_cd
                           AND blk.hq_impr_nbr = imp.hq_impr_nbr
                           AND blk.blk_rls_dt IS NULL
                           AND cg1.rv_domain = 'BLK_RSN_CD'
                           AND cg1.rv_low_value = blk.blk_rsn_cd
                           AND cg2.rv_domain = 'BLK_SIDE_CD'
                           AND cg2.rv_low_value = blk.blk_side_cd
                           AND cg3.rv_domain = 'BLK_TYPE'
                           AND cg3.rv_low_value = blk.blk_type
                  GROUP BY imp.bus_id,
                           imp.bus_id_brnch,
                           DECODE (blk_deploy_dt, NULL, 1, 0),
                           5,
                           DECODE (blk.port_cd, NULL, blk.port_cd, 0),
                           0,
                              ' عدم تسديد فروقات الرسوم الجمركية يمسلسل '
                           || blk.blk_isn
                           || ' وتاريخ '
                           || TO_CHAR (blk.blk_start_dt, 'MI-MM-YYYY')
                           || DECODE (blk.diff_duty_amount,
                                      0, '',
                                      ' ومبلغ الفرق ' || blk.diff_duty_amount)
                           || DECODE (
                                 blk.blk_deploy_dt,
                                 NULL, '',
                                    ' وتاريخ تعميم الإيقاف '
                                 || TO_CHAR (blk.blk_deploy_dt, 'MI-MM-YYYY'))
                           || DECODE (blk.BLK_PORT_CD,
                                      NULL, '',
                                      ' ورمز جمرك الإيقاف ' || blk.BLK_PORT_CD)
                           || DECODE (
                                 blk.DIFFERENCE_ISN,
                                 NULL, '',
                                 ' ورقم مسلسل الفرق  ' || blk.DIFFERENCE_ISN)
                           || ' '
                           || blk.blk_rls_rmrks,
                           'التدقيق العام'
                  ---------------------------------------------------------------------------------------
                  UNION ALL
                    SELECT imp.bus_id,
                           imp.bus_id_brnch,
                           0,
                           6,
                           0,
                           0,
                              ' ملاحظة تفتبش دقيق يمسلسل '
                           || ins.inspctn_isn
                           || ' ورقم القرار '
                           || ins.decree_nbr
                           || ' وتاريخ '
                           || TO_CHAR (ins.decree_dt, 'MI-MM-YYYY')
                           || ins.decree_rsn,
                           'القيود'
                      FROM importers imp, impr_accur_inspctns ins
                     WHERE     imp.bus_id = v_p_bus_id
                           AND (ins.hq_impr_nbr = imp.hq_impr_nbr)
                           AND imp.PORT_CD = v_p_curr_port_cd
                  GROUP BY imp.bus_id,
                           imp.bus_id_brnch,
                           0,
                           6,
                           0,
                           0,
                              ' ملاحظة تفتبش دقيق يمسلسل '
                           || ins.inspctn_isn
                           || ' ورقم القرار '
                           || ins.decree_nbr
                           || ' وتاريخ '
                           || TO_CHAR (ins.decree_dt, 'MI-MM-YYYY')
                           || ins.decree_rsn,
                           'القيود'
                  ---------------------------------------------------------------------------------------
                  UNION ALL
                    SELECT imp.bus_id,
                           imp.bus_id_brnch,
                           1,
                           7,
                           imp.port_cd port_cd_f1,
                           imp.impr_nbr impr_nbr_f1,
                              ' قضية غير مقفلة على هذا المستورد وحالة القضية هي ( '
                           || rv_meaning
                           || ')'
                           || ' رقم القضية ( '
                           || case_accuseds.case_seq
                           || ')'
                           || ' تاريخ القضية ( '
                           || TO_CHAR (case_accuseds.case_date, 'MI-MM-YYYY')
                           || ')'
                              txt_f1,
                           ' '
                      FROM importers imp,
                           case_accuseds,
                           cg_ref_codes,
                           customs_cases
                     WHERE     rv_domain = 'CASE_STAGE'
                           AND rv_low_value = CASE_STAGE
                           AND CASE_STAGE != 21
                           AND imp.bus_id = v_p_bus_id
                           AND imp.PORT_CD = v_p_curr_port_cd
                           AND case_accuseds.port_cd = imp.port_cd
                           AND case_accuseds.impr_nbr = imp.impr_nbr
                           AND accused_type = 1
                           AND case_accuseds.port_cd = customs_cases.port_cd
                           AND case_accuseds.case_seq = customs_cases.case_seq
                           AND case_accuseds.case_date = customs_cases.case_date
                           AND v_pselect1 = 1
                  GROUP BY imp.bus_id,
                           imp.bus_id_brnch,
                           1,
                           7,
                           imp.port_cd,
                           imp.impr_nbr,
                              ' قضية غير مقفلة على هذا المستورد وحالة القضية هي ( '
                           || rv_meaning
                           || ')'
                           || ' رقم القضية ( '
                           || case_accuseds.case_seq
                           || ')'
                           || ' تاريخ القضية ( '
                           || TO_CHAR (case_accuseds.case_date, 'MI-MM-YYYY')
                           || ')',
                           ' '
                  ---------------------------------------------------------------------------------------
                  ---------------->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                  ---------------------------------------------------------------------------------------
                  UNION ALL
                    SELECT imp.bus_id,
                           imp.bus_id_brnch,
                           1,
                           8,
                           imp.port_cd,
                           imp.impr_nbr,
                              ' لا يمكن إضافة تعهد جديد يوجد تعهد فاتورة للمستورد لم يسدد '
                           || '   برقم '
                           || wvr.wvr_seq_nbr
                           || ' وتاريخ '
                           || TO_CHAR (wvr.issued_dt, 'MI-MM-YYYY')
                           || ' ',
                           ' '
                      FROM importers imp, waivers wvr, wvr_items wi
                     WHERE     imp.bus_id = v_p_bus_id
                           AND imp.PORT_CD = v_p_curr_port_cd
                           AND wi.wvr_port_cd = wvr.wvr_port_cd
                           AND wi.wvr_seq_nbr = wvr.wvr_seq_nbr
                           AND wi.issued_dt = wvr.issued_dt
                           AND wi.item_type_cd = 1
                           AND wvr.wvr_status = 1
                           AND wvr.wvr_port_cd = imp.port_cd(+)
                           AND wvr.impr_nbr = imp.impr_nbr(+)
                           AND (wi.item_status IS NULL OR wi.item_status = '0')
                           AND wi.item_end_dt < v_cf_curr_dt
                           AND TO_CHAR (wi.item_issue_dt, 'YYYY-MM-MI') > '1427-02-26'
                           AND v_p_curr_port_cd != 99
                  GROUP BY imp.bus_id,
                           imp.bus_id_brnch,
                           1,
                           8,
                           imp.port_cd,
                           imp.impr_nbr,
                              ' لا يمكن إضافة تعهد جديد يوجد تعهد فاتورة للمستورد لم يسدد '
                           || '   برقم '
                           || wvr.wvr_seq_nbr
                           || ' وتاريخ '
                           || TO_CHAR (wvr.issued_dt, 'MI-MM-YYYY')
                           || ' ',
                           ' '
                  ---------------------------------------------------------------------------------------
                  UNION ALL
                    SELECT imp.bus_id,
                           imp.bus_id_brnch,
                           1,
                           9,
                           imp.port_cd,
                           imp.impr_nbr,
                              ' لا يمكن إضافة تعهد جديد يوجد تعهد شهادة منشأ للمستورد  لم    يسدد '
                           || ' برقم '
                           || wvr.wvr_seq_nbr
                           || ' وتاريخ '
                           || TO_CHAR (wvr.issued_dt, 'MI-MM-YYYY')
                           || ' ',
                           ' '
                      FROM importers imp, waivers wvr, wvr_items wi
                     WHERE     imp.bus_id = v_p_bus_id
                           AND imp.PORT_CD = v_p_curr_port_cd
                           AND wi.wvr_port_cd = wvr.wvr_port_cd
                           AND wi.wvr_seq_nbr = wvr.wvr_seq_nbr
                           AND wi.issued_dt = wvr.issued_dt
                           AND wi.item_type_cd = 2
                           AND wvr.wvr_status = 1
                           AND wvr.wvr_port_cd = imp.port_cd(+)
                           AND wvr.impr_nbr = imp.impr_nbr(+)
                           AND (wi.item_status IS NULL OR wi.item_status = '0')
                           AND wi.item_end_dt < v_cf_curr_dt
                           AND TO_CHAR (wi.item_issue_dt, 'YYYY-MM-MI') > '1427-02-26'
                           AND v_p_curr_port_cd != 99
                  GROUP BY imp.bus_id,
                           imp.bus_id_brnch,
                           1,
                           9,
                           imp.port_cd,
                           imp.impr_nbr,
                              ' لا يمكن إضافة تعهد جديد يوجد تعهد شهادة منشأ للمستورد  لم    يسدد '
                           || ' برقم '
                           || wvr.wvr_seq_nbr
                           || ' وتاريخ '
                           || TO_CHAR (wvr.issued_dt, 'MI-MM-YYYY')
                           || ' ',
                           ' '
                  ---------------------------------------------------------------------------------------
                  UNION ALL
                    SELECT imp.bus_id,
                           imp.bus_id_brnch,
                           1,
                           10,
                           imp.port_cd,
                           imp.impr_nbr,
                              ' لا يمكن إضافة تعهد جديد لهذا المستورد لوجود حرمان من ميزة الفسح بتعهد '
                           || ' برقم '
                           || ex.ed_dcre_nbr
                           || ' وتاريخ '
                           || TO_CHAR (ex.ed_dcre_date, 'MI-MM-YYYY')
                           || ' ',
                           ' '
                      FROM importers imp, importer_excludeds ex
                     WHERE     imp.bus_id = v_p_bus_id
                           AND imp.PORT_CD = v_p_curr_port_cd
                           AND imp.hq_impr_nbr = ex.hq_impr_nbr
                           AND (ex.dcre_type = 1)
                           AND v_p_curr_port_cd != 99
                  GROUP BY imp.bus_id,
                           imp.bus_id_brnch,
                           1,
                           10,
                           imp.port_cd,
                           imp.impr_nbr,
                              ' لا يمكن إضافة تعهد جديد لهذا المستورد لوجود حرمان من ميزة الفسح بتعهد '
                           || ' برقم '
                           || ex.ed_dcre_nbr
                           || ' وتاريخ '
                           || TO_CHAR (ex.ed_dcre_date, 'MI-MM-YYYY')
                           || ' ',
                           ' '
                  ---------------------------------------------------------------------------------------
                  UNION ALL
                    SELECT imp.bus_id,
                           imp.bus_id_brnch,
                           1,
                           11,
                           imp.port_cd,
                           imp.impr_nbr,
                              ' لا يمكن إضافة تعهد جديد لهذا المستورد لوجود حرمان من ميزة الفسح بتعهد '
                           || ' برقم '
                           || ex.ed_dcre_nbr
                           || ' وتاريخ '
                           || TO_CHAR (ex.ed_dcre_date, 'MI-MM-YYYY')
                           || ' ',
                           ' '
                      FROM importers imp, importer_excludeds ex, exclusion_decrees DEC
                     WHERE     imp.bus_id = v_p_bus_id
                           AND imp.PORT_CD = v_p_curr_port_cd
                           AND imp.hq_impr_nbr = ex.hq_impr_nbr
                           AND ex.dcre_type = 2
                           AND ex.ed_dcre_nbr = DEC.dcre_nbr
                           AND ex.ed_dcre_date = DEC.dcre_date
                           AND DEC.dcre_expr_date > v_cf_curr_dt
                           AND v_p_curr_port_cd != 99
                  GROUP BY imp.bus_id,
                           imp.bus_id_brnch,
                           1,
                           11,
                           imp.port_cd,
                           imp.impr_nbr,
                              ' لا يمكن إضافة تعهد جديد لهذا المستورد لوجود حرمان من ميزة الفسح بتعهد '
                           || ' برقم '
                           || ex.ed_dcre_nbr
                           || ' وتاريخ '
                           || TO_CHAR (ex.ed_dcre_date, 'MI-MM-YYYY')
                           || ' ',
                           ' '
                  ---------------------------------------------------------------------------------------
                  UNION ALL
                    SELECT imp.bus_id,
                           imp.bus_id_brnch,
                           1,
                           12,
                           imp.port_cd,
                           imp.impr_nbr,
                              ' لا يمكن إضافة تعهد جديد يوجد تعهد (عدم تصرف) منتهي للمستورد لم يسدد '
                           || ' برقم '
                           || wvr.wvr_seq_nbr
                           || ' وتاريخ '
                           || TO_CHAR (wvr.issued_dt, 'MI-MM-YYYY')
                           || ' ',
                           ' '
                      FROM importers imp, waivers wvr, wvr_items wi
                     WHERE     imp.bus_id = v_p_bus_id
                           AND imp.PORT_CD = v_p_curr_port_cd
                           AND wi.wvr_port_cd = wvr.wvr_port_cd
                           AND wi.wvr_seq_nbr = wvr.wvr_seq_nbr
                           AND wi.issued_dt = wvr.issued_dt
                           AND wi.item_type_cd = 9
                           AND wvr.wvr_status = 1
                           AND wvr.wvr_port_cd = imp.port_cd(+)
                           AND wvr.impr_nbr = imp.impr_nbr(+)
                           AND (wi.item_status IS NULL OR wi.item_status = '0')
                           AND TO_CHAR (wi.item_end_dt, 'YYYY-MM-MI') <
                                  TO_CHAR (v_cf_curr_dt, 'YYYY-MM-MI')
                           --AND TO_CHAR (wi.item_end_dt, 'YYYY-MM-MI') < TO_CHAR(HIJDATE_DB.Cur_Hij_Date,'YYYY-MM-MI')
                           AND v_p_curr_port_cd != 99
                  GROUP BY imp.bus_id,
                           imp.bus_id_brnch,
                           1,
                           12,
                           imp.port_cd,
                           imp.impr_nbr,
                              ' لا يمكن إضافة تعهد جديد يوجد تعهد (عدم تصرف) منتهي للمستورد لم يسدد '
                           || ' برقم '
                           || wvr.wvr_seq_nbr
                           || ' وتاريخ '
                           || TO_CHAR (wvr.issued_dt, 'MI-MM-YYYY')
                           || ' ',
                           ' '
                  --------------------------------------------------------------------------------------
                  UNION ALL
                    SELECT imp.bus_id,
                           imp.bus_id_brnch,
                           1,
                           13,
                           imp.port_cd,
                           imp.impr_nbr,
                              ' توجد بضاعة ليس مسجل عليها دلالة منشأ سيتم إلزام المستورد بإعادة تصدير البضاعة وتغريمه 5000 ريال لوجود   تعهدات سابقة '
                           || ' برقم '
                           || wvr.wvr_seq_nbr
                           || ' وتاريخ '
                           || TO_CHAR (wvr.issued_dt, 'MI-MM-YYYY')
                           || ' ',
                           ' '
                      FROM importers imp, wvr_items_globals wvr
                     WHERE     imp.bus_id = v_p_bus_id
                           AND imp.PORT_CD = v_p_curr_port_cd
                           AND wvr.wvr_port_cd = imp.port_cd(+)
                           AND wvr.impr_nbr = imp.impr_nbr(+)
                           AND wvr.item_type_cd = 7
                           AND wvr.bus_id = v_p_bus_id
                           AND (wvr.item_status <> 9 OR wvr.item_status IS NULL)
                           AND TO_CHAR (wvr.item_issue_dt, 'RRRR-MM-MI') >= '1430-02-01'
                           AND v_p_curr_port_cd != 99
                  GROUP BY imp.bus_id,
                           imp.bus_id_brnch,
                           1,
                           13,
                           imp.port_cd,
                           imp.impr_nbr,
                              ' توجد بضاعة ليس مسجل عليها دلالة منشأ سيتم إلزام المستورد بإعادة تصدير البضاعة وتغريمه 5000 ريال لوجود   تعهدات سابقة '
                           || ' برقم '
                           || wvr.wvr_seq_nbr
                           || ' وتاريخ '
                           || TO_CHAR (wvr.issued_dt, 'MI-MM-YYYY')
                           || ' ',
                           ' '
                  --------------------------------------------------------------------------------------
                  UNION ALL
                    SELECT imp.bus_id,
                           imp.bus_id_brnch,
                           1,
                           14,
                           imp.port_cd port_cd_f1,
                           imp.impr_nbr impr_nbr_f1,
                              ' إيقاف مركزي '
                           || ' من تاريخ '
                           || TO_CHAR (is_1.suspn_strt_dt, 'MI-MM-YYYY')
                           || ' إلى تاريخ '
                           || TO_CHAR (is_1.suspn_end_dt, 'MI-MM-YYYY')
                           || ' بسبب '
                           || is_1.suspn_rsn_text
                              txt_f1,
                           ' ' || cg1.rv_meaning
                      FROM importers imp, impr_cntrl_suspns is_1, cg_ref_codes cg1
                     WHERE     imp.bus_id = v_p_bus_id
                           AND imp.PORT_CD = v_p_curr_port_cd
                           AND is_1.hq_impr_nbr = imp.hq_impr_nbr
                           AND TO_CHAR (is_1.suspn_strt_dt, 'YYYY-MM-MI') <=
                                  TO_CHAR (v_cf_curr_dt, 'YYYY-MM-MI')
                           AND TO_CHAR (is_1.suspn_end_dt, 'YYYY-MM-MI') >=
                                  TO_CHAR (v_cf_curr_dt, 'YYYY-MM-MI')
                           AND is_1.suspn_rlse_dt IS NULL
                           AND cg1.rv_domain = 'SUSPN SIDE CD'
                           AND cg1.rv_low_value = is_1.suspn_side_cd
                  GROUP BY imp.bus_id,
                           imp.bus_id_brnch,
                           1,
                           14,
                           imp.port_cd,
                           imp.impr_nbr,
                              ' إيقاف مركزي '
                           || ' من تاريخ '
                           || TO_CHAR (is_1.suspn_strt_dt, 'MI-MM-YYYY')
                           || ' إلى تاريخ '
                           || TO_CHAR (is_1.suspn_end_dt, 'MI-MM-YYYY')
                           || ' بسبب '
                           || is_1.suspn_rsn_text,
                           ' ' || cg1.rv_meaning
                  ---------------------------------------------------------------------------------------
                  --------------------------------------------------------------------------------------
                  ---------------->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                  ---------------------------------------------------------------------------------------
                  ---------------->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                  ORDER BY 3, 5, 4)
        LOOP
            -- R_2 (G_PORT_F0): M_HEADER لكل مجموعة
            IF v_prev_port_f0 IS NULL OR v_prev_port_f0 <> q.PORT_F0 THEN
                IF v_prev_port_f0 IS NOT NULL THEN
                    dbms_lob.append (retVal, '</tbody></table>');
                END IF;
                v_prev_port_f0 := q.PORT_F0;
                v_count := 0;
                dbms_lob.append (retVal, '
              <table class="data" dir="rtl" style="margin-top:8px;"><thead><tr>
                <th style="width:4%;">#</th>'
                    || CASE WHEN q.PORT_F0 = 0 THEN '<th colspan="2" style="width:23%;">مستوى الإيقاف</th>'
                            ELSE '<th style="width:15%;">مستوى الإيقاف</th><th style="width:8%;">رقم المستورد</th>' END
                    || '<th style="width:12%;">رقم الاستدلالي الرئيسي</th><th style="width:10%;">الرقم الفرعي</th>
                <th style="width:17%;">اسم المستورد</th><th style="width:25%;">الحالة</th><th style="width:9%;">الإدارة</th>
              </tr></thead><tbody>');
            END IF;

            -- R_1 (G_C_PORT_CD)
            v_count := v_count + 1;
            dbms_lob.append (retVal, '<tr>' || HTML_CELL (v_count)
                || CASE WHEN q.PORT_F0 = 0 THEN '<td colspan="2">' || APEX_ESCAPE.HTML (CF_X1Formula (q.PORT_CD_F1)) || '</td>'
                        ELSE HTML_CELL (CF_X1Formula (q.PORT_CD_F1)) || HTML_CELL (CF_IMPR_NBR_XFormula (q.IMPR_NBR_F1)) END
                || HTML_CELL (q.BUS_ID) || HTML_CELL (q.BUS_ID_BRNCH)
                || HTML_CELL (impr_name_dumFormula (q.PORT_F0, v_p_bus_id, q.PORT_CD_F1, q.IMPR_NBR_F1), 'text-align:right;')
                || HTML_CELL (q.TXT_F1, 'text-align:right;') || HTML_CELL (q.TXT_F9) || '</tr>');
        END LOOP;

        IF v_prev_port_f0 IS NOT NULL THEN
            dbms_lob.append (retVal, '</tbody></table>');
        END IF;

        dbms_lob.append (retVal, '
    </td>
  </tr>
</tbody>
</table>
<div id="MRD-Footer"><table border="0" cellpadding="1" cellspacing="1" style="width:100%"><tbody><tr><td></td></tr></tbody></table></div>
</div>
</div>
');
        RETURN retVal;
    END ARD_IMPR2170;
END IMPR2170_ARD;
/
SHOW ERRORS


CREATE OR REPLACE PUBLIC SYNONYM IMPR2170_ARD FOR LIB_APX_USR.IMPR2170_ARD;


GRANT EXECUTE ON LIB_APX_USR.IMPR2170_ARD TO LIB_USR;

GRANT EXECUTE ON LIB_APX_USR.IMPR2170_ARD TO SECURITY_DEFAULT;

GRANT EXECUTE ON LIB_APX_USR.IMPR2170_ARD TO SECURITY_PROD;

GRANT EXECUTE ON LIB_APX_USR.IMPR2170_ARD TO CUSTOMS;
