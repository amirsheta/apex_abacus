-- =============================================================================
-- Package     : IMPR3100_ARD   (report IMPR3100.rdf "تقرير إضافات وتعديلات بيانات المستوردين (مساندة فنية)" as an ARD report)
-- Source      : forms/IMPR/reports/IMPR3100.xml (Oracle Reports, data source CG$Q_IMPORTERS (JOURNAL.IMPORTERS_JN))
-- Pattern     : ARD reports (Forms_to_APEX standard 13-c, DEC-014 / DEC-024), as plsql/Shared/DCLN3300_ARD
--               and plsql/IMPR2110/IMPR2110_ARD: ARD_IMPR3100 returns the report as HTML, the ARD server (ardpdf)
--               turns it into PDF.
-- Called from : page 3100 through IMPR3100.PRINT_IMPR3100_ARD (ardpdf link; plsql/IMPR3100/impr3100_body.sql).
-- Generated   : scripts/gen_ard_impr_reports.py (a change goes there, then re-run)
-- Author      : Claude Code      Created: 2026-11-25      Version: 001
-- Status      : NOT COMPILED. Depends on ARD_LOGO (static file LOGO1.jpg, DEC-034) and HIJDATE_DB.
-- =============================================================================
SET DEFINE OFF

CREATE OR REPLACE PACKAGE LIB_APX_USR.IMPR3100_ARD
AS
   V_PKG_VERSION       VARCHAR2 (100) := 'VERSION NO. IS:' || '001';
   V_PKG_VERSION_QC    VARCHAR2 (100) := 'VERSION NO. IS:' || '001';
   V_PKG_VERSION_DEV   VARCHAR2 (100) := 'VERSION NO. IS:' || '001';
   FUNCTION PKG_VERSION
      RETURN VARCHAR2;
   V_PACKAGE_NAME      VARCHAR2 (50) := 'IMPR3100_ARD';
   V_LAST_MODIFY_DT    VARCHAR2 (10) := '25-11-2026';
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
    -- معاملات التقرير بنفس أسماء الـ RDF
    --   P_PARAMETER1   P_CURR_PORT_CD     الجمرك (P_PORT_CD في الشاشة)
    --   P_PARAMETER2   START_DT           من تاريخ 'YYYY-MM-MI'
    --   P_PARAMETER3   END_DT             إلى تاريخ 'YYYY-MM-MI'
    --   P_PARAMETER4   P_SUPP_SRCE_CD     جمرك الخطاب (SUP_PORT_CD في الشاشة)
    --   P_PARAMETER5   P_IMPR_NBR         رقم المستورد (IMPR_NBR1 في الشاشة)
    --   P_PARAMETER6   P_SUPP_TITLE_CD    جهة الخطاب
    --   P_PARAMETER7   P_LETTER_NBR       رقم الخطاب
    --   P_PARAMETER8   LETTER_DT          تاريخ الخطاب 'YYYY-MM-MI'
    --   P_PARAMETER9   P_USER_ID          رمز المستخدم (JN_ORACLE_USER)
    --   P_PARAMETER10  REPORT1            0 = المعدلة، 1 = المضافة (REPORT في الشاشة)
    --   P_PARAMETER11  P_MODULE_NAME      عنوان التقرير
    --   P_PARAMETER12  P_REPORT_NO        رقم التقرير
    -- الكويري في الـ RDF بيقرا :LETTER_DT والفورم كان بيبعت P_LETTER_DT، فتاريخ الخطاب ماكانش بيفلتر في Forms؛
    -- هنا بيتبعت LETTER_DT وبيفلتر (قرار المستخدم 2026-11-26). التواريخ YYYY-MM-MI زي DCLN3300_ARD.

    -- الـ formula columns بتاعة الـ RDF بنفس الكود، بتتنادى من جوه الكويري أو اللوب زي الريفرنس
    FUNCTION C_CODEFormula (P_CITY_CODE NUMBER) RETURN VARCHAR2;
    FUNCTION v_name2Formula (P_BUS_ID_TYPE_CD NUMBER) RETURN VARCHAR2;
    FUNCTION V_NAMEFormula (P_IMPR_TYPE_CD NUMBER) RETURN VARCHAR2;
    FUNCTION CF_SUPP_PORT_NAMEFormula (P_SUPP_SRCE_CD NUMBER) RETURN VARCHAR2;
    FUNCTION CF_DEPTFormula (P_SUPP_TITLE_CD NUMBER) RETURN VARCHAR2;
    FUNCTION CF_TITLEFormula (P_REPORT1 NUMBER) RETURN VARCHAR2;
    FUNCTION CF_USERFormula (P_JN_ORACLE_USER VARCHAR2, P_CURR_PORT_CD NUMBER) RETURN VARCHAR2;
    FUNCTION V_PORT_NAME_SEC1FormatTrigger (P_CURR_PORT_CD NUMBER) RETURN VARCHAR2;

    FUNCTION ARD_IMPR3100 (P_PARAMETER1   IN VARCHAR2 DEFAULT NULL,
                           P_PARAMETER2   IN VARCHAR2 DEFAULT NULL,
                           P_PARAMETER3   IN VARCHAR2 DEFAULT NULL,
                           P_PARAMETER4   IN VARCHAR2 DEFAULT NULL,
                           P_PARAMETER5   IN VARCHAR2 DEFAULT NULL,
                           P_PARAMETER6   IN VARCHAR2 DEFAULT NULL,
                           P_PARAMETER7   IN VARCHAR2 DEFAULT NULL,
                           P_PARAMETER8   IN VARCHAR2 DEFAULT NULL,
                           P_PARAMETER9   IN VARCHAR2 DEFAULT NULL,
                           P_PARAMETER10  IN VARCHAR2 DEFAULT NULL,
                           P_PARAMETER11  IN VARCHAR2 DEFAULT NULL,
                           P_PARAMETER12  IN VARCHAR2 DEFAULT NULL)
        RETURN CLOB;
END IMPR3100_ARD;
/
SHOW ERRORS


CREATE OR REPLACE PUBLIC SYNONYM IMPR3100_ARD FOR LIB_APX_USR.IMPR3100_ARD;


GRANT EXECUTE ON LIB_APX_USR.IMPR3100_ARD TO LIB_USR;

GRANT EXECUTE ON LIB_APX_USR.IMPR3100_ARD TO SECURITY_DEFAULT;

GRANT EXECUTE ON LIB_APX_USR.IMPR3100_ARD TO SECURITY_PROD;

GRANT EXECUTE ON LIB_APX_USR.IMPR3100_ARD TO CUSTOMS;
