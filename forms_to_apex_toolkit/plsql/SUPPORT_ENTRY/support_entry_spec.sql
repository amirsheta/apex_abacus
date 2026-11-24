-- =============================================================================
-- Package     : SUPPORT_ENTRY        (upper-case form name, no prefix - f345 standard)
-- Source form : Support_Entry.fmb (Oracle Forms 12c) - window "بيانات المساندة الفنية"
--               support letter that authorises a change in the calling form (no table DML)
-- Target      : Oracle APEX 21.2 / Oracle Database 12.1.0.2, reference application f345
--               one modal dialog page 9001 SUPPORT_ENTRY (SC subsystem; page number: user decision 2026-11-24)
-- Author      : Claude Code
-- Created     : 2026-11-24
-- Version     : 002
-- Purpose     : Business logic of the form, organised like the form itself:
--               VERSION -> f345 HELPERS -> FORM LEVEL -> BLOCK RP (control block: items in navigation
--               order, then the buttons) -> PROGRAM UNITS (none in the form)
--               (docs/f345_reference_standard.md §10). No UI state, no session-state reads of page items.
-- Contract    : the caller first runs OPEN_DIALOG (server side, FOS) and opens the URL it returns, with P_MODE (0 = new letter, otherwise edit the letter already in
--               the G_ items; user decision D1: the same dialog opened on demand with P_MODE = 1) and
--               P_CURR_PORT_CD (default port). AGREE writes the application items G_PORT_CD, G_SUPP_TITLE_CD,
--               G_LETTER_NBR, G_LETTER_DT (FORMS_APX.SET_GLOBAL = :GLOBAL.X); in mode 0 they are cleared on
--               open and by CANCEL, so a caller that finds G_LETTER_NBR null after "Dialog Closed" does nothing.
--               G_LETTER_DT holds the Hijri date as text in FORMS_APX.HIJRI_DATE_FORMAT (default YYYY-MM-MI,
--               the f345 Hijri picker; the day is kept in the minutes as in Forms MI-MM-RRRR). The callers pass
--               FORMS_APX.HIJRI_TEXT_TO_DATE(G_LETTER_DT) to DB_JOURNAL.JOURNALING_ON, whose parameter is a
--               DATE (plsql/Shared/DB_JOURNAL.pks; inventory §10.6).
-- Parameters  : no I_ / IO_ / O_ prefix (the mode is IN / IN OUT / OUT). Page item P9001_<ITEM> -> P_<ITEM>;
--               the Forms items P_PORT_CD / P_PORT_NAME and the Forms parameters P_MODE / P_CURR_PORT_CD keep
--               one P_ (no doubled P_P_): P_PORT_CD => :P9001_P_PORT_CD, P_MODE => :P9001_P_MODE,
--               P_CURR_PORT_CD => :P9001_P_CURR_PORT_CD (the page item, not the f345 application item of
--               the same name). Inside SQL a parameter is qualified with its member name.
--               Common helpers (CHECK_ERROR, REQUIRED_VALIDATION, HIJRI_DATE_ERROR, SET_GLOBAL ...) are in
--               FORMS_APX (version 004) and called as FORMS_APX.<NAME>.
-- Names       : SUPP_TITLE_CD_WHEN_VALIDATE_ITEM is 32 bytes -> SUPP_TITLE_CD_VALIDATE_ITEM (WHEN_ dropped).
-- Rules       : every identifier <= 30 bytes (DB 12.1.0.2); no qualified expressions (18c);
--               no COMMIT / ROLLBACK.
-- Owner       : LIB_APX_USR; public synonym SUPPORT_ENTRY + EXECUTE grants at the end of this file.
--               LIB_APX_USR needs SELECT on SD_PORTS and SUPP_TITLES, EXECUTE on FORMS_APX and HIJDATE_DB
--               (through FORMS_APX.HIJRI_DATE_ERROR).
-- Status      : NOT COMPILED (no database in this session).
-- History     : 2026-11-24 Claude Code 001 Initial migration (step 02)
--               2026-11-24 Claude Code 002 Step 03: OPEN_DIALOG (page 9001 is shared by several callers; f345
--                          SCREEN ENTRY RESET would clear P0_PAGE_PK and the URL items when it opens, because
--                          9001 is not <caller> / <caller>01). Previous version: rollback/SUPPORT_ENTRY/step03_v001/
-- =============================================================================
SET DEFINE OFF

CREATE OR REPLACE PACKAGE LIB_APX_USR.SUPPORT_ENTRY AS
   V_PKG_VERSION       VARCHAR2 (100) := 'VERSION NO. IS:' || '002';
   V_PKG_VERSION_QC    VARCHAR2 (100) := 'VERSION NO. IS:' || '002';
   V_PKG_VERSION_DEV   VARCHAR2 (100) := 'VERSION NO. IS:' || '002';
   FUNCTION PKG_VERSION
      RETURN VARCHAR2;
   V_PACKAGE_NAME      VARCHAR2 (50) := 'SUPPORT_ENTRY';
   V_LAST_MODIFY_DT    VARCHAR2 (10) := '24-11-2026';
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
    -- f345 HELPERS  (the common ones are in FORMS_APX: CHECK_ERROR, REQUIRED_VALIDATION, HIJRI_DATE_ERROR ...)
    -- No P0_PAGE_PK_CHECK: control block without a table, the dialog has no record key.
    -- =========================================================================

    -- =========================================================================
    -- FORM LEVEL                                   (Forms: form-level triggers)
    -- =========================================================================
    -- Source: SUPPORT_ENTRY.WHEN-NEW-FORM-INSTANCE / AGREE / CANCEL - IF :PARAMETER.P_MODE = 0
    -- APEX  : server-side condition (PL/SQL Expression) of the mode-0 components:
    --           SUPPORT_ENTRY.IS_NEW_LETTER(P_MODE => :P9001_P_MODE)
    --         buttons AGREE "موافق" / CANCEL "تراجع"; NOT of it: AGREE_EDIT "تعديل" / CANCEL_EDIT "إغلاق"
    --         (WNFI SET_ITEM_PROPERTY LABEL)
    FUNCTION  IS_NEW_LETTER (P_MODE IN NUMBER) RETURN BOOLEAN;

    -- Source: the callers' CALL_FORM('SUPPORT_ENTRY.FMX', ..., PL_ID) with ADD_PARAMETER P_MODE / P_CURR_PORT_CD
    --         (IMPR1110 PU EXEC_FUNS, IMPR1130 WHEN-NEW-FORM-INSTANCE)
    -- APEX  : on the CALLER page, the DA that opens the dialog: action FOS Execute PL/SQL Code
    --           SUPPORT_ENTRY.OPEN_DIALOG(P_MODE => 0, P_CURR_PORT_CD => :P1110_PORT_CD,
    --                                     P_SUPPORT_URL => :P1110_SUPPORT_URL);
    --         (Items to Return P<caller>_SUPPORT_URL), then apex.navigation.redirect($v('P<caller>_SUPPORT_URL'));
    --         Sets G_LAST_PAGE := 9001 so that f345 SCREEN ENTRY RESET does not clear P0_PAGE_PK and the URL items
    --         when page 9001 renders, and keeps the caller page in G_SUPPORT_ENTRY_CALLER; page 9001 puts it back
    --         into G_LAST_PAGE (After Header process "G_LAST_PAGE KEEP").
    --         Parameters are named after the Forms parameter list (P_MODE, P_CURR_PORT_CD), the same for every caller.
    PROCEDURE OPEN_DIALOG (P_MODE         IN  NUMBER,
                           P_CURR_PORT_CD IN  NUMBER,
                           P_SUPPORT_URL  OUT VARCHAR2);

    -- Source: SUPPORT_ENTRY.WHEN-NEW-FORM-INSTANCE
    -- APEX  : Process "WHEN-NEW-FORM-INSTANCE" (Before Header, page 9001)
    --           SUPPORT_ENTRY.INIT_FORM(P_MODE => :P9001_P_MODE, P_CURR_PORT_CD => :P9001_P_CURR_PORT_CD,
    --             P_PORT_CD => :P9001_P_PORT_CD, P_PORT_NAME => :P9001_P_PORT_NAME,
    --             P_SUPP_TITLE_CD => :P9001_SUPP_TITLE_CD, P_SUPP_TITLE_NM => :P9001_SUPP_TITLE_NM,
    --             P_LETTER_NBR => :P9001_LETTER_NBR, P_LETTER_DT => :P9001_LETTER_DT);
    PROCEDURE INIT_FORM (P_MODE          IN     NUMBER,
                         P_CURR_PORT_CD  IN     NUMBER,
                         P_PORT_CD       IN OUT VARCHAR2,
                         P_PORT_NAME     IN OUT VARCHAR2,
                         P_SUPP_TITLE_CD IN OUT VARCHAR2,
                         P_SUPP_TITLE_NM IN OUT VARCHAR2,
                         P_LETTER_NBR    IN OUT VARCHAR2,
                         P_LETTER_DT     IN OUT VARCHAR2);

    -- Source: SUPPORT_ENTRY.PRE-FORM (SET_WINDOW_PROPERTY POSITION) - dropped: the modal dialog is centred.

    -- =========================================================================
    -- BLOCK RP  (control block, 1 record, no base table)
    -- Page 9001 never submits (a re-render would run f345 SCREEN ENTRY RESET again), so the checks run in
    -- dynamic actions (FOS) and again inside AGREE_WHEN_BUTTON_PRESSED; there are no page validations.
    -- =========================================================================
    -- Source: RP.P_PORT_CD.WHEN-VALIDATE-ITEM (NO_DATA_FOUND -> FORM_TRIGGER_FAILURE)
    -- APEX  : DA "P_PORT_CD WHEN-VALIDATE-ITEM" (change, FOS Execute PL/SQL Code), first line:
    --           FORMS_APX.CHECK_ERROR(SUPPORT_ENTRY.P_PORT_CD_VALIDATION(P_PORT_CD => :P9001_P_PORT_CD));
    FUNCTION  P_PORT_CD_VALIDATION (P_PORT_CD IN VARCHAR2) RETURN VARCHAR2;

    -- Source: RP.P_PORT_CD.WHEN-VALIDATE-ITEM - SELECT PORT_NAME INTO :P_PORT_NAME
    -- APEX  : same DA, second line; Items to Submit P9001_P_PORT_CD, Items to Return P9001_P_PORT_NAME
    --           SUPPORT_ENTRY.P_PORT_CD_WHEN_VALIDATE_ITEM(P_PORT_CD => :P9001_P_PORT_CD,
    --                                                      P_PORT_NAME => :P9001_P_PORT_NAME);
    PROCEDURE P_PORT_CD_WHEN_VALIDATE_ITEM (P_PORT_CD   IN     VARCHAR2,
                                            P_PORT_NAME IN OUT VARCHAR2);

    -- Source: RP.SUPP_TITLE_CD.WHEN-VALIDATE-ITEM (NO_DATA_FOUND -> FORM_TRIGGER_FAILURE)
    -- APEX  : DA "SUPP_TITLE_CD WHEN-VALIDATE-ITEM" (change, FOS), first line
    --           FORMS_APX.CHECK_ERROR(SUPPORT_ENTRY.SUPP_TITLE_CD_VALIDATION(P_SUPP_TITLE_CD => :P9001_SUPP_TITLE_CD));
    FUNCTION  SUPP_TITLE_CD_VALIDATION (P_SUPP_TITLE_CD IN VARCHAR2) RETURN VARCHAR2;

    -- Source: RP.SUPP_TITLE_CD.WHEN-VALIDATE-ITEM - SELECT SUPP_TITLE_NM INTO :SUPP_TITLE_NM
    --         full name SUPP_TITLE_CD_WHEN_VALIDATE_ITEM (32 bytes, WHEN_ dropped)
    -- APEX  : same DA, second line; Items to Return P9001_SUPP_TITLE_NM
    PROCEDURE SUPP_TITLE_CD_VALIDATE_ITEM (P_SUPP_TITLE_CD IN     VARCHAR2,
                                           P_SUPP_TITLE_NM IN OUT VARCHAR2);

    -- Source: RP.LETTER_DT format mask MI-MM-RRRR (Forms rejects a value that does not fit the mask;
    --         the item's own WHEN-VALIDATE-ITEM is empty)
    -- APEX  : DA "LETTER_DT WHEN-VALIDATE-ITEM" (change, FOS)
    --           FORMS_APX.CHECK_ERROR(SUPPORT_ENTRY.LETTER_DT_VALIDATION(P_LETTER_DT => :P9001_LETTER_DT));
    FUNCTION  LETTER_DT_VALIDATION (P_LETTER_DT IN VARCHAR2) RETURN VARCHAR2;

    -- Source: RP.AGREE.WHEN-BUTTON-PRESSED
    -- APEX  : DA "AGREE WHEN-BUTTON-PRESSED" (click AGREE or AGREE_EDIT): FOS
    --           SUPPORT_ENTRY.AGREE_WHEN_BUTTON_PRESSED(P_PORT_CD => :P9001_P_PORT_CD,
    --             P_SUPP_TITLE_CD => :P9001_SUPP_TITLE_CD, P_LETTER_NBR => :P9001_LETTER_NBR,
    --             P_LETTER_DT => :P9001_LETTER_DT);
    --         (the required checks stop at the first missing item in the Forms order, FOS shows the text),
    --         then native Close Dialog (both modes, decision D1; Forms closed only in mode 0)
    PROCEDURE AGREE_WHEN_BUTTON_PRESSED (P_PORT_CD       IN VARCHAR2,
                                         P_SUPP_TITLE_CD IN VARCHAR2,
                                         P_LETTER_NBR    IN VARCHAR2,
                                         P_LETTER_DT     IN VARCHAR2);

    -- Source: RP.CANCEL.WHEN-BUTTON-PRESSED
    -- APEX  : DA "CANCEL WHEN-BUTTON-PRESSED" (button CANCEL or CANCEL_EDIT): FOS
    --           SUPPORT_ENTRY.CANCEL_WHEN_BUTTON_PRESSED(P_MODE => :P9001_P_MODE);
    --         then native Close Dialog (always: EXIT_FORM in both modes)
    PROCEDURE CANCEL_WHEN_BUTTON_PRESSED (P_MODE IN NUMBER);

    -- =========================================================================
    -- PROGRAM UNITS                                (Forms: none)
    -- =========================================================================

END SUPPORT_ENTRY;
/
SHOW ERRORS

-- -----------------------------------------------------------------------------
-- Synonym and grants (run as a user allowed to create public synonyms / grant on LIB_APX_USR)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PUBLIC SYNONYM SUPPORT_ENTRY FOR LIB_APX_USR.SUPPORT_ENTRY;

GRANT EXECUTE ON LIB_APX_USR.SUPPORT_ENTRY TO LIB_USR;

GRANT EXECUTE ON LIB_APX_USR.SUPPORT_ENTRY TO SECURITY_DEFAULT;

GRANT EXECUTE ON LIB_APX_USR.SUPPORT_ENTRY TO SECURITY_PROD;

-- CUSTOMS = parsing schema of the APEX application (APEX needs a direct grant, not a role)
GRANT EXECUTE ON LIB_APX_USR.SUPPORT_ENTRY TO CUSTOMS;
