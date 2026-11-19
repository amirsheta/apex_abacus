# IMPR1110 – Inventory & Migration Risk Assessment

- **Form:** IMPR1110 (module `IMPR1110_PROD_CENTRL`) – "إضافة وتعديل بيانات مستورد"
- **Source:** `forms/IMPR/IMPR1110_fmb.xml` (frmf2xml output, 897 lines)
- **Target:** Oracle APEX 21.2 on Oracle Database 12.1.0.2, reference application f345 (CLAUDE.md §4b, §4c)
- **Produced:** 2026-11-19 (revision 2 of step 01) – mechanical sections by `scripts/gen_inv.py`, manual analysis in sections 1, 10.3, 10.6–10.8, 11–15. Revision 1 (2026-11-18): `rollback/IMPR1110/IMPR1110_inventory_v1.md`.
- **Sources used besides the form XML (new in revision 2):** library texts `forms/COMMON/libraries/*.pld` (10 of the 17 attached libraries, incl. `CIC_LIB`), object library `forms/COMMON/olb/CIC_OLB_OLB.xml`, menu `forms/COMMON/menus/CIC_MENU_MMB.xml`, the 9 called forms (`forms/COMMON/lov_forms/`, `forms/SC/Support_Entry_fmb.xml`), launcher `forms/SC/APPS_fmb.xml`, DB packages `plsql/Shared/ACTIVITY_DB.*`, `HIJDATE_DB.*`.
- **Scope rule:** what is still not available is marked **MISSING SOURCE** and is not guessed: 7 libraries (OFGTEL, SEC_LIB, OFGTAB, PICKLIST, POS, SCDLL, VCDLL), the login form that sets the `P_*` parameters, and the DB packages other than ACTIVITY_DB / HIJDATE_DB (IMPR_CENTRAL, MCISERVICE, WEB_SERVICES_GAZT, IMPR, IMPR_UTILITIES, GNRL, STR_DB, DB_JOURNAL …).

