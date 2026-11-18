-- =============================================================================
-- Package     : <FORM>              (upper-case form name, no prefix - f345 standard, e.g. AGR1100)
--               replace <FORM>, <page>, <BLOCK>, <BLOCK_ABBR>, <ITEM>, <PK> everywhere
-- Source form : <FORM>.fmb (Oracle Forms 12c)
-- Target      : Oracle APEX 21.2 / Oracle Database 12.1.0.2, reference application f345
-- Author      : <author>
-- Created     : <YYYY-MM-DD>
-- Version     : 1.0.0
-- Purpose     : Business logic of the form, organised like the form itself:
--               FORM LEVEL -> one section per BLOCK -> PROGRAM UNITS.
--               Member and component names: docs/f345_reference_standard.md section 5.
-- Parameters  : members called by APEX use I_ (IN) / IO_ (IN OUT) / O_ (OUT) + the bind name
--               (IO_P<page>_<ITEM> => :P<page>_<ITEM>, I_<COLUMN> => :<COLUMN> for IG columns,
--               I_SSO_APP_USER => :SSO_APP_USER). Internal members use p_<name>.
--               The package never reads page items itself, so it is testable without APEX.
-- Rules       : every identifier <= 30 bytes (DB 12.1.0.2); no qualified expressions (18c).
-- History     : <YYYY-MM-DD> <author> 1.0.0 Initial migration
-- =============================================================================
SET DEFINE OFF

CREATE OR REPLACE PACKAGE <FORM>
AUTHID DEFINER
AS
    c_version CONSTANT VARCHAR2(10) := '1.0.0';

    -- =========================================================================
    -- f345 HELPERS                                 (every form package has these)
    -- =========================================================================
    -- Raises the error text; used by dynamic actions: <FORM>.CHK(<FORM>.<ITEM>_VAL(...))
    PROCEDURE CHK (I_ERR IN VARCHAR2);

    -- Error text when a required value is empty, else NULL
    -- APEX  : Validation "<ITEM> REQUIRED": return <FORM>.REQUIRED_VAL(:P<page>_<ITEM>, '<label>');
    FUNCTION  REQUIRED_VAL (I_VALUE IN VARCHAR2, I_LABEL IN VARCHAR2) RETURN VARCHAR2;

    -- APEX  : Process "P0_PAGE_PK CHECK" (Before Header) - drops a key that no longer exists
    PROCEDURE P0_PAGE_PK_CHECK (IO_P0_PAGE_PK IN OUT VARCHAR2);

    -- APEX  : Process "PARAMETERS": :P<page>_MODULE_ID := <FORM>.GET_MODULE_ID(...)
    FUNCTION  GET_MODULE_ID (I_P<page>_MODULE_ID IN VARCHAR2) RETURN VARCHAR2;

    -- APEX  : Process "HEADER TITLE" (Before Header) - title of the hero region
    PROCEDURE HEADER_TITLE (I_P0_PAGE_PK         IN VARCHAR2,
                            IO_P<page>_HERO_TITLE IN OUT VARCHAR2);

    -- =========================================================================
    -- FORM LEVEL                                   (Forms: form-level triggers)
    -- =========================================================================
    -- Source: <FORM>.WHEN-NEW-FORM-INSTANCE   APEX: Process "WHEN-NEW-FORM-INSTANCE" (Before Header)
    PROCEDURE INIT_FORM (I_P<page>_P_<PARAM> IN VARCHAR2,
                         IO_P0_PAGE_PK       IN OUT VARCHAR2);

    -- Source: <FORM>.PRE-FORM                  APEX: Process "PRE-FORM" (Before Header)
    -- PROCEDURE PRE_FORM (...);

    -- Source: <FORM>.PRE-COMMIT                APEX: Process "PRE-COMMIT" (before the DML processes)
    -- PROCEDURE PRE_COMMIT (...);

    -- =========================================================================
    -- BLOCK <BLOCK>  (master, single record)       (Forms: block + item triggers)
    -- =========================================================================
    -- Source: <BLOCK>.<ITEM>.WHEN-VALIDATE-ITEM
    -- APEX  : Validation "<ITEM> VALIDATION" (PL/SQL Function Body returning Error Text)
    --           return <FORM>.<ITEM>_VAL(I_P<page>_<ITEM> => :P<page>_<ITEM>);
    --         DA "<ITEM> WHEN-VALIDATE-ITEM" (change, FOS Execute PL/SQL Code)
    --           <FORM>.CHK(<FORM>.<ITEM>_VAL(I_P<page>_<ITEM> => :P<page>_<ITEM>));
    FUNCTION  <ITEM>_VAL (I_P<page>_<ITEM> IN VARCHAR2) RETURN VARCHAR2;

    -- Source: <BLOCK>.<ITEM>.WHEN-VALIDATE-ITEM - the part that derives other item values
    -- APEX  : same DA, FOS "Items to Return" = the IO_ items
    -- PROCEDURE <ITEM>_WVI (I_P<page>_<ITEM> IN VARCHAR2, IO_P<page>_<ITEM2> IN OUT VARCHAR2);

    -- Source: <BLOCK>.WHEN-VALIDATE-RECORD     APEX: Validation "<BLOCK> WHEN-VALIDATE-RECORD"
    FUNCTION  <BLOCK>_WVR (I_P<page>_START_DATE IN DATE,
                           I_P<page>_END_DATE   IN DATE) RETURN VARCHAR2;

    -- Source: <BLOCK>.PRE-INSERT / PRE-UPDATE / PRE-DELETE
    -- APEX  : Processes "PRE-INSERT" (:P0_PAGE_PK is null and :REQUEST = 'CREATE'),
    --         "PRE-UPDATE" (:P0_PAGE_PK is not null and :REQUEST = 'SAVE'), "PRE-DELETE" (DELETE),
    --         placed BEFORE "Process form" (standard section 6)
    PROCEDURE PRE_INSERT (IO_P<page>_<PK>  IN OUT VARCHAR2,
                          I_SSO_APP_USER   IN VARCHAR2);
    PROCEDURE PRE_UPDATE (I_P<page>_<PK>   IN VARCHAR2,
                          I_SSO_APP_USER   IN VARCHAR2);
    PROCEDURE PRE_DELETE (I_P<page>_<PK>   IN VARCHAR2);

    -- Source: <BLOCK>.POST-INSERT              APEX: Process "POST-INSERT" (after "Process form")
    -- PROCEDURE POST_INSERT (I_P<page>_<PK> IN VARCHAR2);

    -- Source: <BLOCK>.POST-QUERY               APEX: column in region SQL / view
    FUNCTION  POST_QUERY (I_LOOKUP_ID IN NUMBER) RETURN VARCHAR2;

    -- Source: <BLOCK>.<BUTTON>.WHEN-BUTTON-PRESSED
    -- APEX  : Button <BUTTON> + Process "<BUTTON> WHEN-BUTTON-PRESSED"
    -- PROCEDURE <BUTTON>_WBP (I_P<page>_<PK> IN VARCHAR2);

    -- =========================================================================
    -- BLOCK <DETAIL_BLOCK>  (detail, Interactive Grid)  members prefixed <BLOCK_ABBR>_
    -- =========================================================================
    -- Source: <DETAIL_BLOCK>.<COLUMN>.WHEN-VALIDATE-ITEM
    -- APEX  : DA "<DETAIL_BLOCK> <COLUMN> WHEN-VALIDATE-ITEM" (column change)
    FUNCTION  <BLOCK_ABBR>_<COLUMN>_VAL (I_<COLUMN> IN VARCHAR2) RETURN VARCHAR2;

    -- Source: <DETAIL_BLOCK>.PRE-INSERT
    -- APEX  : Process "<DETAIL_BLOCK> PRE-INSERT" (Editable Region = IG, :APEX$ROW_STATUS = 'C'),
    --         before "<DETAIL_BLOCK> - Save Interactive Grid Data"
    PROCEDURE <BLOCK_ABBR>_PRE_INSERT (I_P<page>_<PK> IN VARCHAR2,
                                       IO_<FK>        IN OUT VARCHAR2,
                                       IO_<DETAIL_PK> IN OUT VARCHAR2);

    -- =========================================================================
    -- PROGRAM UNITS                                (Forms: Program Units node, same names)
    -- =========================================================================
    -- PROCEDURE <PROGRAM_UNIT_NAME> (...);
    -- FUNCTION  <PROGRAM_UNIT_NAME> (...) RETURN ...;

END <FORM>;
/
SHOW ERRORS
