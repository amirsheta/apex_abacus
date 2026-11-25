-- =============================================================================
-- Package     : IMPR1150  (form IMPR1150.fmb, module IMPR1150_PROD_CENTRL: activation of the importers
--               registered on the Fasah platform - "المستوردين من منصة فسح")
-- Owner       : LIB_APX_USR (public synonym IMPR1150; EXECUTE granted to LIB_USR, SECURITY_DEFAULT, SECURITY_PROD, CUSTOMS)
-- Version     : 001 (25-11-2026: step 02 - first version)
-- Author      : Claude Code
-- Status      : NOT COMPILED.
-- Source      : forms/IMPR/IMPR1150_fmb.xml; analysis analysis/IMPR1150/IMPR1150_inventory.md and
--               analysis/IMPR1150/IMPR1150_logic_extraction.md.
-- Data source : as in Forms (user decision 2026-11-25): the importer is read and updated at HQ through the
--               database link, CUSTOMS.IMPORTERS_CENTRAL@HQPRD.HQ.CUSTOMS.GOV, PORT_CD 99
--               (WHEN-NEW-FORM-INSTANCE SET_BLOCK_PROPERTY(QUERY_DATA_SOURCE_NAME), EXEC_FUNS UPDATE ...@HQPRD).
--               The look-ups (IMPR_TYPES, BUS_ID_TYPES, COUNTRIES, CITIES), the documents (IMPORTERS_DOCS) and
--               the Designer key check (CGUV$CHK_IMP_CNTRL_PK) use the local tables, as in Forms.
--               LIB_APX_USR needs a usable link HQPRD.HQ.CUSTOMS.GOV (public, or its own) - see
--               apex/IMPR1150/import_notes.md.
-- Layout      : VERSION -> f345 HELPERS -> BLOCK IMPORTERS_CENTRAL (query, items, DML requests) -> FUNCTIONS.
--               Parameters have no I_ / IO_ / O_ prefix; a page item P1150_X is passed as P_X, application items
--               keep their name (P_CURR_PORT_CD, SSO_APP_USER, P_GLOBAL_V_WS_ID); P0_PAGE_PK as P_PAGE_PK.
-- Key         : the page key P0_PAGE_PK is IMPR_NBR (the record is remote: no local ROWID).
-- =============================================================================
SET DEFINE OFF

CREATE OR REPLACE PACKAGE LIB_APX_USR.IMPR1150 AS
   V_PKG_VERSION       VARCHAR2 (100) := 'VERSION NO. IS:' || '001';
   V_PKG_VERSION_QC    VARCHAR2 (100) := 'VERSION NO. IS:' || '001';
   V_PKG_VERSION_DEV   VARCHAR2 (100) := 'VERSION NO. IS:' || '001';
   FUNCTION PKG_VERSION
      RETURN VARCHAR2;
   V_PACKAGE_NAME      VARCHAR2 (50) := 'IMPR1150';
   V_LAST_MODIFY_DT    VARCHAR2 (10) := '25-11-2026';
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

    -- =========================================================================
    -- f345 HELPERS
    -- =========================================================================

    -- f345 key check: P0_PAGE_PK = IMPR_NBR of an importer at HQ (PORT_CD 99) inside the block WHERE clause
    -- (PORT_CD = :PARAMETER.P_CURR_PORT_CD); anything else -> NULL (empty page).
    -- APEX  : Before Header process "P0_PAGE_PK CHECK" (seq 20)
    PROCEDURE P0_PAGE_PK_CHECK (P_PAGE_PK      IN OUT VARCHAR2,
                                P_CURR_PORT_CD IN     NUMBER);

    -- Source: IMPORTERS_CENTRAL.PRE-QUERY + WHEN-NEW-ITEM-INSTANCE (:GLOBAL.EXEC_QUERY_NOW = 1 -> EXECUTE_QUERY)
    --         after IMPR_NBR / BUS_ID WHEN-VALIDATE-ITEM: the key of the record to show, IMPR_NBR first, then BUS_ID.
    -- APEX  : After Submit process "EXECUTE-QUERY" (request EXECUTE_QUERY): :P0_PAGE_PK := IMPR1150.IMPORTER_KEY(...)
    FUNCTION IMPORTER_KEY (P_IMPR_NBR     IN NUMBER,
                           P_BUS_ID       IN VARCHAR2,
                           P_CURR_PORT_CD IN NUMBER) RETURN VARCHAR2;

    -- =========================================================================
    -- BLOCK IMPORTERS_CENTRAL
    -- =========================================================================

    -- Source: IMPORTERS_CENTRAL.POST-QUERY (names of the codes; local tables)
    -- APEX  : Before Header process "POST-QUERY" after "Initialize form" (record shown)
    PROCEDURE POST_QUERY (P_IMPR_TYPE_CD       IN  NUMBER,
                          P_IMPR_TYPE_NAME     OUT VARCHAR2,
                          P_BUS_ID_TYPE_CD     IN  NUMBER,
                          P_BUS_ID_TYPE_NAME   OUT VARCHAR2,
                          P_CTRY_CD            IN  NUMBER,
                          P_CRTY_ARBC_NAME     OUT VARCHAR2,
                          P_ADD_CTRY_CD        IN  NUMBER,
                          P_ADD_CRTY_ARBC_NAME OUT VARCHAR2,
                          P_CITY_CODE          IN  NUMBER,
                          P_CITY_NAME          OUT VARCHAR2);

    -- Source: IMPORTERS_CENTRAL.IMPR_NBR.WHEN-VALIDATE-ITEM (pending importer at HQ, message 9-150;
    --         + Designer key check CGUV$CHK_IMP_CNTRL_PK on the local IMPORTERS_CENTRAL)
    -- APEX  : validation "IMPR_NBR VALIDATION" (request EXECUTE_QUERY) and DA "IMPR_NBR WHEN-VALIDATE-ITEM"
    --         (FORMS_APX.CHECK_ERROR, then Submit Page EXECUTE_QUERY). NULL = valid.
    FUNCTION IMPR_NBR_VALIDATION (P_PORT_CD  IN NUMBER,
                                  P_IMPR_NBR IN NUMBER) RETURN VARCHAR2;

    -- Source: IMPORTERS_CENTRAL.BUS_ID.WHEN-VALIDATE-ITEM (pending importer at HQ, message 9-150)
    -- APEX  : validation "BUS_ID VALIDATION" (request EXECUTE_QUERY) and DA "BUS_ID WHEN-VALIDATE-ITEM". NULL = valid.
    FUNCTION BUS_ID_VALIDATION (P_BUS_ID IN VARCHAR2) RETURN VARCHAR2;

    -- Source: block IMPORTERS_CENTRAL - the page 0 CREATE request: no record is ever inserted from this form
    --         (every typed IMPR_NBR / BUS_ID leads to a query or to message 9-150)
    -- APEX  : After Submit process "PRE-INSERT" (request CREATE): refused with a message
    PROCEDURE PRE_INSERT;

    -- Source: IMPORTERS_CENTRAL.PRE-UPDATE (STR.DISPALERT INFORMATION, no raise)
    -- APEX  : After Submit process "PRE-UPDATE" (request SAVE); the page has no DML (block Update Allowed = false)
    PROCEDURE PRE_UPDATE (P_REJCT_RESON IN VARCHAR2);

    -- Source: block IMPORTERS_CENTRAL Delete Allowed = false (FORM.KEY-DELREC -> NIB.KEY_DELREC)
    -- APEX  : After Submit process "PRE-DELETE" (request DELETE): refused with a message
    PROCEDURE PRE_DELETE;

    -- =========================================================================
    -- FUNCTIONS (f345 Page Functions list in the page 0 FUNCS drawer)
    -- =========================================================================

    -- Source: PU ADJ_FUNS (TMPLT.ENABLE_FUN / DISABLE_FUN of IMPR1150_ACTIVATE, IMPR1150_REJECT)
    -- APEX  : Computation P1150_ADJ_FUNS (After Header): comma list of the enabled functions
    FUNCTION ADJ_FUNS (P_PENDING_ACTIVE IN NUMBER) RETURN VARCHAR2;

    -- Source: PU EXEC_FUNS (IMPR1150_ACTIVATE: PENDING_ACTIVE 1 + activity 1; IMPR1150_REJECT: PENDING_ACTIVE 2,
    --         IMPR_REJCT_RESON = REJCT_RESON + activity 2), CR-7234
    -- APEX  : After Submit processes "IMPR1150_ACTIVATE EXECUTE-FUNCTION" / "IMPR1150_REJECT EXECUTE-FUNCTION"
    --         (requests of the same name, sent by the function DAs); the success message is the process message.
    PROCEDURE EXEC_FUNS (P_FUNCTION_CODE  IN VARCHAR2,
                         P_PORT_CD        IN NUMBER,
                         P_IMPR_NBR       IN NUMBER,
                         P_REJCT_RESON    IN VARCHAR2,
                         P_CURR_PORT_CD   IN NUMBER,
                         SSO_APP_USER     IN VARCHAR2,
                         P_GLOBAL_V_WS_ID IN VARCHAR2);

END IMPR1150;
/
SHOW ERRORS

-- -----------------------------------------------------------------------------
-- Synonym and grants (run as a user allowed to create public synonyms / grant on LIB_APX_USR).
-- CUSTOMS = parsing schema of the APEX application: APEX needs the direct grant.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PUBLIC SYNONYM IMPR1150 FOR LIB_APX_USR.IMPR1150;

GRANT EXECUTE ON LIB_APX_USR.IMPR1150 TO LIB_USR;

GRANT EXECUTE ON LIB_APX_USR.IMPR1150 TO SECURITY_DEFAULT;

GRANT EXECUTE ON LIB_APX_USR.IMPR1150 TO SECURITY_PROD;

GRANT EXECUTE ON LIB_APX_USR.IMPR1150 TO CUSTOMS;
