-- =============================================================================
-- Package     : pkg_impr1110_apx
-- Source form : IMPR1110.fmb - APEX glue for pkg_impr1110 (page 1110)
-- Target      : Oracle APEX 21.2 / Oracle Database 12.1.0.2
-- Author      : Claude Code
-- Created     : 2026-11-18
-- Version     : 1.0.0
-- Purpose     : The ONLY code that reads/writes page items P1110_*. It builds t_rec / t_ctx,
--               calls pkg_impr1110 in the Forms trigger order and writes the results back.
--               pkg_impr1110 itself stays free of page items (testable without APEX).
-- Page items  : P1110_<FORMS_ITEM_NAME> for every item of t_rec, plus
--               P1110_ROW_ID, P1110_REC_STATUS, P1110_ACTIVITY_ENTR, P1110_BUS_ID_BRNCH_ENTR,
--               P1110_PRSNL_IMPR, P1110_LETTER_NBR, P1110_CODE, P1110_UI_STATE (JSON for the DA).
-- App items   : AI_P_CURR_PORT_CD, AI_P_USER_ID, AI_P_WS_ID, AI_P_CLASS_CD, AI_P_USER_TYPE,
--               AI_P_BRKR_PORT_CD, AI_P_LIC_TYPE, AI_P_BRKR_NBR (= :PARAMETER.P_* of the menu)
-- Status      : NOT COMPILED.
-- =============================================================================
SET DEFINE OFF

CREATE OR REPLACE PACKAGE pkg_impr1110_apx
AUTHID DEFINER
AS
    c_page CONSTANT PLS_INTEGER := 1110;

    -- Forms fires POST-CHANGE for non-NULL values fetched by a query (documented legacy
    -- behaviour). TRUE = do the same on page load. TODO-VERIFY with a Forms trace (HIGH).
    c_post_chg_on_fetch CONSTANT BOOLEAN := TRUE;

    FUNCTION  get_ctx RETURN pkg_impr1110.t_ctx;
    FUNCTION  get_rec RETURN pkg_impr1110.t_rec;
    PROCEDURE set_rec (p_rec IN pkg_impr1110.t_rec);

    -- Before Header process "WHEN-NEW-FORM-INSTANCE" (first entry into the page only)
    PROCEDURE page_wnfi;
    -- Before Header process "IMPORTERS.POST-QUERY": loads P1110_ROW_ID, or
    -- P1110_PORT_CD + P1110_IMPR_NBR, or :GLOBAL.PORT_CD/IMPR_NBR (EXEC_QUERY_NOW)
    PROCEDURE page_fetch;
    -- Before Header process "IMPORTERS.WHEN-CREATE-RECORD" (no row loaded)
    PROCEDURE page_new_record;

    -- AJAX Callback "IMPR1110_ITEM":
    --   x01 = Forms item name, x02 = event VALIDATE | WNII | WLC | LOV_RET | KEY_NXT | WNRI,
    --   x03 / x04 = answers of Confirm DAs (1 = yes, 2 = no; empty = yes)
    -- Returns {"items":{"P1110_X":"v",...},"ui":{...pkg_impr1110.ui_json...}} or {"error":"..."}
    PROCEDURE ajax_item;
    -- AJAX Callback "IMPR1110_CONFIRM": x01 = WNRI | SUSP | UPD_IMPR -> {"text":"..."} ("" = none)
    PROCEDURE ajax_confirm;
    -- AJAX Callback "IMPR1110_FUN": x01 = function code (EXEC_FUNS), x02 = answer
    PROCEDURE ajax_fun;

    -- Page processes "IMPORTERS.PRE-INSERT/INSERT/POST-INSERT", ".PRE-UPDATE/UPDATE/POST-UPDATE"
    -- (request SAVE) and "IMPORTERS.KEY-DELREC" (request DELETE)
    PROCEDURE page_dml (p_request IN VARCHAR2);
END pkg_impr1110_apx;
/
SHOW ERRORS
