-- =============================================================================
-- Package     : SUPPORT_ENTRY        (upper-case form name, no prefix - f345 standard)
-- Source form : Support_Entry.fmb (Oracle Forms 12c) - window "بيانات المساندة الفنية"
--               support letter that authorises a change in the calling form (no table DML)
-- Target      : Oracle APEX 21.2 / Oracle Database 12.1.0.2, reference application f345
--               one modal dialog page (SC subsystem; page number from MIG_FORM_REGISTRY: TODO, inventory §15 Q4)
-- Author      : Claude Code
-- Created     : 2026-11-24
-- Version     : 001
-- Purpose     : Business logic of the form, organised like the form itself:
--               VERSION -> f345 HELPERS -> FORM LEVEL -> BLOCK RP (control block: items in navigation
--               order, then the buttons) -> PROGRAM UNITS (none in the form)
--               (docs/f345_reference_standard.md §10). No UI state, no session-state reads of page items.
-- Contract    : the caller opens the dialog with P_MODE (0 = new letter, otherwise edit the letter already in
--               the G_ items; user decision D1: the same dialog opened on demand with P_MODE = 1) and
--               P_CURR_PORT_CD (default port). AGREE writes the application items G_PORT_CD, G_SUPP_TITLE_CD,
--               G_LETTER_NBR, G_LETTER_DT (FORMS_APX.SET_GLOBAL = :GLOBAL.X); in mode 0 they are cleared on
--               open and by CANCEL, so a caller that finds G_LETTER_NBR null after "Dialog Closed" does nothing.
--               G_LETTER_DT holds the Hijri date as text in FORMS_APX.HIJRI_DATE_FORMAT (default YYYY-MM-MI,
--               the f345 Hijri picker; the day is kept in the minutes as in Forms MI-MM-RRRR). The callers pass
--               FORMS_APX.HIJRI_TEXT_TO_DATE(G_LETTER_DT) to DB_JOURNAL.JOURNALING_ON, whose parameter is a
--               DATE (plsql/Shared/DB_JOURNAL.pks; inventory §10.6).
-- Parameters  : no I_ / IO_ / O_ prefix (the mode is IN / IN OUT / OUT). Page item P<page>_<ITEM> -> P_<ITEM>;
--               the Forms items P_PORT_CD / P_PORT_NAME and the Forms parameters P_MODE / P_CURR_PORT_CD keep
--               one P_ (no doubled P_P_): P_PORT_CD => :P<page>_P_PORT_CD, P_MODE => :P<page>_P_MODE,
--               P_CURR_PORT_CD => :P<page>_P_CURR_PORT_CD (the page item, not the f345 application item of
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
-- =============================================================================
SET DEFINE OFF

CREATE OR REPLACE PACKAGE LIB_APX_USR.SUPPORT_ENTRY AS
   V_PKG_VERSION       VARCHAR2 (100) := 'VERSION NO. IS:' || '001';
   V_PKG_VERSION_QC    VARCHAR2 (100) := 'VERSION NO. IS:' || '001';
   V_PKG_VERSION_DEV   VARCHAR2 (100) := 'VERSION NO. IS:' || '001';
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
    --           SUPPORT_ENTRY.IS_NEW_LETTER(P_MODE => :P<page>_P_MODE)
    --         buttons AGREE "موافق" / CANCEL "تراجع" and the Close Dialog after AGREE; NOT of it: the
    --         buttons "تعديل" / "إغلاق" (WNFI SET_ITEM_PROPERTY LABEL)
    FUNCTION  IS_NEW_LETTER (P_MODE IN NUMBER) RETURN BOOLEAN;

    -- Source: SUPPORT_ENTRY.WHEN-NEW-FORM-INSTANCE
    -- APEX  : Process "WHEN-NEW-FORM-INSTANCE" (Before Header)
    --           SUPPORT_ENTRY.INIT_FORM(P_MODE => :P<page>_P_MODE, P_CURR_PORT_CD => :P<page>_P_CURR_PORT_CD,
    --             P_PORT_CD => :P<page>_P_PORT_CD, P_PORT_NAME => :P<page>_P_PORT_NAME,
    --             P_SUPP_TITLE_CD => :P<page>_SUPP_TITLE_CD, P_SUPP_TITLE_NM => :P<page>_SUPP_TITLE_NM,
    --             P_LETTER_NBR => :P<page>_LETTER_NBR, P_LETTER_DT => :P<page>_LETTER_DT);
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
    -- =========================================================================
    -- Source: RP.P_PORT_CD.WHEN-VALIDATE-ITEM (NO_DATA_FOUND -> FORM_TRIGGER_FAILURE)
    -- APEX  : Validation "P_PORT_CD VALIDATION" (PL/SQL Function Body returning Error Text)
    --           return SUPPORT_ENTRY.P_PORT_CD_VALIDATION(P_PORT_CD => :P<page>_P_PORT_CD);
    --         DA "P_PORT_CD WHEN-VALIDATE-ITEM" (change, FOS Execute PL/SQL Code), first line:
    --           FORMS_APX.CHECK_ERROR(SUPPORT_ENTRY.P_PORT_CD_VALIDATION(P_PORT_CD => :P<page>_P_PORT_CD));
    FUNCTION  P_PORT_CD_VALIDATION (P_PORT_CD IN VARCHAR2) RETURN VARCHAR2;

    -- Source: RP.P_PORT_CD.WHEN-VALIDATE-ITEM - SELECT PORT_NAME INTO :P_PORT_NAME
    -- APEX  : same DA, second line; Items to Submit P<page>_P_PORT_CD, Items to Return P<page>_P_PORT_NAME
    --           SUPPORT_ENTRY.P_PORT_CD_WHEN_VALIDATE_ITEM(P_PORT_CD => :P<page>_P_PORT_CD,
    --                                                      P_PORT_NAME => :P<page>_P_PORT_NAME);
    PROCEDURE P_PORT_CD_WHEN_VALIDATE_ITEM (P_PORT_CD   IN     VARCHAR2,
                                            P_PORT_NAME IN OUT VARCHAR2);

    -- Source: RP.SUPP_TITLE_CD.WHEN-VALIDATE-ITEM (NO_DATA_FOUND -> FORM_TRIGGER_FAILURE)
    -- APEX  : Validation "SUPP_TITLE_CD VALIDATION"
    --           return SUPPORT_ENTRY.SUPP_TITLE_CD_VALIDATION(P_SUPP_TITLE_CD => :P<page>_SUPP_TITLE_CD);
    --         DA "SUPP_TITLE_CD WHEN-VALIDATE-ITEM", first line FORMS_APX.CHECK_ERROR(<the same call>);
    FUNCTION  SUPP_TITLE_CD_VALIDATION (P_SUPP_TITLE_CD IN VARCHAR2) RETURN VARCHAR2;

    -- Source: RP.SUPP_TITLE_CD.WHEN-VALIDATE-ITEM - SELECT SUPP_TITLE_NM INTO :SUPP_TITLE_NM
    --         full name SUPP_TITLE_CD_WHEN_VALIDATE_ITEM (32 bytes, WHEN_ dropped)
    -- APEX  : same DA, second line; Items to Return P<page>_SUPP_TITLE_NM
    PROCEDURE SUPP_TITLE_CD_VALIDATE_ITEM (P_SUPP_TITLE_CD IN     VARCHAR2,
                                           P_SUPP_TITLE_NM IN OUT VARCHAR2);

    -- Source: RP.LETTER_DT format mask MI-MM-RRRR (Forms rejects a value that does not fit the mask;
    --         the item's own WHEN-VALIDATE-ITEM is empty)
    -- APEX  : Validation "LETTER_DT VALIDATION"
    --           return SUPPORT_ENTRY.LETTER_DT_VALIDATION(P_LETTER_DT => :P<page>_LETTER_DT);
    FUNCTION  LETTER_DT_VALIDATION (P_LETTER_DT IN VARCHAR2) RETURN VARCHAR2;

    -- Source: RP.AGREE.WHEN-BUTTON-PRESSED
    -- APEX  : Validations "P_PORT_CD REQUIRED", "SUPP_TITLE_CD REQUIRED", "LETTER_NBR REQUIRED",
    --         "LETTER_DT REQUIRED" (When Button Pressed AGREE / AGREE_EDIT):
    --           return FORMS_APX.REQUIRED_VALIDATION(ITEM_VALUE => :P<page>_<ITEM>, ITEM_LABEL => '<prompt>');
    --         Process "AGREE WHEN-BUTTON-PRESSED" (button AGREE or AGREE_EDIT)
    --           SUPPORT_ENTRY.AGREE_WHEN_BUTTON_PRESSED(P_PORT_CD => :P<page>_P_PORT_CD,
    --             P_SUPP_TITLE_CD => :P<page>_SUPP_TITLE_CD, P_LETTER_NBR => :P<page>_LETTER_NBR,
    --             P_LETTER_DT => :P<page>_LETTER_DT);
    --         then Process "Close Dialog" (condition IS_NEW_LETTER: EXIT_FORM only in mode 0)
    PROCEDURE AGREE_WHEN_BUTTON_PRESSED (P_PORT_CD       IN VARCHAR2,
                                         P_SUPP_TITLE_CD IN VARCHAR2,
                                         P_LETTER_NBR    IN VARCHAR2,
                                         P_LETTER_DT     IN VARCHAR2);

    -- Source: RP.CANCEL.WHEN-BUTTON-PRESSED
    -- APEX  : Process "CANCEL WHEN-BUTTON-PRESSED" (button CANCEL or CANCEL_EDIT, no validations)
    --           SUPPORT_ENTRY.CANCEL_WHEN_BUTTON_PRESSED(P_MODE => :P<page>_P_MODE);
    --         then Process "Close Dialog" (always: EXIT_FORM in both modes)
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
