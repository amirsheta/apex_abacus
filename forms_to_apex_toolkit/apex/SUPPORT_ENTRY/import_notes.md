# SUPPORT_ENTRY – import notes (step 04, revision 1)

> ⚠️ **REVIEW BEFORE IMPORT.** Generated `wwv_flow_api` code is not an officially supported way to build APEX
> applications. Import into a **DEV** workspace first, back up application 202530, and inspect page 9001 in
> Page Designer after the import.

| Item | Value |
|---|---|
| Form | SUPPORT_ENTRY (`forms/SC/Support_Entry_fmb.xml`) – "بيانات المساندة الفنية" |
| Export (placeholders) | `apex/SUPPORT_ENTRY/f345_support_entry.sql` (620 lines) |
| Import-ready copy | `apex/SUPPORT_ENTRY/f202530_support_entry_import.sql` (workspace 23232323, app 202530, offset 460632461717563830, schema CUSTOMS) |
| Full application | `apex/f202530_full.sql`, rebuilt with IMPR1110 + IMPR1120 + SUPPORT_ENTRY (`scripts/build_full_app.py --app-id=202530 --shift-ids=460632461717563830 …`); only additions compared with the previous build |
| Generator | `scripts/gen_apex_support_entry.py` (deterministic ids `9001<kind><seq>`; re-run after a design change) |
| Design | `analysis/SUPPORT_ENTRY/SUPPORT_ENTRY_apex_page_spec.md` (rev 1 + step-04 corrections) |
| Package | `LIB_APX_USR.SUPPORT_ENTRY` **002** (`plsql/SUPPORT_ENTRY/`) – NOT COMPILED yet |
| Status | NOT IMPORTED |

## 1. Contents

| Component | Name | Count |
|---|---|---|
| Page | 9001 `SUPPORT_ENTRY` (Modal Dialog, width 720, protection C, page group SC) | 1 |
| Regions | `RP` (Blank with Attributes, `zatca-forms cg-form`), `RP_BUTTONS` (Buttons Container) | 2 |
| Items | `P9001_P_PORT_CD`, `P9001_P_PORT_NAME`, `P9001_SUPP_TITLE_CD`, `P9001_SUPP_TITLE_NM`, `P9001_LETTER_NBR`, `P9001_LETTER_DT`, hidden `P9001_P_MODE`, `P9001_P_CURR_PORT_CD`, `P9001_HIJRI_DATE_FORMAT` | 9 |
| Buttons | `AGREE` موافق / `AGREE_EDIT` تعديل / `CANCEL` تراجع / `CANCEL_EDIT` إغلاق (Defined by DA, condition `IS_NEW_LETTER`) | 4 |
| Computation | `P9001_HIJRI_DATE_FORMAT` = `FORMS_APX.HIJRI_DATE_FORMAT` | 1 |
| Processes | `WHEN-NEW-FORM-INSTANCE` (Before Header 60), `G_LAST_PAGE KEEP` (After Header 10) | 2 |
| Dynamic actions | `P_PORT_CD`, `SUPP_TITLE_CD`, `LETTER_DT WHEN-VALIDATE-ITEM`; `AGREE`, `CANCEL WHEN-BUTTON-PRESSED`; `Hide` | 6 events, 10 actions (7 FOS, 2 Close Dialog, 1 Hide) |
| Validations / After Submit processes | none – the page never submits (spec §0.2) | 0 |
| JavaScript actions | none | 0 |
| Shared | page group `SC`; application item `G_SUPPORT_ENTRY_CALLER`; LOVs `LOV_SD_PORTS_TYPES`, `LOV_SUPP_TITLES` | 4 |

Never generated: theme, templates, page 0, plug-ins, application processes, Authorization Schemes (CLAUDE.md §8).

## 2. Placeholders

| Token | Value for 202530 | How to get it |
|---|---|---|
| `__WORKSPACE_ID__` | 23232323 | `select workspace_id from apex_workspaces where workspace = '<NAME>';` |
| `__APP_ID__` | 202530 | the application installed from f345 |
| `__SCHEMA_NAME__` | CUSTOMS | parsing schema |
| `__ID_OFFSET__` | 460632461717563830 | `select template_id - 11621850520475869674 from apex_application_temp_page where application_id = 202530 and template_name = 'Standard';` |

Template ids (`wwv_flow_api.id(1162…)`) resolve only when the offset matches the installed application. Regenerate the
import-ready copy with
`python3 -I scripts/gen_apex_support_entry.py --workspace-id=… --app-id=… --id-offset=… --schema=…` if any value changes.

## 3. Prerequisites (in this order)

1. **Application 202530 contains the IMPR1110 export** (or the full file): it creates the application items
   `G_PORT_CD`, `G_SUPP_TITLE_CD`, `G_LETTER_NBR`, `G_LETTER_DT` that this page writes. This export does not create them
   (an application item that already exists would make the import fail).
2. `FORMS_APX` **004** compiled (`CHECK_ERROR`, `REQUIRED_VALIDATION`, `HIJRI_DATE_FORMAT`, `HIJRI_DATE_ERROR`,
   `GET_GLOBAL` / `SET_GLOBAL`) and the Application Setting `HIJRI_DATE_FORMAT` (from the IMPR1110 export).
3. Package `LIB_APX_USR.SUPPORT_ENTRY` **002** compiled: `@plsql/SUPPORT_ENTRY/support_entry_spec.sql`, then
   `@plsql/SUPPORT_ENTRY/support_entry_body.sql` (the spec file also creates the public synonym and the 4 EXECUTE grants).
4. Grants (DBA):
   ```sql
   GRANT SELECT ON <owner>.SD_PORTS     TO LIB_APX_USR;   -- package SUPPORT_ENTRY (definer rights)
   GRANT SELECT ON <owner>.SUPP_TITLES  TO LIB_APX_USR;
   -- the parsing schema CUSTOMS reads SD_PORTS, SUPP_TITLES, CG_REF_CODES in the two LOVs
   ```
5. The FOS plug-in `COM.FOS.EXECUTE_PLSQL_CODE` is in the application (f345).

## 4. Import

```
sql CUSTOMS@<tns> @apex/SUPPORT_ENTRY/f345_support_entry.sql     -- after replacing the 4 placeholders, or:
sql CUSTOMS@<tns> @apex/SUPPORT_ENTRY/f202530_support_entry_import.sql
```
or App Builder → Import → File Type **Page or Component Export** → `f202530_support_entry_import.sql`.

Page 9001 is removed first (`wwv_flow_api.remove_page`), so a re-import is safe for the page. The shared components
(page group SC, `G_SUPPORT_ENTRY_CALLER`, the two LOVs) keep their ids; a component with the same name but another id
makes the import fail – delete or rename it first.

Alternative: import the full `apex/f202530_full.sql` (replaces application 202530 completely).

## 5. Child modal page and `P0_PAGE_PK` (f345 SCREEN ENTRY RESET)

9001 is **not** `<caller>01`, so f345 SCREEN ENTRY RESET would clear `P0_PAGE_PK` and the URL items when it opens.
The protection (spec §0.2) has two halves and both must be present:

| Where | What | In this export |
|---|---|---|
| caller (IMPR1110 page 1110) | FOS `SUPPORT_ENTRY.OPEN_DIALOG(P_MODE => 0, P_CURR_PORT_CD => :P1110_PORT_CD, P_SUPPORT_URL => :P1110_SUPPORT_URL);` right before `apex.navigation.redirect($v('P1110_SUPPORT_URL'))` | **no – IMPR1110 export, its own session** (page spec §10.1) |
| page 9001 | After Header `G_LAST_PAGE KEEP`: `:G_LAST_PAGE := NVL(:G_SUPPORT_ENTRY_CALLER, :G_LAST_PAGE);` | yes |

**Until the IMPR1110 export is updated the dialog cannot be used from 1110**: `P1110_SUPPORT_URL` is still empty
there (TODO in IMPR1110). Test page 9001 on its own as in §7 step 3.

## 6. Uncertain parameters – verify after import

Used in this export but not present in f345 (name or effect unconfirmed for 21.2):

1. DA action `NATIVE_DIALOG_CLOSE` (Close Dialog) – AGREE and CANCEL. If the import rejects it, open each of the two DAs
   and set the second action to *Close Dialog* by hand.
2. DA triggering element type `JQUERY_SELECTOR` with `#AGREE,#AGREE_EDIT` and `#CANCEL,#CANCEL_EDIT` (buttons have
   `p_button_static_id`, which f345 uses).
3. `p_item_default => '1'` on the Hidden item `P9001_P_MODE` (used by IMPR1110 too).
4. `create_list_of_values_cols` also for the return / display column `D`, so the Popup LOV shows the code; check the
   column list of `LOV_SD_PORTS_TYPES` and `LOV_SUPP_TITLES`.

Omitted on purpose: Popup LOV *Manual Entry* (attribute not in f345 / IMPR1110): a code can only be picked from the list.

## 7. Post-import review and test

1. Page Designer 9001: no "invalid template" warnings; dialog title "بيانات المساندة الفنية"; RP region items in three rows.
2. Shared Components: LOVs `LOV_SD_PORTS_TYPES` (ports with port-type meaning) and `LOV_SUPP_TITLES` (active titles only).
3. Page 9001 alone (until IMPR1110 is updated): in SQL Workshop / a test page run
   `SUPPORT_ENTRY.OPEN_DIALOG(P_MODE => 0, P_CURR_PORT_CD => <port>, P_SUPPORT_URL => :X)` inside an APEX session, or open
   `f?p=202530:9001:<session>` from App Builder (P_MODE defaults to 1 = edit, empty letter).
   - mode 0: port prefilled and named, buttons موافق / تراجع; edit: تعديل / إغلاق with the values of the `G_` items;
   - AGREE with an empty item → "يجب إدخال …" (first missing item in the Forms order), dialog stays open;
   - unknown / typed date "1446-13-01" → date message; valid date → dialog closes, `G_LETTER_NBR` etc. set
     (Session → Application Items), `G_LETTER_DT` in `HIJRI_DATE_FORMAT`;
   - CANCEL in mode 0 → the four `G_` items are NULL; in edit mode they are kept;
   - the page 0 toolbar is not visible in the dialog;
   - `G_LAST_PAGE` after closing = the caller page.
4. After the IMPR1110 update: function F1 on 1110 with an importer open → dialog → AGREE → `EXEC_FUNS` continues; the
   importer stays open on 1110 (P0_PAGE_PK kept); CANCEL / X → nothing happens on 1110.
5. Run APEX Advisor on page 9001.
