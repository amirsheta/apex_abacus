# IMPR1160 – Logic Extraction (step 02)

- **Form:** IMPR1160 (title `IMPR1160_ND_CNTRL`): car exceptions of individual importers (`IMPR_CAR_EXCEPTION`)
- **Package:** `IMPR1160` version 001 – `plsql/IMPR1160/impr1160_spec.sql`, `plsql/IMPR1160/impr1160_body.sql` (NOT COMPILED)
- **Shared package changed:** `LOV_APX` 003 → **004** (`plsql_templates/lov_apx.sql`; previous version `rollback/LOV_APX/v003/`)
- **Inventory:** `analysis/IMPR1160/IMPR1160_inventory.md` (Forms code quoted in sections 6 and 9)
- **Produced:** 2026-11-25 by Claude Code
- **Rollback:** new package, there is no previous version (rollback = `DROP PACKAGE LIB_APX_USR.IMPR1160; DROP PUBLIC SYNONYM IMPR1160;`);
  LOV_APX: re-run `rollback/LOV_APX/v003/lov_apx.sql`.

## 1. Decisions

| # | Decision | Reason |
|---|---|---|
| 1 | Page key `P0_PAGE_PK` = ROWID of `IMPR_CAR_EXCEPTION` (URL-safe on the search page) | as IMPR1140 / IMPR1120; Designer key is (PORT_CD, IMPR_CAR_EXPTN_ISN) |
| 2 | Insert, update and delete are possible; on a queried record only STATUS is enterable | Designer Update / Delete = false, but PRE-QUERY `MAKE_BLOCK_FULL_OPERATION(TRUE, TRUE, TRUE)` and `SET_ITEM_PROPERTY('STATUS', UPDATE_ALLOWED, TRUE)`; every other item has Update Allowed = false |
| 3 | The suspension check of `IMPR_NBR.KEY-NEXT-ITEM` is the validation of IMPR_NBR (CREATE) and a DA on change | WHEN-VALIDATE-ITEM never raises (the IF is inside the NO_DATA_FOUND handler); KEY-NEXT-ITEM holds the real check (inventory §14 #1, §15 #1) |
| 4 | Hijri dates (AWARD_DATE, EXPTN_START_DT, DCLTN_DT) are text in `FORMS_APX.HIJRI_DATE_FORMAT` | IMPR1120 / IMPR1110 decision (Application Setting) |
| 5 | GNRL calls copied unchanged (sequence and setting) | MISSING SOURCE; same call as Forms |
| 6 | LOV forms become shared LOVs in LOV_APX: `IMPORTERS` with new optional type filters (LOV `LOV_IMPR_P`), new `LOV_IMPR_DCLTN` | CLAUDE.md §4d (reuse + parameters; a single-use function is named like its LOV) |
| 7 | Common helpers from `FORMS_APX` 004 (`FORM_TRIGGER_FAILURE`, `HIJRI_*`, `CUR_HIJ_DATE`, `CG_MESSAGE`, `ROWID_FROM_URL`); AWARD_DATE's check is `FORMS_APX.HIJRI_DATE_ERROR` called by the page | CLAUDE.md §4a rule 3 |

## 2. Classification of the Forms code

| Forms object | Kind | Target |
|---|---|---|
| FORM.WHEN-NEW-FORM-INSTANCE (last block) | defaults of a new record | `WHEN_NEW_FORM_INSTANCE` (PORT_CD / PORT_NAME, EXPTN_START_DT) |
| IMPR_CAR_EXCEPTION.POST-QUERY | look-ups | `POST_QUERY` (one NO_DATA_FOUND handler kept, `-- SUGGESTION:`) |
| IMPR_CAR_EXCEPTION.PRE-QUERY + POST-QUERY SET_ITEM_PROPERTY | UI | Form region `i:u:d`, read-only condition on every item except STATUS |
| IMPR_NBR.KEY-NEXT-ITEM | look-up + check | `IMPR_NBR_KEY_NEXT_ITEM` (DA, returns IMPR_NAME) |
| IMPR_NBR.WHEN-VALIDATE-ITEM | check (dead code) | `IMPR_NBR_VALIDATION` = the KEY-NEXT-ITEM check (decision 3) |
| DCLTN_NBR.POST-CHANGE | derivation | `DCLTN_NBR_POST_CHANGE` (ISN, date, number of cars) |
| AWARD_NBR / NO_OF_CARS WHEN-VALIDATE-ITEM | checks | `AWARD_NBR_VALIDATION`, `NO_OF_CARS_VALIDATION` |
| AWARD_DATE WHEN-VALIDATE-ITEM | Hijri date check | `FORMS_APX.HIJRI_DATE_ERROR` (page) |
| EXPTN_START_DT / EXPTN_END_DT WHEN-VALIDATE-ITEM, KEY-F4, KEY-LISTVAL | Hijri check / picker of hidden items | dropped: the items are not displayed |
| DCLTN_DT KEY-NEXT-ITEM / WHEN-VALIDATE-ITEM | `NULL;` (code commented out) | dropped |
| PRE-INSERT | business | `PRE_INSERT` (+ PU `GET_NEXT_IMPR_CAR_EXPTN_CNTRL`) |
| PRE-UPDATE | business | `PRE_UPDATE` |
| ON-ERROR (block) + CGTE$CHECK_CONSTRAINT_VIO | constraint messages | Text Messages `ICE_PK`, `ICE_SD_FK`, `ICE_SDP_FK`, `ICE_IMP_FK`, `ICE_DCLTN_FK` (APEX error handler); ORA-01031 texts dropped |
| PU CALL_IMPR_LOV / CALL_IMPR_DCLTN_LOV | LOV forms | Popup LOVs `LOV_IMPR_P`, `LOV_IMPR_DCLTN` + the DAs above |
| PU CGUI$GET_NEXT_IMPR_CAR_EXPTN_S | sequence (not called) | dropped (same code as GET_NEXT_IMPR_CAR_EXPTN_CNTRL) |
| PU CGDV$POPULATE_DYNAMIC_LISTS | lists | LOVs `LOV_DCL_STA_FLAG`, `LOV_REC_STATUS` (IMPR1140, reused) |
| PU POPULATE_DYNAMIC_LISTS, EXEC_FUNS, ADJ_FUNS, DEV_VERSIONS | `NULL;` | dropped |
| KEY-DUPREC (block), KEY-HELP, KEY-LISTVAL ×15, NIB / TMPLT frame | boilerplate | dropped |

## 3. Package members

| Member | Source | APEX caller |
|---|---|---|
| `P0_PAGE_PK_CHECK` | f345 key check (ROWID) | Before Header 20 |
| `WHEN_NEW_FORM_INSTANCE` | FORM.WHEN-NEW-FORM-INSTANCE | Before Header 60 (new record) |
| `POST_QUERY` | POST-QUERY | Before Header 82 |
| `IMPR_NBR_VALIDATION` | IMPR_NBR WHEN-VALIDATE-ITEM / KEY-NEXT-ITEM | validation (CREATE) |
| `IMPR_NBR_KEY_NEXT_ITEM` | IMPR_NBR.KEY-NEXT-ITEM | DA |
| `DCLTN_NBR_POST_CHANGE` | DCLTN_NBR.POST-CHANGE | DA |
| `AWARD_NBR_VALIDATION`, `NO_OF_CARS_VALIDATION` | WHEN-VALIDATE-ITEM | validations + DAs |
| `PRE_INSERT` | PRE-INSERT | After Submit (CREATE) |
| `PRE_UPDATE` | PRE-UPDATE | After Submit (SAVE) |
| `GET_NEXT_IMPR_CAR_EXPTN_CNTRL` | PU | `PRE_INSERT` |

Private: `importer_suspended` (the suspension SELECT shared by the two IMPR_NBR members).

## 4. Grants needed by LIB_APX_USR (definer rights)

`SELECT` on `IMPR_CAR_EXCEPTION`, `IMPORTERS`, `IMPR_SUSPNS`, `SD_PORTS`, `DECLARATIONS`, `DCLTN_ITEMS`, `STATS_DCLTNS`,
`STATS_ITEMS`, `GROUP_ITEMS`; `EXECUTE` on `GNRL` and `HIJDATE_DB`. The parsing schema CUSTOMS needs DML on `IMPR_CAR_EXCEPTION`
(Form region) and `SELECT` on `IMPORTERS`, `DECLARATIONS`, `STATS_DCLTNS`, `CG_REF_CODES`, `SD_PORTS` (LOVs, search page).

## 5. Open points

See inventory §15: suspension check at save, delete, query scope (all ports), declaration type 3, table DDL, GNRL source,
constraint texts.
