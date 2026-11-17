> **Trigger summary**
> - 323 triggers: Form 26, Block 18, Item 279. 158 contain code; 165 have no `TriggerText` in the XML (inherited from `CIC_OLB.olb` or deliberately empty) and are flagged **MISSING SOURCE / empty**.
> - `LSIDE`: 150 item triggers (WHEN-MOUSE-ENTER / WHEN-MOUSE-LEAVE / WHEN-MOUSE-CLICK × 50 side-menu buttons) — all empty in the XML → behaviour lives in the OLB/NIB library (**MISSING SOURCE**).
> - Many form-level triggers are one-line delegations to the `NIB` library (e.g. `NIB.ON_ERROR`, `NIB.PRE_FORM`, `NIB.WHEN_TIMER_EXPIRED`, KEY-* handlers). The called library code is **MISSING SOURCE**.
> - 59 KEY-LISTVAL item triggers: most open separate LOV *forms* via CALL_FORM and read the result back from :GLOBAL variables.
> - Large commented-out blocks (`/* ... */`, e.g. original WHEN-NEW-FORM-INSTANCE timer code) are kept verbatim below; line counts show total / active.

