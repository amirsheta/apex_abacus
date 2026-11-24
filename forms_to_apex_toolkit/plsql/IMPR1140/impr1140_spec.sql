-- =============================================================================
-- Package     : IMPR1140             (upper-case form name, no prefix - f345 standard)
-- Source form : IMPR1140.fmb (Oracle Forms 12c) - "قواعد التعامل مع المستوردين"
--               (importer handling rules / exceptions: ports and tariff items, Designer function IMPR1140)
-- Target      : Oracle APEX 21.2 / Oracle Database 12.1.0.2, reference application f345
--               main page 1140 (IMPR1140), search page 114001 (IMPR1140_SEARCH)
-- Author      : Claude Code
-- Created     : 2026-11-24
-- Version     : 001
-- Purpose     : Business logic of the form, organised like the form itself:
--               VERSION -> f345 HELPERS -> FORM LEVEL -> BLOCK IMPR_RULES (master, Form region)
--               -> BLOCK IMPR_RULE_PORTS (detail, Interactive Grid) -> BLOCK IMPR_RULE_TARIFF (detail,
--               Interactive Grid) -> PROGRAM UNITS (docs/f345_reference_standard.md §10).
--               No UI state, no session-state reads: UI rules are DAs / BOOLEAN functions (§9).
-- Parameters  : no I_ / IO_ / O_ prefix (the mode is in IN / IN OUT / OUT). A parameter carrying the page
--               item P1140_<ITEM> is named P_<ITEM> (P_RULE_ISN => :P1140_RULE_ISN, P_PAGE_PK => :P0_PAGE_PK);
--               IG columns keep the column name (PORT_CD => :PORT_CD); f345 application items keep theirs
--               (P_CURR_PORT_CD => :P_CURR_PORT_CD, SSO_APP_USER => :SSO_APP_USER,
--               P_GLOBAL_V_WS_ID => :P_GLOBAL_V_WS_ID). Inside SQL a parameter is qualified with its member
--               name (PRE_DELETE.P_RULE_ISN). Internal members keep p_<name>. Rule: scripts/parameter_names.py.
--               Common helpers (CHECK_ERROR, REQUIRED_VALIDATION, GET_MODULE_ID, HEADER_TITLE, ROWID_FROM_URL,
--               ARABIC_MESSAGE, CG_MESSAGE ...) are in FORMS_APX (version 004) and called as FORMS_APX.<NAME>.
--               The package never reads page items itself, so it is testable without APEX.
-- Names       : IMPR_RULE_PORTS / IMPR_RULE_TARIFF column members drop the block prefix where
--               <BLOCK>_<COLUMN>_<SUFFIX> is longer than 30 bytes (CLAUDE.md §4): PORT_CD exists only in
--               IMPR_RULE_PORTS, HRMNZD_CODE / EXEPTION_QTY only in IMPR_RULE_TARIFF; the full name is in each
--               member's comment. _WHEN_VALIDATE_ITEM becomes _VALIDATE_ITEM only where the name is still > 30.
-- Rules       : every identifier <= 30 bytes (DB 12.1.0.2); no qualified expressions (18c);
--               no COMMIT / ROLLBACK (APEX commits after page processing).
-- Owner       : LIB_APX_USR; public synonym IMPR1140 + EXECUTE grants at the end of this file.
-- Status      : NOT COMPILED. Depends on DB package LIB_USR.SMS_MESSAGE (MISSING SOURCE, call copied
--               unchanged from the Forms code) and on STR_DB through FORMS_APX.ARABIC_MESSAGE (message 1-270).
-- History     : 2026-11-24 Claude Code 001 Initial migration (step 02)
-- =============================================================================
SET DEFINE OFF

CREATE OR REPLACE PACKAGE LIB_APX_USR.IMPR1140 AS
   V_PKG_VERSION       VARCHAR2 (100) := 'VERSION NO. IS:' || '001';
   V_PKG_VERSION_QC    VARCHAR2 (100) := 'VERSION NO. IS:' || '001';
   V_PKG_VERSION_DEV   VARCHAR2 (100) := 'VERSION NO. IS:' || '001';
   FUNCTION PKG_VERSION
      RETURN VARCHAR2;
   V_PACKAGE_NAME      VARCHAR2 (50) := 'IMPR1140';
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

    -- APEX  : Process "P0_PAGE_PK CHECK" (Before Header). P0_PAGE_PK holds the ROWID of the IMPR_RULES
    --         row (as IMPR1110 / IMPR1120); a key that is not a rule is dropped. The search page 114001
    --         passes the ROWID URL-safe (TRANSLATE(ROWID, '+/', '-_')); FORMS_APX.ROWID_FROM_URL restores it.
    PROCEDURE P0_PAGE_PK_CHECK (P_PAGE_PK IN OUT VARCHAR2);

    -- =========================================================================
    -- FORM LEVEL                                   (Forms: form-level triggers)
    -- =========================================================================
    -- No business code at form level: PRE-FORM (version stamp, hide item D, date format) and
    -- WHEN-NEW-FORM-INSTANCE (NIB frame, Designer start-up) are replaced by the f345 shell
    -- (extraction report §1.1).

    -- =========================================================================
    -- BLOCK IMPR_RULES  (master, single record, insert / update / delete)
    -- =========================================================================
    -- Source: IMPR_RULES.POST-QUERY (importer name + CGFK$QRY_LOOKUP_DATA business id type name)
    -- APEX  : Process "POST-QUERY" (Before Header, after "Initialize form", when P1140_ROW_ID is not null)
    PROCEDURE POST_QUERY (P_HQ_IMPR_NBR         IN     NUMBER,
                          P_RULE_TYPE           IN     NUMBER,
                          P_BUS_ID_TYPE_CD      IN     NUMBER,
                          P_CURR_PORT_CD        IN     NUMBER,
                          P_L_SI_ARBC_IMPR_NAME IN OUT VARCHAR2,
                          P_BUS_ID_TYPE_NAME    IN OUT VARCHAR2);

    -- Source: IMPR_RULES.RULE_TYPE.WHEN-LIST-CHANGED and WHEN-VALIDATE-ITEM (same code)
    -- APEX  : Validation "RULE_TYPE VALIDATION" + DA "RULE_TYPE WHEN-LIST-CHANGED" (FOS CHECK_ERROR)
    FUNCTION  RULE_TYPE_VALIDATION (P_RULE_TYPE IN NUMBER) RETURN VARCHAR2;

    -- Source: IMPR_RULES.ALL_BRNCH_FLAG.WHEN-VALIDATE-ITEM -> PU ADJ_BRANCH (see PROGRAM UNITS)

    -- Source: IMPR_RULES.HQ_IMPR_NBR.WHEN-VALIDATE-ITEM (check part)
    -- APEX  : Validation "HQ_IMPR_NBR VALIDATION"
    FUNCTION  HQ_IMPR_NBR_VALIDATION (P_HQ_IMPR_NBR  IN NUMBER,
                                      P_RULE_TYPE    IN NUMBER,
                                      P_CURR_PORT_CD IN NUMBER) RETURN VARCHAR2;

    -- Source: IMPR_RULES.HQ_IMPR_NBR.WHEN-VALIDATE-ITEM (derived values; full name HQ_IMPR_NBR_WHEN_VALIDATE_ITEM, 31 bytes)
    -- APEX  : DA "HQ_IMPR_NBR WHEN-VALIDATE-ITEM" (FOS, Items to Return P1140_BUS_ID, P1140_BUS_ID_BRNCH,
    --         P1140_BUS_ID_TYPE_CD, P1140_L_SI_ARBC_IMPR_NAME, P1140_BUS_ID_TYPE_NAME); raises the error text.
    PROCEDURE HQ_IMPR_NBR_VALIDATE_ITEM (P_HQ_IMPR_NBR         IN     NUMBER,
                                              P_RULE_TYPE           IN     NUMBER,
                                              P_CURR_PORT_CD        IN     NUMBER,
                                              P_BUS_ID              IN OUT VARCHAR2,
                                              P_BUS_ID_BRNCH        IN OUT VARCHAR2,
                                              P_BUS_ID_TYPE_CD      IN OUT NUMBER,
                                              P_L_SI_ARBC_IMPR_NAME IN OUT VARCHAR2,
                                              P_BUS_ID_TYPE_NAME    IN OUT VARCHAR2);

    -- Source: IMPR_RULES.KEY-DELREC (port-row check, CGRI$CHECK_ON_DELETE) + relation CGFK$IRT_IR_FK
    --         (Non-Isolated: no delete while tariff rows exist)
    -- APEX  : Process "KEY-DELREC" (After Submit, request DELETE, before "PRE-DELETE")
    PROCEDURE KEY_DELREC (P_RULE_ISN     IN NUMBER,
                          P_CURR_PORT_CD IN NUMBER);

    -- Source: IMPR_RULES.PRE-INSERT (RULE_ISN = MAX + 1, activity log, role check for rule types 13 / 14)
    -- APEX  : Process "PRE-INSERT" (After Submit, P0_PAGE_PK null and request CREATE)
    PROCEDURE PRE_INSERT (P_RULE_ISN       IN OUT NUMBER,
                          P_RULE_TYPE      IN     NUMBER,
                          P_CURR_PORT_CD   IN     NUMBER,
                          SSO_APP_USER     IN     VARCHAR2,
                          P_GLOBAL_V_WS_ID IN     VARCHAR2);

    -- Source: IMPR_RULES.POST-INSERT (SMS for rule type 14)
    -- APEX  : Process "POST-INSERT" (After Submit, after "Process form", request CREATE)
    PROCEDURE POST_INSERT (P_RULE_ISN     IN NUMBER,
                           P_HQ_IMPR_NBR  IN NUMBER,
                           P_RULE_TYPE    IN NUMBER,
                           P_REC_STATUS   IN NUMBER,
                           P_CURR_PORT_CD IN NUMBER);

    -- Source: IMPR_RULES.PRE-UPDATE (role check for rule types 13 / 14)
    -- APEX  : Process "PRE-UPDATE" (After Submit, P0_PAGE_PK not null and request SAVE)
    PROCEDURE PRE_UPDATE (P_RULE_TYPE    IN NUMBER,
                          P_CURR_PORT_CD IN NUMBER,
                          SSO_APP_USER   IN VARCHAR2);

    -- Source: IMPR_RULES.POST-UPDATE (activity log + SMS for rule type 14)
    -- APEX  : Process "POST-UPDATE" (After Submit, after "Process form", request SAVE)
    PROCEDURE POST_UPDATE (P_RULE_ISN       IN NUMBER,
                           P_HQ_IMPR_NBR    IN NUMBER,
                           P_RULE_TYPE      IN NUMBER,
                           P_REC_STATUS     IN NUMBER,
                           P_CURR_PORT_CD   IN NUMBER,
                           SSO_APP_USER     IN VARCHAR2,
                           P_GLOBAL_V_WS_ID IN VARCHAR2);

    -- Source: IMPR_RULES.PRE-DELETE (activity log)
    -- APEX  : Process "PRE-DELETE" (After Submit, request DELETE)
    PROCEDURE PRE_DELETE (P_RULE_ISN       IN NUMBER,
                          P_CURR_PORT_CD   IN NUMBER,
                          SSO_APP_USER     IN VARCHAR2,
                          P_GLOBAL_V_WS_ID IN VARCHAR2);

    -- =========================================================================
    -- BLOCK IMPR_RULE_PORTS  (detail, 8 rows, WHERE PORT_CD = :P_CURR_PORT_CD)
    -- =========================================================================
    -- Source: IMPR_RULE_PORTS.POST-QUERY / PRE-RECORD / WHEN-NEW-RECORD-INSTANCE
    --         (SET_BLOCK_PROPERTY(INSERT_ALLOWED) by IMPR_RULES.ALL_BRNCH_FLAG)
    -- APEX  : used by IMPR_RULE_PORTS_PRE_INSERT (server check) and by the server-side condition of the
    --         ports grid "add row" (page spec §3).
    FUNCTION  IMPR_RULE_PORTS_INSERT_ALLOWED (P_ALL_BRNCH_FLAG IN NUMBER) RETURN BOOLEAN;

    -- Source: IMPR_RULE_PORTS.PORT_CD.WHEN-VALIDATE-ITEM (CGFK$VALDIDATE_FK_OVF) - check part
    --         (full name IMPR_RULE_PORTS_PORT_CD_VALIDATION, 34 bytes)
    -- APEX  : IG validation "IMPR_RULE_PORTS PORT_CD VALIDATION"
    FUNCTION  PORT_CD_VALIDATION (PORT_CD IN NUMBER) RETURN VARCHAR2;

    -- Source: IMPR_RULE_PORTS.PORT_CD.WHEN-VALIDATE-ITEM - derived PORT_NAME
    --         (full name IMPR_RULE_PORTS_PORT_CD_WHEN_VALIDATE_ITEM)
    -- APEX  : DA "IMPR_RULE_PORTS PORT_CD WHEN-VALIDATE-ITEM" (FOS, Items to Return PORT_NAME)
    PROCEDURE PORT_CD_WHEN_VALIDATE_ITEM (PORT_CD   IN     NUMBER,
                                          PORT_NAME IN OUT VARCHAR2);

    -- Source: IMPR_RULE_PORTS.PRE-INSERT (activity log) + insert-allowed rule (see above)
    PROCEDURE IMPR_RULE_PORTS_PRE_INSERT (RULE_ISN         IN NUMBER,
                                          PORT_CD          IN NUMBER,
                                          P_ALL_BRNCH_FLAG IN NUMBER,
                                          P_CURR_PORT_CD   IN NUMBER,
                                          SSO_APP_USER     IN VARCHAR2,
                                          P_GLOBAL_V_WS_ID IN VARCHAR2);

    -- Source: IMPR_RULE_PORTS.PRE-UPDATE (activity log)
    PROCEDURE IMPR_RULE_PORTS_PRE_UPDATE (RULE_ISN         IN NUMBER,
                                          PORT_CD          IN NUMBER,
                                          P_CURR_PORT_CD   IN NUMBER,
                                          SSO_APP_USER     IN VARCHAR2,
                                          P_GLOBAL_V_WS_ID IN VARCHAR2);

    -- Source: IMPR_RULE_PORTS.PRE-DELETE (activity log)
    PROCEDURE IMPR_RULE_PORTS_PRE_DELETE (RULE_ISN         IN NUMBER,
                                          PORT_CD          IN NUMBER,
                                          P_CURR_PORT_CD   IN NUMBER,
                                          SSO_APP_USER     IN VARCHAR2,
                                          P_GLOBAL_V_WS_ID IN VARCHAR2);

    -- Source: block IMPR_RULE_PORTS DML in Forms order (PRE-<op> trigger, then the row DML of the block)
    -- APEX  : Process "IMPR_RULE_PORTS - Save Interactive Grid Data" (IG DML, Target Type PL/SQL Code):
    --           IMPR1140.IMPR_RULE_PORTS_SAVE_ROW(APEX$ROW_STATUS => :APEX$ROW_STATUS, ROW_ID => :ROW_ID, ...);
    --         ROW_ID = ROWIDTOCHAR of the row; returned for a new row so the grid can refresh it.
    PROCEDURE IMPR_RULE_PORTS_SAVE_ROW (APEX$ROW_STATUS  IN     VARCHAR2,
                                        ROW_ID           IN OUT VARCHAR2,
                                        RULE_ISN         IN     NUMBER,
                                        PORT_CD          IN     NUMBER,
                                        REC_STATUS       IN     NUMBER,
                                        P_ALL_BRNCH_FLAG IN     NUMBER,
                                        P_CURR_PORT_CD   IN     NUMBER,
                                        SSO_APP_USER     IN     VARCHAR2,
                                        P_GLOBAL_V_WS_ID IN     VARCHAR2);

    -- =========================================================================
    -- BLOCK IMPR_RULE_TARIFF  (detail, 8 rows, Delete Allowed = false)
    -- =========================================================================
    -- Source: IMPR_RULE_TARIFF.POST-QUERY (international unit of the item, latest TARIFF_DETAILS row)
    -- APEX  : column INTL_UNIT of the grid SQL:
    --           (SELECT IMPR1140.IMPR_RULE_TARIFF_POST_QUERY(HRMNZD_CODE => t.hrmnzd_code) FROM dual)
    FUNCTION  IMPR_RULE_TARIFF_POST_QUERY (HRMNZD_CODE IN VARCHAR2) RETURN VARCHAR2;

    -- Source: IMPR_RULE_TARIFF.HRMNZD_CODE.WHEN-VALIDATE-ITEM - check part (item not found / already
    --         excepted for the importer). Full name IMPR_RULE_TARIFF_HRMNZD_CODE_VALIDATION (39 bytes).
    -- APEX  : IG validation "IMPR_RULE_TARIFF HRMNZD_CODE VALIDATION" + the FOS DA below
    FUNCTION  HRMNZD_CODE_VALIDATION (HRMNZD_CODE      IN VARCHAR2,
                                      P_RULE_ISN       IN NUMBER,
                                      P_HQ_IMPR_NBR    IN NUMBER,
                                      P_BUS_ID_TYPE_CD IN NUMBER,
                                      P_BUS_ID         IN VARCHAR2) RETURN VARCHAR2;

    -- Source: IMPR_RULE_TARIFF.HRMNZD_CODE.WHEN-VALIDATE-ITEM (derived description and international unit)
    --         + HRMNZD_CODE.POST-CHANGE (description). Full name IMPR_RULE_TARIFF_HRMNZD_CODE_WHEN_VALIDATE_ITEM.
    -- APEX  : DA "IMPR_RULE_TARIFF HRMNZD_CODE WHEN-VALIDATE-ITEM" (FOS, Items to Return HT_ITEM_ARBC_DESC,
    --         INTL_UNIT); raises the error text of HRMNZD_CODE_VALIDATION.
    PROCEDURE HRMNZD_CODE_VALIDATE_ITEM (HRMNZD_CODE       IN     VARCHAR2,
                                         P_RULE_ISN        IN     NUMBER,
                                         P_HQ_IMPR_NBR     IN     NUMBER,
                                         P_BUS_ID_TYPE_CD  IN     NUMBER,
                                         P_BUS_ID          IN     VARCHAR2,
                                         HT_ITEM_ARBC_DESC IN OUT VARCHAR2,
                                         INTL_UNIT         IN OUT VARCHAR2);

    -- Source: IMPR_RULE_TARIFF.EXEPTION_QTY.WHEN-VALIDATE-ITEM (REMAINED_QTY := EXEPTION_QTY)
    --         Full name IMPR_RULE_TARIFF_EXEPTION_QTY_WHEN_VALIDATE_ITEM. The INFORMATION alert is the
    --         native Alert action of the DA (page spec §10).
    -- APEX  : DA "IMPR_RULE_TARIFF EXEPTION_QTY WHEN-VALIDATE-ITEM" (FOS, Items to Return REMAINED_QTY)
    PROCEDURE EXEPTION_QTY_VALIDATE_ITEM (EXEPTION_QTY IN     NUMBER,
                                          REMAINED_QTY IN OUT NUMBER);

    -- Source: IMPR_RULE_TARIFF.PRE-INSERT (ITEM_SEQUENCE = MAX + 1 in the rule, REC_STATUS default 1,
    --         activity log)
    PROCEDURE IMPR_RULE_TARIFF_PRE_INSERT (RULE_ISN         IN     NUMBER,
                                           HRMNZD_CODE      IN     VARCHAR2,
                                           ITEM_SEQUENCE    IN OUT NUMBER,
                                           REC_STATUS       IN OUT NUMBER,
                                           P_CURR_PORT_CD   IN     NUMBER,
                                           SSO_APP_USER     IN     VARCHAR2,
                                           P_GLOBAL_V_WS_ID IN     VARCHAR2);

    -- Source: IMPR_RULE_TARIFF.PRE-UPDATE (activity log)
    PROCEDURE IMPR_RULE_TARIFF_PRE_UPDATE (RULE_ISN         IN NUMBER,
                                           HRMNZD_CODE      IN VARCHAR2,
                                           P_CURR_PORT_CD   IN NUMBER,
                                           SSO_APP_USER     IN VARCHAR2,
                                           P_GLOBAL_V_WS_ID IN VARCHAR2);

    -- Source: block IMPR_RULE_TARIFF DML in Forms order (PRE-INSERT / PRE-UPDATE, then the row DML).
    --         Delete Allowed = false: a deleted row is refused (FRM-41049).
    -- APEX  : Process "IMPR_RULE_TARIFF - Save Interactive Grid Data" (IG DML, Target Type PL/SQL Code)
    PROCEDURE IMPR_RULE_TARIFF_SAVE_ROW (APEX$ROW_STATUS  IN     VARCHAR2,
                                         ROW_ID           IN OUT VARCHAR2,
                                         RULE_ISN         IN     NUMBER,
                                         HRMNZD_CODE      IN     VARCHAR2,
                                         EXEPTION_QTY     IN     NUMBER,
                                         REMAINED_QTY     IN     NUMBER,
                                         REC_STATUS       IN     NUMBER,
                                         ITEM_SEQUENCE    IN OUT NUMBER,
                                         P_CURR_PORT_CD   IN     NUMBER,
                                         SSO_APP_USER     IN     VARCHAR2,
                                         P_GLOBAL_V_WS_ID IN     VARCHAR2);

    -- =========================================================================
    -- PROGRAM UNITS                                (Forms: Program Units node, same names)
    -- =========================================================================
    -- Source: PU CGFK$QRY_IMPR_RULES_IR_BIT_FK (Designer lookup of the business id type name).
    --         Raises NO_DATA_FOUND when not found.
    PROCEDURE CGFK$QRY_IMPR_RULES_IR_BIT_FK (p_bus_id_type_name IN OUT VARCHAR2,
                                             p_bus_id_type_cd   IN     NUMBER);

    -- Source: PU CGFK$CHK_IMPR_RULE_PORTS_IRP_S (Designer FK check of PORT_CD). Raises NO_DATA_FOUND.
    PROCEDURE CGFK$CHK_IMPR_RULE_PORTS_IRP_S (p_port_name IN OUT VARCHAR2,
                                              p_port_cd   IN     NUMBER);

    -- Source: PU CGRI$CHK_IMPR_RULES (deletion prevented while IMPR_RULE_PORTS rows exist, FK IRP_IR2_FK).
    PROCEDURE CGRI$CHK_IMPR_RULES (p_rule_isn IN NUMBER);

    -- Source: PU CHECK_FASH_ROLE_ID (user holds role IMP_EXCEPTION_FASH in the port)
    FUNCTION  CHECK_FASH_ROLE_ID (p_port_cd IN NUMBER,
                                  p_user_id IN VARCHAR2) RETURN BOOLEAN;

    -- Source: PU ADJ_BRANCH (business part: BUS_ID_BRNCH := NULL when ALL_BRNCH_FLAG = 1; the
    --         MAKE_FIELD_ENTRABLE part is the DA "ALL_BRNCH_FLAG WHEN-VALIDATE-ITEM")
    -- APEX  : Process "ALL_BRNCH_FLAG WHEN-VALIDATE-ITEM" (After Submit, before "PRE-INSERT"):
    --           IMPR1140.ADJ_BRANCH(P_ALL_BRNCH_FLAG => :P1140_ALL_BRNCH_FLAG, P_BUS_ID_BRNCH => :P1140_BUS_ID_BRNCH);
    PROCEDURE ADJ_BRANCH (P_ALL_BRNCH_FLAG IN     NUMBER,
                          P_BUS_ID_BRNCH   IN OUT VARCHAR2);

END IMPR1140;
/
SHOW ERRORS

-- -----------------------------------------------------------------------------
-- Synonym and grants (run as a user allowed to create public synonyms / grant on LIB_APX_USR)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PUBLIC SYNONYM IMPR1140 FOR LIB_APX_USR.IMPR1140;

GRANT EXECUTE ON LIB_APX_USR.IMPR1140 TO LIB_USR;

GRANT EXECUTE ON LIB_APX_USR.IMPR1140 TO SECURITY_DEFAULT;

GRANT EXECUTE ON LIB_APX_USR.IMPR1140 TO SECURITY_PROD;

-- CUSTOMS = parsing schema of the APEX application (APEX needs a direct grant, not a role)
GRANT EXECUTE ON LIB_APX_USR.IMPR1140 TO CUSTOMS;
