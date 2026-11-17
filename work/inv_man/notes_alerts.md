> **Alert notes**
> - All 9 alerts are subclassed from `CIC_OLB.olb`; style/title/message/buttons are **MISSING SOURCE**.
> - No active `SHOW_ALERT` call exists in the form's own code (only in comments). Alerts are raised indirectly by the `STR.DispAlert(text, 'WARNING' | 'INFORMATION' | 'ERROR' | 'SYSTEM_ERROR' …)` library function (117 references) and `STR.DispArbMsg` (49 references), which presumably select the `CFG_*` / `USR_*` alert — **MISSING SOURCE**.
> - Message texts are hard-coded Arabic literals in the triggers (see §6), e.g. `'هل أنت متأكد من عملية الحذف'` in KEY-DELREC.

