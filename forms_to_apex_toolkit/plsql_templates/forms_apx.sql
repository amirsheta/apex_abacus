-- =============================================================================
-- Owner       : LIB_APX_USR (public synonym FORMS_COMPAT; EXECUTE granted to LIB_USR, SECURITY_DEFAULT, SECURITY_PROD, CUSTOMS)
-- Package     : FORMS_COMPAT
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
-- =============================================================================
SET DEFINE OFF

CREATE OR REPLACE PACKAGE LIB_APX_USR.FORMS_COMPAT AS
   V_PKG_VERSION       VARCHAR2 (100) := 'VERSION NO. IS:' || '002';
   V_PKG_VERSION_QC    VARCHAR2 (100) := 'VERSION NO. IS:' || '001';
   V_PKG_VERSION_DEV   VARCHAR2 (100) := 'VERSION NO. IS:' || '001';
   FUNCTION PKG_VERSION
      RETURN VARCHAR2;
   V_PACKAGE_NAME      VARCHAR2 (50) := 'FORMS_COMPAT';
   V_LAST_MODIFY_DT    VARCHAR2 (10) := '18-11-2026';
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
    -- Error Handling > Error Handling Function = FORMS_COMPAT.apex_error_handler).
    -- Shows business errors (-20000..-20999) without the "ORA-200xx:" prefix and
    -- translates constraint violations via Text Messages named after the constraint.
    FUNCTION apex_error_handler (p_error IN apex_error.t_error)
        RETURN apex_error.t_error_result;

END FORMS_COMPAT;
/
SHOW ERRORS

CREATE OR REPLACE PACKAGE BODY LIB_APX_USR.FORMS_COMPAT
AS
    -- Fallback storage for globals when running outside APEX (unit tests, SQL*Plus)
    TYPE t_globals IS TABLE OF VARCHAR2(4000) INDEX BY VARCHAR2(30);
    g_globals t_globals;

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
    -- PACKAGE VERSION   (SELECT FORMS_COMPAT.PKG_VERSION FROM dual;)
    -- =========================================================================
    FUNCTION PKG_VERSION
       RETURN VARCHAR2
    IS
    BEGIN
       RETURN V_INFO;
    END PKG_VERSION;

END FORMS_COMPAT;
/
SHOW ERRORS

-- -----------------------------------------------------------------------------
-- Synonym and grants (run as a user allowed to create public synonyms / grant on LIB_APX_USR).
-- CUSTOMS = parsing schema of the APEX application: APEX needs the direct grant.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PUBLIC SYNONYM FORMS_COMPAT FOR LIB_APX_USR.FORMS_COMPAT;

GRANT EXECUTE ON LIB_APX_USR.FORMS_COMPAT TO LIB_USR;

GRANT EXECUTE ON LIB_APX_USR.FORMS_COMPAT TO SECURITY_DEFAULT;

GRANT EXECUTE ON LIB_APX_USR.FORMS_COMPAT TO SECURITY_PROD;

GRANT EXECUTE ON LIB_APX_USR.FORMS_COMPAT TO CUSTOMS;
