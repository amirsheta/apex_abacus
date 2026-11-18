-- =============================================================================
-- Package body : IMPR1110_APX  (APEX glue for IMPR1110, page 1110)
-- Author       : Claude Code
-- Created      : 2026-11-18
-- Version      : 1.2.0  (2026-11-18: menu parameters read from f345 application items, see APPLICATION_ITEM();
-- Owner       : LIB_APX_USR (public synonym IMPR1110_APX; EXECUTE granted to LIB_USR, SECURITY_DEFAULT, SECURITY_PROD, CUSTOMS)
--                        previous version rollback/IMPR1110/pkg_impr1110_apx_body_v1_1_0.sql)
-- Status       : NOT COMPILED.
-- Called by    : package IMPR1110 (APEX entry point, f345 standard). Pages never call this package directly.
-- Order rules  : item validation = POST-CHANGE then WHEN-VALIDATE-ITEM (Forms order);
--                save = item validations (changed items only) -> required items ->
--                PRE-INSERT -> INSERT -> POST-INSERT  /  PRE-UPDATE -> UPDATE -> POST-UPDATE;
--                no COMMIT here - APEX commits after the page processes.
-- =============================================================================
SET DEFINE OFF

CREATE OR REPLACE PACKAGE BODY LIB_APX_USR.IMPR1110_APX
AS
    c_mask CONSTANT VARCHAR2(10) := 'MI-MM-YYYY';   -- Hijri date mask of the form (as in Forms)

    -- Items with a POST-CHANGE / WHEN-VALIDATE-ITEM trigger, in Forms item order (XML order)
    TYPE t_names IS TABLE OF VARCHAR2(30);
    c_val_items CONSTANT t_names := t_names(
        'PORT_CD', 'HQ_IMPR_NBR', 'IMPR_NBR', 'IMPR_TYPE_CD', 'BUS_ID_EXPRD_DT', 'BUS_ID_TYPE_CD',
        'CITY_CODE_OF_ID', 'BUS_ID', 'BRNH_CITY_CD', 'BUS_ID_BRNCH', 'CTRY_CD', 'IMPR_EXPR_TYPE',
        'ARBC_IMPR_NAME', 'ENG_IMPR_NAME', 'BUS_ID_ISSUE_DT', 'IMPR_NBR_PARENT', 'ADD_CTRY_CD',
        'CITY_CODE', 'IMPR_TEL_NBR', 'B_EMAIL', 'EMAIL', 'B_MOBILE_NO', 'BANK_IBAN', 'B_ID_NBR',
        'CTRY_CD_OF_ID');
    -- Items with Required = true in the form (static); dynamic changes come from the UI state
    c_req_items CONSTANT t_names := t_names(
        'PORT_CD', 'IMPR_TYPE_CD', 'BUS_ID_TYPE_CD', 'BUS_ID', 'CTRY_CD', 'IMPR_EXPR_TYPE',
        'ARBC_IMPR_NAME', 'ADD_CTRY_CD');
    -- Items whose REQUIRED property the form changes at runtime
    c_dyn_req_items CONSTANT t_names := t_names(
        'COMM_RGSTRTN_TYPE', 'CITY_CODE_OF_ID', 'BRNH_CITY_CD', 'BUS_ID_BRNCH');

    -- ----------------------------------------------------------------- session state helpers
    FUNCTION ITEM_VALUE (p_item IN VARCHAR2) RETURN VARCHAR2
    IS
    BEGIN
        RETURN FORMS_COMPAT.name_in('P1110_' || p_item);
    END ITEM_VALUE;

    FUNCTION NUMBER_ITEM (p_item IN VARCHAR2) RETURN NUMBER
    IS
    BEGIN
        RETURN TO_NUMBER(ITEM_VALUE(p_item));
    END NUMBER_ITEM;

    FUNCTION DATE_ITEM (p_item IN VARCHAR2) RETURN DATE
    IS
    BEGIN
        RETURN TO_DATE(ITEM_VALUE(p_item), c_mask);
    END DATE_ITEM;

    PROCEDURE SET_ITEM (p_item IN VARCHAR2, p_val IN VARCHAR2)
    IS
    BEGIN
        FORMS_COMPAT.copy(p_val, 'P1110_' || p_item);
    END SET_ITEM;

    -- Menu parameters (:PARAMETER.P_*) -> application items of the f345 reference application.
    -- 1.2.0: names follow f345 (CLAUDE.md §4b) instead of AI_P_*. Items f345 already fills
    -- (app process "After Auth") are reused; the others are new f345-style P_* items.
    FUNCTION APPLICATION_ITEM (p_name IN VARCHAR2) RETURN VARCHAR2
    IS
    BEGIN
        RETURN FORMS_COMPAT.name_in(
                   CASE UPPER(p_name)
                       WHEN 'P_USER_ID'   THEN 'SSO_APP_USER'      -- TODO-VERIFY: Forms P_USER_ID = SSO user id?
                       WHEN 'P_USER_TYPE' THEN 'V_USR_TYPE'        -- SC_USERS.USR_TYPE_CD (f345)
                       WHEN 'P_WS_ID'     THEN 'P_GLOBAL_V_WS_ID'  -- TODO-VERIFY
                       ELSE UPPER(p_name)                          -- P_CURR_PORT_CD, P_CLASS_CD, P_BRKR_NBR,
                   END);                                           -- P_PORT_TYPE (f345); P_BRKR_PORT_CD, P_LIC_TYPE (new)
    END APPLICATION_ITEM;

    FUNCTION answer (p_val IN VARCHAR2) RETURN PLS_INTEGER
    IS
    BEGIN
        RETURN NVL(TO_NUMBER(p_val), IMPR1110.c_yes);
    END answer;

    -- ----------------------------------------------------------------- server item state
    PROCEDURE state_reset
    IS
    BEGIN
        apex_collection.create_or_truncate_collection(c_state_coll);
    END state_reset;

    FUNCTION STATE_SEQUENCE (p_kind IN VARCHAR2, p_item IN VARCHAR2, p_prop IN VARCHAR2) RETURN NUMBER
    IS
        v_seq NUMBER;
    BEGIN
        SELECT MAX(seq_id) INTO v_seq
          FROM apex_collections
         WHERE collection_name = c_state_coll
           AND c001 = p_kind AND c002 = p_item AND c003 = p_prop;
        RETURN v_seq;
    END STATE_SEQUENCE;

    PROCEDURE state_put (p_kind IN VARCHAR2, p_item IN VARCHAR2, p_prop IN VARCHAR2, p_val IN VARCHAR2)
    IS
        v_seq NUMBER;
    BEGIN
        IF NOT apex_collection.collection_exists(c_state_coll) THEN
            state_reset;
        END IF;
        v_seq := STATE_SEQUENCE(p_kind, p_item, p_prop);
        IF v_seq IS NULL THEN
            apex_collection.add_member(p_collection_name => c_state_coll,
                                       p_c001 => p_kind, p_c002 => p_item, p_c003 => p_prop, p_c004 => p_val);
        ELSE
            apex_collection.update_member_attribute(p_collection_name => c_state_coll, p_seq => v_seq,
                                                    p_attr_number => 4, p_attr_value => p_val);
        END IF;
    END state_put;

    FUNCTION state_get (p_kind IN VARCHAR2, p_item IN VARCHAR2, p_prop IN VARCHAR2,
                        p_found OUT BOOLEAN) RETURN VARCHAR2
    IS
        v_val VARCHAR2(4000);
        v_cnt NUMBER;
    BEGIN
        p_found := FALSE;
        IF apex_collection.collection_exists(c_state_coll) THEN
            SELECT MAX(c004), COUNT(*) INTO v_val, v_cnt
              FROM apex_collections
             WHERE collection_name = c_state_coll
               AND c001 = p_kind AND c002 = p_item AND c003 = p_prop;
            p_found := v_cnt > 0;
        END IF;
        RETURN v_val;
    END state_get;

    -- 'Y' / 'N' for a UI property, p_default when the form never changed it
    FUNCTION ui_state (p_item IN VARCHAR2, p_prop IN VARCHAR2, p_default IN VARCHAR2) RETURN VARCHAR2
    IS
        v_found BOOLEAN;
        v_val   VARCHAR2(10) := state_get('UI', p_item, p_prop, v_found);
    BEGIN
        RETURN CASE WHEN v_found THEN v_val ELSE p_default END;
    END ui_state;

    -- Keep the UI entries recorded by the last IMPR1110 call (last one per item/prop wins)
    PROCEDURE save_ui
    IS
        v_item VARCHAR2(61);
        v_prop VARCHAR2(30);
        v_val  VARCHAR2(10);
    BEGIN
        FOR i IN 1 .. IMPR1110.ui_count LOOP
            IMPR1110.ui_entry(i, v_item, v_prop, v_val);
            IF v_prop IN ('ENTRABLE', 'ENABLED', 'REQUIRED', 'VISIBLE') THEN
                state_put('UI', v_item, v_prop, v_val);
            END IF;
        END LOOP;
    END save_ui;

    -- Current value of every validated item = "valid" (Forms: queried / created record)
    PROCEDURE BASELINE_VALUES
    IS
    BEGIN
        FOR i IN 1 .. c_val_items.COUNT LOOP
            state_put('VAL', c_val_items(i), '-', ITEM_VALUE(c_val_items(i)));
        END LOOP;
    END BASELINE_VALUES;

    -- ----------------------------------------------------------------- record / context
    FUNCTION GET_CONTEXT RETURN IMPR1110.T_CONTEXT
    IS
        c IMPR1110.T_CONTEXT;
    BEGIN
        c.curr_port_cd := TO_NUMBER(APPLICATION_ITEM('P_CURR_PORT_CD'));
        c.user_id      := APPLICATION_ITEM('P_USER_ID');
        c.ws_id        := APPLICATION_ITEM('P_WS_ID');
        c.class_cd     := TO_NUMBER(APPLICATION_ITEM('P_CLASS_CD'));
        c.user_type    := TO_NUMBER(APPLICATION_ITEM('P_USER_TYPE'));
        c.brkr_port_cd := TO_NUMBER(APPLICATION_ITEM('P_BRKR_PORT_CD'));
        c.lic_type     := TO_NUMBER(APPLICATION_ITEM('P_LIC_TYPE'));
        c.brkr_nbr     := TO_NUMBER(APPLICATION_ITEM('P_BRKR_NBR'));
        c.prsnl_impr   := NVL(NUMBER_ITEM('PRSNL_IMPR'), 0);      -- module parameter PRSNL_IMPR default 0
        c.letter_nbr   := ITEM_VALUE('LETTER_NBR');
        c.code         := ITEM_VALUE('CODE');
        RETURN c;
    END GET_CONTEXT;

    PROCEDURE SET_CONTEXT (p_ctx IN IMPR1110.T_CONTEXT)
    IS
    BEGIN
        SET_ITEM('LETTER_NBR', p_ctx.letter_nbr);
        SET_ITEM('CODE', p_ctx.code);
    END SET_CONTEXT;

    FUNCTION GET_RECORD RETURN IMPR1110.T_RECORD
    IS
        r IMPR1110.T_RECORD;
    BEGIN
        r.row_id            := ITEM_VALUE('ROW_ID');
        r.rec_status        := NVL(ITEM_VALUE('REC_STATUS'), CASE WHEN ITEM_VALUE('ROW_ID') IS NULL THEN 'NEW' ELSE 'QUERY' END);
        -- GET_ITEM_PROPERTY(..., ENABLED): from the server state, never from the browser
        r.activity_entr     := ui_state('ACTIVITY', 'ENTRABLE', 'Y');
        r.bus_id_brnch_entr := ui_state('BUS_ID_BRNCH', 'ENTRABLE', 'Y');
        r.port_cd           := NUMBER_ITEM('PORT_CD');           r.hq_impr_nbr       := NUMBER_ITEM('HQ_IMPR_NBR');
        r.impr_nbr          := NUMBER_ITEM('IMPR_NBR');          r.bus_id_status     := ITEM_VALUE('BUS_ID_STATUS');
        r.impr_type_cd      := NUMBER_ITEM('IMPR_TYPE_CD');      r.bus_id_exprd_dt   := DATE_ITEM('BUS_ID_EXPRD_DT');
        r.bus_id_type_cd    := NUMBER_ITEM('BUS_ID_TYPE_CD');    r.comm_rgstrtn_type := NUMBER_ITEM('COMM_RGSTRTN_TYPE');
        r.city_code_of_id   := NUMBER_ITEM('CITY_CODE_OF_ID');   r.bus_id            := ITEM_VALUE('BUS_ID');
        r.bus_id_brnch      := ITEM_VALUE('BUS_ID_BRNCH');      r.ctry_cd           := NUMBER_ITEM('CTRY_CD');
        r.impr_expr_type    := NUMBER_ITEM('IMPR_EXPR_TYPE');    r.arbc_impr_name    := ITEM_VALUE('ARBC_IMPR_NAME');
        r.impr_name_std     := ITEM_VALUE('IMPR_NAME_STD');     r.lst_tran_dt       := TO_DATE(ITEM_VALUE('LST_TRAN_DT'), 'YYYY/MM/DD HH24:MI:SS');
        r.impd_stmt_nbr     := ITEM_VALUE('IMPD_STMT_NBR');     r.impr_data_srce    := ITEM_VALUE('IMPR_DATA_SRCE');
        r.eng_impr_name     := ITEM_VALUE('ENG_IMPR_NAME');     r.impr_cntct_name   := ITEM_VALUE('IMPR_CNTCT_NAME');
        r.impr_address      := ITEM_VALUE('IMPR_ADDRESS');      r.bus_id_issue_dt   := DATE_ITEM('BUS_ID_ISSUE_DT');
        r.impr_nbr_parent   := NUMBER_ITEM('IMPR_NBR_PARENT');   r.add_ctry_cd       := NUMBER_ITEM('ADD_CTRY_CD');
        r.city_code         := NUMBER_ITEM('CITY_CODE');         r.impr_pob_nbr      := ITEM_VALUE('IMPR_POB_NBR');
        r.impr_zip_cd       := ITEM_VALUE('IMPR_ZIP_CD');       r.impr_tel_nbr      := ITEM_VALUE('IMPR_TEL_NBR');
        r.impr_fax_nbr      := ITEM_VALUE('IMPR_FAX_NBR');      r.impr_telex_nbr    := ITEM_VALUE('IMPR_TELEX_NBR');
        r.email             := ITEM_VALUE('EMAIL');             r.mobile_no         := ITEM_VALUE('MOBILE_NO');
        r.bank_iban         := ITEM_VALUE('BANK_IBAN');         r.id_nbr            := ITEM_VALUE('ID_NBR');
        r.car_agent_flag    := NUMBER_ITEM('CAR_AGENT_FLAG');    r.express_post      := ITEM_VALUE('EXPRESS_POST');
        r.ctry_cd_of_id     := ITEM_VALUE('CTRY_CD_OF_ID');     r.expd_stmt_nbr     := ITEM_VALUE('EXPD_STMT_NBR');
        r.wvr_entry_nbr     := ITEM_VALUE('WVR_ENTRY_NBR');     r.activity          := ITEM_VALUE('ACTIVITY');
        r.customs_entered   := ITEM_VALUE('CUSTOMS_ENTERED');   r.creation_flag     := ITEM_VALUE('CREATION_FLAG');
        r.port_name         := ITEM_VALUE('PORT_NAME');         r.sdp_port_status   := NUMBER_ITEM('SDP_PORT_STATUS');
        r.suspn_status      := ITEM_VALUE('SUSPN_STATUS');      r.status_desc       := ITEM_VALUE('STATUS_DESC');
        r.impr_type_name    := ITEM_VALUE('IMPR_TYPE_NAME');    r.bus_id_type_name  := ITEM_VALUE('BUS_ID_TYPE_NAME');
        r.id_city_name      := ITEM_VALUE('ID_CITY_NAME');      r.id_mins_comm_cd   := NUMBER_ITEM('ID_MINS_COMM_CD');
        r.l_ct_city_status2 := NUMBER_ITEM('L_CT_CITY_STATUS2'); r.brnh_id_mins_comm_cd := NUMBER_ITEM('BRNH_ID_MINS_COMM_CD');
        r.brnh_city_cd      := NUMBER_ITEM('BRNH_CITY_CD');      r.brnh_city_name    := ITEM_VALUE('BRNH_CITY_NAME');
        r.crty_arbc_name    := ITEM_VALUE('CRTY_ARBC_NAME');    r.ctry_ctry_status  := NUMBER_ITEM('CTRY_CTRY_STATUS');
        r.itidt_note        := ITEM_VALUE('ITIDT_NOTE');        r.status            := NUMBER_ITEM('STATUS');
        r.impr_name_parent  := ITEM_VALUE('IMPR_NAME_PARENT');  r.wasl_city_name    := ITEM_VALUE('WASL_CITY_NAME');
        r.add_crty_arbc_name := ITEM_VALUE('ADD_CRTY_ARBC_NAME'); r.city_name       := ITEM_VALUE('CITY_NAME');
        r.l_ct_city_status  := NUMBER_ITEM('L_CT_CITY_STATUS');  r.b_email           := ITEM_VALUE('B_EMAIL');
        r.b_mobile_no       := ITEM_VALUE('B_MOBILE_NO');       r.b_id_nbr          := ITEM_VALUE('B_ID_NBR');
        r.impr_id_type      := ITEM_VALUE('IMPR_ID_TYPE');
        RETURN r;
    END GET_RECORD;

    PROCEDURE SET_RECORD (p_rec IN IMPR1110.T_RECORD)
    IS
    BEGIN
        SET_ITEM('ROW_ID', p_rec.row_id);                 SET_ITEM('REC_STATUS', p_rec.rec_status);
        SET_ITEM('PORT_CD', p_rec.port_cd);               SET_ITEM('HQ_IMPR_NBR', p_rec.hq_impr_nbr);
        SET_ITEM('IMPR_NBR', p_rec.impr_nbr);             SET_ITEM('BUS_ID_STATUS', p_rec.bus_id_status);
        SET_ITEM('IMPR_TYPE_CD', p_rec.impr_type_cd);     SET_ITEM('BUS_ID_EXPRD_DT', TO_CHAR(p_rec.bus_id_exprd_dt, c_mask));
        SET_ITEM('BUS_ID_TYPE_CD', p_rec.bus_id_type_cd); SET_ITEM('COMM_RGSTRTN_TYPE', p_rec.comm_rgstrtn_type);
        SET_ITEM('CITY_CODE_OF_ID', p_rec.city_code_of_id); SET_ITEM('BUS_ID', p_rec.bus_id);
        SET_ITEM('BUS_ID_BRNCH', p_rec.bus_id_brnch);     SET_ITEM('CTRY_CD', p_rec.ctry_cd);
        SET_ITEM('IMPR_EXPR_TYPE', p_rec.impr_expr_type); SET_ITEM('ARBC_IMPR_NAME', p_rec.arbc_impr_name);
        SET_ITEM('IMPR_NAME_STD', p_rec.impr_name_std);   SET_ITEM('LST_TRAN_DT', TO_CHAR(p_rec.lst_tran_dt, 'YYYY/MM/DD HH24:MI:SS'));
        SET_ITEM('IMPD_STMT_NBR', p_rec.impd_stmt_nbr);   SET_ITEM('IMPR_DATA_SRCE', p_rec.impr_data_srce);
        SET_ITEM('ENG_IMPR_NAME', p_rec.eng_impr_name);   SET_ITEM('IMPR_CNTCT_NAME', p_rec.impr_cntct_name);
        SET_ITEM('IMPR_ADDRESS', p_rec.impr_address);     SET_ITEM('BUS_ID_ISSUE_DT', TO_CHAR(p_rec.bus_id_issue_dt, c_mask));
        SET_ITEM('IMPR_NBR_PARENT', p_rec.impr_nbr_parent); SET_ITEM('ADD_CTRY_CD', p_rec.add_ctry_cd);
        SET_ITEM('CITY_CODE', p_rec.city_code);           SET_ITEM('IMPR_POB_NBR', p_rec.impr_pob_nbr);
        SET_ITEM('IMPR_ZIP_CD', p_rec.impr_zip_cd);       SET_ITEM('IMPR_TEL_NBR', p_rec.impr_tel_nbr);
        SET_ITEM('IMPR_FAX_NBR', p_rec.impr_fax_nbr);     SET_ITEM('IMPR_TELEX_NBR', p_rec.impr_telex_nbr);
        SET_ITEM('EMAIL', p_rec.email);                   SET_ITEM('MOBILE_NO', p_rec.mobile_no);
        SET_ITEM('BANK_IBAN', p_rec.bank_iban);           SET_ITEM('ID_NBR', p_rec.id_nbr);
        SET_ITEM('CAR_AGENT_FLAG', p_rec.car_agent_flag); SET_ITEM('EXPRESS_POST', p_rec.express_post);
        SET_ITEM('CTRY_CD_OF_ID', p_rec.ctry_cd_of_id);   SET_ITEM('EXPD_STMT_NBR', p_rec.expd_stmt_nbr);
        SET_ITEM('WVR_ENTRY_NBR', p_rec.wvr_entry_nbr);   SET_ITEM('ACTIVITY', p_rec.activity);
        SET_ITEM('CUSTOMS_ENTERED', p_rec.customs_entered); SET_ITEM('CREATION_FLAG', p_rec.creation_flag);
        SET_ITEM('PORT_NAME', p_rec.port_name);           SET_ITEM('SDP_PORT_STATUS', p_rec.sdp_port_status);
        SET_ITEM('SUSPN_STATUS', p_rec.suspn_status);     SET_ITEM('STATUS_DESC', p_rec.status_desc);
        SET_ITEM('IMPR_TYPE_NAME', p_rec.impr_type_name); SET_ITEM('BUS_ID_TYPE_NAME', p_rec.bus_id_type_name);
        SET_ITEM('ID_CITY_NAME', p_rec.id_city_name);     SET_ITEM('ID_MINS_COMM_CD', p_rec.id_mins_comm_cd);
        SET_ITEM('L_CT_CITY_STATUS2', p_rec.l_ct_city_status2); SET_ITEM('BRNH_ID_MINS_COMM_CD', p_rec.brnh_id_mins_comm_cd);
        SET_ITEM('BRNH_CITY_CD', p_rec.brnh_city_cd);     SET_ITEM('BRNH_CITY_NAME', p_rec.brnh_city_name);
        SET_ITEM('CRTY_ARBC_NAME', p_rec.crty_arbc_name); SET_ITEM('CTRY_CTRY_STATUS', p_rec.ctry_ctry_status);
        SET_ITEM('ITIDT_NOTE', p_rec.itidt_note);         SET_ITEM('STATUS', p_rec.status);
        SET_ITEM('IMPR_NAME_PARENT', p_rec.impr_name_parent); SET_ITEM('WASL_CITY_NAME', p_rec.wasl_city_name);
        SET_ITEM('ADD_CRTY_ARBC_NAME', p_rec.add_crty_arbc_name); SET_ITEM('CITY_NAME', p_rec.city_name);
        SET_ITEM('L_CT_CITY_STATUS', p_rec.l_ct_city_status); SET_ITEM('B_EMAIL', p_rec.b_email);
        SET_ITEM('B_MOBILE_NO', p_rec.b_mobile_no);       SET_ITEM('B_ID_NBR', p_rec.b_id_nbr);
        SET_ITEM('IMPR_ID_TYPE', p_rec.impr_id_type);
    END SET_RECORD;

    -- Writes ui_json into P1110_UI_STATE (applied by the page-load Dynamic Action) and keeps
    -- the item state on the server
    PROCEDURE keep_ui
    IS
    BEGIN
        save_ui;
        SET_ITEM('UI_STATE', dbms_lob.substr(IMPR1110.ui_json, 32000, 1));
    END keep_ui;

    -- Text Forms would show for an error (business errors pass through unchanged)
    FUNCTION ERROR_TEXT (p_op IN VARCHAR2) RETURN VARCHAR2
    IS
    BEGIN
        IF SQLCODE BETWEEN -20999 AND -20000 THEN
            RETURN REGEXP_REPLACE(SQLERRM, '^ORA-[0-9]+: ');
        END IF;
        RETURN IMPR1110.importers_on_error(p_op, SQLCODE, SQLERRM);
    END ERROR_TEXT;

    -- Block WHERE clause of IMPORTERS: PORT_CD = :PARAMETER.P_CURR_PORT_CD (always applied)
    PROCEDURE load_row (p_rec IN OUT NOCOPY IMPR1110.T_RECORD, p_where_rowid IN VARCHAR2,
                        p_port_cd IN NUMBER, p_impr_nbr IN NUMBER, p_curr_port IN NUMBER)
    IS
    BEGIN
        SELECT ROWIDTOCHAR(ROWID), port_cd, hq_impr_nbr, impr_nbr, bus_id_status, impr_type_cd,
               bus_id_exprd_dt, bus_id_type_cd, comm_rgstrtn_type, city_code_of_id, bus_id,
               bus_id_brnch, ctry_cd, impr_expr_type, arbc_impr_name, impr_name_std, lst_tran_dt,
               impd_stmt_nbr, impr_data_srce, eng_impr_name, impr_cntct_name, impr_address,
               bus_id_issue_dt, impr_nbr_parent, add_ctry_cd, city_code, impr_pob_nbr, impr_zip_cd,
               impr_tel_nbr, impr_fax_nbr, impr_telex_nbr, email, mobile_no, bank_iban, id_nbr,
               car_agent_flag, express_post, ctry_cd_of_id, expd_stmt_nbr, wvr_entry_nbr,
               activity, customs_entered, creation_flag
          INTO p_rec.row_id, p_rec.port_cd, p_rec.hq_impr_nbr, p_rec.impr_nbr, p_rec.bus_id_status,
               p_rec.impr_type_cd, p_rec.bus_id_exprd_dt, p_rec.bus_id_type_cd, p_rec.comm_rgstrtn_type,
               p_rec.city_code_of_id, p_rec.bus_id, p_rec.bus_id_brnch, p_rec.ctry_cd,
               p_rec.impr_expr_type, p_rec.arbc_impr_name, p_rec.impr_name_std, p_rec.lst_tran_dt,
               p_rec.impd_stmt_nbr, p_rec.impr_data_srce, p_rec.eng_impr_name, p_rec.impr_cntct_name,
               p_rec.impr_address, p_rec.bus_id_issue_dt, p_rec.impr_nbr_parent, p_rec.add_ctry_cd,
               p_rec.city_code, p_rec.impr_pob_nbr, p_rec.impr_zip_cd, p_rec.impr_tel_nbr,
               p_rec.impr_fax_nbr, p_rec.impr_telex_nbr, p_rec.email, p_rec.mobile_no,
               p_rec.bank_iban, p_rec.id_nbr, p_rec.car_agent_flag, p_rec.express_post,
               p_rec.ctry_cd_of_id, p_rec.expd_stmt_nbr, p_rec.wvr_entry_nbr, p_rec.activity,
               p_rec.customs_entered, p_rec.creation_flag
          FROM importers
         WHERE port_cd = p_curr_port
           AND ((p_where_rowid IS NOT NULL AND ROWID = CHARTOROWID(p_where_rowid))
                OR (p_where_rowid IS NULL AND port_cd = p_port_cd AND impr_nbr = p_impr_nbr));
        p_rec.rec_status := 'QUERY';
    END load_row;

    -- ----------------------------------------------------------------- dispatch (Forms order)
    PROCEDURE run_validate (p_item IN VARCHAR2, r IN OUT NOCOPY IMPR1110.T_RECORD,
                            c IN IMPR1110.T_CONTEXT, a1 IN PLS_INTEGER, a2 IN PLS_INTEGER,
                            p_from_item IN BOOLEAN)
    IS
    BEGIN
        -- 1) POST-CHANGE
        CASE p_item
            WHEN 'HQ_IMPR_NBR'    THEN IMPR1110.HQ_IMPR_NBR_POST_CHANGE;
            WHEN 'IMPR_TYPE_CD'   THEN IMPR1110.IMPR_TYPE_CD_POST_CHANGE(r);
            WHEN 'BUS_ID_TYPE_CD' THEN IMPR1110.BUS_ID_TYPE_CD_POST_CHANGE(r);
            WHEN 'BUS_ID'         THEN IMPR1110.BUS_ID_POST_CHANGE;
            WHEN 'BUS_ID_BRNCH'   THEN IMPR1110.BUS_ID_BRNCH_POST_CHANGE;
            WHEN 'IMPR_EXPR_TYPE' THEN IMPR1110.IMPR_EXPR_TYPE_POST_CHANGE;
            WHEN 'B_EMAIL'        THEN IMPR1110.B_EMAIL_POST_CHANGE(r, c);
            WHEN 'B_MOBILE_NO'    THEN IMPR1110.B_MOBILE_NO_POST_CHANGE(r, c);
            WHEN 'B_ID_NBR'       THEN IMPR1110.B_ID_NBR_POST_CHANGE(r, c);
            ELSE NULL;
        END CASE;
        -- 2) WHEN-VALIDATE-ITEM
        CASE p_item
            WHEN 'PORT_CD'         THEN IMPR1110.PORT_CD_WHEN_VALIDATE_ITEM(r);
            WHEN 'IMPR_NBR'        THEN IMPR1110.IMPR_NBR_WHEN_VALIDATE_ITEM(r);
            WHEN 'IMPR_TYPE_CD'    THEN IMPR1110.IMPR_TYPE_CD_VALIDATE_ITEM(r, c);
            WHEN 'BUS_ID_EXPRD_DT' THEN IMPR1110.BUS_ID_EXPRD_DT_VALIDATE_ITEM(r, p_from_item);
            WHEN 'CTRY_CD_OF_ID'   THEN IMPR1110.CTRY_CD_OF_ID_VALIDATE_ITEM(r);
            WHEN 'CITY_CODE_OF_ID' THEN IMPR1110.CITY_CODE_OF_ID_VALIDATE_ITEM(r);
            WHEN 'BUS_ID'          THEN IMPR1110.BUS_ID_WHEN_VALIDATE_ITEM(r, c, a1, a2);
            WHEN 'BRNH_CITY_CD'    THEN IMPR1110.BRNH_CITY_CD_VALIDATE_ITEM(r);
            WHEN 'BUS_ID_BRNCH'    THEN IMPR1110.BUS_ID_BRNCH_VALIDATE_ITEM(r, c, a1);
            WHEN 'CTRY_CD'         THEN IMPR1110.CTRY_CD_WHEN_VALIDATE_ITEM(r);
            WHEN 'ARBC_IMPR_NAME'  THEN IMPR1110.ARBC_IMPR_NAME_VALIDATE_ITEM(r);
            WHEN 'ENG_IMPR_NAME'   THEN IMPR1110.ENG_IMPR_NAME_VALIDATE_ITEM(r);
            WHEN 'BUS_ID_ISSUE_DT' THEN IMPR1110.BUS_ID_ISSUE_DT_VALIDATE_ITEM(r, p_from_item);
            WHEN 'IMPR_NBR_PARENT' THEN IMPR1110.IMPR_NBR_PARENT_VALIDATE_ITEM(r);
            WHEN 'ADD_CTRY_CD'     THEN IMPR1110.ADD_CTRY_CD_WHEN_VALIDATE_ITEM(r);
            WHEN 'CITY_CODE'       THEN IMPR1110.CITY_CODE_WHEN_VALIDATE_ITEM(r);
            WHEN 'IMPR_TEL_NBR'    THEN IMPR1110.IMPR_TEL_NBR_VALIDATE_ITEM(r);
            WHEN 'B_EMAIL'         THEN IMPR1110.B_EMAIL_WHEN_VALIDATE_ITEM(r, p_from_item);
            WHEN 'EMAIL'           THEN IMPR1110.EMAIL_WHEN_VALIDATE_ITEM(r, p_from_item);
            WHEN 'B_MOBILE_NO'     THEN IMPR1110.B_MOBILE_NO_WHEN_VALIDATE_ITEM(r, c);
            WHEN 'BANK_IBAN'       THEN IMPR1110.BANK_IBAN_WHEN_VALIDATE_ITEM(r);
            WHEN 'B_ID_NBR'        THEN IMPR1110.B_ID_NBR_WHEN_VALIDATE_ITEM(r);
            ELSE NULL;
        END CASE;
        IF r.rec_status = 'QUERY' THEN
            r.rec_status := 'CHANGED';
        ELSIF r.rec_status = 'NEW' THEN
            r.rec_status := 'INSERT';
        END IF;
    END run_validate;

    -- ----------------------------------------------------------------- page processes
    PROCEDURE PAGE_WHEN_NEW_FORM_INSTANCE
    IS
        r IMPR1110.T_RECORD := GET_RECORD;
    BEGIN
        state_reset;
        IMPR1110.ui_reset;
        IMPR1110.WHEN_NEW_FORM_INSTANCE(r, GET_CONTEXT);
        SET_RECORD(r);
        SET_ITEM('FORM_OPEN', 'Y');
        keep_ui;
    END PAGE_WHEN_NEW_FORM_INSTANCE;

    PROCEDURE page_fetch
    IS
        r   IMPR1110.T_RECORD;
        c   IMPR1110.T_CONTEXT := GET_CONTEXT;
        q   IMPR1110.T_RECORD := GET_RECORD;      -- query criteria / key
    BEGIN
        SET_ITEM('NEED_FETCH', NULL);
        IMPR1110.ui_reset;
        IMPR1110.IMPORTERS_PRE_QUERY(q, c);   -- consumes :GLOBAL.EXEC_QUERY_NOW
        q.port_cd := NVL(q.port_cd, c.curr_port_cd);
        IF q.row_id IS NULL AND q.impr_nbr IS NULL THEN
            RETURN;
        END IF;
        load_row(r, q.row_id, q.port_cd, q.impr_nbr, c.curr_port_cd);
        IF c_post_chg_on_fetch THEN
            IF r.hq_impr_nbr IS NOT NULL THEN IMPR1110.HQ_IMPR_NBR_POST_CHANGE; END IF;
            IF r.impr_type_cd IS NOT NULL THEN IMPR1110.IMPR_TYPE_CD_POST_CHANGE(r); END IF;
            IF r.bus_id_type_cd IS NOT NULL THEN IMPR1110.BUS_ID_TYPE_CD_POST_CHANGE(r); END IF;
            IF r.bus_id IS NOT NULL THEN IMPR1110.BUS_ID_POST_CHANGE; END IF;
            IF r.bus_id_brnch IS NOT NULL THEN IMPR1110.BUS_ID_BRNCH_POST_CHANGE; END IF;
            IF r.impr_expr_type IS NOT NULL THEN IMPR1110.IMPR_EXPR_TYPE_POST_CHANGE; END IF;
        END IF;
        IMPR1110.IMPORTERS_POST_QUERY(r, c);
        r.rec_status := 'QUERY';
        IMPR1110.IMPORTERS_PRE_RECORD(r, c);
        IMPR1110.IMPORTERS_NEW_RECORD_INSTANCE(r, c);
        SET_RECORD(r);
        SET_CONTEXT(c);
        BASELINE_VALUES;
        keep_ui;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            -- Forms FRM-40350 "Query caused no records to be retrieved"
            -- TODO: Arabic text used by NIB.ON_MESSAGE (MISSING SOURCE)
            apex_error.add_error(p_message => 'FRM-40350',
                                 p_display_location => apex_error.c_inline_in_notification);
    END page_fetch;

    PROCEDURE page_new_record
    IS
        r IMPR1110.T_RECORD := GET_RECORD;
        c IMPR1110.T_CONTEXT := GET_CONTEXT;
    BEGIN
        IF r.row_id IS NOT NULL THEN
            RETURN;
        END IF;
        IMPR1110.ui_reset;
        r.rec_status := 'NEW';
        IMPR1110.IMPORTERS_WHEN_CREATE_RECORD(r, c);
        IMPR1110.IMPORTERS_PRE_RECORD(r, c);
        IMPR1110.IMPORTERS_NEW_RECORD_INSTANCE(r, c);
        SET_RECORD(r);
        SET_CONTEXT(c);
        BASELINE_VALUES;
        keep_ui;
    END page_new_record;

    -- ----------------------------------------------------------------- AJAX
    PROCEDURE reply (p_rec IN IMPR1110.T_RECORD, p_ctx IN IMPR1110.T_CONTEXT)
    IS
        v_items CLOB;
    BEGIN
        SET_RECORD(p_rec);
        SET_CONTEXT(p_ctx);
        save_ui;
        apex_json.initialize_clob_output;
        apex_json.open_object;
        FOR i IN (SELECT item_name
                    FROM apex_application_page_items
                   WHERE application_id = TO_NUMBER(FORMS_COMPAT.name_in('APP_ID'))
                     AND page_id = c_page
                     AND item_name NOT IN ('P1110_ROW_ID', 'P1110_UI_STATE', 'P1110_FORM_OPEN', 'P1110_NEED_FETCH')) LOOP
            apex_json.write(i.item_name, FORMS_COMPAT.name_in(i.item_name), TRUE);
        END LOOP;
        apex_json.close_object;
        v_items := apex_json.get_clob_output;
        apex_json.free_output;
        htp.prn('{"items":');
        htp.prn(v_items);
        htp.prn(',"ui":');
        htp.prn(IMPR1110.ui_json);
        htp.prn('}');
    END reply;

    PROCEDURE reply_error (p_rec IN IMPR1110.T_RECORD, p_ctx IN IMPR1110.T_CONTEXT, p_op IN VARCHAR2)
    IS
        v_text VARCHAR2(4000) := ERROR_TEXT(p_op);
    BEGIN
        SET_RECORD(p_rec);                       -- Forms keeps item changes made before the failure
        SET_CONTEXT(p_ctx);
        save_ui;
        apex_json.open_object;
        apex_json.write('error', v_text);
        apex_json.close_object;
    END reply_error;

    PROCEDURE ajax_item
    IS
        v_item VARCHAR2(61) := UPPER(apex_application.g_x01);
        v_evt  VARCHAR2(30) := UPPER(apex_application.g_x02);
        a1     PLS_INTEGER  := answer(apex_application.g_x03);
        a2     PLS_INTEGER  := answer(apex_application.g_x04);
        r      IMPR1110.T_RECORD := GET_RECORD;
        c      IMPR1110.T_CONTEXT := GET_CONTEXT;
    BEGIN
        IMPR1110.ui_reset;
        IF v_evt = 'VALIDATE' THEN
            -- City chosen from LOV_CITIES_IMP: COPY_SELECTED_VALUES set :GLOBAL.MINS_COMM_CD
            IF v_item IN ('CITY_CODE_OF_ID', 'BRNH_CITY_CD') AND apex_application.g_x05 = 'LOV' THEN
                FOR m IN (SELECT mins_comm_cd FROM cities
                           WHERE city_cd = CASE v_item WHEN 'CITY_CODE_OF_ID' THEN r.city_code_of_id
                                                       ELSE r.brnh_city_cd END
                             AND ctry_cd = NVL(r.ctry_cd_of_id, ctry_cd)
                             AND ROWNUM = 1) LOOP
                    FORMS_COMPAT.set_global('MINS_COMM_CD', m.mins_comm_cd);
                END LOOP;
            END IF;
            run_validate(v_item, r, c, a1, a2, TRUE);
            -- the item itself is now valid with its final value (e.g. BUS_ID after the 9-120
            -- prefix). Other items changed by the trigger keep their previous "validated" value
            -- and are validated again at SAVE (Forms validates programmatically changed items
            -- when the record is validated).
            SET_RECORD(r);
            state_put('VAL', v_item, '-', ITEM_VALUE(v_item));
        ELSIF v_evt = 'WNII' THEN
            CASE v_item
                WHEN 'IMPR_TYPE_CD'    THEN IMPR1110.IMPR_TYPE_CD_NEW_ITEM_INSTANCE(r);
                WHEN 'CITY_CODE_OF_ID' THEN IMPR1110.CITY_CODE_OF_ID_WHEN_NEW_ITEM(r);
                WHEN 'BUS_ID'          THEN IMPR1110.BUS_ID_WHEN_NEW_ITEM_INSTANCE(r);
                WHEN 'BRNH_CITY_CD'    THEN IMPR1110.BRNH_CITY_CD_NEW_ITEM_INSTANCE;
                WHEN 'BUS_ID_BRNCH'    THEN IMPR1110.BUS_ID_BRNCH_NEW_ITEM_INSTANCE(r);
                WHEN 'BANK_IBAN'       THEN IMPR1110.BANK_IBAN_NEW_ITEM_INSTANCE(r);
                ELSE NULL;
            END CASE;
        ELSIF v_evt = 'WLC' AND v_item = 'COMM_RGSTRTN_TYPE' THEN
            IMPR1110.COMM_RGSTRTN_TYPE_LIST_CHANGED(r);
        ELSIF v_evt = 'LOV_RET' AND v_item = 'BUS_ID_TYPE_CD' THEN
            -- LOV_IMPR_TYPE returned the pair IMPR_TYPE_CD / BUS_ID_TYPE_CD and both names
            FOR t IN (SELECT it.impr_type_name, bit.bus_id_type_name
                        FROM impr_types it, bus_id_types bit
                       WHERE it.impr_type_cd = r.impr_type_cd
                         AND bit.bus_id_type_cd = r.bus_id_type_cd) LOOP
                r.impr_type_name   := t.impr_type_name;
                r.bus_id_type_name := t.bus_id_type_name;
            END LOOP;
            IMPR1110.IMPR_TYPE_CD_LOV_RETURN(r);
            IMPR1110.BUS_ID_TYPE_CD_POST_CHANGE(r);            -- value changed -> POST-CHANGE
            state_put('VAL', 'BUS_ID_TYPE_CD', '-', ITEM_VALUE('BUS_ID_TYPE_CD'));
        ELSIF v_evt = 'KEY_NXT' AND v_item = 'ARBC_IMPR_NAME' THEN
            IMPR1110.ARBC_IMPR_NAME_KEY_NEXT_ITEM(r);
        ELSIF v_evt = 'WNRI' THEN
            IMPR1110.IMPORTERS_NEW_RECORD_INSTANCE(r, c, a1);
        END IF;
        reply(r, c);
    EXCEPTION
        WHEN OTHERS THEN
            reply_error(r, c, CASE WHEN r.row_id IS NULL THEN 'I' ELSE 'U' END);
    END ajax_item;

    PROCEDURE ajax_confirm
    IS
        r      IMPR1110.T_RECORD := GET_RECORD;
        c      IMPR1110.T_CONTEXT := GET_CONTEXT;
        v_text VARCHAR2(4000);
        v_nbr  NUMBER;
    BEGIN
        CASE UPPER(apex_application.g_x01)
            WHEN 'WNRI' THEN
                v_text := IMPR1110.NEW_RECORD_CONFIRM_TEXT(r, c);
            WHEN 'SUSP' THEN
                v_nbr := IMPR1110.BUS_ID_SUSPENDED_IMPORTER(r);
                IF v_nbr <> 0 THEN
                    v_text := 'يوجد مستورد' || v_nbr
                              || ' موقوف له نفس الرقم الإستدلالي" هل تريد تعديل الرقم الاستدلالي بالرغم من ذلك ؟';
                END IF;
            WHEN 'UPD_IMPR' THEN
                v_text := IMPR1110.update_importer_msg(r);
            ELSE
                NULL;
        END CASE;
        apex_json.open_object;
        apex_json.write('text', v_text, TRUE);
        apex_json.close_object;
    END ajax_confirm;

    PROCEDURE AJAX_FUNCTION
    IS
        v_cd VARCHAR2(30) := UPPER(apex_application.g_x01);
        r    IMPR1110.T_RECORD := GET_RECORD;
        c    IMPR1110.T_CONTEXT := GET_CONTEXT;
    BEGIN
        IMPR1110.ui_reset;
        IF v_cd = 'IMPR_MCI_SERVICE' THEN
            IF answer(apex_application.g_x02) = IMPR1110.c_yes
               AND (FORMS_COMPAT.get_global('ALLOW_MCI') = '1'
                    OR FORMS_COMPAT.get_global('ALLOW_MOI') = '1') THEN
                IMPR1110.update_importer(r);
            END IF;
        ELSIF v_cd = 'IMPR1110_MOB_RET' THEN          -- after dialog LOV_UPDATE_IMPR_MOBILE closed
            IMPR1110.lov_update_moblie(r);
        ELSE
            -- EXEC_FUNS may set :PARAMETER.CODE (reply item P1110_CODE). The page then runs
            -- WHEN-NEW-RECORD-INSTANCE: IMPR1110_CONFIRM('WNRI') -> Confirm -> IMPR1110_ITEM('WNRI')
            IMPR1110.exec_funs(r, c, v_cd);
        END IF;
        reply(r, c);
    EXCEPTION
        WHEN OTHERS THEN
            reply_error(r, c, 'U');
    END AJAX_FUNCTION;

    -- ----------------------------------------------------------------- clear / query / dialogs
    PROCEDURE page_clear
    IS
        v_empty IMPR1110.T_RECORD;
    BEGIN
        IMPR1110.ui_reset;
        IMPR1110.IMPORTERS_WHEN_CLEAR_BLOCK;
        SET_RECORD(v_empty);
        SET_ITEM('REC_STATUS', NULL);
        SET_ITEM('NEED_FETCH', NULL);
        IF apex_collection.collection_exists(c_state_coll) THEN
            FOR m IN (SELECT seq_id FROM apex_collections
                       WHERE collection_name = c_state_coll AND c001 = 'VAL') LOOP
                apex_collection.delete_member(c_state_coll, m.seq_id);
            END LOOP;
        END IF;
    END page_clear;

    PROCEDURE page_query (p_impr_nbr IN NUMBER)
    IS
    BEGIN
        page_clear;
        SET_ITEM('PORT_CD', APPLICATION_ITEM('P_CURR_PORT_CD'));
        SET_ITEM('IMPR_NBR', p_impr_nbr);
        SET_ITEM('NEED_FETCH', 'Y');
    END page_query;

    FUNCTION central_mobile (p_impr_nbr IN NUMBER) RETURN NUMBER
    IS
        r IMPR1110.T_RECORD;
    BEGIN
        r.impr_nbr := p_impr_nbr;
        RETURN IMPR1110.central_mobile(r, GET_CONTEXT);
    END central_mobile;

    -- ----------------------------------------------------------------- validations on SAVE
    FUNCTION validate_on_submit (p_item IN VARCHAR2) RETURN VARCHAR2
    IS
        r       IMPR1110.T_RECORD := GET_RECORD;
        c       IMPR1110.T_CONTEXT := GET_CONTEXT;
        v_found BOOLEAN;
        v_last  VARCHAR2(4000) := state_get('VAL', UPPER(p_item), '-', v_found);
        v_now   VARCHAR2(4000) := ITEM_VALUE(UPPER(p_item));
    BEGIN
        IF v_found AND (v_last = v_now OR (v_last IS NULL AND v_now IS NULL)) THEN
            RETURN NULL;                               -- item is valid (Forms: not changed)
        END IF;
        IMPR1110.ui_reset;
        run_validate(UPPER(p_item), r, c, IMPR1110.c_yes, IMPR1110.c_yes, FALSE);
        SET_RECORD(r);
        save_ui;
        state_put('VAL', UPPER(p_item), '-', ITEM_VALUE(UPPER(p_item)));
        RETURN NULL;
    EXCEPTION
        WHEN OTHERS THEN
            SET_RECORD(r);
            save_ui;
            RETURN ERROR_TEXT(CASE WHEN r.row_id IS NULL THEN 'I' ELSE 'U' END);
    END validate_on_submit;

    FUNCTION required_items RETURN VARCHAR2
    IS
        FUNCTION IS_REQUIRED (p_item IN VARCHAR2, p_static IN VARCHAR2) RETURN BOOLEAN IS
        BEGIN
            RETURN ui_state(p_item, 'REQUIRED', p_static) = 'Y';
        END IS_REQUIRED;
    BEGIN
        FOR i IN 1 .. c_req_items.COUNT LOOP
            IF IS_REQUIRED(c_req_items(i), 'Y') AND ITEM_VALUE(c_req_items(i)) IS NULL THEN
                -- Forms FRM-40202 "Field must be entered" - TODO: Arabic text of NIB.ON_ERROR
                RETURN 'FRM-40202: ' || c_req_items(i);
            END IF;
        END LOOP;
        FOR i IN 1 .. c_dyn_req_items.COUNT LOOP
            IF IS_REQUIRED(c_dyn_req_items(i), 'N') AND ITEM_VALUE(c_dyn_req_items(i)) IS NULL THEN
                RETURN 'FRM-40202: ' || c_dyn_req_items(i);
            END IF;
        END LOOP;
        RETURN NULL;
    END required_items;

    PROCEDURE page_dml (p_request IN VARCHAR2)
    IS
        r       IMPR1110.T_RECORD := GET_RECORD;
        c       IMPR1110.T_CONTEXT := GET_CONTEXT;
        v_empty IMPR1110.T_RECORD;
        v_op    VARCHAR2(1);
    BEGIN
        IMPR1110.ui_reset;
        IF p_request = 'SAVE' THEN
            IF r.row_id IS NULL THEN
                IF r.rec_status = 'NEW' THEN
                    RETURN;                                -- nothing entered: Forms inserts nothing
                END IF;
                v_op := 'I';
                IMPR1110.IMPORTERS_PRE_INSERT(r, c);      -- Confirm (class 1 / type 3) done by DA
                IMPR1110.IMPORTERS_INSERT(r);
                IMPR1110.IMPORTERS_POST_INSERT(r, c);
            ELSIF r.rec_status = 'CHANGED' THEN
                v_op := 'U';
                IMPR1110.IMPORTERS_PRE_UPDATE(r, c);
                IMPR1110.IMPORTERS_UPDATE(r);
                IMPR1110.IMPORTERS_POST_UPDATE(r);
            END IF;
            r.rec_status := 'QUERY';
        ELSIF p_request = 'DELETE' THEN
            v_op := 'D';
            IMPR1110.importers_key_delrec(r, c);          -- Confirm 'هل أنت متأكد من عملية الحذف' done by DA
            r := v_empty;
            r.rec_status := 'NEW';
        END IF;
        SET_RECORD(r);
        keep_ui;
        BASELINE_VALUES;
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20000, ERROR_TEXT(v_op));
    END page_dml;


    -- =========================================================================
    -- PACKAGE VERSION   (SELECT IMPR1110_APX.PKG_VERSION FROM dual;)
    -- =========================================================================
    FUNCTION PKG_VERSION
       RETURN VARCHAR2
    IS
    BEGIN
       RETURN V_INFO;
    END PKG_VERSION;

END IMPR1110_APX;
/
SHOW ERRORS
