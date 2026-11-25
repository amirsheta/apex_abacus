# IMPR2150 – Analysis and APEX page spec (report parameter form)

Form `forms/IMPR/IMPR2150_fmb.xml` «استثناءات المستوردين». It prints the report `forms/IMPR/reports/IMPR2150.xml`.
Package `IMPR2150` 001, page **2150**, generator `scripts/gen_apex_impr2150.py`. Date 2026-11-25. Nothing has been
compiled or imported.

**Template:** this is the report-screen pattern of IMPR2110 / IMPR2130 / IMPR2140 (`analysis/IMPR2110/IMPR2110_apex_page_spec.md`
§2, §12), built from the IMPR2140 generator. The differences are:
- there is no port item (`P_PORT_CD`): the report runs for every port, and the user's port is only sent for the header;
- one **optional** unified importer number `HQ_IMPR_NBR` (empty = every importer), with four display items filled by its
  WHEN-VALIDATE-ITEM;
- two required parameters: the list item `REC_STATUS` and the code `RULE_TYPE`.

The Forms module title «MAINTAIN IMPORTERS APPREVIATION CODES» was copied from another form and is not used.
The page's default title comes from the report: «استثناءات المستوردين».

## 1. What the form does

This is a parameter screen with no base table. The user may enter or pick a unified importer number, picks the record
status (default «فعال») and the rule type (default 1), then presses **عرض [F5]** (`CHECK_VAL`) or **طباعة [F4]**
(`PRINT_CHECK_VAL`). Both run the same count on `IMPR_RULES` / `IMPR_RULE_PORTS` (zero: «لا يوجد سجلات تحقق المطلوب»)
and then run `IMPR2150.REP` with `P_HQ_IMPR_NBR`, `P_REC_STATUS`, `P_RULE_TYPE`, `P_REPORT_NO`, `P_MODULE_NAME`, `V_ORDER`.

| Block | Kind | Items |
|---|---|---|
| `CALLING_PARAMETERS` | control, 1 record | `HQ_IMPR_NBR` (+ button `HQ_IMPR_NBR2`), `L_SI_ARBC_IMPR_NAME`, `BUS_ID_TYPE_CD`, `BUS_ID_TYPE_NAME`, `BUS_ID`, `BUS_ID_BRNCH`, `REC_STATUS` (list), `RULE_TYPE` (+ LOV319, button `ITEM318`), `RULE_NAME`; hidden and unused: `FROM_PORT_CD` |
| `TITLE` (OLB) | header | `SCREEN_NAME`, `USER_NAME`, `SYSTEM_DATE`, `SYSTEM_G_DATE`, `REPORT_NO`, `P_CURR_PORT_NAME` |
| `TOOLBAR` | buttons | `PRINT`, `VIEW`, `CLEAR`, `LOV`, `EXIT` |
| `ZATCA_LOGOS` (OLB) | logos | — |

## 2. Approach

1. **Report.** `IMPR2150_ARD` (`plsql/IMPR2150`), generated earlier by `scripts/gen_ard_impr_reports.py`; this
   conversion only changed its caller note.
2. **Toolbar.** Page 0 shows only PRINT, CLEAR and BACK (`P2150_REPORT`).
3. **Print.** The custom event `REPORT_PRINT` runs FOS `IMPR2150.PRINT_CHECK_VAL`, which returns the ardpdf link from
   `PRINT_IMPR2150_ARD`; one line of JavaScript opens it in a new tab.
4. **Report server settings.** `ARD_URL` and `ARD_DSNAME` come from `SC_PORT_SETTING` (SYSOBJ_ID 999, PORT_CD 99).

| ARD parameter | RDF parameter | Value sent by the page |
|---|---|---|
| `P_PARAMETER1` | `P_CURR_PORT_CD` | `P_CURR_PORT_CD` (header port name only; the form did not send it) |
| `P_PARAMETER2` | `P_HQ_IMPR_NBR` | `P2150_HQ_IMPR_NBR` (empty = all) |
| `P_PARAMETER3` | `P_REC_STATUS` | `P2150_REC_STATUS` (1 / 0) |
| `P_PARAMETER4` | `P_RULE_TYPE` | `P2150_RULE_TYPE` |
| `P_PARAMETER5` | `P_MODULE_NAME` | `P2150_HERO_TITLE` |
| `P_PARAMETER6` | `P_REPORT_NO` | `P2150_REPORT_NO` |

`V_ORDER` (an empty menu parameter) and the Reports Runtime options are not sent.

**The count:** kept exactly as in Forms (private `rules_count`), following the IMPR2140 user decision of 2026-11-25.
See §12 item 1: it has an operator-precedence problem.

## 3. Page 2150 `IMPR2150`

Template *Zatca-Minimal_No_Navigation*, class `zf`, protection C, page group IMPR (IMPR1110). No search page, never
submits, no DML.

| Seq | Region (static id) | Type / template | Source |
|---|---|---|---|
| 10 | الهيدر (`TITLE`) | static, hero | module name, port name, report number (KPI) |
| 20 | معاملات التقرير (`CALLING_PARAMETERS`) | static, *Interactive Report* template, `zatca-forms cg-form cg-card` | block CALLING_PARAMETERS |

## 4. Items

| Item | Type | Forms source | Notes |
|---|---|---|---|
| `P2150_HQ_IMPR_NBR` | Popup LOV `LOV_IMPORT_HQ_NBR`, optional, «الرقم الموحد للمستورد» | `HQ_IMPR_NBR`, KEY-LISTVAL, button `HQ_IMPR_NBR2` (PU `SINGLE_IMP_LOV`) | |
| `P2150_L_SI_ARBC_IMPR_NAME` | Display only | `L_SI_ARBC_IMPR_NAME` | set by the HQ_IMPR_NBR DA |
| `P2150_BUS_ID_TYPE_CD` | Display only, «نوع الرقم الاستدلالى» | `BUS_ID_TYPE_CD` | Forms let the user type here, but nothing reads it (SUGGESTION, §12) |
| `P2150_BUS_ID_TYPE_NAME` | Display only | `BUS_ID_TYPE_NAME` | |
| `P2150_BUS_ID` | Display only, «الرقم الاستدلالي» | `BUS_ID` (Insert / Update Allowed No) | |
| `P2150_BUS_ID_BRNCH` | Display only, «الفرع» | `BUS_ID_BRNCH` (Insert / Update Allowed No) | used by the count; `PRINT_CHECK_VAL` reads it again from `SINGLE_IMPORTERS` |
| `P2150_REC_STATUS` | Select List, inline STATIC2 فعال;1, غير فعال;0, default 1, required | `REC_STATUS` (list item) | |
| `P2150_RULE_TYPE` | Select List `LOV_RULE_TYPE` (IMPR1140), default 1, required, «نوع الاستثناء» | `RULE_TYPE` + LOV319 + `ITEM318` + `RULE_NAME` | the select list shows RV_MEANING, the value of `RULE_NAME` |
| `P2150_HERO_TITLE` | Hidden | `TITLE.SCREEN_NAME` (`P_MODULE_NAME`) | sent as P_MODULE_NAME |
| `P2150_MODULE_ID` | Hidden | `:PARAMETER.P_MODULE_ID` | f345 |
| `P2150_REPORT_NO` | Hidden (hero) | `TITLE.REPORT_NO` = `P_SYS_ID-P_REP_NO` | from `SC_PORT_SETTING` |
| `P2150_P_CURR_PORT_NAME` | Hidden (hero) | `TITLE.P_CURR_PORT_NAME` | |
| `P2150_REPORT` | Hidden, no value | — | report-page flag |
| `P2150_REPORT_URL` | Hidden, not protected | `REP.Run_Product` | returned by FOS |

## 6. LOVs

- **`LOV_IMPORT_HQ_NBR`** (new, id base 9215) = `return LOV_APX.SINGLE_IMPORTERS;` Columns D (unified number),
  ARBC_IMPR_NAME, BUS_ID, as the LOV form `LOV_IMPORT_HQ_NBR`.
  **LOV_APX 005:** the function was `LOV_SINGLE_IMPORTERS` (IMPR1140, with the rule-type-12 switch to `IMPORTERS`). It now
  has two users, so it is renamed `SINGLE_IMPORTERS` (CLAUDE.md §4d rule 2) and `P_RULE_TYPE_ITEM` became optional: without
  it the function returns only the `SINGLE_IMPORTERS` list. IMPR1140's call changed by name only
  (`scripts/gen_apex_impr1140.py`, re-run; one line differs in its export). Previous version: `rollback/LOV_APX/v004/`.
  IMPR2150 does not switch lists by rule type: its PU `SINGLE_IMP_LOV` always calls `LOV_IMPORT_HQ_NBR`.
- **`LOV_RULE_TYPE`** (reused from the IMPR1140 export) = `LOV_APX.REFERENCE_CODES(P_DOMAIN => 'RULE_TYPE')`, the query
  of record group LOV319.

## 8. Processes (Before Header)

The five processes of IMPR2140: `New` (Never), `P0_PAGE_PK CHECK`, `PARAMETERS` (`GET_MODULE_ID … 'IMPR2150'`),
`WHEN-NEW-FORM-INSTANCE` and `HEADER TITLE` (default «استثناءات المستوردين»).

No validations: the page never submits. `PRINT_CHECK_VAL` repeats every check (importer, REC_STATUS, RULE_TYPE).

## 10. Dynamic actions

| Name | Event | Actions |
|---|---|---|
| `HQ_IMPR_NBR WHEN-VALIDATE-ITEM` | change | Clear the five display items (Forms clears them on error and when empty); FOS `HQ_IMPR_NBR_WHEN_VALIDATE_ITEM` (returns them) |
| `REPORT_PRINT` | custom (page 0) | Clear URL; FOS `PRINT_CHECK_VAL`; one-line JS that opens the link |

## 11. Trace (every Forms object)

| Forms object | Target / rationale |
|---|---|
| HQ_IMPR_NBR KEY-LISTVAL, HQ_IMPR_NBR2 WHEN-BUTTON-PRESSED, PU SINGLE_IMP_LOV (CALL_FORM LOV_IMPORT_HQ_NBR, `:GLOBAL.HQ_IMPR_NBR / BUS_ID / ARBC_IMPR_NAME`) | Popup LOV `P2150_HQ_IMPR_NBR` (`LOV_IMPORT_HQ_NBR`); the DA fills the rest |
| HQ_IMPR_NBR WHEN-VALIDATE-ITEM | `HQ_IMPR_NBR_VALIDATION`, `HQ_IMPR_NBR_WHEN_VALIDATE_ITEM`, DA |
| L_SI_ARBC_IMPR_NAME, BUS_ID_TYPE_CD, BUS_ID_TYPE_NAME, BUS_ID, BUS_ID_BRNCH | display items (§4) |
| BUS_ID_BRNCH WHEN-VALIDATE-ITEM | dropped: the code is commented out (`NULL;`) |
| REC_STATUS (list item) | Select List + `REC_STATUS_VALIDATION` (new value check, SUGGESTION) |
| RULE_TYPE, LOV LOV319 / record group LOV319, ITEM318 WHEN-BUTTON-PRESSED, RULE_NAME | Select List on `LOV_RULE_TYPE` + `RULE_TYPE_VALIDATION`; `RULE_NAME` = the shown meaning |
| FROM_PORT_CD | dropped: hidden and not used |
| TITLE.SYSTEM_DATE / SYSTEM_G_DATE WHEN-VALIDATE-ITEM | dropped: display items, never entered |
| TOOLBAR.VIEW, KEY-F5, PU CHECK_VAL | page 0 طباعة (REPORT_SHOW Never, DEC-018); same PDF |
| TOOLBAR.PRINT, KEY-PRINT, KEY-F4, PU PRINT_CHECK_VAL | DA `REPORT_PRINT`, `IMPR2150.PRINT_CHECK_VAL` (count → private `rules_count`) |
| REP.Run_Product (IMPR2150.REP) | `PRINT_IMPR2150_ARD` |
| Report IMPR2150.rdf | `IMPR2150_ARD` (generated earlier; caller note updated) |
| KEY-CLRBLK (NULL), TOOLBAR.CLEAR | page 0 CLEAR |
| TOOLBAR.LOV / EXIT | Popup LOV button / page 0 BACK |
| WHEN-NEW-FORM-INSTANCE | process + `WHEN_NEW_FORM_INSTANCE` |
| PRE-FORM, WHEN-WINDOW-ACTIVATED | dropped: window, icon and date format (f345 shell) |
| PU LOAD_ZATCA_LOGOS, block ZATCA_LOGOS | f345 hero / theme |
| `:GLOBAL.CHPT_CODE / CHPT_ARB / SEC_CODE / IMPR_NBR / ARBC_IMPR_NAME` | LOV-form globals → Popup LOV return value |
| Module parameters | `P_MODULE_ID` → item; `P_SYS_ID`, `P_REP_NO` → `SC_PORT_SETTING`; `P_CURR_PORT_CD` → f345 app item; `P_MODULE_NAME` → hero title; `P_REPORT_PATH` / `P_REPORT_FILE` → ARD; `V_ORDER` and the others unused |

## 12. Findings and decisions

1. **The count is kept as in Forms, but it is probably wrong. Confirm with the business owner.**
   `WHERE IR.HQ_IMPR_NBR = :HQ_IMPR_NBR OR :HQ_IMPR_NBR IS NULL AND <join> AND <status> AND <branch>` means
   `HQ = :HQ OR (:HQ IS NULL AND …)`, because AND binds before OR. So:
   - with an importer number, the count is the importer's rules times **every** `IMPR_RULE_PORTS` row (no join), with no
     status or branch rule. The check passes as soon as the importer has any rule, and the PDF can still be empty
     (for example, «غير فعال» chosen but every rule is active);
   - without a number, the join and the status / branch rules apply.

   The count also ignores `RULE_TYPE`, which the report filters on. The probable intent is
   `(IR.HQ_IMPR_NBR = :HQ OR :HQ IS NULL) AND … AND IR.RULE_TYPE = :RULE_TYPE`. Marked `SUGGESTION` in `rules_count`.
2. **Unqualified `BUS_ID_BRNCH`** in the count is read as `IMPR_RULES.BUS_ID_BRNCH`, the column the report reads.
3. **`BUS_ID_TYPE_CD` editable in Forms.** It is Enabled with no Insert / Update restriction, but no code reads it, so it
   is display only here (SUGGESTION). `BUS_ID` and `BUS_ID_BRNCH` were read-only in Forms already.
4. **`RULE_TYPE` prompt.** The Forms prompt «حـالة السجل» was copied from REC_STATUS. The page uses «نوع الاستثناء»
   (the LOV title is «انواع الاستثناءات»). The select list allows only RULE_TYPE codes. Forms accepted any typed number,
   which then failed the report silently (SUGGESTION, `RULE_TYPE_VALIDATION`).
5. **`HQ_IMPR_NBR` errors.** «رقم المستورد المدخل غير صحيح…» is shown for the same cases as Forms' `WHEN OTHERS`: an unknown
   number, a number with several `SINGLE_IMPORTERS` rows, or a business id type missing from `BUS_ID_TYPES`.
6. **Port in the header.** The form did not send `P_CURR_PORT_CD`, so the RDF header had no port name. The page sends the
   user's port, and the ARD prints its name (IMPR2150_ARD note).
7. **Shared-component id base 9215.** The generator's self-check found no id clash with any export.
