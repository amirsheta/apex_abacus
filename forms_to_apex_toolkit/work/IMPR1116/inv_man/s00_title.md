# IMPR1116 – Inventory & Migration Risk Assessment

- **Form:** IMPR1116 – "شاشة استعراض بيانات رقم المنشأة 700 المدخلة من البوابة" (review of the establishment number 700 data entered through the portal)
- **Source:** `forms/IMPR/IMPR1116_fmb.xml` (frmf2xml output)
- **Target:** Oracle APEX 21.2 on Oracle Database 12.1.0.2, reference application f345 (CLAUDE.md §4b, §4c)
- **Produced:** 2026-11-24 (step 01, revision 1): mechanical sections by `scripts/gen_inv.py`; manual analysis in sections 1, 3–9 notes, 10.3, 10.6–10.8, 11–15 (sources in `work/IMPR1116/inv_man/`).
- **Sources used besides the form XML:** library texts in `forms/COMMON/libraries/` (`CIC_LIB` for NIB, STR, TMPLT, HIJDATE, ACTIVITY, KEY_CONTROL, REP), object library `forms/COMMON/olb/CIC_OLB_OLB.xml`, DB package `plsql/Shared/ACTIVITY_DB.*`. Every trigger and program unit was compared with IMPR1120 (`work/IMPR1116/tmp/diff_trg.py`): all form-level code, the frame PUs and the TOOLBAR / LSIDE / TITLE triggers are **identical** to IMPR1120 except the items listed in §6 notes, so the frame findings of the IMPR1110 / IMPR1120 inventories apply unchanged and are only summarised here.
- **Scope rule:** anything not available is marked **MISSING SOURCE** and is not guessed: libraries OFGTEL, SEC_LIB, OFGTAB, PICKLIST, POS, SCDLL, VCDLL; the DDL of table `IMPR_PRTL_NAT` and any DB trigger on it; the process that fills `IMPR_PRTL_NAT` from the portal.
