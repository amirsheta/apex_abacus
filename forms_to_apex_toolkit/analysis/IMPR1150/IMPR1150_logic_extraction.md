# IMPR1150 – Logic Extraction (step 02)

- **Form:** IMPR1150 (module `IMPR1150_PROD_CENTRL`): activation of the importers registered on the Fasah platform
- **Package:** `IMPR1150` version 001 – `plsql/IMPR1150/impr1150_spec.sql`, `plsql/IMPR1150/impr1150_body.sql` (NOT COMPILED)
- **Inventory:** `analysis/IMPR1150/IMPR1150_inventory.md` (Forms code quoted in sections 6 and 9)
- **Produced:** 2026-11-25 by Claude Code
- **Rollback:** new package, there is no previous version (rollback = `DROP PACKAGE LIB_APX_USR.IMPR1150; DROP PUBLIC SYNONYM IMPR1150;`)

## 1. Decisions

| # | Decision | Reason |
|---|---|---|
| 1 | The HQ table is used **through the database link**, as in Forms: `CUSTOMS.IMPORTERS_CENTRAL@HQPRD.HQ.CUSTOMS.GOV` | user decision 2026-11-25 |
| 2 | The page key `P0_PAGE_PK` is `IMPR_NBR` (PORT_CD is always 99); a remote ROWID is not used | the record is remote; IMPR_NBR is the Designer key (CGUV$CHK_IMP_CNTRL_PK) |
| 3 | No insert / update / delete from the page: CREATE and DELETE are refused (`PRE_INSERT` / `PRE_DELETE`, as IMPR1116); SAVE only runs PRE-UPDATE's message | Update / Delete Allowed = false; every typed IMPR_NBR / BUS_ID ends in a query or in message 9-150, so the insert path is unreachable |
| 4 | The two functions write through `EXEC_FUNS`, with Forms' COMMIT points | PU EXEC_FUNS |
| 5 | `EXEC_FUNS` checks the HQ status with `ADJ_FUNS` before it updates | TMPLT.DISABLE_FUN hides the menu entry in Forms; in a browser a request can be sent by hand |
| 6 | Common helpers come from `FORMS_APX` (004): `ARABIC_MESSAGE`, `MESSAGE`, `FORM_TRIGGER_FAILURE`; no local copy | CLAUDE.md §4a rule 3 |

## 2. Classification of the Forms code

| Forms object | Kind | Target |
|---|---|---|
| IMPORTERS_CENTRAL.IMPR_NBR.WHEN-VALIDATE-ITEM | validation + navigation | `IMPR_NBR_VALIDATION` (message 9-150, local key check) + DA Submit Page EXECUTE_QUERY |
| IMPORTERS_CENTRAL.BUS_ID.WHEN-VALIDATE-ITEM | validation + navigation | `BUS_ID_VALIDATION` + DA Submit Page EXECUTE_QUERY |
| IMPORTERS_CENTRAL.PRE-QUERY + WHEN-NEW-ITEM-INSTANCE | query key | `IMPORTER_KEY` (process EXECUTE-QUERY) |
| IMPORTERS_CENTRAL.POST-QUERY | look-ups | `POST_QUERY` (the Forms IF nesting is kept: ADD_CTRY / CITY names only when CTRY_CD is not null; `-- SUGGESTION:`) |
| IMPORTERS_CENTRAL.PRE-UPDATE | message | `PRE_UPDATE` (FORMS_APX.MESSAGE, no raise) |
| IMPORTERS_CENTRAL.WHEN-NEW-RECORD-INSTANCE, KEY-F9 → ADJ_FUNS | UI | `ADJ_FUNS` → computation `P1150_ADJ_FUNS` |
| PU EXEC_FUNS | business | `EXEC_FUNS` (server part) + DA (first REJECT press: message, REJCT_RESON shown) |
| PU DETIL_DATA, KEY-EXEQRY / KEY-DOWN / KEY-UP | query of the detail | IG query `WHERE impr_nbr = :P1150_IMPR_NBR` |
| PU OPEN_FILE_DOS, OPEN_DEC | client HOST | **TODO** (inventory §15 #1) |
| IMPORTERS_CENTRAL.BUS_ID_EXPRD_DT.WHEN-VALIDATE-ITEM | validation | dropped: the item is never enterable |
| FORM.PRE-FORM | UI | DA `PRE-FORM` (REJCT_RESON hidden); NIB / NLS / versions dropped |
| FORM.WHEN-NEW-FORM-INSTANCE | data source | region SQL on the HQ table; globals reset = a new page |
| ON-ERROR (both blocks), KEY-HELP, KEY-LISTVAL ×25, NIB / TMPLT frame | boilerplate | dropped (APEX error handling, no DML) |

## 3. Package members

| Member | Source | APEX caller |
|---|---|---|
| `P0_PAGE_PK_CHECK` | f345 key check (block scope: PORT_CD 99 = P_CURR_PORT_CD) | Before Header 20 |
| `IMPORTER_KEY` | PRE-QUERY + WNII | After Submit EXECUTE-QUERY |
| `POST_QUERY` | POST-QUERY | Before Header 82 |
| `IMPR_NBR_VALIDATION` | IMPR_NBR.WHEN-VALIDATE-ITEM + CGUV$CHK_IMP_CNTRL_PK | validation + DA |
| `BUS_ID_VALIDATION` | BUS_ID.WHEN-VALIDATE-ITEM | validation + DA |
| `PRE_INSERT` / `PRE_DELETE` | Insert / Delete not possible | After Submit (CREATE / DELETE) |
| `PRE_UPDATE` | PRE-UPDATE | After Submit (SAVE) |
| `ADJ_FUNS` | PU ADJ_FUNS | computation P1150_ADJ_FUNS |
| `EXEC_FUNS` | PU EXEC_FUNS | After Submit IMPR1150_ACTIVATE / IMPR1150_REJECT EXECUTE-FUNCTION |

Private: `pending_count` (COUNT of pending HQ importers), `add_activity` (ACTIVITY.ADD_ACTIVITY(9, 9, …) → `ACTIVITY_DB`).

## 4. Grants needed by LIB_APX_USR (definer rights)

`SELECT` on `IMPR_TYPES`, `BUS_ID_TYPES`, `COUNTRIES`, `CITIES`, `IMPORTERS_CENTRAL` (local); `EXECUTE` on `LIB_USR.ACTIVITY_DB`;
a usable database link `HQPRD.HQ.CUSTOMS.GOV` (public link, or a link owned by LIB_APX_USR) whose remote user can `SELECT` and
`UPDATE` `CUSTOMS.IMPORTERS_CENTRAL`. The parsing schema CUSTOMS needs the link and `SELECT` on `IMPORTERS_DOCS`, `IMPR_TYPES`,
`CG_REF_CODES` for the region / grid queries.

## 5. Open points

See inventory §15: document opening (TODO), the column of the rejection reason, functions on an empty record, message 9-150,
message texts, the database link.
