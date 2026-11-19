
Branch: after processing → page 1110 (f345 default). Request `EXECUTE_QUERY` additionally clears the
cache of page 1110, so the non-database items of the old record are not kept.

### Page 111002

| Point | Seq | Process | Code | Condition | Source |
|---|---|---|---|---|---|
| After Header | 10 | `G_LAST_PAGE KEEP` | `:G_LAST_PAGE := 1110;` | – | f345 standard §4 |
| After Submit | 10 | `PB_OK WHEN-BUTTON-PRESSED` | `IMPR1110.MOBILE_OK(I_P111002_MOBILE_NO => :P111002_MOBILE_NO);` | request `PB_OK` | LOV_UPDATE_IMPR_MOBILE.CTRL_BLK.PB_OK |
| After Submit | 20 | `Close Dialog` | native Close Dialog | request `PB_OK` | COPY_SELECTED_VALUES + EXIT_FORM |

## 9. Computations

APEX runs Before Header computations before the Before Header processes, so the computations that need
the fetched record (ADJ_FUNS, MOBILE_URL, PRE_INSERT_QUESTION) run After Header.

