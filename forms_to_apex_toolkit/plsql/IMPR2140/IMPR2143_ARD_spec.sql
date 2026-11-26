-- =============================================================================
-- Package     : IMPR2143_ARD   (report IMPR2143.rdf "خطاب للمستورد (رئيس قسم التدقيق والفروقات)" as an ARD report)
-- Source      : forms/IMPR/reports/impr2143.xml (Oracle Reports, data source CG$Q_SMPL_ITEMS)
-- Pattern     : ARD reports (Forms_to_APEX standard 13-c, DEC-014 / DEC-024), as plsql/Shared/DCLN3300_ARD
--               and plsql/IMPR2110/IMPR2110_ARD: ARD_IMPR2143 returns the report as HTML, the ARD server (ardpdf)
--               turns it into PDF.
-- Called from : page 2140 through IMPR2140.PRINT_IMPR2143_ARD (ardpdf link; plsql/IMPR2140/impr2140_body.sql). IMPR2140 picks the letter: LETTER_DIRCTION 1 = IMPR2141, 2 = IMPR2142, else IMPR2143.
-- Generated   : scripts/gen_ard_impr_reports.py (a change goes there, then re-run)
-- Author      : Claude Code      Created: 2026-11-25      Version: 001
-- Status      : NOT COMPILED. Depends on ARD_LOGO (static file LOGO1.jpg, DEC-034) and HIJDATE_DB.
-- =============================================================================
SET DEFINE OFF

CREATE OR REPLACE PACKAGE LIB_APX_USR.IMPR2143_ARD
AS
   V_PKG_VERSION       VARCHAR2 (100) := 'VERSION NO. IS:' || '001';
   V_PKG_VERSION_QC    VARCHAR2 (100) := 'VERSION NO. IS:' || '001';
   V_PKG_VERSION_DEV   VARCHAR2 (100) := 'VERSION NO. IS:' || '001';
   FUNCTION PKG_VERSION
      RETURN VARCHAR2;
   V_PACKAGE_NAME      VARCHAR2 (50) := 'IMPR2143_ARD';
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
    --   P_PARAMETER2   IMPR_NO            رقم المستورد (إجباري في الشاشة)
    -- IMPR_NO: رقم مستورد واحد. CF_PORT_MANGERFormula و V_PORT_CDFormula مش ظاهرين في الـ layout.

    -- الـ formula columns بتاعة الـ RDF بنفس الكود، بتتنادى من جوه الكويري أو اللوب زي الريفرنس
    FUNCTION V_PORT_NAME_SEC1FormatTrigger (P_CURR_PORT_CD NUMBER) RETURN VARCHAR2;

    FUNCTION ARD_IMPR2143 (P_PARAMETER1   IN VARCHAR2 DEFAULT NULL,
                           P_PARAMETER2   IN VARCHAR2 DEFAULT NULL)
        RETURN CLOB;
END IMPR2143_ARD;
/
SHOW ERRORS


CREATE OR REPLACE PUBLIC SYNONYM IMPR2143_ARD FOR LIB_APX_USR.IMPR2143_ARD;


GRANT EXECUTE ON LIB_APX_USR.IMPR2143_ARD TO LIB_USR;

GRANT EXECUTE ON LIB_APX_USR.IMPR2143_ARD TO SECURITY_DEFAULT;

GRANT EXECUTE ON LIB_APX_USR.IMPR2143_ARD TO SECURITY_PROD;

GRANT EXECUTE ON LIB_APX_USR.IMPR2143_ARD TO CUSTOMS;
