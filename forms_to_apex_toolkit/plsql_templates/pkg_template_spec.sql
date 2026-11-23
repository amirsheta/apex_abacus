-- =============================================================================
-- Package     : <FORM>              (upper-case form name, no prefix - f345 standard, e.g. AGR1100)
--               replace <FORM>, <page>, <BLOCK>, <DETAIL_BLOCK>, <ITEM>, <PK> everywhere
-- Source form : <FORM>.fmb (Oracle Forms 12c)
-- Target      : Oracle APEX 21.2 / Oracle Database 12.1.0.2, reference application f345
-- Author      : <author>
-- Created     : <YYYY-MM-DD>
-- Version     : 1.0.0
-- Purpose     : Business logic of the form, organised like the form itself:
--               VERSION -> f345 HELPERS -> FORM LEVEL -> one section per BLOCK (query, record,
--               items in navigation order, DML, buttons) -> PROGRAM UNITS
--               (docs/f345_reference_standard.md §10). No UI state, no session-state reads:
--               UI rules are BOOLEAN functions that APEX conditions call (§9).
--               Member and component names: docs/f345_reference_standard.md section 5.
-- Parameters  : members called by APEX name each parameter after its bind, without an I_ / IO_ / O_
--               prefix (the mode is IN / IN OUT / OUT): page item P<page>_<ITEM> -> P_<ITEM>
--               (P_<ITEM> => :P<page>_<ITEM>), P0_PAGE_PK -> P_PAGE_PK, IG columns <COLUMN> => :<COLUMN>,
--               application items keep their name (SSO_APP_USER => :SSO_APP_USER). Inside SQL qualify a
--               parameter with its member name (PRE_DELETE.P_<PK>): an unqualified name that matches a
--               column resolves to the column. Internal members use p_<name>. Rule: scripts/parameter_names.py.
--               The package never reads page items itself, so it is testable without APEX.
-- Rules       : every identifier <= 30 bytes (DB 12.1.0.2); no qualified expressions (18c).
-- Owner       : LIB_APX_USR; public synonym <FORM> + EXECUTE grants at the end of this file.
-- Version     : raise V_PKG_VERSION (and the _QC / _DEV copies per environment) and
--               V_LAST_MODIFY_DT (DD-MM-YYYY) / V_MODIFIED_BY on every change.
-- History     : <YYYY-MM-DD> <author> 1.0.0 Initial migration
-- =============================================================================
SET DEFINE OFF

CREATE OR REPLACE PACKAGE LIB_APX_USR.<FORM> AS
   V_PKG_VERSION       VARCHAR2 (100) := 'VERSION NO. IS:' || '001';
   V_PKG_VERSION_QC    VARCHAR2 (100) := 'VERSION NO. IS:' || '001';
   V_PKG_VERSION_DEV   VARCHAR2 (100) := 'VERSION NO. IS:' || '001';
   FUNCTION PKG_VERSION
      RETURN VARCHAR2;
   V_PACKAGE_NAME      VARCHAR2 (50) := '<FORM>';
   V_LAST_MODIFY_DT    VARCHAR2 (10) := '<DD-MM-YYYY>';
   V_MODIFIED_BY       VARCHAR2 (50) := '-';
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

    -- =========================================================================
    -- f345 HELPERS                                 (every form package has these)
    -- =========================================================================
    -- Raises the error text; used by dynamic actions: <FORM>.CHECK_ERROR(<FORM>.<ITEM>_VALIDATION(...))
    PROCEDURE CHECK_ERROR (ERROR_TEXT IN VARCHAR2);

    -- Error text when a required value is empty, else NULL
    -- APEX  : Validation "<ITEM> REQUIRED": return <FORM>.REQUIRED_VALIDATION(:P<page>_<ITEM>, '<label>');
    FUNCTION  REQUIRED_VALIDATION (ITEM_VALUE IN VARCHAR2, ITEM_LABEL IN VARCHAR2) RETURN VARCHAR2;

    -- APEX  : Process "P0_PAGE_PK CHECK" (Before Header) - drops a key that no longer exists
    PROCEDURE P0_PAGE_PK_CHECK (P_PAGE_PK IN OUT VARCHAR2);

    -- APEX  : Process "PARAMETERS": :P<page>_MODULE_ID := <FORM>.GET_MODULE_ID(...)
    FUNCTION  GET_MODULE_ID (P_MODULE_ID IN VARCHAR2) RETURN VARCHAR2;

    -- APEX  : Process "HEADER TITLE" (Before Header) - title of the hero region
    PROCEDURE HEADER_TITLE (P_PAGE_PK         IN VARCHAR2,
                            P_HERO_TITLE IN OUT VARCHAR2);

    -- =========================================================================
    -- FORM LEVEL                                   (Forms: form-level triggers)
    -- =========================================================================
    -- Source: <FORM>.WHEN-NEW-FORM-INSTANCE   APEX: Process "WHEN-NEW-FORM-INSTANCE" (Before Header)
    PROCEDURE INIT_FORM (P_<PARAM> IN VARCHAR2,
                         P_PAGE_PK       IN OUT VARCHAR2);

    -- Source: <FORM>.PRE-FORM                  APEX: Process "PRE-FORM" (Before Header)
    -- PROCEDURE PRE_FORM (...);

    -- Source: <FORM>.PRE-COMMIT                APEX: Process "PRE-COMMIT" (before the DML processes)
    -- PROCEDURE PRE_COMMIT (...);

    -- =========================================================================
    -- BLOCK <BLOCK>  (master, single record)       (Forms: block + item triggers)
    -- =========================================================================
    -- Source: <BLOCK>.<ITEM>.WHEN-VALIDATE-ITEM
    -- APEX  : Validation "<ITEM> VALIDATION" (PL/SQL Function Body returning Error Text)
    --           return <FORM>.<ITEM>_VALIDATION(P_<ITEM> => :P<page>_<ITEM>);
    --         DA "<ITEM> WHEN-VALIDATE-ITEM" (change, FOS Execute PL/SQL Code)
    --           <FORM>.CHECK_ERROR(<FORM>.<ITEM>_VALIDATION(P_<ITEM> => :P<page>_<ITEM>));
    FUNCTION  <ITEM>_VALIDATION (P_<ITEM> IN VARCHAR2) RETURN VARCHAR2;

    -- Source: Make_Field_Entrable('<BLOCK>.<ITEM>', FALSE) in <trigger>
    -- APEX  : item P<page>_<ITEM> Read Only = PL/SQL Expression <FORM>.<ITEM>_IS_READ_ONLY(I_... => :...)
    --         (or native Enable / Disable in the DA of the item that changes the rule)
    FUNCTION  <ITEM>_IS_READ_ONLY (P_<OTHER_ITEM> IN VARCHAR2) RETURN BOOLEAN;

    -- Source: SET_ITEM_PROPERTY('<BLOCK>.<ITEM>', REQUIRED, PROPERTY_TRUE) in <trigger>
    -- APEX  : server-side condition of Validation "<ITEM> REQUIRED"
    FUNCTION  <ITEM>_IS_REQUIRED (P_<OTHER_ITEM> IN VARCHAR2) RETURN BOOLEAN;

    -- Source: <BLOCK>.<ITEM>.WHEN-VALIDATE-ITEM - the part that derives other item values
    -- APEX  : same DA, FOS "Items to Return" = the IO_ items
    -- PROCEDURE <ITEM>_WHEN_VALIDATE_ITEM (P_<ITEM> IN VARCHAR2, P_<ITEM2> IN OUT VARCHAR2);

    -- Source: <BLOCK>.WHEN-VALIDATE-RECORD     APEX: Validation "<BLOCK> WHEN-VALIDATE-RECORD"
    FUNCTION  <BLOCK>_WHEN_VALIDATE_RECORD (P_START_DATE IN DATE,
                           P_END_DATE   IN DATE) RETURN VARCHAR2;

    -- Source: <BLOCK>.PRE-INSERT / PRE-UPDATE / PRE-DELETE
    -- APEX  : Processes "PRE-INSERT" (:P0_PAGE_PK is null and :REQUEST = 'CREATE'),
    --         "PRE-UPDATE" (:P0_PAGE_PK is not null and :REQUEST = 'SAVE'), "PRE-DELETE" (DELETE),
    --         placed BEFORE "Process form" (standard section 6)
    PROCEDURE PRE_INSERT (P_<PK>  IN OUT VARCHAR2,
                          SSO_APP_USER   IN VARCHAR2);
    PROCEDURE PRE_UPDATE (P_<PK>   IN VARCHAR2,
                          SSO_APP_USER   IN VARCHAR2);
    PROCEDURE PRE_DELETE (P_<PK>   IN VARCHAR2);

    -- Source: <BLOCK>.POST-INSERT              APEX: Process "POST-INSERT" (after "Process form")
    -- PROCEDURE POST_INSERT (P_<PK> IN VARCHAR2);

    -- Source: <BLOCK>.POST-QUERY               APEX: column in region SQL / view
    FUNCTION  POST_QUERY (LOOKUP_ID IN NUMBER) RETURN VARCHAR2;

    -- Source: <BLOCK>.<BUTTON>.WHEN-BUTTON-PRESSED
    -- APEX  : Button <BUTTON> + Process "<BUTTON> WHEN-BUTTON-PRESSED"
    -- PROCEDURE <BUTTON>_WHEN_BUTTON_PRESSED (P_<PK> IN VARCHAR2);

    -- =========================================================================
    -- BLOCK <DETAIL_BLOCK>  (detail, Interactive Grid)  members prefixed <DETAIL_BLOCK>_
    -- =========================================================================
    -- Source: <DETAIL_BLOCK>.<COLUMN>.WHEN-VALIDATE-ITEM
    -- APEX  : DA "<DETAIL_BLOCK> <COLUMN> WHEN-VALIDATE-ITEM" (column change)
    FUNCTION  <DETAIL_BLOCK>_<COLUMN>_VALIDATION (<COLUMN> IN VARCHAR2) RETURN VARCHAR2;

    -- Source: <DETAIL_BLOCK>.PRE-INSERT
    -- APEX  : Process "<DETAIL_BLOCK> PRE-INSERT" (Editable Region = IG, :APEX$ROW_STATUS = 'C'),
    --         before "<DETAIL_BLOCK> - Save Interactive Grid Data"
    PROCEDURE <DETAIL_BLOCK>_PRE_INSERT (P_<PK> IN VARCHAR2,
                                       <FK>        IN OUT VARCHAR2,
                                       <DETAIL_PK> IN OUT VARCHAR2);

    -- =========================================================================
    -- PROGRAM UNITS                                (Forms: Program Units node, same names)
    -- =========================================================================
    -- PROCEDURE <PROGRAM_UNIT_NAME> (...);
    -- FUNCTION  <PROGRAM_UNIT_NAME> (...) RETURN ...;

END <FORM>;
/
SHOW ERRORS

-- -----------------------------------------------------------------------------
-- Synonym and grants (run as a user allowed to create public synonyms / grant on LIB_APX_USR)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PUBLIC SYNONYM <FORM> FOR LIB_APX_USR.<FORM>;

GRANT EXECUTE ON LIB_APX_USR.<FORM> TO LIB_USR;

GRANT EXECUTE ON LIB_APX_USR.<FORM> TO SECURITY_DEFAULT;

GRANT EXECUTE ON LIB_APX_USR.<FORM> TO SECURITY_PROD;

-- CUSTOMS = parsing schema of the APEX application (APEX needs a direct grant, not a role)
GRANT EXECUTE ON LIB_APX_USR.<FORM> TO CUSTOMS;
