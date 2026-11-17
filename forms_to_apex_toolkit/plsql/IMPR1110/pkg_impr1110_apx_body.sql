-- =============================================================================
-- Package body : pkg_impr1110_apx  (APEX glue for pkg_impr1110, page 1110)
-- Author       : Claude Code
-- Created      : 2026-11-18
-- Version      : 1.0.0
-- Status       : NOT COMPILED.
-- Order rules  : item validation = POST-CHANGE then WHEN-VALIDATE-ITEM (Forms order);
--                save = PRE-INSERT -> INSERT -> POST-INSERT  /  PRE-UPDATE -> UPDATE -> POST-UPDATE;
--                no COMMIT here - APEX commits after the page processes.
-- =============================================================================
SET DEFINE OFF

CREATE OR REPLACE PACKAGE BODY pkg_impr1110_apx
AS
    c_mask CONSTANT VARCHAR2(10) := 'MI-MM-YYYY';   -- Hijri date mask of the form (as in Forms)

    FUNCTION v (p_item IN VARCHAR2) RETURN VARCHAR2
    IS
    BEGIN
        RETURN pkg_forms_compat.name_in('P1110_' || p_item);
    END v;

    FUNCTION n (p_item IN VARCHAR2) RETURN NUMBER
    IS
    BEGIN
        RETURN TO_NUMBER(v(p_item));
    END n;

    FUNCTION d (p_item IN VARCHAR2) RETURN DATE
    IS
    BEGIN
        RETURN TO_DATE(v(p_item), c_mask);
    END d;

    PROCEDURE s (p_item IN VARCHAR2, p_val IN VARCHAR2)
    IS
    BEGIN
        pkg_forms_compat.copy(p_val, 'P1110_' || p_item);
    END s;

    FUNCTION ai (p_name IN VARCHAR2) RETURN VARCHAR2
    IS
    BEGIN
        RETURN pkg_forms_compat.name_in('AI_' || p_name);
    END ai;

    FUNCTION answer (p_val IN VARCHAR2) RETURN PLS_INTEGER
    IS
    BEGIN
        RETURN NVL(TO_NUMBER(p_val), pkg_impr1110.c_yes);
    END answer;

    FUNCTION get_ctx RETURN pkg_impr1110.t_ctx
    IS
        c pkg_impr1110.t_ctx;
    BEGIN
        c.curr_port_cd := TO_NUMBER(ai('P_CURR_PORT_CD'));
        c.user_id      := ai('P_USER_ID');
        c.ws_id        := ai('P_WS_ID');
        c.class_cd     := TO_NUMBER(ai('P_CLASS_CD'));
        c.user_type    := TO_NUMBER(ai('P_USER_TYPE'));
        c.brkr_port_cd := TO_NUMBER(ai('P_BRKR_PORT_CD'));
        c.lic_type     := TO_NUMBER(ai('P_LIC_TYPE'));
        c.brkr_nbr     := TO_NUMBER(ai('P_BRKR_NBR'));
        c.prsnl_impr   := NVL(n('PRSNL_IMPR'), 0);      -- module parameter PRSNL_IMPR default 0
        c.letter_nbr   := v('LETTER_NBR');
        c.code         := v('CODE');
        RETURN c;
    END get_ctx;

    PROCEDURE set_ctx (p_ctx IN pkg_impr1110.t_ctx)
    IS
    BEGIN
        s('LETTER_NBR', p_ctx.letter_nbr);
        s('CODE', p_ctx.code);
    END set_ctx;

    FUNCTION get_rec RETURN pkg_impr1110.t_rec
    IS
        r pkg_impr1110.t_rec;
    BEGIN
        r.row_id            := v('ROW_ID');
        r.rec_status        := NVL(v('REC_STATUS'), CASE WHEN v('ROW_ID') IS NULL THEN 'NEW' ELSE 'QUERY' END);
        r.activity_entr     := v('ACTIVITY_ENTR');
        r.bus_id_brnch_entr := v('BUS_ID_BRNCH_ENTR');
        r.port_cd           := n('PORT_CD');           r.hq_impr_nbr       := n('HQ_IMPR_NBR');
        r.impr_nbr          := n('IMPR_NBR');          r.bus_id_status     := v('BUS_ID_STATUS');
        r.impr_type_cd      := n('IMPR_TYPE_CD');      r.bus_id_exprd_dt   := d('BUS_ID_EXPRD_DT');
        r.bus_id_type_cd    := n('BUS_ID_TYPE_CD');    r.comm_rgstrtn_type := n('COMM_RGSTRTN_TYPE');
        r.city_code_of_id   := n('CITY_CODE_OF_ID');   r.bus_id            := v('BUS_ID');
        r.bus_id_brnch      := v('BUS_ID_BRNCH');      r.ctry_cd           := n('CTRY_CD');
        r.impr_expr_type    := n('IMPR_EXPR_TYPE');    r.arbc_impr_name    := v('ARBC_IMPR_NAME');
        r.impr_name_std     := v('IMPR_NAME_STD');     r.lst_tran_dt       := TO_DATE(v('LST_TRAN_DT'), 'YYYY/MM/DD HH24:MI:SS');
        r.impd_stmt_nbr     := v('IMPD_STMT_NBR');     r.impr_data_srce    := v('IMPR_DATA_SRCE');
        r.eng_impr_name     := v('ENG_IMPR_NAME');     r.impr_cntct_name   := v('IMPR_CNTCT_NAME');
        r.impr_address      := v('IMPR_ADDRESS');      r.bus_id_issue_dt   := d('BUS_ID_ISSUE_DT');
        r.impr_nbr_parent   := n('IMPR_NBR_PARENT');   r.add_ctry_cd       := n('ADD_CTRY_CD');
        r.city_code         := n('CITY_CODE');         r.impr_pob_nbr      := v('IMPR_POB_NBR');
        r.impr_zip_cd       := v('IMPR_ZIP_CD');       r.impr_tel_nbr      := v('IMPR_TEL_NBR');
        r.impr_fax_nbr      := v('IMPR_FAX_NBR');      r.impr_telex_nbr    := v('IMPR_TELEX_NBR');
        r.email             := v('EMAIL');             r.mobile_no         := v('MOBILE_NO');
        r.bank_iban         := v('BANK_IBAN');         r.id_nbr            := v('ID_NBR');
        r.car_agent_flag    := n('CAR_AGENT_FLAG');    r.express_post      := v('EXPRESS_POST');
        r.ctry_cd_of_id     := v('CTRY_CD_OF_ID');     r.expd_stmt_nbr     := v('EXPD_STMT_NBR');
        r.wvr_entry_nbr     := v('WVR_ENTRY_NBR');     r.activity          := v('ACTIVITY');
        r.customs_entered   := v('CUSTOMS_ENTERED');   r.creation_flag     := v('CREATION_FLAG');
        r.port_name         := v('PORT_NAME');         r.sdp_port_status   := n('SDP_PORT_STATUS');
        r.suspn_status      := v('SUSPN_STATUS');      r.status_desc       := v('STATUS_DESC');
        r.impr_type_name    := v('IMPR_TYPE_NAME');    r.bus_id_type_name  := v('BUS_ID_TYPE_NAME');
        r.id_city_name      := v('ID_CITY_NAME');      r.id_mins_comm_cd   := n('ID_MINS_COMM_CD');
        r.l_ct_city_status2 := n('L_CT_CITY_STATUS2'); r.brnh_id_mins_comm_cd := n('BRNH_ID_MINS_COMM_CD');
        r.brnh_city_cd      := n('BRNH_CITY_CD');      r.brnh_city_name    := v('BRNH_CITY_NAME');
        r.crty_arbc_name    := v('CRTY_ARBC_NAME');    r.ctry_ctry_status  := n('CTRY_CTRY_STATUS');
        r.itidt_note        := v('ITIDT_NOTE');        r.status            := n('STATUS');
        r.impr_name_parent  := v('IMPR_NAME_PARENT');  r.wasl_city_name    := v('WASL_CITY_NAME');
        r.add_crty_arbc_name := v('ADD_CRTY_ARBC_NAME'); r.city_name       := v('CITY_NAME');
        r.l_ct_city_status  := n('L_CT_CITY_STATUS');  r.b_email           := v('B_EMAIL');
        r.b_mobile_no       := v('B_MOBILE_NO');       r.b_id_nbr          := v('B_ID_NBR');
        r.impr_id_type      := v('IMPR_ID_TYPE');
        RETURN r;
    END get_rec;

    PROCEDURE set_rec (p_rec IN pkg_impr1110.t_rec)
    IS
    BEGIN
        s('ROW_ID', p_rec.row_id);                 s('REC_STATUS', p_rec.rec_status);
        s('PORT_CD', p_rec.port_cd);               s('HQ_IMPR_NBR', p_rec.hq_impr_nbr);
        s('IMPR_NBR', p_rec.impr_nbr);             s('BUS_ID_STATUS', p_rec.bus_id_status);
        s('IMPR_TYPE_CD', p_rec.impr_type_cd);     s('BUS_ID_EXPRD_DT', TO_CHAR(p_rec.bus_id_exprd_dt, c_mask));
        s('BUS_ID_TYPE_CD', p_rec.bus_id_type_cd); s('COMM_RGSTRTN_TYPE', p_rec.comm_rgstrtn_type);
        s('CITY_CODE_OF_ID', p_rec.city_code_of_id); s('BUS_ID', p_rec.bus_id);
        s('BUS_ID_BRNCH', p_rec.bus_id_brnch);     s('CTRY_CD', p_rec.ctry_cd);
        s('IMPR_EXPR_TYPE', p_rec.impr_expr_type); s('ARBC_IMPR_NAME', p_rec.arbc_impr_name);
        s('IMPR_NAME_STD', p_rec.impr_name_std);   s('LST_TRAN_DT', TO_CHAR(p_rec.lst_tran_dt, 'YYYY/MM/DD HH24:MI:SS'));
        s('IMPD_STMT_NBR', p_rec.impd_stmt_nbr);   s('IMPR_DATA_SRCE', p_rec.impr_data_srce);
        s('ENG_IMPR_NAME', p_rec.eng_impr_name);   s('IMPR_CNTCT_NAME', p_rec.impr_cntct_name);
        s('IMPR_ADDRESS', p_rec.impr_address);     s('BUS_ID_ISSUE_DT', TO_CHAR(p_rec.bus_id_issue_dt, c_mask));
        s('IMPR_NBR_PARENT', p_rec.impr_nbr_parent); s('ADD_CTRY_CD', p_rec.add_ctry_cd);
        s('CITY_CODE', p_rec.city_code);           s('IMPR_POB_NBR', p_rec.impr_pob_nbr);
        s('IMPR_ZIP_CD', p_rec.impr_zip_cd);       s('IMPR_TEL_NBR', p_rec.impr_tel_nbr);
        s('IMPR_FAX_NBR', p_rec.impr_fax_nbr);     s('IMPR_TELEX_NBR', p_rec.impr_telex_nbr);
        s('EMAIL', p_rec.email);                   s('MOBILE_NO', p_rec.mobile_no);
        s('BANK_IBAN', p_rec.bank_iban);           s('ID_NBR', p_rec.id_nbr);
        s('CAR_AGENT_FLAG', p_rec.car_agent_flag); s('EXPRESS_POST', p_rec.express_post);
        s('CTRY_CD_OF_ID', p_rec.ctry_cd_of_id);   s('EXPD_STMT_NBR', p_rec.expd_stmt_nbr);
        s('WVR_ENTRY_NBR', p_rec.wvr_entry_nbr);   s('ACTIVITY', p_rec.activity);
        s('CUSTOMS_ENTERED', p_rec.customs_entered); s('CREATION_FLAG', p_rec.creation_flag);
        s('PORT_NAME', p_rec.port_name);           s('SDP_PORT_STATUS', p_rec.sdp_port_status);
        s('SUSPN_STATUS', p_rec.suspn_status);     s('STATUS_DESC', p_rec.status_desc);
        s('IMPR_TYPE_NAME', p_rec.impr_type_name); s('BUS_ID_TYPE_NAME', p_rec.bus_id_type_name);
        s('ID_CITY_NAME', p_rec.id_city_name);     s('ID_MINS_COMM_CD', p_rec.id_mins_comm_cd);
        s('L_CT_CITY_STATUS2', p_rec.l_ct_city_status2); s('BRNH_ID_MINS_COMM_CD', p_rec.brnh_id_mins_comm_cd);
        s('BRNH_CITY_CD', p_rec.brnh_city_cd);     s('BRNH_CITY_NAME', p_rec.brnh_city_name);
        s('CRTY_ARBC_NAME', p_rec.crty_arbc_name); s('CTRY_CTRY_STATUS', p_rec.ctry_ctry_status);
        s('ITIDT_NOTE', p_rec.itidt_note);         s('STATUS', p_rec.status);
        s('IMPR_NAME_PARENT', p_rec.impr_name_parent); s('WASL_CITY_NAME', p_rec.wasl_city_name);
        s('ADD_CRTY_ARBC_NAME', p_rec.add_crty_arbc_name); s('CITY_NAME', p_rec.city_name);
        s('L_CT_CITY_STATUS', p_rec.l_ct_city_status); s('B_EMAIL', p_rec.b_email);
        s('B_MOBILE_NO', p_rec.b_mobile_no);       s('B_ID_NBR', p_rec.b_id_nbr);
        s('IMPR_ID_TYPE', p_rec.impr_id_type);
    END set_rec;

    -- Writes ui_json into P1110_UI_STATE (applied by the page-load Dynamic Action)
    PROCEDURE keep_ui
    IS
    BEGIN
        s('UI_STATE', dbms_lob.substr(pkg_impr1110.ui_json, 32000, 1));
    END keep_ui;

    -- Text Forms would show for an error (business errors pass through unchanged)
    FUNCTION err_text (p_op IN VARCHAR2) RETURN VARCHAR2
    IS
    BEGIN
        IF SQLCODE BETWEEN -20999 AND -20000 THEN
            RETURN REGEXP_REPLACE(SQLERRM, '^ORA-[0-9]+: ');
        END IF;
        RETURN pkg_impr1110.importers_on_error(p_op, SQLCODE, SQLERRM);
    END err_text;

    PROCEDURE load_row (p_rec IN OUT NOCOPY pkg_impr1110.t_rec, p_where_rowid IN VARCHAR2,
                        p_port_cd IN NUMBER, p_impr_nbr IN NUMBER)
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
         WHERE (p_where_rowid IS NOT NULL AND ROWID = CHARTOROWID(p_where_rowid))
            OR (p_where_rowid IS NULL AND port_cd = p_port_cd AND impr_nbr = p_impr_nbr);
        p_rec.rec_status := 'QUERY';
    END load_row;

    PROCEDURE page_wnfi
    IS
        r pkg_impr1110.t_rec := get_rec;
    BEGIN
        pkg_impr1110.ui_reset;
        pkg_impr1110.wnfi(r, get_ctx);
        set_rec(r);
        keep_ui;
    END page_wnfi;

    PROCEDURE page_fetch
    IS
        r   pkg_impr1110.t_rec;
        c   pkg_impr1110.t_ctx := get_ctx;
        q   pkg_impr1110.t_rec := get_rec;      -- query criteria / key
    BEGIN
        pkg_impr1110.ui_reset;
        pkg_impr1110.importers_pre_qry(q, c);   -- consumes :GLOBAL.EXEC_QUERY_NOW
        IF q.row_id IS NULL AND (q.port_cd IS NULL OR q.impr_nbr IS NULL) THEN
            RETURN;
        END IF;
        load_row(r, q.row_id, q.port_cd, q.impr_nbr);
        IF c_post_chg_on_fetch THEN
            IF r.hq_impr_nbr IS NOT NULL THEN pkg_impr1110.hq_impr_nbr_post_chg; END IF;
            IF r.impr_type_cd IS NOT NULL THEN pkg_impr1110.impr_type_cd_post_chg(r); END IF;
            IF r.bus_id_type_cd IS NOT NULL THEN pkg_impr1110.bus_id_type_post_chg(r); END IF;
            IF r.bus_id IS NOT NULL THEN pkg_impr1110.bus_id_post_chg; END IF;
            IF r.bus_id_brnch IS NOT NULL THEN pkg_impr1110.bus_id_brnch_post_chg; END IF;
            IF r.impr_expr_type IS NOT NULL THEN pkg_impr1110.impr_expr_type_post_chg; END IF;
        END IF;
        pkg_impr1110.importers_post_qry(r, c);
        r.rec_status := 'QUERY';
        pkg_impr1110.importers_pre_rec(r, c);
        pkg_impr1110.importers_wnri(r, c);
        set_rec(r);
        set_ctx(c);
        keep_ui;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            apex_error.add_error(p_message => 'FRM-40350', p_display_location => apex_error.c_inline_in_notification);
    END page_fetch;

    PROCEDURE page_new_record
    IS
        r pkg_impr1110.t_rec := get_rec;
        c pkg_impr1110.t_ctx := get_ctx;
    BEGIN
        IF r.row_id IS NOT NULL THEN
            RETURN;
        END IF;
        pkg_impr1110.ui_reset;
        r.rec_status := 'NEW';
        pkg_impr1110.importers_wcr(r, c);
        pkg_impr1110.importers_pre_rec(r, c);
        pkg_impr1110.importers_wnri(r, c);
        set_rec(r);
        set_ctx(c);
        keep_ui;
    END page_new_record;

    PROCEDURE reply (p_rec IN pkg_impr1110.t_rec, p_ctx IN pkg_impr1110.t_ctx)
    IS
        v_items CLOB;
    BEGIN
        set_rec(p_rec);
        set_ctx(p_ctx);
        apex_json.initialize_clob_output;
        apex_json.open_object;
        FOR i IN (SELECT item_name
                    FROM apex_application_page_items
                   WHERE application_id = TO_NUMBER(pkg_forms_compat.name_in('APP_ID'))
                     AND page_id = c_page) LOOP
            apex_json.write(i.item_name, pkg_forms_compat.name_in(i.item_name), TRUE);
        END LOOP;
        apex_json.close_object;
        v_items := apex_json.get_clob_output;
        apex_json.free_output;
        htp.prn('{"items":');
        htp.prn(v_items);
        htp.prn(',"ui":');
        htp.prn(pkg_impr1110.ui_json);
        htp.prn('}');
    END reply;

    PROCEDURE ajax_item
    IS
        v_item VARCHAR2(61) := UPPER(apex_application.g_x01);
        v_evt  VARCHAR2(30) := UPPER(apex_application.g_x02);
        a1     PLS_INTEGER  := answer(apex_application.g_x03);
        a2     PLS_INTEGER  := answer(apex_application.g_x04);
        r      pkg_impr1110.t_rec := get_rec;
        c      pkg_impr1110.t_ctx := get_ctx;
    BEGIN
        pkg_impr1110.ui_reset;
        IF v_evt = 'VALIDATE' THEN
            -- 1) POST-CHANGE
            CASE v_item
                WHEN 'HQ_IMPR_NBR'    THEN pkg_impr1110.hq_impr_nbr_post_chg;
                WHEN 'IMPR_TYPE_CD'   THEN pkg_impr1110.impr_type_cd_post_chg(r);
                WHEN 'BUS_ID_TYPE_CD' THEN pkg_impr1110.bus_id_type_post_chg(r);
                WHEN 'BUS_ID'         THEN pkg_impr1110.bus_id_post_chg;
                WHEN 'BUS_ID_BRNCH'   THEN pkg_impr1110.bus_id_brnch_post_chg;
                WHEN 'IMPR_EXPR_TYPE' THEN pkg_impr1110.impr_expr_type_post_chg;
                WHEN 'B_EMAIL'        THEN pkg_impr1110.b_email_post_chg(r, c);
                WHEN 'B_MOBILE_NO'    THEN pkg_impr1110.b_mobile_no_post_chg(r, c);
                WHEN 'B_ID_NBR'       THEN pkg_impr1110.b_id_nbr_post_chg(r, c);
                ELSE NULL;
            END CASE;
            -- 2) WHEN-VALIDATE-ITEM
            CASE v_item
                WHEN 'PORT_CD'         THEN pkg_impr1110.port_cd_wvi(r);
                WHEN 'IMPR_NBR'        THEN pkg_impr1110.impr_nbr_wvi(r);
                WHEN 'IMPR_TYPE_CD'    THEN pkg_impr1110.impr_type_cd_wvi(r, c);
                WHEN 'BUS_ID_EXPRD_DT' THEN pkg_impr1110.bus_id_exprd_dt_wvi(r);
                WHEN 'CTRY_CD_OF_ID'   THEN pkg_impr1110.ctry_cd_of_id_wvi(r);
                WHEN 'CITY_CODE_OF_ID' THEN pkg_impr1110.city_code_of_id_wvi(r);
                WHEN 'BUS_ID'          THEN pkg_impr1110.bus_id_wvi(r, c, a1, a2);
                WHEN 'BRNH_CITY_CD'    THEN pkg_impr1110.brnh_city_cd_wvi(r);
                WHEN 'BUS_ID_BRNCH'    THEN pkg_impr1110.bus_id_brnch_wvi(r, c, a1);
                WHEN 'CTRY_CD'         THEN pkg_impr1110.ctry_cd_wvi(r);
                WHEN 'ARBC_IMPR_NAME'  THEN pkg_impr1110.arbc_impr_name_wvi(r);
                WHEN 'ENG_IMPR_NAME'   THEN pkg_impr1110.eng_impr_name_wvi(r);
                WHEN 'BUS_ID_ISSUE_DT' THEN pkg_impr1110.bus_id_issue_dt_wvi(r);
                WHEN 'IMPR_NBR_PARENT' THEN pkg_impr1110.impr_nbr_parent_wvi(r);
                WHEN 'ADD_CTRY_CD'     THEN pkg_impr1110.add_ctry_cd_wvi(r);
                WHEN 'CITY_CODE'       THEN pkg_impr1110.city_code_wvi(r);
                WHEN 'IMPR_TEL_NBR'    THEN pkg_impr1110.impr_tel_nbr_wvi(r);
                WHEN 'B_EMAIL'         THEN pkg_impr1110.b_email_wvi(r);
                WHEN 'EMAIL'           THEN pkg_impr1110.email_wvi(r);
                WHEN 'B_MOBILE_NO'     THEN pkg_impr1110.b_mobile_no_wvi(r, c);
                WHEN 'BANK_IBAN'       THEN pkg_impr1110.bank_iban_wvi(r);
                WHEN 'B_ID_NBR'        THEN pkg_impr1110.b_id_nbr_wvi(r);
                ELSE NULL;
            END CASE;
            IF r.rec_status = 'QUERY' THEN
                r.rec_status := 'CHANGED';
            ELSIF r.rec_status = 'NEW' THEN
                r.rec_status := 'INSERT';
            END IF;
        ELSIF v_evt = 'WNII' THEN
            CASE v_item
                WHEN 'IMPR_TYPE_CD'    THEN pkg_impr1110.impr_type_cd_wnii(r);
                WHEN 'CITY_CODE_OF_ID' THEN pkg_impr1110.city_code_of_id_wnii(r);
                WHEN 'BUS_ID'          THEN pkg_impr1110.bus_id_wnii(r);
                WHEN 'BRNH_CITY_CD'    THEN pkg_impr1110.brnh_city_cd_wnii;
                WHEN 'BUS_ID_BRNCH'    THEN pkg_impr1110.bus_id_brnch_wnii(r);
                WHEN 'BANK_IBAN'       THEN pkg_impr1110.bank_iban_wnii(r);
                ELSE NULL;
            END CASE;
        ELSIF v_evt = 'WLC' AND v_item = 'COMM_RGSTRTN_TYPE' THEN
            pkg_impr1110.comm_rgstrtn_wlc(r);
        ELSIF v_evt = 'LOV_RET' AND v_item = 'IMPR_TYPE_CD' THEN
            pkg_impr1110.impr_type_cd_lov_ret(r);
        ELSIF v_evt = 'KEY_NXT' AND v_item = 'ARBC_IMPR_NAME' THEN
            pkg_impr1110.arbc_impr_name_key_nxt(r);
        ELSIF v_evt = 'WNRI' THEN
            pkg_impr1110.importers_wnri(r, c, a1);
        END IF;
        reply(r, c);
    EXCEPTION
        WHEN OTHERS THEN
            set_rec(r);                       -- Forms keeps item changes made before the failure
            set_ctx(c);
            apex_json.open_object;
            apex_json.write('error', err_text(CASE WHEN r.row_id IS NULL THEN 'I' ELSE 'U' END));
            apex_json.close_object;
    END ajax_item;

    PROCEDURE ajax_confirm
    IS
        r      pkg_impr1110.t_rec := get_rec;
        c      pkg_impr1110.t_ctx := get_ctx;
        v_text VARCHAR2(4000);
        v_nbr  NUMBER;
    BEGIN
        CASE UPPER(apex_application.g_x01)
            WHEN 'WNRI' THEN
                v_text := pkg_impr1110.wnri_confirm_text(r, c);
            WHEN 'SUSP' THEN
                v_nbr := pkg_impr1110.bus_id_susp_impr(r);
                IF v_nbr <> 0 THEN
                    v_text := 'يوجد مستورد' || v_nbr
                              || ' موقوف له نفس الرقم الإستدلالي" هل تريد تعديل الرقم الاستدلالي بالرغم من ذلك ؟';
                END IF;
            WHEN 'UPD_IMPR' THEN
                v_text := pkg_impr1110.update_importer_msg(r);
            ELSE
                NULL;
        END CASE;
        apex_json.open_object;
        apex_json.write('text', v_text, TRUE);
        apex_json.close_object;
    END ajax_confirm;

    PROCEDURE ajax_fun
    IS
        v_cd VARCHAR2(30) := UPPER(apex_application.g_x01);
        r    pkg_impr1110.t_rec := get_rec;
        c    pkg_impr1110.t_ctx := get_ctx;
    BEGIN
        pkg_impr1110.ui_reset;
        IF v_cd = 'IMPR_MCI_SERVICE' THEN
            IF answer(apex_application.g_x02) = pkg_impr1110.c_yes
               AND (pkg_forms_compat.get_global('ALLOW_MCI') = '1'
                    OR pkg_forms_compat.get_global('ALLOW_MOI') = '1') THEN
                pkg_impr1110.update_importer(r);
            END IF;
        ELSIF v_cd = 'IMPR1110_MOB_RET' THEN          -- after dialog LOV_UPDATE_IMPR_MOBILE closed
            pkg_impr1110.lov_update_moblie(r);
        ELSE
            pkg_impr1110.exec_funs(r, c, v_cd);
            IF c.code IS NOT NULL THEN                -- EXEC_FUNS set :PARAMETER.CODE -> WNRI handles it
                pkg_impr1110.importers_wnri(r, c, answer(apex_application.g_x02));
            END IF;
        END IF;
        reply(r, c);
    EXCEPTION
        WHEN OTHERS THEN
            set_rec(r);
            set_ctx(c);
            apex_json.open_object;
            apex_json.write('error', err_text('U'));
            apex_json.close_object;
    END ajax_fun;

    PROCEDURE page_dml (p_request IN VARCHAR2)
    IS
        r       pkg_impr1110.t_rec := get_rec;
        c       pkg_impr1110.t_ctx := get_ctx;
        v_empty pkg_impr1110.t_rec;
        v_op    VARCHAR2(1);
    BEGIN
        pkg_impr1110.ui_reset;
        IF p_request = 'SAVE' THEN
            IF r.row_id IS NULL THEN
                IF r.rec_status = 'NEW' THEN
                    RETURN;                                -- nothing entered: Forms inserts nothing
                END IF;
                v_op := 'I';
                pkg_impr1110.importers_pre_ins(r, c);      -- Confirm (class 1 / type 3) done by DA
                pkg_impr1110.importers_ins(r);
                pkg_impr1110.importers_post_ins(r, c);
            ELSIF r.rec_status = 'CHANGED' THEN
                v_op := 'U';
                pkg_impr1110.importers_pre_upd(r, c);
                pkg_impr1110.importers_upd(r);
                pkg_impr1110.importers_post_upd(r);
            END IF;
            r.rec_status := 'QUERY';
        ELSIF p_request = 'DELETE' THEN
            v_op := 'D';
            pkg_impr1110.importers_key_delrec(r);          -- Confirm 'هل أنت متأكد من عملية الحذف' done by DA
            r := v_empty;
            r.rec_status := 'NEW';
        END IF;
        set_rec(r);
        keep_ui;
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20000, err_text(v_op));
    END page_dml;

END pkg_impr1110_apx;
/
SHOW ERRORS
