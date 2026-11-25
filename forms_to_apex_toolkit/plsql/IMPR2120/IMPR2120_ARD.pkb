-- =============================================================================
-- Package body: IMPR2120_ARD   (matches IMPR2120_ARD.pks)   Version: 001
-- Layout of IMPR2120.rdf (Landscape, right to left):
--   margin : port name, logo, الرقم / التاريخ / المرفقات, title P_MODULE_NAME, footer report number + dates + page
--   M_CG$G_IMPR_SUSPNS_GRPFR (printed only when there are rows): one header row, then
--   R_1 (G_C_PORT_CD, per importer): جهة التوقيف, مسلسل المستورد, الرقم الاستدلالى, رقم الفرع, اسم المستورد
--   next to R_CG$G_IMPR_SUSPNS (per suspension): بداية / نهاية التوقيف, حالة التوقيف, تاريخ الحذف, السبب.
--   The importer cells print on the first suspension line of the importer (as the RDF frames).
-- =============================================================================
SET DEFINE OFF

CREATE OR REPLACE PACKAGE BODY LIB_APX_USR.IMPR2120_ARD
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

    -- C_PORT_CDFormula بالحرف من الـ RDF (بيقرا PORT_CD بتاع أول توقيف في المجموعة)
    FUNCTION C_PORT_CDFormula (P_PORT_CD NUMBER) RETURN VARCHAR2 IS
    	v_port  varchar2 (20) := 'الجمــــرك';
    	R_VALUE CHAR(20) := 'المصلحة';
    begin
      if P_PORT_CD = 99 then
      	RETURN (R_VALUE);
      else
      	RETURN (V_PORT);
      	END IF ;
    	end;

    -- C_DATEFormula من الـ RDF (HIJDATE -> HIJDATE_DB)
    FUNCTION C_DATEFormula RETURN DATE IS
    H_DAT		DATE ;
    begin
      H_DAT := HIJDATE_DB.CUR_HIJ_DATE ;
      RETURN (H_DAT );
    end;

    -- V_MEANFormula بالحرف من الـ RDF
    FUNCTION V_MEANFormula (P_SUSPN_RLSE_DT DATE, P_SUSPN_STRT_DT DATE, P_SUSPN_END_DT DATE) RETURN VARCHAR2 IS
    H_DAT		DATE ;
    begin
      H_DAT := HIJDATE_DB.CUR_HIJ_DATE ;

      IF P_SUSPN_RLSE_DT IS  NOT NULL THEN
      	RETURN ('  غير ساري  ');
      ELSIF P_SUSPN_RLSE_DT IS  NULL AND  H_DAT NOT BETWEEN P_SUSPN_STRT_DT AND P_SUSPN_END_DT THEN
      	RETURN (' غير ساري ');
      ELSE
      	RETURN (' ساري ');
      END IF ;
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

    FUNCTION ARD_IMPR2120 (P_PARAMETER1   IN VARCHAR2 DEFAULT NULL,
                           P_PARAMETER2   IN VARCHAR2 DEFAULT NULL,
                           P_PARAMETER3   IN VARCHAR2 DEFAULT NULL,
                           P_PARAMETER4   IN VARCHAR2 DEFAULT NULL,
                           P_PARAMETER5   IN VARCHAR2 DEFAULT NULL)
        RETURN CLOB
    IS
        retVal                 CLOB;
        v_p_curr_port_cd       NUMBER := TO_NUMBER (P_PARAMETER1);
        v_impr_list            VARCHAR2 (4000) := RTRIM (REGEXP_REPLACE (P_PARAMETER2, '\s', ''), ',');
        v_p_type               NUMBER := TO_NUMBER (P_PARAMETER3);
        v_p_module_name        VARCHAR2 (4000) := P_PARAMETER4;
        v_p_report_no          VARCHAR2 (4000) := P_PARAMETER5;
        v_c_date               DATE;             -- C_DATE
        v_port_name            VARCHAR2 (100);   -- V_PORT_NAME_SEC1
        v_key                  VARCHAR2 (4000);
        v_prev_key             VARCHAR2 (4000);  -- G_C_PORT_CD اللي فات (break)
        v_rows                 NUMBER := 0;
    BEGIN
        DBMS_LOB.createtemporary (retVal, TRUE);

        v_c_date := C_DATEFormula;
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
            FOR q IN (SELECT IMP.IMPR_NBR        IMPR_NBR,
                             IS_1.SUSPN_SEQ      SUSPN_SEQ,
                             IMP.BUS_ID          BUS_ID,
                             IS_1.PORT_CD        PORT_CD,
                             IMP.ARBC_IMPR_NAME  ARBC_IMPR_NAME,
                             IMP.BUS_ID_BRNCH    BUS_ID_BRNCH,
                             IS_1.SUSPN_STRT_DT  SUSPN_STRT_DT,
                             IS_1.SUSPN_END_DT   SUSPN_END_DT,
                             IS_1.SUSPN_RLSE_DT  SUSPN_RLSE_DT,
                             IS_1.SUSPN_RSN_TEXT SUSPN_RSN_TEXT,
                             IMPR2120_ARD.V_MEANFormula (IS_1.SUSPN_RLSE_DT, IS_1.SUSPN_STRT_DT, IS_1.SUSPN_END_DT) V_MEAN
                        FROM IMPORTERS IMP, IMPR_SUSPNS IS_1
                       WHERE     IS_1.IMPR_NBR = IMP.IMPR_NBR
                             AND IS_1.PORT_CD = IMP.PORT_CD
                             -- &CG$P_IMPR_NBR (:parameter.TRAN_SELECT of the form)
                             AND IMP.IMPR_NBR IS NOT NULL
                             AND (   v_impr_list IS NULL
                                  OR IMP.IMPR_NBR IN (SELECT TO_NUMBER (REGEXP_SUBSTR (v_impr_list, '[^,]+', 1, LEVEL)) FROM DUAL
                                    CONNECT BY REGEXP_SUBSTR (v_impr_list, '[^,]+', 1, LEVEL) IS NOT NULL))
                             AND (v_p_curr_port_cd IS NULL OR IS_1.PORT_CD = v_p_curr_port_cd)
                             AND (   (    (v_c_date BETWEEN IS_1.SUSPN_STRT_DT AND IS_1.SUSPN_END_DT)
                                      AND IS_1.SUSPN_RLSE_DT IS NULL
                                      AND (v_p_type = 2 OR v_p_type = 3))
                                  OR (    (   (v_c_date NOT BETWEEN IS_1.SUSPN_STRT_DT AND IS_1.SUSPN_END_DT)
                                           OR IS_1.SUSPN_RLSE_DT IS NOT NULL)
                                      AND (v_p_type = 1 OR v_p_type = 3)))
                       ORDER BY IMP.IMPR_NBR, IMP.BUS_ID, IMP.ARBC_IMPR_NAME, IMP.BUS_ID_BRNCH, IS_1.SUSPN_SEQ)
            LOOP
                v_rows := v_rows + 1;
                IF v_rows = 1 THEN
                    -- M_CG$G_IMPR_SUSPNS_HDR
                    dbms_lob.append (retVal, '
              <table class="data" dir="rtl"><thead><tr>
                <th style="width:6%;">جهة التوقيف</th><th style="width:6%;">مسلسل المستورد</th>
                <th style="width:9%;">الرقم الاستدلالى للمستورد</th><th style="width:7%;">رقم الفرع التابع للمستورد الرئيسى</th>
                <th style="width:20%;">اسم المستورد</th><th style="width:8%;">تاريخ بدايه التوقيف</th>
                <th style="width:8%;">تاريخ نهايه التوقيف</th><th style="width:7%;">حالة التوقيف</th>
                <th style="width:8%;">تاريخ حذف التوقيف</th><th style="width:21%;">توصيف سبب التوقيف</th>
              </tr></thead><tbody>');
                END IF;

                -- R_1 (G_C_PORT_CD): خانات المستورد في أول سطر بس
                v_key := q.IMPR_NBR || '|' || q.BUS_ID || '|' || q.ARBC_IMPR_NAME || '|' || q.BUS_ID_BRNCH;
                IF v_prev_key IS NULL OR v_prev_key <> v_key THEN
                    v_prev_key := v_key;
                    dbms_lob.append (retVal, '<tr>' || HTML_CELL (C_PORT_CDFormula (q.PORT_CD)) || HTML_CELL (q.IMPR_NBR)
                                             || HTML_CELL (q.BUS_ID) || HTML_CELL (q.BUS_ID_BRNCH)
                                             || HTML_CELL (q.ARBC_IMPR_NAME, 'text-align:right;'));
                ELSE
                    dbms_lob.append (retVal, '<tr><td></td><td></td><td></td><td></td><td></td>');
                END IF;

                -- R_CG$G_IMPR_SUSPNS
                dbms_lob.append (retVal, HTML_CELL (TO_CHAR (q.SUSPN_STRT_DT, 'MI-MM-YYYY')) || HTML_CELL (TO_CHAR (q.SUSPN_END_DT, 'MI-MM-YYYY'))
                                         || HTML_CELL (q.V_MEAN) || HTML_CELL (TO_CHAR (q.SUSPN_RLSE_DT, 'MI-MM-YYYY'))
                                         || HTML_CELL (q.SUSPN_RSN_TEXT, 'text-align:right;') || '</tr>');
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
    END ARD_IMPR2120;
END IMPR2120_ARD;
/
SHOW ERRORS


CREATE OR REPLACE PUBLIC SYNONYM IMPR2120_ARD FOR LIB_APX_USR.IMPR2120_ARD;


GRANT EXECUTE ON LIB_APX_USR.IMPR2120_ARD TO LIB_USR;

GRANT EXECUTE ON LIB_APX_USR.IMPR2120_ARD TO SECURITY_DEFAULT;

GRANT EXECUTE ON LIB_APX_USR.IMPR2120_ARD TO SECURITY_PROD;

GRANT EXECUTE ON LIB_APX_USR.IMPR2120_ARD TO CUSTOMS;
