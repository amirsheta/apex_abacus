-- =============================================================================
-- Package body : pkg_impr1110
-- Source form  : IMPR1110.fmb (module IMPR1110_PROD_CENTRL), XML forms/IMPR/IMPR1110_fmb.xml
-- Target       : Oracle APEX 21.2 / Oracle Database 12.1.0.2
-- Author       : Claude Code
-- Created      : 2026-11-18
-- Version      : 1.0.0
-- Status       : NOT COMPILED - compile in DEV first.
-- Conversions  : Str.DispArbMsg(s,n,..) + RAISE FTF   -> disp_arb_ftf(s,n)
--                Str.DispArbMsg(s,n,..) (no raise)     -> disp_arb_info(s,n)
--                STR.DispAlert(t,'ERROR'|..) + FTF     -> pkg_forms_compat.ftf(t)
--                STR.DispAlert(t,..) (no raise)        -> info(t)
--                STR.DispAlert(t,'CONFIRM'|'WARNING')  -> Confirm DA on the page; answer -> p_answer
--                :GLOBAL.X                             -> g_get / g_set (pkg_forms_compat)
--                INTRFACE.Make_Field_Entrable / SET_ITEM_PROPERTY / GO_ITEM -> ui_* recorder
--                TMPLT.ENABLE_FUN / DISABLE_FUN        -> fun() recorder (function menu)
--                COMMIT / FORMS_DDL('COMMIT') / STANDARD.COMMIT -> removed (APEX commits), flagged HIGH
-- Original code: every "Original Forms code" block below is copied verbatim from the XML
--                (comment-only and blank lines removed) by the build step described in
--                analysis/IMPR1110/IMPR1110_logic_extraction.md §8.
-- =============================================================================
SET DEFINE OFF

CREATE OR REPLACE PACKAGE BODY pkg_impr1110
AS
    -- ======================================================================= UI recorder state
    TYPE t_vc_tab IS TABLE OF VARCHAR2(4000) INDEX BY PLS_INTEGER;
    g_ui_item   t_vc_tab;     -- item name
    g_ui_prop   t_vc_tab;     -- ENTRABLE / ENABLED / REQUIRED / VISIBLE / VALID / OPEN_LOV / BLOCK_OPS / DO_COMMIT
    g_ui_val    t_vc_tab;     -- 'Y' / 'N' (or free text for BLOCK_OPS)
    g_msgs      t_vc_tab;     -- non-blocking messages (alerts shown without RAISE FTF)
    g_fun_cd    t_vc_tab;     -- function menu codes touched by ADJ_FUNS
    g_fun_on    t_vc_tab;     -- 'Y' / 'N'
    g_focus     VARCHAR2(61); -- last GO_ITEM target

    PROCEDURE ui_reset
    IS
    BEGIN
        g_ui_item.DELETE; g_ui_prop.DELETE; g_ui_val.DELETE;
        g_msgs.DELETE; g_fun_cd.DELETE; g_fun_on.DELETE;
        g_focus := NULL;
    END ui_reset;

    PROCEDURE ui (p_item IN VARCHAR2, p_prop IN VARCHAR2, p_on IN BOOLEAN)
    IS
        n PLS_INTEGER := g_ui_item.COUNT + 1;
    BEGIN
        g_ui_item(n) := UPPER(REPLACE(p_item, 'IMPORTERS.'));
        g_ui_prop(n) := p_prop;
        g_ui_val(n)  := CASE WHEN p_on THEN 'Y' ELSE 'N' END;
    END ui;

    -- INTRFACE.Make_Field_Entrable(item, flag)   -- TODO: MISSING SOURCE INTRFACE.pll (exact
    -- properties it sets are unknown; recorded as ENTRABLE = enabled + navigable + updateable)
    PROCEDURE entrable (p_item IN VARCHAR2, p_on IN BOOLEAN)
    IS
    BEGIN
        ui(p_item, 'ENTRABLE', p_on);
    END entrable;

    PROCEDURE ui_focus (p_item IN VARCHAR2)
    IS
    BEGIN
        g_focus := UPPER(REPLACE(p_item, 'IMPORTERS.'));
    END ui_focus;

    -- TMPLT.ENABLE_FUN / TMPLT.DISABLE_FUN  -- TODO: MISSING SOURCE TMPLT (LIB_APX_USR / OLB)
    PROCEDURE fun (p_fun IN VARCHAR2, p_on IN BOOLEAN)
    IS
        n PLS_INTEGER := g_fun_cd.COUNT + 1;
    BEGIN
        g_fun_cd(n) := p_fun;
        g_fun_on(n) := CASE WHEN p_on THEN 'Y' ELSE 'N' END;
    END fun;

    FUNCTION fun_state (p_fun IN VARCHAR2) RETURN VARCHAR2
    IS
        v VARCHAR2(1);
    BEGIN
        FOR i IN 1 .. g_fun_cd.COUNT LOOP
            IF g_fun_cd(i) = p_fun THEN
                v := g_fun_on(i);          -- last call wins, as in Forms
            END IF;
        END LOOP;
        RETURN v;
    END fun_state;

    -- STR.DispAlert(text, 'INFORMATION'|'ERROR'|'WARNING') without RAISE FORM_TRIGGER_FAILURE
    PROCEDURE info (p_text IN VARCHAR2)
    IS
    BEGIN
        g_msgs(g_msgs.COUNT + 1) := p_text;
        pkg_forms_compat.message(p_text);
    END info;

    FUNCTION ui_json RETURN CLOB
    IS
        v_clob CLOB;
    BEGIN
        apex_json.initialize_clob_output;
        apex_json.open_object;
        apex_json.open_array('items');
        FOR i IN 1 .. g_ui_item.COUNT LOOP
            apex_json.open_object;
            apex_json.write('item',  g_ui_item(i));
            apex_json.write('prop',  g_ui_prop(i));
            apex_json.write('value', g_ui_val(i) = 'Y');
            apex_json.close_object;
        END LOOP;
        apex_json.close_array;
        apex_json.write('focus', g_focus, TRUE);
        apex_json.open_array('messages');
        FOR i IN 1 .. g_msgs.COUNT LOOP
            apex_json.write(g_msgs(i));
        END LOOP;
        apex_json.close_array;
        apex_json.open_array('funs');
        FOR i IN 1 .. g_fun_cd.COUNT LOOP
            apex_json.open_object;
            apex_json.write('fun', g_fun_cd(i));
            apex_json.write('enabled', g_fun_on(i) = 'Y');
            apex_json.close_object;
        END LOOP;
        apex_json.close_array;
        apex_json.close_object;
        v_clob := apex_json.get_clob_output;
        apex_json.free_output;
        RETURN v_clob;
    END ui_json;

    FUNCTION ui_count RETURN PLS_INTEGER
    IS
    BEGIN
        RETURN g_ui_item.COUNT;
    END ui_count;

    PROCEDURE ui_entry (p_idx  IN  PLS_INTEGER,
                        p_item OUT VARCHAR2,
                        p_prop OUT VARCHAR2,
                        p_val  OUT VARCHAR2)
    IS
    BEGIN
        p_item := g_ui_item(p_idx);
        p_prop := g_ui_prop(p_idx);
        p_val  := g_ui_val(p_idx);
    END ui_entry;

    -- ======================================================================= private helpers

    PROCEDURE ftf (p_text IN VARCHAR2 DEFAULT NULL)
    IS
    BEGIN
        pkg_forms_compat.ftf(p_text);
    END ftf;

    FUNCTION g_get (p_name IN VARCHAR2) RETURN VARCHAR2
    IS
    BEGIN
        RETURN pkg_forms_compat.get_global(p_name);
    END g_get;

    PROCEDURE g_set (p_name IN VARCHAR2, p_val IN VARCHAR2)
    IS
    BEGIN
        pkg_forms_compat.set_global(p_name, p_val);
    END g_set;

    -- Text of Str.DispArbMsg(sys, nbr). STR.pll is MISSING SOURCE; the format below is the one
    -- the form itself builds inline for message 9-120 (IMPORTERS.BUS_ID.WHEN-VALIDATE-ITEM).
    -- TODO: verify against STR.DispArbMsg once STR.pll is available.
    FUNCTION arb_msg (p_sys IN NUMBER, p_nbr IN NUMBER) RETURN VARCHAR2
    IS
        v_txt VARCHAR2(4000);
    BEGIN
        v_txt := str_db.getarbmsg(p_sys, p_nbr);
        IF v_txt = '-1' THEN
            RETURN 'خطأ فى رقم الرسالة  ' || p_sys || '-' || p_nbr || 'إتصل بالمسانده الفنيه';
        END IF;
        RETURN p_sys || '-' || p_nbr || ' : ' || v_txt;
    END arb_msg;

    -- ret := Str.DispArbMsg(s, n, ...); RAISE FORM_TRIGGER_FAILURE;
    PROCEDURE disp_arb_ftf (p_sys IN NUMBER, p_nbr IN NUMBER)
    IS
    BEGIN
        ftf(arb_msg(p_sys, p_nbr));
    END disp_arb_ftf;

    -- ret := Str.DispArbMsg(s, n, ...);   (no raise)
    PROCEDURE disp_arb_info (p_sys IN NUMBER, p_nbr IN NUMBER)
    IS
    BEGIN
        info(arb_msg(p_sys, p_nbr));
    END disp_arb_info;

    -- Des$Form_errors.MSGGETTEXT(n, '<p1> ...', p1)   -- TODO: MISSING SOURCE Des$Form_errors
    -- (CG library). English default text with <p1> replaced; verify the Arabic text it returns.
    FUNCTION cg_msg (p_default IN VARCHAR2, p1 IN VARCHAR2) RETURN VARCHAR2
    IS
    BEGIN
        RETURN REPLACE(p_default, '<p1>', p1);
    END cg_msg;

    -- IF NOT ACTIVITY.ADD_ACTIVITY(9, 2, n, :IMPORTERS.Port_Cd||'!'||:IMPORTERS.Impr_Nbr) THEN
    --     RAISE FORM_TRIGGER_FAILURE;
    -- TODO: verify ACTIVITY is the DB package (not a client .pll) and its signature.
    PROCEDURE add_activity (p_act IN NUMBER, p_rec IN t_rec)
    IS
    BEGIN
        IF NOT activity.add_activity(9, 2, p_act, p_rec.port_cd || '!' || p_rec.impr_nbr) THEN
            ftf;
        END IF;
    END add_activity;

    -- HIJDATE.Cur_Hij_Date (client library) -> HIJDATE_DB.Cur_Hij_Date (used by the form itself)
    FUNCTION cur_hij_date RETURN DATE
    IS
    BEGIN
        RETURN hijdate_db.cur_hij_date;
    END cur_hij_date;

    -- HIJDATE.VALID_HIJ_DATE  -- TODO: MISSING SOURCE HIJDATE.pll. Assumed server twin in
    -- HIJDATE_DB; compilation fails here if it does not exist (intended - do not guess).
    FUNCTION valid_hij_date (p_dt IN DATE) RETURN BOOLEAN
    IS
    BEGIN
        RETURN hijdate_db.valid_hij_date(p_dt);
    END valid_hij_date;

    -- Repeated block: IMPR_TYPE_CD.WHEN-NEW-ITEM-INSTANCE, WHEN-NEW-RECORD-INSTANCE,
    -- WHEN-NEW-FORM-INSTANCE, IMPR_TYPE_CD.KEY-LISTVAL (identical text in all four)
    PROCEDURE ctry_100_defaults (p_rec IN OUT NOCOPY t_rec)
    IS
    BEGIN
        IF p_rec.impr_type_cd = 4 AND p_rec.bus_id_type_cd = 3
           OR p_rec.impr_type_cd = 4 AND p_rec.bus_id_type_cd = 5 THEN
            p_rec.ctry_cd := 100;
            ui('CTRY_CD', 'ENABLED', FALSE);
            SELECT crty_arbc_name INTO p_rec.crty_arbc_name
              FROM countries
             WHERE ctry_cd = 100;
        END IF;
        p_rec.add_ctry_cd := 100;
        ui('ADD_CTRY_CD', 'ENABLED', FALSE);
        SELECT crty_arbc_name INTO p_rec.add_crty_arbc_name
          FROM countries
         WHERE ctry_cd = 100;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            disp_arb_ftf(18, 15);
    END ctry_100_defaults;

    -- Repeated block of IMPR_TYPE_CD.WHEN-VALIDATE-ITEM and POST-QUERY:
    -- entrable state of CTRY/ADD_CTRY/CITY_CODE_OF_ID/BUS_ID_BRNCH/BUS_ID by importer type.
    -- (POST-QUERY has the same branches without value assignments; see callers.)
    PROCEDURE type_entrable_qry (p_rec IN t_rec)
    IS
    BEGIN
        IF p_rec.impr_type_cd = 1 THEN
            entrable('CTRY_CD', FALSE); entrable('ADD_CTRY_CD', FALSE);
        ELSIF p_rec.impr_type_cd = 2 THEN
            entrable('CTRY_CD', FALSE); entrable('ADD_CTRY_CD', FALSE);
            entrable('CITY_CODE_OF_ID', FALSE); ui('CITY_CODE_OF_ID2', 'ENABLED', FALSE);
            entrable('BUS_ID_BRNCH', FALSE);
        ELSIF p_rec.impr_type_cd = 4 THEN
            entrable('CITY_CODE_OF_ID', FALSE); ui('CITY_CODE_OF_ID2', 'ENABLED', FALSE);
            entrable('BUS_ID_BRNCH', FALSE);
        ELSIF p_rec.impr_type_cd = 5 THEN
            entrable('CTRY_CD', FALSE); entrable('ADD_CTRY_CD', FALSE);
        ELSIF p_rec.impr_type_cd = 7 THEN
            entrable('CITY_CODE_OF_ID', FALSE); ui('CITY_CODE_OF_ID2', 'ENABLED', FALSE);
            entrable('BUS_ID_BRNCH', FALSE);
        ELSIF p_rec.impr_type_cd = 8 THEN
            entrable('CTRY_CD', FALSE); entrable('ADD_CTRY_CD', FALSE);
        ELSIF p_rec.impr_type_cd = 9 THEN
            IF p_rec.bus_id_type_cd = 6 THEN
                entrable('CTRY_CD', FALSE); entrable('ADD_CTRY_CD', FALSE);
                entrable('CITY_CODE_OF_ID', FALSE); ui('CITY_CODE_OF_ID2', 'ENABLED', FALSE);
                entrable('BUS_ID_BRNCH', FALSE); entrable('BUS_ID', FALSE);
            ELSE
                entrable('CTRY_CD', TRUE); entrable('ADD_CTRY_CD', TRUE);
                entrable('CITY_CODE_OF_ID', TRUE); ui('CITY_CODE_OF_ID2', 'ENABLED', TRUE);
                entrable('BUS_ID', TRUE); entrable('BUS_ID_BRNCH', FALSE);
            END IF;
        ELSIF p_rec.impr_type_cd = 10 THEN
            entrable('CITY_CODE_OF_ID', FALSE); ui('CITY_CODE_OF_ID2', 'ENABLED', FALSE);
            entrable('BUS_ID_BRNCH', FALSE);
        ELSIF p_rec.impr_type_cd = 11 THEN
            entrable('CTRY_CD', FALSE); entrable('ADD_CTRY_CD', FALSE);
            entrable('BUS_ID_BRNCH', FALSE);
        ELSIF p_rec.impr_type_cd = 12 THEN
            entrable('CITY_CODE_OF_ID', FALSE); ui('CITY_CODE_OF_ID2', 'ENABLED', FALSE);
        ELSIF p_rec.impr_type_cd IN (13, 14) THEN
            entrable('CTRY_CD', FALSE); entrable('ADD_CTRY_CD', FALSE);
            entrable('BUS_ID', FALSE); entrable('BUS_ID_BRNCH', FALSE);
            entrable('CITY_CODE_OF_ID', FALSE); ui('CITY_CODE_OF_ID2', 'ENABLED', FALSE);
        END IF;
    END type_entrable_qry;

    -- Identical list of Make_Field_Entrable(FALSE) after a successful insert/update
    -- (PRE-INSERT result=1, POST-INSERT, POST-UPDATE)
    PROCEDURE lock_key_items
    IS
    BEGIN
        entrable('BUS_ID', FALSE);
        entrable('BUS_ID_BRNCH', FALSE);
        entrable('BUS_ID_EXPRD_DT', FALSE);
        entrable('ARBC_IMPR_NAME', FALSE);
        entrable('COMM_RGSTRTN_TYPE', FALSE);
        entrable('BUS_ID_BRNCH', FALSE);
        entrable('CITY_CODE_OF_ID', FALSE);
        entrable('BUS_ID_TYPE_CD', FALSE);
        entrable('IMPR_EXPR_TYPE', FALSE);
        entrable('IMPR_TYPE_CD', FALSE);
        entrable('BRNH_CITY_CD', FALSE);
    END lock_key_items;

    -- Commercial-register fields made (non-)entrable together (BUS_ID / BUS_ID_BRNCH WVI)
    PROCEDURE cr_fields_entrable (p_on IN BOOLEAN, p_with_activity IN BOOLEAN)
    IS
    BEGIN
        entrable('BUS_ID_EXPRD_DT', p_on);
        entrable('IMPR_POB_NBR', p_on);
        entrable('IMPR_ZIP_CD', p_on);
        entrable('IMPR_TEL_NBR', p_on);
        entrable('IMPR_FAX_NBR', p_on);
        entrable('IMPR_TELEX_NBR', p_on);
        entrable('ARBC_IMPR_NAME', p_on);
        IF p_with_activity THEN
            entrable('ACTIVITY', p_on);
        END IF;
    END cr_fields_entrable;

    -- CGSF$CLRLU_IMPORTERS_IMP_BUS_I : clear the BUS_ID city lookup items
    PROCEDURE cgsf_clrlu_bus_i (p_rec IN OUT NOCOPY t_rec)
    IS
    BEGIN
        p_rec.city_code_of_id   := NULL;
        p_rec.ctry_cd_of_id     := NULL;
        p_rec.l_ct_city_status2 := NULL;
        p_rec.id_city_name      := NULL;
        p_rec.id_mins_comm_cd   := NULL;
    END cgsf_clrlu_bus_i;

    -- CGTE$STRIP_CONSTRAINT  -- TODO: MISSING SOURCE (CG library). Re-implemented: constraint
    -- name between the brackets of the ORA- message, without the owner.
    FUNCTION strip_constraint (p_msg IN VARCHAR2) RETURN VARCHAR2
    IS
        v VARCHAR2(200);
    BEGIN
        v := REGEXP_SUBSTR(p_msg, '\(([^)]+)\)', 1, 1, NULL, 1);
        RETURN SUBSTR(v, INSTR(v, '.') + 1);
    END strip_constraint;

    -- ======================================================================= FORM LEVEL

    -- Source: IMPR1110.WHEN-NEW-FORM-INSTANCE (business part)
    -- Dropped: NIB.WHEN_NEW_FORM_INSTANCE (MISSING SOURCE, toolbar/menu library) and
    -- CG$WHEN_NEW_FORM_INSTANCE (fills list items from CG_REF_CODES -> shared LOVs).
    --@ORIG FORM.WHEN-NEW-FORM-INSTANCE
    -- >>> Original Forms code: FORM.WHEN-NEW-FORM-INSTANCE
    --    NIB.WHEN_NEW_FORM_INSTANCE;
    --   BEGIN
    --     BEGIN
    --       CG$WHEN_NEW_FORM_INSTANCE;
    --     EXCEPTION
    --       WHEN OTHERS THEN
    --         CGTE$OTHER_EXCEPTIONS;
    --     END;
    --   END;
    --   DECLARE
    --     rg_id RECORDGROUP;
    --     temp NUMBER;
    --    RET NUMBER;
    --   BEGIN
    --   INTRFACE.Make_Field_Entrable('IMPORTERS.COMM_RGSTRTN_TYPE' , FALSE);
    --   INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_EXPRD_DT' , FALSE);
    --   INTRFACE.Make_Field_Entrable('IMPORTERS.CITY_CODE_OF_ID' , FALSE);
    --   IF :PARAMETER.P_CLASS_CD=1 AND :PARAMETER.P_USER_TYPE=3 THEN
    --       BROKER_INT;
    --   END IF;
    --       :GLOBAL.FLAGUPDATE := 0;
    --       :global.Exec_Query_Now := 0;
    --       :global.PORT_CD  := NULL;
    --       :global.IMPR_NBR  := NULL;
    --       :GLOBAL.EXE_DETAIL_QUERY:=0;
    --         :GLOBAL.LETTER_NBR :=NULL;
    --       :GLOBAL.CHK_DUP_BUSID := 0 ;
    --   :GLOBAL.OLD_impr_type_cd := 0 ;
    --               IF :PARAMETER.LETTER_NBR IS NULL THEN
    --           GO_ITEM('IMPORTERS.IMPR_NBR');
    --           END IF;
    --           SET_ITEM_PROPERTY('IMPORTERS.PORT_CD', ENABLED, PROPERTY_FALSE);
    --   :GLOBAL.VALID:=0;
    --   :GLOBAL.IMP0F4:=0;
    --   :GLOBAL.STAT_QUE:=0;
    --   :GLOBAL.STAT_CLR:=0;
    --   :GLOBAL.FUNS_IMP :=0;
    --   :GLOBAL.FUNS_BUSID :=0;
    --   :GLOBAL.MINS_COMM_CD := NULL;
    --   :GLOBAL.CHK_IMP_TYP := 0;
    --   BEGIN
    --      :GLOBAL.allow_mci := 0;
    --      :GLOBAL.allow_moi := 0;
    --      BEGIN
    --         SELECT var_value
    --           INTO :GLOBAL.allow_mci
    --           FROM sc_port_setting
    --          WHERE sysobj_id = 24 AND var_name = 'ALLOW_MCI'
    --           AND PORT_CD=:PARAMETER.P_CURR_PORT_CD;
    --        SELECT var_value
    --           INTO :GLOBAL.allow_moi
    --           FROM sc_port_setting
    --          WHERE sysobj_id = 24 AND var_name = 'ALLOW_MOI'
    --   AND PORT_CD=:PARAMETER.P_CURR_PORT_CD;
    --      EXCEPTION
    --         WHEN OTHERS
    --         THEN
    --            NULL;
    --      END;
    --      :GLOBAL.allow_mci := NVL (:GLOBAL.allow_mci, 0);
    --      :GLOBAL.allow_moi := NVL (:GLOBAL.allow_moi, 0);
    --   END;
    --   BEGIN
    --   IF :IMPR_TYPE_CD = 4  AND  :BUS_ID_TYPE_CD = 3
    --   OR :IMPR_TYPE_CD = 4  AND  :BUS_ID_TYPE_CD = 5 THEN
    --   :CTRY_CD := 100;
    --   SET_ITEM_PROPERTY('CTRY_CD', ENABLED,PROPERTY_FALSE);
    --   SELECT CRTY_ARBC_NAME INTO :CRTY_ARBC_NAME
    --    FROM   COUNTRIES
    --    WHERE  CTRY_CD = 100;
    --   END IF;
    --   :ADD_CTRY_CD := 100 ;
    --   SET_ITEM_PROPERTY('ADD_CTRY_CD', ENABLED,PROPERTY_FALSE);
    --   SELECT CRTY_ARBC_NAME INTO :ADD_CRTY_ARBC_NAME
    --    FROM   COUNTRIES
    --    WHERE  CTRY_CD = 100;
    --   EXCEPTION
    --   WHEN NO_DATA_FOUND THEN
    --     ret := Str.DispArbMsg(18, 15,'ERROR');
    --     RAISE FORM_TRIGGER_FAILURE;
    --   END;
    --   END ;
    -- <<<
    PROCEDURE wnfi (p_rec IN OUT NOCOPY t_rec, p_ctx IN t_ctx)
    IS
        v_val VARCHAR2(200);
    BEGIN
        entrable('COMM_RGSTRTN_TYPE', FALSE);
        entrable('BUS_ID_EXPRD_DT', FALSE);
        entrable('CITY_CODE_OF_ID', FALSE);
        IF p_ctx.class_cd = 1 AND p_ctx.user_type = 3 THEN
            broker_int(p_rec);
        END IF;
        g_set('FLAGUPDATE', '0');
        g_set('EXEC_QUERY_NOW', '0');
        g_set('PORT_CD', NULL);
        g_set('IMPR_NBR', NULL);
        g_set('EXE_DETAIL_QUERY', '0');
        g_set('LETTER_NBR', NULL);
        g_set('CHK_DUP_BUSID', '0');
        g_set('OLD_IMPR_TYPE_CD', '0');
        IF p_ctx.letter_nbr IS NULL THEN
            ui_focus('IMPR_NBR');
        END IF;
        ui('PORT_CD', 'ENABLED', FALSE);
        g_set('VALID', '0');
        g_set('IMP0F4', '0');
        g_set('STAT_QUE', '0');
        g_set('STAT_CLR', '0');
        g_set('FUNS_IMP', '0');
        g_set('FUNS_BUSID', '0');
        g_set('MINS_COMM_CD', NULL);
        g_set('CHK_IMP_TYP', '0');
        g_set('ALLOW_MCI', '0');
        g_set('ALLOW_MOI', '0');
        BEGIN
            SELECT var_value INTO v_val
              FROM sc_port_setting
             WHERE sysobj_id = 24 AND var_name = 'ALLOW_MCI'
               AND port_cd = p_ctx.curr_port_cd;
            g_set('ALLOW_MCI', v_val);
            SELECT var_value INTO v_val
              FROM sc_port_setting
             WHERE sysobj_id = 24 AND var_name = 'ALLOW_MOI'
               AND port_cd = p_ctx.curr_port_cd;
            g_set('ALLOW_MOI', v_val);
        EXCEPTION
            WHEN OTHERS THEN
                NULL;
        END;
        g_set('ALLOW_MCI', NVL(g_get('ALLOW_MCI'), '0'));
        g_set('ALLOW_MOI', NVL(g_get('ALLOW_MOI'), '0'));
        ctry_100_defaults(p_rec);
    END wnfi;

    -- ======================================================================= BLOCK IMPORTERS

    -- Source: IMPORTERS.WHEN-CREATE-RECORD
    --@ORIG IMPORTERS.WHEN-CREATE-RECORD
    -- >>> Original Forms code: IMPORTERS.WHEN-CREATE-RECORD
    --   BEGIN
    --           :IMPORTERS.PORT_CD := :PARAMETER.P_CURR_PORT_CD;
    --           SELECT PORT_NAME
    --           INTO:PORT_NAME
    --           FROM SD_PORTS
    --           WHERE    PORT_CD = :IMPORTERS.PORT_CD;
    --       IF :PARAMETER.PRSNL_IMPR = 1 THEN
    --           :IMPORTERS.IMPR_TYPE_CD := 4;
    --           SELECT     IMPR_TYPE_NAME
    --           INTO        :IMPORTERS.IMPR_TYPE_NAME
    --           FROM        IMPR_TYPES
    --           WHERE        IMPR_TYPE_CD = :IMPORTERS.IMPR_TYPE_CD
    --           ;
    --           INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_TYPE_CD' , FALSE);
    --           INTRFACE.Make_Field_Entrable('IMPORTERS.CITY_CODE_OF_ID' , FALSE);
    --           SET_ITEM_PROPERTY('IMPORTERS.CITY_CODE_OF_ID2' , ENABLED , PROPERTY_FALSE);
    --           INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_BRNCH' , FALSE);
    --       ELSE
    --           INTRFACE.Make_Field_Entrable('IMPORTERS.CITY_CODE_OF_ID' , TRUE);
    --           SET_ITEM_PROPERTY('IMPORTERS.CITY_CODE_OF_ID2' , ENABLED , PROPERTY_TRUE);
    --       END IF;
    --       INTRFACE.Make_Field_Entrable('IMPORTERS.CTRY_CD' , TRUE);
    --       INTRFACE.Make_Field_Entrable('IMPORTERS.ADD_CTRY_CD' , TRUE);
    --       :Global.Ins := 0;
    --   END;
    -- <<<
    PROCEDURE importers_wcr (p_rec IN OUT NOCOPY t_rec, p_ctx IN t_ctx)
    IS
    BEGIN
        p_rec.port_cd := p_ctx.curr_port_cd;
        SELECT port_name
          INTO p_rec.port_name
          FROM sd_ports
         WHERE port_cd = p_rec.port_cd;
        IF p_ctx.prsnl_impr = 1 THEN
            p_rec.impr_type_cd := 4;
            SELECT impr_type_name
              INTO p_rec.impr_type_name
              FROM impr_types
             WHERE impr_type_cd = p_rec.impr_type_cd;
            entrable('IMPR_TYPE_CD', FALSE);
            entrable('CITY_CODE_OF_ID', FALSE);
            ui('CITY_CODE_OF_ID2', 'ENABLED', FALSE);
            entrable('BUS_ID_BRNCH', FALSE);
        ELSE
            entrable('CITY_CODE_OF_ID', TRUE);
            ui('CITY_CODE_OF_ID2', 'ENABLED', TRUE);
        END IF;
        entrable('CTRY_CD', TRUE);
        entrable('ADD_CTRY_CD', TRUE);
        g_set('INS', '0');
    END importers_wcr;

    -- Shared by IMPR1110F1 / IMPR1110F5: count + name from COMM_IMPR_RGSTR
    PROCEDURE comm_name (p_rec IN t_rec, p_cnt OUT NUMBER, p_name OUT VARCHAR2)
    IS
    BEGIN
        p_name := NULL;
        IF p_rec.comm_rgstrtn_type = 1 THEN
            SELECT COUNT(bus_id) INTO p_cnt
              FROM comm_impr_rgstr
             WHERE bus_id = p_rec.bus_id AND brnchreg = 0;
            IF p_cnt = 1 THEN
                SELECT arbc_impr_name INTO p_name
                  FROM comm_impr_rgstr
                 WHERE bus_id = p_rec.bus_id AND brnchreg = 0;
            END IF;
        ELSIF p_rec.comm_rgstrtn_type = 2 THEN
            SELECT COUNT(bus_id) INTO p_cnt
              FROM comm_impr_rgstr
             WHERE bus_id = p_rec.bus_id AND brnch_bus_id = p_rec.bus_id_brnch;
            IF p_cnt = 1 THEN
                SELECT arbc_impr_name INTO p_name
                  FROM comm_impr_rgstr
                 WHERE bus_id = p_rec.bus_id AND brnch_bus_id = p_rec.bus_id_brnch;
            END IF;
        ELSE
            p_cnt := NULL;
        END IF;
    END comm_name;

    FUNCTION wnri_confirm_text (p_rec IN t_rec, p_ctx IN t_ctx) RETURN VARCHAR2
    IS
        v_cnt  NUMBER;
        v_name VARCHAR2(500);
    BEGIN
        IF p_ctx.code IN ('IMPR1110F1', 'IMPR1110F5')
           AND p_rec.bus_id_type_cd = 2 AND p_rec.impr_type_cd != 12 THEN
            comm_name(p_rec, v_cnt, v_name);
            IF v_cnt = 1 THEN
                RETURN ' سيتم تعديل الإسم إلى ( ' || v_name || ' )';
            END IF;
        END IF;
        RETURN NULL;
    END wnri_confirm_text;

    -- Source: IMPORTERS.WHEN-NEW-RECORD-INSTANCE
    -- p_answer: answer to the CONFIRM of IMPR1110F1 / IMPR1110F5 (see wnri_confirm_text)
    --@ORIG IMPORTERS.WHEN-NEW-RECORD-INSTANCE
    -- >>> Original Forms code: IMPORTERS.WHEN-NEW-RECORD-INSTANCE
    --   DECLARE
    --       V_COUNT NUMBER;
    --       V_IMPR_NAME VARCHAR2(500);
    --         RET NUMBER;
    --         V_CNT NUMBER;
    --   BEGIN
    --   INTRFACE.Make_Field_Entrable('IMPORTERS.COMM_RGSTRTN_TYPE' , FALSE);
    --   INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_EXPRD_DT' , FALSE);
    --   INTRFACE.Make_Field_Entrable('IMPORTERS.CITY_CODE_OF_ID' , FALSE);
    --       :GLOBAL.FUNS_BUSID  := 0;
    --       :GLOBAL.FUNS_IMP    := 0 ;
    --       :GLOBAL.CHK_IMP_TYP := 0;
    --   IF :IMPR_NBR IS NULL THEN
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID' , TRUE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_EXPRD_DT' , TRUE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.ARBC_IMPR_NAME' , TRUE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.CITY_CODE_OF_ID',TRUE);
    --   IF :PARAMETER.P_CLASS_CD=1 AND :PARAMETER.P_USER_TYPE=3 THEN
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_EXPR_TYPE' , FALSE);
    --   ELSE
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_EXPR_TYPE' , TRUE);
    --   END IF;
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_TYPE_CD' , TRUE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_POB_NBR' , TRUE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_ZIP_CD' , TRUE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_TEL_NBR' , TRUE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_FAX_NBR' , TRUE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_TELEX_NBR' , TRUE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.COMM_RGSTRTN_TYPE' , FALSE);
    --   ELSE
    --   GO_ITEM('IMPR_NBR');
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID' , FALSE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_EXPRD_DT' , FALSE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.ARBC_IMPR_NAME' , FALSE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.COMM_RGSTRTN_TYPE' , FALSE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.CITY_CODE_OF_ID',FALSE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_EXPR_TYPE' , FALSE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_TYPE_CD' , FALSE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.BRNH_CITY_CD' , FALSE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_BRNCH', FALSE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_TYPE_CD' , FALSE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.CAR_AGENT_FLAG' , FALSE);
    --   END IF;
    --   IF :PARAMETER.CODE = 'IMPR1110F2' THEN
    --       :GLOBAL.FUNS_BUSID := 1;
    --       INTRFACE.Make_Field_Entrable('IMPORTERS.COMM_RGSTRTN_TYPE' , TRUE);
    --       INTRFACE.Make_Field_Entrable('IMPORTERS.CITY_CODE_OF_ID' , TRUE);
    --       INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID' , TRUE);
    --       INTRFACE.Make_Field_Entrable('IMPORTERS.BRNH_CITY_CD' , TRUE);
    --       INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_BRNCH', TRUE);
    --       GO_ITEM('IMPORTERS.COMM_RGSTRTN_TYPE');
    --       :PARAMETER.CODE:=NULL;
    --   ELSIF :PARAMETER.CODE = 'IMPR1110F1' THEN
    --        IF :BUS_ID_TYPE_CD = 2 AND :IMPR_TYPE_CD!=12  THEN
    --           IF :COMM_RGSTRTN_TYPE = 1 THEN
    --                   SELECT COUNT(BUS_ID) INTO V_CNT FROM COMM_IMPR_RGSTR
    --                   WHERE  BUS_ID=:BUS_ID
    --                    AND   BRNCHREG=0;
    --                   IF V_CNT >1 THEN
    --                    :PARAMETER.CODE:=NULL;
    --                       RET := STR.DispALERT('لا يمكن تعديل الإسم الرجاء مراجعة المساندة الفنية','ERROR');
    --                   RAISE FORM_TRIGGER_FAILURE;
    --               ELSIF V_CNT = 1 THEN
    --                          SELECT ARBC_IMPR_NAME INTO V_IMPR_NAME
    --                        FROM COMM_IMPR_RGSTR
    --                          WHERE BUS_ID   =:BUS_ID
    --                       AND   BRNCHREG =0;
    --                   RET := STR.DispALERT(' سيتم تعديل الإسم إلى ( '||V_IMPR_NAME ||' )' ,'CONFIRM');
    --                     IF Ret = alert_button1 THEN
    --                       :ARBC_IMPR_NAME :=V_IMPR_NAME ;
    --                   END IF;
    --                     :PARAMETER.CODE:=NULL;
    --               ELSE
    --                     :PARAMETER.CODE:=NULL;
    --                          RET := STR.DispALERT('لا يمكن تعديل الإسم الرجاء مراجعة المساندة الفنية','ERROR');
    --                   RAISE FORM_TRIGGER_FAILURE;
    --               END IF;
    --           ELSIF :COMM_RGSTRTN_TYPE = 2 THEN
    --               SELECT COUNT(BUS_ID)INTO V_CNT
    --               FROM  COMM_IMPR_RGSTR
    --               WHERE BUS_ID=:BUS_ID
    --               AND   BRNCH_BUS_ID=:BUS_ID_BRNCH;
    --               IF V_CNT >1 THEN
    --                     :PARAMETER.CODE:=NULL;
    --                       RET := STR.DispALERT('لا يمكن تعديل الإسم الرجاء مراجعة المساندة الفنية','ERROR');
    --                   RAISE FORM_TRIGGER_FAILURE;
    --               ELSIF V_CNT = 1 THEN
    --                   SELECT ARBC_IMPR_NAME INTO V_IMPR_NAME
    --                   FROM COMM_IMPR_RGSTR
    --                   WHERE  BUS_ID=:BUS_ID
    --                   AND   BRNCH_BUS_ID=:BUS_ID_BRNCH;
    --                   RET := STR.DispALERT(' سيتم تعديل الإسم إلى ( '||V_IMPR_NAME ||' )' ,'CONFIRM');
    --                   IF Ret = alert_button1 THEN
    --                       :ARBC_IMPR_NAME :=V_IMPR_NAME ;
    --                   END IF;
    --                     :PARAMETER.CODE:=NULL;
    --               ELSE
    --                       :PARAMETER.CODE:=NULL;
    --                          RET := STR.DispALERT('لا يمكن تعديل الإسم الرجاء مراجعة المساندة الفنية','ERROR');
    --                   RAISE FORM_TRIGGER_FAILURE;
    --               END IF;
    --           ELSE
    --                    :PARAMETER.CODE:=NULL;
    --                          RET := STR.DispALERT('لا يمكن تعديل الإسم الرجاء مراجعة المساندة الفنية','ERROR');
    --                   RAISE FORM_TRIGGER_FAILURE;
    --           END IF;
    --       ELSE
    --            :PARAMETER.CODE:=NULL;
    --           INTRFACE.Make_Field_Entrable('ARBC_IMPR_NAME', TRUE);
    --           GO_ITEM('ARBC_IMPR_NAME');
    --       END IF;
    --       :PARAMETER.CODE:=NULL;
    --   ELSIF :PARAMETER.CODE = 'IMPR1110F5' THEN
    --        IF :BUS_ID_TYPE_CD = 2 AND :IMPR_TYPE_CD!=12  THEN
    --           IF :COMM_RGSTRTN_TYPE = 1 THEN
    --                   SELECT COUNT(BUS_ID) INTO V_CNT FROM COMM_IMPR_RGSTR
    --                   WHERE  BUS_ID=:BUS_ID
    --                    AND   BRNCHREG=0;
    --                   IF V_CNT >1 THEN
    --                    :PARAMETER.CODE:=NULL;
    --                       RET := STR.DispALERT('لا يمكن تعديل الإسم الرجاء مراجعة المساندة الفنية','ERROR');
    --                   RAISE FORM_TRIGGER_FAILURE;
    --               ELSIF V_CNT = 1 THEN
    --                          SELECT ARBC_IMPR_NAME INTO V_IMPR_NAME
    --                        FROM COMM_IMPR_RGSTR
    --                          WHERE BUS_ID   =:BUS_ID
    --                       AND   BRNCHREG =0;
    --                   RET := STR.DispALERT(' سيتم تعديل الإسم إلى ( '||V_IMPR_NAME ||' )' ,'CONFIRM');
    --                     IF Ret = alert_button1 THEN
    --                       :ARBC_IMPR_NAME :=V_IMPR_NAME ;
    --                   ELSE
    --                       INTRFACE.Make_Field_Entrable('ARBC_IMPR_NAME', TRUE);
    --                       GO_ITEM('ARBC_IMPR_NAME');
    --                   END IF;
    --                     :PARAMETER.CODE:=NULL;
    --               ELSE
    --                   INTRFACE.Make_Field_Entrable('ARBC_IMPR_NAME', TRUE);
    --                   GO_ITEM('ARBC_IMPR_NAME');
    --                     :PARAMETER.CODE:=NULL;
    --               END IF;
    --           ELSIF :COMM_RGSTRTN_TYPE = 2 THEN
    --               SELECT COUNT(BUS_ID)INTO V_CNT
    --               FROM  COMM_IMPR_RGSTR
    --               WHERE BUS_ID=:BUS_ID
    --               AND   BRNCH_BUS_ID=:BUS_ID_BRNCH;
    --               IF V_CNT >1 THEN
    --                     :PARAMETER.CODE:=NULL;
    --                       RET := STR.DispALERT('لا يمكن تعديل الإسم الرجاء مراجعة المساندة الفنية','ERROR');
    --                   RAISE FORM_TRIGGER_FAILURE;
    --               ELSIF V_CNT = 1 THEN
    --                   SELECT ARBC_IMPR_NAME INTO V_IMPR_NAME
    --                   FROM COMM_IMPR_RGSTR
    --                   WHERE  BUS_ID=:BUS_ID
    --                   AND   BRNCH_BUS_ID=:BUS_ID_BRNCH;
    --                   RET := STR.DispALERT(' سيتم تعديل الإسم إلى ( '||V_IMPR_NAME ||' )' ,'CONFIRM');
    --                   IF Ret = alert_button1 THEN
    --                       :ARBC_IMPR_NAME :=V_IMPR_NAME ;
    --                   ELSE
    --                       INTRFACE.Make_Field_Entrable('ARBC_IMPR_NAME', TRUE);
    --                       GO_ITEM('ARBC_IMPR_NAME');
    --                   END IF;
    --                     :PARAMETER.CODE:=NULL;
    --               ELSE
    --                      INTRFACE.Make_Field_Entrable('ARBC_IMPR_NAME', TRUE);
    --                   GO_ITEM('ARBC_IMPR_NAME');
    --               END IF;
    --           ELSE
    --                      INTRFACE.Make_Field_Entrable('ARBC_IMPR_NAME', TRUE);
    --                   GO_ITEM('ARBC_IMPR_NAME');
    --           END IF;
    --       ELSE
    --           INTRFACE.Make_Field_Entrable('ARBC_IMPR_NAME', TRUE);
    --           GO_ITEM('ARBC_IMPR_NAME');
    --       END IF;
    --       :PARAMETER.CODE:=NULL;
    --   ELSIF :PARAMETER.CODE = 'IMPR1110F3' THEN
    --       :GLOBAL.FUNS_IMP := 1 ;
    --       :GLOBAL.CHK_IMP_TYP := 1;
    --       INTRFACE.Make_Field_Entrable('IMPR_TYPE_CD', TRUE);
    --       GO_ITEM('IMPR_TYPE_CD');
    --           IF :PARAMETER.P_CLASS_CD = 19 AND :PARAMETER.P_USER_TYPE = 1 THEN
    --           IF :IMPR_TYPE_CD <> 4 THEN
    --               INTRFACE.MAKE_BLOCK_FULL_OPERATION('IMPORTERS',FALSE,TRUE,FALSE);
    --               :IMPR_TYPE_CD := 19;
    --               STR.DISPALERT(' تم تعديل النشاط التجاري الى "مؤسسة/شركة/استثمارية "  ','INFORMATION');
    --               COMMIT;
    --               INTRFACE.MAKE_BLOCK_FULL_OPERATION('IMPORTERS',FALSE,FALSE,FALSE);
    --           END IF ;
    --           IF :IMPR_TYPE_CD = 4 THEN
    --                 STR.DISPALERT('لا يمكن التعديل  للمستورد الشخصي الا من خلال الدعم الفني التطبيقات','ERROR');
    --           END IF ;
    --           END IF;
    --       :PARAMETER.CODE:=NULL;
    --   ELSIF :PARAMETER.CODE = 'IMPR1110F4' THEN
    --         INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_EXPRD_DT',TRUE);
    --       GO_ITEM('IMPORTERS.BUS_ID_EXPRD_DT');
    --         :PARAMETER.CODE:=NULL;
    --   ELSIF :PARAMETER.CODE = 'IMPR1110SF6' THEN
    --         INTRFACE.Make_Field_Entrable('IMPORTERS.CAR_AGENT_FLAG',TRUE);
    --       GO_ITEM('IMPORTERS.CAR_AGENT_FLAG');
    --         :PARAMETER.CODE:=NULL;
    --    END IF;
    --   END;
    --           SET_ITEM_PROPERTY('IMPORTERS.CITY_CODE_OF_ID' ,REQUIRED,PROPERTY_FALSE);
    --           SET_ITEM_PROPERTY('IMPORTERS.BRNH_CITY_CD' ,REQUIRED,PROPERTY_FALSE);
    --   declare
    --             RET NUMBER;
    --   BEGIN
    --   IF :IMPR_TYPE_CD = 4  AND  :BUS_ID_TYPE_CD = 3
    --   OR :IMPR_TYPE_CD = 4  AND  :BUS_ID_TYPE_CD = 5 THEN
    --   :CTRY_CD := 100;
    --   SET_ITEM_PROPERTY('CTRY_CD', ENABLED,PROPERTY_FALSE);
    --   SELECT CRTY_ARBC_NAME INTO :CRTY_ARBC_NAME
    --    FROM   COUNTRIES
    --    WHERE  CTRY_CD = 100;
    --   END IF;
    --   :ADD_CTRY_CD := 100 ;
    --   SET_ITEM_PROPERTY('ADD_CTRY_CD', ENABLED,PROPERTY_FALSE);
    --   SELECT CRTY_ARBC_NAME INTO :ADD_CRTY_ARBC_NAME
    --    FROM   COUNTRIES
    --    WHERE  CTRY_CD = 100;
    --   EXCEPTION
    --   WHEN NO_DATA_FOUND THEN
    --     ret := Str.DispArbMsg(18, 15,'ERROR');
    --     RAISE FORM_TRIGGER_FAILURE;
    --   END;
    -- <<<
    PROCEDURE importers_wnri (p_rec    IN OUT NOCOPY t_rec,
                              p_ctx    IN OUT NOCOPY t_ctx,
                              p_answer IN PLS_INTEGER DEFAULT c_yes)
    IS
        v_cnt       NUMBER;
        v_impr_name VARCHAR2(500);
        c_no_rename CONSTANT VARCHAR2(100) := 'لا يمكن تعديل الإسم الرجاء مراجعة المساندة الفنية';
    BEGIN
        entrable('COMM_RGSTRTN_TYPE', FALSE);
        entrable('BUS_ID_EXPRD_DT', FALSE);
        entrable('CITY_CODE_OF_ID', FALSE);
        g_set('FUNS_BUSID', '0');
        g_set('FUNS_IMP', '0');
        g_set('CHK_IMP_TYP', '0');
        IF p_rec.impr_nbr IS NULL THEN
            entrable('BUS_ID', TRUE);
            entrable('BUS_ID_EXPRD_DT', TRUE);
            entrable('ARBC_IMPR_NAME', TRUE);
            entrable('CITY_CODE_OF_ID', TRUE);
            IF p_ctx.class_cd = 1 AND p_ctx.user_type = 3 THEN
                entrable('IMPR_EXPR_TYPE', FALSE);
            ELSE
                entrable('IMPR_EXPR_TYPE', TRUE);
            END IF;
            entrable('IMPR_TYPE_CD', TRUE);
            entrable('IMPR_POB_NBR', TRUE);
            entrable('IMPR_ZIP_CD', TRUE);
            entrable('IMPR_TEL_NBR', TRUE);
            entrable('IMPR_FAX_NBR', TRUE);
            entrable('IMPR_TELEX_NBR', TRUE);
            entrable('COMM_RGSTRTN_TYPE', FALSE);
        ELSE
            ui_focus('IMPR_NBR');
            entrable('BUS_ID', FALSE);
            entrable('BUS_ID_EXPRD_DT', FALSE);
            entrable('ARBC_IMPR_NAME', FALSE);
            entrable('COMM_RGSTRTN_TYPE', FALSE);
            entrable('CITY_CODE_OF_ID', FALSE);
            entrable('IMPR_EXPR_TYPE', FALSE);
            entrable('IMPR_TYPE_CD', FALSE);
            entrable('BRNH_CITY_CD', FALSE);
            entrable('BUS_ID_BRNCH', FALSE);
            entrable('BUS_ID_TYPE_CD', FALSE);
            entrable('CAR_AGENT_FLAG', FALSE);
        END IF;

        IF p_ctx.code = 'IMPR1110F2' THEN
            g_set('FUNS_BUSID', '1');
            entrable('COMM_RGSTRTN_TYPE', TRUE);
            entrable('CITY_CODE_OF_ID', TRUE);
            entrable('BUS_ID', TRUE);
            entrable('BRNH_CITY_CD', TRUE);
            entrable('BUS_ID_BRNCH', TRUE);
            ui_focus('COMM_RGSTRTN_TYPE');
            p_ctx.code := NULL;
        ELSIF p_ctx.code = 'IMPR1110F1' THEN
            IF p_rec.bus_id_type_cd = 2 AND p_rec.impr_type_cd != 12 THEN
                IF p_rec.comm_rgstrtn_type IN (1, 2) THEN
                    comm_name(p_rec, v_cnt, v_impr_name);
                    IF v_cnt > 1 THEN
                        p_ctx.code := NULL;
                        ftf(c_no_rename);
                    ELSIF v_cnt = 1 THEN
                        IF p_answer = c_yes THEN       -- CONFIRM: wnri_confirm_text
                            p_rec.arbc_impr_name := v_impr_name;
                        END IF;
                        p_ctx.code := NULL;
                    ELSE
                        p_ctx.code := NULL;
                        ftf(c_no_rename);
                    END IF;
                ELSE
                    p_ctx.code := NULL;
                    ftf(c_no_rename);
                END IF;
            ELSE
                p_ctx.code := NULL;
                entrable('ARBC_IMPR_NAME', TRUE);
                ui_focus('ARBC_IMPR_NAME');
            END IF;
            p_ctx.code := NULL;
        ELSIF p_ctx.code = 'IMPR1110F5' THEN
            IF p_rec.bus_id_type_cd = 2 AND p_rec.impr_type_cd != 12 THEN
                IF p_rec.comm_rgstrtn_type IN (1, 2) THEN
                    comm_name(p_rec, v_cnt, v_impr_name);
                    IF v_cnt > 1 THEN
                        p_ctx.code := NULL;
                        ftf(c_no_rename);
                    ELSIF v_cnt = 1 THEN
                        IF p_answer = c_yes THEN       -- CONFIRM: wnri_confirm_text
                            p_rec.arbc_impr_name := v_impr_name;
                        ELSE
                            entrable('ARBC_IMPR_NAME', TRUE);
                            ui_focus('ARBC_IMPR_NAME');
                        END IF;
                        p_ctx.code := NULL;
                    ELSE
                        entrable('ARBC_IMPR_NAME', TRUE);
                        ui_focus('ARBC_IMPR_NAME');
                        IF p_rec.comm_rgstrtn_type = 1 THEN   -- Forms resets CODE only in this branch
                            p_ctx.code := NULL;
                        END IF;
                    END IF;
                ELSE
                    entrable('ARBC_IMPR_NAME', TRUE);
                    ui_focus('ARBC_IMPR_NAME');
                END IF;
            ELSE
                entrable('ARBC_IMPR_NAME', TRUE);
                ui_focus('ARBC_IMPR_NAME');
            END IF;
            p_ctx.code := NULL;
        ELSIF p_ctx.code = 'IMPR1110F3' THEN
            g_set('FUNS_IMP', '1');
            g_set('CHK_IMP_TYP', '1');
            entrable('IMPR_TYPE_CD', TRUE);
            ui_focus('IMPR_TYPE_CD');
            IF p_ctx.class_cd = 19 AND p_ctx.user_type = 1 THEN
                IF p_rec.impr_type_cd <> 4 THEN
                    -- INTRFACE.MAKE_BLOCK_FULL_OPERATION('IMPORTERS',FALSE,TRUE,FALSE): update only
                    ui('IMPORTERS', 'BLOCK_UPDATE_ONLY', TRUE);
                    p_rec.impr_type_cd := 19;
                    info(' تم تعديل النشاط التجاري الى "مؤسسة/شركة/استثمارية "  ');
                    -- HIGH: Forms COMMIT here (fires PRE-UPDATE/UPDATE/POST-UPDATE). Recorded as
                    -- DO_COMMIT: the page must submit with request SAVE right after this call.
                    ui('IMPORTERS', 'DO_COMMIT', TRUE);
                END IF;
                IF p_rec.impr_type_cd = 4 THEN
                    info('لا يمكن التعديل  للمستورد الشخصي الا من خلال الدعم الفني التطبيقات');
                END IF;
            END IF;
            p_ctx.code := NULL;
        ELSIF p_ctx.code = 'IMPR1110F4' THEN
            entrable('BUS_ID_EXPRD_DT', TRUE);
            ui_focus('BUS_ID_EXPRD_DT');
            p_ctx.code := NULL;
        ELSIF p_ctx.code = 'IMPR1110SF6' THEN
            entrable('CAR_AGENT_FLAG', TRUE);
            ui_focus('CAR_AGENT_FLAG');
            p_ctx.code := NULL;
        END IF;

        ui('CITY_CODE_OF_ID', 'REQUIRED', FALSE);
        ui('BRNH_CITY_CD', 'REQUIRED', FALSE);
        ctry_100_defaults(p_rec);
    END importers_wnri;

    -- Source: IMPORTERS.PRE-RECORD
    --@ORIG IMPORTERS.PRE-RECORD
    -- >>> Original Forms code: IMPORTERS.PRE-RECORD
    --   DECLARE
    --       ret NUMBER;
    --       CURSOR C_P_NAME IS
    --               SELECT ARBC_IMPR_NAME
    --           FROM IMPORTERS
    --           WHERE IMPR_NBR = :IMPR_NBR_PARENT
    --               AND PORT_CD=:PARAMETER.P_CURR_PORT_CD;
    --   BEGIN
    --   IF :IMPR_NBR_PARENT IS NOT NULL THEN
    --       OPEN C_P_NAME;
    --       FETCH C_P_NAME INTO :IMPR_NAME_PARENT;
    --       IF C_P_NAME%NOTFOUND THEN
    --           ret := Str.DispArbMsg(9, 150,'ERROR');
    --       END IF;
    --       CLOSE C_P_NAME;
    --   END IF;
    --   END;
    -- <<<
    PROCEDURE importers_pre_rec (p_rec IN OUT NOCOPY t_rec, p_ctx IN t_ctx)
    IS
        CURSOR c_p_name IS
            SELECT arbc_impr_name
              FROM importers
             WHERE impr_nbr = p_rec.impr_nbr_parent
               AND port_cd  = p_ctx.curr_port_cd;
    BEGIN
        IF p_rec.impr_nbr_parent IS NOT NULL THEN
            OPEN c_p_name;
            FETCH c_p_name INTO p_rec.impr_name_parent;
            IF c_p_name%NOTFOUND THEN
                disp_arb_info(9, 150);
            END IF;
            CLOSE c_p_name;
        END IF;
    END importers_pre_rec;

    -- Source: IMPORTERS.WHEN-CLEAR-BLOCK
    PROCEDURE importers_wcb
    IS
    BEGIN
        g_set('STAT_CLR', '1');
    END importers_wcb;

    -- Source: IMPORTERS.PRE-QUERY. p_rec holds the query criteria (Enter-Query values).
    -- The CGFK$DEFAULT_WHERE part (PORT_NAME criterion -> PORT_CD IN (SELECT ... SD_PORTS))
    -- belongs in the region query - see extraction report §3.3.
    --@ORIG IMPORTERS.PRE-QUERY
    -- >>> Original Forms code: IMPORTERS.PRE-QUERY
    --   BEGIN
    --       IF :PARAMETER.PRSNL_IMPR = 1 THEN
    --           :IMPR_TYPE_CD := 4;
    --       END IF;
    --       IF (:global.Exec_Query_Now = 1) THEN
    --           IF (:global.IMPR_NBR  IS NOT NULL ) THEN
    --               :IMPORTERS.PORT_CD  := :global.PORT_CD;
    --               :IMPORTERS.IMPR_NBR  := :global.IMPR_NBR;
    --           END IF;
    --           :global.Exec_Query_Now := 0;
    --           :global.PORT_CD  := NULL;
    --           :global.IMPR_NBR  := NULL;
    --       ELSE
    --           :IMPR_NAME_STD := STR.StrFormat(:ARBC_IMPR_NAME, TRUE);
    --           :ARBC_IMPR_NAME := '';
    --       END IF;
    --   END;
    --   BEGIN
    --     DECLARE
    --       block_id   Block := find_block('IMPORTERS');
    --       sub_where  VARCHAR2(4000) := NULL;
    --       def_where  VARCHAR2(4000) := NULL;
    --       r_string   VARCHAR2(512) := NULL;
    --       FUNCTION add_and(
    --         P_WHERE IN VARCHAR2
    --       ) RETURN VARCHAR2 IS
    --       BEGIN
    --         IF (nvl( length(P_WHERE), 0) != 0) THEN
    --           RETURN( P_WHERE || ' AND ');
    --         ELSE
    --           RETURN( P_WHERE );
    --         END IF;
    --       END;
    --     BEGIN
    --       IF ( CG$IMPR1110_PROD_CENTRL_GLOBAL.IMPORTERS_WHERE = 'first_time') THEN
    --         CG$IMPR1110_PROD_CENTRL_GLOBAL.IMPORTERS_WHERE := get_block_property(block_id, DEFAULT_WHERE);
    --       END IF;
    --       def_where := CG$IMPR1110_PROD_CENTRL_GLOBAL.IMPORTERS_WHERE;
    --       sub_where := NULL;
    --       r_string := NAME_IN('IMPORTERS.PORT_NAME');
    --       IF (r_string IS NOT NULL) THEN
    --         BEGIN
    --           IF substr(r_string, 1,1) IN ('<','>','=') THEN
    --             sub_where := add_and( sub_where ) || '(PORT_NAME '|| r_string || ')';
    --           ELSIF substr(r_string, 1,1) ='#' THEN
    --             sub_where := add_and( sub_where ) || '(PORT_NAME '|| substr(r_string,2) || ')';
    --           ELSIF instr(r_string, '%') <> 0 THEN
    --             sub_where := add_and( sub_where ) || '(PORT_NAME LIKE '''|| replace(r_string,'''','''''') || ''')';
    --           ELSE
    --             sub_where := add_and( sub_where ) || '(PORT_NAME ='''|| replace(r_string,'''','''''') || ''')';
    --           END IF;
    --         END;
    --       END IF;
    --       IF (sub_where IS NOT NULL) THEN
    --         def_where := add_and( def_where ) || '((PORT_CD) IN '||'(SELECT PORT_CD '||'FROM SD_PORTS WHERE '|| sub_where || '))';
    --       END IF;
    --       set_block_property(block_id, DEFAULT_WHERE, def_where);
    --     EXCEPTION
    --       WHEN VALUE_ERROR THEN
    --         Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(33, 'Query criteria too complex - simplify and re-query'), 'E', 'OFG', 33);
    --         Des$Form_errors.RAISE_FAILURE;
    --     END;
    --   END;
    -- <<<
    PROCEDURE importers_pre_qry (p_rec IN OUT NOCOPY t_rec, p_ctx IN t_ctx)
    IS
    BEGIN
        IF p_ctx.prsnl_impr = 1 THEN
            p_rec.impr_type_cd := 4;
        END IF;
        IF (g_get('EXEC_QUERY_NOW') = '1') THEN
            IF (g_get('IMPR_NBR') IS NOT NULL) THEN
                p_rec.port_cd  := g_get('PORT_CD');
                p_rec.impr_nbr := g_get('IMPR_NBR');
            END IF;
            g_set('EXEC_QUERY_NOW', '0');
            g_set('PORT_CD', NULL);
            g_set('IMPR_NBR', NULL);
        ELSE
            -- STR.StrFormat(x, TRUE): client STR.pll is MISSING SOURCE; the server twin
            -- STR_DB.StrFormat is used by the form (GET_CR_DATA) with one argument only.
            -- TODO: verify STR_DB.StrFormat has the 2-argument overload.
            p_rec.impr_name_std  := str_db.strformat(p_rec.arbc_impr_name, TRUE);
            p_rec.arbc_impr_name := '';
        END IF;
    END importers_pre_qry;

    -- Source: IMPORTERS.POST-QUERY
    --@ORIG IMPORTERS.POST-QUERY
    -- >>> Original Forms code: IMPORTERS.POST-QUERY
    --   DECLARE
    --   V_COUNT NUMBER := 0 ;
    --   XDT DATE ;
    --   BEGIN
    --   :GLOBAL.OLD_impr_type_cd :=  :impr_type_cd ;
    --   :GLOBAL.OLD_PORT_CD      := :PORT_CD ;
    --   IF :IMPORTERS.IMPR_NBR IS NOT NULL THEN
    --       BEGIN
    --           XDT := HIJDATE.Cur_Hij_Date ;
    --           SELECT COUNT(*) INTO V_COUNT
    --           FROM IMPORTERS IMP, IMPR_SUSPNS IS_1
    --           WHERE
    --           IMP.PORT_CD = :IMPORTERS.PORT_CD AND
    --           IMP.IMPR_NBR = :IMPORTERS.IMPR_NBR  AND
    --           IS_1.PORT_CD = IMP.PORT_CD AND
    --           IS_1.IMPR_NBR = IMP.IMPR_NBR AND
    --           TO_CHAR(IS_1.SUSPN_STRT_DT, 'YYYY-MM-MI') <= TO_CHAR(XDT, 'YYYY-MM-MI') AND
    --           TO_CHAR(IS_1.SUSPN_END_DT, 'YYYY-MM-MI') >= TO_CHAR(XDT, 'YYYY-MM-MI') AND
    --           IS_1.SUSPN_RLSE_DT IS NULL;
    --               IF  V_COUNT >= 1 THEN
    --                   :IMPORTERS.SUSPN_STATUS := 'موقوف';
    --               ELSE
    --                   :IMPORTERS.SUSPN_STATUS := 'غير موقوف';
    --               END IF;
    --       IF V_COUNT = 0 THEN
    --               SELECT COUNT(*) INTO V_COUNT
    --               FROM   IMPR_DUTY_DIFF_BLKS
    --               WHERE  HQ_IMPR_NBR = :HQ_IMPR_NBR
    --               AND    BLK_RLS_DT IS NULL
    --               ;
    --               IF  V_COUNT > 0 THEN
    --               SELECT COUNT (*) INTO V_COUNT
    --     FROM (SELECT 1
    --             FROM duty_diff_blk_exp_dtls d1, stats_dcltns d2, importers d3
    --            WHERE d1.stats_isn IS NOT NULL
    --              AND d1.dcltn_stat_port_cd = d2.port_cd
    --              AND d1.stats_isn = d2.stats_isn
    --              AND d2.port_cd = d3.port_cd
    --              AND d2.impr_expr_nbr = d3.impr_nbr
    --              AND d3.hq_impr_nbr = :hq_impr_nbr
    --              AND d2.stats_status NOT IN (7, 8, 10)
    --           UNION ALL
    --           SELECT 1
    --             FROM duty_diff_blk_exp_dtls d1, declarations d2, importers d3
    --            WHERE d1.dcltn_isn IS NOT NULL
    --              AND d1.dcltn_stat_port_cd = d2.port_cd
    --              AND d1.dcltn_isn = d2.dcltn_isn
    --              AND d2.port_cd = d3.port_cd
    --              AND d2.impr_nbr = d3.impr_nbr
    --              AND d3.hq_impr_nbr = :hq_impr_nbr
    --              AND d2.dcltn_sta_cd <> 9
    --           UNION ALL
    --           SELECT 1
    --             FROM duty_diff_blk_exp_dtls d1
    --            WHERE d1.from_date IS NOT NULL
    --              AND d1.hq_impr_nbr = :hq_impr_nbr
    --              AND hijdate_db.cur_hij_date BETWEEN d1.from_date AND d1.TO_DATE);
    --   IF NVL (gnrl.get_customs_setting ('CRQ24602_RUN', 21), 0) =  0 THEN
    --               IF V_COUNT = 0 THEN
    --                   :IMPORTERS.SUSPN_STATUS := 'موقوف(تدقيق عام)';
    --               else
    --                   :IMPORTERS.SUSPN_STATUS := 'موقوف(تدقيق)له استثناء';
    --               END IF;
    --   elsif NVL (gnrl.get_customs_setting ('CRQ24602_RUN', 21), 0) =  1 THEN
    --               IF V_COUNT = 0 THEN
    --                   :IMPORTERS.SUSPN_STATUS := '';
    --               ELSE
    --                   :IMPORTERS.SUSPN_STATUS := '';
    --               END IF;
    --   END IF;
    --       END IF;
    --           END IF;
    --           IF V_COUNT = 0 THEN
    --               DECLARE
    --                   V_SUSPN_RSN_TEXT VARCHAR2(2000) := '';
    --               BEGIN
    --                   SELECT SUSPN_RSN_TEXT INTO V_SUSPN_RSN_TEXT
    --                   FROM   IMPR_CNTRL_SUSPNS
    --                   WHERE  HQ_IMPR_NBR = :HQ_IMPR_NBR
    --                   AND    TO_CHAR(SUSPN_STRT_DT, 'YYYY-MM-MI') <= TO_CHAR(XDT, 'YYYY-MM-MI')
    --                   AND    TO_CHAR(SUSPN_END_DT, 'YYYY-MM-MI') >= TO_CHAR(XDT, 'YYYY-MM-MI')
    --                   AND    SUSPN_RLSE_DT  IS NULL;
    --                   :IMPORTERS.SUSPN_STATUS := 'إيقاف مركزي من قبل المصلحة - إدارة القيود بسبب '||V_SUSPN_RSN_TEXT;
    --               EXCEPTION
    --                   WHEN NO_DATA_FOUND THEN NULL;
    --               END;
    --           END IF;
    --       EXCEPTION    WHEN OTHERS THEN
    --           NULL;
    --       END;
    --   END IF;
    --   :B_MOBILE_NO := :MOBILE_NO;
    --   :B_ID_NBR := :ID_NBR;
    --   :B_EMAIL := :EMAIL;
    --   :GLOBAL.STAT_QUE:=1;
    --       IF :IMPORTERS.IMPR_TYPE_CD = 1 THEN
    --           INTRFACE.Make_Field_Entrable('IMPORTERS.CTRY_CD' , FALSE);
    --           INTRFACE.Make_Field_Entrable('IMPORTERS.ADD_CTRY_CD' , FALSE);
    --       ELSIF :IMPORTERS.IMPR_TYPE_CD = 2 THEN
    --           INTRFACE.Make_Field_Entrable('IMPORTERS.CTRY_CD' , FALSE);
    --           INTRFACE.Make_Field_Entrable('IMPORTERS.ADD_CTRY_CD' , FALSE);
    --           INTRFACE.Make_Field_Entrable('IMPORTERS.CITY_CODE_OF_ID' , FALSE);
    --           SET_ITEM_PROPERTY('IMPORTERS.CITY_CODE_OF_ID2' , ENABLED , PROPERTY_FALSE);
    --           INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_BRNCH' , FALSE);
    --       ELSIF :IMPORTERS.IMPR_TYPE_CD = 4 THEN
    --           INTRFACE.Make_Field_Entrable('IMPORTERS.CITY_CODE_OF_ID' , FALSE);
    --           SET_ITEM_PROPERTY('IMPORTERS.CITY_CODE_OF_ID2' , ENABLED , PROPERTY_FALSE);
    --           INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_BRNCH' , FALSE);
    --       ELSIF :IMPORTERS.IMPR_TYPE_CD = 5 THEN
    --           INTRFACE.Make_Field_Entrable('IMPORTERS.CTRY_CD' , FALSE);
    --           INTRFACE.Make_Field_Entrable('IMPORTERS.ADD_CTRY_CD' , FALSE);
    --       ELSIF :IMPORTERS.IMPR_TYPE_CD = 7 THEN
    --           INTRFACE.Make_Field_Entrable('IMPORTERS.CITY_CODE_OF_ID' , FALSE);
    --           SET_ITEM_PROPERTY('IMPORTERS.CITY_CODE_OF_ID2' , ENABLED , PROPERTY_FALSE);
    --           INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_BRNCH' , FALSE);
    --       ELSIF :IMPORTERS.IMPR_TYPE_CD = 8 THEN
    --           INTRFACE.Make_Field_Entrable('IMPORTERS.CTRY_CD' , FALSE);
    --           INTRFACE.Make_Field_Entrable('IMPORTERS.ADD_CTRY_CD' , FALSE);
    --       ELSIF :IMPORTERS.IMPR_TYPE_CD = 9 THEN
    --           IF :IMPORTERS.BUS_ID_TYPE_CD = 6 THEN
    --               INTRFACE.Make_Field_Entrable('IMPORTERS.CTRY_CD' , FALSE);
    --               INTRFACE.Make_Field_Entrable('IMPORTERS.ADD_CTRY_CD' , FALSE);
    --               INTRFACE.Make_Field_Entrable('IMPORTERS.CITY_CODE_OF_ID' , FALSE);
    --               SET_ITEM_PROPERTY('IMPORTERS.CITY_CODE_OF_ID2' , ENABLED , PROPERTY_FALSE);
    --               INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_BRNCH' , FALSE);
    --               INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID' , FALSE);
    --           ELSE
    --               INTRFACE.Make_Field_Entrable('IMPORTERS.CTRY_CD' , TRUE);
    --               INTRFACE.Make_Field_Entrable('IMPORTERS.ADD_CTRY_CD' , TRUE);
    --               INTRFACE.Make_Field_Entrable('IMPORTERS.CITY_CODE_OF_ID' , TRUE);
    --               SET_ITEM_PROPERTY('IMPORTERS.CITY_CODE_OF_ID2' , ENABLED , PROPERTY_TRUE);
    --               INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID' , TRUE);
    --               INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_BRNCH' , FALSE);
    --           END IF;
    --       ELSIF :IMPORTERS.IMPR_TYPE_CD = 10 THEN
    --               INTRFACE.Make_Field_Entrable('IMPORTERS.CITY_CODE_OF_ID' , FALSE);
    --               SET_ITEM_PROPERTY('IMPORTERS.CITY_CODE_OF_ID2' , ENABLED , PROPERTY_FALSE);
    --               INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_BRNCH' , FALSE);
    --       ELSIF :IMPORTERS.IMPR_TYPE_CD = 11 THEN
    --               INTRFACE.Make_Field_Entrable('IMPORTERS.CTRY_CD' , FALSE);
    --               INTRFACE.Make_Field_Entrable('IMPORTERS.ADD_CTRY_CD' , FALSE);
    --               INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_BRNCH' , FALSE);
    --       ELSIF :IMPORTERS.IMPR_TYPE_CD = 12 THEN
    --               INTRFACE.Make_Field_Entrable('IMPORTERS.CITY_CODE_OF_ID' , FALSE);
    --               SET_ITEM_PROPERTY('IMPORTERS.CITY_CODE_OF_ID2' , ENABLED , PROPERTY_FALSE);
    --       ELSIF :IMPORTERS.IMPR_TYPE_CD IN (13, 14) THEN
    --               INTRFACE.Make_Field_Entrable('IMPORTERS.CTRY_CD' , FALSE);
    --               INTRFACE.Make_Field_Entrable('IMPORTERS.ADD_CTRY_CD' , FALSE);
    --               INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID' , FALSE);
    --               INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_BRNCH' , FALSE);
    --               INTRFACE.Make_Field_Entrable('IMPORTERS.CITY_CODE_OF_ID' , FALSE);
    --               SET_ITEM_PROPERTY('IMPORTERS.CITY_CODE_OF_ID2' , ENABLED , PROPERTY_FALSE);
    --       END IF;
    --   DECLARE
    --   V_USER_BUS_ID VARCHAR2(4);
    --   BEGIN
    --      IF :IMPORTERS.BUS_ID_TYPE_CD = 2 AND :IMPORTERS.IMPR_TYPE_CD != 12  THEN
    --         IF :BUS_ID_BRNCH IS NOT NULL THEN
    --           BEGIN
    --             V_USER_BUS_ID := SUBSTR(:IMPORTERS.BUS_ID_BRNCH, 1, 4);
    --             SELECT  CITY_CD,CITY_ARB_NAME INTO  :IMPORTERS.BRNH_CITY_CD,:IMPORTERS.BRNH_CITY_NAME
    --           FROM    CITIES
    --           WHERE   CTRY_CD      = 100
    --             AND     MINS_COMM_CD = V_USER_BUS_ID ;
    --           EXCEPTION
    --             WHEN OTHERS THEN
    --            NULL;
    --           END;
    --         END IF;
    --      END IF;
    --   END;
    --   END;
    --   BEGIN
    --      SELECT status_desc
    --        INTO :importers.status_desc
    --        FROM mci_bus_id_status
    --       WHERE bus_id_status LIKE :importers.bus_id_status;
    --   EXCEPTION
    --      WHEN OTHERS THEN NULL;
    --   END;
    --   DECLARE
    --   V_EXPIRY_DATE DATE;
    --   V_DUMMY NUMBER(1);
    --   begin
    --     SELECT MAX(EXPIRY_DATE)
    --     INTO   V_EXPIRY_DATE
    --       FROM   PRIVILEGED_IMPORTERS
    --       WHERE  IMPR_PRIVILEGE_TYPE = 3
    --       AND    REC_STATUS = 1
    --       AND    IMPR_NBR = :IMPORTERS.IMPR_NBR;
    --       IF V_EXPIRY_DATE IS NOT NULL THEN
    --           IF V_EXPIRY_DATE < hijdate_db.cur_hij_date THEN
    --               :IMPR_ID_TYPE := 'اقامة عادية';
    --           ELSE
    --               :IMPR_ID_TYPE := 'اقامة مميزة محددة المدة تنتهي بتاريخ '||TO_CHAR(V_EXPIRY_DATE,'MI-MM-YYYY');
    --           END IF;
    --       ELSE
    --         BEGIN
    --         SELECT 1
    --           INTO   V_DUMMY
    --           FROM   PRIVILEGED_IMPORTERS
    --           WHERE  IMPR_PRIVILEGE_TYPE = 3
    --         AND    REC_STATUS = 1
    --           AND    IMPR_NBR = :IMPORTERS.IMPR_NBR
    --           AND    ROWNUM  =  1;
    --           :IMPR_ID_TYPE := 'اقامة مميزة دائمة ';
    --         EXCEPTION
    --             WHEN NO_DATA_FOUND THEN
    --                  :IMPR_ID_TYPE := 'عادية';
    --         END;
    --       END IF;
    --   END;
    --   ADJ_FUNS;
    --   BEGIN
    --     IF (name_in('IMPORTERS.PORT_CD') IS NOT NULL) THEN
    --       BEGIN
    --        SELECT L_SDP.PORT_STATUS,L_SDP.PORT_NAME
    --               INTO  :IMPORTERS.SDP_PORT_STATUS,:IMPORTERS.PORT_NAME
    --         FROM   SD_PORTS L_SDP
    --         WHERE  L_SDP.PORT_CD = :IMPORTERS.PORT_CD;
    --       EXCEPTION
    --         WHEN NO_DATA_FOUND THEN
    --           Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(13, 'This <p1> does not exist', 'رمز الجمــــــــــــــرك' ), 'E', 'OFG', 13);
    --         WHEN OTHERS THEN
    --           CGTE$OTHER_EXCEPTIONS;
    --       END;
    --       SET_RECORD_PROPERTY(:SYSTEM.TRIGGER_RECORD, 'IMPORTERS', STATUS ,                 QUERY_STATUS);
    --     END IF;
    --     IF (name_in('IMPORTERS.IMPR_TYPE_CD') IS NOT NULL AND name_in('IMPORTERS.BUS_ID_TYPE_CD') IS NOT NULL) THEN
    --       BEGIN
    --         CGFK$QRY_IMPORTERS_IMP_ITIDT_F(
    --           :IMPORTERS.BUS_ID_TYPE_NAME
    --          ,:IMPORTERS.IMPR_TYPE_NAME
    --          ,:IMPORTERS.STATUS
    --          ,:IMPORTERS.ITIDT_NOTE
    --          ,:IMPORTERS.IMPR_TYPE_CD
    --          ,:IMPORTERS.BUS_ID_TYPE_CD  );
    --       EXCEPTION
    --         WHEN NO_DATA_FOUND THEN
    --           Des$Form_errors.PUSH('رمز النشاط التجاري غير صحيح - أعد إدخال البيانات', 'E', 'OFG', 0);
    --         WHEN OTHERS THEN
    --           CGTE$OTHER_EXCEPTIONS;
    --       END;
    --       SET_RECORD_PROPERTY(:SYSTEM.TRIGGER_RECORD, 'IMPORTERS', STATUS ,                 QUERY_STATUS);
    --     ELSE
    --         Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(78, '<p1> must be entered', 'رمز النشاط التجارى' ), 'E', 'OFG', 78);
    --         Des$Form_errors.RAISE_FAILURE;
    --     END IF;
    --     IF (name_in('IMPORTERS.CTRY_CD') IS NOT NULL) THEN
    --       BEGIN
    --         CGFK$QRY_IMPORTERS_IMP_CTRY_FK(
    --           :IMPORTERS.CTRY_CTRY_STATUS
    --          ,:IMPORTERS.CRTY_ARBC_NAME
    --          ,:IMPORTERS.CTRY_CD         );
    --       EXCEPTION
    --         WHEN NO_DATA_FOUND THEN
    --           Des$Form_errors.PUSH('رمز الدولة غير صحيح - أعد ادخال البيانات', 'E', 'OFG', 0);
    --         WHEN OTHERS THEN
    --           CGTE$OTHER_EXCEPTIONS;
    --       END;
    --       SET_RECORD_PROPERTY(:SYSTEM.TRIGGER_RECORD, 'IMPORTERS', STATUS ,                 QUERY_STATUS);
    --     END IF;
    --     IF (name_in('IMPORTERS.CITY_CODE_OF_ID') IS NOT NULL AND name_in('IMPORTERS.CTRY_CD_OF_ID') IS NOT NULL) THEN
    --       BEGIN
    --         CGFK$QRY_IMPORTERS_IMP_BUS_ID_(
    --           :IMPORTERS.ID_MINS_COMM_CD
    --          ,:IMPORTERS.ID_CITY_NAME
    --          ,:IMPORTERS.L_CT_CITY_STATUS2
    --          ,:IMPORTERS.CTRY_CD_OF_ID
    --          ,:IMPORTERS.CITY_CODE_OF_ID  );
    --       EXCEPTION
    --         WHEN NO_DATA_FOUND THEN
    --           Des$Form_errors.PUSH('خطأ في رمز مدينة مصدر الرقم الإستدلالي', 'E', 'OFG', 0);
    --         WHEN OTHERS THEN
    --           CGTE$OTHER_EXCEPTIONS;
    --       END;
    --       SET_RECORD_PROPERTY(:SYSTEM.TRIGGER_RECORD, 'IMPORTERS', STATUS ,                 QUERY_STATUS);
    --     END IF;
    --     IF (name_in('IMPORTERS.ADD_CTRY_CD') IS NOT NULL AND name_in('IMPORTERS.CITY_CODE') IS NOT NULL) THEN
    --       BEGIN
    --         CGFK$QRY_IMPORTERS_IMP_ADD_CIT(
    --           :IMPORTERS.ADD_CRTY_ARBC_NAME
    --          ,:IMPORTERS.CITY_NAME
    --          ,:IMPORTERS.L_CT_CITY_STATUS
    --          ,:IMPORTERS.CITY_CODE
    --          ,:IMPORTERS.ADD_CTRY_CD       );
    --       EXCEPTION
    --         WHEN NO_DATA_FOUND THEN
    --           Des$Form_errors.PUSH('خطأ في رمز مدينة عنوان المستورد', 'E', 'OFG', 0);
    --         WHEN OTHERS THEN
    --           CGTE$OTHER_EXCEPTIONS;
    --       END;
    --       SET_RECORD_PROPERTY(:SYSTEM.TRIGGER_RECORD, 'IMPORTERS', STATUS ,                 QUERY_STATUS);
    --     ELSE
    --         Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(78, '<p1> must be entered', 'دولــــــــة الإقامـــــة,المدينـة' ), 'E', 'OFG', 78);
    --         Des$Form_errors.RAISE_FAILURE;
    --     END IF;
    --   END;
    --   if NVL (gnrl.get_customs_setting (:PARAMETER.P_CURR_PORT_CD,'CR-6730',9), 0) = 1 then
    --       begin
    --           select WASL_CITY_NAME
    --           into   :importers.WASL_CITY_NAME
    --           from   IMPR_COMMON_DATA
    --           where  impr_type_cd = :importers.impr_type_cd
    --         and    bus_id_type_cd = :importers.bus_id_type_cd
    --         and    bus_id = :importers.bus_id
    --         and    bus_id_brnch = :importers.bus_id_brnch
    --         and    ctry_cd = :importers.ctry_cd;
    --      if :importers.WASL_CITY_NAME is not null then
    --       set_item_property('IMPORTERS.CITY_CODE',VISIBLE,property_false);
    --       set_item_property('IMPORTERS.CITY_CODE2',VISIBLE,property_false);
    --       set_item_property('IMPORTERS.CITY_NAME',VISIBLE,property_false);
    --      else
    --          set_item_property('IMPORTERS.WASL_CITY_NAME',VISIBLE,property_false);
    --      end if;
    --       exception
    --           when no_data_found then
    --             :importers.WASL_CITY_NAME :=:importers.CITY_NAME;
    --          set_item_property('IMPORTERS.WASL_CITY_NAME',VISIBLE,property_false);
    --       end;
    --   else
    --     set_item_property('IMPORTERS.WASL_CITY_NAME',VISIBLE,property_false);
    --   END IF;
    --   BEGIN
    --     IF (CG$IMPR1110_PROD_CENTRL_GLOBAL.IMPORTERS_WHERE <> 'first_time') THEN
    --       set_block_property('IMPORTERS', DEFAULT_WHERE, CG$IMPR1110_PROD_CENTRL_GLOBAL.IMPORTERS_WHERE);
    --       CG$IMPR1110_PROD_CENTRL_GLOBAL.IMPORTERS_WHERE := 'first_time';
    --     END IF;
    --   END;
    -- <<<
    PROCEDURE importers_post_qry (p_rec IN OUT NOCOPY t_rec, p_ctx IN t_ctx)
    IS
        v_count        NUMBER := 0;
        xdt            DATE;
        v_user_bus_id  VARCHAR2(4);
        v_expiry_date  DATE;
        v_dummy        NUMBER(1);
    BEGIN
        g_set('OLD_IMPR_TYPE_CD', p_rec.impr_type_cd);
        g_set('OLD_PORT_CD', p_rec.port_cd);
        IF p_rec.impr_nbr IS NOT NULL THEN
            BEGIN
                xdt := cur_hij_date;
                SELECT COUNT(*) INTO v_count
                  FROM importers imp, impr_suspns is_1
                 WHERE imp.port_cd  = p_rec.port_cd
                   AND imp.impr_nbr = p_rec.impr_nbr
                   AND is_1.port_cd  = imp.port_cd
                   AND is_1.impr_nbr = imp.impr_nbr
                   AND TO_CHAR(is_1.suspn_strt_dt, 'YYYY-MM-MI') <= TO_CHAR(xdt, 'YYYY-MM-MI')
                   AND TO_CHAR(is_1.suspn_end_dt, 'YYYY-MM-MI') >= TO_CHAR(xdt, 'YYYY-MM-MI')
                   AND is_1.suspn_rlse_dt IS NULL;
                IF v_count >= 1 THEN
                    p_rec.suspn_status := 'موقوف';
                ELSE
                    p_rec.suspn_status := 'غير موقوف';
                END IF;
                IF v_count = 0 THEN
                    SELECT COUNT(*) INTO v_count
                      FROM impr_duty_diff_blks
                     WHERE hq_impr_nbr = p_rec.hq_impr_nbr
                       AND blk_rls_dt IS NULL;
                    IF v_count > 0 THEN
                        SELECT COUNT(*) INTO v_count
                          FROM (SELECT 1
                                  FROM duty_diff_blk_exp_dtls d1, stats_dcltns d2, importers d3
                                 WHERE d1.stats_isn IS NOT NULL
                                   AND d1.dcltn_stat_port_cd = d2.port_cd
                                   AND d1.stats_isn = d2.stats_isn
                                   AND d2.port_cd = d3.port_cd
                                   AND d2.impr_expr_nbr = d3.impr_nbr
                                   AND d3.hq_impr_nbr = p_rec.hq_impr_nbr
                                   AND d2.stats_status NOT IN (7, 8, 10)
                                UNION ALL
                                SELECT 1
                                  FROM duty_diff_blk_exp_dtls d1, declarations d2, importers d3
                                 WHERE d1.dcltn_isn IS NOT NULL
                                   AND d1.dcltn_stat_port_cd = d2.port_cd
                                   AND d1.dcltn_isn = d2.dcltn_isn
                                   AND d2.port_cd = d3.port_cd
                                   AND d2.impr_nbr = d3.impr_nbr
                                   AND d3.hq_impr_nbr = p_rec.hq_impr_nbr
                                   AND d2.dcltn_sta_cd <> 9
                                UNION ALL
                                SELECT 1
                                  FROM duty_diff_blk_exp_dtls d1
                                 WHERE d1.from_date IS NOT NULL
                                   AND d1.hq_impr_nbr = p_rec.hq_impr_nbr
                                   AND hijdate_db.cur_hij_date BETWEEN d1.from_date AND d1.to_date);
                        IF NVL(gnrl.get_customs_setting('CRQ24602_RUN', 21), 0) = 0 THEN
                            IF v_count = 0 THEN
                                p_rec.suspn_status := 'موقوف(تدقيق عام)';
                            ELSE
                                p_rec.suspn_status := 'موقوف(تدقيق)له استثناء';
                            END IF;
                        ELSIF NVL(gnrl.get_customs_setting('CRQ24602_RUN', 21), 0) = 1 THEN
                            p_rec.suspn_status := '';
                        END IF;
                    END IF;
                END IF;
                IF v_count = 0 THEN
                    DECLARE
                        v_suspn_rsn_text VARCHAR2(2000) := '';
                    BEGIN
                        SELECT suspn_rsn_text INTO v_suspn_rsn_text
                          FROM impr_cntrl_suspns
                         WHERE hq_impr_nbr = p_rec.hq_impr_nbr
                           AND TO_CHAR(suspn_strt_dt, 'YYYY-MM-MI') <= TO_CHAR(xdt, 'YYYY-MM-MI')
                           AND TO_CHAR(suspn_end_dt, 'YYYY-MM-MI') >= TO_CHAR(xdt, 'YYYY-MM-MI')
                           AND suspn_rlse_dt IS NULL;
                        p_rec.suspn_status := 'إيقاف مركزي من قبل المصلحة - إدارة القيود بسبب ' || v_suspn_rsn_text;
                    EXCEPTION
                        WHEN NO_DATA_FOUND THEN
                            NULL;
                    END;
                END IF;
            EXCEPTION
                WHEN OTHERS THEN
                    NULL;
            END;
        END IF;
        p_rec.b_mobile_no := p_rec.mobile_no;
        p_rec.b_id_nbr    := p_rec.id_nbr;
        p_rec.b_email     := p_rec.email;
        g_set('STAT_QUE', '1');
        type_entrable_qry(p_rec);
        IF p_rec.bus_id_type_cd = 2 AND p_rec.impr_type_cd != 12 THEN
            IF p_rec.bus_id_brnch IS NOT NULL THEN
                BEGIN
                    v_user_bus_id := SUBSTR(p_rec.bus_id_brnch, 1, 4);
                    SELECT city_cd, city_arb_name
                      INTO p_rec.brnh_city_cd, p_rec.brnh_city_name
                      FROM cities
                     WHERE ctry_cd      = 100
                       AND mins_comm_cd = v_user_bus_id;
                EXCEPTION
                    WHEN OTHERS THEN
                        NULL;
                END;
            END IF;
        END IF;

        BEGIN
            SELECT status_desc
              INTO p_rec.status_desc
              FROM mci_bus_id_status
             WHERE bus_id_status LIKE p_rec.bus_id_status;
        EXCEPTION
            WHEN OTHERS THEN
                NULL;
        END;

        BEGIN
            SELECT MAX(expiry_date)
              INTO v_expiry_date
              FROM privileged_importers
             WHERE impr_privilege_type = 3
               AND rec_status = 1
               AND impr_nbr   = p_rec.impr_nbr;
            IF v_expiry_date IS NOT NULL THEN
                IF v_expiry_date < hijdate_db.cur_hij_date THEN
                    p_rec.impr_id_type := 'اقامة عادية';
                ELSE
                    p_rec.impr_id_type := 'اقامة مميزة محددة المدة تنتهي بتاريخ ' || TO_CHAR(v_expiry_date, 'MI-MM-YYYY');
                END IF;
            ELSE
                BEGIN
                    SELECT 1
                      INTO v_dummy
                      FROM privileged_importers
                     WHERE impr_privilege_type = 3
                       AND rec_status = 1
                       AND impr_nbr   = p_rec.impr_nbr
                       AND ROWNUM = 1;
                    p_rec.impr_id_type := 'اقامة مميزة دائمة ';
                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        p_rec.impr_id_type := 'عادية';
                END;
            END IF;
        END;

        adj_funs(p_rec, p_ctx);

        -- CGFK$QRY_LOOKUP_DATA (CGFK$QRY_IMPORTERS_* units inlined)
        IF p_rec.port_cd IS NOT NULL THEN
            BEGIN
                SELECT l_sdp.port_status, l_sdp.port_name
                  INTO p_rec.sdp_port_status, p_rec.port_name
                  FROM sd_ports l_sdp
                 WHERE l_sdp.port_cd = p_rec.port_cd;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    info(cg_msg('This <p1> does not exist', 'رمز الجمــــــــــــــرك'));
            END;
        END IF;
        IF p_rec.impr_type_cd IS NOT NULL AND p_rec.bus_id_type_cd IS NOT NULL THEN
            BEGIN
                SELECT itidt.note, itidt.status, it.impr_type_name, bit.bus_id_type_name
                  INTO p_rec.itidt_note, p_rec.status, p_rec.impr_type_name, p_rec.bus_id_type_name
                  FROM impr_type_id_types itidt, impr_types it, bus_id_types bit
                 WHERE itidt.bus_id_type_cd = p_rec.bus_id_type_cd
                   AND itidt.impr_type_cd   = p_rec.impr_type_cd
                   AND it.impr_type_cd      = itidt.impr_type_cd
                   AND bit.bus_id_type_cd   = itidt.bus_id_type_cd
                   AND ROWNUM = 1;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    info('رمز النشاط التجاري غير صحيح - أعد إدخال البيانات');
            END;
        ELSE
            ftf(cg_msg('<p1> must be entered', 'رمز النشاط التجارى'));
        END IF;
        IF p_rec.ctry_cd IS NOT NULL THEN
            BEGIN
                SELECT ctry.crty_arbc_name, ctry.ctry_status
                  INTO p_rec.crty_arbc_name, p_rec.ctry_ctry_status
                  FROM countries ctry
                 WHERE ctry.ctry_cd = p_rec.ctry_cd;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    info('رمز الدولة غير صحيح - أعد ادخال البيانات');
            END;
        END IF;
        IF p_rec.city_code_of_id IS NOT NULL AND p_rec.ctry_cd_of_id IS NOT NULL THEN
            BEGIN
                SELECT id_city.city_status, id_city.city_arb_name, id_city.mins_comm_cd
                  INTO p_rec.l_ct_city_status2, p_rec.id_city_name, p_rec.id_mins_comm_cd
                  FROM cities id_city
                 WHERE id_city.city_cd = p_rec.city_code_of_id
                   AND id_city.ctry_cd = p_rec.ctry_cd_of_id
                   AND ROWNUM = 1;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    info('خطأ في رمز مدينة مصدر الرقم الإستدلالي');
            END;
        END IF;
        IF p_rec.add_ctry_cd IS NOT NULL AND p_rec.city_code IS NOT NULL THEN
            BEGIN
                SELECT add_city.city_status, add_city.city_arb_name, l_ctry.crty_arbc_name
                  INTO p_rec.l_ct_city_status, p_rec.city_name, p_rec.add_crty_arbc_name
                  FROM cities add_city, countries l_ctry
                 WHERE add_city.ctry_cd = p_rec.add_ctry_cd
                   AND add_city.city_cd = p_rec.city_code
                   AND l_ctry.ctry_cd   = add_city.ctry_cd
                   AND ROWNUM = 1;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    info('خطأ في رمز مدينة عنوان المستورد');
            END;
        ELSE
            ftf(cg_msg('<p1> must be entered', 'دولــــــــة الإقامـــــة,المدينـة'));
        END IF;

        IF NVL(gnrl.get_customs_setting(p_ctx.curr_port_cd, 'CR-6730', 9), 0) = 1 THEN
            BEGIN
                SELECT wasl_city_name
                  INTO p_rec.wasl_city_name
                  FROM impr_common_data
                 WHERE impr_type_cd   = p_rec.impr_type_cd
                   AND bus_id_type_cd = p_rec.bus_id_type_cd
                   AND bus_id         = p_rec.bus_id
                   AND bus_id_brnch   = p_rec.bus_id_brnch
                   AND ctry_cd        = p_rec.ctry_cd;
                IF p_rec.wasl_city_name IS NOT NULL THEN
                    ui('CITY_CODE', 'VISIBLE', FALSE);
                    ui('CITY_CODE2', 'VISIBLE', FALSE);
                    ui('CITY_NAME', 'VISIBLE', FALSE);
                ELSE
                    ui('WASL_CITY_NAME', 'VISIBLE', FALSE);
                END IF;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    p_rec.wasl_city_name := p_rec.city_name;
                    ui('WASL_CITY_NAME', 'VISIBLE', FALSE);
            END;
        ELSE
            ui('WASL_CITY_NAME', 'VISIBLE', FALSE);
        END IF;
        -- CGFK$RESET_BLOCK_WHERE_CLAUSE: not needed (no DEFAULT_WHERE manipulation in APEX)
    END importers_post_qry;

    -- Source: IMPORTERS.PRE-INSERT
    -- p_answer: answer to the CONFIRM shown to class 1 / user type 3 (broker) before saving.
    --@ORIG IMPORTERS.PRE-INSERT
    -- >>> Original Forms code: IMPORTERS.PRE-INSERT
    --   BEGIN
    --   SET_BLOCK_PROPERTY('IMPORTERS',UPDATE_ALLOWED,PROPERTY_FALSE);
    --   IF :B_MOBILE_NO IS NULL THEN
    --   STR.DISPALERT('يجب إدخال رقم المحمول','INFORMATION');
    --   RAISE FORM_TRIGGER_FAILURE;
    --   END IF;
    --   IF :CITY_CODE  IS NULL THEN
    --   STR.DISPALERT('يجب إدخال المدينة','INFORMATION');
    --     RAISE FORM_TRIGGER_FAILURE;
    --   END IF;
    --   END;
    --   DECLARE
    --    RET NUMBER;
    --   BEGIN
    --     CHK_DUPL_IMP_BRKR ;
    --     IF :IMPR_TEL_NBR IS NULL THEN
    --         INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_TEL_NBR',TRUE);
    --         RET := STR.DispALERT('يجب ادخال رقم الهاتف','INFORMATION');
    --         RAISE FORM_TRIGGER_FAILURE;
    --     END IF;
    --     IF  ((:BUS_ID_TYPE_CD = 2 AND :IMPR_TYPE_CD IN (1,3,5,6,8,12))
    --      OR (:BUS_ID_TYPE_CD = 3 AND :IMPR_TYPE_CD = 4)
    --      OR (:BUS_ID_TYPE_CD = 4 AND :IMPR_TYPE_CD = 4))
    --     THEN
    --      IF :BUS_ID_EXPRD_DT IS NULL THEN
    --         INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_EXPRD_DT',TRUE);
    --         ret := Str.DispArbMsg(9,220,'ERROR');
    --       RAISE FORM_TRIGGER_FAILURE;
    --      END IF;
    --    END IF;
    --   CHK_IMPR_DUPL;
    --   IF GET_ITEM_PROPERTY('ACTIVITY',ENABLED) = 'TRUE' AND :ACTIVITY IS NULL THEN
    --       STR.DISPALERT('يجب إدخال حقل نشاط المستورد','INFORMATION');
    --        RAISE FORM_TRIGGER_FAILURE;
    --   END IF;
    --   DECLARE
    --   RET NUMBER;
    --   BEGIN
    --   IF :PARAMETER.P_CLASS_CD=1 AND :PARAMETER.P_USER_TYPE=3 THEN
    --   RET:=STR.DISPALERT('يجب مراجعة البيانات والتأكد من صحتها قبل التخزين، لايمكن التعديل إلا من قبل شئون المستوردين! هل ترغب بالاستمرار؟','CONFIRM');
    --   IF RET = ALERT_BUTTON1 THEN
    --   NULL;
    --   ELSE
    --   RAISE FORm_Trigger_Failure;
    --   END IF;
    --   END IF;
    --   END;
    --   IF NOT ACTIVITY.ADD_ACTIVITY(9, 2, 1, :IMPORTERS.Port_Cd||'!'||:IMPORTERS.Impr_Nbr) THEN
    --       RAISE FORm_Trigger_Failure;
    --   END IF;
    --   END;
    --   DECLARE
    --     V_CNT NUMBER;
    --     RET NUMBER;
    --     V_RET VARCHAR2(5);
    --     V_EXPRD_DT DATE;
    --     V_CUSTOMS_ENTERED  NUMBER;
    --   BEGIN
    --    IF  :BUS_ID_TYPE_CD = 2 AND :IMPR_TYPE_CD!=12 THEN
    --        IF :COMM_RGSTRTN_TYPE = 1 THEN
    --            IF :BUS_ID IS NOT NULL THEN
    --                 SELECT COUNT(BUS_ID) INTO V_CNT FROM COMM_IMPR_RGSTR
    --                 WHERE  BUS_ID=:BUS_ID
    --                   AND  BRNCHREG=0;
    --                 IF V_CNT =0 THEN
    --                   V_RET := LIB_USR.GNRL.GET_CUSTOMS_SETTING(:PARAMETER.P_CURR_PORT_CD,'COMM_TABLE_UNCHECK',9);
    --                   IF NVL(V_RET,0) = 0 THEN
    --                      ret := Str.DispArbMsg(9, 190,'ERROR');
    --                    RAISE FORM_TRIGGER_FAILURE;
    --               ELSE
    --                 V_CUSTOMS_ENTERED:=1;
    --                 END IF;
    --              ELSE
    --                V_CUSTOMS_ENTERED:= 0 ;
    --                  END IF;
    --            ELSE
    --                ret := Str.DispArbMsg(9, 250,'ERROR');
    --              RAISE FORM_TRIGGER_FAILURE;
    --            END IF;
    --        ELSIF :COMM_RGSTRTN_TYPE = 2 THEN
    --            IF :BUS_ID IS NOT NULL AND :BUS_ID_BRNCH IS NOT NULL THEN
    --               SELECT COUNT(BUS_ID)INTO V_CNT    FROM COMM_IMPR_RGSTR
    --               WHERE  BUS_ID       =:BUS_ID
    --                 AND  BRNCH_BUS_ID =:IMPORTERS.BUS_ID_BRNCH ;
    --                 IF V_CNT =0 THEN
    --                    V_RET := LIB_USR.GNRL.GET_CUSTOMS_SETTING(:PARAMETER.P_CURR_PORT_CD,'COMM_TABLE_UNCHECK',9);
    --                  IF NVL(V_RET,0) = 0 THEN
    --                     ret := Str.DispArbMsg(9, 190,'ERROR');
    --                     RAISE FORM_TRIGGER_FAILURE;
    --                ELSE
    --                V_CUSTOMS_ENTERED:=1;
    --                  END IF;
    --             ELSE
    --              V_CUSTOMS_ENTERED:= 0 ;
    --                    END IF;
    --             ELSE
    --                ret := Str.DispArbMsg(9, 230,'ERROR');
    --              RAISE FORM_TRIGGER_FAILURE;
    --            END IF;
    --       ELSE
    --          ret := Str.DispArbMsg(9, 240,'ERROR');
    --          INTRFACE.Make_Field_Entrable('IMPORTERS.COMM_RGSTRTN_TYPE' , TRUE);
    --        RAISE FORM_TRIGGER_FAILURE;
    --       END IF;
    --     END IF;
    --   IF     :GLOBAL.CHK_DUP_BUSID = 1 THEN
    --         IF NOT ACTIVITY.ADD_ACTIVITY(9, 2, 3, :IMPORTERS.Port_Cd||'!'||:IMPORTERS.Impr_Nbr) THEN
    --           RAISE FORm_Trigger_Failure;
    --         END IF;
    --         :GLOBAL.CHK_DUP_BUSID := 0 ;
    --     END IF;
    --   SET_BLOCK_PROPERTY('IMPORTERS',UPDATE_ALLOWED,PROPERTY_FALSE);
    --   DECLARE
    --       V_IMPR_NBR        VARCHAR2(50);
    --     V_msg_txt         VARCHAR2(500);
    --     V_RESULT          NUMBER;
    --   BEGIN
    --       LIB_USR.IMPR_CENTRAL.Create_Uni_IMPR_NEBRAS ( :PORT_CD,
    --                                                     :BUS_ID,
    --                                                     :BUS_ID_BRNCH,
    --                                                     :BUS_ID_TYPE_CD,
    --                                                     :IMPR_TYPE_CD,
    --                                                     :CTRY_CD,
    --                                                     :CITY_CODE,
    --                                                     :IMPR_CNTCT_NAME,
    --                                                     NVL(:IMPR_TEL_NBR,0),
    --                                                     :B_EMAIL,
    --                                                     :BANK_IBAN,
    --                                                                 NVL(:IMPR_POB_NBR,0),
    --                                                     TO_CHAR(:BUS_ID_EXPRD_DT,'MI-MM-YYYY'),
    --                                                     :ACTIVITY,
    --                                                     :ARBC_IMPR_NAME,
    --                                                     :ENG_IMPR_NAME,
    --                                                           NVL(:B_MOBILE_NO,0),
    --                                                                   NVL(:IMPR_ZIP_CD,0),
    --                                                     NVL(:BRNH_CITY_CD,0),
    --                                                     :IMPR_EXPR_TYPE,
    --                                                     :IMPR_ADDRESS,
    --                                                     TO_CHAR(:BUS_ID_ISSUE_DT,'MI-MM-YYYY'),
    --                                                     :B_ID_NBR,
    --                                                     NVL(:COMM_RGSTRTN_TYPE,0),
    --                                                     0,--NVL(:CTRY_CD_OF_ID,0),
    --                                                     NVL(:CITY_CODE_OF_ID,0),
    --                                                     NVL(:IMPR_NBR_PARENT,0),
    --                                                     NVL(:IMPR_FAX_NBR,0),
    --                                                     NVL(:IMPR_TELEX_NBR,0),
    --                                                     NVL(:ADD_CTRY_CD,0),
    --                                                     NVL(:IMPD_STMT_NBR,0),
    --                                                     NVL(:IMPR_DATA_SRCE,0),
    --                                                     NVL(V_CUSTOMS_ENTERED,0),
    --                                                     NVL(:EXPD_STMT_NBR,0),
    --                                                     NVL(:WVR_ENTRY_NBR,0),
    --                                                     NVL(:CAR_AGENT_FLAG,0),
    --                                                     NVL(:EXPRESS_POST,0),
    --                                                     V_IMPR_NBR,
    --                                                     V_msg_txt,
    --                                                     V_RESULT,
    --                                                     :PARAMETER.P_USER_ID,
    --                                                     :PARAMETER.P_WS_ID
    --                                                     );
    --        IF V_RESULT = 1 THEN
    --                     STR.DISPALERT(V_msg_txt,'information') ;--||'  '||V_RESULT,'INFORMATION') ;
    --                STR.DISPALERT('رقم المستورد'||' = '||V_IMPR_NBR,'INFORMATION') ;
    --          :GLOBAL.SET :=  V_IMPR_NBR ;
    --   IF :GLOBAL.SET IS NOT NULL THEN
    --    :HQ_IMPR_NBR := :GLOBAL.SET;
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID' , FALSE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_BRNCH', FALSE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_EXPRD_DT' , FALSE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.ARBC_IMPR_NAME' , FALSE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.COMM_RGSTRTN_TYPE' , FALSE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_BRNCH' , FALSE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.CITY_CODE_OF_ID',FALSE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_TYPE_CD' , FALSE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_EXPR_TYPE' , FALSE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_TYPE_CD' , FALSE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.BRNH_CITY_CD' , FALSE);
    --   END IF;
    --          ELSE
    --                  STR.DISPALERT(V_msg_txt,'information'); --||' <=> '||V_RESULT,'INFORMATION') ;--
    --                    RAISE FORm_Trigger_Failure;
    --                    SET_BLOCK_PROPERTY('IMPORTERS',UPDATE_ALLOWED,PROPERTY_TRUE);
    --        END IF;
    --   END ;
    --   END;
    --   BEGIN
    --     IF (name_in('IMPORTERS.CITY_CODE_OF_ID') IS NULL AND name_in('IMPORTERS.CTRY_CD_OF_ID') IS NULL) THEN
    --       BEGIN
    --         CGSF$CLRLU_IMPORTERS_IMP_BUS_I;
    --       EXCEPTION
    --         WHEN OTHERS THEN
    --           CGTE$OTHER_EXCEPTIONS;
    --       END;
    --     END IF;
    --   END;
    -- <<<
    PROCEDURE importers_pre_ins (p_rec    IN OUT NOCOPY t_rec,
                                 p_ctx    IN t_ctx,
                                 p_answer IN PLS_INTEGER DEFAULT c_yes)
    IS
        v_cnt             NUMBER;
        v_ret             VARCHAR2(5);
        v_customs_entered NUMBER;
        v_impr_nbr        VARCHAR2(50);
        v_msg_txt         VARCHAR2(500);
        v_result          NUMBER;
    BEGIN
        -- SET_BLOCK_PROPERTY('IMPORTERS',UPDATE_ALLOWED,PROPERTY_FALSE): UI only
        IF p_rec.b_mobile_no IS NULL THEN
            ftf('يجب إدخال رقم المحمول');
        END IF;
        IF p_rec.city_code IS NULL THEN
            ftf('يجب إدخال المدينة');
        END IF;

        chk_dupl_imp_brkr(p_rec, p_ctx);
        IF p_rec.impr_tel_nbr IS NULL THEN
            entrable('IMPR_TEL_NBR', TRUE);
            ftf('يجب ادخال رقم الهاتف');
        END IF;
        IF ((p_rec.bus_id_type_cd = 2 AND p_rec.impr_type_cd IN (1, 3, 5, 6, 8, 12))
            OR (p_rec.bus_id_type_cd = 3 AND p_rec.impr_type_cd = 4)
            OR (p_rec.bus_id_type_cd = 4 AND p_rec.impr_type_cd = 4)) THEN
            IF p_rec.bus_id_exprd_dt IS NULL THEN
                entrable('BUS_ID_EXPRD_DT', TRUE);
                disp_arb_ftf(9, 220);
            END IF;
        END IF;
        chk_impr_dupl(p_rec);
        IF NVL(p_rec.activity_entr, 'N') = 'Y' AND p_rec.activity IS NULL THEN
            ftf('يجب إدخال حقل نشاط المستورد');
        END IF;
        IF p_ctx.class_cd = 1 AND p_ctx.user_type = 3 THEN
            -- CONFIRM 'يجب مراجعة البيانات والتأكد من صحتها قبل التخزين، لايمكن التعديل إلا من قبل شئون المستوردين! هل ترغب بالاستمرار؟'
            IF p_answer = c_yes THEN
                NULL;
            ELSE
                ftf;
            END IF;
        END IF;
        add_activity(1, p_rec);

        IF p_rec.bus_id_type_cd = 2 AND p_rec.impr_type_cd != 12 THEN
            IF p_rec.comm_rgstrtn_type = 1 THEN
                IF p_rec.bus_id IS NOT NULL THEN
                    SELECT COUNT(bus_id) INTO v_cnt
                      FROM comm_impr_rgstr
                     WHERE bus_id = p_rec.bus_id
                       AND brnchreg = 0;
                    IF v_cnt = 0 THEN
                        v_ret := lib_usr.gnrl.get_customs_setting(p_ctx.curr_port_cd, 'COMM_TABLE_UNCHECK', 9);
                        IF NVL(v_ret, 0) = 0 THEN
                            disp_arb_ftf(9, 190);
                        ELSE
                            v_customs_entered := 1;
                        END IF;
                    ELSE
                        v_customs_entered := 0;
                    END IF;
                ELSE
                    disp_arb_ftf(9, 250);
                END IF;
            ELSIF p_rec.comm_rgstrtn_type = 2 THEN
                IF p_rec.bus_id IS NOT NULL AND p_rec.bus_id_brnch IS NOT NULL THEN
                    SELECT COUNT(bus_id) INTO v_cnt
                      FROM comm_impr_rgstr
                     WHERE bus_id       = p_rec.bus_id
                       AND brnch_bus_id = p_rec.bus_id_brnch;
                    IF v_cnt = 0 THEN
                        v_ret := lib_usr.gnrl.get_customs_setting(p_ctx.curr_port_cd, 'COMM_TABLE_UNCHECK', 9);
                        IF NVL(v_ret, 0) = 0 THEN
                            disp_arb_ftf(9, 190);
                        ELSE
                            v_customs_entered := 1;
                        END IF;
                    ELSE
                        v_customs_entered := 0;
                    END IF;
                ELSE
                    disp_arb_ftf(9, 230);
                END IF;
            ELSE
                entrable('COMM_RGSTRTN_TYPE', TRUE);
                disp_arb_ftf(9, 240);
            END IF;
        END IF;
        IF g_get('CHK_DUP_BUSID') = '1' THEN
            -- Note: only the unused PU VIEW_SAME_BUSID sets this global to 1 -> never true today.
            add_activity(3, p_rec);
            g_set('CHK_DUP_BUSID', '0');
        END IF;

        -- RECORD IMPORTER IN HQ AND PORT (Bassam Mansour 09/01/2019)
        lib_usr.impr_central.create_uni_impr_nebras(
            p_rec.port_cd,
            p_rec.bus_id,
            p_rec.bus_id_brnch,
            p_rec.bus_id_type_cd,
            p_rec.impr_type_cd,
            p_rec.ctry_cd,
            p_rec.city_code,
            p_rec.impr_cntct_name,
            NVL(p_rec.impr_tel_nbr, 0),
            p_rec.b_email,
            p_rec.bank_iban,
            NVL(p_rec.impr_pob_nbr, 0),
            TO_CHAR(p_rec.bus_id_exprd_dt, 'MI-MM-YYYY'),
            p_rec.activity,
            p_rec.arbc_impr_name,
            p_rec.eng_impr_name,
            NVL(p_rec.b_mobile_no, 0),
            NVL(p_rec.impr_zip_cd, 0),
            NVL(p_rec.brnh_city_cd, 0),
            p_rec.impr_expr_type,
            p_rec.impr_address,
            TO_CHAR(p_rec.bus_id_issue_dt, 'MI-MM-YYYY'),
            p_rec.b_id_nbr,
            NVL(p_rec.comm_rgstrtn_type, 0),
            0,                                   -- NVL(:CTRY_CD_OF_ID,0) is commented out in Forms
            NVL(p_rec.city_code_of_id, 0),
            NVL(p_rec.impr_nbr_parent, 0),
            NVL(p_rec.impr_fax_nbr, 0),
            NVL(p_rec.impr_telex_nbr, 0),
            NVL(p_rec.add_ctry_cd, 0),
            NVL(p_rec.impd_stmt_nbr, 0),
            NVL(p_rec.impr_data_srce, 0),
            NVL(v_customs_entered, 0),
            NVL(p_rec.expd_stmt_nbr, 0),
            NVL(p_rec.wvr_entry_nbr, 0),
            NVL(p_rec.car_agent_flag, 0),
            NVL(p_rec.express_post, 0),
            v_impr_nbr,
            v_msg_txt,
            v_result,
            p_ctx.user_id,
            p_ctx.ws_id);
        IF v_result = 1 THEN
            info(v_msg_txt);
            info('رقم المستورد' || ' = ' || v_impr_nbr);
            g_set('SET', v_impr_nbr);
            IF g_get('SET') IS NOT NULL THEN
                p_rec.hq_impr_nbr := g_get('SET');
                lock_key_items;
            END IF;
        ELSE
            ftf(v_msg_txt);
        END IF;

        -- CGFK$CLR_FK_ON_INS
        IF p_rec.city_code_of_id IS NULL AND p_rec.ctry_cd_of_id IS NULL THEN
            cgsf_clrlu_bus_i(p_rec);
        END IF;
    END importers_pre_ins;

    -- Source: Forms default INSERT (block IMPORTERS has no ON-INSERT trigger; all base-table
    -- items are inserted with their current values).
    -- HIGH / OPEN QUESTION: at this point IMPR_NBR is still NULL (it is copied from :GLOBAL.SET
    -- only in POST-INSERT) and IMPR_CENTRAL.Create_Uni_IMPR_NEBRAS was already called in
    -- PRE-INSERT. Whether this INSERT really runs as written (view with INSTEAD OF trigger,
    -- DB trigger, or DML Returning inherited from CIC_OLB) must be confirmed with a Forms
    -- trace before go-live. Kept exactly as Forms would issue it.
    PROCEDURE importers_ins (p_rec IN OUT NOCOPY t_rec)
    IS
    BEGIN
        INSERT INTO importers (
            port_cd, hq_impr_nbr, impr_nbr, bus_id_status, impr_type_cd, bus_id_exprd_dt,
            bus_id_type_cd, comm_rgstrtn_type, city_code_of_id, bus_id, bus_id_brnch, ctry_cd,
            impr_expr_type, arbc_impr_name, impr_name_std, lst_tran_dt, impd_stmt_nbr,
            impr_data_srce, eng_impr_name, impr_cntct_name, impr_address, bus_id_issue_dt,
            impr_nbr_parent, add_ctry_cd, city_code, impr_pob_nbr, impr_zip_cd, impr_tel_nbr,
            impr_fax_nbr, impr_telex_nbr, email, mobile_no, bank_iban, id_nbr, car_agent_flag,
            express_post, ctry_cd_of_id, expd_stmt_nbr, wvr_entry_nbr, activity, customs_entered,
            creation_flag)
        VALUES (
            p_rec.port_cd, p_rec.hq_impr_nbr, p_rec.impr_nbr, p_rec.bus_id_status, p_rec.impr_type_cd,
            p_rec.bus_id_exprd_dt, p_rec.bus_id_type_cd, p_rec.comm_rgstrtn_type, p_rec.city_code_of_id,
            p_rec.bus_id, p_rec.bus_id_brnch, p_rec.ctry_cd, p_rec.impr_expr_type, p_rec.arbc_impr_name,
            p_rec.impr_name_std, p_rec.lst_tran_dt, p_rec.impd_stmt_nbr, p_rec.impr_data_srce,
            p_rec.eng_impr_name, p_rec.impr_cntct_name, p_rec.impr_address, p_rec.bus_id_issue_dt,
            p_rec.impr_nbr_parent, p_rec.add_ctry_cd, p_rec.city_code, p_rec.impr_pob_nbr,
            p_rec.impr_zip_cd, p_rec.impr_tel_nbr, p_rec.impr_fax_nbr, p_rec.impr_telex_nbr,
            p_rec.email, p_rec.mobile_no, p_rec.bank_iban, p_rec.id_nbr, p_rec.car_agent_flag,
            p_rec.express_post, p_rec.ctry_cd_of_id, p_rec.expd_stmt_nbr, p_rec.wvr_entry_nbr,
            p_rec.activity, p_rec.customs_entered, p_rec.creation_flag)
        RETURNING ROWID INTO p_rec.row_id;
    END importers_ins;

    -- Source: IMPORTERS.POST-INSERT
    --@ORIG IMPORTERS.POST-INSERT
    -- >>> Original Forms code: IMPORTERS.POST-INSERT
    --   BEGIN
    --   IF :GLOBAL.CHEK = 1 THEN
    --   SET_BLOCK_PROPERTY('IMPORTERS',UPDATE_ALLOWED,PROPERTY_TRUE);
    --   END IF;
    --        Insert_Audit_Record ('I');
    --   END;
    --   update_basic_importer;
    --   IF :PARAMETER.P_CLASS_CD=1 AND :PARAMETER.P_USER_TYPE=3 THEN
    --   CREATE_BRKR_IMPR_AUTH;
    --   END IF;
    --   IF :GLOBAL.SET IS NOT NULL THEN
    --   :IMPR_NBR := :GLOBAL.SET;
    --   :HQ_IMPR_NBR := :GLOBAL.SET;
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID' , FALSE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_BRNCH', FALSE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_EXPRD_DT' , FALSE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.ARBC_IMPR_NAME' , FALSE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.COMM_RGSTRTN_TYPE' , FALSE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_BRNCH' , FALSE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.CITY_CODE_OF_ID',FALSE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_TYPE_CD' , FALSE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_EXPR_TYPE' , FALSE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_TYPE_CD' , FALSE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.BRNH_CITY_CD' , FALSE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_TEL_NBR', FALSE);
    --   END IF;
    --   BEGIN
    --   RETURN_IMPR_ID ;
    --   END;
    -- <<<
    PROCEDURE importers_post_ins (p_rec IN OUT NOCOPY t_rec, p_ctx IN t_ctx)
    IS
    BEGIN
        IF g_get('CHEK') = '1' THEN
            -- SET_BLOCK_PROPERTY('IMPORTERS',UPDATE_ALLOWED,PROPERTY_TRUE): UI only
            -- (:GLOBAL.CHEK is never set in this form - set by another form or the OLB)
            NULL;
        END IF;
        insert_audit_record(p_rec, p_ctx, 'I');
        update_basic_importer(p_rec);
        IF p_ctx.class_cd = 1 AND p_ctx.user_type = 3 THEN
            create_brkr_impr_auth(p_rec, p_ctx);
        END IF;
        IF g_get('SET') IS NOT NULL THEN
            p_rec.impr_nbr    := g_get('SET');
            p_rec.hq_impr_nbr := g_get('SET');
            lock_key_items;
            entrable('IMPR_TEL_NBR', FALSE);
        END IF;
        return_impr_id(p_rec, p_ctx);
    END importers_post_ins;

    -- Source: IMPORTERS.PRE-UPDATE
    --@ORIG IMPORTERS.PRE-UPDATE
    -- >>> Original Forms code: IMPORTERS.PRE-UPDATE
    --   BEGIN
    --   chk_personal (:impr_type_cd,:hq_impr_nbr) ;
    --   END;
    --   BEGIN
    --   IF :B_MOBILE_NO IS NULL THEN
    --   STR.DISPALERT('يجب إدخال رقم المحمول','ERROR');
    --   RAISE FORM_TRIGGER_FAILURE;
    --   END IF;
    --   END;
    --   DECLARE
    --   CURSOR c1_hq_nbr IS
    --       SELECT     HQ_IMPR_NBR
    --       FROM         HQ_IMPRS
    --       WHERE     BUS_ID_TYPE_CD = :IMPORTERS.BUS_ID_TYPE_CD
    --       AND        BUS_ID = :IMPORTERS.BUS_ID
    --       AND        BUS_ID_BRNCH = :IMPORTERS.BUS_ID_BRNCH ;
    --   CURSOR c2_hq_nbr IS
    --       SELECT     HQ_IMPR_NBR
    --       FROM         HQ_IMPRS
    --       WHERE     BUS_ID_TYPE_CD = :IMPORTERS.BUS_ID_TYPE_CD
    --       AND        BUS_ID = :IMPORTERS.BUS_ID
    --       AND        BUS_ID_BRNCH IS NULL;
    --   V_HQ_NBR NUMBER := NULL;
    --    RET NUMBER;
    --   BEGIN
    --     CHK_DUPL_IMP_BRKR ;
    --     IF  ((:BUS_ID_TYPE_CD = 2 AND :IMPR_TYPE_CD IN (1,3,5,6,8,12))
    --      OR (:BUS_ID_TYPE_CD = 3 AND :IMPR_TYPE_CD = 4)
    --      OR (:BUS_ID_TYPE_CD = 4 AND :IMPR_TYPE_CD = 4))
    --    THEN
    --      IF :BUS_ID_EXPRD_DT IS NULL THEN
    --         INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_EXPRD_DT',TRUE);
    --         ret := Str.DispArbMsg(9,220,'ERROR');
    --       RAISE FORM_TRIGGER_FAILURE;
    --      END IF;
    --    END IF;
    --   IF :PARAMETER.LETTER_NBR IS NOT NULL THEN
    --     :IMPORTERS.HQ_IMPR_NBR:=NULL;
    --   END IF;
    --   :IMPR_NAME_STD := STR.StrFormat(:ARBC_IMPR_NAME);
    --   Insert_Audit_Record ('U');
    --   IF :IMPORTERS.BUS_ID_BRNCH IS NULL THEN
    --       OPEN     c2_hq_nbr;
    --       FETCH c2_hq_nbr INTO V_HQ_NBR;
    --       :IMPORTERS.hq_impr_nbr := V_HQ_NBR;
    --       CLOSE c2_hq_nbr;
    --   ELSE
    --       OPEN     c1_hq_nbr;
    --       FETCH c1_hq_nbr INTO V_HQ_NBR;
    --       :IMPORTERS.hq_impr_nbr := V_HQ_NBR;
    --       CLOSE c1_hq_nbr;
    --   END IF;
    --   IF NOT ACTIVITY.ADD_ACTIVITY(9, 2, 2, :IMPORTERS.Port_Cd||'!'||:IMPORTERS.Impr_Nbr) THEN
    --       RAISE FORm_Trigger_Failure;
    --   END IF;
    --   IF :GLOBAL.LETTER_NBR IS NOT NULL THEN
    --     DB_JOURNAL.JOURNALING_ON(:GLOBAL.PORT_CD,:GLOBAL.SUPP_TITLE_CD,:GLOBAL.LETTER_NBR,:GLOBAL.LETTER_DT);
    --    END IF;
    --   END;
    --   DECLARE
    --       V_ANAME VARCHAR2(200);
    --       V_ENAME VARCHAR2(200);
    --       V_CNAME VARCHAR2(200);
    --   BEGIN
    --   V_ANAME := LTRIM(RTRIM(:IMPORTERS.ARBC_IMPR_NAME));
    --   V_ENAME := LTRIM(RTRIM(:IMPORTERS.ENG_IMPR_NAME));
    --   V_CNAME := LTRIM(RTRIM(:IMPORTERS.IMPR_CNTCT_NAME));
    --   :IMPORTERS.ARBC_IMPR_NAME:=V_ANAME;
    --   :IMPORTERS.ENG_IMPR_NAME:=V_ENAME;
    --   :IMPORTERS.IMPR_CNTCT_NAME:=V_CNAME;
    --   END;
    --   DECLARE
    --     V_CNT NUMBER;
    --     RET NUMBER;
    --     V_RET VARCHAR2(5);
    --   BEGIN
    --    IF :BUS_ID_TYPE_CD = 2 AND :IMPR_TYPE_CD!=12 THEN
    --       IF :COMM_RGSTRTN_TYPE = 1 THEN
    --           IF :BUS_ID IS NOT NULL THEN
    --               SELECT COUNT(BUS_ID) INTO V_CNT FROM COMM_IMPR_RGSTR
    --               WHERE  BUS_ID=:BUS_ID
    --                AND   BRNCHREG=0;
    --               IF V_CNT =0 THEN
    --                  V_RET := LIB_USR.GNRL.GET_CUSTOMS_SETTING(:PARAMETER.P_CURR_PORT_CD,'COMM_TABLE_UNCHECK',9);
    --                  IF NVL(V_RET,0) = 0 THEN
    --                     ret := Str.DispArbMsg(9, 190,'ERROR');
    --                   RAISE FORM_TRIGGER_FAILURE;
    --              ELSE
    --                  :IMPORTERS.CUSTOMS_ENTERED:=1;
    --              END IF;
    --           ELSE
    --             :IMPORTERS.CUSTOMS_ENTERED:= 0 ;
    --               END IF;
    --           ELSE
    --               ret := Str.DispArbMsg(9, 250,'ERROR');
    --             RAISE FORM_TRIGGER_FAILURE;
    --           END IF;
    --        ELSIF :COMM_RGSTRTN_TYPE = 2 THEN
    --          IF :BUS_ID IS NOT NULL AND :BUS_ID_BRNCH IS NOT NULL THEN
    --            SELECT COUNT(BUS_ID)INTO V_CNT    FROM COMM_IMPR_RGSTR
    --            WHERE  BUS_ID=:BUS_ID
    --             AND   BRNCH_BUS_ID=:IMPORTERS.BUS_ID_BRNCH ;
    --              IF V_CNT =0 THEN
    --                V_RET := LIB_USR.GNRL.GET_CUSTOMS_SETTING(:PARAMETER.P_CURR_PORT_CD,'COMM_TABLE_UNCHECK',9);
    --                  IF NVL(V_RET,0) = 0 THEN
    --                  ret := Str.DispArbMsg(9, 190,'ERROR');
    --                  RAISE FORM_TRIGGER_FAILURE;
    --              ELSE
    --                :IMPORTERS.CUSTOMS_ENTERED:=1;
    --                END IF;
    --            ELSE
    --                      :IMPORTERS.CUSTOMS_ENTERED:= 0 ;
    --              END IF;
    --           ELSE
    --               ret := Str.DispArbMsg(9, 230,'ERROR');
    --             RAISE FORM_TRIGGER_FAILURE;
    --           END IF;
    --        ELSE
    --          ret := Str.DispArbMsg(9, 240,'ERROR');
    --          INTRFACE.Make_Field_Entrable('IMPORTERS.COMM_RGSTRTN_TYPE' , TRUE);
    --        RAISE FORM_TRIGGER_FAILURE;
    --        END IF;
    --     END IF;
    --    :MOBILE_NO:=:B_MOBILE_NO;
    --   END;
    -- <<<
    PROCEDURE importers_pre_upd (p_rec IN OUT NOCOPY t_rec, p_ctx IN t_ctx)
    IS
        CURSOR c1_hq_nbr IS
            SELECT hq_impr_nbr
              FROM hq_imprs
             WHERE bus_id_type_cd = p_rec.bus_id_type_cd
               AND bus_id         = p_rec.bus_id
               AND bus_id_brnch   = p_rec.bus_id_brnch;
        CURSOR c2_hq_nbr IS
            SELECT hq_impr_nbr
              FROM hq_imprs
             WHERE bus_id_type_cd = p_rec.bus_id_type_cd
               AND bus_id         = p_rec.bus_id
               AND bus_id_brnch IS NULL;
        v_hq_nbr NUMBER := NULL;
        v_cnt    NUMBER;
        v_ret    VARCHAR2(5);
    BEGIN
        chk_personal(p_rec, p_ctx, p_rec.impr_type_cd, p_rec.hq_impr_nbr);
        IF p_rec.b_mobile_no IS NULL THEN
            ftf('يجب إدخال رقم المحمول');
        END IF;

        chk_dupl_imp_brkr(p_rec, p_ctx);
        IF ((p_rec.bus_id_type_cd = 2 AND p_rec.impr_type_cd IN (1, 3, 5, 6, 8, 12))
            OR (p_rec.bus_id_type_cd = 3 AND p_rec.impr_type_cd = 4)
            OR (p_rec.bus_id_type_cd = 4 AND p_rec.impr_type_cd = 4)) THEN
            IF p_rec.bus_id_exprd_dt IS NULL THEN
                entrable('BUS_ID_EXPRD_DT', TRUE);
                disp_arb_ftf(9, 220);
            END IF;
        END IF;
        IF p_ctx.letter_nbr IS NOT NULL THEN
            p_rec.hq_impr_nbr := NULL;
        END IF;
        -- STR.StrFormat (client) -> STR_DB.StrFormat, see importers_pre_qry
        p_rec.impr_name_std := str_db.strformat(p_rec.arbc_impr_name);
        insert_audit_record(p_rec, p_ctx, 'U');
        IF p_rec.bus_id_brnch IS NULL THEN
            OPEN c2_hq_nbr;
            FETCH c2_hq_nbr INTO v_hq_nbr;
            p_rec.hq_impr_nbr := v_hq_nbr;
            CLOSE c2_hq_nbr;
        ELSE
            OPEN c1_hq_nbr;
            FETCH c1_hq_nbr INTO v_hq_nbr;
            p_rec.hq_impr_nbr := v_hq_nbr;
            CLOSE c1_hq_nbr;
        END IF;
        add_activity(2, p_rec);
        IF g_get('LETTER_NBR') IS NOT NULL THEN
            db_journal.journaling_on(g_get('PORT_CD'), g_get('SUPP_TITLE_CD'),
                                     g_get('LETTER_NBR'), g_get('LETTER_DT'));
        END IF;

        p_rec.arbc_impr_name  := LTRIM(RTRIM(p_rec.arbc_impr_name));
        p_rec.eng_impr_name   := LTRIM(RTRIM(p_rec.eng_impr_name));
        p_rec.impr_cntct_name := LTRIM(RTRIM(p_rec.impr_cntct_name));

        IF p_rec.bus_id_type_cd = 2 AND p_rec.impr_type_cd != 12 THEN
            IF p_rec.comm_rgstrtn_type = 1 THEN
                IF p_rec.bus_id IS NOT NULL THEN
                    SELECT COUNT(bus_id) INTO v_cnt
                      FROM comm_impr_rgstr
                     WHERE bus_id = p_rec.bus_id
                       AND brnchreg = 0;
                    IF v_cnt = 0 THEN
                        v_ret := lib_usr.gnrl.get_customs_setting(p_ctx.curr_port_cd, 'COMM_TABLE_UNCHECK', 9);
                        IF NVL(v_ret, 0) = 0 THEN
                            disp_arb_ftf(9, 190);
                        ELSE
                            p_rec.customs_entered := 1;
                        END IF;
                    ELSE
                        p_rec.customs_entered := 0;
                    END IF;
                ELSE
                    disp_arb_ftf(9, 250);
                END IF;
            ELSIF p_rec.comm_rgstrtn_type = 2 THEN
                IF p_rec.bus_id IS NOT NULL AND p_rec.bus_id_brnch IS NOT NULL THEN
                    SELECT COUNT(bus_id) INTO v_cnt
                      FROM comm_impr_rgstr
                     WHERE bus_id       = p_rec.bus_id
                       AND brnch_bus_id = p_rec.bus_id_brnch;
                    IF v_cnt = 0 THEN
                        v_ret := lib_usr.gnrl.get_customs_setting(p_ctx.curr_port_cd, 'COMM_TABLE_UNCHECK', 9);
                        IF NVL(v_ret, 0) = 0 THEN
                            disp_arb_ftf(9, 190);
                        ELSE
                            p_rec.customs_entered := 1;
                        END IF;
                    ELSE
                        p_rec.customs_entered := 0;
                    END IF;
                ELSE
                    disp_arb_ftf(9, 230);
                END IF;
            ELSE
                entrable('COMM_RGSTRTN_TYPE', TRUE);
                disp_arb_ftf(9, 240);
            END IF;
        END IF;
        p_rec.mobile_no := p_rec.b_mobile_no;
    END importers_pre_upd;

    -- Source: Forms default UPDATE (key mode ROWID; all base-table items are written).
    -- The key is the ROWID of the queried row - NOT (PORT_CD, IMPR_NBR) - because PORT_CD
    -- itself can change (B_EMAIL / B_MOBILE_NO / B_ID_NBR POST-CHANGE set it to the
    -- current port).
    PROCEDURE importers_upd (p_rec IN t_rec)
    IS
    BEGIN
        UPDATE importers
           SET port_cd           = p_rec.port_cd,
               hq_impr_nbr       = p_rec.hq_impr_nbr,
               impr_nbr          = p_rec.impr_nbr,
               bus_id_status     = p_rec.bus_id_status,
               impr_type_cd      = p_rec.impr_type_cd,
               bus_id_exprd_dt   = p_rec.bus_id_exprd_dt,
               bus_id_type_cd    = p_rec.bus_id_type_cd,
               comm_rgstrtn_type = p_rec.comm_rgstrtn_type,
               city_code_of_id   = p_rec.city_code_of_id,
               bus_id            = p_rec.bus_id,
               bus_id_brnch      = p_rec.bus_id_brnch,
               ctry_cd           = p_rec.ctry_cd,
               impr_expr_type    = p_rec.impr_expr_type,
               arbc_impr_name    = p_rec.arbc_impr_name,
               impr_name_std     = p_rec.impr_name_std,
               lst_tran_dt       = p_rec.lst_tran_dt,
               impd_stmt_nbr     = p_rec.impd_stmt_nbr,
               impr_data_srce    = p_rec.impr_data_srce,
               eng_impr_name     = p_rec.eng_impr_name,
               impr_cntct_name   = p_rec.impr_cntct_name,
               impr_address      = p_rec.impr_address,
               bus_id_issue_dt   = p_rec.bus_id_issue_dt,
               impr_nbr_parent   = p_rec.impr_nbr_parent,
               add_ctry_cd       = p_rec.add_ctry_cd,
               city_code         = p_rec.city_code,
               impr_pob_nbr      = p_rec.impr_pob_nbr,
               impr_zip_cd       = p_rec.impr_zip_cd,
               impr_tel_nbr      = p_rec.impr_tel_nbr,
               impr_fax_nbr      = p_rec.impr_fax_nbr,
               impr_telex_nbr    = p_rec.impr_telex_nbr,
               email             = p_rec.email,
               mobile_no         = p_rec.mobile_no,
               bank_iban         = p_rec.bank_iban,
               id_nbr            = p_rec.id_nbr,
               car_agent_flag    = p_rec.car_agent_flag,
               express_post      = p_rec.express_post,
               ctry_cd_of_id     = p_rec.ctry_cd_of_id,
               expd_stmt_nbr     = p_rec.expd_stmt_nbr,
               wvr_entry_nbr     = p_rec.wvr_entry_nbr,
               activity          = p_rec.activity,
               customs_entered   = p_rec.customs_entered,
               creation_flag     = p_rec.creation_flag
         WHERE ROWID = CHARTOROWID(p_rec.row_id);
        IF SQL%ROWCOUNT = 0 THEN
            -- Forms: FRM-40654 "Record has been updated by another user. Re-query..."
            ftf('FRM-40654');   -- TODO: Arabic text of FRM-40654 used by NIB.ON_ERROR (MISSING SOURCE)
        END IF;
    END importers_upd;

    -- Source: IMPORTERS.POST-UPDATE
    --@ORIG IMPORTERS.POST-UPDATE
    -- >>> Original Forms code: IMPORTERS.POST-UPDATE
    --   BEGIN
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID' , FALSE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_BRNCH', FALSE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_EXPRD_DT' , FALSE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.ARBC_IMPR_NAME' , FALSE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.COMM_RGSTRTN_TYPE' , FALSE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_BRNCH' , FALSE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.CITY_CODE_OF_ID',FALSE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_TYPE_CD' , FALSE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_EXPR_TYPE' , FALSE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_TYPE_CD' , FALSE);
    --        INTRFACE.Make_Field_Entrable('IMPORTERS.BRNH_CITY_CD' , FALSE);
    --        IF DB_JOURNAL.IS_JOURNALING_ON THEN
    --           DB_JOURNAL.JOURNALING_OFF;
    --        END IF;
    --   END;
    --   IF :GLOBAL.FLAGUPDATE = 1 THEN
    --   UPDATE_BASIC_IMPORTER;
    --   :GLOBAL.FLAGUPDATE := 0;
    --   END IF;
    -- <<<
    PROCEDURE importers_post_upd (p_rec IN OUT NOCOPY t_rec)
    IS
    BEGIN
        lock_key_items;
        IF db_journal.is_journaling_on THEN
            db_journal.journaling_off;
        END IF;
        IF g_get('FLAGUPDATE') = '1' THEN
            update_basic_importer(p_rec);
            g_set('FLAGUPDATE', '0');
        END IF;
    END importers_post_upd;

    -- Source: IMPORTERS.PRE-DELETE
    --@ORIG IMPORTERS.PRE-DELETE
    -- >>> Original Forms code: IMPORTERS.PRE-DELETE
    --   BEGIN
    --       IF NOT ACTIVITY.ADD_ACTIVITY(9, 2, 5, :IMPORTERS.Port_Cd||'!'||:IMPORTERS.Impr_Nbr) THEN
    --           RAISE FORm_Trigger_Failure;
    --       END IF;
    --   END;
    -- <<<
    PROCEDURE importers_pre_del (p_rec IN t_rec)
    IS
    BEGIN
        add_activity(5, p_rec);
    END importers_pre_del;

    -- Source: IMPORTERS.KEY-DELREC, branch "ALERT_BUTTON1" (Confirm DA 'هل أنت متأكد من عملية الحذف')
    -- The REMOVE button visible+enabled check -> Server-side Condition / Authorization of DELETE.
    -- HIGH: FORMS_DDL('COMMIT') after deleting IMPR_UPDTS and the final COMMIT are removed:
    -- in Forms the IMPR_UPDTS rows stay deleted even if the importer delete fails; in APEX both
    -- are in one transaction. Block property DeleteAllowed = false - see open questions.
    --@ORIG IMPORTERS.KEY-DELREC
    -- >>> Original Forms code: IMPORTERS.KEY-DELREC
    --   DECLARE
    --       RET  NUMBER;
    --       PROP VARCHAR2(10);
    --       STAT VARCHAR2(10);
    --       PROP1 VARCHAR2(10);
    --   BEGIN
    --     STAT := NAME_IN('SYSTEM.RECORD_STATUS');
    --     PROP1 := GET_ITEM_PROPERTY('REMOVE',VISIBLE);
    --     PROP  := GET_ITEM_PROPERTY('REMOVE',ENABLED);
    --     IF PROP = 'FALSE' AND PROP1 = 'FALSE' THEN
    --          NULL;
    --     ELSIF STAT !='NEW' AND PROP = 'TRUE' AND PROP1 = 'TRUE' THEN
    --       BEGIN
    --           RET := STR.DispAlert('هل أنت متأكد من عملية الحذف','WARNING');
    --           IF RET = ALERT_BUTTON1 THEN
    --           DELETE     IMPR_UPDTS
    --           WHERE     PORT_CD     = :IMPORTERS.PORT_CD
    --           AND        IMPR_NBR     = :IMPORTERS.IMPR_NBR
    --           ;
    --           FORMS_DDL('COMMIT');
    --                Delete_record;
    --               COMMIT;
    --            ELSIF RET = ALERT_BUTTON2 THEN
    --              NULL;
    --          END IF;
    --       END;
    --   END IF;
    --   END;
    -- <<<
    PROCEDURE importers_key_delrec (p_rec IN t_rec)
    IS
    BEGIN
        IF NVL(p_rec.rec_status, 'QUERY') != 'NEW' THEN
            DELETE impr_updts
             WHERE port_cd  = p_rec.port_cd
               AND impr_nbr = p_rec.impr_nbr;
            -- FORMS_DDL('COMMIT');   -- removed, see header
            importers_pre_del(p_rec);              -- Delete_Record -> PRE-DELETE
            DELETE importers                        -- Forms default DELETE (key mode ROWID)
             WHERE ROWID = CHARTOROWID(p_rec.row_id);
            -- COMMIT;                -- removed, see header
        END IF;
    END importers_key_delrec;

    -- Source: IMPORTERS.ON-ERROR (+ PU CGTE$CHECK_CONSTRAINT_VIO).
    -- p_op = 'I' / 'U' / 'D' (FRM-40508 / 40509 / 40510). Returns the text Forms shows.
    --@ORIG IMPORTERS.ON-ERROR
    -- >>> Original Forms code: IMPORTERS.ON-ERROR
    --   BEGIN
    --     DECLARE
    --       err_code        CONSTANT NUMBER         := ERROR_CODE;
    --       err_type        CONSTANT VARCHAR2(3)    := ERROR_TYPE;
    --       server_err               NUMBER         := abs(DBMS_ERROR_CODE);
    --       server_msg               VARCHAR2(2000) := DBMS_ERROR_TEXT;
    --       constraint_name          VARCHAR2(61);
    --     BEGIN
    --         IF server_err = 1031 THEN
    --   IF (err_type = 'FRM' AND
    --           err_code = 40508 ) THEN
    --   Des$Form_errors.PUSH('ليس لديك صلاحية الادخال ' ,'E', 'OFG',0);
    --   END IF;
    --   IF (err_type = 'FRM' AND
    --           err_code = 40509 ) THEN
    --   Des$Form_errors.PUSH('ليس لديك صلاحية التعديل' ,'E', 'OFG',0);
    --   END IF;
    --   IF (err_type = 'FRM' AND
    --           err_code = 40510 ) THEN
    --   Des$Form_errors.PUSH('ليس لديك صلاحية الحذف' ,'E', 'OFG',0);
    --   END IF;
    --   END IF;
    --     END;
    --     END;
    --   BEGIN
    --     DECLARE
    --       err_code        CONSTANT NUMBER         := ERROR_CODE;
    --       err_type        CONSTANT VARCHAR2(3)    := ERROR_TYPE;
    --       server_err               NUMBER         := abs(DBMS_ERROR_CODE);
    --       server_msg               VARCHAR2(2000) := DBMS_ERROR_TEXT;
    --       constraint_name          VARCHAR2(61);
    --     BEGIN
    --       IF (err_type = 'FRM' AND
    --           err_code IN (40506, 40508, 40509, 40510) ) THEN
    --         WHILE (server_err = 604) LOOP
    --           CGTE$POP_ERROR_STACK(server_err, server_msg);
    --         END LOOP;
    --         IF ( CGTE$CHECK_CONSTRAINT_VIO(server_err, server_msg) ) THEN
    --           Des$Form_errors.RAISE_FAILURE;
    --         END IF;
    --         constraint_name := CGTE$STRIP_CONSTRAINT(server_msg);
    --         IF (server_err = 2291) THEN
    --           IF (constraint_name = 'IMP_SDP_FK') THEN
    --             Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(13, 'This <p1> does not exist', 'رمز الجمــــــــــــــرك' ), 'E', 'OFG', 13);
    --           ELSIF (constraint_name = 'IMP_NATIONALITY_FK') THEN
    --             Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(13, 'This <p1> does not exist', 'NATIONALITY' ), 'E', 'OFG', 13);
    --           ELSIF (constraint_name = 'IMP_ITIDT_FK') THEN
    --             Des$Form_errors.PUSH('رمز النشاط التجاري غير صحيح - أعد إدخال البيانات', 'E', 'OFG', 0);
    --           ELSIF (constraint_name = 'IMP_IMP_FK') THEN
    --             Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(13, 'This <p1> does not exist', 'IMPR_NBR_PARENT,PORT_CD' ), 'E', 'OFG', 13);
    --           ELSIF (constraint_name = 'IMP_CTRY_FK') THEN
    --             Des$Form_errors.PUSH('رمز الدولة غير صحيح - أعد ادخال البيانات', 'E', 'OFG', 0);
    --           ELSIF (constraint_name = 'IMP_BUS_ID_CITY_FK') THEN
    --             Des$Form_errors.PUSH('خطأ في رمز مدينة مصدر الرقم الإستدلالي', 'E', 'OFG', 0);
    --           ELSIF (constraint_name = 'IMP_ADD_CITY_FK') THEN
    --             Des$Form_errors.PUSH('خطأ في رمز مدينة عنوان المستورد', 'E', 'OFG', 0);
    --           ELSE
    --             Des$Form_errors.PUSH(server_msg, 'I', 'OFG', 0);
    --           END IF;
    --           Des$Form_errors.RAISE_FAILURE;
    --         END IF;
    --         IF (server_err = 2292) THEN
    --           IF (err_code = 40509) THEN
    --             Des$Form_errors.PUSH(server_msg, 'I', 'OFG', 0);
    --           END IF;
    --           Des$Form_errors.RAISE_FAILURE;
    --         END IF;
    --       END IF;
    --       IF (err_type = 'FRM' AND
    --           err_code = 40735 ) THEN
    --         WHILE (server_err = 604) LOOP
    --           CGTE$POP_ERROR_STACK(server_err, server_msg);
    --         END LOOP;
    --         Des$Form_errors.PUSH(err_type||'-'||to_char(server_err)||': '||server_msg, 'I', 'OFG', 0);
    --         Des$Form_errors.RAISE_FAILURE;
    --       END IF;
    --       Des$Form_errors.PUSH(err_type||'-'||to_char(err_code)||': '||ERROR_TEXT, 'I', 'OFG', 0);
    --       Des$Form_errors.RAISE_FAILURE;
    --     END;
    --   END;
    -- <<<
    --@ORIG PU CGTE$CHECK_CONSTRAINT_VIO
    -- >>> Original Forms code: PU CGTE$CHECK_CONSTRAINT_VIO
    --   FUNCTION CGTE$CHECK_CONSTRAINT_VIO(
    --      P_SERVER_ERR IN NUMBER
    --     ,P_SERVER_MSG IN VARCHAR2)
    --   RETURN BOOLEAN IS
    --     constraint_name VARCHAR2(61);
    --   BEGIN
    --     IF ( NOT (P_SERVER_ERR IN  (1, 2290) OR
    --              (P_SERVER_ERR >= 20000 AND P_SERVER_ERR <= 20999) ) )
    --     THEN
    --       RETURN( FALSE );
    --     END IF;
    --     IF (P_SERVER_ERR >= 20000 AND P_SERVER_ERR <= 20999) THEN
    --       Des$Form_errors.PUSH(''||CGTE$STRIP_FIRST_ERROR(P_SERVER_MSG), 'E', 'OFG', 0);
    --       RETURN( TRUE );
    --     END IF;
    --     constraint_name := CGTE$STRIP_CONSTRAINT(P_SERVER_MSG);
    --     IF (P_SERVER_ERR = 1) THEN
    --       IF (constraint_name = 'IMP_PK') THEN
    --         Des$Form_errors.PUSH('هذا السجل مدخل سابقاً - أعد ادخال البيانات', 'E', 'OFG', 0);
    --       ELSIF (constraint_name = 'IMP_BUSID_UK') THEN
    --         Des$Form_errors.PUSH('هذا السجل مدخل سابقاً - أعد ادخال البيانات', 'E', 'OFG', 0);
    --       ELSIF (constraint_name = 'SDP_PK') THEN
    --         Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(6, 'Row exists already with same <p1>', 'رمز الجمرك' ), 'E', 'OFG', 6);
    --       ELSIF (constraint_name = 'ITIDT_PK') THEN
    --         Des$Form_errors.PUSH('هذا السجل مدخل سابقاً - أعد ادخال البيانات', 'E', 'OFG', 0);
    --       ELSIF (constraint_name = 'IT_PK') THEN
    --         Des$Form_errors.PUSH('هذا السجل مدخل سابقاً - أعد ادخال البيانات', 'E', 'OFG', 0);
    --       ELSIF (constraint_name = 'BIT_PK') THEN
    --         Des$Form_errors.PUSH('هذا السجل مدخل سابقاً - أعد ادخال البيانات', 'E', 'OFG', 0);
    --       ELSIF (constraint_name = 'CT_PK') THEN
    --         Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(6, 'Row exists already with same <p1>', 'City Cd,رمز الدولة' ), 'E', 'OFG', 6);
    --       ELSIF (constraint_name = 'CT_PK') THEN
    --         Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(6, 'Row exists already with same <p1>', 'City Cd,رمز الدولة' ), 'E', 'OFG', 6);
    --       ELSIF (constraint_name = 'CTRY_PK') THEN
    --         Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(6, 'Row exists already with same <p1>', 'رمز الدولة' ), 'E', 'OFG', 6);
    --       ELSIF (constraint_name = 'CTRY_PK') THEN
    --         Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(6, 'Row exists already with same <p1>', 'Ctry Cd' ), 'E', 'OFG', 6);
    --       ELSE
    --         Des$Form_errors.PUSH(P_SERVER_MSG, 'I', 'OFG', 0);
    --       END IF;
    --     ELSIF (P_SERVER_ERR = 2290) THEN
    --       Des$Form_errors.PUSH(P_SERVER_MSG, 'I', 'OFG', 0);
    --     END IF;
    --     RETURN( TRUE );
    --   END;
    -- <<<
    FUNCTION importers_on_error (p_op IN VARCHAR2, p_sqlcode IN NUMBER, p_sqlerrm IN VARCHAR2)
        RETURN VARCHAR2
    IS
        server_err      NUMBER := ABS(p_sqlcode);
        constraint_name VARCHAR2(61);
    BEGIN
        IF server_err = 1031 THEN
            IF p_op = 'I' THEN RETURN 'ليس لديك صلاحية الادخال '; END IF;
            IF p_op = 'U' THEN RETURN 'ليس لديك صلاحية التعديل'; END IF;
            IF p_op = 'D' THEN RETURN 'ليس لديك صلاحية الحذف'; END IF;
        END IF;
        -- CGTE$CHECK_CONSTRAINT_VIO
        IF server_err BETWEEN 20000 AND 20999 THEN
            -- CGTE$STRIP_FIRST_ERROR (MISSING SOURCE): text without the "ORA-2xxxx: " prefix
            RETURN REGEXP_REPLACE(REGEXP_SUBSTR(p_sqlerrm, '[^' || CHR(10) || ']+'), '^ORA-[0-9]+: ');
        END IF;
        constraint_name := strip_constraint(p_sqlerrm);
        IF server_err = 1 THEN
            IF constraint_name IN ('IMP_PK', 'IMP_BUSID_UK', 'ITIDT_PK', 'IT_PK', 'BIT_PK') THEN
                RETURN 'هذا السجل مدخل سابقاً - أعد ادخال البيانات';
            ELSIF constraint_name = 'SDP_PK' THEN
                RETURN cg_msg('Row exists already with same <p1>', 'رمز الجمرك');
            ELSIF constraint_name = 'CT_PK' THEN
                RETURN cg_msg('Row exists already with same <p1>', 'City Cd,رمز الدولة');
            ELSIF constraint_name = 'CTRY_PK' THEN
                RETURN cg_msg('Row exists already with same <p1>', 'رمز الدولة');
            END IF;
            RETURN p_sqlerrm;
        ELSIF server_err = 2290 THEN
            RETURN p_sqlerrm;
        END IF;
        -- FK - parent key not found
        IF server_err = 2291 THEN
            IF constraint_name = 'IMP_SDP_FK' THEN
                RETURN cg_msg('This <p1> does not exist', 'رمز الجمــــــــــــــرك');
            ELSIF constraint_name = 'IMP_NATIONALITY_FK' THEN
                RETURN cg_msg('This <p1> does not exist', 'NATIONALITY');
            ELSIF constraint_name = 'IMP_ITIDT_FK' THEN
                RETURN 'رمز النشاط التجاري غير صحيح - أعد إدخال البيانات';
            ELSIF constraint_name = 'IMP_IMP_FK' THEN
                RETURN cg_msg('This <p1> does not exist', 'IMPR_NBR_PARENT,PORT_CD');
            ELSIF constraint_name = 'IMP_CTRY_FK' THEN
                RETURN 'رمز الدولة غير صحيح - أعد ادخال البيانات';
            ELSIF constraint_name = 'IMP_BUS_ID_CITY_FK' THEN
                RETURN 'خطأ في رمز مدينة مصدر الرقم الإستدلالي';
            ELSIF constraint_name = 'IMP_ADD_CITY_FK' THEN
                RETURN 'خطأ في رمز مدينة عنوان المستورد';
            END IF;
            RETURN p_sqlerrm;
        END IF;
        -- FK - child record found
        IF server_err = 2292 THEN
            RETURN p_sqlerrm;
        END IF;
        RETURN p_sqlerrm;
    END importers_on_error;

    -- ======================================================================= ITEM TRIGGERS

    -- Source: IMPORTERS.PORT_CD.WHEN-VALIDATE-ITEM (first block fully commented out in Forms)
    --@ORIG IMPORTERS.PORT_CD.WHEN-VALIDATE-ITEM
    -- >>> Original Forms code: IMPORTERS.PORT_CD.WHEN-VALIDATE-ITEM
    --   BEGIN
    --   NULL;
    --   END;
    --   BEGIN
    --     IF (name_in('IMPORTERS.PORT_CD') IS NOT NULL) THEN
    --       BEGIN
    --         CGFK$CHK_IMPORTERS_IMP_SDP_FK(
    --           :IMPORTERS.PORT_NAME
    --          ,:IMPORTERS.SDP_PORT_STATUS
    --          ,:IMPORTERS.PORT_CD        );
    --       EXCEPTION
    --         WHEN NO_DATA_FOUND THEN
    --           Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(13, 'This <p1> does not exist', 'رمز الجمــــــــــــــرك' ), 'E', 'OFG', 13);
    --           Des$Form_errors.RAISE_FAILURE;
    --         WHEN OTHERS THEN
    --           CGTE$OTHER_EXCEPTIONS;
    --       END;
    --     END IF;
    --   END;
    -- <<<
    PROCEDURE port_cd_wvi (p_rec IN OUT NOCOPY t_rec)
    IS
    BEGIN
        IF p_rec.port_cd IS NOT NULL THEN
            SELECT l_sdp.port_status, l_sdp.port_name
              INTO p_rec.sdp_port_status, p_rec.port_name
              FROM sd_ports l_sdp
             WHERE l_sdp.port_cd = p_rec.port_cd;
        END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            ftf(cg_msg('This <p1> does not exist', 'رمز الجمــــــــــــــرك'));
    END port_cd_wvi;

    -- Source: IMPORTERS.HQ_IMPR_NBR.POST-CHANGE (same body: BUS_ID, BUS_ID_BRNCH, IMPR_EXPR_TYPE)
    PROCEDURE hq_impr_nbr_post_chg
    IS
    BEGIN
        g_set('FLAGUPDATE', '1');
    END hq_impr_nbr_post_chg;

    -- Source: IMPORTERS.IMPR_NBR.WHEN-VALIDATE-ITEM
    -- APEX: when an existing number is typed, the page re-queries that importer
    -- (EXEC_QUERY_NOW=1 is consumed by IMPR_TYPE_CD/BUS_ID_EXPRD_DT/block WHEN-NEW-ITEM-INSTANCE).
    --@ORIG IMPORTERS.IMPR_NBR.WHEN-VALIDATE-ITEM
    -- >>> Original Forms code: IMPORTERS.IMPR_NBR.WHEN-VALIDATE-ITEM
    --   DECLARE
    --       rec_count NUMBER;
    --   BEGIN
    --   IF (:IMPORTERS.IMPR_NBR IS NOT NULL) THEN
    --       SELECT COUNT(*) INTO Rec_Count
    --       FROM IMPORTERS
    --       WHERE PORT_CD = :IMPORTERS.PORT_CD
    --       AND IMPR_NBR = :IMPORTERS.IMPR_NBR;
    --       IF Rec_Count <> 0 THEN
    --           :global.PORT_CD    := :IMPORTERS.PORT_CD;
    --           :global.IMPR_NBR    := :IMPORTERS.IMPR_NBR;
    --           :global.Exec_Query_Now := 1;
    --       ELSE
    --           rec_count := STR.DispArbMsg(9, 150,'INFORMATION');
    --           RAISE FORm_Trigger_Failure;
    --       END IF;
    --   END IF;
    --   END;
    -- <<<
    PROCEDURE impr_nbr_wvi (p_rec IN OUT NOCOPY t_rec)
    IS
        rec_count NUMBER;
    BEGIN
        IF (p_rec.impr_nbr IS NOT NULL) THEN
            SELECT COUNT(*) INTO rec_count
              FROM importers
             WHERE port_cd  = p_rec.port_cd
               AND impr_nbr = p_rec.impr_nbr;
            IF rec_count <> 0 THEN
                g_set('PORT_CD', p_rec.port_cd);
                g_set('IMPR_NBR', p_rec.impr_nbr);
                g_set('EXEC_QUERY_NOW', '1');
            ELSE
                disp_arb_ftf(9, 150);
            END IF;
        END IF;
    END impr_nbr_wvi;

    -- Source: IMPORTERS.IMPR_TYPE_CD.WHEN-VALIDATE-ITEM
    --@ORIG IMPORTERS.IMPR_TYPE_CD.WHEN-VALIDATE-ITEM
    -- >>> Original Forms code: IMPORTERS.IMPR_TYPE_CD.WHEN-VALIDATE-ITEM
    --   DECLARE
    --       IMPR_SEQ VARCHAR2(6);
    --       BUS_ID_COUNT NUMBER;
    --       V_COUNT NUMBER;
    --       RET NUMBER;
    --       V_COUNT_IMPR_TYPE_CD NUMBER;
    --   BEGIN
    --   BEGIN
    --       IF :IMPR_NBR IS NOT NULL THEN
    --           IF NVL(:IMPORTERS.IMPR_TYPE_CD,0) NOT IN (4,9) AND :IMPR_NBR > TO_NUMBER(NVL(gnrl.get_customs_setting ('CREATE_IMPR_NBR',9),5000000)) THEN
    --               RET:=Str.DispArbMsg(9, 332,'INFORMATION');
    --               RAISE FORM_TRIGGER_FAILURE;
    --           END IF;
    --       ELSE
    --           IF NVL(:IMPORTERS.IMPR_TYPE_CD,0) NOT IN (4,9) THEN
    --               RET:=Str.DispArbMsg(9, 332,'INFORMATION');
    --               RAISE FORM_TRIGGER_FAILURE;
    --           END IF;
    --       END IF;
    --   END;
    --   IF NVL(gnrl.get_customs_setting ('STOP_IMPR_CR_TYPE',9),0) = 1 THEN
    --   SELECT COUNT(*) INTO  V_COUNT_IMPR_TYPE_CD
    --   FROM     IMPR_TYPE_ID_TYPES
    --   WHERE IMPR_TYPE_CD     = :IMPORTERS.IMPR_TYPE_CD
    --   AND   BUS_ID_TYPE_CD     = 2
    --   AND   STATUS         = 1
    --   ;
    --       IF  V_COUNT_IMPR_TYPE_CD > 0  THEN
    --             RET:=Str.DispArbMsg(9, 331,'INFORMATION');
    --             RAISE FORM_TRIGGER_FAILURE;
    --       END IF;
    --   END IF;
    --   IF :GLOBAL.VALID  = 0 THEN
    --       IF :IMPORTERS.IMPR_TYPE_CD IS NOT NULL THEN
    --           SELECT COUNT(*)
    --           INTO BUS_ID_COUNT
    --           FROM IMPR_TYPE_ID_TYPES
    --           WHERE IMPR_TYPE_CD = :IMPORTERS.IMPR_TYPE_CD
    --            AND  STATUS=1 ;
    --           IF BUS_ID_COUNT = 1 THEN
    --               SELECT IT.BUS_ID_TYPE_CD, IDT.BUS_ID_TYPE_NAME
    --               INTO :IMPORTERS.BUS_ID_TYPE_CD, :IMPORTERS.BUS_ID_TYPE_NAME
    --               FROM IMPR_TYPE_ID_TYPES IT, BUS_ID_TYPES IDT
    --               WHERE IT.IMPR_TYPE_CD = :IMPORTERS.IMPR_TYPE_CD
    --                      AND IT.STATUS=1
    --                 AND IT.BUS_ID_TYPE_CD = IDT.BUS_ID_TYPE_CD;
    --           ELSIF BUS_ID_COUNT > 1   THEN
    --                DO_KEY('LIST_VALUES ');
    --           ELSE
    --                 :IMPORTERS.IMPR_TYPE_CD:=NULL;
    --                 RET:=Str.DispArbMsg(2, 170,'INFORMATION');
    --                 RAISE FORM_TRIGGER_FAILURE;
    --           END IF;
    --       END IF;
    --   END IF;
    --   :GLOBAL.VALID:=0;
    --   IF :IMPORTERS.IMPR_TYPE_CD IS NOT NULL THEN
    --       SELECT     IMPR_TYPE_NAME
    --       INTO        :IMPORTERS.IMPR_TYPE_NAME
    --       FROM        IMPR_TYPES
    --       WHERE        IMPR_TYPE_CD = :IMPORTERS.IMPR_TYPE_CD ;
    --   END IF;
    --   IF     :GLOBAL.FUNS_IMP = 0 THEN
    --       IF :IMPORTERS.BUS_ID_TYPE_CD  = 2  AND :IMPORTERS.IMPR_TYPE_CD !=12 THEN
    --           INTRFACE.Make_Field_Entrable('IMPORTERS.COMM_RGSTRTN_TYPE' , TRUE);
    --           SET_ITEM_PROPERTY('IMPORTERS.COMM_RGSTRTN_TYPE',REQUIRED,PROPERTY_TRUE);
    --       ELSE
    --           INTRFACE.Make_Field_Entrable('IMPORTERS.COMM_RGSTRTN_TYPE' , FALSE);
    --           SET_ITEM_PROPERTY('IMPORTERS.COMM_RGSTRTN_TYPE',REQUIRED,PROPERTY_FALSE);
    --       END IF;
    --       IF :IMPORTERS.IMPR_TYPE_CD = 1 THEN
    --           :IMPORTERS.CTRY_CD := 100;
    --           :IMPORTERS.ADD_CTRY_CD := 100;
    --           INTRFACE.Make_Field_Entrable('IMPORTERS.CTRY_CD' , FALSE);
    --           INTRFACE.Make_Field_Entrable('IMPORTERS.ADD_CTRY_CD' , FALSE);
    --       ELSIF :IMPORTERS.IMPR_TYPE_CD = 2 THEN
    --           :IMPORTERS.CTRY_CD := 100;
    --           :IMPORTERS.ADD_CTRY_CD := 100;
    --           INTRFACE.Make_Field_Entrable('IMPORTERS.CTRY_CD' , FALSE);
    --           INTRFACE.Make_Field_Entrable('IMPORTERS.ADD_CTRY_CD' , FALSE);
    --           INTRFACE.Make_Field_Entrable('IMPORTERS.CITY_CODE_OF_ID' , FALSE);
    --           SET_ITEM_PROPERTY('IMPORTERS.CITY_CODE_OF_ID2' , ENABLED , PROPERTY_FALSE);
    --           INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_BRNCH' , FALSE);
    --       ELSIF :IMPORTERS.IMPR_TYPE_CD = 4 THEN
    --           IF :IMPORTERS.BUS_ID_TYPE_CD = 5 THEN
    --               :IMPORTERS.CTRY_CD := 100;
    --               :IMPORTERS.ADD_CTRY_CD := 100;
    --           END IF;
    --           INTRFACE.Make_Field_Entrable('IMPORTERS.CITY_CODE_OF_ID' , FALSE);
    --           SET_ITEM_PROPERTY('IMPORTERS.CITY_CODE_OF_ID2' , ENABLED , PROPERTY_FALSE);
    --           INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_BRNCH' , FALSE);
    --       ELSIF :IMPORTERS.IMPR_TYPE_CD = 5 THEN
    --           :IMPORTERS.CTRY_CD := 100;
    --           :IMPORTERS.ADD_CTRY_CD := 100;
    --           INTRFACE.Make_Field_Entrable('IMPORTERS.CTRY_CD' , FALSE);
    --           INTRFACE.Make_Field_Entrable('IMPORTERS.ADD_CTRY_CD' , FALSE);
    --       ELSIF :IMPORTERS.IMPR_TYPE_CD = 7 THEN
    --           INTRFACE.Make_Field_Entrable('IMPORTERS.CITY_CODE_OF_ID' , FALSE);
    --           SET_ITEM_PROPERTY('IMPORTERS.CITY_CODE_OF_ID2' , ENABLED , PROPERTY_FALSE);
    --           INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_BRNCH' , FALSE);
    --       ELSIF :IMPORTERS.IMPR_TYPE_CD = 8 THEN
    --           :IMPORTERS.CTRY_CD := 100;
    --           :IMPORTERS.ADD_CTRY_CD := 100;
    --           INTRFACE.Make_Field_Entrable('IMPORTERS.CTRY_CD' , FALSE);
    --           INTRFACE.Make_Field_Entrable('IMPORTERS.ADD_CTRY_CD' , FALSE);
    --       ELSIF :IMPORTERS.IMPR_TYPE_CD = 9 THEN
    --           :IMPORTERS.CTRY_CD := 100;
    --           :IMPORTERS.ADD_CTRY_CD := 100;
    --           IF :IMPORTERS.BUS_ID_TYPE_CD IS NULL THEN
    --               :IMPORTERS.BUS_ID_TYPE_CD := 6;
    --           END IF;
    --           IF :IMPORTERS.BUS_ID_TYPE_CD = 6 THEN
    --               SELECT LPAD(--KING_IMPR_SEQ.NEXTVAL
    --               GNRL.GET_SEQUENCE_VALUE (:PARAMETER.P_CURR_PORT_CD,'KING_IMPR_SEQ')
    --               , 6,'0') INTO IMPR_SEQ FROM DUAL;
    --               :IMPORTERS.BUS_ID := 'ملكى'||IMPR_SEQ;
    --               INTRFACE.Make_Field_Entrable('IMPORTERS.CTRY_CD' , FALSE);
    --               INTRFACE.Make_Field_Entrable('IMPORTERS.ADD_CTRY_CD' , FALSE);
    --               INTRFACE.Make_Field_Entrable('IMPORTERS.CITY_CODE_OF_ID' , FALSE);
    --               SET_ITEM_PROPERTY('IMPORTERS.CITY_CODE_OF_ID2' , ENABLED , PROPERTY_FALSE);
    --               INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_BRNCH' , FALSE);
    --               INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID' , FALSE);
    --           ELSE
    --               INTRFACE.Make_Field_Entrable('IMPORTERS.CTRY_CD' , TRUE);
    --               INTRFACE.Make_Field_Entrable('IMPORTERS.ADD_CTRY_CD' , TRUE);
    --               INTRFACE.Make_Field_Entrable('IMPORTERS.CITY_CODE_OF_ID' , TRUE);
    --               SET_ITEM_PROPERTY('IMPORTERS.CITY_CODE_OF_ID2' , ENABLED , PROPERTY_TRUE);
    --               INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID' , TRUE);
    --               INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_BRNCH' , FALSE);
    --           END IF;
    --       ELSIF :IMPORTERS.IMPR_TYPE_CD = 10 THEN
    --               INTRFACE.Make_Field_Entrable('IMPORTERS.CITY_CODE_OF_ID' , FALSE);
    --               SET_ITEM_PROPERTY('IMPORTERS.CITY_CODE_OF_ID2' , ENABLED , PROPERTY_FALSE);
    --               INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_BRNCH' , FALSE);
    --       ELSIF :IMPORTERS.IMPR_TYPE_CD = 11 THEN
    --               :IMPORTERS.CTRY_CD := 100;
    --               :IMPORTERS.ADD_CTRY_CD := 100;
    --               INTRFACE.Make_Field_Entrable('IMPORTERS.CTRY_CD' , FALSE);
    --               INTRFACE.Make_Field_Entrable('IMPORTERS.ADD_CTRY_CD' , FALSE);
    --               INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_BRNCH' , FALSE);
    --       ELSIF :IMPORTERS.IMPR_TYPE_CD = 12 THEN
    --               INTRFACE.Make_Field_Entrable('IMPORTERS.CITY_CODE_OF_ID' , FALSE);
    --               SET_ITEM_PROPERTY('IMPORTERS.CITY_CODE_OF_ID2' , ENABLED , PROPERTY_FALSE);
    --               IF :CTRY_CD IS NOT NULL THEN
    --                   SELECT COUNT(*)
    --                   INTO     V_COUNT
    --                   FROM     CTRY_GROUP_DETAILS
    --                   WHERE  CTRY_CD = :CTRY_CD
    --                   AND     CTRY_GRP_STAT = 1
    --                   AND     CTRY_GRP_NBR = 1
    --                   ;
    --                   IF V_COUNT = 0 THEN
    --                       STR.DISPALERT('لابد أن تكون دولة المستورد الخليجي تابعة لدول مجلس التعاون','INFORMATION');
    --                       RAISE FORM_TRIGGER_FAILURE;
    --                   END IF;
    --               END IF;
    --       ELSIF :IMPORTERS.IMPR_TYPE_CD IN (13,14,16,17,18,20) THEN
    --           SELECT --IMPORTERS_SEQ.NEXTVAL
    --           GNRL.GET_SEQUENCE_VALUE (:PARAMETER.P_CURR_PORT_CD,'IMPORTERS_SEQ')
    --            INTO :IMPORTERS.BUS_ID FROM DUAL;
    --               IF :IMPORTERS.BUS_ID IS NULL THEN
    --                   :IMPORTERS.BUS_ID := 1;
    --               END IF;
    --               :IMPORTERS.CTRY_CD := 100;
    --               :IMPORTERS.ADD_CTRY_CD := 100;
    --               INTRFACE.Make_Field_Entrable('IMPORTERS.CTRY_CD' , FALSE);
    --               INTRFACE.Make_Field_Entrable('IMPORTERS.ADD_CTRY_CD' , FALSE);
    --               INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID' , FALSE);
    --               INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_BRNCH' , FALSE);
    --               INTRFACE.Make_Field_Entrable('IMPORTERS.CITY_CODE_OF_ID' , FALSE);
    --               SET_ITEM_PROPERTY('IMPORTERS.CITY_CODE_OF_ID2' , ENABLED , PROPERTY_FALSE);
    --       END IF;
    --       IF :IMPORTERS.CTRY_CD IS NOT NULL THEN
    --           SELECT CRTY_ARBC_NAME
    --           INTO :CRTY_ARBC_NAME
    --           FROM COUNTRIES
    --           WHERE CTRY_CD = :IMPORTERS.CTRY_CD;
    --       END IF;
    --       IF :IMPORTERS.ADD_CTRY_CD IS NOT NULL THEN
    --           SELECT CRTY_ARBC_NAME
    --           INTO :ADD_CRTY_ARBC_NAME
    --           FROM COUNTRIES
    --           WHERE CTRY_CD = :IMPORTERS.ADD_CTRY_CD;
    --       END IF;
    --   END IF;
    --   CHECK_BUS_ID;
    --   END;
    --   BEGIN
    --     IF (name_in('IMPORTERS.IMPR_TYPE_CD') IS NOT NULL AND name_in('IMPORTERS.BUS_ID_TYPE_CD') IS NOT NULL) THEN
    --       BEGIN
    --         CGFK$CHK_IMPORTERS_IMP_ITIDT_F(
    --           :IMPORTERS.BUS_ID_TYPE_NAME
    --          ,:IMPORTERS.IMPR_TYPE_NAME
    --          ,:IMPORTERS.STATUS
    --          ,:IMPORTERS.ITIDT_NOTE
    --          ,:IMPORTERS.IMPR_TYPE_CD
    --          ,:IMPORTERS.BUS_ID_TYPE_CD  );
    --       EXCEPTION
    --         WHEN NO_DATA_FOUND THEN
    --           Des$Form_errors.PUSH('رمز النشاط التجاري غير صحيح - أعد إدخال البيانات', 'E', 'OFG', 0);
    --           Des$Form_errors.RAISE_FAILURE;
    --         WHEN OTHERS THEN
    --           CGTE$OTHER_EXCEPTIONS;
    --       END;
    --     END IF;
    --   END;
    -- <<<
    PROCEDURE impr_type_cd_wvi (p_rec IN OUT NOCOPY t_rec, p_ctx IN t_ctx)
    IS
        impr_seq             VARCHAR2(6);
        bus_id_count         NUMBER;
        v_count              NUMBER;
        v_count_impr_type_cd NUMBER;
    BEGIN
        IF p_rec.impr_nbr IS NOT NULL THEN
            IF NVL(p_rec.impr_type_cd, 0) NOT IN (4, 9)
               AND p_rec.impr_nbr > TO_NUMBER(NVL(gnrl.get_customs_setting('CREATE_IMPR_NBR', 9), 5000000)) THEN
                disp_arb_ftf(9, 332);
            END IF;
        ELSE
            IF NVL(p_rec.impr_type_cd, 0) NOT IN (4, 9) THEN
                disp_arb_ftf(9, 332);
            END IF;
        END IF;

        IF NVL(gnrl.get_customs_setting('STOP_IMPR_CR_TYPE', 9), 0) = 1 THEN
            SELECT COUNT(*) INTO v_count_impr_type_cd
              FROM impr_type_id_types
             WHERE impr_type_cd   = p_rec.impr_type_cd
               AND bus_id_type_cd = 2
               AND status         = 1;
            IF v_count_impr_type_cd > 0 THEN
                disp_arb_ftf(9, 331);
            END IF;
        END IF;

        IF g_get('VALID') = '0' THEN
            IF p_rec.impr_type_cd IS NOT NULL THEN
                SELECT COUNT(*)
                  INTO bus_id_count
                  FROM impr_type_id_types
                 WHERE impr_type_cd = p_rec.impr_type_cd
                   AND status = 1;
                IF bus_id_count = 1 THEN
                    SELECT it.bus_id_type_cd, idt.bus_id_type_name
                      INTO p_rec.bus_id_type_cd, p_rec.bus_id_type_name
                      FROM impr_type_id_types it, bus_id_types idt
                     WHERE it.impr_type_cd   = p_rec.impr_type_cd
                       AND it.status         = 1
                       AND it.bus_id_type_cd = idt.bus_id_type_cd;
                ELSIF bus_id_count > 1 THEN
                    ui('IMPR_TYPE_CD', 'OPEN_LOV', TRUE);      -- DO_KEY('LIST_VALUES')
                ELSE
                    p_rec.impr_type_cd := NULL;
                    disp_arb_ftf(2, 170);
                END IF;
            END IF;
        END IF;
        g_set('VALID', '0');
        IF p_rec.impr_type_cd IS NOT NULL THEN
            SELECT impr_type_name
              INTO p_rec.impr_type_name
              FROM impr_types
             WHERE impr_type_cd = p_rec.impr_type_cd;
        END IF;

        IF g_get('FUNS_IMP') = '0' THEN
            IF p_rec.bus_id_type_cd = 2 AND p_rec.impr_type_cd != 12 THEN
                entrable('COMM_RGSTRTN_TYPE', TRUE);
                ui('COMM_RGSTRTN_TYPE', 'REQUIRED', TRUE);
            ELSE
                entrable('COMM_RGSTRTN_TYPE', FALSE);
                ui('COMM_RGSTRTN_TYPE', 'REQUIRED', FALSE);
            END IF;
            IF p_rec.impr_type_cd IN (1, 2, 5, 8, 11) THEN
                p_rec.ctry_cd     := 100;
                p_rec.add_ctry_cd := 100;
            ELSIF p_rec.impr_type_cd = 4 THEN
                IF p_rec.bus_id_type_cd = 5 THEN
                    p_rec.ctry_cd     := 100;
                    p_rec.add_ctry_cd := 100;
                END IF;
            ELSIF p_rec.impr_type_cd = 9 THEN
                p_rec.ctry_cd     := 100;
                p_rec.add_ctry_cd := 100;
                IF p_rec.bus_id_type_cd IS NULL THEN
                    p_rec.bus_id_type_cd := 6;
                END IF;
                IF p_rec.bus_id_type_cd = 6 THEN
                    SELECT LPAD(gnrl.get_sequence_value(p_ctx.curr_port_cd, 'KING_IMPR_SEQ'), 6, '0')
                      INTO impr_seq
                      FROM dual;
                    p_rec.bus_id := 'ملكى' || impr_seq;
                END IF;
            ELSIF p_rec.impr_type_cd = 12 THEN
                type_entrable_qry(p_rec);   -- Forms sets these before the check below can fail
                IF p_rec.ctry_cd IS NOT NULL THEN
                    SELECT COUNT(*)
                      INTO v_count
                      FROM ctry_group_details
                     WHERE ctry_cd       = p_rec.ctry_cd
                       AND ctry_grp_stat = 1
                       AND ctry_grp_nbr  = 1;
                    IF v_count = 0 THEN
                        ftf('لابد أن تكون دولة المستورد الخليجي تابعة لدول مجلس التعاون');
                    END IF;
                END IF;
            ELSIF p_rec.impr_type_cd IN (13, 14, 16, 17, 18, 20) THEN
                SELECT gnrl.get_sequence_value(p_ctx.curr_port_cd, 'IMPORTERS_SEQ')
                  INTO p_rec.bus_id
                  FROM dual;
                IF p_rec.bus_id IS NULL THEN
                    p_rec.bus_id := 1;
                END IF;
                p_rec.ctry_cd     := 100;
                p_rec.add_ctry_cd := 100;
            END IF;
            -- entrable state per type: identical to the POST-QUERY branches, except type 11
            -- (POST-QUERY same) and types 16/17/18/20 (only here) - handled below.
            IF p_rec.impr_type_cd IN (16, 17, 18, 20) THEN
                entrable('CTRY_CD', FALSE); entrable('ADD_CTRY_CD', FALSE);
                entrable('BUS_ID', FALSE); entrable('BUS_ID_BRNCH', FALSE);
                entrable('CITY_CODE_OF_ID', FALSE); ui('CITY_CODE_OF_ID2', 'ENABLED', FALSE);
            ELSE
                type_entrable_qry(p_rec);
            END IF;
            IF p_rec.ctry_cd IS NOT NULL THEN
                SELECT crty_arbc_name
                  INTO p_rec.crty_arbc_name
                  FROM countries
                 WHERE ctry_cd = p_rec.ctry_cd;
            END IF;
            IF p_rec.add_ctry_cd IS NOT NULL THEN
                SELECT crty_arbc_name
                  INTO p_rec.add_crty_arbc_name
                  FROM countries
                 WHERE ctry_cd = p_rec.add_ctry_cd;
            END IF;
        END IF;
        check_bus_id;

        -- CGFK$VALDIDATE_FK_OVF (CGFK$CHK_IMPORTERS_IMP_ITIDT_F)
        IF p_rec.impr_type_cd IS NOT NULL AND p_rec.bus_id_type_cd IS NOT NULL THEN
            BEGIN
                SELECT itidt.note, itidt.status, it.impr_type_name, bit.bus_id_type_name
                  INTO p_rec.itidt_note, p_rec.status, p_rec.impr_type_name, p_rec.bus_id_type_name
                  FROM impr_type_id_types itidt, impr_types it, bus_id_types bit
                 WHERE itidt.bus_id_type_cd = p_rec.bus_id_type_cd
                   AND itidt.impr_type_cd   = p_rec.impr_type_cd
                   AND it.impr_type_cd      = itidt.impr_type_cd
                   AND bit.bus_id_type_cd   = itidt.bus_id_type_cd
                   AND ROWNUM = 1;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    ftf('رمز النشاط التجاري غير صحيح - أعد إدخال البيانات');
            END;
        END IF;
    END impr_type_cd_wvi;

    -- Source: IMPORTERS.IMPR_TYPE_CD.POST-CHANGE
    --@ORIG IMPORTERS.IMPR_TYPE_CD.POST-CHANGE
    -- >>> Original Forms code: IMPORTERS.IMPR_TYPE_CD.POST-CHANGE
    --   BEGIN
    --   :GLOBAL.FLAGUPDATE := 1;
    --   IF :IMPR_TYPE_CD IN (1,3,5,6,8,19)
    --       THEN
    --        SET_ITEM_PROPERTY('CITY_CODE_OF_ID',REQUIRED,PROPERTY_TRUE);
    --   END IF ;
    --   END;
    -- <<<
    PROCEDURE impr_type_cd_post_chg (p_rec IN t_rec)
    IS
    BEGIN
        g_set('FLAGUPDATE', '1');
        IF p_rec.impr_type_cd IN (1, 3, 5, 6, 8, 19) THEN
            ui('CITY_CODE_OF_ID', 'REQUIRED', TRUE);
        END IF;
    END impr_type_cd_post_chg;

    -- Source: IMPORTERS.IMPR_TYPE_CD.WHEN-NEW-ITEM-INSTANCE
    -- First block (EXEC_QUERY_NOW = 1 -> Clear_Block + EXECUTE_QUERY) is navigation: the page
    -- re-queries when impr_nbr_wvi set EXEC_QUERY_NOW (see importers_pre_qry).
    --@ORIG IMPORTERS.IMPR_TYPE_CD.WHEN-NEW-ITEM-INSTANCE
    -- >>> Original Forms code: IMPORTERS.IMPR_TYPE_CD.WHEN-NEW-ITEM-INSTANCE
    --   BEGIN
    --   IF :global.Exec_Query_Now = 1 THEN
    --       Clear_Block(No_Validate);
    --       execute_query;
    --   END IF;
    --   END;
    --   DECLARE
    --   ret    NUMBER;
    --   BEGIN
    --   IF :IMPR_TYPE_CD = 4  AND  :BUS_ID_TYPE_CD = 3
    --   OR :IMPR_TYPE_CD = 4  AND  :BUS_ID_TYPE_CD = 5 THEN
    --   :CTRY_CD := 100;
    --   SET_ITEM_PROPERTY('CTRY_CD', ENABLED,PROPERTY_FALSE);
    --   SELECT CRTY_ARBC_NAME INTO :CRTY_ARBC_NAME
    --    FROM   COUNTRIES
    --    WHERE  CTRY_CD = 100;
    --   END IF;
    --   :ADD_CTRY_CD := 100 ;
    --   SET_ITEM_PROPERTY('ADD_CTRY_CD', ENABLED,PROPERTY_FALSE);
    --   SELECT CRTY_ARBC_NAME INTO :ADD_CRTY_ARBC_NAME
    --    FROM   COUNTRIES
    --    WHERE  CTRY_CD = 100;
    --   EXCEPTION
    --   WHEN NO_DATA_FOUND THEN
    --     ret := Str.DispArbMsg(18, 15,'ERROR');
    --     RAISE FORM_TRIGGER_FAILURE;
    --   END;
    -- <<<
    PROCEDURE impr_type_cd_wnii (p_rec IN OUT NOCOPY t_rec)
    IS
    BEGIN
        IF g_get('EXEC_QUERY_NOW') = '1' THEN
            ui('IMPORTERS', 'REQUERY', TRUE);
        END IF;
        ctry_100_defaults(p_rec);
    END impr_type_cd_wnii;

    -- Source: IMPORTERS.IMPR_TYPE_CD.KEY-LISTVAL, part after CALL_FORM('LOV_Impr_Type')
    -- (the LOV form returned :GLOBAL.IMPR_TYPE_CD/_NAME and BUS_ID_TYPE_CD/_NAME).
    -- p_rec already carries the returned values (NULL = nothing selected).
    PROCEDURE impr_type_cd_lov_ret (p_rec IN OUT NOCOPY t_rec)
    IS
    BEGIN
        IF p_rec.impr_type_cd IS NOT NULL THEN
            g_set('VALID', '1');
            ctry_100_defaults(p_rec);
        ELSE
            p_rec.impr_type_cd     := NULL;
            p_rec.impr_type_name   := NULL;
            p_rec.bus_id_type_cd   := NULL;
            p_rec.bus_id_type_name := NULL;
        END IF;
    END impr_type_cd_lov_ret;

    -- Source: IMPORTERS.BUS_ID_EXPRD_DT.WHEN-VALIDATE-ITEM
    --@ORIG IMPORTERS.BUS_ID_EXPRD_DT.WHEN-VALIDATE-ITEM
    -- >>> Original Forms code: IMPORTERS.BUS_ID_EXPRD_DT.WHEN-VALIDATE-ITEM
    --   DECLARE
    --       HDATE DATE;
    --   BEGIN
    --       IF :System.TRIGGER_ITEM = :System.CURSOR_ITEM THEN
    --           IF :System.Cursor_Value IS NOT NULL THEN
    --               HDATE := TO_DATE(:System.Cursor_Value);
    --               IF NOT HIJDATE.VALID_HIJ_DATE(HDATE) THEN
    --                   RAISE FORM_TRIGGER_FAILURE;
    --               END IF;
    --           END IF;
    --       END IF;
    --   END;
    --   DECLARE
    --    RET NUMBER;
    --   BEGIN
    --    IF :SYSTEM.TRIGGER_ITEM = :SYSTEM.CURSOR_ITEM THEN
    --       IF :BUS_ID_EXPRD_DT < HIJDATE.Cur_Hij_Date THEN
    --          RET := Str.DispArbMsg(1,10,'ERROR');
    --             RAISE FORM_TRIGGER_FAILURE;
    --       END IF;
    --    END IF;
    --   END;
    -- <<<
    PROCEDURE bus_id_exprd_dt_wvi (p_rec IN t_rec, p_from_item IN BOOLEAN DEFAULT TRUE)
    IS
    BEGIN
        IF p_from_item THEN
            IF p_rec.bus_id_exprd_dt IS NOT NULL THEN
                IF NOT valid_hij_date(p_rec.bus_id_exprd_dt) THEN
                    ftf;
                END IF;
            END IF;
        END IF;
        IF p_from_item THEN
            IF p_rec.bus_id_exprd_dt < cur_hij_date THEN
                disp_arb_ftf(1, 10);
            END IF;
        END IF;
    END bus_id_exprd_dt_wvi;

    -- Source: IMPORTERS.BUS_ID_TYPE_CD.POST-CHANGE
    -- SUGGESTION: Forms assigns the name of country 100 to ADD_CRTY_ARBC_NAME inside the IF and
    -- to CRTY_ARBC_NAME after it (swapped compared with the other copies of this block). Kept.
    --@ORIG IMPORTERS.BUS_ID_TYPE_CD.POST-CHANGE
    -- >>> Original Forms code: IMPORTERS.BUS_ID_TYPE_CD.POST-CHANGE
    --   BEGIN
    --   :GLOBAL.FLAGUPDATE := 1;
    --   DECLARE
    --   ret    NUMBER;
    --   BEGIN
    --   IF :IMPR_TYPE_CD = 4  AND  :BUS_ID_TYPE_CD = 3
    --   OR :IMPR_TYPE_CD = 4  AND  :BUS_ID_TYPE_CD = 5 THEN
    --   :CTRY_CD := 100;
    --   SET_ITEM_PROPERTY('CTRY_CD', ENABLED,PROPERTY_FALSE);
    --   SELECT CRTY_ARBC_NAME INTO :ADD_CRTY_ARBC_NAME
    --    FROM   COUNTRIES
    --    WHERE  CTRY_CD = 100;
    --   END IF;
    --   :ADD_CTRY_CD := 100 ;
    --   SET_ITEM_PROPERTY('ADD_CTRY_CD', ENABLED,PROPERTY_FALSE);
    --   SELECT CRTY_ARBC_NAME INTO :CRTY_ARBC_NAME
    --    FROM   COUNTRIES
    --    WHERE  CTRY_CD = 100;
    --   EXCEPTION
    --   WHEN NO_DATA_FOUND THEN
    --     ret := Str.DispArbMsg(18, 15,'ERROR');
    --     RAISE FORM_TRIGGER_FAILURE;
    --   END;
    --   END;
    -- <<<
    PROCEDURE bus_id_type_post_chg (p_rec IN OUT NOCOPY t_rec)
    IS
    BEGIN
        g_set('FLAGUPDATE', '1');
        BEGIN
            IF p_rec.impr_type_cd = 4 AND p_rec.bus_id_type_cd = 3
               OR p_rec.impr_type_cd = 4 AND p_rec.bus_id_type_cd = 5 THEN
                p_rec.ctry_cd := 100;
                ui('CTRY_CD', 'ENABLED', FALSE);
                SELECT crty_arbc_name INTO p_rec.add_crty_arbc_name
                  FROM countries
                 WHERE ctry_cd = 100;
            END IF;
            p_rec.add_ctry_cd := 100;
            ui('ADD_CTRY_CD', 'ENABLED', FALSE);
            SELECT crty_arbc_name INTO p_rec.crty_arbc_name
              FROM countries
             WHERE ctry_cd = 100;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                disp_arb_ftf(18, 15);
        END;
    END bus_id_type_post_chg;

    -- Source: IMPORTERS.COMM_RGSTRTN_TYPE.WHEN-LIST-CHANGED
    --@ORIG IMPORTERS.COMM_RGSTRTN_TYPE.WHEN-LIST-CHANGED
    -- >>> Original Forms code: IMPORTERS.COMM_RGSTRTN_TYPE.WHEN-LIST-CHANGED
    --   BEGIN
    --   IF :IMPORTERS.COMM_RGSTRTN_TYPE = 1 THEN
    --         :IMPORTERS.BUS_ID_BRNCH := NULL;
    --   INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_BRNCH' , FALSE);
    --   INTRFACE.Make_Field_Entrable('BRNH_CITY_CD',FALSE);
    --         SET_ITEM_PROPERTY('BRNH_CITY_CD',REQUIRED,PROPERTY_FALSE);
    --         SET_ITEM_PROPERTY('IMPORTERS.BUS_ID_BRNCH',ITEM_IS_VALID,PROPERTY_TRUE);
    --    ELSIF :IMPORTERS.COMM_RGSTRTN_TYPE = 2 THEN
    --         SET_ITEM_PROPERTY('BRNH_CITY_CD',REQUIRED,PROPERTY_true);
    --         INTRFACE.Make_Field_Entrable('BRNH_CITY_CD',TRUE);
    --         INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_BRNCH' , TRUE);
    --         SET_ITEM_PROPERTY('IMPORTERS.BUS_ID_BRNCH',ITEM_IS_VALID,PROPERTY_FALSE);
    --   END IF;
    --   END;
    -- <<<
    PROCEDURE comm_rgstrtn_wlc (p_rec IN OUT NOCOPY t_rec)
    IS
    BEGIN
        IF p_rec.comm_rgstrtn_type = 1 THEN
            p_rec.bus_id_brnch := NULL;
            entrable('BUS_ID_BRNCH', FALSE);
            entrable('BRNH_CITY_CD', FALSE);
            ui('BRNH_CITY_CD', 'REQUIRED', FALSE);
            ui('BUS_ID_BRNCH', 'VALID', TRUE);
        ELSIF p_rec.comm_rgstrtn_type = 2 THEN
            ui('BRNH_CITY_CD', 'REQUIRED', TRUE);
            entrable('BRNH_CITY_CD', TRUE);
            entrable('BUS_ID_BRNCH', TRUE);
            ui('BUS_ID_BRNCH', 'VALID', FALSE);
        END IF;
    END comm_rgstrtn_wlc;

    -- Source: IMPORTERS.CTRY_CD_OF_ID.WHEN-VALIDATE-ITEM (CGFK$WVI_CLR_DEPS_OVF)
    --@ORIG IMPORTERS.CTRY_CD_OF_ID.WHEN-VALIDATE-ITEM
    -- >>> Original Forms code: IMPORTERS.CTRY_CD_OF_ID.WHEN-VALIDATE-ITEM
    --   BEGIN
    --     IF (name_in('IMPORTERS.CITY_CODE_OF_ID') IS NULL AND name_in('IMPORTERS.CTRY_CD_OF_ID') IS NULL) THEN
    --       IF (:SYSTEM.RECORD_STATUS = 'NEW') THEN
    --         RETURN;
    --       END IF;
    --       BEGIN
    --         CGSF$CLRLU_IMPORTERS_IMP_BUS_I;
    --       EXCEPTION
    --         WHEN OTHERS THEN
    --           CGTE$OTHER_EXCEPTIONS;
    --       END;
    --     END IF;
    --   END;
    -- <<<
    PROCEDURE ctry_cd_of_id_wvi (p_rec IN OUT NOCOPY t_rec)
    IS
    BEGIN
        IF p_rec.city_code_of_id IS NULL AND p_rec.ctry_cd_of_id IS NULL THEN
            IF p_rec.rec_status = 'NEW' THEN
                RETURN;
            END IF;
            cgsf_clrlu_bus_i(p_rec);
        END IF;
    END ctry_cd_of_id_wvi;

    -- Source: IMPORTERS.CITY_CODE_OF_ID.WHEN-VALIDATE-ITEM
    --@ORIG IMPORTERS.CITY_CODE_OF_ID.WHEN-VALIDATE-ITEM
    -- >>> Original Forms code: IMPORTERS.CITY_CODE_OF_ID.WHEN-VALIDATE-ITEM
    --   DECLARE
    --   V_BUS_ID VARCHAR2(6);
    --   V_ALL_BUS_ID VARCHAR2(10);
    --   V_ID_MINS_COMM_CD VARCHAR2(4);
    --   V_USER_BUS_ID VARCHAR2(4);
    --   Alert_txt   VARCHAR2(80);
    --   al_button NUMBER;
    --   SYS_ID NUMBER;
    --   MSG_CD NUMBER;
    --   RET NUMBER;
    --   BEGIN
    --                       BEGIN
    --                          SELECT city_arb_name
    --                            INTO :importers.id_city_name
    --                            FROM cities
    --                           WHERE city_cd = :city_code_of_id AND ctry_cd = :ctry_cd_of_id;
    --                       EXCEPTION
    --                          WHEN OTHERS THEN NULL;
    --                       END;
    --   END;
    --   BEGIN
    --     IF (name_in('IMPORTERS.CITY_CODE_OF_ID') IS NULL AND name_in('IMPORTERS.CTRY_CD_OF_ID') IS NULL) THEN
    --       IF (:SYSTEM.RECORD_STATUS = 'NEW') THEN
    --         RETURN;
    --       END IF;
    --       BEGIN
    --         CGSF$CLRLU_IMPORTERS_IMP_BUS_I;
    --       EXCEPTION
    --         WHEN OTHERS THEN
    --           CGTE$OTHER_EXCEPTIONS;
    --       END;
    --     END IF;
    --   END;
    --   BEGIN
    --     IF (name_in('IMPORTERS.CITY_CODE_OF_ID') IS NOT NULL AND name_in('IMPORTERS.CTRY_CD_OF_ID') IS NOT NULL) THEN
    --       BEGIN
    --         CGFK$CHK_IMPORTERS_IMP_BUS_ID_(
    --           :IMPORTERS.ID_MINS_COMM_CD
    --          ,:IMPORTERS.ID_CITY_NAME
    --          ,:IMPORTERS.L_CT_CITY_STATUS2
    --          ,:IMPORTERS.CTRY_CD_OF_ID
    --          ,:IMPORTERS.CITY_CODE_OF_ID  );
    --       EXCEPTION
    --         WHEN NO_DATA_FOUND THEN
    --           Des$Form_errors.PUSH('خطأ في رمز مدينة مصدر الرقم الإستدلالي', 'W', 'OFG', 0);
    --         WHEN OTHERS THEN
    --           CGTE$OTHER_EXCEPTIONS;
    --       END;
    --     END IF;
    --   END;
    -- <<<
    PROCEDURE city_code_of_id_wvi (p_rec IN OUT NOCOPY t_rec)
    IS
    BEGIN
        BEGIN
            SELECT city_arb_name
              INTO p_rec.id_city_name
              FROM cities
             WHERE city_cd = p_rec.city_code_of_id
               AND ctry_cd = p_rec.ctry_cd_of_id;
        EXCEPTION
            WHEN OTHERS THEN
                NULL;
        END;
        -- CGFK$WVI_CLR_DEPS_OVF
        IF p_rec.city_code_of_id IS NULL AND p_rec.ctry_cd_of_id IS NULL THEN
            IF p_rec.rec_status = 'NEW' THEN
                RETURN;
            END IF;
            cgsf_clrlu_bus_i(p_rec);
        END IF;
        -- CGFK$VALDIDATE_FK_OVF (CGFK$CHK_IMPORTERS_IMP_BUS_ID_) - warning only ('W', no failure)
        IF p_rec.city_code_of_id IS NOT NULL AND p_rec.ctry_cd_of_id IS NOT NULL THEN
            BEGIN
                SELECT id_city.city_status, id_city.city_arb_name, id_city.mins_comm_cd
                  INTO p_rec.l_ct_city_status2, p_rec.id_city_name, p_rec.id_mins_comm_cd
                  FROM cities id_city
                 WHERE id_city.city_cd = p_rec.city_code_of_id
                   AND id_city.ctry_cd = p_rec.ctry_cd_of_id
                   AND id_city.city_status = 1
                   AND ROWNUM = 1;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    info('خطأ في رمز مدينة مصدر الرقم الإستدلالي');
            END;
        END IF;
    END city_code_of_id_wvi;

    -- Source: IMPORTERS.CITY_CODE_OF_ID.WHEN-NEW-ITEM-INSTANCE
    PROCEDURE city_code_of_id_wnii (p_rec IN t_rec)
    IS
    BEGIN
        IF p_rec.comm_rgstrtn_type = 2 THEN
            ui('BRNH_CITY_CD', 'REQUIRED', TRUE);
            ui('BRNH_CITY_CD', 'VALID', FALSE);
        END IF;
    END city_code_of_id_wnii;

    -- Suspended importer with the same BUS_ID (the WARNING inside bus_id_wvi). 0 = no warning.
    FUNCTION bus_id_susp_impr (p_rec IN t_rec) RETURN NUMBER
    IS
        v_count    NUMBER;
        v_impr_nbr NUMBER;
        v_hijdt    DATE;
    BEGIN
        IF (p_rec.bus_id_brnch IS NULL) AND (p_rec.comm_rgstrtn_type = 1 OR p_rec.comm_rgstrtn_type IS NULL) THEN
            v_hijdt := cur_hij_date;
            SELECT COUNT(*) INTO v_count
              FROM importers
             WHERE port_cd        = p_rec.port_cd
               AND ctry_cd        = NVL(p_rec.ctry_cd, ctry_cd)
               AND bus_id_type_cd = p_rec.bus_id_type_cd
               AND bus_id         = p_rec.bus_id
               AND bus_id_brnch IS NULL
               AND ((p_rec.impr_nbr IS NULL) OR (p_rec.impr_nbr IS NOT NULL AND impr_nbr <> p_rec.impr_nbr));
            IF v_count > 0 THEN
                SELECT NVL(MAX(impr_nbr), 0) INTO v_impr_nbr
                  FROM importers
                 WHERE port_cd        = p_rec.port_cd
                   AND ctry_cd        = NVL(p_rec.ctry_cd, ctry_cd)
                   AND bus_id_type_cd = p_rec.bus_id_type_cd
                   AND bus_id         = p_rec.bus_id
                   AND bus_id_brnch IS NULL
                   AND ((p_rec.impr_nbr IS NULL) OR (p_rec.impr_nbr IS NOT NULL AND impr_nbr <> p_rec.impr_nbr))
                   AND lib_usr.impr.impr_suspended(p_rec.port_cd, impr_nbr, v_hijdt) <> 1;
                IF v_impr_nbr = 0 THEN
                    SELECT NVL(MAX(impr_nbr), 0) INTO v_impr_nbr
                      FROM importers
                     WHERE port_cd        = p_rec.port_cd
                       AND ctry_cd        = NVL(p_rec.ctry_cd, ctry_cd)
                       AND bus_id_type_cd = p_rec.bus_id_type_cd
                       AND bus_id         = p_rec.bus_id
                       AND bus_id_brnch IS NULL
                       AND ((p_rec.impr_nbr IS NULL) OR (p_rec.impr_nbr IS NOT NULL AND impr_nbr <> p_rec.impr_nbr))
                       AND lib_usr.impr.impr_suspended(p_rec.port_cd, impr_nbr, v_hijdt) = 1;
                    RETURN v_impr_nbr;
                END IF;
            END IF;
        END IF;
        RETURN 0;
    END bus_id_susp_impr;

    -- Source: IMPORTERS.BUS_ID.WHEN-VALIDATE-ITEM
    -- p_cr_answer  : alert 9-120 ("prefix the city commercial code?") - ALERT_BUTTON1 = c_yes.
    --                Shown as an 'ERROR' alert (normally a single OK button) -> default c_yes.
    -- p_susp_answer: WARNING "يوجد مستورد ... موقوف ..." (text: see bus_id_susp_impr) - c_no clears BUS_ID.
    --@ORIG IMPORTERS.BUS_ID.WHEN-VALIDATE-ITEM
    -- >>> Original Forms code: IMPORTERS.BUS_ID.WHEN-VALIDATE-ITEM
    --   BEGIN
    --   CHK_IMPR_DUPL;
    --   DECLARE
    --   V_BUS_ID VARCHAR2(6);
    --   V_ALL_BUS_ID VARCHAR2(10);
    --   V_ID_MINS_COMM_CD VARCHAR2(4);
    --   V_USER_BUS_ID VARCHAR2(4);
    --   V_COUNT NUMBER;
    --   Alert_txt   VARCHAR2(100);
    --   al_button NUMBER;
    --   SYS_ID NUMBER;
    --   MSG_CD NUMBER;
    --   V_IMPR_NBR NUMBER;
    --   V_HIJDT DATE;
    --     V_CNT NUMBER;
    --     RET NUMBER;
    --     V_RET VARCHAR2(5);
    --   BEGIN
    --   IF (:IMPR_TYPE_CD in (1,3,5,6,8,19)  and LENGTH(:IMPORTERS.BUS_ID) != 10)
    --       THEN
    --              STR.DISPALERT(' يجب أن يكون الرقم الاستدلالي مكونا من عشرة ارقام ','ERROR');
    --                  RAISE FORM_TRIGGER_FAILURE;
    --         END IF;
    --     IF :BUS_ID_TYPE_CD IN( 5,3) AND :IMPR_TYPE_CD = 4 THEN
    --         :IMPORTERS.BUS_ID := LTRIM(RTRIM(:IMPORTERS.BUS_ID));
    --         IF LENGTH(:IMPORTERS.BUS_ID) != 10 THEN
    --              STR.DISPALERT(' يجب أن يكون الرقم الاستدلالي مكونا من عشرة ارقام ','ERROR');
    --                  RAISE FORM_TRIGGER_FAILURE;
    --         END IF;
    --         IF IS_Digit(:BUS_ID)= FALSE THEN
    --               RET := Str.DispArbMsg(9, 270,'ERROR');
    --                  RAISE FORM_TRIGGER_FAILURE;
    --         END IF;
    --     END IF;
    --     IF :IMPORTERS.BUS_ID_TYPE_CD = 2 AND :IMPORTERS.IMPR_TYPE_CD != 12  THEN
    --            IF IS_Digit(:BUS_ID)= FALSE THEN
    --               RET := Str.DispArbMsg(9, 270,'ERROR');
    --                  RAISE FORM_TRIGGER_FAILURE;
    --            END IF;
    --           IF NOT (LENGTH(:IMPORTERS.BUS_ID) <= 6 OR LENGTH(:IMPORTERS.BUS_ID) = 10) THEN
    --                   RET := Str.DispArbMsg(9, 260,'ERROR');
    --                   RAISE FORM_TRIGGER_FAILURE;
    --             END IF;
    --          IF :IMPORTERS.CITY_CODE_OF_ID IS NOT NULL THEN
    --               IF LENGTH(:IMPORTERS.BUS_ID) <= 6 THEN
    --               SELECT LPAD(:IMPORTERS.BUS_ID, 6,'0') INTO V_BUS_ID FROM dual;
    --               SELECT MINS_COMM_CD
    --               INTO :IMPORTERS.ID_MINS_COMM_CD
    --               FROM CITIES
    --               WHERE  CITY_CD = :IMPORTERS.CITY_CODE_OF_ID
    --               AND     CTRY_CD = :IMPORTERS.CTRY_CD_OF_ID;
    --               SELECT LPAD(TO_CHAR(:IMPORTERS.ID_MINS_COMM_CD), 4,'0') INTO V_ID_MINS_COMM_CD FROM dual;
    --               V_ALL_BUS_ID := CONCAT(V_ID_MINS_COMM_CD,V_BUS_ID);
    --               SYS_ID := 9;
    --               MSG_CD := 120;
    --               Alert_txt := STR_DB.GetArbMsg(SYS_ID, MSG_CD);
    --               IF Alert_txt = '-1' THEN
    --                     Alert_txt :='خطأ فى رقم الرسالة  '||sys_Id||'-'||Msg_Cd||'إتصل بالمسانده الفنيه';
    --                   al_button := STR.DispAlert(Alert_Txt, 'ERROR');
    --               ELSE
    --                   Alert_Txt :=sys_Id||'-'||Msg_Cd||' : '||Alert_Txt||' '||V_ALL_BUS_ID;
    --                   al_button := STR.DispAlert(Alert_Txt, 'ERROR');
    --                   IF al_button = alert_button1 THEN
    --                       :importers.BUS_ID := V_ALL_BUS_ID;
    --                   ELSIF al_button = alert_button2 THEN
    --                       RAISE Form_trigger_failure;
    --                   END IF;
    --                END IF;
    --             ELSIF LENGTH(:IMPORTERS.BUS_ID) = 10 THEN
    --               V_USER_BUS_ID := SUBSTR(:IMPORTERS.BUS_ID, 1, 4);
    --               IF TO_NUMBER(V_USER_BUS_ID) <> :IMPORTERS.ID_MINS_COMM_CD THEN
    --                   al_button := STR.DispArbMsg(9, 130, 'ERROR');
    --                   RAISE Form_trigger_failure;
    --               END IF;
    --           END IF;
    --          END IF;
    --        END IF;
    --        IF (:BUS_ID_BRNCH IS NULL) AND (:COMM_RGSTRTN_TYPE = 1 OR :COMM_RGSTRTN_TYPE IS NULL) THEN
    --       V_HIJDT :=HIJDATE.Cur_Hij_Date;
    --           SELECT COUNT(*) INTO V_COUNT
    --           FROM IMPORTERS
    --           WHERE PORT_CD = :IMPORTERS.PORT_CD
    --           AND    CTRY_CD = NVL(:IMPORTERS.CTRY_CD, CTRY_CD)
    --           AND    BUS_ID_TYPE_CD = :IMPORTERS.BUS_ID_TYPE_CD
    --           AND     BUS_ID  = :IMPORTERS.BUS_ID
    --           AND     BUS_ID_BRNCH IS NULL
    --           AND    ((:IMPORTERS.IMPR_NBR IS NULL) OR (:IMPORTERS.IMPR_NBR IS NOT NULL AND IMPR_NBR <> :IMPORTERS.IMPR_NBR));
    --           IF V_COUNT > 0 THEN
    --               SELECT NVL(MAX(IMPR_NBR),0)
    --               INTO     V_IMPR_NBR
    --               FROM   IMPORTERS
    --               WHERE  PORT_CD        = :IMPORTERS.PORT_CD
    --               AND     CTRY_CD        = NVL(:IMPORTERS.CTRY_CD, CTRY_CD)
    --               AND     BUS_ID_TYPE_CD = :IMPORTERS.BUS_ID_TYPE_CD
    --               AND       BUS_ID         = :IMPORTERS.BUS_ID
    --               AND      BUS_ID_BRNCH IS NULL
    --               AND     ((:IMPORTERS.IMPR_NBR IS NULL) OR (:IMPORTERS.IMPR_NBR IS NOT NULL AND IMPR_NBR <> :IMPORTERS.IMPR_NBR))
    --               AND    LIB_USR.IMPR.Impr_Suspended(:IMPORTERS.PORT_CD, IMPR_NBR, V_HIJDT) <> 1    ;
    --               IF V_IMPR_NBR <> 0 THEN
    --                   STR.DISPALERT(' لا يمكن تكرار الرقم الإستدلالي - الرقم الإستدلالي مستخدم لمستورد آخر مسلسله بالجمرك رقم : '||V_IMPR_NBR,'ERROR');
    --                   RAISE FORM_TRIGGER_FAILURE;
    --               ELSE
    --                   SELECT NVL(MAX(IMPR_NBR),0)
    --                   INTO     V_IMPR_NBR
    --                   FROM   IMPORTERS
    --                   WHERE  PORT_CD        = :IMPORTERS.PORT_CD
    --                   AND     CTRY_CD        = NVL(:IMPORTERS.CTRY_CD, CTRY_CD)
    --                   AND     BUS_ID_TYPE_CD = :IMPORTERS.BUS_ID_TYPE_CD
    --                   AND       BUS_ID         = :IMPORTERS.BUS_ID
    --                   AND      BUS_ID_BRNCH IS NULL
    --                   AND     ((:IMPORTERS.IMPR_NBR IS NULL) OR (:IMPORTERS.IMPR_NBR IS NOT NULL AND IMPR_NBR <> :IMPORTERS.IMPR_NBR))
    --                   AND    LIB_USR.IMPR.Impr_Suspended(:IMPORTERS.PORT_CD, IMPR_NBR, V_HIJDT) = 1    ;
    --                   RET := STR.DispAlert('يوجد مستورد'||V_IMPR_NBR||' موقوف له نفس الرقم الإستدلالي" هل تريد تعديل الرقم الاستدلالي بالرغم من ذلك ؟','WARNING');
    --                          IF RET = ALERT_BUTTON1 THEN
    --                           NULL;
    --                       ELSE
    --                           :BUS_ID := NULL;
    --                       END IF;
    --               END IF;
    --            END IF;
    --         END IF;
    --   IF :GLOBAL.FUNS_BUSID = 0 THEN
    --       IF :IMPORTERS.BUS_ID_TYPE_CD = 2 AND :IMPORTERS.IMPR_TYPE_CD != 12  THEN
    --         IF :COMM_RGSTRTN_TYPE = 1 THEN
    --               SELECT COUNT(BUS_ID) INTO V_CNT FROM COMM_IMPR_RGSTR
    --               WHERE  BUS_ID=:BUS_ID
    --                AND   BRNCHREG=0;
    --               IF V_CNT >1 THEN
    --                   RET := Str.DispArbMsg(9, 290,'ERROR');
    --                   RAISE FORM_TRIGGER_FAILURE;
    --           ELSIF V_CNT = 1 THEN
    --                  SELECT ARBC_IMPR_NAME,ARBC_NAME_STD,BUS_ID_EXPRD_DT,IMPR_TEL_NBR,IMPR_POB_NBR,IMPR_ZIP_CD,IMPR_FAX_NBR,IMPR_TELEX_NBR,ACTIVITY
    --                  INTO:ARBC_IMPR_NAME,:IMPR_NAME_STD,:BUS_ID_EXPRD_DT,:IMPR_TEL_NBR,:IMPR_POB_NBR,:IMPR_ZIP_CD,:IMPR_FAX_NBR,:IMPR_TELEX_NBR,:ACTIVITY
    --                  FROM COMM_IMPR_RGSTR
    --                  WHERE BUS_ID   =:BUS_ID
    --                  AND   BRNCHREG =0;
    --                  INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_EXPRD_DT' , FALSE);
    --                  INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_POB_NBR' , FALSE);
    --               INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_ZIP_CD' , FALSE);
    --              INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_TEL_NBR' , FALSE);
    --              INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_FAX_NBR' , FALSE);
    --              INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_TELEX_NBR' , FALSE);
    --              INTRFACE.Make_Field_Entrable('IMPORTERS.ARBC_IMPR_NAME' , FALSE);
    --              INTRFACE.Make_Field_Entrable('IMPORTERS.ACTIVITY' , FALSE);
    --                ELSE
    --                   V_RET := LIB_USR.GNRL.GET_CUSTOMS_SETTING('COMM_TABLE_UNCHECK',9);
    --                    IF NVL(V_RET,0) = 0 THEN
    --                      ret := Str.DispArbMsg(9, 190,'ERROR');
    --                    RAISE FORM_TRIGGER_FAILURE;
    --                  ELSE
    --                 INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_EXPRD_DT' , TRUE);
    --                       INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_POB_NBR' , TRUE);
    --                  INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_ZIP_CD' , TRUE);
    --                 INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_TEL_NBR' , TRUE);
    --                 INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_FAX_NBR' , TRUE);
    --                 INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_TELEX_NBR' , TRUE);
    --                 INTRFACE.Make_Field_Entrable('IMPORTERS.ARBC_IMPR_NAME' , TRUE);
    --                 INTRFACE.Make_Field_Entrable('IMPORTERS.ACTIVITY' , TRUE);
    --                     END IF;
    --                END IF;
    --           END IF;
    --   ELSE
    --       INTRFACE.Make_Field_Entrable('IMPORTERS.ACTIVITY' , TRUE);
    --        END IF;
    --    END IF;
    --   IF :BUS_ID IS NOT NULL AND :ACTIVITY IS NULL THEN
    --       INTRFACE.Make_Field_Entrable('IMPORTERS.ACTIVITY' , TRUE);
    --   ELSE
    --       INTRFACE.Make_Field_Entrable('IMPORTERS.ACTIVITY' , FALSE);
    --   END IF;
    --   CHECK_BUS_ID ;
    --   IF :IMPR_TYPE_CD=4 AND :BUS_ID_TYPE_CD=5 THEN
    --   :B_ID_NBR:=:BUS_ID;
    --   SET_ITEM_PROPERTY('B_ID_NBR',ENABLED,PROPERTY_FALSE);
    --   ELSE
    --   SET_ITEM_PROPERTY('B_ID_NBR',ENABLED,PROPERTY_TRUE);
    --   END IF;
    --   IF :IMPR_TYPE_CD=4 AND :BUS_ID_TYPE_CD IN(5,3) THEN
    --       IF  NOT CHECK_IDNO(:BUS_ID)THEN
    --           STR.DISPALERT('رقم الهوية المدخل غير صحيح.. يجب إدخال رقم هوية صحيح','ERROR');
    --           RAISE FORM_TRIGGER_FAILURE;
    --       END IF;
    --   END IF;
    --   END;
    --   BEGIN
    --      IF     GET_RECORD_PROPERTY (:SYSTEM.cursor_record,:SYSTEM.cursor_block,status) IN ('NEW', 'INSERT') AND
    --           :importers.IMPR_TYPE_CD IN ( 1,3,5,6,19 ) AND :importers.bus_id_type_cd = 2
    --            AND :GLOBAL.ALLOW_MCI = 1
    --      THEN
    --         IF :importers.comm_rgstrtn_type = 1 AND :importers.bus_id IS NOT NULL THEN
    --            get_main_cr_data;
    --         ELSIF :importers.comm_rgstrtn_type = 2 AND :importers.bus_id_brnch IS NOT NULL THEN
    --            get_branch_cr_data;
    --         END IF;
    --      END IF;
    --   END;
    --   END;
    --   BEGIN
    --   chk_bus_id_brnch ;
    --   END;
    -- <<<
    PROCEDURE bus_id_wvi (p_rec         IN OUT NOCOPY t_rec,
                          p_ctx         IN t_ctx,
                          p_cr_answer   IN PLS_INTEGER DEFAULT c_yes,
                          p_susp_answer IN PLS_INTEGER DEFAULT c_yes)
    IS
        v_bus_id          VARCHAR2(6);
        v_all_bus_id      VARCHAR2(10);
        v_id_mins_comm_cd VARCHAR2(4);
        v_user_bus_id     VARCHAR2(4);
        v_count           NUMBER;
        alert_txt         VARCHAR2(100);  -- SUGGESTION: 100 as in Forms; a long 9-120 text raises ORA-06502
        v_impr_nbr        NUMBER;
        v_hijdt           DATE;
        v_cnt             NUMBER;
        v_ret             VARCHAR2(5);
    BEGIN
        chk_impr_dupl(p_rec);
        IF (p_rec.impr_type_cd IN (1, 3, 5, 6, 8, 19) AND LENGTH(p_rec.bus_id) != 10) THEN
            ftf(' يجب أن يكون الرقم الاستدلالي مكونا من عشرة ارقام ');
        END IF;
        IF p_rec.bus_id_type_cd IN (5, 3) AND p_rec.impr_type_cd = 4 THEN
            p_rec.bus_id := LTRIM(RTRIM(p_rec.bus_id));
            IF LENGTH(p_rec.bus_id) != 10 THEN
                ftf(' يجب أن يكون الرقم الاستدلالي مكونا من عشرة ارقام ');
            END IF;
            IF is_digit(p_rec.bus_id) = FALSE THEN
                disp_arb_ftf(9, 270);
            END IF;
        END IF;
        IF p_rec.bus_id_type_cd = 2 AND p_rec.impr_type_cd != 12 THEN
            IF is_digit(p_rec.bus_id) = FALSE THEN
                disp_arb_ftf(9, 270);
            END IF;
            IF NOT (LENGTH(p_rec.bus_id) <= 6 OR LENGTH(p_rec.bus_id) = 10) THEN
                disp_arb_ftf(9, 260);
            END IF;
            IF p_rec.city_code_of_id IS NOT NULL THEN
                IF LENGTH(p_rec.bus_id) <= 6 THEN
                    v_bus_id := LPAD(p_rec.bus_id, 6, '0');
                    SELECT mins_comm_cd
                      INTO p_rec.id_mins_comm_cd
                      FROM cities
                     WHERE city_cd = p_rec.city_code_of_id
                       AND ctry_cd = p_rec.ctry_cd_of_id;
                    v_id_mins_comm_cd := LPAD(TO_CHAR(p_rec.id_mins_comm_cd), 4, '0');
                    v_all_bus_id := CONCAT(v_id_mins_comm_cd, v_bus_id);
                    alert_txt := str_db.getarbmsg(9, 120);
                    IF alert_txt = '-1' THEN
                        alert_txt := 'خطأ فى رقم الرسالة  ' || 9 || '-' || 120 || 'إتصل بالمسانده الفنيه';
                        info(alert_txt);
                    ELSE
                        alert_txt := 9 || '-' || 120 || ' : ' || alert_txt || ' ' || v_all_bus_id;
                        info(alert_txt);
                        IF p_cr_answer = c_yes THEN
                            p_rec.bus_id := v_all_bus_id;
                        ELSIF p_cr_answer = c_no THEN
                            ftf;
                        END IF;
                    END IF;
                ELSIF LENGTH(p_rec.bus_id) = 10 THEN
                    v_user_bus_id := SUBSTR(p_rec.bus_id, 1, 4);
                    IF TO_NUMBER(v_user_bus_id) <> p_rec.id_mins_comm_cd THEN
                        disp_arb_ftf(9, 130);
                    END IF;
                END IF;
            END IF;
        END IF;

        IF (p_rec.bus_id_brnch IS NULL) AND (p_rec.comm_rgstrtn_type = 1 OR p_rec.comm_rgstrtn_type IS NULL) THEN
            v_hijdt := cur_hij_date;
            SELECT COUNT(*) INTO v_count
              FROM importers
             WHERE port_cd        = p_rec.port_cd
               AND ctry_cd        = NVL(p_rec.ctry_cd, ctry_cd)
               AND bus_id_type_cd = p_rec.bus_id_type_cd
               AND bus_id         = p_rec.bus_id
               AND bus_id_brnch IS NULL
               AND ((p_rec.impr_nbr IS NULL) OR (p_rec.impr_nbr IS NOT NULL AND impr_nbr <> p_rec.impr_nbr));
            IF v_count > 0 THEN
                SELECT NVL(MAX(impr_nbr), 0)
                  INTO v_impr_nbr
                  FROM importers
                 WHERE port_cd        = p_rec.port_cd
                   AND ctry_cd        = NVL(p_rec.ctry_cd, ctry_cd)
                   AND bus_id_type_cd = p_rec.bus_id_type_cd
                   AND bus_id         = p_rec.bus_id
                   AND bus_id_brnch IS NULL
                   AND ((p_rec.impr_nbr IS NULL) OR (p_rec.impr_nbr IS NOT NULL AND impr_nbr <> p_rec.impr_nbr))
                   AND lib_usr.impr.impr_suspended(p_rec.port_cd, impr_nbr, v_hijdt) <> 1;
                IF v_impr_nbr <> 0 THEN
                    ftf(' لا يمكن تكرار الرقم الإستدلالي - الرقم الإستدلالي مستخدم لمستورد آخر مسلسله بالجمرك رقم : ' || v_impr_nbr);
                ELSE
                    -- WARNING 'يوجد مستورد'||V_IMPR_NBR||' موقوف له نفس الرقم الإستدلالي" هل تريد تعديل الرقم الاستدلالي بالرغم من ذلك ؟'
                    -- -> Confirm DA before this call (number from bus_id_susp_impr)
                    IF p_susp_answer = c_yes THEN
                        NULL;
                    ELSE
                        p_rec.bus_id := NULL;
                    END IF;
                END IF;
            END IF;
        END IF;

        IF g_get('FUNS_BUSID') = '0' THEN
            IF p_rec.bus_id_type_cd = 2 AND p_rec.impr_type_cd != 12 THEN
                IF p_rec.comm_rgstrtn_type = 1 THEN
                    SELECT COUNT(bus_id) INTO v_cnt
                      FROM comm_impr_rgstr
                     WHERE bus_id   = p_rec.bus_id
                       AND brnchreg = 0;
                    IF v_cnt > 1 THEN
                        disp_arb_ftf(9, 290);
                    ELSIF v_cnt = 1 THEN
                        SELECT arbc_impr_name, arbc_name_std, bus_id_exprd_dt, impr_tel_nbr, impr_pob_nbr,
                               impr_zip_cd, impr_fax_nbr, impr_telex_nbr, activity
                          INTO p_rec.arbc_impr_name, p_rec.impr_name_std, p_rec.bus_id_exprd_dt,
                               p_rec.impr_tel_nbr, p_rec.impr_pob_nbr, p_rec.impr_zip_cd,
                               p_rec.impr_fax_nbr, p_rec.impr_telex_nbr, p_rec.activity
                          FROM comm_impr_rgstr
                         WHERE bus_id   = p_rec.bus_id
                           AND brnchreg = 0;
                        cr_fields_entrable(FALSE, TRUE);
                    ELSE
                        v_ret := lib_usr.gnrl.get_customs_setting('COMM_TABLE_UNCHECK', 9);
                        IF NVL(v_ret, 0) = 0 THEN
                            disp_arb_ftf(9, 190);
                        ELSE
                            cr_fields_entrable(TRUE, TRUE);
                        END IF;
                    END IF;
                END IF;
            ELSE
                entrable('ACTIVITY', TRUE);
            END IF;
        END IF;
        IF p_rec.bus_id IS NOT NULL AND p_rec.activity IS NULL THEN
            entrable('ACTIVITY', TRUE);
        ELSE
            entrable('ACTIVITY', FALSE);
        END IF;
        check_bus_id;
        IF p_rec.impr_type_cd = 4 AND p_rec.bus_id_type_cd = 5 THEN
            p_rec.b_id_nbr := p_rec.bus_id;
            ui('B_ID_NBR', 'ENABLED', FALSE);
        ELSE
            ui('B_ID_NBR', 'ENABLED', TRUE);
        END IF;
        IF p_rec.impr_type_cd = 4 AND p_rec.bus_id_type_cd IN (5, 3) THEN
            IF NOT check_idno(p_rec.bus_id) THEN
                ftf('رقم الهوية المدخل غير صحيح.. يجب إدخال رقم هوية صحيح');
            END IF;
        END IF;

        IF p_rec.rec_status IN ('NEW', 'INSERT')
           AND p_rec.impr_type_cd IN (1, 3, 5, 6, 19) AND p_rec.bus_id_type_cd = 2
           AND g_get('ALLOW_MCI') = '1' THEN
            IF p_rec.comm_rgstrtn_type = 1 AND p_rec.bus_id IS NOT NULL THEN
                get_main_cr_data(p_rec);
            ELSIF p_rec.comm_rgstrtn_type = 2 AND p_rec.bus_id_brnch IS NOT NULL THEN
                get_branch_cr_data(p_rec);
            END IF;
        END IF;

        chk_bus_id_brnch(p_rec);
    END bus_id_wvi;

    -- Source: IMPORTERS.BUS_ID.POST-CHANGE
    PROCEDURE bus_id_post_chg
    IS
    BEGIN
        g_set('FLAGUPDATE', '1');
    END bus_id_post_chg;

    -- Source: IMPORTERS.BUS_ID.WHEN-NEW-ITEM-INSTANCE
    --@ORIG IMPORTERS.BUS_ID.WHEN-NEW-ITEM-INSTANCE
    -- >>> Original Forms code: IMPORTERS.BUS_ID.WHEN-NEW-ITEM-INSTANCE
    --   DECLARE
    --    RET NUMBER;
    --   BEGIN
    --    IF :IMPORTERS.BUS_ID_TYPE_CD = 2 AND :IMPORTERS.IMPR_TYPE_CD != 12  THEN
    --      IF :COMM_RGSTRTN_TYPE IS NULL THEN
    --        SET_ITEM_PROPERTY('BUS_ID',REQUIRED,PROPERTY_FALSE);
    --        RET:=Str.DispArbMsg(9, 240,'ERROR');
    --        GO_ITEM('COMM_RGSTRTN_TYPE');
    --      END IF;
    --      IF :COMM_RGSTRTN_TYPE = 2 THEN
    --         SET_ITEM_PROPERTY('BRNH_CITY_CD',REQUIRED,PROPERTY_TRUE);
    --         SET_ITEM_PROPERTY('BRNH_CITY_CD',ITEM_IS_VALID,PROPERTY_FALSE);
    --      END IF;
    --   END IF;
    --       IF :CITY_CODE_OF_ID IS NOT NULL AND (:GLOBAL.MINS_COMM_CD IS NOT NULL OR :ID_MINS_COMM_CD IS NOT NULL )
    --          AND :BUS_ID IS NULL THEN
    --           STR.DISPALERT('الرمز التجاري للمدينة المحددة :  '||NVL(:GLOBAL.MINS_COMM_CD,:ID_MINS_COMM_CD) ,'INFORMATION');
    --           :GLOBAL.MINS_COMM_CD := NULL ;
    --       END IF;
    --   END;
    -- <<<
    PROCEDURE bus_id_wnii (p_rec IN t_rec)
    IS
    BEGIN
        IF p_rec.bus_id_type_cd = 2 AND p_rec.impr_type_cd != 12 THEN
            IF p_rec.comm_rgstrtn_type IS NULL THEN
                ui('BUS_ID', 'REQUIRED', FALSE);
                disp_arb_info(9, 240);
                ui_focus('COMM_RGSTRTN_TYPE');
            END IF;
            IF p_rec.comm_rgstrtn_type = 2 THEN
                ui('BRNH_CITY_CD', 'REQUIRED', TRUE);
                ui('BRNH_CITY_CD', 'VALID', FALSE);
            END IF;
        END IF;
        IF p_rec.city_code_of_id IS NOT NULL
           AND (g_get('MINS_COMM_CD') IS NOT NULL OR p_rec.id_mins_comm_cd IS NOT NULL)
           AND p_rec.bus_id IS NULL THEN
            info('الرمز التجاري للمدينة المحددة :  ' || NVL(g_get('MINS_COMM_CD'), p_rec.id_mins_comm_cd));
            g_set('MINS_COMM_CD', NULL);
        END IF;
    END bus_id_wnii;

    -- Source: IMPORTERS.BRNH_CITY_CD.WHEN-VALIDATE-ITEM
    --@ORIG IMPORTERS.BRNH_CITY_CD.WHEN-VALIDATE-ITEM
    -- >>> Original Forms code: IMPORTERS.BRNH_CITY_CD.WHEN-VALIDATE-ITEM
    --   DECLARE
    --     RET NUMBER;
    --   BEGIN
    --    IF :BRNH_CITY_CD IS NOT NULL THEN
    --     SELECT CITY_ARB_NAME INTO :BRNH_CITY_NAME
    --     FROM   CITIES
    --     WHERE   CTRY_CD=:IMPORTERS.CTRY_CD_OF_ID
    --     AND     CITY_CD=:BRNH_CITY_CD;
    --    END IF;
    --   EXCEPTION
    --     WHEN NO_DATA_FOUND THEN
    --          RET := Str.DispArbMsg(1, 120,'ERROR');
    --          RAISE FORM_TRIGGER_FAILURE;
    --   END;
    -- <<<
    PROCEDURE brnh_city_cd_wvi (p_rec IN OUT NOCOPY t_rec)
    IS
    BEGIN
        IF p_rec.brnh_city_cd IS NOT NULL THEN
            SELECT city_arb_name INTO p_rec.brnh_city_name
              FROM cities
             WHERE ctry_cd = p_rec.ctry_cd_of_id
               AND city_cd = p_rec.brnh_city_cd;
        END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            disp_arb_ftf(1, 120);
    END brnh_city_cd_wvi;

    -- Source: IMPORTERS.BRNH_CITY_CD.WHEN-NEW-ITEM-INSTANCE
    PROCEDURE brnh_city_cd_wnii
    IS
    BEGIN
        ui('BRNH_CITY_CD', 'REQUIRED', FALSE);
        ui('BUS_ID_BRNCH', 'REQUIRED', TRUE);
        ui('BUS_ID_BRNCH', 'VALID', FALSE);
    END brnh_city_cd_wnii;

    -- Source: IMPORTERS.BUS_ID_BRNCH.WHEN-VALIDATE-ITEM
    -- p_cr_answer: alert 9-120 ("سيتم تحويل الرقم الفرعي إلى الرقم ...") - ALERT_BUTTON1 = c_yes.
    -- SUGGESTION: the 10-digit branch check tests LENGTH(:BUS_ID) (main number), not
    -- LENGTH(:BUS_ID_BRNCH) - kept as in Forms.
    --@ORIG IMPORTERS.BUS_ID_BRNCH.WHEN-VALIDATE-ITEM
    -- >>> Original Forms code: IMPORTERS.BUS_ID_BRNCH.WHEN-VALIDATE-ITEM
    --   BEGIN
    --   IF GET_ITEM_PROPERTY('IMPORTERS.BUS_ID_BRNCH',ENABLED)= 'TRUE' THEN
    --   DECLARE
    --   V_BUS_ID VARCHAR2(6);
    --   V_ALL_BUS_ID VARCHAR2(10);
    --   V_ID_MINS_COMM_CD VARCHAR2(4);
    --   V_USER_BUS_ID VARCHAR2(4);
    --   V_COUNT NUMBER;
    --   Alert_txt   VARCHAR2(100);
    --   al_button NUMBER;
    --   SYS_ID NUMBER;
    --   MSG_CD NUMBER;
    --   V_IMPR_NBR NUMBER;
    --     V_CNT NUMBER;
    --     RET NUMBER;
    --     V_RET VARCHAR2(5);
    --   BEGIN
    --    IF :BUS_ID_BRNCH = '0' THEN
    --          ret := Str.DispArbMsg(1, 220,'ERROR');
    --          RAISE FORM_TRIGGER_FAILURE;
    --    END IF;
    --    IF :IMPORTERS.BUS_ID_TYPE_CD = 2 AND :IMPORTERS.IMPR_TYPE_CD != 12  THEN
    --        BEGIN
    --         IF IS_Digit(:BUS_ID_BRNCH)= FALSE THEN
    --             RET := Str.DispArbMsg(9, 270,'ERROR');
    --             RAISE FORM_TRIGGER_FAILURE;
    --         END IF;
    --        END;
    --       IF NOT (LENGTH(:IMPORTERS.BUS_ID_BRNCH) = 6 OR LENGTH(:IMPORTERS.BUS_ID_BRNCH) = 10) THEN
    --              RET := Str.DispArbMsg(9,260,'ERROR');
    --              RAISE form_trigger_failure;
    --       END IF;
    --       IF :IMPORTERS.BRNH_CITY_CD IS NOT NULL THEN
    --                     SELECT MINS_COMM_CD
    --               INTO :BRNH_ID_MINS_COMM_CD
    --               FROM CITIES
    --               WHERE  CITY_CD = :IMPORTERS.BRNH_CITY_CD
    --               AND     CTRY_CD = :IMPORTERS.CTRY_CD;--=100
    --               SELECT LPAD(:IMPORTERS.BRNH_ID_MINS_COMM_CD, 4,'0') INTO V_ID_MINS_COMM_CD FROM dual;
    --                 IF LENGTH(:IMPORTERS.BUS_ID_BRNCH) = 6 THEN
    --                   V_ALL_BUS_ID := CONCAT(V_ID_MINS_COMM_CD,:IMPORTERS.BUS_ID_BRNCH);
    --                   SYS_ID := 9;
    --                   MSG_CD := 120;
    --                   Alert_txt := STR_DB.GetArbMsg(SYS_ID, MSG_CD);
    --                   IF Alert_txt = '-1' THEN
    --                         Alert_txt :='خطأ فى رقم الرسالة  '||sys_Id||'-'||Msg_Cd||'إتصل بالمسانده الفنيه';
    --                       al_button := STR.DispAlert(Alert_Txt, 'ERROR');
    --                   ELSE
    --                       Alert_Txt :='سيتم تحويل الرقم الفرعي إلى الرقم '||V_ALL_BUS_ID;
    --                       al_button := STR.DispAlert(Alert_Txt, 'ERROR');
    --                       IF al_button = alert_button1 THEN
    --                           :importers.BUS_ID_BRNCH := V_ALL_BUS_ID;
    --                       ELSIF al_button = alert_button2 THEN
    --                           RAISE Form_trigger_failure;
    --                       END IF;
    --                     END IF;
    --                  ELSIF LENGTH(:IMPORTERS.BUS_ID) = 10 THEN
    --                   V_USER_BUS_ID := SUBSTR(:IMPORTERS.BUS_ID_BRNCH, 1, 4);
    --                   IF TO_NUMBER(V_USER_BUS_ID) <> V_ID_MINS_COMM_CD THEN
    --                       al_button := STR.DispArbMsg(9, 130, 'ERROR');
    --                       RAISE Form_trigger_failure;
    --                   END IF;
    --               END IF;
    --         END IF;
    --    ELSE
    --         SET_ITEM_PROPERTY('BUS_ID_BRNCH',REQUIRED,PROPERTY_FALSE);
    --    END IF;
    --   END;
    --       CHK_IMPR_DUPL;
    --   IF :GLOBAL.FUNS_BUSID = 0 THEN
    --   DECLARE
    --     V_CNT NUMBER;
    --     RET   NUMBER;
    --     V_RET VARCHAR2(5);
    --   BEGIN
    --    IF :BUS_ID_TYPE_CD = 2 AND :IMPR_TYPE_CD!=12  THEN
    --     IF :COMM_RGSTRTN_TYPE = 2 THEN
    --        IF :BUS_ID IS NOT NULL AND :BUS_ID_BRNCH IS NOT NULL THEN
    --         SELECT COUNT(BUS_ID)INTO V_CNT    FROM COMM_IMPR_RGSTR
    --         WHERE  BUS_ID=:BUS_ID
    --          AND   BRNCH_BUS_ID=:BUS_ID_BRNCH;
    --            IF V_CNT >1 THEN
    --              RET := Str.DispArbMsg(9, 290,'ERROR');
    --            RAISE FORM_TRIGGER_FAILURE;
    --             ELSIF V_CNT = 1 THEN
    --             SELECT  ARBC_IMPR_NAME,ARBC_NAME_STD,BUS_ID_EXPRD_DT,
    --                      IMPR_TEL_NBR,IMPR_POB_NBR,IMPR_ZIP_CD,IMPR_FAX_NBR,IMPR_TELEX_NBR
    --               INTO   :ARBC_IMPR_NAME,:IMPR_NAME_STD,:BUS_ID_EXPRD_DT,:IMPR_TEL_NBR
    --                      ,:IMPR_POB_NBR,:IMPR_ZIP_CD,:IMPR_FAX_NBR,:IMPR_TELEX_NBR
    --                FROM  COMM_IMPR_RGSTR
    --            WHERE  BUS_ID=:BUS_ID
    --             AND   BRNCH_BUS_ID=:BUS_ID_BRNCH;
    --              INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_EXPRD_DT' , FALSE);
    --              INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_POB_NBR' , FALSE);
    --             INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_ZIP_CD' , FALSE);
    --            INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_TEL_NBR' , FALSE);
    --            INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_FAX_NBR' , FALSE);
    --            INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_TELEX_NBR' , FALSE);
    --            INTRFACE.Make_Field_Entrable('IMPORTERS.ARBC_IMPR_NAME' , FALSE);
    --           ELSE
    --                 V_RET := LIB_USR.GNRL.GET_CUSTOMS_SETTING('COMM_TABLE_UNCHECK',9);
    --                  IF NVL(V_RET,0) = 0 THEN
    --                     ret := Str.DispArbMsg(9, 190,'ERROR');
    --                     RAISE FORM_TRIGGER_FAILURE;
    --                ELSE
    --                 INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_EXPRD_DT' , TRUE);
    --                       INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_POB_NBR' , TRUE);
    --                  INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_ZIP_CD' , TRUE);
    --                 INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_TEL_NBR' , TRUE);
    --                 INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_FAX_NBR' , TRUE);
    --                 INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_TELEX_NBR' , TRUE);
    --                 INTRFACE.Make_Field_Entrable('IMPORTERS.ARBC_IMPR_NAME' , TRUE);
    --                  END IF;
    --          END IF;
    --     END IF;
    --    END IF;
    --   END IF;
    --   END;
    --   END IF;
    --   END IF;
    --   BEGIN
    --      IF     GET_RECORD_PROPERTY (:SYSTEM.cursor_record,:SYSTEM.cursor_block,status) IN ('NEW', 'INSERT') AND
    --           :importers.IMPR_TYPE_CD IN ( 1,3,5,6,19 ) AND :importers.bus_id_type_cd = 2
    --            AND :GLOBAL.ALLOW_MCI = 1
    --      THEN
    --         IF :importers.comm_rgstrtn_type = 1 AND :importers.bus_id IS NOT NULL THEN
    --            get_main_cr_data;
    --         ELSIF :importers.comm_rgstrtn_type = 2 AND :importers.bus_id_brnch IS NOT NULL THEN
    --            get_branch_cr_data;
    --         END IF;
    --      END IF;
    --   END;
    --   END;
    --   BEGIN
    --   chk_bus_id_brnch ;
    --   END;
    -- <<<
    PROCEDURE bus_id_brnch_wvi (p_rec       IN OUT NOCOPY t_rec,
                                p_ctx       IN t_ctx,
                                p_cr_answer IN PLS_INTEGER DEFAULT c_yes)
    IS
        v_all_bus_id      VARCHAR2(10);
        v_id_mins_comm_cd VARCHAR2(4);
        v_user_bus_id     VARCHAR2(4);
        alert_txt         VARCHAR2(100);  -- SUGGESTION: size as in Forms
        v_cnt             NUMBER;
        v_ret             VARCHAR2(5);
    BEGIN
        IF NVL(p_rec.bus_id_brnch_entr, 'Y') = 'Y' THEN      -- GET_ITEM_PROPERTY(...,ENABLED) = 'TRUE'
            IF p_rec.bus_id_brnch = '0' THEN
                disp_arb_ftf(1, 220);
            END IF;
            IF p_rec.bus_id_type_cd = 2 AND p_rec.impr_type_cd != 12 THEN
                IF is_digit(p_rec.bus_id_brnch) = FALSE THEN
                    disp_arb_ftf(9, 270);
                END IF;
                IF NOT (LENGTH(p_rec.bus_id_brnch) = 6 OR LENGTH(p_rec.bus_id_brnch) = 10) THEN
                    disp_arb_ftf(9, 260);
                END IF;
                IF p_rec.brnh_city_cd IS NOT NULL THEN
                    SELECT mins_comm_cd
                      INTO p_rec.brnh_id_mins_comm_cd
                      FROM cities
                     WHERE city_cd = p_rec.brnh_city_cd
                       AND ctry_cd = p_rec.ctry_cd;
                    v_id_mins_comm_cd := LPAD(p_rec.brnh_id_mins_comm_cd, 4, '0');
                    IF LENGTH(p_rec.bus_id_brnch) = 6 THEN
                        v_all_bus_id := CONCAT(v_id_mins_comm_cd, p_rec.bus_id_brnch);
                        alert_txt := str_db.getarbmsg(9, 120);
                        IF alert_txt = '-1' THEN
                            alert_txt := 'خطأ فى رقم الرسالة  ' || 9 || '-' || 120 || 'إتصل بالمسانده الفنيه';
                            info(alert_txt);
                        ELSE
                            alert_txt := 'سيتم تحويل الرقم الفرعي إلى الرقم ' || v_all_bus_id;
                            info(alert_txt);
                            IF p_cr_answer = c_yes THEN
                                p_rec.bus_id_brnch := v_all_bus_id;
                            ELSIF p_cr_answer = c_no THEN
                                ftf;
                            END IF;
                        END IF;
                    ELSIF LENGTH(p_rec.bus_id) = 10 THEN
                        v_user_bus_id := SUBSTR(p_rec.bus_id_brnch, 1, 4);
                        IF TO_NUMBER(v_user_bus_id) <> v_id_mins_comm_cd THEN
                            disp_arb_ftf(9, 130);
                        END IF;
                    END IF;
                END IF;
            ELSE
                ui('BUS_ID_BRNCH', 'REQUIRED', FALSE);
            END IF;
            chk_impr_dupl(p_rec);
            IF g_get('FUNS_BUSID') = '0' THEN
                IF p_rec.bus_id_type_cd = 2 AND p_rec.impr_type_cd != 12 THEN
                    IF p_rec.comm_rgstrtn_type = 2 THEN
                        IF p_rec.bus_id IS NOT NULL AND p_rec.bus_id_brnch IS NOT NULL THEN
                            SELECT COUNT(bus_id) INTO v_cnt
                              FROM comm_impr_rgstr
                             WHERE bus_id       = p_rec.bus_id
                               AND brnch_bus_id = p_rec.bus_id_brnch;
                            IF v_cnt > 1 THEN
                                disp_arb_ftf(9, 290);
                            ELSIF v_cnt = 1 THEN
                                SELECT arbc_impr_name, arbc_name_std, bus_id_exprd_dt, impr_tel_nbr,
                                       impr_pob_nbr, impr_zip_cd, impr_fax_nbr, impr_telex_nbr
                                  INTO p_rec.arbc_impr_name, p_rec.impr_name_std, p_rec.bus_id_exprd_dt,
                                       p_rec.impr_tel_nbr, p_rec.impr_pob_nbr, p_rec.impr_zip_cd,
                                       p_rec.impr_fax_nbr, p_rec.impr_telex_nbr
                                  FROM comm_impr_rgstr
                                 WHERE bus_id       = p_rec.bus_id
                                   AND brnch_bus_id = p_rec.bus_id_brnch;
                                cr_fields_entrable(FALSE, FALSE);
                            ELSE
                                v_ret := lib_usr.gnrl.get_customs_setting('COMM_TABLE_UNCHECK', 9);
                                IF NVL(v_ret, 0) = 0 THEN
                                    disp_arb_ftf(9, 190);
                                ELSE
                                    cr_fields_entrable(TRUE, FALSE);
                                END IF;
                            END IF;
                        END IF;
                    END IF;
                END IF;
            END IF;
        END IF;

        IF p_rec.rec_status IN ('NEW', 'INSERT')
           AND p_rec.impr_type_cd IN (1, 3, 5, 6, 19) AND p_rec.bus_id_type_cd = 2
           AND g_get('ALLOW_MCI') = '1' THEN
            IF p_rec.comm_rgstrtn_type = 1 AND p_rec.bus_id IS NOT NULL THEN
                get_main_cr_data(p_rec);
            ELSIF p_rec.comm_rgstrtn_type = 2 AND p_rec.bus_id_brnch IS NOT NULL THEN
                get_branch_cr_data(p_rec);
            END IF;
        END IF;

        chk_bus_id_brnch(p_rec);
    END bus_id_brnch_wvi;

    -- Source: IMPORTERS.BUS_ID_BRNCH.POST-CHANGE
    PROCEDURE bus_id_brnch_post_chg
    IS
    BEGIN
        g_set('FLAGUPDATE', '1');
    END bus_id_brnch_post_chg;

    -- Source: IMPORTERS.BUS_ID_BRNCH.WHEN-NEW-ITEM-INSTANCE
    --@ORIG IMPORTERS.BUS_ID_BRNCH.WHEN-NEW-ITEM-INSTANCE
    -- >>> Original Forms code: IMPORTERS.BUS_ID_BRNCH.WHEN-NEW-ITEM-INSTANCE
    --   DECLARE
    --    RET NUMBER;
    --    V_MINS_COMM_CD NUMBER;
    --   BEGIN
    --    IF :IMPORTERS.BUS_ID_TYPE_CD = 2 AND :IMPORTERS.IMPR_TYPE_CD != 12  THEN
    --      IF :BUS_ID IS NULL OR :CITY_CODE_OF_ID IS NULL THEN
    --         SET_ITEM_PROPERTY('BUS_ID_BRNCH',REQUIRED,PROPERTY_FALSE);
    --       END IF;
    --   END IF;
    --   IF :CITY_CODE =100 THEN
    --       IF :BRNH_CITY_CD IS NOT NULL THEN
    --           BEGIN
    --               SELECT MINS_COMM_CD
    --               INTO   V_MINS_COMM_CD
    --               FROM      CITIES
    --               WHERE  CITY_CD = :IMPORTERS.BRNH_CITY_CD
    --               AND     CTRY_CD = 100;
    --           EXCEPTION
    --               WHEN OTHERS THEN
    --                   NULL;
    --           END;
    --       IF (:GLOBAL.MINS_COMM_CD IS NOT NULL OR V_MINS_COMM_CD IS NOT NULL )
    --          AND :BUS_ID_BRNCH IS NULL THEN
    --           STR.DISPALERT('الرمز التجاري للمدينة المحددة :  '||NVL(:GLOBAL.MINS_COMM_CD,V_MINS_COMM_CD) ,'INFORMATION');
    --           :GLOBAL.MINS_COMM_CD := NULL ;
    --       END IF;
    --       END IF;
    --   END IF;
    --   END;
    -- <<<
    PROCEDURE bus_id_brnch_wnii (p_rec IN t_rec)
    IS
        v_mins_comm_cd NUMBER;
    BEGIN
        IF p_rec.bus_id_type_cd = 2 AND p_rec.impr_type_cd != 12 THEN
            IF p_rec.bus_id IS NULL OR p_rec.city_code_of_id IS NULL THEN
                ui('BUS_ID_BRNCH', 'REQUIRED', FALSE);
            END IF;
        END IF;
        IF p_rec.city_code = 100 THEN       -- SUGGESTION: CITY_CODE (city) compared with 100 (country code?) - kept
            IF p_rec.brnh_city_cd IS NOT NULL THEN
                BEGIN
                    SELECT mins_comm_cd
                      INTO v_mins_comm_cd
                      FROM cities
                     WHERE city_cd = p_rec.brnh_city_cd
                       AND ctry_cd = 100;
                EXCEPTION
                    WHEN OTHERS THEN
                        NULL;
                END;
                IF (g_get('MINS_COMM_CD') IS NOT NULL OR v_mins_comm_cd IS NOT NULL)
                   AND p_rec.bus_id_brnch IS NULL THEN
                    info('الرمز التجاري للمدينة المحددة :  ' || NVL(g_get('MINS_COMM_CD'), v_mins_comm_cd));
                    g_set('MINS_COMM_CD', NULL);
                END IF;
            END IF;
        END IF;
    END bus_id_brnch_wnii;

    -- Source: IMPORTERS.CTRY_CD.WHEN-VALIDATE-ITEM
    --@ORIG IMPORTERS.CTRY_CD.WHEN-VALIDATE-ITEM
    -- >>> Original Forms code: IMPORTERS.CTRY_CD.WHEN-VALIDATE-ITEM
    --   DECLARE
    --       V_COUNT NUMBER;
    --       RET NUMBER;
    --       V_IMPR_NBR NUMBER;
    --   BEGIN
    --   IF :IMPR_TYPE_CD = 12 THEN
    --       SELECT COUNT(*)
    --       INTO     V_COUNT
    --       FROM     CTRY_GROUP_DETAILS
    --       WHERE  CTRY_CD = :CTRY_CD
    --       AND     CTRY_GRP_STAT = 1
    --       AND     CTRY_GRP_NBR = 1
    --       ;
    --       IF V_COUNT = 0 THEN
    --           STR.DISPALERT('لابد أن تكون دولة المستورد الخليجي تابعة لدول مجلس التعاون','ERROR');
    --           RAISE FORM_TRIGGER_FAILURE;
    --       END IF;
    --   END IF;
    --   END;
    --   IF :IMPR_TYPE_CD = 3 AND :BUS_ID_TYPE_CD = 2 THEN
    --       :CTRY_CD_OF_ID := 100;
    --   ELSE
    --       :CTRY_CD_OF_ID := :CTRY_CD;
    --   END IF;
    --   BEGIN
    --     IF (name_in('IMPORTERS.CTRY_CD') IS NOT NULL) THEN
    --       BEGIN
    --         CGFK$CHK_IMPORTERS_IMP_CTRY_FK(
    --           :IMPORTERS.CTRY_CTRY_STATUS
    --          ,:IMPORTERS.CRTY_ARBC_NAME
    --          ,:IMPORTERS.CTRY_CD         );
    --       EXCEPTION
    --         WHEN NO_DATA_FOUND THEN
    --           Des$Form_errors.PUSH('رمز الدولة غير صحيح - أعد ادخال البيانات', 'E', 'OFG', 0);
    --           Des$Form_errors.RAISE_FAILURE;
    --         WHEN OTHERS THEN
    --           CGTE$OTHER_EXCEPTIONS;
    --       END;
    --     END IF;
    --   END;
    -- <<<
    PROCEDURE ctry_cd_wvi (p_rec IN OUT NOCOPY t_rec)
    IS
        v_count NUMBER;
    BEGIN
        IF p_rec.impr_type_cd = 12 THEN
            SELECT COUNT(*)
              INTO v_count
              FROM ctry_group_details
             WHERE ctry_cd       = p_rec.ctry_cd
               AND ctry_grp_stat = 1
               AND ctry_grp_nbr  = 1;
            IF v_count = 0 THEN
                ftf('لابد أن تكون دولة المستورد الخليجي تابعة لدول مجلس التعاون');
            END IF;
        END IF;
        IF p_rec.impr_type_cd = 3 AND p_rec.bus_id_type_cd = 2 THEN
            p_rec.ctry_cd_of_id := 100;
        ELSE
            p_rec.ctry_cd_of_id := p_rec.ctry_cd;
        END IF;
        -- CGFK$VALDIDATE_FK_OVF (CGFK$CHK_IMPORTERS_IMP_CTRY_FK: active countries only)
        IF p_rec.ctry_cd IS NOT NULL THEN
            BEGIN
                SELECT ctry.crty_arbc_name, ctry.ctry_status
                  INTO p_rec.crty_arbc_name, p_rec.ctry_ctry_status
                  FROM countries ctry
                 WHERE ctry.ctry_cd = p_rec.ctry_cd
                   AND ctry.ctry_status = 1;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    ftf('رمز الدولة غير صحيح - أعد ادخال البيانات');
            END;
        END IF;
    END ctry_cd_wvi;

    -- Source: IMPORTERS.IMPR_EXPR_TYPE.POST-CHANGE
    PROCEDURE impr_expr_type_post_chg
    IS
    BEGIN
        g_set('FLAGUPDATE', '1');
    END impr_expr_type_post_chg;

    -- Source: IMPORTERS.ARBC_IMPR_NAME.WHEN-VALIDATE-ITEM
    --@ORIG IMPORTERS.ARBC_IMPR_NAME.WHEN-VALIDATE-ITEM
    -- >>> Original Forms code: IMPORTERS.ARBC_IMPR_NAME.WHEN-VALIDATE-ITEM
    --   BEGIN
    --   :ARBC_IMPR_NAME := STR_db.RemoveRepeat(:ARBC_IMPR_NAME);
    --   :IMPR_NAME_STD    := STR.STRFORMAT(:ARBC_IMPR_NAME);
    --   END;
    -- <<<
    PROCEDURE arbc_impr_name_wvi (p_rec IN OUT NOCOPY t_rec)
    IS
    BEGIN
        p_rec.arbc_impr_name := str_db.removerepeat(p_rec.arbc_impr_name);
        p_rec.impr_name_std  := str_db.strformat(p_rec.arbc_impr_name);  -- STR.STRFORMAT (client)
    END arbc_impr_name_wvi;

    -- Source: IMPORTERS.ARBC_IMPR_NAME.KEY-NEXT-ITEM
    -- Net effect in Forms: temporary dummy values that are all reset before GO_ITEM -> the
    -- record is unchanged; only the focus moves to ENG_IMPR_NAME. Kept for traceability.
    --@ORIG IMPORTERS.ARBC_IMPR_NAME.KEY-NEXT-ITEM
    -- >>> Original Forms code: IMPORTERS.ARBC_IMPR_NAME.KEY-NEXT-ITEM
    --   DECLARE
    --       CITY_DUMMY_VALUE     NUMBER := 1;
    --       CTRY_DUMMY_VALUE     NUMBER := 1;
    --         TEL_DUMMY_VALUE    NUMBER := 1;
    --   BEGIN
    --       IF :ADD_CTRY_CD IS NULL THEN
    --           :ADD_CTRY_CD := :CTRY_CD;  -- only bcz CITY_CODE is Mandatory
    --       ELSE
    --           CTRY_DUMMY_VALUE := NULL;
    --       END IF;
    --       IF :CITY_CODE IS NULL THEN
    --           SELECT MIN(CITY_CD)
    --           INTO     :CITY_CODE
    --           FROM     CITIES
    --           WHERE CTRY_CD = :CTRY_CD
    --           AND    CITY_STATUS = 1
    --           ;
    --       ELSE
    --           CITY_DUMMY_VALUE  := NULL;
    --       END IF;
    --       IF :IMPR_TEL_NBR IS NULL THEN
    --   :IMPR_TEL_NBR := 1;
    --       ELSE
    --           TEL_DUMMY_VALUE  := NULL;
    --       END IF;
    --       IF CITY_DUMMY_VALUE IS NOT NULL THEN
    --           :CITY_CODE      := NULL;
    --           :CITY_NAME     := NULL;
    --       END IF;
    --       IF TEL_DUMMY_VALUE IS NOT NULL THEN
    --           :IMPR_TEL_NBR      := NULL;
    --       END IF;
    --       IF CTRY_DUMMY_VALUE IS NOT NULL THEN
    --           :ADD_CTRY_CD       := NULL;
    --           :ADD_CRTY_ARBC_NAME := NULL;
    --       END IF;
    --   BEGIN
    --       go_Item('IMPORTERS.ENG_IMPR_NAME');
    --   END;
    --   END;
    -- <<<
    PROCEDURE arbc_impr_name_key_nxt (p_rec IN OUT NOCOPY t_rec)
    IS
        city_dummy_value NUMBER := 1;
        ctry_dummy_value NUMBER := 1;
        tel_dummy_value  NUMBER := 1;
    BEGIN
        IF p_rec.add_ctry_cd IS NULL THEN
            p_rec.add_ctry_cd := p_rec.ctry_cd;
        ELSE
            ctry_dummy_value := NULL;
        END IF;
        IF p_rec.city_code IS NULL THEN
            SELECT MIN(city_cd)
              INTO p_rec.city_code
              FROM cities
             WHERE ctry_cd = p_rec.ctry_cd
               AND city_status = 1;
        ELSE
            city_dummy_value := NULL;
        END IF;
        IF p_rec.impr_tel_nbr IS NULL THEN
            p_rec.impr_tel_nbr := 1;
        ELSE
            tel_dummy_value := NULL;
        END IF;
        IF city_dummy_value IS NOT NULL THEN
            p_rec.city_code := NULL;
            p_rec.city_name := NULL;
        END IF;
        IF tel_dummy_value IS NOT NULL THEN
            p_rec.impr_tel_nbr := NULL;
        END IF;
        IF ctry_dummy_value IS NOT NULL THEN
            p_rec.add_ctry_cd        := NULL;
            p_rec.add_crty_arbc_name := NULL;
        END IF;
        ui_focus('ENG_IMPR_NAME');
    END arbc_impr_name_key_nxt;

    -- Source: IMPORTERS.ENG_IMPR_NAME.WHEN-VALIDATE-ITEM
    --@ORIG IMPORTERS.ENG_IMPR_NAME.WHEN-VALIDATE-ITEM
    -- >>> Original Forms code: IMPORTERS.ENG_IMPR_NAME.WHEN-VALIDATE-ITEM
    --   DECLARE
    --       ENG_IMPR_NAME_length   NUMBER;
    --       V         VARCHAR2(1);
    --   BEGIN
    --   IF :ENG_IMPR_NAME IS NOT NULL THEN
    --    :eng_IMPR_NAME := STR_db.RemoveRepeat(:eng_IMPR_NAME);
    --       ENG_IMPR_NAME_length := LENGTH(:ENG_IMPR_NAME);
    --           FOR I IN  1 .. ENG_IMPR_NAME_length LOOP
    --             V := SUBSTR(:ENG_IMPR_NAME,I,1);
    --                IF ( V BETWEEN '0' AND '9' ) OR ( V BETWEEN 'A' AND 'Z' ) OR ( V BETWEEN 'a' AND 'z' )
    --                     OR ( V = ' ' ) THEN
    --                   NULL;
    --                ELSE
    --                   STR.DISPALERT ('فضلا .. يجب إدخال اسم المستورد باللغة الانجليزية','information');
    --                   RAISE FORM_TRIGGER_FAILURE;
    --                    END IF;
    --         END LOOP;
    --   ELSE
    --   NULL;
    --   END IF;
    --   END;
    -- <<<
    PROCEDURE eng_impr_name_wvi (p_rec IN OUT NOCOPY t_rec)
    IS
        eng_impr_name_length NUMBER;
        v                    VARCHAR2(1);
    BEGIN
        IF p_rec.eng_impr_name IS NOT NULL THEN
            p_rec.eng_impr_name := str_db.removerepeat(p_rec.eng_impr_name);
            eng_impr_name_length := LENGTH(p_rec.eng_impr_name);
            FOR i IN 1 .. eng_impr_name_length LOOP
                v := SUBSTR(p_rec.eng_impr_name, i, 1);
                IF (v BETWEEN '0' AND '9') OR (v BETWEEN 'A' AND 'Z') OR (v BETWEEN 'a' AND 'z')
                   OR (v = ' ') THEN
                    NULL;
                ELSE
                    ftf('فضلا .. يجب إدخال اسم المستورد باللغة الانجليزية');
                END IF;
            END LOOP;
        END IF;
    END eng_impr_name_wvi;

    -- Source: IMPORTERS.BUS_ID_ISSUE_DT.WHEN-VALIDATE-ITEM
    --@ORIG IMPORTERS.BUS_ID_ISSUE_DT.WHEN-VALIDATE-ITEM
    -- >>> Original Forms code: IMPORTERS.BUS_ID_ISSUE_DT.WHEN-VALIDATE-ITEM
    --   DECLARE
    --       HDATE DATE;
    --   BEGIN
    --       IF :System.TRIGGER_ITEM = :System.CURSOR_ITEM THEN
    --           IF :System.Cursor_Value IS NOT NULL THEN
    --               HDATE := TO_DATE(:System.Cursor_Value);
    --               IF NOT HIJDATE.VALID_HIJ_DATE(HDATE) THEN
    --                   RAISE FORM_TRIGGER_FAILURE;
    --               END IF;
    --           END IF;
    --       END IF;
    --   END;
    -- <<<
    PROCEDURE bus_id_issue_dt_wvi (p_rec IN t_rec, p_from_item IN BOOLEAN DEFAULT TRUE)
    IS
    BEGIN
        IF p_from_item THEN
            IF p_rec.bus_id_issue_dt IS NOT NULL THEN
                IF NOT valid_hij_date(p_rec.bus_id_issue_dt) THEN
                    ftf;
                END IF;
            END IF;
        END IF;
    END bus_id_issue_dt_wvi;

    -- Source: IMPORTERS.IMPR_NBR_PARENT.WHEN-VALIDATE-ITEM (9-160 is shown, no failure)
    --@ORIG IMPORTERS.IMPR_NBR_PARENT.WHEN-VALIDATE-ITEM
    -- >>> Original Forms code: IMPORTERS.IMPR_NBR_PARENT.WHEN-VALIDATE-ITEM
    --   DECLARE
    --       ret NUMBER;
    --       CURSOR C_P_NAME IS
    --               SELECT ARBC_IMPR_NAME
    --           FROM IMPORTERS
    --           WHERE IMPR_NBR = :IMPR_NBR_PARENT;
    --   BEGIN
    --   IF :IMPR_NBR_PARENT IS NOT NULL THEN
    --           OPEN C_P_NAME;
    --         FETCH C_P_NAME INTO :IMPR_NAME_PARENT;
    --            IF C_P_NAME%NOTFOUND THEN
    --           ret := Str.DispArbMsg(9, 160,'ERROR');
    --         END IF;
    --         CLOSE C_P_NAME;
    --   END IF;
    --   END;
    -- <<<
    PROCEDURE impr_nbr_parent_wvi (p_rec IN OUT NOCOPY t_rec)
    IS
        CURSOR c_p_name IS
            SELECT arbc_impr_name
              FROM importers
             WHERE impr_nbr = p_rec.impr_nbr_parent;
    BEGIN
        IF p_rec.impr_nbr_parent IS NOT NULL THEN
            OPEN c_p_name;
            FETCH c_p_name INTO p_rec.impr_name_parent;
            IF c_p_name%NOTFOUND THEN
                disp_arb_info(9, 160);
            END IF;
            CLOSE c_p_name;
        END IF;
    END impr_nbr_parent_wvi;

    -- Source: IMPORTERS.ADD_CTRY_CD.WHEN-VALIDATE-ITEM
    --@ORIG IMPORTERS.ADD_CTRY_CD.WHEN-VALIDATE-ITEM
    -- >>> Original Forms code: IMPORTERS.ADD_CTRY_CD.WHEN-VALIDATE-ITEM
    --   DECLARE
    --    RET NUMBER;
    --   BEGIN
    --    SELECT CRTY_ARBC_NAME INTO :ADD_CRTY_ARBC_NAME
    --    FROM   COUNTRIES
    --    WHERE  CTRY_CD=:ADD_CTRY_CD;
    --   EXCEPTION
    --   WHEN NO_DATA_FOUND THEN
    --     ret := Str.DispArbMsg(18, 15,'ERROR');
    --     RAISE FORM_TRIGGER_FAILURE;
    --   END;
    --   BEGIN
    --     IF (name_in('IMPORTERS.ADD_CTRY_CD') IS NOT NULL AND name_in('IMPORTERS.CITY_CODE') IS NOT NULL) THEN
    --       BEGIN
    --         CGFK$CHK_IMPORTERS_IMP_ADD_CIT(
    --           :IMPORTERS.ADD_CRTY_ARBC_NAME
    --          ,:IMPORTERS.CITY_NAME
    --          ,:IMPORTERS.L_CT_CITY_STATUS
    --          ,:IMPORTERS.CITY_CODE
    --          ,:IMPORTERS.ADD_CTRY_CD       );
    --       EXCEPTION
    --         WHEN NO_DATA_FOUND THEN
    --           Des$Form_errors.PUSH('خطأ في رمز مدينة عنوان المستورد', 'W', 'OFG', 0);
    --         WHEN OTHERS THEN
    --           CGTE$OTHER_EXCEPTIONS;
    --       END;
    --     END IF;
    --   END;
    -- <<<
    PROCEDURE add_ctry_cd_wvi (p_rec IN OUT NOCOPY t_rec)
    IS
    BEGIN
        BEGIN
            SELECT crty_arbc_name INTO p_rec.add_crty_arbc_name
              FROM countries
             WHERE ctry_cd = p_rec.add_ctry_cd;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                disp_arb_ftf(18, 15);
        END;
        -- CGFK$VALDIDATE_FK_OVF (CGFK$CHK_IMPORTERS_IMP_ADD_CIT) - warning only
        IF p_rec.add_ctry_cd IS NOT NULL AND p_rec.city_code IS NOT NULL THEN
            BEGIN
                SELECT add_city.city_status, add_city.city_arb_name, l_ctry.crty_arbc_name
                  INTO p_rec.l_ct_city_status, p_rec.city_name, p_rec.add_crty_arbc_name
                  FROM cities add_city, countries l_ctry
                 WHERE add_city.ctry_cd     = p_rec.add_ctry_cd
                   AND add_city.city_cd     = p_rec.city_code
                   AND add_city.city_status = 1
                   AND l_ctry.ctry_cd       = add_city.ctry_cd
                   AND ROWNUM = 1;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    info('خطأ في رمز مدينة عنوان المستورد');
            END;
        END IF;
    END add_ctry_cd_wvi;

    -- Source: IMPORTERS.CITY_CODE.WHEN-VALIDATE-ITEM
    --@ORIG IMPORTERS.CITY_CODE.WHEN-VALIDATE-ITEM
    -- >>> Original Forms code: IMPORTERS.CITY_CODE.WHEN-VALIDATE-ITEM
    --   DECLARE
    --    RET NUMBER;
    --   BEGIN
    --   IF :CITY_CODE  IS NULL THEN
    --   STR.DISPALERT('يجب إدخال المدينة','INFORMATION');
    --     RAISE FORM_TRIGGER_FAILURE;
    --   END IF;
    --    SELECT CITY_ARB_NAME INTO :CITY_NAME
    --    FROM   CITIES
    --    WHERE  CTRY_CD=:ADD_CTRY_CD
    --     AND   CITY_CD=:CITY_CODE;
    --   EXCEPTION
    --   WHEN NO_DATA_FOUND THEN
    --     ret := Str.DispArbMsg(18, 282,'ERROR');
    --     RAISE FORM_TRIGGER_FAILURE;
    --   END;
    --   BEGIN
    --     IF (name_in('IMPORTERS.ADD_CTRY_CD') IS NOT NULL AND name_in('IMPORTERS.CITY_CODE') IS NOT NULL) THEN
    --       BEGIN
    --         CGFK$CHK_IMPORTERS_IMP_ADD_CIT(
    --           :IMPORTERS.ADD_CRTY_ARBC_NAME
    --          ,:IMPORTERS.CITY_NAME
    --          ,:IMPORTERS.L_CT_CITY_STATUS
    --          ,:IMPORTERS.CITY_CODE
    --          ,:IMPORTERS.ADD_CTRY_CD       );
    --       EXCEPTION
    --         WHEN NO_DATA_FOUND THEN
    --           Des$Form_errors.PUSH('خطأ في رمز مدينة عنوان المستورد', 'W', 'OFG', 0);
    --         WHEN OTHERS THEN
    --           CGTE$OTHER_EXCEPTIONS;
    --       END;
    --     END IF;
    --   END;
    -- <<<
    PROCEDURE city_code_wvi (p_rec IN OUT NOCOPY t_rec)
    IS
    BEGIN
        BEGIN
            IF p_rec.city_code IS NULL THEN
                ftf('يجب إدخال المدينة');
            END IF;
            SELECT city_arb_name INTO p_rec.city_name
              FROM cities
             WHERE ctry_cd = p_rec.add_ctry_cd
               AND city_cd = p_rec.city_code;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                disp_arb_ftf(18, 282);
        END;
        -- CGFK$VALDIDATE_FK_OVF (CGFK$CHK_IMPORTERS_IMP_ADD_CIT) - warning only
        IF p_rec.add_ctry_cd IS NOT NULL AND p_rec.city_code IS NOT NULL THEN
            BEGIN
                SELECT add_city.city_status, add_city.city_arb_name, l_ctry.crty_arbc_name
                  INTO p_rec.l_ct_city_status, p_rec.city_name, p_rec.add_crty_arbc_name
                  FROM cities add_city, countries l_ctry
                 WHERE add_city.ctry_cd     = p_rec.add_ctry_cd
                   AND add_city.city_cd     = p_rec.city_code
                   AND add_city.city_status = 1
                   AND l_ctry.ctry_cd       = add_city.ctry_cd
                   AND ROWNUM = 1;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    info('خطأ في رمز مدينة عنوان المستورد');
            END;
        END IF;
    END city_code_wvi;

    -- Source: IMPORTERS.IMPR_TEL_NBR.WHEN-VALIDATE-ITEM
    -- (TO_NUMBER of a non-numeric value raises ORA-01722 in Forms too - kept)
    --@ORIG IMPORTERS.IMPR_TEL_NBR.WHEN-VALIDATE-ITEM
    -- >>> Original Forms code: IMPORTERS.IMPR_TEL_NBR.WHEN-VALIDATE-ITEM
    --   BEGIN
    --   IF :IMPR_TEL_NBR IS NULL THEN
    --     str.DISPALERT('يجب إدخال الهاتف','INFORMATION');
    --      RAISE FORM_TRIGGER_FAILURE ;
    --   END IF;
    --   IF LENGTH(:IMPR_TEL_NBR) < 10 OR LENGTH(:IMPR_TEL_NBR) > 10 THEN
    --      str.DISPALERT('رقم الهاتف يجب أن يتكون من 10 أرقام','INFORMATION');
    --   RAISE FORM_TRIGGER_FAILURE ;
    --   END IF;
    --   IF TO_NUMBER(:IMPR_TEL_NBR) = 0 THEN
    --    str.DISPALERT('يجب أن يكون رقم الهاتف المدخل أرقام','INFORMATION');
    --   RAISE FORM_TRIGGER_FAILURE ;
    --   END IF;
    --   END;
    -- <<<
    PROCEDURE impr_tel_nbr_wvi (p_rec IN t_rec)
    IS
    BEGIN
        IF p_rec.impr_tel_nbr IS NULL THEN
            ftf('يجب إدخال الهاتف');
        END IF;
        IF LENGTH(p_rec.impr_tel_nbr) < 10 OR LENGTH(p_rec.impr_tel_nbr) > 10 THEN
            ftf('رقم الهاتف يجب أن يتكون من 10 أرقام');
        END IF;
        IF TO_NUMBER(p_rec.impr_tel_nbr) = 0 THEN
            ftf('يجب أن يكون رقم الهاتف المدخل أرقام');
        END IF;
    END impr_tel_nbr_wvi;

    -- Shared body of B_EMAIL / EMAIL WHEN-VALIDATE-ITEM (identical text in both triggers)
    PROCEDURE check_email (p_email IN VARCHAR2, p_from_item IN BOOLEAN)
    IS
        at_pos NUMBER;
    BEGIN
        IF p_from_item THEN
            IF (LENGTH(p_email) > 0) THEN
                at_pos := INSTR(p_email, '@');
                IF (at_pos <= 0 OR at_pos = 1) THEN
                    ftf('خطأ فى صيغة البريد الالكتروني');
                END IF;
            END IF;
        END IF;
    END check_email;

    -- Source: IMPORTERS.B_EMAIL.WHEN-VALIDATE-ITEM
    --@ORIG IMPORTERS.B_EMAIL.WHEN-VALIDATE-ITEM
    -- >>> Original Forms code: IMPORTERS.B_EMAIL.WHEN-VALIDATE-ITEM
    --   DECLARE
    --       EMAIL VARCHAR2(200);
    --       At_Pos number;
    --       Dot_Pos number;
    --       EMAIL_LENGTH  number;
    --       RET NUMBER;
    --   Begin
    --       IF :System.TRIGGER_ITEM = :System.CURSOR_ITEM THEN
    --           EMAIL := :System.Cursor_Value;
    --           EMAIL_LENGTH := LENGTH(EMAIL);
    --           IF (EMAIL_LENGTH > 0)     THEN
    --               At_Pos := INSTR(EMAIL, '@');
    --               Dot_Pos := INSTR(EMAIL, '.');
    --                   IF (At_Pos  <= 0 OR At_Pos = 1 ) THEN
    --                   RET := STR.DISPALERT('خطأ فى صيغة البريد الالكتروني','INFORMATION');
    --                   RAISE FORM_TRIGGER_FAILURE;
    --               END IF;
    --           END IF;
    --       END IF;
    --   End;
    -- <<<
    PROCEDURE b_email_wvi (p_rec IN t_rec, p_from_item IN BOOLEAN DEFAULT TRUE)
    IS
    BEGIN
        check_email(p_rec.b_email, p_from_item);
    END b_email_wvi;

    -- Source: IMPORTERS.EMAIL.WHEN-VALIDATE-ITEM (EMAIL is hidden; only filled by POST-QUERY)
    PROCEDURE email_wvi (p_rec IN t_rec, p_from_item IN BOOLEAN DEFAULT TRUE)
    IS
    BEGIN
        check_email(p_rec.email, p_from_item);
    END email_wvi;

    -- Source: IMPORTERS.B_EMAIL.POST-CHANGE (same body: B_MOBILE_NO, B_ID_NBR)
    -- Business rule: changing e-mail / mobile / ID moves the importer row to the current port.
    --@ORIG IMPORTERS.B_EMAIL.POST-CHANGE
    -- >>> Original Forms code: IMPORTERS.B_EMAIL.POST-CHANGE
    --   BEGIN
    --   :GLOBAL.FLAGUPDATE := 1;
    --   :PORT_CD:=:PARAMETER.P_CURR_PORT_CD;
    --   END;
    -- <<<
    PROCEDURE b_email_post_chg (p_rec IN OUT NOCOPY t_rec, p_ctx IN t_ctx)
    IS
    BEGIN
        g_set('FLAGUPDATE', '1');
        p_rec.port_cd := p_ctx.curr_port_cd;
    END b_email_post_chg;

    -- Source: IMPORTERS.B_MOBILE_NO.WHEN-VALIDATE-ITEM
    --@ORIG IMPORTERS.B_MOBILE_NO.WHEN-VALIDATE-ITEM
    -- >>> Original Forms code: IMPORTERS.B_MOBILE_NO.WHEN-VALIDATE-ITEM
    --   DECLARE
    --   MOBILE_NO_length  NUMBER;
    --   V    VARCHAR2(1);
    --   BEGIN
    --      IF :PARAMETER.P_CURR_PORT_CD = 99  THEN
    --          IF :GLOBAL.OLD_PORT_CD <> 99 AND :IMPR_NBR IS NOT NULL THEN
    --                  STR.DISPALERT ('لا يمكن تعديل رقم الجوال, الرجاء استخدام الوظيفة الخاصة بتعديل رقم الجوال','ERROR');
    --                   RAISE FORM_TRIGGER_FAILURE ;
    --          END IF;
    --      END IF;
    --   BEGIN
    --   MOBILE_NO_length := LENGTH (:B_MOBILE_NO);
    --           FOR I IN  1 .. MOBILE_NO_length LOOP
    --             V := SUBSTR(:B_MOBILE_NO,I,1);
    --                IF ( V BETWEEN '0' AND '9' )
    --                     THEN
    --                   NULL;
    --                ELSE
    --                   STR.DISPALERT ('يجب أن يكون رقم الجوال المدخل أرقام','information');
    --                   RAISE FORM_TRIGGER_FAILURE;
    --                    END IF;
    --         END LOOP;
    --   END ;
    --       IF :B_MOBILE_NO IS NOT NULL AND (LENGTH(:B_MOBILE_NO) != 9 OR SUBSTR(:B_MOBILE_NO,1,1) != 5 ) THEN
    --           STR.DISPALERT('رقم الجوال المدخل غير صحيح .. الرجاء اعادة الادخال ','ERROR');
    --           RAISE FORM_TRIGGER_FAILURE;
    --       END IF;
    --   END;
    -- <<<
    PROCEDURE b_mobile_no_wvi (p_rec IN t_rec, p_ctx IN t_ctx)
    IS
        mobile_no_length NUMBER;
        v                VARCHAR2(1);
    BEGIN
        IF p_ctx.curr_port_cd = 99 THEN
            IF g_get('OLD_PORT_CD') <> 99 AND p_rec.impr_nbr IS NOT NULL THEN
                ftf('لا يمكن تعديل رقم الجوال, الرجاء استخدام الوظيفة الخاصة بتعديل رقم الجوال');
            END IF;
        END IF;
        mobile_no_length := LENGTH(p_rec.b_mobile_no);
        FOR i IN 1 .. mobile_no_length LOOP
            v := SUBSTR(p_rec.b_mobile_no, i, 1);
            IF (v BETWEEN '0' AND '9') THEN
                NULL;
            ELSE
                ftf('يجب أن يكون رقم الجوال المدخل أرقام');
            END IF;
        END LOOP;
        IF p_rec.b_mobile_no IS NOT NULL
           AND (LENGTH(p_rec.b_mobile_no) != 9 OR SUBSTR(p_rec.b_mobile_no, 1, 1) != 5) THEN
            ftf('رقم الجوال المدخل غير صحيح .. الرجاء اعادة الادخال ');
        END IF;
    END b_mobile_no_wvi;

    -- Source: IMPORTERS.B_MOBILE_NO.POST-CHANGE
    PROCEDURE b_mobile_no_post_chg (p_rec IN OUT NOCOPY t_rec, p_ctx IN t_ctx)
    IS
    BEGIN
        b_email_post_chg(p_rec, p_ctx);
    END b_mobile_no_post_chg;

    -- Source: IMPORTERS.BANK_IBAN.WHEN-VALIDATE-ITEM
    --@ORIG IMPORTERS.BANK_IBAN.WHEN-VALIDATE-ITEM
    -- >>> Original Forms code: IMPORTERS.BANK_IBAN.WHEN-VALIDATE-ITEM
    --   BEGIN
    --       :BANK_IBAN := UPPER(:BANK_IBAN);
    --       IF :BANK_IBAN ='SA' THEN
    --              :BANK_IBAN :=NULL;
    --       ELSIF :BANK_IBAN IS NOT NULL AND SUBSTR(:BANK_IBAN ,1,2)!='SA' THEN
    --              :BANK_IBAN := 'SA'||:BANK_IBAN ;
    --       END IF;
    --       IF :BANK_IBAN IS NOT NULL AND LENGTH(:BANK_IBAN ) != 24 THEN
    --           STR.DISPALERT(' رقم الآيبان المدخل غير صحيح..الرجاء إعادة الإدخال ','ERROR');
    --           RAISE FORM_TRIGGER_FAILURE;
    --       END IF;
    --   END;
    -- <<<
    PROCEDURE bank_iban_wvi (p_rec IN OUT NOCOPY t_rec)
    IS
    BEGIN
        p_rec.bank_iban := UPPER(p_rec.bank_iban);
        IF p_rec.bank_iban = 'SA' THEN
            p_rec.bank_iban := NULL;
        ELSIF p_rec.bank_iban IS NOT NULL AND SUBSTR(p_rec.bank_iban, 1, 2) != 'SA' THEN
            p_rec.bank_iban := 'SA' || p_rec.bank_iban;
        END IF;
        IF p_rec.bank_iban IS NOT NULL AND LENGTH(p_rec.bank_iban) != 24 THEN
            ftf(' رقم الآيبان المدخل غير صحيح..الرجاء إعادة الإدخال ');
        END IF;
    END bank_iban_wvi;

    -- Source: IMPORTERS.BANK_IBAN.WHEN-NEW-ITEM-INSTANCE
    PROCEDURE bank_iban_wnii (p_rec IN OUT NOCOPY t_rec)
    IS
    BEGIN
        IF p_rec.bank_iban IS NULL THEN
            p_rec.bank_iban := 'SA';
        END IF;
    END bank_iban_wnii;

    -- Source: IMPORTERS.B_ID_NBR.WHEN-VALIDATE-ITEM
    --@ORIG IMPORTERS.B_ID_NBR.WHEN-VALIDATE-ITEM
    -- >>> Original Forms code: IMPORTERS.B_ID_NBR.WHEN-VALIDATE-ITEM
    --   DECLARE
    --     X NUMBER;
    --   BEGIN
    --       IF :B_ID_NBR IS NOT NULL THEN
    --           X:=TO_NUMBER(:B_ID_NBR);
    --       END IF;
    --   EXCEPTION WHEN OTHERS THEN
    --       STR.DISPALERT('يجب إدخال رقم الهوية بشكل صحيح','ERROR');
    --       RAISE FORM_TRIGGER_FAILURE;
    --   END;
    --       IF :B_ID_NBR IS NOT NULL THEN
    --           IF  NOT CHECK_IDNO(:B_ID_NBR)THEN
    --               STR.DISPALERT('رقم الهوية المدخل غير صحيح.. يجب إدخال رقم هوية صحيح','ERROR');
    --               RAISE FORM_TRIGGER_FAILURE;
    --           END IF;
    --       END IF;
    -- <<<
    PROCEDURE b_id_nbr_wvi (p_rec IN t_rec)
    IS
        x NUMBER;
    BEGIN
        BEGIN
            IF p_rec.b_id_nbr IS NOT NULL THEN
                x := TO_NUMBER(p_rec.b_id_nbr);
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                ftf('يجب إدخال رقم الهوية بشكل صحيح');
        END;
        IF p_rec.b_id_nbr IS NOT NULL THEN
            IF NOT check_idno(p_rec.b_id_nbr) THEN
                ftf('رقم الهوية المدخل غير صحيح.. يجب إدخال رقم هوية صحيح');
            END IF;
        END IF;
    END b_id_nbr_wvi;

    -- Source: IMPORTERS.B_ID_NBR.POST-CHANGE
    PROCEDURE b_id_nbr_post_chg (p_rec IN OUT NOCOPY t_rec, p_ctx IN t_ctx)
    IS
    BEGIN
        b_email_post_chg(p_rec, p_ctx);
    END b_id_nbr_post_chg;

    -- ======================================================================= PROGRAM UNITS

    -- Source: PU CHECK_IDNO (unchanged)
    --@ORIG PU CHECK_IDNO
    -- >>> Original Forms code: PU CHECK_IDNO
    --   FUNCTION CHECK_IDNO(ID_NO VARCHAR2) RETURN BOOLEAN IS
    --       RESULT     NUMBER:=0;
    --       SU         NUMBER:=0;
    --       CHR_RESULT     VARCHAR2(10);
    --   BEGIN
    --       FOR I IN 1..9 LOOP
    --           SU :=TO_NUMBER(SUBSTR(ID_NO,I,1));
    --               IF MOD(I,2)<>0 THEN
    --                   RESULT:=RESULT + MOD(SU * 2,10);
    --                   RESULT:=RESULT + TRUNC((SU * 2)/10);
    --               ELSE
    --                   RESULT:=RESULT + SU;
    --               END IF;
    --       END LOOP;
    --       CHR_RESULT:=RESULT;
    --       IF SUBSTR(ID_NO,10,1)=0 THEN
    --          IF SUBSTR(CHR_RESULT,LENGTH(CHR_RESULT),1)=0 THEN
    --              RETURN TRUE;
    --          END IF;
    --       ELSE
    --           IF TO_CHAR((10 - TO_NUMBER(SUBSTR(CHR_RESULT,LENGTH(CHR_RESULT),1))))=SUBSTR(ID_NO,10,1) THEN
    --          RETURN TRUE;
    --           END IF;
    --       END IF;
    --       RETURN FALSE;
    --   END;
    -- <<<
    FUNCTION check_idno (id_no IN VARCHAR2) RETURN BOOLEAN
    IS
        result     NUMBER := 0;
        su         NUMBER := 0;
        chr_result VARCHAR2(10);
    BEGIN
        FOR i IN 1 .. 9 LOOP
            su := TO_NUMBER(SUBSTR(id_no, i, 1));
            IF MOD(i, 2) <> 0 THEN
                result := result + MOD(su * 2, 10);
                result := result + TRUNC((su * 2) / 10);
            ELSE
                result := result + su;
            END IF;
        END LOOP;
        chr_result := result;
        IF SUBSTR(id_no, 10, 1) = 0 THEN
            IF SUBSTR(chr_result, LENGTH(chr_result), 1) = 0 THEN
                RETURN TRUE;
            END IF;
        ELSE
            IF TO_CHAR((10 - TO_NUMBER(SUBSTR(chr_result, LENGTH(chr_result), 1)))) = SUBSTR(id_no, 10, 1) THEN
                RETURN TRUE;
            END IF;
        END IF;
        RETURN FALSE;
    END check_idno;

    -- Source: PU IS_DIGIT (unchanged)
    --@ORIG PU IS_DIGIT
    -- >>> Original Forms code: PU IS_DIGIT
    --   FUNCTION IS_Digit(txt_num VARCHAR2) RETURN BOOLEAN IS
    --    chr1      VARCHAR2(200);
    --    len_txt   NUMBER ;
    --    counter   NUMBER :=1;
    --   BEGIN
    --    len_txt:=LENGTH(txt_num);
    --    WHILE (counter<=len_txt) LOOP
    --       chr1 := SUBSTR(txt_num,counter,1) ;
    --       IF ASCII(chr1) <48  OR ASCII(chr1)>57 THEN
    --          RETURN FALSE;
    --        END IF;
    --        counter :=counter+1;
    --    END LOOP;
    --        RETURN TRUE;
    --   END;
    -- <<<
    FUNCTION is_digit (txt_num IN VARCHAR2) RETURN BOOLEAN
    IS
        chr1    VARCHAR2(200);
        len_txt NUMBER;
        counter NUMBER := 1;
    BEGIN
        len_txt := LENGTH(txt_num);
        WHILE (counter <= len_txt) LOOP
            chr1 := SUBSTR(txt_num, counter, 1);
            IF ASCII(chr1) < 48 OR ASCII(chr1) > 57 THEN
                RETURN FALSE;
            END IF;
            counter := counter + 1;
        END LOOP;
        RETURN TRUE;
    END is_digit;

    -- Source: PU CHECK_BUS_ID - whole body is commented out in Forms (only NULL is active)
    PROCEDURE check_bus_id
    IS
    BEGIN
        NULL;
    END check_bus_id;

    -- Source: PU CHK_BUS_ID_BRNCH
    --@ORIG PU CHK_BUS_ID_BRNCH
    -- >>> Original Forms code: PU CHK_BUS_ID_BRNCH
    --   PROCEDURE chk_bus_id_brnch IS
    --   BEGIN
    --       IF :IMPORTERS.BUS_ID_BRNCH = :IMPORTERS.BUS_ID THEN
    --           str.dispalert('غير مسموح بادخال رقم السجل الرئيسي مساوي لرقم السجل الفرعي .. أعد الادخال','error');
    --           RAISE form_trigger_failure ;
    --       END IF;
    --   END;
    -- <<<
    PROCEDURE chk_bus_id_brnch (p_rec IN t_rec)
    IS
    BEGIN
        IF p_rec.bus_id_brnch = p_rec.bus_id THEN
            ftf('غير مسموح بادخال رقم السجل الرئيسي مساوي لرقم السجل الفرعي .. أعد الادخال');
        END IF;
    END chk_bus_id_brnch;

    -- Source: PU CHK_IMPR_DUPL (ELSE branch is commented out in Forms)
    --@ORIG PU CHK_IMPR_DUPL
    -- >>> Original Forms code: PU CHK_IMPR_DUPL
    --   PROCEDURE CHK_IMPR_DUPL IS
    --       V_COUNT NUMBER;
    --       V_IMPR_NAME VARCHAR2(200);
    --         V_IMPR_NBR  NUMBER;
    --   BEGIN
    --       IF :BUS_ID_BRNCH IS NOT NULL THEN
    --           SELECT COUNT(*)
    --           INTO    V_COUNT
    --           FROM  IMPORTERS
    --           WHERE PORT_CD = :IMPORTERS.PORT_CD
    --           AND    CTRY_CD = NVL(:IMPORTERS.CTRY_CD, CTRY_CD)
    --           AND    BUS_ID_TYPE_CD = :IMPORTERS.BUS_ID_TYPE_CD
    --           AND     BUS_ID  = :IMPORTERS.BUS_ID
    --           AND     BUS_ID_BRNCH = :IMPORTERS.BUS_ID_BRNCH
    --           AND        ((:IMPORTERS.IMPR_NBR IS NULL) OR (:IMPORTERS.IMPR_NBR IS NOT NULL AND IMPR_NBR <> :IMPORTERS.IMPR_NBR))
    --           ;
    --           IF V_COUNT > 0 THEN
    --               SELECT ARBC_IMPR_NAME,IMPR_NBR
    --               INTO    V_IMPR_NAME,V_IMPR_NBR
    --               FROM IMPORTERS
    --               WHERE PORT_CD = :IMPORTERS.PORT_CD
    --               AND    CTRY_CD = NVL(:IMPORTERS.CTRY_CD, CTRY_CD)
    --               AND    BUS_ID_TYPE_CD = :IMPORTERS.BUS_ID_TYPE_CD
    --               AND     BUS_ID  = :IMPORTERS.BUS_ID
    --               AND     BUS_ID_BRNCH = :IMPORTERS.BUS_ID_BRNCH
    --               AND        ((:IMPORTERS.IMPR_NBR IS NULL) OR (:IMPORTERS.IMPR_NBR IS NOT NULL AND IMPR_NBR <> :IMPORTERS.IMPR_NBR))
    --                     AND ROWNUM<=1
    --               ;
    --               STR.DISPALERT(' لايمكن الإدخال، يوجد مستورد مدخل بنفس نوع المستورد ونفس الرقم الإستدلالي الرئيسي والفرعي ورقمه:  '||V_IMPR_NBR||' اسمه '||V_IMPR_NAME,'ERROR');
    --               RAISE FORM_TRIGGER_FAILURE;
    --           END IF;
    --         END IF;
    --   END;
    -- <<<
    PROCEDURE chk_impr_dupl (p_rec IN t_rec)
    IS
        v_count     NUMBER;
        v_impr_name VARCHAR2(200);
        v_impr_nbr  NUMBER;
    BEGIN
        IF p_rec.bus_id_brnch IS NOT NULL THEN
            SELECT COUNT(*)
              INTO v_count
              FROM importers
             WHERE port_cd        = p_rec.port_cd
               AND ctry_cd        = NVL(p_rec.ctry_cd, ctry_cd)
               AND bus_id_type_cd = p_rec.bus_id_type_cd
               AND bus_id         = p_rec.bus_id
               AND bus_id_brnch   = p_rec.bus_id_brnch
               AND ((p_rec.impr_nbr IS NULL) OR (p_rec.impr_nbr IS NOT NULL AND impr_nbr <> p_rec.impr_nbr));
            IF v_count > 0 THEN
                SELECT arbc_impr_name, impr_nbr
                  INTO v_impr_name, v_impr_nbr
                  FROM importers
                 WHERE port_cd        = p_rec.port_cd
                   AND ctry_cd        = NVL(p_rec.ctry_cd, ctry_cd)
                   AND bus_id_type_cd = p_rec.bus_id_type_cd
                   AND bus_id         = p_rec.bus_id
                   AND bus_id_brnch   = p_rec.bus_id_brnch
                   AND ((p_rec.impr_nbr IS NULL) OR (p_rec.impr_nbr IS NOT NULL AND impr_nbr <> p_rec.impr_nbr))
                   AND ROWNUM <= 1;
                ftf(' لايمكن الإدخال، يوجد مستورد مدخل بنفس نوع المستورد ونفس الرقم الإستدلالي الرئيسي والفرعي ورقمه:  '
                    || v_impr_nbr || ' اسمه ' || v_impr_name);
            END IF;
        END IF;
    END chk_impr_dupl;

    -- Source: PU CHK_DUPL_IMP_BRKR
    -- Note: Forms passes :BUS_ID twice (4th and 6th argument) - kept as is.
    --@ORIG PU CHK_DUPL_IMP_BRKR
    -- >>> Original Forms code: PU CHK_DUPL_IMP_BRKR
    --   PROCEDURE CHK_DUPL_IMP_BRKR IS
    --       V_VAR_VALUE VARCHAR2(2) := 0;
    --       V_CHK       NUMBER;
    --       V_MSG        VARCHAR2(500);
    --   BEGIN
    --       BEGIN
    --           SELECT VAR_VALUE
    --           INTO V_VAR_VALUE
    --           FROM SC_PORT_SETTING
    --           WHERE SYSOBJ_ID = 9
    --           AND VAR_NAME = 'CHK_DPLCATE_IMP_BRKR'
    --           AND PORT_CD    = :PARAMETER.P_CURR_PORT_CD
    --           ;
    --       EXCEPTION
    --       WHEN NO_DATA_FOUND  THEN
    --           V_VAR_VALUE := 0 ;
    --       END;
    --       IF V_VAR_VALUE = 1 THEN
    --           IF :IMPR_TYPE_CD IN (1,4) THEN
    --           V_CHK := IMPR.CHECK_DUPLICATE_IMP_BRKR(:PORT_CD,1,:IMPR_TYPE_CD,:BUS_ID,:COMM_RGSTRTN_TYPE,:BUS_ID,:BUS_ID_BRNCH,V_MSG);
    --           IF V_CHK = 1 THEN
    --               STR.DISPALERT(V_MSG,'ERROR');
    --               RAISE FORM_TRIGGER_FAILURE;
    --           END IF;
    --         END IF;
    --       END IF;
    --   END;
    -- <<<
    PROCEDURE chk_dupl_imp_brkr (p_rec IN t_rec, p_ctx IN t_ctx)
    IS
        v_var_value VARCHAR2(2) := 0;
        v_chk       NUMBER;
        v_msg       VARCHAR2(500);
    BEGIN
        BEGIN
            SELECT var_value
              INTO v_var_value
              FROM sc_port_setting
             WHERE sysobj_id = 9
               AND var_name  = 'CHK_DPLCATE_IMP_BRKR'
               AND port_cd   = p_ctx.curr_port_cd;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_var_value := 0;
        END;
        IF v_var_value = 1 THEN
            IF p_rec.impr_type_cd IN (1, 4) THEN
                v_chk := impr.check_duplicate_imp_brkr(p_rec.port_cd, 1, p_rec.impr_type_cd, p_rec.bus_id,
                                                       p_rec.comm_rgstrtn_type, p_rec.bus_id,
                                                       p_rec.bus_id_brnch, v_msg);
                IF v_chk = 1 THEN
                    ftf(v_msg);
                END IF;
            END IF;
        END IF;
    END chk_dupl_imp_brkr;

    -- Source: PU CHK_PERSONAL
    -- In Forms the exception handler resets :IMPR_TYPE_CD to :GLOBAL.OLD_IMPR_TYPE_CD before
    -- the failure; p_rec is NOCOPY so the caller still sees the reset value after the error.
    --@ORIG PU CHK_PERSONAL
    -- >>> Original Forms code: PU CHK_PERSONAL
    --   PROCEDURE chk_personal (
    --      P_impr_type_cd   NUMBER,
    --      P_hq_impr_nbr    NUMBER,
    --      P_STOP NUMBER DEFAULT 1)
    --   IS
    --      v_new_type              NUMBER;
    --      v_old_type_personal     NUMBER;
    --      ex_personal_vs_others   EXCEPTION;
    --   BEGIN
    --      v_new_type := P_impr_type_cd;
    --      SELECT COUNT (*)
    --        INTO v_old_type_personal
    --        FROM importers
    --       WHERE hq_impr_nbr = P_hq_impr_nbr AND impr_type_cd = 4
    --   AND PORT_CD    = :PARAMETER.P_CURR_PORT_CD;
    --      IF v_new_type = 4 AND v_old_type_personal = 0
    --      THEN
    --         RAISE ex_personal_vs_others;
    --      END IF;
    --      IF v_new_type <> 4 AND v_old_type_personal > 0
    --      THEN
    --         RAISE ex_personal_vs_others;
    --      END IF;
    --   EXCEPTION
    --      WHEN ex_personal_vs_others
    --      THEN
    --        :impr_type_cd  := :GLOBAL.OLD_impr_type_cd ;
    --        SELECT IMPR_TYPE_NAME
    --        INTO :IMPR_TYPE_NAME
    --        FROM IMPR_TYPES
    --        WHERE IMPR_TYPE_CD = :impr_type_cd ;
    --         STR.DISPALERT('لا يمكن تغيير نوع المستورد من شخصي الي نوع آخر أو العكس , يتم ذلك من خلال الدعم الفني التطبيقات فقط' ,'ERROR');
    --       IF P_STOP = 1 THEN
    --             RAISE form_trigger_failure;
    --       END IF;
    --   END;
    -- <<<
    PROCEDURE chk_personal (p_rec          IN OUT NOCOPY t_rec,
                            p_ctx          IN t_ctx,
                            p_impr_type_cd IN NUMBER,
                            p_hq_impr_nbr  IN NUMBER,
                            p_stop         IN NUMBER DEFAULT 1)
    IS
        v_new_type            NUMBER;
        v_old_type_personal   NUMBER;
        ex_personal_vs_others EXCEPTION;
    BEGIN
        v_new_type := p_impr_type_cd;
        SELECT COUNT(*)
          INTO v_old_type_personal
          FROM importers
         WHERE hq_impr_nbr  = p_hq_impr_nbr
           AND impr_type_cd = 4
           AND port_cd      = p_ctx.curr_port_cd;
        IF v_new_type = 4 AND v_old_type_personal = 0 THEN
            RAISE ex_personal_vs_others;
        END IF;
        IF v_new_type <> 4 AND v_old_type_personal > 0 THEN
            RAISE ex_personal_vs_others;
        END IF;
    EXCEPTION
        WHEN ex_personal_vs_others THEN
            p_rec.impr_type_cd := g_get('OLD_IMPR_TYPE_CD');
            SELECT impr_type_name
              INTO p_rec.impr_type_name
              FROM impr_types
             WHERE impr_type_cd = p_rec.impr_type_cd;
            IF p_stop = 1 THEN
                ftf('لا يمكن تغيير نوع المستورد من شخصي الي نوع آخر أو العكس , يتم ذلك من خلال الدعم الفني التطبيقات فقط');
            ELSE
                info('لا يمكن تغيير نوع المستورد من شخصي الي نوع آخر أو العكس , يتم ذلك من خلال الدعم الفني التطبيقات فقط');
            END IF;
    END chk_personal;

    -- Source: PU INSERT_AUDIT_RECORD
    --@ORIG PU INSERT_AUDIT_RECORD
    -- >>> Original Forms code: PU INSERT_AUDIT_RECORD
    --   PROCEDURE Insert_Audit_Record (V_ACT_TYPE VARCHAR2) IS
    --       Ret NUMBER;
    --       V_ACT_DT DATE;
    --        V_USER_ID  VARCHAR2(11);
    --        v_impr_master_nbr   IMPORTERS.IMPR_MASTER_NBR%TYPE;
    --         v_act_status        IMPORTERS.ACT_STATUS%TYPE;
    --   BEGIN
    --   IF (:IMPORTERS.Impr_Nbr IS NOT NULL) THEN
    --   SELECT SYSDATE INTO V_ACT_DT FROM dual;
    --   V_USER_ID := :PARAMETER.P_USER_ID;
    --                  BEGIN
    --                     SELECT impr_master_nbr, act_status
    --                       INTO v_impr_master_nbr, v_act_status
    --                       FROM IMPORTERS
    --                      WHERE   PORT_CD    = :PARAMETER.P_CURR_PORT_CD
    --                   AND   bus_id_type_cd = :IMPORTERS.BUS_ID_TYPE_CD
    --                            AND bus_id = :IMPORTERS.BUS_ID
    --                            AND bus_id_brnch = :IMPORTERS.bus_id_brnch
    --                            AND impr_type_cd = :IMPORTERS.impr_type_cd
    --                            AND ctry_cd = :IMPORTERS.ctry_cd
    --                            AND ROWNUM = 1;
    --                  EXCEPTION
    --                     WHEN NO_DATA_FOUND
    --                     THEN
    --                        v_impr_master_nbr := NULL;
    --                        v_act_status := NULL;
    --                  END;
    --   INSERT INTO IMPR_UPDTS(Port_Cd, IMPR_NBR, HQ_IMPR_NBR, IMPR_TYPE_CD, BUS_ID_TYPE_CD, BUS_ID , BUS_ID_BRNCH, BUS_ID_EXPRD_DT, CTRY_CD_OF_ID, CITY_CODE_OF_ID, IMPR_EXPR_TYPE, ARBC_IMPR_NAME, ENG_IMPR_NAME, IMPR_NAME_STD, IMPR_NBR_PARENT,
    --                    IMPR_CNTCT_NAME, IMPR_TEL_NBR, IMPR_POB_NBR, IMPR_ZIP_CD, IMPR_FAX_NBR, IMPR_TELEX_NBR,  EMAIL, CTRY_CD, ADD_CTRY_CD, CITY_CODE, LST_TRAN_DT, IMPD_STMT_NBR, IMPR_DATA_SRCE, ACT_DT, ACT_TYPE, USR_ID,COMM_RGSTRTN_TYPE,CAR_AGENT_FLAG,MOBILE_NO,BANK_IBAN, EXPRESS_POST
    --                    ,ID_NBR
    --                          ,BUS_ID_ISSUE_DT,BUS_ID_STATUS,CREATION_FLAG
    --                          ,IMPR_ADDRESS ,impr_master_nbr ,act_status
    --                                         )
    --        VALUES(:IMPORTERS.Port_Cd, :IMPORTERS.IMPR_NBR, :IMPORTERS.HQ_IMPR_NBR, :IMPORTERS.IMPR_TYPE_CD, :IMPORTERS.BUS_ID_TYPE_CD,:IMPORTERS.BUS_ID , :IMPORTERS.BUS_ID_BRNCH, :IMPORTERS.BUS_ID_EXPRD_DT, :IMPORTERS.CTRY_CD_OF_ID, :IMPORTERS.CITY_CODE_OF_ID, :IMPORTERS.IMPR_EXPR_TYPE,:IMPORTERS.ARBC_IMPR_NAME, :IMPORTERS.ENG_IMPR_NAME, :IMPORTERS.IMPR_NAME_STD, :IMPORTERS.IMPR_NBR_PARENT,
    --             :IMPORTERS.IMPR_CNTCT_NAME, :IMPORTERS.IMPR_TEL_NBR, :IMPORTERS.IMPR_POB_NBR, :IMPORTERS.IMPR_ZIP_CD, :IMPORTERS.IMPR_FAX_NBR, :IMPORTERS.IMPR_TELEX_NBR, :IMPORTERS.EMAIL, :IMPORTERS.CTRY_CD, :IMPORTERS.ADD_CTRY_CD, :IMPORTERS.CITY_CODE, :IMPORTERS.LST_TRAN_DT, :IMPORTERS.IMPD_STMT_NBR, :IMPORTERS.IMPR_DATA_SRCE,  V_ACT_DT, V_ACT_TYPE, V_USER_ID,:IMPORTERS.COMM_RGSTRTN_TYPE,
    --             :IMPORTERS.CAR_AGENT_FLAG,:IMPORTERS.MOBILE_NO,:IMPORTERS.BANK_IBAN, :IMPORTERS.EXPRESS_POST
    --             ,:IMPORTERS.ID_NBR
    --                 ,:IMPORTERS.BUS_ID_ISSUE_DT,:IMPORTERS.BUS_ID_STATUS,:IMPORTERS.CREATION_FLAG
    --                 ,:IMPORTERS.IMPR_ADDRESS , v_impr_master_nbr , v_act_status
    --                                           );
    --   ELSE
    --       Ret := STR.DispArbMsg(9, 140,'ERROR');
    --       RAISE FORm_Trigger_Failure;
    --   END IF;
    --   END;
    -- <<<
    PROCEDURE insert_audit_record (p_rec IN t_rec, p_ctx IN t_ctx, v_act_type IN VARCHAR2)
    IS
        v_act_dt            DATE;
        v_user_id           VARCHAR2(11);
        v_impr_master_nbr   importers.impr_master_nbr%TYPE;
        v_act_status        importers.act_status%TYPE;
    BEGIN
        IF (p_rec.impr_nbr IS NOT NULL) THEN
            SELECT SYSDATE INTO v_act_dt FROM dual;
            v_user_id := p_ctx.user_id;
            BEGIN
                SELECT impr_master_nbr, act_status
                  INTO v_impr_master_nbr, v_act_status
                  FROM importers
                 WHERE port_cd        = p_ctx.curr_port_cd
                   AND bus_id_type_cd = p_rec.bus_id_type_cd
                   AND bus_id         = p_rec.bus_id
                   AND bus_id_brnch   = p_rec.bus_id_brnch
                   AND impr_type_cd   = p_rec.impr_type_cd
                   AND ctry_cd        = p_rec.ctry_cd
                   AND ROWNUM = 1;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    v_impr_master_nbr := NULL;
                    v_act_status      := NULL;
            END;
            INSERT INTO impr_updts (
                port_cd, impr_nbr, hq_impr_nbr, impr_type_cd, bus_id_type_cd, bus_id, bus_id_brnch,
                bus_id_exprd_dt, ctry_cd_of_id, city_code_of_id, impr_expr_type, arbc_impr_name,
                eng_impr_name, impr_name_std, impr_nbr_parent, impr_cntct_name, impr_tel_nbr,
                impr_pob_nbr, impr_zip_cd, impr_fax_nbr, impr_telex_nbr, email, ctry_cd, add_ctry_cd,
                city_code, lst_tran_dt, impd_stmt_nbr, impr_data_srce, act_dt, act_type, usr_id,
                comm_rgstrtn_type, car_agent_flag, mobile_no, bank_iban, express_post, id_nbr,
                bus_id_issue_dt, bus_id_status, creation_flag, impr_address, impr_master_nbr, act_status)
            VALUES (
                p_rec.port_cd, p_rec.impr_nbr, p_rec.hq_impr_nbr, p_rec.impr_type_cd, p_rec.bus_id_type_cd,
                p_rec.bus_id, p_rec.bus_id_brnch, p_rec.bus_id_exprd_dt, p_rec.ctry_cd_of_id,
                p_rec.city_code_of_id, p_rec.impr_expr_type, p_rec.arbc_impr_name, p_rec.eng_impr_name,
                p_rec.impr_name_std, p_rec.impr_nbr_parent, p_rec.impr_cntct_name, p_rec.impr_tel_nbr,
                p_rec.impr_pob_nbr, p_rec.impr_zip_cd, p_rec.impr_fax_nbr, p_rec.impr_telex_nbr,
                p_rec.email, p_rec.ctry_cd, p_rec.add_ctry_cd, p_rec.city_code, p_rec.lst_tran_dt,
                p_rec.impd_stmt_nbr, p_rec.impr_data_srce, v_act_dt, v_act_type, v_user_id,
                p_rec.comm_rgstrtn_type, p_rec.car_agent_flag, p_rec.mobile_no, p_rec.bank_iban,
                p_rec.express_post, p_rec.id_nbr, p_rec.bus_id_issue_dt, p_rec.bus_id_status,
                p_rec.creation_flag, p_rec.impr_address, v_impr_master_nbr, v_act_status);
        ELSE
            disp_arb_ftf(9, 140);
        END IF;
    END insert_audit_record;

    -- Source: PU UPDATE_BASIC_IMPORTER
    -- HIGH: Forms ends with STANDARD.COMMIT (commits the whole form transaction in the middle
    -- of POST-INSERT/POST-UPDATE). Removed - APEX commits at the end of page processing.
    --@ORIG PU UPDATE_BASIC_IMPORTER
    -- >>> Original Forms code: PU UPDATE_BASIC_IMPORTER
    --   PROCEDURE UPDATE_BASIC_IMPORTER IS
    --   X NUMBER;
    --   BEGIN
    --   SELECT COUNT(*) INTO X FROM IMPORTER_BASIC_DATA
    --   WHERE  BUS_ID=:BUS_ID AND BUS_ID_BRNCH = NVL(:BUS_ID_BRNCH,0)
    --   AND IMPR_TYPE_CD=:IMPR_TYPE_CD AND BUS_ID_TYPE_CD = :BUS_ID_TYPE_CD;
    --   IF X = 0 THEN
    --   INSERT INTO IMPORTER_BASIC_DATA
    --      (BUS_ID, BUS_ID_BRNCH,
    --       IMPR_TYPE_CD, BUS_ID_TYPE_CD, MOBILE_NO, EMAIL,ID_NBR,HQ_IMPR_NBR)
    --    VALUES
    --     (:BUS_ID, NVL(:BUS_ID_BRNCH,0),
    --       :IMPR_TYPE_CD, :BUS_ID_TYPE_CD, :B_MOBILE_NO,:B_EMAIL,:B_ID_NBR,:HQ_IMPR_NBR);
    --   ELSE
    --   UPDATE IMPORTER_BASIC_DATA SET MOBILE_NO=NVL(:IMPORTERS.B_MOBILE_NO,MOBILE_NO),
    --       EMAIL=NVL(:IMPORTERS.B_EMAIL,EMAIL),
    --       ID_NBR=NVL(:IMPORTERS.B_ID_NBR,ID_NBR),
    --       HQ_IMPR_NBR=NVL(:HQ_IMPR_NBR,HQ_IMPR_NBR)
    --   WHERE  BUS_ID=:BUS_ID AND NVL(BUS_ID_BRNCH,0) = NVL(:BUS_ID_BRNCH,0)
    --   AND IMPR_TYPE_CD=:IMPR_TYPE_CD AND BUS_ID_TYPE_CD = :BUS_ID_TYPE_CD;
    --   END IF;
    --   STANDARD.COMMIT;
    --   END;
    -- <<<
    PROCEDURE update_basic_importer (p_rec IN t_rec)
    IS
        x NUMBER;
    BEGIN
        SELECT COUNT(*) INTO x
          FROM importer_basic_data
         WHERE bus_id         = p_rec.bus_id
           AND bus_id_brnch   = NVL(p_rec.bus_id_brnch, 0)
           AND impr_type_cd   = p_rec.impr_type_cd
           AND bus_id_type_cd = p_rec.bus_id_type_cd;
        IF x = 0 THEN
            INSERT INTO importer_basic_data
                (bus_id, bus_id_brnch, impr_type_cd, bus_id_type_cd, mobile_no, email, id_nbr, hq_impr_nbr)
            VALUES
                (p_rec.bus_id, NVL(p_rec.bus_id_brnch, 0), p_rec.impr_type_cd, p_rec.bus_id_type_cd,
                 p_rec.b_mobile_no, p_rec.b_email, p_rec.b_id_nbr, p_rec.hq_impr_nbr);
        ELSE
            UPDATE importer_basic_data
               SET mobile_no   = NVL(p_rec.b_mobile_no, mobile_no),
                   email       = NVL(p_rec.b_email, email),
                   id_nbr      = NVL(p_rec.b_id_nbr, id_nbr),
                   hq_impr_nbr = NVL(p_rec.hq_impr_nbr, hq_impr_nbr)
             WHERE bus_id               = p_rec.bus_id
               AND NVL(bus_id_brnch, 0) = NVL(p_rec.bus_id_brnch, 0)
               AND impr_type_cd         = p_rec.impr_type_cd
               AND bus_id_type_cd       = p_rec.bus_id_type_cd;
        END IF;
        -- STANDARD.COMMIT;   -- removed, see header
    END update_basic_importer;

    -- Source: PU RETURN_IMPR_ID
    --@ORIG PU RETURN_IMPR_ID
    -- >>> Original Forms code: PU RETURN_IMPR_ID
    --   PROCEDURE RETURN_IMPR_ID IS
    --   BEGIN
    --   IF    :PARAMETER.P_USER_TYPE = 2 AND :PARAMETER.P_CLASS_CD = 23 THEN
    --   :GLOBAL.IMPR_NBR_B:=:IMPR_NBR;
    --   :GLOBAL.IMPR_NAME_B:=:ARBC_IMPR_NAME;
    --   END IF ;
    --   END;
    -- <<<
    PROCEDURE return_impr_id (p_rec IN t_rec, p_ctx IN t_ctx)
    IS
    BEGIN
        IF p_ctx.user_type = 2 AND p_ctx.class_cd = 23 THEN
            g_set('IMPR_NBR_B', p_rec.impr_nbr);
            g_set('IMPR_NAME_B', p_rec.arbc_impr_name);
        END IF;
    END return_impr_id;

    -- Source: PU BROKER_INT
    --@ORIG PU BROKER_INT
    -- >>> Original Forms code: PU BROKER_INT
    --   PROCEDURE BROKER_INT IS
    --   BEGIN
    --   :IMPR_EXPR_TYPE:=1;
    --   :EXPRESS_POST:=2;
    --   SET_ITEM_PROPERTY('IMPR_EXPR_TYPE',ENABLED,PROPERTY_FALSE);
    --   SET_ITEM_PROPERTY('EXPRESS_POST',ENABLED,PROPERTY_FALSE);
    --   END;
    -- <<<
    PROCEDURE broker_int (p_rec IN OUT NOCOPY t_rec)
    IS
    BEGIN
        p_rec.impr_expr_type := 1;
        p_rec.express_post   := 2;
        ui('IMPR_EXPR_TYPE', 'ENABLED', FALSE);
        ui('EXPRESS_POST', 'ENABLED', FALSE);
    END broker_int;

    -- Source: PU ADJ_FUNS (TMPLT function menu -> fun() recorder; APEX: button/menu conditions)
    --@ORIG PU ADJ_FUNS
    -- >>> Original Forms code: PU ADJ_FUNS
    --   PROCEDURE ADJ_FUNS IS
    --       V_COUNT     NUMBER := 0;
    --       V_ROL_CNT NUMBER;
    --   BEGIN
    --       IF   :PARAMETER.P_CLASS_CD=1 AND :PARAMETER.P_USER_TYPE=3 AND :IMPR_NBR IS NOT NULL THEN
    --           NULL;
    --       ELSE
    --           TMPLT.DISABLE_FUN('CREATE_BRKR_IMPR_AUTH');
    --       END IF;  -- HATEM 6-9-2015
    --       IF :PARAMETER.P_CLASS_CD = 19 AND :PARAMETER.P_USER_TYPE = 1 THEN
    --           SELECT COUNT(*) INTO V_ROL_CNT
    --           FROM   SC_USER_ROLES
    --           WHERE PORT_CD    = :PARAMETER.P_CURR_PORT_CD
    --           and USER_ID = :PARAMETER.P_USER_ID
    --           AND    ROLE_ID = 'IMPR_UPD'
    --           ;
    --           IF V_ROL_CNT > 0 AND :IMPR_TYPE_CD = 1  THEN
    --               TMPLT.ENABLE_FUN('IMPR1110F3');
    --           ELSE
    --               TMPLT.DISABLE_FUN('IMPR1110F3');
    --           END IF;
    --       END IF;
    --   IF (NVL(:BUS_ID_TYPE_CD,0) = 2  AND :GLOBAL.ALLOW_MCI = 1 AND :IMPR_TYPE_CD <>12)OR (:IMPR_TYPE_CD = 4 AND :BUS_ID_TYPE_CD IN (3, 5) AND :GLOBAL.ALLOW_MOI = 1  )THEN
    --    TMPLT.ENABLE_FUN('IMPR_MCI_SERVICE');
    --   ELSE
    --    TMPLT.DISABLE_FUN('IMPR_MCI_SERVICE');
    --   END IF;
    --   TMPLT.DISABLE_FUN('IMPR1110F2');
    --        IF :PARAMETER.P_CURR_PORT_CD <> 99 THEN
    --          TMPLT.DISABLE_FUN('IMPR1110_MOB');
    --        END IF;
    --   EXCEPTION
    --       WHEN OTHERS THEN NULL;
    --   END;
    -- <<<
    PROCEDURE adj_funs (p_rec IN t_rec, p_ctx IN t_ctx)
    IS
        v_rol_cnt NUMBER;
    BEGIN
        IF p_ctx.class_cd = 1 AND p_ctx.user_type = 3 AND p_rec.impr_nbr IS NOT NULL THEN
            NULL;
        ELSE
            fun('CREATE_BRKR_IMPR_AUTH', FALSE);
        END IF;
        IF p_ctx.class_cd = 19 AND p_ctx.user_type = 1 THEN
            SELECT COUNT(*) INTO v_rol_cnt
              FROM sc_user_roles
             WHERE port_cd = p_ctx.curr_port_cd
               AND user_id = p_ctx.user_id
               AND role_id = 'IMPR_UPD';
            IF v_rol_cnt > 0 AND p_rec.impr_type_cd = 1 THEN
                fun('IMPR1110F3', TRUE);
            ELSE
                fun('IMPR1110F3', FALSE);
            END IF;
        END IF;
        IF (NVL(p_rec.bus_id_type_cd, 0) = 2 AND g_get('ALLOW_MCI') = '1' AND p_rec.impr_type_cd <> 12)
           OR (p_rec.impr_type_cd = 4 AND p_rec.bus_id_type_cd IN (3, 5) AND g_get('ALLOW_MOI') = '1') THEN
            fun('IMPR_MCI_SERVICE', TRUE);
        ELSE
            fun('IMPR_MCI_SERVICE', FALSE);
        END IF;
        fun('IMPR1110F2', FALSE);
        IF p_ctx.curr_port_cd <> 99 THEN
            fun('IMPR1110_MOB', FALSE);
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END adj_funs;

    -- Source: PU GET_CR_DATA (Ministry of Commerce reply "f1|f2|...|f16")
    -- Converted 1:1; the 17 INSTR/SUBSTR statements are written as a loop (same result).
    --@ORIG PU GET_CR_DATA
    -- >>> Original Forms code: PU GET_CR_DATA
    --   PROCEDURE get_cr_data (p_string_result VARCHAR2, p_type VARCHAR2)
    --   IS
    --      FOUND               NUMBER;
    --      string_result       VARCHAR2 (5000);
    --      v_pos_1             NUMBER;
    --      v_pos_2             NUMBER;
    --      v_pos_3             NUMBER;
    --      v_pos_4             NUMBER;
    --      v_pos_5             NUMBER;
    --      v_pos_6             NUMBER;
    --      v_pos_7             NUMBER;
    --      v_pos_8             NUMBER;
    --      v_pos_9             NUMBER;
    --      v_pos_10            NUMBER;
    --      v_pos_11            NUMBER;
    --      v_pos_12            NUMBER;
    --      v_pos_13            NUMBER;
    --      v_pos_14            NUMBER;
    --      v_pos_15            NUMBER;
    --      v_pos_16            NUMBER;
    --      v_pos_17            NUMBER;
    --      v_pos_18            NUMBER;
    --      v_pos_19            NUMBER;
    --      v_pos_20            NUMBER;
    --      v_pos_21            NUMBER;
    --      v_txt_1             VARCHAR2 (500);
    --      v_txt_2             VARCHAR2 (500);
    --      v_txt_3             VARCHAR2 (500);
    --      v_txt_4             VARCHAR2 (500);
    --      v_txt_5             VARCHAR2 (500);
    --      v_txt_6             VARCHAR2 (500);
    --      v_txt_7             VARCHAR2 (500);
    --      v_txt_8             VARCHAR2 (500);
    --      v_txt_9             VARCHAR2 (500);
    --      v_txt_10            VARCHAR2 (500);
    --      v_txt_11            VARCHAR2 (500);
    --      v_txt_12            VARCHAR2 (500);
    --      v_txt_13            VARCHAR2 (500);
    --      v_txt_14            VARCHAR2 (500);
    --      v_txt_15            VARCHAR2 (500);
    --      v_txt_16            VARCHAR2 (500);
    --      v_txt_17            VARCHAR2 (500);
    --      v_txt_18            VARCHAR2 (500);
    --      v_txt_19            VARCHAR2 (500);
    --      v_txt_20            VARCHAR2 (500);
    --      v_txt_21            VARCHAR2 (500);
    --      v_bus_id_exprd_dt   importers.bus_id_exprd_dt%TYPE;
    --      v_bus_id_issue_dt   importers.bus_id_issue_dt%TYPE;
    --      v_arbc_impr_name    importers.arbc_impr_name%TYPE;
    --      v_impr_name_std     importers.impr_name_std%TYPE;
    --      v_impr_address      importers.impr_address%TYPE;
    --      v_impr_tel_nbr      importers.impr_tel_nbr%TYPE;
    --      v_impr_fax_nbr      importers.impr_fax_nbr%TYPE;
    --      v_impr_telex_nbr    importers.impr_telex_nbr%TYPE;
    --      v_activity          importers.activity%TYPE;
    --      v_bus_id_status     importers.bus_id_status%TYPE;
    --      v_city_code_of_id   importers.city_code_of_id%TYPE;
    --      v_port_cd           importers.port_cd%TYPE;
    --      v_impr_nbr          importers.impr_nbr%TYPE;
    --      v_hq_impr_nbr       importers.hq_impr_nbr%TYPE;
    --      v_bus_id            importers.bus_id%TYPE;
    --      v_bus_id_brnch      importers.bus_id_brnch%TYPE;
    --   BEGIN
    --      str.dispalert
    --         ('سيتم الحصول على بيانات المستورد من وزارة التجارة.....الرجاء الإنتظار',
    --          'ERROR'
    --         );
    --      string_result := p_string_result;
    --      IF string_result IS NOT NULL
    --      THEN
    --         string_result :=
    --               LTRIM (RTRIM (string_result))
    --            || ' |'
    --            || ' |'
    --            || ' |'
    --            || ' |'
    --            || ' |'
    --            || ' |'
    --            || ' |'
    --            || ' |'
    --            || ' |'
    --            || ' |'
    --            || ' |'
    --            || ' |'
    --            || ' |'
    --            || ' |'
    --            || ' |'
    --            || ' |'
    --            || ' |'
    --            || ' |'
    --            || ' |'
    --            || ' |'
    --            || ' |'
    --            || ' |';
    --         SELECT INSTR (string_result, '|', 1)
    --           INTO v_pos_1
    --           FROM DUAL;
    --         SELECT INSTR (string_result, '|', 1 + v_pos_1)
    --           INTO v_pos_2
    --           FROM DUAL;
    --         SELECT INSTR (string_result, '|', 1 + v_pos_2)
    --           INTO v_pos_3
    --           FROM DUAL;
    --         SELECT INSTR (string_result, '|', 1 + v_pos_3)
    --           INTO v_pos_4
    --           FROM DUAL;
    --         SELECT INSTR (string_result, '|', 1 + v_pos_4)
    --           INTO v_pos_5
    --           FROM DUAL;
    --         SELECT INSTR (string_result, '|', 1 + v_pos_5)
    --           INTO v_pos_6
    --           FROM DUAL;
    --         SELECT INSTR (string_result, '|', 1 + v_pos_6)
    --           INTO v_pos_7
    --           FROM DUAL;
    --         SELECT INSTR (string_result, '|', 1 + v_pos_7)
    --           INTO v_pos_8
    --           FROM DUAL;
    --         SELECT INSTR (string_result, '|', 1 + v_pos_8)
    --           INTO v_pos_9
    --           FROM DUAL;
    --         SELECT INSTR (string_result, '|', 1 + v_pos_9)
    --           INTO v_pos_10
    --           FROM DUAL;
    --         SELECT INSTR (string_result, '|', 1 + v_pos_10)
    --           INTO v_pos_11
    --           FROM DUAL;
    --         SELECT INSTR (string_result, '|', 1 + v_pos_11)
    --           INTO v_pos_12
    --           FROM DUAL;
    --         SELECT INSTR (string_result, '|', 1 + v_pos_12)
    --           INTO v_pos_13
    --           FROM DUAL;
    --         SELECT INSTR (string_result, '|', 1 + v_pos_13)
    --           INTO v_pos_14
    --           FROM DUAL;
    --         SELECT INSTR (string_result, '|', 1 + v_pos_14)
    --           INTO v_pos_15
    --           FROM DUAL;
    --         SELECT INSTR (string_result, '|', 1 + v_pos_15)
    --           INTO v_pos_16
    --           FROM DUAL;
    --         SELECT INSTR (string_result, '|', 1 + v_pos_16)
    --           INTO v_pos_17
    --           FROM DUAL;
    --         v_txt_1 :=
    --                 UPPER (LTRIM (RTRIM (SUBSTR (string_result, 1, v_pos_1 - (1)))));
    --         v_txt_2 :=
    --            UPPER (LTRIM (RTRIM (SUBSTR (string_result,
    --                                         v_pos_1 + 1,
    --                                         v_pos_2 - (v_pos_1 + 1)
    --                                        )
    --                                )
    --                         )
    --                  );
    --         v_txt_3 :=
    --            UPPER (LTRIM (RTRIM (SUBSTR (string_result,
    --                                         v_pos_2 + 1,
    --                                         v_pos_3 - (v_pos_2 + 1)
    --                                        )
    --                                )
    --                         )
    --                  );
    --         v_txt_4 :=
    --            UPPER (LTRIM (RTRIM (SUBSTR (string_result,
    --                                         v_pos_3 + 1,
    --                                         v_pos_4 - (v_pos_3 + 1)
    --                                        )
    --                                )
    --                         )
    --                  );
    --         v_txt_5 :=
    --            UPPER (LTRIM (RTRIM (SUBSTR (string_result,
    --                                         v_pos_4 + 1,
    --                                         v_pos_5 - (v_pos_4 + 1)
    --                                        )
    --                                )
    --                         )
    --                  );
    --         v_txt_6 :=
    --            UPPER (LTRIM (RTRIM (SUBSTR (string_result,
    --                                         v_pos_5 + 1,
    --                                         v_pos_6 - (v_pos_5 + 1)
    --                                        )
    --                                )
    --                         )
    --                  );
    --         v_txt_7 :=
    --            UPPER (LTRIM (RTRIM (SUBSTR (string_result,
    --                                         v_pos_6 + 1,
    --                                         v_pos_7 - (v_pos_6 + 1)
    --                                        )
    --                                )
    --                         )
    --                  );
    --         v_txt_8 :=
    --            UPPER (LTRIM (RTRIM (SUBSTR (string_result,
    --                                         v_pos_7 + 1,
    --                                         v_pos_8 - (v_pos_7 + 1)
    --                                        )
    --                                )
    --                         )
    --                  );
    --         v_txt_9 :=
    --            UPPER (LTRIM (RTRIM (SUBSTR (string_result,
    --                                         v_pos_8 + 1,
    --                                         v_pos_9 - (v_pos_8 + 1)
    --                                        )
    --                                )
    --                         )
    --                  );
    --         v_txt_10 :=
    --            UPPER (LTRIM (RTRIM (SUBSTR (string_result,
    --                                         v_pos_9 + 1,
    --                                         v_pos_10 - (v_pos_9 + 1)
    --                                        )
    --                                )
    --                         )
    --                  );
    --         v_txt_11 :=
    --            UPPER (LTRIM (RTRIM (SUBSTR (string_result,
    --                                         v_pos_10 + 1,
    --                                         v_pos_11 - (v_pos_10 + 1)
    --                                        )
    --                                )
    --                         )
    --                  );
    --         v_txt_12 :=
    --            UPPER (LTRIM (RTRIM (SUBSTR (string_result,
    --                                         v_pos_11 + 1,
    --                                         v_pos_12 - (v_pos_11 + 1)
    --                                        )
    --                                )
    --                         )
    --                  );
    --         v_txt_13 :=
    --            UPPER (LTRIM (RTRIM (SUBSTR (string_result,
    --                                         v_pos_12 + 1,
    --                                         v_pos_13 - (v_pos_12 + 1)
    --                                        )
    --                                )
    --                         )
    --                  );
    --         v_txt_14 :=
    --            UPPER (LTRIM (RTRIM (SUBSTR (string_result,
    --                                         v_pos_13 + 1,
    --                                         v_pos_14 - (v_pos_13 + 1)
    --                                        )
    --                                )
    --                         )
    --                  );
    --         v_txt_15 :=
    --            UPPER (LTRIM (RTRIM (SUBSTR (string_result,
    --                                         v_pos_14 + 1,
    --                                         v_pos_15 - (v_pos_14 + 1)
    --                                        )
    --                                )
    --                         )
    --                  );
    --         v_txt_16 :=
    --            UPPER (LTRIM (RTRIM (SUBSTR (string_result,
    --                                         v_pos_15 + 1,
    --                                         v_pos_16 - (v_pos_15 + 1)
    --                                        )
    --                                )
    --                         )
    --                  );
    --         IF v_txt_1 IS NOT NULL
    --         THEN
    --            v_bus_id_exprd_dt := TO_DATE (v_txt_3, 'MI-MM-YYYY');
    --            v_bus_id_issue_dt := TO_DATE (v_txt_4, 'MI-MM-YYYY');
    --            v_arbc_impr_name := v_txt_6;
    --            v_impr_address := v_txt_8;
    --            IF v_txt_9 > '0000000'
    --            THEN
    --               v_impr_tel_nbr := v_txt_9;
    --            ELSIF v_txt_10 > '0000000'
    --            THEN
    --               v_impr_tel_nbr := v_txt_10;
    --            END IF;
    --            IF v_txt_11 > '0000000'
    --            THEN
    --               v_impr_fax_nbr := v_txt_11;
    --            ELSIF v_txt_12 > '0000000'
    --            THEN
    --               v_impr_fax_nbr := v_txt_12;
    --            END IF;
    --            v_impr_telex_nbr := v_txt_13;
    --            v_activity := v_txt_14;
    --            IF UPPER (v_txt_15) = 'ACTIVE'
    --            THEN
    --               v_bus_id_status := 1;
    --            ELSIF UPPER (v_txt_15) = 'EXPIRED'
    --            THEN
    --               v_bus_id_status := 2;
    --            ELSIF UPPER (v_txt_15) = 'SUSPENDED'
    --            THEN
    --               v_bus_id_status := 3;
    --            ELSIF UPPER (v_txt_15) LIKE 'WRITTEN%OFF'
    --            THEN
    --               v_bus_id_status := 4;
    --            ELSIF UPPER (v_txt_15) LIKE 'CANCELLED'
    --            THEN
    --               v_bus_id_status := 4;
    --            ELSE
    --               v_bus_id_status := 5;
    --            END IF;
    --            BEGIN
    --               SELECT city_cd
    --                 INTO v_city_code_of_id
    --                 FROM cities
    --                WHERE mins_comm_cd = v_txt_16;
    --            EXCEPTION
    --               WHEN OTHERS
    --               THEN
    --                  NULL;
    --            END;
    --            v_impr_name_std := str_db.strformat (v_arbc_impr_name);
    --            :importers.bus_id_exprd_dt := v_bus_id_exprd_dt;
    --            :importers.bus_id_issue_dt := v_bus_id_issue_dt;
    --            :importers.arbc_impr_name := v_arbc_impr_name;
    --            :importers.impr_name_std := v_impr_name_std;
    --            :importers.impr_address := v_impr_address;
    --            :importers.impr_tel_nbr := v_impr_tel_nbr;
    --            :importers.impr_fax_nbr := v_impr_fax_nbr;
    --            :importers.impr_telex_nbr := v_impr_telex_nbr;
    --            :importers.activity := v_activity;
    --            :importers.bus_id_status := v_bus_id_status;
    --            :importers.lst_tran_dt := SYSDATE;
    --            :importers.creation_flag := 3;
    --            IF p_type = 'B'
    --            THEN
    --               :importers.brnh_city_cd := v_city_code_of_id;
    --               BEGIN
    --                  SELECT city_arb_name
    --                    INTO :importers.brnh_city_name
    --                    FROM cities
    --                   WHERE city_cd = :importers.brnh_city_cd
    --                     AND ctry_cd = :ctry_cd_of_id;
    --               EXCEPTION
    --                  WHEN OTHERS
    --                  THEN
    --                     NULL;
    --               END;
    --            ELSIF p_type = 'M'
    --            THEN
    --               :importers.city_code_of_id := v_city_code_of_id;
    --               BEGIN
    --                  SELECT city_arb_name
    --                    INTO :importers.id_city_name
    --                    FROM cities
    --                   WHERE city_cd = :importers.city_code_of_id
    --                     AND ctry_cd = :ctry_cd_of_id;
    --               EXCEPTION
    --                  WHEN OTHERS
    --                  THEN
    --                     NULL;
    --               END;
    --            END IF;
    --         END IF;
    --      END IF;
    --   END;
    -- <<<
    PROCEDURE get_cr_data (p_rec           IN OUT NOCOPY t_rec,
                           p_string_result IN VARCHAR2,
                           p_type          IN VARCHAR2)
    IS
        TYPE t_num_tab IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
        string_result      VARCHAR2(5000);
        v_pos              t_num_tab;
        v_txt              t_vc_tab;
        v_bus_id_exprd_dt  importers.bus_id_exprd_dt%TYPE;
        v_bus_id_issue_dt  importers.bus_id_issue_dt%TYPE;
        v_arbc_impr_name   importers.arbc_impr_name%TYPE;
        v_impr_name_std    importers.impr_name_std%TYPE;
        v_impr_address     importers.impr_address%TYPE;
        v_impr_tel_nbr     importers.impr_tel_nbr%TYPE;
        v_impr_fax_nbr     importers.impr_fax_nbr%TYPE;
        v_impr_telex_nbr   importers.impr_telex_nbr%TYPE;
        v_activity         importers.activity%TYPE;
        v_bus_id_status    importers.bus_id_status%TYPE;
        v_city_code_of_id  importers.city_code_of_id%TYPE;
    BEGIN
        info('سيتم الحصول على بيانات المستورد من وزارة التجارة.....الرجاء الإنتظار');
        string_result := p_string_result;
        IF string_result IS NOT NULL THEN
            string_result := LTRIM(RTRIM(string_result));
            FOR i IN 1 .. 22 LOOP
                string_result := string_result || ' |';
            END LOOP;
            v_pos(0) := 0;
            FOR i IN 1 .. 17 LOOP
                v_pos(i) := INSTR(string_result, '|', 1 + v_pos(i - 1));
            END LOOP;
            v_txt(1) := UPPER(LTRIM(RTRIM(SUBSTR(string_result, 1, v_pos(1) - (1)))));
            FOR i IN 2 .. 16 LOOP
                v_txt(i) := UPPER(LTRIM(RTRIM(SUBSTR(string_result, v_pos(i - 1) + 1,
                                                     v_pos(i) - (v_pos(i - 1) + 1)))));
            END LOOP;
            IF v_txt(1) IS NOT NULL THEN
                v_bus_id_exprd_dt := TO_DATE(v_txt(3), 'MI-MM-YYYY');
                v_bus_id_issue_dt := TO_DATE(v_txt(4), 'MI-MM-YYYY');
                v_arbc_impr_name  := v_txt(6);
                v_impr_address    := v_txt(8);
                IF v_txt(9) > '0000000' THEN
                    v_impr_tel_nbr := v_txt(9);
                ELSIF v_txt(10) > '0000000' THEN
                    v_impr_tel_nbr := v_txt(10);
                END IF;
                IF v_txt(11) > '0000000' THEN
                    v_impr_fax_nbr := v_txt(11);
                ELSIF v_txt(12) > '0000000' THEN
                    v_impr_fax_nbr := v_txt(12);
                END IF;
                v_impr_telex_nbr := v_txt(13);
                v_activity       := v_txt(14);
                IF UPPER(v_txt(15)) = 'ACTIVE' THEN
                    v_bus_id_status := 1;
                ELSIF UPPER(v_txt(15)) = 'EXPIRED' THEN
                    v_bus_id_status := 2;
                ELSIF UPPER(v_txt(15)) = 'SUSPENDED' THEN
                    v_bus_id_status := 3;
                ELSIF UPPER(v_txt(15)) LIKE 'WRITTEN%OFF' THEN
                    v_bus_id_status := 4;
                ELSIF UPPER(v_txt(15)) LIKE 'CANCELLED' THEN
                    v_bus_id_status := 4;
                ELSE
                    v_bus_id_status := 5;
                END IF;
                BEGIN
                    SELECT city_cd
                      INTO v_city_code_of_id
                      FROM cities
                     WHERE mins_comm_cd = v_txt(16);
                EXCEPTION
                    WHEN OTHERS THEN
                        NULL;
                END;
                v_impr_name_std := str_db.strformat(v_arbc_impr_name);
                p_rec.bus_id_exprd_dt := v_bus_id_exprd_dt;
                p_rec.bus_id_issue_dt := v_bus_id_issue_dt;
                p_rec.arbc_impr_name  := v_arbc_impr_name;
                p_rec.impr_name_std   := v_impr_name_std;
                p_rec.impr_address    := v_impr_address;
                p_rec.impr_tel_nbr    := v_impr_tel_nbr;
                p_rec.impr_fax_nbr    := v_impr_fax_nbr;
                p_rec.impr_telex_nbr  := v_impr_telex_nbr;
                p_rec.activity        := v_activity;
                p_rec.bus_id_status   := v_bus_id_status;
                p_rec.lst_tran_dt     := SYSDATE;
                p_rec.creation_flag   := 3;
                IF p_type = 'B' THEN
                    p_rec.brnh_city_cd := v_city_code_of_id;
                    BEGIN
                        SELECT city_arb_name
                          INTO p_rec.brnh_city_name
                          FROM cities
                         WHERE city_cd = p_rec.brnh_city_cd
                           AND ctry_cd = p_rec.ctry_cd_of_id;
                    EXCEPTION
                        WHEN OTHERS THEN
                            NULL;
                    END;
                ELSIF p_type = 'M' THEN
                    p_rec.city_code_of_id := v_city_code_of_id;
                    BEGIN
                        SELECT city_arb_name
                          INTO p_rec.id_city_name
                          FROM cities
                         WHERE city_cd = p_rec.city_code_of_id
                           AND ctry_cd = p_rec.ctry_cd_of_id;
                    EXCEPTION
                        WHEN OTHERS THEN
                            NULL;
                    END;
                END IF;
            END IF;
        END IF;
    END get_cr_data;

    -- Source: PU GET_MAIN_CR_DATA
    --@ORIG PU GET_MAIN_CR_DATA
    -- >>> Original Forms code: PU GET_MAIN_CR_DATA
    --   PROCEDURE get_main_cr_data IS
    --   STRING_RESULT VARCHAR2(5000);
    --   BEGIN
    --       SELECT MCISERVICE.getMainCRInfoCall ( :importers.bus_id , 'MCIService')
    --       INTO STRING_RESULT
    --       FROM DUAL;
    --       get_cr_data(STRING_RESULT,'M');
    --   EXCEPTION
    --       WHEN OTHERS THEN NULL;
    --   END;
    -- <<<
    PROCEDURE get_main_cr_data (p_rec IN OUT NOCOPY t_rec)
    IS
        string_result VARCHAR2(5000);
    BEGIN
        SELECT mciservice.getmaincrinfocall(p_rec.bus_id, 'MCIService')
          INTO string_result
          FROM dual;
        get_cr_data(p_rec, string_result, 'M');
    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END get_main_cr_data;

    -- Source: PU GET_BRANCH_CR_DATA
    --@ORIG PU GET_BRANCH_CR_DATA
    -- >>> Original Forms code: PU GET_BRANCH_CR_DATA
    --   PROCEDURE get_branch_cr_data IS
    --   STRING_RESULT VARCHAR2(5000);
    --   BEGIN
    --       SELECT MCISERVICE.getBranchCRInfoCall ( :importers.bus_id_brnch , 'MCIService')
    --       INTO STRING_RESULT
    --       FROM DUAL;
    --       get_cr_data(STRING_RESULT,'B');
    --   EXCEPTION
    --       WHEN OTHERS THEN NULL;
    --   END;
    -- <<<
    PROCEDURE get_branch_cr_data (p_rec IN OUT NOCOPY t_rec)
    IS
        string_result VARCHAR2(5000);
    BEGIN
        SELECT mciservice.getbranchcrinfocall(p_rec.bus_id_brnch, 'MCIService')
          INTO string_result
          FROM dual;
        get_cr_data(p_rec, string_result, 'B');
    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END get_branch_cr_data;

    -- Source: PU CREATE_BRKR_IMPR_AUTH
    -- HIGH: STANDARD.COMMIT removed (APEX commits). Message and globals are set for both user
    -- groups exactly as in Forms (the INSERT only for class 1 / user type 3).
    --@ORIG PU CREATE_BRKR_IMPR_AUTH
    -- >>> Original Forms code: PU CREATE_BRKR_IMPR_AUTH
    --   PROCEDURE CREATE_BRKR_IMPR_AUTH IS
    --   BEGIN
    --   IF (:PARAMETER.P_CLASS_CD = 1 AND :PARAMETER.P_USER_TYPE = 3)
    --       OR
    --      (:PARAMETER.P_USER_TYPE = 2 AND :PARAMETER.P_CLASS_CD = 23) THEN
    --   DECLARE
    --   V_ATHRZTN_SEQ_NBR NUMBER;
    --   BEGIN
    --   IF (:PARAMETER.P_CLASS_CD = 1 AND :PARAMETER.P_USER_TYPE = 3) THEN
    --   V_ATHRZTN_SEQ_NBR := GNRL.GET_CUSTOMS_SEQ(:PARAMETER.P_CURR_PORT_CD,'BRKIMPS_AUTH_SEQ');
    --   INSERT INTO BRKIMPS(
    --                   PORT_CD,
    --                   ATHRZTN_SEQ_NBR,
    --                   IMPR_NBR,
    --                   PORT_CD_BRKR,
    --                   LIC_TYPE,
    --                       LIC_NBR,
    --                       ALLOW_EXPORT,
    --                       ATHRZTN_LETR_NBR,
    --                       ATHRZTN_LETR_DT,
    --                       ATHRZTN_TYPE_CD,
    --                       ATHRZTN_STRT_DT,
    --                       ATHRZTN_END_DT,
    --                       NOTE,
    --                       ATHRZTN_USG_NBR,
    --                       ATHRZTN_LAST_USG_DT,
    --                       ATHRZTN_CNCLD_DT)
    --               VALUES(:PORT_CD,
    --                   V_ATHRZTN_SEQ_NBR,
    --                   :IMPR_NBR,
    --                   :PARAMETER.P_BRKR_PORT_CD,
    --                   :PARAMETER.P_LIC_TYPE,
    --                   :PARAMETER.P_BRKR_NBR,
    --                   1,
    --                   'تفويض الي ',
    --                   HIJDATE_DB.CUR_HIJ_DATE,
    --                   1,
    --                   NULL,
    --                   NULL,
    --                   'تفويض بريد سريع',
    --                   0,
    --                   HIJDATE_DB.CUR_HIJ_DATE,
    --                   NULL);
    --    IF NOT ACTIVITY.ADD_ACTIVITY(9, 2, 6, :IMPORTERS.Port_Cd||'!'||:IMPORTERS.Impr_Nbr) THEN
    --           RAISE FORm_Trigger_Failure;
    --    END IF;
    --   end if;
    --   STANDARD.COMMIT;
    --   STR.DISPALERT('تم أنشاء التفويض','CFG_INFORMATION');
    --   :GLOBAL.IMPR_NBR_B:=:IMPR_NBR;
    --   :GLOBAL.IMPR_NAME_B:=:ARBC_IMPR_NAME;
    --   :GLOBAL.BRKR_ATHRZTN_NBR_B:=V_ATHRZTN_SEQ_NBR;
    --   END;
    --   END IF;
    --   END;
    -- <<<
    PROCEDURE create_brkr_impr_auth (p_rec IN t_rec, p_ctx IN t_ctx)
    IS
        v_athrztn_seq_nbr NUMBER;
    BEGIN
        IF (p_ctx.class_cd = 1 AND p_ctx.user_type = 3)
           OR (p_ctx.user_type = 2 AND p_ctx.class_cd = 23) THEN
            IF (p_ctx.class_cd = 1 AND p_ctx.user_type = 3) THEN
                v_athrztn_seq_nbr := gnrl.get_customs_seq(p_ctx.curr_port_cd, 'BRKIMPS_AUTH_SEQ');
                INSERT INTO brkimps (
                    port_cd, athrztn_seq_nbr, impr_nbr, port_cd_brkr, lic_type, lic_nbr, allow_export,
                    athrztn_letr_nbr, athrztn_letr_dt, athrztn_type_cd, athrztn_strt_dt, athrztn_end_dt,
                    note, athrztn_usg_nbr, athrztn_last_usg_dt, athrztn_cncld_dt)
                VALUES (
                    p_rec.port_cd, v_athrztn_seq_nbr, p_rec.impr_nbr, p_ctx.brkr_port_cd, p_ctx.lic_type,
                    p_ctx.brkr_nbr, 1, 'تفويض الي ', hijdate_db.cur_hij_date, 1, NULL, NULL,
                    'تفويض بريد سريع', 0, hijdate_db.cur_hij_date, NULL);
                add_activity(6, p_rec);
            END IF;
            -- STANDARD.COMMIT;   -- removed, see header
            info('تم أنشاء التفويض');
            g_set('IMPR_NBR_B', p_rec.impr_nbr);
            g_set('IMPR_NAME_B', p_rec.arbc_impr_name);
            g_set('BRKR_ATHRZTN_NBR_B', v_athrztn_seq_nbr);
        END IF;
    END create_brkr_impr_auth;

    -- Source: PU UPDATE_IMPORTER, part 1 = text of the CONFIRM alert (NULL when no alert)
    -- HIGH: Forms first runs FORMS_DDL('COMMIT') (saves pending changes). In APEX the page must
    -- be saved (SAVE) before this function is offered - see extraction report §5.
    FUNCTION update_importer_msg (p_rec IN t_rec) RETURN VARCHAR2
    IS
        v_msg VARCHAR2(500);
    BEGIN
        IF p_rec.port_cd IS NOT NULL AND p_rec.impr_nbr IS NOT NULL THEN
            IF p_rec.bus_id_type_cd = 2 THEN
                v_msg := 'السجل الرئيسي =  ' || p_rec.bus_id || 'السجل الفرعي = ' || p_rec.bus_id_brnch
                         || ' تأكيد التحديث؟';
            END IF;
            IF p_rec.impr_type_cd = 4 AND p_rec.bus_id_type_cd = 5 THEN
                v_msg := 'رقم مدني =  ' || p_rec.bus_id || ' تأكيد التحديث؟';
            END IF;
            IF p_rec.impr_type_cd = 4 AND p_rec.bus_id_type_cd = 3 THEN
                v_msg := ' رقم الاقامة =  ' || p_rec.bus_id || ' تأكيد التحديث؟';
            END IF;
        END IF;
        RETURN v_msg;
    END update_importer_msg;

    -- Source: PU UPDATE_IMPORTER, part 2 = after ALERT_BUTTON1
    --@ORIG PU UPDATE_IMPORTER
    -- >>> Original Forms code: PU UPDATE_IMPORTER
    --   PROCEDURE update_importer
    --   IS
    --      ret         NUMBER;
    --      v_chk_upd   NUMBER;
    --      v_msg       VARCHAR2 (500);
    --      msg_lvl     VARCHAR2 (5);
    --      MSG_CD      NUMBER;
    --   BEGIN
    --      BEGIN
    --         msg_lvl := :SYSTEM.message_level;
    --         :SYSTEM.message_level := '25';
    --         FORMS_DDL ('COMMIT');
    --         :SYSTEM.message_level := msg_lvl;
    --      EXCEPTION
    --         WHEN OTHERS
    --         THEN
    --            NULL;
    --      END;
    --      IF :importers.port_cd IS NOT NULL AND :importers.impr_nbr IS NOT NULL
    --      THEN
    --         IF :IMPORTERS.BUS_ID_TYPE_CD = 2 THEN
    --         V_MSG :=
    --               'السجل الرئيسي =  '
    --            || :IMPORTERS.BUS_ID
    --            || 'السجل الفرعي = '
    --            || :IMPORTERS.BUS_ID_BRNCH
    --            || ' تأكيد التحديث؟';
    --       END IF ;
    --       IF :IMPORTERS.IMPR_TYPE_CD = 4 AND :IMPORTERS.BUS_ID_TYPE_CD = 5 THEN
    --         V_MSG :=
    --               'رقم مدني =  '
    --            || :IMPORTERS.BUS_ID
    --            || ' تأكيد التحديث؟';
    --       END IF ;
    --        IF :IMPORTERS.IMPR_TYPE_CD = 4 AND :IMPORTERS.BUS_ID_TYPE_CD = 3 THEN
    --         V_MSG :=
    --               ' رقم الاقامة =  '
    --            || :IMPORTERS.BUS_ID
    --            || ' تأكيد التحديث؟';
    --        END IF ;
    --         ret := str.dispalert (v_msg, 'CONFIRM');
    --         IF ret = alert_button1
    --         THEN
    --            msg_lvl := :SYSTEM.message_level;
    --            :SYSTEM.message_level := '25';
    --            BEGIN
    --               LIB_USR.impr_utilities.UPDATE_IMPORTERS_NAMES (
    --                  :importers.port_cd,
    --                  :importers.impr_nbr,
    --                  MSG_CD,
    --                  v_msg);
    --               ret := str.dispalert (v_msg, 'INFORMATION');
    --            EXCEPTION
    --               WHEN OTHERS
    --               THEN
    --                  NULL;
    --            END;
    --         END IF;
    --      END IF;
    --   END;
    -- <<<
    PROCEDURE update_importer (p_rec IN t_rec)
    IS
        msg_cd NUMBER;
        v_msg  VARCHAR2(500);
    BEGIN
        IF p_rec.port_cd IS NOT NULL AND p_rec.impr_nbr IS NOT NULL THEN
            BEGIN
                lib_usr.impr_utilities.update_importers_names(p_rec.port_cd, p_rec.impr_nbr, msg_cd, v_msg);
                info(v_msg);
            EXCEPTION
                WHEN OTHERS THEN
                    NULL;
            END;
        END IF;
    END update_importer;

    -- Source: PU LOV_UPDATE_MOBLIE, part before CALL_FORM: P_CENTRAL_MOBILE parameter
    FUNCTION central_mobile (p_rec IN t_rec, p_ctx IN t_ctx) RETURN NUMBER
    IS
        v_central_mobile NUMBER;
    BEGIN
        SELECT mobile_no
          INTO v_central_mobile
          FROM importers_central
         WHERE port_cd  = p_ctx.curr_port_cd
           AND impr_nbr = p_rec.impr_nbr;
        RETURN v_central_mobile;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END central_mobile;

    -- Source: PU LOV_UPDATE_MOBLIE, part after LOV_UPDATE_IMPR_MOBILE returned :GLOBAL.MOBILE_NO
    -- HIGH: STANDARD.COMMIT removed.
    --@ORIG PU LOV_UPDATE_MOBLIE
    -- >>> Original Forms code: PU LOV_UPDATE_MOBLIE
    --   PROCEDURE LOV_UPDATE_MOBLIE IS
    --   V_CNT_RASEL      NUMBER;
    --   V_CNT_INFO_RASEL NUMBER;
    --   v_filler1      VARCHAR2(200);
    --    pl_id   ParamList;
    --      pl_name VARCHAR2(100) := 'LOV_CONFIRM_TAR';
    --      RET NUMBER;
    --      V_RESULT NUMBER;
    --      V_CENTRAL_MOBILE NUMBER;
    --     P_RESULT_CD NUMBER;
    --     P_MSG  VARCHAR2(50);
    --   BEGIN
    --          pl_id := Get_Parameter_List(pl_name);
    --     IF Id_Null(pl_id) THEN
    --        pl_id := Create_Parameter_List(pl_name);
    --        IF Id_Null(pl_id) THEN
    --          ret := Str.Dispalert('Error creating parameter list '||pl_name, 'SYSTEM_ERROR');
    --          RAISE Form_Trigger_Failure;
    --        END IF;
    --         BEGIN
    --             SELECT MOBILE_NO
    --               INTO V_CENTRAL_MOBILE
    --                FROM IMPORTERS_CENTRAL
    --                 WHERE PORT_CD    = :PARAMETER.P_CURR_PORT_CD AND IMPR_NBR = :IMPORTERS.IMPR_NBR ;
    --         EXCEPTION WHEN NO_DATA_FOUND THEN
    --              V_CENTRAL_MOBILE := NULL;
    --            END;
    --      Add_Parameter(pl_id, 'WINDOW_WIDTH', TEXT_PARAMETER, 5);
    --      Add_Parameter(pl_id, 'WINDOW_TITLE', TEXT_PARAMETER, 'تعديل رقم الجوال');
    --      Add_Parameter(pl_id, 'P_CENTRAL_MOBILE', TEXT_PARAMETER, V_CENTRAL_MOBILE);
    --             CALL_FORM('LOV_UPDATE_IMPR_MOBILE.fmx',
    --                     no_hide,
    --                 no_replace,
    --                 no_query_only,
    --                 pl_id);
    --                     Destroy_Parameter_List(pl_id);
    --       ELSE
    --           ret := Str.DispAlert('Parameter list '||pl_name||' already EXISTS!','INFORMATION');
    --           RAISE Form_Trigger_Failure;
    --       END IF;
    --      IF    :GLOBAL.MOBILE_NO  IS NOT NULL THEN
    --                impr.CHK_MOBILE_FORMAT (:GLOBAL.MOBILE_NO  , V_RESULT );
    --               IF V_RESULT = 0 THEN
    --                      STR.DISPALERT('رقم الجوال المدخل غير صحيح' ,'ERROR');
    --                  RAISE Form_Trigger_Failure;
    --              END IF ;
    --        IMPR_UTILITIES.UPDATE_IMPR_MOBILE_NO (:IMPR_NBR , :GLOBAL.MOBILE_NO ,P_RESULT_CD , P_MSG ) ;
    --           IF P_RESULT_CD = 1 THEN
    --                    STANDARD.COMMIT;
    --           STR.DISPALERT('تمت العملية بنجاح','INFORMATION');
    --           END IF;
    --     END IF;
    --   END;
    -- <<<
    PROCEDURE lov_update_moblie (p_rec IN t_rec)
    IS
        v_result    NUMBER;
        p_result_cd NUMBER;
        p_msg       VARCHAR2(50);
    BEGIN
        IF g_get('MOBILE_NO') IS NOT NULL THEN
            impr.chk_mobile_format(g_get('MOBILE_NO'), v_result);
            IF v_result = 0 THEN
                ftf('رقم الجوال المدخل غير صحيح');
            END IF;
            impr_utilities.update_impr_mobile_no(p_rec.impr_nbr, g_get('MOBILE_NO'), p_result_cd, p_msg);
            IF p_result_cd = 1 THEN
                -- STANDARD.COMMIT;   -- removed, see header
                info('تمت العملية بنجاح');
            END IF;
        END IF;
    END lov_update_moblie;

    -- Source: PU EXEC_FUNS (server part of each function code; dialogs/CALL_FORM are UI)
    --@ORIG PU EXEC_FUNS
    -- >>> Original Forms code: PU EXEC_FUNS
    --   PROCEDURE EXEC_FUNS(CD VARCHAR2) IS
    --       PL_ID PARAMLIST;
    --     RET NUMBER;
    --   pl_name      VARCHAR2(100) := 'TMPLT_MOD_CALL';
    --      P_Result NUMBER;
    --      P_Result_Msg VARCHAR2(100);
    --   BEGIN
    --   IF CD IN ('IMPR1110F4') THEN
    --     :PARAMETER.CODE :='IMPR1110F4';
    --   END IF;
    --   IF CD IN ('IMPR1115_SCR') THEN
    --       pl_id := Get_Parameter_List(pl_name);
    --           IF NOT Id_Null(pl_id) THEN
    --         ADD_PARAMETER(PL_ID,'P_IMPR_NO',TEXT_PARAMETER,:IMPORTERS.IMPR_NBR);
    --           END IF;
    --   END IF;
    --   IF CD IN( 'IMPR1110F2','IMPR1110F1','IMPR1110F3','IMPR1110F5') THEN
    --     IF NOT ID_NULL(FIND_FORM('SUPPORT_ENTRY')) THEN
    --            CLOSE_FORM('SUPPORT_ENTRY');
    --     END IF;
    --     PL_ID := GET_PARAMETER_LIST('SUPPORT_ENTRY');
    --     IF ID_NULL(PL_ID) THEN
    --           PL_ID := CREATE_PARAMETER_LIST('SUPPORT_ENTRY');
    --           IF ID_NULL(PL_ID) THEN
    --              STR.DISPALERT('Error creating parameter list SUPPORT_ENTRY','SYSTEM_ERROR');
    --              RAISE FORM_TRIGGER_FAILURE;
    --           END IF;
    --           ADD_PARAMETER(PL_ID,'WINDOW_X_POS',TEXT_PARAMETER,1.5);
    --         ADD_PARAMETER(PL_ID,'WINDOW_Y_POS',TEXT_PARAMETER,2);
    --         ADD_PARAMETER(PL_ID,'P_MODE',TEXT_PARAMETER,0);
    --         ADD_PARAMETER(PL_ID,'P_CURR_PORT_CD',TEXT_PARAMETER,:IMPORTERS.PORT_CD);
    --         CALL_FORM('SUPPORT_ENTRY.FMX',NO_HIDE,NO_REPLACE,NO_QUERY_ONLY,PL_ID);
    --         DESTROY_PARAMETER_LIST(PL_ID);
    --         IF :GLOBAL.LETTER_NBR IS NOT NULL THEN
    --              :PARAMETER.CODE :=CD;
    --           :PARAMETER.LETTER_NBR :=:GLOBAL.LETTER_NBR;
    --           GO_BLOCK('IMPORTERS');
    --          END IF;
    --      END IF;
    --   END IF;
    --   IF CD IN ('IMPR_CAR_AGENT') THEN
    --       :PARAMETER.CODE := 'IMPR1110SF6';
    --   END IF;
    --   IF CD IN ('IMPR_MCI_SERVICE') AND (:GLOBAL.ALLOW_MCI = 1 OR :GLOBAL.allow_moi
    --   =1)THEN
    --       Update_Importer;
    --   END IF;
    --   IF CD IN ('CREATE_BRKR_IMPR_AUTH') THEN
    --       CREATE_BRKR_IMPR_AUTH;
    --   END IF;
    --   IF CD IN ('IMPR1115_GZT') THEN
    --   BEGIN
    --   Lib_Usr.Web_Services_Gazt.Pr_Import_Impr_Certificate(:IMPORTERS.Bus_Id, :IMPORTERS.Bus_Id_Brnch, P_Result, P_Result_Msg);
    --    IF P_Result = 3 THEN
    --              str.dispalert('تم التحديث بنجاح','WARNING');
    --    ELSIF P_Result = '00' THEN
    --              str.dispalert('رقم استدلالي غير صحيح','WARNING');
    --    ELSIF P_Result = '02' THEN
    --              str.dispalert('رقم شهادة غير صحيح','WARNING');
    --    ELSIF P_Result = '04' THEN
    --              str.dispalert('لا يوجد بيانات','WARNING');
    --    END IF;
    --       EXCEPTION
    --               WHEN OTHERS
    --               THEN
    --                  NULL;
    --   END;
    --   END IF;
    --   IF CD IN ('IMPR1110_MOB') THEN
    --        IF  :IMPORTERS.IMPR_NBR > 3000000 THEN
    --        LOV_UPDATE_MOBLIE ;
    --        ELSE
    --            STR.DISPALERT('رقم المستورد غير محدث ,, الرجاء مراجعة الدعم', 'ERROR');
    --             RAISE FORM_TRIGGER_FAILURE;
    --        END IF;
    --   END IF;
    --   END;
    -- <<<
    PROCEDURE exec_funs (p_rec IN OUT NOCOPY t_rec, p_ctx IN OUT NOCOPY t_ctx, cd IN VARCHAR2)
    IS
        p_result     NUMBER;
        p_result_msg VARCHAR2(100);
    BEGIN
        IF cd IN ('IMPR1110F4') THEN
            p_ctx.code := 'IMPR1110F4';
        END IF;
        -- 'IMPR1115_SCR': APEX-DA -> open page IMPR1115 with P_IMPR_NO = IMPR_NBR
        IF cd IN ('IMPR1110F2', 'IMPR1110F1', 'IMPR1110F3', 'IMPR1110F5') THEN
            -- APEX-DA: modal dialog SUPPORT_ENTRY (P_MODE=0, P_CURR_PORT_CD=PORT_CD) is opened by
            -- the page first; this part runs after the dialog closed and set :GLOBAL.LETTER_NBR.
            IF g_get('LETTER_NBR') IS NOT NULL THEN
                p_ctx.code       := cd;
                p_ctx.letter_nbr := g_get('LETTER_NBR');
            END IF;
        END IF;
        IF cd IN ('IMPR_CAR_AGENT') THEN
            p_ctx.code := 'IMPR1110SF6';
        END IF;
        -- 'IMPR_MCI_SERVICE' (ALLOW_MCI = 1 OR ALLOW_MOI = 1): Confirm(update_importer_msg) ->
        -- update_importer. Interactive -> page process, see extraction report §5.
        IF cd IN ('CREATE_BRKR_IMPR_AUTH') THEN
            create_brkr_impr_auth(p_rec, p_ctx);
        END IF;
        IF cd IN ('IMPR1115_GZT') THEN
            BEGIN
                lib_usr.web_services_gazt.pr_import_impr_certificate(p_rec.bus_id, p_rec.bus_id_brnch,
                                                                    p_result, p_result_msg);
                IF p_result = 3 THEN
                    info('تم التحديث بنجاح');
                ELSIF p_result = '00' THEN
                    info('رقم استدلالي غير صحيح');
                ELSIF p_result = '02' THEN
                    info('رقم شهادة غير صحيح');
                ELSIF p_result = '04' THEN
                    info('لا يوجد بيانات');
                END IF;
            EXCEPTION
                WHEN OTHERS THEN
                    NULL;
            END;
        END IF;
        IF cd IN ('IMPR1110_MOB') THEN
            IF p_rec.impr_nbr > 3000000 THEN
                NULL;   -- APEX-DA: open dialog LOV_UPDATE_IMPR_MOBILE, then lov_update_moblie
            ELSE
                ftf('رقم المستورد غير محدث ,, الرجاء مراجعة الدعم');
            END IF;
        END IF;
    END exec_funs;

END pkg_impr1110;
/
SHOW ERRORS
