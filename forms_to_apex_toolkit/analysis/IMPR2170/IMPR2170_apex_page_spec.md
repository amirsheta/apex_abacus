# IMPR2170 – Analysis and APEX page spec (report parameter form)

Form `forms/IMPR/IMPR2170_fmb.xml` «تقرير حالة مستورد». It prints the report `forms/IMPR/reports/IMPR2170.xml`.
Package `IMPR2170` 001, page **2170**, generator `scripts/gen_apex_impr2170.py`. Date 2026-11-25. Nothing has been
compiled or imported.

**Template:** this is the report-screen pattern of IMPR2110 … IMPR2150 (`analysis/IMPR2110/IMPR2110_apex_page_spec.md`
§2, §12), built from the IMPR2150 generator. The differences are:
- the radio group `SELECT1` chooses between **one importer of a port** (1: `P_PORT_CD` + `IMPR_NBR`) and a
  **unified importer number** (2: `HQ_IMPR_NBR`); PU `ENB_DISP_FLDS` clears and enables the items of each choice;
- outside head office (user port ≠ 99) the radio group, the port and the unified number are hidden: `SELECT1` = 1 and the
  port is the user's port;
- before the report, PU `COUNT_SUSP1` runs 20 "is anything wrong with this importer" checks; if all are empty the form
  says «حالة المستورد سليمة» and prints nothing.

## 1. What the form does

A parameter screen with no base table. The user picks the choice, the port and importer (or the unified number), then
presses **طباعة [F4]** (`ITEM303`, PU `PRINT_CHECK_VAL`) or **عرض [F5]** (`ITEM304`, PU `CHECK_VAL`). Note: the keys are
swapped in Forms (`KEY-F4` runs CHECK_VAL, `KEY-F5` runs PRINT_CHECK_VAL). Both PUs check the required number, run
`COUNT_SUSP1`, and run `IMPR2170.REP` with `P_MODULE_NAME`, `P_CURR_PORT_CD`, `PPORT_CD`, `PSELECT1`, `PIMPR_NBR`,
`PHQ_IMPR_NBR`, `P_REPORT_NO` (and `P_TYPE` 0, not a report parameter).

| Block | Kind | Items |
|---|---|---|
| `CALLING_PARAMETERS` | control, 1 record | `SELECT1` (radio), `P_PORT_CD` (+ button `P_LOV_PORT`), `P_PORT_NAME`, `IMPR_NBR` (+ `LOV_IMPR`), `IMPR_NAME`, `HQ_IMPR_NBR` (+ `HQ_LOV_IMPR`), `HQ_IMPR_NAME` |
| `TITLE` (OLB) | header | `SCREEN_NAME`, `USER_NAME`, `SYSTEM_DATE`, `SYSTEM_G_DATE`, `REPORT_NO`, `P_CURR_PORT_NAME`, **`SHOW_USER`** (check box «اضافة اسم المستخدم») |
| `TOOLBAR` | buttons | `ITEM306` قائمة, `ITEM305` مسح, `ITEM303` طباعة, `ITEM304` عرض, `ITEM307` خروج |
| `ZATCA_LOGOS` (OLB) | logos | — |

## 2. Approach

1. **Report.** `IMPR2170_ARD` (`plsql/IMPR2170`), generated earlier by `scripts/gen_ard_impr_reports.py`; this conversion
   only changed its caller note (the `.pkb` is unchanged).
2. **Toolbar.** Page 0 shows only PRINT, CLEAR and BACK (`P2170_REPORT`).
3. **Print.** The custom event `REPORT_PRINT` runs FOS `IMPR2170.PRINT_CHECK_VAL`, which returns the ardpdf link from
   `PRINT_IMPR2170_ARD`; one line of JavaScript opens it in a new tab.
4. **Report server settings.** `ARD_URL` and `ARD_DSNAME` come from `SC_PORT_SETTING` (SYSOBJ_ID 999, PORT_CD 99).

| ARD parameter | RDF parameter | Value sent by the page |
|---|---|---|
| `P_PARAMETER1` | `P_CURR_PORT_CD` | `P_CURR_PORT_CD` (f345 application item) |
| `P_PARAMETER2` | `PPORT_CD` | `P2170_P_PORT_CD` (user port outside head office; empty for SELECT1 = 2) |
| `P_PARAMETER3` | `PSELECT1` | `P2170_SELECT1` (1 outside head office) |
| `P_PARAMETER4` | `PIMPR_NBR` | `P2170_IMPR_NBR` (empty for SELECT1 = 2) |
| `P_PARAMETER5` | `PHQ_IMPR_NBR` | `P2170_HQ_IMPR_NBR` (empty for SELECT1 = 1) |
| `P_PARAMETER6` | `P_MODULE_NAME` | `P2170_HERO_TITLE` |
| `P_PARAMETER7` | `P_REPORT_NO` | `P2170_REPORT_NO` |

**The count:** `COUNT_SUSP1` is kept exactly as in Forms (private, same name), following the IMPR2140 user decision of
2026-11-25. It is split into two private parts (`count_susp1_common` for checks 1–8, `count_susp1_waivers` for 11–16 /
21–26) so each member stays readable. See §12 for what looks wrong in it.

## 3. Page 2170 `IMPR2170`

Template *Zatca-Minimal_No_Navigation*, class `zf`, protection C, page group IMPR (IMPR1110). No search page, never
submits, no DML.

| Seq | Region (static id) | Type / template | Source |
|---|---|---|---|
| 10 | الهيدر (`TITLE`) | static, hero | module name, port name, report number (KPI) |
| 20 | معاملات التقرير (`CALLING_PARAMETERS`) | static, *Interactive Report* template, `zatca-forms cg-form cg-card` | block CALLING_PARAMETERS |

## 4. Items

"Head office only" = server-side condition `IMPR2170.P_PORT_CD_IS_VISIBLE(P_CURR_PORT_CD => :P_CURR_PORT_CD)`
(PU `ENB_DISP_FLDS`, branch port ≠ 99).

| Item | Type | Forms source | Notes |
|---|---|---|---|
| `P2170_SELECT1` | Radio group, STATIC2 جمرك محدد;1, جميع الجمارك;2, default 1, required, «نوع الاستعلام» | `SELECT1` (REP1 / REP2) | head office only; the label is new (Forms has none) |
| `P2170_P_PORT_CD` | Popup LOV `LOV_SD_PORTS` (IMPR1110), «رمز الجمرك» | `P_PORT_CD`, `P_LOV_PORT` (REP_LOV_SD_PORTS) | head office only |
| `P2170_P_PORT_NAME` | Display only | `P_PORT_NAME` | head office only |
| `P2170_IMPR_NBR` | Popup LOV `LOV_IMPR2170_LOV_IMPR_NBR`, «رقم المستورد / المصدر» | `IMPR_NBR`, `LOV_IMPR` (PU CHECK_LIST_VAL → LOV_IMPR_NBR) | LOV Items to Submit `P2170_P_PORT_CD` |
| `P2170_IMPR_NAME` | Display only | `IMPR_NAME` | set by DA |
| `P2170_HQ_IMPR_NBR` | Popup LOV `LOV_IMPORT_HQ_NBR` (IMPR2150), «الرقم الموحد للمستورد / المصدر» | `HQ_IMPR_NBR`, `HQ_LOV_IMPR` (PU CHECK_LIST_VAL → LOV_IMPR_NBR) | head office only; disabled while SELECT1 = 1 |
| `P2170_HQ_IMPR_NAME` | Display only | `HQ_IMPR_NAME` | head office only |
| `P2170_HERO_TITLE` | Hidden | `TITLE.SCREEN_NAME` (`P_MODULE_NAME`) | sent as P_MODULE_NAME |
| `P2170_MODULE_ID` | Hidden | `:PARAMETER.P_MODULE_ID` | f345 |
| `P2170_REPORT_NO` | Hidden (hero) | `TITLE.REPORT_NO` = `P_SYS_ID-P_REP_NO` | from `SC_PORT_SETTING` |
| `P2170_P_CURR_PORT_NAME` | Hidden (hero) | `TITLE.P_CURR_PORT_NAME` | |
| `P2170_REPORT` | Hidden, no value | — | report-page flag |
| `P2170_REPORT_URL` | Hidden, not protected | `REP.Run_Product` | returned by FOS |

`TITLE.SHOW_USER` is **not converted** (§12 item 1).

## 6. LOVs

- **`LOV_IMPR2170_LOV_IMPR_NBR`** (new, id base 9217) =
  `LOV_APX.IMPORTERS(P_PORT_ITEM => 'P2170_P_PORT_CD', P_DEFAULT_PORT_ITEM => 'P_CURR_PORT_CD')`, columns D (number),
  ARBC_IMPR_NAME, BUS_ID. Page-specific because the call names the port item (as `LOV_IMPR2140_REP_IMPR`). No LOV_APX change.
- **`LOV_SD_PORTS`** (IMPR1110) and **`LOV_IMPORT_HQ_NBR`** (IMPR2150, `LOV_APX.SINGLE_IMPORTERS`) are reused.

## 8. Processes (Before Header)

The five processes of IMPR2150: `New` (Never), `P0_PAGE_PK CHECK`, `PARAMETERS` (`GET_MODULE_ID … 'IMPR2170'`),
`WHEN-NEW-FORM-INSTANCE` and `HEADER TITLE` (default «تقرير حالة مستورد»).

No validations: the page never submits. `PRINT_CHECK_VAL` repeats every check (SELECT1, port, numbers).

## 10. Dynamic actions

| Name | Event | Actions |
|---|---|---|
| `SELECT1 WHEN-RADIO-CHANGED` | change + page load, client condition SELECT1 = 2 | TRUE: Clear port / port name / importer / name, Disable port + importer, Enable HQ. FALSE: Clear HQ + name, Enable port + importer, Disable HQ |
| `P_PORT_CD WHEN-VALIDATE-ITEM` | change | Clear name; FOS `P_PORT_CD_WHEN_VALIDATE_ITEM` (returns P_PORT_NAME) |
| `IMPR_NBR WHEN-VALIDATE-ITEM` | change | Clear name; FOS `IMPR_NBR_WHEN_VALIDATE_ITEM` (returns IMPR_NBR, cleared when unknown, and IMPR_NAME) |
| `HQ_IMPR_NBR WHEN-VALIDATE-ITEM` | change | Clear name; FOS `HQ_IMPR_NBR_WHEN_VALIDATE_ITEM` (returns HQ_IMPR_NAME) |
| `REPORT_PRINT` | custom (page 0) | Clear URL; FOS `PRINT_CHECK_VAL`; one-line JS that opens the link |

## 11. Trace (every Forms object)

| Forms object | Target / rationale |
|---|---|
| SELECT1 (radio), SELECT1 WHEN-RADIO-CHANGED, CALLING_PARAMETERS WHEN-NEW-RECORD-INSTANCE, PU ENB_DISP_FLDS | Radio group + `SELECT1_VALIDATION`; DA `SELECT1 WHEN-RADIO-CHANGED`; port ≠ 99 branch → item conditions `P_PORT_CD_IS_VISIBLE` + `PRINT_CHECK_VAL` (SELECT1 = 1, port = user port); `GO_ITEM` not needed |
| P_PORT_CD KEY-LISTVAL, P_LOV_PORT WHEN-BUTTON-PRESSED (REP_LOV_SD_PORTS, `:GLOBAL.PORT_CD / PORT_NAME`) | Popup LOV `LOV_SD_PORTS` |
| P_PORT_CD WHEN-VALIDATE-ITEM | `P_PORT_CD_VALIDATION`, `P_PORT_CD_WHEN_VALIDATE_ITEM`, DA |
| IMPR_NBR KEY-LISTVAL, LOV_IMPR WHEN-BUTTON-PRESSED, HQ_IMPR_NBR KEY-LISTVAL, HQ_LOV_IMPR WHEN-BUTTON-PRESSED, PU CHECK_LIST_VAL (LOV_IMPR_NBR, `:GLOBAL.PORT_CD / IMPR_NBR / IMPR_NAME / HQ_IMPR_NBR`) | Popup LOVs `LOV_IMPR2170_LOV_IMPR_NBR` / `LOV_IMPORT_HQ_NBR`; the DAs fill the names |
| IMPR_NBR WHEN-VALIDATE-ITEM | `IMPR_NBR_WHEN_VALIDATE_ITEM`, DA |
| HQ_IMPR_NBR WHEN-VALIDATE-ITEM, PU GET_HQ_IMPR_NAME | `HQ_IMPR_NBR_WHEN_VALIDATE_ITEM`, DA |
| IMPR_NAME / HQ_IMPR_NAME WHEN-VALIDATE-ITEM, KEY-LISTVAL | dropped: empty triggers |
| TITLE.SHOW_USER | **not converted**: `TODO: MISSING SOURCE IMPR2170n.rep` (§12 item 1) |
| TITLE.SYSTEM_DATE / SYSTEM_G_DATE WHEN-VALIDATE-ITEM, TITLE.USER_NAME | dropped: display items / f345 shell |
| TOOLBAR.ITEM304 (عرض), KEY-F4, PU CHECK_VAL | page 0 طباعة (REPORT_SHOW Never, DEC-018); same PDF |
| TOOLBAR.ITEM303 (طباعة), KEY-F5, PU PRINT_CHECK_VAL | DA `REPORT_PRINT`, `IMPR2170.PRINT_CHECK_VAL` |
| KEY-PRINT | NULL in Forms → nothing |
| PU COUNT_SUSP1 | private `COUNT_SUSP1` (+ `count_susp1_common`, `count_susp1_waivers`) |
| PU COUNT_SUSP1_OLD | dropped: not called anywhere |
| REP.Run_Product (IMPR2170.REP) | `PRINT_IMPR2170_ARD` |
| Report IMPR2170.rdf | `IMPR2170_ARD` (generated earlier; caller note updated) |
| TOOLBAR.ITEM305 (مسح) | page 0 CLEAR |
| TOOLBAR.ITEM306 (قائمة) / ITEM307 (خروج), KEY-NEXT-ITEM of the buttons | Popup LOV button / page 0 BACK / none |
| WHEN-NEW-FORM-INSTANCE | process + `WHEN_NEW_FORM_INSTANCE`; `:SELECT1 := 1` → item default |
| PRE-FORM, WHEN-WINDOW-ACTIVATED | dropped: window, icon and date format (f345 shell) |
| PU LOAD_ZATCA_LOGOS, block ZATCA_LOGOS | f345 hero / theme |
| Alerts CFG_*, USR_*, CG$ASK_COMMIT | not used by this form's code (STR.DISPALERT → `FORMS_APX.CHECK_ERROR`) |
| Module parameters | `P_MODULE_ID` → item; `P_SYS_ID`, `P_REP_NO` → `SC_PORT_SETTING`; `P_CURR_PORT_CD` → f345 app item; `P_MODULE_NAME` → hero title; `P_REPORT_PATH` / `P_REPORT_FILE` → ARD; the others unused |

## 12. Findings and decisions

1. **`SHOW_USER` / IMPR2170n.rep — open item.** With the check box ticked, both PUs ran `IMPR2170n.rep` instead of
   `IMPR2170.rep`. That report is not in `forms/IMPR/reports`, so there is nothing to convert. The check box is left out of
   the page. **Decision needed:** supply IMPR2170n.rdf (then a second ARD package and a check box are added), or confirm it
   can be dropped.
2. **Importer LOV picks the port first.** Forms' LOV form `LOV_IMPR_NBR` listed importers of every port and also returned
   the port. A 21.2 Popup LOV returns one value, so the page lists the importers of the chosen port (else of the user's
   port), as IMPR2140. A head-office user picks the port, then the importer.
3. **Port required for SELECT1 = 1 (SUGGESTION, new check).** Every count check and the report need
   `IMPR_NBR AND PORT_CD = :P_PORT_CD`; with an empty port Forms always said «حالة المستورد سليمة». `PRINT_CHECK_VAL` now
   asks for the port. An unknown port gives «رمز الجمرك غير صحيح» (Forms: unhandled ORA-01403).
4. **`COUNT_SUSP1` is kept as in Forms; confirm with the business owner:**
   - the date tests use `TO_CHAR(…, 'YYYY-MM-MI')`: MI is **minutes**, so they compare year-month only (probably meant `DD`);
   - checks 14 / 24 compare `DCRE_EXPR_DATE > TO_CHAR(XDT, 'YYYY-MM-MI')`; if the column is a DATE, Oracle converts the text
     with the session NLS_DATE_FORMAT, which most likely fails (day `00`), and the check silently counts 0;
   - checks 7 and 8 test `IMP.IMPR_NBR` / `IMP.HQ_IMPR_NBR` in the inner EXISTS, where all the others use `I.`;
   - each check swallows every error (`WHEN OTHERS THEN NULL`), so a broken check just says "clean".
5. **«حالة المستورد سليمة» is shown as an error**, as in Forms (`STR.DISPALERT(…, 'ERROR')`), and no PDF opens.
6. **`IMPR_NBR` behaviour.** Unknown number: cleared without a message, as in Forms. The same number in several ports with no
   port chosen: Forms opened the LOV (TOO_MANY_ROWS); here the first name is shown (SUGGESTION).
7. **`HQ_IMPR_NBR` name (SUGGESTION).** `GET_HQ_IMPR_NAME` wrote the IMPORTERS name into `IMPR_NAME`, the field of the other
   choice; here it goes to `HQ_IMPR_NAME`. An unknown number is accepted without a message, as in Forms. The LOV lists
   `SINGLE_IMPORTERS` (`LOV_IMPORT_HQ_NBR`); Forms' LOV form listed `IMPORTERS` rows.
8. **Report filter at head office.** The ARD (from the RDF) filters `imp.PORT_CD = P_CURR_PORT_CD`, so at head office (99)
   it shows only importers registered under port 99. This is the RDF as written; check it in the first test.
9. **Function keys are swapped in Forms** (`KEY-F4` = عرض, `KEY-F5` = طباعة, opposite to the button labels). There are no
   keyboard shortcuts in APEX, so it does not matter here.
10. **Shared-component id base 9217.** The generator's self-check found no id clash with any export.
