# IMPR1150 – Inventory & Migration Risk Assessment

- **Form:** IMPR1150 (module name in the XML: `IMPR1150_PROD_CENTRL`) – activation of the importers registered on the Fasah platform (block comment "المستوردين من منصحة فسح"; functions `IMPR1150_ACTIVATE` / `IMPR1150_REJECT`)
- **Source:** `forms/IMPR/IMPR1150_fmb.xml` (frmf2xml output)
- **Target:** Oracle APEX 21.2 on Oracle Database 12.1.0.2, reference application f345 (CLAUDE.md §4b, §4c)
- **Produced:** 2026-11-25 (step 01): mechanical sections by `scripts/gen_inv.py`; manual analysis in sections 1, 13–15 (sources in `work/IMPR1150/inv_man/`).
- **Sources used besides the form XML:** library text `forms/COMMON/libraries/CIC_LIB.pld` (NIB, STR, INTRFACE, TMPLT, ACTIVITY), DB package `plsql/Shared/ACTIVITY_DB.*`; the IMPR1130 / IMPR1116 inventories for the shared OLB frame findings.
- **Scope rule:** anything not available is marked **MISSING SOURCE** and is not guessed: the libraries OFGTEL, SEC_LIB, OFGTAB, PICKLIST, POS, SCDLL, VCDLL; the text of message 9-150 (`STR_DB`, read at run time by `FORMS_APX.ARABIC_MESSAGE`).
