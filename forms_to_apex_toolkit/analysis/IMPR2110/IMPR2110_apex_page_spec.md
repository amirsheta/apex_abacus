# IMPR2110 – Analysis and APEX page spec (report parameter form)

Form `forms/IMPR/IMPR2110_fmb.xml` "طباعة بيانات المستوردين" and its report `forms/IMPR/reports/IMPR2110.xml`
(Oracle Reports, data source `CG$Q_IMPORTERS`). Package `IMPR2110` 001, page **2110**, generator
`scripts/gen_apex_impr2110.py`. Date 2026-11-25. Nothing compiled or imported.

## 1. What the form does

A parameter screen with no base table: the user picks a port (only at head office, port 99) and zero or more
importer numbers (comma list), then **عرض [F5]** (`CHECK_VAL`) or **طباعة [F4]** (`PRINT_CHECK_VAL`).
Both count the matching importers. If there are none, they stop with «لا يوجد سجلات تحقق المطلوب»; otherwise they call
`REP.Run_Product(REPORTS, P_REPORT_PATH || 'IMPR2110', …)` with `DESTYPE=SCREEN` or `PRINTER`.

| Block | Kind | Items |
|---|---|---|
| `CALLING_PARAMETERS` | control, 1 record | `P_PORT_CD`, `P_PORT_NAME`, `LICE_NO`, buttons `P_LOV_PORT`, `SECT_LOV` |
| `CTR_BLK` | control, 5 records | `P_AGR_NBR` (hidden), `P_AGR_DESC`: the numbers of `LICE_NO` and their names |
| `TITLE` (OLB) | header | `SCREEN_NAME`, `USER_NAME`, `SYSTEM_DATE`, `SYSTEM_G_DATE`, `REPORT_NO`, `P_CURR_PORT_NAME` |
| `TOOLBAR` | buttons | `PRINT`, `VIEW`, `CLEAR`, `LOV`, `EXIT` |
| `ZATCA_LOGOS` (OLB) | logos | — |

## 2. Approach: report page + ARD report package (user decisions 2026-11-25)

`REP.Run_Product` is a decision point in CLAUDE.md §7. It follows the approved standard of the same project
(Forms_to_APEX `APPROVED_STANDARD.md` 13-b / 13-c) and the in-repo references `plsql/Shared/DCLN3300_ARD` and `DCLN3100_ARD`:

* **The report itself becomes the package `IMPR2110_ARD`** (`plsql/IMPR2110/IMPR2110_ARD.pks` / `.pkb`).
  `ARD_IMPR2110(P_PARAMETER1..4) RETURN CLOB` builds the report as HTML from the RDF query, its formula columns
  (same names, same code) and its layout. The ARD server (`ardpdf`) turns it into a PDF.
  The RDF on the Reports Server is no longer used (user: ARD package only).
* **Buttons: PRINT, CLEAR and BACK only** (DEC-017 / DEC-018). `P2110_REPORT` marks the page as a report page.
  `scripts/report_toolbar.py`, called by `build_full_app.py`, changes page 0: CREATE / SEARCH are hidden on report pages
  and REPORT_SHOW is `Never`. SAVE / DELETE are already hidden because the page clears `P0_PAGE_PK`, and FUNCS was already hidden.
* Page 0 **طباعة** fires the custom event `REPORT_PRINT`. The page DA clears `P2110_REPORT_URL`, then
  FOS `IMPR2110.PRINT_CHECK_VAL` repeats the item checks and the count («لا يوجد سجلات تحقق المطلوب») and returns
  the ardpdf link from `PRINT_IMPR2110_ARD`. One line of JavaScript then opens it in a new tab.
  Forms **عرض** (PU `CHECK_VAL`, same code) and **طباعة** open the same PDF.
* ardpdf link: `<ARD_URL>?func_name=LIB_APX_USR.IMPR2110_ARD.ARD_IMPR2110&P_PARAMETER1..4&DsName=<ARD_DSNAME>`.
  `ARD_URL` / `ARD_DSNAME` are **settings** in `SC_PORT_SETTING` (SYSOBJ_ID 999, PORT_CD 99; user decision 2026-11-25,
  `migration/001_ard_settings.sql`). There is no server link in the code; a missing setting stops with a message.

### Report package IMPR2110_ARD

| ARD parameter | RDF parameter | Value sent by the page |
|---|---|---|
| `P_PARAMETER1` | `P_CURR_PORT_CD` | `NVL(P2110_P_PORT_CD, P_CURR_PORT_CD)` |
| `P_PARAMETER2` | `CG$P_impr_nbr` | importer list of `P2110_LICE_NO` (digits and commas; empty = all) |
| `P_PARAMETER3` | `P_MODULE_NAME` | `P2110_HERO_TITLE` |
| `P_PARAMETER4` | `P_REPORT_NO` | `P2110_REPORT_NO` |

* **Filter (user decision):** the importers of the port whose `IMPR_NBR` is in the list (all when empty). This is the
  form's `:parameter.TRAN_SELECT`, and the rows match the page's count check. The RDF's `IMP.HQ_IMPR_NBR = :P_IMPR_NBR`
  (never sent by the form, so the report was empty) is not used. The list is read as numbers, not as a lexical.
* Formula columns as functions with the RDF code: `V_NAMEFormula`, `CF_impr_id_typeFormula`, `v_name2Formula`,
  `C_CODEFormula`, `V_PORT_NAME_SEC1FormatTrigger`. They are called inside the query, as in the reference.
  `CF_CG$G_IMPORTERS`, `CS_CG$G_IMPORTERS` and `CG$SuppressFrame` only hide the frame when there are no rows, so with no rows the loop prints nothing.
  `BeforeReport` (NLS_DATE_FORMAT) is not needed: dates are formatted explicitly.
* Layout: A4 landscape (RDF `ORIENTATION`). The header repeats on every page: port name, `ARD_LOGO.IMG(85, 335, NULL, 'LOGO1.jpg')`,
  الرقم / التاريخ / المرفقات, then the title. One block per importer (group `G_IMPR_NBR`: مسلسل, نوع المستورد,
  نوع الاقامة), followed by a table with the 8 columns of `R_CG$G_IMPORTERS` in the RDF's right-to-left order. The footer holds
  رقم التقرير and the Hijri (`MI-MM-YYYY`) / Gregorian date, plus «صفحة X من Y» (DEC-016). Text goes through `APEX_ESCAPE.HTML`.
  The old letterhead lines (وزارة المالية / مصلحة الجمارك) and image are replaced by the logo, as in the other ARD reports.

## 3. Page 2110 `IMPR2110`

Page template *Zatca-Minimal_No_Navigation*, class `zf`, protection C, page group IMPR (IMPR1110), no
search page, no submit, no DML.

| Seq | Region (static id) | Type / template | Source |
|---|---|---|---|
| 10 | الهيدر (`TITLE`) | static, hero | module name, port name, report number (KPI) |
| 20 | معاملات التقرير (`CALLING_PARAMETERS`) | static, *Interactive Report* template, `zatca-forms cg-form cg-card` | block CALLING_PARAMETERS |
| 30 | المستوردون المختارون (`CTR_BLK`) | read-only IG, *Standard*, `cg-card cg-grid`, 5 rows | block CTR_BLK |

## 4. Items

| Item | Type | Forms source | Notes |
|---|---|---|---|
| `P2110_P_PORT_CD` | Popup LOV `LOV_SD_PORTS` (IMPR1110) | `P_PORT_CD`, `P_LOV_PORT` | condition `IMPR2110.P_PORT_CD_IS_VISIBLE` (port 99 only) |
| `P2110_P_PORT_NAME` | Display only | `P_PORT_NAME` | same condition |
| `P2110_SECT_LOV` | Popup LOV `LOV_REP_IMPR`, label «رقم المستورد» | `LICE_NO` KEY-LISTVAL, button `SECT_LOV` (REP_LOV_IMPR) | **the only importer entry** (user request 2026-11-25): each pick is added to the table CTR_BLK, then the LOV is cleared |
| `P2110_LICE_NO` | Hidden, not protected | `LICE_NO` | the picked numbers, comma separated (no typing); empty = all importers of the port. **Session state only**: written by the FOS of `SECT_LOV`, read by the CTR_BLK query and `PRINT_CHECK_VAL`, never submitted from the browser (fix 2026-11-25: the table did not update after a pick) |
| `P2110_HERO_TITLE` | Hidden | `TITLE.SCREEN_NAME` (`P_MODULE_NAME`) | sent as report `P_MODULE_NAME` |
| `P2110_MODULE_ID` | Hidden | `:PARAMETER.P_MODULE_ID` | f345 |
| `P2110_REPORT_NO` | Hidden (hero) | `TITLE.REPORT_NO` = `P_SYS_ID-P_REP_NO` | values from `SC_PORT_SETTING` |
| `P2110_P_CURR_PORT_NAME` | Hidden (hero) | `TITLE.P_CURR_PORT_NAME` | |
| `P2110_REPORT` | Hidden, no value | — | report-page flag: page 0 shows PRINT, CLEAR, BACK only |
| `P2110_REPORT_URL` | Hidden, not protected | `REP.Run_Product` | returned by FOS |

Grid `CTR_BLK`: SQL splits `:P2110_LICE_NO` and joins `IMPORTERS` of `NVL(:P2110_P_PORT_CD, :P_CURR_PORT_CD)`;
columns `SEQ` (hidden key), `P_AGR_NBR`, `P_AGR_DESC` (an unknown number shows «هذا المستورد غير موجود», the Forms
message of `LICE_NO` WHEN-VALIDATE-ITEM, which did not stop the user).

## 6. LOV

`LOV_REP_IMPR` = `LOV_APX.IMPORTERS(P_PORT_ITEM => 'P2110_P_PORT_CD', P_DEFAULT_PORT_ITEM => 'P_CURR_PORT_CD')`,
columns D (number), ARBC_IMPR_NAME, BUS_ID. **LOV_APX 003**: `IMPORTERS` gets the optional fallback item. Existing
calls are unchanged; the previous version is in `rollback/LOV_APX/v002/`.

## 8. Processes (Before Header)

| Seq | Name | Call |
|---|---|---|
| 10 | `New` | Never (f345) |
| 20 | `P0_PAGE_PK CHECK` | `:P0_PAGE_PK := NULL;` (no record on a report page) |
| 40 | `PARAMETERS` | `FORMS_APX.GET_MODULE_ID(... 'IMPR2110')` |
| 60 | `WHEN-NEW-FORM-INSTANCE` | `IMPR2110.WHEN_NEW_FORM_INSTANCE` (report number, port name) |
| 100 | `HEADER TITLE` | `FORMS_APX.HEADER_TITLE` (default «طباعة بيانات المستوردين») |

No validations: the page never submits. Standard 13-b repeats the item checks inside `CHECK_VAL` / `PRINT_CHECK_VAL`.

## 10. Dynamic actions

| Name | Event | Actions |
|---|---|---|
| `P_PORT_CD WHEN-VALIDATE-ITEM` | change | FOS `P_PORT_CD_WHEN_VALIDATE_ITEM` (returns name; «رمز الجمرك غير صحيح»), Refresh CTR_BLK |
| `SECT_LOV WHEN-BUTTON-PRESSED` | change, not null | FOS `SECT_LOV_WHEN_BUTTON_PRESSED` (returns LICE_NO, clears the pick), Refresh CTR_BLK |
| `REPORT_PRINT` | custom (page 0) | Clear URL, FOS `PRINT_CHECK_VAL`, JS open the ardpdf link (1 line) |

There is no `REPORT_SHOW` DA (page 0 REPORT_SHOW is `Never`, DEC-018). The one JavaScript action is a single line
(CLAUDE.md §4c allows up to 3). It is needed because no native action opens a URL in a new tab. This is the f202604 / standard 13-b pattern.

## 11. Trace (every Forms object)

| Forms object | Target / rationale |
|---|---|
| P_PORT_CD KEY-LISTVAL, P_LOV_PORT WHEN-BUTTON-PRESSED | Popup LOV `LOV_SD_PORTS` |
| P_PORT_CD WHEN-VALIDATE-ITEM | `P_PORT_CD_VALIDATION`, `P_PORT_CD_WHEN_VALIDATE_ITEM`, DA |
| LICE_NO KEY-LISTVAL, SECT_LOV WHEN-BUTTON-PRESSED | `P2110_SECT_LOV` + `SECT_LOV_WHEN_BUTTON_PRESSED` |
| LICE_NO WHEN-VALIDATE-ITEM | name column of CTR_BLK (message only in Forms) + new list check |
| CTR_BLK WHEN-NEW-BLOCK-INSTANCE | CTR_BLK grid SQL |
| TITLE.SYSTEM_DATE / SYSTEM_G_DATE WHEN-VALIDATE-ITEM | dropped: display items, never entered |
| TOOLBAR.VIEW, KEY-F5, PU CHECK_VAL | same code as PRINT_CHECK_VAL → page 0 طباعة (REPORT_SHOW Never, DEC-018) |
| TOOLBAR.PRINT, KEY-PRINT, KEY-F4, PU PRINT_CHECK_VAL | DA `REPORT_PRINT`, `IMPR2110.PRINT_CHECK_VAL` |
| REP.Run_Product | `IMPR2110.PRINT_IMPR2110_ARD` (ardpdf link) |
| Report IMPR2110.rdf (query, groups, formulas, layout) | package `IMPR2110_ARD` (§2) |
| TOOLBAR.CLEAR / LOV / EXIT | page 0 CLEAR / Popup LOV buttons / BACK |
| WHEN-NEW-FORM-INSTANCE | process + `WHEN_NEW_FORM_INSTANCE`, item condition `P_PORT_CD_IS_VISIBLE` |
| PRE-FORM, WHEN-WINDOW-ACTIVATED | dropped: window, icon, date format (f345 shell) |
| PU P_ORDER | dropped: body commented out (NULL) |
| PU CGDV$POPULATE_DYNAMIC_LISTS | dropped: fills a non-existent item, call commented out |
| PU LOAD_ZATCA_LOGOS, block ZATCA_LOGOS | f345 hero / theme |
| Alerts CFG_*, USR_*, CG$ASK_COMMIT | not used by this form's code (STR.DispAlert texts only in LOV parameter-list errors, dropped with CALL_FORM) |
| Module parameters | `P_MODULE_ID` → item; `P_SYS_ID`, `P_REP_NO`, `P_REPORT_FILE` → `SC_PORT_SETTING`; `P_CURR_PORT_CD` → f345 app item; `P_REPORT_PATH` → Reports Server; others unused |
| Libraries OFGTEL, OFGMES, OFGHPL, D2KWUTIL, CIC_LIB, CIC_AMSG, SEC_LIB, OFGBSL, CAPTION | no call from this form's code except `HIJDATE.CUR_HIJ_DATE` (value unused) |

## 12. Findings and decisions

1. **The RDF filter does not match the form.** `IMP.HQ_IMPR_NBR = :P_IMPR_NBR` is never sent by the form, so the RDF
   was always empty, and the line that used the form's list `CG$P_impr_nbr` is commented out. **User decision 2026-11-25:**
   the ARD package filters on the form's importer list (§2). This is a deliberate change from the RDF.
2. **`LICE_NO` was pasted into SQL unchanged** (lexical parameter). It is now checked to be digits and commas only
   (`LICE_NO_VALIDATION`, SUGGESTION), and the report reads it as numbers.
3. **User decision 2026-11-25:** ARD package only, with no RDF link. PRINT, CLEAR and BACK are the only page 0 buttons on report pages.
4. The Forms LOV form `REP_LOV_IMPR` (source not here) returned a list; the Popup LOV adds one importer per pick.
5. `V_NAMEFormula` / `v_name2Formula` have no exception handler in the RDF (kept). Called inside the query, a missing type
   gives an empty cell, where the RDF would have stopped with REP-1401.
