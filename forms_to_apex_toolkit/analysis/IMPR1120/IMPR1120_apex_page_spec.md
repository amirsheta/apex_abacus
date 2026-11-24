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
| `P1120_IMPR_NBR` | IMPR_NBR | Number Field, CSS class `number_only` | الرقم الجمركى | Item `P0_PAGE_PK` is not null | – | 11 | `IMPORTERS.IMPR_NBR` |
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
| `NUMBER ONLY` | 1120 | Page Load | *Execute JavaScript Code* (1 line, `scripts/number_only.py`): one delegated `input` handler for `.number_only` keeps only digits (Arabic-Indic / Persian digits become 0-9); Fire on Initialization = Yes | – | – | No | Forms NUMBER item (user request 2026-11-24) |
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

515 objects: DROPPED 396, MAPPED 117, TODO 2. By type: ALERT 10, BLOCK 6, CALLED_FORM 6, CANVAS 5, GLOBAL 17, ITEM 117, LIBRARY 17, LOV 5, PARAMETER 22, PROGRAM_UNIT 33, RECORD_GROUP 6, RELATION 1, TRIGGER 269, WINDOW 1.

| # | Type | Forms object | APEX component | Page | Package member | Status | Notes |
|---|---|---|---|---|---|---|---|
| 1 | BLOCK | `TITLE` | IMPORTERS_HERO | 1120 | IMPR1120.HEADER_TITLE | MAPPED | OLB title bar -> hero region (HEADER TITLE) |
| 2 | BLOCK | `EDI_MSG` | – | – | – | DROPPED | OLB EDI message ticker - dropped (timers, IMPR1110 decision 2026-11-19) |
| 3 | BLOCK | `LSIDE` | FUNCS | 1120 | – | MAPPED | OLB side function menu -> inline dialog FUNCS, f345 list Page Functions |
| 4 | BLOCK | `TOOLBAR` | P0_ACTIONS (page 0 toolbar, f345) | 0 | – | MAPPED | OLB toolbar -> f345 page 0 toolbar |
| 5 | BLOCK | `IMPORTERS` | IMPORTERS (Form region, table IMPORTERS, primary key ROWID, read only) | 1120 | – | MAPPED | master, query only; search page 112001 = Enter / Execute Query |
| 6 | BLOCK | `IMPR_SUSPN` | IMPR_SUSPN (editable Interactive Grid on IMPR_SUSPNS) | 1120 | IMPR1120.IMPR_SUSPN_SAVE_ROW | MAPPED | detail; WHERE SUSPN_RLSE_DT IS NULL; DML through IMPR_SUSPN_SAVE_ROW (soft delete) |
| 7 | ITEM | `TITLE.CGSO$CHECK_BOX_U` | – | – | – | DROPPED | OLB block TITLE |
| 8 | ITEM | `TITLE.CGSO$CHAR_ARB_ED` | – | – | – | DROPPED | OLB block TITLE |
| 9 | ITEM | `TITLE.CGSO$CHAR_ARB_DO_MLINE` | – | – | – | DROPPED | OLB block TITLE |
| 10 | ITEM | `TITLE.CGSO$CHAR_ARB_ORA_LOV` | – | – | – | DROPPED | OLB block TITLE |
| 11 | ITEM | `TITLE.CGSO$CHAR_ARB_DO_ENB_Y` | – | – | – | DROPPED | OLB block TITLE |
| 12 | ITEM | `TITLE.CGSO$CHAR_ARB_MLINE` | – | – | – | DROPPED | OLB block TITLE |
| 13 | ITEM | `TITLE.CGSO$CHAR_ARB` | – | – | – | DROPPED | OLB block TITLE |
| 14 | ITEM | `TITLE.CGSO$CHAR_ARB_DO` | – | – | – | DROPPED | OLB block TITLE |
| 15 | ITEM | `TITLE.SCREEN_NAME` | – | – | – | DROPPED | OLB block TITLE |
| 16 | ITEM | `TITLE.USER_NAME` | – | – | – | DROPPED | OLB block TITLE |
| 17 | ITEM | `TITLE.SYSTEM_DATE` | – | – | – | DROPPED | OLB block TITLE |
| 18 | ITEM | `TITLE.VERSION` | – | – | – | DROPPED | OLB block TITLE |
| 19 | ITEM | `EDI_MSG.EDI_MSG_TXT` | – | – | – | DROPPED | OLB block EDI_MSG |
| 20 | ITEM | `EDI_MSG.EDI_MSG_LOVE_BUT` | – | – | – | DROPPED | OLB block EDI_MSG |
| 21 | ITEM | `LSIDE.FN1` | – | – | – | DROPPED | OLB block LSIDE |
| 22 | ITEM | `LSIDE.FN50` | – | – | – | DROPPED | OLB block LSIDE |
| 23 | ITEM | `LSIDE.FN2` | – | – | – | DROPPED | OLB block LSIDE |
| 24 | ITEM | `LSIDE.FN49` | – | – | – | DROPPED | OLB block LSIDE |
| 25 | ITEM | `LSIDE.FN3` | – | – | – | DROPPED | OLB block LSIDE |
| 26 | ITEM | `LSIDE.FN48` | – | – | – | DROPPED | OLB block LSIDE |
| 27 | ITEM | `LSIDE.FN4` | – | – | – | DROPPED | OLB block LSIDE |
| 28 | ITEM | `LSIDE.FN47` | – | – | – | DROPPED | OLB block LSIDE |
| 29 | ITEM | `LSIDE.FN5` | – | – | – | DROPPED | OLB block LSIDE |
| 30 | ITEM | `LSIDE.FN46` | – | – | – | DROPPED | OLB block LSIDE |
| 31 | ITEM | `LSIDE.FN6` | – | – | – | DROPPED | OLB block LSIDE |
| 32 | ITEM | `LSIDE.FN45` | – | – | – | DROPPED | OLB block LSIDE |
| 33 | ITEM | `LSIDE.FN7` | – | – | – | DROPPED | OLB block LSIDE |
| 34 | ITEM | `LSIDE.FN44` | – | – | – | DROPPED | OLB block LSIDE |
| 35 | ITEM | `LSIDE.FN8` | – | – | – | DROPPED | OLB block LSIDE |
| 36 | ITEM | `LSIDE.FN43` | – | – | – | DROPPED | OLB block LSIDE |
| 37 | ITEM | `LSIDE.FN9` | – | – | – | DROPPED | OLB block LSIDE |
| 38 | ITEM | `LSIDE.FN42` | – | – | – | DROPPED | OLB block LSIDE |
| 39 | ITEM | `LSIDE.FN10` | – | – | – | DROPPED | OLB block LSIDE |
| 40 | ITEM | `LSIDE.FN41` | – | – | – | DROPPED | OLB block LSIDE |
| 41 | ITEM | `LSIDE.FN11` | – | – | – | DROPPED | OLB block LSIDE |
| 42 | ITEM | `LSIDE.FN40` | – | – | – | DROPPED | OLB block LSIDE |
| 43 | ITEM | `LSIDE.FN12` | – | – | – | DROPPED | OLB block LSIDE |
| 44 | ITEM | `LSIDE.FN39` | – | – | – | DROPPED | OLB block LSIDE |
| 45 | ITEM | `LSIDE.FN13` | – | – | – | DROPPED | OLB block LSIDE |
| 46 | ITEM | `LSIDE.FN38` | – | – | – | DROPPED | OLB block LSIDE |
| 47 | ITEM | `LSIDE.FN14` | – | – | – | DROPPED | OLB block LSIDE |
| 48 | ITEM | `LSIDE.FN37` | – | – | – | DROPPED | OLB block LSIDE |
| 49 | ITEM | `LSIDE.FN15` | – | – | – | DROPPED | OLB block LSIDE |
| 50 | ITEM | `LSIDE.FN36` | – | – | – | DROPPED | OLB block LSIDE |
| 51 | ITEM | `LSIDE.FN16` | – | – | – | DROPPED | OLB block LSIDE |
| 52 | ITEM | `LSIDE.FN17` | – | – | – | DROPPED | OLB block LSIDE |
| 53 | ITEM | `LSIDE.FN34` | – | – | – | DROPPED | OLB block LSIDE |
| 54 | ITEM | `LSIDE.FN35` | – | – | – | DROPPED | OLB block LSIDE |
| 55 | ITEM | `LSIDE.FN18` | – | – | – | DROPPED | OLB block LSIDE |
| 56 | ITEM | `LSIDE.FN33` | – | – | – | DROPPED | OLB block LSIDE |
| 57 | ITEM | `LSIDE.FN19` | – | – | – | DROPPED | OLB block LSIDE |
| 58 | ITEM | `LSIDE.FN32` | – | – | – | DROPPED | OLB block LSIDE |
| 59 | ITEM | `LSIDE.FN20` | – | – | – | DROPPED | OLB block LSIDE |
| 60 | ITEM | `LSIDE.FN31` | – | – | – | DROPPED | OLB block LSIDE |
| 61 | ITEM | `LSIDE.FN21` | – | – | – | DROPPED | OLB block LSIDE |
| 62 | ITEM | `LSIDE.FN30` | – | – | – | DROPPED | OLB block LSIDE |
| 63 | ITEM | `LSIDE.FN22` | – | – | – | DROPPED | OLB block LSIDE |
| 64 | ITEM | `LSIDE.FN29` | – | – | – | DROPPED | OLB block LSIDE |
| 65 | ITEM | `LSIDE.FN23` | – | – | – | DROPPED | OLB block LSIDE |
| 66 | ITEM | `LSIDE.FN28` | – | – | – | DROPPED | OLB block LSIDE |
| 67 | ITEM | `LSIDE.FN24` | – | – | – | DROPPED | OLB block LSIDE |
| 68 | ITEM | `LSIDE.FN27` | – | – | – | DROPPED | OLB block LSIDE |
| 69 | ITEM | `LSIDE.FN25` | – | – | – | DROPPED | OLB block LSIDE |
| 70 | ITEM | `LSIDE.FN26` | – | – | – | DROPPED | OLB block LSIDE |
| 71 | ITEM | `TOOLBAR.DUMMY` | – | – | – | DROPPED | OLB toolbar item (record navigation / frame) |
| 72 | ITEM | `TOOLBAR.SAVE` | SAVE (page 0 toolbar) | 0 | – | MAPPED | saves the grid (request SAVE) |
| 73 | ITEM | `TOOLBAR.CLEAR_ALL` | CLEAR (page 0 toolbar) | 0 | – | MAPPED | – |
| 74 | ITEM | `TOOLBAR.EXIT` | BACK (page 0 toolbar) | 0 | – | MAPPED | – |
| 75 | ITEM | `TOOLBAR.EXIT1` | BACK (page 0 toolbar) | 0 | – | MAPPED | leave Enter-Query mode -> no query mode in APEX |
| 76 | ITEM | `TOOLBAR.ENTER` | SEARCH (page 0 toolbar) | 0 | – | MAPPED | Enter Query -> search page 112001 |
| 77 | ITEM | `TOOLBAR.EXECUTE` | SEARCH (page 0 toolbar) | 0 | – | MAPPED | Execute Query -> search page 112001 |
| 78 | ITEM | `TOOLBAR.REMOVE` | DELETE (page 0 toolbar) / IG row delete | 0 | – | MAPPED | importer: refused by PRE-DELETE (Delete Allowed = No); suspension: IG row delete |
| 79 | ITEM | `TOOLBAR.LIST_VALUE` | – | – | – | DROPPED | popup LOV icon of the item |
| 80 | ITEM | `TOOLBAR.HELP` | – | – | – | DROPPED | MS-Help obsolete |
| 81 | ITEM | `TOOLBAR.LAST_REC` | – | – | – | DROPPED | OLB toolbar item (record navigation / frame) |
| 82 | ITEM | `TOOLBAR.RE_ENTER_QUERY` | SEARCH (page 0 toolbar) | 0 | – | MAPPED | – |
| 83 | ITEM | `TOOLBAR.FIRST_REC` | – | – | – | DROPPED | OLB toolbar item (record navigation / frame) |
| 84 | ITEM | `TOOLBAR.PAGE_UP` | – | – | – | DROPPED | OLB toolbar item (record navigation / frame) |
| 85 | ITEM | `TOOLBAR.PAGE_DOWN` | – | – | – | DROPPED | OLB toolbar item (record navigation / frame) |
| 86 | ITEM | `TOOLBAR.FUN_BUT` | FUNCS (page 0 toolbar) | 0 | – | MAPPED | – |
| 87 | ITEM | `IMPORTERS.PORT_CD` | P1120_PORT_CD | 1120 | – | MAPPED | Popup LOV LOV_SD_PORTS, read only unless port 99 and no record (PORT_CD_IS_READ_ONLY) |
| 88 | ITEM | `IMPORTERS.PORT_CD2` | – | – | – | DROPPED | LOV button -> popup LOV icon |
| 89 | ITEM | `IMPORTERS.PORT_NAME` | P1120_PORT_NAME | 1120 | – | MAPPED | Display Only (POST-QUERY / WHEN-CREATE-RECORD / LOV additional output) |
| 90 | ITEM | `IMPORTERS.HQ_IMPR_NBR` | P1120_HQ_IMPR_NBR | 1120 | – | MAPPED | Display Only |
| 91 | ITEM | `IMPORTERS.IMPR_NBR` | P1120_IMPR_NBR | 1120 | – | MAPPED | Number Field, editable only while P0_PAGE_PK is null (entry of the importer) |
| 92 | ITEM | `IMPORTERS.SDP_PORT_STATUS` | – | – | – | DROPPED | hidden lookup status, read nowhere |
| 93 | ITEM | `IMPORTERS.IMPR_TYPE_CD` | P1120_IMPR_TYPE_CD | 1120 | – | MAPPED | Display Only |
| 94 | ITEM | `IMPORTERS.IMPR_TYPE_CD2` | – | – | – | DROPPED | LOV button (item is display only) |
| 95 | ITEM | `IMPORTERS.IMPR_TYPE_NAME` | P1120_IMPR_TYPE_NAME | 1120 | – | MAPPED | Display Only (POST-QUERY) |
| 96 | ITEM | `IMPORTERS.CTRY_CD` | P1120_CTRY_CD | 1120 | – | MAPPED | Display Only |
| 97 | ITEM | `IMPORTERS.CTRY_CD2` | – | – | – | DROPPED | LOV button (item is display only) |
| 98 | ITEM | `IMPORTERS.CRTY_ARBC_NAME` | P1120_CRTY_ARBC_NAME | 1120 | – | MAPPED | Display Only (POST-QUERY) |
| 99 | ITEM | `IMPORTERS.CITY_CODE_OF_ID` | P1120_CITY_CODE_OF_ID | 1120 | – | MAPPED | Display Only |
| 100 | ITEM | `IMPORTERS.CITY_CODE_OF_ID2` | – | – | – | DROPPED | LOV button (item is display only) |
| 101 | ITEM | `IMPORTERS.ID_CITY_NAME` | P1120_ID_CITY_NAME | 1120 | – | MAPPED | Display Only (POST-QUERY) |
| 102 | ITEM | `IMPORTERS.IMPR_EXPR_TYPE` | P1120_IMPR_EXPR_TYPE | 1120 | – | MAPPED | Display Only, LOV_ALLOWED_EXPORT |
| 103 | ITEM | `IMPORTERS.BUS_ID` | P1120_BUS_ID | 1120 | – | MAPPED | Display Only |
| 104 | ITEM | `IMPORTERS.BUS_ID_TYPE_CD` | P1120_BUS_ID_TYPE_CD | 1120 | – | MAPPED | Display Only |
| 105 | ITEM | `IMPORTERS.BUTT` | – | – | – | DROPPED | LOV button of BUS_ID_TYPE_CD (item is display only) |
| 106 | ITEM | `IMPORTERS.BUS_ID_TYPE_NAME` | P1120_BUS_ID_TYPE_NAME | 1120 | – | MAPPED | Display Only (POST-QUERY) |
| 107 | ITEM | `IMPORTERS.BUS_ID_BRNCH` | P1120_BUS_ID_BRNCH | 1120 | – | MAPPED | Display Only |
| 108 | ITEM | `IMPORTERS.CTRY_CTRY_STATUS` | – | – | – | DROPPED | hidden lookup status, read nowhere |
| 109 | ITEM | `IMPORTERS.STATUS` | – | – | – | DROPPED | hidden lookup status, read nowhere |
| 110 | ITEM | `IMPORTERS.ARBC_IMPR_NAME` | P1120_ARBC_IMPR_NAME | 1120 | – | MAPPED | Display Only |
| 111 | ITEM | `IMPORTERS.ENG_IMPR_NAME` | P1120_ENG_IMPR_NAME | 1120 | – | MAPPED | Display Only |
| 112 | ITEM | `IMPORTERS.IMPR_CNTCT_NAME` | P1120_IMPR_CNTCT_NAME | 1120 | – | MAPPED | Display Only |
| 113 | ITEM | `IMPORTERS.IMPR_NAME_STD` | search filter on IMPR_NAME_STD (page 112001 SQL) | 112001 | IMPR1120.IMPORTERS_PRE_QUERY_NAME_STD | MAPPED | standardised Arabic name, query only |
| 114 | ITEM | `IMPORTERS.CTRY_CD_OF_ID` | P1120_CTRY_CD_OF_ID | 1120 | – | MAPPED | Hidden (Value Protected) - input of the POST-QUERY city lookup |
| 115 | ITEM | `IMPR_SUSPN.SUSPN_STRT_DT` | IMPR_SUSPN.SUSPN_STRT_DT | 1120 | – | MAPPED | Text Field (HIJRI_DATE_FORMAT, default YYYY-MM-MI, hijri-date-default), required, default SUSPN_STRT_DT_DEFAULT |
| 116 | ITEM | `IMPR_SUSPN.SUSPN_END_DT` | IMPR_SUSPN.SUSPN_END_DT | 1120 | – | MAPPED | Text Field (HIJRI_DATE_FORMAT, default YYYY-MM-MI, hijri-date-default), required |
| 117 | ITEM | `IMPR_SUSPN.SUSPN_SEQ` | IMPR_SUSPN.SUSPN_SEQ | 1120 | – | MAPPED | Hidden, primary key (set by IMPR_SUSPN_PRE_INSERT) |
| 118 | ITEM | `IMPR_SUSPN.SUSPN_RSN_CD` | IMPR_SUSPN.SUSPN_RSN_CD | 1120 | – | MAPPED | Select List LOV_IMPR_SUSPN_RSN_CD, default SUSPN_RSN_CD_DEFAULT |
| 119 | ITEM | `IMPR_SUSPN.SUSPN_RSN_TEXT` | IMPR_SUSPN.SUSPN_RSN_TEXT | 1120 | – | MAPPED | Text Field, required, default SUSPN_RSN_TEXT_DEFAULT |
| 120 | ITEM | `IMPR_SUSPN.SUSPN_SIDE_CD` | IMPR_SUSPN.SUSPN_SIDE_CD | 1120 | – | MAPPED | Select List LOV_SUSPN_SIDE_CD, default SUSPN_SIDE_CD_DEFAULT, read only once stored |
| 121 | ITEM | `IMPR_SUSPN.SUSPN_RLSE_DT` | – | – | IMPR1120.IMPR_SUSPN_SAVE_ROW | MAPPED | not a grid column: set by IMPR_SUSPN_PRE_UPDATE / IMPR_SUSPN_ON_DELETE; region WHERE SUSPN_RLSE_DT IS NULL |
| 122 | ITEM | `IMPR_SUSPN.IMPR_NBR` | IMPR_SUSPN.IMPR_NBR | 1120 | – | MAPPED | Hidden, primary key (default = master item P1120_IMPR_NBR; save call NVL(:IMPR_NBR, :P1120_IMPR_NBR)) |
| 123 | ITEM | `IMPR_SUSPN.PORT_CD` | IMPR_SUSPN.PORT_CD | 1120 | – | MAPPED | Hidden, primary key (default = master item P1120_PORT_CD; save call NVL(:PORT_CD, :P1120_PORT_CD)) |
| 124 | TRIGGER | `FORM.KEY-EDIT` | – | – | – | DROPPED | NIB.KEY_EDIT -> page 0 toolbar / IG keyboard |
| 125 | TRIGGER | `FORM.KEY-DUPREC` | – | – | – | DROPPED | NIB.KEY_DUPREC -> page 0 toolbar / IG keyboard |
| 126 | TRIGGER | `FORM.PRE-FORM` | – | – | – | DROPPED | NIB.PRE_FORM, NLS date setting, help path -> f345 application |
| 127 | TRIGGER | `FORM.WHEN-NEW-FORM-INSTANCE` | WHEN-NEW-FORM-INSTANCE | 1120 | IMPR1120.INIT_FORM | MAPPED | site check; PORT_CD rule -> PORT_CD_IS_READ_ONLY; port value -> IMPORTERS WHEN-CREATE-RECORD; NIB / CG$ startup -> f345, LOVs |
| 128 | TRIGGER | `FORM.WHEN-WINDOW-ACTIVATED` | – | – | – | DROPPED | timers / window / frame (OLB, NIB) |
| 129 | TRIGGER | `FORM.KEY-ENTQRY` | – | – | – | DROPPED | NIB.KEY_ENTQRY -> page 0 toolbar / IG keyboard |
| 130 | TRIGGER | `FORM.ON-ERROR` | APP_ERROR_HANDLER (f345) | – | – | MAPPED | NIB.ON_ERROR |
| 131 | TRIGGER | `FORM.ON-MESSAGE` | APP_ERROR_HANDLER (f345) / page messages | – | – | MAPPED | NIB.ON_MESSAGE |
| 132 | TRIGGER | `FORM.KEY-CLRBLK` | – | – | – | DROPPED | NIB.KEY_CLRBLK -> page 0 toolbar / IG keyboard |
| 133 | TRIGGER | `FORM.KEY-DELREC` | – | – | – | DROPPED | NIB.KEY_DELREC -> page 0 toolbar / IG keyboard |
| 134 | TRIGGER | `FORM.KEY-F5` | – | – | – | DROPPED | NIB.KEY_F5 -> page 0 toolbar / IG keyboard |
| 135 | TRIGGER | `FORM.KEY-F4` | – | – | – | DROPPED | timers / window / frame (OLB, NIB) |
| 136 | TRIGGER | `FORM.KEY-NXTREC` | – | – | – | DROPPED | NIB.KEY_NXTREC -> page 0 toolbar / IG keyboard |
| 137 | TRIGGER | `FORM.KEY-PRVREC` | – | – | – | DROPPED | NIB.KEY_PRVREC -> page 0 toolbar / IG keyboard |
| 138 | TRIGGER | `FORM.KEY-DOWN` | – | – | – | DROPPED | NIB.KEY_DOWN -> page 0 toolbar / IG keyboard |
| 139 | TRIGGER | `FORM.KEY-UP` | – | – | – | DROPPED | NIB.KEY_UP -> page 0 toolbar / IG keyboard |
| 140 | TRIGGER | `FORM.KEY-SCRUP` | – | – | – | DROPPED | NIB.KEY_SCRUP -> page 0 toolbar / IG keyboard |
| 141 | TRIGGER | `FORM.KEY-SCRDOWN` | – | – | – | DROPPED | NIB.KEY_SCRDOWN -> page 0 toolbar / IG keyboard |
| 142 | TRIGGER | `FORM.KEY-PRINT` | – | – | – | DROPPED | NIB.KEY_PRINT -> page 0 toolbar / IG keyboard |
| 143 | TRIGGER | `FORM.KEY-EXIT` | – | – | – | DROPPED | NIB.KEY_EXIT -> page 0 toolbar / IG keyboard |
| 144 | TRIGGER | `FORM.WHEN-MOUSE-DOWN` | – | – | – | DROPPED | timers / window / frame (OLB, NIB) |
| 145 | TRIGGER | `FORM.KEY-EXEQRY` | – | – | – | DROPPED | NIB.KEY_EXEQRY -> page 0 toolbar / IG keyboard |
| 146 | TRIGGER | `FORM.KEY-F9` | FUNCS (page 0 toolbar) | 0 | – | MAPPED | side-menu toggle -> FUNCS |
| 147 | TRIGGER | `FORM.WHEN-TIMER-EXPIRED` | – | – | – | DROPPED | timers / window / frame (OLB, NIB) |
| 148 | TRIGGER | `FORM.KEY-HELP` | – | – | – | DROPPED | MS-Help obsolete |
| 149 | TRIGGER | `FORM.WHEN-NEW-BLOCK-INSTANCE` | – | – | – | DROPPED | Designer master-detail coordination (CGBS$) -> native Form + IG |
| 150 | TRIGGER | `FORM.ON-CLEAR-DETAILS` | – | – | – | DROPPED | Designer master-detail coordination (CGBS$) -> native Form + IG |
| 151 | TRIGGER | `FORM.ON-POPULATE-DETAILS` | – | – | – | DROPPED | Designer master-detail coordination (CGBS$) -> native Form + IG |
| 152 | TRIGGER | `FORM.KEY-CQUERY` | – | – | – | DROPPED | Designer key handler -> page 0 toolbar / IG |
| 153 | TRIGGER | `FORM.KEY-CLRREC` | – | – | – | DROPPED | Designer key handler -> page 0 toolbar / IG |
| 154 | TRIGGER | `FORM.KEY-NXTKEY` | – | – | – | DROPPED | Designer key handler -> page 0 toolbar / IG |
| 155 | TRIGGER | `FORM.KEY-MENU` | – | – | – | DROPPED | Designer key handler -> page 0 toolbar / IG |
| 156 | TRIGGER | `FORM.KEY-CLRFRM` | – | – | – | DROPPED | Designer key handler -> page 0 toolbar / IG |
| 157 | TRIGGER | `TITLE.CGSO$CHAR_ARB_ED.KEY-LISTVAL` | – | – | – | DROPPED | OLB frame (TITLE) |
| 158 | TRIGGER | `TITLE.CGSO$CHAR_ARB_DO_ENB_Y.KEY-LISTVAL` | – | – | – | DROPPED | OLB frame (TITLE) |
| 159 | TRIGGER | `TITLE.CGSO$CHAR_ARB_MLINE.KEY-LISTVAL` | – | – | – | DROPPED | OLB frame (TITLE) |
| 160 | TRIGGER | `TITLE.CGSO$CHAR_ARB.KEY-LISTVAL` | – | – | – | DROPPED | OLB frame (TITLE) |
| 161 | TRIGGER | `TITLE.CGSO$CHAR_ARB_DO.KEY-LISTVAL` | – | – | – | DROPPED | OLB frame (TITLE) |
| 162 | TRIGGER | `TITLE.SYSTEM_DATE.WHEN-VALIDATE-ITEM` | – | – | – | DROPPED | OLB frame (TITLE) |
| 163 | TRIGGER | `EDI_MSG.EDI_MSG_LOVE_BUT.WHEN-BUTTON-PRESSED` | – | – | – | DROPPED | OLB frame (EDI_MSG) |
| 164 | TRIGGER | `LSIDE.FN1.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 165 | TRIGGER | `LSIDE.FN1.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 166 | TRIGGER | `LSIDE.FN1.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 167 | TRIGGER | `LSIDE.FN50.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 168 | TRIGGER | `LSIDE.FN50.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 169 | TRIGGER | `LSIDE.FN50.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 170 | TRIGGER | `LSIDE.FN2.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 171 | TRIGGER | `LSIDE.FN2.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 172 | TRIGGER | `LSIDE.FN2.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 173 | TRIGGER | `LSIDE.FN49.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 174 | TRIGGER | `LSIDE.FN49.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 175 | TRIGGER | `LSIDE.FN49.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 176 | TRIGGER | `LSIDE.FN3.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 177 | TRIGGER | `LSIDE.FN3.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 178 | TRIGGER | `LSIDE.FN3.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 179 | TRIGGER | `LSIDE.FN48.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 180 | TRIGGER | `LSIDE.FN48.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 181 | TRIGGER | `LSIDE.FN48.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 182 | TRIGGER | `LSIDE.FN4.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 183 | TRIGGER | `LSIDE.FN4.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 184 | TRIGGER | `LSIDE.FN4.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 185 | TRIGGER | `LSIDE.FN47.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 186 | TRIGGER | `LSIDE.FN47.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 187 | TRIGGER | `LSIDE.FN47.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 188 | TRIGGER | `LSIDE.FN5.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 189 | TRIGGER | `LSIDE.FN5.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 190 | TRIGGER | `LSIDE.FN5.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 191 | TRIGGER | `LSIDE.FN46.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 192 | TRIGGER | `LSIDE.FN46.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 193 | TRIGGER | `LSIDE.FN46.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 194 | TRIGGER | `LSIDE.FN6.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 195 | TRIGGER | `LSIDE.FN6.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 196 | TRIGGER | `LSIDE.FN6.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 197 | TRIGGER | `LSIDE.FN45.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 198 | TRIGGER | `LSIDE.FN45.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 199 | TRIGGER | `LSIDE.FN45.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 200 | TRIGGER | `LSIDE.FN7.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 201 | TRIGGER | `LSIDE.FN7.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 202 | TRIGGER | `LSIDE.FN7.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 203 | TRIGGER | `LSIDE.FN44.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 204 | TRIGGER | `LSIDE.FN44.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 205 | TRIGGER | `LSIDE.FN44.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 206 | TRIGGER | `LSIDE.FN8.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 207 | TRIGGER | `LSIDE.FN8.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 208 | TRIGGER | `LSIDE.FN8.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 209 | TRIGGER | `LSIDE.FN43.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 210 | TRIGGER | `LSIDE.FN43.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 211 | TRIGGER | `LSIDE.FN43.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 212 | TRIGGER | `LSIDE.FN9.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 213 | TRIGGER | `LSIDE.FN9.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 214 | TRIGGER | `LSIDE.FN9.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 215 | TRIGGER | `LSIDE.FN42.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 216 | TRIGGER | `LSIDE.FN42.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 217 | TRIGGER | `LSIDE.FN42.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 218 | TRIGGER | `LSIDE.FN10.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 219 | TRIGGER | `LSIDE.FN10.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 220 | TRIGGER | `LSIDE.FN10.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 221 | TRIGGER | `LSIDE.FN41.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 222 | TRIGGER | `LSIDE.FN41.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 223 | TRIGGER | `LSIDE.FN41.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 224 | TRIGGER | `LSIDE.FN11.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 225 | TRIGGER | `LSIDE.FN11.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 226 | TRIGGER | `LSIDE.FN11.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 227 | TRIGGER | `LSIDE.FN40.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 228 | TRIGGER | `LSIDE.FN40.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 229 | TRIGGER | `LSIDE.FN40.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 230 | TRIGGER | `LSIDE.FN12.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 231 | TRIGGER | `LSIDE.FN12.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 232 | TRIGGER | `LSIDE.FN12.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 233 | TRIGGER | `LSIDE.FN39.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 234 | TRIGGER | `LSIDE.FN39.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 235 | TRIGGER | `LSIDE.FN39.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 236 | TRIGGER | `LSIDE.FN13.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 237 | TRIGGER | `LSIDE.FN13.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 238 | TRIGGER | `LSIDE.FN13.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 239 | TRIGGER | `LSIDE.FN38.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 240 | TRIGGER | `LSIDE.FN38.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 241 | TRIGGER | `LSIDE.FN38.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 242 | TRIGGER | `LSIDE.FN14.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 243 | TRIGGER | `LSIDE.FN14.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 244 | TRIGGER | `LSIDE.FN14.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 245 | TRIGGER | `LSIDE.FN37.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 246 | TRIGGER | `LSIDE.FN37.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 247 | TRIGGER | `LSIDE.FN37.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 248 | TRIGGER | `LSIDE.FN15.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 249 | TRIGGER | `LSIDE.FN15.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 250 | TRIGGER | `LSIDE.FN15.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 251 | TRIGGER | `LSIDE.FN36.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 252 | TRIGGER | `LSIDE.FN36.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 253 | TRIGGER | `LSIDE.FN36.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 254 | TRIGGER | `LSIDE.FN16.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 255 | TRIGGER | `LSIDE.FN16.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 256 | TRIGGER | `LSIDE.FN16.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 257 | TRIGGER | `LSIDE.FN17.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 258 | TRIGGER | `LSIDE.FN17.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 259 | TRIGGER | `LSIDE.FN17.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 260 | TRIGGER | `LSIDE.FN34.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 261 | TRIGGER | `LSIDE.FN34.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 262 | TRIGGER | `LSIDE.FN34.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 263 | TRIGGER | `LSIDE.FN35.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 264 | TRIGGER | `LSIDE.FN35.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 265 | TRIGGER | `LSIDE.FN35.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 266 | TRIGGER | `LSIDE.FN18.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 267 | TRIGGER | `LSIDE.FN18.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 268 | TRIGGER | `LSIDE.FN18.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 269 | TRIGGER | `LSIDE.FN33.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 270 | TRIGGER | `LSIDE.FN33.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 271 | TRIGGER | `LSIDE.FN33.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 272 | TRIGGER | `LSIDE.FN19.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 273 | TRIGGER | `LSIDE.FN19.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 274 | TRIGGER | `LSIDE.FN19.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 275 | TRIGGER | `LSIDE.FN32.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 276 | TRIGGER | `LSIDE.FN32.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 277 | TRIGGER | `LSIDE.FN32.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 278 | TRIGGER | `LSIDE.FN20.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 279 | TRIGGER | `LSIDE.FN20.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 280 | TRIGGER | `LSIDE.FN20.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 281 | TRIGGER | `LSIDE.FN31.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 282 | TRIGGER | `LSIDE.FN31.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 283 | TRIGGER | `LSIDE.FN31.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 284 | TRIGGER | `LSIDE.FN21.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 285 | TRIGGER | `LSIDE.FN21.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 286 | TRIGGER | `LSIDE.FN21.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 287 | TRIGGER | `LSIDE.FN30.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 288 | TRIGGER | `LSIDE.FN30.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 289 | TRIGGER | `LSIDE.FN30.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 290 | TRIGGER | `LSIDE.FN22.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 291 | TRIGGER | `LSIDE.FN22.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 292 | TRIGGER | `LSIDE.FN22.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 293 | TRIGGER | `LSIDE.FN29.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 294 | TRIGGER | `LSIDE.FN29.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 295 | TRIGGER | `LSIDE.FN29.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 296 | TRIGGER | `LSIDE.FN23.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 297 | TRIGGER | `LSIDE.FN23.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 298 | TRIGGER | `LSIDE.FN23.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 299 | TRIGGER | `LSIDE.FN28.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 300 | TRIGGER | `LSIDE.FN28.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 301 | TRIGGER | `LSIDE.FN28.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 302 | TRIGGER | `LSIDE.FN24.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 303 | TRIGGER | `LSIDE.FN24.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 304 | TRIGGER | `LSIDE.FN24.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 305 | TRIGGER | `LSIDE.FN27.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 306 | TRIGGER | `LSIDE.FN27.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 307 | TRIGGER | `LSIDE.FN27.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 308 | TRIGGER | `LSIDE.FN25.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 309 | TRIGGER | `LSIDE.FN25.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 310 | TRIGGER | `LSIDE.FN25.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 311 | TRIGGER | `LSIDE.FN26.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 312 | TRIGGER | `LSIDE.FN26.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 313 | TRIGGER | `LSIDE.FN26.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 314 | TRIGGER | `TOOLBAR.KEY-DOWN` | – | – | – | DROPPED | OLB toolbar / side-menu keyboard |
| 315 | TRIGGER | `TOOLBAR.KEY-UP` | – | – | – | DROPPED | OLB toolbar / side-menu keyboard |
| 316 | TRIGGER | `TOOLBAR.KEY-NEXT-ITEM` | – | – | – | DROPPED | OLB toolbar / side-menu keyboard |
| 317 | TRIGGER | `TOOLBAR.SAVE.WHEN-BUTTON-PRESSED` | SAVE (page 0 toolbar) | 0 | – | MAPPED | toolbar button |
| 318 | TRIGGER | `TOOLBAR.CLEAR_ALL.WHEN-BUTTON-PRESSED` | CLEAR (page 0 toolbar) | 0 | – | MAPPED | toolbar button |
| 319 | TRIGGER | `TOOLBAR.EXIT.WHEN-BUTTON-PRESSED` | BACK (page 0 toolbar) | 0 | – | MAPPED | toolbar button |
| 320 | TRIGGER | `TOOLBAR.EXIT1.WHEN-BUTTON-PRESSED` | BACK (page 0 toolbar) | 0 | – | MAPPED | toolbar button |
| 321 | TRIGGER | `TOOLBAR.ENTER.WHEN-BUTTON-PRESSED` | SEARCH (page 0 toolbar) | 0 | – | MAPPED | toolbar button |
| 322 | TRIGGER | `TOOLBAR.EXECUTE.WHEN-BUTTON-PRESSED` | SEARCH (page 0 toolbar) | 0 | – | MAPPED | toolbar button |
| 323 | TRIGGER | `TOOLBAR.REMOVE.WHEN-BUTTON-PRESSED` | DELETE (page 0 toolbar) / IG row delete | 0 | – | MAPPED | toolbar button |
| 324 | TRIGGER | `TOOLBAR.LIST_VALUE.WHEN-BUTTON-PRESSED` | – | – | – | DROPPED | OLB toolbar / side-menu keyboard |
| 325 | TRIGGER | `TOOLBAR.HELP.WHEN-BUTTON-PRESSED` | – | – | – | DROPPED | OLB toolbar / side-menu keyboard |
| 326 | TRIGGER | `TOOLBAR.LAST_REC.WHEN-BUTTON-PRESSED` | – | – | – | DROPPED | OLB toolbar / side-menu keyboard |
| 327 | TRIGGER | `TOOLBAR.RE_ENTER_QUERY.WHEN-BUTTON-PRESSED` | SEARCH (page 0 toolbar) | 0 | – | MAPPED | toolbar button |
| 328 | TRIGGER | `TOOLBAR.FIRST_REC.WHEN-BUTTON-PRESSED` | – | – | – | DROPPED | OLB toolbar / side-menu keyboard |
| 329 | TRIGGER | `TOOLBAR.PAGE_UP.WHEN-BUTTON-PRESSED` | – | – | – | DROPPED | OLB toolbar / side-menu keyboard |
| 330 | TRIGGER | `TOOLBAR.PAGE_DOWN.WHEN-BUTTON-PRESSED` | – | – | – | DROPPED | OLB toolbar / side-menu keyboard |
| 331 | TRIGGER | `TOOLBAR.FUN_BUT.WHEN-MOUSE-UP` | FUNCS (page 0 toolbar) | 0 | – | MAPPED | toolbar button |
| 332 | TRIGGER | `TOOLBAR.FUN_BUT.WHEN-MOUSE-DOWN` | FUNCS (page 0 toolbar) | 0 | – | MAPPED | toolbar button |
| 333 | TRIGGER | `IMPORTERS.ON-ERROR` | APP_ERROR_HANDLER (f345) | – | – | MAPPED | Designer constraint messages |
| 334 | TRIGGER | `IMPORTERS.POST-QUERY` | POST-QUERY | 1120 | IMPR1120.IMPORTERS_POST_QUERY | MAPPED | Before Header after Initialize form |
| 335 | TRIGGER | `IMPORTERS.PRE-QUERY` | IMPORTERS_SEARCH region SQL (page 112001) | 112001 | IMPR1120.IMPORTERS_PRE_QUERY_PORT_CD | MAPPED | port rule + one search text P112001_SEARCH over all columns (+ IMPORTERS_PRE_QUERY_NAME_STD); Exec_Query_Now -> P0_PAGE_PK |
| 336 | TRIGGER | `IMPORTERS.KEY-HELP` | – | – | – | DROPPED | MS-Help obsolete |
| 337 | TRIGGER | `IMPORTERS.WHEN-CREATE-RECORD` | IMPORTERS WHEN-CREATE-RECORD | 1120 | IMPR1120.IMPORTERS_WHEN_CREATE_RECORD | MAPPED | Before Header when P0_PAGE_PK is null |
| 338 | TRIGGER | `IMPORTERS.PORT_CD.KEY-LISTVAL` | LOV_SD_PORTS (Popup LOV of P1120_PORT_CD; on 112001 the port is part of the search text) | 1120 | – | MAPPED | CALL_FORM LOV_SD_PORTS |
| 339 | TRIGGER | `IMPORTERS.PORT_CD2.WHEN-BUTTON-PRESSED` | – | – | – | DROPPED | LOV button -> popup LOV icon / item display only |
| 340 | TRIGGER | `IMPORTERS.PORT_NAME.KEY-LISTVAL` | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 341 | TRIGGER | `IMPORTERS.HQ_IMPR_NBR.KEY-LISTVAL` | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 342 | TRIGGER | `IMPORTERS.IMPR_NBR.KEY-LISTVAL` | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 343 | TRIGGER | `IMPORTERS.IMPR_NBR.WHEN-VALIDATE-ITEM` | IMPR_NBR VALIDATION + DA IMPR_NBR WHEN-VALIDATE-ITEM + process EXECUTE-QUERY | 1120 | IMPR1120.IMPR_NBR_VALIDATION | MAPPED | also IMPR1120.IMPR_NBR_WHEN_VALIDATE_ITEM (process EXECUTE-QUERY) |
| 344 | TRIGGER | `IMPORTERS.SDP_PORT_STATUS.KEY-LISTVAL` | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 345 | TRIGGER | `IMPORTERS.IMPR_TYPE_CD.KEY-LISTVAL` | IMPORTERS_SEARCH column filter (page 112001) | 112001 | – | MAPPED | CALL_FORM LOV_Impr_Type used as query criterion -> IG column filter |
| 346 | TRIGGER | `IMPORTERS.IMPR_TYPE_CD.WHEN-VALIDATE-ITEM` | – | – | – | DROPPED | item display only; names come from IMPORTERS_POST_QUERY |
| 347 | TRIGGER | `IMPORTERS.IMPR_TYPE_CD.WHEN-NEW-ITEM-INSTANCE` | IMPR_NBR WHEN-VALIDATE-ITEM (Submit EXECUTE_QUERY) | 1120 | – | MAPPED | CLEAR_BLOCK + EXECUTE_QUERY -> page submit |
| 348 | TRIGGER | `IMPORTERS.IMPR_TYPE_CD2.WHEN-BUTTON-PRESSED` | – | – | – | DROPPED | LOV button -> popup LOV icon / item display only |
| 349 | TRIGGER | `IMPORTERS.IMPR_TYPE_NAME.KEY-LISTVAL` | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 350 | TRIGGER | `IMPORTERS.CTRY_CD.KEY-LISTVAL` | IMPORTERS_SEARCH column filter (page 112001) | 112001 | – | MAPPED | CALL_FORM LOV_COUNTRIES used as query criterion -> IG column filter |
| 351 | TRIGGER | `IMPORTERS.CTRY_CD2.WHEN-BUTTON-PRESSED` | – | – | – | DROPPED | LOV button -> popup LOV icon / item display only |
| 352 | TRIGGER | `IMPORTERS.CRTY_ARBC_NAME.KEY-LISTVAL` | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 353 | TRIGGER | `IMPORTERS.CITY_CODE_OF_ID.KEY-LISTVAL` | IMPORTERS_SEARCH column filter (page 112001) | 112001 | – | MAPPED | CALL_FORM LOV_CITIES used as query criterion -> IG column filter |
| 354 | TRIGGER | `IMPORTERS.CITY_CODE_OF_ID2.WHEN-BUTTON-PRESSED` | – | – | – | DROPPED | LOV button -> popup LOV icon / item display only |
| 355 | TRIGGER | `IMPORTERS.ID_CITY_NAME.KEY-LISTVAL` | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 356 | TRIGGER | `IMPORTERS.BUS_ID.KEY-LISTVAL` | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 357 | TRIGGER | `IMPORTERS.BUS_ID_TYPE_CD.KEY-LISTVAL` | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 358 | TRIGGER | `IMPORTERS.BUTT.WHEN-BUTTON-PRESSED` | – | – | – | DROPPED | LOV button -> popup LOV icon / item display only |
| 359 | TRIGGER | `IMPORTERS.BUS_ID_TYPE_NAME.KEY-LISTVAL` | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 360 | TRIGGER | `IMPORTERS.BUS_ID_BRNCH.KEY-LISTVAL` | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 361 | TRIGGER | `IMPORTERS.CTRY_CTRY_STATUS.KEY-LISTVAL` | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 362 | TRIGGER | `IMPORTERS.ARBC_IMPR_NAME.KEY-LISTVAL` | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 363 | TRIGGER | `IMPORTERS.ENG_IMPR_NAME.KEY-LISTVAL` | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 364 | TRIGGER | `IMPORTERS.IMPR_CNTCT_NAME.KEY-LISTVAL` | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 365 | TRIGGER | `IMPORTERS.CTRY_CD_OF_ID.KEY-LISTVAL` | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 366 | TRIGGER | `IMPR_SUSPN.ON-ERROR` | IS_1_IMP_FK (Text Message) + APP_ERROR_HANDLER | – | – | MAPPED | – |
| 367 | TRIGGER | `IMPR_SUSPN.KEY-HELP` | – | – | – | DROPPED | MS-Help obsolete |
| 368 | TRIGGER | `IMPR_SUSPN.KEY-DELREC` | IMPR_SUSPN row delete (native confirm) | 1120 | – | MAPPED | TMPLT.KEY_DELETE_RECORD: confirm + delete + COMMIT -> IG delete, APEX commit |
| 369 | TRIGGER | `IMPR_SUSPN.ON-DELETE` | IMPR_SUSPN - Save Interactive Grid Data | 1120 | IMPR1120.IMPR_SUSPN_ON_DELETE | MAPPED | soft delete, called by IMPR_SUSPN_SAVE_ROW (row status D) |
| 370 | TRIGGER | `IMPR_SUSPN.POST-INSERT` | IMPR_SUSPN - Save Interactive Grid Data | 1120 | IMPR1120.IMPR_SUSPN_POST_INSERT | MAPPED | called by IMPR_SUSPN_SAVE_ROW; COMMIT removed (HIGH); enabling part -> SUSPN_SIDE_CD_IS_READ_ONLY |
| 371 | TRIGGER | `IMPR_SUSPN.POST-QUERY` | IMPR_SUSPN.SUSPN_SIDE_CD Read Only | 1120 | IMPR1120.SUSPN_SIDE_CD_IS_READ_ONLY | MAPPED | – |
| 372 | TRIGGER | `IMPR_SUSPN.PRE-INSERT` | IMPR_SUSPN - Save Interactive Grid Data | 1120 | IMPR1120.IMPR_SUSPN_PRE_INSERT | MAPPED | called by IMPR_SUSPN_SAVE_ROW (row status C) |
| 373 | TRIGGER | `IMPR_SUSPN.PRE-UPDATE` | IMPR_SUSPN - Save Interactive Grid Data | 1120 | IMPR1120.IMPR_SUSPN_PRE_UPDATE | MAPPED | called by IMPR_SUSPN_SAVE_ROW (row status U) |
| 374 | TRIGGER | `IMPR_SUSPN.WHEN-NEW-RECORD-INSTANCE` | Read Only of every IMPR_SUSPN column (For Each Row) | 1120 | IMPR1120.IMPR_SUSPN_IS_READ_ONLY | MAPPED | NEXT_RECORD -> row read only + server check; stored side -> SUSPN_SIDE_CD_IS_READ_ONLY; GO_ITEM dropped |
| 375 | TRIGGER | `IMPR_SUSPN.SUSPN_STRT_DT.KEY-LISTVAL` | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 376 | TRIGGER | `IMPR_SUSPN.SUSPN_STRT_DT.KEY-F4` | – | – | – | DROPPED | INTRFACE.DISP_DATE_CON -> date column (Hijri picker) |
| 377 | TRIGGER | `IMPR_SUSPN.SUSPN_STRT_DT.WHEN-VALIDATE-ITEM` | IMPR_SUSPN SUSPN_STRT_DT VALIDATION + DA IMPR_SUSPN SUSPN_STRT_DT WHEN-VALIDATE-ITEM | 1120 | IMPR1120.SUSPN_STRT_DT_VALIDATION | MAPPED | – |
| 378 | TRIGGER | `IMPR_SUSPN.SUSPN_STRT_DT.WHEN-NEW-ITEM-INSTANCE` | IMPR_SUSPN.SUSPN_STRT_DT default | 1120 | IMPR1120.SUSPN_STRT_DT_DEFAULT | MAPPED | – |
| 379 | TRIGGER | `IMPR_SUSPN.SUSPN_END_DT.KEY-LISTVAL` | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 380 | TRIGGER | `IMPR_SUSPN.SUSPN_END_DT.KEY-F4` | – | – | – | DROPPED | INTRFACE.DISP_DATE_CON -> date column (Hijri picker) |
| 381 | TRIGGER | `IMPR_SUSPN.SUSPN_END_DT.WHEN-VALIDATE-ITEM` | IMPR_SUSPN SUSPN_END_DT VALIDATION + DA IMPR_SUSPN SUSPN_END_DT WHEN-VALIDATE-ITEM | 1120 | IMPR1120.SUSPN_END_DT_VALIDATION | MAPPED | – |
| 382 | TRIGGER | `IMPR_SUSPN.SUSPN_RSN_CD.KEY-LISTVAL` | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 383 | TRIGGER | `IMPR_SUSPN.SUSPN_RSN_CD.WHEN-NEW-ITEM-INSTANCE` | IMPR_SUSPN.SUSPN_RSN_CD / SUSPN_RSN_TEXT defaults | 1120 | IMPR1120.SUSPN_RSN_CD_DEFAULT | MAPPED | with SUSPN_RSN_TEXT_DEFAULT |
| 384 | TRIGGER | `IMPR_SUSPN.SUSPN_RSN_CD.WHEN-VALIDATE-ITEM` | IMPR_SUSPN SUSPN_RSN_CD VALIDATION + DA IMPR_SUSPN SUSPN_RSN_CD WHEN-VALIDATE-ITEM | 1120 | IMPR1120.SUSPN_RSN_CD_VALIDATION | MAPPED | derived SUSPN_RSN_TEXT -> SUSPN_RSN_CD_VALIDATE_ITEM |
| 385 | TRIGGER | `IMPR_SUSPN.SUSPN_RSN_TEXT.KEY-LISTVAL` | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 386 | TRIGGER | `IMPR_SUSPN.SUSPN_RSN_TEXT.WHEN-NEW-ITEM-INSTANCE` | – | – | – | DROPPED | body is NULL |
| 387 | TRIGGER | `IMPR_SUSPN.SUSPN_SIDE_CD.WHEN-LIST-CHANGED` | IMPR_SUSPN SUSPN_SIDE_CD WHEN-LIST-CHANGED | 1120 | IMPR1120.SUSPN_SIDE_CD_VALIDATION | MAPPED | – |
| 388 | TRIGGER | `IMPR_SUSPN.SUSPN_SIDE_CD.WHEN-NEW-ITEM-INSTANCE` | IMPR_SUSPN.SUSPN_SIDE_CD default | 1120 | IMPR1120.SUSPN_SIDE_CD_DEFAULT | MAPPED | – |
| 389 | TRIGGER | `IMPR_SUSPN.SUSPN_SIDE_CD.WHEN-VALIDATE-ITEM` | IMPR_SUSPN SUSPN_SIDE_CD VALIDATION | 1120 | IMPR1120.SUSPN_SIDE_CD_VALIDATION | MAPPED | – |
| 390 | TRIGGER | `IMPR_SUSPN.SUSPN_RLSE_DT.KEY-LISTVAL` | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 391 | TRIGGER | `IMPR_SUSPN.SUSPN_RLSE_DT.KEY-F4` | – | – | – | DROPPED | INTRFACE.DISP_DATE_CON -> date column (Hijri picker) |
| 392 | TRIGGER | `IMPR_SUSPN.SUSPN_RLSE_DT.WHEN-VALIDATE-ITEM` | – | – | – | DROPPED | hidden, non-navigable item: never fires |
| 393 | RELATION | `CGFK$IS_1_IMP_FK` | IMPR_SUSPN (IG WHERE port_cd = :P1120_PORT_CD AND impr_nbr = :P1120_IMPR_NBR) | 1120 | – | MAPPED | IMPORTERS -> IMPR_SUSPN; master keys from the master form (column default + NVL in the save call) |
| 394 | LOV | `CGFK$IMPORTERS_PORT_CD` | LOV_SD_PORTS (from IMPR1110) | 1120 | – | MAPPED | P1120_PORT_CD (port 99 only) |
| 395 | LOV | `CGFK$IMPORTERS_CITY_CODE_OF_ID` | – | – | – | DROPPED | item display only; search by IG column filter |
| 396 | LOV | `CGFK$IMPORTERS_CTRY_CD` | – | – | – | DROPPED | item display only; search by IG column filter |
| 397 | LOV | `CGFK$IMPORTERS_HQ_IMPR_NBR` | – | – | – | DROPPED | item display only |
| 398 | LOV | `CGFK$IMPORTERS_IMPR_TYPE_CD` | – | – | – | DROPPED | item display only; search by IG column filter |
| 399 | RECORD_GROUP | `CGFK$IMPORTERS_PORT_CD` | LOV_SD_PORTS (from IMPR1110) | 1120 | – | MAPPED | query of LOV CGFK$IMPORTERS_PORT_CD |
| 400 | RECORD_GROUP | `CGFK$IMPORTERS_CITY_CODE_OF_ID` | – | – | – | DROPPED | query of LOV CGFK$IMPORTERS_CITY_CODE_OF_ID |
| 401 | RECORD_GROUP | `CGFK$IMPORTERS_CTRY_CD` | – | – | – | DROPPED | query of LOV CGFK$IMPORTERS_CTRY_CD |
| 402 | RECORD_GROUP | `CGFK$IMPORTERS_HQ_IMPR_NBR` | – | – | – | DROPPED | query of LOV CGFK$IMPORTERS_HQ_IMPR_NBR |
| 403 | RECORD_GROUP | `CGFK$IMPORTERS_IMPR_TYPE_CD` | – | – | – | DROPPED | query of LOV CGFK$IMPORTERS_IMPR_TYPE_CD |
| 404 | RECORD_GROUP | `CGDV$DLRG (runtime)` | LOV_ALLOWED_EXPORT, LOV_IMPR_SUSPN_RSN_CD, LOV_SUSPN_SIDE_CD | 1120 | – | MAPPED | CREATE_GROUP_FROM_QUERY on CG_REF_CODES in CGDV$POPULATE_DYNAMIC_LISTS |
| 405 | CANVAS | `LSIDE` | – | – | – | DROPPED | OLB canvas LSIDE |
| 406 | CANVAS | `EDI_MSG` | – | – | – | DROPPED | OLB canvas EDI_MSG |
| 407 | CANVAS | `TITLE` | – | – | – | DROPPED | OLB canvas TITLE |
| 408 | CANVAS | `TOOLBAR` | – | – | – | DROPPED | OLB canvas TOOLBAR |
| 409 | CANVAS | `CG$PAGE_1` | 1120 IMPR1120 | 1120 | – | MAPPED | main content canvas |
| 410 | WINDOW | `CGSO$WINDOW_1` | 1120 IMPR1120 | 1120 | – | MAPPED | console window |
| 411 | ALERT | `CG$ASK_COMMIT` | – | – | – | DROPPED | not used by IMPR1120 code |
| 412 | ALERT | `USR_CONFIRM_B` | – | – | – | DROPPED | not used by IMPR1120 code |
| 413 | ALERT | `USR_CONFIRM` | – | – | – | DROPPED | not used by IMPR1120 code |
| 414 | ALERT | `USR_WARNING_C` | – | – | – | DROPPED | not used by IMPR1120 code |
| 415 | ALERT | `USR_WARNING_B` | IG row delete confirm "هل أنت متأكد من عملية الحذف" | 1120 | – | MAPPED | TMPLT.KEY_DELETE_RECORD |
| 416 | ALERT | `CFG_WARNING_A` | – | – | – | DROPPED | not used by IMPR1120 code |
| 417 | ALERT | `CFG_INFORMATION` | validation error text (message 9-150 stops the query in Forms too) | 1120 | – | MAPPED | – |
| 418 | ALERT | `CFG_ERROR` | CHECK_ERROR / FORMS_APX.FORM_TRIGGER_FAILURE (inline error) | 1120 | – | MAPPED | STR.DispArbMsg ERROR 9-100, 9-110; DispAlert SYSTEM_ERROR |
| 419 | ALERT | `CFG_SYSTEM_ERROR` | FORMS_APX.FORM_TRIGGER_FAILURE (activity log / Hijri date errors) | 1120 | – | MAPPED | – |
| 420 | ALERT | `CFG_ASK_COMMIT` | – | – | – | DROPPED | not used by IMPR1120 code |
| 421 | PARAMETER | `P_SHPG_AGNT_NBR` | – | – | – | DROPPED | not used by the business code (function menu / reports / frame) |
| 422 | PARAMETER | `P_CTRL_LAST_EXEC_CD` | – | – | – | DROPPED | not used by the business code (function menu / reports / frame) |
| 423 | PARAMETER | `P_BANK_CD` | – | – | – | DROPPED | not used by the business code (function menu / reports / frame) |
| 424 | PARAMETER | `P_BANK_BRNCH_CD` | – | – | – | DROPPED | not used by the business code (function menu / reports / frame) |
| 425 | PARAMETER | `P_BRKR_PORT_CD` | – | – | – | DROPPED | not used by the business code (function menu / reports / frame) |
| 426 | PARAMETER | `P_LIC_TYPE` | – | – | – | DROPPED | not used by the business code (function menu / reports / frame) |
| 427 | PARAMETER | `P_BRKR_NBR` | – | – | – | DROPPED | not used by the business code (function menu / reports / frame) |
| 428 | PARAMETER | `P_CLASS_CD` | – | – | – | DROPPED | not used by the business code (function menu / reports / frame) |
| 429 | PARAMETER | `P_JOB_ID` | – | – | – | DROPPED | not used by the business code (function menu / reports / frame) |
| 430 | PARAMETER | `P_CURRENT_ITEM` | – | – | – | DROPPED | not used by the business code (function menu / reports / frame) |
| 431 | PARAMETER | `P_GROUP_CD` | – | – | – | DROPPED | not used by the business code (function menu / reports / frame) |
| 432 | PARAMETER | `P_USER_TYPE` | – | – | – | DROPPED | not used by the business code (function menu / reports / frame) |
| 433 | PARAMETER | `P_PORT_TYPE` | P_PORT_TYPE (f345) | – | – | MAPPED | bind of LOV_SD_PORTS |
| 434 | PARAMETER | `P_CURR_PORT_CD` | P_CURR_PORT_CD (f345) | – | – | MAPPED | – |
| 435 | PARAMETER | `P_MODULE_ID` | P1120_MODULE_ID | 1120 | IMPR1120.GET_MODULE_ID | MAPPED | – |
| 436 | PARAMETER | `P_MODULE_NAME` | SYS_ANAME (f345 page title) | – | – | MAPPED | title bar only |
| 437 | PARAMETER | `P_APPLICATION_NAME` | – | – | – | DROPPED | not used by the business code (function menu / reports / frame) |
| 438 | PARAMETER | `P_USER_ID` | SSO_APP_USER (f345) | – | – | MAPPED | ACTIVITY_DB user |
| 439 | PARAMETER | `P_WS_ID` | P_GLOBAL_V_WS_ID (f345) | – | – | MAPPED | ACTIVITY_DB workstation |
| 440 | PARAMETER | `P_USER_NAME` | V_USR_NAME (f345 header) | – | – | MAPPED | title bar only |
| 441 | PARAMETER | `CG$STARTUP_MODE` | – | – | – | DROPPED | not used by the business code (function menu / reports / frame) |
| 442 | PARAMETER | `CURRENT_SIDE` | P1120_P_CURRENT_SIDE | 1120 | IMPR1120.GET_CURRENT_SIDE | MAPPED | source to confirm (inventory §15 #1) |
| 443 | LIBRARY | `OFGTEL` | – | – | – | TODO | MISSING SOURCE - constraint messages (CGTE$); block texts known, Text Messages per constraint |
| 444 | LIBRARY | `OFGMES` | – | – | – | DROPPED | not needed in the browser (help, DLL, window, tab, pick list) |
| 445 | LIBRARY | `OFGHPL` | – | – | – | DROPPED | not needed in the browser (help, DLL, window, tab, pick list) |
| 446 | LIBRARY | `CIC_AMSG` | – | – | – | MAPPED | Des$Form_errors messages -> FORMS_APX / APP_ERROR_HANDLER |
| 447 | LIBRARY | `SEC_LIB` | – | – | – | DROPPED | not needed in the browser (help, DLL, window, tab, pick list) |
| 448 | LIBRARY | `CAPTION` | – | – | – | DROPPED | not needed in the browser (help, DLL, window, tab, pick list) |
| 449 | LIBRARY | `OFGBSL` | – | – | – | MAPPED | CGBS$ master-detail -> native Form + IG |
| 450 | LIBRARY | `D2KWUTIL` | – | – | – | DROPPED | not needed in the browser (help, DLL, window, tab, pick list) |
| 451 | LIBRARY | `CUSTOMDLL` | – | – | – | DROPPED | not needed in the browser (help, DLL, window, tab, pick list) |
| 452 | LIBRARY | `D2KWUTIL_PDF` | – | – | – | DROPPED | not needed in the browser (help, DLL, window, tab, pick list) |
| 453 | LIBRARY | `GETCOMP` | – | – | – | DROPPED | not needed in the browser (help, DLL, window, tab, pick list) |
| 454 | LIBRARY | `OFGTAB` | – | – | – | DROPPED | not needed in the browser (help, DLL, window, tab, pick list) |
| 455 | LIBRARY | `PICKLIST` | – | – | – | DROPPED | not needed in the browser (help, DLL, window, tab, pick list) |
| 456 | LIBRARY | `POS` | – | – | – | DROPPED | not needed in the browser (help, DLL, window, tab, pick list) |
| 457 | LIBRARY | `SCDLL` | – | – | – | DROPPED | not needed in the browser (help, DLL, window, tab, pick list) |
| 458 | LIBRARY | `VCDLL` | – | – | – | DROPPED | not needed in the browser (help, DLL, window, tab, pick list) |
| 459 | LIBRARY | `CIC_LIB` | – | – | – | MAPPED | NIB / TMPLT -> f345; STR -> STR_DB; HIJDATE -> HIJDATE_DB; ACTIVITY -> ACTIVITY_DB; INTRFACE -> date column |
| 460 | GLOBAL | `CG$HP_HFILE` | – | – | – | DROPPED | LOV-form return value / Designer internal / version stamp / function menu - not needed |
| 461 | GLOBAL | `CG$HP_HPATH` | – | – | – | DROPPED | LOV-form return value / Designer internal / version stamp / function menu - not needed |
| 462 | GLOBAL | `CG$QUERY_MODE` | – | – | – | DROPPED | LOV-form return value / Designer internal / version stamp / function menu - not needed |
| 463 | GLOBAL | `CITY_ARB_NAME` | – | – | – | DROPPED | LOV-form return value / Designer internal / version stamp / function menu - not needed |
| 464 | GLOBAL | `CITY_CD` | – | – | – | DROPPED | LOV-form return value / Designer internal / version stamp / function menu - not needed |
| 465 | GLOBAL | `CRTY_ARBC_NAME` | – | – | – | DROPPED | LOV-form return value / Designer internal / version stamp / function menu - not needed |
| 466 | GLOBAL | `CTRY_CD` | – | – | – | DROPPED | LOV-form return value / Designer internal / version stamp / function menu - not needed |
| 467 | GLOBAL | `CURRENT_DT` | – | – | – | DROPPED | LOV-form return value / Designer internal / version stamp / function menu - not needed |
| 468 | GLOBAL | `CURRENT_VER` | – | – | – | DROPPED | LOV-form return value / Designer internal / version stamp / function menu - not needed |
| 469 | GLOBAL | `EXEC_QUERY_NOW` | P0_PAGE_PK (process EXECUTE-QUERY) | 1120 | – | MAPPED | no G_ application item needed |
| 470 | GLOBAL | `EXIT` | – | – | – | DROPPED | LOV-form return value / Designer internal / version stamp / function menu - not needed |
| 471 | GLOBAL | `IMPR_NBR` | P0_PAGE_PK | 1120 | – | MAPPED | no G_ application item needed |
| 472 | GLOBAL | `IMPR_TYPE_CD` | – | – | – | DROPPED | LOV-form return value / Designer internal / version stamp / function menu - not needed |
| 473 | GLOBAL | `IMPR_TYPE_NAME` | – | – | – | DROPPED | LOV-form return value / Designer internal / version stamp / function menu - not needed |
| 474 | GLOBAL | `PORT_CD` | P0_PAGE_PK / LOV return | 1120 | – | MAPPED | no G_ application item needed |
| 475 | GLOBAL | `PORT_NAME` | LOV additional output of P1120_PORT_CD | 1120 | – | MAPPED | no G_ application item needed |
| 476 | GLOBAL | `SYSTEM_OBJ` | – | – | – | DROPPED | LOV-form return value / Designer internal / version stamp / function menu - not needed |
| 477 | CALLED_FORM | `LOV_SD_PORTS` | LOV_SD_PORTS | 1120 | – | MAPPED | PORT_CD KEY-LISTVAL |
| 478 | CALLED_FORM | `LOV_IMPR_TYPE` | IMPORTERS_SEARCH column filter IMPR_TYPE_CD | 112001 | – | MAPPED | IMPR_TYPE_CD KEY-LISTVAL |
| 479 | CALLED_FORM | `LOV_COUNTRIES` | IMPORTERS_SEARCH column filter CTRY_CD | 112001 | – | MAPPED | CTRY_CD KEY-LISTVAL |
| 480 | CALLED_FORM | `LOV_CITIES` | IMPORTERS_SEARCH column filter CITY_CODE_OF_ID | 112001 | – | MAPPED | CITY_CODE_OF_ID KEY-LISTVAL |
| 481 | CALLED_FORM | `V_CALLED_FORM (dynamic, PU EXECUTE_FUNCTION)` | FUNCS (Page Functions list) | 1120 | – | TODO | functions of the module in SC_SYSTEM_OBJECTS unknown (inventory §15 #9) |
| 482 | CALLED_FORM | `calendar forms (INTRFACE.DISP_CALENDAR / DISP_DATE_CON)` | hijri-date-default date columns | 1120 | – | MAPPED | date KEY-LISTVAL / KEY-F4 |
| 483 | PROGRAM_UNIT | `CHECK_TIMEOUT` | – | – | – | DROPPED | not called by active code (NIB wrapper / Designer check / query-mode toggle) |
| 484 | PROGRAM_UNIT | `MOUSE_CLICK` | – | – | – | DROPPED | f345 Page Functions (FUNCS) |
| 485 | PROGRAM_UNIT | `TOGGEL_WND` | – | – | – | DROPPED | not called by active code (NIB wrapper / Designer check / query-mode toggle) |
| 486 | PROGRAM_UNIT | `PRINT_REPORT` | – | – | – | DROPPED | not called by active code (NIB wrapper / Designer check / query-mode toggle) |
| 487 | PROGRAM_UNIT | `EXECUTE_FUNCTION` | – | – | – | DROPPED | f345 Page Functions (FUNCS) |
| 488 | PROGRAM_UNIT | `TERMINATE_FUN` | – | – | – | DROPPED | not called by active code (NIB wrapper / Designer check / query-mode toggle) |
| 489 | PROGRAM_UNIT | `CHECK_EDI_MSG_LOV` | – | – | – | DROPPED | not called by active code (NIB wrapper / Designer check / query-mode toggle) |
| 490 | PROGRAM_UNIT | `CHECK_EDI_MSG_TIMER` | – | – | – | DROPPED | not called by active code (NIB wrapper / Designer check / query-mode toggle) |
| 491 | PROGRAM_UNIT | `CHECK_EDI_ROLE_ID` | – | – | – | DROPPED | not called by active code (NIB wrapper / Designer check / query-mode toggle) |
| 492 | PROGRAM_UNIT | `EDI_MSG_LOV` | – | – | – | DROPPED | not called by active code (NIB wrapper / Designer check / query-mode toggle) |
| 493 | PROGRAM_UNIT | `FOR_EDI_MSG` | – | – | – | DROPPED | not called by active code (NIB wrapper / Designer check / query-mode toggle) |
| 494 | PROGRAM_UNIT | `RETURN_MSG` | – | – | – | DROPPED | not called by active code (NIB wrapper / Designer check / query-mode toggle) |
| 495 | PROGRAM_UNIT | `TURN_MSG` | – | – | – | DROPPED | not called by active code (NIB wrapper / Designer check / query-mode toggle) |
| 496 | PROGRAM_UNIT | `WHEN_TIMER_EXPIRED_MSG` | – | – | – | DROPPED | not called by active code (NIB wrapper / Designer check / query-mode toggle) |
| 497 | PROGRAM_UNIT | `CG$WHEN_NEW_FORM_INSTANCE` | – | – | – | DROPPED | lists + block-sync startup -> shared LOVs / native master-detail |
| 498 | PROGRAM_UNIT | `CGDV$POPULATE_DYNAMIC_LISTS` | – | – | – | DROPPED | shared LOVs on CG_REF_CODES |
| 499 | PROGRAM_UNIT | `CGFK$QRY_IMPORTERS_IMP_SDP_FK` | – | 1120 | IMPR1120.CGFK$QRY_IMPORTERS_IMP_SDP_FK | MAPPED | same name; called by IMPORTERS_POST_QUERY |
| 500 | PROGRAM_UNIT | `CGFK$CHK_IMPORTERS_IMP_SDP_FK` | – | – | – | DROPPED | not called by active code (NIB wrapper / Designer check / query-mode toggle) |
| 501 | PROGRAM_UNIT | `CG$IMPR1120_GLOBALS` | – | – | – | DROPPED | Designer dynamic WHERE holder |
| 502 | PROGRAM_UNIT | `CGFK$QRY_IMPORTERS_IMP_ITIDT_F` | – | 1120 | IMPR1120.CGFK$QRY_IMPORTERS_IMP_ITIDT_F | MAPPED | same name; called by IMPORTERS_POST_QUERY |
| 503 | PROGRAM_UNIT | `CGFK$CHK_IMPORTERS_IMP_ITIDT_F` | – | – | – | DROPPED | with IMPR_TYPE_CD WHEN-VALIDATE-ITEM (item display only) |
| 504 | PROGRAM_UNIT | `CGFK$QRY_IMPORTERS_IMP_CTRY_FK` | – | 1120 | IMPR1120.CGFK$QRY_IMPORTERS_IMP_CTRY_FK | MAPPED | same name; called by IMPORTERS_POST_QUERY |
| 505 | PROGRAM_UNIT | `CGFK$CHK_IMPORTERS_IMP_CTRY_FK` | – | – | – | DROPPED | not called by active code (NIB wrapper / Designer check / query-mode toggle) |
| 506 | PROGRAM_UNIT | `CGFK$QRY_IMPORTERS_IMP_BUS_ID_` | – | 1120 | IMPR1120.CGFK$QRY_IMPORTERS_IMP_BUS_ID_ | MAPPED | same name; called by IMPORTERS_POST_QUERY |
| 507 | PROGRAM_UNIT | `CGFK$CHK_IMPORTERS_IMP_BUS_ID_` | – | – | – | DROPPED | not called by active code (NIB wrapper / Designer check / query-mode toggle) |
| 508 | PROGRAM_UNIT | `CGFK$CHK_IMPR_SUSPN_IS_1_IMP_F` | – | – | – | DROPPED | not called by active code (NIB wrapper / Designer check / query-mode toggle) |
| 509 | PROGRAM_UNIT | `CGUV$CHK_IS_1_PK` | – | – | – | DROPPED | not called by active code (NIB wrapper / Designer check / query-mode toggle) |
| 510 | PROGRAM_UNIT | `CGTE$CHECK_CONSTRAINT_VIO` | – | – | – | DROPPED | APP_ERROR_HANDLER |
| 511 | PROGRAM_UNIT | `CGBS$TOGGLE` | – | – | – | DROPPED | not called by active code (NIB wrapper / Designer check / query-mode toggle) |
| 512 | PROGRAM_UNIT | `CGBS$SET_QUERY_MODE` | – | – | – | DROPPED | not called by active code (NIB wrapper / Designer check / query-mode toggle) |
| 513 | PROGRAM_UNIT | `CGBS$MESSAGE_QUERY_MODE` | – | – | – | DROPPED | not called by active code (NIB wrapper / Designer check / query-mode toggle) |
| 514 | PROGRAM_UNIT | `EXEC_FUNS` | – | – | – | DROPPED | empty in Forms |
| 515 | PROGRAM_UNIT | `ADJ_FUNS` | – | – | – | DROPPED | empty in Forms |


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
