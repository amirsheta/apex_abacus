# IMPR1170 – Logic Extraction (step 02)

- **Form:** IMPR1170 (module `IMPR1170_CNTRL`): commercial-registration data from the Ministry of Commerce (`MCI_DATA` + detail `MCI_OWNERS`)
- **Package:** `IMPR1170` version 001 – `plsql/IMPR1170/impr1170_spec.sql`, `plsql/IMPR1170/impr1170_body.sql` (NOT COMPILED)
- **Shared packages changed:** none (`LOV_APX` and `FORMS_APX` unchanged; LOV `LOV_COMM_RGSTRTN_TYPE` of IMPR1130 is reused)
- **Inventory:** `analysis/IMPR1170/IMPR1170_inventory.md` (Forms code quoted in sections 6 and 9)
- **Produced:** 2026-11-25 by Claude Code
- **Rollback:** new package, there is no previous version (rollback = `DROP PACKAGE LIB_APX_USR.IMPR1170; DROP PUBLIC SYNONYM IMPR1170;`).

## 1. Decisions

| # | Decision | Reason |
|---|---|---|
| 1 | Page key `P0_PAGE_PK` = `CR_NBR` (`MCI_DATA_PK`) | the master key of the relation to MCI_OWNERS; the record is never changed, so no ROWID is needed (as IMPR1150 with IMPR_NBR) |
| 2 | `CR_NBR.KEY-NEXT-ITEM` becomes the After Submit process "CR_NBR KEY-NEXT-ITEM" (request `EXECUTE_QUERY`, sent by a DA on change) that sets `P0_PAGE_PK`; the branch reloads the page and "Initialize form" queries the record | `SET_BLOCK_PROPERTY(DEFAULT_WHERE)` + `EXECUTE_QUERY` = show the record of that key (IMPR1150 pattern); a change event also fires with the mouse (inventory §14 #1) |
| 3 | Page 0 CREATE / SAVE / DELETE are refused with a message | block Update / Delete Allowed = false; Forms insert of a bare row without the look-up is not kept (inventory §14 #2, §15 #1, to confirm) |
| 4 | The web service is called unchanged through `LIB_USR.PRTL_NEBRAS_SERVICES.CALL_WEB_SERVICE`; the URL is one package constant | MISSING SOURCE; same call as Forms; `-- SUGGESTION:` move the address to a setting |
| 5 | The STR.DISPALERT 'ERROR' of a failed service call is `FORMS_APX.FORM_TRIGGER_FAILURE` | the Forms trigger ends there too; APEX shows the text and keeps the typed number |
| 6 | MCI_OWNERS.POST-QUERY (relation name) is an outer join in the grid query; MCI_DATA.POST-QUERY is the process POST-QUERY → `IMPR1170.POST_QUERY` | read-only grid rows (CLAUDE.md §5: POST-QUERY → SQL / computed column); the single record keeps the Forms trigger as one member |
| 7 | `WHEN OTHERS` of the POST-QUERY triggers narrowed to `NO_DATA_FOUND` / `TOO_MANY_ROWS` (outer join in the grid) | same result for missing / ambiguous codes; other errors are faults |
| 8 | CR_ISSUE_DATE / CR_EXPIRY_DATE (Hijri, `MI-MM-YYYY`) are display only with the mask `FORMS_APX.HIJRI_DATE_FORMAT`; their WHEN-VALIDATE-ITEM (HIJDATE.VALID_HIJ_DATE) is dropped | the items are never enterable (Insert / Update Allowed = false) |

## 2. Classification of the Forms code

| Forms object | Kind | Target |
|---|---|---|
| MCI_DATA.CR_NBR.KEY-NEXT-ITEM | look-up + web service + query | `CR_NBR_KEY_NEXT_ITEM` (After Submit, request EXECUTE_QUERY) + DA "CR_NBR KEY-NEXT-ITEM" + branch "EXECUTE-QUERY" |
| MCI_DATA.CR_NBR.WHEN-VALIDATE-ITEM | `NULL;` | dropped |
| MCI_DATA.POST-QUERY | look-up | `POST_QUERY` (CR_STAT_DESC) |
| MCI_OWNERS.POST-QUERY | look-up | outer join `MCI_RELATION_TYPES` in the grid query (RELATION_DESC) |
| MCI_DATA.CR_ISSUE_DATE / CR_EXPIRY_DATE WHEN-VALIDATE-ITEM | Hijri check of non-enterable items | dropped |
| Relation `CGFK$MCI_OWNER_MCI_DATA_FK`, FORM.ON-POPULATE-DETAILS / ON-CLEAR-DETAILS | master–detail | grid MCI_OWNERS `WHERE cr_nbr = :P1170_CR_NBR` |
| MCI_DATA.ON-ERROR / MCI_OWNERS.ON-ERROR + CGTE$CHECK_CONSTRAINT_VIO (`MCI_DATA_PK`) | constraint / privilege messages | dropped: the page does no DML |
| PU CGDV$POPULATE_DYNAMIC_LISTS (CR_TYPE, CG_REF_CODES `COMM_RGSTRTN_TYPE`) | list | LOV `LOV_COMM_RGSTRTN_TYPE` (IMPR1130, reused) |
| TOOLBAR.SAVE.WHEN-BUTTON-PRESSED (COMMIT, CLOSE_FORM SUPPORT_ENTRY, title items) | frame | page 0 SAVE → process PRE-UPDATE (refused) |
| PU EXEC_FUNS, ADJ_FUNS | `NULL;` | dropped |
| KEY-LISTVAL ×22, KEY-HELP, NIB / TMPLT / CGBS frame, timers, EDI messages | boilerplate | dropped |

## 3. Package members

| Member | Source | APEX caller |
|---|---|---|
| `P0_PAGE_PK_CHECK` | f345 key check (CR_NBR in MCI_DATA) | Before Header 20 |
| `POST_QUERY` | MCI_DATA.POST-QUERY | Before Header 82 |
| `CR_NBR_KEY_NEXT_ITEM` | MCI_DATA.CR_NBR.KEY-NEXT-ITEM | After Submit 10 (request EXECUTE_QUERY) |
| `PRE_INSERT` / `PRE_UPDATE` / `PRE_DELETE` | block DML not allowed | After Submit (requests CREATE / SAVE / DELETE) |

Private: `cached_key` (the block query by CR_NBR, used by the key check and by the look-up).

## 4. Grants needed by LIB_APX_USR (definer rights)

`SELECT` on `MCI_DATA`, `MCI_BUS_ID_STATUS`; `EXECUTE` on `LIB_USR.PRTL_NEBRAS_SERVICES`. The parsing schema CUSTOMS needs
`SELECT` on `MCI_DATA` (Form region, search page), `MCI_OWNERS`, `MCI_RELATION_TYPES` (grid), `MCI_BUS_ID_STATUS` (search page)
and `CG_REF_CODES` (LOV). The network ACL of the web service belongs to the owner of `PRTL_NEBRAS_SERVICES` (unchanged).

## 5. Open points

See inventory §15: insert from the form, web-service package source and address, table DDL, module title.
