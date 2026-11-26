-- =============================================================================
-- Package body: IMPR2310_ARD   (matches IMPR2310_ARD_spec.sql)   Version: 001
-- Layout of IMPR2310.rdf (Landscape, right to left):
--   margin : port name, logo, الرقم / التاريخ / المرفقات, title P_MODULE_NAME + CF_TITLE, footer report number
--            + dates + page
--   M_CG$G_IMPORTERS_HDR once (repeated on every page by thead), then R_1 (G_SUPP_SRCE_CD, per letter):
--   جمرك / جهة / رقم / تاريخ الخطاب, اسم المستخدم on the first line, next to R_CG$G_IMPORTERS rows: نوع
--   المستورد, الرقم الجمركي, اسم المستورد, نوع الرقم الإستدلالي, الرقم الاستدلالى, الفرع, الرقم الموحد.
--   C_CODEFormula is in the RDF group but not in the layout; kept for the same package API as IMPR2110_ARD.
-- =============================================================================
SET DEFINE OFF

CREATE OR REPLACE PACKAGE BODY LIB_APX_USR.IMPR2310_ARD
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

    -- C_CODEFormula بالحرف من الـ RDF
    FUNCTION C_CODEFormula (P_CITY_CODE NUMBER) RETURN VARCHAR2 IS
    C_NAME		VARCHAR2 (100) ;
    begin
      SELECT CITY_ARB_NAME  INTO C_NAME
      FROM CITIES
      WHERE CITY_CD = P_CITY_CODE ;
      RETURN (C_NAME);
    EXCEPTION
    	WHEN OTHERS THEN
    	RETURN (NULL);
    end;

    -- v_name2Formula بالحرف من الـ RDF
    FUNCTION v_name2Formula (P_BUS_ID_TYPE_CD NUMBER) RETURN VARCHAR2 IS
    V_NAME VARCHAR2(100);
    begin
      SELECT BUS_ID_TYPE_NAME
      INTO   V_NAME
      FROM   BUS_ID_TYPES
      WHERE  BUS_ID_TYPE_CD = P_BUS_ID_TYPE_CD ;
      RETURN (V_NAME);
    end;

    -- V_NAMEFormula بالحرف من الـ RDF
    FUNCTION V_NAMEFormula (P_IMPR_TYPE_CD NUMBER) RETURN VARCHAR2 IS
    V_NAME VARCHAR2(100);
    begin
       SELECT ' '||IMPR_TYPE_NAME
      INTO   V_NAME
      FROM   IMPR_TYPES
      WHERE  IMPR_TYPE_CD  = P_IMPR_TYPE_CD ;
      RETURN (V_NAME);
    end;

    -- CF_SUPP_PORT_NAMEFormula بالحرف من الـ RDF
    FUNCTION CF_SUPP_PORT_NAMEFormula (P_SUPP_SRCE_CD NUMBER) RETURN VARCHAR2 IS
    V_RET VARCHAR2(100);
    begin
      SELECT ' '||PORT_NAME INTO V_RET FROM SD_PORTS WHERE
      PORT_CD=P_SUPP_SRCE_CD;
      RETURN(V_RET);
    EXCEPTION
    	WHEN OTHERS THEN
    	RETURN(NULL);
    end;

    -- CF_DEPTFormula بالحرف من الـ RDF
    FUNCTION CF_DEPTFormula (P_SUPP_TITLE_CD NUMBER) RETURN VARCHAR2 IS
    V_RET VARCHAR2(100);
    begin
      SELECT ' '||SUPP_TITLE_NM INTO V_RET FROM SUPP_TITLES WHERE
      SUPP_TITLE_CD=P_SUPP_TITLE_CD;
      RETURN(V_RET);
    EXCEPTION
    	WHEN OTHERS THEN
    	RETURN(NULL);
    end;

    -- CF_TITLEFormula بالحرف من الـ RDF
    FUNCTION CF_TITLEFormula (P_REPORT1 NUMBER) RETURN VARCHAR2 IS
    begin
      IF P_REPORT1=0 THEN
      	RETURN('بيانات المستوردين المعدلة');
      ELSIF P_REPORT1=1 THEN
      	RETURN('بيانات المستوردين المضافة');
      ELSE
      	RETURN(NULL);
      END IF;
    end;

    -- CF_USERFormula بالحرف من الـ RDF
    FUNCTION CF_USERFormula (P_JN_ORACLE_USER VARCHAR2, P_CURR_PORT_CD NUMBER) RETURN VARCHAR2 IS
    CH VARCHAR2(100);
    begin
      SELECT USR_ANAME INTO CH FROM SC_USERS WHERE USER_ID=P_JN_ORACLE_USER AND PORT_CD = P_CURR_PORT_CD ;
       RETURN(CH);
    EXCEPTION
    	WHEN OTHERS THEN
    	RETURN('');
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

    FUNCTION ARD_IMPR2310 (P_PARAMETER1   IN VARCHAR2 DEFAULT NULL,
                           P_PARAMETER2   IN VARCHAR2 DEFAULT NULL,
                           P_PARAMETER3   IN VARCHAR2 DEFAULT NULL,
                           P_PARAMETER4   IN VARCHAR2 DEFAULT NULL,
                           P_PARAMETER5   IN VARCHAR2 DEFAULT NULL,
                           P_PARAMETER6   IN VARCHAR2 DEFAULT NULL,
                           P_PARAMETER7   IN VARCHAR2 DEFAULT NULL,
                           P_PARAMETER8   IN VARCHAR2 DEFAULT NULL,
                           P_PARAMETER9   IN VARCHAR2 DEFAULT NULL,
                           P_PARAMETER10  IN VARCHAR2 DEFAULT NULL,
                           P_PARAMETER11  IN VARCHAR2 DEFAULT NULL)
        RETURN CLOB
    IS
        retVal                 CLOB;
        v_p_curr_port_cd       NUMBER := TO_NUMBER (P_PARAMETER1);
        v_select1              NUMBER := TO_NUMBER (P_PARAMETER2);
        v_report1              NUMBER := TO_NUMBER (P_PARAMETER3);
        v_p_impr_nbr           NUMBER := TO_NUMBER (P_PARAMETER4);
        v_ltr_nbr              VARCHAR2 (4000) := P_PARAMETER5;
        v_ltr_date             DATE := TO_DATE (P_PARAMETER6, 'YYYY-MM-MI');
        v_supp_srce_cd         NUMBER := TO_NUMBER (P_PARAMETER7);
        v_start_dt             DATE := TO_DATE (P_PARAMETER8, 'YYYY-MM-MI');
        v_end_dt               DATE := TO_DATE (P_PARAMETER9, 'YYYY-MM-MI');
        v_p_module_name        VARCHAR2 (4000) := P_PARAMETER10;
        v_p_report_no          VARCHAR2 (4000) := P_PARAMETER11;
        v_port_name            VARCHAR2 (100);   -- V_PORT_NAME_SEC1
        v_key                  VARCHAR2 (4000);
        v_prev_key             VARCHAR2 (4000);  -- G_SUPP_SRCE_CD اللي فات
        v_rows                 NUMBER := 0;
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
      <p style="text-align:center;margin:2px;"><span style="color:#0e0f50;font-size:12px;">' || APEX_ESCAPE.HTML (CF_TITLEFormula (v_report1)) || '</span></p>
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

        FOR q IN (SELECT IMP.PORT_CD,
                         IMP.IMPR_NBR,
                         IMP.IMPR_TYPE_CD,
                         IMP.BUS_ID,
                         IMP.BUS_ID_TYPE_CD,
                         ' ' || IMP.ARBC_IMPR_NAME ARBC_IMPR_NAME,
                         IMP.BUS_ID_BRNCH,
                         IMP.HQ_IMPR_NBR,
                         IMP.SUPP_SRCE_CD,
                         IMP.SUPP_TITLE_CD,
                         IMP.SUPP_LETR_NO,
                         IMP.SUPP_LETR_DT,
                         IMP.JN_ORACLE_USER
                    FROM JOURNAL.IMPORTERS_JN IMP
                   WHERE     (   (IMP.JN_OPERATION <> 'INS' AND v_report1 = 0)
                              OR (IMP.JN_OPERATION = 'INS' AND v_report1 = 1))
                         AND (IMP.PORT_CD = v_p_curr_port_cd)
                         AND (   (v_select1 = 1 AND IMP.IMPR_NBR = v_p_impr_nbr)
                              OR (    v_select1 = 2
                                  AND (   (    IMP.SUPP_LETR_NO = v_ltr_nbr
                                           AND (   TO_CHAR (IMP.SUPP_LETR_DT, 'RRRR-MM-MI') = TO_CHAR (v_ltr_date, 'RRRR-MM-MI')
                                                OR v_ltr_date IS NULL)
                                           AND (IMP.SUPP_SRCE_CD = v_supp_srce_cd OR v_supp_srce_cd IS NULL)
                                           AND (v_ltr_nbr IS NOT NULL))
                                       OR (    v_ltr_nbr IS NULL
                                           AND v_start_dt IS NOT NULL
                                           AND v_end_dt IS NOT NULL
                                           AND (   (IMP.SUPP_LETR_DT BETWEEN v_start_dt AND v_end_dt)
                                                OR (v_start_dt IS NULL AND v_end_dt IS NULL AND v_ltr_nbr IS NOT NULL))))))
                   ORDER BY IMP.SUPP_SRCE_CD, IMP.SUPP_TITLE_CD, IMP.SUPP_LETR_NO, IMP.JN_ORACLE_USER, IMP.SUPP_LETR_DT)
        LOOP
            v_rows := v_rows + 1;
            IF v_rows = 1 THEN
                -- M_CG$G_IMPORTERS_HDR
                dbms_lob.append (retVal, '
              <table class="data" dir="rtl"><thead><tr>
                <th style="width:10%;">جمرك الخطاب</th><th style="width:8%;">جهة الخطاب</th><th style="width:7%;">رقم الخطاب</th>
                <th style="width:7%;">تاريخ الخطاب</th><th style="width:9%;">اسم المستخدم</th><th style="width:10%;">نوع المستورد</th>
                <th style="width:6%;">الرقم الجمركي</th><th style="width:15%;">اسم المستورد</th><th style="width:10%;">نوع الرقم الإستدلالي</th>
                <th style="width:8%;">الرقم الاستدلالى</th><th style="width:4%;">الفرع</th><th style="width:6%;">الرقم الموحد</th>
              </tr></thead><tbody>');
            END IF;

            -- R_1 (G_SUPP_SRCE_CD): خانات الخطاب في أول سطر
            v_key := q.SUPP_SRCE_CD || '|' || q.SUPP_TITLE_CD || '|' || q.SUPP_LETR_NO || '|' || q.JN_ORACLE_USER || '|'
                     || TO_CHAR (q.SUPP_LETR_DT, 'YYYY-MM-DD HH24:MI:SS');
            IF v_prev_key IS NULL OR v_prev_key <> v_key THEN
                v_prev_key := v_key;
                dbms_lob.append (retVal, '<tr>' || HTML_CELL (CF_SUPP_PORT_NAMEFormula (q.SUPP_SRCE_CD)) || HTML_CELL (CF_DEPTFormula (q.SUPP_TITLE_CD))
                                         || HTML_CELL (q.SUPP_LETR_NO) || HTML_CELL (TO_CHAR (q.SUPP_LETR_DT, 'MI-MM-RRRR'))
                                         || HTML_CELL (CF_USERFormula (q.JN_ORACLE_USER, v_p_curr_port_cd)));
            ELSE
                dbms_lob.append (retVal, '<tr><td></td><td></td><td></td><td></td><td></td>');
            END IF;

            -- R_CG$G_IMPORTERS
            dbms_lob.append (retVal, HTML_CELL (V_NAMEFormula (q.IMPR_TYPE_CD)) || HTML_CELL (q.IMPR_NBR)
                                     || HTML_CELL (q.ARBC_IMPR_NAME, 'text-align:right;') || HTML_CELL (v_name2Formula (q.BUS_ID_TYPE_CD))
                                     || HTML_CELL (q.BUS_ID) || HTML_CELL (q.BUS_ID_BRNCH) || HTML_CELL (q.HQ_IMPR_NBR) || '</tr>');
        END LOOP;

        IF v_rows > 0 THEN
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
    END ARD_IMPR2310;
END IMPR2310_ARD;
/
SHOW ERRORS


CREATE OR REPLACE PUBLIC SYNONYM IMPR2310_ARD FOR LIB_APX_USR.IMPR2310_ARD;


GRANT EXECUTE ON LIB_APX_USR.IMPR2310_ARD TO LIB_USR;

GRANT EXECUTE ON LIB_APX_USR.IMPR2310_ARD TO SECURITY_DEFAULT;

GRANT EXECUTE ON LIB_APX_USR.IMPR2310_ARD TO SECURITY_PROD;

GRANT EXECUTE ON LIB_APX_USR.IMPR2310_ARD TO CUSTOMS;
