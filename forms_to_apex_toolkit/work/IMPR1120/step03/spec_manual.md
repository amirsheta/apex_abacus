# IMPR1120 – APEX 21.2 Page Specification (step 03, revision 1)

| Item | Value |
|---|---|
| Form | `IMPR1120.fmb` — "صيانة توقيفات المستوردين" (Importer Suspension Maintenance) |
| Date | 2026-11-23 |
| Application | 202530 (installed from f345, ID offset 460632461717563830), page group `IMPR` |
| Pages | **1120** `IMPR1120` (main) · **112001** `IMPR1120_SEARCH` (modal search) |
| Package | `LIB_APX_USR.IMPR1120` version **009** (009: common helpers in FORMS_APX 004, pages call FORMS_APX.CHECK_ERROR / GET_MODULE_ID / HEADER_TITLE / HIJRI_DATE_FORMAT; 008: Hijri date format from the Application Setting `HIJRI_DATE_FORMAT`; 007: URL-safe ROWID key from the search page, P0_PAGE_PK_CHECK; 006: compile fix in IMPR_SUSPN_SAVE_ROW; step 03 changes in §16; 003–005: parameter names without `I_` / `IO_` / `O_`, page items passed as `P_<ITEM>`, no doubled `P_P_`, §16 #14) |
| Inputs | [inventory](IMPR1120_inventory.md), [logic extraction](IMPR1120_logic_extraction.md), [package spec](../../plsql/IMPR1120/impr1120_spec.sql), `docs/f345_reference_standard.md` |
| Generated parts | §14 and `registry/IMPR1120_registry.sql` are built by `work/IMPR1120/step03/build_trace.py` from the XML (edit `work/IMPR1120/step03/spec_manual.md` or the script, then re-run) |
| Status | design only: no export yet (step 04); the package is **not compiled** |

---

## 0. Decisions that shape the page

1. **Master-detail on one page (AGR1100 pattern).** `IMPORTERS` becomes a **read-only Form region** keyed by ROWID, as in IMPR1110. `IMPR_SUSPN` becomes an **editable Interactive Grid** filtered by the master keys (relation `CGFK$IS_1_IMP_FK`).
2. **Record key = importer ROWID in `P0_PAGE_PK`.** It is set by the search page link, or by typing the importer number (`IMPR_NBR` → process `EXECUTE-QUERY`, which replaces the `:GLOBAL.Exec_Query_Now` flow).
3. **Page 0 requests on this page** (page 0 is not changed: f345 rule):

   | Request | Shown when | Page 1120 does |
   |---|---|---|
   | `CREATE` | `P0_PAGE_PK` is null | the same as typing the number: process `EXECUTE-QUERY` opens the importer. Forms never inserts an importer here (all items Insert Allowed = No) |
   | `SAVE` | `P0_PAGE_PK` is set | saves the grid (`IMPR_SUSPN - Save Interactive Grid Data`) |
   | `DELETE` | `P0_PAGE_PK` is set | refused by process `PRE-DELETE` (`IMPR1120.PRE_DELETE`): block `IMPORTERS` has Delete Allowed = No. Suspensions are deleted in the grid |
   | `SEARCH` | `P0_PAGE_PK` is null | opens 112001 |

4. **Grid DML is one package call per row.** Process `IMPR_SUSPN - Save Interactive Grid Data` is *Interactive Grid – Automatic Row Processing (DML)* with **Target Type = PL/SQL Code**, which calls `IMPR1120.IMPR_SUSPN_SAVE_ROW`. That member runs the Forms order per row:

   | Row status | Order |
   |---|---|
   | C | PRE-INSERT → INSERT → POST-INSERT |
   | U | PRE-UPDATE → UPDATE |
   | D | ON-DELETE (soft delete) |

   This differs from the f345 skeleton (separate `<BLOCK> PRE-*` processes around a native DML process) for two reasons. `MAX(SUSPN_SEQ)+1` in PRE-INSERT needs the previous new row already inserted. And the native DML would really delete the row instead of setting `SUSPN_RLSE_DT`.
5. **Rules driven by `CURRENT_SIDE`.** The site comes from the page item `P1120_P_CURRENT_SIDE` (process `PARAMETERS CURRENT_SIDE`). It drives:
   - the site check at entry (`WHEN-NEW-FORM-INSTANCE`);
   - the column defaults;
   - the reason and side validations;
   - row read-only state (every column: `IMPR_SUSPN_IS_READ_ONLY`, *For Each Row*), with the matching server check in `IMPR_SUSPN_SAVE_ROW`.
6. **Hijri dates as text, one format.** The grid SQL returns the dates as `TO_CHAR(…, (SELECT FORMS_APX.HIJRI_DATE_FORMAT FROM dual))`. `FORMS_APX.HIJRI_DATE_FORMAT` reads the APEX Application Setting `HIJRI_DATE_FORMAT` (default `YYYY-MM-MI`, the output format of the f345 Hijri picker; the day is kept in the minutes); Forms used `MI-MM-RRRR` (OLB class `CGSO$HDATE_ARB`). Change the setting to change the format of both forms, without a recompile (user request 2026-11-23). The columns are Text Fields with the f345 class `hijri-date-default` (app-wide Hijri picker), and the package converts the text with the same function.
7. **Forms WHEN-VALIDATE-ITEM fires only when the item changes.** The grid validations get the row key and skip a value equal to the stored one. Without this, editing only the end date of an older suspension would fail "start date ≥ today".
8. **Declarative, no JavaScript.** 0 *Execute JavaScript Code* actions, no JavaScript file, no AJAX callback.

## 1. Page type decision per block

| Forms block | Characteristics | APEX 21.2 | Template / classes | Reason |
|---|---|---|---|---|
| `IMPORTERS` | single record, base table, UPDATE / DELETE not allowed, items not insertable: a search header | **Form region** `IMPORTERS` on page 1120, primary key ROWID, **no Process form** (read only) | Interactive Report (`11621909206693869707`), `#DEFAULT#`, `zatca-forms cg-form cg-card` | decision table row 1, read only |
| `IMPORTERS` Enter / Execute Query | QBE on the header items + PRE-QUERY | search page **112001**: criteria region + read-only IG with link column | Blank with Attributes `zatca-forms cg-form` + Standard IG `cg-card cg-grid` | f345 `<page>01` |
| `IMPR_SUSPN` | multi record (5 shown), base table `IMPR_SUSPNS`, insert / update / delete, 6 editable columns, detail of IMPORTERS | **editable Interactive Grid** `IMPR_SUSPN` | Standard (`11621913486616869708`), `#DEFAULT#:t-Region--noPadding`, `cg-card cg-grid` | decision table row "master single-record + detail multi-record" |
| `TITLE` | OLB control block | hero region `IMPORTERS_HERO` | Blank with Attributes (`11621859120066869682`), `cg-hero` | f345 |
| `LSIDE` | OLB side function menu | inline dialog region `FUNCS`, f345 list *Page Functions* | Inline Dialog (`11621894586660869699`), `#DEFAULT#:js-dialog-size480x320` | f345 toolbar `FUNCS` |
| `TOOLBAR` | OLB toolbar | page 0 toolbar `P0_ACTIONS` | – | f345 |
| `EDI_MSG` | OLB EDI ticker | dropped | – | timers dropped (IMPR1110 decision 2026-11-19) |

## 2. Pages

| Page | Name / alias | Mode | Page template | Title | CSS / protection | Source canvas / window | Menu role (documentation only) | Navigation menu |
|---|---|---|---|---|---|---|---|---|
| 1120 | `IMPR1120` / `IMPR1120` | Normal | Zatca-Minimal_No_Navigation (`11622270914969205733`) | `&SYS_ANAME.` | `zf` / `C` | `CG$PAGE_1` / `CGSO$WINDOW_1` "بيانات المستورد" | none in the form; the launcher opens it from `SC_SYSTEM_OBJECTS` (privileges: application, CLAUDE.md §8) | entry under the IMPR group, as for IMPR1110 (f345 menu list) |
| 112001 | `IMPR1120_SEARCH` / `IMPR1120-SEARCH` | Modal Dialog 1800 × 800, Cursor Focus *First item on page* (`P112001_SEARCH`) | theme default for dialogs | `&SYS_ANAME.` | `zf` / `C` | Enter-Query / Execute-Query of block IMPORTERS | as 1120 | no |

Both pages: `p_user_interface_id => wwv_flow_api.id(11622010846008869795)`, page group `IMPR`. No `<page>02` page is needed (no stacked canvas, and the 4 LOV forms become LOVs / column filters).

## 3. Regions

### Page 1120

| Seq | Region (Static ID) | Type | Source | Primary key | Template / options / CSS | Position | Edit | Forms block |
|---|---|---|---|---|---|---|---|---|
| 10 | `IMPORTERS_HERO` | Static Content | item `P1120_HERO_TITLE` | – | Blank with Attributes, `#DEFAULT#`, `cg-hero` | Body | – | `TITLE` |
| 20 | `IMPORTERS` – title "بيانات المستورد" | **Form** | Table `IMPORTERS` | **ROWID** → `P1120_ROW_ID` | Interactive Report, `#DEFAULT#`, `zatca-forms cg-form cg-card` | Body | none (no Process form) | `IMPORTERS` |
| 30 | `IMPR_SUSPN` – title "توقيفات المستوردين" | **Interactive Grid**, editable | SQL below | `PORT_CD`, `IMPR_NBR`, `SUSPN_SEQ` (Forms PK `IS_1_PK`) | Standard, `#DEFAULT#:t-Region--noPadding`, `cg-card cg-grid` | Body | Add, Update, Delete | `IMPR_SUSPN` |
| 40 | `FUNCS` | List, f345 *Page Functions* | – | – | Inline Dialog, `#DEFAULT#:js-dialog-size480x320`; list template as IMPR1110 (TODO-VERIFY) | Body | – | `LSIDE` |

Region `IMPR_SUSPN`:

```sql
SELECT s.port_cd,
       s.impr_nbr,
       s.suspn_seq,
       TO_CHAR(s.suspn_strt_dt, (SELECT FORMS_APX.HIJRI_DATE_FORMAT FROM dual)) AS suspn_strt_dt,
       TO_CHAR(s.suspn_end_dt,  (SELECT FORMS_APX.HIJRI_DATE_FORMAT FROM dual)) AS suspn_end_dt,
       s.suspn_rsn_cd,
       s.suspn_rsn_text,
       s.suspn_side_cd
  FROM impr_suspns s
 WHERE s.port_cd  = :P1120_PORT_CD             -- relation CGFK$IS_1_IMP_FK
   AND s.impr_nbr = :P1120_IMPR_NBR
   AND s.suspn_rlse_dt IS NULL                 -- block WHERE clause (active suspensions only)
```

- Page Items to Submit: `P1120_PORT_CD`, `P1120_IMPR_NBR`.
- Server-side condition: `P0_PAGE_PK` is not null. In Forms the grid is empty until an importer is queried.
- IG attributes: f345 defaults (standard §8). `p_is_editable => true`, `p_edit_operations => 'i:u:d'`, `p_add_row_if_empty => false`, `p_submit_checked_rows => false`, `p_lazy_loading => false`, toolbar `SEARCH_COLUMN:SEARCH_FIELD:ACTIONS_MENU:RESET`, `p_enable_save_public_report => false`.
- Default report: 5 rows per page (Forms *Records Displayed* = 5), sorted by `SUSPN_SEQ`. The Forms block has no ORDER BY; rows came in ROWID order, which for an ever-growing sequence is the same order.
- *Prevent Lost Updates* = Yes (verify in step 04 that it applies with Target Type PL/SQL Code, §16 #6).

### Page 112001 – IMPR1120_SEARCH

| Seq | Region | Type | Content | Template | Forms source |
|---|---|---|---|---|---|
| 10 | `IMPORTERS_SEARCH_CRITERIA` | Static Content | one search text `P112001_SEARCH`, buttons `SEARCH` (Text with Icon, `fa-search`, class `cg-b-search`) and `CLEAR` (Text with Icon, `fa-eraser`, class `cg-b-clear`), both `#DEFAULT#:t-Button--iconLeft`, Defined by DA | Blank with Attributes, `zatca-forms cg-form` | PRE-QUERY criteria as one text over all columns (user request 2026-11-23) |
| 20 | `IMPORTERS_SEARCH` | Interactive Grid, not editable | SQL below | Standard, `#DEFAULT#:t-Region--noPadding`, `cg-card cg-grid`; IG defaults (standard §8) except: toolbar `ACTIONS_MENU:RESET` (no second search field), Lazy Loading on, no total row count | QBE on the IMPORTERS items: the one search text and the column filters |

```sql
-- one search text over every shown column (user request 2026-11-23); no rows until a search is made, as Forms
-- opens the block in Enter-Query mode: the dialog opens without reading IMPORTERS. No sort clause (user request
-- 2026-11-23: the whole result is not sorted; the grid columns can still be sorted)
SELECT TRANSLATE(ROWIDTOCHAR(i.ROWID), '+/', '-_') AS row_id,   -- URL-safe: a '+' in f?p arrives as a space
       i.port_cd, p.port_name, i.impr_nbr, i.hq_impr_nbr,
       i.arbc_impr_name, i.eng_impr_name, i.impr_cntct_name,
       i.impr_type_cd, it.impr_type_name, i.bus_id_type_cd, i.bus_id, i.bus_id_brnch,
       i.ctry_cd, c.crty_arbc_name, i.city_code_of_id, i.impr_expr_type
  FROM importers i, sd_ports p, impr_types it, countries c
 WHERE :P112001_SEARCH IS NOT NULL
   AND i.port_cd = NVL((SELECT IMPR1120.IMPORTERS_PRE_QUERY_PORT_CD(PORT_CD        => NULL,
                                                                    P_CURR_PORT_CD => :P_CURR_PORT_CD)
                          FROM dual), i.port_cd)
   AND p.port_cd (+)       = i.port_cd
   AND it.impr_type_cd (+) = i.impr_type_cd
   AND c.ctry_cd (+)       = i.ctry_cd
   AND (INSTR(UPPER(i.port_cd || '|' || p.port_name || '|' || i.impr_nbr || '|' || i.hq_impr_nbr || '|' ||
                    i.arbc_impr_name || '|' || i.eng_impr_name || '|' || i.impr_cntct_name || '|' ||
                    i.impr_type_cd || '|' || it.impr_type_name || '|' || i.bus_id_type_cd || '|' || i.bus_id || '|' ||
                    i.bus_id_brnch || '|' || i.ctry_cd || '|' || c.crty_arbc_name || '|' || i.city_code_of_id || '|' ||
                    i.impr_expr_type), UPPER(TRIM(:P112001_SEARCH))) > 0
        OR i.impr_name_std LIKE '%' || (SELECT IMPR1120.IMPORTERS_PRE_QUERY_NAME_STD(
                                                   ARBC_IMPR_NAME => TRIM(:P112001_SEARCH))
                                          FROM dual) || '%')
```

- The `(SELECT … FROM dual)` wrappers make Oracle call each function once per query (scalar subquery caching), not once per row.
- Page Items to Submit: `P112001_SEARCH`.
- **Opening is fast:** the query returns no rows while `P112001_SEARCH` is empty (Forms opens the block in Enter-Query mode), so the dialog opens without reading `IMPORTERS`; there is no total row count (a COUNT over the whole result on every search) and no sort clause (the block ORDER BY port_cd DESC is dropped at the user's request: the whole result is not sorted; a grid column can still be sorted).
- بحث and Enter refresh the grid (no page submit). The loading overlay tried on 2026-11-23 (Submit Page with Show Processing) did not work and was removed at the user's request.
- **One search text** is compared (contains, upper case) with every shown column, and the Arabic name is also searched in `IMPR_NAME_STD` through `IMPORTERS_PRE_QUERY_NAME_STD` (PRE-QUERY `STR.StrFormat`). The port rule of PRE-QUERY stays: outside port 99 only the user's port (`IMPORTERS_PRE_QUERY_PORT_CD(PORT_CD => NULL, …)`). A search reads the importers of the port (all importers for port 99): it cannot use an index, because the text may match any column.
- Link column `IMPR_NBR`: Link Builder → page 1120, clear cache 1120, `P0_PAGE_PK = &ROW_ID.`. `ROW_ID` is the ROWID made URL-safe (`TRANSLATE(…, '+/', '-_')`): a `+` in an `f?p` value arrives as a space and the checksum fails ("The checksum computed on the request … did not match", found at import 2026-11-23). `IMPR1120.P0_PAGE_PK_CHECK` translates it back; a ROWID never contains `-` or `_`.
- `ROW_ID` is hidden. Every other column is shown with the Forms prompt as its heading, so the IG column filters replace the Forms QBE on each item. They also replace the LOV forms `LOV_Impr_Type`, `LOV_COUNTRIES` and `LOV_CITIES`, which this form only used as query criteria.
- Forms QBE supports `<`, `>`, `=`, `#` and `%`; the search text is a plain *contains* search (no wildcards). The column filters of the Actions menu remain for exact criteria.

## 4. Items

### 4.1 Page 1120 – region `IMPORTERS` (Forms tab order)

Label template *Optional - Above* (`11621983529556869749`) with `#DEFAULT#:t-Form-fieldContainer--stretchInputs`, unless noted. No item is required: the header is read only.

| Page item | Source column | Type | Label | Read Only | LOV | Max | Forms item |
|---|---|---|---|---|---|---|---|
| `P1120_ROW_ID` | ROWID (primary key) | Hidden, Value Protected | – | – | – | – | Forms key mode ROWID |
| `P1120_PORT_CD` | PORT_CD | Popup LOV (Additional Output `PORT_NAME` → `P1120_PORT_NAME`) | رمز الجمرك | PL/SQL Expression `IMPR1120.PORT_CD_IS_READ_ONLY(P_CURR_PORT_CD => :P_CURR_PORT_CD) OR :P0_PAGE_PK IS NOT NULL` | `LOV_SD_PORTS` | 4 | `IMPORTERS.PORT_CD` |
| `P1120_PORT_NAME` | – (Source None) | Display Only | – | always | – | 40 | `IMPORTERS.PORT_NAME` |
| `P1120_HQ_IMPR_NBR` | HQ_IMPR_NBR | Display Only | الرقم الموحد بالمصلحة | always | – | 11 | `IMPORTERS.HQ_IMPR_NBR` |
| `P1120_IMPR_NBR` | IMPR_NBR | Number Field | الرقم الجمركى | Item `P0_PAGE_PK` is not null | – | 11 | `IMPORTERS.IMPR_NBR` |
| `P1120_IMPR_TYPE_CD` | IMPR_TYPE_CD | Display Only | رمز النشاط التجارى | always | – | 4 | `IMPORTERS.IMPR_TYPE_CD` |
| `P1120_IMPR_TYPE_NAME` | – | Display Only | – | always | – | 40 | `IMPORTERS.IMPR_TYPE_NAME` |
| `P1120_CTRY_CD` | CTRY_CD | Display Only | الجنسيه | always | – | 4 | `IMPORTERS.CTRY_CD` |
| `P1120_CRTY_ARBC_NAME` | – | Display Only | – | always | – | 50 | `IMPORTERS.CRTY_ARBC_NAME` |
| `P1120_CITY_CODE_OF_ID` | CITY_CODE_OF_ID | Display Only | مصدر الرقم الإستدلالي | always | – | 4 | `IMPORTERS.CITY_CODE_OF_ID` |
| `P1120_ID_CITY_NAME` | – | Display Only | – | always | – | 20 | `IMPORTERS.ID_CITY_NAME` |
| `P1120_IMPR_EXPR_TYPE` | IMPR_EXPR_TYPE | Display Only (based on LOV) | النشاط الجمركي | always | `LOV_ALLOWED_EXPORT` | 2 | `IMPORTERS.IMPR_EXPR_TYPE` |
| `P1120_BUS_ID` | BUS_ID | Display Only | الرقم الاستدلالى | always | – | 15 | `IMPORTERS.BUS_ID` |
| `P1120_BUS_ID_TYPE_CD` | BUS_ID_TYPE_CD | Display Only | نوعه | always | – | 4 | `IMPORTERS.BUS_ID_TYPE_CD` |
| `P1120_BUS_ID_TYPE_NAME` | – | Display Only | – | always | – | 40 | `IMPORTERS.BUS_ID_TYPE_NAME` |
| `P1120_BUS_ID_BRNCH` | BUS_ID_BRNCH | Display Only | الفرع | always | – | 10 | `IMPORTERS.BUS_ID_BRNCH` |
| `P1120_ARBC_IMPR_NAME` | ARBC_IMPR_NAME | Display Only | الاسم العربى | always | – | – | `IMPORTERS.ARBC_IMPR_NAME` |
| `P1120_ENG_IMPR_NAME` | ENG_IMPR_NAME | Display Only | الاسم الأجنبي | always | – | – | `IMPORTERS.ENG_IMPR_NAME` |
| `P1120_IMPR_CNTCT_NAME` | IMPR_CNTCT_NAME | Display Only | الوكيل المفوض | always | – | – | `IMPORTERS.IMPR_CNTCT_NAME` |
| `P1120_CTRY_CD_OF_ID` | CTRY_CD_OF_ID | Hidden, Value Protected | – | – | – | 4 | `IMPORTERS.CTRY_CD_OF_ID` (input of the city lookup) |

The Forms prompts use tatweel padding (e.g. `رمز الجمــــــــــــــرك`); the labels above drop it. Display Only items have *Send On Page Submit* = Yes only for `P1120_PORT_CD`, `P1120_IMPR_NBR`, `P1120_HQ_IMPR_NBR`, `P1120_PORT_NAME` and `P1120_BUS_ID`, because the save needs them (POST-INSERT notification). Dropped items: §14.

### 4.2 Page 1120 – other items

| Item | Type | Purpose | Forms source |
|---|---|---|---|
| `P1120_HERO_TITLE` | Display Only in `IMPORTERS_HERO` | screen title (`HEADER TITLE`) | `TITLE` block |
| `P1120_MODULE_ID` | Hidden | f345 (kept by SCREEN ENTRY RESET) | `:PARAMETER.P_MODULE_ID` |
| `P1120_P_CURRENT_SIDE` | Hidden, Value Protected = Yes | site of the user (1 / 2 / 3) | `:PARAMETER.CURRENT_SIDE` |

### 4.3 Page 1120 – IG `IMPR_SUSPN` columns (Forms navigation order)

The row read-only expression **R** is `IMPR1120.IMPR_SUSPN_IS_READ_ONLY(SUSPN_SIDE_CD => :SUSPN_SIDE_CD, P_CURRENT_SIDE => :P1120_P_CURRENT_SIDE, P_CURR_PORT_CD => :P_CURR_PORT_CD)`, set as Read Only, PL/SQL Expression, *Execute For Each Row*.

| Column | Type | Heading | Required | Default | LOV | Max | Read Only | Forms item |
|---|---|---|---|---|---|---|---|---|
| `PORT_CD` | Hidden, primary key | – | – | Item `P1120_PORT_CD` (master form) | – | – | – | `IMPR_SUSPN.PORT_CD` (CopyValueFrom IMPORTERS.PORT_CD; the save call also uses `NVL(:PORT_CD, :P1120_PORT_CD)`) |
| `IMPR_NBR` | Hidden, primary key | – | – | Item `P1120_IMPR_NBR` (master form) | – | – | – | `IMPR_SUSPN.IMPR_NBR` (CopyValueFrom IMPORTERS.IMPR_NBR; the save call also uses `NVL(:IMPR_NBR, :P1120_IMPR_NBR)`) |
| `SUSPN_SEQ` | Hidden, primary key | – | – | – | – | – | – | `IMPR_SUSPN.SUSPN_SEQ` (set in PRE-INSERT) |
| `SUSPN_STRT_DT` | Text Field, CSS class `hijri-date-default`, placeholder "يوم-شهر-سنة" | بداية الإيقاف | Yes (Value Required) | PL/SQL Expression `IMPR1120.SUSPN_STRT_DT_DEFAULT` | – | 10 | R | `IMPR_SUSPN.SUSPN_STRT_DT` |
| `SUSPN_END_DT` | Text Field, `hijri-date-default` | نهاية الإيقاف | Yes | – | – | 10 | R | `IMPR_SUSPN.SUSPN_END_DT` |
| `SUSPN_RSN_CD` | Select List (no null entry) | السبب | through `SUSPN_RSN_CD VALIDATION` | `IMPR1120.SUSPN_RSN_CD_DEFAULT(P_CURRENT_SIDE => :P1120_P_CURRENT_SIDE, P_CURR_PORT_CD => :P_CURR_PORT_CD)` | `LOV_IMPR_SUSPN_RSN_CD` | – | R | `IMPR_SUSPN.SUSPN_RSN_CD` |
| `SUSPN_RSN_TEXT` | Text Field | ملاحظات | Yes | `IMPR1120.SUSPN_RSN_TEXT_DEFAULT(P_CURRENT_SIDE => :P1120_P_CURRENT_SIDE, P_CURR_PORT_CD => :P_CURR_PORT_CD)` | – | 100 | R | `IMPR_SUSPN.SUSPN_RSN_TEXT` |
| `SUSPN_SIDE_CD` | Select List (no null entry) | الجهة | through `SUSPN_SIDE_CD VALIDATION` | `IMPR1120.SUSPN_SIDE_CD_DEFAULT(P_CURRENT_SIDE => :P1120_P_CURRENT_SIDE, P_CURR_PORT_CD => :P_CURR_PORT_CD)` | `LOV_SUSPN_SIDE_CD` | – | R `OR IMPR1120.SUSPN_SIDE_CD_IS_READ_ONLY(PORT_CD => :PORT_CD, IMPR_NBR => :IMPR_NBR, SUSPN_SEQ => :SUSPN_SEQ)` | `IMPR_SUSPN.SUSPN_SIDE_CD` |

`SUSPN_RLSE_DT` is not a grid column. The package sets it (PRE-UPDATE, ON-DELETE), and the region shows only rows where it is empty.

### 4.4 Page 112001 – criteria items

| Item | Type | Label | Default | Read Only | LOV | Forms source |
|---|---|---|---|---|---|---|
| `P112001_SEARCH` | Text Field | بحث في كل الأعمدة | – | – | – | PRE-QUERY criteria (PORT_CD, PORT_NAME, ARBC_IMPR_NAME) and the QBE of the other items, as one text |

## 5. Buttons

No page buttons on 1120: page 0 supplies CREATE, SAVE, DELETE, SEARCH, CLEAR, FUNCS and BACK (§0 #3).

| Button | Page / region | Action | Template | Source |
|---|---|---|---|---|
| `SEARCH` | 112001 / `IMPORTERS_SEARCH_CRITERIA` | Defined by DA `SEARCH WHEN-BUTTON-PRESSED` (native Refresh of `IMPORTERS_SEARCH`) | Text with Icon (`11621986167597869752`), `#DEFAULT#:t-Button--iconLeft`, `fa-search`, class `cg-b-search` | TOOLBAR.EXECUTE (Execute Query) |
| `CLEAR` | 112001 / `IMPORTERS_SEARCH_CRITERIA` | Defined by DA `CLEAR WHEN-BUTTON-PRESSED` (native Clear of `P112001_SEARCH`, then Refresh of `IMPORTERS_SEARCH`) | Text with Icon (`11621986167597869752`), `#DEFAULT#:t-Button--iconLeft`, `fa-eraser`, class `cg-b-clear`, label "مسح البحث" | TOOLBAR.CLEAR_ALL for the search (user request 2026-11-23) |

The Forms toolbar and LOV buttons map to page 0 or to the popup LOV icon (§14).

## 6. LOVs

| Forms LOV / list | APEX LOV | Type | SQL (display, return) | Used by | Item type | Notes |
|---|---|---|---|---|---|---|
| `CGFK$IMPORTERS_PORT_CD` / LOV form `LOV_SD_PORTS` | **`LOV_SD_PORTS`** (exists from IMPR1110) | SQL | `SELECT port_cd d, port_cd r, port_name FROM sd_ports WHERE port_status = 1 AND port_type = NVL(:P_PORT_TYPE, port_type) ORDER BY port_cd` | `P1120_PORT_CD` | Popup LOV, Additional Output PORT_NAME | Forms passes `STATUS = 1` only outside Enter-Query (§16 #8) |
| list item `IMPR_EXPR_TYPE` (`CG_REF_CODES` 'ALLOWED EXPORT') | **`LOV_ALLOWED_EXPORT`** (exists from IMPR1110) | SQL | `SELECT rv_meaning d, rv_low_value r FROM cg_ref_codes WHERE rv_domain = 'ALLOWED EXPORT' ORDER BY 2` | `P1120_IMPR_EXPR_TYPE` | Display Only based on LOV | |
| list item `SUSPN_RSN_CD` (`CG_REF_CODES` 'IMPR_SUSPN_RSN_CD') | **`LOV_IMPR_SUSPN_RSN_CD`** (new) | SQL | `SELECT rv_meaning d, rv_low_value r FROM cg_ref_codes WHERE rv_domain = 'IMPR_SUSPN_RSN_CD' ORDER BY 2` | IG `SUSPN_RSN_CD` | Select List | `CGDV$POPULATE_DYNAMIC_LISTS` |
| pop list `SUSPN_SIDE_CD` (`CG_REF_CODES` 'SUSPN SIDE CD') | **`LOV_SUSPN_SIDE_CD`** (new) | SQL | `SELECT rv_meaning d, rv_low_value r FROM cg_ref_codes WHERE rv_domain = 'SUSPN SIDE CD' ORDER BY 2` | IG `SUSPN_SIDE_CD` | Select List | `CGDV$POPULATE_DYNAMIC_LISTS` |
| `CGFK$IMPORTERS_IMPR_TYPE_CD`, `_CTRY_CD`, `_CITY_CODE_OF_ID`, `_HQ_IMPR_NBR`; LOV forms `LOV_Impr_Type`, `LOV_COUNTRIES`, `LOV_CITIES` | – | – | – | – | – | header items are display only; as criteria they are IG column filters on 112001 |

`ORDER BY 2` sorts by `RV_LOW_VALUE` as text, as the Forms record-group query did. The XML static list values (6 reasons, 7 sides) are replaced at runtime by these queries, as in Forms.

## 7. Validations

Error display: inline with field and in notification. All are *PL/SQL Function Body (returning Error Text)*, one call into `IMPR1120`.

| Validation | Level | Code | Associated | Condition | Source |
|---|---|---|---|---|---|
| `IMPR_NBR VALIDATION` | item | `return IMPR1120.IMPR_NBR_VALIDATION(P_PORT_CD => :P1120_PORT_CD, P_IMPR_NBR => :P1120_IMPR_NBR);` | `P1120_IMPR_NBR` | `:REQUEST IN ('EXECUTE_QUERY', 'CREATE')` | IMPORTERS.IMPR_NBR.WHEN-VALIDATE-ITEM |
| `IMPR_SUSPN SUSPN_STRT_DT VALIDATION` | IG row (Editable Region `IMPR_SUSPN`) | `return IMPR1120.SUSPN_STRT_DT_VALIDATION(SUSPN_STRT_DT => :SUSPN_STRT_DT, PORT_CD => :PORT_CD, IMPR_NBR => :IMPR_NBR, SUSPN_SEQ => :SUSPN_SEQ);` | `SUSPN_STRT_DT` | `:APEX$ROW_STATUS IN ('C', 'U')` | IMPR_SUSPN.SUSPN_STRT_DT.WHEN-VALIDATE-ITEM |
| `IMPR_SUSPN SUSPN_END_DT VALIDATION` | IG row | `return IMPR1120.SUSPN_END_DT_VALIDATION(SUSPN_STRT_DT => :SUSPN_STRT_DT, SUSPN_END_DT => :SUSPN_END_DT, PORT_CD => :PORT_CD, IMPR_NBR => :IMPR_NBR, SUSPN_SEQ => :SUSPN_SEQ);` | `SUSPN_END_DT` | same | IMPR_SUSPN.SUSPN_END_DT.WHEN-VALIDATE-ITEM |
| `IMPR_SUSPN SUSPN_RSN_CD VALIDATION` | IG row | `return IMPR1120.SUSPN_RSN_CD_VALIDATION(SUSPN_RSN_CD => :SUSPN_RSN_CD, P_CURRENT_SIDE => :P1120_P_CURRENT_SIDE, PORT_CD => :PORT_CD, IMPR_NBR => :IMPR_NBR, SUSPN_SEQ => :SUSPN_SEQ);` | `SUSPN_RSN_CD` | same | IMPR_SUSPN.SUSPN_RSN_CD.WHEN-VALIDATE-ITEM |
| `IMPR_SUSPN SUSPN_SIDE_CD VALIDATION` | IG row | `return IMPR1120.SUSPN_SIDE_CD_VALIDATION(SUSPN_SIDE_CD => :SUSPN_SIDE_CD, P_CURRENT_SIDE => :P1120_P_CURRENT_SIDE, P_CURR_PORT_CD => :P_CURR_PORT_CD, PORT_CD => :PORT_CD, IMPR_NBR => :IMPR_NBR, SUSPN_SEQ => :SUSPN_SEQ);` | `SUSPN_SIDE_CD` | same | IMPR_SUSPN.SUSPN_SIDE_CD.WHEN-LIST-CHANGED + WHEN-VALIDATE-ITEM |

The required columns (`SUSPN_STRT_DT`, `SUSPN_END_DT`, `SUSPN_RSN_TEXT`; Forms *Required* = Yes) use the IG column attribute *Value Required*. No package call is needed: it is the same static rule.

## 8. Processes

### Page 1120

f345 order (standard §6), error display inline in notification. Slot 50 `PARAMETERS ENTRY` is not used, because no caller passes parameters. Slot 90 `PRE-FORM` is not used either, because PRE-FORM only sets NLS, the help path and NIB (dropped).

| Point | Seq | Process | Code (one line) | Condition | Source |
|---|---|---|---|---|---|
| Before Header | 10 | `New` | f345 session setup, copied from AGR1100 / IMPR1110 | – | f345 §6 |
| Before Header | 20 | `P0_PAGE_PK CHECK` | `IMPR1120.P0_PAGE_PK_CHECK(P_PAGE_PK => :P0_PAGE_PK, P_CURR_PORT_CD => :P_CURR_PORT_CD);` | – | f345; PRE-QUERY port rule |
| Before Header | 40 | `PARAMETERS` | `:P1120_MODULE_ID := FORMS_APX.GET_MODULE_ID(P_MODULE_ID => :P1120_MODULE_ID, FORM_NAME => 'IMPR1120');` | – | f345 |
| Before Header | 45 | `PARAMETERS CURRENT_SIDE` | `:P1120_P_CURRENT_SIDE := IMPR1120.GET_CURRENT_SIDE(P_MODULE_ID => :P1120_MODULE_ID, P_CURR_PORT_CD => :P_CURR_PORT_CD);` | Item `P1120_P_CURRENT_SIDE` is null | parameter CURRENT_SIDE (launcher, SC_PORT_SETTING) |
| Before Header | 60 | `WHEN-NEW-FORM-INSTANCE` | `IMPR1120.INIT_FORM(P_CURRENT_SIDE => :P1120_P_CURRENT_SIDE, P_CURR_PORT_CD => :P_CURR_PORT_CD);` | – | FORM.WHEN-NEW-FORM-INSTANCE |
| Before Header | 70 | `P0_PAGE_PK` | `:P1120_ROW_ID := :P0_PAGE_PK;` | – | f345 (key = ROWID) |
| Before Header | 80 | `Initialize form IMPORTERS` | NATIVE_FORM_INIT, region `IMPORTERS` | – | block IMPORTERS fetch |
| Before Header | 82 | `POST-QUERY` | `IMPR1120.IMPORTERS_POST_QUERY(P_PORT_CD => :P1120_PORT_CD, P_IMPR_TYPE_CD => :P1120_IMPR_TYPE_CD, P_BUS_ID_TYPE_CD => :P1120_BUS_ID_TYPE_CD, P_CTRY_CD => :P1120_CTRY_CD, P_CTRY_CD_OF_ID => :P1120_CTRY_CD_OF_ID, P_CITY_CODE_OF_ID => :P1120_CITY_CODE_OF_ID, P_PORT_NAME => :P1120_PORT_NAME, P_IMPR_TYPE_NAME => :P1120_IMPR_TYPE_NAME, P_BUS_ID_TYPE_NAME => :P1120_BUS_ID_TYPE_NAME, P_CRTY_ARBC_NAME => :P1120_CRTY_ARBC_NAME, P_ID_CITY_NAME => :P1120_ID_CITY_NAME);` | Item `P1120_ROW_ID` is not null | IMPORTERS.POST-QUERY |
| Before Header | 84 | `IMPORTERS WHEN-CREATE-RECORD` | `IMPR1120.IMPORTERS_WHEN_CREATE_RECORD(P_CURR_PORT_CD => :P_CURR_PORT_CD, P_PORT_CD => :P1120_PORT_CD, P_PORT_NAME => :P1120_PORT_NAME);` | Item `P1120_ROW_ID` is null **and** `P1120_PORT_CD` is null | IMPORTERS.WHEN-CREATE-RECORD (the second condition keeps a port 99 user's chosen port after a failed validation) |
| Before Header | 100 | `HEADER TITLE` | `FORMS_APX.HEADER_TITLE(P_MODULE_ID => :P1120_MODULE_ID, P_HERO_TITLE => :P1120_HERO_TITLE, DEFAULT_TITLE => 'صيانة توقيفات المستوردين');` | – | f345 (OLB block TITLE) |
| After Submit | 10 | `EXECUTE-QUERY` | `IMPR1120.IMPR_NBR_WHEN_VALIDATE_ITEM(P_PORT_CD => :P1120_PORT_CD, P_IMPR_NBR => :P1120_IMPR_NBR, P_PAGE_PK => :P0_PAGE_PK);` | `:REQUEST IN ('EXECUTE_QUERY', 'CREATE')` | IMPR_NBR.WHEN-VALIDATE-ITEM → Exec_Query_Now → EXECUTE_QUERY |
| After Submit | 30 | `PRE-DELETE` | `IMPR1120.PRE_DELETE;` | `:REQUEST = 'DELETE'` | block IMPORTERS Delete Allowed = No |
| After Submit | 110 | `IMPR_SUSPN - Save Interactive Grid Data` | NATIVE_IG_DML, Editable Region `IMPR_SUSPN`, Target Type **PL/SQL Code**: `IMPR1120.IMPR_SUSPN_SAVE_ROW(APEX$ROW_STATUS => :APEX$ROW_STATUS, PORT_CD => NVL(:PORT_CD, :P1120_PORT_CD), IMPR_NBR => NVL(:IMPR_NBR, :P1120_IMPR_NBR), SUSPN_SEQ => :SUSPN_SEQ, SUSPN_STRT_DT => :SUSPN_STRT_DT, SUSPN_END_DT => :SUSPN_END_DT, SUSPN_RSN_CD => :SUSPN_RSN_CD, SUSPN_RSN_TEXT => :SUSPN_RSN_TEXT, SUSPN_SIDE_CD => :SUSPN_SIDE_CD, P_HQ_IMPR_NBR => :P1120_HQ_IMPR_NBR, P_PORT_NAME => :P1120_PORT_NAME, P_BUS_ID => :P1120_BUS_ID, P_CURRENT_SIDE => :P1120_P_CURRENT_SIDE, P_CURR_PORT_CD => :P_CURR_PORT_CD, SSO_APP_USER => :SSO_APP_USER, P_GLOBAL_V_WS_ID => :P_GLOBAL_V_WS_ID);` | `:REQUEST = 'SAVE'` | Forms transaction processing of IMPR_SUSPN: PRE-INSERT, POST-INSERT, PRE-UPDATE, ON-DELETE (§0 #4) |

- **Success message** of process 110: the f345 save message, as on IMPR1110. Forms showed FRM-40400 through `NIB.ON_MESSAGE`.
- **Branch:** after processing → page 1120 (f345 default). Request `EXECUTE_QUERY` also clears the cache of page 1120, so the old record's names are not kept. `P1120_MODULE_ID` and `P1120_P_CURRENT_SIDE` are cleared too, and Before Header processes 40 / 45 compute them again.

### Page 112001

| Point | Seq | Process | Code | Condition | Source |
|---|---|---|---|---|---|
| – | – | none | The `01` page needs no `G_LAST_PAGE KEEP` (SCREEN ENTRY RESET keeps the record between 1120 and 112001) | – | f345 §4 |

## 9. Computations

| Item | Point | Type | Expression | Condition | Source |
|---|---|---|---|---|---|
| – | – | – | – | – | PRE-QUERY port (`:IMPORTERS.PORT_CD := :PARAMETER.P_CURR_PORT_CD`) is applied in the region SQL; no computation on 112001 |

The IG column defaults are listed in §4.3. No other computation is needed.

## 10. Dynamic Actions

All server calls use **FOS – Execute PL/SQL Code** (`COM.FOS.EXECUTE_PLSQL_CODE`) with `p_attribute_05 => '#SQLERRM#'`, `p_attribute_15 => 'suppressChangeEvent:escape-message'` and `p_wait_for_result => 'Y'` (f345 standard §9). An error stops the remaining actions.

| DA | Page | Event / selection | Action 1 | Action 2 | Items to Submit / Return | Fire on init | Source |
|---|---|---|---|---|---|---|---|
| `IMPR_NBR WHEN-VALIDATE-ITEM` | 1120 | Change, item `P1120_IMPR_NBR`; client condition item is not null | FOS `FORMS_APX.CHECK_ERROR(IMPR1120.IMPR_NBR_VALIDATION(P_PORT_CD => :P1120_PORT_CD, P_IMPR_NBR => :P1120_IMPR_NBR));` | native Submit Page, request `EXECUTE_QUERY` | Submit `P1120_PORT_CD`, `P1120_IMPR_NBR` | No | IMPR_NBR WVI + IMPR_TYPE_CD WNII (EXECUTE_QUERY) |
| `IMPR_SUSPN SUSPN_STRT_DT WHEN-VALIDATE-ITEM` | 1120 | Change, column `SUSPN_STRT_DT` of IG `IMPR_SUSPN` | FOS `FORMS_APX.CHECK_ERROR(IMPR1120.SUSPN_STRT_DT_VALIDATION(SUSPN_STRT_DT => :SUSPN_STRT_DT, PORT_CD => :PORT_CD, IMPR_NBR => :IMPR_NBR, SUSPN_SEQ => :SUSPN_SEQ));` | – | Submit `SUSPN_STRT_DT`, `PORT_CD`, `IMPR_NBR`, `SUSPN_SEQ` | No | SUSPN_STRT_DT WVI |
| `IMPR_SUSPN SUSPN_END_DT WHEN-VALIDATE-ITEM` | 1120 | Change, column `SUSPN_END_DT` | FOS `FORMS_APX.CHECK_ERROR(IMPR1120.SUSPN_END_DT_VALIDATION(SUSPN_STRT_DT => :SUSPN_STRT_DT, SUSPN_END_DT => :SUSPN_END_DT, PORT_CD => :PORT_CD, IMPR_NBR => :IMPR_NBR, SUSPN_SEQ => :SUSPN_SEQ));` | – | Submit `SUSPN_STRT_DT`, `SUSPN_END_DT`, `PORT_CD`, `IMPR_NBR`, `SUSPN_SEQ` | No | SUSPN_END_DT WVI |
| `IMPR_SUSPN SUSPN_RSN_CD WHEN-VALIDATE-ITEM` | 1120 | Change, column `SUSPN_RSN_CD` | FOS `IMPR1120.SUSPN_RSN_CD_VALIDATE_ITEM(SUSPN_RSN_CD => :SUSPN_RSN_CD, P_CURRENT_SIDE => :P1120_P_CURRENT_SIDE, PORT_CD => :PORT_CD, IMPR_NBR => :IMPR_NBR, SUSPN_SEQ => :SUSPN_SEQ, SUSPN_RSN_TEXT => :SUSPN_RSN_TEXT);` | – | Submit `SUSPN_RSN_CD`, `P1120_P_CURRENT_SIDE`, `PORT_CD`, `IMPR_NBR`, `SUSPN_SEQ`; Return `SUSPN_RSN_TEXT` | No | SUSPN_RSN_CD WVI |
| `IMPR_SUSPN SUSPN_SIDE_CD WHEN-LIST-CHANGED` | 1120 | Change, column `SUSPN_SIDE_CD` | FOS `FORMS_APX.CHECK_ERROR(IMPR1120.SUSPN_SIDE_CD_VALIDATION(SUSPN_SIDE_CD => :SUSPN_SIDE_CD, P_CURRENT_SIDE => :P1120_P_CURRENT_SIDE, P_CURR_PORT_CD => :P_CURR_PORT_CD, PORT_CD => :PORT_CD, IMPR_NBR => :IMPR_NBR, SUSPN_SEQ => :SUSPN_SEQ));` | – | Submit `SUSPN_SIDE_CD`, `P1120_P_CURRENT_SIDE`, `PORT_CD`, `IMPR_NBR`, `SUSPN_SEQ` | No | SUSPN_SIDE_CD WLC |
| `SEARCH WHEN-BUTTON-PRESSED` | 112001 | Click, button `SEARCH` | native Refresh, region `IMPORTERS_SEARCH` | – | – | No | TOOLBAR.EXECUTE |
| `SEARCH KEY-ENTER` | 112001 | Key Up, item `P112001_SEARCH`; client condition JavaScript expression `this.browserEvent.which === 13` (Enter) | native Refresh, region `IMPORTERS_SEARCH` | – | – | No | KEY-EXEQRY; f345 AGR1100_SEARCH `SEARCH REFRESH` (keyup) |
| `CLEAR WHEN-BUTTON-PRESSED` | 112001 | Click, button `CLEAR` | native Clear, item `P112001_SEARCH` | native Refresh, region `IMPORTERS_SEARCH` (empty again) | – | No | TOOLBAR.CLEAR_ALL (criteria) |

**Not built:**
- the Forms resets of a rejected value (start date → today, reason / side → the site's default; §16 #9);
- `GO_ITEM` (the grid starts on its first column);
- a delete confirmation: deleted grid rows stay visible (struck through) and can be restored until SAVE, which plays the role of the Forms question "هل أنت متأكد من عملية الحذف" (§16 #10).

**Execute JavaScript Code actions: 0.**

## 11. Alerts and messages

| Forms alert / message | Usage | APEX equivalent | Text |
|---|---|---|---|
| `CFG_ERROR` (`STR.DispArbMsg … 'ERROR'`) | 9-100 start date, 9-110 end date | validation error text (`arabic_message`, `STR_DB.GetArbMsg`) | from the message table (MISSING SOURCE STR_DB) |
| `CFG_INFORMATION` (`DispArbMsg … 'INFORMATION'` + FTF) | 9-150 importer not in the port | `IMPR_NBR VALIDATION` error | from the message table |
| `CFG_SYSTEM_ERROR` (`ACTIVITY` / `HIJDATE` failures) | activity log, current Hijri date | `FORMS_APX.FORM_TRIGGER_FAILURE(<text from ACTIVITY_DB / HIJDATE_DB>)` | from the DB packages |
| `USR_WARNING_B` (`TMPLT.KEY_DELETE_RECORD`) | delete confirmation | IG row delete, undone until SAVE (§10) | 'هل أنت متأكد من عملية الحذف' |
| MESSAGE + EXIT_FORM (WNFI) | site 3 outside port 99 | `INIT_FORM` error, page not shown | 'ليس لديك الصلاحية للدخول على الشاشة' |
| FRM-41049 (block Delete Allowed = No) | page 0 DELETE | `PRE_DELETE` error | 'لا يمكن حذف بيانات المستورد من هذه الشاشة - احذف التوقيف من الجدول' (to confirm) |
| ON-ERROR `IS_1_IMP_FK` (ORA-02291) | parent key not found | **Text Message `IS_1_IMP_FK`** via `APP_ERROR_HANDLER` | 'بيانات الربط مع ملف المستوردين غير صحيحة - أعد إدخال البيانات' |
| (none in Forms) | rejected reason / side / other-site row | package constants (extraction §5) | placeholders to agree |
| other OLB alerts (`USR_CONFIRM*`, `USR_WARNING_C`, `CFG_WARNING_A`, `CFG_ASK_COMMIT`, `CG$ASK_COMMIT`) | not used by IMPR1120 code | – | – |

## 12. Branches and navigation

| Branch / link | Point | Target | Condition | Items set | Forms source |
|---|---|---|---|---|---|
| after processing | After Processing | 1120 | always (request EXECUTE_QUERY: clear cache 1120) | – | Forms stays in the form |
| page 0 SEARCH | – | 112001 (dialog) | `P0_PAGE_PK` is null | – | ENTER / EXECUTE (toolbar), KEY-ENTQRY / KEY-EXEQRY |
| link column `IMPR_NBR` on 112001 | – | 1120 | – | `P0_PAGE_PK = &ROW_ID.` (checksum) | query result |
| page 0 FUNCS | – | inline dialog `FUNCS` | – | – | LSIDE / KEY-F9 |

## 13. Shared components

### 13.1 Reused from f345 (do not create)

Theme 42 / style ZATCA Forms, page 0 (`P0_ACTIONS`, `P0_PAGE_PK`, `P0_SEARCH_URL`), application items `SSO_APP_USER`, `P_CURR_PORT_CD`, `P_PORT_TYPE`, `P_GLOBAL_V_WS_ID`, `SYS_ANAME`, app process `SCREEN ENTRY RESET`, `APP_ERROR_HANDLER`, plug-in `COM.FOS.EXECUTE_PLSQL_CODE`, list *Page Functions*, the app-wide Hijri picker class `hijri-date-default`.

### 13.2 Reused from the IMPR1110 export (already in application 202530)

`LOV_SD_PORTS`, `LOV_ALLOWED_EXPORT`. If IMPR1110 is not installed in the target, create them with the SQL in §6.

### 13.3 New

| Component | Name | Content |
|---|---|---|
| Shared LOV | `LOV_IMPR_SUSPN_RSN_CD` | §6 |
| Shared LOV | `LOV_SUSPN_SIDE_CD` | §6 |
| Text Message | `IS_1_IMP_FK` | §11 |
| Application items | none | `CURRENT_SIDE` is a page item (not passed between pages); no `:GLOBAL` survives |

## 14. Traceability matrix (every object of the XML)

<!-- TRACE -->

## 15. Registry script

`registry/IMPR1120_registry.sql` (generated with §14) contains:
- the `MIG_FORM_REGISTRY` row: app 202530, pages 1120–1120, alias and package `IMPR1120`, COMPLEX, status DESIGN;
- one `MIG_OBJECT_MAP` row per object of §14.

It deletes the form's rows first, so it can be re-run, and ends with COMMIT. **Not executed** (CLAUDE.md §6.10).

## 16. Changes made to step-02 code during this step, open items

Package `IMPR1120` 001 → **002** (001 kept in `rollback/IMPR1120/step02_v001/`):

1. **Dates as text.** The date parameters are `VARCHAR2` in the format `HIJRI_DATE_FORMAT` (package 008: Application Setting, default `YYYY-MM-MI`; was the Forms mask `MI-MM-RRRR`). Private helpers `hijri_text_to_date` / `hijri_text` convert them (no calendar conversion: the text is already Hijri); a wrong format gives the FRM-50026 equivalent in the format of the setting (e.g. سنة-شهر-يوم (YYYY-MM-MI); Arabic text to confirm). `SUSPN_STRT_DT_DEFAULT` returns text.
2. **Validations skip unchanged values.** The four column validations (and `SUSPN_RSN_CD_VALIDATE_ITEM`) take the row key and skip a value equal to the stored one (private `stored_suspension`, §0 #7).
3. **New `PRE_DELETE`** refuses the page 0 DELETE of the importer.
4. **New `IMPR_SUSPN_SAVE_ROW`** does the grid DML per row (§0 #4).
5. **New `SUSPN_RSN_TEXT_DEFAULT`.** In Forms the default reason's text was filled when the cursor left the reason item; a grid default fires no change event.

Open items for step 04 / 05 (beyond the inventory §15 questions):

| # | Item | Level |
|---|---|---|
| 6 | *Prevent Lost Updates* with IG Target Type PL/SQL Code: confirm that APEX 21.2 still compares the row checksum. If not, the UPDATE in `IMPR_SUSPN_SAVE_ROW` has no lost-update check (Forms locked the row) | Medium |
| 7 | IG column Read Only *For Each Row* for rows added in the browser: confirm that new rows stay editable (side code empty → not read only) | Low |
| 8 | `LOV_SD_PORTS` filters `port_status = 1`. In Enter-Query, Forms called `LOV_SD_PORTS` without STATUS. Check the LOV form's default before reusing the IMPR1110 LOV for the search page | Low |
| 9 | Rejected values are not reset (start date → today, reason / side → the site default); the user corrects them | Low |
| 10 | No delete confirmation (rows can be restored until SAVE). If one is required, it needs a confirm before page 0 SAVE (the 3-line JavaScript case of standard §9) | Low |
| 11 | Popup LOV *Additional Outputs* for `PORT_NAME`: confirm that the attribute exists in 21.2. Otherwise the name stays empty until the record is queried (Display Only, cosmetic) | Low |
| 12 | Text of the FRM-41049 and FRM-50026 equivalents and of the three package placeholders (extraction §5) | Medium |
| 13 | HIGH items carried over: COMMIT removed from POST-INSERT (notification sent inside the save); source of `CURRENT_SIDE` (extraction §8 #1, #2) | High |
| 14 | Done in packages 003–005 (step 04, user requests): parameters are named after their binds without `I_` / `IO_` / `O_`; a page item is passed as `P_<ITEM>` (`P_PORT_CD => :P1120_PORT_CD`, `P_PAGE_PK => :P0_PAGE_PK`, `P_CURRENT_SIDE => :P1120_P_CURRENT_SIDE`), IG columns by their name (`PORT_CD => :PORT_CD`); inside SQL they are qualified with the member name. CLAUDE.md §4, `docs/f345_reference_standard.md` §5 and the templates now state this rule (`scripts/parameter_names.py`) | – |
