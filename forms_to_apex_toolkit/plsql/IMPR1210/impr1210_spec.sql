-- =============================================================================
-- Package     : IMPR1210             (upper-case form name, no prefix - f345 standard)
-- Source form : IMPR1210.fmb (Oracle Forms 12c, module IMPR1210) - "صيانة تفاويض الشركات الوسيطة"
--               (authorizations an importer gives to a broker company in the user's port, table AGNTS)
-- Target      : Oracle APEX 21.2 / Oracle Database 12.1.0.2, reference application f345
--               main page 1210 (IMPR1210), search page 121001 (IMPR1210_SEARCH)
-- Author      : Claude Code
-- Created     : 2026-11-25
-- Version     : 001
-- Purpose     : Business logic of the form, organised like the form itself:
--               VERSION -> f345 HELPERS -> BLOCK AGNTS (single record, Form region: query, record, items in
--               navigation order, DML) -> FUNCTIONS (PU EXEC_FUNS) (docs/f345_reference_standard.md §10).
--               No UI state, no session-state reads: UI rules are DAs / APEX conditions (§9).
-- Parameters  : no I_ / IO_ / O_ prefix (the mode is in IN / IN OUT / OUT). A parameter carrying the page
--               item P1210_<ITEM> is named P_<ITEM> (P_IMPR_NBR => :P1210_IMPR_NBR, P_PAGE_PK => :P0_PAGE_PK);
--               f345 application items keep their names (P_CURR_PORT_CD => :P_CURR_PORT_CD, SSO_APP_USER,
--               P_GLOBAL_V_WS_ID). Inside SQL a parameter is qualified with its member name (PRE_INSERT.P_PORT_CD).
--               Internal members keep p_<name>. Common helpers (CHECK_ERROR, ARABIC_MESSAGE, CUR_HIJ_DATE,
--               HIJRI_TEXT, FORM_TRIGGER_FAILURE, ROWID_FROM_URL ...) are in FORMS_APX (version 004).
-- Dates       : Hijri dates are DATE values with the day in the minutes (Forms mask MI-MM-RRRR); the page
--               shows them as text in FORMS_APX.HIJRI_DATE_FORMAT (Application Setting), so the Hijri
--               parameters of this package are VARCHAR2 texts in that format.
-- Rules       : every identifier <= 30 bytes (DB 12.1.0.2); no qualified expressions (18c);
--               no COMMIT / ROLLBACK except in EXEC_FUNS, where the Forms code commits (logic extraction #4).
-- Owner       : LIB_APX_USR; public synonym IMPR1210 + EXECUTE grants at the end of this file.
-- Status      : NOT COMPILED. Depends on DB packages without source in the repository (calls copied
--               unchanged from the Forms code): LIB_USR.IMPR (IMPR_SUSPENDED), DCLTN (IMPR_IMPR_AUTH_USED),
--               STR_DB (GETARBMSG); and on ACTIVITY_DB (plsql/Shared).
-- History     : 2026-11-25 Claude Code 001 Initial migration (step 02)
-- =============================================================================
SET DEFINE OFF

CREATE OR REPLACE PACKAGE LIB_APX_USR.IMPR1210 AS
   V_PKG_VERSION       VARCHAR2 (100) := 'VERSION NO. IS:' || '001';
   V_PKG_VERSION_QC    VARCHAR2 (100) := 'VERSION NO. IS:' || '001';
   V_PKG_VERSION_DEV   VARCHAR2 (100) := 'VERSION NO. IS:' || '001';

   FUNCTION PKG_VERSION
      RETURN VARCHAR2;

   V_PACKAGE_NAME      VARCHAR2 (50) := 'IMPR1210';
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

    -- Function codes of the f345 Page Functions list (SC_SYSTEM_OBJECTS.SYS_OS_FILE_NAME, PU EXEC_FUNS)
    c_stop_authorization    CONSTANT VARCHAR2(30) := 'CD1_STOPIMPRAUTH';
    c_reuse_authorization   CONSTANT VARCHAR2(30) := 'CD2_REUSEIMPRAUTH';

    -- =========================================================================
    -- f345 HELPERS  (the common ones are in FORMS_APX; this form keeps its own key check)
    -- =========================================================================
    -- APEX  : Process "P0_PAGE_PK CHECK" (Before Header). P0_PAGE_PK holds the ROWID of the AGNTS row (as
    --         IMPR1160); a key that is not an authorization of the user's port (block WHERE clause
    --         PORT_CD = :PARAMETER.P_CURR_PORT_CD) is dropped. The search page 121001 passes the ROWID URL-safe
    --         (TRANSLATE(ROWID, '+/', '-_')); FORMS_APX.ROWID_FROM_URL restores it.
    PROCEDURE P0_PAGE_PK_CHECK (P_PAGE_PK      IN OUT VARCHAR2,
                                P_CURR_PORT_CD IN     NUMBER);

    -- =========================================================================
    -- BLOCK AGNTS  (single record; insert; queried record: update when valid and not used; no delete)
    -- =========================================================================
    -- ------------------------------------------------------------------ query
    -- Source: AGNTS.PRE-QUERY (:GLOBAL.PORT_CD / ATHRZTN_SEQ_NBR copied into the key items when
    --         :GLOBAL.EXEC_QUERY_NOW = 1, set by ATHRZTN_SEQ_NBR.WHEN-VALIDATE-ITEM) + IMPR_NBR.WHEN-NEW-ITEM-INSTANCE
    --         (CLEAR_BLOCK + EXECUTE_QUERY)
    -- APEX  : Process "EXECUTE-QUERY" (After Submit, request EXECUTE_QUERY): :P0_PAGE_PK := IMPR1210.PRE_QUERY(...);
    --         returns the ROWID of the authorization of the port with that number (NULL when there is none).
    FUNCTION  PRE_QUERY (P_PORT_CD         IN NUMBER,
                         P_ATHRZTN_SEQ_NBR IN NUMBER) RETURN VARCHAR2;

    -- Source: AGNTS.POST-QUERY (CGFK$QRY_AGNTS_AG_SDP_FK, CGFK$QRY_AGNTS_AG_IMP_FK, CGFK$QRY_AGNTS_AG_IMP_AGENT_ID)
    -- APEX  : Process "POST-QUERY" (Before Header, after "Initialize form", when P1210_ROW_ID is not null)
    PROCEDURE POST_QUERY (P_PORT_CD           IN     NUMBER,
                          P_IMPR_NBR          IN     NUMBER,
                          P_IMPR_NBR_AG       IN     NUMBER,
                          P_PORT_NAME         IN OUT VARCHAR2,
                          P_IMPR_NAME         IN OUT VARCHAR2,
                          P_IMPR_EXPR_TYPE    IN OUT NUMBER,
                          P_IMPR_NAME_AG      IN OUT VARCHAR2,
                          P_IMPR_EXPR_TYPE_AG IN OUT NUMBER);

    -- ------------------------------------------------------------------ record
    -- Source: AGNTS.WHEN-CREATE-RECORD (PORT_CD := :PARAMETER.P_CURR_PORT_CD, its PORT_NAME)
    -- APEX  : Process "WHEN-CREATE-RECORD" (Before Header, after "Initialize form", P1210_ROW_ID null = new record)
    PROCEDURE WHEN_CREATE_RECORD (P_CURR_PORT_CD IN     NUMBER,
                                  P_PORT_CD      IN OUT NUMBER,
                                  P_PORT_NAME    IN OUT VARCHAR2);

    -- Source: AGNTS.WHEN-NEW-RECORD-INSTANCE (text of UPDATE_STATUS: message 8-30 used in a declaration,
    --         8-80 cancelled, ' يمكن التعديل' otherwise). The MAKE_BLOCK_FULL_OPERATION part is AGNTS_IS_READ_ONLY.
    -- APEX  : Process "WHEN-NEW-RECORD-INSTANCE" (Before Header, after POST-QUERY / WHEN-CREATE-RECORD)
    PROCEDURE WHEN_NEW_RECORD_INSTANCE (P_PORT_CD         IN     NUMBER,
                                        P_ATHRZTN_SEQ_NBR IN     NUMBER,
                                        P_UPDATE_STATUS   IN OUT VARCHAR2);

    -- Source: AGNTS.WHEN-NEW-RECORD-INSTANCE INTRFACE.MAKE_BLOCK_FULL_OPERATION('AGNTS', TRUE, <update>, FALSE):
    --         TRUE (not updatable) for a queried authorization that is used in a declaration or not valid (status 2).
    --         The status is read from the table (the posted item could be changed in the browser).
    -- APEX  : Read Only condition (PL/SQL expression) of the enterable items of region AGNTS (spec §4) and
    --         the server check of PRE_UPDATE.
    FUNCTION  AGNTS_IS_READ_ONLY (P_PORT_CD         IN NUMBER,
                                  P_ATHRZTN_SEQ_NBR IN NUMBER) RETURN BOOLEAN;

    -- ------------------------------------------------------------------ items (navigation order)
    -- Source: AGNTS.ATHRZTN_SEQ_NBR.WHEN-VALIDATE-ITEM (a typed number must be an authorization of the port:
    --         message 9-40; found -> query, see PRE_QUERY)
    -- APEX  : Validation "ATHRZTN_SEQ_NBR VALIDATION" + DA "ATHRZTN_SEQ_NBR WHEN-VALIDATE-ITEM"
    --         (FOS CHECK_ERROR, then Submit Page EXECUTE_QUERY). Returns the error text, NULL = OK.
    FUNCTION  ATHRZTN_SEQ_NBR_VALIDATION (P_PORT_CD         IN NUMBER,
                                          P_ATHRZTN_SEQ_NBR IN NUMBER) RETURN VARCHAR2;

    -- Source: AGNTS.IMPR_NBR.WHEN-VALIDATE-ITEM (importer of the port: 9-20; CHECK_SUSPENSION: 9-70;
    --         not the broker company: 9-10)
    -- APEX  : Validation "IMPR_NBR VALIDATION" (CREATE / SAVE). Returns the error text, NULL = OK.
    FUNCTION  IMPR_NBR_VALIDATION (P_PORT_CD     IN NUMBER,
                                   P_IMPR_NBR    IN NUMBER,
                                   P_IMPR_NBR_AG IN NUMBER) RETURN VARCHAR2;

    -- Source: AGNTS.IMPR_NBR.WHEN-VALIDATE-ITEM (FETCH C_P_NAME INTO :IMPR_NAME) + CGFK$CHK_AGNTS_AG_IMP_FK
    --         (IMPR_EXPR_TYPE, IMPR_NAME); raises the IMPR_NBR_VALIDATION error first.
    -- APEX  : DA "IMPR_NBR WHEN-VALIDATE-ITEM" (Change, FOS, Items to Return P1210_IMPR_NAME, P1210_IMPR_EXPR_TYPE)
    PROCEDURE IMPR_NBR_WHEN_VALIDATE_ITEM (P_PORT_CD        IN     NUMBER,
                                           P_IMPR_NBR       IN     NUMBER,
                                           P_IMPR_NBR_AG    IN     NUMBER,
                                           P_IMPR_NAME      IN OUT VARCHAR2,
                                           P_IMPR_EXPR_TYPE IN OUT NUMBER);

    -- Source: AGNTS.IMPR_NBR_AG.WHEN-VALIDATE-ITEM (broker company of the port: 9-20; CHECK_SUSPENSION: 9-70;
    --         not the importer: 9-10)
    -- APEX  : Validation "IMPR_NBR_AG VALIDATION" (CREATE / SAVE). Returns the error text, NULL = OK.
    FUNCTION  IMPR_NBR_AG_VALIDATION (P_PORT_CD     IN NUMBER,
                                      P_IMPR_NBR    IN NUMBER,
                                      P_IMPR_NBR_AG IN NUMBER) RETURN VARCHAR2;

    -- Source: AGNTS.IMPR_NBR_AG.WHEN-VALIDATE-ITEM (FETCH C_P_NAME INTO :IMPR_NAME_AG) + CGFK$CHK_AGNTS_AG_IMP_AGENT_ID
    -- APEX  : DA "IMPR_NBR_AG WHEN-VALIDATE-ITEM" (Change, FOS, Items to Return P1210_IMPR_NAME_AG,
    --         P1210_IMPR_EXPR_TYPE_AG); raises the IMPR_NBR_AG_VALIDATION error first.
    PROCEDURE IMPR_NBR_AG_WHEN_VALIDATE_ITEM (P_PORT_CD           IN     NUMBER,
                                              P_IMPR_NBR          IN     NUMBER,
                                              P_IMPR_NBR_AG       IN     NUMBER,
                                              P_IMPR_NAME_AG      IN OUT VARCHAR2,
                                              P_IMPR_EXPR_TYPE_AG IN OUT NUMBER);

    -- ------------------------------------------------------------------ DML
    -- Source: AGNTS.PRE-INSERT (next ATHRZTN_SEQ_NBR of the port, status 1, creation date = current Hijri date,
    --         ACTIVITY.ADD_ACTIVITY(9, 1, 1, PORT_CD!ATHRZTN_SEQ_NBR))
    -- APEX  : Process "PRE-INSERT" (After Submit, P0_PAGE_PK null and request CREATE, before "Process form")
    PROCEDURE PRE_INSERT (P_PORT_CD          IN     NUMBER,
                          P_CURR_PORT_CD     IN     NUMBER,
                          SSO_APP_USER       IN     VARCHAR2,
                          P_GLOBAL_V_WS_ID   IN     VARCHAR2,
                          P_ATHRZTN_SEQ_NBR  IN OUT NUMBER,
                          P_ATHRZTN_STA_CD   IN OUT NUMBER,
                          P_ATHRZTN_CRET_DT  IN OUT VARCHAR2);

    -- Source: AGNTS.PRE-UPDATE (ACTIVITY.ADD_ACTIVITY(9, 1, 2, ...) unless a function runs) + the update rule of
    --         WHEN-NEW-RECORD-INSTANCE (server check: a used / cancelled authorization cannot be changed)
    -- APEX  : Process "PRE-UPDATE" (After Submit, P0_PAGE_PK not null and request SAVE, before "Process form")
    PROCEDURE PRE_UPDATE (P_PORT_CD         IN NUMBER,
                          P_ATHRZTN_SEQ_NBR IN NUMBER,
                          P_CURR_PORT_CD    IN NUMBER,
                          SSO_APP_USER      IN VARCHAR2,
                          P_GLOBAL_V_WS_ID  IN VARCHAR2);

    -- Source: FORM.KEY-DELREC (NIB.KEY_DELREC) with AGNTS.WHEN-NEW-RECORD-INSTANCE: a queried authorization is
    --         never deletable (MAKE_BLOCK_FULL_OPERATION ..., FALSE); cancel it with the function CD1_STOPIMPRAUTH.
    -- APEX  : Process "PRE-DELETE" (After Submit, request DELETE): refuses the page 0 DELETE.
    PROCEDURE PRE_DELETE;

    -- =========================================================================
    -- FUNCTIONS                                    (Forms: PU EXEC_FUNS, called by PU EXECUTE_FUNCTION)
    -- =========================================================================
    -- Source: PU EXEC_FUNS
    --   CD1_STOPIMPRAUTH : valid authorization (status 1) -> status 2, cancel date = current Hijri date,
    --                      ACTIVITY.ADD_ACTIVITY(9, 1, 3, ...), COMMIT
    --   CD2_REUSEIMPRAUTH: cancelled authorization (status 2) -> status 1, no cancel date,
    --                      ACTIVITY.ADD_ACTIVITY(9, 1, 4, ...), COMMIT
    --   The confirmations (message 9-50 / 'سيتم إسترجاع التفويض ...') are DA Confirm actions (spec §10).
    -- APEX  : Processes "CD1_STOPIMPRAUTH EXECUTE-FUNCTION" / "CD2_REUSEIMPRAUTH EXECUTE-FUNCTION" (After Submit,
    --         request = function code). Any other code or a record in another status: nothing (as Forms).
    PROCEDURE EXEC_FUNS (P_FUNCTION_CODE   IN VARCHAR2,
                         P_PORT_CD         IN NUMBER,
                         P_ATHRZTN_SEQ_NBR IN NUMBER,
                         P_CURR_PORT_CD    IN NUMBER,
                         SSO_APP_USER      IN VARCHAR2,
                         P_GLOBAL_V_WS_ID  IN VARCHAR2);

    -- Program units without a member:
    -- PU CHECK_SUSPENSION         -> private helper importer_suspended (message 9-70 in the two validations)
    -- PU CGFK$QRY_* / CGFK$CHK_*  -> private helpers port_row / importer_row (POST_QUERY, WHEN_VALIDATE_ITEM members)
    -- PU CGDV$POPULATE_DYNAMIC_LISTS -> shared LOV LOV_ALLOWED_EXPORT (IMPR1110) on ALLOW_EXPORT, IMPR_EXPR_TYPE(_AG)
    -- PU CGTE$CHECK_CONSTRAINT_VIO   -> Text Messages AG_PK, AG_SDP_FK, AG_IMP_FK, AG_IMP_AGENT_ID_FK
    -- PU CGNV$AI_CGSO$WINDOW_1_IMP_NEW -> page button IMP_NEW (redirect to page 1130, to confirm)
    -- PU ADJ_FUNS                  -> empty in Forms (NULL;): no member

END IMPR1210;
/
SHOW ERRORS

-- -----------------------------------------------------------------------------
-- Synonym and grants (run as a user allowed to create public synonyms / grant on LIB_APX_USR)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PUBLIC SYNONYM IMPR1210 FOR LIB_APX_USR.IMPR1210;

GRANT EXECUTE ON LIB_APX_USR.IMPR1210 TO LIB_USR;

GRANT EXECUTE ON LIB_APX_USR.IMPR1210 TO SECURITY_DEFAULT;

GRANT EXECUTE ON LIB_APX_USR.IMPR1210 TO SECURITY_PROD;

-- CUSTOMS = parsing schema of the APEX application (APEX needs a direct grant, not a role)
GRANT EXECUTE ON LIB_APX_USR.IMPR1210 TO CUSTOMS;
