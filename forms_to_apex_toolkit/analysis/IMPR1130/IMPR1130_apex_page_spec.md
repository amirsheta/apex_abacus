# IMPR1130 – APEX 21.2 Page Specification (step 03, revision 1)

- **Form:** IMPR1130 (XML module `IMPR1110_PROD_CENTRL`) – "إضافة وتعديل بيانات مستورد"
- **Package:** `IMPR1130` version 001 (`plsql/IMPR1130/`), logic report `analysis/IMPR1130/IMPR1130_logic_extraction.md`
- **Standard:** f345 (`apex/Reference/f345.sql`), CLAUDE.md §4a–§4d, `docs/f345_reference_standard.md`
- **Design data:** `work/IMPR1130/step03/page_design.json` (`build_design.py`); this file and `registry/IMPR1130_registry.sql`
  are rendered from it by `build_spec.py`; the export of step 04 (`scripts/gen_apex_impr1130.py`) reads the same data.
- **Produced:** 2026-11-24 by Claude Code. Same page design as IMPR1110 (revision 2) wherever the forms agree.

## 0. Decisions that shape the page

| # | Decision | Reason / source |
|---|---|---|
| 1 | Main page **1130** `IMPR1130`, search page **113001** `IMPR1130_SEARCH` (modal 1800×800), page group `IMPR` (reused from the IMPR1110 export) | f345 standard §3; registry page plan (SUPPORT_ENTRY already names 1130 as a caller) |
| 2 | Block IMPORTERS = native **Form** region on `IMPORTERS`, key **ROWID** (Forms key mode), `WHERE PORT_CD = :P_CURR_PORT_CD`, operations insert / update; delete by process `KEY-DELREC` | as IMPR1110; IMPR1130 allows delete (inventory §3 notes) |
| 3 | One validation + one DA per Forms WHEN-VALIDATE-ITEM; validation functions never change values or read sequences | CLAUDE.md §4c; package design §1 |
| 4 | Read-only rules: 8 flag items `P1130_<ITEM>_LOCKED` set by `READ_ONLY_FLAGS` (rules that change while the page is open) and Read Only conditions for IMPR_NBR, IMPR_TYPE_CD, BUS_ID_TYPE_CD, ARBC_IMPR_NAME, ENG_IMPR_NAME | IMPR1130's own rules: `work/IMPR1130/step02/read_only_rules.md` |
| 5 | Questions computed on the server (9-120 of CITY_CODE_OF_ID, UPDATE_IMPORTER): FOS returns `P1130_CONFIRM_TEXT`, a 2-line `apex.message.confirm` sets `P1130_ANSWER` and raises a custom event for the second FOS | IMPR1110 pattern (21.2 native Confirm cannot show server text); 2 JavaScript actions of 2 lines |
| 6 | SUPPORT_ENTRY: page 9001 opened on the **first view** of the form with `P_MODE 0` (Forms CALL_FORM in WNFI); button "بيانات المساندة الفنية" opens it again on demand (edit mode `P_MODE 1` when a letter exists) | SUPPORT_ENTRY contract §0.4 / D1; inventory §15 #3 |
| 7 | Shared components of the IMPR1110 export are **reused**: page group, application items (`G_ALLOW_MCI`, `G_ALLOW_MOI`, `G_LETTER_*`, `G_PORT_CD`, `G_SUPP_TITLE_CD`, `G_CHK_IMP_TYP`, `P_PRSNL_IMPR`, `P_LETTER_NBR`), Application Setting `HIJRI_DATE_FORMAT`, 8 LOVs. Four LOVs whose query names a page item are new (`LOV_IMPR1130_*`) | CLAUDE.md §4b.1; §4d (same LOV_APX functions) |
| 8 | Country LOV of CTRY_CD: IMPR1130 also shows the Gulf list for activity type 12; `LOV_APX.GULF_COUNTRIES` has no such option yet → **change request** `work/IMPR1130/step03/lov_apx_change_request.md` (not applied: LOV_APX is being changed by another session). Until then type 12 gets all active countries; `CTRY_CD VALIDATION` still refuses a non-Gulf country | CLAUDE.md §4d.2 (add a parameter, no copy) |
| 9 | Toolbar: page 0 (CREATE / SAVE / DELETE / SEARCH / CLEAR / FUNCS); the functions drawer shows `IMPR_MCI_SERVICE` when `P1130_ADJ_FUNS` contains it | CLAUDE.md §4a.5 |
| 10 | Navigation keys (KEY-NEXT-ITEM, GO_ITEM after the LOVs, KEY-F4 / KEY-LISTVAL calendars) are not converted: normal tab order, popup LOVs and the Hijri picker | CLAUDE.md §4c (no client UI state) |

## 1. Page type decision per block

| Block | Forms | APEX |
|---|---|---|
| IMPORTERS | base table, single record in use, query + insert + update + delete | Form region (page 1130) + search IG (page 113001) |
| TITLE, EDI_MSG, LSIDE, TOOLBAR | OLB control blocks (frame) | f345 page template, hero region, page 0 toolbar, FUNCS drawer |

## 2. Pages

| Page | Name / alias | Title | Mode | Template / class | Source |
|---|---|---|---|---|---|
| 1130 | IMPR1130 / IMPR1130 | &SYS_ANAME. (hero: module title) | Normal, Warn on Unsaved Changes, protection C | Zatca-Minimal_No_Navigation (11622270914969205733), `zf` | window CGSO$WINDOW_1, canvas CG$PAGE_1 |
| 113001 | IMPR1130_SEARCH / IMPR1130-SEARCH | &SYS_ANAME. | Modal 1800×800, protection C | theme dialog, `zf` | Enter-Query / Execute-Query of IMPORTERS (page 0 SEARCH) |

## 3. Regions

| Page | Region (Static ID) | Type | Template / classes | Source |
|---|---|---|---|---|
| 1130 | `IMPORTERS_HERO` "الهيدر" | Static HTML with `&P1130_HERO_TITLE.`; button `SUPPORT_ENTRY` | f345 hero (11621859120066869682), `cg-hero` | TITLE (OLB) |
| 1130 | `IMPORTERS` "إضافة وتعديل بيانات مستورد" | Form, table IMPORTERS, ROWID, WHERE `PORT_CD = :P_CURR_PORT_CD`, insert / update | Interactive Report (11621909206693869707), `zatca-forms cg-form cg-card` | block IMPORTERS |
| 113001 | `IMPORTERS_SEARCH_CRITERIA` "بحث" | Static, item `P113001_SEARCH`, buttons SEARCH / CLEAR | f345 hero | PRE-QUERY criteria |
| 113001 | `IMPORTERS_SEARCH` "المستوردون" | Interactive Grid (read-only), one search text over all columns, no rows before a search, `PRSNL_IMPR` → type 4 only, link IMPR_NBR → page 1130 with the URL-safe ROWID | Standard (11621913486616869708), `t-Region--noPadding`, `cg-card cg-grid` | block query + PRE-QUERY |

## 4. Items (page 1130)

Layout from the canvas CG$PAGE_1 (rows by Y, right to left by X, 12 columns). Read-only rule: §0 #4.

| Item | Column | Type | Label | Required | Mask | Default | LOV | Parents | Max | Layout | Read only | Source | Notes | Submit |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| P1130_PORT_CD | PORT_CD | Popup LOV (display = return value, manual entry) | رمز الجمــــــــــــــرك | Yes | - | - | LOV_SD_PORTS | - | 4 | 10 / row Yes / col 1 span 2 | Always (value P_CURR_PORT_CD; UpdateAllowed false) | IMPORTERS.PORT_CD (CGSO$CHAR_ARB) | - | Yes |
| P1130_PORT_NAME | - | Display Only (Send On Page Submit = No) | - | No | - | - | - | - | 40 | 20 / row No / col 3 span 8 | - | IMPORTERS.PORT_NAME (CGSO$CHAR_ARB_DO) | - | No (server value) |
| P1130_HQ_IMPR_NBR | HQ_IMPR_NBR | Display Only (Send On Page Submit = No) | الرقم الموحد بالمصلحة | No | - | - | - | - | 11 | 30 / row No / col 11 span 2 | - | IMPORTERS.HQ_IMPR_NBR (CGSO$CHAR_ARB_DO) | set by PRE-INSERT (CREATE_UNI_IMPR_NEBRAS) / PRE-UPDATE | No (server value) |
| P1130_IMPR_NBR | IMPR_NBR | Number Field | الرقــــــم الجمركــــى | No | - | - | - | - | 11 | 40 / row Yes / col 1 span 4 | PL/SQL Expression `IMPR1130.IMPR_NBR_IS_READ_ONLY(P_ROW_ID => :P1130_ROW_ID)` | IMPORTERS.IMPR_NBR (CGSO$CHAR_ARB) | new record: number of an importer to query (request EXECUTE_QUERY) | Yes |
| P1130_SUSPN_STATUS | - | Display Only (Send On Page Submit = No) | حالة المستورد بالمصلحة | No | - | - | - | - | - | 50 / row No / col 5 span 5 | - | IMPORTERS.SUSPN_STATUS (CGSO$CHAR_ARB_DO) | POST-QUERY | No (server value) |
| P1130_STATUS_DESC | - | Display Only (Send On Page Submit = No) | حالة المستورد بالوزارة | No | - | - | - | - | - | 60 / row No / col 10 span 2 | - | IMPORTERS.STATUS_DESC (CGSO$CHAR_ARB_DO) | POST-QUERY | No (server value) |
| P1130_IMPR_TYPE_CD | IMPR_TYPE_CD | Popup LOV (display = return value, manual entry) | رمز النشاط التجارى | Yes | - | - | LOV_IMPR_TYPE | - | 4 | 70 / row Yes / col 1 span 2 | PL/SQL Expression `IMPR1130.IMPR_TYPE_CD_IS_READ_ONLY(P_ROW_ID => :P1130_ROW_ID, P_PRSNL_IMPR => :P1130_P_PRSNL_IMPR)` | IMPORTERS.IMPR_TYPE_CD (CGSO$CHAR_ARB) | - | Yes |
| P1130_IMPR_TYPE_NAME | - | Display Only (Send On Page Submit = No) | - | No | - | - | - | - | 40 | 80 / row No / col 3 span 8 | - | IMPORTERS.IMPR_TYPE_NAME (CGSO$CHAR_ARB_DO) | - | No (server value) |
| P1130_BUS_ID_EXPRD_DT | BUS_ID_EXPRD_DT | Text Field, CSS class `hijri-date-default` (f345 Hijri picker) | إنتهاء النشاط | No | &P1130_HIJRI_DATE_FORMAT. | - | - | - | - | 90 / row No / col 11 span 2 | DA `BUS_ID_EXPRD_DT READ ONLY` (flag `P1130_BUS_ID_EXPRD_DT_LOCKED`) | IMPORTERS.BUS_ID_EXPRD_DT (CGSO$HDATE_ARB) | required on insert: PRE-INSERT 9-220 | Yes |
| P1130_BUS_ID_TYPE_CD | BUS_ID_TYPE_CD | Select List | نوع الرقم الإستدلالي | Yes | - | - | LOV_IMPR1130_IMPR_TYPE_BUS_ID | P1130_IMPR_TYPE_CD | 4 | 100 / row Yes / col 1 span 2 | PL/SQL Expression `IMPR1130.BUS_ID_TYPE_CD_IS_READ_ONLY(P_ROW_ID => :P1130_ROW_ID)` | IMPORTERS.BUS_ID_TYPE_CD (CGSO$CHAR_ARB_DO) | Forms: display-only item chosen with LOV_Impr_Type (button BUTT) | Yes |
| P1130_BUS_ID_TYPE_NAME | - | Display Only (Send On Page Submit = No) | - | No | - | - | - | - | 40 | 110 / row No / col 3 span 8 | - | IMPORTERS.BUS_ID_TYPE_NAME (CGSO$CHAR_ARB_DO) | - | No (server value) |
| P1130_COMM_RGSTRTN_TYPE | COMM_RGSTRTN_TYPE | Select List | نوع السجل التجاري | Validation `COMM_RGSTRTN_TYPE REQUIRED` (`COMM_RGSTRTN_TYPE_IS_REQUIRED`) | - | - | LOV_COMM_RGSTRTN_TYPE | - | 2 | 120 / row No / col 11 span 2 | DA `COMM_RGSTRTN_TYPE READ ONLY` (flag `P1130_COMM_RGSTRTN_TYPE_LOCKED`) | IMPORTERS.COMM_RGSTRTN_TYPE (CGSO$CHAR_ARB) | - | Yes |
| P1130_CTRY_CD | CTRY_CD | Popup LOV (display = return value, manual entry) | دولة الرقم الإستدلالي | Yes | - | - | LOV_IMPR1130_COUNTRIES_GULF | P1130_IMPR_TYPE_CD, P1130_BUS_ID_TYPE_CD | 4 | 130 / row Yes / col 1 span 2 | DA `CTRY_CD READ ONLY` (flag `P1130_CTRY_CD_LOCKED`) | IMPORTERS.CTRY_CD (CGSO$CHAR_ARB) | KEY-LISTVAL: CALL_LOV_COUN_GULF for type 4 / identity 16 and type 12, else CALL_LOV_COUNTRIES | Yes |
| P1130_CRTY_ARBC_NAME | - | Display Only (Send On Page Submit = No) | - | No | - | - | - | - | 50 | 140 / row No / col 3 span 10 | - | IMPORTERS.CRTY_ARBC_NAME (CGSO$CHAR_ARB_DO) | - | No (server value) |
| P1130_CITY_CODE_OF_ID | CITY_CODE_OF_ID | Popup LOV (display = return value, manual entry) | مصدررقم الإستدلالي | No | - | - | LOV_IMPR1130_CITIES_OF_ID | P1130_CTRY_CD | 4 | 150 / row Yes / col 1 span 2 | DA `CITY_CODE_OF_ID READ ONLY` (flag `P1130_CITY_CODE_OF_ID_LOCKED`) | IMPORTERS.CITY_CODE_OF_ID (CGSO$CHAR_ARB) | KEY-LISTVAL: LOV_CITIES with CTRY_CD | Yes |
| P1130_ID_CITY_NAME | - | Display Only (Send On Page Submit = No) | - | No | - | - | - | - | 20 | 160 / row No / col 3 span 8 | - | IMPORTERS.ID_CITY_NAME (CGSO$CHAR_ARB_DO) | - | No (server value) |
| P1130_IMPR_EXPR_TYPE | IMPR_EXPR_TYPE | Select List | النشاط الجمركي | Yes | - | Static: 0 | LOV_ALLOWED_EXPORT | - | 2 | 170 / row No / col 11 span 2 | - | IMPORTERS.IMPR_EXPR_TYPE (CGSO$POP_MD) | pop list CGSO$POP_MD, initial value 0 | Yes |
| P1130_NATIONAL_NBR | NATIONAL_NBR | Text Field | رقم المنشأة | Yes | - | - | - | - | 15 | 180 / row Yes / col 1 span 5 | - | IMPORTERS.NATIONAL_NBR (CGSO$CHAR_ARB) | new in IMPR1130: must start with 7; Ministry of Commerce lookup | Yes |
| P1130_BUS_ID | BUS_ID | Text Field | الرقم الاستدلالـــــــى | Yes | - | - | - | - | 15 | 190 / row No / col 6 span 5 | DA `BUS_ID READ ONLY` (flag `P1130_BUS_ID_LOCKED`) | IMPORTERS.BUS_ID (CGSO$CHAR_ARB_DO) | - | Yes |
| P1130_BUS_ID_BRNCH | BUS_ID_BRNCH | Text Field | الفرع | No | - | - | - | - | 10 | 200 / row No / col 11 span 2 | DA `BUS_ID_BRNCH READ ONLY` (flag `P1130_BUS_ID_BRNCH_LOCKED`) | IMPORTERS.BUS_ID_BRNCH (CGSO$CHAR_ARB_DO) | - | Yes |
| P1130_ARBC_IMPR_NAME | ARBC_IMPR_NAME | Text Field | الاســــم العربــــــــى | Yes | - | - | - | - | - | 210 / row Yes / col 1 span 12 | PL/SQL Expression `IMPR1130.ARBC_IMPR_NAME_IS_READ_ONLY(P_ROW_ID => :P1130_ROW_ID, P_IMPR_NBR => :P1130_IMPR_NBR, P_CURR_PORT_CD => :P_CURR_PORT_CD)` | IMPORTERS.ARBC_IMPR_NAME (CGSO$CHAR_ARB) | - | Yes |
| P1130_ENG_IMPR_NAME | ENG_IMPR_NAME | Text Field (dir=ltr) | الاســــم الأجنبـــــــي | No | - | - | - | - | - | 220 / row Yes / col 1 span 7 | PL/SQL Expression `IMPR1130.ENG_IMPR_NAME_IS_READ_ONLY(P_ROW_ID => :P1130_ROW_ID, P_IMPR_NBR => :P1130_IMPR_NBR, P_CURR_PORT_CD => :P_CURR_PORT_CD)` | IMPORTERS.ENG_IMPR_NAME (CGSO$CHAR_EN) | - | Yes |
| P1130_IMPR_CNTCT_NAME | IMPR_CNTCT_NAME | Text Field | الوكيل المفوض | No | - | - | - | - | - | 230 / row No / col 8 span 5 | - | IMPORTERS.IMPR_CNTCT_NAME (CGSO$CHAR_ARB) | - | Yes |
| P1130_IMPR_ADDRESS | IMPR_ADDRESS | Text Field | الــعـــــــنـــــــوان | No | - | - | - | - | 2000 | 240 / row Yes / col 1 span 10 | - | IMPORTERS.IMPR_ADDRESS (CGSO$CHAR_ARB) | - | Yes |
| P1130_BUS_ID_ISSUE_DT | BUS_ID_ISSUE_DT | Text Field, CSS class `hijri-date-default` (f345 Hijri picker) | تاريخ انشاء النشاط | No | &P1130_HIJRI_DATE_FORMAT. | - | - | - | - | 250 / row No / col 11 span 2 | - | IMPORTERS.BUS_ID_ISSUE_DT (CGSO$HDATE_ARB) | enterable in IMPR1130 (KEY-LISTVAL / KEY-F4 calendars) | Yes |
| P1130_IMPR_NBR_PARENT | IMPR_NBR_PARENT | Popup LOV (display = return value, manual entry) | تابــع الـــــــــــــــــى | No | - | - | LOV_IMPR | - | 11 | 260 / row Yes / col 1 span 2 | - | IMPORTERS.IMPR_NBR_PARENT (CGSO$CHAR_ARB) | - | Yes |
| P1130_IMPR_NAME_PARENT | - | Display Only (Send On Page Submit = No) | - | No | - | - | - | - | - | 270 / row No / col 3 span 10 | - | IMPORTERS.IMPR_NAME_PARENT (CGSO$CHAR_ARB_DO) | - | No (server value) |
| P1130_ADD_CTRY_CD | ADD_CTRY_CD | Popup LOV (display = return value, manual entry) | دولــــــــة الإقامـــــة | Yes | - | - | LOV_COUNTRIES | - | 4 | 280 / row Yes / col 1 span 2 | DA `ADD_CTRY_CD READ ONLY` (flag `P1130_ADD_CTRY_CD_LOCKED`) | IMPORTERS.ADD_CTRY_CD (CGSO$CHAR_ARB) | value 100 from WHEN-NEW-FORM-INSTANCE | Yes |
| P1130_ADD_CRTY_ARBC_NAME | - | Display Only (Send On Page Submit = No) | - | No | - | - | - | - | 50 | 290 / row No / col 3 span 10 | - | IMPORTERS.ADD_CRTY_ARBC_NAME (CGSO$CHAR_ARB_DO) | - | No (server value) |
| P1130_CITY_CODE | CITY_CODE | Popup LOV (display = return value, manual entry) | المدينـــــــــــــــــــــة | No | - | - | LOV_IMPR1130_CITIES | P1130_ADD_CTRY_CD | 4 | 300 / row Yes / col 1 span 2 | - | IMPORTERS.CITY_CODE (CGSO$CHAR_ARB) | required by CITY_CODE VALIDATION (Forms WVI) | Yes |
| P1130_CITY_NAME | - | Display Only (Send On Page Submit = No) | - | No | - | - | - | - | 20 | 310 / row No / col 3 span 10 | - | IMPORTERS.CITY_NAME (CGSO$CHAR_ARB_DO) | - | No (server value) |
| P1130_IMPR_POB_NBR | IMPR_POB_NBR | Number Field | صنــــدوق بريــــــــد | No | - | - | - | - | 9 | 320 / row Yes / col 1 span 4 | DA `REGISTER_ITEMS READ ONLY` (flag `P1130_REGISTER_ITEMS_LOCKED`) | IMPORTERS.IMPR_POB_NBR (CGSO$CHAR_ARB) | - | Yes |
| P1130_IMPR_ZIP_CD | IMPR_ZIP_CD | Number Field | رمز بريدي | No | - | - | - | - | 11 | 330 / row No / col 5 span 3 | DA `REGISTER_ITEMS READ ONLY` (flag `P1130_REGISTER_ITEMS_LOCKED`) | IMPORTERS.IMPR_ZIP_CD (CGSO$CHAR_ARB) | - | Yes |
| P1130_IMPR_TEL_NBR | IMPR_TEL_NBR | Text Field | تليفـون | No | - | - | - | - | 15 | 340 / row No / col 8 span 3 | - | IMPORTERS.IMPR_TEL_NBR (CGSO$CHAR_ARB) | required by IMPR_TEL_NBR VALIDATION (Forms WVI) | Yes |
| P1130_IMPR_FAX_NBR | IMPR_FAX_NBR | Text Field | فاكــس | No | - | - | - | - | 15 | 350 / row No / col 11 span 2 | DA `REGISTER_ITEMS READ ONLY` (flag `P1130_REGISTER_ITEMS_LOCKED`) | IMPORTERS.IMPR_FAX_NBR (CGSO$CHAR_ARB) | - | Yes |
| P1130_IMPR_TELEX_NBR | IMPR_TELEX_NBR | Text Field | تلكـــــــــــــــــــــــس | No | - | - | - | - | 16 | 360 / row Yes / col 1 span 6 | DA `REGISTER_ITEMS READ ONLY` (flag `P1130_REGISTER_ITEMS_LOCKED`) | IMPORTERS.IMPR_TELEX_NBR (CGSO$CHAR_ARB) | - | Yes |
| P1130_EMAIL | EMAIL | Text Field (subtype E-Mail, dir=ltr) | بريــد إلكترونى | No | - | - | - | - | - | 370 / row No / col 7 span 6 | - | IMPORTERS.EMAIL (CGSO$EMAIL) | displayed in IMPR1130 | Yes |
| P1130_MOBILE_NO | MOBILE_NO | Text Field (subtype Phone) | رقم الجوال | No | - | - | - | - | 30 | 380 / row Yes / col 1 span 5 | - | IMPORTERS.MOBILE_NO (CGSO$CHAR_EN) | displayed in IMPR1130; required by MOBILE_NO VALIDATION | Yes |
| P1130_CAR_AGENT_FLAG | CAR_AGENT_FLAG | Select List | وكيـــل سيـــارات؟ | Yes | - | Static: 0 | LOV_CAR_AGENT_FLAG | - | 2 | 390 / row No / col 6 span 5 | - | IMPORTERS.CAR_AGENT_FLAG (CGSO$POP_DO) | required in IMPR1130 | Yes |
| P1130_EXPRESS_POST | EXPRESS_POST | Select List | بريد سريع | No | - | Static: 0 | LOV_EXPRESS_POST | - | 1 | 400 / row No / col 11 span 2 | - | IMPORTERS.EXPRESS_POST (CGSO$CHAR_ARB) | - | Yes |
| P1130_BUS_ID_STATUS | BUS_ID_STATUS | Display Only, CSS u-hidden (Send On Page Submit = No) | - | No | - | - | - | - | 2 | 1010 / hidden | - | IMPORTERS.BUS_ID_STATUS (CGSO$COMBO_DO) | non-displayed item | No (server value) |
| P1130_IMPR_NAME_STD | IMPR_NAME_STD | Display Only, CSS u-hidden (Send On Page Submit = No) | - | No | - | - | - | - | 200 | 1020 / hidden | - | IMPORTERS.IMPR_NAME_STD (CGSO$CHAR_MD) | non-displayed item | No (server value) |
| P1130_LST_TRAN_DT | LST_TRAN_DT | Display Only, CSS u-hidden (Send On Page Submit = No) | - | No | YYYY/MM/DD HH24:MI:SS | - | - | - | - | 1030 / hidden | - | IMPORTERS.LST_TRAN_DT (CGSO$DATE) | non-displayed item | No (server value) |
| P1130_IMPD_STMT_NBR | IMPD_STMT_NBR | Display Only, CSS u-hidden (Send On Page Submit = No) | - | No | - | - | - | - | 10 | 1040 / hidden | - | IMPORTERS.IMPD_STMT_NBR (CGSO$NUMBER) | non-displayed item | No (server value) |
| P1130_IMPR_DATA_SRCE | IMPR_DATA_SRCE | Display Only, CSS u-hidden (Send On Page Submit = No) | - | No | - | - | - | - | 7 | 1050 / hidden | - | IMPORTERS.IMPR_DATA_SRCE (CGSO$NUMBER) | non-displayed item | No (server value) |
| P1130_CTRY_CD_OF_ID | CTRY_CD_OF_ID | Display Only, CSS u-hidden (Send On Page Submit = No) | - | No | - | Static: 100 | - | - | 4 | 1060 / hidden | - | IMPORTERS.CTRY_CD_OF_ID (CGSO$NUMBER) | non-displayed item | No (server value) |
| P1130_ID_NBR | ID_NBR | Display Only, CSS u-hidden (Send On Page Submit = No) | - | No | - | - | - | - | 15 | 1070 / hidden | - | IMPORTERS.ID_NBR (CGSO$CHAR) | non-displayed item | No (server value) |
| P1130_EXPD_STMT_NBR | EXPD_STMT_NBR | Display Only, CSS u-hidden (Send On Page Submit = No) | - | No | - | - | - | - | 11 | 1080 / hidden | - | IMPORTERS.EXPD_STMT_NBR (CGSO$NUMBER) | non-displayed item | No (server value) |
| P1130_WVR_ENTRY_NBR | WVR_ENTRY_NBR | Display Only, CSS u-hidden (Send On Page Submit = No) | - | No | - | - | - | - | 8 | 1090 / hidden | - | IMPORTERS.WVR_ENTRY_NBR (CGSO$NUMBER) | non-displayed item | No (server value) |
| P1130_ACTIVITY | ACTIVITY | Display Only, CSS u-hidden (Send On Page Submit = No) | - | No | - | - | - | - | 1000 | 1100 / hidden | - | IMPORTERS.ACTIVITY (CGSO$CHAR) | non-displayed item | No (server value) |
| P1130_BANK_IBAN | BANK_IBAN | Display Only, CSS u-hidden (Send On Page Submit = No) | - | No | - | - | - | - | 60 | 1110 / hidden | - | IMPORTERS.BANK_IBAN (CGSO$CHAR) | non-displayed item | No (server value) |
| P1130_CUSTOMS_ENTERED | CUSTOMS_ENTERED | Display Only, CSS u-hidden (Send On Page Submit = No) | - | No | - | - | - | - | 2 | 1120 / hidden | - | IMPORTERS.CUSTOMS_ENTERED (CGSO$NUMBER) | non-displayed item | No (server value) |
| P1130_CREATION_FLAG | CREATION_FLAG | Display Only, CSS u-hidden (Send On Page Submit = No) | - | No | - | Static: 1 | - | - | 4 | 1130 / hidden | - | IMPORTERS.CREATION_FLAG (CGSO$NUMBER) | non-displayed item | No (server value) |
| P1130_BIRTH_DT | BIRTH_DT | Display Only, CSS u-hidden (Send On Page Submit = No) | - | No | YYYY/MM/DD HH24:MI:SS | - | - | - | - | 1140 / hidden | - | IMPORTERS.BIRTH_DT (CGSO$DATE) | non-displayed item | No (server value) |
| P1130_ID_MINS_COMM_CD | - | Display Only, CSS u-hidden (Send On Page Submit = No) | - | No | - | - | - | - | 5 | 1150 / hidden | - | IMPORTERS.ID_MINS_COMM_CD (CGSO$NUMBER_MD) | non-displayed item | No (server value) |
| P1130_ROW_ID | ROWID (primary key) | Hidden (Value Protected = Yes) | - | No | - | - | - | - | - | 1160 / hidden | - | - | Form region primary key, type ROWID (Forms key mode ROWID); = P0_PAGE_PK | No (server value) |
| P1130_P_LETTER_NBR | - | Hidden (Value Protected = Yes) | - | No | - | - | - | - | - | hidden | - | - | :PARAMETER.LETTER_NBR (PARAMETERS ENTRY; SUPPORT_ENTRY letter) | No (server value) |
| P1130_P_PRSNL_IMPR | - | Hidden (Value Protected = Yes) | - | No | - | Static: 0 | - | - | - | hidden | - | - | :PARAMETER.PRSNL_IMPR (PARAMETERS ENTRY) | No (server value) |
| P1130_MODULE_ID | - | Hidden (Value Protected = Yes) | - | No | - | - | - | - | - | hidden | - | - | f345 Page Functions: P<page>_MODULE_ID | No (server value) |
| P1130_HIJRI_DATE_FORMAT | - | Hidden (Value Protected = Yes) | - | No | - | - | - | - | - | hidden | - | - | FORMS_APX.HIJRI_DATE_FORMAT (format mask of the Hijri items) | No (server value) |
| P1130_HERO_TITLE | - | Display Only (region IMPORTERS_HERO) | - | No | - | - | - | - | - | hidden | - | - | f345 hero title (FORMS_APX.HEADER_TITLE) | No (server value) |
| P1130_FORM_OPEN | - | Hidden (Value Protected = Yes) | - | No | - | - | - | - | - | hidden | - | - | first view of the form (WHEN-NEW-FORM-INSTANCE once) | No (server value) |
| P1130_SUPPORT_ENTRY_OPEN | - | Hidden (Value Protected = Yes) | - | No | - | - | - | - | - | hidden | - | - | Y on the first view: open SUPPORT_ENTRY (WNFI CALL_FORM P_MODE 0) | No (server value) |
| P1130_ADJ_FUNS | - | Hidden (Value Protected = Yes) | - | No | - | - | - | - | - | hidden | - | - | PU ADJ_FUNS: enabled functions of the Page Functions list | No (server value) |
| P1130_SUPPORT_URL | - | Hidden (Value Protected = No) | - | No | - | - | - | - | - | hidden | - | - | URL of page 9001 returned by SUPPORT_ENTRY.OPEN_DIALOG | No (server value) |
| P1130_CONFIRM_TEXT | - | Hidden (Value Protected = No) | - | No | - | - | - | - | - | hidden | - | - | question computed on the server (CITY_CODE_OF_ID 9-120, UPDATE_IMPORTER) | Yes |
| P1130_ANSWER | - | Hidden (Value Protected = No) | - | No | - | - | - | - | - | hidden | - | - | answer of the question: 1 = ALERT_BUTTON1, 2 = ALERT_BUTTON2 | Yes |
| P1130_COMM_RGSTRTN_TYPE_LOCKED | - | Hidden (Value Protected = No) | - | No | - | - | - | - | - | hidden | - | - | READ_ONLY_FLAGS: Y = COMM_RGSTRTN_TYPE read-only | No (server value) |
| P1130_CTRY_CD_LOCKED | - | Hidden (Value Protected = No) | - | No | - | - | - | - | - | hidden | - | - | READ_ONLY_FLAGS: Y = CTRY_CD read-only | No (server value) |
| P1130_ADD_CTRY_CD_LOCKED | - | Hidden (Value Protected = No) | - | No | - | - | - | - | - | hidden | - | - | READ_ONLY_FLAGS: Y = ADD_CTRY_CD read-only | No (server value) |
| P1130_CITY_CODE_OF_ID_LOCKED | - | Hidden (Value Protected = No) | - | No | - | - | - | - | - | hidden | - | - | READ_ONLY_FLAGS: Y = CITY_CODE_OF_ID read-only | No (server value) |
| P1130_BUS_ID_LOCKED | - | Hidden (Value Protected = No) | - | No | - | - | - | - | - | hidden | - | - | READ_ONLY_FLAGS: Y = BUS_ID read-only | No (server value) |
| P1130_BUS_ID_BRNCH_LOCKED | - | Hidden (Value Protected = No) | - | No | - | - | - | - | - | hidden | - | - | READ_ONLY_FLAGS: Y = BUS_ID_BRNCH read-only | No (server value) |
| P1130_BUS_ID_EXPRD_DT_LOCKED | - | Hidden (Value Protected = No) | - | No | - | - | - | - | - | hidden | - | - | READ_ONLY_FLAGS: Y = BUS_ID_EXPRD_DT read-only | No (server value) |
| P1130_REGISTER_ITEMS_LOCKED | - | Hidden (Value Protected = No) | - | No | - | - | - | - | - | hidden | - | - | READ_ONLY_FLAGS: Y = IMPR_POB_NBR, IMPR_ZIP_CD, IMPR_FAX_NBR, IMPR_TELEX_NBR read-only | No (server value) |

## 5. Buttons

| Page | Button | Label | Action | Source |
|---|---|---|---|---|
| 0 | CREATE / SAVE / DELETE / SEARCH / CLEAR / FUNCS | f345 page 0 toolbar | requests CREATE, SAVE, DELETE; SEARCH opens 113001 | TOOLBAR (OLB), KEY-COMMIT, KEY-DELREC, KEY-ENTQRY |
| 1130 | `SUPPORT_ENTRY` (hero region) | بيانات المساندة الفنية | DA → `SUPPORT_ENTRY.OPEN_DIALOG` (P_MODE 0 / 1) | WNFI OPEN_FORM(SUPPORT_ENTRY) |
| 113001 | `SEARCH`, `CLEAR` | بحث / مسح البحث | refresh the grid / clear the text | EXECUTE_QUERY, CLEAR |

## 6. LOVs

All SQL LOVs: *PL/SQL Function Body returning SQL Query* calling one `LOV_APX` function, return column `R`, display `D`.

| LOV | Status | LOV_APX call / source |
|---|---|---|
| LOV_SD_PORTS | reused (IMPR1110 export) | LOV form LOV_SD_PORTS (PORT_CD; read-only here) |
| LOV_IMPR_TYPE | reused (IMPR1110 export) | LOV form LOV_Impr_Type (IMPR_TYPE_CD) |
| LOV_COUNTRIES | reused (IMPR1110 export) | LOV form LOV_COUNTRIES (ADD_CTRY_CD) |
| LOV_IMPR | reused (IMPR1110 export) | LOV form LOV_IMPR (IMPR_NBR_PARENT) |
| LOV_COMM_RGSTRTN_TYPE | reused (IMPR1110 export) | list item COMM_RGSTRTN_TYPE (CG_REF_CODES) |
| LOV_ALLOWED_EXPORT | reused (IMPR1110 export) | pop list IMPR_EXPR_TYPE (CG_REF_CODES) |
| LOV_EXPRESS_POST | reused (IMPR1110 export) | list item EXPRESS_POST (static) |
| LOV_CAR_AGENT_FLAG | reused (IMPR1110 export) | pop list CAR_AGENT_FLAG (static) |
| LOV_IMPR1130_IMPR_TYPE_BUS_ID | new | `return LOV_APX.BUSINESS_ID_TYPES(P_IMPORTER_TYPE_ITEM => 'P1130_IMPR_TYPE_CD', P_ALL_STATUSES_ITEM => 'G_CHK_IMP_TYP');` – LOV form LOV_Impr_Type with IMPR_TYPE_CD (BUS_ID_TYPE_CD.KEY-LISTVAL, button BUTT) |
| LOV_IMPR1130_COUNTRIES_GULF | new | `return LOV_APX.GULF_COUNTRIES(P_IMPORTER_TYPE_ITEM => 'P1130_IMPR_TYPE_CD', P_BUSINESS_ID_TYPE_ITEM => 'P1130_BUS_ID_TYPE_CD');` – CTRY_CD.KEY-LISTVAL: CALL_LOV_COUN_GULF / CALL_LOV_COUNTRIES (TODO: type 12 Gulf list, LOV_APX change request) |
| LOV_IMPR1130_CITIES_OF_ID | new | `return LOV_APX.CITIES(P_COUNTRY_ITEM => 'P1130_CTRY_CD', P_WITH_MINISTRY_CODE => TRUE);` – CITY_CODE_OF_ID.KEY-LISTVAL: LOV_CITIES with CTRY_CD |
| LOV_IMPR1130_CITIES | new | `return LOV_APX.CITIES(P_COUNTRY_ITEM => 'P1130_ADD_CTRY_CD');` – CITY_CODE.KEY-LISTVAL: LOV_CITIES with ADD_CTRY_CD |

## 7. Validations (page 1130, request CREATE / SAVE)

| # | Name | Item | PL/SQL Function Body returning Error Text | Extra condition | Source |
|---|---|---|---|---|---|
| 1 | IMPR_NBR VALIDATION | P1130_IMPR_NBR | `RETURN IMPR1130.IMPR_NBR_VALIDATION(P_ROW_ID => :P1130_ROW_ID, P_PORT_CD => :P1130_PORT_CD, P_IMPR_NBR => :P1130_IMPR_NBR)` | :REQUEST = 'CREATE' | IMPORTERS.IMPR_NBR.WHEN-VALIDATE-ITEM |
| 2 | IMPR_TYPE_CD VALIDATION | P1130_IMPR_TYPE_CD | `RETURN IMPR1130.IMPR_TYPE_CD_VALIDATION(P_IMPR_TYPE_CD => :P1130_IMPR_TYPE_CD, P_BUS_ID_TYPE_CD => :P1130_BUS_ID_TYPE_CD, P_CTRY_CD => :P1130_CTRY_CD, P_CURR_PORT_CD => :P_CURR_PORT_CD)` | :REQUEST = 'CREATE' | IMPORTERS.IMPR_TYPE_CD.WHEN-VALIDATE-ITEM |
| 3 | BUS_ID_EXPRD_DT VALIDATION | P1130_BUS_ID_EXPRD_DT | `RETURN IMPR1130.BUS_ID_EXPRD_DT_VALIDATION(P_BUS_ID_EXPRD_DT => :P1130_BUS_ID_EXPRD_DT)` | - | IMPORTERS.BUS_ID_EXPRD_DT.WHEN-VALIDATE-ITEM |
| 4 | BUS_ID_TYPE_CD VALIDATION | P1130_BUS_ID_TYPE_CD | `RETURN IMPR1130.BUS_ID_TYPE_CD_VALIDATION(P_IMPR_TYPE_CD => :P1130_IMPR_TYPE_CD, P_BUS_ID_TYPE_CD => :P1130_BUS_ID_TYPE_CD, P_CTRY_CD => :P1130_CTRY_CD)` | :REQUEST = 'CREATE' | IMPORTERS.BUS_ID_TYPE_CD.WHEN-VALIDATE-ITEM |
| 5 | COMM_RGSTRTN_TYPE REQUIRED | P1130_COMM_RGSTRTN_TYPE | `RETURN FORMS_APX.REQUIRED_VALIDATION(ITEM_VALUE => :P1130_COMM_RGSTRTN_TYPE, ITEM_LABEL => 'نوع السجل التجاري');` | IMPR1130.COMM_RGSTRTN_TYPE_IS_REQUIRED(P_ROW_ID => :P1130_ROW_ID, P_BUS_ID_TYPE_CD => :P1130_BUS_ID_TYPE_CD) | IMPORTERS.IMPR_TYPE_CD.WHEN-VALIDATE-ITEM SET_ITEM_PROPERTY(COMM_RGSTRTN_TYPE, REQUIRED) |
| 6 | CTRY_CD VALIDATION | P1130_CTRY_CD | `RETURN IMPR1130.CTRY_CD_VALIDATION(P_IMPR_TYPE_CD => :P1130_IMPR_TYPE_CD, P_CTRY_CD => :P1130_CTRY_CD)` | :REQUEST = 'CREATE' | IMPORTERS.CTRY_CD.WHEN-VALIDATE-ITEM |
| 7 | CITY_CODE_OF_ID VALIDATION | P1130_CITY_CODE_OF_ID | `RETURN IMPR1130.CITY_CODE_OF_ID_VALIDATION(P_ROW_ID => :P1130_ROW_ID, P_IMPR_TYPE_CD => :P1130_IMPR_TYPE_CD, P_CTRY_CD => :P1130_CTRY_CD, P_CITY_CODE_OF_ID => :P1130_CITY_CODE_OF_ID, P_CTRY_CD_OF_ID => :P1130_CTRY_CD_OF_ID)` | :REQUEST = 'CREATE' | IMPORTERS.CITY_CODE_OF_ID.WHEN-VALIDATE-ITEM |
| 8 | NATIONAL_NBR VALIDATION | P1130_NATIONAL_NBR | `RETURN IMPR1130.NATIONAL_NBR_VALIDATION(P_NATIONAL_NBR => :P1130_NATIONAL_NBR)` | - | IMPORTERS.NATIONAL_NBR.WHEN-VALIDATE-ITEM |
| 9 | BUS_ID VALIDATION | P1130_BUS_ID | `RETURN IMPR1130.BUS_ID_VALIDATION(P_PORT_CD => :P1130_PORT_CD, P_IMPR_NBR => :P1130_IMPR_NBR, P_IMPR_TYPE_CD => :P1130_IMPR_TYPE_CD, P_BUS_ID_TYPE_CD => :P1130_BUS_ID_TYPE_CD, P_COMM_RGSTRTN_TYPE => :P1130_COMM_RGSTRTN_TYPE, P_CITY_CODE_OF_ID => :P1130_CITY_CODE_OF_ID, P_CTRY_CD_OF_ID => :P1130_CTRY_CD_OF_ID, P_BUS_ID => :P1130_BUS_ID, P_BUS_ID_BRNCH => :P1130_BUS_ID_BRNCH, P_ID_MINS_COMM_CD => :P1130_ID_MINS_COMM_CD, P_CURR_PORT_CD => :P_CURR_PORT_CD)` | - | IMPORTERS.BUS_ID.WHEN-VALIDATE-ITEM |
| 10 | BUS_ID_BRNCH VALIDATION | P1130_BUS_ID_BRNCH | `RETURN IMPR1130.BUS_ID_BRNCH_VALIDATION(P_PORT_CD => :P1130_PORT_CD, P_IMPR_NBR => :P1130_IMPR_NBR, P_IMPR_TYPE_CD => :P1130_IMPR_TYPE_CD, P_BUS_ID_TYPE_CD => :P1130_BUS_ID_TYPE_CD, P_COMM_RGSTRTN_TYPE => :P1130_COMM_RGSTRTN_TYPE, P_CTRY_CD => :P1130_CTRY_CD, P_BUS_ID => :P1130_BUS_ID, P_BUS_ID_BRNCH => :P1130_BUS_ID_BRNCH)` | - | IMPORTERS.BUS_ID_BRNCH.WHEN-VALIDATE-ITEM |
| 11 | ENG_IMPR_NAME VALIDATION | P1130_ENG_IMPR_NAME | `RETURN IMPR1130.ENG_IMPR_NAME_VALIDATION(P_ENG_IMPR_NAME => :P1130_ENG_IMPR_NAME)` | - | IMPORTERS.ENG_IMPR_NAME.WHEN-VALIDATE-ITEM |
| 12 | BUS_ID_ISSUE_DT VALIDATION | P1130_BUS_ID_ISSUE_DT | `RETURN IMPR1130.BUS_ID_ISSUE_DT_VALIDATION(P_BUS_ID_ISSUE_DT => :P1130_BUS_ID_ISSUE_DT)` | - | IMPORTERS.BUS_ID_ISSUE_DT.WHEN-VALIDATE-ITEM |
| 13 | CITY_CODE VALIDATION | P1130_CITY_CODE | `RETURN IMPR1130.CITY_CODE_VALIDATION(P_ADD_CTRY_CD => :P1130_ADD_CTRY_CD, P_CITY_CODE => :P1130_CITY_CODE)` | - | IMPORTERS.CITY_CODE.WHEN-VALIDATE-ITEM |
| 14 | IMPR_TEL_NBR VALIDATION | P1130_IMPR_TEL_NBR | `RETURN IMPR1130.IMPR_TEL_NBR_VALIDATION(P_IMPR_TEL_NBR => :P1130_IMPR_TEL_NBR)` | - | IMPORTERS.IMPR_TEL_NBR.WHEN-VALIDATE-ITEM |
| 15 | MOBILE_NO VALIDATION | P1130_MOBILE_NO | `RETURN IMPR1130.MOBILE_NO_VALIDATION(P_MOBILE_NO => :P1130_MOBILE_NO)` | - | IMPORTERS.MOBILE_NO.WHEN-VALIDATE-ITEM |

No page validation for EMAIL (Forms checks it only when the user leaves the item: DA only).

## 8. Processes

| Point | Seq | Name | Code | Condition | Source |
|---|---|---|---|---|---|
| Before Header | 10 | New | f345 session setup, copied from AGR1100 (condition Never) | - | f345 standard §6 |
| Before Header | 20 | P0_PAGE_PK CHECK | `IMPR1130.P0_PAGE_PK_CHECK(P_PAGE_PK => :P0_PAGE_PK, P_CURR_PORT_CD => :P_CURR_PORT_CD);` | - | f345 key (ROWID of IMPORTERS, port scope) |
| Before Header | 40 | PARAMETERS | `:P1130_MODULE_ID := FORMS_APX.GET_MODULE_ID(P_MODULE_ID => :P1130_MODULE_ID, FORM_NAME => 'IMPR1130');` | - | f345 module id of the Page Functions list |
| Before Header | 50 | PARAMETERS ENTRY | `IMPR1130.PARAMETERS_ENTRY(APP_P_PRSNL_IMPR => :P_PRSNL_IMPR, APP_P_LETTER_NBR => :P_LETTER_NBR, P_PRSNL_IMPR => :P1130_P_PRSNL_IMPR, P_LETTER_NBR => :P1130_P_LETTER_NBR);` | - | CALL_FORM parameters PRSNL_IMPR, LETTER_NBR |
| Before Header | 70 | P0_PAGE_PK | `:P1130_ROW_ID := :P0_PAGE_PK;` | - | f345 (key = ROWID, Forms key mode ROWID) |
| Before Header | 80 | Initialize form IMPORTERS | NATIVE_FORM_INIT, region IMPORTERS | - | block IMPORTERS query (Forms EXECUTE_QUERY) |
| Before Header | 82 | POST-QUERY | `IMPR1130.POST_QUERY(P_PORT_CD => :P1130_PORT_CD, P_IMPR_NBR => :P1130_IMPR_NBR, P_BUS_ID_STATUS => :P1130_BUS_ID_STATUS, P_IMPR_TYPE_CD => :P1130_IMPR_TYPE_CD, P_BUS_ID_TYPE_CD => :P1130_BUS_ID_TYPE_CD, P_CTRY_CD => :P1130_CTRY_CD, P_CITY_CODE_OF_ID => :P1130_CITY_CODE_OF_ID, P_CTRY_CD_OF_ID => :P1130_CTRY_CD_OF_ID, P_ADD_CTRY_CD => :P1130_ADD_CTRY_CD, P_CITY_CODE => :P1130_CITY_CODE, P_SUSPN_STATUS => :P1130_SUSPN_STATUS, P_STATUS_DESC => :P1130_STATUS_DESC, P_PORT_NAME => :P1130_PORT_NAME, P_IMPR_TYPE_NAME => :P1130_IMPR_TYPE_NAME, P_BUS_ID_TYPE_NAME => :P1130_BUS_ID_TYPE_NAME, P_CRTY_ARBC_NAME => :P1130_CRTY_ARBC_NAME, P_ID_CITY_NAME => :P1130_ID_CITY_NAME, P_ID_MINS_COMM_CD => :P1130_ID_MINS_COMM_CD, P_ADD_CRTY_ARBC_NAME => :P1130_ADD_CRTY_ARBC_NAME, P_CITY_NAME => :P1130_CITY_NAME);` | :P1130_ROW_ID is not null | IMPORTERS.POST-QUERY |
| Before Header | 84 | WHEN-CREATE-RECORD | `IMPR1130.WHEN_CREATE_RECORD(P_PRSNL_IMPR => :P1130_P_PRSNL_IMPR, P_PORT_CD => :P1130_PORT_CD, P_PORT_NAME => :P1130_PORT_NAME, P_IMPR_TYPE_CD => :P1130_IMPR_TYPE_CD, P_IMPR_TYPE_NAME => :P1130_IMPR_TYPE_NAME, P_CURR_PORT_CD => :P_CURR_PORT_CD);` | :P1130_ROW_ID is null | IMPORTERS.WHEN-CREATE-RECORD |
| Before Header | 85 | WHEN-NEW-FORM-INSTANCE | `IMPR1130.WHEN_NEW_FORM_INSTANCE(P_ROW_ID => :P1130_ROW_ID, P_IMPR_TYPE_CD => :P1130_IMPR_TYPE_CD, P_BUS_ID_TYPE_CD => :P1130_BUS_ID_TYPE_CD, P_CTRY_CD => :P1130_CTRY_CD, P_CRTY_ARBC_NAME => :P1130_CRTY_ARBC_NAME, P_ADD_CTRY_CD => :P1130_ADD_CTRY_CD, P_ADD_CRTY_ARBC_NAME => :P1130_ADD_CRTY_ARBC_NAME, P_CURR_PORT_CD => :P_CURR_PORT_CD, G_ALLOW_MCI => :G_ALLOW_MCI, G_ALLOW_MOI => :G_ALLOW_MOI);` | :P1130_FORM_OPEN is null | FORM.WHEN-NEW-FORM-INSTANCE (after WHEN-CREATE-RECORD of the first record, as Forms) |
| Before Header | 86 | FORM OPEN | `:P1130_FORM_OPEN := 'Y';` | :P1130_FORM_OPEN is null | WHEN-NEW-FORM-INSTANCE runs once per form instance |
| Before Header | 87 | PRE-RECORD | `IMPR1130.PRE_RECORD(P_IMPR_NBR_PARENT => :P1130_IMPR_NBR_PARENT, P_IMPR_NAME_PARENT => :P1130_IMPR_NAME_PARENT, P_CURR_PORT_CD => :P_CURR_PORT_CD);` | :P1130_ROW_ID is not null | IMPORTERS.PRE-RECORD |
| Before Header | 88 | READ ONLY FLAGS | `IMPR1130.READ_ONLY_FLAGS(P_ROW_ID => :P1130_ROW_ID, P_PRSNL_IMPR => :P1130_P_PRSNL_IMPR, P_IMPR_TYPE_CD => :P1130_IMPR_TYPE_CD, P_BUS_ID_TYPE_CD => :P1130_BUS_ID_TYPE_CD, P_COMM_RGSTRTN_TYPE => :P1130_COMM_RGSTRTN_TYPE, P_BUS_ID => :P1130_BUS_ID, P_BUS_ID_BRNCH => :P1130_BUS_ID_BRNCH, P_BUS_ID_EXPRD_DT => :P1130_BUS_ID_EXPRD_DT, P_CREATION_FLAG => :P1130_CREATION_FLAG, G_ALLOW_MCI => :G_ALLOW_MCI, P_COMM_RGSTRTN_TYPE_LOCKED => :P1130_COMM_RGSTRTN_TYPE_LOCKED, P_CTRY_CD_LOCKED => :P1130_CTRY_CD_LOCKED, P_ADD_CTRY_CD_LOCKED => :P1130_ADD_CTRY_CD_LOCKED, P_CITY_CODE_OF_ID_LOCKED => :P1130_CITY_CODE_OF_ID_LOCKED, P_BUS_ID_LOCKED => :P1130_BUS_ID_LOCKED, P_BUS_ID_BRNCH_LOCKED => :P1130_BUS_ID_BRNCH_LOCKED, P_BUS_ID_EXPRD_DT_LOCKED => :P1130_BUS_ID_EXPRD_DT_LOCKED, P_REGISTER_ITEMS_LOCKED => :P1130_REGISTER_ITEMS_LOCKED);` | - | Make_Field_Entrable of WNFI / WCR / WNRI / POST-QUERY (rules) |
| Before Header | 100 | HEADER TITLE | `FORMS_APX.HEADER_TITLE(P_MODULE_ID => :P1130_MODULE_ID, P_HERO_TITLE => :P1130_HERO_TITLE, DEFAULT_TITLE => 'إضافة وتعديل بيانات مستورد');` | - | f345 hero title (module title) |
| After Submit | 10 | EXECUTE-QUERY | `:P0_PAGE_PK := IMPR1130.IMPORTER_ROW_ID(P_IMPR_NBR => :P1130_IMPR_NBR, P_CURR_PORT_CD => :P_CURR_PORT_CD);` | :REQUEST = 'EXECUTE_QUERY' | IMPORTERS.IMPR_NBR.WHEN-VALIDATE-ITEM + WHEN-NEW-ITEM-INSTANCE EXECUTE_QUERY |
| After Submit | 20 | PRE-INSERT | `IMPR1130.PRE_INSERT(P_PORT_CD => :P1130_PORT_CD, P_IMPR_NBR => :P1130_IMPR_NBR, P_HQ_IMPR_NBR => :P1130_HQ_IMPR_NBR, P_IMPR_TYPE_CD => :P1130_IMPR_TYPE_CD, P_BUS_ID_EXPRD_DT => :P1130_BUS_ID_EXPRD_DT, P_BUS_ID_TYPE_CD => :P1130_BUS_ID_TYPE_CD, P_COMM_RGSTRTN_TYPE => :P1130_COMM_RGSTRTN_TYPE, P_CTRY_CD => :P1130_CTRY_CD, P_CITY_CODE_OF_ID => :P1130_CITY_CODE_OF_ID, P_CTRY_CD_OF_ID => :P1130_CTRY_CD_OF_ID, P_IMPR_EXPR_TYPE => :P1130_IMPR_EXPR_TYPE, P_NATIONAL_NBR => :P1130_NATIONAL_NBR, P_BUS_ID => :P1130_BUS_ID, P_BUS_ID_BRNCH => :P1130_BUS_ID_BRNCH, P_ARBC_IMPR_NAME => :P1130_ARBC_IMPR_NAME, P_ENG_IMPR_NAME => :P1130_ENG_IMPR_NAME, P_IMPR_CNTCT_NAME => :P1130_IMPR_CNTCT_NAME, P_IMPR_ADDRESS => :P1130_IMPR_ADDRESS, P_BUS_ID_ISSUE_DT => :P1130_BUS_ID_ISSUE_DT, P_IMPR_NBR_PARENT => :P1130_IMPR_NBR_PARENT, P_ADD_CTRY_CD => :P1130_ADD_CTRY_CD, P_CITY_CODE => :P1130_CITY_CODE, P_IMPR_POB_NBR => :P1130_IMPR_POB_NBR, P_IMPR_ZIP_CD => :P1130_IMPR_ZIP_CD, P_IMPR_TEL_NBR => :P1130_IMPR_TEL_NBR, P_IMPR_FAX_NBR => :P1130_IMPR_FAX_NBR, P_IMPR_TELEX_NBR => :P1130_IMPR_TELEX_NBR, P_EMAIL => :P1130_EMAIL, P_MOBILE_NO => :P1130_MOBILE_NO, P_CAR_AGENT_FLAG => :P1130_CAR_AGENT_FLAG, P_EXPRESS_POST => :P1130_EXPRESS_POST, P_ID_NBR => :P1130_ID_NBR, P_IMPD_STMT_NBR => :P1130_IMPD_STMT_NBR, P_IMPR_DATA_SRCE => :P1130_IMPR_DATA_SRCE, P_EXPD_STMT_NBR => :P1130_EXPD_STMT_NBR, P_WVR_ENTRY_NBR => :P1130_WVR_ENTRY_NBR, P_ACTIVITY => :P1130_ACTIVITY, P_BANK_IBAN => :P1130_BANK_IBAN, P_ID_CITY_NAME => :P1130_ID_CITY_NAME, P_ID_MINS_COMM_CD => :P1130_ID_MINS_COMM_CD, G_PORT_CD => :G_PORT_CD, G_SUPP_TITLE_CD => :G_SUPP_TITLE_CD, G_LETTER_NBR => :G_LETTER_NBR, G_LETTER_DT => :G_LETTER_DT, P_CURR_PORT_CD => :P_CURR_PORT_CD, SSO_APP_USER => :SSO_APP_USER, P_GLOBAL_V_WS_ID => :P_GLOBAL_V_WS_ID);` | :P0_PAGE_PK is null and :REQUEST = 'CREATE' | IMPORTERS.PRE-INSERT |
| After Submit | 30 | PRE-UPDATE | `IMPR1130.PRE_UPDATE(P_PORT_CD => :P1130_PORT_CD, P_IMPR_NBR => :P1130_IMPR_NBR, P_HQ_IMPR_NBR => :P1130_HQ_IMPR_NBR, P_BUS_ID_STATUS => :P1130_BUS_ID_STATUS, P_IMPR_TYPE_CD => :P1130_IMPR_TYPE_CD, P_BUS_ID_EXPRD_DT => :P1130_BUS_ID_EXPRD_DT, P_BUS_ID_TYPE_CD => :P1130_BUS_ID_TYPE_CD, P_COMM_RGSTRTN_TYPE => :P1130_COMM_RGSTRTN_TYPE, P_CTRY_CD => :P1130_CTRY_CD, P_CITY_CODE_OF_ID => :P1130_CITY_CODE_OF_ID, P_CTRY_CD_OF_ID => :P1130_CTRY_CD_OF_ID, P_IMPR_EXPR_TYPE => :P1130_IMPR_EXPR_TYPE, P_BUS_ID => :P1130_BUS_ID, P_BUS_ID_BRNCH => :P1130_BUS_ID_BRNCH, P_ARBC_IMPR_NAME => :P1130_ARBC_IMPR_NAME, P_IMPR_NAME_STD => :P1130_IMPR_NAME_STD, P_LST_TRAN_DT => :P1130_LST_TRAN_DT, P_IMPD_STMT_NBR => :P1130_IMPD_STMT_NBR, P_IMPR_DATA_SRCE => :P1130_IMPR_DATA_SRCE, P_ENG_IMPR_NAME => :P1130_ENG_IMPR_NAME, P_IMPR_CNTCT_NAME => :P1130_IMPR_CNTCT_NAME, P_IMPR_ADDRESS => :P1130_IMPR_ADDRESS, P_BUS_ID_ISSUE_DT => :P1130_BUS_ID_ISSUE_DT, P_IMPR_NBR_PARENT => :P1130_IMPR_NBR_PARENT, P_ADD_CTRY_CD => :P1130_ADD_CTRY_CD, P_CITY_CODE => :P1130_CITY_CODE, P_IMPR_POB_NBR => :P1130_IMPR_POB_NBR, P_IMPR_ZIP_CD => :P1130_IMPR_ZIP_CD, P_IMPR_TEL_NBR => :P1130_IMPR_TEL_NBR, P_IMPR_FAX_NBR => :P1130_IMPR_FAX_NBR, P_IMPR_TELEX_NBR => :P1130_IMPR_TELEX_NBR, P_EMAIL => :P1130_EMAIL, P_ID_NBR => :P1130_ID_NBR, P_CREATION_FLAG => :P1130_CREATION_FLAG, P_CURR_PORT_CD => :P_CURR_PORT_CD, SSO_APP_USER => :SSO_APP_USER, P_GLOBAL_V_WS_ID => :P_GLOBAL_V_WS_ID);` | :P0_PAGE_PK is not null and :REQUEST = 'SAVE' | IMPORTERS.PRE-UPDATE |
| After Submit | 35 | KEY-DELREC | `IMPR1130.KEY_DELREC(P_ROW_ID => :P1130_ROW_ID, P_PORT_CD => :P1130_PORT_CD, P_IMPR_NBR => :P1130_IMPR_NBR, P_CURR_PORT_CD => :P_CURR_PORT_CD, SSO_APP_USER => :SSO_APP_USER, P_GLOBAL_V_WS_ID => :P_GLOBAL_V_WS_ID);` | :REQUEST = 'DELETE' | IMPORTERS.KEY-DELREC + PRE-DELETE |
| After Submit | 40 | Process form IMPORTERS | NATIVE_FORM_DML, region IMPORTERS, Prevent Lost Updates = Yes, Lock Row = Yes, Return Primary Key(s) after Insert = Yes | :REQUEST in ('CREATE', 'SAVE') | Forms default INSERT / UPDATE of block IMPORTERS |
| After Submit | 50 | POST-INSERT | `IMPR1130.POST_INSERT(P_ROW_ID => :P1130_ROW_ID, P_IMPR_NBR => :P1130_IMPR_NBR, SSO_APP_USER => :SSO_APP_USER);` | :P0_PAGE_PK is null and :REQUEST = 'CREATE' | IMPORTERS.POST-INSERT |
| After Submit | 80 | P0_PAGE_PK AFTER INSERT | `:P0_PAGE_PK := :P1130_ROW_ID;` | :P0_PAGE_PK is null and :REQUEST = 'CREATE' | f345: the new record stays on the page (Forms stays on the record after COMMIT) |
| After Submit | 85 | P0_PAGE_PK AFTER DELETE | `:P0_PAGE_PK := NULL;` | :REQUEST = 'DELETE' | Forms Delete_record + COMMIT: an empty record follows |

## 9. Computations

| Item | Point | Expression | Condition | Source |
|---|---|---|---|---|
| P1130_HIJRI_DATE_FORMAT | Before Header | `FORMS_APX.HIJRI_DATE_FORMAT` | - | Hijri date format from one place: Application Setting HIJRI_DATE_FORMAT (Forms mask MI-MM-YYYY) |
| P1130_SUPPORT_ENTRY_OPEN | Before Header | `CASE WHEN :P1130_FORM_OPEN IS NULL THEN 'Y' ELSE 'N' END` | - | FORM.WHEN-NEW-FORM-INSTANCE CALL_FORM(SUPPORT_ENTRY) on the first view (computations run before the processes) |
| P1130_ADJ_FUNS | After Header | `IMPR1130.ADJ_FUNS(P_IMPR_TYPE_CD => :P1130_IMPR_TYPE_CD, P_BUS_ID_TYPE_CD => :P1130_BUS_ID_TYPE_CD, G_ALLOW_MCI => :G_ALLOW_MCI, G_ALLOW_MOI => :G_ALLOW_MOI)` | - | PU ADJ_FUNS (TMPLT.ENABLE_FUN / DISABLE_FUN), filter of the f345 Page Functions list |

## 10. Dynamic Actions (page 1130)

| DA | Event | Selection | Client condition | Fire on init | # | Action | Code | Items to Submit | Items to Return | Note | Source |
|---|---|---|---|---|---|---|---|---|---|---|---|
| IMPR_NBR WHEN-VALIDATE-ITEM | Change | Item P1130_IMPR_NBR | Item P1130_IMPR_NBR is not null | No | 1 | FOS - Execute PL/SQL Code | `FORMS_APX.CHECK_ERROR(IMPR1130.IMPR_NBR_VALIDATION(P_ROW_ID => :P1130_ROW_ID, P_PORT_CD => :P1130_PORT_CD, P_IMPR_NBR => :P1130_IMPR_NBR));` | P1130_IMPR_NBR, P1130_PORT_CD, P1130_ROW_ID | - | - | IMPORTERS.IMPR_NBR.WHEN-VALIDATE-ITEM |
| - | - | - | - | - | 2 | Submit Page | request EXECUTE_QUERY | - | - | runs only when the FOS succeeded (the number exists) - Forms :GLOBAL.EXEC_QUERY_NOW + EXECUTE_QUERY | - |
| IMPR_TYPE_CD WHEN-VALIDATE-ITEM | Change | Item P1130_IMPR_TYPE_CD | - | No | 1 | FOS - Execute PL/SQL Code | `IMPR1130.IMPR_TYPE_CD_VALIDATE_ITEM(P_IMPR_TYPE_CD => :P1130_IMPR_TYPE_CD, P_IMPR_TYPE_NAME => :P1130_IMPR_TYPE_NAME, P_BUS_ID_TYPE_CD => :P1130_BUS_ID_TYPE_CD, P_BUS_ID_TYPE_NAME => :P1130_BUS_ID_TYPE_NAME, P_BUS_ID => :P1130_BUS_ID, P_CTRY_CD => :P1130_CTRY_CD, P_CRTY_ARBC_NAME => :P1130_CRTY_ARBC_NAME, P_ADD_CTRY_CD => :P1130_ADD_CTRY_CD, P_ADD_CRTY_ARBC_NAME => :P1130_ADD_CRTY_ARBC_NAME, P_CURR_PORT_CD => :P_CURR_PORT_CD);` | P1130_ADD_CRTY_ARBC_NAME, P1130_ADD_CTRY_CD, P1130_BUS_ID, P1130_BUS_ID_TYPE_CD, P1130_BUS_ID_TYPE_NAME, P1130_CRTY_ARBC_NAME, P1130_CTRY_CD, P1130_IMPR_TYPE_CD, P1130_IMPR_TYPE_NAME | P1130_IMPR_TYPE_CD, P1130_IMPR_TYPE_NAME, P1130_BUS_ID_TYPE_CD, P1130_BUS_ID_TYPE_NAME, P1130_BUS_ID, P1130_CTRY_CD, P1130_CRTY_ARBC_NAME, P1130_ADD_CTRY_CD, P1130_ADD_CRTY_ARBC_NAME | - | IMPORTERS.IMPR_TYPE_CD.WHEN-VALIDATE-ITEM (+ KEY-LISTVAL return values) |
| - | - | - | - | - | 2 | FOS - Execute PL/SQL Code (change events ON) | `IMPR1130.READ_ONLY_FLAGS(P_ROW_ID => :P1130_ROW_ID, P_PRSNL_IMPR => :P1130_P_PRSNL_IMPR, P_IMPR_TYPE_CD => :P1130_IMPR_TYPE_CD, P_BUS_ID_TYPE_CD => :P1130_BUS_ID_TYPE_CD, P_COMM_RGSTRTN_TYPE => :P1130_COMM_RGSTRTN_TYPE, P_BUS_ID => :P1130_BUS_ID, P_BUS_ID_BRNCH => :P1130_BUS_ID_BRNCH, P_BUS_ID_EXPRD_DT => :P1130_BUS_ID_EXPRD_DT, P_CREATION_FLAG => :P1130_CREATION_FLAG, G_ALLOW_MCI => :G_ALLOW_MCI, P_COMM_RGSTRTN_TYPE_LOCKED => :P1130_COMM_RGSTRTN_TYPE_LOCKED, P_CTRY_CD_LOCKED => :P1130_CTRY_CD_LOCKED, P_ADD_CTRY_CD_LOCKED => :P1130_ADD_CTRY_CD_LOCKED, P_CITY_CODE_OF_ID_LOCKED => :P1130_CITY_CODE_OF_ID_LOCKED, P_BUS_ID_LOCKED => :P1130_BUS_ID_LOCKED, P_BUS_ID_BRNCH_LOCKED => :P1130_BUS_ID_BRNCH_LOCKED, P_BUS_ID_EXPRD_DT_LOCKED => :P1130_BUS_ID_EXPRD_DT_LOCKED, P_REGISTER_ITEMS_LOCKED => :P1130_REGISTER_ITEMS_LOCKED);` | P1130_BUS_ID, P1130_BUS_ID_BRNCH, P1130_BUS_ID_EXPRD_DT, P1130_BUS_ID_TYPE_CD, P1130_COMM_RGSTRTN_TYPE, P1130_CREATION_FLAG, P1130_IMPR_TYPE_CD, P1130_P_PRSNL_IMPR, P1130_ROW_ID | P1130_COMM_RGSTRTN_TYPE_LOCKED, P1130_CTRY_CD_LOCKED, P1130_ADD_CTRY_CD_LOCKED, P1130_CITY_CODE_OF_ID_LOCKED, P1130_BUS_ID_LOCKED, P1130_BUS_ID_BRNCH_LOCKED, P1130_BUS_ID_EXPRD_DT_LOCKED, P1130_REGISTER_ITEMS_LOCKED | last action: the read-only flags fire the DAs "<ITEM> READ ONLY" | - |
| BUS_ID_EXPRD_DT WHEN-VALIDATE-ITEM | Change | Item P1130_BUS_ID_EXPRD_DT | - | No | 1 | FOS - Execute PL/SQL Code | `FORMS_APX.CHECK_ERROR(IMPR1130.BUS_ID_EXPRD_DT_VALIDATION(P_BUS_ID_EXPRD_DT => :P1130_BUS_ID_EXPRD_DT));` | P1130_BUS_ID_EXPRD_DT | - | - | IMPORTERS.BUS_ID_EXPRD_DT.WHEN-VALIDATE-ITEM |
| BUS_ID_TYPE_CD WHEN-VALIDATE-ITEM | Change | Item P1130_BUS_ID_TYPE_CD | - | No | 1 | FOS - Execute PL/SQL Code | `IMPR1130.BUS_ID_TYPE_CD_VALIDATE_ITEM(P_IMPR_TYPE_CD => :P1130_IMPR_TYPE_CD, P_CTRY_CD => :P1130_CTRY_CD, P_BUS_ID_TYPE_CD => :P1130_BUS_ID_TYPE_CD, P_BUS_ID_TYPE_NAME => :P1130_BUS_ID_TYPE_NAME);` | P1130_BUS_ID_TYPE_CD, P1130_BUS_ID_TYPE_NAME, P1130_CTRY_CD, P1130_IMPR_TYPE_CD | P1130_BUS_ID_TYPE_NAME | - | IMPORTERS.BUS_ID_TYPE_CD.WHEN-VALIDATE-ITEM (+ KEY-LISTVAL return values) |
| - | - | - | - | - | 2 | FOS - Execute PL/SQL Code (change events ON) | `IMPR1130.READ_ONLY_FLAGS(P_ROW_ID => :P1130_ROW_ID, P_PRSNL_IMPR => :P1130_P_PRSNL_IMPR, P_IMPR_TYPE_CD => :P1130_IMPR_TYPE_CD, P_BUS_ID_TYPE_CD => :P1130_BUS_ID_TYPE_CD, P_COMM_RGSTRTN_TYPE => :P1130_COMM_RGSTRTN_TYPE, P_BUS_ID => :P1130_BUS_ID, P_BUS_ID_BRNCH => :P1130_BUS_ID_BRNCH, P_BUS_ID_EXPRD_DT => :P1130_BUS_ID_EXPRD_DT, P_CREATION_FLAG => :P1130_CREATION_FLAG, G_ALLOW_MCI => :G_ALLOW_MCI, P_COMM_RGSTRTN_TYPE_LOCKED => :P1130_COMM_RGSTRTN_TYPE_LOCKED, P_CTRY_CD_LOCKED => :P1130_CTRY_CD_LOCKED, P_ADD_CTRY_CD_LOCKED => :P1130_ADD_CTRY_CD_LOCKED, P_CITY_CODE_OF_ID_LOCKED => :P1130_CITY_CODE_OF_ID_LOCKED, P_BUS_ID_LOCKED => :P1130_BUS_ID_LOCKED, P_BUS_ID_BRNCH_LOCKED => :P1130_BUS_ID_BRNCH_LOCKED, P_BUS_ID_EXPRD_DT_LOCKED => :P1130_BUS_ID_EXPRD_DT_LOCKED, P_REGISTER_ITEMS_LOCKED => :P1130_REGISTER_ITEMS_LOCKED);` | P1130_BUS_ID, P1130_BUS_ID_BRNCH, P1130_BUS_ID_EXPRD_DT, P1130_BUS_ID_TYPE_CD, P1130_COMM_RGSTRTN_TYPE, P1130_CREATION_FLAG, P1130_IMPR_TYPE_CD, P1130_P_PRSNL_IMPR, P1130_ROW_ID | P1130_COMM_RGSTRTN_TYPE_LOCKED, P1130_CTRY_CD_LOCKED, P1130_ADD_CTRY_CD_LOCKED, P1130_CITY_CODE_OF_ID_LOCKED, P1130_BUS_ID_LOCKED, P1130_BUS_ID_BRNCH_LOCKED, P1130_BUS_ID_EXPRD_DT_LOCKED, P1130_REGISTER_ITEMS_LOCKED | last action: the read-only flags fire the DAs "<ITEM> READ ONLY" | - |
| COMM_RGSTRTN_TYPE WHEN-LIST-CHANGED | Change | Item P1130_COMM_RGSTRTN_TYPE | - | No | 1 | FOS - Execute PL/SQL Code | `IMPR1130.COMM_RGSTRTN_TYPE_LIST_CHANGED(P_COMM_RGSTRTN_TYPE => :P1130_COMM_RGSTRTN_TYPE, P_BUS_ID_BRNCH => :P1130_BUS_ID_BRNCH);` | P1130_BUS_ID_BRNCH, P1130_COMM_RGSTRTN_TYPE | P1130_BUS_ID_BRNCH | - | IMPORTERS.COMM_RGSTRTN_TYPE.WHEN-LIST-CHANGED |
| - | - | - | - | - | 2 | FOS - Execute PL/SQL Code (change events ON) | `IMPR1130.READ_ONLY_FLAGS(P_ROW_ID => :P1130_ROW_ID, P_PRSNL_IMPR => :P1130_P_PRSNL_IMPR, P_IMPR_TYPE_CD => :P1130_IMPR_TYPE_CD, P_BUS_ID_TYPE_CD => :P1130_BUS_ID_TYPE_CD, P_COMM_RGSTRTN_TYPE => :P1130_COMM_RGSTRTN_TYPE, P_BUS_ID => :P1130_BUS_ID, P_BUS_ID_BRNCH => :P1130_BUS_ID_BRNCH, P_BUS_ID_EXPRD_DT => :P1130_BUS_ID_EXPRD_DT, P_CREATION_FLAG => :P1130_CREATION_FLAG, G_ALLOW_MCI => :G_ALLOW_MCI, P_COMM_RGSTRTN_TYPE_LOCKED => :P1130_COMM_RGSTRTN_TYPE_LOCKED, P_CTRY_CD_LOCKED => :P1130_CTRY_CD_LOCKED, P_ADD_CTRY_CD_LOCKED => :P1130_ADD_CTRY_CD_LOCKED, P_CITY_CODE_OF_ID_LOCKED => :P1130_CITY_CODE_OF_ID_LOCKED, P_BUS_ID_LOCKED => :P1130_BUS_ID_LOCKED, P_BUS_ID_BRNCH_LOCKED => :P1130_BUS_ID_BRNCH_LOCKED, P_BUS_ID_EXPRD_DT_LOCKED => :P1130_BUS_ID_EXPRD_DT_LOCKED, P_REGISTER_ITEMS_LOCKED => :P1130_REGISTER_ITEMS_LOCKED);` | P1130_BUS_ID, P1130_BUS_ID_BRNCH, P1130_BUS_ID_EXPRD_DT, P1130_BUS_ID_TYPE_CD, P1130_COMM_RGSTRTN_TYPE, P1130_CREATION_FLAG, P1130_IMPR_TYPE_CD, P1130_P_PRSNL_IMPR, P1130_ROW_ID | P1130_COMM_RGSTRTN_TYPE_LOCKED, P1130_CTRY_CD_LOCKED, P1130_ADD_CTRY_CD_LOCKED, P1130_CITY_CODE_OF_ID_LOCKED, P1130_BUS_ID_LOCKED, P1130_BUS_ID_BRNCH_LOCKED, P1130_BUS_ID_EXPRD_DT_LOCKED, P1130_REGISTER_ITEMS_LOCKED | last action: the read-only flags fire the DAs "<ITEM> READ ONLY" | - |
| CTRY_CD WHEN-VALIDATE-ITEM | Change | Item P1130_CTRY_CD | - | No | 1 | FOS - Execute PL/SQL Code | `IMPR1130.CTRY_CD_WHEN_VALIDATE_ITEM(P_IMPR_TYPE_CD => :P1130_IMPR_TYPE_CD, P_CTRY_CD => :P1130_CTRY_CD, P_CRTY_ARBC_NAME => :P1130_CRTY_ARBC_NAME);` | P1130_CRTY_ARBC_NAME, P1130_CTRY_CD, P1130_IMPR_TYPE_CD | P1130_CRTY_ARBC_NAME | - | IMPORTERS.CTRY_CD.WHEN-VALIDATE-ITEM (+ KEY-LISTVAL return values) |
| CITY_CODE_OF_ID WHEN-VALIDATE-ITEM | Change | Item P1130_CITY_CODE_OF_ID | - | No | 1 | FOS - Execute PL/SQL Code | `:P1130_CONFIRM_TEXT := IMPR1130.CITY_CODE_OF_ID_CONFIRM_TEXT(P_IMPR_TYPE_CD => :P1130_IMPR_TYPE_CD, P_CTRY_CD => :P1130_CTRY_CD, P_BUS_ID_TYPE_CD => :P1130_BUS_ID_TYPE_CD, P_BUS_ID => :P1130_BUS_ID, P_CITY_CODE_OF_ID => :P1130_CITY_CODE_OF_ID, P_CTRY_CD_OF_ID => :P1130_CTRY_CD_OF_ID);` | P1130_BUS_ID, P1130_BUS_ID_TYPE_CD, P1130_CITY_CODE_OF_ID, P1130_CTRY_CD, P1130_CTRY_CD_OF_ID, P1130_IMPR_TYPE_CD | P1130_CONFIRM_TEXT | - | IMPORTERS.CITY_CODE_OF_ID.WHEN-VALIDATE-ITEM (question 9-120) |
| - | - | - | - | - | 2 | Execute JavaScript Code | `var t = $v('P1130_CONFIRM_TEXT'), go = function (a) { $s('P1130_ANSWER', a); apex.event.trigger('#P1130_CITY_CODE_OF_ID', 'impr1130-city-code-of-id-validate'); }; if (t) { apex.message.confirm(t, function (ok) { go(ok ? '1' : '2'); }); } else { go('1'); }` | - | - | STR.DispAlert(9-120, CONFIRM): question text computed on the server, answer in P1130_ANSWER | - |
| CITY_CODE_OF_ID WHEN-VALIDATE-ITEM CONFIRMED | Custom: impr1130-city-code-of-id-validate | Item P1130_CITY_CODE_OF_ID | - | No | 1 | FOS - Execute PL/SQL Code | `IMPR1130.CITY_CODE_OF_ID_VALIDATE_ITEM(P_ROW_ID => :P1130_ROW_ID, P_IMPR_TYPE_CD => :P1130_IMPR_TYPE_CD, P_CTRY_CD => :P1130_CTRY_CD, P_BUS_ID_TYPE_CD => :P1130_BUS_ID_TYPE_CD, P_ANSWER => :P1130_ANSWER, P_CITY_CODE_OF_ID => :P1130_CITY_CODE_OF_ID, P_CTRY_CD_OF_ID => :P1130_CTRY_CD_OF_ID, P_BUS_ID => :P1130_BUS_ID, P_ID_MINS_COMM_CD => :P1130_ID_MINS_COMM_CD, P_ID_CITY_NAME => :P1130_ID_CITY_NAME);` | P1130_ANSWER, P1130_BUS_ID, P1130_BUS_ID_TYPE_CD, P1130_CITY_CODE_OF_ID, P1130_CTRY_CD, P1130_CTRY_CD_OF_ID, P1130_ID_CITY_NAME, P1130_ID_MINS_COMM_CD, P1130_IMPR_TYPE_CD, P1130_ROW_ID | P1130_CTRY_CD_OF_ID, P1130_BUS_ID, P1130_ID_MINS_COMM_CD, P1130_ID_CITY_NAME | - | IMPORTERS.CITY_CODE_OF_ID.WHEN-VALIDATE-ITEM (after the answer) + WHEN-NEW-ITEM-INSTANCE + CTRY_CD_OF_ID.WHEN-VALIDATE-ITEM |
| - | - | - | - | - | 2 | FOS - Execute PL/SQL Code (change events ON) | `IMPR1130.READ_ONLY_FLAGS(P_ROW_ID => :P1130_ROW_ID, P_PRSNL_IMPR => :P1130_P_PRSNL_IMPR, P_IMPR_TYPE_CD => :P1130_IMPR_TYPE_CD, P_BUS_ID_TYPE_CD => :P1130_BUS_ID_TYPE_CD, P_COMM_RGSTRTN_TYPE => :P1130_COMM_RGSTRTN_TYPE, P_BUS_ID => :P1130_BUS_ID, P_BUS_ID_BRNCH => :P1130_BUS_ID_BRNCH, P_BUS_ID_EXPRD_DT => :P1130_BUS_ID_EXPRD_DT, P_CREATION_FLAG => :P1130_CREATION_FLAG, G_ALLOW_MCI => :G_ALLOW_MCI, P_COMM_RGSTRTN_TYPE_LOCKED => :P1130_COMM_RGSTRTN_TYPE_LOCKED, P_CTRY_CD_LOCKED => :P1130_CTRY_CD_LOCKED, P_ADD_CTRY_CD_LOCKED => :P1130_ADD_CTRY_CD_LOCKED, P_CITY_CODE_OF_ID_LOCKED => :P1130_CITY_CODE_OF_ID_LOCKED, P_BUS_ID_LOCKED => :P1130_BUS_ID_LOCKED, P_BUS_ID_BRNCH_LOCKED => :P1130_BUS_ID_BRNCH_LOCKED, P_BUS_ID_EXPRD_DT_LOCKED => :P1130_BUS_ID_EXPRD_DT_LOCKED, P_REGISTER_ITEMS_LOCKED => :P1130_REGISTER_ITEMS_LOCKED);` | P1130_BUS_ID, P1130_BUS_ID_BRNCH, P1130_BUS_ID_EXPRD_DT, P1130_BUS_ID_TYPE_CD, P1130_COMM_RGSTRTN_TYPE, P1130_CREATION_FLAG, P1130_IMPR_TYPE_CD, P1130_P_PRSNL_IMPR, P1130_ROW_ID | P1130_COMM_RGSTRTN_TYPE_LOCKED, P1130_CTRY_CD_LOCKED, P1130_ADD_CTRY_CD_LOCKED, P1130_CITY_CODE_OF_ID_LOCKED, P1130_BUS_ID_LOCKED, P1130_BUS_ID_BRNCH_LOCKED, P1130_BUS_ID_EXPRD_DT_LOCKED, P1130_REGISTER_ITEMS_LOCKED | last action: the read-only flags fire the DAs "<ITEM> READ ONLY" | - |
| NATIONAL_NBR WHEN-VALIDATE-ITEM | Change | Item P1130_NATIONAL_NBR | - | No | 1 | FOS - Execute PL/SQL Code | `IMPR1130.NATIONAL_NBR_VALIDATE_ITEM(P_ROW_ID => :P1130_ROW_ID, P_IMPR_TYPE_CD => :P1130_IMPR_TYPE_CD, P_BUS_ID_TYPE_CD => :P1130_BUS_ID_TYPE_CD, P_COMM_RGSTRTN_TYPE => :P1130_COMM_RGSTRTN_TYPE, P_NATIONAL_NBR => :P1130_NATIONAL_NBR, P_BUS_ID => :P1130_BUS_ID, P_BUS_ID_BRNCH => :P1130_BUS_ID_BRNCH, P_BUS_ID_EXPRD_DT => :P1130_BUS_ID_EXPRD_DT, P_BUS_ID_ISSUE_DT => :P1130_BUS_ID_ISSUE_DT, P_ARBC_IMPR_NAME => :P1130_ARBC_IMPR_NAME, P_IMPR_NAME_STD => :P1130_IMPR_NAME_STD, P_IMPR_ADDRESS => :P1130_IMPR_ADDRESS, P_IMPR_TEL_NBR => :P1130_IMPR_TEL_NBR, P_IMPR_FAX_NBR => :P1130_IMPR_FAX_NBR, P_IMPR_TELEX_NBR => :P1130_IMPR_TELEX_NBR, P_ACTIVITY => :P1130_ACTIVITY, P_BUS_ID_STATUS => :P1130_BUS_ID_STATUS, P_CITY_CODE_OF_ID => :P1130_CITY_CODE_OF_ID, P_LST_TRAN_DT => :P1130_LST_TRAN_DT, P_CREATION_FLAG => :P1130_CREATION_FLAG, G_ALLOW_MCI => :G_ALLOW_MCI);` | P1130_ACTIVITY, P1130_ARBC_IMPR_NAME, P1130_BUS_ID, P1130_BUS_ID_BRNCH, P1130_BUS_ID_EXPRD_DT, P1130_BUS_ID_ISSUE_DT, P1130_BUS_ID_STATUS, P1130_BUS_ID_TYPE_CD, P1130_CITY_CODE_OF_ID, P1130_COMM_RGSTRTN_TYPE, P1130_CREATION_FLAG, P1130_IMPR_ADDRESS, P1130_IMPR_FAX_NBR, P1130_IMPR_NAME_STD, P1130_IMPR_TELEX_NBR, P1130_IMPR_TEL_NBR, P1130_IMPR_TYPE_CD, P1130_LST_TRAN_DT, P1130_NATIONAL_NBR, P1130_ROW_ID | P1130_BUS_ID, P1130_BUS_ID_BRNCH, P1130_BUS_ID_EXPRD_DT, P1130_BUS_ID_ISSUE_DT, P1130_ARBC_IMPR_NAME, P1130_IMPR_NAME_STD, P1130_IMPR_ADDRESS, P1130_IMPR_TEL_NBR, P1130_IMPR_FAX_NBR, P1130_IMPR_TELEX_NBR, P1130_ACTIVITY, P1130_BUS_ID_STATUS, P1130_CITY_CODE_OF_ID, P1130_LST_TRAN_DT, P1130_CREATION_FLAG | - | IMPORTERS.NATIONAL_NBR.WHEN-VALIDATE-ITEM (GET_MAIN_CR_DATA / GET_BRANCH_CR_DATA / GET_CR_DATA) |
| - | - | - | - | - | 2 | FOS - Execute PL/SQL Code (change events ON) | `IMPR1130.READ_ONLY_FLAGS(P_ROW_ID => :P1130_ROW_ID, P_PRSNL_IMPR => :P1130_P_PRSNL_IMPR, P_IMPR_TYPE_CD => :P1130_IMPR_TYPE_CD, P_BUS_ID_TYPE_CD => :P1130_BUS_ID_TYPE_CD, P_COMM_RGSTRTN_TYPE => :P1130_COMM_RGSTRTN_TYPE, P_BUS_ID => :P1130_BUS_ID, P_BUS_ID_BRNCH => :P1130_BUS_ID_BRNCH, P_BUS_ID_EXPRD_DT => :P1130_BUS_ID_EXPRD_DT, P_CREATION_FLAG => :P1130_CREATION_FLAG, G_ALLOW_MCI => :G_ALLOW_MCI, P_COMM_RGSTRTN_TYPE_LOCKED => :P1130_COMM_RGSTRTN_TYPE_LOCKED, P_CTRY_CD_LOCKED => :P1130_CTRY_CD_LOCKED, P_ADD_CTRY_CD_LOCKED => :P1130_ADD_CTRY_CD_LOCKED, P_CITY_CODE_OF_ID_LOCKED => :P1130_CITY_CODE_OF_ID_LOCKED, P_BUS_ID_LOCKED => :P1130_BUS_ID_LOCKED, P_BUS_ID_BRNCH_LOCKED => :P1130_BUS_ID_BRNCH_LOCKED, P_BUS_ID_EXPRD_DT_LOCKED => :P1130_BUS_ID_EXPRD_DT_LOCKED, P_REGISTER_ITEMS_LOCKED => :P1130_REGISTER_ITEMS_LOCKED);` | P1130_BUS_ID, P1130_BUS_ID_BRNCH, P1130_BUS_ID_EXPRD_DT, P1130_BUS_ID_TYPE_CD, P1130_COMM_RGSTRTN_TYPE, P1130_CREATION_FLAG, P1130_IMPR_TYPE_CD, P1130_P_PRSNL_IMPR, P1130_ROW_ID | P1130_COMM_RGSTRTN_TYPE_LOCKED, P1130_CTRY_CD_LOCKED, P1130_ADD_CTRY_CD_LOCKED, P1130_CITY_CODE_OF_ID_LOCKED, P1130_BUS_ID_LOCKED, P1130_BUS_ID_BRNCH_LOCKED, P1130_BUS_ID_EXPRD_DT_LOCKED, P1130_REGISTER_ITEMS_LOCKED | last action: the read-only flags fire the DAs "<ITEM> READ ONLY" | - |
| BUS_ID WHEN-VALIDATE-ITEM | Change | Item P1130_BUS_ID | - | No | 1 | FOS - Execute PL/SQL Code | `IMPR1130.BUS_ID_WHEN_VALIDATE_ITEM(P_PORT_CD => :P1130_PORT_CD, P_IMPR_NBR => :P1130_IMPR_NBR, P_IMPR_TYPE_CD => :P1130_IMPR_TYPE_CD, P_BUS_ID_TYPE_CD => :P1130_BUS_ID_TYPE_CD, P_COMM_RGSTRTN_TYPE => :P1130_COMM_RGSTRTN_TYPE, P_CITY_CODE_OF_ID => :P1130_CITY_CODE_OF_ID, P_CTRY_CD_OF_ID => :P1130_CTRY_CD_OF_ID, P_BUS_ID_BRNCH => :P1130_BUS_ID_BRNCH, P_BUS_ID => :P1130_BUS_ID, P_ID_MINS_COMM_CD => :P1130_ID_MINS_COMM_CD, P_ARBC_IMPR_NAME => :P1130_ARBC_IMPR_NAME, P_IMPR_NAME_STD => :P1130_IMPR_NAME_STD, P_BUS_ID_EXPRD_DT => :P1130_BUS_ID_EXPRD_DT, P_IMPR_TEL_NBR => :P1130_IMPR_TEL_NBR, P_IMPR_POB_NBR => :P1130_IMPR_POB_NBR, P_IMPR_ZIP_CD => :P1130_IMPR_ZIP_CD, P_IMPR_FAX_NBR => :P1130_IMPR_FAX_NBR, P_IMPR_TELEX_NBR => :P1130_IMPR_TELEX_NBR, P_CURR_PORT_CD => :P_CURR_PORT_CD);` | P1130_ARBC_IMPR_NAME, P1130_BUS_ID, P1130_BUS_ID_BRNCH, P1130_BUS_ID_EXPRD_DT, P1130_BUS_ID_TYPE_CD, P1130_CITY_CODE_OF_ID, P1130_COMM_RGSTRTN_TYPE, P1130_CTRY_CD_OF_ID, P1130_ID_MINS_COMM_CD, P1130_IMPR_FAX_NBR, P1130_IMPR_NAME_STD, P1130_IMPR_NBR, P1130_IMPR_POB_NBR, P1130_IMPR_TELEX_NBR, P1130_IMPR_TEL_NBR, P1130_IMPR_TYPE_CD, P1130_IMPR_ZIP_CD, P1130_PORT_CD | P1130_BUS_ID, P1130_ID_MINS_COMM_CD, P1130_ARBC_IMPR_NAME, P1130_IMPR_NAME_STD, P1130_BUS_ID_EXPRD_DT, P1130_IMPR_TEL_NBR, P1130_IMPR_POB_NBR, P1130_IMPR_ZIP_CD, P1130_IMPR_FAX_NBR, P1130_IMPR_TELEX_NBR | - | IMPORTERS.BUS_ID.WHEN-VALIDATE-ITEM |
| - | - | - | - | - | 2 | FOS - Execute PL/SQL Code (change events ON) | `IMPR1130.READ_ONLY_FLAGS(P_ROW_ID => :P1130_ROW_ID, P_PRSNL_IMPR => :P1130_P_PRSNL_IMPR, P_IMPR_TYPE_CD => :P1130_IMPR_TYPE_CD, P_BUS_ID_TYPE_CD => :P1130_BUS_ID_TYPE_CD, P_COMM_RGSTRTN_TYPE => :P1130_COMM_RGSTRTN_TYPE, P_BUS_ID => :P1130_BUS_ID, P_BUS_ID_BRNCH => :P1130_BUS_ID_BRNCH, P_BUS_ID_EXPRD_DT => :P1130_BUS_ID_EXPRD_DT, P_CREATION_FLAG => :P1130_CREATION_FLAG, G_ALLOW_MCI => :G_ALLOW_MCI, P_COMM_RGSTRTN_TYPE_LOCKED => :P1130_COMM_RGSTRTN_TYPE_LOCKED, P_CTRY_CD_LOCKED => :P1130_CTRY_CD_LOCKED, P_ADD_CTRY_CD_LOCKED => :P1130_ADD_CTRY_CD_LOCKED, P_CITY_CODE_OF_ID_LOCKED => :P1130_CITY_CODE_OF_ID_LOCKED, P_BUS_ID_LOCKED => :P1130_BUS_ID_LOCKED, P_BUS_ID_BRNCH_LOCKED => :P1130_BUS_ID_BRNCH_LOCKED, P_BUS_ID_EXPRD_DT_LOCKED => :P1130_BUS_ID_EXPRD_DT_LOCKED, P_REGISTER_ITEMS_LOCKED => :P1130_REGISTER_ITEMS_LOCKED);` | P1130_BUS_ID, P1130_BUS_ID_BRNCH, P1130_BUS_ID_EXPRD_DT, P1130_BUS_ID_TYPE_CD, P1130_COMM_RGSTRTN_TYPE, P1130_CREATION_FLAG, P1130_IMPR_TYPE_CD, P1130_P_PRSNL_IMPR, P1130_ROW_ID | P1130_COMM_RGSTRTN_TYPE_LOCKED, P1130_CTRY_CD_LOCKED, P1130_ADD_CTRY_CD_LOCKED, P1130_CITY_CODE_OF_ID_LOCKED, P1130_BUS_ID_LOCKED, P1130_BUS_ID_BRNCH_LOCKED, P1130_BUS_ID_EXPRD_DT_LOCKED, P1130_REGISTER_ITEMS_LOCKED | last action: the read-only flags fire the DAs "<ITEM> READ ONLY" | - |
| BUS_ID_BRNCH WHEN-VALIDATE-ITEM | Change | Item P1130_BUS_ID_BRNCH | - | No | 1 | FOS - Execute PL/SQL Code | `IMPR1130.BUS_ID_BRNCH_VALIDATE_ITEM(P_PORT_CD => :P1130_PORT_CD, P_IMPR_NBR => :P1130_IMPR_NBR, P_IMPR_TYPE_CD => :P1130_IMPR_TYPE_CD, P_BUS_ID_TYPE_CD => :P1130_BUS_ID_TYPE_CD, P_COMM_RGSTRTN_TYPE => :P1130_COMM_RGSTRTN_TYPE, P_CTRY_CD => :P1130_CTRY_CD, P_BUS_ID => :P1130_BUS_ID, P_BUS_ID_BRNCH => :P1130_BUS_ID_BRNCH, P_ARBC_IMPR_NAME => :P1130_ARBC_IMPR_NAME, P_IMPR_NAME_STD => :P1130_IMPR_NAME_STD, P_BUS_ID_EXPRD_DT => :P1130_BUS_ID_EXPRD_DT, P_IMPR_TEL_NBR => :P1130_IMPR_TEL_NBR, P_IMPR_POB_NBR => :P1130_IMPR_POB_NBR, P_IMPR_ZIP_CD => :P1130_IMPR_ZIP_CD, P_IMPR_FAX_NBR => :P1130_IMPR_FAX_NBR, P_IMPR_TELEX_NBR => :P1130_IMPR_TELEX_NBR);` | P1130_ARBC_IMPR_NAME, P1130_BUS_ID, P1130_BUS_ID_BRNCH, P1130_BUS_ID_EXPRD_DT, P1130_BUS_ID_TYPE_CD, P1130_COMM_RGSTRTN_TYPE, P1130_CTRY_CD, P1130_IMPR_FAX_NBR, P1130_IMPR_NAME_STD, P1130_IMPR_NBR, P1130_IMPR_POB_NBR, P1130_IMPR_TELEX_NBR, P1130_IMPR_TEL_NBR, P1130_IMPR_TYPE_CD, P1130_IMPR_ZIP_CD, P1130_PORT_CD | P1130_BUS_ID_BRNCH, P1130_ARBC_IMPR_NAME, P1130_IMPR_NAME_STD, P1130_BUS_ID_EXPRD_DT, P1130_IMPR_TEL_NBR, P1130_IMPR_POB_NBR, P1130_IMPR_ZIP_CD, P1130_IMPR_FAX_NBR, P1130_IMPR_TELEX_NBR | - | IMPORTERS.BUS_ID_BRNCH.WHEN-VALIDATE-ITEM + KEY-NEXT-ITEM |
| - | - | - | - | - | 2 | FOS - Execute PL/SQL Code (change events ON) | `IMPR1130.READ_ONLY_FLAGS(P_ROW_ID => :P1130_ROW_ID, P_PRSNL_IMPR => :P1130_P_PRSNL_IMPR, P_IMPR_TYPE_CD => :P1130_IMPR_TYPE_CD, P_BUS_ID_TYPE_CD => :P1130_BUS_ID_TYPE_CD, P_COMM_RGSTRTN_TYPE => :P1130_COMM_RGSTRTN_TYPE, P_BUS_ID => :P1130_BUS_ID, P_BUS_ID_BRNCH => :P1130_BUS_ID_BRNCH, P_BUS_ID_EXPRD_DT => :P1130_BUS_ID_EXPRD_DT, P_CREATION_FLAG => :P1130_CREATION_FLAG, G_ALLOW_MCI => :G_ALLOW_MCI, P_COMM_RGSTRTN_TYPE_LOCKED => :P1130_COMM_RGSTRTN_TYPE_LOCKED, P_CTRY_CD_LOCKED => :P1130_CTRY_CD_LOCKED, P_ADD_CTRY_CD_LOCKED => :P1130_ADD_CTRY_CD_LOCKED, P_CITY_CODE_OF_ID_LOCKED => :P1130_CITY_CODE_OF_ID_LOCKED, P_BUS_ID_LOCKED => :P1130_BUS_ID_LOCKED, P_BUS_ID_BRNCH_LOCKED => :P1130_BUS_ID_BRNCH_LOCKED, P_BUS_ID_EXPRD_DT_LOCKED => :P1130_BUS_ID_EXPRD_DT_LOCKED, P_REGISTER_ITEMS_LOCKED => :P1130_REGISTER_ITEMS_LOCKED);` | P1130_BUS_ID, P1130_BUS_ID_BRNCH, P1130_BUS_ID_EXPRD_DT, P1130_BUS_ID_TYPE_CD, P1130_COMM_RGSTRTN_TYPE, P1130_CREATION_FLAG, P1130_IMPR_TYPE_CD, P1130_P_PRSNL_IMPR, P1130_ROW_ID | P1130_COMM_RGSTRTN_TYPE_LOCKED, P1130_CTRY_CD_LOCKED, P1130_ADD_CTRY_CD_LOCKED, P1130_CITY_CODE_OF_ID_LOCKED, P1130_BUS_ID_LOCKED, P1130_BUS_ID_BRNCH_LOCKED, P1130_BUS_ID_EXPRD_DT_LOCKED, P1130_REGISTER_ITEMS_LOCKED | last action: the read-only flags fire the DAs "<ITEM> READ ONLY" | - |
| ENG_IMPR_NAME WHEN-VALIDATE-ITEM | Change | Item P1130_ENG_IMPR_NAME | - | No | 1 | FOS - Execute PL/SQL Code | `IMPR1130.ENG_IMPR_NAME_VALIDATE_ITEM(P_ENG_IMPR_NAME => :P1130_ENG_IMPR_NAME);` | P1130_ENG_IMPR_NAME | P1130_ENG_IMPR_NAME | - | IMPORTERS.ENG_IMPR_NAME.WHEN-VALIDATE-ITEM |
| BUS_ID_ISSUE_DT WHEN-VALIDATE-ITEM | Change | Item P1130_BUS_ID_ISSUE_DT | - | No | 1 | FOS - Execute PL/SQL Code | `FORMS_APX.CHECK_ERROR(IMPR1130.BUS_ID_ISSUE_DT_VALIDATION(P_BUS_ID_ISSUE_DT => :P1130_BUS_ID_ISSUE_DT));` | P1130_BUS_ID_ISSUE_DT | - | - | IMPORTERS.BUS_ID_ISSUE_DT.WHEN-VALIDATE-ITEM |
| IMPR_NBR_PARENT WHEN-VALIDATE-ITEM | Change | Item P1130_IMPR_NBR_PARENT | - | No | 1 | FOS - Execute PL/SQL Code | `IMPR1130.IMPR_NBR_PARENT_VALIDATE_ITEM(P_IMPR_NBR_PARENT => :P1130_IMPR_NBR_PARENT, P_IMPR_NAME_PARENT => :P1130_IMPR_NAME_PARENT, P_CURR_PORT_CD => :P_CURR_PORT_CD);` | P1130_IMPR_NAME_PARENT, P1130_IMPR_NBR_PARENT | P1130_IMPR_NAME_PARENT | - | IMPORTERS.IMPR_NBR_PARENT.WHEN-VALIDATE-ITEM (+ KEY-LISTVAL) |
| ADD_CTRY_CD WHEN-VALIDATE-ITEM | Change | Item P1130_ADD_CTRY_CD | - | No | 1 | FOS - Execute PL/SQL Code | `IMPR1130.ADD_CTRY_CD_WHEN_VALIDATE_ITEM(P_ADD_CTRY_CD => :P1130_ADD_CTRY_CD, P_CITY_CODE => :P1130_CITY_CODE, P_ADD_CRTY_ARBC_NAME => :P1130_ADD_CRTY_ARBC_NAME, P_CITY_NAME => :P1130_CITY_NAME);` | P1130_ADD_CRTY_ARBC_NAME, P1130_ADD_CTRY_CD, P1130_CITY_CODE, P1130_CITY_NAME | P1130_ADD_CRTY_ARBC_NAME, P1130_CITY_NAME | - | IMPORTERS.ADD_CTRY_CD.WHEN-VALIDATE-ITEM (+ KEY-LISTVAL) |
| CITY_CODE WHEN-VALIDATE-ITEM | Change | Item P1130_CITY_CODE | - | No | 1 | FOS - Execute PL/SQL Code | `IMPR1130.CITY_CODE_WHEN_VALIDATE_ITEM(P_ADD_CTRY_CD => :P1130_ADD_CTRY_CD, P_CITY_CODE => :P1130_CITY_CODE, P_CITY_NAME => :P1130_CITY_NAME, P_ADD_CRTY_ARBC_NAME => :P1130_ADD_CRTY_ARBC_NAME);` | P1130_ADD_CRTY_ARBC_NAME, P1130_ADD_CTRY_CD, P1130_CITY_CODE, P1130_CITY_NAME | P1130_CITY_NAME, P1130_ADD_CRTY_ARBC_NAME | - | IMPORTERS.CITY_CODE.WHEN-VALIDATE-ITEM (+ KEY-LISTVAL) |
| IMPR_TEL_NBR WHEN-VALIDATE-ITEM | Change | Item P1130_IMPR_TEL_NBR | - | No | 1 | FOS - Execute PL/SQL Code | `FORMS_APX.CHECK_ERROR(IMPR1130.IMPR_TEL_NBR_VALIDATION(P_IMPR_TEL_NBR => :P1130_IMPR_TEL_NBR));` | P1130_IMPR_TEL_NBR | - | - | IMPORTERS.IMPR_TEL_NBR.WHEN-VALIDATE-ITEM |
| EMAIL WHEN-VALIDATE-ITEM | Change | Item P1130_EMAIL | - | No | 1 | FOS - Execute PL/SQL Code | `FORMS_APX.CHECK_ERROR(IMPR1130.EMAIL_VALIDATION(P_EMAIL => :P1130_EMAIL));` | P1130_EMAIL | - | - | IMPORTERS.EMAIL.WHEN-VALIDATE-ITEM |
| MOBILE_NO WHEN-VALIDATE-ITEM | Change | Item P1130_MOBILE_NO | - | No | 1 | FOS - Execute PL/SQL Code | `FORMS_APX.CHECK_ERROR(IMPR1130.MOBILE_NO_VALIDATION(P_MOBILE_NO => :P1130_MOBILE_NO));` | P1130_MOBILE_NO | - | - | IMPORTERS.MOBILE_NO.WHEN-VALIDATE-ITEM |
| COMM_RGSTRTN_TYPE READ ONLY | Change | Item P1130_COMM_RGSTRTN_TYPE_LOCKED | Item P1130_COMM_RGSTRTN_TYPE_LOCKED = Y | Yes | 1 | Disable | items P1130_COMM_RGSTRTN_TYPE | - | - | True action | INTRFACE.Make_Field_Entrable (COMM_RGSTRTN_TYPE): READ_ONLY_FLAGS |
| - | - | - | - | - | 2 | Enable | items P1130_COMM_RGSTRTN_TYPE | - | - | False action | - |
| CTRY_CD READ ONLY | Change | Item P1130_CTRY_CD_LOCKED | Item P1130_CTRY_CD_LOCKED = Y | Yes | 1 | Disable | items P1130_CTRY_CD | - | - | True action | INTRFACE.Make_Field_Entrable (CTRY_CD): READ_ONLY_FLAGS |
| - | - | - | - | - | 2 | Enable | items P1130_CTRY_CD | - | - | False action | - |
| ADD_CTRY_CD READ ONLY | Change | Item P1130_ADD_CTRY_CD_LOCKED | Item P1130_ADD_CTRY_CD_LOCKED = Y | Yes | 1 | Disable | items P1130_ADD_CTRY_CD | - | - | True action | INTRFACE.Make_Field_Entrable (ADD_CTRY_CD): READ_ONLY_FLAGS |
| - | - | - | - | - | 2 | Enable | items P1130_ADD_CTRY_CD | - | - | False action | - |
| CITY_CODE_OF_ID READ ONLY | Change | Item P1130_CITY_CODE_OF_ID_LOCKED | Item P1130_CITY_CODE_OF_ID_LOCKED = Y | Yes | 1 | Disable | items P1130_CITY_CODE_OF_ID | - | - | True action | INTRFACE.Make_Field_Entrable (CITY_CODE_OF_ID): READ_ONLY_FLAGS |
| - | - | - | - | - | 2 | Enable | items P1130_CITY_CODE_OF_ID | - | - | False action | - |
| BUS_ID READ ONLY | Change | Item P1130_BUS_ID_LOCKED | Item P1130_BUS_ID_LOCKED = Y | Yes | 1 | Disable | items P1130_BUS_ID | - | - | True action | INTRFACE.Make_Field_Entrable (BUS_ID): READ_ONLY_FLAGS |
| - | - | - | - | - | 2 | Enable | items P1130_BUS_ID | - | - | False action | - |
| BUS_ID_BRNCH READ ONLY | Change | Item P1130_BUS_ID_BRNCH_LOCKED | Item P1130_BUS_ID_BRNCH_LOCKED = Y | Yes | 1 | Disable | items P1130_BUS_ID_BRNCH | - | - | True action | INTRFACE.Make_Field_Entrable (BUS_ID_BRNCH): READ_ONLY_FLAGS |
| - | - | - | - | - | 2 | Enable | items P1130_BUS_ID_BRNCH | - | - | False action | - |
| BUS_ID_EXPRD_DT READ ONLY | Change | Item P1130_BUS_ID_EXPRD_DT_LOCKED | Item P1130_BUS_ID_EXPRD_DT_LOCKED = Y | Yes | 1 | Disable | items P1130_BUS_ID_EXPRD_DT | - | - | True action | INTRFACE.Make_Field_Entrable (BUS_ID_EXPRD_DT): READ_ONLY_FLAGS |
| - | - | - | - | - | 2 | Enable | items P1130_BUS_ID_EXPRD_DT | - | - | False action | - |
| REGISTER_ITEMS READ ONLY | Change | Item P1130_REGISTER_ITEMS_LOCKED | Item P1130_REGISTER_ITEMS_LOCKED = Y | Yes | 1 | Disable | items P1130_IMPR_POB_NBR, P1130_IMPR_ZIP_CD, P1130_IMPR_FAX_NBR, P1130_IMPR_TELEX_NBR | - | - | True action | INTRFACE.Make_Field_Entrable (IMPR_POB_NBR, IMPR_ZIP_CD, IMPR_FAX_NBR, IMPR_TELEX_NBR): READ_ONLY_FLAGS |
| - | - | - | - | - | 2 | Enable | items P1130_IMPR_POB_NBR, P1130_IMPR_ZIP_CD, P1130_IMPR_FAX_NBR, P1130_IMPR_TELEX_NBR | - | - | False action | - |
| SUPPORT_ENTRY WHEN-NEW-FORM-INSTANCE | Page Load | - | JavaScript expression: $v('P1130_SUPPORT_ENTRY_OPEN') === 'Y' | No | 1 | FOS - Execute PL/SQL Code | `SUPPORT_ENTRY.OPEN_DIALOG(P_MODE => 0, P_CURR_PORT_CD => :P1130_PORT_CD, P_SUPPORT_URL => :P1130_SUPPORT_URL);` | P1130_PORT_CD | P1130_SUPPORT_URL | CALL_FORM(SUPPORT_ENTRY.FMX) with P_MODE 0 and P_CURR_PORT_CD = :IMPORTERS.PORT_CD | FORM.WHEN-NEW-FORM-INSTANCE CALL_FORM(SUPPORT_ENTRY) |
| - | - | - | - | - | 2 | Execute JavaScript Code | `apex.navigation.redirect($v('P1130_SUPPORT_URL'));` | - | - | open the SUPPORT_ENTRY dialog page 9001 (URL from SUPPORT_ENTRY.OPEN_DIALOG) | - |
| SUPPORT_ENTRY WHEN-BUTTON-PRESSED | Click | Button SUPPORT_ENTRY | - | No | 1 | FOS - Execute PL/SQL Code | `SUPPORT_ENTRY.OPEN_DIALOG(P_MODE => CASE WHEN :G_LETTER_NBR IS NULL THEN 0 ELSE 1 END, P_CURR_PORT_CD => :P1130_PORT_CD, P_SUPPORT_URL => :P1130_SUPPORT_URL);` | P1130_PORT_CD | P1130_SUPPORT_URL | edit mode on demand (D1) when a letter exists (Forms OPEN_FORM(SUPPORT_ENTRY.FMX), default P_MODE 1), else a new letter | FORM.WHEN-NEW-FORM-INSTANCE OPEN_FORM(SUPPORT_ENTRY) (edit mode, modeless window in Forms) |
| - | - | - | - | - | 2 | Execute JavaScript Code | `apex.navigation.redirect($v('P1130_SUPPORT_URL'));` | - | - | open the SUPPORT_ENTRY dialog page 9001 (URL from SUPPORT_ENTRY.OPEN_DIALOG) | - |
| SUPPORT_ENTRY DIALOG CLOSED | Dialog Closed | JavaScript Expression: document | dialog page 9001 | No | 1 | FOS - Execute PL/SQL Code | `:P1130_P_LETTER_NBR := :G_LETTER_NBR;` | - | P1130_P_LETTER_NBR | :PARAMETER.LETTER_NBR := :GLOBAL.LETTER_NBR | FORM.WHEN-NEW-FORM-INSTANCE after CALL_FORM(SUPPORT_ENTRY) |
| IMPR_MCI_SERVICE EXECUTE-FUNCTION | Custom: IMPR_MCI_SERVICE | JavaScript Expression: document | - | No | 1 | FOS - Execute PL/SQL Code | `:P1130_CONFIRM_TEXT := IMPR1130.UPDATE_IMPORTER_CONFIRM_TEXT(P_PORT_CD => :P1130_PORT_CD, P_IMPR_NBR => :P1130_IMPR_NBR, P_IMPR_TYPE_CD => :P1130_IMPR_TYPE_CD, P_BUS_ID_TYPE_CD => :P1130_BUS_ID_TYPE_CD, P_BUS_ID => :P1130_BUS_ID, P_BUS_ID_BRNCH => :P1130_BUS_ID_BRNCH);` | P1130_BUS_ID, P1130_BUS_ID_BRNCH, P1130_BUS_ID_TYPE_CD, P1130_IMPR_NBR, P1130_IMPR_TYPE_CD, P1130_PORT_CD | P1130_CONFIRM_TEXT | - | PU EXEC_FUNS / UPDATE_IMPORTER (function IMPR_MCI_SERVICE, enabled by ADJ_FUNS) |
| - | - | - | - | - | 2 | Execute JavaScript Code | `var t = $v('P1130_CONFIRM_TEXT'), go = function (a) { $s('P1130_ANSWER', a); apex.event.trigger(document, 'impr1130-update-importer'); }; if (t) { apex.message.confirm(t, function (ok) { go(ok ? '1' : '2'); }); } else { go('2'); }` | - | - | STR.DISPALERT(V_MSG, CONFIRM) of UPDATE_IMPORTER; no saved importer: only the re-query | - |
| UPDATE_IMPORTER | Custom: impr1130-update-importer | JavaScript Expression: document | - | No | 1 | FOS - Execute PL/SQL Code | `IMPR1130.EXEC_FUNS(P_FUNCTION_CODE => 'IMPR_MCI_SERVICE', P_PORT_CD => :P1130_PORT_CD, P_IMPR_NBR => :P1130_IMPR_NBR, P_ANSWER => :P1130_ANSWER, G_ALLOW_MCI => :G_ALLOW_MCI, G_ALLOW_MOI => :G_ALLOW_MOI);` | P1130_ANSWER, P1130_IMPR_NBR, P1130_PORT_CD | - | - | PU UPDATE_IMPORTER (LIB_USR.IMPR_UTILITIES.UPDATE_IMPORTERS_NAMES, then re-query) |
| - | - | - | - | - | 2 | Submit Page | request EXECUTE_QUERY | - | - | :GLOBAL.EXEC_QUERY_NOW := 1 -> WHEN-NEW-ITEM-INSTANCE EXECUTE_QUERY: the record is read again | - |

JavaScript actions: 4, each 1–2 lines (two confirms, two `apex.navigation.redirect` to page 9001).

## 11. Alerts and messages

| Forms | APEX |
|---|---|
| `STR.DispAlert` / `DispArbMsg` ERROR, INFORMATION + RAISE | error text of the validation / FOS (`FORMS_APX.CHECK_ERROR`, `FORM_TRIGGER_FAILURE`) |
| `STR.DispAlert` / `DispArbMsg` without RAISE, Designer warnings | `FORMS_APX.MESSAGE` (page message) |
| CONFIRM 9-120 (CITY_CODE_OF_ID), CONFIRM of UPDATE_IMPORTER | §0 #5 |
| KEY-DELREC 'هل أنت متأكد من عملية الحذف' | confirm of the page 0 DELETE button |
| ON-ERROR constraint messages, delete check messages | `IMPR1130.KEY_DELREC` / validations (package `importers_on_error`) |

## 12. Branches and navigation

| Branch | Condition | Target |
|---|---|---|
| `EXECUTE-QUERY` (seq 10) | request EXECUTE_QUERY | page 1130, clear cache 1130, `P0_PAGE_PK` kept (set by process EXECUTE-QUERY) |
| `IMPR1130 - stay in the form` (seq 20) | – | page 1130 with the success message (Forms stays on the record after COMMIT) |
| search grid link | – | page 1130, `P0_PAGE_PK` = URL-safe ROWID (`P0_PAGE_PK_CHECK` translates it back) |
| page 9001 | DAs §10 | `SUPPORT_ENTRY.OPEN_DIALOG` URL; its own `G_LAST_PAGE KEEP` returns to 1130 |

## 13. Shared components

### 13.1 Reused (do not create)
f345: theme 42, templates, page 0 (toolbar, FUNCS, `NUMBER ONLY`), application items `SSO_APP_USER`, `P_CURR_PORT_CD`,
`P_GLOBAL_V_WS_ID`, `P_CLASS_CD`, `V_USR_TYPE`, `G_LAST_PAGE`. IMPR1110 export: page group `IMPR`, the items of §0 #7,
Application Setting `HIJRI_DATE_FORMAT`, LOVs of §6 marked reused. SUPPORT_ENTRY export: page 9001, `G_SUPPORT_ENTRY_CALLER`.

### 13.2 New
LOVs `LOV_IMPR1130_IMPR_TYPE_BUS_ID`, `LOV_IMPR1130_COUNTRIES_GULF`, `LOV_IMPR1130_CITIES_OF_ID`, `LOV_IMPR1130_CITIES`
(ids base 9130). No new application item, message or authorization scheme (CLAUDE.md §8).

## 14. Traceability matrix (every object of the XML)

596 rows: DROPPED 363, MAPPED 226, TODO 7.

| Forms type | Forms object | APEX type | APEX component | Page | Package member | Status | Notes |
|---|---|---|---|---|---|---|---|
| BLOCK | TITLE | REGION | - | - | - | DROPPED | OLB frame block -> f345 page template / page 0 toolbar / FUNCS |
| ITEM | TITLE.CGSO$CHECK_BOX_U | ITEM | - | - | - | DROPPED | OLB block TITLE |
| ITEM | TITLE.CGSO$CHAR_ARB_ED | ITEM | - | - | - | DROPPED | OLB block TITLE |
| ITEM | TITLE.CGSO$CHAR_ARB_DO_MLINE | ITEM | - | - | - | DROPPED | OLB block TITLE |
| ITEM | TITLE.CGSO$CHAR_ARB_ORA_LOV | ITEM | - | - | - | DROPPED | OLB block TITLE |
| ITEM | TITLE.CGSO$CHAR_ARB_DO_ENB_Y | ITEM | - | - | - | DROPPED | OLB block TITLE |
| ITEM | TITLE.CGSO$CHAR_ARB_MLINE | ITEM | - | - | - | DROPPED | OLB block TITLE |
| ITEM | TITLE.CGSO$CHAR_ARB | ITEM | - | - | - | DROPPED | OLB block TITLE |
| ITEM | TITLE.CGSO$CHAR_ARB_DO | ITEM | - | - | - | DROPPED | OLB block TITLE |
| ITEM | TITLE.SCREEN_NAME | ITEM | - | - | - | DROPPED | OLB block TITLE |
| ITEM | TITLE.USER_NAME | ITEM | - | - | - | DROPPED | OLB block TITLE |
| ITEM | TITLE.SYSTEM_DATE | ITEM | - | - | - | DROPPED | OLB block TITLE |
| ITEM | TITLE.VERSION | ITEM | - | - | - | DROPPED | OLB block TITLE |
| BLOCK | EDI_MSG | REGION | - | - | - | DROPPED | OLB frame block -> f345 page template / page 0 toolbar / FUNCS |
| ITEM | EDI_MSG.EDI_MSG_TXT | ITEM | - | - | - | DROPPED | OLB block EDI_MSG |
| ITEM | EDI_MSG.EDI_MSG_LOVE_BUT | ITEM | - | - | - | DROPPED | OLB block EDI_MSG |
| BLOCK | LSIDE | REGION | - | - | - | DROPPED | OLB frame block -> f345 page template / page 0 toolbar / FUNCS |
| ITEM | LSIDE.FN1 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| ITEM | LSIDE.FN50 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| ITEM | LSIDE.FN2 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| ITEM | LSIDE.FN49 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| ITEM | LSIDE.FN3 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| ITEM | LSIDE.FN48 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| ITEM | LSIDE.FN4 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| ITEM | LSIDE.FN47 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| ITEM | LSIDE.FN5 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| ITEM | LSIDE.FN46 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| ITEM | LSIDE.FN6 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| ITEM | LSIDE.FN45 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| ITEM | LSIDE.FN7 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| ITEM | LSIDE.FN44 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| ITEM | LSIDE.FN8 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| ITEM | LSIDE.FN43 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| ITEM | LSIDE.FN9 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| ITEM | LSIDE.FN42 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| ITEM | LSIDE.FN10 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| ITEM | LSIDE.FN41 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| ITEM | LSIDE.FN11 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| ITEM | LSIDE.FN40 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| ITEM | LSIDE.FN12 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| ITEM | LSIDE.FN39 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| ITEM | LSIDE.FN13 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| ITEM | LSIDE.FN38 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| ITEM | LSIDE.FN14 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| ITEM | LSIDE.FN37 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| ITEM | LSIDE.FN15 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| ITEM | LSIDE.FN36 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| ITEM | LSIDE.FN16 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| ITEM | LSIDE.FN17 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| ITEM | LSIDE.FN34 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| ITEM | LSIDE.FN35 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| ITEM | LSIDE.FN18 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| ITEM | LSIDE.FN33 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| ITEM | LSIDE.FN19 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| ITEM | LSIDE.FN32 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| ITEM | LSIDE.FN20 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| ITEM | LSIDE.FN31 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| ITEM | LSIDE.FN21 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| ITEM | LSIDE.FN30 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| ITEM | LSIDE.FN22 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| ITEM | LSIDE.FN29 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| ITEM | LSIDE.FN23 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| ITEM | LSIDE.FN28 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| ITEM | LSIDE.FN24 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| ITEM | LSIDE.FN27 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| ITEM | LSIDE.FN25 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| ITEM | LSIDE.FN26 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| BLOCK | TOOLBAR | REGION | - | - | - | DROPPED | OLB frame block -> f345 page template / page 0 toolbar / FUNCS |
| ITEM | TOOLBAR.DUMMY | ITEM | - | - | - | DROPPED | OLB block TOOLBAR |
| ITEM | TOOLBAR.SAVE | ITEM | - | - | - | DROPPED | OLB block TOOLBAR |
| ITEM | TOOLBAR.CLEAR_ALL | ITEM | - | - | - | DROPPED | OLB block TOOLBAR |
| ITEM | TOOLBAR.EXIT | ITEM | - | - | - | DROPPED | OLB block TOOLBAR |
| ITEM | TOOLBAR.EXIT1 | ITEM | - | - | - | DROPPED | OLB block TOOLBAR |
| ITEM | TOOLBAR.ENTER | ITEM | - | - | - | DROPPED | OLB block TOOLBAR |
| ITEM | TOOLBAR.EXECUTE | ITEM | - | - | - | DROPPED | OLB block TOOLBAR |
| ITEM | TOOLBAR.REMOVE | ITEM | - | - | - | DROPPED | OLB block TOOLBAR |
| ITEM | TOOLBAR.LIST_VALUE | ITEM | - | - | - | DROPPED | OLB block TOOLBAR |
| ITEM | TOOLBAR.HELP | ITEM | - | - | - | DROPPED | OLB block TOOLBAR |
| ITEM | TOOLBAR.LAST_REC | ITEM | - | - | - | DROPPED | OLB block TOOLBAR |
| ITEM | TOOLBAR.RE_ENTER_QUERY | ITEM | - | - | - | DROPPED | OLB block TOOLBAR |
| ITEM | TOOLBAR.FIRST_REC | ITEM | - | - | - | DROPPED | OLB block TOOLBAR |
| ITEM | TOOLBAR.PAGE_UP | ITEM | - | - | - | DROPPED | OLB block TOOLBAR |
| ITEM | TOOLBAR.PAGE_DOWN | ITEM | - | - | - | DROPPED | OLB block TOOLBAR |
| ITEM | TOOLBAR.FUN_BUT | ITEM | - | - | - | DROPPED | OLB block TOOLBAR |
| BLOCK | IMPORTERS | REGION | IMPORTERS | 1130 | - | MAPPED | Form region on IMPORTERS (ROWID), WHERE PORT_CD = :P_CURR_PORT_CD |
| ITEM | IMPORTERS.L_CT_CITY_STATUS2 | ITEM | - | - | - | DROPPED | LOV button -> the Popup LOV / Select List of the item |
| ITEM | IMPORTERS.L_CT_CITY_STATUS | ITEM | - | - | - | DROPPED | non-displayed lookup item filled by the Designer FK lookups, read by no code |
| ITEM | IMPORTERS.PORT_CD | ITEM | P1130_PORT_CD | 1130 | - | MAPPED | Popup LOV (display = return value, manual entry) |
| ITEM | IMPORTERS.PORT_CD2 | ITEM | - | - | - | DROPPED | LOV button -> the Popup LOV / Select List of the item |
| ITEM | IMPORTERS.PORT_NAME | ITEM | P1130_PORT_NAME | 1130 | - | MAPPED | Display Only (Send On Page Submit = No) |
| ITEM | IMPORTERS.HQ_IMPR_NBR | ITEM | P1130_HQ_IMPR_NBR | 1130 | - | MAPPED | Display Only (Send On Page Submit = No) |
| ITEM | IMPORTERS.IMPR_NBR | ITEM | P1130_IMPR_NBR | 1130 | - | MAPPED | Number Field |
| ITEM | IMPORTERS.SUSPN_STATUS | ITEM | P1130_SUSPN_STATUS | 1130 | - | MAPPED | Display Only (Send On Page Submit = No) |
| ITEM | IMPORTERS.STATUS_DESC | ITEM | P1130_STATUS_DESC | 1130 | - | MAPPED | Display Only (Send On Page Submit = No) |
| ITEM | IMPORTERS.BUS_ID_STATUS | ITEM | P1130_BUS_ID_STATUS | 1130 | - | MAPPED | Display Only, CSS u-hidden (Send On Page Submit = No) |
| ITEM | IMPORTERS.IMPR_TYPE_CD | ITEM | P1130_IMPR_TYPE_CD | 1130 | - | MAPPED | Popup LOV (display = return value, manual entry) |
| ITEM | IMPORTERS.IMPR_TYPE_CD2 | ITEM | - | - | - | DROPPED | LOV button -> the Popup LOV / Select List of the item |
| ITEM | IMPORTERS.IMPR_TYPE_NAME | ITEM | P1130_IMPR_TYPE_NAME | 1130 | - | MAPPED | Display Only (Send On Page Submit = No) |
| ITEM | IMPORTERS.BUS_ID_EXPRD_DT | ITEM | P1130_BUS_ID_EXPRD_DT | 1130 | - | MAPPED | Text Field, CSS class `hijri-date-default` (f345 Hijri picker) |
| ITEM | IMPORTERS.BUS_ID_TYPE_CD | ITEM | P1130_BUS_ID_TYPE_CD | 1130 | - | MAPPED | Select List |
| ITEM | IMPORTERS.BUTT | ITEM | - | - | - | DROPPED | LOV button -> the Popup LOV / Select List of the item |
| ITEM | IMPORTERS.BUS_ID_TYPE_NAME | ITEM | P1130_BUS_ID_TYPE_NAME | 1130 | - | MAPPED | Display Only (Send On Page Submit = No) |
| ITEM | IMPORTERS.COMM_RGSTRTN_TYPE | ITEM | P1130_COMM_RGSTRTN_TYPE | 1130 | - | MAPPED | Select List |
| ITEM | IMPORTERS.CTRY_CD | ITEM | P1130_CTRY_CD | 1130 | - | MAPPED | Popup LOV (display = return value, manual entry) |
| ITEM | IMPORTERS.CTRY_CD2 | ITEM | - | - | - | DROPPED | LOV button -> the Popup LOV / Select List of the item |
| ITEM | IMPORTERS.CRTY_ARBC_NAME | ITEM | P1130_CRTY_ARBC_NAME | 1130 | - | MAPPED | Display Only (Send On Page Submit = No) |
| ITEM | IMPORTERS.CITY_CODE_OF_ID | ITEM | P1130_CITY_CODE_OF_ID | 1130 | - | MAPPED | Popup LOV (display = return value, manual entry) |
| ITEM | IMPORTERS.CITY_CODE_OF_ID2 | ITEM | - | - | - | DROPPED | LOV button -> the Popup LOV / Select List of the item |
| ITEM | IMPORTERS.ID_CITY_NAME | ITEM | P1130_ID_CITY_NAME | 1130 | - | MAPPED | Display Only (Send On Page Submit = No) |
| ITEM | IMPORTERS.IMPR_EXPR_TYPE | ITEM | P1130_IMPR_EXPR_TYPE | 1130 | - | MAPPED | Select List |
| ITEM | IMPORTERS.NATIONAL_NBR | ITEM | P1130_NATIONAL_NBR | 1130 | - | MAPPED | Text Field |
| ITEM | IMPORTERS.BUS_ID | ITEM | P1130_BUS_ID | 1130 | - | MAPPED | Text Field |
| ITEM | IMPORTERS.BUS_ID_BRNCH | ITEM | P1130_BUS_ID_BRNCH | 1130 | - | MAPPED | Text Field |
| ITEM | IMPORTERS.CTRY_CTRY_STATUS | ITEM | - | - | - | DROPPED | non-displayed lookup item filled by the Designer FK lookups, read by no code |
| ITEM | IMPORTERS.ID_MINS_COMM_CD | ITEM | P1130_ID_MINS_COMM_CD | 1130 | - | MAPPED | Display Only, CSS u-hidden (Send On Page Submit = No) |
| ITEM | IMPORTERS.ITIDT_NOTE | ITEM | - | - | - | DROPPED | non-displayed lookup item filled by the Designer FK lookups, read by no code |
| ITEM | IMPORTERS.ARBC_IMPR_NAME | ITEM | P1130_ARBC_IMPR_NAME | 1130 | - | MAPPED | Text Field |
| ITEM | IMPORTERS.IMPR_NAME_STD | ITEM | P1130_IMPR_NAME_STD | 1130 | - | MAPPED | Display Only, CSS u-hidden (Send On Page Submit = No) |
| ITEM | IMPORTERS.LST_TRAN_DT | ITEM | P1130_LST_TRAN_DT | 1130 | - | MAPPED | Display Only, CSS u-hidden (Send On Page Submit = No) |
| ITEM | IMPORTERS.IMPD_STMT_NBR | ITEM | P1130_IMPD_STMT_NBR | 1130 | - | MAPPED | Display Only, CSS u-hidden (Send On Page Submit = No) |
| ITEM | IMPORTERS.IMPR_DATA_SRCE | ITEM | P1130_IMPR_DATA_SRCE | 1130 | - | MAPPED | Display Only, CSS u-hidden (Send On Page Submit = No) |
| ITEM | IMPORTERS.STATUS | ITEM | - | - | - | DROPPED | non-displayed lookup item filled by the Designer FK lookups, read by no code |
| ITEM | IMPORTERS.ENG_IMPR_NAME | ITEM | P1130_ENG_IMPR_NAME | 1130 | - | MAPPED | Text Field (dir=ltr) |
| ITEM | IMPORTERS.IMPR_CNTCT_NAME | ITEM | P1130_IMPR_CNTCT_NAME | 1130 | - | MAPPED | Text Field |
| ITEM | IMPORTERS.IMPR_ADDRESS | ITEM | P1130_IMPR_ADDRESS | 1130 | - | MAPPED | Text Field |
| ITEM | IMPORTERS.BUS_ID_ISSUE_DT | ITEM | P1130_BUS_ID_ISSUE_DT | 1130 | - | MAPPED | Text Field, CSS class `hijri-date-default` (f345 Hijri picker) |
| ITEM | IMPORTERS.IMPR_NBR_PARENT | ITEM | P1130_IMPR_NBR_PARENT | 1130 | - | MAPPED | Popup LOV (display = return value, manual entry) |
| ITEM | IMPORTERS.IMPR_NBR_PARENT2 | ITEM | - | - | - | DROPPED | LOV button -> the Popup LOV / Select List of the item |
| ITEM | IMPORTERS.IMPR_NAME_PARENT | ITEM | P1130_IMPR_NAME_PARENT | 1130 | - | MAPPED | Display Only (Send On Page Submit = No) |
| ITEM | IMPORTERS.ADD_CTRY_CD | ITEM | P1130_ADD_CTRY_CD | 1130 | - | MAPPED | Popup LOV (display = return value, manual entry) |
| ITEM | IMPORTERS.ADD_CTRY_CD2 | ITEM | - | - | - | DROPPED | LOV button -> the Popup LOV / Select List of the item |
| ITEM | IMPORTERS.ADD_CRTY_ARBC_NAME | ITEM | P1130_ADD_CRTY_ARBC_NAME | 1130 | - | MAPPED | Display Only (Send On Page Submit = No) |
| ITEM | IMPORTERS.CITY_CODE | ITEM | P1130_CITY_CODE | 1130 | - | MAPPED | Popup LOV (display = return value, manual entry) |
| ITEM | IMPORTERS.CITY_CODE2 | ITEM | - | - | - | DROPPED | LOV button -> the Popup LOV / Select List of the item |
| ITEM | IMPORTERS.CITY_NAME | ITEM | P1130_CITY_NAME | 1130 | - | MAPPED | Display Only (Send On Page Submit = No) |
| ITEM | IMPORTERS.IMPR_POB_NBR | ITEM | P1130_IMPR_POB_NBR | 1130 | - | MAPPED | Number Field |
| ITEM | IMPORTERS.IMPR_ZIP_CD | ITEM | P1130_IMPR_ZIP_CD | 1130 | - | MAPPED | Number Field |
| ITEM | IMPORTERS.IMPR_TEL_NBR | ITEM | P1130_IMPR_TEL_NBR | 1130 | - | MAPPED | Text Field |
| ITEM | IMPORTERS.IMPR_FAX_NBR | ITEM | P1130_IMPR_FAX_NBR | 1130 | - | MAPPED | Text Field |
| ITEM | IMPORTERS.IMPR_TELEX_NBR | ITEM | P1130_IMPR_TELEX_NBR | 1130 | - | MAPPED | Text Field |
| ITEM | IMPORTERS.EMAIL | ITEM | P1130_EMAIL | 1130 | - | MAPPED | Text Field (subtype E-Mail, dir=ltr) |
| ITEM | IMPORTERS.MOBILE_NO | ITEM | P1130_MOBILE_NO | 1130 | - | MAPPED | Text Field (subtype Phone) |
| ITEM | IMPORTERS.CAR_AGENT_FLAG | ITEM | P1130_CAR_AGENT_FLAG | 1130 | - | MAPPED | Select List |
| ITEM | IMPORTERS.EXPRESS_POST | ITEM | P1130_EXPRESS_POST | 1130 | - | MAPPED | Select List |
| ITEM | IMPORTERS.CTRY_CD_OF_ID | ITEM | P1130_CTRY_CD_OF_ID | 1130 | - | MAPPED | Display Only, CSS u-hidden (Send On Page Submit = No) |
| ITEM | IMPORTERS.ID_NBR | ITEM | P1130_ID_NBR | 1130 | - | MAPPED | Display Only, CSS u-hidden (Send On Page Submit = No) |
| ITEM | IMPORTERS.CUSTOMS_ENTERED | ITEM | P1130_CUSTOMS_ENTERED | 1130 | - | MAPPED | Display Only, CSS u-hidden (Send On Page Submit = No) |
| ITEM | IMPORTERS.CUSTOMS_ENTERED2 | ITEM | - | - | - | DROPPED | LOV button -> the Popup LOV / Select List of the item |
| ITEM | IMPORTERS.EXPD_STMT_NBR | ITEM | P1130_EXPD_STMT_NBR | 1130 | - | MAPPED | Display Only, CSS u-hidden (Send On Page Submit = No) |
| ITEM | IMPORTERS.WVR_ENTRY_NBR | ITEM | P1130_WVR_ENTRY_NBR | 1130 | - | MAPPED | Display Only, CSS u-hidden (Send On Page Submit = No) |
| ITEM | IMPORTERS.ACTIVITY | ITEM | P1130_ACTIVITY | 1130 | - | MAPPED | Display Only, CSS u-hidden (Send On Page Submit = No) |
| ITEM | IMPORTERS.BANK_IBAN | ITEM | P1130_BANK_IBAN | 1130 | - | MAPPED | Display Only, CSS u-hidden (Send On Page Submit = No) |
| ITEM | IMPORTERS.CREATION_FLAG | ITEM | P1130_CREATION_FLAG | 1130 | - | MAPPED | Display Only, CSS u-hidden (Send On Page Submit = No) |
| ITEM | IMPORTERS.CREATION_FLAG2 | ITEM | - | - | - | DROPPED | LOV button -> the Popup LOV / Select List of the item |
| ITEM | IMPORTERS.BIRTH_DT | ITEM | P1130_BIRTH_DT | 1130 | - | MAPPED | Display Only, CSS u-hidden (Send On Page Submit = No) |
| TRIGGER | FORM.KEY-CLRBLK | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| TRIGGER | FORM.KEY-CLRFRM | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| TRIGGER | FORM.KEY-DELREC | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| TRIGGER | FORM.KEY-DOWN | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| TRIGGER | FORM.KEY-DUPREC | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| TRIGGER | FORM.KEY-EDIT | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| TRIGGER | FORM.KEY-ENTQRY | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| TRIGGER | FORM.KEY-EXEQRY | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| TRIGGER | FORM.KEY-EXIT | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| TRIGGER | FORM.KEY-F5 | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| TRIGGER | FORM.KEY-F9 | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| TRIGGER | FORM.KEY-HELP | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| TRIGGER | FORM.KEY-NXTREC | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| TRIGGER | FORM.KEY-PRINT | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| TRIGGER | FORM.KEY-PRVREC | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| TRIGGER | FORM.KEY-SCRDOWN | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| TRIGGER | FORM.KEY-SCRUP | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| TRIGGER | FORM.KEY-UP | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| TRIGGER | FORM.ON-ERROR | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| TRIGGER | FORM.ON-MESSAGE | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| TRIGGER | FORM.PRE-FORM | - | - | - | - | DROPPED | NIB.PRE_FORM, date-format ALTER SESSION, help path |
| TRIGGER | FORM.WHEN-MOUSE-DOWN | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| TRIGGER | FORM.WHEN-NEW-FORM-INSTANCE | PACKAGE | WHEN_NEW_FORM_INSTANCE | 1130 | IMPR1130.WHEN_NEW_FORM_INSTANCE | MAPPED | settings ALLOW_MCI / ALLOW_MOI, country 100 defaults; SUPPORT_ENTRY -> page 9001 DAs; rest = f345 frame |
| TRIGGER | FORM.WHEN-TIMER-EXPIRED | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| TRIGGER | FORM.WHEN-WINDOW-ACTIVATED | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| TRIGGER | IMPORTERS.ADD_CRTY_ARBC_NAME.KEY-LISTVAL | - | - | - | - | DROPPED | Designer "may the LOV be shown" check of an item without an LOV call (APEX: no LOV, or the LOV of the item) |
| TRIGGER | IMPORTERS.ADD_CTRY_CD.KEY-LISTVAL | APEX | Popup LOV LOV_COUNTRIES + ADD_CTRY_CD_WHEN_VALIDATE_ITEM | 1130 | IMPR1130.ADD_CTRY_CD_WHEN_VALIDATE_ITEM | MAPPED | CALL_FORM LOV_COUNTRIES |
| TRIGGER | IMPORTERS.ADD_CTRY_CD.WHEN-VALIDATE-ITEM | PACKAGE | ADD_CTRY_CD_WHEN_VALIDATE_ITEM | 1130 | IMPR1130.ADD_CTRY_CD_WHEN_VALIDATE_ITEM | MAPPED | country name (LOV return), city lookup warning |
| TRIGGER | IMPORTERS.ADD_CTRY_CD2.WHEN-BUTTON-PRESSED | APEX | Popup LOV button | 1130 | - | MAPPED | GO_ITEM + DO_KEY |
| TRIGGER | IMPORTERS.ARBC_IMPR_NAME.KEY-LISTVAL | - | - | - | - | DROPPED | Designer "may the LOV be shown" check of an item without an LOV call (APEX: no LOV, or the LOV of the item) |
| TRIGGER | IMPORTERS.ARBC_IMPR_NAME.KEY-NEXT-ITEM | - | - | - | - | DROPPED | temporary ADD_CTRY_CD / CITY_CODE values only for FIRST_RECORD navigation, restored at once: no net effect |
| TRIGGER | IMPORTERS.BUS_ID.KEY-LISTVAL | - | - | - | - | DROPPED | Designer "may the LOV be shown" check of an item without an LOV call (APEX: no LOV, or the LOV of the item) |
| TRIGGER | IMPORTERS.BUS_ID.WHEN-VALIDATE-ITEM | PACKAGE | BUS_ID_VALIDATION / BUS_ID_WHEN_VALIDATE_ITEM | 1130 | IMPR1130.BUS_ID_VALIDATION | MAPPED | formats, full number, duplicates, register |
| TRIGGER | IMPORTERS.BUS_ID_BRNCH.KEY-LISTVAL | - | - | - | - | DROPPED | Designer "may the LOV be shown" check of an item without an LOV call (APEX: no LOV, or the LOV of the item) |
| TRIGGER | IMPORTERS.BUS_ID_BRNCH.KEY-NEXT-ITEM | PACKAGE | BUS_ID_BRNCH_VALIDATE_ITEM | 1130 | IMPR1130.BUS_ID_BRNCH_VALIDATE_ITEM | MAPPED | CHK_IMPR_DUPL on a new record (also in the validation) |
| TRIGGER | IMPORTERS.BUS_ID_BRNCH.WHEN-VALIDATE-ITEM | PACKAGE | BUS_ID_BRNCH_VALIDATION / BUS_ID_BRNCH_VALIDATE_ITEM | 1130 | IMPR1130.BUS_ID_BRNCH_VALIDATION | MAPPED | CHK_IMPR_DUPL, 1-220, register, 9-190 / 9-210 |
| TRIGGER | IMPORTERS.BUS_ID_EXPRD_DT.KEY-F4 | APEX | date picker | 1130 | - | MAPPED | INTRFACE.Disp_Date_Con |
| TRIGGER | IMPORTERS.BUS_ID_EXPRD_DT.KEY-LISTVAL | APEX | date picker | 1130 | - | MAPPED | INTRFACE.Disp_Calendar |
| TRIGGER | IMPORTERS.BUS_ID_EXPRD_DT.WHEN-NEW-ITEM-INSTANCE | APEX | page reload | 1130 | - | MAPPED | EXECUTE_QUERY after :GLOBAL.EXEC_QUERY_NOW |
| TRIGGER | IMPORTERS.BUS_ID_EXPRD_DT.WHEN-VALIDATE-ITEM | PACKAGE | BUS_ID_EXPRD_DT_VALIDATION | 1130 | IMPR1130.BUS_ID_EXPRD_DT_VALIDATION | MAPPED | Hijri date check |
| TRIGGER | IMPORTERS.BUS_ID_ISSUE_DT.KEY-F4 | APEX | date picker | 1130 | - | MAPPED | INTRFACE.Disp_Date_Con |
| TRIGGER | IMPORTERS.BUS_ID_ISSUE_DT.KEY-LISTVAL | APEX | date picker | 1130 | - | MAPPED | INTRFACE.Disp_Calendar |
| TRIGGER | IMPORTERS.BUS_ID_ISSUE_DT.WHEN-VALIDATE-ITEM | PACKAGE | BUS_ID_ISSUE_DT_VALIDATION | 1130 | IMPR1130.BUS_ID_ISSUE_DT_VALIDATION | MAPPED | Hijri date check |
| TRIGGER | IMPORTERS.BUS_ID_TYPE_CD.KEY-LISTVAL | APEX | Popup LOV LOV_IMPR_TYPE_BUS_ID + BUS_ID_TYPE_CD_VALIDATE_ITEM | 1130 | IMPR1130.BUS_ID_TYPE_CD_VALIDATE_ITEM | MAPPED | CALL_FORM LOV_Impr_Type with IMPR_TYPE_CD |
| TRIGGER | IMPORTERS.BUS_ID_TYPE_CD.WHEN-VALIDATE-ITEM | PACKAGE | BUS_ID_TYPE_CD_VALIDATION / BUS_ID_TYPE_CD_VALIDATE_ITEM | 1130 | IMPR1130.BUS_ID_TYPE_CD_VALIDATION | MAPPED | message 9-170 |
| TRIGGER | IMPORTERS.BUS_ID_TYPE_NAME.KEY-LISTVAL | - | - | - | - | DROPPED | Designer "may the LOV be shown" check of an item without an LOV call (APEX: no LOV, or the LOV of the item) |
| TRIGGER | IMPORTERS.BUTT.WHEN-BUTTON-PRESSED | APEX | Popup LOV button | 1130 | - | MAPPED | LOV button of BUS_ID_TYPE_CD |
| TRIGGER | IMPORTERS.CITY_CODE.KEY-LISTVAL | APEX | Popup LOV LOV_CITIES + CITY_CODE_WHEN_VALIDATE_ITEM | 1130 | IMPR1130.CITY_CODE_WHEN_VALIDATE_ITEM | MAPPED | CALL_FORM LOV_CITIES by ADD_CTRY_CD |
| TRIGGER | IMPORTERS.CITY_CODE.WHEN-VALIDATE-ITEM | PACKAGE | CITY_CODE_VALIDATION / CITY_CODE_WHEN_VALIDATE_ITEM | 1130 | IMPR1130.CITY_CODE_VALIDATION | MAPPED | required, 18-282, lookup warning |
| TRIGGER | IMPORTERS.CITY_CODE2.WHEN-BUTTON-PRESSED | APEX | Popup LOV button | 1130 | - | MAPPED | LOV button |
| TRIGGER | IMPORTERS.CITY_CODE_OF_ID.KEY-LISTVAL | APEX | Popup LOV LOV_CITIES_IMP_ID | 1130 | - | MAPPED | CALL_FORM LOV_CITIES (Saudi cities) |
| TRIGGER | IMPORTERS.CITY_CODE_OF_ID.WHEN-NEW-ITEM-INSTANCE | PACKAGE | CITY_CODE_OF_ID_VALIDATE_ITEM (ctry_cd_of_id_value) | 1130 | IMPR1130.CITY_CODE_OF_ID_VALIDATE_ITEM | MAPPED | CTRY_CD_OF_ID default |
| TRIGGER | IMPORTERS.CITY_CODE_OF_ID.WHEN-VALIDATE-ITEM | PACKAGE | CITY_CODE_OF_ID_CONFIRM_TEXT / _VALIDATION / _VALIDATE_ITEM | 1130 | IMPR1130.CITY_CODE_OF_ID_CONFIRM_TEXT | MAPPED | country of the city, full number (9-120 Confirm), 9-130, lookups |
| TRIGGER | IMPORTERS.CITY_CODE_OF_ID2.WHEN-BUTTON-PRESSED | APEX | Popup LOV button | 1130 | - | MAPPED | GO_ITEM + DO_KEY |
| TRIGGER | IMPORTERS.CITY_NAME.KEY-LISTVAL | - | - | - | - | DROPPED | Designer "may the LOV be shown" check of an item without an LOV call (APEX: no LOV, or the LOV of the item) |
| TRIGGER | IMPORTERS.COMM_RGSTRTN_TYPE.KEY-LISTVAL | - | - | - | - | DROPPED | Designer "may the LOV be shown" check of an item without an LOV call (APEX: no LOV, or the LOV of the item) |
| TRIGGER | IMPORTERS.COMM_RGSTRTN_TYPE.WHEN-LIST-CHANGED | PACKAGE | COMM_RGSTRTN_TYPE_LIST_CHANGED | 1130 | IMPR1130.COMM_RGSTRTN_TYPE_LIST_CHANGED | MAPPED | branch cleared for type 1; enabling -> rules |
| TRIGGER | IMPORTERS.CREATION_FLAG.KEY-LISTVAL | - | - | - | - | DROPPED | Designer "may the LOV be shown" check of an item without an LOV call (APEX: no LOV, or the LOV of the item) |
| TRIGGER | IMPORTERS.CREATION_FLAG2.WHEN-BUTTON-PRESSED | - | - | - | - | DROPPED | LOV button of a non-displayed item |
| TRIGGER | IMPORTERS.CRTY_ARBC_NAME.KEY-LISTVAL | - | - | - | - | DROPPED | Designer "may the LOV be shown" check of an item without an LOV call (APEX: no LOV, or the LOV of the item) |
| TRIGGER | IMPORTERS.CTRY_CD.KEY-LISTVAL | APEX | Popup LOV LOV_COUNTRIES / LOV_COUNTRIES_GULF | 1130 | - | MAPPED | CALL_LOV_COUNTRIES / CALL_LOV_COUN_GULF by type |
| TRIGGER | IMPORTERS.CTRY_CD.WHEN-VALIDATE-ITEM | PACKAGE | CTRY_CD_VALIDATION / CTRY_CD_WHEN_VALIDATE_ITEM | 1130 | IMPR1130.CTRY_CD_VALIDATION | MAPPED | Gulf rule, country lookup |
| TRIGGER | IMPORTERS.CTRY_CD2.WHEN-BUTTON-PRESSED | APEX | Popup LOV button | 1130 | - | MAPPED | GO_ITEM + DO_KEY |
| TRIGGER | IMPORTERS.CTRY_CD_OF_ID.KEY-LISTVAL | - | - | - | - | DROPPED | Designer "may the LOV be shown" check of an item without an LOV call (APEX: no LOV, or the LOV of the item) |
| TRIGGER | IMPORTERS.CTRY_CD_OF_ID.WHEN-VALIDATE-ITEM | PACKAGE | CITY_CODE_OF_ID_VALIDATE_ITEM | 1130 | IMPR1130.CITY_CODE_OF_ID_VALIDATE_ITEM | MAPPED | CGSF$CLRLU (hidden item, set by the city) |
| TRIGGER | IMPORTERS.CTRY_CTRY_STATUS.KEY-LISTVAL | - | - | - | - | DROPPED | Designer "may the LOV be shown" check of an item without an LOV call (APEX: no LOV, or the LOV of the item) |
| TRIGGER | IMPORTERS.CUSTOMS_ENTERED.KEY-LISTVAL | - | - | - | - | DROPPED | Designer "may the LOV be shown" check of an item without an LOV call (APEX: no LOV, or the LOV of the item) |
| TRIGGER | IMPORTERS.CUSTOMS_ENTERED2.WHEN-BUTTON-PRESSED | - | - | - | - | DROPPED | LOV button of a non-displayed item |
| TRIGGER | IMPORTERS.EMAIL.WHEN-VALIDATE-ITEM | PACKAGE | EMAIL_VALIDATION | 1130 | IMPR1130.EMAIL_VALIDATION | MAPPED | '@' check (DA only, as Forms: only when the user leaves the item) |
| TRIGGER | IMPORTERS.ENG_IMPR_NAME.KEY-LISTVAL | - | - | - | - | DROPPED | Designer "may the LOV be shown" check of an item without an LOV call (APEX: no LOV, or the LOV of the item) |
| TRIGGER | IMPORTERS.ENG_IMPR_NAME.WHEN-VALIDATE-ITEM | PACKAGE | ENG_IMPR_NAME_VALIDATION / ENG_IMPR_NAME_VALIDATE_ITEM | 1130 | IMPR1130.ENG_IMPR_NAME_VALIDATION | MAPPED | RemoveRepeat, English letters |
| TRIGGER | IMPORTERS.EXPD_STMT_NBR.KEY-LISTVAL | - | - | - | - | DROPPED | Designer "may the LOV be shown" check of an item without an LOV call (APEX: no LOV, or the LOV of the item) |
| TRIGGER | IMPORTERS.EXPRESS_POST.KEY-LISTVAL | - | - | - | - | DROPPED | Designer "may the LOV be shown" check of an item without an LOV call (APEX: no LOV, or the LOV of the item) |
| TRIGGER | IMPORTERS.HQ_IMPR_NBR.KEY-LISTVAL | - | - | - | - | DROPPED | Designer "may the LOV be shown" check of an item without an LOV call (APEX: no LOV, or the LOV of the item) |
| TRIGGER | IMPORTERS.ID_CITY_NAME.KEY-LISTVAL | - | - | - | - | DROPPED | Designer "may the LOV be shown" check of an item without an LOV call (APEX: no LOV, or the LOV of the item) |
| TRIGGER | IMPORTERS.ID_MINS_COMM_CD.KEY-LISTVAL | - | - | - | - | DROPPED | Designer "may the LOV be shown" check of an item without an LOV call (APEX: no LOV, or the LOV of the item) |
| TRIGGER | IMPORTERS.IMPD_STMT_NBR.KEY-LISTVAL | - | - | - | - | DROPPED | Designer "may the LOV be shown" check of an item without an LOV call (APEX: no LOV, or the LOV of the item) |
| TRIGGER | IMPORTERS.IMPR_ADDRESS.KEY-LISTVAL | - | - | - | - | DROPPED | Designer "may the LOV be shown" check of an item without an LOV call (APEX: no LOV, or the LOV of the item) |
| TRIGGER | IMPORTERS.IMPR_CNTCT_NAME.KEY-LISTVAL | - | - | - | - | DROPPED | Designer "may the LOV be shown" check of an item without an LOV call (APEX: no LOV, or the LOV of the item) |
| TRIGGER | IMPORTERS.IMPR_DATA_SRCE.KEY-LISTVAL | - | - | - | - | DROPPED | Designer "may the LOV be shown" check of an item without an LOV call (APEX: no LOV, or the LOV of the item) |
| TRIGGER | IMPORTERS.IMPR_FAX_NBR.KEY-LISTVAL | - | - | - | - | DROPPED | Designer "may the LOV be shown" check of an item without an LOV call (APEX: no LOV, or the LOV of the item) |
| TRIGGER | IMPORTERS.IMPR_NAME_PARENT.KEY-LISTVAL | - | - | - | - | DROPPED | Designer "may the LOV be shown" check of an item without an LOV call (APEX: no LOV, or the LOV of the item) |
| TRIGGER | IMPORTERS.IMPR_NBR.KEY-LISTVAL | - | - | - | - | DROPPED | Designer "may the LOV be shown" check of an item without an LOV call (APEX: no LOV, or the LOV of the item) |
| TRIGGER | IMPORTERS.IMPR_NBR.WHEN-VALIDATE-ITEM | PACKAGE | IMPR_NBR_VALIDATION + IMPORTER_ROW_ID | 1130 | IMPR1130.IMPR_NBR_VALIDATION | MAPPED | query by number -> request EXECUTE_QUERY |
| TRIGGER | IMPORTERS.IMPR_NBR_PARENT.KEY-LISTVAL | APEX | Popup LOV LOV_IMPR + IMPR_NBR_PARENT_VALIDATE_ITEM | 1130 | IMPR1130.IMPR_NBR_PARENT_VALIDATE_ITEM | MAPPED | CALL_FORM LOV_IMPR |
| TRIGGER | IMPORTERS.IMPR_NBR_PARENT.WHEN-VALIDATE-ITEM | PACKAGE | IMPR_NBR_PARENT_VALIDATE_ITEM | 1130 | IMPR1130.IMPR_NBR_PARENT_VALIDATE_ITEM | MAPPED | parent name, message 9-160 |
| TRIGGER | IMPORTERS.IMPR_NBR_PARENT2.WHEN-BUTTON-PRESSED | APEX | Popup LOV button | 1130 | - | MAPPED | LOV button |
| TRIGGER | IMPORTERS.IMPR_POB_NBR.KEY-LISTVAL | - | - | - | - | DROPPED | Designer "may the LOV be shown" check of an item without an LOV call (APEX: no LOV, or the LOV of the item) |
| TRIGGER | IMPORTERS.IMPR_TELEX_NBR.KEY-LISTVAL | - | - | - | - | DROPPED | Designer "may the LOV be shown" check of an item without an LOV call (APEX: no LOV, or the LOV of the item) |
| TRIGGER | IMPORTERS.IMPR_TEL_NBR.KEY-LISTVAL | - | - | - | - | DROPPED | Designer "may the LOV be shown" check of an item without an LOV call (APEX: no LOV, or the LOV of the item) |
| TRIGGER | IMPORTERS.IMPR_TEL_NBR.WHEN-VALIDATE-ITEM | PACKAGE | IMPR_TEL_NBR_VALIDATION | 1130 | IMPR1130.IMPR_TEL_NBR_VALIDATION | MAPPED | required, 10 digits |
| TRIGGER | IMPORTERS.IMPR_TYPE_CD.KEY-LISTVAL | APEX | Popup LOV LOV_IMPR_TYPE + IMPR_TYPE_CD_VALIDATE_ITEM | 1130 | IMPR1130.IMPR_TYPE_CD_VALIDATE_ITEM | MAPPED | CALL_FORM LOV_Impr_Type returns type / identity type / names |
| TRIGGER | IMPORTERS.IMPR_TYPE_CD.KEY-NEXT-ITEM | APEX | DA Set Focus | 1130 | - | MAPPED | next item COMM_RGSTRTN_TYPE (identity type 2) / BUS_ID_EXPRD_DT |
| TRIGGER | IMPORTERS.IMPR_TYPE_CD.WHEN-NEW-ITEM-INSTANCE | APEX | page reload | 1130 | - | MAPPED | EXECUTE_QUERY after :GLOBAL.EXEC_QUERY_NOW |
| TRIGGER | IMPORTERS.IMPR_TYPE_CD.WHEN-VALIDATE-ITEM | PACKAGE | IMPR_TYPE_CD_VALIDATION / IMPR_TYPE_CD_VALIDATE_ITEM | 1130 | IMPR1130.IMPR_TYPE_CD_VALIDATION | MAPPED | type table, sequences, identity type, names |
| TRIGGER | IMPORTERS.IMPR_TYPE_CD2.WHEN-BUTTON-PRESSED | APEX | Popup LOV button | 1130 | - | MAPPED | GO_ITEM + DO_KEY(LIST_VALUES) |
| TRIGGER | IMPORTERS.IMPR_TYPE_NAME.KEY-LISTVAL | - | - | - | - | DROPPED | Designer "may the LOV be shown" check of an item without an LOV call (APEX: no LOV, or the LOV of the item) |
| TRIGGER | IMPORTERS.IMPR_ZIP_CD.KEY-LISTVAL | - | - | - | - | DROPPED | Designer "may the LOV be shown" check of an item without an LOV call (APEX: no LOV, or the LOV of the item) |
| TRIGGER | IMPORTERS.KEY-DELREC | PACKAGE | KEY_DELREC | 1130 | IMPR1130.KEY_DELREC | MAPPED | child deletes, delete check, delete (no COMMIT); question = page 0 DELETE confirm |
| TRIGGER | IMPORTERS.KEY-HELP | - | - | - | - | DROPPED | Designer MS-Help (CGHP$CALL_MS_HELP) |
| TRIGGER | IMPORTERS.L_CT_CITY_STATUS.KEY-LISTVAL | - | - | - | - | DROPPED | Designer "may the LOV be shown" check of an item without an LOV call (APEX: no LOV, or the LOV of the item) |
| TRIGGER | IMPORTERS.L_CT_CITY_STATUS2.KEY-LISTVAL | - | - | - | - | DROPPED | Designer "may the LOV be shown" check of an item without an LOV call (APEX: no LOV, or the LOV of the item) |
| TRIGGER | IMPORTERS.MOBILE_NO.KEY-LISTVAL | - | - | - | - | DROPPED | Designer "may the LOV be shown" check of an item without an LOV call (APEX: no LOV, or the LOV of the item) |
| TRIGGER | IMPORTERS.MOBILE_NO.WHEN-VALIDATE-ITEM | PACKAGE | MOBILE_NO_VALIDATION | 1130 | IMPR1130.MOBILE_NO_VALIDATION | MAPPED | required, digits, 9 digits starting with 5 |
| TRIGGER | IMPORTERS.NATIONAL_NBR.KEY-LISTVAL | - | - | - | - | DROPPED | Designer "may the LOV be shown" check of an item without an LOV call (APEX: no LOV, or the LOV of the item) |
| TRIGGER | IMPORTERS.NATIONAL_NBR.WHEN-VALIDATE-ITEM | PACKAGE | NATIONAL_NBR_VALIDATION / NATIONAL_NBR_VALIDATE_ITEM | 1130 | IMPR1130.NATIONAL_NBR_VALIDATION | MAPPED | starts with 7; Ministry of Commerce web service |
| TRIGGER | IMPORTERS.ON-ERROR | PACKAGE | importers_on_error (private) | 1130 | - | MAPPED | constraint messages incl. the 32 delete constraints (FRM-40510) |
| TRIGGER | IMPORTERS.PORT_CD.KEY-LISTVAL | APEX | not needed | 1130 | - | MAPPED | PORT_CD is always P_CURR_PORT_CD (read-only) |
| TRIGGER | IMPORTERS.PORT_CD.WHEN-VALIDATE-ITEM | PACKAGE | PORT_CD_VALIDATION / PORT_CD_WHEN_VALIDATE_ITEM | 1130 | IMPR1130.PORT_CD_VALIDATION | MAPPED | port lookup (PORT_CD read-only in APEX) |
| TRIGGER | IMPORTERS.PORT_CD2.WHEN-BUTTON-PRESSED | APEX | not needed | 1130 | - | MAPPED | LOV button of the read-only PORT_CD |
| TRIGGER | IMPORTERS.PORT_NAME.KEY-LISTVAL | - | - | - | - | DROPPED | Designer "may the LOV be shown" check of an item without an LOV call (APEX: no LOV, or the LOV of the item) |
| TRIGGER | IMPORTERS.POST-INSERT | PACKAGE | POST_INSERT | 1130 | IMPR1130.POST_INSERT | MAPPED | audit row, journaling off |
| TRIGGER | IMPORTERS.POST-QUERY | PACKAGE | POST_QUERY | 1130 | IMPR1130.POST_QUERY | MAPPED | suspension, Ministry status, FK lookups; entrable part -> rules |
| TRIGGER | IMPORTERS.PRE-DELETE | PACKAGE | KEY_DELREC | 1130 | IMPR1130.KEY_DELREC | MAPPED | activity 5 + the same delete check |
| TRIGGER | IMPORTERS.PRE-INSERT | PACKAGE | PRE_INSERT | 1130 | IMPR1130.PRE_INSERT | MAPPED | required checks, CHK_IMPR_DUPL, journaling, activity, CREATE_UNI_IMPR_NEBRAS, CGFK$CLR_FK_ON_INS |
| TRIGGER | IMPORTERS.PRE-QUERY | APEX | search page 113001 SQL | 1130 | - | MAPPED | PRSNL_IMPR filter, :GLOBAL query-by-number -> request EXECUTE_QUERY; DEFAULT_WHERE / StrFormat search -> search page |
| TRIGGER | IMPORTERS.PRE-RECORD | PACKAGE | PRE_RECORD | 1130 | IMPR1130.PRE_RECORD | MAPPED | parent importer name, message 9-150 |
| TRIGGER | IMPORTERS.PRE-UPDATE | PACKAGE | PRE_UPDATE | 1130 | IMPR1130.PRE_UPDATE | MAPPED | IMPR_NAME_STD, audit row, HQ number, activity, trims |
| TRIGGER | IMPORTERS.STATUS_DESC.KEY-LISTVAL | - | - | - | - | DROPPED | Designer "may the LOV be shown" check of an item without an LOV call (APEX: no LOV, or the LOV of the item) |
| TRIGGER | IMPORTERS.SUSPN_STATUS.KEY-LISTVAL | - | - | - | - | DROPPED | Designer "may the LOV be shown" check of an item without an LOV call (APEX: no LOV, or the LOV of the item) |
| TRIGGER | IMPORTERS.WHEN-CREATE-RECORD | PACKAGE | WHEN_CREATE_RECORD | 1130 | IMPR1130.WHEN_CREATE_RECORD | MAPPED | port, personal importer type 4; entrable calls -> rules |
| TRIGGER | IMPORTERS.WHEN-NEW-ITEM-INSTANCE | APEX | request EXECUTE_QUERY / page reload | 1130 | - | MAPPED | EXECUTE_QUERY after :GLOBAL.EXEC_QUERY_NOW |
| TRIGGER | IMPORTERS.WHEN-NEW-RECORD-INSTANCE | PACKAGE | READ_ONLY_FLAGS | 1130 | IMPR1130.READ_ONLY_FLAGS | MAPPED | only Make_Field_Entrable / REQUIRED / GO_ITEM (declarations -> names read-only) |
| TRIGGER | IMPORTERS.WVR_ENTRY_NBR.KEY-LISTVAL | - | - | - | - | DROPPED | Designer "may the LOV be shown" check of an item without an LOV call (APEX: no LOV, or the LOV of the item) |
| PROGRAM_UNIT | ADJ_FUNS | PACKAGE | ADJ_FUNS | 1130 | IMPR1130.ADJ_FUNS | MAPPED | IMPR_MCI_SERVICE enabled / disabled |
| PROGRAM_UNIT | CALL_LOV_COUNTRIES | APEX | Popup LOV LOV_COUNTRIES + CTRY_CD_WHEN_VALIDATE_ITEM | 1130 | IMPR1130.CTRY_CD_WHEN_VALIDATE_ITEM | MAPPED | CALL_FORM LOV_COUNTRIES |
| PROGRAM_UNIT | CALL_LOV_COUN_GULF | APEX | Popup LOV LOV_COUNTRIES_GULF + CTRY_CD_WHEN_VALIDATE_ITEM | 1130 | IMPR1130.CTRY_CD_WHEN_VALIDATE_ITEM | MAPPED | CALL_FORM LOV_COUNTRIES_GULF |
| PROGRAM_UNIT | CG$IMPR1130_PROD_CENTRL_GLOBAL | - | - | - | - | DROPPED | IMPORTERS_WHERE variable of PRE-QUERY (search page SQL) |
| PROGRAM_UNIT | CG$WHEN_NEW_FORM_INSTANCE | APEX | shared LOVs | 1130 | - | MAPPED | CGDV$POPULATE_DYNAMIC_LISTS |
| PROGRAM_UNIT | CGDV$POPULATE_DYNAMIC_LISTS | APEX | shared LOVs LOV_COMM_RGSTRTN_TYPE / LOV_ALLOWED_EXPORT (REFERENCE_CODES) | 1130 | - | MAPPED | list items from CG_REF_CODES |
| PROGRAM_UNIT | CGFK$CHK_IMPORTERS_IMP_ADD_CIT | PACKAGE | address_city_lookup (private) | 1130 | - | MAPPED | FK lookup |
| PROGRAM_UNIT | CGFK$CHK_IMPORTERS_IMP_BUS_ID_ | PACKAGE | city_code_of_id_logic (private) | 1130 | - | MAPPED | FK lookup |
| PROGRAM_UNIT | CGFK$CHK_IMPORTERS_IMP_CTRY_FK | PACKAGE | ctry_cd_logic (private) | 1130 | - | MAPPED | FK lookup |
| PROGRAM_UNIT | CGFK$CHK_IMPORTERS_IMP_ITIDT_F | PACKAGE | impr_type_cd_logic (private) | 1130 | - | MAPPED | FK lookup |
| PROGRAM_UNIT | CGFK$CHK_IMPORTERS_IMP_MB_FK | - | - | - | - | DROPPED | not called by any active code |
| PROGRAM_UNIT | CGFK$CHK_IMPORTERS_IMP_SDP_FK | PACKAGE | port_cd_logic (private) | 1130 | - | MAPPED | FK lookup |
| PROGRAM_UNIT | CGFK$QRY_IMPORTERS_IMP_ADD_CIT | PACKAGE | POST_QUERY | 1130 | IMPR1130.POST_QUERY | MAPPED | FK lookup on query |
| PROGRAM_UNIT | CGFK$QRY_IMPORTERS_IMP_BUS_ID_ | PACKAGE | POST_QUERY | 1130 | IMPR1130.POST_QUERY | MAPPED | FK lookup on query |
| PROGRAM_UNIT | CGFK$QRY_IMPORTERS_IMP_CTRY_FK | PACKAGE | POST_QUERY | 1130 | IMPR1130.POST_QUERY | MAPPED | FK lookup on query |
| PROGRAM_UNIT | CGFK$QRY_IMPORTERS_IMP_ITIDT_F | PACKAGE | POST_QUERY | 1130 | IMPR1130.POST_QUERY | MAPPED | FK lookup on query |
| PROGRAM_UNIT | CGFK$QRY_IMPORTERS_IMP_SDP_FK | PACKAGE | POST_QUERY | 1130 | IMPR1130.POST_QUERY | MAPPED | FK lookup on query |
| PROGRAM_UNIT | CGRI$CHK_IMPORTERS | PACKAGE | CGRI$CHK_IMPORTERS (private, generated) | 1130 | - | MAPPED | 36 dependent-table checks |
| PROGRAM_UNIT | CGSF$CLRLU_IMPORTERS_IMP_BUS_I | PACKAGE | city_code_of_id_logic / PRE_INSERT (private) | 1130 | IMPR1130.PRE_INSERT | MAPPED | clear the city-of-ID lookups |
| PROGRAM_UNIT | CGTE$CHECK_CONSTRAINT_VIO | PACKAGE | importers_on_error (private) | 1130 | - | MAPPED | constraint messages |
| PROGRAM_UNIT | CHECK_EDI_MSG_LOV | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| PROGRAM_UNIT | CHECK_EDI_MSG_TIMER | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| PROGRAM_UNIT | CHECK_EDI_ROLE_ID | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| PROGRAM_UNIT | CHECK_TIMEOUT | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| PROGRAM_UNIT | CHK_IMPR_DUPL | PACKAGE | chk_impr_dupl (private) | 1130 | - | MAPPED | duplicate BUS_ID / branch |
| PROGRAM_UNIT | DEV_VERSIONS | - | - | - | - | DROPPED | developer comment (version 8) -> PKG_VERSION |
| PROGRAM_UNIT | EDI_MSG_LOV | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| PROGRAM_UNIT | EXECUTE_FUNCTION | APEX | f345 Page Functions list (page 0 FUNCS) | 1130 | - | MAPPED | TMPLT function runner (CALL_FORM / RUN_PRODUCT by SC_SYSTEM_OBJECTS) |
| PROGRAM_UNIT | EXEC_FUNS | PACKAGE | EXEC_FUNS | 1130 | IMPR1130.EXEC_FUNS | MAPPED | function IMPR_MCI_SERVICE |
| PROGRAM_UNIT | FOR_EDI_MSG | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| PROGRAM_UNIT | GET_BRANCH_CR_DATA | PACKAGE | NATIONAL_NBR_VALIDATE_ITEM | 1130 | IMPR1130.NATIONAL_NBR_VALIDATE_ITEM | MAPPED | MCISERVICE.getBranchCRInfoCall |
| PROGRAM_UNIT | GET_CR_DATA | PACKAGE | get_cr_data (private) | 1130 | - | MAPPED | parse of the web-service answer (loop instead of 16 SELECT INSTR FROM DUAL) |
| PROGRAM_UNIT | GET_MAIN_CR_DATA | PACKAGE | NATIONAL_NBR_VALIDATE_ITEM | 1130 | IMPR1130.NATIONAL_NBR_VALIDATE_ITEM | MAPPED | MCISERVICE.getMainCRInfoCall |
| PROGRAM_UNIT | INSERT_AUDIT_RECORD | PACKAGE | insert_audit_record (private) | 1130 | - | MAPPED | IMPR_UPDTS row, 9-140 |
| PROGRAM_UNIT | MOUSE_CLICK | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| PROGRAM_UNIT | PRINT_REPORT | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| PROGRAM_UNIT | RETURN_MSG | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| PROGRAM_UNIT | TERMINATE_FUN | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| PROGRAM_UNIT | TOGGEL_WND | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| PROGRAM_UNIT | TURN_MSG | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| PROGRAM_UNIT | UPDATE_IMPORTER | PACKAGE | UPDATE_IMPORTER_CONFIRM_TEXT + update_importer (private, via EXEC_FUNS) | 1130 | IMPR1130.UPDATE_IMPORTER_CONFIRM_TEXT | MAPPED | Confirm, UPDATE_IMPORTERS_NAMES, re-query; COMMITs removed |
| PROGRAM_UNIT | WHEN_TIMER_EXPIRED_MSG | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| TRIGGER | TITLE.SYSTEM_DATE.WHEN-VALIDATE-ITEM | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| TRIGGER | TOOLBAR.EXIT.WHEN-BUTTON-PRESSED | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| TRIGGER | TOOLBAR.EXIT1.WHEN-BUTTON-PRESSED | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| TRIGGER | TOOLBAR.FUN_BUT.WHEN-MOUSE-DOWN | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| TRIGGER | TOOLBAR.FUN_BUT.WHEN-MOUSE-UP | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| TRIGGER | TOOLBAR.KEY-DOWN | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| TRIGGER | TOOLBAR.KEY-NEXT-ITEM | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| TRIGGER | TOOLBAR.KEY-UP | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| TRIGGER | TOOLBAR.LAST_REC.WHEN-BUTTON-PRESSED | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| TRIGGER | TOOLBAR.PAGE_DOWN.WHEN-BUTTON-PRESSED | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| TRIGGER | TOOLBAR.RE_ENTER_QUERY.WHEN-BUTTON-PRESSED | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| TRIGGER | TOOLBAR.SAVE.WHEN-BUTTON-PRESSED | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| TRIGGER | TITLE.CGSO$CHAR_ARB_ED.KEY-LISTVAL | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | TITLE.CGSO$CHAR_ARB_DO_ENB_Y.KEY-LISTVAL | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | TITLE.CGSO$CHAR_ARB_MLINE.KEY-LISTVAL | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | TITLE.CGSO$CHAR_ARB.KEY-LISTVAL | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | TITLE.CGSO$CHAR_ARB_DO.KEY-LISTVAL | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | EDI_MSG.EDI_MSG_LOVE_BUT.WHEN-BUTTON-PRESSED | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN1.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN1.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN1.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN50.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN50.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN50.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN2.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN2.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN2.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN49.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN49.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN49.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN3.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN3.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN3.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN48.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN48.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN48.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN4.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN4.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN4.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN47.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN47.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN47.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN5.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN5.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN5.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN46.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN46.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN46.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN6.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN6.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN6.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN45.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN45.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN45.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN7.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN7.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN7.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN44.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN44.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN44.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN8.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN8.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN8.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN43.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN43.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN43.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN9.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN9.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN9.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN42.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN42.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN42.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN10.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN10.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN10.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN41.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN41.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN41.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN11.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN11.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN11.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN40.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN40.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN40.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN12.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN12.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN12.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN39.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN39.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN39.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN13.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN13.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN13.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN38.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN38.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN38.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN14.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN14.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN14.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN37.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN37.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN37.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN15.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN15.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN15.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN36.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN36.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN36.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN16.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN16.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN16.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN17.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN17.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN17.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN34.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN34.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN34.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN35.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN35.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN35.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN18.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN18.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN18.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN33.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN33.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN33.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN19.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN19.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN19.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN32.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN32.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN32.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN20.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN20.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN20.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN31.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN31.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN31.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN21.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN21.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN21.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN30.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN30.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN30.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN22.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN22.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN22.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN29.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN29.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN29.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN23.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN23.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN23.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN28.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN28.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN28.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN24.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN24.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN24.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN27.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN27.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN27.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN25.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN25.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN25.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN26.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN26.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | LSIDE.FN26.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | TOOLBAR.CLEAR_ALL.WHEN-BUTTON-PRESSED | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | TOOLBAR.ENTER.WHEN-BUTTON-PRESSED | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | TOOLBAR.EXECUTE.WHEN-BUTTON-PRESSED | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | TOOLBAR.REMOVE.WHEN-BUTTON-PRESSED | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | TOOLBAR.LIST_VALUE.WHEN-BUTTON-PRESSED | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | TOOLBAR.HELP.WHEN-BUTTON-PRESSED | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | TOOLBAR.FIRST_REC.WHEN-BUTTON-PRESSED | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | TOOLBAR.PAGE_UP.WHEN-BUTTON-PRESSED | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| TRIGGER | FORM.KEY-F4 | - | - | - | - | DROPPED | no code in the form XML: inherited from CIC_OLB.olb (screen frame) |
| GLOBAL | :GLOBAL.ALLOW_MCI | APP_ITEM | G_ALLOW_MCI | - | - | MAPPED | application item (IMPR1110 export) |
| GLOBAL | :GLOBAL.ALLOW_MOI | APP_ITEM | G_ALLOW_MOI | - | - | MAPPED | application item (IMPR1110 export) |
| GLOBAL | :GLOBAL.BUS_ID_TYPE_CD | - | - | - | - | MAPPED | LOV return channel / flag / version stamp -> page items, parameters or requests (logic report §5) |
| GLOBAL | :GLOBAL.BUS_ID_TYPE_NAME | - | - | - | - | MAPPED | LOV return channel / flag / version stamp -> page items, parameters or requests (logic report §5) |
| GLOBAL | :GLOBAL.CG | - | - | - | - | MAPPED | LOV return channel / flag / version stamp -> page items, parameters or requests (logic report §5) |
| GLOBAL | :GLOBAL.CITY_ARB_NAME | - | - | - | - | MAPPED | LOV return channel / flag / version stamp -> page items, parameters or requests (logic report §5) |
| GLOBAL | :GLOBAL.CITY_CD | - | - | - | - | MAPPED | LOV return channel / flag / version stamp -> page items, parameters or requests (logic report §5) |
| GLOBAL | :GLOBAL.CRTY_ARBC_NAME | - | - | - | - | MAPPED | LOV return channel / flag / version stamp -> page items, parameters or requests (logic report §5) |
| GLOBAL | :GLOBAL.CTRY_CD | - | - | - | - | MAPPED | LOV return channel / flag / version stamp -> page items, parameters or requests (logic report §5) |
| GLOBAL | :GLOBAL.CURRENT_DT | - | - | - | - | MAPPED | LOV return channel / flag / version stamp -> page items, parameters or requests (logic report §5) |
| GLOBAL | :GLOBAL.CURRENT_VER | - | - | - | - | MAPPED | LOV return channel / flag / version stamp -> page items, parameters or requests (logic report §5) |
| GLOBAL | :GLOBAL.CURRENT_VERSION | - | - | - | - | MAPPED | LOV return channel / flag / version stamp -> page items, parameters or requests (logic report §5) |
| GLOBAL | :GLOBAL.EXEC_QUERY_NOW | - | - | - | - | MAPPED | LOV return channel / flag / version stamp -> page items, parameters or requests (logic report §5) |
| GLOBAL | :GLOBAL.EXIT | - | - | - | - | MAPPED | LOV return channel / flag / version stamp -> page items, parameters or requests (logic report §5) |
| GLOBAL | :GLOBAL.IMPR_NAME | - | - | - | - | MAPPED | LOV return channel / flag / version stamp -> page items, parameters or requests (logic report §5) |
| GLOBAL | :GLOBAL.IMPR_NBR | - | - | - | - | MAPPED | LOV return channel / flag / version stamp -> page items, parameters or requests (logic report §5) |
| GLOBAL | :GLOBAL.IMPR_TYPE_CD | - | - | - | - | MAPPED | LOV return channel / flag / version stamp -> page items, parameters or requests (logic report §5) |
| GLOBAL | :GLOBAL.IMPR_TYPE_NAME | - | - | - | - | MAPPED | LOV return channel / flag / version stamp -> page items, parameters or requests (logic report §5) |
| GLOBAL | :GLOBAL.INS | - | - | - | - | MAPPED | LOV return channel / flag / version stamp -> page items, parameters or requests (logic report §5) |
| GLOBAL | :GLOBAL.LETTER_DT | APP_ITEM | G_LETTER_DT | - | - | MAPPED | application item (IMPR1110 export) |
| GLOBAL | :GLOBAL.LETTER_NBR | APP_ITEM | G_LETTER_NBR | - | - | MAPPED | application item (IMPR1110 export) |
| GLOBAL | :GLOBAL.PORT_CD | APP_ITEM | G_PORT_CD (SUPPORT_ENTRY) / page item (query by number) | - | - | MAPPED | application item (IMPR1110 export) |
| GLOBAL | :GLOBAL.PORT_NAME | - | - | - | - | MAPPED | LOV return channel / flag / version stamp -> page items, parameters or requests (logic report §5) |
| GLOBAL | :GLOBAL.SET | - | - | - | - | MAPPED | LOV return channel / flag / version stamp -> page items, parameters or requests (logic report §5) |
| GLOBAL | :GLOBAL.SUPP_TITLE_CD | APP_ITEM | G_SUPP_TITLE_CD | - | - | MAPPED | application item (IMPR1110 export) |
| GLOBAL | :GLOBAL.SYSTEM_OBJ | - | - | - | - | MAPPED | LOV return channel / flag / version stamp -> page items, parameters or requests (logic report §5) |
| GLOBAL | :GLOBAL.VALID | - | - | - | - | MAPPED | LOV return channel / flag / version stamp -> page items, parameters or requests (logic report §5) |
| LOV | CGDV$IMPORTERS_CREATION_FLAG | LOV | - | - | - | MAPPED | replaced by the shared LOV of the item (LOV form, spec 6) |
| LOV | CGFK$IMPORTERS_ADD_CTRY_CD | LOV | - | - | - | MAPPED | replaced by the shared LOV of the item (LOV form, spec 6) |
| LOV | CGFK$IMPORTERS_CITY_CODE_OF_ID | LOV | - | - | - | MAPPED | replaced by the shared LOV of the item (LOV form, spec 6) |
| LOV | CGFK$IMPORTERS_CTRY_CD | LOV | - | - | - | MAPPED | replaced by the shared LOV of the item (LOV form, spec 6) |
| LOV | CGFK$IMPORTERS_HQ_IMPR_NBR | LOV | - | - | - | MAPPED | replaced by the shared LOV of the item (LOV form, spec 6) |
| LOV | CGFK$IMPORTERS_IMPR_TYPE_CD | LOV | - | - | - | MAPPED | replaced by the shared LOV of the item (LOV form, spec 6) |
| LOV | CGFK$IMPORTERS_PORT_CD | LOV | - | - | - | MAPPED | replaced by the shared LOV of the item (LOV form, spec 6) |
| LOV | CGDV$IMPORTERS_CUSTOMS_ENTERED | LOV | - | - | - | MAPPED | replaced by the shared LOV of the item (LOV form, spec 6) |
| RECORD_GROUP | CGDV$CREATION_FLAG | LOV | - | - | - | MAPPED | query in LOV_APX (spec 6) |
| RECORD_GROUP | CGFK$IMPORTERS_ADD_CTRY_CD | LOV | - | - | - | MAPPED | query in LOV_APX (spec 6) |
| RECORD_GROUP | CGFK$IMPORTERS_CITY_CODE_OF_ID | LOV | - | - | - | MAPPED | query in LOV_APX (spec 6) |
| RECORD_GROUP | CGFK$IMPORTERS_CTRY_CD | LOV | - | - | - | MAPPED | query in LOV_APX (spec 6) |
| RECORD_GROUP | CGFK$IMPORTERS_HQ_IMPR_NBR | LOV | - | - | - | MAPPED | query in LOV_APX (spec 6) |
| RECORD_GROUP | CGFK$IMPORTERS_IMPR_TYPE_CD | LOV | - | - | - | MAPPED | query in LOV_APX (spec 6) |
| RECORD_GROUP | CGFK$IMPORTERS_PORT_CD | LOV | - | - | - | MAPPED | query in LOV_APX (spec 6) |
| RECORD_GROUP | CGDV$IMPORTERS_CUSTOMS_ENTERED | LOV | - | - | - | MAPPED | query in LOV_APX (spec 6) |
| ALERT | USR_CONFIRM_B | MESSAGE | - | - | - | MAPPED | STR.DispAlert type -> FORMS_APX error / message / confirm (spec 11) |
| ALERT | USR_CONFIRM | MESSAGE | - | - | - | MAPPED | STR.DispAlert type -> FORMS_APX error / message / confirm (spec 11) |
| ALERT | USR_WARNING_C | MESSAGE | - | - | - | MAPPED | STR.DispAlert type -> FORMS_APX error / message / confirm (spec 11) |
| ALERT | USR_WARNING_B | MESSAGE | - | - | - | MAPPED | STR.DispAlert type -> FORMS_APX error / message / confirm (spec 11) |
| ALERT | CFG_WARNING_A | MESSAGE | - | - | - | MAPPED | STR.DispAlert type -> FORMS_APX error / message / confirm (spec 11) |
| ALERT | CFG_INFORMATION | MESSAGE | - | - | - | MAPPED | STR.DispAlert type -> FORMS_APX error / message / confirm (spec 11) |
| ALERT | CFG_ERROR | MESSAGE | - | - | - | MAPPED | STR.DispAlert type -> FORMS_APX error / message / confirm (spec 11) |
| ALERT | CFG_SYSTEM_ERROR | MESSAGE | - | - | - | MAPPED | STR.DispAlert type -> FORMS_APX error / message / confirm (spec 11) |
| ALERT | CFG_ASK_COMMIT | MESSAGE | - | - | - | MAPPED | STR.DispAlert type -> FORMS_APX error / message / confirm (spec 11) |
| CANVAS | LSIDE | PAGE | - | - | - | DROPPED | OLB frame |
| CANVAS | EDI_MSG | PAGE | - | - | - | DROPPED | OLB frame |
| CANVAS | TITLE | PAGE | - | - | - | DROPPED | OLB frame |
| CANVAS | TOOLBAR | PAGE | - | - | - | DROPPED | OLB frame |
| CANVAS | CG$PAGE_1 | PAGE | 1130 | - | - | MAPPED | page 1130 |
| WINDOW | CGSO$WINDOW_1 | PAGE | 1130 | - | - | MAPPED | page 1130 (f345 page template) |
| PARAMETER | P_SHPG_AGNT_NBR | APP_ITEM | (f345 application item) | - | - | MAPPED | f345 parameter mapping (inventory §12) |
| PARAMETER | P_CTRL_LAST_EXEC_CD | APP_ITEM | (f345 application item) | - | - | MAPPED | f345 parameter mapping (inventory §12) |
| PARAMETER | P_BANK_CD | APP_ITEM | (f345 application item) | - | - | MAPPED | f345 parameter mapping (inventory §12) |
| PARAMETER | P_BANK_BRNCH_CD | APP_ITEM | (f345 application item) | - | - | MAPPED | f345 parameter mapping (inventory §12) |
| PARAMETER | P_BRKR_PORT_CD | APP_ITEM | (f345 application item) | - | - | MAPPED | f345 parameter mapping (inventory §12) |
| PARAMETER | P_LIC_TYPE | APP_ITEM | (f345 application item) | - | - | MAPPED | f345 parameter mapping (inventory §12) |
| PARAMETER | P_BRKR_NBR | APP_ITEM | (f345 application item) | - | - | MAPPED | f345 parameter mapping (inventory §12) |
| PARAMETER | P_CLASS_CD | APP_ITEM | (f345 application item) | - | - | MAPPED | f345 parameter mapping (inventory §12) |
| PARAMETER | P_JOB_ID | APP_ITEM | (f345 application item) | - | - | MAPPED | f345 parameter mapping (inventory §12) |
| PARAMETER | P_CURRENT_ITEM | APP_ITEM | (f345 application item) | - | - | MAPPED | f345 parameter mapping (inventory §12) |
| PARAMETER | P_GROUP_CD | APP_ITEM | (f345 application item) | - | - | MAPPED | f345 parameter mapping (inventory §12) |
| PARAMETER | P_USER_TYPE | APP_ITEM | (f345 application item) | - | - | MAPPED | f345 parameter mapping (inventory §12) |
| PARAMETER | P_PORT_TYPE | APP_ITEM | (f345 application item) | - | - | MAPPED | f345 parameter mapping (inventory §12) |
| PARAMETER | P_CURR_PORT_CD | APP_ITEM | (f345 application item) | - | - | MAPPED | f345 parameter mapping (inventory §12) |
| PARAMETER | P_MODULE_ID | APP_ITEM | (f345 application item) | - | - | MAPPED | f345 parameter mapping (inventory §12) |
| PARAMETER | P_MODULE_NAME | APP_ITEM | (f345 application item) | - | - | MAPPED | f345 parameter mapping (inventory §12) |
| PARAMETER | P_APPLICATION_NAME | APP_ITEM | (f345 application item) | - | - | MAPPED | f345 parameter mapping (inventory §12) |
| PARAMETER | P_USER_ID | APP_ITEM | (f345 application item) | - | - | MAPPED | f345 parameter mapping (inventory §12) |
| PARAMETER | P_WS_ID | APP_ITEM | (f345 application item) | - | - | MAPPED | f345 parameter mapping (inventory §12) |
| PARAMETER | P_USER_NAME | APP_ITEM | (f345 application item) | - | - | MAPPED | f345 parameter mapping (inventory §12) |
| PARAMETER | CG$STARTUP_MODE | APP_ITEM | (f345 application item) | - | - | DROPPED | f345 parameter mapping (inventory §12) |
| PARAMETER | PRSNL_IMPR | ITEM | P1130_P_PRSNL_IMPR | 1130 | - | MAPPED | f345 parameter mapping (inventory §12) |
| PARAMETER | LETTER_NBR | ITEM | P1130_P_LETTER_NBR | 1130 | - | MAPPED | f345 parameter mapping (inventory §12) |
| LIBRARY | OFGTEL | - | - | - | - | TODO | inventory §10.3 |
| LIBRARY | OFGMES | - | - | - | - | MAPPED | inventory §10.3 |
| LIBRARY | OFGHPL | - | - | - | - | MAPPED | inventory §10.3 |
| LIBRARY | CIC_AMSG | - | - | - | - | MAPPED | inventory §10.3 |
| LIBRARY | SEC_LIB | - | - | - | - | TODO | inventory §10.3 |
| LIBRARY | CAPTION | - | - | - | - | MAPPED | inventory §10.3 |
| LIBRARY | OFGBSL | - | - | - | - | MAPPED | inventory §10.3 |
| LIBRARY | D2KWUTIL | - | - | - | - | MAPPED | inventory §10.3 |
| LIBRARY | CUSTOMDLL | - | - | - | - | MAPPED | inventory §10.3 |
| LIBRARY | D2KWUTIL_PDF | - | - | - | - | MAPPED | inventory §10.3 |
| LIBRARY | GETCOMP | - | - | - | - | MAPPED | inventory §10.3 |
| LIBRARY | OFGTAB | - | - | - | - | TODO | inventory §10.3 |
| LIBRARY | PICKLIST | - | - | - | - | TODO | inventory §10.3 |
| LIBRARY | POS | - | - | - | - | TODO | inventory §10.3 |
| LIBRARY | SCDLL | - | - | - | - | TODO | inventory §10.3 |
| LIBRARY | VCDLL | - | - | - | - | TODO | inventory §10.3 |
| LIBRARY | CIC_LIB | - | - | - | - | MAPPED | inventory §10.3 |

## 15. Registry script

`registry/IMPR1130_registry.sql`: one MIG_FORM_REGISTRY row and the 596 MIG_OBJECT_MAP rows of §14 (not executed).

## 16. Open items

| # | Item | Owner |
|---|---|---|
| 1 | LOV_APX change request: Gulf list for activity type 12 (§0 #8) | next LOV_APX change (coordinate with the IMPR1140 session) |
| 2 | Read-only interpretations (`read_only_rules.md` "Interpretations") | business owner |
| 3 | SUPPORT_ENTRY shown on every first view (inventory §15 #3) | business owner |
| 4 | Package `IMPR1130` 001 and `LOV_APX` / `FORMS_APX` compiled before the import | DBA |
| 5 | Open questions of the inventory §15 (#1, #4, #5, #15, #16) | business owner / DBA |
