-- =============================================================================
-- Package body: IMPR1170 (version 001, 25-11-2026) - see the spec header. NOT COMPILED.
-- Layout      : 1 private constants, 2 private helpers, 3 APEX entry points (spec order), 4 version.
-- Forms code  : the original trigger text is quoted in analysis/IMPR1170/IMPR1170_inventory.md section 6;
--               every member names its source. Forms UI calls are kept as "-- APEX-DA:" comments.
-- =============================================================================
SET DEFINE OFF

CREATE OR REPLACE PACKAGE BODY LIB_APX_USR.IMPR1170
AS

    -- =========================================================================
    -- 1 PRIVATE CONSTANTS
    -- =========================================================================
    -- url_strg of CR_NBR.KEY-NEXT-ITEM: '<address>' || 99 || '/' || :MCI_DATA.CR_NBR
    -- SUGGESTION: the address is fixed in Forms; move it to a customs setting / Application Setting per environment.
    c_service_url      CONSTANT VARCHAR2(200) := 'http://10.0.0.214:8080/MciDataWebSrvcs/webresources/mciImp/';
    c_service_port     CONSTANT NUMBER        := 99;          -- ||99|| in the URL (head-office port)
    c_service_success  CONSTANT VARCHAR2(10)  := 'success';   -- IF V_respond = 'success'
    c_msg_insert_not_allowed CONSTANT VARCHAR2(200) := 'لا يمكن إضافة بيانات من هذه الشاشة';   -- = IMPR1150 (to agree)
    c_msg_update_not_allowed CONSTANT VARCHAR2(200) := 'لا يمكن تعديل بيانات من هذه الشاشة';   -- (to agree)
    c_msg_delete_not_allowed CONSTANT VARCHAR2(200) := 'لا يمكن حذف بيانات من هذه الشاشة';    -- = IMPR1150 (to agree)

    -- =========================================================================
    -- 2 PRIVATE HELPERS
    -- =========================================================================

    -- CR_NBR of the cached row (the block query after SET_BLOCK_PROPERTY(DEFAULT_WHERE, 'CR_NBR=' || ...));
    -- NULL when the row is not there (the Forms query then finds no record).
    -- Forms compares CR_NBR=<number> (implicit TO_NUMBER of the column); the page compares the text as typed.
    FUNCTION cached_key (p_cr_nbr IN VARCHAR2) RETURN VARCHAR2
    IS
        v_cr_nbr mci_data.cr_nbr%TYPE;
    BEGIN
        SELECT md.cr_nbr
          INTO v_cr_nbr
          FROM mci_data md
         WHERE md.cr_nbr = p_cr_nbr;
        RETURN v_cr_nbr;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END cached_key;

    -- =========================================================================
    -- 3 APEX ENTRY POINTS
    -- =========================================================================

    -- ------------------------------------------------------------------ f345 HELPERS
    PROCEDURE P0_PAGE_PK_CHECK (P_PAGE_PK IN OUT VARCHAR2)
    IS
    BEGIN
        IF P_PAGE_PK IS NOT NULL THEN
            P_PAGE_PK := cached_key(P_PAGE_PK);
        END IF;
    END P0_PAGE_PK_CHECK;

    -- ------------------------------------------------------------------ BLOCK MCI_DATA
    -- Source: MCI_DATA.POST-QUERY
    --   BEGIN
    --   SELECT MC.STATUS_DESC INTO :CR_STAT_DESC FROM MCI_BUS_ID_STATUS MC WHERE MC.BUS_ID_STATUS = :MCI_DATA.CR_STATUS;
    --   EXCEPTION WHEN OTHERS THEN :CR_STAT_DESC := NULL;
    --   END;
    -- WHEN OTHERS narrowed to the two SELECT INTO errors (the other errors are real faults).
    PROCEDURE POST_QUERY (P_CR_STATUS    IN     VARCHAR2,
                          P_CR_STAT_DESC IN OUT VARCHAR2)
    IS
    BEGIN
        SELECT mc.status_desc
          INTO POST_QUERY.P_CR_STAT_DESC
          FROM mci_bus_id_status mc
         WHERE mc.bus_id_status = POST_QUERY.P_CR_STATUS;
    EXCEPTION
        WHEN NO_DATA_FOUND OR TOO_MANY_ROWS THEN
            P_CR_STAT_DESC := NULL;
    END POST_QUERY;

    -- Source: MCI_DATA.CR_NBR.KEY-NEXT-ITEM
    --   IF :MCI_DATA.CR_NBR IS NOT NULL THEN
    --     BEGIN SELECT CR_NBR, LST_TRAN_DT INTO V_CR_NBR, V_LST_DT FROM MCI_DATA WHERE CR_NBR = :MCI_DATA.CR_NBR;
    --     EXCEPTION WHEN OTHERS THEN V_CR_NBR := NULL; V_LST_DT := NULL; END;
    --   END IF;
    --   IF V_CR_NBR IS NOT NULL AND TO_CHAR(V_LST_DT,'DDMMYYYY') = TO_CHAR(SYSDATE,'DDMMYYYY') THEN
    --     SET_BLOCK_PROPERTY('MCI_DATA', DEFAULT_WHERE, 'CR_NBR=' || V_CR_NBR); EXECUTE_QUERY(NO_VALIDATE);
    --   END IF;
    --   IF :MCI_DATA.CR_NBR IS NOT NULL AND ((TO_CHAR(V_LST_DT,'DDMMYYYY') <> TO_CHAR(SYSDATE,'DDMMYYYY') OR V_CR_NBR IS NULL)) THEN
    --     url_strg := 'http://10.0.0.214:8080/MciDataWebSrvcs/webresources/mciImp/' || 99 || '/' || :MCI_DATA.CR_NBR;
    --     V_respond := LIB_USR.prtl_nebras_services.call_web_service(url_strg);
    --     IF V_respond = 'success' THEN SET_BLOCK_PROPERTY(... 'CR_NBR=' || :MCI_DATA.CR_NBR); EXECUTE_QUERY(NO_VALIDATE);
    --     ELSE STR.DISPALERT('	بيانات السجل التجارى رقم ' || :MCI_DATA.CR_NBR || ' حالتة غير فعال أو بياناتة غير متاحة
    --          فى الوقت الحالى من خدمة الربط مع وزارة التجارة', 'ERROR');
    --     END IF;
    --   END IF;
    -- Kept as Forms: a cached row whose LST_TRAN_DT is NULL meets neither condition (NULL <> today is not TRUE):
    -- nothing is shown and the service is not called.
    -- SUGGESTION: treat LST_TRAN_DT NULL as "not loaded today" (NVL) so the service refreshes such a row.
    -- The leading TAB of the Forms alert text is dropped (not visible in APEX).
    PROCEDURE CR_NBR_KEY_NEXT_ITEM (P_CR_NBR  IN     VARCHAR2,
                                    P_PAGE_PK IN OUT VARCHAR2)
    IS
        v_cr_nbr   NUMBER;                    -- V_CR_NBR NUMBER as in Forms
        v_lst_dt   DATE;
        v_url      VARCHAR2(1000);
        v_respond  VARCHAR2(1000);
    BEGIN
        IF P_CR_NBR IS NULL THEN
            RETURN;
        END IF;
        BEGIN
            SELECT md.cr_nbr, md.lst_tran_dt
              INTO v_cr_nbr, v_lst_dt
              FROM mci_data md
             WHERE md.cr_nbr = CR_NBR_KEY_NEXT_ITEM.P_CR_NBR;
        EXCEPTION
            WHEN OTHERS THEN                  -- as Forms (also a non-numeric CR_NBR: ORA-06502 -> not cached)
                v_cr_nbr := NULL;
                v_lst_dt := NULL;
        END;

        IF v_cr_nbr IS NOT NULL AND TO_CHAR(v_lst_dt, 'DDMMYYYY') = TO_CHAR(SYSDATE, 'DDMMYYYY') THEN
            P_PAGE_PK := cached_key(P_CR_NBR);                 -- APEX-DA: EXECUTE_QUERY (branch EXECUTE-QUERY)
        END IF;

        IF TO_CHAR(v_lst_dt, 'DDMMYYYY') <> TO_CHAR(SYSDATE, 'DDMMYYYY') OR v_cr_nbr IS NULL THEN
            v_url     := c_service_url || c_service_port || '/' || P_CR_NBR;
            v_respond := lib_usr.prtl_nebras_services.call_web_service(v_url);   -- TODO: MISSING SOURCE (DB package)
            IF v_respond = c_service_success THEN
                P_PAGE_PK := cached_key(P_CR_NBR);             -- APEX-DA: EXECUTE_QUERY (branch EXECUTE-QUERY)
            ELSE
                FORMS_APX.FORM_TRIGGER_FAILURE('بيانات السجل التجارى رقم ' || P_CR_NBR
                    || ' حالتة غير فعال أو بياناتة غير متاحة فى الوقت الحالى من خدمة الربط مع وزارة التجارة');
            END IF;
        END IF;
    END CR_NBR_KEY_NEXT_ITEM;

    PROCEDURE PRE_INSERT
    IS
    BEGIN
        FORMS_APX.FORM_TRIGGER_FAILURE(c_msg_insert_not_allowed);
    END PRE_INSERT;

    PROCEDURE PRE_UPDATE
    IS
    BEGIN
        FORMS_APX.FORM_TRIGGER_FAILURE(c_msg_update_not_allowed);
    END PRE_UPDATE;

    PROCEDURE PRE_DELETE
    IS
    BEGIN
        FORMS_APX.FORM_TRIGGER_FAILURE(c_msg_delete_not_allowed);
    END PRE_DELETE;

    -- =========================================================================
    -- 4 VERSION
    -- =========================================================================
    FUNCTION PKG_VERSION
       RETURN VARCHAR2
    IS
    BEGIN
       RETURN V_INFO;
    END PKG_VERSION;

END IMPR1170;
/
SHOW ERRORS
