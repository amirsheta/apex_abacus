-- =============================================================================
-- Package     : IMPR3100             (upper-case form name, no prefix - f345 standard)
-- Source form : IMPR3100.fmb (Oracle Forms 12c) - report parameter form of IMPR3100.rdf
--               "تقرير إضافات وتعديلات بيانات المستوردين (مساندة فنية)"
-- Target      : Oracle APEX 21.2 / Oracle Database 12.1.0.2, reference application f345
--               page 3100 (IMPR3100) - report page: no search page, no DML
-- Author      : Claude Code
-- Created     : 2026-11-26
-- Version     : 001
-- Purpose     : Business logic of the form, organised like the form itself:
--               VERSION -> FORM LEVEL -> BLOCK CALLING_PARAMETERS (items in navigation order)
--               -> BLOCK TOOLBAR (PRINT) -> PROGRAM UNITS (PRINT_IMPR3100_ARD; the count of CHECK_VAL is private).
--               Report-screen pattern of IMPR2110 ... IMPR2310 (template: plsql/IMPR2310): the radio group REPORT
--               chooses the modified (0) or the added (1) importers of the journal JOURNAL.IMPORTERS_JN; every other
--               item is an optional filter (period, letter port / department / number / date, user, importer).
-- Report      : IMPR3100.rdf is the ARD package IMPR3100_ARD (plsql/IMPR3100, standard 13-c,
--               scripts/gen_ard_impr_reports.py). REP.Run_Product becomes PRINT_IMPR3100_ARD, which returns the ardpdf
--               link; the page opens it in a new tab (standard 13-b). Report page buttons: PRINT, CLEAR, BACK only
--               (DEC-017 / DEC-018).
-- Decisions   : user 2026-11-26: (1) the page PRINT follows PU CHECK_VAL (VIEW: the two date checks, the count with the
--               RDF filters, every filter sent), not the stale PU PRINT_CHECK_VAL (IMPR2310 copy whose LTR_NBR /
--               SUPP_SRCE_CD parameters the RDF never reads); the member keeps the standard name PRINT_CHECK_VAL.
--               (2) the letter date is applied by the report (Forms sent P_LETTER_DT, the RDF read :LETTER_DT).
-- Parameters  : no I_ / IO_ / O_ prefix. Page item P3100_<ITEM> -> P_<ITEM>; application items keep their name
--               (P_CURR_PORT_CD). Inside SQL a parameter is qualified with its member name. PRINT_IMPR3100_ARD is
--               called by this package only (public for tests): its parameters are p_<name> (internal style).
--               Hijri dates arrive as text in FORMS_APX.HIJRI_DATE_FORMAT (the f345 Hijri picker).
--               Rule: scripts/parameter_names.py.
-- Rules       : every identifier <= 30 bytes (DB 12.1.0.2); no COMMIT / ROLLBACK; no V('...').
-- Owner       : LIB_APX_USR; public synonym IMPR3100 + EXECUTE grants at the end of this file.
--               LIB_APX_USR needs direct grants: SELECT on SD_PORTS, SC_PORT_SETTING, SC_USERS, SUPP_TITLES,
--               IMPORTERS, JOURNAL.IMPORTERS_JN; EXECUTE on FORMS_APX.
-- Status      : NOT COMPILED.
-- History     : 2026-11-26 Claude Code 001 Initial migration (report as ARD package IMPR3100_ARD, ARD_URL / ARD_DSNAME
--                          from SC_PORT_SETTING 999 / 99 - the IMPR2110 002 decisions; the CHECK_VAL count kept as in
--                          Forms, as the IMPR2140 user decision of 2026-11-25)
-- =============================================================================
SET DEFINE OFF

CREATE OR REPLACE PACKAGE LIB_APX_USR.IMPR3100 AS
   V_PKG_VERSION       VARCHAR2 (100) := 'VERSION NO. IS:' || '001';
   V_PKG_VERSION_QC    VARCHAR2 (100) := 'VERSION NO. IS:' || '001';
   V_PKG_VERSION_DEV   VARCHAR2 (100) := 'VERSION NO. IS:' || '001';
   FUNCTION PKG_VERSION
      RETURN VARCHAR2;
   V_PACKAGE_NAME      VARCHAR2 (50) := 'IMPR3100';
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
    -- APEX  : server-side condition of P3100_P_PORT_CD and P3100_P_PORT_NAME.
    FUNCTION P_PORT_CD_IS_VISIBLE (P_CURR_PORT_CD IN VARCHAR2)
       RETURN BOOLEAN;

    -- =========================================================================
    -- BLOCK CALLING_PARAMETERS  (control block: report parameters)
    -- =========================================================================
    -- Source: CALLING_PARAMETERS.WHEN-NEW-RECORD-INSTANCE (full name CALLING_PARAMETERS_WHEN_NEW_RECORD_INSTANCE,
    --         shortened to 30 bytes)
    --   IF :PARAMETER.P_CURR_PORT_CD != 99 THEN :SUP_PORT_CD := :PARAMETER.P_CURR_PORT_CD; END IF;
    -- SUGGESTION: Forms set only the code (an assignment fires no WHEN-VALIDATE-ITEM, so SUP_PORT_NAME stayed empty);
    --   here the name is returned too.
    -- APEX  : Process "CALLING_PARAMETERS WHEN-NEW-RECORD-INSTANCE" (Before Header).
    PROCEDURE PARAMETERS_NEW_RECORD_INSTANCE (P_SUP_PORT_CD    OUT VARCHAR2,
                                              P_SUP_PORT_NAME  OUT VARCHAR2,
                                              P_CURR_PORT_CD   IN  VARCHAR2);

    -- Source: CALLING_PARAMETERS.REPORT (Radio Group REP1 = 0 تعديلات بيانات المستوردين, REP2 = 1 إضافة مستوردين جدد;
    --         InitializeValue 0, :REPORT := 0 in PRE-FORM)
    -- Returns the error text when REPORT is not 0 or 1, NULL = OK.
    -- SUGGESTION: new check (a Forms radio group allows only its values; an APEX item can be posted with any value).
    FUNCTION REPORT_VALIDATION (P_REPORT IN VARCHAR2)
       RETURN VARCHAR2;

    -- Source: CALLING_PARAMETERS.P_PORT_CD.WHEN-VALIDATE-ITEM (SELECT PORT_NAME INTO :P_PORT_NAME FROM SD_PORTS, no
    --         handler: an unknown port stopped with the Forms error FRM-40735 / ORA-01403)
    -- Returns 'رمز الجمرك غير صحيح' (the IMPR2110 text) for an unknown port, NULL = OK (empty is allowed here).
    FUNCTION P_PORT_CD_VALIDATION (P_PORT_CD IN VARCHAR2)
       RETURN VARCHAR2;

    -- Source: CALLING_PARAMETERS.P_PORT_CD.WHEN-VALIDATE-ITEM (see P_PORT_CD_VALIDATION)
    -- APEX  : DA "P_PORT_CD WHEN-VALIDATE-ITEM": FOS, Items to Return P3100_P_PORT_NAME. The Popup LOV
    --         P3100_P_PORT_CD (LOV_SD_PORTS) replaces P_PORT_CD.KEY-LISTVAL / P_LOV_PORT (CALL_FORM REP_LOV_SD_PORTS).
    PROCEDURE P_PORT_CD_WHEN_VALIDATE_ITEM (P_PORT_CD   IN  VARCHAR2,
                                            P_PORT_NAME OUT VARCHAR2);

    -- Source: START_DT / END_DT WHEN-VALIDATE-ITEM (HIJDATE.VALID_HIJ_DATE)
    -- APEX  : no member here (CLAUDE.md 4a rule 3): the DAs "<ITEM> WHEN-VALIDATE-ITEM" call
    --         FORMS_APX.CHECK_ERROR(FORMS_APX.HIJRI_DATE_ERROR(:P3100_<ITEM>)) directly, as IMPR2310;
    --         PRINT_CHECK_VAL checks the three dates again. LETTER_DT has the same Hijri check (its OLB triggers are
    --         empty in the XML; the item is a Datetime with mask MI-MM-RRRR).

    -- Source: CALLING_PARAMETERS.SUP_PORT_CD.WHEN-VALIDATE-ITEM
    --   IF :SUP_PORT_CD IS NULL THEN RETURN; END IF;
    --   SELECT PORT_NAME INTO :SUP_PORT_NAME FROM SD_PORTS WHERE PORT_CD = :SUP_PORT_CD;
    --   EXCEPTION WHEN NO_DATA_FOUND THEN RAISE FORM_TRIGGER_FAILURE;
    -- Returns 'رمز الجمرك غير صحيح' for an unknown port (Forms stopped without a text), NULL = OK.
    FUNCTION SUP_PORT_CD_VALIDATION (P_SUP_PORT_CD IN VARCHAR2)
       RETURN VARCHAR2;

    -- Source: CALLING_PARAMETERS.SUP_PORT_CD.WHEN-VALIDATE-ITEM (see SUP_PORT_CD_VALIDATION)
    -- APEX  : DA "SUP_PORT_CD WHEN-VALIDATE-ITEM": FOS, Items to Return P3100_SUP_PORT_NAME. The Popup LOV
    --         P3100_SUP_PORT_CD (LOV_SD_PORTS) replaces SUP_PORT_CD.KEY-LISTVAL / SUPP_PORT_CD_LOV (REP_LOV_SD_PORTS).
    PROCEDURE SUP_PORT_CD_WHEN_VALIDATE_ITEM (P_SUP_PORT_CD   IN  VARCHAR2,
                                              P_SUP_PORT_NAME OUT VARCHAR2);

    -- Source: CALLING_PARAMETERS.SUPP_TITLE_CD.WHEN-VALIDATE-ITEM
    --   IF :SUPP_TITLE_CD IS NULL THEN RETURN; END IF;
    --   SELECT SUPP_TITLE_NM INTO :SUPP_TITLE_NM FROM SUPP_TITLES WHERE SUPP_TITLE_CD = :SUPP_TITLE_CD;
    --   EXCEPTION WHEN NO_DATA_FOUND THEN RAISE FORM_TRIGGER_FAILURE;
    -- Returns 'رمز جهة الخطاب غير موجود' (the SUPPORT_ENTRY text; Forms stopped without a text), NULL = OK.
    FUNCTION SUPP_TITLE_CD_VALIDATION (P_SUPP_TITLE_CD IN VARCHAR2)
       RETURN VARCHAR2;

    -- Source: CALLING_PARAMETERS.SUPP_TITLE_CD.WHEN-VALIDATE-ITEM (full name SUPP_TITLE_CD_WHEN_VALIDATE_ITEM,
    --         32 bytes: WHEN_ dropped, as SUPPORT_ENTRY)
    -- APEX  : DA "SUPP_TITLE_CD WHEN-VALIDATE-ITEM": FOS, Items to Return P3100_SUPP_TITLE_NM. The Popup LOV
    --         P3100_SUPP_TITLE_CD (LOV_SUPP_TITLES) replaces KEY-LISTVAL / P_LOV_SUPP_TITLES (LOV_SUPP_TITLES.FMX).
    PROCEDURE SUPP_TITLE_CD_VALIDATE_ITEM (P_SUPP_TITLE_CD IN  VARCHAR2,
                                           P_SUPP_TITLE_NM OUT VARCHAR2);

    -- Source: CALLING_PARAMETERS.USER_ID.WHEN-VALIDATE-ITEM
    --   IF :USER_ID IS NOT NULL THEN
    --      SELECT USR_ANAME INTO :USR_USR_ANAME FROM SC_USERS WHERE PORT_CD = :P_PORT_CD AND USER_ID = :USER_ID;
    --   END IF;
    --   EXCEPTION WHEN NO_DATA_FOUND THEN STR.DISPARBMSG(1, 80, 'SYSTEM_ERROR'); RAISE FORM_TRIGGER_FAILURE;
    -- Returns FORMS_APX.ARABIC_MESSAGE(1, 80) for an unknown user, NULL = OK.
    -- The port: :P_PORT_CD in Forms (= P_CURR_PORT_CD outside head office); empty at head office when no port is
    -- picked, and then every user was refused. SUGGESTION: here NVL(P_PORT_CD, P_CURR_PORT_CD), as the LOV LOV_USER.
    FUNCTION USER_ID_VALIDATION (P_USER_ID      IN VARCHAR2,
                                 P_PORT_CD      IN VARCHAR2,
                                 P_CURR_PORT_CD IN VARCHAR2)
       RETURN VARCHAR2;

    -- Source: CALLING_PARAMETERS.USER_ID.WHEN-VALIDATE-ITEM (see USER_ID_VALIDATION)
    -- APEX  : DA "USER_ID WHEN-VALIDATE-ITEM": FOS, Items to Return P3100_USR_USR_ANAME. The Popup LOV
    --         P3100_USER_ID (LOV_USER) replaces USER_ID.KEY-LISTVAL / BUT1 (PU LOV_USER -> CALL_FORM LOV_USER.FMX).
    PROCEDURE USER_ID_WHEN_VALIDATE_ITEM (P_USER_ID       IN  VARCHAR2,
                                          P_PORT_CD       IN  VARCHAR2,
                                          P_CURR_PORT_CD  IN  VARCHAR2,
                                          P_USR_USR_ANAME OUT VARCHAR2);

    -- Source: CALLING_PARAMETERS.IMPR_NBR1.WHEN-VALIDATE-ITEM
    --   SELECT ARBC_IMPR_NAME INTO :IMPR_NAME FROM IMPORTERS WHERE --PORT_CD = :P_PORT_CD AND
    --   IMPR_NBR = :IMPR_NBR1;
    --   EXCEPTION WHEN TOO_MANY_ROWS THEN DO_KEY('LIST_VALUES'); WHEN OTHERS THEN :IMPR_NBR1 := NULL;
    -- The port condition is commented out in Forms: the number is looked up in every port (kept).
    -- No row (or not a number): IMPR_NBR1 is cleared without a message, as in Forms.
    -- APEX  : DA "IMPR_NBR1 WHEN-VALIDATE-ITEM": Clear P3100_IMPR_NAME, then FOS, Items to Return P3100_IMPR_NBR1,
    --         P3100_IMPR_NAME. The Popup LOV P3100_IMPR_NBR1 replaces KEY-LISTVAL / LOV_IMPR (PU CHECK_LIST_VAL).
    PROCEDURE IMPR_NBR1_WHEN_VALIDATE_ITEM (P_IMPR_NBR1 IN OUT VARCHAR2,
                                            P_IMPR_NAME OUT    VARCHAR2);

    -- =========================================================================
    -- BLOCK TOOLBAR  (PRINT -> page 0 button REPORT_PRINT; VIEW / KEY-F4 open the same PDF, DEC-018)
    -- =========================================================================
    -- Source: PU CHECK_VAL (TOOLBAR.ITEM304 «عرض», KEY-F4, KEY-F5) - user decision 2026-11-26 (spec 12 item 1):
    --   IF :LETTER_DT IS NOT NULL AND (:START_DT IS NOT NULL OR :END_DT IS NOT NULL)
    --      -> MESSAGE 'يجب إدخال تاريخ الخطاب أو الفترة وليس كليهما' + FTF
    --   IF :START_DT / :END_DT both given AND TO_CHAR(:END_DT,'RRRR-MM-MI') < TO_CHAR(:START_DT,'RRRR-MM-MI')
    --      -> MESSAGE 'تاريخ النهاية يجب أن يكون أكبر من تاريخ البداية' + FTF
    --   V_COUNT := EXISTS JOURNAL.IMPORTERS_JN with the NVL filters (no port);
    --   IF V_COUNT > 0 THEN REP.Run_Product(IMPR3100.REP) with P_MODULE_NAME, P_CURR_PORT_CD (= :P_PORT_CD), START_DT,
    --        END_DT (YYYY-MM-MI), P_SUPP_SRCE_CD (= :SUP_PORT_CD), P_IMPR_NBR (= :IMPR_NBR1), P_SUPP_TITLE_CD,
    --        P_LETTER_NBR, P_LETTER_DT, P_USER_ID, REPORT1 (= :REPORT), P_REPORT_NO
    --   ELSE MESSAGE 'لا يوجد سجلات تحقق المطلوب' + FTF.
    -- PU PRINT_CHECK_VAL (ITEM303 «طباعة», KEY-PRINT) is a copy of the IMPR2310 code (spec 12 item 1): not converted.
    -- The port: P_CURR_PORT_CD outside head office (WHEN-NEW-FORM-INSTANCE), else the port item, else P_CURR_PORT_CD
    -- (as IMPR2310).
    -- APEX  : DA "REPORT_PRINT" (custom event of page 0): FOS, Items to Return P3100_REPORT_URL.
    PROCEDURE PRINT_CHECK_VAL (P_REPORT         IN  VARCHAR2,
                               P_PORT_CD        IN  VARCHAR2,
                               P_START_DT       IN  VARCHAR2,
                               P_END_DT         IN  VARCHAR2,
                               P_SUP_PORT_CD    IN  VARCHAR2,
                               P_SUPP_TITLE_CD  IN  VARCHAR2,
                               P_LETTER_NBR     IN  VARCHAR2,
                               P_LETTER_DT      IN  VARCHAR2,
                               P_USER_ID        IN  VARCHAR2,
                               P_IMPR_NBR1      IN  VARCHAR2,
                               P_REPORT_NO      IN  VARCHAR2,
                               P_HERO_TITLE     IN  VARCHAR2,
                               P_CURR_PORT_CD   IN  VARCHAR2,
                               P_REPORT_URL     OUT VARCHAR2);

    -- =========================================================================
    -- PROGRAM UNITS
    -- =========================================================================
    -- Source: REP.Run_Product(REPORTS, :PARAMETER.P_REPORT_PATH || :PARAMETER.P_REPORT_FILE, SYNCHRONOUS, RUNTIME,
    --         FILESYSTEM, pl_id, NULL)
    -- Returns the ardpdf link of IMPR3100_ARD.ARD_IMPR3100 (standard 13-c), parameters in the order of IMPR3100_ARD_spec.sql:
    --   P_PARAMETER1 P_CURR_PORT_CD, P_PARAMETER2 START_DT, P_PARAMETER3 END_DT, P_PARAMETER4 P_SUPP_SRCE_CD,
    --   P_PARAMETER5 P_IMPR_NBR, P_PARAMETER6 P_SUPP_TITLE_CD, P_PARAMETER7 P_LETTER_NBR, P_PARAMETER8 LETTER_DT,
    --   P_PARAMETER9 P_USER_ID, P_PARAMETER10 REPORT1, P_PARAMETER11 P_MODULE_NAME, P_PARAMETER12 P_REPORT_NO.
    --   The three dates are sent as text 'YYYY-MM-MI' (as Forms CHECK_VAL).
    --   ARD_URL / ARD_DSNAME: settings in SC_PORT_SETTING (SYSOBJ_ID 999, PORT_CD 99; migration/001_ard_settings.sql);
    --   missing -> error message. Not sent: DESTYPE, PARAMFORM, PRINTJOB, MAXIMIZE, ORACLE_SHUTDOWN (Reports Runtime
    --   options).
    FUNCTION PRINT_IMPR3100_ARD (p_curr_port_cd  IN VARCHAR2,
                                 p_start_dt      IN VARCHAR2,
                                 p_end_dt        IN VARCHAR2,
                                 p_supp_srce_cd  IN VARCHAR2,
                                 p_impr_nbr      IN VARCHAR2,
                                 p_supp_title_cd IN VARCHAR2,
                                 p_letter_nbr    IN VARCHAR2,
                                 p_letter_dt     IN VARCHAR2,
                                 p_user_id       IN VARCHAR2,
                                 p_report1       IN VARCHAR2,
                                 p_module_name   IN VARCHAR2,
                                 p_report_no     IN VARCHAR2)
       RETURN VARCHAR2;

    -- =========================================================================
    -- UI LOGIC FOR APEX DYNAMIC ACTIONS (comments only)
    -- =========================================================================
    -- APEX-DA: [Source: P_PORT_CD.KEY-LISTVAL, P_LOV_PORT.WHEN-BUTTON-PRESSED -> CALL_FORM REP_LOV_SD_PORTS,
    --          :GLOBAL.PORT_CD / PORT_NAME] -> Popup LOV P3100_P_PORT_CD on LOV_SD_PORTS (IMPR1110).
    -- APEX-DA: [Source: SUP_PORT_CD.KEY-LISTVAL, SUPP_PORT_CD_LOV.WHEN-BUTTON-PRESSED -> REP_LOV_SD_PORTS]
    --          -> Popup LOV P3100_SUP_PORT_CD on LOV_SD_PORTS.
    -- APEX-DA: [Source: SUPP_TITLE_CD.KEY-LISTVAL, P_LOV_SUPP_TITLES.WHEN-BUTTON-PRESSED -> LOV_SUPP_TITLES.FMX,
    --          :GLOBAL.SUPP_TITLE_CD / SUPP_TITLE_NM] -> Popup LOV P3100_SUPP_TITLE_CD on LOV_SUPP_TITLES (SUPPORT_ENTRY).
    -- APEX-DA: [Source: USER_ID.KEY-LISTVAL, BUT1.WHEN-BUTTON-PRESSED -> PU LOV_USER -> CALL_FORM LOV_USER.FMX
    --          (PORT_CD = :P_PORT_CD), :GLOBAL.USER_ID2 / USR_ANAME] -> Popup LOV P3100_USER_ID on LOV_IMPR3100_LOV_USER
    --          (LOV_APX.LOV_USER, users of NVL(P3100_P_PORT_CD, P_CURR_PORT_CD)). The KEY-LISTVAL property checks
    --          (:SYSTEM.MODE, INSERT_ALLOWED ...) -> not needed (the item is always entrable).
    -- APEX-DA: [Source: IMPR_NBR1.KEY-LISTVAL, LOV_IMPR.WHEN-BUTTON-PRESSED -> PU CHECK_LIST_VAL -> CALL_FORM LOV_IMPR
    --          (no port: every port), :GLOBAL.IMPR_NBR / IMPR_NAME] -> Popup LOV P3100_IMPR_NBR1 on LOV_IMPR3100_LOV_IMPR
    --          (importers of P3100_P_PORT_CD, else of P_CURR_PORT_CD - the port the report filters on; spec 12).
    -- APEX-DA: [Source: START_DT / END_DT KEY-LISTVAL (intrface.Disp_Calendar), KEY-F4 (intrface.Disp_date_con)]
    --          -> f345 Hijri picker (class hijri-date-default). LETTER_DT KEY-LISTVAL / KEY-F4 / WHEN-VALIDATE-ITEM have
    --          no code in the XML -> the same picker and the same date check.
    -- APEX-DA: [Source: TOOLBAR.ITEM305 «مسح»] CLEAR_BLOCK(NO_VALIDATE) -> page 0 button CLEAR.
    -- APEX-DA: [Source: TOOLBAR.ITEM304 «عرض», KEY-F4 / KEY-F5 -> CHECK_VAL; ITEM303 «طباعة», KEY-PRINT -> PRINT_CHECK_VAL]
    --          -> page 0 REPORT_PRINT (REPORT_SHOW is Never, DEC-018): one PDF.
    -- APEX-DA: [Source: TOOLBAR.ITEM306 «قائمة»] DO_KEY('LIST_VALUES') -> the Popup LOV button of the item.
    -- APEX-DA: [Source: TOOLBAR.ITEM307 «خروج»] EXIT_FORM -> page 0 button BACK. [KEY-NEXT-ITEM of the buttons] -> none.
    -- APEX-DA: [Source: WHEN-NEW-FORM-INSTANCE GO_ITEM('START_DT') / NEXT_ITEM] -> not needed.
    -- APEX-DA: [Source: PRE-FORM, WHEN-WINDOW-ACTIVATED] window title / icon / date format -> f345 shell;
    --          PRE-FORM :REPORT := 0 -> item default of P3100_REPORT.
    -- APEX-DA: [Source: TITLE block, LOAD_ZATCA_LOGOS] -> hero region (module name, report number, port).

END IMPR3100;
/
SHOW ERRORS

-- -----------------------------------------------------------------------------
-- Synonym and grants (run as a user allowed to create public synonyms / grant on LIB_APX_USR)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PUBLIC SYNONYM IMPR3100 FOR LIB_APX_USR.IMPR3100;

GRANT EXECUTE ON LIB_APX_USR.IMPR3100 TO LIB_USR;

GRANT EXECUTE ON LIB_APX_USR.IMPR3100 TO SECURITY_DEFAULT;

GRANT EXECUTE ON LIB_APX_USR.IMPR3100 TO SECURITY_PROD;

-- CUSTOMS = parsing schema of the APEX application (APEX needs a direct grant, not a role)
GRANT EXECUTE ON LIB_APX_USR.IMPR3100 TO CUSTOMS;
