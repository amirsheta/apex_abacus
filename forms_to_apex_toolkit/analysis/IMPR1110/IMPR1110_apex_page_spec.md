# IMPR1110 – APEX 21.2 Page Specification (step 03, revision 2)

| Item | Value |
|---|---|
| Form | IMPR1110 (module `IMPR1110_PROD_CENTRL`) – "إضافة وتعديل بيانات مستورد" |
| Inputs | `analysis/IMPR1110/IMPR1110_inventory.md` (rev 2), `analysis/IMPR1110/IMPR1110_logic_extraction.md` (rev 2), `plsql/IMPR1110/impr1110_spec.sql` (package `IMPR1110` 006), `apex/Reference/f345.sql`, `docs/f345_reference_standard.md` |
| Application | **202530** (installed from f345; workspace 23232323, ID offset 460632461717563830) |
| Pages | 1110 `IMPR1110`, 111001 `IMPR1110_SEARCH`, 111002 `IMPR1110_MOBILE` |
| Page group | `IMPR` |
| Access | application privileges (f345 login); no Authorization Scheme (CLAUDE.md §8) |
| Outputs | this file, `registry/IMPR1110_registry.sql` (v3.0), `work/step03/page_design.json` (the same design as data, for step 04) |
| Replaces | revision 1 (AJAX callbacks + `impr1110.js`, Static Content region, pages 1111–1113) → `rollback/IMPR1110/step03_rev1/` |
| Generated | §4, §7, §8, §9, §10 and §14 tables by `work/step03/build_spec.py` from the package spec; re-run after a package change |
| Status | Design. Package not compiled; no export yet (step 04). |
| Date | 2026-11-19 – Claude Code |

---

## 0. Decisions that shape the page

1. **One single-record block → native Form region.** `IMPORTERS` is the only data block (no relations, no
   tab canvas). Region `IMPORTERS` is a native **Form** region on table `IMPORTERS` with primary key
   **ROWID** (Forms key mode ROWID). "Initialize form" fetches the row and "Process form" inserts / updates
   it; the package runs the Forms triggers around them (`PRE-INSERT` … `POST-UPDATE`). Revision 1 used
   a Static Content region with package DML; that is no longer needed because every trigger now takes its
   items as named binds (IN / IN OUT parameters).
2. **Record key = ROWID in `P0_PAGE_PK`.** The search page and the after-insert process put the ROWID into
   `P0_PAGE_PK`; process `P0_PAGE_PK` copies it to `P1110_ROW_ID`. A ROWID key keeps working while the
   origin of IMPR_NBR on insert is still open (extraction report §7 #1; the column is nullable, "SEL INS NUL").
3. **Every process, validation and DA is one call into `IMPR1110` with named binds** (`P_X => :P1110_X`; packages 007 / 008: no `I_` / `IO_` / `O_` prefix, a page item `P<page>_X` is passed as `P_X`, application items keep their name).
   The parameter lists in this spec are generated from the package spec, so they match it exactly.
4. **Read-only rules (the answer to "why is an item read-only").** Three kinds, all from
   `work/step02/read_only_rules.md`:
   - *Always*: PORT_CD, ADD_CTRY_CD → Read Only = Always.
   - *Decided by stored data only*: BUS_ID_TYPE_CD, IMPR_EXPR_TYPE, EXPRESS_POST → item Read Only condition
     calling `IMPR1110.<ITEM>_IS_READ_ONLY`.
   - *Can change while the page is open* (item changes, function modes F1–F5 / SF6): 14 groups → a hidden flag
     `P1110_<GROUP>_LOCKED` (Y/N) and a DA `<GROUP> READ ONLY` (Disable when Y, else Enable, fire on
     initialization). The flags come from `IMPR1110.READ_ONLY_FLAGS`: process `READ ONLY FLAGS` on page
     load, and the last FOS action of every DA whose item moves the rules. A Read Only *condition* cannot be
     used for these: APEX renders such an item as text, and a later native Enable cannot turn it back
     into an input field.
   - *Required* rules that change at runtime → validations `<ITEM> REQUIRED` with the server-side condition
     `IMPR1110.<ITEM>_IS_REQUIRED(...)`.
5. **Dates.** BUS_ID_EXPRD_DT and BUS_ID_ISSUE_DT are Hijri dates stored as DATE with the Forms mask
   `MI-MM-YYYY` (decision §15 #10; the day is kept in the minutes because e.g. 30-02 is not a valid
   DATE). The items are Text Fields with the f345 class `hijri-date-default` (app-wide Hijri picker, no page
   JavaScript). Since package 010 (user request 2026-11-23) the format comes from one place: the APEX
   Application Setting `HIJRI_DATE_FORMAT` (default `YYYY-MM-MI`, the output of the f345 Hijri picker; the day
   stays in the minutes). Computation `P1110_HIJRI_DATE_FORMAT` (Before Header) = `FORMS_APX.HIJRI_DATE_FORMAT`,
   item format mask `&P1110_HIJRI_DATE_FORMAT.`, placeholder سنة-شهر-يوم. The package entry points take them as
   `VARCHAR2` and convert with the same function. Interface texts keep `MI-MM-YYYY` (the MCI data string,
   the values sent with the importer, the residence-expiry message): they are external formats.
6. **Declarative, minimal JavaScript.** No JavaScript file, no AJAX callback. 9 *Execute JavaScript Code*
   actions remain, each 1–3 lines, all of them for a question whose text is computed on the server, or for
   opening a dialog from a function (§10.3).
7. **Toolbar and functions from f345.** Page 0 supplies CREATE · SAVE · DELETE · SEARCH · CLEAR · FUNCS · BACK.
   The Forms side menu (LSIDE / TMPLT) becomes the f345 *Page Functions* list in the inline dialog `FUNCS`.
   The list reads `P1110_ADJ_FUNS`, the enabled codes computed by `IMPR1110.ADJ_FUNS`, and fires a custom
   event named after `SC_SYSTEM_OBJECTS.SYS_OS_FILE_NAME`. Page 1110 has one DA per function code.

---

## 1. Page type decision per block

| Forms block | Characteristics (XML) | APEX 21.2 choice | f345 template / classes | Reasoning |
|---|---|---|---|---|
| `IMPORTERS` | single record, base table IMPORTERS (`SEL INS UPD`, Delete Allowed = No), WHERE `PORT_CD = :PARAMETER.P_CURR_PORT_CD`, ORDER BY `IMPR_NBR DESC`, key mode ROWID | **Form region** `IMPORTERS` on page 1110 | Interactive Report (`11621909206693869707`), `zatca-forms cg-form cg-card` | decision table row 1; PK ROWID; delete only through KEY-DELREC (process, not native delete) |
| `IMPORTERS` Enter-Query / Execute-Query | TOOLBAR RE_ENTER_QUERY / ENTER / EXECUTE, PRE-QUERY | search page **111001**: criteria region + read-only IG | Blank with Attributes `zatca-forms cg-form` + Standard IG `cg-card cg-grid` | f345 `<page>01` page, found by page 0 SEARCH |
| `TITLE` (OLB) | screen title, user, date, version | hero region `IMPORTERS_HERO` | Blank with Attributes `cg-hero` | f345 HEADER TITLE |
| `TOOLBAR` (OLB) | Forms toolbar | page 0 `P0_ACTIONS` | – | not generated (f345) |
| `LSIDE` (OLB) | function side menu | inline dialog `FUNCS` with list *Page Functions* | Inline Dialog `11621894586660869699` | f345 |
| `EDI_MSG` (OLB) | EDI ticker | – (dropped, decision §15 #9) | – | APEX session timeout replaces the timers |
| called form `LOV_UPDATE_IMPR_MOBILE` | dialog of function IMPR1110_MOB | modal page **111002** | Modal Dialog page | f345 `<page>02` |
| called form `SUPPORT_ENTRY` | support-letter entry (functions F1, F2, F3, F5) | its own page, converted as a separate form (SC subsystem, decision §15 #12) | – | **TODO**: page number not known yet |

## 2. Pages

| Page | Name / alias | Title | Mode | Page template | Source (Forms) | Forms menu role (documentation only) | Navigation menu |
|---|---|---|---|---|---|---|---|
| 1110 | `IMPR1110` / `IMPR1110` | `&SYS_ANAME.` | Normal | Zatca-Minimal_No_Navigation (`11622270914969205733`), CSS class `zf`, protection C, Warn on Unsaved Changes = Yes | window `CGSO$WINDOW_1`, canvas `CG$PAGE_1` | module IMPR1110 in `CIC_MENU` (MISSING SOURCE) | entry under IMPR, same position as in the Forms menu (TODO when CIC_MENU is available) |
| 111001 | `IMPR1110_SEARCH` / `IMPR1110-SEARCH` | `&SYS_ANAME.` | Modal Dialog 1800 × 800, Cursor Focus *First item on page* (`P111001_SEARCH`) | theme default for dialogs | Enter-Query / Execute-Query of block IMPORTERS | as 1110 | No |
| 111002 | `IMPR1110_MOBILE` / `IMPR1110-MOBILE` | تعديل رقم الجوال | Modal Dialog 480 × 320 | theme default for dialogs | called form `LOV_UPDATE_IMPR_MOBILE` | function IMPR1110_MOB (Page Functions) | No |

Page 111002 needs process `G_LAST_PAGE KEEP` (After Header, `:G_LAST_PAGE := 1110;`). Without it, f345
SCREEN ENTRY RESET clears the open record when the user comes back to 1110 (standard §4). The SUPPORT_ENTRY
page will need the same process.

## 3. Regions

### Page 1110

| Seq | Region (Static ID) | Type | Source | Primary key | Template / options / CSS classes | Position | Edit | Source Forms block |
|---|---|---|---|---|---|---|---|---|
| 10 | `IMPORTERS_HERO` | Static Content | item `P1110_HERO_TITLE` | – | Blank with Attributes (`11621859120066869682`), `#DEFAULT#`, `cg-hero` | Body | – | `TITLE` |
| 20 | `IMPORTERS` – title "إضافة وتعديل بيانات مستورد" | **Form** | Table `IMPORTERS`, Where Clause `PORT_CD = :P_CURR_PORT_CD` (block WHERE clause) | **ROWID** → `P1110_ROW_ID` | Interactive Report (`11621909206693869707`), `#DEFAULT#`, `zatca-forms cg-form cg-card` | Body | Insert, Update (no native Delete: KEY-DELREC) | `IMPORTERS` |
| 30 | `FUNCS` | List, list *Page Functions* (f345) | – | – | Inline Dialog (`11621894586660869699`), `#DEFAULT#:js-dialog-size480x320`; list template as in AGR1100 (TODO-VERIFY, git history of f345) | Body | – | `LSIDE` |

The Form region's non-database items (names, statuses, flags) have Source = None. Their values come from
the Before Header processes and the FOS *Items to Return*.

### Page 111001 – IMPR1110_SEARCH

| Seq | Region | Type | Source | Template | Notes |
|---|---|---|---|---|---|
| 10 | `IMPORTERS_SEARCH_CRITERIA` | Static Content | one search text `P111001_SEARCH` (label بحث في كل الأعمدة), buttons `SEARCH` (Text with Icon, fa-search, Defined by DA: Refresh `IMPORTERS_SEARCH`) and `CLEAR` (Text with Icon, fa-eraser, class `cg-b-clear`, label مسح البحث, Defined by DA: Clear `P111001_SEARCH` + Refresh); DA `SEARCH KEY-ENTER` (Key Up of `P111001_SEARCH`, client condition `this.browserEvent.which === 13`: Refresh) | Blank with Attributes, `zatca-forms cg-form` | PRE-QUERY criteria as one text over all columns (user request 2026-11-23, as IMPR1120) |
| 20 | `IMPORTERS_SEARCH` | Interactive Grid, not editable | SQL below | Standard, `#DEFAULT#:t-Region--noPadding`, `cg-card cg-grid`; f345 IG defaults (standard §8) except: toolbar `ACTIONS_MENU:RESET` (no second search field), Lazy Loading on, no total row count | the one search text and the column filters = Forms query-by-example |

```sql
-- one search text over every shown column; no rows until a search is made, as Forms opens the block in
-- Enter-Query mode: the dialog opens without reading IMPORTERS. No sort clause: the whole result is not sorted
SELECT TRANSLATE(ROWIDTOCHAR(i.ROWID), '+/', '-_') AS row_id,   -- URL-safe: a '+' in f?p arrives as a space
       i.impr_nbr, i.arbc_impr_name, i.eng_impr_name, i.bus_id, i.bus_id_brnch,
       i.impr_type_cd || ' - ' || it.impr_type_name AS impr_type, i.hq_impr_nbr
  FROM importers i, impr_types it
 WHERE :P111001_SEARCH IS NOT NULL
   AND i.port_cd = :P_CURR_PORT_CD
   AND it.impr_type_cd (+) = i.impr_type_cd
   AND (NVL(:P1110_P_PRSNL_IMPR, 0) <> 1 OR i.impr_type_cd = 4)
   AND (INSTR(UPPER(i.impr_nbr || '|' || i.arbc_impr_name || '|' || i.eng_impr_name || '|' || i.bus_id || '|' ||
                    i.bus_id_brnch || '|' || i.impr_type_cd || ' - ' || it.impr_type_name || '|' || i.hq_impr_nbr),
              UPPER(TRIM(:P111001_SEARCH))) > 0
        OR i.impr_name_std LIKE '%' || (SELECT str_db.strformat(TRIM(:P111001_SEARCH), 1) FROM dual) || '%')
```

- Link column `IMPR_NBR`: Link Builder → page 1110, clear cache 1110, set `P0_PAGE_PK = &ROW_ID.`. `ROW_ID` is
  the ROWID made URL-safe (`+` → `-`, `/` → `_`): a `+` in an `f?p` value arrives as a space and the checksum
  fails (found on IMPR1120, 2026-11-23). `IMPR1110.P0_PAGE_PK_CHECK` (package 009) translates it back; a ROWID
  never contains `-` or `_`.
- `:P1110_P_PRSNL_IMPR` is read from session state: SCREEN ENTRY RESET keeps page 1110 items between 1110
  and its `01` page.
- **Opening is fast:** no rows while `P111001_SEARCH` is empty (Forms opens the block in Enter-Query mode), so the
  dialog opens without reading `IMPORTERS`; Lazy Loading, no total row count, no sort clause (block ORDER BY
  impr_nbr DESC dropped at the user's request; a grid column can still be sorted).
- **One search text** (contains, upper case) over every shown column; the Arabic name is also searched in
  `IMPR_NAME_STD` through `str_db.strformat(text, 1)` (PRE-QUERY `STR.StrFormat`). Forms QBE operators (`=`,
  `%`, `<` ...) are not supported in it; the column filters of the Actions menu remain for exact criteria.
- The `EXEC_QUERY_NOW` branch of PRE-QUERY (query by IMPR_NBR after IMPR_NBR WHEN-VALIDATE-ITEM) is process
  `EXECUTE-QUERY` of page 1110 (§8), not this page.

### Page 111002 – IMPR1110_MOBILE (LOV_UPDATE_IMPR_MOBILE)

| Seq | Region | Type | Items / buttons | Notes |
|---|---|---|---|---|
| 10 | `BLK` | Static Content, Blank with Attributes `zatca-forms cg-form` | `P111002_MOBILE_NO` (Text Field, subtype Phone, label رقم الجوال, Optional - Above), `P111002_IMPR_NBR` (Hidden, Value Protected, set by the URL with checksum), `P111002_CENTRAL_MOBILE` (Hidden) | `BLK.WHEN-NEW-BLOCK-INSTANCE`: MOBILE_NO := :PARAMETER.P_CENTRAL_MOBILE → computations §9 |
| 20 | `CTRL_BLK` | Buttons Container | `PB_OK` (Submit, request `PB_OK`), `PB_CANCEL` (Defined by DA) | process `PB_OK WHEN-BUTTON-PRESSED` → `IMPR1110.MOBILE_OK(P_MOBILE_NO => :P111002_MOBILE_NO);` then process *Close Dialog*; DA `PB_CANCEL WHEN-BUTTON-PRESSED`: FOS `IMPR1110.MOBILE_CANCEL;` then native *Cancel Dialog* |

---

## 4. Items (page 1110)

Columns *Type* … *Seq / layout* come from the XML through revision 1 (item order = Forms tab order; rows
and columns from the canvas X/Y, RTL). New in this revision: *Read only*, *Condition*, *Submitted*, and the
helper items at the end.

Rules:
- Label templates *Required - Above* / *Optional - Above*, options `#DEFAULT#:t-Form-fieldContainer--stretchInputs`.
- *Submitted = No (server value)*: Display Only items have Send On Page Submit = No. Their value lives in
  session state, written only by the server (Before Header processes, FOS *Items to Return*), and a
  stale browser value cannot overwrite it. These items are never listed in *Items to Submit*; the package
  receives them through binds from session state.
- Hidden items that FOS changes (flags, answers, function codes) have Value Protected = No. Otherwise the
  page submit fails the checksum.
- The 11 LOV buttons of the form (`…2`, `BUTT`, `BRNH_CITY_CD_LOV`) are not items: the Popup LOV / Select List
  has its own control.

| Page item | Source column | Type | Label (Forms prompt) | Required | Format mask | Default | LOV | Cascading parent(s) | Max length | Seq / layout | Read only | Condition | Submitted | Source Forms item | Notes |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `P1110_SDP_PORT_STATUS` | - | Display Only, CSS u-hidden (Send On Page Submit = No) | - | No | - | Static: 1 | - | - | 2 | 1010 / hidden | - | - | No (server value) | `IMPORTERS.SDP_PORT_STATUS (CGSO$NUMBER_MD)` | - |
| `P1110_L_CT_CITY_STATUS2` | - | Display Only, CSS u-hidden (Send On Page Submit = No) | - | No | - | - | - | - | 2 | 1020 / hidden | - | - | No (server value) | `IMPORTERS.L_CT_CITY_STATUS2 (CGSO$NUMBER_MD)` | - |
| `P1110_L_CT_CITY_STATUS` | - | Display Only, CSS u-hidden (Send On Page Submit = No) | - | No | - | - | - | - | 2 | 1030 / hidden | - | - | No (server value) | `IMPORTERS.L_CT_CITY_STATUS (CGSO$NUMBER_MD)` | - |
| `P1110_PORT_CD` | PORT_CD | Popup LOV (display = return value, manual entry) | رمز الجمــــــــــــــرك | Yes | - | - | LOV_SD_PORTS | - | 4 | 10 / row Yes / col 1 span 1 | Always (WHEN-NEW-FORM-INSTANCE (SET_ITEM_PROPERTY ENABLED FALSE)) | - | Yes | `IMPORTERS.PORT_CD (CGSO$CHAR_ARB)` | disabled by WHEN-NEW-FORM-INSTANCE |
| `P1110_PORT_NAME` | - | Display Only (Send On Page Submit = No) | - | No | - | - | - | - | 40 | 20 / row No / col 2 span 5 | - | - | No (server value) | `IMPORTERS.PORT_NAME (CGSO$CHAR_EN_DO_MLINE)` | - |
| `P1110_HQ_IMPR_NBR` | HQ_IMPR_NBR | Display Only (Send On Page Submit = No) | الرقم الموحد بالمصلحة | No | - | - | - | - | 11 | 30 / row No / col 10 span 1 | - | - | No (server value) | `IMPORTERS.HQ_IMPR_NBR (CGSO$CHAR_ARB_DO)` | - |
| `P1110_IMPR_NBR` | IMPR_NBR | Number Field | الرقــــــم الجمركــــى | No | - | - | - | - | 11 | 40 / row Yes / col 1 span 1 | - | - | Yes | `IMPORTERS.IMPR_NBR (CGSO$CHAR_ARB)` | - |
| `P1110_SUSPN_STATUS` | - | Display Only (Send On Page Submit = No) | حالة المستورد بالمصلحة | No | - | - | - | - | - | 50 / row No / col 5 span 2 | - | - | No (server value) | `IMPORTERS.SUSPN_STATUS (CGSO$CHAR_ARB)` | - |
| `P1110_STATUS_DESC` | - | Display Only (Send On Page Submit = No) | حالة المستورد بالوزارة | No | - | - | - | - | - | 60 / row No / col 9 span 2 | - | - | No (server value) | `IMPORTERS.STATUS_DESC (CGSO$CHAR_ARB_DO)` | - |
| `P1110_BUS_ID_STATUS` | BUS_ID_STATUS | Display Only, CSS u-hidden (Send On Page Submit = No) | - | No | - | - | - | - | 2 | 1040 / hidden | - | - | No (server value) | `IMPORTERS.BUS_ID_STATUS (CGSO$COMBO_DO)` | - |
| `P1110_IMPR_TYPE_CD` | IMPR_TYPE_CD | Popup LOV (display = return value, manual entry) | رمز النشاط التجارى | Yes | - | - | LOV_IMPR_TYPE | - | 4 | 70 / row Yes / col 1 span 1 | DA `IMPR_TYPE_CD READ ONLY` (flag `P1110_IMPR_TYPE_CD_LOCKED`) | - | Yes | `IMPORTERS.IMPR_TYPE_CD (CGSO$CHAR_ARB)` | LOV form LOV_Impr_Type (type part) |
| `P1110_IMPR_TYPE_NAME` | - | Display Only (Send On Page Submit = No) | - | No | - | - | - | - | 40 | 80 / row No / col 2 span 5 | - | - | No (server value) | `IMPORTERS.IMPR_TYPE_NAME (CGSO$CHAR_ARB_DO)` | - |
| `P1110_BUS_ID_EXPRD_DT` | BUS_ID_EXPRD_DT | Text Field, CSS class `hijri-date-default` (f345 Hijri picker) | إنـتهـاء الـنشاط | Validation `BUS_ID_EXPRD_DT REQUIRED` (`BUS_ID_EXPRD_DT_IS_REQUIRED`) | &P1110_HIJRI_DATE_FORMAT. | - | - | - | 10 | 90 / row No / col 9 span 2 | DA `BUS_ID_EXPRD_DT READ ONLY` (flag `P1110_BUS_ID_EXPRD_DT_LOCKED`) | - | Yes | `IMPORTERS.BUS_ID_EXPRD_DT (CGSO$HDATE_ARB)` | Hijri DATE, mask MI-MM-YYYY as in Forms (placeholder "يوم-شهر-سنة") |
| `P1110_BUS_ID_TYPE_CD` | BUS_ID_TYPE_CD | Select List | نوع الرقم الإستدلالي | Yes | - | - | LOV_IMPR_TYPE_BUS_ID | P1110_IMPR_TYPE_CD | 4 | 100 / row Yes / col 1 span 1 | PL/SQL Expression `IMPR1110.BUS_ID_TYPE_CD_IS_READ_ONLY(P_IMPR_NBR => :P1110_IMPR_NBR)` | - | Yes | `IMPORTERS.BUS_ID_TYPE_CD (CGSO$CHAR_ARB_DO)` | bus-id-type part of LOV_Impr_Type (Forms: display item + LOV button BUTT) |
| `P1110_BUS_ID_TYPE_NAME` | - | Display Only (Send On Page Submit = No) | - | No | - | - | - | - | 40 | 110 / row No / col 2 span 3 | - | - | No (server value) | `IMPORTERS.BUS_ID_TYPE_NAME (CGSO$CHAR_ARB_DO)` | - |
| `P1110_COMM_RGSTRTN_TYPE` | COMM_RGSTRTN_TYPE | Select List | نوع السجل التجاري | Validation `COMM_RGSTRTN_TYPE REQUIRED` (`COMM_RGSTRTN_TYPE_IS_REQUIRED`) | - | - | LOV_COMM_RGSTRTN_TYPE | - | 2 | 120 / row No / col 9 span 2 | DA `COMM_RGSTRTN_TYPE READ ONLY` (flag `P1110_COMM_RGSTRTN_TYPE_LOCKED`) | - | Yes | `IMPORTERS.COMM_RGSTRTN_TYPE (CGSO$CHAR_ARB)` | list item, CG_REF_CODES |
| `P1110_CITY_CODE_OF_ID` | CITY_CODE_OF_ID | Popup LOV (display = return value, manual entry) | مصدررقم الإستدلالي | Validation `CITY_CODE_OF_ID REQUIRED` (`CITY_CODE_OF_ID_IS_REQUIRED`) | - | - | LOV_CITIES_IMP_ID | P1110_IMPR_TYPE_CD, P1110_BUS_ID_TYPE_CD, P1110_CTRY_CD | 4 | 130 / row Yes / col 1 span 1 | DA `CITY_CODE_OF_ID READ ONLY` (flag `P1110_CITY_CODE_OF_ID_LOCKED`) | - | Yes | `IMPORTERS.CITY_CODE_OF_ID (CGSO$CHAR_ARB)` | LOV form LOV_CITIES_IMP |
| `P1110_ID_CITY_NAME` | - | Display Only (Send On Page Submit = No) | - | No | - | - | - | - | 20 | 140 / row No / col 2 span 3 | - | - | No (server value) | `IMPORTERS.ID_CITY_NAME (CGSO$CHAR_ARB_DO)` | - |
| `P1110_BUS_ID` | BUS_ID | Text Field | الـرقم الإستدلالي | Yes | - | - | - | - | 15 | 150 / row No / col 9 span 2 | DA `BUS_ID READ ONLY` (flag `P1110_BUS_ID_LOCKED`) | - | Yes | `IMPORTERS.BUS_ID (CGSO$CHAR_ARB)` | REQUIRED switched off by BUS_ID.WHEN-NEW-ITEM-INSTANCE |
| `P1110_BRNH_ID_MINS_COMM_CD` | - | Display Only, CSS u-hidden (Send On Page Submit = No) | - | No | - | - | - | - | - | 1050 / hidden | - | - | No (server value) | `IMPORTERS.BRNH_ID_MINS_COMM_CD (CGSO$CHAR)` | - |
| `P1110_BRNH_CITY_CD` | - | Popup LOV (display = return value, manual entry) | مصدر الرقم الفرعي | Validation `BRNH_CITY_CD REQUIRED` (`BRNH_CITY_CD_IS_REQUIRED`) | - | - | LOV_CITIES_IMP_BRNH | P1110_CTRY_CD | - | 160 / row Yes / col 1 span 1 | DA `BRNH_CITY_CD READ ONLY` (flag `P1110_BRNH_CITY_CD_LOCKED`) | - | Yes | `IMPORTERS.BRNH_CITY_CD (CGSO$CHAR_ARB_DO)` | LOV form LOV_CITIES_IMP |
| `P1110_BRNH_CITY_NAME` | - | Display Only (Send On Page Submit = No) | - | No | - | - | - | - | - | 170 / row No / col 2 span 3 | - | - | No (server value) | `IMPORTERS.BRNH_CITY_NAME (CGSO$CHAR_ARB_DO)` | - |
| `P1110_BUS_ID_BRNCH` | BUS_ID_BRNCH | Text Field | الـرقم الــفــرعي | Validation `BUS_ID_BRNCH REQUIRED` (`BUS_ID_BRNCH_IS_REQUIRED`) | - | - | - | - | 10 | 180 / row No / col 9 span 2 | DA `BUS_ID_BRNCH READ ONLY` (flag `P1110_BUS_ID_BRNCH_LOCKED`) | - | Yes | `IMPORTERS.BUS_ID_BRNCH (CGSO$CHAR_ARB_DO)` | - |
| `P1110_CTRY_CD` | CTRY_CD | Popup LOV (display = return value, manual entry) | دولة الرقم الإستدلالي | Yes | - | - | LOV_COUNTRIES_GULF | P1110_IMPR_TYPE_CD, P1110_BUS_ID_TYPE_CD | 4 | 190 / row Yes / col 1 span 1 | DA `CTRY_CD READ ONLY` (flag `P1110_CTRY_CD_LOCKED`) | - | Yes | `IMPORTERS.CTRY_CD (CGSO$CHAR_ARB)` | LOV_COUNTRIES or LOV_COUNTRIES_GULF |
| `P1110_CRTY_ARBC_NAME` | - | Display Only (Send On Page Submit = No) | - | No | - | - | - | - | 50 | 200 / row No / col 2 span 3 | - | - | No (server value) | `IMPORTERS.CRTY_ARBC_NAME (CGSO$CHAR_ARB_DO)` | - |
| `P1110_IMPR_EXPR_TYPE` | IMPR_EXPR_TYPE | Select List | النشاط الجمركي | Yes | - | Static: 2 | LOV_ALLOWED_EXPORT | - | - | 210 / row No / col 9 span 2 | PL/SQL Expression `IMPR1110.IMPR_EXPR_TYPE_IS_READ_ONLY(P_IMPR_NBR => :P1110_IMPR_NBR, P_CLASS_CD => :P_CLASS_CD, V_USR_TYPE => :V_USR_TYPE)` | - | Yes | `IMPORTERS.IMPR_EXPR_TYPE (CGSO$CHAR_ARB)` | list item, CG_REF_CODES |
| `P1110_CTRY_CTRY_STATUS` | - | Display Only, CSS u-hidden (Send On Page Submit = No) | - | No | - | Static: 1 | - | - | 2 | 1060 / hidden | - | - | No (server value) | `IMPORTERS.CTRY_CTRY_STATUS (CGSO$NUMBER_MD)` | - |
| `P1110_ID_MINS_COMM_CD` | - | Display Only, CSS u-hidden (Send On Page Submit = No) | - | No | - | - | - | - | 5 | 1070 / hidden | - | - | No (server value) | `IMPORTERS.ID_MINS_COMM_CD (CGSO$NUMBER_MD)` | - |
| `P1110_ITIDT_NOTE` | - | Display Only, CSS u-hidden (Send On Page Submit = No) | - | No | - | - | - | - | 200 | 1080 / hidden | - | - | No (server value) | `IMPORTERS.ITIDT_NOTE (CGSO$CHAR_MD)` | - |
| `P1110_ARBC_IMPR_NAME` | ARBC_IMPR_NAME | Text Field | الاســــم العربــــــــى | Yes | - | - | - | - | 200 | 220 / row Yes / col 1 span 10 | DA `ARBC_IMPR_NAME READ ONLY` (flag `P1110_ARBC_IMPR_NAME_LOCKED`) | - | Yes | `IMPORTERS.ARBC_IMPR_NAME (CGSO$CHAR_ARB)` | - |
| `P1110_IMPR_NAME_STD` | IMPR_NAME_STD | Display Only, CSS u-hidden (Send On Page Submit = No) | - | No | - | - | - | - | 200 | 1090 / hidden | - | - | No (server value) | `IMPORTERS.IMPR_NAME_STD (CGSO$CHAR_MD)` | - |
| `P1110_LST_TRAN_DT` | LST_TRAN_DT | Display Only, CSS u-hidden (Send On Page Submit = No) | - | No | YYYY/MM/DD HH24:MI:SS | - | - | - | - | 1100 / hidden | - | - | No (server value) | `IMPORTERS.LST_TRAN_DT (CGSO$DATE)` | - |
| `P1110_IMPD_STMT_NBR` | IMPD_STMT_NBR | Display Only, CSS u-hidden (Send On Page Submit = No) | - | No | - | - | - | - | 10 | 1110 / hidden | - | - | No (server value) | `IMPORTERS.IMPD_STMT_NBR (CGSO$NUMBER)` | - |
| `P1110_IMPR_DATA_SRCE` | IMPR_DATA_SRCE | Display Only, CSS u-hidden (Send On Page Submit = No) | - | No | - | - | - | - | 7 | 1120 / hidden | - | - | No (server value) | `IMPORTERS.IMPR_DATA_SRCE (CGSO$NUMBER)` | - |
| `P1110_ENG_IMPR_NAME` | ENG_IMPR_NAME | Text Field (dir=ltr) | الاســــم الأجنبـــــــي | No | - | - | - | - | 200 | 230 / row Yes / col 1 span 5 | - | - | Yes | `IMPORTERS.ENG_IMPR_NAME (CGSO$CHAR_EN)` | - |
| `P1110_IMPR_CNTCT_NAME` | IMPR_CNTCT_NAME | Text Field | الوكيل المفوض | No | - | - | - | - | 200 | 240 / row No / col 7 span 4 | - | - | Yes | `IMPORTERS.IMPR_CNTCT_NAME (CGSO$CHAR_ARB)` | - |
| `P1110_IMPR_ADDRESS` | IMPR_ADDRESS | Text Field | الــعـــــــنـــــــوان | No | - | - | - | - | 2000 | 250 / row Yes / col 1 span 6 | - | - | Yes | `IMPORTERS.IMPR_ADDRESS (CGSO$CHAR_ARB)` | - |
| `P1110_BUS_ID_ISSUE_DT` | BUS_ID_ISSUE_DT | Display Only (Send On Page Submit = No) | تاريخ انشاء النشاط | No | &P1110_HIJRI_DATE_FORMAT. | - | - | - | 10 | 260 / row No / col 9 span 2 | - | - | No (server value) | `IMPORTERS.BUS_ID_ISSUE_DT (CGSO$HDATE_ARB_DO)` | Hijri DATE, mask MI-MM-YYYY as in Forms (placeholder "يوم-شهر-سنة") |
| `P1110_STATUS` | - | Display Only, CSS u-hidden (Send On Page Submit = No) | - | No | - | Static: 1 | - | - | 2 | 1130 / hidden | - | - | No (server value) | `IMPORTERS.STATUS (CGSO$CHECK_BOX_MD)` | - |
| `P1110_IMPR_NBR_PARENT` | IMPR_NBR_PARENT | Popup LOV (display = return value, manual entry) | تابــع الـــــــــــــــــى | No | - | - | LOV_IMPR | - | 11 | 270 / row Yes / col 1 span 2 | - | - | Yes | `IMPORTERS.IMPR_NBR_PARENT (CGSO$CHAR_ARB)` | LOV form LOV_IMPR |
| `P1110_IMPR_NAME_PARENT` | - | Display Only (Send On Page Submit = No) | - | No | - | - | - | - | - | 280 / row No / col 3 span 3 | - | - | No (server value) | `IMPORTERS.IMPR_NAME_PARENT (CGSO$CHAR_ARB_DO)` | - |
| `P1110_WASL_CITY_NAME` | - | Display Only (Send On Page Submit = No) | المدينة | No | - | - | - | - | - | 290 / row No / col 9 span 3 | - | Server-side condition: `IMPR1110.WASL_CITY_IS_SHOWN(P_CURR_PORT_CD => :P_CURR_PORT_CD, P_WASL_CITY_NAME => :P1110_WASL_CITY_NAME)` | No (server value) | `IMPORTERS.WASL_CITY_NAME (CGSO$CHAR_ARB_DO)` | - |
| `P1110_ADD_CTRY_CD` | ADD_CTRY_CD | Popup LOV (display = return value, manual entry) | دولــــــــة الإقامـــــة | Yes | - | - | LOV_COUNTRIES | - | 4 | 300 / row Yes / col 1 span 1 | Always (value 100, disabled by the "CTRY 100" block) | - | Yes | `IMPORTERS.ADD_CTRY_CD (CGSO$CHAR_ARB)` | LOV form LOV_COUNTRIES |
| `P1110_ADD_CRTY_ARBC_NAME` | - | Display Only (Send On Page Submit = No) | - | No | - | - | - | - | 50 | 310 / row No / col 2 span 3 | - | - | No (server value) | `IMPORTERS.ADD_CRTY_ARBC_NAME (CGSO$CHAR_ARB_DO)` | - |
| `P1110_CITY_CODE` | CITY_CODE | Popup LOV (display = return value, manual entry) | المدينـة | No | - | - | LOV_CITIES | P1110_ADD_CTRY_CD | 4 | 320 / row No / col 7 span 1 | - | Server-side condition: NOT `IMPR1110.WASL_CITY_IS_SHOWN(P_CURR_PORT_CD => :P_CURR_PORT_CD, P_WASL_CITY_NAME => :P1110_WASL_CITY_NAME)` | Yes | `IMPORTERS.CITY_CODE (CGSO$CHAR_ARB)` | LOV form LOV_CITIES |
| `P1110_CITY_NAME` | - | Display Only (Send On Page Submit = No) | - | No | - | - | - | - | 20 | 330 / row No / col 8 span 3 | - | Server-side condition: NOT `IMPR1110.WASL_CITY_IS_SHOWN(P_CURR_PORT_CD => :P_CURR_PORT_CD, P_WASL_CITY_NAME => :P1110_WASL_CITY_NAME)` | No (server value) | `IMPORTERS.CITY_NAME (CGSO$CHAR_ARB_DO)` | - |
| `P1110_IMPR_POB_NBR` | IMPR_POB_NBR | Number Field | صنــــدوق بريــــــــد | No | - | - | - | - | 9 | 340 / row Yes / col 1 span 2 | DA `REGISTER_ITEMS READ ONLY` (flag `P1110_REGISTER_ITEMS_LOCKED`) | - | Yes | `IMPORTERS.IMPR_POB_NBR (CGSO$CHAR_ARB)` | - |
| `P1110_IMPR_ZIP_CD` | IMPR_ZIP_CD | Number Field | رمز بريدي | No | - | - | - | - | 11 | 350 / row No / col 4 span 2 | DA `REGISTER_ITEMS READ ONLY` (flag `P1110_REGISTER_ITEMS_LOCKED`) | - | Yes | `IMPORTERS.IMPR_ZIP_CD (CGSO$CHAR_ARB)` | - |
| `P1110_IMPR_TEL_NBR` | IMPR_TEL_NBR | Text Field | تليفـون | No | - | - | - | - | 15 | 360 / row No / col 7 span 2 | DA `IMPR_TEL_NBR READ ONLY` (flag `P1110_IMPR_TEL_NBR_LOCKED`) | - | Yes | `IMPORTERS.IMPR_TEL_NBR (CGSO$CHAR_ARB)` | - |
| `P1110_IMPR_FAX_NBR` | IMPR_FAX_NBR | Text Field | فاكــس | No | - | - | - | - | 15 | 370 / row No / col 10 span 2 | DA `REGISTER_ITEMS READ ONLY` (flag `P1110_REGISTER_ITEMS_LOCKED`) | - | Yes | `IMPORTERS.IMPR_FAX_NBR (CGSO$CHAR_ARB)` | - |
| `P1110_IMPR_TELEX_NBR` | IMPR_TELEX_NBR | Text Field | تلكـــــــــــــــــــــــس | No | - | - | - | - | 16 | 380 / row Yes / col 1 span 3 | DA `REGISTER_ITEMS READ ONLY` (flag `P1110_REGISTER_ITEMS_LOCKED`) | - | Yes | `IMPORTERS.IMPR_TELEX_NBR (CGSO$CHAR_ARB)` | - |
| `P1110_B_EMAIL` | - | Text Field (subtype E-Mail, dir=ltr) | بريــد إلكترونى | No | - | - | - | - | 200 | 390 / row No / col 6 span 6 | - | - | Yes | `IMPORTERS.B_EMAIL (CGSO$EMAIL)` | - |
| `P1110_EMAIL` | EMAIL | Display Only, CSS u-hidden (Send On Page Submit = No) | - | No | - | - | - | - | - | 1140 / hidden | - | - | No (server value) | `IMPORTERS.EMAIL (CGSO$EMAIL)` | - |
| `P1110_B_MOBILE_NO` | - | Text Field (subtype Phone) | رقم الجوال | No | - | - | - | - | 31 | 400 / row Yes / col 1 span 3 | - | - | Yes | `IMPORTERS.B_MOBILE_NO (CGSO$CHAR_EN)` | - |
| `P1110_MOBILE_NO` | MOBILE_NO | Display Only, CSS u-hidden (Send On Page Submit = No) | - | No | - | - | - | - | 31 | 1150 / hidden | - | - | No (server value) | `IMPORTERS.MOBILE_NO (CGSO$NUMBER)` | - |
| `P1110_BANK_IBAN` | BANK_IBAN | Text Field (dir=ltr, upper case) | رقم حسـاب آيبان | No | - | - | - | - | 60 | 410 / row No / col 6 span 6 | - | - | Yes | `IMPORTERS.BANK_IBAN (CGSO$CHAR)` | - |
| `P1110_B_ID_NBR` | - | Text Field | رقم هويه المستورد | No | - | - | - | - | 15 | 420 / row Yes / col 1 span 3 | DA `B_ID_NBR READ ONLY` (flag `P1110_B_ID_NBR_LOCKED`) | - | Yes | `IMPORTERS.B_ID_NBR (CGSO$CHAR)` | - |
| `P1110_ID_NBR` | ID_NBR | Display Only, CSS u-hidden (Send On Page Submit = No) | - | No | - | - | - | - | 15 | 1160 / hidden | - | - | No (server value) | `IMPORTERS.ID_NBR (CGSO$CHAR)` | - |
| `P1110_CAR_AGENT_FLAG` | CAR_AGENT_FLAG | Select List | وكيـــل سيـــارات؟ | No | - | Static: 0 | LOV_CAR_AGENT_FLAG | - | 2 | 430 / row No / col 6 span 3 | DA `CAR_AGENT_FLAG READ ONLY` (flag `P1110_CAR_AGENT_FLAG_LOCKED`) | - | Yes | `IMPORTERS.CAR_AGENT_FLAG (CGSO$POP_DO)` | pop list, static values |
| `P1110_EXPRESS_POST` | EXPRESS_POST | Select List | بريد سريع | No | - | Static: 0 | LOV_EXPRESS_POST | - | 1 | 440 / row No / col 10 span 1 | PL/SQL Expression `IMPR1110.EXPRESS_POST_IS_READ_ONLY(P_CLASS_CD => :P_CLASS_CD, V_USR_TYPE => :V_USR_TYPE)` | - | Yes | `IMPORTERS.EXPRESS_POST (CGSO$CHAR_ARB)` | list item, static values |
| `P1110_IMPR_ID_TYPE` | - | Display Only (Send On Page Submit = No) | نوع الاقامة | No | - | - | - | - | - | 450 / row Yes / col 1 span 6 | - | - | No (server value) | `IMPORTERS.IMPR_ID_TYPE (CGSO$CHAR_ARB_DO)` | - |
| `P1110_CTRY_CD_OF_ID` | CTRY_CD_OF_ID | Display Only, CSS u-hidden (Send On Page Submit = No) | - | No | - | Static: 100 | - | - | 4 | 1170 / hidden | - | - | No (server value) | `IMPORTERS.CTRY_CD_OF_ID (CGSO$NUMBER)` | - |
| `P1110_EXPD_STMT_NBR` | EXPD_STMT_NBR | Display Only, CSS u-hidden (Send On Page Submit = No) | - | No | - | - | - | - | 11 | 1180 / hidden | - | - | No (server value) | `IMPORTERS.EXPD_STMT_NBR (CGSO$NUMBER)` | - |
| `P1110_WVR_ENTRY_NBR` | WVR_ENTRY_NBR | Display Only, CSS u-hidden (Send On Page Submit = No) | - | No | - | - | - | - | 8 | 1190 / hidden | - | - | No (server value) | `IMPORTERS.WVR_ENTRY_NBR (CGSO$NUMBER)` | - |
| `P1110_ACTIVITY` | ACTIVITY | Textarea | نشاط المستورد | Validation `ACTIVITY REQUIRED` (`ACTIVITY_IS_REQUIRED`) | - | - | - | - | 1000 | 460 / row Yes / col 1 span 11 | DA `ACTIVITY READ ONLY` (flag `P1110_ACTIVITY_LOCKED`) | - | Yes | `IMPORTERS.ACTIVITY (CGSO$CHAR_ARB_MLINE)` | - |
| `P1110_CUSTOMS_ENTERED` | CUSTOMS_ENTERED | Display Only, CSS u-hidden (Send On Page Submit = No) | - | No | - | - | - | - | 2 | 1200 / hidden | - | - | No (server value) | `IMPORTERS.CUSTOMS_ENTERED (CGSO$NUMBER)` | Forms LOV CGDV$IMPORTERS_CUSTOMS_ENTERED not needed (item hidden) |
| `P1110_CREATION_FLAG` | CREATION_FLAG | Display Only, CSS u-hidden (Send On Page Submit = No) | - | No | - | Static: 1 | - | - | 4 | 1210 / hidden | - | - | No (server value) | `IMPORTERS.CREATION_FLAG (CGSO$NUMBER)` | Forms LOV CGDV$IMPORTERS_CREATION_FLAG not needed (item hidden) |
| `P1110_ROW_ID` | ROWID (primary key) | Hidden (Value Protected = Yes) | - | No | - | - | - | - | - | 1220 / hidden | - | - | No (server value) | - | Form region primary key, type ROWID (Forms key mode ROWID); = P0_PAGE_PK |
| `P1110_P_CODE` | - | Hidden (Value Protected = No) | - | No | - | - | - | - | - | hidden | - | - | No (server value) | - | :PARAMETER.CODE - function mode set by EXEC_FUNS; kept until SAVE / CLEAR / another record (extraction §7 #2) |
| `P1110_P_LETTER_NBR` | - | Hidden (Value Protected = Yes) | - | No | - | - | - | - | - | hidden | - | - | No (server value) | - | :PARAMETER.LETTER_NBR (PARAMETERS ENTRY, EXEC_FUNS) |
| `P1110_P_PRSNL_IMPR` | - | Hidden (Value Protected = Yes) | - | No | - | Static: 0 | - | - | - | hidden | - | - | No (server value) | - | :PARAMETER.PRSNL_IMPR (PARAMETERS ENTRY), default 0 |
| `P1110_MODULE_ID` | - | Hidden (Value Protected = Yes) | - | No | - | - | - | - | - | hidden | - | - | No (server value) | - | f345: SC_SYSTEM_OBJECTS id of the form; kept by SCREEN ENTRY RESET |
| `P1110_HIJRI_DATE_FORMAT` | - | Hidden (Value Protected = Yes) | - | No | - | - | - | - | - | hidden | - | - | No (server value) | - | Hijri date format (Application Setting HIJRI_DATE_FORMAT, default YYYY-MM-MI): format mask &P1110_HIJRI_DATE_FORMAT. of the Hijri date items |
| `P1110_HERO_TITLE` | - | Display Only (region IMPORTERS_HERO) | - | No | - | - | - | - | - | hidden | - | - | No (server value) | - | f345 HEADER TITLE |
| `P1110_FORM_OPEN` | - | Hidden (Value Protected = Yes) | - | No | - | - | - | - | - | hidden | - | - | No (server value) | - | Y after WHEN-NEW-FORM-INSTANCE ran (once per entry; SCREEN ENTRY RESET clears it) |
| `P1110_ADJ_FUNS` | - | Hidden (Value Protected = Yes) | - | No | - | - | - | - | - | hidden | - | - | No (server value) | - | f345 Page Functions filter (comma list of SYS_OS_FILE_NAME) |
| `P1110_MOBILE_URL` | - | Hidden (Value Protected = Yes) | - | No | - | - | - | - | - | hidden | - | - | No (server value) | - | URL of dialog page 111002 (function IMPR1110_MOB) |
| `P1110_FUNCTION_CODE` | - | Hidden (Value Protected = No) | - | No | - | - | - | - | - | hidden | - | - | Yes | - | function being executed (Set Value by the function DAs, drives DA EXEC_FUNS) |
| `P1110_FUNCTION_PENDING` | - | Hidden (Value Protected = No) | - | No | - | - | - | - | - | hidden | - | - | No (server value) | - | function waiting for the SUPPORT_ENTRY dialog (F1, F2, F3, F5) |
| `P1110_CONFIRM_TEXT` | - | Hidden (Value Protected = No) | - | No | - | - | - | - | - | hidden | - | - | Yes | - | question computed by a *_CONFIRM_TEXT function |
| `P1110_ANSWER` | - | Hidden (Value Protected = No) | - | No | - | - | - | - | - | hidden | - | - | Yes | - | answer of the last confirm: 1 = yes, 2 = no (Forms ALERT_BUTTON1 / 2) |
| `P1110_SUSPEND_ANSWER` | - | Hidden (Value Protected = No) | - | No | - | - | - | - | - | hidden | - | - | Yes | - | answer of the BUS_ID suspended-importer question |
| `P1110_IMPR_TYPE_CD_LOCKED` | - | Hidden (Value Protected = No) | - | No | - | - | - | - | - | hidden | - | - | No (server value) | - | read-only flag Y / N of IMPR_TYPE_CD |
| `P1110_BUS_ID_EXPRD_DT_LOCKED` | - | Hidden (Value Protected = No) | - | No | - | - | - | - | - | hidden | - | - | No (server value) | - | read-only flag Y / N of BUS_ID_EXPRD_DT |
| `P1110_COMM_RGSTRTN_TYPE_LOCKED` | - | Hidden (Value Protected = No) | - | No | - | - | - | - | - | hidden | - | - | No (server value) | - | read-only flag Y / N of COMM_RGSTRTN_TYPE |
| `P1110_CITY_CODE_OF_ID_LOCKED` | - | Hidden (Value Protected = No) | - | No | - | - | - | - | - | hidden | - | - | No (server value) | - | read-only flag Y / N of CITY_CODE_OF_ID |
| `P1110_BUS_ID_LOCKED` | - | Hidden (Value Protected = No) | - | No | - | - | - | - | - | hidden | - | - | No (server value) | - | read-only flag Y / N of BUS_ID |
| `P1110_BRNH_CITY_CD_LOCKED` | - | Hidden (Value Protected = No) | - | No | - | - | - | - | - | hidden | - | - | No (server value) | - | read-only flag Y / N of BRNH_CITY_CD |
| `P1110_BUS_ID_BRNCH_LOCKED` | - | Hidden (Value Protected = No) | - | No | - | - | - | - | - | hidden | - | - | No (server value) | - | read-only flag Y / N of BUS_ID_BRNCH |
| `P1110_CTRY_CD_LOCKED` | - | Hidden (Value Protected = No) | - | No | - | - | - | - | - | hidden | - | - | No (server value) | - | read-only flag Y / N of CTRY_CD |
| `P1110_ARBC_IMPR_NAME_LOCKED` | - | Hidden (Value Protected = No) | - | No | - | - | - | - | - | hidden | - | - | No (server value) | - | read-only flag Y / N of ARBC_IMPR_NAME |
| `P1110_REGISTER_ITEMS_LOCKED` | - | Hidden (Value Protected = No) | - | No | - | - | - | - | - | hidden | - | - | No (server value) | - | read-only flag Y / N of IMPR_POB_NBR, IMPR_ZIP_CD, IMPR_FAX_NBR, IMPR_TELEX_NBR |
| `P1110_IMPR_TEL_NBR_LOCKED` | - | Hidden (Value Protected = No) | - | No | - | - | - | - | - | hidden | - | - | No (server value) | - | read-only flag Y / N of IMPR_TEL_NBR |
| `P1110_ACTIVITY_LOCKED` | - | Hidden (Value Protected = No) | - | No | - | - | - | - | - | hidden | - | - | No (server value) | - | read-only flag Y / N of ACTIVITY |
| `P1110_B_ID_NBR_LOCKED` | - | Hidden (Value Protected = No) | - | No | - | - | - | - | - | hidden | - | - | No (server value) | - | read-only flag Y / N of B_ID_NBR |
| `P1110_CAR_AGENT_FLAG_LOCKED` | - | Hidden (Value Protected = No) | - | No | - | - | - | - | - | hidden | - | - | No (server value) | - | read-only flag Y / N of CAR_AGENT_FLAG |
| `P1110_BROKER_USER` | - | Hidden (Value Protected = Yes) | - | No | - | - | - | - | - | hidden | - | - | No (server value) | - | Y for brokers (class 1, type 3): client condition of DA PRE-INSERT CONFIRM |
| `P1110_PRE_INSERT_QUESTION` | - | Hidden (Value Protected = Yes) | - | No | - | - | - | - | - | hidden | - | - | No (server value) | - | text of the broker question (Text Message IMPR1110_PRE_INSERT_CONFIRM), read by DA PRE-INSERT CONFIRM |
| `P1110_SUPPORT_URL` | - | Hidden (Value Protected = Yes) | - | No | - | - | - | - | - | hidden | - | - | No (server value) | - | URL of the SUPPORT_ENTRY dialog (TODO: page of the separately converted form) |

---

## 5. Buttons

Page 1110 has **no buttons of its own**. Every Forms toolbar button maps to page 0 (§14):

| Forms | Page 0 (f345) | What happens on page 1110 |
|---|---|---|
| TOOLBAR.SAVE (COMMIT) on a new record | `CREATE` (P0_PAGE_PK null) | DA `PRE-INSERT CONFIRM` (brokers), validations, PRE-INSERT → Process form → POST-INSERT → `P0_PAGE_PK AFTER INSERT` |
| TOOLBAR.SAVE on a queried record | `SAVE` | validations, PRE-UPDATE → Process form → POST-UPDATE |
| TOOLBAR.REMOVE / KEY-DELREC | `DELETE` (confirm on page 0) | process `KEY-DELREC` → `P0_PAGE_PK AFTER DELETE` |
| TOOLBAR.RE_ENTER_QUERY / ENTER / EXECUTE | `SEARCH` → page 111001 | – |
| KEY-CLRFRM / TOOLBAR.CLEAR | `CLEAR` (redirect, clear cache) | – (WHEN-CLEAR-BLOCK only sets `:GLOBAL.STAT_CLR`, which no code reads) |
| KEY-F9 / TOOLBAR.FUN_BUT | `FUNCS` → region `FUNCS` | DAs `<CODE> EXECUTE-FUNCTION` (§10.3) |
| TOOLBAR.EXIT | `BACK` | – |

Page 111002 buttons: §3.

## 6. LOVs

Built from the LOV forms' block query (`forms/COMMON/lov_forms/*.xml`) with the parameters IMPR1110 passes,
as in revision 1. Binds now use the f345 items. Popup LOVs show the code in the field (Display = return
value, as in Forms); the name is shown by the separate display item, which the item's WHEN-VALIDATE-ITEM
DA fills (FOS *Items to Return*). No Popup LOV "additional outputs" are needed.

| Forms LOV | APEX LOV (Shared Component) | Type | SQL (display, return, …) | Used by | Item type | Cascading parent(s) | Notes |
|---|---|---|---|---|---|---|---|
| `LOV_SD_PORTS` (form) / `CGFK$IMPORTERS_PORT_CD` | `LOV_SD_PORTS` | SQL | `SELECT port_cd d, port_cd r, port_name FROM sd_ports WHERE port_status = 1 AND port_type = NVL(:P_PORT_TYPE, port_type) ORDER BY port_cd` | P1110_PORT_CD | Popup LOV | – | item is always read-only |
| `LOV_Impr_Type` (form), type part / `CGFK$IMPORTERS_IMPR_TYPE_CD` | `LOV_IMPR_TYPE` | SQL | `SELECT DISTINCT itidt.impr_type_cd d, itidt.impr_type_cd r, it.impr_type_name FROM impr_type_id_types itidt, impr_types it WHERE it.impr_type_cd = itidt.impr_type_cd AND itidt.impr_type_cd > 0 AND (:G_CHK_IMP_TYP = '1' OR itidt.status = 1) ORDER BY 2` | P1110_IMPR_TYPE_CD | Popup LOV | – | |
| `LOV_Impr_Type` (form), bus-id-type part | `LOV_IMPR_TYPE_BUS_ID` | SQL | `SELECT bit.bus_id_type_name d, itidt.bus_id_type_cd r FROM impr_type_id_types itidt, bus_id_types bit WHERE bit.bus_id_type_cd = itidt.bus_id_type_cd AND itidt.impr_type_cd = :P1110_IMPR_TYPE_CD AND itidt.impr_type_cd > 0 AND (:G_CHK_IMP_TYP = '1' OR itidt.status = 1) ORDER BY itidt.bus_id_type_cd` | P1110_BUS_ID_TYPE_CD | Select List | P1110_IMPR_TYPE_CD | the LOV form returns the pair; APEX: type, then bus-id type |
| `LOV_CITIES_IMP` (form) for CITY_CODE_OF_ID / `CGFK$IMPORTERS_CITY_CODE_OF_ID` | `LOV_CITIES_IMP_ID` | SQL | `SELECT city_cd d, city_cd r, city_arb_name, mins_comm_cd FROM cities WHERE city_status = 1 AND ctry_cd = NVL(CASE WHEN :P1110_IMPR_TYPE_CD = 3 AND :P1110_BUS_ID_TYPE_CD = 2 THEN 100 ELSE TO_NUMBER(:P1110_CTRY_CD) END, ctry_cd) ORDER BY ctry_cd, city_cd` | P1110_CITY_CODE_OF_ID | Popup LOV | IMPR_TYPE_CD, BUS_ID_TYPE_CD, CTRY_CD | `:GLOBAL.MINS_COMM_CD` of the LOV form: set by CITY_CODE_OF_ID WHEN-VALIDATE-ITEM (TODO-VERIFY) |
| `LOV_CITIES_IMP` (form) for BRNH_CITY_CD | `LOV_CITIES_IMP_BRNH` | SQL | `SELECT city_cd d, city_cd r, city_arb_name, mins_comm_cd FROM cities WHERE city_status = 1 AND ctry_cd = NVL(:P1110_CTRY_CD, ctry_cd) ORDER BY ctry_cd, city_cd` | P1110_BRNH_CITY_CD | Popup LOV | CTRY_CD | |
| `LOV_CITIES` (form) / `CGFK$IMPORTERS_ADD_CTRY_CD` (city part) | `LOV_CITIES` | SQL | `SELECT city_cd d, city_cd r, city_arb_name FROM cities WHERE city_status = 1 AND ctry_cd = NVL(:P1110_ADD_CTRY_CD, ctry_cd) ORDER BY ctry_cd, city_cd` | P1110_CITY_CODE | Popup LOV | ADD_CTRY_CD | |
| `LOV_COUNTRIES` (form) / `CGFK$IMPORTERS_ADD_CTRY_CD` | `LOV_COUNTRIES` | SQL | `SELECT ctry_cd d, ctry_cd r, crty_arbc_name FROM countries WHERE ctry_status = 1 AND ctry_cd NOT IN (-1) ORDER BY ctry_cd` | P1110_ADD_CTRY_CD | Popup LOV | – | item always read-only (value 100) |
| `LOV_COUNTRIES` / `LOV_COUNTRIES_GULF` (PU CALL_LOV_COUNTRIES / CALL_LOV_COUN_GULF) / `CGFK$IMPORTERS_CTRY_CD` | `LOV_COUNTRIES_GULF` | SQL | `SELECT ctry_cd d, ctry_cd r, crty_arbc_name FROM countries WHERE (:P1110_IMPR_TYPE_CD = 4 AND :P1110_BUS_ID_TYPE_CD = 16 AND ctry_cd IN (113,116,117,119,120,100)) OR (NOT (NVL(:P1110_IMPR_TYPE_CD,0) = 4 AND NVL(:P1110_BUS_ID_TYPE_CD,0) = 16) AND ctry_status = 1) ORDER BY ctry_cd` | P1110_CTRY_CD | Popup LOV | IMPR_TYPE_CD, BUS_ID_TYPE_CD | Gulf list hard-coded in LOV_COUNTRIES_GULF |
| `LOV_IMPR` (form) | `LOV_IMPR` | SQL | `SELECT impr_nbr d, impr_nbr r, arbc_impr_name, bus_id, bus_id_brnch, impr_tel_nbr FROM importers WHERE port_cd = :P_CURR_PORT_CD` | P1110_IMPR_NBR_PARENT | Popup LOV | – | |
| list item COMM_RGSTRTN_TYPE (`CGDV$POPULATE_DYNAMIC_LISTS`) | `LOV_COMM_RGSTRTN_TYPE` | SQL | `SELECT rv_meaning d, rv_low_value r FROM cg_ref_codes WHERE rv_domain = 'COMM_RGSTRTN_TYPE' ORDER BY 2` | P1110_COMM_RGSTRTN_TYPE | Select List | – | |
| list item IMPR_EXPR_TYPE (`CGDV$POPULATE_DYNAMIC_LISTS`) | `LOV_ALLOWED_EXPORT` | SQL | `SELECT rv_meaning d, rv_low_value r FROM cg_ref_codes WHERE rv_domain = 'ALLOWED EXPORT' ORDER BY 2` | P1110_IMPR_EXPR_TYPE | Select List | – | |
| list item EXPRESS_POST | `LOV_EXPRESS_POST` | Static | `0` لا · `1` نعم · `2` تم انشاءه بواسطة البريد السريع | P1110_EXPRESS_POST | Select List | – | |
| pop list CAR_AGENT_FLAG | `LOV_CAR_AGENT_FLAG` | Static | `0` ليس وكيل سيارات · `1` وكيل سيارات | P1110_CAR_AGENT_FLAG | Select List | – | |
| `CGFK$IMPORTERS_HQ_IMPR_NBR`, `CGDV$IMPORTERS_CREATION_FLAG`, `CGDV$IMPORTERS_CUSTOMS_ENTERED` | – | – | – | – | – | – | not needed (display-only / hidden items) |

Before creating them, check f345 for an existing LOV with the same query (f345 rule: never re-create a
shared component). f345 has none of these names today.

## 7. Validations (page 1110)

Every item validation calls the item's `<ITEM>_VALIDATION` function, which runs the converted POST-CHANGE +
WHEN-VALIDATE-ITEM code and returns the error text (NULL = OK). Error display: inline with field and in
notification. Condition: request `CREATE` or `SAVE`. The `<ITEM> REQUIRED` validations add the required
rules that change at runtime. The static Forms *Required* items use the item attribute Value Required = Yes.
TODO-VERIFY in step 05: an item disabled by a `READ ONLY` DA is not submitted, so check that its Value
Required check does not fire on an empty locked item (Forms does not ask for a non-enterable item).

| # | Validation | Item | Type | Code | Server-side condition | Source |
|---|---|---|---|---|---|---|
| 1 | `PORT_CD VALIDATION` | P1110_PORT_CD | PL/SQL Function Body returning Error Text | `RETURN IMPR1110.PORT_CD_VALIDATION(P_PORT_CD => :P1110_PORT_CD, P_PORT_NAME => :P1110_PORT_NAME, P_SDP_PORT_STATUS => :P1110_SDP_PORT_STATUS);` | request in (CREATE, SAVE) | IMPORTERS.PORT_CD.WHEN-VALIDATE-ITEM |
| 2 | `HQ_IMPR_NBR VALIDATION` | P1110_HQ_IMPR_NBR | PL/SQL Function Body returning Error Text | `RETURN IMPR1110.HQ_IMPR_NBR_VALIDATION();` | request in (CREATE, SAVE) | IMPORTERS.HQ_IMPR_NBR.POST-CHANGE |
| 3 | `IMPR_NBR VALIDATION` | P1110_IMPR_NBR | PL/SQL Function Body returning Error Text | `RETURN IMPR1110.IMPR_NBR_VALIDATION(P_PORT_CD => :P1110_PORT_CD, P_IMPR_NBR => :P1110_IMPR_NBR);` | request in (CREATE, SAVE) | IMPORTERS.IMPR_NBR.WHEN-VALIDATE-ITEM |
| 4 | `IMPR_TYPE_CD VALIDATION` | P1110_IMPR_TYPE_CD | PL/SQL Function Body returning Error Text | `RETURN IMPR1110.IMPR_TYPE_CD_VALIDATION(P_IMPR_NBR => :P1110_IMPR_NBR, P_IMPR_TYPE_CD => :P1110_IMPR_TYPE_CD, P_BUS_ID_TYPE_CD => :P1110_BUS_ID_TYPE_CD, P_BUS_ID => :P1110_BUS_ID, P_CTRY_CD => :P1110_CTRY_CD, P_ADD_CTRY_CD => :P1110_ADD_CTRY_CD, P_IMPR_TYPE_NAME => :P1110_IMPR_TYPE_NAME, P_BUS_ID_TYPE_NAME => :P1110_BUS_ID_TYPE_NAME, P_CRTY_ARBC_NAME => :P1110_CRTY_ARBC_NAME, P_ITIDT_NOTE => :P1110_ITIDT_NOTE, P_STATUS => :P1110_STATUS, P_ADD_CRTY_ARBC_NAME => :P1110_ADD_CRTY_ARBC_NAME, P_CURR_PORT_CD => :P_CURR_PORT_CD);` | request in (CREATE, SAVE) | IMPORTERS.IMPR_TYPE_CD.POST-CHANGE + WHEN-VALIDATE-ITEM |
| 5 | `BUS_ID_EXPRD_DT VALIDATION` | P1110_BUS_ID_EXPRD_DT | PL/SQL Function Body returning Error Text | `RETURN IMPR1110.BUS_ID_EXPRD_DT_VALIDATION(P_BUS_ID_EXPRD_DT => :P1110_BUS_ID_EXPRD_DT);` | request in (CREATE, SAVE) | IMPORTERS.BUS_ID_EXPRD_DT.WHEN-VALIDATE-ITEM |
| 6 | `BUS_ID_TYPE_CD VALIDATION` | P1110_BUS_ID_TYPE_CD | PL/SQL Function Body returning Error Text | `RETURN IMPR1110.BUS_ID_TYPE_CD_VALIDATION(P_IMPR_TYPE_CD => :P1110_IMPR_TYPE_CD, P_BUS_ID_TYPE_CD => :P1110_BUS_ID_TYPE_CD, P_CTRY_CD => :P1110_CTRY_CD, P_ADD_CTRY_CD => :P1110_ADD_CTRY_CD, P_CRTY_ARBC_NAME => :P1110_CRTY_ARBC_NAME, P_ADD_CRTY_ARBC_NAME => :P1110_ADD_CRTY_ARBC_NAME);` | request in (CREATE, SAVE) | IMPORTERS.BUS_ID_TYPE_CD.POST-CHANGE |
| 7 | `CITY_CODE_OF_ID VALIDATION` | P1110_CITY_CODE_OF_ID | PL/SQL Function Body returning Error Text | `RETURN IMPR1110.CITY_CODE_OF_ID_VALIDATION(P_CITY_CODE_OF_ID => :P1110_CITY_CODE_OF_ID, P_CTRY_CD_OF_ID => :P1110_CTRY_CD_OF_ID, P_ID_CITY_NAME => :P1110_ID_CITY_NAME, P_ID_MINS_COMM_CD => :P1110_ID_MINS_COMM_CD, P_L_CT_CITY_STATUS2 => :P1110_L_CT_CITY_STATUS2, P_ROW_ID => :P1110_ROW_ID);` | request in (CREATE, SAVE) | IMPORTERS.CITY_CODE_OF_ID.WHEN-VALIDATE-ITEM |
| 8 | `BUS_ID VALIDATION` | P1110_BUS_ID | PL/SQL Function Body returning Error Text | `RETURN IMPR1110.BUS_ID_VALIDATION(P_PORT_CD => :P1110_PORT_CD, P_IMPR_NBR => :P1110_IMPR_NBR, P_BUS_ID_STATUS => :P1110_BUS_ID_STATUS, P_IMPR_TYPE_CD => :P1110_IMPR_TYPE_CD, P_BUS_ID_EXPRD_DT => :P1110_BUS_ID_EXPRD_DT, P_BUS_ID_TYPE_CD => :P1110_BUS_ID_TYPE_CD, P_COMM_RGSTRTN_TYPE => :P1110_COMM_RGSTRTN_TYPE, P_CITY_CODE_OF_ID => :P1110_CITY_CODE_OF_ID, P_BUS_ID => :P1110_BUS_ID, P_BUS_ID_BRNCH => :P1110_BUS_ID_BRNCH, P_CTRY_CD => :P1110_CTRY_CD, P_ARBC_IMPR_NAME => :P1110_ARBC_IMPR_NAME, P_IMPR_NAME_STD => :P1110_IMPR_NAME_STD, P_LST_TRAN_DT => :P1110_LST_TRAN_DT, P_IMPR_ADDRESS => :P1110_IMPR_ADDRESS, P_BUS_ID_ISSUE_DT => :P1110_BUS_ID_ISSUE_DT, P_IMPR_POB_NBR => :P1110_IMPR_POB_NBR, P_IMPR_ZIP_CD => :P1110_IMPR_ZIP_CD, P_IMPR_TEL_NBR => :P1110_IMPR_TEL_NBR, P_IMPR_FAX_NBR => :P1110_IMPR_FAX_NBR, P_IMPR_TELEX_NBR => :P1110_IMPR_TELEX_NBR, P_CTRY_CD_OF_ID => :P1110_CTRY_CD_OF_ID, P_ACTIVITY => :P1110_ACTIVITY, P_CREATION_FLAG => :P1110_CREATION_FLAG, P_ID_CITY_NAME => :P1110_ID_CITY_NAME, P_ID_MINS_COMM_CD => :P1110_ID_MINS_COMM_CD, P_BRNH_CITY_CD => :P1110_BRNH_CITY_CD, P_BRNH_CITY_NAME => :P1110_BRNH_CITY_NAME, P_B_ID_NBR => :P1110_B_ID_NBR, P_ROW_ID => :P1110_ROW_ID);` | request in (CREATE, SAVE) | IMPORTERS.BUS_ID.POST-CHANGE + WHEN-VALIDATE-ITEM |
| 9 | `BRNH_CITY_CD VALIDATION` | P1110_BRNH_CITY_CD | PL/SQL Function Body returning Error Text | `RETURN IMPR1110.BRNH_CITY_CD_VALIDATION(P_CTRY_CD_OF_ID => :P1110_CTRY_CD_OF_ID, P_BRNH_CITY_CD => :P1110_BRNH_CITY_CD, P_BRNH_CITY_NAME => :P1110_BRNH_CITY_NAME);` | request in (CREATE, SAVE) | IMPORTERS.BRNH_CITY_CD.WHEN-VALIDATE-ITEM |
| 10 | `BUS_ID_BRNCH VALIDATION` | P1110_BUS_ID_BRNCH | PL/SQL Function Body returning Error Text | `RETURN IMPR1110.BUS_ID_BRNCH_VALIDATION(P_PORT_CD => :P1110_PORT_CD, P_IMPR_NBR => :P1110_IMPR_NBR, P_BUS_ID_STATUS => :P1110_BUS_ID_STATUS, P_IMPR_TYPE_CD => :P1110_IMPR_TYPE_CD, P_BUS_ID_EXPRD_DT => :P1110_BUS_ID_EXPRD_DT, P_BUS_ID_TYPE_CD => :P1110_BUS_ID_TYPE_CD, P_COMM_RGSTRTN_TYPE => :P1110_COMM_RGSTRTN_TYPE, P_CITY_CODE_OF_ID => :P1110_CITY_CODE_OF_ID, P_BUS_ID => :P1110_BUS_ID, P_BUS_ID_BRNCH => :P1110_BUS_ID_BRNCH, P_CTRY_CD => :P1110_CTRY_CD, P_ARBC_IMPR_NAME => :P1110_ARBC_IMPR_NAME, P_IMPR_NAME_STD => :P1110_IMPR_NAME_STD, P_LST_TRAN_DT => :P1110_LST_TRAN_DT, P_IMPR_ADDRESS => :P1110_IMPR_ADDRESS, P_BUS_ID_ISSUE_DT => :P1110_BUS_ID_ISSUE_DT, P_IMPR_POB_NBR => :P1110_IMPR_POB_NBR, P_IMPR_ZIP_CD => :P1110_IMPR_ZIP_CD, P_IMPR_TEL_NBR => :P1110_IMPR_TEL_NBR, P_IMPR_FAX_NBR => :P1110_IMPR_FAX_NBR, P_IMPR_TELEX_NBR => :P1110_IMPR_TELEX_NBR, P_CTRY_CD_OF_ID => :P1110_CTRY_CD_OF_ID, P_ACTIVITY => :P1110_ACTIVITY, P_CREATION_FLAG => :P1110_CREATION_FLAG, P_ID_CITY_NAME => :P1110_ID_CITY_NAME, P_BRNH_ID_MINS_COMM_CD => :P1110_BRNH_ID_MINS_COMM_CD, P_BRNH_CITY_CD => :P1110_BRNH_CITY_CD, P_BRNH_CITY_NAME => :P1110_BRNH_CITY_NAME, P_ROW_ID => :P1110_ROW_ID, P_CODE => :P1110_P_CODE);` | request in (CREATE, SAVE) | IMPORTERS.BUS_ID_BRNCH.POST-CHANGE + WHEN-VALIDATE-ITEM |
| 11 | `CTRY_CD VALIDATION` | P1110_CTRY_CD | PL/SQL Function Body returning Error Text | `RETURN IMPR1110.CTRY_CD_VALIDATION(P_IMPR_TYPE_CD => :P1110_IMPR_TYPE_CD, P_BUS_ID_TYPE_CD => :P1110_BUS_ID_TYPE_CD, P_CTRY_CD => :P1110_CTRY_CD, P_CTRY_CD_OF_ID => :P1110_CTRY_CD_OF_ID, P_CRTY_ARBC_NAME => :P1110_CRTY_ARBC_NAME, P_CTRY_CTRY_STATUS => :P1110_CTRY_CTRY_STATUS);` | request in (CREATE, SAVE) | IMPORTERS.CTRY_CD.WHEN-VALIDATE-ITEM |
| 12 | `IMPR_EXPR_TYPE VALIDATION` | P1110_IMPR_EXPR_TYPE | PL/SQL Function Body returning Error Text | `RETURN IMPR1110.IMPR_EXPR_TYPE_VALIDATION();` | request in (CREATE, SAVE) | IMPORTERS.IMPR_EXPR_TYPE.POST-CHANGE |
| 13 | `ARBC_IMPR_NAME VALIDATION` | P1110_ARBC_IMPR_NAME | PL/SQL Function Body returning Error Text | `RETURN IMPR1110.ARBC_IMPR_NAME_VALIDATION(P_ARBC_IMPR_NAME => :P1110_ARBC_IMPR_NAME, P_IMPR_NAME_STD => :P1110_IMPR_NAME_STD);` | request in (CREATE, SAVE) | IMPORTERS.ARBC_IMPR_NAME.WHEN-VALIDATE-ITEM |
| 14 | `ENG_IMPR_NAME VALIDATION` | P1110_ENG_IMPR_NAME | PL/SQL Function Body returning Error Text | `RETURN IMPR1110.ENG_IMPR_NAME_VALIDATION(P_ENG_IMPR_NAME => :P1110_ENG_IMPR_NAME);` | request in (CREATE, SAVE) | IMPORTERS.ENG_IMPR_NAME.WHEN-VALIDATE-ITEM |
| 15 | `BUS_ID_ISSUE_DT VALIDATION` | P1110_BUS_ID_ISSUE_DT | PL/SQL Function Body returning Error Text | `RETURN IMPR1110.BUS_ID_ISSUE_DT_VALIDATION(P_BUS_ID_ISSUE_DT => :P1110_BUS_ID_ISSUE_DT);` | request in (CREATE, SAVE) | IMPORTERS.BUS_ID_ISSUE_DT.WHEN-VALIDATE-ITEM |
| 16 | `IMPR_NBR_PARENT VALIDATION` | P1110_IMPR_NBR_PARENT | PL/SQL Function Body returning Error Text | `RETURN IMPR1110.IMPR_NBR_PARENT_VALIDATION(P_IMPR_NBR_PARENT => :P1110_IMPR_NBR_PARENT, P_IMPR_NAME_PARENT => :P1110_IMPR_NAME_PARENT);` | request in (CREATE, SAVE) | IMPORTERS.IMPR_NBR_PARENT.WHEN-VALIDATE-ITEM |
| 17 | `ADD_CTRY_CD VALIDATION` | P1110_ADD_CTRY_CD | PL/SQL Function Body returning Error Text | `RETURN IMPR1110.ADD_CTRY_CD_VALIDATION(P_ADD_CTRY_CD => :P1110_ADD_CTRY_CD, P_CITY_CODE => :P1110_CITY_CODE, P_ADD_CRTY_ARBC_NAME => :P1110_ADD_CRTY_ARBC_NAME, P_CITY_NAME => :P1110_CITY_NAME, P_L_CT_CITY_STATUS => :P1110_L_CT_CITY_STATUS);` | request in (CREATE, SAVE) | IMPORTERS.ADD_CTRY_CD.WHEN-VALIDATE-ITEM |
| 18 | `CITY_CODE VALIDATION` | P1110_CITY_CODE | PL/SQL Function Body returning Error Text | `RETURN IMPR1110.CITY_CODE_VALIDATION(P_ADD_CTRY_CD => :P1110_ADD_CTRY_CD, P_CITY_CODE => :P1110_CITY_CODE, P_ADD_CRTY_ARBC_NAME => :P1110_ADD_CRTY_ARBC_NAME, P_CITY_NAME => :P1110_CITY_NAME, P_L_CT_CITY_STATUS => :P1110_L_CT_CITY_STATUS);` | request in (CREATE, SAVE) | IMPORTERS.CITY_CODE.WHEN-VALIDATE-ITEM |
| 19 | `IMPR_TEL_NBR VALIDATION` | P1110_IMPR_TEL_NBR | PL/SQL Function Body returning Error Text | `RETURN IMPR1110.IMPR_TEL_NBR_VALIDATION(P_IMPR_TEL_NBR => :P1110_IMPR_TEL_NBR);` | request in (CREATE, SAVE) | IMPORTERS.IMPR_TEL_NBR.WHEN-VALIDATE-ITEM |
| 20 | `B_EMAIL VALIDATION` | P1110_B_EMAIL | PL/SQL Function Body returning Error Text | `RETURN IMPR1110.B_EMAIL_VALIDATION(P_PORT_CD => :P1110_PORT_CD, P_B_EMAIL => :P1110_B_EMAIL, P_CURR_PORT_CD => :P_CURR_PORT_CD);` | request in (CREATE, SAVE) | IMPORTERS.B_EMAIL.POST-CHANGE + WHEN-VALIDATE-ITEM |
| 21 | `EMAIL VALIDATION` | P1110_EMAIL | PL/SQL Function Body returning Error Text | `RETURN IMPR1110.EMAIL_VALIDATION(P_EMAIL => :P1110_EMAIL);` | request in (CREATE, SAVE) | IMPORTERS.EMAIL.WHEN-VALIDATE-ITEM |
| 22 | `B_MOBILE_NO VALIDATION` | P1110_B_MOBILE_NO | PL/SQL Function Body returning Error Text | `RETURN IMPR1110.B_MOBILE_NO_VALIDATION(P_PORT_CD => :P1110_PORT_CD, P_IMPR_NBR => :P1110_IMPR_NBR, P_B_MOBILE_NO => :P1110_B_MOBILE_NO, P_CURR_PORT_CD => :P_CURR_PORT_CD);` | request in (CREATE, SAVE) | IMPORTERS.B_MOBILE_NO.POST-CHANGE + WHEN-VALIDATE-ITEM |
| 23 | `BANK_IBAN VALIDATION` | P1110_BANK_IBAN | PL/SQL Function Body returning Error Text | `RETURN IMPR1110.BANK_IBAN_VALIDATION(P_BANK_IBAN => :P1110_BANK_IBAN);` | request in (CREATE, SAVE) | IMPORTERS.BANK_IBAN.WHEN-VALIDATE-ITEM |
| 24 | `B_ID_NBR VALIDATION` | P1110_B_ID_NBR | PL/SQL Function Body returning Error Text | `RETURN IMPR1110.B_ID_NBR_VALIDATION(P_PORT_CD => :P1110_PORT_CD, P_B_ID_NBR => :P1110_B_ID_NBR, P_CURR_PORT_CD => :P_CURR_PORT_CD);` | request in (CREATE, SAVE) | IMPORTERS.B_ID_NBR.POST-CHANGE + WHEN-VALIDATE-ITEM |
| 25 | `CTRY_CD_OF_ID VALIDATION` | P1110_CTRY_CD_OF_ID | PL/SQL Function Body returning Error Text | `RETURN IMPR1110.CTRY_CD_OF_ID_VALIDATION(P_CITY_CODE_OF_ID => :P1110_CITY_CODE_OF_ID, P_CTRY_CD_OF_ID => :P1110_CTRY_CD_OF_ID, P_ID_CITY_NAME => :P1110_ID_CITY_NAME, P_ID_MINS_COMM_CD => :P1110_ID_MINS_COMM_CD, P_L_CT_CITY_STATUS2 => :P1110_L_CT_CITY_STATUS2, P_ROW_ID => :P1110_ROW_ID);` | request in (CREATE, SAVE) | IMPORTERS.CTRY_CD_OF_ID.WHEN-VALIDATE-ITEM |
| 26 | `BUS_ID_EXPRD_DT REQUIRED` | P1110_BUS_ID_EXPRD_DT | PL/SQL Function Body returning Error Text | `RETURN FORMS_APX.REQUIRED_VALIDATION(ITEM_VALUE => :P1110_BUS_ID_EXPRD_DT, ITEM_LABEL => 'إنـتهـاء الـنشاط');` | request in (CREATE, SAVE) and `IMPR1110.BUS_ID_EXPRD_DT_IS_REQUIRED(P_IMPR_TYPE_CD => :P1110_IMPR_TYPE_CD, P_BUS_ID_TYPE_CD => :P1110_BUS_ID_TYPE_CD)` | SET_ITEM_PROPERTY(BUS_ID_EXPRD_DT, REQUIRED) - read_only_rules.md |
| 27 | `COMM_RGSTRTN_TYPE REQUIRED` | P1110_COMM_RGSTRTN_TYPE | PL/SQL Function Body returning Error Text | `RETURN FORMS_APX.REQUIRED_VALIDATION(ITEM_VALUE => :P1110_COMM_RGSTRTN_TYPE, ITEM_LABEL => 'نوع السجل التجاري');` | request in (CREATE, SAVE) and `IMPR1110.COMM_RGSTRTN_TYPE_IS_REQUIRED(P_IMPR_TYPE_CD => :P1110_IMPR_TYPE_CD, P_BUS_ID_TYPE_CD => :P1110_BUS_ID_TYPE_CD)` | SET_ITEM_PROPERTY(COMM_RGSTRTN_TYPE, REQUIRED) - read_only_rules.md |
| 28 | `CITY_CODE_OF_ID REQUIRED` | P1110_CITY_CODE_OF_ID | PL/SQL Function Body returning Error Text | `RETURN FORMS_APX.REQUIRED_VALIDATION(ITEM_VALUE => :P1110_CITY_CODE_OF_ID, ITEM_LABEL => 'مصدررقم الإستدلالي');` | request in (CREATE, SAVE) and `IMPR1110.CITY_CODE_OF_ID_IS_REQUIRED(P_IMPR_TYPE_CD => :P1110_IMPR_TYPE_CD)` | SET_ITEM_PROPERTY(CITY_CODE_OF_ID, REQUIRED) - read_only_rules.md |
| 29 | `BRNH_CITY_CD REQUIRED` | P1110_BRNH_CITY_CD | PL/SQL Function Body returning Error Text | `RETURN FORMS_APX.REQUIRED_VALIDATION(ITEM_VALUE => :P1110_BRNH_CITY_CD, ITEM_LABEL => 'مصدر الرقم الفرعي');` | request in (CREATE, SAVE) and `IMPR1110.BRNH_CITY_CD_IS_REQUIRED(P_COMM_RGSTRTN_TYPE => :P1110_COMM_RGSTRTN_TYPE)` | SET_ITEM_PROPERTY(BRNH_CITY_CD, REQUIRED) - read_only_rules.md |
| 30 | `BUS_ID_BRNCH REQUIRED` | P1110_BUS_ID_BRNCH | PL/SQL Function Body returning Error Text | `RETURN FORMS_APX.REQUIRED_VALIDATION(ITEM_VALUE => :P1110_BUS_ID_BRNCH, ITEM_LABEL => 'الـرقم الــفــرعي');` | request in (CREATE, SAVE) and `IMPR1110.BUS_ID_BRNCH_IS_REQUIRED(P_COMM_RGSTRTN_TYPE => :P1110_COMM_RGSTRTN_TYPE, P_BUS_ID => :P1110_BUS_ID, P_CITY_CODE_OF_ID => :P1110_CITY_CODE_OF_ID)` | SET_ITEM_PROPERTY(BUS_ID_BRNCH, REQUIRED) - read_only_rules.md |
| 31 | `ACTIVITY REQUIRED` | P1110_ACTIVITY | PL/SQL Function Body returning Error Text | `RETURN FORMS_APX.REQUIRED_VALIDATION(ITEM_VALUE => :P1110_ACTIVITY, ITEM_LABEL => 'نشاط المستورد');` | request in (CREATE, SAVE) and `IMPR1110.ACTIVITY_IS_REQUIRED(P_BUS_ID => :P1110_BUS_ID)` | SET_ITEM_PROPERTY(ACTIVITY, REQUIRED) - read_only_rules.md |

## 8. Processes

### Page 1110

f345 order (standard §6). Error display location: inline in notification. Slot 90 `PRE-FORM` is not used:
the form's PRE-FORM only sets a version stamp, the date format and a help path (dropped, extraction §5).

| Point | Seq | Process | Code (one line) | Condition | Source |
|---|---|---|---|---|---|
| Before Header | 10 | `New` | f345 session setup, copied from AGR1100 (`:SSO_APP_USER := GENERAL_UTILITY.ZATCA_SSO(:APP_USER);` + port / user lookups) | - | f345 standard §6 |
| Before Header | 20 | `P0_PAGE_PK CHECK` | `IMPR1110.P0_PAGE_PK_CHECK(P_PAGE_PK => :P0_PAGE_PK, P_CURR_PORT_CD => :P_CURR_PORT_CD);` | - | f345 (block WHERE clause PORT_CD = :PARAMETER.P_CURR_PORT_CD) |
| Before Header | 40 | `PARAMETERS` | `:P1110_MODULE_ID := FORMS_APX.GET_MODULE_ID(P_MODULE_ID => :P1110_MODULE_ID, FORM_NAME => 'IMPR1110');` | - | f345 |
| Before Header | 50 | `PARAMETERS ENTRY` | `IMPR1110.PARAMETERS_ENTRY(APP_P_PRSNL_IMPR => :P_PRSNL_IMPR, APP_P_LETTER_NBR => :P_LETTER_NBR, P_PRSNL_IMPR => :P1110_P_PRSNL_IMPR, P_LETTER_NBR => :P1110_P_LETTER_NBR);` | - | CALL_FORM parameters PRSNL_IMPR, LETTER_NBR |
| Before Header | 60 | `WHEN-NEW-FORM-INSTANCE` | `IMPR1110.WHEN_NEW_FORM_INSTANCE(P_IMPR_TYPE_CD => :P1110_IMPR_TYPE_CD, P_BUS_ID_TYPE_CD => :P1110_BUS_ID_TYPE_CD, P_CTRY_CD => :P1110_CTRY_CD, P_IMPR_EXPR_TYPE => :P1110_IMPR_EXPR_TYPE, P_ADD_CTRY_CD => :P1110_ADD_CTRY_CD, P_EXPRESS_POST => :P1110_EXPRESS_POST, P_CRTY_ARBC_NAME => :P1110_CRTY_ARBC_NAME, P_ADD_CRTY_ARBC_NAME => :P1110_ADD_CRTY_ARBC_NAME, P_CURR_PORT_CD => :P_CURR_PORT_CD, P_CLASS_CD => :P_CLASS_CD, V_USR_TYPE => :V_USR_TYPE);` | :P1110_FORM_OPEN is null | FORM.WHEN-NEW-FORM-INSTANCE |
| Before Header | 65 | `FORM OPEN` | `:P1110_FORM_OPEN := 'Y';` | :P1110_FORM_OPEN is null | once per entry (SCREEN ENTRY RESET clears it) |
| Before Header | 70 | `P0_PAGE_PK` | `:P1110_ROW_ID := :P0_PAGE_PK;` | - | f345 (key = ROWID, Forms key mode ROWID) |
| Before Header | 80 | `Initialize form IMPORTERS` | NATIVE_FORM_INIT, region IMPORTERS | - | block IMPORTERS fetch |
| Before Header | 82 | `POST-QUERY` | `IMPR1110.POST_QUERY(P_PORT_CD => :P1110_PORT_CD, P_HQ_IMPR_NBR => :P1110_HQ_IMPR_NBR, P_IMPR_NBR => :P1110_IMPR_NBR, P_BUS_ID_STATUS => :P1110_BUS_ID_STATUS, P_IMPR_TYPE_CD => :P1110_IMPR_TYPE_CD, P_BUS_ID_TYPE_CD => :P1110_BUS_ID_TYPE_CD, P_CITY_CODE_OF_ID => :P1110_CITY_CODE_OF_ID, P_BUS_ID => :P1110_BUS_ID, P_BUS_ID_BRNCH => :P1110_BUS_ID_BRNCH, P_CTRY_CD => :P1110_CTRY_CD, P_ADD_CTRY_CD => :P1110_ADD_CTRY_CD, P_CITY_CODE => :P1110_CITY_CODE, P_EMAIL => :P1110_EMAIL, P_MOBILE_NO => :P1110_MOBILE_NO, P_ID_NBR => :P1110_ID_NBR, P_CTRY_CD_OF_ID => :P1110_CTRY_CD_OF_ID, P_PORT_NAME => :P1110_PORT_NAME, P_SDP_PORT_STATUS => :P1110_SDP_PORT_STATUS, P_SUSPN_STATUS => :P1110_SUSPN_STATUS, P_STATUS_DESC => :P1110_STATUS_DESC, P_IMPR_TYPE_NAME => :P1110_IMPR_TYPE_NAME, P_BUS_ID_TYPE_NAME => :P1110_BUS_ID_TYPE_NAME, P_ID_CITY_NAME => :P1110_ID_CITY_NAME, P_ID_MINS_COMM_CD => :P1110_ID_MINS_COMM_CD, P_L_CT_CITY_STATUS2 => :P1110_L_CT_CITY_STATUS2, P_BRNH_CITY_CD => :P1110_BRNH_CITY_CD, P_BRNH_CITY_NAME => :P1110_BRNH_CITY_NAME, P_CRTY_ARBC_NAME => :P1110_CRTY_ARBC_NAME, P_CTRY_CTRY_STATUS => :P1110_CTRY_CTRY_STATUS, P_ITIDT_NOTE => :P1110_ITIDT_NOTE, P_STATUS => :P1110_STATUS, P_WASL_CITY_NAME => :P1110_WASL_CITY_NAME, P_ADD_CRTY_ARBC_NAME => :P1110_ADD_CRTY_ARBC_NAME, P_CITY_NAME => :P1110_CITY_NAME, P_L_CT_CITY_STATUS => :P1110_L_CT_CITY_STATUS, P_B_EMAIL => :P1110_B_EMAIL, P_B_MOBILE_NO => :P1110_B_MOBILE_NO, P_B_ID_NBR => :P1110_B_ID_NBR, P_IMPR_ID_TYPE => :P1110_IMPR_ID_TYPE, P_CURR_PORT_CD => :P_CURR_PORT_CD, SSO_APP_USER => :SSO_APP_USER, P_CLASS_CD => :P_CLASS_CD, V_USR_TYPE => :V_USR_TYPE);` | :P1110_ROW_ID is not null | IMPORTERS.POST-QUERY (+ POST-CHANGE on fetch) |
| Before Header | 84 | `WHEN-CREATE-RECORD` | `IMPR1110.WHEN_CREATE_RECORD(P_PORT_CD => :P1110_PORT_CD, P_IMPR_TYPE_CD => :P1110_IMPR_TYPE_CD, P_PORT_NAME => :P1110_PORT_NAME, P_IMPR_TYPE_NAME => :P1110_IMPR_TYPE_NAME, P_CURR_PORT_CD => :P_CURR_PORT_CD, P_PRSNL_IMPR => :P1110_P_PRSNL_IMPR);` | :P1110_ROW_ID is null | IMPORTERS.WHEN-CREATE-RECORD |
| Before Header | 86 | `WHEN-NEW-RECORD-INSTANCE` | `IMPR1110.WHEN_NEW_RECORD_INSTANCE(P_IMPR_TYPE_CD => :P1110_IMPR_TYPE_CD, P_BUS_ID_TYPE_CD => :P1110_BUS_ID_TYPE_CD, P_COMM_RGSTRTN_TYPE => :P1110_COMM_RGSTRTN_TYPE, P_BUS_ID => :P1110_BUS_ID, P_BUS_ID_BRNCH => :P1110_BUS_ID_BRNCH, P_CTRY_CD => :P1110_CTRY_CD, P_ARBC_IMPR_NAME => :P1110_ARBC_IMPR_NAME, P_IMPR_NBR_PARENT => :P1110_IMPR_NBR_PARENT, P_ADD_CTRY_CD => :P1110_ADD_CTRY_CD, P_CRTY_ARBC_NAME => :P1110_CRTY_ARBC_NAME, P_IMPR_NAME_PARENT => :P1110_IMPR_NAME_PARENT, P_ADD_CRTY_ARBC_NAME => :P1110_ADD_CRTY_ARBC_NAME, P_CURR_PORT_CD => :P_CURR_PORT_CD, P_CLASS_CD => :P_CLASS_CD, V_USR_TYPE => :V_USR_TYPE, P_CODE => NULL);` | - | IMPORTERS.PRE-RECORD + WHEN-NEW-RECORD-INSTANCE. P_CODE => NULL: Forms consumes :PARAMETER.CODE in the first WNRI after the function |
| Before Header | 88 | `READ ONLY FLAGS` | `IMPR1110.READ_ONLY_FLAGS(P_IMPR_NBR => :P1110_IMPR_NBR, P_CODE => :P1110_P_CODE, P_PRSNL_IMPR => :P1110_P_PRSNL_IMPR, P_IMPR_TYPE_CD => :P1110_IMPR_TYPE_CD, P_BUS_ID_TYPE_CD => :P1110_BUS_ID_TYPE_CD, P_COMM_RGSTRTN_TYPE => :P1110_COMM_RGSTRTN_TYPE, P_BUS_ID => :P1110_BUS_ID, P_BUS_ID_BRNCH => :P1110_BUS_ID_BRNCH, P_BUS_ID_EXPRD_DT => :P1110_BUS_ID_EXPRD_DT, P_IMPR_TEL_NBR => :P1110_IMPR_TEL_NBR, P_ACTIVITY => :P1110_ACTIVITY, IMPR_TYPE_CD_LOCKED => :P1110_IMPR_TYPE_CD_LOCKED, BUS_ID_EXPRD_DT_LOCKED => :P1110_BUS_ID_EXPRD_DT_LOCKED, COMM_RGSTRTN_TYPE_LOCKED => :P1110_COMM_RGSTRTN_TYPE_LOCKED, CITY_CODE_OF_ID_LOCKED => :P1110_CITY_CODE_OF_ID_LOCKED, BUS_ID_LOCKED => :P1110_BUS_ID_LOCKED, BRNH_CITY_CD_LOCKED => :P1110_BRNH_CITY_CD_LOCKED, BUS_ID_BRNCH_LOCKED => :P1110_BUS_ID_BRNCH_LOCKED, CTRY_CD_LOCKED => :P1110_CTRY_CD_LOCKED, ARBC_IMPR_NAME_LOCKED => :P1110_ARBC_IMPR_NAME_LOCKED, REGISTER_ITEMS_LOCKED => :P1110_REGISTER_ITEMS_LOCKED, IMPR_TEL_NBR_LOCKED => :P1110_IMPR_TEL_NBR_LOCKED, ACTIVITY_LOCKED => :P1110_ACTIVITY_LOCKED, B_ID_NBR_LOCKED => :P1110_B_ID_NBR_LOCKED, CAR_AGENT_FLAG_LOCKED => :P1110_CAR_AGENT_FLAG_LOCKED);` | - | net read-only state (read_only_rules.md) |
| Before Header | 100 | `HEADER TITLE` | FORMS_APX.HEADER_TITLE(P_MODULE_ID => :P1110_MODULE_ID, P_HERO_TITLE => :P1110_HERO_TITLE, DEFAULT_TITLE => 'إضافة وتعديل بيانات مستورد'); | - | f345 (OLB block TITLE) |
| After Submit | 10 | `EXECUTE-QUERY` | `:P0_PAGE_PK := IMPR1110.IMPORTER_ROW_ID(P_IMPR_NBR => :P1110_IMPR_NBR, P_CURR_PORT_CD => :P_CURR_PORT_CD);` | :REQUEST = 'EXECUTE_QUERY' | IMPORTERS.IMPR_NBR.WHEN-VALIDATE-ITEM -> WHEN-NEW-ITEM-INSTANCE EXECUTE_QUERY |
| After Submit | 20 | `PRE-INSERT` | `IMPR1110.PRE_INSERT(P_PORT_CD => :P1110_PORT_CD, P_HQ_IMPR_NBR => :P1110_HQ_IMPR_NBR, P_IMPR_NBR => :P1110_IMPR_NBR, P_IMPR_TYPE_CD => :P1110_IMPR_TYPE_CD, P_BUS_ID_EXPRD_DT => :P1110_BUS_ID_EXPRD_DT, P_BUS_ID_TYPE_CD => :P1110_BUS_ID_TYPE_CD, P_COMM_RGSTRTN_TYPE => :P1110_COMM_RGSTRTN_TYPE, P_CITY_CODE_OF_ID => :P1110_CITY_CODE_OF_ID, P_BUS_ID => :P1110_BUS_ID, P_BUS_ID_BRNCH => :P1110_BUS_ID_BRNCH, P_CTRY_CD => :P1110_CTRY_CD, P_IMPR_EXPR_TYPE => :P1110_IMPR_EXPR_TYPE, P_ARBC_IMPR_NAME => :P1110_ARBC_IMPR_NAME, P_IMPD_STMT_NBR => :P1110_IMPD_STMT_NBR, P_IMPR_DATA_SRCE => :P1110_IMPR_DATA_SRCE, P_ENG_IMPR_NAME => :P1110_ENG_IMPR_NAME, P_IMPR_CNTCT_NAME => :P1110_IMPR_CNTCT_NAME, P_IMPR_ADDRESS => :P1110_IMPR_ADDRESS, P_BUS_ID_ISSUE_DT => :P1110_BUS_ID_ISSUE_DT, P_IMPR_NBR_PARENT => :P1110_IMPR_NBR_PARENT, P_ADD_CTRY_CD => :P1110_ADD_CTRY_CD, P_CITY_CODE => :P1110_CITY_CODE, P_IMPR_POB_NBR => :P1110_IMPR_POB_NBR, P_IMPR_ZIP_CD => :P1110_IMPR_ZIP_CD, P_IMPR_TEL_NBR => :P1110_IMPR_TEL_NBR, P_IMPR_FAX_NBR => :P1110_IMPR_FAX_NBR, P_IMPR_TELEX_NBR => :P1110_IMPR_TELEX_NBR, P_BANK_IBAN => :P1110_BANK_IBAN, P_CAR_AGENT_FLAG => :P1110_CAR_AGENT_FLAG, P_EXPRESS_POST => :P1110_EXPRESS_POST, P_CTRY_CD_OF_ID => :P1110_CTRY_CD_OF_ID, P_EXPD_STMT_NBR => :P1110_EXPD_STMT_NBR, P_WVR_ENTRY_NBR => :P1110_WVR_ENTRY_NBR, P_ACTIVITY => :P1110_ACTIVITY, P_ID_CITY_NAME => :P1110_ID_CITY_NAME, P_ID_MINS_COMM_CD => :P1110_ID_MINS_COMM_CD, P_L_CT_CITY_STATUS2 => :P1110_L_CT_CITY_STATUS2, P_BRNH_CITY_CD => :P1110_BRNH_CITY_CD, P_B_EMAIL => :P1110_B_EMAIL, P_B_MOBILE_NO => :P1110_B_MOBILE_NO, P_B_ID_NBR => :P1110_B_ID_NBR, P_CURR_PORT_CD => :P_CURR_PORT_CD, SSO_APP_USER => :SSO_APP_USER, P_GLOBAL_V_WS_ID => :P_GLOBAL_V_WS_ID, P_CLASS_CD => :P_CLASS_CD, V_USR_TYPE => :V_USR_TYPE, P_ANSWER => :P1110_ANSWER);` | :P0_PAGE_PK is null and :REQUEST = 'CREATE' | IMPORTERS.PRE-INSERT |
| After Submit | 30 | `PRE-UPDATE` | `IMPR1110.PRE_UPDATE(P_PORT_CD => :P1110_PORT_CD, P_HQ_IMPR_NBR => :P1110_HQ_IMPR_NBR, P_IMPR_NBR => :P1110_IMPR_NBR, P_BUS_ID_STATUS => :P1110_BUS_ID_STATUS, P_IMPR_TYPE_CD => :P1110_IMPR_TYPE_CD, P_BUS_ID_EXPRD_DT => :P1110_BUS_ID_EXPRD_DT, P_BUS_ID_TYPE_CD => :P1110_BUS_ID_TYPE_CD, P_COMM_RGSTRTN_TYPE => :P1110_COMM_RGSTRTN_TYPE, P_CITY_CODE_OF_ID => :P1110_CITY_CODE_OF_ID, P_BUS_ID => :P1110_BUS_ID, P_BUS_ID_BRNCH => :P1110_BUS_ID_BRNCH, P_CTRY_CD => :P1110_CTRY_CD, P_IMPR_EXPR_TYPE => :P1110_IMPR_EXPR_TYPE, P_ARBC_IMPR_NAME => :P1110_ARBC_IMPR_NAME, P_IMPR_NAME_STD => :P1110_IMPR_NAME_STD, P_LST_TRAN_DT => :P1110_LST_TRAN_DT, P_IMPD_STMT_NBR => :P1110_IMPD_STMT_NBR, P_IMPR_DATA_SRCE => :P1110_IMPR_DATA_SRCE, P_ENG_IMPR_NAME => :P1110_ENG_IMPR_NAME, P_IMPR_CNTCT_NAME => :P1110_IMPR_CNTCT_NAME, P_IMPR_ADDRESS => :P1110_IMPR_ADDRESS, P_BUS_ID_ISSUE_DT => :P1110_BUS_ID_ISSUE_DT, P_IMPR_NBR_PARENT => :P1110_IMPR_NBR_PARENT, P_ADD_CTRY_CD => :P1110_ADD_CTRY_CD, P_CITY_CODE => :P1110_CITY_CODE, P_IMPR_POB_NBR => :P1110_IMPR_POB_NBR, P_IMPR_ZIP_CD => :P1110_IMPR_ZIP_CD, P_IMPR_TEL_NBR => :P1110_IMPR_TEL_NBR, P_IMPR_FAX_NBR => :P1110_IMPR_FAX_NBR, P_IMPR_TELEX_NBR => :P1110_IMPR_TELEX_NBR, P_EMAIL => :P1110_EMAIL, P_MOBILE_NO => :P1110_MOBILE_NO, P_BANK_IBAN => :P1110_BANK_IBAN, P_ID_NBR => :P1110_ID_NBR, P_CAR_AGENT_FLAG => :P1110_CAR_AGENT_FLAG, P_EXPRESS_POST => :P1110_EXPRESS_POST, P_CTRY_CD_OF_ID => :P1110_CTRY_CD_OF_ID, P_CUSTOMS_ENTERED => :P1110_CUSTOMS_ENTERED, P_CREATION_FLAG => :P1110_CREATION_FLAG, P_IMPR_TYPE_NAME => :P1110_IMPR_TYPE_NAME, P_B_MOBILE_NO => :P1110_B_MOBILE_NO, P_CURR_PORT_CD => :P_CURR_PORT_CD, SSO_APP_USER => :SSO_APP_USER, P_GLOBAL_V_WS_ID => :P_GLOBAL_V_WS_ID, P_LETTER_NBR => :P1110_P_LETTER_NBR);` | :P0_PAGE_PK is not null and :REQUEST = 'SAVE' | IMPORTERS.PRE-UPDATE |
| After Submit | 35 | `KEY-DELREC` | `IMPR1110.KEY_DELREC(P_PORT_CD => :P1110_PORT_CD, P_IMPR_NBR => :P1110_IMPR_NBR, P_ROW_ID => :P1110_ROW_ID, P_CURR_PORT_CD => :P_CURR_PORT_CD, SSO_APP_USER => :SSO_APP_USER, P_GLOBAL_V_WS_ID => :P_GLOBAL_V_WS_ID);` | :REQUEST = 'DELETE' | IMPORTERS.KEY-DELREC + PRE-DELETE (block Delete Allowed = No: the trigger deletes) |
| After Submit | 40 | `Process form IMPORTERS` | NATIVE_FORM_DML, region IMPORTERS, Prevent Lost Updates = Yes, Lock Row = Yes, Return Primary Key(s) after Insert = Yes | :REQUEST in ('CREATE', 'SAVE') | Forms default INSERT / UPDATE of block IMPORTERS |
| After Submit | 50 | `POST-INSERT` | `IMPR1110.POST_INSERT(P_PORT_CD => :P1110_PORT_CD, P_HQ_IMPR_NBR => :P1110_HQ_IMPR_NBR, P_IMPR_NBR => :P1110_IMPR_NBR, P_BUS_ID_STATUS => :P1110_BUS_ID_STATUS, P_IMPR_TYPE_CD => :P1110_IMPR_TYPE_CD, P_BUS_ID_EXPRD_DT => :P1110_BUS_ID_EXPRD_DT, P_BUS_ID_TYPE_CD => :P1110_BUS_ID_TYPE_CD, P_COMM_RGSTRTN_TYPE => :P1110_COMM_RGSTRTN_TYPE, P_CITY_CODE_OF_ID => :P1110_CITY_CODE_OF_ID, P_BUS_ID => :P1110_BUS_ID, P_BUS_ID_BRNCH => :P1110_BUS_ID_BRNCH, P_CTRY_CD => :P1110_CTRY_CD, P_IMPR_EXPR_TYPE => :P1110_IMPR_EXPR_TYPE, P_ARBC_IMPR_NAME => :P1110_ARBC_IMPR_NAME, P_IMPR_NAME_STD => :P1110_IMPR_NAME_STD, P_LST_TRAN_DT => :P1110_LST_TRAN_DT, P_IMPD_STMT_NBR => :P1110_IMPD_STMT_NBR, P_IMPR_DATA_SRCE => :P1110_IMPR_DATA_SRCE, P_ENG_IMPR_NAME => :P1110_ENG_IMPR_NAME, P_IMPR_CNTCT_NAME => :P1110_IMPR_CNTCT_NAME, P_IMPR_ADDRESS => :P1110_IMPR_ADDRESS, P_BUS_ID_ISSUE_DT => :P1110_BUS_ID_ISSUE_DT, P_IMPR_NBR_PARENT => :P1110_IMPR_NBR_PARENT, P_ADD_CTRY_CD => :P1110_ADD_CTRY_CD, P_CITY_CODE => :P1110_CITY_CODE, P_IMPR_POB_NBR => :P1110_IMPR_POB_NBR, P_IMPR_ZIP_CD => :P1110_IMPR_ZIP_CD, P_IMPR_TEL_NBR => :P1110_IMPR_TEL_NBR, P_IMPR_FAX_NBR => :P1110_IMPR_FAX_NBR, P_IMPR_TELEX_NBR => :P1110_IMPR_TELEX_NBR, P_EMAIL => :P1110_EMAIL, P_MOBILE_NO => :P1110_MOBILE_NO, P_BANK_IBAN => :P1110_BANK_IBAN, P_ID_NBR => :P1110_ID_NBR, P_CAR_AGENT_FLAG => :P1110_CAR_AGENT_FLAG, P_EXPRESS_POST => :P1110_EXPRESS_POST, P_CTRY_CD_OF_ID => :P1110_CTRY_CD_OF_ID, P_CREATION_FLAG => :P1110_CREATION_FLAG, P_B_EMAIL => :P1110_B_EMAIL, P_B_MOBILE_NO => :P1110_B_MOBILE_NO, P_B_ID_NBR => :P1110_B_ID_NBR, P_CURR_PORT_CD => :P_CURR_PORT_CD, SSO_APP_USER => :SSO_APP_USER, P_GLOBAL_V_WS_ID => :P_GLOBAL_V_WS_ID, P_CLASS_CD => :P_CLASS_CD, V_USR_TYPE => :V_USR_TYPE, P_BRKR_PORT_CD => :P_BRKR_PORT_CD, P_LIC_TYPE => :P_LIC_TYPE, P_BRKR_NBR => :P_BRKR_NBR);` | :P0_PAGE_PK is null and :REQUEST = 'CREATE' | IMPORTERS.POST-INSERT |
| After Submit | 60 | `POST-UPDATE` | `IMPR1110.POST_UPDATE(P_HQ_IMPR_NBR => :P1110_HQ_IMPR_NBR, P_IMPR_TYPE_CD => :P1110_IMPR_TYPE_CD, P_BUS_ID_TYPE_CD => :P1110_BUS_ID_TYPE_CD, P_BUS_ID => :P1110_BUS_ID, P_BUS_ID_BRNCH => :P1110_BUS_ID_BRNCH, P_B_EMAIL => :P1110_B_EMAIL, P_B_MOBILE_NO => :P1110_B_MOBILE_NO, P_B_ID_NBR => :P1110_B_ID_NBR);` | :P0_PAGE_PK is not null and :REQUEST = 'SAVE' | IMPORTERS.POST-UPDATE |
| After Submit | 70 | `P_CODE RESET` | `:P1110_P_CODE := NULL;` | :REQUEST in ('CREATE', 'SAVE') | function mode ends with the commit (extraction §7 #2) |
| After Submit | 80 | `P0_PAGE_PK AFTER INSERT` | `:P0_PAGE_PK := :P1110_ROW_ID;` | :P0_PAGE_PK is null and :REQUEST = 'CREATE' | f345 |
| After Submit | 85 | `P0_PAGE_PK AFTER DELETE` | `:P0_PAGE_PK := NULL;` | :REQUEST = 'DELETE' | f345 |

Branch: after processing → page 1110 (f345 default). Request `EXECUTE_QUERY` additionally clears the
cache of page 1110, so the non-database items of the old record are not kept.

### Page 111002

| Point | Seq | Process | Code | Condition | Source |
|---|---|---|---|---|---|
| After Header | 10 | `G_LAST_PAGE KEEP` | `:G_LAST_PAGE := 1110;` | – | f345 standard §4 |
| After Submit | 10 | `PB_OK WHEN-BUTTON-PRESSED` | `IMPR1110.MOBILE_OK(P_MOBILE_NO => :P111002_MOBILE_NO);` | request `PB_OK` | LOV_UPDATE_IMPR_MOBILE.CTRL_BLK.PB_OK |
| After Submit | 20 | `Close Dialog` | native Close Dialog | request `PB_OK` | COPY_SELECTED_VALUES + EXIT_FORM |

## 9. Computations

APEX runs Before Header computations before the Before Header processes, so the computations that need
the fetched record (ADJ_FUNS, MOBILE_URL, PRE_INSERT_QUESTION) run After Header.

| Item | Point | Type | Expression | Condition | Source |
|---|---|---|---|---|---|
| P1110_HIJRI_DATE_FORMAT | Before Header | PL/SQL Expression | `FORMS_APX.HIJRI_DATE_FORMAT` | - | Hijri date format from one place: Application Setting HIJRI_DATE_FORMAT (Forms mask MI-MM-YYYY) |
| P1110_ADJ_FUNS | After Header | PL/SQL Expression | `IMPR1110.ADJ_FUNS(P_IMPR_NBR => :P1110_IMPR_NBR, P_IMPR_TYPE_CD => :P1110_IMPR_TYPE_CD, P_BUS_ID_TYPE_CD => :P1110_BUS_ID_TYPE_CD, P_CURR_PORT_CD => :P_CURR_PORT_CD, SSO_APP_USER => :SSO_APP_USER, P_CLASS_CD => :P_CLASS_CD, V_USR_TYPE => :V_USR_TYPE)` | - | PU ADJ_FUNS |
| P1110_BROKER_USER | Before Header | PL/SQL Expression | `CASE WHEN IMPR1110.EXPRESS_POST_IS_READ_ONLY(P_CLASS_CD => :P_CLASS_CD, V_USR_TYPE => :V_USR_TYPE) THEN 'Y' ELSE 'N' END` | - | PRE-INSERT condition class 1 / type 3 (same rule as EXPRESS_POST) |
| P1110_PRE_INSERT_QUESTION | After Header | PL/SQL Expression | `APEX_LANG.MESSAGE('IMPR1110_PRE_INSERT_CONFIRM')` | :P1110_BROKER_USER = 'Y' | IMPORTERS.PRE-INSERT CONFIRM text (Text Message, translatable) |
| P1110_MOBILE_URL | After Header | PL/SQL Expression | `APEX_PAGE.GET_URL(p_page => 111002, p_clear_cache => '111002', p_items => 'P111002_IMPR_NBR', p_values => :P1110_IMPR_NBR)` | :P1110_IMPR_NBR is not null | CALL_FORM(LOV_UPDATE_IMPR_MOBILE) |
| P111002_CENTRAL_MOBILE | Before Header (page 111002) | PL/SQL Expression | `IMPR1110.CENTRAL_MOBILE(P_IMPR_NBR => :P111002_IMPR_NBR, P_CURR_PORT_CD => :P_CURR_PORT_CD)` | - | PU LOV_UPDATE_MOBLIE (P_CENTRAL_MOBILE parameter) |
| P111002_MOBILE_NO | Before Header (page 111002) | PL/SQL Expression | `:P111002_CENTRAL_MOBILE` | :P111002_MOBILE_NO is null | LOV_UPDATE_IMPR_MOBILE.BLK.WHEN-NEW-BLOCK-INSTANCE |

`P1110_SUPPORT_URL` (URL of the SUPPORT_ENTRY dialog): **TODO**, added when that form's page exists.

## 10. Dynamic Actions (page 1110)

### 10.1 How the DAs are built

- **`NUMBER ONLY`** (Page Load, sequence 5, user request 2026-11-24): one *Execute JavaScript Code* line from
  `scripts/number_only.py`, a delegated `input` handler for `.number_only`: only digits stay while typing or pasting
  (Arabic-Indic / Persian digits become 0-9). The Number Field items `P1110_IMPR_NBR`, `P1110_IMPR_POB_NBR` and
  `P1110_IMPR_ZIP_CD` have the CSS class `number_only`. Popup LOVs (name search) and phone fields (`+`, spaces) do not.

- **FOS - Execute PL/SQL Code** (f345 plug-in `COM.FOS.EXECUTE_PLSQL_CODE`) with the attributes of standard §9:
  `p_attribute_01` = the call below; `p_attribute_02` = *Items to Submit* (only items the user can change,
  plus the answer / function-code items; everything else is read from session state); `p_attribute_03` =
  *Items to Return* (the IN OUT / OUT parameters); `p_attribute_05 => '#SQLERRM#'`; `p_wait_for_result => 'Y'`.
  `p_attribute_15 => 'suppressChangeEvent:escape-message'`, except on the `READ_ONLY_FLAGS` action, which
  must fire the change events of the flag items.
- An error raised by the package (`FORMS_APX.FORM_TRIGGER_FAILURE`, ORA-20001) stops the DA, and FOS
  shows the text, as Forms does with `RAISE FORM_TRIGGER_FAILURE`.
- Messages that do not stop processing (`INFO` → `FORMS_APX.MESSAGE` → `apex_application.g_print_success_message`)
  are shown by FOS as its success message (TODO-VERIFY with the f345 FOS version in step 04).
- POST-CHANGE + WHEN-VALIDATE-ITEM → event *Change*. WHEN-NEW-ITEM-INSTANCE → *Get Focus*. KEY-NEXT-ITEM →
  *Lose Focus*. WHEN-LIST-CHANGED → *Change*.
- Forms fires WHEN-VALIDATE-ITEM when the user leaves a changed item; *Change* fires at the same moment for
  text items, and at once for select lists and LOVs.

### 10.2 All dynamic actions

The table is generated. *Code / setting* is the exact call; one row per action.

| # | Dynamic action | Event | Selection | Client condition | Act | Action | Code / setting | Items to Submit | Items to Return | Fire on init | Note | Source |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | `PORT_CD WHEN-VALIDATE-ITEM` | Change | Item P1110_PORT_CD | - | 1 | FOS - Execute PL/SQL Code | `IMPR1110.PORT_CD_WHEN_VALIDATE_ITEM(P_PORT_CD => :P1110_PORT_CD, P_PORT_NAME => :P1110_PORT_NAME, P_SDP_PORT_STATUS => :P1110_SDP_PORT_STATUS);` | P1110_PORT_CD | P1110_PORT_NAME, P1110_SDP_PORT_STATUS | No | - | IMPORTERS.PORT_CD.WHEN-VALIDATE-ITEM |
| 2 | `HQ_IMPR_NBR WHEN-VALIDATE-ITEM` | Change | Item P1110_HQ_IMPR_NBR | - | 1 | FOS - Execute PL/SQL Code | `IMPR1110.HQ_IMPR_NBR_WHEN_VALIDATE_ITEM();` | - | - | No | - | IMPORTERS.HQ_IMPR_NBR.POST-CHANGE |
| 3 | `IMPR_NBR WHEN-VALIDATE-ITEM` | Change | Item P1110_IMPR_NBR | - | 1 | FOS - Execute PL/SQL Code | `IMPR1110.IMPR_NBR_WHEN_VALIDATE_ITEM(P_PORT_CD => :P1110_PORT_CD, P_IMPR_NBR => :P1110_IMPR_NBR);` | P1110_PORT_CD, P1110_IMPR_NBR | - | No | - | IMPORTERS.IMPR_NBR.WHEN-VALIDATE-ITEM |
| - | - | - | - | - | 2 | Submit Page | request EXECUTE_QUERY | - | - | - | runs only when the FOS succeeded (the number exists) - Forms :GLOBAL.EXEC_QUERY_NOW -> EXECUTE_QUERY | - |
| 4 | `IMPR_TYPE_CD WHEN-VALIDATE-ITEM` | Change | Item P1110_IMPR_TYPE_CD | - | 1 | FOS - Execute PL/SQL Code | `IMPR1110.IMPR_TYPE_CD_LOV_RETURN(P_IMPR_TYPE_CD => :P1110_IMPR_TYPE_CD, P_BUS_ID_TYPE_CD => :P1110_BUS_ID_TYPE_CD, P_CTRY_CD => :P1110_CTRY_CD, P_ADD_CTRY_CD => :P1110_ADD_CTRY_CD, P_IMPR_TYPE_NAME => :P1110_IMPR_TYPE_NAME, P_BUS_ID_TYPE_NAME => :P1110_BUS_ID_TYPE_NAME, P_CRTY_ARBC_NAME => :P1110_CRTY_ARBC_NAME, P_ADD_CRTY_ARBC_NAME => :P1110_ADD_CRTY_ARBC_NAME);` | P1110_IMPR_TYPE_CD, P1110_BUS_ID_TYPE_CD, P1110_CTRY_CD, P1110_ADD_CTRY_CD | P1110_IMPR_TYPE_CD, P1110_BUS_ID_TYPE_CD, P1110_CTRY_CD, P1110_ADD_CTRY_CD, P1110_IMPR_TYPE_NAME, P1110_BUS_ID_TYPE_NAME, P1110_CRTY_ARBC_NAME, P1110_ADD_CRTY_ARBC_NAME | No | KEY-LISTVAL post-select logic (TODO-VERIFY: Forms runs it only after an LOV pick) | IMPORTERS.IMPR_TYPE_CD.POST-CHANGE + WHEN-VALIDATE-ITEM |
| - | - | - | - | - | 2 | FOS - Execute PL/SQL Code | `IMPR1110.IMPR_TYPE_CD_VALIDATE_ITEM(P_IMPR_NBR => :P1110_IMPR_NBR, P_IMPR_TYPE_CD => :P1110_IMPR_TYPE_CD, P_BUS_ID_TYPE_CD => :P1110_BUS_ID_TYPE_CD, P_BUS_ID => :P1110_BUS_ID, P_CTRY_CD => :P1110_CTRY_CD, P_ADD_CTRY_CD => :P1110_ADD_CTRY_CD, P_IMPR_TYPE_NAME => :P1110_IMPR_TYPE_NAME, P_BUS_ID_TYPE_NAME => :P1110_BUS_ID_TYPE_NAME, P_CRTY_ARBC_NAME => :P1110_CRTY_ARBC_NAME, P_ITIDT_NOTE => :P1110_ITIDT_NOTE, P_STATUS => :P1110_STATUS, P_ADD_CRTY_ARBC_NAME => :P1110_ADD_CRTY_ARBC_NAME, P_CURR_PORT_CD => :P_CURR_PORT_CD);` | P1110_IMPR_NBR, P1110_IMPR_TYPE_CD, P1110_BUS_ID_TYPE_CD, P1110_BUS_ID, P1110_CTRY_CD, P1110_ADD_CTRY_CD, P_CURR_PORT_CD | P1110_IMPR_TYPE_CD, P1110_BUS_ID_TYPE_CD, P1110_BUS_ID, P1110_CTRY_CD, P1110_ADD_CTRY_CD, P1110_IMPR_TYPE_NAME, P1110_BUS_ID_TYPE_NAME, P1110_CRTY_ARBC_NAME, P1110_ITIDT_NOTE, P1110_STATUS, P1110_ADD_CRTY_ARBC_NAME | - | - | - |
| - | - | - | - | - | 3 | FOS - Execute PL/SQL Code (change events ON) | `IMPR1110.READ_ONLY_FLAGS(P_IMPR_NBR => :P1110_IMPR_NBR, P_CODE => :P1110_P_CODE, P_PRSNL_IMPR => :P1110_P_PRSNL_IMPR, P_IMPR_TYPE_CD => :P1110_IMPR_TYPE_CD, P_BUS_ID_TYPE_CD => :P1110_BUS_ID_TYPE_CD, P_COMM_RGSTRTN_TYPE => :P1110_COMM_RGSTRTN_TYPE, P_BUS_ID => :P1110_BUS_ID, P_BUS_ID_BRNCH => :P1110_BUS_ID_BRNCH, P_BUS_ID_EXPRD_DT => :P1110_BUS_ID_EXPRD_DT, P_IMPR_TEL_NBR => :P1110_IMPR_TEL_NBR, P_ACTIVITY => :P1110_ACTIVITY, IMPR_TYPE_CD_LOCKED => :P1110_IMPR_TYPE_CD_LOCKED, BUS_ID_EXPRD_DT_LOCKED => :P1110_BUS_ID_EXPRD_DT_LOCKED, COMM_RGSTRTN_TYPE_LOCKED => :P1110_COMM_RGSTRTN_TYPE_LOCKED, CITY_CODE_OF_ID_LOCKED => :P1110_CITY_CODE_OF_ID_LOCKED, BUS_ID_LOCKED => :P1110_BUS_ID_LOCKED, BRNH_CITY_CD_LOCKED => :P1110_BRNH_CITY_CD_LOCKED, BUS_ID_BRNCH_LOCKED => :P1110_BUS_ID_BRNCH_LOCKED, CTRY_CD_LOCKED => :P1110_CTRY_CD_LOCKED, ARBC_IMPR_NAME_LOCKED => :P1110_ARBC_IMPR_NAME_LOCKED, REGISTER_ITEMS_LOCKED => :P1110_REGISTER_ITEMS_LOCKED, IMPR_TEL_NBR_LOCKED => :P1110_IMPR_TEL_NBR_LOCKED, ACTIVITY_LOCKED => :P1110_ACTIVITY_LOCKED, B_ID_NBR_LOCKED => :P1110_B_ID_NBR_LOCKED, CAR_AGENT_FLAG_LOCKED => :P1110_CAR_AGENT_FLAG_LOCKED);` | P1110_IMPR_NBR, P1110_IMPR_TYPE_CD, P1110_BUS_ID_TYPE_CD, P1110_COMM_RGSTRTN_TYPE, P1110_BUS_ID, P1110_BUS_ID_BRNCH, P1110_BUS_ID_EXPRD_DT, P1110_IMPR_TEL_NBR, P1110_ACTIVITY | P1110_IMPR_TYPE_CD_LOCKED, P1110_BUS_ID_EXPRD_DT_LOCKED, P1110_COMM_RGSTRTN_TYPE_LOCKED, P1110_CITY_CODE_OF_ID_LOCKED, P1110_BUS_ID_LOCKED, P1110_BRNH_CITY_CD_LOCKED, P1110_BUS_ID_BRNCH_LOCKED, P1110_CTRY_CD_LOCKED, P1110_ARBC_IMPR_NAME_LOCKED, P1110_REGISTER_ITEMS_LOCKED, P1110_IMPR_TEL_NBR_LOCKED, P1110_ACTIVITY_LOCKED, P1110_B_ID_NBR_LOCKED, P1110_CAR_AGENT_FLAG_LOCKED | - | returns the P1110_<GROUP>_LOCKED flags; their change events run the READ ONLY DAs | - |
| 5 | `BUS_ID_EXPRD_DT WHEN-VALIDATE-ITEM` | Change | Item P1110_BUS_ID_EXPRD_DT | - | 1 | FOS - Execute PL/SQL Code | `IMPR1110.BUS_ID_EXPRD_DT_VALIDATE_ITEM(P_BUS_ID_EXPRD_DT => :P1110_BUS_ID_EXPRD_DT);` | P1110_BUS_ID_EXPRD_DT | - | No | - | IMPORTERS.BUS_ID_EXPRD_DT.WHEN-VALIDATE-ITEM |
| - | - | - | - | - | 2 | FOS - Execute PL/SQL Code (change events ON) | `IMPR1110.READ_ONLY_FLAGS(P_IMPR_NBR => :P1110_IMPR_NBR, P_CODE => :P1110_P_CODE, P_PRSNL_IMPR => :P1110_P_PRSNL_IMPR, P_IMPR_TYPE_CD => :P1110_IMPR_TYPE_CD, P_BUS_ID_TYPE_CD => :P1110_BUS_ID_TYPE_CD, P_COMM_RGSTRTN_TYPE => :P1110_COMM_RGSTRTN_TYPE, P_BUS_ID => :P1110_BUS_ID, P_BUS_ID_BRNCH => :P1110_BUS_ID_BRNCH, P_BUS_ID_EXPRD_DT => :P1110_BUS_ID_EXPRD_DT, P_IMPR_TEL_NBR => :P1110_IMPR_TEL_NBR, P_ACTIVITY => :P1110_ACTIVITY, IMPR_TYPE_CD_LOCKED => :P1110_IMPR_TYPE_CD_LOCKED, BUS_ID_EXPRD_DT_LOCKED => :P1110_BUS_ID_EXPRD_DT_LOCKED, COMM_RGSTRTN_TYPE_LOCKED => :P1110_COMM_RGSTRTN_TYPE_LOCKED, CITY_CODE_OF_ID_LOCKED => :P1110_CITY_CODE_OF_ID_LOCKED, BUS_ID_LOCKED => :P1110_BUS_ID_LOCKED, BRNH_CITY_CD_LOCKED => :P1110_BRNH_CITY_CD_LOCKED, BUS_ID_BRNCH_LOCKED => :P1110_BUS_ID_BRNCH_LOCKED, CTRY_CD_LOCKED => :P1110_CTRY_CD_LOCKED, ARBC_IMPR_NAME_LOCKED => :P1110_ARBC_IMPR_NAME_LOCKED, REGISTER_ITEMS_LOCKED => :P1110_REGISTER_ITEMS_LOCKED, IMPR_TEL_NBR_LOCKED => :P1110_IMPR_TEL_NBR_LOCKED, ACTIVITY_LOCKED => :P1110_ACTIVITY_LOCKED, B_ID_NBR_LOCKED => :P1110_B_ID_NBR_LOCKED, CAR_AGENT_FLAG_LOCKED => :P1110_CAR_AGENT_FLAG_LOCKED);` | P1110_IMPR_NBR, P1110_IMPR_TYPE_CD, P1110_BUS_ID_TYPE_CD, P1110_COMM_RGSTRTN_TYPE, P1110_BUS_ID, P1110_BUS_ID_BRNCH, P1110_BUS_ID_EXPRD_DT, P1110_IMPR_TEL_NBR, P1110_ACTIVITY | P1110_IMPR_TYPE_CD_LOCKED, P1110_BUS_ID_EXPRD_DT_LOCKED, P1110_COMM_RGSTRTN_TYPE_LOCKED, P1110_CITY_CODE_OF_ID_LOCKED, P1110_BUS_ID_LOCKED, P1110_BRNH_CITY_CD_LOCKED, P1110_BUS_ID_BRNCH_LOCKED, P1110_CTRY_CD_LOCKED, P1110_ARBC_IMPR_NAME_LOCKED, P1110_REGISTER_ITEMS_LOCKED, P1110_IMPR_TEL_NBR_LOCKED, P1110_ACTIVITY_LOCKED, P1110_B_ID_NBR_LOCKED, P1110_CAR_AGENT_FLAG_LOCKED | - | returns the P1110_<GROUP>_LOCKED flags; their change events run the READ ONLY DAs | - |
| 6 | `BUS_ID_TYPE_CD WHEN-VALIDATE-ITEM` | Change | Item P1110_BUS_ID_TYPE_CD | - | 1 | FOS - Execute PL/SQL Code | `IMPR1110.BUS_ID_TYPE_CD_VALIDATE_ITEM(P_IMPR_TYPE_CD => :P1110_IMPR_TYPE_CD, P_BUS_ID_TYPE_CD => :P1110_BUS_ID_TYPE_CD, P_CTRY_CD => :P1110_CTRY_CD, P_ADD_CTRY_CD => :P1110_ADD_CTRY_CD, P_CRTY_ARBC_NAME => :P1110_CRTY_ARBC_NAME, P_ADD_CRTY_ARBC_NAME => :P1110_ADD_CRTY_ARBC_NAME);` | P1110_IMPR_TYPE_CD, P1110_BUS_ID_TYPE_CD, P1110_CTRY_CD, P1110_ADD_CTRY_CD | P1110_CTRY_CD, P1110_ADD_CTRY_CD, P1110_CRTY_ARBC_NAME, P1110_ADD_CRTY_ARBC_NAME | No | - | IMPORTERS.BUS_ID_TYPE_CD.POST-CHANGE |
| - | - | - | - | - | 2 | FOS - Execute PL/SQL Code (change events ON) | `IMPR1110.READ_ONLY_FLAGS(P_IMPR_NBR => :P1110_IMPR_NBR, P_CODE => :P1110_P_CODE, P_PRSNL_IMPR => :P1110_P_PRSNL_IMPR, P_IMPR_TYPE_CD => :P1110_IMPR_TYPE_CD, P_BUS_ID_TYPE_CD => :P1110_BUS_ID_TYPE_CD, P_COMM_RGSTRTN_TYPE => :P1110_COMM_RGSTRTN_TYPE, P_BUS_ID => :P1110_BUS_ID, P_BUS_ID_BRNCH => :P1110_BUS_ID_BRNCH, P_BUS_ID_EXPRD_DT => :P1110_BUS_ID_EXPRD_DT, P_IMPR_TEL_NBR => :P1110_IMPR_TEL_NBR, P_ACTIVITY => :P1110_ACTIVITY, IMPR_TYPE_CD_LOCKED => :P1110_IMPR_TYPE_CD_LOCKED, BUS_ID_EXPRD_DT_LOCKED => :P1110_BUS_ID_EXPRD_DT_LOCKED, COMM_RGSTRTN_TYPE_LOCKED => :P1110_COMM_RGSTRTN_TYPE_LOCKED, CITY_CODE_OF_ID_LOCKED => :P1110_CITY_CODE_OF_ID_LOCKED, BUS_ID_LOCKED => :P1110_BUS_ID_LOCKED, BRNH_CITY_CD_LOCKED => :P1110_BRNH_CITY_CD_LOCKED, BUS_ID_BRNCH_LOCKED => :P1110_BUS_ID_BRNCH_LOCKED, CTRY_CD_LOCKED => :P1110_CTRY_CD_LOCKED, ARBC_IMPR_NAME_LOCKED => :P1110_ARBC_IMPR_NAME_LOCKED, REGISTER_ITEMS_LOCKED => :P1110_REGISTER_ITEMS_LOCKED, IMPR_TEL_NBR_LOCKED => :P1110_IMPR_TEL_NBR_LOCKED, ACTIVITY_LOCKED => :P1110_ACTIVITY_LOCKED, B_ID_NBR_LOCKED => :P1110_B_ID_NBR_LOCKED, CAR_AGENT_FLAG_LOCKED => :P1110_CAR_AGENT_FLAG_LOCKED);` | P1110_IMPR_NBR, P1110_IMPR_TYPE_CD, P1110_BUS_ID_TYPE_CD, P1110_COMM_RGSTRTN_TYPE, P1110_BUS_ID, P1110_BUS_ID_BRNCH, P1110_BUS_ID_EXPRD_DT, P1110_IMPR_TEL_NBR, P1110_ACTIVITY | P1110_IMPR_TYPE_CD_LOCKED, P1110_BUS_ID_EXPRD_DT_LOCKED, P1110_COMM_RGSTRTN_TYPE_LOCKED, P1110_CITY_CODE_OF_ID_LOCKED, P1110_BUS_ID_LOCKED, P1110_BRNH_CITY_CD_LOCKED, P1110_BUS_ID_BRNCH_LOCKED, P1110_CTRY_CD_LOCKED, P1110_ARBC_IMPR_NAME_LOCKED, P1110_REGISTER_ITEMS_LOCKED, P1110_IMPR_TEL_NBR_LOCKED, P1110_ACTIVITY_LOCKED, P1110_B_ID_NBR_LOCKED, P1110_CAR_AGENT_FLAG_LOCKED | - | returns the P1110_<GROUP>_LOCKED flags; their change events run the READ ONLY DAs | - |
| 7 | `CITY_CODE_OF_ID WHEN-VALIDATE-ITEM` | Change | Item P1110_CITY_CODE_OF_ID | - | 1 | FOS - Execute PL/SQL Code | `IMPR1110.CITY_CODE_OF_ID_VALIDATE_ITEM(P_CITY_CODE_OF_ID => :P1110_CITY_CODE_OF_ID, P_CTRY_CD_OF_ID => :P1110_CTRY_CD_OF_ID, P_ID_CITY_NAME => :P1110_ID_CITY_NAME, P_ID_MINS_COMM_CD => :P1110_ID_MINS_COMM_CD, P_L_CT_CITY_STATUS2 => :P1110_L_CT_CITY_STATUS2, P_ROW_ID => :P1110_ROW_ID);` | P1110_CITY_CODE_OF_ID | P1110_CITY_CODE_OF_ID, P1110_CTRY_CD_OF_ID, P1110_ID_CITY_NAME, P1110_ID_MINS_COMM_CD, P1110_L_CT_CITY_STATUS2 | No | - | IMPORTERS.CITY_CODE_OF_ID.WHEN-VALIDATE-ITEM |
| 8 | `BUS_ID WHEN-VALIDATE-ITEM` | Change | Item P1110_BUS_ID | - | 1 | FOS - Execute PL/SQL Code | `:P1110_CONFIRM_TEXT := IMPR1110.BUS_ID_SUSPENDED_CONFIRM_TEXT(P_PORT_CD => :P1110_PORT_CD, P_IMPR_NBR => :P1110_IMPR_NBR, P_BUS_ID_TYPE_CD => :P1110_BUS_ID_TYPE_CD, P_COMM_RGSTRTN_TYPE => :P1110_COMM_RGSTRTN_TYPE, P_BUS_ID => :P1110_BUS_ID, P_BUS_ID_BRNCH => :P1110_BUS_ID_BRNCH, P_CTRY_CD => :P1110_CTRY_CD);` | P1110_PORT_CD, P1110_IMPR_NBR, P1110_BUS_ID_TYPE_CD, P1110_COMM_RGSTRTN_TYPE, P1110_BUS_ID, P1110_BUS_ID_BRNCH, P1110_CTRY_CD | P1110_CONFIRM_TEXT | No | Items to Return: P1110_CONFIRM_TEXT (function result) | IMPORTERS.BUS_ID.POST-CHANGE + WHEN-VALIDATE-ITEM |
| - | - | - | - | - | 2 | Execute JavaScript Code | `var t = $v('P1110_CONFIRM_TEXT'), go = function (a) { $s('P1110_SUSPEND_ANSWER', a); apex.event.trigger('#P1110_BUS_ID', 'impr1110-bus-id-validate'); };<br>if (t) { apex.message.confirm(t, function (ok) { go(ok ? '1' : '2'); }); } else { go('1'); }` | - | - | - | WARNING alert with a text computed on the server (importer number); the answer is needed before the WHEN-VALIDATE-ITEM code runs | - |
| 9 | `BUS_ID WHEN-VALIDATE-ITEM CONFIRMED` | Custom: impr1110-bus-id-validate | Item P1110_BUS_ID | - | 1 | FOS - Execute PL/SQL Code | `IMPR1110.BUS_ID_WHEN_VALIDATE_ITEM(P_PORT_CD => :P1110_PORT_CD, P_IMPR_NBR => :P1110_IMPR_NBR, P_BUS_ID_STATUS => :P1110_BUS_ID_STATUS, P_IMPR_TYPE_CD => :P1110_IMPR_TYPE_CD, P_BUS_ID_EXPRD_DT => :P1110_BUS_ID_EXPRD_DT, P_BUS_ID_TYPE_CD => :P1110_BUS_ID_TYPE_CD, P_COMM_RGSTRTN_TYPE => :P1110_COMM_RGSTRTN_TYPE, P_CITY_CODE_OF_ID => :P1110_CITY_CODE_OF_ID, P_BUS_ID => :P1110_BUS_ID, P_BUS_ID_BRNCH => :P1110_BUS_ID_BRNCH, P_CTRY_CD => :P1110_CTRY_CD, P_ARBC_IMPR_NAME => :P1110_ARBC_IMPR_NAME, P_IMPR_NAME_STD => :P1110_IMPR_NAME_STD, P_LST_TRAN_DT => :P1110_LST_TRAN_DT, P_IMPR_ADDRESS => :P1110_IMPR_ADDRESS, P_BUS_ID_ISSUE_DT => :P1110_BUS_ID_ISSUE_DT, P_IMPR_POB_NBR => :P1110_IMPR_POB_NBR, P_IMPR_ZIP_CD => :P1110_IMPR_ZIP_CD, P_IMPR_TEL_NBR => :P1110_IMPR_TEL_NBR, P_IMPR_FAX_NBR => :P1110_IMPR_FAX_NBR, P_IMPR_TELEX_NBR => :P1110_IMPR_TELEX_NBR, P_CTRY_CD_OF_ID => :P1110_CTRY_CD_OF_ID, P_ACTIVITY => :P1110_ACTIVITY, P_CREATION_FLAG => :P1110_CREATION_FLAG, P_ID_CITY_NAME => :P1110_ID_CITY_NAME, P_ID_MINS_COMM_CD => :P1110_ID_MINS_COMM_CD, P_BRNH_CITY_CD => :P1110_BRNH_CITY_CD, P_BRNH_CITY_NAME => :P1110_BRNH_CITY_NAME, P_B_ID_NBR => :P1110_B_ID_NBR, P_ROW_ID => :P1110_ROW_ID, P_ANSWER => :P1110_ANSWER, P_SUSPEND_ANSWER => :P1110_SUSPEND_ANSWER);` | P1110_PORT_CD, P1110_IMPR_NBR, P1110_IMPR_TYPE_CD, P1110_BUS_ID_EXPRD_DT, P1110_BUS_ID_TYPE_CD, P1110_COMM_RGSTRTN_TYPE, P1110_CITY_CODE_OF_ID, P1110_BUS_ID, P1110_BUS_ID_BRNCH, P1110_CTRY_CD, P1110_ARBC_IMPR_NAME, P1110_IMPR_ADDRESS, P1110_IMPR_POB_NBR, P1110_IMPR_ZIP_CD, P1110_IMPR_TEL_NBR, P1110_IMPR_FAX_NBR, P1110_IMPR_TELEX_NBR, P1110_ACTIVITY, P1110_BRNH_CITY_CD, P1110_B_ID_NBR, P1110_ANSWER, P1110_SUSPEND_ANSWER | P1110_BUS_ID_STATUS, P1110_BUS_ID_EXPRD_DT, P1110_CITY_CODE_OF_ID, P1110_BUS_ID, P1110_ARBC_IMPR_NAME, P1110_IMPR_NAME_STD, P1110_LST_TRAN_DT, P1110_IMPR_ADDRESS, P1110_BUS_ID_ISSUE_DT, P1110_IMPR_POB_NBR, P1110_IMPR_ZIP_CD, P1110_IMPR_TEL_NBR, P1110_IMPR_FAX_NBR, P1110_IMPR_TELEX_NBR, P1110_ACTIVITY, P1110_CREATION_FLAG, P1110_ID_CITY_NAME, P1110_ID_MINS_COMM_CD, P1110_BRNH_CITY_CD, P1110_BRNH_CITY_NAME, P1110_B_ID_NBR | No | - | IMPORTERS.BUS_ID.POST-CHANGE + WHEN-VALIDATE-ITEM (after the suspended-importer question) |
| - | - | - | - | - | 2 | FOS - Execute PL/SQL Code (change events ON) | `IMPR1110.READ_ONLY_FLAGS(P_IMPR_NBR => :P1110_IMPR_NBR, P_CODE => :P1110_P_CODE, P_PRSNL_IMPR => :P1110_P_PRSNL_IMPR, P_IMPR_TYPE_CD => :P1110_IMPR_TYPE_CD, P_BUS_ID_TYPE_CD => :P1110_BUS_ID_TYPE_CD, P_COMM_RGSTRTN_TYPE => :P1110_COMM_RGSTRTN_TYPE, P_BUS_ID => :P1110_BUS_ID, P_BUS_ID_BRNCH => :P1110_BUS_ID_BRNCH, P_BUS_ID_EXPRD_DT => :P1110_BUS_ID_EXPRD_DT, P_IMPR_TEL_NBR => :P1110_IMPR_TEL_NBR, P_ACTIVITY => :P1110_ACTIVITY, IMPR_TYPE_CD_LOCKED => :P1110_IMPR_TYPE_CD_LOCKED, BUS_ID_EXPRD_DT_LOCKED => :P1110_BUS_ID_EXPRD_DT_LOCKED, COMM_RGSTRTN_TYPE_LOCKED => :P1110_COMM_RGSTRTN_TYPE_LOCKED, CITY_CODE_OF_ID_LOCKED => :P1110_CITY_CODE_OF_ID_LOCKED, BUS_ID_LOCKED => :P1110_BUS_ID_LOCKED, BRNH_CITY_CD_LOCKED => :P1110_BRNH_CITY_CD_LOCKED, BUS_ID_BRNCH_LOCKED => :P1110_BUS_ID_BRNCH_LOCKED, CTRY_CD_LOCKED => :P1110_CTRY_CD_LOCKED, ARBC_IMPR_NAME_LOCKED => :P1110_ARBC_IMPR_NAME_LOCKED, REGISTER_ITEMS_LOCKED => :P1110_REGISTER_ITEMS_LOCKED, IMPR_TEL_NBR_LOCKED => :P1110_IMPR_TEL_NBR_LOCKED, ACTIVITY_LOCKED => :P1110_ACTIVITY_LOCKED, B_ID_NBR_LOCKED => :P1110_B_ID_NBR_LOCKED, CAR_AGENT_FLAG_LOCKED => :P1110_CAR_AGENT_FLAG_LOCKED);` | P1110_IMPR_NBR, P1110_IMPR_TYPE_CD, P1110_BUS_ID_TYPE_CD, P1110_COMM_RGSTRTN_TYPE, P1110_BUS_ID, P1110_BUS_ID_BRNCH, P1110_BUS_ID_EXPRD_DT, P1110_IMPR_TEL_NBR, P1110_ACTIVITY | P1110_IMPR_TYPE_CD_LOCKED, P1110_BUS_ID_EXPRD_DT_LOCKED, P1110_COMM_RGSTRTN_TYPE_LOCKED, P1110_CITY_CODE_OF_ID_LOCKED, P1110_BUS_ID_LOCKED, P1110_BRNH_CITY_CD_LOCKED, P1110_BUS_ID_BRNCH_LOCKED, P1110_CTRY_CD_LOCKED, P1110_ARBC_IMPR_NAME_LOCKED, P1110_REGISTER_ITEMS_LOCKED, P1110_IMPR_TEL_NBR_LOCKED, P1110_ACTIVITY_LOCKED, P1110_B_ID_NBR_LOCKED, P1110_CAR_AGENT_FLAG_LOCKED | - | returns the P1110_<GROUP>_LOCKED flags; their change events run the READ ONLY DAs | - |
| 10 | `BRNH_CITY_CD WHEN-VALIDATE-ITEM` | Change | Item P1110_BRNH_CITY_CD | - | 1 | FOS - Execute PL/SQL Code | `IMPR1110.BRNH_CITY_CD_VALIDATE_ITEM(P_CTRY_CD_OF_ID => :P1110_CTRY_CD_OF_ID, P_BRNH_CITY_CD => :P1110_BRNH_CITY_CD, P_BRNH_CITY_NAME => :P1110_BRNH_CITY_NAME);` | P1110_BRNH_CITY_CD | P1110_BRNH_CITY_NAME | No | - | IMPORTERS.BRNH_CITY_CD.WHEN-VALIDATE-ITEM |
| 11 | `BUS_ID_BRNCH WHEN-VALIDATE-ITEM` | Change | Item P1110_BUS_ID_BRNCH | - | 1 | FOS - Execute PL/SQL Code | `IMPR1110.BUS_ID_BRNCH_VALIDATE_ITEM(P_PORT_CD => :P1110_PORT_CD, P_IMPR_NBR => :P1110_IMPR_NBR, P_BUS_ID_STATUS => :P1110_BUS_ID_STATUS, P_IMPR_TYPE_CD => :P1110_IMPR_TYPE_CD, P_BUS_ID_EXPRD_DT => :P1110_BUS_ID_EXPRD_DT, P_BUS_ID_TYPE_CD => :P1110_BUS_ID_TYPE_CD, P_COMM_RGSTRTN_TYPE => :P1110_COMM_RGSTRTN_TYPE, P_CITY_CODE_OF_ID => :P1110_CITY_CODE_OF_ID, P_BUS_ID => :P1110_BUS_ID, P_BUS_ID_BRNCH => :P1110_BUS_ID_BRNCH, P_CTRY_CD => :P1110_CTRY_CD, P_ARBC_IMPR_NAME => :P1110_ARBC_IMPR_NAME, P_IMPR_NAME_STD => :P1110_IMPR_NAME_STD, P_LST_TRAN_DT => :P1110_LST_TRAN_DT, P_IMPR_ADDRESS => :P1110_IMPR_ADDRESS, P_BUS_ID_ISSUE_DT => :P1110_BUS_ID_ISSUE_DT, P_IMPR_POB_NBR => :P1110_IMPR_POB_NBR, P_IMPR_ZIP_CD => :P1110_IMPR_ZIP_CD, P_IMPR_TEL_NBR => :P1110_IMPR_TEL_NBR, P_IMPR_FAX_NBR => :P1110_IMPR_FAX_NBR, P_IMPR_TELEX_NBR => :P1110_IMPR_TELEX_NBR, P_CTRY_CD_OF_ID => :P1110_CTRY_CD_OF_ID, P_ACTIVITY => :P1110_ACTIVITY, P_CREATION_FLAG => :P1110_CREATION_FLAG, P_ID_CITY_NAME => :P1110_ID_CITY_NAME, P_BRNH_ID_MINS_COMM_CD => :P1110_BRNH_ID_MINS_COMM_CD, P_BRNH_CITY_CD => :P1110_BRNH_CITY_CD, P_BRNH_CITY_NAME => :P1110_BRNH_CITY_NAME, P_ROW_ID => :P1110_ROW_ID, P_CODE => :P1110_P_CODE, P_ANSWER => :P1110_ANSWER);` | P1110_PORT_CD, P1110_IMPR_NBR, P1110_IMPR_TYPE_CD, P1110_BUS_ID_EXPRD_DT, P1110_BUS_ID_TYPE_CD, P1110_COMM_RGSTRTN_TYPE, P1110_CITY_CODE_OF_ID, P1110_BUS_ID, P1110_BUS_ID_BRNCH, P1110_CTRY_CD, P1110_ARBC_IMPR_NAME, P1110_IMPR_ADDRESS, P1110_IMPR_POB_NBR, P1110_IMPR_ZIP_CD, P1110_IMPR_TEL_NBR, P1110_IMPR_FAX_NBR, P1110_IMPR_TELEX_NBR, P1110_ACTIVITY, P1110_BRNH_CITY_CD, P1110_ANSWER | P1110_BUS_ID_STATUS, P1110_BUS_ID_EXPRD_DT, P1110_CITY_CODE_OF_ID, P1110_BUS_ID_BRNCH, P1110_ARBC_IMPR_NAME, P1110_IMPR_NAME_STD, P1110_LST_TRAN_DT, P1110_IMPR_ADDRESS, P1110_BUS_ID_ISSUE_DT, P1110_IMPR_POB_NBR, P1110_IMPR_ZIP_CD, P1110_IMPR_TEL_NBR, P1110_IMPR_FAX_NBR, P1110_IMPR_TELEX_NBR, P1110_ACTIVITY, P1110_CREATION_FLAG, P1110_ID_CITY_NAME, P1110_BRNH_ID_MINS_COMM_CD, P1110_BRNH_CITY_CD, P1110_BRNH_CITY_NAME | No | - | IMPORTERS.BUS_ID_BRNCH.POST-CHANGE + WHEN-VALIDATE-ITEM |
| - | - | - | - | - | 2 | FOS - Execute PL/SQL Code (change events ON) | `IMPR1110.READ_ONLY_FLAGS(P_IMPR_NBR => :P1110_IMPR_NBR, P_CODE => :P1110_P_CODE, P_PRSNL_IMPR => :P1110_P_PRSNL_IMPR, P_IMPR_TYPE_CD => :P1110_IMPR_TYPE_CD, P_BUS_ID_TYPE_CD => :P1110_BUS_ID_TYPE_CD, P_COMM_RGSTRTN_TYPE => :P1110_COMM_RGSTRTN_TYPE, P_BUS_ID => :P1110_BUS_ID, P_BUS_ID_BRNCH => :P1110_BUS_ID_BRNCH, P_BUS_ID_EXPRD_DT => :P1110_BUS_ID_EXPRD_DT, P_IMPR_TEL_NBR => :P1110_IMPR_TEL_NBR, P_ACTIVITY => :P1110_ACTIVITY, IMPR_TYPE_CD_LOCKED => :P1110_IMPR_TYPE_CD_LOCKED, BUS_ID_EXPRD_DT_LOCKED => :P1110_BUS_ID_EXPRD_DT_LOCKED, COMM_RGSTRTN_TYPE_LOCKED => :P1110_COMM_RGSTRTN_TYPE_LOCKED, CITY_CODE_OF_ID_LOCKED => :P1110_CITY_CODE_OF_ID_LOCKED, BUS_ID_LOCKED => :P1110_BUS_ID_LOCKED, BRNH_CITY_CD_LOCKED => :P1110_BRNH_CITY_CD_LOCKED, BUS_ID_BRNCH_LOCKED => :P1110_BUS_ID_BRNCH_LOCKED, CTRY_CD_LOCKED => :P1110_CTRY_CD_LOCKED, ARBC_IMPR_NAME_LOCKED => :P1110_ARBC_IMPR_NAME_LOCKED, REGISTER_ITEMS_LOCKED => :P1110_REGISTER_ITEMS_LOCKED, IMPR_TEL_NBR_LOCKED => :P1110_IMPR_TEL_NBR_LOCKED, ACTIVITY_LOCKED => :P1110_ACTIVITY_LOCKED, B_ID_NBR_LOCKED => :P1110_B_ID_NBR_LOCKED, CAR_AGENT_FLAG_LOCKED => :P1110_CAR_AGENT_FLAG_LOCKED);` | P1110_IMPR_NBR, P1110_IMPR_TYPE_CD, P1110_BUS_ID_TYPE_CD, P1110_COMM_RGSTRTN_TYPE, P1110_BUS_ID, P1110_BUS_ID_BRNCH, P1110_BUS_ID_EXPRD_DT, P1110_IMPR_TEL_NBR, P1110_ACTIVITY | P1110_IMPR_TYPE_CD_LOCKED, P1110_BUS_ID_EXPRD_DT_LOCKED, P1110_COMM_RGSTRTN_TYPE_LOCKED, P1110_CITY_CODE_OF_ID_LOCKED, P1110_BUS_ID_LOCKED, P1110_BRNH_CITY_CD_LOCKED, P1110_BUS_ID_BRNCH_LOCKED, P1110_CTRY_CD_LOCKED, P1110_ARBC_IMPR_NAME_LOCKED, P1110_REGISTER_ITEMS_LOCKED, P1110_IMPR_TEL_NBR_LOCKED, P1110_ACTIVITY_LOCKED, P1110_B_ID_NBR_LOCKED, P1110_CAR_AGENT_FLAG_LOCKED | - | returns the P1110_<GROUP>_LOCKED flags; their change events run the READ ONLY DAs | - |
| 12 | `CTRY_CD WHEN-VALIDATE-ITEM` | Change | Item P1110_CTRY_CD | - | 1 | FOS - Execute PL/SQL Code | `IMPR1110.CTRY_CD_WHEN_VALIDATE_ITEM(P_IMPR_TYPE_CD => :P1110_IMPR_TYPE_CD, P_BUS_ID_TYPE_CD => :P1110_BUS_ID_TYPE_CD, P_CTRY_CD => :P1110_CTRY_CD, P_CTRY_CD_OF_ID => :P1110_CTRY_CD_OF_ID, P_CRTY_ARBC_NAME => :P1110_CRTY_ARBC_NAME, P_CTRY_CTRY_STATUS => :P1110_CTRY_CTRY_STATUS);` | P1110_IMPR_TYPE_CD, P1110_BUS_ID_TYPE_CD, P1110_CTRY_CD | P1110_CTRY_CD_OF_ID, P1110_CRTY_ARBC_NAME, P1110_CTRY_CTRY_STATUS | No | - | IMPORTERS.CTRY_CD.WHEN-VALIDATE-ITEM |
| 13 | `IMPR_EXPR_TYPE WHEN-VALIDATE-ITEM` | Change | Item P1110_IMPR_EXPR_TYPE | - | 1 | FOS - Execute PL/SQL Code | `IMPR1110.IMPR_EXPR_TYPE_VALIDATE_ITEM();` | - | - | No | - | IMPORTERS.IMPR_EXPR_TYPE.POST-CHANGE |
| 14 | `ARBC_IMPR_NAME WHEN-VALIDATE-ITEM` | Change | Item P1110_ARBC_IMPR_NAME | - | 1 | FOS - Execute PL/SQL Code | `IMPR1110.ARBC_IMPR_NAME_VALIDATE_ITEM(P_ARBC_IMPR_NAME => :P1110_ARBC_IMPR_NAME, P_IMPR_NAME_STD => :P1110_IMPR_NAME_STD);` | P1110_ARBC_IMPR_NAME | P1110_ARBC_IMPR_NAME, P1110_IMPR_NAME_STD | No | - | IMPORTERS.ARBC_IMPR_NAME.WHEN-VALIDATE-ITEM |
| 15 | `ENG_IMPR_NAME WHEN-VALIDATE-ITEM` | Change | Item P1110_ENG_IMPR_NAME | - | 1 | FOS - Execute PL/SQL Code | `IMPR1110.ENG_IMPR_NAME_VALIDATE_ITEM(P_ENG_IMPR_NAME => :P1110_ENG_IMPR_NAME);` | P1110_ENG_IMPR_NAME | P1110_ENG_IMPR_NAME | No | - | IMPORTERS.ENG_IMPR_NAME.WHEN-VALIDATE-ITEM |
| 16 | `BUS_ID_ISSUE_DT WHEN-VALIDATE-ITEM` | Change | Item P1110_BUS_ID_ISSUE_DT | - | 1 | FOS - Execute PL/SQL Code | `IMPR1110.BUS_ID_ISSUE_DT_VALIDATE_ITEM(P_BUS_ID_ISSUE_DT => :P1110_BUS_ID_ISSUE_DT);` | - | - | No | - | IMPORTERS.BUS_ID_ISSUE_DT.WHEN-VALIDATE-ITEM |
| 17 | `IMPR_NBR_PARENT WHEN-VALIDATE-ITEM` | Change | Item P1110_IMPR_NBR_PARENT | - | 1 | FOS - Execute PL/SQL Code | `IMPR1110.IMPR_NBR_PARENT_VALIDATE_ITEM(P_IMPR_NBR_PARENT => :P1110_IMPR_NBR_PARENT, P_IMPR_NAME_PARENT => :P1110_IMPR_NAME_PARENT);` | P1110_IMPR_NBR_PARENT | P1110_IMPR_NAME_PARENT | No | - | IMPORTERS.IMPR_NBR_PARENT.WHEN-VALIDATE-ITEM |
| 18 | `ADD_CTRY_CD WHEN-VALIDATE-ITEM` | Change | Item P1110_ADD_CTRY_CD | - | 1 | FOS - Execute PL/SQL Code | `IMPR1110.ADD_CTRY_CD_WHEN_VALIDATE_ITEM(P_ADD_CTRY_CD => :P1110_ADD_CTRY_CD, P_CITY_CODE => :P1110_CITY_CODE, P_ADD_CRTY_ARBC_NAME => :P1110_ADD_CRTY_ARBC_NAME, P_CITY_NAME => :P1110_CITY_NAME, P_L_CT_CITY_STATUS => :P1110_L_CT_CITY_STATUS);` | P1110_ADD_CTRY_CD, P1110_CITY_CODE | P1110_ADD_CRTY_ARBC_NAME, P1110_CITY_NAME, P1110_L_CT_CITY_STATUS | No | - | IMPORTERS.ADD_CTRY_CD.WHEN-VALIDATE-ITEM |
| 19 | `CITY_CODE WHEN-VALIDATE-ITEM` | Change | Item P1110_CITY_CODE | - | 1 | FOS - Execute PL/SQL Code | `IMPR1110.CITY_CODE_WHEN_VALIDATE_ITEM(P_ADD_CTRY_CD => :P1110_ADD_CTRY_CD, P_CITY_CODE => :P1110_CITY_CODE, P_ADD_CRTY_ARBC_NAME => :P1110_ADD_CRTY_ARBC_NAME, P_CITY_NAME => :P1110_CITY_NAME, P_L_CT_CITY_STATUS => :P1110_L_CT_CITY_STATUS);` | P1110_ADD_CTRY_CD, P1110_CITY_CODE | P1110_ADD_CRTY_ARBC_NAME, P1110_CITY_NAME, P1110_L_CT_CITY_STATUS | No | - | IMPORTERS.CITY_CODE.WHEN-VALIDATE-ITEM |
| 20 | `IMPR_TEL_NBR WHEN-VALIDATE-ITEM` | Change | Item P1110_IMPR_TEL_NBR | - | 1 | FOS - Execute PL/SQL Code | `IMPR1110.IMPR_TEL_NBR_VALIDATE_ITEM(P_IMPR_TEL_NBR => :P1110_IMPR_TEL_NBR);` | P1110_IMPR_TEL_NBR | - | No | - | IMPORTERS.IMPR_TEL_NBR.WHEN-VALIDATE-ITEM |
| 21 | `B_EMAIL WHEN-VALIDATE-ITEM` | Change | Item P1110_B_EMAIL | - | 1 | FOS - Execute PL/SQL Code | `IMPR1110.B_EMAIL_WHEN_VALIDATE_ITEM(P_PORT_CD => :P1110_PORT_CD, P_B_EMAIL => :P1110_B_EMAIL, P_CURR_PORT_CD => :P_CURR_PORT_CD);` | P1110_PORT_CD, P1110_B_EMAIL, P_CURR_PORT_CD | P1110_PORT_CD | No | - | IMPORTERS.B_EMAIL.POST-CHANGE + WHEN-VALIDATE-ITEM |
| 22 | `EMAIL WHEN-VALIDATE-ITEM` | Change | Item P1110_EMAIL | - | 1 | FOS - Execute PL/SQL Code | `IMPR1110.EMAIL_WHEN_VALIDATE_ITEM(P_EMAIL => :P1110_EMAIL);` | - | - | No | - | IMPORTERS.EMAIL.WHEN-VALIDATE-ITEM |
| 23 | `B_MOBILE_NO WHEN-VALIDATE-ITEM` | Change | Item P1110_B_MOBILE_NO | - | 1 | FOS - Execute PL/SQL Code | `IMPR1110.B_MOBILE_NO_WHEN_VALIDATE_ITEM(P_PORT_CD => :P1110_PORT_CD, P_IMPR_NBR => :P1110_IMPR_NBR, P_B_MOBILE_NO => :P1110_B_MOBILE_NO, P_CURR_PORT_CD => :P_CURR_PORT_CD);` | P1110_PORT_CD, P1110_IMPR_NBR, P1110_B_MOBILE_NO, P_CURR_PORT_CD | P1110_PORT_CD | No | - | IMPORTERS.B_MOBILE_NO.POST-CHANGE + WHEN-VALIDATE-ITEM |
| 24 | `BANK_IBAN WHEN-VALIDATE-ITEM` | Change | Item P1110_BANK_IBAN | - | 1 | FOS - Execute PL/SQL Code | `IMPR1110.BANK_IBAN_WHEN_VALIDATE_ITEM(P_BANK_IBAN => :P1110_BANK_IBAN);` | P1110_BANK_IBAN | P1110_BANK_IBAN | No | - | IMPORTERS.BANK_IBAN.WHEN-VALIDATE-ITEM |
| 25 | `B_ID_NBR WHEN-VALIDATE-ITEM` | Change | Item P1110_B_ID_NBR | - | 1 | FOS - Execute PL/SQL Code | `IMPR1110.B_ID_NBR_WHEN_VALIDATE_ITEM(P_PORT_CD => :P1110_PORT_CD, P_B_ID_NBR => :P1110_B_ID_NBR, P_CURR_PORT_CD => :P_CURR_PORT_CD);` | P1110_PORT_CD, P1110_B_ID_NBR, P_CURR_PORT_CD | P1110_PORT_CD | No | - | IMPORTERS.B_ID_NBR.POST-CHANGE + WHEN-VALIDATE-ITEM |
| 26 | `CTRY_CD_OF_ID WHEN-VALIDATE-ITEM` | Change | Item P1110_CTRY_CD_OF_ID | - | 1 | FOS - Execute PL/SQL Code | `IMPR1110.CTRY_CD_OF_ID_VALIDATE_ITEM(P_CITY_CODE_OF_ID => :P1110_CITY_CODE_OF_ID, P_CTRY_CD_OF_ID => :P1110_CTRY_CD_OF_ID, P_ID_CITY_NAME => :P1110_ID_CITY_NAME, P_ID_MINS_COMM_CD => :P1110_ID_MINS_COMM_CD, P_L_CT_CITY_STATUS2 => :P1110_L_CT_CITY_STATUS2, P_ROW_ID => :P1110_ROW_ID);` | P1110_CITY_CODE_OF_ID | P1110_CITY_CODE_OF_ID, P1110_CTRY_CD_OF_ID, P1110_ID_CITY_NAME, P1110_ID_MINS_COMM_CD, P1110_L_CT_CITY_STATUS2 | No | - | IMPORTERS.CTRY_CD_OF_ID.WHEN-VALIDATE-ITEM |
| 27 | `IMPR_TYPE_CD WHEN-NEW-ITEM-INSTANCE` | Get Focus | Item P1110_IMPR_TYPE_CD | - | 1 | FOS - Execute PL/SQL Code | `IMPR1110.IMPR_TYPE_CD_NEW_ITEM_INSTANCE(P_IMPR_TYPE_CD => :P1110_IMPR_TYPE_CD, P_BUS_ID_TYPE_CD => :P1110_BUS_ID_TYPE_CD, P_CTRY_CD => :P1110_CTRY_CD, P_ADD_CTRY_CD => :P1110_ADD_CTRY_CD, P_CRTY_ARBC_NAME => :P1110_CRTY_ARBC_NAME, P_ADD_CRTY_ARBC_NAME => :P1110_ADD_CRTY_ARBC_NAME);` | P1110_IMPR_TYPE_CD, P1110_BUS_ID_TYPE_CD, P1110_CTRY_CD, P1110_ADD_CTRY_CD | P1110_CTRY_CD, P1110_ADD_CTRY_CD, P1110_CRTY_ARBC_NAME, P1110_ADD_CRTY_ARBC_NAME | No | - | IMPORTERS.IMPR_TYPE_CD.WHEN-NEW-ITEM-INSTANCE |
| 28 | `BUS_ID WHEN-NEW-ITEM-INSTANCE` | Get Focus | Item P1110_BUS_ID | - | 1 | FOS - Execute PL/SQL Code | `IMPR1110.BUS_ID_WHEN_NEW_ITEM_INSTANCE(P_IMPR_TYPE_CD => :P1110_IMPR_TYPE_CD, P_BUS_ID_TYPE_CD => :P1110_BUS_ID_TYPE_CD, P_COMM_RGSTRTN_TYPE => :P1110_COMM_RGSTRTN_TYPE, P_CITY_CODE_OF_ID => :P1110_CITY_CODE_OF_ID, P_BUS_ID => :P1110_BUS_ID, P_ID_MINS_COMM_CD => :P1110_ID_MINS_COMM_CD);` | P1110_IMPR_TYPE_CD, P1110_BUS_ID_TYPE_CD, P1110_COMM_RGSTRTN_TYPE, P1110_CITY_CODE_OF_ID, P1110_BUS_ID | - | No | - | IMPORTERS.BUS_ID.WHEN-NEW-ITEM-INSTANCE |
| 29 | `BUS_ID_BRNCH WHEN-NEW-ITEM-INSTANCE` | Get Focus | Item P1110_BUS_ID_BRNCH | - | 1 | FOS - Execute PL/SQL Code | `IMPR1110.BUS_ID_BRNCH_NEW_ITEM_INSTANCE(P_BUS_ID_BRNCH => :P1110_BUS_ID_BRNCH, P_CITY_CODE => :P1110_CITY_CODE, P_BRNH_CITY_CD => :P1110_BRNH_CITY_CD);` | P1110_BUS_ID_BRNCH, P1110_CITY_CODE, P1110_BRNH_CITY_CD | - | No | - | IMPORTERS.BUS_ID_BRNCH.WHEN-NEW-ITEM-INSTANCE |
| 30 | `BANK_IBAN WHEN-NEW-ITEM-INSTANCE` | Get Focus | Item P1110_BANK_IBAN | - | 1 | FOS - Execute PL/SQL Code | `IMPR1110.BANK_IBAN_NEW_ITEM_INSTANCE(P_BANK_IBAN => :P1110_BANK_IBAN);` | P1110_BANK_IBAN | P1110_BANK_IBAN | No | - | IMPORTERS.BANK_IBAN.WHEN-NEW-ITEM-INSTANCE |
| 31 | `ARBC_IMPR_NAME KEY-NEXT-ITEM` | Lose Focus | Item P1110_ARBC_IMPR_NAME | - | 1 | FOS - Execute PL/SQL Code | `IMPR1110.ARBC_IMPR_NAME_KEY_NEXT_ITEM(P_CTRY_CD => :P1110_CTRY_CD, P_ADD_CTRY_CD => :P1110_ADD_CTRY_CD, P_CITY_CODE => :P1110_CITY_CODE, P_IMPR_TEL_NBR => :P1110_IMPR_TEL_NBR, P_ADD_CRTY_ARBC_NAME => :P1110_ADD_CRTY_ARBC_NAME, P_CITY_NAME => :P1110_CITY_NAME);` | P1110_CTRY_CD, P1110_ADD_CTRY_CD, P1110_CITY_CODE, P1110_IMPR_TEL_NBR | P1110_ADD_CTRY_CD, P1110_CITY_CODE, P1110_IMPR_TEL_NBR, P1110_ADD_CRTY_ARBC_NAME, P1110_CITY_NAME | No | - | IMPORTERS.ARBC_IMPR_NAME.KEY-NEXT-ITEM |
| 32 | `COMM_RGSTRTN_TYPE WHEN-LIST-CHANGED` | Change | Item P1110_COMM_RGSTRTN_TYPE | - | 1 | FOS - Execute PL/SQL Code | `IMPR1110.COMM_RGSTRTN_TYPE_LIST_CHANGED(P_COMM_RGSTRTN_TYPE => :P1110_COMM_RGSTRTN_TYPE, P_BUS_ID_BRNCH => :P1110_BUS_ID_BRNCH);` | P1110_COMM_RGSTRTN_TYPE, P1110_BUS_ID_BRNCH | P1110_BUS_ID_BRNCH | No | - | IMPORTERS.COMM_RGSTRTN_TYPE.WHEN-LIST-CHANGED |
| - | - | - | - | - | 2 | FOS - Execute PL/SQL Code (change events ON) | `IMPR1110.READ_ONLY_FLAGS(P_IMPR_NBR => :P1110_IMPR_NBR, P_CODE => :P1110_P_CODE, P_PRSNL_IMPR => :P1110_P_PRSNL_IMPR, P_IMPR_TYPE_CD => :P1110_IMPR_TYPE_CD, P_BUS_ID_TYPE_CD => :P1110_BUS_ID_TYPE_CD, P_COMM_RGSTRTN_TYPE => :P1110_COMM_RGSTRTN_TYPE, P_BUS_ID => :P1110_BUS_ID, P_BUS_ID_BRNCH => :P1110_BUS_ID_BRNCH, P_BUS_ID_EXPRD_DT => :P1110_BUS_ID_EXPRD_DT, P_IMPR_TEL_NBR => :P1110_IMPR_TEL_NBR, P_ACTIVITY => :P1110_ACTIVITY, IMPR_TYPE_CD_LOCKED => :P1110_IMPR_TYPE_CD_LOCKED, BUS_ID_EXPRD_DT_LOCKED => :P1110_BUS_ID_EXPRD_DT_LOCKED, COMM_RGSTRTN_TYPE_LOCKED => :P1110_COMM_RGSTRTN_TYPE_LOCKED, CITY_CODE_OF_ID_LOCKED => :P1110_CITY_CODE_OF_ID_LOCKED, BUS_ID_LOCKED => :P1110_BUS_ID_LOCKED, BRNH_CITY_CD_LOCKED => :P1110_BRNH_CITY_CD_LOCKED, BUS_ID_BRNCH_LOCKED => :P1110_BUS_ID_BRNCH_LOCKED, CTRY_CD_LOCKED => :P1110_CTRY_CD_LOCKED, ARBC_IMPR_NAME_LOCKED => :P1110_ARBC_IMPR_NAME_LOCKED, REGISTER_ITEMS_LOCKED => :P1110_REGISTER_ITEMS_LOCKED, IMPR_TEL_NBR_LOCKED => :P1110_IMPR_TEL_NBR_LOCKED, ACTIVITY_LOCKED => :P1110_ACTIVITY_LOCKED, B_ID_NBR_LOCKED => :P1110_B_ID_NBR_LOCKED, CAR_AGENT_FLAG_LOCKED => :P1110_CAR_AGENT_FLAG_LOCKED);` | P1110_IMPR_NBR, P1110_IMPR_TYPE_CD, P1110_BUS_ID_TYPE_CD, P1110_COMM_RGSTRTN_TYPE, P1110_BUS_ID, P1110_BUS_ID_BRNCH, P1110_BUS_ID_EXPRD_DT, P1110_IMPR_TEL_NBR, P1110_ACTIVITY | P1110_IMPR_TYPE_CD_LOCKED, P1110_BUS_ID_EXPRD_DT_LOCKED, P1110_COMM_RGSTRTN_TYPE_LOCKED, P1110_CITY_CODE_OF_ID_LOCKED, P1110_BUS_ID_LOCKED, P1110_BRNH_CITY_CD_LOCKED, P1110_BUS_ID_BRNCH_LOCKED, P1110_CTRY_CD_LOCKED, P1110_ARBC_IMPR_NAME_LOCKED, P1110_REGISTER_ITEMS_LOCKED, P1110_IMPR_TEL_NBR_LOCKED, P1110_ACTIVITY_LOCKED, P1110_B_ID_NBR_LOCKED, P1110_CAR_AGENT_FLAG_LOCKED | - | returns the P1110_<GROUP>_LOCKED flags; their change events run the READ ONLY DAs | - |
| 33 | `IMPR_TYPE_CD READ ONLY` | Change | Item P1110_IMPR_TYPE_CD_LOCKED | Item P1110_IMPR_TYPE_CD_LOCKED = Y | 1 | Disable | items P1110_IMPR_TYPE_CD | - | - | Yes | True action | read_only_rules.md (Make_Field_Entrable / SET_ITEM_PROPERTY ENABLED) |
| - | - | - | - | - | 2 | Enable | items P1110_IMPR_TYPE_CD | - | - | - | False action | - |
| 34 | `BUS_ID_EXPRD_DT READ ONLY` | Change | Item P1110_BUS_ID_EXPRD_DT_LOCKED | Item P1110_BUS_ID_EXPRD_DT_LOCKED = Y | 1 | Disable | items P1110_BUS_ID_EXPRD_DT | - | - | Yes | True action | read_only_rules.md (Make_Field_Entrable / SET_ITEM_PROPERTY ENABLED) |
| - | - | - | - | - | 2 | Enable | items P1110_BUS_ID_EXPRD_DT | - | - | - | False action | - |
| 35 | `COMM_RGSTRTN_TYPE READ ONLY` | Change | Item P1110_COMM_RGSTRTN_TYPE_LOCKED | Item P1110_COMM_RGSTRTN_TYPE_LOCKED = Y | 1 | Disable | items P1110_COMM_RGSTRTN_TYPE | - | - | Yes | True action | read_only_rules.md (Make_Field_Entrable / SET_ITEM_PROPERTY ENABLED) |
| - | - | - | - | - | 2 | Enable | items P1110_COMM_RGSTRTN_TYPE | - | - | - | False action | - |
| 36 | `CITY_CODE_OF_ID READ ONLY` | Change | Item P1110_CITY_CODE_OF_ID_LOCKED | Item P1110_CITY_CODE_OF_ID_LOCKED = Y | 1 | Disable | items P1110_CITY_CODE_OF_ID | - | - | Yes | True action | read_only_rules.md (Make_Field_Entrable / SET_ITEM_PROPERTY ENABLED) |
| - | - | - | - | - | 2 | Enable | items P1110_CITY_CODE_OF_ID | - | - | - | False action | - |
| 37 | `BUS_ID READ ONLY` | Change | Item P1110_BUS_ID_LOCKED | Item P1110_BUS_ID_LOCKED = Y | 1 | Disable | items P1110_BUS_ID | - | - | Yes | True action | read_only_rules.md (Make_Field_Entrable / SET_ITEM_PROPERTY ENABLED) |
| - | - | - | - | - | 2 | Enable | items P1110_BUS_ID | - | - | - | False action | - |
| 38 | `BRNH_CITY_CD READ ONLY` | Change | Item P1110_BRNH_CITY_CD_LOCKED | Item P1110_BRNH_CITY_CD_LOCKED = Y | 1 | Disable | items P1110_BRNH_CITY_CD | - | - | Yes | True action | read_only_rules.md (Make_Field_Entrable / SET_ITEM_PROPERTY ENABLED) |
| - | - | - | - | - | 2 | Enable | items P1110_BRNH_CITY_CD | - | - | - | False action | - |
| 39 | `BUS_ID_BRNCH READ ONLY` | Change | Item P1110_BUS_ID_BRNCH_LOCKED | Item P1110_BUS_ID_BRNCH_LOCKED = Y | 1 | Disable | items P1110_BUS_ID_BRNCH | - | - | Yes | True action | read_only_rules.md (Make_Field_Entrable / SET_ITEM_PROPERTY ENABLED) |
| - | - | - | - | - | 2 | Enable | items P1110_BUS_ID_BRNCH | - | - | - | False action | - |
| 40 | `CTRY_CD READ ONLY` | Change | Item P1110_CTRY_CD_LOCKED | Item P1110_CTRY_CD_LOCKED = Y | 1 | Disable | items P1110_CTRY_CD | - | - | Yes | True action | read_only_rules.md (Make_Field_Entrable / SET_ITEM_PROPERTY ENABLED) |
| - | - | - | - | - | 2 | Enable | items P1110_CTRY_CD | - | - | - | False action | - |
| 41 | `ARBC_IMPR_NAME READ ONLY` | Change | Item P1110_ARBC_IMPR_NAME_LOCKED | Item P1110_ARBC_IMPR_NAME_LOCKED = Y | 1 | Disable | items P1110_ARBC_IMPR_NAME | - | - | Yes | True action | read_only_rules.md (Make_Field_Entrable / SET_ITEM_PROPERTY ENABLED) |
| - | - | - | - | - | 2 | Enable | items P1110_ARBC_IMPR_NAME | - | - | - | False action | - |
| 42 | `REGISTER_ITEMS READ ONLY` | Change | Item P1110_REGISTER_ITEMS_LOCKED | Item P1110_REGISTER_ITEMS_LOCKED = Y | 1 | Disable | items P1110_IMPR_POB_NBR, P1110_IMPR_ZIP_CD, P1110_IMPR_FAX_NBR, P1110_IMPR_TELEX_NBR | - | - | Yes | True action | read_only_rules.md (Make_Field_Entrable / SET_ITEM_PROPERTY ENABLED) |
| - | - | - | - | - | 2 | Enable | items P1110_IMPR_POB_NBR, P1110_IMPR_ZIP_CD, P1110_IMPR_FAX_NBR, P1110_IMPR_TELEX_NBR | - | - | - | False action | - |
| 43 | `IMPR_TEL_NBR READ ONLY` | Change | Item P1110_IMPR_TEL_NBR_LOCKED | Item P1110_IMPR_TEL_NBR_LOCKED = Y | 1 | Disable | items P1110_IMPR_TEL_NBR | - | - | Yes | True action | read_only_rules.md (Make_Field_Entrable / SET_ITEM_PROPERTY ENABLED) |
| - | - | - | - | - | 2 | Enable | items P1110_IMPR_TEL_NBR | - | - | - | False action | - |
| 44 | `ACTIVITY READ ONLY` | Change | Item P1110_ACTIVITY_LOCKED | Item P1110_ACTIVITY_LOCKED = Y | 1 | Disable | items P1110_ACTIVITY | - | - | Yes | True action | read_only_rules.md (Make_Field_Entrable / SET_ITEM_PROPERTY ENABLED) |
| - | - | - | - | - | 2 | Enable | items P1110_ACTIVITY | - | - | - | False action | - |
| 45 | `B_ID_NBR READ ONLY` | Change | Item P1110_B_ID_NBR_LOCKED | Item P1110_B_ID_NBR_LOCKED = Y | 1 | Disable | items P1110_B_ID_NBR | - | - | Yes | True action | read_only_rules.md (Make_Field_Entrable / SET_ITEM_PROPERTY ENABLED) |
| - | - | - | - | - | 2 | Enable | items P1110_B_ID_NBR | - | - | - | False action | - |
| 46 | `CAR_AGENT_FLAG READ ONLY` | Change | Item P1110_CAR_AGENT_FLAG_LOCKED | Item P1110_CAR_AGENT_FLAG_LOCKED = Y | 1 | Disable | items P1110_CAR_AGENT_FLAG | - | - | Yes | True action | read_only_rules.md (Make_Field_Entrable / SET_ITEM_PROPERTY ENABLED) |
| - | - | - | - | - | 2 | Enable | items P1110_CAR_AGENT_FLAG | - | - | - | False action | - |
| 47 | `IMPR1110F1 EXECUTE-FUNCTION` | Custom: IMPR1110F1 | JavaScript Expression: document | - | 1 | Set Value | Static 'IMPR1110F1' -> P1110_FUNCTION_PENDING | - | - | No | - | PU EXEC_FUNS / TMPLT EXECUTE_FUNCTION (IMPR1110F1) |
| - | - | - | - | - | 2 | Execute JavaScript Code | `apex.navigation.redirect($v('P1110_SUPPORT_URL'));` | - | - | - | open the SUPPORT_ENTRY dialog (form converted separately, decision §15 #12; its page and URL item are TODO) | - |
| 48 | `IMPR1110F2 EXECUTE-FUNCTION` | Custom: IMPR1110F2 | JavaScript Expression: document | - | 1 | Set Value | Static 'IMPR1110F2' -> P1110_FUNCTION_PENDING | - | - | No | - | PU EXEC_FUNS / TMPLT EXECUTE_FUNCTION (IMPR1110F2) |
| - | - | - | - | - | 2 | Execute JavaScript Code | `apex.navigation.redirect($v('P1110_SUPPORT_URL'));` | - | - | - | open the SUPPORT_ENTRY dialog (form converted separately, decision §15 #12; its page and URL item are TODO) | - |
| 49 | `IMPR1110F3 EXECUTE-FUNCTION` | Custom: IMPR1110F3 | JavaScript Expression: document | - | 1 | Set Value | Static 'IMPR1110F3' -> P1110_FUNCTION_PENDING | - | - | No | - | PU EXEC_FUNS / TMPLT EXECUTE_FUNCTION (IMPR1110F3) |
| - | - | - | - | - | 2 | Execute JavaScript Code | `apex.navigation.redirect($v('P1110_SUPPORT_URL'));` | - | - | - | open the SUPPORT_ENTRY dialog (form converted separately, decision §15 #12; its page and URL item are TODO) | - |
| 50 | `IMPR1110F5 EXECUTE-FUNCTION` | Custom: IMPR1110F5 | JavaScript Expression: document | - | 1 | Set Value | Static 'IMPR1110F5' -> P1110_FUNCTION_PENDING | - | - | No | - | PU EXEC_FUNS / TMPLT EXECUTE_FUNCTION (IMPR1110F5) |
| - | - | - | - | - | 2 | Execute JavaScript Code | `apex.navigation.redirect($v('P1110_SUPPORT_URL'));` | - | - | - | open the SUPPORT_ENTRY dialog (form converted separately, decision §15 #12; its page and URL item are TODO) | - |
| 51 | `IMPR1110F4 EXECUTE-FUNCTION` | Custom: IMPR1110F4 | JavaScript Expression: document | - | 1 | Set Value | Static NULL -> P1110_FUNCTION_CODE, Suppress Change Event = Yes | - | - | No | so the next value always fires a change | PU EXEC_FUNS / TMPLT EXECUTE_FUNCTION (IMPR1110F4) |
| - | - | - | - | - | 2 | Set Value | Static 'IMPR1110F4' -> P1110_FUNCTION_CODE | - | - | - | fires DA EXEC_FUNS | - |
| 52 | `IMPR_CAR_AGENT EXECUTE-FUNCTION` | Custom: IMPR_CAR_AGENT | JavaScript Expression: document | - | 1 | Set Value | Static NULL -> P1110_FUNCTION_CODE, Suppress Change Event = Yes | - | - | No | so the next value always fires a change | PU EXEC_FUNS / TMPLT EXECUTE_FUNCTION (IMPR_CAR_AGENT) |
| - | - | - | - | - | 2 | Set Value | Static 'IMPR_CAR_AGENT' -> P1110_FUNCTION_CODE | - | - | - | fires DA EXEC_FUNS | - |
| 53 | `CREATE_BRKR_IMPR_AUTH EXECUTE-FUNCTION` | Custom: CREATE_BRKR_IMPR_AUTH | JavaScript Expression: document | - | 1 | FOS - Execute PL/SQL Code | `IMPR1110.EXEC_FUNS(P_PORT_CD => :P1110_PORT_CD, P_IMPR_NBR => :P1110_IMPR_NBR, P_BUS_ID => :P1110_BUS_ID, P_BUS_ID_BRNCH => :P1110_BUS_ID_BRNCH, P_ARBC_IMPR_NAME => :P1110_ARBC_IMPR_NAME, P_CURR_PORT_CD => :P_CURR_PORT_CD, SSO_APP_USER => :SSO_APP_USER, P_GLOBAL_V_WS_ID => :P_GLOBAL_V_WS_ID, P_CLASS_CD => :P_CLASS_CD, V_USR_TYPE => :V_USR_TYPE, P_LETTER_NBR => :P1110_P_LETTER_NBR, P_CODE => :P1110_P_CODE, P_BRKR_PORT_CD => :P_BRKR_PORT_CD, P_LIC_TYPE => :P_LIC_TYPE, P_BRKR_NBR => :P_BRKR_NBR, FUNCTION_CODE => 'CREATE_BRKR_IMPR_AUTH');` | P1110_PORT_CD, P1110_IMPR_NBR, P1110_BUS_ID, P1110_BUS_ID_BRNCH, P1110_ARBC_IMPR_NAME, P_CURR_PORT_CD, P_GLOBAL_V_WS_ID, P_CLASS_CD, P_BRKR_PORT_CD, P_LIC_TYPE, P_BRKR_NBR | P1110_P_LETTER_NBR, P1110_P_CODE | No | - | PU EXEC_FUNS / TMPLT EXECUTE_FUNCTION (CREATE_BRKR_IMPR_AUTH) |
| 54 | `IMPR1115_GZT EXECUTE-FUNCTION` | Custom: IMPR1115_GZT | JavaScript Expression: document | - | 1 | FOS - Execute PL/SQL Code | `IMPR1110.EXEC_FUNS(P_PORT_CD => :P1110_PORT_CD, P_IMPR_NBR => :P1110_IMPR_NBR, P_BUS_ID => :P1110_BUS_ID, P_BUS_ID_BRNCH => :P1110_BUS_ID_BRNCH, P_ARBC_IMPR_NAME => :P1110_ARBC_IMPR_NAME, P_CURR_PORT_CD => :P_CURR_PORT_CD, SSO_APP_USER => :SSO_APP_USER, P_GLOBAL_V_WS_ID => :P_GLOBAL_V_WS_ID, P_CLASS_CD => :P_CLASS_CD, V_USR_TYPE => :V_USR_TYPE, P_LETTER_NBR => :P1110_P_LETTER_NBR, P_CODE => :P1110_P_CODE, P_BRKR_PORT_CD => :P_BRKR_PORT_CD, P_LIC_TYPE => :P_LIC_TYPE, P_BRKR_NBR => :P_BRKR_NBR, FUNCTION_CODE => 'IMPR1115_GZT');` | P1110_PORT_CD, P1110_IMPR_NBR, P1110_BUS_ID, P1110_BUS_ID_BRNCH, P1110_ARBC_IMPR_NAME, P_CURR_PORT_CD, P_GLOBAL_V_WS_ID, P_CLASS_CD, P_BRKR_PORT_CD, P_LIC_TYPE, P_BRKR_NBR | P1110_P_LETTER_NBR, P1110_P_CODE | No | - | PU EXEC_FUNS / TMPLT EXECUTE_FUNCTION (IMPR1115_GZT) |
| 55 | `IMPR_MCI_SERVICE EXECUTE-FUNCTION` | Custom: IMPR_MCI_SERVICE | JavaScript Expression: document | - | 1 | FOS - Execute PL/SQL Code | `:P1110_CONFIRM_TEXT := IMPR1110.UPDATE_IMPORTER_CONFIRM_TEXT(P_PORT_CD => :P1110_PORT_CD, P_IMPR_NBR => :P1110_IMPR_NBR, P_IMPR_TYPE_CD => :P1110_IMPR_TYPE_CD, P_BUS_ID_TYPE_CD => :P1110_BUS_ID_TYPE_CD, P_BUS_ID => :P1110_BUS_ID, P_BUS_ID_BRNCH => :P1110_BUS_ID_BRNCH);` | P1110_PORT_CD, P1110_IMPR_NBR, P1110_IMPR_TYPE_CD, P1110_BUS_ID_TYPE_CD, P1110_BUS_ID, P1110_BUS_ID_BRNCH | P1110_CONFIRM_TEXT | No | - | PU EXEC_FUNS / TMPLT EXECUTE_FUNCTION (IMPR_MCI_SERVICE) |
| - | - | - | - | - | 2 | Execute JavaScript Code | `apex.message.confirm($v('P1110_CONFIRM_TEXT'), function (ok) {<br>    if (ok) { $s('P1110_ANSWER', '1'); apex.event.trigger(document, 'impr1110-update-importer'); } });` | - | - | - | question text computed on the server (UPDATE_IMPORTER_MSG) | - |
| 56 | `IMPR1110_MOB EXECUTE-FUNCTION` | Custom: IMPR1110_MOB | JavaScript Expression: document | - | 1 | FOS - Execute PL/SQL Code | `IMPR1110.EXEC_FUNS(P_PORT_CD => :P1110_PORT_CD, P_IMPR_NBR => :P1110_IMPR_NBR, P_BUS_ID => :P1110_BUS_ID, P_BUS_ID_BRNCH => :P1110_BUS_ID_BRNCH, P_ARBC_IMPR_NAME => :P1110_ARBC_IMPR_NAME, P_CURR_PORT_CD => :P_CURR_PORT_CD, SSO_APP_USER => :SSO_APP_USER, P_GLOBAL_V_WS_ID => :P_GLOBAL_V_WS_ID, P_CLASS_CD => :P_CLASS_CD, V_USR_TYPE => :V_USR_TYPE, P_LETTER_NBR => :P1110_P_LETTER_NBR, P_CODE => :P1110_P_CODE, P_BRKR_PORT_CD => :P_BRKR_PORT_CD, P_LIC_TYPE => :P_LIC_TYPE, P_BRKR_NBR => :P_BRKR_NBR, FUNCTION_CODE => 'IMPR1110_MOB');` | P1110_PORT_CD, P1110_IMPR_NBR, P1110_BUS_ID, P1110_BUS_ID_BRNCH, P1110_ARBC_IMPR_NAME, P_CURR_PORT_CD, P_GLOBAL_V_WS_ID, P_CLASS_CD, P_BRKR_PORT_CD, P_LIC_TYPE, P_BRKR_NBR | P1110_P_LETTER_NBR, P1110_P_CODE | No | checks IMPR_NBR > 3000000 | PU EXEC_FUNS / TMPLT EXECUTE_FUNCTION (IMPR1110_MOB) |
| - | - | - | - | - | 2 | Execute JavaScript Code | `apex.navigation.redirect($v('P1110_MOBILE_URL'));` | - | - | - | open dialog page 111002 (URL from apex_page.get_url, modal) | - |
| 57 | `SUPPORT_ENTRY DIALOG CLOSED` | Dialog Closed | JavaScript Expression: document | TODO: dialog = SUPPORT_ENTRY page | 1 | Set Value | Static NULL -> P1110_FUNCTION_CODE, Suppress Change Event = Yes | - | - | No | - | CALL_FORM(SUPPORT_ENTRY) return (functions F1, F2, F3, F5) |
| - | - | - | - | - | 2 | Set Value | JavaScript Expression $v('P1110_FUNCTION_PENDING') -> P1110_FUNCTION_CODE | - | - | - | fires DA EXEC_FUNS | - |
| 58 | `EXEC_FUNS` | Change | Item P1110_FUNCTION_CODE | Item P1110_FUNCTION_CODE is not null | 1 | FOS - Execute PL/SQL Code | `IMPR1110.EXEC_FUNS(P_PORT_CD => :P1110_PORT_CD, P_IMPR_NBR => :P1110_IMPR_NBR, P_BUS_ID => :P1110_BUS_ID, P_BUS_ID_BRNCH => :P1110_BUS_ID_BRNCH, P_ARBC_IMPR_NAME => :P1110_ARBC_IMPR_NAME, P_CURR_PORT_CD => :P_CURR_PORT_CD, SSO_APP_USER => :SSO_APP_USER, P_GLOBAL_V_WS_ID => :P_GLOBAL_V_WS_ID, P_CLASS_CD => :P_CLASS_CD, V_USR_TYPE => :V_USR_TYPE, P_LETTER_NBR => :P1110_P_LETTER_NBR, P_CODE => :P1110_P_CODE, P_BRKR_PORT_CD => :P_BRKR_PORT_CD, P_LIC_TYPE => :P_LIC_TYPE, P_BRKR_NBR => :P_BRKR_NBR, FUNCTION_CODE => :P1110_FUNCTION_CODE);` | P1110_PORT_CD, P1110_IMPR_NBR, P1110_BUS_ID, P1110_BUS_ID_BRNCH, P1110_ARBC_IMPR_NAME, P_CURR_PORT_CD, P_GLOBAL_V_WS_ID, P_CLASS_CD, P_BRKR_PORT_CD, P_LIC_TYPE, P_BRKR_NBR, P1110_FUNCTION_CODE | P1110_P_LETTER_NBR, P1110_P_CODE | No | - | PU EXEC_FUNS + IMPORTERS.WHEN-NEW-RECORD-INSTANCE |
| - | - | - | - | - | 2 | FOS - Execute PL/SQL Code | `:P1110_CONFIRM_TEXT := IMPR1110.NEW_RECORD_CONFIRM_TEXT(P_IMPR_TYPE_CD => :P1110_IMPR_TYPE_CD, P_BUS_ID_TYPE_CD => :P1110_BUS_ID_TYPE_CD, P_COMM_RGSTRTN_TYPE => :P1110_COMM_RGSTRTN_TYPE, P_BUS_ID => :P1110_BUS_ID, P_BUS_ID_BRNCH => :P1110_BUS_ID_BRNCH, P_CODE => :P1110_P_CODE);` | P1110_IMPR_TYPE_CD, P1110_BUS_ID_TYPE_CD, P1110_COMM_RGSTRTN_TYPE, P1110_BUS_ID, P1110_BUS_ID_BRNCH | P1110_CONFIRM_TEXT | - | - | - |
| - | - | - | - | - | 3 | Execute JavaScript Code | `var t = $v('P1110_CONFIRM_TEXT'), go = function (a) { $s('P1110_ANSWER', a); apex.event.trigger(document, 'impr1110-new-record-instance'); };<br>if (t) { apex.message.confirm(t, function (ok) { go(ok ? '1' : '2'); }); } else { go('1'); }` | - | - | - | CONFIRM alert of IMPR1110F1 / F5 with a computed text (new name), then WHEN-NEW-RECORD-INSTANCE | - |
| 59 | `WHEN-NEW-RECORD-INSTANCE` | Custom: impr1110-new-record-instance | JavaScript Expression: document | - | 1 | FOS - Execute PL/SQL Code | `IMPR1110.WHEN_NEW_RECORD_INSTANCE(P_IMPR_TYPE_CD => :P1110_IMPR_TYPE_CD, P_BUS_ID_TYPE_CD => :P1110_BUS_ID_TYPE_CD, P_COMM_RGSTRTN_TYPE => :P1110_COMM_RGSTRTN_TYPE, P_BUS_ID => :P1110_BUS_ID, P_BUS_ID_BRNCH => :P1110_BUS_ID_BRNCH, P_CTRY_CD => :P1110_CTRY_CD, P_ARBC_IMPR_NAME => :P1110_ARBC_IMPR_NAME, P_IMPR_NBR_PARENT => :P1110_IMPR_NBR_PARENT, P_ADD_CTRY_CD => :P1110_ADD_CTRY_CD, P_CRTY_ARBC_NAME => :P1110_CRTY_ARBC_NAME, P_IMPR_NAME_PARENT => :P1110_IMPR_NAME_PARENT, P_ADD_CRTY_ARBC_NAME => :P1110_ADD_CRTY_ARBC_NAME, P_CURR_PORT_CD => :P_CURR_PORT_CD, P_CLASS_CD => :P_CLASS_CD, V_USR_TYPE => :V_USR_TYPE, P_CODE => :P1110_P_CODE, P_ANSWER => :P1110_ANSWER);` | P1110_IMPR_TYPE_CD, P1110_BUS_ID_TYPE_CD, P1110_COMM_RGSTRTN_TYPE, P1110_BUS_ID, P1110_BUS_ID_BRNCH, P1110_CTRY_CD, P1110_ARBC_IMPR_NAME, P1110_IMPR_NBR_PARENT, P1110_ADD_CTRY_CD, P_CURR_PORT_CD, P_CLASS_CD | P1110_IMPR_TYPE_CD, P1110_CTRY_CD, P1110_ARBC_IMPR_NAME, P1110_ADD_CTRY_CD, P1110_CRTY_ARBC_NAME, P1110_IMPR_NAME_PARENT, P1110_ADD_CRTY_ARBC_NAME | No | - | IMPORTERS.PRE-RECORD + WHEN-NEW-RECORD-INSTANCE after a function |
| - | - | - | - | - | 2 | FOS - Execute PL/SQL Code (change events ON) | `IMPR1110.READ_ONLY_FLAGS(P_IMPR_NBR => :P1110_IMPR_NBR, P_CODE => :P1110_P_CODE, P_PRSNL_IMPR => :P1110_P_PRSNL_IMPR, P_IMPR_TYPE_CD => :P1110_IMPR_TYPE_CD, P_BUS_ID_TYPE_CD => :P1110_BUS_ID_TYPE_CD, P_COMM_RGSTRTN_TYPE => :P1110_COMM_RGSTRTN_TYPE, P_BUS_ID => :P1110_BUS_ID, P_BUS_ID_BRNCH => :P1110_BUS_ID_BRNCH, P_BUS_ID_EXPRD_DT => :P1110_BUS_ID_EXPRD_DT, P_IMPR_TEL_NBR => :P1110_IMPR_TEL_NBR, P_ACTIVITY => :P1110_ACTIVITY, IMPR_TYPE_CD_LOCKED => :P1110_IMPR_TYPE_CD_LOCKED, BUS_ID_EXPRD_DT_LOCKED => :P1110_BUS_ID_EXPRD_DT_LOCKED, COMM_RGSTRTN_TYPE_LOCKED => :P1110_COMM_RGSTRTN_TYPE_LOCKED, CITY_CODE_OF_ID_LOCKED => :P1110_CITY_CODE_OF_ID_LOCKED, BUS_ID_LOCKED => :P1110_BUS_ID_LOCKED, BRNH_CITY_CD_LOCKED => :P1110_BRNH_CITY_CD_LOCKED, BUS_ID_BRNCH_LOCKED => :P1110_BUS_ID_BRNCH_LOCKED, CTRY_CD_LOCKED => :P1110_CTRY_CD_LOCKED, ARBC_IMPR_NAME_LOCKED => :P1110_ARBC_IMPR_NAME_LOCKED, REGISTER_ITEMS_LOCKED => :P1110_REGISTER_ITEMS_LOCKED, IMPR_TEL_NBR_LOCKED => :P1110_IMPR_TEL_NBR_LOCKED, ACTIVITY_LOCKED => :P1110_ACTIVITY_LOCKED, B_ID_NBR_LOCKED => :P1110_B_ID_NBR_LOCKED, CAR_AGENT_FLAG_LOCKED => :P1110_CAR_AGENT_FLAG_LOCKED);` | P1110_IMPR_NBR, P1110_IMPR_TYPE_CD, P1110_BUS_ID_TYPE_CD, P1110_COMM_RGSTRTN_TYPE, P1110_BUS_ID, P1110_BUS_ID_BRNCH, P1110_BUS_ID_EXPRD_DT, P1110_IMPR_TEL_NBR, P1110_ACTIVITY | P1110_IMPR_TYPE_CD_LOCKED, P1110_BUS_ID_EXPRD_DT_LOCKED, P1110_COMM_RGSTRTN_TYPE_LOCKED, P1110_CITY_CODE_OF_ID_LOCKED, P1110_BUS_ID_LOCKED, P1110_BRNH_CITY_CD_LOCKED, P1110_BUS_ID_BRNCH_LOCKED, P1110_CTRY_CD_LOCKED, P1110_ARBC_IMPR_NAME_LOCKED, P1110_REGISTER_ITEMS_LOCKED, P1110_IMPR_TEL_NBR_LOCKED, P1110_ACTIVITY_LOCKED, P1110_B_ID_NBR_LOCKED, P1110_CAR_AGENT_FLAG_LOCKED | - | returns the P1110_<GROUP>_LOCKED flags; their change events run the READ ONLY DAs | - |
| 60 | `UPDATE_IMPORTER` | Custom: impr1110-update-importer | JavaScript Expression: document | - | 1 | FOS - Execute PL/SQL Code | `IMPR1110.UPDATE_IMPORTER(P_PORT_CD => :P1110_PORT_CD, P_IMPR_NBR => :P1110_IMPR_NBR, P_ANSWER => :P1110_ANSWER);` | P1110_PORT_CD, P1110_IMPR_NBR | - | No | - | PU UPDATE_IMPORTER (function IMPR_MCI_SERVICE) |
| 61 | `LOV_UPDATE_IMPR_MOBILE DIALOG CLOSED` | Dialog Closed | JavaScript Expression: document | dialog page 111002 | 1 | FOS - Execute PL/SQL Code | `IMPR1110.LOV_UPDATE_MOBLIE(P_IMPR_NBR => :P1110_IMPR_NBR);` | P1110_IMPR_NBR | - | No | - | PU LOV_UPDATE_MOBLIE after CALL_FORM(LOV_UPDATE_IMPR_MOBILE) |
| 62 | `PRE-INSERT CONFIRM` | Before Page Submit | - | JavaScript expression: this.data === 'CREATE' && $v('P1110_BROKER_USER') === 'Y' && $v('P1110_ANSWER') !== '1' | 1 | Execute JavaScript Code | `apex.event.gCancelFlag = true;<br>apex.message.confirm($v('P1110_PRE_INSERT_QUESTION'), function (ok) { if (ok) { $s('P1110_ANSWER', '1'); apex.page.submit('CREATE'); } });` | - | - | No | f345 known case: page 0 CREATE submits directly, the question must come before the submit | IMPORTERS.PRE-INSERT (CONFIRM for brokers, class 1 / type 3) |

### 10.3 JavaScript actions (9, each 1–3 lines)

| # | DA | Lines | Why native actions are not enough |
|---|---|---|---|
| 1 | `BUS_ID WHEN-VALIDATE-ITEM` | 2 | WARNING alert "يوجد مستورد … موقوف له نفس الرقم الإستدلالي" with the importer number computed on the server; the answer must be known before the WHEN-VALIDATE-ITEM code runs. Native *Confirm* has a fixed text |
| 2–5 | `IMPR1110F1` / `F2` / `F3` / `F5 EXECUTE-FUNCTION` | 1 each | open the SUPPORT_ENTRY dialog (`apex.navigation.redirect` of a modal-page URL); there is no native "open dialog" action in 21.2 |
| 6 | `IMPR_MCI_SERVICE EXECUTE-FUNCTION` | 2 | question text computed by `UPDATE_IMPORTER_MSG` |
| 7 | `IMPR1110_MOB EXECUTE-FUNCTION` | 1 | open dialog page 111002 after the server check |
| 8 | `EXEC_FUNS` | 2 | CONFIRM of IMPR1110F1 / F5 "سيتم تعديل الإسم إلى …" with the new name computed on the server, then the WHEN-NEW-RECORD-INSTANCE DA |
| 9 | `PRE-INSERT CONFIRM` | 2 | the f345 known case: page 0 CREATE submits directly, so the broker question must cancel and resubmit (`apex.event.gCancelFlag`) |

No JavaScript file, no AJAX callback process, no client UI-state engine. Revision 1 had `impr1110.js`
(396 lines) and 3 AJAX callback processes.

### 10.4 Order of events after a function (example IMPR1110F4)

1. FUNCS list → custom event `IMPR1110F4` → DA `IMPR1110F4 EXECUTE-FUNCTION`: `P1110_FUNCTION_CODE` := NULL
   (no event), then := `IMPR1110F4` → change event.
2. DA `EXEC_FUNS`: FOS `EXEC_FUNS` (returns `P1110_P_CODE` = IMPR1110F4) → FOS `NEW_RECORD_CONFIRM_TEXT`
   (NULL for F4) → JS: no question → `P1110_ANSWER` := 1 → event `impr1110-new-record-instance`.
3. DA `WHEN-NEW-RECORD-INSTANCE`: FOS `WHEN_NEW_RECORD_INSTANCE` → FOS `READ_ONLY_FLAGS` (BUS_ID_EXPRD_DT
   now unlocked) → change of `P1110_BUS_ID_EXPRD_DT_LOCKED` → DA `BUS_ID_EXPRD_DT READ ONLY` enables the item.
4. SAVE → PRE-UPDATE / Process form / POST-UPDATE → `P_CODE RESET` → the page renders with the item locked again.

## 11. Alerts and messages

| Forms alert / message | Usage | APEX equivalent | Text |
|---|---|---|---|
| `USR_CONFIRM_B`, `USR_CONFIRM`, `USR_WARNING_C`, `USR_WARNING_B`, `CFG_WARNING_A`, `CFG_INFORMATION`, `CFG_ERROR`, `CFG_SYSTEM_ERROR`, `CFG_ASK_COMMIT` (CIC_OLB, resolved in step 01) | only through `STR.DispAlert` / `STR.DispArbMsg` | no Text Message: the texts are in the package (verbatim from the form) | – |
| `STR.DispAlert(text, 'ERROR')` + FORM_TRIGGER_FAILURE | stop | `FORMS_APX.FORM_TRIGGER_FAILURE` → validation error text / FOS error / process error | verbatim |
| `STR.DispAlert(text, 'INFORMATION')` without failure | note | `FORMS_APX.MESSAGE` → success message of the process / FOS | verbatim |
| CONFIRM of PRE-INSERT (brokers) | caution | Text Message **`IMPR1110_PRE_INSERT_CONFIRM`** → computation `P1110_PRE_INSERT_QUESTION` (`APEX_LANG.MESSAGE`) → DA `PRE-INSERT CONFIRM` | يجب مراجعة البيانات والتأكد من صحتها قبل التخزين، لايمكن التعديل إلا من قبل شئون المستوردين! هل ترغب بالاستمرار؟ |
| WARNING suspended importer (BUS_ID), CONFIRM new name (F1 / F5), CONFIRM MCI update | caution, text computed | `*_CONFIRM_TEXT` functions + `apex.message.confirm` (§10.3) | from the package |
| page 0 DELETE question | caution | page 0 `DELETE` confirm (f345) | f345 text (Forms: "هل أنت متأكد من عملية الحذف") |
| FRM-40202 / 40350 | Forms runtime | Value Required / `FORMS_APX.REQUIRED_VALIDATION` ("يجب إدخال <label>", common helper since FORMS_APX 004; was CG_MESSAGE "<p1> must be entered"); no-row-found is not possible (key from the search page) | **TODO** Arabic texts of `NIB.ON_ERROR` (MISSING SOURCE) |

Error handling function: the f345 `APP_ERROR_HANDLER` (application attribute, not changed).

## 12. Branches and navigation

| Branch / link | Point | Target | Condition | Items set | Source |
|---|---|---|---|---|---|
| After processing | After Processing | 1110 | always (EXECUTE_QUERY: clear cache 1110) | – | Forms stays in the form after COMMIT |
| page 0 SEARCH | – | 111001 (dialog) | `P0_PAGE_PK` is null | – | ENTER_QUERY / EXECUTE_QUERY |
| link column of 111001 | – | 1110 | – | `P0_PAGE_PK` = ROWID (checksum) | EXECUTE_QUERY result |
| function `IMPR1110_MOB` | – | 111002 (dialog) | `IMPR_NBR > 3000000` (checked by `EXEC_FUNS`) | `P111002_IMPR_NBR` (checksum, `P1110_MOBILE_URL`) | `CALL_FORM('LOV_UPDATE_IMPR_MOBILE.fmx')` |
| functions IMPR1110F1 / F2 / F3 / F5 | – | SUPPORT_ENTRY page (dialog) | – | P_MODE = 0, P_CURR_PORT_CD = PORT_CD | `CALL_FORM('SUPPORT_ENTRY.FMX')` – **TODO** |
| function `IMPR1115_SCR` | – | page IMPR1115 when converted (the f345 list links to a page named after the file) | – | `P_IMPR_NO` = IMPR_NBR | TMPLT CALL_FORM – **TODO** |
| other forms that open IMPR1110 | – | 1110 | – | application items `P_PRSNL_IMPR`, `P_LETTER_NBR` (read once by `PARAMETERS ENTRY`) | CALL_FORM with PRSNL_IMPR / LETTER_NBR |
| page 0 BACK | – | home application | – | – | EXIT_FORM |

## 13. Shared components

### 13.1 Reused from f345 (do not create)

Theme 42 / ZATCA Forms templates (§1–§3), page 0 (`P0_ACTIONS`, `ASK_DLG`, `P0_PAGE_PK`, `P0_SEARCH_URL`),
list *Page Functions*, plug-in `COM.FOS.EXECUTE_PLSQL_CODE`, application process `SCREEN ENTRY RESET`,
`APP_ERROR_HANDLER`, the Hijri picker (`Hijri_init.js`, class `hijri-date-default`), and the application items
`SSO_APP_USER`, `P_CURR_PORT_CD`, `P_GLOBAL_V_WS_ID`, `P_CLASS_CD`, `V_USR_TYPE`, `P_BRKR_NBR`, `P_PORT_TYPE`,
`SYS_ANAME`, `G_LAST_PAGE`.

### 13.2 New application items (Session State Protection: Restricted)

| Item | Source | Notes |
|---|---|---|
| `P_BRKR_PORT_CD`, `P_LIC_TYPE` | `:PARAMETER.P_BRKR_PORT_CD` / `P_LIC_TYPE` of the menu | not filled by the f345 login yet: **TODO**, the f345 After Authentication process must set them (CIC_MENU source missing) |
| `P_PRSNL_IMPR`, `P_LETTER_NBR` | parameters callers pass to IMPR1110 | read once by `PARAMETERS ENTRY` |
| 28 globals `G_<NAME>` | `:GLOBAL.<NAME>` through `FORMS_APX.GET_GLOBAL` / `SET_GLOBAL` | `G_ALLOW_MCI`, `G_ALLOW_MOI`, `G_BRKR_ATHRZTN_NBR_B`, `G_CHEK`, `G_CHK_DUP_BUSID`, `G_CHK_IMP_TYP`, `G_EXEC_QUERY_NOW`, `G_EXE_DETAIL_QUERY`, `G_FLAGUPDATE`, `G_FUNS_BUSID`, `G_FUNS_IMP`, `G_IMP0F4`, `G_IMPR_NAME_B`, `G_IMPR_NBR`, `G_IMPR_NBR_B`, `G_INS`, `G_LETTER_DT`, `G_LETTER_NBR`, `G_MINS_COMM_CD`, `G_MOBILE_NO`, `G_OLD_IMPR_TYPE_CD`, `G_OLD_PORT_CD`, `G_PORT_CD`, `G_SET`, `G_STAT_CLR`, `G_STAT_QUE`, `G_SUPP_TITLE_CD`, `G_VALID`. Several are written but never read by IMPR1110 (kept until the other IMPR forms are analysed) |

### 13.3 Other new components

- 13 shared LOVs (§6).
- Text Message `IMPR1110_PRE_INSERT_CONFIRM` (§11).
- Navigation menu entry for page 1110 (§2).
- **Not created:** Authorization Schemes (CLAUDE.md §8: page access from the application privileges;
  function rights from the *Page Functions* list, SC_SYSOBJ_ROLE_PRIVS), JavaScript files, AJAX callbacks,
  collections.

---

## 14. Traceability matrix (every object of the XML)

The rows of revision 1, re-mapped to the components and package members of this revision (generated). 5
blocks, 158 items, 323 triggers, 53 program units, 8 LOVs, 9 record groups (+ runtime CGDV$DLRG), 9 alerts, 5
canvases, 1 window, 24 parameters, 45 globals, 17 libraries and the called forms.
`DROPPED` = no APEX component (reason in *Notes*). `TODO` = depends on a missing source or a form not yet
converted. *IMPR1110 (private X)* = converted Forms code inside the package, reached through the entry
points of §7–§10.

| # | Forms object type | Forms object | APEX component type | APEX component | Page | PL/SQL member | Status | Notes |
|---|---|---|---|---|---|---|---|---|
| 1 | BLOCK | TITLE | REGION | - | - | - | DROPPED | title bar -> APEX page title / header |
| 2 | ITEM | TITLE.CGSO$CHECK_BOX_U | ITEM | - | - | - | DROPPED | OLB block TITLE |
| 3 | ITEM | TITLE.CGSO$CHAR_ARB_ED | ITEM | - | - | - | DROPPED | OLB block TITLE |
| 4 | ITEM | TITLE.CGSO$CHAR_ARB_DO_MLINE | ITEM | - | - | - | DROPPED | OLB block TITLE |
| 5 | ITEM | TITLE.CGSO$CHAR_ARB_ORA_LOV | ITEM | - | - | - | DROPPED | OLB block TITLE |
| 6 | ITEM | TITLE.CGSO$CHAR_ARB_DO_ENB_Y | ITEM | - | - | - | DROPPED | OLB block TITLE |
| 7 | ITEM | TITLE.CGSO$CHAR_ARB_MLINE | ITEM | - | - | - | DROPPED | OLB block TITLE |
| 8 | ITEM | TITLE.CGSO$CHAR_ARB | ITEM | - | - | - | DROPPED | OLB block TITLE |
| 9 | ITEM | TITLE.CGSO$CHAR_ARB_DO | ITEM | - | - | - | DROPPED | OLB block TITLE |
| 10 | ITEM | TITLE.SCREEN_NAME | ITEM | - | - | - | DROPPED | OLB block TITLE |
| 11 | ITEM | TITLE.USER_NAME | ITEM | - | - | - | DROPPED | OLB block TITLE |
| 12 | ITEM | TITLE.SYSTEM_DATE | ITEM | - | - | - | DROPPED | OLB block TITLE |
| 13 | ITEM | TITLE.VERSION | ITEM | - | - | - | DROPPED | OLB block TITLE |
| 14 | BLOCK | EDI_MSG | REGION | - | - | - | DROPPED | EDI message ticker (units not called) |
| 15 | ITEM | EDI_MSG.EDI_MSG_TXT | ITEM | - | - | - | DROPPED | OLB block EDI_MSG |
| 16 | ITEM | EDI_MSG.EDI_MSG_LOVE_BUT | ITEM | - | - | - | DROPPED | OLB block EDI_MSG |
| 17 | BLOCK | LSIDE | REGION | - | - | - | DROPPED | side function menu -> page 0 FUNCS + region FUNCS (f345 Page Functions list) |
| 18 | ITEM | LSIDE.FN1 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 19 | ITEM | LSIDE.FN50 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 20 | ITEM | LSIDE.FN2 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 21 | ITEM | LSIDE.FN49 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 22 | ITEM | LSIDE.FN3 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 23 | ITEM | LSIDE.FN48 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 24 | ITEM | LSIDE.FN4 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 25 | ITEM | LSIDE.FN47 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 26 | ITEM | LSIDE.FN5 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 27 | ITEM | LSIDE.FN46 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 28 | ITEM | LSIDE.FN6 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 29 | ITEM | LSIDE.FN45 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 30 | ITEM | LSIDE.FN7 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 31 | ITEM | LSIDE.FN44 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 32 | ITEM | LSIDE.FN8 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 33 | ITEM | LSIDE.FN43 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 34 | ITEM | LSIDE.FN9 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 35 | ITEM | LSIDE.FN42 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 36 | ITEM | LSIDE.FN10 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 37 | ITEM | LSIDE.FN41 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 38 | ITEM | LSIDE.FN11 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 39 | ITEM | LSIDE.FN40 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 40 | ITEM | LSIDE.FN12 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 41 | ITEM | LSIDE.FN39 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 42 | ITEM | LSIDE.FN13 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 43 | ITEM | LSIDE.FN38 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 44 | ITEM | LSIDE.FN14 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 45 | ITEM | LSIDE.FN37 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 46 | ITEM | LSIDE.FN15 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 47 | ITEM | LSIDE.FN36 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 48 | ITEM | LSIDE.FN16 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 49 | ITEM | LSIDE.FN17 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 50 | ITEM | LSIDE.FN34 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 51 | ITEM | LSIDE.FN35 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 52 | ITEM | LSIDE.FN18 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 53 | ITEM | LSIDE.FN33 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 54 | ITEM | LSIDE.FN19 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 55 | ITEM | LSIDE.FN32 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 56 | ITEM | LSIDE.FN20 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 57 | ITEM | LSIDE.FN31 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 58 | ITEM | LSIDE.FN21 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 59 | ITEM | LSIDE.FN30 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 60 | ITEM | LSIDE.FN22 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 61 | ITEM | LSIDE.FN29 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 62 | ITEM | LSIDE.FN23 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 63 | ITEM | LSIDE.FN28 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 64 | ITEM | LSIDE.FN24 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 65 | ITEM | LSIDE.FN27 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 66 | ITEM | LSIDE.FN25 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 67 | ITEM | LSIDE.FN26 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 68 | BLOCK | TOOLBAR | REGION | P0_ACTIONS (page 0 toolbar, f345) | 0 | - | MAPPED | OLB toolbar -> f345 page 0 toolbar CREATE / SAVE / DELETE / SEARCH / CLEAR / FUNCS / BACK |
| 69 | ITEM | TOOLBAR.DUMMY | ITEM | - | - | - | DROPPED | OLB block TOOLBAR |
| 70 | ITEM | TOOLBAR.SAVE | BUTTON | SAVE / CREATE (page 0 toolbar) | 0 | - | MAPPED | f345 page 0 toolbar button |
| 71 | ITEM | TOOLBAR.CLEAR_ALL | BUTTON | CLEAR (page 0 toolbar) | 0 | - | MAPPED | f345 page 0 toolbar button |
| 72 | ITEM | TOOLBAR.EXIT | BUTTON | BACK (page 0 toolbar) | 0 | - | MAPPED | f345 page 0 toolbar button |
| 73 | ITEM | TOOLBAR.EXIT1 | ITEM | - | - | - | DROPPED | OLB block TOOLBAR |
| 74 | ITEM | TOOLBAR.ENTER | BUTTON | SEARCH (page 0 toolbar) -> page 111001 | 0 | - | MAPPED | f345 page 0 toolbar button |
| 75 | ITEM | TOOLBAR.EXECUTE | BUTTON | SEARCH (page 0 toolbar) -> page 111001 | 0 | - | MAPPED | f345 page 0 toolbar button |
| 76 | ITEM | TOOLBAR.REMOVE | BUTTON | DELETE (page 0 toolbar, confirm) | 0 | - | MAPPED | f345 page 0 toolbar button |
| 77 | ITEM | TOOLBAR.LIST_VALUE | BUTTON | - | 0 | - | DROPPED | Popup LOV icon replaces the LOV toolbar button |
| 78 | ITEM | TOOLBAR.HELP | ITEM | - | - | - | DROPPED | OLB block TOOLBAR |
| 79 | ITEM | TOOLBAR.LAST_REC | ITEM | - | - | - | DROPPED | OLB block TOOLBAR |
| 80 | ITEM | TOOLBAR.RE_ENTER_QUERY | BUTTON | SEARCH (page 0 toolbar) -> page 111001 | 0 | - | MAPPED | f345 page 0 toolbar button |
| 81 | ITEM | TOOLBAR.FIRST_REC | ITEM | - | - | - | DROPPED | OLB block TOOLBAR |
| 82 | ITEM | TOOLBAR.PAGE_UP | ITEM | - | - | - | DROPPED | OLB block TOOLBAR |
| 83 | ITEM | TOOLBAR.PAGE_DOWN | ITEM | - | - | - | DROPPED | OLB block TOOLBAR |
| 84 | ITEM | TOOLBAR.FUN_BUT | BUTTON | FUNCS (page 0 toolbar) -> region FUNCS | 0 | - | MAPPED | f345 page 0 toolbar button |
| 85 | BLOCK | IMPORTERS | REGION | IMPORTERS (Form region on IMPORTERS, primary key ROWID, template Interactive Report, page 1110) | 1110 | IMPR1110 | MAPPED | single-record base-table block; native Form DML (Process form IMPORTERS) + KEY-DELREC |
| 86 | ITEM | IMPORTERS.SDP_PORT_STATUS | ITEM | P1110_SDP_PORT_STATUS | 1110 | - | MAPPED | - |
| 87 | ITEM | IMPORTERS.L_CT_CITY_STATUS2 | ITEM | P1110_L_CT_CITY_STATUS2 | 1110 | - | MAPPED | - |
| 88 | ITEM | IMPORTERS.L_CT_CITY_STATUS | ITEM | P1110_L_CT_CITY_STATUS | 1110 | - | MAPPED | - |
| 89 | ITEM | IMPORTERS.PORT_CD | ITEM | P1110_PORT_CD | 1110 | - | MAPPED | - |
| 90 | ITEM | IMPORTERS.PORT_CD2 | ITEM | - | - | - | DROPPED | LOV button - Popup LOV / select list has its own control |
| 91 | ITEM | IMPORTERS.PORT_NAME | ITEM | P1110_PORT_NAME | 1110 | - | MAPPED | - |
| 92 | ITEM | IMPORTERS.HQ_IMPR_NBR | ITEM | P1110_HQ_IMPR_NBR | 1110 | - | MAPPED | - |
| 93 | ITEM | IMPORTERS.IMPR_NBR | ITEM | P1110_IMPR_NBR | 1110 | - | MAPPED | - |
| 94 | ITEM | IMPORTERS.SUSPN_STATUS | ITEM | P1110_SUSPN_STATUS | 1110 | - | MAPPED | - |
| 95 | ITEM | IMPORTERS.STATUS_DESC | ITEM | P1110_STATUS_DESC | 1110 | - | MAPPED | - |
| 96 | ITEM | IMPORTERS.BUS_ID_STATUS | ITEM | P1110_BUS_ID_STATUS | 1110 | - | MAPPED | - |
| 97 | ITEM | IMPORTERS.IMPR_TYPE_CD | ITEM | P1110_IMPR_TYPE_CD | 1110 | - | MAPPED | read-only: DA IMPR_TYPE_CD READ ONLY |
| 98 | ITEM | IMPORTERS.IMPR_TYPE_CD2 | ITEM | - | - | - | DROPPED | LOV button - Popup LOV / select list has its own control |
| 99 | ITEM | IMPORTERS.IMPR_TYPE_NAME | ITEM | P1110_IMPR_TYPE_NAME | 1110 | - | MAPPED | - |
| 100 | ITEM | IMPORTERS.BUS_ID_EXPRD_DT | ITEM | P1110_BUS_ID_EXPRD_DT | 1110 | - | MAPPED | read-only: DA BUS_ID_EXPRD_DT READ ONLY |
| 101 | ITEM | IMPORTERS.BUS_ID_TYPE_CD | ITEM | P1110_BUS_ID_TYPE_CD | 1110 | - | MAPPED | read-only: BUS_ID_TYPE_CD_IS_READ_ONLY |
| 102 | ITEM | IMPORTERS.BUTT | ITEM | - | - | - | DROPPED | LOV button - Popup LOV / select list has its own control |
| 103 | ITEM | IMPORTERS.BUS_ID_TYPE_NAME | ITEM | P1110_BUS_ID_TYPE_NAME | 1110 | - | MAPPED | - |
| 104 | ITEM | IMPORTERS.COMM_RGSTRTN_TYPE | ITEM | P1110_COMM_RGSTRTN_TYPE | 1110 | - | MAPPED | read-only: DA COMM_RGSTRTN_TYPE READ ONLY |
| 105 | ITEM | IMPORTERS.CITY_CODE_OF_ID | ITEM | P1110_CITY_CODE_OF_ID | 1110 | - | MAPPED | read-only: DA CITY_CODE_OF_ID READ ONLY |
| 106 | ITEM | IMPORTERS.CITY_CODE_OF_ID2 | ITEM | - | - | - | DROPPED | LOV button - Popup LOV / select list has its own control |
| 107 | ITEM | IMPORTERS.ID_CITY_NAME | ITEM | P1110_ID_CITY_NAME | 1110 | - | MAPPED | - |
| 108 | ITEM | IMPORTERS.BUS_ID | ITEM | P1110_BUS_ID | 1110 | - | MAPPED | read-only: DA BUS_ID READ ONLY |
| 109 | ITEM | IMPORTERS.BRNH_ID_MINS_COMM_CD | ITEM | P1110_BRNH_ID_MINS_COMM_CD | 1110 | - | MAPPED | - |
| 110 | ITEM | IMPORTERS.BRNH_CITY_CD | ITEM | P1110_BRNH_CITY_CD | 1110 | - | MAPPED | read-only: DA BRNH_CITY_CD READ ONLY |
| 111 | ITEM | IMPORTERS.BRNH_CITY_CD_LOV | ITEM | - | - | - | DROPPED | LOV button - Popup LOV / select list has its own control |
| 112 | ITEM | IMPORTERS.BRNH_CITY_NAME | ITEM | P1110_BRNH_CITY_NAME | 1110 | - | MAPPED | - |
| 113 | ITEM | IMPORTERS.BUS_ID_BRNCH | ITEM | P1110_BUS_ID_BRNCH | 1110 | - | MAPPED | read-only: DA BUS_ID_BRNCH READ ONLY |
| 114 | ITEM | IMPORTERS.CTRY_CD | ITEM | P1110_CTRY_CD | 1110 | - | MAPPED | read-only: DA CTRY_CD READ ONLY |
| 115 | ITEM | IMPORTERS.CTRY_CD2 | ITEM | - | - | - | DROPPED | LOV button - Popup LOV / select list has its own control |
| 116 | ITEM | IMPORTERS.CRTY_ARBC_NAME | ITEM | P1110_CRTY_ARBC_NAME | 1110 | - | MAPPED | - |
| 117 | ITEM | IMPORTERS.IMPR_EXPR_TYPE | ITEM | P1110_IMPR_EXPR_TYPE | 1110 | - | MAPPED | read-only: IMPR_EXPR_TYPE_IS_READ_ONLY |
| 118 | ITEM | IMPORTERS.CTRY_CTRY_STATUS | ITEM | P1110_CTRY_CTRY_STATUS | 1110 | - | MAPPED | - |
| 119 | ITEM | IMPORTERS.ID_MINS_COMM_CD | ITEM | P1110_ID_MINS_COMM_CD | 1110 | - | MAPPED | - |
| 120 | ITEM | IMPORTERS.ITIDT_NOTE | ITEM | P1110_ITIDT_NOTE | 1110 | - | MAPPED | - |
| 121 | ITEM | IMPORTERS.ARBC_IMPR_NAME | ITEM | P1110_ARBC_IMPR_NAME | 1110 | - | MAPPED | read-only: DA ARBC_IMPR_NAME READ ONLY |
| 122 | ITEM | IMPORTERS.IMPR_NAME_STD | ITEM | P1110_IMPR_NAME_STD | 1110 | - | MAPPED | - |
| 123 | ITEM | IMPORTERS.LST_TRAN_DT | ITEM | P1110_LST_TRAN_DT | 1110 | - | MAPPED | - |
| 124 | ITEM | IMPORTERS.IMPD_STMT_NBR | ITEM | P1110_IMPD_STMT_NBR | 1110 | - | MAPPED | - |
| 125 | ITEM | IMPORTERS.IMPR_DATA_SRCE | ITEM | P1110_IMPR_DATA_SRCE | 1110 | - | MAPPED | - |
| 126 | ITEM | IMPORTERS.ENG_IMPR_NAME | ITEM | P1110_ENG_IMPR_NAME | 1110 | - | MAPPED | - |
| 127 | ITEM | IMPORTERS.IMPR_CNTCT_NAME | ITEM | P1110_IMPR_CNTCT_NAME | 1110 | - | MAPPED | - |
| 128 | ITEM | IMPORTERS.IMPR_ADDRESS | ITEM | P1110_IMPR_ADDRESS | 1110 | - | MAPPED | - |
| 129 | ITEM | IMPORTERS.BUS_ID_ISSUE_DT | ITEM | P1110_BUS_ID_ISSUE_DT | 1110 | - | MAPPED | - |
| 130 | ITEM | IMPORTERS.STATUS | ITEM | P1110_STATUS | 1110 | - | MAPPED | - |
| 131 | ITEM | IMPORTERS.IMPR_NBR_PARENT | ITEM | P1110_IMPR_NBR_PARENT | 1110 | - | MAPPED | - |
| 132 | ITEM | IMPORTERS.IMPR_NBR_PARENT2 | ITEM | - | - | - | DROPPED | LOV button - Popup LOV / select list has its own control |
| 133 | ITEM | IMPORTERS.IMPR_NAME_PARENT | ITEM | P1110_IMPR_NAME_PARENT | 1110 | - | MAPPED | - |
| 134 | ITEM | IMPORTERS.WASL_CITY_NAME | ITEM | P1110_WASL_CITY_NAME | 1110 | - | MAPPED | - |
| 135 | ITEM | IMPORTERS.ADD_CTRY_CD | ITEM | P1110_ADD_CTRY_CD | 1110 | - | MAPPED | - |
| 136 | ITEM | IMPORTERS.ADD_CTRY_CD2 | ITEM | - | - | - | DROPPED | LOV button - Popup LOV / select list has its own control |
| 137 | ITEM | IMPORTERS.ADD_CRTY_ARBC_NAME | ITEM | P1110_ADD_CRTY_ARBC_NAME | 1110 | - | MAPPED | - |
| 138 | ITEM | IMPORTERS.CITY_CODE | ITEM | P1110_CITY_CODE | 1110 | - | MAPPED | - |
| 139 | ITEM | IMPORTERS.CITY_CODE2 | ITEM | - | - | - | DROPPED | LOV button - Popup LOV / select list has its own control |
| 140 | ITEM | IMPORTERS.CITY_NAME | ITEM | P1110_CITY_NAME | 1110 | - | MAPPED | - |
| 141 | ITEM | IMPORTERS.IMPR_POB_NBR | ITEM | P1110_IMPR_POB_NBR | 1110 | - | MAPPED | read-only: DA REGISTER_ITEMS READ ONLY |
| 142 | ITEM | IMPORTERS.IMPR_ZIP_CD | ITEM | P1110_IMPR_ZIP_CD | 1110 | - | MAPPED | read-only: DA REGISTER_ITEMS READ ONLY |
| 143 | ITEM | IMPORTERS.IMPR_TEL_NBR | ITEM | P1110_IMPR_TEL_NBR | 1110 | - | MAPPED | read-only: DA IMPR_TEL_NBR READ ONLY |
| 144 | ITEM | IMPORTERS.IMPR_FAX_NBR | ITEM | P1110_IMPR_FAX_NBR | 1110 | - | MAPPED | read-only: DA REGISTER_ITEMS READ ONLY |
| 145 | ITEM | IMPORTERS.IMPR_TELEX_NBR | ITEM | P1110_IMPR_TELEX_NBR | 1110 | - | MAPPED | read-only: DA REGISTER_ITEMS READ ONLY |
| 146 | ITEM | IMPORTERS.B_EMAIL | ITEM | P1110_B_EMAIL | 1110 | - | MAPPED | - |
| 147 | ITEM | IMPORTERS.EMAIL | ITEM | P1110_EMAIL | 1110 | - | MAPPED | - |
| 148 | ITEM | IMPORTERS.B_MOBILE_NO | ITEM | P1110_B_MOBILE_NO | 1110 | - | MAPPED | - |
| 149 | ITEM | IMPORTERS.MOBILE_NO | ITEM | P1110_MOBILE_NO | 1110 | - | MAPPED | - |
| 150 | ITEM | IMPORTERS.BANK_IBAN | ITEM | P1110_BANK_IBAN | 1110 | - | MAPPED | - |
| 151 | ITEM | IMPORTERS.B_ID_NBR | ITEM | P1110_B_ID_NBR | 1110 | - | MAPPED | read-only: DA B_ID_NBR READ ONLY |
| 152 | ITEM | IMPORTERS.ID_NBR | ITEM | P1110_ID_NBR | 1110 | - | MAPPED | - |
| 153 | ITEM | IMPORTERS.CAR_AGENT_FLAG | ITEM | P1110_CAR_AGENT_FLAG | 1110 | - | MAPPED | read-only: DA CAR_AGENT_FLAG READ ONLY |
| 154 | ITEM | IMPORTERS.EXPRESS_POST | ITEM | P1110_EXPRESS_POST | 1110 | - | MAPPED | read-only: EXPRESS_POST_IS_READ_ONLY |
| 155 | ITEM | IMPORTERS.IMPR_ID_TYPE | ITEM | P1110_IMPR_ID_TYPE | 1110 | - | MAPPED | - |
| 156 | ITEM | IMPORTERS.CTRY_CD_OF_ID | ITEM | P1110_CTRY_CD_OF_ID | 1110 | - | MAPPED | - |
| 157 | ITEM | IMPORTERS.EXPD_STMT_NBR | ITEM | P1110_EXPD_STMT_NBR | 1110 | - | MAPPED | - |
| 158 | ITEM | IMPORTERS.WVR_ENTRY_NBR | ITEM | P1110_WVR_ENTRY_NBR | 1110 | - | MAPPED | - |
| 159 | ITEM | IMPORTERS.ACTIVITY | ITEM | P1110_ACTIVITY | 1110 | - | MAPPED | read-only: DA ACTIVITY READ ONLY |
| 160 | ITEM | IMPORTERS.CUSTOMS_ENTERED | ITEM | P1110_CUSTOMS_ENTERED | 1110 | - | MAPPED | - |
| 161 | ITEM | IMPORTERS.CUSTOMS_ENTERED2 | ITEM | - | - | - | DROPPED | LOV button - Popup LOV / select list has its own control |
| 162 | ITEM | IMPORTERS.CREATION_FLAG | ITEM | P1110_CREATION_FLAG | 1110 | - | MAPPED | - |
| 163 | ITEM | IMPORTERS.CREATION_FLAG2 | ITEM | - | - | - | DROPPED | LOV button - Popup LOV / select list has its own control |
| 164 | TRIGGER | FORM.KEY-EDIT | - | - | - | - | DROPPED | NIB.KEY_EDIT (MISSING SOURCE, toolbar key library) - APEX buttons/keys |
| 165 | TRIGGER | FORM.KEY-DUPREC | - | - | - | - | DROPPED | NIB.KEY_DUPREC (MISSING SOURCE, toolbar key library) - APEX buttons/keys |
| 166 | TRIGGER | FORM.PRE-FORM | - | - | - | - | DROPPED | NIB.PRE_FORM (MISSING SOURCE), version globals, NLS date compat, help path - not needed in APEX; date masks set per item |
| 167 | TRIGGER | FORM.WHEN-NEW-FORM-INSTANCE | PROCESS | WHEN-NEW-FORM-INSTANCE | 1110 | IMPR1110.WHEN_NEW_FORM_INSTANCE | MAPPED | Process "WHEN-NEW-FORM-INSTANCE" (Before Header). NIB.WHEN_NEW_FORM_INSTANCE + CG$WHEN_NEW_FORM_INSTANCE dropped (toolbar library / list population) |
| 168 | TRIGGER | FORM.WHEN-WINDOW-ACTIVATED | - | - | - | - | DROPPED | NIB.WHEN_WINDOW_ACTIVATED (MISSING SOURCE, toolbar key library) - APEX buttons/keys |
| 169 | TRIGGER | FORM.KEY-ENTQRY | - | - | - | - | DROPPED | NIB.KEY_ENTQRY (MISSING SOURCE, toolbar key library) - APEX buttons/keys |
| 170 | TRIGGER | FORM.ON-ERROR | - | - | - | - | DROPPED | NIB.ON_ERROR (MISSING SOURCE, toolbar key library) - APEX buttons/keys |
| 171 | TRIGGER | FORM.ON-MESSAGE | - | - | - | - | DROPPED | NIB.ON_MESSAGE (MISSING SOURCE, toolbar key library) - APEX buttons/keys |
| 172 | TRIGGER | FORM.KEY-CLRBLK | - | - | - | - | DROPPED | NIB.KEY_CLRBLK (MISSING SOURCE, toolbar key library) - APEX buttons/keys |
| 173 | TRIGGER | FORM.KEY-DELREC | - | - | - | - | DROPPED | NIB.KEY_DELREC (MISSING SOURCE, toolbar key library) - APEX buttons/keys |
| 174 | TRIGGER | FORM.KEY-F5 | - | - | - | - | DROPPED | NIB.KEY_F5 (MISSING SOURCE, toolbar key library) - APEX buttons/keys |
| 175 | TRIGGER | FORM.KEY-F4 | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 176 | TRIGGER | FORM.KEY-NXTREC | - | - | - | - | DROPPED | NIB.KEY_NXTREC (MISSING SOURCE, toolbar key library) - APEX buttons/keys |
| 177 | TRIGGER | FORM.KEY-PRVREC | - | - | - | - | DROPPED | NIB.KEY_PRVREC (MISSING SOURCE, toolbar key library) - APEX buttons/keys |
| 178 | TRIGGER | FORM.KEY-DOWN | - | - | - | - | DROPPED | NIB.KEY_DOWN (MISSING SOURCE, toolbar key library) - APEX buttons/keys |
| 179 | TRIGGER | FORM.KEY-UP | - | - | - | - | DROPPED | NIB.KEY_UP (MISSING SOURCE, toolbar key library) - APEX buttons/keys |
| 180 | TRIGGER | FORM.KEY-SCRUP | - | - | - | - | DROPPED | NIB.KEY_SCRUP (MISSING SOURCE, toolbar key library) - APEX buttons/keys |
| 181 | TRIGGER | FORM.KEY-SCRDOWN | - | - | - | - | DROPPED | NIB.KEY_SCRDOWN (MISSING SOURCE, toolbar key library) - APEX buttons/keys |
| 182 | TRIGGER | FORM.KEY-PRINT | - | - | - | - | DROPPED | NIB.KEY_PRINT (MISSING SOURCE, toolbar key library) - APEX buttons/keys |
| 183 | TRIGGER | FORM.KEY-EXIT | - | - | - | - | DROPPED | NIB.KEY_EXIT (MISSING SOURCE, toolbar key library) - APEX buttons/keys |
| 184 | TRIGGER | FORM.WHEN-MOUSE-DOWN | - | - | - | - | DROPPED | NIB.WHEN_MOUSE_DOWN (MISSING SOURCE, toolbar key library) - APEX buttons/keys |
| 185 | TRIGGER | FORM.KEY-EXEQRY | - | - | - | - | DROPPED | NIB.KEY_EXEQRY (MISSING SOURCE, toolbar key library) - APEX buttons/keys |
| 186 | TRIGGER | FORM.KEY-F9 | DYNAMIC_ACTION | FUNCS (page 0 toolbar) -> region FUNCS | 0 | - | MAPPED | Opens region FUNCS (f345 Page Functions list, rights from SC_SYSOBJ_ROLE_PRIVS); one custom-event DA per function code on page 1110 |
| 187 | TRIGGER | FORM.WHEN-TIMER-EXPIRED | - | - | - | - | DROPPED | NIB.WHEN_TIMER_EXPIRED (MISSING SOURCE, toolbar key library) - APEX buttons/keys |
| 188 | TRIGGER | FORM.KEY-HELP | - | - | - | - | DROPPED | CG help call; help file is empty in the form |
| 189 | TRIGGER | FORM.KEY-CLRFRM | BUTTON | CLEAR (page 0 toolbar) | 0 | - | MAPPED | page 0 CLEAR (redirect, clear cache 0 + page); list population dropped |
| 190 | TRIGGER | TITLE.CGSO$CHAR_ARB_ED.KEY-LISTVAL | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 191 | TRIGGER | TITLE.CGSO$CHAR_ARB_DO_ENB_Y.KEY-LISTVAL | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 192 | TRIGGER | TITLE.CGSO$CHAR_ARB_MLINE.KEY-LISTVAL | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 193 | TRIGGER | TITLE.CGSO$CHAR_ARB.KEY-LISTVAL | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 194 | TRIGGER | TITLE.CGSO$CHAR_ARB_DO.KEY-LISTVAL | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 195 | TRIGGER | TITLE.SYSTEM_DATE.WHEN-VALIDATE-ITEM | - | - | - | - | DROPPED | Title bar date (OLB block TITLE) |
| 196 | TRIGGER | EDI_MSG.EDI_MSG_LOVE_BUT.WHEN-BUTTON-PRESSED | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 197 | TRIGGER | LSIDE.FN1.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 198 | TRIGGER | LSIDE.FN1.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 199 | TRIGGER | LSIDE.FN1.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 200 | TRIGGER | LSIDE.FN50.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 201 | TRIGGER | LSIDE.FN50.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 202 | TRIGGER | LSIDE.FN50.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 203 | TRIGGER | LSIDE.FN2.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 204 | TRIGGER | LSIDE.FN2.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 205 | TRIGGER | LSIDE.FN2.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 206 | TRIGGER | LSIDE.FN49.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 207 | TRIGGER | LSIDE.FN49.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 208 | TRIGGER | LSIDE.FN49.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 209 | TRIGGER | LSIDE.FN3.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 210 | TRIGGER | LSIDE.FN3.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 211 | TRIGGER | LSIDE.FN3.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 212 | TRIGGER | LSIDE.FN48.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 213 | TRIGGER | LSIDE.FN48.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 214 | TRIGGER | LSIDE.FN48.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 215 | TRIGGER | LSIDE.FN4.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 216 | TRIGGER | LSIDE.FN4.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 217 | TRIGGER | LSIDE.FN4.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 218 | TRIGGER | LSIDE.FN47.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 219 | TRIGGER | LSIDE.FN47.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 220 | TRIGGER | LSIDE.FN47.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 221 | TRIGGER | LSIDE.FN5.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 222 | TRIGGER | LSIDE.FN5.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 223 | TRIGGER | LSIDE.FN5.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 224 | TRIGGER | LSIDE.FN46.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 225 | TRIGGER | LSIDE.FN46.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 226 | TRIGGER | LSIDE.FN46.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 227 | TRIGGER | LSIDE.FN6.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 228 | TRIGGER | LSIDE.FN6.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 229 | TRIGGER | LSIDE.FN6.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 230 | TRIGGER | LSIDE.FN45.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 231 | TRIGGER | LSIDE.FN45.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 232 | TRIGGER | LSIDE.FN45.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 233 | TRIGGER | LSIDE.FN7.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 234 | TRIGGER | LSIDE.FN7.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 235 | TRIGGER | LSIDE.FN7.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 236 | TRIGGER | LSIDE.FN44.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 237 | TRIGGER | LSIDE.FN44.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 238 | TRIGGER | LSIDE.FN44.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 239 | TRIGGER | LSIDE.FN8.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 240 | TRIGGER | LSIDE.FN8.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 241 | TRIGGER | LSIDE.FN8.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 242 | TRIGGER | LSIDE.FN43.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 243 | TRIGGER | LSIDE.FN43.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 244 | TRIGGER | LSIDE.FN43.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 245 | TRIGGER | LSIDE.FN9.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 246 | TRIGGER | LSIDE.FN9.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 247 | TRIGGER | LSIDE.FN9.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 248 | TRIGGER | LSIDE.FN42.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 249 | TRIGGER | LSIDE.FN42.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 250 | TRIGGER | LSIDE.FN42.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 251 | TRIGGER | LSIDE.FN10.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 252 | TRIGGER | LSIDE.FN10.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 253 | TRIGGER | LSIDE.FN10.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 254 | TRIGGER | LSIDE.FN41.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 255 | TRIGGER | LSIDE.FN41.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 256 | TRIGGER | LSIDE.FN41.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 257 | TRIGGER | LSIDE.FN11.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 258 | TRIGGER | LSIDE.FN11.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 259 | TRIGGER | LSIDE.FN11.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 260 | TRIGGER | LSIDE.FN40.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 261 | TRIGGER | LSIDE.FN40.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 262 | TRIGGER | LSIDE.FN40.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 263 | TRIGGER | LSIDE.FN12.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 264 | TRIGGER | LSIDE.FN12.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 265 | TRIGGER | LSIDE.FN12.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 266 | TRIGGER | LSIDE.FN39.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 267 | TRIGGER | LSIDE.FN39.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 268 | TRIGGER | LSIDE.FN39.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 269 | TRIGGER | LSIDE.FN13.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 270 | TRIGGER | LSIDE.FN13.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 271 | TRIGGER | LSIDE.FN13.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 272 | TRIGGER | LSIDE.FN38.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 273 | TRIGGER | LSIDE.FN38.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 274 | TRIGGER | LSIDE.FN38.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 275 | TRIGGER | LSIDE.FN14.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 276 | TRIGGER | LSIDE.FN14.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 277 | TRIGGER | LSIDE.FN14.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 278 | TRIGGER | LSIDE.FN37.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 279 | TRIGGER | LSIDE.FN37.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 280 | TRIGGER | LSIDE.FN37.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 281 | TRIGGER | LSIDE.FN15.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 282 | TRIGGER | LSIDE.FN15.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 283 | TRIGGER | LSIDE.FN15.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 284 | TRIGGER | LSIDE.FN36.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 285 | TRIGGER | LSIDE.FN36.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 286 | TRIGGER | LSIDE.FN36.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 287 | TRIGGER | LSIDE.FN16.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 288 | TRIGGER | LSIDE.FN16.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 289 | TRIGGER | LSIDE.FN16.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 290 | TRIGGER | LSIDE.FN17.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 291 | TRIGGER | LSIDE.FN17.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 292 | TRIGGER | LSIDE.FN17.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 293 | TRIGGER | LSIDE.FN34.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 294 | TRIGGER | LSIDE.FN34.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 295 | TRIGGER | LSIDE.FN34.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 296 | TRIGGER | LSIDE.FN35.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 297 | TRIGGER | LSIDE.FN35.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 298 | TRIGGER | LSIDE.FN35.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 299 | TRIGGER | LSIDE.FN18.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 300 | TRIGGER | LSIDE.FN18.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 301 | TRIGGER | LSIDE.FN18.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 302 | TRIGGER | LSIDE.FN33.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 303 | TRIGGER | LSIDE.FN33.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 304 | TRIGGER | LSIDE.FN33.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 305 | TRIGGER | LSIDE.FN19.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 306 | TRIGGER | LSIDE.FN19.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 307 | TRIGGER | LSIDE.FN19.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 308 | TRIGGER | LSIDE.FN32.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 309 | TRIGGER | LSIDE.FN32.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 310 | TRIGGER | LSIDE.FN32.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 311 | TRIGGER | LSIDE.FN20.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 312 | TRIGGER | LSIDE.FN20.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 313 | TRIGGER | LSIDE.FN20.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 314 | TRIGGER | LSIDE.FN31.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 315 | TRIGGER | LSIDE.FN31.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 316 | TRIGGER | LSIDE.FN31.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 317 | TRIGGER | LSIDE.FN21.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 318 | TRIGGER | LSIDE.FN21.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 319 | TRIGGER | LSIDE.FN21.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 320 | TRIGGER | LSIDE.FN30.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 321 | TRIGGER | LSIDE.FN30.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 322 | TRIGGER | LSIDE.FN30.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 323 | TRIGGER | LSIDE.FN22.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 324 | TRIGGER | LSIDE.FN22.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 325 | TRIGGER | LSIDE.FN22.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 326 | TRIGGER | LSIDE.FN29.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 327 | TRIGGER | LSIDE.FN29.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 328 | TRIGGER | LSIDE.FN29.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 329 | TRIGGER | LSIDE.FN23.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 330 | TRIGGER | LSIDE.FN23.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 331 | TRIGGER | LSIDE.FN23.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 332 | TRIGGER | LSIDE.FN28.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 333 | TRIGGER | LSIDE.FN28.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 334 | TRIGGER | LSIDE.FN28.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 335 | TRIGGER | LSIDE.FN24.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 336 | TRIGGER | LSIDE.FN24.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 337 | TRIGGER | LSIDE.FN24.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 338 | TRIGGER | LSIDE.FN27.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 339 | TRIGGER | LSIDE.FN27.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 340 | TRIGGER | LSIDE.FN27.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 341 | TRIGGER | LSIDE.FN25.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 342 | TRIGGER | LSIDE.FN25.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 343 | TRIGGER | LSIDE.FN25.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 344 | TRIGGER | LSIDE.FN26.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 345 | TRIGGER | LSIDE.FN26.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 346 | TRIGGER | LSIDE.FN26.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 347 | TRIGGER | TOOLBAR.KEY-DOWN | - | - | - | - | DROPPED | Function menu keyboard |
| 348 | TRIGGER | TOOLBAR.KEY-UP | - | - | - | - | DROPPED | Function menu keyboard |
| 349 | TRIGGER | TOOLBAR.KEY-NEXT-ITEM | - | - | - | - | DROPPED | Keyboard navigation of the function menu |
| 350 | TRIGGER | TOOLBAR.SAVE.WHEN-BUTTON-PRESSED | BUTTON | SAVE / CREATE (page 0 toolbar) | 0 | - | MAPPED | page 0 SAVE / CREATE -> PRE-*, Process form IMPORTERS, POST-*; title refresh dropped |
| 351 | TRIGGER | TOOLBAR.CLEAR_ALL.WHEN-BUTTON-PRESSED | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 352 | TRIGGER | TOOLBAR.EXIT.WHEN-BUTTON-PRESSED | BUTTON | BACK (page 0 toolbar) | 0 | - | MAPPED | page 0 BACK -> home application; :GLOBAL.EXIT=2 is set by other forms only |
| 353 | TRIGGER | TOOLBAR.EXIT1.WHEN-BUTTON-PRESSED | - | - | - | - | DROPPED | Toolbar button visibility (OLB) |
| 354 | TRIGGER | TOOLBAR.ENTER.WHEN-BUTTON-PRESSED | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 355 | TRIGGER | TOOLBAR.EXECUTE.WHEN-BUTTON-PRESSED | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 356 | TRIGGER | TOOLBAR.REMOVE.WHEN-BUTTON-PRESSED | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 357 | TRIGGER | TOOLBAR.LIST_VALUE.WHEN-BUTTON-PRESSED | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 358 | TRIGGER | TOOLBAR.HELP.WHEN-BUTTON-PRESSED | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 359 | TRIGGER | TOOLBAR.LAST_REC.WHEN-BUTTON-PRESSED | - | - | - | - | DROPPED | Single-record form region |
| 360 | TRIGGER | TOOLBAR.RE_ENTER_QUERY.WHEN-BUTTON-PRESSED | BUTTON | SEARCH (page 0 toolbar) -> page 111001 | 0 | - | MAPPED | page 0 SEARCH opens the search page 111001 IMPR1110_SEARCH (f345 <page>01) |
| 361 | TRIGGER | TOOLBAR.FIRST_REC.WHEN-BUTTON-PRESSED | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 362 | TRIGGER | TOOLBAR.PAGE_UP.WHEN-BUTTON-PRESSED | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 363 | TRIGGER | TOOLBAR.PAGE_DOWN.WHEN-BUTTON-PRESSED | - | - | - | - | DROPPED | Single-record form region |
| 364 | TRIGGER | TOOLBAR.FUN_BUT.WHEN-MOUSE-UP | - | - | - | - | DROPPED | Side function menu (TMPLT) |
| 365 | TRIGGER | TOOLBAR.FUN_BUT.WHEN-MOUSE-DOWN | DYNAMIC_ACTION | FUNCS (page 0 toolbar) -> region FUNCS | 0 | - | MAPPED | Opens region FUNCS (f345 Page Functions list, rights from SC_SYSOBJ_ROLE_PRIVS); one custom-event DA per function code on page 1110 |
| 366 | TRIGGER | IMPORTERS.ON-ERROR | PLSQL | error text of every <ITEM> VALIDATION (PRIVATE_ERROR_TEXT) | 1110 | - | MAPPED | Used by IMPR1110.ERROR_TEXT for DB errors |
| 367 | TRIGGER | IMPORTERS.POST-QUERY | PROCESS | POST-QUERY | 1110 | IMPR1110.POST_QUERY | MAPPED | Process "POST-QUERY" IMPR1110.POST_QUERY |
| 368 | TRIGGER | IMPORTERS.PRE-QUERY | REGION | IMPORTERS_SEARCH (SQL of page 111001) | 1110 | - | MAPPED | EXEC_QUERY_NOW / PRSNL_IMPR / name criterion; PORT_NAME criterion -> region SQL |
| 369 | TRIGGER | IMPORTERS.PRE-INSERT | PROCESS | PRE-INSERT | 1110 | IMPR1110.PRE_INSERT | MAPPED | Process around native Process form; CONFIRM for class 1/type 3 -> DA PRE-INSERT CONFIRM (before submit of CREATE) |
| 370 | TRIGGER | IMPORTERS.KEY-HELP | - | - | - | - | DROPPED | 9 copies of the CG help call; help file is empty |
| 371 | TRIGGER | IMPORTERS.KEY-DELREC | PROCESS | KEY-DELREC | 1110 | IMPR1110.KEY_DELREC | MAPPED | page 0 DELETE (confirm); REMOVE visible/enabled -> button condition |
| 372 | TRIGGER | IMPORTERS.POST-INSERT | PROCESS | POST-INSERT | 1110 | IMPR1110.POST_INSERT | MAPPED | Process around native Process form |
| 373 | TRIGGER | IMPORTERS.POST-UPDATE | PROCESS | POST-UPDATE | 1110 | IMPR1110.POST_UPDATE | MAPPED | Process around native Process form |
| 374 | TRIGGER | IMPORTERS.PRE-DELETE | PROCESS | KEY-DELREC | 1110 | IMPR1110.KEY_DELREC | MAPPED | Called by importers_key_delrec |
| 375 | TRIGGER | IMPORTERS.PRE-RECORD | PROCESS | WHEN-NEW-RECORD-INSTANCE | 1110 | IMPR1110.WHEN_NEW_RECORD_INSTANCE | MAPPED | Parent importer name on record entry |
| 376 | TRIGGER | IMPORTERS.PRE-UPDATE | PROCESS | PRE-UPDATE | 1110 | IMPR1110.PRE_UPDATE | MAPPED | Process around native Process form |
| 377 | TRIGGER | IMPORTERS.WHEN-CLEAR-BLOCK | - | - | - | - | DROPPED | only sets :GLOBAL.STAT_CLR, which no code reads; page 0 CLEAR is a redirect (package 012) |
| 378 | TRIGGER | IMPORTERS.WHEN-CREATE-RECORD | PROCESS | WHEN-CREATE-RECORD | 1110 | IMPR1110.WHEN_CREATE_RECORD | MAPPED | Process "WHEN-CREATE-RECORD"  |
| 379 | TRIGGER | IMPORTERS.WHEN-NEW-ITEM-INSTANCE | DYNAMIC_ACTION | IMPORTERS WHEN-NEW-ITEM-INSTANCE | 1110 | - | MAPPED | EXEC_QUERY_NOW=1 -> re-query (page reload) |
| 380 | TRIGGER | IMPORTERS.WHEN-NEW-RECORD-INSTANCE | PROCESS | WHEN-NEW-RECORD-INSTANCE + DA WHEN-NEW-RECORD-INSTANCE | 1110 | IMPR1110.WHEN_NEW_RECORD_INSTANCE | MAPPED | function codes F1..F5/SF6; CONFIRM F1/F5 -> NEW_RECORD_CONFIRM_TEXT + Confirm DA |
| 381 | TRIGGER | IMPORTERS.SDP_PORT_STATUS.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 382 | TRIGGER | IMPORTERS.L_CT_CITY_STATUS2.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 383 | TRIGGER | IMPORTERS.L_CT_CITY_STATUS.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 384 | TRIGGER | IMPORTERS.PORT_CD.KEY-LISTVAL | LOV | Popup LOV (item is disabled) | - | - | MAPPED | LOV form LOV_SD_PORTS (PORT_TYPE, STATUS=1) -> Popup LOV (item is disabled) |
| 385 | TRIGGER | IMPORTERS.PORT_CD.WHEN-VALIDATE-ITEM | VALIDATION | PORT_CD VALIDATION + DA PORT_CD WHEN-VALIDATE-ITEM | 1110 | IMPR1110.PORT_CD_VALIDATION / IMPR1110.PORT_CD_WHEN_VALIDATE_ITEM | MAPPED | PORT_CD is disabled (WHEN_NEW_FORM_INSTANCE) - kept for completeness |
| 386 | TRIGGER | IMPORTERS.PORT_CD2.WHEN-BUTTON-PRESSED | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV button (GO_ITEM + LIST_VALUES) - Popup LOV has its own button |
| 387 | TRIGGER | IMPORTERS.PORT_NAME.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 388 | TRIGGER | IMPORTERS.HQ_IMPR_NBR.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 389 | TRIGGER | IMPORTERS.HQ_IMPR_NBR.POST-CHANGE | VALIDATION | HQ_IMPR_NBR VALIDATION + DA HQ_IMPR_NBR WHEN-VALIDATE-ITEM | 1110 | IMPR1110.HQ_IMPR_NBR_VALIDATION / IMPR1110.HQ_IMPR_NBR_WHEN_VALIDATE_ITEM | MAPPED | :GLOBAL.FLAGUPDATE := 1 |
| 390 | TRIGGER | IMPORTERS.IMPR_NBR.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 391 | TRIGGER | IMPORTERS.IMPR_NBR.WHEN-VALIDATE-ITEM | VALIDATION | IMPR_NBR VALIDATION + DA IMPR_NBR WHEN-VALIDATE-ITEM | 1110 | IMPR1110.IMPR_NBR_VALIDATION / IMPR1110.IMPR_NBR_WHEN_VALIDATE_ITEM | MAPPED | Existing number -> re-query that importer |
| 392 | TRIGGER | IMPORTERS.SUSPN_STATUS.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 393 | TRIGGER | IMPORTERS.STATUS_DESC.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 394 | TRIGGER | IMPORTERS.IMPR_TYPE_CD.KEY-LISTVAL | LOV | Popup LOV returning 4 columns; post-select logic in package | - | IMPR1110.IMPR_TYPE_CD_LOV_RETURN | MAPPED | LOV form LOV_IMPR_TYPE -> Popup LOV returning 4 columns; post-select logic in package |
| 395 | TRIGGER | IMPORTERS.IMPR_TYPE_CD.WHEN-VALIDATE-ITEM | VALIDATION | IMPR_TYPE_CD VALIDATION + DA IMPR_TYPE_CD WHEN-VALIDATE-ITEM | 1110 | IMPR1110.IMPR_TYPE_CD_VALIDATION / IMPR1110.IMPR_TYPE_CD_VALIDATE_ITEM | MAPPED | Includes CGFK ITIDT check; DO_KEY LIST_VALUES -> (LOV opens from the item) |
| 396 | TRIGGER | IMPORTERS.IMPR_TYPE_CD.POST-CHANGE | VALIDATION | IMPR_TYPE_CD VALIDATION + DA IMPR_TYPE_CD WHEN-VALIDATE-ITEM | 1110 | IMPR1110.IMPR_TYPE_CD_VALIDATION / IMPR1110.IMPR_TYPE_CD_VALIDATE_ITEM | MAPPED | - |
| 397 | TRIGGER | IMPORTERS.IMPR_TYPE_CD.WHEN-NEW-ITEM-INSTANCE | DYNAMIC_ACTION | IMPR_TYPE_CD WHEN-NEW-ITEM-INSTANCE | 1110 | IMPR1110.IMPR_TYPE_CD_NEW_ITEM_INSTANCE | MAPPED | Re-query part -> page submit EXECUTE_QUERY; country 100 defaults |
| 398 | TRIGGER | IMPORTERS.IMPR_TYPE_CD2.WHEN-BUTTON-PRESSED | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV button (GO_ITEM + LIST_VALUES) - Popup LOV has its own button |
| 399 | TRIGGER | IMPORTERS.IMPR_TYPE_NAME.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 400 | TRIGGER | IMPORTERS.BUS_ID_EXPRD_DT.KEY-LISTVAL | LOV | Popup LOV | - | - | MAPPED | Same Hijri calendar as KEY-F4 |
| 401 | TRIGGER | IMPORTERS.BUS_ID_EXPRD_DT.KEY-F4 | DYNAMIC_ACTION | BUS_ID_EXPRD_DT KEY-F4 | 1110 | - | MAPPED | INTRFACE.Disp_date_con Hijri calendar -> Hijri date picker (decision needed) |
| 402 | TRIGGER | IMPORTERS.BUS_ID_EXPRD_DT.WHEN-VALIDATE-ITEM | VALIDATION | BUS_ID_EXPRD_DT VALIDATION + DA BUS_ID_EXPRD_DT WHEN-VALIDATE-ITEM | 1110 | IMPR1110.BUS_ID_EXPRD_DT_VALIDATION / IMPR1110.BUS_ID_EXPRD_DT_VALIDATE_ITEM | MAPPED | p_from_item = (:SYSTEM.TRIGGER_ITEM = :SYSTEM.CURSOR_ITEM) |
| 403 | TRIGGER | IMPORTERS.BUS_ID_EXPRD_DT.WHEN-NEW-ITEM-INSTANCE | DYNAMIC_ACTION | BUS_ID_EXPRD_DT WHEN-NEW-ITEM-INSTANCE | 1110 | - | MAPPED | EXEC_QUERY_NOW=1 -> re-query |
| 404 | TRIGGER | IMPORTERS.BUS_ID_TYPE_CD.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 405 | TRIGGER | IMPORTERS.BUS_ID_TYPE_CD.POST-CHANGE | VALIDATION | BUS_ID_TYPE_CD VALIDATION + DA BUS_ID_TYPE_CD WHEN-VALIDATE-ITEM | 1110 | IMPR1110.BUS_ID_TYPE_CD_VALIDATION / IMPR1110.BUS_ID_TYPE_CD_VALIDATE_ITEM | MAPPED | Swapped country-name assignment kept (SUGGESTION) |
| 406 | TRIGGER | IMPORTERS.BUTT.WHEN-BUTTON-PRESSED | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV button (GO_ITEM + LIST_VALUES) - Popup LOV has its own button |
| 407 | TRIGGER | IMPORTERS.BUS_ID_TYPE_NAME.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 408 | TRIGGER | IMPORTERS.COMM_RGSTRTN_TYPE.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 409 | TRIGGER | IMPORTERS.COMM_RGSTRTN_TYPE.WHEN-LIST-CHANGED | DYNAMIC_ACTION | COMM_RGSTRTN_TYPE WHEN-LIST-CHANGED | 1110 | IMPR1110.COMM_RGSTRTN_TYPE_LIST_CHANGED | MAPPED | Clears BUS_ID_BRNCH (server) + read-only / required rules |
| 410 | TRIGGER | IMPORTERS.CITY_CODE_OF_ID.KEY-LISTVAL | LOV | Popup LOV; returns CTRY_CD_OF_ID too | - | - | MAPPED | LOV form LOV_CITIES_IMP (CTRY 100 for type 3/bus 2, else CTRY_CD) -> Popup LOV; returns CTRY_CD_OF_ID too |
| 411 | TRIGGER | IMPORTERS.CITY_CODE_OF_ID.WHEN-VALIDATE-ITEM | VALIDATION | CITY_CODE_OF_ID VALIDATION + DA CITY_CODE_OF_ID WHEN-VALIDATE-ITEM | 1110 | IMPR1110.CITY_CODE_OF_ID_VALIDATION / IMPR1110.CITY_CODE_OF_ID_VALIDATE_ITEM | MAPPED | FK message is a warning (no failure) |
| 412 | TRIGGER | IMPORTERS.CITY_CODE_OF_ID.WHEN-NEW-ITEM-INSTANCE | - | - | - | - | DROPPED | only UI calls (BRNH_CITY_CD REQUIRED when COMM_RGSTRTN_TYPE = 2): BRNH_CITY_CD_IS_REQUIRED covers it (package 012) |
| 413 | TRIGGER | IMPORTERS.CITY_CODE_OF_ID2.WHEN-BUTTON-PRESSED | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV button (GO_ITEM + LIST_VALUES) - Popup LOV has its own button |
| 414 | TRIGGER | IMPORTERS.ID_CITY_NAME.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 415 | TRIGGER | IMPORTERS.BUS_ID.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 416 | TRIGGER | IMPORTERS.BUS_ID.POST-CHANGE | VALIDATION | BUS_ID VALIDATION + DA BUS_ID WHEN-VALIDATE-ITEM | 1110 | IMPR1110.BUS_ID_VALIDATION / IMPR1110.BUS_ID_WHEN_VALIDATE_ITEM | MAPPED | - |
| 417 | TRIGGER | IMPORTERS.BUS_ID.WHEN-NEW-ITEM-INSTANCE | DYNAMIC_ACTION | BUS_ID WHEN-NEW-ITEM-INSTANCE | 1110 | IMPR1110.BUS_ID_WHEN_NEW_ITEM_INSTANCE | MAPPED | Message 9-240 + GO_ITEM; city commercial code hint |
| 418 | TRIGGER | IMPORTERS.BUS_ID.WHEN-VALIDATE-ITEM | VALIDATION | BUS_ID VALIDATION + DA BUS_ID WHEN-VALIDATE-ITEM | 1110 | IMPR1110.BUS_ID_VALIDATION / IMPR1110.BUS_ID_WHEN_VALIDATE_ITEM | MAPPED | 2 alerts -> p_cr_answer / p_susp_answer; MCI service; read-only rules |
| 419 | TRIGGER | IMPORTERS.BRNH_CITY_CD.KEY-LISTVAL | LOV | Popup LOV; returns BRNH_CITY_CD/NAME | - | - | MAPPED | LOV form LOV_CITIES_IMP (CTRY_CD = :CTRY_CD) -> Popup LOV; returns BRNH_CITY_CD/NAME |
| 420 | TRIGGER | IMPORTERS.BRNH_CITY_CD.WHEN-NEW-ITEM-INSTANCE | - | - | - | - | DROPPED | only UI calls (REQUIRED / VALID of BRNH_CITY_CD, BUS_ID_BRNCH): required rules and validations cover them (package 012) |
| 421 | TRIGGER | IMPORTERS.BRNH_CITY_CD.WHEN-VALIDATE-ITEM | VALIDATION | BRNH_CITY_CD VALIDATION + DA BRNH_CITY_CD WHEN-VALIDATE-ITEM | 1110 | IMPR1110.BRNH_CITY_CD_VALIDATION / IMPR1110.BRNH_CITY_CD_VALIDATE_ITEM | MAPPED | - |
| 422 | TRIGGER | IMPORTERS.BRNH_CITY_CD_LOV.WHEN-BUTTON-PRESSED | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV button (GO_ITEM + LIST_VALUES) - Popup LOV has its own button |
| 423 | TRIGGER | IMPORTERS.BRNH_CITY_NAME.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 424 | TRIGGER | IMPORTERS.BUS_ID_BRNCH.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 425 | TRIGGER | IMPORTERS.BUS_ID_BRNCH.POST-CHANGE | VALIDATION | BUS_ID_BRNCH VALIDATION + DA BUS_ID_BRNCH WHEN-VALIDATE-ITEM | 1110 | IMPR1110.BUS_ID_BRNCH_VALIDATION / IMPR1110.BUS_ID_BRNCH_VALIDATE_ITEM | MAPPED | - |
| 426 | TRIGGER | IMPORTERS.BUS_ID_BRNCH.WHEN-NEW-ITEM-INSTANCE | DYNAMIC_ACTION | BUS_ID_BRNCH WHEN-NEW-ITEM-INSTANCE | 1110 | IMPR1110.BUS_ID_BRNCH_NEW_ITEM_INSTANCE | MAPPED | REQUIRED flag + hint message |
| 427 | TRIGGER | IMPORTERS.BUS_ID_BRNCH.WHEN-VALIDATE-ITEM | VALIDATION | BUS_ID_BRNCH VALIDATION + DA BUS_ID_BRNCH WHEN-VALIDATE-ITEM | 1110 | IMPR1110.BUS_ID_BRNCH_VALIDATION / IMPR1110.BUS_ID_BRNCH_VALIDATE_ITEM | MAPPED | Alert 9-120 -> p_cr_answer |
| 428 | TRIGGER | IMPORTERS.CTRY_CD.KEY-LISTVAL | LOV | Popup LOV with conditional query | - | - | MAPPED | LOV_COUNTRIES_GULF when type 4 / bus id type 16, else LOV_COUNTRIES -> Popup LOV with conditional query |
| 429 | TRIGGER | IMPORTERS.CTRY_CD.WHEN-VALIDATE-ITEM | VALIDATION | CTRY_CD VALIDATION + DA CTRY_CD WHEN-VALIDATE-ITEM | 1110 | IMPR1110.CTRY_CD_VALIDATION / IMPR1110.CTRY_CD_WHEN_VALIDATE_ITEM | MAPPED | Includes CGFK CTRY check |
| 430 | TRIGGER | IMPORTERS.CTRY_CD2.WHEN-BUTTON-PRESSED | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV button (GO_ITEM + LIST_VALUES) - Popup LOV has its own button |
| 431 | TRIGGER | IMPORTERS.CRTY_ARBC_NAME.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 432 | TRIGGER | IMPORTERS.IMPR_EXPR_TYPE.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 433 | TRIGGER | IMPORTERS.IMPR_EXPR_TYPE.POST-CHANGE | VALIDATION | IMPR_EXPR_TYPE VALIDATION + DA IMPR_EXPR_TYPE WHEN-VALIDATE-ITEM | 1110 | IMPR1110.IMPR_EXPR_TYPE_VALIDATION / IMPR1110.IMPR_EXPR_TYPE_VALIDATE_ITEM | MAPPED | - |
| 434 | TRIGGER | IMPORTERS.CTRY_CTRY_STATUS.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 435 | TRIGGER | IMPORTERS.ID_MINS_COMM_CD.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 436 | TRIGGER | IMPORTERS.ARBC_IMPR_NAME.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 437 | TRIGGER | IMPORTERS.ARBC_IMPR_NAME.KEY-NEXT-ITEM | DYNAMIC_ACTION | ARBC_IMPR_NAME KEY-NEXT-ITEM | 1110 | IMPR1110.ARBC_IMPR_NAME_KEY_NEXT_ITEM | MAPPED | Net effect: focus ENG_IMPR_NAME (dummy values are reset) |
| 438 | TRIGGER | IMPORTERS.ARBC_IMPR_NAME.WHEN-VALIDATE-ITEM | VALIDATION | ARBC_IMPR_NAME VALIDATION + DA ARBC_IMPR_NAME WHEN-VALIDATE-ITEM | 1110 | IMPR1110.ARBC_IMPR_NAME_VALIDATION / IMPR1110.ARBC_IMPR_NAME_VALIDATE_ITEM | MAPPED | - |
| 439 | TRIGGER | IMPORTERS.IMPD_STMT_NBR.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 440 | TRIGGER | IMPORTERS.IMPR_DATA_SRCE.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 441 | TRIGGER | IMPORTERS.ENG_IMPR_NAME.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 442 | TRIGGER | IMPORTERS.ENG_IMPR_NAME.WHEN-VALIDATE-ITEM | VALIDATION | ENG_IMPR_NAME VALIDATION + DA ENG_IMPR_NAME WHEN-VALIDATE-ITEM | 1110 | IMPR1110.ENG_IMPR_NAME_VALIDATION / IMPR1110.ENG_IMPR_NAME_VALIDATE_ITEM | MAPPED | - |
| 443 | TRIGGER | IMPORTERS.IMPR_CNTCT_NAME.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 444 | TRIGGER | IMPORTERS.IMPR_ADDRESS.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 445 | TRIGGER | IMPORTERS.BUS_ID_ISSUE_DT.WHEN-VALIDATE-ITEM | VALIDATION | BUS_ID_ISSUE_DT VALIDATION + DA BUS_ID_ISSUE_DT WHEN-VALIDATE-ITEM | 1110 | IMPR1110.BUS_ID_ISSUE_DT_VALIDATION / IMPR1110.BUS_ID_ISSUE_DT_VALIDATE_ITEM | MAPPED | - |
| 446 | TRIGGER | IMPORTERS.IMPR_NBR_PARENT.KEY-LISTVAL | LOV | Popup LOV; then focus CITY_CODE | - | - | MAPPED | LOV form LOV_IMPR (PORT_CD = current port) -> Popup LOV; then focus CITY_CODE |
| 447 | TRIGGER | IMPORTERS.IMPR_NBR_PARENT.WHEN-VALIDATE-ITEM | VALIDATION | IMPR_NBR_PARENT VALIDATION + DA IMPR_NBR_PARENT WHEN-VALIDATE-ITEM | 1110 | IMPR1110.IMPR_NBR_PARENT_VALIDATION / IMPR1110.IMPR_NBR_PARENT_VALIDATE_ITEM | MAPPED | 9-160 is a message, not a failure |
| 448 | TRIGGER | IMPORTERS.IMPR_NBR_PARENT2.WHEN-BUTTON-PRESSED | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV button (GO_ITEM + LIST_VALUES) - Popup LOV has its own button |
| 449 | TRIGGER | IMPORTERS.IMPR_NAME_PARENT.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 450 | TRIGGER | IMPORTERS.WASL_CITY_NAME.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 451 | TRIGGER | IMPORTERS.ADD_CTRY_CD.KEY-LISTVAL | LOV | Popup LOV | - | - | MAPPED | LOV form LOV_COUNTRIES (STATUS=1) -> Popup LOV |
| 452 | TRIGGER | IMPORTERS.ADD_CTRY_CD.WHEN-VALIDATE-ITEM | VALIDATION | ADD_CTRY_CD VALIDATION + DA ADD_CTRY_CD WHEN-VALIDATE-ITEM | 1110 | IMPR1110.ADD_CTRY_CD_VALIDATION / IMPR1110.ADD_CTRY_CD_WHEN_VALIDATE_ITEM | MAPPED | - |
| 453 | TRIGGER | IMPORTERS.ADD_CTRY_CD2.WHEN-BUTTON-PRESSED | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV button (GO_ITEM + LIST_VALUES) - Popup LOV has its own button |
| 454 | TRIGGER | IMPORTERS.ADD_CRTY_ARBC_NAME.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 455 | TRIGGER | IMPORTERS.CITY_CODE.KEY-LISTVAL | LOV | Popup LOV; also returns ADD_CTRY_CD | - | - | MAPPED | LOV form LOV_CITIES (CTRY_CD = ADD_CTRY_CD) -> Popup LOV; also returns ADD_CTRY_CD |
| 456 | TRIGGER | IMPORTERS.CITY_CODE.WHEN-VALIDATE-ITEM | VALIDATION | CITY_CODE VALIDATION + DA CITY_CODE WHEN-VALIDATE-ITEM | 1110 | IMPR1110.CITY_CODE_VALIDATION / IMPR1110.CITY_CODE_WHEN_VALIDATE_ITEM | MAPPED | - |
| 457 | TRIGGER | IMPORTERS.CITY_CODE2.WHEN-BUTTON-PRESSED | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV button (GO_ITEM + LIST_VALUES) - Popup LOV has its own button |
| 458 | TRIGGER | IMPORTERS.CITY_NAME.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 459 | TRIGGER | IMPORTERS.IMPR_POB_NBR.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 460 | TRIGGER | IMPORTERS.IMPR_ZIP_CD.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 461 | TRIGGER | IMPORTERS.IMPR_TEL_NBR.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 462 | TRIGGER | IMPORTERS.IMPR_TEL_NBR.WHEN-VALIDATE-ITEM | VALIDATION | IMPR_TEL_NBR VALIDATION + DA IMPR_TEL_NBR WHEN-VALIDATE-ITEM | 1110 | IMPR1110.IMPR_TEL_NBR_VALIDATION / IMPR1110.IMPR_TEL_NBR_VALIDATE_ITEM | MAPPED | - |
| 463 | TRIGGER | IMPORTERS.IMPR_FAX_NBR.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 464 | TRIGGER | IMPORTERS.IMPR_TELEX_NBR.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 465 | TRIGGER | IMPORTERS.B_EMAIL.WHEN-VALIDATE-ITEM | VALIDATION | B_EMAIL VALIDATION + DA B_EMAIL WHEN-VALIDATE-ITEM | 1110 | IMPR1110.B_EMAIL_VALIDATION / IMPR1110.B_EMAIL_WHEN_VALIDATE_ITEM | MAPPED | - |
| 466 | TRIGGER | IMPORTERS.B_EMAIL.POST-CHANGE | VALIDATION | B_EMAIL VALIDATION + DA B_EMAIL WHEN-VALIDATE-ITEM | 1110 | IMPR1110.B_EMAIL_VALIDATION / IMPR1110.B_EMAIL_WHEN_VALIDATE_ITEM | MAPPED | Moves the row to the current port |
| 467 | TRIGGER | IMPORTERS.EMAIL.WHEN-VALIDATE-ITEM | VALIDATION | EMAIL VALIDATION + DA EMAIL WHEN-VALIDATE-ITEM | 1110 | IMPR1110.EMAIL_VALIDATION / IMPR1110.EMAIL_WHEN_VALIDATE_ITEM | MAPPED | EMAIL is hidden |
| 468 | TRIGGER | IMPORTERS.B_MOBILE_NO.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 469 | TRIGGER | IMPORTERS.B_MOBILE_NO.POST-CHANGE | VALIDATION | B_MOBILE_NO VALIDATION + DA B_MOBILE_NO WHEN-VALIDATE-ITEM | 1110 | IMPR1110.B_MOBILE_NO_VALIDATION / IMPR1110.B_MOBILE_NO_WHEN_VALIDATE_ITEM | MAPPED | Moves the row to the current port |
| 470 | TRIGGER | IMPORTERS.B_MOBILE_NO.WHEN-VALIDATE-ITEM | VALIDATION | B_MOBILE_NO VALIDATION + DA B_MOBILE_NO WHEN-VALIDATE-ITEM | 1110 | IMPR1110.B_MOBILE_NO_VALIDATION / IMPR1110.B_MOBILE_NO_WHEN_VALIDATE_ITEM | MAPPED | - |
| 471 | TRIGGER | IMPORTERS.MOBILE_NO.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 472 | TRIGGER | IMPORTERS.BANK_IBAN.WHEN-NEW-ITEM-INSTANCE | DYNAMIC_ACTION | BANK_IBAN WHEN-NEW-ITEM-INSTANCE | 1110 | IMPR1110.BANK_IBAN_NEW_ITEM_INSTANCE | MAPPED | Default "SA" on focus |
| 473 | TRIGGER | IMPORTERS.BANK_IBAN.WHEN-VALIDATE-ITEM | VALIDATION | BANK_IBAN VALIDATION + DA BANK_IBAN WHEN-VALIDATE-ITEM | 1110 | IMPR1110.BANK_IBAN_VALIDATION / IMPR1110.BANK_IBAN_WHEN_VALIDATE_ITEM | MAPPED | - |
| 474 | TRIGGER | IMPORTERS.B_ID_NBR.POST-CHANGE | VALIDATION | B_ID_NBR VALIDATION + DA B_ID_NBR WHEN-VALIDATE-ITEM | 1110 | IMPR1110.B_ID_NBR_VALIDATION / IMPR1110.B_ID_NBR_WHEN_VALIDATE_ITEM | MAPPED | Moves the row to the current port |
| 475 | TRIGGER | IMPORTERS.B_ID_NBR.WHEN-VALIDATE-ITEM | VALIDATION | B_ID_NBR VALIDATION + DA B_ID_NBR WHEN-VALIDATE-ITEM | 1110 | IMPR1110.B_ID_NBR_VALIDATION / IMPR1110.B_ID_NBR_WHEN_VALIDATE_ITEM | MAPPED | - |
| 476 | TRIGGER | IMPORTERS.EXPRESS_POST.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 477 | TRIGGER | IMPORTERS.IMPR_ID_TYPE.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 478 | TRIGGER | IMPORTERS.CTRY_CD_OF_ID.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 479 | TRIGGER | IMPORTERS.CTRY_CD_OF_ID.WHEN-VALIDATE-ITEM | VALIDATION | CTRY_CD_OF_ID VALIDATION + DA CTRY_CD_OF_ID WHEN-VALIDATE-ITEM | 1110 | IMPR1110.CTRY_CD_OF_ID_VALIDATION / IMPR1110.CTRY_CD_OF_ID_VALIDATE_ITEM | MAPPED | CTRY_CD_OF_ID is hidden |
| 480 | TRIGGER | IMPORTERS.EXPD_STMT_NBR.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 481 | TRIGGER | IMPORTERS.WVR_ENTRY_NBR.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 482 | TRIGGER | IMPORTERS.ACTIVITY.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 483 | TRIGGER | IMPORTERS.CUSTOMS_ENTERED.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 484 | TRIGGER | IMPORTERS.CUSTOMS_ENTERED2.WHEN-BUTTON-PRESSED | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV button (GO_ITEM + LIST_VALUES) - Popup LOV has its own button |
| 485 | TRIGGER | IMPORTERS.CREATION_FLAG.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 486 | TRIGGER | IMPORTERS.CREATION_FLAG2.WHEN-BUTTON-PRESSED | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV button (GO_ITEM + LIST_VALUES) - Popup LOV has its own button |
| 487 | PROGRAM_UNIT | CHECK_TIMEOUT | - | - | - | - | DROPPED | not called; NIB library |
| 488 | PROGRAM_UNIT | MOUSE_CLICK | - | - | - | - | DROPPED | not called |
| 489 | PROGRAM_UNIT | TOGGEL_WND | - | - | - | - | DROPPED | not called; window API |
| 490 | PROGRAM_UNIT | PRINT_REPORT | - | - | - | - | DROPPED | not called; NIB library |
| 491 | PROGRAM_UNIT | EXECUTE_FUNCTION | PLSQL | - | - | - | MAPPED | TMPLT side-menu dispatcher -> region FUNCS calls one DA per function code -> IMPR1110.EXEC_FUNS |
| 492 | PROGRAM_UNIT | TERMINATE_FUN | - | - | - | - | DROPPED | not called; NIB library |
| 493 | PROGRAM_UNIT | CHECK_EDI_MSG_LOV | - | - | - | - | DROPPED | not called (EDI messages) |
| 494 | PROGRAM_UNIT | CHECK_EDI_MSG_TIMER | - | - | - | - | DROPPED | not called |
| 495 | PROGRAM_UNIT | CHECK_EDI_ROLE_ID | - | - | - | - | DROPPED | not called |
| 496 | PROGRAM_UNIT | EDI_MSG_LOV | - | - | - | - | DROPPED | not called |
| 497 | PROGRAM_UNIT | FOR_EDI_MSG | - | - | - | - | DROPPED | not called |
| 498 | PROGRAM_UNIT | RETURN_MSG | - | - | - | - | DROPPED | not called; NIB timers |
| 499 | PROGRAM_UNIT | TURN_MSG | - | - | - | - | DROPPED | not called; NIB timers |
| 500 | PROGRAM_UNIT | WHEN_TIMER_EXPIRED_MSG | - | - | - | - | DROPPED | not called |
| 501 | PROGRAM_UNIT | CG$WHEN_NEW_FORM_INSTANCE | PLSQL | - | - | - | MAPPED | only calls CGDV$POPULATE_DYNAMIC_LISTS -> shared LOVs |
| 502 | PROGRAM_UNIT | CGDV$POPULATE_DYNAMIC_LISTS | PLSQL | - | - | - | MAPPED | list items from CG_REF_CODES -> shared LOVs (domains COMM_RGSTRTN_TYPE, ALLOWED EXPORT) |
| 503 | PROGRAM_UNIT | CGFK$QRY_IMPORTERS_IMP_SDP_FK | - | - | - | - | DROPPED | not called |
| 504 | PROGRAM_UNIT | CGFK$CHK_IMPORTERS_IMP_SDP_FK | PLSQL | - | - | - | MAPPED | - |
| 505 | PROGRAM_UNIT | CG$IMPR1110_PROD_CENTRL_GLOBAL | - | - | - | - | DROPPED | holds DEFAULT_WHERE between PRE/POST-QUERY - not needed |
| 506 | PROGRAM_UNIT | CGFK$CHK_IMPORTERS_IMP_MB_FK | - | - | - | - | DROPPED | not called |
| 507 | PROGRAM_UNIT | CGFK$QRY_IMPORTERS_IMP_ITIDT_F | PLSQL | - | - | - | MAPPED | - |
| 508 | PROGRAM_UNIT | CGFK$CHK_IMPORTERS_IMP_ITIDT_F | PLSQL | - | - | - | MAPPED | - |
| 509 | PROGRAM_UNIT | CGFK$QRY_IMPORTERS_IMP_CTRY_FK | PLSQL | - | - | - | MAPPED | - |
| 510 | PROGRAM_UNIT | CGFK$CHK_IMPORTERS_IMP_CTRY_FK | PLSQL | - | - | - | MAPPED | - |
| 511 | PROGRAM_UNIT | CGFK$QRY_IMPORTERS_IMP_BUS_ID_ | PLSQL | - | - | - | MAPPED | - |
| 512 | PROGRAM_UNIT | CGFK$CHK_IMPORTERS_IMP_BUS_ID_ | PLSQL | - | - | - | MAPPED | - |
| 513 | PROGRAM_UNIT | CGSF$CLRLU_IMPORTERS_IMP_BUS_I | PLSQL | - | - | - | MAPPED | - |
| 514 | PROGRAM_UNIT | CGFK$QRY_IMPORTERS_IMP_ADD_CIT | PLSQL | - | - | - | MAPPED | - |
| 515 | PROGRAM_UNIT | CGFK$CHK_IMPORTERS_IMP_ADD_CIT | PLSQL | - | - | - | MAPPED | - |
| 516 | PROGRAM_UNIT | CGTE$CHECK_CONSTRAINT_VIO | PLSQL | - | - | - | MAPPED | - |
| 517 | PROGRAM_UNIT | UPDATE_IMPORTER | PLSQL | - | - | IMPR1110.UPDATE_IMPORTER / UPDATE_IMPORTER_CONFIRM_TEXT | MAPPED | - |
| 518 | PROGRAM_UNIT | UPDATE_BASIC_IMPORTER | PLSQL | - | - | IMPR1110 (private UPDATE_BASIC_IMPORTER) | MAPPED | - |
| 519 | PROGRAM_UNIT | RETURN_IMPR_ID | PLSQL | - | - | IMPR1110 (private RETURN_IMPR_ID) | MAPPED | - |
| 520 | PROGRAM_UNIT | LOV_UPDATE_MOBLIE | PLSQL | - | - | IMPR1110.CENTRAL_MOBILE / LOV_UPDATE_MOBLIE | MAPPED | - |
| 521 | PROGRAM_UNIT | IS_DIGIT | PLSQL | - | - | IMPR1110 (private IS_DIGIT) | MAPPED | - |
| 522 | PROGRAM_UNIT | INSERT_AUDIT_RECORD | PLSQL | - | - | IMPR1110 (private INSERT_AUDIT_RECORD) | MAPPED | - |
| 523 | PROGRAM_UNIT | GET_MAIN_CR_DATA | PLSQL | - | - | IMPR1110 (private GET_MAIN_CR_DATA) | MAPPED | - |
| 524 | PROGRAM_UNIT | GET_CR_DATA | PLSQL | - | - | IMPR1110 (private GET_CR_DATA) | MAPPED | - |
| 525 | PROGRAM_UNIT | GET_BRANCH_CR_DATA | PLSQL | - | - | IMPR1110 (private GET_BRANCH_CR_DATA) | MAPPED | - |
| 526 | PROGRAM_UNIT | EXEC_FUNS | PLSQL | - | - | IMPR1110.EXEC_FUNS | MAPPED | - |
| 527 | PROGRAM_UNIT | DEV_VERSIONS | - | - | - | - | DROPPED | change log only (NULL) |
| 528 | PROGRAM_UNIT | CREATE_BRKR_IMPR_AUTH | PLSQL | - | - | IMPR1110 (private CREATE_BRKR_IMPR_AUTH) | MAPPED | - |
| 529 | PROGRAM_UNIT | CHK_PERSONAL | PLSQL | - | - | IMPR1110 (private CHK_PERSONAL) | MAPPED | - |
| 530 | PROGRAM_UNIT | CHK_IMPR_DUPL | PLSQL | - | - | IMPR1110 (private CHK_IMPR_DUPL) | MAPPED | - |
| 531 | PROGRAM_UNIT | CHK_DUPL_IMP_BRKR | PLSQL | - | - | IMPR1110 (private CHK_DUPL_IMP_BRKR) | MAPPED | - |
| 532 | PROGRAM_UNIT | CHECK_IDNO | PLSQL | - | - | IMPR1110 (private CHECK_IDNO) | MAPPED | - |
| 533 | PROGRAM_UNIT | CHECK_BUS_ID | PLSQL | - | - | IMPR1110 (private CHECK_BUS_ID) | MAPPED | - |
| 534 | PROGRAM_UNIT | CALL_LOV_COUNTRIES | LOV | Popup LOV | - | - | MAPPED | LOV form LOV_COUNTRIES -> Popup LOV |
| 535 | PROGRAM_UNIT | CALL_LOV_COUN_GULF | LOV | Popup LOV | - | - | MAPPED | LOV form LOV_COUNTRIES_GULF -> Popup LOV |
| 536 | PROGRAM_UNIT | BROKER_INT | PLSQL | - | - | IMPR1110 (private BROKER_INT) | MAPPED | - |
| 537 | PROGRAM_UNIT | ADJ_FUNS | PLSQL | - | - | IMPR1110.ADJ_FUNS | MAPPED | - |
| 538 | PROGRAM_UNIT | VIEW_SAME_BUSID | - | - | - | - | DROPPED | not called (only setter of :GLOBAL.CHK_DUP_BUSID = 1) |
| 539 | PROGRAM_UNIT | CHK_BUS_ID_BRNCH | PLSQL | - | - | IMPR1110 (private CHK_BUS_ID_BRNCH) | MAPPED | - |
| 540 | LOV | CGDV$IMPORTERS_CREATION_FLAG | - | - | - | - | DROPPED | item is display-only / hidden - no LOV needed |
| 541 | LOV | CGFK$IMPORTERS_ADD_CTRY_CD | LOV | LOV_COUNTRIES | - | - | MAPPED | Forms KEY-LISTVAL calls an LOV form instead; APEX LOV built from that LOV form |
| 542 | LOV | CGFK$IMPORTERS_CITY_CODE_OF_ID | LOV | LOV_CITIES_IMP_ID | - | - | MAPPED | Forms KEY-LISTVAL calls an LOV form instead; APEX LOV built from that LOV form |
| 543 | LOV | CGFK$IMPORTERS_CTRY_CD | LOV | inline LOV of P1110_CTRY_CD | - | - | MAPPED | Forms KEY-LISTVAL calls an LOV form instead; APEX LOV built from that LOV form |
| 544 | LOV | CGFK$IMPORTERS_HQ_IMPR_NBR | - | - | - | - | DROPPED | item is display-only / hidden - no LOV needed |
| 545 | LOV | CGFK$IMPORTERS_IMPR_TYPE_CD | LOV | LOV_IMPR_TYPE + LOV_IMPR_TYPE_BUS_ID | - | - | MAPPED | Forms KEY-LISTVAL calls an LOV form instead; APEX LOV built from that LOV form |
| 546 | LOV | CGFK$IMPORTERS_PORT_CD | LOV | LOV_SD_PORTS | - | - | MAPPED | Forms KEY-LISTVAL calls an LOV form instead; APEX LOV built from that LOV form |
| 547 | LOV | CGDV$IMPORTERS_CUSTOMS_ENTERED | - | - | - | - | DROPPED | item is display-only / hidden - no LOV needed |
| 548 | RECORD_GROUP | CGDV$CREATION_FLAG | - | - | - | - | DROPPED | record group of the LOV with the same name |
| 549 | RECORD_GROUP | CGFK$IMPORTERS_ADD_CTRY_CD | LOV | LOV_COUNTRIES | - | - | MAPPED | record group of the LOV with the same name |
| 550 | RECORD_GROUP | CGFK$IMPORTERS_CITY_CODE_OF_ID | LOV | LOV_CITIES_IMP_ID | - | - | MAPPED | record group of the LOV with the same name |
| 551 | RECORD_GROUP | CGFK$IMPORTERS_CTRY_CD | LOV | inline LOV of P1110_CTRY_CD | - | - | MAPPED | record group of the LOV with the same name |
| 552 | RECORD_GROUP | CGFK$IMPORTERS_HQ_IMPR_NBR | - | - | - | - | DROPPED | record group of the LOV with the same name |
| 553 | RECORD_GROUP | CGFK$IMPORTERS_IMPR_TYPE_CD | LOV | LOV_IMPR_TYPE + LOV_IMPR_TYPE_BUS_ID | - | - | MAPPED | record group of the LOV with the same name |
| 554 | RECORD_GROUP | CGFK$IMPORTERS_PORT_CD | LOV | LOV_SD_PORTS | - | - | MAPPED | record group of the LOV with the same name |
| 555 | RECORD_GROUP | CGDV$IMPORTERS_CUSTOMS_ENTERED | - | - | - | - | DROPPED | record group of the LOV with the same name |
| 556 | RECORD_GROUP | CGDV$DLRG | LOV | LOV_COMM_RGSTRTN_TYPE / LOV_ALLOWED_EXPORT | - | - | MAPPED | runtime group of CGDV$POPULATE_DYNAMIC_LISTS |
| 557 | CALLED_FORM | LOV_SD_PORTS | LOV | LOV_SD_PORTS | - | - | MAPPED | LOV form (forms/COMMON/lov_forms) |
| 558 | CALLED_FORM | LOV_IMPR_TYPE | LOV | LOV_IMPR_TYPE + LOV_IMPR_TYPE_BUS_ID | - | - | MAPPED | LOV form (forms/COMMON/lov_forms) |
| 559 | CALLED_FORM | LOV_CITIES_IMP | LOV | LOV_CITIES_IMP_ID / LOV_CITIES_IMP_BRNH | - | - | MAPPED | LOV form (forms/COMMON/lov_forms) |
| 560 | CALLED_FORM | LOV_CITIES | LOV | LOV_CITIES | - | - | MAPPED | LOV form (forms/COMMON/lov_forms) |
| 561 | CALLED_FORM | LOV_COUNTRIES | LOV | LOV_COUNTRIES | - | - | MAPPED | LOV form (forms/COMMON/lov_forms) |
| 562 | CALLED_FORM | LOV_COUNTRIES_GULF | LOV | inline LOV of P1110_CTRY_CD | - | - | MAPPED | LOV form (forms/COMMON/lov_forms) |
| 563 | CALLED_FORM | LOV_IMPR | LOV | LOV_IMPR | - | - | MAPPED | LOV form (forms/COMMON/lov_forms) |
| 564 | CALLED_FORM | LOV_UPDATE_IMPR_MOBILE | PAGE | 111002 IMPR1110_MOBILE (Modal Dialog) | 111002 | IMPR1110.CENTRAL_MOBILE | MAPPED | dialog of function IMPR1110_MOB |
| 565 | CALLED_FORM | SUPPORT_ENTRY | PAGE | SUPPORT_ENTRY page (form converted on its own, SC subsystem - decision §15 #12) | - | - | TODO | TODO: page number and URL item P1110_SUPPORT_URL; on close it must set G_LETTER_NBR / G_SUPP_TITLE_CD / G_LETTER_DT / G_PORT_CD |
| 566 | CALLED_FORM | IMPR1115 | PAGE | link to the IMPR1115 page | - | - | TODO | function IMPR1115_SCR - when IMPR1115 is converted |
| 567 | CALLED_FORM | V_CALLED_FORM (TMPLT menu) | PAGE | - | - | - | TODO | screens of SC_SYSTEM_OBJECTS called by EXECUTE_FUNCTION -> navigation menu |
| 568 | ALERT | USR_CONFIRM_B | - | - | - | - | DROPPED | OLB alert used only through STR.DispAlert; texts are inline in the code (MISSING SOURCE CIC_OLB) |
| 569 | ALERT | USR_CONFIRM | - | - | - | - | DROPPED | OLB alert used only through STR.DispAlert; texts are inline in the code (MISSING SOURCE CIC_OLB) |
| 570 | ALERT | USR_WARNING_C | - | - | - | - | DROPPED | OLB alert used only through STR.DispAlert; texts are inline in the code (MISSING SOURCE CIC_OLB) |
| 571 | ALERT | USR_WARNING_B | - | - | - | - | DROPPED | OLB alert used only through STR.DispAlert; texts are inline in the code (MISSING SOURCE CIC_OLB) |
| 572 | ALERT | CFG_WARNING_A | - | - | - | - | DROPPED | OLB alert used only through STR.DispAlert; texts are inline in the code (MISSING SOURCE CIC_OLB) |
| 573 | ALERT | CFG_INFORMATION | - | - | - | - | DROPPED | OLB alert used only through STR.DispAlert; texts are inline in the code (MISSING SOURCE CIC_OLB) |
| 574 | ALERT | CFG_ERROR | - | - | - | - | DROPPED | OLB alert used only through STR.DispAlert; texts are inline in the code (MISSING SOURCE CIC_OLB) |
| 575 | ALERT | CFG_SYSTEM_ERROR | - | - | - | - | DROPPED | OLB alert used only through STR.DispAlert; texts are inline in the code (MISSING SOURCE CIC_OLB) |
| 576 | ALERT | CFG_ASK_COMMIT | - | - | - | - | DROPPED | OLB alert used only through STR.DispAlert; texts are inline in the code (MISSING SOURCE CIC_OLB) |
| 577 | CANVAS | LSIDE | - | - | - | - | DROPPED | OLB canvas LSIDE |
| 578 | CANVAS | EDI_MSG | - | - | - | - | DROPPED | OLB canvas EDI_MSG |
| 579 | CANVAS | TITLE | - | - | - | - | DROPPED | OLB canvas TITLE |
| 580 | CANVAS | TOOLBAR | - | - | - | - | DROPPED | OLB canvas TOOLBAR |
| 581 | CANVAS | CG$PAGE_1 | PAGE | 1110 IMPR1110 | 1110 | - | MAPPED | main content canvas |
| 582 | WINDOW | CGSO$WINDOW_1 | PAGE | 1110 IMPR1110 | 1110 | - | MAPPED | console window |
| 583 | PARAMETER | P_SHPG_AGNT_NBR | - | - | - | - | DROPPED | used only by dropped code (title, menu, help, reports) |
| 584 | PARAMETER | P_CTRL_LAST_EXEC_CD | - | - | - | - | DROPPED | used only by dropped code (title, menu, help, reports) |
| 585 | PARAMETER | P_BANK_CD | - | - | - | - | DROPPED | used only by dropped code (title, menu, help, reports) |
| 586 | PARAMETER | P_BANK_BRNCH_CD | - | - | - | - | DROPPED | used only by dropped code (title, menu, help, reports) |
| 587 | PARAMETER | P_BRKR_PORT_CD | APP_ITEM | P_BRKR_PORT_CD | - | - | MAPPED | session parameter of the menu; new P_ item (f345 style), not filled by f345 After Auth yet |
| 588 | PARAMETER | P_LIC_TYPE | APP_ITEM | P_LIC_TYPE | - | - | MAPPED | session parameter of the menu; new P_ item (f345 style), not filled by f345 After Auth yet |
| 589 | PARAMETER | P_BRKR_NBR | APP_ITEM | P_BRKR_NBR | - | - | MAPPED | session parameter of the menu; f345 item |
| 590 | PARAMETER | P_CLASS_CD | APP_ITEM | P_CLASS_CD | - | - | MAPPED | session parameter of the menu; f345 item |
| 591 | PARAMETER | P_JOB_ID | - | - | - | - | DROPPED | used only by dropped code (title, menu, help, reports) |
| 592 | PARAMETER | P_CURRENT_ITEM | - | - | - | - | DROPPED | used only by dropped code (title, menu, help, reports) |
| 593 | PARAMETER | P_GROUP_CD | - | - | - | - | DROPPED | used only by dropped code (title, menu, help, reports) |
| 594 | PARAMETER | P_USER_TYPE | APP_ITEM | V_USR_TYPE | - | - | MAPPED | session parameter of the menu; f345 item |
| 595 | PARAMETER | P_PORT_TYPE | APP_ITEM | P_PORT_TYPE | - | - | MAPPED | session parameter of the menu; f345 item |
| 596 | PARAMETER | P_CURR_PORT_CD | APP_ITEM | P_CURR_PORT_CD | - | - | MAPPED | session parameter of the menu; f345 item |
| 597 | PARAMETER | P_MODULE_ID | - | - | - | - | DROPPED | used only by dropped code (title, menu, help, reports) |
| 598 | PARAMETER | P_MODULE_NAME | - | - | - | - | DROPPED | used only by dropped code (title, menu, help, reports) |
| 599 | PARAMETER | P_APPLICATION_NAME | - | - | - | - | DROPPED | used only by dropped code (title, menu, help, reports) |
| 600 | PARAMETER | P_USER_ID | APP_ITEM | SSO_APP_USER | - | - | MAPPED | session parameter of the menu; f345 item |
| 601 | PARAMETER | P_WS_ID | APP_ITEM | P_GLOBAL_V_WS_ID | - | - | MAPPED | session parameter of the menu; f345 item |
| 602 | PARAMETER | P_USER_NAME | - | - | - | - | DROPPED | used only by dropped code (title, menu, help, reports) |
| 603 | PARAMETER | CG$STARTUP_MODE | - | - | - | - | DROPPED | used only by dropped code (title, menu, help, reports) |
| 604 | PARAMETER | LETTER_NBR | ITEM | P1110_P_LETTER_NBR | 1110 | - | MAPPED | page parameter |
| 605 | PARAMETER | CODE | ITEM | P1110_P_CODE | 1110 | - | MAPPED | page parameter |
| 606 | PARAMETER | PRSNL_IMPR | ITEM | P1110_P_PRSNL_IMPR | 1110 | - | MAPPED | page parameter |
| 607 | GLOBAL | FLAGUPDATE | APP_ITEM | G_FLAGUPDATE | - | - | MAPPED | FORMS_APX.get/set_global (f345: G_<name>) |
| 608 | GLOBAL | EXEC_QUERY_NOW | APP_ITEM | G_EXEC_QUERY_NOW | - | - | MAPPED | FORMS_APX.get/set_global (f345: G_<name>) |
| 609 | GLOBAL | PORT_CD | APP_ITEM | G_PORT_CD | - | - | MAPPED | FORMS_APX.get/set_global (f345: G_<name>) |
| 610 | GLOBAL | IMPR_NBR | APP_ITEM | G_IMPR_NBR | - | - | MAPPED | FORMS_APX.get/set_global (f345: G_<name>) |
| 611 | GLOBAL | VALID | APP_ITEM | G_VALID | - | - | MAPPED | FORMS_APX.get/set_global (f345: G_<name>) |
| 612 | GLOBAL | FUNS_IMP | APP_ITEM | G_FUNS_IMP | - | - | MAPPED | FORMS_APX.get/set_global (f345: G_<name>) |
| 613 | GLOBAL | FUNS_BUSID | APP_ITEM | G_FUNS_BUSID | - | - | MAPPED | FORMS_APX.get/set_global (f345: G_<name>) |
| 614 | GLOBAL | CHK_IMP_TYP | APP_ITEM | G_CHK_IMP_TYP | - | - | MAPPED | FORMS_APX.get/set_global (f345: G_<name>) |
| 615 | GLOBAL | CHK_DUP_BUSID | APP_ITEM | G_CHK_DUP_BUSID | - | - | MAPPED | FORMS_APX.get/set_global (f345: G_<name>) |
| 616 | GLOBAL | OLD_IMPR_TYPE_CD | APP_ITEM | G_OLD_IMPR_TYPE_CD | - | - | MAPPED | FORMS_APX.get/set_global (f345: G_<name>) |
| 617 | GLOBAL | OLD_PORT_CD | APP_ITEM | G_OLD_PORT_CD | - | - | MAPPED | FORMS_APX.get/set_global (f345: G_<name>) |
| 618 | GLOBAL | ALLOW_MCI | APP_ITEM | G_ALLOW_MCI | - | - | MAPPED | FORMS_APX.get/set_global (f345: G_<name>) |
| 619 | GLOBAL | ALLOW_MOI | APP_ITEM | G_ALLOW_MOI | - | - | MAPPED | FORMS_APX.get/set_global (f345: G_<name>) |
| 620 | GLOBAL | SET | APP_ITEM | SET_GLOBAL | - | - | MAPPED | FORMS_APX.get/set_global (f345: G_<name>) |
| 621 | GLOBAL | MINS_COMM_CD | APP_ITEM | G_MINS_COMM_CD | - | - | MAPPED | FORMS_APX.get/set_global (f345: G_<name>) |
| 622 | GLOBAL | LETTER_NBR | APP_ITEM | G_LETTER_NBR | - | - | MAPPED | FORMS_APX.get/set_global (f345: G_<name>) |
| 623 | GLOBAL | SUPP_TITLE_CD | APP_ITEM | G_SUPP_TITLE_CD | - | - | MAPPED | FORMS_APX.get/set_global (f345: G_<name>) |
| 624 | GLOBAL | LETTER_DT | APP_ITEM | G_LETTER_DT | - | - | MAPPED | FORMS_APX.get/set_global (f345: G_<name>) |
| 625 | GLOBAL | MOBILE_NO | APP_ITEM | G_MOBILE_NO | - | - | MAPPED | FORMS_APX.get/set_global (f345: G_<name>) |
| 626 | GLOBAL | IMPR_NBR_B | APP_ITEM | G_IMPR_NBR_B | - | - | MAPPED | FORMS_APX.get/set_global (f345: G_<name>) |
| 627 | GLOBAL | IMPR_NAME_B | APP_ITEM | G_IMPR_NAME_B | - | - | MAPPED | FORMS_APX.get/set_global (f345: G_<name>) |
| 628 | GLOBAL | BRKR_ATHRZTN_NBR_B | APP_ITEM | G_BRKR_ATHRZTN_NBR_B | - | - | MAPPED | FORMS_APX.get/set_global (f345: G_<name>) |
| 629 | GLOBAL | CHEK | APP_ITEM | G_CHEK | - | - | MAPPED | FORMS_APX.get/set_global (f345: G_<name>) |
| 630 | GLOBAL | STAT_QUE | APP_ITEM | G_STAT_QUE | - | - | MAPPED | FORMS_APX.get/set_global (f345: G_<name>) |
| 631 | GLOBAL | STAT_CLR | APP_ITEM | G_STAT_CLR | - | - | MAPPED | FORMS_APX.get/set_global (f345: G_<name>) |
| 632 | GLOBAL | IMP0F4 | APP_ITEM | G_IMP0F4 | - | - | MAPPED | FORMS_APX.get/set_global (f345: G_<name>) |
| 633 | GLOBAL | EXE_DETAIL_QUERY | APP_ITEM | G_EXE_DETAIL_QUERY | - | - | MAPPED | FORMS_APX.get/set_global (f345: G_<name>) |
| 634 | GLOBAL | INS | APP_ITEM | G_INS | - | - | MAPPED | FORMS_APX.get/set_global (f345: G_<name>) |
| 635 | GLOBAL | IMPR_TYPE_CD | LOV | Popup LOV return value | - | - | MAPPED | LOV-form return global |
| 636 | GLOBAL | IMPR_TYPE_NAME | LOV | Popup LOV return value | - | - | MAPPED | LOV-form return global |
| 637 | GLOBAL | BUS_ID_TYPE_CD | LOV | Popup LOV return value | - | - | MAPPED | LOV-form return global |
| 638 | GLOBAL | BUS_ID_TYPE_NAME | LOV | Popup LOV return value | - | - | MAPPED | LOV-form return global |
| 639 | GLOBAL | CTRY_CD | LOV | Popup LOV return value | - | - | MAPPED | LOV-form return global |
| 640 | GLOBAL | CRTY_ARBC_NAME | LOV | Popup LOV return value | - | - | MAPPED | LOV-form return global |
| 641 | GLOBAL | CITY_CD | LOV | Popup LOV return value | - | - | MAPPED | LOV-form return global |
| 642 | GLOBAL | CITY_ARB_NAME | LOV | Popup LOV return value | - | - | MAPPED | LOV-form return global |
| 643 | GLOBAL | PORT_NAME | LOV | Popup LOV return value | - | - | MAPPED | LOV-form return global |
| 644 | GLOBAL | IMPR_NAME | LOV | Popup LOV return value | - | - | MAPPED | LOV-form return global |
| 645 | GLOBAL | EXIT | - | - | - | - | DROPPED | toolbar / version / help |
| 646 | GLOBAL | CURRENT_VER | - | - | - | - | DROPPED | toolbar / version / help |
| 647 | GLOBAL | CURRENT_DT | - | - | - | - | DROPPED | toolbar / version / help |
| 648 | GLOBAL | CURRENT_VERSION | - | - | - | - | DROPPED | toolbar / version / help |
| 649 | GLOBAL | CG$HP_HPATH | - | - | - | - | DROPPED | toolbar / version / help |
| 650 | GLOBAL | CG$HP_HFILE | - | - | - | - | DROPPED | toolbar / version / help |
| 651 | GLOBAL | SYSTEM_OBJ | - | - | - | - | DROPPED | toolbar / version / help |
| 652 | LIBRARY | OFGTEL | - | - | - | - | TODO | MISSING SOURCE .pll - used calls re-implemented or mapped (extraction report §7.3) |
| 653 | LIBRARY | OFGMES | - | - | - | - | TODO | MISSING SOURCE .pll - used calls re-implemented or mapped (extraction report §7.3) |
| 654 | LIBRARY | OFGHPL | - | - | - | - | TODO | MISSING SOURCE .pll - used calls re-implemented or mapped (extraction report §7.3) |
| 655 | LIBRARY | CIC_AMSG | - | - | - | - | TODO | MISSING SOURCE .pll - used calls re-implemented or mapped (extraction report §7.3) |
| 656 | LIBRARY | SEC_LIB | - | - | - | - | TODO | MISSING SOURCE .pll - used calls re-implemented or mapped (extraction report §7.3) |
| 657 | LIBRARY | CAPTION | - | - | - | - | TODO | MISSING SOURCE .pll - used calls re-implemented or mapped (extraction report §7.3) |
| 658 | LIBRARY | OFGBSL | - | - | - | - | TODO | MISSING SOURCE .pll - used calls re-implemented or mapped (extraction report §7.3) |
| 659 | LIBRARY | D2KWUTIL | - | - | - | - | TODO | MISSING SOURCE .pll - used calls re-implemented or mapped (extraction report §7.3) |
| 660 | LIBRARY | CUSTOMDLL | - | - | - | - | TODO | MISSING SOURCE .pll - used calls re-implemented or mapped (extraction report §7.3) |
| 661 | LIBRARY | D2KWUTIL_PDF | - | - | - | - | TODO | MISSING SOURCE .pll - used calls re-implemented or mapped (extraction report §7.3) |
| 662 | LIBRARY | GETCOMP | - | - | - | - | TODO | MISSING SOURCE .pll - used calls re-implemented or mapped (extraction report §7.3) |
| 663 | LIBRARY | OFGTAB | - | - | - | - | TODO | MISSING SOURCE .pll - used calls re-implemented or mapped (extraction report §7.3) |
| 664 | LIBRARY | PICKLIST | - | - | - | - | TODO | MISSING SOURCE .pll - used calls re-implemented or mapped (extraction report §7.3) |
| 665 | LIBRARY | POS | - | - | - | - | TODO | MISSING SOURCE .pll - used calls re-implemented or mapped (extraction report §7.3) |
| 666 | LIBRARY | SCDLL | - | - | - | - | TODO | MISSING SOURCE .pll - used calls re-implemented or mapped (extraction report §7.3) |
| 667 | LIBRARY | VCDLL | - | - | - | - | TODO | MISSING SOURCE .pll - used calls re-implemented or mapped (extraction report §7.3) |
| 668 | LIBRARY | CIC_LIB | - | - | - | - | TODO | MISSING SOURCE .pll - used calls re-implemented or mapped (extraction report §7.3) |

## 15. Registry script

`registry/IMPR1110_registry.sql` v3.0 (generated): one `MIG_FORM_REGISTRY` row (app 202530, page 1110,
package IMPR1110, status DESIGN) and one `MIG_OBJECT_MAP` row per line of §14. Re-runnable: it deletes the
form's rows first, and it ends with COMMIT. **Not executed** (CLAUDE.md §6.10).

## 16. Changes made to step-02 code during this step, open items

Package `IMPR1110` **005 → 006** (generator `work/step02/build_package.py`, self-check clean):
- DATE columns (BUS_ID_EXPRD_DT, BUS_ID_ISSUE_DT, LST_TRAN_DT) are passed as `VARCHAR2` and converted with
  `c_mask` (`MI-MM-YYYY`; package 010: function `HIJRI_DATE_FORMAT`, Application Setting, default `YYYY-MM-MI`) / `c_date_time_mask` (`YYYY/MM/DD HH24:MI:SS`, the Forms PLSQL_DATE_FORMAT).
  APEX binds page items as text with the application date format (`DS`), which cannot read Hijri values.
- `P0_PAGE_PK_CHECK` checks a ROWID key; new `IMPORTER_ROW_ID` for process `EXECUTE-QUERY`.
- `READ_ONLY_FLAGS` covers 14 groups (added IMPR_TYPE_CD, BUS_ID_EXPRD_DT, IMPR_TEL_NBR and CAR_AGENT_FLAG,
  which the function modes and PRE-INSERT unlock).

Open items:

| # | Item | Blocks |
|---|---|---|
| 1 | HIGH (extraction §7 #1): how IMPR_NBR gets its value on insert (`CREATE_UNI_IMPR_NEBRAS`, a DB trigger, or a view). The ROWID key works either way, but the native insert must give the same row as Forms | CREATE |
| 2 | SUPPORT_ENTRY is converted as its own form (decision §15 #12): its page number, the `P1110_SUPPORT_URL` computation, and the G_ items it sets on close | functions F1, F2, F3, F5 |
| 3 | `SYS_OS_FILE_NAME` values of the 11 functions: the custom-event names and the `ADJ_FUNS` list must match them exactly (with or without `.fmx`) | functions |
| 4 | Security: an item disabled by a `READ ONLY` DA is enforced only in the browser. A changed request could still update a locked column. SUGGESTION: a server-side check in PRE_UPDATE that compares the locked columns with the database row, using the same `<ITEM>_IS_READ_ONLY` functions | SAVE |
| 5 | Forms runs `IMPR_TYPE_CD_LOV_RETURN` only after an LOV pick; the design runs it on every change of IMPR_TYPE_CD (TODO-VERIFY in step 05) | IMPR_TYPE_CD |
| 6 | The broker question (PRE-INSERT CONFIRM) is asked before the validations; Forms asks it inside PRE-INSERT, after them | CREATE |
| 7 | WHEN-NEW-RECORD-INSTANCE also runs after every SAVE (the page renders the record again); Forms stays in the record. Check the class 19 / user type 1 rule (IMPR_TYPE_CD := 19) for side effects | SAVE |
| 8 | `P_BRKR_PORT_CD`, `P_LIC_TYPE` are not set by the f345 login (§13.2) | brokers |
| 9 | Arabic texts of FRM-40202 / 40350 (NIB.ON_ERROR, MISSING SOURCE) | messages |
| 10 | FOS success-message display of `FORMS_APX.MESSAGE` text from an AJAX call (§10.1) | notes |
| 11 | List template of region `FUNCS` (f345 *Moy Functions Nav*, TODO-VERIFY against AGR1100). Process `New` is a disabled placeholder (condition Never, as in AGR1100): its AGR1100 code holds a host name | step 04 |
| 12 | Decision §15 #6 (page 0 DELETE offered, no extra function restriction): to be confirmed | DELETE |

Step 04 must replace `scripts/gen_apex_impr1110.py` (revision-1 design: AJAX, JavaScript file). The new
generator should read `work/step03/page_design.json`.
