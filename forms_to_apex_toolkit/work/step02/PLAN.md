# Step 02 (revision 2) — IMPR1110 logic extraction — work plan and progress

Started 2026-11-19. Standard: CLAUDE.md §3.2, §4, §4b, §4c; docs/f345_reference_standard.md §5, §9, §10;
prompt_templates/02_logic_extraction.md. Decisions from step 01: inventory §15 (#6 delete offered,
#9 timers dropped, #10 Hijri = DATE, #12 SUPPORT_ENTRY separate form, #16 WNRI type-19 rule kept, no COMMIT).

Inputs: forms/IMPR/IMPR1110_fmb.xml → work/step02/units.json (211 units with code: 53 PUs, 158 triggers),
analysis/IMPR1110/IMPR1110_inventory.md (rev 2), forms/COMMON/libraries/CIC_LIB.pld, plsql/Shared/*.
Previous step-02 output (rev 1, session-state design): rollback/IMPR1110/step02_rev1/.

Outputs: plsql/IMPR1110/impr1110_spec.sql, impr1110_body.sql (package LIB_APX_USR.IMPR1110),
analysis/IMPR1110/IMPR1110_logic_extraction.md.

## Design decisions

1. One package `IMPR1110`. No session-state adapter, no record of all items, no UI recorder (ui/entrable/JSON).
2. Members called by APEX take exactly the items they read (I_) and change (IO_ / O_); internal helpers use p_.
3. DML: APEX native Form region DML ("Process form") on IMPORTERS; package PRE_INSERT / POST_INSERT /
   PRE_UPDATE / POST_UPDATE / KEY_DELREC around it (f345 §6). PRE_INSERT computes IMPR_NBR via
   LIB_USR.IMPR_CENTRAL.CREATE_UNI_IMPR_NEBRAS (TODO-VERIFY: may insert itself — inventory §15 #5).
4. Read-only rules (Make_Field_Entrable, 201 calls; SET_ITEM_PROPERTY ENABLED/REQUIRED/VISIBLE): net effect
   per item as BOOLEAN functions <ITEM>_IS_READ_ONLY / <GROUP>_IS_READ_ONLY over the state inputs
   (IMPR_TYPE_CD, BUS_ID_TYPE_CD, COMM_RGSTRTN_TYPE, record saved?, function CODE, P_CLASS_CD, V_USR_TYPE).
   Used by item Read Only conditions; the same functions feed FOS flag items for native Enable/Disable.
5. Messages: STR.DispAlert ERROR/SYSTEM_ERROR → FORMS_APX.FORM_TRIGGER_FAILURE(text);
   INFORMATION → FORMS_APX.MESSAGE; CONFIRM/WARNING → split (question in APEX, branch in a procedure).
6. Dropped (screen frame, replaced by f345): TITLE, TOOLBAR, LSIDE, EDI_MSG triggers; NIB.* startup /
   key / timer / window calls; KEY-HELP (MS-Help); CHECK_TIMEOUT, TOGGEL_WND, timers, TEXT_IO.
7. Library calls → DB: HIJDATE → HIJDATE_DB, ACTIVITY → ACTIVITY_DB (p_ctx port/user/ws), STR.StrFormat →
   STR_DB.StrFormat, KEY_CONTROL.FOUND_KEY → role query (same tables as Page Functions list).
8. No COMMIT / FORMS_DDL('COMMIT'): APEX commits at the end of the request.
9. Names in full words; ≤ 30 bytes (drop WHEN_ first); Forms program-unit names unchanged.

## Progress

- [x] units.json work list
- [x] entrable / required / visible rules per item  → work/step02/read_only_rules.md
- [x] classification of all 211 units               → work/step02/classification.md (112 dropped, 99 converted)
- [x] package spec (sections per §10, items in Forms navigation order)      → build_package.py
- [x] package body: private converted logic (rev 1, Forms order, 130 UI calls → NULL; -- APEX)
- [x] package body: read-only / required / visible rules                   → rules.sql
- [x] package body: f345 helpers                                           → helpers.sql
- [x] package body: 76 generated entry points (I_ / IO_ from the call graph) → entries.json
- [x] extraction report                                                     → analysis/IMPR1110/IMPR1110_logic_extraction.md
- [x] self-check (no findings; negative test on rev 1: 758)                 → self_check.py / self_check.json
- [ ] compile on 12.1.0.2 (needs a database)
- [ ] split the 8 members over 80 lines (after step 05 tests exist)

Changed decision: classification of PRE-FORM → DROPPED (only version stamp, date format, help path).
