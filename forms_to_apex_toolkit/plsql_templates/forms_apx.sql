-- =============================================================================
-- Owner       : LIB_APX_USR (public synonym FORMS_APX; EXECUTE granted to LIB_USR, SECURITY_DEFAULT, SECURITY_PROD, CUSTOMS)
-- Package     : FORMS_APX
-- Purpose     : Forms-like server-side "built-ins" for migrated code, so converted
--               trigger code reads like the original Forms code.
--               (MESSAGE, RAISE FORM_TRIGGER_FAILURE, SHOW_ALERT, :GLOBAL, NAME_IN,
--               COPY, USER, :SYSTEM.CURRENT_FORM) + an APEX error handling function.
-- Target      : Oracle APEX 21.2 / Oracle Database 12.1.0.2
-- Install     : once per parsing schema (FORMS_MIGRATION). Not form-specific.
-- Notes       : Works inside an APEX session AND outside (SQL*Plus / utPLSQL):
--               outside APEX, globals are kept in package memory and messages go to
--               DBMS_OUTPUT, so the <FORM> packages stay unit-testable.
--               UI built-ins (GO_BLOCK, SET_ITEM_PROPERTY ...) are NOT here -> Dynamic Actions.
-- Status      : NOT YET COMPILED against a real 12.1.0.2 / APEX 21.2 instance - compile in DEV first.
-- Version 004 : (2026-11-24, user request) the helpers common to every form package moved here: CHECK_ERROR,
--               REQUIRED_VALIDATION, GET_MODULE_ID, HEADER_TITLE, ROWID_FROM_URL, the Hijri date helpers
--               (HIJRI_DATE_FORMAT ...) and the CIC_LIB conversions (ARABIC_MESSAGE, CG_MESSAGE, CUR_HIJ_DATE).
--               Pages call them directly (FORMS_APX.CHECK_ERROR(<FORM>.<ITEM>_VALIDATION(...))).
--               Depends on STR_DB, HIJDATE_DB and SC_SYSTEM_OBJECTS, as the form packages did.
--               Previous version: rollback/FORMS_APX/v003/
-- =============================================================================
SET DEFINE OFF

CREATE OR REPLACE PACKAGE LIB_APX_USR.FORMS_APX AS
   V_PKG_VERSION       VARCHAR2 (100) := 'VERSION NO. IS:' || '004';
   V_PKG_VERSION_QC    VARCHAR2 (100) := 'VERSION NO. IS:' || '001';
   V_PKG_VERSION_DEV   VARCHAR2 (100) := 'VERSION NO. IS:' || '001';
   FUNCTION PKG_VERSION
      RETURN VARCHAR2;
   V_PACKAGE_NAME      VARCHAR2 (50) := 'FORMS_APX';
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

    c_err_ftf       CONSTANT PLS_INTEGER := -20000;   -- FORM_TRIGGER_FAILURE equivalent
    c_global_prefix CONSTANT VARCHAR2(3) := 'G_';     -- :GLOBAL.X -> application item G_X (f345 convention; was AI_)

    -- TRUE when called inside an APEX session
    FUNCTION in_apex RETURN BOOLEAN;

    -- MESSAGE('text')  -> success message of the current page process
    PROCEDURE message (p_text IN VARCHAR2);

    -- MESSAGE('text'); RAISE FORM_TRIGGER_FAILURE;
    PROCEDURE FORM_TRIGGER_FAILURE (p_text IN VARCHAR2 DEFAULT NULL);

    -- Text of an alert (Text Message with the same name as the Forms alert).
    -- %0..%2 placeholders are replaced by p0..p2.
    FUNCTION alert_text (
        p_alert_name IN VARCHAR2,
        p0           IN VARCHAR2 DEFAULT NULL,
        p1           IN VARCHAR2 DEFAULT NULL,
        p2           IN VARCHAR2 DEFAULT NULL
    ) RETURN VARCHAR2;

    -- SHOW_ALERT('AL_X') used as a STOP alert followed by RAISE FORM_TRIGGER_FAILURE.
    -- (Yes/No alerts are UI -> Confirm Dynamic Action; see dynamic_action_patterns.sql)
    PROCEDURE alert (
        p_alert_name IN VARCHAR2,
        p0           IN VARCHAR2 DEFAULT NULL,
        p1           IN VARCHAR2 DEFAULT NULL,
        p2           IN VARCHAR2 DEFAULT NULL
    );

    -- :GLOBAL.<name>  (stored in application item G_<NAME>, f345 convention)
    FUNCTION  get_global (p_name IN VARCHAR2) RETURN VARCHAR2;
    PROCEDURE set_global (p_name IN VARCHAR2, p_value IN VARCHAR2);
    PROCEDURE erase_global (p_name IN VARCHAR2);

    -- NAME_IN('P120_STATUS') / COPY(value, 'P120_STATUS')  (page items / app items)
    FUNCTION  name_in (p_item_name IN VARCHAR2) RETURN VARCHAR2;
    PROCEDURE copy (p_value IN VARCHAR2, p_item_name IN VARCHAR2);

    -- USER / GET_APPLICATION_PROPERTY(USERNAME)
    FUNCTION app_user RETURN VARCHAR2;

    -- :SYSTEM.CURRENT_FORM  -> alias of the current page (= Forms module name)
    FUNCTION current_form RETURN VARCHAR2;

    -- Application error handling function (Application > Edit Application Properties >
    -- Error Handling > Error Handling Function = FORMS_APX.apex_error_handler).
    -- Shows business errors (-20000..-20999) without the "ORA-200xx:" prefix and
    -- translates constraint violations via Text Messages named after the constraint.
    FUNCTION apex_error_handler (p_error IN apex_error.t_error)
        RETURN apex_error.t_error_result;

    -- =========================================================================
    -- COMMON HELPERS OF THE FORM PACKAGES (version 004; were copied in every <FORM> package)
    -- Parameters called by pages are named after their binds (CLAUDE.md §4).
    -- =========================================================================
    -- Raises ERROR_TEXT when it is not null.
    -- APEX  : FOS dynamic actions: FORMS_APX.CHECK_ERROR(<FORM>.<ITEM>_VALIDATION(...));
    PROCEDURE CHECK_ERROR (ERROR_TEXT IN VARCHAR2);

    -- Forms FRM-40202 "Field must be entered": error text when ITEM_VALUE is empty, else NULL.
    -- APEX  : Validation "<ITEM> REQUIRED": return FORMS_APX.REQUIRED_VALIDATION(ITEM_VALUE => :P<page>_<ITEM>, ITEM_LABEL => '<label>');
    FUNCTION  REQUIRED_VALIDATION (ITEM_VALUE IN VARCHAR2, ITEM_LABEL IN VARCHAR2) RETURN VARCHAR2;

    -- f345: SC_SYSTEM_OBJECTS id of the form (module), kept once known.
    -- APEX  : Process "PARAMETERS": :P<page>_MODULE_ID := FORMS_APX.GET_MODULE_ID(P_MODULE_ID => :P<page>_MODULE_ID, FORM_NAME => '<FORM>');
    FUNCTION  GET_MODULE_ID (P_MODULE_ID IN VARCHAR2, FORM_NAME IN VARCHAR2) RETURN VARCHAR2;

    -- f345 hero title (OLB block TITLE): SC_SYSTEM_OBJECTS.SYS_ANAME of the module, else DEFAULT_TITLE.
    -- APEX  : Process "HEADER TITLE": FORMS_APX.HEADER_TITLE(P_MODULE_ID => :P<page>_MODULE_ID,
    --           P_HERO_TITLE => :P<page>_HERO_TITLE, DEFAULT_TITLE => '<form title>');
    PROCEDURE HEADER_TITLE (P_MODULE_ID   IN     VARCHAR2,
                            P_HERO_TITLE  IN OUT VARCHAR2,
                            DEFAULT_TITLE IN     VARCHAR2);

    -- A search page <page>01 passes the ROWID key URL-safe (TRANSLATE(ROWID, '+/', '-_')): a '+' in f?p
    -- arrives as a space and the checksum fails. Back to the ROWID text; a ROWID never contains '-' or '_'.
    -- Used by <FORM>.P0_PAGE_PK_CHECK.
    FUNCTION  ROWID_FROM_URL (p_value IN VARCHAR2) RETURN VARCHAR2;

    -- Hijri date format of the application: APEX Application Setting HIJRI_DATE_FORMAT, default YYYY-MM-MI
    -- (the f345 Hijri picker writes iYYYY-iMM-iDD; the day is kept in the minutes, so e.g. 30-02 fits in a
    -- DATE). Change the setting (Shared Components > Application Settings, or APEX_APP_SETTING.SET_VALUE).
    -- APEX  : region SQL TO_CHAR(<date>, (SELECT FORMS_APX.HIJRI_DATE_FORMAT FROM dual)); computation
    --         P<page>_HIJRI_DATE_FORMAT = FORMS_APX.HIJRI_DATE_FORMAT (format mask &P<page>_HIJRI_DATE_FORMAT.)
    FUNCTION  HIJRI_DATE_FORMAT RETURN VARCHAR2;

    -- Forms FRM-50026 "Date must be entered in a format like <mask>", in the format of the setting
    -- (YYYY-MM-MI -> سنة-شهر-يوم). TODO: confirm the Arabic text.
    FUNCTION  DATE_FORMAT_MESSAGE RETURN VARCHAR2;

    -- Hijri date text (format HIJRI_DATE_FORMAT) -> DATE. No calendar conversion: the text is already Hijri
    -- (HIJDATE_DB.TO_HIJRI would convert a Gregorian date). A wrong format raises DATE_FORMAT_MESSAGE.
    FUNCTION  HIJRI_TEXT_TO_DATE (p_text IN VARCHAR2) RETURN DATE;

    -- DATE -> Hijri date text in the format HIJRI_DATE_FORMAT
    FUNCTION  HIJRI_TEXT (p_date IN DATE) RETURN VARCHAR2;

    -- HIJDATE.VALID_HIJ_DATE (CIC_LIB.pld) as an error text: NULL = valid or empty; a wrong format gives
    -- DATE_FORMAT_MESSAGE (Forms FRM-50026 before WHEN-VALIDATE-ITEM).
    FUNCTION  HIJRI_DATE_ERROR (p_text IN VARCHAR2) RETURN VARCHAR2;

    -- HIJDATE.Cur_Hij_Date (CIC_LIB.pld): HIJDATE_DB.Cur_Hij_Date(V_MSG); NULL -> FORM_TRIGGER_FAILURE(V_MSG)
    FUNCTION  CUR_HIJ_DATE RETURN DATE;

    -- Text of STR.DispArbMsg(sys, nbr) (CIC_LIB.pld): STR_DB.GetArbMsg(sys, nbr) as '<sys>-<nbr> : <text>';
    -- '-1' = unknown message number.
    FUNCTION  ARABIC_MESSAGE (p_sys IN NUMBER, p_nbr IN NUMBER) RETURN VARCHAR2;

    -- ret := Str.DispArbMsg(s, n, ...); RAISE FORM_TRIGGER_FAILURE;
    PROCEDURE DISPLAY_ARABIC_ERROR (p_sys IN NUMBER, p_nbr IN NUMBER);

    -- ret := Str.DispArbMsg(s, n, ...);   (no raise: page success message)
    PROCEDURE DISPLAY_ARABIC_INFO (p_sys IN NUMBER, p_nbr IN NUMBER);

    -- Des$Form_errors.MSGGETTEXT(n, '<p1> ...', p1) (CG library, MISSING SOURCE): the English default
    -- text with <p1> replaced. TODO: verify the Arabic text it returns.
    FUNCTION  CG_MESSAGE (p_default IN VARCHAR2, p1 IN VARCHAR2) RETURN VARCHAR2;

END FORMS_APX;
/
SHOW ERRORS

CREATE OR REPLACE PACKAGE BODY LIB_APX_USR.FORMS_APX
AS
    -- Fallback storage for globals when running outside APEX (unit tests, SQL*Plus)
    TYPE t_globals IS TABLE OF VARCHAR2(4000) INDEX BY VARCHAR2(30);
    g_globals t_globals;
    c_err_check         CONSTANT PLS_INTEGER  := -20001;        -- CHECK_ERROR (as the form packages)
    c_hijri_date_format CONSTANT VARCHAR2(30) := 'YYYY-MM-MI';  -- default of the setting HIJRI_DATE_FORMAT

    FUNCTION in_apex RETURN BOOLEAN
    IS
    BEGIN
        RETURN sys_context('APEX$SESSION', 'APP_SESSION') IS NOT NULL;
    END in_apex;

    FUNCTION global_item (p_name IN VARCHAR2) RETURN VARCHAR2
    IS
    BEGIN
        RETURN c_global_prefix || UPPER(TRIM(p_name));
    END global_item;

    -- Source: Forms built-in MESSAGE
    PROCEDURE message (p_text IN VARCHAR2)
    IS
    BEGIN
        IF in_apex THEN
            apex_application.g_print_success_message := p_text;
        ELSE
            dbms_output.put_line('MESSAGE: ' || p_text);
        END IF;
    END message;

    -- Source: MESSAGE + RAISE FORM_TRIGGER_FAILURE
    PROCEDURE FORM_TRIGGER_FAILURE (p_text IN VARCHAR2 DEFAULT NULL)
    IS
    BEGIN
        raise_application_error(c_err_ftf, NVL(p_text, 'FORM_TRIGGER_FAILURE'));
    END FORM_TRIGGER_FAILURE;

    FUNCTION alert_text (
        p_alert_name IN VARCHAR2,
        p0           IN VARCHAR2 DEFAULT NULL,
        p1           IN VARCHAR2 DEFAULT NULL,
        p2           IN VARCHAR2 DEFAULT NULL
    ) RETURN VARCHAR2
    IS
    BEGIN
        IF in_apex THEN
            -- Returns the message name itself when the Text Message does not exist
            RETURN apex_lang.message(p_name => UPPER(p_alert_name), p0 => p0, p1 => p1, p2 => p2);
        END IF;
        RETURN UPPER(p_alert_name)
               || CASE WHEN p0 IS NOT NULL THEN ' ' || p0 END
               || CASE WHEN p1 IS NOT NULL THEN ' ' || p1 END
               || CASE WHEN p2 IS NOT NULL THEN ' ' || p2 END;
    END alert_text;

    -- Source: SHOW_ALERT (stop alert) + RAISE FORM_TRIGGER_FAILURE
    PROCEDURE alert (
        p_alert_name IN VARCHAR2,
        p0           IN VARCHAR2 DEFAULT NULL,
        p1           IN VARCHAR2 DEFAULT NULL,
        p2           IN VARCHAR2 DEFAULT NULL
    )
    IS
    BEGIN
        FORM_TRIGGER_FAILURE(alert_text(p_alert_name, p0, p1, p2));
    END alert;

    -- Source: :GLOBAL.<name>
    FUNCTION get_global (p_name IN VARCHAR2) RETURN VARCHAR2
    IS
    BEGIN
        IF in_apex THEN
            RETURN apex_util.get_session_state(p_item => global_item(p_name));
        END IF;
        IF g_globals.EXISTS(global_item(p_name)) THEN
            RETURN g_globals(global_item(p_name));
        END IF;
        RETURN NULL;
    END get_global;

    PROCEDURE set_global (p_name IN VARCHAR2, p_value IN VARCHAR2)
    IS
    BEGIN
        IF in_apex THEN
            apex_util.set_session_state(p_name => global_item(p_name), p_value => p_value);
        ELSE
            g_globals(global_item(p_name)) := p_value;
        END IF;
    END set_global;

    -- Source: ERASE('GLOBAL.<name>')
    PROCEDURE erase_global (p_name IN VARCHAR2)
    IS
    BEGIN
        IF in_apex THEN
            apex_util.set_session_state(p_name => global_item(p_name), p_value => NULL);
        ELSIF g_globals.EXISTS(global_item(p_name)) THEN
            g_globals.DELETE(global_item(p_name));
        END IF;
    END erase_global;

    -- Source: NAME_IN
    FUNCTION name_in (p_item_name IN VARCHAR2) RETURN VARCHAR2
    IS
    BEGIN
        IF in_apex THEN
            RETURN apex_util.get_session_state(p_item => UPPER(p_item_name));
        END IF;
        IF g_globals.EXISTS(UPPER(p_item_name)) THEN
            RETURN g_globals(UPPER(p_item_name));
        END IF;
        RETURN NULL;
    END name_in;

    -- Source: COPY
    PROCEDURE copy (p_value IN VARCHAR2, p_item_name IN VARCHAR2)
    IS
    BEGIN
        IF in_apex THEN
            apex_util.set_session_state(p_name => UPPER(p_item_name), p_value => p_value);
        ELSE
            g_globals(UPPER(p_item_name)) := p_value;
        END IF;
    END copy;

    -- Source: USER / GET_APPLICATION_PROPERTY(USERNAME)
    FUNCTION app_user RETURN VARCHAR2
    IS
    BEGIN
        RETURN NVL(sys_context('APEX$SESSION', 'APP_USER'), USER);
    END app_user;

    -- Source: :SYSTEM.CURRENT_FORM
    FUNCTION current_form RETURN VARCHAR2
    IS
        v_alias VARCHAR2(255);
    BEGIN
        IF NOT in_apex THEN
            RETURN NULL;
        END IF;
        SELECT page_alias
          INTO v_alias
          FROM apex_application_pages
         WHERE application_id = apex_application.g_flow_id
           AND page_id        = apex_application.g_flow_step_id;
        RETURN v_alias;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END current_form;

    FUNCTION apex_error_handler (p_error IN apex_error.t_error)
        RETURN apex_error.t_error_result
    IS
        v_result     apex_error.t_error_result;
        v_constraint VARCHAR2(255);
        v_text       VARCHAR2(4000);
    BEGIN
        v_result := apex_error.init_error_result(p_error => p_error);

        IF NOT p_error.is_internal_error THEN
            -- Business errors from FORM_TRIGGER_FAILURE / alert / raise_application_error: clean text
            IF p_error.ora_sqlcode BETWEEN -20999 AND -20000 THEN
                v_result.message         := apex_error.get_first_ora_error_text(p_error => p_error);
                v_result.additional_info := NULL;

            -- Constraint violations: Text Message named after the constraint (if defined)
            ELSIF p_error.ora_sqlcode IN (-1, -2091, -2290, -2291, -2292) THEN
                v_constraint := apex_error.extract_constraint_name(p_error => p_error);
                IF v_constraint IS NOT NULL THEN
                    v_text := apex_lang.message(p_name => v_constraint);
                    IF v_text IS NOT NULL AND v_text <> v_constraint THEN
                        v_result.message         := v_text;
                        v_result.additional_info := NULL;
                    END IF;
                END IF;
            END IF;
        END IF;

        RETURN v_result;
    END apex_error_handler;

    -- =========================================================================
    -- COMMON HELPERS OF THE FORM PACKAGES (version 004)
    -- =========================================================================
    PROCEDURE CHECK_ERROR (ERROR_TEXT IN VARCHAR2)
    IS
    BEGIN
        IF ERROR_TEXT IS NOT NULL THEN
            raise_application_error(c_err_check, ERROR_TEXT);
        END IF;
    END CHECK_ERROR;

    FUNCTION REQUIRED_VALIDATION (ITEM_VALUE IN VARCHAR2, ITEM_LABEL IN VARCHAR2) RETURN VARCHAR2
    IS
    BEGIN
        RETURN CASE WHEN TRIM(ITEM_VALUE) IS NULL THEN 'يجب إدخال ' || ITEM_LABEL END;
    END REQUIRED_VALIDATION;

    FUNCTION GET_MODULE_ID (P_MODULE_ID IN VARCHAR2, FORM_NAME IN VARCHAR2) RETURN VARCHAR2
    IS
        v_id VARCHAR2(40);
    BEGIN
        IF P_MODULE_ID IS NOT NULL THEN
            RETURN P_MODULE_ID;
        END IF;
        SELECT TO_CHAR(MIN(o.sysobj_id))
          INTO v_id
          FROM sc_system_objects o
         WHERE UPPER(REGEXP_REPLACE(o.sys_os_file_name, '\..*$', '')) = UPPER(GET_MODULE_ID.FORM_NAME);
        RETURN v_id;
    END GET_MODULE_ID;

    PROCEDURE HEADER_TITLE (P_MODULE_ID   IN     VARCHAR2,
                            P_HERO_TITLE  IN OUT VARCHAR2,
                            DEFAULT_TITLE IN     VARCHAR2)
    IS
        v_name VARCHAR2(400);
    BEGIN
        IF P_MODULE_ID IS NOT NULL THEN
            SELECT MAX(o.sys_aname)
              INTO v_name
              FROM sc_system_objects o
             WHERE o.sysobj_id = TO_NUMBER(HEADER_TITLE.P_MODULE_ID);
        END IF;
        P_HERO_TITLE := NVL(v_name, DEFAULT_TITLE);
    EXCEPTION
        WHEN VALUE_ERROR OR INVALID_NUMBER THEN      -- module id is not a number
            P_HERO_TITLE := DEFAULT_TITLE;
    END HEADER_TITLE;

    FUNCTION ROWID_FROM_URL (p_value IN VARCHAR2) RETURN VARCHAR2
    IS
    BEGIN
        RETURN TRANSLATE(p_value, '-_', '+/');
    END ROWID_FROM_URL;

    FUNCTION HIJRI_DATE_FORMAT RETURN VARCHAR2
    IS
    BEGIN
        RETURN NVL(APEX_APP_SETTING.GET_VALUE(p_name => 'HIJRI_DATE_FORMAT'), c_hijri_date_format);
    EXCEPTION
        WHEN OTHERS THEN               -- no APEX session / setting missing: the default format
            RETURN c_hijri_date_format;
    END HIJRI_DATE_FORMAT;

    FUNCTION DATE_FORMAT_MESSAGE RETURN VARCHAR2
    IS
        v_format VARCHAR2(30) := HIJRI_DATE_FORMAT;
    BEGIN
        RETURN 'يجب إدخال التاريخ بالصيغة '
               || REPLACE(REPLACE(REPLACE(REPLACE(UPPER(v_format), 'YYYY', 'سنة'), 'RRRR', 'سنة'), 'MI', 'يوم'), 'MM', 'شهر')
               || ' (' || v_format || ')';
    END DATE_FORMAT_MESSAGE;

    FUNCTION HIJRI_TEXT_TO_DATE (p_text IN VARCHAR2) RETURN DATE
    IS
    BEGIN
        RETURN TO_DATE(p_text, HIJRI_DATE_FORMAT);
    EXCEPTION
        WHEN OTHERS THEN               -- ORA-01821 / ORA-01843 / ORA-01847 ...: not in the format
            FORM_TRIGGER_FAILURE(DATE_FORMAT_MESSAGE);
            RETURN NULL;               -- not reached
    END HIJRI_TEXT_TO_DATE;

    FUNCTION HIJRI_TEXT (p_date IN DATE) RETURN VARCHAR2
    IS
    BEGIN
        RETURN TO_CHAR(p_date, HIJRI_DATE_FORMAT);
    END HIJRI_TEXT;

    FUNCTION HIJRI_DATE_ERROR (p_text IN VARCHAR2) RETURN VARCHAR2
    IS
        v_msg  VARCHAR2(2000);
        v_date DATE;
    BEGIN
        IF p_text IS NULL THEN
            RETURN NULL;
        END IF;
        BEGIN
            v_date := TO_DATE(p_text, HIJRI_DATE_FORMAT);
        EXCEPTION
            WHEN OTHERS THEN
                RETURN DATE_FORMAT_MESSAGE;
        END;
        IF hijdate_db.valid_hij_date(v_date, v_msg) = 0 THEN
            RETURN NVL(v_msg, 'التاريخ غير صحيح');
        END IF;
        RETURN NULL;
    END HIJRI_DATE_ERROR;

    FUNCTION CUR_HIJ_DATE RETURN DATE
    IS
        v_msg VARCHAR2(2000);
        v_ret DATE;
    BEGIN
        v_ret := hijdate_db.cur_hij_date(v_msg);
        IF v_ret IS NULL THEN
            FORM_TRIGGER_FAILURE(v_msg);
        END IF;
        RETURN v_ret;
    END CUR_HIJ_DATE;

    FUNCTION ARABIC_MESSAGE (p_sys IN NUMBER, p_nbr IN NUMBER) RETURN VARCHAR2
    IS
        v_txt VARCHAR2(4000);
    BEGIN
        v_txt := str_db.getarbmsg(p_sys, p_nbr);
        IF v_txt = '-1' THEN
            RETURN 'خطأ فى رقم الرسالة ' || p_sys || '-' || p_nbr || 'إتصل بالمسانده الفنيه';
        END IF;
        RETURN p_sys || '-' || p_nbr || ' : ' || v_txt;
    END ARABIC_MESSAGE;

    PROCEDURE DISPLAY_ARABIC_ERROR (p_sys IN NUMBER, p_nbr IN NUMBER)
    IS
    BEGIN
        FORM_TRIGGER_FAILURE(ARABIC_MESSAGE(p_sys, p_nbr));
    END DISPLAY_ARABIC_ERROR;

    PROCEDURE DISPLAY_ARABIC_INFO (p_sys IN NUMBER, p_nbr IN NUMBER)
    IS
    BEGIN
        message(ARABIC_MESSAGE(p_sys, p_nbr));
    END DISPLAY_ARABIC_INFO;

    FUNCTION CG_MESSAGE (p_default IN VARCHAR2, p1 IN VARCHAR2) RETURN VARCHAR2
    IS
    BEGIN
        RETURN REPLACE(p_default, '<p1>', p1);
    END CG_MESSAGE;


    -- =========================================================================
    -- PACKAGE VERSION   (SELECT FORMS_APX.PKG_VERSION FROM dual;)
    -- =========================================================================
    FUNCTION PKG_VERSION
       RETURN VARCHAR2
    IS
    BEGIN
       RETURN V_INFO;
    END PKG_VERSION;

END FORMS_APX;
/
SHOW ERRORS

-- -----------------------------------------------------------------------------
-- Synonym and grants (run as a user allowed to create public synonyms / grant on LIB_APX_USR).
-- CUSTOMS = parsing schema of the APEX application: APEX needs the direct grant.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PUBLIC SYNONYM FORMS_APX FOR LIB_APX_USR.FORMS_APX;

GRANT EXECUTE ON LIB_APX_USR.FORMS_APX TO LIB_USR;

GRANT EXECUTE ON LIB_APX_USR.FORMS_APX TO SECURITY_DEFAULT;

GRANT EXECUTE ON LIB_APX_USR.FORMS_APX TO SECURITY_PROD;

GRANT EXECUTE ON LIB_APX_USR.FORMS_APX TO CUSTOMS;
