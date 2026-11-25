-- =============================================================================
-- Package     : IMPR2310_ARD   (report IMPR2310.rdf "بيانات المستوردين المعدلة / المضافة" as an ARD report)
-- Source      : forms/IMPR/reports/IMPR2310.xml (Oracle Reports, data source CG$Q_IMPORTERS (JOURNAL.IMPORTERS_JN))
-- Pattern     : ARD reports (Forms_to_APEX standard 13-c, DEC-014 / DEC-024), as plsql/Shared/DCLN3300_ARD
--               and plsql/IMPR2110/IMPR2110_ARD: ARD_IMPR2310 returns the report as HTML, the ARD server (ardpdf)
--               turns it into PDF.
-- Called from : page 2310 through IMPR2310.PRINT_IMPR2310_ARD (ardpdf link) - page not built yet.
-- Generated   : scripts/gen_ard_impr_reports.py (a change goes there, then re-run)
-- Author      : Claude Code      Created: 2026-11-25      Version: 001
-- Status      : NOT COMPILED. Depends on ARD_LOGO (static file LOGO1.jpg, DEC-034) and HIJDATE_DB.
-- =============================================================================
SET DEFINE OFF

CREATE OR REPLACE PACKAGE LIB_APX_USR.IMPR2310_ARD
AS
   V_PKG_VERSION       VARCHAR2 (100) := 'VERSION NO. IS:' || '001';
   V_PKG_VERSION_QC    VARCHAR2 (100) := 'VERSION NO. IS:' || '001';
   V_PKG_VERSION_DEV   VARCHAR2 (100) := 'VERSION NO. IS:' || '001';
   FUNCTION PKG_VERSION
      RETURN VARCHAR2;
   V_PACKAGE_NAME      VARCHAR2 (50) := 'IMPR2310_ARD';
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
    --   P_PARAMETER2   SELECT1            1 = مستورد محدد، 2 = خطاب / فترة
    --   P_PARAMETER3   REPORT1            0 = المعدلة، 1 = المضافة (REPORT في الشاشة)
    --   P_PARAMETER4   P_IMPR_NBR         رقم المستورد (SELECT1 = 1)
    --   P_PARAMETER5   LTR_NBR            رقم الخطاب
    --   P_PARAMETER6   LTR_DATE           تاريخ الخطاب 'YYYY-MM-MI'
    --   P_PARAMETER7   SUPP_SRCE_CD       جمرك الخطاب
    --   P_PARAMETER8   START_DT           من تاريخ 'YYYY-MM-MI'
    --   P_PARAMETER9   END_DT             إلى تاريخ 'YYYY-MM-MI'
    --   P_PARAMETER10  P_MODULE_NAME      عنوان التقرير
    --   P_PARAMETER11  P_REPORT_NO        رقم التقرير
    -- الكويري في الـ RDF بيقارن IMP.IMPR_NBR = :IMPR_NBR ومفيش parameter بالاسم ده والفورم بيبعت P_IMPR_NBR،
    -- فهنا المقارنة بـ P_IMPR_NBR. التواريخ كانت بتتبعت MI-MM-RRRR، هنا YYYY-MM-MI زي DCLN3300_ARD.

    -- الـ formula columns بتاعة الـ RDF بنفس الكود، بتتنادى من جوه الكويري أو اللوب زي الريفرنس
    FUNCTION C_CODEFormula (P_CITY_CODE NUMBER) RETURN VARCHAR2;
    FUNCTION v_name2Formula (P_BUS_ID_TYPE_CD NUMBER) RETURN VARCHAR2;
    FUNCTION V_NAMEFormula (P_IMPR_TYPE_CD NUMBER) RETURN VARCHAR2;
    FUNCTION CF_SUPP_PORT_NAMEFormula (P_SUPP_SRCE_CD NUMBER) RETURN VARCHAR2;
    FUNCTION CF_DEPTFormula (P_SUPP_TITLE_CD NUMBER) RETURN VARCHAR2;
    FUNCTION CF_TITLEFormula (P_REPORT1 NUMBER) RETURN VARCHAR2;
    FUNCTION CF_USERFormula (P_JN_ORACLE_USER VARCHAR2, P_CURR_PORT_CD NUMBER) RETURN VARCHAR2;
    FUNCTION V_PORT_NAME_SEC1FormatTrigger (P_CURR_PORT_CD NUMBER) RETURN VARCHAR2;

    FUNCTION ARD_IMPR2310 (P_PARAMETER1   IN VARCHAR2 DEFAULT NULL,
                           P_PARAMETER2   IN VARCHAR2 DEFAULT NULL,
                           P_PARAMETER3   IN VARCHAR2 DEFAULT NULL,
                           P_PARAMETER4   IN VARCHAR2 DEFAULT NULL,
                           P_PARAMETER5   IN VARCHAR2 DEFAULT NULL,
                           P_PARAMETER6   IN VARCHAR2 DEFAULT NULL,
                           P_PARAMETER7   IN VARCHAR2 DEFAULT NULL,
                           P_PARAMETER8   IN VARCHAR2 DEFAULT NULL,
                           P_PARAMETER9   IN VARCHAR2 DEFAULT NULL,
                           P_PARAMETER10  IN VARCHAR2 DEFAULT NULL,
                           P_PARAMETER11  IN VARCHAR2 DEFAULT NULL)
        RETURN CLOB;
END IMPR2310_ARD;
/
SHOW ERRORS


CREATE OR REPLACE PUBLIC SYNONYM IMPR2310_ARD FOR LIB_APX_USR.IMPR2310_ARD;


GRANT EXECUTE ON LIB_APX_USR.IMPR2310_ARD TO LIB_USR;

GRANT EXECUTE ON LIB_APX_USR.IMPR2310_ARD TO SECURITY_DEFAULT;

GRANT EXECUTE ON LIB_APX_USR.IMPR2310_ARD TO SECURITY_PROD;

GRANT EXECUTE ON LIB_APX_USR.IMPR2310_ARD TO CUSTOMS;
