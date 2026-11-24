-- =============================================================================
-- Package body: IMPR1116   (matches impr1116_spec.sql - f345 standard)
-- Source form : IMPR1116.fmb   Target: APEX 21.2 / DB 12.1.0.2   Version: 001
-- Author      : Claude Code     Created: 2026-11-24   (see the spec history)
-- Rules: no Forms built-ins (FORMS_APX instead), no COMMIT / ROLLBACK,
--        parameters named after their binds without I_ / IO_ / O_; page items P<page>_X -> P_X;
--        inside SQL every parameter is qualified with its member name; identifiers <= 30 bytes.
-- Common helpers: FORMS_APX (version 004), called as FORMS_APX.<NAME>.
-- Layout (docs/f345_reference_standard.md §10): PRIVATE HELPERS (top, used by the members below)
-- -> VERSION -> f345 HELPERS -> FORM LEVEL -> BLOCK IMPR_PRTL_NAT -> BLOCK IMPORTERS -> PROGRAM UNITS
-- -> UI LOGIC FOR APEX DYNAMIC ACTIONS (comments only).
-- Status: NOT COMPILED.
-- =============================================================================
SET DEFINE OFF

CREATE OR REPLACE PACKAGE BODY LIB_APX_USR.IMPR1116
AS
    c_sysobj_importers CONSTANT NUMBER := 9;      -- ACTIVITY.ADD_ACTIVITY(9, ...)
    c_subject_prtl_nat CONSTANT NUMBER := 8;      -- ACTIVITY.ADD_ACTIVITY(9, 8, ...)
    c_activity_update  CONSTANT NUMBER := 2;      -- PRE-UPDATE (PRE-INSERT 1 / PRE-DELETE 3 cannot fire)
    c_review_initial   CONSTANT NUMBER := 0;      -- REVIEW_FLAG 0 = قيمة ابتدائية (block WHERE)

    -- Texts the Forms code did not have: Forms refuses the action itself because the block has
    -- Insert Allowed / Delete Allowed = false. TODO: agree the texts (logic extraction §7).
    c_msg_insert_not_allowed CONSTANT VARCHAR2(200) := 'لا يمكن إضافة بيانات من هذه الشاشة';
    c_msg_delete_not_allowed CONSTANT VARCHAR2(200) := 'لا يمكن حذف بيانات من هذه الشاشة';

    -- =========================================================================
    -- PRIVATE HELPERS
    -- =========================================================================

    -- Forms: actv_ret := activity.add_activity(9, 8, <type>, :impr_prtl_nat.prtl_nat_isn);
    --        IF actv_ret = FALSE THEN RAISE form_trigger_failure; END IF;
    -- ACTIVITY.ADD_ACTIVITY (CIC_LIB.pld) passes :PARAMETER.P_Curr_Port_Cd, P_USER_ID, P_WS_ID to
    -- ACTIVITY_DB.ADD_ACTIVITY and on 0 shows V_MSG_TXT (CFG_SYSTEM_ERROR) and returns FALSE.
    PROCEDURE add_activity (p_activity_type IN NUMBER,
                            p_prtl_nat_isn  IN NUMBER,
                            p_curr_port_cd  IN NUMBER,
                            p_user_id       IN VARCHAR2,
                            p_ws_id         IN VARCHAR2)
    IS
        v_msg  VARCHAR2(2000);
        v_pkey VARCHAR2(50) := p_prtl_nat_isn;        -- Forms: pkey VARCHAR2 (50)
    BEGIN
        IF activity_db.add_activity(c_sysobj_importers, c_subject_prtl_nat, p_activity_type, v_pkey,
                                    p_curr_port_cd, p_user_id, p_ws_id, v_msg) = 0 THEN
            FORMS_APX.FORM_TRIGGER_FAILURE(v_msg);
        END IF;
    END add_activity;

    -- =========================================================================
    -- VERSION
    -- =========================================================================
    FUNCTION PKG_VERSION
       RETURN VARCHAR2
    IS
    BEGIN
       RETURN V_INFO;
    END PKG_VERSION;

    -- =========================================================================
    -- f345 HELPERS
    -- =========================================================================
    -- Source: f345 standard (P0_PAGE_PK = record key of the master block; no Forms trigger)
    PROCEDURE P0_PAGE_PK_CHECK (P_PAGE_PK IN OUT VARCHAR2)
    IS
        v_cnt NUMBER;
    BEGIN
        IF P_PAGE_PK IS NULL THEN
            RETURN;
        END IF;
        P_PAGE_PK := FORMS_APX.ROWID_FROM_URL(P_PAGE_PK);   -- URL-safe ROWID of page 111601 -> ROWID
        SELECT COUNT(*)
          INTO v_cnt
          FROM impr_prtl_nat n
         WHERE n.ROWID = CHARTOROWID(P0_PAGE_PK_CHECK.P_PAGE_PK);
        IF v_cnt = 0 THEN
            P_PAGE_PK := NULL;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN               -- ORA-01410 invalid ROWID ...: not a key of this page
            P_PAGE_PK := NULL;
    END P0_PAGE_PK_CHECK;

    -- =========================================================================
    -- FORM LEVEL
    -- =========================================================================
    -- No member (see the spec and the UI LOGIC section).

    -- =========================================================================
    -- BLOCK IMPR_PRTL_NAT  (master)
    -- =========================================================================
    -- Source: block IMPR_PRTL_NAT property WHERE clause
    -- Original Forms code:
    --   WHERE   ( IMPR_PRTL_NAT.REVIEW_FLAG = 0 AND IMPR_PRTL_NAT.GAZT_NAME IS NOT NULL )
    -- Returns 'Y' for a row still waiting for review (a SQL-usable function: BOOLEAN is not allowed in SQL).
    FUNCTION IMPR_PRTL_NAT_IS_PENDING (REVIEW_FLAG IN NUMBER,
                                       GAZT_NAME   IN VARCHAR2) RETURN VARCHAR2
    IS
    BEGIN
        IF REVIEW_FLAG = c_review_initial AND GAZT_NAME IS NOT NULL THEN
            RETURN 'Y';
        END IF;
        RETURN 'N';
    END IMPR_PRTL_NAT_IS_PENDING;

    -- Source: IMPR_PRTL_NAT.PRE-INSERT + block property Insert Allowed = false
    -- Original Forms code:
    --   DECLARE
    --      actv_ret   BOOLEAN;
    --      pkey       VARCHAR2 (50);
    --   BEGIN
    --      pkey := :impr_prtl_nat.prtl_nat_isn;
    --      actv_ret := activity.add_activity (9, 8, 1, pkey);
    --      IF actv_ret = FALSE THEN RAISE form_trigger_failure; END IF;
    --   END;
    -- The trigger can never fire: the block does not allow inserts (table usage IMPR_PRTL_NAT SEL UPD).
    -- The page 0 CREATE request is refused here instead; the log call is kept in add_activity for the
    -- day the business allows inserts (activity type 1).
    PROCEDURE PRE_INSERT
    IS
    BEGIN
        FORMS_APX.FORM_TRIGGER_FAILURE(c_msg_insert_not_allowed);
    END PRE_INSERT;

    -- Source: IMPR_PRTL_NAT.PRE-UPDATE
    -- Original Forms code:
    --   DECLARE
    --      actv_ret   BOOLEAN;
    --      pkey       VARCHAR2 (50);
    --   BEGIN
    --      pkey := :impr_prtl_nat.prtl_nat_isn;
    --      actv_ret := activity.add_activity (9, 8, 2, pkey);
    --      IF actv_ret = FALSE THEN RAISE form_trigger_failure; END IF;
    --   END;
    -- SUGGESTION: USER_ID / LST_TRAN_DT / UPDATE_DT are not set by the form (inventory §15 #2); set them
    --             here once it is known that no DB trigger does it.
    PROCEDURE PRE_UPDATE (P_PRTL_NAT_ISN   IN NUMBER,
                          P_CURR_PORT_CD   IN NUMBER,
                          SSO_APP_USER     IN VARCHAR2,
                          P_GLOBAL_V_WS_ID IN VARCHAR2)
    IS
    BEGIN
        add_activity(c_activity_update, P_PRTL_NAT_ISN, P_CURR_PORT_CD, SSO_APP_USER, P_GLOBAL_V_WS_ID);
    END PRE_UPDATE;

    -- Source: IMPR_PRTL_NAT.PRE-DELETE + block property Delete Allowed = false
    -- Original Forms code:
    --   DECLARE
    --      actv_ret   BOOLEAN;
    --      pkey       VARCHAR2 (50);
    --   BEGIN
    --      pkey := :impr_prtl_nat.prtl_nat_isn;
    --      actv_ret := activity.add_activity (9, 8, 3, pkey);
    --      IF actv_ret = FALSE THEN RAISE form_trigger_failure; END IF;
    --   END;
    -- The trigger can never fire: the block does not allow deletes. The page 0 DELETE request is refused.
    PROCEDURE PRE_DELETE
    IS
    BEGIN
        FORMS_APX.FORM_TRIGGER_FAILURE(c_msg_delete_not_allowed);
    END PRE_DELETE;

    -- =========================================================================
    -- BLOCK IMPORTERS  (detail, query only)
    -- =========================================================================
    -- No member. Region SQL of IG IMPORTERS on page 1116 (analysis/IMPR1116/IMPR1116_apex_page_spec.md):
    --   Forms WHERE  : IMPORTERS.IMPR_TYPE_CD = :impr_prtl_nat.impr_type_cd AND IMPORTERS.CTRY_CD = :impr_prtl_nat.ctry_cd
    --                  AND IMPORTERS.BUS_ID_TYPE_CD = :impr_prtl_nat.bus_id_type_cd AND IMPORTERS.BUS_ID = :impr_prtl_nat.bus_id
    --                  AND NVL (IMPORTERS.BUS_ID_BRNCH, 0) = NVL (:impr_prtl_nat.bus_id_brnch, 0)
    --   POST-QUERY   : CGFK$QRY_IMPORTERS_IMP_ITIDT_F (L_IT1_IMPR_TYPE_NAME, L_BIT_BUS_ID_TYPE_NAME) -> outer joins
    --                  IMPR_TYPE_ID_TYPES / IMPR_TYPES / BUS_ID_TYPES. The Forms message on a missing type
    --                  ('رمز النشاط التجاري غير صحيح - أعد إدخال البيانات') is dropped: the names stay empty.

    -- =========================================================================
    -- PROGRAM UNITS
    -- =========================================================================
    -- None kept (see the spec).

    -- =========================================================================
    -- UI LOGIC FOR APEX DYNAMIC ACTIONS  (comments only - no executable code)
    -- =========================================================================
    -- APEX-DA: [Source: IMPR_PRTL_NAT.WHEN-NEW-RECORD-INSTANCE] -> no DA
    -- Original : GO_BLOCK ('IMPORTERS'); CLEAR_BLOCK (no_validate); EXECUTE_QUERY (no_validate);
    --            GO_BLOCK ('IMPR_PRTL_NAT');  (:SYSTEM.message_level := 25, WHEN OTHERS THEN NULL)
    -- Implement: IG IMPORTERS region SQL binds the master page items P1116_IMPR_TYPE_CD, P1116_CTRY_CD,
    --            P1116_BUS_ID_TYPE_CD, P1116_BUS_ID, P1116_BUS_ID_BRNCH (Page Items to Submit); the page shows
    --            one IMPR_PRTL_NAT record (P0_PAGE_PK), so the grid is queried at page render.
    --
    -- APEX-DA: [Source: IMPR1116.WHEN-NEW-FORM-INSTANCE (form-specific part)] -> no DA
    -- Original : SET_ITEM_PROPERTY ('IMPORTERS.PORT_CD2', visible, property_false);
    --            SET_ITEM_PROPERTY ('IMPORTERS.L_BIT_BUS_ID_TYPE_NAME2', visible, property_false);
    --            SET_ITEM_PROPERTY ('IMPORTERS.PORT_CD', WIDTH, 0.5);
    --            SET_ITEM_PROPERTY ('IMPORTERS.L_BIT_BUS_ID_TYPE_NAME', WIDTH, 1.2);
    -- Implement: the two LOV buttons are not created; column widths set in the IG.
    --
    -- APEX-DA: [Source: IMPR_PRTL_NAT items Update Allowed = false, 17 Designer KEY-LISTVAL checks]
    -- Implement: every P1116 item is Read Only (Always) except P1116_REVIEW_FLAG (Select List,
    --            LOV_APX.REFERENCE_CODES('PRTL_NAT_FLAG')); IG IMPORTERS not editable.
    --
    -- APEX-DA: [Source: PU CGDV$POPULATE_DYNAMIC_LISTS] -> shared LOVs
    -- Implement: LOV_ID_TYPE_GZT = LOV_APX.REFERENCE_CODES(P_DOMAIN => 'ID_TYPE_GZT'),
    --            LOV_PRTL_NAT_FLAG = LOV_APX.REFERENCE_CODES(P_DOMAIN => 'PRTL_NAT_FLAG').

END IMPR1116;
/
SHOW ERRORS
