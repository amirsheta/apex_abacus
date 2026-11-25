# IMPR2180 – Analysis and APEX page spec (report parameter form)

Form `forms/IMPR/IMPR2180_fmb.xml` «تقرير ازدواجية مهنتي الإستيراد والتخليص الجمركي». It prints the report
`forms/IMPR/reports/IMPR2180.xml`. Package `IMPR2180` 001, page **2180**, generator `scripts/gen_apex_impr2180.py`.
Date 2026-11-25. Nothing has been compiled or imported.

**Template:** the report-screen pattern of IMPR2110 … IMPR2170 (`analysis/IMPR2110/IMPR2110_apex_page_spec.md` §2, §12),
built from the IMPR2170 generator. IMPR2180 is the simplest of them:
- block `CONTROL` holds only the port (head office only) and the licence type;
- Forms has **no count check** (`V_COUNT := 1`): the report always runs;
- the licence-type list is filled at run time by PU `LOAD_LIST` from `CG_REF_CODES` (domain `LIC_TYPE`, without value 3).

## 1. What the form does

A parameter screen with no base table (the header comment still describes the generated AC1100 screen; it is not
relevant). The user optionally picks a port (head office only) and a licence type, then presses **طباعة [F4]**
(`PRINT`, PU `PRINT_CHECK_VAL`) or **عرض [F5]** (`VIEW`, PU `CHECK_VALUE`). Both run `IMPR2180.REP` with
`P_CURR_PORT_CD` (head office: the chosen port or empty; port user: own port), `P_REPORT_NO`, `p_lic_type`
(`CHECK_VALUE` also sends `P_MODULE_NAME`).

| Block | Kind | Items |
|---|---|---|
| `CONTROL` | control, 1 record | `P_PORT_CD` (+ button `P_LOV_PORT`), `P_PORT_NAME`, `P_LIC_TYPE` (list item) |
| `TITLE` (OLB) | header | `SCREEN_NAME`, `USER_NAME`, `SYSTEM_DATE`, `SYSTEM_G_DATE`, `REPORT_NO`, `P_CURR_PORT_NAME` |
| `TOOLBAR` | buttons | `LOV` قائمة, `CLEAR` مسح, `PRINT` طباعة, `VIEW` عرض, `EXIT` خروج |
| `ZATCA_LOGOS` (OLB) | logos | — |

## 2. Approach

1. **Report.** `IMPR2180_ARD` (`plsql/IMPR2180`), generated earlier by `scripts/gen_ard_impr_reports.py`; this conversion
   only changed its caller note (the `.pkb` is unchanged).
2. **Toolbar.** Page 0 shows only PRINT, CLEAR and BACK (`P2180_REPORT`).
3. **Print.** The custom event `REPORT_PRINT` runs FOS `IMPR2180.PRINT_CHECK_VAL`, which returns the ardpdf link from
   `PRINT_IMPR2180_ARD`; one line of JavaScript opens it in a new tab.
4. **Report server settings.** `ARD_URL` and `ARD_DSNAME` come from `SC_PORT_SETTING` (SYSOBJ_ID 999, PORT_CD 99).

| ARD parameter | RDF parameter | Value sent by the page |
|---|---|---|
| `P_PARAMETER1` | `P_CURR_PORT_CD` | head office: `P2180_P_PORT_CD` (empty = every port); else the application item `P_CURR_PORT_CD` |
| `P_PARAMETER2` | `P_LIC_TYPE` | `P2180_P_LIC_TYPE` (empty = every type) |
| `P_PARAMETER3` | `P_MODULE_NAME` | `P2180_HERO_TITLE` |
| `P_PARAMETER4` | `P_REPORT_NO` | `P2180_REPORT_NO` |

## 3. Page 2180 `IMPR2180`

Template *Zatca-Minimal_No_Navigation*, class `zf`, protection C, page group IMPR (IMPR1110). No search page, never
submits, no DML.

| Seq | Region (static id) | Type / template | Source |
|---|---|---|---|
| 10 | الهيدر (`TITLE`) | static, hero | module name, port name, report number (KPI) |
| 20 | معاملات التقرير (`CONTROL`) | static, *Interactive Report* template, `zatca-forms cg-form cg-card` | block CONTROL |

## 4. Items

"Head office only" = server-side condition `IMPR2180.P_PORT_CD_IS_VISIBLE(P_CURR_PORT_CD => :P_CURR_PORT_CD)`
(WHEN-NEW-FORM-INSTANCE hides `P_LOV_PORT`, `P_PORT_NAME`, `P_PORT_CD` when the port is not 99).

| Item | Type | Forms source | Notes |
|---|---|---|---|
| `P2180_P_PORT_CD` | Popup LOV `LOV_SD_PORTS` (IMPR1110), «رمز الجمرك» | `P_PORT_CD`, `P_LOV_PORT` (REP_LOV_SD_PORTS) | head office only; optional |
| `P2180_P_PORT_NAME` | Display only | `P_PORT_NAME` | head office only |
| `P2180_P_LIC_TYPE` | Select List `LOV_LIC_TYPE`, empty entry, «نوع الرخصة» | `P_LIC_TYPE` (list item, PU LOAD_LIST) | optional: empty = every type |
| `P2180_HERO_TITLE` | Hidden | `TITLE.SCREEN_NAME` (`P_MODULE_NAME`) | sent as P_MODULE_NAME |
| `P2180_MODULE_ID` | Hidden | `:PARAMETER.P_MODULE_ID` | f345 |
| `P2180_REPORT_NO` | Hidden (hero) | `TITLE.REPORT_NO` = `P_SYS_ID-P_REP_NO` | from `SC_PORT_SETTING` |
| `P2180_P_CURR_PORT_NAME` | Hidden (hero) | `TITLE.P_CURR_PORT_NAME` | |
| `P2180_REPORT` | Hidden, no value | — | report-page flag |
| `P2180_REPORT_URL` | Hidden, not protected | `REP.Run_Product` | returned by FOS |

The page item keeps the Forms name `P_LIC_TYPE` (`P2180_P_LIC_TYPE`); it is not the f345 application item `P_LIC_TYPE`
(the broker licence type of the login, used by IMPR1110), and `PRINT_CHECK_VAL` does not receive that application item.

## 6. LOVs

- **`LOV_LIC_TYPE`** (new, Select List, id base 9218) =
  `LOV_APX.REFERENCE_CODES(P_DOMAIN => 'LIC_TYPE', P_EXCLUDED_VALUE => '3')` — the record group `GROUP_TYPE` of PU
  `LOAD_LIST`. **LOV_APX 006**: `REFERENCE_CODES` gets the optional `P_EXCLUDED_VALUE` (CLAUDE.md 4d rule 2: a parameter, not
  a copy); existing calls are unchanged. Previous version: `rollback/LOV_APX/v005/`.
- **`LOV_SD_PORTS`** (IMPR1110) is reused.

## 8. Processes (Before Header)

The five processes of IMPR2170: `New` (Never), `P0_PAGE_PK CHECK`, `PARAMETERS` (`GET_MODULE_ID … 'IMPR2180'`),
`WHEN-NEW-FORM-INSTANCE` and `HEADER TITLE` (default «تقرير ازدواجية مهنتي الإستيراد والتخليص الجمركي»).

No validations: the page never submits. `PRINT_CHECK_VAL` repeats the port check and checks the licence type.

## 10. Dynamic actions

| Name | Event | Actions |
|---|---|---|
| `P_PORT_CD WHEN-VALIDATE-ITEM` | change | Clear name; FOS `P_PORT_CD_WHEN_VALIDATE_ITEM` (returns P_PORT_NAME; unknown port → Arabic message 1-120) |
| `REPORT_PRINT` | custom (page 0) | Clear URL; FOS `PRINT_CHECK_VAL`; one-line JS that opens the link |

## 11. Trace (every Forms object)

| Forms object | Target / rationale |
|---|---|
| P_PORT_CD KEY-LISTVAL, P_LOV_PORT WHEN-BUTTON-PRESSED (REP_LOV_SD_PORTS, `:GLOBAL.PORT_CD / PORT_NAME`) | Popup LOV `LOV_SD_PORTS` |
| P_PORT_CD WHEN-VALIDATE-ITEM (`STR.DispArbMsg(1, 120)`) | `P_PORT_CD_VALIDATION` (`FORMS_APX.ARABIC_MESSAGE(1, 120)`), `P_PORT_CD_WHEN_VALIDATE_ITEM`, DA |
| P_LIC_TYPE (list item), PU LOAD_LIST | Select List on `LOV_LIC_TYPE`; `P_LIC_TYPE_VALIDATION` in `PRINT_CHECK_VAL` |
| PU PORTS | dropped: fills a list item `PORT` that does not exist; its call is commented out |
| TITLE.SYSTEM_DATE / SYSTEM_G_DATE WHEN-VALIDATE-ITEM, TITLE.USER_NAME | dropped: display items / f345 shell |
| TOOLBAR.PRINT (طباعة), KEY-PRINT, KEY-F4, PU PRINT_CHECK_VAL | DA `REPORT_PRINT`, `IMPR2180.PRINT_CHECK_VAL` |
| TOOLBAR.VIEW (عرض), KEY-F5, PU CHECK_VALUE | page 0 طباعة (REPORT_SHOW Never, DEC-018); same PDF |
| REP.Run_Product (IMPR2180.REP), WIN_API_DIALOG.SELECT_PRINTER | `PRINT_IMPR2180_ARD`; printer choice = browser print of the PDF |
| Report IMPR2180.rdf | `IMPR2180_ARD` (generated earlier; caller note updated) |
| TOOLBAR.CLEAR (مسح) | page 0 CLEAR |
| TOOLBAR.LOV (قائمة) / EXIT (خروج) | Popup LOV button / page 0 BACK |
| WHEN-NEW-FORM-INSTANCE | process + `WHEN_NEW_FORM_INSTANCE`; VISIBLE lines → `P_PORT_CD_IS_VISIBLE`; `NEXT_ITEM` not needed |
| PRE-FORM, WHEN-WINDOW-ACTIVATED | dropped: window, icon and date format (f345 shell) |
| PU LOAD_ZATCA_LOGOS, block ZATCA_LOGOS | f345 hero / theme |
| Alerts CFG_*, USR_*, CG$ASK_COMMIT | not used (STR.DISPALERT in the LOV triggers is about the Forms parameter list only) |
| Module parameters | `P_MODULE_ID` → item; `P_SYS_ID`, `P_REP_NO` → `SC_PORT_SETTING`; `P_CURR_PORT_CD` → f345 app item; `P_MODULE_NAME` → hero title; `P_REPORT_PATH` / `P_REPORT_FILE` → ARD; the others (incl. the module parameter `P_LIC_TYPE`) unused by this form |

## 12. Findings and decisions

1. **No count check.** Forms always runs the report (`V_COUNT := 1`; the «لا يوجد» branch is dead code). Kept: an empty
   result is an empty PDF.
2. **Licence type check (SUGGESTION, new).** `P_LIC_TYPE_VALIDATION` refuses a posted value that is not in the list, with
   the new text «نوع الرخصة غير صحيح» (Forms has no message, a list item cannot hold another value).
3. **Licence type list.** The XML elements (عامة 2, مندوب 1) are replaced at run time by `LOAD_LIST`, so the page uses
   `CG_REF_CODES` as Forms does at run time. The list has an empty entry because the item is not Required and has no
   initial value; the report treats empty as every type.
4. **Port check in PRINT_CHECK_VAL** (head office only): an unknown typed port stops with message 1-120, as the Forms
   WHEN-VALIDATE-ITEM did. A port user's own port is sent without a check, as in Forms.
5. **WHEN-NEW-FORM-INSTANCE** reads the port name twice; the first SELECT has no handler (unknown port → ORA-01403).
   Here an unknown port leaves the name empty (SUGGESTION).
6. **Shared-component id base 9218.** The generator's self-check found no id clash with any export.
