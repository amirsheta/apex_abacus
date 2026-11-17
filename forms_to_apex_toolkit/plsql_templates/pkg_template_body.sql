-- =============================================================================
-- Package body: pkg_<form>   (matches pkg_template_spec.sql)
-- Source form : <FORM>.fmb   Target: APEX 21.2 / DB 12.1.0.2   Version: 1.0.0
-- Rules: no Forms built-ins (use pkg_forms_compat), no COMMIT/ROLLBACK,
--        item values passed as parameters, identifiers <= 30 bytes.
-- Layout mirrors the form: FORM LEVEL -> one section per BLOCK -> PROGRAM UNITS.
-- =============================================================================
SET DEFINE OFF

CREATE OR REPLACE PACKAGE BODY pkg_<form>
AS
    -- =========================================================================
    -- FORM LEVEL
    -- =========================================================================
    -- Source: <FORM>.WHEN-NEW-FORM-INSTANCE
    -- Original Forms code:
    --   :GLOBAL.company_id := 10;
    --   :CONTROL.today := SYSDATE;
    PROCEDURE wnfi
    IS
    BEGIN
        IF pkg_forms_compat.get_global('COMPANY_ID') IS NULL THEN
            pkg_forms_compat.set_global('COMPANY_ID', '10');   -- :GLOBAL.company_id := 10;
        END IF;
        -- :CONTROL.today := SYSDATE  -> item default of P<page>_TODAY (no code needed)
    END wnfi;

    -- =========================================================================
    -- BLOCK <BLOCK>
    -- =========================================================================
    -- Source: <BLOCK>.<ITEM>.WHEN-VALIDATE-ITEM
    -- Original Forms code:
    --   IF :<BLOCK>.<ITEM> IS NULL THEN
    --      MESSAGE('Value is required'); RAISE FORM_TRIGGER_FAILURE;
    --   END IF;
    -- Returns NULL when valid, otherwise the error text (APEX shows it next to the item).
    FUNCTION <item>_wvi (p_value IN VARCHAR2) RETURN VARCHAR2
    IS
    BEGIN
        IF p_value IS NULL THEN
            RETURN 'Value is required';
        END IF;
        RETURN NULL;
    END <item>_wvi;

    -- Source: <BLOCK>.WHEN-VALIDATE-RECORD
    -- Original Forms code:
    --   IF :<BLOCK>.end_date < :<BLOCK>.start_date THEN
    --      SHOW_ALERT('AL_DATES'); RAISE FORM_TRIGGER_FAILURE;
    --   END IF;
    PROCEDURE <block>_wvr (p_rec IN t_<block>_rec)
    IS
    BEGIN
        -- IF p_rec.end_date < p_rec.start_date THEN
        --     pkg_forms_compat.alert('AL_DATES');      -- SHOW_ALERT + FORM_TRIGGER_FAILURE
        -- END IF;
        NULL;
    END <block>_wvr;

    -- Source: <BLOCK>.WHEN-CREATE-RECORD
    PROCEDURE <block>_wcr (p_rec IN OUT NOCOPY t_<block>_rec)
    IS
    BEGIN
        -- p_rec.status := 'NEW';
        NULL;
    END <block>_wcr;

    -- Source: <BLOCK>.PRE-INSERT
    -- Original Forms code:
    --   SELECT <seq>.NEXTVAL INTO :<BLOCK>.id FROM dual;
    --   :<BLOCK>.created_by := USER;
    PROCEDURE <block>_pre_ins (p_rec IN OUT NOCOPY t_<block>_rec)
    IS
    BEGIN
        -- p_rec.id         := <seq>.NEXTVAL;                 -- direct assignment is valid on 12.1
        -- p_rec.created_by := pkg_forms_compat.app_user;     -- USER -> APP_USER
        -- p_rec.created_on := SYSDATE;
        <block>_wvr(p_rec);
    END <block>_pre_ins;

    -- Source: <BLOCK>.PRE-UPDATE
    PROCEDURE <block>_pre_upd (p_rec IN OUT NOCOPY t_<block>_rec)
    IS
    BEGIN
        -- p_rec.updated_by := pkg_forms_compat.app_user;
        -- p_rec.updated_on := SYSDATE;
        <block>_wvr(p_rec);
    END <block>_pre_upd;

    -- Source: <BLOCK>.PRE-DELETE
    -- Original Forms code:
    --   SELECT COUNT(*) INTO v_cnt FROM <child> WHERE fk = :<BLOCK>.id;
    --   IF v_cnt > 0 THEN MESSAGE('Child records exist'); RAISE FORM_TRIGGER_FAILURE; END IF;
    PROCEDURE <block>_pre_del (p_rec IN t_<block>_rec)
    IS
        v_cnt PLS_INTEGER := 0;
    BEGIN
        -- SELECT COUNT(*) INTO v_cnt FROM <child_table> WHERE <fk> = p_rec.<pk>;
        IF v_cnt > 0 THEN
            pkg_forms_compat.ftf('Child records exist');      -- MESSAGE + FORM_TRIGGER_FAILURE
        END IF;
    END <block>_pre_del;

    -- Source: <BLOCK>.POST-QUERY
    -- APEX  : SELECT t.*, pkg_<form>.<block>_post_qry(t.lookup_id) AS lookup_desc FROM ...
    --         (for big reports prefer a JOIN / view)
    FUNCTION <block>_post_qry (p_lookup_id IN NUMBER) RETURN VARCHAR2
    IS
        v_desc VARCHAR2(4000);
    BEGIN
        -- SELECT description INTO v_desc FROM <lookup_table> WHERE id = p_lookup_id;
        RETURN v_desc;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END <block>_post_qry;

    -- =========================================================================
    -- PROGRAM UNITS   (same names as in the Forms Program Units node)
    -- =========================================================================

    -- =========================================================================
    -- UI LOGIC FOR APEX DYNAMIC ACTIONS  (comments only - no executable code)
    -- =========================================================================
    -- APEX-DA: "<BLOCK>.<ITEM>.WHEN-LIST-CHANGED"
    -- Original : SET_ITEM_PROPERTY('<BLOCK>.<ITEM2>', ENABLED, PROPERTY_FALSE);
    -- Implement: DA on change of P<page>_<ITEM> -> Disable P<page>_<ITEM2>

END pkg_<form>;
/
SHOW ERRORS
