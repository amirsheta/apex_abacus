
## 15. Registry script

`registry/IMPR1110_registry.sql` v3.0 (generated): one `MIG_FORM_REGISTRY` row (app 202530, page 1110,
package IMPR1110, status DESIGN) and one `MIG_OBJECT_MAP` row per line of §14. Re-runnable: it deletes the
form's rows first, and it ends with COMMIT. **Not executed** (CLAUDE.md §6.10).

## 16. Changes made to step-02 code during this step, open items

Package `IMPR1110` **005 → 006** (generator `work/step02/build_package.py`, self-check clean):
- DATE columns (BUS_ID_EXPRD_DT, BUS_ID_ISSUE_DT, LST_TRAN_DT) are passed as `VARCHAR2` and converted with
  `c_mask` (`MI-MM-YYYY`) / `c_date_time_mask` (`YYYY/MM/DD HH24:MI:SS`, the Forms PLSQL_DATE_FORMAT).
  APEX binds page items as text with the application date format (`DS`), which cannot read Hijri values.
- `P0_PAGE_PK_CHECK` checks a ROWID key; new `IMPORTER_ROW_ID` for process `EXECUTE-QUERY`.
- `READ_ONLY_FLAGS` covers 14 groups (added IMPR_TYPE_CD, BUS_ID_EXPRD_DT, IMPR_TEL_NBR and CAR_AGENT_FLAG,
  which the function modes and PRE-INSERT unlock).

Open items:

| # | Item | Blocks |
|---|---|---|
| 1 | HIGH (extraction §7 #1): how IMPR_NBR gets its value on insert (`CREATE_UNI_IMPR_NEBRAS`, a DB trigger, or a view). The ROWID key works either way, but the native insert must give the same row as Forms | CREATE |
| 2 | SUPPORT_ENTRY is converted as its own form (decision §15 #12): its page number, the `P1110_SUPPORT_URL` computation, and the G_ items it sets on close | functions F1, F2, F3, F5 |
| 3 | `SYS_OS_FILE_NAME` values of the 11 functions: the custom-event names and the `ADJ_FUNS` list must match them exactly (with or without `.fmx`) | functions |
| 4 | Security: an item disabled by a `READ ONLY` DA is enforced only in the browser. A changed request could still update a locked column. SUGGESTION: a server-side check in PRE_UPDATE that compares the locked columns with the database row, using the same `<ITEM>_IS_READ_ONLY` functions | SAVE |
| 5 | Forms runs `IMPR_TYPE_CD_LOV_RETURN` only after an LOV pick; the design runs it on every change of IMPR_TYPE_CD (TODO-VERIFY in step 05) | IMPR_TYPE_CD |
| 6 | The broker question (PRE-INSERT CONFIRM) is asked before the validations; Forms asks it inside PRE-INSERT, after them | CREATE |
| 7 | WHEN-NEW-RECORD-INSTANCE also runs after every SAVE (the page renders the record again); Forms stays in the record. Check the class 19 / user type 1 rule (IMPR_TYPE_CD := 19) for side effects | SAVE |
| 8 | `P_BRKR_PORT_CD`, `P_LIC_TYPE` are not set by the f345 login (§13.2) | brokers |
| 9 | Arabic texts of FRM-40202 / 40350 (NIB.ON_ERROR, MISSING SOURCE) | messages |
| 10 | FOS success-message display of `FORMS_APX.MESSAGE` text from an AJAX call (§10.1) | notes |
| 11 | List template of region `FUNCS` and the session-setup process `New`: copy them from AGR1100 (git history of f345) | step 04 |
| 12 | Decision §15 #6 (page 0 DELETE offered, no extra function restriction): to be confirmed | DELETE |

Step 04 must replace `scripts/gen_apex_impr1110.py` (revision-1 design: AJAX, JavaScript file). The new
generator should read `work/step03/page_design.json`.
