-- =============================================================================
-- Package body: IMPR2210_ARD   (matches IMPR2210_ARD_spec.sql)   Version: 001
-- Layout of IMPR2210.rdf (Landscape, right to left):
--   margin : port name, logo, الرقم / التاريخ / المرفقات, title P_MODULE_NAME, footer report number + dates + page
--   M_CG$G_AGNTS_GRPFR (printed only when there are rows): header row + R_CG$G_AGNTS rows.
-- =============================================================================
SET DEFINE OFF

CREATE OR REPLACE PACKAGE BODY LIB_APX_USR.IMPR2210_ARD
AS
    c_list_pattern   CONSTANT VARCHAR2 (60) := '^[0-9]+(,[0-9]+)*$';

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

    -- V_NAME2Formula بالحرف من الـ RDF
    FUNCTION V_NAME2Formula (P_L_IMP_IMPR_TYPE_CD NUMBER) RETURN VARCHAR2 IS
    V_NAME VARCHAR2(100);
    begin
      SELECT IMPR_TYPE_NAME
      INTO   V_NAME
      FROM   IMPR_TYPES
      WHERE  IMPR_TYPE_CD  = P_L_IMP_IMPR_TYPE_CD ;
      RETURN (V_NAME);
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

    FUNCTION ARD_IMPR2210 (P_PARAMETER1   IN VARCHAR2 DEFAULT NULL,
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

        IF v_impr_list IS NULL OR REGEXP_LIKE (v_impr_list, c_list_pattern) THEN
            FOR q IN (SELECT AG.ATHRZTN_SEQ_NBR   ATHRZTN_SEQ_NBR,
                             AG.ATHRZTN_CRET_DT   ATHRZTN_CRET_DT,
                             AG.ATHRZTN_CNCLD_DT  ATHRZTN_CNCLD_DT,
                             DECODE (AG.ATHRZTN_STA_CD, '1', 'ساري', '2', 'غير ساري', AG.ATHRZTN_STA_CD) ATHRZTN_STA_CDM,
                             IMP.IMPR_NBR         IMPR_NBR,
                             IMP.ARBC_IMPR_NAME   ARBC_IMPR_NAME,
                             IMP.IMPR_TYPE_CD     IMPR_TYPE_CD,
                             L_IMP.IMPR_NBR       L_IMP_IMPR_NBR,
                             L_IMP.ARBC_IMPR_NAME L_IMP_ARBC_IMPR_NAME,
                             L_IMP.IMPR_TYPE_CD   L_IMP_IMPR_TYPE_CD
                        FROM IMPORTERS IMP, IMPORTERS L_IMP, AGNTS AG
                       WHERE     AG.PORT_CD = L_IMP.PORT_CD
                             AND AG.IMPR_NBR = L_IMP.IMPR_NBR
                             AND AG.PORT_CD = IMP.PORT_CD
                             AND AG.IMPR_NBR_AGENT_ID = IMP.IMPR_NBR
                             AND IMP.PORT_CD = v_p_curr_port_cd
                             AND (v_impr_list IS NULL OR IMP.IMPR_NBR IN (SELECT TO_NUMBER (REGEXP_SUBSTR (v_impr_list, '[^,]+', 1, LEVEL)) FROM DUAL
                                    CONNECT BY REGEXP_SUBSTR (v_impr_list, '[^,]+', 1, LEVEL) IS NOT NULL))
                             AND (IMP.PORT_CD = v_p_curr_port_cd OR v_p_curr_port_cd IS NULL)
                       ORDER BY AG.ATHRZTN_SEQ_NBR)
            LOOP
                v_rows := v_rows + 1;
                IF v_rows = 1 THEN
                    -- M_CG$G_AGNTS_HDR
                    dbms_lob.append (retVal, '
              <table class="data" dir="rtl"><thead><tr>
                <th style="width:6%;">مسلسل التفويض</th><th style="width:9%;">تاريخ انشاء التفويض</th><th style="width:7%;">حالة التفويض</th>
                <th style="width:9%;">تاريخ حذف التفويض</th><th style="width:6%;">مسلسل الشركة</th><th style="width:19%;">اسم الشركة الوسيطه</th>
                <th style="width:11%;">نوع الشركة الوسيطه</th><th style="width:6%;">مسلسل المستورد</th><th style="width:17%;">اسم المستورد</th>
                <th style="width:10%;">نوع المستورد</th>
              </tr></thead><tbody>');
                END IF;
                -- R_CG$G_AGNTS
                dbms_lob.append (retVal, '<tr>' || HTML_CELL (q.ATHRZTN_SEQ_NBR) || HTML_CELL (TO_CHAR (q.ATHRZTN_CRET_DT, 'MI-MM-YYYY'))
                                         || HTML_CELL (q.ATHRZTN_STA_CDM) || HTML_CELL (TO_CHAR (q.ATHRZTN_CNCLD_DT, 'MI-MM-YYYY'))
                                         || HTML_CELL (q.IMPR_NBR) || HTML_CELL (q.ARBC_IMPR_NAME, 'text-align:right;')
                                         || HTML_CELL (V_NAMEFormula (q.IMPR_TYPE_CD)) || HTML_CELL (q.L_IMP_IMPR_NBR)
                                         || HTML_CELL (q.L_IMP_ARBC_IMPR_NAME, 'text-align:right;')
                                         || HTML_CELL (V_NAME2Formula (q.L_IMP_IMPR_TYPE_CD)) || '</tr>');
            END LOOP;
        END IF;

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
    END ARD_IMPR2210;
END IMPR2210_ARD;
/
SHOW ERRORS


CREATE OR REPLACE PUBLIC SYNONYM IMPR2210_ARD FOR LIB_APX_USR.IMPR2210_ARD;


GRANT EXECUTE ON LIB_APX_USR.IMPR2210_ARD TO LIB_USR;

GRANT EXECUTE ON LIB_APX_USR.IMPR2210_ARD TO SECURITY_DEFAULT;

GRANT EXECUTE ON LIB_APX_USR.IMPR2210_ARD TO SECURITY_PROD;

GRANT EXECUTE ON LIB_APX_USR.IMPR2210_ARD TO CUSTOMS;
