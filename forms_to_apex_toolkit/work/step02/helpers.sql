    -- Section: PRIVATE
    -- Error text for a failed entry point: FORMS_APX.FORM_TRIGGER_FAILURE / raise_application_error text,
    -- else the IMPORTERS.ON-ERROR constraint message (importers_on_error)
    FUNCTION PRIVATE_ERROR_TEXT (p_sqlcode IN NUMBER, p_sqlerrm IN VARCHAR2, p_op IN VARCHAR2 DEFAULT 'U')
        RETURN VARCHAR2
    IS
    BEGIN
        IF p_sqlcode BETWEEN -20999 AND -20000 THEN
            RETURN REGEXP_REPLACE(p_sqlerrm, '^ORA-[0-9]+: ');
        END IF;
        RETURN importers_on_error(p_op, p_sqlcode, p_sqlerrm);
    END PRIVATE_ERROR_TEXT;

    -- Section: PRIVATE
    -- Comma list of the functions ADJ_FUNS left enabled (SET_FUNCTION_ENABLED calls; last call wins)
    FUNCTION PRIVATE_ENABLED_FUNCTIONS RETURN VARCHAR2
    IS
        v_list VARCHAR2(4000);
        v_rest VARCHAR2(4000) := c_functions || ',';
        v_fun  VARCHAR2(100);
    BEGIN
        WHILE v_rest IS NOT NULL LOOP
            v_fun  := SUBSTR(v_rest, 1, INSTR(v_rest, ',') - 1);
            v_rest := SUBSTR(v_rest, INSTR(v_rest, ',') + 1);
            IF NVL(FUNCTION_STATE(v_fun), 'Y') = 'Y' THEN
                v_list := v_list || CASE WHEN v_list IS NOT NULL THEN ',' END || v_fun;
            END IF;
        END LOOP;
        RETURN v_list;
    END PRIVATE_ENABLED_FUNCTIONS;

    -- Section: f345 HELPERS
    -- f345 CHECK_ERROR: raise the text returned by a <ITEM>_VALIDATION function (used by the FOS DAs)
    PROCEDURE CHECK_ERROR (I_ERR IN VARCHAR2)
    IS
    BEGIN
        IF I_ERR IS NOT NULL THEN
            raise_application_error(c_err, I_ERR);
        END IF;
    END CHECK_ERROR;

    -- Section: f345 HELPERS
    -- Validation "<ITEM> REQUIRED" (server-side condition <ITEM>_IS_REQUIRED): Forms FRM-40202
    FUNCTION REQUIRED_VALIDATION (I_VALUE IN VARCHAR2, I_LABEL IN VARCHAR2) RETURN VARCHAR2
    IS
    BEGIN
        IF I_VALUE IS NULL THEN
            RETURN CG_MESSAGE('<p1> must be entered', I_LABEL);
        END IF;
        RETURN NULL;
    END REQUIRED_VALIDATION;

    -- Section: f345 HELPERS
    -- Hijri date format of the application: APEX Application Setting HIJRI_DATE_FORMAT, default YYYY-MM-MI
    -- (the f345 Hijri picker writes iYYYY-iMM-iDD; the day is kept in the minutes). Change the setting
    -- (Shared Components > Application Settings, or APEX_APP_SETTING.SET_VALUE) to change it.
    -- APEX  : computation P1110_HIJRI_DATE_FORMAT (Before Header) = format mask &P1110_HIJRI_DATE_FORMAT.
    --         of the Hijri date items; the package converts the item texts with the same function.
    FUNCTION HIJRI_DATE_FORMAT RETURN VARCHAR2
    IS
    BEGIN
        RETURN NVL(APEX_APP_SETTING.GET_VALUE(p_name => 'HIJRI_DATE_FORMAT'), c_hijri_date_format);
    EXCEPTION
        WHEN OTHERS THEN               -- no APEX session / setting missing: the default format
            RETURN c_hijri_date_format;
    END HIJRI_DATE_FORMAT;

    -- Section: f345 HELPERS
    -- Process "P0_PAGE_PK CHECK" (Before Header): P0_PAGE_PK holds the ROWID of the importer (Forms key
    -- mode ROWID); forget a key that is not a row of IMPORTERS of this port (block WHERE clause).
    -- The search page 111001 passes the ROWID URL-safe (TRANSLATE(ROWID, '+/', '-_'): a '+' in f?p arrives
    -- as a space and the checksum fails); it is translated back first. A ROWID never contains '-' or '_'.
    PROCEDURE P0_PAGE_PK_CHECK (IO_P0_PAGE_PK    IN OUT VARCHAR2,
                                I_P_CURR_PORT_CD IN     NUMBER)
    IS
        v_cnt NUMBER;
    BEGIN
        IF IO_P0_PAGE_PK IS NULL THEN
            RETURN;
        END IF;
        IO_P0_PAGE_PK := TRANSLATE(IO_P0_PAGE_PK, '-_', '+/');      -- URL-safe ROWID of page 111001 -> ROWID
        SELECT COUNT(*)
          INTO v_cnt
          FROM importers i
         WHERE i.ROWID   = CHARTOROWID(IO_P0_PAGE_PK)
           AND i.port_cd = I_P_CURR_PORT_CD;
        IF v_cnt = 0 THEN
            IO_P0_PAGE_PK := NULL;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN               -- ORA-01410 invalid ROWID, ORA-01445 ...: not a key of this page
            IO_P0_PAGE_PK := NULL;
    END P0_PAGE_PK_CHECK;

    -- Section: f345 HELPERS
    -- Process "EXECUTE-QUERY" (request EXECUTE_QUERY): the ROWID of importer IMPR_NBR of this port, for
    -- P0_PAGE_PK. Source: IMPORTERS.IMPR_NBR.WHEN-VALIDATE-ITEM (existing number -> :GLOBAL.EXEC_QUERY_NOW
    -- -> IMPORTERS.WHEN-NEW-ITEM-INSTANCE EXECUTE_QUERY with PRE-QUERY on :GLOBAL.PORT_CD / IMPR_NBR)
    FUNCTION IMPORTER_ROW_ID (I_P1110_IMPR_NBR IN NUMBER,
                              I_P_CURR_PORT_CD IN NUMBER) RETURN VARCHAR2
    IS
        v_row_id VARCHAR2(18);
    BEGIN
        SELECT MAX(ROWIDTOCHAR(i.ROWID))
          INTO v_row_id
          FROM importers i
         WHERE i.port_cd  = I_P_CURR_PORT_CD
           AND i.impr_nbr = I_P1110_IMPR_NBR;
        RETURN v_row_id;
    END IMPORTER_ROW_ID;

    -- Section: f345 HELPERS
    -- Computation P1110_MODULE_ID: SC_SYSTEM_OBJECTS id of the form (f345 Page Functions list)
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

    -- Section: f345 HELPERS
    -- Process "PARAMETERS ENTRY" (f345): one-shot hand-over of :PARAMETER.PRSNL_IMPR / LETTER_NBR
    PROCEDURE PARAMETERS_ENTRY (IO_P_PRSNL_IMPR       IN OUT VARCHAR2,
                                IO_P_LETTER_NBR       IN OUT VARCHAR2,
                                IO_P1110_P_PRSNL_IMPR IN OUT VARCHAR2,
                                IO_P1110_P_LETTER_NBR IN OUT VARCHAR2)
    IS
    BEGIN
        IO_P1110_P_PRSNL_IMPR := NVL(IO_P_PRSNL_IMPR, IO_P1110_P_PRSNL_IMPR);
        IO_P1110_P_LETTER_NBR := NVL(IO_P_LETTER_NBR, IO_P1110_P_LETTER_NBR);
        IO_P_PRSNL_IMPR       := NULL;
        IO_P_LETTER_NBR       := NULL;
    END PARAMETERS_ENTRY;

    -- Section: f345 HELPERS
    -- Process "HEADER TITLE": the form title from SC_SYSTEM_OBJECTS (Forms TITLE block)
    PROCEDURE HEADER_TITLE (I_P1110_MODULE_ID   IN     VARCHAR2,
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

    -- Section: PAGE 111002 (LOV_UPDATE_IMPR_MOBILE)
    -- Source: LOV_UPDATE_IMPR_MOBILE.CTRL_BLK.PB_OK (:GLOBAL.OK := 1; COPY_SELECTED_VALUES)
    -- APEX  : Process "PB_OK WHEN-BUTTON-PRESSED" of page 111002, then Close Dialog
    PROCEDURE MOBILE_OK (I_P111002_MOBILE_NO IN VARCHAR2)
    IS
    BEGIN
        FORMS_APX.set_global('MOBILE_NO', I_P111002_MOBILE_NO);
    END MOBILE_OK;

    -- Section: PAGE 111002 (LOV_UPDATE_IMPR_MOBILE)
    -- Source: LOV_UPDATE_IMPR_MOBILE.CTRL_BLK.PB_CANCEL (CANCEL_LOV_FORM)
    PROCEDURE MOBILE_CANCEL
    IS
    BEGIN
        FORMS_APX.set_global('MOBILE_NO', NULL);
    END MOBILE_CANCEL;
