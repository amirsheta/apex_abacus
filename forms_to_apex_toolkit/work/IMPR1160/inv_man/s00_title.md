# IMPR1160 – Inventory & Migration Risk Assessment

- **Form:** IMPR1160 (title in the XML: `IMPR1160_ND_CNTRL`) – car exceptions of individual importers (table comment "استثناء المستوردين الافراد للسيارات"): an importer of type 4 is allowed to clear a number of cars of one customs or statistical declaration, by an award letter
- **Source:** `forms/IMPR/IMPR1160_fmb.xml` (frmf2xml output); LOV forms `forms/COMMON/lov_forms/LOV_IMPR_P_fmb.xml`, `LOV_IMPR_DCLTN_fmb.xml`
- **Target:** Oracle APEX 21.2 on Oracle Database 12.1.0.2, reference application f345 (CLAUDE.md §4b, §4c)
- **Produced:** 2026-11-25 (step 01): mechanical sections by `scripts/gen_inv.py`; manual analysis in sections 1, 13–15 (sources in `work/IMPR1160/inv_man/`).
- **Sources used besides the form XML:** library text `forms/COMMON/libraries/CIC_LIB.pld` (NIB, STR, INTRFACE.MAKE_BLOCK_FULL_OPERATION, HIJDATE), OLB `forms/COMMON/olb/CIC_OLB_OLB.xml` (item classes `CGSO$CHAR_ARB_DO`, `CGSO$HDATE_ARB` …); the IMPR1140 / IMPR1150 inventories for the shared OLB frame findings.
- **Scope rule:** anything not available is marked **MISSING SOURCE** and is not guessed: the libraries OFGTEL, SEC_LIB, OFGTAB, PICKLIST, POS, SCDLL, VCDLL; DB package `GNRL` (`GET_SEQUENCE_VALUE`, `GET_CUSTOMS_SETTING`, called unchanged); the DDL of `IMPR_CAR_EXCEPTION` (column types taken from the Forms items).
