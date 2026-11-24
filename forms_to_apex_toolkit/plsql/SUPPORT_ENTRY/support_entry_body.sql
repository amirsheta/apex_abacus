-- =============================================================================
-- Package body: SUPPORT_ENTRY   (matches support_entry_spec.sql - f345 standard)
-- Source form : Support_Entry.fmb   Target: APEX 21.2 / DB 12.1.0.2   Version: 002 (page 9001)
-- Author      : Claude Code   Created: 2026-11-24
-- Rules: no Forms built-ins (FORMS_APX instead), no COMMIT / ROLLBACK, item values passed as parameters
--        named after their binds (P_<ITEM>, no I_ / IO_ / O_), qualified with the member name inside SQL;
--        identifiers <= 30 bytes. Layout: VERSION -> PRIVATE HELPERS -> FORM LEVEL -> BLOCK RP -> UI LOGIC.
-- Status: NOT COMPILED (no database in this session).
-- =============================================================================
SET DEFINE OFF

CREATE OR REPLACE PACKAGE BODY LIB_APX_USR.SUPPORT_ENTRY
AS

    -- =========================================================================
    -- CONSTANTS  (declarations must precede the subprogram bodies)
    -- =========================================================================
    c_page_id CONSTANT PLS_INTEGER := 9001;              -- APEX page SUPPORT_ENTRY

    -- Labels of the four letter items (Forms prompts without the ':' and the tatweel), used in the
    -- required messages of AGREE (FORMS_APX.REQUIRED_VALIDATION -> 'يجب إدخال <label>').
    c_port_label       CONSTANT VARCHAR2(30) := 'جمرك الخطاب';
    c_supp_title_label CONSTANT VARCHAR2(30) := 'جهة الخطاب';
    c_letter_nbr_label CONSTANT VARCHAR2(30) := 'رقم الخطاب';
    c_letter_dt_label  CONSTANT VARCHAR2(30) := 'تاريخ الخطاب';

    -- SUGGESTION: Forms raised FORM_TRIGGER_FAILURE without a message for an unknown code (only the cursor
    -- stayed in the item). APEX needs a text; these two are new and need the business owner's approval.
    c_port_not_found       CONSTANT VARCHAR2(100) := 'رمز الجمرك غير موجود';
    c_supp_title_not_found CONSTANT VARCHAR2(100) := 'رمز جهة الخطاب غير موجود';

    -- =========================================================================
    -- PACKAGE VERSION
    -- =========================================================================
    -- SELECT SUPPORT_ENTRY.PKG_VERSION FROM dual;  -> package name, version, modified date / by
    FUNCTION PKG_VERSION
       RETURN VARCHAR2
    IS
    BEGIN
       RETURN V_INFO;
    END PKG_VERSION;

    -- =========================================================================
    -- PRIVATE HELPERS
    -- =========================================================================
    -- Looks up SD_PORTS.PORT_NAME (SELECT of RP.P_PORT_CD.WHEN-VALIDATE-ITEM).
    -- FALSE when the port does not exist. The Forms item is CHAR and was compared with the NUMBER column
    -- through an implicit TO_NUMBER; a text that is not a number is treated as "not found" here.
    FUNCTION find_port (p_port_cd   IN  VARCHAR2,
                        p_port_name OUT VARCHAR2) RETURN BOOLEAN
    IS
        v_port_cd NUMBER;
    BEGIN
        v_port_cd := TO_NUMBER(p_port_cd);
        SELECT port_name
          INTO p_port_name
          FROM sd_ports
         WHERE port_cd = v_port_cd;
        RETURN TRUE;
    EXCEPTION
        WHEN NO_DATA_FOUND OR VALUE_ERROR OR INVALID_NUMBER THEN
            p_port_name := NULL;
            RETURN FALSE;
    END find_port;

    -- Looks up SUPP_TITLES.SUPP_TITLE_NM (SELECT of RP.SUPP_TITLE_CD.WHEN-VALIDATE-ITEM).
    -- As in Forms the lookup does not check TITLE_STATUS = 1 (only the LOV does).
    -- SUGGESTION: add TITLE_STATUS = 1 so that a typed code of an inactive title is refused too.
    FUNCTION find_supp_title (p_supp_title_cd IN  VARCHAR2,
                              p_supp_title_nm OUT VARCHAR2) RETURN BOOLEAN
    IS
        v_supp_title_cd NUMBER;
    BEGIN
        v_supp_title_cd := TO_NUMBER(p_supp_title_cd);
        SELECT supp_title_nm
          INTO p_supp_title_nm
          FROM supp_titles
         WHERE supp_title_cd = v_supp_title_cd;
        RETURN TRUE;
    EXCEPTION
        WHEN NO_DATA_FOUND OR VALUE_ERROR OR INVALID_NUMBER THEN
            p_supp_title_nm := NULL;
            RETURN FALSE;
    END find_supp_title;

    -- Clears the letter globals (the same six lines in WHEN-NEW-FORM-INSTANCE and CANCEL, mode 0).
    -- :GLOBAL.PORT_NAME and :GLOBAL.SUPP_TITLE_NAME are not carried over: no caller reads them
    -- (inventory §15 Q5); add G_PORT_NAME / G_SUPP_TITLE_NAME here and in AGREE if a caller needs them.
    PROCEDURE clear_letter_globals
    IS
    BEGIN
        FORMS_APX.SET_GLOBAL('PORT_CD', NULL);           -- :GLOBAL.PORT_CD := NULL;       (G_PORT_CD)
        FORMS_APX.SET_GLOBAL('SUPP_TITLE_CD', NULL);     -- :GLOBAL.SUPP_TITLE_CD := NULL; (G_SUPP_TITLE_CD)
        FORMS_APX.SET_GLOBAL('LETTER_NBR', NULL);        -- :GLOBAL.LETTER_NBR := NULL;    (G_LETTER_NBR)
        FORMS_APX.SET_GLOBAL('LETTER_DT', NULL);         -- :GLOBAL.LETTER_DT := NULL;     (G_LETTER_DT)
    END clear_letter_globals;

    -- =========================================================================
    -- FORM LEVEL
    -- =========================================================================
    -- Source: IF :PARAMETER.P_MODE = 0 (WHEN-NEW-FORM-INSTANCE, AGREE, CANCEL).
    -- A NULL mode takes the ELSE branch in Forms (edit); the parameter default is 1.
    FUNCTION IS_NEW_LETTER (P_MODE IN NUMBER) RETURN BOOLEAN
    IS
    BEGIN
        RETURN NVL(P_MODE = 0, FALSE);
    END IS_NEW_LETTER;

    -- Source: the callers' parameter list and CALL_FORM
    -- Original Forms code (IMPR1110 PU EXEC_FUNS, the same in IMPR1130 WHEN-NEW-FORM-INSTANCE):
    --   ADD_PARAMETER(PL_ID,'WINDOW_X_POS',TEXT_PARAMETER,1.5);  ADD_PARAMETER(PL_ID,'WINDOW_Y_POS',TEXT_PARAMETER,2);
    --   ADD_PARAMETER(PL_ID,'P_MODE',TEXT_PARAMETER,0);
    --   ADD_PARAMETER(PL_ID,'P_CURR_PORT_CD',TEXT_PARAMETER,:IMPORTERS.PORT_CD);
    --   CALL_FORM('SUPPORT_ENTRY.FMX',NO_HIDE,NO_REPLACE,NO_QUERY_ONLY,PL_ID);
    -- f345 SCREEN ENTRY RESET (Before Header, application level) clears P0_PAGE_PK and every item of the page
    -- unless G_LAST_PAGE is the page or its 01 page. G_LAST_PAGE is set to 9001 here, just before the dialog
    -- opens (not when the caller renders, which would reset the caller on its next render). A second call
    -- while 9001 is already the last page keeps the first caller.
    PROCEDURE OPEN_DIALOG (P_MODE         IN  NUMBER,
                           P_CURR_PORT_CD IN  NUMBER,
                           P_SUPPORT_URL  OUT VARCHAR2)
    IS
        v_last_page VARCHAR2(30) := FORMS_APX.GET_GLOBAL('LAST_PAGE');
    BEGIN
        IF v_last_page IS NULL OR v_last_page <> TO_CHAR(c_page_id) THEN
            FORMS_APX.SET_GLOBAL('SUPPORT_ENTRY_CALLER', v_last_page);     -- G_SUPPORT_ENTRY_CALLER
        END IF;
        FORMS_APX.SET_GLOBAL('LAST_PAGE', TO_CHAR(c_page_id));             -- G_LAST_PAGE
        P_SUPPORT_URL := APEX_PAGE.GET_URL(
                             p_page        => c_page_id,
                             p_clear_cache => TO_CHAR(c_page_id),
                             p_items       => 'P9001_P_MODE,P9001_P_CURR_PORT_CD',
                             p_values      => TO_CHAR(P_MODE) || ',' || TO_CHAR(P_CURR_PORT_CD));
    END OPEN_DIALOG;

    -- Source: SUPPORT_ENTRY.WHEN-NEW-FORM-INSTANCE
    -- Original Forms code:
    --   IF :PARAMETER.P_MODE = 0 THEN
    --      :GLOBAL.PORT_NAME := NULL;  :GLOBAL.SUPP_TITLE_NAME := NULL;  :GLOBAL.PORT_CD := NULL;
    --      :GLOBAL.SUPP_TITLE_CD := NULL;  :GLOBAL.LETTER_NBR := NULL;  :GLOBAL.LETTER_DT := NULL;
    --      SET_ITEM_PROPERTY('AGREE',LABEL,'موافق');  SET_ITEM_PROPERTY('CANCEL',LABEL,'تراجع');
    --      :P_PORT_CD := :PARAMETER.P_CURR_PORT_CD;
    --      GO_ITEM('P_PORT_CD');
    --      VALIDATE(ITEM_SCOPE);
    --   ELSE
    --      :P_PORT_CD := :GLOBAL.PORT_CD;  :SUPP_TITLE_CD := :GLOBAL.SUPP_TITLE_CD;
    --      :LETTER_NBR := :GLOBAL.LETTER_NBR;  :LETTER_DT := :GLOBAL.LETTER_DT;
    --      VALIDATE(FORM_SCOPE);
    --      SET_ITEM_PROPERTY('AGREE',LABEL,'تعديل');  SET_ITEM_PROPERTY('CANCEL',LABEL,'إغلاق');
    --   END IF;
    -- VALIDATE fires the WHEN-VALIDATE-ITEM triggers, which fill the names; their silent failure (unknown
    -- code) left the code on screen without a name - the same here (the validations report it on AGREE).
    -- Labels and GO_ITEM: UI LOGIC section at the end.
    PROCEDURE INIT_FORM (P_MODE          IN     NUMBER,
                         P_CURR_PORT_CD  IN     NUMBER,
                         P_PORT_CD       IN OUT VARCHAR2,
                         P_PORT_NAME     IN OUT VARCHAR2,
                         P_SUPP_TITLE_CD IN OUT VARCHAR2,
                         P_SUPP_TITLE_NM IN OUT VARCHAR2,
                         P_LETTER_NBR    IN OUT VARCHAR2,
                         P_LETTER_DT     IN OUT VARCHAR2)
    IS
    BEGIN
        IF IS_NEW_LETTER(P_MODE) THEN
            clear_letter_globals;
            P_PORT_CD := TO_CHAR(P_CURR_PORT_CD);       -- :P_PORT_CD := :PARAMETER.P_CURR_PORT_CD;
            P_PORT_CD_WHEN_VALIDATE_ITEM(P_PORT_CD, P_PORT_NAME);     -- VALIDATE(ITEM_SCOPE)
        ELSE
            P_PORT_CD       := FORMS_APX.GET_GLOBAL('PORT_CD');
            P_SUPP_TITLE_CD := FORMS_APX.GET_GLOBAL('SUPP_TITLE_CD');
            P_LETTER_NBR    := FORMS_APX.GET_GLOBAL('LETTER_NBR');
            P_LETTER_DT     := FORMS_APX.GET_GLOBAL('LETTER_DT');     -- HIJRI_DATE_FORMAT text (AGREE)
            P_PORT_CD_WHEN_VALIDATE_ITEM(P_PORT_CD, P_PORT_NAME);     -- VALIDATE(FORM_SCOPE)
            SUPP_TITLE_CD_VALIDATE_ITEM(P_SUPP_TITLE_CD, P_SUPP_TITLE_NM);
        END IF;
    END INIT_FORM;

    -- =========================================================================
    -- BLOCK RP  (control block)
    -- =========================================================================
    -- Source: RP.P_PORT_CD.WHEN-VALIDATE-ITEM
    -- Original Forms code:
    --   BEGIN
    --    IF :P_PORT_CD IS NULL THEN RETURN; END IF;
    --    SELECT PORT_NAME INTO :P_PORT_NAME FROM SD_PORTS WHERE PORT_CD = :P_PORT_CD;
    --   EXCEPTION
    --    WHEN NO_DATA_FOUND THEN RAISE FORM_TRIGGER_FAILURE;
    --   END;
    -- Returns NULL when valid, otherwise the error text.
    FUNCTION P_PORT_CD_VALIDATION (P_PORT_CD IN VARCHAR2) RETURN VARCHAR2
    IS
        v_port_name sd_ports.port_name%TYPE;
    BEGIN
        IF P_PORT_CD IS NULL THEN
            RETURN NULL;                                 -- required only on AGREE
        END IF;
        IF NOT find_port(P_PORT_CD, v_port_name) THEN
            RETURN c_port_not_found;                     -- RAISE FORM_TRIGGER_FAILURE (silent in Forms)
        END IF;
        RETURN NULL;
    END P_PORT_CD_VALIDATION;

    -- Source: RP.P_PORT_CD.WHEN-VALIDATE-ITEM - the part that fills :P_PORT_NAME
    -- A NULL code returns without touching the name (Forms RETURN), an unknown code leaves it as it was
    -- (Forms FORM_TRIGGER_FAILURE before the INTO).
    -- SUGGESTION: clear P_PORT_NAME when the code is cleared, so that no stale name stays on screen.
    PROCEDURE P_PORT_CD_WHEN_VALIDATE_ITEM (P_PORT_CD   IN     VARCHAR2,
                                            P_PORT_NAME IN OUT VARCHAR2)
    IS
        v_port_name sd_ports.port_name%TYPE;
    BEGIN
        IF P_PORT_CD IS NULL THEN
            RETURN;
        END IF;
        IF find_port(P_PORT_CD, v_port_name) THEN
            P_PORT_NAME := v_port_name;
        END IF;
    END P_PORT_CD_WHEN_VALIDATE_ITEM;

    -- Source: RP.SUPP_TITLE_CD.WHEN-VALIDATE-ITEM
    -- Original Forms code:
    --   BEGIN
    --    IF :SUPP_TITLE_CD IS NULL THEN RETURN; END IF;
    --    SELECT SUPP_TITLE_NM INTO :SUPP_TITLE_NM FROM SUPP_TITLES WHERE SUPP_TITLE_CD = :SUPP_TITLE_CD;
    --   EXCEPTION
    --    WHEN NO_DATA_FOUND THEN RAISE FORM_TRIGGER_FAILURE;
    --   END;
    FUNCTION SUPP_TITLE_CD_VALIDATION (P_SUPP_TITLE_CD IN VARCHAR2) RETURN VARCHAR2
    IS
        v_supp_title_nm supp_titles.supp_title_nm%TYPE;
    BEGIN
        IF P_SUPP_TITLE_CD IS NULL THEN
            RETURN NULL;                                 -- required only on AGREE
        END IF;
        IF NOT find_supp_title(P_SUPP_TITLE_CD, v_supp_title_nm) THEN
            RETURN c_supp_title_not_found;               -- RAISE FORM_TRIGGER_FAILURE (silent in Forms)
        END IF;
        RETURN NULL;
    END SUPP_TITLE_CD_VALIDATION;

    -- Source: RP.SUPP_TITLE_CD.WHEN-VALIDATE-ITEM - the part that fills :SUPP_TITLE_NM
    --         (full name SUPP_TITLE_CD_WHEN_VALIDATE_ITEM, 32 bytes)
    -- SUGGESTION: clear P_SUPP_TITLE_NM when the code is cleared (as P_PORT_CD).
    PROCEDURE SUPP_TITLE_CD_VALIDATE_ITEM (P_SUPP_TITLE_CD IN     VARCHAR2,
                                           P_SUPP_TITLE_NM IN OUT VARCHAR2)
    IS
        v_supp_title_nm supp_titles.supp_title_nm%TYPE;
    BEGIN
        IF P_SUPP_TITLE_CD IS NULL THEN
            RETURN;
        END IF;
        IF find_supp_title(P_SUPP_TITLE_CD, v_supp_title_nm) THEN
            P_SUPP_TITLE_NM := v_supp_title_nm;
        END IF;
    END SUPP_TITLE_CD_VALIDATE_ITEM;

    -- Source: RP.LETTER_DT (Datetime, FormatMask MI-MM-RRRR; WHEN-VALIDATE-ITEM, KEY-LISTVAL, KEY-F4 empty)
    -- Forms refused a text that did not fit the mask. Here the text must fit FORMS_APX.HIJRI_DATE_FORMAT
    -- (the f345 Hijri picker) and be a valid Hijri date (HIJDATE_DB.VALID_HIJ_DATE), as in IMPR1110 / IMPR1120.
    FUNCTION LETTER_DT_VALIDATION (P_LETTER_DT IN VARCHAR2) RETURN VARCHAR2
    IS
    BEGIN
        RETURN FORMS_APX.HIJRI_DATE_ERROR(P_LETTER_DT);    -- NULL text -> NULL (required only on AGREE)
    END LETTER_DT_VALIDATION;

    -- Source: RP.AGREE.WHEN-BUTTON-PRESSED
    -- Original Forms code:
    --   IF :P_PORT_CD IS NULL THEN GO_ITEM('P_PORT_CD'); RAISE FORM_TRIGGER_FAILURE; END IF;
    --   IF :SUPP_TITLE_CD IS NULL THEN GO_ITEM('SUPP_TITLE_CD'); RAISE FORM_TRIGGER_FAILURE; END IF;
    --   IF :LETTER_NBR IS NULL THEN GO_ITEM('LETTER_NBR'); RAISE FORM_TRIGGER_FAILURE; END IF;
    --   IF :LETTER_DT IS NULL THEN GO_ITEM('LETTER_DT'); RAISE FORM_TRIGGER_FAILURE; END IF;
    --   :GLOBAL.PORT_CD := :P_PORT_CD;          :GLOBAL.PORT_NAME := :P_PORT_NAME;
    --   :GLOBAL.SUPP_TITLE_CD := :SUPP_TITLE_CD; :GLOBAL.SUPP_TITLE_NAME := :SUPP_TITLE_NM;
    --   :GLOBAL.LETTER_NBR := :LETTER_NBR;      :GLOBAL.LETTER_DT := :LETTER_DT;
    --   IF :PARAMETER.P_MODE = 0 THEN EXIT_FORM(NO_VALIDATE); END IF;
    -- The page validations ("<ITEM> REQUIRED", "<ITEM> VALIDATION") run first and show each message at its
    -- item; the same checks are repeated here in the Forms order, so that the globals are never set with a
    -- missing or unknown value (DB_JOURNAL's journal trigger refuses NULLs, inventory §10.6).
    -- SUGGESTION: Forms stopped without a message; the required messages are FORMS_APX.REQUIRED_VALIDATION.
    -- EXIT_FORM (mode 0) -> APEX Close Dialog process; GO_ITEM -> the page shows the error at the item.
    PROCEDURE AGREE_WHEN_BUTTON_PRESSED (P_PORT_CD       IN VARCHAR2,
                                         P_SUPP_TITLE_CD IN VARCHAR2,
                                         P_LETTER_NBR    IN VARCHAR2,
                                         P_LETTER_DT     IN VARCHAR2)
    IS
    BEGIN
        FORMS_APX.CHECK_ERROR(FORMS_APX.REQUIRED_VALIDATION(P_PORT_CD, c_port_label));
        FORMS_APX.CHECK_ERROR(FORMS_APX.REQUIRED_VALIDATION(P_SUPP_TITLE_CD, c_supp_title_label));
        FORMS_APX.CHECK_ERROR(FORMS_APX.REQUIRED_VALIDATION(P_LETTER_NBR, c_letter_nbr_label));
        FORMS_APX.CHECK_ERROR(FORMS_APX.REQUIRED_VALIDATION(P_LETTER_DT, c_letter_dt_label));
        FORMS_APX.CHECK_ERROR(P_PORT_CD_VALIDATION(P_PORT_CD));
        FORMS_APX.CHECK_ERROR(SUPP_TITLE_CD_VALIDATION(P_SUPP_TITLE_CD));
        FORMS_APX.CHECK_ERROR(LETTER_DT_VALIDATION(P_LETTER_DT));

        FORMS_APX.SET_GLOBAL('PORT_CD', P_PORT_CD);               -- :GLOBAL.PORT_CD := :P_PORT_CD;
        FORMS_APX.SET_GLOBAL('SUPP_TITLE_CD', P_SUPP_TITLE_CD);   -- :GLOBAL.SUPP_TITLE_CD := :SUPP_TITLE_CD;
        FORMS_APX.SET_GLOBAL('LETTER_NBR', P_LETTER_NBR);         -- :GLOBAL.LETTER_NBR := :LETTER_NBR;
        FORMS_APX.SET_GLOBAL('LETTER_DT', P_LETTER_DT);           -- :GLOBAL.LETTER_DT := :LETTER_DT; (text)
        -- :GLOBAL.PORT_NAME / :GLOBAL.SUPP_TITLE_NAME: not carried over (no reader, inventory §15 Q5)
    END AGREE_WHEN_BUTTON_PRESSED;

    -- Source: RP.CANCEL.WHEN-BUTTON-PRESSED
    -- Original Forms code:
    --   IF :PARAMETER.P_MODE = 0 THEN
    --      :GLOBAL.PORT_NAME := NULL;  :GLOBAL.SUPP_TITLE_NAME := NULL;  :GLOBAL.PORT_CD := NULL;
    --      :GLOBAL.SUPP_TITLE_CD := NULL;  :GLOBAL.LETTER_NBR := NULL;  :GLOBAL.LETTER_DT := NULL;
    --   END IF;
    --   EXIT_FORM(NO_VALIDATE);
    -- EXIT_FORM(NO_VALIDATE) -> APEX Close Dialog without validations. Edit mode ("إغلاق") keeps the globals.
    PROCEDURE CANCEL_WHEN_BUTTON_PRESSED (P_MODE IN NUMBER)
    IS
    BEGIN
        IF IS_NEW_LETTER(P_MODE) THEN
            clear_letter_globals;
        END IF;
    END CANCEL_WHEN_BUTTON_PRESSED;

    -- =========================================================================
    -- PROGRAM UNITS   (none in the form)
    -- =========================================================================

    -- =========================================================================
    -- UI LOGIC FOR APEX DYNAMIC ACTIONS  (comments only - no executable code)
    -- =========================================================================
    -- APEX-DA: [Source: SUPPORT_ENTRY.WHEN-NEW-FORM-INSTANCE] button labels by mode
    -- Original : SET_ITEM_PROPERTY('AGREE',LABEL,'موافق' / 'تعديل'); SET_ITEM_PROPERTY('CANCEL',LABEL,'تراجع' / 'إغلاق');
    -- Implement: two button pairs - AGREE "موافق" + CANCEL "تراجع" with condition
    --            SUPPORT_ENTRY.IS_NEW_LETTER(P_MODE => :P9001_P_MODE); AGREE_EDIT "تعديل" + CANCEL_EDIT "إغلاق"
    --            with NOT IS_NEW_LETTER. Same processes for each pair (step 03 decides).
    --
    -- APEX-DA: [Source: SUPPORT_ENTRY.WHEN-NEW-FORM-INSTANCE] GO_ITEM('P_PORT_CD') in mode 0
    -- Implement: page attribute Cursor Focus = First item on page (P9001_P_PORT_CD is the first entry item).
    --
    -- APEX-DA: [Source: SUPPORT_ENTRY.PRE-FORM] SET_WINDOW_PROPERTY('RP_WINDOW',POSITION,X,Y)
    -- Implement: nothing - modal dialog page (f345 Modal Dialog template); WINDOW_X_POS / WINDOW_Y_POS dropped.
    --
    -- APEX-DA: [Source: RP.P_LOV_PORT.WHEN-BUTTON-PRESSED] GO_ITEM('P_PORT_CD'); DO_KEY('LIST_VALUES');
    -- Implement: P9001_P_PORT_CD is a Popup LOV on shared LOV LOV_SD_PORTS_TYPES (decision D2: SD_PORTS +
    --            CG_REF_CODES 'PORT_TYPE_CD', columns PORT_CD / RV_MEANING / PORT_NAME); its own button replaces
    --            P_LOV_PORT. The commented-out CALL_FORM('REP_LOV_SD_PORTS.FMX') is not converted.
    --
    -- APEX-DA: [Source: RP.P_LOV_SUPP_TITLES.WHEN-BUTTON-PRESSED] GO_ITEM('SUPP_TITLE_CD'); DO_KEY('LIST_VALUES');
    -- Implement: P9001_SUPP_TITLE_CD is a Popup LOV on shared LOV LOV_SUPP_TITLES
    --            (SUPP_TITLES WHERE TITLE_STATUS = 1); the commented-out CALL_FORM('LOV_SUPP_TITLES.FMX') is not converted.
    --
    -- APEX-DA: [Source: RP.P_PORT_CD.WHEN-VALIDATE-ITEM] DA "P_PORT_CD WHEN-VALIDATE-ITEM" (change, FOS)
    --            FORMS_APX.CHECK_ERROR(SUPPORT_ENTRY.P_PORT_CD_VALIDATION(P_PORT_CD => :P9001_P_PORT_CD));
    --            SUPPORT_ENTRY.P_PORT_CD_WHEN_VALIDATE_ITEM(P_PORT_CD => :P9001_P_PORT_CD, P_PORT_NAME => :P9001_P_PORT_NAME);
    --            (the Popup LOV may also return PORT_NAME directly; the DA keeps typed codes working)
    --
    -- APEX-DA: [Source: RP.SUPP_TITLE_CD.WHEN-VALIDATE-ITEM] DA "SUPP_TITLE_CD WHEN-VALIDATE-ITEM" (change, FOS)
    --            FORMS_APX.CHECK_ERROR(SUPPORT_ENTRY.SUPP_TITLE_CD_VALIDATION(P_SUPP_TITLE_CD => :P9001_SUPP_TITLE_CD));
    --            SUPPORT_ENTRY.SUPP_TITLE_CD_VALIDATE_ITEM(P_SUPP_TITLE_CD => ..., P_SUPP_TITLE_NM => :P9001_SUPP_TITLE_NM);
    --
    -- APEX-DA: [Source: RP.LETTER_DT KEY-LISTVAL / KEY-F4 (empty)] no list on the date
    -- Implement: the f345 Hijri date picker as in IMPR1110 (a picker, not an LOV); nothing else.
    --
    -- APEX-DA: [Source: RP.P_PORT_NAME / RP.SUPP_TITLE_NM Enabled = false] display items
    -- Implement: Display Only (or Text Field Read Only = Always), not submitted for validation.
    --
    -- APEX-DA: [Source: RP.AGREE / RP.CANCEL EXIT_FORM(NO_VALIDATE)] Close Dialog
    -- Implement: page 9001 never submits. DA "AGREE WHEN-BUTTON-PRESSED" / "CANCEL WHEN-BUTTON-PRESSED": FOS call,
    --            then native Close Dialog (fires "Dialog Closed" on the caller, which reads G_LETTER_NBR).
    --            AGREE closes in both modes (decision D1: the edit dialog is opened on demand).
    --            The dialog's X closes without a call: the globals stay as INIT_FORM left them (cleared in
    --            mode 0) - the same result as CANCEL; G_LAST_PAGE is already the caller (process G_LAST_PAGE KEEP).
    --
    -- APEX-DA: [Source: f345 page 0 toolbar] P0_ACTIONS is shown on every page except 100000
    -- Implement: page 9001 DA "Hide" (Page Load, native Hide of region P0_ACTIONS), the f345 AGR1100_SEARCH pattern
    --            (SAVE / DELETE of the caller's record must not appear inside the dialog; page 0 is not changed).

END SUPPORT_ENTRY;
/
SHOW ERRORS
