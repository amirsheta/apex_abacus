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

