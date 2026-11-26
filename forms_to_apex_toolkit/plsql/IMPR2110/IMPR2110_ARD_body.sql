-- =============================================================================
-- Package body: IMPR2110_ARD   (matches IMPR2110_ARD_spec.sql)   Version: 001
-- Layout of IMPR2110.rdf (Landscape, right to left):
--   margin    : port name (V_PORT_NAME_SEC1), logo, الرقم / التاريخ / المرفقات, title P_MODULE_NAME,
--               footer report number + Hijri / Gregorian date + "page x of y"
--   R_1       : one frame per importer (group G_IMPR_NBR): مسلسل, نوع المستورد (V_NAME), نوع الاقامة (CF_impr_id_type)
--   R_CG$G_IMPORTERS : header row + rows: نوع الرقم الإستدلالي, الرقم الاستدلالى, الفرع, اسم المستورد, المدينة,
--               الرمز البريدى, صندوق البريد, رقم تليفون المستورد
--   M_CG$G_IMPORTERS_GRPFR is printed only when there are rows (CG$SuppressFrame(CS_CG$G_IMPORTERS) = count > 0).
--   The old letterhead lines (المملكة العربية السعودية / وزارة المالية / مصلحة الجمارك, image B_1_SEC1_SEC1) are
--   the logo of ARD_LOGO, as in the other ARD reports.
-- =============================================================================
SET DEFINE OFF

CREATE OR REPLACE PACKAGE BODY LIB_APX_USR.IMPR2110_ARD
AS
    c_list_pattern   CONSTANT VARCHAR2 (60) := '^[0-9]+(,[0-9]+)*$';

    FUNCTION PKG_VERSION RETURN VARCHAR2 IS
    BEGIN
        RETURN (V_PKG_VERSION);
    END PKG_VERSION;

    -- V_NAMEFormula بالحرف من الـ RDF
    FUNCTION V_NAMEFormula (P_IMPR_TYPE_CD NUMBER) RETURN VARCHAR2 IS
    V_NAME VARCHAR2(100);
    begin
       SELECT IMPR_TYPE_NAME
      INTO   V_NAME
      FROM   IMPR_TYPES
      WHERE  IMPR_TYPE_CD  = P_IMPR_TYPE_CD ;

      RETURN (V_NAME);
    end;

    -- CF_impr_id_typeFormula بالحرف من الـ RDF
    FUNCTION CF_impr_id_typeFormula (P_IMPR_NBR NUMBER) RETURN VARCHAR2 IS
    V_EXPIRY_DATE DATE;
    V_DUMMY NUMBER(1);
    begin
      SELECT MAX(EXPIRY_DATE)
      INTO   V_EXPIRY_DATE
    	FROM   PRIVILEGED_IMPORTERS
    	WHERE  IMPR_PRIVILEGE_TYPE = 3
    	AND    REC_STATUS = 1
    	AND    IMPR_NBR = P_IMPR_NBR;

    	IF V_EXPIRY_DATE IS NOT NULL THEN
    		IF V_EXPIRY_DATE < hijdate_db.cur_hij_date THEN
    			RETURN 'اقامة عادية';
    		ELSE
    			RETURN 'اقامة مميزة محددة المدة تنتهي بتاريخ '||TO_CHAR(V_EXPIRY_DATE,'MI-MM-YYYY');
    		END IF;
    	ELSE
    	  BEGIN
          SELECT 1
    	    INTO   V_DUMMY
    	    FROM   PRIVILEGED_IMPORTERS
    	    WHERE  IMPR_PRIVILEGE_TYPE = 3
          AND    REC_STATUS = 1
    	    AND    IMPR_NBR = P_IMPR_NBR
    	    AND    ROWNUM  =  1;
    		RETURN 'اقامة مميزة دائمة ';
    	  EXCEPTION
    	  	WHEN NO_DATA_FOUND THEN
    	  	 	RETURN  'عادية';
    	  END;

    	END IF;
    END;

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

    FUNCTION ARD_IMPR2110 (P_PARAMETER1   IN VARCHAR2 DEFAULT NULL,
                           P_PARAMETER2   IN VARCHAR2 DEFAULT NULL,
                           P_PARAMETER3   IN VARCHAR2 DEFAULT NULL,
                           P_PARAMETER4   IN VARCHAR2 DEFAULT NULL)
        RETURN CLOB
    IS
        retVal                 CLOB;
        v_p_curr_port_cd       NUMBER := TO_NUMBER (P_PARAMETER1);
        v_impr_list            VARCHAR2 (4000) := RTRIM (REGEXP_REPLACE (P_PARAMETER2, '\s', ''), ',');
        v_p_module_name        VARCHAR2 (4000) := P_PARAMETER3;
        v_p_report_no          VARCHAR2 (4000) := P_PARAMETER4;
        v_port_name            VARCHAR2 (100);   -- V_PORT_NAME_SEC1
        v_prev_key             VARCHAR2 (4000);  -- G_IMPR_NBR اللي فات (break)
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

        -- القايمة لازم تكون أرقام مفصولة بفاصلة (الشاشة بتتأكد قبل ما تبعت)، وإلا التقرير من غير سجلات
        IF v_impr_list IS NULL OR REGEXP_LIKE (v_impr_list, c_list_pattern) THEN
            FOR q IN (SELECT HI.BUS_ID           BUS_ID2,
                             IMP.PORT_CD         PORT_CD,
                             IMP.IMPR_NBR        IMPR_NBR,
                             IMP.IMPR_TYPE_CD,
                             HI.BUS_ID_BRNCH     BUS_ID_BRNCH2,
                             IMP.BUS_ID          BUS_ID,
                             IMP.CITY_CODE,
                             IMP.BUS_ID_TYPE_CD,
                             IMP.ARBC_IMPR_NAME  ARBC_IMPR_NAME,
                             IMP.IMPR_TEL_NBR    IMPR_TEL_NBR,
                             IMP.IMPR_POB_NBR    IMPR_POB_NBR,
                             IMP.IMPR_ZIP_CD     IMPR_ZIP_CD,
                             IMP.IMPR_FAX_NBR    IMPR_FAX_NBR,
                             IMP.IMPR_TELEX_NBR  IMPR_TELEX_NBR,
                             IMP.ENG_IMPR_NAME   ENG_IMPR_NAME,
                             IMP.IMPR_CNTCT_NAME IMPR_CNTCT_NAME,
                             IMP.BUS_ID_BRNCH    BUS_ID_BRNCH,
                             IMP.EMAIL           EMAIL,
                             IMPR2110_ARD.V_NAMEFormula (IMP.IMPR_TYPE_CD)        V_NAME,
                             IMPR2110_ARD.CF_impr_id_typeFormula (IMP.IMPR_NBR)   CF_IMPR_ID_TYPE,
                             IMPR2110_ARD.v_name2Formula (IMP.BUS_ID_TYPE_CD)     V_NAME2,
                             IMPR2110_ARD.C_CODEFormula (IMP.CITY_CODE)           C_CODE
                        FROM HQ_IMPRS HI, IMPORTERS IMP
                       WHERE     IMP.PORT_CD = v_p_curr_port_cd
                             AND IMP.HQ_IMPR_NBR = HI.HQ_IMPR_NBR(+)
                             -- :parameter.TRAN_SELECT of the form (RDF: AND IMP.HQ_IMPR_NBR = :P_IMPR_NBR, see the spec)
                             AND IMP.IMPR_NBR IS NOT NULL
                             AND (   v_impr_list IS NULL
                                  OR IMP.IMPR_NBR IN (SELECT TO_NUMBER (REGEXP_SUBSTR (v_impr_list, '[^,]+', 1, LEVEL))
                                                        FROM DUAL
                                                     CONNECT BY REGEXP_SUBSTR (v_impr_list, '[^,]+', 1, LEVEL) IS NOT NULL))
                       ORDER BY IMP.IMPR_NBR)
            LOOP
                -- G_IMPR_NBR (أول صف للمستورد): الإطار R_1 وهيدر جدول R_CG$G_IMPORTERS
                IF v_prev_key IS NULL OR v_prev_key <> TO_CHAR (q.IMPR_NBR) THEN
                    IF v_prev_key IS NOT NULL THEN
                        dbms_lob.append (retVal, '</tbody></table>');
                    END IF;
                    v_prev_key := TO_CHAR (q.IMPR_NBR);
                    dbms_lob.append (retVal, '
              <table class="grp" dir="rtl"><tbody><tr>
                <td style="width:15%;"><span class="lbl">مسلسل  : </span><span class="val">' || APEX_ESCAPE.HTML (q.IMPR_NBR) || '</span></td>
                <td style="width:35%;"><span class="lbl">نوع المستورد : </span><span class="val">' || APEX_ESCAPE.HTML (q.V_NAME) || '</span></td>
                <td style="width:50%;"><span class="lbl">نوع الاقامة : </span><span class="val">' || APEX_ESCAPE.HTML (q.CF_IMPR_ID_TYPE) || '</span></td>
              </tr></tbody></table>
              <table class="data" dir="rtl"><thead><tr>
                <th style="width:15%;">نوع الرقم الإستدلالي</th><th style="width:11%;">الرقم الاستدلالى</th><th style="width:6%;">الفرع</th>
                <th style="width:24%;">اسم المستورد</th><th style="width:12%;">المدينة</th><th style="width:8%;">الرمز البريدى</th>
                <th style="width:8%;">صندوق البريد</th><th style="width:16%;">رقم تليفون المستورد</th>
              </tr></thead><tbody>');
                END IF;

                -- R_CG$G_IMPORTERS
                dbms_lob.append (retVal, '<tr><td>' || APEX_ESCAPE.HTML (q.V_NAME2) || '</td><td>' || APEX_ESCAPE.HTML (q.BUS_ID)
                                         || '</td><td>' || APEX_ESCAPE.HTML (q.BUS_ID_BRNCH) || '</td><td style="text-align:right;">'
                                         || APEX_ESCAPE.HTML (q.ARBC_IMPR_NAME) || '</td><td>' || APEX_ESCAPE.HTML (q.C_CODE)
                                         || '</td><td>' || APEX_ESCAPE.HTML (q.IMPR_ZIP_CD) || '</td><td>' || APEX_ESCAPE.HTML (q.IMPR_POB_NBR)
                                         || '</td><td style="direction:ltr;">' || APEX_ESCAPE.HTML (q.IMPR_TEL_NBR) || '</td></tr>');
            END LOOP;
        END IF;

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
    END ARD_IMPR2110;
END IMPR2110_ARD;
/
SHOW ERRORS


CREATE OR REPLACE PUBLIC SYNONYM IMPR2110_ARD FOR LIB_APX_USR.IMPR2110_ARD;


GRANT EXECUTE ON LIB_APX_USR.IMPR2110_ARD TO LIB_USR;

GRANT EXECUTE ON LIB_APX_USR.IMPR2110_ARD TO SECURITY_DEFAULT;

GRANT EXECUTE ON LIB_APX_USR.IMPR2110_ARD TO SECURITY_PROD;
