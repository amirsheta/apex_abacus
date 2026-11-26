-- =============================================================================
-- Package body: IMPR2150_ARD   (matches IMPR2150_ARD_spec.sql)   Version: 001
-- Layout of IMPR2150.rdf (Landscape, right to left):
--   margin : port name, logo, الرقم / التاريخ / المرفقات, title P_MODULE_NAME, footer report number + dates + page
--   R_2 (G_HQ_IMPR_NBR): الرقم الموحد للمستورد + الاسم / نوع الرقم الاستدلالي, الرقم الاستدلالي, الفرع
--   R_1 (per exception): header row + rows: مسلسل الإستثناء, حالة السجل, نوع الإستثناء, استخدام الإستثناء
--   (first port line) next to R_CG$G_AGNTS (per port): رمز الجمرك, اسم الجمرك, حالة السجل.
-- =============================================================================
SET DEFINE OFF

CREATE OR REPLACE PACKAGE BODY LIB_APX_USR.IMPR2150_ARD
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

    -- CF_REC_STATUSFormula بالحرف من الـ RDF
    FUNCTION CF_REC_STATUSFormula (P_REC_STATUS NUMBER) RETURN VARCHAR2 IS
    	V_RV_MEANING CG_REF_CODES.RV_MEANING%TYPE;
    begin
      SELECT RV_MEANING INTO V_RV_MEANING
      FROM CG_REF_CODES
      WHERE RV_DOMAIN ='REC_STATUS'
      AND RV_LOW_VALUE =P_REC_STATUS;
      RETURN  V_RV_MEANING;
    EXCEPTION
    	WHEN OTHERS THEN RETURN NULL;
    end;

    -- CF_REC_STATUS2Formula بالحرف من الـ RDF
    FUNCTION CF_REC_STATUS2Formula (P_REC_STATUS NUMBER) RETURN VARCHAR2 IS
    	V_RV_MEANING CG_REF_CODES.RV_MEANING%TYPE;
    begin
      SELECT RV_MEANING INTO V_RV_MEANING
      FROM CG_REF_CODES
      WHERE RV_DOMAIN ='REC_STATUS'
      AND RV_LOW_VALUE =P_REC_STATUS;
      RETURN  V_RV_MEANING;
    EXCEPTION
    	WHEN OTHERS THEN RETURN NULL;
    end;

    -- CF_RUL_TYPEFormula بالحرف من الـ RDF
    FUNCTION CF_RUL_TYPEFormula (P_RULE_TYPE NUMBER) RETURN VARCHAR2 IS
    	V_RV_MEANING CG_REF_CODES.RV_MEANING%TYPE;
    begin
      SELECT RV_MEANING INTO V_RV_MEANING
      FROM CG_REF_CODES
      WHERE RV_DOMAIN ='RULE_TYPE'
      AND RV_LOW_VALUE =P_RULE_TYPE
      AND ROWNUM=1;
      RETURN  V_RV_MEANING;
    EXCEPTION
    	WHEN OTHERS THEN RETURN NULL;
    end;

    -- CF_BUS_TYPE_IDFormula بالحرف من الـ RDF
    FUNCTION CF_BUS_TYPE_IDFormula (P_BUS_ID_TYPE_CD NUMBER) RETURN VARCHAR2 IS
    	V_BUS_ID_TYPE_NAME	VARCHAR2(400);
    begin
    	SELECT BUS_ID_TYPE_NAME INTO V_BUS_ID_TYPE_NAME
    	FROM BUS_ID_TYPES
    	WHERE BUS_ID_TYPE_CD = P_BUS_ID_TYPE_CD;
    	RETURN V_BUS_ID_TYPE_NAME;
    EXCEPTION
    	WHEN OTHERS THEN RETURN NULL;
    end;

    -- CF_ALL_BRANCHESFormula بالحرف من الـ RDF
    FUNCTION CF_ALL_BRANCHESFormula (P_ALL_BRNCH_FLAG NUMBER) RETURN VARCHAR2 IS
    	V_RET VARCHAR2(50);
    begin
      IF P_ALL_BRNCH_FLAG = 1 THEN
      	V_RET :='جميع الفروع' ;
      ELSE
      	V_RET :='فرع محدد' ;
      END IF;
      RETURN V_RET;
    end;

    -- CF_BRCH_LBLFormula بالحرف من الـ RDF
    FUNCTION CF_BRCH_LBLFormula (P_BUS_ID_BRNCH VARCHAR2) RETURN VARCHAR2 IS
    begin
      IF P_BUS_ID_BRNCH IS NOT NULL THEN
      	RETURN 'فرع :';
      ELSE
      	RETURN '';
      END IF;
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

    FUNCTION ARD_IMPR2150 (P_PARAMETER1   IN VARCHAR2 DEFAULT NULL,
                           P_PARAMETER2   IN VARCHAR2 DEFAULT NULL,
                           P_PARAMETER3   IN VARCHAR2 DEFAULT NULL,
                           P_PARAMETER4   IN VARCHAR2 DEFAULT NULL,
                           P_PARAMETER5   IN VARCHAR2 DEFAULT NULL,
                           P_PARAMETER6   IN VARCHAR2 DEFAULT NULL)
        RETURN CLOB
    IS
        retVal                 CLOB;
        v_p_curr_port_cd       NUMBER := TO_NUMBER (P_PARAMETER1);
        v_p_hq_impr_nbr        NUMBER := TO_NUMBER (P_PARAMETER2);
        v_p_rec_status         NUMBER := TO_NUMBER (P_PARAMETER3);
        v_p_rule_type          NUMBER := TO_NUMBER (P_PARAMETER4);
        v_p_module_name        VARCHAR2 (4000) := P_PARAMETER5;
        v_p_report_no          VARCHAR2 (4000) := P_PARAMETER6;
        v_port_name            VARCHAR2 (100);   -- V_PORT_NAME_SEC1
        v_hq_key               VARCHAR2 (4000);
        v_prev_hq_key          VARCHAR2 (4000);  -- G_HQ_IMPR_NBR اللي فات
        v_rule_key             VARCHAR2 (4000);
        v_prev_rule_key        VARCHAR2 (4000);  -- G_L_IMP_ARBC_IMPR_NAME اللي فات
    BEGIN
        DBMS_LOB.createtemporary (retVal, TRUE);

        v_port_name := V_PORT_NAME_SEC1FormatTrigger (v_p_curr_port_cd);
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

        -- الهيدر بيتكرر في كل صفحة: اسم الجمرك يمين، اللوجو في النص، الرقم / التاريخ / المرفقات شمال، والعنوان تحت
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
            <td style="width:25%;vertical-align:bottom;"><span style="color:#0e0f50;font-size:12px;font-weight:bold;">' || APEX_ESCAPE.HTML (v_port_name) || '</span></td>
            <td style="width:50%;text-align:center;">');
        dbms_lob.append (retVal, ARD_LOGO.IMG (85, 335, NULL, 'LOGO1.jpg'));   -- اللوجو Static File في الأبلكيشن (DEC-034)، في نص الصفحة
        dbms_lob.append (retVal, '</td>
            <td style="width:25%;text-align:left;vertical-align:top;">
              <p class="lbl" style="margin:2px;">الرقم :</p>
              <p class="lbl" style="margin:2px;">التاريخ :</p>
              <p class="lbl" style="margin:2px;">المرفقات :</p>
            </td>
          </tr>
        </tbody>
      </table>
      <p style="text-align:center;margin:2px;"><span style="color:#0e0f50;font-size:14px;font-weight:bold;">' || APEX_ESCAPE.HTML (v_p_module_name) || '</span></p>
    </div></td>
  </tr>
</thead>
<tfoot>
  <tr>
    <td><div class="MRDFooter">
      <table border="0" cellpadding="1" cellspacing="1" dir="rtl" style="width:100%;">
        <tbody>
          <tr>
            <td style="font-size:11px;color:#0e0f50;">رقم التقرير: <span style="color:#707070;">' || APEX_ESCAPE.HTML (v_p_report_no) || '</span></td>
            <td style="font-size:11px;color:#0e0f50;">تاريخه : <span style="color:#707070;">' || TO_CHAR (HIJDATE_DB.CUR_HIJ_DATE, 'MI-MM-YYYY') || '</span> هـ
               / <span style="color:#707070;">' || TO_CHAR (SYSDATE, 'DD-MM-YYYY') || '</span> م</td>
          </tr>
        </tbody>
      </table>
    </div></td>
  </tr>
</tfoot>
<tbody>
  <tr>
    <td>');

        FOR q IN (SELECT IMPR_RULE_PORTS.PORT_CD,
                         IMPR_RULE_PORTS.REC_STATUS,
                         ' ' || SD_PORTS.PORT_NAME PORT_NAME,
                         IMPR_RULES.RULE_ISN,
                         IMPR_RULES.BUS_ID_TYPE_CD,
                         IMPR_RULES.BUS_ID,
                         IMPR_RULES.BUS_ID_BRNCH,
                         IMPR_RULES.ALL_BRNCH_FLAG,
                         IMPR_RULES.RULE_TYPE,
                         IMPR_RULES.HQ_IMPR_NBR,
                         SINGLE_IMPORTERS.ARBC_IMPR_NAME
                    FROM IMPR_RULES, IMPR_RULE_PORTS, SD_PORTS, SINGLE_IMPORTERS
                   WHERE     IMPR_RULE_PORTS.RULE_ISN = IMPR_RULES.RULE_ISN
                         AND IMPR_RULE_PORTS.PORT_CD = SD_PORTS.PORT_CD
                         AND (IMPR_RULES.RULE_TYPE = v_p_rule_type OR v_p_rule_type IS NULL)
                         AND IMPR_RULES.HQ_IMPR_NBR = SINGLE_IMPORTERS.HQ_IMPR_NBR
                         AND (IMPR_RULES.HQ_IMPR_NBR = v_p_hq_impr_nbr OR v_p_hq_impr_nbr IS NULL)
                         AND (   (v_p_rec_status = 1 AND IMPR_RULES.REC_STATUS = 1 AND IMPR_RULE_PORTS.REC_STATUS = 1)
                              OR (v_p_rec_status = 0 AND IMPR_RULES.REC_STATUS = 0))
                   ORDER BY IMPR_RULES.HQ_IMPR_NBR, SINGLE_IMPORTERS.ARBC_IMPR_NAME, IMPR_RULES.BUS_ID,
                            IMPR_RULES.BUS_ID_BRNCH, IMPR_RULES.BUS_ID_TYPE_CD, IMPR_RULES.RULE_ISN,
                            IMPR_RULES.RULE_TYPE, IMPR_RULES.ALL_BRNCH_FLAG, IMPR_RULE_PORTS.REC_STATUS,
                            IMPR_RULE_PORTS.PORT_CD)
        LOOP
            v_hq_key := q.HQ_IMPR_NBR || '|' || q.ARBC_IMPR_NAME || '|' || q.BUS_ID || '|' || q.BUS_ID_BRNCH || '|' || q.BUS_ID_TYPE_CD;
            v_rule_key := v_hq_key || '|' || q.RULE_ISN || '|' || q.RULE_TYPE || '|' || q.ALL_BRNCH_FLAG || '|' || q.REC_STATUS;

            IF v_prev_rule_key IS NOT NULL AND v_prev_rule_key <> v_rule_key THEN
                dbms_lob.append (retVal, '</tbody></table>');
            END IF;

            -- R_2 (G_HQ_IMPR_NBR)
            IF v_prev_hq_key IS NULL OR v_prev_hq_key <> v_hq_key THEN
                v_prev_hq_key := v_hq_key;
                dbms_lob.append (retVal, '
              <table class="grp" dir="rtl"><tbody>
                <tr><td colspan="3">' || LABEL_VALUE ('الرقم الموحد للمستورد :', q.HQ_IMPR_NBR) || '&nbsp;&nbsp;<span class="val">'
                                    || APEX_ESCAPE.HTML (q.ARBC_IMPR_NAME) || '</span></td></tr>
                <tr><td style="width:40%;">' || LABEL_VALUE ('نوع الرقم الاستدلالي :', CF_BUS_TYPE_IDFormula (q.BUS_ID_TYPE_CD)) || '</td>
                    <td style="width:35%;">' || LABEL_VALUE ('الرقم الاستدلالي :', q.BUS_ID) || '</td>
                    <td style="width:25%;">' || LABEL_VALUE (CF_BRCH_LBLFormula (q.BUS_ID_BRNCH), q.BUS_ID_BRNCH) || '</td></tr>
              </tbody></table>');
            END IF;

            -- R_1 (per exception): الهيدر وخانات الاستثناء في أول سطر
            IF v_prev_rule_key IS NULL OR v_prev_rule_key <> v_rule_key THEN
                v_prev_rule_key := v_rule_key;
                dbms_lob.append (retVal, '
              <table class="data" dir="rtl" style="margin-bottom:6px;"><thead><tr>
                <th style="width:10%;">مسلسل الإستثناء</th><th style="width:9%;">حالة السجل</th><th style="width:20%;">نــوع الإستثناء</th>
                <th style="width:12%;">استخدام الإستثناء</th><th style="width:9%;">رمز الجمرك</th><th style="width:28%;">اسم الجمرك</th>
                <th style="width:12%;">حالة السجل</th>
              </tr></thead><tbody>');
                dbms_lob.append (retVal, '<tr>' || HTML_CELL (q.RULE_ISN) || HTML_CELL (CF_REC_STATUSFormula (q.REC_STATUS))
                                         || HTML_CELL (CF_RUL_TYPEFormula (q.RULE_TYPE)) || HTML_CELL (CF_ALL_BRANCHESFormula (q.ALL_BRNCH_FLAG)));
            ELSE
                dbms_lob.append (retVal, '<tr><td></td><td></td><td></td><td></td>');
            END IF;

            -- R_CG$G_AGNTS
            dbms_lob.append (retVal, HTML_CELL (q.PORT_CD) || HTML_CELL (q.PORT_NAME, 'text-align:right;')
                                     || HTML_CELL (CF_REC_STATUS2Formula (q.REC_STATUS)) || '</tr>');
        END LOOP;

        IF v_prev_rule_key IS NOT NULL THEN
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
    END ARD_IMPR2150;
END IMPR2150_ARD;
/
SHOW ERRORS


CREATE OR REPLACE PUBLIC SYNONYM IMPR2150_ARD FOR LIB_APX_USR.IMPR2150_ARD;


GRANT EXECUTE ON LIB_APX_USR.IMPR2150_ARD TO LIB_USR;

GRANT EXECUTE ON LIB_APX_USR.IMPR2150_ARD TO SECURITY_DEFAULT;

GRANT EXECUTE ON LIB_APX_USR.IMPR2150_ARD TO SECURITY_PROD;

GRANT EXECUTE ON LIB_APX_USR.IMPR2150_ARD TO CUSTOMS;
