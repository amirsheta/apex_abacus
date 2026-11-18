-- =============================================================================
-- Package     : IMPR1110
-- Source form : IMPR1110.fmb (module IMPR1110_PROD_CENTRL) - "إضافة وتعديل بيانات مستورد"
--               XML: forms/IMPR/IMPR1110_fmb.xml
-- Target      : Oracle APEX 21.2 / Oracle Database 12.1.0.2
-- Author      : Claude Code
-- Created     : 2026-11-18
-- Version     : 1.0.0  (step 02 - logic extraction, re-done from the full trigger text)
-- Owner       : LIB_APX_USR (public synonym IMPR1110; EXECUTE granted to LIB_USR, SECURITY_DEFAULT, SECURITY_PROD, CUSTOMS)
-- Purpose     : Business logic of block IMPORTERS, organised like the form:
--               FORM LEVEL -> BLOCK IMPORTERS (block triggers, item triggers in item order)
--               -> PROGRAM UNITS (same names as in Forms) -> UI state recorder.
-- Rules       : - no reference to APEX page items: item values come in as t_rec,
--                 :PARAMETER.* as t_ctx; :GLOBAL.* through FORMS_COMPAT.get/set_global.
--               - INTRFACE.Make_Field_Entrable / SET_ITEM_PROPERTY / GO_ITEM are recorded
--                 (ui_* below) at the exact place Forms executes them; the page reads
--                 ui_json after each call and applies it with a Dynamic Action.
--               - every identifier <= 30 bytes; no 12.2+/18c+ syntax.
-- Depends on  : FORMS_COMPAT, and DB code called by the form (see extraction report §7):
--               GNRL, STR_DB, HIJDATE_DB, ACTIVITY, DB_JOURNAL, IMPR, IMPR_CENTRAL,
--               IMPR_UTILITIES, MCISERVICE, WEB_SERVICES_GAZT (LIB_USR schema).
-- Status      : NOT COMPILED - no 12.1.0.2 / APEX 21.2 instance was available.
-- History     : 2026-11-18 Claude Code 1.0.0 Replaces the summary-based draft
--               (kept in rollback/IMPR1110/pkg_impr1110_*_v0.sql).
-- =============================================================================
SET DEFINE OFF

CREATE OR REPLACE PACKAGE LIB_APX_USR.IMPR1110 AS
   V_PKG_VERSION       VARCHAR2 (100) := 'VERSION NO. IS:' || '002';
   V_PKG_VERSION_QC    VARCHAR2 (100) := 'VERSION NO. IS:' || '001';
   V_PKG_VERSION_DEV   VARCHAR2 (100) := 'VERSION NO. IS:' || '001';
   FUNCTION PKG_VERSION
      RETURN VARCHAR2;
   V_PACKAGE_NAME      VARCHAR2 (50) := 'IMPR1110';
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

    c_version CONSTANT VARCHAR2(10) := '1.0.0';

    -- Forms ALERT_BUTTON1 / ALERT_BUTTON2 answers passed back from a Confirm DA
    c_yes     CONSTANT PLS_INTEGER := 1;
    c_no      CONSTANT PLS_INTEGER := 2;

    -- :PARAMETER.* of the form (session context)
    TYPE t_ctx IS RECORD (
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

    -- One record of block IMPORTERS (all base-table items + non-DB items used by the code)
    TYPE t_rec IS RECORD (
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

    -- =========================================================================
    -- FORM LEVEL
    -- =========================================================================
    -- Source: IMPR1110.WHEN-NEW-FORM-INSTANCE (business part)  APEX: Before Header process
    PROCEDURE wnfi (p_rec IN OUT NOCOPY t_rec, p_ctx IN t_ctx);

    -- =========================================================================
    -- BLOCK IMPORTERS - block triggers
    -- =========================================================================
    -- Source: IMPORTERS.WHEN-CREATE-RECORD
    PROCEDURE importers_wcr (p_rec IN OUT NOCOPY t_rec, p_ctx IN t_ctx);
    -- Source: IMPORTERS.WHEN-NEW-RECORD-INSTANCE (needs p_answer for IMPR1110F1/F5 Confirm)
    PROCEDURE importers_wnri (p_rec    IN OUT NOCOPY t_rec,
                              p_ctx    IN OUT NOCOPY t_ctx,
                              p_answer IN PLS_INTEGER DEFAULT c_yes);
    -- IMPR1110F1/F5 Confirm text ("سيتم تعديل الإسم إلى ...") or NULL when no Confirm is shown
    FUNCTION  wnri_confirm_text (p_rec IN t_rec, p_ctx IN t_ctx) RETURN VARCHAR2;
    -- Source: IMPORTERS.PRE-RECORD
    PROCEDURE importers_pre_rec (p_rec IN OUT NOCOPY t_rec, p_ctx IN t_ctx);
    -- Source: IMPORTERS.WHEN-CLEAR-BLOCK
    PROCEDURE importers_wcb;
    -- Source: IMPORTERS.PRE-QUERY (p_rec = query criteria; PORT_NAME criterion -> region SQL)
    PROCEDURE importers_pre_qry (p_rec IN OUT NOCOPY t_rec, p_ctx IN t_ctx);
    -- Source: IMPORTERS.POST-QUERY
    PROCEDURE importers_post_qry (p_rec IN OUT NOCOPY t_rec, p_ctx IN t_ctx);
    -- Source: IMPORTERS.PRE-INSERT (p_answer = answer to the class 1 / user type 3 Confirm)
    PROCEDURE importers_pre_ins (p_rec    IN OUT NOCOPY t_rec,
                                 p_ctx    IN t_ctx,
                                 p_answer IN PLS_INTEGER DEFAULT c_yes);
    -- Source: Forms default INSERT of block IMPORTERS (no ON-INSERT trigger exists)
    PROCEDURE importers_ins (p_rec IN OUT NOCOPY t_rec);
    -- Source: IMPORTERS.POST-INSERT
    PROCEDURE importers_post_ins (p_rec IN OUT NOCOPY t_rec, p_ctx IN t_ctx);
    -- Source: IMPORTERS.PRE-UPDATE
    PROCEDURE importers_pre_upd (p_rec IN OUT NOCOPY t_rec, p_ctx IN t_ctx);
    -- Source: Forms default UPDATE of block IMPORTERS (key = ROWID, no ON-UPDATE trigger)
    PROCEDURE importers_upd (p_rec IN t_rec);
    -- Source: IMPORTERS.POST-UPDATE
    PROCEDURE importers_post_upd (p_rec IN OUT NOCOPY t_rec);
    -- Source: IMPORTERS.PRE-DELETE
    PROCEDURE importers_pre_del (p_rec IN t_rec, p_ctx IN t_ctx);
    -- Source: IMPORTERS.KEY-DELREC (business part, after the Confirm DA answered "yes")
    PROCEDURE importers_key_delrec (p_rec IN t_rec, p_ctx IN t_ctx);
    -- Source: IMPORTERS.ON-ERROR + PU CGTE$CHECK_CONSTRAINT_VIO: Forms text for a DB error.
    -- p_op = 'I' / 'U' / 'D' (operation that failed: FRM-40508 / 40509 / 40510)
    FUNCTION  importers_on_error (p_op      IN VARCHAR2,
                                  p_sqlcode IN NUMBER,
                                  p_sqlerrm IN VARCHAR2) RETURN VARCHAR2;

    -- =========================================================================
    -- BLOCK IMPORTERS - item triggers (Forms item order)
    -- p_from_item = TRUE  when :SYSTEM.TRIGGER_ITEM = :SYSTEM.CURSOR_ITEM (user left the item)
    --             = FALSE when the item is validated during record/commit validation
    -- =========================================================================
    PROCEDURE port_cd_wvi          (p_rec IN OUT NOCOPY t_rec);
    PROCEDURE hq_impr_nbr_post_chg;
    PROCEDURE impr_nbr_wvi         (p_rec IN OUT NOCOPY t_rec);
    PROCEDURE impr_type_cd_wvi     (p_rec IN OUT NOCOPY t_rec, p_ctx IN t_ctx);
    PROCEDURE impr_type_cd_post_chg(p_rec IN t_rec);
    PROCEDURE impr_type_cd_wnii    (p_rec IN OUT NOCOPY t_rec);
    -- LOV LOV_IMPR_TYPE return (KEY-LISTVAL after CALL_FORM)
    PROCEDURE impr_type_cd_lov_ret (p_rec IN OUT NOCOPY t_rec);
    PROCEDURE bus_id_exprd_dt_wvi  (p_rec IN t_rec, p_from_item IN BOOLEAN DEFAULT TRUE);
    PROCEDURE bus_id_type_post_chg (p_rec IN OUT NOCOPY t_rec);
    PROCEDURE comm_rgstrtn_wlc     (p_rec IN OUT NOCOPY t_rec);
    PROCEDURE ctry_cd_of_id_wvi    (p_rec IN OUT NOCOPY t_rec);
    PROCEDURE city_code_of_id_wvi  (p_rec IN OUT NOCOPY t_rec);
    PROCEDURE city_code_of_id_wnii (p_rec IN t_rec);
    -- p_cr_answer : answer to alert 9-120 (ALERT_BUTTON1 = take the prefixed number)
    -- p_susp_answer: answer to the "suspended importer with same BUS_ID" warning
    PROCEDURE bus_id_wvi           (p_rec         IN OUT NOCOPY t_rec,
                                    p_ctx         IN t_ctx,
                                    p_cr_answer   IN PLS_INTEGER DEFAULT c_yes,
                                    p_susp_answer IN PLS_INTEGER DEFAULT c_yes);
    -- Suspended importer number that triggers the BUS_ID warning (0 = no warning)
    FUNCTION  bus_id_susp_impr     (p_rec IN t_rec) RETURN NUMBER;
    PROCEDURE bus_id_post_chg;
    PROCEDURE bus_id_wnii          (p_rec IN t_rec);
    PROCEDURE brnh_city_cd_wvi     (p_rec IN OUT NOCOPY t_rec);
    PROCEDURE brnh_city_cd_wnii;
    PROCEDURE bus_id_brnch_wvi     (p_rec       IN OUT NOCOPY t_rec,
                                    p_ctx       IN t_ctx,
                                    p_cr_answer IN PLS_INTEGER DEFAULT c_yes);
    PROCEDURE bus_id_brnch_post_chg;
    PROCEDURE bus_id_brnch_wnii    (p_rec IN t_rec);
    PROCEDURE ctry_cd_wvi          (p_rec IN OUT NOCOPY t_rec);
    PROCEDURE impr_expr_type_post_chg;
    PROCEDURE arbc_impr_name_wvi   (p_rec IN OUT NOCOPY t_rec);
    PROCEDURE arbc_impr_name_key_nxt (p_rec IN OUT NOCOPY t_rec);
    PROCEDURE eng_impr_name_wvi    (p_rec IN OUT NOCOPY t_rec);
    PROCEDURE bus_id_issue_dt_wvi  (p_rec IN t_rec, p_from_item IN BOOLEAN DEFAULT TRUE);
    PROCEDURE impr_nbr_parent_wvi  (p_rec IN OUT NOCOPY t_rec);
    PROCEDURE add_ctry_cd_wvi      (p_rec IN OUT NOCOPY t_rec);
    PROCEDURE city_code_wvi        (p_rec IN OUT NOCOPY t_rec);
    PROCEDURE impr_tel_nbr_wvi     (p_rec IN t_rec);
    PROCEDURE b_email_wvi          (p_rec IN t_rec, p_from_item IN BOOLEAN DEFAULT TRUE);
    PROCEDURE b_email_post_chg     (p_rec IN OUT NOCOPY t_rec, p_ctx IN t_ctx);
    PROCEDURE email_wvi            (p_rec IN t_rec, p_from_item IN BOOLEAN DEFAULT TRUE);
    PROCEDURE b_mobile_no_wvi      (p_rec IN t_rec, p_ctx IN t_ctx);
    PROCEDURE b_mobile_no_post_chg (p_rec IN OUT NOCOPY t_rec, p_ctx IN t_ctx);
    PROCEDURE bank_iban_wvi        (p_rec IN OUT NOCOPY t_rec);
    PROCEDURE bank_iban_wnii       (p_rec IN OUT NOCOPY t_rec);
    PROCEDURE b_id_nbr_wvi         (p_rec IN t_rec);
    PROCEDURE b_id_nbr_post_chg    (p_rec IN OUT NOCOPY t_rec, p_ctx IN t_ctx);

    -- =========================================================================
    -- PROGRAM UNITS (same names as in Forms)
    -- =========================================================================
    FUNCTION  check_idno (id_no IN VARCHAR2) RETURN BOOLEAN;
    FUNCTION  is_digit (txt_num IN VARCHAR2) RETURN BOOLEAN;
    PROCEDURE check_bus_id;
    PROCEDURE chk_bus_id_brnch (p_rec IN t_rec);
    PROCEDURE chk_impr_dupl (p_rec IN t_rec);
    PROCEDURE chk_dupl_imp_brkr (p_rec IN t_rec, p_ctx IN t_ctx);
    PROCEDURE chk_personal (p_rec          IN OUT NOCOPY t_rec,
                            p_ctx          IN t_ctx,
                            p_impr_type_cd IN NUMBER,
                            p_hq_impr_nbr  IN NUMBER,
                            p_stop         IN NUMBER DEFAULT 1);
    PROCEDURE insert_audit_record (p_rec IN t_rec, p_ctx IN t_ctx, v_act_type IN VARCHAR2);
    PROCEDURE update_basic_importer (p_rec IN t_rec);
    PROCEDURE return_impr_id (p_rec IN t_rec, p_ctx IN t_ctx);
    PROCEDURE broker_int (p_rec IN OUT NOCOPY t_rec);
    PROCEDURE adj_funs (p_rec IN t_rec, p_ctx IN t_ctx);
    -- Function-menu state after ADJ_FUNS: 'Y' enabled / 'N' disabled / NULL not touched
    FUNCTION  fun_state (p_fun IN VARCHAR2) RETURN VARCHAR2;
    PROCEDURE get_main_cr_data (p_rec IN OUT NOCOPY t_rec);
    PROCEDURE get_branch_cr_data (p_rec IN OUT NOCOPY t_rec);
    PROCEDURE get_cr_data (p_rec           IN OUT NOCOPY t_rec,
                           p_string_result IN VARCHAR2,
                           p_type          IN VARCHAR2);
    -- EXEC_FUNS(CD): server part of every function code; UI part -> see extraction report §5
    PROCEDURE exec_funs (p_rec IN OUT NOCOPY t_rec, p_ctx IN OUT NOCOPY t_ctx, cd IN VARCHAR2);
    PROCEDURE create_brkr_impr_auth (p_rec IN t_rec, p_ctx IN t_ctx);
    -- UPDATE_IMPORTER: Confirm text, then the update itself after "yes"
    FUNCTION  update_importer_msg (p_rec IN t_rec) RETURN VARCHAR2;
    PROCEDURE update_importer (p_rec IN t_rec);
    -- LOV_UPDATE_MOBLIE: part after the LOV_UPDATE_IMPR_MOBILE dialog returned :GLOBAL.MOBILE_NO
    FUNCTION  central_mobile (p_rec IN t_rec, p_ctx IN t_ctx) RETURN NUMBER;
    PROCEDURE lov_update_moblie (p_rec IN t_rec);

    -- =========================================================================
    -- UI STATE RECORDER (INTRFACE.Make_Field_Entrable / SET_ITEM_PROPERTY / GO_ITEM / alerts)
    -- =========================================================================
    PROCEDURE ui_reset;
    -- {"items":[{"item":"BUS_ID","prop":"ENTRABLE","value":false},...],
    --  "focus":"IMPR_NBR","messages":["..."],"funs":[{"fun":"IMPR1110F3","enabled":true}]}
    FUNCTION  ui_json RETURN CLOB;
    -- Read access to the recorded entries (used by IMPR1110_APX to keep the item state
    -- on the server, so REQUIRED / ENTRABLE can be enforced at SAVE)
    FUNCTION  ui_count RETURN PLS_INTEGER;
    PROCEDURE ui_entry (p_idx  IN  PLS_INTEGER,
                        p_item OUT VARCHAR2,
                        p_prop OUT VARCHAR2,
                        p_val  OUT VARCHAR2);


    -- =========================================================================
    -- APEX ENTRY POINTS (f345)  - every page process / validation / DA / AJAX callback
    -- of pages 1110 / 111001 / 111002 calls these members (formerly package IMPR1110 1.0.0,
    -- merged into this package 2026-11-18 when the pkg_ prefix was dropped)
    -- =========================================================================
    c_page        CONSTANT PLS_INTEGER := 1110;
    c_search_page CONSTANT PLS_INTEGER := 111001;
    c_mobile_page CONSTANT PLS_INTEGER := 111002;

    -- ------------------------------------------------------------- f345 helpers
    -- Raises the error text (used by dynamic actions: IMPR1110.CHK(IMPR1110.<ITEM>_VAL(...)))
    PROCEDURE CHK (I_ERR IN VARCHAR2);
    -- Error text when a required value is empty, else NULL
    FUNCTION  REQUIRED_VAL (I_VALUE IN VARCHAR2, I_LABEL IN VARCHAR2) RETURN VARCHAR2;

    -- ------------------------------------------------------------- Before Header
    -- Source: P0_PAGE_PK CHECK - forget a key that is not an importer of the current port
    PROCEDURE P0_PAGE_PK_CHECK (IO_P0_PAGE_PK IN OUT VARCHAR2);
    -- Source: PARAMETERS - module id of IMPR1110 in SC_SYSTEM_OBJECTS
    FUNCTION  GET_MODULE_ID (I_P1110_MODULE_ID IN VARCHAR2) RETURN VARCHAR2;
    -- Source: :PARAMETER.PRSNL_IMPR / :PARAMETER.LETTER_NBR passed by the caller
    PROCEDURE PARAMETERS_ENTRY (IO_P_PRSNL_IMPR      IN OUT VARCHAR2,
                                IO_P_LETTER_NBR      IN OUT VARCHAR2,
                                IO_P1110_PRSNL_IMPR  IN OUT VARCHAR2,
                                IO_P1110_LETTER_NBR  IN OUT VARCHAR2);
    -- Source: FORM.WHEN-NEW-FORM-INSTANCE
    PROCEDURE WHEN_NEW_FORM_INSTANCE;
    -- Source: P0_PAGE_PK (record chosen on the search page / kept by the toolbar)
    PROCEDURE SET_PAGE_PK (I_P0_PAGE_PK IN VARCHAR2);
    -- Source: IMPORTERS.PRE-QUERY, POST-QUERY, PRE-RECORD, WHEN-NEW-RECORD-INSTANCE
    PROCEDURE POST_QUERY;
    -- Source: IMPORTERS.WHEN-CREATE-RECORD, PRE-RECORD, WHEN-NEW-RECORD-INSTANCE
    PROCEDURE WHEN_CREATE_RECORD;
    -- Source: hero region title (f345 HEADER TITLE)
    PROCEDURE HEADER_TITLE (I_P1110_MODULE_ID   IN VARCHAR2,
                            IO_P1110_HERO_TITLE IN OUT VARCHAR2);
    -- Source: PU LOV_UPDATE_MOBLIE - URL of page 111002 with checksum
    FUNCTION  MOBILE_URL (I_P1110_IMPR_NBR IN VARCHAR2) RETURN VARCHAR2;

    -- ------------------------------------------------------------- After Submit
    -- Source: IMPORTERS.PRE-INSERT, INSERT, POST-INSERT (request CREATE)
    PROCEDURE ON_INSERT;
    -- Source: IMPORTERS.PRE-UPDATE, UPDATE, POST-UPDATE (request SAVE)
    PROCEDURE ON_UPDATE;
    -- Source: IMPORTERS.KEY-DELREC, PRE-DELETE (request DELETE)
    PROCEDURE KEY_DELREC;
    -- Source: IMPORTERS.IMPR_NBR re-query (QUERY / QUERY_NBR)
    PROCEDURE EXECUTE_QUERY (I_REQUEST IN VARCHAR2, I_P1110_IMPR_NBR IN VARCHAR2);

    -- ------------------------------------------------------------- validations (on submit)
    -- Each returns the error text of the item's POST-CHANGE + WHEN-VALIDATE-ITEM, or NULL.
    FUNCTION PORT_CD_VAL         (I_P1110_PORT_CD         IN VARCHAR2) RETURN VARCHAR2;
    FUNCTION HQ_IMPR_NBR_VAL     (I_P1110_HQ_IMPR_NBR     IN VARCHAR2) RETURN VARCHAR2;
    FUNCTION IMPR_NBR_VAL        (I_P1110_IMPR_NBR        IN VARCHAR2) RETURN VARCHAR2;
    FUNCTION IMPR_TYPE_CD_VAL    (I_P1110_IMPR_TYPE_CD    IN VARCHAR2) RETURN VARCHAR2;
    FUNCTION BUS_ID_EXPRD_DT_VAL (I_P1110_BUS_ID_EXPRD_DT IN VARCHAR2) RETURN VARCHAR2;
    FUNCTION BUS_ID_TYPE_CD_VAL  (I_P1110_BUS_ID_TYPE_CD  IN VARCHAR2) RETURN VARCHAR2;
    FUNCTION CITY_CODE_OF_ID_VAL (I_P1110_CITY_CODE_OF_ID IN VARCHAR2) RETURN VARCHAR2;
    FUNCTION BUS_ID_VAL          (I_P1110_BUS_ID          IN VARCHAR2) RETURN VARCHAR2;
    FUNCTION BRNH_CITY_CD_VAL    (I_P1110_BRNH_CITY_CD    IN VARCHAR2) RETURN VARCHAR2;
    FUNCTION BUS_ID_BRNCH_VAL    (I_P1110_BUS_ID_BRNCH    IN VARCHAR2) RETURN VARCHAR2;
    FUNCTION CTRY_CD_VAL         (I_P1110_CTRY_CD         IN VARCHAR2) RETURN VARCHAR2;
    FUNCTION IMPR_EXPR_TYPE_VAL  (I_P1110_IMPR_EXPR_TYPE  IN VARCHAR2) RETURN VARCHAR2;
    FUNCTION ARBC_IMPR_NAME_VAL  (I_P1110_ARBC_IMPR_NAME  IN VARCHAR2) RETURN VARCHAR2;
    FUNCTION ENG_IMPR_NAME_VAL   (I_P1110_ENG_IMPR_NAME   IN VARCHAR2) RETURN VARCHAR2;
    FUNCTION BUS_ID_ISSUE_DT_VAL (I_P1110_BUS_ID_ISSUE_DT IN VARCHAR2) RETURN VARCHAR2;
    FUNCTION IMPR_NBR_PARENT_VAL (I_P1110_IMPR_NBR_PARENT IN VARCHAR2) RETURN VARCHAR2;
    FUNCTION ADD_CTRY_CD_VAL     (I_P1110_ADD_CTRY_CD     IN VARCHAR2) RETURN VARCHAR2;
    FUNCTION CITY_CODE_VAL       (I_P1110_CITY_CODE       IN VARCHAR2) RETURN VARCHAR2;
    FUNCTION IMPR_TEL_NBR_VAL    (I_P1110_IMPR_TEL_NBR    IN VARCHAR2) RETURN VARCHAR2;
    FUNCTION B_EMAIL_VAL         (I_P1110_B_EMAIL         IN VARCHAR2) RETURN VARCHAR2;
    FUNCTION EMAIL_VAL           (I_P1110_EMAIL           IN VARCHAR2) RETURN VARCHAR2;
    FUNCTION B_MOBILE_NO_VAL     (I_P1110_B_MOBILE_NO     IN VARCHAR2) RETURN VARCHAR2;
    FUNCTION BANK_IBAN_VAL       (I_P1110_BANK_IBAN       IN VARCHAR2) RETURN VARCHAR2;
    FUNCTION B_ID_NBR_VAL        (I_P1110_B_ID_NBR        IN VARCHAR2) RETURN VARCHAR2;
    FUNCTION CTRY_CD_OF_ID_VAL   (I_P1110_CTRY_CD_OF_ID   IN VARCHAR2) RETURN VARCHAR2;
    -- Source: FRM-40202 at commit (static Required + SET_ITEM_PROPERTY REQUIRED)
    FUNCTION REQUIRED_ITEMS_VAL RETURN VARCHAR2;

    -- ------------------------------------------------------------- AJAX callbacks (impr1110.js)
    PROCEDURE AJAX_ITEM;        -- all item triggers (x01 item, x02 event)
    PROCEDURE AJAX_CONFIRM;     -- CONFIRM / WARNING alert texts
    PROCEDURE AJAX_FUN;         -- PU EXEC_FUNS

    -- ------------------------------------------------------------- page 111002 (LOV_UPDATE_IMPR_MOBILE)
    FUNCTION  CENTRAL_MOBILE (I_P111002_IMPR_NBR IN VARCHAR2) RETURN NUMBER;
    PROCEDURE MOBILE_OK      (I_P111002_MOBILE_NO IN VARCHAR2);
    PROCEDURE MOBILE_CANCEL;

END IMPR1110;
/
SHOW ERRORS

-- -----------------------------------------------------------------------------
-- Synonym and grants (run as a user allowed to create public synonyms / grant on LIB_APX_USR).
-- CUSTOMS = parsing schema of the APEX application: APEX needs the direct grant.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PUBLIC SYNONYM IMPR1110 FOR LIB_APX_USR.IMPR1110;

GRANT EXECUTE ON LIB_APX_USR.IMPR1110 TO LIB_USR;

GRANT EXECUTE ON LIB_APX_USR.IMPR1110 TO SECURITY_DEFAULT;

GRANT EXECUTE ON LIB_APX_USR.IMPR1110 TO SECURITY_PROD;

GRANT EXECUTE ON LIB_APX_USR.IMPR1110 TO CUSTOMS;
