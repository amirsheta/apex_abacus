# SUPPORT_ENTRY — handoff from the IMPR1110 session

| Item | Value |
|---|---|
| Written | 2026-11-24, Claude Code, at the end of the IMPR1110 session (user decision: convert SUPPORT_ENTRY in its own session, CLAUDE.md §6.3) |
| Source | `forms/SC/Support_Entry_fmb.xml` (17 KB: block `RP`, 11 triggers, 2 LOVs, 4 parameters) |
| Start the new session with | `start step 1 for page support_entry` |
| Status | input for step 01; nothing of SUPPORT_ENTRY is converted yet |

This note is not the inventory. It records what the callers expect from the page, so that the converted page fits
IMPR1110, whose page design is already done (and the other callers later).

## 1. What the form is

A small modal dialog with **no table DML**: the user enters the support letter that authorises a change, and the
values go back to the caller through globals.

| Forms item | Prompt | Type / LOV | Required (AGREE button) |
|---|---|---|---|
| `RP.P_PORT_CD` (+ `P_PORT_NAME`) | جمــرك الخطاب | LOV `LOV_SD_PORTS` (SD_PORTS + CG_REF_CODES port type); WVI fills `P_PORT_NAME` | yes |
| `RP.SUPP_TITLE_CD` (+ `SUPP_TITLE_NM`) | جهــــة الخطاب | LOV `LOV_SUPP_TITLES` (`SUPP_TITLES WHERE TITLE_STATUS = 1`); WVI fills `SUPP_TITLE_NM` | yes |
| `RP.LETTER_NBR` | رقــــــم الخطاب | text, max 50 | yes |
| `RP.LETTER_DT` | تاريخ الخطاب | Datetime, mask `MI-MM-RRRR` (Hijri, day kept in the minutes: use `FORMS_APX.HIJRI_DATE_FORMAT` / the f345 Hijri picker as in IMPR1110) | yes |

Buttons: **AGREE** (checks the four items, sets the globals, closes when `P_MODE = 0`) and **CANCEL** (clears the
globals when `P_MODE = 0`, closes). `P_LOV_PORT` / `P_LOV_SUPP_TITLES` only open the LOVs (→ Popup LOV).
Parameters: `P_MODE` (0 = new letter, else edit the letter already in the globals; labels change: موافق / تراجع vs
تعديل / إغلاق), `P_CURR_PORT_CD` (default port), `WINDOW_X_POS` / `WINDOW_Y_POS` (window position → dropped).

## 2. Contract IMPR1110 expects (already built into IMPR1110 package 012 and its page design)

Caller: IMPR1110 functions **IMPR1110F1, F2, F3, F5** (PU `EXEC_FUNS`:
`CALL_FORM('SUPPORT_ENTRY.FMX', …)` with `P_MODE = 0`, `P_CURR_PORT_CD = :IMPORTERS.PORT_CD`).

| Direction | Forms | APEX (as IMPR1110 uses it) |
|---|---|---|
| in | `P_MODE = 0` | page item of the dialog, set in the URL |
| in | `P_CURR_PORT_CD = PORT_CD` of the importer | page item, default of the port item |
| out (AGREE) | `:GLOBAL.LETTER_NBR`, `SUPP_TITLE_CD`, `LETTER_DT`, `PORT_CD` (+ `PORT_NAME`, `SUPP_TITLE_NAME`) | application items `G_LETTER_NBR`, `G_SUPP_TITLE_CD`, `G_LETTER_DT`, `G_PORT_CD` (exist in IMPR1110's export; add `G_PORT_NAME`, `G_SUPP_TITLE_NAME` if the new design keeps them), set with `FORMS_APX.SET_GLOBAL`, then **Close Dialog** |
| out (CANCEL) | the same globals := NULL | `FORMS_APX.SET_GLOBAL(..., NULL)`, then Close Dialog (or Cancel Dialog) |

What IMPR1110 does with it:
- DA `IMPR1110F1/F2/F3/F5 EXECUTE-FUNCTION` sets `P1110_FUNCTION_PENDING`, then opens the dialog with
  `apex.navigation.redirect($v('P1110_SUPPORT_URL'))`.
- DA `SUPPORT_ENTRY DIALOG CLOSED` (event Dialog Closed) copies `P1110_FUNCTION_PENDING` into
  `P1110_FUNCTION_CODE`, which runs `IMPR1110.EXEC_FUNS`. That member continues **only when
  `G_LETTER_NBR` is not null** (as Forms: CANCEL clears it, so nothing happens).
- `IMPORTERS_PRE_UPDATE` calls `db_journal.journaling_on(G_PORT_CD, G_SUPP_TITLE_CD, G_LETTER_NBR, G_LETTER_DT)`
  when `G_LETTER_NBR` is set: `G_LETTER_DT` must stay in the text form the Forms global had (Hijri `MI-MM-RRRR`);
  check `DB_JOURNAL.JOURNALING_ON`'s parameter type in step 01.

## 3. Open in IMPR1110 until this page exists (come back to IMPR1110 after step 04 of SUPPORT_ENTRY)

| IMPR1110 TODO | To fill in |
|---|---|
| `P1110_SUPPORT_URL` (hidden item, spec §9 / `work/step03/spec_part5.md`) | computation `APEX_PAGE.GET_URL(p_page => <SUPPORT_ENTRY page>, p_items => '<P_MODE item>,<P_CURR_PORT_CD item>', p_values => '0,' \|\| :P1110_PORT_CD)` with checksum |
| registry row `CALLED_FORM SUPPORT_ENTRY` (status TODO) | page number |
| spec §12 branch row "functions IMPR1110F1 / F2 / F3 / F5" | page number |

## 4. Points for the SUPPORT_ENTRY design

1. **Shared page.** 63 form XMLs mention SUPPORT_ENTRY (all SC forms, IMPR1110 / 1116 / 1120 / 1125 / 1130 / 1140 /
   1150 / 1160 / 1170, several LOV forms, `CIC_OLB`). Give it its own page number from `MIG_FORM_REGISTRY` (SC
   subsystem), not a `1110xx` child number, and keep the contract of §2 generic: any caller passes `P_MODE` /
   `P_CURR_PORT_CD` and reads the `G_` items after Dialog Closed.
2. f345 standard for a child page: `G_LAST_PAGE KEEP` process (as page 111002 of IMPR1110), modal dialog template.
3. No DML → no Form region DML; a Static Content region with the four items, validations `<ITEM> REQUIRED` /
   `P_PORT_CD VALIDATION` / `SUPP_TITLE_CD VALIDATION`, processes `AGREE WHEN-BUTTON-PRESSED` /
   `CANCEL WHEN-BUTTON-PRESSED` + Close Dialog, package `SUPPORT_ENTRY` (CLAUDE.md §4).
4. Shared LOV `LOV_SD_PORTS` already exists (created by IMPR1110's export): reuse it if its query matches the
   SUPPORT_ENTRY record group (SD_PORTS + CG_REF_CODES port type), otherwise name the new one differently.
   `LOV_SUPP_TITLES` does not exist yet.
