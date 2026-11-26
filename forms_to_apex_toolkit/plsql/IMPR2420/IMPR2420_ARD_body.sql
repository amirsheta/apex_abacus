-- =============================================================================
-- Package body: IMPR2420_ARD   (matches IMPR2420_ARD_spec.sql)   Version: 001
-- Layout of IMPR2420.rdf (Landscape, right to left):
--   margin : port name, logo, الرقم / التاريخ / المرفقات, title P_MODULE_NAME, footer report number + dates + page
--   R_G_PORT_CD1 (G_PORT): اسم الجمرك; R_G_TYP1 (G_TYP): نوع الخطـأ; then header row + R_G_IMPR_NBR1 rows:
--   م, رقم المستورد, الرقم الموحد, اسم المستورد, مدينة إصدار السجل, رقم السجل الرئيسي / الفرعي,
--   ت.إنتهاء النشاط, حالة الصلاحية.
-- =============================================================================
SET DEFINE OFF

CREATE OR REPLACE PACKAGE BODY LIB_APX_USR.IMPR2420_ARD
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

    -- CF_PORTFormula بالحرف من الـ RDF
    FUNCTION CF_PORTFormula (P_PORT_CD NUMBER) RETURN VARCHAR2 IS
    XBUF VARCHAR2(5000);
    begin
    	SELECT PORT_NAME INTO XBUF
    	FROM SD_PORTS
    	WHERE PORT_CD = P_PORT_CD;
    	RETURN(XBUF);
    EXCEPTION
    	WHEN OTHERS THEN RETURN(' ');
    end;

    -- CF_TYPFormula بالحرف من الـ RDF
    FUNCTION CF_TYPFormula (P_TYP VARCHAR2) RETURN VARCHAR2 IS
    XBUF VARCHAR2(5000) := ' ';
    begin
    	IF 		P_TYP = 1 THEN XBUF := '1- نوع السجل (رئيسي) ورقم السجل الرئيسي غير مدخل   أو رقم السجل الرئيسي والفرعي مدخلان معا.';
    	ELSIF P_TYP = 2 THEN XBUF := '2- نوع السجل (فرعي) ورقم السجل الفرعي غير مدخل';
    	ELSIF P_TYP = 3 THEN XBUF := '3- نوع السجل (رئيسي) وطول الرقم لا يساوي 10 خانات';
    	ELSIF P_TYP = 4 THEN XBUF := '4- نوع السجل (فرعي) وطول الرقم الرئيسي فقط لا يساوي 10 خانات';
    	ELSIF P_TYP = 5 THEN XBUF := '5- نوع السجل (فرعي ) ورقم السجل الرئيسي والفرعي متساويان';
    	ELSIF P_TYP = 6 THEN XBUF := '6- الأرقام الأربعة الأولى من رقم السجل الرئيسي لا تطابق (رمز مدينة إصدار السجل)';
    	ELSIF P_TYP = 7 THEN XBUF := '7- نوع التسجيل في ملف المستوردين (فرعي) ورقم السجل الرئيسي ملف المستوردين  يقابل السجل الفرعي في ملف وزارة التجارة، ورقم السجل الفرعي في ملف المستوردين  يقابل السجل الرئيسي في ملف وزارة التجارة';
    	END IF;
    	RETURN(XBUF);
    EXCEPTION
    	WHEN OTHERS THEN RETURN(' ');
    end;

    -- CF_TYPEFormula بالحرف من الـ RDF
    FUNCTION CF_TYPEFormula (P_BUS_ID_EXPRD_DT DATE, P_CF_CURR_DT DATE) RETURN VARCHAR2 IS
    XBUF VARCHAR2(500);
    begin
    	IF P_BUS_ID_EXPRD_DT > P_CF_CURR_DT THEN
     -- XBUF := 'غير منتهي الصلاحية';
     		XBUF := ' ';
    		ELSE
    		XBUF := 'منتهي الصلاحية';
    	END IF;
    		RETURN(XBUF);
    EXCEPTION
    		WHEN OTHERS THEN RETURN(' ');
    end;

    -- CF_CITYFormula بالحرف من الـ RDF
    FUNCTION CF_CITYFormula (P_CITY_CODE_OF_ID NUMBER, P_CTRY_CD_OF_ID NUMBER) RETURN VARCHAR2 IS
    XBUF VARCHAR2(5000);
    begin
    	SELECT MINS_COMM_CD INTO XBUF
    	FROM CITIES
    	WHERE  CITY_CD = P_CITY_CODE_OF_ID
    	AND	 CTRY_CD = P_CTRY_CD_OF_ID;
    	IF LTRIM(RTRIM(XBUF)) = '1'	OR LTRIM(RTRIM(XBUF)) <= ' '	OR LTRIM(RTRIM(XBUF)) IS NULL THEN
    		RETURN('غير معروف');
    	ELSE
    		RETURN(XBUF);
    	END IF;
    EXCEPTION
    	WHEN OTHERS THEN RETURN('غير معروف');
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

    FUNCTION ARD_IMPR2420 (P_PARAMETER1   IN VARCHAR2 DEFAULT NULL,
                           P_PARAMETER2   IN VARCHAR2 DEFAULT NULL,
                           P_PARAMETER3   IN VARCHAR2 DEFAULT NULL,
                           P_PARAMETER4   IN VARCHAR2 DEFAULT NULL)
        RETURN CLOB
    IS
        retVal                 CLOB;
        v_p_curr_port_cd       NUMBER := TO_NUMBER (P_PARAMETER1);
        v_p_type               NUMBER := NVL (TO_NUMBER (P_PARAMETER2), 3);   -- initial value 3 في الـ RDF
        v_p_module_name        VARCHAR2 (4000) := P_PARAMETER3;
        v_p_report_no          VARCHAR2 (4000) := P_PARAMETER4;
        v_cf_curr_dt           DATE;             -- CF_CURR_DT
        v_port_name            VARCHAR2 (100);   -- V_PORT_NAME_SEC1
        v_prev_port            NUMBER;           -- G_PORT اللي فات
        v_prev_typ             VARCHAR2 (10);    -- G_TYP اللي فات
        v_count                NUMBER := 0;      -- CS_1
    BEGIN
        DBMS_LOB.createtemporary (retVal, TRUE);

        -- BeforeReport
        IF v_p_curr_port_cd IS NULL THEN v_p_curr_port_cd := 99; END IF;

        v_cf_curr_dt := CF_CURR_DTFormula;
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

        FOR q IN (SELECT '1' TYP, PORT_CD, IMPR_NBR, HQ_IMPR_NBR, BUS_ID, BUS_ID_BRNCH, BUS_ID_EXPRD_DT,
                         CTRY_CD_OF_ID, CITY_CODE_OF_ID, ARBC_IMPR_NAME
                    FROM IMPORTERS
                   WHERE     IMPR_TYPE_CD IN (1, 5, 8)
                         AND BUS_ID_TYPE_CD = 2
                         AND PORT_CD = v_p_curr_port_cd
                         AND (COMM_RGSTRTN_TYPE = 1 AND (BUS_ID IS NULL OR BUS_ID_BRNCH IS NOT NULL))
                         AND (   (v_p_type = 1 AND BUS_ID_EXPRD_DT <= v_cf_curr_dt)
                              OR (v_p_type = 2 AND BUS_ID_EXPRD_DT > v_cf_curr_dt)
                              OR (v_p_type = 3))
                  UNION ALL
                  SELECT '2' TYP, PORT_CD, IMPR_NBR, HQ_IMPR_NBR, BUS_ID, BUS_ID_BRNCH, BUS_ID_EXPRD_DT,
                         CTRY_CD_OF_ID, CITY_CODE_OF_ID, ARBC_IMPR_NAME
                    FROM IMPORTERS
                   WHERE     IMPR_TYPE_CD IN (1, 5, 8)
                         AND BUS_ID_TYPE_CD = 2
                         AND PORT_CD = v_p_curr_port_cd
                         AND (COMM_RGSTRTN_TYPE = 2 AND BUS_ID_BRNCH IS NULL)
                         AND (   (v_p_type = 1 AND BUS_ID_EXPRD_DT <= v_cf_curr_dt)
                              OR (v_p_type = 2 AND BUS_ID_EXPRD_DT > v_cf_curr_dt)
                              OR (v_p_type = 3))
                  UNION ALL
                  SELECT '3' TYP, PORT_CD, IMPR_NBR, HQ_IMPR_NBR, BUS_ID, BUS_ID_BRNCH, BUS_ID_EXPRD_DT,
                         CTRY_CD_OF_ID, CITY_CODE_OF_ID, ARBC_IMPR_NAME
                    FROM IMPORTERS
                   WHERE     IMPR_TYPE_CD IN (1, 5, 8)
                         AND BUS_ID_TYPE_CD = 2
                         AND PORT_CD = v_p_curr_port_cd
                         AND (COMM_RGSTRTN_TYPE = 1 AND LENGTH (LTRIM (RTRIM (BUS_ID))) <> 10)
                         AND (   (v_p_type = 1 AND BUS_ID_EXPRD_DT <= v_cf_curr_dt)
                              OR (v_p_type = 2 AND BUS_ID_EXPRD_DT > v_cf_curr_dt)
                              OR (v_p_type = 3))
                  UNION ALL
                  SELECT '4' TYP, PORT_CD, IMPR_NBR, HQ_IMPR_NBR, BUS_ID, BUS_ID_BRNCH, BUS_ID_EXPRD_DT,
                         CTRY_CD_OF_ID, CITY_CODE_OF_ID, ARBC_IMPR_NAME
                    FROM IMPORTERS
                   WHERE     IMPR_TYPE_CD IN (1, 5, 8)
                         AND BUS_ID_TYPE_CD = 2
                         AND PORT_CD = v_p_curr_port_cd
                         AND COMM_RGSTRTN_TYPE = 2 AND LENGTH (LTRIM (RTRIM (BUS_ID))) <> 10
                         AND (   (v_p_type = 1 AND BUS_ID_EXPRD_DT <= v_cf_curr_dt)
                              OR (v_p_type = 2 AND BUS_ID_EXPRD_DT > v_cf_curr_dt)
                              OR (v_p_type = 3))
                  UNION ALL
                  SELECT '5' TYP, PORT_CD, IMPR_NBR, HQ_IMPR_NBR, BUS_ID, BUS_ID_BRNCH, BUS_ID_EXPRD_DT,
                         CTRY_CD_OF_ID, CITY_CODE_OF_ID, ARBC_IMPR_NAME
                    FROM IMPORTERS
                   WHERE     IMPR_TYPE_CD IN (1, 5, 8)
                         AND BUS_ID_TYPE_CD = 2
                         AND PORT_CD = v_p_curr_port_cd
                         AND (COMM_RGSTRTN_TYPE = 2 AND BUS_ID = BUS_ID_BRNCH)
                         AND (   (v_p_type = 1 AND BUS_ID_EXPRD_DT <= v_cf_curr_dt)
                              OR (v_p_type = 2 AND BUS_ID_EXPRD_DT > v_cf_curr_dt)
                              OR (v_p_type = 3))
                  UNION ALL
                  SELECT '6' TYP, PORT_CD, IMPR_NBR, HQ_IMPR_NBR, BUS_ID, BUS_ID_BRNCH, BUS_ID_EXPRD_DT,
                         CTRY_CD_OF_ID, CITY_CODE_OF_ID, ARBC_IMPR_NAME
                    FROM IMPORTERS
                   WHERE     IMPR_TYPE_CD IN (1, 5, 8)
                         AND BUS_ID_TYPE_CD = 2
                         AND PORT_CD = v_p_curr_port_cd
                         AND NOT EXISTS (SELECT '1' FROM CITIES WHERE CITIES.CTRY_CD = IMPORTERS.CTRY_CD_OF_ID
                                                    AND CITIES.CITY_CD = IMPORTERS.CITY_CODE_OF_ID
                                                    AND SUBSTR (CITIES.MINS_COMM_CD, 1) = SUBSTR (BUS_ID, 1, 4))
                         AND (   (v_p_type = 1 AND BUS_ID_EXPRD_DT <= v_cf_curr_dt)
                              OR (v_p_type = 2 AND BUS_ID_EXPRD_DT > v_cf_curr_dt)
                              OR (v_p_type = 3))
                  UNION ALL
                  SELECT '7' TYP, PORT_CD, IMPR_NBR, HQ_IMPR_NBR, BUS_ID, BUS_ID_BRNCH, BUS_ID_EXPRD_DT,
                         CTRY_CD_OF_ID, CITY_CODE_OF_ID, ARBC_IMPR_NAME
                    FROM IMPORTERS
                   WHERE     IMPR_TYPE_CD IN (1, 5, 8)
                         AND BUS_ID_TYPE_CD = 2
                         AND PORT_CD = v_p_curr_port_cd
                         AND (TO_CHAR (BUS_ID)) IN (SELECT TO_CHAR (BUS_ID_BRNCH) FROM COMM_IMPR_RGSTR) AND COMM_RGSTRTN_TYPE = 1
                         AND (   (v_p_type = 1 AND BUS_ID_EXPRD_DT > v_cf_curr_dt)
                              OR (v_p_type = 2 AND BUS_ID_EXPRD_DT <= v_cf_curr_dt)
                              OR (v_p_type = 3))
                  ORDER BY 2, 1, 3)
        LOOP
            IF v_prev_typ IS NOT NULL AND (v_prev_port <> q.PORT_CD OR v_prev_typ <> q.TYP) THEN
                dbms_lob.append (retVal, '</tbody></table>');
            END IF;

            -- R_G_PORT_CD1 (G_PORT)
            IF v_prev_port IS NULL OR v_prev_port <> q.PORT_CD THEN
                v_prev_port := q.PORT_CD;
                v_prev_typ := NULL;
                dbms_lob.append (retVal, '<table class="grp" dir="rtl"><tbody><tr><td>'
                                         || LABEL_VALUE ('اسم الجمرك:', CF_PORTFormula (q.PORT_CD)) || '</td></tr></tbody></table>');
            END IF;

            -- R_G_TYP1 (G_TYP) + M_G_IMPR_NBR_HDR1
            IF v_prev_typ IS NULL OR v_prev_typ <> q.TYP THEN
                v_prev_typ := q.TYP;
                v_count := 0;
                dbms_lob.append (retVal, '<table class="grp" dir="rtl"><tbody><tr><td>'
                                         || LABEL_VALUE ('نوع الخطـأ:', CF_TYPFormula (q.TYP)) || '</td></tr></tbody></table>
              <table class="data" dir="rtl"><thead><tr>
                <th style="width:4%;">م</th><th style="width:7%;">رقم المستورد</th><th style="width:7%;">الرقم الموحد</th>
                <th style="width:31%;">اسم المستورد</th><th style="width:10%;">مدينة إصدار السجل</th><th style="width:11%;">رقم السجل الرئيسي</th>
                <th style="width:9%;">رقم السجل الفرعي</th><th style="width:8%;">ت.إنتهاء النشاط</th><th style="width:9%;">حالة الصلاحية</th>
              </tr></thead><tbody>');
            END IF;

            -- R_G_IMPR_NBR1 (G_IMPR)
            v_count := v_count + 1;
            dbms_lob.append (retVal, '<tr>' || HTML_CELL (v_count) || HTML_CELL (q.IMPR_NBR) || HTML_CELL (q.HQ_IMPR_NBR)
                                     || HTML_CELL (q.ARBC_IMPR_NAME, 'text-align:right;')
                                     || HTML_CELL (CF_CITYFormula (q.CITY_CODE_OF_ID, q.CTRY_CD_OF_ID)) || HTML_CELL (q.BUS_ID)
                                     || HTML_CELL (q.BUS_ID_BRNCH) || HTML_CELL (TO_CHAR (q.BUS_ID_EXPRD_DT, 'MI-MM-YYYY'))
                                     || HTML_CELL (CF_TYPEFormula (q.BUS_ID_EXPRD_DT, v_cf_curr_dt)) || '</tr>');
        END LOOP;

        IF v_prev_typ IS NOT NULL THEN
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
    END ARD_IMPR2420;
END IMPR2420_ARD;
/
SHOW ERRORS


CREATE OR REPLACE PUBLIC SYNONYM IMPR2420_ARD FOR LIB_APX_USR.IMPR2420_ARD;


GRANT EXECUTE ON LIB_APX_USR.IMPR2420_ARD TO LIB_USR;

GRANT EXECUTE ON LIB_APX_USR.IMPR2420_ARD TO SECURITY_DEFAULT;

GRANT EXECUTE ON LIB_APX_USR.IMPR2420_ARD TO SECURITY_PROD;

GRANT EXECUTE ON LIB_APX_USR.IMPR2420_ARD TO CUSTOMS;
