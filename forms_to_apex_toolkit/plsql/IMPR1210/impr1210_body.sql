-- =============================================================================
-- Package body: IMPR1210   (matches impr1210_spec.sql - f345 standard)
-- Source form : IMPR1210.fmb   Target: APEX 21.2 / DB 12.1.0.2   Version: 001
-- Author      : Claude Code     Created: 2026-11-25   (see the spec history)
-- Rules: no Forms built-ins (FORMS_APX instead), no COMMIT / ROLLBACK except EXEC_FUNS (Forms commits there),
--        parameters named after their binds without I_ / IO_ / O_; page items P<page>_X -> P_X;
--        inside SQL every parameter is qualified with its member name; identifiers <= 30 bytes.
-- Common helpers: FORMS_APX (version 004), called as FORMS_APX.<NAME>.
-- Layout (docs/f345_reference_standard.md §10): PRIVATE HELPERS (top, used by the members below)
-- -> f345 HELPERS -> BLOCK AGNTS -> FUNCTIONS -> VERSION -> UI LOGIC FOR APEX DYNAMIC ACTIONS (comments only).
-- Status: NOT COMPILED. External DB packages without source: LIB_USR.IMPR, DCLTN, STR_DB (calls copied unchanged).
-- =============================================================================
SET DEFINE OFF

CREATE OR REPLACE PACKAGE BODY LIB_APX_USR.IMPR1210
AS
    c_status_valid       CONSTANT NUMBER := 1;      -- ATHRZTN_STA_CD 1 = ساري
    c_status_cancelled   CONSTANT NUMBER := 2;      -- ATHRZTN_STA_CD 2 = غير ساري
    c_used               CONSTANT NUMBER := 1;      -- DCLTN.IMPR_IMPR_AUTH_USED = 1: used in an importer declaration
    c_suspended          CONSTANT NUMBER := 1;      -- IMPR.IMPR_SUSPENDED = 1
    -- ACTIVITY.ADD_ACTIVITY(9, 1, <type>, ...): system object 9, subject 1 (authorization)
    c_activity_object    CONSTANT NUMBER := 9;
    c_activity_subject   CONSTANT NUMBER := 1;
    c_activity_insert    CONSTANT NUMBER := 1;      -- PRE-INSERT
    c_activity_update    CONSTANT NUMBER := 2;      -- PRE-UPDATE
    c_activity_stop      CONSTANT NUMBER := 3;      -- EXEC_FUNS CD1_STOPIMPRAUTH
    c_activity_reuse     CONSTANT NUMBER := 4;      -- EXEC_FUNS CD2_REUSEIMPRAUTH

    -- Forms texts (literals of the triggers)
    c_msg_can_update       CONSTANT VARCHAR2(100) := ' يمكن التعديل';     -- WHEN-NEW-RECORD-INSTANCE (leading space as Forms)
    c_msg_delete_not_allowed CONSTANT VARCHAR2(200) := 'لا يمكن حذف بيانات من هذه الشاشة';   -- = IMPR1150 / IMPR1116 (to agree)

    -- =========================================================================
    -- PRIVATE HELPERS
    -- =========================================================================

    -- ACTIVITY.ADD_ACTIVITY(9, 1, p_type, :PORT_CD || '!' || :ATHRZTN_SEQ_NBR) of CIC_LIB.pld -> ACTIVITY_DB with
    -- the f345 items for :PARAMETER.P_CURR_PORT_CD / P_USER_ID / P_WS_ID (as IMPR1150 add_activity).
    -- Failure: STR.DISPALERT(V_MSG_TXT) + RAISE FORM_TRIGGER_FAILURE -> FORMS_APX.FORM_TRIGGER_FAILURE(v_msg).
    PROCEDURE add_activity (p_type            IN NUMBER,
                            p_port_cd         IN NUMBER,
                            p_athrztn_seq_nbr IN NUMBER,
                            p_curr_port_cd    IN NUMBER,
                            p_user_id         IN VARCHAR2,
                            p_ws_id           IN VARCHAR2)
    IS
        v_msg VARCHAR2(2000);
    BEGIN
        IF activity_db.add_activity(c_activity_object, c_activity_subject, p_type,
                                    p_port_cd || '!' || p_athrztn_seq_nbr,
                                    p_curr_port_cd, p_user_id, p_ws_id, v_msg) = 0 THEN
            FORMS_APX.FORM_TRIGGER_FAILURE(v_msg);
        END IF;
    END add_activity;

    -- PU CHECK_SUSPENSION: IMPR.Impr_Suspended(PORT_CD, IMORTER_NUMBER, HIJDATE.Cur_Hij_Date) = 1.
    -- LIB_USR.IMPR is a DB package (MISSING SOURCE), called as IMPR1110 calls it.
    FUNCTION importer_suspended (p_port_cd  IN NUMBER,
                                 p_impr_nbr IN NUMBER) RETURN BOOLEAN
    IS
    BEGIN
        RETURN lib_usr.impr.impr_suspended(p_port_cd, p_impr_nbr, FORMS_APX.CUR_HIJ_DATE) = c_suspended;
    END importer_suspended;

    -- Cursor C_P_NAME of IMPR_NBR / IMPR_NBR_AG WHEN-VALIDATE-ITEM + CGFK$CHK_AGNTS_AG_IMP_FK / _IMP_AGENT_ID:
    -- the importer (or broker company, also an IMPORTERS row) of the port. FALSE when there is none.
    FUNCTION importer_row (p_port_cd        IN     NUMBER,
                           p_impr_nbr       IN     NUMBER,
                           p_impr_name      IN OUT VARCHAR2,
                           p_impr_expr_type IN OUT NUMBER) RETURN BOOLEAN
    IS
    BEGIN
        SELECT i.arbc_impr_name, i.impr_expr_type
          INTO p_impr_name, p_impr_expr_type
          FROM importers i
         WHERE i.impr_nbr = p_impr_nbr
           AND i.port_cd = p_port_cd;
        RETURN TRUE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN FALSE;
    END importer_row;

    -- The checks shared by IMPR_NBR and IMPR_NBR_AG WHEN-VALIDATE-ITEM, in the Forms order:
    -- not an importer of the port -> 9-20; suspended (CHECK_SUSPENSION) -> 9-70; same number as the other item -> 9-10.
    FUNCTION importer_error (p_port_cd     IN NUMBER,
                             p_impr_nbr    IN NUMBER,
                             p_other_nbr   IN NUMBER) RETURN VARCHAR2
    IS
        v_name VARCHAR2(200);
        v_type NUMBER;
    BEGIN
        IF p_impr_nbr IS NULL THEN
            RETURN NULL;                    -- Required: the item's Value Required check
        END IF;
        IF NOT importer_row(p_port_cd, p_impr_nbr, v_name, v_type) THEN
            RETURN FORMS_APX.ARABIC_MESSAGE(9, 20);                -- Str.DispArbMsg(9, 20, 'ERROR') + RAISE
        END IF;
        IF importer_suspended(p_port_cd, p_impr_nbr) THEN
            RETURN FORMS_APX.ARABIC_MESSAGE(9, 70);                -- Check_Suspension: DispArbMsg(9, 70, 'ERROR') + RAISE
        END IF;
        IF p_other_nbr IS NOT NULL AND p_impr_nbr = p_other_nbr THEN
            RETURN FORMS_APX.ARABIC_MESSAGE(9, 10);                -- STR.DispArbMsg(9, 10, ...) + RAISE
        END IF;
        RETURN NULL;
    END importer_error;

    -- The stored status of the authorization (NULL when the row does not exist)
    FUNCTION stored_status (p_port_cd         IN NUMBER,
                            p_athrztn_seq_nbr IN NUMBER) RETURN NUMBER
    IS
        v_status NUMBER;
    BEGIN
        SELECT a.athrztn_sta_cd
          INTO v_status
          FROM agnts a
         WHERE a.port_cd = p_port_cd
           AND a.athrztn_seq_nbr = p_athrztn_seq_nbr;
        RETURN v_status;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END stored_status;

    -- WHEN-NEW-RECORD-INSTANCE: Used := DCLTN.Impr_Impr_Auth_Used(:PORT_CD, :ATHRZTN_SEQ_NBR)
    -- DCLTN is a DB package (MISSING SOURCE), called unchanged through its synonym.
    FUNCTION authorization_used (p_port_cd         IN NUMBER,
                                 p_athrztn_seq_nbr IN NUMBER) RETURN BOOLEAN
    IS
    BEGIN
        RETURN dcltn.impr_impr_auth_used(p_port_cd, p_athrztn_seq_nbr) = c_used;
    END authorization_used;

    -- =========================================================================
    -- f345 HELPERS
    -- =========================================================================
    PROCEDURE P0_PAGE_PK_CHECK (P_PAGE_PK      IN OUT VARCHAR2,
                                P_CURR_PORT_CD IN     NUMBER)
    IS
        v_cnt NUMBER;
    BEGIN
        IF P_PAGE_PK IS NULL THEN
            RETURN;
        END IF;
        P_PAGE_PK := FORMS_APX.ROWID_FROM_URL(P_PAGE_PK);   -- URL-safe ROWID of page 121001 -> ROWID
        SELECT COUNT(*)
          INTO v_cnt
          FROM agnts a
         WHERE a.ROWID = CHARTOROWID(P0_PAGE_PK_CHECK.P_PAGE_PK)
           AND a.port_cd = P0_PAGE_PK_CHECK.P_CURR_PORT_CD;      -- block WHERE clause
        IF v_cnt = 0 THEN
            P_PAGE_PK := NULL;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN               -- ORA-01410 invalid ROWID ...: not a key of this page
            P_PAGE_PK := NULL;
    END P0_PAGE_PK_CHECK;

    -- =========================================================================
    -- BLOCK AGNTS
    -- =========================================================================

    -- ------------------------------------------------------------------ query
    -- Source: AGNTS.PRE-QUERY + AGNTS.IMPR_NBR.WHEN-NEW-ITEM-INSTANCE
    -- Original Forms code (active part):
    --   IF (:global.Exec_Query_Now = 1) THEN
    --      IF (:global.Port_CD IS NOT NULL ) THEN :PORT_CD := :global.Port_CD; END IF;
    --      IF (:global.ATHRZTN_SEQ_NBR IS NOT NULL ) THEN :ATHRZTN_SEQ_NBR := :global.ATHRZTN_SEQ_NBR; END IF;
    --      IF (:global.IMPR_NBR_AGENT_ID IS NOT NULL ) THEN :IMPR_NBR_AG :=:GLOBAL.IMPR_NBR_AGENT_ID; END IF;
    --      :global.Exec_Query_Now := 0; :global.ATHRZTN_SEQ_NBR := NULL; :global.port_cd := NULL;
    --      :GLOBAL.IMPR_NBR_AGENT_ID :=NULL;
    --   END IF;
    --   -- IMPR_NBR.WHEN-NEW-ITEM-INSTANCE: IF :global.Exec_Query_Now = 1 THEN Clear_Block(No_Validate); execute_query;
    -- Only ATHRZTN_SEQ_NBR.WHEN-VALIDATE-ITEM sets Exec_Query_Now (with PORT_CD and ATHRZTN_SEQ_NBR); nothing in this
    -- form sets :GLOBAL.IMPR_NBR_AGENT_ID, so the query key is (PORT_CD, ATHRZTN_SEQ_NBR) within the block WHERE clause.
    FUNCTION PRE_QUERY (P_PORT_CD         IN NUMBER,
                        P_ATHRZTN_SEQ_NBR IN NUMBER) RETURN VARCHAR2
    IS
        v_rowid VARCHAR2(18);
    BEGIN
        SELECT ROWIDTOCHAR(a.ROWID)
          INTO v_rowid
          FROM agnts a
         WHERE a.port_cd = PRE_QUERY.P_PORT_CD
           AND a.athrztn_seq_nbr = PRE_QUERY.P_ATHRZTN_SEQ_NBR;
        RETURN v_rowid;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END PRE_QUERY;

    -- Source: AGNTS.POST-QUERY
    -- Original Forms code (active part, CGFK$QRY_LOOKUP_DATA):
    --   IF PORT_CD IS NOT NULL THEN CGFK$QRY_AGNTS_AG_SDP_FK(:SDP_PORT_STATUS, :PORT_NAME, :PORT_CD);
    --      EXCEPTION WHEN NO_DATA_FOUND THEN PUSH('رمز الجمرك غير صحيح - أعد إدخال رمز الجمرك', 'E') ...
    --   IF PORT_CD IS NOT NULL OR IMPR_NBR IS NOT NULL THEN
    --      CGFK$QRY_AGNTS_AG_IMP_FK(:IMPR_NAME, :IMPR_EXPR_TYPE, :PORT_CD, :IMPR_NBR);
    --      EXCEPTION WHEN NO_DATA_FOUND THEN PUSH('بيانات المستورد غير صحيحة - أعد إدخال البيانات', 'E') ...
    --   ELSE PUSH(MSGGETTEXT(78, '<p1> must be entered', 'رقم المستـــــــــــــورد')); RAISE_FAILURE;
    --   (same for IMPR_NBR_AG -> CGFK$QRY_AGNTS_AG_IMP_AGENT_ID, 'بيانات الشركة الوسيطة غير صحيحة ...')
    --   SET_RECORD_PROPERTY(..., QUERY_STATUS) after each look-up.
    -- The PUSH(.., 'E') messages do not stop the query (no RAISE_FAILURE): the names stay empty. The foreign keys
    -- AG_SDP_FK / AG_IMP_FK / AG_IMP_AGENT_ID_FK make the rows exist, so the messages are not kept.
    -- SUGGESTION: show a page message when a look-up finds nothing (data repaired outside the form).
    -- SDP_PORT_STATUS (not displayed, never read) is not kept. The ELSE branches need a row without PORT_CD:
    -- not possible for a table row (block WHERE clause on PORT_CD).
    PROCEDURE POST_QUERY (P_PORT_CD           IN     NUMBER,
                          P_IMPR_NBR          IN     NUMBER,
                          P_IMPR_NBR_AG       IN     NUMBER,
                          P_PORT_NAME         IN OUT VARCHAR2,
                          P_IMPR_NAME         IN OUT VARCHAR2,
                          P_IMPR_EXPR_TYPE    IN OUT NUMBER,
                          P_IMPR_NAME_AG      IN OUT VARCHAR2,
                          P_IMPR_EXPR_TYPE_AG IN OUT NUMBER)
    IS
    BEGIN
        BEGIN
            SELECT p.port_name
              INTO POST_QUERY.P_PORT_NAME
              FROM sd_ports p
             WHERE p.port_cd = POST_QUERY.P_PORT_CD;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                P_PORT_NAME := NULL;
        END;
        IF NOT importer_row(P_PORT_CD, P_IMPR_NBR, P_IMPR_NAME, P_IMPR_EXPR_TYPE) THEN
            P_IMPR_NAME := NULL;
            P_IMPR_EXPR_TYPE := NULL;
        END IF;
        IF NOT importer_row(P_PORT_CD, P_IMPR_NBR_AG, P_IMPR_NAME_AG, P_IMPR_EXPR_TYPE_AG) THEN
            P_IMPR_NAME_AG := NULL;
            P_IMPR_EXPR_TYPE_AG := NULL;
        END IF;
    END POST_QUERY;

    -- ------------------------------------------------------------------ record
    -- Source: AGNTS.WHEN-CREATE-RECORD
    -- Original Forms code:
    --   :PORT_CD := :PARAMETER.P_CURR_PORT_CD;
    --   SELECT PORT_NAME INTO :PORT_NAME FROM SD_PORTS WHERE PORT_CD = :PORT_CD;
    -- The SELECT has no handler in Forms: an unknown port raises the Oracle error (kept).
    PROCEDURE WHEN_CREATE_RECORD (P_CURR_PORT_CD IN     NUMBER,
                                  P_PORT_CD      IN OUT NUMBER,
                                  P_PORT_NAME    IN OUT VARCHAR2)
    IS
    BEGIN
        P_PORT_CD := P_CURR_PORT_CD;
        SELECT p.port_name
          INTO WHEN_CREATE_RECORD.P_PORT_NAME
          FROM sd_ports p
         WHERE p.port_cd = WHEN_CREATE_RECORD.P_PORT_CD;
    END WHEN_CREATE_RECORD;

    -- Source: AGNTS.WHEN-NEW-RECORD-INSTANCE
    -- Original Forms code:
    --   IF (:ATHRZTN_SEQ_NBR IS NOT NULL) THEN
    --      Used := DCLTN.Impr_Impr_Auth_Used(:PORT_CD, :ATHRZTN_SEQ_NBR);
    --      IF (Used = 1) THEN
    --         INTRFACE.Make_Block_Full_Operation( 'AGNTS', TRUE, FALSE, FALSE );
    --         :AGNTS.UPDATE_STATUS:=STR_DB.GetArbMsg(8, 30);
    --      ELSIF (:ATHRZTN_STA_CD = 2 ) THEN
    --         INTRFACE.Make_Block_Full_Operation( 'AGNTS', TRUE, FALSE, FALSE );
    --         :AGNTS.UPDATE_STATUS:=STR_DB.GetArbMsg(8, 80);
    --      ELSE
    --         INTRFACE.Make_Block_Full_Operation( 'AGNTS', TRUE, TRUE, FALSE );
    --         :AGNTS.UPDATE_STATUS:=' يمكن التعديل';
    --      END IF;
    --   ELSE
    --      INTRFACE.Make_Block_Full_Operation( 'AGNTS', TRUE, TRUE, TRUE );
    --      :AGNTS.UPDATE_STATUS:=' يمكن التعديل';
    --   END IF;
    -- STR_DB.GetArbMsg returns the bare text (no '<sys>-<nbr> :' prefix, unlike STR.DispArbMsg), so it is called
    -- directly here. The block properties are AGNTS_IS_READ_ONLY (item rule) and PRE_DELETE.
    PROCEDURE WHEN_NEW_RECORD_INSTANCE (P_PORT_CD         IN     NUMBER,
                                        P_ATHRZTN_SEQ_NBR IN     NUMBER,
                                        P_UPDATE_STATUS   IN OUT VARCHAR2)
    IS
    BEGIN
        IF P_ATHRZTN_SEQ_NBR IS NULL THEN
            P_UPDATE_STATUS := c_msg_can_update;
        ELSIF authorization_used(P_PORT_CD, P_ATHRZTN_SEQ_NBR) THEN
            P_UPDATE_STATUS := str_db.getarbmsg(8, 30);
        ELSIF stored_status(P_PORT_CD, P_ATHRZTN_SEQ_NBR) = c_status_cancelled THEN
            P_UPDATE_STATUS := str_db.getarbmsg(8, 80);
        ELSE
            P_UPDATE_STATUS := c_msg_can_update;
        END IF;
    END WHEN_NEW_RECORD_INSTANCE;

    -- Source: AGNTS.WHEN-NEW-RECORD-INSTANCE (MAKE_BLOCK_FULL_OPERATION update argument)
    -- APEX-DA: [Source: AGNTS.WHEN-NEW-RECORD-INSTANCE] -> Read Only condition of P1210_ALLOW_EXPORT, P1210_IMPR_NBR,
    --          P1210_IMPR_NBR_AG, P1210_ATHRZTN_NOTE, P1210_ATHRZTN_STA_CD (spec §4)
    -- Original: INTRFACE.Make_Block_Full_Operation('AGNTS', TRUE, FALSE, FALSE) when used or status 2
    FUNCTION AGNTS_IS_READ_ONLY (P_PORT_CD         IN NUMBER,
                                 P_ATHRZTN_SEQ_NBR IN NUMBER) RETURN BOOLEAN
    IS
    BEGIN
        IF P_ATHRZTN_SEQ_NBR IS NULL THEN
            RETURN FALSE;                                       -- new record: TRUE, TRUE, TRUE
        END IF;
        RETURN authorization_used(P_PORT_CD, P_ATHRZTN_SEQ_NBR)
            OR NVL(stored_status(P_PORT_CD, P_ATHRZTN_SEQ_NBR), c_status_valid) = c_status_cancelled;
    END AGNTS_IS_READ_ONLY;

    -- ------------------------------------------------------------------ items
    -- Source: AGNTS.ATHRZTN_SEQ_NBR.WHEN-VALIDATE-ITEM
    -- Original Forms code:
    --   IF (:ATHRZTN_SEQ_NBR IS NOT NULL) THEN
    --      SELECT COUNT(*) INTO Rec_Count FROM AGNTS WHERE Port_Cd = :port_cd AND ATHRZTN_SEQ_NBR = :ATHRZTN_SEQ_NBR;
    --      IF Rec_Count <> 0 THEN
    --         :global.Port_CD := :PORT_CD; :global.ATHRZTN_SEQ_NBR := :ATHRZTN_SEQ_NBR; :global.Exec_Query_Now := 1;
    --      ELSE rec_count := STR.DispArbMsg(9, 40, 'INFORMATION'); RAISE FORm_Trigger_FAilure;
    --      END IF;
    --   END IF;
    -- APEX-DA: the globals + Exec_Query_Now = Submit Page EXECUTE_QUERY after the check (process EXECUTE-QUERY).
    FUNCTION ATHRZTN_SEQ_NBR_VALIDATION (P_PORT_CD         IN NUMBER,
                                         P_ATHRZTN_SEQ_NBR IN NUMBER) RETURN VARCHAR2
    IS
        v_count NUMBER;
    BEGIN
        IF P_ATHRZTN_SEQ_NBR IS NULL THEN
            RETURN NULL;
        END IF;
        SELECT COUNT(*)
          INTO v_count
          FROM agnts a
         WHERE a.port_cd = ATHRZTN_SEQ_NBR_VALIDATION.P_PORT_CD
           AND a.athrztn_seq_nbr = ATHRZTN_SEQ_NBR_VALIDATION.P_ATHRZTN_SEQ_NBR;
        IF v_count = 0 THEN
            RETURN FORMS_APX.ARABIC_MESSAGE(9, 40);
        END IF;
        RETURN NULL;
    END ATHRZTN_SEQ_NBR_VALIDATION;

    -- Source: AGNTS.IMPR_NBR.WHEN-VALIDATE-ITEM (first block)
    -- Original Forms code:
    --   CURSOR C_P_NAME IS SELECT ARBC_IMPR_NAME FROM IMPORTERS
    --                       WHERE IMPORTERS.IMPR_NBR = :AGNTS.IMPR_NBR AND IMPORTERS.PORT_CD = :AGNTS.PORT_CD;
    --   IF :System.TRIGGER_ITEM = :System.CURSOR_ITEM THEN
    --      OPEN C_P_NAME; FETCH C_P_NAME INTO :IMPR_NAME;
    --      IF C_P_NAME%NOTFOUND THEN ret := Str.DispArbMsg(9, 20,'ERROR'); RAISE FORm_Trigger_failure; END IF;
    --      CLOSE C_P_NAME;
    --   END IF;
    --   Check_Suspension(:PORT_CD, :IMPR_NBR);
    --   IF :IMPR_NBR_AG IS NOT NULL AND :IMPR_NBR = :IMPR_NBR_AG THEN
    --      ret := STR.DispArbMsg(9, 10,'ERROR'); RAISE Form_trigger_failure;
    --   END IF;
    -- The name check runs in Forms only when the user leaves the item (TRIGGER_ITEM = CURSOR_ITEM); here it runs
    -- on every check (inventory §14 #9).
    FUNCTION IMPR_NBR_VALIDATION (P_PORT_CD     IN NUMBER,
                                  P_IMPR_NBR    IN NUMBER,
                                  P_IMPR_NBR_AG IN NUMBER) RETURN VARCHAR2
    IS
    BEGIN
        RETURN importer_error(P_PORT_CD, P_IMPR_NBR, P_IMPR_NBR_AG);
    END IMPR_NBR_VALIDATION;

    -- Source: AGNTS.IMPR_NBR.WHEN-VALIDATE-ITEM (derived values) + CGFK$VALDIDATE_FK_OVF -> CGFK$CHK_AGNTS_AG_IMP_FK
    -- Original Forms code (CGFK part):
    --   IF PORT_CD IS NOT NULL AND IMPR_NBR IS NOT NULL THEN
    --      CGFK$CHK_AGNTS_AG_IMP_FK(:IMPR_NAME, :IMPR_EXPR_TYPE, :PORT_CD, :IMPR_NBR);
    --      EXCEPTION WHEN NO_DATA_FOUND THEN PUSH('بيانات المستورد غير صحيحة - أعد إدخال البيانات', 'W') ...
    -- The second block (CALL_FORM LOV_AGNT_ATHR_IMPR when the importer already has authorizations) is UI:
    -- APEX-DA: region LOV_AGNT_ATHR_IMPR refreshed by this DA (spec §3, §10).
    PROCEDURE IMPR_NBR_WHEN_VALIDATE_ITEM (P_PORT_CD        IN     NUMBER,
                                           P_IMPR_NBR       IN     NUMBER,
                                           P_IMPR_NBR_AG    IN     NUMBER,
                                           P_IMPR_NAME      IN OUT VARCHAR2,
                                           P_IMPR_EXPR_TYPE IN OUT NUMBER)
    IS
    BEGIN
        FORMS_APX.CHECK_ERROR(IMPR_NBR_VALIDATION(P_PORT_CD, P_IMPR_NBR, P_IMPR_NBR_AG));
        IF NOT importer_row(P_PORT_CD, P_IMPR_NBR, P_IMPR_NAME, P_IMPR_EXPR_TYPE) THEN
            P_IMPR_NAME := NULL;
            P_IMPR_EXPR_TYPE := NULL;
        END IF;
    END IMPR_NBR_WHEN_VALIDATE_ITEM;

    -- Source: AGNTS.IMPR_NBR_AG.WHEN-VALIDATE-ITEM (first block)
    -- Original Forms code:
    --   CURSOR C_P_NAME IS SELECT ARBC_IMPR_NAME FROM IMPORTERS
    --                       WHERE IMPORTERS.IMPR_NBR = :AGNTS.IMPR_NBR_AG AND IMPORTERS.PORT_CD = :AGNTS.PORT_CD;
    --   IF :System.TRIGGER_ITEM = :System.CURSOR_ITEM THEN ... FETCH C_P_NAME INTO :IMPR_NAME_AG;
    --      IF C_P_NAME%NOTFOUND THEN ret := Str.DispArbMsg(9, 20,'ERROR'); RAISE FORm_Trigger_failure; END IF; ...
    --   Check_Suspension(:PORT_CD, :IMPR_NBR_AG);
    --   IF :IMPR_NBR_AG = :IMPR_NBR THEN ret := STR.DispArbMsg(9, 10 ,'INFORMATION'); RAISE Form_trigger_failure; END IF;
    FUNCTION IMPR_NBR_AG_VALIDATION (P_PORT_CD     IN NUMBER,
                                     P_IMPR_NBR    IN NUMBER,
                                     P_IMPR_NBR_AG IN NUMBER) RETURN VARCHAR2
    IS
    BEGIN
        RETURN importer_error(P_PORT_CD, P_IMPR_NBR_AG, P_IMPR_NBR);
    END IMPR_NBR_AG_VALIDATION;

    -- Source: AGNTS.IMPR_NBR_AG.WHEN-VALIDATE-ITEM (derived values) + CGFK$CHK_AGNTS_AG_IMP_AGENT_ID
    --   (NO_DATA_FOUND -> PUSH('بيانات الشركة الوسيطة غير صحيحة - أعد إدخال البيانات', 'W'))
    -- APEX-DA: IMPR_NBR_AG.WHEN-NEW-ITEM-INSTANCE (GO_ITEM IMPR_NBR when :GLOBAL.EXEC_QUERY = 1) has no effect after
    --          the LOV form (inventory §14 #4): not kept.
    PROCEDURE IMPR_NBR_AG_WHEN_VALIDATE_ITEM (P_PORT_CD           IN     NUMBER,
                                              P_IMPR_NBR          IN     NUMBER,
                                              P_IMPR_NBR_AG       IN     NUMBER,
                                              P_IMPR_NAME_AG      IN OUT VARCHAR2,
                                              P_IMPR_EXPR_TYPE_AG IN OUT NUMBER)
    IS
    BEGIN
        FORMS_APX.CHECK_ERROR(IMPR_NBR_AG_VALIDATION(P_PORT_CD, P_IMPR_NBR, P_IMPR_NBR_AG));
        IF NOT importer_row(P_PORT_CD, P_IMPR_NBR_AG, P_IMPR_NAME_AG, P_IMPR_EXPR_TYPE_AG) THEN
            P_IMPR_NAME_AG := NULL;
            P_IMPR_EXPR_TYPE_AG := NULL;
        END IF;
    END IMPR_NBR_AG_WHEN_VALIDATE_ITEM;

    -- ------------------------------------------------------------------ DML
    -- Source: AGNTS.PRE-INSERT
    -- Original Forms code:
    --   IF (:AGNTS.ATHRZTN_SEQ_NBR)IS NULL THEN
    --      SELECT MAX(AGNTS.ATHRZTN_SEQ_NBR) + 1 INTO :AGNTS.ATHRZTN_SEQ_NBR FROM AGNTS
    --       WHERE PORT_CD = :PARAMETER.P_CURR_PORT_CD -- NALSALEH CENTRALIZED PROJECT
    --      ;
    --      IF :AGNTS.ATHRZTN_SEQ_NBR IS NULL THEN :AGNTS.ATHRZTN_SEQ_NBR := 1; END IF;
    --   END IF;
    --   :AGNTS.ATHRZTN_STA_CD := 1;
    --   :AGNTS.ATHRZTN_CRET_DT := HIJDATE.Cur_Hij_Date;
    --   IF NOT ACTIVITY.ADD_ACTIVITY(9, 1, 1, :PORT_CD||'!'||:ATHRZTN_SEQ_NBR) THEN RAISE FORm_Trigger_Failure; END IF;
    -- SUGGESTION: MAX + 1 is not safe for two clerks saving at once (inventory §14 #2): the second save fails on AG_PK.
    PROCEDURE PRE_INSERT (P_PORT_CD          IN     NUMBER,
                          P_CURR_PORT_CD     IN     NUMBER,
                          SSO_APP_USER       IN     VARCHAR2,
                          P_GLOBAL_V_WS_ID   IN     VARCHAR2,
                          P_ATHRZTN_SEQ_NBR  IN OUT NUMBER,
                          P_ATHRZTN_STA_CD   IN OUT NUMBER,
                          P_ATHRZTN_CRET_DT  IN OUT VARCHAR2)
    IS
    BEGIN
        IF P_ATHRZTN_SEQ_NBR IS NULL THEN
            SELECT MAX(a.athrztn_seq_nbr) + 1
              INTO PRE_INSERT.P_ATHRZTN_SEQ_NBR
              FROM agnts a
             WHERE a.port_cd = PRE_INSERT.P_CURR_PORT_CD;      -- NALSALEH CENTRALIZED PROJECT
            IF P_ATHRZTN_SEQ_NBR IS NULL THEN
                P_ATHRZTN_SEQ_NBR := 1;
            END IF;
        END IF;
        P_ATHRZTN_STA_CD := c_status_valid;
        P_ATHRZTN_CRET_DT := FORMS_APX.HIJRI_TEXT(FORMS_APX.CUR_HIJ_DATE);
        add_activity(c_activity_insert, P_PORT_CD, P_ATHRZTN_SEQ_NBR, P_CURR_PORT_CD, SSO_APP_USER, P_GLOBAL_V_WS_ID);
    END PRE_INSERT;

    -- Source: AGNTS.PRE-UPDATE
    -- Original Forms code:
    --   IF :PARAMETER.P_FUNCTION_CD <> 1 THEN
    --      IF NOT ACTIVITY.ADD_ACTIVITY(9, 1, 2, :PORT_CD||'!'||:ATHRZTN_SEQ_NBR) THEN RAISE FORm_Trigger_Failure; END IF;
    --   END IF;
    -- P_FUNCTION_CD is 1 only while EXEC_FUNS runs; the APEX functions write in EXEC_FUNS and never reach SAVE, so
    -- the condition is always true here. The first check is the update rule of WHEN-NEW-RECORD-INSTANCE
    -- (block Update Allowed = false) done on the server, with the UPDATE_STATUS text as the message.
    PROCEDURE PRE_UPDATE (P_PORT_CD         IN NUMBER,
                          P_ATHRZTN_SEQ_NBR IN NUMBER,
                          P_CURR_PORT_CD    IN NUMBER,
                          SSO_APP_USER      IN VARCHAR2,
                          P_GLOBAL_V_WS_ID  IN VARCHAR2)
    IS
        v_text VARCHAR2(4000);
    BEGIN
        IF AGNTS_IS_READ_ONLY(P_PORT_CD, P_ATHRZTN_SEQ_NBR) THEN
            WHEN_NEW_RECORD_INSTANCE(P_PORT_CD, P_ATHRZTN_SEQ_NBR, v_text);
            FORMS_APX.FORM_TRIGGER_FAILURE(v_text);
        END IF;
        add_activity(c_activity_update, P_PORT_CD, P_ATHRZTN_SEQ_NBR, P_CURR_PORT_CD, SSO_APP_USER, P_GLOBAL_V_WS_ID);
    END PRE_UPDATE;

    -- Source: FORM.KEY-DELREC (NIB.KEY_DELREC) + AGNTS.WHEN-NEW-RECORD-INSTANCE (Deletable FALSE on every queried record)
    PROCEDURE PRE_DELETE
    IS
    BEGIN
        FORMS_APX.FORM_TRIGGER_FAILURE(c_msg_delete_not_allowed);
    END PRE_DELETE;

    -- =========================================================================
    -- FUNCTIONS
    -- =========================================================================
    -- Source: PU EXEC_FUNS
    -- Original Forms code:
    --   IF CD LIKE 'CD1_STOPIMPRAUTH' THEN
    --      HDate := HIJDATE.Cur_Hij_Date;
    --      IF :ATHRZTN_SEQ_NBR IS NOT NULL AND :ATHRZTN_STA_CD = 1 THEN
    --         RET := STR.DispArbMsg(9, 50,'CONFIRM');
    --         IF Ret = alert_button1 THEN
    --            :PARAMETER.P_FUNCTION_CD := 1; :ATHRZTN_STA_CD := 2; :ATHRZTN_CNCLD_DT := HDate;
    --            IF NOT ACTIVITY.ADD_ACTIVITY(9, 1, 3, :PORT_CD||'!'||:ATHRZTN_SEQ_NBR) THEN RAISE FORm_Trigger_Failure; END IF;
    --            COMMIT;
    --         END IF;
    --      END IF;
    --      :PARAMETER.P_FUNCTION_CD := 0;
    --   ELSIF CD LIKE 'CD2_REUSEIMPRAUTH' THEN
    --      IF :ATHRZTN_SEQ_NBR IS NOT NULL AND :ATHRZTN_STA_CD = 2 THEN
    --         RET := STR.DispALERT('سيتم إسترجاع التفويض - هل ترغب في إستكمال الإسترجاع','CONFIRM');
    --         IF Ret = alert_button1 THEN
    --            :PARAMETER.P_FUNCTION_CD := 1; INTRFACE.Make_Block_Full_Operation( 'AGNTS', TRUE, TRUE, FALSE );
    --            :ATHRZTN_STA_CD := 1; :ATHRZTN_CNCLD_DT := NULL;
    --            IF NOT ACTIVITY.ADD_ACTIVITY(9, 1, 4, :PORT_CD||'!'||:ATHRZTN_SEQ_NBR) THEN RAISE FORm_Trigger_Failure; END IF;
    --            COMMIT;
    --         END IF;
    --      END IF;
    --      :PARAMETER.P_FUNCTION_CD := 0;
    --   END IF;
    -- APEX-DA: the confirmations are DA Confirm actions before the submit (spec §10). The item values become one
    -- UPDATE of the row (the Forms COMMIT posts the changed record); the status is read from the table. Cancel is
    -- allowed on a used authorization too (module description: "At all cases ... the user can soft delete").
    -- Forms shows no message after the COMMIT, so the APEX processes have no success message.
    PROCEDURE EXEC_FUNS (P_FUNCTION_CODE   IN VARCHAR2,
                         P_PORT_CD         IN NUMBER,
                         P_ATHRZTN_SEQ_NBR IN NUMBER,
                         P_CURR_PORT_CD    IN NUMBER,
                         SSO_APP_USER      IN VARCHAR2,
                         P_GLOBAL_V_WS_ID  IN VARCHAR2)
    IS
        v_status NUMBER;
    BEGIN
        IF P_ATHRZTN_SEQ_NBR IS NULL THEN
            RETURN;
        END IF;
        v_status := stored_status(P_PORT_CD, P_ATHRZTN_SEQ_NBR);
        IF P_FUNCTION_CODE = c_stop_authorization AND v_status = c_status_valid THEN
            UPDATE agnts a
               SET a.athrztn_sta_cd   = c_status_cancelled,
                   a.athrztn_cncld_dt = FORMS_APX.CUR_HIJ_DATE
             WHERE a.port_cd = EXEC_FUNS.P_PORT_CD
               AND a.athrztn_seq_nbr = EXEC_FUNS.P_ATHRZTN_SEQ_NBR;
            add_activity(c_activity_stop, P_PORT_CD, P_ATHRZTN_SEQ_NBR, P_CURR_PORT_CD, SSO_APP_USER, P_GLOBAL_V_WS_ID);
            COMMIT;                                            -- Forms: COMMIT;
        ELSIF P_FUNCTION_CODE = c_reuse_authorization AND v_status = c_status_cancelled THEN
            UPDATE agnts a
               SET a.athrztn_sta_cd   = c_status_valid,
                   a.athrztn_cncld_dt = NULL
             WHERE a.port_cd = EXEC_FUNS.P_PORT_CD
               AND a.athrztn_seq_nbr = EXEC_FUNS.P_ATHRZTN_SEQ_NBR;
            add_activity(c_activity_reuse, P_PORT_CD, P_ATHRZTN_SEQ_NBR, P_CURR_PORT_CD, SSO_APP_USER, P_GLOBAL_V_WS_ID);
            COMMIT;                                            -- Forms: COMMIT;
        END IF;
    END EXEC_FUNS;

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
    -- UI LOGIC FOR APEX DYNAMIC ACTIONS  (comments only, no executable code)
    -- =========================================================================
    -- APEX-DA: [Source: AGNTS.ATHRZTN_SEQ_NBR.WHEN-VALIDATE-ITEM + PRE-QUERY + IMPR_NBR.WHEN-NEW-ITEM-INSTANCE]
    --          -> DA "ATHRZTN_SEQ_NBR WHEN-VALIDATE-ITEM" (change, not null): FOS CHECK_ERROR(ATHRZTN_SEQ_NBR_VALIDATION),
    --             then Submit Page EXECUTE_QUERY -> process EXECUTE-QUERY (:P0_PAGE_PK := PRE_QUERY(...)) -> branch.
    -- APEX-DA: [Source: AGNTS.IMPR_NBR.WHEN-VALIDATE-ITEM] -> DA "IMPR_NBR WHEN-VALIDATE-ITEM": FOS
    --             IMPR_NBR_WHEN_VALIDATE_ITEM (returns IMPR_NAME, IMPR_EXPR_TYPE), then Refresh region
    --             LOV_AGNT_ATHR_IMPR (CALL_FORM LOV_AGNT_ATHR_IMPR when the importer has authorizations), then
    --             Set Focus IMPR_NBR_AG (KEY-LISTVAL GO_ITEM after the LOV).
    -- APEX-DA: [Source: AGNTS.IMPR_NBR_AG.WHEN-VALIDATE-ITEM] -> DA "IMPR_NBR_AG WHEN-VALIDATE-ITEM": FOS
    --             IMPR_NBR_AG_WHEN_VALIDATE_ITEM (returns IMPR_NAME_AG, IMPR_EXPR_TYPE_AG), Set Focus ATHRZTN_NOTE
    --             (KEY-LISTVAL GO_ITEM('ATHRZTN_NOTE')).
    -- APEX-DA: [Source: AGNTS.IMPR_NBR.KEY-LISTVAL / IMP_LOV, IMPR_NBR_AG.KEY-LISTVAL / AGNT_LOV]
    --             -> Popup LOV LOV_IMPR (LOV form LOV_IMPR, PORT_CD = P_CURR_PORT_CD) on both items; the buttons are the
    --             Popup LOV buttons.
    -- APEX-DA: [Source: AGNTS.WHEN-NEW-RECORD-INSTANCE MAKE_BLOCK_FULL_OPERATION] -> item Read Only conditions
    --             IMPR1210.AGNTS_IS_READ_ONLY(...) (no DA).
    -- APEX-DA: [Source: PU EXEC_FUNS confirmations] -> DAs "CD1_STOPIMPRAUTH EXECUTE-FUNCTION" /
    --             "CD2_REUSEIMPRAUTH EXECUTE-FUNCTION" on the page 0 FUNCS custom events: client condition (number shown,
    --             status 1 / 2), Confirm (&P1210_CONFIRM_STOP. = message 9-50 / the Forms literal), Submit Page <code>.
    -- APEX-DA: [Source: PU CGNV$AI_CGSO$WINDOW_1_IMP_NEW OPEN_FORM('IMP_NEW')] -> page button IMP_NEW (redirect).

END IMPR1210;
/
SHOW ERRORS
