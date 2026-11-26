-- =============================================================================
-- Package     : IMPR2310             (upper-case form name, no prefix - f345 standard)
-- Source form : IMPR2310.fmb (Oracle Forms 12c) - report parameter form of IMPR2310.rdf
--               "بيانات المستوردين المعدلة / المضافة"
-- Target      : Oracle APEX 21.2 / Oracle Database 12.1.0.2, reference application f345
--               page 2310 (IMPR2310) - report page: no search page, no DML
-- Author      : Claude Code
-- Created     : 2026-11-26
-- Version     : 001
-- Purpose     : Business logic of the form, organised like the form itself:
--               VERSION -> FORM LEVEL -> BLOCK CALLING_PARAMETERS (items in navigation order)
--               -> BLOCK TOOLBAR (PRINT) -> PROGRAM UNITS (PRINT_IMPR2310_ARD; the count of PRINT_CHECK_VAL is private).
--               Report-screen pattern of IMPR2110 ... IMPR2230 (template: plsql/IMPR2170): the radio group SELECT1
--               chooses one importer (1) or a support letter / period (2); the radio group REPORT chooses the
--               modified (0) or the added (1) importers of the journal JOURNAL.IMPORTERS_JN.
-- Report      : IMPR2310.rdf is the ARD package IMPR2310_ARD (plsql/IMPR2310, standard 13-c,
--               scripts/gen_ard_impr_reports.py). REP.Run_Product becomes PRINT_IMPR2310_ARD, which returns the ardpdf
--               link; the page opens it in a new tab (standard 13-b). Report page buttons: PRINT, CLEAR, BACK only
--               (DEC-017 / DEC-018): Forms VIEW and PRINT both open the same PDF.
-- Parameters  : no I_ / IO_ / O_ prefix. Page item P2310_<ITEM> -> P_<ITEM>; application items keep their name
--               (P_CURR_PORT_CD). Inside SQL a parameter is qualified with its member name. PRINT_IMPR2310_ARD is
--               called by this package only (public for tests): its parameters are p_<name> (internal style).
--               Hijri dates arrive as text in FORMS_APX.HIJRI_DATE_FORMAT (the f345 Hijri picker).
--               Rule: scripts/parameter_names.py.
-- Rules       : every identifier <= 30 bytes (DB 12.1.0.2); no COMMIT / ROLLBACK; no V('...').
-- Owner       : LIB_APX_USR; public synonym IMPR2310 + EXECUTE grants at the end of this file.
--               LIB_APX_USR needs direct grants: SELECT on SD_PORTS, SC_PORT_SETTING, IMPORTERS,
--               JOURNAL.IMPORTERS_JN; EXECUTE on FORMS_APX.
-- Status      : NOT COMPILED.
-- History     : 2026-11-26 Claude Code 001 Initial migration (report as ARD package IMPR2310_ARD, ARD_URL / ARD_DSNAME
--                          from SC_PORT_SETTING 999 / 99 - the IMPR2110 002 decisions; the PRINT_CHECK_VAL count kept
--                          as in Forms, as the IMPR2140 user decision of 2026-11-25)
-- =============================================================================
SET DEFINE OFF

CREATE OR REPLACE PACKAGE LIB_APX_USR.IMPR2310 AS
   V_PKG_VERSION       VARCHAR2 (100) := 'VERSION NO. IS:' || '001';
   V_PKG_VERSION_QC    VARCHAR2 (100) := 'VERSION NO. IS:' || '001';
   V_PKG_VERSION_DEV   VARCHAR2 (100) := 'VERSION NO. IS:' || '001';
   FUNCTION PKG_VERSION
      RETURN VARCHAR2;
   V_PACKAGE_NAME      VARCHAR2 (50) := 'IMPR2310';
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
    --   :SELECT1 := 2 -> item default of P2310_SELECT1 (the XML InitializeValue 1 is overwritten here);
    --   the Enable / Disable lines -> DA "SELECT1 WHEN-RADIO-CHANGED" on page load;
    --   P_CURR_PORT_NAME := SD_PORTS.PORT_NAME of :PARAMETER.P_CURR_PORT_CD when it is not 99, and then
    --   :P_PORT_CD := :PARAMETER.P_CURR_PORT_CD and P_PORT_CD / P_PORT_NAME / P_LOV_PORT are not visible -> the port
    --   items are not shown for such a user, and PRINT_CHECK_VAL uses P_CURR_PORT_CD instead.
    --   The menu parameters P_SYS_ID / P_REP_NO come from SC_PORT_SETTING (port, SYSOBJ_ID = module id), as IMPR2110.
    -- APEX  : Process "WHEN-NEW-FORM-INSTANCE" (Before Header).
    PROCEDURE WHEN_NEW_FORM_INSTANCE (P_REPORT_NO        OUT VARCHAR2,
                                      P_CURR_PORT_NAME   OUT VARCHAR2,
                                      P_MODULE_ID        IN  VARCHAR2,
                                      P_CURR_PORT_CD     IN  VARCHAR2);

    -- Source: WHEN-NEW-FORM-INSTANCE, branch :PARAMETER.P_CURR_PORT_CD != 99: P_PORT_CD, P_PORT_NAME and P_LOV_PORT
    --         are VISIBLE false. TRUE = show them (head office, port 99).
    -- APEX  : server-side condition of P2310_P_PORT_CD and P2310_P_PORT_NAME.
    FUNCTION P_PORT_CD_IS_VISIBLE (P_CURR_PORT_CD IN VARCHAR2)
       RETURN BOOLEAN;

    -- =========================================================================
    -- BLOCK CALLING_PARAMETERS  (control block: report parameters)
    -- =========================================================================
    -- Source: CALLING_PARAMETERS.P_PORT_CD.WHEN-VALIDATE-ITEM (SELECT PORT_NAME INTO :P_PORT_NAME FROM SD_PORTS, no
    --         handler: an unknown port stopped with the Forms error FRM-40735 / ORA-01403)
    -- Returns 'رمز الجمرك غير صحيح' (the IMPR2110 text) for an unknown port, NULL = OK (empty is allowed here).
    FUNCTION P_PORT_CD_VALIDATION (P_PORT_CD IN VARCHAR2)
       RETURN VARCHAR2;

    -- Source: CALLING_PARAMETERS.P_PORT_CD.WHEN-VALIDATE-ITEM (see P_PORT_CD_VALIDATION)
    -- APEX  : DA "P_PORT_CD WHEN-VALIDATE-ITEM": FOS, Items to Return P2310_P_PORT_NAME. The Popup LOV
    --         P2310_P_PORT_CD (LOV_SD_PORTS) replaces P_PORT_CD.KEY-LISTVAL / P_LOV_PORT (CALL_FORM REP_LOV_SD_PORTS).
    PROCEDURE P_PORT_CD_WHEN_VALIDATE_ITEM (P_PORT_CD   IN  VARCHAR2,
                                            P_PORT_NAME OUT VARCHAR2);

    -- Source: CALLING_PARAMETERS.REPORT (Radio Group REP1 = 0 تعديلات بيانات المستوردين, REP2 = 1 إضافة مستوردين جدد;
    --         InitializeValue 0)
    -- Returns the error text when REPORT is not 0 or 1, NULL = OK.
    -- SUGGESTION: new check (a Forms radio group allows only its values; an APEX item can be posted with any value).
    FUNCTION REPORT_VALIDATION (P_REPORT IN VARCHAR2)
       RETURN VARCHAR2;

    -- Source: CALLING_PARAMETERS.SELECT1 (Radio Group S1 = 1 حسب رقم المستورد, S2 = 2 حسب الخطاب; set to 2 by
    --         WHEN-NEW-FORM-INSTANCE)
    -- Returns the error text when SELECT1 is not 1 or 2, NULL = OK.
    -- SUGGESTION: new check, as REPORT_VALIDATION.
    FUNCTION SELECT1_VALIDATION (P_SELECT1 IN VARCHAR2)
       RETURN VARCHAR2;

    -- Source: CALLING_PARAMETERS.IMPR_NBR.WHEN-VALIDATE-ITEM
    --   SELECT ARBC_IMPR_NAME INTO :IMPR_NAME FROM IMPORTERS WHERE --PORT_CD = :P_PORT_CD AND
    --   IMPR_NBR = :IMPR_NBR;
    --   EXCEPTION WHEN TOO_MANY_ROWS THEN DO_KEY('LIST_VALUES'); WHEN OTHERS THEN :IMPR_NBR := NULL;
    -- The port condition is commented out in Forms: the number is looked up in every port (kept).
    -- No row (or not a number): IMPR_NBR is cleared without a message, as in Forms.
    -- APEX  : DA "IMPR_NBR WHEN-VALIDATE-ITEM": Clear P2310_IMPR_NAME, then FOS, Items to Return P2310_IMPR_NBR,
    --         P2310_IMPR_NAME. The Popup LOV P2310_IMPR_NBR replaces IMPR_NBR.KEY-LISTVAL / LOV_IMPR (PU CHECK_LIST_VAL).
    PROCEDURE IMPR_NBR_WHEN_VALIDATE_ITEM (P_IMPR_NBR  IN OUT VARCHAR2,
                                           P_IMPR_NAME OUT    VARCHAR2);

    -- Source: LTR_DATE / START_DT / END_DT WHEN-VALIDATE-ITEM (object library CGSO$HDATE: HIJDATE.VALID_HIJ_DATE)
    -- APEX  : no member here (CLAUDE.md 4a rule 3): the DAs "<ITEM> WHEN-VALIDATE-ITEM" call
    --         FORMS_APX.CHECK_ERROR(FORMS_APX.HIJRI_DATE_ERROR(:P2310_<ITEM>)) directly, as IMPR1160 AWARD_DATE;
    --         PRINT_CHECK_VAL checks the three dates again.

    -- =========================================================================
    -- BLOCK TOOLBAR  (PRINT -> page 0 button REPORT_PRINT; VIEW / KEY-F4 open the same PDF, DEC-018)
    -- =========================================================================
    -- Source: PU PRINT_CHECK_VAL (TOOLBAR.ITEM303 «طباعة», KEY-F5) and PU CHECK_VAL (TOOLBAR.ITEM304 «عرض», KEY-F4) -
    --         same code except DESTYPE:
    --   IF :SELECT1 = 1 AND :IMPR_NBR IS NULL -> MESSAGE 'الرجاء تحديد رقم المستورد'
    --   ELSIF :SELECT1 = 2 AND :LTR_NBR IS NULL AND (:START_DT IS NULL OR :END_DT IS NULL)
    --        -> MESSAGE 'الرجاء إدخال بيانات الخطاب أو الفترة'
    --   ELSE V_COUNT := COUNT(IMP.IMPR_NBR) FROM JOURNAL.IMPORTERS_JN (REPORT, SELECT1, the letter / period filter -
    --        no port); IF V_COUNT > 0 THEN REP.Run_Product(IMPR2310.REP) with P_MODULE_NAME, P_CURR_PORT_CD
    --        (= :P_PORT_CD), SELECT1, REPORT1 (= :REPORT), P_IMPR_NBR, LTR_NBR, LTR_DATE, SUPP_SRCE_CD, START_DT, END_DT
    --        (dates MI-MM-RRRR), P_REPORT_NO ELSE MESSAGE 'لا يوجد سجلات تحقق المطلوب' + FTF.
    -- The values follow SELECT1.WHEN-RADIO-CHANGED: SELECT1 = 1 clears the letter / period items, SELECT1 = 2 clears
    -- IMPR_NBR. The port: P_CURR_PORT_CD outside head office (WHEN-NEW-FORM-INSTANCE), else the port item, else
    -- P_CURR_PORT_CD (as IMPR2130).
    -- APEX  : DA "REPORT_PRINT" (custom event of page 0): FOS, Items to Return P2310_REPORT_URL.
    PROCEDURE PRINT_CHECK_VAL (P_SELECT1        IN  VARCHAR2,
                               P_REPORT         IN  VARCHAR2,
                               P_PORT_CD        IN  VARCHAR2,
                               P_IMPR_NBR       IN  VARCHAR2,
                               P_LTR_NBR        IN  VARCHAR2,
                               P_LTR_DATE       IN  VARCHAR2,
                               P_SUPP_SRCE_CD   IN  VARCHAR2,
                               P_START_DT       IN  VARCHAR2,
                               P_END_DT         IN  VARCHAR2,
                               P_REPORT_NO      IN  VARCHAR2,
                               P_HERO_TITLE     IN  VARCHAR2,
                               P_CURR_PORT_CD   IN  VARCHAR2,
                               P_REPORT_URL     OUT VARCHAR2);

    -- =========================================================================
    -- PROGRAM UNITS
    -- =========================================================================
    -- Source: REP.Run_Product(REPORTS, :PARAMETER.P_REPORT_PATH || :PARAMETER.P_REPORT_FILE, SYNCHRONOUS, RUNTIME,
    --         FILESYSTEM, pl_id, NULL)
    -- Returns the ardpdf link of IMPR2310_ARD.ARD_IMPR2310 (standard 13-c), parameters in the order of IMPR2310_ARD_spec.sql:
    --   P_PARAMETER1 P_CURR_PORT_CD, P_PARAMETER2 SELECT1, P_PARAMETER3 REPORT1, P_PARAMETER4 P_IMPR_NBR,
    --   P_PARAMETER5 LTR_NBR, P_PARAMETER6 LTR_DATE, P_PARAMETER7 SUPP_SRCE_CD, P_PARAMETER8 START_DT,
    --   P_PARAMETER9 END_DT, P_PARAMETER10 P_MODULE_NAME, P_PARAMETER11 P_REPORT_NO.
    --   The three dates are sent as text 'YYYY-MM-MI' (the format IMPR2310_ARD reads; Forms sent MI-MM-RRRR).
    --   ARD_URL / ARD_DSNAME: settings in SC_PORT_SETTING (SYSOBJ_ID 999, PORT_CD 99; migration/001_ard_settings.sql);
    --   missing -> error message. Not sent: DESTYPE, PARAMFORM, PRINTJOB, MAXIMIZE, ORACLE_SHUTDOWN (Reports Runtime
    --   options).
    FUNCTION PRINT_IMPR2310_ARD (p_curr_port_cd IN VARCHAR2,
                                 p_select1      IN VARCHAR2,
                                 p_report1      IN VARCHAR2,
                                 p_impr_nbr     IN VARCHAR2,
                                 p_ltr_nbr      IN VARCHAR2,
                                 p_ltr_date     IN VARCHAR2,
                                 p_supp_srce_cd IN VARCHAR2,
                                 p_start_dt     IN VARCHAR2,
                                 p_end_dt       IN VARCHAR2,
                                 p_module_name  IN VARCHAR2,
                                 p_report_no    IN VARCHAR2)
       RETURN VARCHAR2;

    -- =========================================================================
    -- UI LOGIC FOR APEX DYNAMIC ACTIONS (comments only)
    -- =========================================================================
    -- APEX-DA: [Source: SELECT1.WHEN-RADIO-CHANGED and the Enable / Disable lines of WHEN-NEW-FORM-INSTANCE] ->
    --          DA "SELECT1 WHEN-RADIO-CHANGED" (change + page load, client condition SELECT1 = 2):
    --          TRUE  (2): Clear IMPR_NBR, IMPR_NAME; Disable IMPR_NBR; Enable LTR_NBR, LTR_DATE, SUPP_SRCE_CD, START_DT, END_DT.
    --          FALSE (1): Clear LTR_NBR, LTR_DATE, SUPP_SRCE_CD, START_DT, END_DT; Disable them; Enable IMPR_NBR.
    --          IMPR_NAME / LOV_IMPR: Display Only item / the Popup LOV button of IMPR_NBR.
    --          GO_ITEM('IMPR_NBR' / 'LTR_NBR') -> not needed (the user clicks the item).
    -- APEX-DA: [Source: P_PORT_CD.KEY-LISTVAL, P_LOV_PORT.WHEN-BUTTON-PRESSED -> CALL_FORM REP_LOV_SD_PORTS,
    --          :GLOBAL.PORT_CD / PORT_NAME] -> Popup LOV P2310_P_PORT_CD on LOV_SD_PORTS (IMPR1110).
    -- APEX-DA: [Source: IMPR_NBR.KEY-LISTVAL, LOV_IMPR.WHEN-BUTTON-PRESSED -> PU CHECK_LIST_VAL -> CALL_FORM LOV_IMPR
    --          (no port: every port), :GLOBAL.IMPR_NBR / IMPR_NAME] -> Popup LOV P2310_IMPR_NBR on LOV_IMPR2310_LOV_IMPR
    --          (importers of P2310_P_PORT_CD, else of P_CURR_PORT_CD - the port the report filters on; spec 12).
    -- APEX-DA: [Source: LTR_NBR.KEY-LISTVAL, SUPP_SRCE_CD.KEY-LISTVAL -> PU CHECK_LIST_VAL] the importer LOV writes
    --          IMPR_NBR / IMPR_NAME (disabled while these items are enabled) -> not converted (spec 12).
    -- APEX-DA: [Source: LTR_DATE / START_DT / END_DT KEY-LISTVAL (object library calendar)] -> f345 Hijri picker
    --          (class hijri-date-default).
    -- APEX-DA: [Source: IMPR_NAME WHEN-VALIDATE-ITEM, KEY-LISTVAL (object library, no code)] -> nothing.
    -- APEX-DA: [Source: TOOLBAR.ITEM305 «مسح»] CLEAR_BLOCK(NO_VALIDATE) -> page 0 button CLEAR.
    -- APEX-DA: [Source: TOOLBAR.ITEM304 «عرض», KEY-F4 -> CHECK_VAL] -> page 0 REPORT_SHOW is Never (DEC-018): PRINT
    --          opens the PDF. [KEY-PRINT] NULL in Forms.
    -- APEX-DA: [Source: TOOLBAR.ITEM306 «قائمة»] DO_KEY('LIST_VALUES') -> the Popup LOV button of the item.
    -- APEX-DA: [Source: TOOLBAR.ITEM307 «خروج»] EXIT_FORM -> page 0 button BACK. [KEY-NEXT-ITEM of the buttons] -> none.
    -- APEX-DA: [Source: PRE-FORM, WHEN-WINDOW-ACTIVATED] window title / icon / date format -> f345 shell.
    -- APEX-DA: [Source: TITLE block, LOAD_ZATCA_LOGOS] -> hero region (module name, report number, port).

END IMPR2310;
/
SHOW ERRORS

-- -----------------------------------------------------------------------------
-- Synonym and grants (run as a user allowed to create public synonyms / grant on LIB_APX_USR)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PUBLIC SYNONYM IMPR2310 FOR LIB_APX_USR.IMPR2310;

GRANT EXECUTE ON LIB_APX_USR.IMPR2310 TO LIB_USR;

GRANT EXECUTE ON LIB_APX_USR.IMPR2310 TO SECURITY_DEFAULT;

GRANT EXECUTE ON LIB_APX_USR.IMPR2310 TO SECURITY_PROD;

-- CUSTOMS = parsing schema of the APEX application (APEX needs a direct grant, not a role)
GRANT EXECUTE ON LIB_APX_USR.IMPR2310 TO CUSTOMS;
