# IMPR1110 — classification of all units with code (step 02 rev 2)

Generated from `work/step02/units.json` by the step-02 classifier; groups as in prompt 02 step 2.

| Group | Units | Active lines |
|---|---|---|
| DROPPED | 113 | 2187 |
| INITIALISATION | 5 | 353 |
| NAVIGATION | 9 | 147 |
| PRE/POST DML | 6 | 402 |
| PROGRAM UNIT | 22 | 995 |
| QUERY | 13 | 705 |
| UI-ONLY | 11 | 574 |
| VALIDATION | 32 | 1077 |

| # | Kind | Owner | Trigger / unit | Active lines | Group | Target (package member / APEX) | Note |
|---|---|---|---|---|---|---|---|
| 1 | TRIGGER | FORM | KEY-EDIT | 1 | DROPPED | page 0 toolbar / APEX navigation (NIB key, timer, window handler) | one-line NIB.* delegation |
| 2 | TRIGGER | FORM | KEY-DUPREC | 1 | DROPPED | page 0 toolbar / APEX navigation (NIB key, timer, window handler) | one-line NIB.* delegation |
| 3 | TRIGGER | FORM | PRE-FORM | 15 | DROPPED | PKG_VERSION / f345 globalization | NIB.PRE_FORM, version stamp :GLOBAL.current_ver (-> PKG_VERSION), date format (f345), help path |
| 4 | TRIGGER | FORM | WHEN-NEW-FORM-INSTANCE | 82 | INITIALISATION | WHEN_NEW_FORM_INSTANCE | NIB startup, timers, window dropped; functions / broker / globals kept |
| 5 | TRIGGER | FORM | WHEN-WINDOW-ACTIVATED | 1 | DROPPED | page 0 toolbar / APEX navigation (NIB key, timer, window handler) | one-line NIB.* delegation |
| 6 | TRIGGER | FORM | KEY-ENTQRY | 1 | DROPPED | page 0 toolbar / APEX navigation (NIB key, timer, window handler) | one-line NIB.* delegation |
| 7 | TRIGGER | FORM | ON-ERROR | 1 | DROPPED | f345 APP_ERROR_HANDLER | NIB.ON_ERROR |
| 8 | TRIGGER | FORM | ON-MESSAGE | 1 | DROPPED | f345 APP_ERROR_HANDLER | NIB.ON_MESSAGE |
| 9 | TRIGGER | FORM | KEY-CLRBLK | 1 | DROPPED | page 0 toolbar / APEX navigation (NIB key, timer, window handler) | one-line NIB.* delegation |
| 10 | TRIGGER | FORM | KEY-DELREC | 1 | DROPPED | page 0 toolbar / APEX navigation (NIB key, timer, window handler) | one-line NIB.* delegation |
| 11 | TRIGGER | FORM | KEY-F5 | 1 | DROPPED | page 0 toolbar / APEX navigation (NIB key, timer, window handler) | one-line NIB.* delegation |
| 12 | TRIGGER | FORM | KEY-NXTREC | 1 | DROPPED | page 0 toolbar / APEX navigation (NIB key, timer, window handler) | one-line NIB.* delegation |
| 13 | TRIGGER | FORM | KEY-PRVREC | 1 | DROPPED | page 0 toolbar / APEX navigation (NIB key, timer, window handler) | one-line NIB.* delegation |
| 14 | TRIGGER | FORM | KEY-DOWN | 1 | DROPPED | page 0 toolbar / APEX navigation (NIB key, timer, window handler) | one-line NIB.* delegation |
| 15 | TRIGGER | FORM | KEY-UP | 1 | DROPPED | page 0 toolbar / APEX navigation (NIB key, timer, window handler) | one-line NIB.* delegation |
| 16 | TRIGGER | FORM | KEY-SCRUP | 1 | DROPPED | page 0 toolbar / APEX navigation (NIB key, timer, window handler) | one-line NIB.* delegation |
| 17 | TRIGGER | FORM | KEY-SCRDOWN | 1 | DROPPED | page 0 toolbar / APEX navigation (NIB key, timer, window handler) | one-line NIB.* delegation |
| 18 | TRIGGER | FORM | KEY-PRINT | 1 | DROPPED | page 0 toolbar / APEX navigation (NIB key, timer, window handler) | one-line NIB.* delegation |
| 19 | TRIGGER | FORM | KEY-EXIT | 1 | DROPPED | page 0 toolbar / APEX navigation (NIB key, timer, window handler) | one-line NIB.* delegation |
| 20 | TRIGGER | FORM | WHEN-MOUSE-DOWN | 1 | DROPPED | page 0 toolbar / APEX navigation (NIB key, timer, window handler) | one-line NIB.* delegation |
| 21 | TRIGGER | FORM | KEY-EXEQRY | 1 | DROPPED | page 0 toolbar / APEX navigation (NIB key, timer, window handler) | one-line NIB.* delegation |
| 22 | TRIGGER | FORM | KEY-F9 | 23 | UI-ONLY | page 0 FUNCS + region FUNCS | side menu toggle; ADJ_FUNS part → ADJ_FUNS |
| 23 | TRIGGER | FORM | WHEN-TIMER-EXPIRED | 1 | DROPPED | page 0 toolbar / APEX navigation (NIB key, timer, window handler) | one-line NIB.* delegation |
| 24 | TRIGGER | FORM | KEY-HELP | 16 | DROPPED | - | MS-Help (CGHP$) |
| 25 | TRIGGER | FORM | KEY-CLRFRM | 8 | UI-ONLY | page 0 CLEAR | CGDV lists → shared LOVs; WHEN-CLEAR-BLOCK logic kept in IMPORTERS_WHEN_CLEAR_BLOCK |
| 26 | TRIGGER | TITLE.SYSTEM_DATE | WHEN-VALIDATE-ITEM | 12 | DROPPED | f345 page template / page 0 toolbar | OLB screen frame |
| 27 | TRIGGER | TOOLBAR | KEY-DOWN | 3 | DROPPED | f345 page template / page 0 toolbar | OLB screen frame |
| 28 | TRIGGER | TOOLBAR | KEY-UP | 3 | DROPPED | f345 page template / page 0 toolbar | OLB screen frame |
| 29 | TRIGGER | TOOLBAR | KEY-NEXT-ITEM | 10 | DROPPED | f345 page template / page 0 toolbar | OLB screen frame |
| 30 | TRIGGER | TOOLBAR.SAVE | WHEN-BUTTON-PRESSED | 12 | DROPPED | f345 page template / page 0 toolbar | OLB screen frame |
| 31 | TRIGGER | TOOLBAR.EXIT | WHEN-BUTTON-PRESSED | 15 | DROPPED | f345 page template / page 0 toolbar | OLB screen frame |
| 32 | TRIGGER | TOOLBAR.EXIT1 | WHEN-BUTTON-PRESSED | 38 | DROPPED | f345 page template / page 0 toolbar | OLB screen frame |
| 33 | TRIGGER | TOOLBAR.LAST_REC | WHEN-BUTTON-PRESSED | 1 | DROPPED | f345 page template / page 0 toolbar | OLB screen frame |
| 34 | TRIGGER | TOOLBAR.RE_ENTER_QUERY | WHEN-BUTTON-PRESSED | 6 | DROPPED | f345 page template / page 0 toolbar | OLB screen frame |
| 35 | TRIGGER | TOOLBAR.PAGE_DOWN | WHEN-BUTTON-PRESSED | 1 | DROPPED | f345 page template / page 0 toolbar | OLB screen frame |
| 36 | TRIGGER | TOOLBAR.FUN_BUT | WHEN-MOUSE-UP | 12 | DROPPED | f345 page template / page 0 toolbar | OLB screen frame |
| 37 | TRIGGER | TOOLBAR.FUN_BUT | WHEN-MOUSE-DOWN | 10 | DROPPED | f345 page template / page 0 toolbar | OLB screen frame |
| 38 | TRIGGER | IMPORTERS | ON-ERROR | 80 | VALIDATION | IMPORTERS_ON_ERROR | constraint name → message (OFGTEL MISSING SOURCE); used by APP_ERROR_HANDLER text lookup |
| 39 | TRIGGER | IMPORTERS | POST-QUERY | 329 | QUERY | IMPORTERS_POST_QUERY | split into private helpers (status, suspension, privileged, duty-diff, CR status, lookups); UI → WASL_CITY_IS_SHOWN / _IS_READ_ONLY |
| 40 | TRIGGER | IMPORTERS | PRE-QUERY | 63 | QUERY | search page SQL | name criterion / IMPORTERS_WHERE / PRSNL_IMPR → WHERE clause of page <page>01 (no package member) |
| 41 | TRIGGER | IMPORTERS | PRE-INSERT | 195 | PRE/POST DML | PRE_INSERT | split: required checks, register check, central number (CREATE_UNI_IMPR_NEBRAS), activity |
| 42 | TRIGGER | IMPORTERS | KEY-HELP | 128 | DROPPED | - | MS-Help |
| 43 | TRIGGER | IMPORTERS | KEY-DELREC | 28 | PRE/POST DML | KEY_DELREC | delete IMPR_UPDTS + importer, no COMMIT (decision §15 #6); confirm = page 0 DELETE |
| 44 | TRIGGER | IMPORTERS | POST-INSERT | 29 | PRE/POST DML | POST_INSERT | Make_Field_Entrable → saved-record lock rule |
| 45 | TRIGGER | IMPORTERS | POST-UPDATE | 20 | PRE/POST DML | POST_UPDATE | journaling off; Make_Field_Entrable → saved-record lock rule |
| 46 | TRIGGER | IMPORTERS | PRE-DELETE | 5 | PRE/POST DML | PRE_DELETE |  |
| 47 | TRIGGER | IMPORTERS | PRE-RECORD | 17 | INITIALISATION | IMPORTERS_PRE_RECORD |  |
| 48 | TRIGGER | IMPORTERS | PRE-UPDATE | 125 | PRE/POST DML | PRE_UPDATE | split like PRE_INSERT; journaling on |
| 49 | TRIGGER | IMPORTERS | WHEN-CLEAR-BLOCK | 3 | INITIALISATION | IMPORTERS_WHEN_CLEAR_BLOCK | globals |
| 50 | TRIGGER | IMPORTERS | WHEN-CREATE-RECORD | 25 | INITIALISATION | IMPORTERS_WHEN_CREATE_RECORD | defaults; PRSNL_IMPR rule → _IS_READ_ONLY |
| 51 | TRIGGER | IMPORTERS | WHEN-NEW-ITEM-INSTANCE | 7 | NAVIGATION | page submit with request (re-query) | EXEC_QUERY_NOW |
| 52 | TRIGGER | IMPORTERS | WHEN-NEW-RECORD-INSTANCE | 226 | INITIALISATION | IMPORTERS_NEW_RECORD_INSTANCE | split per function code (F1..F5, SF6); type-19 rule kept without COMMIT (§15 #16); entrable → rules |
| 53 | TRIGGER | IMPORTERS.SDP_PORT_STATUS | KEY-LISTVAL | 32 | DROPPED | - | generic Designer KEY-LISTVAL (no LOV on this item) |
| 54 | TRIGGER | IMPORTERS.L_CT_CITY_STATUS2 | KEY-LISTVAL | 32 | DROPPED | - | generic Designer KEY-LISTVAL (no LOV on this item) |
| 55 | TRIGGER | IMPORTERS.L_CT_CITY_STATUS | KEY-LISTVAL | 32 | DROPPED | - | generic Designer KEY-LISTVAL (no LOV on this item) |
| 56 | TRIGGER | IMPORTERS.PORT_CD | KEY-LISTVAL | 65 | UI-ONLY | Popup LOV on P1110_PORT_CD | LOV form call → popup LOV; returned globals → LOV return columns |
| 57 | TRIGGER | IMPORTERS.PORT_CD | WHEN-VALIDATE-ITEM | 19 | VALIDATION | PORT_CD_VALIDATION / PORT_CD_WHEN_VALIDATE_ITEM | error text function + procedure for derived values; entrable → rules |
| 58 | TRIGGER | IMPORTERS.PORT_CD2 | WHEN-BUTTON-PRESSED | 4 | DROPPED | popup LOV button | DO_KEY(LIST_VALUES) |
| 59 | TRIGGER | IMPORTERS.PORT_NAME | KEY-LISTVAL | 32 | DROPPED | - | generic Designer KEY-LISTVAL (no LOV on this item) |
| 60 | TRIGGER | IMPORTERS.HQ_IMPR_NBR | KEY-LISTVAL | 32 | DROPPED | - | generic Designer KEY-LISTVAL (no LOV on this item) |
| 61 | TRIGGER | IMPORTERS.HQ_IMPR_NBR | POST-CHANGE | 3 | VALIDATION | HQ_IMPR_NBR_POST_CHANGE | runs before WHEN-VALIDATE-ITEM |
| 62 | TRIGGER | IMPORTERS.IMPR_NBR | KEY-LISTVAL | 32 | DROPPED | - | generic Designer KEY-LISTVAL (no LOV on this item) |
| 63 | TRIGGER | IMPORTERS.IMPR_NBR | WHEN-VALIDATE-ITEM | 18 | VALIDATION | IMPR_NBR_VALIDATION / IMPR_NBR_WHEN_VALIDATE_ITEM | error text function + procedure for derived values; entrable → rules |
| 64 | TRIGGER | IMPORTERS.SUSPN_STATUS | KEY-LISTVAL | 32 | DROPPED | - | generic Designer KEY-LISTVAL (no LOV on this item) |
| 65 | TRIGGER | IMPORTERS.STATUS_DESC | KEY-LISTVAL | 32 | DROPPED | - | generic Designer KEY-LISTVAL (no LOV on this item) |
| 66 | TRIGGER | IMPORTERS.IMPR_TYPE_CD | KEY-LISTVAL | 95 | UI-ONLY | Popup LOV on P1110_IMPR_TYPE_CD | LOV form call → popup LOV; returned globals → LOV return columns |
| 67 | TRIGGER | IMPORTERS.IMPR_TYPE_CD | WHEN-VALIDATE-ITEM | 206 | VALIDATION | IMPR_TYPE_CD_VALIDATION / IMPR_TYPE_CD_WHEN_VALIDATE_ITEM | error text function + procedure for derived values; entrable → rules |
| 68 | TRIGGER | IMPORTERS.IMPR_TYPE_CD | POST-CHANGE | 7 | VALIDATION | IMPR_TYPE_CD_POST_CHANGE | runs before WHEN-VALIDATE-ITEM |
| 69 | TRIGGER | IMPORTERS.IMPR_TYPE_CD | WHEN-NEW-ITEM-INSTANCE | 27 | NAVIGATION | DA IMPR_TYPE_CD WHEN-NEW-ITEM-INSTANCE | messages / defaults on focus; required flags → _IS_REQUIRED |
| 70 | TRIGGER | IMPORTERS.IMPR_TYPE_CD2 | WHEN-BUTTON-PRESSED | 5 | DROPPED | popup LOV button | DO_KEY(LIST_VALUES) |
| 71 | TRIGGER | IMPORTERS.IMPR_TYPE_NAME | KEY-LISTVAL | 32 | DROPPED | - | generic Designer KEY-LISTVAL (no LOV on this item) |
| 72 | TRIGGER | IMPORTERS.BUS_ID_EXPRD_DT | KEY-LISTVAL | 25 | DROPPED | - | generic Designer KEY-LISTVAL (no LOV on this item) |
| 73 | TRIGGER | IMPORTERS.BUS_ID_EXPRD_DT | KEY-F4 | 25 | DROPPED | date picker | Hijri calendar (INTRFACE.Disp_Date_Con) |
| 74 | TRIGGER | IMPORTERS.BUS_ID_EXPRD_DT | WHEN-VALIDATE-ITEM | 22 | VALIDATION | BUS_ID_EXPRD_DT_VALIDATION / BUS_ID_EXPRD_DT_WHEN_VALIDATE_ITEM | error text function + procedure for derived values; entrable → rules |
| 75 | TRIGGER | IMPORTERS.BUS_ID_EXPRD_DT | WHEN-NEW-ITEM-INSTANCE | 6 | NAVIGATION | DA BUS_ID_EXPRD_DT WHEN-NEW-ITEM-INSTANCE | messages / defaults on focus; required flags → _IS_REQUIRED |
| 76 | TRIGGER | IMPORTERS.BUS_ID_TYPE_CD | KEY-LISTVAL | 32 | DROPPED | - | generic Designer KEY-LISTVAL (no LOV on this item) |
| 77 | TRIGGER | IMPORTERS.BUS_ID_TYPE_CD | POST-CHANGE | 24 | VALIDATION | BUS_ID_TYPE_CD_POST_CHANGE | runs before WHEN-VALIDATE-ITEM |
| 78 | TRIGGER | IMPORTERS.BUTT | WHEN-BUTTON-PRESSED | 5 | DROPPED | popup LOV button | DO_KEY(LIST_VALUES) |
| 79 | TRIGGER | IMPORTERS.BUS_ID_TYPE_NAME | KEY-LISTVAL | 32 | DROPPED | - | generic Designer KEY-LISTVAL (no LOV on this item) |
| 80 | TRIGGER | IMPORTERS.COMM_RGSTRTN_TYPE | KEY-LISTVAL | 32 | DROPPED | - | generic Designer KEY-LISTVAL (no LOV on this item) |
| 81 | TRIGGER | IMPORTERS.COMM_RGSTRTN_TYPE | WHEN-LIST-CHANGED | 14 | UI-ONLY | COMM_RGSTRTN_TYPE_LIST_CHANGED | clears BUS_ID_BRNCH; entrable / required → rules |
| 82 | TRIGGER | IMPORTERS.CITY_CODE_OF_ID | KEY-LISTVAL | 71 | UI-ONLY | Popup LOV on P1110_CITY_CODE_OF_ID | LOV form call → popup LOV; returned globals → LOV return columns |
| 83 | TRIGGER | IMPORTERS.CITY_CODE_OF_ID | WHEN-VALIDATE-ITEM | 50 | VALIDATION | CITY_CODE_OF_ID_VALIDATION / CITY_CODE_OF_ID_WHEN_VALIDATE_ITEM | error text function + procedure for derived values; entrable → rules |
| 84 | TRIGGER | IMPORTERS.CITY_CODE_OF_ID | WHEN-NEW-ITEM-INSTANCE | 6 | NAVIGATION | DA CITY_CODE_OF_ID WHEN-NEW-ITEM-INSTANCE | messages / defaults on focus; required flags → _IS_REQUIRED |
| 85 | TRIGGER | IMPORTERS.CITY_CODE_OF_ID2 | WHEN-BUTTON-PRESSED | 4 | DROPPED | popup LOV button | DO_KEY(LIST_VALUES) |
| 86 | TRIGGER | IMPORTERS.ID_CITY_NAME | KEY-LISTVAL | 32 | DROPPED | - | generic Designer KEY-LISTVAL (no LOV on this item) |
| 87 | TRIGGER | IMPORTERS.BUS_ID | KEY-LISTVAL | 32 | DROPPED | - | generic Designer KEY-LISTVAL (no LOV on this item) |
| 88 | TRIGGER | IMPORTERS.BUS_ID | POST-CHANGE | 3 | VALIDATION | BUS_ID_POST_CHANGE | runs before WHEN-VALIDATE-ITEM |
| 89 | TRIGGER | IMPORTERS.BUS_ID | WHEN-NEW-ITEM-INSTANCE | 20 | NAVIGATION | DA BUS_ID WHEN-NEW-ITEM-INSTANCE | messages / defaults on focus; required flags → _IS_REQUIRED |
| 90 | TRIGGER | IMPORTERS.BUS_ID | WHEN-VALIDATE-ITEM | 200 | VALIDATION | BUS_ID_VALIDATION / BUS_ID_WHEN_VALIDATE_ITEM | error text function + procedure for derived values; entrable → rules |
| 91 | TRIGGER | IMPORTERS.BRNH_CITY_CD | KEY-LISTVAL | 66 | UI-ONLY | Popup LOV on P1110_BRNH_CITY_CD | LOV form call → popup LOV; returned globals → LOV return columns |
| 92 | TRIGGER | IMPORTERS.BRNH_CITY_CD | WHEN-NEW-ITEM-INSTANCE | 7 | NAVIGATION | DA BRNH_CITY_CD WHEN-NEW-ITEM-INSTANCE | messages / defaults on focus; required flags → _IS_REQUIRED |
| 93 | TRIGGER | IMPORTERS.BRNH_CITY_CD | WHEN-VALIDATE-ITEM | 14 | VALIDATION | BRNH_CITY_CD_VALIDATION / BRNH_CITY_CD_WHEN_VALIDATE_ITEM | error text function + procedure for derived values; entrable → rules |
| 94 | TRIGGER | IMPORTERS.BRNH_CITY_CD_LOV | WHEN-BUTTON-PRESSED | 5 | DROPPED | popup LOV button | DO_KEY(LIST_VALUES) |
| 95 | TRIGGER | IMPORTERS.BRNH_CITY_NAME | KEY-LISTVAL | 32 | DROPPED | - | generic Designer KEY-LISTVAL (no LOV on this item) |
| 96 | TRIGGER | IMPORTERS.BUS_ID_BRNCH | KEY-LISTVAL | 32 | DROPPED | - | generic Designer KEY-LISTVAL (no LOV on this item) |
| 97 | TRIGGER | IMPORTERS.BUS_ID_BRNCH | POST-CHANGE | 3 | VALIDATION | BUS_ID_BRNCH_POST_CHANGE | runs before WHEN-VALIDATE-ITEM |
| 98 | TRIGGER | IMPORTERS.BUS_ID_BRNCH | WHEN-NEW-ITEM-INSTANCE | 29 | NAVIGATION | DA BUS_ID_BRNCH WHEN-NEW-ITEM-INSTANCE | messages / defaults on focus; required flags → _IS_REQUIRED |
| 99 | TRIGGER | IMPORTERS.BUS_ID_BRNCH | WHEN-VALIDATE-ITEM | 136 | VALIDATION | BUS_ID_BRNCH_VALIDATION / BUS_ID_BRNCH_WHEN_VALIDATE_ITEM | error text function + procedure for derived values; entrable → rules |
| 100 | TRIGGER | IMPORTERS.CTRY_CD | KEY-LISTVAL | 39 | UI-ONLY | Popup LOV on P1110_CTRY_CD | LOV form call → popup LOV; returned globals → LOV return columns |
| 101 | TRIGGER | IMPORTERS.CTRY_CD | WHEN-VALIDATE-ITEM | 40 | VALIDATION | CTRY_CD_VALIDATION / CTRY_CD_WHEN_VALIDATE_ITEM | error text function + procedure for derived values; entrable → rules |
| 102 | TRIGGER | IMPORTERS.CTRY_CD2 | WHEN-BUTTON-PRESSED | 4 | DROPPED | popup LOV button | DO_KEY(LIST_VALUES) |
| 103 | TRIGGER | IMPORTERS.CRTY_ARBC_NAME | KEY-LISTVAL | 32 | DROPPED | - | generic Designer KEY-LISTVAL (no LOV on this item) |
| 104 | TRIGGER | IMPORTERS.IMPR_EXPR_TYPE | KEY-LISTVAL | 32 | DROPPED | - | generic Designer KEY-LISTVAL (no LOV on this item) |
| 105 | TRIGGER | IMPORTERS.IMPR_EXPR_TYPE | POST-CHANGE | 3 | VALIDATION | IMPR_EXPR_TYPE_POST_CHANGE | runs before WHEN-VALIDATE-ITEM |
| 106 | TRIGGER | IMPORTERS.CTRY_CTRY_STATUS | KEY-LISTVAL | 32 | DROPPED | - | generic Designer KEY-LISTVAL (no LOV on this item) |
| 107 | TRIGGER | IMPORTERS.ID_MINS_COMM_CD | KEY-LISTVAL | 32 | DROPPED | - | generic Designer KEY-LISTVAL (no LOV on this item) |
| 108 | TRIGGER | IMPORTERS.ARBC_IMPR_NAME | KEY-LISTVAL | 32 | DROPPED | - | generic Designer KEY-LISTVAL (no LOV on this item) |
| 109 | TRIGGER | IMPORTERS.ARBC_IMPR_NAME | KEY-NEXT-ITEM | 40 | NAVIGATION | native Set Focus | net effect GO_ITEM |
| 110 | TRIGGER | IMPORTERS.ARBC_IMPR_NAME | WHEN-VALIDATE-ITEM | 4 | VALIDATION | ARBC_IMPR_NAME_VALIDATION / ARBC_IMPR_NAME_WHEN_VALIDATE_ITEM | error text function + procedure for derived values; entrable → rules |
| 111 | TRIGGER | IMPORTERS.IMPD_STMT_NBR | KEY-LISTVAL | 32 | DROPPED | - | generic Designer KEY-LISTVAL (no LOV on this item) |
| 112 | TRIGGER | IMPORTERS.IMPR_DATA_SRCE | KEY-LISTVAL | 32 | DROPPED | - | generic Designer KEY-LISTVAL (no LOV on this item) |
| 113 | TRIGGER | IMPORTERS.ENG_IMPR_NAME | KEY-LISTVAL | 32 | DROPPED | - | generic Designer KEY-LISTVAL (no LOV on this item) |
| 114 | TRIGGER | IMPORTERS.ENG_IMPR_NAME | WHEN-VALIDATE-ITEM | 21 | VALIDATION | ENG_IMPR_NAME_VALIDATION / ENG_IMPR_NAME_WHEN_VALIDATE_ITEM | error text function + procedure for derived values; entrable → rules |
| 115 | TRIGGER | IMPORTERS.IMPR_CNTCT_NAME | KEY-LISTVAL | 32 | DROPPED | - | generic Designer KEY-LISTVAL (no LOV on this item) |
| 116 | TRIGGER | IMPORTERS.IMPR_ADDRESS | KEY-LISTVAL | 32 | DROPPED | - | generic Designer KEY-LISTVAL (no LOV on this item) |
| 117 | TRIGGER | IMPORTERS.BUS_ID_ISSUE_DT | WHEN-VALIDATE-ITEM | 12 | VALIDATION | BUS_ID_ISSUE_DT_VALIDATION / BUS_ID_ISSUE_DT_WHEN_VALIDATE_ITEM | error text function + procedure for derived values; entrable → rules |
| 118 | TRIGGER | IMPORTERS.IMPR_NBR_PARENT | KEY-LISTVAL | 62 | UI-ONLY | Popup LOV on P1110_IMPR_NBR_PARENT | LOV form call → popup LOV; returned globals → LOV return columns |
| 119 | TRIGGER | IMPORTERS.IMPR_NBR_PARENT | WHEN-VALIDATE-ITEM | 16 | VALIDATION | IMPR_NBR_PARENT_VALIDATION / IMPR_NBR_PARENT_WHEN_VALIDATE_ITEM | error text function + procedure for derived values; entrable → rules |
| 120 | TRIGGER | IMPORTERS.IMPR_NBR_PARENT2 | WHEN-BUTTON-PRESSED | 5 | DROPPED | popup LOV button | DO_KEY(LIST_VALUES) |
| 121 | TRIGGER | IMPORTERS.IMPR_NAME_PARENT | KEY-LISTVAL | 32 | DROPPED | - | generic Designer KEY-LISTVAL (no LOV on this item) |
| 122 | TRIGGER | IMPORTERS.WASL_CITY_NAME | KEY-LISTVAL | 32 | DROPPED | - | generic Designer KEY-LISTVAL (no LOV on this item) |
| 123 | TRIGGER | IMPORTERS.ADD_CTRY_CD | KEY-LISTVAL | 64 | UI-ONLY | Popup LOV on P1110_ADD_CTRY_CD | LOV form call → popup LOV; returned globals → LOV return columns |
| 124 | TRIGGER | IMPORTERS.ADD_CTRY_CD | WHEN-VALIDATE-ITEM | 28 | VALIDATION | ADD_CTRY_CD_VALIDATION / ADD_CTRY_CD_WHEN_VALIDATE_ITEM | error text function + procedure for derived values; entrable → rules |
| 125 | TRIGGER | IMPORTERS.ADD_CTRY_CD2 | WHEN-BUTTON-PRESSED | 4 | DROPPED | popup LOV button | DO_KEY(LIST_VALUES) |
| 126 | TRIGGER | IMPORTERS.ADD_CRTY_ARBC_NAME | KEY-LISTVAL | 32 | DROPPED | - | generic Designer KEY-LISTVAL (no LOV on this item) |
| 127 | TRIGGER | IMPORTERS.CITY_CODE | KEY-LISTVAL | 67 | UI-ONLY | Popup LOV on P1110_CITY_CODE | LOV form call → popup LOV; returned globals → LOV return columns |
| 128 | TRIGGER | IMPORTERS.CITY_CODE | WHEN-VALIDATE-ITEM | 33 | VALIDATION | CITY_CODE_VALIDATION / CITY_CODE_WHEN_VALIDATE_ITEM | error text function + procedure for derived values; entrable → rules |
| 129 | TRIGGER | IMPORTERS.CITY_CODE2 | WHEN-BUTTON-PRESSED | 5 | DROPPED | popup LOV button | DO_KEY(LIST_VALUES) |
| 130 | TRIGGER | IMPORTERS.CITY_NAME | KEY-LISTVAL | 32 | DROPPED | - | generic Designer KEY-LISTVAL (no LOV on this item) |
| 131 | TRIGGER | IMPORTERS.IMPR_POB_NBR | KEY-LISTVAL | 32 | DROPPED | - | generic Designer KEY-LISTVAL (no LOV on this item) |
| 132 | TRIGGER | IMPORTERS.IMPR_ZIP_CD | KEY-LISTVAL | 32 | DROPPED | - | generic Designer KEY-LISTVAL (no LOV on this item) |
| 133 | TRIGGER | IMPORTERS.IMPR_TEL_NBR | KEY-LISTVAL | 32 | DROPPED | - | generic Designer KEY-LISTVAL (no LOV on this item) |
| 134 | TRIGGER | IMPORTERS.IMPR_TEL_NBR | WHEN-VALIDATE-ITEM | 14 | VALIDATION | IMPR_TEL_NBR_VALIDATION / IMPR_TEL_NBR_WHEN_VALIDATE_ITEM | error text function + procedure for derived values; entrable → rules |
| 135 | TRIGGER | IMPORTERS.IMPR_FAX_NBR | KEY-LISTVAL | 32 | DROPPED | - | generic Designer KEY-LISTVAL (no LOV on this item) |
| 136 | TRIGGER | IMPORTERS.IMPR_TELEX_NBR | KEY-LISTVAL | 32 | DROPPED | - | generic Designer KEY-LISTVAL (no LOV on this item) |
| 137 | TRIGGER | IMPORTERS.B_EMAIL | WHEN-VALIDATE-ITEM | 20 | VALIDATION | B_EMAIL_VALIDATION / B_EMAIL_WHEN_VALIDATE_ITEM | error text function + procedure for derived values; entrable → rules |
| 138 | TRIGGER | IMPORTERS.B_EMAIL | POST-CHANGE | 4 | VALIDATION | B_EMAIL_POST_CHANGE | runs before WHEN-VALIDATE-ITEM |
| 139 | TRIGGER | IMPORTERS.EMAIL | WHEN-VALIDATE-ITEM | 20 | VALIDATION | EMAIL_VALIDATION / EMAIL_WHEN_VALIDATE_ITEM | error text function + procedure for derived values; entrable → rules |
| 140 | TRIGGER | IMPORTERS.B_MOBILE_NO | KEY-LISTVAL | 32 | DROPPED | - | generic Designer KEY-LISTVAL (no LOV on this item) |
| 141 | TRIGGER | IMPORTERS.B_MOBILE_NO | POST-CHANGE | 4 | VALIDATION | B_MOBILE_NO_POST_CHANGE | runs before WHEN-VALIDATE-ITEM |
| 142 | TRIGGER | IMPORTERS.B_MOBILE_NO | WHEN-VALIDATE-ITEM | 28 | VALIDATION | B_MOBILE_NO_VALIDATION / B_MOBILE_NO_WHEN_VALIDATE_ITEM | error text function + procedure for derived values; entrable → rules |
| 143 | TRIGGER | IMPORTERS.MOBILE_NO | KEY-LISTVAL | 32 | DROPPED | - | generic Designer KEY-LISTVAL (no LOV on this item) |
| 144 | TRIGGER | IMPORTERS.BANK_IBAN | WHEN-NEW-ITEM-INSTANCE | 5 | NAVIGATION | DA BANK_IBAN WHEN-NEW-ITEM-INSTANCE | messages / defaults on focus; required flags → _IS_REQUIRED |
| 145 | TRIGGER | IMPORTERS.BANK_IBAN | WHEN-VALIDATE-ITEM | 12 | VALIDATION | BANK_IBAN_VALIDATION / BANK_IBAN_WHEN_VALIDATE_ITEM | error text function + procedure for derived values; entrable → rules |
| 146 | TRIGGER | IMPORTERS.B_ID_NBR | POST-CHANGE | 4 | VALIDATION | B_ID_NBR_POST_CHANGE | runs before WHEN-VALIDATE-ITEM |
| 147 | TRIGGER | IMPORTERS.B_ID_NBR | WHEN-VALIDATE-ITEM | 16 | VALIDATION | B_ID_NBR_VALIDATION / B_ID_NBR_WHEN_VALIDATE_ITEM | error text function + procedure for derived values; entrable → rules |
| 148 | TRIGGER | IMPORTERS.EXPRESS_POST | KEY-LISTVAL | 32 | DROPPED | - | generic Designer KEY-LISTVAL (no LOV on this item) |
| 149 | TRIGGER | IMPORTERS.IMPR_ID_TYPE | KEY-LISTVAL | 32 | DROPPED | - | generic Designer KEY-LISTVAL (no LOV on this item) |
| 150 | TRIGGER | IMPORTERS.CTRY_CD_OF_ID | KEY-LISTVAL | 32 | DROPPED | - | generic Designer KEY-LISTVAL (no LOV on this item) |
| 151 | TRIGGER | IMPORTERS.CTRY_CD_OF_ID | WHEN-VALIDATE-ITEM | 13 | VALIDATION | CTRY_CD_OF_ID_VALIDATION / CTRY_CD_OF_ID_WHEN_VALIDATE_ITEM | error text function + procedure for derived values; entrable → rules |
| 152 | TRIGGER | IMPORTERS.EXPD_STMT_NBR | KEY-LISTVAL | 32 | DROPPED | - | generic Designer KEY-LISTVAL (no LOV on this item) |
| 153 | TRIGGER | IMPORTERS.WVR_ENTRY_NBR | KEY-LISTVAL | 32 | DROPPED | - | generic Designer KEY-LISTVAL (no LOV on this item) |
| 154 | TRIGGER | IMPORTERS.ACTIVITY | KEY-LISTVAL | 32 | DROPPED | - | generic Designer KEY-LISTVAL (no LOV on this item) |
| 155 | TRIGGER | IMPORTERS.CUSTOMS_ENTERED | KEY-LISTVAL | 32 | DROPPED | - | generic Designer KEY-LISTVAL (no LOV on this item) |
| 156 | TRIGGER | IMPORTERS.CUSTOMS_ENTERED2 | WHEN-BUTTON-PRESSED | 4 | DROPPED | popup LOV button | DO_KEY(LIST_VALUES) |
| 157 | TRIGGER | IMPORTERS.CREATION_FLAG | KEY-LISTVAL | 32 | DROPPED | - | generic Designer KEY-LISTVAL (no LOV on this item) |
| 158 | TRIGGER | IMPORTERS.CREATION_FLAG2 | WHEN-BUTTON-PRESSED | 4 | DROPPED | popup LOV button | DO_KEY(LIST_VALUES) |
| 159 | PU | PROGRAM UNITS | CHECK_TIMEOUT | 10 | DROPPED | - | session timeout → APEX (§15 #9) |
| 160 | PU | PROGRAM UNITS | MOUSE_CLICK | 7 | DROPPED | - | LSIDE menu |
| 161 | PU | PROGRAM UNITS | TOGGEL_WND | 5 | DROPPED | - | window (Windows API) |
| 162 | PU | PROGRAM UNITS | PRINT_REPORT | 14 | DROPPED | - | not called by active code |
| 163 | PU | PROGRAM UNITS | EXECUTE_FUNCTION | 144 | DROPPED | - | TMPLT dispatcher → f345 Page Functions list; report branch (REP.RUN_PRODUCT) open (§14 #5) |
| 164 | PU | PROGRAM UNITS | TERMINATE_FUN | 7 | DROPPED | - | function menu |
| 165 | PU | PROGRAM UNITS | CHECK_EDI_MSG_LOV | 9 | DROPPED | - | EDI ticker (§15 #9) |
| 166 | PU | PROGRAM UNITS | CHECK_EDI_MSG_TIMER | 9 | DROPPED | - | EDI ticker |
| 167 | PU | PROGRAM UNITS | CHECK_EDI_ROLE_ID | 9 | DROPPED | - | EDI ticker |
| 168 | PU | PROGRAM UNITS | EDI_MSG_LOV | 8 | DROPPED | - | EDI ticker |
| 169 | PU | PROGRAM UNITS | FOR_EDI_MSG | 5 | DROPPED | - | EDI ticker |
| 170 | PU | PROGRAM UNITS | RETURN_MSG | 6 | DROPPED | - | EDI ticker |
| 171 | PU | PROGRAM UNITS | TURN_MSG | 6 | DROPPED | - | EDI ticker |
| 172 | PU | PROGRAM UNITS | WHEN_TIMER_EXPIRED_MSG | 8 | DROPPED | - | EDI ticker |
| 173 | PU | PROGRAM UNITS | CG$WHEN_NEW_FORM_INSTANCE | 9 | DROPPED | - | calls CGDV$POPULATE_DYNAMIC_LISTS only |
| 174 | PU | PROGRAM UNITS | CGDV$POPULATE_DYNAMIC_LISTS | 21 | DROPPED | - | list items → shared LOVs on CG_REF_CODES |
| 175 | PU | PROGRAM UNITS | CGFK$QRY_IMPORTERS_IMP_SDP_FK | 23 | QUERY | CGFK$QRY_IMPORTERS_IMP_SDP_FK | Designer FK lookup / check, same name; used by validations |
| 176 | PU | PROGRAM UNITS | CGFK$CHK_IMPORTERS_IMP_SDP_FK | 23 | QUERY | CGFK$CHK_IMPORTERS_IMP_SDP_FK | Designer FK lookup / check, same name; used by validations |
| 177 | PU | PROGRAM UNITS | CG$IMPR1110_PROD_CENTRL_GLOBAL | 3 | DROPPED | - | IMPORTERS_WHERE variable → search page SQL |
| 178 | PU | PROGRAM UNITS | CGFK$CHK_IMPORTERS_IMP_MB_FK | 20 | QUERY | CGFK$CHK_IMPORTERS_IMP_MB_FK | Designer FK lookup / check, same name; used by validations |
| 179 | PU | PROGRAM UNITS | CGFK$QRY_IMPORTERS_IMP_ITIDT_F | 35 | QUERY | CGFK$QRY_IMPORTERS_IMP_ITIDT_F | Designer FK lookup / check, same name; used by validations |
| 180 | PU | PROGRAM UNITS | CGFK$CHK_IMPORTERS_IMP_ITIDT_F | 35 | QUERY | CGFK$CHK_IMPORTERS_IMP_ITIDT_F | Designer FK lookup / check, same name; used by validations |
| 181 | PU | PROGRAM UNITS | CGFK$QRY_IMPORTERS_IMP_CTRY_FK | 23 | QUERY | CGFK$QRY_IMPORTERS_IMP_CTRY_FK | Designer FK lookup / check, same name; used by validations |
| 182 | PU | PROGRAM UNITS | CGFK$CHK_IMPORTERS_IMP_CTRY_FK | 24 | QUERY | CGFK$CHK_IMPORTERS_IMP_CTRY_FK | Designer FK lookup / check, same name; used by validations |
| 183 | PU | PROGRAM UNITS | CGFK$QRY_IMPORTERS_IMP_BUS_ID_ | 32 | QUERY | CGFK$QRY_IMPORTERS_IMP_BUS_ID_ | Designer FK lookup / check, same name; used by validations |
| 184 | PU | PROGRAM UNITS | CGFK$CHK_IMPORTERS_IMP_BUS_ID_ | 33 | QUERY | CGFK$CHK_IMPORTERS_IMP_BUS_ID_ | Designer FK lookup / check, same name; used by validations |
| 185 | PU | PROGRAM UNITS | CGSF$CLRLU_IMPORTERS_IMP_BUS_I | 18 | PROGRAM UNIT | CGSF$CLRLU_IMPORTERS_IMP_BUS_I | same name as in Forms |
| 186 | PU | PROGRAM UNITS | CGFK$QRY_IMPORTERS_IMP_ADD_CIT | 32 | QUERY | CGFK$QRY_IMPORTERS_IMP_ADD_CIT | Designer FK lookup / check, same name; used by validations |
| 187 | PU | PROGRAM UNITS | CGFK$CHK_IMPORTERS_IMP_ADD_CIT | 33 | QUERY | CGFK$CHK_IMPORTERS_IMP_ADD_CIT | Designer FK lookup / check, same name; used by validations |
| 188 | PU | PROGRAM UNITS | CGTE$CHECK_CONSTRAINT_VIO | 45 | PROGRAM UNIT | CGTE$CHECK_CONSTRAINT_VIO | same name as in Forms |
| 189 | PU | PROGRAM UNITS | UPDATE_IMPORTER | 60 | PROGRAM UNIT | UPDATE_IMPORTER | same name as in Forms |
| 190 | PU | PROGRAM UNITS | UPDATE_BASIC_IMPORTER | 23 | PROGRAM UNIT | UPDATE_BASIC_IMPORTER | same name as in Forms |
| 191 | PU | PROGRAM UNITS | RETURN_IMPR_ID | 7 | PROGRAM UNIT | RETURN_IMPR_ID | same name as in Forms |
| 192 | PU | PROGRAM UNITS | LOV_UPDATE_MOBLIE | 53 | PROGRAM UNIT | LOV_UPDATE_MOBLIE | same name as in Forms |
| 193 | PU | PROGRAM UNITS | IS_DIGIT | 15 | PROGRAM UNIT | IS_DIGIT | same name as in Forms |
| 194 | PU | PROGRAM UNITS | INSERT_AUDIT_RECORD | 45 | PROGRAM UNIT | INSERT_AUDIT_RECORD | same name as in Forms |
| 195 | PU | PROGRAM UNITS | GET_MAIN_CR_DATA | 10 | PROGRAM UNIT | GET_MAIN_CR_DATA | same name as in Forms |
| 196 | PU | PROGRAM UNITS | GET_CR_DATA | 362 | PROGRAM UNIT | GET_CR_DATA | same name as in Forms |
| 197 | PU | PROGRAM UNITS | GET_BRANCH_CR_DATA | 10 | PROGRAM UNIT | GET_BRANCH_CR_DATA | same name as in Forms |
| 198 | PU | PROGRAM UNITS | EXEC_FUNS | 77 | PROGRAM UNIT | EXEC_FUNS | same name as in Forms |
| 199 | PU | PROGRAM UNITS | DEV_VERSIONS | 4 | DROPPED | - | version stamp |
| 200 | PU | PROGRAM UNITS | CREATE_BRKR_IMPR_AUTH | 55 | PROGRAM UNIT | CREATE_BRKR_IMPR_AUTH | same name as in Forms |
| 201 | PU | PROGRAM UNITS | CHK_PERSONAL | 36 | PROGRAM UNIT | CHK_PERSONAL | same name as in Forms |
| 202 | PU | PROGRAM UNITS | CHK_IMPR_DUPL | 33 | PROGRAM UNIT | CHK_IMPR_DUPL | same name as in Forms |
| 203 | PU | PROGRAM UNITS | CHK_DUPL_IMP_BRKR | 27 | PROGRAM UNIT | CHK_DUPL_IMP_BRKR | same name as in Forms |
| 204 | PU | PROGRAM UNITS | CHECK_IDNO | 26 | PROGRAM UNIT | CHECK_IDNO | same name as in Forms |
| 205 | PU | PROGRAM UNITS | CHECK_BUS_ID | 5 | PROGRAM UNIT | CHECK_BUS_ID | same name as in Forms |
| 206 | PU | PROGRAM UNITS | CALL_LOV_COUNTRIES | 31 | DROPPED | - | LOV form → popup LOV |
| 207 | PU | PROGRAM UNITS | CALL_LOV_COUN_GULF | 31 | DROPPED | - | LOV form → popup LOV |
| 208 | PU | PROGRAM UNITS | BROKER_INT | 7 | PROGRAM UNIT | BROKER_INT | same name as in Forms |
| 209 | PU | PROGRAM UNITS | ADJ_FUNS | 34 | PROGRAM UNIT | ADJ_FUNS | same name as in Forms |
| 210 | PU | PROGRAM UNITS | VIEW_SAME_BUSID | 40 | PROGRAM UNIT | VIEW_SAME_BUSID | same name as in Forms |
| 211 | PU | PROGRAM UNITS | CHK_BUS_ID_BRNCH | 7 | PROGRAM UNIT | CHK_BUS_ID_BRNCH | same name as in Forms |
