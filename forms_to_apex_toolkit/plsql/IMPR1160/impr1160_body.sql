-- =============================================================================
-- Package body: IMPR1160   (matches impr1160_spec.sql - f345 standard)
-- Source form : IMPR1160.fmb   Target: APEX 21.2 / DB 12.1.0.2   Version: 001
-- Author      : Claude Code     Created: 2026-11-25   (see the spec history)
-- Rules: no Forms built-ins (FORMS_APX instead), no COMMIT / ROLLBACK,
--        parameters named after their binds without I_ / IO_ / O_; page items P<page>_X -> P_X;
--        inside SQL every parameter is qualified with its member name; identifiers <= 30 bytes.
-- Common helpers: FORMS_APX (version 004), called as FORMS_APX.<NAME>.
-- Layout (docs/f345_reference_standard.md §10): PRIVATE HELPERS (top, used by the members below)
-- -> f345 HELPERS -> FORM LEVEL -> BLOCK IMPR_CAR_EXCEPTION -> PROGRAM UNITS -> VERSION
-- -> UI LOGIC FOR APEX DYNAMIC ACTIONS (comments only).
-- Status: NOT COMPILED. External DB package without source: GNRL (calls copied unchanged).
-- =============================================================================
SET DEFINE OFF

CREATE OR REPLACE PACKAGE BODY LIB_APX_USR.IMPR1160
AS
    c_impr_type_individual CONSTANT NUMBER := 4;         -- IMPORTERS.IMPR_TYPE_CD 4 (KEY-NEXT-ITEM, POST-QUERY)
    c_dcltn_customs        CONSTANT NUMBER := 1;         -- DCLTN_TYPE 1 = بيان جمركى (DECLARATIONS)
    c_dcltn_stats          CONSTANT NUMBER := 2;         -- DCLTN_TYPE 2 = بيان إحصائى (STATS_DCLTNS)
    c_group_cars           CONSTANT NUMBER := 76;        -- GROUP_ITEMS.GRP_CODE of the car tariff items
    c_status_inactive      CONSTANT NUMBER := 0;         -- STATUS 0 = غير فعال
    c_sequence_name        CONSTANT VARCHAR2(30) := 'IMPR_CAR_EXPTN_SEQ';
    -- ENTRY_DT: Forms item class CGSO$DATETIME; the page item uses this mask (spec §4)
    c_entry_dt_format      CONSTANT VARCHAR2(30) := 'YYYY/MM/DD HH24:MI:SS';

    -- Forms texts (STR.DispAlert)
    c_msg_suspended        CONSTANT VARCHAR2(200) := 'هذا المستورد موقوف ';
    c_msg_dcltn_unknown    CONSTANT VARCHAR2(200) := 'رقم البيان او  تاريخه الذى تم ادخاله غير معرف فى انظمة البيان ';
    c_msg_dcltn_excepted   CONSTANT VARCHAR2(200) := 'لقد تم استثناء هذا البيان من قبل ';
    c_msg_award_nbr        CONSTANT VARCHAR2(200) := 'لا يمكن ادخال رقم قرار اقل من او يساوي صفر';
    c_msg_no_of_cars       CONSTANT VARCHAR2(200) := 'لا يمكن ادخال عدد سيارات اقل من او يساوي صفر';
    c_msg_status_inactive  CONSTANT VARCHAR2(200) := 'غير مسموح بتعديل الحالة من غير فعال الى فعال';

    -- =========================================================================
    -- PRIVATE HELPERS
    -- =========================================================================

    -- The suspension check of IMPR_NBR.KEY-NEXT-ITEM (the same SELECT is in WHEN-VALIDATE-ITEM): TRUE when the
    -- last suspension row of the importer in the port is open today. The GROUP BY returns no row when nothing
    -- matches (NO_DATA_FOUND = not suspended, as the Forms handler).
    FUNCTION importer_suspended (p_port_cd  IN NUMBER,
                                 p_impr_nbr IN NUMBER) RETURN BOOLEAN
    IS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*)
          INTO v_count
          FROM impr_suspns s
         WHERE s.port_cd = p_port_cd
           AND hijdate_db.cur_hij_date BETWEEN s.suspn_strt_dt AND s.suspn_end_dt
           AND s.suspn_end_dt IS NOT NULL
           AND s.ROWID = (SELECT MAX(m.ROWID)
                            FROM impr_suspns m
                           WHERE m.port_cd = p_port_cd
                             AND m.impr_nbr = p_impr_nbr)
         GROUP BY s.impr_nbr;
        RETURN v_count > 0;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN FALSE;
    END importer_suspended;

    -- =========================================================================
    -- f345 HELPERS
    -- =========================================================================
    PROCEDURE P0_PAGE_PK_CHECK (P_PAGE_PK IN OUT VARCHAR2)
    IS
        v_cnt NUMBER;
    BEGIN
        IF P_PAGE_PK IS NULL THEN
            RETURN;
        END IF;
        P_PAGE_PK := FORMS_APX.ROWID_FROM_URL(P_PAGE_PK);   -- URL-safe ROWID of page 116001 -> ROWID
        SELECT COUNT(*)
          INTO v_cnt
          FROM impr_car_exception e
         WHERE e.ROWID = CHARTOROWID(P0_PAGE_PK_CHECK.P_PAGE_PK);
        IF v_cnt = 0 THEN
            P_PAGE_PK := NULL;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN               -- ORA-01410 invalid ROWID ...: not a key of this page
            P_PAGE_PK := NULL;
    END P0_PAGE_PK_CHECK;

    -- =========================================================================
    -- FORM LEVEL
    -- =========================================================================

    -- Source: FORM.WHEN-NEW-FORM-INSTANCE (last block)
    -- Original Forms code (active part):
    --   :GLOBAL.current_ver := 4;
    --   :EXPTN_START_DT := HIJDATE_DB.CUR_HIJ_DATE ;
    --   POPULATE_DYNAMIC_LISTS;                                     -- body is NULL;
    --   SELECT PORT_CD , PORT_NAME INTO :PORT_CD , :PORT_NAME FROM SD_PORTS
    --    WHERE PORT_CD = :PARAMETER.P_CURR_PORT_CD ;
    --   SET_ITEM_PROPERTY('DCLTN_NBR' / 'DCLTN_DT', ENABLED / UPDATE_ALLOWED / INSERT_ALLOWED, PROPERTY_TRUE);
    -- HIJDATE_DB.CUR_HIJ_DATE -> FORMS_APX.CUR_HIJ_DATE (same DB function, error text raised).
    -- The SELECT has no handler in Forms: an unknown port raises the Oracle error (kept).
    -- APEX-DA: the SET_ITEM_PROPERTY calls = DCLTN_NBR / DCLTN_DT enterable on a new record (item read-only rule).
    -- SUGGESTION: KEY-CLRFRM does not run this block again, so after "clear" in Forms the new record has no
    --             PORT_CD; the page runs it on every new record.
    PROCEDURE WHEN_NEW_FORM_INSTANCE (P_CURR_PORT_CD   IN     NUMBER,
                                      P_PORT_CD        IN OUT NUMBER,
                                      P_PORT_NAME      IN OUT VARCHAR2,
                                      P_EXPTN_START_DT IN OUT VARCHAR2)
    IS
    BEGIN
        P_EXPTN_START_DT := FORMS_APX.HIJRI_TEXT(FORMS_APX.CUR_HIJ_DATE);
        SELECT p.port_cd, p.port_name
          INTO WHEN_NEW_FORM_INSTANCE.P_PORT_CD, WHEN_NEW_FORM_INSTANCE.P_PORT_NAME
          FROM sd_ports p
         WHERE p.port_cd = WHEN_NEW_FORM_INSTANCE.P_CURR_PORT_CD;
    END WHEN_NEW_FORM_INSTANCE;

    -- =========================================================================
    -- BLOCK IMPR_CAR_EXCEPTION
    -- =========================================================================

    -- Source: IMPR_CAR_EXCEPTION.POST-QUERY
    -- Original Forms code (active part):
    --   BEGIN
    --     SELECT ARBC_IMPR_NAME INTO :IMPR_NAME FROM IMPORTERS WHERE PORT_CD=:PARAMETER.P_CURR_PORT_CD
    --        AND IMPR_NBR=:IMPR_NBR AND IMPR_TYPE_CD=4 AND BUS_ID_TYPE_CD IN ( 5,16);
    --     SELECT PORT_NAME INTO :PORT_NAME FROM SD_PORTS WHERE PORT_CD = :PARAMETER.P_CURR_PORT_CD;
    --     IF :DCLTN_TYPE=1 THEN
    --        SELECT DCLTN_NBR,DCLTN_DT INTO :DCLTN_NBR,:DCLTN_DT FROM DECLARATIONS
    --         WHERE DCLTN_ISN = :DCLTN_ISN AND PORT_CD=:PARAMETER.P_CURR_PORT_CD AND IMPR_NBR = :IMPR_NBR ;
    --     ELSIF :DCLTN_TYPE=2 THEN
    --        SELECT STATS_NBR,STATS_DT INTO :DCLTN_NBR,:DCLTN_DT FROM STATS_DCLTNS
    --         WHERE STATS_ISN = :STATS_ISN AND PORT_CD=:PARAMETER.P_CURR_PORT_CD AND IMPR_EXPR_NBR = :IMPR_NBR;
    --     END IF;
    --   EXCEPTION WHEN NO_DATA_FOUND THEN NULL;
    --   END;
    --   SET_ITEM_PROPERTY('STATUS', ENABLED / UPDATE_ALLOWED / INSERT_ALLOWED, PROPERTY_TRUE);   -- APEX-DA (item rule)
    -- SUGGESTION: one handler for all lookups (as Forms): an importer that is no longer type 4 leaves the port
    --             name and the declaration empty; separate blocks per lookup would show them.
    PROCEDURE POST_QUERY (P_IMPR_NBR     IN     NUMBER,
                          P_DCLTN_TYPE   IN     NUMBER,
                          P_DCLTN_ISN    IN     NUMBER,
                          P_STATS_ISN    IN     NUMBER,
                          P_CURR_PORT_CD IN     NUMBER,
                          P_IMPR_NAME    IN OUT VARCHAR2,
                          P_PORT_NAME    IN OUT VARCHAR2,
                          P_DCLTN_NBR    IN OUT VARCHAR2,
                          P_DCLTN_DT     IN OUT VARCHAR2)
    IS
        v_dcltn_dt DATE;
    BEGIN
        SELECT i.arbc_impr_name
          INTO POST_QUERY.P_IMPR_NAME
          FROM importers i
         WHERE i.port_cd = POST_QUERY.P_CURR_PORT_CD
           AND i.impr_nbr = POST_QUERY.P_IMPR_NBR
           AND i.impr_type_cd = c_impr_type_individual
           AND i.bus_id_type_cd IN (5, 16);
        SELECT p.port_name
          INTO POST_QUERY.P_PORT_NAME
          FROM sd_ports p
         WHERE p.port_cd = POST_QUERY.P_CURR_PORT_CD;
        IF P_DCLTN_TYPE = c_dcltn_customs THEN
            SELECT d.dcltn_nbr, d.dcltn_dt
              INTO POST_QUERY.P_DCLTN_NBR, v_dcltn_dt
              FROM declarations d
             WHERE d.dcltn_isn = POST_QUERY.P_DCLTN_ISN
               AND d.port_cd = POST_QUERY.P_CURR_PORT_CD
               AND d.impr_nbr = POST_QUERY.P_IMPR_NBR;
            P_DCLTN_DT := FORMS_APX.HIJRI_TEXT(v_dcltn_dt);
        ELSIF P_DCLTN_TYPE = c_dcltn_stats THEN
            SELECT s.stats_nbr, s.stats_dt
              INTO POST_QUERY.P_DCLTN_NBR, v_dcltn_dt
              FROM stats_dcltns s
             WHERE s.stats_isn = POST_QUERY.P_STATS_ISN
               AND s.port_cd = POST_QUERY.P_CURR_PORT_CD
               AND s.impr_expr_nbr = POST_QUERY.P_IMPR_NBR;
            P_DCLTN_DT := FORMS_APX.HIJRI_TEXT(v_dcltn_dt);
        END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            NULL;
    END POST_QUERY;

    -- Source: IMPR_CAR_EXCEPTION.IMPR_NBR.WHEN-VALIDATE-ITEM
    -- Original Forms code:
    --   BEGIN DECLARE X NUMBER; BEGIN
    --     SELECT COUNT(*) INTO X FROM IMPR_SUSPNS WHERE PORT_CD=:PORT_CD
    --        AND hijdate_db.cur_hij_date BETWEEN SUSPN_STRT_DT AND SUSPN_END_DT AND SUSPN_END_DT IS NOT NULL
    --        AND ROWID=(SELECT MAX(ROWID) FROM IMPR_SUSPNS WHERE PORT_CD=:PORT_CD AND IMPR_NBR=:IMPR_NBR)
    --      GROUP BY IMPR_NBR;
    --   EXCEPTION WHEN NO_DATA_FOUND THEN x:=0;
    --     IF X>0 THEN STR.DISPALERT('هذا المستورد موقوف ','ERROR'); RAISE FORM_TRIGGER_FAILURE; END IF;
    --   END; END;
    -- The IF is inside the NO_DATA_FOUND handler right after x := 0, so this trigger never raises. The same check
    -- is done by KEY-NEXT-ITEM (below), which Forms fires when the user leaves the item with the keyboard.
    -- Decision (page spec §7, inventory §15 #1): the validation runs the KEY-NEXT-ITEM check at CREATE, because in
    -- a browser the DA can be skipped; the DA "IMPR_NBR KEY-NEXT-ITEM" gives the message while typing.
    -- SUGGESTION: Forms could be bypassed with the mouse; the page cannot (stricter by one check, same message).
    FUNCTION IMPR_NBR_VALIDATION (P_PORT_CD  IN NUMBER,
                                  P_IMPR_NBR IN NUMBER) RETURN VARCHAR2
    IS
    BEGIN
        IF P_IMPR_NBR IS NOT NULL AND importer_suspended(P_PORT_CD, P_IMPR_NBR) THEN
            RETURN c_msg_suspended;
        END IF;
        RETURN NULL;
    END IMPR_NBR_VALIDATION;

    -- Source: IMPR_CAR_EXCEPTION.IMPR_NBR.KEY-NEXT-ITEM
    -- Original Forms code:
    --   BEGIN
    --     SELECT ARBC_IMPR_NAME INTO :IMPR_NAME FROM IMPORTERS WHERE PORT_CD=:PORT_CD AND IMPR_NBR=:IMPR_NBR
    --        AND IMPR_TYPE_CD=4 AND BUS_ID_TYPE_CD IN (5,16);
    --     go_item('DCLTN_TYPE');
    --   EXCEPTION WHEN NO_DATA_FOUND THEN :IMPR_NAME := NULL;
    --   END;
    --   <suspension SELECT as in WHEN-VALIDATE-ITEM>
    --   IF X>0 THEN STR.DISPALERT('هذا المستورد موقوف ','ERROR'); RAISE FORM_TRIGGER_FAILURE;
    --   ELSE go_item('DCLTN_TYPE'); END IF;
    --   EXCEPTION WHEN NO_DATA_FOUND THEN NULL;
    -- APEX-DA: go_item('DCLTN_TYPE') = native Set Focus after the FOS action.
    PROCEDURE IMPR_NBR_KEY_NEXT_ITEM (P_PORT_CD   IN     NUMBER,
                                      P_IMPR_NBR  IN     NUMBER,
                                      P_IMPR_NAME IN OUT VARCHAR2)
    IS
    BEGIN
        BEGIN
            SELECT i.arbc_impr_name
              INTO IMPR_NBR_KEY_NEXT_ITEM.P_IMPR_NAME
              FROM importers i
             WHERE i.port_cd = IMPR_NBR_KEY_NEXT_ITEM.P_PORT_CD
               AND i.impr_nbr = IMPR_NBR_KEY_NEXT_ITEM.P_IMPR_NBR
               AND i.impr_type_cd = c_impr_type_individual
               AND i.bus_id_type_cd IN (5, 16);
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                P_IMPR_NAME := NULL;
        END;
        IF importer_suspended(P_PORT_CD, P_IMPR_NBR) THEN
            FORMS_APX.FORM_TRIGGER_FAILURE(c_msg_suspended);
        END IF;
    END IMPR_NBR_KEY_NEXT_ITEM;

    -- Source: IMPR_CAR_EXCEPTION.DCLTN_NBR.POST-CHANGE
    -- Original Forms code (active part):
    --   IF :DCLTN_TYPE=1 THEN
    --      SELECT DCLTN_ISN,DCLTN_DT INTO :DCLTN_ISN,:DCLTN_DT FROM DECLARATIONS
    --       WHERE PORT_CD = :PARAMETER.P_CURR_PORT_CD AND DCLTN_NBR =:DCLTN_NBR AND IMPR_NBR =:IMPR_NBR ;
    --      IF :DCLTN_ISN IS NOT NULL THEN
    --         SELECT NVL (SUM (INV_qty), 0) INTO :NO_OF_CARS FROM DCLTN_items, group_items
    --          WHERE DCLTN_items.FINAL_TARIFF_CD = group_items.hrmnzd_code
    --            AND DCLTN_items.port_cd = :PARAMETER.P_CURR_PORT_CD AND DCLTN_items.DCLTN_ISN = :DCLTN_ISN
    --            AND group_items.grp_code = 76 ;
    --      END IF ;
    --   ELSIF :DCLTN_TYPE=2 THEN
    --      SELECT STATS_ISN,STATS_DT INTO :STATS_ISN ,:DCLTN_DT FROM STATS_DCLTNS
    --       WHERE PORT_CD = :PARAMETER.P_CURR_PORT_CD AND STATS_NBR =:DCLTN_NBR AND IMPR_EXPR_NBR =:IMPR_NBR ;
    --      IF :STATS_ISN IS NOT NULL THEN
    --         SELECT NVL (SUM (qty), 0) INTO :NO_OF_CARS FROM stats_items, group_items
    --          WHERE stats_items.port_cd = :PARAMETER.P_CURR_PORT_CD AND stats_items.stats_isn = :STATS_ISN
    --            AND stats_items.tariff_code = group_items.hrmnzd_code AND group_items.grp_code = 76 ;
    --      END IF;
    --   END IF;
    --   EXCEPTION WHEN NO_DATA_FOUND THEN
    --     STR.DISPALERT('رقم البيان او  تاريخه الذى تم ادخاله غير معرف فى انظمة البيان ','ERROR');
    --     CALL_IMPR_DCLTN_LOV;                -- APEX-DA: the Popup LOV of P1160_DCLTN_NBR (not re-opened)
    --     RAISE FORM_TRIGGER_FAILURE;
    -- SUGGESTION: the declaration is found by number + importer only; two declarations with the same number raise
    --             TOO_MANY_ROWS (unhandled in Forms as well).
    PROCEDURE DCLTN_NBR_POST_CHANGE (P_DCLTN_TYPE   IN     NUMBER,
                                     P_DCLTN_NBR    IN     VARCHAR2,
                                     P_IMPR_NBR     IN     NUMBER,
                                     P_CURR_PORT_CD IN     NUMBER,
                                     P_DCLTN_ISN    IN OUT NUMBER,
                                     P_STATS_ISN    IN OUT NUMBER,
                                     P_DCLTN_DT     IN OUT VARCHAR2,
                                     P_NO_OF_CARS   IN OUT NUMBER)
    IS
        v_dcltn_dt DATE;
    BEGIN
        IF P_DCLTN_TYPE = c_dcltn_customs THEN
            SELECT d.dcltn_isn, d.dcltn_dt
              INTO DCLTN_NBR_POST_CHANGE.P_DCLTN_ISN, v_dcltn_dt
              FROM declarations d
             WHERE d.port_cd = DCLTN_NBR_POST_CHANGE.P_CURR_PORT_CD
               AND d.dcltn_nbr = DCLTN_NBR_POST_CHANGE.P_DCLTN_NBR
               AND d.impr_nbr = DCLTN_NBR_POST_CHANGE.P_IMPR_NBR;
            P_DCLTN_DT := FORMS_APX.HIJRI_TEXT(v_dcltn_dt);
            IF P_DCLTN_ISN IS NOT NULL THEN
                SELECT NVL(SUM(di.inv_qty), 0)
                  INTO DCLTN_NBR_POST_CHANGE.P_NO_OF_CARS
                  FROM dcltn_items di, group_items gi
                 WHERE di.final_tariff_cd = gi.hrmnzd_code
                   AND di.port_cd = DCLTN_NBR_POST_CHANGE.P_CURR_PORT_CD
                   AND di.dcltn_isn = DCLTN_NBR_POST_CHANGE.P_DCLTN_ISN
                   AND gi.grp_code = c_group_cars;
            END IF;
        ELSIF P_DCLTN_TYPE = c_dcltn_stats THEN
            SELECT s.stats_isn, s.stats_dt
              INTO DCLTN_NBR_POST_CHANGE.P_STATS_ISN, v_dcltn_dt
              FROM stats_dcltns s
             WHERE s.port_cd = DCLTN_NBR_POST_CHANGE.P_CURR_PORT_CD
               AND s.stats_nbr = DCLTN_NBR_POST_CHANGE.P_DCLTN_NBR
               AND s.impr_expr_nbr = DCLTN_NBR_POST_CHANGE.P_IMPR_NBR;
            P_DCLTN_DT := FORMS_APX.HIJRI_TEXT(v_dcltn_dt);
            IF P_STATS_ISN IS NOT NULL THEN
                SELECT NVL(SUM(si.qty), 0)
                  INTO DCLTN_NBR_POST_CHANGE.P_NO_OF_CARS
                  FROM stats_items si, group_items gi
                 WHERE si.port_cd = DCLTN_NBR_POST_CHANGE.P_CURR_PORT_CD
                   AND si.stats_isn = DCLTN_NBR_POST_CHANGE.P_STATS_ISN
                   AND si.tariff_code = gi.hrmnzd_code
                   AND gi.grp_code = c_group_cars;
            END IF;
        END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            FORMS_APX.FORM_TRIGGER_FAILURE(c_msg_dcltn_unknown);
    END DCLTN_NBR_POST_CHANGE;

    -- Source: IMPR_CAR_EXCEPTION.AWARD_NBR.WHEN-VALIDATE-ITEM
    -- Original Forms code:
    --   IF :AWARD_NBR <=0 THEN STR.DISPALERT('لا يمكن ادخال رقم قرار اقل من او يساوي صفر','ERROR');
    --      RAISE FORM_TRIGGER_FAILURE; END IF;
    -- AWARD_NBR is a text item (VARCHAR2(20)) compared with a number: Forms converts it, and a text that is not a
    -- number fails with ORA-06502 (FRM-40735). The Oracle error text is returned the same way.
    FUNCTION AWARD_NBR_VALIDATION (P_AWARD_NBR IN VARCHAR2) RETURN VARCHAR2
    IS
    BEGIN
        IF TO_NUMBER(P_AWARD_NBR) <= 0 THEN
            RETURN c_msg_award_nbr;
        END IF;
        RETURN NULL;
    EXCEPTION
        WHEN VALUE_ERROR OR INVALID_NUMBER THEN
            RETURN SQLERRM;
    END AWARD_NBR_VALIDATION;

    -- Source: IMPR_CAR_EXCEPTION.NO_OF_CARS.WHEN-VALIDATE-ITEM
    -- Original Forms code:
    --   IF :NO_OF_CARS<=0 THEN STR.DISPALERT('لا يمكن ادخال عدد سيارات اقل من او يساوي صفر','ERROR');
    --      RAISE FORM_TRIGGER_FAILURE; END IF;
    --   /* IF :NO_OF_CARS > 2 THEN ... */            (commented out in Forms)
    FUNCTION NO_OF_CARS_VALIDATION (P_NO_OF_CARS IN NUMBER) RETURN VARCHAR2
    IS
    BEGIN
        IF P_NO_OF_CARS <= 0 THEN
            RETURN c_msg_no_of_cars;
        END IF;
        RETURN NULL;
    END NO_OF_CARS_VALIDATION;

    -- Source: IMPR_CAR_EXCEPTION.PRE-INSERT
    -- Original Forms code (active part):
    --   IF NVL(GNRL.GET_CUSTOMS_SETTING(:PARAMETER.P_CURR_PORT_CD,'CNTRL_DATABASE',999),0) = 0 THEN
    --      SELECT GNRL.GET_SEQUENCE_VALUE (:PARAMETER.P_CURR_PORT_CD,'IMPR_CAR_EXPTN_SEQ') INTO :EXCPT_ISN FROM DUAL;
    --   ELSIF NVL(GNRL.GET_CUSTOMS_SETTING(:PARAMETER.P_CURR_PORT_CD,'CNTRL_DATABASE',999),0) = 1 THEN
    --      :EXCPT_ISN := GNRL.GET_SEQUENCE_VALUE(:PARAMETER.P_CURR_PORT_CD,'IMPR_CAR_EXPTN_SEQ');
    --   END IF;
    --   SELECT(SYSDATE) INTO V_DT FROM DUAL;  :ENTRY_DT :=V_DT;
    --   IF :DCLTN_TYPE=1 THEN
    --      SELECT DCLTN_ISN INTO :DCLTN_ISN FROM DECLARATIONS WHERE PORT_CD = :PARAMETER.P_CURR_PORT_CD
    --         AND DCLTN_NBR =:DCLTN_NBR AND IMPR_NBR =:IMPR_NBR AND DCLTN_DT=:DCLTN_DT ;
    --      SELECT COUNT(*) INTO v_CNT_DC FROM IMPR_CAR_EXCEPTION WHERE PORT_CD = :PARAMETER.P_CURR_PORT_CD
    --         AND DCLTN_ISN =:DCLTN_ISN ;
    --      IF v_CNT_DC > 0 THEN STR.DISPALERT('لقد تم استثناء هذا البيان من قبل ','ERROR'); RAISE FORM_TRIGGER_FAILURE;
    --   ELSIF :DCLTN_TYPE=2 THEN
    --      SELECT STATS_ISN INTO :STATS_ISN FROM STATS_DCLTNS WHERE PORT_CD = :PARAMETER.P_CURR_PORT_CD
    --         AND STATS_NBR =:DCLTN_NBR AND IMPR_EXPR_NBR =:IMPR_NBR AND STATS_DT = :DCLTN_DT ;
    --      SELECT COUNT(*) INTO v_CNT_ST FROM IMPR_CAR_EXCEPTION WHERE PORT_CD = :PARAMETER.P_CURR_PORT_CD
    --         AND STATS_ISN=:STATS_ISN ;
    --      IF v_CNT_ST > 0 THEN <same alert>; RAISE FORM_TRIGGER_FAILURE;
    --   END IF;
    --   EXCEPTION WHEN NO_DATA_FOUND THEN
    --     STR.DISPALERT('رقم البيان او  تاريخه الذى تم ادخاله غير معرف فى انظمة البيان ','ERROR'); RAISE FORM_TRIGGER_FAILURE;
    --   /* CGUI$GET_UNIQUE_ID_MODIFIED */
    --   IF (name_in('IMPR_CAR_EXCEPTION.EXCPT_ISN') IS NULL) THEN GET_NEXT_IMPR_CAR_EXPTN_CNTRL(:EXCPT_ISN);
    --      (NO_DATA_FOUND -> 'No row in table SYS.DUAL', TOO_MANY_ROWS -> 'More than one row ...')
    -- Order kept: the sequence value is taken before the declaration checks (a refused save uses a number).
    -- DCLTN_DT is the Hijri text of the page; it is converted once before the SELECT (a wrong format raises the
    -- FORMS_APX date-format message, as FRM-50026 would before PRE-INSERT).
    -- SUGGESTION: DCLTN_TYPE 3 (ترانزيت) gets no ISN and no duplicate check (as Forms).
    PROCEDURE PRE_INSERT (P_DCLTN_TYPE   IN     NUMBER,
                          P_DCLTN_NBR    IN     VARCHAR2,
                          P_DCLTN_DT     IN     VARCHAR2,
                          P_IMPR_NBR     IN     NUMBER,
                          P_CURR_PORT_CD IN     NUMBER,
                          P_EXCPT_ISN    IN OUT NUMBER,
                          P_ENTRY_DT     IN OUT VARCHAR2,
                          P_DCLTN_ISN    IN OUT NUMBER,
                          P_STATS_ISN    IN OUT NUMBER)
    IS
        v_dcltn_dt DATE := FORMS_APX.HIJRI_TEXT_TO_DATE(P_DCLTN_DT);
        v_setting  NUMBER;
        v_count    NUMBER;
    BEGIN
        BEGIN
            v_setting := NVL(gnrl.get_customs_setting(P_CURR_PORT_CD, 'CNTRL_DATABASE', 999), 0);   -- NALSALEH CENTRALIZED PROJECT
            IF v_setting = 0 THEN
                SELECT gnrl.get_sequence_value(PRE_INSERT.P_CURR_PORT_CD, c_sequence_name)
                  INTO PRE_INSERT.P_EXCPT_ISN
                  FROM dual;
            ELSIF v_setting = 1 THEN
                P_EXCPT_ISN := gnrl.get_sequence_value(P_CURR_PORT_CD, c_sequence_name);
            END IF;
            P_ENTRY_DT := TO_CHAR(SYSDATE, c_entry_dt_format);
            IF P_DCLTN_TYPE = c_dcltn_customs THEN
                SELECT d.dcltn_isn
                  INTO PRE_INSERT.P_DCLTN_ISN
                  FROM declarations d
                 WHERE d.port_cd = PRE_INSERT.P_CURR_PORT_CD
                   AND d.dcltn_nbr = PRE_INSERT.P_DCLTN_NBR
                   AND d.impr_nbr = PRE_INSERT.P_IMPR_NBR
                   AND d.dcltn_dt = v_dcltn_dt;
                SELECT COUNT(*)
                  INTO v_count
                  FROM impr_car_exception e
                 WHERE e.port_cd = PRE_INSERT.P_CURR_PORT_CD
                   AND e.dcltn_isn = PRE_INSERT.P_DCLTN_ISN;
                IF v_count > 0 THEN
                    FORMS_APX.FORM_TRIGGER_FAILURE(c_msg_dcltn_excepted);
                END IF;
            ELSIF P_DCLTN_TYPE = c_dcltn_stats THEN
                SELECT s.stats_isn
                  INTO PRE_INSERT.P_STATS_ISN
                  FROM stats_dcltns s
                 WHERE s.port_cd = PRE_INSERT.P_CURR_PORT_CD
                   AND s.stats_nbr = PRE_INSERT.P_DCLTN_NBR
                   AND s.impr_expr_nbr = PRE_INSERT.P_IMPR_NBR
                   AND s.stats_dt = v_dcltn_dt;
                SELECT COUNT(*)
                  INTO v_count
                  FROM impr_car_exception e
                 WHERE e.port_cd = PRE_INSERT.P_CURR_PORT_CD
                   AND e.stats_isn = PRE_INSERT.P_STATS_ISN;
                IF v_count > 0 THEN
                    FORMS_APX.FORM_TRIGGER_FAILURE(c_msg_dcltn_excepted);
                END IF;
            END IF;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                FORMS_APX.FORM_TRIGGER_FAILURE(c_msg_dcltn_unknown);
        END;
        -- CGUI$GET_UNIQUE_ID_MODIFIED
        IF P_EXCPT_ISN IS NULL THEN
            BEGIN
                GET_NEXT_IMPR_CAR_EXPTN_CNTRL(P_CURR_PORT_CD, P_EXCPT_ISN);
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    FORMS_APX.FORM_TRIGGER_FAILURE(FORMS_APX.CG_MESSAGE('No row in table <p1>', 'SYS.DUAL'));
                WHEN TOO_MANY_ROWS THEN
                    FORMS_APX.FORM_TRIGGER_FAILURE(FORMS_APX.CG_MESSAGE('More than one row in table <p1>', 'SYS.DUAL'));
            END;
        END IF;
    END PRE_INSERT;

    -- Source: IMPR_CAR_EXCEPTION.PRE-UPDATE
    -- Original Forms code:
    --   SELECT STATUS INTO V_STATUS FROM IMPR_CAR_EXCEPTION WHERE PORT_CD = :PORT_CD AND IMPR_CAR_EXPTN_ISN =:EXCPT_ISN ;
    --   IF V_STATUS = 0 THEN STR.DISPALERT('غير مسموح بتعديل الحالة من غير فعال الى فعال','ERROR');
    --      RAISE FORM_TRIGGER_FAILURE; END IF;
    PROCEDURE PRE_UPDATE (P_PORT_CD   IN NUMBER,
                          P_EXCPT_ISN IN NUMBER)
    IS
        v_status NUMBER;
    BEGIN
        SELECT e.status
          INTO v_status
          FROM impr_car_exception e
         WHERE e.port_cd = PRE_UPDATE.P_PORT_CD
           AND e.impr_car_exptn_isn = PRE_UPDATE.P_EXCPT_ISN;
        IF v_status = c_status_inactive THEN
            FORMS_APX.FORM_TRIGGER_FAILURE(c_msg_status_inactive);
        END IF;
    END PRE_UPDATE;

    -- =========================================================================
    -- PROGRAM UNITS
    -- =========================================================================

    -- Source: PU GET_NEXT_IMPR_CAR_EXPTN_CNTRL
    -- Original Forms code:
    --   CURSOR C IS SELECT GNRL.GET_SEQUENCE_VALUE(:PARAMETER.P_CURR_PORT_CD,'IMPR_CAR_EXPTN_SEQ') FROM SYS.DUAL;
    --   OPEN C; FETCH C INTO P_NEXT_VALUE; IF C%NOTFOUND THEN CLOSE C; RAISE NO_DATA_FOUND; END IF; CLOSE C;
    PROCEDURE GET_NEXT_IMPR_CAR_EXPTN_CNTRL (p_curr_port_cd IN     NUMBER,
                                             p_next_value   IN OUT NUMBER)
    IS
        CURSOR cur_next_value IS
            SELECT gnrl.get_sequence_value(GET_NEXT_IMPR_CAR_EXPTN_CNTRL.p_curr_port_cd, c_sequence_name)
              FROM sys.dual;
    BEGIN
        OPEN cur_next_value;
        FETCH cur_next_value INTO p_next_value;
        IF cur_next_value%NOTFOUND THEN
            CLOSE cur_next_value;
            RAISE NO_DATA_FOUND;
        END IF;
        CLOSE cur_next_value;
    END GET_NEXT_IMPR_CAR_EXPTN_CNTRL;

    -- =========================================================================
    -- VERSION   (SELECT IMPR1160.PKG_VERSION FROM dual;)
    -- =========================================================================
    FUNCTION PKG_VERSION
       RETURN VARCHAR2
    IS
    BEGIN
       RETURN V_INFO;
    END PKG_VERSION;

    -- =========================================================================
    -- UI LOGIC FOR APEX DYNAMIC ACTIONS   (comments only - page spec §10)
    -- =========================================================================
    -- APEX-DA: IMPR_BUT / DCLTN_LOV / PORT_CD2 WHEN-BUTTON-PRESSED (go_item + do_key('List_values')) -> the Popup LOV
    --          buttons of P1160_IMPR_NBR and P1160_DCLTN_NBR; PORT_CD is never enterable (button dropped).
    -- APEX-DA: IMPR_NBR KEY-NEXT-ITEM go_item('DCLTN_TYPE') -> native Set Focus P1160_DCLTN_TYPE.
    -- APEX-DA: CALL_IMPR_DCLTN_LOV GO_ITEM('AWARD_NBR') -> native Set Focus P1160_AWARD_NBR after the declaration.
    -- APEX-DA: PRE-QUERY / POST-QUERY SET_ITEM_PROPERTY('STATUS', ENABLED / UPDATE_ALLOWED) and
    --          MAKE_BLOCK_FULL_OPERATION(TRUE, TRUE, TRUE) -> Form region i:u:d; on a queried record only STATUS is
    --          enterable (read-only condition :P0_PAGE_PK IS NOT NULL on every other item).
    -- APEX-DA: AWARD_DATE KEY-F4 / KEY-LISTVAL (INTRFACE.DISP_DATE_CON 'H' / DISP_CALENDAR) -> f345 Hijri picker
    --          (CSS class hijri-date-default).

END IMPR1160;
/
SHOW ERRORS
