-- =============================================================================
-- Package     : IMPR2170             (upper-case form name, no prefix - f345 standard)
-- Source form : IMPR2170.fmb (Oracle Forms 12c) - report parameter form of IMPR2170.rdf "تقرير حالة مستورد"
-- Target      : Oracle APEX 21.2 / Oracle Database 12.1.0.2, reference application f345
--               page 2170 (IMPR2170) - report page: no search page, no DML
-- Author      : Claude Code
-- Created     : 2026-11-25
-- Version     : 001
-- Purpose     : Business logic of the form, organised like the form itself:
--               VERSION -> FORM LEVEL -> BLOCK CALLING_PARAMETERS (items in navigation order)
--               -> BLOCK TOOLBAR (PRINT) -> PROGRAM UNITS (PRINT_IMPR2170_ARD; COUNT_SUSP1 is private).
--               Report-screen pattern of IMPR2110 ... IMPR2150 (template: plsql/IMPR2150 and plsql/IMPR2140): the radio
--               group SELECT1 chooses one importer of a port (1) or a unified importer number (2).
-- Report      : IMPR2170.rdf is the ARD package IMPR2170_ARD (plsql/IMPR2170, standard 13-c,
--               scripts/gen_ard_impr_reports.py). REP.Run_Product becomes PRINT_IMPR2170_ARD, which returns the ardpdf
--               link; the page opens it in a new tab (standard 13-b). Report page buttons: PRINT, CLEAR, BACK only
--               (DEC-017 / DEC-018): Forms VIEW and PRINT both open the same PDF.
--               TODO: MISSING SOURCE IMPR2170n.rep - TITLE.SHOW_USER = 1 («اضافة اسم المستخدم») ran this second report,
--               which is not in forms/IMPR/reports; the check box is not converted (spec 12).
-- Parameters  : no I_ / IO_ / O_ prefix. Page item P2170_<ITEM> -> P_<ITEM>; application items keep their name
--               (P_CURR_PORT_CD). Inside SQL a parameter is qualified with its member name. PRINT_IMPR2170_ARD is
--               called by this package only (public for tests): its parameters are p_<name> (internal style).
--               Rule: scripts/parameter_names.py.
-- Rules       : every identifier <= 30 bytes (DB 12.1.0.2); no COMMIT / ROLLBACK; no V('...').
-- Owner       : LIB_APX_USR; public synonym IMPR2170 + EXECUTE grants at the end of this file.
--               LIB_APX_USR needs direct grants: SELECT on SD_PORTS, SC_PORT_SETTING, IMPORTERS, SINGLE_IMPORTERS,
--               IMPR_SUSPNS, IMPORTER_SEIZURES, HQ_IMPRS, BUS_ID_TYPES, CSTMS_INSTS, IMPR_DUTY_DIFF_BLKS,
--               IMPR_ACCUR_INSPCTNS, CASE_ACCUSEDS, CUSTOMS_CASES, IMPR_CNTRL_SUSPNS, WAIVERS, WVR_ITEMS,
--               IMPORTER_EXCLUDEDS, EXCLUSION_DECREES, WVR_ITEMS_GLOBALS; EXECUTE on FORMS_APX.
-- Status      : NOT COMPILED.
-- History     : 2026-11-25 Claude Code 001 Initial migration (report as ARD package IMPR2170_ARD, ARD_URL / ARD_DSNAME
--                          from SC_PORT_SETTING 999 / 99 - the IMPR2110 002 decisions; COUNT_SUSP1 kept as in Forms,
--                          as the IMPR2140 user decision of 2026-11-25)
-- =============================================================================
SET DEFINE OFF

CREATE OR REPLACE PACKAGE LIB_APX_USR.IMPR2170 AS
   V_PKG_VERSION       VARCHAR2 (100) := 'VERSION NO. IS:' || '001';
   V_PKG_VERSION_QC    VARCHAR2 (100) := 'VERSION NO. IS:' || '001';
   V_PKG_VERSION_DEV   VARCHAR2 (100) := 'VERSION NO. IS:' || '001';
   FUNCTION PKG_VERSION
      RETURN VARCHAR2;
   V_PACKAGE_NAME      VARCHAR2 (50) := 'IMPR2170';
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
    --   :SELECT1 := 1 -> item default of P2170_SELECT1; :P_PORT_CD := :PARAMETER.P_CURR_PORT_CD (port not 99) -> the
    --   port items are not shown for such a user, and every member below uses P_CURR_PORT_CD instead (ENB_DISP_FLDS).
    --   The menu parameters P_SYS_ID / P_REP_NO come from SC_PORT_SETTING (port, SYSOBJ_ID = module id), as IMPR2110.
    -- APEX  : Process "WHEN-NEW-FORM-INSTANCE" (Before Header).
    PROCEDURE WHEN_NEW_FORM_INSTANCE (P_REPORT_NO        OUT VARCHAR2,
                                      P_CURR_PORT_NAME   OUT VARCHAR2,
                                      P_MODULE_ID        IN  VARCHAR2,
                                      P_CURR_PORT_CD     IN  VARCHAR2);

    -- Source: PU ENB_DISP_FLDS (WHEN-NEW-RECORD-INSTANCE, SELECT1.WHEN-RADIO-CHANGED), branch P_CURR_PORT_CD != 99:
    --         SELECT1 radio buttons REP1 / REP2, P_PORT_CD, P_PORT_NAME, P_LOV_PORT, HQ_IMPR_NBR, HQ_LOV_IMPR and
    --         HQ_IMPR_NAME are VISIBLE false. TRUE = show them (head office, port 99).
    -- APEX  : server-side condition of P2170_SELECT1, P2170_P_PORT_CD, P2170_P_PORT_NAME, P2170_HQ_IMPR_NBR,
    --         P2170_HQ_IMPR_NAME.
    FUNCTION P_PORT_CD_IS_VISIBLE (P_CURR_PORT_CD IN VARCHAR2)
       RETURN BOOLEAN;

    -- =========================================================================
    -- BLOCK CALLING_PARAMETERS  (control block: report parameters)
    -- =========================================================================
    -- Source: CALLING_PARAMETERS.SELECT1 (Radio Group: 1 جمرك محدد, 2 جميع الجمارك; InitializeValue 1)
    -- Returns the error text when SELECT1 is not 1 or 2, NULL = OK.
    -- SUGGESTION: new check (a Forms radio group allows only its values; an APEX item can be posted with any value).
    FUNCTION SELECT1_VALIDATION (P_SELECT1 IN VARCHAR2)
       RETURN VARCHAR2;

    -- Source: CALLING_PARAMETERS.P_PORT_CD.WHEN-VALIDATE-ITEM (SELECT PORT_NAME INTO :P_PORT_NAME FROM SD_PORTS, no
    --         handler: an unknown port stopped with the Forms error FRM-40735 / ORA-01403)
    -- Returns 'رمز الجمرك غير صحيح' (the IMPR2110 text) for an unknown port, NULL = OK (empty is allowed here).
    FUNCTION P_PORT_CD_VALIDATION (P_PORT_CD IN VARCHAR2)
       RETURN VARCHAR2;

    -- Source: CALLING_PARAMETERS.P_PORT_CD.WHEN-VALIDATE-ITEM (see P_PORT_CD_VALIDATION)
    -- APEX  : DA "P_PORT_CD WHEN-VALIDATE-ITEM": FOS, Items to Return P2170_P_PORT_NAME. The Popup LOV
    --         P2170_P_PORT_CD (LOV_SD_PORTS) replaces P_PORT_CD.KEY-LISTVAL / P_LOV_PORT (CALL_FORM REP_LOV_SD_PORTS).
    PROCEDURE P_PORT_CD_WHEN_VALIDATE_ITEM (P_PORT_CD   IN  VARCHAR2,
                                            P_PORT_NAME OUT VARCHAR2);

    -- Source: CALLING_PARAMETERS.IMPR_NBR.WHEN-VALIDATE-ITEM
    --   SELECT ARBC_IMPR_NAME INTO :IMPR_NAME FROM IMPORTERS
    --    WHERE (PORT_CD = :P_PORT_CD OR :P_PORT_CD IS NULL) AND IMPR_NBR = :IMPR_NBR;
    --   EXCEPTION WHEN TOO_MANY_ROWS THEN DO_KEY('LIST_VALUES'); WHEN OTHERS THEN :IMPR_NBR := NULL;
    -- No row (or not a number): IMPR_NBR is cleared without a message, as in Forms. The port is P_CURR_PORT_CD for a
    -- user outside head office (ENB_DISP_FLDS sets P_PORT_CD to it).
    -- APEX  : DA "IMPR_NBR WHEN-VALIDATE-ITEM": Clear P2170_IMPR_NAME, then FOS, Items to Return P2170_IMPR_NBR,
    --         P2170_IMPR_NAME. The Popup LOV P2170_IMPR_NBR replaces IMPR_NBR.KEY-LISTVAL / LOV_IMPR (PU CHECK_LIST_VAL).
    PROCEDURE IMPR_NBR_WHEN_VALIDATE_ITEM (P_IMPR_NBR       IN OUT VARCHAR2,
                                           P_PORT_CD        IN     VARCHAR2,
                                           P_CURR_PORT_CD   IN     VARCHAR2,
                                           P_IMPR_NAME      OUT    VARCHAR2);

    -- Source: CALLING_PARAMETERS.HQ_IMPR_NBR.WHEN-VALIDATE-ITEM
    --   SELECT ARBC_IMPR_NAME INTO :HQ_IMPR_NAME FROM SINGLE_IMPORTERS WHERE HQ_IMPR_NBR = :HQ_IMPR_NBR;
    --   EXCEPTION WHEN TOO_MANY_ROWS THEN DO_KEY('LIST_VALUES'); WHEN OTHERS THEN GET_HQ_IMPR_NAME;
    --   PU GET_HQ_IMPR_NAME: SELECT ARBC_IMPR_NAME INTO :IMPR_NAME FROM IMPORTERS WHERE HQ_IMPR_NBR = :HQ_IMPR_NBR;
    --   (TOO_MANY_ROWS -> LOV, OTHERS -> NULL)
    -- APEX  : DA "HQ_IMPR_NBR WHEN-VALIDATE-ITEM": Clear P2170_HQ_IMPR_NAME, then FOS, Items to Return
    --         P2170_HQ_IMPR_NAME. The Popup LOV P2170_HQ_IMPR_NBR (LOV_IMPORT_HQ_NBR) replaces KEY-LISTVAL / HQ_LOV_IMPR.
    PROCEDURE HQ_IMPR_NBR_WHEN_VALIDATE_ITEM (P_HQ_IMPR_NBR  IN  VARCHAR2,
                                              P_HQ_IMPR_NAME OUT VARCHAR2);

    -- =========================================================================
    -- BLOCK TOOLBAR  (PRINT -> page 0 button REPORT_PRINT; VIEW / KEY-F4 open the same PDF, DEC-018)
    -- =========================================================================
    -- Source: PU PRINT_CHECK_VAL (TOOLBAR.ITEM303 «طباعة», KEY-F5) and PU CHECK_VAL (TOOLBAR.ITEM304 «عرض», KEY-F4) -
    --         same code except DESTYPE:
    --   IF :SELECT1 = 1 AND :IMPR_NBR IS NULL    -> 'الرجاء تحديد رقم المستورد' + FTF
    --   ELSIF :SELECT1 = 2 AND :HQ_IMPR_NBR IS NULL -> 'الرجاء تحديد رقم المستورد الموحد' + FTF
    --   ELSE V_COUNT := COUNT_SUSP1; IF V_COUNT > 0 THEN REP.Run_Product(IMPR2170.REP) with P_MODULE_NAME,
    --        P_CURR_PORT_CD, PPORT_CD, PSELECT1, PIMPR_NBR, PHQ_IMPR_NBR, P_REPORT_NO
    --        ELSE ' حالة المستورد سليمة ' + FTF.
    -- The values follow ENB_DISP_FLDS: outside head office SELECT1 = 1 and the port is P_CURR_PORT_CD; SELECT1 = 1
    -- clears HQ_IMPR_NBR, SELECT1 = 2 clears P_PORT_CD and IMPR_NBR.
    -- APEX  : DA "REPORT_PRINT" (custom event of page 0): FOS, Items to Return P2170_REPORT_URL.
    PROCEDURE PRINT_CHECK_VAL (P_SELECT1        IN  VARCHAR2,
                               P_PORT_CD        IN  VARCHAR2,
                               P_IMPR_NBR       IN  VARCHAR2,
                               P_HQ_IMPR_NBR    IN  VARCHAR2,
                               P_REPORT_NO      IN  VARCHAR2,
                               P_HERO_TITLE     IN  VARCHAR2,
                               P_CURR_PORT_CD   IN  VARCHAR2,
                               P_REPORT_URL     OUT VARCHAR2);

    -- =========================================================================
    -- PROGRAM UNITS
    -- =========================================================================
    -- Source: REP.Run_Product(REPORTS, :PARAMETER.P_REPORT_PATH || :PARAMETER.P_REPORT_FILE, SYNCHRONOUS, RUNTIME,
    --         FILESYSTEM, pl_id, NULL)
    -- Returns the ardpdf link of IMPR2170_ARD.ARD_IMPR2170 (standard 13-c), parameters in the order of IMPR2170_ARD.pks:
    --   P_PARAMETER1 P_CURR_PORT_CD, P_PARAMETER2 PPORT_CD, P_PARAMETER3 PSELECT1, P_PARAMETER4 PIMPR_NBR,
    --   P_PARAMETER5 PHQ_IMPR_NBR, P_PARAMETER6 P_MODULE_NAME, P_PARAMETER7 P_REPORT_NO.
    --   ARD_URL / ARD_DSNAME: settings in SC_PORT_SETTING (SYSOBJ_ID 999, PORT_CD 99; migration/001_ard_settings.sql);
    --   missing -> error message. Not sent: DESTYPE, PARAMFORM, PRINTJOB, MAXIMIZE, ORACLE_SHUTDOWN (Reports Runtime
    --   options), P_TYPE (0; not a parameter of the report).
    FUNCTION PRINT_IMPR2170_ARD (p_curr_port_cd IN VARCHAR2,
                                 p_pport_cd     IN VARCHAR2,
                                 p_pselect1     IN VARCHAR2,
                                 p_pimpr_nbr    IN VARCHAR2,
                                 p_phq_impr_nbr IN VARCHAR2,
                                 p_module_name  IN VARCHAR2,
                                 p_report_no    IN VARCHAR2)
       RETURN VARCHAR2;

    -- =========================================================================
    -- UI LOGIC FOR APEX DYNAMIC ACTIONS (comments only)
    -- =========================================================================
    -- APEX-DA: [Source: PU ENB_DISP_FLDS from SELECT1.WHEN-RADIO-CHANGED and CALLING_PARAMETERS.WHEN-NEW-RECORD-INSTANCE,
    --          head office branch] -> DA "SELECT1 WHEN-RADIO-CHANGED" (change + page load, client condition SELECT1 = 2):
    --          TRUE  (2): Clear P_PORT_CD, P_PORT_NAME, IMPR_NBR, IMPR_NAME; Disable P_PORT_CD, IMPR_NBR; Enable HQ_IMPR_NBR.
    --          FALSE (1): Clear HQ_IMPR_NBR, HQ_IMPR_NAME; Enable P_PORT_CD, IMPR_NBR; Disable HQ_IMPR_NBR.
    --          GO_ITEM('HQ_IMPR_NBR' / 'P_PORT_CD' / 'IMPR_NBR') -> not needed (the user clicks the item).
    -- APEX-DA: [Source: P_PORT_CD.KEY-LISTVAL, P_LOV_PORT.WHEN-BUTTON-PRESSED -> CALL_FORM REP_LOV_SD_PORTS,
    --          :GLOBAL.PORT_CD / PORT_NAME] -> Popup LOV P2170_P_PORT_CD on LOV_SD_PORTS (IMPR1110).
    -- APEX-DA: [Source: IMPR_NBR.KEY-LISTVAL, LOV_IMPR.WHEN-BUTTON-PRESSED -> PU CHECK_LIST_VAL (SELECT1 = 1) ->
    --          CALL_FORM LOV_IMPR_NBR, :GLOBAL.PORT_CD / IMPR_NBR / IMPR_NAME] -> Popup LOV P2170_IMPR_NBR on
    --          LOV_IMPR2170_LOV_IMPR_NBR (importers of P2170_P_PORT_CD, else of P_CURR_PORT_CD). The LOV form listed the
    --          importers of every port and also returned the port; a 21.2 Popup LOV returns one value, so the port is
    --          picked first (spec 12).
    -- APEX-DA: [Source: HQ_IMPR_NBR.KEY-LISTVAL, HQ_LOV_IMPR.WHEN-BUTTON-PRESSED -> PU CHECK_LIST_VAL (SELECT1 = 2) ->
    --          CALL_FORM LOV_IMPR_NBR, :GLOBAL.HQ_IMPR_NBR / IMPR_NAME] -> Popup LOV P2170_HQ_IMPR_NBR on
    --          LOV_IMPORT_HQ_NBR (IMPR2150, LOV_APX.SINGLE_IMPORTERS).
    -- APEX-DA: [Source: IMPR_NAME / HQ_IMPR_NAME WHEN-VALIDATE-ITEM, KEY-LISTVAL] empty triggers -> nothing.
    -- APEX-DA: [Source: TOOLBAR.ITEM305 «مسح»] CLEAR_BLOCK(NO_VALIDATE) -> page 0 button CLEAR.
    -- APEX-DA: [Source: TOOLBAR.ITEM304 «عرض», KEY-F4 -> CHECK_VAL] -> page 0 REPORT_SHOW is Never (DEC-018): PRINT
    --          opens the PDF. [KEY-PRINT] NULL in Forms.
    -- APEX-DA: [Source: TOOLBAR.ITEM306 «قائمة»] DO_KEY('LIST_VALUES') -> the Popup LOV button of the item.
    -- APEX-DA: [Source: TOOLBAR.ITEM307 «خروج»] EXIT_FORM -> page 0 button BACK. [KEY-NEXT-ITEM of the buttons] -> none.
    -- APEX-DA: [Source: PRE-FORM, WHEN-WINDOW-ACTIVATED] window title / icon / date format -> f345 shell.
    -- APEX-DA: [Source: TITLE block, LOAD_ZATCA_LOGOS] -> hero region (module name, report number, port).

END IMPR2170;
/
SHOW ERRORS

-- -----------------------------------------------------------------------------
-- Synonym and grants (run as a user allowed to create public synonyms / grant on LIB_APX_USR)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PUBLIC SYNONYM IMPR2170 FOR LIB_APX_USR.IMPR2170;

GRANT EXECUTE ON LIB_APX_USR.IMPR2170 TO LIB_USR;

GRANT EXECUTE ON LIB_APX_USR.IMPR2170 TO SECURITY_DEFAULT;

GRANT EXECUTE ON LIB_APX_USR.IMPR2170 TO SECURITY_PROD;

-- CUSTOMS = parsing schema of the APEX application (APEX needs a direct grant, not a role)
GRANT EXECUTE ON LIB_APX_USR.IMPR2170 TO CUSTOMS;
