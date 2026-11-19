-- =============================================================================
-- =============================================================================
-- Package body: <FORM>   (matches pkg_template_spec.sql - f345 standard)
-- Source form : <FORM>.fmb   Target: APEX 21.2 / DB 12.1.0.2   Version: 1.0.0
-- Rules: no Forms built-ins (use FORMS_COMPAT), no COMMIT/ROLLBACK,
--        item values passed as I_/IO_ parameters, identifiers <= 30 bytes.
-- Layout (docs/f345_reference_standard.md §10): VERSION -> f345 HELPERS -> FORM LEVEL -> one section
-- per BLOCK (query, record, items in navigation order, DML, buttons) -> PROGRAM UNITS ->
-- UI LOGIC comments. Private helpers shared by several triggers go first in the body, named by
-- what they do. One Forms trigger = one member, about 80 lines at most.
-- =============================================================================
SET DEFINE OFF

CREATE OR REPLACE PACKAGE BODY LIB_APX_USR.<FORM>
AS
    c_err CONSTANT PLS_INTEGER := -20001;

    -- =========================================================================
    -- PACKAGE VERSION
    -- =========================================================================
    -- SELECT <FORM>.PKG_VERSION FROM dual;  -> package name, version, modified date / by
    FUNCTION PKG_VERSION
       RETURN VARCHAR2
    IS
    BEGIN
       RETURN V_INFO;
    END PKG_VERSION;

    -- =========================================================================
    -- f345 HELPERS
    -- =========================================================================
    PROCEDURE CHECK_ERROR (I_ERR IN VARCHAR2)
    IS
    BEGIN
        IF I_ERR IS NOT NULL THEN
            raise_application_error(c_err, I_ERR);
        END IF;
    END CHECK_ERROR;

    FUNCTION REQUIRED_VALIDATION (I_VALUE IN VARCHAR2, I_LABEL IN VARCHAR2) RETURN VARCHAR2
    IS
    BEGIN
        -- Source: FRM-40202 "Field must be entered"
        RETURN CASE WHEN TRIM(I_VALUE) IS NULL THEN 'يجب إدخال ' || I_LABEL END;
    END REQUIRED_VALIDATION;

    PROCEDURE P0_PAGE_PK_CHECK (IO_P0_PAGE_PK IN OUT VARCHAR2)
    IS
        v_cnt PLS_INTEGER;
    BEGIN
        IF IO_P0_PAGE_PK IS NULL THEN
            RETURN;
        END IF;
        -- SELECT COUNT(*) INTO v_cnt FROM <base_table> WHERE <pk> = IO_P0_PAGE_PK;
        v_cnt := 1;
        IF v_cnt = 0 THEN
            IO_P0_PAGE_PK := NULL;                         -- record deleted / not visible
        END IF;
    END P0_PAGE_PK_CHECK;

    FUNCTION GET_MODULE_ID (I_P<page>_MODULE_ID IN VARCHAR2) RETURN VARCHAR2
    IS
        v_id VARCHAR2(40);
    BEGIN
        IF I_P<page>_MODULE_ID IS NOT NULL THEN
            RETURN I_P<page>_MODULE_ID;
        END IF;
        SELECT TO_CHAR(MIN(o.sysobj_id))
          INTO v_id
          FROM sc_system_objects o
         WHERE UPPER(REGEXP_REPLACE(o.sys_os_file_name, '\..*$', '')) = '<FORM>';
        RETURN v_id;
    END GET_MODULE_ID;

    PROCEDURE HEADER_TITLE (I_P0_PAGE_PK         IN VARCHAR2,
                            IO_P<page>_HERO_TITLE IN OUT VARCHAR2)
    IS
    BEGIN
        IO_P<page>_HERO_TITLE := CASE WHEN I_P0_PAGE_PK IS NULL THEN '<screen title>'
                                      ELSE '<screen title> - ' || I_P0_PAGE_PK END;
    END HEADER_TITLE;

    -- =========================================================================
    -- FORM LEVEL
    -- =========================================================================
    -- Source: <FORM>.WHEN-NEW-FORM-INSTANCE
    -- Original Forms code:
    --   :GLOBAL.company_id := 10;
    --   IF :PARAMETER.<param> IS NOT NULL THEN <query that record>; END IF;
    PROCEDURE INIT_FORM (I_P<page>_P_<PARAM> IN VARCHAR2,
                         IO_P0_PAGE_PK       IN OUT VARCHAR2)
    IS
    BEGIN
        IF FORMS_COMPAT.get_global('COMPANY_ID') IS NULL THEN
            FORMS_COMPAT.set_global('COMPANY_ID', '10');   -- :GLOBAL.company_id := 10; (item G_COMPANY_ID)
        END IF;
        IF I_P<page>_P_<PARAM> IS NOT NULL THEN
            IO_P0_PAGE_PK := I_P<page>_P_<PARAM>;              -- open the record (toolbar shows SAVE / DELETE)
        END IF;
    END INIT_FORM;

    -- =========================================================================
    -- BLOCK <BLOCK>  (master)
    -- =========================================================================
    -- Source: <BLOCK>.<ITEM>.WHEN-VALIDATE-ITEM
    -- Original Forms code:
    --   IF :<BLOCK>.<ITEM> IS NULL THEN
    --      MESSAGE('Value is required'); RAISE FORM_TRIGGER_FAILURE;
    --   END IF;
    -- Returns NULL when valid, otherwise the error text (APEX shows it next to the item).
    FUNCTION <ITEM>_VALIDATION (I_P<page>_<ITEM> IN VARCHAR2) RETURN VARCHAR2
    IS
    BEGIN
        IF I_P<page>_<ITEM> IS NULL THEN
            RETURN 'Value is required';
        END IF;
        RETURN NULL;
    END <ITEM>_VALIDATION;

    -- Source: Make_Field_Entrable('<BLOCK>.<ITEM>', FALSE) when <condition>
    FUNCTION <ITEM>_IS_READ_ONLY (I_P<page>_<OTHER_ITEM> IN VARCHAR2) RETURN BOOLEAN
    IS
    BEGIN
        RETURN I_P<page>_<OTHER_ITEM> = '<VALUE>';
    END <ITEM>_IS_READ_ONLY;

    -- Source: SET_ITEM_PROPERTY('<BLOCK>.<ITEM>', REQUIRED, PROPERTY_TRUE) when <condition>
    FUNCTION <ITEM>_IS_REQUIRED (I_P<page>_<OTHER_ITEM> IN VARCHAR2) RETURN BOOLEAN
    IS
    BEGIN
        RETURN I_P<page>_<OTHER_ITEM> = '<VALUE>';
    END <ITEM>_IS_REQUIRED;

    -- Source: <BLOCK>.WHEN-VALIDATE-RECORD
    -- Original Forms code:
    --   IF :<BLOCK>.end_date < :<BLOCK>.start_date THEN
    --      SHOW_ALERT('AL_DATES'); RAISE FORM_TRIGGER_FAILURE;
    --   END IF;
    FUNCTION <BLOCK>_WHEN_VALIDATE_RECORD (I_P<page>_START_DATE IN DATE,
                          I_P<page>_END_DATE   IN DATE) RETURN VARCHAR2
    IS
    BEGIN
        IF I_P<page>_END_DATE < I_P<page>_START_DATE THEN
            RETURN apex_lang.message('AL_DATES');          -- Text Message named after the alert
        END IF;
        RETURN NULL;
    END <BLOCK>_WHEN_VALIDATE_RECORD;

    -- Source: <BLOCK>.PRE-INSERT
    -- Original Forms code:
    --   SELECT <seq>.NEXTVAL INTO :<BLOCK>.id FROM dual;
    --   :<BLOCK>.created_by := USER;
    PROCEDURE PRE_INSERT (IO_P<page>_<PK>  IN OUT VARCHAR2,
                          I_SSO_APP_USER   IN VARCHAR2)
    IS
    BEGIN
        -- IO_P<page>_<PK> := <seq>.NEXTVAL;              -- direct assignment is valid on 12.1
        -- the audit column uses I_SSO_APP_USER (USER -> f345 item SSO_APP_USER)
        NULL;
    END PRE_INSERT;

    -- Source: <BLOCK>.PRE-UPDATE
    PROCEDURE PRE_UPDATE (I_P<page>_<PK>   IN VARCHAR2,
                          I_SSO_APP_USER   IN VARCHAR2)
    IS
    BEGIN
        NULL;
    END PRE_UPDATE;

    -- Source: <BLOCK>.PRE-DELETE
    -- Original Forms code:
    --   SELECT COUNT(*) INTO v_cnt FROM <child> WHERE fk = :<BLOCK>.id;
    --   IF v_cnt > 0 THEN MESSAGE('Child records exist'); RAISE FORM_TRIGGER_FAILURE; END IF;
    PROCEDURE PRE_DELETE (I_P<page>_<PK> IN VARCHAR2)
    IS
        v_cnt PLS_INTEGER := 0;
    BEGIN
        -- SELECT COUNT(*) INTO v_cnt FROM <child_table> WHERE <fk> = I_P<page>_<PK>;
        IF v_cnt > 0 THEN
            FORMS_COMPAT.FORM_TRIGGER_FAILURE('Child records exist');      -- MESSAGE + FORM_TRIGGER_FAILURE
        END IF;
    END PRE_DELETE;

    -- Source: <BLOCK>.POST-QUERY
    -- APEX  : SELECT t.*, <FORM>.POST_QUERY(t.lookup_id) AS lookup_desc FROM ...
    --         (for big reports prefer a JOIN / view)
    FUNCTION POST_QUERY (I_LOOKUP_ID IN NUMBER) RETURN VARCHAR2
    IS
        v_desc VARCHAR2(4000);
    BEGIN
        -- SELECT description INTO v_desc FROM <lookup_table> WHERE id = I_LOOKUP_ID;
        RETURN v_desc;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END POST_QUERY;

    -- =========================================================================
    -- BLOCK <DETAIL_BLOCK>  (detail)
    -- =========================================================================
    -- Source: <DETAIL_BLOCK>.<COLUMN>.WHEN-VALIDATE-ITEM
    FUNCTION <DETAIL_BLOCK>_<COLUMN>_VALIDATION (I_<COLUMN> IN VARCHAR2) RETURN VARCHAR2
    IS
    BEGIN
        RETURN NULL;
    END <DETAIL_BLOCK>_<COLUMN>_VALIDATION;

    -- Source: <DETAIL_BLOCK>.PRE-INSERT (master key copied to the new row, own key from a sequence)
    PROCEDURE <DETAIL_BLOCK>_PRE_INSERT (I_P<page>_<PK> IN VARCHAR2,
                                       IO_<FK>        IN OUT VARCHAR2,
                                       IO_<DETAIL_PK> IN OUT VARCHAR2)
    IS
    BEGIN
        IO_<FK> := I_P<page>_<PK>;
        -- IO_<DETAIL_PK> := <detail_seq>.NEXTVAL;
    END <DETAIL_BLOCK>_PRE_INSERT;

    -- =========================================================================
    -- PROGRAM UNITS   (same names as in the Forms Program Units node)
    -- =========================================================================

    -- =========================================================================
    -- UI LOGIC FOR APEX DYNAMIC ACTIONS  (comments only - no executable code)
    -- =========================================================================
    -- APEX-DA: "<ITEM> WHEN-LIST-CHANGED"
    -- Original : SET_ITEM_PROPERTY('<BLOCK>.<ITEM2>', ENABLED, PROPERTY_FALSE);
    -- Implement: DA on change of P<page>_<ITEM> -> Disable P<page>_<ITEM2>

END <FORM>;
/
SHOW ERRORS
