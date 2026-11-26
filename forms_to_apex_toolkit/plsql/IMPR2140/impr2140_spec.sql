-- =============================================================================
-- Package     : IMPR2140             (upper-case form name, no prefix - f345 standard)
-- Source form : IMPR2140.fmb (Oracle Forms 12c) - report parameter form of the letters IMPR2141.rdf,
--               IMPR2142.rdf and IMPR2143.rdf "خطاب للمستورد" (one letter, picked by LETTER_DIRCTION)
-- Target      : Oracle APEX 21.2 / Oracle Database 12.1.0.2, reference application f345
--               page 2140 (IMPR2140) - report page: no search page, no DML
-- Author      : Claude Code
-- Created     : 2026-11-25
-- Version     : 001
-- Purpose     : Business logic of the form, organised like the form itself:
--               VERSION -> FORM LEVEL -> BLOCK CALLING_PARAMETERS (items in navigation order)
--               -> BLOCK TOOLBAR (PRINT) -> PROGRAM UNITS (PRINT_CHECK_VAL, PRINT_IMPR2141_ARD / 2142 / 2143).
--               Report-screen pattern of IMPR2110 / IMPR2130 (template: plsql/IMPR2130); one importer (IMPR_NO)
--               instead of an importer list, and the list item LETTER_DIRCTION picks the report.
-- Report      : IMPR2141.rdf / IMPR2142.rdf / IMPR2143.rdf are the ARD packages IMPR2141_ARD / IMPR2142_ARD /
--               IMPR2143_ARD (plsql/IMPR2140, standard 13-c, scripts/gen_ard_impr_reports.py).
--               REP.Run_Product becomes PRINT_IMPR214<n>_ARD, which returns the ardpdf link of the letter; the page
--               opens it in a new tab (standard 13-b). Report page buttons: PRINT, CLEAR, BACK only (DEC-017 / DEC-018):
--               Forms VIEW and PRINT both open the same PDF.
-- Parameters  : no I_ / IO_ / O_ prefix. Page item P2140_<ITEM> -> P_<ITEM> (P2140_P_PORT_CD -> P_PORT_CD,
--               no doubled P_P_); application items keep their name (P_CURR_PORT_CD). Inside SQL a
--               parameter is qualified with its member name. PRINT_IMPR214<n>_ARD are called by this package only
--               (public for tests): their parameters are p_<name> (internal style). Rule: scripts/parameter_names.py.
-- Rules       : every identifier <= 30 bytes (DB 12.1.0.2); no COMMIT / ROLLBACK; no V('...').
-- Owner       : LIB_APX_USR; public synonym IMPR2140 + EXECUTE grants at the end of this file.
--               LIB_APX_USR needs direct grants: SELECT on IMPORTERS, SD_PORTS, SC_USERS, CITIES, SMPL_LABS,
--               SMPL_REQUESTS, SMPL_ITEMS, SC_PORT_SETTING.
-- Status      : NOT COMPILED.
-- History     : 2026-11-25 Claude Code 001 Initial migration (letters as ARD packages IMPR2141_ARD .. IMPR2143_ARD,
--                          ARD_URL / ARD_DSNAME from SC_PORT_SETTING 999 / 99 - the IMPR2110 002 decisions;
--                          count of PRINT_CHECK_VAL kept as in Forms - user decision 2026-11-25)
-- =============================================================================
SET DEFINE OFF

CREATE OR REPLACE PACKAGE LIB_APX_USR.IMPR2140 AS
   V_PKG_VERSION       VARCHAR2 (100) := 'VERSION NO. IS:' || '001';
   V_PKG_VERSION_QC    VARCHAR2 (100) := 'VERSION NO. IS:' || '001';
   V_PKG_VERSION_DEV   VARCHAR2 (100) := 'VERSION NO. IS:' || '001';
   FUNCTION PKG_VERSION
      RETURN VARCHAR2;
   V_PACKAGE_NAME      VARCHAR2 (50) := 'IMPR2140';
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
    -- Source: WHEN-NEW-FORM-INSTANCE  SET_ITEM_PROPERTY('P_LOV_PORT' / 'P_PORT_NAME' / 'P_PORT_CD', VISIBLE, FALSE)
    --         when :PARAMETER.P_CURR_PORT_CD != 99 (a port user prints for his own port only).
    -- APEX  : Server-side condition of P2140_P_PORT_CD and P2140_P_PORT_NAME:
    --         IMPR2140.P_PORT_CD_IS_VISIBLE(P_CURR_PORT_CD => :P_CURR_PORT_CD)
    FUNCTION P_PORT_CD_IS_VISIBLE (P_CURR_PORT_CD IN VARCHAR2)
       RETURN BOOLEAN;

    -- Source: CALLING_PARAMETERS.P_PORT_CD.WHEN-VALIDATE-ITEM (check part): MESSAGE('NO_DATA_FOUND') + FTF.
    -- Returns the error text, NULL = OK.
    FUNCTION P_PORT_CD_VALIDATION (P_PORT_CD IN VARCHAR2)
       RETURN VARCHAR2;

    -- Source: CALLING_PARAMETERS.P_PORT_CD.WHEN-VALIDATE-ITEM (SELECT PORT_NAME INTO :P_PORT_NAME).
    -- APEX  : DA "P_PORT_CD WHEN-VALIDATE-ITEM" (FOS, Items to Return P2140_P_PORT_NAME).
    PROCEDURE P_PORT_CD_WHEN_VALIDATE_ITEM (P_PORT_CD   IN  VARCHAR2,
                                            P_PORT_NAME OUT VARCHAR2);

    -- Source: CALLING_PARAMETERS.LETTER_DIRCTION (List Item: 1 خطابات ديوان المراقبة, 2 خطابات إدارة التدقيق,
    --         3 خطابات قسم التدقيق بالجمرك; InitializeValue 1, Required)
    -- Returns the error text when LETTER_DIRCTION is not 1, 2 or 3, NULL = OK.
    -- SUGGESTION: new check (Forms list items allow only their values; the APEX select list can be posted with any value).
    FUNCTION LETTER_DIRCTION_VALIDATION (P_LETTER_DIRCTION IN VARCHAR2)
       RETURN VARCHAR2;

    -- Source: CALLING_PARAMETERS.IMPR_NO.WHEN-VALIDATE-ITEM (check part): 'رمزالمستورد غير موجود' + FTF.
    -- Returns the error text, NULL = OK (an empty IMPR_NO is checked by PRINT_CHECK_VAL).
    FUNCTION IMPR_NO_VALIDATION (P_IMPR_NO IN VARCHAR2)
       RETURN VARCHAR2;

    -- Source: CALLING_PARAMETERS.IMPR_NO.WHEN-VALIDATE-ITEM (SELECT DISTINCT ARBC_IMPR_NAME INTO :IMPR_NAME).
    -- APEX  : DA "IMPR_NO WHEN-VALIDATE-ITEM" (FOS, Items to Return P2140_IMPR_NAME); the Popup LOV P2140_IMPR_NO
    --         replaces IMPR_NO.KEY-LISTVAL / SECT_LOV.WHEN-BUTTON-PRESSED (CALL_FORM REP_LOV_IMPR).
    PROCEDURE IMPR_NO_WHEN_VALIDATE_ITEM (P_IMPR_NO   IN  VARCHAR2,
                                          P_IMPR_NAME OUT VARCHAR2);

    -- =========================================================================
    -- BLOCK TOOLBAR  (PRINT -> page 0 button REPORT_PRINT; VIEW / KEY-F5 open the same PDF, DEC-018)
    -- =========================================================================
    -- Source: PU PRINT_CHECK_VAL (TOOLBAR.PRINT.WHEN-BUTTON-PRESSED, KEY-PRINT, KEY-F4) and PU CHECK_VAL
    --         (TOOLBAR.VIEW, KEY-F5): IMPR_NO required, the count of the chosen letter (the PRINT_CHECK_VAL queries,
    --         user decision 2026-11-25), then REP.Run_Product of IMPR2141 / IMPR2142 / IMPR2143.
    -- APEX  : DA "REPORT_PRINT" (custom event of page 0): FOS, Items to Return P2140_REPORT_URL.
    PROCEDURE PRINT_CHECK_VAL (P_IMPR_NO         IN  VARCHAR2,
                               P_PORT_CD         IN  VARCHAR2,
                               P_LETTER_DIRCTION IN  VARCHAR2,
                               P_CURR_PORT_CD    IN  VARCHAR2,
                               P_REPORT_URL      OUT VARCHAR2);

    -- =========================================================================
    -- PROGRAM UNITS
    -- =========================================================================
    -- Source: REP.Run_Product(REPORTS, :PARAMETER.P_REPORT_PATH || :PARAMETER.P_REPORT_FILE, ..., pl_id)
    --         with P_REPORT_FILE 'IMPR2141.REP' (LETTER_DIRCTION 1), 'IMPR2142.REP' (2), 'IMPR2143.REP' (else).
    -- Return the ardpdf link of IMPR214<n>_ARD.ARD_IMPR214<n> (standard 13-c):
    --   <ARD_URL>?func_name=LIB_APX_USR.IMPR214<n>_ARD.ARD_IMPR214<n>&P_PARAMETER1=<port>&P_PARAMETER2=<IMPR_NO>&DsName=<ARD_DSNAME>
    --   P_PARAMETER1 P_CURR_PORT_CD = NVL(:P_PORT_CD, :PARAMETER.P_CURR_PORT_CD), P_PARAMETER2 IMPR_NO
    --   (the order of IMPR214<n>_ARD_spec.sql).
    --   ARD_URL / ARD_DSNAME: settings in SC_PORT_SETTING (SYSOBJ_ID 999, PORT_CD 99; migration/001_ard_settings.sql);
    --   missing -> error message. Not sent: DESTYPE, DESNAME, PARAMFORM, PRINTJOB, MAXIMIZE, ORACLE_SHUTDOWN (Reports
    --   Runtime options), P_REPORT_NO, P_MODULE_NAME, V_ORDER (not parameters of the letter reports).
    FUNCTION PRINT_IMPR2141_ARD (p_curr_port_cd IN VARCHAR2,
                                 p_impr_no      IN VARCHAR2)
       RETURN VARCHAR2;

    FUNCTION PRINT_IMPR2142_ARD (p_curr_port_cd IN VARCHAR2,
                                 p_impr_no      IN VARCHAR2)
       RETURN VARCHAR2;

    FUNCTION PRINT_IMPR2143_ARD (p_curr_port_cd IN VARCHAR2,
                                 p_impr_no      IN VARCHAR2)
       RETURN VARCHAR2;

    -- =========================================================================
    -- UI LOGIC FOR APEX DYNAMIC ACTIONS (comments only)
    -- =========================================================================
    -- APEX-DA: [Source: P_PORT_CD.KEY-LISTVAL, P_LOV_PORT.WHEN-BUTTON-PRESSED -> CALL_FORM REP_LOV_SD_PORTS]
    --          -> Popup LOV P2140_P_PORT_CD on LOV_SD_PORTS (IMPR1110); DA "P_PORT_CD WHEN-VALIDATE-ITEM".
    -- APEX-DA: [Source: IMPR_NO.KEY-LISTVAL, SECT_LOV.WHEN-BUTTON-PRESSED -> CALL_FORM REP_LOV_IMPR, NEXT_ITEM]
    --          -> Popup LOV P2140_IMPR_NO on LOV_IMPR2140_REP_IMPR; DA "IMPR_NO WHEN-VALIDATE-ITEM".
    -- APEX-DA: [Source: WHEN-NEW-FORM-INSTANCE GO_ITEM('LETTER_DIRCTION')] -> first visible item, no action needed.
    -- APEX-DA: [Source: KEY-CLRBLK, TOOLBAR.CLEAR] clear IMPR_NO, IMPR_NAME, P_PORT_CD, P_PORT_NAME -> page 0 button CLEAR.
    -- APEX-DA: [Source: TOOLBAR.VIEW, KEY-F5] -> page 0 REPORT_SHOW is Never (DEC-018): PRINT opens the PDF.
    -- APEX-DA: [Source: TOOLBAR.LOV] DO_KEY('LIST_VALUES') -> the Popup LOV buttons of the items.
    -- APEX-DA: [Source: TOOLBAR.EXIT] EXIT_FORM -> page 0 button BACK.
    -- APEX-DA: [Source: PRE-FORM, WHEN-WINDOW-ACTIVATED] window title / icon / date format -> f345 shell.
    -- APEX-DA: [Source: TITLE block, LOAD_ZATCA_LOGOS] -> hero region (module name, report number, port).

END IMPR2140;
/
SHOW ERRORS

-- -----------------------------------------------------------------------------
-- Synonym and grants (run as a user allowed to create public synonyms / grant on LIB_APX_USR)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PUBLIC SYNONYM IMPR2140 FOR LIB_APX_USR.IMPR2140;

GRANT EXECUTE ON LIB_APX_USR.IMPR2140 TO LIB_USR;

GRANT EXECUTE ON LIB_APX_USR.IMPR2140 TO SECURITY_DEFAULT;

GRANT EXECUTE ON LIB_APX_USR.IMPR2140 TO SECURITY_PROD;

-- CUSTOMS = parsing schema of the APEX application (APEX needs a direct grant, not a role)
GRANT EXECUTE ON LIB_APX_USR.IMPR2140 TO CUSTOMS;
