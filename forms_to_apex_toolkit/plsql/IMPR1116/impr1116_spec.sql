-- =============================================================================
-- Package     : IMPR1116             (upper-case form name, no prefix - f345 standard)
-- Source form : IMPR1116.fmb (Oracle Forms 12c) - "شاشة استعراض بيانات رقم المنشأة 700 المدخلة من البوابة"
--               (review of the establishment number 700 data entered through the portal)
-- Target      : Oracle APEX 21.2 / Oracle Database 12.1.0.2, reference application f345
--               main page 1116 (IMPR1116), search page 111601 (IMPR1116_SEARCH)
-- Author      : Claude Code
-- Created     : 2026-11-24
-- Version     : 001
-- Purpose     : Business logic of the form, organised like the form itself:
--               VERSION -> f345 HELPERS -> FORM LEVEL -> BLOCK IMPR_PRTL_NAT (master, review status)
--               -> BLOCK IMPORTERS (detail, query only) -> PROGRAM UNITS
--               (docs/f345_reference_standard.md §10). No UI state, no session-state reads.
--               The form has almost no business logic: the review status REVIEW_FLAG is the only
--               updatable column, every DML writes the activity log, and the importer grid is a
--               query (region SQL on page 1116, analysis/IMPR1116/IMPR1116_logic_extraction.md §5).
-- Parameters  : no I_ / IO_ / O_ prefix (the mode is in IN / IN OUT / OUT). A parameter carrying the
--               page item P<page>_<ITEM> is named P_<ITEM> (P_PRTL_NAT_ISN => :P1116_PRTL_NAT_ISN,
--               P_PAGE_PK => :P0_PAGE_PK); f345 application items keep their name
--               (P_CURR_PORT_CD => :P_CURR_PORT_CD, SSO_APP_USER => :SSO_APP_USER,
--               P_GLOBAL_V_WS_ID => :P_GLOBAL_V_WS_ID). Inside SQL a parameter is qualified with its
--               member name. Internal members keep p_<name>. Rule: scripts/parameter_names.py.
--               Common helpers (CHECK_ERROR, REQUIRED_VALIDATION, GET_MODULE_ID, HEADER_TITLE,
--               ROWID_FROM_URL, FORM_TRIGGER_FAILURE ...) are in FORMS_APX (version 004) and called as
--               FORMS_APX.<NAME>. The package never reads page items itself, so it is testable without APEX.
-- Rules       : every identifier <= 30 bytes (DB 12.1.0.2); no qualified expressions (18c);
--               no COMMIT / ROLLBACK (APEX commits after page processing).
-- Owner       : LIB_APX_USR; public synonym IMPR1116 + EXECUTE grants at the end of this file.
-- Status      : NOT COMPILED. Needs direct grants to LIB_APX_USR on IMPR_PRTL_NAT and ACTIVITY_DB,
--               and FORMS_APX 004 (inventory §15 #10).
-- History     : 2026-11-24 Claude Code 001 Initial migration (step 02)
-- =============================================================================
SET DEFINE OFF

CREATE OR REPLACE PACKAGE LIB_APX_USR.IMPR1116 AS
   V_PKG_VERSION       VARCHAR2 (100) := 'VERSION NO. IS:' || '001';
   V_PKG_VERSION_QC    VARCHAR2 (100) := 'VERSION NO. IS:' || '001';
   V_PKG_VERSION_DEV   VARCHAR2 (100) := 'VERSION NO. IS:' || '001';
   FUNCTION PKG_VERSION
      RETURN VARCHAR2;
   V_PACKAGE_NAME      VARCHAR2 (50) := 'IMPR1116';
   V_LAST_MODIFY_DT    VARCHAR2 (10) := '24-11-2026';
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
    -- f345 HELPERS  (the common ones are in FORMS_APX: CHECK_ERROR, REQUIRED_VALIDATION, GET_MODULE_ID,
    --               HEADER_TITLE, ROWID_FROM_URL ...; this form keeps its own key check)
    -- =========================================================================

    -- APEX  : Process "P0_PAGE_PK CHECK" (Before Header 20). P0_PAGE_PK holds the ROWID of the
    --         IMPR_PRTL_NAT row chosen on the search page 111601 (passed URL-safe:
    --         TRANSLATE(ROWID, '+/', '-_'); FORMS_APX.ROWID_FROM_URL translates it back). A value that is not
    --         a row of IMPR_PRTL_NAT is dropped. A reviewed row (REVIEW_FLAG <> 0) is kept, so the record
    --         stays on the page after SAVE, as in Forms until the next query.
    PROCEDURE P0_PAGE_PK_CHECK (P_PAGE_PK IN OUT VARCHAR2);

    -- =========================================================================
    -- FORM LEVEL                                   (Forms: form-level triggers)
    -- =========================================================================
    -- No business logic: PRE-FORM, WHEN-NEW-FORM-INSTANCE and the KEY-* triggers are the CIC_OLB frame
    -- (NIB library) replaced by the f345 shell; the form-specific part of WHEN-NEW-FORM-INSTANCE only hides
    -- two LOV buttons and changes item widths (see UI LOGIC at the end of the body).

    -- =========================================================================
    -- BLOCK IMPR_PRTL_NAT  (master; Forms: 5 rows, Insert / Delete not allowed, only REVIEW_FLAG updatable)
    -- =========================================================================
    -- Source: block IMPR_PRTL_NAT, WHERE clause (REVIEW_FLAG = 0 AND GAZT_NAME IS NOT NULL)
    -- APEX  : search page 111601, region SQL ... WHERE IMPR1116.IMPR_PRTL_NAT_IS_PENDING(n.REVIEW_FLAG,
    --         n.GAZT_NAME) = 'Y'. Usable in SQL (public function returning VARCHAR2).
    FUNCTION  IMPR_PRTL_NAT_IS_PENDING (REVIEW_FLAG IN NUMBER,
                                        GAZT_NAME   IN VARCHAR2) RETURN VARCHAR2;

    -- Source: IMPR_PRTL_NAT.PRE-INSERT (activity log, type 1) + block property Insert Allowed = false
    -- APEX  : Process "PRE-INSERT" (After Submit 10, request CREATE of the page 0 toolbar): refuses the
    --         insert, the Forms block cannot create records.
    PROCEDURE PRE_INSERT;

    -- Source: IMPR_PRTL_NAT.PRE-UPDATE (activity log ACTIVITY.ADD_ACTIVITY(9, 8, 2, PRTL_NAT_ISN))
    -- APEX  : Process "PRE-UPDATE" (After Submit 20, request SAVE, P0_PAGE_PK not null):
    --           IMPR1116.PRE_UPDATE(P_PRTL_NAT_ISN => :P1116_PRTL_NAT_ISN, P_CURR_PORT_CD => :P_CURR_PORT_CD,
    --                               SSO_APP_USER => :SSO_APP_USER, P_GLOBAL_V_WS_ID => :P_GLOBAL_V_WS_ID);
    -- Errors: the ACTIVITY_DB message (Forms alert CFG_SYSTEM_ERROR) when the log cannot be written.
    PROCEDURE PRE_UPDATE (P_PRTL_NAT_ISN   IN NUMBER,
                          P_CURR_PORT_CD   IN NUMBER,
                          SSO_APP_USER     IN VARCHAR2,
                          P_GLOBAL_V_WS_ID IN VARCHAR2);

    -- Source: IMPR_PRTL_NAT.PRE-DELETE (activity log, type 3) + block property Delete Allowed = false
    -- APEX  : Process "PRE-DELETE" (After Submit 30, request DELETE of the page 0 toolbar): refuses the delete.
    PROCEDURE PRE_DELETE;

    -- =========================================================================
    -- BLOCK IMPORTERS  (detail, query only; Forms: no relation, WHERE on :IMPR_PRTL_NAT.*)
    -- =========================================================================
    -- No member: the query (WHERE on the 5 identification columns of the current IMPR_PRTL_NAT row) and the
    -- POST-QUERY lookup CGFK$QRY_IMPORTERS_IMP_ITIDT_F are the region SQL of IG IMPORTERS on page 1116
    -- (outer joins on IMPR_TYPE_ID_TYPES / IMPR_TYPES / BUS_ID_TYPES; no N+1 lookups). Block Insert / Update /
    -- Delete Allowed = false -> IG not editable.

    -- =========================================================================
    -- PROGRAM UNITS                                (Forms: Program Units node, same names)
    -- =========================================================================
    -- None kept. CGFK$QRY_IMPORTERS_IMP_ITIDT_F -> region SQL join; CGDV$POPULATE_DYNAMIC_LISTS -> shared LOVs
    -- LOV_APX.REFERENCE_CODES (domains ID_TYPE_GZT, PRTL_NAT_FLAG); the other 18 are the frame
    -- (logic extraction §1).

END IMPR1116;
/
SHOW ERRORS

-- -----------------------------------------------------------------------------
-- Synonym and grants (run as a user allowed to create public synonyms / grant on LIB_APX_USR)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PUBLIC SYNONYM IMPR1116 FOR LIB_APX_USR.IMPR1116;

GRANT EXECUTE ON LIB_APX_USR.IMPR1116 TO LIB_USR;

GRANT EXECUTE ON LIB_APX_USR.IMPR1116 TO SECURITY_DEFAULT;

GRANT EXECUTE ON LIB_APX_USR.IMPR1116 TO SECURITY_PROD;

-- CUSTOMS = parsing schema of the APEX application (APEX needs a direct grant, not a role)
GRANT EXECUTE ON LIB_APX_USR.IMPR1116 TO CUSTOMS;
