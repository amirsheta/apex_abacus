# IMPR1130 – Inventory & Migration Risk Assessment

- **Form:** IMPR1130 (module name inside the XML: `IMPR1110_PROD_CENTRL`) – "إضافة وتعديل بيانات مستورد" (Add / update importer data)
- **Source:** `forms/IMPR/IMPR1130_fmb.xml` (frmf2xml output)
- **Target:** Oracle APEX 21.2 on Oracle Database 12.1.0.2, reference application f345 (CLAUDE.md §4b, §4c, §4d)
- **Produced:** 2026-11-24 (step 01, revision 1): mechanical sections by `scripts/gen_inv.py`; manual analysis in sections 1, 2 (note), 3–9 notes, 10.3, 10.6–10.8, 11–15 (sources in `work/IMPR1130/inv_man/`). Unit-by-unit comparison with IMPR1110: `work/IMPR1130/compare_impr1110.md`.
- **Sources used besides the form XML:** the IMPR1110 analysis (`analysis/IMPR1110/IMPR1110_inventory.md` rev 2, whose library / OLB / menu findings apply unchanged because both forms attach the same 17 libraries and the same OLB), `forms/COMMON/libraries/CIC_LIB.pld`, `forms/COMMON/olb/CIC_OLB_OLB.xml`, the LOV forms in `forms/COMMON/lov_forms/`, `forms/SC/Support_Entry_fmb.xml` and the SUPPORT_ENTRY analysis, `plsql/Shared/*`.
- **Scope rule:** what is not available is marked **MISSING SOURCE** and is not guessed: libraries OFGTEL, SEC_LIB, OFGTAB, PICKLIST, POS, SCDLL, VCDLL; DB packages GNRL, IMPR, IMPR_CENTRAL, IMPR_UTILITIES, MCISERVICE, STR_DB, DB_JOURNAL (spec only through SUPPORT_ENTRY).
