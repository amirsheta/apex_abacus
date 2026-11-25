-- =============================================================================
-- Package body: IMPR2410_ARD   (matches IMPR2410_ARD.pks)   Version: 001
-- Layout of IMPR2410.rdf (Portrait, left to right layout of Arabic text; here dir rtl with the same
-- positions mirrored):
--   margin : letterhead (logo) and port name right, التاريخ / الموافق / الرقم left, title P_MODULE_NAME,
--            header row (اسم الجمرك, اسم المستورد, تاريخ انتهاء صلاحية النشاط) on every page; footer
--            رقم التقرير + التاريخ (Hijri YYYY-MM-MI / Gregorian YYYY-MM-DD) + page
--   R_1 (G_PORT_CD): اسم الجمرك on the first line of the port, next to R_CG$G_DCLTN rows.
-- =============================================================================
SET DEFINE OFF

CREATE OR REPLACE PACKAGE BODY LIB_APX_USR.IMPR2410_ARD
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

    FUNCTION ARD_IMPR2410 (P_PARAMETER1   IN VARCHAR2 DEFAULT NULL,
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
        v_p_port_cd            NUMBER := TO_NUMBER (P_PARAMETER2);
        v_p_clnt_id            VARCHAR2 (4000) := P_PARAMETER3;
        v_p_bus_id             VARCHAR2 (4000) := P_PARAMETER4;
        v_p_bus_id_brnch       VARCHAR2 (4000) := P_PARAMETER5;
        v_p_module_name        VARCHAR2 (4000) := P_PARAMETER6;
        v_p_report_no          VARCHAR2 (4000) := P_PARAMETER7;
        v_port_name            VARCHAR2 (100);   -- V_PORT_NAME_SEC1
        v_key                  VARCHAR2 (4000);
        v_prev_key             VARCHAR2 (4000);  -- G_PORT_CD اللي فات
    BEGIN
        DBMS_LOB.createtemporary (retVal, TRUE);

        -- AfterPForm
        IF (v_p_bus_id IS NOT NULL OR v_p_bus_id_brnch IS NOT NULL) THEN
            v_p_clnt_id := NULL;
        END IF;

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
   size: A4 portrait;
   @bottom-center { content: "صفحة " counter(page) " من " counter(pages); direction: rtl; font-family: Somar; font-size: 10px; color: #0e0f50; }
}
</style></head>');

        -- الهيدر في كل صفحة: اللوجو واسم الجمرك يمين، التاريخ / الموافق / الرقم شمال، العنوان وهيدر الجدول
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
            <td style="width:40%;text-align:center;">');
        dbms_lob.append (retVal, ARD_LOGO.IMG (85, 335, NULL, 'LOGO1.jpg'));   -- اللوجو Static File في الأبلكيشن (DEC-034)
        dbms_lob.append (retVal, '
              <p style="margin:2px;"><span style="color:#0e0f50;font-size:12px;font-weight:bold;">' || APEX_ESCAPE.HTML (v_port_name) || '</span></p>
            </td>
            <td style="width:30%;"></td>
            <td style="width:30%;text-align:left;vertical-align:top;">
              <p class="lbl" style="margin:2px;">الـتـاريـخ :</p>
              <p class="lbl" style="margin:2px;">الـموافق :</p>
              <p class="lbl" style="margin:2px;">الــرقــــم :</p>
            </td>
          </tr>
        </tbody>
      </table>
      <p style="text-align:center;margin:2px;"><span style="color:#0e0f50;font-size:14px;font-weight:bold;">' || APEX_ESCAPE.HTML (v_p_module_name) || '</span></p>
      <table class="data" dir="rtl" style="margin-top:6px;"><thead><tr>
        <th style="width:30%;">اسم الجمرك</th><th style="width:46%;">اسم المستورد</th><th style="width:24%;">تاريخ انتهاء صلاحية النشاط</th>
      </tr></thead></table>
    </div></td>
  </tr>
</thead>
<tfoot>
  <tr>
    <td><div class="MRDFooter">
      <table border="0" cellpadding="1" cellspacing="1" dir="rtl" style="width:100%;">
        <tbody>
          <tr>
            <td style="font-size:11px;color:#0e0f50;">رقم التقرير : <span style="color:#707070;">' || APEX_ESCAPE.HTML (v_p_report_no) || '</span></td>
            <td style="font-size:11px;color:#0e0f50;">التاريخ : <span style="color:#707070;">' || TO_CHAR (HIJDATE_DB.CUR_HIJ_DATE, 'YYYY-MM-MI') || '</span> هـ
               / <span style="color:#707070;">' || TO_CHAR (SYSDATE, 'YYYY-MM-DD') || '</span> م</td>
          </tr>
        </tbody>
      </table>
    </div></td>
  </tr>
</tfoot>
<tbody>
  <tr>
    <td>');

        dbms_lob.append (retVal, '<table class="data" dir="rtl"><tbody>');
        FOR q IN (SELECT IMP.BUS_ID_EXPRD_DT, IMP.ARBC_IMPR_NAME, IMP.PORT_CD, SDP.PORT_NAME PORT_NAME2
                    FROM CSTMS_CLNTS CST, IMPORTERS IMP, SD_PORTS SDP
                   WHERE     IMP.HQ_IMPR_NBR = CST.HQ_IMPR_NBR (+)
                         AND (CST.CLNT_ID = v_p_clnt_id OR v_p_clnt_id IS NULL)
                         AND (IMP.PORT_CD = v_p_port_cd OR v_p_port_cd IS NULL)
                         AND SDP.PORT_CD = IMP.PORT_CD
                         AND (IMP.BUS_ID = v_p_bus_id OR v_p_bus_id IS NULL)
                         AND (IMP.BUS_ID_BRNCH = v_p_bus_id_brnch OR v_p_bus_id_brnch IS NULL)
                   ORDER BY IMP.PORT_CD, SDP.PORT_NAME, IMP.ARBC_IMPR_NAME, IMP.BUS_ID_EXPRD_DT)
        LOOP
            -- R_1 (G_PORT_CD): اسم الجمرك في أول سطر
            v_key := q.PORT_CD || '|' || q.PORT_NAME2;
            IF v_prev_key IS NULL OR v_prev_key <> v_key THEN
                v_prev_key := v_key;
                dbms_lob.append (retVal, '<tr>' || HTML_CELL (q.PORT_NAME2, 'width:30%;text-align:right;'));
            ELSE
                dbms_lob.append (retVal, '<tr><td style="width:30%;"></td>');
            END IF;
            -- R_CG$G_DCLTN
            dbms_lob.append (retVal, HTML_CELL (q.ARBC_IMPR_NAME, 'width:46%;text-align:right;')
                                     || HTML_CELL (TO_CHAR (q.BUS_ID_EXPRD_DT, 'YYYY-MM-MI'), 'width:24%;') || '</tr>');
        END LOOP;
        dbms_lob.append (retVal, '</tbody></table>');

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
    END ARD_IMPR2410;
END IMPR2410_ARD;
/
SHOW ERRORS


CREATE OR REPLACE PUBLIC SYNONYM IMPR2410_ARD FOR LIB_APX_USR.IMPR2410_ARD;


GRANT EXECUTE ON LIB_APX_USR.IMPR2410_ARD TO LIB_USR;

GRANT EXECUTE ON LIB_APX_USR.IMPR2410_ARD TO SECURITY_DEFAULT;

GRANT EXECUTE ON LIB_APX_USR.IMPR2410_ARD TO SECURITY_PROD;

GRANT EXECUTE ON LIB_APX_USR.IMPR2410_ARD TO CUSTOMS;
