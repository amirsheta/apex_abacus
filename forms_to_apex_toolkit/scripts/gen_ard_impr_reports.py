# -*- coding: utf-8 -*-
"""
gen_ard_impr_reports.py - the IMPR Oracle Reports (forms/IMPR/reports/*.xml) as ARD packages <REPORT>_ARD.

Pattern : as plsql/IMPR2110/IMPR2110_ARD (user decision 2026-11-25, Forms_to_APEX standard 13-c) and the in-repo
          references plsql/Shared/DCLN3300_ARD / DCLN3100_ARD: ARD_<REPORT>(P_PARAMETER1..n) RETURN CLOB builds
          the report as HTML (ARD_LOGO.IMG logo, APEX_ESCAPE.HTML, @page counter), the ARD server makes the PDF.
          RDF formula columns / format triggers that the layout uses keep their RDF names and code (bind
          variables become parameters). Date parameters are text 'YYYY-MM-MI' (as DCLN3300_ARD).
          Lexical parameters (&CG$P_IMPR_NBR, &P_IMPR_NBR, &IMPR_NBR, &L_IMPR_NBR = :parameter.TRAN_SELECT of the
          form) become a list of numbers checked with a pattern, never concatenated into SQL (as IMPR2110_ARD).
Data    : each report is written below by hand from its RDF (data model, formulas, layout); the shared parts
          (spec, styles, header / footer, synonym, grants) come from the functions at the top.
Writes  : plsql/<FORM>/<REPORT>_ARD_spec.sql / <REPORT>_ARD_body.sql  (IMPR2141..2143 under plsql/IMPR2140, the form that calls them)
          IMPR2110_ARD was written before this script and is not generated here.

Usage (from forms_to_apex_toolkit):  python3 -I scripts/gen_ard_impr_reports.py [IMPR2120 ...]
"""
import os, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATE, DATE_DMY, VERSION = '2026-11-25', '25-11-2026', '001'
LIST_PATTERN = "    c_list_pattern   CONSTANT VARCHAR2 (60) := '^[0-9]+(,[0-9]+)*$';\n"
NUMBER_PATTERN = "    c_number_pattern CONSTANT VARCHAR2 (60) := '^[0-9]+$';\n"


def list_in(var='v_impr_list'):
    return ("(SELECT TO_NUMBER (REGEXP_SUBSTR (%s, '[^,]+', 1, LEVEL)) FROM DUAL\n"
            "                                    CONNECT BY REGEXP_SUBSTR (%s, '[^,]+', 1, LEVEL) IS NOT NULL)") % (var, var)


# ----------------------------------------------------------------------------- shared PL/SQL pieces
PORT_NAME_TRIGGER_DECL = "    FUNCTION V_PORT_NAME_SEC1FormatTrigger (P_CURR_PORT_CD NUMBER) RETURN VARCHAR2;\n"
PORT_NAME_TRIGGER = r"""
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
"""

HTML_HELPERS = r"""
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
"""


COUNTER = '   @bottom-center { content: "صفحة " counter(page) " من " counter(pages); direction: rtl; font-family: Somar; font-size: 10px; color: #0e0f50; }\n'


def style(size='A4 landscape', extra='', counter=True):
    return r"""        dbms_lob.append (retVal, '<head><style>
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
""" + extra + r"""@page {
   background: white;
   margin-top: 20px;
   margin-bottom: 40px;
   margin-left: 30px;
   margin-right: 30px;
   size: """ + size + r""";
""" + (COUNTER if counter else '') + r"""}
</style></head>');
"""


def standard_header(subtitle=None, footer=True):
    """thead (port name / logo / الرقم-التاريخ-المرفقات / title) + tfoot (report number, dates) + tbody open,
    as IMPR2110_ARD. subtitle: PL/SQL expression printed under the title (CF_TITLE of IMPR2310)."""
    sub = ''
    if subtitle:
        sub = ("\n      <p style=\"text-align:center;margin:2px;\"><span style=\"color:#0e0f50;font-size:12px;\">' || "
               "APEX_ESCAPE.HTML (" + subtitle + ") || '</span></p>")
    foot = ''
    if footer:
        foot = r"""
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
</tfoot>"""
    return r"""
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
      <p style="text-align:center;margin:2px;"><span style="color:#0e0f50;font-size:14px;font-weight:bold;">' || APEX_ESCAPE.HTML (v_p_module_name) || '</span></p>""" + sub + r"""
    </div></td>
  </tr>
</thead>""" + foot + r"""
<tbody>
  <tr>
    <td>');
"""


CLOSE_HTML = r"""
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
"""


def grants(name):
    return ("\n\nCREATE OR REPLACE PUBLIC SYNONYM %s_ARD FOR LIB_APX_USR.%s_ARD;\n\n\n"
            "GRANT EXECUTE ON LIB_APX_USR.%s_ARD TO LIB_USR;\n\n"
            "GRANT EXECUTE ON LIB_APX_USR.%s_ARD TO SECURITY_DEFAULT;\n\n"
            "GRANT EXECUTE ON LIB_APX_USR.%s_ARD TO SECURITY_PROD;\n\n"
            "GRANT EXECUTE ON LIB_APX_USR.%s_ARD TO CUSTOMS;\n") % ((name,) * 6)


def ard_signature(name, count, indent='    '):
    pad = ' ' * len('FUNCTION ARD_%s (' % name)
    lines = []
    for i in range(1, count + 1):
        lines.append('P_PARAMETER%-3d IN VARCHAR2 DEFAULT NULL' % i)
    return (indent + 'FUNCTION ARD_%s (' % name + (',\n' + indent + pad).join(lines) + ')\n'
            + indent + '    RETURN CLOB')


def spec(r):
    n = r['name']
    head = r"""-- =============================================================================
-- Package     : %(n)s_ARD   (report %(n)s.rdf "%(title)s" as an ARD report)
-- Source      : forms/IMPR/reports/%(file)s (Oracle Reports, data source %(query)s)
-- Pattern     : ARD reports (Forms_to_APEX standard 13-c, DEC-014 / DEC-024), as plsql/Shared/DCLN3300_ARD
--               and plsql/IMPR2110/IMPR2110_ARD: ARD_%(n)s returns the report as HTML, the ARD server (ardpdf)
--               turns it into PDF.
-- Called from : %(caller)s
-- Generated   : scripts/gen_ard_impr_reports.py (a change goes there, then re-run)
-- Author      : Claude Code      Created: %(date)s      Version: %(ver)s
-- Status      : NOT COMPILED. Depends on ARD_LOGO (static file LOGO1.jpg, DEC-034) and HIJDATE_DB%(deps)s.
-- =============================================================================
SET DEFINE OFF

CREATE OR REPLACE PACKAGE LIB_APX_USR.%(n)s_ARD
AS
   V_PKG_VERSION       VARCHAR2 (100) := 'VERSION NO. IS:' || '%(ver)s';
   V_PKG_VERSION_QC    VARCHAR2 (100) := 'VERSION NO. IS:' || '%(ver)s';
   V_PKG_VERSION_DEV   VARCHAR2 (100) := 'VERSION NO. IS:' || '%(ver)s';
   FUNCTION PKG_VERSION
      RETURN VARCHAR2;
   V_PACKAGE_NAME      VARCHAR2 (50) := '%(n)s_ARD';
   V_LAST_MODIFY_DT    VARCHAR2 (10) := '%(dmy)s';
   V_MODIFIED_BY       VARCHAR2 (50) := 'Claude Code';
   V_INFO              VARCHAR2 (500)
      :=    'PACKAGE NAME :  '
         || V_PACKAGE_NAME
         || CHR (10)
         || CHR (13)
         || V_PKG_VERSION
         || CHR (10)
         || CHR (13)
         || 'MODIFIED DATE : '
         || V_LAST_MODIFY_DT
         || CHR (10)
         || CHR (13)
         || 'MODIFIED BY : '
         || V_MODIFIED_BY;
""" % dict(n=n, title=r['title'], file=r['file'], query=r['query'], caller=r['caller'], date=DATE,
           ver=VERSION, dmy=DATE_DMY, deps=r.get('deps', ''))
    params = '    -- معاملات التقرير بنفس أسماء الـ RDF\n'
    for i, (rdf, text) in enumerate(r['params'], 1):
        params += '    --   P_PARAMETER%-3d %-18s %s\n' % (i, rdf, text)
    notes = ''.join('    -- ' + line + '\n' for line in r.get('notes', []))
    decls = '\n    -- الـ formula columns بتاعة الـ RDF بنفس الكود، بتتنادى من جوه الكويري أو اللوب زي الريفرنس\n' + r['decls']
    return (head + params + notes + decls + '\n' + ard_signature(n, len(r['params'])) + ';\nEND %s_ARD;\n/\nSHOW ERRORS\n' % n
            + grants(n))


def body(r):
    n = r['name']
    head = ('-- =============================================================================\n'
            '-- Package body: %s_ARD   (matches %s_ARD_spec.sql)   Version: %s\n' % (n, n, VERSION)
            + ''.join('-- ' + line + '\n' for line in r['layout'])
            + '-- =============================================================================\n'
              'SET DEFINE OFF\n\nCREATE OR REPLACE PACKAGE BODY LIB_APX_USR.%s_ARD\nAS\n' % n)
    consts = r.get('consts', '')
    text = (head + consts + r.get('globals', '') + "\n    FUNCTION PKG_VERSION RETURN VARCHAR2 IS\n    BEGIN\n"
            "        RETURN (V_PKG_VERSION);\n    END PKG_VERSION;\n" + HTML_HELPERS + r['formulas'] + '\n'
            + ard_signature(n, len(r['params'])) + '\n    IS\n        retVal                 CLOB;\n' + r['vars']
            + '    BEGIN\n        DBMS_LOB.createtemporary (retVal, TRUE);\n' + r['init']
            + style(r.get('size', 'A4 landscape'), r.get('css', ''), r.get('counter', True)) + r.get('header', standard_header())
            + r['data'] + CLOSE_HTML + '    END ARD_%s;\nEND %s_ARD;\n/\nSHOW ERRORS\n' % (n, n) + grants(n))
    return text


# ============================================================================= IMPR2120
IMPR2120 = dict(
    name='IMPR2120', folder='IMPR2120', file='IMPR2120.xml', query='CG$Q_IMPR_SUSPNS',
    title='توقيفات المستوردين',
    caller='page 2120 through IMPR2120.PRINT_IMPR2120_ARD (ardpdf link; plsql/IMPR2120/impr2120_body.sql).',
    params=[('P_CURR_PORT_CD', 'الجمرك (P_PORT_CD في الشاشة، وإلا جمرك المستخدم)'),
            ('CG$P_IMPR_NBR', 'أرقام المستوردين مفصولة بفاصلة (فاضي = كل المستوردين)'),
            ('P_TYPE', 'حالة التوقيف 1 / 2 / 3 (P_TYPE في الشاشة)'),
            ('P_MODULE_NAME', 'عنوان التقرير'),
            ('P_REPORT_NO', 'رقم التقرير')],
    notes=['الفلتر: &CG$P_IMPR_NBR في الـ RDF هو :parameter.TRAN_SELECT في الفورم (" AND IMP.IMPR_NBR in (LICE_NO)")،',
           'هنا القايمة بتتقرا أرقام (من غير lexical) زي IMPR2110_ARD.',
           'TITFormula و C_CODEFormula مش ظاهرين في الـ layout فمش منقولين.'],
    decls=("    FUNCTION C_PORT_CDFormula (P_PORT_CD NUMBER) RETURN VARCHAR2;\n"
           "    FUNCTION C_DATEFormula RETURN DATE;\n"
           "    FUNCTION V_MEANFormula (P_SUSPN_RLSE_DT DATE, P_SUSPN_STRT_DT DATE, P_SUSPN_END_DT DATE) RETURN VARCHAR2;\n"
           + PORT_NAME_TRIGGER_DECL),
    layout=['Layout of IMPR2120.rdf (Landscape, right to left):',
            '  margin : port name, logo, الرقم / التاريخ / المرفقات, title P_MODULE_NAME, footer report number + dates + page',
            '  M_CG$G_IMPR_SUSPNS_GRPFR (printed only when there are rows): one header row, then',
            '  R_1 (G_C_PORT_CD, per importer): جهة التوقيف, مسلسل المستورد, الرقم الاستدلالى, رقم الفرع, اسم المستورد',
            '  next to R_CG$G_IMPR_SUSPNS (per suspension): بداية / نهاية التوقيف, حالة التوقيف, تاريخ الحذف, السبب.',
            '  The importer cells print on the first suspension line of the importer (as the RDF frames).'],
    consts=LIST_PATTERN,
    formulas=r"""
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
""" + PORT_NAME_TRIGGER,
    vars=r"""        v_p_curr_port_cd       NUMBER := TO_NUMBER (P_PARAMETER1);
        v_impr_list            VARCHAR2 (4000) := RTRIM (REGEXP_REPLACE (P_PARAMETER2, '\s', ''), ',');
        v_p_type               NUMBER := TO_NUMBER (P_PARAMETER3);
        v_p_module_name        VARCHAR2 (4000) := P_PARAMETER4;
        v_p_report_no          VARCHAR2 (4000) := P_PARAMETER5;
        v_c_date               DATE;             -- C_DATE
        v_port_name            VARCHAR2 (100);   -- V_PORT_NAME_SEC1
        v_key                  VARCHAR2 (4000);
        v_prev_key             VARCHAR2 (4000);  -- G_C_PORT_CD اللي فات (break)
        v_rows                 NUMBER := 0;
""",
    init=r"""
        v_c_date := C_DATEFormula;
        v_port_name := V_PORT_NAME_SEC1FormatTrigger (v_p_curr_port_cd);
""",
    data=r"""
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
                                  OR IMP.IMPR_NBR IN """ + list_in() + r""")
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
""")

# ============================================================================= IMPR2130
IMPR2130_FIELDS = [   # (label, value expression): right column then left column of R_CG$G_DET_G
    ("تاريخ اضافة السجل :", "TO_CHAR (q.ACT_DT, 'DD-MM-YYYY')", "المستخدم :", "q.USR_ID"),
    ("نوع النشاط :", "q.ACT_TYPEM", "اسم المستخدم :", "q.L_USR_USR_ANAME"),
    ("مدينة إصدار الحفيظه :", "q.ADD_CITY_ARB_NAME", "تاريخ انتهاء سجل المستورد :", "TO_CHAR (q.BUS_ID_EXPRD_DT, 'MI-MM-YYYY')"),
    ("اسم المستورد :", "q.ARBC_IMPR_NAME", "البريد الإلكتروني للمستورد :", "q.EMAIL"),
    ("الرقم الاستدلالى للمستورد :", "q.BUS_ID", "اسم الوكيل المفوض :", "q.IMPR_CNTCT_NAME"),
    ("رقم الفرع للمستورد :", "q.BUS_ID_BRNCH", "رقم الفاكس :", "q.IMPR_FAX_NBR"),
    ("مسمي نوع المستورد :", "q.BUS_ID_TYPE_NAME", "صندوق البريد :", "q.IMPR_POB_NBR"),
    ("الاسم الأجنبى للمستورد :", "q.ENG_IMPR_NAME", "تلكس :", "q.IMPR_TELEX_NBR"),
    ("الرقم الموحد :", "q.HQ_IMPR_NBR", "رقم تليفون المستورد :", "q.IMPR_TEL_NBR"),
    ("رمز مدينة إصدار الحفيظه :", "q.ID_CITY_ARB_NAME", "الرمز البريدى :", "q.IMPR_ZIP_CD"),
    ("نوع العمليه :", "q.IMPR_EXPR_TYPEM", "تابع لي :", "q.PARENT_IMPR_NAME"),
    ("نوع المستورد :", "q.IMPR_TYPE_NAME", None, None),
]


def impr2130_rows():
    out = []
    for l1, v1, l2, v2 in IMPR2130_FIELDS:
        right = "'<tr><td class=\"lbl\" style=\"width:18%%;\">%s</td>' || HTML_CELL (%s, 'width:32%%;')" % (l1, v1)
        if l2:
            left = " || '<td class=\"lbl\" style=\"width:18%%;\">%s</td>' || HTML_CELL (%s, 'width:32%%;') || '</tr>'" % (l2, v2)
        else:
            left = " || '<td></td><td></td></tr>'"
        out.append('                dbms_lob.append (retVal, ' + right + left + ');')
    return '\n'.join(out) + '\n'


IMPR2130 = dict(
    name='IMPR2130', folder='IMPR2130', file='IMPR2130.xml', query='IMPR_UPDTS',
    title='تعديلات بيانات المستوردين',
    caller='page 2130 through IMPR2130.PRINT_IMPR2130_ARD (ardpdf link; plsql/IMPR2130/impr2130_body.sql).',
    params=[('P_CURR_PORT_CD', 'الجمرك (P_PORT_CD في الشاشة، وإلا جمرك المستخدم)'),
            ('P_IMPR_NBR', 'أرقام المستوردين مفصولة بفاصلة (فاضي = كل المستوردين)'),
            ('START_DT', "من تاريخ 'YYYY-MM-MI' (الفورم مش بيبعته)"),
            ('END_DT', "إلى تاريخ 'YYYY-MM-MI' (الفورم مش بيبعته)"),
            ('P_MODULE_NAME', 'عنوان التقرير'),
            ('P_REPORT_NO', 'رقم التقرير')],
    notes=['الفلتر: &P_IMPR_NBR في الـ RDF هو :parameter.TRAN_SELECT في الفورم (" AND IU.IMPR_NBR in (LICE_NO)")، هنا',
           'القايمة بتتقرا أرقام. CHECK_VAL بيبعت P_IMPR_NBR و PRINT_CHECK_VAL بيبعت CG$P_impr_nbr (مش موجود في الـ RDF',
           'فالطباعة كانت بتطلع كل المستوردين)؛ هنا الاتنين بقايمة الشاشة.'],
    decls=PORT_NAME_TRIGGER_DECL,
    layout=['Layout of IMPR2130.rdf (Landscape, right to left):',
            '  margin : port name, logo, الرقم / التاريخ / المرفقات, title P_MODULE_NAME, footer report number + dates + page',
            '  R_CG$G_MAS_G (per importer IMPR_NBR): "رقم المستورد :"',
            '  R_CG$G_DET_G (per update record): two columns of label : value (12 right, 11 left), labels without the',
            '  kashida stretching of the RDF. Frames print only when there are rows.'],
    consts=LIST_PATTERN,
    formulas=PORT_NAME_TRIGGER,
    vars=r"""        v_p_curr_port_cd       NUMBER := TO_NUMBER (P_PARAMETER1);
        v_impr_list            VARCHAR2 (4000) := RTRIM (REGEXP_REPLACE (P_PARAMETER2, '\s', ''), ',');
        v_start_dt             DATE := TO_DATE (P_PARAMETER3, 'YYYY-MM-MI');
        v_end_dt               DATE := TO_DATE (P_PARAMETER4, 'YYYY-MM-MI');
        v_p_module_name        VARCHAR2 (4000) := P_PARAMETER5;
        v_p_report_no          VARCHAR2 (4000) := P_PARAMETER6;
        v_port_name            VARCHAR2 (100);   -- V_PORT_NAME_SEC1
        v_prev_key             VARCHAR2 (4000);  -- CG$G_MAS_G اللي فات (break)
""",
    init=r"""
        v_port_name := V_PORT_NAME_SEC1FormatTrigger (v_p_curr_port_cd);
""",
    data=r"""
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
                                  OR IU.IMPR_NBR IN """ + list_in() + r""")
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
""" + impr2130_rows() + r"""                dbms_lob.append (retVal, '</tbody></table>');
            END LOOP;
        END IF;
""",
    css='.data td.lbl{ color:#0e0f50; text-align:right; }\n')


# ============================================================================= IMPR2141 / 2142 / 2143 (letters)
def letter_header(department):
    return r"""
        -- كل صفحة: اسم الجمرك و""" + department + r""" يمين، اللوجو في النص، الرقم / التاريخ / المرفقات شمال
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
              <p style="margin:2px;"><span style="color:#0e0f50;font-size:12px;">""" + department + r"""</span></p>
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
"""


LETTER_CSS = ('.letter{ font-size:14px; line-height:2.1; color:#000000; padding:0 20px; }\n'
              '.letter p{ margin:0; }\n.letter .sign{ text-align:center; width:45%; margin-right:55%; }\n'
              '.letter .fld{ font-weight:bold; }\n')


def letter_report(name, query_sql, letter_html, formulas, decls, department, notes, title, port_filter_note):
    return dict(
        name=name, folder='IMPR2140', file=(name if name == 'IMPR2141' else name.lower()) + '.xml', query='CG$Q_SMPL_ITEMS',
        title=title, size='A4 portrait', css=LETTER_CSS, counter=False,
        caller=('page 2140 through IMPR2140.PRINT_%s_ARD (ardpdf link; plsql/IMPR2140/impr2140_body.sql). IMPR2140 picks '
                'the letter: LETTER_DIRCTION 1 = IMPR2141, 2 = IMPR2142, else IMPR2143.') % name,
        params=[('P_CURR_PORT_CD', 'الجمرك (P_PORT_CD في الشاشة، وإلا جمرك المستخدم)'),
                ('IMPR_NO', 'رقم المستورد (إجباري في الشاشة)')],
        notes=notes,
        decls=decls + PORT_NAME_TRIGGER_DECL,
        layout=['Layout of %s.rdf (Portrait, right to left): a letter per importer (R_1), one page each.' % name,
                '  margin : port name + "%s" (right), logo, الرقم / التاريخ / المرفقات (left)' % department,
                '  R_1    : the letter text of the RDF boilerplate with the importer fields.',
                '  ' + port_filter_note],
        consts=NUMBER_PATTERN,
        formulas=formulas + PORT_NAME_TRIGGER,
        vars=r"""        v_p_curr_port_cd       NUMBER := TO_NUMBER (P_PARAMETER1);
        v_impr_no              VARCHAR2 (4000) := TRIM (P_PARAMETER2);
        v_port_name            VARCHAR2 (100);   -- V_PORT_NAME_SEC1
        v_port_manager         VARCHAR2 (200);   -- CF_PORT_MANGER
        v_rows                 NUMBER := 0;
""",
        init=r"""
        v_port_name := V_PORT_NAME_SEC1FormatTrigger (v_p_curr_port_cd);
""" + ("        v_port_manager := CF_PORT_MANGERFormula (v_p_curr_port_cd);\n" if 'CF_PORT_MANGER' in formulas else ''),
        header=letter_header(department),
        data=r"""
        -- IMPR_NO لازم يكون رقم (الشاشة بتتأكد)، وإلا من غير خطابات
        IF v_impr_no IS NULL OR REGEXP_LIKE (v_impr_no, c_number_pattern) THEN
            FOR q IN (""" + query_sql + r""")
            LOOP
                v_rows := v_rows + 1;
                -- R_1: خطاب لكل مستورد في صفحة لوحده
                dbms_lob.append (retVal, '<div class="letter"' || CASE WHEN v_rows > 1 THEN ' style="page-break-before:always;"' END || '>');
""" + letter_html + r"""                dbms_lob.append (retVal, '</div>');
            END LOOP;
        END IF;
""")


LETTER_ADDRESS = r"""                dbms_lob.append (retVal, '
              <p>السـادة / <span class="fld">' || APEX_ESCAPE.HTML (q.IMPR_NAME) || '</span>&nbsp;&nbsp;&nbsp; المحترمين</p>
              <p>رقم المالك / <span class="fld">' || APEX_ESCAPE.HTML (q.IMPR_NBR) || '</span></p>
              <p>ص . ب ( <span class="fld">' || APEX_ESCAPE.HTML (q.IMPR_POB_NBR) || '</span> ) &nbsp;&nbsp;&nbsp; الرمــز البـريـدي ( <span class="fld">' || APEX_ESCAPE.HTML (q.IMPR_ZIP_CD) || '</span> )</p>
              <p>الـسـلام عـلـيـكـم ورحـمـة الله وبـركـاتـه ... &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; وبعد:-</p>');
"""

CF_PORT_MANGER_DECL = "    FUNCTION CF_PORT_MANGERFormula (P_CURR_PORT_CD NUMBER) RETURN VARCHAR2;\n"
CF_PORT_MANGER = r"""
    -- CF_PORT_MANGERFormula من الـ RDF@@NOTE@@
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
"""

IMPR2141 = letter_report(
    'IMPR2141',
    r"""SELECT IMP.IMPR_NBR       IMPR_NBR,
                             IMP.ARBC_IMPR_NAME IMPR_NAME,
                             IMP.IMPR_POB_NBR   IMPR_POB_NBR,
                             IMP.IMPR_ZIP_CD    IMPR_ZIP_CD,
                             SDP.PORT_NAME      PORT_NAME
                        FROM IMPORTERS IMP, SD_PORTS SDP
                       WHERE     SDP.PORT_CD = IMP.PORT_CD
                             AND (IMP.IMPR_NBR = v_impr_no OR v_impr_no IS NULL)
                             AND SDP.PORT_CD = v_p_curr_port_cd
                       ORDER BY IMP.IMPR_NBR""",
    r"""                dbms_lob.append (retVal, '
              <p>صورة مع التحية لسعادة مدير عام الإدارة العامة لمراجعة الإيرادات بديوان المراقبة العامة &nbsp;&nbsp;&nbsp; المحترم</p>
              <p>رمزا لخطابكم رقم &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; وتاريخ &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; هــ</p>
              <p>صورة مع التحية لسعادة مدير عام إدارة التدقيق العام بمصلحة الجمارك &nbsp;&nbsp;&nbsp; المحترم</p>');
""" + LETTER_ADDRESS + r"""                dbms_lob.append (retVal, '
              <p>تـلقـينا خـطـاب سعادة مدير عام الإدارة العامة لمراقبة الإيرادات بديوان المراقبـة العـامـة المتضمن</p>
              <p>وجود فروقات مالية عليكم على البيان الإستيراد رقم &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; وتاريخ &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; هــ</p>
              <p>نأمل منكم مراجعة قسم التدقيق والفروقات بـ <span class="fld">' || APEX_ESCAPE.HTML (q.PORT_NAME) || '</span> في مدة أقصاها عشرة
                 أيام من تاريخه لسـداد الفروقـات المترتبة عليـكم وفي حالة عدم مراجعتـكم سيتم إيقـاف سجلكم في الحاسب الآلي لحيــن المراجعة والتسديد.</p>
              <p style="text-align:center;">وتـقـبلـوا تحياتـا,،،،،</p>
              <p class="sign">مدير عام <span class="fld">' || APEX_ESCAPE.HTML (q.PORT_NAME) || '</span></p>
              <p class="sign"><span class="fld">' || APEX_ESCAPE.HTML (v_port_manager) || '</span></p>');
""",
    CF_PORT_MANGER.replace('@@NOTE@@', ' بالحرف'), CF_PORT_MANGER_DECL, 'التدقيق والفروقات',
    ['IMPR_NO: رقم مستورد واحد (IMP.IMPR_NBR = :IMPR_NO). V_PORT_CDFormula و V_NAMEFormula مش ظاهرين في الـ layout.',
     'الـ RDF من غير letterhead (ورق مطبوع)؛ هنا اللوجو زي باقي تقارير ARD.'],
    'خطاب للمستورد (الإدارة العامة لمراجعة الإيرادات)',
    'Query: as the RDF (port of the importer = P_CURR_PORT_CD).')

IMPR2142 = letter_report(
    'IMPR2142',
    r"""SELECT IMP.IMPR_NBR       IMPR_NBR,
                             IMP.IMPR_POB_NBR   IMPR_POB_NBR,
                             IMP.IMPR_ZIP_CD    IMPR_ZIP_CD,
                             IMP.ARBC_IMPR_NAME IMPR_NAME,
                             SDP.PORT_NAME      PORT_NAME
                        FROM IMPORTERS IMP, SD_PORTS SDP
                       WHERE     (IMP.IMPR_NBR = v_impr_no OR v_impr_no IS NULL)
                             -- الـ RDF من غير ربط IMP بـ SDP (خطاب لكل مستورد بنفس الرقم في كل الجمارك)؛ الربط زي IMPR2141 / 2143
                             AND SDP.PORT_CD = IMP.PORT_CD
                             AND (SDP.PORT_CD = v_p_curr_port_cd OR v_p_curr_port_cd IS NULL)
                       ORDER BY IMP.IMPR_NBR""",
    r"""                dbms_lob.append (retVal, '
              <p>صورة مع التحية لسعادة مدير عام إدارة التدقيق العام بمصلحة الجمارك &nbsp;&nbsp;&nbsp; المحترم</p>');
""" + LETTER_ADDRESS + r"""                dbms_lob.append (retVal, '
              <p>تـلـقـينا خـطـاب سعـادة مديـر عام إدارة التدقيـق بمصلحة الجمـارك المتضمن وجـود فروقـات مالية عليكم.</p>
              <p>نأمل منكم مراجعة قسم التدقيق والفروقات بـ <span class="fld">' || APEX_ESCAPE.HTML (q.PORT_NAME) || '</span> في مدة أقصاها
                 عشـرة أيـام من تاريخه لسـداد الفروقـات المترتبة عليـكم وفي حالـة عدم مراجعتـكم سيتـــم إيقـاف سجلكم في الحـاسب الآلي لحيــن المراجعة والتسديد.</p>
              <p style="text-align:center;">وتـقبلوا تحياتي,،،،،</p>
              <p class="sign">مدير عام <span class="fld">' || APEX_ESCAPE.HTML (q.PORT_NAME) || '</span></p>
              <p class="sign"><span class="fld">' || APEX_ESCAPE.HTML (v_port_manager) || '</span></p>');
""",
    CF_PORT_MANGER.replace('@@NOTE@@', ' (الـ RDF من غير PORT_CD: لو الإعداد في أكتر من جمرك TOO_MANY_ROWS\n'
                                         '    -- والتقرير بيقف؛ هنا PORT_CD = P_CURR_PORT_CD زي IMPR2141 / 2143)'),
    CF_PORT_MANGER_DECL, 'التدقيق والفروقات',
    ['IMPR_NO: رقم مستورد واحد. اختلاف مقصود عن الـ RDF: ربط IMP.PORT_CD = SDP.PORT_CD في الكويري و PORT_CD في',
     'CF_PORT_MANGERFormula (الـ RDF من غيرهم، زي IMPR2141 / 2143). V_PORT_CDFormula مش ظاهر في الـ layout.'],
    'خطاب للمستورد (إدارة التدقيق العام)',
    'Query: RDF plus the join IMP.PORT_CD = SDP.PORT_CD (the RDF has none, see the spec).')

IMPR2143 = letter_report(
    'IMPR2143',
    r"""SELECT IMP.IMPR_POB_NBR   IMPR_POB_NBR,
                             IMP.IMPR_NBR       IMPR_NBR,
                             IMP.IMPR_ZIP_CD    IMPR_ZIP_CD,
                             IMP.ARBC_IMPR_NAME IMPR_NAME,
                             SDP.PORT_NAME      PORT_NAME
                        FROM IMPORTERS IMP, SD_PORTS SDP
                       WHERE     (IMP.IMPR_NBR = v_impr_no OR v_impr_no IS NULL)
                             AND IMP.PORT_CD = SDP.PORT_CD
                             AND (SDP.PORT_CD = v_p_curr_port_cd OR v_p_curr_port_cd IS NULL)
                       ORDER BY IMP.IMPR_NBR""",
    r"""                dbms_lob.append (retVal, '
              <p>صورة مع التحية لسعادة مدير عام <span class="fld">' || APEX_ESCAPE.HTML (q.PORT_NAME) || '</span> &nbsp;&nbsp;&nbsp; المحترم</p>');
""" + LETTER_ADDRESS + r"""                dbms_lob.append (retVal, '
              <p>نظراً لوجود بعض الفروقات المالية المترتبة عليكم.</p>
              <p>لذا نأمل منكم مراجعة قسم التدقيق والفروقات بـ <span class="fld">' || APEX_ESCAPE.HTML (q.PORT_NAME) || '</span> في مدة أقصاها
                 عشرة أيـام من تاريـخه لسـداد الفـروقـات المترتبـة عليـكم وفي حالة عـدم مراجعتـكم سيتم إيقــاف سجلكم في الحـاسب الآلي لحيــن المراجعة والتسديد.</p>
              <p style="text-align:center;">وتـقبلوا تحياتي,،،،،</p>
              <p class="sign">رئيس قسم التدقيق والفروقات</p>');
""",
    '', '', 'التدقيق والفروقات',
    ['IMPR_NO: رقم مستورد واحد. CF_PORT_MANGERFormula و V_PORT_CDFormula مش ظاهرين في الـ layout.'],
    'خطاب للمستورد (رئيس قسم التدقيق والفروقات)',
    'Query: as the RDF.')

# ============================================================================= IMPR2150
RULE_FORMULAS_DECL = ("    FUNCTION CF_REC_STATUSFormula (P_REC_STATUS NUMBER) RETURN VARCHAR2;\n"
                      "    FUNCTION CF_REC_STATUS2Formula (P_REC_STATUS NUMBER) RETURN VARCHAR2;\n"
                      "    FUNCTION CF_RUL_TYPEFormula (P_RULE_TYPE NUMBER) RETURN VARCHAR2;\n"
                      "    FUNCTION CF_BUS_TYPE_IDFormula (P_BUS_ID_TYPE_CD NUMBER) RETURN VARCHAR2;\n"
                      "    FUNCTION CF_ALL_BRANCHESFormula (P_ALL_BRNCH_FLAG NUMBER) RETURN VARCHAR2;\n"
                      "    FUNCTION CF_BRCH_LBLFormula (P_BUS_ID_BRNCH VARCHAR2) RETURN VARCHAR2;\n")


def rule_formulas(rule_type_rownum):
    return r"""
    -- CF_REC_STATUSFormula بالحرف من الـ RDF
    FUNCTION CF_REC_STATUSFormula (P_REC_STATUS NUMBER) RETURN VARCHAR2 IS
    	V_RV_MEANING CG_REF_CODES.RV_MEANING%TYPE;
    begin
      SELECT RV_MEANING INTO V_RV_MEANING
      FROM CG_REF_CODES
      WHERE RV_DOMAIN ='REC_STATUS'
      AND RV_LOW_VALUE =P_REC_STATUS;
      RETURN  V_RV_MEANING;
    EXCEPTION
    	WHEN OTHERS THEN RETURN NULL;
    end;

    -- CF_REC_STATUS2Formula بالحرف من الـ RDF
    FUNCTION CF_REC_STATUS2Formula (P_REC_STATUS NUMBER) RETURN VARCHAR2 IS
    	V_RV_MEANING CG_REF_CODES.RV_MEANING%TYPE;
    begin
      SELECT RV_MEANING INTO V_RV_MEANING
      FROM CG_REF_CODES
      WHERE RV_DOMAIN ='REC_STATUS'
      AND RV_LOW_VALUE =P_REC_STATUS;
      RETURN  V_RV_MEANING;
    EXCEPTION
    	WHEN OTHERS THEN RETURN NULL;
    end;

    -- CF_RUL_TYPEFormula بالحرف من الـ RDF
    FUNCTION CF_RUL_TYPEFormula (P_RULE_TYPE NUMBER) RETURN VARCHAR2 IS
    	V_RV_MEANING CG_REF_CODES.RV_MEANING%TYPE;
    begin
      SELECT RV_MEANING INTO V_RV_MEANING
      FROM CG_REF_CODES
      WHERE RV_DOMAIN ='RULE_TYPE'
      AND RV_LOW_VALUE =P_RULE_TYPE""" + ("\n      AND ROWNUM=1" if rule_type_rownum else '') + r""";
      RETURN  V_RV_MEANING;
    EXCEPTION
    	WHEN OTHERS THEN RETURN NULL;
    end;

    -- CF_BUS_TYPE_IDFormula بالحرف من الـ RDF
    FUNCTION CF_BUS_TYPE_IDFormula (P_BUS_ID_TYPE_CD NUMBER) RETURN VARCHAR2 IS
    	V_BUS_ID_TYPE_NAME	VARCHAR2(400);
    begin
    	SELECT BUS_ID_TYPE_NAME INTO V_BUS_ID_TYPE_NAME
    	FROM BUS_ID_TYPES
    	WHERE BUS_ID_TYPE_CD = P_BUS_ID_TYPE_CD;
    	RETURN V_BUS_ID_TYPE_NAME;
    EXCEPTION
    	WHEN OTHERS THEN RETURN NULL;
    end;

    -- CF_ALL_BRANCHESFormula بالحرف من الـ RDF
    FUNCTION CF_ALL_BRANCHESFormula (P_ALL_BRNCH_FLAG NUMBER) RETURN VARCHAR2 IS
    	V_RET VARCHAR2(50);
    begin
      IF P_ALL_BRNCH_FLAG = 1 THEN
      	V_RET :='جميع الفروع' ;
      ELSE
      	V_RET :='فرع محدد' ;
      END IF;
      RETURN V_RET;
    end;

    -- CF_BRCH_LBLFormula بالحرف من الـ RDF
    FUNCTION CF_BRCH_LBLFormula (P_BUS_ID_BRNCH VARCHAR2) RETURN VARCHAR2 IS
    begin
      IF P_BUS_ID_BRNCH IS NOT NULL THEN
      	RETURN 'فرع :';
      ELSE
      	RETURN '';
      END IF;
    end;
"""


IMPR2150 = dict(
    name='IMPR2150', folder='IMPR2150', file='IMPR2150.xml', query='IMPR_RULS',
    title='استثناءات المستوردين',
    caller='page 2150 through IMPR2150.PRINT_IMPR2150_ARD (ardpdf link; plsql/IMPR2150/impr2150_body.sql).',
    params=[('P_CURR_PORT_CD', 'جمرك المستخدم لاسم الجمرك في الهيدر (الفورم مكانش بيبعته فالـ RDF من غير اسم)'),
            ('P_HQ_IMPR_NBR', 'الرقم الموحد (فاضي = الكل)'),
            ('P_REC_STATUS', 'حالة السجل 1 / 0'),
            ('P_RULE_TYPE', 'نوع الاستثناء (فاضي = الكل)'),
            ('P_MODULE_NAME', 'عنوان التقرير'),
            ('P_REPORT_NO', 'رقم التقرير')],
    notes=['REC_STATUS في مجموعة الاستثناء هو IMPR_RULE_PORTS.REC_STATUS (زي الـ RDF)، و CF_REC_STATUS / CF_REC_STATUS2',
           'الاتنين بيقروه.'],
    decls=RULE_FORMULAS_DECL + PORT_NAME_TRIGGER_DECL,
    layout=['Layout of IMPR2150.rdf (Landscape, right to left):',
            '  margin : port name, logo, الرقم / التاريخ / المرفقات, title P_MODULE_NAME, footer report number + dates + page',
            '  R_2 (G_HQ_IMPR_NBR): الرقم الموحد للمستورد + الاسم / نوع الرقم الاستدلالي, الرقم الاستدلالي, الفرع',
            '  R_1 (per exception): header row + rows: مسلسل الإستثناء, حالة السجل, نوع الإستثناء, استخدام الإستثناء',
            '  (first port line) next to R_CG$G_AGNTS (per port): رمز الجمرك, اسم الجمرك, حالة السجل.'],
    formulas=rule_formulas(True) + PORT_NAME_TRIGGER,
    vars=r"""        v_p_curr_port_cd       NUMBER := TO_NUMBER (P_PARAMETER1);
        v_p_hq_impr_nbr        NUMBER := TO_NUMBER (P_PARAMETER2);
        v_p_rec_status         NUMBER := TO_NUMBER (P_PARAMETER3);
        v_p_rule_type          NUMBER := TO_NUMBER (P_PARAMETER4);
        v_p_module_name        VARCHAR2 (4000) := P_PARAMETER5;
        v_p_report_no          VARCHAR2 (4000) := P_PARAMETER6;
        v_port_name            VARCHAR2 (100);   -- V_PORT_NAME_SEC1
        v_hq_key               VARCHAR2 (4000);
        v_prev_hq_key          VARCHAR2 (4000);  -- G_HQ_IMPR_NBR اللي فات
        v_rule_key             VARCHAR2 (4000);
        v_prev_rule_key        VARCHAR2 (4000);  -- G_L_IMP_ARBC_IMPR_NAME اللي فات
""",
    init=r"""
        v_port_name := V_PORT_NAME_SEC1FormatTrigger (v_p_curr_port_cd);
""",
    data=r"""
        FOR q IN (SELECT IMPR_RULE_PORTS.PORT_CD,
                         IMPR_RULE_PORTS.REC_STATUS,
                         ' ' || SD_PORTS.PORT_NAME PORT_NAME,
                         IMPR_RULES.RULE_ISN,
                         IMPR_RULES.BUS_ID_TYPE_CD,
                         IMPR_RULES.BUS_ID,
                         IMPR_RULES.BUS_ID_BRNCH,
                         IMPR_RULES.ALL_BRNCH_FLAG,
                         IMPR_RULES.RULE_TYPE,
                         IMPR_RULES.HQ_IMPR_NBR,
                         SINGLE_IMPORTERS.ARBC_IMPR_NAME
                    FROM IMPR_RULES, IMPR_RULE_PORTS, SD_PORTS, SINGLE_IMPORTERS
                   WHERE     IMPR_RULE_PORTS.RULE_ISN = IMPR_RULES.RULE_ISN
                         AND IMPR_RULE_PORTS.PORT_CD = SD_PORTS.PORT_CD
                         AND (IMPR_RULES.RULE_TYPE = v_p_rule_type OR v_p_rule_type IS NULL)
                         AND IMPR_RULES.HQ_IMPR_NBR = SINGLE_IMPORTERS.HQ_IMPR_NBR
                         AND (IMPR_RULES.HQ_IMPR_NBR = v_p_hq_impr_nbr OR v_p_hq_impr_nbr IS NULL)
                         AND (   (v_p_rec_status = 1 AND IMPR_RULES.REC_STATUS = 1 AND IMPR_RULE_PORTS.REC_STATUS = 1)
                              OR (v_p_rec_status = 0 AND IMPR_RULES.REC_STATUS = 0))
                   ORDER BY IMPR_RULES.HQ_IMPR_NBR, SINGLE_IMPORTERS.ARBC_IMPR_NAME, IMPR_RULES.BUS_ID,
                            IMPR_RULES.BUS_ID_BRNCH, IMPR_RULES.BUS_ID_TYPE_CD, IMPR_RULES.RULE_ISN,
                            IMPR_RULES.RULE_TYPE, IMPR_RULES.ALL_BRNCH_FLAG, IMPR_RULE_PORTS.REC_STATUS,
                            IMPR_RULE_PORTS.PORT_CD)
        LOOP
            v_hq_key := q.HQ_IMPR_NBR || '|' || q.ARBC_IMPR_NAME || '|' || q.BUS_ID || '|' || q.BUS_ID_BRNCH || '|' || q.BUS_ID_TYPE_CD;
            v_rule_key := v_hq_key || '|' || q.RULE_ISN || '|' || q.RULE_TYPE || '|' || q.ALL_BRNCH_FLAG || '|' || q.REC_STATUS;

            IF v_prev_rule_key IS NOT NULL AND v_prev_rule_key <> v_rule_key THEN
                dbms_lob.append (retVal, '</tbody></table>');
            END IF;

            -- R_2 (G_HQ_IMPR_NBR)
            IF v_prev_hq_key IS NULL OR v_prev_hq_key <> v_hq_key THEN
                v_prev_hq_key := v_hq_key;
                dbms_lob.append (retVal, '
              <table class="grp" dir="rtl"><tbody>
                <tr><td colspan="3">' || LABEL_VALUE ('الرقم الموحد للمستورد :', q.HQ_IMPR_NBR) || '&nbsp;&nbsp;<span class="val">'
                                    || APEX_ESCAPE.HTML (q.ARBC_IMPR_NAME) || '</span></td></tr>
                <tr><td style="width:40%;">' || LABEL_VALUE ('نوع الرقم الاستدلالي :', CF_BUS_TYPE_IDFormula (q.BUS_ID_TYPE_CD)) || '</td>
                    <td style="width:35%;">' || LABEL_VALUE ('الرقم الاستدلالي :', q.BUS_ID) || '</td>
                    <td style="width:25%;">' || LABEL_VALUE (CF_BRCH_LBLFormula (q.BUS_ID_BRNCH), q.BUS_ID_BRNCH) || '</td></tr>
              </tbody></table>');
            END IF;

            -- R_1 (per exception): الهيدر وخانات الاستثناء في أول سطر
            IF v_prev_rule_key IS NULL OR v_prev_rule_key <> v_rule_key THEN
                v_prev_rule_key := v_rule_key;
                dbms_lob.append (retVal, '
              <table class="data" dir="rtl" style="margin-bottom:6px;"><thead><tr>
                <th style="width:10%;">مسلسل الإستثناء</th><th style="width:9%;">حالة السجل</th><th style="width:20%;">نــوع الإستثناء</th>
                <th style="width:12%;">استخدام الإستثناء</th><th style="width:9%;">رمز الجمرك</th><th style="width:28%;">اسم الجمرك</th>
                <th style="width:12%;">حالة السجل</th>
              </tr></thead><tbody>');
                dbms_lob.append (retVal, '<tr>' || HTML_CELL (q.RULE_ISN) || HTML_CELL (CF_REC_STATUSFormula (q.REC_STATUS))
                                         || HTML_CELL (CF_RUL_TYPEFormula (q.RULE_TYPE)) || HTML_CELL (CF_ALL_BRANCHESFormula (q.ALL_BRNCH_FLAG)));
            ELSE
                dbms_lob.append (retVal, '<tr><td></td><td></td><td></td><td></td>');
            END IF;

            -- R_CG$G_AGNTS
            dbms_lob.append (retVal, HTML_CELL (q.PORT_CD) || HTML_CELL (q.PORT_NAME, 'text-align:right;')
                                     || HTML_CELL (CF_REC_STATUS2Formula (q.REC_STATUS)) || '</tr>');
        END LOOP;

        IF v_prev_rule_key IS NOT NULL THEN
            dbms_lob.append (retVal, '</tbody></table>');
        END IF;
""")

# ============================================================================= IMPR2170
IMPR2170 = dict(
    name='IMPR2170', folder='IMPR2170', file='IMPR2170.xml', query='CG$Q_IMPR_SUSPNS, Q_2',
    title='تقرير حالة مستورد', deps=', IMPR_UTILITIES (get_main_szr_rsn / get_sub_szr_rsn)',
    caller=('page 2170 through IMPR2170.PRINT_IMPR2170_ARD (ardpdf link; plsql/IMPR2170/impr2170_body.sql). SHOW_USER = 1 '
            'ran IMPR2170n.rep, which is not in forms/IMPR/reports (not converted).'),
    params=[('P_CURR_PORT_CD', 'جمرك المستخدم (فاضي = 99 زي BeforeReport)'),
            ('PPORT_CD', 'جمرك المستورد (P_PORT_CD في الشاشة)'),
            ('PSELECT1', '1 = مستورد في جمرك، 2 = الرقم الموحد'),
            ('PIMPR_NBR', 'رقم المستورد (PSELECT1 = 1)'),
            ('PHQ_IMPR_NBR', 'الرقم الموحد (PSELECT1 = 2)'),
            ('P_MODULE_NAME', 'عنوان التقرير'),
            ('P_REPORT_NO', 'رقم التقرير')],
    notes=['BeforeReport بالحرف: P_BUS_ID من IMPORTERS بالمستورد أو الرقم الموحد (ROWNUM <= 1)؛ لو مفيش -> من غير سطور.',
           'TITFormula و CF_1Formula مش ظاهرين في الـ layout. المسلسل # (CS_1) بيتعد في كل جدول (G_PORT_F0).'],
    decls=("    FUNCTION CF_CURR_DTFormula RETURN DATE;\n"
           "    FUNCTION CF_X1Formula (P_PORT_CD_F1 NUMBER) RETURN VARCHAR2;\n"
           "    FUNCTION CF_IMPR_NBR_XFormula (P_IMPR_NBR_F1 NUMBER) RETURN VARCHAR2;\n"
           "    FUNCTION impr_name_dumFormula (P_PORT_F0 NUMBER, P_BUS_ID VARCHAR2, P_PORT_CD_F1 NUMBER, P_IMPR_NBR_F1 NUMBER) RETURN VARCHAR2;\n"
           + PORT_NAME_TRIGGER_DECL),
    layout=['Layout of IMPR2170.rdf (Landscape, right to left, 2024 design):',
            '  margin : title P_MODULE_NAME and port name (V_PORT_NAME_SEC1 on PPORT_CD) right, logo left,',
            '           رقم التقرير + التاريخ (Hijri / Gregorian) line; footer the address line and the page counter',
            '  R_CG$G_MZS_G2 (Q_2, G_X0_IMPR_NAME): اسم المستورد, الرقم الاستدلالى, الرقم الفرعي',
            '  R_2 (G_PORT_F0): header row per group (M_HEADER) + R_1 rows: #, مستوى الإيقاف, رقم المستورد, الرقم',
            '  الاستدلالي الرئيسي, الرقم الفرعي, اسم المستورد, الحالة, الإدارة. PORT_F0 = 0 (format triggers): no',
            '  رقم المستورد column, مستوى الإيقاف takes its place (colspan 2).'],
    formulas=r"""
    -- CF_CURR_DTFormula من الـ RDF (HIJDATE -> HIJDATE_DB)
    FUNCTION CF_CURR_DTFormula RETURN DATE IS
    begin
      RETURN(HIJDATE_DB.Cur_Hij_Date);
    end;

    -- CF_X1Formula بالحرف من الـ RDF
    FUNCTION CF_X1Formula (P_PORT_CD_F1 NUMBER) RETURN VARCHAR2 IS
    X_PORT_NAME VARCHAR2(100);
    begin
      SELECT PORT_NAME
      INTO   X_PORT_NAME
      FROM   SD_PORTS
      WHERE  PORT_CD = P_PORT_CD_F1 ;
        RETURN X_PORT_NAME;
    EXCEPTION
    	WHEN NO_DATA_FOUND THEN
    	RETURN 'جميع الجمارك';
    end;

    -- CF_IMPR_NBR_XFormula بالحرف من الـ RDF
    FUNCTION CF_IMPR_NBR_XFormula (P_IMPR_NBR_F1 NUMBER) RETURN VARCHAR2 IS
    BEGIN
    	IF P_IMPR_NBR_F1 IS NULL OR P_IMPR_NBR_F1 = 0
    		THEN RETURN(' ');
    	ELSE RETURN(P_IMPR_NBR_F1);
    	END IF;
    END;

    -- impr_name_dumFormula بالحرف من الـ RDF
    FUNCTION impr_name_dumFormula (P_PORT_F0 NUMBER, P_BUS_ID VARCHAR2, P_PORT_CD_F1 NUMBER, P_IMPR_NBR_F1 NUMBER) RETURN VARCHAR2 IS
    dummy varchar2(150);
    begin
    	IF P_PORT_F0 = 0 THEN
      	select ARBC_IMPR_NAME into dummy from importers where BUS_ID=P_BUS_ID AND ROWNUM<=1 AND ARBC_IMPR_NAME IS NOT NULL;
    	ELSE
      	select ARBC_IMPR_NAME into dummy
      	from importers
      	where PORT_CD = P_PORT_CD_F1 AND IMPR_NBR = P_IMPR_NBR_F1;
    	END IF;
      RETURN DUMMY;
    EXCEPTION WHEN OTHERS THEN
    	RETURN NULL;
    end;
""" + PORT_NAME_TRIGGER,
    vars=r"""        v_p_curr_port_cd       NUMBER := TO_NUMBER (P_PARAMETER1);
        v_pport_cd             NUMBER := TO_NUMBER (P_PARAMETER2);
        v_pselect1             NUMBER := TO_NUMBER (P_PARAMETER3);
        v_pimpr_nbr            NUMBER := TO_NUMBER (P_PARAMETER4);
        v_phq_impr_nbr         NUMBER := TO_NUMBER (P_PARAMETER5);
        v_p_module_name        VARCHAR2 (4000) := P_PARAMETER6;
        v_p_report_no          VARCHAR2 (4000) := P_PARAMETER7;
        v_p_bus_id             VARCHAR2 (100);   -- P_BUS_ID (BeforeReport)
        v_cf_curr_dt           DATE;             -- CF_CURR_DT
        v_port_name            VARCHAR2 (100);   -- V_PORT_NAME_SEC1
        v_prev_port_f0         NUMBER;           -- G_PORT_F0 اللي فات
        v_count                NUMBER := 0;      -- CS_1
""",
    init=r"""
        -- BeforeReport
        BEGIN
            SELECT BUS_ID INTO v_p_bus_id
              FROM IMPORTERS
             WHERE ((IMPR_NBR = v_pimpr_nbr AND PORT_CD = v_pport_cd) OR HQ_IMPR_NBR = v_phq_impr_nbr) AND ROWNUM <= 1;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_p_bus_id := NULL;
        END;
        IF v_p_curr_port_cd IS NULL THEN v_p_curr_port_cd := 99; END IF;

        v_cf_curr_dt := CF_CURR_DTFormula;
        v_port_name := V_PORT_NAME_SEC1FormatTrigger (v_pport_cd);
""",
    header=r"""
        -- الهيدر في كل صفحة: العنوان واسم الجمرك يمين واللوجو شمال، وتحتهم رقم التقرير والتاريخ؛ الفوتر سطر العنوان
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
            <td style="width:60%;vertical-align:bottom;">
              <p style="margin:2px;"><span style="color:#0e0f50;font-size:12px;font-weight:bold;">' || APEX_ESCAPE.HTML (v_port_name) || '</span></p>
              <p style="margin:2px;"><span style="color:#0e0f50;font-size:14px;font-weight:bold;">' || APEX_ESCAPE.HTML (v_p_module_name) || '</span></p>
            </td>
            <td style="width:40%;text-align:left;">');
        dbms_lob.append (retVal, ARD_LOGO.IMG (85, 335, NULL, 'LOGO1.jpg'));   -- اللوجو Static File في الأبلكيشن (DEC-034)
        dbms_lob.append (retVal, '</td>
          </tr>
          <tr>
            <td style="font-size:11px;color:#0e0f50;">رقم التقرير: <span style="color:#707070;">' || APEX_ESCAPE.HTML (v_p_report_no) || '</span></td>
            <td style="font-size:11px;color:#0e0f50;">التاريــخ: <span style="color:#707070;">' || TO_CHAR (HIJDATE_DB.CUR_HIJ_DATE, 'MI-MM-YYYY') || '</span> هـ
               / <span style="color:#707070;">' || TO_CHAR (SYSDATE, 'DD-MM-YYYY') || '</span> م</td>
          </tr>
        </tbody>
      </table>
    </div></td>
  </tr>
</thead>
<tfoot>
  <tr>
    <td><div class="MRDFooter">
      <p style="margin:2px;font-size:10px;color:#0e0f50;">المملكة العربية السعودية | الهيئة العامة للجمارك | ص.ب 3483 الرياض 11197</p>
    </div></td>
  </tr>
</tfoot>
<tbody>
  <tr>
    <td>');
""",
    data=r"""
        -- R_CG$G_MZS_G2 (Q_2)
        FOR x IN (SELECT SI.ARBC_IMPR_NAME X0_IMPR_NAME,
                         HI.HQ_IMPR_NBR    X0_HQ_IMPR_NBR,
                         HI.BUS_ID         X0_BUS_ID,
                         HI.BUS_ID_BRNCH   X0_BUS_ID_BRNCH
                    FROM IMPORTERS IMP, HQ_IMPRS HI, SINGLE_IMPORTERS SI
                   WHERE     (   (v_pselect1 = 1 AND IMP.PORT_CD = v_pport_cd AND IMP.IMPR_NBR = v_pimpr_nbr)
                              OR (v_pselect1 = 2 AND IMP.HQ_IMPR_NBR = v_phq_impr_nbr))
                         AND HI.HQ_IMPR_NBR = IMP.HQ_IMPR_NBR
                         AND IMP.HQ_IMPR_NBR = SI.HQ_IMPR_NBR
                GROUP BY SI.ARBC_IMPR_NAME, HI.HQ_IMPR_NBR, HI.BUS_ID, HI.BUS_ID_BRNCH
                ORDER BY SI.ARBC_IMPR_NAME, HI.HQ_IMPR_NBR, HI.BUS_ID, HI.BUS_ID_BRNCH)
        LOOP
            dbms_lob.append (retVal, '
              <table class="grp" dir="rtl"><tbody><tr>
                <td style="width:50%;">' || LABEL_VALUE ('اسم المستورد:', x.X0_IMPR_NAME) || '</td>
                <td style="width:25%;">' || LABEL_VALUE ('الرقم الاستدلالى :', x.X0_BUS_ID) || '</td>
                <td style="width:25%;">' || LABEL_VALUE ('الرقم الفرعي:', x.X0_BUS_ID_BRNCH) || '</td>
              </tr></tbody></table>');
        END LOOP;

        -- M_ALL: CG$Q_IMPR_SUSPNS بالحرف (الـ bind variables بقت متغيرات)
        FOR q IN (""" + "@@IMPR2170_QUERY@@" + r""")
        LOOP
            -- R_2 (G_PORT_F0): M_HEADER لكل مجموعة
            IF v_prev_port_f0 IS NULL OR v_prev_port_f0 <> q.PORT_F0 THEN
                IF v_prev_port_f0 IS NOT NULL THEN
                    dbms_lob.append (retVal, '</tbody></table>');
                END IF;
                v_prev_port_f0 := q.PORT_F0;
                v_count := 0;
                dbms_lob.append (retVal, '
              <table class="data" dir="rtl" style="margin-top:8px;"><thead><tr>
                <th style="width:4%;">#</th>'
                    || CASE WHEN q.PORT_F0 = 0 THEN '<th colspan="2" style="width:23%;">مستوى الإيقاف</th>'
                            ELSE '<th style="width:15%;">مستوى الإيقاف</th><th style="width:8%;">رقم المستورد</th>' END
                    || '<th style="width:12%;">رقم الاستدلالي الرئيسي</th><th style="width:10%;">الرقم الفرعي</th>
                <th style="width:17%;">اسم المستورد</th><th style="width:25%;">الحالة</th><th style="width:9%;">الإدارة</th>
              </tr></thead><tbody>');
            END IF;

            -- R_1 (G_C_PORT_CD)
            v_count := v_count + 1;
            dbms_lob.append (retVal, '<tr>' || HTML_CELL (v_count)
                || CASE WHEN q.PORT_F0 = 0 THEN '<td colspan="2">' || APEX_ESCAPE.HTML (CF_X1Formula (q.PORT_CD_F1)) || '</td>'
                        ELSE HTML_CELL (CF_X1Formula (q.PORT_CD_F1)) || HTML_CELL (CF_IMPR_NBR_XFormula (q.IMPR_NBR_F1)) END
                || HTML_CELL (q.BUS_ID) || HTML_CELL (q.BUS_ID_BRNCH)
                || HTML_CELL (impr_name_dumFormula (q.PORT_F0, v_p_bus_id, q.PORT_CD_F1, q.IMPR_NBR_F1), 'text-align:right;')
                || HTML_CELL (q.TXT_F1, 'text-align:right;') || HTML_CELL (q.TXT_F9) || '</tr>');
        END LOOP;

        IF v_prev_port_f0 IS NOT NULL THEN
            dbms_lob.append (retVal, '</tbody></table>');
        END IF;
""")

# ============================================================================= IMPR2180
IMPR2180 = dict(
    name='IMPR2180', folder='IMPR2180', file='IMPR2180.xml', query='CG$Q_BRKR_MSTR',
    title='تقرير ازدواجية مهنتي الإستيراد والتخليص الجمركي',
    caller='page 2180 through IMPR2180.PRINT_IMPR2180_ARD (ardpdf link; plsql/IMPR2180/impr2180_body.sql).',
    params=[('P_CURR_PORT_CD', 'الجمرك (لو المستخدم 99: P_PORT_CD أو فاضي = الكل، وإلا جمرك المستخدم)'),
            ('P_LIC_TYPE', 'نوع الرخصة (فاضي = الكل)'),
            ('P_MODULE_NAME', 'عنوان التقرير'),
            ('P_REPORT_NO', 'رقم التقرير')],
    notes=['V_HEDFormula و PORT_NAMEFormula مش ظاهرين في الـ layout. P_WORK_PORT_TYPE (format triggers) مش بيتبعت',
           'فكل الأعمدة ظاهرة. إجمالي العدد (CS_3) = عدد المخلصين / المعقبين في النوع، والإجمالي الكلي (CS_2) للتقرير.'],
    decls="    FUNCTION C_LIC_TYPEFormula (P_LIC_TYPE NUMBER) RETURN VARCHAR2;\n" + PORT_NAME_TRIGGER_DECL,
    layout=['Layout of IMPR2180.rdf (Landscape, right to left):',
            '  margin : port name, logo, الرقم / التاريخ / المرفقات, title P_MODULE_NAME, footer report number + dates + page',
            '  R_1 (G_TYP): header row (رقم رخصه المخلص for TYP 1, رقم بطاقة المعقب otherwise) + rows, then إجمالي العدد',
            '  R_2 (broker) / R_3 (BUS_ID) / R_4 (importer) on one line each, outer cells on the first line of their',
            '  group. After the last group: الإجمالي الكلي.'],
    formulas=r"""
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
""" + PORT_NAME_TRIGGER,
    vars=r"""        v_p_curr_port_cd       NUMBER := TO_NUMBER (P_PARAMETER1);
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
""",
    init=r"""
        v_port_name := V_PORT_NAME_SEC1FormatTrigger (v_p_curr_port_cd);
""",
    data=r"""
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
""")

# ============================================================================= IMPR2210 / 2220 / 2230 (AGNTS)
AGNT_DECL = ("    FUNCTION V_NAMEFormula (P_IMPR_TYPE_CD NUMBER) RETURN VARCHAR2;\n"
             "    FUNCTION V_NAME2Formula (P_L_IMP_IMPR_TYPE_CD NUMBER) RETURN VARCHAR2;\n")
AGNT_FORMULAS = r"""
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
""" + PORT_NAME_TRIGGER

AGNT_SELECT = r"""SELECT AG.ATHRZTN_SEQ_NBR   ATHRZTN_SEQ_NBR,
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
                             AND AG.IMPR_NBR_AGENT_ID = IMP.IMPR_NBR"""

AGNT_VARS = r"""        v_p_curr_port_cd       NUMBER := TO_NUMBER (P_PARAMETER1);
        v_impr_list            VARCHAR2 (4000) := RTRIM (REGEXP_REPLACE (P_PARAMETER2, '\s', ''), ',');
"""

AGNT_LAYOUT_MARGIN = '  margin : port name, logo, الرقم / التاريخ / المرفقات, title P_MODULE_NAME, footer report number + dates + page'

IMPR2210 = dict(
    name='IMPR2210', folder='IMPR2210', file='IMPR2210.xml', query='AGNTS',
    title='تفويضات الشركات الوسيطة',
    caller='page 2210 through IMPR2210.PRINT_IMPR2210_ARD (ardpdf link; plsql/IMPR2210/impr2210_body.sql).',
    params=[('P_CURR_PORT_CD', 'الجمرك (P_PORT_CD في الشاشة، وإلا جمرك المستخدم)'),
            ('IMPR_NBR', 'أرقام الشركات الوسيطة مفصولة بفاصلة (LICE_NO في الشاشة، فاضي = الكل)'),
            ('P_MODULE_NAME', 'عنوان التقرير'),
            ('P_REPORT_NO', 'رقم التقرير')],
    notes=['الـ RDF: IMP.IMPR_NBR = :IMPR_NBR والفورم بيبعت LICE_NO (ممكن أكتر من رقم مفصولين بفاصلة فالمقارنة بتفشل)؛',
           'هنا IMP.IMPR_NBR IN (القايمة) زي IMPR2110_ARD.'],
    decls=AGNT_DECL + PORT_NAME_TRIGGER_DECL,
    layout=['Layout of IMPR2210.rdf (Landscape, right to left):', AGNT_LAYOUT_MARGIN,
            '  M_CG$G_AGNTS_GRPFR (printed only when there are rows): header row + R_CG$G_AGNTS rows.'],
    consts=LIST_PATTERN, formulas=AGNT_FORMULAS,
    vars=AGNT_VARS + r"""        v_p_module_name        VARCHAR2 (4000) := P_PARAMETER3;
        v_p_report_no          VARCHAR2 (4000) := P_PARAMETER4;
        v_port_name            VARCHAR2 (100);   -- V_PORT_NAME_SEC1
        v_rows                 NUMBER := 0;
""",
    init="\n        v_port_name := V_PORT_NAME_SEC1FormatTrigger (v_p_curr_port_cd);\n",
    data=r"""
        IF v_impr_list IS NULL OR REGEXP_LIKE (v_impr_list, c_list_pattern) THEN
            FOR q IN (""" + AGNT_SELECT + r"""
                             AND IMP.PORT_CD = v_p_curr_port_cd
                             AND (v_impr_list IS NULL OR IMP.IMPR_NBR IN """ + list_in() + r""")
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
""")


def agnt_grouped(name, title, list_rdf, list_note, single_rdf, single_note, list_col, single_col, group_cols,
                 group_html, header_html, row_html, order_by, layout_group):
    return dict(
        name=name, folder=name, file=name + '.xml', query='AGNTS', title=title,
        caller='page %s through %s.PRINT_%s_ARD (ardpdf link) - page not built yet.' % (name[4:], name, name),
        params=[('P_CURR_PORT_CD', 'الجمرك (P_PORT_CD في الشاشة، وإلا جمرك المستخدم)'),
                (list_rdf, list_note),
                (single_rdf, single_note),
                ('P_MODULE_NAME', 'عنوان التقرير'),
                ('P_REPORT_NO', 'رقم التقرير')],
        notes=['الفلتر: &%s في الـ RDF هو :parameter.TRAN_SELECT في الفورم (" AND %s in (LICE_NO)")، هنا القايمة' % (list_rdf, list_col),
               'بتتقرا أرقام (من غير lexical) زي IMPR2110_ARD.'],
        decls=AGNT_DECL + PORT_NAME_TRIGGER_DECL,
        layout=['Layout of %s.rdf (Landscape, right to left):' % name, AGNT_LAYOUT_MARGIN, layout_group],
        consts=LIST_PATTERN + NUMBER_PATTERN, formulas=AGNT_FORMULAS,
        vars=AGNT_VARS + r"""        v_single_nbr           VARCHAR2 (4000) := TRIM (P_PARAMETER3);
        v_p_module_name        VARCHAR2 (4000) := P_PARAMETER4;
        v_p_report_no          VARCHAR2 (4000) := P_PARAMETER5;
        v_port_name            VARCHAR2 (100);   -- V_PORT_NAME_SEC1
        v_key                  VARCHAR2 (4000);
        v_prev_key             VARCHAR2 (4000);  -- المجموعة اللي فاتت (break)
""",
        init="\n        v_port_name := V_PORT_NAME_SEC1FormatTrigger (v_p_curr_port_cd);\n",
        data=r"""
        IF     (v_impr_list IS NULL OR REGEXP_LIKE (v_impr_list, c_list_pattern))
           AND (v_single_nbr IS NULL OR REGEXP_LIKE (v_single_nbr, c_number_pattern)) THEN
            FOR q IN (""" + AGNT_SELECT + r"""
                             AND (v_single_nbr IS NULL OR """ + single_col + r""" = TO_NUMBER (v_single_nbr))
                             AND (IMP.PORT_CD = v_p_curr_port_cd OR v_p_curr_port_cd IS NULL)
                             -- &""" + list_rdf + r""" (:parameter.TRAN_SELECT of the form)
                             AND """ + list_col + r""" IS NOT NULL
                             AND (v_impr_list IS NULL OR """ + list_col + r""" IN """ + list_in() + r""")
                       ORDER BY """ + order_by + r""")
            LOOP
                v_key := """ + group_cols + r""";
                IF v_prev_key IS NULL OR v_prev_key <> v_key THEN
                    IF v_prev_key IS NOT NULL THEN
                        dbms_lob.append (retVal, '</tbody></table>');
                    END IF;
                    v_prev_key := v_key;
""" + group_html + header_html + r"""                END IF;
""" + row_html + r"""            END LOOP;
        END IF;

        IF v_prev_key IS NOT NULL THEN
            dbms_lob.append (retVal, '</tbody></table>');
        END IF;
""")


IMPR2220 = agnt_grouped(
    'IMPR2220', 'تفويضات الشركات الوسيطة حسب الشركة',
    'IMPR_NBR', 'أرقام الشركات الوسيطة مفصولة بفاصلة (LICE_NO في الشاشة، فاضي = الكل)',
    'L_IMPR_NBR', 'مسلسل المستورد (الفورم مش بيبعته، فاضي = الكل)',
    'IMP.IMPR_NBR', 'L_IMP.IMPR_NBR',
    "q.IMPR_NBR || '|' || q.ARBC_IMPR_NAME",
    r"""                    -- R_1 (G_V_NAME): V_NAME من أول تفويض في المجموعة
                    dbms_lob.append (retVal, '
              <table class="grp" dir="rtl"><tbody><tr>
                <td style="width:20%;">' || LABEL_VALUE ('مسلسل الشركة :', q.IMPR_NBR) || '</td>
                <td style="width:45%;">' || LABEL_VALUE ('اسم الشركة الوسيطه :', q.ARBC_IMPR_NAME) || '</td>
                <td style="width:35%;">' || LABEL_VALUE ('نوع الشركة الوسيطه :', V_NAMEFormula (q.IMPR_TYPE_CD)) || '</td>
              </tr></tbody></table>');
""",
    r"""                    -- M_CG$G_AGNTS_HDR
                    dbms_lob.append (retVal, '
              <table class="data" dir="rtl"><thead><tr>
                <th style="width:10%;">مسلسل التفويض</th><th style="width:14%;">تاريخ انشاء التفويض</th><th style="width:12%;">حالة التفويض</th>
                <th style="width:13%;">تاريخ حذف التفويض</th><th style="width:8%;">مسلسل المستورد</th><th style="width:28%;">اسم المستورد</th>
                <th style="width:15%;">نوع المستورد</th>
              </tr></thead><tbody>');
""",
    r"""                -- R_CG$G_AGNTS
                dbms_lob.append (retVal, '<tr>' || HTML_CELL (q.ATHRZTN_SEQ_NBR) || HTML_CELL (TO_CHAR (q.ATHRZTN_CRET_DT, 'MI-MM-YYYY'))
                                         || HTML_CELL (q.ATHRZTN_STA_CDM) || HTML_CELL (TO_CHAR (q.ATHRZTN_CNCLD_DT, 'MI-MM-YYYY'))
                                         || HTML_CELL (q.L_IMP_IMPR_NBR) || HTML_CELL (q.L_IMP_ARBC_IMPR_NAME, 'text-align:right;')
                                         || HTML_CELL (V_NAME2Formula (q.L_IMP_IMPR_TYPE_CD)) || '</tr>');
""",
    'IMP.IMPR_NBR, IMP.ARBC_IMPR_NAME, AG.ATHRZTN_SEQ_NBR',
    '  R_1 (G_V_NAME, per intermediary company): مسلسل / اسم / نوع الشركة الوسيطه, then header row + R_CG$G_AGNTS rows.')

IMPR2220['caller'] = 'page 2220 through IMPR2220.PRINT_IMPR2220_ARD (ardpdf link; plsql/IMPR2220/impr2220_body.sql).'

IMPR2230 = agnt_grouped(
    'IMPR2230', 'تفويضات الشركات الوسيطة حسب المستورد',
    'L_IMPR_NBR', 'أرقام المستوردين مفصولة بفاصلة (LICE_NO في الشاشة، فاضي = الكل)',
    'IMPR_NBR', 'مسلسل الشركة الوسيطة (الفورم مش بيبعته، فاضي = الكل)',
    'L_IMP.IMPR_NBR', 'IMP.IMPR_NBR',
    "q.L_IMP_IMPR_NBR || '|' || q.L_IMP_ARBC_IMPR_NAME",
    r"""                    -- R_1 (G_L_IMP_ARBC_IMPR_NAME): V_NAME2 من أول تفويض في المجموعة
                    dbms_lob.append (retVal, '
              <table class="grp" dir="rtl"><tbody><tr>
                <td style="width:20%;">' || LABEL_VALUE ('مسلسل المستورد :', q.L_IMP_IMPR_NBR) || '</td>
                <td style="width:45%;">' || LABEL_VALUE ('اسم المستورد :', q.L_IMP_ARBC_IMPR_NAME) || '</td>
                <td style="width:35%;">' || LABEL_VALUE ('نوع المستورد :', V_NAME2Formula (q.L_IMP_IMPR_TYPE_CD)) || '</td>
              </tr></tbody></table>');
""",
    r"""                    -- M_CG$G_AGNTS_HDR
                    dbms_lob.append (retVal, '
              <table class="data" dir="rtl"><thead><tr>
                <th style="width:8%;">مسلسل التفويض</th><th style="width:13%;">تاريخ انشاء التفويض</th><th style="width:13%;">حالة التفويض</th>
                <th style="width:11%;">تاريخ حذف التفويض</th><th style="width:7%;">مسلسل الشركة</th><th style="width:29%;">اسم الشركة الوسيطه</th>
                <th style="width:19%;">نوع الشركة الوسيطه</th>
              </tr></thead><tbody>');
""",
    r"""                -- R_CG$G_AGNTS
                dbms_lob.append (retVal, '<tr>' || HTML_CELL (q.ATHRZTN_SEQ_NBR) || HTML_CELL (TO_CHAR (q.ATHRZTN_CRET_DT, 'MI-MM-YYYY'))
                                         || HTML_CELL (q.ATHRZTN_STA_CDM) || HTML_CELL (TO_CHAR (q.ATHRZTN_CNCLD_DT, 'MI-MM-YYYY'))
                                         || HTML_CELL (q.IMPR_NBR) || HTML_CELL (q.ARBC_IMPR_NAME, 'text-align:right;')
                                         || HTML_CELL (V_NAMEFormula (q.IMPR_TYPE_CD)) || '</tr>');
""",
    'L_IMP.IMPR_NBR, L_IMP.ARBC_IMPR_NAME, AG.ATHRZTN_SEQ_NBR',
    '  R_1 (G_L_IMP_ARBC_IMPR_NAME, per importer): مسلسل / اسم / نوع المستورد, then header row + R_CG$G_AGNTS rows.')

IMPR2230['caller'] = 'page 2230 through IMPR2230.PRINT_IMPR2230_ARD (ardpdf link; plsql/IMPR2230/impr2230_body.sql).'

# ============================================================================= IMPR2250
IMPR2250 = dict(
    name='IMPR2250', folder='IMPR2250', file='IMPR2250.xml', query='IMPR_RULS',
    title='استثناءات المستوردين بالرقم الاستدلالي',
    caller='no form in forms/IMPR calls IMPR2250 (no page yet); a page builds the link as PRINT_IMPR2250_ARD.',
    params=[('P_CURR_PORT_CD', 'جمرك المستخدم (اسم الجمرك في الهيدر)'),
            ('P_BUS_ID_TYPE_CD', 'نوع الرقم الاستدلالي (فاضي = الكل)'),
            ('P_BUS_ID', 'الرقم الاستدلالي (فاضي = الكل)'),
            ('P_BUS_ID_BRNCH', 'الفرع (فاضي = الكل)'),
            ('P_MODULE_NAME', 'عنوان التقرير'),
            ('P_REPORT_NO', 'رقم التقرير')],
    notes=['REC_STATUS في مجموعة الاستثناء هو IMPR_RULE_PORTS.REC_STATUS و REC_STATUS2 في الجمارك هو IMPR_RULES.REC_STATUS',
           '(زي الـ RDF).'],
    decls=RULE_FORMULAS_DECL + PORT_NAME_TRIGGER_DECL,
    layout=['Layout of IMPR2250.rdf (Landscape, right to left):',
            '  margin : port name, logo, الرقم / التاريخ / المرفقات, title P_MODULE_NAME, footer report number + dates + page',
            '  R_1 (per exception): مسلسل / نوع / استخدام الاستثناء, نوع الرقم الاستدلالي : الرقم, الفرع, حالة السجل,',
            '  then header row + R_CG$G_AGNTS rows: رمز الجمرك, اسم الجمرك, حالة السجل.'],
    formulas=rule_formulas(False) + PORT_NAME_TRIGGER,
    vars=r"""        v_p_curr_port_cd       NUMBER := TO_NUMBER (P_PARAMETER1);
        v_p_bus_id_type_cd     NUMBER := TO_NUMBER (P_PARAMETER2);
        v_p_bus_id             VARCHAR2 (4000) := P_PARAMETER3;
        v_p_bus_id_brnch       VARCHAR2 (4000) := P_PARAMETER4;
        v_p_module_name        VARCHAR2 (4000) := P_PARAMETER5;
        v_p_report_no          VARCHAR2 (4000) := P_PARAMETER6;
        v_port_name            VARCHAR2 (100);   -- V_PORT_NAME_SEC1
        v_key                  VARCHAR2 (4000);
        v_prev_key             VARCHAR2 (4000);  -- G_L_IMP_ARBC_IMPR_NAME اللي فات
""",
    init="\n        v_port_name := V_PORT_NAME_SEC1FormatTrigger (v_p_curr_port_cd);\n",
    data=r"""
        FOR q IN (SELECT IMPR_RULE_PORTS.PORT_CD,
                         IMPR_RULE_PORTS.REC_STATUS,
                         ' ' || SD_PORTS.PORT_NAME PORT_NAME,
                         IMPR_RULES.RULE_ISN,
                         IMPR_RULES.BUS_ID_TYPE_CD,
                         IMPR_RULES.BUS_ID,
                         IMPR_RULES.BUS_ID_BRNCH,
                         IMPR_RULES.ALL_BRNCH_FLAG,
                         IMPR_RULES.RULE_TYPE,
                         IMPR_RULES.REC_STATUS REC_STATUS2
                    FROM IMPR_RULES, IMPR_RULE_PORTS, SD_PORTS
                   WHERE     IMPR_RULE_PORTS.RULE_ISN = IMPR_RULES.RULE_ISN
                         AND IMPR_RULE_PORTS.PORT_CD = SD_PORTS.PORT_CD
                         AND IMPR_RULES.BUS_ID_TYPE_CD = NVL (v_p_bus_id_type_cd, IMPR_RULES.BUS_ID_TYPE_CD)
                         AND IMPR_RULES.BUS_ID = NVL (v_p_bus_id, IMPR_RULES.BUS_ID)
                         AND (IMPR_RULES.BUS_ID_BRNCH = v_p_bus_id_brnch OR v_p_bus_id_brnch IS NULL)
                   ORDER BY IMPR_RULES.RULE_ISN, IMPR_RULES.RULE_TYPE, IMPR_RULES.ALL_BRNCH_FLAG, IMPR_RULE_PORTS.REC_STATUS,
                            IMPR_RULES.BUS_ID_TYPE_CD, IMPR_RULES.BUS_ID, IMPR_RULES.BUS_ID_BRNCH, IMPR_RULE_PORTS.PORT_CD)
        LOOP
            -- R_1 (G_L_IMP_ARBC_IMPR_NAME)
            v_key := q.RULE_ISN || '|' || q.RULE_TYPE || '|' || q.ALL_BRNCH_FLAG || '|' || q.REC_STATUS || '|'
                     || q.BUS_ID_TYPE_CD || '|' || q.BUS_ID || '|' || q.BUS_ID_BRNCH;
            IF v_prev_key IS NULL OR v_prev_key <> v_key THEN
                IF v_prev_key IS NOT NULL THEN
                    dbms_lob.append (retVal, '</tbody></table>');
                END IF;
                v_prev_key := v_key;
                dbms_lob.append (retVal, '
              <table class="grp" dir="rtl"><tbody>
                <tr><td style="width:25%;">' || LABEL_VALUE ('مسلسل الاستثناء :', q.RULE_ISN) || '</td>
                    <td style="width:45%;">' || LABEL_VALUE ('نوع الاستثناء :', CF_RUL_TYPEFormula (q.RULE_TYPE)) || '</td>
                    <td style="width:30%;">' || LABEL_VALUE ('استخدام الاستثناء :', CF_ALL_BRANCHESFormula (q.ALL_BRNCH_FLAG)) || '</td></tr>
                <tr><td colspan="2">' || LABEL_VALUE (APEX_ESCAPE.HTML (CF_BUS_TYPE_IDFormula (q.BUS_ID_TYPE_CD)) || ' :', q.BUS_ID)
                                    || '&nbsp;&nbsp;' || LABEL_VALUE (CF_BRCH_LBLFormula (q.BUS_ID_BRNCH), q.BUS_ID_BRNCH) || '</td>
                    <td>' || LABEL_VALUE ('حالة السجل :', CF_REC_STATUSFormula (q.REC_STATUS)) || '</td></tr>
              </tbody></table>
              <table class="data" dir="rtl" style="width:80%;"><thead><tr>
                <th style="width:20%;">رمز الجمرك</th><th style="width:55%;">اسم الجمرك</th><th style="width:25%;">حالة السجل</th>
              </tr></thead><tbody>');
            END IF;

            -- R_CG$G_AGNTS
            dbms_lob.append (retVal, '<tr>' || HTML_CELL (q.PORT_CD) || HTML_CELL (q.PORT_NAME, 'text-align:right;')
                                     || HTML_CELL (CF_REC_STATUS2Formula (q.REC_STATUS2)) || '</tr>');
        END LOOP;

        IF v_prev_key IS NOT NULL THEN
            dbms_lob.append (retVal, '</tbody></table>');
        END IF;
""")

# ============================================================================= IMPR2310
IMPR2310 = dict(
    name='IMPR2310', folder='IMPR2310', file='IMPR2310.xml', query='CG$Q_IMPORTERS (JOURNAL.IMPORTERS_JN)',
    title='بيانات المستوردين المعدلة / المضافة',
    caller='page 2310 through IMPR2310.PRINT_IMPR2310_ARD (ardpdf link; plsql/IMPR2310/impr2310_body.sql).',
    params=[('P_CURR_PORT_CD', 'الجمرك (P_PORT_CD في الشاشة)'),
            ('SELECT1', '1 = مستورد محدد، 2 = خطاب / فترة'),
            ('REPORT1', '0 = المعدلة، 1 = المضافة (REPORT في الشاشة)'),
            ('P_IMPR_NBR', 'رقم المستورد (SELECT1 = 1)'),
            ('LTR_NBR', 'رقم الخطاب'),
            ('LTR_DATE', "تاريخ الخطاب 'YYYY-MM-MI'"),
            ('SUPP_SRCE_CD', 'جمرك الخطاب'),
            ('START_DT', "من تاريخ 'YYYY-MM-MI'"),
            ('END_DT', "إلى تاريخ 'YYYY-MM-MI'"),
            ('P_MODULE_NAME', 'عنوان التقرير'),
            ('P_REPORT_NO', 'رقم التقرير')],
    notes=['الكويري في الـ RDF بيقارن IMP.IMPR_NBR = :IMPR_NBR ومفيش parameter بالاسم ده والفورم بيبعت P_IMPR_NBR،',
           'فهنا المقارنة بـ P_IMPR_NBR. التواريخ كانت بتتبعت MI-MM-RRRR، هنا YYYY-MM-MI زي DCLN3300_ARD.'],
    decls=("    FUNCTION C_CODEFormula (P_CITY_CODE NUMBER) RETURN VARCHAR2;\n"
           "    FUNCTION v_name2Formula (P_BUS_ID_TYPE_CD NUMBER) RETURN VARCHAR2;\n"
           "    FUNCTION V_NAMEFormula (P_IMPR_TYPE_CD NUMBER) RETURN VARCHAR2;\n"
           "    FUNCTION CF_SUPP_PORT_NAMEFormula (P_SUPP_SRCE_CD NUMBER) RETURN VARCHAR2;\n"
           "    FUNCTION CF_DEPTFormula (P_SUPP_TITLE_CD NUMBER) RETURN VARCHAR2;\n"
           "    FUNCTION CF_TITLEFormula (P_REPORT1 NUMBER) RETURN VARCHAR2;\n"
           "    FUNCTION CF_USERFormula (P_JN_ORACLE_USER VARCHAR2, P_CURR_PORT_CD NUMBER) RETURN VARCHAR2;\n"
           + PORT_NAME_TRIGGER_DECL),
    layout=['Layout of IMPR2310.rdf (Landscape, right to left):',
            '  margin : port name, logo, الرقم / التاريخ / المرفقات, title P_MODULE_NAME + CF_TITLE, footer report number',
            '           + dates + page',
            '  M_CG$G_IMPORTERS_HDR once (repeated on every page by thead), then R_1 (G_SUPP_SRCE_CD, per letter):',
            '  جمرك / جهة / رقم / تاريخ الخطاب, اسم المستخدم on the first line, next to R_CG$G_IMPORTERS rows: نوع',
            '  المستورد, الرقم الجمركي, اسم المستورد, نوع الرقم الإستدلالي, الرقم الاستدلالى, الفرع, الرقم الموحد.',
            '  C_CODEFormula is in the RDF group but not in the layout; kept for the same package API as IMPR2110_ARD.'],
    formulas=r"""
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
""" + PORT_NAME_TRIGGER,
    vars=r"""        v_p_curr_port_cd       NUMBER := TO_NUMBER (P_PARAMETER1);
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
""",
    init="\n        v_port_name := V_PORT_NAME_SEC1FormatTrigger (v_p_curr_port_cd);\n",
    header=standard_header('CF_TITLEFormula (v_report1)'),
    data=r"""
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
""")

# ============================================================================= IMPR2410
IMPR2410 = dict(
    name='IMPR2410', folder='IMPR2410', file='IMPR2410.xml', query='Q_1',
    title='تقرير تواريخ انتهاء نشاطات المستوردين', size='A4 portrait',
    caller='no form in forms/IMPR calls IMPR2410 (no page yet); a page builds the link as PRINT_IMPR2410_ARD.',
    params=[('P_CURR_PORT_CD', 'جمرك المستخدم (اسم الجمرك في الهيدر)'),
            ('P_PORT_CD', 'جمرك المستورد (فاضي = الكل)'),
            ('P_CLNT_ID', 'رقم العميل (فاضي = الكل)'),
            ('P_BUS_ID', 'الرقم الاستدلالي (فاضي = الكل)'),
            ('P_BUS_ID_BRNCH', 'الفرع (فاضي = الكل)'),
            ('P_MODULE_NAME', 'عنوان التقرير'),
            ('P_REPORT_NO', 'رقم التقرير')],
    notes=['AfterPForm بالحرف: لو P_BUS_ID أو P_BUS_ID_BRNCH مدخل، P_CLNT_ID بيتلغي. P_IMPR_NBR في الـ RDF مش مستخدم.'],
    decls=PORT_NAME_TRIGGER_DECL,
    layout=['Layout of IMPR2410.rdf (Portrait, left to right layout of Arabic text; here dir rtl with the same',
            'positions mirrored):',
            '  margin : letterhead (logo) and port name right, التاريخ / الموافق / الرقم left, title P_MODULE_NAME,',
            '           header row (اسم الجمرك, اسم المستورد, تاريخ انتهاء صلاحية النشاط) on every page; footer',
            '           رقم التقرير + التاريخ (Hijri YYYY-MM-MI / Gregorian YYYY-MM-DD) + page',
            '  R_1 (G_PORT_CD): اسم الجمرك on the first line of the port, next to R_CG$G_DCLTN rows.'],
    formulas=PORT_NAME_TRIGGER,
    vars=r"""        v_p_curr_port_cd       NUMBER := TO_NUMBER (P_PARAMETER1);
        v_p_port_cd            NUMBER := TO_NUMBER (P_PARAMETER2);
        v_p_clnt_id            VARCHAR2 (4000) := P_PARAMETER3;
        v_p_bus_id             VARCHAR2 (4000) := P_PARAMETER4;
        v_p_bus_id_brnch       VARCHAR2 (4000) := P_PARAMETER5;
        v_p_module_name        VARCHAR2 (4000) := P_PARAMETER6;
        v_p_report_no          VARCHAR2 (4000) := P_PARAMETER7;
        v_port_name            VARCHAR2 (100);   -- V_PORT_NAME_SEC1
        v_key                  VARCHAR2 (4000);
        v_prev_key             VARCHAR2 (4000);  -- G_PORT_CD اللي فات
""",
    init=r"""
        -- AfterPForm
        IF (v_p_bus_id IS NOT NULL OR v_p_bus_id_brnch IS NOT NULL) THEN
            v_p_clnt_id := NULL;
        END IF;

        v_port_name := V_PORT_NAME_SEC1FormatTrigger (v_p_curr_port_cd);
""",
    header=r"""
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
""",
    data=r"""
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
""")

# ============================================================================= IMPR2420
IMPR2420_TYPES = [   # (TYP, condition on the importer, expiry condition reversed)
    ('1', '(COMM_RGSTRTN_TYPE = 1 AND (BUS_ID IS NULL OR BUS_ID_BRNCH IS NOT NULL))', False),
    ('2', '(COMM_RGSTRTN_TYPE = 2 AND BUS_ID_BRNCH IS NULL)', False),
    ('3', '(COMM_RGSTRTN_TYPE = 1 AND LENGTH (LTRIM (RTRIM (BUS_ID))) <> 10)', False),
    ('4', 'COMM_RGSTRTN_TYPE = 2 AND LENGTH (LTRIM (RTRIM (BUS_ID))) <> 10', False),
    ('5', '(COMM_RGSTRTN_TYPE = 2 AND BUS_ID = BUS_ID_BRNCH)', False),
    ('6', ("NOT EXISTS (SELECT '1' FROM CITIES WHERE CITIES.CTRY_CD = IMPORTERS.CTRY_CD_OF_ID\n"
           "                                                    AND CITIES.CITY_CD = IMPORTERS.CITY_CODE_OF_ID\n"
           "                                                    AND SUBSTR (CITIES.MINS_COMM_CD, 1) = SUBSTR (BUS_ID, 1, 4))"), False),
    ('7', '(TO_CHAR (BUS_ID)) IN (SELECT TO_CHAR (BUS_ID_BRNCH) FROM COMM_IMPR_RGSTR) AND COMM_RGSTRTN_TYPE = 1', True),
]


def impr2420_query():
    parts = []
    for typ, cond, reverse in IMPR2420_TYPES:
        expired, active = ('>', '<=') if reverse else ('<=', '>')
        parts.append(("SELECT '%s' TYP, PORT_CD, IMPR_NBR, HQ_IMPR_NBR, BUS_ID, BUS_ID_BRNCH, BUS_ID_EXPRD_DT,\n"
                      "                         CTRY_CD_OF_ID, CITY_CODE_OF_ID, ARBC_IMPR_NAME\n"
                      "                    FROM IMPORTERS\n"
                      "                   WHERE     IMPR_TYPE_CD IN (1, 5, 8)\n"
                      "                         AND BUS_ID_TYPE_CD = 2\n"
                      "                         AND PORT_CD = v_p_curr_port_cd\n"
                      "                         AND %s\n"
                      "                         AND (   (v_p_type = 1 AND BUS_ID_EXPRD_DT %s v_cf_curr_dt)\n"
                      "                              OR (v_p_type = 2 AND BUS_ID_EXPRD_DT %s v_cf_curr_dt)\n"
                      "                              OR (v_p_type = 3))") % (typ, cond, expired, active))
    return '\n                  UNION ALL\n                  '.join(parts) + '\n                  ORDER BY 2, 1, 3'


IMPR2420 = dict(
    name='IMPR2420', folder='IMPR2420', file='IMPR2420.xml', query='CG$Q_IMPR_SUSPNS',
    title='تقرير أخطاء المستوردين',
    caller='page 2420 through IMPR2420.PRINT_IMPR2420_ARD (ardpdf link; plsql/IMPR2420/impr2420_body.sql).',
    params=[('P_CURR_PORT_CD', 'جمرك المستخدم (فاضي = 99 زي BeforeReport)'),
            ('P_TYPE', '1 منتهي / 2 ساري / 3 الكل (P_TYPE في الشاشة)'),
            ('P_MODULE_NAME', 'عنوان التقرير'),
            ('P_REPORT_NO', 'رقم التقرير')],
    notes=['الكويري: نفس الـ 7 UNION ALL بتاعة الـ RDF بالأعمدة اللي الـ layout بيستخدمها بس (الـ RDF بيجيب كل أعمدة',
           'IMPORTERS). المسلسل م (CS_1) بيتعد في كل نوع خطأ. TITFormula و CF_1Formula مش ظاهرين في الـ layout.'],
    decls=("    FUNCTION CF_CURR_DTFormula RETURN DATE;\n"
           "    FUNCTION CF_PORTFormula (P_PORT_CD NUMBER) RETURN VARCHAR2;\n"
           "    FUNCTION CF_TYPFormula (P_TYP VARCHAR2) RETURN VARCHAR2;\n"
           "    FUNCTION CF_TYPEFormula (P_BUS_ID_EXPRD_DT DATE, P_CF_CURR_DT DATE) RETURN VARCHAR2;\n"
           "    FUNCTION CF_CITYFormula (P_CITY_CODE_OF_ID NUMBER, P_CTRY_CD_OF_ID NUMBER) RETURN VARCHAR2;\n"
           + PORT_NAME_TRIGGER_DECL),
    layout=['Layout of IMPR2420.rdf (Landscape, right to left):',
            '  margin : port name, logo, الرقم / التاريخ / المرفقات, title P_MODULE_NAME, footer report number + dates + page',
            '  R_G_PORT_CD1 (G_PORT): اسم الجمرك; R_G_TYP1 (G_TYP): نوع الخطـأ; then header row + R_G_IMPR_NBR1 rows:',
            '  م, رقم المستورد, الرقم الموحد, اسم المستورد, مدينة إصدار السجل, رقم السجل الرئيسي / الفرعي,',
            '  ت.إنتهاء النشاط, حالة الصلاحية.'],
    formulas=r"""
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
""" + PORT_NAME_TRIGGER,
    vars=r"""        v_p_curr_port_cd       NUMBER := TO_NUMBER (P_PARAMETER1);
        v_p_type               NUMBER := NVL (TO_NUMBER (P_PARAMETER2), 3);   -- initial value 3 في الـ RDF
        v_p_module_name        VARCHAR2 (4000) := P_PARAMETER3;
        v_p_report_no          VARCHAR2 (4000) := P_PARAMETER4;
        v_cf_curr_dt           DATE;             -- CF_CURR_DT
        v_port_name            VARCHAR2 (100);   -- V_PORT_NAME_SEC1
        v_prev_port            NUMBER;           -- G_PORT اللي فات
        v_prev_typ             VARCHAR2 (10);    -- G_TYP اللي فات
        v_count                NUMBER := 0;      -- CS_1
""",
    init=r"""
        -- BeforeReport
        IF v_p_curr_port_cd IS NULL THEN v_p_curr_port_cd := 99; END IF;

        v_cf_curr_dt := CF_CURR_DTFormula;
        v_port_name := V_PORT_NAME_SEC1FormatTrigger (v_p_curr_port_cd);
""",
    data=r"""
        FOR q IN (""" + impr2420_query() + r""")
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
""")

# ============================================================================= IMPR3100
# IMPR3100.rdf has the IMPR2310 data model and layout (same groups, same formula code - only a comment differs in
# CF_USER - and the same column positions; the header text «فرع» instead of «الفرع»). Different: SELECT DISTINCT and
# the WHERE clause (NVL filters on every parameter instead of SELECT1 / letter / period). The parameters are the ones
# the form's PU CHECK_VAL (VIEW) sends - user decision 2026-11-26: the page follows CHECK_VAL, not the stale
# PRINT_CHECK_VAL. The RDF reads :LETTER_DT while the form sent P_LETTER_DT (so Forms never filtered by the letter
# date); user decision 2026-11-26: the letter date is applied (parameter 8 = LETTER_DT).
IMPR3100 = dict(
    name='IMPR3100', folder='IMPR3100', file='IMPR3100.xml', query='CG$Q_IMPORTERS (JOURNAL.IMPORTERS_JN)',
    title='تقرير إضافات وتعديلات بيانات المستوردين (مساندة فنية)',
    caller='page 3100 through IMPR3100.PRINT_IMPR3100_ARD (ardpdf link; plsql/IMPR3100/impr3100_body.sql).',
    params=[('P_CURR_PORT_CD', 'الجمرك (P_PORT_CD في الشاشة)'),
            ('START_DT', "من تاريخ 'YYYY-MM-MI'"),
            ('END_DT', "إلى تاريخ 'YYYY-MM-MI'"),
            ('P_SUPP_SRCE_CD', 'جمرك الخطاب (SUP_PORT_CD في الشاشة)'),
            ('P_IMPR_NBR', 'رقم المستورد (IMPR_NBR1 في الشاشة)'),
            ('P_SUPP_TITLE_CD', 'جهة الخطاب'),
            ('P_LETTER_NBR', 'رقم الخطاب'),
            ('LETTER_DT', "تاريخ الخطاب 'YYYY-MM-MI'"),
            ('P_USER_ID', 'رمز المستخدم (JN_ORACLE_USER)'),
            ('REPORT1', '0 = المعدلة، 1 = المضافة (REPORT في الشاشة)'),
            ('P_MODULE_NAME', 'عنوان التقرير'),
            ('P_REPORT_NO', 'رقم التقرير')],
    notes=['الكويري في الـ RDF بيقرا :LETTER_DT والفورم كان بيبعت P_LETTER_DT، فتاريخ الخطاب ماكانش بيفلتر في Forms؛',
           'هنا بيتبعت LETTER_DT وبيفلتر (قرار المستخدم 2026-11-26). التواريخ YYYY-MM-MI زي DCLN3300_ARD.'],
    decls=IMPR2310['decls'],
    layout=['Layout of IMPR3100.rdf (Landscape, right to left) = the IMPR2310 layout:',
            '  margin : port name, logo, الرقم / التاريخ / المرفقات, title P_MODULE_NAME + CF_TITLE, footer report number',
            '           + dates + page',
            '  M_CG$G_IMPORTERS_HDR once (repeated on every page by thead), then R_1 (G_SUPP_SRCE_CD, per letter):',
            '  جمرك / جهة / رقم / تاريخ الخطاب, اسم المستخدم on the first line, next to R_CG$G_IMPORTERS rows: نوع',
            '  المستورد, الرقم الجمركي, اسم المستورد, نوع الرقم الإستدلالي, الرقم الاستدلالى, فرع, الرقم الموحد.',
            '  C_CODEFormula is in the RDF group but not in the layout; kept for the same package API as IMPR2310_ARD.',
            '  The RDF DECODE of JN_OPERATION (OPERATION) is not in the layout and its Arabic text is lost in the XML: left out.'],
    formulas=IMPR2310['formulas'],
    vars=r"""        v_p_curr_port_cd       NUMBER := TO_NUMBER (P_PARAMETER1);
        v_start_dt             DATE := TO_DATE (P_PARAMETER2, 'YYYY-MM-MI');
        v_end_dt               DATE := TO_DATE (P_PARAMETER3, 'YYYY-MM-MI');
        v_p_supp_srce_cd       NUMBER := TO_NUMBER (P_PARAMETER4);
        v_p_impr_nbr           NUMBER := TO_NUMBER (P_PARAMETER5);
        v_p_supp_title_cd      NUMBER := TO_NUMBER (P_PARAMETER6);
        v_p_letter_nbr         VARCHAR2 (4000) := P_PARAMETER7;
        v_letter_dt            DATE := TO_DATE (P_PARAMETER8, 'YYYY-MM-MI');
        v_p_user_id            VARCHAR2 (4000) := P_PARAMETER9;
        v_report1              NUMBER := TO_NUMBER (P_PARAMETER10);
        v_p_module_name        VARCHAR2 (4000) := P_PARAMETER11;
        v_p_report_no          VARCHAR2 (4000) := P_PARAMETER12;
        v_port_name            VARCHAR2 (100);   -- V_PORT_NAME_SEC1
        v_key                  VARCHAR2 (4000);
        v_prev_key             VARCHAR2 (4000);  -- G_SUPP_SRCE_CD اللي فات
        v_rows                 NUMBER := 0;
""",
    init="\n        v_port_name := V_PORT_NAME_SEC1FormatTrigger (v_p_curr_port_cd);\n",
    header=standard_header('CF_TITLEFormula (v_report1)'),
    data=r"""
        -- CG$Q_IMPORTERS بالحرف من الـ RDF (SELECT DISTINCT على كل الأعمدة)، الـ binds بقت variables
        FOR q IN (SELECT DISTINCT
                         IMP.PORT_CD               PORT_CD,
                         IMP.IMPR_NBR              IMPR_NBR,
                         IMP.IMPR_TYPE_CD,
                         IMP.BUS_ID_BRNCH          BUS_ID_BRNCH2,
                         IMP.BUS_ID                BUS_ID,
                         IMP.CITY_CODE,
                         IMP.BUS_ID_TYPE_CD,
                         ' ' || IMP.ARBC_IMPR_NAME ARBC_IMPR_NAME,
                         IMP.IMPR_TEL_NBR          IMPR_TEL_NBR,
                         IMP.IMPR_POB_NBR          IMPR_POB_NBR,
                         IMP.IMPR_ZIP_CD           IMPR_ZIP_CD,
                         IMP.IMPR_FAX_NBR          IMPR_FAX_NBR,
                         IMP.IMPR_TELEX_NBR        IMPR_TELEX_NBR,
                         IMP.ENG_IMPR_NAME         ENG_IMPR_NAME,
                         IMP.IMPR_CNTCT_NAME       IMPR_CNTCT_NAME,
                         IMP.BUS_ID_BRNCH          BUS_ID_BRNCH,
                         IMP.HQ_IMPR_NBR,
                         IMP.EMAIL                 EMAIL,
                         IMP.SUPP_SRCE_CD,
                         IMP.SUPP_TITLE_CD,
                         IMP.SUPP_LETR_NO,
                         IMP.SUPP_LETR_DT,
                         IMP.JN_ORACLE_USER,
                         IMP.JN_OPERATION
                    FROM JOURNAL.IMPORTERS_JN IMP
                   WHERE     IMP.PORT_CD = v_p_curr_port_cd /*CNTRL BY AHMED*/
                         AND IMP.IMPR_NBR = NVL (v_p_impr_nbr, IMP.IMPR_NBR)
                         AND IMP.SUPP_SRCE_CD = NVL (v_p_supp_srce_cd, IMP.SUPP_SRCE_CD)
                         AND IMP.SUPP_TITLE_CD = NVL (v_p_supp_title_cd, IMP.SUPP_TITLE_CD)
                         AND IMP.SUPP_LETR_NO = NVL (v_p_letter_nbr, IMP.SUPP_LETR_NO)
                         AND IMP.JN_ORACLE_USER = NVL (v_p_user_id, IMP.JN_ORACLE_USER)
                         AND TO_CHAR (IMP.SUPP_LETR_DT, 'RRRR-MM-MI') =
                                TO_CHAR (NVL (v_letter_dt, IMP.SUPP_LETR_DT), 'RRRR-MM-MI')
                         AND TO_CHAR (IMP.SUPP_LETR_DT, 'RRRR-MM-MI') >=
                                TO_CHAR (NVL (v_start_dt, IMP.SUPP_LETR_DT), 'RRRR-MM-MI')
                         AND TO_CHAR (IMP.SUPP_LETR_DT, 'RRRR-MM-MI') <=
                                TO_CHAR (NVL (v_end_dt, IMP.SUPP_LETR_DT), 'RRRR-MM-MI')
                         AND (   (IMP.JN_OPERATION IN ('UPB', 'UPA') AND v_report1 = 0)
                              OR (IMP.JN_OPERATION = 'INS' AND v_report1 = 1))
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
                <th style="width:8%;">الرقم الاستدلالى</th><th style="width:4%;">فرع</th><th style="width:6%;">الرقم الموحد</th>
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
""")

REPORTS = [IMPR2120, IMPR2130, IMPR2141, IMPR2142, IMPR2143, IMPR2150, IMPR2170, IMPR2180, IMPR2210, IMPR2220,
           IMPR2230, IMPR2250, IMPR2310, IMPR2410, IMPR2420, IMPR3100]


def impr2170_query():
    path = os.path.join(ROOT, 'scripts', 'ard_sql', 'IMPR2170_query.sql')
    return open(path, encoding='utf-8').read().rstrip()


def main(names):
    for r in REPORTS:
        if names and r['name'] not in names:
            continue
        if r['name'] == 'IMPR2170':
            r['data'] = r['data'].replace('@@IMPR2170_QUERY@@', impr2170_query())
        folder = os.path.join(ROOT, 'plsql', r['folder'])
        os.makedirs(folder, exist_ok=True)
        for part, text in (('spec', spec(r)), ('body', body(r))):
            path = os.path.join(folder, '%s_ARD_%s.sql' % (r['name'], part))
            with open(path, 'w', encoding='utf-8') as f:
                f.write(text)
            print('wrote', os.path.relpath(path, ROOT))


if __name__ == '__main__':
    main(sys.argv[1:])
