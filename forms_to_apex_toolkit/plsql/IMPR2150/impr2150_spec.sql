-- =============================================================================
-- Package     : IMPR2150             (upper-case form name, no prefix - f345 standard)
-- Source form : IMPR2150.fmb (Oracle Forms 12c) - report parameter form of IMPR2150.rdf "استثناءات المستوردين"
--               (Forms module title "MAINTAIN IMPORTERS APPREVIATION CODES" is a copy from another form, not used)
-- Target      : Oracle APEX 21.2 / Oracle Database 12.1.0.2, reference application f345
--               page 2150 (IMPR2150) - report page: no search page, no DML
-- Author      : Claude Code
-- Created     : 2026-11-25
-- Version     : 001
-- Purpose     : Business logic of the form, organised like the form itself:
--               VERSION -> FORM LEVEL -> BLOCK CALLING_PARAMETERS (items in navigation order)
--               -> BLOCK TOOLBAR (PRINT) -> PROGRAM UNITS (PRINT_IMPR2150_ARD).
--               Report-screen pattern of IMPR2110 / IMPR2130 / IMPR2140 (template: plsql/IMPR2140); no port item,
--               one unified importer number (HQ_IMPR_NBR, optional = all importers), record status and rule type.
-- Report      : IMPR2150.rdf is the ARD package IMPR2150_ARD (plsql/IMPR2150, standard 13-c,
--               scripts/gen_ard_impr_reports.py). REP.Run_Product becomes PRINT_IMPR2150_ARD, which returns the ardpdf
--               link; the page opens it in a new tab (standard 13-b). Report page buttons: PRINT, CLEAR, BACK only
--               (DEC-017 / DEC-018): Forms VIEW and PRINT both open the same PDF.
-- Parameters  : no I_ / IO_ / O_ prefix. Page item P2150_<ITEM> -> P_<ITEM>; application items keep their name
--               (P_CURR_PORT_CD). Inside SQL a parameter is qualified with its member name. PRINT_IMPR2150_ARD is
--               called by this package only (public for tests): its parameters are p_<name> (internal style).
--               Rule: scripts/parameter_names.py.
-- Rules       : every identifier <= 30 bytes (DB 12.1.0.2); no COMMIT / ROLLBACK; no V('...').
-- Owner       : LIB_APX_USR; public synonym IMPR2150 + EXECUTE grants at the end of this file.
--               LIB_APX_USR needs direct grants: SELECT on SINGLE_IMPORTERS, BUS_ID_TYPES, IMPR_RULES, IMPR_RULE_PORTS,
--               CG_REF_CODES, SD_PORTS, SC_PORT_SETTING.
-- Status      : NOT COMPILED.
-- History     : 2026-11-25 Claude Code 001 Initial migration (report as ARD package IMPR2150_ARD, ARD_URL / ARD_DSNAME
--                          from SC_PORT_SETTING 999 / 99 - the IMPR2110 002 decisions; count of PRINT_CHECK_VAL kept as
--                          in Forms, as the IMPR2140 user decision of 2026-11-25)
-- =============================================================================
SET DEFINE OFF

CREATE OR REPLACE PACKAGE LIB_APX_USR.IMPR2150 AS
   V_PKG_VERSION       VARCHAR2 (100) := 'VERSION NO. IS:' || '001';
   V_PKG_VERSION_QC    VARCHAR2 (100) := 'VERSION NO. IS:' || '001';
   V_PKG_VERSION_DEV   VARCHAR2 (100) := 'VERSION NO. IS:' || '001';
   FUNCTION PKG_VERSION
      RETURN VARCHAR2;
   V_PACKAGE_NAME      VARCHAR2 (50) := 'IMPR2150';
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

    -- =========================================================================
    -- FORM LEVEL                                   (Forms: form-level triggers)
    -- =========================================================================
    -- Source: WHEN-NEW-FORM-INSTANCE (business part)
    --   :REPORT_NO := :PARAMETER.P_SYS_ID || '-' || :PARAMETER.P_REP_NO;
    --   P_CURR_PORT_NAME := SD_PORTS.PORT_NAME of :PARAMETER.P_CURR_PORT_CD when it is not 99.
    --   The menu parameters P_SYS_ID / P_REP_NO come from SC_PORT_SETTING (port, SYSOBJ_ID = module id),
    --   as in IMPR2110.
    -- APEX  : Process "WHEN-NEW-FORM-INSTANCE" (Before Header).
    PROCEDURE WHEN_NEW_FORM_INSTANCE (P_REPORT_NO        OUT VARCHAR2,
                                      P_CURR_PORT_NAME   OUT VARCHAR2,
                                      P_MODULE_ID        IN  VARCHAR2,
                                      P_CURR_PORT_CD     IN  VARCHAR2);

    -- =========================================================================
    -- BLOCK CALLING_PARAMETERS  (control block: report parameters)
    -- =========================================================================
    -- Source: CALLING_PARAMETERS.HQ_IMPR_NBR.WHEN-VALIDATE-ITEM (check part): any error of the two SELECT ... INTO
    --         (no or several SINGLE_IMPORTERS rows, no BUS_ID_TYPES row) ->
    --         'رقم المستورد المدخل غير صحيح، أدخل الرقم الصحيح أو استخدم القائمة المرفقة' + FTF.
    -- Returns the error text, NULL = OK (an empty HQ_IMPR_NBR means every importer).
    FUNCTION HQ_IMPR_NBR_VALIDATION (P_HQ_IMPR_NBR IN VARCHAR2)
       RETURN VARCHAR2;

    -- Source: CALLING_PARAMETERS.HQ_IMPR_NBR.WHEN-VALIDATE-ITEM (SELECT BUS_ID, BUS_ID_BRNCH, BUS_ID_TYPE_CD,
    --         ARBC_IMPR_NAME FROM SINGLE_IMPORTERS; SELECT BUS_ID_TYPE_NAME FROM BUS_ID_TYPES; empty number -> all NULL).
    -- APEX  : DA "HQ_IMPR_NBR WHEN-VALIDATE-ITEM": Clear the five items (Forms clears them on error too), then FOS
    --         with Items to Return P2150_BUS_ID, P2150_BUS_ID_BRNCH, P2150_BUS_ID_TYPE_CD, P2150_BUS_ID_TYPE_NAME,
    --         P2150_L_SI_ARBC_IMPR_NAME. The Popup LOV P2150_HQ_IMPR_NBR replaces HQ_IMPR_NBR.KEY-LISTVAL /
    --         HQ_IMPR_NBR2.WHEN-BUTTON-PRESSED (PU SINGLE_IMP_LOV, CALL_FORM LOV_IMPORT_HQ_NBR).
    PROCEDURE HQ_IMPR_NBR_WHEN_VALIDATE_ITEM (P_HQ_IMPR_NBR         IN  VARCHAR2,
                                              P_BUS_ID              OUT VARCHAR2,
                                              P_BUS_ID_BRNCH        OUT VARCHAR2,
                                              P_BUS_ID_TYPE_CD      OUT VARCHAR2,
                                              P_BUS_ID_TYPE_NAME    OUT VARCHAR2,
                                              P_L_SI_ARBC_IMPR_NAME OUT VARCHAR2);

    -- Source: CALLING_PARAMETERS.REC_STATUS (List Item: 1 فعال, 0 غير فعال; InitializeValue 1, Required)
    -- Returns the error text when REC_STATUS is not 1 or 0, NULL = OK.
    -- SUGGESTION: new check (a Forms list item allows only its values; the APEX select list can be posted with any value).
    FUNCTION REC_STATUS_VALIDATION (P_REC_STATUS IN VARCHAR2)
       RETURN VARCHAR2;

    -- Source: CALLING_PARAMETERS.RULE_TYPE (Required, InitializeValue 1, LOV LOV319 = CG_REF_CODES domain RULE_TYPE)
    -- Returns the error text when RULE_TYPE is empty or not a RULE_TYPE code, NULL = OK.
    -- SUGGESTION: the code check is new (Forms did not validate the typed value against LOV319).
    FUNCTION RULE_TYPE_VALIDATION (P_RULE_TYPE IN VARCHAR2)
       RETURN VARCHAR2;

    -- =========================================================================
    -- BLOCK TOOLBAR  (PRINT -> page 0 button REPORT_PRINT; VIEW / KEY-F5 open the same PDF, DEC-018)
    -- =========================================================================
    -- Source: PU PRINT_CHECK_VAL (TOOLBAR.PRINT.WHEN-BUTTON-PRESSED, KEY-PRINT, KEY-F4) and PU CHECK_VAL
    --         (TOOLBAR.VIEW, KEY-F5) - same code: the IMPR_RULES / IMPR_RULE_PORTS count (0 -> 'لا يوجد سجلات تحقق
    --         المطلوب'), then REP.Run_Product of IMPR2150.REP with P_HQ_IMPR_NBR, P_REC_STATUS, P_RULE_TYPE,
    --         P_REPORT_NO, P_MODULE_NAME. BUS_ID_BRNCH of the count is read again from SINGLE_IMPORTERS here (in Forms it
    --         is a read-only item set by HQ_IMPR_NBR WHEN-VALIDATE-ITEM).
    -- APEX  : DA "REPORT_PRINT" (custom event of page 0): FOS, Items to Return P2150_REPORT_URL.
    PROCEDURE PRINT_CHECK_VAL (P_HQ_IMPR_NBR    IN  VARCHAR2,
                               P_REC_STATUS     IN  VARCHAR2,
                               P_RULE_TYPE      IN  VARCHAR2,
                               P_REPORT_NO      IN  VARCHAR2,
                               P_HERO_TITLE     IN  VARCHAR2,
                               P_CURR_PORT_CD   IN  VARCHAR2,
                               P_REPORT_URL     OUT VARCHAR2);

    -- =========================================================================
    -- PROGRAM UNITS
    -- =========================================================================
    -- Source: REP.Run_Product(REPORTS, :PARAMETER.P_REPORT_PATH || 'IMPR2150.REP', SYNCHRONOUS, RUNTIME, FILESYSTEM, pl_id)
    -- Returns the ardpdf link of IMPR2150_ARD.ARD_IMPR2150 (standard 13-c), parameters in the order of IMPR2150_ARD_spec.sql:
    --   P_PARAMETER1 P_CURR_PORT_CD (port name of the report header; the form did not send it), P_PARAMETER2
    --   P_HQ_IMPR_NBR, P_PARAMETER3 P_REC_STATUS, P_PARAMETER4 P_RULE_TYPE, P_PARAMETER5 P_MODULE_NAME,
    --   P_PARAMETER6 P_REPORT_NO.
    --   ARD_URL / ARD_DSNAME: settings in SC_PORT_SETTING (SYSOBJ_ID 999, PORT_CD 99; migration/001_ard_settings.sql);
    --   missing -> error message. Not sent: DESTYPE, PARAMFORM, PRINTJOB, MAXIMIZE, ORACLE_SHUTDOWN (Reports Runtime
    --   options), V_ORDER (empty menu parameter, not a parameter of the report).
    FUNCTION PRINT_IMPR2150_ARD (p_curr_port_cd IN VARCHAR2,
                                 p_hq_impr_nbr  IN VARCHAR2,
                                 p_rec_status   IN VARCHAR2,
                                 p_rule_type    IN VARCHAR2,
                                 p_module_name  IN VARCHAR2,
                                 p_report_no    IN VARCHAR2)
       RETURN VARCHAR2;

    -- =========================================================================
    -- UI LOGIC FOR APEX DYNAMIC ACTIONS (comments only)
    -- =========================================================================
    -- APEX-DA: [Source: HQ_IMPR_NBR.KEY-LISTVAL, HQ_IMPR_NBR2.WHEN-BUTTON-PRESSED -> PU SINGLE_IMP_LOV -> CALL_FORM
    --          LOV_IMPORT_HQ_NBR, :GLOBAL.HQ_IMPR_NBR / BUS_ID / ARBC_IMPR_NAME] -> Popup LOV P2150_HQ_IMPR_NBR on
    --          LOV_IMPORT_HQ_NBR; DA "HQ_IMPR_NBR WHEN-VALIDATE-ITEM" fills the other items.
    -- APEX-DA: [Source: RULE_TYPE LOV319, ITEM318.WHEN-BUTTON-PRESSED, RULE_NAME] -> Select List P2150_RULE_TYPE on
    --          LOV_RULE_TYPE (IMPR1140): it shows the RV_MEANING that LOV319 returned into RULE_NAME.
    -- APEX-DA: [Source: BUS_ID_BRNCH.WHEN-VALIDATE-ITEM] the code is commented out in Forms (NULL;) -> nothing.
    -- APEX-DA: [Source: KEY-CLRBLK] NULL in Forms; [TOOLBAR.CLEAR] CLEAR_BLOCK -> page 0 button CLEAR.
    -- APEX-DA: [Source: TOOLBAR.VIEW, KEY-F5] -> page 0 REPORT_SHOW is Never (DEC-018): PRINT opens the PDF.
    -- APEX-DA: [Source: TOOLBAR.LOV] DO_KEY('LIST_VALUES') -> the Popup LOV button of the item.
    -- APEX-DA: [Source: TOOLBAR.EXIT] EXIT_FORM -> page 0 button BACK.
    -- APEX-DA: [Source: PRE-FORM, WHEN-WINDOW-ACTIVATED] window title / icon / date format -> f345 shell.
    -- APEX-DA: [Source: TITLE block, LOAD_ZATCA_LOGOS] -> hero region (module name, report number, port).

END IMPR2150;
/
SHOW ERRORS

-- -----------------------------------------------------------------------------
-- Synonym and grants (run as a user allowed to create public synonyms / grant on LIB_APX_USR)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PUBLIC SYNONYM IMPR2150 FOR LIB_APX_USR.IMPR2150;

GRANT EXECUTE ON LIB_APX_USR.IMPR2150 TO LIB_USR;

GRANT EXECUTE ON LIB_APX_USR.IMPR2150 TO SECURITY_DEFAULT;

GRANT EXECUTE ON LIB_APX_USR.IMPR2150 TO SECURITY_PROD;

-- CUSTOMS = parsing schema of the APEX application (APEX needs a direct grant, not a role)
GRANT EXECUTE ON LIB_APX_USR.IMPR2150 TO CUSTOMS;
