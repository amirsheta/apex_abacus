-- =============================================================================
-- Package     : pkg_impr1110
-- Source      : IMPR1110.fmb (module IMPR1110_PROD_CENTRL) - "إضافة وتعديل بيانات مستورد"
-- APEX        : application IMPR, page 1110 (alias IMPR1110), region Static ID IMPORTERS
-- Purpose     : server-side logic of block IMPORTERS (validations, PRE/POST DML,
--               POST-QUERY, function-menu actions). Member names = Forms trigger names
--               (see docs/apex_structure_standard.md section 5).
-- Target      : Oracle APEX 21.2 / Oracle Database 12.1.0.2 (identifiers <= 30 bytes,
--               no JSON_OBJECT_T -> APEX_JSON).
-- Depends on  : pkg_forms_compat, and existing DB code used by the form:
--               GNRL, STR_DB, HIJDATE_DB, ACTIVITY, DB_JOURNAL, IMPR, IMPR_CENTRAL,
--               IMPR_UTILITIES, MCISERVICE (LIB_USR schema - verify grants/synonyms).
-- Status      : NOT YET COMPILED against a real 12.1.0.2 / APEX 21.2 instance.
-- =============================================================================
SET DEFINE OFF

CREATE OR REPLACE PACKAGE pkg_impr1110
AUTHID DEFINER
AS
    c_page CONSTANT PLS_INTEGER := 1110;

    -- :PARAMETER.* of the form (session context, filled by get_ctx)
    TYPE t_ctx IS RECORD (
        curr_port_cd  NUMBER,          -- :PARAMETER.P_CURR_PORT_CD
        user_id       VARCHAR2(30),    -- :PARAMETER.P_USER_ID
        ws_id         VARCHAR2(30),    -- :PARAMETER.P_WS_ID
        class_cd      NUMBER,          -- :PARAMETER.P_CLASS_CD
        user_type     NUMBER,          -- :PARAMETER.P_USER_TYPE
        prsnl_impr    NUMBER,          -- :PARAMETER.PRSNL_IMPR (default 0)
        letter_nbr    VARCHAR2(30)     -- :PARAMETER.LETTER_NBR
    );

    -- One record of block IMPORTERS (DB items + non-DB items used by the logic)
    TYPE t_rec IS RECORD (
        port_cd            NUMBER,
        port_name          VARCHAR2(200),
        hq_impr_nbr        NUMBER,
        impr_nbr           NUMBER,
        suspn_status       VARCHAR2(500),
        status_desc        VARCHAR2(200),
        impr_type_cd       NUMBER,
        impr_type_name     VARCHAR2(200),
        bus_id_exprd_dt    DATE,            -- Hijri, mask MI-MM-YYYY
        bus_id_type_cd     NUMBER,
        bus_id_type_name   VARCHAR2(200),
        comm_rgstrtn_type  NUMBER,
        ctry_cd_of_id      NUMBER,
        city_code_of_id    NUMBER,
        id_city_name       VARCHAR2(200),
        id_mins_comm_cd    VARCHAR2(10),
        bus_id             VARCHAR2(15),
        brnh_city_cd       NUMBER,          -- non-DB
        brnh_city_name     VARCHAR2(200),   -- non-DB
        bus_id_brnch       VARCHAR2(10),
        ctry_cd            NUMBER,
        crty_arbc_name     VARCHAR2(200),
        impr_expr_type     NUMBER,
        arbc_impr_name     VARCHAR2(200),
        eng_impr_name      VARCHAR2(200),
        impr_cntct_name    VARCHAR2(200),
        impr_address       VARCHAR2(2000),
        bus_id_issue_dt    DATE,            -- Hijri
        impr_nbr_parent    NUMBER,
        impr_name_parent   VARCHAR2(200),
        wasl_city_name     VARCHAR2(200),
        add_ctry_cd        NUMBER,
        add_crty_arbc_name VARCHAR2(200),
        city_code          NUMBER,
        city_name          VARCHAR2(200),
        impr_pob_nbr       VARCHAR2(20),
        impr_zip_cd        VARCHAR2(20),
        impr_tel_nbr       VARCHAR2(20),
        impr_fax_nbr       VARCHAR2(20),
        impr_telex_nbr     VARCHAR2(20),
        b_email            VARCHAR2(200),   -- screen copy of EMAIL
        email              VARCHAR2(200),
        b_mobile_no        VARCHAR2(20),    -- screen copy of MOBILE_NO
        mobile_no          VARCHAR2(20),
        b_id_nbr           VARCHAR2(20),    -- screen copy of ID_NBR
        id_nbr             VARCHAR2(20),
        bank_iban          VARCHAR2(34),
        car_agent_flag     NUMBER,
        express_post       NUMBER,
        impr_id_type       VARCHAR2(200),
        activity           VARCHAR2(1000),
        bus_id_status      VARCHAR2(10),
        impr_name_std      VARCHAR2(200),
        lst_tran_dt        DATE,
        impd_stmt_nbr      NUMBER,
        impr_data_srce     NUMBER,
        expd_stmt_nbr      NUMBER,
        wvr_entry_nbr      NUMBER,
        customs_entered    NUMBER,
        creation_flag      NUMBER
    );

    -- ---------------------------------------------------------------- context
    FUNCTION  get_ctx RETURN t_ctx;
    FUNCTION  get_page_rec RETURN t_rec;           -- P1110_* -> t_rec
    PROCEDURE set_page_rec (p_rec IN t_rec);       -- t_rec -> P1110_*

    -- ---------------------------------------------------------------- helpers (program units)
    FUNCTION  check_idno (p_id_no IN VARCHAR2) RETURN BOOLEAN;         -- PU CHECK_IDNO
    FUNCTION  is_digit (p_txt IN VARCHAR2) RETURN BOOLEAN;             -- PU IS_DIGIT
    FUNCTION  fmt_hijri (p_dt IN DATE) RETURN VARCHAR2;                -- TO_CHAR(dt,'MI-MM-YYYY')
    FUNCTION  to_hijri (p_txt IN VARCHAR2) RETURN DATE;                -- TO_DATE(txt,'MI-MM-YYYY')
    PROCEDURE chk_impr_dupl (p_rec IN t_rec);                          -- PU CHK_IMPR_DUPL
    PROCEDURE chk_dupl_imp_brkr (p_rec IN t_rec, p_ctx IN t_ctx);      -- PU CHK_DUPL_IMP_BRKR
    PROCEDURE chk_personal (p_rec IN t_rec);                           -- PU CHK_PERSONAL
    PROCEDURE insert_audit_record (p_rec IN t_rec, p_ctx IN t_ctx, p_act_type IN VARCHAR2);
    PROCEDURE update_basic_importer (p_rec IN t_rec);                  -- PU UPDATE_BASIC_IMPORTER (no COMMIT)
    PROCEDURE chk_comm_rgstr (p_rec IN OUT NOCOPY t_rec, p_ctx IN t_ctx); -- shared block of PRE-INSERT/PRE-UPDATE

    -- ---------------------------------------------------------------- form triggers
    PROCEDURE wnfi (p_ctx IN t_ctx);                                   -- WHEN-NEW-FORM-INSTANCE (globals)
    PROCEDURE importers_wcr (p_rec IN OUT NOCOPY t_rec, p_ctx IN t_ctx);       -- WHEN-CREATE-RECORD
    PROCEDURE importers_post_qry (p_rec IN OUT NOCOPY t_rec, p_ctx IN t_ctx);  -- POST-QUERY
    FUNCTION  impr_name_std_qry (p_arbc_name IN VARCHAR2) RETURN VARCHAR2;     -- PRE-QUERY (name search)

    -- ---------------------------------------------------------------- item validations (WHEN-VALIDATE-ITEM)
    PROCEDURE impr_nbr_wvi        (p_rec IN OUT NOCOPY t_rec);
    PROCEDURE impr_type_cd_wvi    (p_rec IN OUT NOCOPY t_rec, p_ctx IN t_ctx);
    PROCEDURE bus_id_exprd_dt_wvi (p_rec IN OUT NOCOPY t_rec);
    PROCEDURE comm_rgstrtn_wlc    (p_rec IN OUT NOCOPY t_rec);         -- COMM_RGSTRTN_TYPE.WHEN-LIST-CHANGED
    PROCEDURE city_code_of_id_wvi (p_rec IN OUT NOCOPY t_rec);
    PROCEDURE bus_id_wvi          (p_rec IN OUT NOCOPY t_rec, p_ctx IN t_ctx);
    PROCEDURE brnh_city_cd_wvi    (p_rec IN OUT NOCOPY t_rec);
    PROCEDURE bus_id_brnch_wvi    (p_rec IN OUT NOCOPY t_rec, p_ctx IN t_ctx);
    PROCEDURE ctry_cd_wvi         (p_rec IN OUT NOCOPY t_rec);
    PROCEDURE arbc_impr_name_wvi  (p_rec IN OUT NOCOPY t_rec);
    PROCEDURE eng_impr_name_wvi   (p_rec IN OUT NOCOPY t_rec);
    PROCEDURE bus_id_issue_dt_wvi (p_rec IN OUT NOCOPY t_rec);
    PROCEDURE impr_nbr_parent_wvi (p_rec IN OUT NOCOPY t_rec, p_ctx IN t_ctx);
    PROCEDURE add_ctry_cd_wvi     (p_rec IN OUT NOCOPY t_rec);
    PROCEDURE city_code_wvi       (p_rec IN OUT NOCOPY t_rec);
    PROCEDURE impr_tel_nbr_wvi    (p_rec IN OUT NOCOPY t_rec);
    PROCEDURE b_email_wvi         (p_rec IN OUT NOCOPY t_rec);
    PROCEDURE b_mobile_no_wvi     (p_rec IN OUT NOCOPY t_rec, p_ctx IN t_ctx);
    PROCEDURE bank_iban_wvi       (p_rec IN OUT NOCOPY t_rec);
    PROCEDURE b_id_nbr_wvi        (p_rec IN OUT NOCOPY t_rec);

    -- ---------------------------------------------------------------- DML (block IMPORTERS)
    PROCEDURE importers_pre_ins  (p_rec IN OUT NOCOPY t_rec, p_ctx IN t_ctx);
    PROCEDURE importers_ins      (p_rec IN OUT NOCOPY t_rec);   -- Forms default INSERT
    PROCEDURE importers_post_ins (p_rec IN OUT NOCOPY t_rec, p_ctx IN t_ctx);
    PROCEDURE importers_pre_upd  (p_rec IN OUT NOCOPY t_rec, p_ctx IN t_ctx);
    PROCEDURE importers_upd      (p_rec IN t_rec);              -- Forms default UPDATE
    PROCEDURE importers_post_upd (p_rec IN t_rec);
    PROCEDURE importers_pre_del  (p_rec IN t_rec);
    PROCEDURE importers_del      (p_rec IN t_rec);              -- KEY-DELREC

    -- ---------------------------------------------------------------- function menu (EXEC_FUNS / ADJ_FUNS)
    FUNCTION  fun_allowed (p_fun IN VARCHAR2, p_rec IN t_rec, p_ctx IN t_ctx) RETURN BOOLEAN;  -- ADJ_FUNS
    FUNCTION  f1_comm_name (p_rec IN t_rec) RETURN VARCHAR2;   -- IMPR1110F1/F5: name from COMM_IMPR_RGSTR
    PROCEDURE f3_set_type_19 (p_rec IN OUT NOCOPY t_rec, p_ctx IN t_ctx);  -- IMPR1110F3 (class 19)

    -- ---------------------------------------------------------------- UI state (INTRFACE.Make_Field_Entrable)
    FUNCTION  ui_state_json (p_rec IN t_rec, p_ctx IN t_ctx) RETURN CLOB;

    -- ---------------------------------------------------------------- thin APEX wrappers
    -- Validation "PL/SQL Function Body (returning Error Text)":
    --     RETURN pkg_impr1110.validate_item('BUS_ID');
    FUNCTION  validate_item (p_item IN VARCHAR2) RETURN VARCHAR2;
    -- Process "IMPORTERS.PRE-INSERT/INSERT/POST-INSERT" etc. :  pkg_impr1110.page_dml(:REQUEST);
    PROCEDURE page_dml (p_request IN VARCHAR2);
    -- Before Header process "IMPORTERS.POST-QUERY": pkg_impr1110.page_fetch;
    PROCEDURE page_fetch;
    -- Before Header process "WHEN-NEW-FORM-INSTANCE"
    PROCEDURE page_wnfi;

END pkg_impr1110;
/
SHOW ERRORS
