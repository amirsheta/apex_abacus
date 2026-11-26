-- =============================================================================
-- Package body: IMPR2180_ARD   (matches IMPR2180_ARD_spec.sql)   Version: 001
-- Layout of IMPR2180.rdf (Landscape, right to left):
--   margin : port name, logo, الرقم / التاريخ / المرفقات, title P_MODULE_NAME, footer report number + dates + page
--   R_1 (G_TYP): header row (رقم رخصه المخلص for TYP 1, رقم بطاقة المعقب otherwise) + rows, then إجمالي العدد
--   R_2 (broker) / R_3 (BUS_ID) / R_4 (importer) on one line each, outer cells on the first line of their
--   group. After the last group: الإجمالي الكلي.
-- =============================================================================
SET DEFINE OFF

CREATE OR REPLACE PACKAGE BODY LIB_APX_USR.IMPR2180_ARD
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

    -- C_LIC_TYPEFormula بالحرف من الـ RDF
    FUNCTION C_LIC_TYPEFormula (P_LIC_TYPE NUMBER) RETURN VARCHAR2 IS
    V_DESC VARCHAR2(200);
    begin
      SELECT RV_MEANING
      INTO   V_DESC
      FROM   CG_REF_CODES
      WHERE  RV_LOW_VALUE  = TO_CHAR(P_LIC_TYPE)
      AND    RV_DOMAIN  LIKE 'LICENSE TYPE' ;
      RETURN (V_DESC);
      EXCEPTION
      WHEN OTHERS THEN
      RETURN NULL;
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

    FUNCTION ARD_IMPR2180 (P_PARAMETER1   IN VARCHAR2 DEFAULT NULL,
                           P_PARAMETER2   IN VARCHAR2 DEFAULT NULL,
                           P_PARAMETER3   IN VARCHAR2 DEFAULT NULL,
                           P_PARAMETER4   IN VARCHAR2 DEFAULT NULL)
        RETURN CLOB
    IS
        retVal                 CLOB;
        v_p_curr_port_cd       NUMBER := TO_NUMBER (P_PARAMETER1);
        v_p_lic_type           NUMBER := TO_NUMBER (P_PARAMETER2);
        v_p_module_name        VARCHAR2 (4000) := P_PARAMETER3;
        v_p_report_no          VARCHAR2 (4000) := P_PARAMETER4;
        v_port_name            VARCHAR2 (100);   -- V_PORT_NAME_SEC1
        v_prev_typ             NUMBER;           -- G_TYP اللي فات
        v_broker_key           VARCHAR2 (4000);
        v_prev_broker_key      VARCHAR2 (4000);  -- CG$G_BRKR_MSTR اللي فات
        v_bus_key              VARCHAR2 (4000);
        v_prev_bus_key         VARCHAR2 (4000);  -- G_BUS_ID اللي فات
        v_cs_3                 NUMBER := 0;      -- CS_3 (لكل نوع)
        v_cs_2                 NUMBER := 0;      -- CS_2 (التقرير)
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

        FOR q IN (SELECT DISTINCT I.TYP, I.LIC_NBR, I.LIC_TYPE, I.BRKR_NAME, I.PORT_CD, I.NEW_ID_NBR,
                                  I.BUS_ID, I.BRNCH_BUS_ID, I.ARBC_IMPR_NAME, I.IMP_PORT_CD
                    FROM (SELECT DISTINCT '  ' || IMP.ARBC_IMPR_NAME ARBC_IMPR_NAME,
                                          IMP.PORT_CD IMP_PORT_CD,
                                          C.BUS_ID,
                                          C.BRNCH_BUS_ID,
                                          C.TYP,
                                          C.LIC_NBR,
                                          C.LIC_TYPE,
                                          C.BRKR_NAME,
                                          C.PORT_CD,
                                          C.NEW_ID_NBR
                            FROM IMPORTERS IMP,
                                 (SELECT DISTINCT B.TYP, B.LIC_NBR, B.LIC_TYPE, B.BRKR_NAME, B.PORT_CD, B.NEW_ID_NBR,
                                                  CIR.BUS_ID BUS_ID, CIR.BRNCH_BUS_ID BRNCH_BUS_ID
                                    FROM COMM_IMPR_RESPONSIBLES CIR,
                                         ((SELECT DISTINCT 1 TYP,
                                                           BKM.LIC_NBR LIC_NBR,
                                                           BKM.LIC_TYPE LIC_TYPE,
                                                           ' ' || BKM.BRKR_NAME BRKR_NAME,
                                                           BKM.PORT_CD,
                                                           BKM.NEW_ID_NBR
                                             FROM BRKR_MSTR BKM
                                            WHERE     (BKM.PORT_CD = v_p_curr_port_cd OR v_p_curr_port_cd IS NULL OR v_p_curr_port_cd = 99)
                                                  AND (BKM.LIC_TYPE = v_p_lic_type OR v_p_lic_type IS NULL))
                                          UNION ALL
                                          (SELECT DISTINCT 2, REP.REP_NBR, 0, ' ' || REP.REP_NAME, REP.PORT_CD, REP.NEW_ID_NBR
                                             FROM REPS REP
                                            WHERE     (REP.PORT_CD = v_p_curr_port_cd OR v_p_curr_port_cd IS NULL OR v_p_curr_port_cd = 99)
                                                  AND (v_p_lic_type = 4 OR v_p_lic_type IS NULL))) B
                                   WHERE CIR.RESPONSIBLE_ID_CARD LIKE B.NEW_ID_NBR) C
                           WHERE     IMP.BUS_ID = C.BUS_ID
                                 AND (   (IMP.BUS_ID_BRNCH LIKE C.BRNCH_BUS_ID)
                                      OR (    (LTRIM (RTRIM (IMP.BUS_ID_BRNCH)) IS NULL OR LTRIM (RTRIM (IMP.BUS_ID_BRNCH)) = '0')
                                          AND (C.BRNCH_BUS_ID IS NULL OR C.BRNCH_BUS_ID = 0)))
                                 AND NOT EXISTS
                                        (SELECT 'X'
                                           FROM IMPR_SUSPNS IS_1
                                          WHERE     IS_1.PORT_CD = IMP.PORT_CD
                                                AND IS_1.IMPR_NBR = IMP.IMPR_NBR
                                                AND IS_1.SUSPN_STRT_DT <= HIJDATE_DB.Cur_Hij_Date
                                                AND IS_1.SUSPN_END_DT >= HIJDATE_DB.Cur_Hij_Date
                                                AND IS_1.SUSPN_RLSE_DT IS NULL)) I
                   ORDER BY I.TYP, I.LIC_NBR, I.LIC_TYPE, I.BRKR_NAME, I.PORT_CD, I.NEW_ID_NBR,
                            I.BUS_ID, I.BRNCH_BUS_ID, I.ARBC_IMPR_NAME, I.IMP_PORT_CD)
        LOOP
            -- R_1 (G_TYP)
            IF v_prev_typ IS NULL OR v_prev_typ <> q.TYP THEN
                IF v_prev_typ IS NOT NULL THEN
                    dbms_lob.append (retVal, '</tbody></table><table class="grp" dir="rtl"><tbody><tr><td>'
                                             || LABEL_VALUE ('إجمالي العدد  :', v_cs_3) || '</td></tr></tbody></table>');
                END IF;
                v_prev_typ := q.TYP;
                v_prev_broker_key := NULL;
                v_prev_bus_key := NULL;
                v_cs_3 := 0;
                -- M_1 (B_LIC_NBR1 / B_LIC_NBR2 بالـ TYP)
                dbms_lob.append (retVal, '
              <table class="data" dir="rtl" style="margin-top:8px;"><thead><tr>
                <th style="width:7%;">' || CASE WHEN q.TYP = 1 THEN 'رقم رخصه المخلص' ELSE 'رقم بطاقة المعقب' END || '</th>
                <th style="width:8%;">نوع الرخصه</th><th style="width:22%;">الأسم</th><th style="width:5%;">رمز الجمرك</th>
                <th style="width:9%;">رقم الهوية</th><th style="width:10%;">رقم السجل التجاري الرئيسي</th>
                <th style="width:10%;">رقم السجل التجاري الفرعي</th><th style="width:24%;">اسم المستورد</th>
                <th style="width:5%;">رمز الجمرك</th>
              </tr></thead><tbody>');
            END IF;

            -- R_2 (CG$G_BRKR_MSTR)
            v_broker_key := q.LIC_NBR || '|' || q.LIC_TYPE || '|' || q.BRKR_NAME || '|' || q.PORT_CD || '|' || q.NEW_ID_NBR;
            IF v_prev_broker_key IS NULL OR v_prev_broker_key <> v_broker_key THEN
                v_prev_broker_key := v_broker_key;
                v_prev_bus_key := NULL;
                v_cs_3 := v_cs_3 + 1;
                v_cs_2 := v_cs_2 + 1;
                dbms_lob.append (retVal, '<tr>' || HTML_CELL (q.LIC_NBR) || HTML_CELL (C_LIC_TYPEFormula (q.LIC_TYPE))
                                         || HTML_CELL (q.BRKR_NAME, 'text-align:right;') || HTML_CELL (q.PORT_CD) || HTML_CELL (q.NEW_ID_NBR));
            ELSE
                dbms_lob.append (retVal, '<tr><td></td><td></td><td></td><td></td><td></td>');
            END IF;

            -- R_3 (G_BUS_ID)
            v_bus_key := q.BUS_ID || '|' || q.BRNCH_BUS_ID;
            IF v_prev_bus_key IS NULL OR v_prev_bus_key <> v_bus_key THEN
                v_prev_bus_key := v_bus_key;
                dbms_lob.append (retVal, HTML_CELL (q.BUS_ID) || HTML_CELL (q.BRNCH_BUS_ID));
            ELSE
                dbms_lob.append (retVal, '<td></td><td></td>');
            END IF;

            -- R_4 (G_ARBC_IMPR_NAME)
            dbms_lob.append (retVal, HTML_CELL (q.ARBC_IMPR_NAME, 'text-align:right;') || HTML_CELL (q.IMP_PORT_CD) || '</tr>');
        END LOOP;

        IF v_prev_typ IS NOT NULL THEN
            dbms_lob.append (retVal, '</tbody></table><table class="grp" dir="rtl"><tbody><tr><td>'
                                     || LABEL_VALUE ('إجمالي العدد  :', v_cs_3) || '</td></tr><tr><td>'
                                     || LABEL_VALUE ('الإجمالي الكلي  :', v_cs_2) || '</td></tr></tbody></table>');
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
    END ARD_IMPR2180;
END IMPR2180_ARD;
/
SHOW ERRORS


CREATE OR REPLACE PUBLIC SYNONYM IMPR2180_ARD FOR LIB_APX_USR.IMPR2180_ARD;


GRANT EXECUTE ON LIB_APX_USR.IMPR2180_ARD TO LIB_USR;

GRANT EXECUTE ON LIB_APX_USR.IMPR2180_ARD TO SECURITY_DEFAULT;

GRANT EXECUTE ON LIB_APX_USR.IMPR2180_ARD TO SECURITY_PROD;

GRANT EXECUTE ON LIB_APX_USR.IMPR2180_ARD TO CUSTOMS;
