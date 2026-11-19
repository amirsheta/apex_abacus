# IMPR1110 — read-only / required / visible rules (step 02 rev 2)

Derived from the 201 `INTRFACE.Make_Field_Entrable` and 82 `SET_ITEM_PROPERTY` calls (skeletons in
`entrable_skeletons.txt`). Make_Field_Entrable(x, FALSE) = not enabled / navigable / insertable / updateable
(`CIC_LIB.pld`) = APEX **Read Only**. Below is the NET state Forms leaves, as a pure function of current values.

Inputs (all page items, passed as I_ parameters):
- `IMPR_NBR` — record saved (Forms WNRI: `IMPR_NBR IS NOT NULL`)
- `P_CODE` — function mode (Forms `:PARAMETER.CODE`, set by EXEC_FUNS; Forms resets the parameter after WNRI but
  the item properties stay until the next record → in APEX the page item `P1110_P_CODE` keeps the mode until the
  record is saved, cleared or queried)
- `IMPR_TYPE_CD`, `BUS_ID_TYPE_CD`, `COMM_RGSTRTN_TYPE`, `BUS_ID`, `BUS_ID_BRNCH`, `ACTIVITY`
- `PRSNL_IMPR` (Forms parameter), user class / type (`P_CLASS_CD`, `V_USR_TYPE`)
- register match (DB): `COMM_IMPR_RGSTR` has exactly one row for BUS_ID (type 1, BRNCHREG = 0) or
  BUS_ID + BUS_ID_BRNCH (type 2)

## Group 1 — saved-record lock (WNRI `IMPR_NBR NOT NULL`, POST-INSERT, POST-UPDATE)
Read-only when `IMPR_NBR` is not null, unless the function mode unlocks the item:

| Item | Unlocked by |
|---|---|
| BUS_ID, BUS_ID_BRNCH, BRNH_CITY_CD, CITY_CODE_OF_ID, COMM_RGSTRTN_TYPE | IMPR1110F2 |
| ARBC_IMPR_NAME | IMPR1110F1 / IMPR1110F5 (when the register gives no single name, or the user keeps his own) |
| IMPR_TYPE_CD | IMPR1110F3 |
| BUS_ID_EXPRD_DT | IMPR1110F4 |
| CAR_AGENT_FLAG | IMPR1110SF6 (also read-only on new records: spec "SEL only") |
| BUS_ID_TYPE_CD, IMPR_EXPR_TYPE | never |

## Group 2 — importer type table (IMPR_TYPE_CD WVI = POST-QUERY, + "CTRY 100" block)
R = read-only, – = not changed by this rule.

| IMPR_TYPE_CD | CTRY_CD | CITY_CODE_OF_ID | BUS_ID_BRNCH | BUS_ID |
|---|---|---|---|---|
| 1, 5, 8 | R | – | – | – |
| 2 | R | R | R | – |
| 4 | R if BUS_ID_TYPE_CD in (3, 5) | R | R | – |
| 7, 10 | – | R | R | – |
| 9, BUS_ID_TYPE_CD = 6 (or null → 6) | R | R | R | R |
| 9, other | editable | editable | R | editable |
| 11 | R | – | R | – |
| 12 | – | R | – | – |
| 13, 14 | R | R | R | R |
| 16, 17, 18, 20 | R | R | R | R (WVI only — POST-QUERY does not list them: difference kept, flagged) |

ADD_CTRY_CD: always read-only (value 100; the "CTRY 100" block runs in WNFI, WNRI, WNII, KEY-LISTVAL, POST-CHANGE).
PORT_CD: always read-only (WNFI). New record with `PRSNL_IMPR = 1` (WCR): IMPR_TYPE_CD := 4 and read-only,
CITY_CODE_OF_ID and BUS_ID_BRNCH read-only.

## Group 3 — commercial register (BUS_ID WVI, BUS_ID_BRNCH WVI; only when FUNS_BUSID = 0, i.e. not in F2 mode)
When `BUS_ID_TYPE_CD = 2 AND IMPR_TYPE_CD <> 12` and the register has exactly one row:
BUS_ID_EXPRD_DT, IMPR_POB_NBR, IMPR_ZIP_CD, IMPR_TEL_NBR, IMPR_FAX_NBR, IMPR_TELEX_NBR, ARBC_IMPR_NAME (and
ACTIVITY in BUS_ID WVI) are read-only; no row but the web-service lookup succeeded (V_RET <> 0) → editable;
more than one row → error 9-290. PRE-INSERT re-enables IMPR_TEL_NBR / BUS_ID_EXPRD_DT when they are empty
(they are required) → read-only only while they have a value.

ACTIVITY (final rule of BUS_ID WVI): editable when `BUS_ID IS NOT NULL AND ACTIVITY IS NULL`, else read-only.
B_ID_NBR: read-only when `IMPR_TYPE_CD = 4 AND BUS_ID_TYPE_CD = 5`.

## Group 4 — registration type (COMM_RGSTRTN_TYPE WLC, IMPR_TYPE_CD WVI)
- COMM_RGSTRTN_TYPE: read-only by default (WNFI, WNRI); editable and required when
  `BUS_ID_TYPE_CD = 2 AND IMPR_TYPE_CD <> 12` (WVI, not in F3 mode); PRE-INSERT / PRE-UPDATE error 9-240 if empty.
- COMM_RGSTRTN_TYPE = 1 → BUS_ID_BRNCH, BRNH_CITY_CD read-only, BRNH_CITY_CD not required.
- COMM_RGSTRTN_TYPE = 2 → BUS_ID_BRNCH, BRNH_CITY_CD editable; BRNH_CITY_CD required; BUS_ID_BRNCH required
  unless BUS_ID or CITY_CODE_OF_ID is empty.

## Group 5 — user class / type
- IMPR_EXPR_TYPE: new record read-only for brokers (`P_CLASS_CD = 1 AND user type = 3`), else editable.
- EXPRESS_POST: read-only for brokers (BROKER_INT; value 2), IMPR_EXPR_TYPE value 1.

## Other required rules
- CITY_CODE_OF_ID required when `IMPR_TYPE_CD IN (1, 3, 5, 6, 8, 19)` (POST-CHANGE); WNRI resets it.
- PRE-INSERT / PRE-UPDATE: B_MOBILE_NO, CITY_CODE, IMPR_TEL_NBR required; BUS_ID_EXPRD_DT required when
  `BUS_ID_TYPE_CD = 2 AND IMPR_TYPE_CD IN (1, 3, 5, 6, 8, 12)`; ACTIVITY required while editable.

## Visible
- `GNRL.GET_CUSTOMS_SETTING(port, 'CR-6730', 9) = 1` and WASL_CITY_NAME not null → CITY_CODE / CITY_NAME hidden,
  WASL_CITY_NAME shown; otherwise WASL_CITY_NAME hidden (POST-QUERY).

## Package functions (step 02)
- `<ITEM>_IS_READ_ONLY` BOOLEAN functions (one per item above), built from private helpers
  `SAVED_RECORD_IS_LOCKED`, `IMPORTER_TYPE_IS_READ_ONLY`, `COMMERCIAL_REGISTER_MATCHES`.
- `<ITEM>_IS_REQUIRED` for COMM_RGSTRTN_TYPE, BRNH_CITY_CD, BUS_ID_BRNCH, CITY_CODE_OF_ID, BUS_ID_EXPRD_DT.
- `WASL_CITY_IS_SHOWN`.
- `<ITEM>_READ_ONLY_FLAGS` procedures for the items whose change moves the rules (IMPR_TYPE_CD,
  BUS_ID_TYPE_CD, COMM_RGSTRTN_TYPE, BUS_ID, BUS_ID_BRNCH): O_ Y/N flags for the dependent items, for the FOS
  "Items to Return" + native Enable / Disable (f345 standard §9).
