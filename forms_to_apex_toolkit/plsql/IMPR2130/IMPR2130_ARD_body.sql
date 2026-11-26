-- =============================================================================
-- Package body: IMPR2130_ARD   (matches IMPR2130_ARD_spec.sql)   Version: 001
-- Layout of IMPR2130.rdf (Landscape, right to left):
--   margin : port name, logo, الرقم / التاريخ / المرفقات, title P_MODULE_NAME, footer report number + dates + page
--   R_CG$G_MAS_G (per importer IMPR_NBR): "رقم المستورد :"
--   R_CG$G_DET_G (per update record): two columns of label : value (12 right, 11 left), labels without the
--   kashida stretching of the RDF. Frames print only when there are rows.
-- =============================================================================
SET DEFINE OFF

CREATE OR REPLACE PACKAGE BODY LIB_APX_USR.IMPR2130_ARD
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

    FUNCTION ARD_IMPR2130 (P_PARAMETER1   IN VARCHAR2 DEFAULT NULL,
                           P_PARAMETER2   IN VARCHAR2 DEFAULT NULL,
                           P_PARAMETER3   IN VARCHAR2 DEFAULT NULL,
                           P_PARAMETER4   IN VARCHAR2 DEFAULT NULL,
                           P_PARAMETER5   IN VARCHAR2 DEFAULT NULL,
                           P_PARAMETER6   IN VARCHAR2 DEFAULT NULL)
        RETURN CLOB
    IS
        retVal                 CLOB;
        v_p_curr_port_cd       NUMBER := TO_NUMBER (P_PARAMETER1);
        v_impr_list            VARCHAR2 (4000) := RTRIM (REGEXP_REPLACE (P_PARAMETER2, '\s', ''), ',');
        v_start_dt             DATE := TO_DATE (P_PARAMETER3, 'YYYY-MM-MI');
        v_end_dt               DATE := TO_DATE (P_PARAMETER4, 'YYYY-MM-MI');
        v_p_module_name        VARCHAR2 (4000) := P_PARAMETER5;
        v_p_report_no          VARCHAR2 (4000) := P_PARAMETER6;
        v_port_name            VARCHAR2 (100);   -- V_PORT_NAME_SEC1
        v_prev_key             VARCHAR2 (4000);  -- CG$G_MAS_G اللي فات (break)
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
.data td.lbl{ color:#0e0f50; text-align:right; }
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
            FOR q IN (SELECT IU.IMPR_NBR        IMPR_NBR,
                             IU.ACT_DT          ACT_DT,
                             DECODE (IU.ACT_TYPE, 'U', 'تعديل السجل', 'D', 'حذف السجل', 'I', 'إضافة سجل', IU.ACT_TYPE) ACT_TYPEM,
                             L_CT.CITY_ARB_NAME ADD_CITY_ARB_NAME,
                             IU.ARBC_IMPR_NAME  ARBC_IMPR_NAME,
                             IU.BUS_ID          BUS_ID,
                             IU.BUS_ID_BRNCH    BUS_ID_BRNCH,
                             L_BIT.BUS_ID_TYPE_NAME BUS_ID_TYPE_NAME,
                             IU.ENG_IMPR_NAME   ENG_IMPR_NAME,
                             IU.HQ_IMPR_NBR     HQ_IMPR_NBR,
                             L_CT2.CITY_ARB_NAME ID_CITY_ARB_NAME,
                             CG.RV_MEANING      IMPR_EXPR_TYPEM,
                             L_IT1.IMPR_TYPE_NAME IMPR_TYPE_NAME,
                             L_USR.USR_ANAME    L_USR_USR_ANAME,
                             IU.USR_ID          USR_ID,
                             IU.BUS_ID_EXPRD_DT BUS_ID_EXPRD_DT,
                             IU.EMAIL           EMAIL,
                             IU.IMPR_CNTCT_NAME IMPR_CNTCT_NAME,
                             IU.IMPR_FAX_NBR    IMPR_FAX_NBR,
                             IU.IMPR_POB_NBR    IMPR_POB_NBR,
                             IU.IMPR_TELEX_NBR  IMPR_TELEX_NBR,
                             IU.IMPR_TEL_NBR    IMPR_TEL_NBR,
                             IU.IMPR_ZIP_CD     IMPR_ZIP_CD,
                             L_IMP.ARBC_IMPR_NAME PARENT_IMPR_NAME
                        FROM CG_REF_CODES CG,
                             COUNTRIES L_CTRY,
                             CITIES L_CT,
                             SC_USERS L_USR,
                             BUS_ID_TYPES L_BIT,
                             IMPR_TYPES L_IT1,
                             IMPR_TYPE_ID_TYPES L_ITIDT,
                             CITIES L_CT2,
                             IMPORTERS L_IMP,
                             IMPR_UPDTS IU
                       WHERE     IU.PORT_CD = L_IMP.PORT_CD
                             AND IU.IMPR_NBR = L_IMP.IMPR_NBR
                             AND IU.CTRY_CD_OF_ID = L_CT2.CTRY_CD (+)
                             AND IU.CITY_CODE_OF_ID = L_CT2.CITY_CD (+)
                             AND IU.IMPR_TYPE_CD = L_ITIDT.IMPR_TYPE_CD
                             AND IU.BUS_ID_TYPE_CD = L_ITIDT.BUS_ID_TYPE_CD
                             AND L_ITIDT.IMPR_TYPE_CD = L_IT1.IMPR_TYPE_CD
                             AND L_ITIDT.BUS_ID_TYPE_CD = L_BIT.BUS_ID_TYPE_CD
                             AND IU.PORT_CD = L_USR.PORT_CD
                             AND IU.USR_ID = L_USR.USER_ID
                             AND IU.ADD_CTRY_CD = L_CT.CTRY_CD
                             AND IU.CITY_CODE = L_CT.CITY_CD
                             AND IU.CTRY_CD = L_CTRY.CTRY_CD
                             AND CG.RV_DOMAIN (+) = 'ALLOWED EXPORT'
                             AND CG.RV_LOW_VALUE (+) = IU.IMPR_EXPR_TYPE
                             AND (IU.ACT_DT BETWEEN v_start_dt AND v_end_dt OR (v_start_dt IS NULL AND v_end_dt IS NULL))
                             AND (L_IMP.PORT_CD = v_p_curr_port_cd OR v_p_curr_port_cd IS NULL)
                             -- &P_IMPR_NBR (:parameter.TRAN_SELECT of the form)
                             AND IU.IMPR_NBR IS NOT NULL
                             AND (   v_impr_list IS NULL
                                  OR IU.IMPR_NBR IN (SELECT TO_NUMBER (REGEXP_SUBSTR (v_impr_list, '[^,]+', 1, LEVEL)) FROM DUAL
                                    CONNECT BY REGEXP_SUBSTR (v_impr_list, '[^,]+', 1, LEVEL) IS NOT NULL))
                       ORDER BY IU.IMPR_NBR, IU.ACT_DT)
            LOOP
                -- R_CG$G_MAS_G
                IF v_prev_key IS NULL OR v_prev_key <> TO_CHAR (q.IMPR_NBR) THEN
                    v_prev_key := TO_CHAR (q.IMPR_NBR);
                    dbms_lob.append (retVal, '<table class="grp" dir="rtl"><tbody><tr><td>'
                                             || LABEL_VALUE ('رقم المستورد :', q.IMPR_NBR) || '</td></tr></tbody></table>');
                END IF;

                -- R_CG$G_DET_G
                dbms_lob.append (retVal, '<table class="data" dir="rtl" style="margin-bottom:8px;"><tbody>');
                dbms_lob.append (retVal, '<tr><td class="lbl" style="width:18%;">تاريخ اضافة السجل :</td>' || HTML_CELL (TO_CHAR (q.ACT_DT, 'DD-MM-YYYY'), 'width:32%;') || '<td class="lbl" style="width:18%;">المستخدم :</td>' || HTML_CELL (q.USR_ID, 'width:32%;') || '</tr>');
                dbms_lob.append (retVal, '<tr><td class="lbl" style="width:18%;">نوع النشاط :</td>' || HTML_CELL (q.ACT_TYPEM, 'width:32%;') || '<td class="lbl" style="width:18%;">اسم المستخدم :</td>' || HTML_CELL (q.L_USR_USR_ANAME, 'width:32%;') || '</tr>');
                dbms_lob.append (retVal, '<tr><td class="lbl" style="width:18%;">مدينة إصدار الحفيظه :</td>' || HTML_CELL (q.ADD_CITY_ARB_NAME, 'width:32%;') || '<td class="lbl" style="width:18%;">تاريخ انتهاء سجل المستورد :</td>' || HTML_CELL (TO_CHAR (q.BUS_ID_EXPRD_DT, 'MI-MM-YYYY'), 'width:32%;') || '</tr>');
                dbms_lob.append (retVal, '<tr><td class="lbl" style="width:18%;">اسم المستورد :</td>' || HTML_CELL (q.ARBC_IMPR_NAME, 'width:32%;') || '<td class="lbl" style="width:18%;">البريد الإلكتروني للمستورد :</td>' || HTML_CELL (q.EMAIL, 'width:32%;') || '</tr>');
                dbms_lob.append (retVal, '<tr><td class="lbl" style="width:18%;">الرقم الاستدلالى للمستورد :</td>' || HTML_CELL (q.BUS_ID, 'width:32%;') || '<td class="lbl" style="width:18%;">اسم الوكيل المفوض :</td>' || HTML_CELL (q.IMPR_CNTCT_NAME, 'width:32%;') || '</tr>');
                dbms_lob.append (retVal, '<tr><td class="lbl" style="width:18%;">رقم الفرع للمستورد :</td>' || HTML_CELL (q.BUS_ID_BRNCH, 'width:32%;') || '<td class="lbl" style="width:18%;">رقم الفاكس :</td>' || HTML_CELL (q.IMPR_FAX_NBR, 'width:32%;') || '</tr>');
                dbms_lob.append (retVal, '<tr><td class="lbl" style="width:18%;">مسمي نوع المستورد :</td>' || HTML_CELL (q.BUS_ID_TYPE_NAME, 'width:32%;') || '<td class="lbl" style="width:18%;">صندوق البريد :</td>' || HTML_CELL (q.IMPR_POB_NBR, 'width:32%;') || '</tr>');
                dbms_lob.append (retVal, '<tr><td class="lbl" style="width:18%;">الاسم الأجنبى للمستورد :</td>' || HTML_CELL (q.ENG_IMPR_NAME, 'width:32%;') || '<td class="lbl" style="width:18%;">تلكس :</td>' || HTML_CELL (q.IMPR_TELEX_NBR, 'width:32%;') || '</tr>');
                dbms_lob.append (retVal, '<tr><td class="lbl" style="width:18%;">الرقم الموحد :</td>' || HTML_CELL (q.HQ_IMPR_NBR, 'width:32%;') || '<td class="lbl" style="width:18%;">رقم تليفون المستورد :</td>' || HTML_CELL (q.IMPR_TEL_NBR, 'width:32%;') || '</tr>');
                dbms_lob.append (retVal, '<tr><td class="lbl" style="width:18%;">رمز مدينة إصدار الحفيظه :</td>' || HTML_CELL (q.ID_CITY_ARB_NAME, 'width:32%;') || '<td class="lbl" style="width:18%;">الرمز البريدى :</td>' || HTML_CELL (q.IMPR_ZIP_CD, 'width:32%;') || '</tr>');
                dbms_lob.append (retVal, '<tr><td class="lbl" style="width:18%;">نوع العمليه :</td>' || HTML_CELL (q.IMPR_EXPR_TYPEM, 'width:32%;') || '<td class="lbl" style="width:18%;">تابع لي :</td>' || HTML_CELL (q.PARENT_IMPR_NAME, 'width:32%;') || '</tr>');
                dbms_lob.append (retVal, '<tr><td class="lbl" style="width:18%;">نوع المستورد :</td>' || HTML_CELL (q.IMPR_TYPE_NAME, 'width:32%;') || '<td></td><td></td></tr>');
                dbms_lob.append (retVal, '</tbody></table>');
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
    END ARD_IMPR2130;
END IMPR2130_ARD;
/
SHOW ERRORS


CREATE OR REPLACE PUBLIC SYNONYM IMPR2130_ARD FOR LIB_APX_USR.IMPR2130_ARD;


GRANT EXECUTE ON LIB_APX_USR.IMPR2130_ARD TO LIB_USR;

GRANT EXECUTE ON LIB_APX_USR.IMPR2130_ARD TO SECURITY_DEFAULT;

GRANT EXECUTE ON LIB_APX_USR.IMPR2130_ARD TO SECURITY_PROD;

GRANT EXECUTE ON LIB_APX_USR.IMPR2130_ARD TO CUSTOMS;
