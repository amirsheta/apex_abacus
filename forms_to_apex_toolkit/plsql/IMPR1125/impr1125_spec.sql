-- =============================================================================
-- Package     : IMPR1125             (upper-case form name, no prefix - f345 standard)
-- Source form : IMPR1125.fmb (module IMPR1125_CENTRAL, Oracle Forms 12c) - "صيانة توقيفات المستوردين"
--               (central importer suspensions by unified importer number HQ_IMPR_NBR)
-- Target      : Oracle APEX 21.2 / Oracle Database 12.1.0.2, reference application f345
--               main page 1125 (IMPR1125), search page 112501 (IMPR1125_SEARCH),
--               deleted-suspensions dialog 112502 (IMPR1125_DELETED_SUSPENSIONS)
-- Author      : Claude Code
-- Created     : 2026-11-24
-- Version     : 001
-- Purpose     : Business logic of the form, organised like the form itself:
--               VERSION -> f345 HELPERS -> FORM LEVEL -> BLOCK HQ_IMPRS (master, search header, never
--               written) -> BLOCK IMPR_CNTRL_SUSPNS (detail, Interactive Grid) -> PROGRAM UNITS
--               (docs/f345_reference_standard.md §10). No UI state, no session-state reads.
-- Parameters  : no I_ / IO_ / O_ prefix (the mode is in IN / IN OUT / OUT). A parameter carrying the
--               page item P<page>_<ITEM> is named P_<ITEM> (P_HQ_IMPR_NBR => :P1125_HQ_IMPR_NBR,
--               P_PAGE_PK => :P0_PAGE_PK); IG columns keep the column name (SUSPN_SEQ => :SUSPN_SEQ).
--               Inside SQL a parameter is qualified with its member name. Internal members keep p_<name>.
--               f345 application items P_CURR_PORT_CD => :P_CURR_PORT_CD, SSO_APP_USER => :SSO_APP_USER,
--               P_GLOBAL_V_WS_ID => :P_GLOBAL_V_WS_ID. Rule: scripts/parameter_names.py.
--               Common helpers (CHECK_ERROR, REQUIRED_VALIDATION, GET_MODULE_ID, HEADER_TITLE, the Hijri date
--               helpers ...) are in FORMS_APX (version 004) and called as FORMS_APX.<NAME>.
--               Hijri dates are passed as text in the format FORMS_APX.HIJRI_DATE_FORMAT, as in IMPR1120.
-- Names       : IMPR_CNTRL_SUSPNS column members drop the block prefix, because
--               IMPR_CNTRL_SUSPNS_SUSPN_<COLUMN>_<SUFFIX> is longer than 30 bytes (CLAUDE.md §4);
--               the full name is in each member's comment.
-- Rules       : every identifier <= 30 bytes (DB 12.1.0.2); no qualified expressions (18c);
--               no COMMIT / ROLLBACK (APEX commits after page processing).
-- Owner       : LIB_APX_USR; public synonym IMPR1125 + EXECUTE grants at the end of this file.
-- Status      : NOT COMPILED. Depends on DB packages whose source is missing: GNRL, SMS_MESSAGE,
--               LIB_APX_USR.APEX_NOTIFICATIONS (calls copied from the Forms code).
-- History     : 2026-11-24 Claude Code 001 Initial migration (step 02)
-- =============================================================================
SET DEFINE OFF

CREATE OR REPLACE PACKAGE LIB_APX_USR.IMPR1125 AS
   V_PKG_VERSION       VARCHAR2 (100) := 'VERSION NO. IS:' || '001';
   V_PKG_VERSION_QC    VARCHAR2 (100) := 'VERSION NO. IS:' || '001';
   V_PKG_VERSION_DEV   VARCHAR2 (100) := 'VERSION NO. IS:' || '001';
   FUNCTION PKG_VERSION
      RETURN VARCHAR2;
   V_PACKAGE_NAME      VARCHAR2 (50) := 'IMPR1125';
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
    -- f345 HELPERS  (the common ones are in FORMS_APX; this form keeps its own key check)
    -- =========================================================================

    -- APEX  : Process "P0_PAGE_PK CHECK" (Before Header). P0_PAGE_PK holds the ROWID of the HQ_IMPRS
    --         row (as IMPR1120 holds the IMPORTERS ROWID); a key that is not a unified importer is dropped.
    --         The search page 112501 passes the ROWID URL-safe; FORMS_APX.ROWID_FROM_URL translates it back.
    PROCEDURE P0_PAGE_PK_CHECK (P_PAGE_PK IN OUT VARCHAR2);

    -- =========================================================================
    -- FORM LEVEL                                   (Forms: form-level triggers)
    -- =========================================================================
    -- Source: IMPR1125.WHEN-NEW-FORM-INSTANCE: only frame code (NIB, CGBS2$) and the globals
    --         HQ_IMPR_NBR / BUS_NBR := NULL, CURRENT_VER := 2. No business rule -> no member.
    --         Forms parameter CURRENT_SIDE is declared but read nowhere -> not migrated.

    -- =========================================================================
    -- BLOCK HQ_IMPRS  (master, single record, search header; ON-INSERT / ON-UPDATE / ON-DELETE = NULL)
    -- =========================================================================
    -- Source: HQ_IMPRS.POST-QUERY (first and second block: lookups from BUS_ID_TYPES, SINGLE_IMPORTERS,
    --         COUNTRIES, CITIES, IMPR_TYPES)
    -- APEX  : Process "POST-QUERY" (Before Header, after "Initialize form HQ_IMPRS", when P0_PAGE_PK is not null)
    PROCEDURE HQ_IMPRS_POST_QUERY (P_HQ_IMPR_NBR      IN     NUMBER,
                                   P_BUS_ID_TYPE_CD   IN     NUMBER,
                                   P_BUS_ID_TYPE_NAME    OUT VARCHAR2,
                                   P_ARBC_IMPR_NAME      OUT VARCHAR2,
                                   P_ENG_IMPR_NAME       OUT VARCHAR2,
                                   P_CTRY_CD             OUT VARCHAR2,
                                   P_IMPR_TYPE_CD        OUT VARCHAR2,
                                   P_IMPR_EXPR_TYPE      OUT VARCHAR2,
                                   P_CITY_CODE_OF_ID     OUT VARCHAR2,
                                   P_CRTY_ARBC_NAME      OUT VARCHAR2,
                                   P_CITY_CODE_OF_NAME   OUT VARCHAR2,
                                   P_IMPR_TYPE_NAME      OUT VARCHAR2);

    -- Source: HQ_IMPRS.POST-QUERY (third block: count of released suspensions -> CONFIRM -> DELETE_SUSPS_LOV)
    -- APEX  : Server-side condition of the page-load DA "HQ_IMPRS POST-QUERY" (PL/SQL Expression
    --           IMPR1125.RELEASED_SUSPENSIONS_EXIST(P_HQ_IMPR_NBR => :P1125_HQ_IMPR_NBR)):
    --         native Confirm with the Forms text -> open dialog page 112502
    FUNCTION  RELEASED_SUSPENSIONS_EXIST (P_HQ_IMPR_NBR IN NUMBER) RETURN BOOLEAN;

    -- Source: HQ_IMPRS.BUS_ID.WHEN-VALIDATE-ITEM (business id must exist in HQ_IMPRS)
    -- APEX  : Validation "BUS_ID VALIDATION" (request EXECUTE_QUERY) + DA "BUS_ID WHEN-VALIDATE-ITEM" (FOS)
    FUNCTION  BUS_ID_VALIDATION (P_BUS_ID IN VARCHAR2) RETURN VARCHAR2;

    -- Source: HQ_IMPRS.BUS_ID.WHEN-VALIDATE-ITEM (existing business id -> :GLOBAL.BUS_NBR -> query)
    -- APEX  : Process "BUS_ID EXECUTE-QUERY" (After Submit, request EXECUTE_QUERY, when P1125_BUS_ID
    --         is not null and P1125_HQ_IMPR_NBR is null): sets P0_PAGE_PK
    PROCEDURE BUS_ID_WHEN_VALIDATE_ITEM (P_BUS_ID  IN     VARCHAR2,
                                         P_PAGE_PK IN OUT VARCHAR2);

    -- Source: HQ_IMPRS.HQ_IMPR_NBR.WHEN-VALIDATE-ITEM (unified number must exist in HQ_IMPRS)
    -- APEX  : Validation "HQ_IMPR_NBR VALIDATION" (request EXECUTE_QUERY) + DA "HQ_IMPR_NBR WHEN-VALIDATE-ITEM"
    FUNCTION  HQ_IMPR_NBR_VALIDATION (P_HQ_IMPR_NBR IN NUMBER) RETURN VARCHAR2;

    -- Source: HQ_IMPRS.HQ_IMPR_NBR.WHEN-VALIDATE-ITEM (existing number -> :GLOBAL.HQ_IMPR_NBR -> query)
    -- APEX  : Process "HQ_IMPR_NBR EXECUTE-QUERY" (After Submit, request EXECUTE_QUERY): sets P0_PAGE_PK
    PROCEDURE HQ_IMPR_NBR_WHEN_VALIDATE_ITEM (P_HQ_IMPR_NBR IN     NUMBER,
                                              P_PAGE_PK     IN OUT VARCHAR2);

    -- Source: block HQ_IMPRS property Delete Allowed = false (+ ON-DELETE = NULL)
    -- APEX  : Process "PRE-DELETE" (After Submit, request DELETE of the page 0 toolbar)
    PROCEDURE PRE_DELETE;

    -- =========================================================================
    -- BLOCK IMPR_CNTRL_SUSPNS  (detail, Interactive Grid, master key HQ_IMPR_NBR)
    -- =========================================================================
    -- Source: IMPR_CNTRL_SUSPNS.SUSPN_STRT_DT.WHEN-VALIDATE-ITEM (valid Hijri date)
    --         full name IMPR_CNTRL_SUSPNS_SUSPN_STRT_DT_VALIDATION (> 30 bytes)
    -- APEX  : Validation "IMPR_CNTRL_SUSPNS SUSPN_STRT_DT VALIDATION" (IG column) +
    --         DA "IMPR_CNTRL_SUSPNS SUSPN_STRT_DT WHEN-VALIDATE-ITEM" (FOS)
    FUNCTION  SUSPN_STRT_DT_VALIDATION (SUSPN_STRT_DT IN VARCHAR2,
                                        HQ_IMPR_NBR   IN NUMBER,
                                        SUSPN_SEQ     IN NUMBER) RETURN VARCHAR2;

    -- Source: IMPR_CNTRL_SUSPNS.SUSPN_END_DT.WHEN-VALIDATE-ITEM (valid Hijri date, not before the start)
    --         full name IMPR_CNTRL_SUSPNS_SUSPN_END_DT_VALIDATION (> 30 bytes)
    -- APEX  : Validation "IMPR_CNTRL_SUSPNS SUSPN_END_DT VALIDATION" +
    --         DA "IMPR_CNTRL_SUSPNS SUSPN_END_DT WHEN-VALIDATE-ITEM" (FOS)
    FUNCTION  SUSPN_END_DT_VALIDATION (SUSPN_STRT_DT IN VARCHAR2,
                                       SUSPN_END_DT  IN VARCHAR2,
                                       HQ_IMPR_NBR   IN NUMBER,
                                       SUSPN_SEQ     IN NUMBER) RETURN VARCHAR2;

    -- Source: IMPR_CNTRL_SUSPNS.PRE-INSERT (SUSPN_SEQ = MAX + 1, activity log 9-7-1)
    -- APEX  : called by IMPR_CNTRL_SUSPNS_SAVE_ROW (row status C), right before the INSERT
    PROCEDURE IMPR_CNTRL_SUSPNS_PRE_INSERT (SUSPN_SEQ        IN OUT NUMBER,
                                            HQ_IMPR_NBR      IN     NUMBER,
                                            P_CURR_PORT_CD   IN     NUMBER,
                                            SSO_APP_USER     IN     VARCHAR2,
                                            P_GLOBAL_V_WS_ID IN     VARCHAR2);

    -- Source: IMPR_CNTRL_SUSPNS.POST-INSERT (SMS / notification to the importer, CR-8414)
    -- APEX  : called by IMPR_CNTRL_SUSPNS_SAVE_ROW (row status C), right after the INSERT
    PROCEDURE IMPR_CNTRL_SUSPNS_POST_INSERT (HQ_IMPR_NBR    IN NUMBER,
                                             SUSPN_SEQ      IN NUMBER,
                                             SUSPN_STRT_DT  IN VARCHAR2,
                                             SUSPN_END_DT   IN VARCHAR2,
                                             SUSPN_RSN_TEXT IN VARCHAR2,
                                             SUSPN_SIDE_CD  IN NUMBER,
                                             P_BUS_ID       IN VARCHAR2,
                                             P_CURR_PORT_CD IN NUMBER);

    -- Source: IMPR_CNTRL_SUSPNS.PRE-UPDATE (activity log 9-7-2)
    -- APEX  : called by IMPR_CNTRL_SUSPNS_SAVE_ROW (row status U), right before the UPDATE
    PROCEDURE IMPR_CNTRL_SUSPNS_PRE_UPDATE (HQ_IMPR_NBR      IN NUMBER,
                                            SUSPN_SEQ        IN NUMBER,
                                            P_CURR_PORT_CD   IN NUMBER,
                                            SSO_APP_USER     IN VARCHAR2,
                                            P_GLOBAL_V_WS_ID IN VARCHAR2);

    -- Source: IMPR_CNTRL_SUSPNS.ON-DELETE (soft delete: SUSPN_RLSE_DT := today, activity log 9-7-3)
    -- APEX  : called by IMPR_CNTRL_SUSPNS_SAVE_ROW (row status D)
    PROCEDURE IMPR_CNTRL_SUSPNS_ON_DELETE (HQ_IMPR_NBR      IN NUMBER,
                                           SUSPN_SEQ        IN NUMBER,
                                           P_CURR_PORT_CD   IN NUMBER,
                                           SSO_APP_USER     IN VARCHAR2,
                                           P_GLOBAL_V_WS_ID IN VARCHAR2);

    -- Source: Forms transaction processing of block IMPR_CNTRL_SUSPNS, one row at a time:
    --         C: PRE-INSERT -> INSERT -> POST-INSERT;  U: PRE-UPDATE -> UPDATE;  D: ON-DELETE.
    -- APEX  : Process "IMPR_CNTRL_SUSPNS - Save Interactive Grid Data" (Interactive Grid - Automatic Row
    --         Processing (DML), Target Type = PL/SQL Code, Editable Region = IMPR_CNTRL_SUSPNS):
    --           IMPR1125.IMPR_CNTRL_SUSPNS_SAVE_ROW(APEX$ROW_STATUS => :APEX$ROW_STATUS, ...);
    PROCEDURE IMPR_CNTRL_SUSPNS_SAVE_ROW (APEX$ROW_STATUS  IN     VARCHAR2,
                                          HQ_IMPR_NBR      IN     NUMBER,
                                          SUSPN_SEQ        IN OUT NUMBER,
                                          SUSPN_STRT_DT    IN     VARCHAR2,
                                          SUSPN_END_DT     IN     VARCHAR2,
                                          SUSPN_RSN_CD     IN     NUMBER,
                                          SUSPN_RSN_TEXT   IN     VARCHAR2,
                                          SUSPN_SIDE_CD    IN     NUMBER,
                                          P_BUS_ID         IN     VARCHAR2,
                                          P_CURR_PORT_CD   IN     NUMBER,
                                          SSO_APP_USER     IN     VARCHAR2,
                                          P_GLOBAL_V_WS_ID IN     VARCHAR2);

    -- =========================================================================
    -- PROGRAM UNITS                                (Forms: Program Units node, same names)
    -- =========================================================================
    -- SINGLE_IMP_LOV  (CALL_FORM LOV_IMPORT_HQ_NBR)   -> search page 112501 (no member)
    -- DELETE_SUSPS_LOV (CALL_FORM LOV_DELETE_IMP_SUSP) -> dialog page 112502 (no member)
    -- CGUV$CHK_HI_PK / CGFK$CHK_IMPR_CNTRL_SUSPNS_ICS: not called by active code; the same checks are in
    --   HQ_IMPR_NBR_VALIDATION and the foreign key ICS_HI_FK. Other PUs: frame (NIB / Designer), dropped.

END IMPR1125;
/
SHOW ERRORS

-- -----------------------------------------------------------------------------
-- Synonym and grants (run as a user allowed to create public synonyms / grant on LIB_APX_USR)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PUBLIC SYNONYM IMPR1125 FOR LIB_APX_USR.IMPR1125;

GRANT EXECUTE ON LIB_APX_USR.IMPR1125 TO LIB_USR;

GRANT EXECUTE ON LIB_APX_USR.IMPR1125 TO SECURITY_DEFAULT;

GRANT EXECUTE ON LIB_APX_USR.IMPR1125 TO SECURITY_PROD;

-- CUSTOMS = parsing schema of the APEX application (APEX needs a direct grant, not a role)
GRANT EXECUTE ON LIB_APX_USR.IMPR1125 TO CUSTOMS;
