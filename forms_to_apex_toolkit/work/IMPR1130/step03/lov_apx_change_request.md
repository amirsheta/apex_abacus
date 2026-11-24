# LOV_APX change request from IMPR1130 (not applied)

**Why not applied:** on 2026-11-24 `plsql_templates/lov_apx.sql` had uncommitted changes of another session (IMPR1140,
version 002). Changing it from this session could overwrite that work. Apply this with the next LOV_APX version.

**Need:** IMPR1130 `CTRY_CD.KEY-LISTVAL` opens the Gulf list (`LOV_COUNTRIES_GULF`) for
`(IMPR_TYPE_CD = 4 AND BUS_ID_TYPE_CD = 16) OR IMPR_TYPE_CD = 12`; IMPR1110 only for the first condition.
`LOV_APX.GULF_COUNTRIES` implements the IMPR1110 rule.

**Change (CLAUDE.md §4d.2: a parameter, not a copy):**

```sql
-- spec
    FUNCTION GULF_COUNTRIES (P_IMPORTER_TYPE_ITEM      IN VARCHAR2,
                             P_BUSINESS_ID_TYPE_ITEM   IN VARCHAR2,
                             P_GULF_FOR_TYPE_12        IN BOOLEAN DEFAULT FALSE)
       RETURN VARCHAR2;
-- body: the Gulf condition
       V_GULF VARCHAR2 (200) := V_IMPORTER_TYPE || ' = 4 AND ' || V_BUSINESS_ID_TYPE || ' = 16';
    BEGIN
       IF P_GULF_FOR_TYPE_12 THEN
          V_GULF := '(' || V_GULF || ') OR ' || V_IMPORTER_TYPE || ' = 12';
       END IF;
       RETURN    'SELECT ctry_cd d, ctry_cd r, crty_arbc_name FROM countries'
              || ' WHERE ((' || V_GULF || ') AND ctry_cd IN (113, 116, 117, 119, 120, 100))'
              || ' OR (NOT (NVL(' || V_IMPORTER_TYPE || ', 0) = 4 AND NVL(' || V_BUSINESS_ID_TYPE || ', 0) = 16)'
              ||        CASE WHEN P_GULF_FOR_TYPE_12 THEN ' AND NVL(' || V_IMPORTER_TYPE || ', 0) <> 12' END
              ||        ' AND ctry_status = 1)'
              || ' ORDER BY ctry_cd';
```

Then: raise LOV_APX to the next version (previous version under `rollback/LOV_APX/v<nnn>/`), and in
`work/IMPR1130/step03/build_design.py` add `P_GULF_FOR_TYPE_12=True` to the `LOV_IMPR1130_COUNTRIES_GULF` call;
re-run `build_design.py`, `build_spec.py` and `scripts/gen_apex_impr1130.py` (its `lov_apx.check` verifies the new
parameter exists). IMPR1110's LOV is unchanged (default FALSE).

**Until then:** type 12 shows every active country; `IMPR1130.CTRY_CD_VALIDATION` refuses a country outside the GCC
group (`CTRY_GROUP_DETAILS`, message 'لابد أن تكون دولة المستورد الخليجي تابعة لدول مجلس التعاون'), so no wrong data
can be saved.
