-- =============================================================================
-- Package body : pkg_impr1110
-- Source       : IMPR1110.fmb (IMPR1110_PROD_CENTRL), block IMPORTERS
-- Target       : APEX 21.2 / DB 12.1.0.2
-- Status       : NOT YET COMPILED against a real database - compile in DEV first.
-- Conventions  : STR.DispArbMsg(s,n,..) + RAISE FORM_TRIGGER_FAILURE -> ftf_msg(s,n)
--                STR.DispAlert(txt,'ERROR') + RAISE FTF               -> pkg_forms_compat.ftf(txt)
--                STR.DispAlert(txt,'INFORMATION') (no raise)          -> pkg_forms_compat.message(txt)
--                :GLOBAL.X                                            -> pkg_forms_compat.get/set_global('X')
--                INTRFACE.Make_Field_Entrable / SET_ITEM_PROPERTY      -> ui_state_json (+ DA JavaScript)
--                CONFIRM alerts                                       -> Confirm Dynamic Action on the page
--                COMMIT inside triggers                               -> removed (APEX commits the page)
--                Lines marked "TODO-VERIFY" were converted from the analysis summary and must be
--                compared with the original trigger text (analysis/IMPR1110/IMPR1110_inventory.md).
-- =============================================================================
SET DEFINE OFF

CREATE OR REPLACE PACKAGE BODY pkg_impr1110
AS
    -- ======================================================================= private helpers

    -- Source: STR.DispArbMsg(p_sys, p_nbr, ...) -> message text from the message table.
    -- TODO-VERIFY: signature of STR_DB.GetArbMsg in the DB.
    FUNCTION arb_msg (p_sys IN NUMBER, p_nbr IN NUMBER) RETURN VARCHAR2
    IS
    BEGIN
        RETURN str_db.getarbmsg(p_sys, p_nbr);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 'MSG ' || p_sys || '-' || p_nbr;
    END arb_msg;

    -- Source: ret := Str.DispArbMsg(s, n, 'ERROR'); RAISE FORM_TRIGGER_FAILURE;
    PROCEDURE ftf_msg (p_sys IN NUMBER, p_nbr IN NUMBER)
    IS
    BEGIN
        pkg_forms_compat.ftf(arb_msg(p_sys, p_nbr));
    END ftf_msg;

    -- Source: gnrl.get_customs_setting('NAME', sysobj)
    FUNCTION setting (p_name IN VARCHAR2, p_sysobj IN NUMBER) RETURN VARCHAR2
    IS
    BEGIN
        RETURN gnrl.get_customs_setting(p_name, p_sysobj);
    END setting;

    -- Source: gnrl.get_customs_setting(:PARAMETER.P_CURR_PORT_CD, 'NAME', sysobj)
    FUNCTION port_setting (p_port IN NUMBER, p_name IN VARCHAR2, p_sysobj IN NUMBER) RETURN VARCHAR2
    IS
    BEGIN
        RETURN gnrl.get_customs_setting(p_port, p_name, p_sysobj);
    END port_setting;

    FUNCTION country_name (p_ctry_cd IN NUMBER) RETURN VARCHAR2
    IS
        v_name countries.crty_arbc_name%TYPE;
    BEGIN
        SELECT crty_arbc_name INTO v_name FROM countries WHERE ctry_cd = p_ctry_cd;
        RETURN v_name;
    END country_name;

    FUNCTION is_type (p_val IN NUMBER, p_list IN VARCHAR2) RETURN BOOLEAN
    IS
    BEGIN
        RETURN INSTR(',' || p_list || ',', ',' || p_val || ',') > 0;
    END is_type;

    PROCEDURE g_set (p_name IN VARCHAR2, p_val IN VARCHAR2)
    IS
    BEGIN
        pkg_forms_compat.set_global(p_name, p_val);
    END g_set;

    FUNCTION g_get (p_name IN VARCHAR2) RETURN VARCHAR2
    IS
    BEGIN
        RETURN pkg_forms_compat.get_global(p_name);
    END g_get;

    -- Source: IF NOT ACTIVITY.ADD_ACTIVITY(9, 2, n, port||'!'||impr) THEN RAISE FTF;
    PROCEDURE add_activity (p_act IN NUMBER, p_rec IN t_rec)
    IS
    BEGIN
        IF NOT activity.add_activity(9, 2, p_act, p_rec.port_cd || '!' || p_rec.impr_nbr) THEN
            pkg_forms_compat.ftf;
        END IF;
    END add_activity;

    -- ======================================================================= context
    FUNCTION get_ctx RETURN t_ctx
    IS
        v t_ctx;
    BEGIN
        -- :PARAMETER.P_* are session-wide -> application items AI_P_* (set after login)
        v.curr_port_cd := TO_NUMBER(g_get('P_CURR_PORT_CD'));
        v.user_id      := g_get('P_USER_ID');
        v.ws_id        := g_get('P_WS_ID');
        v.class_cd     := TO_NUMBER(g_get('P_CLASS_CD'));
        v.user_type    := TO_NUMBER(g_get('P_USER_TYPE'));
        -- per-call parameters -> page items
        v.prsnl_impr   := NVL(TO_NUMBER(pkg_forms_compat.name_in('P1110_PRSNL_IMPR')), 0);
        v.letter_nbr   := pkg_forms_compat.name_in('P1110_LETTER_NBR');
        RETURN v;
    END get_ctx;

    FUNCTION fmt_hijri (p_dt IN DATE) RETURN VARCHAR2
    IS
    BEGIN
        RETURN TO_CHAR(p_dt, 'MI-MM-YYYY');
    END fmt_hijri;

    FUNCTION to_hijri (p_txt IN VARCHAR2) RETURN DATE
    IS
    BEGIN
        IF p_txt IS NULL THEN
            RETURN NULL;
        END IF;
        RETURN TO_DATE(p_txt, 'MI-MM-YYYY');
    EXCEPTION
        WHEN OTHERS THEN
            ftf_msg(1, 10);   -- invalid date
            RETURN NULL;
    END to_hijri;

    FUNCTION get_page_rec RETURN t_rec
    IS
        r t_rec;
        FUNCTION v (p_item IN VARCHAR2) RETURN VARCHAR2 IS
        BEGIN
            RETURN pkg_forms_compat.name_in('P1110_' || p_item);
        END v;
        FUNCTION n (p_item IN VARCHAR2) RETURN NUMBER IS
        BEGIN
            RETURN TO_NUMBER(v(p_item));
        END n;
    BEGIN
        r.port_cd            := n('PORT_CD');
        r.port_name          := v('PORT_NAME');
        r.hq_impr_nbr        := n('HQ_IMPR_NBR');
        r.impr_nbr           := n('IMPR_NBR');
        r.suspn_status       := v('SUSPN_STATUS');
        r.status_desc        := v('STATUS_DESC');
        r.impr_type_cd       := n('IMPR_TYPE_CD');
        r.impr_type_name     := v('IMPR_TYPE_NAME');
        r.bus_id_exprd_dt    := to_hijri(v('BUS_ID_EXPRD_DT'));
        r.bus_id_type_cd     := n('BUS_ID_TYPE_CD');
        r.bus_id_type_name   := v('BUS_ID_TYPE_NAME');
        r.comm_rgstrtn_type  := n('COMM_RGSTRTN_TYPE');
        r.ctry_cd_of_id      := n('CTRY_CD_OF_ID');
        r.city_code_of_id    := n('CITY_CODE_OF_ID');
        r.id_city_name       := v('ID_CITY_NAME');
        r.id_mins_comm_cd    := v('ID_MINS_COMM_CD');
        r.bus_id             := v('BUS_ID');
        r.brnh_city_cd       := n('BRNH_CITY_CD');
        r.brnh_city_name     := v('BRNH_CITY_NAME');
        r.bus_id_brnch       := v('BUS_ID_BRNCH');
        r.ctry_cd            := n('CTRY_CD');
        r.crty_arbc_name     := v('CRTY_ARBC_NAME');
        r.impr_expr_type     := n('IMPR_EXPR_TYPE');
        r.arbc_impr_name     := v('ARBC_IMPR_NAME');
        r.eng_impr_name      := v('ENG_IMPR_NAME');
        r.impr_cntct_name    := v('IMPR_CNTCT_NAME');
        r.impr_address       := v('IMPR_ADDRESS');
        r.bus_id_issue_dt    := to_hijri(v('BUS_ID_ISSUE_DT'));
        r.impr_nbr_parent    := n('IMPR_NBR_PARENT');
        r.impr_name_parent   := v('IMPR_NAME_PARENT');
        r.wasl_city_name     := v('WASL_CITY_NAME');
        r.add_ctry_cd        := n('ADD_CTRY_CD');
        r.add_crty_arbc_name := v('ADD_CRTY_ARBC_NAME');
        r.city_code          := n('CITY_CODE');
        r.city_name          := v('CITY_NAME');
        r.impr_pob_nbr       := v('IMPR_POB_NBR');
        r.impr_zip_cd        := v('IMPR_ZIP_CD');
        r.impr_tel_nbr       := v('IMPR_TEL_NBR');
        r.impr_fax_nbr       := v('IMPR_FAX_NBR');
        r.impr_telex_nbr     := v('IMPR_TELEX_NBR');
        r.b_email            := v('B_EMAIL');
        r.email              := v('EMAIL');
        r.b_mobile_no        := v('B_MOBILE_NO');
        r.mobile_no          := v('MOBILE_NO');
        r.b_id_nbr           := v('B_ID_NBR');
        r.id_nbr             := v('ID_NBR');
        r.bank_iban          := v('BANK_IBAN');
        r.car_agent_flag     := n('CAR_AGENT_FLAG');
        r.express_post       := n('EXPRESS_POST');
        r.impr_id_type       := v('IMPR_ID_TYPE');
        r.activity           := v('ACTIVITY');
        r.bus_id_status      := v('BUS_ID_STATUS');
        r.impr_name_std      := v('IMPR_NAME_STD');
        r.impd_stmt_nbr      := n('IMPD_STMT_NBR');
        r.impr_data_srce     := n('IMPR_DATA_SRCE');
        r.expd_stmt_nbr      := n('EXPD_STMT_NBR');
        r.wvr_entry_nbr      := n('WVR_ENTRY_NBR');
        r.customs_entered    := n('CUSTOMS_ENTERED');
        r.creation_flag      := n('CREATION_FLAG');
        RETURN r;
    END get_page_rec;

    PROCEDURE set_page_rec (p_rec IN t_rec)
    IS
        PROCEDURE s (p_item IN VARCHAR2, p_val IN VARCHAR2) IS
        BEGIN
            pkg_forms_compat.copy(p_val, 'P1110_' || p_item);
        END s;
    BEGIN
        s('PORT_CD', p_rec.port_cd);                 s('PORT_NAME', p_rec.port_name);
        s('HQ_IMPR_NBR', p_rec.hq_impr_nbr);         s('IMPR_NBR', p_rec.impr_nbr);
        s('SUSPN_STATUS', p_rec.suspn_status);       s('STATUS_DESC', p_rec.status_desc);
        s('IMPR_TYPE_CD', p_rec.impr_type_cd);       s('IMPR_TYPE_NAME', p_rec.impr_type_name);
        s('BUS_ID_EXPRD_DT', fmt_hijri(p_rec.bus_id_exprd_dt));
        s('BUS_ID_TYPE_CD', p_rec.bus_id_type_cd);   s('BUS_ID_TYPE_NAME', p_rec.bus_id_type_name);
        s('COMM_RGSTRTN_TYPE', p_rec.comm_rgstrtn_type);
        s('CTRY_CD_OF_ID', p_rec.ctry_cd_of_id);     s('CITY_CODE_OF_ID', p_rec.city_code_of_id);
        s('ID_CITY_NAME', p_rec.id_city_name);       s('ID_MINS_COMM_CD', p_rec.id_mins_comm_cd);
        s('BUS_ID', p_rec.bus_id);                   s('BRNH_CITY_CD', p_rec.brnh_city_cd);
        s('BRNH_CITY_NAME', p_rec.brnh_city_name);   s('BUS_ID_BRNCH', p_rec.bus_id_brnch);
        s('CTRY_CD', p_rec.ctry_cd);                 s('CRTY_ARBC_NAME', p_rec.crty_arbc_name);
        s('IMPR_EXPR_TYPE', p_rec.impr_expr_type);   s('ARBC_IMPR_NAME', p_rec.arbc_impr_name);
        s('ENG_IMPR_NAME', p_rec.eng_impr_name);     s('IMPR_CNTCT_NAME', p_rec.impr_cntct_name);
        s('IMPR_ADDRESS', p_rec.impr_address);
        s('BUS_ID_ISSUE_DT', fmt_hijri(p_rec.bus_id_issue_dt));
        s('IMPR_NBR_PARENT', p_rec.impr_nbr_parent); s('IMPR_NAME_PARENT', p_rec.impr_name_parent);
        s('WASL_CITY_NAME', p_rec.wasl_city_name);   s('ADD_CTRY_CD', p_rec.add_ctry_cd);
        s('ADD_CRTY_ARBC_NAME', p_rec.add_crty_arbc_name);
        s('CITY_CODE', p_rec.city_code);             s('CITY_NAME', p_rec.city_name);
        s('IMPR_POB_NBR', p_rec.impr_pob_nbr);       s('IMPR_ZIP_CD', p_rec.impr_zip_cd);
        s('IMPR_TEL_NBR', p_rec.impr_tel_nbr);       s('IMPR_FAX_NBR', p_rec.impr_fax_nbr);
        s('IMPR_TELEX_NBR', p_rec.impr_telex_nbr);
        s('B_EMAIL', p_rec.b_email);                 s('EMAIL', p_rec.email);
        s('B_MOBILE_NO', p_rec.b_mobile_no);         s('MOBILE_NO', p_rec.mobile_no);
        s('B_ID_NBR', p_rec.b_id_nbr);               s('ID_NBR', p_rec.id_nbr);
        s('BANK_IBAN', p_rec.bank_iban);             s('CAR_AGENT_FLAG', p_rec.car_agent_flag);
        s('EXPRESS_POST', p_rec.express_post);       s('IMPR_ID_TYPE', p_rec.impr_id_type);
        s('ACTIVITY', p_rec.activity);               s('BUS_ID_STATUS', p_rec.bus_id_status);
        s('IMPR_NAME_STD', p_rec.impr_name_std);
        s('IMPD_STMT_NBR', p_rec.impd_stmt_nbr);     s('IMPR_DATA_SRCE', p_rec.impr_data_srce);
        s('EXPD_STMT_NBR', p_rec.expd_stmt_nbr);     s('WVR_ENTRY_NBR', p_rec.wvr_entry_nbr);
        s('CUSTOMS_ENTERED', p_rec.customs_entered); s('CREATION_FLAG', p_rec.creation_flag);
    END set_page_rec;

    -- ======================================================================= program units

    -- Source: PU CHECK_IDNO (Saudi ID check digit) - converted 1:1
    FUNCTION check_idno (p_id_no IN VARCHAR2) RETURN BOOLEAN
    IS
        v_result     NUMBER := 0;
        v_su         NUMBER := 0;
        v_chr_result VARCHAR2(10);
    BEGIN
        IF p_id_no IS NULL OR LENGTH(p_id_no) <> 10 OR NOT is_digit(p_id_no) THEN
            RETURN FALSE;
        END IF;
        FOR i IN 1 .. 9 LOOP
            v_su := TO_NUMBER(SUBSTR(p_id_no, i, 1));
            IF MOD(i, 2) <> 0 THEN
                v_result := v_result + MOD(v_su * 2, 10);
                v_result := v_result + TRUNC((v_su * 2) / 10);
            ELSE
                v_result := v_result + v_su;
            END IF;
        END LOOP;
        v_chr_result := TO_CHAR(v_result);
        IF SUBSTR(p_id_no, 10, 1) = '0' THEN
            RETURN SUBSTR(v_chr_result, LENGTH(v_chr_result), 1) = '0';
        END IF;
        RETURN TO_CHAR(10 - TO_NUMBER(SUBSTR(v_chr_result, LENGTH(v_chr_result), 1)))
               = SUBSTR(p_id_no, 10, 1);
    END check_idno;

    -- Source: PU IS_DIGIT
    FUNCTION is_digit (p_txt IN VARCHAR2) RETURN BOOLEAN
    IS
    BEGIN
        RETURN p_txt IS NOT NULL AND TRANSLATE(p_txt, 'x0123456789', 'x') IS NULL;
    END is_digit;

    -- Source: PU CHK_IMPR_DUPL (active part only; ELSE part is commented out in Forms)
    PROCEDURE chk_impr_dupl (p_rec IN t_rec)
    IS
        v_impr_name importers.arbc_impr_name%TYPE;
        v_impr_nbr  importers.impr_nbr%TYPE;
    BEGIN
        IF p_rec.bus_id_brnch IS NOT NULL THEN
            SELECT arbc_impr_name, impr_nbr
              INTO v_impr_name, v_impr_nbr
              FROM importers
             WHERE port_cd        = p_rec.port_cd
               AND ctry_cd        = NVL(p_rec.ctry_cd, ctry_cd)
               AND bus_id_type_cd = p_rec.bus_id_type_cd
               AND bus_id         = p_rec.bus_id
               AND bus_id_brnch   = p_rec.bus_id_brnch
               AND (p_rec.impr_nbr IS NULL OR impr_nbr <> p_rec.impr_nbr)
               AND ROWNUM = 1;
            pkg_forms_compat.ftf(' لايمكن الإدخال، يوجد مستورد مدخل بنفس نوع المستورد ونفس الرقم الإستدلالي الرئيسي والفرعي ورقمه:  '
                                 || v_impr_nbr || ' اسمه ' || v_impr_name);
        END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            NULL;
    END chk_impr_dupl;

    -- Source: PU CHK_DUPL_IMP_BRKR
    PROCEDURE chk_dupl_imp_brkr (p_rec IN t_rec, p_ctx IN t_ctx)
    IS
        v_var_value VARCHAR2(2) := '0';
        v_chk       NUMBER;
        v_msg       VARCHAR2(500);
    BEGIN
        BEGIN
            SELECT var_value
              INTO v_var_value
              FROM sc_port_setting
             WHERE sysobj_id = 9
               AND var_name  = 'CHK_DPLCATE_IMP_BRKR'
               AND port_cd   = p_ctx.curr_port_cd;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_var_value := '0';
        END;
        IF v_var_value = '1' AND p_rec.impr_type_cd IN (1, 4) THEN
            v_chk := impr.check_duplicate_imp_brkr(p_rec.port_cd, 1, p_rec.impr_type_cd, p_rec.bus_id,
                                                   p_rec.comm_rgstrtn_type, p_rec.bus_id,
                                                   p_rec.bus_id_brnch, v_msg);
            IF v_chk = 1 THEN
                pkg_forms_compat.ftf(v_msg);
            END IF;
        END IF;
    END chk_dupl_imp_brkr;

    -- Source: PU CHK_PERSONAL(:impr_type_cd, :hq_impr_nbr) - a personal importer (type 4)
    -- cannot become non-personal and vice versa.
    -- TODO-VERIFY: message text against original PU CHK_PERSONAL.
    PROCEDURE chk_personal (p_rec IN t_rec)
    IS
        v_old_type importers.impr_type_cd%TYPE;
    BEGIN
        SELECT impr_type_cd
          INTO v_old_type
          FROM importers
         WHERE port_cd  = p_rec.port_cd
           AND impr_nbr = p_rec.impr_nbr;
        IF (v_old_type = 4 AND p_rec.impr_type_cd <> 4)
           OR (v_old_type <> 4 AND p_rec.impr_type_cd = 4) THEN
            pkg_forms_compat.ftf('لا يمكن التعديل  للمستورد الشخصي الا من خلال الدعم الفني التطبيقات');
        END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            NULL;
    END chk_personal;

    -- Source: PU INSERT_AUDIT_RECORD(V_ACT_TYPE) - 'I' / 'U' row in IMPR_UPDTS
    PROCEDURE insert_audit_record (p_rec IN t_rec, p_ctx IN t_ctx, p_act_type IN VARCHAR2)
    IS
        v_impr_master_nbr importers.impr_master_nbr%TYPE;
        v_act_status      importers.act_status%TYPE;
    BEGIN
        IF p_rec.impr_nbr IS NULL THEN
            ftf_msg(9, 140);
        END IF;
        BEGIN
            SELECT impr_master_nbr, act_status
              INTO v_impr_master_nbr, v_act_status
              FROM importers
             WHERE port_cd        = p_ctx.curr_port_cd
               AND bus_id_type_cd = p_rec.bus_id_type_cd
               AND bus_id         = p_rec.bus_id
               AND bus_id_brnch   = p_rec.bus_id_brnch
               AND impr_type_cd   = p_rec.impr_type_cd
               AND ctry_cd        = p_rec.ctry_cd
               AND ROWNUM = 1;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_impr_master_nbr := NULL;
                v_act_status      := NULL;
        END;
        INSERT INTO impr_updts (
            port_cd, impr_nbr, hq_impr_nbr, impr_type_cd, bus_id_type_cd, bus_id, bus_id_brnch,
            bus_id_exprd_dt, ctry_cd_of_id, city_code_of_id, impr_expr_type, arbc_impr_name,
            eng_impr_name, impr_name_std, impr_nbr_parent, impr_cntct_name, impr_tel_nbr,
            impr_pob_nbr, impr_zip_cd, impr_fax_nbr, impr_telex_nbr, email, ctry_cd, add_ctry_cd,
            city_code, lst_tran_dt, impd_stmt_nbr, impr_data_srce, act_dt, act_type, usr_id,
            comm_rgstrtn_type, car_agent_flag, mobile_no, bank_iban, express_post, id_nbr,
            bus_id_issue_dt, bus_id_status, creation_flag, impr_address, impr_master_nbr, act_status)
        VALUES (
            p_rec.port_cd, p_rec.impr_nbr, p_rec.hq_impr_nbr, p_rec.impr_type_cd, p_rec.bus_id_type_cd,
            p_rec.bus_id, p_rec.bus_id_brnch, p_rec.bus_id_exprd_dt, p_rec.ctry_cd_of_id,
            p_rec.city_code_of_id, p_rec.impr_expr_type, p_rec.arbc_impr_name, p_rec.eng_impr_name,
            p_rec.impr_name_std, p_rec.impr_nbr_parent, p_rec.impr_cntct_name, p_rec.impr_tel_nbr,
            p_rec.impr_pob_nbr, p_rec.impr_zip_cd, p_rec.impr_fax_nbr, p_rec.impr_telex_nbr,
            p_rec.email, p_rec.ctry_cd, p_rec.add_ctry_cd, p_rec.city_code, p_rec.lst_tran_dt,
            p_rec.impd_stmt_nbr, p_rec.impr_data_srce, SYSDATE, p_act_type, p_ctx.user_id,
            p_rec.comm_rgstrtn_type, p_rec.car_agent_flag, p_rec.mobile_no, p_rec.bank_iban,
            p_rec.express_post, p_rec.id_nbr, p_rec.bus_id_issue_dt, p_rec.bus_id_status,
            p_rec.creation_flag, p_rec.impr_address, v_impr_master_nbr, v_act_status);
    END insert_audit_record;

    -- Source: PU UPDATE_BASIC_IMPORTER (STANDARD.COMMIT removed - APEX commits the page)
    PROCEDURE update_basic_importer (p_rec IN t_rec)
    IS
        v_cnt NUMBER;
    BEGIN
        SELECT COUNT(*)
          INTO v_cnt
          FROM importer_basic_data
         WHERE bus_id         = p_rec.bus_id
           AND bus_id_brnch   = NVL(p_rec.bus_id_brnch, '0')
           AND impr_type_cd   = p_rec.impr_type_cd
           AND bus_id_type_cd = p_rec.bus_id_type_cd;
        IF v_cnt = 0 THEN
            INSERT INTO importer_basic_data
                (bus_id, bus_id_brnch, impr_type_cd, bus_id_type_cd, mobile_no, email, id_nbr, hq_impr_nbr)
            VALUES
                (p_rec.bus_id, NVL(p_rec.bus_id_brnch, '0'), p_rec.impr_type_cd, p_rec.bus_id_type_cd,
                 p_rec.b_mobile_no, p_rec.b_email, p_rec.b_id_nbr, p_rec.hq_impr_nbr);
        ELSE
            UPDATE importer_basic_data
               SET mobile_no   = NVL(p_rec.b_mobile_no, mobile_no),
                   email       = NVL(p_rec.b_email, email),
                   id_nbr      = NVL(p_rec.b_id_nbr, id_nbr),
                   hq_impr_nbr = NVL(p_rec.hq_impr_nbr, hq_impr_nbr)
             WHERE bus_id               = p_rec.bus_id
               AND NVL(bus_id_brnch, '0') = NVL(p_rec.bus_id_brnch, '0')
               AND impr_type_cd         = p_rec.impr_type_cd
               AND bus_id_type_cd       = p_rec.bus_id_type_cd;
        END IF;
    END update_basic_importer;

    -- Source: identical block in IMPORTERS.PRE-INSERT and IMPORTERS.PRE-UPDATE
    --         (commercial register check -> CUSTOMS_ENTERED)
    PROCEDURE chk_comm_rgstr (p_rec IN OUT NOCOPY t_rec, p_ctx IN t_ctx)
    IS
        v_cnt NUMBER;
        PROCEDURE not_found IS
        BEGIN
            -- NOT CHECK IN COMM TABLE IF FUNCTION VALUE <> 0
            IF NVL(port_setting(p_ctx.curr_port_cd, 'COMM_TABLE_UNCHECK', 9), '0') = '0' THEN
                ftf_msg(9, 190);
            ELSE
                p_rec.customs_entered := 1;
            END IF;
        END not_found;
    BEGIN
        IF p_rec.bus_id_type_cd = 2 AND p_rec.impr_type_cd <> 12 THEN
            IF p_rec.comm_rgstrtn_type = 1 THEN
                IF p_rec.bus_id IS NULL THEN
                    ftf_msg(9, 250);
                END IF;
                SELECT COUNT(bus_id) INTO v_cnt
                  FROM comm_impr_rgstr
                 WHERE bus_id = p_rec.bus_id AND brnchreg = 0;
                IF v_cnt = 0 THEN not_found; ELSE p_rec.customs_entered := 0; END IF;
            ELSIF p_rec.comm_rgstrtn_type = 2 THEN
                IF p_rec.bus_id IS NULL OR p_rec.bus_id_brnch IS NULL THEN
                    ftf_msg(9, 230);
                END IF;
                SELECT COUNT(bus_id) INTO v_cnt
                  FROM comm_impr_rgstr
                 WHERE bus_id = p_rec.bus_id AND brnch_bus_id = p_rec.bus_id_brnch;
                IF v_cnt = 0 THEN not_found; ELSE p_rec.customs_entered := 0; END IF;
            ELSE
                ftf_msg(9, 240);
            END IF;
        END IF;
    END chk_comm_rgstr;

    -- ======================================================================= form triggers

    -- Source: FORM.WHEN-NEW-FORM-INSTANCE (business part; TMPLT/NIB toolbar code dropped)
    PROCEDURE wnfi (p_ctx IN t_ctx)
    IS
        v_mci VARCHAR2(10);
        v_moi VARCHAR2(10);
    BEGIN
        BEGIN
            SELECT var_value INTO v_mci FROM sc_port_setting
             WHERE sysobj_id = 24 AND var_name = 'ALLOW_MCI' AND port_cd = p_ctx.curr_port_cd;
            SELECT var_value INTO v_moi FROM sc_port_setting
             WHERE sysobj_id = 24 AND var_name = 'ALLOW_MOI' AND port_cd = p_ctx.curr_port_cd;
        EXCEPTION
            WHEN OTHERS THEN NULL;
        END;
        g_set('ALLOW_MCI', NVL(v_mci, '0'));
        g_set('ALLOW_MOI', NVL(v_moi, '0'));
        g_set('FLAGUPDATE', '0');
        g_set('CHK_DUP_BUSID', '0');
    END wnfi;

    -- Source: IMPORTERS.WHEN-CREATE-RECORD (+ CTRY defaults of WNRI)
    PROCEDURE importers_wcr (p_rec IN OUT NOCOPY t_rec, p_ctx IN t_ctx)
    IS
    BEGIN
        p_rec.port_cd := p_ctx.curr_port_cd;
        SELECT port_name INTO p_rec.port_name FROM sd_ports WHERE port_cd = p_rec.port_cd;
        IF p_ctx.prsnl_impr = 1 THEN
            p_rec.impr_type_cd := 4;
            SELECT impr_type_name INTO p_rec.impr_type_name
              FROM impr_types WHERE impr_type_cd = 4;
        END IF;
        -- item defaults from the Forms item properties
        p_rec.impr_expr_type := NVL(p_rec.impr_expr_type, 2);
        p_rec.ctry_cd_of_id  := NVL(p_rec.ctry_cd_of_id, 100);
        p_rec.add_ctry_cd    := 100;                       -- WNRI: :ADD_CTRY_CD := 100
        p_rec.add_crty_arbc_name := country_name(100);
        p_rec.car_agent_flag := NVL(p_rec.car_agent_flag, 0);
        p_rec.creation_flag  := NVL(p_rec.creation_flag, 1);
        p_rec.bank_iban      := NVL(p_rec.bank_iban, 'SA');
        -- WNFI: broker (class 1 / user type 3)
        IF p_ctx.class_cd = 1 AND p_ctx.user_type = 3 THEN
            p_rec.impr_expr_type := 1;
            p_rec.express_post   := 2;
        END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            ftf_msg(18, 15);
    END importers_wcr;

    -- Source: IMPORTERS.PRE-QUERY  :IMPR_NAME_STD := STR.StrFormat(:ARBC_IMPR_NAME, TRUE)
    -- Used in the search: WHERE impr_name_std = pkg_impr1110.impr_name_std_qry(:P1110_SEARCH_NAME)
    FUNCTION impr_name_std_qry (p_arbc_name IN VARCHAR2) RETURN VARCHAR2
    IS
    BEGIN
        RETURN str_db.strformat(p_arbc_name);   -- TODO-VERIFY: STR_DB.strformat signature
    END impr_name_std_qry;

    -- Source: IMPORTERS.POST-QUERY (suspension status, B_ copies, status, privileged id type,
    --         branch city, lookup names, WASL city). Enable/disable rules -> ui_state_json.
    PROCEDURE importers_post_qry (p_rec IN OUT NOCOPY t_rec, p_ctx IN t_ctx)
    IS
        v_count  NUMBER := 0;
        v_xdt    DATE;
        v_exp    DATE;
        v_rsn    VARCHAR2(2000);
    BEGIN
        g_set('OLD_IMPR_TYPE_CD', p_rec.impr_type_cd);
        g_set('OLD_PORT_CD', p_rec.port_cd);

        IF p_rec.impr_nbr IS NOT NULL THEN
            BEGIN
                v_xdt := hijdate_db.cur_hij_date;
                SELECT COUNT(*) INTO v_count
                  FROM impr_suspns is_1
                 WHERE is_1.port_cd  = p_rec.port_cd
                   AND is_1.impr_nbr = p_rec.impr_nbr
                   AND TO_CHAR(is_1.suspn_strt_dt, 'YYYY-MM-MI') <= TO_CHAR(v_xdt, 'YYYY-MM-MI')
                   AND TO_CHAR(is_1.suspn_end_dt,  'YYYY-MM-MI') >= TO_CHAR(v_xdt, 'YYYY-MM-MI')
                   AND is_1.suspn_rlse_dt IS NULL;
                p_rec.suspn_status := CASE WHEN v_count >= 1 THEN 'موقوف' ELSE 'غير موقوف' END;

                IF v_count = 0 THEN
                    SELECT COUNT(*) INTO v_count
                      FROM impr_duty_diff_blks
                     WHERE hq_impr_nbr = p_rec.hq_impr_nbr AND blk_rls_dt IS NULL;
                    IF v_count > 0 THEN
                        SELECT COUNT(*) INTO v_count
                          FROM (SELECT 1
                                  FROM duty_diff_blk_exp_dtls d1, stats_dcltns d2, importers d3
                                 WHERE d1.stats_isn IS NOT NULL
                                   AND d1.dcltn_stat_port_cd = d2.port_cd
                                   AND d1.stats_isn = d2.stats_isn
                                   AND d2.port_cd = d3.port_cd
                                   AND d2.impr_expr_nbr = d3.impr_nbr
                                   AND d3.hq_impr_nbr = p_rec.hq_impr_nbr
                                   AND d2.stats_status NOT IN (7, 8, 10)
                                UNION ALL
                                SELECT 1
                                  FROM duty_diff_blk_exp_dtls d1, declarations d2, importers d3
                                 WHERE d1.dcltn_isn IS NOT NULL
                                   AND d1.dcltn_stat_port_cd = d2.port_cd
                                   AND d1.dcltn_isn = d2.dcltn_isn
                                   AND d2.port_cd = d3.port_cd
                                   AND d2.impr_nbr = d3.impr_nbr
                                   AND d3.hq_impr_nbr = p_rec.hq_impr_nbr
                                   AND d2.dcltn_sta_cd <> 9
                                UNION ALL
                                SELECT 1
                                  FROM duty_diff_blk_exp_dtls d1
                                 WHERE d1.from_date IS NOT NULL
                                   AND d1.hq_impr_nbr = p_rec.hq_impr_nbr
                                   AND hijdate_db.cur_hij_date BETWEEN d1.from_date AND d1.to_date);
                        -- CRQ24602 (Yasser Mahmoud 24-01-2022)
                        IF NVL(setting('CRQ24602_RUN', 21), '0') = '0' THEN
                            p_rec.suspn_status := CASE WHEN v_count = 0 THEN 'موقوف(تدقيق عام)'
                                                       ELSE 'موقوف(تدقيق)له استثناء' END;
                        ELSIF NVL(setting('CRQ24602_RUN', 21), '0') = '1' THEN
                            p_rec.suspn_status := NULL;
                        END IF;
                    END IF;
                END IF;

                IF v_count = 0 THEN
                    BEGIN
                        SELECT suspn_rsn_text INTO v_rsn
                          FROM impr_cntrl_suspns
                         WHERE hq_impr_nbr = p_rec.hq_impr_nbr
                           AND TO_CHAR(suspn_strt_dt, 'YYYY-MM-MI') <= TO_CHAR(v_xdt, 'YYYY-MM-MI')
                           AND TO_CHAR(suspn_end_dt,  'YYYY-MM-MI') >= TO_CHAR(v_xdt, 'YYYY-MM-MI')
                           AND suspn_rlse_dt IS NULL;
                        p_rec.suspn_status := 'إيقاف مركزي من قبل المصلحة - إدارة القيود بسبب ' || v_rsn;
                    EXCEPTION
                        WHEN NO_DATA_FOUND THEN NULL;
                    END;
                END IF;
            EXCEPTION
                WHEN OTHERS THEN NULL;   -- as in Forms
            END;
        END IF;

        p_rec.b_mobile_no := p_rec.mobile_no;
        p_rec.b_id_nbr    := p_rec.id_nbr;
        p_rec.b_email     := p_rec.email;

        -- branch city from the first 4 digits of BUS_ID_BRNCH
        IF p_rec.bus_id_type_cd = 2 AND p_rec.impr_type_cd <> 12 AND p_rec.bus_id_brnch IS NOT NULL THEN
            BEGIN
                SELECT city_cd, city_arb_name
                  INTO p_rec.brnh_city_cd, p_rec.brnh_city_name
                  FROM cities
                 WHERE ctry_cd = 100 AND mins_comm_cd = SUBSTR(p_rec.bus_id_brnch, 1, 4);
            EXCEPTION
                WHEN OTHERS THEN NULL;
            END;
        END IF;

        BEGIN
            SELECT status_desc INTO p_rec.status_desc
              FROM mci_bus_id_status WHERE bus_id_status LIKE p_rec.bus_id_status;
        EXCEPTION
            WHEN OTHERS THEN NULL;
        END;

        -- CR-6410 (Mahmoud Ali Issa)
        SELECT MAX(expiry_date) INTO v_exp
          FROM privileged_importers
         WHERE impr_privilege_type = 3 AND rec_status = 1 AND impr_nbr = p_rec.impr_nbr;
        IF v_exp IS NOT NULL THEN
            IF v_exp < hijdate_db.cur_hij_date THEN
                p_rec.impr_id_type := 'اقامة عادية';
            ELSE
                p_rec.impr_id_type := 'اقامة مميزة محددة المدة تنتهي بتاريخ ' || TO_CHAR(v_exp, 'MI-MM-YYYY');
            END IF;
        ELSE
            SELECT CASE WHEN COUNT(*) > 0 THEN 'اقامة مميزة دائمة ' ELSE 'عادية' END
              INTO p_rec.impr_id_type
              FROM privileged_importers
             WHERE impr_privilege_type = 3 AND rec_status = 1 AND impr_nbr = p_rec.impr_nbr;
        END IF;

        -- CGFK$QRY_LOOKUP_DATA (lookup names)
        BEGIN
            SELECT port_name INTO p_rec.port_name FROM sd_ports WHERE port_cd = p_rec.port_cd;
        EXCEPTION WHEN NO_DATA_FOUND THEN NULL;
        END;
        BEGIN
            SELECT t.impr_type_name, b.bus_id_type_name
              INTO p_rec.impr_type_name, p_rec.bus_id_type_name
              FROM impr_type_id_types it, impr_types t, bus_id_types b
             WHERE it.impr_type_cd   = p_rec.impr_type_cd
               AND it.bus_id_type_cd = p_rec.bus_id_type_cd
               AND t.impr_type_cd    = it.impr_type_cd
               AND b.bus_id_type_cd  = it.bus_id_type_cd;
        EXCEPTION WHEN NO_DATA_FOUND THEN NULL;
        END;
        BEGIN
            p_rec.crty_arbc_name := country_name(p_rec.ctry_cd);
        EXCEPTION WHEN NO_DATA_FOUND THEN NULL;
        END;
        BEGIN
            SELECT mins_comm_cd, city_arb_name INTO p_rec.id_mins_comm_cd, p_rec.id_city_name
              FROM cities WHERE ctry_cd = p_rec.ctry_cd_of_id AND city_cd = p_rec.city_code_of_id;
        EXCEPTION WHEN NO_DATA_FOUND THEN NULL;
        END;
        BEGIN
            p_rec.add_crty_arbc_name := country_name(p_rec.add_ctry_cd);
            SELECT city_arb_name INTO p_rec.city_name
              FROM cities WHERE ctry_cd = p_rec.add_ctry_cd AND city_cd = p_rec.city_code;
        EXCEPTION WHEN NO_DATA_FOUND THEN NULL;
        END;
        -- PRE-RECORD: parent importer name
        IF p_rec.impr_nbr_parent IS NOT NULL THEN
            BEGIN
                SELECT arbc_impr_name INTO p_rec.impr_name_parent
                  FROM importers
                 WHERE impr_nbr = p_rec.impr_nbr_parent AND port_cd = p_ctx.curr_port_cd AND ROWNUM = 1;
            EXCEPTION WHEN NO_DATA_FOUND THEN NULL;
            END;
        END IF;

        -- CR-6730 (WASL city name)
        IF NVL(port_setting(p_ctx.curr_port_cd, 'CR-6730', 9), '0') = '1' THEN
            BEGIN
                SELECT wasl_city_name INTO p_rec.wasl_city_name
                  FROM impr_common_data
                 WHERE impr_type_cd   = p_rec.impr_type_cd
                   AND bus_id_type_cd = p_rec.bus_id_type_cd
                   AND bus_id         = p_rec.bus_id
                   AND bus_id_brnch   = p_rec.bus_id_brnch
                   AND ctry_cd        = p_rec.ctry_cd;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN p_rec.wasl_city_name := NULL;
            END;
        ELSE
            p_rec.wasl_city_name := NULL;
        END IF;
    END importers_post_qry;

    -- ======================================================================= WHEN-VALIDATE-ITEM

    -- Source: IMPORTERS.IMPR_NBR.WHEN-VALIDATE-ITEM (exists -> query it; else 9-150)
    PROCEDURE impr_nbr_wvi (p_rec IN OUT NOCOPY t_rec)
    IS
        v_cnt NUMBER;
    BEGIN
        IF p_rec.impr_nbr IS NOT NULL THEN
            SELECT COUNT(*) INTO v_cnt FROM importers
             WHERE port_cd = p_rec.port_cd AND impr_nbr = p_rec.impr_nbr;
            IF v_cnt = 0 THEN
                ftf_msg(9, 150);
            END IF;
        END IF;
    END impr_nbr_wvi;

    -- Source: IMPORTERS.IMPR_TYPE_CD.WHEN-VALIDATE-ITEM + POST-CHANGE
    PROCEDURE impr_type_cd_wvi (p_rec IN OUT NOCOPY t_rec, p_ctx IN t_ctx)
    IS
        v_cnt     NUMBER;
        v_seq     VARCHAR2(30);
    BEGIN
        IF p_rec.impr_type_cd IS NULL THEN
            RETURN;
        END IF;
        -- only types 4/9 for new importers or numbers above CREATE_IMPR_NBR
        IF NVL(p_rec.impr_type_cd, 0) NOT IN (4, 9)
           AND (p_rec.impr_nbr IS NULL
                OR p_rec.impr_nbr > TO_NUMBER(NVL(setting('CREATE_IMPR_NBR', 9), 5000000))) THEN
            ftf_msg(9, 332);
        END IF;
        IF NVL(setting('STOP_IMPR_CR_TYPE', 9), '0') = '1' THEN
            SELECT COUNT(*) INTO v_cnt FROM impr_type_id_types
             WHERE impr_type_cd = p_rec.impr_type_cd AND bus_id_type_cd = 2 AND status = 1;
            IF v_cnt > 0 THEN
                ftf_msg(9, 331);
            END IF;
        END IF;
        -- :GLOBAL.VALID = 0 branch: auto-fill BUS_ID_TYPE when exactly one active combination
        SELECT COUNT(*) INTO v_cnt FROM impr_type_id_types
         WHERE impr_type_cd = p_rec.impr_type_cd AND status = 1;
        IF v_cnt = 1 THEN
            SELECT it.bus_id_type_cd, idt.bus_id_type_name
              INTO p_rec.bus_id_type_cd, p_rec.bus_id_type_name
              FROM impr_type_id_types it, bus_id_types idt
             WHERE it.impr_type_cd = p_rec.impr_type_cd AND it.status = 1
               AND it.bus_id_type_cd = idt.bus_id_type_cd;
        ELSIF v_cnt = 0 THEN
            ftf_msg(2, 170);
        END IF;
        -- v_cnt > 1: Forms opened the LOV (DO_KEY LIST_VALUES) -> user picks BUS_ID_TYPE_CD (cascading LOV)

        SELECT impr_type_name INTO p_rec.impr_type_name
          FROM impr_types WHERE impr_type_cd = p_rec.impr_type_cd;

        IF NVL(g_get('FUNS_IMP'), '0') = '0' THEN
            IF is_type(p_rec.impr_type_cd, '1,2,5,8,11') THEN
                p_rec.ctry_cd := 100; p_rec.add_ctry_cd := 100;
            ELSIF p_rec.impr_type_cd = 4 AND p_rec.bus_id_type_cd = 5 THEN
                p_rec.ctry_cd := 100; p_rec.add_ctry_cd := 100;
            ELSIF p_rec.impr_type_cd = 9 THEN
                p_rec.ctry_cd := 100; p_rec.add_ctry_cd := 100;
                p_rec.bus_id_type_cd := NVL(p_rec.bus_id_type_cd, 6);
                IF p_rec.bus_id_type_cd = 6 THEN
                    v_seq := LPAD(gnrl.get_sequence_value(p_ctx.curr_port_cd, 'KING_IMPR_SEQ'), 6, '0');
                    p_rec.bus_id := 'ملكى' || v_seq;
                END IF;
            ELSIF p_rec.impr_type_cd = 12 AND p_rec.ctry_cd IS NOT NULL THEN
                SELECT COUNT(*) INTO v_cnt FROM ctry_group_details
                 WHERE ctry_cd = p_rec.ctry_cd AND ctry_grp_stat = 1 AND ctry_grp_nbr = 1;
                IF v_cnt = 0 THEN
                    pkg_forms_compat.ftf('لابد أن تكون دولة المستورد الخليجي تابعة لدول مجلس التعاون');
                END IF;
            ELSIF is_type(p_rec.impr_type_cd, '13,14,16,17,18,20') THEN
                p_rec.bus_id := NVL(TO_CHAR(gnrl.get_sequence_value(p_ctx.curr_port_cd, 'IMPORTERS_SEQ')), '1');
                p_rec.ctry_cd := 100; p_rec.add_ctry_cd := 100;
            END IF;
            IF p_rec.ctry_cd IS NOT NULL THEN
                p_rec.crty_arbc_name := country_name(p_rec.ctry_cd);
            END IF;
            IF p_rec.add_ctry_cd IS NOT NULL THEN
                p_rec.add_crty_arbc_name := country_name(p_rec.add_ctry_cd);
            END IF;
        END IF;
        g_set('FLAGUPDATE', '1');   -- POST-CHANGE
    END impr_type_cd_wvi;

    -- Source: IMPORTERS.BUS_ID_EXPRD_DT.WHEN-VALIDATE-ITEM (valid Hijri, not before today -> 1-10)
    PROCEDURE bus_id_exprd_dt_wvi (p_rec IN OUT NOCOPY t_rec)
    IS
    BEGIN
        IF p_rec.bus_id_exprd_dt IS NOT NULL
           AND TO_CHAR(p_rec.bus_id_exprd_dt, 'YYYY-MM-MI') < TO_CHAR(hijdate_db.cur_hij_date, 'YYYY-MM-MI') THEN
            ftf_msg(1, 10);
        END IF;
    END bus_id_exprd_dt_wvi;

    -- Source: IMPORTERS.COMM_RGSTRTN_TYPE.WHEN-LIST-CHANGED
    PROCEDURE comm_rgstrtn_wlc (p_rec IN OUT NOCOPY t_rec)
    IS
    BEGIN
        IF p_rec.comm_rgstrtn_type = 1 THEN
            p_rec.bus_id_brnch   := NULL;
            p_rec.brnh_city_cd   := NULL;
            p_rec.brnh_city_name := NULL;
        END IF;
        -- = 2: BRNH_CITY_CD becomes required (ui_state_json)
    END comm_rgstrtn_wlc;

    -- Source: IMPORTERS.CITY_CODE_OF_ID.WHEN-VALIDATE-ITEM (city must exist for CTRY_CD_OF_ID)
    PROCEDURE city_code_of_id_wvi (p_rec IN OUT NOCOPY t_rec)
    IS
    BEGIN
        IF p_rec.city_code_of_id IS NULL THEN
            p_rec.id_city_name := NULL; p_rec.id_mins_comm_cd := NULL;
            RETURN;
        END IF;
        SELECT mins_comm_cd, city_arb_name
          INTO p_rec.id_mins_comm_cd, p_rec.id_city_name
          FROM cities
         WHERE ctry_cd = NVL(p_rec.ctry_cd_of_id, 100) AND city_cd = p_rec.city_code_of_id AND city_status = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            pkg_forms_compat.ftf('خطأ في رمز مدينة مصدر الرقم الإستدلالي');
    END city_code_of_id_wvi;

    -- Source: IMPORTERS.BUS_ID.WHEN-VALIDATE-ITEM
    -- TODO-VERIFY: messages without a code were rebuilt from the analysis summary.
    PROCEDURE bus_id_wvi (p_rec IN OUT NOCOPY t_rec, p_ctx IN t_ctx)
    IS
        v_cnt       NUMBER;
        v_susp      NUMBER;
        v_name      comm_impr_rgstr.arbc_impr_name%TYPE;
    BEGIN
        IF p_rec.bus_id IS NULL THEN
            RETURN;
        END IF;
        IF is_type(p_rec.impr_type_cd, '1,3,5,6,8,19') AND LENGTH(p_rec.bus_id) <> 10 THEN
            pkg_forms_compat.ftf('الرقم الإستدلالي يجب أن يكون 10 خانات');            -- TODO-VERIFY
        END IF;
        IF p_rec.impr_type_cd = 4 AND p_rec.bus_id_type_cd IN (3, 5) THEN
            IF NOT check_idno(p_rec.bus_id) THEN
                pkg_forms_compat.ftf('رقم الهوية / الإقامة غير صحيح');                -- TODO-VERIFY
            END IF;
        END IF;
        IF p_rec.bus_id_type_cd = 2 AND p_rec.impr_type_cd <> 12 THEN
            IF NOT is_digit(p_rec.bus_id) OR NOT (LENGTH(p_rec.bus_id) <= 6 OR LENGTH(p_rec.bus_id) = 10) THEN
                pkg_forms_compat.ftf('السجل التجاري أرقام فقط بطول 6 أو 10');           -- TODO-VERIFY
            END IF;
            IF LENGTH(p_rec.bus_id) <= 6 THEN
                -- Forms asked 9-120 (confirm) before prefixing -> Confirm DA on the page
                p_rec.bus_id := LPAD(p_rec.id_mins_comm_cd, 4, '0') || LPAD(p_rec.bus_id, 6, '0');
            ELSIF SUBSTR(p_rec.bus_id, 1, 4) <> LPAD(p_rec.id_mins_comm_cd, 4, '0') THEN
                ftf_msg(9, 130);
            END IF;
        END IF;
        -- duplicate check (same port / country / bus type / bus id, no branch, not self)
        SELECT COUNT(*),
               SUM(CASE WHEN EXISTS (SELECT 1 FROM impr_suspns s
                                      WHERE s.port_cd = i.port_cd AND s.impr_nbr = i.impr_nbr
                                        AND s.suspn_rlse_dt IS NULL) THEN 1 ELSE 0 END)
          INTO v_cnt, v_susp
          FROM importers i
         WHERE i.port_cd        = p_rec.port_cd
           AND i.ctry_cd        = NVL(p_rec.ctry_cd, i.ctry_cd)
           AND i.bus_id_type_cd = p_rec.bus_id_type_cd
           AND i.bus_id         = p_rec.bus_id
           AND i.bus_id_brnch IS NULL
           AND (p_rec.impr_nbr IS NULL OR i.impr_nbr <> p_rec.impr_nbr);
        IF v_cnt > NVL(v_susp, 0) THEN
            pkg_forms_compat.ftf('لا يمكن تكرار الرقم الإستدلالي - الرقم الإستدلالي مستخدم لمستورد آخر');
        ELSIF v_cnt > 0 THEN
            g_set('CHK_DUP_BUSID', '1');   -- suspended duplicate: warning + ADD_ACTIVITY 3 on insert
            pkg_forms_compat.message('تنبيه: الرقم الإستدلالي مستخدم لمستورد موقوف');
        END IF;
        -- commercial register lookup
        IF p_rec.bus_id_type_cd = 2 AND p_rec.impr_type_cd <> 12 AND p_rec.comm_rgstrtn_type = 1 THEN
            SELECT COUNT(*) INTO v_cnt FROM comm_impr_rgstr WHERE bus_id = p_rec.bus_id AND brnchreg = 0;
            IF v_cnt > 1 THEN
                ftf_msg(9, 290);
            ELSIF v_cnt = 1 THEN
                SELECT arbc_impr_name INTO v_name
                  FROM comm_impr_rgstr WHERE bus_id = p_rec.bus_id AND brnchreg = 0;
                p_rec.arbc_impr_name := v_name;                -- TODO-VERIFY other copied fields
            ELSIF NVL(port_setting(p_ctx.curr_port_cd, 'COMM_TABLE_UNCHECK', 9), '0') = '0' THEN
                ftf_msg(9, 190);
            END IF;
        END IF;
        IF p_rec.impr_type_cd = 4 AND p_rec.bus_id_type_cd = 5 THEN
            p_rec.b_id_nbr := p_rec.bus_id;
        END IF;
        IF p_rec.bus_id_brnch IS NOT NULL AND p_rec.bus_id_brnch = p_rec.bus_id THEN
            pkg_forms_compat.ftf('الرقم الفرعي لا يجوز أن يساوي الرقم الرئيسي');      -- TODO-VERIFY
        END IF;
        -- MCI service (get_main_cr_data / GET_CR_DATA) for new records: MANUAL step, see README
        g_set('FLAGUPDATE', '1');
    END bus_id_wvi;

    -- Source: IMPORTERS.BRNH_CITY_CD.WHEN-VALIDATE-ITEM (1-120)
    PROCEDURE brnh_city_cd_wvi (p_rec IN OUT NOCOPY t_rec)
    IS
    BEGIN
        IF p_rec.brnh_city_cd IS NULL THEN
            p_rec.brnh_city_name := NULL;
            RETURN;
        END IF;
        SELECT city_arb_name INTO p_rec.brnh_city_name
          FROM cities WHERE ctry_cd = NVL(p_rec.ctry_cd_of_id, 100) AND city_cd = p_rec.brnh_city_cd;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            ftf_msg(1, 120);
    END brnh_city_cd_wvi;

    -- Source: IMPORTERS.BUS_ID_BRNCH.WHEN-VALIDATE-ITEM
    PROCEDURE bus_id_brnch_wvi (p_rec IN OUT NOCOPY t_rec, p_ctx IN t_ctx)
    IS
        v_mins cities.mins_comm_cd%TYPE;
    BEGIN
        IF p_rec.bus_id_brnch IS NULL THEN
            RETURN;
        END IF;
        IF p_rec.bus_id_brnch = '0' THEN
            ftf_msg(1, 220);
        END IF;
        IF NOT is_digit(p_rec.bus_id_brnch) OR LENGTH(p_rec.bus_id_brnch) NOT IN (6, 10) THEN
            pkg_forms_compat.ftf('الرقم الفرعي أرقام فقط بطول 6 أو 10');              -- TODO-VERIFY
        END IF;
        IF p_rec.brnh_city_cd IS NOT NULL THEN
            SELECT mins_comm_cd INTO v_mins FROM cities
             WHERE ctry_cd = NVL(p_rec.ctry_cd_of_id, 100) AND city_cd = p_rec.brnh_city_cd;
            IF LENGTH(p_rec.bus_id_brnch) = 6 THEN
                p_rec.bus_id_brnch := LPAD(v_mins, 4, '0') || p_rec.bus_id_brnch;
            ELSIF SUBSTR(p_rec.bus_id_brnch, 1, 4) <> LPAD(v_mins, 4, '0') THEN
                ftf_msg(9, 130);
            END IF;
        END IF;
        IF p_rec.bus_id_brnch = p_rec.bus_id THEN
            pkg_forms_compat.ftf('الرقم الفرعي لا يجوز أن يساوي الرقم الرئيسي');      -- TODO-VERIFY
        END IF;
        chk_impr_dupl(p_rec);
        g_set('FLAGUPDATE', '1');
    END bus_id_brnch_wvi;

    -- Source: IMPORTERS.CTRY_CD.WHEN-VALIDATE-ITEM
    PROCEDURE ctry_cd_wvi (p_rec IN OUT NOCOPY t_rec)
    IS
    BEGIN
        IF p_rec.ctry_cd IS NULL THEN RETURN; END IF;
        BEGIN
            p_rec.crty_arbc_name := country_name(p_rec.ctry_cd);
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                pkg_forms_compat.ftf('رمز الدولة غير صحيح - أعد ادخال البيانات');
        END;
        p_rec.ctry_cd_of_id := CASE WHEN p_rec.impr_type_cd = 3 AND p_rec.bus_id_type_cd = 2
                                    THEN 100 ELSE p_rec.ctry_cd END;
    END ctry_cd_wvi;

    -- Source: IMPORTERS.ARBC_IMPR_NAME.WHEN-VALIDATE-ITEM (RemoveRepeat + StrFormat)
    PROCEDURE arbc_impr_name_wvi (p_rec IN OUT NOCOPY t_rec)
    IS
    BEGIN
        IF p_rec.arbc_impr_name IS NOT NULL THEN
            p_rec.arbc_impr_name := str_db.removerepeat(p_rec.arbc_impr_name);   -- TODO-VERIFY signature
            p_rec.impr_name_std  := str_db.strformat(p_rec.arbc_impr_name);
        END IF;
    END arbc_impr_name_wvi;

    -- Source: IMPORTERS.ENG_IMPR_NAME.WHEN-VALIDATE-ITEM (only 0-9 A-Z a-z space)
    PROCEDURE eng_impr_name_wvi (p_rec IN OUT NOCOPY t_rec)
    IS
    BEGIN
        IF p_rec.eng_impr_name IS NOT NULL
           AND NOT REGEXP_LIKE(p_rec.eng_impr_name, '^[0-9A-Za-z ]+$') THEN
            pkg_forms_compat.ftf('الاسم الإنجليزي يقبل الحروف الإنجليزية والأرقام فقط');  -- TODO-VERIFY
        END IF;
    END eng_impr_name_wvi;

    -- Source: IMPORTERS.BUS_ID_ISSUE_DT.WHEN-VALIDATE-ITEM (valid Hijri date)
    PROCEDURE bus_id_issue_dt_wvi (p_rec IN OUT NOCOPY t_rec)
    IS
    BEGIN
        NULL;   -- format checked by to_hijri in get_page_rec (1-10)
    END bus_id_issue_dt_wvi;

    -- Source: IMPORTERS.IMPR_NBR_PARENT.WHEN-VALIDATE-ITEM (9-160)
    PROCEDURE impr_nbr_parent_wvi (p_rec IN OUT NOCOPY t_rec, p_ctx IN t_ctx)
    IS
    BEGIN
        IF p_rec.impr_nbr_parent IS NULL THEN
            p_rec.impr_name_parent := NULL;
            RETURN;
        END IF;
        SELECT arbc_impr_name INTO p_rec.impr_name_parent
          FROM importers
         WHERE impr_nbr = p_rec.impr_nbr_parent AND port_cd = p_ctx.curr_port_cd AND ROWNUM = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            ftf_msg(9, 160);
    END impr_nbr_parent_wvi;

    -- Source: IMPORTERS.ADD_CTRY_CD.WHEN-VALIDATE-ITEM (18-15)
    PROCEDURE add_ctry_cd_wvi (p_rec IN OUT NOCOPY t_rec)
    IS
    BEGIN
        IF p_rec.add_ctry_cd IS NOT NULL THEN
            p_rec.add_crty_arbc_name := country_name(p_rec.add_ctry_cd);
        END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            ftf_msg(18, 15);
    END add_ctry_cd_wvi;

    -- Source: IMPORTERS.CITY_CODE.WHEN-VALIDATE-ITEM (18-282)
    PROCEDURE city_code_wvi (p_rec IN OUT NOCOPY t_rec)
    IS
    BEGIN
        IF p_rec.city_code IS NULL THEN
            pkg_forms_compat.ftf('يجب إدخال المدينة');
        END IF;
        SELECT city_arb_name INTO p_rec.city_name
          FROM cities WHERE ctry_cd = p_rec.add_ctry_cd AND city_cd = p_rec.city_code;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            ftf_msg(18, 282);
    END city_code_wvi;

    -- Source: IMPORTERS.IMPR_TEL_NBR.WHEN-VALIDATE-ITEM (exactly 10 digits, not 0)
    PROCEDURE impr_tel_nbr_wvi (p_rec IN OUT NOCOPY t_rec)
    IS
    BEGIN
        IF p_rec.impr_tel_nbr IS NULL OR p_rec.impr_tel_nbr = '0'
           OR LENGTH(p_rec.impr_tel_nbr) <> 10 OR NOT is_digit(p_rec.impr_tel_nbr) THEN
            pkg_forms_compat.ftf('رقم الهاتف يجب أن يكون 10 أرقام');                  -- TODO-VERIFY
        END IF;
    END impr_tel_nbr_wvi;

    -- Source: IMPORTERS.B_EMAIL / EMAIL.WHEN-VALIDATE-ITEM
    PROCEDURE b_email_wvi (p_rec IN OUT NOCOPY t_rec)
    IS
    BEGIN
        IF p_rec.b_email IS NOT NULL AND INSTR(p_rec.b_email, '@') <= 1 THEN
            pkg_forms_compat.ftf('البريد الإلكتروني غير صحيح');                       -- TODO-VERIFY
        END IF;
        g_set('FLAGUPDATE', '1');   -- B_EMAIL.POST-CHANGE
    END b_email_wvi;

    -- Source: IMPORTERS.B_MOBILE_NO.WHEN-VALIDATE-ITEM
    PROCEDURE b_mobile_no_wvi (p_rec IN OUT NOCOPY t_rec, p_ctx IN t_ctx)
    IS
    BEGIN
        IF p_rec.b_mobile_no IS NULL THEN RETURN; END IF;
        IF NOT is_digit(p_rec.b_mobile_no) OR LENGTH(p_rec.b_mobile_no) <> 9
           OR SUBSTR(p_rec.b_mobile_no, 1, 1) <> '5' THEN
            pkg_forms_compat.ftf('رقم الجوال المدخل غير صحيح');
        END IF;
        IF p_ctx.curr_port_cd = 99 AND p_rec.impr_nbr IS NOT NULL
           AND NVL(TO_NUMBER(g_get('OLD_PORT_CD')), 99) <> 99 THEN
            pkg_forms_compat.ftf('لا يمكن تعديل رقم الجوال لمستورد تابع لجمرك آخر');  -- TODO-VERIFY
        END IF;
        g_set('FLAGUPDATE', '1');
    END b_mobile_no_wvi;

    -- Source: IMPORTERS.BANK_IBAN.WHEN-VALIDATE-ITEM
    PROCEDURE bank_iban_wvi (p_rec IN OUT NOCOPY t_rec)
    IS
    BEGIN
        IF p_rec.bank_iban IS NULL OR p_rec.bank_iban = 'SA' THEN RETURN; END IF;
        p_rec.bank_iban := UPPER(REPLACE(p_rec.bank_iban, ' '));
        IF SUBSTR(p_rec.bank_iban, 1, 2) <> 'SA' THEN
            p_rec.bank_iban := 'SA' || p_rec.bank_iban;
        END IF;
        IF LENGTH(p_rec.bank_iban) <> 24 THEN
            pkg_forms_compat.ftf('رقم الآيبان يجب أن يكون 24 خانة');                   -- TODO-VERIFY
        END IF;
    END bank_iban_wvi;

    -- Source: IMPORTERS.B_ID_NBR.WHEN-VALIDATE-ITEM (numeric + CHECK_IDNO)
    PROCEDURE b_id_nbr_wvi (p_rec IN OUT NOCOPY t_rec)
    IS
    BEGIN
        IF p_rec.b_id_nbr IS NOT NULL AND NOT check_idno(p_rec.b_id_nbr) THEN
            pkg_forms_compat.ftf('رقم الهوية غير صحيح');                               -- TODO-VERIFY
        END IF;
        g_set('FLAGUPDATE', '1');
    END b_id_nbr_wvi;

    -- ======================================================================= DML

    -- Source: IMPORTERS.PRE-INSERT (all blocks, incl. Create_Uni_IMPR_NEBRAS by Bassam Mansour 09/01/2019)
    PROCEDURE importers_pre_ins (p_rec IN OUT NOCOPY t_rec, p_ctx IN t_ctx)
    IS
        v_impr_nbr VARCHAR2(50);
        v_msg_txt  VARCHAR2(500);
        v_result   NUMBER;
    BEGIN
        IF p_rec.b_mobile_no IS NULL THEN
            pkg_forms_compat.ftf('يجب إدخال رقم المحمول');
        END IF;
        IF p_rec.city_code IS NULL THEN
            pkg_forms_compat.ftf('يجب إدخال المدينة');
        END IF;
        chk_dupl_imp_brkr(p_rec, p_ctx);
        IF p_rec.impr_tel_nbr IS NULL THEN
            pkg_forms_compat.ftf('يجب ادخال رقم الهاتف');
        END IF;
        IF ((p_rec.bus_id_type_cd = 2 AND is_type(p_rec.impr_type_cd, '1,3,5,6,8,12'))
            OR (p_rec.bus_id_type_cd IN (3, 4) AND p_rec.impr_type_cd = 4))
           AND p_rec.bus_id_exprd_dt IS NULL THEN
            ftf_msg(9, 220);
        END IF;
        chk_impr_dupl(p_rec);
        IF p_rec.activity IS NULL THEN
            pkg_forms_compat.ftf('يجب إدخال حقل نشاط المستورد');
        END IF;
        -- broker CONFIRM alert -> Confirm DA on the CREATE button (class 1 / user type 3)
        add_activity(1, p_rec);
        chk_comm_rgstr(p_rec, p_ctx);
        IF g_get('CHK_DUP_BUSID') = '1' THEN
            add_activity(3, p_rec);
            g_set('CHK_DUP_BUSID', '0');
        END IF;

        -- RECORD IMPORTER IN HQ AND PORT (positional call kept identical to Forms)
        impr_central.create_uni_impr_nebras(
            p_rec.port_cd, p_rec.bus_id, p_rec.bus_id_brnch, p_rec.bus_id_type_cd, p_rec.impr_type_cd,
            p_rec.ctry_cd, p_rec.city_code, p_rec.impr_cntct_name, NVL(p_rec.impr_tel_nbr, 0),
            p_rec.b_email, p_rec.bank_iban, NVL(p_rec.impr_pob_nbr, 0),
            TO_CHAR(p_rec.bus_id_exprd_dt, 'MI-MM-YYYY'), p_rec.activity, p_rec.arbc_impr_name,
            p_rec.eng_impr_name, NVL(p_rec.b_mobile_no, 0), NVL(p_rec.impr_zip_cd, 0),
            NVL(p_rec.brnh_city_cd, 0), p_rec.impr_expr_type, p_rec.impr_address,
            TO_CHAR(p_rec.bus_id_issue_dt, 'MI-MM-YYYY'), p_rec.b_id_nbr,
            NVL(p_rec.comm_rgstrtn_type, 0), 0 /* NVL(:CTRY_CD_OF_ID,0) */, NVL(p_rec.city_code_of_id, 0),
            NVL(p_rec.impr_nbr_parent, 0), NVL(p_rec.impr_fax_nbr, 0), NVL(p_rec.impr_telex_nbr, 0),
            NVL(p_rec.add_ctry_cd, 0), NVL(p_rec.impd_stmt_nbr, 0), NVL(p_rec.impr_data_srce, 0),
            NVL(p_rec.customs_entered, 0), NVL(p_rec.expd_stmt_nbr, 0), NVL(p_rec.wvr_entry_nbr, 0),
            NVL(p_rec.car_agent_flag, 0), NVL(p_rec.express_post, 0),
            v_impr_nbr, v_msg_txt, v_result,
            p_ctx.user_id, p_ctx.ws_id);
        IF v_result = 1 THEN
            pkg_forms_compat.message(v_msg_txt || ' - رقم المستورد = ' || v_impr_nbr);
            g_set('SET', v_impr_nbr);
            IF v_impr_nbr IS NOT NULL THEN
                p_rec.hq_impr_nbr := TO_NUMBER(v_impr_nbr);
            END IF;
        ELSE
            pkg_forms_compat.ftf(v_msg_txt);
        END IF;
        -- data copies done in Forms by POST-CHANGE of B_ items (ASSUMPTION)
        p_rec.email     := p_rec.b_email;
        p_rec.mobile_no := p_rec.b_mobile_no;
        p_rec.id_nbr    := p_rec.b_id_nbr;
    END importers_pre_ins;

    -- Source: Forms default INSERT of block IMPORTERS (after PRE-INSERT).
    -- OPEN QUESTION (README): does Create_Uni_IMPR_NEBRAS already insert the port row?
    -- IMPR_NBR: Forms sends NULL and later sets :IMPR_NBR := :GLOBAL.SET; DB trigger assumed.
    PROCEDURE importers_ins (p_rec IN OUT NOCOPY t_rec)
    IS
    BEGIN
        INSERT INTO importers (
            port_cd, impr_nbr, hq_impr_nbr, impr_type_cd, bus_id_type_cd, bus_id, bus_id_brnch,
            bus_id_exprd_dt, ctry_cd_of_id, city_code_of_id, impr_expr_type, arbc_impr_name,
            eng_impr_name, impr_name_std, impr_nbr_parent, impr_cntct_name, impr_tel_nbr,
            impr_pob_nbr, impr_zip_cd, impr_fax_nbr, impr_telex_nbr, email, ctry_cd, add_ctry_cd,
            city_code, impd_stmt_nbr, impr_data_srce, comm_rgstrtn_type, car_agent_flag, mobile_no,
            bank_iban, express_post, id_nbr, bus_id_issue_dt, bus_id_status, creation_flag,
            impr_address, expd_stmt_nbr, wvr_entry_nbr, customs_entered)
        VALUES (
            p_rec.port_cd, p_rec.impr_nbr, p_rec.hq_impr_nbr, p_rec.impr_type_cd, p_rec.bus_id_type_cd,
            p_rec.bus_id, p_rec.bus_id_brnch, p_rec.bus_id_exprd_dt, p_rec.ctry_cd_of_id,
            p_rec.city_code_of_id, p_rec.impr_expr_type, p_rec.arbc_impr_name, p_rec.eng_impr_name,
            p_rec.impr_name_std, p_rec.impr_nbr_parent, p_rec.impr_cntct_name, p_rec.impr_tel_nbr,
            p_rec.impr_pob_nbr, p_rec.impr_zip_cd, p_rec.impr_fax_nbr, p_rec.impr_telex_nbr,
            p_rec.email, p_rec.ctry_cd, p_rec.add_ctry_cd, p_rec.city_code, p_rec.impd_stmt_nbr,
            p_rec.impr_data_srce, p_rec.comm_rgstrtn_type, p_rec.car_agent_flag, p_rec.mobile_no,
            p_rec.bank_iban, p_rec.express_post, p_rec.id_nbr, p_rec.bus_id_issue_dt,
            p_rec.bus_id_status, p_rec.creation_flag, p_rec.impr_address, p_rec.expd_stmt_nbr,
            p_rec.wvr_entry_nbr, p_rec.customs_entered)
        RETURNING impr_nbr INTO p_rec.impr_nbr;
    END importers_ins;

    -- Source: IMPORTERS.POST-INSERT
    PROCEDURE importers_post_ins (p_rec IN OUT NOCOPY t_rec, p_ctx IN t_ctx)
    IS
    BEGIN
        IF g_get('SET') IS NOT NULL THEN
            p_rec.impr_nbr    := NVL(p_rec.impr_nbr, TO_NUMBER(g_get('SET')));
            p_rec.hq_impr_nbr := TO_NUMBER(g_get('SET'));
        END IF;
        insert_audit_record(p_rec, p_ctx, 'I');
        update_basic_importer(p_rec);
        IF p_ctx.class_cd = 1 AND p_ctx.user_type = 3 THEN
            NULL;   -- CREATE_BRKR_IMPR_AUTH (BRKIMPS): MANUAL - see README / registry TODO
        END IF;
        -- RETURN_IMPR_ID
        IF p_ctx.user_type = 2 AND p_ctx.class_cd = 23 THEN
            g_set('IMPR_NBR_B', p_rec.impr_nbr);
            g_set('IMPR_NAME_B', p_rec.arbc_impr_name);
        END IF;
    END importers_post_ins;

    -- Source: IMPORTERS.PRE-UPDATE
    PROCEDURE importers_pre_upd (p_rec IN OUT NOCOPY t_rec, p_ctx IN t_ctx)
    IS
        v_hq NUMBER;
    BEGIN
        chk_personal(p_rec);   -- MAIH 08-02-2015
        IF p_rec.b_mobile_no IS NULL THEN
            pkg_forms_compat.ftf('يجب إدخال رقم المحمول');
        END IF;
        chk_dupl_imp_brkr(p_rec, p_ctx);
        IF ((p_rec.bus_id_type_cd = 2 AND is_type(p_rec.impr_type_cd, '1,3,5,6,8,12'))
            OR (p_rec.bus_id_type_cd IN (3, 4) AND p_rec.impr_type_cd = 4))
           AND p_rec.bus_id_exprd_dt IS NULL THEN
            ftf_msg(9, 220);
        END IF;
        IF p_ctx.letter_nbr IS NOT NULL THEN
            p_rec.hq_impr_nbr := NULL;
        END IF;
        p_rec.impr_name_std := str_db.strformat(p_rec.arbc_impr_name);
        insert_audit_record(p_rec, p_ctx, 'U');
        BEGIN
            SELECT hq_impr_nbr INTO v_hq
              FROM hq_imprs
             WHERE bus_id_type_cd = p_rec.bus_id_type_cd
               AND bus_id         = p_rec.bus_id
               AND ((p_rec.bus_id_brnch IS NULL AND bus_id_brnch IS NULL)
                    OR bus_id_brnch = p_rec.bus_id_brnch)
               AND ROWNUM = 1;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN v_hq := NULL;
        END;
        p_rec.hq_impr_nbr := v_hq;
        add_activity(2, p_rec);
        IF g_get('LETTER_NBR') IS NOT NULL THEN
            db_journal.journaling_on(g_get('PORT_CD'), g_get('SUPP_TITLE_CD'),
                                     g_get('LETTER_NBR'), g_get('LETTER_DT'));
        END IF;
        p_rec.arbc_impr_name  := TRIM(p_rec.arbc_impr_name);
        p_rec.eng_impr_name   := TRIM(p_rec.eng_impr_name);
        p_rec.impr_cntct_name := TRIM(p_rec.impr_cntct_name);
        chk_comm_rgstr(p_rec, p_ctx);
        p_rec.mobile_no := p_rec.b_mobile_no;
        p_rec.email     := p_rec.b_email;     -- ASSUMPTION (B_EMAIL.POST-CHANGE)
        p_rec.id_nbr    := p_rec.b_id_nbr;    -- ASSUMPTION
    END importers_pre_upd;

    -- Source: Forms default UPDATE (items with Update Allowed = Yes)
    PROCEDURE importers_upd (p_rec IN t_rec)
    IS
    BEGIN
        UPDATE importers
           SET hq_impr_nbr       = p_rec.hq_impr_nbr,
               impr_type_cd      = p_rec.impr_type_cd,
               bus_id_type_cd    = p_rec.bus_id_type_cd,
               bus_id            = p_rec.bus_id,
               bus_id_brnch      = p_rec.bus_id_brnch,
               bus_id_exprd_dt   = p_rec.bus_id_exprd_dt,
               ctry_cd_of_id     = p_rec.ctry_cd_of_id,
               city_code_of_id   = p_rec.city_code_of_id,
               impr_expr_type    = p_rec.impr_expr_type,
               arbc_impr_name    = p_rec.arbc_impr_name,
               eng_impr_name     = p_rec.eng_impr_name,
               impr_name_std     = p_rec.impr_name_std,
               impr_nbr_parent   = p_rec.impr_nbr_parent,
               impr_cntct_name   = p_rec.impr_cntct_name,
               impr_tel_nbr      = p_rec.impr_tel_nbr,
               impr_pob_nbr      = p_rec.impr_pob_nbr,
               impr_zip_cd       = p_rec.impr_zip_cd,
               impr_fax_nbr      = p_rec.impr_fax_nbr,
               impr_telex_nbr    = p_rec.impr_telex_nbr,
               email             = p_rec.email,
               ctry_cd           = p_rec.ctry_cd,
               add_ctry_cd       = p_rec.add_ctry_cd,
               city_code         = p_rec.city_code,
               comm_rgstrtn_type = p_rec.comm_rgstrtn_type,
               car_agent_flag    = p_rec.car_agent_flag,
               mobile_no         = p_rec.mobile_no,
               bank_iban         = p_rec.bank_iban,
               express_post      = p_rec.express_post,
               id_nbr            = p_rec.id_nbr,
               bus_id_issue_dt   = p_rec.bus_id_issue_dt,
               impr_address      = p_rec.impr_address,
               customs_entered   = p_rec.customs_entered
         WHERE port_cd  = p_rec.port_cd
           AND impr_nbr = p_rec.impr_nbr;
        IF SQL%ROWCOUNT = 0 THEN
            ftf_msg(9, 150);
        END IF;
    END importers_upd;

    -- Source: IMPORTERS.POST-UPDATE
    PROCEDURE importers_post_upd (p_rec IN t_rec)
    IS
    BEGIN
        IF db_journal.is_journaling_on THEN
            db_journal.journaling_off;
        END IF;
        IF g_get('FLAGUPDATE') = '1' THEN
            update_basic_importer(p_rec);
            g_set('FLAGUPDATE', '0');
        END IF;
    END importers_post_upd;

    -- Source: IMPORTERS.PRE-DELETE
    PROCEDURE importers_pre_del (p_rec IN t_rec)
    IS
    BEGIN
        add_activity(5, p_rec);
    END importers_pre_del;

    -- Source: IMPORTERS.KEY-DELREC (confirmation -> DA; FORMS_DDL('COMMIT') removed)
    PROCEDURE importers_del (p_rec IN t_rec)
    IS
    BEGIN
        DELETE impr_updts WHERE port_cd = p_rec.port_cd AND impr_nbr = p_rec.impr_nbr;
        DELETE importers  WHERE port_cd = p_rec.port_cd AND impr_nbr = p_rec.impr_nbr;
    END importers_del;

    -- ======================================================================= function menu

    -- Source: PU ADJ_FUNS (TMPLT.ENABLE_FUN / DISABLE_FUN) -> button Server-side Condition
    FUNCTION fun_allowed (p_fun IN VARCHAR2, p_rec IN t_rec, p_ctx IN t_ctx) RETURN BOOLEAN
    IS
        v_mci BOOLEAN := g_get('ALLOW_MCI') = '1';
        v_moi BOOLEAN := g_get('ALLOW_MOI') = '1';
    BEGIN
        CASE UPPER(p_fun)
            WHEN 'IMPR_MCI_SERVICE' THEN
                RETURN (NVL(p_rec.bus_id_type_cd, 0) = 2 AND v_mci AND p_rec.impr_type_cd <> 12)
                    OR (p_rec.impr_type_cd = 4 AND p_rec.bus_id_type_cd IN (3, 5) AND v_moi);
            WHEN 'IMPR1110F2' THEN
                RETURN FALSE;                               -- always disabled in ADJ_FUNS
            WHEN 'IMPR1110F3' THEN
                RETURN p_rec.impr_nbr IS NOT NULL;
            WHEN 'CREATE_BRKR_IMPR_AUTH' THEN
                RETURN p_ctx.class_cd = 1 AND p_ctx.user_type = 3 AND p_rec.impr_nbr IS NOT NULL;
            WHEN 'IMPR1110_MOB' THEN
                RETURN p_ctx.curr_port_cd = 99 AND p_rec.impr_nbr > 3000000;
            ELSE
                RETURN p_rec.impr_nbr IS NOT NULL;          -- F1, F4, F5, SF6, IMPR1115_GZT
        END CASE;
    END fun_allowed;

    -- Source: WNRI branch :PARAMETER.CODE = 'IMPR1110F1' / 'IMPR1110F5'
    -- Returns the name from COMM_IMPR_RGSTR; the page asks
    -- ' سيتم تعديل الإسم إلى ( name )' (Confirm DA) and copies it to P1110_ARBC_IMPR_NAME.
    FUNCTION f1_comm_name (p_rec IN t_rec) RETURN VARCHAR2
    IS
        v_name comm_impr_rgstr.arbc_impr_name%TYPE;
    BEGIN
        IF p_rec.bus_id_type_cd = 2 AND p_rec.impr_type_cd <> 12 THEN
            IF p_rec.comm_rgstrtn_type = 1 THEN
                SELECT arbc_impr_name INTO v_name
                  FROM comm_impr_rgstr WHERE bus_id = p_rec.bus_id AND brnchreg = 0;
            ELSIF p_rec.comm_rgstrtn_type = 2 THEN
                SELECT arbc_impr_name INTO v_name
                  FROM comm_impr_rgstr WHERE bus_id = p_rec.bus_id AND brnch_bus_id = p_rec.bus_id_brnch;
            ELSE
                pkg_forms_compat.ftf('لا يمكن تعديل الإسم الرجاء مراجعة المساندة الفنية');
            END IF;
        END IF;
        RETURN v_name;   -- NULL -> name field is simply made editable (F5 behaviour)
    EXCEPTION
        WHEN NO_DATA_FOUND OR TOO_MANY_ROWS THEN
            pkg_forms_compat.ftf('لا يمكن تعديل الإسم الرجاء مراجعة المساندة الفنية');
            RETURN NULL;
    END f1_comm_name;

    -- Source: WNRI branch 'IMPR1110F3' (Bilal Alhabshi 01/02/2012 - restrictions department)
    PROCEDURE f3_set_type_19 (p_rec IN OUT NOCOPY t_rec, p_ctx IN t_ctx)
    IS
    BEGIN
        g_set('FUNS_IMP', '1');
        g_set('CHK_IMP_TYP', '1');
        IF p_ctx.class_cd = 19 AND p_ctx.user_type = 1 THEN
            IF p_rec.impr_type_cd = 4 THEN
                pkg_forms_compat.ftf('لا يمكن التعديل  للمستورد الشخصي الا من خلال الدعم الفني التطبيقات');
            END IF;
            UPDATE importers SET impr_type_cd = 19
             WHERE port_cd = p_rec.port_cd AND impr_nbr = p_rec.impr_nbr;
            p_rec.impr_type_cd := 19;
            pkg_forms_compat.message(' تم تعديل النشاط التجاري الى "مؤسسة/شركة/استثمارية "  ');
        END IF;
    END f3_set_type_19;

    -- ======================================================================= UI state
    -- Source: INTRFACE.Make_Field_Entrable / SET_ITEM_PROPERTY(REQUIRED) in POST-QUERY,
    --         WHEN-NEW-RECORD-INSTANCE, WHEN-CREATE-RECORD, IMPR_TYPE_CD.WVI/POST-CHANGE, WNFI.
    -- Returns {"disabled":[...],"required":[...]} with page item names.
    FUNCTION ui_state_json (p_rec IN t_rec, p_ctx IN t_ctx) RETURN CLOB
    IS
        TYPE t_list IS TABLE OF VARCHAR2(30) INDEX BY VARCHAR2(30);
        v_dis  t_list;
        v_req  t_list;
        v_key  VARCHAR2(30);
        v_out  CLOB;
        PROCEDURE dis (p IN VARCHAR2) IS BEGIN v_dis(p) := p; END dis;
        PROCEDURE req (p IN VARCHAR2) IS BEGIN v_req(p) := p; END req;
    BEGIN
        dis('PORT_CD');
        dis('ADD_CTRY_CD');                                   -- WNRI: always 100, disabled
        IF p_rec.impr_nbr IS NOT NULL THEN                    -- WNRI existing record
            dis('BUS_ID'); dis('BUS_ID_EXPRD_DT'); dis('ARBC_IMPR_NAME'); dis('COMM_RGSTRTN_TYPE');
            dis('CITY_CODE_OF_ID'); dis('IMPR_EXPR_TYPE'); dis('IMPR_TYPE_CD'); dis('BRNH_CITY_CD');
            dis('BUS_ID_BRNCH'); dis('BUS_ID_TYPE_CD'); dis('CAR_AGENT_FLAG');
        ELSE
            IF p_ctx.class_cd = 1 AND p_ctx.user_type = 3 THEN
                dis('IMPR_EXPR_TYPE'); dis('EXPRESS_POST');
            END IF;
            IF NOT (p_rec.bus_id_type_cd = 2 AND p_rec.impr_type_cd <> 12) THEN
                dis('COMM_RGSTRTN_TYPE');
            ELSE
                req('COMM_RGSTRTN_TYPE');
            END IF;
            IF p_ctx.prsnl_impr = 1 THEN
                dis('IMPR_TYPE_CD');
            END IF;
        END IF;
        -- per importer type (POST-QUERY / IMPR_TYPE_CD.WVI)
        IF is_type(p_rec.impr_type_cd, '1,2,5,8,11,13,14,16,17,18,20') THEN
            dis('CTRY_CD');
        END IF;
        IF is_type(p_rec.impr_type_cd, '2,4,7,10,12,13,14,16,17,18,20') THEN
            dis('CITY_CODE_OF_ID');
        END IF;
        IF is_type(p_rec.impr_type_cd, '2,4,7,10,11,13,14,16,17,18,20') THEN
            dis('BUS_ID_BRNCH');
        END IF;
        IF is_type(p_rec.impr_type_cd, '13,14,16,17,18,20') THEN
            dis('BUS_ID');
        END IF;
        IF p_rec.impr_type_cd = 9 THEN
            dis('BUS_ID_BRNCH');
            IF p_rec.bus_id_type_cd = 6 THEN
                dis('CTRY_CD'); dis('CITY_CODE_OF_ID'); dis('BUS_ID');
            END IF;
        END IF;
        IF p_rec.impr_type_cd = 4 AND p_rec.bus_id_type_cd IN (3, 5) THEN
            dis('CTRY_CD');
        END IF;
        IF p_rec.comm_rgstrtn_type = 1 THEN
            dis('BUS_ID_BRNCH'); dis('BRNH_CITY_CD');
        ELSIF p_rec.comm_rgstrtn_type = 2 THEN
            req('BRNH_CITY_CD');
        END IF;
        IF is_type(p_rec.impr_type_cd, '1,3,5,6,8,19') THEN   -- IMPR_TYPE_CD.POST-CHANGE
            req('CITY_CODE_OF_ID');
        END IF;

        apex_json.initialize_clob_output;
        apex_json.open_object;
        apex_json.open_array('disabled');
        v_key := v_dis.FIRST;
        WHILE v_key IS NOT NULL LOOP
            apex_json.write('P1110_' || v_key);
            v_key := v_dis.NEXT(v_key);
        END LOOP;
        apex_json.close_array;
        apex_json.open_array('required');
        v_key := v_req.FIRST;
        WHILE v_key IS NOT NULL LOOP
            apex_json.write('P1110_' || v_key);
            v_key := v_req.NEXT(v_key);
        END LOOP;
        apex_json.close_array;
        apex_json.close_object;
        v_out := apex_json.get_clob_output;
        apex_json.free_output;
        RETURN v_out;
    END ui_state_json;

    -- ======================================================================= APEX wrappers

    FUNCTION validate_item (p_item IN VARCHAR2) RETURN VARCHAR2
    IS
        v_rec t_rec;
        v_ctx t_ctx;
    BEGIN
        v_rec := get_page_rec;
        v_ctx := get_ctx;
        CASE UPPER(p_item)
            WHEN 'IMPR_NBR'          THEN impr_nbr_wvi(v_rec);
            WHEN 'IMPR_TYPE_CD'      THEN impr_type_cd_wvi(v_rec, v_ctx);
            WHEN 'BUS_ID_EXPRD_DT'   THEN bus_id_exprd_dt_wvi(v_rec);
            WHEN 'COMM_RGSTRTN_TYPE' THEN comm_rgstrtn_wlc(v_rec);
            WHEN 'CITY_CODE_OF_ID'   THEN city_code_of_id_wvi(v_rec);
            WHEN 'BUS_ID'            THEN bus_id_wvi(v_rec, v_ctx);
            WHEN 'BRNH_CITY_CD'      THEN brnh_city_cd_wvi(v_rec);
            WHEN 'BUS_ID_BRNCH'      THEN bus_id_brnch_wvi(v_rec, v_ctx);
            WHEN 'CTRY_CD'           THEN ctry_cd_wvi(v_rec);
            WHEN 'ARBC_IMPR_NAME'    THEN arbc_impr_name_wvi(v_rec);
            WHEN 'ENG_IMPR_NAME'     THEN eng_impr_name_wvi(v_rec);
            WHEN 'BUS_ID_ISSUE_DT'   THEN bus_id_issue_dt_wvi(v_rec);
            WHEN 'IMPR_NBR_PARENT'   THEN impr_nbr_parent_wvi(v_rec, v_ctx);
            WHEN 'ADD_CTRY_CD'       THEN add_ctry_cd_wvi(v_rec);
            WHEN 'CITY_CODE'         THEN city_code_wvi(v_rec);
            WHEN 'IMPR_TEL_NBR'      THEN impr_tel_nbr_wvi(v_rec);
            WHEN 'B_EMAIL'           THEN b_email_wvi(v_rec);
            WHEN 'B_MOBILE_NO'       THEN b_mobile_no_wvi(v_rec, v_ctx);
            WHEN 'BANK_IBAN'         THEN bank_iban_wvi(v_rec);
            WHEN 'B_ID_NBR'          THEN b_id_nbr_wvi(v_rec);
        END CASE;
        set_page_rec(v_rec);                         -- derived values back to the page
        pkg_forms_compat.copy(ui_state_json(v_rec, v_ctx), 'P1110_UI_STATE');
        RETURN NULL;
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE BETWEEN -20999 AND -20000 THEN
                RETURN REGEXP_REPLACE(SQLERRM, '^ORA-2[0-9]{4}: ');
            END IF;
            RAISE;
    END validate_item;

    PROCEDURE page_dml (p_request IN VARCHAR2)
    IS
        v_rec t_rec;
        v_ctx t_ctx;
    BEGIN
        v_rec := get_page_rec;
        v_ctx := get_ctx;
        CASE p_request
            WHEN 'CREATE' THEN
                importers_pre_ins(v_rec, v_ctx);
                importers_ins(v_rec);
                importers_post_ins(v_rec, v_ctx);
            WHEN 'SAVE' THEN
                importers_pre_upd(v_rec, v_ctx);
                importers_upd(v_rec);
                importers_post_upd(v_rec);
            WHEN 'DELETE' THEN
                importers_pre_del(v_rec);
                importers_del(v_rec);
            WHEN 'IMPR1110F3' THEN
                f3_set_type_19(v_rec, v_ctx);
            ELSE
                NULL;
        END CASE;
        set_page_rec(v_rec);
    END page_dml;

    PROCEDURE page_fetch
    IS
        v_rec t_rec;
        v_ctx t_ctx;
        v_pk  NUMBER := TO_NUMBER(pkg_forms_compat.name_in('P1110_IMPR_NBR'));
    BEGIN
        v_ctx := get_ctx;
        IF v_pk IS NULL THEN
            importers_wcr(v_rec, v_ctx);                -- new record
        ELSE
            SELECT port_cd, hq_impr_nbr, impr_nbr, impr_type_cd, bus_id_exprd_dt, bus_id_type_cd,
                   comm_rgstrtn_type, ctry_cd_of_id, city_code_of_id, bus_id, bus_id_brnch, ctry_cd,
                   impr_expr_type, arbc_impr_name, eng_impr_name, impr_cntct_name, impr_address,
                   bus_id_issue_dt, impr_nbr_parent, add_ctry_cd, city_code, impr_pob_nbr, impr_zip_cd,
                   impr_tel_nbr, impr_fax_nbr, impr_telex_nbr, email, mobile_no, id_nbr, bank_iban,
                   car_agent_flag, express_post, bus_id_status, impr_name_std, lst_tran_dt,
                   impd_stmt_nbr, impr_data_srce, expd_stmt_nbr, wvr_entry_nbr, customs_entered,
                   creation_flag
              INTO v_rec.port_cd, v_rec.hq_impr_nbr, v_rec.impr_nbr, v_rec.impr_type_cd,
                   v_rec.bus_id_exprd_dt, v_rec.bus_id_type_cd, v_rec.comm_rgstrtn_type,
                   v_rec.ctry_cd_of_id, v_rec.city_code_of_id, v_rec.bus_id, v_rec.bus_id_brnch,
                   v_rec.ctry_cd, v_rec.impr_expr_type, v_rec.arbc_impr_name, v_rec.eng_impr_name,
                   v_rec.impr_cntct_name, v_rec.impr_address, v_rec.bus_id_issue_dt,
                   v_rec.impr_nbr_parent, v_rec.add_ctry_cd, v_rec.city_code, v_rec.impr_pob_nbr,
                   v_rec.impr_zip_cd, v_rec.impr_tel_nbr, v_rec.impr_fax_nbr, v_rec.impr_telex_nbr,
                   v_rec.email, v_rec.mobile_no, v_rec.id_nbr, v_rec.bank_iban, v_rec.car_agent_flag,
                   v_rec.express_post, v_rec.bus_id_status, v_rec.impr_name_std, v_rec.lst_tran_dt,
                   v_rec.impd_stmt_nbr, v_rec.impr_data_srce, v_rec.expd_stmt_nbr,
                   v_rec.wvr_entry_nbr, v_rec.customs_entered, v_rec.creation_flag
              FROM importers
             WHERE port_cd  = v_ctx.curr_port_cd       -- block WHERE: PORT_CD = :PARAMETER.P_CURR_PORT_CD
               AND impr_nbr = v_pk;
            importers_post_qry(v_rec, v_ctx);
        END IF;
        set_page_rec(v_rec);
        pkg_forms_compat.copy(ui_state_json(v_rec, v_ctx), 'P1110_UI_STATE');
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            ftf_msg(9, 150);
    END page_fetch;

    PROCEDURE page_wnfi
    IS
    BEGIN
        wnfi(get_ctx);
    END page_wnfi;

END pkg_impr1110;
/
SHOW ERRORS
