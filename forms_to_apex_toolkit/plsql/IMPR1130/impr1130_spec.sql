-- =============================================================================
-- Package     : IMPR1130  (form IMPR1130.fmb "إضافة وتعديل بيانات مستورد", module IMPR1110_PROD_CENTRL)
-- Owner       : LIB_APX_USR (public synonym IMPR1130; EXECUTE granted to LIB_USR, SECURITY_DEFAULT, SECURITY_PROD, CUSTOMS)
-- Version     : 001 (24-11-2026: step 02 - first version)
-- Author      : Claude Code
-- Status      : NOT COMPILED.
-- Source      : forms/IMPR/IMPR1130_fmb.xml; analysis analysis/IMPR1130/IMPR1130_inventory.md and
--               analysis/IMPR1130/IMPR1130_logic_extraction.md; read-only rules work/IMPR1130/step02/read_only_rules.md.
--               IMPR1130 is an older copy of IMPR1110: members whose Forms code is identical follow the
--               IMPR1110 package (version 013) line by line; the others are converted from the IMPR1130 code.
-- Layout      : VERSION -> f345 HELPERS -> FORM LEVEL -> BLOCK IMPORTERS (query, record, items in Forms
--               navigation order with their read-only / required rules, DML) -> FUNCTIONS.
--               Every member here is called by APEX with named binds. Parameter names have no I_ / IO_ / O_
--               prefix (the mode is IN / IN OUT / OUT); a page item P1130_X is passed as P_X
--               (P_BUS_ID => :P1130_BUS_ID, P_PAGE_PK => :P0_PAGE_PK, P_PRSNL_IMPR => :P1130_P_PRSNL_IMPR),
--               application items keep their name (P_CURR_PORT_CD => :P_CURR_PORT_CD, G_ALLOW_MCI => :G_ALLOW_MCI).
--               Hijri DATE items are passed as text in FORMS_APX.HIJRI_DATE_FORMAT (as IMPR1110).
--               SQL is kept in private members of the body; the public members only pass values.
-- Validation  : <ITEM>_VALIDATION returns the error text (NULL = valid) and never changes a value; it is used
--               by the validation "<ITEM> VALIDATION" and by the DA "<ITEM> WHEN-VALIDATE-ITEM" through
--               FORMS_APX.CHECK_ERROR. <ITEM>_WHEN_VALIDATE_ITEM (or <ITEM>_VALIDATE_ITEM when the full name is
--               longer than 30 bytes) runs the whole trigger with its side effects (FOS, Items to Return).
-- =============================================================================
SET DEFINE OFF

CREATE OR REPLACE PACKAGE LIB_APX_USR.IMPR1130 AS
   V_PKG_VERSION       VARCHAR2 (100) := 'VERSION NO. IS:' || '001';
   V_PKG_VERSION_QC    VARCHAR2 (100) := 'VERSION NO. IS:' || '001';
   V_PKG_VERSION_DEV   VARCHAR2 (100) := 'VERSION NO. IS:' || '001';
   FUNCTION PKG_VERSION
      RETURN VARCHAR2;
   V_PACKAGE_NAME      VARCHAR2 (50) := 'IMPR1130';
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

    c_yes CONSTANT PLS_INTEGER := 1;   -- confirm answers (ALERT_BUTTON1 / ALERT_BUTTON2)
    c_no  CONSTANT PLS_INTEGER := 2;

    -- =========================================================================
    -- f345 HELPERS
    -- =========================================================================

    -- Read-only flags of the items whose rule can change while the page is open (after a change of
    -- IMPR_TYPE_CD, BUS_ID_TYPE_CD, COMM_RGSTRTN_TYPE, NATIONAL_NBR (web service), BUS_ID, BUS_ID_BRNCH).
    -- IMPR_NBR, IMPR_TYPE_CD, BUS_ID_TYPE_CD, ARBC_IMPR_NAME, ENG_IMPR_NAME do not change while the page is
    -- open: they use a Read Only condition with their <ITEM>_IS_READ_ONLY function.
    -- APEX renders a Read Only item as text, which native Enable cannot undo, so these items use flags
    -- (same design as IMPR1110). 'Y' = read-only. Rules: work/IMPR1130/step02/read_only_rules.md.
    -- APEX  : Before Header process "READ ONLY FLAGS" and the last FOS action of the DAs above
    --         (Items to Return = P1130_<ITEM>_LOCKED); DA "<ITEM> READ ONLY" on change of P1130_<ITEM>_LOCKED:
    --         Disable when Y, else Enable (fire on initialization). REGISTER_ITEMS = IMPR_POB_NBR,
    --         IMPR_ZIP_CD, IMPR_FAX_NBR, IMPR_TELEX_NBR.
    PROCEDURE READ_ONLY_FLAGS (P_ROW_ID                   IN  VARCHAR2,
                               P_PRSNL_IMPR               IN  NUMBER,
                               P_IMPR_TYPE_CD             IN  NUMBER,
                               P_BUS_ID_TYPE_CD           IN  NUMBER,
                               P_COMM_RGSTRTN_TYPE        IN  NUMBER,
                               P_BUS_ID                   IN  VARCHAR2,
                               P_BUS_ID_BRNCH             IN  VARCHAR2,
                               P_BUS_ID_EXPRD_DT          IN  VARCHAR2,
                               P_CREATION_FLAG            IN  NUMBER,
                               G_ALLOW_MCI                IN  VARCHAR2,
                               P_COMM_RGSTRTN_TYPE_LOCKED OUT VARCHAR2,
                               P_CTRY_CD_LOCKED           OUT VARCHAR2,
                               P_ADD_CTRY_CD_LOCKED       OUT VARCHAR2,
                               P_CITY_CODE_OF_ID_LOCKED   OUT VARCHAR2,
                               P_BUS_ID_LOCKED            OUT VARCHAR2,
                               P_BUS_ID_BRNCH_LOCKED      OUT VARCHAR2,
                               P_BUS_ID_EXPRD_DT_LOCKED   OUT VARCHAR2,
                               P_REGISTER_ITEMS_LOCKED    OUT VARCHAR2);

    -- Process "P0_PAGE_PK CHECK" (Before Header): P0_PAGE_PK holds the ROWID of the importer (Forms key
    -- mode ROWID); a key that is not a row of IMPORTERS of this port (block WHERE clause) is forgotten.
    -- The search page 113001 passes the ROWID URL-safe; FORMS_APX.ROWID_FROM_URL translates it back.
    PROCEDURE P0_PAGE_PK_CHECK (P_PAGE_PK      IN OUT VARCHAR2,
                                P_CURR_PORT_CD IN     NUMBER);

    -- Process "EXECUTE-QUERY" (request EXECUTE_QUERY): the ROWID of importer IMPR_NBR of this port, for
    -- P0_PAGE_PK. Source: IMPORTERS.IMPR_NBR.WHEN-VALIDATE-ITEM (existing number -> :GLOBAL.EXEC_QUERY_NOW
    -- -> IMPORTERS.WHEN-NEW-ITEM-INSTANCE EXECUTE_QUERY with PRE-QUERY on :GLOBAL.PORT_CD / IMPR_NBR)
    FUNCTION IMPORTER_ROW_ID (P_IMPR_NBR     IN NUMBER,
                              P_CURR_PORT_CD IN NUMBER) RETURN VARCHAR2;

    -- Process "PARAMETERS ENTRY" (f345): one-shot hand-over of :PARAMETER.PRSNL_IMPR / LETTER_NBR from the
    -- application items P_PRSNL_IMPR / P_LETTER_NBR to the page items P1130_P_PRSNL_IMPR / P1130_P_LETTER_NBR.
    PROCEDURE PARAMETERS_ENTRY (APP_P_PRSNL_IMPR IN OUT VARCHAR2,
                                APP_P_LETTER_NBR IN OUT VARCHAR2,
                                P_PRSNL_IMPR     IN OUT VARCHAR2,
                                P_LETTER_NBR     IN OUT VARCHAR2);

    -- =========================================================================
    -- FORM LEVEL
    -- =========================================================================

    -- Source: IMPR1130.WHEN-NEW-FORM-INSTANCE (business part; NIB / timers / versioning / TMPLT are the
    --         f345 frame, CG$WHEN_NEW_FORM_INSTANCE fills list items -> shared LOVs, SUPPORT_ENTRY -> page 9001)
    -- APEX  : Process "WHEN-NEW-FORM-INSTANCE" (Before Header, after "WHEN-CREATE-RECORD": Forms fires
    --         WHEN-CREATE-RECORD of the first record before WHEN-NEW-FORM-INSTANCE). The country defaults
    --         are applied to a new record only (P_ROW_ID null).
    PROCEDURE WHEN_NEW_FORM_INSTANCE (P_ROW_ID             IN     VARCHAR2,
                                      P_IMPR_TYPE_CD       IN     importers.impr_type_cd%TYPE,
                                      P_BUS_ID_TYPE_CD     IN     importers.bus_id_type_cd%TYPE,
                                      P_CTRY_CD            IN OUT importers.ctry_cd%TYPE,
                                      P_CRTY_ARBC_NAME     IN OUT VARCHAR2,
                                      P_ADD_CTRY_CD        IN OUT importers.add_ctry_cd%TYPE,
                                      P_ADD_CRTY_ARBC_NAME IN OUT VARCHAR2,
                                      P_CURR_PORT_CD       IN     NUMBER,
                                      G_ALLOW_MCI          OUT    VARCHAR2,
                                      G_ALLOW_MOI          OUT    VARCHAR2);

    -- =========================================================================
    -- BLOCK IMPORTERS - query
    -- =========================================================================

    -- Source: IMPORTERS.POST-QUERY (suspension status, Ministry status text, Designer FK lookups)
    -- APEX  : Process "POST-QUERY" (Before Header, after "Initialize form IMPORTERS"; P1130_ROW_ID not null).
    --         The read-only part of POST-QUERY / WHEN-NEW-RECORD-INSTANCE is in READ_ONLY_FLAGS.
    PROCEDURE POST_QUERY (P_PORT_CD            IN     importers.port_cd%TYPE,
                          P_IMPR_NBR           IN     importers.impr_nbr%TYPE,
                          P_BUS_ID_STATUS      IN     importers.bus_id_status%TYPE,
                          P_IMPR_TYPE_CD       IN     importers.impr_type_cd%TYPE,
                          P_BUS_ID_TYPE_CD     IN     importers.bus_id_type_cd%TYPE,
                          P_CTRY_CD            IN     importers.ctry_cd%TYPE,
                          P_CITY_CODE_OF_ID    IN     importers.city_code_of_id%TYPE,
                          P_CTRY_CD_OF_ID      IN     importers.ctry_cd_of_id%TYPE,
                          P_ADD_CTRY_CD        IN     importers.add_ctry_cd%TYPE,
                          P_CITY_CODE          IN     importers.city_code%TYPE,
                          P_SUSPN_STATUS       OUT    VARCHAR2,
                          P_STATUS_DESC        OUT    VARCHAR2,
                          P_PORT_NAME          OUT    VARCHAR2,
                          P_IMPR_TYPE_NAME     OUT    VARCHAR2,
                          P_BUS_ID_TYPE_NAME   OUT    VARCHAR2,
                          P_CRTY_ARBC_NAME     OUT    VARCHAR2,
                          P_ID_CITY_NAME       OUT    VARCHAR2,
                          P_ID_MINS_COMM_CD    OUT    NUMBER,
                          P_ADD_CRTY_ARBC_NAME OUT    VARCHAR2,
                          P_CITY_NAME          OUT    VARCHAR2);

    -- =========================================================================
    -- BLOCK IMPORTERS - record
    -- =========================================================================

    -- Source: IMPORTERS.WHEN-CREATE-RECORD (the Make_Field_Entrable calls are rules in READ_ONLY_FLAGS)
    -- APEX  : Process "WHEN-CREATE-RECORD" (Before Header, P1130_ROW_ID is null)
    PROCEDURE WHEN_CREATE_RECORD (P_PRSNL_IMPR     IN     NUMBER,
                                  P_PORT_CD        OUT    importers.port_cd%TYPE,
                                  P_PORT_NAME      OUT    VARCHAR2,
                                  P_IMPR_TYPE_CD   IN OUT importers.impr_type_cd%TYPE,
                                  P_IMPR_TYPE_NAME IN OUT VARCHAR2,
                                  P_CURR_PORT_CD   IN     NUMBER);

    -- Source: IMPORTERS.PRE-RECORD (name of the parent importer; message 9-150 when it is not found)
    -- APEX  : Process "PRE-RECORD" (Before Header, after "POST-QUERY")
    PROCEDURE PRE_RECORD (P_IMPR_NBR_PARENT  IN     importers.impr_nbr_parent%TYPE,
                          P_IMPR_NAME_PARENT IN OUT VARCHAR2,
                          P_CURR_PORT_CD     IN     NUMBER);

    -- =========================================================================
    -- BLOCK IMPORTERS - items (Forms navigation order)
    -- =========================================================================

    -- ---------------------------------------------------------------- PORT_CD (always read-only: P_CURR_PORT_CD)
    -- Source: IMPORTERS.PORT_CD.WHEN-VALIDATE-ITEM (CGFK$CHK_IMPORTERS_IMP_SDP_FK)
    FUNCTION PORT_CD_VALIDATION (P_PORT_CD IN importers.port_cd%TYPE) RETURN VARCHAR2;
    -- APEX  : not needed while PORT_CD is read-only; kept for the LOV return of KEY-LISTVAL (port name)
    PROCEDURE PORT_CD_WHEN_VALIDATE_ITEM (P_PORT_CD   IN     importers.port_cd%TYPE,
                                          P_PORT_NAME IN OUT VARCHAR2);

    -- ---------------------------------------------------------------- IMPR_NBR
    -- Source: IMPORTERS.IMPR_NBR.WHEN-VALIDATE-ITEM (number of this port must exist; message 9-150)
    -- APEX  : DA "IMPR_NBR WHEN-VALIDATE-ITEM": FORMS_APX.CHECK_ERROR(...), then submit EXECUTE_QUERY
    FUNCTION IMPR_NBR_VALIDATION (P_ROW_ID   IN VARCHAR2,
                                  P_PORT_CD  IN importers.port_cd%TYPE,
                                  P_IMPR_NBR IN importers.impr_nbr%TYPE) RETURN VARCHAR2;
    -- Item property UpdateAllowed = false: read-only on a saved record
    FUNCTION IMPR_NBR_IS_READ_ONLY (P_ROW_ID IN VARCHAR2) RETURN BOOLEAN;

    -- ---------------------------------------------------------------- IMPR_TYPE_CD
    -- Source: IMPORTERS.IMPR_TYPE_CD.WHEN-VALIDATE-ITEM (+ the LOV return of KEY-LISTVAL)
    FUNCTION IMPR_TYPE_CD_VALIDATION (P_IMPR_TYPE_CD   IN importers.impr_type_cd%TYPE,
                                      P_BUS_ID_TYPE_CD IN importers.bus_id_type_cd%TYPE,
                                      P_CTRY_CD        IN importers.ctry_cd%TYPE,
                                      P_CURR_PORT_CD   IN NUMBER) RETURN VARCHAR2;
    -- APEX  : DA "IMPR_TYPE_CD WHEN-VALIDATE-ITEM" (Change): FOS, then READ_ONLY_FLAGS; when BUS_ID_TYPE_CD
    --         comes back empty the activity type has several identity types: Set Focus BUS_ID_TYPE_CD
    --         (Forms DO_KEY('LIST_VALUES')). The sequences KING_IMPR_SEQ / IMPORTERS_SEQ are read here only.
    PROCEDURE IMPR_TYPE_CD_VALIDATE_ITEM (P_IMPR_TYPE_CD       IN OUT importers.impr_type_cd%TYPE,
                                          P_IMPR_TYPE_NAME     IN OUT VARCHAR2,
                                          P_BUS_ID_TYPE_CD     IN OUT importers.bus_id_type_cd%TYPE,
                                          P_BUS_ID_TYPE_NAME   IN OUT VARCHAR2,
                                          P_BUS_ID             IN OUT importers.bus_id%TYPE,
                                          P_CTRY_CD            IN OUT importers.ctry_cd%TYPE,
                                          P_CRTY_ARBC_NAME     IN OUT VARCHAR2,
                                          P_ADD_CTRY_CD        IN OUT importers.add_ctry_cd%TYPE,
                                          P_ADD_CRTY_ARBC_NAME IN OUT VARCHAR2,
                                          P_CURR_PORT_CD       IN     NUMBER);
    FUNCTION IMPR_TYPE_CD_IS_READ_ONLY (P_ROW_ID     IN VARCHAR2,
                                        P_PRSNL_IMPR IN NUMBER) RETURN BOOLEAN;

    -- ---------------------------------------------------------------- BUS_ID_EXPRD_DT
    -- Source: IMPORTERS.BUS_ID_EXPRD_DT.WHEN-VALIDATE-ITEM (HIJDATE.VALID_HIJ_DATE)
    -- APEX  : DA (FORMS_APX.CHECK_ERROR) and validation
    FUNCTION BUS_ID_EXPRD_DT_VALIDATION (P_BUS_ID_EXPRD_DT IN VARCHAR2) RETURN VARCHAR2;
    FUNCTION BUS_ID_EXPRD_DT_IS_READ_ONLY (P_ROW_ID            IN VARCHAR2,
                                           P_IMPR_TYPE_CD      IN NUMBER,
                                           P_BUS_ID_TYPE_CD    IN NUMBER,
                                           P_COMM_RGSTRTN_TYPE IN NUMBER,
                                           P_BUS_ID            IN VARCHAR2,
                                           P_BUS_ID_BRNCH      IN VARCHAR2,
                                           P_BUS_ID_EXPRD_DT   IN VARCHAR2,
                                           G_ALLOW_MCI         IN VARCHAR2) RETURN BOOLEAN;

    -- ---------------------------------------------------------------- BUS_ID_TYPE_CD
    -- Source: IMPORTERS.BUS_ID_TYPE_CD.WHEN-VALIDATE-ITEM (message 9-170)
    FUNCTION BUS_ID_TYPE_CD_VALIDATION (P_IMPR_TYPE_CD   IN importers.impr_type_cd%TYPE,
                                        P_BUS_ID_TYPE_CD IN importers.bus_id_type_cd%TYPE,
                                        P_CTRY_CD        IN importers.ctry_cd%TYPE) RETURN VARCHAR2;
    -- Source: + IMPORTERS.BUS_ID_TYPE_CD.KEY-LISTVAL (LOV_Impr_Type returns the identity type name)
    -- APEX  : DA "BUS_ID_TYPE_CD WHEN-VALIDATE-ITEM" (Change): FOS, then READ_ONLY_FLAGS
    PROCEDURE BUS_ID_TYPE_CD_VALIDATE_ITEM (P_IMPR_TYPE_CD     IN     importers.impr_type_cd%TYPE,
                                            P_CTRY_CD          IN     importers.ctry_cd%TYPE,
                                            P_BUS_ID_TYPE_CD   IN     importers.bus_id_type_cd%TYPE,
                                            P_BUS_ID_TYPE_NAME IN OUT VARCHAR2);
    -- Display-only item (OLB CGSO$CHAR_ARB_DO) chosen through its LOV: editable on a new record only
    FUNCTION BUS_ID_TYPE_CD_IS_READ_ONLY (P_ROW_ID IN VARCHAR2) RETURN BOOLEAN;

    -- ---------------------------------------------------------------- COMM_RGSTRTN_TYPE
    -- Source: IMPORTERS.COMM_RGSTRTN_TYPE.WHEN-LIST-CHANGED (1 = main register: no branch)
    -- APEX  : DA "COMM_RGSTRTN_TYPE WHEN-LIST-CHANGED" (Change): FOS, then READ_ONLY_FLAGS
    PROCEDURE COMM_RGSTRTN_TYPE_LIST_CHANGED (P_COMM_RGSTRTN_TYPE IN     importers.comm_rgstrtn_type%TYPE,
                                              P_BUS_ID_BRNCH      IN OUT importers.bus_id_brnch%TYPE);
    FUNCTION COMM_RGSTRTN_TYPE_IS_READ_ONLY (P_ROW_ID         IN VARCHAR2,
                                             P_IMPR_TYPE_CD   IN NUMBER,
                                             P_BUS_ID_TYPE_CD IN NUMBER) RETURN BOOLEAN;
    -- APEX  : Validation "COMM_RGSTRTN_TYPE REQUIRED" (FORMS_APX.REQUIRED_VALIDATION), condition this function
    FUNCTION COMM_RGSTRTN_TYPE_IS_REQUIRED (P_ROW_ID         IN VARCHAR2,
                                            P_BUS_ID_TYPE_CD IN NUMBER) RETURN BOOLEAN;

    -- ---------------------------------------------------------------- CTRY_CD
    -- Source: IMPORTERS.CTRY_CD.WHEN-VALIDATE-ITEM (Gulf country for type 12, CGFK$CHK_IMPORTERS_IMP_CTRY_FK)
    FUNCTION CTRY_CD_VALIDATION (P_IMPR_TYPE_CD IN importers.impr_type_cd%TYPE,
                                 P_CTRY_CD      IN importers.ctry_cd%TYPE) RETURN VARCHAR2;
    -- Source: + KEY-LISTVAL (CALL_LOV_COUNTRIES / CALL_LOV_COUN_GULF return the country name)
    PROCEDURE CTRY_CD_WHEN_VALIDATE_ITEM (P_IMPR_TYPE_CD   IN     importers.impr_type_cd%TYPE,
                                          P_CTRY_CD        IN     importers.ctry_cd%TYPE,
                                          P_CRTY_ARBC_NAME IN OUT VARCHAR2);
    FUNCTION CTRY_CD_IS_READ_ONLY (P_ROW_ID         IN VARCHAR2,
                                   P_IMPR_TYPE_CD   IN NUMBER,
                                   P_BUS_ID_TYPE_CD IN NUMBER) RETURN BOOLEAN;

    -- ---------------------------------------------------------------- CITY_CODE_OF_ID
    -- Source: IMPORTERS.CITY_CODE_OF_ID.WHEN-VALIDATE-ITEM, question of message 9-120 (STR.DispAlert CONFIRM:
    --         "use the full identification number?"). NULL = no question.
    -- APEX  : first FOS action of DA "CITY_CODE_OF_ID WHEN-VALIDATE-ITEM": returns P1130_CONFIRM_TEXT; native
    --         Confirm when it is not null, the answer goes to P1130_ANSWER (1 yes / 2 no)
    FUNCTION CITY_CODE_OF_ID_CONFIRM_TEXT (P_IMPR_TYPE_CD    IN importers.impr_type_cd%TYPE,
                                           P_CTRY_CD         IN importers.ctry_cd%TYPE,
                                           P_BUS_ID_TYPE_CD  IN importers.bus_id_type_cd%TYPE,
                                           P_BUS_ID          IN importers.bus_id%TYPE,
                                           P_CITY_CODE_OF_ID IN importers.city_code_of_id%TYPE,
                                           P_CTRY_CD_OF_ID   IN importers.ctry_cd_of_id%TYPE) RETURN VARCHAR2;
    FUNCTION CITY_CODE_OF_ID_VALIDATION (P_ROW_ID          IN VARCHAR2,
                                         P_IMPR_TYPE_CD    IN importers.impr_type_cd%TYPE,
                                         P_CTRY_CD         IN importers.ctry_cd%TYPE,
                                         P_CITY_CODE_OF_ID IN importers.city_code_of_id%TYPE,
                                         P_CTRY_CD_OF_ID   IN importers.ctry_cd_of_id%TYPE) RETURN VARCHAR2;
    -- Source: + IMPORTERS.CITY_CODE_OF_ID.WHEN-NEW-ITEM-INSTANCE (CTRY_CD_OF_ID default), KEY-LISTVAL (city name),
    --         IMPORTERS.CTRY_CD_OF_ID.WHEN-VALIDATE-ITEM (CGSF$CLRLU_IMPORTERS_IMP_BUS_I)
    -- APEX  : second FOS action of the DA (after the Confirm), then READ_ONLY_FLAGS
    PROCEDURE CITY_CODE_OF_ID_VALIDATE_ITEM (P_ROW_ID          IN     VARCHAR2,
                                             P_IMPR_TYPE_CD    IN     importers.impr_type_cd%TYPE,
                                             P_CTRY_CD         IN     importers.ctry_cd%TYPE,
                                             P_BUS_ID_TYPE_CD  IN     importers.bus_id_type_cd%TYPE,
                                             P_ANSWER          IN     NUMBER,
                                             P_CITY_CODE_OF_ID IN     importers.city_code_of_id%TYPE,
                                             P_CTRY_CD_OF_ID   IN OUT importers.ctry_cd_of_id%TYPE,
                                             P_BUS_ID          IN OUT importers.bus_id%TYPE,
                                             P_ID_MINS_COMM_CD IN OUT NUMBER,
                                             P_ID_CITY_NAME    IN OUT VARCHAR2);
    FUNCTION CITY_CODE_OF_ID_IS_READ_ONLY (P_ROW_ID         IN VARCHAR2,
                                           P_IMPR_TYPE_CD   IN NUMBER,
                                           P_BUS_ID_TYPE_CD IN NUMBER) RETURN BOOLEAN;

    -- ---------------------------------------------------------------- NATIONAL_NBR
    -- Source: IMPORTERS.NATIONAL_NBR.WHEN-VALIDATE-ITEM (must start with 7)
    FUNCTION NATIONAL_NBR_VALIDATION (P_NATIONAL_NBR IN importers.national_nbr%TYPE) RETURN VARCHAR2;
    -- Source: + GET_MAIN_CR_DATA / GET_BRANCH_CR_DATA / GET_CR_DATA (Ministry of Commerce web service, new
    --         record, activity types 1, 3, 5, 6, 19, identity type 2, ALLOW_MCI = 1)
    -- APEX  : DA "NATIONAL_NBR WHEN-VALIDATE-ITEM" (Change): FOS (Items to Return = all IN OUT items), then
    --         READ_ONLY_FLAGS (CREATION_FLAG 3 locks BUS_ID / BUS_ID_BRNCH)
    PROCEDURE NATIONAL_NBR_VALIDATE_ITEM (P_ROW_ID            IN     VARCHAR2,
                                          P_IMPR_TYPE_CD      IN     importers.impr_type_cd%TYPE,
                                          P_BUS_ID_TYPE_CD    IN     importers.bus_id_type_cd%TYPE,
                                          P_COMM_RGSTRTN_TYPE IN     importers.comm_rgstrtn_type%TYPE,
                                          P_NATIONAL_NBR      IN     importers.national_nbr%TYPE,
                                          P_BUS_ID            IN OUT importers.bus_id%TYPE,
                                          P_BUS_ID_BRNCH      IN OUT importers.bus_id_brnch%TYPE,
                                          P_BUS_ID_EXPRD_DT   IN OUT VARCHAR2,
                                          P_BUS_ID_ISSUE_DT   IN OUT VARCHAR2,
                                          P_ARBC_IMPR_NAME    IN OUT importers.arbc_impr_name%TYPE,
                                          P_IMPR_NAME_STD     IN OUT importers.impr_name_std%TYPE,
                                          P_IMPR_ADDRESS      IN OUT importers.impr_address%TYPE,
                                          P_IMPR_TEL_NBR      IN OUT importers.impr_tel_nbr%TYPE,
                                          P_IMPR_FAX_NBR      IN OUT importers.impr_fax_nbr%TYPE,
                                          P_IMPR_TELEX_NBR    IN OUT importers.impr_telex_nbr%TYPE,
                                          P_ACTIVITY          IN OUT importers.activity%TYPE,
                                          P_BUS_ID_STATUS     IN OUT importers.bus_id_status%TYPE,
                                          P_CITY_CODE_OF_ID   IN OUT importers.city_code_of_id%TYPE,
                                          P_LST_TRAN_DT       IN OUT VARCHAR2,
                                          P_CREATION_FLAG     IN OUT importers.creation_flag%TYPE,
                                          G_ALLOW_MCI         IN     VARCHAR2);

    -- ---------------------------------------------------------------- BUS_ID
    -- Source: IMPORTERS.BUS_ID.WHEN-VALIDATE-ITEM
    FUNCTION BUS_ID_VALIDATION (P_PORT_CD           IN importers.port_cd%TYPE,
                                P_IMPR_NBR          IN importers.impr_nbr%TYPE,
                                P_IMPR_TYPE_CD      IN importers.impr_type_cd%TYPE,
                                P_BUS_ID_TYPE_CD    IN importers.bus_id_type_cd%TYPE,
                                P_COMM_RGSTRTN_TYPE IN importers.comm_rgstrtn_type%TYPE,
                                P_CITY_CODE_OF_ID   IN importers.city_code_of_id%TYPE,
                                P_CTRY_CD_OF_ID     IN importers.ctry_cd_of_id%TYPE,
                                P_BUS_ID            IN importers.bus_id%TYPE,
                                P_BUS_ID_BRNCH      IN importers.bus_id_brnch%TYPE,
                                P_ID_MINS_COMM_CD   IN NUMBER,
                                P_CURR_PORT_CD      IN NUMBER) RETURN VARCHAR2;
    -- APEX  : DA "BUS_ID WHEN-VALIDATE-ITEM" (Change): FOS, then READ_ONLY_FLAGS. Message 9-120 is shown as
    --         information and the full number is taken (Forms ERROR alert with one button)
    PROCEDURE BUS_ID_WHEN_VALIDATE_ITEM (P_PORT_CD           IN     importers.port_cd%TYPE,
                                         P_IMPR_NBR          IN     importers.impr_nbr%TYPE,
                                         P_IMPR_TYPE_CD      IN     importers.impr_type_cd%TYPE,
                                         P_BUS_ID_TYPE_CD    IN     importers.bus_id_type_cd%TYPE,
                                         P_COMM_RGSTRTN_TYPE IN     importers.comm_rgstrtn_type%TYPE,
                                         P_CITY_CODE_OF_ID   IN     importers.city_code_of_id%TYPE,
                                         P_CTRY_CD_OF_ID     IN     importers.ctry_cd_of_id%TYPE,
                                         P_BUS_ID_BRNCH      IN     importers.bus_id_brnch%TYPE,
                                         P_BUS_ID            IN OUT importers.bus_id%TYPE,
                                         P_ID_MINS_COMM_CD   IN OUT NUMBER,
                                         P_ARBC_IMPR_NAME    IN OUT importers.arbc_impr_name%TYPE,
                                         P_IMPR_NAME_STD     IN OUT importers.impr_name_std%TYPE,
                                         P_BUS_ID_EXPRD_DT   IN OUT VARCHAR2,
                                         P_IMPR_TEL_NBR      IN OUT importers.impr_tel_nbr%TYPE,
                                         P_IMPR_POB_NBR      IN OUT importers.impr_pob_nbr%TYPE,
                                         P_IMPR_ZIP_CD       IN OUT importers.impr_zip_cd%TYPE,
                                         P_IMPR_FAX_NBR      IN OUT importers.impr_fax_nbr%TYPE,
                                         P_IMPR_TELEX_NBR    IN OUT importers.impr_telex_nbr%TYPE,
                                         P_CURR_PORT_CD      IN     NUMBER);
    FUNCTION BUS_ID_IS_READ_ONLY (P_ROW_ID         IN VARCHAR2,
                                  P_IMPR_TYPE_CD   IN NUMBER,
                                  P_BUS_ID_TYPE_CD IN NUMBER,
                                  P_CREATION_FLAG  IN NUMBER) RETURN BOOLEAN;

    -- ---------------------------------------------------------------- BUS_ID_BRNCH
    -- Source: IMPORTERS.BUS_ID_BRNCH.WHEN-VALIDATE-ITEM (+ KEY-NEXT-ITEM: CHK_IMPR_DUPL on a new record)
    FUNCTION BUS_ID_BRNCH_VALIDATION (P_PORT_CD           IN importers.port_cd%TYPE,
                                      P_IMPR_NBR          IN importers.impr_nbr%TYPE,
                                      P_IMPR_TYPE_CD      IN importers.impr_type_cd%TYPE,
                                      P_BUS_ID_TYPE_CD    IN importers.bus_id_type_cd%TYPE,
                                      P_COMM_RGSTRTN_TYPE IN importers.comm_rgstrtn_type%TYPE,
                                      P_CTRY_CD           IN importers.ctry_cd%TYPE,
                                      P_BUS_ID            IN importers.bus_id%TYPE,
                                      P_BUS_ID_BRNCH      IN importers.bus_id_brnch%TYPE) RETURN VARCHAR2;
    -- APEX  : DA "BUS_ID_BRNCH WHEN-VALIDATE-ITEM" (Change): FOS, then READ_ONLY_FLAGS
    PROCEDURE BUS_ID_BRNCH_VALIDATE_ITEM (P_PORT_CD           IN     importers.port_cd%TYPE,
                                          P_IMPR_NBR          IN     importers.impr_nbr%TYPE,
                                          P_IMPR_TYPE_CD      IN     importers.impr_type_cd%TYPE,
                                          P_BUS_ID_TYPE_CD    IN     importers.bus_id_type_cd%TYPE,
                                          P_COMM_RGSTRTN_TYPE IN     importers.comm_rgstrtn_type%TYPE,
                                          P_CTRY_CD           IN     importers.ctry_cd%TYPE,
                                          P_BUS_ID            IN     importers.bus_id%TYPE,
                                          P_BUS_ID_BRNCH      IN OUT importers.bus_id_brnch%TYPE,
                                          P_ARBC_IMPR_NAME    IN OUT importers.arbc_impr_name%TYPE,
                                          P_IMPR_NAME_STD     IN OUT importers.impr_name_std%TYPE,
                                          P_BUS_ID_EXPRD_DT   IN OUT VARCHAR2,
                                          P_IMPR_TEL_NBR      IN OUT importers.impr_tel_nbr%TYPE,
                                          P_IMPR_POB_NBR      IN OUT importers.impr_pob_nbr%TYPE,
                                          P_IMPR_ZIP_CD       IN OUT importers.impr_zip_cd%TYPE,
                                          P_IMPR_FAX_NBR      IN OUT importers.impr_fax_nbr%TYPE,
                                          P_IMPR_TELEX_NBR    IN OUT importers.impr_telex_nbr%TYPE);
    FUNCTION BUS_ID_BRNCH_IS_READ_ONLY (P_ROW_ID            IN VARCHAR2,
                                        P_PRSNL_IMPR        IN NUMBER,
                                        P_IMPR_TYPE_CD      IN NUMBER,
                                        P_BUS_ID_TYPE_CD    IN NUMBER,
                                        P_COMM_RGSTRTN_TYPE IN NUMBER,
                                        P_CREATION_FLAG     IN NUMBER) RETURN BOOLEAN;

    -- ---------------------------------------------------------------- ARBC_IMPR_NAME / ENG_IMPR_NAME
    -- Source: IMPORTERS.WHEN-NEW-RECORD-INSTANCE (names locked once the importer has declarations)
    FUNCTION ARBC_IMPR_NAME_IS_READ_ONLY (P_ROW_ID       IN VARCHAR2,
                                          P_IMPR_NBR     IN NUMBER,
                                          P_CURR_PORT_CD IN NUMBER) RETURN BOOLEAN;
    -- Source: IMPORTERS.ENG_IMPR_NAME.WHEN-VALIDATE-ITEM (STR_DB.RemoveRepeat, English letters only)
    FUNCTION ENG_IMPR_NAME_VALIDATION (P_ENG_IMPR_NAME IN importers.eng_impr_name%TYPE) RETURN VARCHAR2;
    -- APEX  : DA "ENG_IMPR_NAME WHEN-VALIDATE-ITEM" (Change): FOS, Items to Return = P1130_ENG_IMPR_NAME
    PROCEDURE ENG_IMPR_NAME_VALIDATE_ITEM (P_ENG_IMPR_NAME IN OUT importers.eng_impr_name%TYPE);
    FUNCTION ENG_IMPR_NAME_IS_READ_ONLY (P_ROW_ID       IN VARCHAR2,
                                         P_IMPR_NBR     IN NUMBER,
                                         P_CURR_PORT_CD IN NUMBER) RETURN BOOLEAN;

    -- ---------------------------------------------------------------- BUS_ID_ISSUE_DT
    -- Source: IMPORTERS.BUS_ID_ISSUE_DT.WHEN-VALIDATE-ITEM (HIJDATE.VALID_HIJ_DATE; KEY-LISTVAL / KEY-F4 =
    --         calendar -> date picker of the item)
    FUNCTION BUS_ID_ISSUE_DT_VALIDATION (P_BUS_ID_ISSUE_DT IN VARCHAR2) RETURN VARCHAR2;

    -- ---------------------------------------------------------------- IMPR_NBR_PARENT
    -- Source: IMPORTERS.IMPR_NBR_PARENT.WHEN-VALIDATE-ITEM (+ KEY-LISTVAL LOV_IMPR); message 9-160 when not found
    -- APEX  : DA "IMPR_NBR_PARENT WHEN-VALIDATE-ITEM" (Change): FOS, Items to Return = P1130_IMPR_NAME_PARENT
    PROCEDURE IMPR_NBR_PARENT_VALIDATE_ITEM (P_IMPR_NBR_PARENT  IN     importers.impr_nbr_parent%TYPE,
                                             P_IMPR_NAME_PARENT IN OUT VARCHAR2,
                                             P_CURR_PORT_CD     IN     NUMBER);

    -- ---------------------------------------------------------------- ADD_CTRY_CD
    -- Source: IMPORTERS.ADD_CTRY_CD.WHEN-VALIDATE-ITEM (CGFK$CHK_IMPORTERS_IMP_ADD_CIT, warning only)
    --         + KEY-LISTVAL (LOV_COUNTRIES returns the country name)
    -- APEX  : DA "ADD_CTRY_CD WHEN-VALIDATE-ITEM" (Change): FOS
    PROCEDURE ADD_CTRY_CD_WHEN_VALIDATE_ITEM (P_ADD_CTRY_CD        IN     importers.add_ctry_cd%TYPE,
                                              P_CITY_CODE          IN     importers.city_code%TYPE,
                                              P_ADD_CRTY_ARBC_NAME IN OUT VARCHAR2,
                                              P_CITY_NAME          IN OUT VARCHAR2);
    FUNCTION ADD_CTRY_CD_IS_READ_ONLY (P_ROW_ID         IN VARCHAR2,
                                       P_IMPR_TYPE_CD   IN NUMBER,
                                       P_BUS_ID_TYPE_CD IN NUMBER) RETURN BOOLEAN;

    -- ---------------------------------------------------------------- CITY_CODE
    -- Source: IMPORTERS.CITY_CODE.WHEN-VALIDATE-ITEM (required; message 18-282; CGFK warning)
    FUNCTION CITY_CODE_VALIDATION (P_ADD_CTRY_CD IN importers.add_ctry_cd%TYPE,
                                   P_CITY_CODE   IN importers.city_code%TYPE) RETURN VARCHAR2;
    PROCEDURE CITY_CODE_WHEN_VALIDATE_ITEM (P_ADD_CTRY_CD        IN     importers.add_ctry_cd%TYPE,
                                            P_CITY_CODE          IN     importers.city_code%TYPE,
                                            P_CITY_NAME          IN OUT VARCHAR2,
                                            P_ADD_CRTY_ARBC_NAME IN OUT VARCHAR2);

    -- ---------------------------------------------------------------- IMPR_POB_NBR, IMPR_ZIP_CD, IMPR_FAX_NBR, IMPR_TELEX_NBR
    -- Source: IMPORTERS.IMPR_TYPE_CD.WHEN-VALIDATE-ITEM (Ministry of Commerce data, ALLOW_MCI = 1) and the
    --         register branch of BUS_ID / BUS_ID_BRNCH WHEN-VALIDATE-ITEM (COMM_TABLE_UNCHECK)
    FUNCTION REGISTER_ITEMS_IS_READ_ONLY (P_ROW_ID            IN VARCHAR2,
                                          P_IMPR_TYPE_CD      IN NUMBER,
                                          P_BUS_ID_TYPE_CD    IN NUMBER,
                                          P_COMM_RGSTRTN_TYPE IN NUMBER,
                                          P_BUS_ID            IN VARCHAR2,
                                          P_BUS_ID_BRNCH      IN VARCHAR2,
                                          G_ALLOW_MCI         IN VARCHAR2) RETURN BOOLEAN;

    -- ---------------------------------------------------------------- IMPR_TEL_NBR
    -- Source: IMPORTERS.IMPR_TEL_NBR.WHEN-VALIDATE-ITEM (required, 10 digits)
    FUNCTION IMPR_TEL_NBR_VALIDATION (P_IMPR_TEL_NBR IN importers.impr_tel_nbr%TYPE) RETURN VARCHAR2;

    -- ---------------------------------------------------------------- EMAIL
    -- Source: IMPORTERS.EMAIL.WHEN-VALIDATE-ITEM ('@' not first). Forms checks it only when the user leaves
    --         the item (:SYSTEM.TRIGGER_ITEM = :SYSTEM.CURSOR_ITEM): used by the DA only, no page validation.
    FUNCTION EMAIL_VALIDATION (P_EMAIL IN importers.email%TYPE) RETURN VARCHAR2;

    -- ---------------------------------------------------------------- MOBILE_NO
    -- Source: IMPORTERS.MOBILE_NO.WHEN-VALIDATE-ITEM (required, digits, 9 digits starting with 5)
    FUNCTION MOBILE_NO_VALIDATION (P_MOBILE_NO IN importers.mobile_no%TYPE) RETURN VARCHAR2;

    -- =========================================================================
    -- BLOCK IMPORTERS - DML
    -- =========================================================================

    -- Source: IMPORTERS.PRE-INSERT (required checks, CHK_IMPR_DUPL, journaling, activity log,
    --         LIB_USR.IMPR_CENTRAL.CREATE_UNI_IMPR_NEBRAS, CGFK$CLR_FK_ON_INS)
    -- APEX  : Process "PRE-INSERT" (request CREATE), before "Process form IMPORTERS"
    PROCEDURE PRE_INSERT (P_PORT_CD           IN     importers.port_cd%TYPE,
                          P_IMPR_NBR          IN     importers.impr_nbr%TYPE,
                          P_HQ_IMPR_NBR       IN OUT importers.hq_impr_nbr%TYPE,
                          P_IMPR_TYPE_CD      IN     importers.impr_type_cd%TYPE,
                          P_BUS_ID_EXPRD_DT   IN     VARCHAR2,
                          P_BUS_ID_TYPE_CD    IN     importers.bus_id_type_cd%TYPE,
                          P_COMM_RGSTRTN_TYPE IN     importers.comm_rgstrtn_type%TYPE,
                          P_CTRY_CD           IN     importers.ctry_cd%TYPE,
                          P_CITY_CODE_OF_ID   IN     importers.city_code_of_id%TYPE,
                          P_CTRY_CD_OF_ID     IN     importers.ctry_cd_of_id%TYPE,
                          P_IMPR_EXPR_TYPE    IN     importers.impr_expr_type%TYPE,
                          P_NATIONAL_NBR      IN     importers.national_nbr%TYPE,
                          P_BUS_ID            IN     importers.bus_id%TYPE,
                          P_BUS_ID_BRNCH      IN OUT importers.bus_id_brnch%TYPE,
                          P_ARBC_IMPR_NAME    IN     importers.arbc_impr_name%TYPE,
                          P_ENG_IMPR_NAME     IN     importers.eng_impr_name%TYPE,
                          P_IMPR_CNTCT_NAME   IN     importers.impr_cntct_name%TYPE,
                          P_IMPR_ADDRESS      IN     importers.impr_address%TYPE,
                          P_BUS_ID_ISSUE_DT   IN     VARCHAR2,
                          P_IMPR_NBR_PARENT   IN     importers.impr_nbr_parent%TYPE,
                          P_ADD_CTRY_CD       IN     importers.add_ctry_cd%TYPE,
                          P_CITY_CODE         IN     importers.city_code%TYPE,
                          P_IMPR_POB_NBR      IN     importers.impr_pob_nbr%TYPE,
                          P_IMPR_ZIP_CD       IN     importers.impr_zip_cd%TYPE,
                          P_IMPR_TEL_NBR      IN     importers.impr_tel_nbr%TYPE,
                          P_IMPR_FAX_NBR      IN     importers.impr_fax_nbr%TYPE,
                          P_IMPR_TELEX_NBR    IN     importers.impr_telex_nbr%TYPE,
                          P_EMAIL             IN     importers.email%TYPE,
                          P_MOBILE_NO         IN     importers.mobile_no%TYPE,
                          P_CAR_AGENT_FLAG    IN     importers.car_agent_flag%TYPE,
                          P_EXPRESS_POST      IN     importers.express_post%TYPE,
                          P_ID_NBR            IN     importers.id_nbr%TYPE,
                          P_IMPD_STMT_NBR     IN     importers.impd_stmt_nbr%TYPE,
                          P_IMPR_DATA_SRCE    IN     importers.impr_data_srce%TYPE,
                          P_EXPD_STMT_NBR     IN     importers.expd_stmt_nbr%TYPE,
                          P_WVR_ENTRY_NBR     IN     importers.wvr_entry_nbr%TYPE,
                          P_ACTIVITY          IN     importers.activity%TYPE,
                          P_BANK_IBAN         IN     importers.bank_iban%TYPE,
                          P_ID_CITY_NAME      IN OUT VARCHAR2,
                          P_ID_MINS_COMM_CD   IN OUT NUMBER,
                          G_PORT_CD           IN     VARCHAR2,
                          G_SUPP_TITLE_CD     IN     VARCHAR2,
                          G_LETTER_NBR        IN     VARCHAR2,
                          G_LETTER_DT         IN     VARCHAR2,
                          P_CURR_PORT_CD      IN     NUMBER,
                          SSO_APP_USER        IN     VARCHAR2,
                          P_GLOBAL_V_WS_ID    IN     VARCHAR2);

    -- Source: IMPORTERS.POST-INSERT (INSERT_AUDIT_RECORD('I'), DB_JOURNAL.JOURNALING_OFF)
    -- APEX  : Process "POST-INSERT" (request CREATE), after "Process form IMPORTERS" (P1130_ROW_ID = the
    --         ROWID returned by the Form region). The audit row is written from the inserted row.
    PROCEDURE POST_INSERT (P_ROW_ID       IN     VARCHAR2,
                           P_IMPR_NBR     IN OUT importers.impr_nbr%TYPE,
                           SSO_APP_USER   IN     VARCHAR2);

    -- Source: IMPORTERS.PRE-UPDATE (IMPR_NAME_STD, INSERT_AUDIT_RECORD('U'), HQ_IMPR_NBR from HQ_IMPRS,
    --         activity log, trimmed names)
    -- APEX  : Process "PRE-UPDATE" (request SAVE, P1130_ROW_ID not null), before "Process form IMPORTERS"
    PROCEDURE PRE_UPDATE (P_PORT_CD           IN     importers.port_cd%TYPE,
                          P_IMPR_NBR          IN     importers.impr_nbr%TYPE,
                          P_HQ_IMPR_NBR       IN OUT importers.hq_impr_nbr%TYPE,
                          P_BUS_ID_STATUS     IN     importers.bus_id_status%TYPE,
                          P_IMPR_TYPE_CD      IN     importers.impr_type_cd%TYPE,
                          P_BUS_ID_EXPRD_DT   IN     VARCHAR2,
                          P_BUS_ID_TYPE_CD    IN     importers.bus_id_type_cd%TYPE,
                          P_COMM_RGSTRTN_TYPE IN     importers.comm_rgstrtn_type%TYPE,
                          P_CTRY_CD           IN     importers.ctry_cd%TYPE,
                          P_CITY_CODE_OF_ID   IN     importers.city_code_of_id%TYPE,
                          P_CTRY_CD_OF_ID     IN     importers.ctry_cd_of_id%TYPE,
                          P_IMPR_EXPR_TYPE    IN     importers.impr_expr_type%TYPE,
                          P_BUS_ID            IN     importers.bus_id%TYPE,
                          P_BUS_ID_BRNCH      IN     importers.bus_id_brnch%TYPE,
                          P_ARBC_IMPR_NAME    IN OUT importers.arbc_impr_name%TYPE,
                          P_IMPR_NAME_STD     IN OUT importers.impr_name_std%TYPE,
                          P_LST_TRAN_DT       IN     VARCHAR2,
                          P_IMPD_STMT_NBR     IN     importers.impd_stmt_nbr%TYPE,
                          P_IMPR_DATA_SRCE    IN     importers.impr_data_srce%TYPE,
                          P_ENG_IMPR_NAME     IN OUT importers.eng_impr_name%TYPE,
                          P_IMPR_CNTCT_NAME   IN OUT importers.impr_cntct_name%TYPE,
                          P_IMPR_ADDRESS      IN     importers.impr_address%TYPE,
                          P_BUS_ID_ISSUE_DT   IN     VARCHAR2,
                          P_IMPR_NBR_PARENT   IN     importers.impr_nbr_parent%TYPE,
                          P_ADD_CTRY_CD       IN     importers.add_ctry_cd%TYPE,
                          P_CITY_CODE         IN     importers.city_code%TYPE,
                          P_IMPR_POB_NBR      IN     importers.impr_pob_nbr%TYPE,
                          P_IMPR_ZIP_CD       IN     importers.impr_zip_cd%TYPE,
                          P_IMPR_TEL_NBR      IN     importers.impr_tel_nbr%TYPE,
                          P_IMPR_FAX_NBR      IN     importers.impr_fax_nbr%TYPE,
                          P_IMPR_TELEX_NBR    IN     importers.impr_telex_nbr%TYPE,
                          P_EMAIL             IN     importers.email%TYPE,
                          P_ID_NBR            IN     importers.id_nbr%TYPE,
                          P_CREATION_FLAG     IN     importers.creation_flag%TYPE,
                          P_CURR_PORT_CD      IN     NUMBER,
                          SSO_APP_USER        IN     VARCHAR2,
                          P_GLOBAL_V_WS_ID    IN     VARCHAR2);

    -- Source: IMPORTERS.KEY-DELREC (+ PRE-DELETE, PU CGRI$CHK_IMPORTERS); the question
    --         'هل أنت متأكد من عملية الحذف' is the confirm of the page 0 DELETE button
    -- APEX  : Process "KEY-DELREC" (request DELETE) instead of the native delete
    PROCEDURE KEY_DELREC (P_ROW_ID         IN VARCHAR2,
                          P_PORT_CD        IN importers.port_cd%TYPE,
                          P_IMPR_NBR       IN importers.impr_nbr%TYPE,
                          P_CURR_PORT_CD   IN NUMBER,
                          SSO_APP_USER     IN VARCHAR2,
                          P_GLOBAL_V_WS_ID IN VARCHAR2);

    -- =========================================================================
    -- FUNCTIONS (f345 Page Functions list in the page 0 FUNCS drawer)
    -- =========================================================================

    -- Source: PU ADJ_FUNS (TMPLT.ENABLE_FUN / DISABLE_FUN of IMPR_MCI_SERVICE)
    -- APEX  : Computation P1130_ADJ_FUNS: comma list of the functions this form switches that are enabled
    FUNCTION ADJ_FUNS (P_IMPR_TYPE_CD   IN importers.impr_type_cd%TYPE,
                       P_BUS_ID_TYPE_CD IN importers.bus_id_type_cd%TYPE,
                       G_ALLOW_MCI      IN VARCHAR2,
                       G_ALLOW_MOI      IN VARCHAR2) RETURN VARCHAR2;

    -- Source: PU UPDATE_IMPORTER, question STR.DispAlert(V_MSG, 'CONFIRM') ("... تأكيد التحديث؟")
    -- APEX  : first FOS action of the function IMPR_MCI_SERVICE: returns P1130_CONFIRM_TEXT; native Confirm
    --         when not null (NULL = no saved importer: no question, only the re-query)
    FUNCTION UPDATE_IMPORTER_CONFIRM_TEXT (P_PORT_CD        IN importers.port_cd%TYPE,
                                           P_IMPR_NBR       IN importers.impr_nbr%TYPE,
                                           P_IMPR_TYPE_CD   IN importers.impr_type_cd%TYPE,
                                           P_BUS_ID_TYPE_CD IN importers.bus_id_type_cd%TYPE,
                                           P_BUS_ID         IN importers.bus_id%TYPE,
                                           P_BUS_ID_BRNCH   IN importers.bus_id_brnch%TYPE) RETURN VARCHAR2;

    -- Source: PU EXEC_FUNS + PU UPDATE_IMPORTER (LIB_USR.IMPR_UTILITIES.UPDATE_IMPORTERS_NAMES)
    -- APEX  : second FOS action of the function (after the Confirm), then reload of the page with the same
    --         P0_PAGE_PK (Forms :GLOBAL.EXEC_QUERY_NOW -> EXECUTE_QUERY)
    PROCEDURE EXEC_FUNS (P_FUNCTION_CODE IN VARCHAR2,
                         P_PORT_CD       IN importers.port_cd%TYPE,
                         P_IMPR_NBR      IN importers.impr_nbr%TYPE,
                         P_ANSWER        IN NUMBER,
                         G_ALLOW_MCI     IN VARCHAR2,
                         G_ALLOW_MOI     IN VARCHAR2);

END IMPR1130;
/
SHOW ERRORS

-- -----------------------------------------------------------------------------
-- Synonym and grants (run as a user allowed to create public synonyms / grant on LIB_APX_USR).
-- CUSTOMS = parsing schema of the APEX application: APEX needs the direct grant.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PUBLIC SYNONYM IMPR1130 FOR LIB_APX_USR.IMPR1130;

GRANT EXECUTE ON LIB_APX_USR.IMPR1130 TO LIB_USR;

GRANT EXECUTE ON LIB_APX_USR.IMPR1130 TO SECURITY_DEFAULT;

GRANT EXECUTE ON LIB_APX_USR.IMPR1130 TO SECURITY_PROD;

GRANT EXECUTE ON LIB_APX_USR.IMPR1130 TO CUSTOMS;
