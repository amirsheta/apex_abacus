-- =============================================================================
-- Package     : IMPR2420_ARD   (report IMPR2420.rdf "تقرير أخطاء المستوردين" as an ARD report)
-- Source      : forms/IMPR/reports/IMPR2420.xml (Oracle Reports, data source CG$Q_IMPR_SUSPNS)
-- Pattern     : ARD reports (Forms_to_APEX standard 13-c, DEC-014 / DEC-024), as plsql/Shared/DCLN3300_ARD
--               and plsql/IMPR2110/IMPR2110_ARD: ARD_IMPR2420 returns the report as HTML, the ARD server (ardpdf)
--               turns it into PDF.
-- Called from : page 2420 through IMPR2420.PRINT_IMPR2420_ARD (ardpdf link; plsql/IMPR2420/impr2420_body.sql).
-- Generated   : scripts/gen_ard_impr_reports.py (a change goes there, then re-run)
-- Author      : Claude Code      Created: 2026-11-25      Version: 001
-- Status      : NOT COMPILED. Depends on ARD_LOGO (static file LOGO1.jpg, DEC-034) and HIJDATE_DB.
-- =============================================================================
SET DEFINE OFF

CREATE OR REPLACE PACKAGE LIB_APX_USR.IMPR2420_ARD
AS
   V_PKG_VERSION       VARCHAR2 (100) := 'VERSION NO. IS:' || '001';
   V_PKG_VERSION_QC    VARCHAR2 (100) := 'VERSION NO. IS:' || '001';
   V_PKG_VERSION_DEV   VARCHAR2 (100) := 'VERSION NO. IS:' || '001';
   FUNCTION PKG_VERSION
      RETURN VARCHAR2;
   V_PACKAGE_NAME      VARCHAR2 (50) := 'IMPR2420_ARD';
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
    --   P_PARAMETER1   P_CURR_PORT_CD     جمرك المستخدم (فاضي = 99 زي BeforeReport)
    --   P_PARAMETER2   P_TYPE             1 منتهي / 2 ساري / 3 الكل (P_TYPE في الشاشة)
    --   P_PARAMETER3   P_MODULE_NAME      عنوان التقرير
    --   P_PARAMETER4   P_REPORT_NO        رقم التقرير
    -- الكويري: نفس الـ 7 UNION ALL بتاعة الـ RDF بالأعمدة اللي الـ layout بيستخدمها بس (الـ RDF بيجيب كل أعمدة
    -- IMPORTERS). المسلسل م (CS_1) بيتعد في كل نوع خطأ. TITFormula و CF_1Formula مش ظاهرين في الـ layout.

    -- الـ formula columns بتاعة الـ RDF بنفس الكود، بتتنادى من جوه الكويري أو اللوب زي الريفرنس
    FUNCTION CF_CURR_DTFormula RETURN DATE;
    FUNCTION CF_PORTFormula (P_PORT_CD NUMBER) RETURN VARCHAR2;
    FUNCTION CF_TYPFormula (P_TYP VARCHAR2) RETURN VARCHAR2;
    FUNCTION CF_TYPEFormula (P_BUS_ID_EXPRD_DT DATE, P_CF_CURR_DT DATE) RETURN VARCHAR2;
    FUNCTION CF_CITYFormula (P_CITY_CODE_OF_ID NUMBER, P_CTRY_CD_OF_ID NUMBER) RETURN VARCHAR2;
    FUNCTION V_PORT_NAME_SEC1FormatTrigger (P_CURR_PORT_CD NUMBER) RETURN VARCHAR2;

    FUNCTION ARD_IMPR2420 (P_PARAMETER1   IN VARCHAR2 DEFAULT NULL,
                           P_PARAMETER2   IN VARCHAR2 DEFAULT NULL,
                           P_PARAMETER3   IN VARCHAR2 DEFAULT NULL,
                           P_PARAMETER4   IN VARCHAR2 DEFAULT NULL)
        RETURN CLOB;
END IMPR2420_ARD;
/
SHOW ERRORS


CREATE OR REPLACE PUBLIC SYNONYM IMPR2420_ARD FOR LIB_APX_USR.IMPR2420_ARD;


GRANT EXECUTE ON LIB_APX_USR.IMPR2420_ARD TO LIB_USR;

GRANT EXECUTE ON LIB_APX_USR.IMPR2420_ARD TO SECURITY_DEFAULT;

GRANT EXECUTE ON LIB_APX_USR.IMPR2420_ARD TO SECURITY_PROD;

GRANT EXECUTE ON LIB_APX_USR.IMPR2420_ARD TO CUSTOMS;
