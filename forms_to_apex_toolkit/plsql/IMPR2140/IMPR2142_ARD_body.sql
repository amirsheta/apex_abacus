-- =============================================================================
-- Package body: IMPR2142_ARD   (matches IMPR2142_ARD_spec.sql)   Version: 001
-- Layout of IMPR2142.rdf (Portrait, right to left): a letter per importer (R_1), one page each.
--   margin : port name + "التدقيق والفروقات" (right), logo, الرقم / التاريخ / المرفقات (left)
--   R_1    : the letter text of the RDF boilerplate with the importer fields.
--   Query: RDF plus the join IMP.PORT_CD = SDP.PORT_CD (the RDF has none, see the spec).
-- =============================================================================
SET DEFINE OFF

CREATE OR REPLACE PACKAGE BODY LIB_APX_USR.IMPR2142_ARD
AS
    c_number_pattern CONSTANT VARCHAR2 (60) := '^[0-9]+$';

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

    -- CF_PORT_MANGERFormula من الـ RDF (الـ RDF من غير PORT_CD: لو الإعداد في أكتر من جمرك TOO_MANY_ROWS
    -- والتقرير بيقف؛ هنا PORT_CD = P_CURR_PORT_CD زي IMPR2141 / 2143)
    FUNCTION CF_PORT_MANGERFormula (P_CURR_PORT_CD NUMBER) RETURN VARCHAR2 IS
    V_MNGR_NAME VARCHAR2(200);
    begin
      SELECT VAR_VALUE
      INTO   V_MNGR_NAME
      FROM   SC_PORT_SETTING
      WHERE  SYSOBJ_ID = 999
        AND  VAR_NAME  = 'PORT_MANAGER_NAME'
        AND PORT_CD = P_CURR_PORT_CD ;
      RETURN (V_MNGR_NAME);
    EXCEPTION
    	WHEN NO_DATA_FOUND THEN
    	RETURN(NULL);
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

    FUNCTION ARD_IMPR2142 (P_PARAMETER1   IN VARCHAR2 DEFAULT NULL,
                           P_PARAMETER2   IN VARCHAR2 DEFAULT NULL)
        RETURN CLOB
    IS
        retVal                 CLOB;
        v_p_curr_port_cd       NUMBER := TO_NUMBER (P_PARAMETER1);
        v_impr_no              VARCHAR2 (4000) := TRIM (P_PARAMETER2);
        v_port_name            VARCHAR2 (100);   -- V_PORT_NAME_SEC1
        v_port_manager         VARCHAR2 (200);   -- CF_PORT_MANGER
        v_rows                 NUMBER := 0;
    BEGIN
        DBMS_LOB.createtemporary (retVal, TRUE);

        v_port_name := V_PORT_NAME_SEC1FormatTrigger (v_p_curr_port_cd);
        v_port_manager := CF_PORT_MANGERFormula (v_p_curr_port_cd);
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
.letter{ font-size:14px; line-height:2.1; color:#000000; padding:0 20px; }
.letter p{ margin:0; }
.letter .sign{ text-align:center; width:45%; margin-right:55%; }
.letter .fld{ font-weight:bold; }
@page {
   background: white;
   margin-top: 20px;
   margin-bottom: 40px;
   margin-left: 30px;
   margin-right: 30px;
   size: A4 portrait;
}
</style></head>');

        -- كل صفحة: اسم الجمرك والتدقيق والفروقات يمين، اللوجو في النص، الرقم / التاريخ / المرفقات شمال
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
            <td style="width:30%;vertical-align:bottom;">
              <p style="margin:2px;"><span style="color:#0e0f50;font-size:12px;font-weight:bold;">' || APEX_ESCAPE.HTML (v_port_name) || '</span></p>
              <p style="margin:2px;"><span style="color:#0e0f50;font-size:12px;">التدقيق والفروقات</span></p>
            </td>
            <td style="width:40%;text-align:center;">');
        dbms_lob.append (retVal, ARD_LOGO.IMG (85, 335, NULL, 'LOGO1.jpg'));   -- اللوجو Static File في الأبلكيشن (DEC-034)
        dbms_lob.append (retVal, '</td>
            <td style="width:30%;text-align:left;vertical-align:top;">
              <p class="lbl" style="margin:2px;">الرقم :</p>
              <p class="lbl" style="margin:2px;">التاريخ :</p>
              <p class="lbl" style="margin:2px;">المرفقات :</p>
            </td>
          </tr>
        </tbody>
      </table>
    </div></td>
  </tr>
</thead>
<tbody>
  <tr>
    <td>');

        -- IMPR_NO لازم يكون رقم (الشاشة بتتأكد)، وإلا من غير خطابات
        IF v_impr_no IS NULL OR REGEXP_LIKE (v_impr_no, c_number_pattern) THEN
            FOR q IN (SELECT IMP.IMPR_NBR       IMPR_NBR,
                             IMP.IMPR_POB_NBR   IMPR_POB_NBR,
                             IMP.IMPR_ZIP_CD    IMPR_ZIP_CD,
                             IMP.ARBC_IMPR_NAME IMPR_NAME,
                             SDP.PORT_NAME      PORT_NAME
                        FROM IMPORTERS IMP, SD_PORTS SDP
                       WHERE     (IMP.IMPR_NBR = v_impr_no OR v_impr_no IS NULL)
                             -- الـ RDF من غير ربط IMP بـ SDP (خطاب لكل مستورد بنفس الرقم في كل الجمارك)؛ الربط زي IMPR2141 / 2143
                             AND SDP.PORT_CD = IMP.PORT_CD
                             AND (SDP.PORT_CD = v_p_curr_port_cd OR v_p_curr_port_cd IS NULL)
                       ORDER BY IMP.IMPR_NBR)
            LOOP
                v_rows := v_rows + 1;
                -- R_1: خطاب لكل مستورد في صفحة لوحده
                dbms_lob.append (retVal, '<div class="letter"' || CASE WHEN v_rows > 1 THEN ' style="page-break-before:always;"' END || '>');
                dbms_lob.append (retVal, '
              <p>صورة مع التحية لسعادة مدير عام إدارة التدقيق العام بمصلحة الجمارك &nbsp;&nbsp;&nbsp; المحترم</p>');
                dbms_lob.append (retVal, '
              <p>السـادة / <span class="fld">' || APEX_ESCAPE.HTML (q.IMPR_NAME) || '</span>&nbsp;&nbsp;&nbsp; المحترمين</p>
              <p>رقم المالك / <span class="fld">' || APEX_ESCAPE.HTML (q.IMPR_NBR) || '</span></p>
              <p>ص . ب ( <span class="fld">' || APEX_ESCAPE.HTML (q.IMPR_POB_NBR) || '</span> ) &nbsp;&nbsp;&nbsp; الرمــز البـريـدي ( <span class="fld">' || APEX_ESCAPE.HTML (q.IMPR_ZIP_CD) || '</span> )</p>
              <p>الـسـلام عـلـيـكـم ورحـمـة الله وبـركـاتـه ... &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; وبعد:-</p>');
                dbms_lob.append (retVal, '
              <p>تـلـقـينا خـطـاب سعـادة مديـر عام إدارة التدقيـق بمصلحة الجمـارك المتضمن وجـود فروقـات مالية عليكم.</p>
              <p>نأمل منكم مراجعة قسم التدقيق والفروقات بـ <span class="fld">' || APEX_ESCAPE.HTML (q.PORT_NAME) || '</span> في مدة أقصاها
                 عشـرة أيـام من تاريخه لسـداد الفروقـات المترتبة عليـكم وفي حالـة عدم مراجعتـكم سيتـــم إيقـاف سجلكم في الحـاسب الآلي لحيــن المراجعة والتسديد.</p>
              <p style="text-align:center;">وتـقبلوا تحياتي,،،،،</p>
              <p class="sign">مدير عام <span class="fld">' || APEX_ESCAPE.HTML (q.PORT_NAME) || '</span></p>
              <p class="sign"><span class="fld">' || APEX_ESCAPE.HTML (v_port_manager) || '</span></p>');
                dbms_lob.append (retVal, '</div>');
            END LOOP;
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
    END ARD_IMPR2142;
END IMPR2142_ARD;
/
SHOW ERRORS


CREATE OR REPLACE PUBLIC SYNONYM IMPR2142_ARD FOR LIB_APX_USR.IMPR2142_ARD;


GRANT EXECUTE ON LIB_APX_USR.IMPR2142_ARD TO LIB_USR;

GRANT EXECUTE ON LIB_APX_USR.IMPR2142_ARD TO SECURITY_DEFAULT;

GRANT EXECUTE ON LIB_APX_USR.IMPR2142_ARD TO SECURITY_PROD;

GRANT EXECUTE ON LIB_APX_USR.IMPR2142_ARD TO CUSTOMS;
