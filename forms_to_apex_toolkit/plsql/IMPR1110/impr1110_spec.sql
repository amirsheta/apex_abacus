-- =============================================================================
-- Package     : IMPR1110  (form IMPR1110.fmb "إضافة وتعديل بيانات مستورد")
-- Owner       : LIB_APX_USR (public synonym IMPR1110; EXECUTE granted to LIB_USR, SECURITY_DEFAULT, SECURITY_PROD, CUSTOMS)
-- Version     : 008 (23-11-2026: 006 = step 02 revision 2 + step 03 changes (DATE items as text, ROWID page key);
--               007 = parameter names by scripts/parameter_names.py; 008 = no doubled P_P_ (P_CODE => :P1110_P_CODE),
--               APP_P_PRSNL_IMPR / APP_P_LETTER_NBR in PARAMETERS_ENTRY. No logic change. 007: rollback/IMPR1110/step04_v007/)
-- Author      : Claude Code
-- Status      : NOT COMPILED.
-- Layout      : VERSION -> f345 HELPERS -> FORM LEVEL -> BLOCK IMPORTERS (query, record, items in Forms
--               navigation order with their read-only / required rules, DML) -> FUNCTIONS -> page 111002.
--               Every member here is called by APEX with named binds. Parameter names have no I_ / IO_ / O_
--               prefix (the mode is IN / IN OUT / OUT); a page item P<page>_X is passed as P_X
--               (P_BUS_ID => :P1110_BUS_ID, P_PAGE_PK => :P0_PAGE_PK, P_MOBILE_NO => :P111002_MOBILE_NO),
--               application items keep their name (P_CURR_PORT_CD => :P_CURR_PORT_CD). Inside SQL a parameter
--               is qualified with its member name. The converted Forms logic is private in the body.
-- Generated   : by work/step02/build_package.py (re-run after a change; do not edit by hand)
-- =============================================================================
SET DEFINE OFF

CREATE OR REPLACE PACKAGE LIB_APX_USR.IMPR1110 AS
   V_PKG_VERSION       VARCHAR2 (100) := 'VERSION NO. IS:' || '008';
   V_PKG_VERSION_QC    VARCHAR2 (100) := 'VERSION NO. IS:' || '001';
   V_PKG_VERSION_DEV   VARCHAR2 (100) := 'VERSION NO. IS:' || '001';
   FUNCTION PKG_VERSION
      RETURN VARCHAR2;
   V_PACKAGE_NAME      VARCHAR2 (50) := 'IMPR1110';
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

    c_yes CONSTANT PLS_INTEGER := 1;   -- confirm answers (ALERT_BUTTON1 / ALERT_BUTTON2)
    c_no  CONSTANT PLS_INTEGER := 2;

    -- =========================================================================
    -- f345 HELPERS
    -- =========================================================================

    -- Section: f345 HELPERS
    -- Read-only flags of the items whose rule can change while the page is open (after a change of
    -- IMPR_TYPE_CD, BUS_ID_TYPE_CD, COMM_RGSTRTN_TYPE, BUS_ID, BUS_ID_BRNCH, IMPR_TEL_NBR, ACTIVITY, or a
    -- function mode set by EXEC_FUNS). APEX renders a Read Only item as text, which native Enable cannot
    -- undo, so these items use flags instead of a Read Only condition.
    -- APEX  : Before Header process "READ ONLY FLAGS" and the last FOS action of the DAs above
    --         (Items to Return = P1110_<ITEM>_LOCKED, change events on); DA "<ITEM> READ ONLY" on change of
    --         P1110_<ITEM>_LOCKED: Disable when Y, else Enable (fire on initialization).
    PROCEDURE READ_ONLY_FLAGS (P_IMPR_NBR           IN  NUMBER,
                               P_CODE             IN  VARCHAR2,
                               P_PRSNL_IMPR       IN  NUMBER,
                               P_IMPR_TYPE_CD       IN  NUMBER,
                               P_BUS_ID_TYPE_CD     IN  NUMBER,
                               P_COMM_RGSTRTN_TYPE  IN  NUMBER,
                               P_BUS_ID             IN  VARCHAR2,
                               P_BUS_ID_BRNCH       IN  VARCHAR2,
                               P_BUS_ID_EXPRD_DT    IN  VARCHAR2,
                               P_IMPR_TEL_NBR       IN  VARCHAR2,
                               P_ACTIVITY           IN  VARCHAR2,
                               IMPR_TYPE_CD_LOCKED      OUT VARCHAR2,
                               BUS_ID_EXPRD_DT_LOCKED   OUT VARCHAR2,
                               COMM_RGSTRTN_TYPE_LOCKED OUT VARCHAR2,
                               CITY_CODE_OF_ID_LOCKED   OUT VARCHAR2,
                               BUS_ID_LOCKED            OUT VARCHAR2,
                               BRNH_CITY_CD_LOCKED      OUT VARCHAR2,
                               BUS_ID_BRNCH_LOCKED      OUT VARCHAR2,
                               CTRY_CD_LOCKED           OUT VARCHAR2,
                               ARBC_IMPR_NAME_LOCKED    OUT VARCHAR2,
                               REGISTER_ITEMS_LOCKED    OUT VARCHAR2,
                               IMPR_TEL_NBR_LOCKED      OUT VARCHAR2,
                               ACTIVITY_LOCKED          OUT VARCHAR2,
                               B_ID_NBR_LOCKED          OUT VARCHAR2,
                               CAR_AGENT_FLAG_LOCKED    OUT VARCHAR2);

    -- Section: f345 HELPERS
    -- f345 CHECK_ERROR: raise the text returned by a <ITEM>_VALIDATION function (used by the FOS DAs)
    PROCEDURE CHECK_ERROR (ERROR_TEXT IN VARCHAR2);

    -- Section: f345 HELPERS
    -- Validation "<ITEM> REQUIRED" (server-side condition <ITEM>_IS_REQUIRED): Forms FRM-40202
    FUNCTION REQUIRED_VALIDATION (ITEM_VALUE IN VARCHAR2, ITEM_LABEL IN VARCHAR2) RETURN VARCHAR2;

    -- Section: f345 HELPERS
    -- Process "P0_PAGE_PK CHECK" (Before Header): P0_PAGE_PK holds the ROWID of the importer (Forms key
    -- mode ROWID); forget a key that is not a row of IMPORTERS of this port (block WHERE clause)
    PROCEDURE P0_PAGE_PK_CHECK (P_PAGE_PK    IN OUT VARCHAR2,
                                P_CURR_PORT_CD IN     NUMBER);

    -- Section: f345 HELPERS
    -- Process "EXECUTE-QUERY" (request EXECUTE_QUERY): the ROWID of importer IMPR_NBR of this port, for
    -- P0_PAGE_PK. Source: IMPORTERS.IMPR_NBR.WHEN-VALIDATE-ITEM (existing number -> :GLOBAL.EXEC_QUERY_NOW
    -- -> IMPORTERS.WHEN-NEW-ITEM-INSTANCE EXECUTE_QUERY with PRE-QUERY on :GLOBAL.PORT_CD / IMPR_NBR)
    FUNCTION IMPORTER_ROW_ID (P_IMPR_NBR IN NUMBER,
                              P_CURR_PORT_CD IN NUMBER) RETURN VARCHAR2;

    -- Section: f345 HELPERS
    -- Computation P1110_MODULE_ID: SC_SYSTEM_OBJECTS id of the form (f345 Page Functions list)
    FUNCTION GET_MODULE_ID (P_MODULE_ID IN VARCHAR2) RETURN VARCHAR2;

    -- Section: f345 HELPERS
    -- Process "PARAMETERS ENTRY" (f345): one-shot hand-over of :PARAMETER.PRSNL_IMPR / LETTER_NBR
    PROCEDURE PARAMETERS_ENTRY (APP_P_PRSNL_IMPR       IN OUT VARCHAR2,
                                APP_P_LETTER_NBR       IN OUT VARCHAR2,
                                P_PRSNL_IMPR IN OUT VARCHAR2,
                                P_LETTER_NBR IN OUT VARCHAR2);

    -- Section: f345 HELPERS
    -- Process "HEADER TITLE": the form title from SC_SYSTEM_OBJECTS (Forms TITLE block)
    PROCEDURE HEADER_TITLE (P_MODULE_ID   IN     VARCHAR2,
                            P_HERO_TITLE IN OUT VARCHAR2);

    -- =========================================================================
    -- FORM LEVEL
    -- =========================================================================

    -- Source: IMPR1110.WHEN-NEW-FORM-INSTANCE (business part)
    -- APEX  : Process "WHEN-NEW-FORM-INSTANCE" (Before Header, first page view)
    PROCEDURE WHEN_NEW_FORM_INSTANCE (P_IMPR_TYPE_CD        IN     importers.impr_type_cd%TYPE,
                                      P_BUS_ID_TYPE_CD      IN     importers.bus_id_type_cd%TYPE,
                                      P_CTRY_CD            IN OUT importers.ctry_cd%TYPE,
                                      P_IMPR_EXPR_TYPE     IN OUT importers.impr_expr_type%TYPE,
                                      P_ADD_CTRY_CD        IN OUT importers.add_ctry_cd%TYPE,
                                      P_EXPRESS_POST       IN OUT importers.express_post%TYPE,
                                      P_CRTY_ARBC_NAME     IN OUT VARCHAR2,
                                      P_ADD_CRTY_ARBC_NAME IN OUT VARCHAR2,
                                      P_CURR_PORT_CD            IN     NUMBER,
                                      P_CLASS_CD                IN     NUMBER,
                                      V_USR_TYPE                IN     NUMBER,
                                      P_LETTER_NBR        IN     VARCHAR2);

    -- =========================================================================
    -- BLOCK IMPORTERS - query
    -- =========================================================================

    -- Source: IMPORTERS.POST-QUERY, after the POST-CHANGE triggers Forms fires for the fetched items
    -- APEX  : Process "POST-QUERY" (Before Header, after "Initialize form IMPORTERS"; :P0_PAGE_PK is not null)
    PROCEDURE POST_QUERY (P_PORT_CD             IN     importers.port_cd%TYPE,
                          P_HQ_IMPR_NBR         IN     importers.hq_impr_nbr%TYPE,
                          P_IMPR_NBR            IN     importers.impr_nbr%TYPE,
                          P_BUS_ID_STATUS       IN     importers.bus_id_status%TYPE,
                          P_IMPR_TYPE_CD        IN     importers.impr_type_cd%TYPE,
                          P_BUS_ID_TYPE_CD      IN     importers.bus_id_type_cd%TYPE,
                          P_CITY_CODE_OF_ID     IN     importers.city_code_of_id%TYPE,
                          P_BUS_ID              IN     importers.bus_id%TYPE,
                          P_BUS_ID_BRNCH        IN     importers.bus_id_brnch%TYPE,
                          P_CTRY_CD            IN OUT importers.ctry_cd%TYPE,
                          P_ADD_CTRY_CD        IN OUT importers.add_ctry_cd%TYPE,
                          P_CITY_CODE           IN     importers.city_code%TYPE,
                          P_EMAIL               IN     importers.email%TYPE,
                          P_MOBILE_NO           IN     importers.mobile_no%TYPE,
                          P_ID_NBR              IN     importers.id_nbr%TYPE,
                          P_CTRY_CD_OF_ID       IN     importers.ctry_cd_of_id%TYPE,
                          P_PORT_NAME          IN OUT VARCHAR2,
                          P_SDP_PORT_STATUS    IN OUT NUMBER,
                          P_SUSPN_STATUS       IN OUT VARCHAR2,
                          P_STATUS_DESC        IN OUT VARCHAR2,
                          P_IMPR_TYPE_NAME     IN OUT VARCHAR2,
                          P_BUS_ID_TYPE_NAME   IN OUT VARCHAR2,
                          P_ID_CITY_NAME       IN OUT VARCHAR2,
                          P_ID_MINS_COMM_CD    IN OUT NUMBER,
                          P_L_CT_CITY_STATUS2  IN OUT NUMBER,
                          P_BRNH_CITY_CD       IN OUT NUMBER,
                          P_BRNH_CITY_NAME     IN OUT VARCHAR2,
                          P_CRTY_ARBC_NAME     IN OUT VARCHAR2,
                          P_CTRY_CTRY_STATUS   IN OUT NUMBER,
                          P_ITIDT_NOTE         IN OUT VARCHAR2,
                          P_STATUS             IN OUT NUMBER,
                          P_WASL_CITY_NAME     IN OUT VARCHAR2,
                          P_ADD_CRTY_ARBC_NAME IN OUT VARCHAR2,
                          P_CITY_NAME          IN OUT VARCHAR2,
                          P_L_CT_CITY_STATUS   IN OUT NUMBER,
                          P_B_EMAIL            IN OUT VARCHAR2,
                          P_B_MOBILE_NO        IN OUT VARCHAR2,
                          P_B_ID_NBR           IN OUT VARCHAR2,
                          P_IMPR_ID_TYPE       IN OUT VARCHAR2,
                          P_CURR_PORT_CD            IN     NUMBER,
                          SSO_APP_USER              IN     VARCHAR2,
                          P_CLASS_CD                IN     NUMBER,
                          V_USR_TYPE                IN     NUMBER);

    -- =========================================================================
    -- BLOCK IMPORTERS - record
    -- =========================================================================

    -- Source: IMPORTERS.WHEN-CREATE-RECORD
    -- APEX  : Process "WHEN-CREATE-RECORD" (Before Header, :P0_PAGE_PK is null)
    PROCEDURE WHEN_CREATE_RECORD (P_PORT_CD        IN OUT importers.port_cd%TYPE,
                                  P_IMPR_TYPE_CD   IN OUT importers.impr_type_cd%TYPE,
                                  P_PORT_NAME      IN OUT VARCHAR2,
                                  P_IMPR_TYPE_NAME IN OUT VARCHAR2,
                                  P_CURR_PORT_CD        IN     NUMBER,
                                  P_PRSNL_IMPR    IN     NUMBER);

    -- Source: IMPORTERS.PRE-RECORD + WHEN-NEW-RECORD-INSTANCE (function modes F1..F5, SF6; type-19 rule without COMMIT)
    -- APEX  : Process "WHEN-NEW-RECORD-INSTANCE" (Before Header, after POST-QUERY / WHEN-CREATE-RECORD); FOS after a function (Confirm with NEW_RECORD_CONFIRM_TEXT first)
    PROCEDURE WHEN_NEW_RECORD_INSTANCE (P_IMPR_NBR            IN     importers.impr_nbr%TYPE,
                                        P_IMPR_TYPE_CD       IN OUT importers.impr_type_cd%TYPE,
                                        P_BUS_ID_TYPE_CD      IN     importers.bus_id_type_cd%TYPE,
                                        P_COMM_RGSTRTN_TYPE   IN     importers.comm_rgstrtn_type%TYPE,
                                        P_BUS_ID              IN     importers.bus_id%TYPE,
                                        P_BUS_ID_BRNCH        IN     importers.bus_id_brnch%TYPE,
                                        P_CTRY_CD            IN OUT importers.ctry_cd%TYPE,
                                        P_ARBC_IMPR_NAME     IN OUT importers.arbc_impr_name%TYPE,
                                        P_IMPR_NBR_PARENT     IN     importers.impr_nbr_parent%TYPE,
                                        P_ADD_CTRY_CD        IN OUT importers.add_ctry_cd%TYPE,
                                        P_CRTY_ARBC_NAME     IN OUT VARCHAR2,
                                        P_IMPR_NAME_PARENT   IN OUT VARCHAR2,
                                        P_ADD_CRTY_ARBC_NAME IN OUT VARCHAR2,
                                        P_CURR_PORT_CD            IN     NUMBER,
                                        P_CLASS_CD                IN     NUMBER,
                                        V_USR_TYPE                IN     NUMBER,
                                        P_CODE              IN     VARCHAR2,
                                        P_ANSWER              IN     PLS_INTEGER DEFAULT NULL);

    -- Source: IMPORTERS.WHEN-NEW-RECORD-INSTANCE, question of IMPR1110F1 / IMPR1110F5 ("سيتم تعديل الإسم إلى ...")
    -- APEX  : FOS returns P1110_CONFIRM_TEXT; native Confirm when it is not null
    FUNCTION NEW_RECORD_CONFIRM_TEXT (P_IMPR_TYPE_CD      IN     importers.impr_type_cd%TYPE,
                                      P_BUS_ID_TYPE_CD    IN     importers.bus_id_type_cd%TYPE,
                                      P_COMM_RGSTRTN_TYPE IN     importers.comm_rgstrtn_type%TYPE,
                                      P_BUS_ID            IN     importers.bus_id%TYPE,
                                      P_BUS_ID_BRNCH      IN     importers.bus_id_brnch%TYPE,
                                      P_CODE            IN     VARCHAR2)
        RETURN VARCHAR2;

    -- Source: IMPORTERS.WHEN-CLEAR-BLOCK
    -- APEX  : Process "WHEN-CLEAR-BLOCK" (request CLEAR of the page 0 toolbar)
    PROCEDURE WHEN_CLEAR_BLOCK;

    -- =========================================================================
    -- ITEM PORT_CD
    -- =========================================================================

    -- Source: IMPORTERS.PORT_CD.WHEN-VALIDATE-ITEM
    -- APEX  : Validation "PORT_CD VALIDATION" (request CREATE / SAVE): returns the error text
    FUNCTION PORT_CD_VALIDATION (P_PORT_CD         IN     importers.port_cd%TYPE,
                                 P_PORT_NAME       IN     VARCHAR2,
                                 P_SDP_PORT_STATUS IN     NUMBER)
        RETURN VARCHAR2;

    -- Source: IMPORTERS.PORT_CD.WHEN-VALIDATE-ITEM
    -- APEX  : DA "PORT_CD WHEN-VALIDATE-ITEM" (Change): FOS, Items to Submit = the IN items, Items to Return = the IN OUT / OUT items
    PROCEDURE PORT_CD_WHEN_VALIDATE_ITEM (P_PORT_CD          IN     importers.port_cd%TYPE,
                                          P_PORT_NAME       IN OUT VARCHAR2,
                                          P_SDP_PORT_STATUS IN OUT NUMBER);

    -- =========================================================================
    -- ITEM HQ_IMPR_NBR
    -- =========================================================================

    -- Source: IMPORTERS.HQ_IMPR_NBR.POST-CHANGE
    -- APEX  : Validation "HQ_IMPR_NBR VALIDATION" (request CREATE / SAVE): returns the error text
    FUNCTION HQ_IMPR_NBR_VALIDATION
        RETURN VARCHAR2;

    -- Source: IMPORTERS.HQ_IMPR_NBR.POST-CHANGE
    -- APEX  : DA "HQ_IMPR_NBR WHEN-VALIDATE-ITEM" (Change): FOS, Items to Submit = the IN items, Items to Return = the IN OUT / OUT items
    PROCEDURE HQ_IMPR_NBR_WHEN_VALIDATE_ITEM;

    -- =========================================================================
    -- ITEM IMPR_NBR
    -- =========================================================================

    -- Source: IMPORTERS.IMPR_NBR.WHEN-VALIDATE-ITEM
    -- APEX  : Validation "IMPR_NBR VALIDATION" (request CREATE / SAVE): returns the error text
    FUNCTION IMPR_NBR_VALIDATION (P_PORT_CD  IN     importers.port_cd%TYPE,
                                  P_IMPR_NBR IN     importers.impr_nbr%TYPE)
        RETURN VARCHAR2;

    -- Source: IMPORTERS.IMPR_NBR.WHEN-VALIDATE-ITEM
    -- APEX  : DA "IMPR_NBR WHEN-VALIDATE-ITEM" (Change): FOS, Items to Submit = the IN items, Items to Return = the IN OUT / OUT items
    PROCEDURE IMPR_NBR_WHEN_VALIDATE_ITEM (P_PORT_CD  IN     importers.port_cd%TYPE,
                                           P_IMPR_NBR IN     importers.impr_nbr%TYPE);

    -- =========================================================================
    -- ITEM IMPR_TYPE_CD
    -- =========================================================================

    -- Source: IMPORTERS.IMPR_TYPE_CD.POST-CHANGE + WHEN-VALIDATE-ITEM
    -- APEX  : Validation "IMPR_TYPE_CD VALIDATION" (request CREATE / SAVE): returns the error text
    FUNCTION IMPR_TYPE_CD_VALIDATION (P_IMPR_NBR           IN     importers.impr_nbr%TYPE,
                                      P_IMPR_TYPE_CD       IN     importers.impr_type_cd%TYPE,
                                      P_BUS_ID_TYPE_CD     IN     importers.bus_id_type_cd%TYPE,
                                      P_BUS_ID             IN     importers.bus_id%TYPE,
                                      P_CTRY_CD            IN     importers.ctry_cd%TYPE,
                                      P_ADD_CTRY_CD        IN     importers.add_ctry_cd%TYPE,
                                      P_IMPR_TYPE_NAME     IN     VARCHAR2,
                                      P_BUS_ID_TYPE_NAME   IN     VARCHAR2,
                                      P_CRTY_ARBC_NAME     IN     VARCHAR2,
                                      P_ITIDT_NOTE         IN     VARCHAR2,
                                      P_STATUS             IN     NUMBER,
                                      P_ADD_CRTY_ARBC_NAME IN     VARCHAR2,
                                      P_CURR_PORT_CD           IN     NUMBER)
        RETURN VARCHAR2;

    -- Source: IMPORTERS.IMPR_TYPE_CD.POST-CHANGE + WHEN-VALIDATE-ITEM
    -- APEX  : DA "IMPR_TYPE_CD WHEN-VALIDATE-ITEM" (Change): FOS, Items to Submit = the IN items, Items to Return = the IN OUT / OUT items
    PROCEDURE IMPR_TYPE_CD_VALIDATE_ITEM (P_IMPR_NBR            IN     importers.impr_nbr%TYPE,
                                          P_IMPR_TYPE_CD       IN OUT importers.impr_type_cd%TYPE,
                                          P_BUS_ID_TYPE_CD     IN OUT importers.bus_id_type_cd%TYPE,
                                          P_BUS_ID             IN OUT importers.bus_id%TYPE,
                                          P_CTRY_CD            IN OUT importers.ctry_cd%TYPE,
                                          P_ADD_CTRY_CD        IN OUT importers.add_ctry_cd%TYPE,
                                          P_IMPR_TYPE_NAME     IN OUT VARCHAR2,
                                          P_BUS_ID_TYPE_NAME   IN OUT VARCHAR2,
                                          P_CRTY_ARBC_NAME     IN OUT VARCHAR2,
                                          P_ITIDT_NOTE         IN OUT VARCHAR2,
                                          P_STATUS             IN OUT NUMBER,
                                          P_ADD_CRTY_ARBC_NAME IN OUT VARCHAR2,
                                          P_CURR_PORT_CD            IN     NUMBER);

    -- Source: IMPORTERS.IMPR_TYPE_CD.WHEN-NEW-ITEM-INSTANCE
    -- APEX  : DA "IMPR_TYPE_CD WHEN-NEW-ITEM-INSTANCE": FOS, Items to Return = the IN OUT / OUT items
    PROCEDURE IMPR_TYPE_CD_NEW_ITEM_INSTANCE (P_IMPR_TYPE_CD        IN     importers.impr_type_cd%TYPE,
                                              P_BUS_ID_TYPE_CD      IN     importers.bus_id_type_cd%TYPE,
                                              P_CTRY_CD            IN OUT importers.ctry_cd%TYPE,
                                              P_ADD_CTRY_CD        IN OUT importers.add_ctry_cd%TYPE,
                                              P_CRTY_ARBC_NAME     IN OUT VARCHAR2,
                                              P_ADD_CRTY_ARBC_NAME IN OUT VARCHAR2);

    -- Source: IMPORTERS.IMPR_TYPE_CD.KEY-LISTVAL (values the LOV returns)
    -- APEX  : DA "IMPR_TYPE_CD KEY-LISTVAL": FOS, Items to Return = the IN OUT / OUT items
    PROCEDURE IMPR_TYPE_CD_LOV_RETURN (P_IMPR_TYPE_CD       IN OUT importers.impr_type_cd%TYPE,
                                       P_BUS_ID_TYPE_CD     IN OUT importers.bus_id_type_cd%TYPE,
                                       P_CTRY_CD            IN OUT importers.ctry_cd%TYPE,
                                       P_ADD_CTRY_CD        IN OUT importers.add_ctry_cd%TYPE,
                                       P_IMPR_TYPE_NAME     IN OUT VARCHAR2,
                                       P_BUS_ID_TYPE_NAME   IN OUT VARCHAR2,
                                       P_CRTY_ARBC_NAME     IN OUT VARCHAR2,
                                       P_ADD_CRTY_ARBC_NAME IN OUT VARCHAR2);

    -- Section: ITEM IMPR_TYPE_CD
    -- Source: WNRI (saved-record lock, unlocked by IMPR1110F3), WHEN-CREATE-RECORD (PRSNL_IMPR = 1)
    -- APEX  : Read Only condition of P1110_IMPR_TYPE_CD (PL/SQL expression)
    FUNCTION IMPR_TYPE_CD_IS_READ_ONLY (P_IMPR_NBR     IN NUMBER,
                                        P_CODE       IN VARCHAR2,
                                        P_PRSNL_IMPR IN NUMBER) RETURN BOOLEAN;

    -- =========================================================================
    -- ITEM BUS_ID_EXPRD_DT
    -- =========================================================================

    -- Source: IMPORTERS.BUS_ID_EXPRD_DT.WHEN-VALIDATE-ITEM
    -- APEX  : Validation "BUS_ID_EXPRD_DT VALIDATION" (request CREATE / SAVE): returns the error text
    FUNCTION BUS_ID_EXPRD_DT_VALIDATION (P_BUS_ID_EXPRD_DT IN     VARCHAR2)
        RETURN VARCHAR2;

    -- Source: IMPORTERS.BUS_ID_EXPRD_DT.WHEN-VALIDATE-ITEM
    -- APEX  : DA "BUS_ID_EXPRD_DT WHEN-VALIDATE-ITEM" (Change): FOS, Items to Submit = the IN items, Items to Return = the IN OUT / OUT items
    PROCEDURE BUS_ID_EXPRD_DT_VALIDATE_ITEM (P_BUS_ID_EXPRD_DT IN     VARCHAR2);

    -- Section: ITEM BUS_ID_EXPRD_DT
    -- Source: WNRI (lock, unlocked by IMPR1110F4), BUS_ID / BUS_ID_BRNCH WHEN-VALIDATE-ITEM (register),
    --         PRE-INSERT (re-enabled while empty: the item is required)
    FUNCTION BUS_ID_EXPRD_DT_IS_READ_ONLY (P_IMPR_NBR          IN NUMBER,
                                           P_CODE            IN VARCHAR2,
                                           P_IMPR_TYPE_CD      IN NUMBER,
                                           P_BUS_ID_TYPE_CD    IN NUMBER,
                                           P_BUS_ID            IN VARCHAR2,
                                           P_BUS_ID_BRNCH      IN VARCHAR2,
                                           P_COMM_RGSTRTN_TYPE IN NUMBER,
                                           P_BUS_ID_EXPRD_DT   IN VARCHAR2) RETURN BOOLEAN;

    -- Section: ITEM BUS_ID_EXPRD_DT
    -- Source: PRE-INSERT / PRE-UPDATE (required for BUS_ID_TYPE_CD = 2 and IMPR_TYPE_CD IN 1,3,5,6,8,12)
    FUNCTION BUS_ID_EXPRD_DT_IS_REQUIRED (P_IMPR_TYPE_CD   IN NUMBER,
                                          P_BUS_ID_TYPE_CD IN NUMBER) RETURN BOOLEAN;

    -- =========================================================================
    -- ITEM BUS_ID_TYPE_CD
    -- =========================================================================

    -- Source: IMPORTERS.BUS_ID_TYPE_CD.POST-CHANGE
    -- APEX  : Validation "BUS_ID_TYPE_CD VALIDATION" (request CREATE / SAVE): returns the error text
    FUNCTION BUS_ID_TYPE_CD_VALIDATION (P_IMPR_TYPE_CD       IN     importers.impr_type_cd%TYPE,
                                        P_BUS_ID_TYPE_CD     IN     importers.bus_id_type_cd%TYPE,
                                        P_CTRY_CD            IN     importers.ctry_cd%TYPE,
                                        P_ADD_CTRY_CD        IN     importers.add_ctry_cd%TYPE,
                                        P_CRTY_ARBC_NAME     IN     VARCHAR2,
                                        P_ADD_CRTY_ARBC_NAME IN     VARCHAR2)
        RETURN VARCHAR2;

    -- Source: IMPORTERS.BUS_ID_TYPE_CD.POST-CHANGE
    -- APEX  : DA "BUS_ID_TYPE_CD WHEN-VALIDATE-ITEM" (Change): FOS, Items to Submit = the IN items, Items to Return = the IN OUT / OUT items
    PROCEDURE BUS_ID_TYPE_CD_VALIDATE_ITEM (P_IMPR_TYPE_CD        IN     importers.impr_type_cd%TYPE,
                                            P_BUS_ID_TYPE_CD      IN     importers.bus_id_type_cd%TYPE,
                                            P_CTRY_CD            IN OUT importers.ctry_cd%TYPE,
                                            P_ADD_CTRY_CD        IN OUT importers.add_ctry_cd%TYPE,
                                            P_CRTY_ARBC_NAME     IN OUT VARCHAR2,
                                            P_ADD_CRTY_ARBC_NAME IN OUT VARCHAR2);

    -- Section: ITEM BUS_ID_TYPE_CD
    -- Source: WNRI (saved record: never unlocked)
    FUNCTION BUS_ID_TYPE_CD_IS_READ_ONLY (P_IMPR_NBR IN NUMBER) RETURN BOOLEAN;

    -- =========================================================================
    -- ITEM COMM_RGSTRTN_TYPE
    -- =========================================================================

    -- Source: IMPORTERS.COMM_RGSTRTN_TYPE.WHEN-LIST-CHANGED
    -- APEX  : DA "COMM_RGSTRTN_TYPE WHEN-LIST-CHANGED": FOS, Items to Return = the IN OUT / OUT items
    PROCEDURE COMM_RGSTRTN_TYPE_LIST_CHANGED (P_COMM_RGSTRTN_TYPE IN     importers.comm_rgstrtn_type%TYPE,
                                              P_BUS_ID_BRNCH     IN OUT importers.bus_id_brnch%TYPE);

    -- Section: ITEM COMM_RGSTRTN_TYPE
    -- Source: WNFI / WNRI (read-only by default), IMPR_TYPE_CD WHEN-VALIDATE-ITEM (editable for
    --         BUS_ID_TYPE_CD = 2 and IMPR_TYPE_CD <> 12), WNRI (saved record, unlocked by IMPR1110F2)
    FUNCTION COMM_RGSTRTN_TYPE_IS_READ_ONLY (P_IMPR_NBR       IN NUMBER,
                                             P_CODE         IN VARCHAR2,
                                             P_IMPR_TYPE_CD   IN NUMBER,
                                             P_BUS_ID_TYPE_CD IN NUMBER) RETURN BOOLEAN;

    -- Section: ITEM COMM_RGSTRTN_TYPE
    -- Source: IMPR_TYPE_CD WHEN-VALIDATE-ITEM (REQUIRED TRUE), PRE-INSERT / PRE-UPDATE error 9-240
    FUNCTION COMM_RGSTRTN_TYPE_IS_REQUIRED (P_IMPR_TYPE_CD   IN NUMBER,
                                            P_BUS_ID_TYPE_CD IN NUMBER) RETURN BOOLEAN;

    -- =========================================================================
    -- ITEM CITY_CODE_OF_ID
    -- =========================================================================

    -- Source: IMPORTERS.CITY_CODE_OF_ID.WHEN-VALIDATE-ITEM
    -- APEX  : Validation "CITY_CODE_OF_ID VALIDATION" (request CREATE / SAVE): returns the error text
    FUNCTION CITY_CODE_OF_ID_VALIDATION (P_CITY_CODE_OF_ID   IN     importers.city_code_of_id%TYPE,
                                         P_CTRY_CD_OF_ID     IN     importers.ctry_cd_of_id%TYPE,
                                         P_ID_CITY_NAME      IN     VARCHAR2,
                                         P_ID_MINS_COMM_CD   IN     NUMBER,
                                         P_L_CT_CITY_STATUS2 IN     NUMBER,
                                         P_ROW_ID            IN     VARCHAR2)
        RETURN VARCHAR2;

    -- Source: IMPORTERS.CITY_CODE_OF_ID.WHEN-VALIDATE-ITEM
    -- APEX  : DA "CITY_CODE_OF_ID WHEN-VALIDATE-ITEM" (Change): FOS, Items to Submit = the IN items, Items to Return = the IN OUT / OUT items
    PROCEDURE CITY_CODE_OF_ID_VALIDATE_ITEM (P_CITY_CODE_OF_ID   IN OUT importers.city_code_of_id%TYPE,
                                             P_CTRY_CD_OF_ID     IN OUT importers.ctry_cd_of_id%TYPE,
                                             P_ID_CITY_NAME      IN OUT VARCHAR2,
                                             P_ID_MINS_COMM_CD   IN OUT NUMBER,
                                             P_L_CT_CITY_STATUS2 IN OUT NUMBER,
                                             P_ROW_ID             IN     VARCHAR2);

    -- Source: IMPORTERS.CITY_CODE_OF_ID.WHEN-NEW-ITEM-INSTANCE
    -- APEX  : DA "CITY_CODE_OF_ID WHEN-NEW-ITEM-INSTANCE": FOS, Items to Return = the IN OUT / OUT items
    PROCEDURE CITY_CODE_OF_ID_WHEN_NEW_ITEM (P_COMM_RGSTRTN_TYPE IN     importers.comm_rgstrtn_type%TYPE);

    -- Section: ITEM CITY_CODE_OF_ID
    -- Source: importer type table (group 2), WNRI (lock, unlocked by IMPR1110F2).
    --         WHEN-CREATE-RECORD with PRSNL_IMPR = 1 sets IMPR_TYPE_CD = 4 -> covered by the type table.
    FUNCTION CITY_CODE_OF_ID_IS_READ_ONLY (P_IMPR_NBR       IN NUMBER,
                                           P_CODE         IN VARCHAR2,
                                           P_IMPR_TYPE_CD   IN NUMBER,
                                           P_BUS_ID_TYPE_CD IN NUMBER) RETURN BOOLEAN;

    -- Section: ITEM CITY_CODE_OF_ID
    -- Source: IMPR_TYPE_CD POST-CHANGE (REQUIRED TRUE for IMPR_TYPE_CD IN 1,3,5,6,8,19)
    FUNCTION CITY_CODE_OF_ID_IS_REQUIRED (P_IMPR_TYPE_CD IN NUMBER) RETURN BOOLEAN;

    -- =========================================================================
    -- ITEM BUS_ID
    -- =========================================================================

    -- Source: IMPORTERS.BUS_ID.POST-CHANGE + WHEN-VALIDATE-ITEM
    -- APEX  : Validation "BUS_ID VALIDATION" (request CREATE / SAVE): returns the error text
    FUNCTION BUS_ID_VALIDATION (P_PORT_CD           IN     importers.port_cd%TYPE,
                                P_IMPR_NBR          IN     importers.impr_nbr%TYPE,
                                P_BUS_ID_STATUS     IN     importers.bus_id_status%TYPE,
                                P_IMPR_TYPE_CD      IN     importers.impr_type_cd%TYPE,
                                P_BUS_ID_EXPRD_DT   IN     VARCHAR2,
                                P_BUS_ID_TYPE_CD    IN     importers.bus_id_type_cd%TYPE,
                                P_COMM_RGSTRTN_TYPE IN     importers.comm_rgstrtn_type%TYPE,
                                P_CITY_CODE_OF_ID   IN     importers.city_code_of_id%TYPE,
                                P_BUS_ID            IN     importers.bus_id%TYPE,
                                P_BUS_ID_BRNCH      IN     importers.bus_id_brnch%TYPE,
                                P_CTRY_CD           IN     importers.ctry_cd%TYPE,
                                P_ARBC_IMPR_NAME    IN     importers.arbc_impr_name%TYPE,
                                P_IMPR_NAME_STD     IN     importers.impr_name_std%TYPE,
                                P_LST_TRAN_DT       IN     VARCHAR2,
                                P_IMPR_ADDRESS      IN     importers.impr_address%TYPE,
                                P_BUS_ID_ISSUE_DT   IN     VARCHAR2,
                                P_IMPR_POB_NBR      IN     importers.impr_pob_nbr%TYPE,
                                P_IMPR_ZIP_CD       IN     importers.impr_zip_cd%TYPE,
                                P_IMPR_TEL_NBR      IN     importers.impr_tel_nbr%TYPE,
                                P_IMPR_FAX_NBR      IN     importers.impr_fax_nbr%TYPE,
                                P_IMPR_TELEX_NBR    IN     importers.impr_telex_nbr%TYPE,
                                P_CTRY_CD_OF_ID     IN     importers.ctry_cd_of_id%TYPE,
                                P_ACTIVITY          IN     importers.activity%TYPE,
                                P_CREATION_FLAG     IN     importers.creation_flag%TYPE,
                                P_ID_CITY_NAME      IN     VARCHAR2,
                                P_ID_MINS_COMM_CD   IN     NUMBER,
                                P_BRNH_CITY_CD      IN     NUMBER,
                                P_BRNH_CITY_NAME    IN     VARCHAR2,
                                P_B_ID_NBR          IN     VARCHAR2,
                                P_ROW_ID            IN     VARCHAR2)
        RETURN VARCHAR2;

    -- Source: IMPORTERS.BUS_ID.POST-CHANGE + WHEN-VALIDATE-ITEM
    -- APEX  : DA "BUS_ID WHEN-VALIDATE-ITEM" (Change): FOS, Items to Submit = the IN items, Items to Return = the IN OUT / OUT items
    PROCEDURE BUS_ID_WHEN_VALIDATE_ITEM (P_PORT_CD           IN     importers.port_cd%TYPE,
                                         P_IMPR_NBR          IN     importers.impr_nbr%TYPE,
                                         P_BUS_ID_STATUS    IN OUT importers.bus_id_status%TYPE,
                                         P_IMPR_TYPE_CD      IN     importers.impr_type_cd%TYPE,
                                         P_BUS_ID_EXPRD_DT  IN OUT VARCHAR2,
                                         P_BUS_ID_TYPE_CD    IN     importers.bus_id_type_cd%TYPE,
                                         P_COMM_RGSTRTN_TYPE IN     importers.comm_rgstrtn_type%TYPE,
                                         P_CITY_CODE_OF_ID  IN OUT importers.city_code_of_id%TYPE,
                                         P_BUS_ID           IN OUT importers.bus_id%TYPE,
                                         P_BUS_ID_BRNCH      IN     importers.bus_id_brnch%TYPE,
                                         P_CTRY_CD           IN     importers.ctry_cd%TYPE,
                                         P_ARBC_IMPR_NAME   IN OUT importers.arbc_impr_name%TYPE,
                                         P_IMPR_NAME_STD    IN OUT importers.impr_name_std%TYPE,
                                         P_LST_TRAN_DT      IN OUT VARCHAR2,
                                         P_IMPR_ADDRESS     IN OUT importers.impr_address%TYPE,
                                         P_BUS_ID_ISSUE_DT  IN OUT VARCHAR2,
                                         P_IMPR_POB_NBR     IN OUT importers.impr_pob_nbr%TYPE,
                                         P_IMPR_ZIP_CD      IN OUT importers.impr_zip_cd%TYPE,
                                         P_IMPR_TEL_NBR     IN OUT importers.impr_tel_nbr%TYPE,
                                         P_IMPR_FAX_NBR     IN OUT importers.impr_fax_nbr%TYPE,
                                         P_IMPR_TELEX_NBR   IN OUT importers.impr_telex_nbr%TYPE,
                                         P_CTRY_CD_OF_ID     IN     importers.ctry_cd_of_id%TYPE,
                                         P_ACTIVITY         IN OUT importers.activity%TYPE,
                                         P_CREATION_FLAG    IN OUT importers.creation_flag%TYPE,
                                         P_ID_CITY_NAME     IN OUT VARCHAR2,
                                         P_ID_MINS_COMM_CD  IN OUT NUMBER,
                                         P_BRNH_CITY_CD     IN OUT NUMBER,
                                         P_BRNH_CITY_NAME   IN OUT VARCHAR2,
                                         P_B_ID_NBR         IN OUT VARCHAR2,
                                         P_ROW_ID            IN     VARCHAR2,
                                         P_ANSWER            IN     PLS_INTEGER DEFAULT NULL,
                                         P_SUSPEND_ANSWER    IN     PLS_INTEGER DEFAULT NULL);

    -- Source: IMPORTERS.BUS_ID.WHEN-NEW-ITEM-INSTANCE
    -- APEX  : DA "BUS_ID WHEN-NEW-ITEM-INSTANCE": FOS, Items to Return = the IN OUT / OUT items
    PROCEDURE BUS_ID_WHEN_NEW_ITEM_INSTANCE (P_IMPR_TYPE_CD      IN     importers.impr_type_cd%TYPE,
                                             P_BUS_ID_TYPE_CD    IN     importers.bus_id_type_cd%TYPE,
                                             P_COMM_RGSTRTN_TYPE IN     importers.comm_rgstrtn_type%TYPE,
                                             P_CITY_CODE_OF_ID   IN     importers.city_code_of_id%TYPE,
                                             P_BUS_ID            IN     importers.bus_id%TYPE,
                                             P_ID_MINS_COMM_CD   IN     NUMBER);

    -- Source: IMPORTERS.BUS_ID.WHEN-VALIDATE-ITEM, question "يوجد مستورد ... موقوف له نفس الرقم الإستدلالي"
    -- APEX  : FOS before "BUS_ID WHEN-VALIDATE-ITEM": returns P1110_CONFIRM_TEXT; Confirm sets P1110_SUSPEND_ANSWER
    FUNCTION BUS_ID_SUSPENDED_CONFIRM_TEXT (P_PORT_CD           IN     importers.port_cd%TYPE,
                                            P_IMPR_NBR          IN     importers.impr_nbr%TYPE,
                                            P_BUS_ID_TYPE_CD    IN     importers.bus_id_type_cd%TYPE,
                                            P_COMM_RGSTRTN_TYPE IN     importers.comm_rgstrtn_type%TYPE,
                                            P_BUS_ID            IN     importers.bus_id%TYPE,
                                            P_BUS_ID_BRNCH      IN     importers.bus_id_brnch%TYPE,
                                            P_CTRY_CD           IN     importers.ctry_cd%TYPE)
        RETURN VARCHAR2;

    -- Section: ITEM BUS_ID
    -- Source: importer type table (group 2), WNRI (lock, unlocked by IMPR1110F2)
    FUNCTION BUS_ID_IS_READ_ONLY (P_IMPR_NBR       IN NUMBER,
                                  P_CODE         IN VARCHAR2,
                                  P_IMPR_TYPE_CD   IN NUMBER,
                                  P_BUS_ID_TYPE_CD IN NUMBER) RETURN BOOLEAN;

    -- =========================================================================
    -- ITEM BRNH_CITY_CD
    -- =========================================================================

    -- Source: IMPORTERS.BRNH_CITY_CD.WHEN-VALIDATE-ITEM
    -- APEX  : Validation "BRNH_CITY_CD VALIDATION" (request CREATE / SAVE): returns the error text
    FUNCTION BRNH_CITY_CD_VALIDATION (P_CTRY_CD_OF_ID  IN     importers.ctry_cd_of_id%TYPE,
                                      P_BRNH_CITY_CD   IN     NUMBER,
                                      P_BRNH_CITY_NAME IN     VARCHAR2)
        RETURN VARCHAR2;

    -- Source: IMPORTERS.BRNH_CITY_CD.WHEN-VALIDATE-ITEM
    -- APEX  : DA "BRNH_CITY_CD WHEN-VALIDATE-ITEM" (Change): FOS, Items to Submit = the IN items, Items to Return = the IN OUT / OUT items
    PROCEDURE BRNH_CITY_CD_VALIDATE_ITEM (P_CTRY_CD_OF_ID   IN     importers.ctry_cd_of_id%TYPE,
                                          P_BRNH_CITY_CD    IN     NUMBER,
                                          P_BRNH_CITY_NAME IN OUT VARCHAR2);

    -- Section: ITEM BRNH_CITY_CD
    -- Source: COMM_RGSTRTN_TYPE WHEN-LIST-CHANGED (1 = read-only, 2 = editable), WNRI (lock, IMPR1110F2)
    -- TODO-VERIFY: value NULL (no registration type) is treated as editable
    FUNCTION BRNH_CITY_CD_IS_READ_ONLY (P_IMPR_NBR          IN NUMBER,
                                        P_CODE            IN VARCHAR2,
                                        P_COMM_RGSTRTN_TYPE IN NUMBER) RETURN BOOLEAN;

    -- Section: ITEM BRNH_CITY_CD
    -- Source: COMM_RGSTRTN_TYPE WHEN-LIST-CHANGED (REQUIRED for type 2)
    FUNCTION BRNH_CITY_CD_IS_REQUIRED (P_COMM_RGSTRTN_TYPE IN NUMBER) RETURN BOOLEAN;

    -- =========================================================================
    -- ITEM BUS_ID_BRNCH
    -- =========================================================================

    -- Source: IMPORTERS.BUS_ID_BRNCH.POST-CHANGE + WHEN-VALIDATE-ITEM
    -- APEX  : Validation "BUS_ID_BRNCH VALIDATION" (request CREATE / SAVE): returns the error text
    FUNCTION BUS_ID_BRNCH_VALIDATION (P_PORT_CD              IN     importers.port_cd%TYPE,
                                      P_IMPR_NBR             IN     importers.impr_nbr%TYPE,
                                      P_BUS_ID_STATUS        IN     importers.bus_id_status%TYPE,
                                      P_IMPR_TYPE_CD         IN     importers.impr_type_cd%TYPE,
                                      P_BUS_ID_EXPRD_DT      IN     VARCHAR2,
                                      P_BUS_ID_TYPE_CD       IN     importers.bus_id_type_cd%TYPE,
                                      P_COMM_RGSTRTN_TYPE    IN     importers.comm_rgstrtn_type%TYPE,
                                      P_CITY_CODE_OF_ID      IN     importers.city_code_of_id%TYPE,
                                      P_BUS_ID               IN     importers.bus_id%TYPE,
                                      P_BUS_ID_BRNCH         IN     importers.bus_id_brnch%TYPE,
                                      P_CTRY_CD              IN     importers.ctry_cd%TYPE,
                                      P_ARBC_IMPR_NAME       IN     importers.arbc_impr_name%TYPE,
                                      P_IMPR_NAME_STD        IN     importers.impr_name_std%TYPE,
                                      P_LST_TRAN_DT          IN     VARCHAR2,
                                      P_IMPR_ADDRESS         IN     importers.impr_address%TYPE,
                                      P_BUS_ID_ISSUE_DT      IN     VARCHAR2,
                                      P_IMPR_POB_NBR         IN     importers.impr_pob_nbr%TYPE,
                                      P_IMPR_ZIP_CD          IN     importers.impr_zip_cd%TYPE,
                                      P_IMPR_TEL_NBR         IN     importers.impr_tel_nbr%TYPE,
                                      P_IMPR_FAX_NBR         IN     importers.impr_fax_nbr%TYPE,
                                      P_IMPR_TELEX_NBR       IN     importers.impr_telex_nbr%TYPE,
                                      P_CTRY_CD_OF_ID        IN     importers.ctry_cd_of_id%TYPE,
                                      P_ACTIVITY             IN     importers.activity%TYPE,
                                      P_CREATION_FLAG        IN     importers.creation_flag%TYPE,
                                      P_ID_CITY_NAME         IN     VARCHAR2,
                                      P_BRNH_ID_MINS_COMM_CD IN     NUMBER,
                                      P_BRNH_CITY_CD         IN     NUMBER,
                                      P_BRNH_CITY_NAME       IN     VARCHAR2,
                                      P_ROW_ID               IN     VARCHAR2,
                                      P_CODE               IN     VARCHAR2)
        RETURN VARCHAR2;

    -- Source: IMPORTERS.BUS_ID_BRNCH.POST-CHANGE + WHEN-VALIDATE-ITEM
    -- APEX  : DA "BUS_ID_BRNCH WHEN-VALIDATE-ITEM" (Change): FOS, Items to Submit = the IN items, Items to Return = the IN OUT / OUT items
    PROCEDURE BUS_ID_BRNCH_VALIDATE_ITEM (P_PORT_CD               IN     importers.port_cd%TYPE,
                                          P_IMPR_NBR              IN     importers.impr_nbr%TYPE,
                                          P_BUS_ID_STATUS        IN OUT importers.bus_id_status%TYPE,
                                          P_IMPR_TYPE_CD          IN     importers.impr_type_cd%TYPE,
                                          P_BUS_ID_EXPRD_DT      IN OUT VARCHAR2,
                                          P_BUS_ID_TYPE_CD        IN     importers.bus_id_type_cd%TYPE,
                                          P_COMM_RGSTRTN_TYPE     IN     importers.comm_rgstrtn_type%TYPE,
                                          P_CITY_CODE_OF_ID      IN OUT importers.city_code_of_id%TYPE,
                                          P_BUS_ID                IN     importers.bus_id%TYPE,
                                          P_BUS_ID_BRNCH         IN OUT importers.bus_id_brnch%TYPE,
                                          P_CTRY_CD               IN     importers.ctry_cd%TYPE,
                                          P_ARBC_IMPR_NAME       IN OUT importers.arbc_impr_name%TYPE,
                                          P_IMPR_NAME_STD        IN OUT importers.impr_name_std%TYPE,
                                          P_LST_TRAN_DT          IN OUT VARCHAR2,
                                          P_IMPR_ADDRESS         IN OUT importers.impr_address%TYPE,
                                          P_BUS_ID_ISSUE_DT      IN OUT VARCHAR2,
                                          P_IMPR_POB_NBR         IN OUT importers.impr_pob_nbr%TYPE,
                                          P_IMPR_ZIP_CD          IN OUT importers.impr_zip_cd%TYPE,
                                          P_IMPR_TEL_NBR         IN OUT importers.impr_tel_nbr%TYPE,
                                          P_IMPR_FAX_NBR         IN OUT importers.impr_fax_nbr%TYPE,
                                          P_IMPR_TELEX_NBR       IN OUT importers.impr_telex_nbr%TYPE,
                                          P_CTRY_CD_OF_ID         IN     importers.ctry_cd_of_id%TYPE,
                                          P_ACTIVITY             IN OUT importers.activity%TYPE,
                                          P_CREATION_FLAG        IN OUT importers.creation_flag%TYPE,
                                          P_ID_CITY_NAME         IN OUT VARCHAR2,
                                          P_BRNH_ID_MINS_COMM_CD IN OUT NUMBER,
                                          P_BRNH_CITY_CD         IN OUT NUMBER,
                                          P_BRNH_CITY_NAME       IN OUT VARCHAR2,
                                          P_ROW_ID                IN     VARCHAR2,
                                          P_CODE                IN     VARCHAR2,
                                          P_ANSWER                IN     PLS_INTEGER DEFAULT NULL);

    -- Source: IMPORTERS.BUS_ID_BRNCH.WHEN-NEW-ITEM-INSTANCE
    -- APEX  : DA "BUS_ID_BRNCH WHEN-NEW-ITEM-INSTANCE": FOS, Items to Return = the IN OUT / OUT items
    PROCEDURE BUS_ID_BRNCH_NEW_ITEM_INSTANCE (P_IMPR_TYPE_CD    IN     importers.impr_type_cd%TYPE,
                                              P_BUS_ID_TYPE_CD  IN     importers.bus_id_type_cd%TYPE,
                                              P_CITY_CODE_OF_ID IN     importers.city_code_of_id%TYPE,
                                              P_BUS_ID          IN     importers.bus_id%TYPE,
                                              P_BUS_ID_BRNCH    IN     importers.bus_id_brnch%TYPE,
                                              P_CITY_CODE       IN     importers.city_code%TYPE,
                                              P_BRNH_CITY_CD    IN     NUMBER);

    -- Section: ITEM BUS_ID_BRNCH
    -- Source: importer type table (group 2), COMM_RGSTRTN_TYPE WHEN-LIST-CHANGED, WNRI (lock, IMPR1110F2)
    FUNCTION BUS_ID_BRNCH_IS_READ_ONLY (P_IMPR_NBR          IN NUMBER,
                                        P_CODE            IN VARCHAR2,
                                        P_IMPR_TYPE_CD      IN NUMBER,
                                        P_BUS_ID_TYPE_CD    IN NUMBER,
                                        P_COMM_RGSTRTN_TYPE IN NUMBER) RETURN BOOLEAN;

    -- Section: ITEM BUS_ID_BRNCH
    -- Source: COMM_RGSTRTN_TYPE WHEN-LIST-CHANGED / BRNH_CITY_CD WHEN-NEW-ITEM-INSTANCE (REQUIRED for
    --         type 2 unless BUS_ID or CITY_CODE_OF_ID is empty)
    FUNCTION BUS_ID_BRNCH_IS_REQUIRED (P_COMM_RGSTRTN_TYPE IN NUMBER,
                                       P_BUS_ID            IN VARCHAR2,
                                       P_CITY_CODE_OF_ID   IN NUMBER) RETURN BOOLEAN;

    -- =========================================================================
    -- ITEM CTRY_CD
    -- =========================================================================

    -- Source: IMPORTERS.CTRY_CD.WHEN-VALIDATE-ITEM
    -- APEX  : Validation "CTRY_CD VALIDATION" (request CREATE / SAVE): returns the error text
    FUNCTION CTRY_CD_VALIDATION (P_IMPR_TYPE_CD     IN     importers.impr_type_cd%TYPE,
                                 P_BUS_ID_TYPE_CD   IN     importers.bus_id_type_cd%TYPE,
                                 P_CTRY_CD          IN     importers.ctry_cd%TYPE,
                                 P_CTRY_CD_OF_ID    IN     importers.ctry_cd_of_id%TYPE,
                                 P_CRTY_ARBC_NAME   IN     VARCHAR2,
                                 P_CTRY_CTRY_STATUS IN     NUMBER)
        RETURN VARCHAR2;

    -- Source: IMPORTERS.CTRY_CD.WHEN-VALIDATE-ITEM
    -- APEX  : DA "CTRY_CD WHEN-VALIDATE-ITEM" (Change): FOS, Items to Submit = the IN items, Items to Return = the IN OUT / OUT items
    PROCEDURE CTRY_CD_WHEN_VALIDATE_ITEM (P_IMPR_TYPE_CD      IN     importers.impr_type_cd%TYPE,
                                          P_BUS_ID_TYPE_CD    IN     importers.bus_id_type_cd%TYPE,
                                          P_CTRY_CD           IN     importers.ctry_cd%TYPE,
                                          P_CTRY_CD_OF_ID    IN OUT importers.ctry_cd_of_id%TYPE,
                                          P_CRTY_ARBC_NAME   IN OUT VARCHAR2,
                                          P_CTRY_CTRY_STATUS IN OUT NUMBER);

    -- Section: ITEM CTRY_CD
    -- Source: importer type table (group 2)
    FUNCTION CTRY_CD_IS_READ_ONLY (P_IMPR_TYPE_CD   IN NUMBER,
                                   P_BUS_ID_TYPE_CD IN NUMBER) RETURN BOOLEAN;

    -- =========================================================================
    -- ITEM IMPR_EXPR_TYPE
    -- =========================================================================

    -- Source: IMPORTERS.IMPR_EXPR_TYPE.POST-CHANGE
    -- APEX  : Validation "IMPR_EXPR_TYPE VALIDATION" (request CREATE / SAVE): returns the error text
    FUNCTION IMPR_EXPR_TYPE_VALIDATION
        RETURN VARCHAR2;

    -- Source: IMPORTERS.IMPR_EXPR_TYPE.POST-CHANGE
    -- APEX  : DA "IMPR_EXPR_TYPE WHEN-VALIDATE-ITEM" (Change): FOS, Items to Submit = the IN items, Items to Return = the IN OUT / OUT items
    PROCEDURE IMPR_EXPR_TYPE_VALIDATE_ITEM;

    -- Section: ITEM IMPR_EXPR_TYPE
    -- Source: WNRI (saved record: never unlocked), WHEN-CREATE-RECORD / BROKER_INT (brokers: class 1, type 3)
    FUNCTION IMPR_EXPR_TYPE_IS_READ_ONLY (P_IMPR_NBR IN NUMBER,
                                          P_CLASS_CD     IN NUMBER,
                                          V_USR_TYPE     IN NUMBER) RETURN BOOLEAN;

    -- =========================================================================
    -- ITEM ARBC_IMPR_NAME
    -- =========================================================================

    -- Source: IMPORTERS.ARBC_IMPR_NAME.WHEN-VALIDATE-ITEM
    -- APEX  : Validation "ARBC_IMPR_NAME VALIDATION" (request CREATE / SAVE): returns the error text
    FUNCTION ARBC_IMPR_NAME_VALIDATION (P_ARBC_IMPR_NAME IN     importers.arbc_impr_name%TYPE,
                                        P_IMPR_NAME_STD  IN     importers.impr_name_std%TYPE)
        RETURN VARCHAR2;

    -- Source: IMPORTERS.ARBC_IMPR_NAME.WHEN-VALIDATE-ITEM
    -- APEX  : DA "ARBC_IMPR_NAME WHEN-VALIDATE-ITEM" (Change): FOS, Items to Submit = the IN items, Items to Return = the IN OUT / OUT items
    PROCEDURE ARBC_IMPR_NAME_VALIDATE_ITEM (P_ARBC_IMPR_NAME IN OUT importers.arbc_impr_name%TYPE,
                                            P_IMPR_NAME_STD  IN OUT importers.impr_name_std%TYPE);

    -- Source: IMPORTERS.ARBC_IMPR_NAME.KEY-NEXT-ITEM
    -- APEX  : DA "ARBC_IMPR_NAME KEY-NEXT-ITEM": FOS, Items to Return = the IN OUT / OUT items
    PROCEDURE ARBC_IMPR_NAME_KEY_NEXT_ITEM (P_CTRY_CD             IN     importers.ctry_cd%TYPE,
                                            P_ADD_CTRY_CD        IN OUT importers.add_ctry_cd%TYPE,
                                            P_CITY_CODE          IN OUT importers.city_code%TYPE,
                                            P_IMPR_TEL_NBR       IN OUT importers.impr_tel_nbr%TYPE,
                                            P_ADD_CRTY_ARBC_NAME IN OUT VARCHAR2,
                                            P_CITY_NAME          IN OUT VARCHAR2);

    -- Section: ITEM ARBC_IMPR_NAME
    -- Source: WNRI (lock, unlocked by IMPR1110F1 / IMPR1110F5), BUS_ID / BUS_ID_BRNCH WHEN-VALIDATE-ITEM
    --         (one register row -> the name comes from the register)
    FUNCTION ARBC_IMPR_NAME_IS_READ_ONLY (P_IMPR_NBR          IN NUMBER,
                                          P_CODE            IN VARCHAR2,
                                          P_IMPR_TYPE_CD      IN NUMBER,
                                          P_BUS_ID_TYPE_CD    IN NUMBER,
                                          P_BUS_ID            IN VARCHAR2,
                                          P_BUS_ID_BRNCH      IN VARCHAR2,
                                          P_COMM_RGSTRTN_TYPE IN NUMBER) RETURN BOOLEAN;

    -- =========================================================================
    -- ITEM ENG_IMPR_NAME
    -- =========================================================================

    -- Source: IMPORTERS.ENG_IMPR_NAME.WHEN-VALIDATE-ITEM
    -- APEX  : Validation "ENG_IMPR_NAME VALIDATION" (request CREATE / SAVE): returns the error text
    FUNCTION ENG_IMPR_NAME_VALIDATION (P_ENG_IMPR_NAME IN     importers.eng_impr_name%TYPE)
        RETURN VARCHAR2;

    -- Source: IMPORTERS.ENG_IMPR_NAME.WHEN-VALIDATE-ITEM
    -- APEX  : DA "ENG_IMPR_NAME WHEN-VALIDATE-ITEM" (Change): FOS, Items to Submit = the IN items, Items to Return = the IN OUT / OUT items
    PROCEDURE ENG_IMPR_NAME_VALIDATE_ITEM (P_ENG_IMPR_NAME IN OUT importers.eng_impr_name%TYPE);

    -- =========================================================================
    -- ITEM BUS_ID_ISSUE_DT
    -- =========================================================================

    -- Source: IMPORTERS.BUS_ID_ISSUE_DT.WHEN-VALIDATE-ITEM
    -- APEX  : Validation "BUS_ID_ISSUE_DT VALIDATION" (request CREATE / SAVE): returns the error text
    FUNCTION BUS_ID_ISSUE_DT_VALIDATION (P_BUS_ID_ISSUE_DT IN     VARCHAR2)
        RETURN VARCHAR2;

    -- Source: IMPORTERS.BUS_ID_ISSUE_DT.WHEN-VALIDATE-ITEM
    -- APEX  : DA "BUS_ID_ISSUE_DT WHEN-VALIDATE-ITEM" (Change): FOS, Items to Submit = the IN items, Items to Return = the IN OUT / OUT items
    PROCEDURE BUS_ID_ISSUE_DT_VALIDATE_ITEM (P_BUS_ID_ISSUE_DT IN     VARCHAR2);

    -- =========================================================================
    -- ITEM IMPR_NBR_PARENT
    -- =========================================================================

    -- Source: IMPORTERS.IMPR_NBR_PARENT.WHEN-VALIDATE-ITEM
    -- APEX  : Validation "IMPR_NBR_PARENT VALIDATION" (request CREATE / SAVE): returns the error text
    FUNCTION IMPR_NBR_PARENT_VALIDATION (P_IMPR_NBR_PARENT  IN     importers.impr_nbr_parent%TYPE,
                                         P_IMPR_NAME_PARENT IN     VARCHAR2)
        RETURN VARCHAR2;

    -- Source: IMPORTERS.IMPR_NBR_PARENT.WHEN-VALIDATE-ITEM
    -- APEX  : DA "IMPR_NBR_PARENT WHEN-VALIDATE-ITEM" (Change): FOS, Items to Submit = the IN items, Items to Return = the IN OUT / OUT items
    PROCEDURE IMPR_NBR_PARENT_VALIDATE_ITEM (P_IMPR_NBR_PARENT   IN     importers.impr_nbr_parent%TYPE,
                                             P_IMPR_NAME_PARENT IN OUT VARCHAR2);

    -- =========================================================================
    -- ITEM ADD_CTRY_CD
    -- =========================================================================

    -- Source: IMPORTERS.ADD_CTRY_CD.WHEN-VALIDATE-ITEM
    -- APEX  : Validation "ADD_CTRY_CD VALIDATION" (request CREATE / SAVE): returns the error text
    FUNCTION ADD_CTRY_CD_VALIDATION (P_ADD_CTRY_CD        IN     importers.add_ctry_cd%TYPE,
                                     P_CITY_CODE          IN     importers.city_code%TYPE,
                                     P_ADD_CRTY_ARBC_NAME IN     VARCHAR2,
                                     P_CITY_NAME          IN     VARCHAR2,
                                     P_L_CT_CITY_STATUS   IN     NUMBER)
        RETURN VARCHAR2;

    -- Source: IMPORTERS.ADD_CTRY_CD.WHEN-VALIDATE-ITEM
    -- APEX  : DA "ADD_CTRY_CD WHEN-VALIDATE-ITEM" (Change): FOS, Items to Submit = the IN items, Items to Return = the IN OUT / OUT items
    PROCEDURE ADD_CTRY_CD_WHEN_VALIDATE_ITEM (P_ADD_CTRY_CD         IN     importers.add_ctry_cd%TYPE,
                                              P_CITY_CODE           IN     importers.city_code%TYPE,
                                              P_ADD_CRTY_ARBC_NAME IN OUT VARCHAR2,
                                              P_CITY_NAME          IN OUT VARCHAR2,
                                              P_L_CT_CITY_STATUS   IN OUT NUMBER);

    -- =========================================================================
    -- ITEM CITY_CODE
    -- =========================================================================

    -- Source: IMPORTERS.CITY_CODE.WHEN-VALIDATE-ITEM
    -- APEX  : Validation "CITY_CODE VALIDATION" (request CREATE / SAVE): returns the error text
    FUNCTION CITY_CODE_VALIDATION (P_ADD_CTRY_CD        IN     importers.add_ctry_cd%TYPE,
                                   P_CITY_CODE          IN     importers.city_code%TYPE,
                                   P_ADD_CRTY_ARBC_NAME IN     VARCHAR2,
                                   P_CITY_NAME          IN     VARCHAR2,
                                   P_L_CT_CITY_STATUS   IN     NUMBER)
        RETURN VARCHAR2;

    -- Source: IMPORTERS.CITY_CODE.WHEN-VALIDATE-ITEM
    -- APEX  : DA "CITY_CODE WHEN-VALIDATE-ITEM" (Change): FOS, Items to Submit = the IN items, Items to Return = the IN OUT / OUT items
    PROCEDURE CITY_CODE_WHEN_VALIDATE_ITEM (P_ADD_CTRY_CD         IN     importers.add_ctry_cd%TYPE,
                                            P_CITY_CODE           IN     importers.city_code%TYPE,
                                            P_ADD_CRTY_ARBC_NAME IN OUT VARCHAR2,
                                            P_CITY_NAME          IN OUT VARCHAR2,
                                            P_L_CT_CITY_STATUS   IN OUT NUMBER);

    -- Section: ITEM CITY_CODE
    -- Source: IMPORTERS.POST-QUERY (CR-6730: WASL city replaces CITY_CODE / CITY_NAME when it exists)
    -- APEX  : Server-side condition of P1110_WASL_CITY_NAME (shown) and P1110_CITY_CODE / CITY_NAME (not shown)
    FUNCTION WASL_CITY_IS_SHOWN (P_CURR_PORT_CD       IN NUMBER,
                                 P_WASL_CITY_NAME IN VARCHAR2) RETURN BOOLEAN;

    -- =========================================================================
    -- ITEM IMPR_TEL_NBR
    -- =========================================================================

    -- Source: IMPORTERS.IMPR_TEL_NBR.WHEN-VALIDATE-ITEM
    -- APEX  : Validation "IMPR_TEL_NBR VALIDATION" (request CREATE / SAVE): returns the error text
    FUNCTION IMPR_TEL_NBR_VALIDATION (P_IMPR_TEL_NBR IN     importers.impr_tel_nbr%TYPE)
        RETURN VARCHAR2;

    -- Source: IMPORTERS.IMPR_TEL_NBR.WHEN-VALIDATE-ITEM
    -- APEX  : DA "IMPR_TEL_NBR WHEN-VALIDATE-ITEM" (Change): FOS, Items to Submit = the IN items, Items to Return = the IN OUT / OUT items
    PROCEDURE IMPR_TEL_NBR_VALIDATE_ITEM (P_IMPR_TEL_NBR IN     importers.impr_tel_nbr%TYPE);

    -- Section: ITEM IMPR_TEL_NBR
    -- Source: BUS_ID / BUS_ID_BRNCH WHEN-VALIDATE-ITEM (group 3: IMPR_POB_NBR, IMPR_ZIP_CD, IMPR_TEL_NBR,
    --         IMPR_FAX_NBR, IMPR_TELEX_NBR come from the register). Pass the item value in I_VALUE for
    --         IMPR_TEL_NBR (PRE-INSERT re-enables it while empty); the other items keep the default.
    FUNCTION REGISTER_ITEMS_IS_READ_ONLY (P_IMPR_TYPE_CD      IN NUMBER,
                                          P_BUS_ID_TYPE_CD    IN NUMBER,
                                          P_BUS_ID            IN VARCHAR2,
                                          P_BUS_ID_BRNCH      IN VARCHAR2,
                                          P_COMM_RGSTRTN_TYPE IN NUMBER,
                                          ITEM_VALUE                   IN VARCHAR2 DEFAULT 'X') RETURN BOOLEAN;

    -- =========================================================================
    -- ITEM B_EMAIL
    -- =========================================================================

    -- Source: IMPORTERS.B_EMAIL.POST-CHANGE + WHEN-VALIDATE-ITEM
    -- APEX  : Validation "B_EMAIL VALIDATION" (request CREATE / SAVE): returns the error text
    FUNCTION B_EMAIL_VALIDATION (P_PORT_CD  IN     importers.port_cd%TYPE,
                                 P_B_EMAIL  IN     VARCHAR2,
                                 P_CURR_PORT_CD IN     NUMBER)
        RETURN VARCHAR2;

    -- Source: IMPORTERS.B_EMAIL.POST-CHANGE + WHEN-VALIDATE-ITEM
    -- APEX  : DA "B_EMAIL WHEN-VALIDATE-ITEM" (Change): FOS, Items to Submit = the IN items, Items to Return = the IN OUT / OUT items
    PROCEDURE B_EMAIL_WHEN_VALIDATE_ITEM (P_PORT_CD IN OUT importers.port_cd%TYPE,
                                          P_B_EMAIL  IN     VARCHAR2,
                                          P_CURR_PORT_CD IN     NUMBER);

    -- =========================================================================
    -- ITEM EMAIL
    -- =========================================================================

    -- Source: IMPORTERS.EMAIL.WHEN-VALIDATE-ITEM
    -- APEX  : Validation "EMAIL VALIDATION" (request CREATE / SAVE): returns the error text
    FUNCTION EMAIL_VALIDATION (P_EMAIL IN     importers.email%TYPE)
        RETURN VARCHAR2;

    -- Source: IMPORTERS.EMAIL.WHEN-VALIDATE-ITEM
    -- APEX  : DA "EMAIL WHEN-VALIDATE-ITEM" (Change): FOS, Items to Submit = the IN items, Items to Return = the IN OUT / OUT items
    PROCEDURE EMAIL_WHEN_VALIDATE_ITEM (P_EMAIL IN     importers.email%TYPE);

    -- =========================================================================
    -- ITEM B_MOBILE_NO
    -- =========================================================================

    -- Source: IMPORTERS.B_MOBILE_NO.POST-CHANGE + WHEN-VALIDATE-ITEM
    -- APEX  : Validation "B_MOBILE_NO VALIDATION" (request CREATE / SAVE): returns the error text
    FUNCTION B_MOBILE_NO_VALIDATION (P_PORT_CD     IN     importers.port_cd%TYPE,
                                     P_IMPR_NBR    IN     importers.impr_nbr%TYPE,
                                     P_B_MOBILE_NO IN     VARCHAR2,
                                     P_CURR_PORT_CD    IN     NUMBER)
        RETURN VARCHAR2;

    -- Source: IMPORTERS.B_MOBILE_NO.POST-CHANGE + WHEN-VALIDATE-ITEM
    -- APEX  : DA "B_MOBILE_NO WHEN-VALIDATE-ITEM" (Change): FOS, Items to Submit = the IN items, Items to Return = the IN OUT / OUT items
    PROCEDURE B_MOBILE_NO_WHEN_VALIDATE_ITEM (P_PORT_CD    IN OUT importers.port_cd%TYPE,
                                              P_IMPR_NBR    IN     importers.impr_nbr%TYPE,
                                              P_B_MOBILE_NO IN     VARCHAR2,
                                              P_CURR_PORT_CD    IN     NUMBER);

    -- =========================================================================
    -- ITEM BANK_IBAN
    -- =========================================================================

    -- Source: IMPORTERS.BANK_IBAN.WHEN-VALIDATE-ITEM
    -- APEX  : Validation "BANK_IBAN VALIDATION" (request CREATE / SAVE): returns the error text
    FUNCTION BANK_IBAN_VALIDATION (P_BANK_IBAN IN     importers.bank_iban%TYPE)
        RETURN VARCHAR2;

    -- Source: IMPORTERS.BANK_IBAN.WHEN-VALIDATE-ITEM
    -- APEX  : DA "BANK_IBAN WHEN-VALIDATE-ITEM" (Change): FOS, Items to Submit = the IN items, Items to Return = the IN OUT / OUT items
    PROCEDURE BANK_IBAN_WHEN_VALIDATE_ITEM (P_BANK_IBAN IN OUT importers.bank_iban%TYPE);

    -- Source: IMPORTERS.BANK_IBAN.WHEN-NEW-ITEM-INSTANCE
    -- APEX  : DA "BANK_IBAN WHEN-NEW-ITEM-INSTANCE": FOS, Items to Return = the IN OUT / OUT items
    PROCEDURE BANK_IBAN_NEW_ITEM_INSTANCE (P_BANK_IBAN IN OUT importers.bank_iban%TYPE);

    -- =========================================================================
    -- ITEM B_ID_NBR
    -- =========================================================================

    -- Source: IMPORTERS.B_ID_NBR.POST-CHANGE + WHEN-VALIDATE-ITEM
    -- APEX  : Validation "B_ID_NBR VALIDATION" (request CREATE / SAVE): returns the error text
    FUNCTION B_ID_NBR_VALIDATION (P_PORT_CD  IN     importers.port_cd%TYPE,
                                  P_B_ID_NBR IN     VARCHAR2,
                                  P_CURR_PORT_CD IN     NUMBER)
        RETURN VARCHAR2;

    -- Source: IMPORTERS.B_ID_NBR.POST-CHANGE + WHEN-VALIDATE-ITEM
    -- APEX  : DA "B_ID_NBR WHEN-VALIDATE-ITEM" (Change): FOS, Items to Submit = the IN items, Items to Return = the IN OUT / OUT items
    PROCEDURE B_ID_NBR_WHEN_VALIDATE_ITEM (P_PORT_CD IN OUT importers.port_cd%TYPE,
                                           P_B_ID_NBR IN     VARCHAR2,
                                           P_CURR_PORT_CD IN     NUMBER);

    -- Section: ITEM B_ID_NBR
    -- Source: IMPR_TYPE_CD WHEN-VALIDATE-ITEM (type 4 with BUS_ID_TYPE_CD 5)
    FUNCTION B_ID_NBR_IS_READ_ONLY (P_IMPR_TYPE_CD   IN NUMBER,
                                    P_BUS_ID_TYPE_CD IN NUMBER) RETURN BOOLEAN;

    -- =========================================================================
    -- ITEM CAR_AGENT_FLAG
    -- =========================================================================

    -- Section: ITEM CAR_AGENT_FLAG
    -- Source: WNRI (editable only in mode IMPR1110SF6 on a saved record; spec "SEL only")
    FUNCTION CAR_AGENT_FLAG_IS_READ_ONLY (P_IMPR_NBR IN NUMBER,
                                          P_CODE   IN VARCHAR2) RETURN BOOLEAN;

    -- =========================================================================
    -- ITEM EXPRESS_POST
    -- =========================================================================

    -- Section: ITEM EXPRESS_POST
    -- Source: BROKER_INT (brokers: value 2 and read-only)
    FUNCTION EXPRESS_POST_IS_READ_ONLY (P_CLASS_CD IN NUMBER,
                                        V_USR_TYPE IN NUMBER) RETURN BOOLEAN;

    -- =========================================================================
    -- ITEM CTRY_CD_OF_ID
    -- =========================================================================

    -- Source: IMPORTERS.CTRY_CD_OF_ID.WHEN-VALIDATE-ITEM
    -- APEX  : Validation "CTRY_CD_OF_ID VALIDATION" (request CREATE / SAVE): returns the error text
    FUNCTION CTRY_CD_OF_ID_VALIDATION (P_CITY_CODE_OF_ID   IN     importers.city_code_of_id%TYPE,
                                       P_CTRY_CD_OF_ID     IN     importers.ctry_cd_of_id%TYPE,
                                       P_ID_CITY_NAME      IN     VARCHAR2,
                                       P_ID_MINS_COMM_CD   IN     NUMBER,
                                       P_L_CT_CITY_STATUS2 IN     NUMBER,
                                       P_ROW_ID            IN     VARCHAR2)
        RETURN VARCHAR2;

    -- Source: IMPORTERS.CTRY_CD_OF_ID.WHEN-VALIDATE-ITEM
    -- APEX  : DA "CTRY_CD_OF_ID WHEN-VALIDATE-ITEM" (Change): FOS, Items to Submit = the IN items, Items to Return = the IN OUT / OUT items
    PROCEDURE CTRY_CD_OF_ID_VALIDATE_ITEM (P_CITY_CODE_OF_ID   IN OUT importers.city_code_of_id%TYPE,
                                           P_CTRY_CD_OF_ID     IN OUT importers.ctry_cd_of_id%TYPE,
                                           P_ID_CITY_NAME      IN OUT VARCHAR2,
                                           P_ID_MINS_COMM_CD   IN OUT NUMBER,
                                           P_L_CT_CITY_STATUS2 IN OUT NUMBER,
                                           P_ROW_ID             IN     VARCHAR2);

    -- =========================================================================
    -- ITEM ACTIVITY
    -- =========================================================================

    -- Section: ITEM ACTIVITY
    -- Source: BUS_ID WHEN-VALIDATE-ITEM (final rule: editable when BUS_ID is set and ACTIVITY is empty)
    FUNCTION ACTIVITY_IS_READ_ONLY (P_BUS_ID   IN VARCHAR2,
                                    P_ACTIVITY IN VARCHAR2) RETURN BOOLEAN;

    -- Section: ITEM ACTIVITY
    -- Source: PRE-INSERT (ACTIVITY must be entered while it is editable)
    FUNCTION ACTIVITY_IS_REQUIRED (P_BUS_ID IN VARCHAR2) RETURN BOOLEAN;

    -- =========================================================================
    -- BLOCK IMPORTERS - DML
    -- =========================================================================

    -- Source: IMPORTERS.PRE-INSERT
    -- APEX  : Process "PRE-INSERT" (request CREATE / SAVE, :P0_PAGE_PK is null), before "Process form IMPORTERS"; Confirm of brokers (class 1, type 3) sets P1110_ANSWER
    PROCEDURE PRE_INSERT (P_PORT_CD            IN     importers.port_cd%TYPE,
                          P_HQ_IMPR_NBR       IN OUT importers.hq_impr_nbr%TYPE,
                          P_IMPR_NBR           IN     importers.impr_nbr%TYPE,
                          P_IMPR_TYPE_CD       IN     importers.impr_type_cd%TYPE,
                          P_BUS_ID_EXPRD_DT    IN     VARCHAR2,
                          P_BUS_ID_TYPE_CD     IN     importers.bus_id_type_cd%TYPE,
                          P_COMM_RGSTRTN_TYPE  IN     importers.comm_rgstrtn_type%TYPE,
                          P_CITY_CODE_OF_ID   IN OUT importers.city_code_of_id%TYPE,
                          P_BUS_ID             IN     importers.bus_id%TYPE,
                          P_BUS_ID_BRNCH       IN     importers.bus_id_brnch%TYPE,
                          P_CTRY_CD            IN     importers.ctry_cd%TYPE,
                          P_IMPR_EXPR_TYPE     IN     importers.impr_expr_type%TYPE,
                          P_ARBC_IMPR_NAME     IN     importers.arbc_impr_name%TYPE,
                          P_IMPD_STMT_NBR      IN     importers.impd_stmt_nbr%TYPE,
                          P_IMPR_DATA_SRCE     IN     importers.impr_data_srce%TYPE,
                          P_ENG_IMPR_NAME      IN     importers.eng_impr_name%TYPE,
                          P_IMPR_CNTCT_NAME    IN     importers.impr_cntct_name%TYPE,
                          P_IMPR_ADDRESS       IN     importers.impr_address%TYPE,
                          P_BUS_ID_ISSUE_DT    IN     VARCHAR2,
                          P_IMPR_NBR_PARENT    IN     importers.impr_nbr_parent%TYPE,
                          P_ADD_CTRY_CD        IN     importers.add_ctry_cd%TYPE,
                          P_CITY_CODE          IN     importers.city_code%TYPE,
                          P_IMPR_POB_NBR       IN     importers.impr_pob_nbr%TYPE,
                          P_IMPR_ZIP_CD        IN     importers.impr_zip_cd%TYPE,
                          P_IMPR_TEL_NBR       IN     importers.impr_tel_nbr%TYPE,
                          P_IMPR_FAX_NBR       IN     importers.impr_fax_nbr%TYPE,
                          P_IMPR_TELEX_NBR     IN     importers.impr_telex_nbr%TYPE,
                          P_BANK_IBAN          IN     importers.bank_iban%TYPE,
                          P_CAR_AGENT_FLAG     IN     importers.car_agent_flag%TYPE,
                          P_EXPRESS_POST       IN     importers.express_post%TYPE,
                          P_CTRY_CD_OF_ID     IN OUT importers.ctry_cd_of_id%TYPE,
                          P_EXPD_STMT_NBR      IN     importers.expd_stmt_nbr%TYPE,
                          P_WVR_ENTRY_NBR      IN     importers.wvr_entry_nbr%TYPE,
                          P_ACTIVITY           IN     importers.activity%TYPE,
                          P_ID_CITY_NAME      IN OUT VARCHAR2,
                          P_ID_MINS_COMM_CD   IN OUT NUMBER,
                          P_L_CT_CITY_STATUS2 IN OUT NUMBER,
                          P_BRNH_CITY_CD       IN     NUMBER,
                          P_B_EMAIL            IN     VARCHAR2,
                          P_B_MOBILE_NO        IN     VARCHAR2,
                          P_B_ID_NBR           IN     VARCHAR2,
                          P_CURR_PORT_CD           IN     NUMBER,
                          SSO_APP_USER             IN     VARCHAR2,
                          P_GLOBAL_V_WS_ID         IN     VARCHAR2,
                          P_CLASS_CD               IN     NUMBER,
                          V_USR_TYPE               IN     NUMBER,
                          P_ANSWER             IN     PLS_INTEGER DEFAULT NULL);

    -- Source: IMPORTERS.POST-INSERT
    -- APEX  : Process "POST-INSERT", after "Process form IMPORTERS"
    PROCEDURE POST_INSERT (P_PORT_CD           IN     importers.port_cd%TYPE,
                           P_HQ_IMPR_NBR      IN OUT importers.hq_impr_nbr%TYPE,
                           P_IMPR_NBR         IN OUT importers.impr_nbr%TYPE,
                           P_BUS_ID_STATUS     IN     importers.bus_id_status%TYPE,
                           P_IMPR_TYPE_CD      IN     importers.impr_type_cd%TYPE,
                           P_BUS_ID_EXPRD_DT   IN     VARCHAR2,
                           P_BUS_ID_TYPE_CD    IN     importers.bus_id_type_cd%TYPE,
                           P_COMM_RGSTRTN_TYPE IN     importers.comm_rgstrtn_type%TYPE,
                           P_CITY_CODE_OF_ID   IN     importers.city_code_of_id%TYPE,
                           P_BUS_ID            IN     importers.bus_id%TYPE,
                           P_BUS_ID_BRNCH      IN     importers.bus_id_brnch%TYPE,
                           P_CTRY_CD           IN     importers.ctry_cd%TYPE,
                           P_IMPR_EXPR_TYPE    IN     importers.impr_expr_type%TYPE,
                           P_ARBC_IMPR_NAME    IN     importers.arbc_impr_name%TYPE,
                           P_IMPR_NAME_STD     IN     importers.impr_name_std%TYPE,
                           P_LST_TRAN_DT       IN     VARCHAR2,
                           P_IMPD_STMT_NBR     IN     importers.impd_stmt_nbr%TYPE,
                           P_IMPR_DATA_SRCE    IN     importers.impr_data_srce%TYPE,
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
                           P_BANK_IBAN         IN     importers.bank_iban%TYPE,
                           P_ID_NBR            IN     importers.id_nbr%TYPE,
                           P_CAR_AGENT_FLAG    IN     importers.car_agent_flag%TYPE,
                           P_EXPRESS_POST      IN     importers.express_post%TYPE,
                           P_CTRY_CD_OF_ID     IN     importers.ctry_cd_of_id%TYPE,
                           P_CREATION_FLAG     IN     importers.creation_flag%TYPE,
                           P_B_EMAIL           IN     VARCHAR2,
                           P_B_MOBILE_NO       IN     VARCHAR2,
                           P_B_ID_NBR          IN     VARCHAR2,
                           P_CURR_PORT_CD          IN     NUMBER,
                           SSO_APP_USER            IN     VARCHAR2,
                           P_GLOBAL_V_WS_ID        IN     VARCHAR2,
                           P_CLASS_CD              IN     NUMBER,
                           V_USR_TYPE              IN     NUMBER,
                           P_BRKR_PORT_CD          IN     NUMBER,
                           P_LIC_TYPE              IN     NUMBER,
                           P_BRKR_NBR              IN     NUMBER);

    -- Source: IMPORTERS.PRE-UPDATE
    -- APEX  : Process "PRE-UPDATE" (request SAVE, :P0_PAGE_PK is not null), before "Process form IMPORTERS"
    PROCEDURE PRE_UPDATE (P_PORT_CD           IN     importers.port_cd%TYPE,
                          P_HQ_IMPR_NBR      IN OUT importers.hq_impr_nbr%TYPE,
                          P_IMPR_NBR          IN     importers.impr_nbr%TYPE,
                          P_BUS_ID_STATUS     IN     importers.bus_id_status%TYPE,
                          P_IMPR_TYPE_CD     IN OUT importers.impr_type_cd%TYPE,
                          P_BUS_ID_EXPRD_DT   IN     VARCHAR2,
                          P_BUS_ID_TYPE_CD    IN     importers.bus_id_type_cd%TYPE,
                          P_COMM_RGSTRTN_TYPE IN     importers.comm_rgstrtn_type%TYPE,
                          P_CITY_CODE_OF_ID   IN     importers.city_code_of_id%TYPE,
                          P_BUS_ID            IN     importers.bus_id%TYPE,
                          P_BUS_ID_BRNCH      IN     importers.bus_id_brnch%TYPE,
                          P_CTRY_CD           IN     importers.ctry_cd%TYPE,
                          P_IMPR_EXPR_TYPE    IN     importers.impr_expr_type%TYPE,
                          P_ARBC_IMPR_NAME   IN OUT importers.arbc_impr_name%TYPE,
                          P_IMPR_NAME_STD    IN OUT importers.impr_name_std%TYPE,
                          P_LST_TRAN_DT       IN     VARCHAR2,
                          P_IMPD_STMT_NBR     IN     importers.impd_stmt_nbr%TYPE,
                          P_IMPR_DATA_SRCE    IN     importers.impr_data_srce%TYPE,
                          P_ENG_IMPR_NAME    IN OUT importers.eng_impr_name%TYPE,
                          P_IMPR_CNTCT_NAME  IN OUT importers.impr_cntct_name%TYPE,
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
                          P_MOBILE_NO        IN OUT importers.mobile_no%TYPE,
                          P_BANK_IBAN         IN     importers.bank_iban%TYPE,
                          P_ID_NBR            IN     importers.id_nbr%TYPE,
                          P_CAR_AGENT_FLAG    IN     importers.car_agent_flag%TYPE,
                          P_EXPRESS_POST      IN     importers.express_post%TYPE,
                          P_CTRY_CD_OF_ID     IN     importers.ctry_cd_of_id%TYPE,
                          P_CUSTOMS_ENTERED  IN OUT importers.customs_entered%TYPE,
                          P_CREATION_FLAG     IN     importers.creation_flag%TYPE,
                          P_IMPR_TYPE_NAME   IN OUT VARCHAR2,
                          P_B_MOBILE_NO       IN     VARCHAR2,
                          P_CURR_PORT_CD          IN     NUMBER,
                          SSO_APP_USER            IN     VARCHAR2,
                          P_GLOBAL_V_WS_ID        IN     VARCHAR2,
                          P_LETTER_NBR      IN     VARCHAR2);

    -- Source: IMPORTERS.POST-UPDATE
    -- APEX  : Process "POST-UPDATE", after "Process form IMPORTERS"
    PROCEDURE POST_UPDATE (P_HQ_IMPR_NBR    IN     importers.hq_impr_nbr%TYPE,
                           P_IMPR_TYPE_CD   IN     importers.impr_type_cd%TYPE,
                           P_BUS_ID_TYPE_CD IN     importers.bus_id_type_cd%TYPE,
                           P_BUS_ID         IN     importers.bus_id%TYPE,
                           P_BUS_ID_BRNCH   IN     importers.bus_id_brnch%TYPE,
                           P_B_EMAIL        IN     VARCHAR2,
                           P_B_MOBILE_NO    IN     VARCHAR2,
                           P_B_ID_NBR       IN     VARCHAR2);

    -- Source: IMPORTERS.KEY-DELREC (+ PRE-DELETE); the question is the page 0 DELETE confirm
    -- APEX  : Process "KEY-DELREC" (request DELETE) instead of the native delete
    PROCEDURE KEY_DELREC (P_PORT_CD    IN     importers.port_cd%TYPE,
                          P_IMPR_NBR   IN     importers.impr_nbr%TYPE,
                          P_ROW_ID     IN     VARCHAR2,
                          P_CURR_PORT_CD   IN     NUMBER,
                          SSO_APP_USER     IN     VARCHAR2,
                          P_GLOBAL_V_WS_ID IN     VARCHAR2);

    -- =========================================================================
    -- FUNCTIONS
    -- =========================================================================

    -- Source: PU ADJ_FUNS (TMPLT.ENABLE_FUN / DISABLE_FUN)
    -- APEX  : Computation P1110_ADJ_FUNS (comma list of the enabled functions, filter of the f345 Page Functions list)
    FUNCTION ADJ_FUNS (P_IMPR_NBR       IN     importers.impr_nbr%TYPE,
                       P_IMPR_TYPE_CD   IN     importers.impr_type_cd%TYPE,
                       P_BUS_ID_TYPE_CD IN     importers.bus_id_type_cd%TYPE,
                       P_CURR_PORT_CD       IN     NUMBER,
                       SSO_APP_USER         IN     VARCHAR2,
                       P_CLASS_CD           IN     NUMBER,
                       V_USR_TYPE           IN     NUMBER)
        RETURN VARCHAR2;

    -- Source: PU EXEC_FUNS (TMPLT EXECUTE_FUNCTION)
    -- APEX  : DA of each entry of the Page Functions list (FOS); then WHEN_NEW_RECORD_INSTANCE
    PROCEDURE EXEC_FUNS (P_PORT_CD        IN     importers.port_cd%TYPE,
                         P_IMPR_NBR       IN     importers.impr_nbr%TYPE,
                         P_BUS_ID         IN     importers.bus_id%TYPE,
                         P_BUS_ID_BRNCH   IN     importers.bus_id_brnch%TYPE,
                         P_ARBC_IMPR_NAME IN     importers.arbc_impr_name%TYPE,
                         P_CURR_PORT_CD       IN     NUMBER,
                         SSO_APP_USER         IN     VARCHAR2,
                         P_GLOBAL_V_WS_ID     IN     VARCHAR2,
                         P_CLASS_CD           IN     NUMBER,
                         V_USR_TYPE           IN     NUMBER,
                         P_LETTER_NBR  IN OUT VARCHAR2,
                         P_CODE        IN OUT VARCHAR2,
                         P_BRKR_PORT_CD       IN     NUMBER,
                         P_LIC_TYPE           IN     NUMBER,
                         P_BRKR_NBR           IN     NUMBER,
                         FUNCTION_CODE        IN     VARCHAR2);

    -- Source: PU UPDATE_IMPORTER_MSG (question of function IMPR_MCI_SERVICE)
    -- APEX  : FOS returns P1110_CONFIRM_TEXT; native Confirm
    FUNCTION UPDATE_IMPORTER_CONFIRM_TEXT (P_PORT_CD        IN     importers.port_cd%TYPE,
                                           P_IMPR_NBR       IN     importers.impr_nbr%TYPE,
                                           P_IMPR_TYPE_CD   IN     importers.impr_type_cd%TYPE,
                                           P_BUS_ID_TYPE_CD IN     importers.bus_id_type_cd%TYPE,
                                           P_BUS_ID         IN     importers.bus_id%TYPE,
                                           P_BUS_ID_BRNCH   IN     importers.bus_id_brnch%TYPE)
        RETURN VARCHAR2;

    -- Source: PU UPDATE_IMPORTER (function IMPR_MCI_SERVICE, ALLOW_MCI / ALLOW_MOI)
    -- APEX  : DA "IMPR_MCI_SERVICE" after the Confirm (FOS)
    PROCEDURE UPDATE_IMPORTER (P_PORT_CD  IN     importers.port_cd%TYPE,
                               P_IMPR_NBR IN     importers.impr_nbr%TYPE,
                               P_ANSWER   IN     PLS_INTEGER DEFAULT NULL);

    -- Source: PU LOV_UPDATE_MOBLIE, part after CALL_FORM(LOV_UPDATE_IMPR_MOBILE)
    -- APEX  : DA "Dialog Closed" of page 111002 (FOS)
    PROCEDURE LOV_UPDATE_MOBLIE (P_IMPR_NBR IN     importers.impr_nbr%TYPE);

    -- =========================================================================
    -- PAGE 111002 (LOV_UPDATE_IMPR_MOBILE)
    -- =========================================================================

    -- Source: PU LOV_UPDATE_MOBLIE, part before CALL_FORM (P_CENTRAL_MOBILE)
    -- APEX  : Computation P111002_CENTRAL_MOBILE (Before Header)
    FUNCTION CENTRAL_MOBILE (P_IMPR_NBR IN     importers.impr_nbr%TYPE,
                             P_CURR_PORT_CD   IN     NUMBER)
        RETURN NUMBER;

    -- Section: PAGE 111002 (LOV_UPDATE_IMPR_MOBILE)
    -- Source: LOV_UPDATE_IMPR_MOBILE.CTRL_BLK.PB_OK (:GLOBAL.OK := 1; COPY_SELECTED_VALUES)
    -- APEX  : Process "PB_OK WHEN-BUTTON-PRESSED" of page 111002, then Close Dialog
    PROCEDURE MOBILE_OK (P_MOBILE_NO IN VARCHAR2);

    -- Section: PAGE 111002 (LOV_UPDATE_IMPR_MOBILE)
    -- Source: LOV_UPDATE_IMPR_MOBILE.CTRL_BLK.PB_CANCEL (CANCEL_LOV_FORM)
    PROCEDURE MOBILE_CANCEL;

END IMPR1110;
/
SHOW ERRORS

-- -----------------------------------------------------------------------------
-- Synonym and grants (run as a user allowed to create public synonyms / grant on LIB_APX_USR).
-- CUSTOMS = parsing schema of the APEX application: APEX needs the direct grant.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PUBLIC SYNONYM IMPR1110 FOR LIB_APX_USR.IMPR1110;

GRANT EXECUTE ON LIB_APX_USR.IMPR1110 TO LIB_USR;

GRANT EXECUTE ON LIB_APX_USR.IMPR1110 TO SECURITY_DEFAULT;

GRANT EXECUTE ON LIB_APX_USR.IMPR1110 TO SECURITY_PROD;

GRANT EXECUTE ON LIB_APX_USR.IMPR1110 TO CUSTOMS;
