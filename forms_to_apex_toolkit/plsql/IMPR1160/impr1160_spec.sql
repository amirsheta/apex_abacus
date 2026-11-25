-- =============================================================================
-- Package     : IMPR1160             (upper-case form name, no prefix - f345 standard)
-- Source form : IMPR1160.fmb (Oracle Forms 12c, title IMPR1160_ND_CNTRL) - "استثناء المستوردين الافراد للسيارات"
--               (car exceptions of individual importers: a number of cars of one declaration, by an award letter)
-- Target      : Oracle APEX 21.2 / Oracle Database 12.1.0.2, reference application f345
--               main page 1160 (IMPR1160), search page 116001 (IMPR1160_SEARCH)
-- Author      : Claude Code
-- Created     : 2026-11-25
-- Version     : 001
-- Purpose     : Business logic of the form, organised like the form itself:
--               VERSION -> f345 HELPERS -> FORM LEVEL -> BLOCK IMPR_CAR_EXCEPTION (single record, Form region)
--               -> PROGRAM UNITS (docs/f345_reference_standard.md §10).
--               No UI state, no session-state reads: UI rules are DAs / APEX conditions (§9).
-- Parameters  : no I_ / IO_ / O_ prefix (the mode is in IN / IN OUT / OUT). A parameter carrying the page
--               item P1160_<ITEM> is named P_<ITEM> (P_IMPR_NBR => :P1160_IMPR_NBR, P_PAGE_PK => :P0_PAGE_PK);
--               f345 application items keep their names (P_CURR_PORT_CD => :P_CURR_PORT_CD). Inside SQL a
--               parameter is qualified with its member name (PRE_INSERT.P_IMPR_NBR). Internal members keep p_<name>.
--               Common helpers (CHECK_ERROR, HIJRI_TEXT, HIJRI_TEXT_TO_DATE, HIJRI_DATE_ERROR, CUR_HIJ_DATE,
--               FORM_TRIGGER_FAILURE, ROWID_FROM_URL ...) are in FORMS_APX (version 004).
-- Dates       : Hijri dates are DATE values with the day in the minutes (Forms mask MI-MM-RRRR); the page
--               shows them as text in FORMS_APX.HIJRI_DATE_FORMAT (Application Setting, as IMPR1120), so the
--               Hijri parameters of this package are VARCHAR2 texts in that format.
-- Rules       : every identifier <= 30 bytes (DB 12.1.0.2); no qualified expressions (18c);
--               no COMMIT / ROLLBACK (APEX commits after page processing).
-- Owner       : LIB_APX_USR; public synonym IMPR1160 + EXECUTE grants at the end of this file.
-- Status      : NOT COMPILED. Depends on DB package GNRL (GET_SEQUENCE_VALUE, GET_CUSTOMS_SETTING:
--               MISSING SOURCE, calls copied unchanged from the Forms code) and on HIJDATE_DB.
-- History     : 2026-11-25 Claude Code 001 Initial migration (step 02)
-- =============================================================================
SET DEFINE OFF

CREATE OR REPLACE PACKAGE LIB_APX_USR.IMPR1160 AS
   V_PKG_VERSION       VARCHAR2 (100) := 'VERSION NO. IS:' || '001';
   V_PKG_VERSION_QC    VARCHAR2 (100) := 'VERSION NO. IS:' || '001';
   V_PKG_VERSION_DEV   VARCHAR2 (100) := 'VERSION NO. IS:' || '001';

   FUNCTION PKG_VERSION
      RETURN VARCHAR2;

   V_PACKAGE_NAME      VARCHAR2 (50) := 'IMPR1160';
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
    -- APEX  : Process "P0_PAGE_PK CHECK" (Before Header). P0_PAGE_PK holds the ROWID of the IMPR_CAR_EXCEPTION
    --         row (as IMPR1140); a key that is not an exception is dropped. The search page 116001 passes the
    --         ROWID URL-safe (TRANSLATE(ROWID, '+/', '-_')); FORMS_APX.ROWID_FROM_URL restores it.
    PROCEDURE P0_PAGE_PK_CHECK (P_PAGE_PK IN OUT VARCHAR2);

    -- =========================================================================
    -- FORM LEVEL                                   (Forms: form-level triggers)
    -- =========================================================================
    -- Source: FORM.WHEN-NEW-FORM-INSTANCE (last block: EXPTN_START_DT := current Hijri date; PORT_CD /
    --         PORT_NAME of the user's port). NIB frame, versions, POPULATE_DYNAMIC_LISTS (empty) and the
    --         SET_ITEM_PROPERTY calls (DCLTN_NBR / DCLTN_DT enterable) are replaced by the page (spec §4).
    -- APEX  : Process "WHEN-NEW-FORM-INSTANCE" (Before Header, after "Initialize form", P0_PAGE_PK null = new record)
    PROCEDURE WHEN_NEW_FORM_INSTANCE (P_CURR_PORT_CD   IN     NUMBER,
                                      P_PORT_CD        IN OUT NUMBER,
                                      P_PORT_NAME      IN OUT VARCHAR2,
                                      P_EXPTN_START_DT IN OUT VARCHAR2);

    -- =========================================================================
    -- BLOCK IMPR_CAR_EXCEPTION  (single record; insert; queried record: STATUS update, delete)
    -- =========================================================================
    -- Source: IMPR_CAR_EXCEPTION.POST-QUERY (importer name, port name, declaration number / date). The
    --         SET_ITEM_PROPERTY('STATUS' ...) part is the item rule "STATUS enterable" (spec §4).
    -- APEX  : Process "POST-QUERY" (Before Header, after "Initialize form", when P1160_ROW_ID is not null)
    PROCEDURE POST_QUERY (P_IMPR_NBR     IN     NUMBER,
                          P_DCLTN_TYPE   IN     NUMBER,
                          P_DCLTN_ISN    IN     NUMBER,
                          P_STATS_ISN    IN     NUMBER,
                          P_CURR_PORT_CD IN     NUMBER,
                          P_IMPR_NAME    IN OUT VARCHAR2,
                          P_PORT_NAME    IN OUT VARCHAR2,
                          P_DCLTN_NBR    IN OUT VARCHAR2,
                          P_DCLTN_DT     IN OUT VARCHAR2);

    -- Source: IMPR_CAR_EXCEPTION.IMPR_NBR.WHEN-VALIDATE-ITEM + KEY-NEXT-ITEM (suspension check)
    -- APEX  : Validation "IMPR_NBR VALIDATION" (request CREATE). Returns the error text, NULL = OK.
    FUNCTION  IMPR_NBR_VALIDATION (P_PORT_CD  IN NUMBER,
                                   P_IMPR_NBR IN NUMBER) RETURN VARCHAR2;

    -- Source: IMPR_CAR_EXCEPTION.IMPR_NBR.KEY-NEXT-ITEM (importer name of type 4, then the suspension check)
    -- APEX  : DA "IMPR_NBR KEY-NEXT-ITEM" (Change, FOS, Items to Return P1160_IMPR_NAME); raises the error.
    PROCEDURE IMPR_NBR_KEY_NEXT_ITEM (P_PORT_CD   IN     NUMBER,
                                      P_IMPR_NBR  IN     NUMBER,
                                      P_IMPR_NAME IN OUT VARCHAR2);

    -- Source: IMPR_CAR_EXCEPTION.DCLTN_NBR.POST-CHANGE (declaration ISN and date, number of cars of tariff group 76)
    -- APEX  : DA "DCLTN_NBR POST-CHANGE" (Change, FOS, Items to Return P1160_DCLTN_ISN, P1160_STATS_ISN,
    --         P1160_DCLTN_DT, P1160_NO_OF_CARS); raises the Forms message when the declaration is unknown.
    PROCEDURE DCLTN_NBR_POST_CHANGE (P_DCLTN_TYPE   IN     NUMBER,
                                     P_DCLTN_NBR    IN     VARCHAR2,
                                     P_IMPR_NBR     IN     NUMBER,
                                     P_CURR_PORT_CD IN     NUMBER,
                                     P_DCLTN_ISN    IN OUT NUMBER,
                                     P_STATS_ISN    IN OUT NUMBER,
                                     P_DCLTN_DT     IN OUT VARCHAR2,
                                     P_NO_OF_CARS   IN OUT NUMBER);

    -- Source: IMPR_CAR_EXCEPTION.AWARD_NBR.WHEN-VALIDATE-ITEM
    -- APEX  : Validation "AWARD_NBR VALIDATION" + DA "AWARD_NBR WHEN-VALIDATE-ITEM" (FOS CHECK_ERROR)
    FUNCTION  AWARD_NBR_VALIDATION (P_AWARD_NBR IN VARCHAR2) RETURN VARCHAR2;

    -- Source: IMPR_CAR_EXCEPTION.AWARD_DATE.WHEN-VALIDATE-ITEM (HIJDATE.VALID_HIJ_DATE): no member, the page
    --         calls FORMS_APX.HIJRI_DATE_ERROR directly (CLAUDE.md §4a rule 3).

    -- Source: IMPR_CAR_EXCEPTION.NO_OF_CARS.WHEN-VALIDATE-ITEM
    -- APEX  : Validation "NO_OF_CARS VALIDATION" + DA "NO_OF_CARS WHEN-VALIDATE-ITEM" (FOS CHECK_ERROR)
    FUNCTION  NO_OF_CARS_VALIDATION (P_NO_OF_CARS IN NUMBER) RETURN VARCHAR2;

    -- Source: IMPR_CAR_EXCEPTION.PRE-INSERT (exception number from the central sequence, entry date,
    --         declaration ISN, "already excepted" check) + CGUI$GET_UNIQUE_ID_MODIFIED
    -- APEX  : Process "PRE-INSERT" (After Submit, P0_PAGE_PK null and request CREATE, before "Process form")
    PROCEDURE PRE_INSERT (P_DCLTN_TYPE   IN     NUMBER,
                          P_DCLTN_NBR    IN     VARCHAR2,
                          P_DCLTN_DT     IN     VARCHAR2,
                          P_IMPR_NBR     IN     NUMBER,
                          P_CURR_PORT_CD IN     NUMBER,
                          P_EXCPT_ISN    IN OUT NUMBER,
                          P_ENTRY_DT     IN OUT VARCHAR2,
                          P_DCLTN_ISN    IN OUT NUMBER,
                          P_STATS_ISN    IN OUT NUMBER);

    -- Source: IMPR_CAR_EXCEPTION.PRE-UPDATE (an inactive exception cannot be changed)
    -- APEX  : Process "PRE-UPDATE" (After Submit, P0_PAGE_PK not null and request SAVE, before "Process form")
    PROCEDURE PRE_UPDATE (P_PORT_CD   IN NUMBER,
                          P_EXCPT_ISN IN NUMBER);

    -- =========================================================================
    -- PROGRAM UNITS                                (Forms: Program Units node, same names)
    -- =========================================================================
    -- Source: PU GET_NEXT_IMPR_CAR_EXPTN_CNTRL (NALSALEH CENTRALIZED PROJECT): next value of IMPR_CAR_EXPTN_SEQ
    --         through GNRL.GET_SEQUENCE_VALUE. Raises NO_DATA_FOUND when nothing is returned (as the cursor).
    PROCEDURE GET_NEXT_IMPR_CAR_EXPTN_CNTRL (p_curr_port_cd IN     NUMBER,
                                             p_next_value   IN OUT NUMBER);

    -- PU CALL_IMPR_LOV        -> Popup LOV LOV_IMPR_P on P1160_IMPR_NBR (LOV_APX.IMPORTERS, type 4 / 5) + the DA
    --                            "IMPR_NBR KEY-NEXT-ITEM" for the name (no member)
    -- PU CALL_IMPR_DCLTN_LOV  -> Popup LOV LOV_IMPR_DCLTN on P1160_DCLTN_NBR (LOV_APX.LOV_IMPR_DCLTN) + the DA
    --                            "DCLTN_NBR POST-CHANGE" for the date (no member)
    -- PU EXEC_FUNS, ADJ_FUNS  -> empty in Forms (NULL;): no functions, no member

END IMPR1160;
/
SHOW ERRORS

-- -----------------------------------------------------------------------------
-- Synonym and grants (run as a user allowed to create public synonyms / grant on LIB_APX_USR)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PUBLIC SYNONYM IMPR1160 FOR LIB_APX_USR.IMPR1160;

GRANT EXECUTE ON LIB_APX_USR.IMPR1160 TO LIB_USR;

GRANT EXECUTE ON LIB_APX_USR.IMPR1160 TO SECURITY_DEFAULT;

GRANT EXECUTE ON LIB_APX_USR.IMPR1160 TO SECURITY_PROD;

-- CUSTOMS = parsing schema of the APEX application (APEX needs a direct grant, not a role)
GRANT EXECUTE ON LIB_APX_USR.IMPR1160 TO CUSTOMS;
