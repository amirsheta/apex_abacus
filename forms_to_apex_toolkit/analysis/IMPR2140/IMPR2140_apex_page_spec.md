# IMPR2140 – Analysis and APEX page spec (report parameter form)

Form `forms/IMPR/impr2140_fmb.xml` «خطاب للمستورد». It prints one of three letter reports:
`forms/IMPR/reports/IMPR2141.xml`, `impr2142.xml` and `impr2143.xml`. Package `IMPR2140` 001, page **2140**, generator
`scripts/gen_apex_impr2140.py`. Date 2026-11-25. Nothing has been compiled or imported.

**Template:** this is the report-screen pattern of IMPR2110 / IMPR2130 (`analysis/IMPR2110/IMPR2110_apex_page_spec.md` §2, §12),
built from the IMPR2130 generator. The differences are:
- one importer number (`IMPR_NO` + `IMPR_NAME`) instead of a comma list, so there is no `CTR_BLK` grid;
- the list item `LETTER_DIRCTION` chooses which of the three reports runs.

The Forms module title «MAINTAIN IMPORTERS APPREVIATION CODES» was copied from another form and is not used.
The page's default title comes from the letters: «خطاب للمستورد».

## 1. What the form does

This is a parameter screen with no base table. The user picks the port (head office, port 99, only), the letter
recipient (`LETTER_DIRCTION`) and **one** importer number. The importer is required. The user then presses
**عرض [F5]** (`CHECK_VAL`) or **طباعة [F4]** (`PRINT_CHECK_VAL`). Both check that the importer number is filled in, run
the count for the chosen letter (if it is zero: «لا يوجد سجلات تحقق المطلوب»), and run the letter's report with `IMPR_NO`
and `P_CURR_PORT_CD`.

| Block | Kind | Items |
|---|---|---|
| `CALLING_PARAMETERS` | control, 1 record | `P_PORT_CD`, `P_PORT_NAME`, `LETTER_DIRCTION` (list), `IMPR_NO`, `IMPR_NAME`; buttons `P_LOV_PORT`, `SECT_LOV`; hidden and unused: `BUS_ID`, `FROM_PORT_CD` |
| `TITLE` (OLB) | header | `SCREEN_NAME`, `USER_NAME`, `SYSTEM_DATE`, `SYSTEM_G_DATE`, `REPORT_NO`, `P_CURR_PORT_NAME` |
| `TOOLBAR` | buttons | `PRINT`, `VIEW`, `CLEAR`, `LOV`, `EXIT` |
| `ZATCA_LOGOS` (OLB) | logos | — |

| LETTER_DIRCTION | Label | Report | Count in PRINT_CHECK_VAL |
|---|---|---|---|
| 1 (default) | خطابات ديوان المراقبة | IMPR2141 | `IMPORTERS ⨝ SD_PORTS`, importer number only, **any port** |
| 2 | خطابات إدارة التدقيق | IMPR2142 | failed samples: `SMPL_ITEMS` RESULT_CD 3/4, ACTION_CD ≠ 1, joined to `SMPL_REQUESTS`, `SMPL_LABS`(+), `IMPORTERS`, `CITIES`, `SD_PORTS`, for the port and importer |
| 3 (else) | خطابات قسم التدقيق بالجمرك | IMPR2143 | `IMPORTERS ⨝ SD_PORTS ⨝ SC_USERS` with CLASS_CD 12, for the port and importer |

## 2. Approach

1. **Reports.** The three letters are the ARD packages `IMPR2141_ARD`, `IMPR2142_ARD` and `IMPR2143_ARD` (`plsql/IMPR2140`).
   They were generated earlier by `scripts/gen_ard_impr_reports.py`; this conversion only changed their caller note.
2. **Toolbar.** Page 0 shows only PRINT, CLEAR and BACK (`P2140_REPORT`).
3. **Print.** The custom event `REPORT_PRINT` runs FOS `IMPR2140.PRINT_CHECK_VAL`. That procedure returns the ardpdf
   link from `PRINT_IMPR2141_ARD`, `PRINT_IMPR2142_ARD` or `PRINT_IMPR2143_ARD`, and one line of JavaScript opens it in a
   new tab.
4. **Report server settings.** `ARD_URL` and `ARD_DSNAME` come from `SC_PORT_SETTING` (SYSOBJ_ID 999, PORT_CD 99).

| ARD parameter | RDF parameter | Value sent by the page |
|---|---|---|
| `P_PARAMETER1` | `P_CURR_PORT_CD` | `NVL(P2140_P_PORT_CD, P_CURR_PORT_CD)` |
| `P_PARAMETER2` | `IMPR_NO` | `P2140_IMPR_NO` (required, digits) |

The form also sends `P_REPORT_NO`, `P_MODULE_NAME` and `V_ORDER`, but the letter reports have no such parameters, so the page
does not send them.

**The count (user decision 2026-11-25):** the PRINT_CHECK_VAL count of each letter is kept exactly as in Forms
(private `letter_count`). The differences from the reports are listed in §12.

## 3. Page 2140 `IMPR2140`

The page uses the template *Zatca-Minimal_No_Navigation*, class `zf`, protection C and page group IMPR (IMPR1110). It has
no search page, never submits and does no DML.

| Seq | Region (static id) | Type / template | Source |
|---|---|---|---|
| 10 | الهيدر (`TITLE`) | static, hero | module name, port name, report number (KPI) |
| 20 | معاملات التقرير (`CALLING_PARAMETERS`) | static, *Interactive Report* template, `zatca-forms cg-form cg-card` | block CALLING_PARAMETERS |

## 4. Items

| Item | Type | Forms source | Notes |
|---|---|---|---|
| `P2140_P_PORT_CD` | Popup LOV `LOV_SD_PORTS` (IMPR1110) | `P_PORT_CD`, `P_LOV_PORT` | condition `IMPR2140.P_PORT_CD_IS_VISIBLE` (port 99 only) |
| `P2140_P_PORT_NAME` | Display only | `P_PORT_NAME` | same condition |
| `P2140_LETTER_DIRCTION` | Select List, inline STATIC2 (1/2/3), default 1, required | `LETTER_DIRCTION` | label from the canvas text «توجيه الخطاب» |
| `P2140_IMPR_NO` | Popup LOV `LOV_IMPR2140_REP_IMPR`, required, «رقم المستورد» | `IMPR_NO`, `IMPR_NO.KEY-LISTVAL`, button `SECT_LOV` (REP_LOV_IMPR) | LOV Items to Submit `P2140_P_PORT_CD` |
| `P2140_IMPR_NAME` | Display only | `IMPR_NAME` | set by DA `IMPR_NO WHEN-VALIDATE-ITEM` |
| `P2140_HERO_TITLE` | Hidden | `TITLE.SCREEN_NAME` (`P_MODULE_NAME`) | |
| `P2140_MODULE_ID` | Hidden | `:PARAMETER.P_MODULE_ID` | f345 |
| `P2140_REPORT_NO` | Hidden (hero) | `TITLE.REPORT_NO` = `P_SYS_ID-P_REP_NO` | values come from `SC_PORT_SETTING` |
| `P2140_P_CURR_PORT_NAME` | Hidden (hero) | `TITLE.P_CURR_PORT_NAME` | |
| `P2140_REPORT` | Hidden, no value | — | report-page flag |
| `P2140_REPORT_URL` | Hidden, not protected | `REP.Run_Product` | returned by FOS |

## 6. LOV

**`LOV_IMPR2140_REP_IMPR`** = `LOV_APX.IMPORTERS(P_PORT_ITEM => 'P2140_P_PORT_CD', P_DEFAULT_PORT_ITEM => 'P_CURR_PORT_CD')`.
Its columns are D (number), ARBC_IMPR_NAME and BUS_ID. It is page-specific because the call names the port item
(as `LOV_IMPR2130_REP_IMPR`). No change to LOV_APX. `LETTER_DIRCTION` uses an inline static list (values from the XML).

## 8. Processes (Before Header)

These are the five processes of IMPR2130: `New` (Never), `P0_PAGE_PK CHECK`, `PARAMETERS` (`GET_MODULE_ID … 'IMPR2140'`),
`WHEN-NEW-FORM-INSTANCE` and `HEADER TITLE` (default «خطاب للمستورد»).

There are no validations because the page never submits. `PRINT_CHECK_VAL` repeats every check: port, importer
required and existing, and letter value (standard 13-b).

## 10. Dynamic actions

| Name | Event | Actions |
|---|---|---|
| `P_PORT_CD WHEN-VALIDATE-ITEM` | change | FOS `P_PORT_CD_WHEN_VALIDATE_ITEM` (returns P_PORT_NAME) |
| `IMPR_NO WHEN-VALIDATE-ITEM` | change | FOS `IMPR_NO_WHEN_VALIDATE_ITEM` (returns IMPR_NAME) |
| `REPORT_PRINT` | custom (page 0) | Clear URL; FOS `PRINT_CHECK_VAL`; one-line JS that opens the link |

## 11. Trace (every Forms object)

| Forms object | Target / rationale |
|---|---|
| P_PORT_CD KEY-LISTVAL, P_LOV_PORT WHEN-BUTTON-PRESSED | Popup LOV `LOV_SD_PORTS` |
| P_PORT_CD WHEN-VALIDATE-ITEM | `P_PORT_CD_VALIDATION`, `P_PORT_CD_WHEN_VALIDATE_ITEM`, DA |
| IMPR_NO KEY-LISTVAL, SECT_LOV WHEN-BUTTON-PRESSED | Popup LOV `P2140_IMPR_NO` (`LOV_IMPR2140_REP_IMPR`); `NEXT_ITEM` not needed |
| IMPR_NO WHEN-VALIDATE-ITEM | `IMPR_NO_VALIDATION`, `IMPR_NO_WHEN_VALIDATE_ITEM`, DA |
| LETTER_DIRCTION (list item) | Select List + `LETTER_DIRCTION_VALIDATION` (new check, SUGGESTION) |
| BUS_ID, FROM_PORT_CD | dropped: hidden and not used by any code (BUS_ID is only in a comment) |
| TITLE.SYSTEM_DATE / SYSTEM_G_DATE WHEN-VALIDATE-ITEM | dropped: display items, never entered |
| TOOLBAR.VIEW, KEY-F5, PU CHECK_VAL | page 0 طباعة (REPORT_SHOW Never, DEC-018); same PDF |
| TOOLBAR.PRINT, KEY-PRINT, KEY-F4, PU PRINT_CHECK_VAL | DA `REPORT_PRINT`, `IMPR2140.PRINT_CHECK_VAL` (count → private `letter_count`) |
| REP.Run_Product (IMPR2141/2142/2143.REP) | `PRINT_IMPR2141_ARD` / `PRINT_IMPR2142_ARD` / `PRINT_IMPR2143_ARD` (private `ard_link`) |
| Reports IMPR2141/2142/2143.rdf | `IMPR2141_ARD`, `IMPR2142_ARD`, `IMPR2143_ARD` (generated earlier; caller note updated) |
| KEY-CLRBLK, TOOLBAR.CLEAR | page 0 CLEAR |
| TOOLBAR.LOV / EXIT | Popup LOV buttons / page 0 BACK |
| WHEN-NEW-FORM-INSTANCE | process + `WHEN_NEW_FORM_INSTANCE`, item condition `P_PORT_CD_IS_VISIBLE`; `GO_ITEM('LETTER_DIRCTION')` not needed |
| PRE-FORM, WHEN-WINDOW-ACTIVATED | dropped: window, icon and date format (f345 shell) |
| PU LOAD_ZATCA_LOGOS, block ZATCA_LOGOS | f345 hero / theme |
| Alerts CFG_*, USR_*, CG$ASK_COMMIT | not used by this form's code |
| `:GLOBAL.CHPT_CODE / CHPT_ARB / SEC_CODE / IMPR_NBR / ARBC_IMPR_NAME / SECT_ARB / PORT_CD / PORT_NAME` | LOV-form globals → Popup LOV return values |
| Module parameters | `P_MODULE_ID` → item; `P_SYS_ID`, `P_REP_NO` → `SC_PORT_SETTING`; `P_CURR_PORT_CD` → f345 app item; `P_REPORT_PATH` / `P_REPORT_FILE` → replaced by ARD; others unused |
| `C_DATE := HIJDATE.CUR_HIJ_DATE`, `WIN_API_DIALOG.SELECT_PRINTER` | dropped: the value is never used / the browser prints |

## 12. Findings and decisions

1. **The count is kept as in Forms (user decision 2026-11-25).** It does not match the letter reports, which select only
   `IMPORTERS ⨝ SD_PORTS` for the port:
   - letter 1 counts the importer in any port, so a PDF can open empty when he is not registered at the report's port;
   - letter 2 needs failed samples, which the report does not check;
   - letter 3 needs a class-12 user at the port, which the report does not check.

   These are marked `SUGGESTION` in `letter_count` and should be confirmed with the business owner.
2. **VIEW and PRINT counted differently.** For letter 2, `CHECK_VAL` (VIEW) has no sample rule: it is a cross join of
   `IMPORTERS` and `SD_PORTS` for the port. APEX has a single PRINT (DEC-018), which uses the PRINT_CHECK_VAL rule.
3. **Port parameter name.** In Forms the name is `'P_CURR_PORT_CD '`, with a trailing blank. Reports probably did not
   match it, so the RDF default port was used. Here the port is always sent as `P_PARAMETER1`.
4. **`P_PORT_CD` message.** The Forms message is the literal text `NO_DATA_FOUND`. It is kept and marked SUGGESTION:
   IMPR2110 and IMPR2130 say «رمز الجمرك غير صحيح» instead. An empty port is accepted, and the report then runs for
   `P_CURR_PORT_CD`.
5. **`IMPR_NO` behaviour.**
   - It is a CHAR item. A value that is not a number gets «رمزالمستورد غير موجود» here, where Forms raised ORA-01722.
   - When the same number has different names in different ports, Forms raised TOO_MANY_ROWS. Here the first name (MIN) is
     shown (SUGGESTION).
   - The port filter and the broker check (`BRKIMPS`) are commented out in Forms and are not converted.
6. **`LETTER_DIRCTION`.** A value check was added (SUGGESTION) because a select list can be posted with any value.
   Forms maps every value other than 1 and 2 to letter 3; the check only allows 1, 2 and 3.
7. **Shared-component id base 9214.** 9213 is used by IMPR2130. The generator's self-check found no id clash with any
   export.
