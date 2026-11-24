-- =============================================================================
-- Package body: IMPR1125   (matches impr1125_spec.sql - f345 standard)
-- Source form : IMPR1125.fmb (IMPR1125_CENTRAL)   Target: APEX 21.2 / DB 12.1.0.2   Version: 001
-- Author      : Claude Code     Created: 2026-11-24   (see the spec history)
-- Rules: no Forms built-ins (FORMS_APX instead), no COMMIT / ROLLBACK,
--        parameters named after their binds without I_ / IO_ / O_; page items P<page>_X -> P_X;
--        inside SQL every parameter is qualified with its member name; identifiers <= 30 bytes.
-- Common helpers: FORMS_APX (version 004), called as FORMS_APX.<NAME>.
-- Layout (docs/f345_reference_standard.md §10): PRIVATE HELPERS (top, used by the members below)
-- -> VERSION -> f345 HELPERS -> BLOCK HQ_IMPRS -> BLOCK IMPR_CNTRL_SUSPNS -> PROGRAM UNITS
-- -> UI LOGIC FOR APEX DYNAMIC ACTIONS (comments only).
-- Status: NOT COMPILED. External DB packages without source: GNRL, SMS_MESSAGE,
--         LIB_APX_USR.APEX_NOTIFICATIONS (calls copied unchanged from the Forms code).
-- =============================================================================
SET DEFINE OFF

CREATE OR REPLACE PACKAGE BODY LIB_APX_USR.IMPR1125
AS
    c_sysobj_importers CONSTANT NUMBER := 9;      -- ACTIVITY.ADD_ACTIVITY(9, ...)
    c_subject_central  CONSTANT NUMBER := 7;      -- ACTIVITY.ADD_ACTIVITY(9, 7, ...): central suspension
    c_activity_insert  CONSTANT NUMBER := 1;
    c_activity_update  CONSTANT NUMBER := 2;
    c_activity_delete  CONSTANT NUMBER := 3;

    -- =========================================================================
    -- PRIVATE HELPERS
    -- =========================================================================

    -- Stored row of a central suspension (NULL fields for a new row). Forms fires WHEN-VALIDATE-ITEM only
    -- when the item value changed; an IG row validation sees every column of a changed row, so the
    -- column validations compare with the stored value and skip an unchanged one (as IMPR1120).
    FUNCTION stored_suspension (p_hq_impr_nbr IN NUMBER,
                                p_suspn_seq   IN NUMBER) RETURN impr_cntrl_suspns%ROWTYPE
    IS
        v_row impr_cntrl_suspns%ROWTYPE;
    BEGIN
        IF p_suspn_seq IS NULL THEN
            RETURN v_row;
        END IF;
        SELECT *
          INTO v_row
          FROM impr_cntrl_suspns s
         WHERE s.hq_impr_nbr = p_hq_impr_nbr
           AND s.suspn_seq   = p_suspn_seq;
        RETURN v_row;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN v_row;
    END stored_suspension;

    -- Forms: IF NOT ACTIVITY.ADD_ACTIVITY(9, 7, <type>, :HQ_IMPR_NBR||'!'||:SUSPN_SEQ) THEN
    --            RAISE FORM_TRIGGER_FAILURE;
    -- ACTIVITY.ADD_ACTIVITY (CIC_LIB.pld) passes :PARAMETER.P_Curr_Port_Cd, P_USER_ID, P_WS_ID to
    -- ACTIVITY_DB.ADD_ACTIVITY and on 0 shows V_MSG_TXT (CFG_SYSTEM_ERROR) and returns FALSE.
    PROCEDURE add_activity (p_activity_type IN NUMBER,
                            p_hq_impr_nbr   IN NUMBER,
                            p_suspn_seq     IN NUMBER,
                            p_curr_port_cd  IN NUMBER,
                            p_user_id       IN VARCHAR2,
                            p_ws_id         IN VARCHAR2)
    IS
        v_msg VARCHAR2(2000);
    BEGIN
        IF activity_db.add_activity(c_sysobj_importers, c_subject_central, p_activity_type,
                                    p_hq_impr_nbr || '!' || p_suspn_seq,
                                    p_curr_port_cd, p_user_id, p_ws_id, v_msg) = 0 THEN
            FORMS_APX.FORM_TRIGGER_FAILURE(v_msg);
        END IF;
    END add_activity;

    -- ROWID of the first HQ_IMPRS row matching the unified number or the business id (value of
    -- P0_PAGE_PK), NULL when not found. Forms queried the block with the criterion and showed the first
    -- row of the result (single-record block); MIN(ROWID) stands for "first row".
    FUNCTION hq_importer_row_id (p_hq_impr_nbr IN NUMBER,
                                 p_bus_id      IN VARCHAR2) RETURN VARCHAR2
    IS
        v_row_id VARCHAR2(18);
    BEGIN
        SELECT ROWIDTOCHAR(MIN(h.ROWID))
          INTO v_row_id
          FROM hq_imprs h
         WHERE (p_hq_impr_nbr IS NULL OR h.hq_impr_nbr = p_hq_impr_nbr)
           AND (p_bus_id      IS NULL OR h.bus_id      = p_bus_id)
           AND (p_hq_impr_nbr IS NOT NULL OR p_bus_id IS NOT NULL);
        RETURN v_row_id;
    END hq_importer_row_id;

    -- =========================================================================
    -- PACKAGE VERSION
    -- =========================================================================
    -- SELECT IMPR1125.PKG_VERSION FROM dual;  -> package name, version, modified date / by
    FUNCTION PKG_VERSION
       RETURN VARCHAR2
    IS
    BEGIN
       RETURN V_INFO;
    END PKG_VERSION;

    -- =========================================================================
    -- f345 HELPERS
    -- =========================================================================

    -- P0_PAGE_PK = ROWID of the HQ_IMPRS row. No port scope: suspensions are central.
    PROCEDURE P0_PAGE_PK_CHECK (P_PAGE_PK IN OUT VARCHAR2)
    IS
        v_cnt NUMBER;
    BEGIN
        IF P_PAGE_PK IS NULL THEN
            RETURN;
        END IF;
        P_PAGE_PK := FORMS_APX.ROWID_FROM_URL(P_PAGE_PK);   -- URL-safe ROWID of page 112501 -> ROWID
        SELECT COUNT(*)
          INTO v_cnt
          FROM hq_imprs h
         WHERE h.ROWID = CHARTOROWID(P0_PAGE_PK_CHECK.P_PAGE_PK);
        IF v_cnt = 0 THEN
            P_PAGE_PK := NULL;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN               -- ORA-01410 invalid ROWID ...: not a key of this page
            P_PAGE_PK := NULL;
    END P0_PAGE_PK_CHECK;

    -- =========================================================================
    -- BLOCK HQ_IMPRS  (master)
    -- =========================================================================
    -- Source: HQ_IMPRS.POST-QUERY (first and second block)
    -- Original Forms code:
    --   :GLOBAL.HQ_IMPR_NBR := NULL; :GLOBAL.BUS_NBR := NULL;
    --   SELECT BUS_ID_TYPE_NAME INTO :BUS_ID_TYPE_NAME FROM BUS_ID_TYPES WHERE BUS_ID_TYPE_CD = :BUS_ID_TYPE_CD;
    --   SELECT ARBC_IMPR_NAME, ENG_IMPR_NAME, CTRY_CD, IMPR_TYPE_CD, IMPR_EXPR_TYPE, CITY_CODE_OF_ID
    --     INTO :ARBC_IMPR_NAME, :ENG_IMPR_NAME, :CTRY_CD, :IMPR_TYPE_CD, :IMPR_EXPR_TYPE, :CITY_CODE_OF_ID
    --     FROM SINGLE_IMPORTERS WHERE HQ_IMPR_NBR = :HQ_IMPRS.HQ_IMPR_NBR;
    --   IF :CTRY_CD IS NOT NULL THEN SELECT CRTY_ARBC_NAME INTO :CRTY_ARBC_NAME FROM COUNTRIES WHERE CTRY_CD = :CTRY_CD; END IF;
    --   IF :CITY_CODE_OF_ID IS NOT NULL THEN SELECT CITY_ARB_NAME INTO :CITY_CODE_OF_NAME FROM CITIES
    --      WHERE CTRY_CD = :CTRY_CD AND CITY_CD = :CITY_CODE_OF_ID; END IF;
    --   IF :IMPR_TYPE_CD IS NOT NULL THEN SELECT IMPR_TYPE_NAME INTO :IMPR_TYPE_NAME FROM IMPR_TYPES
    --      WHERE IMPR_TYPE_CD = :IMPR_TYPE_CD; END IF;
    -- The globals are not needed (P0_PAGE_PK carries the key). No exception handler in Forms: a
    -- NO_DATA_FOUND / TOO_MANY_ROWS stopped POST-QUERY with an error (FRM-40735); kept as it is.
    -- SUGGESTION: SINGLE_IMPORTERS may hold several rows per unified number (TOO_MANY_ROWS); take the
    --             first one (ROWNUM = 1) once the data owner confirms (inventory §15 #3).
    PROCEDURE HQ_IMPRS_POST_QUERY (P_HQ_IMPR_NBR      IN     NUMBER,
                                   P_BUS_ID_TYPE_CD   IN     NUMBER,
                                   P_BUS_ID_TYPE_NAME    OUT VARCHAR2,
                                   P_ARBC_IMPR_NAME      OUT VARCHAR2,
                                   P_ENG_IMPR_NAME       OUT VARCHAR2,
                                   P_CTRY_CD             OUT VARCHAR2,
                                   P_IMPR_TYPE_CD        OUT VARCHAR2,
                                   P_IMPR_EXPR_TYPE      OUT VARCHAR2,
                                   P_CITY_CODE_OF_ID     OUT VARCHAR2,
                                   P_CRTY_ARBC_NAME      OUT VARCHAR2,
                                   P_CITY_CODE_OF_NAME   OUT VARCHAR2,
                                   P_IMPR_TYPE_NAME      OUT VARCHAR2)
    IS
    BEGIN
        SELECT t.bus_id_type_name
          INTO HQ_IMPRS_POST_QUERY.P_BUS_ID_TYPE_NAME
          FROM bus_id_types t
         WHERE t.bus_id_type_cd = HQ_IMPRS_POST_QUERY.P_BUS_ID_TYPE_CD;

        SELECT s.arbc_impr_name, s.eng_impr_name, s.ctry_cd, s.impr_type_cd, s.impr_expr_type,
               s.city_code_of_id
          INTO HQ_IMPRS_POST_QUERY.P_ARBC_IMPR_NAME, HQ_IMPRS_POST_QUERY.P_ENG_IMPR_NAME,
               HQ_IMPRS_POST_QUERY.P_CTRY_CD, HQ_IMPRS_POST_QUERY.P_IMPR_TYPE_CD,
               HQ_IMPRS_POST_QUERY.P_IMPR_EXPR_TYPE, HQ_IMPRS_POST_QUERY.P_CITY_CODE_OF_ID
          FROM single_importers s
         WHERE s.hq_impr_nbr = HQ_IMPRS_POST_QUERY.P_HQ_IMPR_NBR;

        IF P_CTRY_CD IS NOT NULL THEN
            SELECT c.crty_arbc_name
              INTO HQ_IMPRS_POST_QUERY.P_CRTY_ARBC_NAME
              FROM countries c
             WHERE c.ctry_cd = HQ_IMPRS_POST_QUERY.P_CTRY_CD;
        END IF;

        IF P_CITY_CODE_OF_ID IS NOT NULL THEN
            SELECT ci.city_arb_name
              INTO HQ_IMPRS_POST_QUERY.P_CITY_CODE_OF_NAME
              FROM cities ci
             WHERE ci.ctry_cd = HQ_IMPRS_POST_QUERY.P_CTRY_CD
               AND ci.city_cd = HQ_IMPRS_POST_QUERY.P_CITY_CODE_OF_ID;
        END IF;

        IF P_IMPR_TYPE_CD IS NOT NULL THEN
            SELECT it.impr_type_name
              INTO HQ_IMPRS_POST_QUERY.P_IMPR_TYPE_NAME
              FROM impr_types it
             WHERE it.impr_type_cd = HQ_IMPRS_POST_QUERY.P_IMPR_TYPE_CD;
        END IF;
    END HQ_IMPRS_POST_QUERY;

    -- Source: HQ_IMPRS.POST-QUERY (third block)
    -- Original Forms code:
    --   SELECT COUNT(*) INTO V_COUNT FROM IMPR_CNTRL_SUSPNS
    --    WHERE HQ_IMPR_NBR = :HQ_IMPRS.HQ_IMPR_NBR AND SUSPN_RLSE_DT IS NOT NULL;
    --   IF V_COUNT > 0 THEN
    --     RET := STR.DispALERT(' توجد إيقافات محذوفة من على هذا المستورد , هل تود أستعراضها ؟ ','CONFIRM');
    --     IF Ret = alert_button1 THEN DELETE_SUSPS_LOV; END IF;
    --   END IF;
    -- The question and the call are UI (see the UI LOGIC section); only the count is here.
    FUNCTION RELEASED_SUSPENSIONS_EXIST (P_HQ_IMPR_NBR IN NUMBER) RETURN BOOLEAN
    IS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*)
          INTO v_count
          FROM impr_cntrl_suspns s
         WHERE s.hq_impr_nbr = RELEASED_SUSPENSIONS_EXIST.P_HQ_IMPR_NBR
           AND s.suspn_rlse_dt IS NOT NULL;
        RETURN v_count > 0;
    END RELEASED_SUSPENSIONS_EXIST;

    -- Source: HQ_IMPRS.BUS_ID.WHEN-VALIDATE-ITEM
    -- Original Forms code:
    --   IF :HQ_IMPRS.BUS_ID IS NOT NULL THEN
    --     SELECT COUNT(*) INTO V_COUNT FROM HQ_IMPRS WHERE BUS_ID = :HQ_IMPRS.BUS_ID;
    --     IF V_COUNT > 0 THEN :GLOBAL.BUS_NBR := :HQ_IMPRS.BUS_ID;   (see BUS_ID_WHEN_VALIDATE_ITEM)
    --     ELSE STR.DISPALERT('رقم الاستدلالي للمستورد المدخل غير صحيح، أدخل الرقم الصحيح أو استخدم القائمة المرفقة','ERROR');
    --          SINGLE_IMP_LOV;   -> the search page is opened from the page (UI LOGIC section)
    --     END IF;
    --   END IF;
    FUNCTION BUS_ID_VALIDATION (P_BUS_ID IN VARCHAR2) RETURN VARCHAR2
    IS
    BEGIN
        IF P_BUS_ID IS NULL THEN
            RETURN NULL;
        END IF;
        IF hq_importer_row_id(NULL, P_BUS_ID) IS NULL THEN
            RETURN 'رقم الاستدلالي للمستورد المدخل غير صحيح، أدخل الرقم الصحيح أو استخدم القائمة المرفقة';
        END IF;
        RETURN NULL;
    END BUS_ID_VALIDATION;

    -- Source: HQ_IMPRS.BUS_ID.WHEN-VALIDATE-ITEM (existing business id)
    -- Original Forms code:
    --   :GLOBAL.BUS_NBR := :HQ_IMPRS.BUS_ID;
    --   (block WHEN-NEW-ITEM-INSTANCE then runs CLEAR_BLOCK + EXECUTE_QUERY and PRE-QUERY sets
    --    :HQ_IMPRS.BUS_ID := :GLOBAL.BUS_NBR as the query criterion)
    -- APEX: the global is replaced by the ROWID of the first matching HQ_IMPRS row in P0_PAGE_PK.
    PROCEDURE BUS_ID_WHEN_VALIDATE_ITEM (P_BUS_ID  IN     VARCHAR2,
                                         P_PAGE_PK IN OUT VARCHAR2)
    IS
    BEGIN
        FORMS_APX.CHECK_ERROR(BUS_ID_VALIDATION(P_BUS_ID));
        IF P_BUS_ID IS NOT NULL THEN
            P_PAGE_PK := hq_importer_row_id(NULL, P_BUS_ID);
        END IF;
    END BUS_ID_WHEN_VALIDATE_ITEM;

    -- Source: HQ_IMPRS.HQ_IMPR_NBR.WHEN-VALIDATE-ITEM
    -- Original Forms code:
    --   IF :HQ_IMPRS.HQ_IMPR_NBR IS NOT NULL THEN
    --     SELECT COUNT(*) INTO V_COUNT FROM HQ_IMPRS WHERE HQ_IMPR_NBR = :HQ_IMPRS.HQ_IMPR_NBR;
    --     IF V_COUNT > 0 THEN :GLOBAL.HQ_IMPR_NBR := :HQ_IMPRS.HQ_IMPR_NBR;   (see HQ_IMPR_NBR_WHEN_VALIDATE_ITEM)
    --     ELSE STR.DISPALERT('الرقم الموحد للمستورد المدخل غير صحيح، أدخل الرقم الصحيح أو استخدم القائمة المرفقة','ERROR');
    --          SINGLE_IMP_LOV;
    --     END IF;
    --   END IF;
    FUNCTION HQ_IMPR_NBR_VALIDATION (P_HQ_IMPR_NBR IN NUMBER) RETURN VARCHAR2
    IS
    BEGIN
        IF P_HQ_IMPR_NBR IS NULL THEN
            RETURN NULL;
        END IF;
        IF hq_importer_row_id(P_HQ_IMPR_NBR, NULL) IS NULL THEN
            RETURN 'الرقم الموحد للمستورد المدخل غير صحيح، أدخل الرقم الصحيح أو استخدم القائمة المرفقة';
        END IF;
        RETURN NULL;
    END HQ_IMPR_NBR_VALIDATION;

    -- Source: HQ_IMPRS.HQ_IMPR_NBR.WHEN-VALIDATE-ITEM (existing unified number)
    -- Original Forms code:
    --   :GLOBAL.HQ_IMPR_NBR := :HQ_IMPRS.HQ_IMPR_NBR;   (-> WHEN-NEW-ITEM-INSTANCE / PRE-QUERY as for BUS_ID)
    PROCEDURE HQ_IMPR_NBR_WHEN_VALIDATE_ITEM (P_HQ_IMPR_NBR IN     NUMBER,
                                              P_PAGE_PK     IN OUT VARCHAR2)
    IS
    BEGIN
        FORMS_APX.CHECK_ERROR(HQ_IMPR_NBR_VALIDATION(P_HQ_IMPR_NBR));
        IF P_HQ_IMPR_NBR IS NOT NULL THEN
            P_PAGE_PK := hq_importer_row_id(P_HQ_IMPR_NBR, NULL);
        END IF;
    END HQ_IMPR_NBR_WHEN_VALIDATE_ITEM;

    -- Source: block HQ_IMPRS, property Delete Allowed = false (and ON-DELETE = NULL)
    -- Forms: a delete in block HQ_IMPRS fails with FRM-41049. The page 0 toolbar shows DELETE whenever
    -- P0_PAGE_PK is set; suspensions are deleted in the grid.
    -- TODO: confirm the Arabic text of FRM-41049 used in production (same text as IMPR1120).
    PROCEDURE PRE_DELETE
    IS
    BEGIN
        FORMS_APX.FORM_TRIGGER_FAILURE('لا يمكن حذف بيانات المستورد من هذه الشاشة - احذف التوقيف من الجدول');
    END PRE_DELETE;

    -- =========================================================================
    -- BLOCK IMPR_CNTRL_SUSPNS  (detail)
    -- =========================================================================
    -- Source: IMPR_CNTRL_SUSPNS.SUSPN_STRT_DT.WHEN-VALIDATE-ITEM
    -- Original Forms code:
    --   IF :System.TRIGGER_ITEM = :System.CURSOR_ITEM THEN
    --     IF :System.Cursor_Value IS NOT NULL THEN
    --       HDATE := TO_DATE(:System.Cursor_Value);
    --       IF NOT HIJDATE.VALID_HIJ_DATE(HDATE) THEN RAISE FORM_TRIGGER_FAILURE; END IF;
    -- HIJDATE.VALID_HIJ_DATE shows its own message (CIC_LIB.pld); FORMS_APX.HIJRI_DATE_ERROR returns it.
    -- An unchanged stored value is not validated again (Forms WVI fires only on change).
    FUNCTION SUSPN_STRT_DT_VALIDATION (SUSPN_STRT_DT IN VARCHAR2,
                                       HQ_IMPR_NBR   IN NUMBER,
                                       SUSPN_SEQ     IN NUMBER) RETURN VARCHAR2
    IS
    BEGIN
        IF SUSPN_STRT_DT IS NULL
           OR SUSPN_STRT_DT = FORMS_APX.HIJRI_TEXT(stored_suspension(HQ_IMPR_NBR, SUSPN_SEQ).suspn_strt_dt) THEN
            RETURN NULL;
        END IF;
        RETURN FORMS_APX.HIJRI_DATE_ERROR(SUSPN_STRT_DT);
    END SUSPN_STRT_DT_VALIDATION;

    -- Source: IMPR_CNTRL_SUSPNS.SUSPN_END_DT.WHEN-VALIDATE-ITEM
    -- Original Forms code:
    --   (valid Hijri date, as SUSPN_STRT_DT)
    --   IF :SUSPN_END_DT < :SUSPN_STRT_DT THEN
    --     STR.DISPALERT(' لا يمكن ان يكون تاريخ نهاية الأيقاف أصغر من تاريخ بداية الأيقاف', 'ERROR');
    --     RAISE FORM_TRIGGER_FAILURE;
    --   END IF;
    -- Forms compared the two DATE values directly (no HIJDATE.COMPARE_HIJ_DATES); kept.
    -- An unchanged stored value is not validated again (Forms WVI fires only on change).
    FUNCTION SUSPN_END_DT_VALIDATION (SUSPN_STRT_DT IN VARCHAR2,
                                      SUSPN_END_DT  IN VARCHAR2,
                                      HQ_IMPR_NBR   IN NUMBER,
                                      SUSPN_SEQ     IN NUMBER) RETURN VARCHAR2
    IS
        v_err VARCHAR2(2000);
    BEGIN
        IF SUSPN_END_DT IS NULL
           OR SUSPN_END_DT = FORMS_APX.HIJRI_TEXT(stored_suspension(HQ_IMPR_NBR, SUSPN_SEQ).suspn_end_dt) THEN
            RETURN NULL;
        END IF;
        v_err := FORMS_APX.HIJRI_DATE_ERROR(SUSPN_END_DT);
        IF v_err IS NOT NULL THEN
            RETURN v_err;
        END IF;
        IF SUSPN_STRT_DT IS NOT NULL AND FORMS_APX.HIJRI_DATE_ERROR(SUSPN_STRT_DT) IS NULL
           AND FORMS_APX.HIJRI_TEXT_TO_DATE(SUSPN_END_DT) < FORMS_APX.HIJRI_TEXT_TO_DATE(SUSPN_STRT_DT) THEN
            RETURN ' لا يمكن ان يكون تاريخ نهاية الأيقاف أصغر من تاريخ بداية الأيقاف';
        END IF;
        RETURN NULL;
    END SUSPN_END_DT_VALIDATION;

    -- Source: IMPR_CNTRL_SUSPNS.PRE-INSERT
    -- Original Forms code:
    --   SELECT NVL(MAX(SUSPN_SEQ),0)+1 INTO :IMPR_CNTRL_SUSPNS.SUSPN_SEQ FROM IMPR_CNTRL_SUSPNS;
    --   IF NOT ACTIVITY.ADD_ACTIVITY(9, 7, 1, :IMPR_CNTRL_SUSPNS.HQ_IMPR_NBR||'!'||:IMPR_CNTRL_SUSPNS.SUSPN_SEQ) THEN
    --     RAISE FORm_Trigger_Failure;
    --   END IF;
    -- Unlike IMPR1120, the number is always recalculated (no "IF SUSPN_SEQ IS NULL").
    -- SUGGESTION: MAX + 1 over the whole table is not safe when two users save at the same time;
    --             a sequence needs a migration script and a decision (inventory §15 #5).
    PROCEDURE IMPR_CNTRL_SUSPNS_PRE_INSERT (SUSPN_SEQ        IN OUT NUMBER,
                                            HQ_IMPR_NBR      IN     NUMBER,
                                            P_CURR_PORT_CD   IN     NUMBER,
                                            SSO_APP_USER     IN     VARCHAR2,
                                            P_GLOBAL_V_WS_ID IN     VARCHAR2)
    IS
    BEGIN
        SELECT NVL(MAX(s.suspn_seq), 0) + 1
          INTO IMPR_CNTRL_SUSPNS_PRE_INSERT.SUSPN_SEQ
          FROM impr_cntrl_suspns s;
        add_activity(c_activity_insert, HQ_IMPR_NBR, SUSPN_SEQ,
                     P_CURR_PORT_CD, SSO_APP_USER, P_GLOBAL_V_WS_ID);
    END IMPR_CNTRL_SUSPNS_PRE_INSERT;

    -- Source: IMPR_CNTRL_SUSPNS.POST-INSERT (CR-8414, "central by Nasser 29-06-2025")
    -- Original Forms code:
    --   SELECT RV_MEANING INTO V_RV_MEANING FROM CG_REF_CODES
    --    WHERE RV_DOMAIN = 'SUSPN SIDE CD' AND RV_LOW_VALUE = :SUSPN_SIDE_CD;
    --   V_ORG_HOTLINE := 19993; V_ORG_NAME := 'https://zatca.gov.sa';
    --   IF NVL(gnrl.get_customs_setting(:PARAMETER.P_CURR_PORT_CD, 'NE_INTEGRATION', 21), 0) = 1 THEN
    --     V_NE_IN_SEND := 'P_RV_MEANING=' || V_RV_MEANING || ',P_BUS_ID=' || :BUS_ID
    --       || ',P_SUSPN_STRT_DT=' || TO_CHAR(:SUSPN_STRT_DT,'MI-MM-YYYY')
    --       || ',P_SUSPN_END_DT=' || TO_CHAR(:SUSPN_END_DT,'MI-MM-YYYY')
    --       || ',P_SUSPN_RSN_TEXT=' || :SUSPN_RSN_TEXT || ',ORG_HOTLINE=' || V_ORG_HOTLINE
    --       || ',ORG_NAME=' || V_ORG_NAME;
    --     LIB_APX_USR.APEX_NOTIFICATIONS.SEND_SMS_EMAIL_NOTIFY(PORT_CODE => :PARAMETER.P_CURR_PORT_CD,
    --       EVENT_CODE => 'IMPR_010', TO_EMAIL => NULL, TO_MOBILE_NO => V_MOBILE_NBR, TO_ID_NO => NULL,
    --       RECIPIENT_TYPE => var_RECIPIENT_TYPE, NOTE_PRIORITY => var_NOTE_PRIORITY, MESSAGE_LANGUAGE => NULL,
    --       VARIABLES => V_NE_IN_SEND, JSON_ATTACH => NULL, ATTACH_TYPE => NULL, ATTACH_NAME => NULL,
    --       ATTACH_CATEGORY => NULL, STATUS => var_STATUS, P_MESSAGE => var_P_MESSAGE);
    --   ELSE
    --     V_SMS_MSG_BODY := ' تم ايقاف مركزي من قبل '||V_RV_MEANING||' للسجل التجاري '||:BUS_ID||
    --       ' من تاريخ '||TO_CHAR(:SUSPN_STRT_DT,'MI-MM-YYYY')||' الى تاريخ '||TO_CHAR(:SUSPN_END_DT,'MI-MM-YYYY')||
    --       ' بسبب '||:SUSPN_RSN_TEXT;
    --     SELECT MOBILE_NO INTO V_MOBILE_NBR FROM IMPORTER_BASIC_DATA
    --      WHERE HQ_IMPR_NBR = :IMPR_CNTRL_SUSPNS.HQ_IMPR_NBR AND ROWNUM=1 AND MOBILE_NO IS NOT NULL;
    --     SMS_MESSAGE.SEND_SMS_MESSAGE(9,2,1,:PARAMETER.P_CURR_PORT_CD,NULL,V_MOBILE_NBR,
    --       V_SMS_MSG_BODY,:IMPR_CNTRL_SUSPNS.HQ_IMPR_NBR||'|'||:SUSPN_SEQ);
    --   END IF;
    --   STANDARD.COMMIT;
    --   EXCEPTION WHEN OTHERS THEN NULL;
    -- STANDARD.COMMIT is removed (HIGH, extraction report): APEX commits at the end of the request.
    -- WHEN OTHERS THEN NULL is kept (preserve behaviour).
    -- Kept as in Forms: in the NE_INTEGRATION branch the mobile number is never read, so TO_MOBILE_NO is NULL.
    -- SUGGESTION: read the mobile number before the IF (as IMPR1120 does) and log errors (inventory §15 #4).
    -- :BUS_ID is the master item HQ_IMPRS.BUS_ID.
    -- TODO: MISSING SOURCE GNRL, SMS_MESSAGE, LIB_APX_USR.APEX_NOTIFICATIONS (calls copied as in Forms).
    PROCEDURE IMPR_CNTRL_SUSPNS_POST_INSERT (HQ_IMPR_NBR    IN NUMBER,
                                             SUSPN_SEQ      IN NUMBER,
                                             SUSPN_STRT_DT  IN VARCHAR2,
                                             SUSPN_END_DT   IN VARCHAR2,
                                             SUSPN_RSN_TEXT IN VARCHAR2,
                                             SUSPN_SIDE_CD  IN NUMBER,
                                             P_BUS_ID       IN VARCHAR2,
                                             P_CURR_PORT_CD IN NUMBER)
    IS
        v_mobile_nbr     NUMBER;
        v_sms_msg_body   VARCHAR2(2000);
        v_rv_meaning     VARCHAR2(200);
        v_recipient_type NUMBER;
        v_note_priority  VARCHAR2(32767);
        v_status         NUMBER;
        v_message        VARCHAR2(32767);
        v_ne_in_send     VARCHAR2(4000);
        c_org_hotline    CONSTANT NUMBER        := 19993;
        c_org_name       CONSTANT VARCHAR2(500) := 'https://zatca.gov.sa';
    BEGIN
        SELECT c.rv_meaning
          INTO v_rv_meaning
          FROM cg_ref_codes c
         WHERE c.rv_domain    = 'SUSPN SIDE CD'
           AND c.rv_low_value = TO_CHAR(IMPR_CNTRL_SUSPNS_POST_INSERT.SUSPN_SIDE_CD);

        IF NVL(gnrl.get_customs_setting(P_CURR_PORT_CD, 'NE_INTEGRATION', 21), 0) = 1 THEN
            v_ne_in_send :=    'P_RV_MEANING='      || v_rv_meaning
                            || ',P_BUS_ID='         || P_BUS_ID
                            || ',P_SUSPN_STRT_DT='  || TO_CHAR(FORMS_APX.HIJRI_TEXT_TO_DATE(SUSPN_STRT_DT), 'MI-MM-YYYY')
                            || ',P_SUSPN_END_DT='   || TO_CHAR(FORMS_APX.HIJRI_TEXT_TO_DATE(SUSPN_END_DT), 'MI-MM-YYYY')
                            || ',P_SUSPN_RSN_TEXT=' || SUSPN_RSN_TEXT
                            || ',ORG_HOTLINE='      || c_org_hotline
                            || ',ORG_NAME='         || c_org_name;
            LIB_APX_USR.APEX_NOTIFICATIONS.SEND_SMS_EMAIL_NOTIFY(
                PORT_CODE        => P_CURR_PORT_CD,
                EVENT_CODE       => 'IMPR_010',
                TO_EMAIL         => NULL,
                TO_MOBILE_NO     => v_mobile_nbr,               -- NULL, as in Forms (see the header)
                TO_ID_NO         => NULL,
                RECIPIENT_TYPE   => v_recipient_type,
                NOTE_PRIORITY    => v_note_priority,
                MESSAGE_LANGUAGE => NULL,
                VARIABLES        => v_ne_in_send,
                JSON_ATTACH      => NULL,
                ATTACH_TYPE      => NULL,
                ATTACH_NAME      => NULL,
                ATTACH_CATEGORY  => NULL,
                STATUS           => v_status,
                P_MESSAGE        => v_message);
        ELSE
            v_sms_msg_body :=    ' تم ايقاف مركزي من قبل ' || v_rv_meaning
                              || ' للسجل التجاري '         || P_BUS_ID
                              || ' من تاريخ '              || TO_CHAR(FORMS_APX.HIJRI_TEXT_TO_DATE(SUSPN_STRT_DT), 'MI-MM-YYYY')
                              || ' الى تاريخ '             || TO_CHAR(FORMS_APX.HIJRI_TEXT_TO_DATE(SUSPN_END_DT), 'MI-MM-YYYY')
                              || ' بسبب '                  || SUSPN_RSN_TEXT;
            SELECT b.mobile_no
              INTO v_mobile_nbr
              FROM importer_basic_data b
             WHERE b.hq_impr_nbr = IMPR_CNTRL_SUSPNS_POST_INSERT.HQ_IMPR_NBR
               AND ROWNUM = 1
               AND b.mobile_no IS NOT NULL;
            sms_message.send_sms_message(9, 2, 1, P_CURR_PORT_CD, NULL, v_mobile_nbr, v_sms_msg_body,
                                         HQ_IMPR_NBR || '|' || SUSPN_SEQ);
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            NULL;                                           -- as in Forms (see the header comment)
    END IMPR_CNTRL_SUSPNS_POST_INSERT;

    -- Source: IMPR_CNTRL_SUSPNS.PRE-UPDATE
    -- Original Forms code:
    --   IF NOT ACTIVITY.ADD_ACTIVITY(9, 7, 2, :IMPR_CNTRL_SUSPNS.HQ_IMPR_NBR||'!'||:IMPR_CNTRL_SUSPNS.SUSPN_SEQ) THEN
    --     RAISE FORm_Trigger_Failure;
    --   END IF;
    PROCEDURE IMPR_CNTRL_SUSPNS_PRE_UPDATE (HQ_IMPR_NBR      IN NUMBER,
                                            SUSPN_SEQ        IN NUMBER,
                                            P_CURR_PORT_CD   IN NUMBER,
                                            SSO_APP_USER     IN VARCHAR2,
                                            P_GLOBAL_V_WS_ID IN VARCHAR2)
    IS
    BEGIN
        add_activity(c_activity_update, HQ_IMPR_NBR, SUSPN_SEQ,
                     P_CURR_PORT_CD, SSO_APP_USER, P_GLOBAL_V_WS_ID);
    END IMPR_CNTRL_SUSPNS_PRE_UPDATE;

    -- Source: IMPR_CNTRL_SUSPNS.ON-DELETE (+ IMPR_CNTRL_SUSPNS.KEY-DELREC -> TMPLT.KEY_DELETE_RECORD)
    -- Original Forms code:
    --   HDATE := HIJDATE.CUR_HIJ_DATE;
    --   UPDATE IMPR_CNTRL_SUSPNS SET IMPR_CNTRL_SUSPNS.SUSPN_RLSE_DT = HDATE
    --    WHERE IMPR_CNTRL_SUSPNS.HQ_IMPR_NBR = :IMPR_CNTRL_SUSPNS.HQ_IMPR_NBR
    --      AND IMPR_CNTRL_SUSPNS.SUSPN_SEQ   = :IMPR_CNTRL_SUSPNS.SUSPN_SEQ;
    --   --COMMIT ;
    --   IF NOT ACTIVITY.ADD_ACTIVITY(9, 7, 3, :IMPR_CNTRL_SUSPNS.HQ_IMPR_NBR||'!'||:IMPR_CNTRL_SUSPNS.SUSPN_SEQ) THEN
    --     RAISE FORm_Trigger_Failure;
    --   END IF;
    -- KEY_DELETE_RECORD's confirm and its COMMIT -> APEX (IG delete confirm, commit at the end).
    PROCEDURE IMPR_CNTRL_SUSPNS_ON_DELETE (HQ_IMPR_NBR      IN NUMBER,
                                           SUSPN_SEQ        IN NUMBER,
                                           P_CURR_PORT_CD   IN NUMBER,
                                           SSO_APP_USER     IN VARCHAR2,
                                           P_GLOBAL_V_WS_ID IN VARCHAR2)
    IS
        v_today DATE;
    BEGIN
        v_today := FORMS_APX.CUR_HIJ_DATE;
        UPDATE impr_cntrl_suspns s
           SET s.suspn_rlse_dt = v_today
         WHERE s.hq_impr_nbr = IMPR_CNTRL_SUSPNS_ON_DELETE.HQ_IMPR_NBR
           AND s.suspn_seq   = IMPR_CNTRL_SUSPNS_ON_DELETE.SUSPN_SEQ;
        add_activity(c_activity_delete, HQ_IMPR_NBR, SUSPN_SEQ,
                     P_CURR_PORT_CD, SSO_APP_USER, P_GLOBAL_V_WS_ID);
    END IMPR_CNTRL_SUSPNS_ON_DELETE;

    -- Source: Forms transaction processing of block IMPR_CNTRL_SUSPNS (default INSERT / UPDATE of the base
    --         table, ON-DELETE instead of DELETE), one row at a time as Forms posts them:
    --           C: PRE-INSERT -> INSERT -> POST-INSERT
    --           U: PRE-UPDATE -> UPDATE (table usage UPD: start / end date, reason, notes, side, release date;
    --              the release date is not enterable and no trigger changes it on update, so it is not set)
    --           D: ON-DELETE (soft delete)
    -- Why one member: PRE-INSERT's MAX + 1 needs the previous new row already inserted, and the native
    --         IG DML would really DELETE a row.
    -- TODO  : lost-update check (the native IG DML compares a row checksum) - decide in step 04 (as IMPR1120).
    PROCEDURE IMPR_CNTRL_SUSPNS_SAVE_ROW (APEX$ROW_STATUS  IN     VARCHAR2,
                                          HQ_IMPR_NBR      IN     NUMBER,
                                          SUSPN_SEQ        IN OUT NUMBER,
                                          SUSPN_STRT_DT    IN     VARCHAR2,
                                          SUSPN_END_DT     IN     VARCHAR2,
                                          SUSPN_RSN_CD     IN     NUMBER,
                                          SUSPN_RSN_TEXT   IN     VARCHAR2,
                                          SUSPN_SIDE_CD    IN     NUMBER,
                                          P_BUS_ID         IN     VARCHAR2,
                                          P_CURR_PORT_CD   IN     NUMBER,
                                          SSO_APP_USER     IN     VARCHAR2,
                                          P_GLOBAL_V_WS_ID IN     VARCHAR2)
    IS
        -- The Hijri texts are converted here, in PL/SQL, before the SQL statements (as IMPR1120 006).
        v_strt_dt DATE;
        v_end_dt  DATE;
    BEGIN
        v_strt_dt := FORMS_APX.HIJRI_TEXT_TO_DATE(SUSPN_STRT_DT);
        v_end_dt  := FORMS_APX.HIJRI_TEXT_TO_DATE(SUSPN_END_DT);
        IF APEX$ROW_STATUS = 'C' THEN
            IMPR_CNTRL_SUSPNS_PRE_INSERT(SUSPN_SEQ, HQ_IMPR_NBR,
                                         P_CURR_PORT_CD, SSO_APP_USER, P_GLOBAL_V_WS_ID);
            INSERT INTO impr_cntrl_suspns (hq_impr_nbr, suspn_seq, suspn_strt_dt, suspn_end_dt,
                                           suspn_rsn_cd, suspn_rsn_text, suspn_side_cd, suspn_rlse_dt)
            VALUES (IMPR_CNTRL_SUSPNS_SAVE_ROW.HQ_IMPR_NBR, IMPR_CNTRL_SUSPNS_SAVE_ROW.SUSPN_SEQ,
                    v_strt_dt, v_end_dt, IMPR_CNTRL_SUSPNS_SAVE_ROW.SUSPN_RSN_CD,
                    IMPR_CNTRL_SUSPNS_SAVE_ROW.SUSPN_RSN_TEXT, IMPR_CNTRL_SUSPNS_SAVE_ROW.SUSPN_SIDE_CD, NULL);
            IMPR_CNTRL_SUSPNS_POST_INSERT(HQ_IMPR_NBR, SUSPN_SEQ, SUSPN_STRT_DT, SUSPN_END_DT,
                                          SUSPN_RSN_TEXT, SUSPN_SIDE_CD, P_BUS_ID, P_CURR_PORT_CD);
        ELSIF APEX$ROW_STATUS = 'U' THEN
            IMPR_CNTRL_SUSPNS_PRE_UPDATE(HQ_IMPR_NBR, SUSPN_SEQ,
                                         P_CURR_PORT_CD, SSO_APP_USER, P_GLOBAL_V_WS_ID);
            UPDATE impr_cntrl_suspns s
               SET s.suspn_strt_dt  = v_strt_dt,
                   s.suspn_end_dt   = v_end_dt,
                   s.suspn_rsn_cd   = IMPR_CNTRL_SUSPNS_SAVE_ROW.SUSPN_RSN_CD,
                   s.suspn_rsn_text = IMPR_CNTRL_SUSPNS_SAVE_ROW.SUSPN_RSN_TEXT,
                   s.suspn_side_cd  = IMPR_CNTRL_SUSPNS_SAVE_ROW.SUSPN_SIDE_CD
             WHERE s.hq_impr_nbr = IMPR_CNTRL_SUSPNS_SAVE_ROW.HQ_IMPR_NBR
               AND s.suspn_seq   = IMPR_CNTRL_SUSPNS_SAVE_ROW.SUSPN_SEQ;
        ELSIF APEX$ROW_STATUS = 'D' THEN
            IMPR_CNTRL_SUSPNS_ON_DELETE(HQ_IMPR_NBR, SUSPN_SEQ,
                                        P_CURR_PORT_CD, SSO_APP_USER, P_GLOBAL_V_WS_ID);
        END IF;
    END IMPR_CNTRL_SUSPNS_SAVE_ROW;

    -- =========================================================================
    -- PROGRAM UNITS   (no executable member: see the spec)
    -- =========================================================================

    -- =========================================================================
    -- UI LOGIC FOR APEX DYNAMIC ACTIONS  (comments only - no executable code)
    -- =========================================================================
    -- APEX-DA: [Source: HQ_IMPRS.HQ_IMPR_NBR.WHEN-VALIDATE-ITEM] -> DA "HQ_IMPR_NBR WHEN-VALIDATE-ITEM"
    -- Original : :GLOBAL.HQ_IMPR_NBR := ...; block WHEN-NEW-ITEM-INSTANCE: CLEAR_BLOCK(NO_VALIDATE);
    --            GO_BLOCK('HQ_IMPRS'); EXECUTE_QUERY;  (PRE-QUERY copies the global into the criterion)
    -- Implement: change of P1125_HQ_IMPR_NBR (while P0_PAGE_PK is null) -> FOS FORMS_APX.CHECK_ERROR(
    --            IMPR1125.HQ_IMPR_NBR_VALIDATION(P_HQ_IMPR_NBR => :P1125_HQ_IMPR_NBR))
    --            -> Submit Page, request EXECUTE_QUERY (process "HQ_IMPR_NBR EXECUTE-QUERY" sets P0_PAGE_PK).
    --            On error the Forms code also opened LOV_IMPORT_HQ_NBR (SINGLE_IMP_LOV): the error text
    --            says to use the list -> the page 0 SEARCH button opens page 112501.
    --
    -- APEX-DA: [Source: HQ_IMPRS.BUS_ID.WHEN-VALIDATE-ITEM] -> DA "BUS_ID WHEN-VALIDATE-ITEM"
    -- Implement: as HQ_IMPR_NBR, with IMPR1125.BUS_ID_VALIDATION(P_BUS_ID => :P1125_BUS_ID) and the process
    --            "BUS_ID EXECUTE-QUERY".
    --
    -- APEX-DA: [Source: HQ_IMPRS.BUS_ID.KEY-LISTVAL, HQ_IMPRS.BUT_SH_HQNUM.WHEN-BUTTON-PRESSED -> SINGLE_IMP_LOV]
    -- Original : CALL_FORM('LOV_IMPORT_HQ_NBR.fmx', ...); IF :GLOBAL.HQ_IMPR_NBR IS NOT NULL THEN :BUS_ID := :GLOBAL.BUS_ID;
    -- Implement: search page 112501 (page 0 SEARCH; BUT_SH_HQNUM = icon button / link to the same page);
    --            the selected row returns its HQ_IMPRS ROWID in P0_PAGE_PK.
    --
    -- APEX-DA: [Source: HQ_IMPRS.POST-QUERY third block -> DELETE_SUSPS_LOV]
    -- Original : STR.DispALERT(' توجد إيقافات محذوفة من على هذا المستورد , هل تود أستعراضها ؟ ','CONFIRM');
    --            IF Ret = alert_button1 THEN DELETE_SUSPS_LOV; -> CALL_FORM('LOV_DELETE_IMP_SUSP.fmx', P_HQ_IMPR_NBR)
    -- Implement: DA "HQ_IMPRS POST-QUERY" on Page Load, server-side condition
    --            IMPR1125.RELEASED_SUSPENSIONS_EXIST(P_HQ_IMPR_NBR => :P1125_HQ_IMPR_NBR): native Confirm
    --            with the same text -> open modal page 112502 (read-only report on IMPR_CNTRL_SUSPNS
    --            WHERE SUSPN_RLSE_DT IS NOT NULL AND HQ_IMPR_NBR = :P112502_P_HQ_IMPR_NBR).
    --
    -- APEX-DA: [Source: HQ_IMPRS items: classes CGSO$CHAR_ARB_DO / CGSO$COMBO_DO (Enabled = false),
    --           BUS_ID_BRNCH / CITY_CODE_OF_ID insert / update false, 12 Designer KEY-LISTVAL checks]
    -- Implement: every P1125 HQ_IMPRS item is Read Only (Always) except P1125_BUS_ID and P1125_HQ_IMPR_NBR
    --            while P0_PAGE_PK is null (HQ_IMPR_NBR has Update Allowed = false).
    --
    -- APEX-DA: [Source: IMPR_CNTRL_SUSPNS.SUSPN_RSN_CD (no canvas, default 1), SUSPN_SIDE_CD (CGSO$COMBO_DO,
    --           display only, default 5)]
    -- Implement: IG column SUSPN_RSN_CD Hidden, Default 1; SUSPN_SIDE_CD Display Only (LOV), Default 5.
    --
    -- APEX-DA: [Source: IMPR_CNTRL_SUSPNS.SUSPN_STRT_DT / SUSPN_END_DT WHEN-VALIDATE-ITEM]
    -- Implement: DA "IMPR_CNTRL_SUSPNS SUSPN_STRT_DT WHEN-VALIDATE-ITEM" / "... SUSPN_END_DT ..." (column change,
    --            FOS FORMS_APX.CHECK_ERROR(IMPR1125.SUSPN_STRT_DT_VALIDATION(...)) / SUSPN_END_DT_VALIDATION(...)).
    --
    -- APEX-DA: [Source: IMPR_CNTRL_SUSPNS.SUSPN_*_DT KEY-LISTVAL / KEY-F4 (INTRFACE.DISP_CALENDAR / DISP_DATE_CON)]
    -- Implement: IG Text Field columns holding the HIJRI_DATE_FORMAT text (region SQL TO_CHAR), CSS class
    --            hijri-date-default (f345 Hijri picker), as IMPR1120.
    --
    -- APEX-DA: [Source: IMPR_CNTRL_SUSPNS.KEY-DELREC -> TMPLT.KEY_DELETE_RECORD] -> IG row delete
    -- Implement: IG delete (native confirm); IMPR_CNTRL_SUSPNS_SAVE_ROW -> IMPR_CNTRL_SUSPNS_ON_DELETE does the
    --            soft delete. The page 0 DELETE (importer) is refused by PRE_DELETE.

END IMPR1125;
/
SHOW ERRORS
