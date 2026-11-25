-- =============================================================================
-- Package     : IMPR1170             (upper-case form name, no prefix - f345 standard)
-- Source form : IMPR1170.fmb (Oracle Forms 12c, module IMPR1170_CNTRL) - commercial-registration data from the
--               Ministry of Commerce ("جدول بيانات السجل التجارى من وزارة التجارة"): MCI_DATA + its owners MCI_OWNERS,
--               refreshed through the MCI web service when the registration was not loaded today
-- Target      : Oracle APEX 21.2 / Oracle Database 12.1.0.2, reference application f345
--               main page 1170 (IMPR1170), search page 117001 (IMPR1170_SEARCH)
-- Author      : Claude Code
-- Created     : 2026-11-25
-- Version     : 001
-- Purpose     : Business logic of the form, organised like the form itself:
--               VERSION -> f345 HELPERS -> BLOCK MCI_DATA (query, items, DML requests) (docs/f345_reference_standard.md §10).
--               Block MCI_OWNERS has no member: it is a read-only grid whose POST-QUERY look-up is an outer join
--               in the grid query (page spec §3). No UI state, no session-state reads.
-- Parameters  : no I_ / IO_ / O_ prefix (the mode is in IN / IN OUT / OUT). A parameter carrying the page
--               item P1170_<ITEM> is named P_<ITEM> (P_CR_NBR => :P1170_CR_NBR, P_PAGE_PK => :P0_PAGE_PK).
--               Inside SQL a parameter is qualified with its member name (POST_QUERY.P_CR_STATUS).
-- Key         : the page key P0_PAGE_PK is CR_NBR (MCI_DATA_PK, the master key of the relation to MCI_OWNERS).
-- Rules       : every identifier <= 30 bytes (DB 12.1.0.2); no qualified expressions (18c);
--               no COMMIT / ROLLBACK here (the web-service package does its own work, as in Forms).
-- Owner       : LIB_APX_USR; public synonym IMPR1170 + EXECUTE grants at the end of this file.
-- Status      : NOT COMPILED. Depends on DB package LIB_USR.PRTL_NEBRAS_SERVICES (CALL_WEB_SERVICE: MISSING SOURCE,
--               call copied unchanged from the Forms code) and on the tables MCI_DATA, MCI_BUS_ID_STATUS (DDL MISSING SOURCE).
-- History     : 2026-11-25 Claude Code 001 Initial migration (step 02)
-- =============================================================================
SET DEFINE OFF

CREATE OR REPLACE PACKAGE LIB_APX_USR.IMPR1170 AS
   V_PKG_VERSION       VARCHAR2 (100) := 'VERSION NO. IS:' || '001';
   V_PKG_VERSION_QC    VARCHAR2 (100) := 'VERSION NO. IS:' || '001';
   V_PKG_VERSION_DEV   VARCHAR2 (100) := 'VERSION NO. IS:' || '001';

   FUNCTION PKG_VERSION
      RETURN VARCHAR2;

   V_PACKAGE_NAME      VARCHAR2 (50) := 'IMPR1170';
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
    -- f345 HELPERS  (the common ones are in FORMS_APX; this form keeps its own key check)
    -- =========================================================================
    -- APEX  : Process "P0_PAGE_PK CHECK" (Before Header). P0_PAGE_PK holds CR_NBR of a cached MCI_DATA row
    --         (search page 117001, or the process "CR_NBR KEY-NEXT-ITEM"); any other value is dropped.
    PROCEDURE P0_PAGE_PK_CHECK (P_PAGE_PK IN OUT VARCHAR2);

    -- =========================================================================
    -- BLOCK MCI_DATA  (single record, query only; detail MCI_OWNERS by CR_NBR)
    -- =========================================================================
    -- Source: MCI_DATA.POST-QUERY (description of the registration status from MCI_BUS_ID_STATUS)
    -- APEX  : Process "POST-QUERY" (Before Header, after "Initialize form", when P1170_CR_NBR is not null)
    PROCEDURE POST_QUERY (P_CR_STATUS    IN     VARCHAR2,
                          P_CR_STAT_DESC IN OUT VARCHAR2);

    -- Source: MCI_DATA.CR_NBR.KEY-NEXT-ITEM (cached today -> query; else MCI web service, 'success' -> query,
    --         otherwise the "not active / not available" error). SET_BLOCK_PROPERTY(DEFAULT_WHERE) + EXECUTE_QUERY
    --         become the page key: P_PAGE_PK = CR_NBR of the record to show.
    -- APEX  : DA "CR_NBR KEY-NEXT-ITEM" (Change -> Submit Page EXECUTE_QUERY) + After Submit process
    --         "CR_NBR KEY-NEXT-ITEM" (request EXECUTE_QUERY); the branch "EXECUTE-QUERY" shows the record.
    PROCEDURE CR_NBR_KEY_NEXT_ITEM (P_CR_NBR  IN     VARCHAR2,
                                    P_PAGE_PK IN OUT VARCHAR2);

    -- Source: MCI_DATA.CR_NBR.WHEN-VALIDATE-ITEM is NULL; MCI_DATA.CR_ISSUE_DATE / CR_EXPIRY_DATE WHEN-VALIDATE-ITEM
    --         (HIJDATE.VALID_HIJ_DATE) never fire: both items are not enterable. No member.

    -- Source: block MCI_DATA - page 0 CREATE. Forms lets SAVE insert the new record (CR_NBR, CR_TYPE 1) without the
    --         look-up; the page refuses it (page spec §0 #3, inventory §15 #1: to confirm).
    -- APEX  : After Submit process "PRE-INSERT" (request CREATE): refused with a message
    PROCEDURE PRE_INSERT;

    -- Source: block MCI_DATA Update Allowed = false (every item Update Allowed = false)
    -- APEX  : After Submit process "PRE-UPDATE" (request SAVE): refused with a message
    PROCEDURE PRE_UPDATE;

    -- Source: block MCI_DATA Delete Allowed = false (FORM.KEY-DELREC -> NIB.KEY_DELREC)
    -- APEX  : After Submit process "PRE-DELETE" (request DELETE): refused with a message
    PROCEDURE PRE_DELETE;

    -- =========================================================================
    -- PROGRAM UNITS                                (Forms: Program Units node)
    -- =========================================================================
    -- PU EXEC_FUNS, ADJ_FUNS  -> empty in Forms (NULL;, the broker-authorization code is commented out): no member
    -- PU CGDV$POPULATE_DYNAMIC_LISTS -> LOV LOV_COMM_RGSTRTN_TYPE on P1170_CR_TYPE (IMPR1130, reused): no member

END IMPR1170;
/
SHOW ERRORS

-- -----------------------------------------------------------------------------
-- Synonym and grants (run as a user allowed to create public synonyms / grant on LIB_APX_USR)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PUBLIC SYNONYM IMPR1170 FOR LIB_APX_USR.IMPR1170;

GRANT EXECUTE ON LIB_APX_USR.IMPR1170 TO LIB_USR;

GRANT EXECUTE ON LIB_APX_USR.IMPR1170 TO SECURITY_DEFAULT;

GRANT EXECUTE ON LIB_APX_USR.IMPR1170 TO SECURITY_PROD;

-- CUSTOMS = parsing schema of the APEX application (APEX needs a direct grant, not a role)
GRANT EXECUTE ON LIB_APX_USR.IMPR1170 TO CUSTOMS;
