-- =============================================================================
-- Package body: IMPR1110 (version 007, 23-11-2026) - see the spec header. NOT COMPILED.
-- Layout      : 1 private types and declarations, 2 forward declarations, 3 private helpers and the
--               converted Forms logic (record based, Forms order, UI calls replaced by "NULL; -- APEX ..."),
--               4 read-only / required rules, 5 f345 helpers, 6 APEX entry points (spec order), 7 version.
-- Generated   : by work/step02/build_package.py from rollback/IMPR1110/step02_rev1/ (do not edit by hand)
-- =============================================================================
SET DEFINE OFF

CREATE OR REPLACE PACKAGE BODY LIB_APX_USR.IMPR1110
AS

    -- =========================================================================
    -- 1 PRIVATE TYPES AND DECLARATIONS
    -- =========================================================================
    -- One record of block IMPORTERS (all base-table items + non-DB items used by the code)
    TYPE T_RECORD IS RECORD (
        -- Forms record context
        row_id             VARCHAR2(18),    -- ROWID of the queried row (Forms key mode ROWID)
        rec_status         VARCHAR2(10),    -- NEW / INSERT / QUERY / CHANGED (:SYSTEM.RECORD_STATUS)
        activity_entr      VARCHAR2(1),     -- 'Y' = item ACTIVITY currently enabled
        bus_id_brnch_entr  VARCHAR2(1),     -- 'Y' = item BUS_ID_BRNCH currently enabled
        -- base-table items (DatabaseItem = Yes)
        port_cd            importers.port_cd%TYPE,
        hq_impr_nbr        importers.hq_impr_nbr%TYPE,
        impr_nbr           importers.impr_nbr%TYPE,
        bus_id_status      importers.bus_id_status%TYPE,
        impr_type_cd       importers.impr_type_cd%TYPE,
        bus_id_exprd_dt    importers.bus_id_exprd_dt%TYPE,     -- Hijri, mask MI-MM-YYYY
        bus_id_type_cd     importers.bus_id_type_cd%TYPE,
        comm_rgstrtn_type  importers.comm_rgstrtn_type%TYPE,
        city_code_of_id    importers.city_code_of_id%TYPE,
        bus_id             importers.bus_id%TYPE,
        bus_id_brnch       importers.bus_id_brnch%TYPE,
        ctry_cd            importers.ctry_cd%TYPE,
        impr_expr_type     importers.impr_expr_type%TYPE,
        arbc_impr_name     importers.arbc_impr_name%TYPE,
        impr_name_std      importers.impr_name_std%TYPE,
        lst_tran_dt        importers.lst_tran_dt%TYPE,
        impd_stmt_nbr      importers.impd_stmt_nbr%TYPE,
        impr_data_srce     importers.impr_data_srce%TYPE,
        eng_impr_name      importers.eng_impr_name%TYPE,
        impr_cntct_name    importers.impr_cntct_name%TYPE,
        impr_address       importers.impr_address%TYPE,
        bus_id_issue_dt    importers.bus_id_issue_dt%TYPE,     -- Hijri
        impr_nbr_parent    importers.impr_nbr_parent%TYPE,
        add_ctry_cd        importers.add_ctry_cd%TYPE,
        city_code          importers.city_code%TYPE,
        impr_pob_nbr       importers.impr_pob_nbr%TYPE,
        impr_zip_cd        importers.impr_zip_cd%TYPE,
        impr_tel_nbr       importers.impr_tel_nbr%TYPE,
        impr_fax_nbr       importers.impr_fax_nbr%TYPE,
        impr_telex_nbr     importers.impr_telex_nbr%TYPE,
        email              importers.email%TYPE,
        mobile_no          importers.mobile_no%TYPE,
        bank_iban          importers.bank_iban%TYPE,
        id_nbr             importers.id_nbr%TYPE,
        car_agent_flag     importers.car_agent_flag%TYPE,
        express_post       importers.express_post%TYPE,
        ctry_cd_of_id      importers.ctry_cd_of_id%TYPE,
        expd_stmt_nbr      importers.expd_stmt_nbr%TYPE,
        wvr_entry_nbr      importers.wvr_entry_nbr%TYPE,
        activity           importers.activity%TYPE,
        customs_entered    importers.customs_entered%TYPE,
        creation_flag      importers.creation_flag%TYPE,
        -- non-DB items
        port_name          VARCHAR2(200),
        sdp_port_status    NUMBER,
        suspn_status       VARCHAR2(2500),
        status_desc        VARCHAR2(200),
        impr_type_name     VARCHAR2(200),
        bus_id_type_name   VARCHAR2(200),
        id_city_name       VARCHAR2(200),
        id_mins_comm_cd    NUMBER,
        l_ct_city_status2  NUMBER,
        brnh_id_mins_comm_cd NUMBER,
        brnh_city_cd       NUMBER,
        brnh_city_name     VARCHAR2(200),
        crty_arbc_name     VARCHAR2(200),
        ctry_ctry_status   NUMBER,
        itidt_note         VARCHAR2(200),
        status             NUMBER,
        impr_name_parent   VARCHAR2(200),
        wasl_city_name     VARCHAR2(200),
        add_crty_arbc_name VARCHAR2(200),
        city_name          VARCHAR2(200),
        l_ct_city_status   NUMBER,
        b_email            VARCHAR2(200),
        b_mobile_no        VARCHAR2(31),
        b_id_nbr           VARCHAR2(15),
        impr_id_type       VARCHAR2(200)
    );

    TYPE T_CONTEXT IS RECORD (
        curr_port_cd  NUMBER,          -- :PARAMETER.P_CURR_PORT_CD
        user_id       VARCHAR2(30),    -- :PARAMETER.P_USER_ID
        ws_id         VARCHAR2(30),    -- :PARAMETER.P_WS_ID
        class_cd      NUMBER,          -- :PARAMETER.P_CLASS_CD
        user_type     NUMBER,          -- :PARAMETER.P_USER_TYPE
        prsnl_impr    NUMBER,          -- :PARAMETER.PRSNL_IMPR
        letter_nbr    VARCHAR2(30),    -- :PARAMETER.LETTER_NBR
        code          VARCHAR2(30),    -- :PARAMETER.CODE (function code set by EXEC_FUNS)
        brkr_port_cd  NUMBER,          -- :PARAMETER.P_BRKR_PORT_CD
        lic_type      NUMBER,          -- :PARAMETER.P_LIC_TYPE
        brkr_nbr      NUMBER           -- :PARAMETER.P_BRKR_NBR
    );

    c_mask       CONSTANT VARCHAR2(10)  := 'MI-MM-YYYY';   -- Hijri mask of the form: day kept in the minutes (Feb 30 is no DATE)
    c_date_time_mask CONSTANT VARCHAR2(30) := 'YYYY/MM/DD HH24:MI:SS';   -- Forms PLSQL_DATE_FORMAT (PRE-FORM), LST_TRAN_DT
    c_err        CONSTANT PLS_INTEGER   := -20001;
    c_hero_title CONSTANT VARCHAR2(200) := 'إضافة وتعديل بيانات مستورد';
    TYPE t_vc_tab IS TABLE OF VARCHAR2(4000) INDEX BY PLS_INTEGER;
    g_fun_cd     t_vc_tab;     -- function codes switched by ADJ_FUNS (TMPLT.ENABLE_FUN / DISABLE_FUN)
    g_fun_on     t_vc_tab;     -- Y / N
    c_functions  CONSTANT VARCHAR2(400) := 'IMPR1110F1,IMPR1110F2,IMPR1110F3,IMPR1110F4,IMPR1110F5,IMPR1110SF6,'
                                        || 'IMPR_CAR_AGENT,IMPR_MCI_SERVICE,CREATE_BRKR_IMPR_AUTH,IMPR1115_GZT,IMPR1110_MOB';

    -- =========================================================================
    -- 2 FORWARD DECLARATIONS (private converted logic)
    -- =========================================================================
    PROCEDURE SET_FUNCTION_ENABLED (p_fun IN VARCHAR2, p_on IN BOOLEAN);
    FUNCTION FUNCTION_STATE (p_fun IN VARCHAR2) RETURN VARCHAR2;
    PROCEDURE info (p_text IN VARCHAR2);
    PROCEDURE FORM_TRIGGER_FAILURE (p_text IN VARCHAR2 DEFAULT NULL);
    FUNCTION GET_GLOBAL (p_name IN VARCHAR2) RETURN VARCHAR2;
    PROCEDURE SET_GLOBAL (p_name IN VARCHAR2, p_val IN VARCHAR2);
    FUNCTION ARABIC_MESSAGE (p_sys IN NUMBER, p_nbr IN NUMBER) RETURN VARCHAR2;
    PROCEDURE DISPLAY_ARABIC_ERROR (p_sys IN NUMBER, p_nbr IN NUMBER);
    PROCEDURE DISPLAY_ARABIC_INFO (p_sys IN NUMBER, p_nbr IN NUMBER);
    FUNCTION CG_MESSAGE (p_default IN VARCHAR2, p1 IN VARCHAR2) RETURN VARCHAR2;
    PROCEDURE add_activity (p_act IN NUMBER, p_rec IN T_RECORD, p_ctx IN T_CONTEXT);
    FUNCTION cur_hij_date RETURN DATE;
    FUNCTION valid_hij_date (p_dt IN DATE) RETURN BOOLEAN;
    PROCEDURE ctry_100_defaults (p_rec IN OUT NOCOPY T_RECORD);
    PROCEDURE CGSF$CLRLU_IMPORTERS_IMP_BUS_I (p_rec IN OUT NOCOPY T_RECORD);
    FUNCTION strip_constraint (p_msg IN VARCHAR2) RETURN VARCHAR2;
    PROCEDURE WHEN_NEW_FORM_INSTANCE (p_rec IN OUT NOCOPY T_RECORD, p_ctx IN T_CONTEXT);
    PROCEDURE IMPORTERS_WHEN_CREATE_RECORD (p_rec IN OUT NOCOPY T_RECORD, p_ctx IN T_CONTEXT);
    PROCEDURE COMMERCIAL_REGISTER_NAME (p_rec IN T_RECORD, p_cnt OUT NUMBER, p_name OUT VARCHAR2);
    FUNCTION NEW_RECORD_CONFIRM_TEXT (p_rec IN T_RECORD, p_ctx IN T_CONTEXT) RETURN VARCHAR2;
    PROCEDURE IMPORTERS_NEW_RECORD_INSTANCE (p_rec    IN OUT NOCOPY T_RECORD,
                              p_ctx    IN OUT NOCOPY T_CONTEXT,
                              p_answer IN PLS_INTEGER DEFAULT c_yes);
    PROCEDURE IMPORTERS_PRE_RECORD (p_rec IN OUT NOCOPY T_RECORD, p_ctx IN T_CONTEXT);
    PROCEDURE IMPORTERS_WHEN_CLEAR_BLOCK;
    PROCEDURE IMPORTERS_POST_QUERY (p_rec IN OUT NOCOPY T_RECORD, p_ctx IN T_CONTEXT);
    PROCEDURE IMPORTERS_PRE_INSERT (p_rec    IN OUT NOCOPY T_RECORD,
                                 p_ctx    IN T_CONTEXT,
                                 p_answer IN PLS_INTEGER DEFAULT c_yes);
    PROCEDURE IMPORTERS_POST_INSERT (p_rec IN OUT NOCOPY T_RECORD, p_ctx IN T_CONTEXT);
    PROCEDURE IMPORTERS_PRE_UPDATE (p_rec IN OUT NOCOPY T_RECORD, p_ctx IN T_CONTEXT);
    PROCEDURE IMPORTERS_POST_UPDATE (p_rec IN OUT NOCOPY T_RECORD);
    PROCEDURE IMPORTERS_PRE_DELETE (p_rec IN T_RECORD, p_ctx IN T_CONTEXT);
    PROCEDURE importers_key_delrec (p_rec IN T_RECORD, p_ctx IN T_CONTEXT);
    FUNCTION importers_on_error (p_op IN VARCHAR2, p_sqlcode IN NUMBER, p_sqlerrm IN VARCHAR2)
        RETURN VARCHAR2;
    PROCEDURE PORT_CD_WHEN_VALIDATE_ITEM (p_rec IN OUT NOCOPY T_RECORD);
    PROCEDURE HQ_IMPR_NBR_POST_CHANGE;
    PROCEDURE IMPR_NBR_WHEN_VALIDATE_ITEM (p_rec IN OUT NOCOPY T_RECORD);
    PROCEDURE IMPR_TYPE_CD_VALIDATE_ITEM (p_rec IN OUT NOCOPY T_RECORD, p_ctx IN T_CONTEXT);
    PROCEDURE IMPR_TYPE_CD_POST_CHANGE (p_rec IN T_RECORD);
    PROCEDURE IMPR_TYPE_CD_NEW_ITEM_INSTANCE (p_rec IN OUT NOCOPY T_RECORD);
    PROCEDURE IMPR_TYPE_CD_LOV_RETURN (p_rec IN OUT NOCOPY T_RECORD);
    PROCEDURE BUS_ID_EXPRD_DT_VALIDATE_ITEM (p_rec IN T_RECORD, p_from_item IN BOOLEAN DEFAULT TRUE);
    PROCEDURE BUS_ID_TYPE_CD_POST_CHANGE (p_rec IN OUT NOCOPY T_RECORD);
    PROCEDURE COMM_RGSTRTN_TYPE_LIST_CHANGED (p_rec IN OUT NOCOPY T_RECORD);
    PROCEDURE CTRY_CD_OF_ID_VALIDATE_ITEM (p_rec IN OUT NOCOPY T_RECORD);
    PROCEDURE CITY_CODE_OF_ID_VALIDATE_ITEM (p_rec IN OUT NOCOPY T_RECORD);
    PROCEDURE CITY_CODE_OF_ID_WHEN_NEW_ITEM (p_rec IN T_RECORD);
    FUNCTION BUS_ID_SUSPENDED_IMPORTER (p_rec IN T_RECORD) RETURN NUMBER;
    PROCEDURE BUS_ID_WHEN_VALIDATE_ITEM (p_rec         IN OUT NOCOPY T_RECORD,
                          p_ctx         IN T_CONTEXT,
                          p_cr_answer   IN PLS_INTEGER DEFAULT c_yes,
                          p_susp_answer IN PLS_INTEGER DEFAULT c_yes);
    PROCEDURE BUS_ID_POST_CHANGE;
    PROCEDURE BUS_ID_WHEN_NEW_ITEM_INSTANCE (p_rec IN T_RECORD);
    PROCEDURE BRNH_CITY_CD_VALIDATE_ITEM (p_rec IN OUT NOCOPY T_RECORD);
    PROCEDURE BRNH_CITY_CD_NEW_ITEM_INSTANCE;
    PROCEDURE BUS_ID_BRNCH_VALIDATE_ITEM (p_rec       IN OUT NOCOPY T_RECORD,
                                p_ctx       IN T_CONTEXT,
                                p_cr_answer IN PLS_INTEGER DEFAULT c_yes);
    PROCEDURE BUS_ID_BRNCH_POST_CHANGE;
    PROCEDURE BUS_ID_BRNCH_NEW_ITEM_INSTANCE (p_rec IN T_RECORD);
    PROCEDURE CTRY_CD_WHEN_VALIDATE_ITEM (p_rec IN OUT NOCOPY T_RECORD);
    PROCEDURE IMPR_EXPR_TYPE_POST_CHANGE;
    PROCEDURE ARBC_IMPR_NAME_VALIDATE_ITEM (p_rec IN OUT NOCOPY T_RECORD);
    PROCEDURE ARBC_IMPR_NAME_KEY_NEXT_ITEM (p_rec IN OUT NOCOPY T_RECORD);
    PROCEDURE ENG_IMPR_NAME_VALIDATE_ITEM (p_rec IN OUT NOCOPY T_RECORD);
    PROCEDURE BUS_ID_ISSUE_DT_VALIDATE_ITEM (p_rec IN T_RECORD, p_from_item IN BOOLEAN DEFAULT TRUE);
    PROCEDURE IMPR_NBR_PARENT_VALIDATE_ITEM (p_rec IN OUT NOCOPY T_RECORD);
    PROCEDURE ADD_CTRY_CD_WHEN_VALIDATE_ITEM (p_rec IN OUT NOCOPY T_RECORD);
    PROCEDURE CITY_CODE_WHEN_VALIDATE_ITEM (p_rec IN OUT NOCOPY T_RECORD);
    PROCEDURE IMPR_TEL_NBR_VALIDATE_ITEM (p_rec IN T_RECORD);
    PROCEDURE check_email (p_email IN VARCHAR2, p_from_item IN BOOLEAN);
    PROCEDURE B_EMAIL_WHEN_VALIDATE_ITEM (p_rec IN T_RECORD, p_from_item IN BOOLEAN DEFAULT TRUE);
    PROCEDURE EMAIL_WHEN_VALIDATE_ITEM (p_rec IN T_RECORD, p_from_item IN BOOLEAN DEFAULT TRUE);
    PROCEDURE B_EMAIL_POST_CHANGE (p_rec IN OUT NOCOPY T_RECORD, p_ctx IN T_CONTEXT);
    PROCEDURE B_MOBILE_NO_WHEN_VALIDATE_ITEM (p_rec IN T_RECORD, p_ctx IN T_CONTEXT);
    PROCEDURE B_MOBILE_NO_POST_CHANGE (p_rec IN OUT NOCOPY T_RECORD, p_ctx IN T_CONTEXT);
    PROCEDURE BANK_IBAN_WHEN_VALIDATE_ITEM (p_rec IN OUT NOCOPY T_RECORD);
    PROCEDURE BANK_IBAN_NEW_ITEM_INSTANCE (p_rec IN OUT NOCOPY T_RECORD);
    PROCEDURE B_ID_NBR_WHEN_VALIDATE_ITEM (p_rec IN T_RECORD);
    PROCEDURE B_ID_NBR_POST_CHANGE (p_rec IN OUT NOCOPY T_RECORD, p_ctx IN T_CONTEXT);
    FUNCTION check_idno (id_no IN VARCHAR2) RETURN BOOLEAN;
    FUNCTION is_digit (txt_num IN VARCHAR2) RETURN BOOLEAN;
    PROCEDURE check_bus_id;
    PROCEDURE chk_bus_id_brnch (p_rec IN T_RECORD);
    PROCEDURE chk_impr_dupl (p_rec IN T_RECORD);
    PROCEDURE chk_dupl_imp_brkr (p_rec IN T_RECORD, p_ctx IN T_CONTEXT);
    PROCEDURE chk_personal (p_rec          IN OUT NOCOPY T_RECORD,
                            p_ctx          IN T_CONTEXT,
                            p_impr_type_cd IN NUMBER,
                            p_hq_impr_nbr  IN NUMBER,
                            p_stop         IN NUMBER DEFAULT 1);
    PROCEDURE insert_audit_record (p_rec IN T_RECORD, p_ctx IN T_CONTEXT, v_act_type IN VARCHAR2);
    PROCEDURE update_basic_importer (p_rec IN T_RECORD);
    PROCEDURE return_impr_id (p_rec IN T_RECORD, p_ctx IN T_CONTEXT);
    PROCEDURE broker_int (p_rec IN OUT NOCOPY T_RECORD);
    PROCEDURE adj_funs (p_rec IN T_RECORD, p_ctx IN T_CONTEXT);
    PROCEDURE get_cr_data (p_rec           IN OUT NOCOPY T_RECORD,
                           p_string_result IN VARCHAR2,
                           p_type          IN VARCHAR2);
    PROCEDURE get_main_cr_data (p_rec IN OUT NOCOPY T_RECORD);
    PROCEDURE get_branch_cr_data (p_rec IN OUT NOCOPY T_RECORD);
    PROCEDURE create_brkr_impr_auth (p_rec IN T_RECORD, p_ctx IN T_CONTEXT);
    FUNCTION update_importer_msg (p_rec IN T_RECORD) RETURN VARCHAR2;
    PROCEDURE update_importer (p_rec IN T_RECORD);
    FUNCTION central_mobile (p_rec IN T_RECORD, p_ctx IN T_CONTEXT) RETURN NUMBER;
    PROCEDURE lov_update_moblie (p_rec IN T_RECORD);
    PROCEDURE exec_funs (p_rec IN OUT NOCOPY T_RECORD, p_ctx IN OUT NOCOPY T_CONTEXT, cd IN VARCHAR2);

    -- =========================================================================
    -- 3 PRIVATE HELPERS AND CONVERTED FORMS LOGIC (Forms order)
    -- =========================================================================
    -- TMPLT.ENABLE_FUN / TMPLT.DISABLE_FUN  -- TODO: MISSING SOURCE TMPLT (LIB_APX_USR / OLB)
    PROCEDURE SET_FUNCTION_ENABLED (p_fun IN VARCHAR2, p_on IN BOOLEAN)
    IS
        n PLS_INTEGER := g_fun_cd.COUNT + 1;
    BEGIN
        g_fun_cd(n) := p_fun;
        g_fun_on(n) := CASE WHEN p_on THEN 'Y' ELSE 'N' END;
    END SET_FUNCTION_ENABLED;

    FUNCTION FUNCTION_STATE (p_fun IN VARCHAR2) RETURN VARCHAR2
    IS
        v VARCHAR2(1);
    BEGIN
        FOR i IN 1 .. g_fun_cd.COUNT LOOP
            IF g_fun_cd(i) = p_fun THEN
                v := g_fun_on(i);          -- last call wins, as in Forms
            END IF;
        END LOOP;
        RETURN v;
    END FUNCTION_STATE;

    -- MESSAGE / STR.DispAlert(..., 'INFORMATION') that does not stop the trigger
    PROCEDURE INFO (p_text IN VARCHAR2)
    IS
    BEGIN
        FORMS_APX.MESSAGE(p_text);
    END INFO;

    PROCEDURE FORM_TRIGGER_FAILURE (p_text IN VARCHAR2 DEFAULT NULL)
    IS
    BEGIN
        FORMS_APX.FORM_TRIGGER_FAILURE(p_text);
    END FORM_TRIGGER_FAILURE;

    FUNCTION GET_GLOBAL (p_name IN VARCHAR2) RETURN VARCHAR2
    IS
    BEGIN
        RETURN FORMS_APX.get_global(p_name);
    END GET_GLOBAL;

    PROCEDURE SET_GLOBAL (p_name IN VARCHAR2, p_val IN VARCHAR2)
    IS
    BEGIN
        FORMS_APX.set_global(p_name, p_val);
    END SET_GLOBAL;

    -- Text of Str.DispArbMsg(sys, nbr). STR.pll is MISSING SOURCE; the format below is the one
    -- the form itself builds inline for message 9-120 (IMPORTERS.BUS_ID.WHEN-VALIDATE-ITEM).
    -- TODO: verify against STR.DispArbMsg once STR.pll is available.
    FUNCTION ARABIC_MESSAGE (p_sys IN NUMBER, p_nbr IN NUMBER) RETURN VARCHAR2
    IS
        v_txt VARCHAR2(4000);
    BEGIN
        v_txt := str_db.getarbmsg(p_sys, p_nbr);
        IF v_txt = '-1' THEN
            RETURN 'خطأ فى رقم الرسالة  ' || p_sys || '-' || p_nbr || 'إتصل بالمسانده الفنيه';
        END IF;
        RETURN p_sys || '-' || p_nbr || ' : ' || v_txt;
    END ARABIC_MESSAGE;

    -- ret := Str.DispArbMsg(s, n, ...); RAISE FORM_TRIGGER_FAILURE;
    PROCEDURE DISPLAY_ARABIC_ERROR (p_sys IN NUMBER, p_nbr IN NUMBER)
    IS
    BEGIN
        FORM_TRIGGER_FAILURE(ARABIC_MESSAGE(p_sys, p_nbr));
    END DISPLAY_ARABIC_ERROR;

    -- ret := Str.DispArbMsg(s, n, ...);   (no raise)
    PROCEDURE DISPLAY_ARABIC_INFO (p_sys IN NUMBER, p_nbr IN NUMBER)
    IS
    BEGIN
        info(ARABIC_MESSAGE(p_sys, p_nbr));
    END DISPLAY_ARABIC_INFO;

    -- Des$Form_errors.MSGGETTEXT(n, '<p1> ...', p1)   -- TODO: MISSING SOURCE Des$Form_errors
    -- (CG library). English default text with <p1> replaced; verify the Arabic text it returns.
    FUNCTION CG_MESSAGE (p_default IN VARCHAR2, p1 IN VARCHAR2) RETURN VARCHAR2
    IS
    BEGIN
        RETURN REPLACE(p_default, '<p1>', p1);
    END CG_MESSAGE;

    -- Forms: IF NOT ACTIVITY.ADD_ACTIVITY(9, 2, n, :IMPORTERS.Port_Cd||'!'||:IMPORTERS.Impr_Nbr) THEN
    --            RAISE FORM_TRIGGER_FAILURE;
    -- ACTIVITY is the client library CIC_LIB.pld; its ADD_ACTIVITY calls the DB package
    --   ACTIVITY_DB.ADD_ACTIVITY(SYSOBJ_ID, SUBJ_CODE, ACTVY_TYPE, ACTVY_SUBJ_ID,
    --       :PARAMETER.P_Curr_Port_Cd, :PARAMETER.P_USER_ID, :PARAMETER.P_WS_ID, V_MSG_TXT)
    -- and on 0 shows STR.DISPALERT(V_MSG_TXT, 'CFG_SYSTEM_ERROR') and returns FALSE.
    -- Here: ACTIVITY_DB (LIB_USR, plsql/Shared/ACTIVITY_DB.pks), 8-parameter overload.
    PROCEDURE add_activity (p_act IN NUMBER, p_rec IN T_RECORD, p_ctx IN T_CONTEXT)
    IS
        v_msg VARCHAR2(2000);
    BEGIN
        IF activity_db.add_activity(9, 2, p_act, p_rec.port_cd || '!' || p_rec.impr_nbr,
                                    p_ctx.curr_port_cd, p_ctx.user_id, p_ctx.ws_id, v_msg) = 0 THEN
            FORM_TRIGGER_FAILURE(v_msg);                                -- DISPALERT(V_MSG_TXT) + FORM_TRIGGER_FAILURE
        END IF;
    END add_activity;

    -- HIJDATE.Cur_Hij_Date (client library CIC_LIB.pld):
    --   V_RET := HIJDATE_DB.Cur_Hij_Date(V_MSG); IF V_RET IS NULL THEN DISPALERT(V_MSG); RAISE FORM_TRIGGER_FAILURE;
    FUNCTION cur_hij_date RETURN DATE
    IS
        v_msg VARCHAR2(2000);
        v_ret DATE;
    BEGIN
        v_ret := hijdate_db.cur_hij_date(v_msg);
        IF v_ret IS NULL THEN
            FORM_TRIGGER_FAILURE(v_msg);
        END IF;
        RETURN v_ret;
    END cur_hij_date;

    -- HIJDATE.VALID_HIJ_DATE (client library CIC_LIB.pld):
    --   IF HDATE IS NULL THEN RETURN NULL; END IF;
    --   V_RET := HIJDATE_DB.VALID_HIJ_DATE(HDate, V_MSG);
    --   IF V_RET = 0 THEN STR.DISPALERT(V_MSG, 'ERROR'); RETURN FALSE; ELSE RETURN TRUE; END IF;
    -- Both callers raise FORM_TRIGGER_FAILURE right after FALSE, so the alert text is raised here
    -- (otherwise the user would get the failure without the HIJDATE_DB message).
    FUNCTION valid_hij_date (p_dt IN DATE) RETURN BOOLEAN
    IS
        v_msg VARCHAR2(2000);
        v_ret NUMBER;
    BEGIN
        IF p_dt IS NULL THEN
            RETURN NULL;
        END IF;
        v_ret := hijdate_db.valid_hij_date(p_dt, v_msg);
        IF v_ret = 0 THEN
            FORM_TRIGGER_FAILURE(v_msg);                                -- DISPALERT(V_MSG, 'ERROR') + caller's FORM_TRIGGER_FAILURE
        END IF;
        RETURN TRUE;
    END valid_hij_date;

    -- Repeated block: IMPR_TYPE_CD.WHEN-NEW-ITEM-INSTANCE, WHEN-NEW-RECORD-INSTANCE,
    -- WHEN-NEW-FORM-INSTANCE, IMPR_TYPE_CD.KEY-LISTVAL (identical text in all four)
    PROCEDURE ctry_100_defaults (p_rec IN OUT NOCOPY T_RECORD)
    IS
    BEGIN
        IF p_rec.impr_type_cd = 4 AND p_rec.bus_id_type_cd = 3
           OR p_rec.impr_type_cd = 4 AND p_rec.bus_id_type_cd = 5 THEN
            p_rec.ctry_cd := 100;
            NULL;  -- APEX (read_only_rules.md): ui('CTRY_CD', 'ENABLED', FALSE);
            SELECT crty_arbc_name INTO p_rec.crty_arbc_name
              FROM countries
             WHERE ctry_cd = 100;
        END IF;
        p_rec.add_ctry_cd := 100;
        NULL;  -- APEX (read_only_rules.md): ui('ADD_CTRY_CD', 'ENABLED', FALSE);
        SELECT crty_arbc_name INTO p_rec.add_crty_arbc_name
          FROM countries
         WHERE ctry_cd = 100;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DISPLAY_ARABIC_ERROR(18, 15);
    END ctry_100_defaults;

    -- CGSF$CLRLU_IMPORTERS_IMP_BUS_I : clear the BUS_ID city lookup items
    PROCEDURE CGSF$CLRLU_IMPORTERS_IMP_BUS_I (p_rec IN OUT NOCOPY T_RECORD)
    IS
    BEGIN
        p_rec.city_code_of_id   := NULL;
        p_rec.ctry_cd_of_id     := NULL;
        p_rec.l_ct_city_status2 := NULL;
        p_rec.id_city_name      := NULL;
        p_rec.id_mins_comm_cd   := NULL;
    END CGSF$CLRLU_IMPORTERS_IMP_BUS_I;

    -- CGTE$STRIP_CONSTRAINT  -- TODO: MISSING SOURCE (CG library). Re-implemented: constraint
    -- name between the brackets of the ORA- message, without the owner.
    FUNCTION strip_constraint (p_msg IN VARCHAR2) RETURN VARCHAR2
    IS
        v VARCHAR2(200);
    BEGIN
        v := REGEXP_SUBSTR(p_msg, '\(([^)]+)\)', 1, 1, NULL, 1);
        RETURN SUBSTR(v, INSTR(v, '.') + 1);
    END strip_constraint;

    -- Source: IMPR1110.WHEN-NEW-FORM-INSTANCE (business part)
    -- Dropped: NIB.WHEN_NEW_FORM_INSTANCE (MISSING SOURCE, toolbar/menu library) and
    -- CG$WHEN_NEW_FORM_INSTANCE (fills list items from CG_REF_CODES -> shared LOVs).
    --@ORIG FORM.WHEN-NEW-FORM-INSTANCE
    -- >>> Original Forms code: FORM.WHEN-NEW-FORM-INSTANCE
    --    NIB.WHEN_NEW_FORM_INSTANCE;
    --   BEGIN
    --     BEGIN
    --       CG$WHEN_NEW_FORM_INSTANCE;
    --     EXCEPTION
    --       WHEN OTHERS THEN
    --         CGTE$OTHER_EXCEPTIONS;
    --     END;
    --   END;
    --   DECLARE
    --     rg_id RECORDGROUP;
    --     temp NUMBER;
    --    RET NUMBER;
    --   BEGIN
    --   INTRFACE.Make_Field_Entrable('IMPORTERS.COMM_RGSTRTN_TYPE' , FALSE);
    --   INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_EXPRD_DT' , FALSE);
    --   INTRFACE.Make_Field_Entrable('IMPORTERS.CITY_CODE_OF_ID' , FALSE);
    --   IF :PARAMETER.P_CLASS_CD=1 AND :PARAMETER.P_USER_TYPE=3 THEN
    --       BROKER_INT;
    --   END IF;
    --       :GLOBAL.FLAGUPDATE := 0;
    --       :global.Exec_Query_Now := 0;
    --       :global.PORT_CD  := NULL;
    --       :global.IMPR_NBR  := NULL;
    --       :GLOBAL.EXE_DETAIL_QUERY:=0;
    --         :GLOBAL.LETTER_NBR :=NULL;
    --       :GLOBAL.CHK_DUP_BUSID := 0 ;
    --   :GLOBAL.OLD_impr_type_cd := 0 ;
    --               IF :PARAMETER.LETTER_NBR IS NULL THEN
    --           GO_ITEM('IMPORTERS.IMPR_NBR');
    --           END IF;
    --           SET_ITEM_PROPERTY('IMPORTERS.PORT_CD', ENABLED, PROPERTY_FALSE);
    --   :GLOBAL.VALID:=0;
    --   :GLOBAL.IMP0F4:=0;
    --   :GLOBAL.STAT_QUE:=0;
    --   :GLOBAL.STAT_CLR:=0;
    --   :GLOBAL.FUNS_IMP :=0;
    --   :GLOBAL.FUNS_BUSID :=0;
    --   :GLOBAL.MINS_COMM_CD := NULL;
    --   :GLOBAL.CHK_IMP_TYP := 0;
    --   BEGIN
    --      :GLOBAL.allow_mci := 0;
    --      :GLOBAL.allow_moi := 0;
    --      BEGIN
    --         SELECT var_value
    --           INTO :GLOBAL.allow_mci
    --           FROM sc_port_setting
    --          WHERE sysobj_id = 24 AND var_name = 'ALLOW_MCI'
    --           AND PORT_CD=:PARAMETER.P_CURR_PORT_CD;
    --        SELECT var_value
    --           INTO :GLOBAL.allow_moi
    --           FROM sc_port_setting
    --          WHERE sysobj_id = 24 AND var_name = 'ALLOW_MOI'
    --   AND PORT_CD=:PARAMETER.P_CURR_PORT_CD;
    --      EXCEPTION
    --         WHEN OTHERS
    --         THEN
    --            NULL;
    --      END;
    --      :GLOBAL.allow_mci := NVL (:GLOBAL.allow_mci, 0);
    --      :GLOBAL.allow_moi := NVL (:GLOBAL.allow_moi, 0);
    --   END;
    --   BEGIN
    --   IF :IMPR_TYPE_CD = 4  AND  :BUS_ID_TYPE_CD = 3
    --   OR :IMPR_TYPE_CD = 4  AND  :BUS_ID_TYPE_CD = 5 THEN
    --   :CTRY_CD := 100;
    --   SET_ITEM_PROPERTY('CTRY_CD', ENABLED,PROPERTY_FALSE);
    --   SELECT CRTY_ARBC_NAME INTO :CRTY_ARBC_NAME
    --    FROM   COUNTRIES
    --    WHERE  CTRY_CD = 100;
    --   END IF;
    --   :ADD_CTRY_CD := 100 ;
    --   SET_ITEM_PROPERTY('ADD_CTRY_CD', ENABLED,PROPERTY_FALSE);
    --   SELECT CRTY_ARBC_NAME INTO :ADD_CRTY_ARBC_NAME
    --    FROM   COUNTRIES
    --    WHERE  CTRY_CD = 100;
    --   EXCEPTION
    --   WHEN NO_DATA_FOUND THEN
    --     ret := Str.DispArbMsg(18, 15,'ERROR');
    --     RAISE FORM_TRIGGER_FAILURE;
    --   END;
    --   END ;
    -- <<<
    PROCEDURE WHEN_NEW_FORM_INSTANCE (p_rec IN OUT NOCOPY T_RECORD, p_ctx IN T_CONTEXT)
    IS
        v_val VARCHAR2(200);
    BEGIN
        NULL;  -- APEX (read_only_rules.md): entrable('COMM_RGSTRTN_TYPE', FALSE);
        NULL;  -- APEX (read_only_rules.md): entrable('BUS_ID_EXPRD_DT', FALSE);
        NULL;  -- APEX (read_only_rules.md): entrable('CITY_CODE_OF_ID', FALSE);
        IF p_ctx.class_cd = 1 AND p_ctx.user_type = 3 THEN
            broker_int(p_rec);
        END IF;
        SET_GLOBAL('FLAGUPDATE', '0');
        SET_GLOBAL('EXEC_QUERY_NOW', '0');
        SET_GLOBAL('PORT_CD', NULL);
        SET_GLOBAL('IMPR_NBR', NULL);
        SET_GLOBAL('EXE_DETAIL_QUERY', '0');
        SET_GLOBAL('LETTER_NBR', NULL);
        SET_GLOBAL('CHK_DUP_BUSID', '0');
        SET_GLOBAL('OLD_IMPR_TYPE_CD', '0');
        IF p_ctx.letter_nbr IS NULL THEN
            NULL;  -- APEX (read_only_rules.md): ui_focus('IMPR_NBR');
        END IF;
        NULL;  -- APEX (read_only_rules.md): ui('PORT_CD', 'ENABLED', FALSE);
        SET_GLOBAL('VALID', '0');
        SET_GLOBAL('IMP0F4', '0');
        SET_GLOBAL('STAT_QUE', '0');
        SET_GLOBAL('STAT_CLR', '0');
        SET_GLOBAL('FUNS_IMP', '0');
        SET_GLOBAL('FUNS_BUSID', '0');
        SET_GLOBAL('MINS_COMM_CD', NULL);
        SET_GLOBAL('CHK_IMP_TYP', '0');
        SET_GLOBAL('ALLOW_MCI', '0');
        SET_GLOBAL('ALLOW_MOI', '0');
        BEGIN
            SELECT var_value INTO v_val
              FROM sc_port_setting
             WHERE sysobj_id = 24 AND var_name = 'ALLOW_MCI'
               AND port_cd = p_ctx.curr_port_cd;
            SET_GLOBAL('ALLOW_MCI', v_val);
            SELECT var_value INTO v_val
              FROM sc_port_setting
             WHERE sysobj_id = 24 AND var_name = 'ALLOW_MOI'
               AND port_cd = p_ctx.curr_port_cd;
            SET_GLOBAL('ALLOW_MOI', v_val);
        EXCEPTION
            WHEN OTHERS THEN
                NULL;
        END;
        SET_GLOBAL('ALLOW_MCI', NVL(GET_GLOBAL('ALLOW_MCI'), '0'));
        SET_GLOBAL('ALLOW_MOI', NVL(GET_GLOBAL('ALLOW_MOI'), '0'));
        ctry_100_defaults(p_rec);
    END WHEN_NEW_FORM_INSTANCE;

    -- Source: IMPORTERS.WHEN-CREATE-RECORD
    --@ORIG IMPORTERS.WHEN-CREATE-RECORD
    -- >>> Original Forms code: IMPORTERS.WHEN-CREATE-RECORD
    --   BEGIN
    --           :IMPORTERS.PORT_CD := :PARAMETER.P_CURR_PORT_CD;
    --           SELECT PORT_NAME
    --           INTO:PORT_NAME
    --           FROM SD_PORTS
    --           WHERE    PORT_CD = :IMPORTERS.PORT_CD;
    --       IF :PARAMETER.PRSNL_IMPR = 1 THEN
    --           :IMPORTERS.IMPR_TYPE_CD := 4;
    --           SELECT     IMPR_TYPE_NAME
    --           INTO        :IMPORTERS.IMPR_TYPE_NAME
    --           FROM        IMPR_TYPES
    --           WHERE        IMPR_TYPE_CD = :IMPORTERS.IMPR_TYPE_CD
    --           ;
    --           INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_TYPE_CD' , FALSE);
    --           INTRFACE.Make_Field_Entrable('IMPORTERS.CITY_CODE_OF_ID' , FALSE);
    --           SET_ITEM_PROPERTY('IMPORTERS.CITY_CODE_OF_ID2' , ENABLED , PROPERTY_FALSE);
    --           INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_BRNCH' , FALSE);
    --       ELSE
    --           INTRFACE.Make_Field_Entrable('IMPORTERS.CITY_CODE_OF_ID' , TRUE);
    --           SET_ITEM_PROPERTY('IMPORTERS.CITY_CODE_OF_ID2' , ENABLED , PROPERTY_TRUE);
    --       END IF;
    --       INTRFACE.Make_Field_Entrable('IMPORTERS.CTRY_CD' , TRUE);
    --       INTRFACE.Make_Field_Entrable('IMPORTERS.ADD_CTRY_CD' , TRUE);
    --       :Global.Ins := 0;
    --   END;
    -- <<<
    PROCEDURE IMPORTERS_WHEN_CREATE_RECORD (p_rec IN OUT NOCOPY T_RECORD, p_ctx IN T_CONTEXT)
    IS
    BEGIN
        p_rec.port_cd := p_ctx.curr_port_cd;
        SELECT port_name
          INTO p_rec.port_name
          FROM sd_ports
         WHERE port_cd = p_rec.port_cd;
        IF p_ctx.prsnl_impr = 1 THEN
            p_rec.impr_type_cd := 4;
            SELECT impr_type_name
              INTO p_rec.impr_type_name
              FROM impr_types
             WHERE impr_type_cd = p_rec.impr_type_cd;
            NULL;  -- APEX (read_only_rules.md): entrable('IMPR_TYPE_CD', FALSE);
            NULL;  -- APEX (read_only_rules.md): entrable('CITY_CODE_OF_ID', FALSE);
            NULL;  -- APEX (read_only_rules.md): ui('CITY_CODE_OF_ID2', 'ENABLED', FALSE);
            NULL;  -- APEX (read_only_rules.md): entrable('BUS_ID_BRNCH', FALSE);
        ELSE
            NULL;  -- APEX (read_only_rules.md): entrable('CITY_CODE_OF_ID', TRUE);
            NULL;  -- APEX (read_only_rules.md): ui('CITY_CODE_OF_ID2', 'ENABLED', TRUE);
        END IF;
        NULL;  -- APEX (read_only_rules.md): entrable('CTRY_CD', TRUE);
        NULL;  -- APEX (read_only_rules.md): entrable('ADD_CTRY_CD', TRUE);
        SET_GLOBAL('INS', '0');
    END IMPORTERS_WHEN_CREATE_RECORD;

    -- Shared by IMPR1110F1 / IMPR1110F5: count + name from COMM_IMPR_RGSTR
    PROCEDURE COMMERCIAL_REGISTER_NAME (p_rec IN T_RECORD, p_cnt OUT NUMBER, p_name OUT VARCHAR2)
    IS
    BEGIN
        p_name := NULL;
        IF p_rec.comm_rgstrtn_type = 1 THEN
            SELECT COUNT(bus_id) INTO p_cnt
              FROM comm_impr_rgstr
             WHERE bus_id = p_rec.bus_id AND brnchreg = 0;
            IF p_cnt = 1 THEN
                SELECT arbc_impr_name INTO p_name
                  FROM comm_impr_rgstr
                 WHERE bus_id = p_rec.bus_id AND brnchreg = 0;
            END IF;
        ELSIF p_rec.comm_rgstrtn_type = 2 THEN
            SELECT COUNT(bus_id) INTO p_cnt
              FROM comm_impr_rgstr
             WHERE bus_id = p_rec.bus_id AND brnch_bus_id = p_rec.bus_id_brnch;
            IF p_cnt = 1 THEN
                SELECT arbc_impr_name INTO p_name
                  FROM comm_impr_rgstr
                 WHERE bus_id = p_rec.bus_id AND brnch_bus_id = p_rec.bus_id_brnch;
            END IF;
        ELSE
            p_cnt := NULL;
        END IF;
    END COMMERCIAL_REGISTER_NAME;

    FUNCTION NEW_RECORD_CONFIRM_TEXT (p_rec IN T_RECORD, p_ctx IN T_CONTEXT) RETURN VARCHAR2
    IS
        v_cnt  NUMBER;
        v_name VARCHAR2(500);
    BEGIN
        IF p_ctx.code IN ('IMPR1110F1', 'IMPR1110F5')
           AND p_rec.bus_id_type_cd = 2 AND p_rec.impr_type_cd != 12 THEN
            COMMERCIAL_REGISTER_NAME(p_rec, v_cnt, v_name);
            IF v_cnt = 1 THEN
                RETURN ' سيتم تعديل الإسم إلى ( ' || v_name || ' )';
            END IF;
        END IF;
        RETURN NULL;
    END NEW_RECORD_CONFIRM_TEXT;

    -- Source: IMPORTERS.WHEN-NEW-RECORD-INSTANCE
    -- p_answer: answer to the CONFIRM of IMPR1110F1 / IMPR1110F5 (see NEW_RECORD_CONFIRM_TEXT)
    --@ORIG IMPORTERS.WHEN-NEW-RECORD-INSTANCE
    -- >>> Original Forms code: IMPORTERS.WHEN-NEW-RECORD-INSTANCE
    --   DECLARE
    --       V_COUNT NUMBER;
    --       V_IMPR_NAME VARCHAR2(500);
    --         RET NUMBER;
    --         V_CNT NUMBER;
    --   BEGIN
    --   INTRFACE.Make_Field_Entrable('IMPORTERS.COMM_RGSTRTN_TYPE' , FALSE);
    --   INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_EXPRD_DT' , FALSE);
    --   INTRFACE.Make_Field_Entrable('IMPORTERS.CITY_CODE_OF_ID' , FALSE);
    --       :GLOBAL.FUNS_BUSID  := 0;
    --       :GLOBAL.FUNS_IMP    := 0 ;
    --       :GLOBAL.CHK_IMP_TYP := 0;
    --   IF :IMPR_NBR IS NULL THEN
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID' , TRUE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_EXPRD_DT' , TRUE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.ARBC_IMPR_NAME' , TRUE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.CITY_CODE_OF_ID',TRUE);
    --   IF :PARAMETER.P_CLASS_CD=1 AND :PARAMETER.P_USER_TYPE=3 THEN
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_EXPR_TYPE' , FALSE);
    --   ELSE
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_EXPR_TYPE' , TRUE);
    --   END IF;
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_TYPE_CD' , TRUE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_POB_NBR' , TRUE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_ZIP_CD' , TRUE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_TEL_NBR' , TRUE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_FAX_NBR' , TRUE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_TELEX_NBR' , TRUE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.COMM_RGSTRTN_TYPE' , FALSE);
    --   ELSE
    --   GO_ITEM('IMPR_NBR');
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID' , FALSE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_EXPRD_DT' , FALSE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.ARBC_IMPR_NAME' , FALSE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.COMM_RGSTRTN_TYPE' , FALSE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.CITY_CODE_OF_ID',FALSE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_EXPR_TYPE' , FALSE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_TYPE_CD' , FALSE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.BRNH_CITY_CD' , FALSE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_BRNCH', FALSE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_TYPE_CD' , FALSE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.CAR_AGENT_FLAG' , FALSE);
    --   END IF;
    --   IF :PARAMETER.CODE = 'IMPR1110F2' THEN
    --       :GLOBAL.FUNS_BUSID := 1;
    --       INTRFACE.Make_Field_Entrable('IMPORTERS.COMM_RGSTRTN_TYPE' , TRUE);
    --       INTRFACE.Make_Field_Entrable('IMPORTERS.CITY_CODE_OF_ID' , TRUE);
    --       INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID' , TRUE);
    --       INTRFACE.Make_Field_Entrable('IMPORTERS.BRNH_CITY_CD' , TRUE);
    --       INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_BRNCH', TRUE);
    --       GO_ITEM('IMPORTERS.COMM_RGSTRTN_TYPE');
    --       :PARAMETER.CODE:=NULL;
    --   ELSIF :PARAMETER.CODE = 'IMPR1110F1' THEN
    --        IF :BUS_ID_TYPE_CD = 2 AND :IMPR_TYPE_CD!=12  THEN
    --           IF :COMM_RGSTRTN_TYPE = 1 THEN
    --                   SELECT COUNT(BUS_ID) INTO V_CNT FROM COMM_IMPR_RGSTR
    --                   WHERE  BUS_ID=:BUS_ID
    --                    AND   BRNCHREG=0;
    --                   IF V_CNT >1 THEN
    --                    :PARAMETER.CODE:=NULL;
    --                       RET := STR.DispALERT('لا يمكن تعديل الإسم الرجاء مراجعة المساندة الفنية','ERROR');
    --                   RAISE FORM_TRIGGER_FAILURE;
    --               ELSIF V_CNT = 1 THEN
    --                          SELECT ARBC_IMPR_NAME INTO V_IMPR_NAME
    --                        FROM COMM_IMPR_RGSTR
    --                          WHERE BUS_ID   =:BUS_ID
    --                       AND   BRNCHREG =0;
    --                   RET := STR.DispALERT(' سيتم تعديل الإسم إلى ( '||V_IMPR_NAME ||' )' ,'CONFIRM');
    --                     IF Ret = alert_button1 THEN
    --                       :ARBC_IMPR_NAME :=V_IMPR_NAME ;
    --                   END IF;
    --                     :PARAMETER.CODE:=NULL;
    --               ELSE
    --                     :PARAMETER.CODE:=NULL;
    --                          RET := STR.DispALERT('لا يمكن تعديل الإسم الرجاء مراجعة المساندة الفنية','ERROR');
    --                   RAISE FORM_TRIGGER_FAILURE;
    --               END IF;
    --           ELSIF :COMM_RGSTRTN_TYPE = 2 THEN
    --               SELECT COUNT(BUS_ID)INTO V_CNT
    --               FROM  COMM_IMPR_RGSTR
    --               WHERE BUS_ID=:BUS_ID
    --               AND   BRNCH_BUS_ID=:BUS_ID_BRNCH;
    --               IF V_CNT >1 THEN
    --                     :PARAMETER.CODE:=NULL;
    --                       RET := STR.DispALERT('لا يمكن تعديل الإسم الرجاء مراجعة المساندة الفنية','ERROR');
    --                   RAISE FORM_TRIGGER_FAILURE;
    --               ELSIF V_CNT = 1 THEN
    --                   SELECT ARBC_IMPR_NAME INTO V_IMPR_NAME
    --                   FROM COMM_IMPR_RGSTR
    --                   WHERE  BUS_ID=:BUS_ID
    --                   AND   BRNCH_BUS_ID=:BUS_ID_BRNCH;
    --                   RET := STR.DispALERT(' سيتم تعديل الإسم إلى ( '||V_IMPR_NAME ||' )' ,'CONFIRM');
    --                   IF Ret = alert_button1 THEN
    --                       :ARBC_IMPR_NAME :=V_IMPR_NAME ;
    --                   END IF;
    --                     :PARAMETER.CODE:=NULL;
    --               ELSE
    --                       :PARAMETER.CODE:=NULL;
    --                          RET := STR.DispALERT('لا يمكن تعديل الإسم الرجاء مراجعة المساندة الفنية','ERROR');
    --                   RAISE FORM_TRIGGER_FAILURE;
    --               END IF;
    --           ELSE
    --                    :PARAMETER.CODE:=NULL;
    --                          RET := STR.DispALERT('لا يمكن تعديل الإسم الرجاء مراجعة المساندة الفنية','ERROR');
    --                   RAISE FORM_TRIGGER_FAILURE;
    --           END IF;
    --       ELSE
    --            :PARAMETER.CODE:=NULL;
    --           INTRFACE.Make_Field_Entrable('ARBC_IMPR_NAME', TRUE);
    --           GO_ITEM('ARBC_IMPR_NAME');
    --       END IF;
    --       :PARAMETER.CODE:=NULL;
    --   ELSIF :PARAMETER.CODE = 'IMPR1110F5' THEN
    --        IF :BUS_ID_TYPE_CD = 2 AND :IMPR_TYPE_CD!=12  THEN
    --           IF :COMM_RGSTRTN_TYPE = 1 THEN
    --                   SELECT COUNT(BUS_ID) INTO V_CNT FROM COMM_IMPR_RGSTR
    --                   WHERE  BUS_ID=:BUS_ID
    --                    AND   BRNCHREG=0;
    --                   IF V_CNT >1 THEN
    --                    :PARAMETER.CODE:=NULL;
    --                       RET := STR.DispALERT('لا يمكن تعديل الإسم الرجاء مراجعة المساندة الفنية','ERROR');
    --                   RAISE FORM_TRIGGER_FAILURE;
    --               ELSIF V_CNT = 1 THEN
    --                          SELECT ARBC_IMPR_NAME INTO V_IMPR_NAME
    --                        FROM COMM_IMPR_RGSTR
    --                          WHERE BUS_ID   =:BUS_ID
    --                       AND   BRNCHREG =0;
    --                   RET := STR.DispALERT(' سيتم تعديل الإسم إلى ( '||V_IMPR_NAME ||' )' ,'CONFIRM');
    --                     IF Ret = alert_button1 THEN
    --                       :ARBC_IMPR_NAME :=V_IMPR_NAME ;
    --                   ELSE
    --                       INTRFACE.Make_Field_Entrable('ARBC_IMPR_NAME', TRUE);
    --                       GO_ITEM('ARBC_IMPR_NAME');
    --                   END IF;
    --                     :PARAMETER.CODE:=NULL;
    --               ELSE
    --                   INTRFACE.Make_Field_Entrable('ARBC_IMPR_NAME', TRUE);
    --                   GO_ITEM('ARBC_IMPR_NAME');
    --                     :PARAMETER.CODE:=NULL;
    --               END IF;
    --           ELSIF :COMM_RGSTRTN_TYPE = 2 THEN
    --               SELECT COUNT(BUS_ID)INTO V_CNT
    --               FROM  COMM_IMPR_RGSTR
    --               WHERE BUS_ID=:BUS_ID
    --               AND   BRNCH_BUS_ID=:BUS_ID_BRNCH;
    --               IF V_CNT >1 THEN
    --                     :PARAMETER.CODE:=NULL;
    --                       RET := STR.DispALERT('لا يمكن تعديل الإسم الرجاء مراجعة المساندة الفنية','ERROR');
    --                   RAISE FORM_TRIGGER_FAILURE;
    --               ELSIF V_CNT = 1 THEN
    --                   SELECT ARBC_IMPR_NAME INTO V_IMPR_NAME
    --                   FROM COMM_IMPR_RGSTR
    --                   WHERE  BUS_ID=:BUS_ID
    --                   AND   BRNCH_BUS_ID=:BUS_ID_BRNCH;
    --                   RET := STR.DispALERT(' سيتم تعديل الإسم إلى ( '||V_IMPR_NAME ||' )' ,'CONFIRM');
    --                   IF Ret = alert_button1 THEN
    --                       :ARBC_IMPR_NAME :=V_IMPR_NAME ;
    --                   ELSE
    --                       INTRFACE.Make_Field_Entrable('ARBC_IMPR_NAME', TRUE);
    --                       GO_ITEM('ARBC_IMPR_NAME');
    --                   END IF;
    --                     :PARAMETER.CODE:=NULL;
    --               ELSE
    --                      INTRFACE.Make_Field_Entrable('ARBC_IMPR_NAME', TRUE);
    --                   GO_ITEM('ARBC_IMPR_NAME');
    --               END IF;
    --           ELSE
    --                      INTRFACE.Make_Field_Entrable('ARBC_IMPR_NAME', TRUE);
    --                   GO_ITEM('ARBC_IMPR_NAME');
    --           END IF;
    --       ELSE
    --           INTRFACE.Make_Field_Entrable('ARBC_IMPR_NAME', TRUE);
    --           GO_ITEM('ARBC_IMPR_NAME');
    --       END IF;
    --       :PARAMETER.CODE:=NULL;
    --   ELSIF :PARAMETER.CODE = 'IMPR1110F3' THEN
    --       :GLOBAL.FUNS_IMP := 1 ;
    --       :GLOBAL.CHK_IMP_TYP := 1;
    --       INTRFACE.Make_Field_Entrable('IMPR_TYPE_CD', TRUE);
    --       GO_ITEM('IMPR_TYPE_CD');
    --           IF :PARAMETER.P_CLASS_CD = 19 AND :PARAMETER.P_USER_TYPE = 1 THEN
    --           IF :IMPR_TYPE_CD <> 4 THEN
    --               INTRFACE.MAKE_BLOCK_FULL_OPERATION('IMPORTERS',FALSE,TRUE,FALSE);
    --               :IMPR_TYPE_CD := 19;
    --               STR.DISPALERT(' تم تعديل النشاط التجاري الى "مؤسسة/شركة/استثمارية "  ','INFORMATION');
    --               COMMIT;
    --               INTRFACE.MAKE_BLOCK_FULL_OPERATION('IMPORTERS',FALSE,FALSE,FALSE);
    --           END IF ;
    --           IF :IMPR_TYPE_CD = 4 THEN
    --                 STR.DISPALERT('لا يمكن التعديل  للمستورد الشخصي الا من خلال الدعم الفني التطبيقات','ERROR');
    --           END IF ;
    --           END IF;
    --       :PARAMETER.CODE:=NULL;
    --   ELSIF :PARAMETER.CODE = 'IMPR1110F4' THEN
    --         INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_EXPRD_DT',TRUE);
    --       GO_ITEM('IMPORTERS.BUS_ID_EXPRD_DT');
    --         :PARAMETER.CODE:=NULL;
    --   ELSIF :PARAMETER.CODE = 'IMPR1110SF6' THEN
    --         INTRFACE.Make_Field_Entrable('IMPORTERS.CAR_AGENT_FLAG',TRUE);
    --       GO_ITEM('IMPORTERS.CAR_AGENT_FLAG');
    --         :PARAMETER.CODE:=NULL;
    --    END IF;
    --   END;
    --           SET_ITEM_PROPERTY('IMPORTERS.CITY_CODE_OF_ID' ,REQUIRED,PROPERTY_FALSE);
    --           SET_ITEM_PROPERTY('IMPORTERS.BRNH_CITY_CD' ,REQUIRED,PROPERTY_FALSE);
    --   declare
    --             RET NUMBER;
    --   BEGIN
    --   IF :IMPR_TYPE_CD = 4  AND  :BUS_ID_TYPE_CD = 3
    --   OR :IMPR_TYPE_CD = 4  AND  :BUS_ID_TYPE_CD = 5 THEN
    --   :CTRY_CD := 100;
    --   SET_ITEM_PROPERTY('CTRY_CD', ENABLED,PROPERTY_FALSE);
    --   SELECT CRTY_ARBC_NAME INTO :CRTY_ARBC_NAME
    --    FROM   COUNTRIES
    --    WHERE  CTRY_CD = 100;
    --   END IF;
    --   :ADD_CTRY_CD := 100 ;
    --   SET_ITEM_PROPERTY('ADD_CTRY_CD', ENABLED,PROPERTY_FALSE);
    --   SELECT CRTY_ARBC_NAME INTO :ADD_CRTY_ARBC_NAME
    --    FROM   COUNTRIES
    --    WHERE  CTRY_CD = 100;
    --   EXCEPTION
    --   WHEN NO_DATA_FOUND THEN
    --     ret := Str.DispArbMsg(18, 15,'ERROR');
    --     RAISE FORM_TRIGGER_FAILURE;
    --   END;
    -- <<<
    PROCEDURE IMPORTERS_NEW_RECORD_INSTANCE (p_rec    IN OUT NOCOPY T_RECORD,
                              p_ctx    IN OUT NOCOPY T_CONTEXT,
                              p_answer IN PLS_INTEGER DEFAULT c_yes)
    IS
        v_cnt       NUMBER;
        v_impr_name VARCHAR2(500);
        c_no_rename CONSTANT VARCHAR2(100) := 'لا يمكن تعديل الإسم الرجاء مراجعة المساندة الفنية';
    BEGIN
        NULL;  -- APEX (read_only_rules.md): entrable('COMM_RGSTRTN_TYPE', FALSE);
        NULL;  -- APEX (read_only_rules.md): entrable('BUS_ID_EXPRD_DT', FALSE);
        NULL;  -- APEX (read_only_rules.md): entrable('CITY_CODE_OF_ID', FALSE);
        SET_GLOBAL('FUNS_BUSID', '0');
        SET_GLOBAL('FUNS_IMP', '0');
        SET_GLOBAL('CHK_IMP_TYP', '0');
        IF p_rec.impr_nbr IS NULL THEN
            NULL;  -- APEX (read_only_rules.md): entrable('BUS_ID', TRUE);
            NULL;  -- APEX (read_only_rules.md): entrable('BUS_ID_EXPRD_DT', TRUE);
            NULL;  -- APEX (read_only_rules.md): entrable('ARBC_IMPR_NAME', TRUE);
            NULL;  -- APEX (read_only_rules.md): entrable('CITY_CODE_OF_ID', TRUE);
            IF p_ctx.class_cd = 1 AND p_ctx.user_type = 3 THEN
                NULL;  -- APEX (read_only_rules.md): entrable('IMPR_EXPR_TYPE', FALSE);
            ELSE
                NULL;  -- APEX (read_only_rules.md): entrable('IMPR_EXPR_TYPE', TRUE);
            END IF;
            NULL;  -- APEX (read_only_rules.md): entrable('IMPR_TYPE_CD', TRUE);
            NULL;  -- APEX (read_only_rules.md): entrable('IMPR_POB_NBR', TRUE);
            NULL;  -- APEX (read_only_rules.md): entrable('IMPR_ZIP_CD', TRUE);
            NULL;  -- APEX (read_only_rules.md): entrable('IMPR_TEL_NBR', TRUE);
            NULL;  -- APEX (read_only_rules.md): entrable('IMPR_FAX_NBR', TRUE);
            NULL;  -- APEX (read_only_rules.md): entrable('IMPR_TELEX_NBR', TRUE);
            NULL;  -- APEX (read_only_rules.md): entrable('COMM_RGSTRTN_TYPE', FALSE);
        ELSE
            NULL;  -- APEX (read_only_rules.md): ui_focus('IMPR_NBR');
            NULL;  -- APEX (read_only_rules.md): entrable('BUS_ID', FALSE);
            NULL;  -- APEX (read_only_rules.md): entrable('BUS_ID_EXPRD_DT', FALSE);
            NULL;  -- APEX (read_only_rules.md): entrable('ARBC_IMPR_NAME', FALSE);
            NULL;  -- APEX (read_only_rules.md): entrable('COMM_RGSTRTN_TYPE', FALSE);
            NULL;  -- APEX (read_only_rules.md): entrable('CITY_CODE_OF_ID', FALSE);
            NULL;  -- APEX (read_only_rules.md): entrable('IMPR_EXPR_TYPE', FALSE);
            NULL;  -- APEX (read_only_rules.md): entrable('IMPR_TYPE_CD', FALSE);
            NULL;  -- APEX (read_only_rules.md): entrable('BRNH_CITY_CD', FALSE);
            NULL;  -- APEX (read_only_rules.md): entrable('BUS_ID_BRNCH', FALSE);
            NULL;  -- APEX (read_only_rules.md): entrable('BUS_ID_TYPE_CD', FALSE);
            NULL;  -- APEX (read_only_rules.md): entrable('CAR_AGENT_FLAG', FALSE);
        END IF;

        IF p_ctx.code = 'IMPR1110F2' THEN
            SET_GLOBAL('FUNS_BUSID', '1');
            NULL;  -- APEX (read_only_rules.md): entrable('COMM_RGSTRTN_TYPE', TRUE);
            NULL;  -- APEX (read_only_rules.md): entrable('CITY_CODE_OF_ID', TRUE);
            NULL;  -- APEX (read_only_rules.md): entrable('BUS_ID', TRUE);
            NULL;  -- APEX (read_only_rules.md): entrable('BRNH_CITY_CD', TRUE);
            NULL;  -- APEX (read_only_rules.md): entrable('BUS_ID_BRNCH', TRUE);
            NULL;  -- APEX (read_only_rules.md): ui_focus('COMM_RGSTRTN_TYPE');
            p_ctx.code := NULL;
        ELSIF p_ctx.code = 'IMPR1110F1' THEN
            IF p_rec.bus_id_type_cd = 2 AND p_rec.impr_type_cd != 12 THEN
                IF p_rec.comm_rgstrtn_type IN (1, 2) THEN
                    COMMERCIAL_REGISTER_NAME(p_rec, v_cnt, v_impr_name);
                    IF v_cnt > 1 THEN
                        p_ctx.code := NULL;
                        FORM_TRIGGER_FAILURE(c_no_rename);
                    ELSIF v_cnt = 1 THEN
                        IF p_answer = c_yes THEN       -- CONFIRM: NEW_RECORD_CONFIRM_TEXT
                            p_rec.arbc_impr_name := v_impr_name;
                        END IF;
                        p_ctx.code := NULL;
                    ELSE
                        p_ctx.code := NULL;
                        FORM_TRIGGER_FAILURE(c_no_rename);
                    END IF;
                ELSE
                    p_ctx.code := NULL;
                    FORM_TRIGGER_FAILURE(c_no_rename);
                END IF;
            ELSE
                p_ctx.code := NULL;
                NULL;  -- APEX (read_only_rules.md): entrable('ARBC_IMPR_NAME', TRUE);
                NULL;  -- APEX (read_only_rules.md): ui_focus('ARBC_IMPR_NAME');
            END IF;
            p_ctx.code := NULL;
        ELSIF p_ctx.code = 'IMPR1110F5' THEN
            IF p_rec.bus_id_type_cd = 2 AND p_rec.impr_type_cd != 12 THEN
                IF p_rec.comm_rgstrtn_type IN (1, 2) THEN
                    COMMERCIAL_REGISTER_NAME(p_rec, v_cnt, v_impr_name);
                    IF v_cnt > 1 THEN
                        p_ctx.code := NULL;
                        FORM_TRIGGER_FAILURE(c_no_rename);
                    ELSIF v_cnt = 1 THEN
                        IF p_answer = c_yes THEN       -- CONFIRM: NEW_RECORD_CONFIRM_TEXT
                            p_rec.arbc_impr_name := v_impr_name;
                        ELSE
                            NULL;  -- APEX (read_only_rules.md): entrable('ARBC_IMPR_NAME', TRUE);
                            NULL;  -- APEX (read_only_rules.md): ui_focus('ARBC_IMPR_NAME');
                        END IF;
                        p_ctx.code := NULL;
                    ELSE
                        NULL;  -- APEX (read_only_rules.md): entrable('ARBC_IMPR_NAME', TRUE);
                        NULL;  -- APEX (read_only_rules.md): ui_focus('ARBC_IMPR_NAME');
                        IF p_rec.comm_rgstrtn_type = 1 THEN   -- Forms resets CODE only in this branch
                            p_ctx.code := NULL;
                        END IF;
                    END IF;
                ELSE
                    NULL;  -- APEX (read_only_rules.md): entrable('ARBC_IMPR_NAME', TRUE);
                    NULL;  -- APEX (read_only_rules.md): ui_focus('ARBC_IMPR_NAME');
                END IF;
            ELSE
                NULL;  -- APEX (read_only_rules.md): entrable('ARBC_IMPR_NAME', TRUE);
                NULL;  -- APEX (read_only_rules.md): ui_focus('ARBC_IMPR_NAME');
            END IF;
            p_ctx.code := NULL;
        ELSIF p_ctx.code = 'IMPR1110F3' THEN
            SET_GLOBAL('FUNS_IMP', '1');
            SET_GLOBAL('CHK_IMP_TYP', '1');
            NULL;  -- APEX (read_only_rules.md): entrable('IMPR_TYPE_CD', TRUE);
            NULL;  -- APEX (read_only_rules.md): ui_focus('IMPR_TYPE_CD');
            IF p_ctx.class_cd = 19 AND p_ctx.user_type = 1 THEN
                IF p_rec.impr_type_cd <> 4 THEN
                    -- INTRFACE.MAKE_BLOCK_FULL_OPERATION('IMPORTERS',FALSE,TRUE,FALSE): update only
                    NULL;  -- APEX (read_only_rules.md): ui('IMPORTERS', 'BLOCK_UPDATE_ONLY', TRUE);
                    p_rec.impr_type_cd := 19;
                    info(' تم تعديل النشاط التجاري الى "مؤسسة/شركة/استثمارية "  ');
                    -- HIGH: Forms COMMIT here (fires PRE-UPDATE/UPDATE/POST-UPDATE). Recorded as
                    -- DO_COMMIT: the page must submit with request SAVE right after this call.
                    NULL;  -- APEX (read_only_rules.md): ui('IMPORTERS', 'DO_COMMIT', TRUE);
                END IF;
                IF p_rec.impr_type_cd = 4 THEN
                    info('لا يمكن التعديل  للمستورد الشخصي الا من خلال الدعم الفني التطبيقات');
                END IF;
            END IF;
            p_ctx.code := NULL;
        ELSIF p_ctx.code = 'IMPR1110F4' THEN
            NULL;  -- APEX (read_only_rules.md): entrable('BUS_ID_EXPRD_DT', TRUE);
            NULL;  -- APEX (read_only_rules.md): ui_focus('BUS_ID_EXPRD_DT');
            p_ctx.code := NULL;
        ELSIF p_ctx.code = 'IMPR1110SF6' THEN
            NULL;  -- APEX (read_only_rules.md): entrable('CAR_AGENT_FLAG', TRUE);
            NULL;  -- APEX (read_only_rules.md): ui_focus('CAR_AGENT_FLAG');
            p_ctx.code := NULL;
        END IF;

        NULL;  -- APEX (read_only_rules.md): ui('CITY_CODE_OF_ID', 'REQUIRED', FALSE);
        NULL;  -- APEX (read_only_rules.md): ui('BRNH_CITY_CD', 'REQUIRED', FALSE);
        ctry_100_defaults(p_rec);
    END IMPORTERS_NEW_RECORD_INSTANCE;

    -- Source: IMPORTERS.PRE-RECORD
    --@ORIG IMPORTERS.PRE-RECORD
    -- >>> Original Forms code: IMPORTERS.PRE-RECORD
    --   DECLARE
    --       ret NUMBER;
    --       CURSOR C_P_NAME IS
    --               SELECT ARBC_IMPR_NAME
    --           FROM IMPORTERS
    --           WHERE IMPR_NBR = :IMPR_NBR_PARENT
    --               AND PORT_CD=:PARAMETER.P_CURR_PORT_CD;
    --   BEGIN
    --   IF :IMPR_NBR_PARENT IS NOT NULL THEN
    --       OPEN C_P_NAME;
    --       FETCH C_P_NAME INTO :IMPR_NAME_PARENT;
    --       IF C_P_NAME%NOTFOUND THEN
    --           ret := Str.DispArbMsg(9, 150,'ERROR');
    --       END IF;
    --       CLOSE C_P_NAME;
    --   END IF;
    --   END;
    -- <<<
    PROCEDURE IMPORTERS_PRE_RECORD (p_rec IN OUT NOCOPY T_RECORD, p_ctx IN T_CONTEXT)
    IS
        CURSOR c_p_name IS
            SELECT arbc_impr_name
              FROM importers
             WHERE impr_nbr = p_rec.impr_nbr_parent
               AND port_cd  = p_ctx.curr_port_cd;
    BEGIN
        IF p_rec.impr_nbr_parent IS NOT NULL THEN
            OPEN c_p_name;
            FETCH c_p_name INTO p_rec.impr_name_parent;
            IF c_p_name%NOTFOUND THEN
                DISPLAY_ARABIC_INFO(9, 150);
            END IF;
            CLOSE c_p_name;
        END IF;
    END IMPORTERS_PRE_RECORD;

    -- Source: IMPORTERS.WHEN-CLEAR-BLOCK
    PROCEDURE IMPORTERS_WHEN_CLEAR_BLOCK
    IS
    BEGIN
        SET_GLOBAL('STAT_CLR', '1');
    END IMPORTERS_WHEN_CLEAR_BLOCK;

    -- Source: IMPORTERS.POST-QUERY
    --@ORIG IMPORTERS.POST-QUERY
    -- >>> Original Forms code: IMPORTERS.POST-QUERY
    --   DECLARE
    --   V_COUNT NUMBER := 0 ;
    --   XDT DATE ;
    --   BEGIN
    --   :GLOBAL.OLD_impr_type_cd :=  :impr_type_cd ;
    --   :GLOBAL.OLD_PORT_CD      := :PORT_CD ;
    --   IF :IMPORTERS.IMPR_NBR IS NOT NULL THEN
    --       BEGIN
    --           XDT := HIJDATE.Cur_Hij_Date ;
    --           SELECT COUNT(*) INTO V_COUNT
    --           FROM IMPORTERS IMP, IMPR_SUSPNS IS_1
    --           WHERE
    --           IMP.PORT_CD = :IMPORTERS.PORT_CD AND
    --           IMP.IMPR_NBR = :IMPORTERS.IMPR_NBR  AND
    --           IS_1.PORT_CD = IMP.PORT_CD AND
    --           IS_1.IMPR_NBR = IMP.IMPR_NBR AND
    --           TO_CHAR(IS_1.SUSPN_STRT_DT, 'YYYY-MM-MI') <= TO_CHAR(XDT, 'YYYY-MM-MI') AND
    --           TO_CHAR(IS_1.SUSPN_END_DT, 'YYYY-MM-MI') >= TO_CHAR(XDT, 'YYYY-MM-MI') AND
    --           IS_1.SUSPN_RLSE_DT IS NULL;
    --               IF  V_COUNT >= 1 THEN
    --                   :IMPORTERS.SUSPN_STATUS := 'موقوف';
    --               ELSE
    --                   :IMPORTERS.SUSPN_STATUS := 'غير موقوف';
    --               END IF;
    --       IF V_COUNT = 0 THEN
    --               SELECT COUNT(*) INTO V_COUNT
    --               FROM   IMPR_DUTY_DIFF_BLKS
    --               WHERE  HQ_IMPR_NBR = :HQ_IMPR_NBR
    --               AND    BLK_RLS_DT IS NULL
    --               ;
    --               IF  V_COUNT > 0 THEN
    --               SELECT COUNT (*) INTO V_COUNT
    --     FROM (SELECT 1
    --             FROM duty_diff_blk_exp_dtls d1, stats_dcltns d2, importers d3
    --            WHERE d1.stats_isn IS NOT NULL
    --              AND d1.dcltn_stat_port_cd = d2.port_cd
    --              AND d1.stats_isn = d2.stats_isn
    --              AND d2.port_cd = d3.port_cd
    --              AND d2.impr_expr_nbr = d3.impr_nbr
    --              AND d3.hq_impr_nbr = :hq_impr_nbr
    --              AND d2.stats_status NOT IN (7, 8, 10)
    --           UNION ALL
    --           SELECT 1
    --             FROM duty_diff_blk_exp_dtls d1, declarations d2, importers d3
    --            WHERE d1.dcltn_isn IS NOT NULL
    --              AND d1.dcltn_stat_port_cd = d2.port_cd
    --              AND d1.dcltn_isn = d2.dcltn_isn
    --              AND d2.port_cd = d3.port_cd
    --              AND d2.impr_nbr = d3.impr_nbr
    --              AND d3.hq_impr_nbr = :hq_impr_nbr
    --              AND d2.dcltn_sta_cd <> 9
    --           UNION ALL
    --           SELECT 1
    --             FROM duty_diff_blk_exp_dtls d1
    --            WHERE d1.from_date IS NOT NULL
    --              AND d1.hq_impr_nbr = :hq_impr_nbr
    --              AND hijdate_db.cur_hij_date BETWEEN d1.from_date AND d1.TO_DATE);
    --   IF NVL (gnrl.get_customs_setting ('CRQ24602_RUN', 21), 0) =  0 THEN
    --               IF V_COUNT = 0 THEN
    --                   :IMPORTERS.SUSPN_STATUS := 'موقوف(تدقيق عام)';
    --               else
    --                   :IMPORTERS.SUSPN_STATUS := 'موقوف(تدقيق)له استثناء';
    --               END IF;
    --   elsif NVL (gnrl.get_customs_setting ('CRQ24602_RUN', 21), 0) =  1 THEN
    --               IF V_COUNT = 0 THEN
    --                   :IMPORTERS.SUSPN_STATUS := '';
    --               ELSE
    --                   :IMPORTERS.SUSPN_STATUS := '';
    --               END IF;
    --   END IF;
    --       END IF;
    --           END IF;
    --           IF V_COUNT = 0 THEN
    --               DECLARE
    --                   V_SUSPN_RSN_TEXT VARCHAR2(2000) := '';
    --               BEGIN
    --                   SELECT SUSPN_RSN_TEXT INTO V_SUSPN_RSN_TEXT
    --                   FROM   IMPR_CNTRL_SUSPNS
    --                   WHERE  HQ_IMPR_NBR = :HQ_IMPR_NBR
    --                   AND    TO_CHAR(SUSPN_STRT_DT, 'YYYY-MM-MI') <= TO_CHAR(XDT, 'YYYY-MM-MI')
    --                   AND    TO_CHAR(SUSPN_END_DT, 'YYYY-MM-MI') >= TO_CHAR(XDT, 'YYYY-MM-MI')
    --                   AND    SUSPN_RLSE_DT  IS NULL;
    --                   :IMPORTERS.SUSPN_STATUS := 'إيقاف مركزي من قبل المصلحة - إدارة القيود بسبب '||V_SUSPN_RSN_TEXT;
    --               EXCEPTION
    --                   WHEN NO_DATA_FOUND THEN NULL;
    --               END;
    --           END IF;
    --       EXCEPTION    WHEN OTHERS THEN
    --           NULL;
    --       END;
    --   END IF;
    --   :B_MOBILE_NO := :MOBILE_NO;
    --   :B_ID_NBR := :ID_NBR;
    --   :B_EMAIL := :EMAIL;
    --   :GLOBAL.STAT_QUE:=1;
    --       IF :IMPORTERS.IMPR_TYPE_CD = 1 THEN
    --           INTRFACE.Make_Field_Entrable('IMPORTERS.CTRY_CD' , FALSE);
    --           INTRFACE.Make_Field_Entrable('IMPORTERS.ADD_CTRY_CD' , FALSE);
    --       ELSIF :IMPORTERS.IMPR_TYPE_CD = 2 THEN
    --           INTRFACE.Make_Field_Entrable('IMPORTERS.CTRY_CD' , FALSE);
    --           INTRFACE.Make_Field_Entrable('IMPORTERS.ADD_CTRY_CD' , FALSE);
    --           INTRFACE.Make_Field_Entrable('IMPORTERS.CITY_CODE_OF_ID' , FALSE);
    --           SET_ITEM_PROPERTY('IMPORTERS.CITY_CODE_OF_ID2' , ENABLED , PROPERTY_FALSE);
    --           INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_BRNCH' , FALSE);
    --       ELSIF :IMPORTERS.IMPR_TYPE_CD = 4 THEN
    --           INTRFACE.Make_Field_Entrable('IMPORTERS.CITY_CODE_OF_ID' , FALSE);
    --           SET_ITEM_PROPERTY('IMPORTERS.CITY_CODE_OF_ID2' , ENABLED , PROPERTY_FALSE);
    --           INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_BRNCH' , FALSE);
    --       ELSIF :IMPORTERS.IMPR_TYPE_CD = 5 THEN
    --           INTRFACE.Make_Field_Entrable('IMPORTERS.CTRY_CD' , FALSE);
    --           INTRFACE.Make_Field_Entrable('IMPORTERS.ADD_CTRY_CD' , FALSE);
    --       ELSIF :IMPORTERS.IMPR_TYPE_CD = 7 THEN
    --           INTRFACE.Make_Field_Entrable('IMPORTERS.CITY_CODE_OF_ID' , FALSE);
    --           SET_ITEM_PROPERTY('IMPORTERS.CITY_CODE_OF_ID2' , ENABLED , PROPERTY_FALSE);
    --           INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_BRNCH' , FALSE);
    --       ELSIF :IMPORTERS.IMPR_TYPE_CD = 8 THEN
    --           INTRFACE.Make_Field_Entrable('IMPORTERS.CTRY_CD' , FALSE);
    --           INTRFACE.Make_Field_Entrable('IMPORTERS.ADD_CTRY_CD' , FALSE);
    --       ELSIF :IMPORTERS.IMPR_TYPE_CD = 9 THEN
    --           IF :IMPORTERS.BUS_ID_TYPE_CD = 6 THEN
    --               INTRFACE.Make_Field_Entrable('IMPORTERS.CTRY_CD' , FALSE);
    --               INTRFACE.Make_Field_Entrable('IMPORTERS.ADD_CTRY_CD' , FALSE);
    --               INTRFACE.Make_Field_Entrable('IMPORTERS.CITY_CODE_OF_ID' , FALSE);
    --               SET_ITEM_PROPERTY('IMPORTERS.CITY_CODE_OF_ID2' , ENABLED , PROPERTY_FALSE);
    --               INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_BRNCH' , FALSE);
    --               INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID' , FALSE);
    --           ELSE
    --               INTRFACE.Make_Field_Entrable('IMPORTERS.CTRY_CD' , TRUE);
    --               INTRFACE.Make_Field_Entrable('IMPORTERS.ADD_CTRY_CD' , TRUE);
    --               INTRFACE.Make_Field_Entrable('IMPORTERS.CITY_CODE_OF_ID' , TRUE);
    --               SET_ITEM_PROPERTY('IMPORTERS.CITY_CODE_OF_ID2' , ENABLED , PROPERTY_TRUE);
    --               INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID' , TRUE);
    --               INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_BRNCH' , FALSE);
    --           END IF;
    --       ELSIF :IMPORTERS.IMPR_TYPE_CD = 10 THEN
    --               INTRFACE.Make_Field_Entrable('IMPORTERS.CITY_CODE_OF_ID' , FALSE);
    --               SET_ITEM_PROPERTY('IMPORTERS.CITY_CODE_OF_ID2' , ENABLED , PROPERTY_FALSE);
    --               INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_BRNCH' , FALSE);
    --       ELSIF :IMPORTERS.IMPR_TYPE_CD = 11 THEN
    --               INTRFACE.Make_Field_Entrable('IMPORTERS.CTRY_CD' , FALSE);
    --               INTRFACE.Make_Field_Entrable('IMPORTERS.ADD_CTRY_CD' , FALSE);
    --               INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_BRNCH' , FALSE);
    --       ELSIF :IMPORTERS.IMPR_TYPE_CD = 12 THEN
    --               INTRFACE.Make_Field_Entrable('IMPORTERS.CITY_CODE_OF_ID' , FALSE);
    --               SET_ITEM_PROPERTY('IMPORTERS.CITY_CODE_OF_ID2' , ENABLED , PROPERTY_FALSE);
    --       ELSIF :IMPORTERS.IMPR_TYPE_CD IN (13, 14) THEN
    --               INTRFACE.Make_Field_Entrable('IMPORTERS.CTRY_CD' , FALSE);
    --               INTRFACE.Make_Field_Entrable('IMPORTERS.ADD_CTRY_CD' , FALSE);
    --               INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID' , FALSE);
    --               INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_BRNCH' , FALSE);
    --               INTRFACE.Make_Field_Entrable('IMPORTERS.CITY_CODE_OF_ID' , FALSE);
    --               SET_ITEM_PROPERTY('IMPORTERS.CITY_CODE_OF_ID2' , ENABLED , PROPERTY_FALSE);
    --       END IF;
    --   DECLARE
    --   V_USER_BUS_ID VARCHAR2(4);
    --   BEGIN
    --      IF :IMPORTERS.BUS_ID_TYPE_CD = 2 AND :IMPORTERS.IMPR_TYPE_CD != 12  THEN
    --         IF :BUS_ID_BRNCH IS NOT NULL THEN
    --           BEGIN
    --             V_USER_BUS_ID := SUBSTR(:IMPORTERS.BUS_ID_BRNCH, 1, 4);
    --             SELECT  CITY_CD,CITY_ARB_NAME INTO  :IMPORTERS.BRNH_CITY_CD,:IMPORTERS.BRNH_CITY_NAME
    --           FROM    CITIES
    --           WHERE   CTRY_CD      = 100
    --             AND     MINS_COMM_CD = V_USER_BUS_ID ;
    --           EXCEPTION
    --             WHEN OTHERS THEN
    --            NULL;
    --           END;
    --         END IF;
    --      END IF;
    --   END;
    --   END;
    --   BEGIN
    --      SELECT status_desc
    --        INTO :importers.status_desc
    --        FROM mci_bus_id_status
    --       WHERE bus_id_status LIKE :importers.bus_id_status;
    --   EXCEPTION
    --      WHEN OTHERS THEN NULL;
    --   END;
    --   DECLARE
    --   V_EXPIRY_DATE DATE;
    --   V_DUMMY NUMBER(1);
    --   begin
    --     SELECT MAX(EXPIRY_DATE)
    --     INTO   V_EXPIRY_DATE
    --       FROM   PRIVILEGED_IMPORTERS
    --       WHERE  IMPR_PRIVILEGE_TYPE = 3
    --       AND    REC_STATUS = 1
    --       AND    IMPR_NBR = :IMPORTERS.IMPR_NBR;
    --       IF V_EXPIRY_DATE IS NOT NULL THEN
    --           IF V_EXPIRY_DATE < hijdate_db.cur_hij_date THEN
    --               :IMPR_ID_TYPE := 'اقامة عادية';
    --           ELSE
    --               :IMPR_ID_TYPE := 'اقامة مميزة محددة المدة تنتهي بتاريخ '||TO_CHAR(V_EXPIRY_DATE,'MI-MM-YYYY');
    --           END IF;
    --       ELSE
    --         BEGIN
    --         SELECT 1
    --           INTO   V_DUMMY
    --           FROM   PRIVILEGED_IMPORTERS
    --           WHERE  IMPR_PRIVILEGE_TYPE = 3
    --         AND    REC_STATUS = 1
    --           AND    IMPR_NBR = :IMPORTERS.IMPR_NBR
    --           AND    ROWNUM  =  1;
    --           :IMPR_ID_TYPE := 'اقامة مميزة دائمة ';
    --         EXCEPTION
    --             WHEN NO_DATA_FOUND THEN
    --                  :IMPR_ID_TYPE := 'عادية';
    --         END;
    --       END IF;
    --   END;
    --   ADJ_FUNS;
    --   BEGIN
    --     IF (name_in('IMPORTERS.PORT_CD') IS NOT NULL) THEN
    --       BEGIN
    --        SELECT L_SDP.PORT_STATUS,L_SDP.PORT_NAME
    --               INTO  :IMPORTERS.SDP_PORT_STATUS,:IMPORTERS.PORT_NAME
    --         FROM   SD_PORTS L_SDP
    --         WHERE  L_SDP.PORT_CD = :IMPORTERS.PORT_CD;
    --       EXCEPTION
    --         WHEN NO_DATA_FOUND THEN
    --           Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(13, 'This <p1> does not exist', 'رمز الجمــــــــــــــرك' ), 'E', 'OFG', 13);
    --         WHEN OTHERS THEN
    --           CGTE$OTHER_EXCEPTIONS;
    --       END;
    --       SET_RECORD_PROPERTY(:SYSTEM.TRIGGER_RECORD, 'IMPORTERS', STATUS ,                 QUERY_STATUS);
    --     END IF;
    --     IF (name_in('IMPORTERS.IMPR_TYPE_CD') IS NOT NULL AND name_in('IMPORTERS.BUS_ID_TYPE_CD') IS NOT NULL) THEN
    --       BEGIN
    --         CGFK$QRY_IMPORTERS_IMP_ITIDT_F(
    --           :IMPORTERS.BUS_ID_TYPE_NAME
    --          ,:IMPORTERS.IMPR_TYPE_NAME
    --          ,:IMPORTERS.STATUS
    --          ,:IMPORTERS.ITIDT_NOTE
    --          ,:IMPORTERS.IMPR_TYPE_CD
    --          ,:IMPORTERS.BUS_ID_TYPE_CD  );
    --       EXCEPTION
    --         WHEN NO_DATA_FOUND THEN
    --           Des$Form_errors.PUSH('رمز النشاط التجاري غير صحيح - أعد إدخال البيانات', 'E', 'OFG', 0);
    --         WHEN OTHERS THEN
    --           CGTE$OTHER_EXCEPTIONS;
    --       END;
    --       SET_RECORD_PROPERTY(:SYSTEM.TRIGGER_RECORD, 'IMPORTERS', STATUS ,                 QUERY_STATUS);
    --     ELSE
    --         Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(78, '<p1> must be entered', 'رمز النشاط التجارى' ), 'E', 'OFG', 78);
    --         Des$Form_errors.RAISE_FAILURE;
    --     END IF;
    --     IF (name_in('IMPORTERS.CTRY_CD') IS NOT NULL) THEN
    --       BEGIN
    --         CGFK$QRY_IMPORTERS_IMP_CTRY_FK(
    --           :IMPORTERS.CTRY_CTRY_STATUS
    --          ,:IMPORTERS.CRTY_ARBC_NAME
    --          ,:IMPORTERS.CTRY_CD         );
    --       EXCEPTION
    --         WHEN NO_DATA_FOUND THEN
    --           Des$Form_errors.PUSH('رمز الدولة غير صحيح - أعد ادخال البيانات', 'E', 'OFG', 0);
    --         WHEN OTHERS THEN
    --           CGTE$OTHER_EXCEPTIONS;
    --       END;
    --       SET_RECORD_PROPERTY(:SYSTEM.TRIGGER_RECORD, 'IMPORTERS', STATUS ,                 QUERY_STATUS);
    --     END IF;
    --     IF (name_in('IMPORTERS.CITY_CODE_OF_ID') IS NOT NULL AND name_in('IMPORTERS.CTRY_CD_OF_ID') IS NOT NULL) THEN
    --       BEGIN
    --         CGFK$QRY_IMPORTERS_IMP_BUS_ID_(
    --           :IMPORTERS.ID_MINS_COMM_CD
    --          ,:IMPORTERS.ID_CITY_NAME
    --          ,:IMPORTERS.L_CT_CITY_STATUS2
    --          ,:IMPORTERS.CTRY_CD_OF_ID
    --          ,:IMPORTERS.CITY_CODE_OF_ID  );
    --       EXCEPTION
    --         WHEN NO_DATA_FOUND THEN
    --           Des$Form_errors.PUSH('خطأ في رمز مدينة مصدر الرقم الإستدلالي', 'E', 'OFG', 0);
    --         WHEN OTHERS THEN
    --           CGTE$OTHER_EXCEPTIONS;
    --       END;
    --       SET_RECORD_PROPERTY(:SYSTEM.TRIGGER_RECORD, 'IMPORTERS', STATUS ,                 QUERY_STATUS);
    --     END IF;
    --     IF (name_in('IMPORTERS.ADD_CTRY_CD') IS NOT NULL AND name_in('IMPORTERS.CITY_CODE') IS NOT NULL) THEN
    --       BEGIN
    --         CGFK$QRY_IMPORTERS_IMP_ADD_CIT(
    --           :IMPORTERS.ADD_CRTY_ARBC_NAME
    --          ,:IMPORTERS.CITY_NAME
    --          ,:IMPORTERS.L_CT_CITY_STATUS
    --          ,:IMPORTERS.CITY_CODE
    --          ,:IMPORTERS.ADD_CTRY_CD       );
    --       EXCEPTION
    --         WHEN NO_DATA_FOUND THEN
    --           Des$Form_errors.PUSH('خطأ في رمز مدينة عنوان المستورد', 'E', 'OFG', 0);
    --         WHEN OTHERS THEN
    --           CGTE$OTHER_EXCEPTIONS;
    --       END;
    --       SET_RECORD_PROPERTY(:SYSTEM.TRIGGER_RECORD, 'IMPORTERS', STATUS ,                 QUERY_STATUS);
    --     ELSE
    --         Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(78, '<p1> must be entered', 'دولــــــــة الإقامـــــة,المدينـة' ), 'E', 'OFG', 78);
    --         Des$Form_errors.RAISE_FAILURE;
    --     END IF;
    --   END;
    --   if NVL (gnrl.get_customs_setting (:PARAMETER.P_CURR_PORT_CD,'CR-6730',9), 0) = 1 then
    --       begin
    --           select WASL_CITY_NAME
    --           into   :importers.WASL_CITY_NAME
    --           from   IMPR_COMMON_DATA
    --           where  impr_type_cd = :importers.impr_type_cd
    --         and    bus_id_type_cd = :importers.bus_id_type_cd
    --         and    bus_id = :importers.bus_id
    --         and    bus_id_brnch = :importers.bus_id_brnch
    --         and    ctry_cd = :importers.ctry_cd;
    --      if :importers.WASL_CITY_NAME is not null then
    --       set_item_property('IMPORTERS.CITY_CODE',VISIBLE,property_false);
    --       set_item_property('IMPORTERS.CITY_CODE2',VISIBLE,property_false);
    --       set_item_property('IMPORTERS.CITY_NAME',VISIBLE,property_false);
    --      else
    --          set_item_property('IMPORTERS.WASL_CITY_NAME',VISIBLE,property_false);
    --      end if;
    --       exception
    --           when no_data_found then
    --             :importers.WASL_CITY_NAME :=:importers.CITY_NAME;
    --          set_item_property('IMPORTERS.WASL_CITY_NAME',VISIBLE,property_false);
    --       end;
    --   else
    --     set_item_property('IMPORTERS.WASL_CITY_NAME',VISIBLE,property_false);
    --   END IF;
    --   BEGIN
    --     IF (CG$IMPR1110_PROD_CENTRL_GLOBAL.IMPORTERS_WHERE <> 'first_time') THEN
    --       set_block_property('IMPORTERS', DEFAULT_WHERE, CG$IMPR1110_PROD_CENTRL_GLOBAL.IMPORTERS_WHERE);
    --       CG$IMPR1110_PROD_CENTRL_GLOBAL.IMPORTERS_WHERE := 'first_time';
    --     END IF;
    --   END;
    -- <<<
    PROCEDURE IMPORTERS_POST_QUERY (p_rec IN OUT NOCOPY T_RECORD, p_ctx IN T_CONTEXT)
    IS
        v_count        NUMBER := 0;
        xdt            DATE;
        v_user_bus_id  VARCHAR2(4);
        v_expiry_date  DATE;
        v_dummy        NUMBER(1);
    BEGIN
        SET_GLOBAL('OLD_IMPR_TYPE_CD', p_rec.impr_type_cd);
        SET_GLOBAL('OLD_PORT_CD', p_rec.port_cd);
        IF p_rec.impr_nbr IS NOT NULL THEN
            BEGIN
                xdt := cur_hij_date;
                SELECT COUNT(*) INTO v_count
                  FROM importers imp, impr_suspns is_1
                 WHERE imp.port_cd  = p_rec.port_cd
                   AND imp.impr_nbr = p_rec.impr_nbr
                   AND is_1.port_cd  = imp.port_cd
                   AND is_1.impr_nbr = imp.impr_nbr
                   AND TO_CHAR(is_1.suspn_strt_dt, 'YYYY-MM-MI') <= TO_CHAR(xdt, 'YYYY-MM-MI')
                   AND TO_CHAR(is_1.suspn_end_dt, 'YYYY-MM-MI') >= TO_CHAR(xdt, 'YYYY-MM-MI')
                   AND is_1.suspn_rlse_dt IS NULL;
                IF v_count >= 1 THEN
                    p_rec.suspn_status := 'موقوف';
                ELSE
                    p_rec.suspn_status := 'غير موقوف';
                END IF;
                IF v_count = 0 THEN
                    SELECT COUNT(*) INTO v_count
                      FROM impr_duty_diff_blks
                     WHERE hq_impr_nbr = p_rec.hq_impr_nbr
                       AND blk_rls_dt IS NULL;
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
                        IF NVL(gnrl.get_customs_setting('CRQ24602_RUN', 21), 0) = 0 THEN
                            IF v_count = 0 THEN
                                p_rec.suspn_status := 'موقوف(تدقيق عام)';
                            ELSE
                                p_rec.suspn_status := 'موقوف(تدقيق)له استثناء';
                            END IF;
                        ELSIF NVL(gnrl.get_customs_setting('CRQ24602_RUN', 21), 0) = 1 THEN
                            p_rec.suspn_status := '';
                        END IF;
                    END IF;
                END IF;
                IF v_count = 0 THEN
                    DECLARE
                        v_suspn_rsn_text VARCHAR2(2000) := '';
                    BEGIN
                        SELECT suspn_rsn_text INTO v_suspn_rsn_text
                          FROM impr_cntrl_suspns
                         WHERE hq_impr_nbr = p_rec.hq_impr_nbr
                           AND TO_CHAR(suspn_strt_dt, 'YYYY-MM-MI') <= TO_CHAR(xdt, 'YYYY-MM-MI')
                           AND TO_CHAR(suspn_end_dt, 'YYYY-MM-MI') >= TO_CHAR(xdt, 'YYYY-MM-MI')
                           AND suspn_rlse_dt IS NULL;
                        p_rec.suspn_status := 'إيقاف مركزي من قبل المصلحة - إدارة القيود بسبب ' || v_suspn_rsn_text;
                    EXCEPTION
                        WHEN NO_DATA_FOUND THEN
                            NULL;
                    END;
                END IF;
            EXCEPTION
                WHEN OTHERS THEN
                    NULL;
            END;
        END IF;
        p_rec.b_mobile_no := p_rec.mobile_no;
        p_rec.b_id_nbr    := p_rec.id_nbr;
        p_rec.b_email     := p_rec.email;
        SET_GLOBAL('STAT_QUE', '1');
        NULL;  -- APEX (read_only_rules.md): TYPE_ENTRABLE_QUERY(p_rec);
        IF p_rec.bus_id_type_cd = 2 AND p_rec.impr_type_cd != 12 THEN
            IF p_rec.bus_id_brnch IS NOT NULL THEN
                BEGIN
                    v_user_bus_id := SUBSTR(p_rec.bus_id_brnch, 1, 4);
                    SELECT city_cd, city_arb_name
                      INTO p_rec.brnh_city_cd, p_rec.brnh_city_name
                      FROM cities
                     WHERE ctry_cd      = 100
                       AND mins_comm_cd = v_user_bus_id;
                EXCEPTION
                    WHEN OTHERS THEN
                        NULL;
                END;
            END IF;
        END IF;

        BEGIN
            SELECT status_desc
              INTO p_rec.status_desc
              FROM mci_bus_id_status
             WHERE bus_id_status LIKE p_rec.bus_id_status;
        EXCEPTION
            WHEN OTHERS THEN
                NULL;
        END;

        BEGIN
            SELECT MAX(expiry_date)
              INTO v_expiry_date
              FROM privileged_importers
             WHERE impr_privilege_type = 3
               AND rec_status = 1
               AND impr_nbr   = p_rec.impr_nbr;
            IF v_expiry_date IS NOT NULL THEN
                IF v_expiry_date < hijdate_db.cur_hij_date THEN
                    p_rec.impr_id_type := 'اقامة عادية';
                ELSE
                    p_rec.impr_id_type := 'اقامة مميزة محددة المدة تنتهي بتاريخ ' || TO_CHAR(v_expiry_date, 'MI-MM-YYYY');
                END IF;
            ELSE
                BEGIN
                    SELECT 1
                      INTO v_dummy
                      FROM privileged_importers
                     WHERE impr_privilege_type = 3
                       AND rec_status = 1
                       AND impr_nbr   = p_rec.impr_nbr
                       AND ROWNUM = 1;
                    p_rec.impr_id_type := 'اقامة مميزة دائمة ';
                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        p_rec.impr_id_type := 'عادية';
                END;
            END IF;
        END;

        adj_funs(p_rec, p_ctx);

        -- CGFK$QRY_LOOKUP_DATA (CGFK$QRY_IMPORTERS_* units inlined)
        IF p_rec.port_cd IS NOT NULL THEN
            BEGIN
                SELECT l_sdp.port_status, l_sdp.port_name
                  INTO p_rec.sdp_port_status, p_rec.port_name
                  FROM sd_ports l_sdp
                 WHERE l_sdp.port_cd = p_rec.port_cd;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    info(CG_MESSAGE('This <p1> does not exist', 'رمز الجمــــــــــــــرك'));
            END;
        END IF;
        IF p_rec.impr_type_cd IS NOT NULL AND p_rec.bus_id_type_cd IS NOT NULL THEN
            BEGIN
                SELECT itidt.note, itidt.status, it.impr_type_name, bit.bus_id_type_name
                  INTO p_rec.itidt_note, p_rec.status, p_rec.impr_type_name, p_rec.bus_id_type_name
                  FROM impr_type_id_types itidt, impr_types it, bus_id_types bit
                 WHERE itidt.bus_id_type_cd = p_rec.bus_id_type_cd
                   AND itidt.impr_type_cd   = p_rec.impr_type_cd
                   AND it.impr_type_cd      = itidt.impr_type_cd
                   AND bit.bus_id_type_cd   = itidt.bus_id_type_cd
                   AND ROWNUM = 1;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    info('رمز النشاط التجاري غير صحيح - أعد إدخال البيانات');
            END;
        ELSE
            FORM_TRIGGER_FAILURE(CG_MESSAGE('<p1> must be entered', 'رمز النشاط التجارى'));
        END IF;
        IF p_rec.ctry_cd IS NOT NULL THEN
            BEGIN
                SELECT ctry.crty_arbc_name, ctry.ctry_status
                  INTO p_rec.crty_arbc_name, p_rec.ctry_ctry_status
                  FROM countries ctry
                 WHERE ctry.ctry_cd = p_rec.ctry_cd;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    info('رمز الدولة غير صحيح - أعد ادخال البيانات');
            END;
        END IF;
        IF p_rec.city_code_of_id IS NOT NULL AND p_rec.ctry_cd_of_id IS NOT NULL THEN
            BEGIN
                SELECT id_city.city_status, id_city.city_arb_name, id_city.mins_comm_cd
                  INTO p_rec.l_ct_city_status2, p_rec.id_city_name, p_rec.id_mins_comm_cd
                  FROM cities id_city
                 WHERE id_city.city_cd = p_rec.city_code_of_id
                   AND id_city.ctry_cd = p_rec.ctry_cd_of_id
                   AND ROWNUM = 1;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    info('خطأ في رمز مدينة مصدر الرقم الإستدلالي');
            END;
        END IF;
        IF p_rec.add_ctry_cd IS NOT NULL AND p_rec.city_code IS NOT NULL THEN
            BEGIN
                SELECT add_city.city_status, add_city.city_arb_name, l_ctry.crty_arbc_name
                  INTO p_rec.l_ct_city_status, p_rec.city_name, p_rec.add_crty_arbc_name
                  FROM cities add_city, countries l_ctry
                 WHERE add_city.ctry_cd = p_rec.add_ctry_cd
                   AND add_city.city_cd = p_rec.city_code
                   AND l_ctry.ctry_cd   = add_city.ctry_cd
                   AND ROWNUM = 1;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    info('خطأ في رمز مدينة عنوان المستورد');
            END;
        ELSE
            FORM_TRIGGER_FAILURE(CG_MESSAGE('<p1> must be entered', 'دولــــــــة الإقامـــــة,المدينـة'));
        END IF;

        IF NVL(gnrl.get_customs_setting(p_ctx.curr_port_cd, 'CR-6730', 9), 0) = 1 THEN
            BEGIN
                SELECT wasl_city_name
                  INTO p_rec.wasl_city_name
                  FROM impr_common_data
                 WHERE impr_type_cd   = p_rec.impr_type_cd
                   AND bus_id_type_cd = p_rec.bus_id_type_cd
                   AND bus_id         = p_rec.bus_id
                   AND bus_id_brnch   = p_rec.bus_id_brnch
                   AND ctry_cd        = p_rec.ctry_cd;
                IF p_rec.wasl_city_name IS NOT NULL THEN
                    NULL;  -- APEX (read_only_rules.md): ui('CITY_CODE', 'VISIBLE', FALSE);
                    NULL;  -- APEX (read_only_rules.md): ui('CITY_CODE2', 'VISIBLE', FALSE);
                    NULL;  -- APEX (read_only_rules.md): ui('CITY_NAME', 'VISIBLE', FALSE);
                ELSE
                    NULL;  -- APEX (read_only_rules.md): ui('WASL_CITY_NAME', 'VISIBLE', FALSE);
                END IF;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    p_rec.wasl_city_name := p_rec.city_name;
                    NULL;  -- APEX (read_only_rules.md): ui('WASL_CITY_NAME', 'VISIBLE', FALSE);
            END;
        ELSE
            NULL;  -- APEX (read_only_rules.md): ui('WASL_CITY_NAME', 'VISIBLE', FALSE);
        END IF;
        -- CGFK$RESET_BLOCK_WHERE_CLAUSE: not needed (no DEFAULT_WHERE manipulation in APEX)
    END IMPORTERS_POST_QUERY;

    -- Source: IMPORTERS.PRE-INSERT
    -- p_answer: answer to the CONFIRM shown to class 1 / user type 3 (broker) before saving.
    --@ORIG IMPORTERS.PRE-INSERT
    -- >>> Original Forms code: IMPORTERS.PRE-INSERT
    --   BEGIN
    --   SET_BLOCK_PROPERTY('IMPORTERS',UPDATE_ALLOWED,PROPERTY_FALSE);
    --   IF :B_MOBILE_NO IS NULL THEN
    --   STR.DISPALERT('يجب إدخال رقم المحمول','INFORMATION');
    --   RAISE FORM_TRIGGER_FAILURE;
    --   END IF;
    --   IF :CITY_CODE  IS NULL THEN
    --   STR.DISPALERT('يجب إدخال المدينة','INFORMATION');
    --     RAISE FORM_TRIGGER_FAILURE;
    --   END IF;
    --   END;
    --   DECLARE
    --    RET NUMBER;
    --   BEGIN
    --     CHK_DUPL_IMP_BRKR ;
    --     IF :IMPR_TEL_NBR IS NULL THEN
    --         INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_TEL_NBR',TRUE);
    --         RET := STR.DispALERT('يجب ادخال رقم الهاتف','INFORMATION');
    --         RAISE FORM_TRIGGER_FAILURE;
    --     END IF;
    --     IF  ((:BUS_ID_TYPE_CD = 2 AND :IMPR_TYPE_CD IN (1,3,5,6,8,12))
    --      OR (:BUS_ID_TYPE_CD = 3 AND :IMPR_TYPE_CD = 4)
    --      OR (:BUS_ID_TYPE_CD = 4 AND :IMPR_TYPE_CD = 4))
    --     THEN
    --      IF :BUS_ID_EXPRD_DT IS NULL THEN
    --         INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_EXPRD_DT',TRUE);
    --         ret := Str.DispArbMsg(9,220,'ERROR');
    --       RAISE FORM_TRIGGER_FAILURE;
    --      END IF;
    --    END IF;
    --   CHK_IMPR_DUPL;
    --   IF GET_ITEM_PROPERTY('ACTIVITY',ENABLED) = 'TRUE' AND :ACTIVITY IS NULL THEN
    --       STR.DISPALERT('يجب إدخال حقل نشاط المستورد','INFORMATION');
    --        RAISE FORM_TRIGGER_FAILURE;
    --   END IF;
    --   DECLARE
    --   RET NUMBER;
    --   BEGIN
    --   IF :PARAMETER.P_CLASS_CD=1 AND :PARAMETER.P_USER_TYPE=3 THEN
    --   RET:=STR.DISPALERT('يجب مراجعة البيانات والتأكد من صحتها قبل التخزين، لايمكن التعديل إلا من قبل شئون المستوردين! هل ترغب بالاستمرار؟','CONFIRM');
    --   IF RET = ALERT_BUTTON1 THEN
    --   NULL;
    --   ELSE
    --   RAISE FORm_Trigger_Failure;
    --   END IF;
    --   END IF;
    --   END;
    --   IF NOT ACTIVITY.ADD_ACTIVITY(9, 2, 1, :IMPORTERS.Port_Cd||'!'||:IMPORTERS.Impr_Nbr) THEN
    --       RAISE FORm_Trigger_Failure;
    --   END IF;
    --   END;
    --   DECLARE
    --     V_CNT NUMBER;
    --     RET NUMBER;
    --     V_RET VARCHAR2(5);
    --     V_EXPRD_DT DATE;
    --     V_CUSTOMS_ENTERED  NUMBER;
    --   BEGIN
    --    IF  :BUS_ID_TYPE_CD = 2 AND :IMPR_TYPE_CD!=12 THEN
    --        IF :COMM_RGSTRTN_TYPE = 1 THEN
    --            IF :BUS_ID IS NOT NULL THEN
    --                 SELECT COUNT(BUS_ID) INTO V_CNT FROM COMM_IMPR_RGSTR
    --                 WHERE  BUS_ID=:BUS_ID
    --                   AND  BRNCHREG=0;
    --                 IF V_CNT =0 THEN
    --                   V_RET := LIB_USR.GNRL.GET_CUSTOMS_SETTING(:PARAMETER.P_CURR_PORT_CD,'COMM_TABLE_UNCHECK',9);
    --                   IF NVL(V_RET,0) = 0 THEN
    --                      ret := Str.DispArbMsg(9, 190,'ERROR');
    --                    RAISE FORM_TRIGGER_FAILURE;
    --               ELSE
    --                 V_CUSTOMS_ENTERED:=1;
    --                 END IF;
    --              ELSE
    --                V_CUSTOMS_ENTERED:= 0 ;
    --                  END IF;
    --            ELSE
    --                ret := Str.DispArbMsg(9, 250,'ERROR');
    --              RAISE FORM_TRIGGER_FAILURE;
    --            END IF;
    --        ELSIF :COMM_RGSTRTN_TYPE = 2 THEN
    --            IF :BUS_ID IS NOT NULL AND :BUS_ID_BRNCH IS NOT NULL THEN
    --               SELECT COUNT(BUS_ID)INTO V_CNT    FROM COMM_IMPR_RGSTR
    --               WHERE  BUS_ID       =:BUS_ID
    --                 AND  BRNCH_BUS_ID =:IMPORTERS.BUS_ID_BRNCH ;
    --                 IF V_CNT =0 THEN
    --                    V_RET := LIB_USR.GNRL.GET_CUSTOMS_SETTING(:PARAMETER.P_CURR_PORT_CD,'COMM_TABLE_UNCHECK',9);
    --                  IF NVL(V_RET,0) = 0 THEN
    --                     ret := Str.DispArbMsg(9, 190,'ERROR');
    --                     RAISE FORM_TRIGGER_FAILURE;
    --                ELSE
    --                V_CUSTOMS_ENTERED:=1;
    --                  END IF;
    --             ELSE
    --              V_CUSTOMS_ENTERED:= 0 ;
    --                    END IF;
    --             ELSE
    --                ret := Str.DispArbMsg(9, 230,'ERROR');
    --              RAISE FORM_TRIGGER_FAILURE;
    --            END IF;
    --       ELSE
    --          ret := Str.DispArbMsg(9, 240,'ERROR');
    --          INTRFACE.Make_Field_Entrable('IMPORTERS.COMM_RGSTRTN_TYPE' , TRUE);
    --        RAISE FORM_TRIGGER_FAILURE;
    --       END IF;
    --     END IF;
    --   IF     :GLOBAL.CHK_DUP_BUSID = 1 THEN
    --         IF NOT ACTIVITY.ADD_ACTIVITY(9, 2, 3, :IMPORTERS.Port_Cd||'!'||:IMPORTERS.Impr_Nbr) THEN
    --           RAISE FORm_Trigger_Failure;
    --         END IF;
    --         :GLOBAL.CHK_DUP_BUSID := 0 ;
    --     END IF;
    --   SET_BLOCK_PROPERTY('IMPORTERS',UPDATE_ALLOWED,PROPERTY_FALSE);
    --   DECLARE
    --       V_IMPR_NBR        VARCHAR2(50);
    --     V_msg_txt         VARCHAR2(500);
    --     V_RESULT          NUMBER;
    --   BEGIN
    --       LIB_USR.IMPR_CENTRAL.Create_Uni_IMPR_NEBRAS ( :PORT_CD,
    --                                                     :BUS_ID,
    --                                                     :BUS_ID_BRNCH,
    --                                                     :BUS_ID_TYPE_CD,
    --                                                     :IMPR_TYPE_CD,
    --                                                     :CTRY_CD,
    --                                                     :CITY_CODE,
    --                                                     :IMPR_CNTCT_NAME,
    --                                                     NVL(:IMPR_TEL_NBR,0),
    --                                                     :B_EMAIL,
    --                                                     :BANK_IBAN,
    --                                                                 NVL(:IMPR_POB_NBR,0),
    --                                                     TO_CHAR(:BUS_ID_EXPRD_DT,'MI-MM-YYYY'),
    --                                                     :ACTIVITY,
    --                                                     :ARBC_IMPR_NAME,
    --                                                     :ENG_IMPR_NAME,
    --                                                           NVL(:B_MOBILE_NO,0),
    --                                                                   NVL(:IMPR_ZIP_CD,0),
    --                                                     NVL(:BRNH_CITY_CD,0),
    --                                                     :IMPR_EXPR_TYPE,
    --                                                     :IMPR_ADDRESS,
    --                                                     TO_CHAR(:BUS_ID_ISSUE_DT,'MI-MM-YYYY'),
    --                                                     :B_ID_NBR,
    --                                                     NVL(:COMM_RGSTRTN_TYPE,0),
    --                                                     0,--NVL(:CTRY_CD_OF_ID,0),
    --                                                     NVL(:CITY_CODE_OF_ID,0),
    --                                                     NVL(:IMPR_NBR_PARENT,0),
    --                                                     NVL(:IMPR_FAX_NBR,0),
    --                                                     NVL(:IMPR_TELEX_NBR,0),
    --                                                     NVL(:ADD_CTRY_CD,0),
    --                                                     NVL(:IMPD_STMT_NBR,0),
    --                                                     NVL(:IMPR_DATA_SRCE,0),
    --                                                     NVL(V_CUSTOMS_ENTERED,0),
    --                                                     NVL(:EXPD_STMT_NBR,0),
    --                                                     NVL(:WVR_ENTRY_NBR,0),
    --                                                     NVL(:CAR_AGENT_FLAG,0),
    --                                                     NVL(:EXPRESS_POST,0),
    --                                                     V_IMPR_NBR,
    --                                                     V_msg_txt,
    --                                                     V_RESULT,
    --                                                     :PARAMETER.P_USER_ID,
    --                                                     :PARAMETER.P_WS_ID
    --                                                     );
    --        IF V_RESULT = 1 THEN
    --                     STR.DISPALERT(V_msg_txt,'information') ;--||'  '||V_RESULT,'INFORMATION') ;
    --                STR.DISPALERT('رقم المستورد'||' = '||V_IMPR_NBR,'INFORMATION') ;
    --          :GLOBAL.SET :=  V_IMPR_NBR ;
    --   IF :GLOBAL.SET IS NOT NULL THEN
    --    :HQ_IMPR_NBR := :GLOBAL.SET;
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID' , FALSE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_BRNCH', FALSE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_EXPRD_DT' , FALSE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.ARBC_IMPR_NAME' , FALSE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.COMM_RGSTRTN_TYPE' , FALSE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_BRNCH' , FALSE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.CITY_CODE_OF_ID',FALSE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_TYPE_CD' , FALSE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_EXPR_TYPE' , FALSE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_TYPE_CD' , FALSE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.BRNH_CITY_CD' , FALSE);
    --   END IF;
    --          ELSE
    --                  STR.DISPALERT(V_msg_txt,'information'); --||' <=> '||V_RESULT,'INFORMATION') ;--
    --                    RAISE FORm_Trigger_Failure;
    --                    SET_BLOCK_PROPERTY('IMPORTERS',UPDATE_ALLOWED,PROPERTY_TRUE);
    --        END IF;
    --   END ;
    --   END;
    --   BEGIN
    --     IF (name_in('IMPORTERS.CITY_CODE_OF_ID') IS NULL AND name_in('IMPORTERS.CTRY_CD_OF_ID') IS NULL) THEN
    --       BEGIN
    --         CGSF$CLRLU_IMPORTERS_IMP_BUS_I;
    --       EXCEPTION
    --         WHEN OTHERS THEN
    --           CGTE$OTHER_EXCEPTIONS;
    --       END;
    --     END IF;
    --   END;
    -- <<<
    PROCEDURE IMPORTERS_PRE_INSERT (p_rec    IN OUT NOCOPY T_RECORD,
                                 p_ctx    IN T_CONTEXT,
                                 p_answer IN PLS_INTEGER DEFAULT c_yes)
    IS
        v_cnt             NUMBER;
        v_ret             VARCHAR2(5);
        v_customs_entered NUMBER;
        v_impr_nbr        VARCHAR2(50);
        v_msg_txt         VARCHAR2(500);
        v_result          NUMBER;
    BEGIN
        -- SET_BLOCK_PROPERTY('IMPORTERS',UPDATE_ALLOWED,PROPERTY_FALSE): UI only
        IF p_rec.b_mobile_no IS NULL THEN
            FORM_TRIGGER_FAILURE('يجب إدخال رقم المحمول');
        END IF;
        IF p_rec.city_code IS NULL THEN
            FORM_TRIGGER_FAILURE('يجب إدخال المدينة');
        END IF;

        chk_dupl_imp_brkr(p_rec, p_ctx);
        IF p_rec.impr_tel_nbr IS NULL THEN
            NULL;  -- APEX (read_only_rules.md): entrable('IMPR_TEL_NBR', TRUE);
            FORM_TRIGGER_FAILURE('يجب ادخال رقم الهاتف');
        END IF;
        IF ((p_rec.bus_id_type_cd = 2 AND p_rec.impr_type_cd IN (1, 3, 5, 6, 8, 12))
            OR (p_rec.bus_id_type_cd = 3 AND p_rec.impr_type_cd = 4)
            OR (p_rec.bus_id_type_cd = 4 AND p_rec.impr_type_cd = 4)) THEN
            IF p_rec.bus_id_exprd_dt IS NULL THEN
                NULL;  -- APEX (read_only_rules.md): entrable('BUS_ID_EXPRD_DT', TRUE);
                DISPLAY_ARABIC_ERROR(9, 220);
            END IF;
        END IF;
        chk_impr_dupl(p_rec);
        IF NVL(p_rec.activity_entr, 'N') = 'Y' AND p_rec.activity IS NULL THEN
            FORM_TRIGGER_FAILURE('يجب إدخال حقل نشاط المستورد');
        END IF;
        IF p_ctx.class_cd = 1 AND p_ctx.user_type = 3 THEN
            -- CONFIRM 'يجب مراجعة البيانات والتأكد من صحتها قبل التخزين، لايمكن التعديل إلا من قبل شئون المستوردين! هل ترغب بالاستمرار؟'
            IF p_answer = c_yes THEN
                NULL;
            ELSE
                FORM_TRIGGER_FAILURE;
            END IF;
        END IF;
        add_activity(1, p_rec, p_ctx);

        IF p_rec.bus_id_type_cd = 2 AND p_rec.impr_type_cd != 12 THEN
            IF p_rec.comm_rgstrtn_type = 1 THEN
                IF p_rec.bus_id IS NOT NULL THEN
                    SELECT COUNT(bus_id) INTO v_cnt
                      FROM comm_impr_rgstr
                     WHERE bus_id = p_rec.bus_id
                       AND brnchreg = 0;
                    IF v_cnt = 0 THEN
                        v_ret := lib_usr.gnrl.get_customs_setting(p_ctx.curr_port_cd, 'COMM_TABLE_UNCHECK', 9);
                        IF NVL(v_ret, 0) = 0 THEN
                            DISPLAY_ARABIC_ERROR(9, 190);
                        ELSE
                            v_customs_entered := 1;
                        END IF;
                    ELSE
                        v_customs_entered := 0;
                    END IF;
                ELSE
                    DISPLAY_ARABIC_ERROR(9, 250);
                END IF;
            ELSIF p_rec.comm_rgstrtn_type = 2 THEN
                IF p_rec.bus_id IS NOT NULL AND p_rec.bus_id_brnch IS NOT NULL THEN
                    SELECT COUNT(bus_id) INTO v_cnt
                      FROM comm_impr_rgstr
                     WHERE bus_id       = p_rec.bus_id
                       AND brnch_bus_id = p_rec.bus_id_brnch;
                    IF v_cnt = 0 THEN
                        v_ret := lib_usr.gnrl.get_customs_setting(p_ctx.curr_port_cd, 'COMM_TABLE_UNCHECK', 9);
                        IF NVL(v_ret, 0) = 0 THEN
                            DISPLAY_ARABIC_ERROR(9, 190);
                        ELSE
                            v_customs_entered := 1;
                        END IF;
                    ELSE
                        v_customs_entered := 0;
                    END IF;
                ELSE
                    DISPLAY_ARABIC_ERROR(9, 230);
                END IF;
            ELSE
                NULL;  -- APEX (read_only_rules.md): entrable('COMM_RGSTRTN_TYPE', TRUE);
                DISPLAY_ARABIC_ERROR(9, 240);
            END IF;
        END IF;
        IF GET_GLOBAL('CHK_DUP_BUSID') = '1' THEN
            -- Note: only the unused PU VIEW_SAME_BUSID sets this global to 1 -> never true today.
            add_activity(3, p_rec, p_ctx);
            SET_GLOBAL('CHK_DUP_BUSID', '0');
        END IF;

        -- RECORD IMPORTER IN HQ AND PORT (Bassam Mansour 09/01/2019)
        lib_usr.impr_central.create_uni_impr_nebras(
            p_rec.port_cd,
            p_rec.bus_id,
            p_rec.bus_id_brnch,
            p_rec.bus_id_type_cd,
            p_rec.impr_type_cd,
            p_rec.ctry_cd,
            p_rec.city_code,
            p_rec.impr_cntct_name,
            NVL(p_rec.impr_tel_nbr, 0),
            p_rec.b_email,
            p_rec.bank_iban,
            NVL(p_rec.impr_pob_nbr, 0),
            TO_CHAR(p_rec.bus_id_exprd_dt, 'MI-MM-YYYY'),
            p_rec.activity,
            p_rec.arbc_impr_name,
            p_rec.eng_impr_name,
            NVL(p_rec.b_mobile_no, 0),
            NVL(p_rec.impr_zip_cd, 0),
            NVL(p_rec.brnh_city_cd, 0),
            p_rec.impr_expr_type,
            p_rec.impr_address,
            TO_CHAR(p_rec.bus_id_issue_dt, 'MI-MM-YYYY'),
            p_rec.b_id_nbr,
            NVL(p_rec.comm_rgstrtn_type, 0),
            0,                                   -- NVL(:CTRY_CD_OF_ID,0) is commented out in Forms
            NVL(p_rec.city_code_of_id, 0),
            NVL(p_rec.impr_nbr_parent, 0),
            NVL(p_rec.impr_fax_nbr, 0),
            NVL(p_rec.impr_telex_nbr, 0),
            NVL(p_rec.add_ctry_cd, 0),
            NVL(p_rec.impd_stmt_nbr, 0),
            NVL(p_rec.impr_data_srce, 0),
            NVL(v_customs_entered, 0),
            NVL(p_rec.expd_stmt_nbr, 0),
            NVL(p_rec.wvr_entry_nbr, 0),
            NVL(p_rec.car_agent_flag, 0),
            NVL(p_rec.express_post, 0),
            v_impr_nbr,
            v_msg_txt,
            v_result,
            p_ctx.user_id,
            p_ctx.ws_id);
        IF v_result = 1 THEN
            info(v_msg_txt);
            info('رقم المستورد' || ' = ' || v_impr_nbr);
            SET_GLOBAL('SET', v_impr_nbr);
            IF GET_GLOBAL('SET') IS NOT NULL THEN
                p_rec.hq_impr_nbr := GET_GLOBAL('SET');
                NULL;  -- APEX (read_only_rules.md): lock_key_items;
            END IF;
        ELSE
            FORM_TRIGGER_FAILURE(v_msg_txt);
        END IF;

        -- CGFK$CLR_FK_ON_INS
        IF p_rec.city_code_of_id IS NULL AND p_rec.ctry_cd_of_id IS NULL THEN
            CGSF$CLRLU_IMPORTERS_IMP_BUS_I(p_rec);
        END IF;
    END IMPORTERS_PRE_INSERT;

    -- Source: IMPORTERS.POST-INSERT
    --@ORIG IMPORTERS.POST-INSERT
    -- >>> Original Forms code: IMPORTERS.POST-INSERT
    --   BEGIN
    --   IF :GLOBAL.CHEK = 1 THEN
    --   SET_BLOCK_PROPERTY('IMPORTERS',UPDATE_ALLOWED,PROPERTY_TRUE);
    --   END IF;
    --        Insert_Audit_Record ('I');
    --   END;
    --   update_basic_importer;
    --   IF :PARAMETER.P_CLASS_CD=1 AND :PARAMETER.P_USER_TYPE=3 THEN
    --   CREATE_BRKR_IMPR_AUTH;
    --   END IF;
    --   IF :GLOBAL.SET IS NOT NULL THEN
    --   :IMPR_NBR := :GLOBAL.SET;
    --   :HQ_IMPR_NBR := :GLOBAL.SET;
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID' , FALSE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_BRNCH', FALSE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_EXPRD_DT' , FALSE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.ARBC_IMPR_NAME' , FALSE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.COMM_RGSTRTN_TYPE' , FALSE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_BRNCH' , FALSE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.CITY_CODE_OF_ID',FALSE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_TYPE_CD' , FALSE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_EXPR_TYPE' , FALSE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_TYPE_CD' , FALSE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.BRNH_CITY_CD' , FALSE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_TEL_NBR', FALSE);
    --   END IF;
    --   BEGIN
    --   RETURN_IMPR_ID ;
    --   END;
    -- <<<
    PROCEDURE IMPORTERS_POST_INSERT (p_rec IN OUT NOCOPY T_RECORD, p_ctx IN T_CONTEXT)
    IS
    BEGIN
        IF GET_GLOBAL('CHEK') = '1' THEN
            -- SET_BLOCK_PROPERTY('IMPORTERS',UPDATE_ALLOWED,PROPERTY_TRUE): UI only
            -- (:GLOBAL.CHEK is never set in this form - set by another form or the OLB)
            NULL;
        END IF;
        insert_audit_record(p_rec, p_ctx, 'I');
        update_basic_importer(p_rec);
        IF p_ctx.class_cd = 1 AND p_ctx.user_type = 3 THEN
            create_brkr_impr_auth(p_rec, p_ctx);
        END IF;
        IF GET_GLOBAL('SET') IS NOT NULL THEN
            p_rec.impr_nbr    := GET_GLOBAL('SET');
            p_rec.hq_impr_nbr := GET_GLOBAL('SET');
            NULL;  -- APEX (read_only_rules.md): lock_key_items;
            NULL;  -- APEX (read_only_rules.md): entrable('IMPR_TEL_NBR', FALSE);
        END IF;
        return_impr_id(p_rec, p_ctx);
    END IMPORTERS_POST_INSERT;

    -- Source: IMPORTERS.PRE-UPDATE
    --@ORIG IMPORTERS.PRE-UPDATE
    -- >>> Original Forms code: IMPORTERS.PRE-UPDATE
    --   BEGIN
    --   chk_personal (:impr_type_cd,:hq_impr_nbr) ;
    --   END;
    --   BEGIN
    --   IF :B_MOBILE_NO IS NULL THEN
    --   STR.DISPALERT('يجب إدخال رقم المحمول','ERROR');
    --   RAISE FORM_TRIGGER_FAILURE;
    --   END IF;
    --   END;
    --   DECLARE
    --   CURSOR c1_hq_nbr IS
    --       SELECT     HQ_IMPR_NBR
    --       FROM         HQ_IMPRS
    --       WHERE     BUS_ID_TYPE_CD = :IMPORTERS.BUS_ID_TYPE_CD
    --       AND        BUS_ID = :IMPORTERS.BUS_ID
    --       AND        BUS_ID_BRNCH = :IMPORTERS.BUS_ID_BRNCH ;
    --   CURSOR c2_hq_nbr IS
    --       SELECT     HQ_IMPR_NBR
    --       FROM         HQ_IMPRS
    --       WHERE     BUS_ID_TYPE_CD = :IMPORTERS.BUS_ID_TYPE_CD
    --       AND        BUS_ID = :IMPORTERS.BUS_ID
    --       AND        BUS_ID_BRNCH IS NULL;
    --   V_HQ_NBR NUMBER := NULL;
    --    RET NUMBER;
    --   BEGIN
    --     CHK_DUPL_IMP_BRKR ;
    --     IF  ((:BUS_ID_TYPE_CD = 2 AND :IMPR_TYPE_CD IN (1,3,5,6,8,12))
    --      OR (:BUS_ID_TYPE_CD = 3 AND :IMPR_TYPE_CD = 4)
    --      OR (:BUS_ID_TYPE_CD = 4 AND :IMPR_TYPE_CD = 4))
    --    THEN
    --      IF :BUS_ID_EXPRD_DT IS NULL THEN
    --         INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_EXPRD_DT',TRUE);
    --         ret := Str.DispArbMsg(9,220,'ERROR');
    --       RAISE FORM_TRIGGER_FAILURE;
    --      END IF;
    --    END IF;
    --   IF :PARAMETER.LETTER_NBR IS NOT NULL THEN
    --     :IMPORTERS.HQ_IMPR_NBR:=NULL;
    --   END IF;
    --   :IMPR_NAME_STD := STR.StrFormat(:ARBC_IMPR_NAME);
    --   Insert_Audit_Record ('U');
    --   IF :IMPORTERS.BUS_ID_BRNCH IS NULL THEN
    --       OPEN     c2_hq_nbr;
    --       FETCH c2_hq_nbr INTO V_HQ_NBR;
    --       :IMPORTERS.hq_impr_nbr := V_HQ_NBR;
    --       CLOSE c2_hq_nbr;
    --   ELSE
    --       OPEN     c1_hq_nbr;
    --       FETCH c1_hq_nbr INTO V_HQ_NBR;
    --       :IMPORTERS.hq_impr_nbr := V_HQ_NBR;
    --       CLOSE c1_hq_nbr;
    --   END IF;
    --   IF NOT ACTIVITY.ADD_ACTIVITY(9, 2, 2, :IMPORTERS.Port_Cd||'!'||:IMPORTERS.Impr_Nbr) THEN
    --       RAISE FORm_Trigger_Failure;
    --   END IF;
    --   IF :GLOBAL.LETTER_NBR IS NOT NULL THEN
    --     DB_JOURNAL.JOURNALING_ON(:GLOBAL.PORT_CD,:GLOBAL.SUPP_TITLE_CD,:GLOBAL.LETTER_NBR,:GLOBAL.LETTER_DT);
    --    END IF;
    --   END;
    --   DECLARE
    --       V_ANAME VARCHAR2(200);
    --       V_ENAME VARCHAR2(200);
    --       V_CNAME VARCHAR2(200);
    --   BEGIN
    --   V_ANAME := LTRIM(RTRIM(:IMPORTERS.ARBC_IMPR_NAME));
    --   V_ENAME := LTRIM(RTRIM(:IMPORTERS.ENG_IMPR_NAME));
    --   V_CNAME := LTRIM(RTRIM(:IMPORTERS.IMPR_CNTCT_NAME));
    --   :IMPORTERS.ARBC_IMPR_NAME:=V_ANAME;
    --   :IMPORTERS.ENG_IMPR_NAME:=V_ENAME;
    --   :IMPORTERS.IMPR_CNTCT_NAME:=V_CNAME;
    --   END;
    --   DECLARE
    --     V_CNT NUMBER;
    --     RET NUMBER;
    --     V_RET VARCHAR2(5);
    --   BEGIN
    --    IF :BUS_ID_TYPE_CD = 2 AND :IMPR_TYPE_CD!=12 THEN
    --       IF :COMM_RGSTRTN_TYPE = 1 THEN
    --           IF :BUS_ID IS NOT NULL THEN
    --               SELECT COUNT(BUS_ID) INTO V_CNT FROM COMM_IMPR_RGSTR
    --               WHERE  BUS_ID=:BUS_ID
    --                AND   BRNCHREG=0;
    --               IF V_CNT =0 THEN
    --                  V_RET := LIB_USR.GNRL.GET_CUSTOMS_SETTING(:PARAMETER.P_CURR_PORT_CD,'COMM_TABLE_UNCHECK',9);
    --                  IF NVL(V_RET,0) = 0 THEN
    --                     ret := Str.DispArbMsg(9, 190,'ERROR');
    --                   RAISE FORM_TRIGGER_FAILURE;
    --              ELSE
    --                  :IMPORTERS.CUSTOMS_ENTERED:=1;
    --              END IF;
    --           ELSE
    --             :IMPORTERS.CUSTOMS_ENTERED:= 0 ;
    --               END IF;
    --           ELSE
    --               ret := Str.DispArbMsg(9, 250,'ERROR');
    --             RAISE FORM_TRIGGER_FAILURE;
    --           END IF;
    --        ELSIF :COMM_RGSTRTN_TYPE = 2 THEN
    --          IF :BUS_ID IS NOT NULL AND :BUS_ID_BRNCH IS NOT NULL THEN
    --            SELECT COUNT(BUS_ID)INTO V_CNT    FROM COMM_IMPR_RGSTR
    --            WHERE  BUS_ID=:BUS_ID
    --             AND   BRNCH_BUS_ID=:IMPORTERS.BUS_ID_BRNCH ;
    --              IF V_CNT =0 THEN
    --                V_RET := LIB_USR.GNRL.GET_CUSTOMS_SETTING(:PARAMETER.P_CURR_PORT_CD,'COMM_TABLE_UNCHECK',9);
    --                  IF NVL(V_RET,0) = 0 THEN
    --                  ret := Str.DispArbMsg(9, 190,'ERROR');
    --                  RAISE FORM_TRIGGER_FAILURE;
    --              ELSE
    --                :IMPORTERS.CUSTOMS_ENTERED:=1;
    --                END IF;
    --            ELSE
    --                      :IMPORTERS.CUSTOMS_ENTERED:= 0 ;
    --              END IF;
    --           ELSE
    --               ret := Str.DispArbMsg(9, 230,'ERROR');
    --             RAISE FORM_TRIGGER_FAILURE;
    --           END IF;
    --        ELSE
    --          ret := Str.DispArbMsg(9, 240,'ERROR');
    --          INTRFACE.Make_Field_Entrable('IMPORTERS.COMM_RGSTRTN_TYPE' , TRUE);
    --        RAISE FORM_TRIGGER_FAILURE;
    --        END IF;
    --     END IF;
    --    :MOBILE_NO:=:B_MOBILE_NO;
    --   END;
    -- <<<
    PROCEDURE IMPORTERS_PRE_UPDATE (p_rec IN OUT NOCOPY T_RECORD, p_ctx IN T_CONTEXT)
    IS
        CURSOR c1_hq_nbr IS
            SELECT hq_impr_nbr
              FROM hq_imprs
             WHERE bus_id_type_cd = p_rec.bus_id_type_cd
               AND bus_id         = p_rec.bus_id
               AND bus_id_brnch   = p_rec.bus_id_brnch;
        CURSOR c2_hq_nbr IS
            SELECT hq_impr_nbr
              FROM hq_imprs
             WHERE bus_id_type_cd = p_rec.bus_id_type_cd
               AND bus_id         = p_rec.bus_id
               AND bus_id_brnch IS NULL;
        v_hq_nbr NUMBER := NULL;
        v_cnt    NUMBER;
        v_ret    VARCHAR2(5);
    BEGIN
        chk_personal(p_rec, p_ctx, p_rec.impr_type_cd, p_rec.hq_impr_nbr);
        IF p_rec.b_mobile_no IS NULL THEN
            FORM_TRIGGER_FAILURE('يجب إدخال رقم المحمول');
        END IF;

        chk_dupl_imp_brkr(p_rec, p_ctx);
        IF ((p_rec.bus_id_type_cd = 2 AND p_rec.impr_type_cd IN (1, 3, 5, 6, 8, 12))
            OR (p_rec.bus_id_type_cd = 3 AND p_rec.impr_type_cd = 4)
            OR (p_rec.bus_id_type_cd = 4 AND p_rec.impr_type_cd = 4)) THEN
            IF p_rec.bus_id_exprd_dt IS NULL THEN
                NULL;  -- APEX (read_only_rules.md): entrable('BUS_ID_EXPRD_DT', TRUE);
                DISPLAY_ARABIC_ERROR(9, 220);
            END IF;
        END IF;
        IF p_ctx.letter_nbr IS NOT NULL THEN
            p_rec.hq_impr_nbr := NULL;
        END IF;
        -- STR.StrFormat(x) = STR_DB.StrFormat(x, 0) (CIC_LIB.pld, STR.StrFormat, SRCH DEFAULT FALSE)
        p_rec.impr_name_std := str_db.strformat(p_rec.arbc_impr_name, 0);
        insert_audit_record(p_rec, p_ctx, 'U');
        IF p_rec.bus_id_brnch IS NULL THEN
            OPEN c2_hq_nbr;
            FETCH c2_hq_nbr INTO v_hq_nbr;
            p_rec.hq_impr_nbr := v_hq_nbr;
            CLOSE c2_hq_nbr;
        ELSE
            OPEN c1_hq_nbr;
            FETCH c1_hq_nbr INTO v_hq_nbr;
            p_rec.hq_impr_nbr := v_hq_nbr;
            CLOSE c1_hq_nbr;
        END IF;
        add_activity(2, p_rec, p_ctx);
        IF GET_GLOBAL('LETTER_NBR') IS NOT NULL THEN
            db_journal.journaling_on(GET_GLOBAL('PORT_CD'), GET_GLOBAL('SUPP_TITLE_CD'),
                                     GET_GLOBAL('LETTER_NBR'), GET_GLOBAL('LETTER_DT'));
        END IF;

        p_rec.arbc_impr_name  := LTRIM(RTRIM(p_rec.arbc_impr_name));
        p_rec.eng_impr_name   := LTRIM(RTRIM(p_rec.eng_impr_name));
        p_rec.impr_cntct_name := LTRIM(RTRIM(p_rec.impr_cntct_name));

        IF p_rec.bus_id_type_cd = 2 AND p_rec.impr_type_cd != 12 THEN
            IF p_rec.comm_rgstrtn_type = 1 THEN
                IF p_rec.bus_id IS NOT NULL THEN
                    SELECT COUNT(bus_id) INTO v_cnt
                      FROM comm_impr_rgstr
                     WHERE bus_id = p_rec.bus_id
                       AND brnchreg = 0;
                    IF v_cnt = 0 THEN
                        v_ret := lib_usr.gnrl.get_customs_setting(p_ctx.curr_port_cd, 'COMM_TABLE_UNCHECK', 9);
                        IF NVL(v_ret, 0) = 0 THEN
                            DISPLAY_ARABIC_ERROR(9, 190);
                        ELSE
                            p_rec.customs_entered := 1;
                        END IF;
                    ELSE
                        p_rec.customs_entered := 0;
                    END IF;
                ELSE
                    DISPLAY_ARABIC_ERROR(9, 250);
                END IF;
            ELSIF p_rec.comm_rgstrtn_type = 2 THEN
                IF p_rec.bus_id IS NOT NULL AND p_rec.bus_id_brnch IS NOT NULL THEN
                    SELECT COUNT(bus_id) INTO v_cnt
                      FROM comm_impr_rgstr
                     WHERE bus_id       = p_rec.bus_id
                       AND brnch_bus_id = p_rec.bus_id_brnch;
                    IF v_cnt = 0 THEN
                        v_ret := lib_usr.gnrl.get_customs_setting(p_ctx.curr_port_cd, 'COMM_TABLE_UNCHECK', 9);
                        IF NVL(v_ret, 0) = 0 THEN
                            DISPLAY_ARABIC_ERROR(9, 190);
                        ELSE
                            p_rec.customs_entered := 1;
                        END IF;
                    ELSE
                        p_rec.customs_entered := 0;
                    END IF;
                ELSE
                    DISPLAY_ARABIC_ERROR(9, 230);
                END IF;
            ELSE
                NULL;  -- APEX (read_only_rules.md): entrable('COMM_RGSTRTN_TYPE', TRUE);
                DISPLAY_ARABIC_ERROR(9, 240);
            END IF;
        END IF;
        p_rec.mobile_no := p_rec.b_mobile_no;
    END IMPORTERS_PRE_UPDATE;

    -- Source: IMPORTERS.POST-UPDATE
    --@ORIG IMPORTERS.POST-UPDATE
    -- >>> Original Forms code: IMPORTERS.POST-UPDATE
    --   BEGIN
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID' , FALSE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_BRNCH', FALSE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_EXPRD_DT' , FALSE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.ARBC_IMPR_NAME' , FALSE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.COMM_RGSTRTN_TYPE' , FALSE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_BRNCH' , FALSE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.CITY_CODE_OF_ID',FALSE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_TYPE_CD' , FALSE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_EXPR_TYPE' , FALSE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_TYPE_CD' , FALSE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.BRNH_CITY_CD' , FALSE);
    --        IF DB_JOURNAL.IS_JOURNALING_ON THEN
    --           DB_JOURNAL.JOURNALING_OFF;
    --        END IF;
    --   END;
    --   IF :GLOBAL.FLAGUPDATE = 1 THEN
    --   UPDATE_BASIC_IMPORTER;
    --   :GLOBAL.FLAGUPDATE := 0;
    --   END IF;
    -- <<<
    PROCEDURE IMPORTERS_POST_UPDATE (p_rec IN OUT NOCOPY T_RECORD)
    IS
    BEGIN
        NULL;  -- APEX (read_only_rules.md): lock_key_items;
        IF db_journal.is_journaling_on THEN
            db_journal.journaling_off;
        END IF;
        IF GET_GLOBAL('FLAGUPDATE') = '1' THEN
            update_basic_importer(p_rec);
            SET_GLOBAL('FLAGUPDATE', '0');
        END IF;
    END IMPORTERS_POST_UPDATE;

    -- Source: IMPORTERS.PRE-DELETE
    --@ORIG IMPORTERS.PRE-DELETE
    -- >>> Original Forms code: IMPORTERS.PRE-DELETE
    --   BEGIN
    --       IF NOT ACTIVITY.ADD_ACTIVITY(9, 2, 5, :IMPORTERS.Port_Cd||'!'||:IMPORTERS.Impr_Nbr) THEN
    --           RAISE FORm_Trigger_Failure;
    --       END IF;
    --   END;
    -- <<<
    PROCEDURE IMPORTERS_PRE_DELETE (p_rec IN T_RECORD, p_ctx IN T_CONTEXT)
    IS
    BEGIN
        add_activity(5, p_rec, p_ctx);
    END IMPORTERS_PRE_DELETE;

    -- Source: IMPORTERS.KEY-DELREC, branch "ALERT_BUTTON1" (Confirm DA 'هل أنت متأكد من عملية الحذف')
    -- The REMOVE button visible+enabled check -> Server-side Condition / Authorization of DELETE.
    -- HIGH: FORMS_DDL('COMMIT') after deleting IMPR_UPDTS and the final COMMIT are removed:
    -- in Forms the IMPR_UPDTS rows stay deleted even if the importer delete fails; in APEX both
    -- are in one transaction. Block property DeleteAllowed = false - see open questions.
    --@ORIG IMPORTERS.KEY-DELREC
    -- >>> Original Forms code: IMPORTERS.KEY-DELREC
    --   DECLARE
    --       RET  NUMBER;
    --       PROP VARCHAR2(10);
    --       STAT VARCHAR2(10);
    --       PROP1 VARCHAR2(10);
    --   BEGIN
    --     STAT := NAME_IN('SYSTEM.RECORD_STATUS');
    --     PROP1 := GET_ITEM_PROPERTY('REMOVE',VISIBLE);
    --     PROP  := GET_ITEM_PROPERTY('REMOVE',ENABLED);
    --     IF PROP = 'FALSE' AND PROP1 = 'FALSE' THEN
    --          NULL;
    --     ELSIF STAT !='NEW' AND PROP = 'TRUE' AND PROP1 = 'TRUE' THEN
    --       BEGIN
    --           RET := STR.DispAlert('هل أنت متأكد من عملية الحذف','WARNING');
    --           IF RET = ALERT_BUTTON1 THEN
    --           DELETE     IMPR_UPDTS
    --           WHERE     PORT_CD     = :IMPORTERS.PORT_CD
    --           AND        IMPR_NBR     = :IMPORTERS.IMPR_NBR
    --           ;
    --           FORMS_DDL('COMMIT');
    --                Delete_record;
    --               COMMIT;
    --            ELSIF RET = ALERT_BUTTON2 THEN
    --              NULL;
    --          END IF;
    --       END;
    --   END IF;
    --   END;
    -- <<<
    PROCEDURE importers_key_delrec (p_rec IN T_RECORD, p_ctx IN T_CONTEXT)
    IS
    BEGIN
        IF NVL(p_rec.rec_status, 'QUERY') != 'NEW' THEN
            DELETE impr_updts
             WHERE port_cd  = p_rec.port_cd
               AND impr_nbr = p_rec.impr_nbr;
            -- FORMS_DDL('COMMIT');   -- removed, see header
            IMPORTERS_PRE_DELETE(p_rec, p_ctx);       -- Delete_Record -> PRE-DELETE
            DELETE importers                        -- Forms default DELETE (key mode ROWID)
             WHERE ROWID = CHARTOROWID(p_rec.row_id);
            -- COMMIT;                -- removed, see header
        END IF;
    END importers_key_delrec;

    -- Source: IMPORTERS.ON-ERROR (+ PU CGTE$CHECK_CONSTRAINT_VIO).
    -- p_op = 'I' / 'U' / 'D' (FRM-40508 / 40509 / 40510). Returns the text Forms shows.
    --@ORIG IMPORTERS.ON-ERROR
    -- >>> Original Forms code: IMPORTERS.ON-ERROR
    --   BEGIN
    --     DECLARE
    --       err_code        CONSTANT NUMBER         := ERROR_CODE;
    --       err_type        CONSTANT VARCHAR2(3)    := ERROR_TYPE;
    --       server_err               NUMBER         := abs(DBMS_ERROR_CODE);
    --       server_msg               VARCHAR2(2000) := DBMS_ERROR_TEXT;
    --       constraint_name          VARCHAR2(61);
    --     BEGIN
    --         IF server_err = 1031 THEN
    --   IF (err_type = 'FRM' AND
    --           err_code = 40508 ) THEN
    --   Des$Form_errors.PUSH('ليس لديك صلاحية الادخال ' ,'E', 'OFG',0);
    --   END IF;
    --   IF (err_type = 'FRM' AND
    --           err_code = 40509 ) THEN
    --   Des$Form_errors.PUSH('ليس لديك صلاحية التعديل' ,'E', 'OFG',0);
    --   END IF;
    --   IF (err_type = 'FRM' AND
    --           err_code = 40510 ) THEN
    --   Des$Form_errors.PUSH('ليس لديك صلاحية الحذف' ,'E', 'OFG',0);
    --   END IF;
    --   END IF;
    --     END;
    --     END;
    --   BEGIN
    --     DECLARE
    --       err_code        CONSTANT NUMBER         := ERROR_CODE;
    --       err_type        CONSTANT VARCHAR2(3)    := ERROR_TYPE;
    --       server_err               NUMBER         := abs(DBMS_ERROR_CODE);
    --       server_msg               VARCHAR2(2000) := DBMS_ERROR_TEXT;
    --       constraint_name          VARCHAR2(61);
    --     BEGIN
    --       IF (err_type = 'FRM' AND
    --           err_code IN (40506, 40508, 40509, 40510) ) THEN
    --         WHILE (server_err = 604) LOOP
    --           CGTE$POP_ERROR_STACK(server_err, server_msg);
    --         END LOOP;
    --         IF ( CGTE$CHECK_CONSTRAINT_VIO(server_err, server_msg) ) THEN
    --           Des$Form_errors.RAISE_FAILURE;
    --         END IF;
    --         constraint_name := CGTE$STRIP_CONSTRAINT(server_msg);
    --         IF (server_err = 2291) THEN
    --           IF (constraint_name = 'IMP_SDP_FK') THEN
    --             Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(13, 'This <p1> does not exist', 'رمز الجمــــــــــــــرك' ), 'E', 'OFG', 13);
    --           ELSIF (constraint_name = 'IMP_NATIONALITY_FK') THEN
    --             Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(13, 'This <p1> does not exist', 'NATIONALITY' ), 'E', 'OFG', 13);
    --           ELSIF (constraint_name = 'IMP_ITIDT_FK') THEN
    --             Des$Form_errors.PUSH('رمز النشاط التجاري غير صحيح - أعد إدخال البيانات', 'E', 'OFG', 0);
    --           ELSIF (constraint_name = 'IMP_IMP_FK') THEN
    --             Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(13, 'This <p1> does not exist', 'IMPR_NBR_PARENT,PORT_CD' ), 'E', 'OFG', 13);
    --           ELSIF (constraint_name = 'IMP_CTRY_FK') THEN
    --             Des$Form_errors.PUSH('رمز الدولة غير صحيح - أعد ادخال البيانات', 'E', 'OFG', 0);
    --           ELSIF (constraint_name = 'IMP_BUS_ID_CITY_FK') THEN
    --             Des$Form_errors.PUSH('خطأ في رمز مدينة مصدر الرقم الإستدلالي', 'E', 'OFG', 0);
    --           ELSIF (constraint_name = 'IMP_ADD_CITY_FK') THEN
    --             Des$Form_errors.PUSH('خطأ في رمز مدينة عنوان المستورد', 'E', 'OFG', 0);
    --           ELSE
    --             Des$Form_errors.PUSH(server_msg, 'I', 'OFG', 0);
    --           END IF;
    --           Des$Form_errors.RAISE_FAILURE;
    --         END IF;
    --         IF (server_err = 2292) THEN
    --           IF (err_code = 40509) THEN
    --             Des$Form_errors.PUSH(server_msg, 'I', 'OFG', 0);
    --           END IF;
    --           Des$Form_errors.RAISE_FAILURE;
    --         END IF;
    --       END IF;
    --       IF (err_type = 'FRM' AND
    --           err_code = 40735 ) THEN
    --         WHILE (server_err = 604) LOOP
    --           CGTE$POP_ERROR_STACK(server_err, server_msg);
    --         END LOOP;
    --         Des$Form_errors.PUSH(err_type||'-'||to_char(server_err)||': '||server_msg, 'I', 'OFG', 0);
    --         Des$Form_errors.RAISE_FAILURE;
    --       END IF;
    --       Des$Form_errors.PUSH(err_type||'-'||to_char(err_code)||': '||ERROR_TEXT, 'I', 'OFG', 0);
    --       Des$Form_errors.RAISE_FAILURE;
    --     END;
    --   END;
    -- <<<
    --@ORIG PU CGTE$CHECK_CONSTRAINT_VIO
    -- >>> Original Forms code: PU CGTE$CHECK_CONSTRAINT_VIO
    --   FUNCTION CGTE$CHECK_CONSTRAINT_VIO(
    --      P_SERVER_ERR IN NUMBER
    --     ,P_SERVER_MSG IN VARCHAR2)
    --   RETURN BOOLEAN IS
    --     constraint_name VARCHAR2(61);
    --   BEGIN
    --     IF ( NOT (P_SERVER_ERR IN  (1, 2290) OR
    --              (P_SERVER_ERR >= 20000 AND P_SERVER_ERR <= 20999) ) )
    --     THEN
    --       RETURN( FALSE );
    --     END IF;
    --     IF (P_SERVER_ERR >= 20000 AND P_SERVER_ERR <= 20999) THEN
    --       Des$Form_errors.PUSH(''||CGTE$STRIP_FIRST_ERROR(P_SERVER_MSG), 'E', 'OFG', 0);
    --       RETURN( TRUE );
    --     END IF;
    --     constraint_name := CGTE$STRIP_CONSTRAINT(P_SERVER_MSG);
    --     IF (P_SERVER_ERR = 1) THEN
    --       IF (constraint_name = 'IMP_PK') THEN
    --         Des$Form_errors.PUSH('هذا السجل مدخل سابقاً - أعد ادخال البيانات', 'E', 'OFG', 0);
    --       ELSIF (constraint_name = 'IMP_BUSID_UK') THEN
    --         Des$Form_errors.PUSH('هذا السجل مدخل سابقاً - أعد ادخال البيانات', 'E', 'OFG', 0);
    --       ELSIF (constraint_name = 'SDP_PK') THEN
    --         Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(6, 'Row exists already with same <p1>', 'رمز الجمرك' ), 'E', 'OFG', 6);
    --       ELSIF (constraint_name = 'ITIDT_PK') THEN
    --         Des$Form_errors.PUSH('هذا السجل مدخل سابقاً - أعد ادخال البيانات', 'E', 'OFG', 0);
    --       ELSIF (constraint_name = 'IT_PK') THEN
    --         Des$Form_errors.PUSH('هذا السجل مدخل سابقاً - أعد ادخال البيانات', 'E', 'OFG', 0);
    --       ELSIF (constraint_name = 'BIT_PK') THEN
    --         Des$Form_errors.PUSH('هذا السجل مدخل سابقاً - أعد ادخال البيانات', 'E', 'OFG', 0);
    --       ELSIF (constraint_name = 'CT_PK') THEN
    --         Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(6, 'Row exists already with same <p1>', 'City Cd,رمز الدولة' ), 'E', 'OFG', 6);
    --       ELSIF (constraint_name = 'CT_PK') THEN
    --         Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(6, 'Row exists already with same <p1>', 'City Cd,رمز الدولة' ), 'E', 'OFG', 6);
    --       ELSIF (constraint_name = 'CTRY_PK') THEN
    --         Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(6, 'Row exists already with same <p1>', 'رمز الدولة' ), 'E', 'OFG', 6);
    --       ELSIF (constraint_name = 'CTRY_PK') THEN
    --         Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(6, 'Row exists already with same <p1>', 'Ctry Cd' ), 'E', 'OFG', 6);
    --       ELSE
    --         Des$Form_errors.PUSH(P_SERVER_MSG, 'I', 'OFG', 0);
    --       END IF;
    --     ELSIF (P_SERVER_ERR = 2290) THEN
    --       Des$Form_errors.PUSH(P_SERVER_MSG, 'I', 'OFG', 0);
    --     END IF;
    --     RETURN( TRUE );
    --   END;
    -- <<<
    FUNCTION importers_on_error (p_op IN VARCHAR2, p_sqlcode IN NUMBER, p_sqlerrm IN VARCHAR2)
        RETURN VARCHAR2
    IS
        server_err      NUMBER := ABS(p_sqlcode);
        constraint_name VARCHAR2(61);
    BEGIN
        IF server_err = 1031 THEN
            IF p_op = 'I' THEN RETURN 'ليس لديك صلاحية الادخال '; END IF;
            IF p_op = 'U' THEN RETURN 'ليس لديك صلاحية التعديل'; END IF;
            IF p_op = 'D' THEN RETURN 'ليس لديك صلاحية الحذف'; END IF;
        END IF;
        -- CGTE$CHECK_CONSTRAINT_VIO
        IF server_err BETWEEN 20000 AND 20999 THEN
            -- CGTE$STRIP_FIRST_ERROR (MISSING SOURCE): text without the "ORA-2xxxx: " prefix
            RETURN REGEXP_REPLACE(REGEXP_SUBSTR(p_sqlerrm, '[^' || CHR(10) || ']+'), '^ORA-[0-9]+: ');
        END IF;
        constraint_name := strip_constraint(p_sqlerrm);
        IF server_err = 1 THEN
            IF constraint_name IN ('IMP_PK', 'IMP_BUSID_UK', 'ITIDT_PK', 'IT_PK', 'BIT_PK') THEN
                RETURN 'هذا السجل مدخل سابقاً - أعد ادخال البيانات';
            ELSIF constraint_name = 'SDP_PK' THEN
                RETURN CG_MESSAGE('Row exists already with same <p1>', 'رمز الجمرك');
            ELSIF constraint_name = 'CT_PK' THEN
                RETURN CG_MESSAGE('Row exists already with same <p1>', 'City Cd,رمز الدولة');
            ELSIF constraint_name = 'CTRY_PK' THEN
                RETURN CG_MESSAGE('Row exists already with same <p1>', 'رمز الدولة');
            END IF;
            RETURN p_sqlerrm;
        ELSIF server_err = 2290 THEN
            RETURN p_sqlerrm;
        END IF;
        -- FK - parent key not found
        IF server_err = 2291 THEN
            IF constraint_name = 'IMP_SDP_FK' THEN
                RETURN CG_MESSAGE('This <p1> does not exist', 'رمز الجمــــــــــــــرك');
            ELSIF constraint_name = 'IMP_NATIONALITY_FK' THEN
                RETURN CG_MESSAGE('This <p1> does not exist', 'NATIONALITY');
            ELSIF constraint_name = 'IMP_ITIDT_FK' THEN
                RETURN 'رمز النشاط التجاري غير صحيح - أعد إدخال البيانات';
            ELSIF constraint_name = 'IMP_IMP_FK' THEN
                RETURN CG_MESSAGE('This <p1> does not exist', 'IMPR_NBR_PARENT,PORT_CD');
            ELSIF constraint_name = 'IMP_CTRY_FK' THEN
                RETURN 'رمز الدولة غير صحيح - أعد ادخال البيانات';
            ELSIF constraint_name = 'IMP_BUS_ID_CITY_FK' THEN
                RETURN 'خطأ في رمز مدينة مصدر الرقم الإستدلالي';
            ELSIF constraint_name = 'IMP_ADD_CITY_FK' THEN
                RETURN 'خطأ في رمز مدينة عنوان المستورد';
            END IF;
            RETURN p_sqlerrm;
        END IF;
        -- FK - child record found
        IF server_err = 2292 THEN
            RETURN p_sqlerrm;
        END IF;
        RETURN p_sqlerrm;
    END importers_on_error;

    -- Source: IMPORTERS.PORT_CD.WHEN-VALIDATE-ITEM (first block fully commented out in Forms)
    --@ORIG IMPORTERS.PORT_CD.WHEN-VALIDATE-ITEM
    -- >>> Original Forms code: IMPORTERS.PORT_CD.WHEN-VALIDATE-ITEM
    --   BEGIN
    --   NULL;
    --   END;
    --   BEGIN
    --     IF (name_in('IMPORTERS.PORT_CD') IS NOT NULL) THEN
    --       BEGIN
    --         CGFK$CHK_IMPORTERS_IMP_SDP_FK(
    --           :IMPORTERS.PORT_NAME
    --          ,:IMPORTERS.SDP_PORT_STATUS
    --          ,:IMPORTERS.PORT_CD        );
    --       EXCEPTION
    --         WHEN NO_DATA_FOUND THEN
    --           Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(13, 'This <p1> does not exist', 'رمز الجمــــــــــــــرك' ), 'E', 'OFG', 13);
    --           Des$Form_errors.RAISE_FAILURE;
    --         WHEN OTHERS THEN
    --           CGTE$OTHER_EXCEPTIONS;
    --       END;
    --     END IF;
    --   END;
    -- <<<
    PROCEDURE PORT_CD_WHEN_VALIDATE_ITEM (p_rec IN OUT NOCOPY T_RECORD)
    IS
    BEGIN
        IF p_rec.port_cd IS NOT NULL THEN
            SELECT l_sdp.port_status, l_sdp.port_name
              INTO p_rec.sdp_port_status, p_rec.port_name
              FROM sd_ports l_sdp
             WHERE l_sdp.port_cd = p_rec.port_cd;
        END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            FORM_TRIGGER_FAILURE(CG_MESSAGE('This <p1> does not exist', 'رمز الجمــــــــــــــرك'));
    END PORT_CD_WHEN_VALIDATE_ITEM;

    -- Source: IMPORTERS.HQ_IMPR_NBR.POST-CHANGE (same body: BUS_ID, BUS_ID_BRNCH, IMPR_EXPR_TYPE)
    PROCEDURE HQ_IMPR_NBR_POST_CHANGE
    IS
    BEGIN
        SET_GLOBAL('FLAGUPDATE', '1');
    END HQ_IMPR_NBR_POST_CHANGE;

    -- Source: IMPORTERS.IMPR_NBR.WHEN-VALIDATE-ITEM
    -- APEX: when an existing number is typed, the page re-queries that importer
    -- (EXEC_QUERY_NOW=1 is consumed by IMPR_TYPE_CD/BUS_ID_EXPRD_DT/block WHEN-NEW-ITEM-INSTANCE).
    --@ORIG IMPORTERS.IMPR_NBR.WHEN-VALIDATE-ITEM
    -- >>> Original Forms code: IMPORTERS.IMPR_NBR.WHEN-VALIDATE-ITEM
    --   DECLARE
    --       rec_count NUMBER;
    --   BEGIN
    --   IF (:IMPORTERS.IMPR_NBR IS NOT NULL) THEN
    --       SELECT COUNT(*) INTO Rec_Count
    --       FROM IMPORTERS
    --       WHERE PORT_CD = :IMPORTERS.PORT_CD
    --       AND IMPR_NBR = :IMPORTERS.IMPR_NBR;
    --       IF Rec_Count <> 0 THEN
    --           :global.PORT_CD    := :IMPORTERS.PORT_CD;
    --           :global.IMPR_NBR    := :IMPORTERS.IMPR_NBR;
    --           :global.Exec_Query_Now := 1;
    --       ELSE
    --           rec_count := STR.DispArbMsg(9, 150,'INFORMATION');
    --           RAISE FORm_Trigger_Failure;
    --       END IF;
    --   END IF;
    --   END;
    -- <<<
    PROCEDURE IMPR_NBR_WHEN_VALIDATE_ITEM (p_rec IN OUT NOCOPY T_RECORD)
    IS
        rec_count NUMBER;
    BEGIN
        IF (p_rec.impr_nbr IS NOT NULL) THEN
            SELECT COUNT(*) INTO rec_count
              FROM importers
             WHERE port_cd  = p_rec.port_cd
               AND impr_nbr = p_rec.impr_nbr;
            IF rec_count <> 0 THEN
                SET_GLOBAL('PORT_CD', p_rec.port_cd);
                SET_GLOBAL('IMPR_NBR', p_rec.impr_nbr);
                SET_GLOBAL('EXEC_QUERY_NOW', '1');
            ELSE
                DISPLAY_ARABIC_ERROR(9, 150);
            END IF;
        END IF;
    END IMPR_NBR_WHEN_VALIDATE_ITEM;

    -- Source: IMPORTERS.IMPR_TYPE_CD.WHEN-VALIDATE-ITEM
    --@ORIG IMPORTERS.IMPR_TYPE_CD.WHEN-VALIDATE-ITEM
    -- >>> Original Forms code: IMPORTERS.IMPR_TYPE_CD.WHEN-VALIDATE-ITEM
    --   DECLARE
    --       IMPR_SEQ VARCHAR2(6);
    --       BUS_ID_COUNT NUMBER;
    --       V_COUNT NUMBER;
    --       RET NUMBER;
    --       V_COUNT_IMPR_TYPE_CD NUMBER;
    --   BEGIN
    --   BEGIN
    --       IF :IMPR_NBR IS NOT NULL THEN
    --           IF NVL(:IMPORTERS.IMPR_TYPE_CD,0) NOT IN (4,9) AND :IMPR_NBR > TO_NUMBER(NVL(gnrl.get_customs_setting ('CREATE_IMPR_NBR',9),5000000)) THEN
    --               RET:=Str.DispArbMsg(9, 332,'INFORMATION');
    --               RAISE FORM_TRIGGER_FAILURE;
    --           END IF;
    --       ELSE
    --           IF NVL(:IMPORTERS.IMPR_TYPE_CD,0) NOT IN (4,9) THEN
    --               RET:=Str.DispArbMsg(9, 332,'INFORMATION');
    --               RAISE FORM_TRIGGER_FAILURE;
    --           END IF;
    --       END IF;
    --   END;
    --   IF NVL(gnrl.get_customs_setting ('STOP_IMPR_CR_TYPE',9),0) = 1 THEN
    --   SELECT COUNT(*) INTO  V_COUNT_IMPR_TYPE_CD
    --   FROM     IMPR_TYPE_ID_TYPES
    --   WHERE IMPR_TYPE_CD     = :IMPORTERS.IMPR_TYPE_CD
    --   AND   BUS_ID_TYPE_CD     = 2
    --   AND   STATUS         = 1
    --   ;
    --       IF  V_COUNT_IMPR_TYPE_CD > 0  THEN
    --             RET:=Str.DispArbMsg(9, 331,'INFORMATION');
    --             RAISE FORM_TRIGGER_FAILURE;
    --       END IF;
    --   END IF;
    --   IF :GLOBAL.VALID  = 0 THEN
    --       IF :IMPORTERS.IMPR_TYPE_CD IS NOT NULL THEN
    --           SELECT COUNT(*)
    --           INTO BUS_ID_COUNT
    --           FROM IMPR_TYPE_ID_TYPES
    --           WHERE IMPR_TYPE_CD = :IMPORTERS.IMPR_TYPE_CD
    --            AND  STATUS=1 ;
    --           IF BUS_ID_COUNT = 1 THEN
    --               SELECT IT.BUS_ID_TYPE_CD, IDT.BUS_ID_TYPE_NAME
    --               INTO :IMPORTERS.BUS_ID_TYPE_CD, :IMPORTERS.BUS_ID_TYPE_NAME
    --               FROM IMPR_TYPE_ID_TYPES IT, BUS_ID_TYPES IDT
    --               WHERE IT.IMPR_TYPE_CD = :IMPORTERS.IMPR_TYPE_CD
    --                      AND IT.STATUS=1
    --                 AND IT.BUS_ID_TYPE_CD = IDT.BUS_ID_TYPE_CD;
    --           ELSIF BUS_ID_COUNT > 1   THEN
    --                DO_KEY('LIST_VALUES ');
    --           ELSE
    --                 :IMPORTERS.IMPR_TYPE_CD:=NULL;
    --                 RET:=Str.DispArbMsg(2, 170,'INFORMATION');
    --                 RAISE FORM_TRIGGER_FAILURE;
    --           END IF;
    --       END IF;
    --   END IF;
    --   :GLOBAL.VALID:=0;
    --   IF :IMPORTERS.IMPR_TYPE_CD IS NOT NULL THEN
    --       SELECT     IMPR_TYPE_NAME
    --       INTO        :IMPORTERS.IMPR_TYPE_NAME
    --       FROM        IMPR_TYPES
    --       WHERE        IMPR_TYPE_CD = :IMPORTERS.IMPR_TYPE_CD ;
    --   END IF;
    --   IF     :GLOBAL.FUNS_IMP = 0 THEN
    --       IF :IMPORTERS.BUS_ID_TYPE_CD  = 2  AND :IMPORTERS.IMPR_TYPE_CD !=12 THEN
    --           INTRFACE.Make_Field_Entrable('IMPORTERS.COMM_RGSTRTN_TYPE' , TRUE);
    --           SET_ITEM_PROPERTY('IMPORTERS.COMM_RGSTRTN_TYPE',REQUIRED,PROPERTY_TRUE);
    --       ELSE
    --           INTRFACE.Make_Field_Entrable('IMPORTERS.COMM_RGSTRTN_TYPE' , FALSE);
    --           SET_ITEM_PROPERTY('IMPORTERS.COMM_RGSTRTN_TYPE',REQUIRED,PROPERTY_FALSE);
    --       END IF;
    --       IF :IMPORTERS.IMPR_TYPE_CD = 1 THEN
    --           :IMPORTERS.CTRY_CD := 100;
    --           :IMPORTERS.ADD_CTRY_CD := 100;
    --           INTRFACE.Make_Field_Entrable('IMPORTERS.CTRY_CD' , FALSE);
    --           INTRFACE.Make_Field_Entrable('IMPORTERS.ADD_CTRY_CD' , FALSE);
    --       ELSIF :IMPORTERS.IMPR_TYPE_CD = 2 THEN
    --           :IMPORTERS.CTRY_CD := 100;
    --           :IMPORTERS.ADD_CTRY_CD := 100;
    --           INTRFACE.Make_Field_Entrable('IMPORTERS.CTRY_CD' , FALSE);
    --           INTRFACE.Make_Field_Entrable('IMPORTERS.ADD_CTRY_CD' , FALSE);
    --           INTRFACE.Make_Field_Entrable('IMPORTERS.CITY_CODE_OF_ID' , FALSE);
    --           SET_ITEM_PROPERTY('IMPORTERS.CITY_CODE_OF_ID2' , ENABLED , PROPERTY_FALSE);
    --           INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_BRNCH' , FALSE);
    --       ELSIF :IMPORTERS.IMPR_TYPE_CD = 4 THEN
    --           IF :IMPORTERS.BUS_ID_TYPE_CD = 5 THEN
    --               :IMPORTERS.CTRY_CD := 100;
    --               :IMPORTERS.ADD_CTRY_CD := 100;
    --           END IF;
    --           INTRFACE.Make_Field_Entrable('IMPORTERS.CITY_CODE_OF_ID' , FALSE);
    --           SET_ITEM_PROPERTY('IMPORTERS.CITY_CODE_OF_ID2' , ENABLED , PROPERTY_FALSE);
    --           INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_BRNCH' , FALSE);
    --       ELSIF :IMPORTERS.IMPR_TYPE_CD = 5 THEN
    --           :IMPORTERS.CTRY_CD := 100;
    --           :IMPORTERS.ADD_CTRY_CD := 100;
    --           INTRFACE.Make_Field_Entrable('IMPORTERS.CTRY_CD' , FALSE);
    --           INTRFACE.Make_Field_Entrable('IMPORTERS.ADD_CTRY_CD' , FALSE);
    --       ELSIF :IMPORTERS.IMPR_TYPE_CD = 7 THEN
    --           INTRFACE.Make_Field_Entrable('IMPORTERS.CITY_CODE_OF_ID' , FALSE);
    --           SET_ITEM_PROPERTY('IMPORTERS.CITY_CODE_OF_ID2' , ENABLED , PROPERTY_FALSE);
    --           INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_BRNCH' , FALSE);
    --       ELSIF :IMPORTERS.IMPR_TYPE_CD = 8 THEN
    --           :IMPORTERS.CTRY_CD := 100;
    --           :IMPORTERS.ADD_CTRY_CD := 100;
    --           INTRFACE.Make_Field_Entrable('IMPORTERS.CTRY_CD' , FALSE);
    --           INTRFACE.Make_Field_Entrable('IMPORTERS.ADD_CTRY_CD' , FALSE);
    --       ELSIF :IMPORTERS.IMPR_TYPE_CD = 9 THEN
    --           :IMPORTERS.CTRY_CD := 100;
    --           :IMPORTERS.ADD_CTRY_CD := 100;
    --           IF :IMPORTERS.BUS_ID_TYPE_CD IS NULL THEN
    --               :IMPORTERS.BUS_ID_TYPE_CD := 6;
    --           END IF;
    --           IF :IMPORTERS.BUS_ID_TYPE_CD = 6 THEN
    --               SELECT LPAD(--KING_IMPR_SEQ.NEXTVAL
    --               GNRL.GET_SEQUENCE_VALUE (:PARAMETER.P_CURR_PORT_CD,'KING_IMPR_SEQ')
    --               , 6,'0') INTO IMPR_SEQ FROM DUAL;
    --               :IMPORTERS.BUS_ID := 'ملكى'||IMPR_SEQ;
    --               INTRFACE.Make_Field_Entrable('IMPORTERS.CTRY_CD' , FALSE);
    --               INTRFACE.Make_Field_Entrable('IMPORTERS.ADD_CTRY_CD' , FALSE);
    --               INTRFACE.Make_Field_Entrable('IMPORTERS.CITY_CODE_OF_ID' , FALSE);
    --               SET_ITEM_PROPERTY('IMPORTERS.CITY_CODE_OF_ID2' , ENABLED , PROPERTY_FALSE);
    --               INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_BRNCH' , FALSE);
    --               INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID' , FALSE);
    --           ELSE
    --               INTRFACE.Make_Field_Entrable('IMPORTERS.CTRY_CD' , TRUE);
    --               INTRFACE.Make_Field_Entrable('IMPORTERS.ADD_CTRY_CD' , TRUE);
    --               INTRFACE.Make_Field_Entrable('IMPORTERS.CITY_CODE_OF_ID' , TRUE);
    --               SET_ITEM_PROPERTY('IMPORTERS.CITY_CODE_OF_ID2' , ENABLED , PROPERTY_TRUE);
    --               INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID' , TRUE);
    --               INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_BRNCH' , FALSE);
    --           END IF;
    --       ELSIF :IMPORTERS.IMPR_TYPE_CD = 10 THEN
    --               INTRFACE.Make_Field_Entrable('IMPORTERS.CITY_CODE_OF_ID' , FALSE);
    --               SET_ITEM_PROPERTY('IMPORTERS.CITY_CODE_OF_ID2' , ENABLED , PROPERTY_FALSE);
    --               INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_BRNCH' , FALSE);
    --       ELSIF :IMPORTERS.IMPR_TYPE_CD = 11 THEN
    --               :IMPORTERS.CTRY_CD := 100;
    --               :IMPORTERS.ADD_CTRY_CD := 100;
    --               INTRFACE.Make_Field_Entrable('IMPORTERS.CTRY_CD' , FALSE);
    --               INTRFACE.Make_Field_Entrable('IMPORTERS.ADD_CTRY_CD' , FALSE);
    --               INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_BRNCH' , FALSE);
    --       ELSIF :IMPORTERS.IMPR_TYPE_CD = 12 THEN
    --               INTRFACE.Make_Field_Entrable('IMPORTERS.CITY_CODE_OF_ID' , FALSE);
    --               SET_ITEM_PROPERTY('IMPORTERS.CITY_CODE_OF_ID2' , ENABLED , PROPERTY_FALSE);
    --               IF :CTRY_CD IS NOT NULL THEN
    --                   SELECT COUNT(*)
    --                   INTO     V_COUNT
    --                   FROM     CTRY_GROUP_DETAILS
    --                   WHERE  CTRY_CD = :CTRY_CD
    --                   AND     CTRY_GRP_STAT = 1
    --                   AND     CTRY_GRP_NBR = 1
    --                   ;
    --                   IF V_COUNT = 0 THEN
    --                       STR.DISPALERT('لابد أن تكون دولة المستورد الخليجي تابعة لدول مجلس التعاون','INFORMATION');
    --                       RAISE FORM_TRIGGER_FAILURE;
    --                   END IF;
    --               END IF;
    --       ELSIF :IMPORTERS.IMPR_TYPE_CD IN (13,14,16,17,18,20) THEN
    --           SELECT --IMPORTERS_SEQ.NEXTVAL
    --           GNRL.GET_SEQUENCE_VALUE (:PARAMETER.P_CURR_PORT_CD,'IMPORTERS_SEQ')
    --            INTO :IMPORTERS.BUS_ID FROM DUAL;
    --               IF :IMPORTERS.BUS_ID IS NULL THEN
    --                   :IMPORTERS.BUS_ID := 1;
    --               END IF;
    --               :IMPORTERS.CTRY_CD := 100;
    --               :IMPORTERS.ADD_CTRY_CD := 100;
    --               INTRFACE.Make_Field_Entrable('IMPORTERS.CTRY_CD' , FALSE);
    --               INTRFACE.Make_Field_Entrable('IMPORTERS.ADD_CTRY_CD' , FALSE);
    --               INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID' , FALSE);
    --               INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_BRNCH' , FALSE);
    --               INTRFACE.Make_Field_Entrable('IMPORTERS.CITY_CODE_OF_ID' , FALSE);
    --               SET_ITEM_PROPERTY('IMPORTERS.CITY_CODE_OF_ID2' , ENABLED , PROPERTY_FALSE);
    --       END IF;
    --       IF :IMPORTERS.CTRY_CD IS NOT NULL THEN
    --           SELECT CRTY_ARBC_NAME
    --           INTO :CRTY_ARBC_NAME
    --           FROM COUNTRIES
    --           WHERE CTRY_CD = :IMPORTERS.CTRY_CD;
    --       END IF;
    --       IF :IMPORTERS.ADD_CTRY_CD IS NOT NULL THEN
    --           SELECT CRTY_ARBC_NAME
    --           INTO :ADD_CRTY_ARBC_NAME
    --           FROM COUNTRIES
    --           WHERE CTRY_CD = :IMPORTERS.ADD_CTRY_CD;
    --       END IF;
    --   END IF;
    --   CHECK_BUS_ID;
    --   END;
    --   BEGIN
    --     IF (name_in('IMPORTERS.IMPR_TYPE_CD') IS NOT NULL AND name_in('IMPORTERS.BUS_ID_TYPE_CD') IS NOT NULL) THEN
    --       BEGIN
    --         CGFK$CHK_IMPORTERS_IMP_ITIDT_F(
    --           :IMPORTERS.BUS_ID_TYPE_NAME
    --          ,:IMPORTERS.IMPR_TYPE_NAME
    --          ,:IMPORTERS.STATUS
    --          ,:IMPORTERS.ITIDT_NOTE
    --          ,:IMPORTERS.IMPR_TYPE_CD
    --          ,:IMPORTERS.BUS_ID_TYPE_CD  );
    --       EXCEPTION
    --         WHEN NO_DATA_FOUND THEN
    --           Des$Form_errors.PUSH('رمز النشاط التجاري غير صحيح - أعد إدخال البيانات', 'E', 'OFG', 0);
    --           Des$Form_errors.RAISE_FAILURE;
    --         WHEN OTHERS THEN
    --           CGTE$OTHER_EXCEPTIONS;
    --       END;
    --     END IF;
    --   END;
    -- <<<
    PROCEDURE IMPR_TYPE_CD_VALIDATE_ITEM (p_rec IN OUT NOCOPY T_RECORD, p_ctx IN T_CONTEXT)
    IS
        impr_seq             VARCHAR2(6);
        bus_id_count         NUMBER;
        v_count              NUMBER;
        v_count_impr_type_cd NUMBER;
    BEGIN
        IF p_rec.impr_nbr IS NOT NULL THEN
            IF NVL(p_rec.impr_type_cd, 0) NOT IN (4, 9)
               AND p_rec.impr_nbr > TO_NUMBER(NVL(gnrl.get_customs_setting('CREATE_IMPR_NBR', 9), 5000000)) THEN
                DISPLAY_ARABIC_ERROR(9, 332);
            END IF;
        ELSE
            IF NVL(p_rec.impr_type_cd, 0) NOT IN (4, 9) THEN
                DISPLAY_ARABIC_ERROR(9, 332);
            END IF;
        END IF;

        IF NVL(gnrl.get_customs_setting('STOP_IMPR_CR_TYPE', 9), 0) = 1 THEN
            SELECT COUNT(*) INTO v_count_impr_type_cd
              FROM impr_type_id_types
             WHERE impr_type_cd   = p_rec.impr_type_cd
               AND bus_id_type_cd = 2
               AND status         = 1;
            IF v_count_impr_type_cd > 0 THEN
                DISPLAY_ARABIC_ERROR(9, 331);
            END IF;
        END IF;

        IF GET_GLOBAL('VALID') = '0' THEN
            IF p_rec.impr_type_cd IS NOT NULL THEN
                SELECT COUNT(*)
                  INTO bus_id_count
                  FROM impr_type_id_types
                 WHERE impr_type_cd = p_rec.impr_type_cd
                   AND status = 1;
                IF bus_id_count = 1 THEN
                    SELECT it.bus_id_type_cd, idt.bus_id_type_name
                      INTO p_rec.bus_id_type_cd, p_rec.bus_id_type_name
                      FROM impr_type_id_types it, bus_id_types idt
                     WHERE it.impr_type_cd   = p_rec.impr_type_cd
                       AND it.status         = 1
                       AND it.bus_id_type_cd = idt.bus_id_type_cd;
                ELSIF bus_id_count > 1 THEN
                    NULL;  -- APEX (read_only_rules.md): ui('IMPR_TYPE_CD', 'OPEN_LOV', TRUE);
                ELSE
                    p_rec.impr_type_cd := NULL;
                    DISPLAY_ARABIC_ERROR(2, 170);
                END IF;
            END IF;
        END IF;
        SET_GLOBAL('VALID', '0');
        IF p_rec.impr_type_cd IS NOT NULL THEN
            SELECT impr_type_name
              INTO p_rec.impr_type_name
              FROM impr_types
             WHERE impr_type_cd = p_rec.impr_type_cd;
        END IF;

        IF GET_GLOBAL('FUNS_IMP') = '0' THEN
            IF p_rec.bus_id_type_cd = 2 AND p_rec.impr_type_cd != 12 THEN
                NULL;  -- APEX (read_only_rules.md): entrable('COMM_RGSTRTN_TYPE', TRUE);
                NULL;  -- APEX (read_only_rules.md): ui('COMM_RGSTRTN_TYPE', 'REQUIRED', TRUE);
            ELSE
                NULL;  -- APEX (read_only_rules.md): entrable('COMM_RGSTRTN_TYPE', FALSE);
                NULL;  -- APEX (read_only_rules.md): ui('COMM_RGSTRTN_TYPE', 'REQUIRED', FALSE);
            END IF;
            IF p_rec.impr_type_cd IN (1, 2, 5, 8, 11) THEN
                p_rec.ctry_cd     := 100;
                p_rec.add_ctry_cd := 100;
            ELSIF p_rec.impr_type_cd = 4 THEN
                IF p_rec.bus_id_type_cd = 5 THEN
                    p_rec.ctry_cd     := 100;
                    p_rec.add_ctry_cd := 100;
                END IF;
            ELSIF p_rec.impr_type_cd = 9 THEN
                p_rec.ctry_cd     := 100;
                p_rec.add_ctry_cd := 100;
                IF p_rec.bus_id_type_cd IS NULL THEN
                    p_rec.bus_id_type_cd := 6;
                END IF;
                IF p_rec.bus_id_type_cd = 6 THEN
                    SELECT LPAD(gnrl.get_sequence_value(p_ctx.curr_port_cd, 'KING_IMPR_SEQ'), 6, '0')
                      INTO impr_seq
                      FROM dual;
                    p_rec.bus_id := 'ملكى' || impr_seq;
                END IF;
            ELSIF p_rec.impr_type_cd = 12 THEN
                NULL;  -- APEX (read_only_rules.md): TYPE_ENTRABLE_QUERY(p_rec);
                IF p_rec.ctry_cd IS NOT NULL THEN
                    SELECT COUNT(*)
                      INTO v_count
                      FROM ctry_group_details
                     WHERE ctry_cd       = p_rec.ctry_cd
                       AND ctry_grp_stat = 1
                       AND ctry_grp_nbr  = 1;
                    IF v_count = 0 THEN
                        FORM_TRIGGER_FAILURE('لابد أن تكون دولة المستورد الخليجي تابعة لدول مجلس التعاون');
                    END IF;
                END IF;
            ELSIF p_rec.impr_type_cd IN (13, 14, 16, 17, 18, 20) THEN
                SELECT gnrl.get_sequence_value(p_ctx.curr_port_cd, 'IMPORTERS_SEQ')
                  INTO p_rec.bus_id
                  FROM dual;
                IF p_rec.bus_id IS NULL THEN
                    p_rec.bus_id := 1;
                END IF;
                p_rec.ctry_cd     := 100;
                p_rec.add_ctry_cd := 100;
            END IF;
            -- entrable state per type: identical to the POST-QUERY branches, except type 11
            -- (POST-QUERY same) and types 16/17/18/20 (only here) - handled below.
            IF p_rec.impr_type_cd IN (16, 17, 18, 20) THEN
                NULL;  -- APEX (read_only_rules.md): entrable('CTRY_CD', FALSE); entrable('ADD_CTRY_CD', FALSE);
                NULL;  -- APEX (read_only_rules.md): entrable('BUS_ID', FALSE); entrable('BUS_ID_BRNCH', FALSE);
                NULL;  -- APEX (read_only_rules.md): entrable('CITY_CODE_OF_ID', FALSE); ui('CITY_CODE_OF_ID2', 'ENABLED', FALSE);
            ELSE
                NULL;  -- APEX (read_only_rules.md): TYPE_ENTRABLE_QUERY(p_rec);
            END IF;
            IF p_rec.ctry_cd IS NOT NULL THEN
                SELECT crty_arbc_name
                  INTO p_rec.crty_arbc_name
                  FROM countries
                 WHERE ctry_cd = p_rec.ctry_cd;
            END IF;
            IF p_rec.add_ctry_cd IS NOT NULL THEN
                SELECT crty_arbc_name
                  INTO p_rec.add_crty_arbc_name
                  FROM countries
                 WHERE ctry_cd = p_rec.add_ctry_cd;
            END IF;
        END IF;
        check_bus_id;

        -- CGFK$VALDIDATE_FK_OVF (CGFK$CHK_IMPORTERS_IMP_ITIDT_F)
        IF p_rec.impr_type_cd IS NOT NULL AND p_rec.bus_id_type_cd IS NOT NULL THEN
            BEGIN
                SELECT itidt.note, itidt.status, it.impr_type_name, bit.bus_id_type_name
                  INTO p_rec.itidt_note, p_rec.status, p_rec.impr_type_name, p_rec.bus_id_type_name
                  FROM impr_type_id_types itidt, impr_types it, bus_id_types bit
                 WHERE itidt.bus_id_type_cd = p_rec.bus_id_type_cd
                   AND itidt.impr_type_cd   = p_rec.impr_type_cd
                   AND it.impr_type_cd      = itidt.impr_type_cd
                   AND bit.bus_id_type_cd   = itidt.bus_id_type_cd
                   AND ROWNUM = 1;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    FORM_TRIGGER_FAILURE('رمز النشاط التجاري غير صحيح - أعد إدخال البيانات');
            END;
        END IF;
    END IMPR_TYPE_CD_VALIDATE_ITEM;

    -- Source: IMPORTERS.IMPR_TYPE_CD.POST-CHANGE
    --@ORIG IMPORTERS.IMPR_TYPE_CD.POST-CHANGE
    -- >>> Original Forms code: IMPORTERS.IMPR_TYPE_CD.POST-CHANGE
    --   BEGIN
    --   :GLOBAL.FLAGUPDATE := 1;
    --   IF :IMPR_TYPE_CD IN (1,3,5,6,8,19)
    --       THEN
    --        SET_ITEM_PROPERTY('CITY_CODE_OF_ID',REQUIRED,PROPERTY_TRUE);
    --   END IF ;
    --   END;
    -- <<<
    PROCEDURE IMPR_TYPE_CD_POST_CHANGE (p_rec IN T_RECORD)
    IS
    BEGIN
        SET_GLOBAL('FLAGUPDATE', '1');
        IF p_rec.impr_type_cd IN (1, 3, 5, 6, 8, 19) THEN
            NULL;  -- APEX (read_only_rules.md): ui('CITY_CODE_OF_ID', 'REQUIRED', TRUE);
        END IF;
    END IMPR_TYPE_CD_POST_CHANGE;

    -- Source: IMPORTERS.IMPR_TYPE_CD.WHEN-NEW-ITEM-INSTANCE
    -- First block (EXEC_QUERY_NOW = 1 -> Clear_Block + EXECUTE_QUERY) is navigation: the page
    -- re-queries when IMPR_NBR_WHEN_VALIDATE_ITEM set EXEC_QUERY_NOW (see IMPORTERS_PRE_QUERY).
    --@ORIG IMPORTERS.IMPR_TYPE_CD.WHEN-NEW-ITEM-INSTANCE
    -- >>> Original Forms code: IMPORTERS.IMPR_TYPE_CD.WHEN-NEW-ITEM-INSTANCE
    --   BEGIN
    --   IF :global.Exec_Query_Now = 1 THEN
    --       Clear_Block(No_Validate);
    --       execute_query;
    --   END IF;
    --   END;
    --   DECLARE
    --   ret    NUMBER;
    --   BEGIN
    --   IF :IMPR_TYPE_CD = 4  AND  :BUS_ID_TYPE_CD = 3
    --   OR :IMPR_TYPE_CD = 4  AND  :BUS_ID_TYPE_CD = 5 THEN
    --   :CTRY_CD := 100;
    --   SET_ITEM_PROPERTY('CTRY_CD', ENABLED,PROPERTY_FALSE);
    --   SELECT CRTY_ARBC_NAME INTO :CRTY_ARBC_NAME
    --    FROM   COUNTRIES
    --    WHERE  CTRY_CD = 100;
    --   END IF;
    --   :ADD_CTRY_CD := 100 ;
    --   SET_ITEM_PROPERTY('ADD_CTRY_CD', ENABLED,PROPERTY_FALSE);
    --   SELECT CRTY_ARBC_NAME INTO :ADD_CRTY_ARBC_NAME
    --    FROM   COUNTRIES
    --    WHERE  CTRY_CD = 100;
    --   EXCEPTION
    --   WHEN NO_DATA_FOUND THEN
    --     ret := Str.DispArbMsg(18, 15,'ERROR');
    --     RAISE FORM_TRIGGER_FAILURE;
    --   END;
    -- <<<
    PROCEDURE IMPR_TYPE_CD_NEW_ITEM_INSTANCE (p_rec IN OUT NOCOPY T_RECORD)
    IS
    BEGIN
        IF GET_GLOBAL('EXEC_QUERY_NOW') = '1' THEN
            NULL;  -- APEX (read_only_rules.md): ui('IMPORTERS', 'REQUERY', TRUE);
        END IF;
        ctry_100_defaults(p_rec);
    END IMPR_TYPE_CD_NEW_ITEM_INSTANCE;

    -- Source: IMPORTERS.IMPR_TYPE_CD.KEY-LISTVAL, part after CALL_FORM('LOV_Impr_Type')
    -- (the LOV form returned :GLOBAL.IMPR_TYPE_CD/_NAME and BUS_ID_TYPE_CD/_NAME).
    -- p_rec already carries the returned values (NULL = nothing selected).
    PROCEDURE IMPR_TYPE_CD_LOV_RETURN (p_rec IN OUT NOCOPY T_RECORD)
    IS
    BEGIN
        IF p_rec.impr_type_cd IS NOT NULL THEN
            SET_GLOBAL('VALID', '1');
            ctry_100_defaults(p_rec);
        ELSE
            p_rec.impr_type_cd     := NULL;
            p_rec.impr_type_name   := NULL;
            p_rec.bus_id_type_cd   := NULL;
            p_rec.bus_id_type_name := NULL;
        END IF;
    END IMPR_TYPE_CD_LOV_RETURN;

    -- Source: IMPORTERS.BUS_ID_EXPRD_DT.WHEN-VALIDATE-ITEM
    --@ORIG IMPORTERS.BUS_ID_EXPRD_DT.WHEN-VALIDATE-ITEM
    -- >>> Original Forms code: IMPORTERS.BUS_ID_EXPRD_DT.WHEN-VALIDATE-ITEM
    --   DECLARE
    --       HDATE DATE;
    --   BEGIN
    --       IF :System.TRIGGER_ITEM = :System.CURSOR_ITEM THEN
    --           IF :System.Cursor_Value IS NOT NULL THEN
    --               HDATE := TO_DATE(:System.Cursor_Value);
    --               IF NOT HIJDATE.VALID_HIJ_DATE(HDATE) THEN
    --                   RAISE FORM_TRIGGER_FAILURE;
    --               END IF;
    --           END IF;
    --       END IF;
    --   END;
    --   DECLARE
    --    RET NUMBER;
    --   BEGIN
    --    IF :SYSTEM.TRIGGER_ITEM = :SYSTEM.CURSOR_ITEM THEN
    --       IF :BUS_ID_EXPRD_DT < HIJDATE.Cur_Hij_Date THEN
    --          RET := Str.DispArbMsg(1,10,'ERROR');
    --             RAISE FORM_TRIGGER_FAILURE;
    --       END IF;
    --    END IF;
    --   END;
    -- <<<
    PROCEDURE BUS_ID_EXPRD_DT_VALIDATE_ITEM (p_rec IN T_RECORD, p_from_item IN BOOLEAN DEFAULT TRUE)
    IS
    BEGIN
        IF p_from_item THEN
            IF p_rec.bus_id_exprd_dt IS NOT NULL THEN
                IF NOT valid_hij_date(p_rec.bus_id_exprd_dt) THEN
                    FORM_TRIGGER_FAILURE;
                END IF;
            END IF;
        END IF;
        IF p_from_item THEN
            IF p_rec.bus_id_exprd_dt < cur_hij_date THEN
                DISPLAY_ARABIC_ERROR(1, 10);
            END IF;
        END IF;
    END BUS_ID_EXPRD_DT_VALIDATE_ITEM;

    -- Source: IMPORTERS.BUS_ID_TYPE_CD.POST-CHANGE
    -- SUGGESTION: Forms assigns the name of country 100 to ADD_CRTY_ARBC_NAME inside the IF and
    -- to CRTY_ARBC_NAME after it (swapped compared with the other copies of this block). Kept.
    --@ORIG IMPORTERS.BUS_ID_TYPE_CD.POST-CHANGE
    -- >>> Original Forms code: IMPORTERS.BUS_ID_TYPE_CD.POST-CHANGE
    --   BEGIN
    --   :GLOBAL.FLAGUPDATE := 1;
    --   DECLARE
    --   ret    NUMBER;
    --   BEGIN
    --   IF :IMPR_TYPE_CD = 4  AND  :BUS_ID_TYPE_CD = 3
    --   OR :IMPR_TYPE_CD = 4  AND  :BUS_ID_TYPE_CD = 5 THEN
    --   :CTRY_CD := 100;
    --   SET_ITEM_PROPERTY('CTRY_CD', ENABLED,PROPERTY_FALSE);
    --   SELECT CRTY_ARBC_NAME INTO :ADD_CRTY_ARBC_NAME
    --    FROM   COUNTRIES
    --    WHERE  CTRY_CD = 100;
    --   END IF;
    --   :ADD_CTRY_CD := 100 ;
    --   SET_ITEM_PROPERTY('ADD_CTRY_CD', ENABLED,PROPERTY_FALSE);
    --   SELECT CRTY_ARBC_NAME INTO :CRTY_ARBC_NAME
    --    FROM   COUNTRIES
    --    WHERE  CTRY_CD = 100;
    --   EXCEPTION
    --   WHEN NO_DATA_FOUND THEN
    --     ret := Str.DispArbMsg(18, 15,'ERROR');
    --     RAISE FORM_TRIGGER_FAILURE;
    --   END;
    --   END;
    -- <<<
    PROCEDURE BUS_ID_TYPE_CD_POST_CHANGE (p_rec IN OUT NOCOPY T_RECORD)
    IS
    BEGIN
        SET_GLOBAL('FLAGUPDATE', '1');
        BEGIN
            IF p_rec.impr_type_cd = 4 AND p_rec.bus_id_type_cd = 3
               OR p_rec.impr_type_cd = 4 AND p_rec.bus_id_type_cd = 5 THEN
                p_rec.ctry_cd := 100;
                NULL;  -- APEX (read_only_rules.md): ui('CTRY_CD', 'ENABLED', FALSE);
                SELECT crty_arbc_name INTO p_rec.add_crty_arbc_name
                  FROM countries
                 WHERE ctry_cd = 100;
            END IF;
            p_rec.add_ctry_cd := 100;
            NULL;  -- APEX (read_only_rules.md): ui('ADD_CTRY_CD', 'ENABLED', FALSE);
            SELECT crty_arbc_name INTO p_rec.crty_arbc_name
              FROM countries
             WHERE ctry_cd = 100;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                DISPLAY_ARABIC_ERROR(18, 15);
        END;
    END BUS_ID_TYPE_CD_POST_CHANGE;

    -- Source: IMPORTERS.COMM_RGSTRTN_TYPE.WHEN-LIST-CHANGED
    --@ORIG IMPORTERS.COMM_RGSTRTN_TYPE.WHEN-LIST-CHANGED
    -- >>> Original Forms code: IMPORTERS.COMM_RGSTRTN_TYPE.WHEN-LIST-CHANGED
    --   BEGIN
    --   IF :IMPORTERS.COMM_RGSTRTN_TYPE = 1 THEN
    --         :IMPORTERS.BUS_ID_BRNCH := NULL;
    --   INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_BRNCH' , FALSE);
    --   INTRFACE.Make_Field_Entrable('BRNH_CITY_CD',FALSE);
    --         SET_ITEM_PROPERTY('BRNH_CITY_CD',REQUIRED,PROPERTY_FALSE);
    --         SET_ITEM_PROPERTY('IMPORTERS.BUS_ID_BRNCH',ITEM_IS_VALID,PROPERTY_TRUE);
    --    ELSIF :IMPORTERS.COMM_RGSTRTN_TYPE = 2 THEN
    --         SET_ITEM_PROPERTY('BRNH_CITY_CD',REQUIRED,PROPERTY_true);
    --         INTRFACE.Make_Field_Entrable('BRNH_CITY_CD',TRUE);
    --         INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_BRNCH' , TRUE);
    --         SET_ITEM_PROPERTY('IMPORTERS.BUS_ID_BRNCH',ITEM_IS_VALID,PROPERTY_FALSE);
    --   END IF;
    --   END;
    -- <<<
    PROCEDURE COMM_RGSTRTN_TYPE_LIST_CHANGED (p_rec IN OUT NOCOPY T_RECORD)
    IS
    BEGIN
        IF p_rec.comm_rgstrtn_type = 1 THEN
            p_rec.bus_id_brnch := NULL;
            NULL;  -- APEX (read_only_rules.md): entrable('BUS_ID_BRNCH', FALSE);
            NULL;  -- APEX (read_only_rules.md): entrable('BRNH_CITY_CD', FALSE);
            NULL;  -- APEX (read_only_rules.md): ui('BRNH_CITY_CD', 'REQUIRED', FALSE);
            NULL;  -- APEX (read_only_rules.md): ui('BUS_ID_BRNCH', 'VALID', TRUE);
        ELSIF p_rec.comm_rgstrtn_type = 2 THEN
            NULL;  -- APEX (read_only_rules.md): ui('BRNH_CITY_CD', 'REQUIRED', TRUE);
            NULL;  -- APEX (read_only_rules.md): entrable('BRNH_CITY_CD', TRUE);
            NULL;  -- APEX (read_only_rules.md): entrable('BUS_ID_BRNCH', TRUE);
            NULL;  -- APEX (read_only_rules.md): ui('BUS_ID_BRNCH', 'VALID', FALSE);
        END IF;
    END COMM_RGSTRTN_TYPE_LIST_CHANGED;

    -- Source: IMPORTERS.CTRY_CD_OF_ID.WHEN-VALIDATE-ITEM (CGFK$WVI_CLR_DEPS_OVF)
    --@ORIG IMPORTERS.CTRY_CD_OF_ID.WHEN-VALIDATE-ITEM
    -- >>> Original Forms code: IMPORTERS.CTRY_CD_OF_ID.WHEN-VALIDATE-ITEM
    --   BEGIN
    --     IF (name_in('IMPORTERS.CITY_CODE_OF_ID') IS NULL AND name_in('IMPORTERS.CTRY_CD_OF_ID') IS NULL) THEN
    --       IF (:SYSTEM.RECORD_STATUS = 'NEW') THEN
    --         RETURN;
    --       END IF;
    --       BEGIN
    --         CGSF$CLRLU_IMPORTERS_IMP_BUS_I;
    --       EXCEPTION
    --         WHEN OTHERS THEN
    --           CGTE$OTHER_EXCEPTIONS;
    --       END;
    --     END IF;
    --   END;
    -- <<<
    PROCEDURE CTRY_CD_OF_ID_VALIDATE_ITEM (p_rec IN OUT NOCOPY T_RECORD)
    IS
    BEGIN
        IF p_rec.city_code_of_id IS NULL AND p_rec.ctry_cd_of_id IS NULL THEN
            IF p_rec.rec_status = 'NEW' THEN
                RETURN;
            END IF;
            CGSF$CLRLU_IMPORTERS_IMP_BUS_I(p_rec);
        END IF;
    END CTRY_CD_OF_ID_VALIDATE_ITEM;

    -- Source: IMPORTERS.CITY_CODE_OF_ID.WHEN-VALIDATE-ITEM
    --@ORIG IMPORTERS.CITY_CODE_OF_ID.WHEN-VALIDATE-ITEM
    -- >>> Original Forms code: IMPORTERS.CITY_CODE_OF_ID.WHEN-VALIDATE-ITEM
    --   DECLARE
    --   V_BUS_ID VARCHAR2(6);
    --   V_ALL_BUS_ID VARCHAR2(10);
    --   V_ID_MINS_COMM_CD VARCHAR2(4);
    --   V_USER_BUS_ID VARCHAR2(4);
    --   Alert_txt   VARCHAR2(80);
    --   al_button NUMBER;
    --   SYS_ID NUMBER;
    --   MSG_CD NUMBER;
    --   RET NUMBER;
    --   BEGIN
    --                       BEGIN
    --                          SELECT city_arb_name
    --                            INTO :importers.id_city_name
    --                            FROM cities
    --                           WHERE city_cd = :city_code_of_id AND ctry_cd = :ctry_cd_of_id;
    --                       EXCEPTION
    --                          WHEN OTHERS THEN NULL;
    --                       END;
    --   END;
    --   BEGIN
    --     IF (name_in('IMPORTERS.CITY_CODE_OF_ID') IS NULL AND name_in('IMPORTERS.CTRY_CD_OF_ID') IS NULL) THEN
    --       IF (:SYSTEM.RECORD_STATUS = 'NEW') THEN
    --         RETURN;
    --       END IF;
    --       BEGIN
    --         CGSF$CLRLU_IMPORTERS_IMP_BUS_I;
    --       EXCEPTION
    --         WHEN OTHERS THEN
    --           CGTE$OTHER_EXCEPTIONS;
    --       END;
    --     END IF;
    --   END;
    --   BEGIN
    --     IF (name_in('IMPORTERS.CITY_CODE_OF_ID') IS NOT NULL AND name_in('IMPORTERS.CTRY_CD_OF_ID') IS NOT NULL) THEN
    --       BEGIN
    --         CGFK$CHK_IMPORTERS_IMP_BUS_ID_(
    --           :IMPORTERS.ID_MINS_COMM_CD
    --          ,:IMPORTERS.ID_CITY_NAME
    --          ,:IMPORTERS.L_CT_CITY_STATUS2
    --          ,:IMPORTERS.CTRY_CD_OF_ID
    --          ,:IMPORTERS.CITY_CODE_OF_ID  );
    --       EXCEPTION
    --         WHEN NO_DATA_FOUND THEN
    --           Des$Form_errors.PUSH('خطأ في رمز مدينة مصدر الرقم الإستدلالي', 'W', 'OFG', 0);
    --         WHEN OTHERS THEN
    --           CGTE$OTHER_EXCEPTIONS;
    --       END;
    --     END IF;
    --   END;
    -- <<<
    PROCEDURE CITY_CODE_OF_ID_VALIDATE_ITEM (p_rec IN OUT NOCOPY T_RECORD)
    IS
    BEGIN
        BEGIN
            SELECT city_arb_name
              INTO p_rec.id_city_name
              FROM cities
             WHERE city_cd = p_rec.city_code_of_id
               AND ctry_cd = p_rec.ctry_cd_of_id;
        EXCEPTION
            WHEN OTHERS THEN
                NULL;
        END;
        -- CGFK$WVI_CLR_DEPS_OVF
        IF p_rec.city_code_of_id IS NULL AND p_rec.ctry_cd_of_id IS NULL THEN
            IF p_rec.rec_status = 'NEW' THEN
                RETURN;
            END IF;
            CGSF$CLRLU_IMPORTERS_IMP_BUS_I(p_rec);
        END IF;
        -- CGFK$VALDIDATE_FK_OVF (CGFK$CHK_IMPORTERS_IMP_BUS_ID_) - warning only ('W', no failure)
        IF p_rec.city_code_of_id IS NOT NULL AND p_rec.ctry_cd_of_id IS NOT NULL THEN
            BEGIN
                SELECT id_city.city_status, id_city.city_arb_name, id_city.mins_comm_cd
                  INTO p_rec.l_ct_city_status2, p_rec.id_city_name, p_rec.id_mins_comm_cd
                  FROM cities id_city
                 WHERE id_city.city_cd = p_rec.city_code_of_id
                   AND id_city.ctry_cd = p_rec.ctry_cd_of_id
                   AND id_city.city_status = 1
                   AND ROWNUM = 1;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    info('خطأ في رمز مدينة مصدر الرقم الإستدلالي');
            END;
        END IF;
    END CITY_CODE_OF_ID_VALIDATE_ITEM;

    -- Source: IMPORTERS.CITY_CODE_OF_ID.WHEN-NEW-ITEM-INSTANCE
    PROCEDURE CITY_CODE_OF_ID_WHEN_NEW_ITEM (p_rec IN T_RECORD)
    IS
    BEGIN
        IF p_rec.comm_rgstrtn_type = 2 THEN
            NULL;  -- APEX (read_only_rules.md): ui('BRNH_CITY_CD', 'REQUIRED', TRUE);
            NULL;  -- APEX (read_only_rules.md): ui('BRNH_CITY_CD', 'VALID', FALSE);
        END IF;
    END CITY_CODE_OF_ID_WHEN_NEW_ITEM;

    -- Suspended importer with the same BUS_ID (the WARNING inside BUS_ID_WHEN_VALIDATE_ITEM). 0 = no warning.
    FUNCTION BUS_ID_SUSPENDED_IMPORTER (p_rec IN T_RECORD) RETURN NUMBER
    IS
        v_count    NUMBER;
        v_impr_nbr NUMBER;
        v_hijdt    DATE;
    BEGIN
        IF (p_rec.bus_id_brnch IS NULL) AND (p_rec.comm_rgstrtn_type = 1 OR p_rec.comm_rgstrtn_type IS NULL) THEN
            v_hijdt := cur_hij_date;
            SELECT COUNT(*) INTO v_count
              FROM importers
             WHERE port_cd        = p_rec.port_cd
               AND ctry_cd        = NVL(p_rec.ctry_cd, ctry_cd)
               AND bus_id_type_cd = p_rec.bus_id_type_cd
               AND bus_id         = p_rec.bus_id
               AND bus_id_brnch IS NULL
               AND ((p_rec.impr_nbr IS NULL) OR (p_rec.impr_nbr IS NOT NULL AND impr_nbr <> p_rec.impr_nbr));
            IF v_count > 0 THEN
                SELECT NVL(MAX(impr_nbr), 0) INTO v_impr_nbr
                  FROM importers
                 WHERE port_cd        = p_rec.port_cd
                   AND ctry_cd        = NVL(p_rec.ctry_cd, ctry_cd)
                   AND bus_id_type_cd = p_rec.bus_id_type_cd
                   AND bus_id         = p_rec.bus_id
                   AND bus_id_brnch IS NULL
                   AND ((p_rec.impr_nbr IS NULL) OR (p_rec.impr_nbr IS NOT NULL AND impr_nbr <> p_rec.impr_nbr))
                   AND lib_usr.impr.impr_suspended(p_rec.port_cd, impr_nbr, v_hijdt) <> 1;
                IF v_impr_nbr = 0 THEN
                    SELECT NVL(MAX(impr_nbr), 0) INTO v_impr_nbr
                      FROM importers
                     WHERE port_cd        = p_rec.port_cd
                       AND ctry_cd        = NVL(p_rec.ctry_cd, ctry_cd)
                       AND bus_id_type_cd = p_rec.bus_id_type_cd
                       AND bus_id         = p_rec.bus_id
                       AND bus_id_brnch IS NULL
                       AND ((p_rec.impr_nbr IS NULL) OR (p_rec.impr_nbr IS NOT NULL AND impr_nbr <> p_rec.impr_nbr))
                       AND lib_usr.impr.impr_suspended(p_rec.port_cd, impr_nbr, v_hijdt) = 1;
                    RETURN v_impr_nbr;
                END IF;
            END IF;
        END IF;
        RETURN 0;
    END BUS_ID_SUSPENDED_IMPORTER;

    -- Source: IMPORTERS.BUS_ID.WHEN-VALIDATE-ITEM
    -- p_cr_answer  : alert 9-120 ("prefix the city commercial code?") - ALERT_BUTTON1 = c_yes.
    --                Shown as an 'ERROR' alert (normally a single OK button) -> default c_yes.
    -- p_susp_answer: WARNING "يوجد مستورد ... موقوف ..." (text: see BUS_ID_SUSPENDED_IMPORTER) - c_no clears BUS_ID.
    --@ORIG IMPORTERS.BUS_ID.WHEN-VALIDATE-ITEM
    -- >>> Original Forms code: IMPORTERS.BUS_ID.WHEN-VALIDATE-ITEM
    --   BEGIN
    --   CHK_IMPR_DUPL;
    --   DECLARE
    --   V_BUS_ID VARCHAR2(6);
    --   V_ALL_BUS_ID VARCHAR2(10);
    --   V_ID_MINS_COMM_CD VARCHAR2(4);
    --   V_USER_BUS_ID VARCHAR2(4);
    --   V_COUNT NUMBER;
    --   Alert_txt   VARCHAR2(100);
    --   al_button NUMBER;
    --   SYS_ID NUMBER;
    --   MSG_CD NUMBER;
    --   V_IMPR_NBR NUMBER;
    --   V_HIJDT DATE;
    --     V_CNT NUMBER;
    --     RET NUMBER;
    --     V_RET VARCHAR2(5);
    --   BEGIN
    --   IF (:IMPR_TYPE_CD in (1,3,5,6,8,19)  and LENGTH(:IMPORTERS.BUS_ID) != 10)
    --       THEN
    --              STR.DISPALERT(' يجب أن يكون الرقم الاستدلالي مكونا من عشرة ارقام ','ERROR');
    --                  RAISE FORM_TRIGGER_FAILURE;
    --         END IF;
    --     IF :BUS_ID_TYPE_CD IN( 5,3) AND :IMPR_TYPE_CD = 4 THEN
    --         :IMPORTERS.BUS_ID := LTRIM(RTRIM(:IMPORTERS.BUS_ID));
    --         IF LENGTH(:IMPORTERS.BUS_ID) != 10 THEN
    --              STR.DISPALERT(' يجب أن يكون الرقم الاستدلالي مكونا من عشرة ارقام ','ERROR');
    --                  RAISE FORM_TRIGGER_FAILURE;
    --         END IF;
    --         IF IS_Digit(:BUS_ID)= FALSE THEN
    --               RET := Str.DispArbMsg(9, 270,'ERROR');
    --                  RAISE FORM_TRIGGER_FAILURE;
    --         END IF;
    --     END IF;
    --     IF :IMPORTERS.BUS_ID_TYPE_CD = 2 AND :IMPORTERS.IMPR_TYPE_CD != 12  THEN
    --            IF IS_Digit(:BUS_ID)= FALSE THEN
    --               RET := Str.DispArbMsg(9, 270,'ERROR');
    --                  RAISE FORM_TRIGGER_FAILURE;
    --            END IF;
    --           IF NOT (LENGTH(:IMPORTERS.BUS_ID) <= 6 OR LENGTH(:IMPORTERS.BUS_ID) = 10) THEN
    --                   RET := Str.DispArbMsg(9, 260,'ERROR');
    --                   RAISE FORM_TRIGGER_FAILURE;
    --             END IF;
    --          IF :IMPORTERS.CITY_CODE_OF_ID IS NOT NULL THEN
    --               IF LENGTH(:IMPORTERS.BUS_ID) <= 6 THEN
    --               SELECT LPAD(:IMPORTERS.BUS_ID, 6,'0') INTO V_BUS_ID FROM dual;
    --               SELECT MINS_COMM_CD
    --               INTO :IMPORTERS.ID_MINS_COMM_CD
    --               FROM CITIES
    --               WHERE  CITY_CD = :IMPORTERS.CITY_CODE_OF_ID
    --               AND     CTRY_CD = :IMPORTERS.CTRY_CD_OF_ID;
    --               SELECT LPAD(TO_CHAR(:IMPORTERS.ID_MINS_COMM_CD), 4,'0') INTO V_ID_MINS_COMM_CD FROM dual;
    --               V_ALL_BUS_ID := CONCAT(V_ID_MINS_COMM_CD,V_BUS_ID);
    --               SYS_ID := 9;
    --               MSG_CD := 120;
    --               Alert_txt := STR_DB.GetArbMsg(SYS_ID, MSG_CD);
    --               IF Alert_txt = '-1' THEN
    --                     Alert_txt :='خطأ فى رقم الرسالة  '||sys_Id||'-'||Msg_Cd||'إتصل بالمسانده الفنيه';
    --                   al_button := STR.DispAlert(Alert_Txt, 'ERROR');
    --               ELSE
    --                   Alert_Txt :=sys_Id||'-'||Msg_Cd||' : '||Alert_Txt||' '||V_ALL_BUS_ID;
    --                   al_button := STR.DispAlert(Alert_Txt, 'ERROR');
    --                   IF al_button = alert_button1 THEN
    --                       :importers.BUS_ID := V_ALL_BUS_ID;
    --                   ELSIF al_button = alert_button2 THEN
    --                       RAISE Form_trigger_failure;
    --                   END IF;
    --                END IF;
    --             ELSIF LENGTH(:IMPORTERS.BUS_ID) = 10 THEN
    --               V_USER_BUS_ID := SUBSTR(:IMPORTERS.BUS_ID, 1, 4);
    --               IF TO_NUMBER(V_USER_BUS_ID) <> :IMPORTERS.ID_MINS_COMM_CD THEN
    --                   al_button := STR.DispArbMsg(9, 130, 'ERROR');
    --                   RAISE Form_trigger_failure;
    --               END IF;
    --           END IF;
    --          END IF;
    --        END IF;
    --        IF (:BUS_ID_BRNCH IS NULL) AND (:COMM_RGSTRTN_TYPE = 1 OR :COMM_RGSTRTN_TYPE IS NULL) THEN
    --       V_HIJDT :=HIJDATE.Cur_Hij_Date;
    --           SELECT COUNT(*) INTO V_COUNT
    --           FROM IMPORTERS
    --           WHERE PORT_CD = :IMPORTERS.PORT_CD
    --           AND    CTRY_CD = NVL(:IMPORTERS.CTRY_CD, CTRY_CD)
    --           AND    BUS_ID_TYPE_CD = :IMPORTERS.BUS_ID_TYPE_CD
    --           AND     BUS_ID  = :IMPORTERS.BUS_ID
    --           AND     BUS_ID_BRNCH IS NULL
    --           AND    ((:IMPORTERS.IMPR_NBR IS NULL) OR (:IMPORTERS.IMPR_NBR IS NOT NULL AND IMPR_NBR <> :IMPORTERS.IMPR_NBR));
    --           IF V_COUNT > 0 THEN
    --               SELECT NVL(MAX(IMPR_NBR),0)
    --               INTO     V_IMPR_NBR
    --               FROM   IMPORTERS
    --               WHERE  PORT_CD        = :IMPORTERS.PORT_CD
    --               AND     CTRY_CD        = NVL(:IMPORTERS.CTRY_CD, CTRY_CD)
    --               AND     BUS_ID_TYPE_CD = :IMPORTERS.BUS_ID_TYPE_CD
    --               AND       BUS_ID         = :IMPORTERS.BUS_ID
    --               AND      BUS_ID_BRNCH IS NULL
    --               AND     ((:IMPORTERS.IMPR_NBR IS NULL) OR (:IMPORTERS.IMPR_NBR IS NOT NULL AND IMPR_NBR <> :IMPORTERS.IMPR_NBR))
    --               AND    LIB_USR.IMPR.Impr_Suspended(:IMPORTERS.PORT_CD, IMPR_NBR, V_HIJDT) <> 1    ;
    --               IF V_IMPR_NBR <> 0 THEN
    --                   STR.DISPALERT(' لا يمكن تكرار الرقم الإستدلالي - الرقم الإستدلالي مستخدم لمستورد آخر مسلسله بالجمرك رقم : '||V_IMPR_NBR,'ERROR');
    --                   RAISE FORM_TRIGGER_FAILURE;
    --               ELSE
    --                   SELECT NVL(MAX(IMPR_NBR),0)
    --                   INTO     V_IMPR_NBR
    --                   FROM   IMPORTERS
    --                   WHERE  PORT_CD        = :IMPORTERS.PORT_CD
    --                   AND     CTRY_CD        = NVL(:IMPORTERS.CTRY_CD, CTRY_CD)
    --                   AND     BUS_ID_TYPE_CD = :IMPORTERS.BUS_ID_TYPE_CD
    --                   AND       BUS_ID         = :IMPORTERS.BUS_ID
    --                   AND      BUS_ID_BRNCH IS NULL
    --                   AND     ((:IMPORTERS.IMPR_NBR IS NULL) OR (:IMPORTERS.IMPR_NBR IS NOT NULL AND IMPR_NBR <> :IMPORTERS.IMPR_NBR))
    --                   AND    LIB_USR.IMPR.Impr_Suspended(:IMPORTERS.PORT_CD, IMPR_NBR, V_HIJDT) = 1    ;
    --                   RET := STR.DispAlert('يوجد مستورد'||V_IMPR_NBR||' موقوف له نفس الرقم الإستدلالي" هل تريد تعديل الرقم الاستدلالي بالرغم من ذلك ؟','WARNING');
    --                          IF RET = ALERT_BUTTON1 THEN
    --                           NULL;
    --                       ELSE
    --                           :BUS_ID := NULL;
    --                       END IF;
    --               END IF;
    --            END IF;
    --         END IF;
    --   IF :GLOBAL.FUNS_BUSID = 0 THEN
    --       IF :IMPORTERS.BUS_ID_TYPE_CD = 2 AND :IMPORTERS.IMPR_TYPE_CD != 12  THEN
    --         IF :COMM_RGSTRTN_TYPE = 1 THEN
    --               SELECT COUNT(BUS_ID) INTO V_CNT FROM COMM_IMPR_RGSTR
    --               WHERE  BUS_ID=:BUS_ID
    --                AND   BRNCHREG=0;
    --               IF V_CNT >1 THEN
    --                   RET := Str.DispArbMsg(9, 290,'ERROR');
    --                   RAISE FORM_TRIGGER_FAILURE;
    --           ELSIF V_CNT = 1 THEN
    --                  SELECT ARBC_IMPR_NAME,ARBC_NAME_STD,BUS_ID_EXPRD_DT,IMPR_TEL_NBR,IMPR_POB_NBR,IMPR_ZIP_CD,IMPR_FAX_NBR,IMPR_TELEX_NBR,ACTIVITY
    --                  INTO:ARBC_IMPR_NAME,:IMPR_NAME_STD,:BUS_ID_EXPRD_DT,:IMPR_TEL_NBR,:IMPR_POB_NBR,:IMPR_ZIP_CD,:IMPR_FAX_NBR,:IMPR_TELEX_NBR,:ACTIVITY
    --                  FROM COMM_IMPR_RGSTR
    --                  WHERE BUS_ID   =:BUS_ID
    --                  AND   BRNCHREG =0;
    --                  INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_EXPRD_DT' , FALSE);
    --                  INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_POB_NBR' , FALSE);
    --               INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_ZIP_CD' , FALSE);
    --              INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_TEL_NBR' , FALSE);
    --              INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_FAX_NBR' , FALSE);
    --              INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_TELEX_NBR' , FALSE);
    --              INTRFACE.Make_Field_Entrable('IMPORTERS.ARBC_IMPR_NAME' , FALSE);
    --              INTRFACE.Make_Field_Entrable('IMPORTERS.ACTIVITY' , FALSE);
    --                ELSE
    --                   V_RET := LIB_USR.GNRL.GET_CUSTOMS_SETTING('COMM_TABLE_UNCHECK',9);
    --                    IF NVL(V_RET,0) = 0 THEN
    --                      ret := Str.DispArbMsg(9, 190,'ERROR');
    --                    RAISE FORM_TRIGGER_FAILURE;
    --                  ELSE
    --                 INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_EXPRD_DT' , TRUE);
    --                       INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_POB_NBR' , TRUE);
    --                  INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_ZIP_CD' , TRUE);
    --                 INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_TEL_NBR' , TRUE);
    --                 INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_FAX_NBR' , TRUE);
    --                 INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_TELEX_NBR' , TRUE);
    --                 INTRFACE.Make_Field_Entrable('IMPORTERS.ARBC_IMPR_NAME' , TRUE);
    --                 INTRFACE.Make_Field_Entrable('IMPORTERS.ACTIVITY' , TRUE);
    --                     END IF;
    --                END IF;
    --           END IF;
    --   ELSE
    --       INTRFACE.Make_Field_Entrable('IMPORTERS.ACTIVITY' , TRUE);
    --        END IF;
    --    END IF;
    --   IF :BUS_ID IS NOT NULL AND :ACTIVITY IS NULL THEN
    --       INTRFACE.Make_Field_Entrable('IMPORTERS.ACTIVITY' , TRUE);
    --   ELSE
    --       INTRFACE.Make_Field_Entrable('IMPORTERS.ACTIVITY' , FALSE);
    --   END IF;
    --   CHECK_BUS_ID ;
    --   IF :IMPR_TYPE_CD=4 AND :BUS_ID_TYPE_CD=5 THEN
    --   :B_ID_NBR:=:BUS_ID;
    --   SET_ITEM_PROPERTY('B_ID_NBR',ENABLED,PROPERTY_FALSE);
    --   ELSE
    --   SET_ITEM_PROPERTY('B_ID_NBR',ENABLED,PROPERTY_TRUE);
    --   END IF;
    --   IF :IMPR_TYPE_CD=4 AND :BUS_ID_TYPE_CD IN(5,3) THEN
    --       IF  NOT CHECK_IDNO(:BUS_ID)THEN
    --           STR.DISPALERT('رقم الهوية المدخل غير صحيح.. يجب إدخال رقم هوية صحيح','ERROR');
    --           RAISE FORM_TRIGGER_FAILURE;
    --       END IF;
    --   END IF;
    --   END;
    --   BEGIN
    --      IF     GET_RECORD_PROPERTY (:SYSTEM.cursor_record,:SYSTEM.cursor_block,status) IN ('NEW', 'INSERT') AND
    --           :importers.IMPR_TYPE_CD IN ( 1,3,5,6,19 ) AND :importers.bus_id_type_cd = 2
    --            AND :GLOBAL.ALLOW_MCI = 1
    --      THEN
    --         IF :importers.comm_rgstrtn_type = 1 AND :importers.bus_id IS NOT NULL THEN
    --            get_main_cr_data;
    --         ELSIF :importers.comm_rgstrtn_type = 2 AND :importers.bus_id_brnch IS NOT NULL THEN
    --            get_branch_cr_data;
    --         END IF;
    --      END IF;
    --   END;
    --   END;
    --   BEGIN
    --   chk_bus_id_brnch ;
    --   END;
    -- <<<
    PROCEDURE BUS_ID_WHEN_VALIDATE_ITEM (p_rec         IN OUT NOCOPY T_RECORD,
                          p_ctx         IN T_CONTEXT,
                          p_cr_answer   IN PLS_INTEGER DEFAULT c_yes,
                          p_susp_answer IN PLS_INTEGER DEFAULT c_yes)
    IS
        v_bus_id          VARCHAR2(6);
        v_all_bus_id      VARCHAR2(10);
        v_id_mins_comm_cd VARCHAR2(4);
        v_user_bus_id     VARCHAR2(4);
        v_count           NUMBER;
        alert_txt         VARCHAR2(100);  -- SUGGESTION: 100 as in Forms; a long 9-120 text raises ORA-06502
        v_impr_nbr        NUMBER;
        v_hijdt           DATE;
        v_cnt             NUMBER;
        v_ret             VARCHAR2(5);
    BEGIN
        chk_impr_dupl(p_rec);
        IF (p_rec.impr_type_cd IN (1, 3, 5, 6, 8, 19) AND LENGTH(p_rec.bus_id) != 10) THEN
            FORM_TRIGGER_FAILURE(' يجب أن يكون الرقم الاستدلالي مكونا من عشرة ارقام ');
        END IF;
        IF p_rec.bus_id_type_cd IN (5, 3) AND p_rec.impr_type_cd = 4 THEN
            p_rec.bus_id := LTRIM(RTRIM(p_rec.bus_id));
            IF LENGTH(p_rec.bus_id) != 10 THEN
                FORM_TRIGGER_FAILURE(' يجب أن يكون الرقم الاستدلالي مكونا من عشرة ارقام ');
            END IF;
            IF is_digit(p_rec.bus_id) = FALSE THEN
                DISPLAY_ARABIC_ERROR(9, 270);
            END IF;
        END IF;
        IF p_rec.bus_id_type_cd = 2 AND p_rec.impr_type_cd != 12 THEN
            IF is_digit(p_rec.bus_id) = FALSE THEN
                DISPLAY_ARABIC_ERROR(9, 270);
            END IF;
            IF NOT (LENGTH(p_rec.bus_id) <= 6 OR LENGTH(p_rec.bus_id) = 10) THEN
                DISPLAY_ARABIC_ERROR(9, 260);
            END IF;
            IF p_rec.city_code_of_id IS NOT NULL THEN
                IF LENGTH(p_rec.bus_id) <= 6 THEN
                    v_bus_id := LPAD(p_rec.bus_id, 6, '0');
                    SELECT mins_comm_cd
                      INTO p_rec.id_mins_comm_cd
                      FROM cities
                     WHERE city_cd = p_rec.city_code_of_id
                       AND ctry_cd = p_rec.ctry_cd_of_id;
                    v_id_mins_comm_cd := LPAD(TO_CHAR(p_rec.id_mins_comm_cd), 4, '0');
                    v_all_bus_id := CONCAT(v_id_mins_comm_cd, v_bus_id);
                    alert_txt := str_db.getarbmsg(9, 120);
                    IF alert_txt = '-1' THEN
                        alert_txt := 'خطأ فى رقم الرسالة  ' || 9 || '-' || 120 || 'إتصل بالمسانده الفنيه';
                        info(alert_txt);
                    ELSE
                        alert_txt := 9 || '-' || 120 || ' : ' || alert_txt || ' ' || v_all_bus_id;
                        info(alert_txt);
                        IF p_cr_answer = c_yes THEN
                            p_rec.bus_id := v_all_bus_id;
                        ELSIF p_cr_answer = c_no THEN
                            FORM_TRIGGER_FAILURE;
                        END IF;
                    END IF;
                ELSIF LENGTH(p_rec.bus_id) = 10 THEN
                    v_user_bus_id := SUBSTR(p_rec.bus_id, 1, 4);
                    IF TO_NUMBER(v_user_bus_id) <> p_rec.id_mins_comm_cd THEN
                        DISPLAY_ARABIC_ERROR(9, 130);
                    END IF;
                END IF;
            END IF;
        END IF;

        IF (p_rec.bus_id_brnch IS NULL) AND (p_rec.comm_rgstrtn_type = 1 OR p_rec.comm_rgstrtn_type IS NULL) THEN
            v_hijdt := cur_hij_date;
            SELECT COUNT(*) INTO v_count
              FROM importers
             WHERE port_cd        = p_rec.port_cd
               AND ctry_cd        = NVL(p_rec.ctry_cd, ctry_cd)
               AND bus_id_type_cd = p_rec.bus_id_type_cd
               AND bus_id         = p_rec.bus_id
               AND bus_id_brnch IS NULL
               AND ((p_rec.impr_nbr IS NULL) OR (p_rec.impr_nbr IS NOT NULL AND impr_nbr <> p_rec.impr_nbr));
            IF v_count > 0 THEN
                SELECT NVL(MAX(impr_nbr), 0)
                  INTO v_impr_nbr
                  FROM importers
                 WHERE port_cd        = p_rec.port_cd
                   AND ctry_cd        = NVL(p_rec.ctry_cd, ctry_cd)
                   AND bus_id_type_cd = p_rec.bus_id_type_cd
                   AND bus_id         = p_rec.bus_id
                   AND bus_id_brnch IS NULL
                   AND ((p_rec.impr_nbr IS NULL) OR (p_rec.impr_nbr IS NOT NULL AND impr_nbr <> p_rec.impr_nbr))
                   AND lib_usr.impr.impr_suspended(p_rec.port_cd, impr_nbr, v_hijdt) <> 1;
                IF v_impr_nbr <> 0 THEN
                    FORM_TRIGGER_FAILURE(' لا يمكن تكرار الرقم الإستدلالي - الرقم الإستدلالي مستخدم لمستورد آخر مسلسله بالجمرك رقم : ' || v_impr_nbr);
                ELSE
                    -- WARNING 'يوجد مستورد'||V_IMPR_NBR||' موقوف له نفس الرقم الإستدلالي" هل تريد تعديل الرقم الاستدلالي بالرغم من ذلك ؟'
                    -- -> Confirm DA before this call (number from BUS_ID_SUSPENDED_IMPORTER)
                    IF p_susp_answer = c_yes THEN
                        NULL;
                    ELSE
                        p_rec.bus_id := NULL;
                    END IF;
                END IF;
            END IF;
        END IF;

        IF GET_GLOBAL('FUNS_BUSID') = '0' THEN
            IF p_rec.bus_id_type_cd = 2 AND p_rec.impr_type_cd != 12 THEN
                IF p_rec.comm_rgstrtn_type = 1 THEN
                    SELECT COUNT(bus_id) INTO v_cnt
                      FROM comm_impr_rgstr
                     WHERE bus_id   = p_rec.bus_id
                       AND brnchreg = 0;
                    IF v_cnt > 1 THEN
                        DISPLAY_ARABIC_ERROR(9, 290);
                    ELSIF v_cnt = 1 THEN
                        SELECT arbc_impr_name, arbc_name_std, bus_id_exprd_dt, impr_tel_nbr, impr_pob_nbr,
                               impr_zip_cd, impr_fax_nbr, impr_telex_nbr, activity
                          INTO p_rec.arbc_impr_name, p_rec.impr_name_std, p_rec.bus_id_exprd_dt,
                               p_rec.impr_tel_nbr, p_rec.impr_pob_nbr, p_rec.impr_zip_cd,
                               p_rec.impr_fax_nbr, p_rec.impr_telex_nbr, p_rec.activity
                          FROM comm_impr_rgstr
                         WHERE bus_id   = p_rec.bus_id
                           AND brnchreg = 0;
                        NULL;  -- APEX (read_only_rules.md): cr_fields_entrable(FALSE, TRUE);
                    ELSE
                        v_ret := lib_usr.gnrl.get_customs_setting('COMM_TABLE_UNCHECK', 9);
                        IF NVL(v_ret, 0) = 0 THEN
                            DISPLAY_ARABIC_ERROR(9, 190);
                        ELSE
                            NULL;  -- APEX (read_only_rules.md): cr_fields_entrable(TRUE, TRUE);
                        END IF;
                    END IF;
                END IF;
            ELSE
                NULL;  -- APEX (read_only_rules.md): entrable('ACTIVITY', TRUE);
            END IF;
        END IF;
        IF p_rec.bus_id IS NOT NULL AND p_rec.activity IS NULL THEN
            NULL;  -- APEX (read_only_rules.md): entrable('ACTIVITY', TRUE);
        ELSE
            NULL;  -- APEX (read_only_rules.md): entrable('ACTIVITY', FALSE);
        END IF;
        check_bus_id;
        IF p_rec.impr_type_cd = 4 AND p_rec.bus_id_type_cd = 5 THEN
            p_rec.b_id_nbr := p_rec.bus_id;
            NULL;  -- APEX (read_only_rules.md): ui('B_ID_NBR', 'ENABLED', FALSE);
        ELSE
            NULL;  -- APEX (read_only_rules.md): ui('B_ID_NBR', 'ENABLED', TRUE);
        END IF;
        IF p_rec.impr_type_cd = 4 AND p_rec.bus_id_type_cd IN (5, 3) THEN
            IF NOT check_idno(p_rec.bus_id) THEN
                FORM_TRIGGER_FAILURE('رقم الهوية المدخل غير صحيح.. يجب إدخال رقم هوية صحيح');
            END IF;
        END IF;

        IF p_rec.rec_status IN ('NEW', 'INSERT')
           AND p_rec.impr_type_cd IN (1, 3, 5, 6, 19) AND p_rec.bus_id_type_cd = 2
           AND GET_GLOBAL('ALLOW_MCI') = '1' THEN
            IF p_rec.comm_rgstrtn_type = 1 AND p_rec.bus_id IS NOT NULL THEN
                get_main_cr_data(p_rec);
            ELSIF p_rec.comm_rgstrtn_type = 2 AND p_rec.bus_id_brnch IS NOT NULL THEN
                get_branch_cr_data(p_rec);
            END IF;
        END IF;

        chk_bus_id_brnch(p_rec);
    END BUS_ID_WHEN_VALIDATE_ITEM;

    -- Source: IMPORTERS.BUS_ID.POST-CHANGE
    PROCEDURE BUS_ID_POST_CHANGE
    IS
    BEGIN
        SET_GLOBAL('FLAGUPDATE', '1');
    END BUS_ID_POST_CHANGE;

    -- Source: IMPORTERS.BUS_ID.WHEN-NEW-ITEM-INSTANCE
    --@ORIG IMPORTERS.BUS_ID.WHEN-NEW-ITEM-INSTANCE
    -- >>> Original Forms code: IMPORTERS.BUS_ID.WHEN-NEW-ITEM-INSTANCE
    --   DECLARE
    --    RET NUMBER;
    --   BEGIN
    --    IF :IMPORTERS.BUS_ID_TYPE_CD = 2 AND :IMPORTERS.IMPR_TYPE_CD != 12  THEN
    --      IF :COMM_RGSTRTN_TYPE IS NULL THEN
    --        SET_ITEM_PROPERTY('BUS_ID',REQUIRED,PROPERTY_FALSE);
    --        RET:=Str.DispArbMsg(9, 240,'ERROR');
    --        GO_ITEM('COMM_RGSTRTN_TYPE');
    --      END IF;
    --      IF :COMM_RGSTRTN_TYPE = 2 THEN
    --         SET_ITEM_PROPERTY('BRNH_CITY_CD',REQUIRED,PROPERTY_TRUE);
    --         SET_ITEM_PROPERTY('BRNH_CITY_CD',ITEM_IS_VALID,PROPERTY_FALSE);
    --      END IF;
    --   END IF;
    --       IF :CITY_CODE_OF_ID IS NOT NULL AND (:GLOBAL.MINS_COMM_CD IS NOT NULL OR :ID_MINS_COMM_CD IS NOT NULL )
    --          AND :BUS_ID IS NULL THEN
    --           STR.DISPALERT('الرمز التجاري للمدينة المحددة :  '||NVL(:GLOBAL.MINS_COMM_CD,:ID_MINS_COMM_CD) ,'INFORMATION');
    --           :GLOBAL.MINS_COMM_CD := NULL ;
    --       END IF;
    --   END;
    -- <<<
    PROCEDURE BUS_ID_WHEN_NEW_ITEM_INSTANCE (p_rec IN T_RECORD)
    IS
    BEGIN
        IF p_rec.bus_id_type_cd = 2 AND p_rec.impr_type_cd != 12 THEN
            IF p_rec.comm_rgstrtn_type IS NULL THEN
                NULL;  -- APEX (read_only_rules.md): ui('BUS_ID', 'REQUIRED', FALSE);
                DISPLAY_ARABIC_INFO(9, 240);
                NULL;  -- APEX (read_only_rules.md): ui_focus('COMM_RGSTRTN_TYPE');
            END IF;
            IF p_rec.comm_rgstrtn_type = 2 THEN
                NULL;  -- APEX (read_only_rules.md): ui('BRNH_CITY_CD', 'REQUIRED', TRUE);
                NULL;  -- APEX (read_only_rules.md): ui('BRNH_CITY_CD', 'VALID', FALSE);
            END IF;
        END IF;
        IF p_rec.city_code_of_id IS NOT NULL
           AND (GET_GLOBAL('MINS_COMM_CD') IS NOT NULL OR p_rec.id_mins_comm_cd IS NOT NULL)
           AND p_rec.bus_id IS NULL THEN
            info('الرمز التجاري للمدينة المحددة :  ' || NVL(GET_GLOBAL('MINS_COMM_CD'), p_rec.id_mins_comm_cd));
            SET_GLOBAL('MINS_COMM_CD', NULL);
        END IF;
    END BUS_ID_WHEN_NEW_ITEM_INSTANCE;

    -- Source: IMPORTERS.BRNH_CITY_CD.WHEN-VALIDATE-ITEM
    --@ORIG IMPORTERS.BRNH_CITY_CD.WHEN-VALIDATE-ITEM
    -- >>> Original Forms code: IMPORTERS.BRNH_CITY_CD.WHEN-VALIDATE-ITEM
    --   DECLARE
    --     RET NUMBER;
    --   BEGIN
    --    IF :BRNH_CITY_CD IS NOT NULL THEN
    --     SELECT CITY_ARB_NAME INTO :BRNH_CITY_NAME
    --     FROM   CITIES
    --     WHERE   CTRY_CD=:IMPORTERS.CTRY_CD_OF_ID
    --     AND     CITY_CD=:BRNH_CITY_CD;
    --    END IF;
    --   EXCEPTION
    --     WHEN NO_DATA_FOUND THEN
    --          RET := Str.DispArbMsg(1, 120,'ERROR');
    --          RAISE FORM_TRIGGER_FAILURE;
    --   END;
    -- <<<
    PROCEDURE BRNH_CITY_CD_VALIDATE_ITEM (p_rec IN OUT NOCOPY T_RECORD)
    IS
    BEGIN
        IF p_rec.brnh_city_cd IS NOT NULL THEN
            SELECT city_arb_name INTO p_rec.brnh_city_name
              FROM cities
             WHERE ctry_cd = p_rec.ctry_cd_of_id
               AND city_cd = p_rec.brnh_city_cd;
        END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DISPLAY_ARABIC_ERROR(1, 120);
    END BRNH_CITY_CD_VALIDATE_ITEM;

    -- Source: IMPORTERS.BRNH_CITY_CD.WHEN-NEW-ITEM-INSTANCE
    PROCEDURE BRNH_CITY_CD_NEW_ITEM_INSTANCE
    IS
    BEGIN
        NULL;  -- APEX (read_only_rules.md): ui('BRNH_CITY_CD', 'REQUIRED', FALSE);
        NULL;  -- APEX (read_only_rules.md): ui('BUS_ID_BRNCH', 'REQUIRED', TRUE);
        NULL;  -- APEX (read_only_rules.md): ui('BUS_ID_BRNCH', 'VALID', FALSE);
    END BRNH_CITY_CD_NEW_ITEM_INSTANCE;

    -- Source: IMPORTERS.BUS_ID_BRNCH.WHEN-VALIDATE-ITEM
    -- p_cr_answer: alert 9-120 ("سيتم تحويل الرقم الفرعي إلى الرقم ...") - ALERT_BUTTON1 = c_yes.
    -- SUGGESTION: the 10-digit branch check tests LENGTH(:BUS_ID) (main number), not
    -- LENGTH(:BUS_ID_BRNCH) - kept as in Forms.
    --@ORIG IMPORTERS.BUS_ID_BRNCH.WHEN-VALIDATE-ITEM
    -- >>> Original Forms code: IMPORTERS.BUS_ID_BRNCH.WHEN-VALIDATE-ITEM
    --   BEGIN
    --   IF GET_ITEM_PROPERTY('IMPORTERS.BUS_ID_BRNCH',ENABLED)= 'TRUE' THEN
    --   DECLARE
    --   V_BUS_ID VARCHAR2(6);
    --   V_ALL_BUS_ID VARCHAR2(10);
    --   V_ID_MINS_COMM_CD VARCHAR2(4);
    --   V_USER_BUS_ID VARCHAR2(4);
    --   V_COUNT NUMBER;
    --   Alert_txt   VARCHAR2(100);
    --   al_button NUMBER;
    --   SYS_ID NUMBER;
    --   MSG_CD NUMBER;
    --   V_IMPR_NBR NUMBER;
    --     V_CNT NUMBER;
    --     RET NUMBER;
    --     V_RET VARCHAR2(5);
    --   BEGIN
    --    IF :BUS_ID_BRNCH = '0' THEN
    --          ret := Str.DispArbMsg(1, 220,'ERROR');
    --          RAISE FORM_TRIGGER_FAILURE;
    --    END IF;
    --    IF :IMPORTERS.BUS_ID_TYPE_CD = 2 AND :IMPORTERS.IMPR_TYPE_CD != 12  THEN
    --        BEGIN
    --         IF IS_Digit(:BUS_ID_BRNCH)= FALSE THEN
    --             RET := Str.DispArbMsg(9, 270,'ERROR');
    --             RAISE FORM_TRIGGER_FAILURE;
    --         END IF;
    --        END;
    --       IF NOT (LENGTH(:IMPORTERS.BUS_ID_BRNCH) = 6 OR LENGTH(:IMPORTERS.BUS_ID_BRNCH) = 10) THEN
    --              RET := Str.DispArbMsg(9,260,'ERROR');
    --              RAISE form_trigger_failure;
    --       END IF;
    --       IF :IMPORTERS.BRNH_CITY_CD IS NOT NULL THEN
    --                     SELECT MINS_COMM_CD
    --               INTO :BRNH_ID_MINS_COMM_CD
    --               FROM CITIES
    --               WHERE  CITY_CD = :IMPORTERS.BRNH_CITY_CD
    --               AND     CTRY_CD = :IMPORTERS.CTRY_CD;--=100
    --               SELECT LPAD(:IMPORTERS.BRNH_ID_MINS_COMM_CD, 4,'0') INTO V_ID_MINS_COMM_CD FROM dual;
    --                 IF LENGTH(:IMPORTERS.BUS_ID_BRNCH) = 6 THEN
    --                   V_ALL_BUS_ID := CONCAT(V_ID_MINS_COMM_CD,:IMPORTERS.BUS_ID_BRNCH);
    --                   SYS_ID := 9;
    --                   MSG_CD := 120;
    --                   Alert_txt := STR_DB.GetArbMsg(SYS_ID, MSG_CD);
    --                   IF Alert_txt = '-1' THEN
    --                         Alert_txt :='خطأ فى رقم الرسالة  '||sys_Id||'-'||Msg_Cd||'إتصل بالمسانده الفنيه';
    --                       al_button := STR.DispAlert(Alert_Txt, 'ERROR');
    --                   ELSE
    --                       Alert_Txt :='سيتم تحويل الرقم الفرعي إلى الرقم '||V_ALL_BUS_ID;
    --                       al_button := STR.DispAlert(Alert_Txt, 'ERROR');
    --                       IF al_button = alert_button1 THEN
    --                           :importers.BUS_ID_BRNCH := V_ALL_BUS_ID;
    --                       ELSIF al_button = alert_button2 THEN
    --                           RAISE Form_trigger_failure;
    --                       END IF;
    --                     END IF;
    --                  ELSIF LENGTH(:IMPORTERS.BUS_ID) = 10 THEN
    --                   V_USER_BUS_ID := SUBSTR(:IMPORTERS.BUS_ID_BRNCH, 1, 4);
    --                   IF TO_NUMBER(V_USER_BUS_ID) <> V_ID_MINS_COMM_CD THEN
    --                       al_button := STR.DispArbMsg(9, 130, 'ERROR');
    --                       RAISE Form_trigger_failure;
    --                   END IF;
    --               END IF;
    --         END IF;
    --    ELSE
    --         SET_ITEM_PROPERTY('BUS_ID_BRNCH',REQUIRED,PROPERTY_FALSE);
    --    END IF;
    --   END;
    --       CHK_IMPR_DUPL;
    --   IF :GLOBAL.FUNS_BUSID = 0 THEN
    --   DECLARE
    --     V_CNT NUMBER;
    --     RET   NUMBER;
    --     V_RET VARCHAR2(5);
    --   BEGIN
    --    IF :BUS_ID_TYPE_CD = 2 AND :IMPR_TYPE_CD!=12  THEN
    --     IF :COMM_RGSTRTN_TYPE = 2 THEN
    --        IF :BUS_ID IS NOT NULL AND :BUS_ID_BRNCH IS NOT NULL THEN
    --         SELECT COUNT(BUS_ID)INTO V_CNT    FROM COMM_IMPR_RGSTR
    --         WHERE  BUS_ID=:BUS_ID
    --          AND   BRNCH_BUS_ID=:BUS_ID_BRNCH;
    --            IF V_CNT >1 THEN
    --              RET := Str.DispArbMsg(9, 290,'ERROR');
    --            RAISE FORM_TRIGGER_FAILURE;
    --             ELSIF V_CNT = 1 THEN
    --             SELECT  ARBC_IMPR_NAME,ARBC_NAME_STD,BUS_ID_EXPRD_DT,
    --                      IMPR_TEL_NBR,IMPR_POB_NBR,IMPR_ZIP_CD,IMPR_FAX_NBR,IMPR_TELEX_NBR
    --               INTO   :ARBC_IMPR_NAME,:IMPR_NAME_STD,:BUS_ID_EXPRD_DT,:IMPR_TEL_NBR
    --                      ,:IMPR_POB_NBR,:IMPR_ZIP_CD,:IMPR_FAX_NBR,:IMPR_TELEX_NBR
    --                FROM  COMM_IMPR_RGSTR
    --            WHERE  BUS_ID=:BUS_ID
    --             AND   BRNCH_BUS_ID=:BUS_ID_BRNCH;
    --              INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_EXPRD_DT' , FALSE);
    --              INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_POB_NBR' , FALSE);
    --             INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_ZIP_CD' , FALSE);
    --            INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_TEL_NBR' , FALSE);
    --            INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_FAX_NBR' , FALSE);
    --            INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_TELEX_NBR' , FALSE);
    --            INTRFACE.Make_Field_Entrable('IMPORTERS.ARBC_IMPR_NAME' , FALSE);
    --           ELSE
    --                 V_RET := LIB_USR.GNRL.GET_CUSTOMS_SETTING('COMM_TABLE_UNCHECK',9);
    --                  IF NVL(V_RET,0) = 0 THEN
    --                     ret := Str.DispArbMsg(9, 190,'ERROR');
    --                     RAISE FORM_TRIGGER_FAILURE;
    --                ELSE
    --                 INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_EXPRD_DT' , TRUE);
    --                       INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_POB_NBR' , TRUE);
    --                  INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_ZIP_CD' , TRUE);
    --                 INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_TEL_NBR' , TRUE);
    --                 INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_FAX_NBR' , TRUE);
    --                 INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_TELEX_NBR' , TRUE);
    --                 INTRFACE.Make_Field_Entrable('IMPORTERS.ARBC_IMPR_NAME' , TRUE);
    --                  END IF;
    --          END IF;
    --     END IF;
    --    END IF;
    --   END IF;
    --   END;
    --   END IF;
    --   END IF;
    --   BEGIN
    --      IF     GET_RECORD_PROPERTY (:SYSTEM.cursor_record,:SYSTEM.cursor_block,status) IN ('NEW', 'INSERT') AND
    --           :importers.IMPR_TYPE_CD IN ( 1,3,5,6,19 ) AND :importers.bus_id_type_cd = 2
    --            AND :GLOBAL.ALLOW_MCI = 1
    --      THEN
    --         IF :importers.comm_rgstrtn_type = 1 AND :importers.bus_id IS NOT NULL THEN
    --            get_main_cr_data;
    --         ELSIF :importers.comm_rgstrtn_type = 2 AND :importers.bus_id_brnch IS NOT NULL THEN
    --            get_branch_cr_data;
    --         END IF;
    --      END IF;
    --   END;
    --   END;
    --   BEGIN
    --   chk_bus_id_brnch ;
    --   END;
    -- <<<
    PROCEDURE BUS_ID_BRNCH_VALIDATE_ITEM (p_rec       IN OUT NOCOPY T_RECORD,
                                p_ctx       IN T_CONTEXT,
                                p_cr_answer IN PLS_INTEGER DEFAULT c_yes)
    IS
        v_all_bus_id      VARCHAR2(10);
        v_id_mins_comm_cd VARCHAR2(4);
        v_user_bus_id     VARCHAR2(4);
        alert_txt         VARCHAR2(100);  -- SUGGESTION: size as in Forms
        v_cnt             NUMBER;
        v_ret             VARCHAR2(5);
    BEGIN
        IF NVL(p_rec.bus_id_brnch_entr, 'Y') = 'Y' THEN      -- GET_ITEM_PROPERTY(...,ENABLED) = 'TRUE'
            IF p_rec.bus_id_brnch = '0' THEN
                DISPLAY_ARABIC_ERROR(1, 220);
            END IF;
            IF p_rec.bus_id_type_cd = 2 AND p_rec.impr_type_cd != 12 THEN
                IF is_digit(p_rec.bus_id_brnch) = FALSE THEN
                    DISPLAY_ARABIC_ERROR(9, 270);
                END IF;
                IF NOT (LENGTH(p_rec.bus_id_brnch) = 6 OR LENGTH(p_rec.bus_id_brnch) = 10) THEN
                    DISPLAY_ARABIC_ERROR(9, 260);
                END IF;
                IF p_rec.brnh_city_cd IS NOT NULL THEN
                    SELECT mins_comm_cd
                      INTO p_rec.brnh_id_mins_comm_cd
                      FROM cities
                     WHERE city_cd = p_rec.brnh_city_cd
                       AND ctry_cd = p_rec.ctry_cd;
                    v_id_mins_comm_cd := LPAD(p_rec.brnh_id_mins_comm_cd, 4, '0');
                    IF LENGTH(p_rec.bus_id_brnch) = 6 THEN
                        v_all_bus_id := CONCAT(v_id_mins_comm_cd, p_rec.bus_id_brnch);
                        alert_txt := str_db.getarbmsg(9, 120);
                        IF alert_txt = '-1' THEN
                            alert_txt := 'خطأ فى رقم الرسالة  ' || 9 || '-' || 120 || 'إتصل بالمسانده الفنيه';
                            info(alert_txt);
                        ELSE
                            alert_txt := 'سيتم تحويل الرقم الفرعي إلى الرقم ' || v_all_bus_id;
                            info(alert_txt);
                            IF p_cr_answer = c_yes THEN
                                p_rec.bus_id_brnch := v_all_bus_id;
                            ELSIF p_cr_answer = c_no THEN
                                FORM_TRIGGER_FAILURE;
                            END IF;
                        END IF;
                    ELSIF LENGTH(p_rec.bus_id) = 10 THEN
                        v_user_bus_id := SUBSTR(p_rec.bus_id_brnch, 1, 4);
                        IF TO_NUMBER(v_user_bus_id) <> v_id_mins_comm_cd THEN
                            DISPLAY_ARABIC_ERROR(9, 130);
                        END IF;
                    END IF;
                END IF;
            ELSE
                NULL;  -- APEX (read_only_rules.md): ui('BUS_ID_BRNCH', 'REQUIRED', FALSE);
            END IF;
            chk_impr_dupl(p_rec);
            IF GET_GLOBAL('FUNS_BUSID') = '0' THEN
                IF p_rec.bus_id_type_cd = 2 AND p_rec.impr_type_cd != 12 THEN
                    IF p_rec.comm_rgstrtn_type = 2 THEN
                        IF p_rec.bus_id IS NOT NULL AND p_rec.bus_id_brnch IS NOT NULL THEN
                            SELECT COUNT(bus_id) INTO v_cnt
                              FROM comm_impr_rgstr
                             WHERE bus_id       = p_rec.bus_id
                               AND brnch_bus_id = p_rec.bus_id_brnch;
                            IF v_cnt > 1 THEN
                                DISPLAY_ARABIC_ERROR(9, 290);
                            ELSIF v_cnt = 1 THEN
                                SELECT arbc_impr_name, arbc_name_std, bus_id_exprd_dt, impr_tel_nbr,
                                       impr_pob_nbr, impr_zip_cd, impr_fax_nbr, impr_telex_nbr
                                  INTO p_rec.arbc_impr_name, p_rec.impr_name_std, p_rec.bus_id_exprd_dt,
                                       p_rec.impr_tel_nbr, p_rec.impr_pob_nbr, p_rec.impr_zip_cd,
                                       p_rec.impr_fax_nbr, p_rec.impr_telex_nbr
                                  FROM comm_impr_rgstr
                                 WHERE bus_id       = p_rec.bus_id
                                   AND brnch_bus_id = p_rec.bus_id_brnch;
                                NULL;  -- APEX (read_only_rules.md): cr_fields_entrable(FALSE, FALSE);
                            ELSE
                                v_ret := lib_usr.gnrl.get_customs_setting('COMM_TABLE_UNCHECK', 9);
                                IF NVL(v_ret, 0) = 0 THEN
                                    DISPLAY_ARABIC_ERROR(9, 190);
                                ELSE
                                    NULL;  -- APEX (read_only_rules.md): cr_fields_entrable(TRUE, FALSE);
                                END IF;
                            END IF;
                        END IF;
                    END IF;
                END IF;
            END IF;
        END IF;

        IF p_rec.rec_status IN ('NEW', 'INSERT')
           AND p_rec.impr_type_cd IN (1, 3, 5, 6, 19) AND p_rec.bus_id_type_cd = 2
           AND GET_GLOBAL('ALLOW_MCI') = '1' THEN
            IF p_rec.comm_rgstrtn_type = 1 AND p_rec.bus_id IS NOT NULL THEN
                get_main_cr_data(p_rec);
            ELSIF p_rec.comm_rgstrtn_type = 2 AND p_rec.bus_id_brnch IS NOT NULL THEN
                get_branch_cr_data(p_rec);
            END IF;
        END IF;

        chk_bus_id_brnch(p_rec);
    END BUS_ID_BRNCH_VALIDATE_ITEM;

    -- Source: IMPORTERS.BUS_ID_BRNCH.POST-CHANGE
    PROCEDURE BUS_ID_BRNCH_POST_CHANGE
    IS
    BEGIN
        SET_GLOBAL('FLAGUPDATE', '1');
    END BUS_ID_BRNCH_POST_CHANGE;

    -- Source: IMPORTERS.BUS_ID_BRNCH.WHEN-NEW-ITEM-INSTANCE
    --@ORIG IMPORTERS.BUS_ID_BRNCH.WHEN-NEW-ITEM-INSTANCE
    -- >>> Original Forms code: IMPORTERS.BUS_ID_BRNCH.WHEN-NEW-ITEM-INSTANCE
    --   DECLARE
    --    RET NUMBER;
    --    V_MINS_COMM_CD NUMBER;
    --   BEGIN
    --    IF :IMPORTERS.BUS_ID_TYPE_CD = 2 AND :IMPORTERS.IMPR_TYPE_CD != 12  THEN
    --      IF :BUS_ID IS NULL OR :CITY_CODE_OF_ID IS NULL THEN
    --         SET_ITEM_PROPERTY('BUS_ID_BRNCH',REQUIRED,PROPERTY_FALSE);
    --       END IF;
    --   END IF;
    --   IF :CITY_CODE =100 THEN
    --       IF :BRNH_CITY_CD IS NOT NULL THEN
    --           BEGIN
    --               SELECT MINS_COMM_CD
    --               INTO   V_MINS_COMM_CD
    --               FROM      CITIES
    --               WHERE  CITY_CD = :IMPORTERS.BRNH_CITY_CD
    --               AND     CTRY_CD = 100;
    --           EXCEPTION
    --               WHEN OTHERS THEN
    --                   NULL;
    --           END;
    --       IF (:GLOBAL.MINS_COMM_CD IS NOT NULL OR V_MINS_COMM_CD IS NOT NULL )
    --          AND :BUS_ID_BRNCH IS NULL THEN
    --           STR.DISPALERT('الرمز التجاري للمدينة المحددة :  '||NVL(:GLOBAL.MINS_COMM_CD,V_MINS_COMM_CD) ,'INFORMATION');
    --           :GLOBAL.MINS_COMM_CD := NULL ;
    --       END IF;
    --       END IF;
    --   END IF;
    --   END;
    -- <<<
    PROCEDURE BUS_ID_BRNCH_NEW_ITEM_INSTANCE (p_rec IN T_RECORD)
    IS
        v_mins_comm_cd NUMBER;
    BEGIN
        IF p_rec.bus_id_type_cd = 2 AND p_rec.impr_type_cd != 12 THEN
            IF p_rec.bus_id IS NULL OR p_rec.city_code_of_id IS NULL THEN
                NULL;  -- APEX (read_only_rules.md): ui('BUS_ID_BRNCH', 'REQUIRED', FALSE);
            END IF;
        END IF;
        IF p_rec.city_code = 100 THEN       -- SUGGESTION: CITY_CODE (city) compared with 100 (country code?) - kept
            IF p_rec.brnh_city_cd IS NOT NULL THEN
                BEGIN
                    SELECT mins_comm_cd
                      INTO v_mins_comm_cd
                      FROM cities
                     WHERE city_cd = p_rec.brnh_city_cd
                       AND ctry_cd = 100;
                EXCEPTION
                    WHEN OTHERS THEN
                        NULL;
                END;
                IF (GET_GLOBAL('MINS_COMM_CD') IS NOT NULL OR v_mins_comm_cd IS NOT NULL)
                   AND p_rec.bus_id_brnch IS NULL THEN
                    info('الرمز التجاري للمدينة المحددة :  ' || NVL(GET_GLOBAL('MINS_COMM_CD'), v_mins_comm_cd));
                    SET_GLOBAL('MINS_COMM_CD', NULL);
                END IF;
            END IF;
        END IF;
    END BUS_ID_BRNCH_NEW_ITEM_INSTANCE;

    -- Source: IMPORTERS.CTRY_CD.WHEN-VALIDATE-ITEM
    --@ORIG IMPORTERS.CTRY_CD.WHEN-VALIDATE-ITEM
    -- >>> Original Forms code: IMPORTERS.CTRY_CD.WHEN-VALIDATE-ITEM
    --   DECLARE
    --       V_COUNT NUMBER;
    --       RET NUMBER;
    --       V_IMPR_NBR NUMBER;
    --   BEGIN
    --   IF :IMPR_TYPE_CD = 12 THEN
    --       SELECT COUNT(*)
    --       INTO     V_COUNT
    --       FROM     CTRY_GROUP_DETAILS
    --       WHERE  CTRY_CD = :CTRY_CD
    --       AND     CTRY_GRP_STAT = 1
    --       AND     CTRY_GRP_NBR = 1
    --       ;
    --       IF V_COUNT = 0 THEN
    --           STR.DISPALERT('لابد أن تكون دولة المستورد الخليجي تابعة لدول مجلس التعاون','ERROR');
    --           RAISE FORM_TRIGGER_FAILURE;
    --       END IF;
    --   END IF;
    --   END;
    --   IF :IMPR_TYPE_CD = 3 AND :BUS_ID_TYPE_CD = 2 THEN
    --       :CTRY_CD_OF_ID := 100;
    --   ELSE
    --       :CTRY_CD_OF_ID := :CTRY_CD;
    --   END IF;
    --   BEGIN
    --     IF (name_in('IMPORTERS.CTRY_CD') IS NOT NULL) THEN
    --       BEGIN
    --         CGFK$CHK_IMPORTERS_IMP_CTRY_FK(
    --           :IMPORTERS.CTRY_CTRY_STATUS
    --          ,:IMPORTERS.CRTY_ARBC_NAME
    --          ,:IMPORTERS.CTRY_CD         );
    --       EXCEPTION
    --         WHEN NO_DATA_FOUND THEN
    --           Des$Form_errors.PUSH('رمز الدولة غير صحيح - أعد ادخال البيانات', 'E', 'OFG', 0);
    --           Des$Form_errors.RAISE_FAILURE;
    --         WHEN OTHERS THEN
    --           CGTE$OTHER_EXCEPTIONS;
    --       END;
    --     END IF;
    --   END;
    -- <<<
    PROCEDURE CTRY_CD_WHEN_VALIDATE_ITEM (p_rec IN OUT NOCOPY T_RECORD)
    IS
        v_count NUMBER;
    BEGIN
        IF p_rec.impr_type_cd = 12 THEN
            SELECT COUNT(*)
              INTO v_count
              FROM ctry_group_details
             WHERE ctry_cd       = p_rec.ctry_cd
               AND ctry_grp_stat = 1
               AND ctry_grp_nbr  = 1;
            IF v_count = 0 THEN
                FORM_TRIGGER_FAILURE('لابد أن تكون دولة المستورد الخليجي تابعة لدول مجلس التعاون');
            END IF;
        END IF;
        IF p_rec.impr_type_cd = 3 AND p_rec.bus_id_type_cd = 2 THEN
            p_rec.ctry_cd_of_id := 100;
        ELSE
            p_rec.ctry_cd_of_id := p_rec.ctry_cd;
        END IF;
        -- CGFK$VALDIDATE_FK_OVF (CGFK$CHK_IMPORTERS_IMP_CTRY_FK: active countries only)
        IF p_rec.ctry_cd IS NOT NULL THEN
            BEGIN
                SELECT ctry.crty_arbc_name, ctry.ctry_status
                  INTO p_rec.crty_arbc_name, p_rec.ctry_ctry_status
                  FROM countries ctry
                 WHERE ctry.ctry_cd = p_rec.ctry_cd
                   AND ctry.ctry_status = 1;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    FORM_TRIGGER_FAILURE('رمز الدولة غير صحيح - أعد ادخال البيانات');
            END;
        END IF;
    END CTRY_CD_WHEN_VALIDATE_ITEM;

    -- Source: IMPORTERS.IMPR_EXPR_TYPE.POST-CHANGE
    PROCEDURE IMPR_EXPR_TYPE_POST_CHANGE
    IS
    BEGIN
        SET_GLOBAL('FLAGUPDATE', '1');
    END IMPR_EXPR_TYPE_POST_CHANGE;

    -- Source: IMPORTERS.ARBC_IMPR_NAME.WHEN-VALIDATE-ITEM
    --@ORIG IMPORTERS.ARBC_IMPR_NAME.WHEN-VALIDATE-ITEM
    -- >>> Original Forms code: IMPORTERS.ARBC_IMPR_NAME.WHEN-VALIDATE-ITEM
    --   BEGIN
    --   :ARBC_IMPR_NAME := STR_db.RemoveRepeat(:ARBC_IMPR_NAME);
    --   :IMPR_NAME_STD    := STR.STRFORMAT(:ARBC_IMPR_NAME);
    --   END;
    -- <<<
    PROCEDURE ARBC_IMPR_NAME_VALIDATE_ITEM (p_rec IN OUT NOCOPY T_RECORD)
    IS
    BEGIN
        p_rec.arbc_impr_name := str_db.removerepeat(p_rec.arbc_impr_name);
        p_rec.impr_name_std  := str_db.strformat(p_rec.arbc_impr_name, 0);  -- STR.STRFORMAT = STR_DB(x, 0)
    END ARBC_IMPR_NAME_VALIDATE_ITEM;

    -- Source: IMPORTERS.ARBC_IMPR_NAME.KEY-NEXT-ITEM
    -- Net effect in Forms: temporary dummy values that are all reset before GO_ITEM -> the
    -- record is unchanged; only the focus moves to ENG_IMPR_NAME. Kept for traceability.
    --@ORIG IMPORTERS.ARBC_IMPR_NAME.KEY-NEXT-ITEM
    -- >>> Original Forms code: IMPORTERS.ARBC_IMPR_NAME.KEY-NEXT-ITEM
    --   DECLARE
    --       CITY_DUMMY_VALUE     NUMBER := 1;
    --       CTRY_DUMMY_VALUE     NUMBER := 1;
    --         TEL_DUMMY_VALUE    NUMBER := 1;
    --   BEGIN
    --       IF :ADD_CTRY_CD IS NULL THEN
    --           :ADD_CTRY_CD := :CTRY_CD;  -- only bcz CITY_CODE is Mandatory
    --       ELSE
    --           CTRY_DUMMY_VALUE := NULL;
    --       END IF;
    --       IF :CITY_CODE IS NULL THEN
    --           SELECT MIN(CITY_CD)
    --           INTO     :CITY_CODE
    --           FROM     CITIES
    --           WHERE CTRY_CD = :CTRY_CD
    --           AND    CITY_STATUS = 1
    --           ;
    --       ELSE
    --           CITY_DUMMY_VALUE  := NULL;
    --       END IF;
    --       IF :IMPR_TEL_NBR IS NULL THEN
    --   :IMPR_TEL_NBR := 1;
    --       ELSE
    --           TEL_DUMMY_VALUE  := NULL;
    --       END IF;
    --       IF CITY_DUMMY_VALUE IS NOT NULL THEN
    --           :CITY_CODE      := NULL;
    --           :CITY_NAME     := NULL;
    --       END IF;
    --       IF TEL_DUMMY_VALUE IS NOT NULL THEN
    --           :IMPR_TEL_NBR      := NULL;
    --       END IF;
    --       IF CTRY_DUMMY_VALUE IS NOT NULL THEN
    --           :ADD_CTRY_CD       := NULL;
    --           :ADD_CRTY_ARBC_NAME := NULL;
    --       END IF;
    --   BEGIN
    --       go_Item('IMPORTERS.ENG_IMPR_NAME');
    --   END;
    --   END;
    -- <<<
    PROCEDURE ARBC_IMPR_NAME_KEY_NEXT_ITEM (p_rec IN OUT NOCOPY T_RECORD)
    IS
        city_dummy_value NUMBER := 1;
        ctry_dummy_value NUMBER := 1;
        tel_dummy_value  NUMBER := 1;
    BEGIN
        IF p_rec.add_ctry_cd IS NULL THEN
            p_rec.add_ctry_cd := p_rec.ctry_cd;
        ELSE
            ctry_dummy_value := NULL;
        END IF;
        IF p_rec.city_code IS NULL THEN
            SELECT MIN(city_cd)
              INTO p_rec.city_code
              FROM cities
             WHERE ctry_cd = p_rec.ctry_cd
               AND city_status = 1;
        ELSE
            city_dummy_value := NULL;
        END IF;
        IF p_rec.impr_tel_nbr IS NULL THEN
            p_rec.impr_tel_nbr := 1;
        ELSE
            tel_dummy_value := NULL;
        END IF;
        IF city_dummy_value IS NOT NULL THEN
            p_rec.city_code := NULL;
            p_rec.city_name := NULL;
        END IF;
        IF tel_dummy_value IS NOT NULL THEN
            p_rec.impr_tel_nbr := NULL;
        END IF;
        IF ctry_dummy_value IS NOT NULL THEN
            p_rec.add_ctry_cd        := NULL;
            p_rec.add_crty_arbc_name := NULL;
        END IF;
        NULL;  -- APEX (read_only_rules.md): ui_focus('ENG_IMPR_NAME');
    END ARBC_IMPR_NAME_KEY_NEXT_ITEM;

    -- Source: IMPORTERS.ENG_IMPR_NAME.WHEN-VALIDATE-ITEM
    --@ORIG IMPORTERS.ENG_IMPR_NAME.WHEN-VALIDATE-ITEM
    -- >>> Original Forms code: IMPORTERS.ENG_IMPR_NAME.WHEN-VALIDATE-ITEM
    --   DECLARE
    --       ENG_IMPR_NAME_length   NUMBER;
    --       V         VARCHAR2(1);
    --   BEGIN
    --   IF :ENG_IMPR_NAME IS NOT NULL THEN
    --    :eng_IMPR_NAME := STR_db.RemoveRepeat(:eng_IMPR_NAME);
    --       ENG_IMPR_NAME_length := LENGTH(:ENG_IMPR_NAME);
    --           FOR I IN  1 .. ENG_IMPR_NAME_length LOOP
    --             V := SUBSTR(:ENG_IMPR_NAME,I,1);
    --                IF ( V BETWEEN '0' AND '9' ) OR ( V BETWEEN 'A' AND 'Z' ) OR ( V BETWEEN 'a' AND 'z' )
    --                     OR ( V = ' ' ) THEN
    --                   NULL;
    --                ELSE
    --                   STR.DISPALERT ('فضلا .. يجب إدخال اسم المستورد باللغة الانجليزية','information');
    --                   RAISE FORM_TRIGGER_FAILURE;
    --                    END IF;
    --         END LOOP;
    --   ELSE
    --   NULL;
    --   END IF;
    --   END;
    -- <<<
    PROCEDURE ENG_IMPR_NAME_VALIDATE_ITEM (p_rec IN OUT NOCOPY T_RECORD)
    IS
        eng_impr_name_length NUMBER;
        v                    VARCHAR2(1);
    BEGIN
        IF p_rec.eng_impr_name IS NOT NULL THEN
            p_rec.eng_impr_name := str_db.removerepeat(p_rec.eng_impr_name);
            eng_impr_name_length := LENGTH(p_rec.eng_impr_name);
            FOR i IN 1 .. eng_impr_name_length LOOP
                v := SUBSTR(p_rec.eng_impr_name, i, 1);
                IF (v BETWEEN '0' AND '9') OR (v BETWEEN 'A' AND 'Z') OR (v BETWEEN 'a' AND 'z')
                   OR (v = ' ') THEN
                    NULL;
                ELSE
                    FORM_TRIGGER_FAILURE('فضلا .. يجب إدخال اسم المستورد باللغة الانجليزية');
                END IF;
            END LOOP;
        END IF;
    END ENG_IMPR_NAME_VALIDATE_ITEM;

    -- Source: IMPORTERS.BUS_ID_ISSUE_DT.WHEN-VALIDATE-ITEM
    --@ORIG IMPORTERS.BUS_ID_ISSUE_DT.WHEN-VALIDATE-ITEM
    -- >>> Original Forms code: IMPORTERS.BUS_ID_ISSUE_DT.WHEN-VALIDATE-ITEM
    --   DECLARE
    --       HDATE DATE;
    --   BEGIN
    --       IF :System.TRIGGER_ITEM = :System.CURSOR_ITEM THEN
    --           IF :System.Cursor_Value IS NOT NULL THEN
    --               HDATE := TO_DATE(:System.Cursor_Value);
    --               IF NOT HIJDATE.VALID_HIJ_DATE(HDATE) THEN
    --                   RAISE FORM_TRIGGER_FAILURE;
    --               END IF;
    --           END IF;
    --       END IF;
    --   END;
    -- <<<
    PROCEDURE BUS_ID_ISSUE_DT_VALIDATE_ITEM (p_rec IN T_RECORD, p_from_item IN BOOLEAN DEFAULT TRUE)
    IS
    BEGIN
        IF p_from_item THEN
            IF p_rec.bus_id_issue_dt IS NOT NULL THEN
                IF NOT valid_hij_date(p_rec.bus_id_issue_dt) THEN
                    FORM_TRIGGER_FAILURE;
                END IF;
            END IF;
        END IF;
    END BUS_ID_ISSUE_DT_VALIDATE_ITEM;

    -- Source: IMPORTERS.IMPR_NBR_PARENT.WHEN-VALIDATE-ITEM (9-160 is shown, no failure)
    --@ORIG IMPORTERS.IMPR_NBR_PARENT.WHEN-VALIDATE-ITEM
    -- >>> Original Forms code: IMPORTERS.IMPR_NBR_PARENT.WHEN-VALIDATE-ITEM
    --   DECLARE
    --       ret NUMBER;
    --       CURSOR C_P_NAME IS
    --               SELECT ARBC_IMPR_NAME
    --           FROM IMPORTERS
    --           WHERE IMPR_NBR = :IMPR_NBR_PARENT;
    --   BEGIN
    --   IF :IMPR_NBR_PARENT IS NOT NULL THEN
    --           OPEN C_P_NAME;
    --         FETCH C_P_NAME INTO :IMPR_NAME_PARENT;
    --            IF C_P_NAME%NOTFOUND THEN
    --           ret := Str.DispArbMsg(9, 160,'ERROR');
    --         END IF;
    --         CLOSE C_P_NAME;
    --   END IF;
    --   END;
    -- <<<
    PROCEDURE IMPR_NBR_PARENT_VALIDATE_ITEM (p_rec IN OUT NOCOPY T_RECORD)
    IS
        CURSOR c_p_name IS
            SELECT arbc_impr_name
              FROM importers
             WHERE impr_nbr = p_rec.impr_nbr_parent;
    BEGIN
        IF p_rec.impr_nbr_parent IS NOT NULL THEN
            OPEN c_p_name;
            FETCH c_p_name INTO p_rec.impr_name_parent;
            IF c_p_name%NOTFOUND THEN
                DISPLAY_ARABIC_INFO(9, 160);
            END IF;
            CLOSE c_p_name;
        END IF;
    END IMPR_NBR_PARENT_VALIDATE_ITEM;

    -- Source: IMPORTERS.ADD_CTRY_CD.WHEN-VALIDATE-ITEM
    --@ORIG IMPORTERS.ADD_CTRY_CD.WHEN-VALIDATE-ITEM
    -- >>> Original Forms code: IMPORTERS.ADD_CTRY_CD.WHEN-VALIDATE-ITEM
    --   DECLARE
    --    RET NUMBER;
    --   BEGIN
    --    SELECT CRTY_ARBC_NAME INTO :ADD_CRTY_ARBC_NAME
    --    FROM   COUNTRIES
    --    WHERE  CTRY_CD=:ADD_CTRY_CD;
    --   EXCEPTION
    --   WHEN NO_DATA_FOUND THEN
    --     ret := Str.DispArbMsg(18, 15,'ERROR');
    --     RAISE FORM_TRIGGER_FAILURE;
    --   END;
    --   BEGIN
    --     IF (name_in('IMPORTERS.ADD_CTRY_CD') IS NOT NULL AND name_in('IMPORTERS.CITY_CODE') IS NOT NULL) THEN
    --       BEGIN
    --         CGFK$CHK_IMPORTERS_IMP_ADD_CIT(
    --           :IMPORTERS.ADD_CRTY_ARBC_NAME
    --          ,:IMPORTERS.CITY_NAME
    --          ,:IMPORTERS.L_CT_CITY_STATUS
    --          ,:IMPORTERS.CITY_CODE
    --          ,:IMPORTERS.ADD_CTRY_CD       );
    --       EXCEPTION
    --         WHEN NO_DATA_FOUND THEN
    --           Des$Form_errors.PUSH('خطأ في رمز مدينة عنوان المستورد', 'W', 'OFG', 0);
    --         WHEN OTHERS THEN
    --           CGTE$OTHER_EXCEPTIONS;
    --       END;
    --     END IF;
    --   END;
    -- <<<
    PROCEDURE ADD_CTRY_CD_WHEN_VALIDATE_ITEM (p_rec IN OUT NOCOPY T_RECORD)
    IS
    BEGIN
        BEGIN
            SELECT crty_arbc_name INTO p_rec.add_crty_arbc_name
              FROM countries
             WHERE ctry_cd = p_rec.add_ctry_cd;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                DISPLAY_ARABIC_ERROR(18, 15);
        END;
        -- CGFK$VALDIDATE_FK_OVF (CGFK$CHK_IMPORTERS_IMP_ADD_CIT) - warning only
        IF p_rec.add_ctry_cd IS NOT NULL AND p_rec.city_code IS NOT NULL THEN
            BEGIN
                SELECT add_city.city_status, add_city.city_arb_name, l_ctry.crty_arbc_name
                  INTO p_rec.l_ct_city_status, p_rec.city_name, p_rec.add_crty_arbc_name
                  FROM cities add_city, countries l_ctry
                 WHERE add_city.ctry_cd     = p_rec.add_ctry_cd
                   AND add_city.city_cd     = p_rec.city_code
                   AND add_city.city_status = 1
                   AND l_ctry.ctry_cd       = add_city.ctry_cd
                   AND ROWNUM = 1;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    info('خطأ في رمز مدينة عنوان المستورد');
            END;
        END IF;
    END ADD_CTRY_CD_WHEN_VALIDATE_ITEM;

    -- Source: IMPORTERS.CITY_CODE.WHEN-VALIDATE-ITEM
    --@ORIG IMPORTERS.CITY_CODE.WHEN-VALIDATE-ITEM
    -- >>> Original Forms code: IMPORTERS.CITY_CODE.WHEN-VALIDATE-ITEM
    --   DECLARE
    --    RET NUMBER;
    --   BEGIN
    --   IF :CITY_CODE  IS NULL THEN
    --   STR.DISPALERT('يجب إدخال المدينة','INFORMATION');
    --     RAISE FORM_TRIGGER_FAILURE;
    --   END IF;
    --    SELECT CITY_ARB_NAME INTO :CITY_NAME
    --    FROM   CITIES
    --    WHERE  CTRY_CD=:ADD_CTRY_CD
    --     AND   CITY_CD=:CITY_CODE;
    --   EXCEPTION
    --   WHEN NO_DATA_FOUND THEN
    --     ret := Str.DispArbMsg(18, 282,'ERROR');
    --     RAISE FORM_TRIGGER_FAILURE;
    --   END;
    --   BEGIN
    --     IF (name_in('IMPORTERS.ADD_CTRY_CD') IS NOT NULL AND name_in('IMPORTERS.CITY_CODE') IS NOT NULL) THEN
    --       BEGIN
    --         CGFK$CHK_IMPORTERS_IMP_ADD_CIT(
    --           :IMPORTERS.ADD_CRTY_ARBC_NAME
    --          ,:IMPORTERS.CITY_NAME
    --          ,:IMPORTERS.L_CT_CITY_STATUS
    --          ,:IMPORTERS.CITY_CODE
    --          ,:IMPORTERS.ADD_CTRY_CD       );
    --       EXCEPTION
    --         WHEN NO_DATA_FOUND THEN
    --           Des$Form_errors.PUSH('خطأ في رمز مدينة عنوان المستورد', 'W', 'OFG', 0);
    --         WHEN OTHERS THEN
    --           CGTE$OTHER_EXCEPTIONS;
    --       END;
    --     END IF;
    --   END;
    -- <<<
    PROCEDURE CITY_CODE_WHEN_VALIDATE_ITEM (p_rec IN OUT NOCOPY T_RECORD)
    IS
    BEGIN
        BEGIN
            IF p_rec.city_code IS NULL THEN
                FORM_TRIGGER_FAILURE('يجب إدخال المدينة');
            END IF;
            SELECT city_arb_name INTO p_rec.city_name
              FROM cities
             WHERE ctry_cd = p_rec.add_ctry_cd
               AND city_cd = p_rec.city_code;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                DISPLAY_ARABIC_ERROR(18, 282);
        END;
        -- CGFK$VALDIDATE_FK_OVF (CGFK$CHK_IMPORTERS_IMP_ADD_CIT) - warning only
        IF p_rec.add_ctry_cd IS NOT NULL AND p_rec.city_code IS NOT NULL THEN
            BEGIN
                SELECT add_city.city_status, add_city.city_arb_name, l_ctry.crty_arbc_name
                  INTO p_rec.l_ct_city_status, p_rec.city_name, p_rec.add_crty_arbc_name
                  FROM cities add_city, countries l_ctry
                 WHERE add_city.ctry_cd     = p_rec.add_ctry_cd
                   AND add_city.city_cd     = p_rec.city_code
                   AND add_city.city_status = 1
                   AND l_ctry.ctry_cd       = add_city.ctry_cd
                   AND ROWNUM = 1;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    info('خطأ في رمز مدينة عنوان المستورد');
            END;
        END IF;
    END CITY_CODE_WHEN_VALIDATE_ITEM;

    -- Source: IMPORTERS.IMPR_TEL_NBR.WHEN-VALIDATE-ITEM
    -- (TO_NUMBER of a non-numeric value raises ORA-01722 in Forms too - kept)
    --@ORIG IMPORTERS.IMPR_TEL_NBR.WHEN-VALIDATE-ITEM
    -- >>> Original Forms code: IMPORTERS.IMPR_TEL_NBR.WHEN-VALIDATE-ITEM
    --   BEGIN
    --   IF :IMPR_TEL_NBR IS NULL THEN
    --     str.DISPALERT('يجب إدخال الهاتف','INFORMATION');
    --      RAISE FORM_TRIGGER_FAILURE ;
    --   END IF;
    --   IF LENGTH(:IMPR_TEL_NBR) < 10 OR LENGTH(:IMPR_TEL_NBR) > 10 THEN
    --      str.DISPALERT('رقم الهاتف يجب أن يتكون من 10 أرقام','INFORMATION');
    --   RAISE FORM_TRIGGER_FAILURE ;
    --   END IF;
    --   IF TO_NUMBER(:IMPR_TEL_NBR) = 0 THEN
    --    str.DISPALERT('يجب أن يكون رقم الهاتف المدخل أرقام','INFORMATION');
    --   RAISE FORM_TRIGGER_FAILURE ;
    --   END IF;
    --   END;
    -- <<<
    PROCEDURE IMPR_TEL_NBR_VALIDATE_ITEM (p_rec IN T_RECORD)
    IS
    BEGIN
        IF p_rec.impr_tel_nbr IS NULL THEN
            FORM_TRIGGER_FAILURE('يجب إدخال الهاتف');
        END IF;
        IF LENGTH(p_rec.impr_tel_nbr) < 10 OR LENGTH(p_rec.impr_tel_nbr) > 10 THEN
            FORM_TRIGGER_FAILURE('رقم الهاتف يجب أن يتكون من 10 أرقام');
        END IF;
        IF TO_NUMBER(p_rec.impr_tel_nbr) = 0 THEN
            FORM_TRIGGER_FAILURE('يجب أن يكون رقم الهاتف المدخل أرقام');
        END IF;
    END IMPR_TEL_NBR_VALIDATE_ITEM;

    -- Shared body of B_EMAIL / EMAIL WHEN-VALIDATE-ITEM (identical text in both triggers)
    PROCEDURE check_email (p_email IN VARCHAR2, p_from_item IN BOOLEAN)
    IS
        at_pos NUMBER;
    BEGIN
        IF p_from_item THEN
            IF (LENGTH(p_email) > 0) THEN
                at_pos := INSTR(p_email, '@');
                IF (at_pos <= 0 OR at_pos = 1) THEN
                    FORM_TRIGGER_FAILURE('خطأ فى صيغة البريد الالكتروني');
                END IF;
            END IF;
        END IF;
    END check_email;

    -- Source: IMPORTERS.B_EMAIL.WHEN-VALIDATE-ITEM
    --@ORIG IMPORTERS.B_EMAIL.WHEN-VALIDATE-ITEM
    -- >>> Original Forms code: IMPORTERS.B_EMAIL.WHEN-VALIDATE-ITEM
    --   DECLARE
    --       EMAIL VARCHAR2(200);
    --       At_Pos number;
    --       Dot_Pos number;
    --       EMAIL_LENGTH  number;
    --       RET NUMBER;
    --   Begin
    --       IF :System.TRIGGER_ITEM = :System.CURSOR_ITEM THEN
    --           EMAIL := :System.Cursor_Value;
    --           EMAIL_LENGTH := LENGTH(EMAIL);
    --           IF (EMAIL_LENGTH > 0)     THEN
    --               At_Pos := INSTR(EMAIL, '@');
    --               Dot_Pos := INSTR(EMAIL, '.');
    --                   IF (At_Pos  <= 0 OR At_Pos = 1 ) THEN
    --                   RET := STR.DISPALERT('خطأ فى صيغة البريد الالكتروني','INFORMATION');
    --                   RAISE FORM_TRIGGER_FAILURE;
    --               END IF;
    --           END IF;
    --       END IF;
    --   End;
    -- <<<
    PROCEDURE B_EMAIL_WHEN_VALIDATE_ITEM (p_rec IN T_RECORD, p_from_item IN BOOLEAN DEFAULT TRUE)
    IS
    BEGIN
        check_email(p_rec.b_email, p_from_item);
    END B_EMAIL_WHEN_VALIDATE_ITEM;

    -- Source: IMPORTERS.EMAIL.WHEN-VALIDATE-ITEM (EMAIL is hidden; only filled by POST-QUERY)
    PROCEDURE EMAIL_WHEN_VALIDATE_ITEM (p_rec IN T_RECORD, p_from_item IN BOOLEAN DEFAULT TRUE)
    IS
    BEGIN
        check_email(p_rec.email, p_from_item);
    END EMAIL_WHEN_VALIDATE_ITEM;

    -- Source: IMPORTERS.B_EMAIL.POST-CHANGE (same body: B_MOBILE_NO, B_ID_NBR)
    -- Business rule: changing e-mail / mobile / ID moves the importer row to the current port.
    --@ORIG IMPORTERS.B_EMAIL.POST-CHANGE
    -- >>> Original Forms code: IMPORTERS.B_EMAIL.POST-CHANGE
    --   BEGIN
    --   :GLOBAL.FLAGUPDATE := 1;
    --   :PORT_CD:=:PARAMETER.P_CURR_PORT_CD;
    --   END;
    -- <<<
    PROCEDURE B_EMAIL_POST_CHANGE (p_rec IN OUT NOCOPY T_RECORD, p_ctx IN T_CONTEXT)
    IS
    BEGIN
        SET_GLOBAL('FLAGUPDATE', '1');
        p_rec.port_cd := p_ctx.curr_port_cd;
    END B_EMAIL_POST_CHANGE;

    -- Source: IMPORTERS.B_MOBILE_NO.WHEN-VALIDATE-ITEM
    --@ORIG IMPORTERS.B_MOBILE_NO.WHEN-VALIDATE-ITEM
    -- >>> Original Forms code: IMPORTERS.B_MOBILE_NO.WHEN-VALIDATE-ITEM
    --   DECLARE
    --   MOBILE_NO_length  NUMBER;
    --   V    VARCHAR2(1);
    --   BEGIN
    --      IF :PARAMETER.P_CURR_PORT_CD = 99  THEN
    --          IF :GLOBAL.OLD_PORT_CD <> 99 AND :IMPR_NBR IS NOT NULL THEN
    --                  STR.DISPALERT ('لا يمكن تعديل رقم الجوال, الرجاء استخدام الوظيفة الخاصة بتعديل رقم الجوال','ERROR');
    --                   RAISE FORM_TRIGGER_FAILURE ;
    --          END IF;
    --      END IF;
    --   BEGIN
    --   MOBILE_NO_length := LENGTH (:B_MOBILE_NO);
    --           FOR I IN  1 .. MOBILE_NO_length LOOP
    --             V := SUBSTR(:B_MOBILE_NO,I,1);
    --                IF ( V BETWEEN '0' AND '9' )
    --                     THEN
    --                   NULL;
    --                ELSE
    --                   STR.DISPALERT ('يجب أن يكون رقم الجوال المدخل أرقام','information');
    --                   RAISE FORM_TRIGGER_FAILURE;
    --                    END IF;
    --         END LOOP;
    --   END ;
    --       IF :B_MOBILE_NO IS NOT NULL AND (LENGTH(:B_MOBILE_NO) != 9 OR SUBSTR(:B_MOBILE_NO,1,1) != 5 ) THEN
    --           STR.DISPALERT('رقم الجوال المدخل غير صحيح .. الرجاء اعادة الادخال ','ERROR');
    --           RAISE FORM_TRIGGER_FAILURE;
    --       END IF;
    --   END;
    -- <<<
    PROCEDURE B_MOBILE_NO_WHEN_VALIDATE_ITEM (p_rec IN T_RECORD, p_ctx IN T_CONTEXT)
    IS
        mobile_no_length NUMBER;
        v                VARCHAR2(1);
    BEGIN
        IF p_ctx.curr_port_cd = 99 THEN
            IF GET_GLOBAL('OLD_PORT_CD') <> 99 AND p_rec.impr_nbr IS NOT NULL THEN
                FORM_TRIGGER_FAILURE('لا يمكن تعديل رقم الجوال, الرجاء استخدام الوظيفة الخاصة بتعديل رقم الجوال');
            END IF;
        END IF;
        mobile_no_length := LENGTH(p_rec.b_mobile_no);
        FOR i IN 1 .. mobile_no_length LOOP
            v := SUBSTR(p_rec.b_mobile_no, i, 1);
            IF (v BETWEEN '0' AND '9') THEN
                NULL;
            ELSE
                FORM_TRIGGER_FAILURE('يجب أن يكون رقم الجوال المدخل أرقام');
            END IF;
        END LOOP;
        IF p_rec.b_mobile_no IS NOT NULL
           AND (LENGTH(p_rec.b_mobile_no) != 9 OR SUBSTR(p_rec.b_mobile_no, 1, 1) != 5) THEN
            FORM_TRIGGER_FAILURE('رقم الجوال المدخل غير صحيح .. الرجاء اعادة الادخال ');
        END IF;
    END B_MOBILE_NO_WHEN_VALIDATE_ITEM;

    -- Source: IMPORTERS.B_MOBILE_NO.POST-CHANGE
    PROCEDURE B_MOBILE_NO_POST_CHANGE (p_rec IN OUT NOCOPY T_RECORD, p_ctx IN T_CONTEXT)
    IS
    BEGIN
        B_EMAIL_POST_CHANGE(p_rec, p_ctx);
    END B_MOBILE_NO_POST_CHANGE;

    -- Source: IMPORTERS.BANK_IBAN.WHEN-VALIDATE-ITEM
    --@ORIG IMPORTERS.BANK_IBAN.WHEN-VALIDATE-ITEM
    -- >>> Original Forms code: IMPORTERS.BANK_IBAN.WHEN-VALIDATE-ITEM
    --   BEGIN
    --       :BANK_IBAN := UPPER(:BANK_IBAN);
    --       IF :BANK_IBAN ='SA' THEN
    --              :BANK_IBAN :=NULL;
    --       ELSIF :BANK_IBAN IS NOT NULL AND SUBSTR(:BANK_IBAN ,1,2)!='SA' THEN
    --              :BANK_IBAN := 'SA'||:BANK_IBAN ;
    --       END IF;
    --       IF :BANK_IBAN IS NOT NULL AND LENGTH(:BANK_IBAN ) != 24 THEN
    --           STR.DISPALERT(' رقم الآيبان المدخل غير صحيح..الرجاء إعادة الإدخال ','ERROR');
    --           RAISE FORM_TRIGGER_FAILURE;
    --       END IF;
    --   END;
    -- <<<
    PROCEDURE BANK_IBAN_WHEN_VALIDATE_ITEM (p_rec IN OUT NOCOPY T_RECORD)
    IS
    BEGIN
        p_rec.bank_iban := UPPER(p_rec.bank_iban);
        IF p_rec.bank_iban = 'SA' THEN
            p_rec.bank_iban := NULL;
        ELSIF p_rec.bank_iban IS NOT NULL AND SUBSTR(p_rec.bank_iban, 1, 2) != 'SA' THEN
            p_rec.bank_iban := 'SA' || p_rec.bank_iban;
        END IF;
        IF p_rec.bank_iban IS NOT NULL AND LENGTH(p_rec.bank_iban) != 24 THEN
            FORM_TRIGGER_FAILURE(' رقم الآيبان المدخل غير صحيح..الرجاء إعادة الإدخال ');
        END IF;
    END BANK_IBAN_WHEN_VALIDATE_ITEM;

    -- Source: IMPORTERS.BANK_IBAN.WHEN-NEW-ITEM-INSTANCE
    PROCEDURE BANK_IBAN_NEW_ITEM_INSTANCE (p_rec IN OUT NOCOPY T_RECORD)
    IS
    BEGIN
        IF p_rec.bank_iban IS NULL THEN
            p_rec.bank_iban := 'SA';
        END IF;
    END BANK_IBAN_NEW_ITEM_INSTANCE;

    -- Source: IMPORTERS.B_ID_NBR.WHEN-VALIDATE-ITEM
    --@ORIG IMPORTERS.B_ID_NBR.WHEN-VALIDATE-ITEM
    -- >>> Original Forms code: IMPORTERS.B_ID_NBR.WHEN-VALIDATE-ITEM
    --   DECLARE
    --     X NUMBER;
    --   BEGIN
    --       IF :B_ID_NBR IS NOT NULL THEN
    --           X:=TO_NUMBER(:B_ID_NBR);
    --       END IF;
    --   EXCEPTION WHEN OTHERS THEN
    --       STR.DISPALERT('يجب إدخال رقم الهوية بشكل صحيح','ERROR');
    --       RAISE FORM_TRIGGER_FAILURE;
    --   END;
    --       IF :B_ID_NBR IS NOT NULL THEN
    --           IF  NOT CHECK_IDNO(:B_ID_NBR)THEN
    --               STR.DISPALERT('رقم الهوية المدخل غير صحيح.. يجب إدخال رقم هوية صحيح','ERROR');
    --               RAISE FORM_TRIGGER_FAILURE;
    --           END IF;
    --       END IF;
    -- <<<
    PROCEDURE B_ID_NBR_WHEN_VALIDATE_ITEM (p_rec IN T_RECORD)
    IS
        x NUMBER;
    BEGIN
        BEGIN
            IF p_rec.b_id_nbr IS NOT NULL THEN
                x := TO_NUMBER(p_rec.b_id_nbr);
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                FORM_TRIGGER_FAILURE('يجب إدخال رقم الهوية بشكل صحيح');
        END;
        IF p_rec.b_id_nbr IS NOT NULL THEN
            IF NOT check_idno(p_rec.b_id_nbr) THEN
                FORM_TRIGGER_FAILURE('رقم الهوية المدخل غير صحيح.. يجب إدخال رقم هوية صحيح');
            END IF;
        END IF;
    END B_ID_NBR_WHEN_VALIDATE_ITEM;

    -- Source: IMPORTERS.B_ID_NBR.POST-CHANGE
    PROCEDURE B_ID_NBR_POST_CHANGE (p_rec IN OUT NOCOPY T_RECORD, p_ctx IN T_CONTEXT)
    IS
    BEGIN
        B_EMAIL_POST_CHANGE(p_rec, p_ctx);
    END B_ID_NBR_POST_CHANGE;

    -- Source: PU CHECK_IDNO (unchanged)
    --@ORIG PU CHECK_IDNO
    -- >>> Original Forms code: PU CHECK_IDNO
    --   FUNCTION CHECK_IDNO(ID_NO VARCHAR2) RETURN BOOLEAN IS
    --       RESULT     NUMBER:=0;
    --       SU         NUMBER:=0;
    --       CHR_RESULT     VARCHAR2(10);
    --   BEGIN
    --       FOR I IN 1..9 LOOP
    --           SU :=TO_NUMBER(SUBSTR(ID_NO,I,1));
    --               IF MOD(I,2)<>0 THEN
    --                   RESULT:=RESULT + MOD(SU * 2,10);
    --                   RESULT:=RESULT + TRUNC((SU * 2)/10);
    --               ELSE
    --                   RESULT:=RESULT + SU;
    --               END IF;
    --       END LOOP;
    --       CHR_RESULT:=RESULT;
    --       IF SUBSTR(ID_NO,10,1)=0 THEN
    --          IF SUBSTR(CHR_RESULT,LENGTH(CHR_RESULT),1)=0 THEN
    --              RETURN TRUE;
    --          END IF;
    --       ELSE
    --           IF TO_CHAR((10 - TO_NUMBER(SUBSTR(CHR_RESULT,LENGTH(CHR_RESULT),1))))=SUBSTR(ID_NO,10,1) THEN
    --          RETURN TRUE;
    --           END IF;
    --       END IF;
    --       RETURN FALSE;
    --   END;
    -- <<<
    FUNCTION check_idno (id_no IN VARCHAR2) RETURN BOOLEAN
    IS
        result     NUMBER := 0;
        su         NUMBER := 0;
        chr_result VARCHAR2(10);
    BEGIN
        FOR i IN 1 .. 9 LOOP
            su := TO_NUMBER(SUBSTR(id_no, i, 1));
            IF MOD(i, 2) <> 0 THEN
                result := result + MOD(su * 2, 10);
                result := result + TRUNC((su * 2) / 10);
            ELSE
                result := result + su;
            END IF;
        END LOOP;
        chr_result := result;
        IF SUBSTR(id_no, 10, 1) = 0 THEN
            IF SUBSTR(chr_result, LENGTH(chr_result), 1) = 0 THEN
                RETURN TRUE;
            END IF;
        ELSE
            IF TO_CHAR((10 - TO_NUMBER(SUBSTR(chr_result, LENGTH(chr_result), 1)))) = SUBSTR(id_no, 10, 1) THEN
                RETURN TRUE;
            END IF;
        END IF;
        RETURN FALSE;
    END check_idno;

    -- Source: PU IS_DIGIT (unchanged)
    --@ORIG PU IS_DIGIT
    -- >>> Original Forms code: PU IS_DIGIT
    --   FUNCTION IS_Digit(txt_num VARCHAR2) RETURN BOOLEAN IS
    --    chr1      VARCHAR2(200);
    --    len_txt   NUMBER ;
    --    counter   NUMBER :=1;
    --   BEGIN
    --    len_txt:=LENGTH(txt_num);
    --    WHILE (counter<=len_txt) LOOP
    --       chr1 := SUBSTR(txt_num,counter,1) ;
    --       IF ASCII(chr1) <48  OR ASCII(chr1)>57 THEN
    --          RETURN FALSE;
    --        END IF;
    --        counter :=counter+1;
    --    END LOOP;
    --        RETURN TRUE;
    --   END;
    -- <<<
    FUNCTION is_digit (txt_num IN VARCHAR2) RETURN BOOLEAN
    IS
        chr1    VARCHAR2(200);
        len_txt NUMBER;
        counter NUMBER := 1;
    BEGIN
        len_txt := LENGTH(txt_num);
        WHILE (counter <= len_txt) LOOP
            chr1 := SUBSTR(txt_num, counter, 1);
            IF ASCII(chr1) < 48 OR ASCII(chr1) > 57 THEN
                RETURN FALSE;
            END IF;
            counter := counter + 1;
        END LOOP;
        RETURN TRUE;
    END is_digit;

    -- Source: PU CHECK_BUS_ID - whole body is commented out in Forms (only NULL is active)
    PROCEDURE check_bus_id
    IS
    BEGIN
        NULL;
    END check_bus_id;

    -- Source: PU CHK_BUS_ID_BRNCH
    --@ORIG PU CHK_BUS_ID_BRNCH
    -- >>> Original Forms code: PU CHK_BUS_ID_BRNCH
    --   PROCEDURE chk_bus_id_brnch IS
    --   BEGIN
    --       IF :IMPORTERS.BUS_ID_BRNCH = :IMPORTERS.BUS_ID THEN
    --           str.dispalert('غير مسموح بادخال رقم السجل الرئيسي مساوي لرقم السجل الفرعي .. أعد الادخال','error');
    --           RAISE form_trigger_failure ;
    --       END IF;
    --   END;
    -- <<<
    PROCEDURE chk_bus_id_brnch (p_rec IN T_RECORD)
    IS
    BEGIN
        IF p_rec.bus_id_brnch = p_rec.bus_id THEN
            FORM_TRIGGER_FAILURE('غير مسموح بادخال رقم السجل الرئيسي مساوي لرقم السجل الفرعي .. أعد الادخال');
        END IF;
    END chk_bus_id_brnch;

    -- Source: PU CHK_IMPR_DUPL (ELSE branch is commented out in Forms)
    --@ORIG PU CHK_IMPR_DUPL
    -- >>> Original Forms code: PU CHK_IMPR_DUPL
    --   PROCEDURE CHK_IMPR_DUPL IS
    --       V_COUNT NUMBER;
    --       V_IMPR_NAME VARCHAR2(200);
    --         V_IMPR_NBR  NUMBER;
    --   BEGIN
    --       IF :BUS_ID_BRNCH IS NOT NULL THEN
    --           SELECT COUNT(*)
    --           INTO    V_COUNT
    --           FROM  IMPORTERS
    --           WHERE PORT_CD = :IMPORTERS.PORT_CD
    --           AND    CTRY_CD = NVL(:IMPORTERS.CTRY_CD, CTRY_CD)
    --           AND    BUS_ID_TYPE_CD = :IMPORTERS.BUS_ID_TYPE_CD
    --           AND     BUS_ID  = :IMPORTERS.BUS_ID
    --           AND     BUS_ID_BRNCH = :IMPORTERS.BUS_ID_BRNCH
    --           AND        ((:IMPORTERS.IMPR_NBR IS NULL) OR (:IMPORTERS.IMPR_NBR IS NOT NULL AND IMPR_NBR <> :IMPORTERS.IMPR_NBR))
    --           ;
    --           IF V_COUNT > 0 THEN
    --               SELECT ARBC_IMPR_NAME,IMPR_NBR
    --               INTO    V_IMPR_NAME,V_IMPR_NBR
    --               FROM IMPORTERS
    --               WHERE PORT_CD = :IMPORTERS.PORT_CD
    --               AND    CTRY_CD = NVL(:IMPORTERS.CTRY_CD, CTRY_CD)
    --               AND    BUS_ID_TYPE_CD = :IMPORTERS.BUS_ID_TYPE_CD
    --               AND     BUS_ID  = :IMPORTERS.BUS_ID
    --               AND     BUS_ID_BRNCH = :IMPORTERS.BUS_ID_BRNCH
    --               AND        ((:IMPORTERS.IMPR_NBR IS NULL) OR (:IMPORTERS.IMPR_NBR IS NOT NULL AND IMPR_NBR <> :IMPORTERS.IMPR_NBR))
    --                     AND ROWNUM<=1
    --               ;
    --               STR.DISPALERT(' لايمكن الإدخال، يوجد مستورد مدخل بنفس نوع المستورد ونفس الرقم الإستدلالي الرئيسي والفرعي ورقمه:  '||V_IMPR_NBR||' اسمه '||V_IMPR_NAME,'ERROR');
    --               RAISE FORM_TRIGGER_FAILURE;
    --           END IF;
    --         END IF;
    --   END;
    -- <<<
    PROCEDURE chk_impr_dupl (p_rec IN T_RECORD)
    IS
        v_count     NUMBER;
        v_impr_name VARCHAR2(200);
        v_impr_nbr  NUMBER;
    BEGIN
        IF p_rec.bus_id_brnch IS NOT NULL THEN
            SELECT COUNT(*)
              INTO v_count
              FROM importers
             WHERE port_cd        = p_rec.port_cd
               AND ctry_cd        = NVL(p_rec.ctry_cd, ctry_cd)
               AND bus_id_type_cd = p_rec.bus_id_type_cd
               AND bus_id         = p_rec.bus_id
               AND bus_id_brnch   = p_rec.bus_id_brnch
               AND ((p_rec.impr_nbr IS NULL) OR (p_rec.impr_nbr IS NOT NULL AND impr_nbr <> p_rec.impr_nbr));
            IF v_count > 0 THEN
                SELECT arbc_impr_name, impr_nbr
                  INTO v_impr_name, v_impr_nbr
                  FROM importers
                 WHERE port_cd        = p_rec.port_cd
                   AND ctry_cd        = NVL(p_rec.ctry_cd, ctry_cd)
                   AND bus_id_type_cd = p_rec.bus_id_type_cd
                   AND bus_id         = p_rec.bus_id
                   AND bus_id_brnch   = p_rec.bus_id_brnch
                   AND ((p_rec.impr_nbr IS NULL) OR (p_rec.impr_nbr IS NOT NULL AND impr_nbr <> p_rec.impr_nbr))
                   AND ROWNUM <= 1;
                FORM_TRIGGER_FAILURE(' لايمكن الإدخال، يوجد مستورد مدخل بنفس نوع المستورد ونفس الرقم الإستدلالي الرئيسي والفرعي ورقمه:  '
                    || v_impr_nbr || ' اسمه ' || v_impr_name);
            END IF;
        END IF;
    END chk_impr_dupl;

    -- Source: PU CHK_DUPL_IMP_BRKR
    -- Note: Forms passes :BUS_ID twice (4th and 6th argument) - kept as is.
    --@ORIG PU CHK_DUPL_IMP_BRKR
    -- >>> Original Forms code: PU CHK_DUPL_IMP_BRKR
    --   PROCEDURE CHK_DUPL_IMP_BRKR IS
    --       V_VAR_VALUE VARCHAR2(2) := 0;
    --       V_CHK       NUMBER;
    --       V_MSG        VARCHAR2(500);
    --   BEGIN
    --       BEGIN
    --           SELECT VAR_VALUE
    --           INTO V_VAR_VALUE
    --           FROM SC_PORT_SETTING
    --           WHERE SYSOBJ_ID = 9
    --           AND VAR_NAME = 'CHK_DPLCATE_IMP_BRKR'
    --           AND PORT_CD    = :PARAMETER.P_CURR_PORT_CD
    --           ;
    --       EXCEPTION
    --       WHEN NO_DATA_FOUND  THEN
    --           V_VAR_VALUE := 0 ;
    --       END;
    --       IF V_VAR_VALUE = 1 THEN
    --           IF :IMPR_TYPE_CD IN (1,4) THEN
    --           V_CHK := IMPR.CHECK_DUPLICATE_IMP_BRKR(:PORT_CD,1,:IMPR_TYPE_CD,:BUS_ID,:COMM_RGSTRTN_TYPE,:BUS_ID,:BUS_ID_BRNCH,V_MSG);
    --           IF V_CHK = 1 THEN
    --               STR.DISPALERT(V_MSG,'ERROR');
    --               RAISE FORM_TRIGGER_FAILURE;
    --           END IF;
    --         END IF;
    --       END IF;
    --   END;
    -- <<<
    PROCEDURE chk_dupl_imp_brkr (p_rec IN T_RECORD, p_ctx IN T_CONTEXT)
    IS
        v_var_value VARCHAR2(2) := 0;
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
                v_var_value := 0;
        END;
        IF v_var_value = 1 THEN
            IF p_rec.impr_type_cd IN (1, 4) THEN
                v_chk := impr.check_duplicate_imp_brkr(p_rec.port_cd, 1, p_rec.impr_type_cd, p_rec.bus_id,
                                                       p_rec.comm_rgstrtn_type, p_rec.bus_id,
                                                       p_rec.bus_id_brnch, v_msg);
                IF v_chk = 1 THEN
                    FORM_TRIGGER_FAILURE(v_msg);
                END IF;
            END IF;
        END IF;
    END chk_dupl_imp_brkr;

    -- Source: PU CHK_PERSONAL
    -- In Forms the exception handler resets :IMPR_TYPE_CD to :GLOBAL.OLD_IMPR_TYPE_CD before
    -- the failure; p_rec is NOCOPY so the caller still sees the reset value after the error.
    --@ORIG PU CHK_PERSONAL
    -- >>> Original Forms code: PU CHK_PERSONAL
    --   PROCEDURE chk_personal (
    --      P_impr_type_cd   NUMBER,
    --      P_hq_impr_nbr    NUMBER,
    --      P_STOP NUMBER DEFAULT 1)
    --   IS
    --      v_new_type              NUMBER;
    --      v_old_type_personal     NUMBER;
    --      ex_personal_vs_others   EXCEPTION;
    --   BEGIN
    --      v_new_type := P_impr_type_cd;
    --      SELECT COUNT (*)
    --        INTO v_old_type_personal
    --        FROM importers
    --       WHERE hq_impr_nbr = P_hq_impr_nbr AND impr_type_cd = 4
    --   AND PORT_CD    = :PARAMETER.P_CURR_PORT_CD;
    --      IF v_new_type = 4 AND v_old_type_personal = 0
    --      THEN
    --         RAISE ex_personal_vs_others;
    --      END IF;
    --      IF v_new_type <> 4 AND v_old_type_personal > 0
    --      THEN
    --         RAISE ex_personal_vs_others;
    --      END IF;
    --   EXCEPTION
    --      WHEN ex_personal_vs_others
    --      THEN
    --        :impr_type_cd  := :GLOBAL.OLD_impr_type_cd ;
    --        SELECT IMPR_TYPE_NAME
    --        INTO :IMPR_TYPE_NAME
    --        FROM IMPR_TYPES
    --        WHERE IMPR_TYPE_CD = :impr_type_cd ;
    --         STR.DISPALERT('لا يمكن تغيير نوع المستورد من شخصي الي نوع آخر أو العكس , يتم ذلك من خلال الدعم الفني التطبيقات فقط' ,'ERROR');
    --       IF P_STOP = 1 THEN
    --             RAISE form_trigger_failure;
    --       END IF;
    --   END;
    -- <<<
    PROCEDURE chk_personal (p_rec          IN OUT NOCOPY T_RECORD,
                            p_ctx          IN T_CONTEXT,
                            p_impr_type_cd IN NUMBER,
                            p_hq_impr_nbr  IN NUMBER,
                            p_stop         IN NUMBER DEFAULT 1)
    IS
        v_new_type            NUMBER;
        v_old_type_personal   NUMBER;
        ex_personal_vs_others EXCEPTION;
    BEGIN
        v_new_type := p_impr_type_cd;
        SELECT COUNT(*)
          INTO v_old_type_personal
          FROM importers
         WHERE hq_impr_nbr  = p_hq_impr_nbr
           AND impr_type_cd = 4
           AND port_cd      = p_ctx.curr_port_cd;
        IF v_new_type = 4 AND v_old_type_personal = 0 THEN
            RAISE ex_personal_vs_others;
        END IF;
        IF v_new_type <> 4 AND v_old_type_personal > 0 THEN
            RAISE ex_personal_vs_others;
        END IF;
    EXCEPTION
        WHEN ex_personal_vs_others THEN
            p_rec.impr_type_cd := GET_GLOBAL('OLD_IMPR_TYPE_CD');
            SELECT impr_type_name
              INTO p_rec.impr_type_name
              FROM impr_types
             WHERE impr_type_cd = p_rec.impr_type_cd;
            IF p_stop = 1 THEN
                FORM_TRIGGER_FAILURE('لا يمكن تغيير نوع المستورد من شخصي الي نوع آخر أو العكس , يتم ذلك من خلال الدعم الفني التطبيقات فقط');
            ELSE
                info('لا يمكن تغيير نوع المستورد من شخصي الي نوع آخر أو العكس , يتم ذلك من خلال الدعم الفني التطبيقات فقط');
            END IF;
    END chk_personal;

    -- Source: PU INSERT_AUDIT_RECORD
    --@ORIG PU INSERT_AUDIT_RECORD
    -- >>> Original Forms code: PU INSERT_AUDIT_RECORD
    --   PROCEDURE Insert_Audit_Record (V_ACT_TYPE VARCHAR2) IS
    --       Ret NUMBER;
    --       V_ACT_DT DATE;
    --        V_USER_ID  VARCHAR2(11);
    --        v_impr_master_nbr   IMPORTERS.IMPR_MASTER_NBR%TYPE;
    --         v_act_status        IMPORTERS.ACT_STATUS%TYPE;
    --   BEGIN
    --   IF (:IMPORTERS.Impr_Nbr IS NOT NULL) THEN
    --   SELECT SYSDATE INTO V_ACT_DT FROM dual;
    --   V_USER_ID := :PARAMETER.P_USER_ID;
    --                  BEGIN
    --                     SELECT impr_master_nbr, act_status
    --                       INTO v_impr_master_nbr, v_act_status
    --                       FROM IMPORTERS
    --                      WHERE   PORT_CD    = :PARAMETER.P_CURR_PORT_CD
    --                   AND   bus_id_type_cd = :IMPORTERS.BUS_ID_TYPE_CD
    --                            AND bus_id = :IMPORTERS.BUS_ID
    --                            AND bus_id_brnch = :IMPORTERS.bus_id_brnch
    --                            AND impr_type_cd = :IMPORTERS.impr_type_cd
    --                            AND ctry_cd = :IMPORTERS.ctry_cd
    --                            AND ROWNUM = 1;
    --                  EXCEPTION
    --                     WHEN NO_DATA_FOUND
    --                     THEN
    --                        v_impr_master_nbr := NULL;
    --                        v_act_status := NULL;
    --                  END;
    --   INSERT INTO IMPR_UPDTS(Port_Cd, IMPR_NBR, HQ_IMPR_NBR, IMPR_TYPE_CD, BUS_ID_TYPE_CD, BUS_ID , BUS_ID_BRNCH, BUS_ID_EXPRD_DT, CTRY_CD_OF_ID, CITY_CODE_OF_ID, IMPR_EXPR_TYPE, ARBC_IMPR_NAME, ENG_IMPR_NAME, IMPR_NAME_STD, IMPR_NBR_PARENT,
    --                    IMPR_CNTCT_NAME, IMPR_TEL_NBR, IMPR_POB_NBR, IMPR_ZIP_CD, IMPR_FAX_NBR, IMPR_TELEX_NBR,  EMAIL, CTRY_CD, ADD_CTRY_CD, CITY_CODE, LST_TRAN_DT, IMPD_STMT_NBR, IMPR_DATA_SRCE, ACT_DT, ACT_TYPE, USR_ID,COMM_RGSTRTN_TYPE,CAR_AGENT_FLAG,MOBILE_NO,BANK_IBAN, EXPRESS_POST
    --                    ,ID_NBR
    --                          ,BUS_ID_ISSUE_DT,BUS_ID_STATUS,CREATION_FLAG
    --                          ,IMPR_ADDRESS ,impr_master_nbr ,act_status
    --                                         )
    --        VALUES(:IMPORTERS.Port_Cd, :IMPORTERS.IMPR_NBR, :IMPORTERS.HQ_IMPR_NBR, :IMPORTERS.IMPR_TYPE_CD, :IMPORTERS.BUS_ID_TYPE_CD,:IMPORTERS.BUS_ID , :IMPORTERS.BUS_ID_BRNCH, :IMPORTERS.BUS_ID_EXPRD_DT, :IMPORTERS.CTRY_CD_OF_ID, :IMPORTERS.CITY_CODE_OF_ID, :IMPORTERS.IMPR_EXPR_TYPE,:IMPORTERS.ARBC_IMPR_NAME, :IMPORTERS.ENG_IMPR_NAME, :IMPORTERS.IMPR_NAME_STD, :IMPORTERS.IMPR_NBR_PARENT,
    --             :IMPORTERS.IMPR_CNTCT_NAME, :IMPORTERS.IMPR_TEL_NBR, :IMPORTERS.IMPR_POB_NBR, :IMPORTERS.IMPR_ZIP_CD, :IMPORTERS.IMPR_FAX_NBR, :IMPORTERS.IMPR_TELEX_NBR, :IMPORTERS.EMAIL, :IMPORTERS.CTRY_CD, :IMPORTERS.ADD_CTRY_CD, :IMPORTERS.CITY_CODE, :IMPORTERS.LST_TRAN_DT, :IMPORTERS.IMPD_STMT_NBR, :IMPORTERS.IMPR_DATA_SRCE,  V_ACT_DT, V_ACT_TYPE, V_USER_ID,:IMPORTERS.COMM_RGSTRTN_TYPE,
    --             :IMPORTERS.CAR_AGENT_FLAG,:IMPORTERS.MOBILE_NO,:IMPORTERS.BANK_IBAN, :IMPORTERS.EXPRESS_POST
    --             ,:IMPORTERS.ID_NBR
    --                 ,:IMPORTERS.BUS_ID_ISSUE_DT,:IMPORTERS.BUS_ID_STATUS,:IMPORTERS.CREATION_FLAG
    --                 ,:IMPORTERS.IMPR_ADDRESS , v_impr_master_nbr , v_act_status
    --                                           );
    --   ELSE
    --       Ret := STR.DispArbMsg(9, 140,'ERROR');
    --       RAISE FORm_Trigger_Failure;
    --   END IF;
    --   END;
    -- <<<
    PROCEDURE insert_audit_record (p_rec IN T_RECORD, p_ctx IN T_CONTEXT, v_act_type IN VARCHAR2)
    IS
        v_act_dt            DATE;
        v_user_id           VARCHAR2(11);
        v_impr_master_nbr   importers.impr_master_nbr%TYPE;
        v_act_status        importers.act_status%TYPE;
    BEGIN
        IF (p_rec.impr_nbr IS NOT NULL) THEN
            SELECT SYSDATE INTO v_act_dt FROM dual;
            v_user_id := p_ctx.user_id;
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
                p_rec.impd_stmt_nbr, p_rec.impr_data_srce, v_act_dt, v_act_type, v_user_id,
                p_rec.comm_rgstrtn_type, p_rec.car_agent_flag, p_rec.mobile_no, p_rec.bank_iban,
                p_rec.express_post, p_rec.id_nbr, p_rec.bus_id_issue_dt, p_rec.bus_id_status,
                p_rec.creation_flag, p_rec.impr_address, v_impr_master_nbr, v_act_status);
        ELSE
            DISPLAY_ARABIC_ERROR(9, 140);
        END IF;
    END insert_audit_record;

    -- Source: PU UPDATE_BASIC_IMPORTER
    -- HIGH: Forms ends with STANDARD.COMMIT (commits the whole form transaction in the middle
    -- of POST-INSERT/POST-UPDATE). Removed - APEX commits at the end of page processing.
    --@ORIG PU UPDATE_BASIC_IMPORTER
    -- >>> Original Forms code: PU UPDATE_BASIC_IMPORTER
    --   PROCEDURE UPDATE_BASIC_IMPORTER IS
    --   X NUMBER;
    --   BEGIN
    --   SELECT COUNT(*) INTO X FROM IMPORTER_BASIC_DATA
    --   WHERE  BUS_ID=:BUS_ID AND BUS_ID_BRNCH = NVL(:BUS_ID_BRNCH,0)
    --   AND IMPR_TYPE_CD=:IMPR_TYPE_CD AND BUS_ID_TYPE_CD = :BUS_ID_TYPE_CD;
    --   IF X = 0 THEN
    --   INSERT INTO IMPORTER_BASIC_DATA
    --      (BUS_ID, BUS_ID_BRNCH,
    --       IMPR_TYPE_CD, BUS_ID_TYPE_CD, MOBILE_NO, EMAIL,ID_NBR,HQ_IMPR_NBR)
    --    VALUES
    --     (:BUS_ID, NVL(:BUS_ID_BRNCH,0),
    --       :IMPR_TYPE_CD, :BUS_ID_TYPE_CD, :B_MOBILE_NO,:B_EMAIL,:B_ID_NBR,:HQ_IMPR_NBR);
    --   ELSE
    --   UPDATE IMPORTER_BASIC_DATA SET MOBILE_NO=NVL(:IMPORTERS.B_MOBILE_NO,MOBILE_NO),
    --       EMAIL=NVL(:IMPORTERS.B_EMAIL,EMAIL),
    --       ID_NBR=NVL(:IMPORTERS.B_ID_NBR,ID_NBR),
    --       HQ_IMPR_NBR=NVL(:HQ_IMPR_NBR,HQ_IMPR_NBR)
    --   WHERE  BUS_ID=:BUS_ID AND NVL(BUS_ID_BRNCH,0) = NVL(:BUS_ID_BRNCH,0)
    --   AND IMPR_TYPE_CD=:IMPR_TYPE_CD AND BUS_ID_TYPE_CD = :BUS_ID_TYPE_CD;
    --   END IF;
    --   STANDARD.COMMIT;
    --   END;
    -- <<<
    PROCEDURE update_basic_importer (p_rec IN T_RECORD)
    IS
        x NUMBER;
    BEGIN
        SELECT COUNT(*) INTO x
          FROM importer_basic_data
         WHERE bus_id         = p_rec.bus_id
           AND bus_id_brnch   = NVL(p_rec.bus_id_brnch, 0)
           AND impr_type_cd   = p_rec.impr_type_cd
           AND bus_id_type_cd = p_rec.bus_id_type_cd;
        IF x = 0 THEN
            INSERT INTO importer_basic_data
                (bus_id, bus_id_brnch, impr_type_cd, bus_id_type_cd, mobile_no, email, id_nbr, hq_impr_nbr)
            VALUES
                (p_rec.bus_id, NVL(p_rec.bus_id_brnch, 0), p_rec.impr_type_cd, p_rec.bus_id_type_cd,
                 p_rec.b_mobile_no, p_rec.b_email, p_rec.b_id_nbr, p_rec.hq_impr_nbr);
        ELSE
            UPDATE importer_basic_data
               SET mobile_no   = NVL(p_rec.b_mobile_no, mobile_no),
                   email       = NVL(p_rec.b_email, email),
                   id_nbr      = NVL(p_rec.b_id_nbr, id_nbr),
                   hq_impr_nbr = NVL(p_rec.hq_impr_nbr, hq_impr_nbr)
             WHERE bus_id               = p_rec.bus_id
               AND NVL(bus_id_brnch, 0) = NVL(p_rec.bus_id_brnch, 0)
               AND impr_type_cd         = p_rec.impr_type_cd
               AND bus_id_type_cd       = p_rec.bus_id_type_cd;
        END IF;
        -- STANDARD.COMMIT;   -- removed, see header
    END update_basic_importer;

    -- Source: PU RETURN_IMPR_ID
    --@ORIG PU RETURN_IMPR_ID
    -- >>> Original Forms code: PU RETURN_IMPR_ID
    --   PROCEDURE RETURN_IMPR_ID IS
    --   BEGIN
    --   IF    :PARAMETER.P_USER_TYPE = 2 AND :PARAMETER.P_CLASS_CD = 23 THEN
    --   :GLOBAL.IMPR_NBR_B:=:IMPR_NBR;
    --   :GLOBAL.IMPR_NAME_B:=:ARBC_IMPR_NAME;
    --   END IF ;
    --   END;
    -- <<<
    PROCEDURE return_impr_id (p_rec IN T_RECORD, p_ctx IN T_CONTEXT)
    IS
    BEGIN
        IF p_ctx.user_type = 2 AND p_ctx.class_cd = 23 THEN
            SET_GLOBAL('IMPR_NBR_B', p_rec.impr_nbr);
            SET_GLOBAL('IMPR_NAME_B', p_rec.arbc_impr_name);
        END IF;
    END return_impr_id;

    -- Source: PU BROKER_INT
    --@ORIG PU BROKER_INT
    -- >>> Original Forms code: PU BROKER_INT
    --   PROCEDURE BROKER_INT IS
    --   BEGIN
    --   :IMPR_EXPR_TYPE:=1;
    --   :EXPRESS_POST:=2;
    --   SET_ITEM_PROPERTY('IMPR_EXPR_TYPE',ENABLED,PROPERTY_FALSE);
    --   SET_ITEM_PROPERTY('EXPRESS_POST',ENABLED,PROPERTY_FALSE);
    --   END;
    -- <<<
    PROCEDURE broker_int (p_rec IN OUT NOCOPY T_RECORD)
    IS
    BEGIN
        p_rec.impr_expr_type := 1;
        p_rec.express_post   := 2;
        NULL;  -- APEX (read_only_rules.md): ui('IMPR_EXPR_TYPE', 'ENABLED', FALSE);
        NULL;  -- APEX (read_only_rules.md): ui('EXPRESS_POST', 'ENABLED', FALSE);
    END broker_int;

    -- Source: PU ADJ_FUNS (TMPLT function menu -> SET_FUNCTION_ENABLED() recorder; APEX: button/menu conditions)
    --@ORIG PU ADJ_FUNS
    -- >>> Original Forms code: PU ADJ_FUNS
    --   PROCEDURE ADJ_FUNS IS
    --       V_COUNT     NUMBER := 0;
    --       V_ROL_CNT NUMBER;
    --   BEGIN
    --       IF   :PARAMETER.P_CLASS_CD=1 AND :PARAMETER.P_USER_TYPE=3 AND :IMPR_NBR IS NOT NULL THEN
    --           NULL;
    --       ELSE
    --           TMPLT.DISABLE_FUN('CREATE_BRKR_IMPR_AUTH');
    --       END IF;  -- HATEM 6-9-2015
    --       IF :PARAMETER.P_CLASS_CD = 19 AND :PARAMETER.P_USER_TYPE = 1 THEN
    --           SELECT COUNT(*) INTO V_ROL_CNT
    --           FROM   SC_USER_ROLES
    --           WHERE PORT_CD    = :PARAMETER.P_CURR_PORT_CD
    --           and USER_ID = :PARAMETER.P_USER_ID
    --           AND    ROLE_ID = 'IMPR_UPD'
    --           ;
    --           IF V_ROL_CNT > 0 AND :IMPR_TYPE_CD = 1  THEN
    --               TMPLT.ENABLE_FUN('IMPR1110F3');
    --           ELSE
    --               TMPLT.DISABLE_FUN('IMPR1110F3');
    --           END IF;
    --       END IF;
    --   IF (NVL(:BUS_ID_TYPE_CD,0) = 2  AND :GLOBAL.ALLOW_MCI = 1 AND :IMPR_TYPE_CD <>12)OR (:IMPR_TYPE_CD = 4 AND :BUS_ID_TYPE_CD IN (3, 5) AND :GLOBAL.ALLOW_MOI = 1  )THEN
    --    TMPLT.ENABLE_FUN('IMPR_MCI_SERVICE');
    --   ELSE
    --    TMPLT.DISABLE_FUN('IMPR_MCI_SERVICE');
    --   END IF;
    --   TMPLT.DISABLE_FUN('IMPR1110F2');
    --        IF :PARAMETER.P_CURR_PORT_CD <> 99 THEN
    --          TMPLT.DISABLE_FUN('IMPR1110_MOB');
    --        END IF;
    --   EXCEPTION
    --       WHEN OTHERS THEN NULL;
    --   END;
    -- <<<
    PROCEDURE adj_funs (p_rec IN T_RECORD, p_ctx IN T_CONTEXT)
    IS
        v_rol_cnt NUMBER;
    BEGIN
        IF p_ctx.class_cd = 1 AND p_ctx.user_type = 3 AND p_rec.impr_nbr IS NOT NULL THEN
            NULL;
        ELSE
            SET_FUNCTION_ENABLED('CREATE_BRKR_IMPR_AUTH', FALSE);
        END IF;
        IF p_ctx.class_cd = 19 AND p_ctx.user_type = 1 THEN
            SELECT COUNT(*) INTO v_rol_cnt
              FROM sc_user_roles
             WHERE port_cd = p_ctx.curr_port_cd
               AND user_id = p_ctx.user_id
               AND role_id = 'IMPR_UPD';
            IF v_rol_cnt > 0 AND p_rec.impr_type_cd = 1 THEN
                SET_FUNCTION_ENABLED('IMPR1110F3', TRUE);
            ELSE
                SET_FUNCTION_ENABLED('IMPR1110F3', FALSE);
            END IF;
        END IF;
        IF (NVL(p_rec.bus_id_type_cd, 0) = 2 AND GET_GLOBAL('ALLOW_MCI') = '1' AND p_rec.impr_type_cd <> 12)
           OR (p_rec.impr_type_cd = 4 AND p_rec.bus_id_type_cd IN (3, 5) AND GET_GLOBAL('ALLOW_MOI') = '1') THEN
            SET_FUNCTION_ENABLED('IMPR_MCI_SERVICE', TRUE);
        ELSE
            SET_FUNCTION_ENABLED('IMPR_MCI_SERVICE', FALSE);
        END IF;
        SET_FUNCTION_ENABLED('IMPR1110F2', FALSE);
        IF p_ctx.curr_port_cd <> 99 THEN
            SET_FUNCTION_ENABLED('IMPR1110_MOB', FALSE);
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END adj_funs;

    -- Source: PU GET_CR_DATA (Ministry of Commerce reply "f1|f2|...|f16")
    -- Converted 1:1; the 17 INSTR/SUBSTR statements are written as a loop (same result).
    --@ORIG PU GET_CR_DATA
    -- >>> Original Forms code: PU GET_CR_DATA
    --   PROCEDURE get_cr_data (p_string_result VARCHAR2, p_type VARCHAR2)
    --   IS
    --      FOUND               NUMBER;
    --      string_result       VARCHAR2 (5000);
    --      v_pos_1             NUMBER;
    --      v_pos_2             NUMBER;
    --      v_pos_3             NUMBER;
    --      v_pos_4             NUMBER;
    --      v_pos_5             NUMBER;
    --      v_pos_6             NUMBER;
    --      v_pos_7             NUMBER;
    --      v_pos_8             NUMBER;
    --      v_pos_9             NUMBER;
    --      v_pos_10            NUMBER;
    --      v_pos_11            NUMBER;
    --      v_pos_12            NUMBER;
    --      v_pos_13            NUMBER;
    --      v_pos_14            NUMBER;
    --      v_pos_15            NUMBER;
    --      v_pos_16            NUMBER;
    --      v_pos_17            NUMBER;
    --      v_pos_18            NUMBER;
    --      v_pos_19            NUMBER;
    --      v_pos_20            NUMBER;
    --      v_pos_21            NUMBER;
    --      v_txt_1             VARCHAR2 (500);
    --      v_txt_2             VARCHAR2 (500);
    --      v_txt_3             VARCHAR2 (500);
    --      v_txt_4             VARCHAR2 (500);
    --      v_txt_5             VARCHAR2 (500);
    --      v_txt_6             VARCHAR2 (500);
    --      v_txt_7             VARCHAR2 (500);
    --      v_txt_8             VARCHAR2 (500);
    --      v_txt_9             VARCHAR2 (500);
    --      v_txt_10            VARCHAR2 (500);
    --      v_txt_11            VARCHAR2 (500);
    --      v_txt_12            VARCHAR2 (500);
    --      v_txt_13            VARCHAR2 (500);
    --      v_txt_14            VARCHAR2 (500);
    --      v_txt_15            VARCHAR2 (500);
    --      v_txt_16            VARCHAR2 (500);
    --      v_txt_17            VARCHAR2 (500);
    --      v_txt_18            VARCHAR2 (500);
    --      v_txt_19            VARCHAR2 (500);
    --      v_txt_20            VARCHAR2 (500);
    --      v_txt_21            VARCHAR2 (500);
    --      v_bus_id_exprd_dt   importers.bus_id_exprd_dt%TYPE;
    --      v_bus_id_issue_dt   importers.bus_id_issue_dt%TYPE;
    --      v_arbc_impr_name    importers.arbc_impr_name%TYPE;
    --      v_impr_name_std     importers.impr_name_std%TYPE;
    --      v_impr_address      importers.impr_address%TYPE;
    --      v_impr_tel_nbr      importers.impr_tel_nbr%TYPE;
    --      v_impr_fax_nbr      importers.impr_fax_nbr%TYPE;
    --      v_impr_telex_nbr    importers.impr_telex_nbr%TYPE;
    --      v_activity          importers.activity%TYPE;
    --      v_bus_id_status     importers.bus_id_status%TYPE;
    --      v_city_code_of_id   importers.city_code_of_id%TYPE;
    --      v_port_cd           importers.port_cd%TYPE;
    --      v_impr_nbr          importers.impr_nbr%TYPE;
    --      v_hq_impr_nbr       importers.hq_impr_nbr%TYPE;
    --      v_bus_id            importers.bus_id%TYPE;
    --      v_bus_id_brnch      importers.bus_id_brnch%TYPE;
    --   BEGIN
    --      str.dispalert
    --         ('سيتم الحصول على بيانات المستورد من وزارة التجارة.....الرجاء الإنتظار',
    --          'ERROR'
    --         );
    --      string_result := p_string_result;
    --      IF string_result IS NOT NULL
    --      THEN
    --         string_result :=
    --               LTRIM (RTRIM (string_result))
    --            || ' |'
    --            || ' |'
    --            || ' |'
    --            || ' |'
    --            || ' |'
    --            || ' |'
    --            || ' |'
    --            || ' |'
    --            || ' |'
    --            || ' |'
    --            || ' |'
    --            || ' |'
    --            || ' |'
    --            || ' |'
    --            || ' |'
    --            || ' |'
    --            || ' |'
    --            || ' |'
    --            || ' |'
    --            || ' |'
    --            || ' |'
    --            || ' |';
    --         SELECT INSTR (string_result, '|', 1)
    --           INTO v_pos_1
    --           FROM DUAL;
    --         SELECT INSTR (string_result, '|', 1 + v_pos_1)
    --           INTO v_pos_2
    --           FROM DUAL;
    --         SELECT INSTR (string_result, '|', 1 + v_pos_2)
    --           INTO v_pos_3
    --           FROM DUAL;
    --         SELECT INSTR (string_result, '|', 1 + v_pos_3)
    --           INTO v_pos_4
    --           FROM DUAL;
    --         SELECT INSTR (string_result, '|', 1 + v_pos_4)
    --           INTO v_pos_5
    --           FROM DUAL;
    --         SELECT INSTR (string_result, '|', 1 + v_pos_5)
    --           INTO v_pos_6
    --           FROM DUAL;
    --         SELECT INSTR (string_result, '|', 1 + v_pos_6)
    --           INTO v_pos_7
    --           FROM DUAL;
    --         SELECT INSTR (string_result, '|', 1 + v_pos_7)
    --           INTO v_pos_8
    --           FROM DUAL;
    --         SELECT INSTR (string_result, '|', 1 + v_pos_8)
    --           INTO v_pos_9
    --           FROM DUAL;
    --         SELECT INSTR (string_result, '|', 1 + v_pos_9)
    --           INTO v_pos_10
    --           FROM DUAL;
    --         SELECT INSTR (string_result, '|', 1 + v_pos_10)
    --           INTO v_pos_11
    --           FROM DUAL;
    --         SELECT INSTR (string_result, '|', 1 + v_pos_11)
    --           INTO v_pos_12
    --           FROM DUAL;
    --         SELECT INSTR (string_result, '|', 1 + v_pos_12)
    --           INTO v_pos_13
    --           FROM DUAL;
    --         SELECT INSTR (string_result, '|', 1 + v_pos_13)
    --           INTO v_pos_14
    --           FROM DUAL;
    --         SELECT INSTR (string_result, '|', 1 + v_pos_14)
    --           INTO v_pos_15
    --           FROM DUAL;
    --         SELECT INSTR (string_result, '|', 1 + v_pos_15)
    --           INTO v_pos_16
    --           FROM DUAL;
    --         SELECT INSTR (string_result, '|', 1 + v_pos_16)
    --           INTO v_pos_17
    --           FROM DUAL;
    --         v_txt_1 :=
    --                 UPPER (LTRIM (RTRIM (SUBSTR (string_result, 1, v_pos_1 - (1)))));
    --         v_txt_2 :=
    --            UPPER (LTRIM (RTRIM (SUBSTR (string_result,
    --                                         v_pos_1 + 1,
    --                                         v_pos_2 - (v_pos_1 + 1)
    --                                        )
    --                                )
    --                         )
    --                  );
    --         v_txt_3 :=
    --            UPPER (LTRIM (RTRIM (SUBSTR (string_result,
    --                                         v_pos_2 + 1,
    --                                         v_pos_3 - (v_pos_2 + 1)
    --                                        )
    --                                )
    --                         )
    --                  );
    --         v_txt_4 :=
    --            UPPER (LTRIM (RTRIM (SUBSTR (string_result,
    --                                         v_pos_3 + 1,
    --                                         v_pos_4 - (v_pos_3 + 1)
    --                                        )
    --                                )
    --                         )
    --                  );
    --         v_txt_5 :=
    --            UPPER (LTRIM (RTRIM (SUBSTR (string_result,
    --                                         v_pos_4 + 1,
    --                                         v_pos_5 - (v_pos_4 + 1)
    --                                        )
    --                                )
    --                         )
    --                  );
    --         v_txt_6 :=
    --            UPPER (LTRIM (RTRIM (SUBSTR (string_result,
    --                                         v_pos_5 + 1,
    --                                         v_pos_6 - (v_pos_5 + 1)
    --                                        )
    --                                )
    --                         )
    --                  );
    --         v_txt_7 :=
    --            UPPER (LTRIM (RTRIM (SUBSTR (string_result,
    --                                         v_pos_6 + 1,
    --                                         v_pos_7 - (v_pos_6 + 1)
    --                                        )
    --                                )
    --                         )
    --                  );
    --         v_txt_8 :=
    --            UPPER (LTRIM (RTRIM (SUBSTR (string_result,
    --                                         v_pos_7 + 1,
    --                                         v_pos_8 - (v_pos_7 + 1)
    --                                        )
    --                                )
    --                         )
    --                  );
    --         v_txt_9 :=
    --            UPPER (LTRIM (RTRIM (SUBSTR (string_result,
    --                                         v_pos_8 + 1,
    --                                         v_pos_9 - (v_pos_8 + 1)
    --                                        )
    --                                )
    --                         )
    --                  );
    --         v_txt_10 :=
    --            UPPER (LTRIM (RTRIM (SUBSTR (string_result,
    --                                         v_pos_9 + 1,
    --                                         v_pos_10 - (v_pos_9 + 1)
    --                                        )
    --                                )
    --                         )
    --                  );
    --         v_txt_11 :=
    --            UPPER (LTRIM (RTRIM (SUBSTR (string_result,
    --                                         v_pos_10 + 1,
    --                                         v_pos_11 - (v_pos_10 + 1)
    --                                        )
    --                                )
    --                         )
    --                  );
    --         v_txt_12 :=
    --            UPPER (LTRIM (RTRIM (SUBSTR (string_result,
    --                                         v_pos_11 + 1,
    --                                         v_pos_12 - (v_pos_11 + 1)
    --                                        )
    --                                )
    --                         )
    --                  );
    --         v_txt_13 :=
    --            UPPER (LTRIM (RTRIM (SUBSTR (string_result,
    --                                         v_pos_12 + 1,
    --                                         v_pos_13 - (v_pos_12 + 1)
    --                                        )
    --                                )
    --                         )
    --                  );
    --         v_txt_14 :=
    --            UPPER (LTRIM (RTRIM (SUBSTR (string_result,
    --                                         v_pos_13 + 1,
    --                                         v_pos_14 - (v_pos_13 + 1)
    --                                        )
    --                                )
    --                         )
    --                  );
    --         v_txt_15 :=
    --            UPPER (LTRIM (RTRIM (SUBSTR (string_result,
    --                                         v_pos_14 + 1,
    --                                         v_pos_15 - (v_pos_14 + 1)
    --                                        )
    --                                )
    --                         )
    --                  );
    --         v_txt_16 :=
    --            UPPER (LTRIM (RTRIM (SUBSTR (string_result,
    --                                         v_pos_15 + 1,
    --                                         v_pos_16 - (v_pos_15 + 1)
    --                                        )
    --                                )
    --                         )
    --                  );
    --         IF v_txt_1 IS NOT NULL
    --         THEN
    --            v_bus_id_exprd_dt := TO_DATE (v_txt_3, 'MI-MM-YYYY');
    --            v_bus_id_issue_dt := TO_DATE (v_txt_4, 'MI-MM-YYYY');
    --            v_arbc_impr_name := v_txt_6;
    --            v_impr_address := v_txt_8;
    --            IF v_txt_9 > '0000000'
    --            THEN
    --               v_impr_tel_nbr := v_txt_9;
    --            ELSIF v_txt_10 > '0000000'
    --            THEN
    --               v_impr_tel_nbr := v_txt_10;
    --            END IF;
    --            IF v_txt_11 > '0000000'
    --            THEN
    --               v_impr_fax_nbr := v_txt_11;
    --            ELSIF v_txt_12 > '0000000'
    --            THEN
    --               v_impr_fax_nbr := v_txt_12;
    --            END IF;
    --            v_impr_telex_nbr := v_txt_13;
    --            v_activity := v_txt_14;
    --            IF UPPER (v_txt_15) = 'ACTIVE'
    --            THEN
    --               v_bus_id_status := 1;
    --            ELSIF UPPER (v_txt_15) = 'EXPIRED'
    --            THEN
    --               v_bus_id_status := 2;
    --            ELSIF UPPER (v_txt_15) = 'SUSPENDED'
    --            THEN
    --               v_bus_id_status := 3;
    --            ELSIF UPPER (v_txt_15) LIKE 'WRITTEN%OFF'
    --            THEN
    --               v_bus_id_status := 4;
    --            ELSIF UPPER (v_txt_15) LIKE 'CANCELLED'
    --            THEN
    --               v_bus_id_status := 4;
    --            ELSE
    --               v_bus_id_status := 5;
    --            END IF;
    --            BEGIN
    --               SELECT city_cd
    --                 INTO v_city_code_of_id
    --                 FROM cities
    --                WHERE mins_comm_cd = v_txt_16;
    --            EXCEPTION
    --               WHEN OTHERS
    --               THEN
    --                  NULL;
    --            END;
    --            v_impr_name_std := str_db.strformat (v_arbc_impr_name);
    --            :importers.bus_id_exprd_dt := v_bus_id_exprd_dt;
    --            :importers.bus_id_issue_dt := v_bus_id_issue_dt;
    --            :importers.arbc_impr_name := v_arbc_impr_name;
    --            :importers.impr_name_std := v_impr_name_std;
    --            :importers.impr_address := v_impr_address;
    --            :importers.impr_tel_nbr := v_impr_tel_nbr;
    --            :importers.impr_fax_nbr := v_impr_fax_nbr;
    --            :importers.impr_telex_nbr := v_impr_telex_nbr;
    --            :importers.activity := v_activity;
    --            :importers.bus_id_status := v_bus_id_status;
    --            :importers.lst_tran_dt := SYSDATE;
    --            :importers.creation_flag := 3;
    --            IF p_type = 'B'
    --            THEN
    --               :importers.brnh_city_cd := v_city_code_of_id;
    --               BEGIN
    --                  SELECT city_arb_name
    --                    INTO :importers.brnh_city_name
    --                    FROM cities
    --                   WHERE city_cd = :importers.brnh_city_cd
    --                     AND ctry_cd = :ctry_cd_of_id;
    --               EXCEPTION
    --                  WHEN OTHERS
    --                  THEN
    --                     NULL;
    --               END;
    --            ELSIF p_type = 'M'
    --            THEN
    --               :importers.city_code_of_id := v_city_code_of_id;
    --               BEGIN
    --                  SELECT city_arb_name
    --                    INTO :importers.id_city_name
    --                    FROM cities
    --                   WHERE city_cd = :importers.city_code_of_id
    --                     AND ctry_cd = :ctry_cd_of_id;
    --               EXCEPTION
    --                  WHEN OTHERS
    --                  THEN
    --                     NULL;
    --               END;
    --            END IF;
    --         END IF;
    --      END IF;
    --   END;
    -- <<<
    PROCEDURE get_cr_data (p_rec           IN OUT NOCOPY T_RECORD,
                           p_string_result IN VARCHAR2,
                           p_type          IN VARCHAR2)
    IS
        TYPE t_num_tab IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
        string_result      VARCHAR2(5000);
        v_pos              t_num_tab;
        v_txt              t_vc_tab;
        v_bus_id_exprd_dt  importers.bus_id_exprd_dt%TYPE;
        v_bus_id_issue_dt  importers.bus_id_issue_dt%TYPE;
        v_arbc_impr_name   importers.arbc_impr_name%TYPE;
        v_impr_name_std    importers.impr_name_std%TYPE;
        v_impr_address     importers.impr_address%TYPE;
        v_impr_tel_nbr     importers.impr_tel_nbr%TYPE;
        v_impr_fax_nbr     importers.impr_fax_nbr%TYPE;
        v_impr_telex_nbr   importers.impr_telex_nbr%TYPE;
        v_activity         importers.activity%TYPE;
        v_bus_id_status    importers.bus_id_status%TYPE;
        v_city_code_of_id  importers.city_code_of_id%TYPE;
    BEGIN
        info('سيتم الحصول على بيانات المستورد من وزارة التجارة.....الرجاء الإنتظار');
        string_result := p_string_result;
        IF string_result IS NOT NULL THEN
            string_result := LTRIM(RTRIM(string_result));
            FOR i IN 1 .. 22 LOOP
                string_result := string_result || ' |';
            END LOOP;
            v_pos(0) := 0;
            FOR i IN 1 .. 17 LOOP
                v_pos(i) := INSTR(string_result, '|', 1 + v_pos(i - 1));
            END LOOP;
            v_txt(1) := UPPER(LTRIM(RTRIM(SUBSTR(string_result, 1, v_pos(1) - (1)))));
            FOR i IN 2 .. 16 LOOP
                v_txt(i) := UPPER(LTRIM(RTRIM(SUBSTR(string_result, v_pos(i - 1) + 1,
                                                     v_pos(i) - (v_pos(i - 1) + 1)))));
            END LOOP;
            IF v_txt(1) IS NOT NULL THEN
                v_bus_id_exprd_dt := TO_DATE(v_txt(3), 'MI-MM-YYYY');
                v_bus_id_issue_dt := TO_DATE(v_txt(4), 'MI-MM-YYYY');
                v_arbc_impr_name  := v_txt(6);
                v_impr_address    := v_txt(8);
                IF v_txt(9) > '0000000' THEN
                    v_impr_tel_nbr := v_txt(9);
                ELSIF v_txt(10) > '0000000' THEN
                    v_impr_tel_nbr := v_txt(10);
                END IF;
                IF v_txt(11) > '0000000' THEN
                    v_impr_fax_nbr := v_txt(11);
                ELSIF v_txt(12) > '0000000' THEN
                    v_impr_fax_nbr := v_txt(12);
                END IF;
                v_impr_telex_nbr := v_txt(13);
                v_activity       := v_txt(14);
                IF UPPER(v_txt(15)) = 'ACTIVE' THEN
                    v_bus_id_status := 1;
                ELSIF UPPER(v_txt(15)) = 'EXPIRED' THEN
                    v_bus_id_status := 2;
                ELSIF UPPER(v_txt(15)) = 'SUSPENDED' THEN
                    v_bus_id_status := 3;
                ELSIF UPPER(v_txt(15)) LIKE 'WRITTEN%OFF' THEN
                    v_bus_id_status := 4;
                ELSIF UPPER(v_txt(15)) LIKE 'CANCELLED' THEN
                    v_bus_id_status := 4;
                ELSE
                    v_bus_id_status := 5;
                END IF;
                BEGIN
                    SELECT city_cd
                      INTO v_city_code_of_id
                      FROM cities
                     WHERE mins_comm_cd = v_txt(16);
                EXCEPTION
                    WHEN OTHERS THEN
                        NULL;
                END;
                v_impr_name_std := str_db.strformat(v_arbc_impr_name);
                p_rec.bus_id_exprd_dt := v_bus_id_exprd_dt;
                p_rec.bus_id_issue_dt := v_bus_id_issue_dt;
                p_rec.arbc_impr_name  := v_arbc_impr_name;
                p_rec.impr_name_std   := v_impr_name_std;
                p_rec.impr_address    := v_impr_address;
                p_rec.impr_tel_nbr    := v_impr_tel_nbr;
                p_rec.impr_fax_nbr    := v_impr_fax_nbr;
                p_rec.impr_telex_nbr  := v_impr_telex_nbr;
                p_rec.activity        := v_activity;
                p_rec.bus_id_status   := v_bus_id_status;
                p_rec.lst_tran_dt     := SYSDATE;
                p_rec.creation_flag   := 3;
                IF p_type = 'B' THEN
                    p_rec.brnh_city_cd := v_city_code_of_id;
                    BEGIN
                        SELECT city_arb_name
                          INTO p_rec.brnh_city_name
                          FROM cities
                         WHERE city_cd = p_rec.brnh_city_cd
                           AND ctry_cd = p_rec.ctry_cd_of_id;
                    EXCEPTION
                        WHEN OTHERS THEN
                            NULL;
                    END;
                ELSIF p_type = 'M' THEN
                    p_rec.city_code_of_id := v_city_code_of_id;
                    BEGIN
                        SELECT city_arb_name
                          INTO p_rec.id_city_name
                          FROM cities
                         WHERE city_cd = p_rec.city_code_of_id
                           AND ctry_cd = p_rec.ctry_cd_of_id;
                    EXCEPTION
                        WHEN OTHERS THEN
                            NULL;
                    END;
                END IF;
            END IF;
        END IF;
    END get_cr_data;

    -- Source: PU GET_MAIN_CR_DATA
    --@ORIG PU GET_MAIN_CR_DATA
    -- >>> Original Forms code: PU GET_MAIN_CR_DATA
    --   PROCEDURE get_main_cr_data IS
    --   STRING_RESULT VARCHAR2(5000);
    --   BEGIN
    --       SELECT MCISERVICE.getMainCRInfoCall ( :importers.bus_id , 'MCIService')
    --       INTO STRING_RESULT
    --       FROM DUAL;
    --       get_cr_data(STRING_RESULT,'M');
    --   EXCEPTION
    --       WHEN OTHERS THEN NULL;
    --   END;
    -- <<<
    PROCEDURE get_main_cr_data (p_rec IN OUT NOCOPY T_RECORD)
    IS
        string_result VARCHAR2(5000);
    BEGIN
        SELECT mciservice.getmaincrinfocall(p_rec.bus_id, 'MCIService')
          INTO string_result
          FROM dual;
        get_cr_data(p_rec, string_result, 'M');
    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END get_main_cr_data;

    -- Source: PU GET_BRANCH_CR_DATA
    --@ORIG PU GET_BRANCH_CR_DATA
    -- >>> Original Forms code: PU GET_BRANCH_CR_DATA
    --   PROCEDURE get_branch_cr_data IS
    --   STRING_RESULT VARCHAR2(5000);
    --   BEGIN
    --       SELECT MCISERVICE.getBranchCRInfoCall ( :importers.bus_id_brnch , 'MCIService')
    --       INTO STRING_RESULT
    --       FROM DUAL;
    --       get_cr_data(STRING_RESULT,'B');
    --   EXCEPTION
    --       WHEN OTHERS THEN NULL;
    --   END;
    -- <<<
    PROCEDURE get_branch_cr_data (p_rec IN OUT NOCOPY T_RECORD)
    IS
        string_result VARCHAR2(5000);
    BEGIN
        SELECT mciservice.getbranchcrinfocall(p_rec.bus_id_brnch, 'MCIService')
          INTO string_result
          FROM dual;
        get_cr_data(p_rec, string_result, 'B');
    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END get_branch_cr_data;

    -- Source: PU CREATE_BRKR_IMPR_AUTH
    -- HIGH: STANDARD.COMMIT removed (APEX commits). Message and globals are set for both user
    -- groups exactly as in Forms (the INSERT only for class 1 / user type 3).
    --@ORIG PU CREATE_BRKR_IMPR_AUTH
    -- >>> Original Forms code: PU CREATE_BRKR_IMPR_AUTH
    --   PROCEDURE CREATE_BRKR_IMPR_AUTH IS
    --   BEGIN
    --   IF (:PARAMETER.P_CLASS_CD = 1 AND :PARAMETER.P_USER_TYPE = 3)
    --       OR
    --      (:PARAMETER.P_USER_TYPE = 2 AND :PARAMETER.P_CLASS_CD = 23) THEN
    --   DECLARE
    --   V_ATHRZTN_SEQ_NBR NUMBER;
    --   BEGIN
    --   IF (:PARAMETER.P_CLASS_CD = 1 AND :PARAMETER.P_USER_TYPE = 3) THEN
    --   V_ATHRZTN_SEQ_NBR := GNRL.GET_CUSTOMS_SEQ(:PARAMETER.P_CURR_PORT_CD,'BRKIMPS_AUTH_SEQ');
    --   INSERT INTO BRKIMPS(
    --                   PORT_CD,
    --                   ATHRZTN_SEQ_NBR,
    --                   IMPR_NBR,
    --                   PORT_CD_BRKR,
    --                   LIC_TYPE,
    --                       LIC_NBR,
    --                       ALLOW_EXPORT,
    --                       ATHRZTN_LETR_NBR,
    --                       ATHRZTN_LETR_DT,
    --                       ATHRZTN_TYPE_CD,
    --                       ATHRZTN_STRT_DT,
    --                       ATHRZTN_END_DT,
    --                       NOTE,
    --                       ATHRZTN_USG_NBR,
    --                       ATHRZTN_LAST_USG_DT,
    --                       ATHRZTN_CNCLD_DT)
    --               VALUES(:PORT_CD,
    --                   V_ATHRZTN_SEQ_NBR,
    --                   :IMPR_NBR,
    --                   :PARAMETER.P_BRKR_PORT_CD,
    --                   :PARAMETER.P_LIC_TYPE,
    --                   :PARAMETER.P_BRKR_NBR,
    --                   1,
    --                   'تفويض الي ',
    --                   HIJDATE_DB.CUR_HIJ_DATE,
    --                   1,
    --                   NULL,
    --                   NULL,
    --                   'تفويض بريد سريع',
    --                   0,
    --                   HIJDATE_DB.CUR_HIJ_DATE,
    --                   NULL);
    --    IF NOT ACTIVITY.ADD_ACTIVITY(9, 2, 6, :IMPORTERS.Port_Cd||'!'||:IMPORTERS.Impr_Nbr) THEN
    --           RAISE FORm_Trigger_Failure;
    --    END IF;
    --   end if;
    --   STANDARD.COMMIT;
    --   STR.DISPALERT('تم أنشاء التفويض','CFG_INFORMATION');
    --   :GLOBAL.IMPR_NBR_B:=:IMPR_NBR;
    --   :GLOBAL.IMPR_NAME_B:=:ARBC_IMPR_NAME;
    --   :GLOBAL.BRKR_ATHRZTN_NBR_B:=V_ATHRZTN_SEQ_NBR;
    --   END;
    --   END IF;
    --   END;
    -- <<<
    PROCEDURE create_brkr_impr_auth (p_rec IN T_RECORD, p_ctx IN T_CONTEXT)
    IS
        v_athrztn_seq_nbr NUMBER;
    BEGIN
        IF (p_ctx.class_cd = 1 AND p_ctx.user_type = 3)
           OR (p_ctx.user_type = 2 AND p_ctx.class_cd = 23) THEN
            IF (p_ctx.class_cd = 1 AND p_ctx.user_type = 3) THEN
                v_athrztn_seq_nbr := gnrl.get_customs_seq(p_ctx.curr_port_cd, 'BRKIMPS_AUTH_SEQ');
                INSERT INTO brkimps (
                    port_cd, athrztn_seq_nbr, impr_nbr, port_cd_brkr, lic_type, lic_nbr, allow_export,
                    athrztn_letr_nbr, athrztn_letr_dt, athrztn_type_cd, athrztn_strt_dt, athrztn_end_dt,
                    note, athrztn_usg_nbr, athrztn_last_usg_dt, athrztn_cncld_dt)
                VALUES (
                    p_rec.port_cd, v_athrztn_seq_nbr, p_rec.impr_nbr, p_ctx.brkr_port_cd, p_ctx.lic_type,
                    p_ctx.brkr_nbr, 1, 'تفويض الي ', hijdate_db.cur_hij_date, 1, NULL, NULL,
                    'تفويض بريد سريع', 0, hijdate_db.cur_hij_date, NULL);
                add_activity(6, p_rec, p_ctx);
            END IF;
            -- STANDARD.COMMIT;   -- removed, see header
            info('تم أنشاء التفويض');
            SET_GLOBAL('IMPR_NBR_B', p_rec.impr_nbr);
            SET_GLOBAL('IMPR_NAME_B', p_rec.arbc_impr_name);
            SET_GLOBAL('BRKR_ATHRZTN_NBR_B', v_athrztn_seq_nbr);
        END IF;
    END create_brkr_impr_auth;

    -- Source: PU UPDATE_IMPORTER, part 1 = text of the CONFIRM alert (NULL when no alert)
    -- HIGH: Forms first runs FORMS_DDL('COMMIT') (saves pending changes). In APEX the page must
    -- be saved (SAVE) before this function is offered - see extraction report §5.
    FUNCTION update_importer_msg (p_rec IN T_RECORD) RETURN VARCHAR2
    IS
        v_msg VARCHAR2(500);
    BEGIN
        IF p_rec.port_cd IS NOT NULL AND p_rec.impr_nbr IS NOT NULL THEN
            IF p_rec.bus_id_type_cd = 2 THEN
                v_msg := 'السجل الرئيسي =  ' || p_rec.bus_id || 'السجل الفرعي = ' || p_rec.bus_id_brnch
                         || ' تأكيد التحديث؟';
            END IF;
            IF p_rec.impr_type_cd = 4 AND p_rec.bus_id_type_cd = 5 THEN
                v_msg := 'رقم مدني =  ' || p_rec.bus_id || ' تأكيد التحديث؟';
            END IF;
            IF p_rec.impr_type_cd = 4 AND p_rec.bus_id_type_cd = 3 THEN
                v_msg := ' رقم الاقامة =  ' || p_rec.bus_id || ' تأكيد التحديث؟';
            END IF;
        END IF;
        RETURN v_msg;
    END update_importer_msg;

    -- Source: PU UPDATE_IMPORTER, part 2 = after ALERT_BUTTON1
    --@ORIG PU UPDATE_IMPORTER
    -- >>> Original Forms code: PU UPDATE_IMPORTER
    --   PROCEDURE update_importer
    --   IS
    --      ret         NUMBER;
    --      v_chk_upd   NUMBER;
    --      v_msg       VARCHAR2 (500);
    --      msg_lvl     VARCHAR2 (5);
    --      MSG_CD      NUMBER;
    --   BEGIN
    --      BEGIN
    --         msg_lvl := :SYSTEM.message_level;
    --         :SYSTEM.message_level := '25';
    --         FORMS_DDL ('COMMIT');
    --         :SYSTEM.message_level := msg_lvl;
    --      EXCEPTION
    --         WHEN OTHERS
    --         THEN
    --            NULL;
    --      END;
    --      IF :importers.port_cd IS NOT NULL AND :importers.impr_nbr IS NOT NULL
    --      THEN
    --         IF :IMPORTERS.BUS_ID_TYPE_CD = 2 THEN
    --         V_MSG :=
    --               'السجل الرئيسي =  '
    --            || :IMPORTERS.BUS_ID
    --            || 'السجل الفرعي = '
    --            || :IMPORTERS.BUS_ID_BRNCH
    --            || ' تأكيد التحديث؟';
    --       END IF ;
    --       IF :IMPORTERS.IMPR_TYPE_CD = 4 AND :IMPORTERS.BUS_ID_TYPE_CD = 5 THEN
    --         V_MSG :=
    --               'رقم مدني =  '
    --            || :IMPORTERS.BUS_ID
    --            || ' تأكيد التحديث؟';
    --       END IF ;
    --        IF :IMPORTERS.IMPR_TYPE_CD = 4 AND :IMPORTERS.BUS_ID_TYPE_CD = 3 THEN
    --         V_MSG :=
    --               ' رقم الاقامة =  '
    --            || :IMPORTERS.BUS_ID
    --            || ' تأكيد التحديث؟';
    --        END IF ;
    --         ret := str.dispalert (v_msg, 'CONFIRM');
    --         IF ret = alert_button1
    --         THEN
    --            msg_lvl := :SYSTEM.message_level;
    --            :SYSTEM.message_level := '25';
    --            BEGIN
    --               LIB_USR.impr_utilities.UPDATE_IMPORTERS_NAMES (
    --                  :importers.port_cd,
    --                  :importers.impr_nbr,
    --                  MSG_CD,
    --                  v_msg);
    --               ret := str.dispalert (v_msg, 'INFORMATION');
    --            EXCEPTION
    --               WHEN OTHERS
    --               THEN
    --                  NULL;
    --            END;
    --         END IF;
    --      END IF;
    --   END;
    -- <<<
    PROCEDURE update_importer (p_rec IN T_RECORD)
    IS
        msg_cd NUMBER;
        v_msg  VARCHAR2(500);
    BEGIN
        IF p_rec.port_cd IS NOT NULL AND p_rec.impr_nbr IS NOT NULL THEN
            BEGIN
                lib_usr.impr_utilities.update_importers_names(p_rec.port_cd, p_rec.impr_nbr, msg_cd, v_msg);
                info(v_msg);
            EXCEPTION
                WHEN OTHERS THEN
                    NULL;
            END;
        END IF;
    END update_importer;

    -- Source: PU LOV_UPDATE_MOBLIE, part before CALL_FORM: P_CENTRAL_MOBILE parameter
    FUNCTION central_mobile (p_rec IN T_RECORD, p_ctx IN T_CONTEXT) RETURN NUMBER
    IS
        v_central_mobile NUMBER;
    BEGIN
        SELECT mobile_no
          INTO v_central_mobile
          FROM importers_central
         WHERE port_cd  = p_ctx.curr_port_cd
           AND impr_nbr = p_rec.impr_nbr;
        RETURN v_central_mobile;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END central_mobile;

    -- Source: PU LOV_UPDATE_MOBLIE, part after LOV_UPDATE_IMPR_MOBILE returned :GLOBAL.MOBILE_NO
    -- HIGH: STANDARD.COMMIT removed.
    --@ORIG PU LOV_UPDATE_MOBLIE
    -- >>> Original Forms code: PU LOV_UPDATE_MOBLIE
    --   PROCEDURE LOV_UPDATE_MOBLIE IS
    --   V_CNT_RASEL      NUMBER;
    --   V_CNT_INFO_RASEL NUMBER;
    --   v_filler1      VARCHAR2(200);
    --    pl_id   ParamList;
    --      pl_name VARCHAR2(100) := 'LOV_CONFIRM_TAR';
    --      RET NUMBER;
    --      V_RESULT NUMBER;
    --      V_CENTRAL_MOBILE NUMBER;
    --     P_RESULT_CD NUMBER;
    --     P_MSG  VARCHAR2(50);
    --   BEGIN
    --          pl_id := Get_Parameter_List(pl_name);
    --     IF Id_Null(pl_id) THEN
    --        pl_id := Create_Parameter_List(pl_name);
    --        IF Id_Null(pl_id) THEN
    --          ret := Str.Dispalert('Error creating parameter list '||pl_name, 'SYSTEM_ERROR');
    --          RAISE Form_Trigger_Failure;
    --        END IF;
    --         BEGIN
    --             SELECT MOBILE_NO
    --               INTO V_CENTRAL_MOBILE
    --                FROM IMPORTERS_CENTRAL
    --                 WHERE PORT_CD    = :PARAMETER.P_CURR_PORT_CD AND IMPR_NBR = :IMPORTERS.IMPR_NBR ;
    --         EXCEPTION WHEN NO_DATA_FOUND THEN
    --              V_CENTRAL_MOBILE := NULL;
    --            END;
    --      Add_Parameter(pl_id, 'WINDOW_WIDTH', TEXT_PARAMETER, 5);
    --      Add_Parameter(pl_id, 'WINDOW_TITLE', TEXT_PARAMETER, 'تعديل رقم الجوال');
    --      Add_Parameter(pl_id, 'P_CENTRAL_MOBILE', TEXT_PARAMETER, V_CENTRAL_MOBILE);
    --             CALL_FORM('LOV_UPDATE_IMPR_MOBILE.fmx',
    --                     no_hide,
    --                 no_replace,
    --                 no_query_only,
    --                 pl_id);
    --                     Destroy_Parameter_List(pl_id);
    --       ELSE
    --           ret := Str.DispAlert('Parameter list '||pl_name||' already EXISTS!','INFORMATION');
    --           RAISE Form_Trigger_Failure;
    --       END IF;
    --      IF    :GLOBAL.MOBILE_NO  IS NOT NULL THEN
    --                impr.CHK_MOBILE_FORMAT (:GLOBAL.MOBILE_NO  , V_RESULT );
    --               IF V_RESULT = 0 THEN
    --                      STR.DISPALERT('رقم الجوال المدخل غير صحيح' ,'ERROR');
    --                  RAISE Form_Trigger_Failure;
    --              END IF ;
    --        IMPR_UTILITIES.UPDATE_IMPR_MOBILE_NO (:IMPR_NBR , :GLOBAL.MOBILE_NO ,P_RESULT_CD , P_MSG ) ;
    --           IF P_RESULT_CD = 1 THEN
    --                    STANDARD.COMMIT;
    --           STR.DISPALERT('تمت العملية بنجاح','INFORMATION');
    --           END IF;
    --     END IF;
    --   END;
    -- <<<
    PROCEDURE lov_update_moblie (p_rec IN T_RECORD)
    IS
        v_result    NUMBER;
        p_result_cd NUMBER;
        p_msg       VARCHAR2(50);
    BEGIN
        IF GET_GLOBAL('MOBILE_NO') IS NOT NULL THEN
            impr.chk_mobile_format(GET_GLOBAL('MOBILE_NO'), v_result);
            IF v_result = 0 THEN
                FORM_TRIGGER_FAILURE('رقم الجوال المدخل غير صحيح');
            END IF;
            impr_utilities.update_impr_mobile_no(p_rec.impr_nbr, GET_GLOBAL('MOBILE_NO'), p_result_cd, p_msg);
            IF p_result_cd = 1 THEN
                -- STANDARD.COMMIT;   -- removed, see header
                info('تمت العملية بنجاح');
            END IF;
        END IF;
    END lov_update_moblie;

    -- Source: PU EXEC_FUNS (server part of each function code; dialogs/CALL_FORM are UI)
    --@ORIG PU EXEC_FUNS
    -- >>> Original Forms code: PU EXEC_FUNS
    --   PROCEDURE EXEC_FUNS(CD VARCHAR2) IS
    --       PL_ID PARAMLIST;
    --     RET NUMBER;
    --   pl_name      VARCHAR2(100) := 'TMPLT_MOD_CALL';
    --      P_Result NUMBER;
    --      P_Result_Msg VARCHAR2(100);
    --   BEGIN
    --   IF CD IN ('IMPR1110F4') THEN
    --     :PARAMETER.CODE :='IMPR1110F4';
    --   END IF;
    --   IF CD IN ('IMPR1115_SCR') THEN
    --       pl_id := Get_Parameter_List(pl_name);
    --           IF NOT Id_Null(pl_id) THEN
    --         ADD_PARAMETER(PL_ID,'P_IMPR_NO',TEXT_PARAMETER,:IMPORTERS.IMPR_NBR);
    --           END IF;
    --   END IF;
    --   IF CD IN( 'IMPR1110F2','IMPR1110F1','IMPR1110F3','IMPR1110F5') THEN
    --     IF NOT ID_NULL(FIND_FORM('SUPPORT_ENTRY')) THEN
    --            CLOSE_FORM('SUPPORT_ENTRY');
    --     END IF;
    --     PL_ID := GET_PARAMETER_LIST('SUPPORT_ENTRY');
    --     IF ID_NULL(PL_ID) THEN
    --           PL_ID := CREATE_PARAMETER_LIST('SUPPORT_ENTRY');
    --           IF ID_NULL(PL_ID) THEN
    --              STR.DISPALERT('Error creating parameter list SUPPORT_ENTRY','SYSTEM_ERROR');
    --              RAISE FORM_TRIGGER_FAILURE;
    --           END IF;
    --           ADD_PARAMETER(PL_ID,'WINDOW_X_POS',TEXT_PARAMETER,1.5);
    --         ADD_PARAMETER(PL_ID,'WINDOW_Y_POS',TEXT_PARAMETER,2);
    --         ADD_PARAMETER(PL_ID,'P_MODE',TEXT_PARAMETER,0);
    --         ADD_PARAMETER(PL_ID,'P_CURR_PORT_CD',TEXT_PARAMETER,:IMPORTERS.PORT_CD);
    --         CALL_FORM('SUPPORT_ENTRY.FMX',NO_HIDE,NO_REPLACE,NO_QUERY_ONLY,PL_ID);
    --         DESTROY_PARAMETER_LIST(PL_ID);
    --         IF :GLOBAL.LETTER_NBR IS NOT NULL THEN
    --              :PARAMETER.CODE :=CD;
    --           :PARAMETER.LETTER_NBR :=:GLOBAL.LETTER_NBR;
    --           GO_BLOCK('IMPORTERS');
    --          END IF;
    --      END IF;
    --   END IF;
    --   IF CD IN ('IMPR_CAR_AGENT') THEN
    --       :PARAMETER.CODE := 'IMPR1110SF6';
    --   END IF;
    --   IF CD IN ('IMPR_MCI_SERVICE') AND (:GLOBAL.ALLOW_MCI = 1 OR :GLOBAL.allow_moi
    --   =1)THEN
    --       Update_Importer;
    --   END IF;
    --   IF CD IN ('CREATE_BRKR_IMPR_AUTH') THEN
    --       CREATE_BRKR_IMPR_AUTH;
    --   END IF;
    --   IF CD IN ('IMPR1115_GZT') THEN
    --   BEGIN
    --   Lib_Usr.Web_Services_Gazt.Pr_Import_Impr_Certificate(:IMPORTERS.Bus_Id, :IMPORTERS.Bus_Id_Brnch, P_Result, P_Result_Msg);
    --    IF P_Result = 3 THEN
    --              str.dispalert('تم التحديث بنجاح','WARNING');
    --    ELSIF P_Result = '00' THEN
    --              str.dispalert('رقم استدلالي غير صحيح','WARNING');
    --    ELSIF P_Result = '02' THEN
    --              str.dispalert('رقم شهادة غير صحيح','WARNING');
    --    ELSIF P_Result = '04' THEN
    --              str.dispalert('لا يوجد بيانات','WARNING');
    --    END IF;
    --       EXCEPTION
    --               WHEN OTHERS
    --               THEN
    --                  NULL;
    --   END;
    --   END IF;
    --   IF CD IN ('IMPR1110_MOB') THEN
    --        IF  :IMPORTERS.IMPR_NBR > 3000000 THEN
    --        LOV_UPDATE_MOBLIE ;
    --        ELSE
    --            STR.DISPALERT('رقم المستورد غير محدث ,, الرجاء مراجعة الدعم', 'ERROR');
    --             RAISE FORM_TRIGGER_FAILURE;
    --        END IF;
    --   END IF;
    --   END;
    -- <<<
    PROCEDURE exec_funs (p_rec IN OUT NOCOPY T_RECORD, p_ctx IN OUT NOCOPY T_CONTEXT, cd IN VARCHAR2)
    IS
        p_result     NUMBER;
        p_result_msg VARCHAR2(100);
    BEGIN
        IF cd IN ('IMPR1110F4') THEN
            p_ctx.code := 'IMPR1110F4';
        END IF;
        -- 'IMPR1115_SCR': APEX-DA -> open page IMPR1115 with P_IMPR_NO = IMPR_NBR
        IF cd IN ('IMPR1110F2', 'IMPR1110F1', 'IMPR1110F3', 'IMPR1110F5') THEN
            -- APEX-DA: modal dialog SUPPORT_ENTRY (P_MODE=0, P_CURR_PORT_CD=PORT_CD) is opened by
            -- the page first; this part runs after the dialog closed and set :GLOBAL.LETTER_NBR.
            IF GET_GLOBAL('LETTER_NBR') IS NOT NULL THEN
                p_ctx.code       := cd;
                p_ctx.letter_nbr := GET_GLOBAL('LETTER_NBR');
            END IF;
        END IF;
        IF cd IN ('IMPR_CAR_AGENT') THEN
            p_ctx.code := 'IMPR1110SF6';
        END IF;
        -- 'IMPR_MCI_SERVICE' (ALLOW_MCI = 1 OR ALLOW_MOI = 1): Confirm(update_importer_msg) ->
        -- update_importer. Interactive -> page process, see extraction report §5.
        IF cd IN ('CREATE_BRKR_IMPR_AUTH') THEN
            create_brkr_impr_auth(p_rec, p_ctx);
        END IF;
        IF cd IN ('IMPR1115_GZT') THEN
            BEGIN
                lib_usr.web_services_gazt.pr_import_impr_certificate(p_rec.bus_id, p_rec.bus_id_brnch,
                                                                    p_result, p_result_msg);
                IF p_result = 3 THEN
                    info('تم التحديث بنجاح');
                ELSIF p_result = '00' THEN
                    info('رقم استدلالي غير صحيح');
                ELSIF p_result = '02' THEN
                    info('رقم شهادة غير صحيح');
                ELSIF p_result = '04' THEN
                    info('لا يوجد بيانات');
                END IF;
            EXCEPTION
                WHEN OTHERS THEN
                    NULL;
            END;
        END IF;
        IF cd IN ('IMPR1110_MOB') THEN
            IF p_rec.impr_nbr > 3000000 THEN
                NULL;   -- APEX-DA: open dialog LOV_UPDATE_IMPR_MOBILE, then lov_update_moblie
            ELSE
                FORM_TRIGGER_FAILURE('رقم المستورد غير محدث ,, الرجاء مراجعة الدعم');
            END IF;
        END IF;
    END exec_funs;


    -- =========================================================================
    -- 4 READ-ONLY / REQUIRED / VISIBLE RULES (work/step02/read_only_rules.md)
    -- =========================================================================
    -- Section: PRIVATE RULE HELPERS
    -- Group 1 of read_only_rules.md: a saved record (IMPR_NBR set) is locked, except in the
    -- function modes listed in p_unlocked_by (comma list of :PARAMETER.CODE values)
    FUNCTION PRIVATE_SAVED_RECORD_LOCKED (p_impr_nbr    IN NUMBER,
                                          p_code        IN VARCHAR2,
                                          p_unlocked_by IN VARCHAR2) RETURN BOOLEAN
    IS
    BEGIN
        RETURN p_impr_nbr IS NOT NULL
               AND (p_code IS NULL OR INSTR(',' || p_unlocked_by || ',', ',' || p_code || ',') = 0);
    END PRIVATE_SAVED_RECORD_LOCKED;

    -- Section: PRIVATE RULE HELPERS
    -- Group 2 of read_only_rules.md: importer type table (IMPR_TYPE_CD WHEN-VALIDATE-ITEM / POST-QUERY)
    FUNCTION PRIVATE_IMPORTER_TYPE_LOCKED (p_item           IN VARCHAR2,
                                           p_impr_type_cd   IN NUMBER,
                                           p_bus_id_type_cd IN NUMBER) RETURN BOOLEAN
    IS
        v_bus_id_type NUMBER := NVL(p_bus_id_type_cd, 6);
    BEGIN
        CASE
            WHEN p_impr_type_cd IN (1, 5, 8) THEN
                RETURN p_item = 'CTRY_CD';
            WHEN p_impr_type_cd = 2 THEN
                RETURN p_item IN ('CTRY_CD', 'CITY_CODE_OF_ID', 'BUS_ID_BRNCH');
            WHEN p_impr_type_cd = 4 THEN
                RETURN p_item IN ('CITY_CODE_OF_ID', 'BUS_ID_BRNCH')
                       OR (p_item = 'CTRY_CD' AND p_bus_id_type_cd IN (3, 5));
            WHEN p_impr_type_cd IN (7, 10) THEN
                RETURN p_item IN ('CITY_CODE_OF_ID', 'BUS_ID_BRNCH');
            WHEN p_impr_type_cd = 9 AND v_bus_id_type = 6 THEN
                RETURN p_item IN ('CTRY_CD', 'CITY_CODE_OF_ID', 'BUS_ID_BRNCH', 'BUS_ID');
            WHEN p_impr_type_cd = 9 THEN
                RETURN p_item = 'BUS_ID_BRNCH';
            WHEN p_impr_type_cd = 11 THEN
                RETURN p_item IN ('CTRY_CD', 'BUS_ID_BRNCH');
            WHEN p_impr_type_cd = 12 THEN
                RETURN p_item = 'CITY_CODE_OF_ID';
            -- 16, 17, 18, 20: WHEN-VALIDATE-ITEM only (POST-QUERY does not list them; difference kept)
            WHEN p_impr_type_cd IN (13, 14, 16, 17, 18, 20) THEN
                RETURN p_item IN ('CTRY_CD', 'CITY_CODE_OF_ID', 'BUS_ID_BRNCH', 'BUS_ID');
            ELSE
                RETURN FALSE;
        END CASE;
    END PRIVATE_IMPORTER_TYPE_LOCKED;

    -- Section: PRIVATE RULE HELPERS
    -- Group 3 of read_only_rules.md: the commercial register has exactly one row for the importer
    -- (only for BUS_ID_TYPE_CD = 2 and IMPR_TYPE_CD <> 12; same query as COMMERCIAL_REGISTER_NAME)
    FUNCTION PRIVATE_REGISTER_MATCHES (p_impr_type_cd      IN NUMBER,
                                       p_bus_id_type_cd    IN NUMBER,
                                       p_bus_id            IN VARCHAR2,
                                       p_bus_id_brnch      IN VARCHAR2,
                                       p_comm_rgstrtn_type IN NUMBER) RETURN BOOLEAN
    IS
        v_cnt NUMBER;
    BEGIN
        IF NOT (p_bus_id_type_cd = 2 AND NVL(p_impr_type_cd, 0) <> 12) OR p_bus_id IS NULL THEN
            RETURN FALSE;
        END IF;
        IF p_comm_rgstrtn_type = 2 THEN
            SELECT COUNT(bus_id) INTO v_cnt
              FROM comm_impr_rgstr
             WHERE bus_id = p_bus_id AND brnch_bus_id = p_bus_id_brnch;
        ELSE
            SELECT COUNT(bus_id) INTO v_cnt
              FROM comm_impr_rgstr
             WHERE bus_id = p_bus_id AND brnchreg = 0;
        END IF;
        RETURN v_cnt = 1;
    END PRIVATE_REGISTER_MATCHES;

    -- Section: ITEM IMPR_TYPE_CD
    -- Source: WNRI (saved-record lock, unlocked by IMPR1110F3), WHEN-CREATE-RECORD (PRSNL_IMPR = 1)
    -- APEX  : Read Only condition of P1110_IMPR_TYPE_CD (PL/SQL expression)
    FUNCTION IMPR_TYPE_CD_IS_READ_ONLY (P_IMPR_NBR     IN NUMBER,
                                        P_P_CODE       IN VARCHAR2,
                                        P_P_PRSNL_IMPR IN NUMBER) RETURN BOOLEAN
    IS
    BEGIN
        RETURN PRIVATE_SAVED_RECORD_LOCKED(P_IMPR_NBR, P_P_CODE, 'IMPR1110F3')
               OR (P_IMPR_NBR IS NULL AND P_P_PRSNL_IMPR = 1);
    END IMPR_TYPE_CD_IS_READ_ONLY;

    -- Section: ITEM BUS_ID_EXPRD_DT
    -- Source: WNRI (lock, unlocked by IMPR1110F4), BUS_ID / BUS_ID_BRNCH WHEN-VALIDATE-ITEM (register),
    --         PRE-INSERT (re-enabled while empty: the item is required)
    FUNCTION BUS_ID_EXPRD_DT_IS_READ_ONLY (P_IMPR_NBR          IN NUMBER,
                                           P_P_CODE            IN VARCHAR2,
                                           P_IMPR_TYPE_CD      IN NUMBER,
                                           P_BUS_ID_TYPE_CD    IN NUMBER,
                                           P_BUS_ID            IN VARCHAR2,
                                           P_BUS_ID_BRNCH      IN VARCHAR2,
                                           P_COMM_RGSTRTN_TYPE IN NUMBER,
                                           P_BUS_ID_EXPRD_DT   IN VARCHAR2) RETURN BOOLEAN
    IS
    BEGIN
        IF P_P_CODE = 'IMPR1110F4' THEN
            RETURN FALSE;
        END IF;
        RETURN PRIVATE_SAVED_RECORD_LOCKED(P_IMPR_NBR, P_P_CODE, 'IMPR1110F4')
               OR (P_BUS_ID_EXPRD_DT IS NOT NULL
                   AND PRIVATE_REGISTER_MATCHES(P_IMPR_TYPE_CD, P_BUS_ID_TYPE_CD, P_BUS_ID,
                                                P_BUS_ID_BRNCH, P_COMM_RGSTRTN_TYPE));
    END BUS_ID_EXPRD_DT_IS_READ_ONLY;

    -- Section: ITEM BUS_ID_EXPRD_DT
    -- Source: PRE-INSERT / PRE-UPDATE (required for BUS_ID_TYPE_CD = 2 and IMPR_TYPE_CD IN 1,3,5,6,8,12)
    FUNCTION BUS_ID_EXPRD_DT_IS_REQUIRED (P_IMPR_TYPE_CD   IN NUMBER,
                                          P_BUS_ID_TYPE_CD IN NUMBER) RETURN BOOLEAN
    IS
    BEGIN
        RETURN P_BUS_ID_TYPE_CD = 2 AND P_IMPR_TYPE_CD IN (1, 3, 5, 6, 8, 12);
    END BUS_ID_EXPRD_DT_IS_REQUIRED;

    -- Section: ITEM BUS_ID_TYPE_CD
    -- Source: WNRI (saved record: never unlocked)
    FUNCTION BUS_ID_TYPE_CD_IS_READ_ONLY (P_IMPR_NBR IN NUMBER) RETURN BOOLEAN
    IS
    BEGIN
        RETURN P_IMPR_NBR IS NOT NULL;
    END BUS_ID_TYPE_CD_IS_READ_ONLY;

    -- Section: ITEM COMM_RGSTRTN_TYPE
    -- Source: WNFI / WNRI (read-only by default), IMPR_TYPE_CD WHEN-VALIDATE-ITEM (editable for
    --         BUS_ID_TYPE_CD = 2 and IMPR_TYPE_CD <> 12), WNRI (saved record, unlocked by IMPR1110F2)
    FUNCTION COMM_RGSTRTN_TYPE_IS_READ_ONLY (P_IMPR_NBR       IN NUMBER,
                                             P_P_CODE         IN VARCHAR2,
                                             P_IMPR_TYPE_CD   IN NUMBER,
                                             P_BUS_ID_TYPE_CD IN NUMBER) RETURN BOOLEAN
    IS
    BEGIN
        RETURN PRIVATE_SAVED_RECORD_LOCKED(P_IMPR_NBR, P_P_CODE, 'IMPR1110F2')
               OR NOT (P_BUS_ID_TYPE_CD = 2 AND NVL(P_IMPR_TYPE_CD, 0) <> 12);
    END COMM_RGSTRTN_TYPE_IS_READ_ONLY;

    -- Section: ITEM COMM_RGSTRTN_TYPE
    -- Source: IMPR_TYPE_CD WHEN-VALIDATE-ITEM (REQUIRED TRUE), PRE-INSERT / PRE-UPDATE error 9-240
    FUNCTION COMM_RGSTRTN_TYPE_IS_REQUIRED (P_IMPR_TYPE_CD   IN NUMBER,
                                            P_BUS_ID_TYPE_CD IN NUMBER) RETURN BOOLEAN
    IS
    BEGIN
        RETURN P_BUS_ID_TYPE_CD = 2 AND NVL(P_IMPR_TYPE_CD, 0) <> 12;
    END COMM_RGSTRTN_TYPE_IS_REQUIRED;

    -- Section: ITEM CITY_CODE_OF_ID
    -- Source: importer type table (group 2), WNRI (lock, unlocked by IMPR1110F2).
    --         WHEN-CREATE-RECORD with PRSNL_IMPR = 1 sets IMPR_TYPE_CD = 4 -> covered by the type table.
    FUNCTION CITY_CODE_OF_ID_IS_READ_ONLY (P_IMPR_NBR       IN NUMBER,
                                           P_P_CODE         IN VARCHAR2,
                                           P_IMPR_TYPE_CD   IN NUMBER,
                                           P_BUS_ID_TYPE_CD IN NUMBER) RETURN BOOLEAN
    IS
    BEGIN
        RETURN PRIVATE_SAVED_RECORD_LOCKED(P_IMPR_NBR, P_P_CODE, 'IMPR1110F2')
               OR PRIVATE_IMPORTER_TYPE_LOCKED('CITY_CODE_OF_ID', P_IMPR_TYPE_CD, P_BUS_ID_TYPE_CD);
    END CITY_CODE_OF_ID_IS_READ_ONLY;

    -- Section: ITEM CITY_CODE_OF_ID
    -- Source: IMPR_TYPE_CD POST-CHANGE (REQUIRED TRUE for IMPR_TYPE_CD IN 1,3,5,6,8,19)
    FUNCTION CITY_CODE_OF_ID_IS_REQUIRED (P_IMPR_TYPE_CD IN NUMBER) RETURN BOOLEAN
    IS
    BEGIN
        RETURN P_IMPR_TYPE_CD IN (1, 3, 5, 6, 8, 19);
    END CITY_CODE_OF_ID_IS_REQUIRED;

    -- Section: ITEM BUS_ID
    -- Source: importer type table (group 2), WNRI (lock, unlocked by IMPR1110F2)
    FUNCTION BUS_ID_IS_READ_ONLY (P_IMPR_NBR       IN NUMBER,
                                  P_P_CODE         IN VARCHAR2,
                                  P_IMPR_TYPE_CD   IN NUMBER,
                                  P_BUS_ID_TYPE_CD IN NUMBER) RETURN BOOLEAN
    IS
    BEGIN
        RETURN PRIVATE_SAVED_RECORD_LOCKED(P_IMPR_NBR, P_P_CODE, 'IMPR1110F2')
               OR PRIVATE_IMPORTER_TYPE_LOCKED('BUS_ID', P_IMPR_TYPE_CD, P_BUS_ID_TYPE_CD);
    END BUS_ID_IS_READ_ONLY;

    -- Section: ITEM BRNH_CITY_CD
    -- Source: COMM_RGSTRTN_TYPE WHEN-LIST-CHANGED (1 = read-only, 2 = editable), WNRI (lock, IMPR1110F2)
    -- TODO-VERIFY: value NULL (no registration type) is treated as editable
    FUNCTION BRNH_CITY_CD_IS_READ_ONLY (P_IMPR_NBR          IN NUMBER,
                                        P_P_CODE            IN VARCHAR2,
                                        P_COMM_RGSTRTN_TYPE IN NUMBER) RETURN BOOLEAN
    IS
    BEGIN
        RETURN PRIVATE_SAVED_RECORD_LOCKED(P_IMPR_NBR, P_P_CODE, 'IMPR1110F2')
               OR P_COMM_RGSTRTN_TYPE = 1;
    END BRNH_CITY_CD_IS_READ_ONLY;

    -- Section: ITEM BRNH_CITY_CD
    -- Source: COMM_RGSTRTN_TYPE WHEN-LIST-CHANGED (REQUIRED for type 2)
    FUNCTION BRNH_CITY_CD_IS_REQUIRED (P_COMM_RGSTRTN_TYPE IN NUMBER) RETURN BOOLEAN
    IS
    BEGIN
        RETURN P_COMM_RGSTRTN_TYPE = 2;
    END BRNH_CITY_CD_IS_REQUIRED;

    -- Section: ITEM BUS_ID_BRNCH
    -- Source: importer type table (group 2), COMM_RGSTRTN_TYPE WHEN-LIST-CHANGED, WNRI (lock, IMPR1110F2)
    FUNCTION BUS_ID_BRNCH_IS_READ_ONLY (P_IMPR_NBR          IN NUMBER,
                                        P_P_CODE            IN VARCHAR2,
                                        P_IMPR_TYPE_CD      IN NUMBER,
                                        P_BUS_ID_TYPE_CD    IN NUMBER,
                                        P_COMM_RGSTRTN_TYPE IN NUMBER) RETURN BOOLEAN
    IS
    BEGIN
        RETURN PRIVATE_SAVED_RECORD_LOCKED(P_IMPR_NBR, P_P_CODE, 'IMPR1110F2')
               OR PRIVATE_IMPORTER_TYPE_LOCKED('BUS_ID_BRNCH', P_IMPR_TYPE_CD, P_BUS_ID_TYPE_CD)
               OR P_COMM_RGSTRTN_TYPE = 1;
    END BUS_ID_BRNCH_IS_READ_ONLY;

    -- Section: ITEM BUS_ID_BRNCH
    -- Source: COMM_RGSTRTN_TYPE WHEN-LIST-CHANGED / BRNH_CITY_CD WHEN-NEW-ITEM-INSTANCE (REQUIRED for
    --         type 2 unless BUS_ID or CITY_CODE_OF_ID is empty)
    FUNCTION BUS_ID_BRNCH_IS_REQUIRED (P_COMM_RGSTRTN_TYPE IN NUMBER,
                                       P_BUS_ID            IN VARCHAR2,
                                       P_CITY_CODE_OF_ID   IN NUMBER) RETURN BOOLEAN
    IS
    BEGIN
        RETURN P_COMM_RGSTRTN_TYPE = 2
               AND P_BUS_ID IS NOT NULL AND P_CITY_CODE_OF_ID IS NOT NULL;
    END BUS_ID_BRNCH_IS_REQUIRED;

    -- Section: ITEM CTRY_CD
    -- Source: importer type table (group 2)
    FUNCTION CTRY_CD_IS_READ_ONLY (P_IMPR_TYPE_CD   IN NUMBER,
                                   P_BUS_ID_TYPE_CD IN NUMBER) RETURN BOOLEAN
    IS
    BEGIN
        RETURN PRIVATE_IMPORTER_TYPE_LOCKED('CTRY_CD', P_IMPR_TYPE_CD, P_BUS_ID_TYPE_CD);
    END CTRY_CD_IS_READ_ONLY;

    -- Section: ITEM IMPR_EXPR_TYPE
    -- Source: WNRI (saved record: never unlocked), WHEN-CREATE-RECORD / BROKER_INT (brokers: class 1, type 3)
    FUNCTION IMPR_EXPR_TYPE_IS_READ_ONLY (P_IMPR_NBR IN NUMBER,
                                          P_CLASS_CD     IN NUMBER,
                                          V_USR_TYPE     IN NUMBER) RETURN BOOLEAN
    IS
    BEGIN
        RETURN P_IMPR_NBR IS NOT NULL OR (P_CLASS_CD = 1 AND V_USR_TYPE = 3);
    END IMPR_EXPR_TYPE_IS_READ_ONLY;

    -- Section: ITEM ARBC_IMPR_NAME
    -- Source: WNRI (lock, unlocked by IMPR1110F1 / IMPR1110F5), BUS_ID / BUS_ID_BRNCH WHEN-VALIDATE-ITEM
    --         (one register row -> the name comes from the register)
    FUNCTION ARBC_IMPR_NAME_IS_READ_ONLY (P_IMPR_NBR          IN NUMBER,
                                          P_P_CODE            IN VARCHAR2,
                                          P_IMPR_TYPE_CD      IN NUMBER,
                                          P_BUS_ID_TYPE_CD    IN NUMBER,
                                          P_BUS_ID            IN VARCHAR2,
                                          P_BUS_ID_BRNCH      IN VARCHAR2,
                                          P_COMM_RGSTRTN_TYPE IN NUMBER) RETURN BOOLEAN
    IS
    BEGIN
        IF P_P_CODE IN ('IMPR1110F1', 'IMPR1110F5') THEN
            RETURN FALSE;
        END IF;
        RETURN P_IMPR_NBR IS NOT NULL
               OR PRIVATE_REGISTER_MATCHES(P_IMPR_TYPE_CD, P_BUS_ID_TYPE_CD, P_BUS_ID,
                                           P_BUS_ID_BRNCH, P_COMM_RGSTRTN_TYPE);
    END ARBC_IMPR_NAME_IS_READ_ONLY;

    -- Section: ITEM IMPR_TEL_NBR
    -- Source: BUS_ID / BUS_ID_BRNCH WHEN-VALIDATE-ITEM (group 3: IMPR_POB_NBR, IMPR_ZIP_CD, IMPR_TEL_NBR,
    --         IMPR_FAX_NBR, IMPR_TELEX_NBR come from the register). Pass the item value in I_VALUE for
    --         IMPR_TEL_NBR (PRE-INSERT re-enables it while empty); the other items keep the default.
    FUNCTION REGISTER_ITEMS_IS_READ_ONLY (P_IMPR_TYPE_CD      IN NUMBER,
                                          P_BUS_ID_TYPE_CD    IN NUMBER,
                                          P_BUS_ID            IN VARCHAR2,
                                          P_BUS_ID_BRNCH      IN VARCHAR2,
                                          P_COMM_RGSTRTN_TYPE IN NUMBER,
                                          ITEM_VALUE                   IN VARCHAR2 DEFAULT 'X') RETURN BOOLEAN
    IS
    BEGIN
        RETURN ITEM_VALUE IS NOT NULL
               AND PRIVATE_REGISTER_MATCHES(P_IMPR_TYPE_CD, P_BUS_ID_TYPE_CD, P_BUS_ID,
                                            P_BUS_ID_BRNCH, P_COMM_RGSTRTN_TYPE);
    END REGISTER_ITEMS_IS_READ_ONLY;

    -- Section: ITEM ACTIVITY
    -- Source: BUS_ID WHEN-VALIDATE-ITEM (final rule: editable when BUS_ID is set and ACTIVITY is empty)
    FUNCTION ACTIVITY_IS_READ_ONLY (P_BUS_ID   IN VARCHAR2,
                                    P_ACTIVITY IN VARCHAR2) RETURN BOOLEAN
    IS
    BEGIN
        RETURN NOT (P_BUS_ID IS NOT NULL AND P_ACTIVITY IS NULL);
    END ACTIVITY_IS_READ_ONLY;

    -- Section: ITEM ACTIVITY
    -- Source: PRE-INSERT (ACTIVITY must be entered while it is editable)
    FUNCTION ACTIVITY_IS_REQUIRED (P_BUS_ID IN VARCHAR2) RETURN BOOLEAN
    IS
    BEGIN
        RETURN P_BUS_ID IS NOT NULL;
    END ACTIVITY_IS_REQUIRED;

    -- Section: ITEM B_ID_NBR
    -- Source: IMPR_TYPE_CD WHEN-VALIDATE-ITEM (type 4 with BUS_ID_TYPE_CD 5)
    FUNCTION B_ID_NBR_IS_READ_ONLY (P_IMPR_TYPE_CD   IN NUMBER,
                                    P_BUS_ID_TYPE_CD IN NUMBER) RETURN BOOLEAN
    IS
    BEGIN
        RETURN P_IMPR_TYPE_CD = 4 AND P_BUS_ID_TYPE_CD = 5;
    END B_ID_NBR_IS_READ_ONLY;

    -- Section: ITEM CAR_AGENT_FLAG
    -- Source: WNRI (editable only in mode IMPR1110SF6 on a saved record; spec "SEL only")
    FUNCTION CAR_AGENT_FLAG_IS_READ_ONLY (P_IMPR_NBR IN NUMBER,
                                          P_P_CODE   IN VARCHAR2) RETURN BOOLEAN
    IS
    BEGIN
        RETURN NOT (P_IMPR_NBR IS NOT NULL AND P_P_CODE = 'IMPR1110SF6');
    END CAR_AGENT_FLAG_IS_READ_ONLY;

    -- Section: ITEM EXPRESS_POST
    -- Source: BROKER_INT (brokers: value 2 and read-only)
    FUNCTION EXPRESS_POST_IS_READ_ONLY (P_CLASS_CD IN NUMBER,
                                        V_USR_TYPE IN NUMBER) RETURN BOOLEAN
    IS
    BEGIN
        RETURN P_CLASS_CD = 1 AND V_USR_TYPE = 3;
    END EXPRESS_POST_IS_READ_ONLY;

    -- Section: ITEM CITY_CODE
    -- Source: IMPORTERS.POST-QUERY (CR-6730: WASL city replaces CITY_CODE / CITY_NAME when it exists)
    -- APEX  : Server-side condition of P1110_WASL_CITY_NAME (shown) and P1110_CITY_CODE / CITY_NAME (not shown)
    FUNCTION WASL_CITY_IS_SHOWN (P_CURR_PORT_CD       IN NUMBER,
                                 P_WASL_CITY_NAME IN VARCHAR2) RETURN BOOLEAN
    IS
    BEGIN
        RETURN P_WASL_CITY_NAME IS NOT NULL
               AND NVL(gnrl.get_customs_setting(P_CURR_PORT_CD, 'CR-6730', 9), 0) = 1;
    END WASL_CITY_IS_SHOWN;

    -- Section: f345 HELPERS
    -- Read-only flags of the items whose rule can change while the page is open (after a change of
    -- IMPR_TYPE_CD, BUS_ID_TYPE_CD, COMM_RGSTRTN_TYPE, BUS_ID, BUS_ID_BRNCH, IMPR_TEL_NBR, ACTIVITY, or a
    -- function mode set by EXEC_FUNS). APEX renders a Read Only item as text, which native Enable cannot
    -- undo, so these items use flags instead of a Read Only condition.
    -- APEX  : Before Header process "READ ONLY FLAGS" and the last FOS action of the DAs above
    --         (Items to Return = P1110_<ITEM>_LOCKED, change events on); DA "<ITEM> READ ONLY" on change of
    --         P1110_<ITEM>_LOCKED: Disable when Y, else Enable (fire on initialization).
    PROCEDURE READ_ONLY_FLAGS (P_IMPR_NBR           IN  NUMBER,
                               P_P_CODE             IN  VARCHAR2,
                               P_P_PRSNL_IMPR       IN  NUMBER,
                               P_IMPR_TYPE_CD       IN  NUMBER,
                               P_BUS_ID_TYPE_CD     IN  NUMBER,
                               P_COMM_RGSTRTN_TYPE  IN  NUMBER,
                               P_BUS_ID             IN  VARCHAR2,
                               P_BUS_ID_BRNCH       IN  VARCHAR2,
                               P_BUS_ID_EXPRD_DT    IN  VARCHAR2,
                               P_IMPR_TEL_NBR       IN  VARCHAR2,
                               P_ACTIVITY           IN  VARCHAR2,
                               IMPR_TYPE_CD_LOCKED      OUT VARCHAR2,
                               BUS_ID_EXPRD_DT_LOCKED   OUT VARCHAR2,
                               COMM_RGSTRTN_TYPE_LOCKED OUT VARCHAR2,
                               CITY_CODE_OF_ID_LOCKED   OUT VARCHAR2,
                               BUS_ID_LOCKED            OUT VARCHAR2,
                               BRNH_CITY_CD_LOCKED      OUT VARCHAR2,
                               BUS_ID_BRNCH_LOCKED      OUT VARCHAR2,
                               CTRY_CD_LOCKED           OUT VARCHAR2,
                               ARBC_IMPR_NAME_LOCKED    OUT VARCHAR2,
                               REGISTER_ITEMS_LOCKED    OUT VARCHAR2,
                               IMPR_TEL_NBR_LOCKED      OUT VARCHAR2,
                               ACTIVITY_LOCKED          OUT VARCHAR2,
                               B_ID_NBR_LOCKED          OUT VARCHAR2,
                               CAR_AGENT_FLAG_LOCKED    OUT VARCHAR2)
    IS
        FUNCTION YES_NO (p_flag IN BOOLEAN) RETURN VARCHAR2 IS
        BEGIN
            RETURN CASE WHEN p_flag THEN 'Y' ELSE 'N' END;
        END YES_NO;
    BEGIN
        IMPR_TYPE_CD_LOCKED      := YES_NO(IMPR_TYPE_CD_IS_READ_ONLY(P_IMPR_NBR, P_P_CODE,
                                                 P_P_PRSNL_IMPR));
        BUS_ID_EXPRD_DT_LOCKED   := YES_NO(BUS_ID_EXPRD_DT_IS_READ_ONLY(P_IMPR_NBR, P_P_CODE,
                                                 P_IMPR_TYPE_CD, P_BUS_ID_TYPE_CD, P_BUS_ID,
                                                 P_BUS_ID_BRNCH, P_COMM_RGSTRTN_TYPE,
                                                 P_BUS_ID_EXPRD_DT));
        COMM_RGSTRTN_TYPE_LOCKED := YES_NO(COMM_RGSTRTN_TYPE_IS_READ_ONLY(P_IMPR_NBR, P_P_CODE,
                                                 P_IMPR_TYPE_CD, P_BUS_ID_TYPE_CD));
        CITY_CODE_OF_ID_LOCKED   := YES_NO(CITY_CODE_OF_ID_IS_READ_ONLY(P_IMPR_NBR, P_P_CODE,
                                                 P_IMPR_TYPE_CD, P_BUS_ID_TYPE_CD));
        BUS_ID_LOCKED            := YES_NO(BUS_ID_IS_READ_ONLY(P_IMPR_NBR, P_P_CODE,
                                                 P_IMPR_TYPE_CD, P_BUS_ID_TYPE_CD));
        BRNH_CITY_CD_LOCKED      := YES_NO(BRNH_CITY_CD_IS_READ_ONLY(P_IMPR_NBR, P_P_CODE,
                                                 P_COMM_RGSTRTN_TYPE));
        BUS_ID_BRNCH_LOCKED      := YES_NO(BUS_ID_BRNCH_IS_READ_ONLY(P_IMPR_NBR, P_P_CODE,
                                                 P_IMPR_TYPE_CD, P_BUS_ID_TYPE_CD,
                                                 P_COMM_RGSTRTN_TYPE));
        CTRY_CD_LOCKED           := YES_NO(CTRY_CD_IS_READ_ONLY(P_IMPR_TYPE_CD, P_BUS_ID_TYPE_CD));
        ARBC_IMPR_NAME_LOCKED    := YES_NO(ARBC_IMPR_NAME_IS_READ_ONLY(P_IMPR_NBR, P_P_CODE,
                                                 P_IMPR_TYPE_CD, P_BUS_ID_TYPE_CD, P_BUS_ID,
                                                 P_BUS_ID_BRNCH, P_COMM_RGSTRTN_TYPE));
        REGISTER_ITEMS_LOCKED    := YES_NO(REGISTER_ITEMS_IS_READ_ONLY(P_IMPR_TYPE_CD,
                                                 P_BUS_ID_TYPE_CD, P_BUS_ID, P_BUS_ID_BRNCH,
                                                 P_COMM_RGSTRTN_TYPE));
        IMPR_TEL_NBR_LOCKED      := YES_NO(REGISTER_ITEMS_IS_READ_ONLY(P_IMPR_TYPE_CD,
                                                 P_BUS_ID_TYPE_CD, P_BUS_ID, P_BUS_ID_BRNCH,
                                                 P_COMM_RGSTRTN_TYPE, P_IMPR_TEL_NBR));
        ACTIVITY_LOCKED          := YES_NO(ACTIVITY_IS_READ_ONLY(P_BUS_ID, P_ACTIVITY));
        B_ID_NBR_LOCKED          := YES_NO(B_ID_NBR_IS_READ_ONLY(P_IMPR_TYPE_CD, P_BUS_ID_TYPE_CD));
        CAR_AGENT_FLAG_LOCKED    := YES_NO(CAR_AGENT_FLAG_IS_READ_ONLY(P_IMPR_NBR, P_P_CODE));
    END READ_ONLY_FLAGS;


    -- =========================================================================
    -- 5 f345 HELPERS AND SMALL ENTRY POINTS
    -- =========================================================================
    -- Section: PRIVATE
    -- Error text for a failed entry point: FORMS_APX.FORM_TRIGGER_FAILURE / raise_application_error text,
    -- else the IMPORTERS.ON-ERROR constraint message (importers_on_error)
    FUNCTION PRIVATE_ERROR_TEXT (p_sqlcode IN NUMBER, p_sqlerrm IN VARCHAR2, p_op IN VARCHAR2 DEFAULT 'U')
        RETURN VARCHAR2
    IS
    BEGIN
        IF p_sqlcode BETWEEN -20999 AND -20000 THEN
            RETURN REGEXP_REPLACE(p_sqlerrm, '^ORA-[0-9]+: ');
        END IF;
        RETURN importers_on_error(p_op, p_sqlcode, p_sqlerrm);
    END PRIVATE_ERROR_TEXT;

    -- Section: PRIVATE
    -- Comma list of the functions ADJ_FUNS left enabled (SET_FUNCTION_ENABLED calls; last call wins)
    FUNCTION PRIVATE_ENABLED_FUNCTIONS RETURN VARCHAR2
    IS
        v_list VARCHAR2(4000);
        v_rest VARCHAR2(4000) := c_functions || ',';
        v_fun  VARCHAR2(100);
    BEGIN
        WHILE v_rest IS NOT NULL LOOP
            v_fun  := SUBSTR(v_rest, 1, INSTR(v_rest, ',') - 1);
            v_rest := SUBSTR(v_rest, INSTR(v_rest, ',') + 1);
            IF NVL(FUNCTION_STATE(v_fun), 'Y') = 'Y' THEN
                v_list := v_list || CASE WHEN v_list IS NOT NULL THEN ',' END || v_fun;
            END IF;
        END LOOP;
        RETURN v_list;
    END PRIVATE_ENABLED_FUNCTIONS;

    -- Section: f345 HELPERS
    -- f345 CHECK_ERROR: raise the text returned by a <ITEM>_VALIDATION function (used by the FOS DAs)
    PROCEDURE CHECK_ERROR (ERROR_TEXT IN VARCHAR2)
    IS
    BEGIN
        IF ERROR_TEXT IS NOT NULL THEN
            raise_application_error(c_err, ERROR_TEXT);
        END IF;
    END CHECK_ERROR;

    -- Section: f345 HELPERS
    -- Validation "<ITEM> REQUIRED" (server-side condition <ITEM>_IS_REQUIRED): Forms FRM-40202
    FUNCTION REQUIRED_VALIDATION (ITEM_VALUE IN VARCHAR2, ITEM_LABEL IN VARCHAR2) RETURN VARCHAR2
    IS
    BEGIN
        IF ITEM_VALUE IS NULL THEN
            RETURN CG_MESSAGE('<p1> must be entered', ITEM_LABEL);
        END IF;
        RETURN NULL;
    END REQUIRED_VALIDATION;

    -- Section: f345 HELPERS
    -- Process "P0_PAGE_PK CHECK" (Before Header): P0_PAGE_PK holds the ROWID of the importer (Forms key
    -- mode ROWID); forget a key that is not a row of IMPORTERS of this port (block WHERE clause)
    PROCEDURE P0_PAGE_PK_CHECK (P_PAGE_PK    IN OUT VARCHAR2,
                                P_CURR_PORT_CD IN     NUMBER)
    IS
        v_cnt NUMBER;
    BEGIN
        IF P_PAGE_PK IS NULL THEN
            RETURN;
        END IF;
        SELECT COUNT(*)
          INTO v_cnt
          FROM importers i
         WHERE i.ROWID   = CHARTOROWID(P0_PAGE_PK_CHECK.P_PAGE_PK)
           AND i.port_cd = P0_PAGE_PK_CHECK.P_CURR_PORT_CD;
        IF v_cnt = 0 THEN
            P_PAGE_PK := NULL;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN               -- ORA-01410 invalid ROWID, ORA-01445 ...: not a key of this page
            P_PAGE_PK := NULL;
    END P0_PAGE_PK_CHECK;

    -- Section: f345 HELPERS
    -- Process "EXECUTE-QUERY" (request EXECUTE_QUERY): the ROWID of importer IMPR_NBR of this port, for
    -- P0_PAGE_PK. Source: IMPORTERS.IMPR_NBR.WHEN-VALIDATE-ITEM (existing number -> :GLOBAL.EXEC_QUERY_NOW
    -- -> IMPORTERS.WHEN-NEW-ITEM-INSTANCE EXECUTE_QUERY with PRE-QUERY on :GLOBAL.PORT_CD / IMPR_NBR)
    FUNCTION IMPORTER_ROW_ID (P_IMPR_NBR IN NUMBER,
                              P_CURR_PORT_CD IN NUMBER) RETURN VARCHAR2
    IS
        v_row_id VARCHAR2(18);
    BEGIN
        SELECT MAX(ROWIDTOCHAR(i.ROWID))
          INTO v_row_id
          FROM importers i
         WHERE i.port_cd  = IMPORTER_ROW_ID.P_CURR_PORT_CD
           AND i.impr_nbr = IMPORTER_ROW_ID.P_IMPR_NBR;
        RETURN v_row_id;
    END IMPORTER_ROW_ID;

    -- Section: f345 HELPERS
    -- Computation P1110_MODULE_ID: SC_SYSTEM_OBJECTS id of the form (f345 Page Functions list)
    FUNCTION GET_MODULE_ID (P_MODULE_ID IN VARCHAR2) RETURN VARCHAR2
    IS
        v_id VARCHAR2(40);
    BEGIN
        IF P_MODULE_ID IS NOT NULL THEN
            RETURN P_MODULE_ID;
        END IF;
        SELECT TO_CHAR(MIN(o.sysobj_id))
          INTO v_id
          FROM sc_system_objects o
         WHERE UPPER(REGEXP_REPLACE(o.sys_os_file_name, '\..*$', '')) = 'IMPR1110';
        RETURN v_id;
    END GET_MODULE_ID;

    -- Section: f345 HELPERS
    -- Process "PARAMETERS ENTRY" (f345): one-shot hand-over of :PARAMETER.PRSNL_IMPR / LETTER_NBR
    PROCEDURE PARAMETERS_ENTRY (P_PRSNL_IMPR       IN OUT VARCHAR2,
                                P_LETTER_NBR       IN OUT VARCHAR2,
                                P_P_PRSNL_IMPR IN OUT VARCHAR2,
                                P_P_LETTER_NBR IN OUT VARCHAR2)
    IS
    BEGIN
        P_P_PRSNL_IMPR := NVL(P_PRSNL_IMPR, P_P_PRSNL_IMPR);
        P_P_LETTER_NBR := NVL(P_LETTER_NBR, P_P_LETTER_NBR);
        P_PRSNL_IMPR       := NULL;
        P_LETTER_NBR       := NULL;
    END PARAMETERS_ENTRY;

    -- Section: f345 HELPERS
    -- Process "HEADER TITLE": the form title from SC_SYSTEM_OBJECTS (Forms TITLE block)
    PROCEDURE HEADER_TITLE (P_MODULE_ID   IN     VARCHAR2,
                            P_HERO_TITLE IN OUT VARCHAR2)
    IS
        v_name VARCHAR2(400);
    BEGIN
        IF P_MODULE_ID IS NOT NULL THEN
            SELECT MAX(o.sys_aname)
              INTO v_name
              FROM sc_system_objects o
             WHERE o.sysobj_id = TO_NUMBER(HEADER_TITLE.P_MODULE_ID);
        END IF;
        P_HERO_TITLE := NVL(v_name, c_hero_title);
    EXCEPTION
        WHEN VALUE_ERROR OR INVALID_NUMBER THEN
            P_HERO_TITLE := c_hero_title;
    END HEADER_TITLE;

    -- Section: PAGE 111002 (LOV_UPDATE_IMPR_MOBILE)
    -- Source: LOV_UPDATE_IMPR_MOBILE.CTRL_BLK.PB_OK (:GLOBAL.OK := 1; COPY_SELECTED_VALUES)
    -- APEX  : Process "PB_OK WHEN-BUTTON-PRESSED" of page 111002, then Close Dialog
    PROCEDURE MOBILE_OK (P_MOBILE_NO IN VARCHAR2)
    IS
    BEGIN
        FORMS_APX.set_global('MOBILE_NO', P_MOBILE_NO);
    END MOBILE_OK;

    -- Section: PAGE 111002 (LOV_UPDATE_IMPR_MOBILE)
    -- Source: LOV_UPDATE_IMPR_MOBILE.CTRL_BLK.PB_CANCEL (CANCEL_LOV_FORM)
    PROCEDURE MOBILE_CANCEL
    IS
    BEGIN
        FORMS_APX.set_global('MOBILE_NO', NULL);
    END MOBILE_CANCEL;


    -- =========================================================================
    -- 6 APEX ENTRY POINTS (generated: IN / IN OUT parameters = items the logic reads / writes)
    -- =========================================================================
    -- Source: IMPR1110.WHEN-NEW-FORM-INSTANCE (business part)
    -- APEX  : Process "WHEN-NEW-FORM-INSTANCE" (Before Header, first page view)
    PROCEDURE WHEN_NEW_FORM_INSTANCE (P_IMPR_TYPE_CD        IN     importers.impr_type_cd%TYPE,
                                      P_BUS_ID_TYPE_CD      IN     importers.bus_id_type_cd%TYPE,
                                      P_CTRY_CD            IN OUT importers.ctry_cd%TYPE,
                                      P_IMPR_EXPR_TYPE     IN OUT importers.impr_expr_type%TYPE,
                                      P_ADD_CTRY_CD        IN OUT importers.add_ctry_cd%TYPE,
                                      P_EXPRESS_POST       IN OUT importers.express_post%TYPE,
                                      P_CRTY_ARBC_NAME     IN OUT VARCHAR2,
                                      P_ADD_CRTY_ARBC_NAME IN OUT VARCHAR2,
                                      P_CURR_PORT_CD            IN     NUMBER,
                                      P_CLASS_CD                IN     NUMBER,
                                      V_USR_TYPE                IN     NUMBER,
                                      P_P_LETTER_NBR        IN     VARCHAR2)
    IS
        r T_RECORD;
        c T_CONTEXT;
    BEGIN
        c.curr_port_cd := P_CURR_PORT_CD;
        c.class_cd := P_CLASS_CD;
        c.user_type := V_USR_TYPE;
        c.letter_nbr := P_P_LETTER_NBR;
        r.impr_type_cd := P_IMPR_TYPE_CD;
        r.bus_id_type_cd := P_BUS_ID_TYPE_CD;
        r.ctry_cd := P_CTRY_CD;
        r.impr_expr_type := P_IMPR_EXPR_TYPE;
        r.add_ctry_cd := P_ADD_CTRY_CD;
        r.express_post := P_EXPRESS_POST;
        r.crty_arbc_name := P_CRTY_ARBC_NAME;
        r.add_crty_arbc_name := P_ADD_CRTY_ARBC_NAME;
        WHEN_NEW_FORM_INSTANCE(r, c);
        P_CTRY_CD := r.ctry_cd;
        P_IMPR_EXPR_TYPE := r.impr_expr_type;
        P_ADD_CTRY_CD := r.add_ctry_cd;
        P_EXPRESS_POST := r.express_post;
        P_CRTY_ARBC_NAME := r.crty_arbc_name;
        P_ADD_CRTY_ARBC_NAME := r.add_crty_arbc_name;
    END WHEN_NEW_FORM_INSTANCE;

    -- Source: IMPORTERS.POST-QUERY, after the POST-CHANGE triggers Forms fires for the fetched items
    -- APEX  : Process "POST-QUERY" (Before Header, after "Initialize form IMPORTERS"; :P0_PAGE_PK is not null)
    PROCEDURE POST_QUERY (P_PORT_CD             IN     importers.port_cd%TYPE,
                          P_HQ_IMPR_NBR         IN     importers.hq_impr_nbr%TYPE,
                          P_IMPR_NBR            IN     importers.impr_nbr%TYPE,
                          P_BUS_ID_STATUS       IN     importers.bus_id_status%TYPE,
                          P_IMPR_TYPE_CD        IN     importers.impr_type_cd%TYPE,
                          P_BUS_ID_TYPE_CD      IN     importers.bus_id_type_cd%TYPE,
                          P_CITY_CODE_OF_ID     IN     importers.city_code_of_id%TYPE,
                          P_BUS_ID              IN     importers.bus_id%TYPE,
                          P_BUS_ID_BRNCH        IN     importers.bus_id_brnch%TYPE,
                          P_CTRY_CD            IN OUT importers.ctry_cd%TYPE,
                          P_ADD_CTRY_CD        IN OUT importers.add_ctry_cd%TYPE,
                          P_CITY_CODE           IN     importers.city_code%TYPE,
                          P_EMAIL               IN     importers.email%TYPE,
                          P_MOBILE_NO           IN     importers.mobile_no%TYPE,
                          P_ID_NBR              IN     importers.id_nbr%TYPE,
                          P_CTRY_CD_OF_ID       IN     importers.ctry_cd_of_id%TYPE,
                          P_PORT_NAME          IN OUT VARCHAR2,
                          P_SDP_PORT_STATUS    IN OUT NUMBER,
                          P_SUSPN_STATUS       IN OUT VARCHAR2,
                          P_STATUS_DESC        IN OUT VARCHAR2,
                          P_IMPR_TYPE_NAME     IN OUT VARCHAR2,
                          P_BUS_ID_TYPE_NAME   IN OUT VARCHAR2,
                          P_ID_CITY_NAME       IN OUT VARCHAR2,
                          P_ID_MINS_COMM_CD    IN OUT NUMBER,
                          P_L_CT_CITY_STATUS2  IN OUT NUMBER,
                          P_BRNH_CITY_CD       IN OUT NUMBER,
                          P_BRNH_CITY_NAME     IN OUT VARCHAR2,
                          P_CRTY_ARBC_NAME     IN OUT VARCHAR2,
                          P_CTRY_CTRY_STATUS   IN OUT NUMBER,
                          P_ITIDT_NOTE         IN OUT VARCHAR2,
                          P_STATUS             IN OUT NUMBER,
                          P_WASL_CITY_NAME     IN OUT VARCHAR2,
                          P_ADD_CRTY_ARBC_NAME IN OUT VARCHAR2,
                          P_CITY_NAME          IN OUT VARCHAR2,
                          P_L_CT_CITY_STATUS   IN OUT NUMBER,
                          P_B_EMAIL            IN OUT VARCHAR2,
                          P_B_MOBILE_NO        IN OUT VARCHAR2,
                          P_B_ID_NBR           IN OUT VARCHAR2,
                          P_IMPR_ID_TYPE       IN OUT VARCHAR2,
                          P_CURR_PORT_CD            IN     NUMBER,
                          SSO_APP_USER              IN     VARCHAR2,
                          P_CLASS_CD                IN     NUMBER,
                          V_USR_TYPE                IN     NUMBER)
    IS
        r T_RECORD;
        c T_CONTEXT;
    BEGIN
        c.curr_port_cd := P_CURR_PORT_CD;
        c.user_id := SSO_APP_USER;
        c.class_cd := P_CLASS_CD;
        c.user_type := V_USR_TYPE;
        r.port_cd := P_PORT_CD;
        r.hq_impr_nbr := P_HQ_IMPR_NBR;
        r.impr_nbr := P_IMPR_NBR;
        r.bus_id_status := P_BUS_ID_STATUS;
        r.impr_type_cd := P_IMPR_TYPE_CD;
        r.bus_id_type_cd := P_BUS_ID_TYPE_CD;
        r.city_code_of_id := P_CITY_CODE_OF_ID;
        r.bus_id := P_BUS_ID;
        r.bus_id_brnch := P_BUS_ID_BRNCH;
        r.ctry_cd := P_CTRY_CD;
        r.add_ctry_cd := P_ADD_CTRY_CD;
        r.city_code := P_CITY_CODE;
        r.email := P_EMAIL;
        r.mobile_no := P_MOBILE_NO;
        r.id_nbr := P_ID_NBR;
        r.ctry_cd_of_id := P_CTRY_CD_OF_ID;
        r.port_name := P_PORT_NAME;
        r.sdp_port_status := P_SDP_PORT_STATUS;
        r.suspn_status := P_SUSPN_STATUS;
        r.status_desc := P_STATUS_DESC;
        r.impr_type_name := P_IMPR_TYPE_NAME;
        r.bus_id_type_name := P_BUS_ID_TYPE_NAME;
        r.id_city_name := P_ID_CITY_NAME;
        r.id_mins_comm_cd := P_ID_MINS_COMM_CD;
        r.l_ct_city_status2 := P_L_CT_CITY_STATUS2;
        r.brnh_city_cd := P_BRNH_CITY_CD;
        r.brnh_city_name := P_BRNH_CITY_NAME;
        r.crty_arbc_name := P_CRTY_ARBC_NAME;
        r.ctry_ctry_status := P_CTRY_CTRY_STATUS;
        r.itidt_note := P_ITIDT_NOTE;
        r.status := P_STATUS;
        r.wasl_city_name := P_WASL_CITY_NAME;
        r.add_crty_arbc_name := P_ADD_CRTY_ARBC_NAME;
        r.city_name := P_CITY_NAME;
        r.l_ct_city_status := P_L_CT_CITY_STATUS;
        r.b_email := P_B_EMAIL;
        r.b_mobile_no := P_B_MOBILE_NO;
        r.b_id_nbr := P_B_ID_NBR;
        r.impr_id_type := P_IMPR_ID_TYPE;
        IF r.hq_impr_nbr IS NOT NULL THEN HQ_IMPR_NBR_POST_CHANGE; END IF;
        IF r.impr_type_cd IS NOT NULL THEN IMPR_TYPE_CD_POST_CHANGE(r); END IF;
        IF r.bus_id_type_cd IS NOT NULL THEN BUS_ID_TYPE_CD_POST_CHANGE(r); END IF;
        IF r.bus_id IS NOT NULL THEN BUS_ID_POST_CHANGE; END IF;
        IF r.bus_id_brnch IS NOT NULL THEN BUS_ID_BRNCH_POST_CHANGE; END IF;
        IF r.impr_expr_type IS NOT NULL THEN IMPR_EXPR_TYPE_POST_CHANGE; END IF;
        IMPORTERS_POST_QUERY(r, c);
        P_CTRY_CD := r.ctry_cd;
        P_ADD_CTRY_CD := r.add_ctry_cd;
        P_PORT_NAME := r.port_name;
        P_SDP_PORT_STATUS := r.sdp_port_status;
        P_SUSPN_STATUS := r.suspn_status;
        P_STATUS_DESC := r.status_desc;
        P_IMPR_TYPE_NAME := r.impr_type_name;
        P_BUS_ID_TYPE_NAME := r.bus_id_type_name;
        P_ID_CITY_NAME := r.id_city_name;
        P_ID_MINS_COMM_CD := r.id_mins_comm_cd;
        P_L_CT_CITY_STATUS2 := r.l_ct_city_status2;
        P_BRNH_CITY_CD := r.brnh_city_cd;
        P_BRNH_CITY_NAME := r.brnh_city_name;
        P_CRTY_ARBC_NAME := r.crty_arbc_name;
        P_CTRY_CTRY_STATUS := r.ctry_ctry_status;
        P_ITIDT_NOTE := r.itidt_note;
        P_STATUS := r.status;
        P_WASL_CITY_NAME := r.wasl_city_name;
        P_ADD_CRTY_ARBC_NAME := r.add_crty_arbc_name;
        P_CITY_NAME := r.city_name;
        P_L_CT_CITY_STATUS := r.l_ct_city_status;
        P_B_EMAIL := r.b_email;
        P_B_MOBILE_NO := r.b_mobile_no;
        P_B_ID_NBR := r.b_id_nbr;
        P_IMPR_ID_TYPE := r.impr_id_type;
    END POST_QUERY;

    -- Source: IMPORTERS.WHEN-CREATE-RECORD
    -- APEX  : Process "WHEN-CREATE-RECORD" (Before Header, :P0_PAGE_PK is null)
    PROCEDURE WHEN_CREATE_RECORD (P_PORT_CD        IN OUT importers.port_cd%TYPE,
                                  P_IMPR_TYPE_CD   IN OUT importers.impr_type_cd%TYPE,
                                  P_PORT_NAME      IN OUT VARCHAR2,
                                  P_IMPR_TYPE_NAME IN OUT VARCHAR2,
                                  P_CURR_PORT_CD        IN     NUMBER,
                                  P_P_PRSNL_IMPR    IN     NUMBER)
    IS
        r T_RECORD;
        c T_CONTEXT;
    BEGIN
        c.curr_port_cd := P_CURR_PORT_CD;
        c.prsnl_impr := P_P_PRSNL_IMPR;
        r.port_cd := P_PORT_CD;
        r.impr_type_cd := P_IMPR_TYPE_CD;
        r.port_name := P_PORT_NAME;
        r.impr_type_name := P_IMPR_TYPE_NAME;
        IMPORTERS_WHEN_CREATE_RECORD(r, c);
        P_PORT_CD := r.port_cd;
        P_IMPR_TYPE_CD := r.impr_type_cd;
        P_PORT_NAME := r.port_name;
        P_IMPR_TYPE_NAME := r.impr_type_name;
    END WHEN_CREATE_RECORD;

    -- Source: IMPORTERS.PRE-RECORD + WHEN-NEW-RECORD-INSTANCE (function modes F1..F5, SF6; type-19 rule without COMMIT)
    -- APEX  : Process "WHEN-NEW-RECORD-INSTANCE" (Before Header, after POST-QUERY / WHEN-CREATE-RECORD); FOS after a function (Confirm with NEW_RECORD_CONFIRM_TEXT first)
    PROCEDURE WHEN_NEW_RECORD_INSTANCE (P_IMPR_NBR            IN     importers.impr_nbr%TYPE,
                                        P_IMPR_TYPE_CD       IN OUT importers.impr_type_cd%TYPE,
                                        P_BUS_ID_TYPE_CD      IN     importers.bus_id_type_cd%TYPE,
                                        P_COMM_RGSTRTN_TYPE   IN     importers.comm_rgstrtn_type%TYPE,
                                        P_BUS_ID              IN     importers.bus_id%TYPE,
                                        P_BUS_ID_BRNCH        IN     importers.bus_id_brnch%TYPE,
                                        P_CTRY_CD            IN OUT importers.ctry_cd%TYPE,
                                        P_ARBC_IMPR_NAME     IN OUT importers.arbc_impr_name%TYPE,
                                        P_IMPR_NBR_PARENT     IN     importers.impr_nbr_parent%TYPE,
                                        P_ADD_CTRY_CD        IN OUT importers.add_ctry_cd%TYPE,
                                        P_CRTY_ARBC_NAME     IN OUT VARCHAR2,
                                        P_IMPR_NAME_PARENT   IN OUT VARCHAR2,
                                        P_ADD_CRTY_ARBC_NAME IN OUT VARCHAR2,
                                        P_CURR_PORT_CD            IN     NUMBER,
                                        P_CLASS_CD                IN     NUMBER,
                                        V_USR_TYPE                IN     NUMBER,
                                        P_P_CODE              IN     VARCHAR2,
                                        P_ANSWER              IN     PLS_INTEGER DEFAULT NULL)
    IS
        r T_RECORD;
        c T_CONTEXT;
    BEGIN
        c.curr_port_cd := P_CURR_PORT_CD;
        c.class_cd := P_CLASS_CD;
        c.user_type := V_USR_TYPE;
        c.code := P_P_CODE;
        r.impr_nbr := P_IMPR_NBR;
        r.impr_type_cd := P_IMPR_TYPE_CD;
        r.bus_id_type_cd := P_BUS_ID_TYPE_CD;
        r.comm_rgstrtn_type := P_COMM_RGSTRTN_TYPE;
        r.bus_id := P_BUS_ID;
        r.bus_id_brnch := P_BUS_ID_BRNCH;
        r.ctry_cd := P_CTRY_CD;
        r.arbc_impr_name := P_ARBC_IMPR_NAME;
        r.impr_nbr_parent := P_IMPR_NBR_PARENT;
        r.add_ctry_cd := P_ADD_CTRY_CD;
        r.crty_arbc_name := P_CRTY_ARBC_NAME;
        r.impr_name_parent := P_IMPR_NAME_PARENT;
        r.add_crty_arbc_name := P_ADD_CRTY_ARBC_NAME;
        IMPORTERS_PRE_RECORD(r, c);
        IMPORTERS_NEW_RECORD_INSTANCE(r, c, NVL(P_ANSWER, c_yes));
        P_IMPR_TYPE_CD := r.impr_type_cd;
        P_CTRY_CD := r.ctry_cd;
        P_ARBC_IMPR_NAME := r.arbc_impr_name;
        P_ADD_CTRY_CD := r.add_ctry_cd;
        P_CRTY_ARBC_NAME := r.crty_arbc_name;
        P_IMPR_NAME_PARENT := r.impr_name_parent;
        P_ADD_CRTY_ARBC_NAME := r.add_crty_arbc_name;
    END WHEN_NEW_RECORD_INSTANCE;

    -- Source: IMPORTERS.WHEN-NEW-RECORD-INSTANCE, question of IMPR1110F1 / IMPR1110F5 ("سيتم تعديل الإسم إلى ...")
    -- APEX  : FOS returns P1110_CONFIRM_TEXT; native Confirm when it is not null
    FUNCTION NEW_RECORD_CONFIRM_TEXT (P_IMPR_TYPE_CD      IN     importers.impr_type_cd%TYPE,
                                      P_BUS_ID_TYPE_CD    IN     importers.bus_id_type_cd%TYPE,
                                      P_COMM_RGSTRTN_TYPE IN     importers.comm_rgstrtn_type%TYPE,
                                      P_BUS_ID            IN     importers.bus_id%TYPE,
                                      P_BUS_ID_BRNCH      IN     importers.bus_id_brnch%TYPE,
                                      P_P_CODE            IN     VARCHAR2)
        RETURN VARCHAR2
    IS
        r T_RECORD;
        c T_CONTEXT;
    BEGIN
        c.code := P_P_CODE;
        r.impr_type_cd := P_IMPR_TYPE_CD;
        r.bus_id_type_cd := P_BUS_ID_TYPE_CD;
        r.comm_rgstrtn_type := P_COMM_RGSTRTN_TYPE;
        r.bus_id := P_BUS_ID;
        r.bus_id_brnch := P_BUS_ID_BRNCH;
        RETURN NEW_RECORD_CONFIRM_TEXT(r, c);
    END NEW_RECORD_CONFIRM_TEXT;

    -- Source: IMPORTERS.WHEN-CLEAR-BLOCK
    -- APEX  : Process "WHEN-CLEAR-BLOCK" (request CLEAR of the page 0 toolbar)
    PROCEDURE WHEN_CLEAR_BLOCK
    IS

    BEGIN
        IMPORTERS_WHEN_CLEAR_BLOCK;
    END WHEN_CLEAR_BLOCK;

    -- Source: IMPORTERS.PORT_CD.WHEN-VALIDATE-ITEM
    -- APEX  : Validation "PORT_CD VALIDATION" (request CREATE / SAVE): returns the error text
    FUNCTION PORT_CD_VALIDATION (P_PORT_CD         IN     importers.port_cd%TYPE,
                                 P_PORT_NAME       IN     VARCHAR2,
                                 P_SDP_PORT_STATUS IN     NUMBER)
        RETURN VARCHAR2
    IS
        r T_RECORD;
    BEGIN
        r.port_cd := P_PORT_CD;
        r.port_name := P_PORT_NAME;
        r.sdp_port_status := P_SDP_PORT_STATUS;
        PORT_CD_WHEN_VALIDATE_ITEM(r);
        RETURN NULL;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN PRIVATE_ERROR_TEXT(SQLCODE, SQLERRM, CASE WHEN r.row_id IS NULL THEN 'I' ELSE 'U' END);
    END PORT_CD_VALIDATION;

    -- Source: IMPORTERS.PORT_CD.WHEN-VALIDATE-ITEM
    -- APEX  : DA "PORT_CD WHEN-VALIDATE-ITEM" (Change): FOS, Items to Submit = the IN items, Items to Return = the IN OUT / OUT items
    PROCEDURE PORT_CD_WHEN_VALIDATE_ITEM (P_PORT_CD          IN     importers.port_cd%TYPE,
                                          P_PORT_NAME       IN OUT VARCHAR2,
                                          P_SDP_PORT_STATUS IN OUT NUMBER)
    IS
        r T_RECORD;
    BEGIN
        r.port_cd := P_PORT_CD;
        r.port_name := P_PORT_NAME;
        r.sdp_port_status := P_SDP_PORT_STATUS;
        PORT_CD_WHEN_VALIDATE_ITEM(r);
        P_PORT_NAME := r.port_name;
        P_SDP_PORT_STATUS := r.sdp_port_status;
    END PORT_CD_WHEN_VALIDATE_ITEM;

    -- Source: IMPORTERS.HQ_IMPR_NBR.POST-CHANGE
    -- APEX  : Validation "HQ_IMPR_NBR VALIDATION" (request CREATE / SAVE): returns the error text
    FUNCTION HQ_IMPR_NBR_VALIDATION
        RETURN VARCHAR2
    IS
        r T_RECORD;
    BEGIN
        HQ_IMPR_NBR_POST_CHANGE;
        RETURN NULL;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN PRIVATE_ERROR_TEXT(SQLCODE, SQLERRM, CASE WHEN r.row_id IS NULL THEN 'I' ELSE 'U' END);
    END HQ_IMPR_NBR_VALIDATION;

    -- Source: IMPORTERS.HQ_IMPR_NBR.POST-CHANGE
    -- APEX  : DA "HQ_IMPR_NBR WHEN-VALIDATE-ITEM" (Change): FOS, Items to Submit = the IN items, Items to Return = the IN OUT / OUT items
    PROCEDURE HQ_IMPR_NBR_WHEN_VALIDATE_ITEM
    IS

    BEGIN
        HQ_IMPR_NBR_POST_CHANGE;
    END HQ_IMPR_NBR_WHEN_VALIDATE_ITEM;

    -- Source: IMPORTERS.IMPR_NBR.WHEN-VALIDATE-ITEM
    -- APEX  : Validation "IMPR_NBR VALIDATION" (request CREATE / SAVE): returns the error text
    FUNCTION IMPR_NBR_VALIDATION (P_PORT_CD  IN     importers.port_cd%TYPE,
                                  P_IMPR_NBR IN     importers.impr_nbr%TYPE)
        RETURN VARCHAR2
    IS
        r T_RECORD;
    BEGIN
        r.port_cd := P_PORT_CD;
        r.impr_nbr := P_IMPR_NBR;
        IMPR_NBR_WHEN_VALIDATE_ITEM(r);
        RETURN NULL;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN PRIVATE_ERROR_TEXT(SQLCODE, SQLERRM, CASE WHEN r.row_id IS NULL THEN 'I' ELSE 'U' END);
    END IMPR_NBR_VALIDATION;

    -- Source: IMPORTERS.IMPR_NBR.WHEN-VALIDATE-ITEM
    -- APEX  : DA "IMPR_NBR WHEN-VALIDATE-ITEM" (Change): FOS, Items to Submit = the IN items, Items to Return = the IN OUT / OUT items
    PROCEDURE IMPR_NBR_WHEN_VALIDATE_ITEM (P_PORT_CD  IN     importers.port_cd%TYPE,
                                           P_IMPR_NBR IN     importers.impr_nbr%TYPE)
    IS
        r T_RECORD;
    BEGIN
        r.port_cd := P_PORT_CD;
        r.impr_nbr := P_IMPR_NBR;
        IMPR_NBR_WHEN_VALIDATE_ITEM(r);
    END IMPR_NBR_WHEN_VALIDATE_ITEM;

    -- Source: IMPORTERS.IMPR_TYPE_CD.POST-CHANGE + WHEN-VALIDATE-ITEM
    -- APEX  : Validation "IMPR_TYPE_CD VALIDATION" (request CREATE / SAVE): returns the error text
    FUNCTION IMPR_TYPE_CD_VALIDATION (P_IMPR_NBR           IN     importers.impr_nbr%TYPE,
                                      P_IMPR_TYPE_CD       IN     importers.impr_type_cd%TYPE,
                                      P_BUS_ID_TYPE_CD     IN     importers.bus_id_type_cd%TYPE,
                                      P_BUS_ID             IN     importers.bus_id%TYPE,
                                      P_CTRY_CD            IN     importers.ctry_cd%TYPE,
                                      P_ADD_CTRY_CD        IN     importers.add_ctry_cd%TYPE,
                                      P_IMPR_TYPE_NAME     IN     VARCHAR2,
                                      P_BUS_ID_TYPE_NAME   IN     VARCHAR2,
                                      P_CRTY_ARBC_NAME     IN     VARCHAR2,
                                      P_ITIDT_NOTE         IN     VARCHAR2,
                                      P_STATUS             IN     NUMBER,
                                      P_ADD_CRTY_ARBC_NAME IN     VARCHAR2,
                                      P_CURR_PORT_CD           IN     NUMBER)
        RETURN VARCHAR2
    IS
        r T_RECORD;
        c T_CONTEXT;
    BEGIN
        c.curr_port_cd := P_CURR_PORT_CD;
        r.impr_nbr := P_IMPR_NBR;
        r.impr_type_cd := P_IMPR_TYPE_CD;
        r.bus_id_type_cd := P_BUS_ID_TYPE_CD;
        r.bus_id := P_BUS_ID;
        r.ctry_cd := P_CTRY_CD;
        r.add_ctry_cd := P_ADD_CTRY_CD;
        r.impr_type_name := P_IMPR_TYPE_NAME;
        r.bus_id_type_name := P_BUS_ID_TYPE_NAME;
        r.crty_arbc_name := P_CRTY_ARBC_NAME;
        r.itidt_note := P_ITIDT_NOTE;
        r.status := P_STATUS;
        r.add_crty_arbc_name := P_ADD_CRTY_ARBC_NAME;
        IMPR_TYPE_CD_POST_CHANGE(r);
        IMPR_TYPE_CD_VALIDATE_ITEM(r, c);
        RETURN NULL;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN PRIVATE_ERROR_TEXT(SQLCODE, SQLERRM, CASE WHEN r.row_id IS NULL THEN 'I' ELSE 'U' END);
    END IMPR_TYPE_CD_VALIDATION;

    -- Source: IMPORTERS.IMPR_TYPE_CD.POST-CHANGE + WHEN-VALIDATE-ITEM
    -- APEX  : DA "IMPR_TYPE_CD WHEN-VALIDATE-ITEM" (Change): FOS, Items to Submit = the IN items, Items to Return = the IN OUT / OUT items
    PROCEDURE IMPR_TYPE_CD_VALIDATE_ITEM (P_IMPR_NBR            IN     importers.impr_nbr%TYPE,
                                          P_IMPR_TYPE_CD       IN OUT importers.impr_type_cd%TYPE,
                                          P_BUS_ID_TYPE_CD     IN OUT importers.bus_id_type_cd%TYPE,
                                          P_BUS_ID             IN OUT importers.bus_id%TYPE,
                                          P_CTRY_CD            IN OUT importers.ctry_cd%TYPE,
                                          P_ADD_CTRY_CD        IN OUT importers.add_ctry_cd%TYPE,
                                          P_IMPR_TYPE_NAME     IN OUT VARCHAR2,
                                          P_BUS_ID_TYPE_NAME   IN OUT VARCHAR2,
                                          P_CRTY_ARBC_NAME     IN OUT VARCHAR2,
                                          P_ITIDT_NOTE         IN OUT VARCHAR2,
                                          P_STATUS             IN OUT NUMBER,
                                          P_ADD_CRTY_ARBC_NAME IN OUT VARCHAR2,
                                          P_CURR_PORT_CD            IN     NUMBER)
    IS
        r T_RECORD;
        c T_CONTEXT;
    BEGIN
        c.curr_port_cd := P_CURR_PORT_CD;
        r.impr_nbr := P_IMPR_NBR;
        r.impr_type_cd := P_IMPR_TYPE_CD;
        r.bus_id_type_cd := P_BUS_ID_TYPE_CD;
        r.bus_id := P_BUS_ID;
        r.ctry_cd := P_CTRY_CD;
        r.add_ctry_cd := P_ADD_CTRY_CD;
        r.impr_type_name := P_IMPR_TYPE_NAME;
        r.bus_id_type_name := P_BUS_ID_TYPE_NAME;
        r.crty_arbc_name := P_CRTY_ARBC_NAME;
        r.itidt_note := P_ITIDT_NOTE;
        r.status := P_STATUS;
        r.add_crty_arbc_name := P_ADD_CRTY_ARBC_NAME;
        IMPR_TYPE_CD_POST_CHANGE(r);
        IMPR_TYPE_CD_VALIDATE_ITEM(r, c);
        P_IMPR_TYPE_CD := r.impr_type_cd;
        P_BUS_ID_TYPE_CD := r.bus_id_type_cd;
        P_BUS_ID := r.bus_id;
        P_CTRY_CD := r.ctry_cd;
        P_ADD_CTRY_CD := r.add_ctry_cd;
        P_IMPR_TYPE_NAME := r.impr_type_name;
        P_BUS_ID_TYPE_NAME := r.bus_id_type_name;
        P_CRTY_ARBC_NAME := r.crty_arbc_name;
        P_ITIDT_NOTE := r.itidt_note;
        P_STATUS := r.status;
        P_ADD_CRTY_ARBC_NAME := r.add_crty_arbc_name;
    END IMPR_TYPE_CD_VALIDATE_ITEM;

    -- Source: IMPORTERS.IMPR_TYPE_CD.WHEN-NEW-ITEM-INSTANCE
    -- APEX  : DA "IMPR_TYPE_CD WHEN-NEW-ITEM-INSTANCE": FOS, Items to Return = the IN OUT / OUT items
    PROCEDURE IMPR_TYPE_CD_NEW_ITEM_INSTANCE (P_IMPR_TYPE_CD        IN     importers.impr_type_cd%TYPE,
                                              P_BUS_ID_TYPE_CD      IN     importers.bus_id_type_cd%TYPE,
                                              P_CTRY_CD            IN OUT importers.ctry_cd%TYPE,
                                              P_ADD_CTRY_CD        IN OUT importers.add_ctry_cd%TYPE,
                                              P_CRTY_ARBC_NAME     IN OUT VARCHAR2,
                                              P_ADD_CRTY_ARBC_NAME IN OUT VARCHAR2)
    IS
        r T_RECORD;
    BEGIN
        r.impr_type_cd := P_IMPR_TYPE_CD;
        r.bus_id_type_cd := P_BUS_ID_TYPE_CD;
        r.ctry_cd := P_CTRY_CD;
        r.add_ctry_cd := P_ADD_CTRY_CD;
        r.crty_arbc_name := P_CRTY_ARBC_NAME;
        r.add_crty_arbc_name := P_ADD_CRTY_ARBC_NAME;
        IMPR_TYPE_CD_NEW_ITEM_INSTANCE(r);
        P_CTRY_CD := r.ctry_cd;
        P_ADD_CTRY_CD := r.add_ctry_cd;
        P_CRTY_ARBC_NAME := r.crty_arbc_name;
        P_ADD_CRTY_ARBC_NAME := r.add_crty_arbc_name;
    END IMPR_TYPE_CD_NEW_ITEM_INSTANCE;

    -- Source: IMPORTERS.IMPR_TYPE_CD.KEY-LISTVAL (values the LOV returns)
    -- APEX  : DA "IMPR_TYPE_CD KEY-LISTVAL": FOS, Items to Return = the IN OUT / OUT items
    PROCEDURE IMPR_TYPE_CD_LOV_RETURN (P_IMPR_TYPE_CD       IN OUT importers.impr_type_cd%TYPE,
                                       P_BUS_ID_TYPE_CD     IN OUT importers.bus_id_type_cd%TYPE,
                                       P_CTRY_CD            IN OUT importers.ctry_cd%TYPE,
                                       P_ADD_CTRY_CD        IN OUT importers.add_ctry_cd%TYPE,
                                       P_IMPR_TYPE_NAME     IN OUT VARCHAR2,
                                       P_BUS_ID_TYPE_NAME   IN OUT VARCHAR2,
                                       P_CRTY_ARBC_NAME     IN OUT VARCHAR2,
                                       P_ADD_CRTY_ARBC_NAME IN OUT VARCHAR2)
    IS
        r T_RECORD;
    BEGIN
        r.impr_type_cd := P_IMPR_TYPE_CD;
        r.bus_id_type_cd := P_BUS_ID_TYPE_CD;
        r.ctry_cd := P_CTRY_CD;
        r.add_ctry_cd := P_ADD_CTRY_CD;
        r.impr_type_name := P_IMPR_TYPE_NAME;
        r.bus_id_type_name := P_BUS_ID_TYPE_NAME;
        r.crty_arbc_name := P_CRTY_ARBC_NAME;
        r.add_crty_arbc_name := P_ADD_CRTY_ARBC_NAME;
        IMPR_TYPE_CD_LOV_RETURN(r);
        P_IMPR_TYPE_CD := r.impr_type_cd;
        P_BUS_ID_TYPE_CD := r.bus_id_type_cd;
        P_CTRY_CD := r.ctry_cd;
        P_ADD_CTRY_CD := r.add_ctry_cd;
        P_IMPR_TYPE_NAME := r.impr_type_name;
        P_BUS_ID_TYPE_NAME := r.bus_id_type_name;
        P_CRTY_ARBC_NAME := r.crty_arbc_name;
        P_ADD_CRTY_ARBC_NAME := r.add_crty_arbc_name;
    END IMPR_TYPE_CD_LOV_RETURN;

    -- Source: IMPORTERS.BUS_ID_EXPRD_DT.WHEN-VALIDATE-ITEM
    -- APEX  : Validation "BUS_ID_EXPRD_DT VALIDATION" (request CREATE / SAVE): returns the error text
    FUNCTION BUS_ID_EXPRD_DT_VALIDATION (P_BUS_ID_EXPRD_DT IN     VARCHAR2)
        RETURN VARCHAR2
    IS
        r T_RECORD;
    BEGIN
        r.bus_id_exprd_dt := TO_DATE(P_BUS_ID_EXPRD_DT, c_mask);
        BUS_ID_EXPRD_DT_VALIDATE_ITEM(r, FALSE);
        RETURN NULL;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN PRIVATE_ERROR_TEXT(SQLCODE, SQLERRM, CASE WHEN r.row_id IS NULL THEN 'I' ELSE 'U' END);
    END BUS_ID_EXPRD_DT_VALIDATION;

    -- Source: IMPORTERS.BUS_ID_EXPRD_DT.WHEN-VALIDATE-ITEM
    -- APEX  : DA "BUS_ID_EXPRD_DT WHEN-VALIDATE-ITEM" (Change): FOS, Items to Submit = the IN items, Items to Return = the IN OUT / OUT items
    PROCEDURE BUS_ID_EXPRD_DT_VALIDATE_ITEM (P_BUS_ID_EXPRD_DT IN     VARCHAR2)
    IS
        r T_RECORD;
    BEGIN
        r.bus_id_exprd_dt := TO_DATE(P_BUS_ID_EXPRD_DT, c_mask);
        BUS_ID_EXPRD_DT_VALIDATE_ITEM(r, TRUE);
    END BUS_ID_EXPRD_DT_VALIDATE_ITEM;

    -- Source: IMPORTERS.BUS_ID_TYPE_CD.POST-CHANGE
    -- APEX  : Validation "BUS_ID_TYPE_CD VALIDATION" (request CREATE / SAVE): returns the error text
    FUNCTION BUS_ID_TYPE_CD_VALIDATION (P_IMPR_TYPE_CD       IN     importers.impr_type_cd%TYPE,
                                        P_BUS_ID_TYPE_CD     IN     importers.bus_id_type_cd%TYPE,
                                        P_CTRY_CD            IN     importers.ctry_cd%TYPE,
                                        P_ADD_CTRY_CD        IN     importers.add_ctry_cd%TYPE,
                                        P_CRTY_ARBC_NAME     IN     VARCHAR2,
                                        P_ADD_CRTY_ARBC_NAME IN     VARCHAR2)
        RETURN VARCHAR2
    IS
        r T_RECORD;
    BEGIN
        r.impr_type_cd := P_IMPR_TYPE_CD;
        r.bus_id_type_cd := P_BUS_ID_TYPE_CD;
        r.ctry_cd := P_CTRY_CD;
        r.add_ctry_cd := P_ADD_CTRY_CD;
        r.crty_arbc_name := P_CRTY_ARBC_NAME;
        r.add_crty_arbc_name := P_ADD_CRTY_ARBC_NAME;
        BUS_ID_TYPE_CD_POST_CHANGE(r);
        RETURN NULL;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN PRIVATE_ERROR_TEXT(SQLCODE, SQLERRM, CASE WHEN r.row_id IS NULL THEN 'I' ELSE 'U' END);
    END BUS_ID_TYPE_CD_VALIDATION;

    -- Source: IMPORTERS.BUS_ID_TYPE_CD.POST-CHANGE
    -- APEX  : DA "BUS_ID_TYPE_CD WHEN-VALIDATE-ITEM" (Change): FOS, Items to Submit = the IN items, Items to Return = the IN OUT / OUT items
    PROCEDURE BUS_ID_TYPE_CD_VALIDATE_ITEM (P_IMPR_TYPE_CD        IN     importers.impr_type_cd%TYPE,
                                            P_BUS_ID_TYPE_CD      IN     importers.bus_id_type_cd%TYPE,
                                            P_CTRY_CD            IN OUT importers.ctry_cd%TYPE,
                                            P_ADD_CTRY_CD        IN OUT importers.add_ctry_cd%TYPE,
                                            P_CRTY_ARBC_NAME     IN OUT VARCHAR2,
                                            P_ADD_CRTY_ARBC_NAME IN OUT VARCHAR2)
    IS
        r T_RECORD;
    BEGIN
        r.impr_type_cd := P_IMPR_TYPE_CD;
        r.bus_id_type_cd := P_BUS_ID_TYPE_CD;
        r.ctry_cd := P_CTRY_CD;
        r.add_ctry_cd := P_ADD_CTRY_CD;
        r.crty_arbc_name := P_CRTY_ARBC_NAME;
        r.add_crty_arbc_name := P_ADD_CRTY_ARBC_NAME;
        BUS_ID_TYPE_CD_POST_CHANGE(r);
        P_CTRY_CD := r.ctry_cd;
        P_ADD_CTRY_CD := r.add_ctry_cd;
        P_CRTY_ARBC_NAME := r.crty_arbc_name;
        P_ADD_CRTY_ARBC_NAME := r.add_crty_arbc_name;
    END BUS_ID_TYPE_CD_VALIDATE_ITEM;

    -- Source: IMPORTERS.COMM_RGSTRTN_TYPE.WHEN-LIST-CHANGED
    -- APEX  : DA "COMM_RGSTRTN_TYPE WHEN-LIST-CHANGED": FOS, Items to Return = the IN OUT / OUT items
    PROCEDURE COMM_RGSTRTN_TYPE_LIST_CHANGED (P_COMM_RGSTRTN_TYPE IN     importers.comm_rgstrtn_type%TYPE,
                                              P_BUS_ID_BRNCH     IN OUT importers.bus_id_brnch%TYPE)
    IS
        r T_RECORD;
    BEGIN
        r.comm_rgstrtn_type := P_COMM_RGSTRTN_TYPE;
        r.bus_id_brnch := P_BUS_ID_BRNCH;
        COMM_RGSTRTN_TYPE_LIST_CHANGED(r);
        P_BUS_ID_BRNCH := r.bus_id_brnch;
    END COMM_RGSTRTN_TYPE_LIST_CHANGED;

    -- Source: IMPORTERS.CITY_CODE_OF_ID.WHEN-VALIDATE-ITEM
    -- APEX  : Validation "CITY_CODE_OF_ID VALIDATION" (request CREATE / SAVE): returns the error text
    FUNCTION CITY_CODE_OF_ID_VALIDATION (P_CITY_CODE_OF_ID   IN     importers.city_code_of_id%TYPE,
                                         P_CTRY_CD_OF_ID     IN     importers.ctry_cd_of_id%TYPE,
                                         P_ID_CITY_NAME      IN     VARCHAR2,
                                         P_ID_MINS_COMM_CD   IN     NUMBER,
                                         P_L_CT_CITY_STATUS2 IN     NUMBER,
                                         P_ROW_ID            IN     VARCHAR2)
        RETURN VARCHAR2
    IS
        r T_RECORD;
    BEGIN
        r.city_code_of_id := P_CITY_CODE_OF_ID;
        r.ctry_cd_of_id := P_CTRY_CD_OF_ID;
        r.id_city_name := P_ID_CITY_NAME;
        r.id_mins_comm_cd := P_ID_MINS_COMM_CD;
        r.l_ct_city_status2 := P_L_CT_CITY_STATUS2;
        r.row_id := P_ROW_ID;
        r.rec_status := CASE WHEN r.row_id IS NULL THEN 'NEW' ELSE 'QUERY' END;
        CITY_CODE_OF_ID_VALIDATE_ITEM(r);
        RETURN NULL;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN PRIVATE_ERROR_TEXT(SQLCODE, SQLERRM, CASE WHEN r.row_id IS NULL THEN 'I' ELSE 'U' END);
    END CITY_CODE_OF_ID_VALIDATION;

    -- Source: IMPORTERS.CITY_CODE_OF_ID.WHEN-VALIDATE-ITEM
    -- APEX  : DA "CITY_CODE_OF_ID WHEN-VALIDATE-ITEM" (Change): FOS, Items to Submit = the IN items, Items to Return = the IN OUT / OUT items
    PROCEDURE CITY_CODE_OF_ID_VALIDATE_ITEM (P_CITY_CODE_OF_ID   IN OUT importers.city_code_of_id%TYPE,
                                             P_CTRY_CD_OF_ID     IN OUT importers.ctry_cd_of_id%TYPE,
                                             P_ID_CITY_NAME      IN OUT VARCHAR2,
                                             P_ID_MINS_COMM_CD   IN OUT NUMBER,
                                             P_L_CT_CITY_STATUS2 IN OUT NUMBER,
                                             P_ROW_ID             IN     VARCHAR2)
    IS
        r T_RECORD;
    BEGIN
        r.city_code_of_id := P_CITY_CODE_OF_ID;
        r.ctry_cd_of_id := P_CTRY_CD_OF_ID;
        r.id_city_name := P_ID_CITY_NAME;
        r.id_mins_comm_cd := P_ID_MINS_COMM_CD;
        r.l_ct_city_status2 := P_L_CT_CITY_STATUS2;
        r.row_id := P_ROW_ID;
        r.rec_status := CASE WHEN r.row_id IS NULL THEN 'NEW' ELSE 'QUERY' END;
        CITY_CODE_OF_ID_VALIDATE_ITEM(r);
        P_CITY_CODE_OF_ID := r.city_code_of_id;
        P_CTRY_CD_OF_ID := r.ctry_cd_of_id;
        P_ID_CITY_NAME := r.id_city_name;
        P_ID_MINS_COMM_CD := r.id_mins_comm_cd;
        P_L_CT_CITY_STATUS2 := r.l_ct_city_status2;
    END CITY_CODE_OF_ID_VALIDATE_ITEM;

    -- Source: IMPORTERS.CITY_CODE_OF_ID.WHEN-NEW-ITEM-INSTANCE
    -- APEX  : DA "CITY_CODE_OF_ID WHEN-NEW-ITEM-INSTANCE": FOS, Items to Return = the IN OUT / OUT items
    PROCEDURE CITY_CODE_OF_ID_WHEN_NEW_ITEM (P_COMM_RGSTRTN_TYPE IN     importers.comm_rgstrtn_type%TYPE)
    IS
        r T_RECORD;
    BEGIN
        r.comm_rgstrtn_type := P_COMM_RGSTRTN_TYPE;
        CITY_CODE_OF_ID_WHEN_NEW_ITEM(r);
    END CITY_CODE_OF_ID_WHEN_NEW_ITEM;

    -- Source: IMPORTERS.BUS_ID.POST-CHANGE + WHEN-VALIDATE-ITEM
    -- APEX  : Validation "BUS_ID VALIDATION" (request CREATE / SAVE): returns the error text
    FUNCTION BUS_ID_VALIDATION (P_PORT_CD           IN     importers.port_cd%TYPE,
                                P_IMPR_NBR          IN     importers.impr_nbr%TYPE,
                                P_BUS_ID_STATUS     IN     importers.bus_id_status%TYPE,
                                P_IMPR_TYPE_CD      IN     importers.impr_type_cd%TYPE,
                                P_BUS_ID_EXPRD_DT   IN     VARCHAR2,
                                P_BUS_ID_TYPE_CD    IN     importers.bus_id_type_cd%TYPE,
                                P_COMM_RGSTRTN_TYPE IN     importers.comm_rgstrtn_type%TYPE,
                                P_CITY_CODE_OF_ID   IN     importers.city_code_of_id%TYPE,
                                P_BUS_ID            IN     importers.bus_id%TYPE,
                                P_BUS_ID_BRNCH      IN     importers.bus_id_brnch%TYPE,
                                P_CTRY_CD           IN     importers.ctry_cd%TYPE,
                                P_ARBC_IMPR_NAME    IN     importers.arbc_impr_name%TYPE,
                                P_IMPR_NAME_STD     IN     importers.impr_name_std%TYPE,
                                P_LST_TRAN_DT       IN     VARCHAR2,
                                P_IMPR_ADDRESS      IN     importers.impr_address%TYPE,
                                P_BUS_ID_ISSUE_DT   IN     VARCHAR2,
                                P_IMPR_POB_NBR      IN     importers.impr_pob_nbr%TYPE,
                                P_IMPR_ZIP_CD       IN     importers.impr_zip_cd%TYPE,
                                P_IMPR_TEL_NBR      IN     importers.impr_tel_nbr%TYPE,
                                P_IMPR_FAX_NBR      IN     importers.impr_fax_nbr%TYPE,
                                P_IMPR_TELEX_NBR    IN     importers.impr_telex_nbr%TYPE,
                                P_CTRY_CD_OF_ID     IN     importers.ctry_cd_of_id%TYPE,
                                P_ACTIVITY          IN     importers.activity%TYPE,
                                P_CREATION_FLAG     IN     importers.creation_flag%TYPE,
                                P_ID_CITY_NAME      IN     VARCHAR2,
                                P_ID_MINS_COMM_CD   IN     NUMBER,
                                P_BRNH_CITY_CD      IN     NUMBER,
                                P_BRNH_CITY_NAME    IN     VARCHAR2,
                                P_B_ID_NBR          IN     VARCHAR2,
                                P_ROW_ID            IN     VARCHAR2)
        RETURN VARCHAR2
    IS
        r T_RECORD;
        c T_CONTEXT;
    BEGIN
        r.port_cd := P_PORT_CD;
        r.impr_nbr := P_IMPR_NBR;
        r.bus_id_status := P_BUS_ID_STATUS;
        r.impr_type_cd := P_IMPR_TYPE_CD;
        r.bus_id_exprd_dt := TO_DATE(P_BUS_ID_EXPRD_DT, c_mask);
        r.bus_id_type_cd := P_BUS_ID_TYPE_CD;
        r.comm_rgstrtn_type := P_COMM_RGSTRTN_TYPE;
        r.city_code_of_id := P_CITY_CODE_OF_ID;
        r.bus_id := P_BUS_ID;
        r.bus_id_brnch := P_BUS_ID_BRNCH;
        r.ctry_cd := P_CTRY_CD;
        r.arbc_impr_name := P_ARBC_IMPR_NAME;
        r.impr_name_std := P_IMPR_NAME_STD;
        r.lst_tran_dt := TO_DATE(P_LST_TRAN_DT, c_date_time_mask);
        r.impr_address := P_IMPR_ADDRESS;
        r.bus_id_issue_dt := TO_DATE(P_BUS_ID_ISSUE_DT, c_mask);
        r.impr_pob_nbr := P_IMPR_POB_NBR;
        r.impr_zip_cd := P_IMPR_ZIP_CD;
        r.impr_tel_nbr := P_IMPR_TEL_NBR;
        r.impr_fax_nbr := P_IMPR_FAX_NBR;
        r.impr_telex_nbr := P_IMPR_TELEX_NBR;
        r.ctry_cd_of_id := P_CTRY_CD_OF_ID;
        r.activity := P_ACTIVITY;
        r.creation_flag := P_CREATION_FLAG;
        r.id_city_name := P_ID_CITY_NAME;
        r.id_mins_comm_cd := P_ID_MINS_COMM_CD;
        r.brnh_city_cd := P_BRNH_CITY_CD;
        r.brnh_city_name := P_BRNH_CITY_NAME;
        r.b_id_nbr := P_B_ID_NBR;
        r.row_id := P_ROW_ID;
        r.rec_status := CASE WHEN r.row_id IS NULL THEN 'NEW' ELSE 'QUERY' END;
        BUS_ID_POST_CHANGE;
        BUS_ID_WHEN_VALIDATE_ITEM(r, c, c_yes, c_yes);
        RETURN NULL;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN PRIVATE_ERROR_TEXT(SQLCODE, SQLERRM, CASE WHEN r.row_id IS NULL THEN 'I' ELSE 'U' END);
    END BUS_ID_VALIDATION;

    -- Source: IMPORTERS.BUS_ID.POST-CHANGE + WHEN-VALIDATE-ITEM
    -- APEX  : DA "BUS_ID WHEN-VALIDATE-ITEM" (Change): FOS, Items to Submit = the IN items, Items to Return = the IN OUT / OUT items
    PROCEDURE BUS_ID_WHEN_VALIDATE_ITEM (P_PORT_CD           IN     importers.port_cd%TYPE,
                                         P_IMPR_NBR          IN     importers.impr_nbr%TYPE,
                                         P_BUS_ID_STATUS    IN OUT importers.bus_id_status%TYPE,
                                         P_IMPR_TYPE_CD      IN     importers.impr_type_cd%TYPE,
                                         P_BUS_ID_EXPRD_DT  IN OUT VARCHAR2,
                                         P_BUS_ID_TYPE_CD    IN     importers.bus_id_type_cd%TYPE,
                                         P_COMM_RGSTRTN_TYPE IN     importers.comm_rgstrtn_type%TYPE,
                                         P_CITY_CODE_OF_ID  IN OUT importers.city_code_of_id%TYPE,
                                         P_BUS_ID           IN OUT importers.bus_id%TYPE,
                                         P_BUS_ID_BRNCH      IN     importers.bus_id_brnch%TYPE,
                                         P_CTRY_CD           IN     importers.ctry_cd%TYPE,
                                         P_ARBC_IMPR_NAME   IN OUT importers.arbc_impr_name%TYPE,
                                         P_IMPR_NAME_STD    IN OUT importers.impr_name_std%TYPE,
                                         P_LST_TRAN_DT      IN OUT VARCHAR2,
                                         P_IMPR_ADDRESS     IN OUT importers.impr_address%TYPE,
                                         P_BUS_ID_ISSUE_DT  IN OUT VARCHAR2,
                                         P_IMPR_POB_NBR     IN OUT importers.impr_pob_nbr%TYPE,
                                         P_IMPR_ZIP_CD      IN OUT importers.impr_zip_cd%TYPE,
                                         P_IMPR_TEL_NBR     IN OUT importers.impr_tel_nbr%TYPE,
                                         P_IMPR_FAX_NBR     IN OUT importers.impr_fax_nbr%TYPE,
                                         P_IMPR_TELEX_NBR   IN OUT importers.impr_telex_nbr%TYPE,
                                         P_CTRY_CD_OF_ID     IN     importers.ctry_cd_of_id%TYPE,
                                         P_ACTIVITY         IN OUT importers.activity%TYPE,
                                         P_CREATION_FLAG    IN OUT importers.creation_flag%TYPE,
                                         P_ID_CITY_NAME     IN OUT VARCHAR2,
                                         P_ID_MINS_COMM_CD  IN OUT NUMBER,
                                         P_BRNH_CITY_CD     IN OUT NUMBER,
                                         P_BRNH_CITY_NAME   IN OUT VARCHAR2,
                                         P_B_ID_NBR         IN OUT VARCHAR2,
                                         P_ROW_ID            IN     VARCHAR2,
                                         P_ANSWER            IN     PLS_INTEGER DEFAULT NULL,
                                         P_SUSPEND_ANSWER    IN     PLS_INTEGER DEFAULT NULL)
    IS
        r T_RECORD;
        c T_CONTEXT;
    BEGIN
        r.port_cd := P_PORT_CD;
        r.impr_nbr := P_IMPR_NBR;
        r.bus_id_status := P_BUS_ID_STATUS;
        r.impr_type_cd := P_IMPR_TYPE_CD;
        r.bus_id_exprd_dt := TO_DATE(P_BUS_ID_EXPRD_DT, c_mask);
        r.bus_id_type_cd := P_BUS_ID_TYPE_CD;
        r.comm_rgstrtn_type := P_COMM_RGSTRTN_TYPE;
        r.city_code_of_id := P_CITY_CODE_OF_ID;
        r.bus_id := P_BUS_ID;
        r.bus_id_brnch := P_BUS_ID_BRNCH;
        r.ctry_cd := P_CTRY_CD;
        r.arbc_impr_name := P_ARBC_IMPR_NAME;
        r.impr_name_std := P_IMPR_NAME_STD;
        r.lst_tran_dt := TO_DATE(P_LST_TRAN_DT, c_date_time_mask);
        r.impr_address := P_IMPR_ADDRESS;
        r.bus_id_issue_dt := TO_DATE(P_BUS_ID_ISSUE_DT, c_mask);
        r.impr_pob_nbr := P_IMPR_POB_NBR;
        r.impr_zip_cd := P_IMPR_ZIP_CD;
        r.impr_tel_nbr := P_IMPR_TEL_NBR;
        r.impr_fax_nbr := P_IMPR_FAX_NBR;
        r.impr_telex_nbr := P_IMPR_TELEX_NBR;
        r.ctry_cd_of_id := P_CTRY_CD_OF_ID;
        r.activity := P_ACTIVITY;
        r.creation_flag := P_CREATION_FLAG;
        r.id_city_name := P_ID_CITY_NAME;
        r.id_mins_comm_cd := P_ID_MINS_COMM_CD;
        r.brnh_city_cd := P_BRNH_CITY_CD;
        r.brnh_city_name := P_BRNH_CITY_NAME;
        r.b_id_nbr := P_B_ID_NBR;
        r.row_id := P_ROW_ID;
        r.rec_status := CASE WHEN r.row_id IS NULL THEN 'NEW' ELSE 'QUERY' END;
        BUS_ID_POST_CHANGE;
        BUS_ID_WHEN_VALIDATE_ITEM(r, c, NVL(P_ANSWER, c_yes), NVL(P_SUSPEND_ANSWER, c_yes));
        P_BUS_ID_STATUS := r.bus_id_status;
        P_BUS_ID_EXPRD_DT := TO_CHAR(r.bus_id_exprd_dt, c_mask);
        P_CITY_CODE_OF_ID := r.city_code_of_id;
        P_BUS_ID := r.bus_id;
        P_ARBC_IMPR_NAME := r.arbc_impr_name;
        P_IMPR_NAME_STD := r.impr_name_std;
        P_LST_TRAN_DT := TO_CHAR(r.lst_tran_dt, c_date_time_mask);
        P_IMPR_ADDRESS := r.impr_address;
        P_BUS_ID_ISSUE_DT := TO_CHAR(r.bus_id_issue_dt, c_mask);
        P_IMPR_POB_NBR := r.impr_pob_nbr;
        P_IMPR_ZIP_CD := r.impr_zip_cd;
        P_IMPR_TEL_NBR := r.impr_tel_nbr;
        P_IMPR_FAX_NBR := r.impr_fax_nbr;
        P_IMPR_TELEX_NBR := r.impr_telex_nbr;
        P_ACTIVITY := r.activity;
        P_CREATION_FLAG := r.creation_flag;
        P_ID_CITY_NAME := r.id_city_name;
        P_ID_MINS_COMM_CD := r.id_mins_comm_cd;
        P_BRNH_CITY_CD := r.brnh_city_cd;
        P_BRNH_CITY_NAME := r.brnh_city_name;
        P_B_ID_NBR := r.b_id_nbr;
    END BUS_ID_WHEN_VALIDATE_ITEM;

    -- Source: IMPORTERS.BUS_ID.WHEN-NEW-ITEM-INSTANCE
    -- APEX  : DA "BUS_ID WHEN-NEW-ITEM-INSTANCE": FOS, Items to Return = the IN OUT / OUT items
    PROCEDURE BUS_ID_WHEN_NEW_ITEM_INSTANCE (P_IMPR_TYPE_CD      IN     importers.impr_type_cd%TYPE,
                                             P_BUS_ID_TYPE_CD    IN     importers.bus_id_type_cd%TYPE,
                                             P_COMM_RGSTRTN_TYPE IN     importers.comm_rgstrtn_type%TYPE,
                                             P_CITY_CODE_OF_ID   IN     importers.city_code_of_id%TYPE,
                                             P_BUS_ID            IN     importers.bus_id%TYPE,
                                             P_ID_MINS_COMM_CD   IN     NUMBER)
    IS
        r T_RECORD;
    BEGIN
        r.impr_type_cd := P_IMPR_TYPE_CD;
        r.bus_id_type_cd := P_BUS_ID_TYPE_CD;
        r.comm_rgstrtn_type := P_COMM_RGSTRTN_TYPE;
        r.city_code_of_id := P_CITY_CODE_OF_ID;
        r.bus_id := P_BUS_ID;
        r.id_mins_comm_cd := P_ID_MINS_COMM_CD;
        BUS_ID_WHEN_NEW_ITEM_INSTANCE(r);
    END BUS_ID_WHEN_NEW_ITEM_INSTANCE;

    -- Source: IMPORTERS.BUS_ID.WHEN-VALIDATE-ITEM, question "يوجد مستورد ... موقوف له نفس الرقم الإستدلالي"
    -- APEX  : FOS before "BUS_ID WHEN-VALIDATE-ITEM": returns P1110_CONFIRM_TEXT; Confirm sets P1110_SUSPEND_ANSWER
    FUNCTION BUS_ID_SUSPENDED_CONFIRM_TEXT (P_PORT_CD           IN     importers.port_cd%TYPE,
                                            P_IMPR_NBR          IN     importers.impr_nbr%TYPE,
                                            P_BUS_ID_TYPE_CD    IN     importers.bus_id_type_cd%TYPE,
                                            P_COMM_RGSTRTN_TYPE IN     importers.comm_rgstrtn_type%TYPE,
                                            P_BUS_ID            IN     importers.bus_id%TYPE,
                                            P_BUS_ID_BRNCH      IN     importers.bus_id_brnch%TYPE,
                                            P_CTRY_CD           IN     importers.ctry_cd%TYPE)
        RETURN VARCHAR2
    IS
        r T_RECORD;
        v_importer NUMBER;
    BEGIN
        r.port_cd := P_PORT_CD;
        r.impr_nbr := P_IMPR_NBR;
        r.bus_id_type_cd := P_BUS_ID_TYPE_CD;
        r.comm_rgstrtn_type := P_COMM_RGSTRTN_TYPE;
        r.bus_id := P_BUS_ID;
        r.bus_id_brnch := P_BUS_ID_BRNCH;
        r.ctry_cd := P_CTRY_CD;
        v_importer := BUS_ID_SUSPENDED_IMPORTER(r);
        RETURN CASE WHEN v_importer <> 0 THEN 'يوجد مستورد' || v_importer || ' موقوف له نفس الرقم الإستدلالي" هل تريد تعديل الرقم الاستدلالي بالرغم من ذلك ؟' END;
    END BUS_ID_SUSPENDED_CONFIRM_TEXT;

    -- Source: IMPORTERS.BRNH_CITY_CD.WHEN-VALIDATE-ITEM
    -- APEX  : Validation "BRNH_CITY_CD VALIDATION" (request CREATE / SAVE): returns the error text
    FUNCTION BRNH_CITY_CD_VALIDATION (P_CTRY_CD_OF_ID  IN     importers.ctry_cd_of_id%TYPE,
                                      P_BRNH_CITY_CD   IN     NUMBER,
                                      P_BRNH_CITY_NAME IN     VARCHAR2)
        RETURN VARCHAR2
    IS
        r T_RECORD;
    BEGIN
        r.ctry_cd_of_id := P_CTRY_CD_OF_ID;
        r.brnh_city_cd := P_BRNH_CITY_CD;
        r.brnh_city_name := P_BRNH_CITY_NAME;
        BRNH_CITY_CD_VALIDATE_ITEM(r);
        RETURN NULL;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN PRIVATE_ERROR_TEXT(SQLCODE, SQLERRM, CASE WHEN r.row_id IS NULL THEN 'I' ELSE 'U' END);
    END BRNH_CITY_CD_VALIDATION;

    -- Source: IMPORTERS.BRNH_CITY_CD.WHEN-VALIDATE-ITEM
    -- APEX  : DA "BRNH_CITY_CD WHEN-VALIDATE-ITEM" (Change): FOS, Items to Submit = the IN items, Items to Return = the IN OUT / OUT items
    PROCEDURE BRNH_CITY_CD_VALIDATE_ITEM (P_CTRY_CD_OF_ID   IN     importers.ctry_cd_of_id%TYPE,
                                          P_BRNH_CITY_CD    IN     NUMBER,
                                          P_BRNH_CITY_NAME IN OUT VARCHAR2)
    IS
        r T_RECORD;
    BEGIN
        r.ctry_cd_of_id := P_CTRY_CD_OF_ID;
        r.brnh_city_cd := P_BRNH_CITY_CD;
        r.brnh_city_name := P_BRNH_CITY_NAME;
        BRNH_CITY_CD_VALIDATE_ITEM(r);
        P_BRNH_CITY_NAME := r.brnh_city_name;
    END BRNH_CITY_CD_VALIDATE_ITEM;

    -- Source: IMPORTERS.BUS_ID_BRNCH.POST-CHANGE + WHEN-VALIDATE-ITEM
    -- APEX  : Validation "BUS_ID_BRNCH VALIDATION" (request CREATE / SAVE): returns the error text
    FUNCTION BUS_ID_BRNCH_VALIDATION (P_PORT_CD              IN     importers.port_cd%TYPE,
                                      P_IMPR_NBR             IN     importers.impr_nbr%TYPE,
                                      P_BUS_ID_STATUS        IN     importers.bus_id_status%TYPE,
                                      P_IMPR_TYPE_CD         IN     importers.impr_type_cd%TYPE,
                                      P_BUS_ID_EXPRD_DT      IN     VARCHAR2,
                                      P_BUS_ID_TYPE_CD       IN     importers.bus_id_type_cd%TYPE,
                                      P_COMM_RGSTRTN_TYPE    IN     importers.comm_rgstrtn_type%TYPE,
                                      P_CITY_CODE_OF_ID      IN     importers.city_code_of_id%TYPE,
                                      P_BUS_ID               IN     importers.bus_id%TYPE,
                                      P_BUS_ID_BRNCH         IN     importers.bus_id_brnch%TYPE,
                                      P_CTRY_CD              IN     importers.ctry_cd%TYPE,
                                      P_ARBC_IMPR_NAME       IN     importers.arbc_impr_name%TYPE,
                                      P_IMPR_NAME_STD        IN     importers.impr_name_std%TYPE,
                                      P_LST_TRAN_DT          IN     VARCHAR2,
                                      P_IMPR_ADDRESS         IN     importers.impr_address%TYPE,
                                      P_BUS_ID_ISSUE_DT      IN     VARCHAR2,
                                      P_IMPR_POB_NBR         IN     importers.impr_pob_nbr%TYPE,
                                      P_IMPR_ZIP_CD          IN     importers.impr_zip_cd%TYPE,
                                      P_IMPR_TEL_NBR         IN     importers.impr_tel_nbr%TYPE,
                                      P_IMPR_FAX_NBR         IN     importers.impr_fax_nbr%TYPE,
                                      P_IMPR_TELEX_NBR       IN     importers.impr_telex_nbr%TYPE,
                                      P_CTRY_CD_OF_ID        IN     importers.ctry_cd_of_id%TYPE,
                                      P_ACTIVITY             IN     importers.activity%TYPE,
                                      P_CREATION_FLAG        IN     importers.creation_flag%TYPE,
                                      P_ID_CITY_NAME         IN     VARCHAR2,
                                      P_BRNH_ID_MINS_COMM_CD IN     NUMBER,
                                      P_BRNH_CITY_CD         IN     NUMBER,
                                      P_BRNH_CITY_NAME       IN     VARCHAR2,
                                      P_ROW_ID               IN     VARCHAR2,
                                      P_P_CODE               IN     VARCHAR2)
        RETURN VARCHAR2
    IS
        r T_RECORD;
        c T_CONTEXT;
    BEGIN
        c.code := P_P_CODE;
        r.port_cd := P_PORT_CD;
        r.impr_nbr := P_IMPR_NBR;
        r.bus_id_status := P_BUS_ID_STATUS;
        r.impr_type_cd := P_IMPR_TYPE_CD;
        r.bus_id_exprd_dt := TO_DATE(P_BUS_ID_EXPRD_DT, c_mask);
        r.bus_id_type_cd := P_BUS_ID_TYPE_CD;
        r.comm_rgstrtn_type := P_COMM_RGSTRTN_TYPE;
        r.city_code_of_id := P_CITY_CODE_OF_ID;
        r.bus_id := P_BUS_ID;
        r.bus_id_brnch := P_BUS_ID_BRNCH;
        r.ctry_cd := P_CTRY_CD;
        r.arbc_impr_name := P_ARBC_IMPR_NAME;
        r.impr_name_std := P_IMPR_NAME_STD;
        r.lst_tran_dt := TO_DATE(P_LST_TRAN_DT, c_date_time_mask);
        r.impr_address := P_IMPR_ADDRESS;
        r.bus_id_issue_dt := TO_DATE(P_BUS_ID_ISSUE_DT, c_mask);
        r.impr_pob_nbr := P_IMPR_POB_NBR;
        r.impr_zip_cd := P_IMPR_ZIP_CD;
        r.impr_tel_nbr := P_IMPR_TEL_NBR;
        r.impr_fax_nbr := P_IMPR_FAX_NBR;
        r.impr_telex_nbr := P_IMPR_TELEX_NBR;
        r.ctry_cd_of_id := P_CTRY_CD_OF_ID;
        r.activity := P_ACTIVITY;
        r.creation_flag := P_CREATION_FLAG;
        r.id_city_name := P_ID_CITY_NAME;
        r.brnh_id_mins_comm_cd := P_BRNH_ID_MINS_COMM_CD;
        r.brnh_city_cd := P_BRNH_CITY_CD;
        r.brnh_city_name := P_BRNH_CITY_NAME;
        r.row_id := P_ROW_ID;
        r.rec_status := CASE WHEN r.row_id IS NULL THEN 'NEW' ELSE 'QUERY' END;
        r.bus_id_brnch_entr := CASE WHEN BUS_ID_BRNCH_IS_READ_ONLY(r.impr_nbr, P_P_CODE, r.impr_type_cd,
                                            r.bus_id_type_cd, r.comm_rgstrtn_type) THEN 'N' ELSE 'Y' END;
        BUS_ID_BRNCH_POST_CHANGE;
        BUS_ID_BRNCH_VALIDATE_ITEM(r, c, c_yes);
        RETURN NULL;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN PRIVATE_ERROR_TEXT(SQLCODE, SQLERRM, CASE WHEN r.row_id IS NULL THEN 'I' ELSE 'U' END);
    END BUS_ID_BRNCH_VALIDATION;

    -- Source: IMPORTERS.BUS_ID_BRNCH.POST-CHANGE + WHEN-VALIDATE-ITEM
    -- APEX  : DA "BUS_ID_BRNCH WHEN-VALIDATE-ITEM" (Change): FOS, Items to Submit = the IN items, Items to Return = the IN OUT / OUT items
    PROCEDURE BUS_ID_BRNCH_VALIDATE_ITEM (P_PORT_CD               IN     importers.port_cd%TYPE,
                                          P_IMPR_NBR              IN     importers.impr_nbr%TYPE,
                                          P_BUS_ID_STATUS        IN OUT importers.bus_id_status%TYPE,
                                          P_IMPR_TYPE_CD          IN     importers.impr_type_cd%TYPE,
                                          P_BUS_ID_EXPRD_DT      IN OUT VARCHAR2,
                                          P_BUS_ID_TYPE_CD        IN     importers.bus_id_type_cd%TYPE,
                                          P_COMM_RGSTRTN_TYPE     IN     importers.comm_rgstrtn_type%TYPE,
                                          P_CITY_CODE_OF_ID      IN OUT importers.city_code_of_id%TYPE,
                                          P_BUS_ID                IN     importers.bus_id%TYPE,
                                          P_BUS_ID_BRNCH         IN OUT importers.bus_id_brnch%TYPE,
                                          P_CTRY_CD               IN     importers.ctry_cd%TYPE,
                                          P_ARBC_IMPR_NAME       IN OUT importers.arbc_impr_name%TYPE,
                                          P_IMPR_NAME_STD        IN OUT importers.impr_name_std%TYPE,
                                          P_LST_TRAN_DT          IN OUT VARCHAR2,
                                          P_IMPR_ADDRESS         IN OUT importers.impr_address%TYPE,
                                          P_BUS_ID_ISSUE_DT      IN OUT VARCHAR2,
                                          P_IMPR_POB_NBR         IN OUT importers.impr_pob_nbr%TYPE,
                                          P_IMPR_ZIP_CD          IN OUT importers.impr_zip_cd%TYPE,
                                          P_IMPR_TEL_NBR         IN OUT importers.impr_tel_nbr%TYPE,
                                          P_IMPR_FAX_NBR         IN OUT importers.impr_fax_nbr%TYPE,
                                          P_IMPR_TELEX_NBR       IN OUT importers.impr_telex_nbr%TYPE,
                                          P_CTRY_CD_OF_ID         IN     importers.ctry_cd_of_id%TYPE,
                                          P_ACTIVITY             IN OUT importers.activity%TYPE,
                                          P_CREATION_FLAG        IN OUT importers.creation_flag%TYPE,
                                          P_ID_CITY_NAME         IN OUT VARCHAR2,
                                          P_BRNH_ID_MINS_COMM_CD IN OUT NUMBER,
                                          P_BRNH_CITY_CD         IN OUT NUMBER,
                                          P_BRNH_CITY_NAME       IN OUT VARCHAR2,
                                          P_ROW_ID                IN     VARCHAR2,
                                          P_P_CODE                IN     VARCHAR2,
                                          P_ANSWER                IN     PLS_INTEGER DEFAULT NULL)
    IS
        r T_RECORD;
        c T_CONTEXT;
    BEGIN
        c.code := P_P_CODE;
        r.port_cd := P_PORT_CD;
        r.impr_nbr := P_IMPR_NBR;
        r.bus_id_status := P_BUS_ID_STATUS;
        r.impr_type_cd := P_IMPR_TYPE_CD;
        r.bus_id_exprd_dt := TO_DATE(P_BUS_ID_EXPRD_DT, c_mask);
        r.bus_id_type_cd := P_BUS_ID_TYPE_CD;
        r.comm_rgstrtn_type := P_COMM_RGSTRTN_TYPE;
        r.city_code_of_id := P_CITY_CODE_OF_ID;
        r.bus_id := P_BUS_ID;
        r.bus_id_brnch := P_BUS_ID_BRNCH;
        r.ctry_cd := P_CTRY_CD;
        r.arbc_impr_name := P_ARBC_IMPR_NAME;
        r.impr_name_std := P_IMPR_NAME_STD;
        r.lst_tran_dt := TO_DATE(P_LST_TRAN_DT, c_date_time_mask);
        r.impr_address := P_IMPR_ADDRESS;
        r.bus_id_issue_dt := TO_DATE(P_BUS_ID_ISSUE_DT, c_mask);
        r.impr_pob_nbr := P_IMPR_POB_NBR;
        r.impr_zip_cd := P_IMPR_ZIP_CD;
        r.impr_tel_nbr := P_IMPR_TEL_NBR;
        r.impr_fax_nbr := P_IMPR_FAX_NBR;
        r.impr_telex_nbr := P_IMPR_TELEX_NBR;
        r.ctry_cd_of_id := P_CTRY_CD_OF_ID;
        r.activity := P_ACTIVITY;
        r.creation_flag := P_CREATION_FLAG;
        r.id_city_name := P_ID_CITY_NAME;
        r.brnh_id_mins_comm_cd := P_BRNH_ID_MINS_COMM_CD;
        r.brnh_city_cd := P_BRNH_CITY_CD;
        r.brnh_city_name := P_BRNH_CITY_NAME;
        r.row_id := P_ROW_ID;
        r.rec_status := CASE WHEN r.row_id IS NULL THEN 'NEW' ELSE 'QUERY' END;
        r.bus_id_brnch_entr := CASE WHEN BUS_ID_BRNCH_IS_READ_ONLY(r.impr_nbr, P_P_CODE, r.impr_type_cd,
                                            r.bus_id_type_cd, r.comm_rgstrtn_type) THEN 'N' ELSE 'Y' END;
        BUS_ID_BRNCH_POST_CHANGE;
        BUS_ID_BRNCH_VALIDATE_ITEM(r, c, NVL(P_ANSWER, c_yes));
        P_BUS_ID_STATUS := r.bus_id_status;
        P_BUS_ID_EXPRD_DT := TO_CHAR(r.bus_id_exprd_dt, c_mask);
        P_CITY_CODE_OF_ID := r.city_code_of_id;
        P_BUS_ID_BRNCH := r.bus_id_brnch;
        P_ARBC_IMPR_NAME := r.arbc_impr_name;
        P_IMPR_NAME_STD := r.impr_name_std;
        P_LST_TRAN_DT := TO_CHAR(r.lst_tran_dt, c_date_time_mask);
        P_IMPR_ADDRESS := r.impr_address;
        P_BUS_ID_ISSUE_DT := TO_CHAR(r.bus_id_issue_dt, c_mask);
        P_IMPR_POB_NBR := r.impr_pob_nbr;
        P_IMPR_ZIP_CD := r.impr_zip_cd;
        P_IMPR_TEL_NBR := r.impr_tel_nbr;
        P_IMPR_FAX_NBR := r.impr_fax_nbr;
        P_IMPR_TELEX_NBR := r.impr_telex_nbr;
        P_ACTIVITY := r.activity;
        P_CREATION_FLAG := r.creation_flag;
        P_ID_CITY_NAME := r.id_city_name;
        P_BRNH_ID_MINS_COMM_CD := r.brnh_id_mins_comm_cd;
        P_BRNH_CITY_CD := r.brnh_city_cd;
        P_BRNH_CITY_NAME := r.brnh_city_name;
    END BUS_ID_BRNCH_VALIDATE_ITEM;

    -- Source: IMPORTERS.BUS_ID_BRNCH.WHEN-NEW-ITEM-INSTANCE
    -- APEX  : DA "BUS_ID_BRNCH WHEN-NEW-ITEM-INSTANCE": FOS, Items to Return = the IN OUT / OUT items
    PROCEDURE BUS_ID_BRNCH_NEW_ITEM_INSTANCE (P_IMPR_TYPE_CD    IN     importers.impr_type_cd%TYPE,
                                              P_BUS_ID_TYPE_CD  IN     importers.bus_id_type_cd%TYPE,
                                              P_CITY_CODE_OF_ID IN     importers.city_code_of_id%TYPE,
                                              P_BUS_ID          IN     importers.bus_id%TYPE,
                                              P_BUS_ID_BRNCH    IN     importers.bus_id_brnch%TYPE,
                                              P_CITY_CODE       IN     importers.city_code%TYPE,
                                              P_BRNH_CITY_CD    IN     NUMBER)
    IS
        r T_RECORD;
    BEGIN
        r.impr_type_cd := P_IMPR_TYPE_CD;
        r.bus_id_type_cd := P_BUS_ID_TYPE_CD;
        r.city_code_of_id := P_CITY_CODE_OF_ID;
        r.bus_id := P_BUS_ID;
        r.bus_id_brnch := P_BUS_ID_BRNCH;
        r.city_code := P_CITY_CODE;
        r.brnh_city_cd := P_BRNH_CITY_CD;
        BUS_ID_BRNCH_NEW_ITEM_INSTANCE(r);
    END BUS_ID_BRNCH_NEW_ITEM_INSTANCE;

    -- Source: IMPORTERS.CTRY_CD.WHEN-VALIDATE-ITEM
    -- APEX  : Validation "CTRY_CD VALIDATION" (request CREATE / SAVE): returns the error text
    FUNCTION CTRY_CD_VALIDATION (P_IMPR_TYPE_CD     IN     importers.impr_type_cd%TYPE,
                                 P_BUS_ID_TYPE_CD   IN     importers.bus_id_type_cd%TYPE,
                                 P_CTRY_CD          IN     importers.ctry_cd%TYPE,
                                 P_CTRY_CD_OF_ID    IN     importers.ctry_cd_of_id%TYPE,
                                 P_CRTY_ARBC_NAME   IN     VARCHAR2,
                                 P_CTRY_CTRY_STATUS IN     NUMBER)
        RETURN VARCHAR2
    IS
        r T_RECORD;
    BEGIN
        r.impr_type_cd := P_IMPR_TYPE_CD;
        r.bus_id_type_cd := P_BUS_ID_TYPE_CD;
        r.ctry_cd := P_CTRY_CD;
        r.ctry_cd_of_id := P_CTRY_CD_OF_ID;
        r.crty_arbc_name := P_CRTY_ARBC_NAME;
        r.ctry_ctry_status := P_CTRY_CTRY_STATUS;
        CTRY_CD_WHEN_VALIDATE_ITEM(r);
        RETURN NULL;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN PRIVATE_ERROR_TEXT(SQLCODE, SQLERRM, CASE WHEN r.row_id IS NULL THEN 'I' ELSE 'U' END);
    END CTRY_CD_VALIDATION;

    -- Source: IMPORTERS.CTRY_CD.WHEN-VALIDATE-ITEM
    -- APEX  : DA "CTRY_CD WHEN-VALIDATE-ITEM" (Change): FOS, Items to Submit = the IN items, Items to Return = the IN OUT / OUT items
    PROCEDURE CTRY_CD_WHEN_VALIDATE_ITEM (P_IMPR_TYPE_CD      IN     importers.impr_type_cd%TYPE,
                                          P_BUS_ID_TYPE_CD    IN     importers.bus_id_type_cd%TYPE,
                                          P_CTRY_CD           IN     importers.ctry_cd%TYPE,
                                          P_CTRY_CD_OF_ID    IN OUT importers.ctry_cd_of_id%TYPE,
                                          P_CRTY_ARBC_NAME   IN OUT VARCHAR2,
                                          P_CTRY_CTRY_STATUS IN OUT NUMBER)
    IS
        r T_RECORD;
    BEGIN
        r.impr_type_cd := P_IMPR_TYPE_CD;
        r.bus_id_type_cd := P_BUS_ID_TYPE_CD;
        r.ctry_cd := P_CTRY_CD;
        r.ctry_cd_of_id := P_CTRY_CD_OF_ID;
        r.crty_arbc_name := P_CRTY_ARBC_NAME;
        r.ctry_ctry_status := P_CTRY_CTRY_STATUS;
        CTRY_CD_WHEN_VALIDATE_ITEM(r);
        P_CTRY_CD_OF_ID := r.ctry_cd_of_id;
        P_CRTY_ARBC_NAME := r.crty_arbc_name;
        P_CTRY_CTRY_STATUS := r.ctry_ctry_status;
    END CTRY_CD_WHEN_VALIDATE_ITEM;

    -- Source: IMPORTERS.IMPR_EXPR_TYPE.POST-CHANGE
    -- APEX  : Validation "IMPR_EXPR_TYPE VALIDATION" (request CREATE / SAVE): returns the error text
    FUNCTION IMPR_EXPR_TYPE_VALIDATION
        RETURN VARCHAR2
    IS
        r T_RECORD;
    BEGIN
        IMPR_EXPR_TYPE_POST_CHANGE;
        RETURN NULL;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN PRIVATE_ERROR_TEXT(SQLCODE, SQLERRM, CASE WHEN r.row_id IS NULL THEN 'I' ELSE 'U' END);
    END IMPR_EXPR_TYPE_VALIDATION;

    -- Source: IMPORTERS.IMPR_EXPR_TYPE.POST-CHANGE
    -- APEX  : DA "IMPR_EXPR_TYPE WHEN-VALIDATE-ITEM" (Change): FOS, Items to Submit = the IN items, Items to Return = the IN OUT / OUT items
    PROCEDURE IMPR_EXPR_TYPE_VALIDATE_ITEM
    IS

    BEGIN
        IMPR_EXPR_TYPE_POST_CHANGE;
    END IMPR_EXPR_TYPE_VALIDATE_ITEM;

    -- Source: IMPORTERS.ARBC_IMPR_NAME.WHEN-VALIDATE-ITEM
    -- APEX  : Validation "ARBC_IMPR_NAME VALIDATION" (request CREATE / SAVE): returns the error text
    FUNCTION ARBC_IMPR_NAME_VALIDATION (P_ARBC_IMPR_NAME IN     importers.arbc_impr_name%TYPE,
                                        P_IMPR_NAME_STD  IN     importers.impr_name_std%TYPE)
        RETURN VARCHAR2
    IS
        r T_RECORD;
    BEGIN
        r.arbc_impr_name := P_ARBC_IMPR_NAME;
        r.impr_name_std := P_IMPR_NAME_STD;
        ARBC_IMPR_NAME_VALIDATE_ITEM(r);
        RETURN NULL;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN PRIVATE_ERROR_TEXT(SQLCODE, SQLERRM, CASE WHEN r.row_id IS NULL THEN 'I' ELSE 'U' END);
    END ARBC_IMPR_NAME_VALIDATION;

    -- Source: IMPORTERS.ARBC_IMPR_NAME.WHEN-VALIDATE-ITEM
    -- APEX  : DA "ARBC_IMPR_NAME WHEN-VALIDATE-ITEM" (Change): FOS, Items to Submit = the IN items, Items to Return = the IN OUT / OUT items
    PROCEDURE ARBC_IMPR_NAME_VALIDATE_ITEM (P_ARBC_IMPR_NAME IN OUT importers.arbc_impr_name%TYPE,
                                            P_IMPR_NAME_STD  IN OUT importers.impr_name_std%TYPE)
    IS
        r T_RECORD;
    BEGIN
        r.arbc_impr_name := P_ARBC_IMPR_NAME;
        r.impr_name_std := P_IMPR_NAME_STD;
        ARBC_IMPR_NAME_VALIDATE_ITEM(r);
        P_ARBC_IMPR_NAME := r.arbc_impr_name;
        P_IMPR_NAME_STD := r.impr_name_std;
    END ARBC_IMPR_NAME_VALIDATE_ITEM;

    -- Source: IMPORTERS.ARBC_IMPR_NAME.KEY-NEXT-ITEM
    -- APEX  : DA "ARBC_IMPR_NAME KEY-NEXT-ITEM": FOS, Items to Return = the IN OUT / OUT items
    PROCEDURE ARBC_IMPR_NAME_KEY_NEXT_ITEM (P_CTRY_CD             IN     importers.ctry_cd%TYPE,
                                            P_ADD_CTRY_CD        IN OUT importers.add_ctry_cd%TYPE,
                                            P_CITY_CODE          IN OUT importers.city_code%TYPE,
                                            P_IMPR_TEL_NBR       IN OUT importers.impr_tel_nbr%TYPE,
                                            P_ADD_CRTY_ARBC_NAME IN OUT VARCHAR2,
                                            P_CITY_NAME          IN OUT VARCHAR2)
    IS
        r T_RECORD;
    BEGIN
        r.ctry_cd := P_CTRY_CD;
        r.add_ctry_cd := P_ADD_CTRY_CD;
        r.city_code := P_CITY_CODE;
        r.impr_tel_nbr := P_IMPR_TEL_NBR;
        r.add_crty_arbc_name := P_ADD_CRTY_ARBC_NAME;
        r.city_name := P_CITY_NAME;
        ARBC_IMPR_NAME_KEY_NEXT_ITEM(r);
        P_ADD_CTRY_CD := r.add_ctry_cd;
        P_CITY_CODE := r.city_code;
        P_IMPR_TEL_NBR := r.impr_tel_nbr;
        P_ADD_CRTY_ARBC_NAME := r.add_crty_arbc_name;
        P_CITY_NAME := r.city_name;
    END ARBC_IMPR_NAME_KEY_NEXT_ITEM;

    -- Source: IMPORTERS.ENG_IMPR_NAME.WHEN-VALIDATE-ITEM
    -- APEX  : Validation "ENG_IMPR_NAME VALIDATION" (request CREATE / SAVE): returns the error text
    FUNCTION ENG_IMPR_NAME_VALIDATION (P_ENG_IMPR_NAME IN     importers.eng_impr_name%TYPE)
        RETURN VARCHAR2
    IS
        r T_RECORD;
    BEGIN
        r.eng_impr_name := P_ENG_IMPR_NAME;
        ENG_IMPR_NAME_VALIDATE_ITEM(r);
        RETURN NULL;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN PRIVATE_ERROR_TEXT(SQLCODE, SQLERRM, CASE WHEN r.row_id IS NULL THEN 'I' ELSE 'U' END);
    END ENG_IMPR_NAME_VALIDATION;

    -- Source: IMPORTERS.ENG_IMPR_NAME.WHEN-VALIDATE-ITEM
    -- APEX  : DA "ENG_IMPR_NAME WHEN-VALIDATE-ITEM" (Change): FOS, Items to Submit = the IN items, Items to Return = the IN OUT / OUT items
    PROCEDURE ENG_IMPR_NAME_VALIDATE_ITEM (P_ENG_IMPR_NAME IN OUT importers.eng_impr_name%TYPE)
    IS
        r T_RECORD;
    BEGIN
        r.eng_impr_name := P_ENG_IMPR_NAME;
        ENG_IMPR_NAME_VALIDATE_ITEM(r);
        P_ENG_IMPR_NAME := r.eng_impr_name;
    END ENG_IMPR_NAME_VALIDATE_ITEM;

    -- Source: IMPORTERS.BUS_ID_ISSUE_DT.WHEN-VALIDATE-ITEM
    -- APEX  : Validation "BUS_ID_ISSUE_DT VALIDATION" (request CREATE / SAVE): returns the error text
    FUNCTION BUS_ID_ISSUE_DT_VALIDATION (P_BUS_ID_ISSUE_DT IN     VARCHAR2)
        RETURN VARCHAR2
    IS
        r T_RECORD;
    BEGIN
        r.bus_id_issue_dt := TO_DATE(P_BUS_ID_ISSUE_DT, c_mask);
        BUS_ID_ISSUE_DT_VALIDATE_ITEM(r, FALSE);
        RETURN NULL;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN PRIVATE_ERROR_TEXT(SQLCODE, SQLERRM, CASE WHEN r.row_id IS NULL THEN 'I' ELSE 'U' END);
    END BUS_ID_ISSUE_DT_VALIDATION;

    -- Source: IMPORTERS.BUS_ID_ISSUE_DT.WHEN-VALIDATE-ITEM
    -- APEX  : DA "BUS_ID_ISSUE_DT WHEN-VALIDATE-ITEM" (Change): FOS, Items to Submit = the IN items, Items to Return = the IN OUT / OUT items
    PROCEDURE BUS_ID_ISSUE_DT_VALIDATE_ITEM (P_BUS_ID_ISSUE_DT IN     VARCHAR2)
    IS
        r T_RECORD;
    BEGIN
        r.bus_id_issue_dt := TO_DATE(P_BUS_ID_ISSUE_DT, c_mask);
        BUS_ID_ISSUE_DT_VALIDATE_ITEM(r, TRUE);
    END BUS_ID_ISSUE_DT_VALIDATE_ITEM;

    -- Source: IMPORTERS.IMPR_NBR_PARENT.WHEN-VALIDATE-ITEM
    -- APEX  : Validation "IMPR_NBR_PARENT VALIDATION" (request CREATE / SAVE): returns the error text
    FUNCTION IMPR_NBR_PARENT_VALIDATION (P_IMPR_NBR_PARENT  IN     importers.impr_nbr_parent%TYPE,
                                         P_IMPR_NAME_PARENT IN     VARCHAR2)
        RETURN VARCHAR2
    IS
        r T_RECORD;
    BEGIN
        r.impr_nbr_parent := P_IMPR_NBR_PARENT;
        r.impr_name_parent := P_IMPR_NAME_PARENT;
        IMPR_NBR_PARENT_VALIDATE_ITEM(r);
        RETURN NULL;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN PRIVATE_ERROR_TEXT(SQLCODE, SQLERRM, CASE WHEN r.row_id IS NULL THEN 'I' ELSE 'U' END);
    END IMPR_NBR_PARENT_VALIDATION;

    -- Source: IMPORTERS.IMPR_NBR_PARENT.WHEN-VALIDATE-ITEM
    -- APEX  : DA "IMPR_NBR_PARENT WHEN-VALIDATE-ITEM" (Change): FOS, Items to Submit = the IN items, Items to Return = the IN OUT / OUT items
    PROCEDURE IMPR_NBR_PARENT_VALIDATE_ITEM (P_IMPR_NBR_PARENT   IN     importers.impr_nbr_parent%TYPE,
                                             P_IMPR_NAME_PARENT IN OUT VARCHAR2)
    IS
        r T_RECORD;
    BEGIN
        r.impr_nbr_parent := P_IMPR_NBR_PARENT;
        r.impr_name_parent := P_IMPR_NAME_PARENT;
        IMPR_NBR_PARENT_VALIDATE_ITEM(r);
        P_IMPR_NAME_PARENT := r.impr_name_parent;
    END IMPR_NBR_PARENT_VALIDATE_ITEM;

    -- Source: IMPORTERS.ADD_CTRY_CD.WHEN-VALIDATE-ITEM
    -- APEX  : Validation "ADD_CTRY_CD VALIDATION" (request CREATE / SAVE): returns the error text
    FUNCTION ADD_CTRY_CD_VALIDATION (P_ADD_CTRY_CD        IN     importers.add_ctry_cd%TYPE,
                                     P_CITY_CODE          IN     importers.city_code%TYPE,
                                     P_ADD_CRTY_ARBC_NAME IN     VARCHAR2,
                                     P_CITY_NAME          IN     VARCHAR2,
                                     P_L_CT_CITY_STATUS   IN     NUMBER)
        RETURN VARCHAR2
    IS
        r T_RECORD;
    BEGIN
        r.add_ctry_cd := P_ADD_CTRY_CD;
        r.city_code := P_CITY_CODE;
        r.add_crty_arbc_name := P_ADD_CRTY_ARBC_NAME;
        r.city_name := P_CITY_NAME;
        r.l_ct_city_status := P_L_CT_CITY_STATUS;
        ADD_CTRY_CD_WHEN_VALIDATE_ITEM(r);
        RETURN NULL;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN PRIVATE_ERROR_TEXT(SQLCODE, SQLERRM, CASE WHEN r.row_id IS NULL THEN 'I' ELSE 'U' END);
    END ADD_CTRY_CD_VALIDATION;

    -- Source: IMPORTERS.ADD_CTRY_CD.WHEN-VALIDATE-ITEM
    -- APEX  : DA "ADD_CTRY_CD WHEN-VALIDATE-ITEM" (Change): FOS, Items to Submit = the IN items, Items to Return = the IN OUT / OUT items
    PROCEDURE ADD_CTRY_CD_WHEN_VALIDATE_ITEM (P_ADD_CTRY_CD         IN     importers.add_ctry_cd%TYPE,
                                              P_CITY_CODE           IN     importers.city_code%TYPE,
                                              P_ADD_CRTY_ARBC_NAME IN OUT VARCHAR2,
                                              P_CITY_NAME          IN OUT VARCHAR2,
                                              P_L_CT_CITY_STATUS   IN OUT NUMBER)
    IS
        r T_RECORD;
    BEGIN
        r.add_ctry_cd := P_ADD_CTRY_CD;
        r.city_code := P_CITY_CODE;
        r.add_crty_arbc_name := P_ADD_CRTY_ARBC_NAME;
        r.city_name := P_CITY_NAME;
        r.l_ct_city_status := P_L_CT_CITY_STATUS;
        ADD_CTRY_CD_WHEN_VALIDATE_ITEM(r);
        P_ADD_CRTY_ARBC_NAME := r.add_crty_arbc_name;
        P_CITY_NAME := r.city_name;
        P_L_CT_CITY_STATUS := r.l_ct_city_status;
    END ADD_CTRY_CD_WHEN_VALIDATE_ITEM;

    -- Source: IMPORTERS.CITY_CODE.WHEN-VALIDATE-ITEM
    -- APEX  : Validation "CITY_CODE VALIDATION" (request CREATE / SAVE): returns the error text
    FUNCTION CITY_CODE_VALIDATION (P_ADD_CTRY_CD        IN     importers.add_ctry_cd%TYPE,
                                   P_CITY_CODE          IN     importers.city_code%TYPE,
                                   P_ADD_CRTY_ARBC_NAME IN     VARCHAR2,
                                   P_CITY_NAME          IN     VARCHAR2,
                                   P_L_CT_CITY_STATUS   IN     NUMBER)
        RETURN VARCHAR2
    IS
        r T_RECORD;
    BEGIN
        r.add_ctry_cd := P_ADD_CTRY_CD;
        r.city_code := P_CITY_CODE;
        r.add_crty_arbc_name := P_ADD_CRTY_ARBC_NAME;
        r.city_name := P_CITY_NAME;
        r.l_ct_city_status := P_L_CT_CITY_STATUS;
        CITY_CODE_WHEN_VALIDATE_ITEM(r);
        RETURN NULL;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN PRIVATE_ERROR_TEXT(SQLCODE, SQLERRM, CASE WHEN r.row_id IS NULL THEN 'I' ELSE 'U' END);
    END CITY_CODE_VALIDATION;

    -- Source: IMPORTERS.CITY_CODE.WHEN-VALIDATE-ITEM
    -- APEX  : DA "CITY_CODE WHEN-VALIDATE-ITEM" (Change): FOS, Items to Submit = the IN items, Items to Return = the IN OUT / OUT items
    PROCEDURE CITY_CODE_WHEN_VALIDATE_ITEM (P_ADD_CTRY_CD         IN     importers.add_ctry_cd%TYPE,
                                            P_CITY_CODE           IN     importers.city_code%TYPE,
                                            P_ADD_CRTY_ARBC_NAME IN OUT VARCHAR2,
                                            P_CITY_NAME          IN OUT VARCHAR2,
                                            P_L_CT_CITY_STATUS   IN OUT NUMBER)
    IS
        r T_RECORD;
    BEGIN
        r.add_ctry_cd := P_ADD_CTRY_CD;
        r.city_code := P_CITY_CODE;
        r.add_crty_arbc_name := P_ADD_CRTY_ARBC_NAME;
        r.city_name := P_CITY_NAME;
        r.l_ct_city_status := P_L_CT_CITY_STATUS;
        CITY_CODE_WHEN_VALIDATE_ITEM(r);
        P_ADD_CRTY_ARBC_NAME := r.add_crty_arbc_name;
        P_CITY_NAME := r.city_name;
        P_L_CT_CITY_STATUS := r.l_ct_city_status;
    END CITY_CODE_WHEN_VALIDATE_ITEM;

    -- Source: IMPORTERS.IMPR_TEL_NBR.WHEN-VALIDATE-ITEM
    -- APEX  : Validation "IMPR_TEL_NBR VALIDATION" (request CREATE / SAVE): returns the error text
    FUNCTION IMPR_TEL_NBR_VALIDATION (P_IMPR_TEL_NBR IN     importers.impr_tel_nbr%TYPE)
        RETURN VARCHAR2
    IS
        r T_RECORD;
    BEGIN
        r.impr_tel_nbr := P_IMPR_TEL_NBR;
        IMPR_TEL_NBR_VALIDATE_ITEM(r);
        RETURN NULL;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN PRIVATE_ERROR_TEXT(SQLCODE, SQLERRM, CASE WHEN r.row_id IS NULL THEN 'I' ELSE 'U' END);
    END IMPR_TEL_NBR_VALIDATION;

    -- Source: IMPORTERS.IMPR_TEL_NBR.WHEN-VALIDATE-ITEM
    -- APEX  : DA "IMPR_TEL_NBR WHEN-VALIDATE-ITEM" (Change): FOS, Items to Submit = the IN items, Items to Return = the IN OUT / OUT items
    PROCEDURE IMPR_TEL_NBR_VALIDATE_ITEM (P_IMPR_TEL_NBR IN     importers.impr_tel_nbr%TYPE)
    IS
        r T_RECORD;
    BEGIN
        r.impr_tel_nbr := P_IMPR_TEL_NBR;
        IMPR_TEL_NBR_VALIDATE_ITEM(r);
    END IMPR_TEL_NBR_VALIDATE_ITEM;

    -- Source: IMPORTERS.B_EMAIL.POST-CHANGE + WHEN-VALIDATE-ITEM
    -- APEX  : Validation "B_EMAIL VALIDATION" (request CREATE / SAVE): returns the error text
    FUNCTION B_EMAIL_VALIDATION (P_PORT_CD  IN     importers.port_cd%TYPE,
                                 P_B_EMAIL  IN     VARCHAR2,
                                 P_CURR_PORT_CD IN     NUMBER)
        RETURN VARCHAR2
    IS
        r T_RECORD;
        c T_CONTEXT;
    BEGIN
        c.curr_port_cd := P_CURR_PORT_CD;
        r.port_cd := P_PORT_CD;
        r.b_email := P_B_EMAIL;
        B_EMAIL_POST_CHANGE(r, c);
        B_EMAIL_WHEN_VALIDATE_ITEM(r, FALSE);
        RETURN NULL;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN PRIVATE_ERROR_TEXT(SQLCODE, SQLERRM, CASE WHEN r.row_id IS NULL THEN 'I' ELSE 'U' END);
    END B_EMAIL_VALIDATION;

    -- Source: IMPORTERS.B_EMAIL.POST-CHANGE + WHEN-VALIDATE-ITEM
    -- APEX  : DA "B_EMAIL WHEN-VALIDATE-ITEM" (Change): FOS, Items to Submit = the IN items, Items to Return = the IN OUT / OUT items
    PROCEDURE B_EMAIL_WHEN_VALIDATE_ITEM (P_PORT_CD IN OUT importers.port_cd%TYPE,
                                          P_B_EMAIL  IN     VARCHAR2,
                                          P_CURR_PORT_CD IN     NUMBER)
    IS
        r T_RECORD;
        c T_CONTEXT;
    BEGIN
        c.curr_port_cd := P_CURR_PORT_CD;
        r.port_cd := P_PORT_CD;
        r.b_email := P_B_EMAIL;
        B_EMAIL_POST_CHANGE(r, c);
        B_EMAIL_WHEN_VALIDATE_ITEM(r, TRUE);
        P_PORT_CD := r.port_cd;
    END B_EMAIL_WHEN_VALIDATE_ITEM;

    -- Source: IMPORTERS.EMAIL.WHEN-VALIDATE-ITEM
    -- APEX  : Validation "EMAIL VALIDATION" (request CREATE / SAVE): returns the error text
    FUNCTION EMAIL_VALIDATION (P_EMAIL IN     importers.email%TYPE)
        RETURN VARCHAR2
    IS
        r T_RECORD;
    BEGIN
        r.email := P_EMAIL;
        EMAIL_WHEN_VALIDATE_ITEM(r, FALSE);
        RETURN NULL;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN PRIVATE_ERROR_TEXT(SQLCODE, SQLERRM, CASE WHEN r.row_id IS NULL THEN 'I' ELSE 'U' END);
    END EMAIL_VALIDATION;

    -- Source: IMPORTERS.EMAIL.WHEN-VALIDATE-ITEM
    -- APEX  : DA "EMAIL WHEN-VALIDATE-ITEM" (Change): FOS, Items to Submit = the IN items, Items to Return = the IN OUT / OUT items
    PROCEDURE EMAIL_WHEN_VALIDATE_ITEM (P_EMAIL IN     importers.email%TYPE)
    IS
        r T_RECORD;
    BEGIN
        r.email := P_EMAIL;
        EMAIL_WHEN_VALIDATE_ITEM(r, TRUE);
    END EMAIL_WHEN_VALIDATE_ITEM;

    -- Source: IMPORTERS.B_MOBILE_NO.POST-CHANGE + WHEN-VALIDATE-ITEM
    -- APEX  : Validation "B_MOBILE_NO VALIDATION" (request CREATE / SAVE): returns the error text
    FUNCTION B_MOBILE_NO_VALIDATION (P_PORT_CD     IN     importers.port_cd%TYPE,
                                     P_IMPR_NBR    IN     importers.impr_nbr%TYPE,
                                     P_B_MOBILE_NO IN     VARCHAR2,
                                     P_CURR_PORT_CD    IN     NUMBER)
        RETURN VARCHAR2
    IS
        r T_RECORD;
        c T_CONTEXT;
    BEGIN
        c.curr_port_cd := P_CURR_PORT_CD;
        r.port_cd := P_PORT_CD;
        r.impr_nbr := P_IMPR_NBR;
        r.b_mobile_no := P_B_MOBILE_NO;
        B_MOBILE_NO_POST_CHANGE(r, c);
        B_MOBILE_NO_WHEN_VALIDATE_ITEM(r, c);
        RETURN NULL;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN PRIVATE_ERROR_TEXT(SQLCODE, SQLERRM, CASE WHEN r.row_id IS NULL THEN 'I' ELSE 'U' END);
    END B_MOBILE_NO_VALIDATION;

    -- Source: IMPORTERS.B_MOBILE_NO.POST-CHANGE + WHEN-VALIDATE-ITEM
    -- APEX  : DA "B_MOBILE_NO WHEN-VALIDATE-ITEM" (Change): FOS, Items to Submit = the IN items, Items to Return = the IN OUT / OUT items
    PROCEDURE B_MOBILE_NO_WHEN_VALIDATE_ITEM (P_PORT_CD    IN OUT importers.port_cd%TYPE,
                                              P_IMPR_NBR    IN     importers.impr_nbr%TYPE,
                                              P_B_MOBILE_NO IN     VARCHAR2,
                                              P_CURR_PORT_CD    IN     NUMBER)
    IS
        r T_RECORD;
        c T_CONTEXT;
    BEGIN
        c.curr_port_cd := P_CURR_PORT_CD;
        r.port_cd := P_PORT_CD;
        r.impr_nbr := P_IMPR_NBR;
        r.b_mobile_no := P_B_MOBILE_NO;
        B_MOBILE_NO_POST_CHANGE(r, c);
        B_MOBILE_NO_WHEN_VALIDATE_ITEM(r, c);
        P_PORT_CD := r.port_cd;
    END B_MOBILE_NO_WHEN_VALIDATE_ITEM;

    -- Source: IMPORTERS.BANK_IBAN.WHEN-VALIDATE-ITEM
    -- APEX  : Validation "BANK_IBAN VALIDATION" (request CREATE / SAVE): returns the error text
    FUNCTION BANK_IBAN_VALIDATION (P_BANK_IBAN IN     importers.bank_iban%TYPE)
        RETURN VARCHAR2
    IS
        r T_RECORD;
    BEGIN
        r.bank_iban := P_BANK_IBAN;
        BANK_IBAN_WHEN_VALIDATE_ITEM(r);
        RETURN NULL;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN PRIVATE_ERROR_TEXT(SQLCODE, SQLERRM, CASE WHEN r.row_id IS NULL THEN 'I' ELSE 'U' END);
    END BANK_IBAN_VALIDATION;

    -- Source: IMPORTERS.BANK_IBAN.WHEN-VALIDATE-ITEM
    -- APEX  : DA "BANK_IBAN WHEN-VALIDATE-ITEM" (Change): FOS, Items to Submit = the IN items, Items to Return = the IN OUT / OUT items
    PROCEDURE BANK_IBAN_WHEN_VALIDATE_ITEM (P_BANK_IBAN IN OUT importers.bank_iban%TYPE)
    IS
        r T_RECORD;
    BEGIN
        r.bank_iban := P_BANK_IBAN;
        BANK_IBAN_WHEN_VALIDATE_ITEM(r);
        P_BANK_IBAN := r.bank_iban;
    END BANK_IBAN_WHEN_VALIDATE_ITEM;

    -- Source: IMPORTERS.BANK_IBAN.WHEN-NEW-ITEM-INSTANCE
    -- APEX  : DA "BANK_IBAN WHEN-NEW-ITEM-INSTANCE": FOS, Items to Return = the IN OUT / OUT items
    PROCEDURE BANK_IBAN_NEW_ITEM_INSTANCE (P_BANK_IBAN IN OUT importers.bank_iban%TYPE)
    IS
        r T_RECORD;
    BEGIN
        r.bank_iban := P_BANK_IBAN;
        BANK_IBAN_NEW_ITEM_INSTANCE(r);
        P_BANK_IBAN := r.bank_iban;
    END BANK_IBAN_NEW_ITEM_INSTANCE;

    -- Source: IMPORTERS.B_ID_NBR.POST-CHANGE + WHEN-VALIDATE-ITEM
    -- APEX  : Validation "B_ID_NBR VALIDATION" (request CREATE / SAVE): returns the error text
    FUNCTION B_ID_NBR_VALIDATION (P_PORT_CD  IN     importers.port_cd%TYPE,
                                  P_B_ID_NBR IN     VARCHAR2,
                                  P_CURR_PORT_CD IN     NUMBER)
        RETURN VARCHAR2
    IS
        r T_RECORD;
        c T_CONTEXT;
    BEGIN
        c.curr_port_cd := P_CURR_PORT_CD;
        r.port_cd := P_PORT_CD;
        r.b_id_nbr := P_B_ID_NBR;
        B_ID_NBR_POST_CHANGE(r, c);
        B_ID_NBR_WHEN_VALIDATE_ITEM(r);
        RETURN NULL;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN PRIVATE_ERROR_TEXT(SQLCODE, SQLERRM, CASE WHEN r.row_id IS NULL THEN 'I' ELSE 'U' END);
    END B_ID_NBR_VALIDATION;

    -- Source: IMPORTERS.B_ID_NBR.POST-CHANGE + WHEN-VALIDATE-ITEM
    -- APEX  : DA "B_ID_NBR WHEN-VALIDATE-ITEM" (Change): FOS, Items to Submit = the IN items, Items to Return = the IN OUT / OUT items
    PROCEDURE B_ID_NBR_WHEN_VALIDATE_ITEM (P_PORT_CD IN OUT importers.port_cd%TYPE,
                                           P_B_ID_NBR IN     VARCHAR2,
                                           P_CURR_PORT_CD IN     NUMBER)
    IS
        r T_RECORD;
        c T_CONTEXT;
    BEGIN
        c.curr_port_cd := P_CURR_PORT_CD;
        r.port_cd := P_PORT_CD;
        r.b_id_nbr := P_B_ID_NBR;
        B_ID_NBR_POST_CHANGE(r, c);
        B_ID_NBR_WHEN_VALIDATE_ITEM(r);
        P_PORT_CD := r.port_cd;
    END B_ID_NBR_WHEN_VALIDATE_ITEM;

    -- Source: IMPORTERS.CTRY_CD_OF_ID.WHEN-VALIDATE-ITEM
    -- APEX  : Validation "CTRY_CD_OF_ID VALIDATION" (request CREATE / SAVE): returns the error text
    FUNCTION CTRY_CD_OF_ID_VALIDATION (P_CITY_CODE_OF_ID   IN     importers.city_code_of_id%TYPE,
                                       P_CTRY_CD_OF_ID     IN     importers.ctry_cd_of_id%TYPE,
                                       P_ID_CITY_NAME      IN     VARCHAR2,
                                       P_ID_MINS_COMM_CD   IN     NUMBER,
                                       P_L_CT_CITY_STATUS2 IN     NUMBER,
                                       P_ROW_ID            IN     VARCHAR2)
        RETURN VARCHAR2
    IS
        r T_RECORD;
    BEGIN
        r.city_code_of_id := P_CITY_CODE_OF_ID;
        r.ctry_cd_of_id := P_CTRY_CD_OF_ID;
        r.id_city_name := P_ID_CITY_NAME;
        r.id_mins_comm_cd := P_ID_MINS_COMM_CD;
        r.l_ct_city_status2 := P_L_CT_CITY_STATUS2;
        r.row_id := P_ROW_ID;
        r.rec_status := CASE WHEN r.row_id IS NULL THEN 'NEW' ELSE 'QUERY' END;
        CTRY_CD_OF_ID_VALIDATE_ITEM(r);
        RETURN NULL;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN PRIVATE_ERROR_TEXT(SQLCODE, SQLERRM, CASE WHEN r.row_id IS NULL THEN 'I' ELSE 'U' END);
    END CTRY_CD_OF_ID_VALIDATION;

    -- Source: IMPORTERS.CTRY_CD_OF_ID.WHEN-VALIDATE-ITEM
    -- APEX  : DA "CTRY_CD_OF_ID WHEN-VALIDATE-ITEM" (Change): FOS, Items to Submit = the IN items, Items to Return = the IN OUT / OUT items
    PROCEDURE CTRY_CD_OF_ID_VALIDATE_ITEM (P_CITY_CODE_OF_ID   IN OUT importers.city_code_of_id%TYPE,
                                           P_CTRY_CD_OF_ID     IN OUT importers.ctry_cd_of_id%TYPE,
                                           P_ID_CITY_NAME      IN OUT VARCHAR2,
                                           P_ID_MINS_COMM_CD   IN OUT NUMBER,
                                           P_L_CT_CITY_STATUS2 IN OUT NUMBER,
                                           P_ROW_ID             IN     VARCHAR2)
    IS
        r T_RECORD;
    BEGIN
        r.city_code_of_id := P_CITY_CODE_OF_ID;
        r.ctry_cd_of_id := P_CTRY_CD_OF_ID;
        r.id_city_name := P_ID_CITY_NAME;
        r.id_mins_comm_cd := P_ID_MINS_COMM_CD;
        r.l_ct_city_status2 := P_L_CT_CITY_STATUS2;
        r.row_id := P_ROW_ID;
        r.rec_status := CASE WHEN r.row_id IS NULL THEN 'NEW' ELSE 'QUERY' END;
        CTRY_CD_OF_ID_VALIDATE_ITEM(r);
        P_CITY_CODE_OF_ID := r.city_code_of_id;
        P_CTRY_CD_OF_ID := r.ctry_cd_of_id;
        P_ID_CITY_NAME := r.id_city_name;
        P_ID_MINS_COMM_CD := r.id_mins_comm_cd;
        P_L_CT_CITY_STATUS2 := r.l_ct_city_status2;
    END CTRY_CD_OF_ID_VALIDATE_ITEM;

    -- Source: IMPORTERS.PRE-INSERT
    -- APEX  : Process "PRE-INSERT" (request CREATE / SAVE, :P0_PAGE_PK is null), before "Process form IMPORTERS"; Confirm of brokers (class 1, type 3) sets P1110_ANSWER
    PROCEDURE PRE_INSERT (P_PORT_CD            IN     importers.port_cd%TYPE,
                          P_HQ_IMPR_NBR       IN OUT importers.hq_impr_nbr%TYPE,
                          P_IMPR_NBR           IN     importers.impr_nbr%TYPE,
                          P_IMPR_TYPE_CD       IN     importers.impr_type_cd%TYPE,
                          P_BUS_ID_EXPRD_DT    IN     VARCHAR2,
                          P_BUS_ID_TYPE_CD     IN     importers.bus_id_type_cd%TYPE,
                          P_COMM_RGSTRTN_TYPE  IN     importers.comm_rgstrtn_type%TYPE,
                          P_CITY_CODE_OF_ID   IN OUT importers.city_code_of_id%TYPE,
                          P_BUS_ID             IN     importers.bus_id%TYPE,
                          P_BUS_ID_BRNCH       IN     importers.bus_id_brnch%TYPE,
                          P_CTRY_CD            IN     importers.ctry_cd%TYPE,
                          P_IMPR_EXPR_TYPE     IN     importers.impr_expr_type%TYPE,
                          P_ARBC_IMPR_NAME     IN     importers.arbc_impr_name%TYPE,
                          P_IMPD_STMT_NBR      IN     importers.impd_stmt_nbr%TYPE,
                          P_IMPR_DATA_SRCE     IN     importers.impr_data_srce%TYPE,
                          P_ENG_IMPR_NAME      IN     importers.eng_impr_name%TYPE,
                          P_IMPR_CNTCT_NAME    IN     importers.impr_cntct_name%TYPE,
                          P_IMPR_ADDRESS       IN     importers.impr_address%TYPE,
                          P_BUS_ID_ISSUE_DT    IN     VARCHAR2,
                          P_IMPR_NBR_PARENT    IN     importers.impr_nbr_parent%TYPE,
                          P_ADD_CTRY_CD        IN     importers.add_ctry_cd%TYPE,
                          P_CITY_CODE          IN     importers.city_code%TYPE,
                          P_IMPR_POB_NBR       IN     importers.impr_pob_nbr%TYPE,
                          P_IMPR_ZIP_CD        IN     importers.impr_zip_cd%TYPE,
                          P_IMPR_TEL_NBR       IN     importers.impr_tel_nbr%TYPE,
                          P_IMPR_FAX_NBR       IN     importers.impr_fax_nbr%TYPE,
                          P_IMPR_TELEX_NBR     IN     importers.impr_telex_nbr%TYPE,
                          P_BANK_IBAN          IN     importers.bank_iban%TYPE,
                          P_CAR_AGENT_FLAG     IN     importers.car_agent_flag%TYPE,
                          P_EXPRESS_POST       IN     importers.express_post%TYPE,
                          P_CTRY_CD_OF_ID     IN OUT importers.ctry_cd_of_id%TYPE,
                          P_EXPD_STMT_NBR      IN     importers.expd_stmt_nbr%TYPE,
                          P_WVR_ENTRY_NBR      IN     importers.wvr_entry_nbr%TYPE,
                          P_ACTIVITY           IN     importers.activity%TYPE,
                          P_ID_CITY_NAME      IN OUT VARCHAR2,
                          P_ID_MINS_COMM_CD   IN OUT NUMBER,
                          P_L_CT_CITY_STATUS2 IN OUT NUMBER,
                          P_BRNH_CITY_CD       IN     NUMBER,
                          P_B_EMAIL            IN     VARCHAR2,
                          P_B_MOBILE_NO        IN     VARCHAR2,
                          P_B_ID_NBR           IN     VARCHAR2,
                          P_CURR_PORT_CD           IN     NUMBER,
                          SSO_APP_USER             IN     VARCHAR2,
                          P_GLOBAL_V_WS_ID         IN     VARCHAR2,
                          P_CLASS_CD               IN     NUMBER,
                          V_USR_TYPE               IN     NUMBER,
                          P_ANSWER             IN     PLS_INTEGER DEFAULT NULL)
    IS
        r T_RECORD;
        c T_CONTEXT;
    BEGIN
        c.curr_port_cd := P_CURR_PORT_CD;
        c.user_id := SSO_APP_USER;
        c.ws_id := P_GLOBAL_V_WS_ID;
        c.class_cd := P_CLASS_CD;
        c.user_type := V_USR_TYPE;
        r.port_cd := P_PORT_CD;
        r.hq_impr_nbr := P_HQ_IMPR_NBR;
        r.impr_nbr := P_IMPR_NBR;
        r.impr_type_cd := P_IMPR_TYPE_CD;
        r.bus_id_exprd_dt := TO_DATE(P_BUS_ID_EXPRD_DT, c_mask);
        r.bus_id_type_cd := P_BUS_ID_TYPE_CD;
        r.comm_rgstrtn_type := P_COMM_RGSTRTN_TYPE;
        r.city_code_of_id := P_CITY_CODE_OF_ID;
        r.bus_id := P_BUS_ID;
        r.bus_id_brnch := P_BUS_ID_BRNCH;
        r.ctry_cd := P_CTRY_CD;
        r.impr_expr_type := P_IMPR_EXPR_TYPE;
        r.arbc_impr_name := P_ARBC_IMPR_NAME;
        r.impd_stmt_nbr := P_IMPD_STMT_NBR;
        r.impr_data_srce := P_IMPR_DATA_SRCE;
        r.eng_impr_name := P_ENG_IMPR_NAME;
        r.impr_cntct_name := P_IMPR_CNTCT_NAME;
        r.impr_address := P_IMPR_ADDRESS;
        r.bus_id_issue_dt := TO_DATE(P_BUS_ID_ISSUE_DT, c_mask);
        r.impr_nbr_parent := P_IMPR_NBR_PARENT;
        r.add_ctry_cd := P_ADD_CTRY_CD;
        r.city_code := P_CITY_CODE;
        r.impr_pob_nbr := P_IMPR_POB_NBR;
        r.impr_zip_cd := P_IMPR_ZIP_CD;
        r.impr_tel_nbr := P_IMPR_TEL_NBR;
        r.impr_fax_nbr := P_IMPR_FAX_NBR;
        r.impr_telex_nbr := P_IMPR_TELEX_NBR;
        r.bank_iban := P_BANK_IBAN;
        r.car_agent_flag := P_CAR_AGENT_FLAG;
        r.express_post := P_EXPRESS_POST;
        r.ctry_cd_of_id := P_CTRY_CD_OF_ID;
        r.expd_stmt_nbr := P_EXPD_STMT_NBR;
        r.wvr_entry_nbr := P_WVR_ENTRY_NBR;
        r.activity := P_ACTIVITY;
        r.id_city_name := P_ID_CITY_NAME;
        r.id_mins_comm_cd := P_ID_MINS_COMM_CD;
        r.l_ct_city_status2 := P_L_CT_CITY_STATUS2;
        r.brnh_city_cd := P_BRNH_CITY_CD;
        r.b_email := P_B_EMAIL;
        r.b_mobile_no := P_B_MOBILE_NO;
        r.b_id_nbr := P_B_ID_NBR;
        r.activity_entr := CASE WHEN ACTIVITY_IS_READ_ONLY(r.bus_id, r.activity) THEN 'N' ELSE 'Y' END;
        IMPORTERS_PRE_INSERT(r, c, NVL(P_ANSWER, c_yes));
        P_HQ_IMPR_NBR := r.hq_impr_nbr;
        P_CITY_CODE_OF_ID := r.city_code_of_id;
        P_CTRY_CD_OF_ID := r.ctry_cd_of_id;
        P_ID_CITY_NAME := r.id_city_name;
        P_ID_MINS_COMM_CD := r.id_mins_comm_cd;
        P_L_CT_CITY_STATUS2 := r.l_ct_city_status2;
    END PRE_INSERT;

    -- Source: IMPORTERS.POST-INSERT
    -- APEX  : Process "POST-INSERT", after "Process form IMPORTERS"
    PROCEDURE POST_INSERT (P_PORT_CD           IN     importers.port_cd%TYPE,
                           P_HQ_IMPR_NBR      IN OUT importers.hq_impr_nbr%TYPE,
                           P_IMPR_NBR         IN OUT importers.impr_nbr%TYPE,
                           P_BUS_ID_STATUS     IN     importers.bus_id_status%TYPE,
                           P_IMPR_TYPE_CD      IN     importers.impr_type_cd%TYPE,
                           P_BUS_ID_EXPRD_DT   IN     VARCHAR2,
                           P_BUS_ID_TYPE_CD    IN     importers.bus_id_type_cd%TYPE,
                           P_COMM_RGSTRTN_TYPE IN     importers.comm_rgstrtn_type%TYPE,
                           P_CITY_CODE_OF_ID   IN     importers.city_code_of_id%TYPE,
                           P_BUS_ID            IN     importers.bus_id%TYPE,
                           P_BUS_ID_BRNCH      IN     importers.bus_id_brnch%TYPE,
                           P_CTRY_CD           IN     importers.ctry_cd%TYPE,
                           P_IMPR_EXPR_TYPE    IN     importers.impr_expr_type%TYPE,
                           P_ARBC_IMPR_NAME    IN     importers.arbc_impr_name%TYPE,
                           P_IMPR_NAME_STD     IN     importers.impr_name_std%TYPE,
                           P_LST_TRAN_DT       IN     VARCHAR2,
                           P_IMPD_STMT_NBR     IN     importers.impd_stmt_nbr%TYPE,
                           P_IMPR_DATA_SRCE    IN     importers.impr_data_srce%TYPE,
                           P_ENG_IMPR_NAME     IN     importers.eng_impr_name%TYPE,
                           P_IMPR_CNTCT_NAME   IN     importers.impr_cntct_name%TYPE,
                           P_IMPR_ADDRESS      IN     importers.impr_address%TYPE,
                           P_BUS_ID_ISSUE_DT   IN     VARCHAR2,
                           P_IMPR_NBR_PARENT   IN     importers.impr_nbr_parent%TYPE,
                           P_ADD_CTRY_CD       IN     importers.add_ctry_cd%TYPE,
                           P_CITY_CODE         IN     importers.city_code%TYPE,
                           P_IMPR_POB_NBR      IN     importers.impr_pob_nbr%TYPE,
                           P_IMPR_ZIP_CD       IN     importers.impr_zip_cd%TYPE,
                           P_IMPR_TEL_NBR      IN     importers.impr_tel_nbr%TYPE,
                           P_IMPR_FAX_NBR      IN     importers.impr_fax_nbr%TYPE,
                           P_IMPR_TELEX_NBR    IN     importers.impr_telex_nbr%TYPE,
                           P_EMAIL             IN     importers.email%TYPE,
                           P_MOBILE_NO         IN     importers.mobile_no%TYPE,
                           P_BANK_IBAN         IN     importers.bank_iban%TYPE,
                           P_ID_NBR            IN     importers.id_nbr%TYPE,
                           P_CAR_AGENT_FLAG    IN     importers.car_agent_flag%TYPE,
                           P_EXPRESS_POST      IN     importers.express_post%TYPE,
                           P_CTRY_CD_OF_ID     IN     importers.ctry_cd_of_id%TYPE,
                           P_CREATION_FLAG     IN     importers.creation_flag%TYPE,
                           P_B_EMAIL           IN     VARCHAR2,
                           P_B_MOBILE_NO       IN     VARCHAR2,
                           P_B_ID_NBR          IN     VARCHAR2,
                           P_CURR_PORT_CD          IN     NUMBER,
                           SSO_APP_USER            IN     VARCHAR2,
                           P_GLOBAL_V_WS_ID        IN     VARCHAR2,
                           P_CLASS_CD              IN     NUMBER,
                           V_USR_TYPE              IN     NUMBER,
                           P_BRKR_PORT_CD          IN     NUMBER,
                           P_LIC_TYPE              IN     NUMBER,
                           P_BRKR_NBR              IN     NUMBER)
    IS
        r T_RECORD;
        c T_CONTEXT;
    BEGIN
        c.curr_port_cd := P_CURR_PORT_CD;
        c.user_id := SSO_APP_USER;
        c.ws_id := P_GLOBAL_V_WS_ID;
        c.class_cd := P_CLASS_CD;
        c.user_type := V_USR_TYPE;
        c.brkr_port_cd := P_BRKR_PORT_CD;
        c.lic_type := P_LIC_TYPE;
        c.brkr_nbr := P_BRKR_NBR;
        r.port_cd := P_PORT_CD;
        r.hq_impr_nbr := P_HQ_IMPR_NBR;
        r.impr_nbr := P_IMPR_NBR;
        r.bus_id_status := P_BUS_ID_STATUS;
        r.impr_type_cd := P_IMPR_TYPE_CD;
        r.bus_id_exprd_dt := TO_DATE(P_BUS_ID_EXPRD_DT, c_mask);
        r.bus_id_type_cd := P_BUS_ID_TYPE_CD;
        r.comm_rgstrtn_type := P_COMM_RGSTRTN_TYPE;
        r.city_code_of_id := P_CITY_CODE_OF_ID;
        r.bus_id := P_BUS_ID;
        r.bus_id_brnch := P_BUS_ID_BRNCH;
        r.ctry_cd := P_CTRY_CD;
        r.impr_expr_type := P_IMPR_EXPR_TYPE;
        r.arbc_impr_name := P_ARBC_IMPR_NAME;
        r.impr_name_std := P_IMPR_NAME_STD;
        r.lst_tran_dt := TO_DATE(P_LST_TRAN_DT, c_date_time_mask);
        r.impd_stmt_nbr := P_IMPD_STMT_NBR;
        r.impr_data_srce := P_IMPR_DATA_SRCE;
        r.eng_impr_name := P_ENG_IMPR_NAME;
        r.impr_cntct_name := P_IMPR_CNTCT_NAME;
        r.impr_address := P_IMPR_ADDRESS;
        r.bus_id_issue_dt := TO_DATE(P_BUS_ID_ISSUE_DT, c_mask);
        r.impr_nbr_parent := P_IMPR_NBR_PARENT;
        r.add_ctry_cd := P_ADD_CTRY_CD;
        r.city_code := P_CITY_CODE;
        r.impr_pob_nbr := P_IMPR_POB_NBR;
        r.impr_zip_cd := P_IMPR_ZIP_CD;
        r.impr_tel_nbr := P_IMPR_TEL_NBR;
        r.impr_fax_nbr := P_IMPR_FAX_NBR;
        r.impr_telex_nbr := P_IMPR_TELEX_NBR;
        r.email := P_EMAIL;
        r.mobile_no := P_MOBILE_NO;
        r.bank_iban := P_BANK_IBAN;
        r.id_nbr := P_ID_NBR;
        r.car_agent_flag := P_CAR_AGENT_FLAG;
        r.express_post := P_EXPRESS_POST;
        r.ctry_cd_of_id := P_CTRY_CD_OF_ID;
        r.creation_flag := P_CREATION_FLAG;
        r.b_email := P_B_EMAIL;
        r.b_mobile_no := P_B_MOBILE_NO;
        r.b_id_nbr := P_B_ID_NBR;
        IMPORTERS_POST_INSERT(r, c);
        P_HQ_IMPR_NBR := r.hq_impr_nbr;
        P_IMPR_NBR := r.impr_nbr;
    END POST_INSERT;

    -- Source: IMPORTERS.PRE-UPDATE
    -- APEX  : Process "PRE-UPDATE" (request SAVE, :P0_PAGE_PK is not null), before "Process form IMPORTERS"
    PROCEDURE PRE_UPDATE (P_PORT_CD           IN     importers.port_cd%TYPE,
                          P_HQ_IMPR_NBR      IN OUT importers.hq_impr_nbr%TYPE,
                          P_IMPR_NBR          IN     importers.impr_nbr%TYPE,
                          P_BUS_ID_STATUS     IN     importers.bus_id_status%TYPE,
                          P_IMPR_TYPE_CD     IN OUT importers.impr_type_cd%TYPE,
                          P_BUS_ID_EXPRD_DT   IN     VARCHAR2,
                          P_BUS_ID_TYPE_CD    IN     importers.bus_id_type_cd%TYPE,
                          P_COMM_RGSTRTN_TYPE IN     importers.comm_rgstrtn_type%TYPE,
                          P_CITY_CODE_OF_ID   IN     importers.city_code_of_id%TYPE,
                          P_BUS_ID            IN     importers.bus_id%TYPE,
                          P_BUS_ID_BRNCH      IN     importers.bus_id_brnch%TYPE,
                          P_CTRY_CD           IN     importers.ctry_cd%TYPE,
                          P_IMPR_EXPR_TYPE    IN     importers.impr_expr_type%TYPE,
                          P_ARBC_IMPR_NAME   IN OUT importers.arbc_impr_name%TYPE,
                          P_IMPR_NAME_STD    IN OUT importers.impr_name_std%TYPE,
                          P_LST_TRAN_DT       IN     VARCHAR2,
                          P_IMPD_STMT_NBR     IN     importers.impd_stmt_nbr%TYPE,
                          P_IMPR_DATA_SRCE    IN     importers.impr_data_srce%TYPE,
                          P_ENG_IMPR_NAME    IN OUT importers.eng_impr_name%TYPE,
                          P_IMPR_CNTCT_NAME  IN OUT importers.impr_cntct_name%TYPE,
                          P_IMPR_ADDRESS      IN     importers.impr_address%TYPE,
                          P_BUS_ID_ISSUE_DT   IN     VARCHAR2,
                          P_IMPR_NBR_PARENT   IN     importers.impr_nbr_parent%TYPE,
                          P_ADD_CTRY_CD       IN     importers.add_ctry_cd%TYPE,
                          P_CITY_CODE         IN     importers.city_code%TYPE,
                          P_IMPR_POB_NBR      IN     importers.impr_pob_nbr%TYPE,
                          P_IMPR_ZIP_CD       IN     importers.impr_zip_cd%TYPE,
                          P_IMPR_TEL_NBR      IN     importers.impr_tel_nbr%TYPE,
                          P_IMPR_FAX_NBR      IN     importers.impr_fax_nbr%TYPE,
                          P_IMPR_TELEX_NBR    IN     importers.impr_telex_nbr%TYPE,
                          P_EMAIL             IN     importers.email%TYPE,
                          P_MOBILE_NO        IN OUT importers.mobile_no%TYPE,
                          P_BANK_IBAN         IN     importers.bank_iban%TYPE,
                          P_ID_NBR            IN     importers.id_nbr%TYPE,
                          P_CAR_AGENT_FLAG    IN     importers.car_agent_flag%TYPE,
                          P_EXPRESS_POST      IN     importers.express_post%TYPE,
                          P_CTRY_CD_OF_ID     IN     importers.ctry_cd_of_id%TYPE,
                          P_CUSTOMS_ENTERED  IN OUT importers.customs_entered%TYPE,
                          P_CREATION_FLAG     IN     importers.creation_flag%TYPE,
                          P_IMPR_TYPE_NAME   IN OUT VARCHAR2,
                          P_B_MOBILE_NO       IN     VARCHAR2,
                          P_CURR_PORT_CD          IN     NUMBER,
                          SSO_APP_USER            IN     VARCHAR2,
                          P_GLOBAL_V_WS_ID        IN     VARCHAR2,
                          P_P_LETTER_NBR      IN     VARCHAR2)
    IS
        r T_RECORD;
        c T_CONTEXT;
    BEGIN
        c.curr_port_cd := P_CURR_PORT_CD;
        c.user_id := SSO_APP_USER;
        c.ws_id := P_GLOBAL_V_WS_ID;
        c.letter_nbr := P_P_LETTER_NBR;
        r.port_cd := P_PORT_CD;
        r.hq_impr_nbr := P_HQ_IMPR_NBR;
        r.impr_nbr := P_IMPR_NBR;
        r.bus_id_status := P_BUS_ID_STATUS;
        r.impr_type_cd := P_IMPR_TYPE_CD;
        r.bus_id_exprd_dt := TO_DATE(P_BUS_ID_EXPRD_DT, c_mask);
        r.bus_id_type_cd := P_BUS_ID_TYPE_CD;
        r.comm_rgstrtn_type := P_COMM_RGSTRTN_TYPE;
        r.city_code_of_id := P_CITY_CODE_OF_ID;
        r.bus_id := P_BUS_ID;
        r.bus_id_brnch := P_BUS_ID_BRNCH;
        r.ctry_cd := P_CTRY_CD;
        r.impr_expr_type := P_IMPR_EXPR_TYPE;
        r.arbc_impr_name := P_ARBC_IMPR_NAME;
        r.impr_name_std := P_IMPR_NAME_STD;
        r.lst_tran_dt := TO_DATE(P_LST_TRAN_DT, c_date_time_mask);
        r.impd_stmt_nbr := P_IMPD_STMT_NBR;
        r.impr_data_srce := P_IMPR_DATA_SRCE;
        r.eng_impr_name := P_ENG_IMPR_NAME;
        r.impr_cntct_name := P_IMPR_CNTCT_NAME;
        r.impr_address := P_IMPR_ADDRESS;
        r.bus_id_issue_dt := TO_DATE(P_BUS_ID_ISSUE_DT, c_mask);
        r.impr_nbr_parent := P_IMPR_NBR_PARENT;
        r.add_ctry_cd := P_ADD_CTRY_CD;
        r.city_code := P_CITY_CODE;
        r.impr_pob_nbr := P_IMPR_POB_NBR;
        r.impr_zip_cd := P_IMPR_ZIP_CD;
        r.impr_tel_nbr := P_IMPR_TEL_NBR;
        r.impr_fax_nbr := P_IMPR_FAX_NBR;
        r.impr_telex_nbr := P_IMPR_TELEX_NBR;
        r.email := P_EMAIL;
        r.mobile_no := P_MOBILE_NO;
        r.bank_iban := P_BANK_IBAN;
        r.id_nbr := P_ID_NBR;
        r.car_agent_flag := P_CAR_AGENT_FLAG;
        r.express_post := P_EXPRESS_POST;
        r.ctry_cd_of_id := P_CTRY_CD_OF_ID;
        r.customs_entered := P_CUSTOMS_ENTERED;
        r.creation_flag := P_CREATION_FLAG;
        r.impr_type_name := P_IMPR_TYPE_NAME;
        r.b_mobile_no := P_B_MOBILE_NO;
        IMPORTERS_PRE_UPDATE(r, c);
        P_HQ_IMPR_NBR := r.hq_impr_nbr;
        P_IMPR_TYPE_CD := r.impr_type_cd;
        P_ARBC_IMPR_NAME := r.arbc_impr_name;
        P_IMPR_NAME_STD := r.impr_name_std;
        P_ENG_IMPR_NAME := r.eng_impr_name;
        P_IMPR_CNTCT_NAME := r.impr_cntct_name;
        P_MOBILE_NO := r.mobile_no;
        P_CUSTOMS_ENTERED := r.customs_entered;
        P_IMPR_TYPE_NAME := r.impr_type_name;
    END PRE_UPDATE;

    -- Source: IMPORTERS.POST-UPDATE
    -- APEX  : Process "POST-UPDATE", after "Process form IMPORTERS"
    PROCEDURE POST_UPDATE (P_HQ_IMPR_NBR    IN     importers.hq_impr_nbr%TYPE,
                           P_IMPR_TYPE_CD   IN     importers.impr_type_cd%TYPE,
                           P_BUS_ID_TYPE_CD IN     importers.bus_id_type_cd%TYPE,
                           P_BUS_ID         IN     importers.bus_id%TYPE,
                           P_BUS_ID_BRNCH   IN     importers.bus_id_brnch%TYPE,
                           P_B_EMAIL        IN     VARCHAR2,
                           P_B_MOBILE_NO    IN     VARCHAR2,
                           P_B_ID_NBR       IN     VARCHAR2)
    IS
        r T_RECORD;
    BEGIN
        r.hq_impr_nbr := P_HQ_IMPR_NBR;
        r.impr_type_cd := P_IMPR_TYPE_CD;
        r.bus_id_type_cd := P_BUS_ID_TYPE_CD;
        r.bus_id := P_BUS_ID;
        r.bus_id_brnch := P_BUS_ID_BRNCH;
        r.b_email := P_B_EMAIL;
        r.b_mobile_no := P_B_MOBILE_NO;
        r.b_id_nbr := P_B_ID_NBR;
        IMPORTERS_POST_UPDATE(r);
    END POST_UPDATE;

    -- Source: IMPORTERS.KEY-DELREC (+ PRE-DELETE); the question is the page 0 DELETE confirm
    -- APEX  : Process "KEY-DELREC" (request DELETE) instead of the native delete
    PROCEDURE KEY_DELREC (P_PORT_CD    IN     importers.port_cd%TYPE,
                          P_IMPR_NBR   IN     importers.impr_nbr%TYPE,
                          P_ROW_ID     IN     VARCHAR2,
                          P_CURR_PORT_CD   IN     NUMBER,
                          SSO_APP_USER     IN     VARCHAR2,
                          P_GLOBAL_V_WS_ID IN     VARCHAR2)
    IS
        r T_RECORD;
        c T_CONTEXT;
    BEGIN
        c.curr_port_cd := P_CURR_PORT_CD;
        c.user_id := SSO_APP_USER;
        c.ws_id := P_GLOBAL_V_WS_ID;
        r.port_cd := P_PORT_CD;
        r.impr_nbr := P_IMPR_NBR;
        r.row_id := P_ROW_ID;
        r.rec_status := CASE WHEN r.row_id IS NULL THEN 'NEW' ELSE 'QUERY' END;
        IMPORTERS_KEY_DELREC(r, c);
    END KEY_DELREC;

    -- Source: PU ADJ_FUNS (TMPLT.ENABLE_FUN / DISABLE_FUN)
    -- APEX  : Computation P1110_ADJ_FUNS (comma list of the enabled functions, filter of the f345 Page Functions list)
    FUNCTION ADJ_FUNS (P_IMPR_NBR       IN     importers.impr_nbr%TYPE,
                       P_IMPR_TYPE_CD   IN     importers.impr_type_cd%TYPE,
                       P_BUS_ID_TYPE_CD IN     importers.bus_id_type_cd%TYPE,
                       P_CURR_PORT_CD       IN     NUMBER,
                       SSO_APP_USER         IN     VARCHAR2,
                       P_CLASS_CD           IN     NUMBER,
                       V_USR_TYPE           IN     NUMBER)
        RETURN VARCHAR2
    IS
        r T_RECORD;
        c T_CONTEXT;
    BEGIN
        c.curr_port_cd := P_CURR_PORT_CD;
        c.user_id := SSO_APP_USER;
        c.class_cd := P_CLASS_CD;
        c.user_type := V_USR_TYPE;
        r.impr_nbr := P_IMPR_NBR;
        r.impr_type_cd := P_IMPR_TYPE_CD;
        r.bus_id_type_cd := P_BUS_ID_TYPE_CD;
        g_fun_cd.DELETE;
        g_fun_on.DELETE;
        ADJ_FUNS(r, c);
        RETURN PRIVATE_ENABLED_FUNCTIONS;
    END ADJ_FUNS;

    -- Source: PU EXEC_FUNS (TMPLT EXECUTE_FUNCTION)
    -- APEX  : DA of each entry of the Page Functions list (FOS); then WHEN_NEW_RECORD_INSTANCE
    PROCEDURE EXEC_FUNS (P_PORT_CD        IN     importers.port_cd%TYPE,
                         P_IMPR_NBR       IN     importers.impr_nbr%TYPE,
                         P_BUS_ID         IN     importers.bus_id%TYPE,
                         P_BUS_ID_BRNCH   IN     importers.bus_id_brnch%TYPE,
                         P_ARBC_IMPR_NAME IN     importers.arbc_impr_name%TYPE,
                         P_CURR_PORT_CD       IN     NUMBER,
                         SSO_APP_USER         IN     VARCHAR2,
                         P_GLOBAL_V_WS_ID     IN     VARCHAR2,
                         P_CLASS_CD           IN     NUMBER,
                         V_USR_TYPE           IN     NUMBER,
                         P_P_LETTER_NBR  IN OUT VARCHAR2,
                         P_P_CODE        IN OUT VARCHAR2,
                         P_BRKR_PORT_CD       IN     NUMBER,
                         P_LIC_TYPE           IN     NUMBER,
                         P_BRKR_NBR           IN     NUMBER,
                         FUNCTION_CODE        IN     VARCHAR2)
    IS
        r T_RECORD;
        c T_CONTEXT;
    BEGIN
        c.curr_port_cd := P_CURR_PORT_CD;
        c.user_id := SSO_APP_USER;
        c.ws_id := P_GLOBAL_V_WS_ID;
        c.class_cd := P_CLASS_CD;
        c.user_type := V_USR_TYPE;
        c.letter_nbr := P_P_LETTER_NBR;
        c.code := P_P_CODE;
        c.brkr_port_cd := P_BRKR_PORT_CD;
        c.lic_type := P_LIC_TYPE;
        c.brkr_nbr := P_BRKR_NBR;
        r.port_cd := P_PORT_CD;
        r.impr_nbr := P_IMPR_NBR;
        r.bus_id := P_BUS_ID;
        r.bus_id_brnch := P_BUS_ID_BRNCH;
        r.arbc_impr_name := P_ARBC_IMPR_NAME;
        EXEC_FUNS(r, c, FUNCTION_CODE);
        P_P_LETTER_NBR := c.letter_nbr;
        P_P_CODE := c.code;
    END EXEC_FUNS;

    -- Source: PU UPDATE_IMPORTER_MSG (question of function IMPR_MCI_SERVICE)
    -- APEX  : FOS returns P1110_CONFIRM_TEXT; native Confirm
    FUNCTION UPDATE_IMPORTER_CONFIRM_TEXT (P_PORT_CD        IN     importers.port_cd%TYPE,
                                           P_IMPR_NBR       IN     importers.impr_nbr%TYPE,
                                           P_IMPR_TYPE_CD   IN     importers.impr_type_cd%TYPE,
                                           P_BUS_ID_TYPE_CD IN     importers.bus_id_type_cd%TYPE,
                                           P_BUS_ID         IN     importers.bus_id%TYPE,
                                           P_BUS_ID_BRNCH   IN     importers.bus_id_brnch%TYPE)
        RETURN VARCHAR2
    IS
        r T_RECORD;
    BEGIN
        r.port_cd := P_PORT_CD;
        r.impr_nbr := P_IMPR_NBR;
        r.impr_type_cd := P_IMPR_TYPE_CD;
        r.bus_id_type_cd := P_BUS_ID_TYPE_CD;
        r.bus_id := P_BUS_ID;
        r.bus_id_brnch := P_BUS_ID_BRNCH;
        RETURN UPDATE_IMPORTER_MSG(r);
    END UPDATE_IMPORTER_CONFIRM_TEXT;

    -- Source: PU UPDATE_IMPORTER (function IMPR_MCI_SERVICE, ALLOW_MCI / ALLOW_MOI)
    -- APEX  : DA "IMPR_MCI_SERVICE" after the Confirm (FOS)
    PROCEDURE UPDATE_IMPORTER (P_PORT_CD  IN     importers.port_cd%TYPE,
                               P_IMPR_NBR IN     importers.impr_nbr%TYPE,
                               P_ANSWER   IN     PLS_INTEGER DEFAULT NULL)
    IS
        r T_RECORD;
    BEGIN
        r.port_cd := P_PORT_CD;
        r.impr_nbr := P_IMPR_NBR;
        IF NVL(P_ANSWER, c_yes) = c_yes AND (GET_GLOBAL('ALLOW_MCI') = '1' OR GET_GLOBAL('ALLOW_MOI') = '1') THEN
            UPDATE_IMPORTER(r);
        END IF;
    END UPDATE_IMPORTER;

    -- Source: PU LOV_UPDATE_MOBLIE, part after CALL_FORM(LOV_UPDATE_IMPR_MOBILE)
    -- APEX  : DA "Dialog Closed" of page 111002 (FOS)
    PROCEDURE LOV_UPDATE_MOBLIE (P_IMPR_NBR IN     importers.impr_nbr%TYPE)
    IS
        r T_RECORD;
    BEGIN
        r.impr_nbr := P_IMPR_NBR;
        LOV_UPDATE_MOBLIE(r);
    END LOV_UPDATE_MOBLIE;

    -- Source: PU LOV_UPDATE_MOBLIE, part before CALL_FORM (P_CENTRAL_MOBILE)
    -- APEX  : Computation P111002_CENTRAL_MOBILE (Before Header)
    FUNCTION CENTRAL_MOBILE (P_IMPR_NBR IN     importers.impr_nbr%TYPE,
                             P_CURR_PORT_CD   IN     NUMBER)
        RETURN NUMBER
    IS
        r T_RECORD;
        c T_CONTEXT;
    BEGIN
        c.curr_port_cd := P_CURR_PORT_CD;
        r.impr_nbr := P_IMPR_NBR;
        RETURN CENTRAL_MOBILE(r, c);
    END CENTRAL_MOBILE;


    -- =========================================================================
    -- 7 PACKAGE VERSION   (SELECT IMPR1110.PKG_VERSION FROM dual;)
    -- =========================================================================
    FUNCTION PKG_VERSION
       RETURN VARCHAR2
    IS
    BEGIN
       RETURN V_INFO;
    END PKG_VERSION;

END IMPR1110;
/
SHOW ERRORS
