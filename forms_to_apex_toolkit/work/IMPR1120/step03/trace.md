515 objects: DROPPED 396, MAPPED 117, TODO 2. By type: ALERT 10, BLOCK 6, CALLED_FORM 6, CANVAS 5, GLOBAL 17, ITEM 117, LIBRARY 17, LOV 5, PARAMETER 22, PROGRAM_UNIT 33, RECORD_GROUP 6, RELATION 1, TRIGGER 269, WINDOW 1.

| # | Type | Forms object | APEX component | Page | Package member | Status | Notes |
|---|---|---|---|---|---|---|---|
| 1 | BLOCK | `TITLE` | IMPORTERS_HERO | 1120 | IMPR1120.HEADER_TITLE | MAPPED | OLB title bar -> hero region (HEADER TITLE) |
| 2 | BLOCK | `EDI_MSG` | – | – | – | DROPPED | OLB EDI message ticker - dropped (timers, IMPR1110 decision 2026-11-19) |
| 3 | BLOCK | `LSIDE` | FUNCS | 1120 | – | MAPPED | OLB side function menu -> inline dialog FUNCS, f345 list Page Functions |
| 4 | BLOCK | `TOOLBAR` | P0_ACTIONS (page 0 toolbar, f345) | 0 | – | MAPPED | OLB toolbar -> f345 page 0 toolbar |
| 5 | BLOCK | `IMPORTERS` | IMPORTERS (Form region, table IMPORTERS, primary key ROWID, read only) | 1120 | – | MAPPED | master, query only; search page 112001 = Enter / Execute Query |
| 6 | BLOCK | `IMPR_SUSPN` | IMPR_SUSPN (editable Interactive Grid on IMPR_SUSPNS) | 1120 | IMPR1120.IMPR_SUSPN_SAVE_ROW | MAPPED | detail; WHERE SUSPN_RLSE_DT IS NULL; DML through IMPR_SUSPN_SAVE_ROW (soft delete) |
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
| 76 | ITEM | `TOOLBAR.ENTER` | SEARCH (page 0 toolbar) | 0 | – | MAPPED | Enter Query -> search page 112001 |
| 77 | ITEM | `TOOLBAR.EXECUTE` | SEARCH (page 0 toolbar) | 0 | – | MAPPED | Execute Query -> search page 112001 |
| 78 | ITEM | `TOOLBAR.REMOVE` | DELETE (page 0 toolbar) / IG row delete | 0 | – | MAPPED | importer: refused by PRE-DELETE (Delete Allowed = No); suspension: IG row delete |
| 79 | ITEM | `TOOLBAR.LIST_VALUE` | – | – | – | DROPPED | popup LOV icon of the item |
| 80 | ITEM | `TOOLBAR.HELP` | – | – | – | DROPPED | MS-Help obsolete |
| 81 | ITEM | `TOOLBAR.LAST_REC` | – | – | – | DROPPED | OLB toolbar item (record navigation / frame) |
| 82 | ITEM | `TOOLBAR.RE_ENTER_QUERY` | SEARCH (page 0 toolbar) | 0 | – | MAPPED | – |
| 83 | ITEM | `TOOLBAR.FIRST_REC` | – | – | – | DROPPED | OLB toolbar item (record navigation / frame) |
| 84 | ITEM | `TOOLBAR.PAGE_UP` | – | – | – | DROPPED | OLB toolbar item (record navigation / frame) |
| 85 | ITEM | `TOOLBAR.PAGE_DOWN` | – | – | – | DROPPED | OLB toolbar item (record navigation / frame) |
| 86 | ITEM | `TOOLBAR.FUN_BUT` | FUNCS (page 0 toolbar) | 0 | – | MAPPED | – |
| 87 | ITEM | `IMPORTERS.PORT_CD` | P1120_PORT_CD | 1120 | – | MAPPED | Popup LOV LOV_SD_PORTS, read only unless port 99 and no record (PORT_CD_IS_READ_ONLY) |
| 88 | ITEM | `IMPORTERS.PORT_CD2` | – | – | – | DROPPED | LOV button -> popup LOV icon |
| 89 | ITEM | `IMPORTERS.PORT_NAME` | P1120_PORT_NAME | 1120 | – | MAPPED | Display Only (POST-QUERY / WHEN-CREATE-RECORD / LOV additional output) |
| 90 | ITEM | `IMPORTERS.HQ_IMPR_NBR` | P1120_HQ_IMPR_NBR | 1120 | – | MAPPED | Display Only |
| 91 | ITEM | `IMPORTERS.IMPR_NBR` | P1120_IMPR_NBR | 1120 | – | MAPPED | Number Field, editable only while P0_PAGE_PK is null (entry of the importer) |
| 92 | ITEM | `IMPORTERS.SDP_PORT_STATUS` | – | – | – | DROPPED | hidden lookup status, read nowhere |
| 93 | ITEM | `IMPORTERS.IMPR_TYPE_CD` | P1120_IMPR_TYPE_CD | 1120 | – | MAPPED | Display Only |
| 94 | ITEM | `IMPORTERS.IMPR_TYPE_CD2` | – | – | – | DROPPED | LOV button (item is display only) |
| 95 | ITEM | `IMPORTERS.IMPR_TYPE_NAME` | P1120_IMPR_TYPE_NAME | 1120 | – | MAPPED | Display Only (POST-QUERY) |
| 96 | ITEM | `IMPORTERS.CTRY_CD` | P1120_CTRY_CD | 1120 | – | MAPPED | Display Only |
| 97 | ITEM | `IMPORTERS.CTRY_CD2` | – | – | – | DROPPED | LOV button (item is display only) |
| 98 | ITEM | `IMPORTERS.CRTY_ARBC_NAME` | P1120_CRTY_ARBC_NAME | 1120 | – | MAPPED | Display Only (POST-QUERY) |
| 99 | ITEM | `IMPORTERS.CITY_CODE_OF_ID` | P1120_CITY_CODE_OF_ID | 1120 | – | MAPPED | Display Only |
| 100 | ITEM | `IMPORTERS.CITY_CODE_OF_ID2` | – | – | – | DROPPED | LOV button (item is display only) |
| 101 | ITEM | `IMPORTERS.ID_CITY_NAME` | P1120_ID_CITY_NAME | 1120 | – | MAPPED | Display Only (POST-QUERY) |
| 102 | ITEM | `IMPORTERS.IMPR_EXPR_TYPE` | P1120_IMPR_EXPR_TYPE | 1120 | – | MAPPED | Display Only, LOV_ALLOWED_EXPORT |
| 103 | ITEM | `IMPORTERS.BUS_ID` | P1120_BUS_ID | 1120 | – | MAPPED | Display Only |
| 104 | ITEM | `IMPORTERS.BUS_ID_TYPE_CD` | P1120_BUS_ID_TYPE_CD | 1120 | – | MAPPED | Display Only |
| 105 | ITEM | `IMPORTERS.BUTT` | – | – | – | DROPPED | LOV button of BUS_ID_TYPE_CD (item is display only) |
| 106 | ITEM | `IMPORTERS.BUS_ID_TYPE_NAME` | P1120_BUS_ID_TYPE_NAME | 1120 | – | MAPPED | Display Only (POST-QUERY) |
| 107 | ITEM | `IMPORTERS.BUS_ID_BRNCH` | P1120_BUS_ID_BRNCH | 1120 | – | MAPPED | Display Only |
| 108 | ITEM | `IMPORTERS.CTRY_CTRY_STATUS` | – | – | – | DROPPED | hidden lookup status, read nowhere |
| 109 | ITEM | `IMPORTERS.STATUS` | – | – | – | DROPPED | hidden lookup status, read nowhere |
| 110 | ITEM | `IMPORTERS.ARBC_IMPR_NAME` | P1120_ARBC_IMPR_NAME | 1120 | – | MAPPED | Display Only |
| 111 | ITEM | `IMPORTERS.ENG_IMPR_NAME` | P1120_ENG_IMPR_NAME | 1120 | – | MAPPED | Display Only |
| 112 | ITEM | `IMPORTERS.IMPR_CNTCT_NAME` | P1120_IMPR_CNTCT_NAME | 1120 | – | MAPPED | Display Only |
| 113 | ITEM | `IMPORTERS.IMPR_NAME_STD` | search filter on IMPR_NAME_STD (page 112001 SQL) | 112001 | IMPR1120.IMPORTERS_PRE_QUERY_NAME_STD | MAPPED | standardised Arabic name, query only |
| 114 | ITEM | `IMPORTERS.CTRY_CD_OF_ID` | P1120_CTRY_CD_OF_ID | 1120 | – | MAPPED | Hidden (Value Protected) - input of the POST-QUERY city lookup |
| 115 | ITEM | `IMPR_SUSPN.SUSPN_STRT_DT` | IMPR_SUSPN.SUSPN_STRT_DT | 1120 | – | MAPPED | Text Field (HIJRI_DATE_FORMAT, default YYYY-MM-MI, hijri-date-default), required, default SUSPN_STRT_DT_DEFAULT |
| 116 | ITEM | `IMPR_SUSPN.SUSPN_END_DT` | IMPR_SUSPN.SUSPN_END_DT | 1120 | – | MAPPED | Text Field (HIJRI_DATE_FORMAT, default YYYY-MM-MI, hijri-date-default), required |
| 117 | ITEM | `IMPR_SUSPN.SUSPN_SEQ` | IMPR_SUSPN.SUSPN_SEQ | 1120 | – | MAPPED | Hidden, primary key (set by IMPR_SUSPN_PRE_INSERT) |
| 118 | ITEM | `IMPR_SUSPN.SUSPN_RSN_CD` | IMPR_SUSPN.SUSPN_RSN_CD | 1120 | – | MAPPED | Select List LOV_IMPR_SUSPN_RSN_CD, default SUSPN_RSN_CD_DEFAULT |
| 119 | ITEM | `IMPR_SUSPN.SUSPN_RSN_TEXT` | IMPR_SUSPN.SUSPN_RSN_TEXT | 1120 | – | MAPPED | Text Field, required, default SUSPN_RSN_TEXT_DEFAULT |
| 120 | ITEM | `IMPR_SUSPN.SUSPN_SIDE_CD` | IMPR_SUSPN.SUSPN_SIDE_CD | 1120 | – | MAPPED | Select List LOV_SUSPN_SIDE_CD, default SUSPN_SIDE_CD_DEFAULT, read only once stored |
| 121 | ITEM | `IMPR_SUSPN.SUSPN_RLSE_DT` | – | – | IMPR1120.IMPR_SUSPN_SAVE_ROW | MAPPED | not a grid column: set by IMPR_SUSPN_PRE_UPDATE / IMPR_SUSPN_ON_DELETE; region WHERE SUSPN_RLSE_DT IS NULL |
| 122 | ITEM | `IMPR_SUSPN.IMPR_NBR` | IMPR_SUSPN.IMPR_NBR | 1120 | – | MAPPED | Hidden, primary key (default = master item P1120_IMPR_NBR; save call NVL(:IMPR_NBR, :P1120_IMPR_NBR)) |
| 123 | ITEM | `IMPR_SUSPN.PORT_CD` | IMPR_SUSPN.PORT_CD | 1120 | – | MAPPED | Hidden, primary key (default = master item P1120_PORT_CD; save call NVL(:PORT_CD, :P1120_PORT_CD)) |
| 124 | TRIGGER | `FORM.KEY-EDIT` | – | – | – | DROPPED | NIB.KEY_EDIT -> page 0 toolbar / IG keyboard |
| 125 | TRIGGER | `FORM.KEY-DUPREC` | – | – | – | DROPPED | NIB.KEY_DUPREC -> page 0 toolbar / IG keyboard |
| 126 | TRIGGER | `FORM.PRE-FORM` | – | – | – | DROPPED | NIB.PRE_FORM, NLS date setting, help path -> f345 application |
| 127 | TRIGGER | `FORM.WHEN-NEW-FORM-INSTANCE` | WHEN-NEW-FORM-INSTANCE | 1120 | IMPR1120.INIT_FORM | MAPPED | site check; PORT_CD rule -> PORT_CD_IS_READ_ONLY; port value -> IMPORTERS WHEN-CREATE-RECORD; NIB / CG$ startup -> f345, LOVs |
| 128 | TRIGGER | `FORM.WHEN-WINDOW-ACTIVATED` | – | – | – | DROPPED | timers / window / frame (OLB, NIB) |
| 129 | TRIGGER | `FORM.KEY-ENTQRY` | – | – | – | DROPPED | NIB.KEY_ENTQRY -> page 0 toolbar / IG keyboard |
| 130 | TRIGGER | `FORM.ON-ERROR` | APP_ERROR_HANDLER (f345) | – | – | MAPPED | NIB.ON_ERROR |
| 131 | TRIGGER | `FORM.ON-MESSAGE` | APP_ERROR_HANDLER (f345) / page messages | – | – | MAPPED | NIB.ON_MESSAGE |
| 132 | TRIGGER | `FORM.KEY-CLRBLK` | – | – | – | DROPPED | NIB.KEY_CLRBLK -> page 0 toolbar / IG keyboard |
| 133 | TRIGGER | `FORM.KEY-DELREC` | – | – | – | DROPPED | NIB.KEY_DELREC -> page 0 toolbar / IG keyboard |
| 134 | TRIGGER | `FORM.KEY-F5` | – | – | – | DROPPED | NIB.KEY_F5 -> page 0 toolbar / IG keyboard |
| 135 | TRIGGER | `FORM.KEY-F4` | – | – | – | DROPPED | timers / window / frame (OLB, NIB) |
| 136 | TRIGGER | `FORM.KEY-NXTREC` | – | – | – | DROPPED | NIB.KEY_NXTREC -> page 0 toolbar / IG keyboard |
| 137 | TRIGGER | `FORM.KEY-PRVREC` | – | – | – | DROPPED | NIB.KEY_PRVREC -> page 0 toolbar / IG keyboard |
| 138 | TRIGGER | `FORM.KEY-DOWN` | – | – | – | DROPPED | NIB.KEY_DOWN -> page 0 toolbar / IG keyboard |
| 139 | TRIGGER | `FORM.KEY-UP` | – | – | – | DROPPED | NIB.KEY_UP -> page 0 toolbar / IG keyboard |
| 140 | TRIGGER | `FORM.KEY-SCRUP` | – | – | – | DROPPED | NIB.KEY_SCRUP -> page 0 toolbar / IG keyboard |
| 141 | TRIGGER | `FORM.KEY-SCRDOWN` | – | – | – | DROPPED | NIB.KEY_SCRDOWN -> page 0 toolbar / IG keyboard |
| 142 | TRIGGER | `FORM.KEY-PRINT` | – | – | – | DROPPED | NIB.KEY_PRINT -> page 0 toolbar / IG keyboard |
| 143 | TRIGGER | `FORM.KEY-EXIT` | – | – | – | DROPPED | NIB.KEY_EXIT -> page 0 toolbar / IG keyboard |
| 144 | TRIGGER | `FORM.WHEN-MOUSE-DOWN` | – | – | – | DROPPED | timers / window / frame (OLB, NIB) |
| 145 | TRIGGER | `FORM.KEY-EXEQRY` | – | – | – | DROPPED | NIB.KEY_EXEQRY -> page 0 toolbar / IG keyboard |
| 146 | TRIGGER | `FORM.KEY-F9` | FUNCS (page 0 toolbar) | 0 | – | MAPPED | side-menu toggle -> FUNCS |
| 147 | TRIGGER | `FORM.WHEN-TIMER-EXPIRED` | – | – | – | DROPPED | timers / window / frame (OLB, NIB) |
| 148 | TRIGGER | `FORM.KEY-HELP` | – | – | – | DROPPED | MS-Help obsolete |
| 149 | TRIGGER | `FORM.WHEN-NEW-BLOCK-INSTANCE` | – | – | – | DROPPED | Designer master-detail coordination (CGBS$) -> native Form + IG |
| 150 | TRIGGER | `FORM.ON-CLEAR-DETAILS` | – | – | – | DROPPED | Designer master-detail coordination (CGBS$) -> native Form + IG |
| 151 | TRIGGER | `FORM.ON-POPULATE-DETAILS` | – | – | – | DROPPED | Designer master-detail coordination (CGBS$) -> native Form + IG |
| 152 | TRIGGER | `FORM.KEY-CQUERY` | – | – | – | DROPPED | Designer key handler -> page 0 toolbar / IG |
| 153 | TRIGGER | `FORM.KEY-CLRREC` | – | – | – | DROPPED | Designer key handler -> page 0 toolbar / IG |
| 154 | TRIGGER | `FORM.KEY-NXTKEY` | – | – | – | DROPPED | Designer key handler -> page 0 toolbar / IG |
| 155 | TRIGGER | `FORM.KEY-MENU` | – | – | – | DROPPED | Designer key handler -> page 0 toolbar / IG |
| 156 | TRIGGER | `FORM.KEY-CLRFRM` | – | – | – | DROPPED | Designer key handler -> page 0 toolbar / IG |
| 157 | TRIGGER | `TITLE.CGSO$CHAR_ARB_ED.KEY-LISTVAL` | – | – | – | DROPPED | OLB frame (TITLE) |
| 158 | TRIGGER | `TITLE.CGSO$CHAR_ARB_DO_ENB_Y.KEY-LISTVAL` | – | – | – | DROPPED | OLB frame (TITLE) |
| 159 | TRIGGER | `TITLE.CGSO$CHAR_ARB_MLINE.KEY-LISTVAL` | – | – | – | DROPPED | OLB frame (TITLE) |
| 160 | TRIGGER | `TITLE.CGSO$CHAR_ARB.KEY-LISTVAL` | – | – | – | DROPPED | OLB frame (TITLE) |
| 161 | TRIGGER | `TITLE.CGSO$CHAR_ARB_DO.KEY-LISTVAL` | – | – | – | DROPPED | OLB frame (TITLE) |
| 162 | TRIGGER | `TITLE.SYSTEM_DATE.WHEN-VALIDATE-ITEM` | – | – | – | DROPPED | OLB frame (TITLE) |
| 163 | TRIGGER | `EDI_MSG.EDI_MSG_LOVE_BUT.WHEN-BUTTON-PRESSED` | – | – | – | DROPPED | OLB frame (EDI_MSG) |
| 164 | TRIGGER | `LSIDE.FN1.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 165 | TRIGGER | `LSIDE.FN1.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 166 | TRIGGER | `LSIDE.FN1.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 167 | TRIGGER | `LSIDE.FN50.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 168 | TRIGGER | `LSIDE.FN50.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 169 | TRIGGER | `LSIDE.FN50.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 170 | TRIGGER | `LSIDE.FN2.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 171 | TRIGGER | `LSIDE.FN2.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 172 | TRIGGER | `LSIDE.FN2.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 173 | TRIGGER | `LSIDE.FN49.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 174 | TRIGGER | `LSIDE.FN49.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 175 | TRIGGER | `LSIDE.FN49.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 176 | TRIGGER | `LSIDE.FN3.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 177 | TRIGGER | `LSIDE.FN3.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 178 | TRIGGER | `LSIDE.FN3.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 179 | TRIGGER | `LSIDE.FN48.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 180 | TRIGGER | `LSIDE.FN48.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 181 | TRIGGER | `LSIDE.FN48.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 182 | TRIGGER | `LSIDE.FN4.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 183 | TRIGGER | `LSIDE.FN4.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 184 | TRIGGER | `LSIDE.FN4.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 185 | TRIGGER | `LSIDE.FN47.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 186 | TRIGGER | `LSIDE.FN47.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 187 | TRIGGER | `LSIDE.FN47.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 188 | TRIGGER | `LSIDE.FN5.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 189 | TRIGGER | `LSIDE.FN5.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 190 | TRIGGER | `LSIDE.FN5.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 191 | TRIGGER | `LSIDE.FN46.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 192 | TRIGGER | `LSIDE.FN46.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 193 | TRIGGER | `LSIDE.FN46.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 194 | TRIGGER | `LSIDE.FN6.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 195 | TRIGGER | `LSIDE.FN6.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 196 | TRIGGER | `LSIDE.FN6.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 197 | TRIGGER | `LSIDE.FN45.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 198 | TRIGGER | `LSIDE.FN45.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 199 | TRIGGER | `LSIDE.FN45.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 200 | TRIGGER | `LSIDE.FN7.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 201 | TRIGGER | `LSIDE.FN7.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 202 | TRIGGER | `LSIDE.FN7.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 203 | TRIGGER | `LSIDE.FN44.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 204 | TRIGGER | `LSIDE.FN44.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 205 | TRIGGER | `LSIDE.FN44.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 206 | TRIGGER | `LSIDE.FN8.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 207 | TRIGGER | `LSIDE.FN8.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 208 | TRIGGER | `LSIDE.FN8.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 209 | TRIGGER | `LSIDE.FN43.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 210 | TRIGGER | `LSIDE.FN43.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 211 | TRIGGER | `LSIDE.FN43.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 212 | TRIGGER | `LSIDE.FN9.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 213 | TRIGGER | `LSIDE.FN9.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 214 | TRIGGER | `LSIDE.FN9.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 215 | TRIGGER | `LSIDE.FN42.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 216 | TRIGGER | `LSIDE.FN42.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 217 | TRIGGER | `LSIDE.FN42.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 218 | TRIGGER | `LSIDE.FN10.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 219 | TRIGGER | `LSIDE.FN10.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 220 | TRIGGER | `LSIDE.FN10.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 221 | TRIGGER | `LSIDE.FN41.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 222 | TRIGGER | `LSIDE.FN41.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 223 | TRIGGER | `LSIDE.FN41.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 224 | TRIGGER | `LSIDE.FN11.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 225 | TRIGGER | `LSIDE.FN11.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 226 | TRIGGER | `LSIDE.FN11.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 227 | TRIGGER | `LSIDE.FN40.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 228 | TRIGGER | `LSIDE.FN40.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 229 | TRIGGER | `LSIDE.FN40.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 230 | TRIGGER | `LSIDE.FN12.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 231 | TRIGGER | `LSIDE.FN12.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 232 | TRIGGER | `LSIDE.FN12.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 233 | TRIGGER | `LSIDE.FN39.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 234 | TRIGGER | `LSIDE.FN39.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 235 | TRIGGER | `LSIDE.FN39.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 236 | TRIGGER | `LSIDE.FN13.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 237 | TRIGGER | `LSIDE.FN13.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 238 | TRIGGER | `LSIDE.FN13.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 239 | TRIGGER | `LSIDE.FN38.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 240 | TRIGGER | `LSIDE.FN38.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 241 | TRIGGER | `LSIDE.FN38.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 242 | TRIGGER | `LSIDE.FN14.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 243 | TRIGGER | `LSIDE.FN14.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 244 | TRIGGER | `LSIDE.FN14.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 245 | TRIGGER | `LSIDE.FN37.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 246 | TRIGGER | `LSIDE.FN37.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 247 | TRIGGER | `LSIDE.FN37.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 248 | TRIGGER | `LSIDE.FN15.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 249 | TRIGGER | `LSIDE.FN15.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 250 | TRIGGER | `LSIDE.FN15.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 251 | TRIGGER | `LSIDE.FN36.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 252 | TRIGGER | `LSIDE.FN36.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 253 | TRIGGER | `LSIDE.FN36.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 254 | TRIGGER | `LSIDE.FN16.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 255 | TRIGGER | `LSIDE.FN16.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 256 | TRIGGER | `LSIDE.FN16.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 257 | TRIGGER | `LSIDE.FN17.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 258 | TRIGGER | `LSIDE.FN17.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 259 | TRIGGER | `LSIDE.FN17.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 260 | TRIGGER | `LSIDE.FN34.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 261 | TRIGGER | `LSIDE.FN34.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 262 | TRIGGER | `LSIDE.FN34.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 263 | TRIGGER | `LSIDE.FN35.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 264 | TRIGGER | `LSIDE.FN35.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 265 | TRIGGER | `LSIDE.FN35.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 266 | TRIGGER | `LSIDE.FN18.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 267 | TRIGGER | `LSIDE.FN18.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 268 | TRIGGER | `LSIDE.FN18.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 269 | TRIGGER | `LSIDE.FN33.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 270 | TRIGGER | `LSIDE.FN33.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 271 | TRIGGER | `LSIDE.FN33.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 272 | TRIGGER | `LSIDE.FN19.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 273 | TRIGGER | `LSIDE.FN19.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 274 | TRIGGER | `LSIDE.FN19.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 275 | TRIGGER | `LSIDE.FN32.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 276 | TRIGGER | `LSIDE.FN32.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 277 | TRIGGER | `LSIDE.FN32.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 278 | TRIGGER | `LSIDE.FN20.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 279 | TRIGGER | `LSIDE.FN20.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 280 | TRIGGER | `LSIDE.FN20.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 281 | TRIGGER | `LSIDE.FN31.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 282 | TRIGGER | `LSIDE.FN31.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 283 | TRIGGER | `LSIDE.FN31.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 284 | TRIGGER | `LSIDE.FN21.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 285 | TRIGGER | `LSIDE.FN21.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 286 | TRIGGER | `LSIDE.FN21.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 287 | TRIGGER | `LSIDE.FN30.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 288 | TRIGGER | `LSIDE.FN30.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 289 | TRIGGER | `LSIDE.FN30.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 290 | TRIGGER | `LSIDE.FN22.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 291 | TRIGGER | `LSIDE.FN22.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 292 | TRIGGER | `LSIDE.FN22.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 293 | TRIGGER | `LSIDE.FN29.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 294 | TRIGGER | `LSIDE.FN29.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 295 | TRIGGER | `LSIDE.FN29.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 296 | TRIGGER | `LSIDE.FN23.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 297 | TRIGGER | `LSIDE.FN23.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 298 | TRIGGER | `LSIDE.FN23.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 299 | TRIGGER | `LSIDE.FN28.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 300 | TRIGGER | `LSIDE.FN28.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 301 | TRIGGER | `LSIDE.FN28.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 302 | TRIGGER | `LSIDE.FN24.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 303 | TRIGGER | `LSIDE.FN24.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 304 | TRIGGER | `LSIDE.FN24.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 305 | TRIGGER | `LSIDE.FN27.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 306 | TRIGGER | `LSIDE.FN27.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 307 | TRIGGER | `LSIDE.FN27.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 308 | TRIGGER | `LSIDE.FN25.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 309 | TRIGGER | `LSIDE.FN25.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 310 | TRIGGER | `LSIDE.FN25.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 311 | TRIGGER | `LSIDE.FN26.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 312 | TRIGGER | `LSIDE.FN26.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 313 | TRIGGER | `LSIDE.FN26.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 314 | TRIGGER | `TOOLBAR.KEY-DOWN` | – | – | – | DROPPED | OLB toolbar / side-menu keyboard |
| 315 | TRIGGER | `TOOLBAR.KEY-UP` | – | – | – | DROPPED | OLB toolbar / side-menu keyboard |
| 316 | TRIGGER | `TOOLBAR.KEY-NEXT-ITEM` | – | – | – | DROPPED | OLB toolbar / side-menu keyboard |
| 317 | TRIGGER | `TOOLBAR.SAVE.WHEN-BUTTON-PRESSED` | SAVE (page 0 toolbar) | 0 | – | MAPPED | toolbar button |
| 318 | TRIGGER | `TOOLBAR.CLEAR_ALL.WHEN-BUTTON-PRESSED` | CLEAR (page 0 toolbar) | 0 | – | MAPPED | toolbar button |
| 319 | TRIGGER | `TOOLBAR.EXIT.WHEN-BUTTON-PRESSED` | BACK (page 0 toolbar) | 0 | – | MAPPED | toolbar button |
| 320 | TRIGGER | `TOOLBAR.EXIT1.WHEN-BUTTON-PRESSED` | BACK (page 0 toolbar) | 0 | – | MAPPED | toolbar button |
| 321 | TRIGGER | `TOOLBAR.ENTER.WHEN-BUTTON-PRESSED` | SEARCH (page 0 toolbar) | 0 | – | MAPPED | toolbar button |
| 322 | TRIGGER | `TOOLBAR.EXECUTE.WHEN-BUTTON-PRESSED` | SEARCH (page 0 toolbar) | 0 | – | MAPPED | toolbar button |
| 323 | TRIGGER | `TOOLBAR.REMOVE.WHEN-BUTTON-PRESSED` | DELETE (page 0 toolbar) / IG row delete | 0 | – | MAPPED | toolbar button |
| 324 | TRIGGER | `TOOLBAR.LIST_VALUE.WHEN-BUTTON-PRESSED` | – | – | – | DROPPED | OLB toolbar / side-menu keyboard |
| 325 | TRIGGER | `TOOLBAR.HELP.WHEN-BUTTON-PRESSED` | – | – | – | DROPPED | OLB toolbar / side-menu keyboard |
| 326 | TRIGGER | `TOOLBAR.LAST_REC.WHEN-BUTTON-PRESSED` | – | – | – | DROPPED | OLB toolbar / side-menu keyboard |
| 327 | TRIGGER | `TOOLBAR.RE_ENTER_QUERY.WHEN-BUTTON-PRESSED` | SEARCH (page 0 toolbar) | 0 | – | MAPPED | toolbar button |
| 328 | TRIGGER | `TOOLBAR.FIRST_REC.WHEN-BUTTON-PRESSED` | – | – | – | DROPPED | OLB toolbar / side-menu keyboard |
| 329 | TRIGGER | `TOOLBAR.PAGE_UP.WHEN-BUTTON-PRESSED` | – | – | – | DROPPED | OLB toolbar / side-menu keyboard |
| 330 | TRIGGER | `TOOLBAR.PAGE_DOWN.WHEN-BUTTON-PRESSED` | – | – | – | DROPPED | OLB toolbar / side-menu keyboard |
| 331 | TRIGGER | `TOOLBAR.FUN_BUT.WHEN-MOUSE-UP` | FUNCS (page 0 toolbar) | 0 | – | MAPPED | toolbar button |
| 332 | TRIGGER | `TOOLBAR.FUN_BUT.WHEN-MOUSE-DOWN` | FUNCS (page 0 toolbar) | 0 | – | MAPPED | toolbar button |
| 333 | TRIGGER | `IMPORTERS.ON-ERROR` | APP_ERROR_HANDLER (f345) | – | – | MAPPED | Designer constraint messages |
| 334 | TRIGGER | `IMPORTERS.POST-QUERY` | POST-QUERY | 1120 | IMPR1120.IMPORTERS_POST_QUERY | MAPPED | Before Header after Initialize form |
| 335 | TRIGGER | `IMPORTERS.PRE-QUERY` | IMPORTERS_SEARCH region SQL (page 112001) | 112001 | IMPR1120.IMPORTERS_PRE_QUERY_PORT_CD | MAPPED | port rule + one search text P112001_SEARCH over all columns (+ IMPORTERS_PRE_QUERY_NAME_STD); Exec_Query_Now -> P0_PAGE_PK |
| 336 | TRIGGER | `IMPORTERS.KEY-HELP` | – | – | – | DROPPED | MS-Help obsolete |
| 337 | TRIGGER | `IMPORTERS.WHEN-CREATE-RECORD` | IMPORTERS WHEN-CREATE-RECORD | 1120 | IMPR1120.IMPORTERS_WHEN_CREATE_RECORD | MAPPED | Before Header when P0_PAGE_PK is null |
| 338 | TRIGGER | `IMPORTERS.PORT_CD.KEY-LISTVAL` | LOV_SD_PORTS (Popup LOV of P1120_PORT_CD; on 112001 the port is part of the search text) | 1120 | – | MAPPED | CALL_FORM LOV_SD_PORTS |
| 339 | TRIGGER | `IMPORTERS.PORT_CD2.WHEN-BUTTON-PRESSED` | – | – | – | DROPPED | LOV button -> popup LOV icon / item display only |
| 340 | TRIGGER | `IMPORTERS.PORT_NAME.KEY-LISTVAL` | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 341 | TRIGGER | `IMPORTERS.HQ_IMPR_NBR.KEY-LISTVAL` | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 342 | TRIGGER | `IMPORTERS.IMPR_NBR.KEY-LISTVAL` | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 343 | TRIGGER | `IMPORTERS.IMPR_NBR.WHEN-VALIDATE-ITEM` | IMPR_NBR VALIDATION + DA IMPR_NBR WHEN-VALIDATE-ITEM + process EXECUTE-QUERY | 1120 | IMPR1120.IMPR_NBR_VALIDATION | MAPPED | also IMPR1120.IMPR_NBR_WHEN_VALIDATE_ITEM (process EXECUTE-QUERY) |
| 344 | TRIGGER | `IMPORTERS.SDP_PORT_STATUS.KEY-LISTVAL` | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 345 | TRIGGER | `IMPORTERS.IMPR_TYPE_CD.KEY-LISTVAL` | IMPORTERS_SEARCH column filter (page 112001) | 112001 | – | MAPPED | CALL_FORM LOV_Impr_Type used as query criterion -> IG column filter |
| 346 | TRIGGER | `IMPORTERS.IMPR_TYPE_CD.WHEN-VALIDATE-ITEM` | – | – | – | DROPPED | item display only; names come from IMPORTERS_POST_QUERY |
| 347 | TRIGGER | `IMPORTERS.IMPR_TYPE_CD.WHEN-NEW-ITEM-INSTANCE` | IMPR_NBR WHEN-VALIDATE-ITEM (Submit EXECUTE_QUERY) | 1120 | – | MAPPED | CLEAR_BLOCK + EXECUTE_QUERY -> page submit |
| 348 | TRIGGER | `IMPORTERS.IMPR_TYPE_CD2.WHEN-BUTTON-PRESSED` | – | – | – | DROPPED | LOV button -> popup LOV icon / item display only |
| 349 | TRIGGER | `IMPORTERS.IMPR_TYPE_NAME.KEY-LISTVAL` | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 350 | TRIGGER | `IMPORTERS.CTRY_CD.KEY-LISTVAL` | IMPORTERS_SEARCH column filter (page 112001) | 112001 | – | MAPPED | CALL_FORM LOV_COUNTRIES used as query criterion -> IG column filter |
| 351 | TRIGGER | `IMPORTERS.CTRY_CD2.WHEN-BUTTON-PRESSED` | – | – | – | DROPPED | LOV button -> popup LOV icon / item display only |
| 352 | TRIGGER | `IMPORTERS.CRTY_ARBC_NAME.KEY-LISTVAL` | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 353 | TRIGGER | `IMPORTERS.CITY_CODE_OF_ID.KEY-LISTVAL` | IMPORTERS_SEARCH column filter (page 112001) | 112001 | – | MAPPED | CALL_FORM LOV_CITIES used as query criterion -> IG column filter |
| 354 | TRIGGER | `IMPORTERS.CITY_CODE_OF_ID2.WHEN-BUTTON-PRESSED` | – | – | – | DROPPED | LOV button -> popup LOV icon / item display only |
| 355 | TRIGGER | `IMPORTERS.ID_CITY_NAME.KEY-LISTVAL` | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 356 | TRIGGER | `IMPORTERS.BUS_ID.KEY-LISTVAL` | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 357 | TRIGGER | `IMPORTERS.BUS_ID_TYPE_CD.KEY-LISTVAL` | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 358 | TRIGGER | `IMPORTERS.BUTT.WHEN-BUTTON-PRESSED` | – | – | – | DROPPED | LOV button -> popup LOV icon / item display only |
| 359 | TRIGGER | `IMPORTERS.BUS_ID_TYPE_NAME.KEY-LISTVAL` | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 360 | TRIGGER | `IMPORTERS.BUS_ID_BRNCH.KEY-LISTVAL` | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 361 | TRIGGER | `IMPORTERS.CTRY_CTRY_STATUS.KEY-LISTVAL` | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 362 | TRIGGER | `IMPORTERS.ARBC_IMPR_NAME.KEY-LISTVAL` | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 363 | TRIGGER | `IMPORTERS.ENG_IMPR_NAME.KEY-LISTVAL` | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 364 | TRIGGER | `IMPORTERS.IMPR_CNTCT_NAME.KEY-LISTVAL` | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 365 | TRIGGER | `IMPORTERS.CTRY_CD_OF_ID.KEY-LISTVAL` | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 366 | TRIGGER | `IMPR_SUSPN.ON-ERROR` | IS_1_IMP_FK (Text Message) + APP_ERROR_HANDLER | – | – | MAPPED | – |
| 367 | TRIGGER | `IMPR_SUSPN.KEY-HELP` | – | – | – | DROPPED | MS-Help obsolete |
| 368 | TRIGGER | `IMPR_SUSPN.KEY-DELREC` | IMPR_SUSPN row delete (native confirm) | 1120 | – | MAPPED | TMPLT.KEY_DELETE_RECORD: confirm + delete + COMMIT -> IG delete, APEX commit |
| 369 | TRIGGER | `IMPR_SUSPN.ON-DELETE` | IMPR_SUSPN - Save Interactive Grid Data | 1120 | IMPR1120.IMPR_SUSPN_ON_DELETE | MAPPED | soft delete, called by IMPR_SUSPN_SAVE_ROW (row status D) |
| 370 | TRIGGER | `IMPR_SUSPN.POST-INSERT` | IMPR_SUSPN - Save Interactive Grid Data | 1120 | IMPR1120.IMPR_SUSPN_POST_INSERT | MAPPED | called by IMPR_SUSPN_SAVE_ROW; COMMIT removed (HIGH); enabling part -> SUSPN_SIDE_CD_IS_READ_ONLY |
| 371 | TRIGGER | `IMPR_SUSPN.POST-QUERY` | IMPR_SUSPN.SUSPN_SIDE_CD Read Only | 1120 | IMPR1120.SUSPN_SIDE_CD_IS_READ_ONLY | MAPPED | – |
| 372 | TRIGGER | `IMPR_SUSPN.PRE-INSERT` | IMPR_SUSPN - Save Interactive Grid Data | 1120 | IMPR1120.IMPR_SUSPN_PRE_INSERT | MAPPED | called by IMPR_SUSPN_SAVE_ROW (row status C) |
| 373 | TRIGGER | `IMPR_SUSPN.PRE-UPDATE` | IMPR_SUSPN - Save Interactive Grid Data | 1120 | IMPR1120.IMPR_SUSPN_PRE_UPDATE | MAPPED | called by IMPR_SUSPN_SAVE_ROW (row status U) |
| 374 | TRIGGER | `IMPR_SUSPN.WHEN-NEW-RECORD-INSTANCE` | Read Only of every IMPR_SUSPN column (For Each Row) | 1120 | IMPR1120.IMPR_SUSPN_IS_READ_ONLY | MAPPED | NEXT_RECORD -> row read only + server check; stored side -> SUSPN_SIDE_CD_IS_READ_ONLY; GO_ITEM dropped |
| 375 | TRIGGER | `IMPR_SUSPN.SUSPN_STRT_DT.KEY-LISTVAL` | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 376 | TRIGGER | `IMPR_SUSPN.SUSPN_STRT_DT.KEY-F4` | – | – | – | DROPPED | INTRFACE.DISP_DATE_CON -> date column (Hijri picker) |
| 377 | TRIGGER | `IMPR_SUSPN.SUSPN_STRT_DT.WHEN-VALIDATE-ITEM` | IMPR_SUSPN SUSPN_STRT_DT VALIDATION + DA IMPR_SUSPN SUSPN_STRT_DT WHEN-VALIDATE-ITEM | 1120 | IMPR1120.SUSPN_STRT_DT_VALIDATION | MAPPED | – |
| 378 | TRIGGER | `IMPR_SUSPN.SUSPN_STRT_DT.WHEN-NEW-ITEM-INSTANCE` | IMPR_SUSPN.SUSPN_STRT_DT default | 1120 | IMPR1120.SUSPN_STRT_DT_DEFAULT | MAPPED | – |
| 379 | TRIGGER | `IMPR_SUSPN.SUSPN_END_DT.KEY-LISTVAL` | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 380 | TRIGGER | `IMPR_SUSPN.SUSPN_END_DT.KEY-F4` | – | – | – | DROPPED | INTRFACE.DISP_DATE_CON -> date column (Hijri picker) |
| 381 | TRIGGER | `IMPR_SUSPN.SUSPN_END_DT.WHEN-VALIDATE-ITEM` | IMPR_SUSPN SUSPN_END_DT VALIDATION + DA IMPR_SUSPN SUSPN_END_DT WHEN-VALIDATE-ITEM | 1120 | IMPR1120.SUSPN_END_DT_VALIDATION | MAPPED | – |
| 382 | TRIGGER | `IMPR_SUSPN.SUSPN_RSN_CD.KEY-LISTVAL` | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 383 | TRIGGER | `IMPR_SUSPN.SUSPN_RSN_CD.WHEN-NEW-ITEM-INSTANCE` | IMPR_SUSPN.SUSPN_RSN_CD / SUSPN_RSN_TEXT defaults | 1120 | IMPR1120.SUSPN_RSN_CD_DEFAULT | MAPPED | with SUSPN_RSN_TEXT_DEFAULT |
| 384 | TRIGGER | `IMPR_SUSPN.SUSPN_RSN_CD.WHEN-VALIDATE-ITEM` | IMPR_SUSPN SUSPN_RSN_CD VALIDATION + DA IMPR_SUSPN SUSPN_RSN_CD WHEN-VALIDATE-ITEM | 1120 | IMPR1120.SUSPN_RSN_CD_VALIDATION | MAPPED | derived SUSPN_RSN_TEXT -> SUSPN_RSN_CD_VALIDATE_ITEM |
| 385 | TRIGGER | `IMPR_SUSPN.SUSPN_RSN_TEXT.KEY-LISTVAL` | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 386 | TRIGGER | `IMPR_SUSPN.SUSPN_RSN_TEXT.WHEN-NEW-ITEM-INSTANCE` | – | – | – | DROPPED | body is NULL |
| 387 | TRIGGER | `IMPR_SUSPN.SUSPN_SIDE_CD.WHEN-LIST-CHANGED` | IMPR_SUSPN SUSPN_SIDE_CD WHEN-LIST-CHANGED | 1120 | IMPR1120.SUSPN_SIDE_CD_VALIDATION | MAPPED | – |
| 388 | TRIGGER | `IMPR_SUSPN.SUSPN_SIDE_CD.WHEN-NEW-ITEM-INSTANCE` | IMPR_SUSPN.SUSPN_SIDE_CD default | 1120 | IMPR1120.SUSPN_SIDE_CD_DEFAULT | MAPPED | – |
| 389 | TRIGGER | `IMPR_SUSPN.SUSPN_SIDE_CD.WHEN-VALIDATE-ITEM` | IMPR_SUSPN SUSPN_SIDE_CD VALIDATION | 1120 | IMPR1120.SUSPN_SIDE_CD_VALIDATION | MAPPED | – |
| 390 | TRIGGER | `IMPR_SUSPN.SUSPN_RLSE_DT.KEY-LISTVAL` | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 391 | TRIGGER | `IMPR_SUSPN.SUSPN_RLSE_DT.KEY-F4` | – | – | – | DROPPED | INTRFACE.DISP_DATE_CON -> date column (Hijri picker) |
| 392 | TRIGGER | `IMPR_SUSPN.SUSPN_RLSE_DT.WHEN-VALIDATE-ITEM` | – | – | – | DROPPED | hidden, non-navigable item: never fires |
| 393 | RELATION | `CGFK$IS_1_IMP_FK` | IMPR_SUSPN (IG WHERE port_cd = :P1120_PORT_CD AND impr_nbr = :P1120_IMPR_NBR) | 1120 | – | MAPPED | IMPORTERS -> IMPR_SUSPN; master keys from the master form (column default + NVL in the save call) |
| 394 | LOV | `CGFK$IMPORTERS_PORT_CD` | LOV_SD_PORTS (from IMPR1110) | 1120 | – | MAPPED | P1120_PORT_CD (port 99 only) |
| 395 | LOV | `CGFK$IMPORTERS_CITY_CODE_OF_ID` | – | – | – | DROPPED | item display only; search by IG column filter |
| 396 | LOV | `CGFK$IMPORTERS_CTRY_CD` | – | – | – | DROPPED | item display only; search by IG column filter |
| 397 | LOV | `CGFK$IMPORTERS_HQ_IMPR_NBR` | – | – | – | DROPPED | item display only |
| 398 | LOV | `CGFK$IMPORTERS_IMPR_TYPE_CD` | – | – | – | DROPPED | item display only; search by IG column filter |
| 399 | RECORD_GROUP | `CGFK$IMPORTERS_PORT_CD` | LOV_SD_PORTS (from IMPR1110) | 1120 | – | MAPPED | query of LOV CGFK$IMPORTERS_PORT_CD |
| 400 | RECORD_GROUP | `CGFK$IMPORTERS_CITY_CODE_OF_ID` | – | – | – | DROPPED | query of LOV CGFK$IMPORTERS_CITY_CODE_OF_ID |
| 401 | RECORD_GROUP | `CGFK$IMPORTERS_CTRY_CD` | – | – | – | DROPPED | query of LOV CGFK$IMPORTERS_CTRY_CD |
| 402 | RECORD_GROUP | `CGFK$IMPORTERS_HQ_IMPR_NBR` | – | – | – | DROPPED | query of LOV CGFK$IMPORTERS_HQ_IMPR_NBR |
| 403 | RECORD_GROUP | `CGFK$IMPORTERS_IMPR_TYPE_CD` | – | – | – | DROPPED | query of LOV CGFK$IMPORTERS_IMPR_TYPE_CD |
| 404 | RECORD_GROUP | `CGDV$DLRG (runtime)` | LOV_ALLOWED_EXPORT, LOV_IMPR_SUSPN_RSN_CD, LOV_SUSPN_SIDE_CD | 1120 | – | MAPPED | CREATE_GROUP_FROM_QUERY on CG_REF_CODES in CGDV$POPULATE_DYNAMIC_LISTS |
| 405 | CANVAS | `LSIDE` | – | – | – | DROPPED | OLB canvas LSIDE |
| 406 | CANVAS | `EDI_MSG` | – | – | – | DROPPED | OLB canvas EDI_MSG |
| 407 | CANVAS | `TITLE` | – | – | – | DROPPED | OLB canvas TITLE |
| 408 | CANVAS | `TOOLBAR` | – | – | – | DROPPED | OLB canvas TOOLBAR |
| 409 | CANVAS | `CG$PAGE_1` | 1120 IMPR1120 | 1120 | – | MAPPED | main content canvas |
| 410 | WINDOW | `CGSO$WINDOW_1` | 1120 IMPR1120 | 1120 | – | MAPPED | console window |
| 411 | ALERT | `CG$ASK_COMMIT` | – | – | – | DROPPED | not used by IMPR1120 code |
| 412 | ALERT | `USR_CONFIRM_B` | – | – | – | DROPPED | not used by IMPR1120 code |
| 413 | ALERT | `USR_CONFIRM` | – | – | – | DROPPED | not used by IMPR1120 code |
| 414 | ALERT | `USR_WARNING_C` | – | – | – | DROPPED | not used by IMPR1120 code |
| 415 | ALERT | `USR_WARNING_B` | IG row delete confirm "هل أنت متأكد من عملية الحذف" | 1120 | – | MAPPED | TMPLT.KEY_DELETE_RECORD |
| 416 | ALERT | `CFG_WARNING_A` | – | – | – | DROPPED | not used by IMPR1120 code |
| 417 | ALERT | `CFG_INFORMATION` | validation error text (message 9-150 stops the query in Forms too) | 1120 | – | MAPPED | – |
| 418 | ALERT | `CFG_ERROR` | CHECK_ERROR / FORMS_APX.FORM_TRIGGER_FAILURE (inline error) | 1120 | – | MAPPED | STR.DispArbMsg ERROR 9-100, 9-110; DispAlert SYSTEM_ERROR |
| 419 | ALERT | `CFG_SYSTEM_ERROR` | FORMS_APX.FORM_TRIGGER_FAILURE (activity log / Hijri date errors) | 1120 | – | MAPPED | – |
| 420 | ALERT | `CFG_ASK_COMMIT` | – | – | – | DROPPED | not used by IMPR1120 code |
| 421 | PARAMETER | `P_SHPG_AGNT_NBR` | – | – | – | DROPPED | not used by the business code (function menu / reports / frame) |
| 422 | PARAMETER | `P_CTRL_LAST_EXEC_CD` | – | – | – | DROPPED | not used by the business code (function menu / reports / frame) |
| 423 | PARAMETER | `P_BANK_CD` | – | – | – | DROPPED | not used by the business code (function menu / reports / frame) |
| 424 | PARAMETER | `P_BANK_BRNCH_CD` | – | – | – | DROPPED | not used by the business code (function menu / reports / frame) |
| 425 | PARAMETER | `P_BRKR_PORT_CD` | – | – | – | DROPPED | not used by the business code (function menu / reports / frame) |
| 426 | PARAMETER | `P_LIC_TYPE` | – | – | – | DROPPED | not used by the business code (function menu / reports / frame) |
| 427 | PARAMETER | `P_BRKR_NBR` | – | – | – | DROPPED | not used by the business code (function menu / reports / frame) |
| 428 | PARAMETER | `P_CLASS_CD` | – | – | – | DROPPED | not used by the business code (function menu / reports / frame) |
| 429 | PARAMETER | `P_JOB_ID` | – | – | – | DROPPED | not used by the business code (function menu / reports / frame) |
| 430 | PARAMETER | `P_CURRENT_ITEM` | – | – | – | DROPPED | not used by the business code (function menu / reports / frame) |
| 431 | PARAMETER | `P_GROUP_CD` | – | – | – | DROPPED | not used by the business code (function menu / reports / frame) |
| 432 | PARAMETER | `P_USER_TYPE` | – | – | – | DROPPED | not used by the business code (function menu / reports / frame) |
| 433 | PARAMETER | `P_PORT_TYPE` | P_PORT_TYPE (f345) | – | – | MAPPED | bind of LOV_SD_PORTS |
| 434 | PARAMETER | `P_CURR_PORT_CD` | P_CURR_PORT_CD (f345) | – | – | MAPPED | – |
| 435 | PARAMETER | `P_MODULE_ID` | P1120_MODULE_ID | 1120 | IMPR1120.GET_MODULE_ID | MAPPED | – |
| 436 | PARAMETER | `P_MODULE_NAME` | SYS_ANAME (f345 page title) | – | – | MAPPED | title bar only |
| 437 | PARAMETER | `P_APPLICATION_NAME` | – | – | – | DROPPED | not used by the business code (function menu / reports / frame) |
| 438 | PARAMETER | `P_USER_ID` | SSO_APP_USER (f345) | – | – | MAPPED | ACTIVITY_DB user |
| 439 | PARAMETER | `P_WS_ID` | P_GLOBAL_V_WS_ID (f345) | – | – | MAPPED | ACTIVITY_DB workstation |
| 440 | PARAMETER | `P_USER_NAME` | V_USR_NAME (f345 header) | – | – | MAPPED | title bar only |
| 441 | PARAMETER | `CG$STARTUP_MODE` | – | – | – | DROPPED | not used by the business code (function menu / reports / frame) |
| 442 | PARAMETER | `CURRENT_SIDE` | P1120_P_CURRENT_SIDE | 1120 | IMPR1120.GET_CURRENT_SIDE | MAPPED | source to confirm (inventory §15 #1) |
| 443 | LIBRARY | `OFGTEL` | – | – | – | TODO | MISSING SOURCE - constraint messages (CGTE$); block texts known, Text Messages per constraint |
| 444 | LIBRARY | `OFGMES` | – | – | – | DROPPED | not needed in the browser (help, DLL, window, tab, pick list) |
| 445 | LIBRARY | `OFGHPL` | – | – | – | DROPPED | not needed in the browser (help, DLL, window, tab, pick list) |
| 446 | LIBRARY | `CIC_AMSG` | – | – | – | MAPPED | Des$Form_errors messages -> FORMS_APX / APP_ERROR_HANDLER |
| 447 | LIBRARY | `SEC_LIB` | – | – | – | DROPPED | not needed in the browser (help, DLL, window, tab, pick list) |
| 448 | LIBRARY | `CAPTION` | – | – | – | DROPPED | not needed in the browser (help, DLL, window, tab, pick list) |
| 449 | LIBRARY | `OFGBSL` | – | – | – | MAPPED | CGBS$ master-detail -> native Form + IG |
| 450 | LIBRARY | `D2KWUTIL` | – | – | – | DROPPED | not needed in the browser (help, DLL, window, tab, pick list) |
| 451 | LIBRARY | `CUSTOMDLL` | – | – | – | DROPPED | not needed in the browser (help, DLL, window, tab, pick list) |
| 452 | LIBRARY | `D2KWUTIL_PDF` | – | – | – | DROPPED | not needed in the browser (help, DLL, window, tab, pick list) |
| 453 | LIBRARY | `GETCOMP` | – | – | – | DROPPED | not needed in the browser (help, DLL, window, tab, pick list) |
| 454 | LIBRARY | `OFGTAB` | – | – | – | DROPPED | not needed in the browser (help, DLL, window, tab, pick list) |
| 455 | LIBRARY | `PICKLIST` | – | – | – | DROPPED | not needed in the browser (help, DLL, window, tab, pick list) |
| 456 | LIBRARY | `POS` | – | – | – | DROPPED | not needed in the browser (help, DLL, window, tab, pick list) |
| 457 | LIBRARY | `SCDLL` | – | – | – | DROPPED | not needed in the browser (help, DLL, window, tab, pick list) |
| 458 | LIBRARY | `VCDLL` | – | – | – | DROPPED | not needed in the browser (help, DLL, window, tab, pick list) |
| 459 | LIBRARY | `CIC_LIB` | – | – | – | MAPPED | NIB / TMPLT -> f345; STR -> STR_DB; HIJDATE -> HIJDATE_DB; ACTIVITY -> ACTIVITY_DB; INTRFACE -> date column |
| 460 | GLOBAL | `CG$HP_HFILE` | – | – | – | DROPPED | LOV-form return value / Designer internal / version stamp / function menu - not needed |
| 461 | GLOBAL | `CG$HP_HPATH` | – | – | – | DROPPED | LOV-form return value / Designer internal / version stamp / function menu - not needed |
| 462 | GLOBAL | `CG$QUERY_MODE` | – | – | – | DROPPED | LOV-form return value / Designer internal / version stamp / function menu - not needed |
| 463 | GLOBAL | `CITY_ARB_NAME` | – | – | – | DROPPED | LOV-form return value / Designer internal / version stamp / function menu - not needed |
| 464 | GLOBAL | `CITY_CD` | – | – | – | DROPPED | LOV-form return value / Designer internal / version stamp / function menu - not needed |
| 465 | GLOBAL | `CRTY_ARBC_NAME` | – | – | – | DROPPED | LOV-form return value / Designer internal / version stamp / function menu - not needed |
| 466 | GLOBAL | `CTRY_CD` | – | – | – | DROPPED | LOV-form return value / Designer internal / version stamp / function menu - not needed |
| 467 | GLOBAL | `CURRENT_DT` | – | – | – | DROPPED | LOV-form return value / Designer internal / version stamp / function menu - not needed |
| 468 | GLOBAL | `CURRENT_VER` | – | – | – | DROPPED | LOV-form return value / Designer internal / version stamp / function menu - not needed |
| 469 | GLOBAL | `EXEC_QUERY_NOW` | P0_PAGE_PK (process EXECUTE-QUERY) | 1120 | – | MAPPED | no G_ application item needed |
| 470 | GLOBAL | `EXIT` | – | – | – | DROPPED | LOV-form return value / Designer internal / version stamp / function menu - not needed |
| 471 | GLOBAL | `IMPR_NBR` | P0_PAGE_PK | 1120 | – | MAPPED | no G_ application item needed |
| 472 | GLOBAL | `IMPR_TYPE_CD` | – | – | – | DROPPED | LOV-form return value / Designer internal / version stamp / function menu - not needed |
| 473 | GLOBAL | `IMPR_TYPE_NAME` | – | – | – | DROPPED | LOV-form return value / Designer internal / version stamp / function menu - not needed |
| 474 | GLOBAL | `PORT_CD` | P0_PAGE_PK / LOV return | 1120 | – | MAPPED | no G_ application item needed |
| 475 | GLOBAL | `PORT_NAME` | LOV additional output of P1120_PORT_CD | 1120 | – | MAPPED | no G_ application item needed |
| 476 | GLOBAL | `SYSTEM_OBJ` | – | – | – | DROPPED | LOV-form return value / Designer internal / version stamp / function menu - not needed |
| 477 | CALLED_FORM | `LOV_SD_PORTS` | LOV_SD_PORTS | 1120 | – | MAPPED | PORT_CD KEY-LISTVAL |
| 478 | CALLED_FORM | `LOV_IMPR_TYPE` | IMPORTERS_SEARCH column filter IMPR_TYPE_CD | 112001 | – | MAPPED | IMPR_TYPE_CD KEY-LISTVAL |
| 479 | CALLED_FORM | `LOV_COUNTRIES` | IMPORTERS_SEARCH column filter CTRY_CD | 112001 | – | MAPPED | CTRY_CD KEY-LISTVAL |
| 480 | CALLED_FORM | `LOV_CITIES` | IMPORTERS_SEARCH column filter CITY_CODE_OF_ID | 112001 | – | MAPPED | CITY_CODE_OF_ID KEY-LISTVAL |
| 481 | CALLED_FORM | `V_CALLED_FORM (dynamic, PU EXECUTE_FUNCTION)` | FUNCS (Page Functions list) | 1120 | – | TODO | functions of the module in SC_SYSTEM_OBJECTS unknown (inventory §15 #9) |
| 482 | CALLED_FORM | `calendar forms (INTRFACE.DISP_CALENDAR / DISP_DATE_CON)` | hijri-date-default date columns | 1120 | – | MAPPED | date KEY-LISTVAL / KEY-F4 |
| 483 | PROGRAM_UNIT | `CHECK_TIMEOUT` | – | – | – | DROPPED | not called by active code (NIB wrapper / Designer check / query-mode toggle) |
| 484 | PROGRAM_UNIT | `MOUSE_CLICK` | – | – | – | DROPPED | f345 Page Functions (FUNCS) |
| 485 | PROGRAM_UNIT | `TOGGEL_WND` | – | – | – | DROPPED | not called by active code (NIB wrapper / Designer check / query-mode toggle) |
| 486 | PROGRAM_UNIT | `PRINT_REPORT` | – | – | – | DROPPED | not called by active code (NIB wrapper / Designer check / query-mode toggle) |
| 487 | PROGRAM_UNIT | `EXECUTE_FUNCTION` | – | – | – | DROPPED | f345 Page Functions (FUNCS) |
| 488 | PROGRAM_UNIT | `TERMINATE_FUN` | – | – | – | DROPPED | not called by active code (NIB wrapper / Designer check / query-mode toggle) |
| 489 | PROGRAM_UNIT | `CHECK_EDI_MSG_LOV` | – | – | – | DROPPED | not called by active code (NIB wrapper / Designer check / query-mode toggle) |
| 490 | PROGRAM_UNIT | `CHECK_EDI_MSG_TIMER` | – | – | – | DROPPED | not called by active code (NIB wrapper / Designer check / query-mode toggle) |
| 491 | PROGRAM_UNIT | `CHECK_EDI_ROLE_ID` | – | – | – | DROPPED | not called by active code (NIB wrapper / Designer check / query-mode toggle) |
| 492 | PROGRAM_UNIT | `EDI_MSG_LOV` | – | – | – | DROPPED | not called by active code (NIB wrapper / Designer check / query-mode toggle) |
| 493 | PROGRAM_UNIT | `FOR_EDI_MSG` | – | – | – | DROPPED | not called by active code (NIB wrapper / Designer check / query-mode toggle) |
| 494 | PROGRAM_UNIT | `RETURN_MSG` | – | – | – | DROPPED | not called by active code (NIB wrapper / Designer check / query-mode toggle) |
| 495 | PROGRAM_UNIT | `TURN_MSG` | – | – | – | DROPPED | not called by active code (NIB wrapper / Designer check / query-mode toggle) |
| 496 | PROGRAM_UNIT | `WHEN_TIMER_EXPIRED_MSG` | – | – | – | DROPPED | not called by active code (NIB wrapper / Designer check / query-mode toggle) |
| 497 | PROGRAM_UNIT | `CG$WHEN_NEW_FORM_INSTANCE` | – | – | – | DROPPED | lists + block-sync startup -> shared LOVs / native master-detail |
| 498 | PROGRAM_UNIT | `CGDV$POPULATE_DYNAMIC_LISTS` | – | – | – | DROPPED | shared LOVs on CG_REF_CODES |
| 499 | PROGRAM_UNIT | `CGFK$QRY_IMPORTERS_IMP_SDP_FK` | – | 1120 | IMPR1120.CGFK$QRY_IMPORTERS_IMP_SDP_FK | MAPPED | same name; called by IMPORTERS_POST_QUERY |
| 500 | PROGRAM_UNIT | `CGFK$CHK_IMPORTERS_IMP_SDP_FK` | – | – | – | DROPPED | not called by active code (NIB wrapper / Designer check / query-mode toggle) |
| 501 | PROGRAM_UNIT | `CG$IMPR1120_GLOBALS` | – | – | – | DROPPED | Designer dynamic WHERE holder |
| 502 | PROGRAM_UNIT | `CGFK$QRY_IMPORTERS_IMP_ITIDT_F` | – | 1120 | IMPR1120.CGFK$QRY_IMPORTERS_IMP_ITIDT_F | MAPPED | same name; called by IMPORTERS_POST_QUERY |
| 503 | PROGRAM_UNIT | `CGFK$CHK_IMPORTERS_IMP_ITIDT_F` | – | – | – | DROPPED | with IMPR_TYPE_CD WHEN-VALIDATE-ITEM (item display only) |
| 504 | PROGRAM_UNIT | `CGFK$QRY_IMPORTERS_IMP_CTRY_FK` | – | 1120 | IMPR1120.CGFK$QRY_IMPORTERS_IMP_CTRY_FK | MAPPED | same name; called by IMPORTERS_POST_QUERY |
| 505 | PROGRAM_UNIT | `CGFK$CHK_IMPORTERS_IMP_CTRY_FK` | – | – | – | DROPPED | not called by active code (NIB wrapper / Designer check / query-mode toggle) |
| 506 | PROGRAM_UNIT | `CGFK$QRY_IMPORTERS_IMP_BUS_ID_` | – | 1120 | IMPR1120.CGFK$QRY_IMPORTERS_IMP_BUS_ID_ | MAPPED | same name; called by IMPORTERS_POST_QUERY |
| 507 | PROGRAM_UNIT | `CGFK$CHK_IMPORTERS_IMP_BUS_ID_` | – | – | – | DROPPED | not called by active code (NIB wrapper / Designer check / query-mode toggle) |
| 508 | PROGRAM_UNIT | `CGFK$CHK_IMPR_SUSPN_IS_1_IMP_F` | – | – | – | DROPPED | not called by active code (NIB wrapper / Designer check / query-mode toggle) |
| 509 | PROGRAM_UNIT | `CGUV$CHK_IS_1_PK` | – | – | – | DROPPED | not called by active code (NIB wrapper / Designer check / query-mode toggle) |
| 510 | PROGRAM_UNIT | `CGTE$CHECK_CONSTRAINT_VIO` | – | – | – | DROPPED | APP_ERROR_HANDLER |
| 511 | PROGRAM_UNIT | `CGBS$TOGGLE` | – | – | – | DROPPED | not called by active code (NIB wrapper / Designer check / query-mode toggle) |
| 512 | PROGRAM_UNIT | `CGBS$SET_QUERY_MODE` | – | – | – | DROPPED | not called by active code (NIB wrapper / Designer check / query-mode toggle) |
| 513 | PROGRAM_UNIT | `CGBS$MESSAGE_QUERY_MODE` | – | – | – | DROPPED | not called by active code (NIB wrapper / Designer check / query-mode toggle) |
| 514 | PROGRAM_UNIT | `EXEC_FUNS` | – | – | – | DROPPED | empty in Forms |
| 515 | PROGRAM_UNIT | `ADJ_FUNS` | – | – | – | DROPPED | empty in Forms |
