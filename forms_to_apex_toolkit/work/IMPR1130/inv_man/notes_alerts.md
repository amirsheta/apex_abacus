> **Alert notes**
> - All 9 alerts come from `CIC_OLB.olb`; style, title and buttons are resolved from `forms/COMMON/olb/CIC_OLB_OLB.xml`. The message text is empty in the OLB (except `CFG_ASK_COMMIT`): `STR.DispAlert` sets it at runtime.
> - No active `SHOW_ALERT` call exists in the form's own code. Alerts are raised by `STR.DispAlert(text, type)` (60 active calls in 27 units) and `STR.DispArbMsg` (17 in 12 units); the type → alert mapping is in §10.8.
> - APEX mapping (f345 standard §9): ERROR / SYSTEM_ERROR → `CHECK_ERROR` / `FORMS_APX.FORM_TRIGGER_FAILURE`; INFORMATION → success message; CONFIRM / WARNING (Yes / No) → native Confirm action. Message texts are hard-coded Arabic literals in the triggers (see §6), e.g. `'هل أنت متأكد من عملية الحذف'` in KEY-DELREC.
