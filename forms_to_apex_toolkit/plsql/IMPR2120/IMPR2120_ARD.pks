-- =============================================================================
-- Package     : IMPR2120_ARD   (report IMPR2120.rdf "توقيفات المستوردين" as an ARD report)
-- Source      : forms/IMPR/reports/IMPR2120.xml (Oracle Reports, data source CG$Q_IMPR_SUSPNS)
-- Pattern     : ARD reports (Forms_to_APEX standard 13-c, DEC-014 / DEC-024), as plsql/Shared/DCLN3300_ARD
--               and plsql/IMPR2110/IMPR2110_ARD: ARD_IMPR2120 returns the report as HTML, the ARD server (ardpdf)
--               turns it into PDF.
-- Called from : page 2120 through IMPR2120.PRINT_IMPR2120_ARD (ardpdf link; plsql/IMPR2120/impr2120_body.sql).
-- Generated   : scripts/gen_ard_impr_reports.py (a change goes there, then re-run)
-- Author      : Claude Code      Created: 2026-11-25      Version: 001
-- Status      : NOT COMPILED. Depends on ARD_LOGO (static file LOGO1.jpg, DEC-034) and HIJDATE_DB.
-- =============================================================================
SET DEFINE OFF

CREATE OR REPLACE PACKAGE LIB_APX_USR.IMPR2120_ARD
AS
   V_PKG_VERSION       VARCHAR2 (100) := 'VERSION NO. IS:' || '001';
   V_PKG_VERSION_QC    VARCHAR2 (100) := 'VERSION NO. IS:' || '001';
   V_PKG_VERSION_DEV   VARCHAR2 (100) := 'VERSION NO. IS:' || '001';
   FUNCTION PKG_VERSION
      RETURN VARCHAR2;
   V_PACKAGE_NAME      VARCHAR2 (50) := 'IMPR2120_ARD';
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
    --   P_PARAMETER2   CG$P_IMPR_NBR      أرقام المستوردين مفصولة بفاصلة (فاضي = كل المستوردين)
    --   P_PARAMETER3   P_TYPE             حالة التوقيف 1 / 2 / 3 (P_TYPE في الشاشة)
    --   P_PARAMETER4   P_MODULE_NAME      عنوان التقرير
    --   P_PARAMETER5   P_REPORT_NO        رقم التقرير
    -- الفلتر: &CG$P_IMPR_NBR في الـ RDF هو :parameter.TRAN_SELECT في الفورم (" AND IMP.IMPR_NBR in (LICE_NO)")،
    -- هنا القايمة بتتقرا أرقام (من غير lexical) زي IMPR2110_ARD.
    -- TITFormula و C_CODEFormula مش ظاهرين في الـ layout فمش منقولين.

    -- الـ formula columns بتاعة الـ RDF بنفس الكود، بتتنادى من جوه الكويري أو اللوب زي الريفرنس
    FUNCTION C_PORT_CDFormula (P_PORT_CD NUMBER) RETURN VARCHAR2;
    FUNCTION C_DATEFormula RETURN DATE;
    FUNCTION V_MEANFormula (P_SUSPN_RLSE_DT DATE, P_SUSPN_STRT_DT DATE, P_SUSPN_END_DT DATE) RETURN VARCHAR2;
    FUNCTION V_PORT_NAME_SEC1FormatTrigger (P_CURR_PORT_CD NUMBER) RETURN VARCHAR2;

    FUNCTION ARD_IMPR2120 (P_PARAMETER1   IN VARCHAR2 DEFAULT NULL,
                           P_PARAMETER2   IN VARCHAR2 DEFAULT NULL,
                           P_PARAMETER3   IN VARCHAR2 DEFAULT NULL,
                           P_PARAMETER4   IN VARCHAR2 DEFAULT NULL,
                           P_PARAMETER5   IN VARCHAR2 DEFAULT NULL)
        RETURN CLOB;
END IMPR2120_ARD;
/
SHOW ERRORS


CREATE OR REPLACE PUBLIC SYNONYM IMPR2120_ARD FOR LIB_APX_USR.IMPR2120_ARD;


GRANT EXECUTE ON LIB_APX_USR.IMPR2120_ARD TO LIB_USR;

GRANT EXECUTE ON LIB_APX_USR.IMPR2120_ARD TO SECURITY_DEFAULT;

GRANT EXECUTE ON LIB_APX_USR.IMPR2120_ARD TO SECURITY_PROD;

GRANT EXECUTE ON LIB_APX_USR.IMPR2120_ARD TO CUSTOMS;
