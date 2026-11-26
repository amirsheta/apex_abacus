# IMPR2310 – Analysis and APEX page spec (report parameter form)

Form `forms/IMPR/IMPR2310_fmb.xml` «بيانات المستوردين المعدلة / المضافة». It prints the report `forms/IMPR/reports/IMPR2310.xml`.
Package `IMPR2310` 001, page **2310**, generator `scripts/gen_apex_impr2310.py`. Date 2026-11-26. Nothing has been
compiled or imported.

**Template:** the report-screen pattern of IMPR2110 … IMPR2230 (`analysis/IMPR2110/IMPR2110_apex_page_spec.md` §2, §12),
built from the IMPR2170 generator (radio group + Enable / Disable). The Hijri date items follow IMPR1160 `AWARD_DATE`.
The differences are:
- the radio group `REPORT` chooses the **modified** (0) or the **added** (1) importers of the journal
  `JOURNAL.IMPORTERS_JN`;
- the radio group `SELECT1` chooses **one importer** (1: `IMPR_NBR`) or a **support letter / period** (2: `LTR_NBR`,
  `LTR_DATE`, `SUPP_SRCE_CD`, `START_DT`, `END_DT`). The form opens with 2;
- the port `P_PORT_CD` is shown to head office only (user port 99), as in IMPR2130.

## 1. What the form does

A parameter screen with no base table. The user picks the report type, the choice and its values, then presses
**طباعة** (`ITEM303`, PU `PRINT_CHECK_VAL`, KEY-F5) or **عرض** (`ITEM304`, PU `CHECK_VAL`, KEY-F4). Both PUs (same code
except DESTYPE) check the required values, count the matching journal rows, and run `IMPR2310.rep` with `P_MODULE_NAME`,
`P_CURR_PORT_CD` (= `:P_PORT_CD`), `SELECT1`, `REPORT1` (= `:REPORT`), `P_IMPR_NBR`, `LTR_NBR`, `LTR_DATE`,
`SUPP_SRCE_CD`, `START_DT`, `END_DT` (dates `MI-MM-RRRR`) and `P_REPORT_NO`.

| Block | Kind | Items |
|---|---|---|
| `CALLING_PARAMETERS` | control, 1 record | `P_PORT_CD` (+ button `P_LOV_PORT`), `P_PORT_NAME`, `REPORT` (radio), `SELECT1` (radio), `LTR_NBR`, `LTR_DATE`, `SUPP_SRCE_CD`, `START_DT`, `END_DT`, `IMPR_NBR` (+ `LOV_IMPR`), `IMPR_NAME` |
| `TITLE` (OLB) | header | `SCREEN_NAME`, `USER_NAME`, `SYSTEM_DATE`, `SYSTEM_G_DATE`, `REPORT_NO`, `P_CURR_PORT_NAME` |
| `TOOLBAR` | buttons | `ITEM306` قائمة, `ITEM305` مسح, `ITEM303` طباعة, `ITEM304` عرض, `ITEM307` خروج |
| `ZATCA_LOGOS` (OLB) | logos | — |

## 2. Approach

1. **Report.** `IMPR2310_ARD` (`plsql/IMPR2310`), generated earlier by `scripts/gen_ard_impr_reports.py`. This conversion
   only changed its caller note; the `_body.sql` is unchanged.
2. **Toolbar.** Page 0 shows only PRINT, CLEAR and BACK. The flag item `P2310_REPORT` is the Forms radio group `REPORT`
   itself: `scripts/report_toolbar.py` only tests that `P<page>_REPORT` exists, so the Forms name is kept and no separate
   hidden flag is added.
3. **Print.** The custom event `REPORT_PRINT` runs FOS `IMPR2310.PRINT_CHECK_VAL`, which returns the ardpdf link from
   `PRINT_IMPR2310_ARD`; one line of JavaScript opens it in a new tab.
4. **Report server settings.** `ARD_URL` and `ARD_DSNAME` come from `SC_PORT_SETTING` (SYSOBJ_ID 999, PORT_CD 99).

| ARD parameter | RDF parameter | Value sent by the page |
|---|---|---|
| `P_PARAMETER1` | `P_CURR_PORT_CD` | `P_CURR_PORT_CD` outside head office; at head office `P2310_P_PORT_CD`, else 99 (as IMPR2130) |
| `P_PARAMETER2` | `SELECT1` | `P2310_SELECT1` |
| `P_PARAMETER3` | `REPORT1` | `P2310_REPORT` |
| `P_PARAMETER4` | `P_IMPR_NBR` | `P2310_IMPR_NBR` (empty for SELECT1 = 2) |
| `P_PARAMETER5` | `LTR_NBR` | `P2310_LTR_NBR` (empty for SELECT1 = 1) |
| `P_PARAMETER6` | `LTR_DATE` | `P2310_LTR_DATE` as `YYYY-MM-MI` |
| `P_PARAMETER7` | `SUPP_SRCE_CD` | `P2310_SUPP_SRCE_CD` |
| `P_PARAMETER8` | `START_DT` | `P2310_START_DT` as `YYYY-MM-MI` |
| `P_PARAMETER9` | `END_DT` | `P2310_END_DT` as `YYYY-MM-MI` |
| `P_PARAMETER10` | `P_MODULE_NAME` | `P2310_HERO_TITLE` |
| `P_PARAMETER11` | `P_REPORT_NO` | `P2310_REPORT_NO` |

**The count:** kept exactly as in Forms (private `journal_count`), following the IMPR2140 user decision of 2026-11-25.
See §12 for how it differs from the report.

## 3. Page 2310 `IMPR2310`

Template *Zatca-Minimal_No_Navigation*, class `zf`, protection C, page group IMPR (IMPR1110). No search page, never
submits, no DML.

| Seq | Region (static id) | Type / template | Source |
|---|---|---|---|
| 10 | الهيدر (`TITLE`) | static, hero | module name, port name, report number (KPI) |
| 20 | معاملات التقرير (`CALLING_PARAMETERS`) | static, *Interactive Report* template, `zatca-forms cg-form cg-card` | block CALLING_PARAMETERS |

## 4. Items

"Head office only" = server-side condition `IMPR2310.P_PORT_CD_IS_VISIBLE(P_CURR_PORT_CD => :P_CURR_PORT_CD)`
(WHEN-NEW-FORM-INSTANCE, branch port ≠ 99). Hijri date = Text Field, format mask `&P2310_HIJRI_DATE_FORMAT.`, class
`hijri-date-default` (f345 Hijri picker), placeholder «سنة-شهر-يوم».

| Item | Type | Forms source | Notes |
|---|---|---|---|
| `P2310_SELECT1` | Radio group, STATIC2 حسب رقم المستورد;1, حسب الخطاب;2, default **2**, required, «نوع الاستعلام» | `SELECT1` (S1 / S2) | default 2 = `:SELECT1 := 2` of WHEN-NEW-FORM-INSTANCE; the label is new |
| `P2310_REPORT` | Radio group, STATIC2 تعديلات بيانات المستوردين;0, إضافة مستوردين جدد;1, default 0, required, «نوع التقرير» | `REPORT` (REP1 / REP2) | also the report-page flag (§2); the label is new |
| `P2310_P_PORT_CD` | Popup LOV `LOV_SD_PORTS` (IMPR1110), «رمز الجمرك» | `P_PORT_CD`, `P_LOV_PORT` (REP_LOV_SD_PORTS) | head office only |
| `P2310_P_PORT_NAME` | Display only | `P_PORT_NAME` | head office only |
| `P2310_LTR_NBR` | Text, 60, «رقم الخطاب» | `LTR_NBR` | disabled while SELECT1 = 1 |
| `P2310_LTR_DATE` | Hijri date, «تاريخ الخطاب» | `LTR_DATE` | disabled while SELECT1 = 1 |
| `P2310_SUPP_SRCE_CD` | Number (`number_only`), «جهة الخطاب» | `SUPP_SRCE_CD` | port of the letter; disabled while SELECT1 = 1 |
| `P2310_START_DT` | Hijri date, «من تاريخ» | `START_DT` | disabled while SELECT1 = 1 |
| `P2310_END_DT` | Hijri date, «إلى تاريخ» | `END_DT` | disabled while SELECT1 = 1 |
| `P2310_IMPR_NBR` | Popup LOV `LOV_IMPR2310_LOV_IMPR`, «رقم المستورد الجمركي» | `IMPR_NBR`, `LOV_IMPR` (PU CHECK_LIST_VAL → LOV_IMPR) | LOV Items to Submit `P2310_P_PORT_CD`; disabled while SELECT1 = 2 |
| `P2310_IMPR_NAME` | Display only | `IMPR_NAME` | set by DA |
| `P2310_HERO_TITLE` | Hidden | `TITLE.SCREEN_NAME` (`P_MODULE_NAME`) | sent as P_MODULE_NAME |
| `P2310_MODULE_ID` | Hidden | `:PARAMETER.P_MODULE_ID` | f345 |
| `P2310_REPORT_NO` | Hidden (hero) | `TITLE.REPORT_NO` = `P_SYS_ID-P_REP_NO` | from `SC_PORT_SETTING` |
| `P2310_P_CURR_PORT_NAME` | Hidden (hero) | `TITLE.P_CURR_PORT_NAME` | |
| `P2310_HIJRI_DATE_FORMAT` | Hidden | — | computation `FORMS_APX.HIJRI_DATE_FORMAT` (§9) |
| `P2310_REPORT_URL` | Hidden, not protected | `REP.Run_Product` | returned by FOS |

## 6. LOVs

- **`LOV_IMPR2310_LOV_IMPR`** (new, id base 9231) =
  `LOV_APX.IMPORTERS(P_PORT_ITEM => 'P2310_P_PORT_CD', P_DEFAULT_PORT_ITEM => 'P_CURR_PORT_CD')`, columns D (number),
  ARBC_IMPR_NAME, BUS_ID. Page-specific because the call names the port item (as `LOV_IMPR2170_LOV_IMPR_NBR`). No
  LOV_APX change.
- **`LOV_SD_PORTS`** (IMPR1110) is reused.

## 8. Processes (Before Header)

The five processes of IMPR2170: `New` (Never), `P0_PAGE_PK CHECK`, `PARAMETERS` (`GET_MODULE_ID … 'IMPR2310'`),
`WHEN-NEW-FORM-INSTANCE` and `HEADER TITLE` (default «بيانات المستوردين المعدلة / المضافة»).

No validations: the page never submits. `PRINT_CHECK_VAL` repeats every check (radio values, port, dates, required values).

## 9. Computations

| Item | Point | Expression |
|---|---|---|
| `P2310_HIJRI_DATE_FORMAT` | Before Header | `FORMS_APX.HIJRI_DATE_FORMAT` (Application Setting HIJRI_DATE_FORMAT, default YYYY-MM-MI) |

## 10. Dynamic actions

| Name | Event | Actions |
|---|---|---|
| `SELECT1 WHEN-RADIO-CHANGED` | change + page load, client condition SELECT1 = 2 | TRUE: Clear IMPR_NBR / IMPR_NAME, Disable IMPR_NBR, Enable the 5 letter / period items. FALSE: Clear the 5 items, Disable them, Enable IMPR_NBR |
| `P_PORT_CD WHEN-VALIDATE-ITEM` | change | Clear name; FOS `P_PORT_CD_WHEN_VALIDATE_ITEM` (returns P_PORT_NAME) |
| `LTR_DATE WHEN-VALIDATE-ITEM`, `START_DT …`, `END_DT …` | change, only when not empty | FOS `FORMS_APX.CHECK_ERROR(FORMS_APX.HIJRI_DATE_ERROR(:P2310_<ITEM>))` (as IMPR1160) |
| `IMPR_NBR WHEN-VALIDATE-ITEM` | change | Clear name; FOS `IMPR_NBR_WHEN_VALIDATE_ITEM` (returns IMPR_NBR, cleared when unknown, and IMPR_NAME) |
| `REPORT_PRINT` | custom (page 0) | Clear URL; FOS `PRINT_CHECK_VAL`; one-line JS that opens the link |

## 11. Trace (every Forms object)

| Forms object | Target / rationale |
|---|---|
| SELECT1 (radio), SELECT1 WHEN-RADIO-CHANGED | Radio group + `SELECT1_VALIDATION`; DA `SELECT1 WHEN-RADIO-CHANGED`; `GO_ITEM` not needed |
| REPORT (radio) | Radio group `P2310_REPORT` + `REPORT_VALIDATION` |
| P_PORT_CD KEY-LISTVAL, P_LOV_PORT WHEN-BUTTON-PRESSED (REP_LOV_SD_PORTS, `:GLOBAL.PORT_CD / PORT_NAME`) | Popup LOV `LOV_SD_PORTS` |
| P_PORT_CD WHEN-VALIDATE-ITEM | `P_PORT_CD_VALIDATION`, `P_PORT_CD_WHEN_VALIDATE_ITEM`, DA |
| LTR_NBR KEY-LISTVAL, SUPP_SRCE_CD KEY-LISTVAL (PU CHECK_LIST_VAL) | **not converted** (§12 item 3) |
| LTR_DATE / START_DT / END_DT WHEN-VALIDATE-ITEM (OLB, no code in the XML) | DAs with `FORMS_APX.HIJRI_DATE_ERROR`; checked again in `PRINT_CHECK_VAL` |
| LTR_DATE / START_DT / END_DT KEY-LISTVAL (OLB calendar) | f345 Hijri picker (`hijri-date-default`) |
| IMPR_NBR KEY-LISTVAL, LOV_IMPR WHEN-BUTTON-PRESSED, PU CHECK_LIST_VAL (LOV_IMPR, `:GLOBAL.IMPR_NBR / IMPR_NAME`) | Popup LOV `LOV_IMPR2310_LOV_IMPR`; the DA fills the name |
| IMPR_NBR WHEN-VALIDATE-ITEM | `IMPR_NBR_WHEN_VALIDATE_ITEM`, DA |
| IMPR_NAME WHEN-VALIDATE-ITEM, KEY-LISTVAL (OLB, no code) | dropped |
| TITLE.SYSTEM_DATE / SYSTEM_G_DATE WHEN-VALIDATE-ITEM, TITLE.USER_NAME | dropped: display items / f345 shell |
| TOOLBAR.ITEM304 (عرض), KEY-F4, PU CHECK_VAL | page 0 طباعة (REPORT_SHOW Never, DEC-018); same PDF |
| TOOLBAR.ITEM303 (طباعة), KEY-F5, PU PRINT_CHECK_VAL | DA `REPORT_PRINT`, `IMPR2310.PRINT_CHECK_VAL` (count = private `journal_count`) |
| KEY-PRINT | NULL in Forms → nothing |
| REP.Run_Product (IMPR2310.rep) | `PRINT_IMPR2310_ARD` |
| Report IMPR2310.rdf | `IMPR2310_ARD` (generated earlier; caller note updated) |
| TOOLBAR.ITEM305 (مسح) | page 0 CLEAR |
| TOOLBAR.ITEM306 (قائمة) / ITEM307 (خروج), KEY-NEXT-ITEM of the buttons | Popup LOV button / page 0 BACK / none |
| WHEN-NEW-FORM-INSTANCE | process + `WHEN_NEW_FORM_INSTANCE`; `:SELECT1 := 2` → item default; Enable / Disable → DA on page load; port ≠ 99 → `P_PORT_CD_IS_VISIBLE` + `report_port` |
| PRE-FORM, WHEN-WINDOW-ACTIVATED | dropped: window, icon and date format (f345 shell) |
| PU LOAD_ZATCA_LOGOS, block ZATCA_LOGOS | f345 hero / theme |
| Alerts CFG_*, USR_*, CG$ASK_COMMIT | not used by this form's code (STR.DISPALERT → `FORMS_APX.CHECK_ERROR`) |
| Module parameters | `P_MODULE_ID` → item; `P_SYS_ID`, `P_REP_NO` → `SC_PORT_SETTING`; `P_CURR_PORT_CD` → f345 app item; `P_MODULE_NAME` → hero title; `P_REPORT_PATH` / `P_REPORT_FILE` → ARD; the others unused |

## 12. Findings and decisions

1. **The count and the report filter differently (SUGGESTION, kept as in Forms).** The Forms count has its port line
   commented out, so it counts journal rows of **every** port; the report filters `IMP.PORT_CD = P_CURR_PORT_CD`. So a
   match in another port passes the count and then prints an empty report. Kept as in Forms, as the IMPR2140 decision.
   Adding the port to the count would make them agree.
2. **Port sent to the report.** Forms sent `:P_PORT_CD`, which is empty for a head-office user who picks no port, and
   then the report shows nothing. The page sends `NVL(P_PORT_CD, P_CURR_PORT_CD)` (99 at head office), as IMPR2130.
3. **`LTR_NBR` / `SUPP_SRCE_CD` KEY-LISTVAL not converted.** Both call PU `CHECK_LIST_VAL`, the importer LOV. It writes
   `IMPR_NBR` / `IMPR_NAME`, which are disabled while these items are enabled, so it looks like a copy-paste slip. They
   stay plain entry items. SUGGESTION: `SUPP_SRCE_CD` is a port (the report shows its `SD_PORTS` name), so a Popup LOV on
   `LOV_SD_PORTS` would fit if the business owner wants one.
4. **Importer LOV per port (SUGGESTION).** The LOV form `LOV_IMPR` got no port and listed every port. The page lists the
   importers of the port the report filters on, `NVL(P_PORT_CD, P_CURR_PORT_CD)`, as IMPR2170 / IMPR2210.
   `IMPR_NBR_WHEN_VALIDATE_ITEM` still looks the number up in every port (its port line is commented out in Forms). If the
   number is in several ports, Forms opened the LOV (TOO_MANY_ROWS); here the first name is shown. An unknown number is
   cleared without a message, as in Forms.
5. **Missing values stop the print.** For «الرجاء تحديد رقم المستورد» and «الرجاء إدخال بيانات الخطاب أو الفترة», Forms
   showed a MESSAGE and printed nothing. Here the same text is an error and no tab opens.
6. **Dates.** The letter date is compared with `TO_CHAR(…, 'RRRR-MM-MI')`, as in Forms and the RDF. In this project the
   Hijri day is held in the minute field (memory: HIJRI_DATE_FORMAT `YYYY-MM-MI`), so this compares year, month and day.
   The dates go to the ARD as `YYYY-MM-MI` (Forms sent `MI-MM-RRRR`; IMPR2310_ARD reads `YYYY-MM-MI`). There is no
   START_DT ≤ END_DT check, as in Forms.
7. **Radio values are checked server-side (SUGGESTION, new check).** A Forms radio group allows only its values; an APEX
   item can be posted with any value, so `SELECT1_VALIDATION` / `REPORT_VALIDATION` check them.
8. **Grants.** `LIB_APX_USR` needs SELECT on `JOURNAL.IMPORTERS_JN` (owned by another schema) for the count.
9. **Shared-component id base 9231** (page-digit pattern). The generator's self-check found no id clash with any export.
