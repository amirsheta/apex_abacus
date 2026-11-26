CREATE OR REPLACE PACKAGE BODY LIB_APX_USR.DCLN3300_ARD
AS
    -- معاملات التقرير اللي الـ formulas بتقراها (بتتملى أول ARD)
    g_p_select               VARCHAR2 (4000);
    g_start_dt               DATE;
    g_end_dt                 DATE;
    g_p_impr_nbr             VARCHAR2 (4000);
    g_p_curr_port_cd         NUMBER;

    FUNCTION PKG_VERSION RETURN VARCHAR2 IS
    BEGIN
        RETURN (V_PKG_VERSION);
    END PKG_VERSION;
    -- CF_RSNSFormula بالحرف من الـ RDF
    FUNCTION CF_RSNSFormula (P_REPRINT_RSN VARCHAR2) RETURN VARCHAR2 IS
    	BUF	VARCHAR2(4500) := P_REPRINT_RSN;
    	DE  VARCHAR2(10) := CHR(13) || CHR(10);
    	D_LEN NUMBER := LENGTH(DE);
    	POS	NUMBER;
    	TOKEN VARCHAR2(200);
    	RET VARCHAR2(4500);
    		RET1 VARCHAR2(4500);
    	I NUMBER;
    	TOKEN_CNT  NUMBER := 0;
    begin
    	LOOP
    		POS := INSTR(BUF, DE);
    		TOKEN_CNT := TOKEN_CNT + 1;
    		IF POS = 0 THEN
    			EXIT;
    		ELSE
    			BUF := SUBSTR(BUF, POS + D_LEN);
    		END IF;
    	END LOOP;

    	I := TOKEN_CNT + 1;
    	BUF	:= P_REPRINT_RSN;

    	LOOP
    		POS := INSTR(BUF, DE);
    		IF POS = 0 THEN
    			TOKEN := BUF;
    		RET := RET ||I || '  -     ' || TOKEN || DE;

    				ret1:= ' '||I || '  -     '||token||de||
    	'------------------------------------------------------------------------'||DE||ret1;
    			EXIT;
    		ELSE
    			TOKEN := SUBSTR(BUF, 1, POS - 1);
    			BUF := SUBSTR(BUF, POS + D_LEN);
    		RET := RET ||I || '  -    ' || TOKEN || DE;
       	ret1:= ' '||I || '  -     '||token||de||
     	'------------------------------------------------------------------------'||DE||ret1;
    			I := I - 1;
    		END IF;
    	END LOOP;
    	RETURN(RET1);
    end;

    -- LICENSE_TYPE_MEANFormula بالحرف من الـ RDF
    FUNCTION LICENSE_TYPE_MEANFormula (P_LIC_TYPE NUMBER) RETURN VARCHAR2 IS
    CH VARCHAR2(50);
    begin
      SELECT RV_MEANING INTO CH FROM CG_REF_CODES WHERE RV_DOMAIN='LICENSE TYPE' AND
      RV_LOW_VALUE=P_LIC_TYPE;
      RETURN(CH);

    EXCEPTION
    	WHEN OTHERS THEN
    	RETURN(NULL);
    end;

    -- CF_TITLEFormula بالحرف من الـ RDF
    FUNCTION CF_TITLEFormula RETURN VARCHAR2 IS
    V_TITLE VARCHAR2(150);
    CH VARCHAR2(70);
    begin
       IF g_p_select =1 THEN
        	V_TITLE:='لبيان محدد';
       ELSIF g_p_select =2 THEN
         	V_TITLE:='خلال الفترة من : '||TO_CHAR(g_start_dt,'RRRR-MM-MI')||'إلى: '||TO_CHAR(g_end_dt,'RRRR-MM-MI');
       ELSE
       	  IF g_p_impr_nbr IS NOT NULL THEN
      	    SELECT ARBC_IMPR_NAME INTO CH FROM IMPORTERS WHERE
      	    PORT_CD=g_p_curr_port_cd AND 
      	    IMPR_NBR=g_p_impr_nbr; 
      	  END IF; 	
         	V_TITLE:='للمستورد : '||CH;
      END IF;
      RETURN(V_TITLE);

    EXCEPTION
     	WHEN NO_DATA_FOUND THEN
     	RETURN(NULL);
    end;

    -- CF_port_nameFormula بالحرف من الـ RDF
    FUNCTION CF_port_nameFormula RETURN VARCHAR2 IS
    CH VARCHAR2(100);
    begin
      SELECT PORT_NAME INTO CH FROM SD_PORTS WHERE PORT_CD=g_p_curr_port_cd;
      RETURN(CH);
    EXCEPTION 
    	WHEN NO_DATA_FOUND THEN
     RETURN(NULL);
    end;

    FUNCTION ARD_DCLN3300 (P_PARAMETER1   IN VARCHAR2 DEFAULT NULL,
                           P_PARAMETER2   IN VARCHAR2 DEFAULT NULL,
                           P_PARAMETER3   IN VARCHAR2 DEFAULT NULL,
                           P_PARAMETER4   IN VARCHAR2 DEFAULT NULL,
                           P_PARAMETER5   IN VARCHAR2 DEFAULT NULL,
                           P_PARAMETER6   IN VARCHAR2 DEFAULT NULL,
                           P_PARAMETER7   IN VARCHAR2 DEFAULT NULL,
                           P_PARAMETER8   IN VARCHAR2 DEFAULT NULL,
                           P_PARAMETER9   IN VARCHAR2 DEFAULT NULL)
        RETURN CLOB
    IS
        retVal                 CLOB;
        v_p_curr_port_cd       NUMBER := TO_NUMBER (P_PARAMETER1);
        v_p_module_name        VARCHAR2 (4000) := P_PARAMETER2;
        v_p_report_no          VARCHAR2 (4000) := P_PARAMETER3;
        v_p_dcltn_isn          NUMBER := TO_NUMBER (P_PARAMETER4);
        v_p_impr_nbr           VARCHAR2 (4000) := P_PARAMETER5;
        v_start_dt             DATE := TO_DATE (P_PARAMETER6, 'YYYY-MM-MI');
        v_end_dt               DATE := TO_DATE (P_PARAMETER7, 'YYYY-MM-MI');
        v_p_select             VARCHAR2 (4000) := P_PARAMETER8;
        v_p_dcltn_type         VARCHAR2 (4000) := P_PARAMETER9;
        v_port_name            VARCHAR2 (100);   -- CF_port_name
        v_title                VARCHAR2 (500);   -- CF_TITLE
        f_lic                  VARCHAR2 (4000);  -- LICENSE_TYPE_MEAN
        f_rsns                 VARCHAR2 (4000);  -- CF_RSNS
        v_prev_key             VARCHAR2 (4000);  -- G_DCLTN_NBR اللي فات (break)
        v_prev_rsn             VARCHAR2 (4000);  -- G_REPRINT_RSN اللي فات (break)
    BEGIN
        DBMS_LOB.createtemporary (retVal, TRUE);

        -- معاملات التقرير اللي الـ formulas بتقراها
        g_p_select := v_p_select;
        g_start_dt := v_start_dt;
        g_end_dt := v_end_dt;
        g_p_impr_nbr := v_p_impr_nbr;
        g_p_curr_port_cd := v_p_curr_port_cd;

        v_port_name := CF_port_nameFormula;
        v_title := CF_TITLEFormula;

        dbms_lob.append (retVal, '<head><style>
.MRD-Header{ display:none; }
.MRDFooter{ position: fixed; bottom: 0px; width: 100%; }
th{ text-align:center; }
.MRD-Body tr{ -fs-page-break-min-height:5mm; }
.ARDHeader{ width:100%; }
body, table, td, p { font-family: Somar; }
.data td{ border:1px solid #a5a5a5; padding:3px 6px; text-align:center; font-size:11px; color:#707070; }
.data th{ border:1px solid #a5a5a5; padding:4px 6px; font-size:11px; color:#ffffff; background:#0e0f50; }
.data .tot td{ color:#0e0f50; font-weight:bold; }
.data .grp td{ color:#0e0f50; font-weight:bold; background:#eef3fb; text-align:right; }
.lbl{ color:#0e0f50; font-size:11px; }
.val{ color:#707070; font-size:11px; }
@page {
   background: white;
   margin-top: 20px;
   margin-bottom: 40px;
   margin-left: 70px;
   margin-right: 70px;
   size: A4 portrait;
   @bottom-center { content: "صفحة " counter(page) " من " counter(pages); direction: rtl; font-family: Somar; font-size: 10px; color: #0e0f50; }
}
</style></head>');

        -- الهيدر بيتكرر في كل صفحة: اللوجو في النص، والعناوين اللي في هامش الـ RDF
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
            <td style="width:25%;"></td>
            <td style="width:50%;text-align:center;">');
        dbms_lob.append (retVal, ARD_LOGO.IMG (85, 335, NULL, 'LOGO1.jpg'));   -- اللوجو Static File في الأبلكيشن (DEC-034)، في نص الصفحة
        dbms_lob.append (retVal, '</td>
            <td style="width:25%;"></td>
          </tr>
        </tbody>
      </table>
      <p style="text-align:center;margin:2px;"><span style="color:#0e0f50;font-size:14px;font-weight:bold;">' || APEX_ESCAPE.HTML (v_port_name) || '</span></p>
      <p style="text-align:center;margin:2px;"><span style="color:#0e0f50;font-size:14px;font-weight:bold;">' || APEX_ESCAPE.HTML (v_p_module_name) || '</span></p>
      <p style="text-align:center;margin:2px;"><span style="color:#0e0f50;font-size:12px;font-weight:bold;">' || APEX_ESCAPE.HTML (v_title) || '</span></p>
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

        FOR q IN (SELECT * FROM (
                          SELECT
                          L_DCLTNT.TYPE_ID L_DCLTNT_TYPE_ID,
                          DCLTN.PORT_CD PORT_CD,
                          DCLTN.DCLTN_ISN DCLTN_ISN,
                          DCLTN.DCLTN_TYPE_CD DCLTN_TYPE_CD,
                          ' '||L_DCLTNT.TYPE_NAME DCLTN_TYPE_NAME,
                          DCLTN.DCLTN_NBR DCLTN_NBR,
                          DCLTN.DCLTN_DT DCLTN_DT,
                          DCLTN.IMPR_NBR IMPR_NBR2,
                          ' '||IMP.ARBC_IMPR_NAME ARBC_IMPR_NAME,
                          DCLTN.LIC_TYPE LIC_TYPE2,
                          DCLTN.LIC_NBR LIC_NBR2,
                          BKM.BRKR_NAME BRKR_NAME,
                          DCLTN.PRINT_CNT PRINT_CNT,
                          DCLTN.BRKR_PORT_CD BRKR_PORT_CD,
                          IMP.PORT_CD IMP_PORT_CD,
                          BKM.PORT_CD BKM_PORT_CD,
                          DCLTN.REPRINT_RSN REPRINT_RSN,
                          IMP.IMPR_NBR IMPR_NBR,
                          BKM.LIC_TYPE LIC_TYPE,
                          BKM.LIC_NBR LIC_NBR
                          FROM
                          BRKR_MSTR BKM,
                          DCLTN_TYPES L_DCLTNT,
                          IMPORTERS IMP,
                          DECLARATIONS DCLTN
                          WHERE
                          DCLTN.PORT_CD = IMP.PORT_CD (+) AND
                          DCLTN.IMPR_NBR = IMP.IMPR_NBR (+) AND
                          DCLTN.DCLTN_TYPE_CD = L_DCLTNT.TYPE_ID AND
                          DCLTN.BRKR_PORT_CD = BKM.PORT_CD (+) AND
                          DCLTN.LIC_TYPE = BKM.LIC_TYPE (+) AND
                          DCLTN.LIC_NBR = BKM.LIC_NBR (+)
                          and PRINT_CNT > 1
                          AND REPRINT_RSN IS NOT NULL
                          AND DCLTN.PORT_CD=v_p_curr_port_cd
                          AND
                          (
                          (
                          (DCLTN.DCLTN_TYPE_CD =v_p_dcltn_type AND v_p_dcltn_type in(1,2)) AND((DCLTN.IMPR_NBR=v_p_impr_nbr AND v_p_select=3) OR( v_p_select <>3) )
                          )
                             OR
                          (
                          (DCLTN.DCLTN_TYPE_CD  =v_p_dcltn_type AND(v_p_dcltn_type in(3,4,5,6)))AND((DCLTN.AGENT_NBR = v_p_impr_nbr AND v_p_select =3) OR  (v_p_select<>3))
                          )
                             OR
                          (
                           (
                               (
                          DCLTN.DCLTN_TYPE_CD IN (1,2) AND  ((DCLTN.IMPR_NBR = v_p_impr_nbr  AND v_p_select=3)  )
                                )
                          OR
                                (
                          DCLTN.DCLTN_TYPE_CD IN (3,4,5,6) AND (( DCLTN.AGENT_NBR=v_p_impr_nbr AND v_p_select=3)  )
                                 )
                          OR( v_p_select<>3)
                           )
                          AND v_p_dcltn_type IS NULL
                          )
                          )
                          AND
                          (
                          (DCLTN.DCLTN_ISN=v_p_dcltn_isn  AND v_p_select =1)
                          OR
                          (TO_CHAR(DCLTN.DCLTN_DT,'RRRR-MM-MI')>=TO_CHAR(v_start_dt,'RRRR-MM-MI') AND
                           TO_CHAR(DCLTN.DCLTN_DT,'RRRR-MM-MI')<=TO_CHAR(v_end_dt,'RRRR-MM-MI') AND v_p_select =2)
                          OR
                          ( v_p_select =3)
                          )
                         )
                   ORDER BY DCLTN_NBR, DCLTN_DT, PRINT_CNT, L_DCLTNT_TYPE_ID, PORT_CD, DCLTN_ISN)
        LOOP
            -- G_DCLTN_NBR (أول صف للبيان): الإطار M_1
            IF v_prev_key IS NULL OR v_prev_key <> q.PORT_CD || '|' || q.DCLTN_ISN THEN
                IF v_prev_key IS NOT NULL THEN
                    dbms_lob.append (retVal, '</tbody></table>');
                END IF;

                v_prev_key := q.PORT_CD || '|' || q.DCLTN_ISN;
                f_lic := LICENSE_TYPE_MEANFormula (q.LIC_TYPE);
                dbms_lob.append (retVal, '
              <table class="data" dir="rtl" style="border-collapse:collapse;width:100%;margin:12px 0 4px 0;table-layout:fixed;"><tbody>
                <tr class="grp"><td colspan="3" style="text-align:center;">الــبــيـــان</td></tr>
                <tr><th>نوعه</th><th>رقمه</th><th>تاريخه</th></tr>
                <tr><td>' || APEX_ESCAPE.HTML (q.DCLTN_TYPE_NAME) || '</td><td>' || APEX_ESCAPE.HTML (q.DCLTN_NBR) || '</td>
                    <td>' || TO_CHAR (q.DCLTN_DT, 'MI-MM-RRRR') || ' هـ</td></tr>
                <tr class="grp"><td colspan="3" style="text-align:center;">الــمـــســتـــورد</td></tr>
                <tr><th>رقمه</th><th colspan="2">اســمــه</th></tr>
                <tr><td>' || APEX_ESCAPE.HTML (q.IMPR_NBR2) || '</td><td colspan="2">' || APEX_ESCAPE.HTML (q.ARBC_IMPR_NAME) || '</td></tr>
                <tr class="grp"><td colspan="3" style="text-align:center;">الــمــخـــلــص</td></tr>
                <tr><th>نوع الرخصة</th><th>رقم الرخصة</th><th>اســمــه</th></tr>
                <tr><td>' || APEX_ESCAPE.HTML (f_lic) || '</td><td>' || APEX_ESCAPE.HTML (q.LIC_NBR) || '</td><td>' || APEX_ESCAPE.HTML (q.BRKR_NAME) || '</td></tr>
                <tr class="tot"><td colspan="3">عدد مرات الطباعة : ' || APEX_ESCAPE.HTML (q.PRINT_CNT) || ' مرة</td></tr>
              </tbody></table>
              <table class="data" dir="rtl" style="border-collapse:collapse;width:100%;table-layout:fixed;"><thead>
                <tr><th>أسباب إعادة الطباعة</th></tr></thead><tbody>');
                v_prev_rsn := '#';
            END IF;

            -- G_REPRINT_RSN (break على REPRINT_RSN جوه البيان): CF_RSNS، والسطور الجديدة <br>
            IF NVL (q.REPRINT_RSN, '#') <> v_prev_rsn THEN
                v_prev_rsn := NVL (q.REPRINT_RSN, '#');
                f_rsns := CF_RSNSFormula (q.REPRINT_RSN);
                dbms_lob.append (retVal, '<tr><td style="text-align:right;">'
                                         || REPLACE (APEX_ESCAPE.HTML (RTRIM (f_rsns, CHR (13) || CHR (10))), CHR (13) || CHR (10), '<br>') || '</td></tr>');
            END IF;
        END LOOP;

        IF v_prev_key IS NOT NULL THEN
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
    END ARD_DCLN3300;
END DCLN3300_ARD;
/


CREATE OR REPLACE PUBLIC SYNONYM DCLN3300_ARD FOR LIB_APX_USR.DCLN3300_ARD;


GRANT EXECUTE ON LIB_APX_USR.DCLN3300_ARD TO LIB_USR;

GRANT EXECUTE ON LIB_APX_USR.DCLN3300_ARD TO LIB_USR_FAS;

GRANT EXECUTE ON LIB_APX_USR.DCLN3300_ARD TO SECURITY_DEFAULT;

GRANT EXECUTE ON LIB_APX_USR.DCLN3300_ARD TO SECURITY_PROD;
