455 objects: DROPPED 361, MAPPED 92, TODO 2. By type: ALERT 10, BLOCK 6, CALLED_FORM 4, CANVAS 5, GLOBAL 9, ITEM 103, LIBRARY 17, LOV 1, PARAMETER 22, PROGRAM_UNIT 26, RECORD_GROUP 2, RELATION 1, TRIGGER 248, WINDOW 1.

| # | Type | Forms object | APEX component | Page | Package member | Status | Notes |
|---|---|---|---|---|---|---|---|
| 1 | BLOCK | `TITLE` | HQ_IMPRS_HERO | 1125 | – | MAPPED | OLB title bar -> hero region (HEADER TITLE, FORMS_APX) |
| 2 | BLOCK | `EDI_MSG` | – | – | – | DROPPED | OLB EDI message ticker - dropped (timers, IMPR1110 decision 2026-11-19) |
| 3 | BLOCK | `LSIDE` | FUNCS (page 0 drawer, f345 Page Functions) | 0 | – | MAPPED | OLB side function menu |
| 4 | BLOCK | `TOOLBAR` | P0_ACTIONS (page 0 toolbar, f345) | 0 | – | MAPPED | OLB toolbar -> f345 page 0 toolbar |
| 5 | BLOCK | `HQ_IMPRS` | HQ_IMPRS (Form region, table HQ_IMPRS, primary key ROWID, no Process form) | 1125 | – | MAPPED | master search header; ON-INSERT / ON-UPDATE / ON-DELETE NULL -> never written; search page 112501 |
| 6 | BLOCK | `IMPR_CNTRL_SUSPNS` | IMPR_CNTRL_SUSPNS (editable Interactive Grid) | 1125 | IMPR1125.IMPR_CNTRL_SUSPNS_SAVE_ROW | MAPPED | detail; WHERE SUSPN_RLSE_DT IS NULL; DML through IMPR_CNTRL_SUSPNS_SAVE_ROW (soft delete) |
| 7 | ITEM | `TITLE.CGSO$CHECK_BOX_U` | – | – | – | DROPPED | OLB block TITLE |
| 8 | ITEM | `TITLE.CGSO$CHAR_ARB_ED` | – | – | – | DROPPED | OLB block TITLE |
| 9 | ITEM | `TITLE.CGSO$CHAR_ARB_DO_MLINE` | – | – | – | DROPPED | OLB block TITLE |
| 10 | ITEM | `TITLE.CGSO$CHAR_ARB_ORA_LOV` | – | – | – | DROPPED | OLB block TITLE |
| 11 | ITEM | `TITLE.CGSO$CHAR_ARB_DO_ENB_Y` | – | – | – | DROPPED | OLB block TITLE |
| 12 | ITEM | `TITLE.CGSO$CHAR_ARB_MLINE` | – | – | – | DROPPED | OLB block TITLE |
| 13 | ITEM | `TITLE.CGSO$CHAR_ARB` | – | – | – | DROPPED | OLB block TITLE |
| 14 | ITEM | `TITLE.CGSO$CHAR_ARB_DO` | – | – | – | DROPPED | OLB block TITLE |
| 15 | ITEM | `TITLE.SCREEN_NAME` | – | – | – | DROPPED | OLB block TITLE |
| 16 | ITEM | `TITLE.USER_NAME` | – | – | – | DROPPED | OLB block TITLE |
| 17 | ITEM | `TITLE.SYSTEM_DATE` | – | – | – | DROPPED | OLB block TITLE |
| 18 | ITEM | `TITLE.VERSION` | – | – | – | DROPPED | OLB block TITLE |
| 19 | ITEM | `EDI_MSG.EDI_MSG_TXT` | – | – | – | DROPPED | OLB block EDI_MSG |
| 20 | ITEM | `EDI_MSG.EDI_MSG_LOVE_BUT` | – | – | – | DROPPED | OLB block EDI_MSG |
| 21 | ITEM | `LSIDE.FN1` | – | – | – | DROPPED | OLB block LSIDE |
| 22 | ITEM | `LSIDE.FN50` | – | – | – | DROPPED | OLB block LSIDE |
| 23 | ITEM | `LSIDE.FN2` | – | – | – | DROPPED | OLB block LSIDE |
| 24 | ITEM | `LSIDE.FN49` | – | – | – | DROPPED | OLB block LSIDE |
| 25 | ITEM | `LSIDE.FN3` | – | – | – | DROPPED | OLB block LSIDE |
| 26 | ITEM | `LSIDE.FN48` | – | – | – | DROPPED | OLB block LSIDE |
| 27 | ITEM | `LSIDE.FN4` | – | – | – | DROPPED | OLB block LSIDE |
| 28 | ITEM | `LSIDE.FN47` | – | – | – | DROPPED | OLB block LSIDE |
| 29 | ITEM | `LSIDE.FN5` | – | – | – | DROPPED | OLB block LSIDE |
| 30 | ITEM | `LSIDE.FN46` | – | – | – | DROPPED | OLB block LSIDE |
| 31 | ITEM | `LSIDE.FN6` | – | – | – | DROPPED | OLB block LSIDE |
| 32 | ITEM | `LSIDE.FN45` | – | – | – | DROPPED | OLB block LSIDE |
| 33 | ITEM | `LSIDE.FN7` | – | – | – | DROPPED | OLB block LSIDE |
| 34 | ITEM | `LSIDE.FN44` | – | – | – | DROPPED | OLB block LSIDE |
| 35 | ITEM | `LSIDE.FN8` | – | – | – | DROPPED | OLB block LSIDE |
| 36 | ITEM | `LSIDE.FN43` | – | – | – | DROPPED | OLB block LSIDE |
| 37 | ITEM | `LSIDE.FN9` | – | – | – | DROPPED | OLB block LSIDE |
| 38 | ITEM | `LSIDE.FN42` | – | – | – | DROPPED | OLB block LSIDE |
| 39 | ITEM | `LSIDE.FN10` | – | – | – | DROPPED | OLB block LSIDE |
| 40 | ITEM | `LSIDE.FN41` | – | – | – | DROPPED | OLB block LSIDE |
| 41 | ITEM | `LSIDE.FN11` | – | – | – | DROPPED | OLB block LSIDE |
| 42 | ITEM | `LSIDE.FN40` | – | – | – | DROPPED | OLB block LSIDE |
| 43 | ITEM | `LSIDE.FN12` | – | – | – | DROPPED | OLB block LSIDE |
| 44 | ITEM | `LSIDE.FN39` | – | – | – | DROPPED | OLB block LSIDE |
| 45 | ITEM | `LSIDE.FN13` | – | – | – | DROPPED | OLB block LSIDE |
| 46 | ITEM | `LSIDE.FN38` | – | – | – | DROPPED | OLB block LSIDE |
| 47 | ITEM | `LSIDE.FN14` | – | – | – | DROPPED | OLB block LSIDE |
| 48 | ITEM | `LSIDE.FN37` | – | – | – | DROPPED | OLB block LSIDE |
| 49 | ITEM | `LSIDE.FN15` | – | – | – | DROPPED | OLB block LSIDE |
| 50 | ITEM | `LSIDE.FN36` | – | – | – | DROPPED | OLB block LSIDE |
| 51 | ITEM | `LSIDE.FN16` | – | – | – | DROPPED | OLB block LSIDE |
| 52 | ITEM | `LSIDE.FN17` | – | – | – | DROPPED | OLB block LSIDE |
| 53 | ITEM | `LSIDE.FN34` | – | – | – | DROPPED | OLB block LSIDE |
| 54 | ITEM | `LSIDE.FN35` | – | – | – | DROPPED | OLB block LSIDE |
| 55 | ITEM | `LSIDE.FN18` | – | – | – | DROPPED | OLB block LSIDE |
| 56 | ITEM | `LSIDE.FN33` | – | – | – | DROPPED | OLB block LSIDE |
| 57 | ITEM | `LSIDE.FN19` | – | – | – | DROPPED | OLB block LSIDE |
| 58 | ITEM | `LSIDE.FN32` | – | – | – | DROPPED | OLB block LSIDE |
| 59 | ITEM | `LSIDE.FN20` | – | – | – | DROPPED | OLB block LSIDE |
| 60 | ITEM | `LSIDE.FN31` | – | – | – | DROPPED | OLB block LSIDE |
| 61 | ITEM | `LSIDE.FN21` | – | – | – | DROPPED | OLB block LSIDE |
| 62 | ITEM | `LSIDE.FN30` | – | – | – | DROPPED | OLB block LSIDE |
| 63 | ITEM | `LSIDE.FN22` | – | – | – | DROPPED | OLB block LSIDE |
| 64 | ITEM | `LSIDE.FN29` | – | – | – | DROPPED | OLB block LSIDE |
| 65 | ITEM | `LSIDE.FN23` | – | – | – | DROPPED | OLB block LSIDE |
| 66 | ITEM | `LSIDE.FN28` | – | – | – | DROPPED | OLB block LSIDE |
| 67 | ITEM | `LSIDE.FN24` | – | – | – | DROPPED | OLB block LSIDE |
| 68 | ITEM | `LSIDE.FN27` | – | – | – | DROPPED | OLB block LSIDE |
| 69 | ITEM | `LSIDE.FN25` | – | – | – | DROPPED | OLB block LSIDE |
| 70 | ITEM | `LSIDE.FN26` | – | – | – | DROPPED | OLB block LSIDE |
| 71 | ITEM | `TOOLBAR.DUMMY` | – | – | – | DROPPED | OLB toolbar item (record navigation / frame) |
| 72 | ITEM | `TOOLBAR.SAVE` | SAVE (page 0 toolbar) | 0 | – | MAPPED | saves the grid (request SAVE) |
| 73 | ITEM | `TOOLBAR.CLEAR_ALL` | CLEAR (page 0 toolbar) | 0 | – | MAPPED | – |
| 74 | ITEM | `TOOLBAR.EXIT` | BACK (page 0 toolbar) | 0 | – | MAPPED | – |
| 75 | ITEM | `TOOLBAR.EXIT1` | BACK (page 0 toolbar) | 0 | – | MAPPED | leave Enter-Query mode -> no query mode in APEX |
| 76 | ITEM | `TOOLBAR.ENTER` | SEARCH (page 0 toolbar) | 0 | – | MAPPED | Enter Query -> search page 112501 |
| 77 | ITEM | `TOOLBAR.EXECUTE` | SEARCH (page 0 toolbar) | 0 | – | MAPPED | Execute Query -> search page 112501 |
| 78 | ITEM | `TOOLBAR.REMOVE` | DELETE (page 0 toolbar) / IG row delete | 0 | – | MAPPED | importer: refused by PRE-DELETE (Delete Allowed = No); suspension: IG row delete |
| 79 | ITEM | `TOOLBAR.LIST_VALUE` | – | – | – | DROPPED | LOV key -> page 0 SEARCH |
| 80 | ITEM | `TOOLBAR.HELP` | – | – | – | DROPPED | MS-Help obsolete |
| 81 | ITEM | `TOOLBAR.LAST_REC` | – | – | – | DROPPED | OLB toolbar item (record navigation / frame) |
| 82 | ITEM | `TOOLBAR.RE_ENTER_QUERY` | SEARCH (page 0 toolbar) | 0 | – | MAPPED | – |
| 83 | ITEM | `TOOLBAR.FIRST_REC` | – | – | – | DROPPED | OLB toolbar item (record navigation / frame) |
| 84 | ITEM | `TOOLBAR.PAGE_UP` | – | – | – | DROPPED | OLB toolbar item (record navigation / frame) |
| 85 | ITEM | `TOOLBAR.PAGE_DOWN` | – | – | – | DROPPED | OLB toolbar item (record navigation / frame) |
| 86 | ITEM | `TOOLBAR.FUN_BUT` | FUNCS (page 0 toolbar) | 0 | – | MAPPED | – |
| 87 | ITEM | `HQ_IMPRS.BUS_ID` | P1125_BUS_ID | 1125 | – | MAPPED | Text Field, editable only while P0_PAGE_PK is null (search key); sent to the save (SMS text) |
| 88 | ITEM | `HQ_IMPRS.BUT_SH_HQNUM` | SEARCH (page 0 toolbar) -> 112501 | 0 | – | MAPPED | LOV button of BUS_ID (SINGLE_IMP_LOV) |
| 89 | ITEM | `HQ_IMPRS.BUS_ID_TYPE_CD` | P1125_BUS_ID_TYPE_CD | 1125 | – | MAPPED | Display Only |
| 90 | ITEM | `HQ_IMPRS.BUS_ID_TYPE_NAME` | P1125_BUS_ID_TYPE_NAME | 1125 | – | MAPPED | Display Only (POST-QUERY) |
| 91 | ITEM | `HQ_IMPRS.BUS_ID_BRNCH` | P1125_BUS_ID_BRNCH | 1125 | – | MAPPED | Display Only |
| 92 | ITEM | `HQ_IMPRS.HQ_IMPR_NBR` | P1125_HQ_IMPR_NBR | 1125 | – | MAPPED | Number Field, editable only while P0_PAGE_PK is null (search key, Update Allowed = No) |
| 93 | ITEM | `HQ_IMPRS.CITY_CODE_OF_ID` | P1125_CITY_CODE_OF_ID | 1125 | – | MAPPED | Display Only (POST-QUERY) |
| 94 | ITEM | `HQ_IMPRS.CITY_CODE_OF_NAME` | P1125_CITY_CODE_OF_NAME | 1125 | – | MAPPED | Display Only (POST-QUERY) |
| 95 | ITEM | `HQ_IMPRS.IMPR_TYPE_CD` | P1125_IMPR_TYPE_CD | 1125 | – | MAPPED | Display Only (POST-QUERY) |
| 96 | ITEM | `HQ_IMPRS.IMPR_TYPE_NAME` | P1125_IMPR_TYPE_NAME | 1125 | – | MAPPED | Display Only (POST-QUERY) |
| 97 | ITEM | `HQ_IMPRS.IMPR_EXPR_TYPE` | P1125_IMPR_EXPR_TYPE | 1125 | – | MAPPED | Display Only based on LOV_ALLOWED_EXPORT (POST-QUERY) |
| 98 | ITEM | `HQ_IMPRS.CTRY_CD` | P1125_CTRY_CD | 1125 | – | MAPPED | Display Only (POST-QUERY) |
| 99 | ITEM | `HQ_IMPRS.CRTY_ARBC_NAME` | P1125_CRTY_ARBC_NAME | 1125 | – | MAPPED | Display Only (POST-QUERY) |
| 100 | ITEM | `HQ_IMPRS.ARBC_IMPR_NAME` | P1125_ARBC_IMPR_NAME | 1125 | – | MAPPED | Display Only (POST-QUERY) |
| 101 | ITEM | `HQ_IMPRS.ENG_IMPR_NAME` | P1125_ENG_IMPR_NAME | 1125 | – | MAPPED | Display Only (POST-QUERY) |
| 102 | ITEM | `IMPR_CNTRL_SUSPNS.SUSPN_STRT_DT` | IMPR_CNTRL_SUSPNS.SUSPN_STRT_DT | 1125 | – | MAPPED | Text Field (HIJRI_DATE_FORMAT, hijri-date-default), required |
| 103 | ITEM | `IMPR_CNTRL_SUSPNS.SUSPN_END_DT` | IMPR_CNTRL_SUSPNS.SUSPN_END_DT | 1125 | – | MAPPED | Text Field (HIJRI_DATE_FORMAT, hijri-date-default) |
| 104 | ITEM | `IMPR_CNTRL_SUSPNS.HQ_IMPR_NBR` | IMPR_CNTRL_SUSPNS.HQ_IMPR_NBR | 1125 | – | MAPPED | Hidden, primary key (default = master item P1125_HQ_IMPR_NBR; save call NVL) |
| 105 | ITEM | `IMPR_CNTRL_SUSPNS.SUSPN_SEQ` | IMPR_CNTRL_SUSPNS.SUSPN_SEQ | 1125 | – | MAPPED | Hidden, primary key (set by IMPR_CNTRL_SUSPNS_PRE_INSERT) |
| 106 | ITEM | `IMPR_CNTRL_SUSPNS.SUSPN_RSN_CD` | IMPR_CNTRL_SUSPNS.SUSPN_RSN_CD | 1125 | – | MAPPED | Hidden, default 1 (no canvas in Forms) |
| 107 | ITEM | `IMPR_CNTRL_SUSPNS.SUSPN_RSN_TEXT` | IMPR_CNTRL_SUSPNS.SUSPN_RSN_TEXT | 1125 | – | MAPPED | Text Field, required, max 50 |
| 108 | ITEM | `IMPR_CNTRL_SUSPNS.SUSPN_SIDE_CD` | IMPR_CNTRL_SUSPNS.SUSPN_SIDE_CD | 1125 | – | MAPPED | Select List LOV_SUSPN_SIDE_CD, Read Only always, default 5 (CGSO$COMBO_DO) |
| 109 | ITEM | `IMPR_CNTRL_SUSPNS.SUSPN_RLSE_DT` | IMPR_CNTRL_SUSPNS_DELETED.SUSPN_RLSE_DT (page 112502) | 112502 | IMPR1125.IMPR_CNTRL_SUSPNS_ON_DELETE | MAPPED | not a grid column on 1125: set by ON_DELETE; region WHERE SUSPN_RLSE_DT IS NULL |
| 110 | TRIGGER | `FORM.KEY-EDIT` | – | – | – | DROPPED | NIB.KEY_EDIT -> page 0 toolbar / IG keyboard |
| 111 | TRIGGER | `FORM.KEY-DUPREC` | – | – | – | DROPPED | NIB.KEY_DUPREC -> page 0 toolbar / IG keyboard |
| 112 | TRIGGER | `FORM.PRE-FORM` | – | – | – | DROPPED | NIB.PRE_FORM, NLS date setting, help path -> f345 application |
| 113 | TRIGGER | `FORM.WHEN-NEW-FORM-INSTANCE` | – | – | – | DROPPED | NIB / CGBS2$ / CG$WHEN_NEW_FORM_INSTANCE -> f345, LOVs, native master-detail; globals := NULL -> P0_PAGE_PK |
| 114 | TRIGGER | `FORM.WHEN-WINDOW-ACTIVATED` | – | – | – | DROPPED | timers / window / frame (OLB, NIB) |
| 115 | TRIGGER | `FORM.KEY-ENTQRY` | – | – | – | DROPPED | NIB.KEY_ENTQRY -> page 0 toolbar / IG keyboard |
| 116 | TRIGGER | `FORM.ON-ERROR` | APP_ERROR_HANDLER (f345) | – | – | MAPPED | NIB.ON_ERROR |
| 117 | TRIGGER | `FORM.ON-MESSAGE` | APP_ERROR_HANDLER (f345) / page messages | – | – | MAPPED | NIB.ON_MESSAGE |
| 118 | TRIGGER | `FORM.KEY-CLRBLK` | – | – | – | DROPPED | NIB.KEY_CLRBLK -> page 0 toolbar / IG keyboard |
| 119 | TRIGGER | `FORM.KEY-DELREC` | – | – | – | DROPPED | NIB.KEY_DELREC -> page 0 toolbar / IG keyboard |
| 120 | TRIGGER | `FORM.KEY-F5` | – | – | – | DROPPED | NIB.KEY_F5 -> page 0 toolbar / IG keyboard |
| 121 | TRIGGER | `FORM.KEY-F4` | – | – | – | DROPPED | timers / window / frame (OLB, NIB) |
| 122 | TRIGGER | `FORM.KEY-NXTREC` | – | – | – | DROPPED | NIB.KEY_NXTREC -> page 0 toolbar / IG keyboard |
| 123 | TRIGGER | `FORM.KEY-PRVREC` | – | – | – | DROPPED | NIB.KEY_PRVREC -> page 0 toolbar / IG keyboard |
| 124 | TRIGGER | `FORM.KEY-DOWN` | – | – | – | DROPPED | NIB.KEY_DOWN -> page 0 toolbar / IG keyboard |
| 125 | TRIGGER | `FORM.KEY-UP` | – | – | – | DROPPED | NIB.KEY_UP -> page 0 toolbar / IG keyboard |
| 126 | TRIGGER | `FORM.KEY-SCRUP` | – | – | – | DROPPED | NIB.KEY_SCRUP -> page 0 toolbar / IG keyboard |
| 127 | TRIGGER | `FORM.KEY-SCRDOWN` | – | – | – | DROPPED | NIB.KEY_SCRDOWN -> page 0 toolbar / IG keyboard |
| 128 | TRIGGER | `FORM.KEY-PRINT` | – | – | – | DROPPED | NIB.KEY_PRINT -> page 0 toolbar / IG keyboard |
| 129 | TRIGGER | `FORM.KEY-EXIT` | – | – | – | DROPPED | NIB.KEY_EXIT -> page 0 toolbar / IG keyboard |
| 130 | TRIGGER | `FORM.WHEN-MOUSE-DOWN` | – | – | – | DROPPED | timers / window / frame (OLB, NIB) |
| 131 | TRIGGER | `FORM.KEY-EXEQRY` | – | – | – | DROPPED | NIB.KEY_EXEQRY -> page 0 toolbar / IG keyboard |
| 132 | TRIGGER | `FORM.KEY-F9` | FUNCS (page 0 toolbar) | 0 | – | MAPPED | side-menu toggle -> FUNCS |
| 133 | TRIGGER | `FORM.WHEN-TIMER-EXPIRED` | – | – | – | DROPPED | timers / window / frame (OLB, NIB) |
| 134 | TRIGGER | `FORM.KEY-HELP` | – | – | – | DROPPED | MS-Help obsolete |
| 135 | TRIGGER | `FORM.WHEN-NEW-BLOCK-INSTANCE` | – | – | – | DROPPED | Designer master-detail coordination (CGBS$) -> native Form + IG |
| 136 | TRIGGER | `FORM.ON-CLEAR-DETAILS` | – | – | – | DROPPED | Designer master-detail coordination (CGBS$) -> native Form + IG |
| 137 | TRIGGER | `FORM.ON-POPULATE-DETAILS` | – | – | – | DROPPED | Designer master-detail coordination (CGBS$) -> native Form + IG |
| 138 | TRIGGER | `FORM.KEY-CQUERY` | – | – | – | DROPPED | Designer key handler -> page 0 toolbar / IG |
| 139 | TRIGGER | `FORM.KEY-CLRREC` | – | – | – | DROPPED | Designer key handler -> page 0 toolbar / IG |
| 140 | TRIGGER | `FORM.KEY-NXTKEY` | – | – | – | DROPPED | Designer key handler -> page 0 toolbar / IG |
| 141 | TRIGGER | `FORM.KEY-MENU` | – | – | – | DROPPED | Designer key handler -> page 0 toolbar / IG |
| 142 | TRIGGER | `FORM.KEY-CLRFRM` | – | – | – | DROPPED | Designer key handler -> page 0 toolbar / IG |
| 143 | TRIGGER | `TITLE.CGSO$CHAR_ARB_ED.KEY-LISTVAL` | – | – | – | DROPPED | OLB frame (TITLE) |
| 144 | TRIGGER | `TITLE.CGSO$CHAR_ARB_DO_ENB_Y.KEY-LISTVAL` | – | – | – | DROPPED | OLB frame (TITLE) |
| 145 | TRIGGER | `TITLE.CGSO$CHAR_ARB_MLINE.KEY-LISTVAL` | – | – | – | DROPPED | OLB frame (TITLE) |
| 146 | TRIGGER | `TITLE.CGSO$CHAR_ARB.KEY-LISTVAL` | – | – | – | DROPPED | OLB frame (TITLE) |
| 147 | TRIGGER | `TITLE.CGSO$CHAR_ARB_DO.KEY-LISTVAL` | – | – | – | DROPPED | OLB frame (TITLE) |
| 148 | TRIGGER | `TITLE.SYSTEM_DATE.WHEN-VALIDATE-ITEM` | – | – | – | DROPPED | OLB frame (TITLE) |
| 149 | TRIGGER | `EDI_MSG.EDI_MSG_LOVE_BUT.WHEN-BUTTON-PRESSED` | – | – | – | DROPPED | OLB frame (EDI_MSG) |
| 150 | TRIGGER | `LSIDE.FN1.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 151 | TRIGGER | `LSIDE.FN1.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 152 | TRIGGER | `LSIDE.FN1.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 153 | TRIGGER | `LSIDE.FN50.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 154 | TRIGGER | `LSIDE.FN50.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 155 | TRIGGER | `LSIDE.FN50.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 156 | TRIGGER | `LSIDE.FN2.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 157 | TRIGGER | `LSIDE.FN2.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 158 | TRIGGER | `LSIDE.FN2.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 159 | TRIGGER | `LSIDE.FN49.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 160 | TRIGGER | `LSIDE.FN49.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 161 | TRIGGER | `LSIDE.FN49.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 162 | TRIGGER | `LSIDE.FN3.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 163 | TRIGGER | `LSIDE.FN3.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 164 | TRIGGER | `LSIDE.FN3.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 165 | TRIGGER | `LSIDE.FN48.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 166 | TRIGGER | `LSIDE.FN48.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 167 | TRIGGER | `LSIDE.FN48.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 168 | TRIGGER | `LSIDE.FN4.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 169 | TRIGGER | `LSIDE.FN4.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 170 | TRIGGER | `LSIDE.FN4.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 171 | TRIGGER | `LSIDE.FN47.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 172 | TRIGGER | `LSIDE.FN47.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 173 | TRIGGER | `LSIDE.FN47.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 174 | TRIGGER | `LSIDE.FN5.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 175 | TRIGGER | `LSIDE.FN5.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 176 | TRIGGER | `LSIDE.FN5.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 177 | TRIGGER | `LSIDE.FN46.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 178 | TRIGGER | `LSIDE.FN46.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 179 | TRIGGER | `LSIDE.FN46.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 180 | TRIGGER | `LSIDE.FN6.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 181 | TRIGGER | `LSIDE.FN6.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 182 | TRIGGER | `LSIDE.FN6.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 183 | TRIGGER | `LSIDE.FN45.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 184 | TRIGGER | `LSIDE.FN45.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 185 | TRIGGER | `LSIDE.FN45.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 186 | TRIGGER | `LSIDE.FN7.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 187 | TRIGGER | `LSIDE.FN7.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 188 | TRIGGER | `LSIDE.FN7.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 189 | TRIGGER | `LSIDE.FN44.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 190 | TRIGGER | `LSIDE.FN44.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 191 | TRIGGER | `LSIDE.FN44.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 192 | TRIGGER | `LSIDE.FN8.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 193 | TRIGGER | `LSIDE.FN8.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 194 | TRIGGER | `LSIDE.FN8.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 195 | TRIGGER | `LSIDE.FN43.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 196 | TRIGGER | `LSIDE.FN43.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 197 | TRIGGER | `LSIDE.FN43.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 198 | TRIGGER | `LSIDE.FN9.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 199 | TRIGGER | `LSIDE.FN9.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 200 | TRIGGER | `LSIDE.FN9.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 201 | TRIGGER | `LSIDE.FN42.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 202 | TRIGGER | `LSIDE.FN42.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 203 | TRIGGER | `LSIDE.FN42.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 204 | TRIGGER | `LSIDE.FN10.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 205 | TRIGGER | `LSIDE.FN10.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 206 | TRIGGER | `LSIDE.FN10.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 207 | TRIGGER | `LSIDE.FN41.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 208 | TRIGGER | `LSIDE.FN41.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 209 | TRIGGER | `LSIDE.FN41.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 210 | TRIGGER | `LSIDE.FN11.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 211 | TRIGGER | `LSIDE.FN11.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 212 | TRIGGER | `LSIDE.FN11.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 213 | TRIGGER | `LSIDE.FN40.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 214 | TRIGGER | `LSIDE.FN40.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 215 | TRIGGER | `LSIDE.FN40.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 216 | TRIGGER | `LSIDE.FN12.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 217 | TRIGGER | `LSIDE.FN12.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 218 | TRIGGER | `LSIDE.FN12.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 219 | TRIGGER | `LSIDE.FN39.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 220 | TRIGGER | `LSIDE.FN39.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 221 | TRIGGER | `LSIDE.FN39.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 222 | TRIGGER | `LSIDE.FN13.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 223 | TRIGGER | `LSIDE.FN13.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 224 | TRIGGER | `LSIDE.FN13.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 225 | TRIGGER | `LSIDE.FN38.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 226 | TRIGGER | `LSIDE.FN38.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 227 | TRIGGER | `LSIDE.FN38.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 228 | TRIGGER | `LSIDE.FN14.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 229 | TRIGGER | `LSIDE.FN14.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 230 | TRIGGER | `LSIDE.FN14.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 231 | TRIGGER | `LSIDE.FN37.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 232 | TRIGGER | `LSIDE.FN37.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 233 | TRIGGER | `LSIDE.FN37.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 234 | TRIGGER | `LSIDE.FN15.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 235 | TRIGGER | `LSIDE.FN15.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 236 | TRIGGER | `LSIDE.FN15.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 237 | TRIGGER | `LSIDE.FN36.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 238 | TRIGGER | `LSIDE.FN36.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 239 | TRIGGER | `LSIDE.FN36.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 240 | TRIGGER | `LSIDE.FN16.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 241 | TRIGGER | `LSIDE.FN16.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 242 | TRIGGER | `LSIDE.FN16.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 243 | TRIGGER | `LSIDE.FN17.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 244 | TRIGGER | `LSIDE.FN17.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 245 | TRIGGER | `LSIDE.FN17.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 246 | TRIGGER | `LSIDE.FN34.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 247 | TRIGGER | `LSIDE.FN34.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 248 | TRIGGER | `LSIDE.FN34.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 249 | TRIGGER | `LSIDE.FN35.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 250 | TRIGGER | `LSIDE.FN35.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 251 | TRIGGER | `LSIDE.FN35.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 252 | TRIGGER | `LSIDE.FN18.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 253 | TRIGGER | `LSIDE.FN18.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 254 | TRIGGER | `LSIDE.FN18.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 255 | TRIGGER | `LSIDE.FN33.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 256 | TRIGGER | `LSIDE.FN33.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 257 | TRIGGER | `LSIDE.FN33.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 258 | TRIGGER | `LSIDE.FN19.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 259 | TRIGGER | `LSIDE.FN19.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 260 | TRIGGER | `LSIDE.FN19.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 261 | TRIGGER | `LSIDE.FN32.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 262 | TRIGGER | `LSIDE.FN32.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 263 | TRIGGER | `LSIDE.FN32.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 264 | TRIGGER | `LSIDE.FN20.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 265 | TRIGGER | `LSIDE.FN20.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 266 | TRIGGER | `LSIDE.FN20.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 267 | TRIGGER | `LSIDE.FN31.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 268 | TRIGGER | `LSIDE.FN31.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 269 | TRIGGER | `LSIDE.FN31.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 270 | TRIGGER | `LSIDE.FN21.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 271 | TRIGGER | `LSIDE.FN21.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 272 | TRIGGER | `LSIDE.FN21.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 273 | TRIGGER | `LSIDE.FN30.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 274 | TRIGGER | `LSIDE.FN30.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 275 | TRIGGER | `LSIDE.FN30.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 276 | TRIGGER | `LSIDE.FN22.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 277 | TRIGGER | `LSIDE.FN22.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 278 | TRIGGER | `LSIDE.FN22.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 279 | TRIGGER | `LSIDE.FN29.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 280 | TRIGGER | `LSIDE.FN29.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 281 | TRIGGER | `LSIDE.FN29.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 282 | TRIGGER | `LSIDE.FN23.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 283 | TRIGGER | `LSIDE.FN23.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 284 | TRIGGER | `LSIDE.FN23.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 285 | TRIGGER | `LSIDE.FN28.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 286 | TRIGGER | `LSIDE.FN28.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 287 | TRIGGER | `LSIDE.FN28.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 288 | TRIGGER | `LSIDE.FN24.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 289 | TRIGGER | `LSIDE.FN24.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 290 | TRIGGER | `LSIDE.FN24.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 291 | TRIGGER | `LSIDE.FN27.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 292 | TRIGGER | `LSIDE.FN27.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 293 | TRIGGER | `LSIDE.FN27.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 294 | TRIGGER | `LSIDE.FN25.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 295 | TRIGGER | `LSIDE.FN25.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 296 | TRIGGER | `LSIDE.FN25.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 297 | TRIGGER | `LSIDE.FN26.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 298 | TRIGGER | `LSIDE.FN26.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 299 | TRIGGER | `LSIDE.FN26.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 300 | TRIGGER | `TOOLBAR.KEY-DOWN` | – | – | – | DROPPED | OLB toolbar / side-menu keyboard |
| 301 | TRIGGER | `TOOLBAR.KEY-UP` | – | – | – | DROPPED | OLB toolbar / side-menu keyboard |
| 302 | TRIGGER | `TOOLBAR.KEY-NEXT-ITEM` | – | – | – | DROPPED | OLB toolbar / side-menu keyboard |
| 303 | TRIGGER | `TOOLBAR.SAVE.WHEN-BUTTON-PRESSED` | SAVE (page 0 toolbar) | 0 | – | MAPPED | toolbar button |
| 304 | TRIGGER | `TOOLBAR.CLEAR_ALL.WHEN-BUTTON-PRESSED` | CLEAR (page 0 toolbar) | 0 | – | MAPPED | toolbar button |
| 305 | TRIGGER | `TOOLBAR.EXIT.WHEN-BUTTON-PRESSED` | BACK (page 0 toolbar) | 0 | – | MAPPED | toolbar button |
| 306 | TRIGGER | `TOOLBAR.EXIT1.WHEN-BUTTON-PRESSED` | BACK (page 0 toolbar) | 0 | – | MAPPED | toolbar button |
| 307 | TRIGGER | `TOOLBAR.ENTER.WHEN-BUTTON-PRESSED` | SEARCH (page 0 toolbar) | 0 | – | MAPPED | toolbar button |
| 308 | TRIGGER | `TOOLBAR.EXECUTE.WHEN-BUTTON-PRESSED` | SEARCH (page 0 toolbar) | 0 | – | MAPPED | toolbar button |
| 309 | TRIGGER | `TOOLBAR.REMOVE.WHEN-BUTTON-PRESSED` | DELETE (page 0 toolbar) / IG row delete | 0 | – | MAPPED | toolbar button |
| 310 | TRIGGER | `TOOLBAR.LIST_VALUE.WHEN-BUTTON-PRESSED` | – | – | – | DROPPED | OLB toolbar / side-menu keyboard |
| 311 | TRIGGER | `TOOLBAR.HELP.WHEN-BUTTON-PRESSED` | – | – | – | DROPPED | OLB toolbar / side-menu keyboard |
| 312 | TRIGGER | `TOOLBAR.LAST_REC.WHEN-BUTTON-PRESSED` | – | – | – | DROPPED | OLB toolbar / side-menu keyboard |
| 313 | TRIGGER | `TOOLBAR.RE_ENTER_QUERY.WHEN-BUTTON-PRESSED` | SEARCH (page 0 toolbar) | 0 | – | MAPPED | toolbar button |
| 314 | TRIGGER | `TOOLBAR.FIRST_REC.WHEN-BUTTON-PRESSED` | – | – | – | DROPPED | OLB toolbar / side-menu keyboard |
| 315 | TRIGGER | `TOOLBAR.PAGE_UP.WHEN-BUTTON-PRESSED` | – | – | – | DROPPED | OLB toolbar / side-menu keyboard |
| 316 | TRIGGER | `TOOLBAR.PAGE_DOWN.WHEN-BUTTON-PRESSED` | – | – | – | DROPPED | OLB toolbar / side-menu keyboard |
| 317 | TRIGGER | `TOOLBAR.FUN_BUT.WHEN-MOUSE-UP` | FUNCS (page 0 toolbar) | 0 | – | MAPPED | toolbar button |
| 318 | TRIGGER | `TOOLBAR.FUN_BUT.WHEN-MOUSE-DOWN` | FUNCS (page 0 toolbar) | 0 | – | MAPPED | toolbar button |
| 319 | TRIGGER | `HQ_IMPRS.ON-ERROR` | APP_ERROR_HANDLER (f345) | – | – | MAPPED | Designer constraint messages |
| 320 | TRIGGER | `HQ_IMPRS.KEY-HELP` | – | – | – | DROPPED | MS-Help obsolete |
| 321 | TRIGGER | `HQ_IMPRS.ON-DELETE` | – | – | – | DROPPED | body NULL: the master is never written (Form region without Process form) |
| 322 | TRIGGER | `HQ_IMPRS.ON-INSERT` | – | – | – | DROPPED | body NULL: the master is never written (Form region without Process form) |
| 323 | TRIGGER | `HQ_IMPRS.ON-UPDATE` | – | – | – | DROPPED | body NULL: the master is never written (Form region without Process form) |
| 324 | TRIGGER | `HQ_IMPRS.POST-QUERY` | POST-QUERY + DA HQ_IMPRS POST-QUERY (Confirm -> dialog 112502) | 1125 | IMPR1125.HQ_IMPRS_POST_QUERY | MAPPED | lookups; released-suspension count -> RELEASED_SUSPENSIONS_EXIST; CONFIRM + DELETE_SUSPS_LOV -> DA |
| 325 | TRIGGER | `HQ_IMPRS.PRE-QUERY` | HQ_IMPR_NBR EXECUTE-QUERY / BUS_ID EXECUTE-QUERY (P0_PAGE_PK) | 1125 | – | MAPPED | :GLOBAL.HQ_IMPR_NBR / BUS_NBR criteria -> ROWID of the first matching HQ_IMPRS row |
| 326 | TRIGGER | `HQ_IMPRS.WHEN-NEW-ITEM-INSTANCE` | HQ_IMPR_NBR / BUS_ID WHEN-VALIDATE-ITEM (Submit EXECUTE_QUERY) | 1125 | – | MAPPED | CLEAR_BLOCK + GO_BLOCK + EXECUTE_QUERY -> page submit + branch |
| 327 | TRIGGER | `HQ_IMPRS.BUS_ID.KEY-LISTVAL` | 112501 IMPR1125_SEARCH (page 0 SEARCH) | 112501 | – | MAPPED | SINGLE_IMP_LOV |
| 328 | TRIGGER | `HQ_IMPRS.BUS_ID.WHEN-VALIDATE-ITEM` | BUS_ID VALIDATION + DA BUS_ID WHEN-VALIDATE-ITEM + process BUS_ID EXECUTE-QUERY | 1125 | IMPR1125.BUS_ID_VALIDATION | MAPPED | also IMPR1125.BUS_ID_WHEN_VALIDATE_ITEM; SINGLE_IMP_LOV on error -> page 0 SEARCH |
| 329 | TRIGGER | `HQ_IMPRS.BUT_SH_HQNUM.WHEN-BUTTON-PRESSED` | 112501 IMPR1125_SEARCH (page 0 SEARCH) | 112501 | – | MAPPED | GO_ITEM BUS_ID + DO_KEY LIST_VALUES |
| 330 | TRIGGER | `HQ_IMPRS.BUS_ID_TYPE_CD.KEY-LISTVAL` | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 331 | TRIGGER | `HQ_IMPRS.BUS_ID_TYPE_NAME.KEY-LISTVAL` | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 332 | TRIGGER | `HQ_IMPRS.BUS_ID_BRNCH.KEY-LISTVAL` | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 333 | TRIGGER | `HQ_IMPRS.HQ_IMPR_NBR.KEY-LISTVAL` | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 334 | TRIGGER | `HQ_IMPRS.HQ_IMPR_NBR.WHEN-VALIDATE-ITEM` | HQ_IMPR_NBR VALIDATION + DA HQ_IMPR_NBR WHEN-VALIDATE-ITEM + process HQ_IMPR_NBR EXECUTE-QUERY | 1125 | IMPR1125.HQ_IMPR_NBR_VALIDATION | MAPPED | also IMPR1125.HQ_IMPR_NBR_WHEN_VALIDATE_ITEM |
| 335 | TRIGGER | `HQ_IMPRS.CITY_CODE_OF_ID.KEY-LISTVAL` | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 336 | TRIGGER | `HQ_IMPRS.CITY_CODE_OF_NAME.KEY-LISTVAL` | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 337 | TRIGGER | `HQ_IMPRS.IMPR_TYPE_CD.KEY-LISTVAL` | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 338 | TRIGGER | `HQ_IMPRS.IMPR_TYPE_NAME.KEY-LISTVAL` | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 339 | TRIGGER | `HQ_IMPRS.CTRY_CD.KEY-LISTVAL` | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 340 | TRIGGER | `HQ_IMPRS.CRTY_ARBC_NAME.KEY-LISTVAL` | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 341 | TRIGGER | `HQ_IMPRS.ARBC_IMPR_NAME.KEY-LISTVAL` | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 342 | TRIGGER | `HQ_IMPRS.ENG_IMPR_NAME.KEY-LISTVAL` | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 343 | TRIGGER | `IMPR_CNTRL_SUSPNS.ON-ERROR` | APP_ERROR_HANDLER (f345) | – | – | MAPPED | Designer constraint messages |
| 344 | TRIGGER | `IMPR_CNTRL_SUSPNS.KEY-HELP` | – | – | – | DROPPED | MS-Help obsolete |
| 345 | TRIGGER | `IMPR_CNTRL_SUSPNS.KEY-DELREC` | IMPR_CNTRL_SUSPNS row delete | 1125 | – | MAPPED | TMPLT.KEY_DELETE_RECORD: confirm + delete + COMMIT -> IG delete, APEX commit |
| 346 | TRIGGER | `IMPR_CNTRL_SUSPNS.ON-DELETE` | IMPR_CNTRL_SUSPNS - Save Interactive Grid Data | 1125 | IMPR1125.IMPR_CNTRL_SUSPNS_ON_DELETE | MAPPED | soft delete, called by IMPR_CNTRL_SUSPNS_SAVE_ROW (row status D) |
| 347 | TRIGGER | `IMPR_CNTRL_SUSPNS.POST-INSERT` | IMPR_CNTRL_SUSPNS - Save Interactive Grid Data | 1125 | IMPR1125.IMPR_CNTRL_SUSPNS_POST_INSERT | MAPPED | called by IMPR_CNTRL_SUSPNS_SAVE_ROW; COMMIT removed (HIGH) |
| 348 | TRIGGER | `IMPR_CNTRL_SUSPNS.PRE-INSERT` | IMPR_CNTRL_SUSPNS - Save Interactive Grid Data | 1125 | IMPR1125.IMPR_CNTRL_SUSPNS_PRE_INSERT | MAPPED | called by IMPR_CNTRL_SUSPNS_SAVE_ROW (row status C) |
| 349 | TRIGGER | `IMPR_CNTRL_SUSPNS.PRE-UPDATE` | IMPR_CNTRL_SUSPNS - Save Interactive Grid Data | 1125 | IMPR1125.IMPR_CNTRL_SUSPNS_PRE_UPDATE | MAPPED | called by IMPR_CNTRL_SUSPNS_SAVE_ROW (row status U) |
| 350 | TRIGGER | `IMPR_CNTRL_SUSPNS.SUSPN_STRT_DT.KEY-LISTVAL` | – | – | – | DROPPED | INTRFACE.DISP_CALENDAR -> Hijri date column (hijri-date-default) |
| 351 | TRIGGER | `IMPR_CNTRL_SUSPNS.SUSPN_STRT_DT.KEY-F4` | – | – | – | DROPPED | INTRFACE.DISP_DATE_CON -> Hijri date column |
| 352 | TRIGGER | `IMPR_CNTRL_SUSPNS.SUSPN_STRT_DT.WHEN-VALIDATE-ITEM` | IMPR_CNTRL_SUSPNS SUSPN_STRT_DT VALIDATION + DA IMPR_CNTRL_SUSPNS SUSPN_STRT_DT WHEN-VALIDATE-ITEM | 1125 | IMPR1125.SUSPN_STRT_DT_VALIDATION | MAPPED | – |
| 353 | TRIGGER | `IMPR_CNTRL_SUSPNS.SUSPN_END_DT.KEY-LISTVAL` | – | – | – | DROPPED | INTRFACE.DISP_CALENDAR -> Hijri date column (hijri-date-default) |
| 354 | TRIGGER | `IMPR_CNTRL_SUSPNS.SUSPN_END_DT.KEY-F4` | – | – | – | DROPPED | INTRFACE.DISP_DATE_CON -> Hijri date column |
| 355 | TRIGGER | `IMPR_CNTRL_SUSPNS.SUSPN_END_DT.WHEN-VALIDATE-ITEM` | IMPR_CNTRL_SUSPNS SUSPN_END_DT VALIDATION + DA IMPR_CNTRL_SUSPNS SUSPN_END_DT WHEN-VALIDATE-ITEM | 1125 | IMPR1125.SUSPN_END_DT_VALIDATION | MAPPED | – |
| 356 | TRIGGER | `IMPR_CNTRL_SUSPNS.SUSPN_SEQ.KEY-LISTVAL` | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 357 | TRIGGER | `IMPR_CNTRL_SUSPNS.SUSPN_RSN_TEXT.KEY-LISTVAL` | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 358 | RELATION | `CGFK$ICS_HI_FK` | IMPR_CNTRL_SUSPNS (IG WHERE hq_impr_nbr = :P1125_HQ_IMPR_NBR) | 1125 | – | MAPPED | HQ_IMPRS -> IMPR_CNTRL_SUSPNS; master key from the master form (column default + NVL in the save call) |
| 359 | LOV | `CGFK$HQ_IMPRS_BUS_ID_TYPE_CD` | – | – | – | DROPPED | item BUS_ID_TYPE_CD is display only; name from HQ_IMPRS_POST_QUERY |
| 360 | RECORD_GROUP | `CGFK$HQ_IMPRS_BUS_ID_TYPE_CD` | – | – | – | DROPPED | query of LOV CGFK$HQ_IMPRS_BUS_ID_TYPE_CD |
| 361 | RECORD_GROUP | `CGDV$DLRG (runtime)` | LOV_ALLOWED_EXPORT (IMPR1110), LOV_SUSPN_SIDE_CD (IMPR1120) | 1125 | – | MAPPED | CREATE_GROUP_FROM_QUERY on CG_REF_CODES; IMPR_SUSPN_RSN_CD list not needed (column hidden, meaning joined on 112502) |
| 362 | CANVAS | `LSIDE` | – | – | – | DROPPED | OLB canvas LSIDE |
| 363 | CANVAS | `EDI_MSG` | – | – | – | DROPPED | OLB canvas EDI_MSG |
| 364 | CANVAS | `TITLE` | – | – | – | DROPPED | OLB canvas TITLE |
| 365 | CANVAS | `TOOLBAR` | – | – | – | DROPPED | OLB canvas TOOLBAR |
| 366 | CANVAS | `CG$PAGE_1` | 1125 IMPR1125 | 1125 | – | MAPPED | main content canvas |
| 367 | WINDOW | `CGSO$WINDOW_1` | 1125 IMPR1125 | 1125 | – | MAPPED | console window |
| 368 | ALERT | `CG$ASK_COMMIT` | – | – | – | DROPPED | not used by IMPR1125 code |
| 369 | ALERT | `USR_CONFIRM_B` | – | – | – | DROPPED | not used by IMPR1125 code |
| 370 | ALERT | `USR_CONFIRM` | HQ_IMPRS POST-QUERY native Confirm | 1125 | – | MAPPED | STR.DispALERT CONFIRM (released suspensions) |
| 371 | ALERT | `USR_WARNING_C` | – | – | – | DROPPED | not used by IMPR1125 code |
| 372 | ALERT | `USR_WARNING_B` | IG row delete (restorable until SAVE) | 1125 | – | MAPPED | TMPLT.KEY_DELETE_RECORD |
| 373 | ALERT | `CFG_WARNING_A` | – | – | – | DROPPED | not used by IMPR1125 code |
| 374 | ALERT | `CFG_INFORMATION` | page messages (f345) | 1125 | – | MAPPED | NIB.ON_MESSAGE |
| 375 | ALERT | `CFG_ERROR` | validation error texts / FORMS_APX.FORM_TRIGGER_FAILURE | 1125 | – | MAPPED | STR.DISPALERT ERROR (literal texts) |
| 376 | ALERT | `CFG_SYSTEM_ERROR` | FORMS_APX.FORM_TRIGGER_FAILURE (activity log / Hijri date errors) | 1125 | – | MAPPED | – |
| 377 | ALERT | `CFG_ASK_COMMIT` | – | – | – | DROPPED | not used by IMPR1125 code |
| 378 | PARAMETER | `P_SHPG_AGNT_NBR` | – | – | – | DROPPED | not used by the business code (function menu / reports / frame) |
| 379 | PARAMETER | `P_CTRL_LAST_EXEC_CD` | – | – | – | DROPPED | not used by the business code (function menu / reports / frame) |
| 380 | PARAMETER | `P_BANK_CD` | – | – | – | DROPPED | not used by the business code (function menu / reports / frame) |
| 381 | PARAMETER | `P_BANK_BRNCH_CD` | – | – | – | DROPPED | not used by the business code (function menu / reports / frame) |
| 382 | PARAMETER | `P_BRKR_PORT_CD` | – | – | – | DROPPED | not used by the business code (function menu / reports / frame) |
| 383 | PARAMETER | `P_LIC_TYPE` | – | – | – | DROPPED | not used by the business code (function menu / reports / frame) |
| 384 | PARAMETER | `P_BRKR_NBR` | – | – | – | DROPPED | not used by the business code (function menu / reports / frame) |
| 385 | PARAMETER | `P_CLASS_CD` | – | – | – | DROPPED | not used by the business code (function menu / reports / frame) |
| 386 | PARAMETER | `P_JOB_ID` | – | – | – | DROPPED | not used by the business code (function menu / reports / frame) |
| 387 | PARAMETER | `P_CURRENT_ITEM` | – | – | – | DROPPED | not used by the business code (function menu / reports / frame) |
| 388 | PARAMETER | `P_GROUP_CD` | – | – | – | DROPPED | not used by the business code (function menu / reports / frame) |
| 389 | PARAMETER | `P_USER_TYPE` | – | – | – | DROPPED | not used by the business code (function menu / reports / frame) |
| 390 | PARAMETER | `P_PORT_TYPE` | – | – | – | DROPPED | not used by the business code (function menu / reports / frame) |
| 391 | PARAMETER | `P_CURR_PORT_CD` | P_CURR_PORT_CD (f345) | – | – | MAPPED | NE_INTEGRATION setting, SMS port, activity log |
| 392 | PARAMETER | `P_MODULE_ID` | P1125_MODULE_ID | 1125 | – | MAPPED | FORMS_APX.GET_MODULE_ID |
| 393 | PARAMETER | `P_MODULE_NAME` | SYS_ANAME (f345 page title) | – | – | MAPPED | title bar only |
| 394 | PARAMETER | `P_APPLICATION_NAME` | – | – | – | DROPPED | not used by the business code (function menu / reports / frame) |
| 395 | PARAMETER | `P_USER_ID` | SSO_APP_USER (f345) | – | – | MAPPED | ACTIVITY_DB user |
| 396 | PARAMETER | `P_WS_ID` | P_GLOBAL_V_WS_ID (f345) | – | – | MAPPED | ACTIVITY_DB workstation |
| 397 | PARAMETER | `P_USER_NAME` | V_USR_NAME (f345 header) | – | – | MAPPED | title bar only |
| 398 | PARAMETER | `CG$STARTUP_MODE` | – | – | – | DROPPED | not used by the business code (function menu / reports / frame) |
| 399 | PARAMETER | `CURRENT_SIDE` | – | – | – | DROPPED | declared but read nowhere in IMPR1125 |
| 400 | LIBRARY | `OFGTEL` | – | – | – | TODO | MISSING SOURCE - constraint messages (CGTE$) |
| 401 | LIBRARY | `OFGMES` | – | – | – | DROPPED | not needed in the browser (help, DLL, window, tab, pick list) |
| 402 | LIBRARY | `OFGHPL` | – | – | – | DROPPED | not needed in the browser (help, DLL, window, tab, pick list) |
| 403 | LIBRARY | `CIC_AMSG` | – | – | – | MAPPED | Des$Form_errors messages -> FORMS_APX / APP_ERROR_HANDLER |
| 404 | LIBRARY | `SEC_LIB` | – | – | – | DROPPED | not needed in the browser (help, DLL, window, tab, pick list) |
| 405 | LIBRARY | `CAPTION` | – | – | – | DROPPED | not needed in the browser (help, DLL, window, tab, pick list) |
| 406 | LIBRARY | `OFGBSL` | – | – | – | MAPPED | CGBS$ master-detail -> native Form + IG |
| 407 | LIBRARY | `D2KWUTIL` | – | – | – | DROPPED | not needed in the browser (help, DLL, window, tab, pick list) |
| 408 | LIBRARY | `CUSTOMDLL` | – | – | – | DROPPED | not needed in the browser (help, DLL, window, tab, pick list) |
| 409 | LIBRARY | `D2KWUTIL_PDF` | – | – | – | DROPPED | not needed in the browser (help, DLL, window, tab, pick list) |
| 410 | LIBRARY | `GETCOMP` | – | – | – | DROPPED | not needed in the browser (help, DLL, window, tab, pick list) |
| 411 | LIBRARY | `OFGTAB` | – | – | – | DROPPED | not needed in the browser (help, DLL, window, tab, pick list) |
| 412 | LIBRARY | `PICKLIST` | – | – | – | DROPPED | not needed in the browser (help, DLL, window, tab, pick list) |
| 413 | LIBRARY | `POS` | – | – | – | DROPPED | not needed in the browser (help, DLL, window, tab, pick list) |
| 414 | LIBRARY | `SCDLL` | – | – | – | DROPPED | not needed in the browser (help, DLL, window, tab, pick list) |
| 415 | LIBRARY | `VCDLL` | – | – | – | DROPPED | not needed in the browser (help, DLL, window, tab, pick list) |
| 416 | LIBRARY | `CIC_LIB` | – | – | – | MAPPED | NIB / TMPLT -> f345; STR.DispAlert -> literal texts; HIJDATE -> FORMS_APX / HIJDATE_DB; ACTIVITY -> ACTIVITY_DB; INTRFACE -> date column |
| 417 | GLOBAL | `BUS_ID` | P0_PAGE_PK (search page link) | 1125 | – | MAPPED | no G_ application item needed |
| 418 | GLOBAL | `BUS_NBR` | P0_PAGE_PK (process BUS_ID EXECUTE-QUERY) | 1125 | – | MAPPED | no G_ application item needed |
| 419 | GLOBAL | `CG$HP_HFILE` | – | – | – | DROPPED | Designer internal / version stamp / frame - not needed |
| 420 | GLOBAL | `CG$HP_HPATH` | – | – | – | DROPPED | Designer internal / version stamp / frame - not needed |
| 421 | GLOBAL | `CG$QUERY_MODE` | – | – | – | DROPPED | Designer internal / version stamp / frame - not needed |
| 422 | GLOBAL | `CURRENT_VER` | – | – | – | DROPPED | Designer internal / version stamp / frame - not needed |
| 423 | GLOBAL | `EXIT` | – | – | – | DROPPED | Designer internal / version stamp / frame - not needed |
| 424 | GLOBAL | `HQ_IMPR_NBR` | P0_PAGE_PK (process HQ_IMPR_NBR EXECUTE-QUERY / search link) | 1125 | – | MAPPED | no G_ application item needed |
| 425 | GLOBAL | `SYSTEM_OBJ` | – | – | – | DROPPED | Designer internal / version stamp / frame - not needed |
| 426 | CALLED_FORM | `LOV_IMPORT_HQ_NBR` | 112501 IMPR1125_SEARCH | 112501 | – | MAPPED | SINGLE_IMP_LOV |
| 427 | CALLED_FORM | `LOV_DELETE_IMP_SUSP` | 112502 IMPR1125_DELETED_SUSPENSIONS | 112502 | IMPR1125.RELEASED_SUSPENSIONS_EXIST | MAPPED | DELETE_SUSPS_LOV (P_HQ_IMPR_NBR -> P112502_P_HQ_IMPR_NBR with checksum) |
| 428 | CALLED_FORM | `V_CALLED_FORM (dynamic, PU EXECUTE_FUNCTION)` | FUNCS (page 0, Page Functions list) | 0 | – | TODO | functions of the module in SC_SYSTEM_OBJECTS unknown (inventory §15 #8) |
| 429 | CALLED_FORM | `calendar forms (INTRFACE.DISP_CALENDAR / DISP_DATE_CON)` | hijri-date-default date columns | 1125 | – | MAPPED | date KEY-LISTVAL / KEY-F4 |
| 430 | PROGRAM_UNIT | `CHECK_TIMEOUT` | – | – | – | DROPPED | not called by active code (NIB wrapper / query-mode toggle) |
| 431 | PROGRAM_UNIT | `MOUSE_CLICK` | – | – | – | DROPPED | f345 Page Functions (FUNCS) |
| 432 | PROGRAM_UNIT | `TOGGEL_WND` | – | – | – | DROPPED | not called by active code (NIB wrapper / query-mode toggle) |
| 433 | PROGRAM_UNIT | `PRINT_REPORT` | – | – | – | DROPPED | not called by active code (NIB wrapper / query-mode toggle) |
| 434 | PROGRAM_UNIT | `EXECUTE_FUNCTION` | – | – | – | DROPPED | f345 Page Functions (FUNCS) |
| 435 | PROGRAM_UNIT | `TERMINATE_FUN` | – | – | – | DROPPED | not called by active code (NIB wrapper / query-mode toggle) |
| 436 | PROGRAM_UNIT | `CHECK_EDI_MSG_LOV` | – | – | – | DROPPED | not called by active code (NIB wrapper / query-mode toggle) |
| 437 | PROGRAM_UNIT | `CHECK_EDI_MSG_TIMER` | – | – | – | DROPPED | not called by active code (NIB wrapper / query-mode toggle) |
| 438 | PROGRAM_UNIT | `CHECK_EDI_ROLE_ID` | – | – | – | DROPPED | not called by active code (NIB wrapper / query-mode toggle) |
| 439 | PROGRAM_UNIT | `EDI_MSG_LOV` | – | – | – | DROPPED | not called by active code (NIB wrapper / query-mode toggle) |
| 440 | PROGRAM_UNIT | `FOR_EDI_MSG` | – | – | – | DROPPED | not called by active code (NIB wrapper / query-mode toggle) |
| 441 | PROGRAM_UNIT | `RETURN_MSG` | – | – | – | DROPPED | not called by active code (NIB wrapper / query-mode toggle) |
| 442 | PROGRAM_UNIT | `TURN_MSG` | – | – | – | DROPPED | not called by active code (NIB wrapper / query-mode toggle) |
| 443 | PROGRAM_UNIT | `WHEN_TIMER_EXPIRED_MSG` | – | – | – | DROPPED | not called by active code (NIB wrapper / query-mode toggle) |
| 444 | PROGRAM_UNIT | `CG$WHEN_NEW_FORM_INSTANCE` | – | – | – | DROPPED | lists + block-sync startup -> shared LOVs / native master-detail |
| 445 | PROGRAM_UNIT | `CGDV$POPULATE_DYNAMIC_LISTS` | – | – | – | DROPPED | shared LOVs on CG_REF_CODES |
| 446 | PROGRAM_UNIT | `CGUV$CHK_HI_PK` | – | – | – | DROPPED | not called; HQ_IMPR_NBR_VALIDATION does the same check |
| 447 | PROGRAM_UNIT | `CGFK$CHK_IMPR_CNTRL_SUSPNS_ICS` | – | – | – | DROPPED | not called; foreign key ICS_HI_FK in the database |
| 448 | PROGRAM_UNIT | `CGTE$CHECK_CONSTRAINT_VIO` | – | – | – | DROPPED | APP_ERROR_HANDLER |
| 449 | PROGRAM_UNIT | `CGBS$TOGGLE` | – | – | – | DROPPED | not called by active code (NIB wrapper / query-mode toggle) |
| 450 | PROGRAM_UNIT | `CGBS$SET_QUERY_MODE` | – | – | – | DROPPED | not called by active code (NIB wrapper / query-mode toggle) |
| 451 | PROGRAM_UNIT | `CGBS$MESSAGE_QUERY_MODE` | – | – | – | DROPPED | not called by active code (NIB wrapper / query-mode toggle) |
| 452 | PROGRAM_UNIT | `SINGLE_IMP_LOV` | 112501 IMPR1125_SEARCH | 112501 | – | MAPPED | CALL_FORM LOV_IMPORT_HQ_NBR |
| 453 | PROGRAM_UNIT | `EXEC_FUNS` | – | – | – | DROPPED | empty in Forms |
| 454 | PROGRAM_UNIT | `DELETE_SUSPS_LOV` | 112502 IMPR1125_DELETED_SUSPENSIONS | 112502 | – | MAPPED | CALL_FORM LOV_DELETE_IMP_SUSP |
| 455 | PROGRAM_UNIT | `ADJ_FUNS` | – | – | – | DROPPED | empty in Forms |
