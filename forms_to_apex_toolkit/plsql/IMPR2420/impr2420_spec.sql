-- =============================================================================
-- Package     : IMPR2420             (upper-case form name, no prefix - f345 standard)
-- Source form : IMPR2420.fmb (Oracle Forms 12c) - report parameter form of IMPR2420.rdf
--               "تقرير أخطاء المستوردين"
-- Target      : Oracle APEX 21.2 / Oracle Database 12.1.0.2, reference application f345
--               page 2420 (IMPR2420) - report page: no search page, no DML
-- Author      : Claude Code
-- Created     : 2026-11-26
-- Version     : 001
-- Purpose     : Business logic of the form, organised like the form itself:
--               VERSION -> FORM LEVEL -> BLOCK CALLING_PARAMETERS -> BLOCK TOOLBAR (PRINT)
--               -> PROGRAM UNITS (PRINT_IMPR2420_ARD).
--               Report-screen pattern of IMPR2110 ... IMPR2310 (template: plsql/IMPR2180): the only parameter is the
--               list item P_TYPE (expiry status); the report gets the user's own port; Forms has no count check
--               (V_COUNT := 1).
-- Report      : IMPR2420.rdf is the ARD package IMPR2420_ARD (plsql/IMPR2420, standard 13-c,
--               scripts/gen_ard_impr_reports.py). REP.Run_Product becomes PRINT_IMPR2420_ARD, which returns the ardpdf
--               link; the page opens it in a new tab (standard 13-b). Report page buttons: PRINT, CLEAR, BACK only
--               (DEC-017 / DEC-018): Forms VIEW and PRINT both open the same PDF.
-- Parameters  : no I_ / IO_ / O_ prefix. Page item P2420_<ITEM> -> P_<ITEM>; application items keep their name
--               (P_CURR_PORT_CD). Inside SQL a parameter is qualified with its member name. PRINT_IMPR2420_ARD is
--               called by this package only (public for tests): its parameters are p_<name> (internal style).
--               Rule: scripts/parameter_names.py.
-- Rules       : every identifier <= 30 bytes (DB 12.1.0.2); no COMMIT / ROLLBACK; no V('...').
-- Owner       : LIB_APX_USR; public synonym IMPR2420 + EXECUTE grants at the end of this file.
--               LIB_APX_USR needs direct grants: SELECT on SD_PORTS, SC_PORT_SETTING; EXECUTE on FORMS_APX.
-- Status      : NOT COMPILED.
-- History     : 2026-11-26 Claude Code 001 Initial migration (report as ARD package IMPR2420_ARD, ARD_URL / ARD_DSNAME
--                          from SC_PORT_SETTING 999 / 99 - the IMPR2110 002 decisions)
-- =============================================================================
SET DEFINE OFF

CREATE OR REPLACE PACKAGE LIB_APX_USR.IMPR2420 AS
   V_PKG_VERSION       VARCHAR2 (100) := 'VERSION NO. IS:' || '001';
   V_PKG_VERSION_QC    VARCHAR2 (100) := 'VERSION NO. IS:' || '001';
   V_PKG_VERSION_DEV   VARCHAR2 (100) := 'VERSION NO. IS:' || '001';
   FUNCTION PKG_VERSION
      RETURN VARCHAR2;
   V_PACKAGE_NAME      VARCHAR2 (50) := 'IMPR2420';
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
    --   (the SELECT of P_CURR_PORT_NAME from SD_PORTS is commented out in Forms; the f345 hero still shows the
    --   user's port name, read here - see the body)
    --   The menu parameters P_SYS_ID / P_REP_NO come from SC_PORT_SETTING (port, SYSOBJ_ID = module id), as IMPR2110.
    -- APEX  : Process "WHEN-NEW-FORM-INSTANCE" (Before Header).
    PROCEDURE WHEN_NEW_FORM_INSTANCE (P_REPORT_NO        OUT VARCHAR2,
                                      P_CURR_PORT_NAME   OUT VARCHAR2,
                                      P_MODULE_ID        IN  VARCHAR2,
                                      P_CURR_PORT_CD     IN  VARCHAR2);

    -- =========================================================================
    -- BLOCK CALLING_PARAMETERS  (report parameters)
    -- =========================================================================
    -- Source: CALLING_PARAMETERS.P_TYPE (List Item: 2 غير منتهي الصلاحية, 1 منتهي الصلاحية, 3 الجميع;
    --         InitializeValue 3, OtherValues 3)
    -- APEX  : static Select List P2420_P_TYPE (default 3, no null entry). No member: PU CHECK_VAL replaces an
    --         empty or unknown value by 3 (see PRINT_CHECK_VAL), it never shows an error.

    -- =========================================================================
    -- BLOCK TOOLBAR  (PRINT -> page 0 button REPORT_PRINT; VIEW / KEY-F5 open the same PDF, DEC-018)
    -- =========================================================================
    -- Source: PU PRINT_CHECK_VAL (TOOLBAR.PRINT «طباعة», KEY-PRINT, KEY-F4) and PU CHECK_VAL (TOOLBAR.VIEW «عرض»,
    --         KEY-F5):
    --   CHECK_VAL only: IF :P_TYPE IS NULL OR :P_TYPE NOT IN (1,2,3) THEN :P_TYPE := 3; END IF;
    --   V_COUNT := 1;   (no check: the report always runs)
    --   REP.Run_Product(IMPR2420.REP) with P_REPORT_NO, P_TYPE, P_MODULE_NAME, P_CURR_PORT_CD
    --   (CHECK_VAL also V_ORDER: always NULL, PU P_ORDER is commented out).
    -- APEX  : DA "REPORT_PRINT" (custom event of page 0): FOS, Items to Return P2420_P_TYPE, P2420_REPORT_URL.
    PROCEDURE PRINT_CHECK_VAL (P_TYPE           IN OUT VARCHAR2,
                               P_REPORT_NO      IN  VARCHAR2,
                               P_HERO_TITLE     IN  VARCHAR2,
                               P_CURR_PORT_CD   IN  VARCHAR2,
                               P_REPORT_URL     OUT VARCHAR2);

    -- =========================================================================
    -- PROGRAM UNITS
    -- =========================================================================
    -- Source: REP.Run_Product(REPORTS, :PARAMETER.P_REPORT_PATH || :PARAMETER.P_REPORT_FILE, SYNCHRONOUS, RUNTIME,
    --         FILESYSTEM, pl_id, NULL)
    -- Returns the ardpdf link of IMPR2420_ARD.ARD_IMPR2420 (standard 13-c), parameters in the order of IMPR2420_ARD_spec.sql:
    --   P_PARAMETER1 P_CURR_PORT_CD, P_PARAMETER2 P_TYPE, P_PARAMETER3 P_MODULE_NAME, P_PARAMETER4 P_REPORT_NO.
    --   ARD_URL / ARD_DSNAME: settings in SC_PORT_SETTING (SYSOBJ_ID 999, PORT_CD 99; migration/001_ard_settings.sql);
    --   missing -> error message. Not sent: DESTYPE, DESNAME, PARAMFORM, PRINTJOB, MAXIMIZE, ORACLE_SHUTDOWN, V_ORDER
    --   (Reports Runtime options / always NULL; WIN_API_DIALOG.SELECT_PRINTER -> the browser print dialog of the PDF).
    FUNCTION PRINT_IMPR2420_ARD (p_curr_port_cd IN VARCHAR2,
                                 p_type         IN VARCHAR2,
                                 p_module_name  IN VARCHAR2,
                                 p_report_no    IN VARCHAR2)
       RETURN VARCHAR2;

    -- =========================================================================
    -- UI LOGIC FOR APEX DYNAMIC ACTIONS (comments only)
    -- =========================================================================
    -- APEX-DA: [Source: P_TYPE List Item] -> static Select List P2420_P_TYPE (STATIC2, default 3, no null entry).
    -- APEX-DA: [Source: PU P_ORDER] body commented out (NULL) -> not converted; V_ORDER is never set.
    -- APEX-DA: [Source: PU CGDV$POPULATE_DYNAMIC_LISTS] body commented out (NULL), call commented out -> not converted.
    -- APEX-DA: [Source: WHEN-NEW-FORM-INSTANCE :GLOBAL.CHPT_CODE / CHPT_ARB := NULL] -> not needed (no LOV form).
    -- APEX-DA: [Source: TOOLBAR.CLEAR «مسح»] NEXT_BLOCK + CLEAR_BLOCK(NO_VALIDATE) x2 -> page 0 button CLEAR.
    -- APEX-DA: [Source: TOOLBAR.VIEW «عرض», KEY-F5 -> CHECK_VAL] -> page 0 REPORT_SHOW is Never (DEC-018): PRINT
    --          opens the PDF.
    -- APEX-DA: [Source: TOOLBAR.LOV «قائمة»] DO_KEY('LIST_VALUES') -> nothing to list (no LOV in the form).
    -- APEX-DA: [Source: TOOLBAR.EXIT «خروج»] EXIT_FORM -> page 0 button BACK.
    -- APEX-DA: [Source: PRE-FORM, WHEN-WINDOW-ACTIVATED] window title / icon / date format -> f345 shell.
    -- APEX-DA: [Source: TITLE block (SYSTEM_DATE / SYSTEM_G_DATE WHEN-VALIDATE-ITEM, display items), LOAD_ZATCA_LOGOS]
    --          -> hero region (module name, report number, port).

END IMPR2420;
/
SHOW ERRORS

-- -----------------------------------------------------------------------------
-- Synonym and grants (run as a user allowed to create public synonyms / grant on LIB_APX_USR)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PUBLIC SYNONYM IMPR2420 FOR LIB_APX_USR.IMPR2420;

GRANT EXECUTE ON LIB_APX_USR.IMPR2420 TO LIB_USR;

GRANT EXECUTE ON LIB_APX_USR.IMPR2420 TO SECURITY_DEFAULT;

GRANT EXECUTE ON LIB_APX_USR.IMPR2420 TO SECURITY_PROD;

-- CUSTOMS = parsing schema of the APEX application (APEX needs a direct grant, not a role)
GRANT EXECUTE ON LIB_APX_USR.IMPR2420 TO CUSTOMS;
