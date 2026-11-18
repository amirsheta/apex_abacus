-- =============================================================================
-- Package     : IMPR1110_APX
-- Source form : IMPR1110.fmb - APEX glue for IMPR1110 (pages 1110-1119)
-- Target      : Oracle APEX 21.2 / Oracle Database 12.1.0.2
-- Author      : Claude Code
-- Created     : 2026-11-18
-- Version     : 1.1.0  (step 03: server-side item state + validation on submit + port scope)
-- Owner       : LIB_APX_USR (public synonym IMPR1110_APX; EXECUTE granted to LIB_USR, SECURITY_DEFAULT, SECURITY_PROD, CUSTOMS)
-- Purpose     : The ONLY code that reads/writes page items P1110_*. It builds t_rec / t_ctx,
--               calls IMPR1110 in the Forms trigger order and writes the results back.
--               IMPR1110 itself stays free of page items (testable without APEX).
-- Server state: APEX collection COL_IMPR1110_STATE (per session)
--                 c001 = 'UI'  : c002 item, c003 property (ENTRABLE/ENABLED/REQUIRED/VISIBLE), c004 Y/N
--                 c001 = 'VAL' : c002 item, c003 last value the server validated (Forms "item valid")
--               Used to enforce at SAVE what Forms enforces at commit:
--                 - items changed since their last validation are validated again (not all items:
--                   several validations consume sequences)
--                 - required items (static Forms Required + dynamic SET_ITEM_PROPERTY REQUIRED)
--                 - GET_ITEM_PROPERTY(..., ENABLED) read by the package
-- Page items  : P1110_<FORMS_ITEM_NAME> for every field of t_rec, plus
--               P1110_ROW_ID, P1110_REC_STATUS, P1110_FORM_OPEN, P1110_NEED_FETCH (server-only),
--               P1110_PRSNL_IMPR, P1110_LETTER_NBR, P1110_CODE, P1110_UI_STATE (JSON for the DA).
-- App items   : P_CURR_PORT_CD, SSO_APP_USER, P_GLOBAL_V_WS_ID, P_CLASS_CD, V_USR_TYPE (f345),
--               P_BRKR_PORT_CD, P_LIC_TYPE, P_BRKR_NBR (= :PARAMETER.P_* of the menu); globals = G_<NAME>
-- Status      : NOT COMPILED.
-- History     : 2026-11-18 1.0.0 step 02; 1.1.0 step 03 (see analysis/IMPR1110/IMPR1110_apex_page_spec.md)
-- =============================================================================
SET DEFINE OFF

CREATE OR REPLACE PACKAGE LIB_APX_USR.IMPR1110_APX AS
   V_PKG_VERSION       VARCHAR2 (100) := 'VERSION NO. IS:' || '001';
   V_PKG_VERSION_QC    VARCHAR2 (100) := 'VERSION NO. IS:' || '001';
   V_PKG_VERSION_DEV   VARCHAR2 (100) := 'VERSION NO. IS:' || '001';
   FUNCTION PKG_VERSION
      RETURN VARCHAR2;
   V_PACKAGE_NAME      VARCHAR2 (50) := 'IMPR1110_APX';
   V_LAST_MODIFY_DT    VARCHAR2 (10) := '18-11-2026';
   V_MODIFIED_BY       VARCHAR2 (50) := 'Claude Code';
   V_INFO              VARCHAR2 (500)
      :=    'PACKAGE NAME :  '
         || V_PACKAGE_NAME
         || CHR (10)
         || CHR (13)
         || V_PKG_VERSION
         || CHR (10)
         || CHR (13)
         || 'MODIFIED DATE : '
         || V_LAST_MODIFY_DT
         || CHR (10)
         || CHR (13)
         || 'MODIFIED BY : '
         || V_MODIFIED_BY;

    c_page       CONSTANT PLS_INTEGER  := 1110;
    c_state_coll CONSTANT VARCHAR2(30) := 'COL_IMPR1110_STATE';

    -- Forms fires POST-CHANGE for non-NULL values fetched by a query (documented legacy
    -- behaviour). TRUE = do the same on page load. TODO-VERIFY with a Forms trace (HIGH).
    c_post_chg_on_fetch CONSTANT BOOLEAN := TRUE;

    FUNCTION  get_ctx RETURN IMPR1110.t_ctx;
    FUNCTION  get_rec RETURN IMPR1110.t_rec;
    PROCEDURE set_rec (p_rec IN IMPR1110.t_rec);

    -- Before Header process "WHEN-NEW-FORM-INSTANCE" (condition: P1110_FORM_OPEN is null)
    PROCEDURE page_wnfi;
    -- Before Header process "IMPORTERS.POST-QUERY": loads P1110_ROW_ID, or
    -- P1110_PORT_CD + P1110_IMPR_NBR (URL with checksum), or :GLOBAL.PORT_CD/IMPR_NBR
    -- (EXEC_QUERY_NOW) - always within PORT_CD = P_CURR_PORT_CD (block WHERE clause)
    PROCEDURE page_fetch;
    -- Before Header process "IMPORTERS.WHEN-CREATE-RECORD" (when no row is loaded)
    PROCEDURE page_new_record;

    -- AJAX Callback "IMPR1110_ITEM":
    --   x01 = Forms item name, x02 = event VALIDATE | WNII | WLC | LOV_RET | KEY_NXT | WNRI,
    --   x03 / x04 = answers of Confirm DAs (1 = yes, 2 = no; empty = yes)
    -- Returns {"items":{"P1110_X":"v",...},"ui":{...IMPR1110.ui_json...}} or {"error":"..."}
    PROCEDURE ajax_item;
    -- AJAX Callback "IMPR1110_CONFIRM": x01 = WNRI | SUSP | UPD_IMPR -> {"text":"..."} ("" = none)
    PROCEDURE ajax_confirm;
    -- AJAX Callback "IMPR1110_FUN": x01 = function code (EXEC_FUNS), x02 = answer
    PROCEDURE ajax_fun;

    -- Validation "IMPORTERS.<ITEM>.WHEN-VALIDATE-ITEM" (request SAVE):
    --   RETURN IMPR1110_APX.validate_on_submit('<ITEM>');
    -- Runs POST-CHANGE + WHEN-VALIDATE-ITEM with p_from_item = FALSE only when the value differs
    -- from the last value the server validated. Returns NULL or the Forms error text.
    FUNCTION  validate_on_submit (p_item IN VARCHAR2) RETURN VARCHAR2;
    -- Validation "IMPORTERS.REQUIRED-ITEMS" (request SAVE): first required item that is NULL
    -- (static Forms Required items + dynamic REQUIRED) -> Forms FRM-40202 text, else NULL
    FUNCTION  required_items RETURN VARCHAR2;

    -- Process "IMPORTERS.KEY-CLRBLK" (requests CLEAR / CREATE): WHEN-CLEAR-BLOCK + empty record;
    -- the next page show runs WHEN-CREATE-RECORD
    PROCEDURE page_clear;
    -- Process "IMPORTERS.EXECUTE-QUERY" (requests QUERY / QUERY_NBR): clears the record and asks
    -- the next page show to fetch IMPR_NBR (NULL = use :GLOBAL.PORT_CD/IMPR_NBR, EXEC_QUERY_NOW)
    PROCEDURE page_query (p_impr_nbr IN NUMBER);
    -- Page 1112 (LOV_UPDATE_IMPR_MOBILE) Before Header: :PARAMETER.P_CENTRAL_MOBILE
    FUNCTION  central_mobile (p_impr_nbr IN NUMBER) RETURN NUMBER;

    -- Page processes "IMPORTERS.PRE-INSERT/INSERT/POST-INSERT", ".PRE-UPDATE/UPDATE/POST-UPDATE"
    -- (request SAVE) and "IMPORTERS.KEY-DELREC" (request DELETE)
    PROCEDURE page_dml (p_request IN VARCHAR2);
END IMPR1110_APX;
/
SHOW ERRORS

-- -----------------------------------------------------------------------------
-- Synonym and grants (run as a user allowed to create public synonyms / grant on LIB_APX_USR).
-- CUSTOMS = parsing schema of the APEX application: APEX needs the direct grant.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PUBLIC SYNONYM IMPR1110_APX FOR LIB_APX_USR.IMPR1110_APX;

GRANT EXECUTE ON LIB_APX_USR.IMPR1110_APX TO LIB_USR;

GRANT EXECUTE ON LIB_APX_USR.IMPR1110_APX TO SECURITY_DEFAULT;

GRANT EXECUTE ON LIB_APX_USR.IMPR1110_APX TO SECURITY_PROD;

GRANT EXECUTE ON LIB_APX_USR.IMPR1110_APX TO CUSTOMS;
