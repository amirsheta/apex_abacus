# IMPR1140 – Inventory & Migration Risk Assessment

- **Form:** IMPR1140 – "قواعد التعامل مع المستوردين" (Importer Handling Rules / exceptions: "استثناءات التعامل مع المستوردين (جمارك - بنود تعرفة)", Designer function IMPR1140)
- **Source:** `forms/IMPR/IMPR1140_fmb.xml` (frmf2xml output, 729 lines)
- **Target:** Oracle APEX 21.2 on Oracle Database 12.1.0.2, reference application f345 (CLAUDE.md §4b, §4c)
- **Produced:** 2026-11-24 (step 01): mechanical sections by `scripts/gen_inv.py`; manual analysis in sections 1, 3–9 notes, 10.3, 10.6–10.8, 11–15 (sources in `work/IMPR1140/inv_man/`).
- **Sources used besides the form XML:** library texts `forms/COMMON/libraries/*.pld` (`CIC_LIB` for NIB, STR, INTRFACE, TMPLT, ACTIVITY, KEY_CONTROL, REP; `OFGBSL` for `CGBS$`), object library `forms/COMMON/olb/CIC_OLB_OLB.xml`, the LOV forms `forms/COMMON/lov_forms/LOV_IMPORT_HQ_NBR`, `LOV_IMPORT_HQ_N12`, `LOV_TRF_ITEMS`, `LOV_SD_PORTS`, DB package `plsql/Shared/ACTIVITY_DB.*`. The IMPR1110 / IMPR1120 inventories were used for the shared library, OLB and frame findings; they are repeated here only where IMPR1140 uses them.
- **Scope rule:** anything not available is marked **MISSING SOURCE** and is not guessed: the libraries OFGTEL, SEC_LIB, OFGTAB, PICKLIST, POS, SCDLL, VCDLL, and the DB packages `LIB_USR.SMS_MESSAGE`, `STR_DB` (message 1-270).
