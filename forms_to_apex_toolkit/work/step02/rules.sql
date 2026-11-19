    -- Section: PRIVATE RULE HELPERS
    -- Group 1 of read_only_rules.md: a saved record (IMPR_NBR set) is locked, except in the
    -- function modes listed in p_unlocked_by (comma list of :PARAMETER.CODE values)
    FUNCTION PRIVATE_SAVED_RECORD_LOCKED (p_impr_nbr    IN NUMBER,
                                          p_code        IN VARCHAR2,
                                          p_unlocked_by IN VARCHAR2) RETURN BOOLEAN
    IS
    BEGIN
        RETURN p_impr_nbr IS NOT NULL
               AND (p_code IS NULL OR INSTR(',' || p_unlocked_by || ',', ',' || p_code || ',') = 0);
    END PRIVATE_SAVED_RECORD_LOCKED;

    -- Section: PRIVATE RULE HELPERS
    -- Group 2 of read_only_rules.md: importer type table (IMPR_TYPE_CD WHEN-VALIDATE-ITEM / POST-QUERY)
    FUNCTION PRIVATE_IMPORTER_TYPE_LOCKED (p_item           IN VARCHAR2,
                                           p_impr_type_cd   IN NUMBER,
                                           p_bus_id_type_cd IN NUMBER) RETURN BOOLEAN
    IS
        v_bus_id_type NUMBER := NVL(p_bus_id_type_cd, 6);
    BEGIN
        CASE
            WHEN p_impr_type_cd IN (1, 5, 8) THEN
                RETURN p_item = 'CTRY_CD';
            WHEN p_impr_type_cd = 2 THEN
                RETURN p_item IN ('CTRY_CD', 'CITY_CODE_OF_ID', 'BUS_ID_BRNCH');
            WHEN p_impr_type_cd = 4 THEN
                RETURN p_item IN ('CITY_CODE_OF_ID', 'BUS_ID_BRNCH')
                       OR (p_item = 'CTRY_CD' AND p_bus_id_type_cd IN (3, 5));
            WHEN p_impr_type_cd IN (7, 10) THEN
                RETURN p_item IN ('CITY_CODE_OF_ID', 'BUS_ID_BRNCH');
            WHEN p_impr_type_cd = 9 AND v_bus_id_type = 6 THEN
                RETURN p_item IN ('CTRY_CD', 'CITY_CODE_OF_ID', 'BUS_ID_BRNCH', 'BUS_ID');
            WHEN p_impr_type_cd = 9 THEN
                RETURN p_item = 'BUS_ID_BRNCH';
            WHEN p_impr_type_cd = 11 THEN
                RETURN p_item IN ('CTRY_CD', 'BUS_ID_BRNCH');
            WHEN p_impr_type_cd = 12 THEN
                RETURN p_item = 'CITY_CODE_OF_ID';
            -- 16, 17, 18, 20: WHEN-VALIDATE-ITEM only (POST-QUERY does not list them; difference kept)
            WHEN p_impr_type_cd IN (13, 14, 16, 17, 18, 20) THEN
                RETURN p_item IN ('CTRY_CD', 'CITY_CODE_OF_ID', 'BUS_ID_BRNCH', 'BUS_ID');
            ELSE
                RETURN FALSE;
        END CASE;
    END PRIVATE_IMPORTER_TYPE_LOCKED;

    -- Section: PRIVATE RULE HELPERS
    -- Group 3 of read_only_rules.md: the commercial register has exactly one row for the importer
    -- (only for BUS_ID_TYPE_CD = 2 and IMPR_TYPE_CD <> 12; same query as COMMERCIAL_REGISTER_NAME)
    FUNCTION PRIVATE_REGISTER_MATCHES (p_impr_type_cd      IN NUMBER,
                                       p_bus_id_type_cd    IN NUMBER,
                                       p_bus_id            IN VARCHAR2,
                                       p_bus_id_brnch      IN VARCHAR2,
                                       p_comm_rgstrtn_type IN NUMBER) RETURN BOOLEAN
    IS
        v_cnt NUMBER;
    BEGIN
        IF NOT (p_bus_id_type_cd = 2 AND NVL(p_impr_type_cd, 0) <> 12) OR p_bus_id IS NULL THEN
            RETURN FALSE;
        END IF;
        IF p_comm_rgstrtn_type = 2 THEN
            SELECT COUNT(bus_id) INTO v_cnt
              FROM comm_impr_rgstr
             WHERE bus_id = p_bus_id AND brnch_bus_id = p_bus_id_brnch;
        ELSE
            SELECT COUNT(bus_id) INTO v_cnt
              FROM comm_impr_rgstr
             WHERE bus_id = p_bus_id AND brnchreg = 0;
        END IF;
        RETURN v_cnt = 1;
    END PRIVATE_REGISTER_MATCHES;

    -- Section: ITEM IMPR_TYPE_CD
    -- Source: WNRI (saved-record lock, unlocked by IMPR1110F3), WHEN-CREATE-RECORD (PRSNL_IMPR = 1)
    -- APEX  : Read Only condition of P1110_IMPR_TYPE_CD (PL/SQL expression)
    FUNCTION IMPR_TYPE_CD_IS_READ_ONLY (I_P1110_IMPR_NBR     IN NUMBER,
                                        I_P1110_P_CODE       IN VARCHAR2,
                                        I_P1110_P_PRSNL_IMPR IN NUMBER) RETURN BOOLEAN
    IS
    BEGIN
        RETURN PRIVATE_SAVED_RECORD_LOCKED(I_P1110_IMPR_NBR, I_P1110_P_CODE, 'IMPR1110F3')
               OR (I_P1110_IMPR_NBR IS NULL AND I_P1110_P_PRSNL_IMPR = 1);
    END IMPR_TYPE_CD_IS_READ_ONLY;

    -- Section: ITEM BUS_ID_EXPRD_DT
    -- Source: WNRI (lock, unlocked by IMPR1110F4), BUS_ID / BUS_ID_BRNCH WHEN-VALIDATE-ITEM (register),
    --         PRE-INSERT (re-enabled while empty: the item is required)
    FUNCTION BUS_ID_EXPRD_DT_IS_READ_ONLY (I_P1110_IMPR_NBR          IN NUMBER,
                                           I_P1110_P_CODE            IN VARCHAR2,
                                           I_P1110_IMPR_TYPE_CD      IN NUMBER,
                                           I_P1110_BUS_ID_TYPE_CD    IN NUMBER,
                                           I_P1110_BUS_ID            IN VARCHAR2,
                                           I_P1110_BUS_ID_BRNCH      IN VARCHAR2,
                                           I_P1110_COMM_RGSTRTN_TYPE IN NUMBER,
                                           I_P1110_BUS_ID_EXPRD_DT   IN VARCHAR2) RETURN BOOLEAN
    IS
    BEGIN
        IF I_P1110_P_CODE = 'IMPR1110F4' THEN
            RETURN FALSE;
        END IF;
        RETURN PRIVATE_SAVED_RECORD_LOCKED(I_P1110_IMPR_NBR, I_P1110_P_CODE, 'IMPR1110F4')
               OR (I_P1110_BUS_ID_EXPRD_DT IS NOT NULL
                   AND PRIVATE_REGISTER_MATCHES(I_P1110_IMPR_TYPE_CD, I_P1110_BUS_ID_TYPE_CD, I_P1110_BUS_ID,
                                                I_P1110_BUS_ID_BRNCH, I_P1110_COMM_RGSTRTN_TYPE));
    END BUS_ID_EXPRD_DT_IS_READ_ONLY;

    -- Section: ITEM BUS_ID_EXPRD_DT
    -- Source: PRE-INSERT / PRE-UPDATE (required for BUS_ID_TYPE_CD = 2 and IMPR_TYPE_CD IN 1,3,5,6,8,12)
    FUNCTION BUS_ID_EXPRD_DT_IS_REQUIRED (I_P1110_IMPR_TYPE_CD   IN NUMBER,
                                          I_P1110_BUS_ID_TYPE_CD IN NUMBER) RETURN BOOLEAN
    IS
    BEGIN
        RETURN I_P1110_BUS_ID_TYPE_CD = 2 AND I_P1110_IMPR_TYPE_CD IN (1, 3, 5, 6, 8, 12);
    END BUS_ID_EXPRD_DT_IS_REQUIRED;

    -- Section: ITEM BUS_ID_TYPE_CD
    -- Source: WNRI (saved record: never unlocked)
    FUNCTION BUS_ID_TYPE_CD_IS_READ_ONLY (I_P1110_IMPR_NBR IN NUMBER) RETURN BOOLEAN
    IS
    BEGIN
        RETURN I_P1110_IMPR_NBR IS NOT NULL;
    END BUS_ID_TYPE_CD_IS_READ_ONLY;

    -- Section: ITEM COMM_RGSTRTN_TYPE
    -- Source: WNFI / WNRI (read-only by default), IMPR_TYPE_CD WHEN-VALIDATE-ITEM (editable for
    --         BUS_ID_TYPE_CD = 2 and IMPR_TYPE_CD <> 12), WNRI (saved record, unlocked by IMPR1110F2)
    FUNCTION COMM_RGSTRTN_TYPE_IS_READ_ONLY (I_P1110_IMPR_NBR       IN NUMBER,
                                             I_P1110_P_CODE         IN VARCHAR2,
                                             I_P1110_IMPR_TYPE_CD   IN NUMBER,
                                             I_P1110_BUS_ID_TYPE_CD IN NUMBER) RETURN BOOLEAN
    IS
    BEGIN
        RETURN PRIVATE_SAVED_RECORD_LOCKED(I_P1110_IMPR_NBR, I_P1110_P_CODE, 'IMPR1110F2')
               OR NOT (I_P1110_BUS_ID_TYPE_CD = 2 AND NVL(I_P1110_IMPR_TYPE_CD, 0) <> 12);
    END COMM_RGSTRTN_TYPE_IS_READ_ONLY;

    -- Section: ITEM COMM_RGSTRTN_TYPE
    -- Source: IMPR_TYPE_CD WHEN-VALIDATE-ITEM (REQUIRED TRUE), PRE-INSERT / PRE-UPDATE error 9-240
    FUNCTION COMM_RGSTRTN_TYPE_IS_REQUIRED (I_P1110_IMPR_TYPE_CD   IN NUMBER,
                                            I_P1110_BUS_ID_TYPE_CD IN NUMBER) RETURN BOOLEAN
    IS
    BEGIN
        RETURN I_P1110_BUS_ID_TYPE_CD = 2 AND NVL(I_P1110_IMPR_TYPE_CD, 0) <> 12;
    END COMM_RGSTRTN_TYPE_IS_REQUIRED;

    -- Section: ITEM CITY_CODE_OF_ID
    -- Source: importer type table (group 2), WNRI (lock, unlocked by IMPR1110F2).
    --         WHEN-CREATE-RECORD with PRSNL_IMPR = 1 sets IMPR_TYPE_CD = 4 -> covered by the type table.
    FUNCTION CITY_CODE_OF_ID_IS_READ_ONLY (I_P1110_IMPR_NBR       IN NUMBER,
                                           I_P1110_P_CODE         IN VARCHAR2,
                                           I_P1110_IMPR_TYPE_CD   IN NUMBER,
                                           I_P1110_BUS_ID_TYPE_CD IN NUMBER) RETURN BOOLEAN
    IS
    BEGIN
        RETURN PRIVATE_SAVED_RECORD_LOCKED(I_P1110_IMPR_NBR, I_P1110_P_CODE, 'IMPR1110F2')
               OR PRIVATE_IMPORTER_TYPE_LOCKED('CITY_CODE_OF_ID', I_P1110_IMPR_TYPE_CD, I_P1110_BUS_ID_TYPE_CD);
    END CITY_CODE_OF_ID_IS_READ_ONLY;

    -- Section: ITEM CITY_CODE_OF_ID
    -- Source: IMPR_TYPE_CD POST-CHANGE (REQUIRED TRUE for IMPR_TYPE_CD IN 1,3,5,6,8,19)
    FUNCTION CITY_CODE_OF_ID_IS_REQUIRED (I_P1110_IMPR_TYPE_CD IN NUMBER) RETURN BOOLEAN
    IS
    BEGIN
        RETURN I_P1110_IMPR_TYPE_CD IN (1, 3, 5, 6, 8, 19);
    END CITY_CODE_OF_ID_IS_REQUIRED;

    -- Section: ITEM BUS_ID
    -- Source: importer type table (group 2), WNRI (lock, unlocked by IMPR1110F2)
    FUNCTION BUS_ID_IS_READ_ONLY (I_P1110_IMPR_NBR       IN NUMBER,
                                  I_P1110_P_CODE         IN VARCHAR2,
                                  I_P1110_IMPR_TYPE_CD   IN NUMBER,
                                  I_P1110_BUS_ID_TYPE_CD IN NUMBER) RETURN BOOLEAN
    IS
    BEGIN
        RETURN PRIVATE_SAVED_RECORD_LOCKED(I_P1110_IMPR_NBR, I_P1110_P_CODE, 'IMPR1110F2')
               OR PRIVATE_IMPORTER_TYPE_LOCKED('BUS_ID', I_P1110_IMPR_TYPE_CD, I_P1110_BUS_ID_TYPE_CD);
    END BUS_ID_IS_READ_ONLY;

    -- Section: ITEM BRNH_CITY_CD
    -- Source: COMM_RGSTRTN_TYPE WHEN-LIST-CHANGED (1 = read-only, 2 = editable), WNRI (lock, IMPR1110F2)
    -- TODO-VERIFY: value NULL (no registration type) is treated as editable
    FUNCTION BRNH_CITY_CD_IS_READ_ONLY (I_P1110_IMPR_NBR          IN NUMBER,
                                        I_P1110_P_CODE            IN VARCHAR2,
                                        I_P1110_COMM_RGSTRTN_TYPE IN NUMBER) RETURN BOOLEAN
    IS
    BEGIN
        RETURN PRIVATE_SAVED_RECORD_LOCKED(I_P1110_IMPR_NBR, I_P1110_P_CODE, 'IMPR1110F2')
               OR I_P1110_COMM_RGSTRTN_TYPE = 1;
    END BRNH_CITY_CD_IS_READ_ONLY;

    -- Section: ITEM BRNH_CITY_CD
    -- Source: COMM_RGSTRTN_TYPE WHEN-LIST-CHANGED (REQUIRED for type 2)
    FUNCTION BRNH_CITY_CD_IS_REQUIRED (I_P1110_COMM_RGSTRTN_TYPE IN NUMBER) RETURN BOOLEAN
    IS
    BEGIN
        RETURN I_P1110_COMM_RGSTRTN_TYPE = 2;
    END BRNH_CITY_CD_IS_REQUIRED;

    -- Section: ITEM BUS_ID_BRNCH
    -- Source: importer type table (group 2), COMM_RGSTRTN_TYPE WHEN-LIST-CHANGED, WNRI (lock, IMPR1110F2)
    FUNCTION BUS_ID_BRNCH_IS_READ_ONLY (I_P1110_IMPR_NBR          IN NUMBER,
                                        I_P1110_P_CODE            IN VARCHAR2,
                                        I_P1110_IMPR_TYPE_CD      IN NUMBER,
                                        I_P1110_BUS_ID_TYPE_CD    IN NUMBER,
                                        I_P1110_COMM_RGSTRTN_TYPE IN NUMBER) RETURN BOOLEAN
    IS
    BEGIN
        RETURN PRIVATE_SAVED_RECORD_LOCKED(I_P1110_IMPR_NBR, I_P1110_P_CODE, 'IMPR1110F2')
               OR PRIVATE_IMPORTER_TYPE_LOCKED('BUS_ID_BRNCH', I_P1110_IMPR_TYPE_CD, I_P1110_BUS_ID_TYPE_CD)
               OR I_P1110_COMM_RGSTRTN_TYPE = 1;
    END BUS_ID_BRNCH_IS_READ_ONLY;

    -- Section: ITEM BUS_ID_BRNCH
    -- Source: COMM_RGSTRTN_TYPE WHEN-LIST-CHANGED / BRNH_CITY_CD WHEN-NEW-ITEM-INSTANCE (REQUIRED for
    --         type 2 unless BUS_ID or CITY_CODE_OF_ID is empty)
    FUNCTION BUS_ID_BRNCH_IS_REQUIRED (I_P1110_COMM_RGSTRTN_TYPE IN NUMBER,
                                       I_P1110_BUS_ID            IN VARCHAR2,
                                       I_P1110_CITY_CODE_OF_ID   IN NUMBER) RETURN BOOLEAN
    IS
    BEGIN
        RETURN I_P1110_COMM_RGSTRTN_TYPE = 2
               AND I_P1110_BUS_ID IS NOT NULL AND I_P1110_CITY_CODE_OF_ID IS NOT NULL;
    END BUS_ID_BRNCH_IS_REQUIRED;

    -- Section: ITEM CTRY_CD
    -- Source: importer type table (group 2)
    FUNCTION CTRY_CD_IS_READ_ONLY (I_P1110_IMPR_TYPE_CD   IN NUMBER,
                                   I_P1110_BUS_ID_TYPE_CD IN NUMBER) RETURN BOOLEAN
    IS
    BEGIN
        RETURN PRIVATE_IMPORTER_TYPE_LOCKED('CTRY_CD', I_P1110_IMPR_TYPE_CD, I_P1110_BUS_ID_TYPE_CD);
    END CTRY_CD_IS_READ_ONLY;

    -- Section: ITEM IMPR_EXPR_TYPE
    -- Source: WNRI (saved record: never unlocked), WHEN-CREATE-RECORD / BROKER_INT (brokers: class 1, type 3)
    FUNCTION IMPR_EXPR_TYPE_IS_READ_ONLY (I_P1110_IMPR_NBR IN NUMBER,
                                          I_P_CLASS_CD     IN NUMBER,
                                          I_V_USR_TYPE     IN NUMBER) RETURN BOOLEAN
    IS
    BEGIN
        RETURN I_P1110_IMPR_NBR IS NOT NULL OR (I_P_CLASS_CD = 1 AND I_V_USR_TYPE = 3);
    END IMPR_EXPR_TYPE_IS_READ_ONLY;

    -- Section: ITEM ARBC_IMPR_NAME
    -- Source: WNRI (lock, unlocked by IMPR1110F1 / IMPR1110F5), BUS_ID / BUS_ID_BRNCH WHEN-VALIDATE-ITEM
    --         (one register row -> the name comes from the register)
    FUNCTION ARBC_IMPR_NAME_IS_READ_ONLY (I_P1110_IMPR_NBR          IN NUMBER,
                                          I_P1110_P_CODE            IN VARCHAR2,
                                          I_P1110_IMPR_TYPE_CD      IN NUMBER,
                                          I_P1110_BUS_ID_TYPE_CD    IN NUMBER,
                                          I_P1110_BUS_ID            IN VARCHAR2,
                                          I_P1110_BUS_ID_BRNCH      IN VARCHAR2,
                                          I_P1110_COMM_RGSTRTN_TYPE IN NUMBER) RETURN BOOLEAN
    IS
    BEGIN
        IF I_P1110_P_CODE IN ('IMPR1110F1', 'IMPR1110F5') THEN
            RETURN FALSE;
        END IF;
        RETURN I_P1110_IMPR_NBR IS NOT NULL
               OR PRIVATE_REGISTER_MATCHES(I_P1110_IMPR_TYPE_CD, I_P1110_BUS_ID_TYPE_CD, I_P1110_BUS_ID,
                                           I_P1110_BUS_ID_BRNCH, I_P1110_COMM_RGSTRTN_TYPE);
    END ARBC_IMPR_NAME_IS_READ_ONLY;

    -- Section: ITEM IMPR_TEL_NBR
    -- Source: BUS_ID / BUS_ID_BRNCH WHEN-VALIDATE-ITEM (group 3: IMPR_POB_NBR, IMPR_ZIP_CD, IMPR_TEL_NBR,
    --         IMPR_FAX_NBR, IMPR_TELEX_NBR come from the register). Pass the item value in I_VALUE for
    --         IMPR_TEL_NBR (PRE-INSERT re-enables it while empty); the other items keep the default.
    FUNCTION REGISTER_ITEMS_IS_READ_ONLY (I_P1110_IMPR_TYPE_CD      IN NUMBER,
                                          I_P1110_BUS_ID_TYPE_CD    IN NUMBER,
                                          I_P1110_BUS_ID            IN VARCHAR2,
                                          I_P1110_BUS_ID_BRNCH      IN VARCHAR2,
                                          I_P1110_COMM_RGSTRTN_TYPE IN NUMBER,
                                          I_VALUE                   IN VARCHAR2 DEFAULT 'X') RETURN BOOLEAN
    IS
    BEGIN
        RETURN I_VALUE IS NOT NULL
               AND PRIVATE_REGISTER_MATCHES(I_P1110_IMPR_TYPE_CD, I_P1110_BUS_ID_TYPE_CD, I_P1110_BUS_ID,
                                            I_P1110_BUS_ID_BRNCH, I_P1110_COMM_RGSTRTN_TYPE);
    END REGISTER_ITEMS_IS_READ_ONLY;

    -- Section: ITEM ACTIVITY
    -- Source: BUS_ID WHEN-VALIDATE-ITEM (final rule: editable when BUS_ID is set and ACTIVITY is empty)
    FUNCTION ACTIVITY_IS_READ_ONLY (I_P1110_BUS_ID   IN VARCHAR2,
                                    I_P1110_ACTIVITY IN VARCHAR2) RETURN BOOLEAN
    IS
    BEGIN
        RETURN NOT (I_P1110_BUS_ID IS NOT NULL AND I_P1110_ACTIVITY IS NULL);
    END ACTIVITY_IS_READ_ONLY;

    -- Section: ITEM ACTIVITY
    -- Source: PRE-INSERT (ACTIVITY must be entered while it is editable)
    FUNCTION ACTIVITY_IS_REQUIRED (I_P1110_BUS_ID IN VARCHAR2) RETURN BOOLEAN
    IS
    BEGIN
        RETURN I_P1110_BUS_ID IS NOT NULL;
    END ACTIVITY_IS_REQUIRED;

    -- Section: ITEM B_ID_NBR
    -- Source: IMPR_TYPE_CD WHEN-VALIDATE-ITEM (type 4 with BUS_ID_TYPE_CD 5)
    FUNCTION B_ID_NBR_IS_READ_ONLY (I_P1110_IMPR_TYPE_CD   IN NUMBER,
                                    I_P1110_BUS_ID_TYPE_CD IN NUMBER) RETURN BOOLEAN
    IS
    BEGIN
        RETURN I_P1110_IMPR_TYPE_CD = 4 AND I_P1110_BUS_ID_TYPE_CD = 5;
    END B_ID_NBR_IS_READ_ONLY;

    -- Section: ITEM CAR_AGENT_FLAG
    -- Source: WNRI (editable only in mode IMPR1110SF6 on a saved record; spec "SEL only")
    FUNCTION CAR_AGENT_FLAG_IS_READ_ONLY (I_P1110_IMPR_NBR IN NUMBER,
                                          I_P1110_P_CODE   IN VARCHAR2) RETURN BOOLEAN
    IS
    BEGIN
        RETURN NOT (I_P1110_IMPR_NBR IS NOT NULL AND I_P1110_P_CODE = 'IMPR1110SF6');
    END CAR_AGENT_FLAG_IS_READ_ONLY;

    -- Section: ITEM EXPRESS_POST
    -- Source: BROKER_INT (brokers: value 2 and read-only)
    FUNCTION EXPRESS_POST_IS_READ_ONLY (I_P_CLASS_CD IN NUMBER,
                                        I_V_USR_TYPE IN NUMBER) RETURN BOOLEAN
    IS
    BEGIN
        RETURN I_P_CLASS_CD = 1 AND I_V_USR_TYPE = 3;
    END EXPRESS_POST_IS_READ_ONLY;

    -- Section: ITEM CITY_CODE
    -- Source: IMPORTERS.POST-QUERY (CR-6730: WASL city replaces CITY_CODE / CITY_NAME when it exists)
    -- APEX  : Server-side condition of P1110_WASL_CITY_NAME (shown) and P1110_CITY_CODE / CITY_NAME (not shown)
    FUNCTION WASL_CITY_IS_SHOWN (I_P_CURR_PORT_CD       IN NUMBER,
                                 I_P1110_WASL_CITY_NAME IN VARCHAR2) RETURN BOOLEAN
    IS
    BEGIN
        RETURN I_P1110_WASL_CITY_NAME IS NOT NULL
               AND NVL(gnrl.get_customs_setting(I_P_CURR_PORT_CD, 'CR-6730', 9), 0) = 1;
    END WASL_CITY_IS_SHOWN;

    -- Section: f345 HELPERS
    -- Read-only flags of the items whose rule can change while the page is open (after a change of
    -- IMPR_TYPE_CD, BUS_ID_TYPE_CD, COMM_RGSTRTN_TYPE, BUS_ID, BUS_ID_BRNCH, IMPR_TEL_NBR, ACTIVITY, or a
    -- function mode set by EXEC_FUNS). APEX renders a Read Only item as text, which native Enable cannot
    -- undo, so these items use flags instead of a Read Only condition.
    -- APEX  : Before Header process "READ ONLY FLAGS" and the last FOS action of the DAs above
    --         (Items to Return = P1110_<ITEM>_LOCKED, change events on); DA "<ITEM> READ ONLY" on change of
    --         P1110_<ITEM>_LOCKED: Disable when Y, else Enable (fire on initialization).
    PROCEDURE READ_ONLY_FLAGS (I_P1110_IMPR_NBR           IN  NUMBER,
                               I_P1110_P_CODE             IN  VARCHAR2,
                               I_P1110_P_PRSNL_IMPR       IN  NUMBER,
                               I_P1110_IMPR_TYPE_CD       IN  NUMBER,
                               I_P1110_BUS_ID_TYPE_CD     IN  NUMBER,
                               I_P1110_COMM_RGSTRTN_TYPE  IN  NUMBER,
                               I_P1110_BUS_ID             IN  VARCHAR2,
                               I_P1110_BUS_ID_BRNCH       IN  VARCHAR2,
                               I_P1110_BUS_ID_EXPRD_DT    IN  VARCHAR2,
                               I_P1110_IMPR_TEL_NBR       IN  VARCHAR2,
                               I_P1110_ACTIVITY           IN  VARCHAR2,
                               O_IMPR_TYPE_CD_LOCKED      OUT VARCHAR2,
                               O_BUS_ID_EXPRD_DT_LOCKED   OUT VARCHAR2,
                               O_COMM_RGSTRTN_TYPE_LOCKED OUT VARCHAR2,
                               O_CITY_CODE_OF_ID_LOCKED   OUT VARCHAR2,
                               O_BUS_ID_LOCKED            OUT VARCHAR2,
                               O_BRNH_CITY_CD_LOCKED      OUT VARCHAR2,
                               O_BUS_ID_BRNCH_LOCKED      OUT VARCHAR2,
                               O_CTRY_CD_LOCKED           OUT VARCHAR2,
                               O_ARBC_IMPR_NAME_LOCKED    OUT VARCHAR2,
                               O_REGISTER_ITEMS_LOCKED    OUT VARCHAR2,
                               O_IMPR_TEL_NBR_LOCKED      OUT VARCHAR2,
                               O_ACTIVITY_LOCKED          OUT VARCHAR2,
                               O_B_ID_NBR_LOCKED          OUT VARCHAR2,
                               O_CAR_AGENT_FLAG_LOCKED    OUT VARCHAR2)
    IS
        FUNCTION YES_NO (p_flag IN BOOLEAN) RETURN VARCHAR2 IS
        BEGIN
            RETURN CASE WHEN p_flag THEN 'Y' ELSE 'N' END;
        END YES_NO;
    BEGIN
        O_IMPR_TYPE_CD_LOCKED      := YES_NO(IMPR_TYPE_CD_IS_READ_ONLY(I_P1110_IMPR_NBR, I_P1110_P_CODE,
                                                 I_P1110_P_PRSNL_IMPR));
        O_BUS_ID_EXPRD_DT_LOCKED   := YES_NO(BUS_ID_EXPRD_DT_IS_READ_ONLY(I_P1110_IMPR_NBR, I_P1110_P_CODE,
                                                 I_P1110_IMPR_TYPE_CD, I_P1110_BUS_ID_TYPE_CD, I_P1110_BUS_ID,
                                                 I_P1110_BUS_ID_BRNCH, I_P1110_COMM_RGSTRTN_TYPE,
                                                 I_P1110_BUS_ID_EXPRD_DT));
        O_COMM_RGSTRTN_TYPE_LOCKED := YES_NO(COMM_RGSTRTN_TYPE_IS_READ_ONLY(I_P1110_IMPR_NBR, I_P1110_P_CODE,
                                                 I_P1110_IMPR_TYPE_CD, I_P1110_BUS_ID_TYPE_CD));
        O_CITY_CODE_OF_ID_LOCKED   := YES_NO(CITY_CODE_OF_ID_IS_READ_ONLY(I_P1110_IMPR_NBR, I_P1110_P_CODE,
                                                 I_P1110_IMPR_TYPE_CD, I_P1110_BUS_ID_TYPE_CD));
        O_BUS_ID_LOCKED            := YES_NO(BUS_ID_IS_READ_ONLY(I_P1110_IMPR_NBR, I_P1110_P_CODE,
                                                 I_P1110_IMPR_TYPE_CD, I_P1110_BUS_ID_TYPE_CD));
        O_BRNH_CITY_CD_LOCKED      := YES_NO(BRNH_CITY_CD_IS_READ_ONLY(I_P1110_IMPR_NBR, I_P1110_P_CODE,
                                                 I_P1110_COMM_RGSTRTN_TYPE));
        O_BUS_ID_BRNCH_LOCKED      := YES_NO(BUS_ID_BRNCH_IS_READ_ONLY(I_P1110_IMPR_NBR, I_P1110_P_CODE,
                                                 I_P1110_IMPR_TYPE_CD, I_P1110_BUS_ID_TYPE_CD,
                                                 I_P1110_COMM_RGSTRTN_TYPE));
        O_CTRY_CD_LOCKED           := YES_NO(CTRY_CD_IS_READ_ONLY(I_P1110_IMPR_TYPE_CD, I_P1110_BUS_ID_TYPE_CD));
        O_ARBC_IMPR_NAME_LOCKED    := YES_NO(ARBC_IMPR_NAME_IS_READ_ONLY(I_P1110_IMPR_NBR, I_P1110_P_CODE,
                                                 I_P1110_IMPR_TYPE_CD, I_P1110_BUS_ID_TYPE_CD, I_P1110_BUS_ID,
                                                 I_P1110_BUS_ID_BRNCH, I_P1110_COMM_RGSTRTN_TYPE));
        O_REGISTER_ITEMS_LOCKED    := YES_NO(REGISTER_ITEMS_IS_READ_ONLY(I_P1110_IMPR_TYPE_CD,
                                                 I_P1110_BUS_ID_TYPE_CD, I_P1110_BUS_ID, I_P1110_BUS_ID_BRNCH,
                                                 I_P1110_COMM_RGSTRTN_TYPE));
        O_IMPR_TEL_NBR_LOCKED      := YES_NO(REGISTER_ITEMS_IS_READ_ONLY(I_P1110_IMPR_TYPE_CD,
                                                 I_P1110_BUS_ID_TYPE_CD, I_P1110_BUS_ID, I_P1110_BUS_ID_BRNCH,
                                                 I_P1110_COMM_RGSTRTN_TYPE, I_P1110_IMPR_TEL_NBR));
        O_ACTIVITY_LOCKED          := YES_NO(ACTIVITY_IS_READ_ONLY(I_P1110_BUS_ID, I_P1110_ACTIVITY));
        O_B_ID_NBR_LOCKED          := YES_NO(B_ID_NBR_IS_READ_ONLY(I_P1110_IMPR_TYPE_CD, I_P1110_BUS_ID_TYPE_CD));
        O_CAR_AGENT_FLAG_LOCKED    := YES_NO(CAR_AGENT_FLAG_IS_READ_ONLY(I_P1110_IMPR_NBR, I_P1110_P_CODE));
    END READ_ONLY_FLAGS;
