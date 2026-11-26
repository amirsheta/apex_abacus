-- =============================================================================
-- Package     : IMPR2210_ARD   (report IMPR2210.rdf "تفويضات الشركات الوسيطة" as an ARD report)
-- Source      : forms/IMPR/reports/IMPR2210.xml (Oracle Reports, data source AGNTS)
-- Pattern     : ARD reports (Forms_to_APEX standard 13-c, DEC-014 / DEC-024), as plsql/Shared/DCLN3300_ARD
--               and plsql/IMPR2110/IMPR2110_ARD: ARD_IMPR2210 returns the report as HTML, the ARD server (ardpdf)
--               turns it into PDF.
-- Called from : page 2210 through IMPR2210.PRINT_IMPR2210_ARD (ardpdf link; plsql/IMPR2210/impr2210_body.sql).
-- Generated   : scripts/gen_ard_impr_reports.py (a change goes there, then re-run)
-- Author      : Claude Code      Created: 2026-11-25      Version: 001
-- Status      : NOT COMPILED. Depends on ARD_LOGO (static file LOGO1.jpg, DEC-034) and HIJDATE_DB.
-- =============================================================================
SET DEFINE OFF

CREATE OR REPLACE PACKAGE LIB_APX_USR.IMPR2210_ARD
AS
   V_PKG_VERSION       VARCHAR2 (100) := 'VERSION NO. IS:' || '001';
   V_PKG_VERSION_QC    VARCHAR2 (100) := 'VERSION NO. IS:' || '001';
   V_PKG_VERSION_DEV   VARCHAR2 (100) := 'VERSION NO. IS:' || '001';
   FUNCTION PKG_VERSION
      RETURN VARCHAR2;
   V_PACKAGE_NAME      VARCHAR2 (50) := 'IMPR2210_ARD';
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
    --   P_PARAMETER1   P_CURR_PORT_CD     الجمرك (P_PORT_CD في الشاشة، وإلا جمرك المستخدم)
    --   P_PARAMETER2   IMPR_NBR           أرقام الشركات الوسيطة مفصولة بفاصلة (LICE_NO في الشاشة، فاضي = الكل)
    --   P_PARAMETER3   P_MODULE_NAME      عنوان التقرير
    --   P_PARAMETER4   P_REPORT_NO        رقم التقرير
    -- الـ RDF: IMP.IMPR_NBR = :IMPR_NBR والفورم بيبعت LICE_NO (ممكن أكتر من رقم مفصولين بفاصلة فالمقارنة بتفشل)؛
    -- هنا IMP.IMPR_NBR IN (القايمة) زي IMPR2110_ARD.

    -- الـ formula columns بتاعة الـ RDF بنفس الكود، بتتنادى من جوه الكويري أو اللوب زي الريفرنس
    FUNCTION V_NAMEFormula (P_IMPR_TYPE_CD NUMBER) RETURN VARCHAR2;
    FUNCTION V_NAME2Formula (P_L_IMP_IMPR_TYPE_CD NUMBER) RETURN VARCHAR2;
    FUNCTION V_PORT_NAME_SEC1FormatTrigger (P_CURR_PORT_CD NUMBER) RETURN VARCHAR2;

    FUNCTION ARD_IMPR2210 (P_PARAMETER1   IN VARCHAR2 DEFAULT NULL,
                           P_PARAMETER2   IN VARCHAR2 DEFAULT NULL,
                           P_PARAMETER3   IN VARCHAR2 DEFAULT NULL,
                           P_PARAMETER4   IN VARCHAR2 DEFAULT NULL)
        RETURN CLOB;
END IMPR2210_ARD;
/
SHOW ERRORS


CREATE OR REPLACE PUBLIC SYNONYM IMPR2210_ARD FOR LIB_APX_USR.IMPR2210_ARD;


GRANT EXECUTE ON LIB_APX_USR.IMPR2210_ARD TO LIB_USR;

GRANT EXECUTE ON LIB_APX_USR.IMPR2210_ARD TO SECURITY_DEFAULT;

GRANT EXECUTE ON LIB_APX_USR.IMPR2210_ARD TO SECURITY_PROD;

GRANT EXECUTE ON LIB_APX_USR.IMPR2210_ARD TO CUSTOMS;
