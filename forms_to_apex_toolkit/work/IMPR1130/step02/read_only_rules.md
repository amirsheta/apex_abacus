# IMPR1130 — read-only / required rules (step 02)

Derived from the 181 `INTRFACE.Make_Field_Entrable` and 42 `SET_ITEM_PROPERTY` calls of IMPR1130 (they differ
from IMPR1110: no function modes, other type tables). `Make_Field_Entrable(x, FALSE)` = not enabled / navigable /
insertable / updatable (`CIC_LIB.pld`) = APEX **read-only**. Forms item properties last until the next call, so the
state depends on the order the triggers fired. The table is the state Forms leaves at the moments that matter:

- **new record** (`P1130_ROW_ID` null): WHEN-CREATE-RECORD → WHEN-NEW-FORM-INSTANCE (first record) →
  WHEN-NEW-RECORD-INSTANCE, then the item triggers in navigation order (IMPR_TYPE_CD → … → COMM_RGSTRTN_TYPE →
  NATIONAL_NBR → BUS_ID → BUS_ID_BRNCH);
- **saved record** (`P1130_ROW_ID` not null): POST-QUERY → WHEN-NEW-RECORD-INSTANCE, after the block was entered
  (WHEN-CREATE-RECORD made everything enabled first). IMPR_TYPE_CD, CTRY_CD and CITY_CODE_OF_ID have
  `UpdateAllowed = false`, so their WHEN-VALIDATE-ITEM never runs on a saved record.

Interpretations (no single Forms state exists; recorded for review):
1. The PRE-INSERT locks (BUS_ID, BUS_ID_BRNCH, BUS_ID_EXPRD_DT, ARBC_IMPR_NAME, COMM_RGSTRTN_TYPE, CITY_CODE_OF_ID,
   BUS_ID_TYPE_CD, IMPR_EXPR_TYPE, IMPR_TYPE_CD) and the block `UPDATE_ALLOWED = false` stay for the rest of a Forms
   session. In APEX a created importer is shown again as a saved record and gets the saved-record rules.
2. COMM_RGSTRTN_TYPE.WHEN-LIST-CHANGED on a saved record clears BUS_ID_BRNCH for type 1 but the branch rule of
   WHEN-NEW-RECORD-INSTANCE stays (the list change is not distinguishable from the queried value).
3. "Data from the Ministry of Commerce" (IMPR_TYPE_CD WVI, first branch): identity type 2, activity type ≠ 12,
   `G_ALLOW_MCI = 1`. GET_CR_DATA marks a fetched record with `CREATION_FLAG = 3`; that value locks BUS_ID /
   BUS_ID_BRNCH on a new record (Forms SET_ITEM_PROPERTY INSERT / UPDATE_ALLOWED false).
4. "Register unlocked" (BUS_ID / BUS_ID_BRNCH WVI, COMM_TABLE_UNCHECK branch): identity type 2, activity type ≠ 12,
   the number (and the branch for type 2) is entered and `COMM_IMPR_RGSTR` has no row for it. The validation already
   refused the number when the setting does not allow that (9-190).

## Rules (Y = read-only)

| Item | New record | Saved record | Function |
|---|---|---|---|
| PORT_CD | always (value `P_CURR_PORT_CD`) | always | static Read Only |
| IMPR_NBR | editable (query by number) | Y (`UpdateAllowed = false`) | `IMPR_NBR_IS_READ_ONLY` |
| IMPR_TYPE_CD | Y when `PRSNL_IMPR = 1` (WCR) | Y | `IMPR_TYPE_CD_IS_READ_ONLY` |
| BUS_ID_TYPE_CD | editable through its LOV (OLB `CGSO$CHAR_ARB_DO`, insert allowed) | Y | `BUS_ID_TYPE_CD_IS_READ_ONLY` |
| BUS_ID_EXPRD_DT | Y while IMPR_TYPE_CD is empty (WNRI); Y with Ministry data while it has a value, unless register unlocked; else editable | Y (WNRI) | `BUS_ID_EXPRD_DT_IS_READ_ONLY` |
| COMM_RGSTRTN_TYPE | editable while IMPR_TYPE_CD is empty (WCR); then Y unless identity type 2 | editable | `COMM_RGSTRTN_TYPE_IS_READ_ONLY`; required (new, identity type 2): `COMM_RGSTRTN_TYPE_IS_REQUIRED` |
| CTRY_CD | Y for types 1, 2, 5, 8, 11, 14, 16, 17, 18, 20 and 9 with identity type 6 (or empty → 6) | Y for types 1, 2, 5, 8, 11, 13, 14 and 9 / 6 (POST-QUERY table) | `CTRY_CD_IS_READ_ONLY` |
| ADD_CTRY_CD | Y unless type 21 with identity type 19 (WNFI disables it, value 100) | POST-QUERY table as CTRY_CD | `ADD_CTRY_CD_IS_READ_ONLY` |
| CITY_CODE_OF_ID | Y unless type 9 with identity type ≠ 6 (WNRI FALSE, type WVI) | Y (WNRI) | `CITY_CODE_OF_ID_IS_READ_ONLY` |
| BUS_ID | Y when `CREATION_FLAG = 3`, type 9 / 6, types 16, 17, 18, 20 (number from a sequence) | Y for type 9 / 6, 13, 14 | `BUS_ID_IS_READ_ONLY` |
| BUS_ID_BRNCH | Y when `CREATION_FLAG = 3`; COMM_RGSTRTN_TYPE 1 → Y, 2 → editable; otherwise Y for `PRSNL_IMPR = 1` and types 2, 4, 7, 9, 10, 11, 16, 17, 18, 20 | Y unless identity type 2 and type 1 (WNRI) | `BUS_ID_BRNCH_IS_READ_ONLY` |
| ARBC_IMPR_NAME, ENG_IMPR_NAME | editable | Y when the importer has declarations (WNRI) | `ARBC_IMPR_NAME_IS_READ_ONLY`, `ENG_IMPR_NAME_IS_READ_ONLY` |
| IMPR_POB_NBR, IMPR_ZIP_CD, IMPR_FAX_NBR, IMPR_TELEX_NBR | Y with Ministry data unless register unlocked | editable | `REGISTER_ITEMS_IS_READ_ONLY` |
| IMPR_TEL_NBR, NATIONAL_NBR, EMAIL, MOBILE_NO, IMPR_EXPR_TYPE, CAR_AGENT_FLAG, EXPRESS_POST, names, address | editable | editable | – |

Items whose rule can change while the page is open get a flag: `READ_ONLY_FLAGS` returns `P1130_<ITEM>_LOCKED`
(Y / N) for COMM_RGSTRTN_TYPE, CTRY_CD, ADD_CTRY_CD, CITY_CODE_OF_ID, BUS_ID, BUS_ID_BRNCH, BUS_ID_EXPRD_DT and
REGISTER_ITEMS, from the Before Header process and the last FOS action of the DAs of IMPR_TYPE_CD, BUS_ID_TYPE_CD,
COMM_RGSTRTN_TYPE, CITY_CODE_OF_ID, NATIONAL_NBR, BUS_ID, BUS_ID_BRNCH (the IMPR1110 design: a native Read Only
condition renders text that Enable cannot undo). IMPR_NBR, IMPR_TYPE_CD, BUS_ID_TYPE_CD, ARBC_IMPR_NAME and
ENG_IMPR_NAME depend only on values that do not change while the page is open: plain Read Only conditions.

## Required (besides the static `Required` of the XML)

| Item | Rule | Source |
|---|---|---|
| COMM_RGSTRTN_TYPE | new record, identity type 2 | IMPR_TYPE_CD WVI / BUS_ID WVI `SET_ITEM_PROPERTY(REQUIRED, TRUE)` |
| CITY_CODE_OF_ID | never (WNRI sets REQUIRED false) | WHEN-NEW-RECORD-INSTANCE |
| BUS_ID_EXPRD_DT, IMPR_TEL_NBR, MOBILE_NO | on insert | PRE-INSERT (9-220, messages) |
| IMPR_TEL_NBR, MOBILE_NO, CITY_CODE | always (their WVI raise when empty) | item WVI |

Static `Required` in the XML: PORT_CD, IMPR_TYPE_CD, BUS_ID_TYPE_CD, CTRY_CD, NATIONAL_NBR, BUS_ID, ARBC_IMPR_NAME,
ADD_CTRY_CD, CAR_AGENT_FLAG, IMPR_EXPR_TYPE (OLB `CGSO$POP_MD`).
