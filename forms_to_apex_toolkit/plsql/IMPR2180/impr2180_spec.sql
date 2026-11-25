-- =============================================================================
-- Package     : IMPR2180             (upper-case form name, no prefix - f345 standard)
-- Source form : IMPR2180.fmb (Oracle Forms 12c) - report parameter form of IMPR2180.rdf
--               "تقرير ازدواجية مهنتي الإستيراد والتخليص الجمركي"
-- Target      : Oracle APEX 21.2 / Oracle Database 12.1.0.2, reference application f345
--               page 2180 (IMPR2180) - report page: no search page, no DML
-- Author      : Claude Code
-- Created     : 2026-11-25
-- Version     : 001
-- Purpose     : Business logic of the form, organised like the form itself:
--               VERSION -> FORM LEVEL -> BLOCK CONTROL (items in navigation order) -> BLOCK TOOLBAR (PRINT)
--               -> PROGRAM UNITS (PRINT_IMPR2180_ARD).
--               Report-screen pattern of IMPR2110 ... IMPR2170 (template: plsql/IMPR2170): the port (head office only)
--               and the licence type are sent to the report; Forms has no count check (V_COUNT := 1).
-- Report      : IMPR2180.rdf is the ARD package IMPR2180_ARD (plsql/IMPR2180, standard 13-c,
--               scripts/gen_ard_impr_reports.py). REP.Run_Product becomes PRINT_IMPR2180_ARD, which returns the ardpdf
--               link; the page opens it in a new tab (standard 13-b). Report page buttons: PRINT, CLEAR, BACK only
--               (DEC-017 / DEC-018): Forms VIEW and PRINT both open the same PDF.
-- Parameters  : no I_ / IO_ / O_ prefix. Page item P2180_<ITEM> -> P_<ITEM>; application items keep their name
--               (P_CURR_PORT_CD). Inside SQL a parameter is qualified with its member name. PRINT_IMPR2180_ARD is
--               called by this package only (public for tests): its parameters are p_<name> (internal style).
--               Rule: scripts/parameter_names.py.
-- Rules       : every identifier <= 30 bytes (DB 12.1.0.2); no COMMIT / ROLLBACK; no V('...').
-- Owner       : LIB_APX_USR; public synonym IMPR2180 + EXECUTE grants at the end of this file.
--               LIB_APX_USR needs direct grants: SELECT on SD_PORTS, SC_PORT_SETTING, CG_REF_CODES; EXECUTE on FORMS_APX.
-- Status      : NOT COMPILED.
-- History     : 2026-11-25 Claude Code 001 Initial migration (report as ARD package IMPR2180_ARD, ARD_URL / ARD_DSNAME
--                          from SC_PORT_SETTING 999 / 99 - the IMPR2110 002 decisions)
-- =============================================================================
SET DEFINE OFF

CREATE OR REPLACE PACKAGE LIB_APX_USR.IMPR2180 AS
   V_PKG_VERSION       VARCHAR2 (100) := 'VERSION NO. IS:' || '001';
   V_PKG_VERSION_QC    VARCHAR2 (100) := 'VERSION NO. IS:' || '001';
   V_PKG_VERSION_DEV   VARCHAR2 (100) := 'VERSION NO. IS:' || '001';
   FUNCTION PKG_VERSION
      RETURN VARCHAR2;
   V_PACKAGE_NAME      VARCHAR2 (50) := 'IMPR2180';
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
    --   SELECT PORT_NAME INTO :P_CURR_PORT_NAME FROM SD_PORTS WHERE PORT_CD = :PARAMETER.P_CURR_PORT_CD;
    --   (NO_DATA_FOUND -> NULL). LOAD_LIST -> the Select List P2180_P_LIC_TYPE on LOV_LIC_TYPE.
    --   The menu parameters P_SYS_ID / P_REP_NO come from SC_PORT_SETTING (port, SYSOBJ_ID = module id), as IMPR2110.
    -- APEX  : Process "WHEN-NEW-FORM-INSTANCE" (Before Header).
    PROCEDURE WHEN_NEW_FORM_INSTANCE (P_REPORT_NO        OUT VARCHAR2,
                                      P_CURR_PORT_NAME   OUT VARCHAR2,
                                      P_MODULE_ID        IN  VARCHAR2,
                                      P_CURR_PORT_CD     IN  VARCHAR2);

    -- Source: WHEN-NEW-FORM-INSTANCE, IF :PARAMETER.P_CURR_PORT_CD != 99 THEN SET_ITEM_PROPERTY('P_LOV_PORT' /
    --         'P_PORT_NAME' / 'P_PORT_CD', VISIBLE, PROPERTY_FALSE). TRUE = show them (head office, port 99).
    -- APEX  : server-side condition of P2180_P_PORT_CD and P2180_P_PORT_NAME.
    FUNCTION P_PORT_CD_IS_VISIBLE (P_CURR_PORT_CD IN VARCHAR2)
       RETURN BOOLEAN;

    -- =========================================================================
    -- BLOCK CONTROL  (control block: report parameters)
    -- =========================================================================
    -- Source: CONTROL.P_PORT_CD.WHEN-VALIDATE-ITEM
    --   IF :P_PORT_CD IS NOT NULL THEN SELECT PORT_NAME INTO :P_PORT_NAME FROM SD_PORTS WHERE PORT_CD = :P_PORT_CD;
    --   EXCEPTION WHEN NO_DATA_FOUND THEN RET := STR.DispArbMsg(1, 120, 'ERROR'); RAISE FORM_TRIGGER_FAILURE;
    -- Returns the Arabic message 1-120 for an unknown port, NULL = OK (empty is allowed: every port).
    FUNCTION P_PORT_CD_VALIDATION (P_PORT_CD IN VARCHAR2)
       RETURN VARCHAR2;

    -- Source: CONTROL.P_PORT_CD.WHEN-VALIDATE-ITEM (see P_PORT_CD_VALIDATION)
    -- APEX  : DA "P_PORT_CD WHEN-VALIDATE-ITEM": FOS, Items to Return P2180_P_PORT_NAME. The Popup LOV
    --         P2180_P_PORT_CD (LOV_SD_PORTS) replaces P_PORT_CD.KEY-LISTVAL / P_LOV_PORT (CALL_FORM REP_LOV_SD_PORTS).
    PROCEDURE P_PORT_CD_WHEN_VALIDATE_ITEM (P_PORT_CD   IN  VARCHAR2,
                                            P_PORT_NAME OUT VARCHAR2);

    -- Source: CONTROL.P_LIC_TYPE (List Item, filled by PU LOAD_LIST: CG_REF_CODES LIC_TYPE, RV_LOW_VALUE != 3; not
    --         Required, empty = every licence type in the report)
    -- Returns an error text when the value is not in that list, NULL = OK.
    -- SUGGESTION: new check (a Forms list item allows only its elements; an APEX item can be posted with any value).
    FUNCTION P_LIC_TYPE_VALIDATION (P_LIC_TYPE IN VARCHAR2)
       RETURN VARCHAR2;

    -- =========================================================================
    -- BLOCK TOOLBAR  (PRINT -> page 0 button REPORT_PRINT; VIEW / KEY-F5 open the same PDF, DEC-018)
    -- =========================================================================
    -- Source: PU PRINT_CHECK_VAL (TOOLBAR.PRINT «طباعة», KEY-PRINT, KEY-F4) and PU CHECK_VALUE (TOOLBAR.VIEW «عرض»,
    --         KEY-F5) - same code except DESTYPE:
    --   V_COUNT := 1;   (no check: the report always runs)
    --   IF :PARAMETER.P_CURR_PORT_CD = 99 THEN P_CURR_PORT_CD := :P_PORT_CD (NULL = every port)
    --   ELSE P_CURR_PORT_CD := :PARAMETER.P_CURR_PORT_CD; END IF;
    --   REP.Run_Product(IMPR2180.REP) with P_CURR_PORT_CD, P_REPORT_NO, p_lic_type (+ P_MODULE_NAME in CHECK_VALUE).
    -- APEX  : DA "REPORT_PRINT" (custom event of page 0): FOS, Items to Return P2180_REPORT_URL.
    PROCEDURE PRINT_CHECK_VAL (P_PORT_CD        IN  VARCHAR2,
                               P_LIC_TYPE       IN  VARCHAR2,
                               P_REPORT_NO      IN  VARCHAR2,
                               P_HERO_TITLE     IN  VARCHAR2,
                               P_CURR_PORT_CD   IN  VARCHAR2,
                               P_REPORT_URL     OUT VARCHAR2);

    -- =========================================================================
    -- PROGRAM UNITS
    -- =========================================================================
    -- Source: REP.Run_Product(REPORTS, :PARAMETER.P_REPORT_PATH || :PARAMETER.P_REPORT_FILE, SYNCHRONOUS, RUNTIME,
    --         FILESYSTEM, pl_id, NULL)
    -- Returns the ardpdf link of IMPR2180_ARD.ARD_IMPR2180 (standard 13-c), parameters in the order of IMPR2180_ARD.pks:
    --   P_PARAMETER1 P_CURR_PORT_CD, P_PARAMETER2 P_LIC_TYPE, P_PARAMETER3 P_MODULE_NAME, P_PARAMETER4 P_REPORT_NO.
    --   ARD_URL / ARD_DSNAME: settings in SC_PORT_SETTING (SYSOBJ_ID 999, PORT_CD 99; migration/001_ard_settings.sql);
    --   missing -> error message. Not sent: DESTYPE, DESNAME, PARAMFORM, PRINTJOB, MAXIMIZE, ORACLE_SHUTDOWN
    --   (Reports Runtime options; WIN_API_DIALOG.SELECT_PRINTER -> the browser print dialog of the PDF).
    FUNCTION PRINT_IMPR2180_ARD (p_curr_port_cd IN VARCHAR2,
                                 p_lic_type     IN VARCHAR2,
                                 p_module_name  IN VARCHAR2,
                                 p_report_no    IN VARCHAR2)
       RETURN VARCHAR2;

    -- =========================================================================
    -- UI LOGIC FOR APEX DYNAMIC ACTIONS (comments only)
    -- =========================================================================
    -- APEX-DA: [Source: P_PORT_CD.KEY-LISTVAL, P_LOV_PORT.WHEN-BUTTON-PRESSED -> CALL_FORM REP_LOV_SD_PORTS,
    --          :GLOBAL.PORT_CD / PORT_NAME] -> Popup LOV P2180_P_PORT_CD on LOV_SD_PORTS (IMPR1110). The LOV form got
    --          P_CURR_PORT_CD only for a port user, who never sees the item (hidden) - nothing to pass.
    -- APEX-DA: [Source: PU LOAD_LIST (WHEN-NEW-FORM-INSTANCE): CREATE_GROUP_FROM_QUERY GROUP_TYPE + POPULATE_LIST
    --          P_LIC_TYPE] -> Select List P2180_P_LIC_TYPE on LOV_LIC_TYPE
    --          (LOV_APX.REFERENCE_CODES(P_DOMAIN => 'LIC_TYPE', P_EXCLUDED_VALUE => '3')), with an empty entry.
    -- APEX-DA: [Source: PU PORTS] populates a list item PORT that does not exist in the form; not called (commented
    --          out in WHEN-NEW-FORM-INSTANCE) -> not converted.
    -- APEX-DA: [Source: WHEN-NEW-FORM-INSTANCE NEXT_ITEM] -> not needed.
    -- APEX-DA: [Source: TOOLBAR.CLEAR «مسح»] NEXT_BLOCK + CLEAR_BLOCK(NO_VALIDATE) x2 -> page 0 button CLEAR.
    -- APEX-DA: [Source: TOOLBAR.VIEW «عرض», KEY-F5 -> CHECK_VALUE] -> page 0 REPORT_SHOW is Never (DEC-018): PRINT
    --          opens the PDF.
    -- APEX-DA: [Source: TOOLBAR.LOV «قائمة»] DO_KEY('LIST_VALUES') -> the Popup LOV button of the item.
    -- APEX-DA: [Source: TOOLBAR.EXIT «خروج»] EXIT_FORM -> page 0 button BACK.
    -- APEX-DA: [Source: PRE-FORM, WHEN-WINDOW-ACTIVATED] window title / icon / date format -> f345 shell.
    -- APEX-DA: [Source: TITLE block (SYSTEM_DATE / SYSTEM_G_DATE WHEN-VALIDATE-ITEM, display items), LOAD_ZATCA_LOGOS]
    --          -> hero region (module name, report number, port).

END IMPR2180;
/
SHOW ERRORS

-- -----------------------------------------------------------------------------
-- Synonym and grants (run as a user allowed to create public synonyms / grant on LIB_APX_USR)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PUBLIC SYNONYM IMPR2180 FOR LIB_APX_USR.IMPR2180;

GRANT EXECUTE ON LIB_APX_USR.IMPR2180 TO LIB_USR;

GRANT EXECUTE ON LIB_APX_USR.IMPR2180 TO SECURITY_DEFAULT;

GRANT EXECUTE ON LIB_APX_USR.IMPR2180 TO SECURITY_PROD;

-- CUSTOMS = parsing schema of the APEX application (APEX needs a direct grant, not a role)
GRANT EXECUTE ON LIB_APX_USR.IMPR2180 TO CUSTOMS;
