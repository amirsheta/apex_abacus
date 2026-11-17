# IMPR1110 – Logic Extraction (Step 02)

| Item | Value |
|---|---|
| Form | IMPR1110 (module `IMPR1110_PROD_CENTRL`) – "إضافة وتعديل بيانات مستورد" |
| Source | `forms/IMPR/IMPR1110_fmb.xml` (same content as `Uploads/IMPR1110_fmb.xml`; the copy under `Downloads/` differs only in line endings) |
| Inputs | `analysis/IMPR1110/IMPR1110_inventory.md` (step 01) + the full decoded `TriggerText` / `ProgramUnitText` of all 376 units in the XML |
| Outputs | `plsql/IMPR1110/pkg_impr1110_spec.sql`, `plsql/IMPR1110/pkg_impr1110_body.sql` (business logic, no page items) · `plsql/IMPR1110/pkg_impr1110_apx_spec.sql`, `plsql/IMPR1110/pkg_impr1110_apx_body.sql` (APEX glue, the only code that touches `P1110_*`) · `scripts/expand_orig.py` (inserts the original code + self-check) |
| Previous version | The earlier draft (built from the inventory summary, 19 `TODO-VERIFY` texts) is kept in `rollback/IMPR1110/pkg_impr1110_spec_v0.sql` / `pkg_impr1110_body_v0.sql` |
| Target | APEX 21.2 / Oracle DB 12.1.0.2 |
| Status | **Written, not compiled.** No 12.1.0.2 database or APEX 21.2 instance was available. Self-checks below passed. |
| Date | 2026-11-18 – Claude Code |

---

## 0. Summary

| Measure | Value |
|---|---|
| Units in the XML (triggers + program units) | 376 (323 triggers + 53 program units) |
| Units with active code | 211 (165 empty / OLB-inherited / fully commented out) |
| Members of `pkg_impr1110` | 82 in the spec + 23 private helpers |
| Units handled by APEX itself (LOV, buttons, DA) | see §1, column *Target* = `APEX`, `APEX LOV`, `APEX-DA`, `native` |
| Units dropped (with reason) | see §1, *Target* = `dropped` |
| Original Forms code kept as comments in the body | 61 blocks, inserted by `scripts/expand_orig.py` (verbatim, blank/comment lines removed) |
| Messages / errors (all as `-20000` via `pkg_forms_compat.ftf`) | 91 (§4) – **every Arabic text was checked mechanically against the XML: 213 literals, 0 differences** |
| Open `TODO` in the code | 10 (§7.3) |
| HIGH flags | 7 (§7.2) |

### 0.1 What changed compared with the summary-based draft (v0)

The v0 package was written from the inventory summary. Reading the full trigger text showed
differences in behaviour, not only in message texts. The most important ones (all fixed in v1.0.0):

| # | Area | v0 | Original Forms (now implemented) |
|---|---|---|---|
| 1 | `BUS_ID` duplicate check | Counted suspensions in `IMPR_SUSPNS` itself | Uses `LIB_USR.IMPR.Impr_Suspended(port, impr, Cur_Hij_Date)`; active duplicate → error with the importer number; only suspended → WARNING "يوجد مستورد … موقوف" (yes keeps, no clears `BUS_ID`) |
| 2 | `BUS_ID` – `:GLOBAL.CHK_DUP_BUSID` | Set to 1 on a suspended duplicate | Never set to 1 in this form (only the unused `VIEW_SAME_BUSID` sets it) → `ADD_ACTIVITY(…,3)` in PRE-INSERT never fires |
| 3 | `BUS_ID` commercial register | Copied only the name; no `:GLOBAL.FUNS_BUSID` check | Copies 9 fields (name, std name, expiry, tel, POB, ZIP, fax, telex, activity) and locks them, only when `FUNS_BUSID = 0`; `COMM_TABLE_UNCHECK` read with the 2-argument setting call |
| 4 | `BUS_ID` checks order and texts | Rebuilt texts, ID check before CR checks | Exact order and texts of the trigger (10-digit check, 9-270, 9-260, 9-120 conversion, 9-130, …) |
| 5 | `BUS_ID_BRNCH` | City from `CTRY_CD_OF_ID`, fixed LENGTH rule | City from `CTRY_CD` (`--=100`), whole check only when the item is enabled, CR lookup by `BRNCH_BUS_ID`, message "سيتم تحويل الرقم الفرعي إلى الرقم …" |
| 6 | `IMPR_NBR` WHEN-VALIDATE-ITEM | Only the 9-150 check | Existing number sets `:GLOBAL.PORT_CD/IMPR_NBR/EXEC_QUERY_NOW` → the importer is re-queried |
| 7 | `B_EMAIL` / `B_MOBILE_NO` / `B_ID_NBR` POST-CHANGE | `FLAGUPDATE` only | Also `:PORT_CD := :PARAMETER.P_CURR_PORT_CD` – the row moves to the current port (HIGH, §7.2) |
| 8 | `CITY_CODE_OF_ID` | Error when the city is unknown | Warning only (`'W'`, no failure) |
| 9 | `IMPR_NBR_PARENT` | Error 9-160, filtered by port | Message 9-160 without failure, no port filter (PRE-RECORD uses the port and 9-150) |
| 10 | `IMPR_TEL_NBR`, `B_MOBILE_NO`, `BANK_IBAN`, `ENG_IMPR_NAME`, `B_ID_NBR`, e-mail | Paraphrased texts / simplified rules | Exact texts and rules (e.g. IBAN: `UPPER` only, no blank removal; mobile: port 99 rule first) |
| 11 | `GET_CR_DATA` (Ministry of Commerce) | Marked MANUAL, not converted | Fully converted (`get_cr_data`, `get_main_cr_data`, `get_branch_cr_data`) |
| 12 | `UPDATE_IMPORTER`, `LOV_UPDATE_MOBLIE`, `CREATE_BRKR_IMPR_AUTH` | Not converted | Converted (Confirm / dialog parts → APEX, §5) |
| 13 | `POST-QUERY` | Partial | Complete: duty-difference block, CRQ24602 setting, central suspension, privileged residence, CR-6730 WASL city, CGFK lookups |
| 14 | UPDATE key | `(PORT_CD, IMPR_NBR)` | ROWID of the queried row (Forms key mode), because `PORT_CD` itself can change (row 7) |
| 15 | Page items inside the package | `get_page_rec`, `validate_item`, `page_dml` read `P1110_*` | Moved to `pkg_impr1110_apx`; `pkg_impr1110` has no page item reference (rule 1 of prompt 02) |

---

## 1. Trigger classification (all 376 units)

Groups as in prompt 02. *Target*: package member, `APEX` (standard page component), `APEX LOV`
(Popup LOV / shared LOV), `APEX-DA` (Dynamic Action, §5), `native` (APEX does it without code),
`dropped` (reason in *Note*). *Active lines* = non-blank, non-comment lines of the original.

| Forms unit | Active lines | Group | Target | Note |
|---|---|---|---|---|
| `FORM.KEY-EDIT` | 1 | NAVIGATION | dropped | NIB.KEY_EDIT (MISSING SOURCE, toolbar key library) - APEX buttons/keys |
| `FORM.KEY-DUPREC` | 1 | NAVIGATION | dropped | NIB.KEY_DUPREC (MISSING SOURCE, toolbar key library) - APEX buttons/keys |
| `FORM.PRE-FORM` | 15 | INITIALISATION | dropped | NIB.PRE_FORM (MISSING SOURCE), version globals, NLS date compat, help path - not needed in APEX; date masks set per item |
| `FORM.WHEN-NEW-FORM-INSTANCE` | 82 | INITIALISATION | pkg_impr1110.wnfi | Process "WHEN-NEW-FORM-INSTANCE" (Before Header). NIB.WHEN_NEW_FORM_INSTANCE + CG$WHEN_NEW_FORM_INSTANCE dropped (toolbar library / list population) |
| `FORM.WHEN-WINDOW-ACTIVATED` | 1 | NAVIGATION | dropped | NIB.WHEN_WINDOW_ACTIVATED (MISSING SOURCE, toolbar key library) - APEX buttons/keys |
| `FORM.KEY-ENTQRY` | 1 | NAVIGATION | dropped | NIB.KEY_ENTQRY (MISSING SOURCE, toolbar key library) - APEX buttons/keys |
| `FORM.ON-ERROR` | 1 | NAVIGATION | dropped | NIB.ON_ERROR (MISSING SOURCE, toolbar key library) - APEX buttons/keys |
| `FORM.ON-MESSAGE` | 1 | NAVIGATION | dropped | NIB.ON_MESSAGE (MISSING SOURCE, toolbar key library) - APEX buttons/keys |
| `FORM.KEY-CLRBLK` | 1 | NAVIGATION | dropped | NIB.KEY_CLRBLK (MISSING SOURCE, toolbar key library) - APEX buttons/keys |
| `FORM.KEY-DELREC` | 1 | NAVIGATION | dropped | NIB.KEY_DELREC (MISSING SOURCE, toolbar key library) - APEX buttons/keys |
| `FORM.KEY-F5` | 1 | NAVIGATION | dropped | NIB.KEY_F5 (MISSING SOURCE, toolbar key library) - APEX buttons/keys |
| `FORM.KEY-F4` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `FORM.KEY-NXTREC` | 1 | NAVIGATION | dropped | NIB.KEY_NXTREC (MISSING SOURCE, toolbar key library) - APEX buttons/keys |
| `FORM.KEY-PRVREC` | 1 | NAVIGATION | dropped | NIB.KEY_PRVREC (MISSING SOURCE, toolbar key library) - APEX buttons/keys |
| `FORM.KEY-DOWN` | 1 | NAVIGATION | dropped | NIB.KEY_DOWN (MISSING SOURCE, toolbar key library) - APEX buttons/keys |
| `FORM.KEY-UP` | 1 | NAVIGATION | dropped | NIB.KEY_UP (MISSING SOURCE, toolbar key library) - APEX buttons/keys |
| `FORM.KEY-SCRUP` | 1 | NAVIGATION | dropped | NIB.KEY_SCRUP (MISSING SOURCE, toolbar key library) - APEX buttons/keys |
| `FORM.KEY-SCRDOWN` | 1 | NAVIGATION | dropped | NIB.KEY_SCRDOWN (MISSING SOURCE, toolbar key library) - APEX buttons/keys |
| `FORM.KEY-PRINT` | 1 | NAVIGATION | dropped | NIB.KEY_PRINT (MISSING SOURCE, toolbar key library) - APEX buttons/keys |
| `FORM.KEY-EXIT` | 1 | NAVIGATION | dropped | NIB.KEY_EXIT (MISSING SOURCE, toolbar key library) - APEX buttons/keys |
| `FORM.WHEN-MOUSE-DOWN` | 1 | NAVIGATION | dropped | NIB.WHEN_MOUSE_DOWN (MISSING SOURCE, toolbar key library) - APEX buttons/keys |
| `FORM.KEY-EXEQRY` | 1 | NAVIGATION | dropped | NIB.KEY_EXEQRY (MISSING SOURCE, toolbar key library) - APEX buttons/keys |
| `FORM.KEY-F9` | 23 | UI-ONLY | APEX-DA | Function side menu (LSIDE) toggle -> APEX "Functions" menu; calls ADJ_FUNS -> pkg_impr1110.adj_funs |
| `FORM.WHEN-TIMER-EXPIRED` | 1 | NAVIGATION | dropped | NIB.WHEN_TIMER_EXPIRED (MISSING SOURCE, toolbar key library) - APEX buttons/keys |
| `FORM.KEY-HELP` | 16 | UI-ONLY | dropped | CG help call; help file is empty in the form |
| `FORM.KEY-CLRFRM` | 14 | NAVIGATION | APEX | CLEAR button (clear cache of page 1110); list population dropped |
| `TITLE.CGSO$CHAR_ARB_ED.KEY-LISTVAL` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `TITLE.CGSO$CHAR_ARB_DO_ENB_Y.KEY-LISTVAL` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `TITLE.CGSO$CHAR_ARB_MLINE.KEY-LISTVAL` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `TITLE.CGSO$CHAR_ARB.KEY-LISTVAL` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `TITLE.CGSO$CHAR_ARB_DO.KEY-LISTVAL` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `TITLE.SYSTEM_DATE.WHEN-VALIDATE-ITEM` | 12 | VALIDATION | dropped | Title bar date (OLB block TITLE) |
| `EDI_MSG.EDI_MSG_LOVE_BUT.WHEN-BUTTON-PRESSED` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN1.WHEN-MOUSE-ENTER` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN1.WHEN-MOUSE-LEAVE` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN1.WHEN-MOUSE-CLICK` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN50.WHEN-MOUSE-ENTER` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN50.WHEN-MOUSE-LEAVE` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN50.WHEN-MOUSE-CLICK` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN2.WHEN-MOUSE-ENTER` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN2.WHEN-MOUSE-LEAVE` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN2.WHEN-MOUSE-CLICK` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN49.WHEN-MOUSE-ENTER` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN49.WHEN-MOUSE-LEAVE` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN49.WHEN-MOUSE-CLICK` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN3.WHEN-MOUSE-ENTER` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN3.WHEN-MOUSE-LEAVE` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN3.WHEN-MOUSE-CLICK` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN48.WHEN-MOUSE-ENTER` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN48.WHEN-MOUSE-LEAVE` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN48.WHEN-MOUSE-CLICK` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN4.WHEN-MOUSE-ENTER` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN4.WHEN-MOUSE-LEAVE` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN4.WHEN-MOUSE-CLICK` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN47.WHEN-MOUSE-ENTER` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN47.WHEN-MOUSE-LEAVE` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN47.WHEN-MOUSE-CLICK` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN5.WHEN-MOUSE-ENTER` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN5.WHEN-MOUSE-LEAVE` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN5.WHEN-MOUSE-CLICK` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN46.WHEN-MOUSE-ENTER` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN46.WHEN-MOUSE-LEAVE` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN46.WHEN-MOUSE-CLICK` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN6.WHEN-MOUSE-ENTER` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN6.WHEN-MOUSE-LEAVE` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN6.WHEN-MOUSE-CLICK` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN45.WHEN-MOUSE-ENTER` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN45.WHEN-MOUSE-LEAVE` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN45.WHEN-MOUSE-CLICK` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN7.WHEN-MOUSE-ENTER` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN7.WHEN-MOUSE-LEAVE` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN7.WHEN-MOUSE-CLICK` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN44.WHEN-MOUSE-ENTER` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN44.WHEN-MOUSE-LEAVE` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN44.WHEN-MOUSE-CLICK` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN8.WHEN-MOUSE-ENTER` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN8.WHEN-MOUSE-LEAVE` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN8.WHEN-MOUSE-CLICK` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN43.WHEN-MOUSE-ENTER` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN43.WHEN-MOUSE-LEAVE` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN43.WHEN-MOUSE-CLICK` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN9.WHEN-MOUSE-ENTER` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN9.WHEN-MOUSE-LEAVE` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN9.WHEN-MOUSE-CLICK` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN42.WHEN-MOUSE-ENTER` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN42.WHEN-MOUSE-LEAVE` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN42.WHEN-MOUSE-CLICK` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN10.WHEN-MOUSE-ENTER` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN10.WHEN-MOUSE-LEAVE` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN10.WHEN-MOUSE-CLICK` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN41.WHEN-MOUSE-ENTER` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN41.WHEN-MOUSE-LEAVE` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN41.WHEN-MOUSE-CLICK` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN11.WHEN-MOUSE-ENTER` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN11.WHEN-MOUSE-LEAVE` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN11.WHEN-MOUSE-CLICK` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN40.WHEN-MOUSE-ENTER` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN40.WHEN-MOUSE-LEAVE` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN40.WHEN-MOUSE-CLICK` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN12.WHEN-MOUSE-ENTER` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN12.WHEN-MOUSE-LEAVE` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN12.WHEN-MOUSE-CLICK` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN39.WHEN-MOUSE-ENTER` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN39.WHEN-MOUSE-LEAVE` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN39.WHEN-MOUSE-CLICK` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN13.WHEN-MOUSE-ENTER` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN13.WHEN-MOUSE-LEAVE` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN13.WHEN-MOUSE-CLICK` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN38.WHEN-MOUSE-ENTER` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN38.WHEN-MOUSE-LEAVE` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN38.WHEN-MOUSE-CLICK` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN14.WHEN-MOUSE-ENTER` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN14.WHEN-MOUSE-LEAVE` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN14.WHEN-MOUSE-CLICK` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN37.WHEN-MOUSE-ENTER` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN37.WHEN-MOUSE-LEAVE` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN37.WHEN-MOUSE-CLICK` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN15.WHEN-MOUSE-ENTER` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN15.WHEN-MOUSE-LEAVE` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN15.WHEN-MOUSE-CLICK` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN36.WHEN-MOUSE-ENTER` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN36.WHEN-MOUSE-LEAVE` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN36.WHEN-MOUSE-CLICK` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN16.WHEN-MOUSE-ENTER` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN16.WHEN-MOUSE-LEAVE` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN16.WHEN-MOUSE-CLICK` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN17.WHEN-MOUSE-ENTER` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN17.WHEN-MOUSE-LEAVE` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN17.WHEN-MOUSE-CLICK` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN34.WHEN-MOUSE-ENTER` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN34.WHEN-MOUSE-LEAVE` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN34.WHEN-MOUSE-CLICK` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN35.WHEN-MOUSE-ENTER` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN35.WHEN-MOUSE-LEAVE` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN35.WHEN-MOUSE-CLICK` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN18.WHEN-MOUSE-ENTER` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN18.WHEN-MOUSE-LEAVE` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN18.WHEN-MOUSE-CLICK` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN33.WHEN-MOUSE-ENTER` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN33.WHEN-MOUSE-LEAVE` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN33.WHEN-MOUSE-CLICK` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN19.WHEN-MOUSE-ENTER` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN19.WHEN-MOUSE-LEAVE` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN19.WHEN-MOUSE-CLICK` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN32.WHEN-MOUSE-ENTER` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN32.WHEN-MOUSE-LEAVE` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN32.WHEN-MOUSE-CLICK` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN20.WHEN-MOUSE-ENTER` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN20.WHEN-MOUSE-LEAVE` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN20.WHEN-MOUSE-CLICK` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN31.WHEN-MOUSE-ENTER` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN31.WHEN-MOUSE-LEAVE` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN31.WHEN-MOUSE-CLICK` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN21.WHEN-MOUSE-ENTER` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN21.WHEN-MOUSE-LEAVE` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN21.WHEN-MOUSE-CLICK` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN30.WHEN-MOUSE-ENTER` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN30.WHEN-MOUSE-LEAVE` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN30.WHEN-MOUSE-CLICK` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN22.WHEN-MOUSE-ENTER` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN22.WHEN-MOUSE-LEAVE` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN22.WHEN-MOUSE-CLICK` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN29.WHEN-MOUSE-ENTER` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN29.WHEN-MOUSE-LEAVE` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN29.WHEN-MOUSE-CLICK` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN23.WHEN-MOUSE-ENTER` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN23.WHEN-MOUSE-LEAVE` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN23.WHEN-MOUSE-CLICK` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN28.WHEN-MOUSE-ENTER` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN28.WHEN-MOUSE-LEAVE` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN28.WHEN-MOUSE-CLICK` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN24.WHEN-MOUSE-ENTER` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN24.WHEN-MOUSE-LEAVE` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN24.WHEN-MOUSE-CLICK` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN27.WHEN-MOUSE-ENTER` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN27.WHEN-MOUSE-LEAVE` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN27.WHEN-MOUSE-CLICK` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN25.WHEN-MOUSE-ENTER` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN25.WHEN-MOUSE-LEAVE` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN25.WHEN-MOUSE-CLICK` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN26.WHEN-MOUSE-ENTER` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN26.WHEN-MOUSE-LEAVE` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `LSIDE.FN26.WHEN-MOUSE-CLICK` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `TOOLBAR.KEY-DOWN` | 3 | UI-ONLY | dropped | Function menu keyboard |
| `TOOLBAR.KEY-UP` | 3 | UI-ONLY | dropped | Function menu keyboard |
| `TOOLBAR.KEY-NEXT-ITEM` | 10 | UI-ONLY | dropped | Keyboard navigation of the function menu |
| `TOOLBAR.SAVE.WHEN-BUTTON-PRESSED` | 12 | BUTTON ACTIONS | APEX | SAVE button -> page_dml(SAVE); title refresh dropped |
| `TOOLBAR.CLEAR_ALL.WHEN-BUTTON-PRESSED` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `TOOLBAR.EXIT.WHEN-BUTTON-PRESSED` | 15 | BUTTON ACTIONS | APEX | EXIT button -> branch to menu; :GLOBAL.EXIT=2 is set by other forms only |
| `TOOLBAR.EXIT1.WHEN-BUTTON-PRESSED` | 38 | UI-ONLY | dropped | Toolbar button visibility (OLB) |
| `TOOLBAR.ENTER.WHEN-BUTTON-PRESSED` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `TOOLBAR.EXECUTE.WHEN-BUTTON-PRESSED` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `TOOLBAR.REMOVE.WHEN-BUTTON-PRESSED` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `TOOLBAR.LIST_VALUE.WHEN-BUTTON-PRESSED` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `TOOLBAR.HELP.WHEN-BUTTON-PRESSED` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `TOOLBAR.LAST_REC.WHEN-BUTTON-PRESSED` | 1 | NAVIGATION | dropped | Single-record form region |
| `TOOLBAR.RE_ENTER_QUERY.WHEN-BUTTON-PRESSED` | 6 | NAVIGATION | APEX | QUERY button -> search region |
| `TOOLBAR.FIRST_REC.WHEN-BUTTON-PRESSED` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `TOOLBAR.PAGE_UP.WHEN-BUTTON-PRESSED` | 0 | EMPTY | dropped | no active code (OLB-inherited or fully commented out) |
| `TOOLBAR.PAGE_DOWN.WHEN-BUTTON-PRESSED` | 1 | NAVIGATION | dropped | Single-record form region |
| `TOOLBAR.FUN_BUT.WHEN-MOUSE-UP` | 12 | UI-ONLY | dropped | Side function menu (TMPLT) |
| `TOOLBAR.FUN_BUT.WHEN-MOUSE-DOWN` | 10 | UI-ONLY | APEX-DA | Opens function menu; calls ADJ_FUNS -> pkg_impr1110.adj_funs |
| `IMPORTERS.ON-ERROR` | 80 | PRE/POST DML | pkg_impr1110.importers_on_error | Used by pkg_impr1110_apx.err_text for DB errors |
| `IMPORTERS.POST-QUERY` | 329 | QUERY | pkg_impr1110.importers_post_qry | Process "IMPORTERS.POST-QUERY" via pkg_impr1110_apx.page_fetch |
| `IMPORTERS.PRE-QUERY` | 63 | QUERY | pkg_impr1110.importers_pre_qry | EXEC_QUERY_NOW / PRSNL_IMPR / name criterion; PORT_NAME criterion -> region SQL |
| `IMPORTERS.PRE-INSERT` | 195 | PRE/POST DML | pkg_impr1110.importers_pre_ins | Process "IMPORTERS.PRE-INSERT"; CONFIRM for class 1/type 3 -> Confirm DA on SAVE |
| `IMPORTERS.KEY-HELP` | 128 | UI-ONLY | dropped | 9 copies of the CG help call; help file is empty |
| `IMPORTERS.KEY-DELREC` | 28 | BUTTON ACTIONS | pkg_impr1110.importers_key_delrec | DELETE button + Confirm DA; REMOVE visible/enabled -> button condition |
| `IMPORTERS.POST-INSERT` | 29 | PRE/POST DML | pkg_impr1110.importers_post_ins | Process "IMPORTERS.POST-INSERT" |
| `IMPORTERS.POST-UPDATE` | 20 | PRE/POST DML | pkg_impr1110.importers_post_upd | Process "IMPORTERS.POST-UPDATE" |
| `IMPORTERS.PRE-DELETE` | 5 | PRE/POST DML | pkg_impr1110.importers_pre_del | Called by importers_key_delrec |
| `IMPORTERS.PRE-RECORD` | 17 | INITIALISATION | pkg_impr1110.importers_pre_rec | Parent importer name on record entry |
| `IMPORTERS.PRE-UPDATE` | 125 | PRE/POST DML | pkg_impr1110.importers_pre_upd | Process "IMPORTERS.PRE-UPDATE" |
| `IMPORTERS.WHEN-CLEAR-BLOCK` | 3 | NAVIGATION | pkg_impr1110.importers_wcb | Sets :GLOBAL.STAT_CLR (never read in this form) |
| `IMPORTERS.WHEN-CREATE-RECORD` | 25 | INITIALISATION | pkg_impr1110.importers_wcr | Process "IMPORTERS.WHEN-CREATE-RECORD" (page_new_record) |
| `IMPORTERS.WHEN-NEW-ITEM-INSTANCE` | 7 | NAVIGATION | APEX-DA | EXEC_QUERY_NOW=1 -> re-query (page reload) |
| `IMPORTERS.WHEN-NEW-RECORD-INSTANCE` | 226 | INITIALISATION | pkg_impr1110.importers_wnri | Entrable state + function codes F1..F5/SF6; CONFIRM F1/F5 -> wnri_confirm_text + Confirm DA |
| `IMPORTERS.SDP_PORT_STATUS.KEY-LISTVAL` | 32 | UI-ONLY | native | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| `IMPORTERS.L_CT_CITY_STATUS2.KEY-LISTVAL` | 32 | UI-ONLY | native | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| `IMPORTERS.L_CT_CITY_STATUS.KEY-LISTVAL` | 32 | UI-ONLY | native | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| `IMPORTERS.PORT_CD.KEY-LISTVAL` | 65 | UI-ONLY | APEX LOV | LOV form LOV_SD_PORTS (PORT_TYPE, STATUS=1) -> Popup LOV (item is disabled) |
| `IMPORTERS.PORT_CD.WHEN-VALIDATE-ITEM` | 19 | VALIDATION | pkg_impr1110.port_cd_wvi | PORT_CD is disabled (WNFI) - kept for completeness |
| `IMPORTERS.PORT_CD2.WHEN-BUTTON-PRESSED` | 4 | UI-ONLY | native | LOV button (GO_ITEM + LIST_VALUES) - Popup LOV has its own button |
| `IMPORTERS.PORT_NAME.KEY-LISTVAL` | 32 | UI-ONLY | native | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| `IMPORTERS.HQ_IMPR_NBR.KEY-LISTVAL` | 32 | UI-ONLY | native | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| `IMPORTERS.HQ_IMPR_NBR.POST-CHANGE` | 3 | VALIDATION | pkg_impr1110.hq_impr_nbr_post_chg | :GLOBAL.FLAGUPDATE := 1 |
| `IMPORTERS.IMPR_NBR.KEY-LISTVAL` | 32 | UI-ONLY | native | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| `IMPORTERS.IMPR_NBR.WHEN-VALIDATE-ITEM` | 18 | VALIDATION | pkg_impr1110.impr_nbr_wvi | Existing number -> re-query that importer |
| `IMPORTERS.SUSPN_STATUS.KEY-LISTVAL` | 32 | UI-ONLY | native | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| `IMPORTERS.STATUS_DESC.KEY-LISTVAL` | 32 | UI-ONLY | native | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| `IMPORTERS.IMPR_TYPE_CD.KEY-LISTVAL` | 95 | UI-ONLY | pkg_impr1110.impr_type_cd_lov_ret | LOV form LOV_IMPR_TYPE -> Popup LOV returning 4 columns; post-select logic in package |
| `IMPORTERS.IMPR_TYPE_CD.WHEN-VALIDATE-ITEM` | 206 | VALIDATION | pkg_impr1110.impr_type_cd_wvi | Includes CGFK ITIDT check; DO_KEY LIST_VALUES -> ui OPEN_LOV |
| `IMPORTERS.IMPR_TYPE_CD.POST-CHANGE` | 7 | VALIDATION | pkg_impr1110.impr_type_cd_post_chg |  |
| `IMPORTERS.IMPR_TYPE_CD.WHEN-NEW-ITEM-INSTANCE` | 27 | NAVIGATION | pkg_impr1110.impr_type_cd_wnii | Re-query part -> ui REQUERY; country 100 defaults |
| `IMPORTERS.IMPR_TYPE_CD2.WHEN-BUTTON-PRESSED` | 5 | UI-ONLY | native | LOV button (GO_ITEM + LIST_VALUES) - Popup LOV has its own button |
| `IMPORTERS.IMPR_TYPE_NAME.KEY-LISTVAL` | 32 | UI-ONLY | native | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| `IMPORTERS.BUS_ID_EXPRD_DT.KEY-LISTVAL` | 25 | UI-ONLY | APEX-DA | Same Hijri calendar as KEY-F4 |
| `IMPORTERS.BUS_ID_EXPRD_DT.KEY-F4` | 25 | UI-ONLY | APEX-DA | INTRFACE.Disp_date_con Hijri calendar -> Hijri date picker (decision needed) |
| `IMPORTERS.BUS_ID_EXPRD_DT.WHEN-VALIDATE-ITEM` | 22 | VALIDATION | pkg_impr1110.bus_id_exprd_dt_wvi | p_from_item = (:SYSTEM.TRIGGER_ITEM = :SYSTEM.CURSOR_ITEM) |
| `IMPORTERS.BUS_ID_EXPRD_DT.WHEN-NEW-ITEM-INSTANCE` | 6 | NAVIGATION | APEX-DA | EXEC_QUERY_NOW=1 -> re-query |
| `IMPORTERS.BUS_ID_TYPE_CD.KEY-LISTVAL` | 32 | UI-ONLY | native | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| `IMPORTERS.BUS_ID_TYPE_CD.POST-CHANGE` | 24 | VALIDATION | pkg_impr1110.bus_id_type_post_chg | Swapped country-name assignment kept (SUGGESTION) |
| `IMPORTERS.BUTT.WHEN-BUTTON-PRESSED` | 5 | UI-ONLY | native | LOV button (GO_ITEM + LIST_VALUES) - Popup LOV has its own button |
| `IMPORTERS.BUS_ID_TYPE_NAME.KEY-LISTVAL` | 32 | UI-ONLY | native | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| `IMPORTERS.COMM_RGSTRTN_TYPE.KEY-LISTVAL` | 32 | UI-ONLY | native | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| `IMPORTERS.COMM_RGSTRTN_TYPE.WHEN-LIST-CHANGED` | 14 | UI-ONLY | pkg_impr1110.comm_rgstrtn_wlc | Clears BUS_ID_BRNCH (server) + entrable/required (ui) |
| `IMPORTERS.CITY_CODE_OF_ID.KEY-LISTVAL` | 71 | UI-ONLY | APEX LOV | LOV form LOV_CITIES_IMP (CTRY 100 for type 3/bus 2, else CTRY_CD) -> Popup LOV; returns CTRY_CD_OF_ID too |
| `IMPORTERS.CITY_CODE_OF_ID.WHEN-VALIDATE-ITEM` | 50 | VALIDATION | pkg_impr1110.city_code_of_id_wvi | FK message is a warning (no failure) |
| `IMPORTERS.CITY_CODE_OF_ID.WHEN-NEW-ITEM-INSTANCE` | 6 | UI-ONLY | pkg_impr1110.city_code_of_id_wnii | REQUIRED BRNH_CITY_CD |
| `IMPORTERS.CITY_CODE_OF_ID2.WHEN-BUTTON-PRESSED` | 4 | UI-ONLY | native | LOV button (GO_ITEM + LIST_VALUES) - Popup LOV has its own button |
| `IMPORTERS.ID_CITY_NAME.KEY-LISTVAL` | 32 | UI-ONLY | native | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| `IMPORTERS.BUS_ID.KEY-LISTVAL` | 32 | UI-ONLY | native | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| `IMPORTERS.BUS_ID.POST-CHANGE` | 3 | VALIDATION | pkg_impr1110.bus_id_post_chg |  |
| `IMPORTERS.BUS_ID.WHEN-NEW-ITEM-INSTANCE` | 20 | UI-ONLY | pkg_impr1110.bus_id_wnii | Message 9-240 + GO_ITEM; city commercial code hint |
| `IMPORTERS.BUS_ID.WHEN-VALIDATE-ITEM` | 200 | VALIDATION | pkg_impr1110.bus_id_wvi | 2 alerts -> p_cr_answer / p_susp_answer; MCI service; entrable state |
| `IMPORTERS.BRNH_CITY_CD.KEY-LISTVAL` | 66 | UI-ONLY | APEX LOV | LOV form LOV_CITIES_IMP (CTRY_CD = :CTRY_CD) -> Popup LOV; returns BRNH_CITY_CD/NAME |
| `IMPORTERS.BRNH_CITY_CD.WHEN-NEW-ITEM-INSTANCE` | 7 | UI-ONLY | pkg_impr1110.brnh_city_cd_wnii | REQUIRED flags |
| `IMPORTERS.BRNH_CITY_CD.WHEN-VALIDATE-ITEM` | 14 | VALIDATION | pkg_impr1110.brnh_city_cd_wvi |  |
| `IMPORTERS.BRNH_CITY_CD_LOV.WHEN-BUTTON-PRESSED` | 5 | UI-ONLY | native | LOV button (GO_ITEM + LIST_VALUES) - Popup LOV has its own button |
| `IMPORTERS.BRNH_CITY_NAME.KEY-LISTVAL` | 32 | UI-ONLY | native | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| `IMPORTERS.BUS_ID_BRNCH.KEY-LISTVAL` | 32 | UI-ONLY | native | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| `IMPORTERS.BUS_ID_BRNCH.POST-CHANGE` | 3 | VALIDATION | pkg_impr1110.bus_id_brnch_post_chg |  |
| `IMPORTERS.BUS_ID_BRNCH.WHEN-NEW-ITEM-INSTANCE` | 29 | UI-ONLY | pkg_impr1110.bus_id_brnch_wnii | REQUIRED flag + hint message |
| `IMPORTERS.BUS_ID_BRNCH.WHEN-VALIDATE-ITEM` | 136 | VALIDATION | pkg_impr1110.bus_id_brnch_wvi | Alert 9-120 -> p_cr_answer |
| `IMPORTERS.CTRY_CD.KEY-LISTVAL` | 39 | UI-ONLY | APEX LOV | LOV_COUNTRIES_GULF when type 4 / bus id type 16, else LOV_COUNTRIES -> Popup LOV with conditional query |
| `IMPORTERS.CTRY_CD.WHEN-VALIDATE-ITEM` | 40 | VALIDATION | pkg_impr1110.ctry_cd_wvi | Includes CGFK CTRY check |
| `IMPORTERS.CTRY_CD2.WHEN-BUTTON-PRESSED` | 4 | UI-ONLY | native | LOV button (GO_ITEM + LIST_VALUES) - Popup LOV has its own button |
| `IMPORTERS.CRTY_ARBC_NAME.KEY-LISTVAL` | 32 | UI-ONLY | native | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| `IMPORTERS.IMPR_EXPR_TYPE.KEY-LISTVAL` | 32 | UI-ONLY | native | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| `IMPORTERS.IMPR_EXPR_TYPE.POST-CHANGE` | 3 | VALIDATION | pkg_impr1110.impr_expr_type_post_chg |  |
| `IMPORTERS.CTRY_CTRY_STATUS.KEY-LISTVAL` | 32 | UI-ONLY | native | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| `IMPORTERS.ID_MINS_COMM_CD.KEY-LISTVAL` | 32 | UI-ONLY | native | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| `IMPORTERS.ARBC_IMPR_NAME.KEY-LISTVAL` | 32 | UI-ONLY | native | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| `IMPORTERS.ARBC_IMPR_NAME.KEY-NEXT-ITEM` | 40 | NAVIGATION | pkg_impr1110.arbc_impr_name_key_nxt | Net effect: focus ENG_IMPR_NAME (dummy values are reset) |
| `IMPORTERS.ARBC_IMPR_NAME.WHEN-VALIDATE-ITEM` | 4 | VALIDATION | pkg_impr1110.arbc_impr_name_wvi |  |
| `IMPORTERS.IMPD_STMT_NBR.KEY-LISTVAL` | 32 | UI-ONLY | native | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| `IMPORTERS.IMPR_DATA_SRCE.KEY-LISTVAL` | 32 | UI-ONLY | native | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| `IMPORTERS.ENG_IMPR_NAME.KEY-LISTVAL` | 32 | UI-ONLY | native | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| `IMPORTERS.ENG_IMPR_NAME.WHEN-VALIDATE-ITEM` | 21 | VALIDATION | pkg_impr1110.eng_impr_name_wvi |  |
| `IMPORTERS.IMPR_CNTCT_NAME.KEY-LISTVAL` | 32 | UI-ONLY | native | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| `IMPORTERS.IMPR_ADDRESS.KEY-LISTVAL` | 32 | UI-ONLY | native | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| `IMPORTERS.BUS_ID_ISSUE_DT.WHEN-VALIDATE-ITEM` | 12 | VALIDATION | pkg_impr1110.bus_id_issue_dt_wvi |  |
| `IMPORTERS.IMPR_NBR_PARENT.KEY-LISTVAL` | 62 | UI-ONLY | APEX LOV | LOV form LOV_IMPR (PORT_CD = current port) -> Popup LOV; then focus CITY_CODE |
| `IMPORTERS.IMPR_NBR_PARENT.WHEN-VALIDATE-ITEM` | 16 | VALIDATION | pkg_impr1110.impr_nbr_parent_wvi | 9-160 is a message, not a failure |
| `IMPORTERS.IMPR_NBR_PARENT2.WHEN-BUTTON-PRESSED` | 5 | UI-ONLY | native | LOV button (GO_ITEM + LIST_VALUES) - Popup LOV has its own button |
| `IMPORTERS.IMPR_NAME_PARENT.KEY-LISTVAL` | 32 | UI-ONLY | native | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| `IMPORTERS.WASL_CITY_NAME.KEY-LISTVAL` | 32 | UI-ONLY | native | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| `IMPORTERS.ADD_CTRY_CD.KEY-LISTVAL` | 64 | UI-ONLY | APEX LOV | LOV form LOV_COUNTRIES (STATUS=1) -> Popup LOV |
| `IMPORTERS.ADD_CTRY_CD.WHEN-VALIDATE-ITEM` | 28 | VALIDATION | pkg_impr1110.add_ctry_cd_wvi |  |
| `IMPORTERS.ADD_CTRY_CD2.WHEN-BUTTON-PRESSED` | 4 | UI-ONLY | native | LOV button (GO_ITEM + LIST_VALUES) - Popup LOV has its own button |
| `IMPORTERS.ADD_CRTY_ARBC_NAME.KEY-LISTVAL` | 32 | UI-ONLY | native | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| `IMPORTERS.CITY_CODE.KEY-LISTVAL` | 67 | UI-ONLY | APEX LOV | LOV form LOV_CITIES (CTRY_CD = ADD_CTRY_CD) -> Popup LOV; also returns ADD_CTRY_CD |
| `IMPORTERS.CITY_CODE.WHEN-VALIDATE-ITEM` | 33 | VALIDATION | pkg_impr1110.city_code_wvi |  |
| `IMPORTERS.CITY_CODE2.WHEN-BUTTON-PRESSED` | 5 | UI-ONLY | native | LOV button (GO_ITEM + LIST_VALUES) - Popup LOV has its own button |
| `IMPORTERS.CITY_NAME.KEY-LISTVAL` | 32 | UI-ONLY | native | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| `IMPORTERS.IMPR_POB_NBR.KEY-LISTVAL` | 32 | UI-ONLY | native | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| `IMPORTERS.IMPR_ZIP_CD.KEY-LISTVAL` | 32 | UI-ONLY | native | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| `IMPORTERS.IMPR_TEL_NBR.KEY-LISTVAL` | 32 | UI-ONLY | native | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| `IMPORTERS.IMPR_TEL_NBR.WHEN-VALIDATE-ITEM` | 14 | VALIDATION | pkg_impr1110.impr_tel_nbr_wvi |  |
| `IMPORTERS.IMPR_FAX_NBR.KEY-LISTVAL` | 32 | UI-ONLY | native | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| `IMPORTERS.IMPR_TELEX_NBR.KEY-LISTVAL` | 32 | UI-ONLY | native | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| `IMPORTERS.B_EMAIL.WHEN-VALIDATE-ITEM` | 20 | VALIDATION | pkg_impr1110.b_email_wvi |  |
| `IMPORTERS.B_EMAIL.POST-CHANGE` | 4 | VALIDATION | pkg_impr1110.b_email_post_chg | Moves the row to the current port |
| `IMPORTERS.EMAIL.WHEN-VALIDATE-ITEM` | 20 | VALIDATION | pkg_impr1110.email_wvi | EMAIL is hidden |
| `IMPORTERS.B_MOBILE_NO.KEY-LISTVAL` | 32 | UI-ONLY | native | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| `IMPORTERS.B_MOBILE_NO.POST-CHANGE` | 4 | VALIDATION | pkg_impr1110.b_mobile_no_post_chg | Moves the row to the current port |
| `IMPORTERS.B_MOBILE_NO.WHEN-VALIDATE-ITEM` | 28 | VALIDATION | pkg_impr1110.b_mobile_no_wvi |  |
| `IMPORTERS.MOBILE_NO.KEY-LISTVAL` | 32 | UI-ONLY | native | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| `IMPORTERS.BANK_IBAN.WHEN-NEW-ITEM-INSTANCE` | 5 | UI-ONLY | pkg_impr1110.bank_iban_wnii | Default "SA" on focus |
| `IMPORTERS.BANK_IBAN.WHEN-VALIDATE-ITEM` | 12 | VALIDATION | pkg_impr1110.bank_iban_wvi |  |
| `IMPORTERS.B_ID_NBR.POST-CHANGE` | 4 | VALIDATION | pkg_impr1110.b_id_nbr_post_chg | Moves the row to the current port |
| `IMPORTERS.B_ID_NBR.WHEN-VALIDATE-ITEM` | 16 | VALIDATION | pkg_impr1110.b_id_nbr_wvi |  |
| `IMPORTERS.EXPRESS_POST.KEY-LISTVAL` | 32 | UI-ONLY | native | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| `IMPORTERS.IMPR_ID_TYPE.KEY-LISTVAL` | 32 | UI-ONLY | native | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| `IMPORTERS.CTRY_CD_OF_ID.KEY-LISTVAL` | 32 | UI-ONLY | native | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| `IMPORTERS.CTRY_CD_OF_ID.WHEN-VALIDATE-ITEM` | 13 | VALIDATION | pkg_impr1110.ctry_cd_of_id_wvi | CTRY_CD_OF_ID is hidden |
| `IMPORTERS.EXPD_STMT_NBR.KEY-LISTVAL` | 32 | UI-ONLY | native | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| `IMPORTERS.WVR_ENTRY_NBR.KEY-LISTVAL` | 32 | UI-ONLY | native | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| `IMPORTERS.ACTIVITY.KEY-LISTVAL` | 32 | UI-ONLY | native | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| `IMPORTERS.CUSTOMS_ENTERED.KEY-LISTVAL` | 32 | UI-ONLY | native | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| `IMPORTERS.CUSTOMS_ENTERED2.WHEN-BUTTON-PRESSED` | 4 | UI-ONLY | native | LOV button (GO_ITEM + LIST_VALUES) - Popup LOV has its own button |
| `IMPORTERS.CREATION_FLAG.KEY-LISTVAL` | 32 | UI-ONLY | native | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| `IMPORTERS.CREATION_FLAG2.WHEN-BUTTON-PRESSED` | 4 | UI-ONLY | native | LOV button (GO_ITEM + LIST_VALUES) - Popup LOV has its own button |
| `PU CHECK_TIMEOUT` | 10 | PROGRAM UNIT | dropped | not called; NIB library |
| `PU MOUSE_CLICK` | 7 | PROGRAM UNIT | dropped | not called |
| `PU TOGGEL_WND` | 5 | PROGRAM UNIT | dropped | not called; window API |
| `PU PRINT_REPORT` | 14 | PROGRAM UNIT | dropped | not called; NIB library |
| `PU EXECUTE_FUNCTION` | 144 | PROGRAM UNIT | APEX | TMPLT side-menu dispatcher -> APEX menu calls pkg_impr1110_apx.ajax_fun(code) -> exec_funs |
| `PU TERMINATE_FUN` | 7 | PROGRAM UNIT | dropped | not called; NIB library |
| `PU CHECK_EDI_MSG_LOV` | 9 | PROGRAM UNIT | dropped | not called (EDI messages) |
| `PU CHECK_EDI_MSG_TIMER` | 9 | PROGRAM UNIT | dropped | not called |
| `PU CHECK_EDI_ROLE_ID` | 9 | PROGRAM UNIT | dropped | not called |
| `PU EDI_MSG_LOV` | 8 | PROGRAM UNIT | dropped | not called |
| `PU FOR_EDI_MSG` | 5 | PROGRAM UNIT | dropped | not called |
| `PU RETURN_MSG` | 6 | PROGRAM UNIT | dropped | not called; NIB timers |
| `PU TURN_MSG` | 6 | PROGRAM UNIT | dropped | not called; NIB timers |
| `PU WHEN_TIMER_EXPIRED_MSG` | 8 | PROGRAM UNIT | dropped | not called |
| `PU CG$WHEN_NEW_FORM_INSTANCE` | 9 | PROGRAM UNIT | APEX | only calls CGDV$POPULATE_DYNAMIC_LISTS -> shared LOVs |
| `PU CGDV$POPULATE_DYNAMIC_LISTS` | 21 | PROGRAM UNIT | APEX | list items from CG_REF_CODES -> shared LOVs (domains COMM_RGSTRTN_TYPE, ALLOWED EXPORT) |
| `PU CGFK$QRY_IMPORTERS_IMP_SDP_FK` | 23 | PROGRAM UNIT | dropped | not called |
| `PU CGFK$CHK_IMPORTERS_IMP_SDP_FK` | 23 | PROGRAM UNIT | inlined in port_cd_wvi |  |
| `PU CG$IMPR1110_PROD_CENTRL_GLOBAL` | 3 | PROGRAM UNIT | dropped | holds DEFAULT_WHERE between PRE/POST-QUERY - not needed |
| `PU CGFK$CHK_IMPORTERS_IMP_MB_FK` | 20 | PROGRAM UNIT | dropped | not called |
| `PU CGFK$QRY_IMPORTERS_IMP_ITIDT_F` | 35 | PROGRAM UNIT | inlined in importers_post_qry |  |
| `PU CGFK$CHK_IMPORTERS_IMP_ITIDT_F` | 35 | PROGRAM UNIT | inlined in impr_type_cd_wvi |  |
| `PU CGFK$QRY_IMPORTERS_IMP_CTRY_FK` | 23 | PROGRAM UNIT | inlined in importers_post_qry |  |
| `PU CGFK$CHK_IMPORTERS_IMP_CTRY_FK` | 24 | PROGRAM UNIT | inlined in ctry_cd_wvi |  |
| `PU CGFK$QRY_IMPORTERS_IMP_BUS_ID_` | 32 | PROGRAM UNIT | inlined in importers_post_qry |  |
| `PU CGFK$CHK_IMPORTERS_IMP_BUS_ID_` | 33 | PROGRAM UNIT | inlined in city_code_of_id_wvi |  |
| `PU CGSF$CLRLU_IMPORTERS_IMP_BUS_I` | 18 | PROGRAM UNIT | private cgsf_clrlu_bus_i |  |
| `PU CGFK$QRY_IMPORTERS_IMP_ADD_CIT` | 32 | PROGRAM UNIT | inlined in importers_post_qry |  |
| `PU CGFK$CHK_IMPORTERS_IMP_ADD_CIT` | 33 | PROGRAM UNIT | inlined in add_ctry_cd_wvi / city_code_wvi |  |
| `PU CGTE$CHECK_CONSTRAINT_VIO` | 45 | PROGRAM UNIT | inlined in importers_on_error |  |
| `PU UPDATE_IMPORTER` | 60 | PROGRAM UNIT | pkg_impr1110.update_importer_msg + update_importer (FORMS_DDL COMMIT removed) |  |
| `PU UPDATE_BASIC_IMPORTER` | 23 | PROGRAM UNIT | pkg_impr1110.update_basic_importer (COMMIT removed) |  |
| `PU RETURN_IMPR_ID` | 7 | PROGRAM UNIT | pkg_impr1110.return_impr_id |  |
| `PU LOV_UPDATE_MOBLIE` | 53 | PROGRAM UNIT | pkg_impr1110.central_mobile + lov_update_moblie (dialog LOV_UPDATE_IMPR_MOBILE) |  |
| `PU IS_DIGIT` | 15 | PROGRAM UNIT | pkg_impr1110.is_digit |  |
| `PU INSERT_AUDIT_RECORD` | 45 | PROGRAM UNIT | pkg_impr1110.insert_audit_record |  |
| `PU GET_MAIN_CR_DATA` | 10 | PROGRAM UNIT | pkg_impr1110.get_main_cr_data |  |
| `PU GET_CR_DATA` | 362 | PROGRAM UNIT | pkg_impr1110.get_cr_data |  |
| `PU GET_BRANCH_CR_DATA` | 10 | PROGRAM UNIT | pkg_impr1110.get_branch_cr_data |  |
| `PU EXEC_FUNS` | 77 | PROGRAM UNIT | pkg_impr1110.exec_funs |  |
| `PU DEV_VERSIONS` | 4 | PROGRAM UNIT | dropped | change log only (NULL) |
| `PU CREATE_BRKR_IMPR_AUTH` | 55 | PROGRAM UNIT | pkg_impr1110.create_brkr_impr_auth (COMMIT removed) |  |
| `PU CHK_PERSONAL` | 36 | PROGRAM UNIT | pkg_impr1110.chk_personal |  |
| `PU CHK_IMPR_DUPL` | 33 | PROGRAM UNIT | pkg_impr1110.chk_impr_dupl |  |
| `PU CHK_DUPL_IMP_BRKR` | 27 | PROGRAM UNIT | pkg_impr1110.chk_dupl_imp_brkr |  |
| `PU CHECK_IDNO` | 26 | PROGRAM UNIT | pkg_impr1110.check_idno |  |
| `PU CHECK_BUS_ID` | 5 | PROGRAM UNIT | pkg_impr1110.check_bus_id (body is NULL in Forms) |  |
| `PU CALL_LOV_COUNTRIES` | 31 | PROGRAM UNIT | APEX LOV | LOV form LOV_COUNTRIES -> Popup LOV |
| `PU CALL_LOV_COUN_GULF` | 31 | PROGRAM UNIT | APEX LOV | LOV form LOV_COUNTRIES_GULF -> Popup LOV |
| `PU BROKER_INT` | 7 | PROGRAM UNIT | pkg_impr1110.broker_int |  |
| `PU ADJ_FUNS` | 34 | PROGRAM UNIT | pkg_impr1110.adj_funs + fun_state |  |
| `PU VIEW_SAME_BUSID` | 40 | PROGRAM UNIT | dropped | not called (only setter of :GLOBAL.CHK_DUP_BUSID = 1) |
| `PU CHK_BUS_ID_BRNCH` | 7 | PROGRAM UNIT | pkg_impr1110.chk_bus_id_brnch |  |

---

## 2. Forms built-ins and their replacement

Generated from the original text of every unit that is converted (not `dropped` / `native`).
*Line(s)* are line numbers inside the trigger / program unit text (comment blocks counted, so they
match the XML). Rows with `n/a` do not exist in converted code.

| Trigger / unit | Line(s) in the trigger text | Built-in | Replacement | Where |
|---|---|---|---|---|
| `FORM.WHEN-NEW-FORM-INSTANCE` | 173 | GO_ITEM | ui_focus() -> DA "Set Focus" | pkg (recorder) / DA |
| `FORM.WHEN-NEW-FORM-INSTANCE` | 175,223,230 | SET_ITEM_PROPERTY | ui(item,'ENABLED'|'REQUIRED'|'VISIBLE'|'VALID') -> DA Enable/Disable/Show/Hide/setRequired | pkg (recorder) / DA |
| `FORM.WHEN-NEW-FORM-INSTANCE` | 151,152,153 | INTRFACE.Make_Field_Entrable | entrable(item, flag) -> DA (enable + navigable + updateable) | pkg (recorder) / DA |
| `FORM.WHEN-NEW-FORM-INSTANCE` | 238 | Str.DispArbMsg | disp_arb_ftf / disp_arb_info (STR_DB.GetArbMsg text) | pkg |
| `FORM.WHEN-NEW-FORM-INSTANCE` | 239 | RAISE FORM_TRIGGER_FAILURE | pkg_forms_compat.ftf (-20000) | pkg |
| `FORM.WHEN-NEW-FORM-INSTANCE` | 159,160,161,162,164,166,168,169,179,180,183,184 … | :GLOBAL.* | g_get / g_set (pkg_forms_compat) -> Application Item AI_<NAME> | pkg |
| `FORM.WHEN-NEW-FORM-INSTANCE` | 155,172,201,206 | :PARAMETER.* | t_ctx field | PL/SQL param |
| `FORM.KEY-F9` | 12,18 | GO_ITEM | ui_focus() -> DA "Set Focus" | pkg (recorder) / DA |
| `FORM.KEY-F9` | 8 | GET_ITEM_PROPERTY | t_rec.activity_entr / bus_id_brnch_entr (page state of the item) | PL/SQL param |
| `FORM.KEY-F9` | 12,16 | NAME_IN | direct field of t_rec | PL/SQL param |
| `FORM.KEY-F9` | 13,16 | COPY | n/a in converted code | - |
| `FORM.KEY-CLRFRM` | 4 | CLEAR_BLOCK / CLEAR_FORM | CLEAR button / clear cache | APEX |
| `FORM.KEY-CLRFRM` | 6 | RAISE FORM_TRIGGER_FAILURE | pkg_forms_compat.ftf (-20000) | pkg |
| `FORM.KEY-CLRFRM` | 5 | :SYSTEM.* | TRIGGER_ITEM=CURSOR_ITEM -> p_from_item; RECORD_STATUS -> rec_status; MODE/CURSOR_* -> n/a | PL/SQL param |
| `TOOLBAR.SAVE.WHEN-BUTTON-PRESSED` | 6 | COMMIT / FORMS_DDL(COMMIT) / STANDARD.COMMIT | removed - APEX commits at end of page processing (HIGH, see §7) | - |
| `TOOLBAR.SAVE.WHEN-BUTTON-PRESSED` | 8 | :SYSTEM.* | TRIGGER_ITEM=CURSOR_ITEM -> p_from_item; RECORD_STATUS -> rec_status; MODE/CURSOR_* -> n/a | PL/SQL param |
| `TOOLBAR.SAVE.WHEN-BUTTON-PRESSED` | 12,13 | :PARAMETER.* | t_ctx field | PL/SQL param |
| `TOOLBAR.EXIT.WHEN-BUTTON-PRESSED` | 14 | GET_ITEM_PROPERTY | t_rec.activity_entr / bus_id_brnch_entr (page state of the item) | PL/SQL param |
| `TOOLBAR.EXIT.WHEN-BUTTON-PRESSED` | 10 | SHOW_ALERT / STR.DispAlert | ftf(text) when followed by FTF; info(text) otherwise; CONFIRM/WARNING -> Confirm DA + p_answer | pkg / DA |
| `TOOLBAR.EXIT.WHEN-BUTTON-PRESSED` | 11 | RAISE FORM_TRIGGER_FAILURE | pkg_forms_compat.ftf (-20000) | pkg |
| `TOOLBAR.EXIT.WHEN-BUTTON-PRESSED` | 9,13 | :GLOBAL.* | g_get / g_set (pkg_forms_compat) -> Application Item AI_<NAME> | pkg |
| `TOOLBAR.RE_ENTER_QUERY.WHEN-BUTTON-PRESSED` | 1 | ENTER_QUERY | QUERY button -> search region | APEX |
| `TOOLBAR.RE_ENTER_QUERY.WHEN-BUTTON-PRESSED` | 3,4 | :PARAMETER.* | t_ctx field | PL/SQL param |
| `TOOLBAR.FUN_BUT.WHEN-MOUSE-DOWN` | 10 | GO_ITEM | ui_focus() -> DA "Set Focus" | pkg (recorder) / DA |
| `TOOLBAR.FUN_BUT.WHEN-MOUSE-DOWN` | 8 | NAME_IN | direct field of t_rec | PL/SQL param |
| `TOOLBAR.FUN_BUT.WHEN-MOUSE-DOWN` | 8 | COPY | n/a in converted code | - |
| `IMPORTERS.ON-ERROR` | 46,71,79,94,99 | RAISE FORM_TRIGGER_FAILURE | pkg_forms_compat.ftf (-20000) | pkg |
| `IMPORTERS.POST-QUERY` | 123,128,135,145,152,160,168,175,357,358,359,361 … | SET_ITEM_PROPERTY | ui(item,'ENABLED'|'REQUIRED'|'VISIBLE'|'VALID') -> DA Enable/Disable/Show/Hide/setRequired | pkg (recorder) / DA |
| `IMPORTERS.POST-QUERY` | 377 | SET_BLOCK_PROPERTY | UPDATE_ALLOWED -> button/region condition; DEFAULT_WHERE -> region SQL | DA / region |
| `IMPORTERS.POST-QUERY` | 117,118,120,121,122,124,127,129,131,132,134,136 … | INTRFACE.Make_Field_Entrable | entrable(item, flag) -> DA (enable + navigable + updateable) | pkg (recorder) / DA |
| `IMPORTERS.POST-QUERY` | 256,274,294,308,324 | NAME_IN | direct field of t_rec | PL/SQL param |
| `IMPORTERS.POST-QUERY` | 292,341 | RAISE FORM_TRIGGER_FAILURE | pkg_forms_compat.ftf (-20000) | pkg |
| `IMPORTERS.POST-QUERY` | 272,289,306,322,338 | :SYSTEM.* | TRIGGER_ITEM=CURSOR_ITEM -> p_from_item; RECORD_STATUS -> rec_status; MODE/CURSOR_* -> n/a | PL/SQL param |
| `IMPORTERS.POST-QUERY` | 6,7,115 | :GLOBAL.* | g_get / g_set (pkg_forms_compat) -> Application Item AI_<NAME> | pkg |
| `IMPORTERS.POST-QUERY` | 346 | :PARAMETER.* | t_ctx field | PL/SQL param |
| `IMPORTERS.PRE-QUERY` | 70 | SET_BLOCK_PROPERTY | UPDATE_ALLOWED -> button/region condition; DEFAULT_WHERE -> region SQL | DA / region |
| `IMPORTERS.PRE-QUERY` | 52 | NAME_IN | direct field of t_rec | PL/SQL param |
| `IMPORTERS.PRE-QUERY` | 75 | RAISE FORM_TRIGGER_FAILURE | pkg_forms_compat.ftf (-20000) | pkg |
| `IMPORTERS.PRE-QUERY` | 7,8,9,10,14,15,16 | :GLOBAL.* | g_get / g_set (pkg_forms_compat) -> Application Item AI_<NAME> | pkg |
| `IMPORTERS.PRE-QUERY` | 3 | :PARAMETER.* | t_ctx field | PL/SQL param |
| `IMPORTERS.PRE-INSERT` | 2,174,252 | SET_BLOCK_PROPERTY | UPDATE_ALLOWED -> button/region condition; DEFAULT_WHERE -> region SQL | DA / region |
| `IMPORTERS.PRE-INSERT` | 56 | GET_ITEM_PROPERTY | t_rec.activity_entr / bus_id_brnch_entr (page state of the item) | PL/SQL param |
| `IMPORTERS.PRE-INSERT` | 34,47,156,234,235,236,237,238,239,240,241,242 … | INTRFACE.Make_Field_Entrable | entrable(item, flag) -> DA (enable + navigable + updateable) | pkg (recorder) / DA |
| `IMPORTERS.PRE-INSERT` | 5,10,35,57,65,227,228,249 | SHOW_ALERT / STR.DispAlert | ftf(text) when followed by FTF; info(text) otherwise; CONFIRM/WARNING -> Confirm DA + p_answer | pkg / DA |
| `IMPORTERS.PRE-INSERT` | 48,108,120,137,149,155 | Str.DispArbMsg | disp_arb_ftf / disp_arb_info (STR_DB.GetArbMsg text) | pkg |
| `IMPORTERS.PRE-INSERT` | 265 | NAME_IN | direct field of t_rec | PL/SQL param |
| `IMPORTERS.PRE-INSERT` | 6,11,36,49,58,69,75,109,121,138,150,157 … | RAISE FORM_TRIGGER_FAILURE | pkg_forms_compat.ftf (-20000) | pkg |
| `IMPORTERS.PRE-INSERT` | 164,168,229,232,233 | :GLOBAL.* | g_get / g_set (pkg_forms_compat) -> Application Item AI_<NAME> | pkg |
| `IMPORTERS.PRE-INSERT` | 64,106,135,221,222 | :PARAMETER.* | t_ctx field | PL/SQL param |
| `IMPORTERS.KEY-DELREC` | 8,9 | GET_ITEM_PROPERTY | t_rec.activity_entr / bus_id_brnch_entr (page state of the item) | PL/SQL param |
| `IMPORTERS.KEY-DELREC` | 14 | SHOW_ALERT / STR.DispAlert | ftf(text) when followed by FTF; info(text) otherwise; CONFIRM/WARNING -> Confirm DA + p_answer | pkg / DA |
| `IMPORTERS.KEY-DELREC` | 28,31 | COMMIT / FORMS_DDL(COMMIT) / STANDARD.COMMIT | removed - APEX commits at end of page processing (HIGH, see §7) | - |
| `IMPORTERS.KEY-DELREC` | 7 | NAME_IN | direct field of t_rec | PL/SQL param |
| `IMPORTERS.POST-INSERT` | 4 | SET_BLOCK_PROPERTY | UPDATE_ALLOWED -> button/region condition; DEFAULT_WHERE -> region SQL | DA / region |
| `IMPORTERS.POST-INSERT` | 36,37,38,39,40,41,42,43,44,45,46,47 | INTRFACE.Make_Field_Entrable | entrable(item, flag) -> DA (enable + navigable + updateable) | pkg (recorder) / DA |
| `IMPORTERS.POST-INSERT` | 3,32,33,34 | :GLOBAL.* | g_get / g_set (pkg_forms_compat) -> Application Item AI_<NAME> | pkg |
| `IMPORTERS.POST-INSERT` | 9 | :PARAMETER.* | t_ctx field | PL/SQL param |
| `IMPORTERS.POST-UPDATE` | 3,4,5,6,7,8,9,10,11,12,13 | INTRFACE.Make_Field_Entrable | entrable(item, flag) -> DA (enable + navigable + updateable) | pkg (recorder) / DA |
| `IMPORTERS.POST-UPDATE` | 20,22 | :GLOBAL.* | g_get / g_set (pkg_forms_compat) -> Application Item AI_<NAME> | pkg |
| `IMPORTERS.PRE-DELETE` | 3 | RAISE FORM_TRIGGER_FAILURE | pkg_forms_compat.ftf (-20000) | pkg |
| `IMPORTERS.PRE-RECORD` | 15 | Str.DispArbMsg | disp_arb_ftf / disp_arb_info (STR_DB.GetArbMsg text) | pkg |
| `IMPORTERS.PRE-RECORD` | 7 | :PARAMETER.* | t_ctx field | PL/SQL param |
| `IMPORTERS.PRE-UPDATE` | 51,168 | INTRFACE.Make_Field_Entrable | entrable(item, flag) -> DA (enable + navigable + updateable) | pkg (recorder) / DA |
| `IMPORTERS.PRE-UPDATE` | 9 | SHOW_ALERT / STR.DispAlert | ftf(text) when followed by FTF; info(text) otherwise; CONFIRM/WARNING -> Confirm DA + p_answer | pkg / DA |
| `IMPORTERS.PRE-UPDATE` | 52,127,137,153,162,167 | Str.DispArbMsg | disp_arb_ftf / disp_arb_info (STR_DB.GetArbMsg text) | pkg |
| `IMPORTERS.PRE-UPDATE` | 10,53,79,128,138,154,163,169 | RAISE FORM_TRIGGER_FAILURE | pkg_forms_compat.ftf (-20000) | pkg |
| `IMPORTERS.PRE-UPDATE` | 81,82 | :GLOBAL.* | g_get / g_set (pkg_forms_compat) -> Application Item AI_<NAME> | pkg |
| `IMPORTERS.PRE-UPDATE` | 60,125,150 | :PARAMETER.* | t_ctx field | PL/SQL param |
| `IMPORTERS.WHEN-CLEAR-BLOCK` | 2 | :GLOBAL.* | g_get / g_set (pkg_forms_compat) -> Application Item AI_<NAME> | pkg |
| `IMPORTERS.WHEN-CREATE-RECORD` | 26,31 | SET_ITEM_PROPERTY | ui(item,'ENABLED'|'REQUIRED'|'VISIBLE'|'VALID') -> DA Enable/Disable/Show/Hide/setRequired | pkg (recorder) / DA |
| `IMPORTERS.WHEN-CREATE-RECORD` | 24,25,27,30,38,39 | INTRFACE.Make_Field_Entrable | entrable(item, flag) -> DA (enable + navigable + updateable) | pkg (recorder) / DA |
| `IMPORTERS.WHEN-CREATE-RECORD` | 42 | :GLOBAL.* | g_get / g_set (pkg_forms_compat) -> Application Item AI_<NAME> | pkg |
| `IMPORTERS.WHEN-CREATE-RECORD` | 4,15 | :PARAMETER.* | t_ctx field | PL/SQL param |
| `IMPORTERS.WHEN-NEW-ITEM-INSTANCE` | 4 | EXECUTE_QUERY | ui('IMPORTERS','REQUERY') -> page reload / region refresh | DA |
| `IMPORTERS.WHEN-NEW-ITEM-INSTANCE` | 3 | CLEAR_BLOCK / CLEAR_FORM | CLEAR button / clear cache | APEX |
| `IMPORTERS.WHEN-NEW-ITEM-INSTANCE` | 2,5 | :GLOBAL.* | g_get / g_set (pkg_forms_compat) -> Application Item AI_<NAME> | pkg |
| `IMPORTERS.WHEN-NEW-RECORD-INSTANCE` | 44,71,137,165,170,194,199,203,207,218,240,245 | GO_ITEM | ui_focus() -> DA "Set Focus" | pkg (recorder) / DA |
| `IMPORTERS.WHEN-NEW-RECORD-INSTANCE` | 263,264,273,280 | SET_ITEM_PROPERTY | ui(item,'ENABLED'|'REQUIRED'|'VISIBLE'|'VALID') -> DA Enable/Disable/Show/Hide/setRequired | pkg (recorder) / DA |
| `IMPORTERS.WHEN-NEW-RECORD-INSTANCE` | 10,11,12,24,25,26,27,29,31,33,35,36 … | INTRFACE.Make_Field_Entrable | entrable(item, flag) -> DA (enable + navigable + updateable) | pkg (recorder) / DA |
| `IMPORTERS.WHEN-NEW-RECORD-INSTANCE` | 224,228 | INTRFACE.MAKE_BLOCK_FULL_OPERATION | ui('IMPORTERS','BLOCK_UPDATE_ONLY') | DA |
| `IMPORTERS.WHEN-NEW-RECORD-INSTANCE` | 83,91,98,110,119,126,131,152,160,181,189,226 … | SHOW_ALERT / STR.DispAlert | ftf(text) when followed by FTF; info(text) otherwise; CONFIRM/WARNING -> Confirm DA + p_answer | pkg / DA |
| `IMPORTERS.WHEN-NEW-RECORD-INSTANCE` | 288 | Str.DispArbMsg | disp_arb_ftf / disp_arb_info (STR_DB.GetArbMsg text) | pkg |
| `IMPORTERS.WHEN-NEW-RECORD-INSTANCE` | 227 | COMMIT / FORMS_DDL(COMMIT) / STANDARD.COMMIT | removed - APEX commits at end of page processing (HIGH, see §7) | - |
| `IMPORTERS.WHEN-NEW-RECORD-INSTANCE` | 84,99,111,127,132,153,182,289 | RAISE FORM_TRIGGER_FAILURE | pkg_forms_compat.ftf (-20000) | pkg |
| `IMPORTERS.WHEN-NEW-RECORD-INSTANCE` | 14,15,16,65,215,216 | :GLOBAL.* | g_get / g_set (pkg_forms_compat) -> Application Item AI_<NAME> | pkg |
| `IMPORTERS.WHEN-NEW-RECORD-INSTANCE` | 28,64,72,74,82,95,97,109,123,125,130,135 … | :PARAMETER.* | t_ctx field | PL/SQL param |
| `IMPORTERS.PORT_CD.KEY-LISTVAL` | 8,9,16,17,25 | GET_ITEM_PROPERTY | t_rec.activity_entr / bus_id_brnch_entr (page state of the item) | PL/SQL param |
| `IMPORTERS.PORT_CD.KEY-LISTVAL` | 6 | GET_RECORD_PROPERTY | t_rec.rec_status | PL/SQL param |
| `IMPORTERS.PORT_CD.KEY-LISTVAL` | 46,72 | SHOW_ALERT / STR.DispAlert | ftf(text) when followed by FTF; info(text) otherwise; CONFIRM/WARNING -> Confirm DA + p_answer | pkg / DA |
| `IMPORTERS.PORT_CD.KEY-LISTVAL` | 58 | CALL_FORM | Modal dialog page / Popup LOV (see §5) | APEX |
| `IMPORTERS.PORT_CD.KEY-LISTVAL` | 31,47,73 | RAISE FORM_TRIGGER_FAILURE | pkg_forms_compat.ftf (-20000) | pkg |
| `IMPORTERS.PORT_CD.KEY-LISTVAL` | 5,6,7,8,9,15,16,17,24,25,54 | :SYSTEM.* | TRIGGER_ITEM=CURSOR_ITEM -> p_from_item; RECORD_STATUS -> rec_status; MODE/CURSOR_* -> n/a | PL/SQL param |
| `IMPORTERS.PORT_CD.KEY-LISTVAL` | 64,65,66 | :GLOBAL.* | g_get / g_set (pkg_forms_compat) -> Application Item AI_<NAME> | pkg |
| `IMPORTERS.PORT_CD.KEY-LISTVAL` | 50 | :PARAMETER.* | t_ctx field | PL/SQL param |
| `IMPORTERS.PORT_CD.WHEN-VALIDATE-ITEM` | 18 | NAME_IN | direct field of t_rec | PL/SQL param |
| `IMPORTERS.PORT_CD.WHEN-VALIDATE-ITEM` | 27 | RAISE FORM_TRIGGER_FAILURE | pkg_forms_compat.ftf (-20000) | pkg |
| `IMPORTERS.HQ_IMPR_NBR.POST-CHANGE` | 2 | :GLOBAL.* | g_get / g_set (pkg_forms_compat) -> Application Item AI_<NAME> | pkg |
| `IMPORTERS.IMPR_NBR.WHEN-VALIDATE-ITEM` | 17 | Str.DispArbMsg | disp_arb_ftf / disp_arb_info (STR_DB.GetArbMsg text) | pkg |
| `IMPORTERS.IMPR_NBR.WHEN-VALIDATE-ITEM` | 18 | RAISE FORM_TRIGGER_FAILURE | pkg_forms_compat.ftf (-20000) | pkg |
| `IMPORTERS.IMPR_NBR.WHEN-VALIDATE-ITEM` | 12,13,14 | :GLOBAL.* | g_get / g_set (pkg_forms_compat) -> Application Item AI_<NAME> | pkg |
| `IMPORTERS.IMPR_TYPE_CD.KEY-LISTVAL` | 85,92 | SET_ITEM_PROPERTY | ui(item,'ENABLED'|'REQUIRED'|'VISIBLE'|'VALID') -> DA Enable/Disable/Show/Hide/setRequired | pkg (recorder) / DA |
| `IMPORTERS.IMPR_TYPE_CD.KEY-LISTVAL` | 8,9,16,17,25 | GET_ITEM_PROPERTY | t_rec.activity_entr / bus_id_brnch_entr (page state of the item) | PL/SQL param |
| `IMPORTERS.IMPR_TYPE_CD.KEY-LISTVAL` | 6 | GET_RECORD_PROPERTY | t_rec.rec_status | PL/SQL param |
| `IMPORTERS.IMPR_TYPE_CD.KEY-LISTVAL` | 45,114 | SHOW_ALERT / STR.DispAlert | ftf(text) when followed by FTF; info(text) otherwise; CONFIRM/WARNING -> Confirm DA + p_answer | pkg / DA |
| `IMPORTERS.IMPR_TYPE_CD.KEY-LISTVAL` | 100 | Str.DispArbMsg | disp_arb_ftf / disp_arb_info (STR_DB.GetArbMsg text) | pkg |
| `IMPORTERS.IMPR_TYPE_CD.KEY-LISTVAL` | 66 | CALL_FORM | Modal dialog page / Popup LOV (see §5) | APEX |
| `IMPORTERS.IMPR_TYPE_CD.KEY-LISTVAL` | 31,46,101,115 | RAISE FORM_TRIGGER_FAILURE | pkg_forms_compat.ftf (-20000) | pkg |
| `IMPORTERS.IMPR_TYPE_CD.KEY-LISTVAL` | 5,6,7,8,9,15,16,17,24,25,52 | :SYSTEM.* | TRIGGER_ITEM=CURSOR_ITEM -> p_from_item; RECORD_STATUS -> rec_status; MODE/CURSOR_* -> n/a | PL/SQL param |
| `IMPORTERS.IMPR_TYPE_CD.KEY-LISTVAL` | 58,71,72,73,74,75,76 | :GLOBAL.* | g_get / g_set (pkg_forms_compat) -> Application Item AI_<NAME> | pkg |
| `IMPORTERS.IMPR_TYPE_CD.WHEN-VALIDATE-ITEM` | 94,97,115,124,135,159,166,172,182,234 | SET_ITEM_PROPERTY | ui(item,'ENABLED'|'REQUIRED'|'VISIBLE'|'VALID') -> DA Enable/Disable/Show/Hide/setRequired | pkg (recorder) / DA |
| `IMPORTERS.IMPR_TYPE_CD.WHEN-VALIDATE-ITEM` | 93,96,105,107,112,113,114,116,123,125,130,131 … | INTRFACE.Make_Field_Entrable | entrable(item, flag) -> DA (enable + navigable + updateable) | pkg (recorder) / DA |
| `IMPORTERS.IMPR_TYPE_CD.WHEN-VALIDATE-ITEM` | 194 | SHOW_ALERT / STR.DispAlert | ftf(text) when followed by FTF; info(text) otherwise; CONFIRM/WARNING -> Confirm DA + p_answer | pkg / DA |
| `IMPORTERS.IMPR_TYPE_CD.WHEN-VALIDATE-ITEM` | 19,24,40,68 | Str.DispArbMsg | disp_arb_ftf / disp_arb_info (STR_DB.GetArbMsg text) | pkg |
| `IMPORTERS.IMPR_TYPE_CD.WHEN-VALIDATE-ITEM` | 260 | NAME_IN | direct field of t_rec | PL/SQL param |
| `IMPORTERS.IMPR_TYPE_CD.WHEN-VALIDATE-ITEM` | 63 | DO_KEY | LIST_VALUES -> ui(item,'OPEN_LOV'); Next_Record/Scroll -> dropped | DA |
| `IMPORTERS.IMPR_TYPE_CD.WHEN-VALIDATE-ITEM` | 20,25,41,69,195,272 | RAISE FORM_TRIGGER_FAILURE | pkg_forms_compat.ftf (-20000) | pkg |
| `IMPORTERS.IMPR_TYPE_CD.WHEN-VALIDATE-ITEM` | 45,75,90 | :GLOBAL.* | g_get / g_set (pkg_forms_compat) -> Application Item AI_<NAME> | pkg |
| `IMPORTERS.IMPR_TYPE_CD.WHEN-VALIDATE-ITEM` | 152,215 | :PARAMETER.* | t_ctx field | PL/SQL param |
| `IMPORTERS.IMPR_TYPE_CD.POST-CHANGE` | 7 | SET_ITEM_PROPERTY | ui(item,'ENABLED'|'REQUIRED'|'VISIBLE'|'VALID') -> DA Enable/Disable/Show/Hide/setRequired | pkg (recorder) / DA |
| `IMPORTERS.IMPR_TYPE_CD.POST-CHANGE` | 2 | :GLOBAL.* | g_get / g_set (pkg_forms_compat) -> Application Item AI_<NAME> | pkg |
| `IMPORTERS.IMPR_TYPE_CD.WHEN-NEW-ITEM-INSTANCE` | 14,21 | SET_ITEM_PROPERTY | ui(item,'ENABLED'|'REQUIRED'|'VISIBLE'|'VALID') -> DA Enable/Disable/Show/Hide/setRequired | pkg (recorder) / DA |
| `IMPORTERS.IMPR_TYPE_CD.WHEN-NEW-ITEM-INSTANCE` | 29 | Str.DispArbMsg | disp_arb_ftf / disp_arb_info (STR_DB.GetArbMsg text) | pkg |
| `IMPORTERS.IMPR_TYPE_CD.WHEN-NEW-ITEM-INSTANCE` | 4 | EXECUTE_QUERY | ui('IMPORTERS','REQUERY') -> page reload / region refresh | DA |
| `IMPORTERS.IMPR_TYPE_CD.WHEN-NEW-ITEM-INSTANCE` | 3 | CLEAR_BLOCK / CLEAR_FORM | CLEAR button / clear cache | APEX |
| `IMPORTERS.IMPR_TYPE_CD.WHEN-NEW-ITEM-INSTANCE` | 30 | RAISE FORM_TRIGGER_FAILURE | pkg_forms_compat.ftf (-20000) | pkg |
| `IMPORTERS.IMPR_TYPE_CD.WHEN-NEW-ITEM-INSTANCE` | 2 | :GLOBAL.* | g_get / g_set (pkg_forms_compat) -> Application Item AI_<NAME> | pkg |
| `IMPORTERS.BUS_ID_EXPRD_DT.KEY-LISTVAL` | 5,6,13,14,22 | GET_ITEM_PROPERTY | t_rec.activity_entr / bus_id_brnch_entr (page state of the item) | PL/SQL param |
| `IMPORTERS.BUS_ID_EXPRD_DT.KEY-LISTVAL` | 3 | GET_RECORD_PROPERTY | t_rec.rec_status | PL/SQL param |
| `IMPORTERS.BUS_ID_EXPRD_DT.KEY-LISTVAL` | 2,3,4,5,6,12,13,14,21,22 | :SYSTEM.* | TRIGGER_ITEM=CURSOR_ITEM -> p_from_item; RECORD_STATUS -> rec_status; MODE/CURSOR_* -> n/a | PL/SQL param |
| `IMPORTERS.BUS_ID_EXPRD_DT.KEY-F4` | 5,6,13,14,22 | GET_ITEM_PROPERTY | t_rec.activity_entr / bus_id_brnch_entr (page state of the item) | PL/SQL param |
| `IMPORTERS.BUS_ID_EXPRD_DT.KEY-F4` | 3 | GET_RECORD_PROPERTY | t_rec.rec_status | PL/SQL param |
| `IMPORTERS.BUS_ID_EXPRD_DT.KEY-F4` | 2,3,4,5,6,12,13,14,21,22 | :SYSTEM.* | TRIGGER_ITEM=CURSOR_ITEM -> p_from_item; RECORD_STATUS -> rec_status; MODE/CURSOR_* -> n/a | PL/SQL param |
| `IMPORTERS.BUS_ID_EXPRD_DT.WHEN-VALIDATE-ITEM` | 22 | Str.DispArbMsg | disp_arb_ftf / disp_arb_info (STR_DB.GetArbMsg text) | pkg |
| `IMPORTERS.BUS_ID_EXPRD_DT.WHEN-VALIDATE-ITEM` | 10,23 | RAISE FORM_TRIGGER_FAILURE | pkg_forms_compat.ftf (-20000) | pkg |
| `IMPORTERS.BUS_ID_EXPRD_DT.WHEN-VALIDATE-ITEM` | 5,6,7,20 | :SYSTEM.* | TRIGGER_ITEM=CURSOR_ITEM -> p_from_item; RECORD_STATUS -> rec_status; MODE/CURSOR_* -> n/a | PL/SQL param |
| `IMPORTERS.BUS_ID_EXPRD_DT.WHEN-NEW-ITEM-INSTANCE` | 4 | EXECUTE_QUERY | ui('IMPORTERS','REQUERY') -> page reload / region refresh | DA |
| `IMPORTERS.BUS_ID_EXPRD_DT.WHEN-NEW-ITEM-INSTANCE` | 3 | CLEAR_BLOCK / CLEAR_FORM | CLEAR button / clear cache | APEX |
| `IMPORTERS.BUS_ID_EXPRD_DT.WHEN-NEW-ITEM-INSTANCE` | 2 | :GLOBAL.* | g_get / g_set (pkg_forms_compat) -> Application Item AI_<NAME> | pkg |
| `IMPORTERS.BUS_ID_TYPE_CD.POST-CHANGE` | 12,19 | SET_ITEM_PROPERTY | ui(item,'ENABLED'|'REQUIRED'|'VISIBLE'|'VALID') -> DA Enable/Disable/Show/Hide/setRequired | pkg (recorder) / DA |
| `IMPORTERS.BUS_ID_TYPE_CD.POST-CHANGE` | 27 | Str.DispArbMsg | disp_arb_ftf / disp_arb_info (STR_DB.GetArbMsg text) | pkg |
| `IMPORTERS.BUS_ID_TYPE_CD.POST-CHANGE` | 28 | RAISE FORM_TRIGGER_FAILURE | pkg_forms_compat.ftf (-20000) | pkg |
| `IMPORTERS.BUS_ID_TYPE_CD.POST-CHANGE` | 2 | :GLOBAL.* | g_get / g_set (pkg_forms_compat) -> Application Item AI_<NAME> | pkg |
| `IMPORTERS.COMM_RGSTRTN_TYPE.WHEN-LIST-CHANGED` | 9,10,12,15 | SET_ITEM_PROPERTY | ui(item,'ENABLED'|'REQUIRED'|'VISIBLE'|'VALID') -> DA Enable/Disable/Show/Hide/setRequired | pkg (recorder) / DA |
| `IMPORTERS.COMM_RGSTRTN_TYPE.WHEN-LIST-CHANGED` | 7,8,13,14 | INTRFACE.Make_Field_Entrable | entrable(item, flag) -> DA (enable + navigable + updateable) | pkg (recorder) / DA |
| `IMPORTERS.CITY_CODE_OF_ID.KEY-LISTVAL` | 8,9,16,17,25 | GET_ITEM_PROPERTY | t_rec.activity_entr / bus_id_brnch_entr (page state of the item) | PL/SQL param |
| `IMPORTERS.CITY_CODE_OF_ID.KEY-LISTVAL` | 6 | GET_RECORD_PROPERTY | t_rec.rec_status | PL/SQL param |
| `IMPORTERS.CITY_CODE_OF_ID.KEY-LISTVAL` | 45,79 | SHOW_ALERT / STR.DispAlert | ftf(text) when followed by FTF; info(text) otherwise; CONFIRM/WARNING -> Confirm DA + p_answer | pkg / DA |
| `IMPORTERS.CITY_CODE_OF_ID.KEY-LISTVAL` | 60 | ENTER_QUERY | QUERY button -> search region | APEX |
| `IMPORTERS.CITY_CODE_OF_ID.KEY-LISTVAL` | 64 | CALL_FORM | Modal dialog page / Popup LOV (see §5) | APEX |
| `IMPORTERS.CITY_CODE_OF_ID.KEY-LISTVAL` | 31,46,80 | RAISE FORM_TRIGGER_FAILURE | pkg_forms_compat.ftf (-20000) | pkg |
| `IMPORTERS.CITY_CODE_OF_ID.KEY-LISTVAL` | 5,6,7,8,9,15,16,17,24,25,60 | :SYSTEM.* | TRIGGER_ITEM=CURSOR_ITEM -> p_from_item; RECORD_STATUS -> rec_status; MODE/CURSOR_* -> n/a | PL/SQL param |
| `IMPORTERS.CITY_CODE_OF_ID.KEY-LISTVAL` | 71,72,73,74 | :GLOBAL.* | g_get / g_set (pkg_forms_compat) -> Application Item AI_<NAME> | pkg |
| `IMPORTERS.CITY_CODE_OF_ID.WHEN-VALIDATE-ITEM` | 44,60 | NAME_IN | direct field of t_rec | PL/SQL param |
| `IMPORTERS.CITY_CODE_OF_ID.WHEN-VALIDATE-ITEM` | 45 | :SYSTEM.* | TRIGGER_ITEM=CURSOR_ITEM -> p_from_item; RECORD_STATUS -> rec_status; MODE/CURSOR_* -> n/a | PL/SQL param |
| `IMPORTERS.CITY_CODE_OF_ID.WHEN-NEW-ITEM-INSTANCE` | 8,9 | SET_ITEM_PROPERTY | ui(item,'ENABLED'|'REQUIRED'|'VISIBLE'|'VALID') -> DA Enable/Disable/Show/Hide/setRequired | pkg (recorder) / DA |
| `IMPORTERS.BUS_ID.POST-CHANGE` | 2 | :GLOBAL.* | g_get / g_set (pkg_forms_compat) -> Application Item AI_<NAME> | pkg |
| `IMPORTERS.BUS_ID.WHEN-NEW-ITEM-INSTANCE` | 9 | GO_ITEM | ui_focus() -> DA "Set Focus" | pkg (recorder) / DA |
| `IMPORTERS.BUS_ID.WHEN-NEW-ITEM-INSTANCE` | 7,22,23 | SET_ITEM_PROPERTY | ui(item,'ENABLED'|'REQUIRED'|'VISIBLE'|'VALID') -> DA Enable/Disable/Show/Hide/setRequired | pkg (recorder) / DA |
| `IMPORTERS.BUS_ID.WHEN-NEW-ITEM-INSTANCE` | 30 | SHOW_ALERT / STR.DispAlert | ftf(text) when followed by FTF; info(text) otherwise; CONFIRM/WARNING -> Confirm DA + p_answer | pkg / DA |
| `IMPORTERS.BUS_ID.WHEN-NEW-ITEM-INSTANCE` | 8 | Str.DispArbMsg | disp_arb_ftf / disp_arb_info (STR_DB.GetArbMsg text) | pkg |
| `IMPORTERS.BUS_ID.WHEN-NEW-ITEM-INSTANCE` | 28,30,31 | :GLOBAL.* | g_get / g_set (pkg_forms_compat) -> Application Item AI_<NAME> | pkg |
| `IMPORTERS.BUS_ID.WHEN-VALIDATE-ITEM` | 234,236 | SET_ITEM_PROPERTY | ui(item,'ENABLED'|'REQUIRED'|'VISIBLE'|'VALID') -> DA Enable/Disable/Show/Hide/setRequired | pkg (recorder) / DA |
| `IMPORTERS.BUS_ID.WHEN-VALIDATE-ITEM` | 249 | GET_RECORD_PROPERTY | t_rec.rec_status | PL/SQL param |
| `IMPORTERS.BUS_ID.WHEN-VALIDATE-ITEM` | 189,190,191,192,193,194,195,196,206,207,208,209 … | INTRFACE.Make_Field_Entrable | entrable(item, flag) -> DA (enable + navigable + updateable) | pkg (recorder) / DA |
| `IMPORTERS.BUS_ID.WHEN-VALIDATE-ITEM` | 41,50,94,97,141,155,241 | SHOW_ALERT / STR.DispAlert | ftf(text) when followed by FTF; info(text) otherwise; CONFIRM/WARNING -> Confirm DA + p_answer | pkg / DA |
| `IMPORTERS.BUS_ID.WHEN-VALIDATE-ITEM` | 54,63,69,108,179,203 | Str.DispArbMsg | disp_arb_ftf / disp_arb_info (STR_DB.GetArbMsg text) | pkg |
| `IMPORTERS.BUS_ID.WHEN-VALIDATE-ITEM` | 42,51,55,64,70,101,109,142,180,204,242 | RAISE FORM_TRIGGER_FAILURE | pkg_forms_compat.ftf (-20000) | pkg |
| `IMPORTERS.BUS_ID.WHEN-VALIDATE-ITEM` | 249 | :SYSTEM.* | TRIGGER_ITEM=CURSOR_ITEM -> p_from_item; RECORD_STATUS -> rec_status; MODE/CURSOR_* -> n/a | PL/SQL param |
| `IMPORTERS.BUS_ID.WHEN-VALIDATE-ITEM` | 169,251 | :GLOBAL.* | g_get / g_set (pkg_forms_compat) -> Application Item AI_<NAME> | pkg |
| `IMPORTERS.BRNH_CITY_CD.KEY-LISTVAL` | 8,9,16,17,25 | GET_ITEM_PROPERTY | t_rec.activity_entr / bus_id_brnch_entr (page state of the item) | PL/SQL param |
| `IMPORTERS.BRNH_CITY_CD.KEY-LISTVAL` | 6 | GET_RECORD_PROPERTY | t_rec.rec_status | PL/SQL param |
| `IMPORTERS.BRNH_CITY_CD.KEY-LISTVAL` | 45,76 | SHOW_ALERT / STR.DispAlert | ftf(text) when followed by FTF; info(text) otherwise; CONFIRM/WARNING -> Confirm DA + p_answer | pkg / DA |
| `IMPORTERS.BRNH_CITY_CD.KEY-LISTVAL` | 58 | ENTER_QUERY | QUERY button -> search region | APEX |
| `IMPORTERS.BRNH_CITY_CD.KEY-LISTVAL` | 62 | CALL_FORM | Modal dialog page / Popup LOV (see §5) | APEX |
| `IMPORTERS.BRNH_CITY_CD.KEY-LISTVAL` | 31,46,77 | RAISE FORM_TRIGGER_FAILURE | pkg_forms_compat.ftf (-20000) | pkg |
| `IMPORTERS.BRNH_CITY_CD.KEY-LISTVAL` | 5,6,7,8,9,15,16,17,24,25,58 | :SYSTEM.* | TRIGGER_ITEM=CURSOR_ITEM -> p_from_item; RECORD_STATUS -> rec_status; MODE/CURSOR_* -> n/a | PL/SQL param |
| `IMPORTERS.BRNH_CITY_CD.KEY-LISTVAL` | 69,70,71 | :GLOBAL.* | g_get / g_set (pkg_forms_compat) -> Application Item AI_<NAME> | pkg |
| `IMPORTERS.BRNH_CITY_CD.WHEN-NEW-ITEM-INSTANCE` | 12,13,14 | SET_ITEM_PROPERTY | ui(item,'ENABLED'|'REQUIRED'|'VISIBLE'|'VALID') -> DA Enable/Disable/Show/Hide/setRequired | pkg (recorder) / DA |
| `IMPORTERS.BRNH_CITY_CD.WHEN-VALIDATE-ITEM` | 12 | Str.DispArbMsg | disp_arb_ftf / disp_arb_info (STR_DB.GetArbMsg text) | pkg |
| `IMPORTERS.BRNH_CITY_CD.WHEN-VALIDATE-ITEM` | 13 | RAISE FORM_TRIGGER_FAILURE | pkg_forms_compat.ftf (-20000) | pkg |
| `IMPORTERS.BUS_ID_BRNCH.POST-CHANGE` | 2 | :GLOBAL.* | g_get / g_set (pkg_forms_compat) -> Application Item AI_<NAME> | pkg |
| `IMPORTERS.BUS_ID_BRNCH.WHEN-NEW-ITEM-INSTANCE` | 10 | SET_ITEM_PROPERTY | ui(item,'ENABLED'|'REQUIRED'|'VISIBLE'|'VALID') -> DA Enable/Disable/Show/Hide/setRequired | pkg (recorder) / DA |
| `IMPORTERS.BUS_ID_BRNCH.WHEN-NEW-ITEM-INSTANCE` | 38 | SHOW_ALERT / STR.DispAlert | ftf(text) when followed by FTF; info(text) otherwise; CONFIRM/WARNING -> Confirm DA + p_answer | pkg / DA |
| `IMPORTERS.BUS_ID_BRNCH.WHEN-NEW-ITEM-INSTANCE` | 36,38,39 | :GLOBAL.* | g_get / g_set (pkg_forms_compat) -> Application Item AI_<NAME> | pkg |
| `IMPORTERS.BUS_ID_BRNCH.WHEN-VALIDATE-ITEM` | 86 | SET_ITEM_PROPERTY | ui(item,'ENABLED'|'REQUIRED'|'VISIBLE'|'VALID') -> DA Enable/Disable/Show/Hide/setRequired | pkg (recorder) / DA |
| `IMPORTERS.BUS_ID_BRNCH.WHEN-VALIDATE-ITEM` | 2 | GET_ITEM_PROPERTY | t_rec.activity_entr / bus_id_brnch_entr (page state of the item) | PL/SQL param |
| `IMPORTERS.BUS_ID_BRNCH.WHEN-VALIDATE-ITEM` | 164 | GET_RECORD_PROPERTY | t_rec.rec_status | PL/SQL param |
| `IMPORTERS.BUS_ID_BRNCH.WHEN-VALIDATE-ITEM` | 124,125,126,127,128,129,130,141,142,143,144,145 … | INTRFACE.Make_Field_Entrable | entrable(item, flag) -> DA (enable + navigable + updateable) | pkg (recorder) / DA |
| `IMPORTERS.BUS_ID_BRNCH.WHEN-VALIDATE-ITEM` | 63,66 | SHOW_ALERT / STR.DispAlert | ftf(text) when followed by FTF; info(text) otherwise; CONFIRM/WARNING -> Confirm DA + p_answer | pkg / DA |
| `IMPORTERS.BUS_ID_BRNCH.WHEN-VALIDATE-ITEM` | 22,30,38,80,112,137 | Str.DispArbMsg | disp_arb_ftf / disp_arb_info (STR_DB.GetArbMsg text) | pkg |
| `IMPORTERS.BUS_ID_BRNCH.WHEN-VALIDATE-ITEM` | 23,31,39,71,81,113,138 | RAISE FORM_TRIGGER_FAILURE | pkg_forms_compat.ftf (-20000) | pkg |
| `IMPORTERS.BUS_ID_BRNCH.WHEN-VALIDATE-ITEM` | 164 | :SYSTEM.* | TRIGGER_ITEM=CURSOR_ITEM -> p_from_item; RECORD_STATUS -> rec_status; MODE/CURSOR_* -> n/a | PL/SQL param |
| `IMPORTERS.BUS_ID_BRNCH.WHEN-VALIDATE-ITEM` | 94,166 | :GLOBAL.* | g_get / g_set (pkg_forms_compat) -> Application Item AI_<NAME> | pkg |
| `IMPORTERS.CTRY_CD.KEY-LISTVAL` | 8,9,16,17,25 | GET_ITEM_PROPERTY | t_rec.activity_entr / bus_id_brnch_entr (page state of the item) | PL/SQL param |
| `IMPORTERS.CTRY_CD.KEY-LISTVAL` | 6 | GET_RECORD_PROPERTY | t_rec.rec_status | PL/SQL param |
| `IMPORTERS.CTRY_CD.KEY-LISTVAL` | 31 | RAISE FORM_TRIGGER_FAILURE | pkg_forms_compat.ftf (-20000) | pkg |
| `IMPORTERS.CTRY_CD.KEY-LISTVAL` | 5,6,7,8,9,15,16,17,24,25 | :SYSTEM.* | TRIGGER_ITEM=CURSOR_ITEM -> p_from_item; RECORD_STATUS -> rec_status; MODE/CURSOR_* -> n/a | PL/SQL param |
| `IMPORTERS.CTRY_CD.WHEN-VALIDATE-ITEM` | 18 | SHOW_ALERT / STR.DispAlert | ftf(text) when followed by FTF; info(text) otherwise; CONFIRM/WARNING -> Confirm DA + p_answer | pkg / DA |
| `IMPORTERS.CTRY_CD.WHEN-VALIDATE-ITEM` | 43 | NAME_IN | direct field of t_rec | PL/SQL param |
| `IMPORTERS.CTRY_CD.WHEN-VALIDATE-ITEM` | 19,52 | RAISE FORM_TRIGGER_FAILURE | pkg_forms_compat.ftf (-20000) | pkg |
| `IMPORTERS.IMPR_EXPR_TYPE.POST-CHANGE` | 2 | :GLOBAL.* | g_get / g_set (pkg_forms_compat) -> Application Item AI_<NAME> | pkg |
| `IMPORTERS.ARBC_IMPR_NAME.KEY-NEXT-ITEM` | 51 | GO_ITEM | ui_focus() -> DA "Set Focus" | pkg (recorder) / DA |
| `IMPORTERS.ENG_IMPR_NAME.WHEN-VALIDATE-ITEM` | 21 | SHOW_ALERT / STR.DispAlert | ftf(text) when followed by FTF; info(text) otherwise; CONFIRM/WARNING -> Confirm DA + p_answer | pkg / DA |
| `IMPORTERS.ENG_IMPR_NAME.WHEN-VALIDATE-ITEM` | 22 | RAISE FORM_TRIGGER_FAILURE | pkg_forms_compat.ftf (-20000) | pkg |
| `IMPORTERS.BUS_ID_ISSUE_DT.WHEN-VALIDATE-ITEM` | 10 | RAISE FORM_TRIGGER_FAILURE | pkg_forms_compat.ftf (-20000) | pkg |
| `IMPORTERS.BUS_ID_ISSUE_DT.WHEN-VALIDATE-ITEM` | 5,6,7 | :SYSTEM.* | TRIGGER_ITEM=CURSOR_ITEM -> p_from_item; RECORD_STATUS -> rec_status; MODE/CURSOR_* -> n/a | PL/SQL param |
| `IMPORTERS.IMPR_NBR_PARENT.KEY-LISTVAL` | 62 | GO_ITEM | ui_focus() -> DA "Set Focus" | pkg (recorder) / DA |
| `IMPORTERS.IMPR_NBR_PARENT.KEY-LISTVAL` | 8,9,16,17,25 | GET_ITEM_PROPERTY | t_rec.activity_entr / bus_id_brnch_entr (page state of the item) | PL/SQL param |
| `IMPORTERS.IMPR_NBR_PARENT.KEY-LISTVAL` | 6 | GET_RECORD_PROPERTY | t_rec.rec_status | PL/SQL param |
| `IMPORTERS.IMPR_NBR_PARENT.KEY-LISTVAL` | 46,68 | SHOW_ALERT / STR.DispAlert | ftf(text) when followed by FTF; info(text) otherwise; CONFIRM/WARNING -> Confirm DA + p_answer | pkg / DA |
| `IMPORTERS.IMPR_NBR_PARENT.KEY-LISTVAL` | 53 | CALL_FORM | Modal dialog page / Popup LOV (see §5) | APEX |
| `IMPORTERS.IMPR_NBR_PARENT.KEY-LISTVAL` | 31,47,69 | RAISE FORM_TRIGGER_FAILURE | pkg_forms_compat.ftf (-20000) | pkg |
| `IMPORTERS.IMPR_NBR_PARENT.KEY-LISTVAL` | 5,6,7,8,9,15,16,17,24,25 | :SYSTEM.* | TRIGGER_ITEM=CURSOR_ITEM -> p_from_item; RECORD_STATUS -> rec_status; MODE/CURSOR_* -> n/a | PL/SQL param |
| `IMPORTERS.IMPR_NBR_PARENT.KEY-LISTVAL` | 59,60,61 | :GLOBAL.* | g_get / g_set (pkg_forms_compat) -> Application Item AI_<NAME> | pkg |
| `IMPORTERS.IMPR_NBR_PARENT.KEY-LISTVAL` | 50 | :PARAMETER.* | t_ctx field | PL/SQL param |
| `IMPORTERS.IMPR_NBR_PARENT.WHEN-VALIDATE-ITEM` | 14 | Str.DispArbMsg | disp_arb_ftf / disp_arb_info (STR_DB.GetArbMsg text) | pkg |
| `IMPORTERS.ADD_CTRY_CD.KEY-LISTVAL` | 8,9,16,17,25 | GET_ITEM_PROPERTY | t_rec.activity_entr / bus_id_brnch_entr (page state of the item) | PL/SQL param |
| `IMPORTERS.ADD_CTRY_CD.KEY-LISTVAL` | 6 | GET_RECORD_PROPERTY | t_rec.rec_status | PL/SQL param |
| `IMPORTERS.ADD_CTRY_CD.KEY-LISTVAL` | 46,72 | SHOW_ALERT / STR.DispAlert | ftf(text) when followed by FTF; info(text) otherwise; CONFIRM/WARNING -> Confirm DA + p_answer | pkg / DA |
| `IMPORTERS.ADD_CTRY_CD.KEY-LISTVAL` | 58 | CALL_FORM | Modal dialog page / Popup LOV (see §5) | APEX |
| `IMPORTERS.ADD_CTRY_CD.KEY-LISTVAL` | 31,47,73 | RAISE FORM_TRIGGER_FAILURE | pkg_forms_compat.ftf (-20000) | pkg |
| `IMPORTERS.ADD_CTRY_CD.KEY-LISTVAL` | 5,6,7,8,9,15,16,17,24,25,50 | :SYSTEM.* | TRIGGER_ITEM=CURSOR_ITEM -> p_from_item; RECORD_STATUS -> rec_status; MODE/CURSOR_* -> n/a | PL/SQL param |
| `IMPORTERS.ADD_CTRY_CD.KEY-LISTVAL` | 64,65,66 | :GLOBAL.* | g_get / g_set (pkg_forms_compat) -> Application Item AI_<NAME> | pkg |
| `IMPORTERS.ADD_CTRY_CD.WHEN-VALIDATE-ITEM` | 9 | Str.DispArbMsg | disp_arb_ftf / disp_arb_info (STR_DB.GetArbMsg text) | pkg |
| `IMPORTERS.ADD_CTRY_CD.WHEN-VALIDATE-ITEM` | 16 | NAME_IN | direct field of t_rec | PL/SQL param |
| `IMPORTERS.ADD_CTRY_CD.WHEN-VALIDATE-ITEM` | 10 | RAISE FORM_TRIGGER_FAILURE | pkg_forms_compat.ftf (-20000) | pkg |
| `IMPORTERS.CITY_CODE.KEY-LISTVAL` | 8,9,16,17,25 | GET_ITEM_PROPERTY | t_rec.activity_entr / bus_id_brnch_entr (page state of the item) | PL/SQL param |
| `IMPORTERS.CITY_CODE.KEY-LISTVAL` | 6 | GET_RECORD_PROPERTY | t_rec.rec_status | PL/SQL param |
| `IMPORTERS.CITY_CODE.KEY-LISTVAL` | 45,77 | SHOW_ALERT / STR.DispAlert | ftf(text) when followed by FTF; info(text) otherwise; CONFIRM/WARNING -> Confirm DA + p_answer | pkg / DA |
| `IMPORTERS.CITY_CODE.KEY-LISTVAL` | 58 | ENTER_QUERY | QUERY button -> search region | APEX |
| `IMPORTERS.CITY_CODE.KEY-LISTVAL` | 62 | CALL_FORM | Modal dialog page / Popup LOV (see §5) | APEX |
| `IMPORTERS.CITY_CODE.KEY-LISTVAL` | 31,46,78 | RAISE FORM_TRIGGER_FAILURE | pkg_forms_compat.ftf (-20000) | pkg |
| `IMPORTERS.CITY_CODE.KEY-LISTVAL` | 5,6,7,8,9,15,16,17,24,25,58 | :SYSTEM.* | TRIGGER_ITEM=CURSOR_ITEM -> p_from_item; RECORD_STATUS -> rec_status; MODE/CURSOR_* -> n/a | PL/SQL param |
| `IMPORTERS.CITY_CODE.KEY-LISTVAL` | 69,70,71,72 | :GLOBAL.* | g_get / g_set (pkg_forms_compat) -> Application Item AI_<NAME> | pkg |
| `IMPORTERS.CITY_CODE.WHEN-VALIDATE-ITEM` | 6 | SHOW_ALERT / STR.DispAlert | ftf(text) when followed by FTF; info(text) otherwise; CONFIRM/WARNING -> Confirm DA + p_answer | pkg / DA |
| `IMPORTERS.CITY_CODE.WHEN-VALIDATE-ITEM` | 16 | Str.DispArbMsg | disp_arb_ftf / disp_arb_info (STR_DB.GetArbMsg text) | pkg |
| `IMPORTERS.CITY_CODE.WHEN-VALIDATE-ITEM` | 23 | NAME_IN | direct field of t_rec | PL/SQL param |
| `IMPORTERS.CITY_CODE.WHEN-VALIDATE-ITEM` | 7,17 | RAISE FORM_TRIGGER_FAILURE | pkg_forms_compat.ftf (-20000) | pkg |
| `IMPORTERS.IMPR_TEL_NBR.WHEN-VALIDATE-ITEM` | 4,9,14 | SHOW_ALERT / STR.DispAlert | ftf(text) when followed by FTF; info(text) otherwise; CONFIRM/WARNING -> Confirm DA + p_answer | pkg / DA |
| `IMPORTERS.IMPR_TEL_NBR.WHEN-VALIDATE-ITEM` | 5,10,15 | RAISE FORM_TRIGGER_FAILURE | pkg_forms_compat.ftf (-20000) | pkg |
| `IMPORTERS.B_EMAIL.WHEN-VALIDATE-ITEM` | 22 | SHOW_ALERT / STR.DispAlert | ftf(text) when followed by FTF; info(text) otherwise; CONFIRM/WARNING -> Confirm DA + p_answer | pkg / DA |
| `IMPORTERS.B_EMAIL.WHEN-VALIDATE-ITEM` | 23 | RAISE FORM_TRIGGER_FAILURE | pkg_forms_compat.ftf (-20000) | pkg |
| `IMPORTERS.B_EMAIL.WHEN-VALIDATE-ITEM` | 11,13 | :SYSTEM.* | TRIGGER_ITEM=CURSOR_ITEM -> p_from_item; RECORD_STATUS -> rec_status; MODE/CURSOR_* -> n/a | PL/SQL param |
| `IMPORTERS.B_EMAIL.POST-CHANGE` | 2 | :GLOBAL.* | g_get / g_set (pkg_forms_compat) -> Application Item AI_<NAME> | pkg |
| `IMPORTERS.B_EMAIL.POST-CHANGE` | 3 | :PARAMETER.* | t_ctx field | PL/SQL param |
| `IMPORTERS.EMAIL.WHEN-VALIDATE-ITEM` | 22 | SHOW_ALERT / STR.DispAlert | ftf(text) when followed by FTF; info(text) otherwise; CONFIRM/WARNING -> Confirm DA + p_answer | pkg / DA |
| `IMPORTERS.EMAIL.WHEN-VALIDATE-ITEM` | 23 | RAISE FORM_TRIGGER_FAILURE | pkg_forms_compat.ftf (-20000) | pkg |
| `IMPORTERS.EMAIL.WHEN-VALIDATE-ITEM` | 11,13 | :SYSTEM.* | TRIGGER_ITEM=CURSOR_ITEM -> p_from_item; RECORD_STATUS -> rec_status; MODE/CURSOR_* -> n/a | PL/SQL param |
| `IMPORTERS.B_MOBILE_NO.POST-CHANGE` | 2 | :GLOBAL.* | g_get / g_set (pkg_forms_compat) -> Application Item AI_<NAME> | pkg |
| `IMPORTERS.B_MOBILE_NO.POST-CHANGE` | 3 | :PARAMETER.* | t_ctx field | PL/SQL param |
| `IMPORTERS.B_MOBILE_NO.WHEN-VALIDATE-ITEM` | 7,22,29 | SHOW_ALERT / STR.DispAlert | ftf(text) when followed by FTF; info(text) otherwise; CONFIRM/WARNING -> Confirm DA + p_answer | pkg / DA |
| `IMPORTERS.B_MOBILE_NO.WHEN-VALIDATE-ITEM` | 8,23,30 | RAISE FORM_TRIGGER_FAILURE | pkg_forms_compat.ftf (-20000) | pkg |
| `IMPORTERS.B_MOBILE_NO.WHEN-VALIDATE-ITEM` | 6 | :GLOBAL.* | g_get / g_set (pkg_forms_compat) -> Application Item AI_<NAME> | pkg |
| `IMPORTERS.B_MOBILE_NO.WHEN-VALIDATE-ITEM` | 5 | :PARAMETER.* | t_ctx field | PL/SQL param |
| `IMPORTERS.BANK_IBAN.WHEN-VALIDATE-ITEM` | 12 | SHOW_ALERT / STR.DispAlert | ftf(text) when followed by FTF; info(text) otherwise; CONFIRM/WARNING -> Confirm DA + p_answer | pkg / DA |
| `IMPORTERS.BANK_IBAN.WHEN-VALIDATE-ITEM` | 13 | RAISE FORM_TRIGGER_FAILURE | pkg_forms_compat.ftf (-20000) | pkg |
| `IMPORTERS.B_ID_NBR.POST-CHANGE` | 2 | :GLOBAL.* | g_get / g_set (pkg_forms_compat) -> Application Item AI_<NAME> | pkg |
| `IMPORTERS.B_ID_NBR.POST-CHANGE` | 3 | :PARAMETER.* | t_ctx field | PL/SQL param |
| `IMPORTERS.B_ID_NBR.WHEN-VALIDATE-ITEM` | 8,14 | SHOW_ALERT / STR.DispAlert | ftf(text) when followed by FTF; info(text) otherwise; CONFIRM/WARNING -> Confirm DA + p_answer | pkg / DA |
| `IMPORTERS.B_ID_NBR.WHEN-VALIDATE-ITEM` | 9,15 | RAISE FORM_TRIGGER_FAILURE | pkg_forms_compat.ftf (-20000) | pkg |
| `IMPORTERS.CTRY_CD_OF_ID.WHEN-VALIDATE-ITEM` | 4 | NAME_IN | direct field of t_rec | PL/SQL param |
| `IMPORTERS.CTRY_CD_OF_ID.WHEN-VALIDATE-ITEM` | 5 | :SYSTEM.* | TRIGGER_ITEM=CURSOR_ITEM -> p_from_item; RECORD_STATUS -> rec_status; MODE/CURSOR_* -> n/a | PL/SQL param |
| `PU EXECUTE_FUNCTION` | 50,58,119,121,130,132,144,148,157 | SHOW_ALERT / STR.DispAlert | ftf(text) when followed by FTF; info(text) otherwise; CONFIRM/WARNING -> Confirm DA + p_answer | pkg / DA |
| `PU EXECUTE_FUNCTION` | 95,106 | CALL_FORM | Modal dialog page / Popup LOV (see §5) | APEX |
| `PU EXECUTE_FUNCTION` | 28 | NAME_IN | direct field of t_rec | PL/SQL param |
| `PU EXECUTE_FUNCTION` | 117,128 | HOST / TEXT_IO / RUN_REPORT_OBJECT | n/a in converted code | - |
| `PU EXECUTE_FUNCTION` | 59,145 | RAISE FORM_TRIGGER_FAILURE | pkg_forms_compat.ftf (-20000) | pkg |
| `PU EXECUTE_FUNCTION` | 102,104 | :GLOBAL.* | g_get / g_set (pkg_forms_compat) -> Application Item AI_<NAME> | pkg |
| `PU EXECUTE_FUNCTION` | 22,62,63,64,65,66,67,68,69,70,73,74 … | :PARAMETER.* | t_ctx field | PL/SQL param |
| `PU CGDV$POPULATE_DYNAMIC_LISTS` | 7,12,13,16,21,22 | CREATE_GROUP / POPULATE_GROUP | shared LOV (CG_REF_CODES domains) | APEX LOV |
| `PU UPDATE_IMPORTER` | 46,59 | SHOW_ALERT / STR.DispAlert | ftf(text) when followed by FTF; info(text) otherwise; CONFIRM/WARNING -> Confirm DA + p_answer | pkg / DA |
| `PU UPDATE_IMPORTER` | 14 | COMMIT / FORMS_DDL(COMMIT) / STANDARD.COMMIT | removed - APEX commits at end of page processing (HIGH, see §7) | - |
| `PU UPDATE_IMPORTER` | 12,13,15,50,51 | :SYSTEM.* | TRIGGER_ITEM=CURSOR_ITEM -> p_from_item; RECORD_STATUS -> rec_status; MODE/CURSOR_* -> n/a | PL/SQL param |
| `PU RETURN_IMPR_ID` | 5,6 | :GLOBAL.* | g_get / g_set (pkg_forms_compat) -> Application Item AI_<NAME> | pkg |
| `PU RETURN_IMPR_ID` | 3 | :PARAMETER.* | t_ctx field | PL/SQL param |
| `PU LOV_UPDATE_MOBLIE` | 18,45,54,65 | SHOW_ALERT / STR.DispAlert | ftf(text) when followed by FTF; info(text) otherwise; CONFIRM/WARNING -> Confirm DA + p_answer | pkg / DA |
| `PU LOV_UPDATE_MOBLIE` | 38 | CALL_FORM | Modal dialog page / Popup LOV (see §5) | APEX |
| `PU LOV_UPDATE_MOBLIE` | 19,46,55 | RAISE FORM_TRIGGER_FAILURE | pkg_forms_compat.ftf (-20000) | pkg |
| `PU LOV_UPDATE_MOBLIE` | 50,52,58 | :GLOBAL.* | g_get / g_set (pkg_forms_compat) -> Application Item AI_<NAME> | pkg |
| `PU LOV_UPDATE_MOBLIE` | 26 | :PARAMETER.* | t_ctx field | PL/SQL param |
| `PU INSERT_AUDIT_RECORD` | 55 | Str.DispArbMsg | disp_arb_ftf / disp_arb_info (STR_DB.GetArbMsg text) | pkg |
| `PU INSERT_AUDIT_RECORD` | 56 | RAISE FORM_TRIGGER_FAILURE | pkg_forms_compat.ftf (-20000) | pkg |
| `PU INSERT_AUDIT_RECORD` | 12,20 | :PARAMETER.* | t_ctx field | PL/SQL param |
| `PU GET_CR_DATA` | 64 | SHOW_ALERT / STR.DispAlert | ftf(text) when followed by FTF; info(text) otherwise; CONFIRM/WARNING -> Confirm DA + p_answer | pkg / DA |
| `PU EXEC_FUNS` | 54 | GO_BLOCK | region navigation | APEX-DA |
| `PU EXEC_FUNS` | 39,86,89,92,95,113 | SHOW_ALERT / STR.DispAlert | ftf(text) when followed by FTF; info(text) otherwise; CONFIRM/WARNING -> Confirm DA + p_answer | pkg / DA |
| `PU EXEC_FUNS` | 47 | CALL_FORM | Modal dialog page / Popup LOV (see §5) | APEX |
| `PU EXEC_FUNS` | 40,114 | RAISE FORM_TRIGGER_FAILURE | pkg_forms_compat.ftf (-20000) | pkg |
| `PU EXEC_FUNS` | 50,52,65 | :GLOBAL.* | g_get / g_set (pkg_forms_compat) -> Application Item AI_<NAME> | pkg |
| `PU EXEC_FUNS` | 12,51,52,62 | :PARAMETER.* | t_ctx field | PL/SQL param |
| `PU CREATE_BRKR_IMPR_AUTH` | 52 | SHOW_ALERT / STR.DispAlert | ftf(text) when followed by FTF; info(text) otherwise; CONFIRM/WARNING -> Confirm DA + p_answer | pkg / DA |
| `PU CREATE_BRKR_IMPR_AUTH` | 48 | RAISE FORM_TRIGGER_FAILURE | pkg_forms_compat.ftf (-20000) | pkg |
| `PU CREATE_BRKR_IMPR_AUTH` | 53,54,55 | :GLOBAL.* | g_get / g_set (pkg_forms_compat) -> Application Item AI_<NAME> | pkg |
| `PU CREATE_BRKR_IMPR_AUTH` | 4,6,11,12,33,34,35 | :PARAMETER.* | t_ctx field | PL/SQL param |
| `PU CHK_PERSONAL` | 38 | SHOW_ALERT / STR.DispAlert | ftf(text) when followed by FTF; info(text) otherwise; CONFIRM/WARNING -> Confirm DA + p_answer | pkg / DA |
| `PU CHK_PERSONAL` | 41 | RAISE FORM_TRIGGER_FAILURE | pkg_forms_compat.ftf (-20000) | pkg |
| `PU CHK_PERSONAL` | 31 | :GLOBAL.* | g_get / g_set (pkg_forms_compat) -> Application Item AI_<NAME> | pkg |
| `PU CHK_PERSONAL` | 17 | :PARAMETER.* | t_ctx field | PL/SQL param |
| `PU CHK_IMPR_DUPL` | 33 | SHOW_ALERT / STR.DispAlert | ftf(text) when followed by FTF; info(text) otherwise; CONFIRM/WARNING -> Confirm DA + p_answer | pkg / DA |
| `PU CHK_IMPR_DUPL` | 34 | RAISE FORM_TRIGGER_FAILURE | pkg_forms_compat.ftf (-20000) | pkg |
| `PU CHK_DUPL_IMP_BRKR` | 23 | SHOW_ALERT / STR.DispAlert | ftf(text) when followed by FTF; info(text) otherwise; CONFIRM/WARNING -> Confirm DA + p_answer | pkg / DA |
| `PU CHK_DUPL_IMP_BRKR` | 24 | RAISE FORM_TRIGGER_FAILURE | pkg_forms_compat.ftf (-20000) | pkg |
| `PU CHK_DUPL_IMP_BRKR` | 12 | :PARAMETER.* | t_ctx field | PL/SQL param |
| `PU CALL_LOV_COUNTRIES` | 13,39 | SHOW_ALERT / STR.DispAlert | ftf(text) when followed by FTF; info(text) otherwise; CONFIRM/WARNING -> Confirm DA + p_answer | pkg / DA |
| `PU CALL_LOV_COUNTRIES` | 25 | CALL_FORM | Modal dialog page / Popup LOV (see §5) | APEX |
| `PU CALL_LOV_COUNTRIES` | 14,40 | RAISE FORM_TRIGGER_FAILURE | pkg_forms_compat.ftf (-20000) | pkg |
| `PU CALL_LOV_COUNTRIES` | 17 | :SYSTEM.* | TRIGGER_ITEM=CURSOR_ITEM -> p_from_item; RECORD_STATUS -> rec_status; MODE/CURSOR_* -> n/a | PL/SQL param |
| `PU CALL_LOV_COUNTRIES` | 31,32,33 | :GLOBAL.* | g_get / g_set (pkg_forms_compat) -> Application Item AI_<NAME> | pkg |
| `PU CALL_LOV_COUN_GULF` | 13,40 | SHOW_ALERT / STR.DispAlert | ftf(text) when followed by FTF; info(text) otherwise; CONFIRM/WARNING -> Confirm DA + p_answer | pkg / DA |
| `PU CALL_LOV_COUN_GULF` | 26 | CALL_FORM | Modal dialog page / Popup LOV (see §5) | APEX |
| `PU CALL_LOV_COUN_GULF` | 14,41 | RAISE FORM_TRIGGER_FAILURE | pkg_forms_compat.ftf (-20000) | pkg |
| `PU CALL_LOV_COUN_GULF` | 17 | :SYSTEM.* | TRIGGER_ITEM=CURSOR_ITEM -> p_from_item; RECORD_STATUS -> rec_status; MODE/CURSOR_* -> n/a | PL/SQL param |
| `PU CALL_LOV_COUN_GULF` | 32,33,34 | :GLOBAL.* | g_get / g_set (pkg_forms_compat) -> Application Item AI_<NAME> | pkg |
| `PU BROKER_INT` | 7,8 | SET_ITEM_PROPERTY | ui(item,'ENABLED'|'REQUIRED'|'VISIBLE'|'VALID') -> DA Enable/Disable/Show/Hide/setRequired | pkg (recorder) / DA |
| `PU ADJ_FUNS` | 48 | :GLOBAL.* | g_get / g_set (pkg_forms_compat) -> Application Item AI_<NAME> | pkg |
| `PU ADJ_FUNS` | 7,19,22,23,55 | :PARAMETER.* | t_ctx field | PL/SQL param |
| `PU CHK_BUS_ID_BRNCH` | 4 | SHOW_ALERT / STR.DispAlert | ftf(text) when followed by FTF; info(text) otherwise; CONFIRM/WARNING -> Confirm DA + p_answer | pkg / DA |
| `PU CHK_BUS_ID_BRNCH` | 5 | RAISE FORM_TRIGGER_FAILURE | pkg_forms_compat.ftf (-20000) | pkg |

### 2.1 Notes on the replacements

* **`STR.DispArbMsg(sys, nbr, …)`** – `STR.pll` is MISSING SOURCE. The text is taken from
  `STR_DB.GetArbMsg(sys, nbr)` and formatted as `sys-nbr : text` – the same format the form builds
  inline for message 9-120 in `BUS_ID` WHEN-VALIDATE-ITEM. `'-1'` gives the form's own
  "خطأ فى رقم الرسالة …" text.
* **`STR.DispAlert(text, kind)`** – followed by `RAISE FORM_TRIGGER_FAILURE` → `ftf(text)` (error);
  without raise → `info(text)` (non-blocking message, returned to the page in `ui_json.messages`).
  `CONFIRM` / `WARNING` alerts whose answer drives logic → Confirm DA + `p_answer` parameter (§5.4).
* **`INTRFACE.Make_Field_Entrable`, `SET_ITEM_PROPERTY`, `GO_ITEM`, `DO_KEY('LIST_VALUES')`,
  `TMPLT.ENABLE_FUN/DISABLE_FUN`** – recorded by `pkg_impr1110` at the exact place Forms runs them
  (`entrable`, `ui`, `ui_focus`, `fun`) and returned as JSON (`ui_json`). This keeps the order and
  conditions of the original without page item references in the package.
* **`:SYSTEM.TRIGGER_ITEM = :SYSTEM.CURSOR_ITEM`** – parameter `p_from_item` (TRUE when the user
  leaves the item; FALSE when Forms validates the item during record/commit validation).
* **`GET_RECORD_PROPERTY(…, STATUS)` / `:SYSTEM.RECORD_STATUS`** – `t_rec.rec_status`
  (`NEW` / `INSERT` / `QUERY` / `CHANGED`), maintained by `pkg_impr1110_apx`.
* **`GET_ITEM_PROPERTY('ACTIVITY'|'BUS_ID_BRNCH', ENABLED)`** – `t_rec.activity_entr` /
  `t_rec.bus_id_brnch_entr`, filled by the page from the current item state.
* **Client library twins** – `HIJDATE.Cur_Hij_Date` → `HIJDATE_DB.Cur_Hij_Date`,
  `STR.StrFormat` → `STR_DB.StrFormat`, `STR_db.RemoveRepeat` unchanged. The form itself already
  uses these server versions in other triggers. `HIJDATE.VALID_HIJ_DATE` → `HIJDATE_DB.valid_hij_date`
  is an **assumption** (TODO, §7.3) – compilation fails if it does not exist, by design.

### 2.2 Query (PRE-QUERY / region SQL) – for step 03

Base query of block `IMPORTERS` (from the XML):

```sql
SELECT ROWIDTOCHAR(ROWID) row_id, i.*
  FROM importers i
 WHERE i.port_cd = :AI_P_CURR_PORT_CD                 -- WhereClause of the block
   -- query-by-example on the entered items (Forms Enter-Query), plus:
   AND (:P1110_Q_PORT_NAME IS NULL
        OR i.port_cd IN (SELECT port_cd FROM sd_ports WHERE port_name = :P1110_Q_PORT_NAME))  -- CGFK$DEFAULT_WHERE
 ORDER BY i.impr_nbr DESC                             -- OrderByClause of the block
```

* `CGFK$DEFAULT_WHERE` also accepts `<`, `>`, `=`, `#` prefixes and `%` (LIKE) in `PORT_NAME`; it
  builds dynamic SQL with string concatenation. In APEX use the bind variable form above
  (`= ` or `LIKE`), never concatenation (CLAUDE.md §6.9). `PORT_CD` is disabled and always the
  current port, so the PORT_NAME criterion has no practical effect – confirm before building it.
* `importers_pre_qry`: name search uses `IMPR_NAME_STD := STR.StrFormat(:ARBC_IMPR_NAME, TRUE)` and
  clears `ARBC_IMPR_NAME` → the region filters on `IMPR_NAME_STD`, not on `ARBC_IMPR_NAME`.
  `PRSNL_IMPR = 1` forces `IMPR_TYPE_CD = 4` in the criteria.
* POST-QUERY runs a duty-difference count per row (3 UNION ALL branches) – N+1 pattern. Acceptable
  for the single-record form; **do not** put `importers_post_qry` into a report column.

---

## 3. Package members and source

### 3.1 `pkg_impr1110` (business logic – no page items)

| Member | Source (Forms) | Called by APEX as |
|---|---|---|
| `wnfi` | FORM.WHEN-NEW-FORM-INSTANCE | `pkg_impr1110_apx.page_wnfi` – Before Header, first entry |
| `importers_wcr` | IMPORTERS.WHEN-CREATE-RECORD | `page_new_record` |
| `importers_wnri` / `wnri_confirm_text` | IMPORTERS.WHEN-NEW-RECORD-INSTANCE | `page_fetch`, `page_new_record`, `ajax_item(WNRI)`, `ajax_fun` |
| `importers_pre_rec` | IMPORTERS.PRE-RECORD | `page_fetch`, `page_new_record` |
| `importers_wcb` | IMPORTERS.WHEN-CLEAR-BLOCK | CLEAR button process |
| `importers_pre_qry` | IMPORTERS.PRE-QUERY | `page_fetch` |
| `importers_post_qry` | IMPORTERS.POST-QUERY | `page_fetch` |
| `importers_pre_ins` / `importers_ins` / `importers_post_ins` | PRE-INSERT / default INSERT / POST-INSERT | `page_dml('SAVE')` (new row) |
| `importers_pre_upd` / `importers_upd` / `importers_post_upd` | PRE-UPDATE / default UPDATE / POST-UPDATE | `page_dml('SAVE')` (changed row) |
| `importers_pre_del` / `importers_key_delrec` | PRE-DELETE / KEY-DELREC | `page_dml('DELETE')` |
| `importers_on_error` | IMPORTERS.ON-ERROR + PU CGTE$CHECK_CONSTRAINT_VIO | error text in `pkg_impr1110_apx` |
| `port_cd_wvi` | PORT_CD.WHEN-VALIDATE-ITEM | `ajax_item(VALIDATE)` |
| `hq_impr_nbr_post_chg` | HQ_IMPR_NBR.POST-CHANGE | `ajax_item(VALIDATE)`, fetch |
| `impr_nbr_wvi` | IMPR_NBR.WHEN-VALIDATE-ITEM | `ajax_item(VALIDATE)` |
| `impr_type_cd_wvi` | IMPR_TYPE_CD.WHEN-VALIDATE-ITEM (+ CGFK ITIDT) | `ajax_item(VALIDATE)` |
| `impr_type_cd_post_chg` | IMPR_TYPE_CD.POST-CHANGE | `ajax_item(VALIDATE)`, fetch |
| `impr_type_cd_wnii` | IMPR_TYPE_CD.WHEN-NEW-ITEM-INSTANCE | `ajax_item(WNII)` |
| `impr_type_cd_lov_ret` | IMPR_TYPE_CD.KEY-LISTVAL (after LOV_IMPR_TYPE) | `ajax_item(LOV_RET)` |
| `bus_id_exprd_dt_wvi` | BUS_ID_EXPRD_DT.WHEN-VALIDATE-ITEM | `ajax_item(VALIDATE)` |
| `bus_id_type_post_chg` | BUS_ID_TYPE_CD.POST-CHANGE | `ajax_item(VALIDATE)`, fetch |
| `comm_rgstrtn_wlc` | COMM_RGSTRTN_TYPE.WHEN-LIST-CHANGED | `ajax_item(WLC)` |
| `ctry_cd_of_id_wvi` | CTRY_CD_OF_ID.WHEN-VALIDATE-ITEM | `ajax_item(VALIDATE)` |
| `city_code_of_id_wvi` | CITY_CODE_OF_ID.WHEN-VALIDATE-ITEM (+ CGFK) | `ajax_item(VALIDATE)` |
| `city_code_of_id_wnii` | CITY_CODE_OF_ID.WHEN-NEW-ITEM-INSTANCE | `ajax_item(WNII)` |
| `bus_id_wvi` / `bus_id_susp_impr` | BUS_ID.WHEN-VALIDATE-ITEM | `ajax_confirm(SUSP)` then `ajax_item(VALIDATE)` |
| `bus_id_post_chg` | BUS_ID.POST-CHANGE | `ajax_item(VALIDATE)`, fetch |
| `bus_id_wnii` | BUS_ID.WHEN-NEW-ITEM-INSTANCE | `ajax_item(WNII)` |
| `brnh_city_cd_wvi` | BRNH_CITY_CD.WHEN-VALIDATE-ITEM | `ajax_item(VALIDATE)` |
| `brnh_city_cd_wnii` | BRNH_CITY_CD.WHEN-NEW-ITEM-INSTANCE | `ajax_item(WNII)` |
| `bus_id_brnch_wvi` | BUS_ID_BRNCH.WHEN-VALIDATE-ITEM | `ajax_item(VALIDATE)` |
| `bus_id_brnch_post_chg` | BUS_ID_BRNCH.POST-CHANGE | `ajax_item(VALIDATE)`, fetch |
| `bus_id_brnch_wnii` | BUS_ID_BRNCH.WHEN-NEW-ITEM-INSTANCE | `ajax_item(WNII)` |
| `ctry_cd_wvi` | CTRY_CD.WHEN-VALIDATE-ITEM (+ CGFK CTRY) | `ajax_item(VALIDATE)` |
| `impr_expr_type_post_chg` | IMPR_EXPR_TYPE.POST-CHANGE | `ajax_item(VALIDATE)`, fetch |
| `arbc_impr_name_wvi` | ARBC_IMPR_NAME.WHEN-VALIDATE-ITEM | `ajax_item(VALIDATE)` |
| `arbc_impr_name_key_nxt` | ARBC_IMPR_NAME.KEY-NEXT-ITEM | `ajax_item(KEY_NXT)` (net effect: focus ENG_IMPR_NAME) |
| `eng_impr_name_wvi` | ENG_IMPR_NAME.WHEN-VALIDATE-ITEM | `ajax_item(VALIDATE)` |
| `bus_id_issue_dt_wvi` | BUS_ID_ISSUE_DT.WHEN-VALIDATE-ITEM | `ajax_item(VALIDATE)` |
| `impr_nbr_parent_wvi` | IMPR_NBR_PARENT.WHEN-VALIDATE-ITEM | `ajax_item(VALIDATE)` |
| `add_ctry_cd_wvi` | ADD_CTRY_CD.WHEN-VALIDATE-ITEM (+ CGFK) | `ajax_item(VALIDATE)` |
| `city_code_wvi` | CITY_CODE.WHEN-VALIDATE-ITEM (+ CGFK) | `ajax_item(VALIDATE)` |
| `impr_tel_nbr_wvi` | IMPR_TEL_NBR.WHEN-VALIDATE-ITEM | `ajax_item(VALIDATE)` |
| `b_email_wvi` / `email_wvi` | B_EMAIL / EMAIL WHEN-VALIDATE-ITEM | `ajax_item(VALIDATE)` |
| `b_email_post_chg` / `b_mobile_no_post_chg` / `b_id_nbr_post_chg` | POST-CHANGE of B_EMAIL / B_MOBILE_NO / B_ID_NBR | `ajax_item(VALIDATE)` |
| `b_mobile_no_wvi` | B_MOBILE_NO.WHEN-VALIDATE-ITEM | `ajax_item(VALIDATE)` |
| `bank_iban_wvi` / `bank_iban_wnii` | BANK_IBAN WVI / WNII | `ajax_item` |
| `b_id_nbr_wvi` | B_ID_NBR.WHEN-VALIDATE-ITEM | `ajax_item(VALIDATE)` |
| `check_idno`, `is_digit`, `check_bus_id`, `chk_bus_id_brnch`, `chk_impr_dupl`, `chk_dupl_imp_brkr`, `chk_personal`, `insert_audit_record`, `update_basic_importer`, `return_impr_id`, `broker_int`, `adj_funs` (+ `fun_state`), `get_cr_data`, `get_main_cr_data`, `get_branch_cr_data`, `exec_funs`, `create_brkr_impr_auth`, `update_importer_msg` + `update_importer`, `central_mobile` + `lov_update_moblie` | Program units with the same names | internal / `ajax_fun` |
| `ui_reset`, `ui_json` | – (UI recorder) | `pkg_impr1110_apx` |

Private helpers (body only): `ui`, `entrable`, `ui_focus`, `fun`, `info`, `ftf`, `g_get`, `g_set`,
`arb_msg`, `disp_arb_ftf`, `disp_arb_info`, `cg_msg`, `add_activity`, `cur_hij_date`,
`valid_hij_date`, `ctry_100_defaults` (block repeated 4× in the form), `type_entrable_qry`
(branches repeated in IMPR_TYPE_CD WVI and POST-QUERY), `lock_key_items` (list repeated 3×),
`cr_fields_entrable`, `cgsf_clrlu_bus_i`, `strip_constraint`, `comm_name`, `check_email`.

### 3.2 `pkg_impr1110_apx` (APEX glue)

| Member | APEX component (step 03) |
|---|---|
| `page_wnfi` | Before Header process `WHEN-NEW-FORM-INSTANCE` (condition: first entry, e.g. request is not SAVE/DELETE and `P1110_UI_STATE` is null) |
| `page_fetch` | Before Header process `IMPORTERS.POST-QUERY` |
| `page_new_record` | Before Header process `IMPORTERS.WHEN-CREATE-RECORD` (when no row is loaded) |
| `ajax_item` | AJAX Callback `IMPR1110_ITEM` (x01 item, x02 event, x03/x04 answers) |
| `ajax_confirm` | AJAX Callback `IMPR1110_CONFIRM` (x01 = WNRI / SUSP / UPD_IMPR) |
| `ajax_fun` | AJAX Callback `IMPR1110_FUN` (x01 = function code) |
| `page_dml` | Page processes `IMPORTERS.PRE-INSERT…POST-UPDATE` (request SAVE) and `IMPORTERS.KEY-DELREC` (request DELETE) |

---

## 4. Errors and messages

All business errors are raised with `pkg_forms_compat.ftf` → `-20000` (shown without the `ORA-`
prefix by `pkg_forms_compat.apex_error_handler`). Messages without failure are returned in
`ui_json.messages` (AJAX) or `P1110_UI_STATE` (page load / save) and shown as page notifications.
Generated from the package body (texts are verbatim from the form). Dynamic texts not listed:
`ftf(v_msg)` from `IMPR.CHECK_DUPLICATE_IMP_BRKR` and `IMPR_CENTRAL.Create_Uni_IMPR_NEBRAS`,
`ftf(cg_msg(…))` from the CG library (`'<p1> must be entered'`, `'This <p1> does not exist'`).

| # | -20xxx | Kind | Text / message source | Package member |
|---|---|---|---|---|
| 1 | -20000 | error (FTF) | (no text – Forms raised FORM_TRIGGER_FAILURE without its own message) | `add_activity` |
| 2 | -20000 | error (FTF) | STR_DB.GetArbMsg(18, 15) → "18-15 : <text>" | `ctry_100_defaults` |
| 3 | — | message |  تم تعديل النشاط التجاري الى "مؤسسة/شركة/استثمارية "   | `importers_wnri` |
| 4 | — | message | لا يمكن التعديل  للمستورد الشخصي الا من خلال الدعم الفني التطبيقات | `importers_wnri` |
| 5 | — | message | STR_DB.GetArbMsg(9, 150) → "9-150 : <text>" | `importers_pre_rec` |
| 6 | — | message | رمز النشاط التجاري غير صحيح - أعد إدخال البيانات | `importers_post_qry` |
| 7 | — | message | رمز الدولة غير صحيح - أعد ادخال البيانات | `importers_post_qry` |
| 8 | — | message | خطأ في رمز مدينة مصدر الرقم الإستدلالي | `importers_post_qry` |
| 9 | — | message | خطأ في رمز مدينة عنوان المستورد | `importers_post_qry` |
| 10 | -20000 | error (FTF) | يجب إدخال رقم المحمول | `importers_pre_ins` |
| 11 | -20000 | error (FTF) | يجب إدخال المدينة | `importers_pre_ins` |
| 12 | -20000 | error (FTF) | يجب ادخال رقم الهاتف | `importers_pre_ins` |
| 13 | -20000 | error (FTF) | STR_DB.GetArbMsg(9, 220) → "9-220 : <text>" | `importers_pre_ins` |
| 14 | -20000 | error (FTF) | يجب إدخال حقل نشاط المستورد | `importers_pre_ins` |
| 15 | -20000 | error (FTF) | (no text – Forms raised FORM_TRIGGER_FAILURE without its own message) | `importers_pre_ins` |
| 16 | -20000 | error (FTF) | STR_DB.GetArbMsg(9, 190) → "9-190 : <text>" | `importers_pre_ins` |
| 17 | -20000 | error (FTF) | STR_DB.GetArbMsg(9, 250) → "9-250 : <text>" | `importers_pre_ins` |
| 18 | -20000 | error (FTF) | STR_DB.GetArbMsg(9, 230) → "9-230 : <text>" | `importers_pre_ins` |
| 19 | -20000 | error (FTF) | STR_DB.GetArbMsg(9, 240) → "9-240 : <text>" | `importers_pre_ins` |
| 20 | — | message | رقم المستورد | `importers_pre_ins` |
| 21 | -20000 | error (FTF) | يجب إدخال رقم المحمول | `importers_pre_upd` |
| 22 | -20000 | error (FTF) | STR_DB.GetArbMsg(9, 220) → "9-220 : <text>" | `importers_pre_upd` |
| 23 | -20000 | error (FTF) | STR_DB.GetArbMsg(9, 190) → "9-190 : <text>" | `importers_pre_upd` |
| 24 | -20000 | error (FTF) | STR_DB.GetArbMsg(9, 250) → "9-250 : <text>" | `importers_pre_upd` |
| 25 | -20000 | error (FTF) | STR_DB.GetArbMsg(9, 230) → "9-230 : <text>" | `importers_pre_upd` |
| 26 | -20000 | error (FTF) | STR_DB.GetArbMsg(9, 240) → "9-240 : <text>" | `importers_pre_upd` |
| 27 | -20000 | error (FTF) | FRM-40654 | `importers_upd` |
| 28 | -20000 | error (FTF) | STR_DB.GetArbMsg(9, 150) → "9-150 : <text>" | `impr_nbr_wvi` |
| 29 | -20000 | error (FTF) | STR_DB.GetArbMsg(9, 332) → "9-332 : <text>" | `impr_type_cd_wvi` |
| 30 | -20000 | error (FTF) | STR_DB.GetArbMsg(9, 331) → "9-331 : <text>" | `impr_type_cd_wvi` |
| 31 | -20000 | error (FTF) | STR_DB.GetArbMsg(2, 170) → "2-170 : <text>" | `impr_type_cd_wvi` |
| 32 | -20000 | error (FTF) | لابد أن تكون دولة المستورد الخليجي تابعة لدول مجلس التعاون | `impr_type_cd_wvi` |
| 33 | -20000 | error (FTF) | رمز النشاط التجاري غير صحيح - أعد إدخال البيانات | `impr_type_cd_wvi` |
| 34 | -20000 | error (FTF) | (no text – Forms raised FORM_TRIGGER_FAILURE without its own message) | `bus_id_exprd_dt_wvi` |
| 35 | -20000 | error (FTF) | STR_DB.GetArbMsg(1, 10) → "1-10 : <text>" | `bus_id_exprd_dt_wvi` |
| 36 | -20000 | error (FTF) | STR_DB.GetArbMsg(18, 15) → "18-15 : <text>" | `bus_id_type_post_chg` |
| 37 | — | message | خطأ في رمز مدينة مصدر الرقم الإستدلالي | `city_code_of_id_wvi` |
| 38 | -20000 | error (FTF) |  يجب أن يكون الرقم الاستدلالي مكونا من عشرة ارقام  | `bus_id_wvi` |
| 39 | -20000 | error (FTF) | STR_DB.GetArbMsg(9, 270) → "9-270 : <text>" | `bus_id_wvi` |
| 40 | -20000 | error (FTF) | STR_DB.GetArbMsg(9, 260) → "9-260 : <text>" | `bus_id_wvi` |
| 41 | -20000 | error (FTF) | (no text – Forms raised FORM_TRIGGER_FAILURE without its own message) | `bus_id_wvi` |
| 42 | -20000 | error (FTF) | STR_DB.GetArbMsg(9, 130) → "9-130 : <text>" | `bus_id_wvi` |
| 43 | -20000 | error (FTF) |  لا يمكن تكرار الرقم الإستدلالي - الرقم الإستدلالي مستخدم لمستورد آخر مسلسله بالجمرك رقم :  | `bus_id_wvi` |
| 44 | -20000 | error (FTF) | STR_DB.GetArbMsg(9, 290) → "9-290 : <text>" | `bus_id_wvi` |
| 45 | -20000 | error (FTF) | STR_DB.GetArbMsg(9, 190) → "9-190 : <text>" | `bus_id_wvi` |
| 46 | -20000 | error (FTF) | رقم الهوية المدخل غير صحيح.. يجب إدخال رقم هوية صحيح | `bus_id_wvi` |
| 47 | — | message | STR_DB.GetArbMsg(9, 240) → "9-240 : <text>" | `bus_id_wnii` |
| 48 | — | message | الرمز التجاري للمدينة المحددة :   | `bus_id_wnii` |
| 49 | -20000 | error (FTF) | STR_DB.GetArbMsg(1, 120) → "1-120 : <text>" | `brnh_city_cd_wvi` |
| 50 | -20000 | error (FTF) | STR_DB.GetArbMsg(1, 220) → "1-220 : <text>" | `bus_id_brnch_wvi` |
| 51 | -20000 | error (FTF) | STR_DB.GetArbMsg(9, 270) → "9-270 : <text>" | `bus_id_brnch_wvi` |
| 52 | -20000 | error (FTF) | STR_DB.GetArbMsg(9, 260) → "9-260 : <text>" | `bus_id_brnch_wvi` |
| 53 | -20000 | error (FTF) | (no text – Forms raised FORM_TRIGGER_FAILURE without its own message) | `bus_id_brnch_wvi` |
| 54 | -20000 | error (FTF) | STR_DB.GetArbMsg(9, 130) → "9-130 : <text>" | `bus_id_brnch_wvi` |
| 55 | -20000 | error (FTF) | STR_DB.GetArbMsg(9, 290) → "9-290 : <text>" | `bus_id_brnch_wvi` |
| 56 | -20000 | error (FTF) | STR_DB.GetArbMsg(9, 190) → "9-190 : <text>" | `bus_id_brnch_wvi` |
| 57 | — | message | الرمز التجاري للمدينة المحددة :   | `bus_id_brnch_wnii` |
| 58 | -20000 | error (FTF) | لابد أن تكون دولة المستورد الخليجي تابعة لدول مجلس التعاون | `ctry_cd_wvi` |
| 59 | -20000 | error (FTF) | رمز الدولة غير صحيح - أعد ادخال البيانات | `ctry_cd_wvi` |
| 60 | -20000 | error (FTF) | فضلا .. يجب إدخال اسم المستورد باللغة الانجليزية | `eng_impr_name_wvi` |
| 61 | -20000 | error (FTF) | (no text – Forms raised FORM_TRIGGER_FAILURE without its own message) | `bus_id_issue_dt_wvi` |
| 62 | — | message | STR_DB.GetArbMsg(9, 160) → "9-160 : <text>" | `impr_nbr_parent_wvi` |
| 63 | -20000 | error (FTF) | STR_DB.GetArbMsg(18, 15) → "18-15 : <text>" | `add_ctry_cd_wvi` |
| 64 | — | message | خطأ في رمز مدينة عنوان المستورد | `add_ctry_cd_wvi` |
| 65 | -20000 | error (FTF) | يجب إدخال المدينة | `city_code_wvi` |
| 66 | -20000 | error (FTF) | STR_DB.GetArbMsg(18, 282) → "18-282 : <text>" | `city_code_wvi` |
| 67 | — | message | خطأ في رمز مدينة عنوان المستورد | `city_code_wvi` |
| 68 | -20000 | error (FTF) | يجب إدخال الهاتف | `impr_tel_nbr_wvi` |
| 69 | -20000 | error (FTF) | رقم الهاتف يجب أن يتكون من 10 أرقام | `impr_tel_nbr_wvi` |
| 70 | -20000 | error (FTF) | يجب أن يكون رقم الهاتف المدخل أرقام | `impr_tel_nbr_wvi` |
| 71 | -20000 | error (FTF) | خطأ فى صيغة البريد الالكتروني | `check_email` |
| 72 | -20000 | error (FTF) | لا يمكن تعديل رقم الجوال, الرجاء استخدام الوظيفة الخاصة بتعديل رقم الجوال | `b_mobile_no_wvi` |
| 73 | -20000 | error (FTF) | يجب أن يكون رقم الجوال المدخل أرقام | `b_mobile_no_wvi` |
| 74 | -20000 | error (FTF) | رقم الجوال المدخل غير صحيح .. الرجاء اعادة الادخال  | `b_mobile_no_wvi` |
| 75 | -20000 | error (FTF) |  رقم الآيبان المدخل غير صحيح..الرجاء إعادة الإدخال  | `bank_iban_wvi` |
| 76 | -20000 | error (FTF) | يجب إدخال رقم الهوية بشكل صحيح | `b_id_nbr_wvi` |
| 77 | -20000 | error (FTF) | رقم الهوية المدخل غير صحيح.. يجب إدخال رقم هوية صحيح | `b_id_nbr_wvi` |
| 78 | -20000 | error (FTF) | غير مسموح بادخال رقم السجل الرئيسي مساوي لرقم السجل الفرعي .. أعد الادخال | `chk_bus_id_brnch` |
| 79 | -20000 | error (FTF) |  لايمكن الإدخال، يوجد مستورد مدخل بنفس نوع المستورد ونفس الرقم الإستدلالي الرئيسي والفرعي ورقمه:   | `chk_impr_dupl` |
| 80 | -20000 | error (FTF) | لا يمكن تغيير نوع المستورد من شخصي الي نوع آخر أو العكس , يتم ذلك من خلال الدعم الفني التطبيقات فقط | `chk_personal` |
| 81 | — | message | لا يمكن تغيير نوع المستورد من شخصي الي نوع آخر أو العكس , يتم ذلك من خلال الدعم الفني التطبيقات فقط | `chk_personal` |
| 82 | -20000 | error (FTF) | STR_DB.GetArbMsg(9, 140) → "9-140 : <text>" | `insert_audit_record` |
| 83 | — | message | سيتم الحصول على بيانات المستورد من وزارة التجارة.....الرجاء الإنتظار | `get_cr_data` |
| 84 | — | message | تم أنشاء التفويض | `create_brkr_impr_auth` |
| 85 | -20000 | error (FTF) | رقم الجوال المدخل غير صحيح | `lov_update_moblie` |
| 86 | — | message | تمت العملية بنجاح | `lov_update_moblie` |
| 87 | — | message | تم التحديث بنجاح | `exec_funs` |
| 88 | — | message | رقم استدلالي غير صحيح | `exec_funs` |
| 89 | — | message | رقم شهادة غير صحيح | `exec_funs` |
| 90 | — | message | لا يوجد بيانات | `exec_funs` |
| 91 | -20000 | error (FTF) | رقم المستورد غير محدث ,, الرجاء مراجعة الدعم | `exec_funs` |

Text Messages to create (Shared Components): none are required by the package – Forms alerts
`USR_CONFIRM*`, `USR_WARNING*`, `CFG_*` come from `CIC_OLB` (definitions MISSING) and are only
used through `STR.DispAlert`, whose texts are given inline in the code.

---

## 5. UI logic for Dynamic Actions (input for prompt 03)

### 5.1 UI state protocol

`pkg_impr1110` records every UI effect; `pkg_impr1110_apx` returns it as:

```json
{"items":[{"item":"BUS_ID","prop":"ENTRABLE","value":false}, ...],
 "focus":"IMPR_NBR", "messages":["..."], "funs":[{"fun":"IMPR1110F3","enabled":true}]}
```

One shared JavaScript function on page 1110 (step 03) applies it in order:

| prop | Meaning in Forms | APEX 21.2 action |
|---|---|---|
| `ENTRABLE` | `INTRFACE.Make_Field_Entrable(item, flag)` | `apex.item(P1110_x).enable()/disable()` (TODO: INTRFACE source – it may also change visual attribute / navigable) |
| `ENABLED` | `SET_ITEM_PROPERTY(…, ENABLED, …)` | enable / disable |
| `REQUIRED` | `SET_ITEM_PROPERTY(…, REQUIRED, …)` | `apex.item().setRequired(flag)` + server validation |
| `VISIBLE` | `SET_ITEM_PROPERTY(…, VISIBLE, …)` | show / hide |
| `VALID` | `ITEM_IS_VALID` | `PROPERTY_FALSE` → mark the item so the next submit re-validates it (call `ajax_item(VALIDATE)` before SAVE) |
| `OPEN_LOV` | `DO_KEY('LIST_VALUES')` | open the Popup LOV of the item |
| `REQUERY` | `Clear_Block` + `EXECUTE_QUERY` (EXEC_QUERY_NOW = 1) | submit/reload page 1110 so `page_fetch` loads `:GLOBAL.PORT_CD/IMPR_NBR` |
| `BLOCK_UPDATE_ONLY` | `INTRFACE.MAKE_BLOCK_FULL_OPERATION('IMPORTERS',FALSE,TRUE,FALSE)` | hide CREATE / DELETE |
| `DO_COMMIT` | `COMMIT` inside WNRI (function IMPR1110F3) | submit with request SAVE immediately (HIGH, §7.2) |
| `focus` | `GO_ITEM` (last one wins) | `apex.item().setFocus()` |
| `funs` | `TMPLT.ENABLE_FUN / DISABLE_FUN` (ADJ_FUNS) | show / hide the function-menu entries |
| `messages` | `STR.DispAlert` without failure | `apex.message.showPageSuccess` / alert |

### 5.2 Events (one DA per row, name = Forms trigger name, Comments = `Source: …`)

| DA name | Event | Call |
|---|---|---|
| `IMPORTERS.<ITEM>.WHEN-VALIDATE-ITEM` for PORT_CD, IMPR_NBR, IMPR_TYPE_CD, BUS_ID_EXPRD_DT, BUS_ID_TYPE_CD (POST-CHANGE only), CTRY_CD_OF_ID, CITY_CODE_OF_ID, BUS_ID, BRNH_CITY_CD, BUS_ID_BRNCH, CTRY_CD, IMPR_EXPR_TYPE (POST-CHANGE only), HQ_IMPR_NBR (POST-CHANGE only), ARBC_IMPR_NAME, ENG_IMPR_NAME, BUS_ID_ISSUE_DT, IMPR_NBR_PARENT, ADD_CTRY_CD, CITY_CODE, IMPR_TEL_NBR, B_EMAIL, B_MOBILE_NO, BANK_IBAN, B_ID_NBR | Change | `IMPR1110_ITEM` x01=item, x02=`VALIDATE` (POST-CHANGE then WHEN-VALIDATE-ITEM, Forms order). On `error`: show it, keep focus in the item (Forms does not leave an invalid item). |
| `IMPORTERS.<ITEM>.WHEN-NEW-ITEM-INSTANCE` for IMPR_TYPE_CD, CITY_CODE_OF_ID, BUS_ID, BRNH_CITY_CD, BUS_ID_BRNCH, BANK_IBAN | Get Focus | `IMPR1110_ITEM` x02=`WNII` |
| `IMPORTERS.WHEN-NEW-ITEM-INSTANCE`, `BUS_ID_EXPRD_DT.WHEN-NEW-ITEM-INSTANCE` | Get Focus (any item) | if the last reply contained `REQUERY`: reload page |
| `IMPORTERS.COMM_RGSTRTN_TYPE.WHEN-LIST-CHANGED` | Change | `IMPR1110_ITEM` x02=`WLC` |
| `IMPORTERS.IMPR_TYPE_CD.KEY-LISTVAL` | Popup LOV close | `IMPR1110_ITEM` x02=`LOV_RET` (LOV returns IMPR_TYPE_CD/NAME + BUS_ID_TYPE_CD/NAME) |
| `IMPORTERS.ARBC_IMPR_NAME.KEY-NEXT-ITEM` | Key Tab / Enter | focus ENG_IMPR_NAME (server call optional, record is unchanged) |
| `IMPORTERS.WHEN-NEW-RECORD-INSTANCE` | after a function code | `IMPR1110_CONFIRM` x01=`WNRI` → if text, Confirm → `IMPR1110_ITEM` x02=`WNRI`, x03=answer |
| Hijri date picker | KEY-F4 / KEY-LISTVAL on BUS_ID_EXPRD_DT | `INTRFACE.Disp_date_con('H',2,1)` (MISSING SOURCE) – decision needed: Hijri picker plug-in or plain text with mask `MI-MM-YYYY` |

### 5.3 Dialogs / LOV forms called by the form

| Forms `CALL_FORM` | From | APEX |
|---|---|---|
| `LOV_SD_PORTS` | PORT_CD.KEY-LISTVAL (item disabled) | Popup LOV (`PORT_TYPE`, `STATUS = 1`) |
| `LOV_Impr_Type` | IMPR_TYPE_CD.KEY-LISTVAL | Popup LOV returning 4 columns; `STATUS=1` and current type only when `:GLOBAL.CHK_IMP_TYP != 1` |
| `LOV_CITIES_IMP` | CITY_CODE_OF_ID / BRNH_CITY_CD KEY-LISTVAL | Popup LOV, country = 100 (type 3 & bus id type 2) or `CTRY_CD`; also returns `:GLOBAL.MINS_COMM_CD`? (MISSING SOURCE – read by BUS_ID/BUS_ID_BRNCH WNII) |
| `LOV_CITIES` | CITY_CODE.KEY-LISTVAL | Popup LOV by `ADD_CTRY_CD`, returns city + country |
| `LOV_COUNTRIES` / `LOV_COUNTRIES_GULF` | CTRY_CD / ADD_CTRY_CD KEY-LISTVAL | Popup LOV; Gulf list when type 4 & bus id type 16 |
| `LOV_IMPR` | IMPR_NBR_PARENT.KEY-LISTVAL | Popup LOV by current port |
| `SUPPORT_ENTRY` | EXEC_FUNS IMPR1110F1/F2/F3/F5 | Modal dialog page (support letter); on close it sets `AI_LETTER_NBR`, `AI_SUPP_TITLE_CD`, `AI_LETTER_DT`, `AI_PORT_CD` → `ajax_fun(code)` |
| `LOV_UPDATE_IMPR_MOBILE` | EXEC_FUNS IMPR1110_MOB (`IMPR_NBR > 3000000`) | Modal dialog with `P_CENTRAL_MOBILE = central_mobile`; on close sets `AI_MOBILE_NO` → `ajax_fun('IMPR1110_MOB_RET')` |
| `IMPR1115` (`P_IMPR_NO`) | EXEC_FUNS IMPR1115_SCR | link to the IMPR1115 page when converted |
| `V_CALLED_FORM` (TMPLT menu) | EXECUTE_FUNCTION | function menu → `ajax_fun(code)`; screens from `SC_SYSTEM_OBJECTS` → navigation menu |

### 5.4 Confirm alerts (answer → package parameter)

| Forms alert | Where | APEX |
|---|---|---|
| "يجب مراجعة البيانات والتأكد من صحتها قبل التخزين …" (CONFIRM) | PRE-INSERT, class 1 / user type 3 | Confirm DA on SAVE when new row and `AI_P_CLASS_CD = 1` and `AI_P_USER_TYPE = 3`; "no" = no submit |
| "هل أنت متأكد من عملية الحذف" (WARNING) | KEY-DELREC | Confirm DA on DELETE |
| "يوجد مستورد … موقوف له نفس الرقم الإستدلالي …" (WARNING) | BUS_ID WVI | `ajax_confirm('SUSP')`; answer → x04 of `ajax_item(VALIDATE)` |
| 9-120 "… <converted number>" (`'ERROR'` alert) | BUS_ID / BUS_ID_BRNCH WVI | `'ERROR'` alerts have one button → always button 1 → number converted automatically, text shown as message (x03 default yes) |
| " سيتم تعديل الإسم إلى ( … )" (CONFIRM) | WNRI, functions IMPR1110F1 / F5 | `ajax_confirm('WNRI')` |
| UPDATE_IMPORTER "… تأكيد التحديث؟" (CONFIRM) | function IMPR_MCI_SERVICE | `ajax_confirm('UPD_IMPR')`, then `ajax_fun('IMPR_MCI_SERVICE', answer)` – **save first** (Forms commits before asking) |

### 5.5 Function menu (TMPLT side menu → APEX "Functions" menu button)

Codes handled by `EXEC_FUNS`: `IMPR1110F1` (rename from CR), `IMPR1110F2` (change BUS_ID / CR type),
`IMPR1110F3` (change importer type, class 19), `IMPR1110F4` (change BUS_ID expiry), `IMPR1110F5`
(rename), `IMPR_CAR_AGENT` (→ `IMPR1110SF6`, car agent flag), `IMPR_MCI_SERVICE`,
`CREATE_BRKR_IMPR_AUTH`, `IMPR1115_GZT`, `IMPR1115_SCR`, `IMPR1110_MOB`. The list of functions a
user may run comes from `TMPLT.LOAD_FUNCTIONS(P_USER_ID, P_MODULE_ID)` (MISSING SOURCE) – each entry
needs an Authorization Scheme in step 03; `ADJ_FUNS` only switches entries on/off on top of that.

---

## 6. Globals and parameters

### 6.1 `:PARAMETER.*`

| Forms | APEX | Used by |
|---|---|---|
| `P_CURR_PORT_CD`, `P_USER_ID`, `P_WS_ID`, `P_CLASS_CD`, `P_USER_TYPE` | Application Items `AI_P_*` (set at login / menu) → `t_ctx` | many |
| `P_BRKR_PORT_CD`, `P_LIC_TYPE`, `P_BRKR_NBR` | `AI_P_*` → `t_ctx` | `create_brkr_impr_auth` |
| `PRSNL_IMPR` (default 0), `LETTER_NBR`, `CODE` | Page items `P1110_PRSNL_IMPR`, `P1110_LETTER_NBR`, `P1110_CODE` (URL / function menu) → `t_ctx` | WCR, PRE-QUERY, WNFI, PRE-UPDATE, WNRI |
| `P_PORT_TYPE` | LOV parameter of LOV_SD_PORTS | PORT_CD LOV only |
| `P_USER_NAME`, `P_MODULE_NAME`, `P_MODULE_ID`, `P_GROUP_CD`, `P_JOB_ID`, `P_BANK_CD`, `P_BANK_BRNCH_CD`, `P_SHPG_AGNT_NBR`, `P_CTRL_LAST_EXEC_CD`, `P_CURRENT_ITEM`, `P_APPLICATION_NAME`, `CG$STARTUP_MODE` | not needed | title bar, TMPLT menu, help (dropped code) |

### 6.2 `:GLOBAL.*` (44 names) → Application Items `AI_<NAME>` via `pkg_forms_compat.get/set_global`

| Global | Set by | Read by | Note |
|---|---|---|---|
| `FLAGUPDATE` | WNFI (0), POST-CHANGE of 9 items (1), POST-UPDATE (0) | POST-UPDATE | controls `update_basic_importer` |
| `EXEC_QUERY_NOW`, `PORT_CD`, `IMPR_NBR` | IMPR_NBR WVI, WNFI | PRE-QUERY, WNII triggers | re-query mechanism. `PORT_CD` / `IMPR_NBR` are also LOV return globals and `PORT_CD` is read by PRE-UPDATE journaling – same name, three meanings (see §7.4 Q6) |
| `VALID` | WNFI (0), IMPR_TYPE LOV return (1), IMPR_TYPE WVI (0) | IMPR_TYPE WVI | skip type → bus-id-type defaulting after the LOV |
| `FUNS_IMP`, `FUNS_BUSID`, `CHK_IMP_TYP` | WNFI, WNRI | IMPR_TYPE WVI, BUS_ID / BUS_ID_BRNCH WVI, IMPR_TYPE LOV | function-code modes |
| `CHK_DUP_BUSID` | WNFI (0), PRE-INSERT (0) | PRE-INSERT | never 1 (see §0.1 row 2) |
| `OLD_IMPR_TYPE_CD`, `OLD_PORT_CD` | WNFI, POST-QUERY | CHK_PERSONAL, B_MOBILE_NO WVI | |
| `ALLOW_MCI`, `ALLOW_MOI` | WNFI (`SC_PORT_SETTING`, sysobj 24) | BUS_ID / BUS_ID_BRNCH WVI, ADJ_FUNS, MCI function | |
| `SET` | PRE-INSERT (new importer number) | PRE-INSERT, POST-INSERT | |
| `MINS_COMM_CD` | WNFI (NULL), WNII (NULL); filled by a LOV form (MISSING SOURCE) | BUS_ID / BUS_ID_BRNCH WNII | |
| `LETTER_NBR`, `SUPP_TITLE_CD`, `LETTER_DT` | SUPPORT_ENTRY dialog; WNFI (NULL) | PRE-UPDATE (`DB_JOURNAL.JOURNALING_ON`), EXEC_FUNS | |
| `MOBILE_NO` | LOV_UPDATE_IMPR_MOBILE dialog | `lov_update_moblie` | |
| `IMPR_NBR_B`, `IMPR_NAME_B`, `BRKR_ATHRZTN_NBR_B` | RETURN_IMPR_ID, CREATE_BRKR_IMPR_AUTH | calling form (broker screens) | keep as application items |
| `CHEK` | – (never set here) | POST-INSERT | external / OLB |
| `STAT_QUE`, `STAT_CLR`, `IMP0F4`, `EXE_DETAIL_QUERY`, `INS` | WNFI / POST-QUERY / WCB / WCR | – (never read in this form) | kept for other forms; can be dropped if no other form reads them |
| `IMPR_TYPE_CD`, `IMPR_TYPE_NAME`, `BUS_ID_TYPE_CD`, `BUS_ID_TYPE_NAME`, `CTRY_CD`, `CRTY_ARBC_NAME`, `CITY_CD`, `CITY_ARB_NAME`, `PORT_NAME`, `IMPR_NAME` | LOV forms | KEY-LISTVAL | replaced by Popup LOV return columns – no application item |
| `EXIT`, `CURRENT_VER`, `CURRENT_DT`, `CURRENT_VERSION`, `CG$HP_*` (`CG`), `SYSTEM_OBJ` | PRE-FORM / toolbar / help | toolbar, help, reports | dropped |

---

## 7. Dropped logic, HIGH flags, TODOs and open questions

### 7.1 Dropped logic (with reason)

* 165 empty units (OLB-inherited triggers with no code or code fully inside `/* */`).
* `NIB.*` key triggers (KEY-EDIT, KEY-DUPREC, KEY-ENTQRY, KEY-EXIT, KEY-PRINT, KEY-NXTREC, …,
  ON-ERROR/ON-MESSAGE at form level, WHEN-TIMER-EXPIRED, WHEN-MOUSE-DOWN, WHEN-WINDOW-ACTIVATED,
  PRE-FORM part) – toolbar / keyboard library `NIB` (MISSING SOURCE); APEX standard buttons replace them.
* OLB blocks `TITLE`, `EDI_MSG`, `LSIDE`, `TOOLBAR` (title bar, EDI message ticker, side function
  menu) – APEX header, notifications and the function-menu button replace them.
* 45 identical `KEY-LISTVAL` guards and 11 LOV buttons (`GO_ITEM` + `LIST_VALUES`) – native Popup LOV.
* Help (`KEY-HELP`, 10 copies) – help file name is empty in the form.
* Unused program units: `VIEW_SAME_BUSID`, `CHECK_TIMEOUT`, `MOUSE_CLICK`, `TOGGEL_WND`,
  `PRINT_REPORT`, `TERMINATE_FUN`, EDI units, `DEV_VERSIONS`, `CGFK$QRY_IMPORTERS_IMP_SDP_FK`,
  `CGFK$CHK_IMPORTERS_IMP_MB_FK`.
* `CGFK$DEFAULT_WHERE` dynamic SQL and `CG$IMPR1110_PROD_CENTRL_GLOBAL` – replaced by a bound
  region query (§2.2).

### 7.2 HIGH flags (behaviour that must be confirmed before go-live)

| # | Flag | Where |
|---|---|---|
| H1 | **Insert path.** PRE-INSERT calls `IMPR_CENTRAL.Create_Uni_IMPR_NEBRAS` (returns the new number), then Forms runs its default INSERT with `IMPR_NBR` still NULL, and POST-INSERT calls `INSERT_AUDIT_RECORD('I')`, which fails with 9-140 when `IMPR_NBR` is NULL. This cannot work as written unless something not in the XML intervenes (a view with INSTEAD OF trigger, a DB trigger, DML-returning from `CIC_OLB`, or `Create_Uni_IMPR_NEBRAS` inserting the row). **Run a Forms trace of one insert** and adjust `importers_ins` accordingly. Kept exactly as Forms issues it. | `importers_pre_ins`, `importers_ins`, `importers_post_ins` |
| H2 | **COMMITs removed** (APEX commits once at the end): `UPDATE_BASIC_IMPORTER` (`STANDARD.COMMIT` inside POST-INSERT/POST-UPDATE), `CREATE_BRKR_IMPR_AUTH`, `LOV_UPDATE_MOBLIE`, `UPDATE_IMPORTER` (`FORMS_DDL('COMMIT')` first), `KEY-DELREC` (2 commits – in Forms the `IMPR_UPDTS` delete survives a failed importer delete; in APEX it is rolled back too), WNRI `IMPR1110F3` (`COMMIT` → `DO_COMMIT`). | see members |
| H3 | **POST-CHANGE on fetch.** Forms fires POST-CHANGE for fetched non-NULL items. Here that would set `FLAGUPDATE = 1` and run the `BUS_ID_TYPE_CD` country defaults (sets `ADD_CTRY_CD = 100` on every queried importer) before POST-QUERY. Implemented behind `pkg_impr1110_apx.c_post_chg_on_fetch = TRUE`; confirm with a trace. | `pkg_impr1110_apx.page_fetch` |
| H4 | **Port move.** Changing `B_EMAIL`, `B_MOBILE_NO` or `B_ID_NBR` sets `PORT_CD` to the user's port; the next UPDATE writes the new `PORT_CD` (key = ROWID). | `b_email_post_chg` & co., `importers_upd` |
| H5 | `EMAIL` and `ID_NBR` columns of `IMPORTERS` are never updated from the screen copies `B_EMAIL` / `B_ID_NBR` (only `MOBILE_NO` in PRE-UPDATE); the screen values go to `IMPORTER_BASIC_DATA`. Kept – confirm it is intended. | `importers_pre_upd`, `update_basic_importer` |
| H6 | Block property `DeleteAllowed = false`, yet `KEY-DELREC` deletes when the toolbar `REMOVE` button is visible and enabled (TMPLT). Decide whether DELETE exists in APEX and its authorization. | `importers_key_delrec` |
| H7 | Item validation fires on change only (as in Forms). Several validations consume sequences (`KING_IMPR_SEQ`, `IMPORTERS_SEQ` in `impr_type_cd_wvi`), so they are **not** re-run at submit. The page must block SAVE while an item validation failed and must re-validate items flagged `VALID = false`. | `pkg_impr1110_apx`, step 03 |

### 7.3 TODO / MISSING SOURCE (10 in code)

| # | TODO | Member |
|---|---|---|
| 1 | `INTRFACE.pll` – exact properties set by `Make_Field_Entrable`, `MAKE_BLOCK_FULL_OPERATION`, `Disp_date_con` | `entrable`, §5 |
| 2 | `TMPLT` – `ENABLE_FUN` / `DISABLE_FUN` / `LOAD_FUNCTIONS` (function list per user) | `fun`, §5.5 |
| 3 | `STR.pll` – `DispArbMsg` output format (assumed `sys-nbr : text`) | `arb_msg` |
| 4 | `Des$Form_errors.MSGGETTEXT` (CG library) – Arabic text of CG messages 13 / 78 / 6 | `cg_msg` |
| 5 | `ACTIVITY.ADD_ACTIVITY` – DB package or client library? signature | `add_activity` |
| 6 | `HIJDATE.VALID_HIJ_DATE` – assumed `HIJDATE_DB.valid_hij_date` | `valid_hij_date` |
| 7 | `CGTE$STRIP_CONSTRAINT` / `CGTE$STRIP_FIRST_ERROR` (CG library) – re-implemented with REGEXP | `strip_constraint`, `importers_on_error` |
| 8 | `STR_DB.StrFormat(text, TRUE)` – 2-argument overload | `importers_pre_qry` |
| 9 | Arabic text of FRM-40654 (row changed by another user) shown by `NIB.ON_ERROR` | `importers_upd` |
| 10 | POST-CHANGE on fetch (H3) | `pkg_impr1110_apx` spec |

DB objects called by the package – verify they exist, and grant EXECUTE / SELECT to the parsing schema
(names exactly as the form uses them, incl. `LIB_USR.` prefixes):
`STR_DB.GetArbMsg/StrFormat/RemoveRepeat`, `HIJDATE_DB.Cur_Hij_Date`, `GNRL.get_customs_setting`
(2- and 3-argument), `GNRL.get_sequence_value`, `GNRL.get_customs_seq`,
`LIB_USR.GNRL.get_customs_setting`, `LIB_USR.IMPR.Impr_Suspended`, `IMPR.CHECK_DUPLICATE_IMP_BRKR`,
`IMPR.CHK_MOBILE_FORMAT`, `LIB_USR.IMPR_CENTRAL.Create_Uni_IMPR_NEBRAS` (43 arguments),
`LIB_USR.IMPR_UTILITIES.UPDATE_IMPORTERS_NAMES`, `IMPR_UTILITIES.UPDATE_IMPR_MOBILE_NO`,
`MCISERVICE.getMainCRInfoCall/getBranchCRInfoCall`, `LIB_USR.WEB_SERVICES_GAZT.Pr_Import_Impr_Certificate`,
`DB_JOURNAL.JOURNALING_ON/JOURNALING_OFF/IS_JOURNALING_ON`, `ACTIVITY.ADD_ACTIVITY`; tables / views
`IMPORTERS`, `IMPORTERS_CENTRAL`, `IMPR_UPDTS`, `IMPORTER_BASIC_DATA`, `HQ_IMPRS`, `COMM_IMPR_RGSTR`,
`IMPR_SUSPNS`, `IMPR_CNTRL_SUSPNS`, `IMPR_DUTY_DIFF_BLKS`, `DUTY_DIFF_BLK_EXP_DTLS`, `STATS_DCLTNS`,
`DECLARATIONS`, `PRIVILEGED_IMPORTERS`, `MCI_BUS_ID_STATUS`, `IMPR_COMMON_DATA`, `IMPR_TYPES`,
`IMPR_TYPE_ID_TYPES`, `BUS_ID_TYPES`, `COUNTRIES`, `CTRY_GROUP_DETAILS`, `CITIES`, `SD_PORTS`,
`SC_PORT_SETTING`, `SC_USER_ROLES`, `BRKIMPS`.

### 7.4 Open questions (decisions needed before step 03)

1. H1 – insert path (trace needed).
2. H3 – POST-CHANGE on fetch (trace needed).
3. H6 – keep DELETE? which authorization?
4. Hijri dates: columns are `DATE` with mask `MI-MM-YYYY` (minutes as day – kept exactly as Forms). Confirm, and choose the Hijri picker for F4.
5. Function-menu authorization source (`TMPLT.LOAD_FUNCTIONS`) – which table / package lists the functions per user?
6. `:GLOBAL.PORT_CD` is used for the re-query, as LOV return and by PRE-UPDATE journaling (`DB_JOURNAL.JOURNALING_ON(:GLOBAL.PORT_CD, …)`). Which value does SUPPORT_ENTRY leave there?
7. `GLOBAL.MINS_COMM_CD` – which LOV form fills it?
8. APEX application id (registry uses 2000 provisionally).

### 7.5 Files that now need updating (later steps)

| File | Why |
|---|---|
| `apex/IMPR1110/IMPR1110_page_spec.md` (step 03) | written against the v0 API (`pkg_impr1110.validate_item`, `page_dml`, `ui_state_json`) – redo with §3.2 / §5 |
| `tests/IMPR1110/test_pkg_impr1110.sql`, `uat_IMPR1110_ar.md` (step 05) | v0 signatures; regenerate |
| `registry/IMPR1110_registry.sql` | object map should list the v1 members |
| `analysis/IMPR1110/README_ar.md` | open questions 1, 7 and 10 changed (see §0.1, §7.4) |

---

## 8. How the package was built and checked

```text
python -I scripts/expand_orig.py forms/IMPR/IMPR1110_fmb.xml \
       plsql/IMPR1110/pkg_impr1110_body.sql plsql/IMPR1110/pkg_impr1110_spec.sql \
       plsql/IMPR1110/pkg_impr1110_apx_spec.sql plsql/IMPR1110/pkg_impr1110_apx_body.sql
```

* Each `--@ORIG <unit>` line in the body is followed by the verbatim original code of that unit
  (61 blocks). Re-running replaces the blocks (idempotent – same MD5 after a second run). The XML is
  only read.
* Self-checks (all passed, `0 problem(s)`):
  1. every `--@ORIG` unit exists in the XML;
  2. every Arabic string literal in the four `.sql` files occurs verbatim in the form code
     (213 literals; a deliberately misspelled test string was detected);
  3. no Forms built-in outside comments (GO_BLOCK, GO_ITEM, SET_ITEM_PROPERTY, SHOW_ALERT,
     EXECUTE_QUERY, FORM_TRIGGER_FAILURE, NAME_IN, COPY, `:SYSTEM.`, `:GLOBAL.`, `:PARAMETER.`, …;
     `pkg_forms_compat.*` wrappers allowed);
  4. no identifier longer than 30 bytes.
* Spec ↔ body: 82 signatures compared programmatically – 0 differences; body sections follow the
  spec order (form → block → items → program units).
* Not done: compilation, utPLSQL, running against data – no 12.1.0.2 database was available.
