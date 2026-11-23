-- =============================================================================
-- Package     : IMPR1120             (upper-case form name, no prefix - f345 standard)
-- Source form : IMPR1120.fmb (Oracle Forms 12c) - "صيانة توقيفات المستوردين"
--               (Importer Suspension Maintenance, Designer function IMPR40000)
-- Target      : Oracle APEX 21.2 / Oracle Database 12.1.0.2, reference application f345
--               main page 1120 (IMPR1120), search page 112001 (IMPR1120_SEARCH)
-- Author      : Claude Code
-- Created     : 2026-11-23
-- Version     : 006
-- Purpose     : Business logic of the form, organised like the form itself:
--               VERSION -> f345 HELPERS -> FORM LEVEL -> BLOCK IMPORTERS (master, query only)
--               -> BLOCK IMPR_SUSPN (detail, Interactive Grid) -> PROGRAM UNITS
--               (docs/f345_reference_standard.md §10). No UI state, no session-state reads:
--               UI rules are BOOLEAN functions that APEX conditions call (§9).
-- Parameters  : no I_ / IO_ / O_ prefix (the mode is in IN / IN OUT / OUT). A parameter carrying the
--               page item P<page>_<ITEM> is named P_<ITEM> (P_PORT_CD => :P1120_PORT_CD,
--               P_PAGE_PK => :P0_PAGE_PK, P_CURRENT_SIDE => :P1120_P_CURRENT_SIDE); IG columns keep the
--               column name (PORT_CD => :PORT_CD); CHECK_ERROR(ERROR_TEXT), REQUIRED_VALIDATION(ITEM_VALUE,
--               ITEM_LABEL). Inside SQL a parameter is qualified with its member name
--               (IMPR_SUSPN_ON_DELETE.PORT_CD), because an unqualified name that matches a column
--               resolves to the column. Internal members keep p_<name>. Rule: scripts/parameter_names.py.
--               f345 application items P_CURR_PORT_CD => :P_CURR_PORT_CD,
--               SSO_APP_USER => :SSO_APP_USER, P_GLOBAL_V_WS_ID => :P_GLOBAL_V_WS_ID.
--               Forms parameter CURRENT_SIDE -> page item P1120_P_CURRENT_SIDE.
--               Hijri dates are passed as text in the Forms mask MI-MM-RRRR (OLB class CGSO$HDATE_ARB;
--               the day is kept in the minutes because e.g. 30-02 is not a valid DATE), as in IMPR1110.
--               The package never reads page items itself, so it is testable without APEX.
-- Names       : IMPR_SUSPN column members drop the block prefix, because
--               IMPR_SUSPN_SUSPN_<COLUMN>_<SUFFIX> is longer than 30 bytes (CLAUDE.md §4);
--               the full name is in each member's comment. The columns exist only in IMPR_SUSPN.
-- Rules       : every identifier <= 30 bytes (DB 12.1.0.2); no qualified expressions (18c);
--               no COMMIT / ROLLBACK (APEX commits after page processing).
-- Owner       : LIB_APX_USR; public synonym IMPR1120 + EXECUTE grants at the end of this file.
-- Status      : NOT COMPILED. Depends on DB packages whose source is missing: STR_DB, GNRL,
--               SMS_MESSAGE, LIB_APX_USR.APEX_NOTIFICATIONS (calls copied from the Forms code).
-- History     : 2026-11-23 Claude Code 001 Initial migration (step 02)
--               2026-11-23 Claude Code 002 Step 03 page design: dates as MI-MM-RRRR text; column
--                          validations skip unchanged stored values (Forms WHEN-VALIDATE-ITEM fires
--                          only on change); PRE_DELETE (block DeleteAllowed = false);
--                          IMPR_SUSPN_SAVE_ROW (row DML in Forms order, soft delete);
--                          SUSPN_RSN_TEXT_DEFAULT. Previous version: rollback/IMPR1120/step02_v001/
--               2026-11-23 Claude Code 003 Parameter names without I_ / IO_ / O_ (user request);
--                          parameters qualified with the member name inside SQL. No logic change.
--                          Previous version: rollback/IMPR1120/step04_v002/
--               2026-11-23 Claude Code 004 Page-item parameters named P_<ITEM> without the page number
--                          (P1120_PORT_CD -> P_PORT_CD, P0_PAGE_PK -> P_PAGE_PK); rule in
--                          scripts/parameter_names.py. No logic change. Previous: rollback/IMPR1120/step04_v003/
--               2026-11-23 Claude Code 005 No doubled P_P_ (P1120_P_CURRENT_SIDE -> P_CURRENT_SIDE); private
--                          helper to_hijri_date renamed hijri_text_to_date (same logic: text -> DATE, no
--                          calendar conversion). Previous version: rollback/IMPR1120/step04_v004/
--               2026-11-23 Claude Code 006 Compile fix: IMPR_SUSPN_SAVE_ROW called the private function
--                          hijri_text_to_date inside INSERT / UPDATE (ORA-00904 invalid identifier: a private
--                          package function cannot be used in SQL); the texts are now converted into local
--                          DATE variables first. Previous version: rollback/IMPR1120/step04_v005/
-- =============================================================================
SET DEFINE OFF

CREATE OR REPLACE PACKAGE LIB_APX_USR.IMPR1120 AS
   V_PKG_VERSION       VARCHAR2 (100) := 'VERSION NO. IS:' || '006';
   V_PKG_VERSION_QC    VARCHAR2 (100) := 'VERSION NO. IS:' || '006';
   V_PKG_VERSION_DEV   VARCHAR2 (100) := 'VERSION NO. IS:' || '006';
   FUNCTION PKG_VERSION
      RETURN VARCHAR2;
   V_PACKAGE_NAME      VARCHAR2 (50) := 'IMPR1120';
   V_LAST_MODIFY_DT    VARCHAR2 (10) := '23-11-2026';
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
    -- f345 HELPERS                                 (every form package has these)
    -- =========================================================================
    -- Raises the error text; used by dynamic actions: IMPR1120.CHECK_ERROR(IMPR1120.<ITEM>_VALIDATION(...))
    PROCEDURE CHECK_ERROR (ERROR_TEXT IN VARCHAR2);

    -- Error text when a required value is empty, else NULL
    -- APEX  : Validation "<ITEM> REQUIRED": return IMPR1120.REQUIRED_VALIDATION(:<ITEM>, '<label>');
    FUNCTION  REQUIRED_VALIDATION (ITEM_VALUE IN VARCHAR2, ITEM_LABEL IN VARCHAR2) RETURN VARCHAR2;

    -- APEX  : Process "P0_PAGE_PK CHECK" (Before Header). P0_PAGE_PK holds the ROWID of the
    --         IMPORTERS row (as IMPR1110); a key that is not an importer of this port is dropped.
    PROCEDURE P0_PAGE_PK_CHECK (P_PAGE_PK    IN OUT VARCHAR2,
                                P_CURR_PORT_CD IN     NUMBER);

    -- APEX  : Process "PARAMETERS": :P1120_MODULE_ID := IMPR1120.GET_MODULE_ID(:P1120_MODULE_ID);
    FUNCTION  GET_MODULE_ID (P_MODULE_ID IN VARCHAR2) RETURN VARCHAR2;

    -- APEX  : Process "HEADER TITLE" (Before Header) - title of the hero region
    PROCEDURE HEADER_TITLE (P_MODULE_ID   IN     VARCHAR2,
                            P_HERO_TITLE IN OUT VARCHAR2);

    -- =========================================================================
    -- FORM LEVEL                                   (Forms: form-level triggers)
    -- =========================================================================
    -- Source: Forms parameter CURRENT_SIDE (no default). The launchers APPS / BUTTON_LAST_TREE and
    --         PU EXECUTE_FUNCTION add the module's parameters from SC_PORT_SETTING (cursor
    --         c_modudle_parameter: VAR_NAME / VAR_VALUE by PORT_CD and SYSOBJ_ID).
    -- APEX  : Process "PARAMETERS CURRENT_SIDE" (Before Header), when P1120_P_CURRENT_SIDE is null:
    --           :P1120_P_CURRENT_SIDE := IMPR1120.GET_CURRENT_SIDE(P_MODULE_ID => :P1120_MODULE_ID,
    --                                                              P_CURR_PORT_CD  => :P_CURR_PORT_CD);
    -- TODO  : confirm the source with the data owner (inventory §15 #1).
    FUNCTION  GET_CURRENT_SIDE (P_MODULE_ID IN VARCHAR2,
                                P_CURR_PORT_CD  IN NUMBER) RETURN NUMBER;

    -- Source: IMPR1120.WHEN-NEW-FORM-INSTANCE (site check; EXIT_FORM -> error)
    -- APEX  : Process "WHEN-NEW-FORM-INSTANCE" (Before Header)
    PROCEDURE INIT_FORM (P_CURRENT_SIDE IN NUMBER,
                         P_CURR_PORT_CD       IN NUMBER);

    -- =========================================================================
    -- BLOCK IMPORTERS  (master, single record, query only)
    -- =========================================================================
    -- Source: IMPORTERS.PRE-QUERY - port criterion (forced to the user's port outside port 99)
    -- APEX  : search page 112001, region SQL:
    --           WHERE i.port_cd = NVL(IMPR1120.IMPORTERS_PRE_QUERY_PORT_CD(PORT_CD => :P112001_PORT_CD,
    --                                 P_CURR_PORT_CD => :P_CURR_PORT_CD), i.port_cd)
    --         (NULL = all ports, only possible for port 99)
    FUNCTION  IMPORTERS_PRE_QUERY_PORT_CD (PORT_CD        IN NUMBER,
                                           P_CURR_PORT_CD IN NUMBER) RETURN NUMBER;

    -- Source: IMPORTERS.PRE-QUERY - Arabic name criterion searched in IMPR_NAME_STD
    -- APEX  : search page 112001, region SQL:
    --           AND (:P112001_ARBC_IMPR_NAME IS NULL
    --                OR i.impr_name_std LIKE IMPR1120.IMPORTERS_PRE_QUERY_NAME_STD(:P112001_ARBC_IMPR_NAME))
    FUNCTION  IMPORTERS_PRE_QUERY_NAME_STD (ARBC_IMPR_NAME IN VARCHAR2) RETURN VARCHAR2;

    -- Source: IMPORTERS.POST-QUERY (Designer lookups CGFK$QRY_*)
    -- APEX  : Process "POST-QUERY" (Before Header, after "Initialize form", when P0_PAGE_PK is not null)
    PROCEDURE IMPORTERS_POST_QUERY (P_PORT_CD          IN     NUMBER,
                                    P_IMPR_TYPE_CD     IN     NUMBER,
                                    P_BUS_ID_TYPE_CD   IN     NUMBER,
                                    P_CTRY_CD          IN     NUMBER,
                                    P_CTRY_CD_OF_ID    IN     NUMBER,
                                    P_CITY_CODE_OF_ID  IN     NUMBER,
                                    P_PORT_NAME           OUT VARCHAR2,
                                    P_IMPR_TYPE_NAME      OUT VARCHAR2,
                                    P_BUS_ID_TYPE_NAME    OUT VARCHAR2,
                                    P_CRTY_ARBC_NAME      OUT VARCHAR2,
                                    P_ID_CITY_NAME        OUT VARCHAR2);

    -- Source: IMPORTERS.WHEN-CREATE-RECORD (+ the port part of WHEN-NEW-FORM-INSTANCE)
    -- APEX  : Process "IMPORTERS WHEN-CREATE-RECORD" (Before Header, when P0_PAGE_PK is null)
    PROCEDURE IMPORTERS_WHEN_CREATE_RECORD (P_CURR_PORT_CD IN     NUMBER,
                                            P_PORT_CD     OUT NUMBER,
                                            P_PORT_NAME   OUT VARCHAR2);

    -- Source: IMPR1120.WHEN-NEW-FORM-INSTANCE (PORT_CD insert / update allowed only for port 99)
    -- APEX  : Read Only of P1120_PORT_CD and P112001_PORT_CD = PL/SQL Expression
    --           IMPR1120.PORT_CD_IS_READ_ONLY(P_CURR_PORT_CD => :P_CURR_PORT_CD)
    FUNCTION  PORT_CD_IS_READ_ONLY (P_CURR_PORT_CD IN NUMBER) RETURN BOOLEAN;

    -- Source: IMPORTERS.IMPR_NBR.WHEN-VALIDATE-ITEM (importer must exist in the port: message 9-150)
    -- APEX  : Validation "IMPR_NBR VALIDATION" (request EXECUTE_QUERY / CREATE) + DA
    --         "IMPR_NBR WHEN-VALIDATE-ITEM" (FOS CHECK_ERROR)
    FUNCTION  IMPR_NBR_VALIDATION (P_PORT_CD  IN NUMBER,
                                   P_IMPR_NBR IN NUMBER) RETURN VARCHAR2;

    -- Source: IMPORTERS.IMPR_NBR.WHEN-VALIDATE-ITEM (existing importer -> :GLOBAL.Exec_Query_Now -> query)
    -- APEX  : Process "EXECUTE-QUERY" (After Submit, request EXECUTE_QUERY or CREATE): sets P0_PAGE_PK
    PROCEDURE IMPR_NBR_WHEN_VALIDATE_ITEM (P_PORT_CD  IN     NUMBER,
                                           P_IMPR_NBR IN     NUMBER,
                                           P_PAGE_PK    IN OUT VARCHAR2);

    -- Source: block IMPORTERS property Delete Allowed = false (Forms FRM-41049)
    -- APEX  : Process "PRE-DELETE" (After Submit, request DELETE of the page 0 toolbar)
    PROCEDURE PRE_DELETE;

    -- =========================================================================
    -- BLOCK IMPR_SUSPN  (detail, Interactive Grid, master key PORT_CD + IMPR_NBR)
    -- =========================================================================
    -- Source: IMPR_SUSPN.WHEN-NEW-RECORD-INSTANCE (NEXT_RECORD skips rows of another site)
    -- APEX  : Read Only of every IG column, Execute "For Each Row", PL/SQL Expression
    --           IMPR1120.IMPR_SUSPN_IS_READ_ONLY(SUSPN_SIDE_CD => :SUSPN_SIDE_CD,
    --                                            P_CURRENT_SIDE => :P1120_P_CURRENT_SIDE,
    --                                            P_CURR_PORT_CD => :P_CURR_PORT_CD)
    FUNCTION  IMPR_SUSPN_IS_READ_ONLY (SUSPN_SIDE_CD        IN NUMBER,
                                       P_CURRENT_SIDE IN NUMBER,
                                       P_CURR_PORT_CD       IN NUMBER) RETURN BOOLEAN;

    -- Source: IMPR_SUSPN.SUSPN_STRT_DT.WHEN-NEW-ITEM-INSTANCE (empty start date := today, Hijri)
    --         full name IMPR_SUSPN_SUSPN_STRT_DT_WHEN_NEW_ITEM_INSTANCE (> 30 bytes)
    -- APEX  : IG column SUSPN_STRT_DT Default = PL/SQL Expression IMPR1120.SUSPN_STRT_DT_DEFAULT
    FUNCTION  SUSPN_STRT_DT_DEFAULT RETURN VARCHAR2;

    -- Source: IMPR_SUSPN.SUSPN_STRT_DT.WHEN-VALIDATE-ITEM (valid Hijri date, not before today: 9-100)
    --         full name IMPR_SUSPN_SUSPN_STRT_DT_VALIDATION
    -- APEX  : Validation "IMPR_SUSPN SUSPN_STRT_DT VALIDATION" (IG column) +
    --         DA "IMPR_SUSPN SUSPN_STRT_DT WHEN-VALIDATE-ITEM" (FOS)
    FUNCTION  SUSPN_STRT_DT_VALIDATION (SUSPN_STRT_DT IN VARCHAR2,
                                        PORT_CD       IN NUMBER,
                                        IMPR_NBR      IN NUMBER,
                                        SUSPN_SEQ     IN NUMBER) RETURN VARCHAR2;

    -- Source: IMPR_SUSPN.SUSPN_END_DT.WHEN-VALIDATE-ITEM (valid Hijri date, not before start: 9-110)
    --         full name IMPR_SUSPN_SUSPN_END_DT_VALIDATION
    -- APEX  : Validation "IMPR_SUSPN SUSPN_END_DT VALIDATION" + DA "IMPR_SUSPN SUSPN_END_DT WHEN-VALIDATE-ITEM"
    FUNCTION  SUSPN_END_DT_VALIDATION (SUSPN_STRT_DT IN VARCHAR2,
                                       SUSPN_END_DT  IN VARCHAR2,
                                       PORT_CD       IN NUMBER,
                                       IMPR_NBR      IN NUMBER,
                                       SUSPN_SEQ     IN NUMBER) RETURN VARCHAR2;

    -- Source: IMPR_SUSPN.SUSPN_RSN_CD.WHEN-NEW-ITEM-INSTANCE (default reason of the site)
    --         full name IMPR_SUSPN_SUSPN_RSN_CD_WHEN_NEW_ITEM_INSTANCE (> 30 bytes)
    -- APEX  : IG column SUSPN_RSN_CD Default = PL/SQL Expression
    --           IMPR1120.SUSPN_RSN_CD_DEFAULT(:P1120_P_CURRENT_SIDE, :P_CURR_PORT_CD)
    FUNCTION  SUSPN_RSN_CD_DEFAULT (P_CURRENT_SIDE IN NUMBER,
                                    P_CURR_PORT_CD       IN NUMBER) RETURN NUMBER;

    -- Source: IMPR_SUSPN.SUSPN_RSN_CD.WHEN-VALIDATE-ITEM (reason required and allowed for the site)
    --         full name IMPR_SUSPN_SUSPN_RSN_CD_VALIDATION
    -- APEX  : Validation "IMPR_SUSPN SUSPN_RSN_CD VALIDATION"
    FUNCTION  SUSPN_RSN_CD_VALIDATION (SUSPN_RSN_CD         IN NUMBER,
                                       P_CURRENT_SIDE IN NUMBER,
                                       PORT_CD              IN NUMBER,
                                       IMPR_NBR             IN NUMBER,
                                       SUSPN_SEQ            IN NUMBER) RETURN VARCHAR2;

    -- Source: IMPR_SUSPN.SUSPN_RSN_CD.WHEN-VALIDATE-ITEM (SUSPN_RSN_TEXT := CG_REF_CODES meaning)
    --         full name IMPR_SUSPN_SUSPN_RSN_CD_WHEN_VALIDATE_ITEM (> 30 bytes, WHEN_ dropped)
    -- APEX  : DA "IMPR_SUSPN SUSPN_RSN_CD WHEN-VALIDATE-ITEM" (column change, FOS,
    --         Items to Submit SUSPN_RSN_CD, PORT_CD, IMPR_NBR, SUSPN_SEQ, P1120_P_CURRENT_SIDE;
    --         Items to Return SUSPN_RSN_TEXT)
    PROCEDURE SUSPN_RSN_CD_VALIDATE_ITEM (SUSPN_RSN_CD         IN     NUMBER,
                                          P_CURRENT_SIDE IN     NUMBER,
                                          PORT_CD              IN     NUMBER,
                                          IMPR_NBR             IN     NUMBER,
                                          SUSPN_SEQ            IN     NUMBER,
                                          SUSPN_RSN_TEXT      IN OUT VARCHAR2);

    -- Source: IMPR_SUSPN.SUSPN_RSN_CD.WHEN-NEW-ITEM-INSTANCE + WHEN-VALIDATE-ITEM: in Forms the default
    --         reason is set on entering the item and its meaning is copied to SUSPN_RSN_TEXT when the
    --         cursor leaves it. A grid column default fires no change event, so the text is defaulted too.
    --         full name IMPR_SUSPN_SUSPN_RSN_TEXT_DEFAULT
    -- APEX  : IG column SUSPN_RSN_TEXT Default = PL/SQL Expression
    --           IMPR1120.SUSPN_RSN_TEXT_DEFAULT(:P1120_P_CURRENT_SIDE, :P_CURR_PORT_CD)
    FUNCTION  SUSPN_RSN_TEXT_DEFAULT (P_CURRENT_SIDE IN NUMBER,
                                      P_CURR_PORT_CD       IN NUMBER) RETURN VARCHAR2;

    -- Source: IMPR_SUSPN.SUSPN_SIDE_CD.WHEN-NEW-ITEM-INSTANCE (default side of the site)
    --         full name IMPR_SUSPN_SUSPN_SIDE_CD_WHEN_NEW_ITEM_INSTANCE (> 30 bytes)
    -- APEX  : IG column SUSPN_SIDE_CD Default = PL/SQL Expression
    --           IMPR1120.SUSPN_SIDE_CD_DEFAULT(:P1120_P_CURRENT_SIDE, :P_CURR_PORT_CD)
    FUNCTION  SUSPN_SIDE_CD_DEFAULT (P_CURRENT_SIDE IN NUMBER,
                                     P_CURR_PORT_CD       IN NUMBER) RETURN NUMBER;

    -- Source: IMPR_SUSPN.SUSPN_SIDE_CD.WHEN-LIST-CHANGED + WHEN-VALIDATE-ITEM (side required and
    --         allowed for the site)   full name IMPR_SUSPN_SUSPN_SIDE_CD_VALIDATION
    -- APEX  : Validation "IMPR_SUSPN SUSPN_SIDE_CD VALIDATION" +
    --         DA "IMPR_SUSPN SUSPN_SIDE_CD WHEN-LIST-CHANGED" (FOS CHECK_ERROR)
    FUNCTION  SUSPN_SIDE_CD_VALIDATION (SUSPN_SIDE_CD        IN NUMBER,
                                        P_CURRENT_SIDE IN NUMBER,
                                        P_CURR_PORT_CD       IN NUMBER,
                                        PORT_CD              IN NUMBER,
                                        IMPR_NBR             IN NUMBER,
                                        SUSPN_SEQ            IN NUMBER) RETURN VARCHAR2;

    -- Source: IMPR_SUSPN.POST-QUERY / POST-INSERT / WHEN-NEW-RECORD-INSTANCE
    --         (SET_ITEM_PROPERTY SUSPN_SIDE_CD ENABLED FALSE once the row has a stored side)
    --         full name IMPR_SUSPN_SUSPN_SIDE_CD_IS_READ_ONLY
    -- APEX  : Read Only of IG column SUSPN_SIDE_CD, Execute "For Each Row", PL/SQL Expression
    --           IMPR1120.SUSPN_SIDE_CD_IS_READ_ONLY(:PORT_CD, :IMPR_NBR, :SUSPN_SEQ)
    FUNCTION  SUSPN_SIDE_CD_IS_READ_ONLY (PORT_CD   IN NUMBER,
                                          IMPR_NBR  IN NUMBER,
                                          SUSPN_SEQ IN NUMBER) RETURN BOOLEAN;

    -- Source: IMPR_SUSPN.PRE-INSERT (SUSPN_SEQ = MAX + 1, activity log)
    -- APEX  : called by IMPR_SUSPN_SAVE_ROW (row status C), right before the INSERT, as in Forms
    PROCEDURE IMPR_SUSPN_PRE_INSERT (SUSPN_SEQ        IN OUT NUMBER,
                                     PORT_CD           IN     NUMBER,
                                     IMPR_NBR          IN     NUMBER,
                                     P_CURR_PORT_CD    IN     NUMBER,
                                     SSO_APP_USER      IN     VARCHAR2,
                                     P_GLOBAL_V_WS_ID  IN     VARCHAR2);

    -- Source: IMPR_SUSPN.POST-INSERT (SMS / notification to the importer, CR-8414)
    -- APEX  : called by IMPR_SUSPN_SAVE_ROW (row status C), right after the INSERT
    PROCEDURE IMPR_SUSPN_POST_INSERT (PORT_CD           IN NUMBER,
                                      IMPR_NBR          IN NUMBER,
                                      SUSPN_SEQ         IN NUMBER,
                                      SUSPN_STRT_DT     IN VARCHAR2,
                                      SUSPN_END_DT      IN VARCHAR2,
                                      SUSPN_RSN_TEXT    IN VARCHAR2,
                                      P_HQ_IMPR_NBR IN NUMBER,
                                      P_PORT_NAME   IN VARCHAR2,
                                      P_BUS_ID      IN VARCHAR2,
                                      P_CURR_PORT_CD    IN NUMBER);

    -- Source: IMPR_SUSPN.PRE-UPDATE (activity log; release date from the end date)
    -- APEX  : called by IMPR_SUSPN_SAVE_ROW (row status U), right before the UPDATE
    PROCEDURE IMPR_SUSPN_PRE_UPDATE (PORT_CD              IN     NUMBER,
                                     IMPR_NBR             IN     NUMBER,
                                     SUSPN_SEQ            IN     NUMBER,
                                     SUSPN_END_DT         IN     VARCHAR2,
                                     SUSPN_RLSE_DT       IN OUT VARCHAR2,
                                     P_CURRENT_SIDE IN     NUMBER,
                                     P_CURR_PORT_CD       IN     NUMBER,
                                     SSO_APP_USER         IN     VARCHAR2,
                                     P_GLOBAL_V_WS_ID     IN     VARCHAR2);

    -- Source: IMPR_SUSPN.ON-DELETE (soft delete: SUSPN_RLSE_DT := today, activity log)
    -- APEX  : called by IMPR_SUSPN_SAVE_ROW (row status D)
    PROCEDURE IMPR_SUSPN_ON_DELETE (PORT_CD              IN NUMBER,
                                    IMPR_NBR             IN NUMBER,
                                    SUSPN_SEQ            IN NUMBER,
                                    P_CURRENT_SIDE IN NUMBER,
                                    P_CURR_PORT_CD       IN NUMBER,
                                    SSO_APP_USER         IN VARCHAR2,
                                    P_GLOBAL_V_WS_ID     IN VARCHAR2);

    -- Source: Forms transaction processing of block IMPR_SUSPN, one row at a time:
    --         C: PRE-INSERT -> INSERT -> POST-INSERT;  U: PRE-UPDATE -> UPDATE;  D: ON-DELETE.
    --         One member so the per-row order of Forms is kept (MAX + 1 in PRE-INSERT needs the
    --         previous row inserted) and the native IG DML cannot really delete a row.
    -- APEX  : Process "IMPR_SUSPN - Save Interactive Grid Data" (Interactive Grid - Automatic Row
    --         Processing (DML), Target Type = PL/SQL Code, Editable Region = IMPR_SUSPN):
    --           IMPR1120.IMPR_SUSPN_SAVE_ROW(APEX$ROW_STATUS => :APEX$ROW_STATUS, ...);
    PROCEDURE IMPR_SUSPN_SAVE_ROW (APEX$ROW_STATUS      IN     VARCHAR2,
                                   PORT_CD              IN     NUMBER,
                                   IMPR_NBR             IN     NUMBER,
                                   SUSPN_SEQ           IN OUT NUMBER,
                                   SUSPN_STRT_DT        IN     VARCHAR2,
                                   SUSPN_END_DT         IN     VARCHAR2,
                                   SUSPN_RSN_CD         IN     NUMBER,
                                   SUSPN_RSN_TEXT       IN     VARCHAR2,
                                   SUSPN_SIDE_CD        IN     NUMBER,
                                   P_HQ_IMPR_NBR    IN     NUMBER,
                                   P_PORT_NAME      IN     VARCHAR2,
                                   P_BUS_ID         IN     VARCHAR2,
                                   P_CURRENT_SIDE IN     NUMBER,
                                   P_CURR_PORT_CD       IN     NUMBER,
                                   SSO_APP_USER         IN     VARCHAR2,
                                   P_GLOBAL_V_WS_ID     IN     VARCHAR2);

    -- =========================================================================
    -- PROGRAM UNITS                                (Forms: Program Units node, same names)
    -- =========================================================================
    -- Designer FK lookups used by IMPORTERS_POST_QUERY. Raise NO_DATA_FOUND when not found.
    PROCEDURE CGFK$QRY_IMPORTERS_IMP_SDP_FK (p_sdp_port_status IN OUT NUMBER,
                                             p_port_name       IN OUT VARCHAR2,
                                             p_port_cd         IN     NUMBER);

    PROCEDURE CGFK$QRY_IMPORTERS_IMP_ITIDT_F (p_bus_id_type_name IN OUT VARCHAR2,
                                              p_impr_type_name   IN OUT VARCHAR2,
                                              p_status           IN OUT NUMBER,
                                              p_impr_type_cd     IN     NUMBER,
                                              p_bus_id_type_cd   IN     NUMBER);

    PROCEDURE CGFK$QRY_IMPORTERS_IMP_CTRY_FK (p_ctry_ctry_status IN OUT NUMBER,
                                              p_crty_arbc_name   IN OUT VARCHAR2,
                                              p_ctry_cd          IN     NUMBER);

    PROCEDURE CGFK$QRY_IMPORTERS_IMP_BUS_ID_ (p_id_city_name    IN OUT VARCHAR2,
                                              p_ctry_cd_of_id   IN     NUMBER,
                                              p_city_code_of_id IN     NUMBER);

END IMPR1120;
/
SHOW ERRORS

-- -----------------------------------------------------------------------------
-- Synonym and grants (run as a user allowed to create public synonyms / grant on LIB_APX_USR)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PUBLIC SYNONYM IMPR1120 FOR LIB_APX_USR.IMPR1120;

GRANT EXECUTE ON LIB_APX_USR.IMPR1120 TO LIB_USR;

GRANT EXECUTE ON LIB_APX_USR.IMPR1120 TO SECURITY_DEFAULT;

GRANT EXECUTE ON LIB_APX_USR.IMPR1120 TO SECURITY_PROD;

-- CUSTOMS = parsing schema of the APEX application (APEX needs a direct grant, not a role)
GRANT EXECUTE ON LIB_APX_USR.IMPR1120 TO CUSTOMS;
