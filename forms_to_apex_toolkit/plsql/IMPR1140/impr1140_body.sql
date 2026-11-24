-- =============================================================================
-- Package body: IMPR1140   (matches impr1140_spec.sql - f345 standard)
-- Source form : IMPR1140.fmb   Target: APEX 21.2 / DB 12.1.0.2   Version: 001
-- Author      : Claude Code     Created: 2026-11-24   (see the spec history)
-- Rules: no Forms built-ins (FORMS_APX instead), no COMMIT / ROLLBACK,
--        parameters named after their binds without I_ / IO_ / O_; page items P<page>_X -> P_X;
--        inside SQL every parameter is qualified with its member name; identifiers <= 30 bytes.
-- Common helpers: FORMS_APX (version 004), called as FORMS_APX.<NAME>.
-- Layout (docs/f345_reference_standard.md §10): PRIVATE HELPERS (top, used by the members below)
-- -> VERSION -> f345 HELPERS -> BLOCK IMPR_RULES -> BLOCK IMPR_RULE_PORTS -> BLOCK IMPR_RULE_TARIFF
-- -> PROGRAM UNITS -> UI LOGIC FOR APEX DYNAMIC ACTIONS (comments only).
-- Status: NOT COMPILED. External DB package without source: LIB_USR.SMS_MESSAGE (call copied unchanged).
-- =============================================================================
SET DEFINE OFF

CREATE OR REPLACE PACKAGE BODY LIB_APX_USR.IMPR1140
AS
    c_sysobj_importers CONSTANT NUMBER := 9;       -- ACTIVITY.ADD_ACTIVITY(9, ...)
    c_subject_rules    CONSTANT NUMBER := 4;       -- ACTIVITY.ADD_ACTIVITY(9, 4, ...)  IMPR_RULES
    c_subject_ports    CONSTANT NUMBER := 5;       -- ACTIVITY.ADD_ACTIVITY(9, 5, ...)  IMPR_RULE_PORTS
    c_subject_tariff   CONSTANT NUMBER := 6;       -- ACTIVITY.ADD_ACTIVITY(9, 6, ...)  IMPR_RULE_TARIFF
    c_activity_insert  CONSTANT NUMBER := 1;
    c_activity_update  CONSTANT NUMBER := 2;
    c_activity_delete  CONSTANT NUMBER := 3;
    c_rule_type_unused CONSTANT NUMBER := 9;       -- RULE_TYPE 9: "هذا النوع غير مستخدم"
    c_rule_type_port   CONSTANT NUMBER := 12;      -- importer data from IMPORTERS of the user's port
    c_rule_type_sms    CONSTANT NUMBER := 14;      -- SMS on insert / update
    c_role_fash        CONSTANT VARCHAR2(30) := 'IMP_EXCEPTION_FASH';

    -- Forms texts (STR.DispAlert)
    c_msg_unused_type   CONSTANT VARCHAR2(200) := 'هذا النوع غير مستخدم';
    c_msg_bad_importer  CONSTANT VARCHAR2(200) :=
        'رقم المستورد المدخل غير صحيح، أدخل الرقم الصحيح أو استخدم القائمة المرفقة';
    c_msg_bad_importer_query CONSTANT VARCHAR2(200) := 'رقم المستورد المدخل غير صحيح';
    c_msg_no_tariff     CONSTANT VARCHAR2(200) := 'رمز بند التعرفة غير موجود ';
    c_msg_tariff_twice  CONSTANT VARCHAR2(200) := 'هذا البند تم ادخاله من قبل لنفس المستورد';
    c_msg_sms           CONSTANT VARCHAR2(500) :=
        'تم منع ميزة الفسح بتعهد للمستورد من إدارة المخاطر - الجمارك السعودية';
    -- Texts the Forms code did not have (Forms built-in errors). TODO: agree the texts (inventory §15 #6, #8).
    c_msg_ports_insert  CONSTANT VARCHAR2(200) := 'لا يمكن إضافة جمارك للاستثناء المطبق على جميع الجمارك';
    c_msg_has_tariff    CONSTANT VARCHAR2(200) := 'لا يمكن حذف الاستثناء لوجود بنود تعريفة مستثناة';
    c_msg_tariff_delete CONSTANT VARCHAR2(200) := 'لا يسمح بحذف بنود التعريفة المستثناة';

    -- =========================================================================
    -- PRIVATE HELPERS
    -- =========================================================================

    -- Forms: IF NOT ACTIVITY.ADD_ACTIVITY(9, <subject>, <type>, <key>) THEN RAISE FORM_TRIGGER_FAILURE;
    -- ACTIVITY.ADD_ACTIVITY (CIC_LIB.pld) passes :PARAMETER.P_Curr_Port_Cd, P_USER_ID, P_WS_ID to
    -- ACTIVITY_DB.ADD_ACTIVITY and on 0 shows V_MSG_TXT (CFG_SYSTEM_ERROR) and returns FALSE (as IMPR1120).
    PROCEDURE add_activity (p_subject       IN NUMBER,
                            p_activity_type IN NUMBER,
                            p_key           IN VARCHAR2,
                            p_curr_port_cd  IN NUMBER,
                            p_user_id       IN VARCHAR2,
                            p_ws_id         IN VARCHAR2)
    IS
        v_msg VARCHAR2(2000);
    BEGIN
        IF activity_db.add_activity(c_sysobj_importers, p_subject, p_activity_type, p_key,
                                    p_curr_port_cd, p_user_id, p_ws_id, v_msg) = 0 THEN
            FORMS_APX.FORM_TRIGGER_FAILURE(v_msg);
        END IF;
    END add_activity;

    -- Mobile number of the importer: IMPORTER_BASIC_DATA by HQ_IMPR_NBR, else IMPORTERS of the port.
    -- Every error is swallowed as in Forms (EXCEPTION WHEN OTHERS THEN NULL), so the result can be NULL.
    -- Shared by IMPR_RULES.POST-INSERT and POST-UPDATE (same code in both triggers).
    FUNCTION importer_mobile (p_hq_impr_nbr  IN NUMBER,
                              p_curr_port_cd IN NUMBER) RETURN NUMBER
    IS
        v_mobile_no NUMBER;
    BEGIN
        BEGIN
            SELECT DISTINCT b.mobile_no
              INTO v_mobile_no
              FROM importer_basic_data b
             WHERE b.hq_impr_nbr = p_hq_impr_nbr
               AND b.mobile_no IS NOT NULL;
            -- Forms: IF V_MOBILE_NO IS NULL (never true after a successful fetch: the second
            -- lookup runs only through the exception path, kept literally below)
            IF v_mobile_no IS NULL THEN
                SELECT DISTINCT i.mobile_no
                  INTO v_mobile_no
                  FROM importers i
                 WHERE i.port_cd = p_curr_port_cd
                   AND i.hq_impr_nbr = p_hq_impr_nbr
                   AND i.mobile_no IS NOT NULL;
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                NULL;
        END;
        RETURN v_mobile_no;
    END importer_mobile;

    -- The SMS of IMPR_RULES.POST-INSERT / POST-UPDATE (rule type 14, active rule, mobile found).
    -- TODO: MISSING SOURCE LIB_USR.SMS_MESSAGE.SEND_SMS_MESSAGE (signature copied from the Forms call).
    PROCEDURE send_rule_sms (p_rule_isn     IN NUMBER,
                             p_hq_impr_nbr  IN NUMBER,
                             p_rule_type    IN NUMBER,
                             p_rec_status   IN NUMBER,
                             p_curr_port_cd IN NUMBER)
    IS
        v_mobile_no NUMBER := importer_mobile(p_hq_impr_nbr, p_curr_port_cd);
    BEGIN
        IF v_mobile_no IS NOT NULL AND p_rule_type = c_rule_type_sms AND p_rec_status = 1 THEN
            lib_usr.sms_message.send_sms_message(9, 6, 1, p_curr_port_cd, NULL, v_mobile_no, c_msg_sms,
                                                 p_rule_isn || '|' || p_hq_impr_nbr);
        END IF;
    END send_rule_sms;

    -- Importer data by unified number: IMPORTERS of the port for rule type 12, else SINGLE_IMPORTERS.
    -- Raises NO_DATA_FOUND / TOO_MANY_ROWS like the Forms SELECT INTO.
    PROCEDURE read_importer (p_hq_impr_nbr    IN     NUMBER,
                             p_rule_type      IN     NUMBER,
                             p_curr_port_cd   IN     NUMBER,
                             p_bus_id            OUT VARCHAR2,
                             p_bus_id_brnch      OUT VARCHAR2,
                             p_bus_id_type_cd    OUT NUMBER,
                             p_arbc_impr_name    OUT VARCHAR2)
    IS
    BEGIN
        IF p_rule_type = c_rule_type_port THEN
            SELECT i.bus_id, i.bus_id_brnch, i.bus_id_type_cd, i.arbc_impr_name
              INTO p_bus_id, p_bus_id_brnch, p_bus_id_type_cd, p_arbc_impr_name
              FROM importers i
             WHERE i.port_cd = p_curr_port_cd          -- NALSALEH CENTRALIZED PROJECT
               AND i.hq_impr_nbr = p_hq_impr_nbr
               AND ROWNUM = 1;
        ELSE
            SELECT s.bus_id, s.bus_id_brnch, s.bus_id_type_cd, s.arbc_impr_name
              INTO p_bus_id, p_bus_id_brnch, p_bus_id_type_cd, p_arbc_impr_name
              FROM single_importers s
             WHERE s.hq_impr_nbr = p_hq_impr_nbr;
        END IF;
    END read_importer;

    -- Role check of IMPR_RULES.PRE-INSERT / PRE-UPDATE for rule types 13 and 14.
    PROCEDURE check_rule_type_role (p_rule_type    IN NUMBER,
                                    p_curr_port_cd IN NUMBER,
                                    p_user_id      IN VARCHAR2)
    IS
    BEGIN
        IF p_rule_type IN (13, 14) THEN
            IF NOT CHECK_FASH_ROLE_ID(p_curr_port_cd, p_user_id) THEN
                FORMS_APX.FORM_TRIGGER_FAILURE(' لا يوجد صلاحيات كافية للمستخدم' || p_user_id
                                               || 'لإنشاء هذا النوع من الاستثناءات ');
            END IF;
        END IF;
    END check_rule_type_role;

    -- =========================================================================
    -- PACKAGE VERSION
    -- =========================================================================
    -- SELECT IMPR1140.PKG_VERSION FROM dual;  -> package name, version, modified date / by
    FUNCTION PKG_VERSION
       RETURN VARCHAR2
    IS
    BEGIN
       RETURN V_INFO;
    END PKG_VERSION;

    -- =========================================================================
    -- f345 HELPERS
    -- =========================================================================

    -- P0_PAGE_PK = ROWID of the IMPR_RULES row. The block is not limited to a port.
    PROCEDURE P0_PAGE_PK_CHECK (P_PAGE_PK IN OUT VARCHAR2)
    IS
        v_cnt NUMBER;
    BEGIN
        IF P_PAGE_PK IS NULL THEN
            RETURN;
        END IF;
        P_PAGE_PK := FORMS_APX.ROWID_FROM_URL(P_PAGE_PK);   -- URL-safe ROWID of page 114001 -> ROWID
        SELECT COUNT(*)
          INTO v_cnt
          FROM impr_rules r
         WHERE r.ROWID = CHARTOROWID(P0_PAGE_PK_CHECK.P_PAGE_PK);
        IF v_cnt = 0 THEN
            P_PAGE_PK := NULL;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN               -- ORA-01410 invalid ROWID ...: not a key of this page
            P_PAGE_PK := NULL;
    END P0_PAGE_PK_CHECK;

    -- =========================================================================
    -- BLOCK IMPR_RULES  (master)
    -- =========================================================================

    -- Source: IMPR_RULES.POST-QUERY
    -- Original Forms code (active part):
    --   IF :hq_impr_nbr IS NOT NULL THEN
    --      IF :impr_rules.rule_type = 12 THEN
    --         SELECT arbc_impr_name INTO :l_si_arbc_impr_name FROM importers
    --          WHERE PORT_CD = :PARAMETER.P_CURR_PORT_CD AND hq_impr_nbr = :hq_impr_nbr AND ROWNUM = 1;
    --      ELSE
    --         SELECT arbc_impr_name INTO :l_si_arbc_impr_name FROM single_importers
    --          WHERE hq_impr_nbr = :hq_impr_nbr;
    --      END IF;
    --      SELECT bus_id_type_name INTO :bus_id_type_name FROM bus_id_types WHERE bus_id_type_cd = :bus_id_type_cd;
    --   END IF;
    --   EXCEPTION WHEN OTHERS THEN str.dispalert('رقم المستورد المدخل غير صحيح', 'ERROR');
    --   /* CGFK$QRY_LOOKUP_DATA */ IF BUS_ID_TYPE_CD IS NOT NULL THEN CGFK$QRY_IMPR_RULES_IR_BIT_FK(...);
    --      NO_DATA_FOUND -> Des$Form_errors.PUSH('This <p1> does not exist', 'Bus Id Type Name');
    --   /* CGFK$RESET_BLOCK_WHERE_CLAUSE */ -> not needed (search page SQL with binds)
    -- The alert and the PUSH show a message and the query goes on: FORMS_APX.MESSAGE (no failure).
    PROCEDURE POST_QUERY (P_HQ_IMPR_NBR         IN     NUMBER,
                          P_RULE_TYPE           IN     NUMBER,
                          P_BUS_ID_TYPE_CD      IN     NUMBER,
                          P_CURR_PORT_CD        IN     NUMBER,
                          P_L_SI_ARBC_IMPR_NAME IN OUT VARCHAR2,
                          P_BUS_ID_TYPE_NAME    IN OUT VARCHAR2)
    IS
        v_bus_id         VARCHAR2(30);
        v_bus_id_brnch   VARCHAR2(30);
        v_bus_id_type_cd NUMBER;
    BEGIN
        BEGIN
            IF P_HQ_IMPR_NBR IS NOT NULL THEN
                read_importer(P_HQ_IMPR_NBR, P_RULE_TYPE, P_CURR_PORT_CD,
                              v_bus_id, v_bus_id_brnch, v_bus_id_type_cd, P_L_SI_ARBC_IMPR_NAME);
                SELECT t.bus_id_type_name
                  INTO POST_QUERY.P_BUS_ID_TYPE_NAME
                  FROM bus_id_types t
                 WHERE t.bus_id_type_cd = POST_QUERY.P_BUS_ID_TYPE_CD;
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                FORMS_APX.MESSAGE(c_msg_bad_importer_query);
        END;
        IF P_BUS_ID_TYPE_CD IS NOT NULL THEN
            BEGIN
                CGFK$QRY_IMPR_RULES_IR_BIT_FK(P_BUS_ID_TYPE_NAME, P_BUS_ID_TYPE_CD);
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    FORMS_APX.MESSAGE(FORMS_APX.CG_MESSAGE('This <p1> does not exist', 'Bus Id Type Name'));
            END;
        END IF;
    END POST_QUERY;

    -- Source: IMPR_RULES.RULE_TYPE.WHEN-LIST-CHANGED / WHEN-VALIDATE-ITEM
    -- Original Forms code:
    --   IF :IMPR_RULES.RULE_TYPE = 9 THEN STR.DISPALERT('هذا النوع غير مستخدم','ERROR'); RAISE FORM_TRIGGER_FAILURE; END IF;
    FUNCTION RULE_TYPE_VALIDATION (P_RULE_TYPE IN NUMBER) RETURN VARCHAR2
    IS
    BEGIN
        IF P_RULE_TYPE = c_rule_type_unused THEN
            RETURN c_msg_unused_type;
        END IF;
        RETURN NULL;
    END RULE_TYPE_VALIDATION;

    -- Source: IMPR_RULES.HQ_IMPR_NBR.WHEN-VALIDATE-ITEM (check part)
    -- Original Forms code: the SELECT INTO of HQ_IMPR_NBR_VALIDATE_ITEM;
    --   EXCEPTION WHEN OTHERS THEN str.dispalert('رقم المستورد المدخل غير صحيح، ...', 'ERROR'); RAISE form_trigger_failure;
    -- Also fails when the business id type name is missing (same exception handler in Forms).
    FUNCTION HQ_IMPR_NBR_VALIDATION (P_HQ_IMPR_NBR  IN NUMBER,
                                     P_RULE_TYPE    IN NUMBER,
                                     P_CURR_PORT_CD IN NUMBER) RETURN VARCHAR2
    IS
        v_bus_id         VARCHAR2(30);
        v_bus_id_brnch   VARCHAR2(30);
        v_bus_id_type_cd NUMBER;
        v_name           VARCHAR2(200);
        v_type_name      VARCHAR2(100);
    BEGIN
        IF P_HQ_IMPR_NBR IS NULL THEN
            RETURN NULL;
        END IF;
        read_importer(P_HQ_IMPR_NBR, P_RULE_TYPE, P_CURR_PORT_CD, v_bus_id, v_bus_id_brnch, v_bus_id_type_cd, v_name);
        SELECT t.bus_id_type_name
          INTO v_type_name
          FROM bus_id_types t
         WHERE t.bus_id_type_cd = v_bus_id_type_cd;
        RETURN NULL;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN c_msg_bad_importer;
    END HQ_IMPR_NBR_VALIDATION;

    -- Source: IMPR_RULES.HQ_IMPR_NBR.WHEN-VALIDATE-ITEM (full name HQ_IMPR_NBR_WHEN_VALIDATE_ITEM)
    -- Original Forms code:
    --   IF :hq_impr_nbr IS NOT NULL THEN
    --      IF :impr_rules.rule_type = 12 THEN
    --         SELECT bus_id, bus_id_brnch, bus_id_type_cd, arbc_impr_name
    --           INTO :bus_id, :bus_id_brnch, :bus_id_type_cd, :l_si_arbc_impr_name
    --           FROM importers WHERE PORT_CD = :PARAMETER.P_CURR_PORT_CD AND hq_impr_nbr = :hq_impr_nbr AND ROWNUM = 1;
    --      ELSE ... FROM single_importers WHERE hq_impr_nbr = :hq_impr_nbr;
    --      END IF;
    --      SELECT bus_id_type_name INTO :bus_id_type_name FROM bus_id_types WHERE bus_id_type_cd = :bus_id_type_cd;
    --   END IF;
    --   EXCEPTION WHEN OTHERS THEN str.dispalert('رقم المستورد المدخل غير صحيح، ...','ERROR'); RAISE form_trigger_failure;
    -- An empty number keeps the items unchanged (as in Forms).
    PROCEDURE HQ_IMPR_NBR_VALIDATE_ITEM (P_HQ_IMPR_NBR         IN     NUMBER,
                                         P_RULE_TYPE           IN     NUMBER,
                                         P_CURR_PORT_CD        IN     NUMBER,
                                         P_BUS_ID              IN OUT VARCHAR2,
                                         P_BUS_ID_BRNCH        IN OUT VARCHAR2,
                                         P_BUS_ID_TYPE_CD      IN OUT NUMBER,
                                         P_L_SI_ARBC_IMPR_NAME IN OUT VARCHAR2,
                                         P_BUS_ID_TYPE_NAME    IN OUT VARCHAR2)
    IS
    BEGIN
        FORMS_APX.CHECK_ERROR(HQ_IMPR_NBR_VALIDATION(P_HQ_IMPR_NBR, P_RULE_TYPE, P_CURR_PORT_CD));
        IF P_HQ_IMPR_NBR IS NOT NULL THEN
            read_importer(P_HQ_IMPR_NBR, P_RULE_TYPE, P_CURR_PORT_CD,
                          P_BUS_ID, P_BUS_ID_BRNCH, P_BUS_ID_TYPE_CD, P_L_SI_ARBC_IMPR_NAME);
            SELECT t.bus_id_type_name
              INTO HQ_IMPR_NBR_VALIDATE_ITEM.P_BUS_ID_TYPE_NAME
              FROM bus_id_types t
             WHERE t.bus_id_type_cd = HQ_IMPR_NBR_VALIDATE_ITEM.P_BUS_ID_TYPE_CD;
        END IF;
    END HQ_IMPR_NBR_VALIDATE_ITEM;

    -- Source: IMPR_RULES.KEY-DELREC
    -- Original Forms code:
    --   SELECT COUNT INTO V_COUNT FROM IMPR_RULE_PORTS
    --    WHERE PORT_CD = :PARAMETER.P_CURR_PORT_CD AND RULE_ISN = :IMPR_RULES.RULE_ISN;
    --   IF V_COUNT > 0 THEN STR.DISPARBMSG(1,270,'ERROR'); RAISE form_trigger_failure; END IF;
    --   TMPLT.KEY_DELETE_RECORD;                       -- confirm + Delete_record + COMMIT
    --   /* CGRI$CHECK_ON_DELETE */ CGRI$CHK_IMPR_RULES(TRUE, :IMPR_RULES.RULE_ISN);
    --   /* CGGN$KEY_DELREC */ delete_record;
    -- APEX: the confirm is the page 0 DELETE confirm; the delete and the commit are "Process form - DELETE"
    -- and APEX. Both checks run before the delete (the Forms RI check ran after the COMMIT of
    -- TMPLT.KEY_DELETE_RECORD; inventory §15 #5). Added: relation CGFK$IRT_IR_FK is Non-Isolated, so Forms
    -- refuses the delete while tariff rows exist (inventory §15 #8).
    PROCEDURE KEY_DELREC (P_RULE_ISN     IN NUMBER,
                          P_CURR_PORT_CD IN NUMBER)
    IS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*)
          INTO v_count
          FROM impr_rule_ports p
         WHERE p.port_cd  = KEY_DELREC.P_CURR_PORT_CD   -- NALSALEH CENTRALIZED PROJECT
           AND p.rule_isn = KEY_DELREC.P_RULE_ISN;
        IF v_count > 0 THEN
            FORMS_APX.FORM_TRIGGER_FAILURE(FORMS_APX.ARABIC_MESSAGE(1, 270));
        END IF;
        CGRI$CHK_IMPR_RULES(P_RULE_ISN);
        SELECT COUNT(*)
          INTO v_count
          FROM impr_rule_tariff t
         WHERE t.rule_isn = KEY_DELREC.P_RULE_ISN;
        IF v_count > 0 THEN
            FORMS_APX.FORM_TRIGGER_FAILURE(c_msg_has_tariff);
        END IF;
    END KEY_DELREC;

    -- Source: IMPR_RULES.PRE-INSERT
    -- Original Forms code (active part; the "AAA" duplicate check and the branch check are commented out):
    --   SELECT NVL(MAX(RULE_ISN),0) + 1 INTO :IMPR_RULES.RULE_ISN FROM IMPR_RULES;
    --   IF NOT ACTIVITY.ADD_ACTIVITY(9, 4, 1, :IMPR_RULES.RULE_ISN) THEN RAISE FORM_TRIGGER_FAILURE; END IF;
    --   IF :IMPR_RULES.RULE_TYPE IN (13,14) THEN
    --     IF CHECK_FASH_ROLE_ID(:PARAMETER.P_CURR_PORT_CD,:PARAMETER.P_USER_ID) = FALSE THEN
    --       STR.DISPALERT(' لا يوجد صلاحيات كافية للمستخدم'|| :PARAMETER.P_USER_ID ||'لإنشاء هذا النوع من الاستثناءات ','ERROR');
    --       RAISE FORM_TRIGGER_FAILURE;
    -- SUGGESTION: MAX + 1 over the whole table is not safe for concurrent saves; a sequence needs a
    --             migration script and a decision (inventory §15 #3).
    PROCEDURE PRE_INSERT (P_RULE_ISN       IN OUT NUMBER,
                          P_RULE_TYPE      IN     NUMBER,
                          P_CURR_PORT_CD   IN     NUMBER,
                          SSO_APP_USER     IN     VARCHAR2,
                          P_GLOBAL_V_WS_ID IN     VARCHAR2)
    IS
    BEGIN
        SELECT NVL(MAX(r.rule_isn), 0) + 1
          INTO PRE_INSERT.P_RULE_ISN
          FROM impr_rules r;
        add_activity(c_subject_rules, c_activity_insert, P_RULE_ISN, P_CURR_PORT_CD, SSO_APP_USER, P_GLOBAL_V_WS_ID);
        check_rule_type_role(P_RULE_TYPE, P_CURR_PORT_CD, SSO_APP_USER);
    END PRE_INSERT;

    -- Source: IMPR_RULES.POST-INSERT
    -- Original Forms code: mobile from IMPORTER_BASIC_DATA (else IMPORTERS of the port), errors swallowed;
    --   IF V_MOBILE_NO IS NOT NULL AND :IMPR_RULES.RULE_TYPE = 14 AND :IMPR_RULES.REC_STATUS = 1 THEN
    --     lib_usr.sms_message.send_sms_message(9, 6, 1, :PARAMETER.P_CURR_PORT_CD, NULL, V_MOBILE_NO, v_msg,
    --                                          :IMPR_RULES.RULE_ISN || '|' || :IMPR_RULES.HQ_IMPR_NBR);
    -- The SMS is sent before APEX commits, as in Forms (POST-INSERT runs before the COMMIT; inventory §15 #2).
    PROCEDURE POST_INSERT (P_RULE_ISN     IN NUMBER,
                           P_HQ_IMPR_NBR  IN NUMBER,
                           P_RULE_TYPE    IN NUMBER,
                           P_REC_STATUS   IN NUMBER,
                           P_CURR_PORT_CD IN NUMBER)
    IS
    BEGIN
        send_rule_sms(P_RULE_ISN, P_HQ_IMPR_NBR, P_RULE_TYPE, P_REC_STATUS, P_CURR_PORT_CD);
    END POST_INSERT;

    -- Source: IMPR_RULES.PRE-UPDATE
    -- Original Forms code (active part): the role check of PRE-INSERT for rule types 13 / 14.
    PROCEDURE PRE_UPDATE (P_RULE_TYPE    IN NUMBER,
                          P_CURR_PORT_CD IN NUMBER,
                          SSO_APP_USER   IN VARCHAR2)
    IS
    BEGIN
        check_rule_type_role(P_RULE_TYPE, P_CURR_PORT_CD, SSO_APP_USER);
    END PRE_UPDATE;

    -- Source: IMPR_RULES.POST-UPDATE
    -- Original Forms code:
    --   IF NOT ACTIVITY.ADD_ACTIVITY(9, 4, 2, :IMPR_RULES.RULE_ISN) THEN RAISE FORM_TRIGGER_FAILURE; END IF;
    --   ... the SMS code of POST-INSERT (sent again on every update of an active type-14 rule).
    PROCEDURE POST_UPDATE (P_RULE_ISN       IN NUMBER,
                           P_HQ_IMPR_NBR    IN NUMBER,
                           P_RULE_TYPE      IN NUMBER,
                           P_REC_STATUS     IN NUMBER,
                           P_CURR_PORT_CD   IN NUMBER,
                           SSO_APP_USER     IN VARCHAR2,
                           P_GLOBAL_V_WS_ID IN VARCHAR2)
    IS
    BEGIN
        add_activity(c_subject_rules, c_activity_update, P_RULE_ISN, P_CURR_PORT_CD, SSO_APP_USER, P_GLOBAL_V_WS_ID);
        send_rule_sms(P_RULE_ISN, P_HQ_IMPR_NBR, P_RULE_TYPE, P_REC_STATUS, P_CURR_PORT_CD);
    END POST_UPDATE;

    -- Source: IMPR_RULES.PRE-DELETE
    -- Original Forms code:
    --   IF NOT ACTIVITY.ADD_ACTIVITY(9, 4, 3, :IMPR_RULES.RULE_ISN) THEN RAISE FORM_TRIGGER_FAILURE; END IF;
    PROCEDURE PRE_DELETE (P_RULE_ISN       IN NUMBER,
                          P_CURR_PORT_CD   IN NUMBER,
                          SSO_APP_USER     IN VARCHAR2,
                          P_GLOBAL_V_WS_ID IN VARCHAR2)
    IS
    BEGIN
        add_activity(c_subject_rules, c_activity_delete, P_RULE_ISN, P_CURR_PORT_CD, SSO_APP_USER, P_GLOBAL_V_WS_ID);
    END PRE_DELETE;

    -- =========================================================================
    -- BLOCK IMPR_RULE_PORTS  (detail)
    -- =========================================================================

    -- Source: IMPR_RULE_PORTS.POST-QUERY / PRE-RECORD / WHEN-NEW-RECORD-INSTANCE
    -- Original Forms code (same in the three triggers):
    --   IF :IMPR_RULES.ALL_BRNCH_FLAG = 1 THEN SET_BLOCK_PROPERTY('IMPR_RULE_PORTS', INSERT_ALLOWED, PROPERTY_FALSE);
    --   ELSE SET_BLOCK_PROPERTY('IMPR_RULE_PORTS', INSERT_ALLOWED, PROPERTY_TRUE); END IF;
    FUNCTION IMPR_RULE_PORTS_INSERT_ALLOWED (P_ALL_BRNCH_FLAG IN NUMBER) RETURN BOOLEAN
    IS
    BEGIN
        RETURN NVL(P_ALL_BRNCH_FLAG, 0) <> 1;   -- NULL flag: insert allowed (Forms: NULL = 1 is not TRUE)
    END IMPR_RULE_PORTS_INSERT_ALLOWED;

    -- Source: IMPR_RULE_PORTS.PORT_CD.WHEN-VALIDATE-ITEM (full name IMPR_RULE_PORTS_PORT_CD_VALIDATION)
    -- Original Forms code (CGFK$VALDIDATE_FK_OVF):
    --   IF PORT_CD IS NOT NULL THEN CGFK$CHK_IMPR_RULE_PORTS_IRP_S(:PORT_NAME, :PORT_CD);
    --   EXCEPTION WHEN NO_DATA_FOUND THEN Des$Form_errors.PUSH(MSGGETTEXT(13, 'This <p1> does not exist', 'رمز الجمرك'));
    --             Des$Form_errors.RAISE_FAILURE;
    FUNCTION PORT_CD_VALIDATION (PORT_CD IN NUMBER) RETURN VARCHAR2
    IS
        v_port_name VARCHAR2(100);
    BEGIN
        IF PORT_CD IS NOT NULL THEN
            CGFK$CHK_IMPR_RULE_PORTS_IRP_S(v_port_name, PORT_CD);
        END IF;
        RETURN NULL;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN FORMS_APX.CG_MESSAGE('This <p1> does not exist', 'رمز الجمرك');
    END PORT_CD_VALIDATION;

    -- Source: IMPR_RULE_PORTS.PORT_CD.WHEN-VALIDATE-ITEM (derived PORT_NAME)
    PROCEDURE PORT_CD_WHEN_VALIDATE_ITEM (PORT_CD   IN     NUMBER,
                                          PORT_NAME IN OUT VARCHAR2)
    IS
    BEGIN
        FORMS_APX.CHECK_ERROR(PORT_CD_VALIDATION(PORT_CD));
        IF PORT_CD IS NOT NULL THEN
            CGFK$CHK_IMPR_RULE_PORTS_IRP_S(PORT_NAME, PORT_CD);
        END IF;
    END PORT_CD_WHEN_VALIDATE_ITEM;

    -- Source: IMPR_RULE_PORTS.PRE-INSERT
    -- Original Forms code:
    --   IF NOT ACTIVITY.ADD_ACTIVITY(9, 5, 1, :IMPR_RULE_PORTS.RULE_ISN||'!'||:IMPR_RULE_PORTS.PORT_CD) THEN
    --     RAISE FORM_TRIGGER_FAILURE;
    -- Added: the insert-allowed rule of the block (Forms refuses the new row itself, FRM-40602).
    PROCEDURE IMPR_RULE_PORTS_PRE_INSERT (RULE_ISN         IN NUMBER,
                                          PORT_CD          IN NUMBER,
                                          P_ALL_BRNCH_FLAG IN NUMBER,
                                          P_CURR_PORT_CD   IN NUMBER,
                                          SSO_APP_USER     IN VARCHAR2,
                                          P_GLOBAL_V_WS_ID IN VARCHAR2)
    IS
    BEGIN
        IF NOT IMPR_RULE_PORTS_INSERT_ALLOWED(P_ALL_BRNCH_FLAG) THEN
            FORMS_APX.FORM_TRIGGER_FAILURE(c_msg_ports_insert);
        END IF;
        add_activity(c_subject_ports, c_activity_insert, RULE_ISN || '!' || PORT_CD,
                     P_CURR_PORT_CD, SSO_APP_USER, P_GLOBAL_V_WS_ID);
    END IMPR_RULE_PORTS_PRE_INSERT;

    -- Source: IMPR_RULE_PORTS.PRE-UPDATE
    -- Original Forms code: IF NOT ACTIVITY.ADD_ACTIVITY(9, 5, 2, RULE_ISN||'!'||PORT_CD) THEN RAISE FORM_TRIGGER_FAILURE;
    PROCEDURE IMPR_RULE_PORTS_PRE_UPDATE (RULE_ISN         IN NUMBER,
                                          PORT_CD          IN NUMBER,
                                          P_CURR_PORT_CD   IN NUMBER,
                                          SSO_APP_USER     IN VARCHAR2,
                                          P_GLOBAL_V_WS_ID IN VARCHAR2)
    IS
    BEGIN
        add_activity(c_subject_ports, c_activity_update, RULE_ISN || '!' || PORT_CD,
                     P_CURR_PORT_CD, SSO_APP_USER, P_GLOBAL_V_WS_ID);
    END IMPR_RULE_PORTS_PRE_UPDATE;

    -- Source: IMPR_RULE_PORTS.PRE-DELETE
    -- Original Forms code: IF NOT ACTIVITY.ADD_ACTIVITY(9, 5, 3, RULE_ISN||'!'||PORT_CD) THEN RAISE FORM_TRIGGER_FAILURE;
    PROCEDURE IMPR_RULE_PORTS_PRE_DELETE (RULE_ISN         IN NUMBER,
                                          PORT_CD          IN NUMBER,
                                          P_CURR_PORT_CD   IN NUMBER,
                                          SSO_APP_USER     IN VARCHAR2,
                                          P_GLOBAL_V_WS_ID IN VARCHAR2)
    IS
    BEGIN
        add_activity(c_subject_ports, c_activity_delete, RULE_ISN || '!' || PORT_CD,
                     P_CURR_PORT_CD, SSO_APP_USER, P_GLOBAL_V_WS_ID);
    END IMPR_RULE_PORTS_PRE_DELETE;

    -- Source: block IMPR_RULE_PORTS row DML (Forms: PRE-<op> trigger, then INSERT / UPDATE / DELETE of the
    -- base table). PORT_CD is not updatable (Update Allowed = false), so the UPDATE only writes REC_STATUS.
    PROCEDURE IMPR_RULE_PORTS_SAVE_ROW (APEX$ROW_STATUS  IN     VARCHAR2,
                                        ROW_ID           IN OUT VARCHAR2,
                                        RULE_ISN         IN     NUMBER,
                                        PORT_CD          IN     NUMBER,
                                        REC_STATUS       IN     NUMBER,
                                        P_ALL_BRNCH_FLAG IN     NUMBER,
                                        P_CURR_PORT_CD   IN     NUMBER,
                                        SSO_APP_USER     IN     VARCHAR2,
                                        P_GLOBAL_V_WS_ID IN     VARCHAR2)
    IS
        v_rowid ROWID;
    BEGIN
        IF APEX$ROW_STATUS = 'C' THEN
            IMPR_RULE_PORTS_PRE_INSERT(RULE_ISN, PORT_CD, P_ALL_BRNCH_FLAG, P_CURR_PORT_CD, SSO_APP_USER, P_GLOBAL_V_WS_ID);
            INSERT INTO impr_rule_ports (rule_isn, port_cd, rec_status)
            VALUES (IMPR_RULE_PORTS_SAVE_ROW.RULE_ISN, IMPR_RULE_PORTS_SAVE_ROW.PORT_CD, IMPR_RULE_PORTS_SAVE_ROW.REC_STATUS)
            RETURNING ROWID INTO v_rowid;
            ROW_ID := ROWIDTOCHAR(v_rowid);
        ELSIF APEX$ROW_STATUS = 'U' THEN
            IMPR_RULE_PORTS_PRE_UPDATE(RULE_ISN, PORT_CD, P_CURR_PORT_CD, SSO_APP_USER, P_GLOBAL_V_WS_ID);
            UPDATE impr_rule_ports p
               SET p.rec_status = IMPR_RULE_PORTS_SAVE_ROW.REC_STATUS
             WHERE p.ROWID = CHARTOROWID(IMPR_RULE_PORTS_SAVE_ROW.ROW_ID);
        ELSIF APEX$ROW_STATUS = 'D' THEN
            IMPR_RULE_PORTS_PRE_DELETE(RULE_ISN, PORT_CD, P_CURR_PORT_CD, SSO_APP_USER, P_GLOBAL_V_WS_ID);
            DELETE FROM impr_rule_ports p
             WHERE p.ROWID = CHARTOROWID(IMPR_RULE_PORTS_SAVE_ROW.ROW_ID);
        END IF;
    END IMPR_RULE_PORTS_SAVE_ROW;

    -- =========================================================================
    -- BLOCK IMPR_RULE_TARIFF  (detail)
    -- =========================================================================

    -- Source: IMPR_RULE_TARIFF.POST-QUERY
    -- Original Forms code:
    --   SELECT TRF_INTL_UNIT INTO V_INTL_UNIT FROM TARIFF_DETAILS
    --    WHERE HRMNZD_CODE = :HRMNZD_CODE AND EFF_DATE = (SELECT MAX(EFF_DATE) FROM TARIFF_DETAILS WHERE HRMNZD_CODE = :HRMNZD_CODE);
    --   SELECT IMSR_ARBC_NAME INTO :INTL_UNIT FROM INTL_MSR_UNITS WHERE INTL_MSR_UNIT = V_INTL_UNIT AND IMSR_STATUS = 1;
    --   EXCEPTION WHEN NO_DATA_FOUND THEN NULL;
    -- Public so the grid SQL can call it (one row lookup per row as in Forms; a join would need the
    -- MAX(EFF_DATE) sub-query anyway).
    FUNCTION IMPR_RULE_TARIFF_POST_QUERY (HRMNZD_CODE IN VARCHAR2) RETURN VARCHAR2
    IS
        v_intl_unit NUMBER;
        v_name      VARCHAR2(200);
    BEGIN
        SELECT d.trf_intl_unit
          INTO v_intl_unit
          FROM tariff_details d
         WHERE d.hrmnzd_code = IMPR_RULE_TARIFF_POST_QUERY.HRMNZD_CODE
           AND d.eff_date = (SELECT MAX(x.eff_date)
                               FROM tariff_details x
                              WHERE x.hrmnzd_code = IMPR_RULE_TARIFF_POST_QUERY.HRMNZD_CODE);
        SELECT u.imsr_arbc_name
          INTO v_name
          FROM intl_msr_units u
         WHERE u.intl_msr_unit = v_intl_unit
           AND u.imsr_status = 1;
        RETURN v_name;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END IMPR_RULE_TARIFF_POST_QUERY;

    -- Source: IMPR_RULE_TARIFF.HRMNZD_CODE.WHEN-VALIDATE-ITEM (check part)
    -- Original Forms code (active part; the "tabbaa" and "current" FILLER1 / FILLER2 checks are commented out):
    --   CURSOR C IS SELECT HT.ITEM_ARBC_DESC, ... FROM HARMONIZED_TARIFF HT, TARIFF_DETAILS
    --    WHERE HT.HRMNZD_CODE = :HRMNZD_CODE AND HT.HRMNZD_CODE = TARIFF_DETAILS.HRMNZD_CODE AND TARIFF_DETAILS.STA_CODE = 0;
    --   IF C%NOTFOUND THEN STR.DISPALERT('رمز بند التعرفة غير موجود ','ERROR'); RAISE NO_DATA_FOUND;
    --   ...
    --   SELECT COUNT(1) INTO v_count FROM DUAL WHERE EXISTS (SELECT 1 FROM impr_rules, impr_rule_tariff
    --     WHERE impr_rules.rule_isn = impr_rule_tariff.rule_isn AND impr_rules.hq_impr_nbr = :impr_rules.hq_impr_nbr
    --       AND impr_rules.bus_id_type_cd = :impr_rules.bus_id_type_cd AND impr_rules.bus_id = :impr_rules.bus_id
    --       AND impr_rule_tariff.hrmnzd_code = :hrmnzd_code AND impr_rule_tariff.remained_qty > 0
    --       AND impr_rule_tariff.rec_status = 1
    --       AND (:impr_rules.rule_isn IS NULL OR impr_rules.rule_isn <> :impr_rules.rule_isn));
    --   IF NVL(v_count,0) > 0 THEN STR.DISPALERT('هذا البند تم ادخاله من قبل لنفس المستورد','ERROR'); RAISE FORM_TRIGGER_FAILURE;
    -- The RAISE NO_DATA_FOUND after the alert ends the trigger with an error (Forms: FRM-40735): the item is
    -- refused, so it is an error text here.
    FUNCTION HRMNZD_CODE_VALIDATION (HRMNZD_CODE      IN VARCHAR2,
                                     P_RULE_ISN       IN NUMBER,
                                     P_HQ_IMPR_NBR    IN NUMBER,
                                     P_BUS_ID_TYPE_CD IN NUMBER,
                                     P_BUS_ID         IN VARCHAR2) RETURN VARCHAR2
    IS
        v_count NUMBER;
    BEGIN
        IF HRMNZD_CODE IS NULL THEN
            RETURN NULL;
        END IF;
        SELECT COUNT(*)
          INTO v_count
          FROM harmonized_tariff ht, tariff_details td
         WHERE ht.hrmnzd_code = HRMNZD_CODE_VALIDATION.HRMNZD_CODE
           AND ht.hrmnzd_code = td.hrmnzd_code
           AND td.sta_code = 0
           AND ROWNUM = 1;
        IF v_count = 0 THEN
            RETURN c_msg_no_tariff;
        END IF;
        BEGIN
            SELECT COUNT(1)
              INTO v_count
              FROM dual
             WHERE EXISTS (SELECT 1
                             FROM impr_rules r, impr_rule_tariff t
                            WHERE r.rule_isn = t.rule_isn
                              AND r.hq_impr_nbr = HRMNZD_CODE_VALIDATION.P_HQ_IMPR_NBR
                              AND r.bus_id_type_cd = HRMNZD_CODE_VALIDATION.P_BUS_ID_TYPE_CD
                              AND r.bus_id = HRMNZD_CODE_VALIDATION.P_BUS_ID
                              AND t.hrmnzd_code = HRMNZD_CODE_VALIDATION.HRMNZD_CODE
                              AND t.remained_qty > 0
                              AND t.rec_status = 1
                              AND (HRMNZD_CODE_VALIDATION.P_RULE_ISN IS NULL
                                   OR r.rule_isn <> HRMNZD_CODE_VALIDATION.P_RULE_ISN));
        EXCEPTION
            WHEN OTHERS THEN
                v_count := 0;
        END;
        IF NVL(v_count, 0) > 0 THEN
            RETURN c_msg_tariff_twice;
        END IF;
        RETURN NULL;
    END HRMNZD_CODE_VALIDATION;

    -- Source: IMPR_RULE_TARIFF.HRMNZD_CODE.WHEN-VALIDATE-ITEM (derived values) + HRMNZD_CODE.POST-CHANGE
    -- Original Forms code: FETCH C INTO :HT_ITEM_ARBC_DESC ...; then the international unit (as
    --   IMPR_RULE_TARIFF_POST_QUERY) with EXCEPTION WHEN NO_DATA_FOUND THEN
    --   STR.DISPALERT(' الوحدة الدولية غير معرفة .. راجع الدعم الفني ','ERROR');   -- no failure
    -- POST-CHANGE: SELECT item_arbc_desc INTO :HT_ITEM_ARBC_DESC FROM harmonized_tariff WHERE hrmnzd_code = ...
    -- The non-blocking alert is not shown (FOS shows errors only): INTL_UNIT stays empty (inventory §15 #7).
    PROCEDURE HRMNZD_CODE_VALIDATE_ITEM (HRMNZD_CODE       IN     VARCHAR2,
                                         P_RULE_ISN        IN     NUMBER,
                                         P_HQ_IMPR_NBR     IN     NUMBER,
                                         P_BUS_ID_TYPE_CD  IN     NUMBER,
                                         P_BUS_ID          IN     VARCHAR2,
                                         HT_ITEM_ARBC_DESC IN OUT VARCHAR2,
                                         INTL_UNIT         IN OUT VARCHAR2)
    IS
    BEGIN
        FORMS_APX.CHECK_ERROR(HRMNZD_CODE_VALIDATION(HRMNZD_CODE, P_RULE_ISN, P_HQ_IMPR_NBR, P_BUS_ID_TYPE_CD, P_BUS_ID));
        IF HRMNZD_CODE IS NOT NULL THEN
            SELECT ht.item_arbc_desc
              INTO HRMNZD_CODE_VALIDATE_ITEM.HT_ITEM_ARBC_DESC
              FROM harmonized_tariff ht
             WHERE ht.hrmnzd_code = HRMNZD_CODE_VALIDATE_ITEM.HRMNZD_CODE;
            INTL_UNIT := IMPR_RULE_TARIFF_POST_QUERY(HRMNZD_CODE);
        END IF;
    END HRMNZD_CODE_VALIDATE_ITEM;

    -- Source: IMPR_RULE_TARIFF.EXEPTION_QTY.WHEN-VALIDATE-ITEM
    -- Original Forms code:
    --   :REMAINED_QTY := :EXEPTION_QTY;
    --   STR.DISPALERT(' تأكد من تطابق الوحده الدولية مع وحدة الكمية المستثناه ','INFORMATION');
    -- APEX-DA: the INFORMATION alert is the native Alert action after this call.
    PROCEDURE EXEPTION_QTY_VALIDATE_ITEM (EXEPTION_QTY IN     NUMBER,
                                          REMAINED_QTY IN OUT NUMBER)
    IS
    BEGIN
        REMAINED_QTY := EXEPTION_QTY;
    END EXEPTION_QTY_VALIDATE_ITEM;

    -- Source: IMPR_RULE_TARIFF.PRE-INSERT
    -- Original Forms code:
    --   SELECT NVL(MAX(ITEM_SEQUENCE),0) INTO MAX_ITEM_SEQUENCE FROM IMPR_RULE_TARIFF WHERE RULE_ISN = :IMPR_RULE_TARIFF.RULE_ISN;
    --   :IMPR_RULE_TARIFF.ITEM_SEQUENCE := MAX_ITEM_SEQUENCE + 1;
    --   IF :IMPR_RULE_TARIFF.REC_STATUS IS NULL THEN :IMPR_RULE_TARIFF.REC_STATUS := 1; END IF;
    --   IF NOT ACTIVITY.ADD_ACTIVITY(9, 6, 1, :IMPR_RULES.RULE_ISN||'!'||:IMPR_RULE_TARIFF.HRMNZD_CODE) THEN RAISE FORM_TRIGGER_FAILURE;
    -- :IMPR_RULES.RULE_ISN = the row's RULE_ISN (copied from the master).
    PROCEDURE IMPR_RULE_TARIFF_PRE_INSERT (RULE_ISN         IN     NUMBER,
                                           HRMNZD_CODE      IN     VARCHAR2,
                                           ITEM_SEQUENCE    IN OUT NUMBER,
                                           REC_STATUS       IN OUT NUMBER,
                                           P_CURR_PORT_CD   IN     NUMBER,
                                           SSO_APP_USER     IN     VARCHAR2,
                                           P_GLOBAL_V_WS_ID IN     VARCHAR2)
    IS
    BEGIN
        SELECT NVL(MAX(t.item_sequence), 0) + 1
          INTO IMPR_RULE_TARIFF_PRE_INSERT.ITEM_SEQUENCE
          FROM impr_rule_tariff t
         WHERE t.rule_isn = IMPR_RULE_TARIFF_PRE_INSERT.RULE_ISN;
        IF REC_STATUS IS NULL THEN
            REC_STATUS := 1;
        END IF;
        add_activity(c_subject_tariff, c_activity_insert, RULE_ISN || '!' || HRMNZD_CODE,
                     P_CURR_PORT_CD, SSO_APP_USER, P_GLOBAL_V_WS_ID);
    END IMPR_RULE_TARIFF_PRE_INSERT;

    -- Source: IMPR_RULE_TARIFF.PRE-UPDATE
    -- Original Forms code: IF NOT ACTIVITY.ADD_ACTIVITY(9, 6, 2, :IMPR_RULES.RULE_ISN||'!'||:HRMNZD_CODE) THEN RAISE FORM_TRIGGER_FAILURE;
    PROCEDURE IMPR_RULE_TARIFF_PRE_UPDATE (RULE_ISN         IN NUMBER,
                                           HRMNZD_CODE      IN VARCHAR2,
                                           P_CURR_PORT_CD   IN NUMBER,
                                           SSO_APP_USER     IN VARCHAR2,
                                           P_GLOBAL_V_WS_ID IN VARCHAR2)
    IS
    BEGIN
        add_activity(c_subject_tariff, c_activity_update, RULE_ISN || '!' || HRMNZD_CODE,
                     P_CURR_PORT_CD, SSO_APP_USER, P_GLOBAL_V_WS_ID);
    END IMPR_RULE_TARIFF_PRE_UPDATE;

    -- Source: block IMPR_RULE_TARIFF row DML. HRMNZD_CODE is not updatable; EXEPTION_QTY is the column
    -- EXCEPTED_QTY. The block PRE-DELETE is dropped: Delete Allowed = false, a deleted row is refused.
    PROCEDURE IMPR_RULE_TARIFF_SAVE_ROW (APEX$ROW_STATUS  IN     VARCHAR2,
                                         ROW_ID           IN OUT VARCHAR2,
                                         RULE_ISN         IN     NUMBER,
                                         HRMNZD_CODE      IN     VARCHAR2,
                                         EXEPTION_QTY     IN     NUMBER,
                                         REMAINED_QTY     IN     NUMBER,
                                         REC_STATUS       IN     NUMBER,
                                         ITEM_SEQUENCE    IN OUT NUMBER,
                                         P_CURR_PORT_CD   IN     NUMBER,
                                         SSO_APP_USER     IN     VARCHAR2,
                                         P_GLOBAL_V_WS_ID IN     VARCHAR2)
    IS
        v_rowid      ROWID;
        v_rec_status NUMBER := REC_STATUS;
    BEGIN
        IF APEX$ROW_STATUS = 'C' THEN
            IMPR_RULE_TARIFF_PRE_INSERT(RULE_ISN, HRMNZD_CODE, ITEM_SEQUENCE, v_rec_status,
                                        P_CURR_PORT_CD, SSO_APP_USER, P_GLOBAL_V_WS_ID);
            INSERT INTO impr_rule_tariff (rule_isn, hrmnzd_code, excepted_qty, remained_qty, rec_status, item_sequence)
            VALUES (IMPR_RULE_TARIFF_SAVE_ROW.RULE_ISN, IMPR_RULE_TARIFF_SAVE_ROW.HRMNZD_CODE,
                    IMPR_RULE_TARIFF_SAVE_ROW.EXEPTION_QTY, IMPR_RULE_TARIFF_SAVE_ROW.REMAINED_QTY,
                    v_rec_status, IMPR_RULE_TARIFF_SAVE_ROW.ITEM_SEQUENCE)
            RETURNING ROWID INTO v_rowid;
            ROW_ID := ROWIDTOCHAR(v_rowid);
        ELSIF APEX$ROW_STATUS = 'U' THEN
            IMPR_RULE_TARIFF_PRE_UPDATE(RULE_ISN, HRMNZD_CODE, P_CURR_PORT_CD, SSO_APP_USER, P_GLOBAL_V_WS_ID);
            UPDATE impr_rule_tariff t
               SET t.excepted_qty = IMPR_RULE_TARIFF_SAVE_ROW.EXEPTION_QTY,
                   t.remained_qty = IMPR_RULE_TARIFF_SAVE_ROW.REMAINED_QTY,
                   t.rec_status   = v_rec_status
             WHERE t.ROWID = CHARTOROWID(IMPR_RULE_TARIFF_SAVE_ROW.ROW_ID);
        ELSIF APEX$ROW_STATUS = 'D' THEN
            FORMS_APX.FORM_TRIGGER_FAILURE(c_msg_tariff_delete);
        END IF;
    END IMPR_RULE_TARIFF_SAVE_ROW;

    -- =========================================================================
    -- PROGRAM UNITS
    -- =========================================================================

    -- Source: PU CGFK$QRY_IMPR_RULES_IR_BIT_FK (cursor on BUS_ID_TYPES; NO_DATA_FOUND when not found)
    PROCEDURE CGFK$QRY_IMPR_RULES_IR_BIT_FK (p_bus_id_type_name IN OUT VARCHAR2,
                                             p_bus_id_type_cd   IN     NUMBER)
    IS
    BEGIN
        SELECT l_bit.bus_id_type_name
          INTO p_bus_id_type_name
          FROM bus_id_types l_bit
         WHERE l_bit.bus_id_type_cd = p_bus_id_type_cd
           AND ROWNUM = 1;
    END CGFK$QRY_IMPR_RULES_IR_BIT_FK;

    -- Source: PU CGFK$CHK_IMPR_RULE_PORTS_IRP_S (cursor on SD_PORTS; NO_DATA_FOUND when not found)
    PROCEDURE CGFK$CHK_IMPR_RULE_PORTS_IRP_S (p_port_name IN OUT VARCHAR2,
                                              p_port_cd   IN     NUMBER)
    IS
    BEGIN
        SELECT sdp.port_name
          INTO p_port_name
          FROM sd_ports sdp
         WHERE sdp.port_cd = p_port_cd
           AND ROWNUM = 1;
    END CGFK$CHK_IMPR_RULE_PORTS_IRP_S;

    -- Source: PU CGRI$CHK_IMPR_RULES
    -- Original Forms code: IF a row of IMPR_RULE_PORTS has RULE_ISN = P_RULE_ISN THEN
    --   Des$Form_errors.PUSH(MSGGETTEXT(5, 'Cannot delete <p1> while dependent <p2> exists',
    --                         'استثناءات المستوردين','جمارك الاستثناء')); RAISE_FAILURE;
    -- The P_CHECK_BOTH parameter (TRUE in the only call) is dropped.
    PROCEDURE CGRI$CHK_IMPR_RULES (p_rule_isn IN NUMBER)
    IS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*)
          INTO v_count
          FROM impr_rule_ports irp
         WHERE irp.rule_isn = p_rule_isn
           AND ROWNUM = 1;
        IF v_count > 0 THEN
            FORMS_APX.FORM_TRIGGER_FAILURE(
                REPLACE(REPLACE('Cannot delete <p1> while dependent <p2> exists',
                                '<p1>', 'استثناءات المستوردين'), '<p2>', 'جمارك الاستثناء'));
        END IF;
    END CGRI$CHK_IMPR_RULES;

    -- Source: PU CHECK_FASH_ROLE_ID
    -- Original Forms code: SELECT UR.ROLE_ID INTO V_ROLE_ID FROM SC_USER_ROLES ... UNION SELECT GR.ROLE_ID FROM
    --   SC_GROUP_ROLES GR, SC_USER_GROUPS UG ... MINUS SELECT ROLE_ID FROM SC_USER_EXCLUDED_ROLES ...;
    --   NO_DATA_FOUND -> FALSE; RETURN V_ROLE_ID = 'IMP_EXCEPTION_FASH'.
    -- SELECT INTO returns at most one row here (every branch selects the same constant role id).
    FUNCTION CHECK_FASH_ROLE_ID (p_port_cd IN NUMBER,
                                 p_user_id IN VARCHAR2) RETURN BOOLEAN
    IS
        v_role_id VARCHAR2(30);
    BEGIN
        BEGIN
            SELECT ur.role_id
              INTO v_role_id
              FROM (SELECT ur.role_id
                      FROM sc_user_roles ur
                     WHERE ur.user_id   = p_user_id
                       AND ur.port_cd   = p_port_cd
                       AND ur.ur_active = 1
                       AND ur.role_id   = c_role_fash
                    UNION
                    SELECT gr.role_id
                      FROM sc_group_roles gr, sc_user_groups ug
                     WHERE ug.port_cd   = p_port_cd
                       AND ug.user_id   = p_user_id
                       AND gr.role_id   = c_role_fash
                       AND gr.group_id  = ug.group_id
                       AND gr.gr_active = 1
                    MINUS
                    SELECT uer.role_id
                      FROM sc_user_excluded_roles uer
                     WHERE uer.user_id    = p_user_id
                       AND uer.port_cd    = p_port_cd
                       AND uer.role_id    = c_role_fash
                       AND uer.uer_active = 1) ur;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RETURN FALSE;
        END;
        RETURN v_role_id = c_role_fash;
    END CHECK_FASH_ROLE_ID;

    -- Source: PU ADJ_BRANCH
    -- Original Forms code:
    --   IF :IMPR_RULES.ALL_BRNCH_FLAG <> 1 THEN INTRFACE.MAKE_FIELD_ENTRABLE('IMPR_RULES.BUS_ID_BRNCH', TRUE);
    --   ELSE :IMPR_RULES.BUS_ID_BRNCH := NULL; INTRFACE.MAKE_FIELD_ENTRABLE('IMPR_RULES.BUS_ID_BRNCH', FALSE); END IF;
    -- Forms: a NULL flag takes the ELSE branch (NULL <> 1 is not TRUE).
    PROCEDURE ADJ_BRANCH (P_ALL_BRNCH_FLAG IN     NUMBER,
                          P_BUS_ID_BRNCH   IN OUT VARCHAR2)
    IS
    BEGIN
        IF P_ALL_BRNCH_FLAG = 1 OR P_ALL_BRNCH_FLAG IS NULL THEN
            P_BUS_ID_BRNCH := NULL;
        END IF;
    END ADJ_BRANCH;

    -- =========================================================================
    -- UI LOGIC FOR APEX DYNAMIC ACTIONS   (comments only, no executable code)
    -- =========================================================================
    -- APEX-DA: [Source: PRE-FORM] SET_ITEM_PROPERTY('D', VISIBLE, FALSE)
    --          -> item IMPR_RULES.D is not created (non-database, never shown).
    -- APEX-DA: [Source: IMPR_RULES.WHEN-NEW-RECORD-INSTANCE, ALL_BRNCH_FLAG.WHEN-VALIDATE-ITEM -> ADJ_BRANCH]
    --          Original: INTRFACE.MAKE_FIELD_ENTRABLE('IMPR_RULES.BUS_ID_BRNCH', TRUE / FALSE); BUS_ID_BRNCH := NULL
    --          Implement as: DA "ALL_BRNCH_FLAG WHEN-VALIDATE-ITEM" (change, fire on initialization), client-side
    --          condition P1140_ALL_BRNCH_FLAG <> 1 (not equal 1): TRUE Enable P1140_BUS_ID_BRNCH;
    --          FALSE Clear + Disable P1140_BUS_ID_BRNCH. The server clears the value again in ADJ_BRANCH.
    -- APEX-DA: [Source: IMPR_RULES.RULE_TYPE.WHEN-LIST-CHANGED] -> DA "RULE_TYPE WHEN-LIST-CHANGED":
    --          FOS FORMS_APX.CHECK_ERROR(IMPR1140.RULE_TYPE_VALIDATION(P_RULE_TYPE => :P1140_RULE_TYPE)).
    -- APEX-DA: [Source: IMPR_RULES.HQ_IMPR_NBR.KEY-LISTVAL, B_IMP.WHEN-BUTTON-PRESSED -> SINGLE_IMP_LOV]
    --          Original: CALL_FORM('LOV_IMPORT_HQ_N12' / 'LOV_IMPORT_HQ_NBR'), values back through :GLOBAL
    --          Implement as: Popup LOV LOV_SINGLE_IMPORTERS on P1140_HQ_IMPR_NBR (Items to Submit P1140_RULE_TYPE),
    --          then DA "HQ_IMPR_NBR WHEN-VALIDATE-ITEM" fills BUS_ID / name (FOS Items to Return).
    -- APEX-DA: [Source: IMPR_RULE_PORTS.PORT_CD.KEY-LISTVAL, PORT_CD2.WHEN-BUTTON-PRESSED -> CALL_SD_PORTS]
    --          -> Popup LOV column on LOV_SD_PORTS; DA "IMPR_RULE_PORTS PORT_CD WHEN-VALIDATE-ITEM" returns PORT_NAME.
    -- APEX-DA: [Source: IMPR_RULE_TARIFF.HRMNZD_CODE.KEY-LISTVAL, HRMNZD_CODE2.WHEN-BUTTON-PRESSED -> DSP_TRF_ITEMS_LOV]
    --          -> Popup LOV column on LOV_HARMONIZED_TARIFF; DA "IMPR_RULE_TARIFF HRMNZD_CODE WHEN-VALIDATE-ITEM"
    --          returns HT_ITEM_ARBC_DESC and INTL_UNIT.
    -- APEX-DA: [Source: IMPR_RULE_TARIFF.EXEPTION_QTY.WHEN-VALIDATE-ITEM] -> DA "IMPR_RULE_TARIFF EXEPTION_QTY
    --          WHEN-VALIDATE-ITEM": FOS EXEPTION_QTY_VALIDATE_ITEM (returns REMAINED_QTY), then native Alert
    --          ' تأكد من تطابق الوحده الدولية مع وحدة الكمية المستثناه '.
    -- APEX-DA: [Source: IMPR_RULE_PORTS POST-QUERY / PRE-RECORD / WHEN-NEW-RECORD-INSTANCE]
    --          SET_BLOCK_PROPERTY(INSERT_ALLOWED) -> server check in IMPR_RULE_PORTS_PRE_INSERT.
    -- APEX-DA: [Source: KEY-LISTVAL x14, CGAP$OLES_SEQUENCE_BEFORE] "may the LOV be shown" -> item read-only state.
    -- APEX-DA: [Source: WHEN-TAB-PAGE-CHANGED, WHEN-NEW-BLOCK-INSTANCE (CGLT$TAB_BLOCKS)] -> Tabs Container region.

END IMPR1140;
/
SHOW ERRORS
