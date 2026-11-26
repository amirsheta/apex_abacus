-- =============================================================================
-- Package     : IMPR2220             (upper-case form name, no prefix - f345 standard)
-- Source form : IMPR2220.fmb (Oracle Forms 12c) - report parameter form of report IMPR2220.rdf
--               "تفويضات الشركات الوسيطة حسب الشركة" (authorizations grouped by brokerage company, report on AGNTS)
-- Target      : Oracle APEX 21.2 / Oracle Database 12.1.0.2, reference application f345
--               page 2220 (IMPR2220) - report page: no search page, no DML
-- Author      : Claude Code
-- Created     : 2026-11-26
-- Version     : 001
-- Purpose     : Business logic of the form, organised like the form itself:
--               VERSION -> FORM LEVEL -> BLOCK CALLING_PARAMETERS (items in navigation order)
--               -> BLOCK TOOLBAR (PRINT) -> PROGRAM UNITS (PRINT_CHECK_VAL, PRINT_IMPR2220_ARD).
--               Same screen as IMPR2210 (template: plsql/IMPR2210); the count runs on AGNTS / IMPORTERS with the
--               joins of the report query. The list LICE_NO holds the brokerage companies (AGNTS.IMPR_NBR_AGENT_ID,
--               screen label "رقم الشركة الوسيطة").
-- Report      : IMPR2220.rdf is the ARD package IMPR2220_ARD (IMPR2220_ARD_spec.sql / _body.sql, standard 13-c,
--               scripts/gen_ard_impr_reports.py).
--               REP.Run_Product becomes PRINT_IMPR2220_ARD, which returns the ardpdf link of
--               IMPR2220_ARD.ARD_IMPR2220; the page opens it in a new tab (standard 13-b). Report page buttons:
--               PRINT, CLEAR, BACK only (DEC-017 / DEC-018): Forms VIEW and PRINT both open the same PDF.
-- Parameters  : no I_ / IO_ / O_ prefix. Page item P2220_<ITEM> -> P_<ITEM> (P2220_P_PORT_CD -> P_PORT_CD,
--               no doubled P_P_); application items keep their name (P_CURR_PORT_CD). Inside SQL a
--               parameter is qualified with its member name. PRINT_IMPR2220_ARD is called by this package only
--               (public for tests): its parameters are p_<name> (internal style). Rule: scripts/parameter_names.py.
-- Rules       : every identifier <= 30 bytes (DB 12.1.0.2); no COMMIT / ROLLBACK; no V('...').
-- Owner       : LIB_APX_USR; public synonym IMPR2220 + EXECUTE grants at the end of this file.
--               LIB_APX_USR needs direct grants: SELECT on AGNTS, IMPORTERS, SD_PORTS, SC_PORT_SETTING.
-- Status      : NOT COMPILED.
-- History     : 2026-11-26 Claude Code 001 Initial migration (report as ARD package IMPR2220_ARD, ARD_URL / ARD_DSNAME
--                          from SC_PORT_SETTING 999 / 99 - the IMPR2110 002 decisions)
-- =============================================================================
SET DEFINE OFF

CREATE OR REPLACE PACKAGE LIB_APX_USR.IMPR2220 AS
   V_PKG_VERSION       VARCHAR2 (100) := 'VERSION NO. IS:' || '001';
   V_PKG_VERSION_QC    VARCHAR2 (100) := 'VERSION NO. IS:' || '001';
   V_PKG_VERSION_DEV   VARCHAR2 (100) := 'VERSION NO. IS:' || '001';
   FUNCTION PKG_VERSION
      RETURN VARCHAR2;
   V_PACKAGE_NAME      VARCHAR2 (50) := 'IMPR2220';
   V_LAST_MODIFY_DT    VARCHAR2 (10) := '26-11-2026';
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
    -- Source: WHEN-NEW-FORM-INSTANCE  SET_ITEM_PROPERTY('P_PORT_CD' / 'P_PORT_NAME' / 'P_LOV_PORT', VISIBLE, FALSE)
    --         when :PARAMETER.P_CURR_PORT_CD != 99 (a port user reports on his own port only).
    -- APEX  : Server-side condition of P2220_P_PORT_CD and P2220_P_PORT_NAME:
    --         IMPR2220.P_PORT_CD_IS_VISIBLE(P_CURR_PORT_CD => :P_CURR_PORT_CD)
    FUNCTION P_PORT_CD_IS_VISIBLE (P_CURR_PORT_CD IN VARCHAR2)
       RETURN BOOLEAN;

    -- Source: CALLING_PARAMETERS.P_PORT_CD.WHEN-VALIDATE-ITEM (check part): 'رمز الجمرك غير صحيح' + FTF.
    -- Returns the error text, NULL = OK.
    FUNCTION P_PORT_CD_VALIDATION (P_PORT_CD IN VARCHAR2)
       RETURN VARCHAR2;

    -- Source: CALLING_PARAMETERS.P_PORT_CD.WHEN-VALIDATE-ITEM (SELECT PORT_NAME INTO :P_PORT_NAME).
    -- APEX  : DA "P_PORT_CD WHEN-VALIDATE-ITEM" (FOS, Items to Return P2220_P_PORT_NAME).
    PROCEDURE P_PORT_CD_WHEN_VALIDATE_ITEM (P_PORT_CD   IN  VARCHAR2,
                                            P_PORT_NAME OUT VARCHAR2);

    -- Source: CALLING_PARAMETERS.LICE_NO (comma-separated importer numbers; split by CTR_BLK.WHEN-NEW-BLOCK-INSTANCE)
    -- Returns the error text when LICE_NO is not a list of numbers separated by commas, NULL = OK.
    -- SUGGESTION: new check. Forms put the text unchanged into the report lexical
    --             ' AND IMP.IMPR_NBR in ( <LICE_NO> )' (SQL injection into the report query).
    -- The Forms LICE_NO.WHEN-VALIDATE-ITEM name lookup ('هذا المستورد غير موجود', a message only, no FTF)
    -- is the name column of the region CTR_BLK.
    FUNCTION LICE_NO_VALIDATION (P_LICE_NO IN VARCHAR2)
       RETURN VARCHAR2;

    -- Source: CALLING_PARAMETERS.SECT_LOV.WHEN-BUTTON-PRESSED / LICE_NO.KEY-LISTVAL
    --         (CALL_FORM REP_LOV_IMPR, :LICE_NO := :GLOBAL.CHPT_CODE)
    -- SUGGESTION: IMPR2220 does not pass P_CURR_PORT_CD to REP_LOV_IMPR (IMPR2110 / IMPR2130 do), so in Forms the LOV
    --             lists the importers of the LOV form's default port 30. The APEX LOV LOV_IMPR2220_REP_IMPR uses
    --             NVL(P2220_P_PORT_CD, P_CURR_PORT_CD), the port the name lookup and the report use. To confirm.
    -- APEX  : the importer picked in the Popup LOV P2220_SECT_LOV is added to the list P2220_LICE_NO
    --         (skipped when already in it), and P2220_SECT_LOV is cleared for the next pick.
    PROCEDURE SECT_LOV_WHEN_BUTTON_PRESSED (P_SECT_LOV IN OUT VARCHAR2,
                                            P_LICE_NO  IN OUT VARCHAR2);

    -- =========================================================================
    -- BLOCK TOOLBAR  (PRINT -> page 0 button REPORT_PRINT; VIEW / KEY-F5 open the same PDF, DEC-018)
    -- =========================================================================
    -- Source: PU PRINT_CHECK_VAL (TOOLBAR.PRINT.WHEN-BUTTON-PRESSED, KEY-PRINT, KEY-F4) and PU CHECK_VAL
    --         (TOOLBAR.VIEW, KEY-F5): the same checks and the count of AGNTS rows (joins of the report),
    --         then REP.Run_Product of IMPR2220.
    -- APEX  : DA "REPORT_PRINT" (custom event of page 0): FOS, Items to Return P2220_REPORT_URL.
    --         P_HERO_TITLE = :PARAMETER.P_MODULE_NAME (module name, from FORMS_APX.HEADER_TITLE).
    PROCEDURE PRINT_CHECK_VAL (P_LICE_NO        IN  VARCHAR2,
                               P_PORT_CD        IN  VARCHAR2,
                               P_REPORT_NO      IN  VARCHAR2,
                               P_HERO_TITLE     IN  VARCHAR2,
                               P_MODULE_ID      IN  VARCHAR2,
                               P_CURR_PORT_CD   IN  VARCHAR2,
                               P_REPORT_URL     OUT VARCHAR2);

    -- =========================================================================
    -- PROGRAM UNITS
    -- =========================================================================
    -- Source: REP.Run_Product(REPORTS, :PARAMETER.P_REPORT_PATH || :PARAMETER.P_REPORT_FILE, ..., pl_id)
    -- Returns the ardpdf link of IMPR2220_ARD.ARD_IMPR2220 (standard 13-c):
    --   <ARD_URL>?func_name=LIB_APX_USR.IMPR2220_ARD.ARD_IMPR2220&P_PARAMETER1..5=...&DsName=<ARD_DSNAME>
    --   P_PARAMETER1 P_CURR_PORT_CD, P_PARAMETER2 brokerage company list (report parameter IMPR_NBR =
    --   :parameter.TRAN_SELECT ' AND IMP.IMPR_NBR in (<LICE_NO>)' in Forms, sent here as the number list),
    --   P_PARAMETER3 L_IMPR_NBR empty (the form does not send it: every importer), P_PARAMETER4 P_MODULE_NAME,
    --   P_PARAMETER5 P_REPORT_NO (the order of IMPR2220_ARD_spec.sql).
    --   ARD_URL / ARD_DSNAME: settings in SC_PORT_SETTING (SYSOBJ_ID 999, PORT_CD 99; migration/001_ard_settings.sql);
    --   missing -> error message. Not sent: DESTYPE, DESNAME, PARAMFORM, PRINTJOB, MAXIMIZE, ORACLE_SHUTDOWN,
    --   V_ORDER (Reports Runtime options / P_ORDER is NULL in Forms).
    FUNCTION PRINT_IMPR2220_ARD (p_impr_list      IN VARCHAR2,
                                 p_curr_port_cd   IN VARCHAR2,
                                 p_module_name    IN VARCHAR2,
                                 p_report_no      IN VARCHAR2)
       RETURN VARCHAR2;

    -- Source: PU P_ORDER - body is commented out in Forms (NULL): not converted.
    -- Source: PU CGDV$POPULATE_DYNAMIC_LISTS - fills item P_LICE_TYPE, which does not exist (call commented
    --         out in WHEN-NEW-FORM-INSTANCE): not converted.

    -- =========================================================================
    -- UI LOGIC FOR APEX DYNAMIC ACTIONS (comments only)
    -- =========================================================================
    -- APEX-DA: [Source: P_PORT_CD.KEY-LISTVAL, P_LOV_PORT.WHEN-BUTTON-PRESSED -> CALL_FORM REP_LOV_SD_PORTS]
    --          -> Popup LOV P2220_P_PORT_CD on LOV_SD_PORTS (IMPR1110); DA "P_PORT_CD WHEN-VALIDATE-ITEM".
    -- APEX-DA: [Source: CTR_BLK.WHEN-NEW-BLOCK-INSTANCE] split LICE_NO / GLOBAL.CHPT_ARB into records
    --          -> read-only grid CTR_BLK (SQL splits P2220_LICE_NO), refreshed by the P_PORT_CD / SECT_LOV DAs.
    -- APEX-DA: [Source: TOOLBAR.CLEAR] CLEAR_BLOCK x2 -> page 0 button CLEAR.
    -- APEX-DA: [Source: TOOLBAR.VIEW, KEY-F5] -> page 0 REPORT_SHOW is Never (DEC-018): PRINT opens the PDF.
    -- APEX-DA: [Source: TOOLBAR.LOV] DO_KEY('LIST_VALUES') -> the Popup LOV buttons of the items.
    -- APEX-DA: [Source: TOOLBAR.EXIT] EXIT_FORM -> page 0 button BACK.
    -- APEX-DA: [Source: PRE-FORM, WHEN-WINDOW-ACTIVATED] window title / icon / date format -> f345 shell.
    -- APEX-DA: [Source: TITLE block, LOAD_ZATCA_LOGOS] -> hero region (module name, report number, port).

END IMPR2220;
/
SHOW ERRORS

-- -----------------------------------------------------------------------------
-- Synonym and grants (run as a user allowed to create public synonyms / grant on LIB_APX_USR)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PUBLIC SYNONYM IMPR2220 FOR LIB_APX_USR.IMPR2220;

GRANT EXECUTE ON LIB_APX_USR.IMPR2220 TO LIB_USR;

GRANT EXECUTE ON LIB_APX_USR.IMPR2220 TO SECURITY_DEFAULT;

GRANT EXECUTE ON LIB_APX_USR.IMPR2220 TO SECURITY_PROD;

-- CUSTOMS = parsing schema of the APEX application (APEX needs a direct grant, not a role)
GRANT EXECUTE ON LIB_APX_USR.IMPR2220 TO CUSTOMS;
