# IMPR1125 – Inventory & Migration Risk Assessment

- **Form:** IMPR1125 (module name in the XML: `IMPR1125_CENTRAL`) – "صيانة توقيفات المستوردين", purpose "توقيفات المستوردين المركزية" (central importer suspensions, by unified importer number `HQ_IMPR_NBR`)
- **Source:** `forms/IMPR/IMPR1125_fmb.xml` (frmf2xml output, 628 lines)
- **Target:** Oracle APEX 21.2 on Oracle Database 12.1.0.2, reference application f345 (CLAUDE.md §4b, §4c)
- **Produced:** 2026-11-24 (step 01, revision 1): mechanical sections by `scripts/gen_inv.py`; manual analysis in sections 1, 2 notes, 3–9 notes, 10.3, 10.6–10.8, 11–15 (sources in `work/IMPR1125/inv_man/`).
- **Sources used besides the form XML:** library texts `forms/COMMON/libraries/*.pld` (`CIC_LIB`, `OFGBSL`), object library `forms/COMMON/olb/CIC_OLB_OLB.xml`, the LOV forms `forms/COMMON/lov_forms/LOV_IMPORT_HQ_NBR_fmb.xml` and `LOV_DELETE_IMP_SUSP_fmb.xml`, DB packages `plsql/Shared/ACTIVITY_DB.*` and `HIJDATE_DB.*`. The IMPR1110 / IMPR1120 inventories were used for the shared library and OLB findings; they are repeated here only where IMPR1125 uses them.
- **Relation to IMPR1120:** same title and frame, same SMS / notification pattern, but a **different data model**: IMPR1120 maintains port-level suspensions (`IMPORTERS` → `IMPR_SUSPNS`, by port + importer number); IMPR1125 maintains **central** suspensions (`HQ_IMPRS` → `IMPR_CNTRL_SUSPNS`, by unified number). It answers IMPR1120 §15 #2: two separate pages.
- **Scope rule:** anything not available is marked **MISSING SOURCE** and is not guessed: the libraries OFGTEL, SEC_LIB, OFGTAB, PICKLIST, POS, SCDLL, VCDLL, and the DB packages `SMS_MESSAGE`, `LIB_APX_USR.APEX_NOTIFICATIONS`, `GNRL`, `STR_DB`.
