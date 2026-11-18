-- =============================================================================
-- Package     : IMPR1110  (APEX entry point of form IMPR1110 - f345 reference standard)
-- Form        : IMPR1110.fmb "إضافة وتعديل بيانات مستورد"
-- Author      : Claude Code
-- Created     : 2026-11-18
-- Version     : 1.0.0
-- Owner       : LIB_APX_USR (public synonym IMPR1110; EXECUTE granted to LIB_USR, SECURITY_DEFAULT, SECURITY_PROD, CUSTOMS)
-- Status      : NOT COMPILED.
-- Purpose     : Every page process, validation, computation and AJAX callback of pages
--               1110 / 111001 / 111002 calls this package and nothing else
--               (docs/f345_reference_standard.md §5: package = form name, I_/IO_ parameters).
--               The business logic stays in pkg_impr1110 (step 02) and the session-state
--               glue in pkg_impr1110_apx; this package only delegates to them.
-- Note        : the item-level members read the record from session state through
--               pkg_impr1110_apx (all P1110_* items are submitted), so their I_ parameter
--               documents which item is validated but is not otherwise needed.
-- Depends on  : pkg_forms_compat, pkg_impr1110, pkg_impr1110_apx (1.2.0), SC_SYSTEM_OBJECTS
-- =============================================================================
SET DEFINE OFF

CREATE OR REPLACE PACKAGE LIB_APX_USR.IMPR1110 AS
   V_PKG_VERSION       VARCHAR2 (100) := 'VERSION NO. IS:' || '001';
   V_PKG_VERSION_QC    VARCHAR2 (100) := 'VERSION NO. IS:' || '001';
   V_PKG_VERSION_DEV   VARCHAR2 (100) := 'VERSION NO. IS:' || '001';
   FUNCTION PKG_VERSION
      RETURN VARCHAR2;
   V_PACKAGE_NAME      VARCHAR2 (50) := 'IMPR1110';
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

    c_page        CONSTANT PLS_INTEGER := 1110;
    c_search_page CONSTANT PLS_INTEGER := 111001;
    c_mobile_page CONSTANT PLS_INTEGER := 111002;

    -- ------------------------------------------------------------- f345 helpers
    -- Raises the error text (used by dynamic actions: IMPR1110.CHK(IMPR1110.<ITEM>_VAL(...)))
    PROCEDURE CHK (I_ERR IN VARCHAR2);
    -- Error text when a required value is empty, else NULL
    FUNCTION  REQUIRED_VAL (I_VALUE IN VARCHAR2, I_LABEL IN VARCHAR2) RETURN VARCHAR2;

    -- ------------------------------------------------------------- Before Header
    -- Source: P0_PAGE_PK CHECK - forget a key that is not an importer of the current port
    PROCEDURE P0_PAGE_PK_CHECK (IO_P0_PAGE_PK IN OUT VARCHAR2);
    -- Source: PARAMETERS - module id of IMPR1110 in SC_SYSTEM_OBJECTS
    FUNCTION  GET_MODULE_ID (I_P1110_MODULE_ID IN VARCHAR2) RETURN VARCHAR2;
    -- Source: :PARAMETER.PRSNL_IMPR / :PARAMETER.LETTER_NBR passed by the caller
    PROCEDURE PARAMETERS_ENTRY (IO_P_PRSNL_IMPR      IN OUT VARCHAR2,
                                IO_P_LETTER_NBR      IN OUT VARCHAR2,
                                IO_P1110_PRSNL_IMPR  IN OUT VARCHAR2,
                                IO_P1110_LETTER_NBR  IN OUT VARCHAR2);
    -- Source: FORM.WHEN-NEW-FORM-INSTANCE
    PROCEDURE WHEN_NEW_FORM_INSTANCE;
    -- Source: P0_PAGE_PK (record chosen on the search page / kept by the toolbar)
    PROCEDURE SET_PAGE_PK (I_P0_PAGE_PK IN VARCHAR2);
    -- Source: IMPORTERS.PRE-QUERY, POST-QUERY, PRE-RECORD, WHEN-NEW-RECORD-INSTANCE
    PROCEDURE POST_QUERY;
    -- Source: IMPORTERS.WHEN-CREATE-RECORD, PRE-RECORD, WHEN-NEW-RECORD-INSTANCE
    PROCEDURE WHEN_CREATE_RECORD;
    -- Source: hero region title (f345 HEADER TITLE)
    PROCEDURE HEADER_TITLE (I_P1110_MODULE_ID   IN VARCHAR2,
                            IO_P1110_HERO_TITLE IN OUT VARCHAR2);
    -- Source: PU LOV_UPDATE_MOBLIE - URL of page 111002 with checksum
    FUNCTION  MOBILE_URL (I_P1110_IMPR_NBR IN VARCHAR2) RETURN VARCHAR2;

    -- ------------------------------------------------------------- After Submit
    -- Source: IMPORTERS.PRE-INSERT, INSERT, POST-INSERT (request CREATE)
    PROCEDURE ON_INSERT;
    -- Source: IMPORTERS.PRE-UPDATE, UPDATE, POST-UPDATE (request SAVE)
    PROCEDURE ON_UPDATE;
    -- Source: IMPORTERS.KEY-DELREC, PRE-DELETE (request DELETE)
    PROCEDURE KEY_DELREC;
    -- Source: IMPORTERS.IMPR_NBR re-query (QUERY / QUERY_NBR)
    PROCEDURE EXECUTE_QUERY (I_REQUEST IN VARCHAR2, I_P1110_IMPR_NBR IN VARCHAR2);

    -- ------------------------------------------------------------- validations (on submit)
    -- Each returns the error text of the item's POST-CHANGE + WHEN-VALIDATE-ITEM, or NULL.
    FUNCTION PORT_CD_VAL         (I_P1110_PORT_CD         IN VARCHAR2) RETURN VARCHAR2;
    FUNCTION HQ_IMPR_NBR_VAL     (I_P1110_HQ_IMPR_NBR     IN VARCHAR2) RETURN VARCHAR2;
    FUNCTION IMPR_NBR_VAL        (I_P1110_IMPR_NBR        IN VARCHAR2) RETURN VARCHAR2;
    FUNCTION IMPR_TYPE_CD_VAL    (I_P1110_IMPR_TYPE_CD    IN VARCHAR2) RETURN VARCHAR2;
    FUNCTION BUS_ID_EXPRD_DT_VAL (I_P1110_BUS_ID_EXPRD_DT IN VARCHAR2) RETURN VARCHAR2;
    FUNCTION BUS_ID_TYPE_CD_VAL  (I_P1110_BUS_ID_TYPE_CD  IN VARCHAR2) RETURN VARCHAR2;
    FUNCTION CITY_CODE_OF_ID_VAL (I_P1110_CITY_CODE_OF_ID IN VARCHAR2) RETURN VARCHAR2;
    FUNCTION BUS_ID_VAL          (I_P1110_BUS_ID          IN VARCHAR2) RETURN VARCHAR2;
    FUNCTION BRNH_CITY_CD_VAL    (I_P1110_BRNH_CITY_CD    IN VARCHAR2) RETURN VARCHAR2;
    FUNCTION BUS_ID_BRNCH_VAL    (I_P1110_BUS_ID_BRNCH    IN VARCHAR2) RETURN VARCHAR2;
    FUNCTION CTRY_CD_VAL         (I_P1110_CTRY_CD         IN VARCHAR2) RETURN VARCHAR2;
    FUNCTION IMPR_EXPR_TYPE_VAL  (I_P1110_IMPR_EXPR_TYPE  IN VARCHAR2) RETURN VARCHAR2;
    FUNCTION ARBC_IMPR_NAME_VAL  (I_P1110_ARBC_IMPR_NAME  IN VARCHAR2) RETURN VARCHAR2;
    FUNCTION ENG_IMPR_NAME_VAL   (I_P1110_ENG_IMPR_NAME   IN VARCHAR2) RETURN VARCHAR2;
    FUNCTION BUS_ID_ISSUE_DT_VAL (I_P1110_BUS_ID_ISSUE_DT IN VARCHAR2) RETURN VARCHAR2;
    FUNCTION IMPR_NBR_PARENT_VAL (I_P1110_IMPR_NBR_PARENT IN VARCHAR2) RETURN VARCHAR2;
    FUNCTION ADD_CTRY_CD_VAL     (I_P1110_ADD_CTRY_CD     IN VARCHAR2) RETURN VARCHAR2;
    FUNCTION CITY_CODE_VAL       (I_P1110_CITY_CODE       IN VARCHAR2) RETURN VARCHAR2;
    FUNCTION IMPR_TEL_NBR_VAL    (I_P1110_IMPR_TEL_NBR    IN VARCHAR2) RETURN VARCHAR2;
    FUNCTION B_EMAIL_VAL         (I_P1110_B_EMAIL         IN VARCHAR2) RETURN VARCHAR2;
    FUNCTION EMAIL_VAL           (I_P1110_EMAIL           IN VARCHAR2) RETURN VARCHAR2;
    FUNCTION B_MOBILE_NO_VAL     (I_P1110_B_MOBILE_NO     IN VARCHAR2) RETURN VARCHAR2;
    FUNCTION BANK_IBAN_VAL       (I_P1110_BANK_IBAN       IN VARCHAR2) RETURN VARCHAR2;
    FUNCTION B_ID_NBR_VAL        (I_P1110_B_ID_NBR        IN VARCHAR2) RETURN VARCHAR2;
    FUNCTION CTRY_CD_OF_ID_VAL   (I_P1110_CTRY_CD_OF_ID   IN VARCHAR2) RETURN VARCHAR2;
    -- Source: FRM-40202 at commit (static Required + SET_ITEM_PROPERTY REQUIRED)
    FUNCTION REQUIRED_ITEMS_VAL RETURN VARCHAR2;

    -- ------------------------------------------------------------- AJAX callbacks (impr1110.js)
    PROCEDURE AJAX_ITEM;        -- all item triggers (x01 item, x02 event)
    PROCEDURE AJAX_CONFIRM;     -- CONFIRM / WARNING alert texts
    PROCEDURE AJAX_FUN;         -- PU EXEC_FUNS

    -- ------------------------------------------------------------- page 111002 (LOV_UPDATE_IMPR_MOBILE)
    FUNCTION  CENTRAL_MOBILE (I_P111002_IMPR_NBR IN VARCHAR2) RETURN NUMBER;
    PROCEDURE MOBILE_OK      (I_P111002_MOBILE_NO IN VARCHAR2);
    PROCEDURE MOBILE_CANCEL;
END IMPR1110;
/
SHOW ERRORS

-- -----------------------------------------------------------------------------
-- Synonym and grants (run as a user allowed to create public synonyms / grant on LIB_APX_USR).
-- CUSTOMS = parsing schema of the APEX application: APEX needs the direct grant.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PUBLIC SYNONYM IMPR1110 FOR LIB_APX_USR.IMPR1110;

GRANT EXECUTE ON LIB_APX_USR.IMPR1110 TO LIB_USR;

GRANT EXECUTE ON LIB_APX_USR.IMPR1110 TO SECURITY_DEFAULT;

GRANT EXECUTE ON LIB_APX_USR.IMPR1110 TO SECURITY_PROD;

GRANT EXECUTE ON LIB_APX_USR.IMPR1110 TO CUSTOMS;
