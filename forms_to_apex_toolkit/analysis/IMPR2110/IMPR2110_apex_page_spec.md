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

## 2. Approach: the report page pattern

`RUN_REPORT_OBJECT` / `REP.Run_Product` is a decision point in CLAUDE.md §7. This repository has no report
screen yet. The approved standard of the same project (Forms_to_APEX `03_Design/Standards/APPROVED_STANDARD.md`
13-b) and the real 21.2 export f202604 (page 2100 `REPR2100`) already define one, and it is used here:

* The page has a hidden item `P2110_REPORT`. Page 0 of f345 then shows `REPORT_SHOW` / `REPORT_PRINT` and hides `FUNCS`.
* Each page 0 button fires a custom event on `document`. The page has one DA per event: Clear `P2110_REPORT_URL`,
  then FOS `IMPR2110.CHECK_VAL` / `PRINT_CHECK_VAL` (same checks as Forms), which returns the URL, then one line
  of JavaScript that opens it in a new tab.
* `PRINT_IMPR2110` builds `IMPR2110.rdf&paramform=no&DESTYPE=…&<parameters>` and returns
  `SC_PORT_SETTINGS_PKG.GET_SC_PORT_REPORT_URL(<user port>, 23, …)`. The RDF on the Reports Server stays the
  report; its layout is not rewritten here. The ARD conversion (standard 13-c) is a separate task.

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
| `P2110_LICE_NO` | Text field (2000) | `LICE_NO` | importer numbers, comma separated; empty = all importers of the port |
| `P2110_SECT_LOV` | Popup LOV `LOV_REP_IMPR` | button `SECT_LOV`, `LICE_NO` KEY-LISTVAL (REP_LOV_IMPR) | the pick is added to `LICE_NO` |
| `P2110_HERO_TITLE` | Hidden | `TITLE.SCREEN_NAME` (`P_MODULE_NAME`) | sent as report `P_MODULE_NAME` |
| `P2110_MODULE_ID` | Hidden | `:PARAMETER.P_MODULE_ID` | f345 |
| `P2110_REPORT_NO` | Hidden (hero) | `TITLE.REPORT_NO` = `P_SYS_ID-P_REP_NO` | values from `SC_PORT_SETTING` |
| `P2110_P_CURR_PORT_NAME` | Hidden (hero) | `TITLE.P_CURR_PORT_NAME` | |
| `P2110_REPORT` | Hidden, no value | — | report-page flag for page 0 |
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
| `LICE_NO WHEN-VALIDATE-ITEM` | change | FOS `CHECK_ERROR(LICE_NO_VALIDATION)`, Refresh CTR_BLK |
| `SECT_LOV WHEN-BUTTON-PRESSED` | change, not null | FOS `SECT_LOV_WHEN_BUTTON_PRESSED` (returns LICE_NO, clears the pick), Refresh CTR_BLK |
| `REPORT_SHOW` | custom (page 0) | Clear URL, FOS `CHECK_VAL`, JS open URL (1 line) |
| `REPORT_PRINT` | custom (page 0) | Clear URL, FOS `PRINT_CHECK_VAL`, JS open URL (1 line) |

The two JavaScript actions are one line each (CLAUDE.md §4c allows up to 3). They are needed because no
native action opens a URL in a new tab. This is the f202604 / standard 13-b pattern.

## 11. Trace (every Forms object)

| Forms object | Target / rationale |
|---|---|
| P_PORT_CD KEY-LISTVAL, P_LOV_PORT WHEN-BUTTON-PRESSED | Popup LOV `LOV_SD_PORTS` |
| P_PORT_CD WHEN-VALIDATE-ITEM | `P_PORT_CD_VALIDATION`, `P_PORT_CD_WHEN_VALIDATE_ITEM`, DA |
| LICE_NO KEY-LISTVAL, SECT_LOV WHEN-BUTTON-PRESSED | `P2110_SECT_LOV` + `SECT_LOV_WHEN_BUTTON_PRESSED` |
| LICE_NO WHEN-VALIDATE-ITEM | name column of CTR_BLK (message only in Forms) + new list check |
| CTR_BLK WHEN-NEW-BLOCK-INSTANCE | CTR_BLK grid SQL |
| TITLE.SYSTEM_DATE / SYSTEM_G_DATE WHEN-VALIDATE-ITEM | dropped: display items, never entered |
| TOOLBAR.VIEW, KEY-F5, PU CHECK_VAL | DA `REPORT_SHOW`, `IMPR2110.CHECK_VAL` |
| TOOLBAR.PRINT, KEY-PRINT, KEY-F4, PU PRINT_CHECK_VAL | DA `REPORT_PRINT`, `IMPR2110.PRINT_CHECK_VAL` |
| REP.Run_Product | `IMPR2110.PRINT_IMPR2110` |
| TOOLBAR.CLEAR / LOV / EXIT | page 0 CLEAR / Popup LOV buttons / BACK |
| WHEN-NEW-FORM-INSTANCE | process + `WHEN_NEW_FORM_INSTANCE`, item condition `P_PORT_CD_IS_VISIBLE` |
| PRE-FORM, WHEN-WINDOW-ACTIVATED | dropped: window, icon, date format (f345 shell) |
| PU P_ORDER | dropped: body commented out (NULL) |
| PU CGDV$POPULATE_DYNAMIC_LISTS | dropped: fills a non-existent item, call commented out |
| PU LOAD_ZATCA_LOGOS, block ZATCA_LOGOS | f345 hero / theme |
| Alerts CFG_*, USR_*, CG$ASK_COMMIT | not used by this form's code (STR.DispAlert texts only in LOV parameter-list errors, dropped with CALL_FORM) |
| Module parameters | `P_MODULE_ID` → item; `P_SYS_ID`, `P_REP_NO`, `P_REPORT_FILE` → `SC_PORT_SETTING`; `P_CURR_PORT_CD` → f345 app item; `P_REPORT_PATH` → Reports Server; others unused |
| Libraries OFGTEL, OFGMES, OFGHPL, D2KWUTIL, CIC_LIB, CIC_AMSG, SEC_LIB, OFGBSL, CAPTION | no call from this form's code except `HIJDATE.CUR_HIJ_DATE` (value unused) |

## 12. Findings for the business owner

1. **The report filter does not match the form.** The RDF query filters `IMP.HQ_IMPR_NBR = :P_IMPR_NBR`, but the
   form never sends `P_IMPR_NBR`, so the report gets `NULL` and returns no rows. The form's filter is the lexical
   `CG$P_impr_nbr` (`AND IMP.IMPR_NBR in (…)`), and the line that used it in the RDF is commented out. The
   conversion sends exactly what the form sends; the RDF was not changed. Please check the RDF deployed on the
   Reports Server (it may differ from this XML).
2. **`LICE_NO` was pasted into SQL unchanged** (lexical parameter). `LICE_NO_VALIDATION` now accepts only digits and
   commas. This is a new check, marked SUGGESTION.
3. `PRINTJOB`, `MAXIMIZE` and `ORACLE_SHUTDOWN` are not sent: they are Reports Runtime client options. `DESTYPE=PRINTER` prints
   on the Reports Server's printer (`DESNAME` was already empty in Forms).
4. The Forms LOV form `REP_LOV_IMPR` (source not here) returned a list; the Popup LOV adds one importer per pick.
