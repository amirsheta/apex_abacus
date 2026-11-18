# f345 Reference Standard: templates and naming for generated APEX exports

Source of truth: `apex/Reference/f345.sql` (app 345 "Moayeen React", APEX 21.2.0, owner CUSTOMS).
The naming rules in §4–§6 come from the AGR1100 pages (11100 and 1110001). Those pages were
removed from the reference file on 2026-11-18 and are still in git history
(`git show HEAD~:forms_to_apex_toolkit/apex/Reference/f345.sql`, or the commit before the
removal). Where this document and `docs/apex_structure_standard.md` disagree, **this document wins**.

---

## 1. Target application

Every generated export is a **component export into the application built from f345**. It is
never a standalone application. The target already has:

| Already in f345, do NOT regenerate | Notes |
|---|---|
| Theme 42 Universal Theme, style **ZATCA Forms** (current) | RTL, `ar-sa`, Somar fonts |
| Global page 0: region `P0_ACTIONS` (toolbar), `ASK_DLG` (confirm dialog), items `P0_PAGE_PK`, `P0_REDIRECT`, `P0_SEARCH_PAGE`, `P0_SEARCH_URL`, `P0_LAT`, `P0_LONG` | Toolbar buttons live here, see §7 |
| Application items `SSO_APP_USER`, `P_CURR_PORT_CD`, `PORT_NAME`, `P_GLOBAL_PORT_TYPE`, `P_PORT_TYPE`, `P_CLASS_CD`, `P_BRKR_NBR`, `P_GLOBAL_V_WS_ID`, `V_USR_NAME`, `V_USR_TYPE`, `V_CLASS_CD`, `V_JOB_ID`, `SYS_ANAME`, `SYSOBJ_ID`, `G_LAST_PAGE`, … | Reuse them. Never create an `AI_` duplicate of an item that exists |
| App process `SCREEN ENTRY RESET` (before header) | On entry from another page it clears `P0_PAGE_PK` and every `P<page>_*` item except `P<page>_MODULE_ID` |
| Error handling function `APP_ERROR_HANDLER`, JWT authentication | |
| Plug-ins `COM.FOS.EXECUTE_PLSQL_CODE`, `MHO.REDIRECT`, `APEX.QR.CODE.SCANNER`, `APEXBCREADER`, `APEXBCREADERNEW`, `COM.APEXCONSULTING.APEX.JET.GAUGE` | Use FOS for server calls from dynamic actions |
| App-wide JS/CSS (`FTEX`, `KEYFUN`, `Hijri_init`, `zatca-profile`, `moyaeen-theme`, …) | Don't add page-level copies |

## 2. ID offset (required for template IDs to resolve)

The f345 template IDs below are written as `wwv_flow_api.id(<n>)`, and `wwv_flow_api.id` adds the
import offset. A component export only finds those templates if its `component_begin` uses the
**same offset as the installed target application**.

- f345 header offset: `p_default_id_offset => 64111868204433090374`. This is valid while the
  target app was installed from f345 with that offset.
- If the target app was installed with `generate_offset` or under another ID, get the offset:
  ```sql
  SELECT template_id - 11621850520475869674 AS id_offset
    FROM apex_application_temp_page
   WHERE application_id = :target_app_id
     AND template_name  = 'Standard';
  ```
- New component IDs: `wwv_flow_api.id(<page><seq>)`, which must not collide with f345 IDs
  (f345 uses 11-digit and 17–20-digit numbers starting `11621`, `11622`, `7305`, `7348`, `8144`, `8155`, `9224`).

## 3. Template IDs (theme 42, written as `wwv_flow_api.id(...)`)

### Page templates
| Use | Template | ID |
|---|---|---|
| Main form page (`p_step_template`, as AGR1100) | **Zatca-Minimal_No_Navigation** | 11622270914969205733 |
| Search page / modal child page (omit `p_step_template`: theme default for dialogs) | Modal Dialog | 11621830417925869664 |
| Other | Standard 11621850520475869674 (theme default) · Minimal (No Navigation) 11621847132324869672 · Left Side Column 11621835732265869668 · Right Side Column 11621839371311869669 · Left and Right 11621843108941869671 · Drawer 11621823527872869643 · Marquee 11621826432873869662 · Wizard Modal Dialog 11621834265435869667 · Login 11621831952809869666 | |

Every `create_page` sets `p_user_interface_id=>wwv_flow_api.id(11622010846008869795)` (f345 Desktop UI).

### Region templates
| Use (as in AGR1100) | Template | ID | Template options | Region CSS classes |
|---|---|---|---|---|
| Hero/header region (page title, KPIs) | Blank with Attributes | 11621859120066869682 | `#DEFAULT#` | `cg-hero` |
| Single-record block (Form region) | Interactive Report | 11621909206693869707 | `#DEFAULT#` | `zatca-forms cg-form cg-card` |
| Multi-record block (IG) | Standard | 11621913486616869708 | `#DEFAULT#:t-Region--noPadding` | `cg-card cg-grid` |
| Search criteria region (search page) | Blank with Attributes | 11621859120066869682 | `#DEFAULT#` | `zatca-forms cg-form` |
| Search results IG (search page) | Standard | 11621913486616869708 | `#DEFAULT#:t-Region--noPadding` | `cg-card cg-grid` |
| Popup / stacked canvas | Inline Dialog | 11621894586660869699 | `#DEFAULT#:js-dialog-size480x320` | |
| Other | Blank with Attributes (No Grid) 11621860514407869683 · Buttons Container 11621861869875869684 · Collapsible 11621877713143869692 · Tabs Container 11621923018393869712 · Title Bar 11621925599532869713 · Inline Drawer 11621899212247869702 · Inline Popup 11621903847785869704 · Content Block 11621887232019869696 · Hero 11621891386524869698 · Cards Container 11621866203823869686 · Alert 11621853938367869676 · Wizard Container 11621930375626869715 · Carousel 11621867814127869687 · Login 11621911061837869707 | | | |

### Item (label) templates
| Use | Template | ID |
|---|---|---|
| Required item | Required - Above | 11621984380233869750 |
| Optional item | Optional - Above | 11621983529556869749 |
| Other | Hidden 11621983266672869747 · Optional 11621983463590869749 · Optional - Floating 11621983660787869749 (theme default) · Required 11621983739878869749 · Required - Floating 11621984932922869750 | |

Item template options: `#DEFAULT#:t-Form-fieldContainer--stretchInputs`. Hidden items
(`NATIVE_HIDDEN`, `p_attribute_01=>'N'`) get no field template.

### Button, report, list templates
| Kind | Template | ID |
|---|---|---|
| Button (default) | Text | 11621986077967869752 |
| Button with icon (toolbar style) | Text with Icon (`#DEFAULT#:t-Button--iconLeft`) | 11621986167597869752 |
| Button icon only | Icon | 11621985435552869751 |
| Classic report (default) | Standard | 11621951142938869728 |
| Classic report, other | Value Attribute Pairs - Row 11621956104914869730 · Value Attribute Pairs - Column 11621954117869869729 · Cards 11621937111668869721 · Badge List 11621933085886869719 · Timeline 11621953704217869729 | |
| List | Links List 11621981748897869746 (default) · Menu Popup 11621981161575869745 · Moy Functions Nav 63163863023905992916 · Tabs 11621979469107869745 · Cards 11621974140215869742 | |
| Breadcrumb | Breadcrumb | 11621987677250869753 |
| Popup LOV | (theme) | 11621987928240869757 |

## 4. Page numbering and attributes

| Attribute | Main page | Search page |
|---|---|---|
| Page ID | from `MIG_FORM_REGISTRY` (AGR1100 → 11100) | **`<main page>01`** (11100 → 1110001). Required: `P0_SEARCH_URL` looks for `:APP_PAGE_ID \|\| '01'` |
| `p_name` | `<FORM>` (`AGR1100`) | `<FORM>_SEARCH` |
| `p_alias` | `<FORM>` | `<FORM>-SEARCH` |
| `p_step_title` | `&SYS_ANAME.` | `&SYS_ANAME.` |
| `p_page_mode` | (normal) | `MODAL`, `p_dialog_height=>'800'`, `p_dialog_width=>'1800'` |
| `p_page_css_classes` | `zf` | `zf` |
| `p_page_template_options` | `#DEFAULT#` | `#DEFAULT#` |
| `p_protection_level` | `C` | `C` |

Note: `SCREEN ENTRY RESET` keeps the open record only between the main page and its `01` page.
Any other child modal page (`<main page>02`…) clears `P0_PAGE_PK` when the user returns. Flag
this in import_notes.md whenever you generate such a page.

## 5. Naming

| Object | Pattern | AGR1100 example |
|---|---|---|
| Database package | **`<FORM>`** (upper case form name, no `pkg_` prefix) | `AGR1100` |
| Region `p_plug_name` | Forms block/canvas title (Arabic, written with `unistr`) | `unistr('\0623\0639\0636\0627\0621 ...')` |
| Region static ID `p_region_name` | Forms block name | `AGRMNT_MEMBERS`, `AGRMNT_ITEMS` |
| Search IG static ID | `<MASTER_TABLE>_SEARCH` | `AGRMNTS_SEARCH` |
| Page item | `P<page>_<FORMS_ITEM>` | `P11100_AGRMNT_NO` |
| Forms parameter → page item | `P<page>_P_<PARAM>` | `P11100_P_AGRMNT_NO` |
| Forms parameter passed between pages → application item | `P_<PARAM>` (no `AI_`) | `P_AGRMNT_NO`, `P_DISPLAY_ONLY` |
| `:GLOBAL.X` → application item | `G_<X>` (`pkg_forms_compat.global_item`) | `G_LAST_PAGE`, `G_UP_MAIN` |
| Menu parameter `:PARAMETER.P_X` | reuse the f345 item (`P_CURR_PORT_CD`, `P_CLASS_CD`, `P_PORT_TYPE`, `P_BRKR_NBR`, `SSO_APP_USER`, `V_USR_TYPE`); otherwise new `P_X` | |
| IG column | Forms item name | `MEMBER_ISN` |
| Report flag item (shows REPORT_SHOW/REPORT_PRINT) | `P<page>_REPORT` | — |
| Module item (kept on entry) | `P<page>_MODULE_ID` | `P11100_MODULE_ID` |

### Package members and parameters
| Member | Pattern | Example |
|---|---|---|
| Master-block trigger | `<TRIGGER>` with `_` for `-` | `AGR1100.PRE_INSERT`, `AGR1100.POST_UPDATE` |
| Detail-block trigger | `<BLOCK_ABBR>_<TRIGGER>` | `AGR1100.MEMBERS_PRE_INSERT`, `AGR1100.ITEMS_PRE_DELETE` |
| Validation function (returns error text, NULL = OK) | `<ITEM>_VAL` / `<BLOCK_ABBR>_<ITEM>_VAL` | `AGR1100.CTRY_CD_VAL`, `AGR1100.MEMBERS_CTRY_CD_VAL` |
| WHEN-VALIDATE-ITEM side effects (procedure) | `<ITEM>_WVI` | `AGR1100.AGRMNT_NO_WVI` |
| Error raiser | `<FORM>.CHK(p_err)` raises when `p_err` is not null | `AGR1100.CHK(AGR1100.CTRY_CD_VAL(...))` |
| Required check | `<FORM>.REQUIRED_VAL(p_value, p_label)` | |
| Form init / helpers | `INIT_FORM`, `P0_PAGE_PK_CHECK`, `HEADER_TITLE`, `GET_MODULE_ID`, `INFO_SAVE`, `INFO_LOAD`, `ADJ_FUNS`, `EXEC_FUNS` | |
| Parameters | `I_<bind name>` (IN), `IO_<bind name>` (IN OUT), `O_<bind name>` (OUT); bind name without `:` | `IO_P11100_AGRMNT_NO => :P11100_AGRMNT_NO`, `I_MEMBER_ISN => :MEMBER_ISN`, `I_SSO_APP_USER => :SSO_APP_USER` |

`<BLOCK_ABBR>` = the block name minus the form's common prefix (`AGRMNT_MEMBERS` → `MEMBERS`).
Every name stays ≤ 30 bytes (DB 12.1.0.2).

### Component names (Forms trigger notation, space-separated)
| Component | Pattern | Example |
|---|---|---|
| Process, master block | `<TRIGGER>` | `PRE-INSERT`, `WHEN-NEW-FORM-INSTANCE`, `PRE-FORM` |
| Process, detail block | `<BLOCK> <TRIGGER>` | `AGRMNT_MEMBERS PRE-UPDATE` |
| Native DML process | `Process form`, `Process form - DELETE`, `<BLOCK> - Save Interactive Grid Data`, `Initialize form` | |
| Helper process | what it does, upper case | `P0_PAGE_PK`, `P0_PAGE_PK CHECK`, `P0_PAGE_PK AFTER INSERT`, `HEADER TITLE`, `PARAMETERS`, `INFO_SAVE` |
| Validation (function returning error text) | `<ITEM> VALIDATION` / `<ITEM> REQUIRED` | `CTRY_CD VALIDATION`, `AGRMNT_DESC REQUIRED` |
| Dynamic action, page item | `<ITEM> WHEN-VALIDATE-ITEM` | `CTRY_CD WHEN-VALIDATE-ITEM` |
| Dynamic action, IG column | `<BLOCK> <COLUMN> WHEN-VALIDATE-ITEM` | `AGRMNT_MEMBERS CTRY_CD WHEN-VALIDATE-ITEM` |
| Other DA | `<ITEM> READ ONLY`, `<BLOCK> ITEM SELECTED`, `INFO SHOW` | |

## 6. Process skeleton (main page, in this order)

All PL/SQL is a one-line call into `<FORM>`. `p_error_display_location=>'INLINE_IN_NOTIFICATION'`.

**Before Header**
| Seq | Name | Body / type |
|---|---|---|
| 10 | `New` | session setup: `:SSO_APP_USER := GENERAL_UTILITY.ZATCA_SSO(:APP_USER);` plus port/user lookups (copy from AGR1100) |
| 20 | `P0_PAGE_PK CHECK` | `<FORM>.P0_PAGE_PK_CHECK(IO_P0_PAGE_PK => :P0_PAGE_PK);` |
| 40 | `PARAMETERS` | `:P<page>_MODULE_ID := <FORM>.GET_MODULE_ID(:P<page>_MODULE_ID);` |
| 50 | `PARAMETERS ENTRY` | copy app items `P_<PARAM>` into `P<page>_P_<PARAM>`, when they are not null |
| 60 | `WHEN-NEW-FORM-INSTANCE` | `<FORM>.INIT_FORM(...)`, when `P<page>_P_<KEY>` is not null |
| 70 | `P0_PAGE_PK` | `:P<page>_<PK> := :P0_PAGE_PK;` |
| 80 | `Initialize form` | `NATIVE_FORM_INIT` on the master region |
| 90 | `PRE-FORM` | `<FORM>.PRE_FORM(...)` |
| 100 | `HEADER TITLE` | `<FORM>.HEADER_TITLE(...)` |

**After Submit** (requests come from the page 0 toolbar: `CREATE`, `SAVE`, `DELETE`)
| Seq | Name | Condition |
|---|---|---|
| 10 | `PRE-INSERT` | `:P0_PAGE_PK is null and :REQUEST = 'CREATE'` |
| 20 | `PRE-UPDATE` | `:P0_PAGE_PK is not null and :REQUEST = 'SAVE'` |
| 30 | `PRE-DELETE` | button `DELETE` |
| 40 / 41 | `Process form` / `Process form - DELETE` | `NATIVE_FORM_DML`, `p_attribute_01=>'REGION_SOURCE'` |
| 50–70 | `POST-INSERT` / `POST-UPDATE` / `POST-DELETE` | same conditions as 10–30 |
| 80 / 85 | `P0_PAGE_PK AFTER INSERT` / `AFTER DELETE` | `:P0_PAGE_PK := :P<page>_<PK>;` / `:= null;` |
| 1xx, 2xx… | per detail block: `<BLOCK> PRE-INSERT/UPDATE/DELETE` → `<BLOCK> - Save Interactive Grid Data` (`NATIVE_IG_DML`) → `<BLOCK> POST-*` | `:APEX$ROW_STATUS = 'C' / 'U' / 'D'`; associate each with the IG region |

The master-key copy into detail rows is a process named `<BLOCK> MASTER KEYS`
(`:<FK> := :P<page>_<PK>;`, row status `C`).

## 7. Toolbar buttons (page 0, do not generate on form pages)

Page 0 region `P0_ACTIONS` holds the Forms toolbar for every page. All buttons use **Text with
Icon** (`11621986167597869752`) and `#DEFAULT#:t-Button--iconLeft`:

| Button | Action | Shown when |
|---|---|---|
| `CREATE` (fa-save) | submit `CREATE` | `P0_PAGE_PK` is null |
| `SAVE` (fa-pencil) | submit `SAVE` | `P0_PAGE_PK` is not null |
| `DELETE` (fa-trash-o) | DA: confirm, then submit `DELETE` | `P0_PAGE_PK` is not null |
| `SEARCH` (fa-search) | DA: open `P0_SEARCH_URL` (page `<page>01`) as a modal dialog | `P0_PAGE_PK` is null |
| `CLEAR` (fa-eraser) | redirect, clear cache 0 and the page | always |
| `FUNCS` (fa-th-large) | DA: `apex.theme.openRegion('FUNCS')` | page has **no** `P<page>_REPORT` item |
| `REPORT_SHOW` / `REPORT_PRINT` | trigger the `REPORT_SHOW` / `REPORT_PRINT` events on `document` | page **has** a `P<page>_REPORT` item |
| `BACK` (fa-arrow-right) | redirect to the home app | always |

A form page only has to: keep its record key in `P0_PAGE_PK`, define its `01` search page,
optionally create `P<page>_REPORT` and listen for the `REPORT_SHOW` / `REPORT_PRINT` custom events,
and provide a `FUNCS` inline-dialog region if it has functions. A page-specific button that has no
equivalent on page 0 gets the Text with Icon template, the same options, and a `cg-b-*` CSS class.

## 8. Interactive Grid defaults

`p_is_editable=>true` and `p_edit_operations=>'i:u:d'` for editable blocks; read-only blocks and
search grids use `p_is_editable=>false`. Always set `p_add_row_if_empty=>false`, `p_submit_checked_rows=>false`,
`p_lazy_loading=>false`, `p_toolbar_buttons=>'SEARCH_COLUMN:SEARCH_FIELD:ACTIONS_MENU:RESET'`,
and `p_enable_save_public_report=>false`. Server calls from IG column DAs use
`PLUGIN_COM.FOS.EXECUTE_PLSQL_CODE` with `<FORM>.CHK(<FORM>.<BLOCK_ABBR>_<COL>_VAL(I_<COL> => :<COL>))`.
