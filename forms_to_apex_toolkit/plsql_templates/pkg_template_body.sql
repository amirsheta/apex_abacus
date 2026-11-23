-- =============================================================================
-- =============================================================================
-- Package body: <FORM>   (matches pkg_template_spec.sql - f345 standard)
-- Source form : <FORM>.fmb   Target: APEX 21.2 / DB 12.1.0.2   Version: 1.0.0
-- Rules: no Forms built-ins (use FORMS_APX), no COMMIT/ROLLBACK,
--        item values passed as parameters named after their binds (P_<ITEM>, no I_ / IO_ / O_),
--        qualified with the member name inside SQL; identifiers <= 30 bytes.
-- Layout (docs/f345_reference_standard.md §10): VERSION -> f345 HELPERS -> FORM LEVEL -> one section
-- per BLOCK (query, record, items in navigation order, DML, buttons) -> PROGRAM UNITS ->
-- UI LOGIC comments. Private helpers shared by several triggers go first in the body, named by
-- what they do. One Forms trigger = one member, about 80 lines at most.
-- =============================================================================
SET DEFINE OFF

CREATE OR REPLACE PACKAGE BODY LIB_APX_USR.<FORM>
AS

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

    PROCEDURE P0_PAGE_PK_CHECK (P_PAGE_PK IN OUT VARCHAR2)
    IS
        v_cnt PLS_INTEGER;
    BEGIN
        IF P_PAGE_PK IS NULL THEN
            RETURN;
        END IF;
        -- SELECT COUNT(*) INTO v_cnt FROM <base_table> WHERE <pk> = P0_PAGE_PK_CHECK.P_PAGE_PK;
        v_cnt := 1;
        IF v_cnt = 0 THEN
            P_PAGE_PK := NULL;                         -- record deleted / not visible
        END IF;
    END P0_PAGE_PK_CHECK;

    -- =========================================================================
    -- FORM LEVEL
    -- =========================================================================
    -- Source: <FORM>.WHEN-NEW-FORM-INSTANCE
    -- Original Forms code:
    --   :GLOBAL.company_id := 10;
    --   IF :PARAMETER.<param> IS NOT NULL THEN <query that record>; END IF;
    PROCEDURE INIT_FORM (P_<PARAM> IN VARCHAR2,
                         P_PAGE_PK       IN OUT VARCHAR2)
    IS
    BEGIN
        IF FORMS_APX.get_global('COMPANY_ID') IS NULL THEN
            FORMS_APX.set_global('COMPANY_ID', '10');   -- :GLOBAL.company_id := 10; (item G_COMPANY_ID)
        END IF;
        IF P_<PARAM> IS NOT NULL THEN
            P_PAGE_PK := P_<PARAM>;              -- open the record (toolbar shows SAVE / DELETE)
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
    FUNCTION <ITEM>_VALIDATION (P_<ITEM> IN VARCHAR2) RETURN VARCHAR2
    IS
    BEGIN
        IF P_<ITEM> IS NULL THEN
            RETURN 'Value is required';
        END IF;
        RETURN NULL;
    END <ITEM>_VALIDATION;

    -- Source: Make_Field_Entrable('<BLOCK>.<ITEM>', FALSE) when <condition>
    FUNCTION <ITEM>_IS_READ_ONLY (P_<OTHER_ITEM> IN VARCHAR2) RETURN BOOLEAN
    IS
    BEGIN
        RETURN P_<OTHER_ITEM> = '<VALUE>';
    END <ITEM>_IS_READ_ONLY;

    -- Source: SET_ITEM_PROPERTY('<BLOCK>.<ITEM>', REQUIRED, PROPERTY_TRUE) when <condition>
    FUNCTION <ITEM>_IS_REQUIRED (P_<OTHER_ITEM> IN VARCHAR2) RETURN BOOLEAN
    IS
    BEGIN
        RETURN P_<OTHER_ITEM> = '<VALUE>';
    END <ITEM>_IS_REQUIRED;

    -- Source: <BLOCK>.WHEN-VALIDATE-RECORD
    -- Original Forms code:
    --   IF :<BLOCK>.end_date < :<BLOCK>.start_date THEN
    --      SHOW_ALERT('AL_DATES'); RAISE FORM_TRIGGER_FAILURE;
    --   END IF;
    FUNCTION <BLOCK>_WHEN_VALIDATE_RECORD (P_START_DATE IN DATE,
                          P_END_DATE   IN DATE) RETURN VARCHAR2
    IS
    BEGIN
        IF P_END_DATE < P_START_DATE THEN
            RETURN apex_lang.message('AL_DATES');          -- Text Message named after the alert
        END IF;
        RETURN NULL;
    END <BLOCK>_WHEN_VALIDATE_RECORD;

    -- Source: <BLOCK>.PRE-INSERT
    -- Original Forms code:
    --   SELECT <seq>.NEXTVAL INTO :<BLOCK>.id FROM dual;
    --   :<BLOCK>.created_by := USER;
    PROCEDURE PRE_INSERT (P_<PK>  IN OUT VARCHAR2,
                          SSO_APP_USER   IN VARCHAR2)
    IS
    BEGIN
        -- P_<PK> := <seq>.NEXTVAL;              -- direct assignment is valid on 12.1
        -- the audit column uses SSO_APP_USER (USER -> f345 item SSO_APP_USER)
        NULL;
    END PRE_INSERT;

    -- Source: <BLOCK>.PRE-UPDATE
    PROCEDURE PRE_UPDATE (P_<PK>   IN VARCHAR2,
                          SSO_APP_USER   IN VARCHAR2)
    IS
    BEGIN
        NULL;
    END PRE_UPDATE;

    -- Source: <BLOCK>.PRE-DELETE
    -- Original Forms code:
    --   SELECT COUNT(*) INTO v_cnt FROM <child> WHERE fk = :<BLOCK>.id;
    --   IF v_cnt > 0 THEN MESSAGE('Child records exist'); RAISE FORM_TRIGGER_FAILURE; END IF;
    PROCEDURE PRE_DELETE (P_<PK> IN VARCHAR2)
    IS
        v_cnt PLS_INTEGER := 0;
    BEGIN
        -- SELECT COUNT(*) INTO v_cnt FROM <child_table> WHERE <fk> = PRE_DELETE.P_<PK>;
        IF v_cnt > 0 THEN
            FORMS_APX.FORM_TRIGGER_FAILURE('Child records exist');      -- MESSAGE + FORM_TRIGGER_FAILURE
        END IF;
    END PRE_DELETE;

    -- Source: <BLOCK>.POST-QUERY
    -- APEX  : SELECT t.*, <FORM>.POST_QUERY(t.lookup_id) AS lookup_desc FROM ...
    --         (for big reports prefer a JOIN / view)
    FUNCTION POST_QUERY (LOOKUP_ID IN NUMBER) RETURN VARCHAR2
    IS
        v_desc VARCHAR2(4000);
    BEGIN
        -- SELECT description INTO v_desc FROM <lookup_table> WHERE id = POST_QUERY.LOOKUP_ID;
        RETURN v_desc;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END POST_QUERY;

    -- =========================================================================
    -- BLOCK <DETAIL_BLOCK>  (detail)
    -- =========================================================================
    -- Source: <DETAIL_BLOCK>.<COLUMN>.WHEN-VALIDATE-ITEM
    FUNCTION <DETAIL_BLOCK>_<COLUMN>_VALIDATION (<COLUMN> IN VARCHAR2) RETURN VARCHAR2
    IS
    BEGIN
        RETURN NULL;
    END <DETAIL_BLOCK>_<COLUMN>_VALIDATION;

    -- Source: <DETAIL_BLOCK>.PRE-INSERT (master key copied to the new row, own key from a sequence)
    PROCEDURE <DETAIL_BLOCK>_PRE_INSERT (P_<PK> IN VARCHAR2,
                                       <FK>        IN OUT VARCHAR2,
                                       <DETAIL_PK> IN OUT VARCHAR2)
    IS
    BEGIN
        <FK> := P_<PK>;
        -- <DETAIL_PK> := <detail_seq>.NEXTVAL;
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
