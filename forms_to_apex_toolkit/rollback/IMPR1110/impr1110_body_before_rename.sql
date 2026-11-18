-- =============================================================================
-- Package body : IMPR1110  (APEX entry point of form IMPR1110 - f345 reference standard)
-- Author       : Claude Code
-- Created      : 2026-11-18
-- Version      : 1.0.0
-- Owner       : LIB_APX_USR (public synonym IMPR1110; EXECUTE granted to LIB_USR, SECURITY_DEFAULT, SECURITY_PROD, CUSTOMS)
-- Status       : NOT COMPILED.
-- Note         : no business logic here - every member delegates to pkg_impr1110_apx /
--                pkg_impr1110 (step 02). No COMMIT: APEX commits after page processing.
-- =============================================================================
SET DEFINE OFF

CREATE OR REPLACE PACKAGE BODY LIB_APX_USR.IMPR1110
AS
    c_err        CONSTANT PLS_INTEGER  := -20001;
    c_hero_title CONSTANT VARCHAR2(200) := 'إضافة وتعديل بيانات مستورد';

    -- validate one item on submit (Forms: POST-CHANGE + WHEN-VALIDATE-ITEM of changed items)
    FUNCTION val (p_item IN VARCHAR2) RETURN VARCHAR2
    IS
    BEGIN
        RETURN pkg_impr1110_apx.validate_on_submit(p_item);
    END val;

    -- ------------------------------------------------------------- f345 helpers
    PROCEDURE CHK (I_ERR IN VARCHAR2)
    IS
    BEGIN
        IF I_ERR IS NOT NULL THEN
            raise_application_error(c_err, I_ERR);
        END IF;
    END CHK;

    FUNCTION REQUIRED_VAL (I_VALUE IN VARCHAR2, I_LABEL IN VARCHAR2) RETURN VARCHAR2
    IS
    BEGIN
        -- Source: FRM-40202 "Field must be entered" - TODO-VERIFY Arabic text used by f345
        RETURN CASE WHEN TRIM(I_VALUE) IS NULL THEN 'يجب إدخال ' || I_LABEL END;
    END REQUIRED_VAL;

    -- ------------------------------------------------------------- Before Header
    PROCEDURE P0_PAGE_PK_CHECK (IO_P0_PAGE_PK IN OUT VARCHAR2)
    IS
        v_cnt NUMBER;
    BEGIN
        IF IO_P0_PAGE_PK IS NULL THEN
            RETURN;
        END IF;
        SELECT COUNT(*)
          INTO v_cnt
          FROM importers i
         WHERE i.impr_nbr = TO_NUMBER(IO_P0_PAGE_PK)
           AND i.port_cd  = TO_NUMBER(v('P_CURR_PORT_CD'));
        IF v_cnt = 0 THEN
            IO_P0_PAGE_PK := NULL;
        END IF;
    EXCEPTION
        WHEN VALUE_ERROR OR INVALID_NUMBER THEN
            IO_P0_PAGE_PK := NULL;
    END P0_PAGE_PK_CHECK;

    FUNCTION GET_MODULE_ID (I_P1110_MODULE_ID IN VARCHAR2) RETURN VARCHAR2
    IS
        v_id VARCHAR2(40);
    BEGIN
        IF I_P1110_MODULE_ID IS NOT NULL THEN
            RETURN I_P1110_MODULE_ID;
        END IF;
        SELECT TO_CHAR(MIN(o.sysobj_id))
          INTO v_id
          FROM sc_system_objects o
         WHERE UPPER(REGEXP_REPLACE(o.sys_os_file_name, '\..*$', '')) = 'IMPR1110';
        RETURN v_id;
    END GET_MODULE_ID;

    PROCEDURE PARAMETERS_ENTRY (IO_P_PRSNL_IMPR      IN OUT VARCHAR2,
                                IO_P_LETTER_NBR      IN OUT VARCHAR2,
                                IO_P1110_PRSNL_IMPR  IN OUT VARCHAR2,
                                IO_P1110_LETTER_NBR  IN OUT VARCHAR2)
    IS
    BEGIN
        -- one-shot hand-over (f345 PARAMETERS ENTRY): the caller sets P_PRSNL_IMPR / P_LETTER_NBR
        IO_P1110_PRSNL_IMPR := NVL(IO_P_PRSNL_IMPR, IO_P1110_PRSNL_IMPR);
        IO_P1110_LETTER_NBR := NVL(IO_P_LETTER_NBR, IO_P1110_LETTER_NBR);
        IO_P_PRSNL_IMPR     := NULL;
        IO_P_LETTER_NBR     := NULL;
    END PARAMETERS_ENTRY;

    PROCEDURE WHEN_NEW_FORM_INSTANCE
    IS
    BEGIN
        pkg_impr1110_apx.page_wnfi;
    END WHEN_NEW_FORM_INSTANCE;

    PROCEDURE SET_PAGE_PK (I_P0_PAGE_PK IN VARCHAR2)
    IS
    BEGIN
        -- a key that is not the record on the page -> query it (the POST-QUERY process fetches it)
        IF I_P0_PAGE_PK IS NOT NULL
           AND (v('P1110_ROW_ID') IS NULL OR NVL(v('P1110_IMPR_NBR'), '#') <> I_P0_PAGE_PK) THEN
            pkg_impr1110_apx.page_query(TO_NUMBER(I_P0_PAGE_PK));
        END IF;
    END SET_PAGE_PK;

    PROCEDURE POST_QUERY
    IS
    BEGIN
        pkg_impr1110_apx.page_fetch;
    END POST_QUERY;

    PROCEDURE WHEN_CREATE_RECORD
    IS
    BEGIN
        pkg_impr1110_apx.page_new_record;
    END WHEN_CREATE_RECORD;

    PROCEDURE HEADER_TITLE (I_P1110_MODULE_ID   IN VARCHAR2,
                            IO_P1110_HERO_TITLE IN OUT VARCHAR2)
    IS
        v_name VARCHAR2(400);
    BEGIN
        IF I_P1110_MODULE_ID IS NOT NULL THEN
            SELECT MAX(o.sys_aname)
              INTO v_name
              FROM sc_system_objects o
             WHERE o.sysobj_id = TO_NUMBER(I_P1110_MODULE_ID);
        END IF;
        IO_P1110_HERO_TITLE := NVL(v_name, c_hero_title);
    EXCEPTION
        WHEN VALUE_ERROR OR INVALID_NUMBER THEN
            IO_P1110_HERO_TITLE := c_hero_title;
    END HEADER_TITLE;

    FUNCTION MOBILE_URL (I_P1110_IMPR_NBR IN VARCHAR2) RETURN VARCHAR2
    IS
    BEGIN
        IF I_P1110_IMPR_NBR IS NULL THEN
            RETURN NULL;
        END IF;
        RETURN apex_page.get_url(p_page        => c_mobile_page,
                                 p_clear_cache => TO_CHAR(c_mobile_page),
                                 p_items       => 'P111002_IMPR_NBR',
                                 p_values      => I_P1110_IMPR_NBR);
    END MOBILE_URL;

    -- ------------------------------------------------------------- After Submit
    PROCEDURE ON_INSERT
    IS
    BEGIN
        pkg_impr1110_apx.page_dml('SAVE');     -- ROW_ID is null -> PRE-INSERT, INSERT, POST-INSERT
    END ON_INSERT;

    PROCEDURE ON_UPDATE
    IS
    BEGIN
        pkg_impr1110_apx.page_dml('SAVE');     -- ROW_ID set, record CHANGED -> PRE/ON/POST-UPDATE
    END ON_UPDATE;

    PROCEDURE KEY_DELREC
    IS
    BEGIN
        pkg_impr1110_apx.page_dml('DELETE');
    END KEY_DELREC;

    PROCEDURE EXECUTE_QUERY (I_REQUEST IN VARCHAR2, I_P1110_IMPR_NBR IN VARCHAR2)
    IS
        v_nbr NUMBER := CASE WHEN I_REQUEST = 'QUERY_NBR' THEN TO_NUMBER(I_P1110_IMPR_NBR) END;
    BEGIN
        pkg_impr1110_apx.page_query(v_nbr);
        apex_util.set_session_state('P0_PAGE_PK', TO_CHAR(v_nbr));   -- toolbar follows the record
    END EXECUTE_QUERY;

    -- ------------------------------------------------------------- validations
    FUNCTION PORT_CD_VAL         (I_P1110_PORT_CD         IN VARCHAR2) RETURN VARCHAR2 IS BEGIN RETURN val('PORT_CD');         END;
    FUNCTION HQ_IMPR_NBR_VAL     (I_P1110_HQ_IMPR_NBR     IN VARCHAR2) RETURN VARCHAR2 IS BEGIN RETURN val('HQ_IMPR_NBR');     END;
    FUNCTION IMPR_NBR_VAL        (I_P1110_IMPR_NBR        IN VARCHAR2) RETURN VARCHAR2 IS BEGIN RETURN val('IMPR_NBR');        END;
    FUNCTION IMPR_TYPE_CD_VAL    (I_P1110_IMPR_TYPE_CD    IN VARCHAR2) RETURN VARCHAR2 IS BEGIN RETURN val('IMPR_TYPE_CD');    END;
    FUNCTION BUS_ID_EXPRD_DT_VAL (I_P1110_BUS_ID_EXPRD_DT IN VARCHAR2) RETURN VARCHAR2 IS BEGIN RETURN val('BUS_ID_EXPRD_DT'); END;
    FUNCTION BUS_ID_TYPE_CD_VAL  (I_P1110_BUS_ID_TYPE_CD  IN VARCHAR2) RETURN VARCHAR2 IS BEGIN RETURN val('BUS_ID_TYPE_CD');  END;
    FUNCTION CITY_CODE_OF_ID_VAL (I_P1110_CITY_CODE_OF_ID IN VARCHAR2) RETURN VARCHAR2 IS BEGIN RETURN val('CITY_CODE_OF_ID'); END;
    FUNCTION BUS_ID_VAL          (I_P1110_BUS_ID          IN VARCHAR2) RETURN VARCHAR2 IS BEGIN RETURN val('BUS_ID');          END;
    FUNCTION BRNH_CITY_CD_VAL    (I_P1110_BRNH_CITY_CD    IN VARCHAR2) RETURN VARCHAR2 IS BEGIN RETURN val('BRNH_CITY_CD');    END;
    FUNCTION BUS_ID_BRNCH_VAL    (I_P1110_BUS_ID_BRNCH    IN VARCHAR2) RETURN VARCHAR2 IS BEGIN RETURN val('BUS_ID_BRNCH');    END;
    FUNCTION CTRY_CD_VAL         (I_P1110_CTRY_CD         IN VARCHAR2) RETURN VARCHAR2 IS BEGIN RETURN val('CTRY_CD');         END;
    FUNCTION IMPR_EXPR_TYPE_VAL  (I_P1110_IMPR_EXPR_TYPE  IN VARCHAR2) RETURN VARCHAR2 IS BEGIN RETURN val('IMPR_EXPR_TYPE');  END;
    FUNCTION ARBC_IMPR_NAME_VAL  (I_P1110_ARBC_IMPR_NAME  IN VARCHAR2) RETURN VARCHAR2 IS BEGIN RETURN val('ARBC_IMPR_NAME');  END;
    FUNCTION ENG_IMPR_NAME_VAL   (I_P1110_ENG_IMPR_NAME   IN VARCHAR2) RETURN VARCHAR2 IS BEGIN RETURN val('ENG_IMPR_NAME');   END;
    FUNCTION BUS_ID_ISSUE_DT_VAL (I_P1110_BUS_ID_ISSUE_DT IN VARCHAR2) RETURN VARCHAR2 IS BEGIN RETURN val('BUS_ID_ISSUE_DT'); END;
    FUNCTION IMPR_NBR_PARENT_VAL (I_P1110_IMPR_NBR_PARENT IN VARCHAR2) RETURN VARCHAR2 IS BEGIN RETURN val('IMPR_NBR_PARENT'); END;
    FUNCTION ADD_CTRY_CD_VAL     (I_P1110_ADD_CTRY_CD     IN VARCHAR2) RETURN VARCHAR2 IS BEGIN RETURN val('ADD_CTRY_CD');     END;
    FUNCTION CITY_CODE_VAL       (I_P1110_CITY_CODE       IN VARCHAR2) RETURN VARCHAR2 IS BEGIN RETURN val('CITY_CODE');       END;
    FUNCTION IMPR_TEL_NBR_VAL    (I_P1110_IMPR_TEL_NBR    IN VARCHAR2) RETURN VARCHAR2 IS BEGIN RETURN val('IMPR_TEL_NBR');    END;
    FUNCTION B_EMAIL_VAL         (I_P1110_B_EMAIL         IN VARCHAR2) RETURN VARCHAR2 IS BEGIN RETURN val('B_EMAIL');         END;
    FUNCTION EMAIL_VAL           (I_P1110_EMAIL           IN VARCHAR2) RETURN VARCHAR2 IS BEGIN RETURN val('EMAIL');           END;
    FUNCTION B_MOBILE_NO_VAL     (I_P1110_B_MOBILE_NO     IN VARCHAR2) RETURN VARCHAR2 IS BEGIN RETURN val('B_MOBILE_NO');     END;
    FUNCTION BANK_IBAN_VAL       (I_P1110_BANK_IBAN       IN VARCHAR2) RETURN VARCHAR2 IS BEGIN RETURN val('BANK_IBAN');       END;
    FUNCTION B_ID_NBR_VAL        (I_P1110_B_ID_NBR        IN VARCHAR2) RETURN VARCHAR2 IS BEGIN RETURN val('B_ID_NBR');        END;
    FUNCTION CTRY_CD_OF_ID_VAL   (I_P1110_CTRY_CD_OF_ID   IN VARCHAR2) RETURN VARCHAR2 IS BEGIN RETURN val('CTRY_CD_OF_ID');   END;

    FUNCTION REQUIRED_ITEMS_VAL RETURN VARCHAR2
    IS
    BEGIN
        RETURN pkg_impr1110_apx.required_items;
    END REQUIRED_ITEMS_VAL;

    -- ------------------------------------------------------------- AJAX callbacks
    PROCEDURE AJAX_ITEM    IS BEGIN pkg_impr1110_apx.ajax_item;    END AJAX_ITEM;
    PROCEDURE AJAX_CONFIRM IS BEGIN pkg_impr1110_apx.ajax_confirm; END AJAX_CONFIRM;
    PROCEDURE AJAX_FUN     IS BEGIN pkg_impr1110_apx.ajax_fun;     END AJAX_FUN;

    -- ------------------------------------------------------------- page 111002
    FUNCTION CENTRAL_MOBILE (I_P111002_IMPR_NBR IN VARCHAR2) RETURN NUMBER
    IS
    BEGIN
        RETURN pkg_impr1110_apx.central_mobile(TO_NUMBER(I_P111002_IMPR_NBR));
    END CENTRAL_MOBILE;

    PROCEDURE MOBILE_OK (I_P111002_MOBILE_NO IN VARCHAR2)
    IS
    BEGIN
        -- Source: LOV_UPDATE_IMPR_MOBILE.CTRL_BLK.PB_OK (:GLOBAL.OK := 1; COPY_SELECTED_VALUES)
        pkg_forms_compat.set_global('MOBILE_NO', I_P111002_MOBILE_NO);
    END MOBILE_OK;

    PROCEDURE MOBILE_CANCEL
    IS
    BEGIN
        -- Source: LOV_UPDATE_IMPR_MOBILE.CTRL_BLK.PB_CANCEL (CANCEL_LOV_FORM)
        pkg_forms_compat.set_global('MOBILE_NO', NULL);
    END MOBILE_CANCEL;

    -- =========================================================================
    -- PACKAGE VERSION   (SELECT IMPR1110.PKG_VERSION FROM dual;)
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
