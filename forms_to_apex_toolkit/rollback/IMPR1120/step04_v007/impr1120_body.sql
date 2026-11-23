-- =============================================================================
-- Package body: IMPR1120   (matches impr1120_spec.sql - f345 standard)
-- Source form : IMPR1120.fmb   Target: APEX 21.2 / DB 12.1.0.2   Version: 007
-- Author      : Claude Code     Created: 2026-11-23   (see the spec history)
-- Rules: no Forms built-ins (FORMS_APX instead), no COMMIT / ROLLBACK,
--        parameters named after their binds without I_ / IO_ / O_; page items P<page>_X -> P_X;
--        inside SQL every parameter is qualified with its member name; identifiers <= 30 bytes.
-- Layout (docs/f345_reference_standard.md §10): PRIVATE HELPERS (top, used by the members below)
-- -> VERSION -> f345 HELPERS -> FORM LEVEL -> BLOCK IMPORTERS -> BLOCK IMPR_SUSPN -> PROGRAM UNITS
-- -> UI LOGIC FOR APEX DYNAMIC ACTIONS (comments only).
-- Status: NOT COMPILED. External DB packages without source: STR_DB, GNRL, SMS_MESSAGE,
--         LIB_APX_USR.APEX_NOTIFICATIONS (calls copied unchanged from the Forms code).
-- =============================================================================
SET DEFINE OFF

CREATE OR REPLACE PACKAGE BODY LIB_APX_USR.IMPR1120
AS
    c_err              CONSTANT PLS_INTEGER  := -20001;
    c_hero_title       CONSTANT VARCHAR2(100) := 'صيانة توقيفات المستوردين';
    c_head_office_port CONSTANT NUMBER       := 99;     -- :PARAMETER.P_CURR_PORT_CD = 99
    c_sysobj_importers CONSTANT NUMBER       := 9;      -- ACTIVITY.ADD_ACTIVITY(9, ...)
    c_subject_suspn    CONSTANT NUMBER       := 3;      -- ACTIVITY.ADD_ACTIVITY(9, 3, ...)
    c_activity_insert  CONSTANT NUMBER       := 1;
    c_activity_update  CONSTANT NUMBER       := 2;
    c_activity_delete  CONSTANT NUMBER       := 3;
    -- Forms format mask of the Hijri date items (OLB property class CGSO$HDATE_ARB); the day is kept
    -- in the minutes, so every Hijri day (e.g. 30-02) fits in a DATE. IMPR1110 uses MI-MM-YYYY.
    c_date_mask        CONSTANT VARCHAR2(10) := 'MI-MM-RRRR';
    -- Forms FRM-50026 "Date must be entered in a format like MI-MM-RRRR". TODO: confirm the Arabic text.
    c_msg_date_format  CONSTANT VARCHAR2(200) := 'يجب إدخال التاريخ بالصيغة يوم-شهر-سنة (MI-MM-RRRR)';

    -- Texts the Forms code did not have (it raised FORM_TRIGGER_FAILURE without a message, or
    -- made the rows unreachable with NEXT_RECORD). TODO: agree the texts (inventory §15 #12).
    c_msg_reason_not_allowed CONSTANT VARCHAR2(200) := 'سبب الإيقاف غير مسموح به لهذه الجهة';
    c_msg_side_not_allowed   CONSTANT VARCHAR2(200) := 'الجهة غير مسموح بها لهذه الجهة';
    c_msg_other_side_row     CONSTANT VARCHAR2(200) := 'لا يمكن تعديل أو حذف توقيف خاص بجهة أخرى';

    -- =========================================================================
    -- PRIVATE HELPERS
    -- =========================================================================
    -- Text of STR.DispArbMsg(sys, nbr, type) (CIC_LIB.pld): STR_DB.GetArbMsg(sys, nbr) shown as
    -- '<sys>-<nbr> : <text>'; '-1' = unknown message number. (Same as IMPR1110.ARABIC_MESSAGE.)
    FUNCTION arabic_message (p_sys IN NUMBER, p_nbr IN NUMBER) RETURN VARCHAR2
    IS
        v_txt VARCHAR2(4000);
    BEGIN
        v_txt := str_db.getarbmsg(p_sys, p_nbr);
        IF v_txt = '-1' THEN
            RETURN 'خطأ فى رقم الرسالة ' || p_sys || '-' || p_nbr || 'إتصل بالمسانده الفنيه';
        END IF;
        RETURN p_sys || '-' || p_nbr || ' : ' || v_txt;
    END arabic_message;

    -- HIJDATE.Cur_Hij_Date (CIC_LIB.pld): HIJDATE_DB.Cur_Hij_Date(V_MSG); NULL -> DispAlert + FAILURE
    FUNCTION cur_hij_date RETURN DATE
    IS
        v_msg VARCHAR2(2000);
        v_ret DATE;
    BEGIN
        v_ret := hijdate_db.cur_hij_date(v_msg);
        IF v_ret IS NULL THEN
            FORMS_APX.FORM_TRIGGER_FAILURE(v_msg);
        END IF;
        RETURN v_ret;
    END cur_hij_date;

    -- Hijri date text (Forms mask MI-MM-RRRR) -> DATE. No calendar conversion: the text is already Hijri
    -- (HIJDATE_DB.TO_HIJRI would convert a Gregorian date). A wrong format raises the FRM-50026 equivalent.
    FUNCTION hijri_text_to_date (p_text IN VARCHAR2) RETURN DATE
    IS
    BEGIN
        RETURN TO_DATE(p_text, c_date_mask);
    EXCEPTION
        WHEN OTHERS THEN               -- ORA-01821 / ORA-01843 / ORA-01847 ...: not in the mask
            FORMS_APX.FORM_TRIGGER_FAILURE(c_msg_date_format);
            RETURN NULL;               -- not reached
    END hijri_text_to_date;

    -- DATE -> Hijri date text in the Forms mask
    FUNCTION hijri_text (p_date IN DATE) RETURN VARCHAR2
    IS
    BEGIN
        RETURN TO_CHAR(p_date, c_date_mask);
    END hijri_text;

    -- HIJDATE.VALID_HIJ_DATE (CIC_LIB.pld): HIJDATE_DB.VALID_HIJ_DATE(HDate, V_MSG) = 0 ->
    -- DispAlert(V_MSG, 'ERROR') and the caller raises FORM_TRIGGER_FAILURE.
    -- Here the alert text is returned, for the validation functions. NULL = valid or empty.
    -- p_text is the item text: a wrong format gives the FRM-50026 text, as Forms does before WVI.
    FUNCTION hijri_date_error (p_text IN VARCHAR2) RETURN VARCHAR2
    IS
        v_msg  VARCHAR2(2000);
        v_date DATE;
    BEGIN
        IF p_text IS NULL THEN
            RETURN NULL;
        END IF;
        BEGIN
            v_date := TO_DATE(p_text, c_date_mask);
        EXCEPTION
            WHEN OTHERS THEN
                RETURN c_msg_date_format;
        END;
        IF hijdate_db.valid_hij_date(v_date, v_msg) = 0 THEN
            RETURN NVL(v_msg, 'التاريخ غير صحيح');
        END IF;
        RETURN NULL;
    END hijri_date_error;

    -- Stored row of a suspension (NULL fields for a new row). Forms fires WHEN-VALIDATE-ITEM only
    -- when the item value changed; an IG row validation sees every column of a changed row, so the
    -- column validations compare with the stored value and skip an unchanged one.
    FUNCTION stored_suspension (p_port_cd   IN NUMBER,
                                p_impr_nbr  IN NUMBER,
                                p_suspn_seq IN NUMBER) RETURN impr_suspns%ROWTYPE
    IS
        v_row impr_suspns%ROWTYPE;
    BEGIN
        IF p_suspn_seq IS NULL THEN
            RETURN v_row;
        END IF;
        SELECT *
          INTO v_row
          FROM impr_suspns s
         WHERE s.port_cd   = p_port_cd
           AND s.impr_nbr  = p_impr_nbr
           AND s.suspn_seq = p_suspn_seq;
        RETURN v_row;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN v_row;
    END stored_suspension;

    -- Forms: IF NOT ACTIVITY.ADD_ACTIVITY(9, 3, <type>, :PORT_CD||'!'||:IMPR_NBR||'!'||:SUSPN_SEQ) THEN
    --            RAISE FORM_TRIGGER_FAILURE;
    -- ACTIVITY.ADD_ACTIVITY (CIC_LIB.pld) passes :PARAMETER.P_Curr_Port_Cd, P_USER_ID, P_WS_ID to
    -- ACTIVITY_DB.ADD_ACTIVITY and on 0 shows V_MSG_TXT (CFG_SYSTEM_ERROR) and returns FALSE.
    PROCEDURE add_activity (p_activity_type IN NUMBER,
                            p_port_cd       IN NUMBER,
                            p_impr_nbr      IN NUMBER,
                            p_suspn_seq     IN NUMBER,
                            p_curr_port_cd  IN NUMBER,
                            p_user_id       IN VARCHAR2,
                            p_ws_id         IN VARCHAR2)
    IS
        v_msg VARCHAR2(2000);
    BEGIN
        IF activity_db.add_activity(c_sysobj_importers, c_subject_suspn, p_activity_type,
                                    p_port_cd || '!' || p_impr_nbr || '!' || p_suspn_seq,
                                    p_curr_port_cd, p_user_id, p_ws_id, v_msg) = 0 THEN
            FORMS_APX.FORM_TRIGGER_FAILURE(v_msg);
        END IF;
    END add_activity;

    -- ROWID of importer IMPR_NBR in port PORT_CD (value of P0_PAGE_PK), NULL when not found
    FUNCTION importer_row_id (p_port_cd IN NUMBER, p_impr_nbr IN NUMBER) RETURN VARCHAR2
    IS
        v_row_id VARCHAR2(18);
    BEGIN
        SELECT MAX(ROWIDTOCHAR(i.ROWID))
          INTO v_row_id
          FROM importers i
         WHERE i.port_cd  = p_port_cd
           AND i.impr_nbr = p_impr_nbr;
        RETURN v_row_id;
    END importer_row_id;

    -- The side rule shared by SUSPN_SIDE_CD.WHEN-LIST-CHANGED and IMPR_SUSPN.WHEN-NEW-RECORD-INSTANCE:
    -- TRUE when side code p_side_cd does not belong to site p_current_side.
    -- A NULL side code is never "another side" (Forms: NULL <> 1 is not TRUE).
    FUNCTION side_of_another_site (p_side_cd      IN NUMBER,
                                   p_current_side IN NUMBER,
                                   p_curr_port_cd IN NUMBER) RETURN BOOLEAN
    IS
    BEGIN
        IF p_side_cd IS NULL THEN
            RETURN FALSE;
        END IF;
        -- NVL: an empty CURRENT_SIDE matches none of the Forms conditions
        RETURN NVL(   (p_current_side = 1 AND p_curr_port_cd <> c_head_office_port AND p_side_cd <> 1)
                   OR (p_current_side = 2 AND p_curr_port_cd <> c_head_office_port AND p_side_cd IN (1, 5))
                   OR (p_current_side = 3 AND p_curr_port_cd =  c_head_office_port AND p_side_cd <> 5),
                   FALSE);
    END side_of_another_site;

    -- Server-side counterpart of WHEN-NEW-RECORD-INSTANCE NEXT_RECORD: in Forms the user could not
    -- reach (so could not change or delete) a suspension of another site. The stored side is read,
    -- not the submitted one.
    PROCEDURE check_row_of_current_site (p_port_cd      IN NUMBER,
                                         p_impr_nbr     IN NUMBER,
                                         p_suspn_seq    IN NUMBER,
                                         p_current_side IN NUMBER,
                                         p_curr_port_cd IN NUMBER)
    IS
        v_side_cd impr_suspns.suspn_side_cd%TYPE;
    BEGIN
        SELECT MAX(s.suspn_side_cd)
          INTO v_side_cd
          FROM impr_suspns s
         WHERE s.port_cd   = p_port_cd
           AND s.impr_nbr  = p_impr_nbr
           AND s.suspn_seq = p_suspn_seq;
        IF side_of_another_site(v_side_cd, p_current_side, p_curr_port_cd) THEN
            FORMS_APX.FORM_TRIGGER_FAILURE(c_msg_other_side_row);
        END IF;
    END check_row_of_current_site;

    -- =========================================================================
    -- PACKAGE VERSION
    -- =========================================================================
    -- SELECT IMPR1120.PKG_VERSION FROM dual;  -> package name, version, modified date / by
    FUNCTION PKG_VERSION
       RETURN VARCHAR2
    IS
    BEGIN
       RETURN V_INFO;
    END PKG_VERSION;

    -- =========================================================================
    -- f345 HELPERS
    -- =========================================================================
    PROCEDURE CHECK_ERROR (ERROR_TEXT IN VARCHAR2)
    IS
    BEGIN
        IF ERROR_TEXT IS NOT NULL THEN
            raise_application_error(c_err, ERROR_TEXT);
        END IF;
    END CHECK_ERROR;

    FUNCTION REQUIRED_VALIDATION (ITEM_VALUE IN VARCHAR2, ITEM_LABEL IN VARCHAR2) RETURN VARCHAR2
    IS
    BEGIN
        -- Source: FRM-40202 "Field must be entered"
        RETURN CASE WHEN TRIM(ITEM_VALUE) IS NULL THEN 'يجب إدخال ' || ITEM_LABEL END;
    END REQUIRED_VALIDATION;

    -- P0_PAGE_PK = ROWID of the importer. Outside port 99 it must belong to the user's port
    -- (IMPORTERS.PRE-QUERY forces PORT_CD := :PARAMETER.P_CURR_PORT_CD).
    PROCEDURE P0_PAGE_PK_CHECK (P_PAGE_PK    IN OUT VARCHAR2,
                                P_CURR_PORT_CD IN     NUMBER)
    IS
        v_cnt NUMBER;
    BEGIN
        IF P_PAGE_PK IS NULL THEN
            RETURN;
        END IF;
        P_PAGE_PK := TRANSLATE(P_PAGE_PK, '-_', '+/');      -- URL-safe ROWID of page 112001 -> ROWID
        SELECT COUNT(*)
          INTO v_cnt
          FROM importers i
         WHERE i.ROWID = CHARTOROWID(P0_PAGE_PK_CHECK.P_PAGE_PK)
           AND (P0_PAGE_PK_CHECK.P_CURR_PORT_CD = c_head_office_port OR i.port_cd = P0_PAGE_PK_CHECK.P_CURR_PORT_CD);
        IF v_cnt = 0 THEN
            P_PAGE_PK := NULL;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN               -- ORA-01410 invalid ROWID ...: not a key of this page
            P_PAGE_PK := NULL;
    END P0_PAGE_PK_CHECK;

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
         WHERE UPPER(REGEXP_REPLACE(o.sys_os_file_name, '\..*$', '')) = 'IMPR1120';
        RETURN v_id;
    END GET_MODULE_ID;

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
        WHEN VALUE_ERROR THEN          -- module id is not a number
            P_HERO_TITLE := c_hero_title;
    END HEADER_TITLE;

    -- =========================================================================
    -- FORM LEVEL
    -- =========================================================================
    -- Source: Forms parameter CURRENT_SIDE, set by the launcher (APPS / BUTTON_LAST_TREE and
    --         IMPR1120 PU EXECUTE_FUNCTION):
    --   cursor c_modudle_parameter(p_mid NUMBER) is select VAR_NAME, VAR_VALUE from sc_port_setting
    --          where PORT_CD = :PARAMETER.P_CURR_PORT_CD AND sysobj_id = p_mid;
    --   for i in c_modudle_parameter(<module id>) loop
    --       ADD_PARAMETER(pl_id, i.VAR_NAME, TEXT_PARAMETER, i.VAR_VALUE);
    --   end loop;
    -- TODO: confirm that SC_PORT_SETTING holds VAR_NAME = 'CURRENT_SIDE' (inventory §15 #1).
    FUNCTION GET_CURRENT_SIDE (P_MODULE_ID IN VARCHAR2,
                               P_CURR_PORT_CD  IN NUMBER) RETURN NUMBER
    IS
        v_value VARCHAR2(4000);
    BEGIN
        SELECT MAX(s.var_value)
          INTO v_value
          FROM sc_port_setting s
         WHERE s.port_cd          = GET_CURRENT_SIDE.P_CURR_PORT_CD
           AND s.sysobj_id        = TO_NUMBER(GET_CURRENT_SIDE.P_MODULE_ID)
           AND UPPER(s.var_name)  = 'CURRENT_SIDE';     -- Forms parameter names are not case sensitive
        RETURN TO_NUMBER(v_value);
    END GET_CURRENT_SIDE;

    -- Source: IMPR1120.WHEN-NEW-FORM-INSTANCE
    -- Original Forms code (business part; the rest is listed in the extraction report):
    --   IF :PARAMETER.Current_Side = 3 AND :PARAMETER.P_CURR_PORT_CD != 99 THEN
    --     MESSAGE('ليس لديك الصلاحية للدخول على الشاشة');
    --     EXIT_FORM(NO_VALIDATE);
    --   END IF;
    -- EXIT_FORM -> the page stops with the same message.
    PROCEDURE INIT_FORM (P_CURRENT_SIDE IN NUMBER,
                         P_CURR_PORT_CD       IN NUMBER)
    IS
    BEGIN
        IF P_CURRENT_SIDE = 3 AND P_CURR_PORT_CD <> c_head_office_port THEN
            FORMS_APX.FORM_TRIGGER_FAILURE('ليس لديك الصلاحية للدخول على الشاشة');
        END IF;
    END INIT_FORM;

    -- =========================================================================
    -- BLOCK IMPORTERS  (master)
    -- =========================================================================
    -- Source: IMPORTERS.PRE-QUERY (port part)
    -- Original Forms code:
    --   IF :PARAMETER.P_CURR_PORT_CD != 99 THEN
    --    :IMPORTERS.PORT_CD := :PARAMETER.P_CURR_PORT_CD;
    --   END IF;
    -- Returns the port to query: the user's port, or for port 99 the port entered (NULL = all).
    FUNCTION IMPORTERS_PRE_QUERY_PORT_CD (PORT_CD        IN NUMBER,
                                          P_CURR_PORT_CD IN NUMBER) RETURN NUMBER
    IS
    BEGIN
        IF P_CURR_PORT_CD <> c_head_office_port THEN
            RETURN P_CURR_PORT_CD;
        END IF;
        RETURN PORT_CD;
    END IMPORTERS_PRE_QUERY_PORT_CD;

    -- Source: IMPORTERS.PRE-QUERY (name part)
    -- Original Forms code:
    --   :IMPR_NAME_STD := STR.StrFormat(:ARBC_IMPR_NAME, TRUE);
    --   :ARBC_IMPR_NAME := '';
    -- STR.StrFormat(x, TRUE) = STR_DB.StrFormat(x, 1) (CIC_LIB.pld). The query then compares the
    -- criterion with column IMPR_NAME_STD instead of ARBC_IMPR_NAME.
    -- TODO: STR_DB is MISSING SOURCE - check whether StrFormat(x, 1) adds the % wildcards.
    -- The Designer CGFK$DEFAULT_WHERE part (PORT_NAME criterion -> sub-query on SD_PORTS built by
    -- string concatenation) becomes a bind filter in the search page SQL (CLAUDE.md §6 #9).
    FUNCTION IMPORTERS_PRE_QUERY_NAME_STD (ARBC_IMPR_NAME IN VARCHAR2) RETURN VARCHAR2
    IS
    BEGIN
        IF ARBC_IMPR_NAME IS NULL THEN
            RETURN NULL;
        END IF;
        RETURN str_db.strformat(ARBC_IMPR_NAME, 1);
    END IMPORTERS_PRE_QUERY_NAME_STD;

    -- Source: IMPORTERS.POST-QUERY (CGFK$QRY_LOOKUP_DATA)
    -- Original Forms code (shortened; each lookup is a CGFK$QRY_* program unit):
    --   IF PORT_CD IS NOT NULL THEN CGFK$QRY_IMPORTERS_IMP_SDP_FK(...);
    --      NO_DATA_FOUND: Des$Form_errors.PUSH('رمز الجمرك غير صحيح - أعد إدخال البيانات', 'E', ...)
    --   IF IMPR_TYPE_CD IS NOT NULL OR BUS_ID_TYPE_CD IS NOT NULL THEN CGFK$QRY_IMPORTERS_IMP_ITIDT_F(...);
    --      NO_DATA_FOUND: PUSH('رمز النشاط التجاري غير صحيح - أعد إدخال البيانات', 'E', ...)
    --   ELSE PUSH(MSGGETTEXT(78, '<p1> must be entered', 'رمز النشاط التجارى')); RAISE_FAILURE;
    --   IF CTRY_CD IS NOT NULL THEN CGFK$QRY_IMPORTERS_IMP_CTRY_FK(...);
    --      NO_DATA_FOUND: PUSH('رمز الدولة غير صحيح - أعد ادخال البيانات', 'E', ...)
    --   IF CITY_CODE_OF_ID IS NOT NULL AND CTRY_CD_OF_ID IS NOT NULL THEN CGFK$QRY_IMPORTERS_IMP_BUS_ID_(...);
    --      NO_DATA_FOUND: PUSH('خطأ في رمز مدينة مصدر الرقم الإستدلالي', 'E', ...)
    --   SET_RECORD_PROPERTY(..., STATUS, QUERY_STATUS)  -> not needed (no record status in APEX)
    --   CGFK$RESET_BLOCK_WHERE_CLAUSE                    -> not needed (no dynamic WHERE)
    -- A PUSH without RAISE_FAILURE shows the message and goes on: FORMS_APX.MESSAGE here.
    -- The *_STATUS items (SDP_PORT_STATUS, STATUS, CTRY_CTRY_STATUS) are hidden and read nowhere,
    -- so they are not returned.
    PROCEDURE IMPORTERS_POST_QUERY (P_PORT_CD          IN     NUMBER,
                                    P_IMPR_TYPE_CD     IN     NUMBER,
                                    P_BUS_ID_TYPE_CD   IN     NUMBER,
                                    P_CTRY_CD          IN     NUMBER,
                                    P_CTRY_CD_OF_ID    IN     NUMBER,
                                    P_CITY_CODE_OF_ID  IN     NUMBER,
                                    P_PORT_NAME           OUT VARCHAR2,
                                    P_IMPR_TYPE_NAME      OUT VARCHAR2,
                                    P_BUS_ID_TYPE_NAME    OUT VARCHAR2,
                                    P_CRTY_ARBC_NAME      OUT VARCHAR2,
                                    P_ID_CITY_NAME        OUT VARCHAR2)
    IS
        v_status NUMBER;
    BEGIN
        IF P_PORT_CD IS NOT NULL THEN
            BEGIN
                CGFK$QRY_IMPORTERS_IMP_SDP_FK(v_status, P_PORT_NAME, P_PORT_CD);
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    FORMS_APX.MESSAGE('رمز الجمرك غير صحيح - أعد إدخال البيانات');
            END;
        END IF;

        IF P_IMPR_TYPE_CD IS NOT NULL OR P_BUS_ID_TYPE_CD IS NOT NULL THEN
            BEGIN
                CGFK$QRY_IMPORTERS_IMP_ITIDT_F(P_BUS_ID_TYPE_NAME, P_IMPR_TYPE_NAME, v_status,
                                               P_IMPR_TYPE_CD, P_BUS_ID_TYPE_CD);
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    FORMS_APX.MESSAGE('رمز النشاط التجاري غير صحيح - أعد إدخال البيانات');
            END;
        ELSE
            -- Des$Form_errors.MSGGETTEXT(78, '<p1> must be entered', ...): English default of the
            -- Designer message (CIC_AMSG.pld); TODO: use the Arabic text of message 78 if it differs.
            FORMS_APX.FORM_TRIGGER_FAILURE(REPLACE('<p1> must be entered', '<p1>', 'رمز النشاط التجارى'));
        END IF;

        IF P_CTRY_CD IS NOT NULL THEN
            BEGIN
                CGFK$QRY_IMPORTERS_IMP_CTRY_FK(v_status, P_CRTY_ARBC_NAME, P_CTRY_CD);
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    FORMS_APX.MESSAGE('رمز الدولة غير صحيح - أعد ادخال البيانات');
            END;
        END IF;

        IF P_CITY_CODE_OF_ID IS NOT NULL AND P_CTRY_CD_OF_ID IS NOT NULL THEN
            BEGIN
                CGFK$QRY_IMPORTERS_IMP_BUS_ID_(P_ID_CITY_NAME, P_CTRY_CD_OF_ID,
                                               P_CITY_CODE_OF_ID);
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    FORMS_APX.MESSAGE('خطأ في رمز مدينة مصدر الرقم الإستدلالي');
            END;
        END IF;
    END IMPORTERS_POST_QUERY;

    -- Source: IMPORTERS.WHEN-CREATE-RECORD
    -- Original Forms code:
    --   :IMPORTERS.PORT_CD := :PARAMETER.P_CURR_PORT_CD;
    --   SELECT PORT_NAME INTO :IMPORTERS.PORT_NAME FROM SD_PORTS WHERE PORT_CD = :IMPORTERS.PORT_CD;
    -- WHEN-NEW-FORM-INSTANCE then keeps it (port 99: NVL(PORT_CD, P_CURR_PORT_CD); else P_CURR_PORT_CD).
    PROCEDURE IMPORTERS_WHEN_CREATE_RECORD (P_CURR_PORT_CD IN     NUMBER,
                                            P_PORT_CD     OUT NUMBER,
                                            P_PORT_NAME   OUT VARCHAR2)
    IS
    BEGIN
        P_PORT_CD := P_CURR_PORT_CD;
        SELECT p.port_name
          INTO IMPORTERS_WHEN_CREATE_RECORD.P_PORT_NAME
          FROM sd_ports p
         WHERE p.port_cd = IMPORTERS_WHEN_CREATE_RECORD.P_PORT_CD;
        -- Forms raised the unhandled NO_DATA_FOUND / TOO_MANY_ROWS here (FRM-40735); kept.
    END IMPORTERS_WHEN_CREATE_RECORD;

    -- Source: IMPR1120.WHEN-NEW-FORM-INSTANCE
    -- Original Forms code:
    --   IF :PARAMETER.P_CURR_PORT_CD = 99 THEN
    --    SET_ITEM_PROPERTY('IMPORTERS.PORT_CD',INSERT_ALLOWED,PROPERTY_TRUE);
    --    SET_ITEM_PROPERTY('IMPORTERS.PORT_CD',UPDATE_ALLOWED,PROPERTY_TRUE);
    --   END IF;
    FUNCTION PORT_CD_IS_READ_ONLY (P_CURR_PORT_CD IN NUMBER) RETURN BOOLEAN
    IS
    BEGIN
        RETURN NVL(P_CURR_PORT_CD <> c_head_office_port, TRUE);
    END PORT_CD_IS_READ_ONLY;

    -- Source: IMPORTERS.IMPR_NBR.WHEN-VALIDATE-ITEM
    -- Original Forms code:
    --   IF (:IMPORTERS.IMPR_NBR IS NOT NULL) THEN
    --     SELECT COUNT(*) INTO Rec_Count FROM IMPORTERS
    --      WHERE PORT_CD = :IMPORTERS.PORT_CD AND IMPR_NBR = :IMPORTERS.IMPR_NBR;
    --     IF Rec_Count <> 0 THEN  (see IMPR_NBR_WHEN_VALIDATE_ITEM)
    --     ELSE rec_count := STR.DispArbMsg(9, 150,'INFORMATION'); RAISE FORm_Trigger_Failure;
    FUNCTION IMPR_NBR_VALIDATION (P_PORT_CD  IN NUMBER,
                                  P_IMPR_NBR IN NUMBER) RETURN VARCHAR2
    IS
    BEGIN
        IF P_IMPR_NBR IS NULL THEN
            RETURN NULL;
        END IF;
        IF importer_row_id(P_PORT_CD, P_IMPR_NBR) IS NULL THEN
            RETURN arabic_message(9, 150);
        END IF;
        RETURN NULL;
    END IMPR_NBR_VALIDATION;

    -- Source: IMPORTERS.IMPR_NBR.WHEN-VALIDATE-ITEM (existing importer)
    -- Original Forms code:
    --   IF Rec_Count <> 0 THEN
    --     :global.PORT_CD := :IMPORTERS.PORT_CD; :global.IMPR_NBR := :IMPORTERS.IMPR_NBR;
    --     :global.Exec_Query_Now := 1;
    --   (IMPR_TYPE_CD.WHEN-NEW-ITEM-INSTANCE then runs CLEAR_BLOCK + EXECUTE_QUERY and PRE-QUERY
    --    queries :global.PORT_CD / IMPR_NBR)
    -- APEX: the three globals are replaced by the importer's ROWID in P0_PAGE_PK.
    PROCEDURE IMPR_NBR_WHEN_VALIDATE_ITEM (P_PORT_CD  IN     NUMBER,
                                           P_IMPR_NBR IN     NUMBER,
                                           P_PAGE_PK    IN OUT VARCHAR2)
    IS
    BEGIN
        CHECK_ERROR(IMPR_NBR_VALIDATION(P_PORT_CD, P_IMPR_NBR));
        IF P_IMPR_NBR IS NOT NULL THEN
            P_PAGE_PK := importer_row_id(P_PORT_CD, P_IMPR_NBR);
        END IF;
    END IMPR_NBR_WHEN_VALIDATE_ITEM;

    -- Source: block IMPORTERS, property Delete Allowed = false
    -- Forms: a delete in block IMPORTERS fails with FRM-41049 "You cannot delete this record".
    -- The page 0 toolbar shows DELETE whenever P0_PAGE_PK is set; suspensions are deleted in the grid.
    -- TODO: confirm the Arabic text of FRM-41049 used in production.
    PROCEDURE PRE_DELETE
    IS
    BEGIN
        FORMS_APX.FORM_TRIGGER_FAILURE('لا يمكن حذف بيانات المستورد من هذه الشاشة - احذف التوقيف من الجدول');
    END PRE_DELETE;

    -- =========================================================================
    -- BLOCK IMPR_SUSPN  (detail)
    -- =========================================================================
    -- Source: IMPR_SUSPN.WHEN-NEW-RECORD-INSTANCE (first block, "UPDATE BY ANAS 9-5-2005")
    -- Original Forms code:
    --   IF     :PARAMETER.Current_Side = 1 AND :PARAMETER.P_CURR_PORT_CD!=99 AND :IMPR_SUSPN.SUSPN_SIDE_CD <> 1 THEN
    --          NEXT_RECORD;
    --   ELSIF  :PARAMETER.Current_Side = 2 AND :PARAMETER.P_CURR_PORT_CD!=99 AND :IMPR_SUSPN.SUSPN_SIDE_CD IN(1,5) THEN
    --          NEXT_RECORD;
    --   ELSIF  :PARAMETER.Current_Side =3 AND :PARAMETER.P_CURR_PORT_CD=99 AND :IMPR_SUSPN.SUSPN_SIDE_CD !=5 THEN
    --          NEXT_RECORD;
    --   END IF;
    -- NEXT_RECORD makes the row unreachable -> the row is read only (it stays visible, as in Forms).
    FUNCTION IMPR_SUSPN_IS_READ_ONLY (SUSPN_SIDE_CD        IN NUMBER,
                                      P_CURRENT_SIDE IN NUMBER,
                                      P_CURR_PORT_CD       IN NUMBER) RETURN BOOLEAN
    IS
    BEGIN
        RETURN side_of_another_site(SUSPN_SIDE_CD, P_CURRENT_SIDE, P_CURR_PORT_CD);
    END IMPR_SUSPN_IS_READ_ONLY;

    -- Source: IMPR_SUSPN.SUSPN_STRT_DT.WHEN-NEW-ITEM-INSTANCE
    -- Original Forms code:
    --   IF :SUSPN_STRT_DT IS NULL THEN :SUSPN_STRT_DT := HIJDATE.Cur_Hij_date; END IF;
    FUNCTION SUSPN_STRT_DT_DEFAULT RETURN VARCHAR2
    IS
    BEGIN
        RETURN hijri_text(cur_hij_date);
    END SUSPN_STRT_DT_DEFAULT;

    -- Source: IMPR_SUSPN.SUSPN_STRT_DT.WHEN-VALIDATE-ITEM
    -- Original Forms code:
    --   IF NOT HIJDATE.VALID_HIJ_DATE(HDATE) THEN RAISE FORM_TRIGGER_FAILURE; END IF;
    --   IF HIJDATE.COMPARE_HIJ_DATES(:SUSPN_STRT_DT, HIJDATE.Cur_Hij_Date) = -1 THEN
    --     Ret := STR.DispArbMsg(9, 100,'ERROR');
    --     :SUSPN_STRT_DT := HIJDATE.Cur_Hij_Date;
    --     RAISE Form_trigger_failure;
    --   END IF;
    -- The reset of the value to today is UI (see the UI LOGIC section).
    -- An unchanged stored value is not validated again (Forms WVI fires only on change).
    FUNCTION SUSPN_STRT_DT_VALIDATION (SUSPN_STRT_DT IN VARCHAR2,
                                       PORT_CD       IN NUMBER,
                                       IMPR_NBR      IN NUMBER,
                                       SUSPN_SEQ     IN NUMBER) RETURN VARCHAR2
    IS
        v_err VARCHAR2(2000);
    BEGIN
        IF SUSPN_STRT_DT IS NULL
           OR SUSPN_STRT_DT = hijri_text(stored_suspension(PORT_CD, IMPR_NBR, SUSPN_SEQ).suspn_strt_dt) THEN
            RETURN NULL;
        END IF;
        v_err := hijri_date_error(SUSPN_STRT_DT);
        IF v_err IS NOT NULL THEN
            RETURN v_err;
        END IF;
        IF hijdate_db.compare_hij_dates(hijri_text_to_date(SUSPN_STRT_DT), cur_hij_date) = -1 THEN
            RETURN arabic_message(9, 100);
        END IF;
        RETURN NULL;
    END SUSPN_STRT_DT_VALIDATION;

    -- Source: IMPR_SUSPN.SUSPN_END_DT.WHEN-VALIDATE-ITEM
    -- Original Forms code:
    --   IF NOT HIJDATE.VALID_HIJ_DATE(HDATE) THEN RAISE FORM_TRIGGER_FAILURE; END IF;
    --   IF HIJDATE.COMPARE_HIJ_DATES(:SUSPN_END_DT, :SUSPN_STRT_DT) = -1 THEN
    --     Ret := STR.DispArbMsg(9, 110,'ERROR'); RAISE Form_trigger_failure;
    --   END IF;
    -- An unchanged stored value is not validated again (Forms WVI fires only on change).
    FUNCTION SUSPN_END_DT_VALIDATION (SUSPN_STRT_DT IN VARCHAR2,
                                      SUSPN_END_DT  IN VARCHAR2,
                                      PORT_CD       IN NUMBER,
                                      IMPR_NBR      IN NUMBER,
                                      SUSPN_SEQ     IN NUMBER) RETURN VARCHAR2
    IS
        v_err VARCHAR2(2000);
    BEGIN
        IF SUSPN_END_DT IS NULL
           OR SUSPN_END_DT = hijri_text(stored_suspension(PORT_CD, IMPR_NBR, SUSPN_SEQ).suspn_end_dt) THEN
            RETURN NULL;
        END IF;
        v_err := hijri_date_error(SUSPN_END_DT);
        IF v_err IS NOT NULL THEN
            RETURN v_err;
        END IF;
        -- HIJDATE.COMPARE_HIJ_DATES returns NULL when one date is NULL (CIC_LIB.pld)
        IF SUSPN_STRT_DT IS NOT NULL AND hijri_date_error(SUSPN_STRT_DT) IS NULL
           AND hijdate_db.compare_hij_dates(hijri_text_to_date(SUSPN_END_DT),
                                            hijri_text_to_date(SUSPN_STRT_DT)) = -1 THEN
            RETURN arabic_message(9, 110);
        END IF;
        RETURN NULL;
    END SUSPN_END_DT_VALIDATION;

    -- Source: IMPR_SUSPN.SUSPN_RSN_CD.WHEN-NEW-ITEM-INSTANCE
    -- Original Forms code:
    --   IF :IMPR_SUSPN.SUSPN_RSN_CD IS NULL THEN
    --     IF :PARAMETER.Current_Side = 1 AND :PARAMETER.P_CURR_PORT_CD!=99 THEN :IMPR_SUSPN.SUSPN_RSN_CD := 1;
    --     ELSIF :PARAMETER.Current_Side = 2 AND :PARAMETER.P_CURR_PORT_CD!=99 THEN :IMPR_SUSPN.SUSPN_RSN_CD := 2;
    --     ELSIF :PARAMETER.Current_Side = 3 AND :PARAMETER.P_CURR_PORT_CD=99 THEN :IMPR_SUSPN.SUSPN_RSN_CD := 3;
    --     END IF;
    --   END IF;
    FUNCTION SUSPN_RSN_CD_DEFAULT (P_CURRENT_SIDE IN NUMBER,
                                   P_CURR_PORT_CD       IN NUMBER) RETURN NUMBER
    IS
    BEGIN
        IF P_CURRENT_SIDE = 1 AND P_CURR_PORT_CD <> c_head_office_port THEN
            RETURN 1;
        ELSIF P_CURRENT_SIDE = 2 AND P_CURR_PORT_CD <> c_head_office_port THEN
            RETURN 2;
        ELSIF P_CURRENT_SIDE = 3 AND P_CURR_PORT_CD = c_head_office_port THEN
            RETURN 3;
        END IF;
        RETURN NULL;
    END SUSPN_RSN_CD_DEFAULT;

    -- Source: IMPR_SUSPN.SUSPN_RSN_CD.WHEN-VALIDATE-ITEM (checks)
    -- Original Forms code:
    --   IF :IMPR_SUSPN.SUSPN_RSN_CD IS NOT NULL THEN
    --     IF :PARAMETER.Current_Side = 1 AND :IMPR_SUSPN.SUSPN_RSN_CD = 2 THEN
    --       :IMPR_SUSPN.SUSPN_RSN_CD := 1; RAISE Form_Trigger_Failure;
    --     ELSIF :PARAMETER.Current_Side = 2 AND :IMPR_SUSPN.SUSPN_RSN_CD =1 THEN
    --       :IMPR_SUSPN.SUSPN_RSN_CD := 2; RAISE Form_Trigger_Failure;
    --     ELSIF :PARAMETER.Current_Side =3 AND :IMPR_SUSPN.SUSPN_RSN_CD IN(1,2) THEN
    --       :IMPR_SUSPN.SUSPN_RSN_CD := 3; RAISE Form_Trigger_Failure;
    --     END IF;
    --     (SUSPN_RSN_TEXT from CG_REF_CODES - see SUSPN_RSN_CD_VALIDATE_ITEM)
    --   ELSE
    --     RAISE FORM_TRIGGER_FAILURE;
    --   END IF;
    -- Forms gave no message; the reset to the site's reason is UI (default value of the column).
    -- An unchanged stored value is not validated again (Forms WVI fires only on change).
    FUNCTION SUSPN_RSN_CD_VALIDATION (SUSPN_RSN_CD         IN NUMBER,
                                      P_CURRENT_SIDE IN NUMBER,
                                      PORT_CD              IN NUMBER,
                                      IMPR_NBR             IN NUMBER,
                                      SUSPN_SEQ            IN NUMBER) RETURN VARCHAR2
    IS
    BEGIN
        IF SUSPN_RSN_CD IS NULL THEN
            RETURN REQUIRED_VALIDATION(NULL, 'السبب');
        END IF;
        IF SUSPN_RSN_CD = stored_suspension(PORT_CD, IMPR_NBR, SUSPN_SEQ).suspn_rsn_cd THEN
            RETURN NULL;
        END IF;
        IF    (P_CURRENT_SIDE = 1 AND SUSPN_RSN_CD = 2)
           OR (P_CURRENT_SIDE = 2 AND SUSPN_RSN_CD = 1)
           OR (P_CURRENT_SIDE = 3 AND SUSPN_RSN_CD IN (1, 2)) THEN
            RETURN c_msg_reason_not_allowed;
        END IF;
        RETURN NULL;
    END SUSPN_RSN_CD_VALIDATION;

    -- Source: IMPR_SUSPN.SUSPN_RSN_CD.WHEN-VALIDATE-ITEM (derived value)
    -- Original Forms code (after the checks):
    --   SELECT RV_MEANING INTO :IMPR_SUSPN.SUSPN_RSN_TEXT FROM CG_REF_CODES
    --    WHERE RV_DOMAIN = 'IMPR_SUSPN_RSN_CD' AND RV_LOW_VALUE = TO_CHAR(:IMPR_SUSPN.SUSPN_RSN_CD);
    -- An unknown code raised NO_DATA_FOUND in Forms; it is kept as an error here.
    PROCEDURE SUSPN_RSN_CD_VALIDATE_ITEM (SUSPN_RSN_CD         IN     NUMBER,
                                          P_CURRENT_SIDE IN     NUMBER,
                                          PORT_CD              IN     NUMBER,
                                          IMPR_NBR             IN     NUMBER,
                                          SUSPN_SEQ            IN     NUMBER,
                                          SUSPN_RSN_TEXT      IN OUT VARCHAR2)
    IS
    BEGIN
        CHECK_ERROR(SUSPN_RSN_CD_VALIDATION(SUSPN_RSN_CD, P_CURRENT_SIDE,
                                            PORT_CD, IMPR_NBR, SUSPN_SEQ));
        SELECT c.rv_meaning
          INTO SUSPN_RSN_CD_VALIDATE_ITEM.SUSPN_RSN_TEXT
          FROM cg_ref_codes c
         WHERE c.rv_domain    = 'IMPR_SUSPN_RSN_CD'
           AND c.rv_low_value = TO_CHAR(SUSPN_RSN_CD_VALIDATE_ITEM.SUSPN_RSN_CD);
    END SUSPN_RSN_CD_VALIDATE_ITEM;

    -- Source: IMPR_SUSPN.SUSPN_RSN_CD.WHEN-NEW-ITEM-INSTANCE (default code) followed by
    --         SUSPN_RSN_CD.WHEN-VALIDATE-ITEM (SUSPN_RSN_TEXT := its CG_REF_CODES meaning)
    -- NULL when the site has no default reason or the code has no meaning.
    FUNCTION SUSPN_RSN_TEXT_DEFAULT (P_CURRENT_SIDE IN NUMBER,
                                     P_CURR_PORT_CD       IN NUMBER) RETURN VARCHAR2
    IS
        v_text cg_ref_codes.rv_meaning%TYPE;
    BEGIN
        SELECT MAX(c.rv_meaning)
          INTO v_text
          FROM cg_ref_codes c
         WHERE c.rv_domain    = 'IMPR_SUSPN_RSN_CD'
           AND c.rv_low_value = TO_CHAR(SUSPN_RSN_CD_DEFAULT(SUSPN_RSN_TEXT_DEFAULT.P_CURRENT_SIDE, SUSPN_RSN_TEXT_DEFAULT.P_CURR_PORT_CD));
        RETURN v_text;
    END SUSPN_RSN_TEXT_DEFAULT;

    -- Source: IMPR_SUSPN.SUSPN_SIDE_CD.WHEN-NEW-ITEM-INSTANCE
    -- Original Forms code:
    --   IF :IMPR_SUSPN.SUSPN_SIDE_CD IS NULL THEN
    --     IF :PARAMETER.Current_Side = 1 AND :PARAMETER.P_CURR_PORT_CD!=99 THEN :IMPR_SUSPN.SUSPN_SIDE_CD := 1;
    --     ELSIF :PARAMETER.Current_Side = 2 AND :PARAMETER.P_CURR_PORT_CD!=99 THEN :IMPR_SUSPN.SUSPN_SIDE_CD := 2;
    --     ELSIF :PARAMETER.Current_Side = 3 AND :PARAMETER.P_CURR_PORT_CD=99 THEN :IMPR_SUSPN.SUSPN_SIDE_CD := 5;
    --     END IF;
    --   END IF;
    FUNCTION SUSPN_SIDE_CD_DEFAULT (P_CURRENT_SIDE IN NUMBER,
                                    P_CURR_PORT_CD       IN NUMBER) RETURN NUMBER
    IS
    BEGIN
        IF P_CURRENT_SIDE = 1 AND P_CURR_PORT_CD <> c_head_office_port THEN
            RETURN 1;
        ELSIF P_CURRENT_SIDE = 2 AND P_CURR_PORT_CD <> c_head_office_port THEN
            RETURN 2;
        ELSIF P_CURRENT_SIDE = 3 AND P_CURR_PORT_CD = c_head_office_port THEN
            RETURN 5;
        END IF;
        RETURN NULL;
    END SUSPN_SIDE_CD_DEFAULT;

    -- Source: IMPR_SUSPN.SUSPN_SIDE_CD.WHEN-LIST-CHANGED and WHEN-VALIDATE-ITEM
    -- Original Forms code (WHEN-LIST-CHANGED):
    --   IF :PARAMETER.Current_Side = 1 AND :PARAMETER.P_CURR_PORT_CD!=99 AND :IMPR_SUSPN.SUSPN_SIDE_CD <> 1 THEN
    --     :IMPR_SUSPN.SUSPN_SIDE_CD := 1; RAISE Form_Trigger_Failure;
    --   ELSIF :PARAMETER.Current_Side = 2 AND :PARAMETER.P_CURR_PORT_CD!=99 AND :IMPR_SUSPN.SUSPN_SIDE_CD IN (1,5) THEN
    --     :IMPR_SUSPN.SUSPN_SIDE_CD := 2; RAISE Form_Trigger_Failure;
    --   ELSIF :PARAMETER.Current_Side = 3 AND :PARAMETER.P_CURR_PORT_CD=99 AND :IMPR_SUSPN.SUSPN_SIDE_CD !=5 THEN
    --     :IMPR_SUSPN.SUSPN_SIDE_CD := 5; RAISE Form_Trigger_Failure;
    --   END IF;
    -- Original Forms code (WHEN-VALIDATE-ITEM):
    --   IF :IMPR_SUSPN.SUSPN_SIDE_CD IS NULL THEN RAISE FORM_TRIGGER_FAILURE; END IF;
    -- An unchanged stored value is not validated again (Forms WVI / WLC fire only on change).
    FUNCTION SUSPN_SIDE_CD_VALIDATION (SUSPN_SIDE_CD        IN NUMBER,
                                       P_CURRENT_SIDE IN NUMBER,
                                       P_CURR_PORT_CD       IN NUMBER,
                                       PORT_CD              IN NUMBER,
                                       IMPR_NBR             IN NUMBER,
                                       SUSPN_SEQ            IN NUMBER) RETURN VARCHAR2
    IS
    BEGIN
        IF SUSPN_SIDE_CD IS NULL THEN
            RETURN REQUIRED_VALIDATION(NULL, 'الجهة');
        END IF;
        IF SUSPN_SIDE_CD = stored_suspension(PORT_CD, IMPR_NBR, SUSPN_SEQ).suspn_side_cd THEN
            RETURN NULL;
        END IF;
        IF side_of_another_site(SUSPN_SIDE_CD, P_CURRENT_SIDE, P_CURR_PORT_CD) THEN
            RETURN c_msg_side_not_allowed;
        END IF;
        RETURN NULL;
    END SUSPN_SIDE_CD_VALIDATION;

    -- Source: IMPR_SUSPN.WHEN-NEW-RECORD-INSTANCE (second block, "ADDED BY ABDALLAH"), with the
    --         same rule in IMPR_SUSPN.POST-QUERY and POST-INSERT
    -- Original Forms code:
    --   SELECT SUSPN_SIDE_CD INTO V_SUSPN_SIDE_CD FROM IMPR_SUSPNS
    --    WHERE PORT_CD = :IMPR_SUSPN.PORT_CD AND IMPR_NBR = :IMPR_SUSPN.IMPR_NBR
    --      AND SUSPN_SEQ = :IMPR_SUSPN.SUSPN_SEQ;   (NO_DATA_FOUND -> NULL)
    --   IF V_SUSPN_SIDE_CD IS NOT NULL THEN
    --     GO_ITEM('IMPR_SUSPN.SUSPN_STRT_DT');
    --     SET_ITEM_PROPERTY('IMPR_SUSPN.SUSPN_SIDE_CD', ENABLED, PROPERTY_FALSE);
    --   ELSE
    --     SET_ITEM_PROPERTY('IMPR_SUSPN.SUSPN_SIDE_CD', ENABLED, PROPERTY_TRUE); (+ NAVIGABLE)
    --   END IF;
    FUNCTION SUSPN_SIDE_CD_IS_READ_ONLY (PORT_CD   IN NUMBER,
                                         IMPR_NBR  IN NUMBER,
                                         SUSPN_SEQ IN NUMBER) RETURN BOOLEAN
    IS
        v_side_cd impr_suspns.suspn_side_cd%TYPE;
    BEGIN
        SELECT MAX(s.suspn_side_cd)
          INTO v_side_cd
          FROM impr_suspns s
         WHERE s.port_cd   = SUSPN_SIDE_CD_IS_READ_ONLY.PORT_CD
           AND s.impr_nbr  = SUSPN_SIDE_CD_IS_READ_ONLY.IMPR_NBR
           AND s.suspn_seq = SUSPN_SIDE_CD_IS_READ_ONLY.SUSPN_SEQ;
        RETURN v_side_cd IS NOT NULL;
    END SUSPN_SIDE_CD_IS_READ_ONLY;

    -- Source: IMPR_SUSPN.PRE-INSERT
    -- Original Forms code:
    --   IF (:IMPR_SUSPN.SUSPN_SEQ) IS NULL THEN
    --     SELECT MAX(IMPR_SUSPNS.SUSPN_SEQ) + 1 INTO :IMPR_SUSPN.SUSPN_SEQ FROM IMPR_SUSPNS;
    --     IF :IMPR_SUSPN.SUSPN_SEQ IS NULL THEN :IMPR_SUSPN.SUSPN_SEQ := 1; END IF;
    --   END IF;
    --   IF NOT ACTIVITY.ADD_ACTIVITY(9, 3, 1, :IMPR_SUSPN.PORT_CD||'!'||:IMPR_SUSPN.IMPR_NBR||'!'||:IMPR_SUSPN.SUSPN_SEQ) THEN
    --     RAISE FORm_Trigger_Failure;
    --   END IF;
    -- SUGGESTION: MAX + 1 over the whole table is not safe when two users save at the same time;
    --             a sequence needs a migration script and a decision (inventory §15 #5).
    PROCEDURE IMPR_SUSPN_PRE_INSERT (SUSPN_SEQ        IN OUT NUMBER,
                                     PORT_CD           IN     NUMBER,
                                     IMPR_NBR          IN     NUMBER,
                                     P_CURR_PORT_CD    IN     NUMBER,
                                     SSO_APP_USER      IN     VARCHAR2,
                                     P_GLOBAL_V_WS_ID  IN     VARCHAR2)
    IS
    BEGIN
        IF SUSPN_SEQ IS NULL THEN
            SELECT NVL(MAX(s.suspn_seq) + 1, 1)
              INTO IMPR_SUSPN_PRE_INSERT.SUSPN_SEQ
              FROM impr_suspns s;
        END IF;
        add_activity(c_activity_insert, PORT_CD, IMPR_NBR, SUSPN_SEQ,
                     P_CURR_PORT_CD, SSO_APP_USER, P_GLOBAL_V_WS_ID);
    END IMPR_SUSPN_PRE_INSERT;

    -- Source: IMPR_SUSPN.POST-INSERT (CR-8414)
    -- Original Forms code (first block; the second block is the SUSPN_SIDE_CD enabling rule):
    --   V_ORG_HOTLINE := 19993; V_ORG_NAME := 'https://zatca.gov.sa';
    --   SELECT MOBILE_NO INTO V_MOBILE_NBR FROM IMPORTER_BASIC_DATA
    --    WHERE HQ_IMPR_NBR = :HQ_IMPR_NBR AND ROWNUM=1 AND MOBILE_NO IS NOT NULL;
    --   IF NVL(gnrl.get_customs_setting(:IMPR_SUSPN.PORT_CD ,'NE_INTEGRATION', 21), 0) = 1 THEN
    --     V_NE_IN_SEND := 'P_PORT_NAME=' || :PORT_NAME || ',P_BUS_ID=' || :BUS_ID
    --       || ',P_SUSPN_STRT_DT=' || TO_CHAR(:SUSPN_STRT_DT,'MI-MM-YYYY')
    --       || ',P_SUSPN_END_DT=' || TO_CHAR(:SUSPN_END_DT,'MI-MM-YYYY')
    --       || ',P_SUSPN_RSN_TEXT=' || :SUSPN_RSN_TEXT || ',ORG_HOTLINE=' || V_ORG_HOTLINE
    --       || ',ORG_NAME=' || V_ORG_NAME;
    --     LIB_APX_USR.APEX_NOTIFICATIONS.SEND_SMS_EMAIL_NOTIFY(PORT_CODE => :PARAMETER.P_CURR_PORT_CD,
    --       EVENT_CODE => 'IMPR_010', TO_EMAIL => NULL, TO_MOBILE_NO => V_MOBILE_NBR, TO_ID_NO => :BUS_ID,
    --       RECIPIENT_TYPE => var_RECIPIENT_TYPE, NOTE_PRIORITY => var_NOTE_PRIORITY, MESSAGE_LANGUAGE => NULL,
    --       VARIABLES => V_NE_IN_SEND, JSON_ATTACH => NULL, ATTACH_TYPE => NULL, ATTACH_NAME => NULL,
    --       ATTACH_CATEGORY => NULL, STATUS => var_STATUS, P_MESSAGE => var_P_MESSAGE);
    --   ELSE
    --     V_SMS_MSG_BODY := ' تم الايقاف من قبل '||:PORT_NAME||' للسجل التجاري '||:BUS_ID||
    --       ' من تاريخ '||TO_CHAR(:SUSPN_STRT_DT,'MI-MM-YYYY')||' الى تاريخ '||TO_CHAR(:SUSPN_END_DT,'MI-MM-YYYY')||
    --       ' بسبب '||:SUSPN_RSN_TEXT;
    --     SMS_MESSAGE.SEND_SMS_MESSAGE(9,3,1,:PARAMETER.P_CURR_PORT_CD,NULL,V_MOBILE_NBR,
    --       V_SMS_MSG_BODY,:IMPR_SUSPN.PORT_CD||'|'||:IMPR_SUSPN.IMPR_NBR||'|'||:IMPR_SUSPN.SUSPN_SEQ);
    --   END IF;
    --   STANDARD.COMMIT;
    --   EXCEPTION WHEN OTHERS THEN NULL;
    -- STANDARD.COMMIT is removed (HIGH, extraction report): APEX commits at the end of the request.
    -- WHEN OTHERS THEN NULL is kept (preserve behaviour): no mobile number or a failing send is ignored.
    -- SUGGESTION: log the error instead of ignoring it (inventory §15 #4).
    -- :PORT_NAME, :BUS_ID, :HQ_IMPR_NBR are items of the master block IMPORTERS.
    -- TODO: MISSING SOURCE GNRL, SMS_MESSAGE, LIB_APX_USR.APEX_NOTIFICATIONS (calls copied as in Forms).
    PROCEDURE IMPR_SUSPN_POST_INSERT (PORT_CD           IN NUMBER,
                                      IMPR_NBR          IN NUMBER,
                                      SUSPN_SEQ         IN NUMBER,
                                      SUSPN_STRT_DT     IN VARCHAR2,
                                      SUSPN_END_DT      IN VARCHAR2,
                                      SUSPN_RSN_TEXT    IN VARCHAR2,
                                      P_HQ_IMPR_NBR IN NUMBER,
                                      P_PORT_NAME   IN VARCHAR2,
                                      P_BUS_ID      IN VARCHAR2,
                                      P_CURR_PORT_CD    IN NUMBER)
    IS
        v_mobile_nbr       NUMBER;
        v_sms_msg_body     VARCHAR2(2000);
        v_recipient_type   NUMBER;
        v_note_priority    VARCHAR2(32767);
        v_status           NUMBER;
        v_message          VARCHAR2(32767);
        v_ne_in_send       VARCHAR2(4000);
        c_org_hotline      CONSTANT NUMBER        := 19993;
        c_org_name         CONSTANT VARCHAR2(500) := 'https://zatca.gov.sa';
    BEGIN
        SELECT b.mobile_no
          INTO v_mobile_nbr
          FROM importer_basic_data b
         WHERE b.hq_impr_nbr = IMPR_SUSPN_POST_INSERT.P_HQ_IMPR_NBR
           AND ROWNUM = 1
           AND b.mobile_no IS NOT NULL;

        IF NVL(gnrl.get_customs_setting(PORT_CD, 'NE_INTEGRATION', 21), 0) = 1 THEN
            v_ne_in_send :=    'P_PORT_NAME='       || P_PORT_NAME
                            || ',P_BUS_ID='         || P_BUS_ID
                            || ',P_SUSPN_STRT_DT='  || TO_CHAR(hijri_text_to_date(SUSPN_STRT_DT), 'MI-MM-YYYY')
                            || ',P_SUSPN_END_DT='   || TO_CHAR(hijri_text_to_date(SUSPN_END_DT), 'MI-MM-YYYY')
                            || ',P_SUSPN_RSN_TEXT=' || SUSPN_RSN_TEXT
                            || ',ORG_HOTLINE='      || c_org_hotline
                            || ',ORG_NAME='         || c_org_name;
            LIB_APX_USR.APEX_NOTIFICATIONS.SEND_SMS_EMAIL_NOTIFY(
                PORT_CODE        => P_CURR_PORT_CD,
                EVENT_CODE       => 'IMPR_010',
                TO_EMAIL         => NULL,
                TO_MOBILE_NO     => v_mobile_nbr,
                TO_ID_NO         => P_BUS_ID,
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
            v_sms_msg_body :=    ' تم الايقاف من قبل ' || P_PORT_NAME
                              || ' للسجل التجاري '     || P_BUS_ID
                              || ' من تاريخ '          || TO_CHAR(hijri_text_to_date(SUSPN_STRT_DT), 'MI-MM-YYYY')
                              || ' الى تاريخ '         || TO_CHAR(hijri_text_to_date(SUSPN_END_DT), 'MI-MM-YYYY')
                              || ' بسبب '              || SUSPN_RSN_TEXT;
            sms_message.send_sms_message(9, 3, 1, P_CURR_PORT_CD, NULL, v_mobile_nbr, v_sms_msg_body,
                                         PORT_CD || '|' || IMPR_NBR || '|' || SUSPN_SEQ);
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            NULL;                                           -- as in Forms (see the header comment)
    END IMPR_SUSPN_POST_INSERT;

    -- Source: IMPR_SUSPN.PRE-UPDATE
    -- Original Forms code:
    --   IF NOT ACTIVITY.ADD_ACTIVITY(9, 3, 2, :IMPR_SUSPN.PORT_CD||'!'||:IMPR_SUSPN.IMPR_NBR||'!'||:IMPR_SUSPN.SUSPN_SEQ) THEN
    --     RAISE FORm_Trigger_Failure;
    --   END IF;
    --   h_date := hijdate_db.cur_hij_date;
    --   IF :impr_suspn.suspn_end_dt <= h_date THEN :impr_suspn.suspn_rlse_dt := :impr_suspn.suspn_end_dt; END IF;
    --   IF :impr_suspn.suspn_end_dt >  h_date THEN :impr_suspn.suspn_rlse_dt := NULL; END IF;
    --   EXCEPTION WHEN OTHERS THEN NULL;   (second block only)
    -- check_row_of_current_site: server-side counterpart of WHEN-NEW-RECORD-INSTANCE (NEXT_RECORD).
    PROCEDURE IMPR_SUSPN_PRE_UPDATE (PORT_CD              IN     NUMBER,
                                     IMPR_NBR             IN     NUMBER,
                                     SUSPN_SEQ            IN     NUMBER,
                                     SUSPN_END_DT         IN     VARCHAR2,
                                     SUSPN_RLSE_DT       IN OUT VARCHAR2,
                                     P_CURRENT_SIDE IN     NUMBER,
                                     P_CURR_PORT_CD       IN     NUMBER,
                                     SSO_APP_USER         IN     VARCHAR2,
                                     P_GLOBAL_V_WS_ID     IN     VARCHAR2)
    IS
        v_today  DATE;
        v_end_dt DATE;
    BEGIN
        check_row_of_current_site(PORT_CD, IMPR_NBR, SUSPN_SEQ,
                                  P_CURRENT_SIDE, P_CURR_PORT_CD);
        add_activity(c_activity_update, PORT_CD, IMPR_NBR, SUSPN_SEQ,
                     P_CURR_PORT_CD, SSO_APP_USER, P_GLOBAL_V_WS_ID);
        BEGIN
            v_today  := hijdate_db.cur_hij_date;
            v_end_dt := TO_DATE(SUSPN_END_DT, c_date_mask);
            IF v_end_dt <= v_today THEN
                SUSPN_RLSE_DT := hijri_text(v_end_dt);
            END IF;
            IF v_end_dt > v_today THEN
                SUSPN_RLSE_DT := NULL;
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                NULL;                                       -- as in Forms
        END;
    END IMPR_SUSPN_PRE_UPDATE;

    -- Source: IMPR_SUSPN.ON-DELETE (+ IMPR_SUSPN.KEY-DELREC -> TMPLT.KEY_DELETE_RECORD)
    -- Original Forms code:
    --   HDATE := HIJDATE.CUR_HIJ_DATE;
    --   UPDATE IMPR_SUSPNS SET IMPR_SUSPNS.SUSPN_RLSE_DT = HDATE
    --    WHERE IMPR_SUSPNS.IMPR_NBR = :IMPR_SUSPN.IMPR_NBR
    --      AND IMPR_SUSPNS.SUSPN_SEQ = :IMPR_SUSPN.SUSPN_SEQ;
    --   IF NOT ACTIVITY.ADD_ACTIVITY(9, 3, 3, :IMPR_SUSPN.PORT_CD||'!'||:IMPR_SUSPN.IMPR_NBR||'!'||:IMPR_SUSPN.SUSPN_SEQ) THEN
    --     RAISE FORm_Trigger_Failure;
    --   END IF;
    -- The WHERE clause has no PORT_CD, as in Forms (SUSPN_SEQ is unique over the whole table).
    -- SUGGESTION: add AND PORT_CD = PORT_CD.
    -- KEY_DELETE_RECORD's confirm "هل أنت متأكد من عملية الحذف" and its COMMIT -> APEX (confirm, commit).
    PROCEDURE IMPR_SUSPN_ON_DELETE (PORT_CD              IN NUMBER,
                                    IMPR_NBR             IN NUMBER,
                                    SUSPN_SEQ            IN NUMBER,
                                    P_CURRENT_SIDE IN NUMBER,
                                    P_CURR_PORT_CD       IN NUMBER,
                                    SSO_APP_USER         IN VARCHAR2,
                                    P_GLOBAL_V_WS_ID     IN VARCHAR2)
    IS
        v_today DATE;
    BEGIN
        check_row_of_current_site(PORT_CD, IMPR_NBR, SUSPN_SEQ,
                                  P_CURRENT_SIDE, P_CURR_PORT_CD);
        v_today := cur_hij_date;
        UPDATE impr_suspns s
           SET s.suspn_rlse_dt = v_today
         WHERE s.impr_nbr  = IMPR_SUSPN_ON_DELETE.IMPR_NBR
           AND s.suspn_seq = IMPR_SUSPN_ON_DELETE.SUSPN_SEQ;
        add_activity(c_activity_delete, PORT_CD, IMPR_NBR, SUSPN_SEQ,
                     P_CURR_PORT_CD, SSO_APP_USER, P_GLOBAL_V_WS_ID);
    END IMPR_SUSPN_ON_DELETE;

    -- Source: Forms transaction processing of block IMPR_SUSPN (default INSERT / UPDATE of the base
    --         table IMPR_SUSPNS, ON-DELETE instead of DELETE), one row at a time as Forms posts them:
    --           C: PRE-INSERT -> INSERT -> POST-INSERT
    --           U: PRE-UPDATE -> UPDATE (columns with Update Allowed: dates, reason, side, release date)
    --           D: ON-DELETE (soft delete)
    -- Why one member: PRE-INSERT's MAX + 1 needs the previous new row already inserted, and the native
    --         IG DML would really DELETE a row. Forms locks the row before UPDATE (default locking);
    --         here the UPDATE uses the primary key IS_1_PK (PORT_CD, IMPR_NBR, SUSPN_SEQ).
    -- TODO  : lost-update check (the native IG DML compares a row checksum) - decide in step 04.
    PROCEDURE IMPR_SUSPN_SAVE_ROW (APEX$ROW_STATUS      IN     VARCHAR2,
                                   PORT_CD              IN     NUMBER,
                                   IMPR_NBR             IN     NUMBER,
                                   SUSPN_SEQ           IN OUT NUMBER,
                                   SUSPN_STRT_DT        IN     VARCHAR2,
                                   SUSPN_END_DT         IN     VARCHAR2,
                                   SUSPN_RSN_CD         IN     NUMBER,
                                   SUSPN_RSN_TEXT       IN     VARCHAR2,
                                   SUSPN_SIDE_CD        IN     NUMBER,
                                   P_HQ_IMPR_NBR    IN     NUMBER,
                                   P_PORT_NAME      IN     VARCHAR2,
                                   P_BUS_ID         IN     VARCHAR2,
                                   P_CURRENT_SIDE IN     NUMBER,
                                   P_CURR_PORT_CD       IN     NUMBER,
                                   SSO_APP_USER         IN     VARCHAR2,
                                   P_GLOBAL_V_WS_ID     IN     VARCHAR2)
    IS
        v_rlse_dt VARCHAR2(10);
        -- The Hijri texts are converted here, in PL/SQL: a private package function (hijri_text_to_date)
        -- cannot be called inside a SQL statement (ORA-00904 / PLS-00231).
        v_strt_dt DATE;
        v_end_dt  DATE;
        v_rlse    DATE;
    BEGIN
        IF APEX$ROW_STATUS = 'C' THEN
            IMPR_SUSPN_PRE_INSERT(SUSPN_SEQ, PORT_CD, IMPR_NBR,
                                  P_CURR_PORT_CD, SSO_APP_USER, P_GLOBAL_V_WS_ID);
            v_strt_dt := hijri_text_to_date(SUSPN_STRT_DT);
            v_end_dt  := hijri_text_to_date(SUSPN_END_DT);
            INSERT INTO impr_suspns (port_cd, impr_nbr, suspn_seq, suspn_strt_dt, suspn_end_dt,
                                     suspn_rsn_cd, suspn_rsn_text, suspn_side_cd, suspn_rlse_dt)
            VALUES (IMPR_SUSPN_SAVE_ROW.PORT_CD, IMPR_SUSPN_SAVE_ROW.IMPR_NBR, IMPR_SUSPN_SAVE_ROW.SUSPN_SEQ, v_strt_dt,
                    v_end_dt, IMPR_SUSPN_SAVE_ROW.SUSPN_RSN_CD, IMPR_SUSPN_SAVE_ROW.SUSPN_RSN_TEXT, IMPR_SUSPN_SAVE_ROW.SUSPN_SIDE_CD, NULL);
            IMPR_SUSPN_POST_INSERT(PORT_CD, IMPR_NBR, SUSPN_SEQ, SUSPN_STRT_DT, SUSPN_END_DT,
                                   SUSPN_RSN_TEXT, P_HQ_IMPR_NBR, P_PORT_NAME,
                                   P_BUS_ID, P_CURR_PORT_CD);
        ELSIF APEX$ROW_STATUS = 'U' THEN
            v_rlse_dt := hijri_text(stored_suspension(PORT_CD, IMPR_NBR, SUSPN_SEQ).suspn_rlse_dt);
            IMPR_SUSPN_PRE_UPDATE(PORT_CD, IMPR_NBR, SUSPN_SEQ, SUSPN_END_DT, v_rlse_dt,
                                  P_CURRENT_SIDE, P_CURR_PORT_CD, SSO_APP_USER, P_GLOBAL_V_WS_ID);
            v_strt_dt := hijri_text_to_date(SUSPN_STRT_DT);
            v_end_dt  := hijri_text_to_date(SUSPN_END_DT);
            v_rlse    := hijri_text_to_date(v_rlse_dt);
            UPDATE impr_suspns s
               SET s.suspn_strt_dt  = v_strt_dt,
                   s.suspn_end_dt   = v_end_dt,
                   s.suspn_rsn_cd   = IMPR_SUSPN_SAVE_ROW.SUSPN_RSN_CD,
                   s.suspn_rsn_text = IMPR_SUSPN_SAVE_ROW.SUSPN_RSN_TEXT,
                   s.suspn_side_cd  = IMPR_SUSPN_SAVE_ROW.SUSPN_SIDE_CD,
                   s.suspn_rlse_dt  = v_rlse
             WHERE s.port_cd   = IMPR_SUSPN_SAVE_ROW.PORT_CD
               AND s.impr_nbr  = IMPR_SUSPN_SAVE_ROW.IMPR_NBR
               AND s.suspn_seq = IMPR_SUSPN_SAVE_ROW.SUSPN_SEQ;
        ELSIF APEX$ROW_STATUS = 'D' THEN
            IMPR_SUSPN_ON_DELETE(PORT_CD, IMPR_NBR, SUSPN_SEQ, P_CURRENT_SIDE,
                                 P_CURR_PORT_CD, SSO_APP_USER, P_GLOBAL_V_WS_ID);
        END IF;
    END IMPR_SUSPN_SAVE_ROW;

    -- =========================================================================
    -- PROGRAM UNITS   (same names as in the Forms Program Units node)
    -- =========================================================================
    -- Source: PU CGFK$QRY_IMPORTERS_IMP_SDP_FK (Designer)
    PROCEDURE CGFK$QRY_IMPORTERS_IMP_SDP_FK (p_sdp_port_status IN OUT NUMBER,
                                             p_port_name       IN OUT VARCHAR2,
                                             p_port_cd         IN     NUMBER)
    IS
    BEGIN
        SELECT sdp.port_name, sdp.port_status
          INTO p_port_name, p_sdp_port_status
          FROM sd_ports sdp
         WHERE sdp.port_cd = p_port_cd
           AND ROWNUM = 1;                                  -- Forms: OPEN / FETCH first row
    END CGFK$QRY_IMPORTERS_IMP_SDP_FK;

    -- Source: PU CGFK$QRY_IMPORTERS_IMP_ITIDT_F (Designer)
    PROCEDURE CGFK$QRY_IMPORTERS_IMP_ITIDT_F (p_bus_id_type_name IN OUT VARCHAR2,
                                              p_impr_type_name   IN OUT VARCHAR2,
                                              p_status           IN OUT NUMBER,
                                              p_impr_type_cd     IN     NUMBER,
                                              p_bus_id_type_cd   IN     NUMBER)
    IS
    BEGIN
        SELECT itidt.status, it.impr_type_name, bit.bus_id_type_name
          INTO p_status, p_impr_type_name, p_bus_id_type_name
          FROM impr_type_id_types itidt,
               impr_types         it,
               bus_id_types       bit
         WHERE (itidt.bus_id_type_cd = p_bus_id_type_cd
                OR (itidt.bus_id_type_cd IS NULL AND p_bus_id_type_cd IS NULL))
           AND itidt.impr_type_cd   = p_impr_type_cd
           AND it.impr_type_cd      = itidt.impr_type_cd
           AND bit.bus_id_type_cd   = itidt.bus_id_type_cd
           AND ROWNUM = 1;
    END CGFK$QRY_IMPORTERS_IMP_ITIDT_F;

    -- Source: PU CGFK$QRY_IMPORTERS_IMP_CTRY_FK (Designer)
    PROCEDURE CGFK$QRY_IMPORTERS_IMP_CTRY_FK (p_ctry_ctry_status IN OUT NUMBER,
                                              p_crty_arbc_name   IN OUT VARCHAR2,
                                              p_ctry_cd          IN     NUMBER)
    IS
    BEGIN
        SELECT ctry.crty_arbc_name, ctry.ctry_status
          INTO p_crty_arbc_name, p_ctry_ctry_status
          FROM countries ctry
         WHERE ctry.ctry_cd = p_ctry_cd
           AND ROWNUM = 1;
    END CGFK$QRY_IMPORTERS_IMP_CTRY_FK;

    -- Source: PU CGFK$QRY_IMPORTERS_IMP_BUS_ID_ (Designer)
    PROCEDURE CGFK$QRY_IMPORTERS_IMP_BUS_ID_ (p_id_city_name    IN OUT VARCHAR2,
                                              p_ctry_cd_of_id   IN     NUMBER,
                                              p_city_code_of_id IN     NUMBER)
    IS
    BEGIN
        SELECT l_ct.city_arb_name
          INTO p_id_city_name
          FROM cities l_ct
         WHERE (l_ct.city_cd = p_city_code_of_id
                OR (l_ct.city_cd IS NULL AND p_city_code_of_id IS NULL))
           AND (l_ct.ctry_cd = p_ctry_cd_of_id
                OR (l_ct.ctry_cd IS NULL AND p_ctry_cd_of_id IS NULL))
           AND ROWNUM = 1;
    END CGFK$QRY_IMPORTERS_IMP_BUS_ID_;

    -- =========================================================================
    -- UI LOGIC FOR APEX DYNAMIC ACTIONS  (comments only - no executable code)
    -- =========================================================================
    -- APEX-DA: [Source: IMPORTERS.IMPR_NBR.WHEN-VALIDATE-ITEM] -> DA "IMPR_NBR WHEN-VALIDATE-ITEM"
    -- Original : :global.Exec_Query_Now := 1;  (IMPR_TYPE_CD.WHEN-NEW-ITEM-INSTANCE: Clear_Block + execute_query)
    -- Implement: change of P1120_IMPR_NBR -> FOS IMPR1120.CHECK_ERROR(IMPR1120.IMPR_NBR_VALIDATION(
    --            P_PORT_CD => :P1120_PORT_CD, P_IMPR_NBR => :P1120_IMPR_NBR))
    --            -> Submit Page, request EXECUTE_QUERY (process "EXECUTE-QUERY" sets P0_PAGE_PK).
    --
    -- APEX-DA: [Source: IMPR1120.WHEN-NEW-FORM-INSTANCE] -> Read Only of P1120_PORT_CD / P112001_PORT_CD
    -- Original : SET_ITEM_PROPERTY('IMPORTERS.PORT_CD', INSERT_ALLOWED / UPDATE_ALLOWED, PROPERTY_TRUE) for port 99
    -- Implement: Read Only = PL/SQL Expression IMPR1120.PORT_CD_IS_READ_ONLY(P_CURR_PORT_CD => :P_CURR_PORT_CD)
    --
    -- APEX-DA: [Source: IMPORTERS items Insert / Update Allowed = false, 20 KEY-LISTVAL Designer checks]
    -- Implement: every P1120 IMPORTERS item is Read Only (Always) except P1120_IMPR_NBR while P0_PAGE_PK is null.
    --            LOV forms LOV_SD_PORTS / LOV_Impr_Type / LOV_COUNTRIES / LOV_CITIES -> popup LOVs on page 112001.
    --
    -- APEX-DA: [Source: IMPR_SUSPN.WHEN-NEW-RECORD-INSTANCE NEXT_RECORD] -> IG row read only
    -- Implement: every IG column Read Only, For Each Row, IMPR1120.IMPR_SUSPN_IS_READ_ONLY(:SUSPN_SIDE_CD,
    --            :P1120_P_CURRENT_SIDE, :P_CURR_PORT_CD); delete of such rows is refused by IMPR_SUSPN_ON_DELETE.
    --
    -- APEX-DA: [Source: IMPR_SUSPN.POST-QUERY / POST-INSERT / WHEN-NEW-RECORD-INSTANCE] -> column SUSPN_SIDE_CD read only
    -- Original : SET_ITEM_PROPERTY('IMPR_SUSPN.SUSPN_SIDE_CD', ENABLED, PROPERTY_FALSE) when a side is stored
    -- Implement: Read Only, For Each Row, IMPR1120.SUSPN_SIDE_CD_IS_READ_ONLY(:PORT_CD, :IMPR_NBR, :SUSPN_SEQ)
    --
    -- APEX-DA: [Source: IMPR_SUSPN.WHEN-NEW-RECORD-INSTANCE] GO_ITEM('IMPR_SUSPN.SUSPN_STRT_DT') -> dropped
    --            (the IG starts on the first column anyway).
    --
    -- APEX-DA: [Source: IMPR_SUSPN.SUSPN_STRT_DT.WHEN-VALIDATE-ITEM] -> DA "IMPR_SUSPN SUSPN_STRT_DT WHEN-VALIDATE-ITEM"
    -- Original : error 9-100 and :SUSPN_STRT_DT := HIJDATE.Cur_Hij_Date
    -- Implement: FOS IMPR1120.CHECK_ERROR(IMPR1120.SUSPN_STRT_DT_VALIDATION(:SUSPN_STRT_DT, :PORT_CD, :IMPR_NBR, :SUSPN_SEQ)).
    --            The reset to today is not repeated: the error keeps the user on the value (step 03 to confirm).
    --
    -- APEX-DA: [Source: IMPR_SUSPN.SUSPN_END_DT.WHEN-VALIDATE-ITEM] -> DA "IMPR_SUSPN SUSPN_END_DT WHEN-VALIDATE-ITEM"
    -- Implement: FOS IMPR1120.CHECK_ERROR(IMPR1120.SUSPN_END_DT_VALIDATION(:SUSPN_STRT_DT, :SUSPN_END_DT,
    --            :PORT_CD, :IMPR_NBR, :SUSPN_SEQ)).
    --
    -- APEX-DA: [Source: IMPR_SUSPN.SUSPN_RSN_CD.WHEN-VALIDATE-ITEM] -> DA "IMPR_SUSPN SUSPN_RSN_CD WHEN-VALIDATE-ITEM"
    -- Implement: FOS IMPR1120.SUSPN_RSN_CD_VALIDATE_ITEM(SUSPN_RSN_CD => :SUSPN_RSN_CD,
    --            P_CURRENT_SIDE => :P1120_P_CURRENT_SIDE, PORT_CD => :PORT_CD, IMPR_NBR => :IMPR_NBR,
    --            SUSPN_SEQ => :SUSPN_SEQ, SUSPN_RSN_TEXT => :SUSPN_RSN_TEXT),
    --            Items to Return SUSPN_RSN_TEXT. The Forms reset of the code to the site's reason is dropped.
    --
    -- APEX-DA: [Source: IMPR_SUSPN.SUSPN_SIDE_CD.WHEN-LIST-CHANGED] -> DA "IMPR_SUSPN SUSPN_SIDE_CD WHEN-LIST-CHANGED"
    -- Implement: FOS IMPR1120.CHECK_ERROR(IMPR1120.SUSPN_SIDE_CD_VALIDATION(:SUSPN_SIDE_CD,
    --            :P1120_P_CURRENT_SIDE, :P_CURR_PORT_CD, :PORT_CD, :IMPR_NBR, :SUSPN_SEQ)).
    --            The Forms reset of the value is dropped.
    --
    -- APEX-DA: [Source: IMPR_SUSPN.SUSPN_RSN_TEXT.WHEN-NEW-ITEM-INSTANCE] -> dropped (body is NULL; GO_ITEM commented out)
    --
    -- APEX-DA: [Source: IMPR_SUSPN.SUSPN_*_DT KEY-LISTVAL / KEY-F4 (INTRFACE.DISP_CALENDAR / DISP_DATE_CON)]
    -- Implement: IG Text Field columns holding the MI-MM-RRRR text (region SQL TO_CHAR), CSS class
    --            hijri-date-default (f345 Hijri picker), as IMPR1110.
    --
    -- APEX-DA: [Source: IMPR_SUSPN.KEY-DELREC -> TMPLT.KEY_DELETE_RECORD] -> IG row delete
    -- Original : STR.DispAlert('هل أنت متأكد من عملية الحذف','WARNING'); Delete_record; COMMIT;
    -- Implement: IG delete (native confirm with the same text); IMPR_SUSPN_SAVE_ROW -> IMPR_SUSPN_ON_DELETE
    --            does the soft delete. The page 0 DELETE (importer) is refused by PRE_DELETE.

END IMPR1120;
/
SHOW ERRORS
