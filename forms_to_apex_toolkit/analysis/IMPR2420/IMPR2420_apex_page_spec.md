# IMPR2420 – Analysis and APEX page spec (report parameter form)

Form `forms/IMPR/IMPR2420_fmb.xml` «تقرير أخطاء المستوردين». It prints the report `forms/IMPR/reports/IMPR2420.xml`.
Package `IMPR2420` 001, page **2420**, generator `scripts/gen_apex_impr2420.py`. Date 2026-11-26. Nothing has been
compiled or imported.

**Template:** the report-screen pattern of IMPR2110 … IMPR2310 (`analysis/IMPR2110/IMPR2110_apex_page_spec.md` §2, §12),
built from the IMPR2180 generator. IMPR2420 is the smallest of them:
- block `CALLING_PARAMETERS` holds only the list item `P_TYPE` (expiry status), a static list from the XML (as IMPR2120);
- there is no port item: the report always gets the user's port (`:PARAMETER.P_CURR_PORT_CD`);
- Forms has **no count check** (`V_COUNT := 1`): the report always runs.

## 1. What the form does

A parameter screen with no base table (the module header comment still describes the generated AC1100 screen; it is not
relevant). The user picks the expiry status and presses **طباعة [F4]** (`PRINT`, PU `PRINT_CHECK_VAL`) or **عرض [F5]**
(`VIEW`, PU `CHECK_VAL`). Both run `IMPR2420.REP` with `P_REPORT_NO`, `P_TYPE`, `P_MODULE_NAME`, `P_CURR_PORT_CD`
(`CHECK_VAL` also sends `V_ORDER`, always NULL). `CHECK_VAL` first sets `P_TYPE := 3` when it is empty or not 1/2/3.

| Block | Kind | Items |
|---|---|---|
| `CALLING_PARAMETERS` | control, 1 record | `P_TYPE` (list item: غير منتهي الصلاحية 2, منتهي الصلاحية 1, الجميع 3; InitializeValue 3) |
| `TITLE` (OLB) | header | `SCREEN_NAME`, `USER_NAME`, `SYSTEM_DATE`, `SYSTEM_G_DATE`, `REPORT_NO`, `P_CURR_PORT_NAME` |
| `TOOLBAR` | buttons | `LOV` قائمة, `CLEAR` مسح, `PRINT` طباعة, `VIEW` عرض, `EXIT` خروج |
| `ZATCA_LOGOS` (OLB) | logos | — |

## 2. Approach

1. **Report.** `IMPR2420_ARD` (`plsql/IMPR2420`), generated earlier by `scripts/gen_ard_impr_reports.py`; this conversion
   only changed its caller note (`_spec.sql`; the `_body.sql` is unchanged).
2. **Toolbar.** Page 0 shows only PRINT, CLEAR and BACK (`P2420_REPORT`).
3. **Print.** The custom event `REPORT_PRINT` runs FOS `IMPR2420.PRINT_CHECK_VAL`, which returns the ardpdf link from
   `PRINT_IMPR2420_ARD`; one line of JavaScript opens it in a new tab.
4. **Report server settings.** `ARD_URL` and `ARD_DSNAME` come from `SC_PORT_SETTING` (SYSOBJ_ID 999, PORT_CD 99).

| ARD parameter | RDF parameter | Value sent by the page |
|---|---|---|
| `P_PARAMETER1` | `P_CURR_PORT_CD` | application item `P_CURR_PORT_CD` (the ARD treats empty as 99, as the RDF BeforeReport) |
| `P_PARAMETER2` | `P_TYPE` | `P2420_P_TYPE` (empty / unknown → 3, PU CHECK_VAL) |
| `P_PARAMETER3` | `P_MODULE_NAME` | `P2420_HERO_TITLE` |
| `P_PARAMETER4` | `P_REPORT_NO` | `P2420_REPORT_NO` |

## 3. Page 2420 `IMPR2420`

Template *Zatca-Minimal_No_Navigation*, class `zf`, protection C, page group IMPR (IMPR1110). No search page, never
submits, no DML.

| Seq | Region (static id) | Type / template | Source |
|---|---|---|---|
| 10 | الهيدر (`TITLE`) | static, hero | module name, port name, report number (KPI) |
| 20 | معاملات التقرير (`CALLING_PARAMETERS`) | static, *Interactive Report* template, `zatca-forms cg-form cg-card` | block CALLING_PARAMETERS |

## 4. Items

| Item | Type | Forms source | Notes |
|---|---|---|---|
| `P2420_P_TYPE` | Select List, inline `STATIC2` (XML order), no null entry, default 3, «حالة الصلاحية» | `P_TYPE` | Required template (always has a value) |
| `P2420_HERO_TITLE` | Hidden | `TITLE.SCREEN_NAME` (`P_MODULE_NAME`) | sent as P_MODULE_NAME |
| `P2420_MODULE_ID` | Hidden | `:PARAMETER.P_MODULE_ID` | f345 |
| `P2420_REPORT_NO` | Hidden (hero) | `TITLE.REPORT_NO` = `P_SYS_ID-P_REP_NO` | from `SC_PORT_SETTING` |
| `P2420_P_CURR_PORT_NAME` | Hidden (hero) | `TITLE.P_CURR_PORT_NAME` | see §12.3 |
| `P2420_REPORT` | Hidden, no value | — | report-page flag |
| `P2420_REPORT_URL` | Hidden, not protected | `REP.Run_Product` | returned by FOS |

The prompt «حالة الصلاحية» is new: the Forms canvas has no text for the list (only a frame graphic); SUGGESTION, the
user can change it in Page Designer.

## 6. LOVs

None. `P_TYPE` is a static list (CLAUDE.md 4d rule 1: fixed values from the XML stay Static).

## 8. Processes (Before Header)

The five processes of IMPR2180: `New` (Never), `P0_PAGE_PK CHECK`, `PARAMETERS` (`GET_MODULE_ID … 'IMPR2420'`),
`WHEN-NEW-FORM-INSTANCE` and `HEADER TITLE` (default «تقرير أخطاء المستوردين» = `P_MODULE_NAME` initial value).

No validations: the page never submits, and Forms never refuses a P_TYPE value (CHECK_VAL replaces it by 3).

## 10. Dynamic actions

| Name | Event | Actions |
|---|---|---|
| `REPORT_PRINT` | custom (page 0) | Clear URL; FOS `PRINT_CHECK_VAL` (returns P2420_P_TYPE, P2420_REPORT_URL); one-line JS that opens the link |

## 11. Trace (every Forms object)

| Forms object | Target / rationale |
|---|---|
| CALLING_PARAMETERS.P_TYPE (list item) | static Select List `P2420_P_TYPE` |
| TITLE.SYSTEM_DATE / SYSTEM_G_DATE WHEN-VALIDATE-ITEM, TITLE.USER_NAME | dropped: display items / f345 shell |
| TOOLBAR.PRINT (طباعة), KEY-PRINT, KEY-F4, PU PRINT_CHECK_VAL | DA `REPORT_PRINT`, `IMPR2420.PRINT_CHECK_VAL` |
| TOOLBAR.VIEW (عرض), KEY-F5, PU CHECK_VAL | page 0 طباعة (REPORT_SHOW Never, DEC-018); same PDF; the P_TYPE := 3 rule is in PRINT_CHECK_VAL |
| REP.Run_Product (IMPR2420.REP), WIN_API_DIALOG.SELECT_PRINTER (commented out) | `PRINT_IMPR2420_ARD`; printer choice = browser print of the PDF |
| Report IMPR2420.rdf | `IMPR2420_ARD` (generated earlier; caller note updated) |
| TOOLBAR.CLEAR (مسح) | page 0 CLEAR |
| TOOLBAR.LOV (قائمة) | dropped: `DO_KEY('LIST_VALUES')`, the form has no LOV |
| TOOLBAR.EXIT (خروج) | page 0 BACK |
| WHEN-NEW-FORM-INSTANCE | process + `WHEN_NEW_FORM_INSTANCE` (REPORT_NO); `:GLOBAL.CHPT_CODE / CHPT_ARB := NULL` not needed (no LOV form) |
| PU P_ORDER, PU CGDV$POPULATE_DYNAMIC_LISTS | dropped: bodies commented out (NULL) |
| PRE-FORM, WHEN-WINDOW-ACTIVATED | dropped: window, icon and date format (f345 shell) |
| PU LOAD_ZATCA_LOGOS, block ZATCA_LOGOS | f345 hero / theme |
| Alerts CFG_*, USR_*, CG$ASK_COMMIT | not used |
| Module parameters | `P_MODULE_ID` → item; `P_SYS_ID`, `P_REP_NO` → `SC_PORT_SETTING`; `P_CURR_PORT_CD` → f345 app item; `P_MODULE_NAME` → hero title; `P_REPORT_PATH` / `P_REPORT_FILE` → ARD; `V_ORDER` → not sent (always NULL); the others unused |

## 12. Findings and decisions

1. **No count check.** Forms always runs the report (`V_COUNT := 1`; the «لا يوجد» branch is dead code). Kept: an empty
   result is an empty PDF.
2. **P_TYPE rule of CHECK_VAL for both buttons.** Only `CHECK_VAL` (عرض) set an empty / unknown P_TYPE to 3;
   `PRINT_CHECK_VAL` sent it unchanged. With one button (DEC-018) the CHECK_VAL rule is kept; the ARD also treats an
   empty value as 3. P_TYPE is IN OUT, so the page shows the value sent.
3. **Port name in the hero (SUGGESTION).** The Forms SELECT of `P_CURR_PORT_NAME` is commented out (the field stayed empty);
   the hero shows the user's port name as on the other report pages. Display only.
4. **Port sent to the report.** Always the user's port (`P_CURR_PORT_CD`), as Forms. A head-office user (99) gets every
   port, which is how the RDF reads 99.
5. **Shared-component id base 9242** (page-digit pattern); this page creates no shared component. The generator's
   self-check found no id clash with any export.
