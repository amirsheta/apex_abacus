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
| `:GLOBAL.X` → application item | `G_<X>` (`FORMS_APX.global_item`) | `G_LAST_PAGE`, `G_UP_MAIN` |
| Menu parameter `:PARAMETER.P_X` | reuse the f345 item (`P_CURR_PORT_CD`, `P_CLASS_CD`, `P_PORT_TYPE`, `P_BRKR_NBR`, `SSO_APP_USER`, `V_USR_TYPE`); otherwise new `P_X` | |
| IG column | Forms item name | `MEMBER_ISN` |
| Report flag item (shows REPORT_SHOW/REPORT_PRINT) | `P<page>_REPORT` | — |
| Module item (kept on entry) | `P<page>_MODULE_ID` | `P11100_MODULE_ID` |

### Package members and parameters
| Member | Pattern | Example |
|---|---|---|
| Master-block trigger | `<TRIGGER>` with `_` for `-` | `AGR1100.PRE_INSERT`, `AGR1100.POST_UPDATE` |
| Detail-block trigger | `<BLOCK>_<TRIGGER>` | `AGR1100.AGRMNT_MEMBERS_PRE_INSERT`, `AGR1100.AGRMNT_ITEMS_PRE_DELETE` |
| Validation function (returns error text, NULL = OK) | `<ITEM>_VALIDATION` / `<BLOCK>_<ITEM>_VALIDATION` | `AGR1100.CTRY_CD_VALIDATION`, `AGR1100.MEMBERS_CTRY_CD_VALIDATION` (shortened: 33 bytes in full) |
| WHEN-VALIDATE-ITEM side effects (procedure) | `<ITEM>_WHEN_VALIDATE_ITEM` | `AGR1100.AGRMNT_NO_WHEN_VALIDATE_ITEM` |
| Error raiser | `FORMS_APX.CHECK_ERROR(ERROR_TEXT)` raises when `ERROR_TEXT` is not null (common helper, FORMS_APX 004; AGR1100 had its own copy) | `FORMS_APX.CHECK_ERROR(AGR1100.CTRY_CD_VALIDATION(...))` |
| Required check | `FORMS_APX.REQUIRED_VALIDATION(ITEM_VALUE, ITEM_LABEL)` ("يجب إدخال <label>") | |
| Form init / helpers | `INIT_FORM`, `P0_PAGE_PK_CHECK`, `INFO_SAVE`, `INFO_LOAD`, `ADJ_FUNS`, `EXEC_FUNS`; common ones in `FORMS_APX`: `HEADER_TITLE`, `GET_MODULE_ID`, `HIJRI_DATE_FORMAT`, `ROWID_FROM_URL` ... (CLAUDE.md §4a rule 3) | |
| Parameters | bind name without `:` and **without** an `I_` / `IO_` / `O_` prefix (the mode is IN / IN OUT / OUT). A page item `P<page>_X` is passed as `P_X` (`P_AGRMNT_NO => :P11100_AGRMNT_NO`); the page item of a Forms parameter `P<page>_P_X` as `P_X` too (no doubled `P_P_`; if the same member also receives the application item `P_X`, that parameter is `APP_P_X`); `P0_PAGE_PK` as `P_PAGE_PK`; application items and IG columns keep their name. Inside SQL a parameter is qualified with its member name (`PRE_DELETE.P_AGRMNT_NO`), because an unqualified name that matches a column resolves to the column. Rule and checks: `scripts/parameter_names.py` | `P_AGRMNT_NO => :P11100_AGRMNT_NO`, `MEMBER_ISN => :MEMBER_ISN`, `SSO_APP_USER => :SSO_APP_USER`, `P_PAGE_PK => :P0_PAGE_PK` |

`<BLOCK>` = the **full** block name. Names are never abbreviated (CLAUDE.md §4); only when a name
would exceed 30 bytes is it shortened (drop `WHEN_`, then shorten the block part), with the full
name in the member's comment. Example: `AGRMNT_MEMBERS_CTRY_CD_VALIDATION` (33 bytes) → `MEMBERS_CTRY_CD_VALIDATION`.
Every name stays ≤ 30 bytes (DB 12.1.0.2).

**Parameter names override f345.** The AGR1100 pages of f345 named parameters `I_` / `IO_` / `O_` + bind
(`IO_P11100_AGRMNT_NO`). By the project decision of 2026-11-23 the prefix is not used and page items are passed as
`P_<ITEM>` (table above). This rule wins over f345 (exception to the "f345 wins" rule at the top of this document).

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
| 20 | `P0_PAGE_PK CHECK` | `<FORM>.P0_PAGE_PK_CHECK(P_PAGE_PK => :P0_PAGE_PK);` |
| 40 | `PARAMETERS` | `:P<page>_MODULE_ID := FORMS_APX.GET_MODULE_ID(P_MODULE_ID => :P<page>_MODULE_ID, FORM_NAME => '<FORM>');` |
| 50 | `PARAMETERS ENTRY` | copy app items `P_<PARAM>` into `P<page>_P_<PARAM>`, when they are not null |
| 60 | `WHEN-NEW-FORM-INSTANCE` | `<FORM>.INIT_FORM(...)`, when `P<page>_P_<KEY>` is not null |
| 70 | `P0_PAGE_PK` | `:P<page>_<PK> := :P0_PAGE_PK;` |
| 80 | `Initialize form` | `NATIVE_FORM_INIT` on the master region |
| 90 | `PRE-FORM` | `<FORM>.PRE_FORM(...)` |
| 100 | `HEADER TITLE` | `FORMS_APX.HEADER_TITLE(P_MODULE_ID => :P<page>_MODULE_ID, P_HERO_TITLE => :P<page>_HERO_TITLE, DEFAULT_TITLE => '<form title>');` |

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
`PLUGIN_COM.FOS.EXECUTE_PLSQL_CODE` with `FORMS_APX.CHECK_ERROR(<FORM>.<BLOCK>_<COL>_VALIDATION(<COL> => :<COL>))`.

## 9. Declarative first: as little JavaScript as possible

Every Forms behaviour is built from native APEX components. JavaScript is the last resort.

| Forms | APEX 21.2 (in this order of preference) |
|---|---|
| WHEN-VALIDATE-ITEM / POST-CHANGE | Validation `<ITEM> VALIDATION` (server, at submit) **plus** DA `<ITEM> WHEN-VALIDATE-ITEM` on Change: action 1 *FOS - Execute PL/SQL Code* `FORMS_APX.CHECK_ERROR(<FORM>.<ITEM>_VALIDATION(P_<ITEM> => :P<page>_<ITEM>));` or, when the trigger derives values, `<FORM>.<ITEM>_WHEN_VALIDATE_ITEM(P_<ITEM> => :P<page>_<ITEM>, P_<ITEM2> => :P<page>_<ITEM2>);` |
| Values the trigger derives (names, codes) | FOS *Items to Return* (`p_attribute_03`) - no JavaScript |
| `Make_Field_Entrable` / `SET_ITEM_PROPERTY(ENABLED / UPDATEABLE)` decided by **stored data** | Item **Read Only** condition, *PL/SQL Expression* `<FORM>.<ITEM>_IS_READ_ONLY(P_<OTHER_ITEM> => :P<page>_<OTHER_ITEM>)` (BOOLEAN function) - evaluated by APEX at page render |
| Same, decided **while typing** | Native *Enable* / *Disable* actions in the item's DA, with a client-side condition. If the rule needs the database, FOS returns a flag item `P<page>_<ITEM>_READ_ONLY` (`Y` / `N`) and the condition is *Item = Value* |
| `SET_ITEM_PROPERTY(VISIBLE)` | Native *Show* / *Hide*, or a server-side condition on the item |
| `SET_ITEM_PROPERTY(REQUIRED)` | Validation `<ITEM> REQUIRED` with a server-side condition (`<FORM>.<ITEM>_IS_REQUIRED(...)`). No client-side "required" script |
| `GO_ITEM` | Native *Set Focus* |
| `SHOW_ALERT` stop / `MESSAGE` + `FORM_TRIGGER_FAILURE` | `FORMS_APX.CHECK_ERROR` / `FORMS_APX.FORM_TRIGGER_FAILURE` - FOS shows the error (`p_attribute_05 => '#SQLERRM#'`) |
| `SHOW_ALERT` caution (Yes / No) | Native *Confirm* action (fixed text, from a Text Message), then the server action. Only when the text is computed on the server: one line `apex.message.confirm($v('P<page>_CONFIRM_TEXT'), ...)` |
| `EXECUTE_QUERY` / re-query | Page submit with a request, or native *Refresh* |
| `CALL_FORM` | Modal page `<page>0n` + *Dialog Closed* DA (native Refresh / Submit) |

FOS action attributes, copied from f345 (AGR1100):
`p_attribute_01` = PL/SQL code (one line, named parameters) · `p_attribute_02` = Items to Submit ·
`p_attribute_03` = Items to Return · `p_attribute_05 => '#SQLERRM#'` ·
`p_attribute_15 => 'suppressChangeEvent:escape-message'` · `p_wait_for_result => 'Y'`.

Not allowed:
- a JavaScript file per form (no `<form>.js`, no `p_javascript_file_urls` on the page);
- AJAX callback processes or a home-made client "engine" that applies UI state (JSON of item properties);
- *Execute JavaScript Code* actions longer than **3 lines**. If more seems necessary, write down why in
  the page spec and ask before generating it.

## 10. Package organisation (one readable package per form)

One package `<FORM>` per form, owned by `LIB_APX_USR` (CLAUDE.md §3.2). No adapter packages, and no
"record of all items" copied to and from session state: each member takes **only the items it uses**,
as IN / IN OUT / OUT parameters named by §5, so APEX passes them as binds and a reader sees every input and output in
the signature.

Fixed section order (banner comment per section, the same in spec and body):

1. **VERSION** - the version block and `PKG_VERSION`.
2. **f345 HELPERS** - the form's own key check `P0_PAGE_PK_CHECK` (and other form-specific helpers). The common helpers (`CHECK_ERROR`, `REQUIRED_VALIDATION`, `GET_MODULE_ID`, `HEADER_TITLE`, Hijri date helpers ...) are in `FORMS_APX` 004, not in the form package.
3. **FORM LEVEL** - form triggers in Forms order (`PRE_FORM`, `WHEN_NEW_FORM_INSTANCE`, `PRE_COMMIT` ...).
4. **BLOCK `<BLOCK>`** - one section per block, in Forms block order, and inside it:
   query (`<BLOCK>_PRE_QUERY`, `<BLOCK>_POST_QUERY`) → record (`<BLOCK>_WHEN_CREATE_RECORD`,
   `<BLOCK>_WHEN_NEW_RECORD_INSTANCE`) → **items in Forms navigation order**, each with its
   `<ITEM>_POST_CHANGE`, `<ITEM>_VALIDATION` / `<ITEM>_WHEN_VALIDATE_ITEM`, `<ITEM>_IS_READ_ONLY`,
   `<ITEM>_IS_REQUIRED` → DML (`PRE_INSERT`, `POST_INSERT`, `PRE_UPDATE`, `POST_UPDATE`, `PRE_DELETE`,
   `POST_DELETE`) → buttons (`<BUTTON>_WHEN_BUTTON_PRESSED`).
5. **PROGRAM UNITS** - Forms program units, same names, Forms order.
6. **PRIVATE HELPERS** (body only, declared before use at the top of the body) - code that several
   triggers share, named by what it does.
7. **UI LOGIC FOR APEX DYNAMIC ACTIONS** (body end, comments only).

Rules:
- One Forms trigger = one member. A member longer than about **80 lines** is split into private helpers.
- Keep the original Forms code as a comment above each member (`-- Original Forms code:`).
- The package never builds UI state (no lists of item properties, no JSON for the page). UI rules are
  BOOLEAN functions (`<ITEM>_IS_READ_ONLY`, `<ITEM>_IS_REQUIRED`) that APEX conditions call.
- The package reads no session state (`v('P..')`); APEX passes values as binds. Exception: `:APP_USER`
  through `FORMS_APX.APP_USER` and globals through `FORMS_APX.GET_GLOBAL`.
- No COMMIT / ROLLBACK (APEX commits after page processing).
