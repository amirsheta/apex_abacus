-- =============================================================================
-- Package     : IMPR2150_ARD   (report IMPR2150.rdf "استثناءات المستوردين" as an ARD report)
-- Source      : forms/IMPR/reports/IMPR2150.xml (Oracle Reports, data source IMPR_RULS)
-- Pattern     : ARD reports (Forms_to_APEX standard 13-c, DEC-014 / DEC-024), as plsql/Shared/DCLN3300_ARD
--               and plsql/IMPR2110/IMPR2110_ARD: ARD_IMPR2150 returns the report as HTML, the ARD server (ardpdf)
--               turns it into PDF.
-- Called from : page 2150 through IMPR2150.PRINT_IMPR2150_ARD (ardpdf link) - page not built yet.
-- Generated   : scripts/gen_ard_impr_reports.py (a change goes there, then re-run)
-- Author      : Claude Code      Created: 2026-11-25      Version: 001
-- Status      : NOT COMPILED. Depends on ARD_LOGO (static file LOGO1.jpg, DEC-034) and HIJDATE_DB.
-- =============================================================================
SET DEFINE OFF

CREATE OR REPLACE PACKAGE LIB_APX_USR.IMPR2150_ARD
AS
   V_PKG_VERSION       VARCHAR2 (100) := 'VERSION NO. IS:' || '001';
   V_PKG_VERSION_QC    VARCHAR2 (100) := 'VERSION NO. IS:' || '001';
   V_PKG_VERSION_DEV   VARCHAR2 (100) := 'VERSION NO. IS:' || '001';
   FUNCTION PKG_VERSION
      RETURN VARCHAR2;
   V_PACKAGE_NAME      VARCHAR2 (50) := 'IMPR2150_ARD';
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
    --   P_PARAMETER1   P_CURR_PORT_CD     جمرك المستخدم لاسم الجمرك في الهيدر (الفورم مكانش بيبعته فالـ RDF من غير اسم)
    --   P_PARAMETER2   P_HQ_IMPR_NBR      الرقم الموحد (فاضي = الكل)
    --   P_PARAMETER3   P_REC_STATUS       حالة السجل 1 / 0
    --   P_PARAMETER4   P_RULE_TYPE        نوع الاستثناء (فاضي = الكل)
    --   P_PARAMETER5   P_MODULE_NAME      عنوان التقرير
    --   P_PARAMETER6   P_REPORT_NO        رقم التقرير
    -- REC_STATUS في مجموعة الاستثناء هو IMPR_RULE_PORTS.REC_STATUS (زي الـ RDF)، و CF_REC_STATUS / CF_REC_STATUS2
    -- الاتنين بيقروه.

    -- الـ formula columns بتاعة الـ RDF بنفس الكود، بتتنادى من جوه الكويري أو اللوب زي الريفرنس
    FUNCTION CF_REC_STATUSFormula (P_REC_STATUS NUMBER) RETURN VARCHAR2;
    FUNCTION CF_REC_STATUS2Formula (P_REC_STATUS NUMBER) RETURN VARCHAR2;
    FUNCTION CF_RUL_TYPEFormula (P_RULE_TYPE NUMBER) RETURN VARCHAR2;
    FUNCTION CF_BUS_TYPE_IDFormula (P_BUS_ID_TYPE_CD NUMBER) RETURN VARCHAR2;
    FUNCTION CF_ALL_BRANCHESFormula (P_ALL_BRNCH_FLAG NUMBER) RETURN VARCHAR2;
    FUNCTION CF_BRCH_LBLFormula (P_BUS_ID_BRNCH VARCHAR2) RETURN VARCHAR2;
    FUNCTION V_PORT_NAME_SEC1FormatTrigger (P_CURR_PORT_CD NUMBER) RETURN VARCHAR2;

    FUNCTION ARD_IMPR2150 (P_PARAMETER1   IN VARCHAR2 DEFAULT NULL,
                           P_PARAMETER2   IN VARCHAR2 DEFAULT NULL,
                           P_PARAMETER3   IN VARCHAR2 DEFAULT NULL,
                           P_PARAMETER4   IN VARCHAR2 DEFAULT NULL,
                           P_PARAMETER5   IN VARCHAR2 DEFAULT NULL,
                           P_PARAMETER6   IN VARCHAR2 DEFAULT NULL)
        RETURN CLOB;
END IMPR2150_ARD;
/
SHOW ERRORS


CREATE OR REPLACE PUBLIC SYNONYM IMPR2150_ARD FOR LIB_APX_USR.IMPR2150_ARD;


GRANT EXECUTE ON LIB_APX_USR.IMPR2150_ARD TO LIB_USR;

GRANT EXECUTE ON LIB_APX_USR.IMPR2150_ARD TO SECURITY_DEFAULT;

GRANT EXECUTE ON LIB_APX_USR.IMPR2150_ARD TO SECURITY_PROD;

GRANT EXECUTE ON LIB_APX_USR.IMPR2150_ARD TO CUSTOMS;
