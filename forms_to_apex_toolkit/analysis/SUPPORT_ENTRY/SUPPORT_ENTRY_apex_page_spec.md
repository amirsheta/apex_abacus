# SUPPORT_ENTRY – APEX 21.2 Page Specification (step 03, revision 1)

| Item | Value |
|---|---|
| Form | SUPPORT_ENTRY (`forms/SC/Support_Entry_fmb.xml`) – window "بيانات المساندة الفنية" |
| Inputs | `SUPPORT_ENTRY_inventory.md` (rev 2, decisions D1–D3), `SUPPORT_ENTRY_logic_extraction.md` (rev 1), `plsql/SUPPORT_ENTRY/support_entry_spec.sql` (package **002**, this step), `apex/Reference/f345.sql`, `docs/f345_reference_standard.md`, page 111002 of IMPR1110 (pattern of a modal child page) |
| Application | **202530** (installed from f345; workspace 23232323, ID offset 460632461717563830) |
| Page | **9001** `SUPPORT_ENTRY` (user decision 2026-11-24, D4: a 9xxx number for dialogs shared by several forms) |
| Page group | `SC` (new; f345 / 202530 have `Administration` and `IMPR`) |
| Access | application privileges (f345 login); no Authorization Scheme (CLAUDE.md §8) |
| Outputs | this file, `registry/SUPPORT_ENTRY_registry.sql`; step 04: `apex/SUPPORT_ENTRY/f345_support_entry.sql` (`scripts/gen_apex_support_entry.py`) |
| Status | Design. Package 002 not compiled; no export yet (step 04). |
| Date | 2026-11-24 – Claude Code |

---

## 0. Decisions that shape the page

1. **One control block → one modal dialog page with a Static Content region.** No table, no Form region, no
   `P0_PAGE_PK` of its own, no search page (`900101` is not created).
2. **Shared page and f345 SCREEN ENTRY RESET (D5, this step).** The f345 application process `SCREEN ENTRY RESET`
   (Before Header, every page) clears `P0_PAGE_PK` **and every item of the page** unless `G_LAST_PAGE` is the page
   itself or its `01` page (`l_base` = page, or page / 100 from 100000). Page 111002 escapes it because `1110 =
   trunc(111002 / 100)`; page 9001 opened from 1110 would not: the caller's record key and the URL values
   `P_MODE` / `P_CURR_PORT_CD` would be lost. Therefore:
   - **caller**, right before it opens the dialog, runs `SUPPORT_ENTRY.OPEN_DIALOG` (FOS): it keeps the caller page in
     the new application item `G_SUPPORT_ENTRY_CALLER`, sets `G_LAST_PAGE := 9001` and returns the dialog URL
     (`APEX_PAGE.GET_URL`, clear cache 9001, checksum). SCREEN ENTRY RESET then leaves 9001 alone;
   - **page 9001**, After Header process `G_LAST_PAGE KEEP` puts the caller back:
     `:G_LAST_PAGE := NVL(:G_SUPPORT_ENTRY_CALLER, :G_LAST_PAGE);` – from then on the caller is safe whichever
     way the dialog is closed (AGREE, CANCEL or the X);
   - **page 9001 never submits.** A submit with an error would re-render 9001 and run SCREEN ENTRY RESET again
     (`G_LAST_PAGE` is the caller by then) – the typed values would be lost. AGREE and CANCEL are dynamic actions
     (FOS call + native Close Dialog), the same pattern as `PB_CANCEL` of 111002. There are **no page
     validations**: the item checks run in `<ITEM> WHEN-VALIDATE-ITEM` DAs, and `AGREE_WHEN_BUTTON_PRESSED`
     repeats all of them before it sets the globals.
   Setting `G_LAST_PAGE := 9001` when the caller *renders* (computation) would be wrong: the caller's next render
   would reset the caller.
3. **Modes (D1).** `P9001_P_MODE` = 0 new letter (buttons موافق / تراجع), 1 edit the letter in the `G_` items
   (buttons تعديل / إغلاق). Two button pairs with server-side conditions `IS_NEW_LETTER` / `NOT IS_NEW_LETTER`
   (Forms changed the labels with `SET_ITEM_PROPERTY(LABEL)`). AGREE closes the dialog in **both** modes: the edit
   dialog is opened on demand, so the Forms "stay open after تعديل" has no use (D1).
4. **Contract with the callers.** Out: application items `G_PORT_CD`, `G_SUPP_TITLE_CD`, `G_LETTER_NBR`,
   `G_LETTER_DT` (exist since IMPR1110's export). The caller's DA on *Dialog Closed* reads `G_LETTER_NBR`
   (null = cancelled). `G_LETTER_DT` is text in `FORMS_APX.HIJRI_DATE_FORMAT`; callers pass
   `FORMS_APX.HIJRI_TEXT_TO_DATE(G_LETTER_DT)` to `DB_JOURNAL.JOURNALING_ON` (DATE parameter, D3).
   `G_PORT_NAME` / `G_SUPP_TITLE_NAME` are not created (inventory Q5, no reader).
5. **Dates.** `P9001_LETTER_DT` is a Text Field with the f345 class `hijri-date-default` (app-wide Hijri picker),
   format mask `&P9001_HIJRI_DATE_FORMAT.`, placeholder سنة-شهر-يوم – as IMPR1110 / IMPR1120.
6. **Page 0 toolbar inside the dialog.** f345 shows region `P0_ACTIONS` on every page except 100000, so SAVE /
   DELETE of the caller's record (P0_PAGE_PK is kept) would appear in the dialog. Page 9001 hides it with the f345
   pattern of AGR1100_SEARCH, as IMPR1110 page 111002: DA `Hide` (Page Load, native Hide of region `P0_ACTIONS`).
   (Step 04: replaces the inline CSS rule of revision 1; page 0 is not changed.)
7. **JavaScript actions on page 9001: 0.** The caller keeps its one-line `apex.navigation.redirect(...)`.

---

## 1. Page type decision per block

| Forms object | Characteristics (XML) | APEX 21.2 choice | f345 template / classes | Reasoning |
|---|---|---|---|---|
| Block `RP` | control block, 1 record, 4 entry items, 2 display items, 4 buttons | Static Content region `RP` on modal page 9001 | Blank with Attributes (`11621859120066869682`), `zatca-forms cg-form` (as 111002 `BLK`) | decision table "control block"; no DML |
| Window `RP_WINDOW` | dialog style, not modal, 4979 × 1271 | Modal Dialog page, 720 × auto | theme default for dialogs (Modal Dialog `11621830417925869664`) | modality came from CALL_FORM |
| Canvas `CANVAS1` | content canvas, 3 rows + buttons | the region's grid layout | – | |
| LOV buttons `P_LOV_PORT`, `P_LOV_SUPP_TITLES` | iconic, open the LOV | not created: the Popup LOV items have their own button | – | |

No hero region: a dialog has its title bar (Forms window title), as 111002.

## 2. Pages

| Page | Name / alias | Title | Mode | Page template | Source (Forms) | Forms menu role (documentation only) | Navigation menu |
|---|---|---|---|---|---|---|---|
| 9001 | `SUPPORT_ENTRY` / `SUPPORT_ENTRY` (alias = form name, standard §4) | بيانات المساندة الفنية | Modal Dialog, width 720, height auto; Cursor Focus *First item on page*; Warn on Unsaved Changes = No | theme default for dialogs | window `RP_WINDOW`, canvas `CANVAS1` | none (no menu entry; reached from IMPR1110 F1 / F2 / F3 / F5, later IMPR1130) | No |

Page attributes: CSS class `zf`, protection `C` (arguments must have a checksum),
page group `SC`, comment `Source: SUPPORT_ENTRY (shared dialog; contract §0.4)`.

## 3. Regions

| Seq | Region (Static ID) | Title | Type | Template / options / CSS classes | Position | Source Forms block |
|---|---|---|---|---|---|---|
| 10 | `RP` | بيانات المساندة الفنية (title hidden: template without header) | Static Content | Blank with Attributes (`11621859120066869682`), `#DEFAULT#`, `zatca-forms cg-form` | Body | `RP` |
| 20 | `RP_BUTTONS` | – | Static Content | Buttons Container (`11621861869875869684`), `#DEFAULT#` | Body (after `RP`) | `RP` buttons row (Y = 953) |

## 4. Items (page 9001)

Order = Forms navigation order of the entry items (the Forms buttons come first in RP's item list; in APEX they are in
`RP_BUTTONS`). Label template *Optional - Above* (`11621983529556869749`) for all entry items: Forms did not mark them
required, only AGREE checks them; template options `#DEFAULT#:t-Form-fieldContainer--stretchInputs`.

| Seq | Page item | Type | Label | Format mask | Default | LOV | Max length | Layout (row / col span) | Read only | SSP | Source Forms item | Notes |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 10 | `P9001_P_PORT_CD` | Popup LOV (Display As Dialog, Initial Fetch First rowset, as IMPR1110) | جمرك الخطاب | – | – (INIT_FORM) | `LOV_SD_PORTS_TYPES` | 23 | row 1, span 3 | – | Unrestricted | `RP.P_PORT_CD` | DA `P_PORT_CD WHEN-VALIDATE-ITEM` |
| 20 | `P9001_P_PORT_NAME` | Display Only (Save Session State = Yes, Based On Value) | – (no label: Forms has none) | – | – (INIT_FORM / DA) | – | 100 | row 1, span 9, same line | always | Unrestricted | `RP.P_PORT_NAME` | |
| 30 | `P9001_SUPP_TITLE_CD` | Popup LOV (as above) | جهة الخطاب | – | – (INIT_FORM) | `LOV_SUPP_TITLES` | 23 | row 2, span 3 | – | Unrestricted | `RP.SUPP_TITLE_CD` | DA `SUPP_TITLE_CD WHEN-VALIDATE-ITEM` |
| 40 | `P9001_SUPP_TITLE_NM` | Display Only (as above) | – | – | – | – | 40 | row 2, span 9, same line | always | Unrestricted | `RP.SUPP_TITLE_NM` | Forms item 30 long, RG column 40 (inventory R6) |
| 50 | `P9001_LETTER_NBR` | Text Field | رقم الخطاب | – | – (INIT_FORM) | – | 50 | row 3, span 6 | – | Unrestricted | `RP.LETTER_NBR` | |
| 60 | `P9001_LETTER_DT` | Text Field, CSS class `hijri-date-default`, placeholder سنة-شهر-يوم | تاريخ الخطاب | `&P9001_HIJRI_DATE_FORMAT.` | – (INIT_FORM) | – | 10 | row 3, span 6, same line | – | Unrestricted | `RP.LETTER_DT` | DA `LETTER_DT WHEN-VALIDATE-ITEM` |
| 70 | `P9001_P_MODE` | Hidden, Value Protected = Yes | – | – | Static `1` (Forms parameter default) | – | – | – | – | Checksum Required – Session Level | parameter `P_MODE` | set by the URL from `OPEN_DIALOG` |
| 80 | `P9001_P_CURR_PORT_CD` | Hidden, Value Protected = Yes | – | – | – | – | – | – | – | Checksum Required – Session Level | parameter `P_CURR_PORT_CD` | set by the URL; not the f345 application item of the same name |
| 90 | `P9001_HIJRI_DATE_FORMAT` | Hidden, Value Protected = Yes | – | – | – | – | – | – | – | Checksum Required – Session Level | – | computation §9 |

Popup LOVs: a code can only be taken from the list (*Manual Entry* is not set: the attribute is not in f345 / IMPR1110 and
its 21.2 name is not confirmed), so an unknown code cannot be entered; the WHEN-VALIDATE-ITEM DAs stay for the edit mode
(values loaded from the `G_` items) and as the Forms check. Labels drop the Forms ':' and the tatweel (جمــرك → جمرك). No `P9001_MODULE_ID` (no functions, no HEADER TITLE on a dialog,
as 111002). No `number_only` class: the codes are Popup LOVs (IMPR1110 rule: Popup LOVs get no class).

## 5. Buttons (region `RP_BUTTONS`)

Template *Text with Icon* (`11621986167597869752`), `#DEFAULT#:t-Button--iconLeft`, action **Defined by Dynamic Action**
(no submit, §0.2). Static ID = button name (used by the DA selectors).

| Seq | Button | Label | Position | Server-side condition (PL/SQL Expression) | Hot / icon | Source |
|---|---|---|---|---|---|---|
| 10 | `AGREE` | موافق | NEXT | `SUPPORT_ENTRY.IS_NEW_LETTER(P_MODE => :P9001_P_MODE)` | Hot, `fa-check` | `RP.AGREE` (label in mode 0) |
| 20 | `AGREE_EDIT` | تعديل | NEXT | `NOT SUPPORT_ENTRY.IS_NEW_LETTER(P_MODE => :P9001_P_MODE)` | Hot, `fa-pencil` | `RP.AGREE` (label in edit mode) |
| 30 | `CANCEL` | تراجع | PREVIOUS | `SUPPORT_ENTRY.IS_NEW_LETTER(P_MODE => :P9001_P_MODE)` | `fa-undo` | `RP.CANCEL` (mode 0) |
| 40 | `CANCEL_EDIT` | إغلاق | PREVIOUS | `NOT SUPPORT_ENTRY.IS_NEW_LETTER(P_MODE => :P9001_P_MODE)` | `fa-times` | `RP.CANCEL` (edit mode) |

UI-BTN-001 (shared button size) applies through the theme; no page-level sizing.

## 6. LOVs

**Type (CLAUDE.md §4d, 2026-11-24):** every SQL LOV below is a *PL/SQL Function Body returning SQL Query* that calls the common package `LOV_APX` (`plsql_templates/lov_apx.sql`); the SQL column is the query the function returns. `LOV_SD_PORTS_TYPES` → `PORTS_WITH_TYPES`; `LOV_SUPP_TITLES` → `SUPPORT_TITLES`.

| Forms LOV | APEX shared LOV | Type | SQL (display, return) | Used by | Item type | Notes |
|---|---|---|---|---|---|---|
| `LOV_SD_PORTS` (RG `LOV_SD_PORTS`) | **`LOV_SD_PORTS_TYPES`** (new, D2; IMPR1110's `LOV_SD_PORTS` has another query and stays) | SQL | `SELECT sd_ports.port_cd d, sd_ports.port_cd r, cg_ref_codes.rv_meaning, sd_ports.port_name FROM cg_ref_codes, sd_ports WHERE cg_ref_codes.rv_low_value = sd_ports.port_type AND cg_ref_codes.rv_domain = 'PORT_TYPE_CD' ORDER BY sd_ports.port_cd` | `P9001_P_PORT_CD` | Popup LOV | columns: رمز الجمرك (D), نوع الجمرك (RV_MEANING), اسم الجمرك (PORT_NAME); the name item is filled by the DA (Forms return item PORT_NAME → P_PORT_NAME) |
| `LOV_SUPP_TITLES` (RG `LOV_SUPP_TITLES`) | **`LOV_SUPP_TITLES`** (new) | SQL | `SELECT supp_title_cd d, supp_title_cd r, supp_title_nm FROM supp_titles WHERE title_status = 1` | `P9001_SUPP_TITLE_CD` | Popup LOV | columns: رمز معتمد الخطاب (D), معتمد الخطاب; name item by the DA |

Display = return = the code (as IMPR1110's LOVs): the Forms screen shows the code in the item and the name beside it.

## 7. Validations

None on page 9001 (§0.2: the page does not submit). Every Forms check is still enforced:

| Forms check | Where in APEX | Call |
|---|---|---|
| `P_PORT_CD` WVI (unknown port) | DA `P_PORT_CD WHEN-VALIDATE-ITEM` line 1, and inside `AGREE_WHEN_BUTTON_PRESSED` | `FORMS_APX.CHECK_ERROR(SUPPORT_ENTRY.P_PORT_CD_VALIDATION(P_PORT_CD => :P9001_P_PORT_CD));` |
| `SUPP_TITLE_CD` WVI | DA `SUPP_TITLE_CD WHEN-VALIDATE-ITEM` line 1, and inside AGREE | `FORMS_APX.CHECK_ERROR(SUPPORT_ENTRY.SUPP_TITLE_CD_VALIDATION(P_SUPP_TITLE_CD => :P9001_SUPP_TITLE_CD));` |
| `LETTER_DT` format mask | DA `LETTER_DT WHEN-VALIDATE-ITEM`, and inside AGREE | `FORMS_APX.CHECK_ERROR(SUPPORT_ENTRY.LETTER_DT_VALIDATION(P_LETTER_DT => :P9001_LETTER_DT));` |
| AGREE: four items required (Forms order, first missing stops) | inside `AGREE_WHEN_BUTTON_PRESSED` | `FORMS_APX.REQUIRED_VALIDATION` → "يجب إدخال جمرك الخطاب" … |

## 8. Processes (page 9001)

| Point | Seq | Process | Type | Code | Condition | Source |
|---|---|---|---|---|---|---|
| Before Header | 60 | `WHEN-NEW-FORM-INSTANCE` | PL/SQL | `SUPPORT_ENTRY.INIT_FORM(P_MODE => :P9001_P_MODE, P_CURR_PORT_CD => :P9001_P_CURR_PORT_CD, P_PORT_CD => :P9001_P_PORT_CD, P_PORT_NAME => :P9001_P_PORT_NAME, P_SUPP_TITLE_CD => :P9001_SUPP_TITLE_CD, P_SUPP_TITLE_NM => :P9001_SUPP_TITLE_NM, P_LETTER_NBR => :P9001_LETTER_NBR, P_LETTER_DT => :P9001_LETTER_DT);` | – | SUPPORT_ENTRY.WHEN-NEW-FORM-INSTANCE |
| After Header | 10 | `G_LAST_PAGE KEEP` | PL/SQL | `:G_LAST_PAGE := NVL(:G_SUPPORT_ENTRY_CALLER, :G_LAST_PAGE);` | – | f345 SCREEN ENTRY RESET (§0.2) |

`PRE-FORM` (window position) is not created (dropped). No After Submit processes (no submit).

## 9. Computations

| Item | Point | Type | Expression | Condition | Source |
|---|---|---|---|---|---|
| `P9001_HIJRI_DATE_FORMAT` | Before Header (seq 10, before WHEN-NEW-FORM-INSTANCE) | PL/SQL Expression | `FORMS_APX.HIJRI_DATE_FORMAT` | – | `RP.LETTER_DT` FormatMask `MI-MM-RRRR` (as IMPR1110 decision §0.5) |

## 10. Dynamic Actions (page 9001)

FOS = plug-in *FOS – Execute PL/SQL Code* (`COM.FOS.EXECUTE_PLSQL_CODE`) with `p_attribute_05 => '#SQLERRM#'`,
`p_wait_for_result => 'Y'`, `p_attribute_15 => 'suppressChangeEvent:escape-message'` (standard §9). An error raised by
the package (ORA-20001 via `FORMS_APX.CHECK_ERROR`) stops the DA and FOS shows the text – the Forms
`RAISE FORM_TRIGGER_FAILURE`.

| # | DA | Event | Selection | Seq | Action | Code / setting | Items to Submit | Items to Return | Fire on init | Source |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | `P_PORT_CD WHEN-VALIDATE-ITEM` | Change | Item `P9001_P_PORT_CD` | 10 | FOS | `FORMS_APX.CHECK_ERROR(SUPPORT_ENTRY.P_PORT_CD_VALIDATION(P_PORT_CD => :P9001_P_PORT_CD));` | `P9001_P_PORT_CD` | – | No | RP.P_PORT_CD.WHEN-VALIDATE-ITEM |
| | | | | 20 | FOS | `SUPPORT_ENTRY.P_PORT_CD_WHEN_VALIDATE_ITEM(P_PORT_CD => :P9001_P_PORT_CD, P_PORT_NAME => :P9001_P_PORT_NAME);` | `P9001_P_PORT_CD`, `P9001_P_PORT_NAME` | `P9001_P_PORT_NAME` | | (INTO :P_PORT_NAME) |
| 2 | `SUPP_TITLE_CD WHEN-VALIDATE-ITEM` | Change | Item `P9001_SUPP_TITLE_CD` | 10 | FOS | `FORMS_APX.CHECK_ERROR(SUPPORT_ENTRY.SUPP_TITLE_CD_VALIDATION(P_SUPP_TITLE_CD => :P9001_SUPP_TITLE_CD));` | `P9001_SUPP_TITLE_CD` | – | No | RP.SUPP_TITLE_CD.WHEN-VALIDATE-ITEM |
| | | | | 20 | FOS | `SUPPORT_ENTRY.SUPP_TITLE_CD_VALIDATE_ITEM(P_SUPP_TITLE_CD => :P9001_SUPP_TITLE_CD, P_SUPP_TITLE_NM => :P9001_SUPP_TITLE_NM);` | `P9001_SUPP_TITLE_CD`, `P9001_SUPP_TITLE_NM` | `P9001_SUPP_TITLE_NM` | | (INTO :SUPP_TITLE_NM) |
| 3 | `LETTER_DT WHEN-VALIDATE-ITEM` | Change | Item `P9001_LETTER_DT` | 10 | FOS | `FORMS_APX.CHECK_ERROR(SUPPORT_ENTRY.LETTER_DT_VALIDATION(P_LETTER_DT => :P9001_LETTER_DT));` | `P9001_LETTER_DT` | – | No | RP.LETTER_DT format mask (WVI empty) |
| 4 | `AGREE WHEN-BUTTON-PRESSED` | Click | jQuery Selector `#AGREE, #AGREE_EDIT` | 10 | FOS | `SUPPORT_ENTRY.AGREE_WHEN_BUTTON_PRESSED(P_PORT_CD => :P9001_P_PORT_CD, P_SUPP_TITLE_CD => :P9001_SUPP_TITLE_CD, P_LETTER_NBR => :P9001_LETTER_NBR, P_LETTER_DT => :P9001_LETTER_DT);` | `P9001_P_PORT_CD`, `P9001_SUPP_TITLE_CD`, `P9001_LETTER_NBR`, `P9001_LETTER_DT` | – | No | RP.AGREE.WHEN-BUTTON-PRESSED |
| | | | | 20 | Close Dialog (native `NATIVE_DIALOG_CLOSE`) | – | – | – | | EXIT_FORM(NO_VALIDATE) (D1: both modes) |
| 5 | `CANCEL WHEN-BUTTON-PRESSED` | Click | jQuery Selector `#CANCEL, #CANCEL_EDIT` | 10 | FOS | `SUPPORT_ENTRY.CANCEL_WHEN_BUTTON_PRESSED(P_MODE => :P9001_P_MODE);` | – (P_MODE from session state) | – | No | RP.CANCEL.WHEN-BUTTON-PRESSED |
| | | | | 20 | Close Dialog (native) | – | – | – | | EXIT_FORM(NO_VALIDATE) |

Close Dialog (not Cancel Dialog) on CANCEL too: the caller always gets *Dialog Closed*, as Forms always returned from
CALL_FORM, and then finds `G_LETTER_NBR` null. The dialog's X (no DA) gives the caller nothing: with the globals cleared
by INIT_FORM in mode 0, the outcome is the same as CANCEL.

| 6 | `Hide` | Page Load | – | 10 | Hide (native) | region `P0_ACTIONS` (page 0 toolbar) | – | – | Yes | f345 AGR1100_SEARCH / §0.6 |

**JavaScript actions on page 9001: 0.**

### 10.1 Caller side (contract; IMPR1110 is changed in its own session)

| Caller DA (IMPR1110 page 1110) | Today (IMPR1110 spec §10.2 #47–50) | Needed |
|---|---|---|
| `IMPR1110F1/F2/F3/F5 EXECUTE-FUNCTION` | 1 Set Value `P1110_FUNCTION_PENDING`; 2 JavaScript `apex.navigation.redirect($v('P1110_SUPPORT_URL'));` | insert between them: FOS `SUPPORT_ENTRY.OPEN_DIALOG(P_MODE => 0, P_CURR_PORT_CD => :P1110_PORT_CD, P_SUPPORT_URL => :P1110_SUPPORT_URL);` Items to Submit `P1110_PORT_CD`, Items to Return `P1110_SUPPORT_URL` |
| `SUPPORT_ENTRY DIALOG CLOSED` (#57) | Dialog Closed, "TODO: dialog = SUPPORT_ENTRY page" | unchanged; the dialog is page 9001 |
| `P1110_SUPPORT_URL` | hidden item, computation TODO | stays Hidden (Value Protected = **No**, it is returned by FOS); **no computation** (OPEN_DIALOG returns the URL) |
| `IMPORTERS_PRE_UPDATE` | `JOURNALING_ON(..., FORMS_APX.GET_GLOBAL('LETTER_DT'))` | `FORMS_APX.HIJRI_TEXT_TO_DATE(FORMS_APX.GET_GLOBAL('LETTER_DT'))` (D3) |

IMPR1130 (later): the same FOS with `P_MODE => 0` for the new-letter dialog; the edit dialog on demand with `P_MODE => 1` (D1).

## 11. Alerts and messages

| Forms alert | Usage | APEX equivalent |
|---|---|---|
| CG$ASK_COMMIT, CFG_ASK_COMMIT, CFG_SYSTEM_ERROR, CFG_ERROR, CFG_INFORMATION, CFG_WARNING_A, USR_WARNING_B, USR_WARNING_C, USR_CONFIRM, USR_CONFIRM_B | not used | none (no Text Messages) |
| silent `FORM_TRIGGER_FAILURE` (unknown code / required) | WVIs, AGREE | FOS error text from the package (§7; two new texts awaiting approval, extraction §5) |

## 12. Branches and navigation

| From | To | How | Items set | Source |
|---|---|---|---|---|
| caller (1110, later 1130) | 9001 | FOS `OPEN_DIALOG` returns the URL (`APEX_PAGE.GET_URL(p_page => 9001, p_clear_cache => '9001', p_items => 'P9001_P_MODE,P9001_P_CURR_PORT_CD', ...)`, checksum), then `apex.navigation.redirect` (caller's existing JS line) | `P9001_P_MODE`, `P9001_P_CURR_PORT_CD`; `G_LAST_PAGE`, `G_SUPPORT_ENTRY_CALLER` | `CALL_FORM('SUPPORT_ENTRY.FMX', NO_HIDE, NO_REPLACE, NO_QUERY_ONLY, PL_ID)` |
| 9001 | caller | native Close Dialog (AGREE / CANCEL) → caller DA *Dialog Closed* | `G_*` letter items | `EXIT_FORM(NO_VALIDATE)` |
| callers' toolbar `CLOSE_FORM('SUPPORT_ENTRY')` | – | dropped: the modal dialog cannot stay open beside the caller | – | CIC_OLB toolbar SAVE / CLEAR_ALL / EXIT / EXIT1 |

No page branches.

## 13. Shared components

### 13.1 Reused (do not create)

Theme 42 templates (§1–§5), FOS plug-in, f345 Hijri picker class `hijri-date-default`, application process `SCREEN ENTRY RESET`,
application items `G_LAST_PAGE` (f345), `G_PORT_CD`, `G_SUPP_TITLE_CD`, `G_LETTER_NBR`, `G_LETTER_DT` (IMPR1110 export,
present in `apex/f202530_full.sql`), Application Setting `HIJRI_DATE_FORMAT`.

### 13.2 New

| Component | Name | Details |
|---|---|---|
| Application item | `G_SUPPORT_ENTRY_CALLER` | Session State Protection Restricted (set only by `OPEN_DIALOG`); comment `Source: SUPPORT_ENTRY - caller page for G_LAST_PAGE KEEP (f345 SCREEN ENTRY RESET)` |
| Shared LOV | `LOV_SD_PORTS_TYPES` | §6 |
| Shared LOV | `LOV_SUPP_TITLES` | §6 |
| Page group | `SC` | |
| Page | 9001 `SUPPORT_ENTRY` | §2 |

Step 04 dependency: if this export is installed without IMPR1110's, it must create the four `G_` letter items
(create only if missing).

Grants: `LIB_APX_USR` SELECT on `SD_PORTS`, `SUPP_TITLES`; parsing schema `CUSTOMS` SELECT on `SD_PORTS`, `SUPP_TITLES`,
`CG_REF_CODES` (the two LOVs).

## 14. Traceability matrix

| # | Forms object | Type | APEX component | Page | Member | Status |
|---|---|---|---|---|---|---|
| 1 | SUPPORT_ENTRY | FORM | page 9001 `SUPPORT_ENTRY` (Modal Dialog) | 9001 | – | MAPPED |
| 2 | RP_WINDOW | WINDOW | page 9001 dialog (title بيانات المساندة الفنية) | 9001 | – | MAPPED |
| 3 | CANVAS1 | CANVAS | region `RP` layout | 9001 | – | MAPPED |
| 4 | RP | BLOCK | region `RP` (Static Content) + `RP_BUTTONS` | 9001 | – | MAPPED |
| 5 | RP.AGREE | ITEM (button) | buttons `AGREE` (موافق) / `AGREE_EDIT` (تعديل) | 9001 | `IS_NEW_LETTER` | MAPPED |
| 6 | RP.CANCEL | ITEM (button) | buttons `CANCEL` (تراجع) / `CANCEL_EDIT` (إغلاق) | 9001 | `IS_NEW_LETTER` | MAPPED |
| 7 | RP.P_PORT_CD | ITEM | `P9001_P_PORT_CD` (Popup LOV) | 9001 | – | MAPPED |
| 8 | RP.P_LOV_PORT | ITEM (button) | Popup LOV button of `P9001_P_PORT_CD` | 9001 | – | DROPPED |
| 9 | RP.P_PORT_NAME | ITEM | `P9001_P_PORT_NAME` (Display Only) | 9001 | – | MAPPED |
| 10 | RP.SUPP_TITLE_CD | ITEM | `P9001_SUPP_TITLE_CD` (Popup LOV) | 9001 | – | MAPPED |
| 11 | RP.P_LOV_SUPP_TITLES | ITEM (button) | Popup LOV button of `P9001_SUPP_TITLE_CD` | 9001 | – | DROPPED |
| 12 | RP.SUPP_TITLE_NM | ITEM | `P9001_SUPP_TITLE_NM` (Display Only) | 9001 | – | MAPPED |
| 13 | RP.LETTER_NBR | ITEM | `P9001_LETTER_NBR` (Text Field, 50) | 9001 | – | MAPPED |
| 14 | RP.LETTER_DT | ITEM | `P9001_LETTER_DT` (Hijri Text Field) + computation `P9001_HIJRI_DATE_FORMAT` | 9001 | – | MAPPED |
| 15 | SUPPORT_ENTRY.WHEN-NEW-FORM-INSTANCE | TRIGGER | process `WHEN-NEW-FORM-INSTANCE` + button conditions | 9001 | `INIT_FORM`, `IS_NEW_LETTER` | MAPPED |
| 16 | SUPPORT_ENTRY.PRE-FORM | TRIGGER | – (window position) | – | – | DROPPED |
| 17 | RP.AGREE.WHEN-BUTTON-PRESSED | TRIGGER | DA `AGREE WHEN-BUTTON-PRESSED` (FOS + Close Dialog) | 9001 | `AGREE_WHEN_BUTTON_PRESSED` | MAPPED |
| 18 | RP.CANCEL.WHEN-BUTTON-PRESSED | TRIGGER | DA `CANCEL WHEN-BUTTON-PRESSED` (FOS + Close Dialog) | 9001 | `CANCEL_WHEN_BUTTON_PRESSED` | MAPPED |
| 19 | RP.P_PORT_CD.WHEN-VALIDATE-ITEM | TRIGGER | DA `P_PORT_CD WHEN-VALIDATE-ITEM` | 9001 | `P_PORT_CD_VALIDATION`, `P_PORT_CD_WHEN_VALIDATE_ITEM` | MAPPED |
| 20 | RP.P_LOV_PORT.WHEN-BUTTON-PRESSED | TRIGGER | Popup LOV (commented CALL_FORM REP_LOV_SD_PORTS not converted) | 9001 | – | DROPPED |
| 21 | RP.SUPP_TITLE_CD.WHEN-VALIDATE-ITEM | TRIGGER | DA `SUPP_TITLE_CD WHEN-VALIDATE-ITEM` | 9001 | `SUPP_TITLE_CD_VALIDATION`, `SUPP_TITLE_CD_VALIDATE_ITEM` | MAPPED |
| 22 | RP.P_LOV_SUPP_TITLES.WHEN-BUTTON-PRESSED | TRIGGER | Popup LOV (commented CALL_FORM LOV_SUPP_TITLES not converted) | 9001 | – | DROPPED |
| 23 | RP.LETTER_DT.KEY-LISTVAL | TRIGGER | – (empty: no LOV on the date) | – | – | DROPPED |
| 24 | RP.LETTER_DT.KEY-F4 | TRIGGER | – (empty) | – | – | DROPPED |
| 25 | RP.LETTER_DT.WHEN-VALIDATE-ITEM | TRIGGER | – (empty); mask check → DA `LETTER_DT WHEN-VALIDATE-ITEM` | 9001 | `LETTER_DT_VALIDATION` | MAPPED |
| 26 | LOV_SD_PORTS | LOV | shared LOV `LOV_SD_PORTS_TYPES` | 9001 | – | MAPPED |
| 27 | LOV_SUPP_TITLES | LOV | shared LOV `LOV_SUPP_TITLES` | 9001 | – | MAPPED |
| 28 | LOV_SD_PORTS | RECORD_GROUP | query of `LOV_SD_PORTS_TYPES` | 9001 | – | MAPPED |
| 29 | LOV_SUPP_TITLES | RECORD_GROUP | query of `LOV_SUPP_TITLES` | 9001 | – | MAPPED |
| 30 | P_MODE | PARAMETER | `P9001_P_MODE` (Hidden, URL with checksum) | 9001 | `OPEN_DIALOG`, `IS_NEW_LETTER` | MAPPED |
| 31 | P_CURR_PORT_CD | PARAMETER | `P9001_P_CURR_PORT_CD` (Hidden, URL with checksum) | 9001 | `OPEN_DIALOG`, `INIT_FORM` | MAPPED |
| 32 | WINDOW_X_POS | PARAMETER | – | – | – | DROPPED |
| 33 | WINDOW_Y_POS | PARAMETER | – | – | – | DROPPED |
| 34 | :GLOBAL.PORT_CD | GLOBAL | application item `G_PORT_CD` | – | `AGREE_WHEN_BUTTON_PRESSED` | MAPPED |
| 35 | :GLOBAL.SUPP_TITLE_CD | GLOBAL | `G_SUPP_TITLE_CD` | – | idem | MAPPED |
| 36 | :GLOBAL.LETTER_NBR | GLOBAL | `G_LETTER_NBR` | – | idem | MAPPED |
| 37 | :GLOBAL.LETTER_DT | GLOBAL | `G_LETTER_DT` (Hijri text) | – | idem | MAPPED |
| 38 | :GLOBAL.PORT_NAME | GLOBAL | – (no reader, Q5) | – | – | DROPPED |
| 39 | :GLOBAL.SUPP_TITLE_NAME | GLOBAL | – (no reader, Q5) | – | – | DROPPED |
| 40–49 | CG$ASK_COMMIT, CFG_ASK_COMMIT, CFG_SYSTEM_ERROR, CFG_ERROR, CFG_INFORMATION, CFG_WARNING_A, USR_WARNING_B, USR_WARNING_C, USR_CONFIRM, USR_CONFIRM_B | ALERT | – (not used) | – | – | DROPPED |
| 50–55 | OFGTEL, OFGMES, OFGHPL, CIC_LIB, D2KWUTIL, CAPTION | LIBRARY | – (attached, not called) | – | – | DROPPED |
| 56 | caller IMPR1110 `CALL_FORM('SUPPORT_ENTRY.FMX')` | CALLER | IMPR1110 DAs F1/F2/F3/F5 + FOS `OPEN_DIALOG` (§10.1) | 1110 | `OPEN_DIALOG` | TODO (IMPR1110 session) |
| 57 | caller IMPR1130 `CALL_FORM` + `OPEN_FORM('SUPPORT_ENTRY.FMX')` | CALLER | the same, P_MODE 0 / 1 (D1) | 1130 | `OPEN_DIALOG` | TODO (IMPR1130 conversion) |
| 58 | CIC_OLB toolbar `CLOSE_FORM('SUPPORT_ENTRY')` | CALLER | – (modal dialog) | – | – | DROPPED |
| 59 | f345 SCREEN ENTRY RESET on a shared page | (new) | process `G_LAST_PAGE KEEP` + application item `G_SUPPORT_ENTRY_CALLER` | 9001 | `OPEN_DIALOG` | MAPPED |

## 15. Registry script

`registry/SUPPORT_ENTRY_registry.sql`: one `MIG_FORM_REGISTRY` row (page 9001, package `SUPPORT_ENTRY`, SIMPLE, DESIGN) and
one `MIG_OBJECT_MAP` row per matrix row (alerts and libraries one row each: 59 rows – MAPPED 29, DROPPED 28, TODO 2). Not executed (CLAUDE.md §6.10).

## 16. Changes made to step-02 code during this step, open items

| Change | Why |
|---|---|
| Package **002**: new `OPEN_DIALOG (P_MODE, P_CURR_PORT_CD, P_SUPPORT_URL OUT)`, constant `c_page_id = 9001`; spec comments for the no-submit page; previous version `rollback/SUPPORT_ENTRY/step03_v001/` | §0.2 |
| Extraction report §3 "Validation … " rows: replaced by the DAs of §10 (no page validations) | §0.2 |

Checks run on package 002: no Forms built-ins outside comments, identifiers ≤ 30 bytes, `parameter_names.py`
(`unqualified_in_sql`, `private_functions_in_sql`) and `forms_apx_helpers.py` (`leftovers`, `unknown_calls`) empty, spec and
body members in the same order.

| # | Open item | For |
|---|---|---|
| 1 | Compile package 002 on 12.1.0.2; grants (§13.2) | DBA |
| 2 | Approve the two new texts (`رمز الجمرك غير موجود`, `رمز جهة الخطاب غير موجود`) | business owner |
| 3 | IMPR1110 changes of §10.1 | IMPR1110 session |
| 4 | TODO-VERIFY at the first import: FOS shows the `CHECK_ERROR` text on the dialog; Display Only items updated by FOS *Items to Return*; the uncertain parameters of `apex/SUPPORT_ENTRY/import_notes.md` §6 | test |
| 5 | `G_PORT_NAME` / `G_SUPP_TITLE_NAME` left out (Q5) – confirm | user |
