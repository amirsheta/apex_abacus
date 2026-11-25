-- =============================================================================
-- Package body: IMPR1150 (version 001, 25-11-2026) - see the spec header. NOT COMPILED.
-- Layout      : 1 private constants, 2 private helpers, 3 APEX entry points (spec order), 4 version.
-- Forms code  : the original trigger text is quoted in analysis/IMPR1150/IMPR1150_inventory.md sections 6 / 9;
--               every member names its source. Forms UI calls are kept as "-- APEX-DA:" comments.
-- HQ table    : CUSTOMS.IMPORTERS_CENTRAL@HQPRD.HQ.CUSTOMS.GOV (static SQL over the database link, as Forms).
-- =============================================================================
SET DEFINE OFF

CREATE OR REPLACE PACKAGE BODY LIB_APX_USR.IMPR1150
AS

    -- =========================================================================
    -- 1 PRIVATE CONSTANTS
    -- =========================================================================
    c_hq_port_cd       CONSTANT NUMBER        := 99;   -- :GLOBAL.PORT_CD := 99 (WHEN-VALIDATE-ITEM, PRE-QUERY, EXEC_FUNS)
    c_pending          CONSTANT NUMBER        := 0;    -- PENDING_ACTIVE 0 = بانتظار التفعيل
    c_active           CONSTANT NUMBER        := 1;    -- PENDING_ACTIVE 1 = فعال
    c_rejected         CONSTANT NUMBER        := 2;    -- PENDING_ACTIVE 2 = مرفوض
    c_activate         CONSTANT VARCHAR2(30)  := 'IMPR1150_ACTIVATE';
    c_reject           CONSTANT VARCHAR2(30)  := 'IMPR1150_REJECT';
    c_msg_insert_not_allowed CONSTANT VARCHAR2(200) := 'لا يمكن إضافة بيانات من هذه الشاشة';   -- = IMPR1116 (to agree)
    c_msg_delete_not_allowed CONSTANT VARCHAR2(200) := 'لا يمكن حذف بيانات من هذه الشاشة';    -- = IMPR1116 (to agree)

    -- =========================================================================
    -- 2 PRIVATE HELPERS
    -- =========================================================================

    -- COUNT(*) of the pending HQ importers of the WHEN-VALIDATE-ITEM triggers (PORT_CD 99, PENDING_ACTIVE 0)
    FUNCTION pending_count (p_impr_nbr IN NUMBER, p_bus_id IN VARCHAR2) RETURN NUMBER
    IS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*)
          INTO v_count
          FROM CUSTOMS.IMPORTERS_CENTRAL@HQPRD.HQ.CUSTOMS.GOV ic
         WHERE ic.port_cd        = c_hq_port_cd
           AND (p_impr_nbr IS NULL OR ic.impr_nbr = p_impr_nbr)
           AND (p_bus_id   IS NULL OR ic.bus_id   = p_bus_id)
           AND ic.pending_active = c_pending;
        RETURN v_count;
    END pending_count;

    -- ACTIVITY.ADD_ACTIVITY(9, 9, p_act, :PORT_CD || '!' || :IMPR_NBR) of CIC_LIB.pld -> ACTIVITY_DB with the
    -- f345 items (as IMPR1130 add_activity, subject 9 here). Failure: RAISE FORM_TRIGGER_FAILURE with its text.
    PROCEDURE add_activity (p_act          IN NUMBER,
                            p_port_cd      IN NUMBER,
                            p_impr_nbr     IN NUMBER,
                            p_curr_port_cd IN NUMBER,
                            p_user_id      IN VARCHAR2,
                            p_ws_id        IN VARCHAR2)
    IS
        v_msg VARCHAR2(2000);
    BEGIN
        IF activity_db.add_activity(9, 9, p_act, p_port_cd || '!' || p_impr_nbr,
                                    p_curr_port_cd, p_user_id, p_ws_id, v_msg) = 0 THEN
            FORMS_APX.FORM_TRIGGER_FAILURE(v_msg);
        END IF;
    END add_activity;

    -- =========================================================================
    -- 3 APEX ENTRY POINTS
    -- =========================================================================

    -- ------------------------------------------------------------------ f345 HELPERS
    PROCEDURE P0_PAGE_PK_CHECK (P_PAGE_PK      IN OUT VARCHAR2,
                                P_CURR_PORT_CD IN     NUMBER)
    IS
        v_count NUMBER;
    BEGIN
        IF P_PAGE_PK IS NULL THEN
            RETURN;
        END IF;
        SELECT COUNT(*)
          INTO v_count
          FROM CUSTOMS.IMPORTERS_CENTRAL@HQPRD.HQ.CUSTOMS.GOV ic
         WHERE ic.port_cd  = c_hq_port_cd                            -- PRE-QUERY :IMPORTERS_CENTRAL.PORT_CD := 99
           AND ic.port_cd  = P0_PAGE_PK_CHECK.P_CURR_PORT_CD         -- block WHERE PORT_CD = :PARAMETER.P_CURR_PORT_CD
           AND ic.impr_nbr = TO_NUMBER(P0_PAGE_PK_CHECK.P_PAGE_PK);
        IF v_count = 0 THEN
            P_PAGE_PK := NULL;
        END IF;
    EXCEPTION
        WHEN VALUE_ERROR OR INVALID_NUMBER THEN   -- not a number: not a key of this page
            P_PAGE_PK := NULL;
    END P0_PAGE_PK_CHECK;

    -- Source: IMPORTERS_CENTRAL.PRE-QUERY
    --   IF (:global.Exec_Query_Now = 1) THEN
    --     IF (:global.IMPR_NBR IS NOT NULL) THEN :PORT_CD := :global.PORT_CD; :IMPR_NBR := :global.IMPR_NBR;
    --     ELSIF (:global.BUS_ID IS NOT NULL) THEN :PORT_CD := :global.PORT_CD; :BUS_ID := :global.BUS_ID;
    --     ELSIF :REJCT_RESON IS NOT NULL THEN ... (after EXEC_FUNS REJECT: :global.IMPR_NBR is set, so the
    --                                          first branch always runs; this branch is unreachable)
    -- + WHEN-NEW-ITEM-INSTANCE: Clear_Block(No_Validate); execute_query; go_block('IMPORTER_DOCS'); execute_query;
    -- The Forms query by BUS_ID can return several HQ records (scrolled with KEY-DOWN / KEY-UP); APEX shows one
    -- record per page: the pending one of that BUS_ID (the one WHEN-VALIDATE-ITEM found), else the first by
    -- IMPR_NBR. The others are reached through the search page 115001 (spec section 0 #4).
    FUNCTION IMPORTER_KEY (P_IMPR_NBR     IN NUMBER,
                           P_BUS_ID       IN VARCHAR2,
                           P_CURR_PORT_CD IN NUMBER) RETURN VARCHAR2
    IS
        v_impr_nbr NUMBER;
    BEGIN
        IF P_IMPR_NBR IS NULL AND P_BUS_ID IS NULL THEN
            RETURN NULL;
        END IF;
        SELECT MIN(ic.impr_nbr) KEEP (DENSE_RANK FIRST
                   ORDER BY CASE WHEN ic.pending_active = c_pending THEN 0 ELSE 1 END, ic.impr_nbr)
          INTO v_impr_nbr
          FROM CUSTOMS.IMPORTERS_CENTRAL@HQPRD.HQ.CUSTOMS.GOV ic
         WHERE ic.port_cd = c_hq_port_cd
           AND ic.port_cd = IMPORTER_KEY.P_CURR_PORT_CD
           AND (   (IMPORTER_KEY.P_IMPR_NBR IS NOT NULL AND ic.impr_nbr = IMPORTER_KEY.P_IMPR_NBR)
                OR (IMPORTER_KEY.P_IMPR_NBR IS NULL     AND ic.bus_id   = IMPORTER_KEY.P_BUS_ID));
        RETURN TO_CHAR(v_impr_nbr);
    END IMPORTER_KEY;

    -- ------------------------------------------------------------------ BLOCK IMPORTERS_CENTRAL
    -- Source: IMPORTERS_CENTRAL.POST-QUERY. The Forms END IF of CTRY_CD closes after the CITY_CODE look-up, so
    -- ADD_CRTY_ARBC_NAME and CITY_NAME are only filled when CTRY_CD is not null - kept as in Forms.
    -- SUGGESTION: close the CTRY_CD IF before the ADD_CTRY_CD look-up (probably the intended nesting).
    PROCEDURE POST_QUERY (P_IMPR_TYPE_CD       IN  NUMBER,
                          P_IMPR_TYPE_NAME     OUT VARCHAR2,
                          P_BUS_ID_TYPE_CD     IN  NUMBER,
                          P_BUS_ID_TYPE_NAME   OUT VARCHAR2,
                          P_CTRY_CD            IN  NUMBER,
                          P_CRTY_ARBC_NAME     OUT VARCHAR2,
                          P_ADD_CTRY_CD        IN  NUMBER,
                          P_ADD_CRTY_ARBC_NAME OUT VARCHAR2,
                          P_CITY_CODE          IN  NUMBER,
                          P_CITY_NAME          OUT VARCHAR2)
    IS
    BEGIN
        IF P_IMPR_TYPE_CD IS NOT NULL THEN
            BEGIN
                SELECT it.impr_type_name
                  INTO POST_QUERY.P_IMPR_TYPE_NAME
                  FROM impr_types it
                 WHERE it.impr_type_cd = POST_QUERY.P_IMPR_TYPE_CD;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN NULL;
            END;
        END IF;
        IF P_BUS_ID_TYPE_CD IS NOT NULL THEN
            BEGIN
                SELECT bt.bus_id_type_name
                  INTO POST_QUERY.P_BUS_ID_TYPE_NAME
                  FROM bus_id_types bt
                 WHERE bt.bus_id_type_cd = POST_QUERY.P_BUS_ID_TYPE_CD;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN NULL;
            END;
        END IF;
        IF P_CTRY_CD IS NOT NULL THEN
            BEGIN
                SELECT ctry.crty_arbc_name
                  INTO POST_QUERY.P_CRTY_ARBC_NAME
                  FROM countries ctry
                 WHERE ctry.ctry_cd     = POST_QUERY.P_CTRY_CD
                   AND ctry.ctry_status = 1;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN NULL;
            END;
            IF P_ADD_CTRY_CD IS NOT NULL THEN
                BEGIN
                    SELECT c.crty_arbc_name
                      INTO POST_QUERY.P_ADD_CRTY_ARBC_NAME
                      FROM countries c
                     WHERE c.ctry_cd = POST_QUERY.P_ADD_CTRY_CD;
                EXCEPTION
                    WHEN NO_DATA_FOUND THEN NULL;
                END;
            END IF;
            IF P_CITY_CODE IS NOT NULL THEN
                BEGIN
                    SELECT ci.city_arb_name
                      INTO POST_QUERY.P_CITY_NAME
                      FROM cities ci
                     WHERE ci.ctry_cd = POST_QUERY.P_ADD_CTRY_CD
                       AND ci.city_cd = POST_QUERY.P_CITY_CODE;
                EXCEPTION
                    WHEN NO_DATA_FOUND THEN NULL;
                END;
            END IF;
        END IF;
    END POST_QUERY;

    -- Source: IMPORTERS_CENTRAL.IMPR_NBR.WHEN-VALIDATE-ITEM
    --   part 1: COUNT(*) FROM CUSTOMS.IMPORTERS_CENTRAL@HQPRD... WHERE PORT_CD = 99 AND IMPR_NBR = :IMPR_NBR
    --           AND PENDING_ACTIVE = 0; <> 0 -> :global.PORT_CD := 99; :global.IMPR_NBR := ...;
    --           :global.Exec_Query_Now := 1 (APEX-DA: Submit Page EXECUTE_QUERY); else DispArbMsg(9, 150) + RAISE
    --   part 2: CGUV$CHK_IMP_CNTRL_PK(:PORT_CD, :IMPR_NBR) on the local IMPORTERS_CENTRAL: found ->
    --           'هذا السجل مدخل سابقاً - أعد ادخال البيانات'; both items null -> MSGGETTEXT(78) (unreachable: part 1
    --           runs only for a not null IMPR_NBR, and IMPR_NBR not null makes the first condition true).
    --           :PORT_CD is null in the new record of the form (no default, Insert Allowed = false), so the
    --           check finds nothing there; kept for the same behaviour.
    FUNCTION IMPR_NBR_VALIDATION (P_PORT_CD  IN NUMBER,
                                  P_IMPR_NBR IN NUMBER) RETURN VARCHAR2
    IS
        v_found NUMBER;
    BEGIN
        IF P_IMPR_NBR IS NULL THEN
            RETURN NULL;
        END IF;
        IF pending_count(P_IMPR_NBR, NULL) = 0 THEN
            RETURN FORMS_APX.ARABIC_MESSAGE(9, 150);                  -- STR.DispArbMsg(9, 150) + RAISE
        END IF;
        SELECT COUNT(*)                                                -- CGUV$CHK_IMP_CNTRL_PK
          INTO v_found
          FROM importers_central ic
         WHERE ic.impr_nbr = IMPR_NBR_VALIDATION.P_IMPR_NBR
           AND ic.port_cd  = IMPR_NBR_VALIDATION.P_PORT_CD;
        IF v_found > 0 THEN
            RETURN 'هذا السجل مدخل سابقاً - أعد ادخال البيانات';
        END IF;
        RETURN NULL;
    END IMPR_NBR_VALIDATION;

    -- Source: IMPORTERS_CENTRAL.BUS_ID.WHEN-VALIDATE-ITEM (as IMPR_NBR part 1, on BUS_ID)
    FUNCTION BUS_ID_VALIDATION (P_BUS_ID IN VARCHAR2) RETURN VARCHAR2
    IS
    BEGIN
        IF P_BUS_ID IS NULL THEN
            RETURN NULL;
        END IF;
        IF pending_count(NULL, P_BUS_ID) = 0 THEN
            RETURN FORMS_APX.ARABIC_MESSAGE(9, 150);                  -- STR.DispArbMsg(9, 150) + RAISE
        END IF;
        RETURN NULL;                                                   -- APEX-DA: Submit Page EXECUTE_QUERY
    END BUS_ID_VALIDATION;

    PROCEDURE PRE_INSERT
    IS
    BEGIN
        FORMS_APX.FORM_TRIGGER_FAILURE(c_msg_insert_not_allowed);
    END PRE_INSERT;

    -- Source: IMPORTERS_CENTRAL.PRE-UPDATE
    --   IF :REJCT_RESON IS NOT NULL THEN str.dispalert('برجاء استخدام وظيفة رفض تفعيل المستورد', 'INFORMATION'); END IF;
    PROCEDURE PRE_UPDATE (P_REJCT_RESON IN VARCHAR2)
    IS
    BEGIN
        IF P_REJCT_RESON IS NOT NULL THEN
            FORMS_APX.MESSAGE('برجاء استخدام وظيفة رفض تفعيل المستورد');
        END IF;
    END PRE_UPDATE;

    PROCEDURE PRE_DELETE
    IS
    BEGIN
        FORMS_APX.FORM_TRIGGER_FAILURE(c_msg_delete_not_allowed);
    END PRE_DELETE;

    -- ------------------------------------------------------------------ FUNCTIONS
    -- Source: PU ADJ_FUNS
    --   IF NVL(:PENDING_ACTIVE, 0) = 0 THEN TMPLT.ENABLE_FUN('IMPR1150_ACTIVATE'); TMPLT.ENABLE_FUN('IMPR1150_REJECT');
    --   ELSE TMPLT.DISABLE_FUN(...) both
    FUNCTION ADJ_FUNS (P_PENDING_ACTIVE IN NUMBER) RETURN VARCHAR2
    IS
    BEGIN
        IF NVL(P_PENDING_ACTIVE, c_pending) = c_pending THEN
            RETURN c_activate || ',' || c_reject;
        END IF;
        RETURN NULL;
    END ADJ_FUNS;

    -- Source: PU EXEC_FUNS (CD = IMPR1150_ACTIVATE / IMPR1150_REJECT), commits as in Forms (FORMS_DDL('COMMIT')).
    -- The REJECT branch without a reason (first press: show REJCT_RESON, message 'برجاء إدخال سبب الرفض') is the
    -- client-side part of DA "IMPR1150_REJECT EXECUTE-FUNCTION"; the server refuses an empty reason again.
    -- The function is refused when ADJ_FUNS disables it for the record at HQ (TMPLT.DISABLE_FUN: the Forms menu
    -- entry cannot be pressed; a request can be sent by hand in a browser).
    -- SUGGESTION: Forms enables both functions on an empty record (NVL(:PENDING_ACTIVE, 0) = 0); the UPDATE then
    --             changes no row but the activity is still written - refuse when P_IMPR_NBR is null (to agree).
    PROCEDURE EXEC_FUNS (P_FUNCTION_CODE  IN VARCHAR2,
                         P_PORT_CD        IN NUMBER,
                         P_IMPR_NBR       IN NUMBER,
                         P_REJCT_RESON    IN VARCHAR2,
                         P_CURR_PORT_CD   IN NUMBER,
                         SSO_APP_USER     IN VARCHAR2,
                         P_GLOBAL_V_WS_ID IN VARCHAR2)
    IS
        v_pending_active NUMBER;
    BEGIN
        IF P_IMPR_NBR IS NOT NULL THEN
            BEGIN
                SELECT ic.pending_active
                  INTO v_pending_active
                  FROM CUSTOMS.IMPORTERS_CENTRAL@HQPRD.HQ.CUSTOMS.GOV ic
                 WHERE ic.port_cd  = c_hq_port_cd
                   AND ic.impr_nbr = EXEC_FUNS.P_IMPR_NBR;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    v_pending_active := NULL;
            END;
        END IF;
        IF INSTR(',' || ADJ_FUNS(v_pending_active) || ',', ',' || P_FUNCTION_CODE || ',') = 0 THEN
            FORMS_APX.FORM_TRIGGER_FAILURE('الوظيفة غير متاحة لهذا المستورد');   -- TMPLT.DISABLE_FUN (text to agree)
        END IF;

        IF P_FUNCTION_CODE = c_activate THEN
            UPDATE CUSTOMS.IMPORTERS_CENTRAL@HQPRD.HQ.CUSTOMS.GOV ic
               SET ic.pending_active = c_active
             WHERE ic.port_cd  = c_hq_port_cd
               AND ic.impr_nbr = EXEC_FUNS.P_IMPR_NBR;
            add_activity(1, P_PORT_CD, P_IMPR_NBR, P_CURR_PORT_CD, SSO_APP_USER, P_GLOBAL_V_WS_ID);
            COMMIT;                            -- FORMS_DDL('COMMIT'); COMMIT;
            -- str.dispalert('تم تفعيل المستورد', 'ERROR'): success message of the APEX process

        ELSIF P_FUNCTION_CODE = c_reject THEN  -- MOHMAED.NOUH CR-7234
            IF P_REJCT_RESON IS NULL THEN
                -- APEX-DA: str.dispalert('برجاء إدخال سبب الرفض', 'INFORMATION'); SET_BLOCK_PROPERTY(UPDATE_ALLOWED TRUE);
                --          IMPR_REJCT_RESON hidden; REJCT_RESON shown / enabled / navigable;
                --          intrface.make_field_entrable('ACTIVITY', FALSE)
                FORMS_APX.FORM_TRIGGER_FAILURE('برجاء إدخال سبب الرفض');
            END IF;
            -- TODO: verify the column: the Forms UPDATE sets IMPR_REJCT_RESON (text of REJCT_RESON), while the item
            --       IMPR_REJCT_RESON shows column IMPR_REJCT_RESON_CD (CG_REF_CODES domain IMPR_REJCT_RESON).
            UPDATE CUSTOMS.IMPORTERS_CENTRAL@HQPRD.HQ.CUSTOMS.GOV ic
               SET ic.pending_active   = c_rejected,
                   ic.impr_rejct_reson = EXEC_FUNS.P_REJCT_RESON
             WHERE ic.port_cd  = c_hq_port_cd
               AND ic.impr_nbr = EXEC_FUNS.P_IMPR_NBR;
            COMMIT;                            -- FORMS_DDL('COMMIT') before the activity, as in Forms
            add_activity(2, P_PORT_CD, P_IMPR_NBR, P_CURR_PORT_CD, SSO_APP_USER, P_GLOBAL_V_WS_ID);
            -- APEX-DA: SET_BLOCK_PROPERTY(UPDATE_ALLOWED FALSE); make_field_entrable('ACTIVITY', TRUE);
            --          REJCT_RESON hidden, IMPR_REJCT_RESON shown (page reload)
            -- str.dispalert('تم إيقاف تفعيل المستورد', 'ERROR'): success message of the APEX process
            -- :global.PORT_CD / IMPR_NBR := ...; CLEAR_BLOCK; :global.Exec_Query_Now := 1: the page is shown
            -- again with the same P0_PAGE_PK (branch "stay in the form")
        END IF;
    END EXEC_FUNS;

    -- =========================================================================
    -- 4 VERSION
    -- =========================================================================
    FUNCTION PKG_VERSION
       RETURN VARCHAR2
    IS
    BEGIN
       RETURN V_INFO;
    END PKG_VERSION;

END IMPR1150;
/
SHOW ERRORS
