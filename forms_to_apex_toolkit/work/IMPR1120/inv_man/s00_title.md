# IMPR1120 – Inventory & Migration Risk Assessment

- **Form:** IMPR1120 – "صيانة توقيفات المستوردين" (Importer Suspension Maintenance, Designer function IMPR40000)
- **Source:** `forms/IMPR/IMPR1120_fmb.xml` (frmf2xml output, 717 lines)
- **Target:** Oracle APEX 21.2 on Oracle Database 12.1.0.2, reference application f345 (CLAUDE.md §4b, §4c)
- **Produced:** 2026-11-23 (step 01, revision 1): mechanical sections by `scripts/gen_inv.py`; manual analysis in sections 1, 3–9 notes, 10.3, 10.6–10.8, 11–15 (sources in `work/IMPR1120/inv_man/`).
- **Sources used besides the form XML:** library texts `forms/COMMON/libraries/*.pld` (`CIC_LIB` for NIB, STR, INTRFACE, TMPLT, HIJDATE, ACTIVITY, KEY_CONTROL, REP; `OFGBSL` for the Designer master-detail package `CGBS$`), object library `forms/COMMON/olb/CIC_OLB_OLB.xml`, the LOV forms in `forms/COMMON/lov_forms/`, the launcher `forms/SC/APPS_fmb.xml`, DB packages `plsql/Shared/ACTIVITY_DB.*` and `HIJDATE_DB.*`. The IMPR1110 inventory was used for the shared library and OLB findings; they are repeated here only where IMPR1120 uses them.
- **Scope rule:** anything not available is marked **MISSING SOURCE** and is not guessed: the libraries OFGTEL, SEC_LIB, OFGTAB, PICKLIST, POS, SCDLL, VCDLL, and the DB packages `SMS_MESSAGE`, `LIB_APX_USR.APEX_NOTIFICATIONS`, `GNRL`, `STR_DB`.
