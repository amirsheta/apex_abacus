# IMPR1125 – APEX 21.2 Page Specification (step 03, revision 1)

| Item | Value |
|---|---|
| Form | `IMPR1125.fmb` (module `IMPR1125_CENTRAL`) — "صيانة توقيفات المستوردين" (central suspensions) |
| Date | 2026-11-24 |
| Application | 202530 (installed from f345, ID offset 460632461717563830), page group `IMPR` |
| Pages | **1125** `IMPR1125` (main) · **112501** `IMPR1125_SEARCH` (modal search) · **112502** `IMPR1125_DELETED_SUSPENSIONS` (modal, released suspensions) |
| Package | `LIB_APX_USR.IMPR1125` version **001** (step 02, no change in this step) |
| Inputs | [inventory](IMPR1125_inventory.md), [logic extraction](IMPR1125_logic_extraction.md), [package spec](../../plsql/IMPR1125/impr1125_spec.sql), `docs/f345_reference_standard.md`, the IMPR1120 design (same frame and grid pattern) |
| Generated parts | §14 and `registry/IMPR1125_registry.sql` are built by `work/IMPR1125/step03/build_trace.py` from the XML (edit `work/IMPR1125/step03/spec_manual.md` or the script, then re-run) |
| Status | design; export generated in step 04; the package is **not compiled** |

---

## 0. Decisions that shape the page

1. **Master-detail on one page (AGR1100 / IMPR1120 pattern).** `HQ_IMPRS` becomes a **Form region** keyed by ROWID with **no Process form**: Forms ON-INSERT / ON-UPDATE / ON-DELETE are `NULL`, so nothing is ever written to `HQ_IMPRS`. `IMPR_CNTRL_SUSPNS` becomes an **editable Interactive Grid** filtered by `HQ_IMPR_NBR` (relation `CGFK$ICS_HI_FK`).
2. **Record key = HQ_IMPRS ROWID in `P0_PAGE_PK`.** It is set by the search page link, or by typing the unified number (`HQ_IMPR_NBR`) or the business id (`BUS_ID`) → processes `HQ_IMPR_NBR EXECUTE-QUERY` / `BUS_ID EXECUTE-QUERY`. They replace `:GLOBAL.HQ_IMPR_NBR / BUS_NBR` and the block WHEN-NEW-ITEM-INSTANCE `EXECUTE_QUERY`.
3. **Page 0 requests on this page** (page 0 is not changed):

   | Request | Shown when | Page 1125 does |
   |---|---|---|
   | `CREATE` | `P0_PAGE_PK` is null | the same as typing the number: the `EXECUTE-QUERY` processes open the importer (no insert of `HQ_IMPRS`) |
   | `SAVE` | `P0_PAGE_PK` is set | saves the grid (`IMPR_CNTRL_SUSPNS - Save Interactive Grid Data`) |
   | `DELETE` | `P0_PAGE_PK` is set | refused by `PRE-DELETE` (`IMPR1125.PRE_DELETE`): block Delete Allowed = No |
   | `SEARCH` | `P0_PAGE_PK` is null | opens 112501 |

4. **Grid DML is one package call per row** (`IMPR1125.IMPR_CNTRL_SUSPNS_SAVE_ROW`, IG DML Target Type PL/SQL Code), as IMPR1120: C = PRE-INSERT → INSERT → POST-INSERT, U = PRE-UPDATE → UPDATE, D = ON-DELETE (soft delete).
5. **Fixed values kept.** `SUSPN_RSN_CD` has no canvas in Forms → hidden column, default **1**. `SUSPN_SIDE_CD` is display only (OLB class `CGSO$COMBO_DO`) → read-only select list, default **5**. No `CURRENT_SIDE` rules (the parameter is read nowhere).
6. **Hijri dates as text, one format** (`FORMS_APX.HIJRI_DATE_FORMAT`, Application Setting), class `hijri-date-default`, as IMPR1120.
7. **Validations skip unchanged stored values** (Forms WHEN-VALIDATE-ITEM fires only on change), as IMPR1120.
8. **Released suspensions question (POST-QUERY → `DELETE_SUSPS_LOV`).** After the importer is loaded, a page-load DA (server condition `IMPR1125.RELEASED_SUSPENSIONS_EXIST`) asks the Forms question with a native **Confirm**; on OK it opens dialog 112502. The dialog URL is computed on the server (`APEX_PAGE.GET_URL`, item with checksum) and opened with **one** JavaScript line `apex.navigation.redirect($v('P1125_DELETED_SUSPENSIONS_URL'));`, the pattern of IMPR1110's dialog 111002. This is the only JavaScript action (§10); it needs the user's approval (CLAUDE.md §4c).

## 1. Page type decision per block

| Forms block | Characteristics | APEX 21.2 | Template / classes | Reason |
|---|---|---|---|---|
| `HQ_IMPRS` | single record, base table, delete not allowed, ON-INSERT / ON-UPDATE / ON-DELETE `NULL`, only BUS_ID / HQ_IMPR_NBR enterable: a search header | **Form region** `HQ_IMPRS`, primary key ROWID, **no Process form** | Interactive Report (`11621909206693869707`), `zatca-forms cg-form cg-card` | decision table row 1, never written |
| `HQ_IMPRS` Enter / Execute Query + LOV form `LOV_IMPORT_HQ_NBR` | QBE + importer list on `SINGLE_IMPORTERS` | search page **112501** | Blank with Attributes `zatca-forms cg-form` + Standard IG | f345 `<page>01` |
| `IMPR_CNTRL_SUSPNS` | multi record (9 shown), base table, insert / update / delete, detail of HQ_IMPRS | **editable Interactive Grid** `IMPR_CNTRL_SUSPNS` | Standard (`11621913486616869708`), `#DEFAULT#:t-Region--noPadding`, `cg-card cg-grid` | master single-record + detail multi-record |
| LOV form `LOV_DELETE_IMP_SUSP` | read-only list of released suspensions | modal page **112502**, read-only IG | Standard IG | f345 `<page>02` |
| `TITLE` | OLB title | hero region `HQ_IMPRS_HERO` | Blank with Attributes, `cg-hero` | f345 |
| `LSIDE` | OLB side function menu | page 0 `FUNCS` drawer (not on the form page) | – | CLAUDE.md §4a #5 |
| `TOOLBAR` | OLB toolbar | page 0 toolbar `P0_ACTIONS` | – | f345 |
| `EDI_MSG` | OLB EDI ticker | dropped | – | timers dropped (IMPR1110 decision) |

## 2. Pages

| Page | Name / alias | Mode | Page template | Title | CSS / protection | Source | Menu role | Navigation menu |
|---|---|---|---|---|---|---|---|---|
| 1125 | `IMPR1125` / `IMPR1125` | Normal | Zatca-Minimal_No_Navigation (`11622270914969205733`) | `&SYS_ANAME.` | `zf` / `C` | `CG$PAGE_1` / `CGSO$WINDOW_1` | none in the form (privileges: application, CLAUDE.md §8) | entry under IMPR, as IMPR1120 |
| 112501 | `IMPR1125_SEARCH` / `IMPR1125-SEARCH` | Modal Dialog 1800 × 800 | theme default for dialogs | `&SYS_ANAME.` | `zf` / `C` | Enter-Query of HQ_IMPRS + `LOV_IMPORT_HQ_NBR` | as 1125 | no |
| 112502 | `IMPR1125_DELETED_SUSPENSIONS` / `IMPR1125-DELETED-SUSPENSIONS` | Modal Dialog 1100 × 500 | theme default for dialogs | `&SYS_ANAME.` | `zf` / `C` | `LOV_DELETE_IMP_SUSP` (title "قائمة الأيقافات المحذوفة") | as 1125 | no |

Page 112502 has process `G_LAST_PAGE KEEP` (After Header, `:G_LAST_PAGE := 1125;`), otherwise f345 SCREEN ENTRY RESET clears the open record when the user returns (f345 standard §4).

## 3. Regions

### Page 1125

| Seq | Region (Static ID) | Type | Source | Primary key | Template / CSS | Edit | Forms block |
|---|---|---|---|---|---|---|---|
| 10 | `HQ_IMPRS_HERO` | Static Content | item `P1125_HERO_TITLE` | – | Blank with Attributes, `cg-hero` | – | `TITLE` |
| 20 | `HQ_IMPRS` – "بيانات المستورد الموحد" | **Form** | Table `HQ_IMPRS` | **ROWID** → `P1125_ROW_ID` | Interactive Report, `zatca-forms cg-form cg-card` | none | `HQ_IMPRS` |
| 30 | `IMPR_CNTRL_SUSPNS` – "توقيفات المستوردين المركزية" | **Interactive Grid**, editable | SQL below | `HQ_IMPR_NBR`, `SUSPN_SEQ` | Standard, `#DEFAULT#:t-Region--noPadding`, `cg-card cg-grid` | Add, Update, Delete | `IMPR_CNTRL_SUSPNS` |

```sql
SELECT s.hq_impr_nbr,
       s.suspn_seq,
       TO_CHAR(s.suspn_strt_dt, (SELECT FORMS_APX.HIJRI_DATE_FORMAT FROM dual)) AS suspn_strt_dt,
       TO_CHAR(s.suspn_end_dt,  (SELECT FORMS_APX.HIJRI_DATE_FORMAT FROM dual)) AS suspn_end_dt,
       s.suspn_rsn_cd,
       s.suspn_rsn_text,
       s.suspn_side_cd
  FROM impr_cntrl_suspns s
 WHERE s.hq_impr_nbr = :P1125_HQ_IMPR_NBR      -- relation CGFK$ICS_HI_FK
   AND s.suspn_rlse_dt IS NULL                 -- block WHERE clause
 ORDER BY s.suspn_seq
```

- Page Items to Submit `P1125_HQ_IMPR_NBR`; server-side condition `P0_PAGE_PK` is not null.
- IG attributes as IMPR1120 (`i:u:d`, lost update check VALUES, no row added when empty); 9 rows per page (Forms Records Displayed = 9).

### Page 112501 – IMPR1125_SEARCH

| Seq | Region | Type | Content | Forms source |
|---|---|---|---|---|
| 10 | `HQ_IMPRS_SEARCH_CRITERIA` | Static Content | `P112501_SEARCH`, buttons `SEARCH`, `CLEAR` (Defined by DA) | QBE of HQ_IMPRS / LOV form criteria |
| 20 | `HQ_IMPRS_SEARCH` | IG, not editable, lazy loading, no total row count | SQL below | `LOV_IMPORT_HQ_NBR` block `SING_IMP` |

```sql
-- one search text over every shown column; no rows until a search is made (as IMPR1120)
SELECT TRANSLATE(ROWIDTOCHAR(h.ROWID), '+/', '-_') AS row_id,   -- URL-safe ROWID of HQ_IMPRS
       s.arbc_impr_name, h.hq_impr_nbr, s.bus_id, s.bus_id_brnch
  FROM single_importers s, hq_imprs h
 WHERE :P112501_SEARCH IS NOT NULL
   AND h.hq_impr_nbr = s.hq_impr_nbr                   -- only unified importers that exist in HQ_IMPRS
   AND INSTR(UPPER(s.arbc_impr_name || '|' || h.hq_impr_nbr || '|' || s.bus_id || '|' || s.bus_id_brnch),
             UPPER(TRIM(:P112501_SEARCH))) > 0
```

- Link column `HQ_IMPR_NBR` → page 1125, clear cache 1125, `P0_PAGE_PK = &ROW_ID.` (checksum; `P0_PAGE_PK_CHECK` restores the ROWID).
- The LOV form lists `SINGLE_IMPORTERS` rows (one unified importer may appear more than once, as in Forms).

### Page 112502 – IMPR1125_DELETED_SUSPENSIONS

| Seq | Region | Type | Content | Forms source |
|---|---|---|---|---|
| 10 | `IMPR_CNTRL_SUSPNS_DELETED` – "قائمة الأيقافات المحذوفة" | IG, not editable | SQL below | `LOV_DELETE_IMP_SUSP` block `IMPR_CNTRL_SUSPNS` |
| 20 | `CTRL_BLK` | Static Content | button `PB_CANCEL` (إغلاق) | `LOV_DELETE_IMP_SUSP` CTRL_BLK |

```sql
SELECT TO_CHAR(s.suspn_strt_dt, (SELECT FORMS_APX.HIJRI_DATE_FORMAT FROM dual)) AS suspn_strt_dt,
       TO_CHAR(s.suspn_end_dt,  (SELECT FORMS_APX.HIJRI_DATE_FORMAT FROM dual)) AS suspn_end_dt,
       TO_CHAR(s.suspn_rlse_dt, (SELECT FORMS_APX.HIJRI_DATE_FORMAT FROM dual)) AS suspn_rlse_dt,
       sd.rv_meaning AS suspn_side_cd,
       rs.rv_meaning AS suspn_rsn_cd,
       s.suspn_rsn_text,
       s.suspn_seq
  FROM impr_cntrl_suspns s, cg_ref_codes sd, cg_ref_codes rs
 WHERE s.suspn_rlse_dt IS NOT NULL
   AND s.hq_impr_nbr = :P112502_P_HQ_IMPR_NBR          -- :PARAMETER.P_HQ_IMPR_NBR
   AND sd.rv_domain (+) = 'SUSPN SIDE CD'     AND sd.rv_low_value (+) = TO_CHAR(s.suspn_side_cd)
   AND rs.rv_domain (+) = 'IMPR_SUSPN_RSN_CD' AND rs.rv_low_value (+) = TO_CHAR(s.suspn_rsn_cd)
 ORDER BY s.suspn_seq
```

## 4. Items

### 4.1 Page 1125 – region `HQ_IMPRS` (Forms tab order)

| Page item | Source column | Type | Label | Read Only | Forms item |
|---|---|---|---|---|---|
| `P1125_ROW_ID` | ROWID (primary key) | Hidden | – | – | key mode ROWID |
| `P1125_BUS_ID` | BUS_ID | Text Field (max 15) | الرقم الاستدلالى | Item `P0_PAGE_PK` is not null | `HQ_IMPRS.BUS_ID` (search key) |
| `P1125_BUS_ID_TYPE_CD` | BUS_ID_TYPE_CD | Display Only | نوعه | always | `HQ_IMPRS.BUS_ID_TYPE_CD` |
| `P1125_BUS_ID_TYPE_NAME` | – | Display Only | – | always | `HQ_IMPRS.BUS_ID_TYPE_NAME` (POST-QUERY) |
| `P1125_BUS_ID_BRNCH` | BUS_ID_BRNCH | Display Only | الرقم الاستدلالي الفرعي | always | `HQ_IMPRS.BUS_ID_BRNCH` |
| `P1125_HQ_IMPR_NBR` | HQ_IMPR_NBR | Number Field (max 11, `number_only`) | الرقم الموحد | Item `P0_PAGE_PK` is not null | `HQ_IMPRS.HQ_IMPR_NBR` (search key, Update Allowed = No) |
| `P1125_CITY_CODE_OF_ID` | – | Display Only | مصدر الرقم الإستدلالي | always | `HQ_IMPRS.CITY_CODE_OF_ID` (POST-QUERY) |
| `P1125_CITY_CODE_OF_NAME` | – | Display Only | – | always | `HQ_IMPRS.CITY_CODE_OF_NAME` |
| `P1125_IMPR_TYPE_CD` | – | Display Only | رمز النشاط التجاري | always | `HQ_IMPRS.IMPR_TYPE_CD` |
| `P1125_IMPR_TYPE_NAME` | – | Display Only | – | always | `HQ_IMPRS.IMPR_TYPE_NAME` |
| `P1125_IMPR_EXPR_TYPE` | – | Display Only based on `LOV_ALLOWED_EXPORT` | النشاط الجمركي | always | `HQ_IMPRS.IMPR_EXPR_TYPE` |
| `P1125_CTRY_CD` | – | Display Only | الجنسيه | always | `HQ_IMPRS.CTRY_CD` |
| `P1125_CRTY_ARBC_NAME` | – | Display Only | – | always | `HQ_IMPRS.CRTY_ARBC_NAME` |
| `P1125_ARBC_IMPR_NAME` | – | Display Only | الاسم العربى | always | `HQ_IMPRS.ARBC_IMPR_NAME` |
| `P1125_ENG_IMPR_NAME` | – | Display Only | الاسم الأجنبي | always | `HQ_IMPRS.ENG_IMPR_NAME` |

The Forms prompts' tatweel padding is dropped. `BUT_SH_HQNUM` (LOV button) → page 0 SEARCH.

### 4.2 Page 1125 – other items

| Item | Type | Purpose | Source |
|---|---|---|---|
| `P1125_HERO_TITLE` | Hidden | screen title (`HEADER TITLE`) | `TITLE` block |
| `P1125_MODULE_ID` | Hidden, protection S | f345 | `:PARAMETER.P_MODULE_ID` |
| `P1125_DELETED_SUSPENSIONS_URL` | Hidden, Value Protected | URL of dialog 112502 (computation §9) | `DELETE_SUSPS_LOV` CALL_FORM |

### 4.3 Page 1125 – IG `IMPR_CNTRL_SUSPNS` columns (Forms navigation order)

| Column | Type | Heading | Required | Default | LOV | Max | Read Only | Forms item |
|---|---|---|---|---|---|---|---|---|
| `SUSPN_STRT_DT` | Text Field, `hijri-date-default` | بداية الإيقاف | Yes | – | – | 10 | – | `SUSPN_STRT_DT` |
| `SUSPN_END_DT` | Text Field, `hijri-date-default` | نهاية الإيقاف | No | – | – | 10 | – | `SUSPN_END_DT` |
| `HQ_IMPR_NBR` | Hidden, primary key | – | – | Item `P1125_HQ_IMPR_NBR` | – | – | – | `HQ_IMPR_NBR` (CopyValueFrom; save call `NVL(:HQ_IMPR_NBR, :P1125_HQ_IMPR_NBR)`) |
| `SUSPN_SEQ` | Hidden, primary key | – | – | – | – | – | – | `SUSPN_SEQ` (PRE-INSERT) |
| `SUSPN_RSN_CD` | Hidden | – | – | Static **1** | – | – | – | `SUSPN_RSN_CD` (no canvas) |
| `SUSPN_RSN_TEXT` | Text Field | ملاحظات | Yes | – | – | 50 | – | `SUSPN_RSN_TEXT` |
| `SUSPN_SIDE_CD` | Select List | الجهة | – | Static **5** | `LOV_SUSPN_SIDE_CD` (from IMPR1120) | – | **Always** | `SUSPN_SIDE_CD` (display only) |

### 4.4 Page 112501 / 112502 items

| Item | Type | Purpose |
|---|---|---|
| `P112501_SEARCH` | Text Field, label "بحث في كل الأعمدة" | search text |
| `P112502_P_HQ_IMPR_NBR` | Hidden, Value Protected, set by the URL with checksum | `:PARAMETER.P_HQ_IMPR_NBR` of `LOV_DELETE_IMP_SUSP` |

## 5. Buttons

No buttons on 1125 (page 0 toolbar). Page 112501: `SEARCH` (`fa-search`, `cg-b-search`) and `CLEAR` (`fa-eraser`, `cg-b-clear`), Defined by DA, as IMPR1120. Page 112502: `PB_CANCEL` "إغلاق" (`fa-times`, `cg-b-clear`), Defined by DA → native Cancel Dialog (LOV form PB_CANCEL / PB_OK: the list returns nothing).

## 6. LOVs

| Forms LOV / list | APEX LOV | Used by | Notes |
|---|---|---|---|
| list `IMPR_EXPR_TYPE` (`ALLOWED EXPORT`) | `LOV_ALLOWED_EXPORT` (from IMPR1110) | `P1125_IMPR_EXPR_TYPE` | reused |
| list `SUSPN_SIDE_CD` (`SUSPN SIDE CD`) | `LOV_SUSPN_SIDE_CD` (from IMPR1120, `LOV_APX.REFERENCE_CODES`) | IG `SUSPN_SIDE_CD` | reused |
| list `SUSPN_RSN_CD` (`IMPR_SUSPN_RSN_CD`) | – | – | column hidden (no canvas); meaning shown on 112502 by a join |
| `CGFK$HQ_IMPRS_BUS_ID_TYPE_CD` | – | – | item display only; name by POST-QUERY |

No new LOV. The export requires IMPR1110 and IMPR1120 to be installed first (as IMPR1120 requires IMPR1110).

## 7. Validations

| Validation | Level | Code | Condition | Source |
|---|---|---|---|---|
| `HQ_IMPR_NBR VALIDATION` | item `P1125_HQ_IMPR_NBR` | `return IMPR1125.HQ_IMPR_NBR_VALIDATION(P_HQ_IMPR_NBR => :P1125_HQ_IMPR_NBR);` | `:REQUEST IN ('EXECUTE_QUERY', 'CREATE')` | HQ_IMPR_NBR.WVI |
| `BUS_ID VALIDATION` | item `P1125_BUS_ID` | `return IMPR1125.BUS_ID_VALIDATION(P_BUS_ID => :P1125_BUS_ID);` | `:REQUEST IN ('EXECUTE_QUERY', 'CREATE') AND :P1125_HQ_IMPR_NBR IS NULL` | BUS_ID.WVI |
| `IMPR_CNTRL_SUSPNS SUSPN_STRT_DT VALIDATION` | IG row | `return IMPR1125.SUSPN_STRT_DT_VALIDATION(SUSPN_STRT_DT => :SUSPN_STRT_DT, HQ_IMPR_NBR => :HQ_IMPR_NBR, SUSPN_SEQ => :SUSPN_SEQ);` | `:APEX$ROW_STATUS IN ('C', 'U')` | SUSPN_STRT_DT.WVI |
| `IMPR_CNTRL_SUSPNS SUSPN_END_DT VALIDATION` | IG row | `return IMPR1125.SUSPN_END_DT_VALIDATION(SUSPN_STRT_DT => :SUSPN_STRT_DT, SUSPN_END_DT => :SUSPN_END_DT, HQ_IMPR_NBR => :HQ_IMPR_NBR, SUSPN_SEQ => :SUSPN_SEQ);` | same | SUSPN_END_DT.WVI |

Required columns (`SUSPN_STRT_DT`, `SUSPN_RSN_TEXT`) use *Value Required*.

## 8. Processes

### Page 1125

| Point | Seq | Process | Code (one line) | Condition | Source |
|---|---|---|---|---|---|
| Before Header | 10 | `New` | f345 session setup (condition Never, as AGR1100) | Never | f345 §6 |
| Before Header | 20 | `P0_PAGE_PK CHECK` | `IMPR1125.P0_PAGE_PK_CHECK(P_PAGE_PK => :P0_PAGE_PK);` | – | f345 |
| Before Header | 40 | `PARAMETERS` | `:P1125_MODULE_ID := FORMS_APX.GET_MODULE_ID(P_MODULE_ID => :P1125_MODULE_ID, FORM_NAME => 'IMPR1125');` | – | f345 |
| Before Header | 70 | `P0_PAGE_PK` | `:P1125_ROW_ID := :P0_PAGE_PK;` | – | f345 |
| Before Header | 80 | `Initialize form` | NATIVE_FORM_INIT, region `HQ_IMPRS` | – | block fetch |
| Before Header | 82 | `POST-QUERY` | `IMPR1125.HQ_IMPRS_POST_QUERY(P_HQ_IMPR_NBR => :P1125_HQ_IMPR_NBR, P_BUS_ID_TYPE_CD => :P1125_BUS_ID_TYPE_CD, P_BUS_ID_TYPE_NAME => :P1125_BUS_ID_TYPE_NAME, P_ARBC_IMPR_NAME => :P1125_ARBC_IMPR_NAME, P_ENG_IMPR_NAME => :P1125_ENG_IMPR_NAME, P_CTRY_CD => :P1125_CTRY_CD, P_IMPR_TYPE_CD => :P1125_IMPR_TYPE_CD, P_IMPR_EXPR_TYPE => :P1125_IMPR_EXPR_TYPE, P_CITY_CODE_OF_ID => :P1125_CITY_CODE_OF_ID, P_CRTY_ARBC_NAME => :P1125_CRTY_ARBC_NAME, P_CITY_CODE_OF_NAME => :P1125_CITY_CODE_OF_NAME, P_IMPR_TYPE_NAME => :P1125_IMPR_TYPE_NAME);` | `P1125_ROW_ID` is not null | HQ_IMPRS.POST-QUERY |
| Before Header | 100 | `HEADER TITLE` | `FORMS_APX.HEADER_TITLE(P_MODULE_ID => :P1125_MODULE_ID, P_HERO_TITLE => :P1125_HERO_TITLE, DEFAULT_TITLE => 'صيانة توقيفات المستوردين');` | – | f345 |
| After Submit | 10 | `HQ_IMPR_NBR EXECUTE-QUERY` | `IMPR1125.HQ_IMPR_NBR_WHEN_VALIDATE_ITEM(P_HQ_IMPR_NBR => :P1125_HQ_IMPR_NBR, P_PAGE_PK => :P0_PAGE_PK);` | `:REQUEST IN ('EXECUTE_QUERY','CREATE') AND :P1125_HQ_IMPR_NBR IS NOT NULL` | HQ_IMPR_NBR.WVI → block WNII EXECUTE_QUERY |
| After Submit | 15 | `BUS_ID EXECUTE-QUERY` | `IMPR1125.BUS_ID_WHEN_VALIDATE_ITEM(P_BUS_ID => :P1125_BUS_ID, P_PAGE_PK => :P0_PAGE_PK);` | `:REQUEST IN ('EXECUTE_QUERY','CREATE') AND :P1125_HQ_IMPR_NBR IS NULL` | BUS_ID.WVI → block WNII |
| After Submit | 30 | `PRE-DELETE` | `IMPR1125.PRE_DELETE;` | request DELETE | block Delete Allowed = No |
| After Submit | 110 | `IMPR_CNTRL_SUSPNS - Save Interactive Grid Data` | NATIVE_IG_DML, PL/SQL Code: `IMPR1125.IMPR_CNTRL_SUSPNS_SAVE_ROW(APEX$ROW_STATUS => :APEX$ROW_STATUS, HQ_IMPR_NBR => NVL(:HQ_IMPR_NBR, :P1125_HQ_IMPR_NBR), SUSPN_SEQ => :SUSPN_SEQ, SUSPN_STRT_DT => :SUSPN_STRT_DT, SUSPN_END_DT => :SUSPN_END_DT, SUSPN_RSN_CD => :SUSPN_RSN_CD, SUSPN_RSN_TEXT => :SUSPN_RSN_TEXT, SUSPN_SIDE_CD => :SUSPN_SIDE_CD, P_BUS_ID => :P1125_BUS_ID, P_CURR_PORT_CD => :P_CURR_PORT_CD, SSO_APP_USER => :SSO_APP_USER, P_GLOBAL_V_WS_ID => :P_GLOBAL_V_WS_ID);` | request SAVE | PRE-INSERT, POST-INSERT, PRE-UPDATE, ON-DELETE |

Branches as IMPR1120: `EXECUTE-QUERY` (requests EXECUTE_QUERY, CREATE: clear cache 1125, P0_PAGE_PK kept) and "stay in the form".

### Page 112502

| Point | Seq | Process | Code |
|---|---|---|---|
| After Header | 10 | `G_LAST_PAGE KEEP` | `:G_LAST_PAGE := 1125;` |

## 9. Computations

| Item | Point | Type | Expression | Source |
|---|---|---|---|---|
| `P1125_DELETED_SUSPENSIONS_URL` | After Header | PL/SQL Expression | `CASE WHEN :P1125_HQ_IMPR_NBR IS NOT NULL THEN APEX_PAGE.GET_URL(p_page => 112502, p_clear_cache => '112502', p_items => 'P112502_P_HQ_IMPR_NBR', p_values => :P1125_HQ_IMPR_NBR) END` | `DELETE_SUSPS_LOV` (CALL_FORM with P_HQ_IMPR_NBR); same pattern as IMPR1110 `P1110_MOBILE_URL` |

## 10. Dynamic Actions

| DA | Page | Event | Actions | Submit / Return | Source |
|---|---|---|---|---|---|
| `HQ_IMPR_NBR WHEN-VALIDATE-ITEM` | 1125 | Change `P1125_HQ_IMPR_NBR`, not null | FOS `FORMS_APX.CHECK_ERROR(IMPR1125.HQ_IMPR_NBR_VALIDATION(P_HQ_IMPR_NBR => :P1125_HQ_IMPR_NBR));` → Submit Page `EXECUTE_QUERY` | `P1125_HQ_IMPR_NBR` | HQ_IMPR_NBR.WVI + block WNII |
| `BUS_ID WHEN-VALIDATE-ITEM` | 1125 | Change `P1125_BUS_ID`, not null | FOS `FORMS_APX.CHECK_ERROR(IMPR1125.BUS_ID_VALIDATION(P_BUS_ID => :P1125_BUS_ID));` → Submit Page `EXECUTE_QUERY` | `P1125_BUS_ID` | BUS_ID.WVI + block WNII |
| `HQ_IMPRS POST-QUERY` | 1125 | Page Load; server condition `:P0_PAGE_PK IS NOT NULL AND IMPR1125.RELEASED_SUSPENSIONS_EXIST(P_HQ_IMPR_NBR => :P1125_HQ_IMPR_NBR)` | native Confirm "توجد إيقافات محذوفة من على هذا المستورد , هل تود أستعراضها ؟" → **Execute JavaScript Code** (1 line) `apex.navigation.redirect($v('P1125_DELETED_SUSPENSIONS_URL'));` | – | POST-QUERY CONFIRM + DELETE_SUSPS_LOV |
| `IMPR_CNTRL_SUSPNS SUSPN_STRT_DT WHEN-VALIDATE-ITEM` | 1125 | Change column | FOS `FORMS_APX.CHECK_ERROR(IMPR1125.SUSPN_STRT_DT_VALIDATION(...))` | `SUSPN_STRT_DT`, `HQ_IMPR_NBR`, `SUSPN_SEQ` | SUSPN_STRT_DT.WVI |
| `IMPR_CNTRL_SUSPNS SUSPN_END_DT WHEN-VALIDATE-ITEM` | 1125 | Change column | FOS `FORMS_APX.CHECK_ERROR(IMPR1125.SUSPN_END_DT_VALIDATION(...))` | `SUSPN_STRT_DT`, `SUSPN_END_DT`, `HQ_IMPR_NBR`, `SUSPN_SEQ` | SUSPN_END_DT.WVI |
| `SEARCH WHEN-BUTTON-PRESSED`, `SEARCH KEY-ENTER`, `CLEAR WHEN-BUTTON-PRESSED`, `Hide` | 112501 | as IMPR1120 112001 | Refresh / Clear / hide `P0_ACTIONS` | – | TOOLBAR.EXECUTE / CLEAR_ALL |
| `PB_CANCEL WHEN-BUTTON-PRESSED`, `Hide` | 112502 | Click / Page Load | native Cancel Dialog / hide `P0_ACTIONS` | – | LOV form PB_CANCEL |

**Execute JavaScript Code actions: 1** (`HQ_IMPRS POST-QUERY`, 1 line). Reason: APEX 21.2 has no native action that opens a page URL after a Confirm; the URL itself is built on the server with a checksum. Same pattern as IMPR1110's dialog 111002. **Needs the user's approval** (CLAUDE.md §4c). Without it: a button on the page instead of the question.

## 11. Alerts and messages

| Forms alert / message | APEX equivalent | Text |
|---|---|---|
| `CFG_ERROR` (`STR.DISPALERT … 'ERROR'`) | validation error texts (extraction §4) | literal Forms texts |
| `CFG_SYSTEM_ERROR` (ACTIVITY / HIJDATE) | `FORMS_APX.FORM_TRIGGER_FAILURE` | from the DB packages |
| `USR_CONFIRM` (`STR.DispALERT … 'CONFIRM'`) | native Confirm of DA `HQ_IMPRS POST-QUERY` | "توجد إيقافات محذوفة من على هذا المستورد , هل تود أستعراضها ؟" |
| `USR_WARNING_B` (`TMPLT.KEY_DELETE_RECORD`) | IG delete (rows restorable until SAVE) | – |
| FRM-41049 | `PRE_DELETE` | "لا يمكن حذف بيانات المستورد من هذه الشاشة - احذف التوقيف من الجدول" (to confirm) |
| ON-ERROR `ICS_HI_FK` | f345 `APP_ERROR_HANDLER` | the master key always comes from the open importer, so the FK cannot fail from this page |
| other OLB alerts | not used | – |

## 12. Branches and navigation

| Branch / link | Target | Condition | Items | Forms source |
|---|---|---|---|---|
| `EXECUTE-QUERY` (After Processing) | 1125 | request EXECUTE_QUERY, CREATE (clear cache 1125) | – | EXECUTE_QUERY |
| stay in the form | 1125 | otherwise | – | – |
| page 0 SEARCH | 112501 | `P0_PAGE_PK` is null | – | ENTER / EXECUTE, BUT_SH_HQNUM, BUS_ID KEY-LISTVAL |
| link `HQ_IMPR_NBR` on 112501 | 1125 | – | `P0_PAGE_PK = &ROW_ID.` | `LOV_IMPORT_HQ_NBR` selection |
| `P1125_DELETED_SUSPENSIONS_URL` | 112502 (dialog) | Confirm OK | `P112502_P_HQ_IMPR_NBR` (checksum) | `DELETE_SUSPS_LOV` |

## 13. Shared components

- **Reused from f345:** theme 42, page 0 (`P0_ACTIONS`, `P0_PAGE_PK`, FUNCS drawer, NUMBER ONLY), application items `SSO_APP_USER`, `P_CURR_PORT_CD`, `P_GLOBAL_V_WS_ID`, `G_LAST_PAGE`, `SYS_ANAME`, `SCREEN ENTRY RESET`, `APP_ERROR_HANDLER`, plug-in `COM.FOS.EXECUTE_PLSQL_CODE`, Hijri picker class.
- **Reused from IMPR1110 / IMPR1120 exports:** page group `IMPR`, `LOV_ALLOWED_EXPORT`, `LOV_SUSPN_SIDE_CD`.
- **New:** none (no LOV, no application item, no Text Message).

## 14. Traceability matrix (every object of the XML)

455 objects: DROPPED 361, MAPPED 92, TODO 2. By type: ALERT 10, BLOCK 6, CALLED_FORM 4, CANVAS 5, GLOBAL 9, ITEM 103, LIBRARY 17, LOV 1, PARAMETER 22, PROGRAM_UNIT 26, RECORD_GROUP 2, RELATION 1, TRIGGER 248, WINDOW 1.

| # | Type | Forms object | APEX component | Page | Package member | Status | Notes |
|---|---|---|---|---|---|---|---|
| 1 | BLOCK | `TITLE` | HQ_IMPRS_HERO | 1125 | – | MAPPED | OLB title bar -> hero region (HEADER TITLE, FORMS_APX) |
| 2 | BLOCK | `EDI_MSG` | – | – | – | DROPPED | OLB EDI message ticker - dropped (timers, IMPR1110 decision 2026-11-19) |
| 3 | BLOCK | `LSIDE` | FUNCS (page 0 drawer, f345 Page Functions) | 0 | – | MAPPED | OLB side function menu |
| 4 | BLOCK | `TOOLBAR` | P0_ACTIONS (page 0 toolbar, f345) | 0 | – | MAPPED | OLB toolbar -> f345 page 0 toolbar |
| 5 | BLOCK | `HQ_IMPRS` | HQ_IMPRS (Form region, table HQ_IMPRS, primary key ROWID, no Process form) | 1125 | – | MAPPED | master search header; ON-INSERT / ON-UPDATE / ON-DELETE NULL -> never written; search page 112501 |
| 6 | BLOCK | `IMPR_CNTRL_SUSPNS` | IMPR_CNTRL_SUSPNS (editable Interactive Grid) | 1125 | IMPR1125.IMPR_CNTRL_SUSPNS_SAVE_ROW | MAPPED | detail; WHERE SUSPN_RLSE_DT IS NULL; DML through IMPR_CNTRL_SUSPNS_SAVE_ROW (soft delete) |
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
| 76 | ITEM | `TOOLBAR.ENTER` | SEARCH (page 0 toolbar) | 0 | – | MAPPED | Enter Query -> search page 112501 |
| 77 | ITEM | `TOOLBAR.EXECUTE` | SEARCH (page 0 toolbar) | 0 | – | MAPPED | Execute Query -> search page 112501 |
| 78 | ITEM | `TOOLBAR.REMOVE` | DELETE (page 0 toolbar) / IG row delete | 0 | – | MAPPED | importer: refused by PRE-DELETE (Delete Allowed = No); suspension: IG row delete |
| 79 | ITEM | `TOOLBAR.LIST_VALUE` | – | – | – | DROPPED | LOV key -> page 0 SEARCH |
| 80 | ITEM | `TOOLBAR.HELP` | – | – | – | DROPPED | MS-Help obsolete |
| 81 | ITEM | `TOOLBAR.LAST_REC` | – | – | – | DROPPED | OLB toolbar item (record navigation / frame) |
| 82 | ITEM | `TOOLBAR.RE_ENTER_QUERY` | SEARCH (page 0 toolbar) | 0 | – | MAPPED | – |
| 83 | ITEM | `TOOLBAR.FIRST_REC` | – | – | – | DROPPED | OLB toolbar item (record navigation / frame) |
| 84 | ITEM | `TOOLBAR.PAGE_UP` | – | – | – | DROPPED | OLB toolbar item (record navigation / frame) |
| 85 | ITEM | `TOOLBAR.PAGE_DOWN` | – | – | – | DROPPED | OLB toolbar item (record navigation / frame) |
| 86 | ITEM | `TOOLBAR.FUN_BUT` | FUNCS (page 0 toolbar) | 0 | – | MAPPED | – |
| 87 | ITEM | `HQ_IMPRS.BUS_ID` | P1125_BUS_ID | 1125 | – | MAPPED | Text Field, editable only while P0_PAGE_PK is null (search key); sent to the save (SMS text) |
| 88 | ITEM | `HQ_IMPRS.BUT_SH_HQNUM` | SEARCH (page 0 toolbar) -> 112501 | 0 | – | MAPPED | LOV button of BUS_ID (SINGLE_IMP_LOV) |
| 89 | ITEM | `HQ_IMPRS.BUS_ID_TYPE_CD` | P1125_BUS_ID_TYPE_CD | 1125 | – | MAPPED | Display Only |
| 90 | ITEM | `HQ_IMPRS.BUS_ID_TYPE_NAME` | P1125_BUS_ID_TYPE_NAME | 1125 | – | MAPPED | Display Only (POST-QUERY) |
| 91 | ITEM | `HQ_IMPRS.BUS_ID_BRNCH` | P1125_BUS_ID_BRNCH | 1125 | – | MAPPED | Display Only |
| 92 | ITEM | `HQ_IMPRS.HQ_IMPR_NBR` | P1125_HQ_IMPR_NBR | 1125 | – | MAPPED | Number Field, editable only while P0_PAGE_PK is null (search key, Update Allowed = No) |
| 93 | ITEM | `HQ_IMPRS.CITY_CODE_OF_ID` | P1125_CITY_CODE_OF_ID | 1125 | – | MAPPED | Display Only (POST-QUERY) |
| 94 | ITEM | `HQ_IMPRS.CITY_CODE_OF_NAME` | P1125_CITY_CODE_OF_NAME | 1125 | – | MAPPED | Display Only (POST-QUERY) |
| 95 | ITEM | `HQ_IMPRS.IMPR_TYPE_CD` | P1125_IMPR_TYPE_CD | 1125 | – | MAPPED | Display Only (POST-QUERY) |
| 96 | ITEM | `HQ_IMPRS.IMPR_TYPE_NAME` | P1125_IMPR_TYPE_NAME | 1125 | – | MAPPED | Display Only (POST-QUERY) |
| 97 | ITEM | `HQ_IMPRS.IMPR_EXPR_TYPE` | P1125_IMPR_EXPR_TYPE | 1125 | – | MAPPED | Display Only based on LOV_ALLOWED_EXPORT (POST-QUERY) |
| 98 | ITEM | `HQ_IMPRS.CTRY_CD` | P1125_CTRY_CD | 1125 | – | MAPPED | Display Only (POST-QUERY) |
| 99 | ITEM | `HQ_IMPRS.CRTY_ARBC_NAME` | P1125_CRTY_ARBC_NAME | 1125 | – | MAPPED | Display Only (POST-QUERY) |
| 100 | ITEM | `HQ_IMPRS.ARBC_IMPR_NAME` | P1125_ARBC_IMPR_NAME | 1125 | – | MAPPED | Display Only (POST-QUERY) |
| 101 | ITEM | `HQ_IMPRS.ENG_IMPR_NAME` | P1125_ENG_IMPR_NAME | 1125 | – | MAPPED | Display Only (POST-QUERY) |
| 102 | ITEM | `IMPR_CNTRL_SUSPNS.SUSPN_STRT_DT` | IMPR_CNTRL_SUSPNS.SUSPN_STRT_DT | 1125 | – | MAPPED | Text Field (HIJRI_DATE_FORMAT, hijri-date-default), required |
| 103 | ITEM | `IMPR_CNTRL_SUSPNS.SUSPN_END_DT` | IMPR_CNTRL_SUSPNS.SUSPN_END_DT | 1125 | – | MAPPED | Text Field (HIJRI_DATE_FORMAT, hijri-date-default) |
| 104 | ITEM | `IMPR_CNTRL_SUSPNS.HQ_IMPR_NBR` | IMPR_CNTRL_SUSPNS.HQ_IMPR_NBR | 1125 | – | MAPPED | Hidden, primary key (default = master item P1125_HQ_IMPR_NBR; save call NVL) |
| 105 | ITEM | `IMPR_CNTRL_SUSPNS.SUSPN_SEQ` | IMPR_CNTRL_SUSPNS.SUSPN_SEQ | 1125 | – | MAPPED | Hidden, primary key (set by IMPR_CNTRL_SUSPNS_PRE_INSERT) |
| 106 | ITEM | `IMPR_CNTRL_SUSPNS.SUSPN_RSN_CD` | IMPR_CNTRL_SUSPNS.SUSPN_RSN_CD | 1125 | – | MAPPED | Hidden, default 1 (no canvas in Forms) |
| 107 | ITEM | `IMPR_CNTRL_SUSPNS.SUSPN_RSN_TEXT` | IMPR_CNTRL_SUSPNS.SUSPN_RSN_TEXT | 1125 | – | MAPPED | Text Field, required, max 50 |
| 108 | ITEM | `IMPR_CNTRL_SUSPNS.SUSPN_SIDE_CD` | IMPR_CNTRL_SUSPNS.SUSPN_SIDE_CD | 1125 | – | MAPPED | Select List LOV_SUSPN_SIDE_CD, Read Only always, default 5 (CGSO$COMBO_DO) |
| 109 | ITEM | `IMPR_CNTRL_SUSPNS.SUSPN_RLSE_DT` | IMPR_CNTRL_SUSPNS_DELETED.SUSPN_RLSE_DT (page 112502) | 112502 | IMPR1125.IMPR_CNTRL_SUSPNS_ON_DELETE | MAPPED | not a grid column on 1125: set by ON_DELETE; region WHERE SUSPN_RLSE_DT IS NULL |
| 110 | TRIGGER | `FORM.KEY-EDIT` | – | – | – | DROPPED | NIB.KEY_EDIT -> page 0 toolbar / IG keyboard |
| 111 | TRIGGER | `FORM.KEY-DUPREC` | – | – | – | DROPPED | NIB.KEY_DUPREC -> page 0 toolbar / IG keyboard |
| 112 | TRIGGER | `FORM.PRE-FORM` | – | – | – | DROPPED | NIB.PRE_FORM, NLS date setting, help path -> f345 application |
| 113 | TRIGGER | `FORM.WHEN-NEW-FORM-INSTANCE` | – | – | – | DROPPED | NIB / CGBS2$ / CG$WHEN_NEW_FORM_INSTANCE -> f345, LOVs, native master-detail; globals := NULL -> P0_PAGE_PK |
| 114 | TRIGGER | `FORM.WHEN-WINDOW-ACTIVATED` | – | – | – | DROPPED | timers / window / frame (OLB, NIB) |
| 115 | TRIGGER | `FORM.KEY-ENTQRY` | – | – | – | DROPPED | NIB.KEY_ENTQRY -> page 0 toolbar / IG keyboard |
| 116 | TRIGGER | `FORM.ON-ERROR` | APP_ERROR_HANDLER (f345) | – | – | MAPPED | NIB.ON_ERROR |
| 117 | TRIGGER | `FORM.ON-MESSAGE` | APP_ERROR_HANDLER (f345) / page messages | – | – | MAPPED | NIB.ON_MESSAGE |
| 118 | TRIGGER | `FORM.KEY-CLRBLK` | – | – | – | DROPPED | NIB.KEY_CLRBLK -> page 0 toolbar / IG keyboard |
| 119 | TRIGGER | `FORM.KEY-DELREC` | – | – | – | DROPPED | NIB.KEY_DELREC -> page 0 toolbar / IG keyboard |
| 120 | TRIGGER | `FORM.KEY-F5` | – | – | – | DROPPED | NIB.KEY_F5 -> page 0 toolbar / IG keyboard |
| 121 | TRIGGER | `FORM.KEY-F4` | – | – | – | DROPPED | timers / window / frame (OLB, NIB) |
| 122 | TRIGGER | `FORM.KEY-NXTREC` | – | – | – | DROPPED | NIB.KEY_NXTREC -> page 0 toolbar / IG keyboard |
| 123 | TRIGGER | `FORM.KEY-PRVREC` | – | – | – | DROPPED | NIB.KEY_PRVREC -> page 0 toolbar / IG keyboard |
| 124 | TRIGGER | `FORM.KEY-DOWN` | – | – | – | DROPPED | NIB.KEY_DOWN -> page 0 toolbar / IG keyboard |
| 125 | TRIGGER | `FORM.KEY-UP` | – | – | – | DROPPED | NIB.KEY_UP -> page 0 toolbar / IG keyboard |
| 126 | TRIGGER | `FORM.KEY-SCRUP` | – | – | – | DROPPED | NIB.KEY_SCRUP -> page 0 toolbar / IG keyboard |
| 127 | TRIGGER | `FORM.KEY-SCRDOWN` | – | – | – | DROPPED | NIB.KEY_SCRDOWN -> page 0 toolbar / IG keyboard |
| 128 | TRIGGER | `FORM.KEY-PRINT` | – | – | – | DROPPED | NIB.KEY_PRINT -> page 0 toolbar / IG keyboard |
| 129 | TRIGGER | `FORM.KEY-EXIT` | – | – | – | DROPPED | NIB.KEY_EXIT -> page 0 toolbar / IG keyboard |
| 130 | TRIGGER | `FORM.WHEN-MOUSE-DOWN` | – | – | – | DROPPED | timers / window / frame (OLB, NIB) |
| 131 | TRIGGER | `FORM.KEY-EXEQRY` | – | – | – | DROPPED | NIB.KEY_EXEQRY -> page 0 toolbar / IG keyboard |
| 132 | TRIGGER | `FORM.KEY-F9` | FUNCS (page 0 toolbar) | 0 | – | MAPPED | side-menu toggle -> FUNCS |
| 133 | TRIGGER | `FORM.WHEN-TIMER-EXPIRED` | – | – | – | DROPPED | timers / window / frame (OLB, NIB) |
| 134 | TRIGGER | `FORM.KEY-HELP` | – | – | – | DROPPED | MS-Help obsolete |
| 135 | TRIGGER | `FORM.WHEN-NEW-BLOCK-INSTANCE` | – | – | – | DROPPED | Designer master-detail coordination (CGBS$) -> native Form + IG |
| 136 | TRIGGER | `FORM.ON-CLEAR-DETAILS` | – | – | – | DROPPED | Designer master-detail coordination (CGBS$) -> native Form + IG |
| 137 | TRIGGER | `FORM.ON-POPULATE-DETAILS` | – | – | – | DROPPED | Designer master-detail coordination (CGBS$) -> native Form + IG |
| 138 | TRIGGER | `FORM.KEY-CQUERY` | – | – | – | DROPPED | Designer key handler -> page 0 toolbar / IG |
| 139 | TRIGGER | `FORM.KEY-CLRREC` | – | – | – | DROPPED | Designer key handler -> page 0 toolbar / IG |
| 140 | TRIGGER | `FORM.KEY-NXTKEY` | – | – | – | DROPPED | Designer key handler -> page 0 toolbar / IG |
| 141 | TRIGGER | `FORM.KEY-MENU` | – | – | – | DROPPED | Designer key handler -> page 0 toolbar / IG |
| 142 | TRIGGER | `FORM.KEY-CLRFRM` | – | – | – | DROPPED | Designer key handler -> page 0 toolbar / IG |
| 143 | TRIGGER | `TITLE.CGSO$CHAR_ARB_ED.KEY-LISTVAL` | – | – | – | DROPPED | OLB frame (TITLE) |
| 144 | TRIGGER | `TITLE.CGSO$CHAR_ARB_DO_ENB_Y.KEY-LISTVAL` | – | – | – | DROPPED | OLB frame (TITLE) |
| 145 | TRIGGER | `TITLE.CGSO$CHAR_ARB_MLINE.KEY-LISTVAL` | – | – | – | DROPPED | OLB frame (TITLE) |
| 146 | TRIGGER | `TITLE.CGSO$CHAR_ARB.KEY-LISTVAL` | – | – | – | DROPPED | OLB frame (TITLE) |
| 147 | TRIGGER | `TITLE.CGSO$CHAR_ARB_DO.KEY-LISTVAL` | – | – | – | DROPPED | OLB frame (TITLE) |
| 148 | TRIGGER | `TITLE.SYSTEM_DATE.WHEN-VALIDATE-ITEM` | – | – | – | DROPPED | OLB frame (TITLE) |
| 149 | TRIGGER | `EDI_MSG.EDI_MSG_LOVE_BUT.WHEN-BUTTON-PRESSED` | – | – | – | DROPPED | OLB frame (EDI_MSG) |
| 150 | TRIGGER | `LSIDE.FN1.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 151 | TRIGGER | `LSIDE.FN1.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 152 | TRIGGER | `LSIDE.FN1.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 153 | TRIGGER | `LSIDE.FN50.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 154 | TRIGGER | `LSIDE.FN50.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 155 | TRIGGER | `LSIDE.FN50.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 156 | TRIGGER | `LSIDE.FN2.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 157 | TRIGGER | `LSIDE.FN2.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 158 | TRIGGER | `LSIDE.FN2.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 159 | TRIGGER | `LSIDE.FN49.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 160 | TRIGGER | `LSIDE.FN49.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 161 | TRIGGER | `LSIDE.FN49.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 162 | TRIGGER | `LSIDE.FN3.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 163 | TRIGGER | `LSIDE.FN3.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 164 | TRIGGER | `LSIDE.FN3.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 165 | TRIGGER | `LSIDE.FN48.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 166 | TRIGGER | `LSIDE.FN48.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 167 | TRIGGER | `LSIDE.FN48.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 168 | TRIGGER | `LSIDE.FN4.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 169 | TRIGGER | `LSIDE.FN4.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 170 | TRIGGER | `LSIDE.FN4.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 171 | TRIGGER | `LSIDE.FN47.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 172 | TRIGGER | `LSIDE.FN47.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 173 | TRIGGER | `LSIDE.FN47.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 174 | TRIGGER | `LSIDE.FN5.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 175 | TRIGGER | `LSIDE.FN5.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 176 | TRIGGER | `LSIDE.FN5.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 177 | TRIGGER | `LSIDE.FN46.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 178 | TRIGGER | `LSIDE.FN46.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 179 | TRIGGER | `LSIDE.FN46.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 180 | TRIGGER | `LSIDE.FN6.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 181 | TRIGGER | `LSIDE.FN6.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 182 | TRIGGER | `LSIDE.FN6.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 183 | TRIGGER | `LSIDE.FN45.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 184 | TRIGGER | `LSIDE.FN45.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 185 | TRIGGER | `LSIDE.FN45.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 186 | TRIGGER | `LSIDE.FN7.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 187 | TRIGGER | `LSIDE.FN7.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 188 | TRIGGER | `LSIDE.FN7.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 189 | TRIGGER | `LSIDE.FN44.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 190 | TRIGGER | `LSIDE.FN44.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 191 | TRIGGER | `LSIDE.FN44.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 192 | TRIGGER | `LSIDE.FN8.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 193 | TRIGGER | `LSIDE.FN8.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 194 | TRIGGER | `LSIDE.FN8.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 195 | TRIGGER | `LSIDE.FN43.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 196 | TRIGGER | `LSIDE.FN43.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 197 | TRIGGER | `LSIDE.FN43.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 198 | TRIGGER | `LSIDE.FN9.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 199 | TRIGGER | `LSIDE.FN9.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 200 | TRIGGER | `LSIDE.FN9.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 201 | TRIGGER | `LSIDE.FN42.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 202 | TRIGGER | `LSIDE.FN42.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 203 | TRIGGER | `LSIDE.FN42.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 204 | TRIGGER | `LSIDE.FN10.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 205 | TRIGGER | `LSIDE.FN10.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 206 | TRIGGER | `LSIDE.FN10.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 207 | TRIGGER | `LSIDE.FN41.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 208 | TRIGGER | `LSIDE.FN41.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 209 | TRIGGER | `LSIDE.FN41.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 210 | TRIGGER | `LSIDE.FN11.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 211 | TRIGGER | `LSIDE.FN11.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 212 | TRIGGER | `LSIDE.FN11.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 213 | TRIGGER | `LSIDE.FN40.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 214 | TRIGGER | `LSIDE.FN40.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 215 | TRIGGER | `LSIDE.FN40.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 216 | TRIGGER | `LSIDE.FN12.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 217 | TRIGGER | `LSIDE.FN12.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 218 | TRIGGER | `LSIDE.FN12.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 219 | TRIGGER | `LSIDE.FN39.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 220 | TRIGGER | `LSIDE.FN39.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 221 | TRIGGER | `LSIDE.FN39.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 222 | TRIGGER | `LSIDE.FN13.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 223 | TRIGGER | `LSIDE.FN13.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 224 | TRIGGER | `LSIDE.FN13.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 225 | TRIGGER | `LSIDE.FN38.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 226 | TRIGGER | `LSIDE.FN38.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 227 | TRIGGER | `LSIDE.FN38.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 228 | TRIGGER | `LSIDE.FN14.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 229 | TRIGGER | `LSIDE.FN14.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 230 | TRIGGER | `LSIDE.FN14.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 231 | TRIGGER | `LSIDE.FN37.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 232 | TRIGGER | `LSIDE.FN37.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 233 | TRIGGER | `LSIDE.FN37.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 234 | TRIGGER | `LSIDE.FN15.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 235 | TRIGGER | `LSIDE.FN15.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 236 | TRIGGER | `LSIDE.FN15.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 237 | TRIGGER | `LSIDE.FN36.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 238 | TRIGGER | `LSIDE.FN36.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 239 | TRIGGER | `LSIDE.FN36.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 240 | TRIGGER | `LSIDE.FN16.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 241 | TRIGGER | `LSIDE.FN16.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 242 | TRIGGER | `LSIDE.FN16.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 243 | TRIGGER | `LSIDE.FN17.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 244 | TRIGGER | `LSIDE.FN17.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 245 | TRIGGER | `LSIDE.FN17.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 246 | TRIGGER | `LSIDE.FN34.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 247 | TRIGGER | `LSIDE.FN34.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 248 | TRIGGER | `LSIDE.FN34.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 249 | TRIGGER | `LSIDE.FN35.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 250 | TRIGGER | `LSIDE.FN35.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 251 | TRIGGER | `LSIDE.FN35.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 252 | TRIGGER | `LSIDE.FN18.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 253 | TRIGGER | `LSIDE.FN18.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 254 | TRIGGER | `LSIDE.FN18.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 255 | TRIGGER | `LSIDE.FN33.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 256 | TRIGGER | `LSIDE.FN33.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 257 | TRIGGER | `LSIDE.FN33.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 258 | TRIGGER | `LSIDE.FN19.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 259 | TRIGGER | `LSIDE.FN19.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 260 | TRIGGER | `LSIDE.FN19.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 261 | TRIGGER | `LSIDE.FN32.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 262 | TRIGGER | `LSIDE.FN32.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 263 | TRIGGER | `LSIDE.FN32.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 264 | TRIGGER | `LSIDE.FN20.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 265 | TRIGGER | `LSIDE.FN20.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 266 | TRIGGER | `LSIDE.FN20.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 267 | TRIGGER | `LSIDE.FN31.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 268 | TRIGGER | `LSIDE.FN31.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 269 | TRIGGER | `LSIDE.FN31.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 270 | TRIGGER | `LSIDE.FN21.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 271 | TRIGGER | `LSIDE.FN21.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 272 | TRIGGER | `LSIDE.FN21.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 273 | TRIGGER | `LSIDE.FN30.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 274 | TRIGGER | `LSIDE.FN30.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 275 | TRIGGER | `LSIDE.FN30.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 276 | TRIGGER | `LSIDE.FN22.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 277 | TRIGGER | `LSIDE.FN22.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 278 | TRIGGER | `LSIDE.FN22.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 279 | TRIGGER | `LSIDE.FN29.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 280 | TRIGGER | `LSIDE.FN29.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 281 | TRIGGER | `LSIDE.FN29.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 282 | TRIGGER | `LSIDE.FN23.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 283 | TRIGGER | `LSIDE.FN23.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 284 | TRIGGER | `LSIDE.FN23.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 285 | TRIGGER | `LSIDE.FN28.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 286 | TRIGGER | `LSIDE.FN28.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 287 | TRIGGER | `LSIDE.FN28.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 288 | TRIGGER | `LSIDE.FN24.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 289 | TRIGGER | `LSIDE.FN24.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 290 | TRIGGER | `LSIDE.FN24.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 291 | TRIGGER | `LSIDE.FN27.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 292 | TRIGGER | `LSIDE.FN27.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 293 | TRIGGER | `LSIDE.FN27.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 294 | TRIGGER | `LSIDE.FN25.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 295 | TRIGGER | `LSIDE.FN25.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 296 | TRIGGER | `LSIDE.FN25.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 297 | TRIGGER | `LSIDE.FN26.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 298 | TRIGGER | `LSIDE.FN26.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 299 | TRIGGER | `LSIDE.FN26.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 300 | TRIGGER | `TOOLBAR.KEY-DOWN` | – | – | – | DROPPED | OLB toolbar / side-menu keyboard |
| 301 | TRIGGER | `TOOLBAR.KEY-UP` | – | – | – | DROPPED | OLB toolbar / side-menu keyboard |
| 302 | TRIGGER | `TOOLBAR.KEY-NEXT-ITEM` | – | – | – | DROPPED | OLB toolbar / side-menu keyboard |
| 303 | TRIGGER | `TOOLBAR.SAVE.WHEN-BUTTON-PRESSED` | SAVE (page 0 toolbar) | 0 | – | MAPPED | toolbar button |
| 304 | TRIGGER | `TOOLBAR.CLEAR_ALL.WHEN-BUTTON-PRESSED` | CLEAR (page 0 toolbar) | 0 | – | MAPPED | toolbar button |
| 305 | TRIGGER | `TOOLBAR.EXIT.WHEN-BUTTON-PRESSED` | BACK (page 0 toolbar) | 0 | – | MAPPED | toolbar button |
| 306 | TRIGGER | `TOOLBAR.EXIT1.WHEN-BUTTON-PRESSED` | BACK (page 0 toolbar) | 0 | – | MAPPED | toolbar button |
| 307 | TRIGGER | `TOOLBAR.ENTER.WHEN-BUTTON-PRESSED` | SEARCH (page 0 toolbar) | 0 | – | MAPPED | toolbar button |
| 308 | TRIGGER | `TOOLBAR.EXECUTE.WHEN-BUTTON-PRESSED` | SEARCH (page 0 toolbar) | 0 | – | MAPPED | toolbar button |
| 309 | TRIGGER | `TOOLBAR.REMOVE.WHEN-BUTTON-PRESSED` | DELETE (page 0 toolbar) / IG row delete | 0 | – | MAPPED | toolbar button |
| 310 | TRIGGER | `TOOLBAR.LIST_VALUE.WHEN-BUTTON-PRESSED` | – | – | – | DROPPED | OLB toolbar / side-menu keyboard |
| 311 | TRIGGER | `TOOLBAR.HELP.WHEN-BUTTON-PRESSED` | – | – | – | DROPPED | OLB toolbar / side-menu keyboard |
| 312 | TRIGGER | `TOOLBAR.LAST_REC.WHEN-BUTTON-PRESSED` | – | – | – | DROPPED | OLB toolbar / side-menu keyboard |
| 313 | TRIGGER | `TOOLBAR.RE_ENTER_QUERY.WHEN-BUTTON-PRESSED` | SEARCH (page 0 toolbar) | 0 | – | MAPPED | toolbar button |
| 314 | TRIGGER | `TOOLBAR.FIRST_REC.WHEN-BUTTON-PRESSED` | – | – | – | DROPPED | OLB toolbar / side-menu keyboard |
| 315 | TRIGGER | `TOOLBAR.PAGE_UP.WHEN-BUTTON-PRESSED` | – | – | – | DROPPED | OLB toolbar / side-menu keyboard |
| 316 | TRIGGER | `TOOLBAR.PAGE_DOWN.WHEN-BUTTON-PRESSED` | – | – | – | DROPPED | OLB toolbar / side-menu keyboard |
| 317 | TRIGGER | `TOOLBAR.FUN_BUT.WHEN-MOUSE-UP` | FUNCS (page 0 toolbar) | 0 | – | MAPPED | toolbar button |
| 318 | TRIGGER | `TOOLBAR.FUN_BUT.WHEN-MOUSE-DOWN` | FUNCS (page 0 toolbar) | 0 | – | MAPPED | toolbar button |
| 319 | TRIGGER | `HQ_IMPRS.ON-ERROR` | APP_ERROR_HANDLER (f345) | – | – | MAPPED | Designer constraint messages |
| 320 | TRIGGER | `HQ_IMPRS.KEY-HELP` | – | – | – | DROPPED | MS-Help obsolete |
| 321 | TRIGGER | `HQ_IMPRS.ON-DELETE` | – | – | – | DROPPED | body NULL: the master is never written (Form region without Process form) |
| 322 | TRIGGER | `HQ_IMPRS.ON-INSERT` | – | – | – | DROPPED | body NULL: the master is never written (Form region without Process form) |
| 323 | TRIGGER | `HQ_IMPRS.ON-UPDATE` | – | – | – | DROPPED | body NULL: the master is never written (Form region without Process form) |
| 324 | TRIGGER | `HQ_IMPRS.POST-QUERY` | POST-QUERY + DA HQ_IMPRS POST-QUERY (Confirm -> dialog 112502) | 1125 | IMPR1125.HQ_IMPRS_POST_QUERY | MAPPED | lookups; released-suspension count -> RELEASED_SUSPENSIONS_EXIST; CONFIRM + DELETE_SUSPS_LOV -> DA |
| 325 | TRIGGER | `HQ_IMPRS.PRE-QUERY` | HQ_IMPR_NBR EXECUTE-QUERY / BUS_ID EXECUTE-QUERY (P0_PAGE_PK) | 1125 | – | MAPPED | :GLOBAL.HQ_IMPR_NBR / BUS_NBR criteria -> ROWID of the first matching HQ_IMPRS row |
| 326 | TRIGGER | `HQ_IMPRS.WHEN-NEW-ITEM-INSTANCE` | HQ_IMPR_NBR / BUS_ID WHEN-VALIDATE-ITEM (Submit EXECUTE_QUERY) | 1125 | – | MAPPED | CLEAR_BLOCK + GO_BLOCK + EXECUTE_QUERY -> page submit + branch |
| 327 | TRIGGER | `HQ_IMPRS.BUS_ID.KEY-LISTVAL` | 112501 IMPR1125_SEARCH (page 0 SEARCH) | 112501 | – | MAPPED | SINGLE_IMP_LOV |
| 328 | TRIGGER | `HQ_IMPRS.BUS_ID.WHEN-VALIDATE-ITEM` | BUS_ID VALIDATION + DA BUS_ID WHEN-VALIDATE-ITEM + process BUS_ID EXECUTE-QUERY | 1125 | IMPR1125.BUS_ID_VALIDATION | MAPPED | also IMPR1125.BUS_ID_WHEN_VALIDATE_ITEM; SINGLE_IMP_LOV on error -> page 0 SEARCH |
| 329 | TRIGGER | `HQ_IMPRS.BUT_SH_HQNUM.WHEN-BUTTON-PRESSED` | 112501 IMPR1125_SEARCH (page 0 SEARCH) | 112501 | – | MAPPED | GO_ITEM BUS_ID + DO_KEY LIST_VALUES |
| 330 | TRIGGER | `HQ_IMPRS.BUS_ID_TYPE_CD.KEY-LISTVAL` | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 331 | TRIGGER | `HQ_IMPRS.BUS_ID_TYPE_NAME.KEY-LISTVAL` | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 332 | TRIGGER | `HQ_IMPRS.BUS_ID_BRNCH.KEY-LISTVAL` | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 333 | TRIGGER | `HQ_IMPRS.HQ_IMPR_NBR.KEY-LISTVAL` | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 334 | TRIGGER | `HQ_IMPRS.HQ_IMPR_NBR.WHEN-VALIDATE-ITEM` | HQ_IMPR_NBR VALIDATION + DA HQ_IMPR_NBR WHEN-VALIDATE-ITEM + process HQ_IMPR_NBR EXECUTE-QUERY | 1125 | IMPR1125.HQ_IMPR_NBR_VALIDATION | MAPPED | also IMPR1125.HQ_IMPR_NBR_WHEN_VALIDATE_ITEM |
| 335 | TRIGGER | `HQ_IMPRS.CITY_CODE_OF_ID.KEY-LISTVAL` | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 336 | TRIGGER | `HQ_IMPRS.CITY_CODE_OF_NAME.KEY-LISTVAL` | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 337 | TRIGGER | `HQ_IMPRS.IMPR_TYPE_CD.KEY-LISTVAL` | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 338 | TRIGGER | `HQ_IMPRS.IMPR_TYPE_NAME.KEY-LISTVAL` | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 339 | TRIGGER | `HQ_IMPRS.CTRY_CD.KEY-LISTVAL` | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 340 | TRIGGER | `HQ_IMPRS.CRTY_ARBC_NAME.KEY-LISTVAL` | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 341 | TRIGGER | `HQ_IMPRS.ARBC_IMPR_NAME.KEY-LISTVAL` | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 342 | TRIGGER | `HQ_IMPRS.ENG_IMPR_NAME.KEY-LISTVAL` | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 343 | TRIGGER | `IMPR_CNTRL_SUSPNS.ON-ERROR` | APP_ERROR_HANDLER (f345) | – | – | MAPPED | Designer constraint messages |
| 344 | TRIGGER | `IMPR_CNTRL_SUSPNS.KEY-HELP` | – | – | – | DROPPED | MS-Help obsolete |
| 345 | TRIGGER | `IMPR_CNTRL_SUSPNS.KEY-DELREC` | IMPR_CNTRL_SUSPNS row delete | 1125 | – | MAPPED | TMPLT.KEY_DELETE_RECORD: confirm + delete + COMMIT -> IG delete, APEX commit |
| 346 | TRIGGER | `IMPR_CNTRL_SUSPNS.ON-DELETE` | IMPR_CNTRL_SUSPNS - Save Interactive Grid Data | 1125 | IMPR1125.IMPR_CNTRL_SUSPNS_ON_DELETE | MAPPED | soft delete, called by IMPR_CNTRL_SUSPNS_SAVE_ROW (row status D) |
| 347 | TRIGGER | `IMPR_CNTRL_SUSPNS.POST-INSERT` | IMPR_CNTRL_SUSPNS - Save Interactive Grid Data | 1125 | IMPR1125.IMPR_CNTRL_SUSPNS_POST_INSERT | MAPPED | called by IMPR_CNTRL_SUSPNS_SAVE_ROW; COMMIT removed (HIGH) |
| 348 | TRIGGER | `IMPR_CNTRL_SUSPNS.PRE-INSERT` | IMPR_CNTRL_SUSPNS - Save Interactive Grid Data | 1125 | IMPR1125.IMPR_CNTRL_SUSPNS_PRE_INSERT | MAPPED | called by IMPR_CNTRL_SUSPNS_SAVE_ROW (row status C) |
| 349 | TRIGGER | `IMPR_CNTRL_SUSPNS.PRE-UPDATE` | IMPR_CNTRL_SUSPNS - Save Interactive Grid Data | 1125 | IMPR1125.IMPR_CNTRL_SUSPNS_PRE_UPDATE | MAPPED | called by IMPR_CNTRL_SUSPNS_SAVE_ROW (row status U) |
| 350 | TRIGGER | `IMPR_CNTRL_SUSPNS.SUSPN_STRT_DT.KEY-LISTVAL` | – | – | – | DROPPED | INTRFACE.DISP_CALENDAR -> Hijri date column (hijri-date-default) |
| 351 | TRIGGER | `IMPR_CNTRL_SUSPNS.SUSPN_STRT_DT.KEY-F4` | – | – | – | DROPPED | INTRFACE.DISP_DATE_CON -> Hijri date column |
| 352 | TRIGGER | `IMPR_CNTRL_SUSPNS.SUSPN_STRT_DT.WHEN-VALIDATE-ITEM` | IMPR_CNTRL_SUSPNS SUSPN_STRT_DT VALIDATION + DA IMPR_CNTRL_SUSPNS SUSPN_STRT_DT WHEN-VALIDATE-ITEM | 1125 | IMPR1125.SUSPN_STRT_DT_VALIDATION | MAPPED | – |
| 353 | TRIGGER | `IMPR_CNTRL_SUSPNS.SUSPN_END_DT.KEY-LISTVAL` | – | – | – | DROPPED | INTRFACE.DISP_CALENDAR -> Hijri date column (hijri-date-default) |
| 354 | TRIGGER | `IMPR_CNTRL_SUSPNS.SUSPN_END_DT.KEY-F4` | – | – | – | DROPPED | INTRFACE.DISP_DATE_CON -> Hijri date column |
| 355 | TRIGGER | `IMPR_CNTRL_SUSPNS.SUSPN_END_DT.WHEN-VALIDATE-ITEM` | IMPR_CNTRL_SUSPNS SUSPN_END_DT VALIDATION + DA IMPR_CNTRL_SUSPNS SUSPN_END_DT WHEN-VALIDATE-ITEM | 1125 | IMPR1125.SUSPN_END_DT_VALIDATION | MAPPED | – |
| 356 | TRIGGER | `IMPR_CNTRL_SUSPNS.SUSPN_SEQ.KEY-LISTVAL` | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 357 | TRIGGER | `IMPR_CNTRL_SUSPNS.SUSPN_RSN_TEXT.KEY-LISTVAL` | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 358 | RELATION | `CGFK$ICS_HI_FK` | IMPR_CNTRL_SUSPNS (IG WHERE hq_impr_nbr = :P1125_HQ_IMPR_NBR) | 1125 | – | MAPPED | HQ_IMPRS -> IMPR_CNTRL_SUSPNS; master key from the master form (column default + NVL in the save call) |
| 359 | LOV | `CGFK$HQ_IMPRS_BUS_ID_TYPE_CD` | – | – | – | DROPPED | item BUS_ID_TYPE_CD is display only; name from HQ_IMPRS_POST_QUERY |
| 360 | RECORD_GROUP | `CGFK$HQ_IMPRS_BUS_ID_TYPE_CD` | – | – | – | DROPPED | query of LOV CGFK$HQ_IMPRS_BUS_ID_TYPE_CD |
| 361 | RECORD_GROUP | `CGDV$DLRG (runtime)` | LOV_ALLOWED_EXPORT (IMPR1110), LOV_SUSPN_SIDE_CD (IMPR1120) | 1125 | – | MAPPED | CREATE_GROUP_FROM_QUERY on CG_REF_CODES; IMPR_SUSPN_RSN_CD list not needed (column hidden, meaning joined on 112502) |
| 362 | CANVAS | `LSIDE` | – | – | – | DROPPED | OLB canvas LSIDE |
| 363 | CANVAS | `EDI_MSG` | – | – | – | DROPPED | OLB canvas EDI_MSG |
| 364 | CANVAS | `TITLE` | – | – | – | DROPPED | OLB canvas TITLE |
| 365 | CANVAS | `TOOLBAR` | – | – | – | DROPPED | OLB canvas TOOLBAR |
| 366 | CANVAS | `CG$PAGE_1` | 1125 IMPR1125 | 1125 | – | MAPPED | main content canvas |
| 367 | WINDOW | `CGSO$WINDOW_1` | 1125 IMPR1125 | 1125 | – | MAPPED | console window |
| 368 | ALERT | `CG$ASK_COMMIT` | – | – | – | DROPPED | not used by IMPR1125 code |
| 369 | ALERT | `USR_CONFIRM_B` | – | – | – | DROPPED | not used by IMPR1125 code |
| 370 | ALERT | `USR_CONFIRM` | HQ_IMPRS POST-QUERY native Confirm | 1125 | – | MAPPED | STR.DispALERT CONFIRM (released suspensions) |
| 371 | ALERT | `USR_WARNING_C` | – | – | – | DROPPED | not used by IMPR1125 code |
| 372 | ALERT | `USR_WARNING_B` | IG row delete (restorable until SAVE) | 1125 | – | MAPPED | TMPLT.KEY_DELETE_RECORD |
| 373 | ALERT | `CFG_WARNING_A` | – | – | – | DROPPED | not used by IMPR1125 code |
| 374 | ALERT | `CFG_INFORMATION` | page messages (f345) | 1125 | – | MAPPED | NIB.ON_MESSAGE |
| 375 | ALERT | `CFG_ERROR` | validation error texts / FORMS_APX.FORM_TRIGGER_FAILURE | 1125 | – | MAPPED | STR.DISPALERT ERROR (literal texts) |
| 376 | ALERT | `CFG_SYSTEM_ERROR` | FORMS_APX.FORM_TRIGGER_FAILURE (activity log / Hijri date errors) | 1125 | – | MAPPED | – |
| 377 | ALERT | `CFG_ASK_COMMIT` | – | – | – | DROPPED | not used by IMPR1125 code |
| 378 | PARAMETER | `P_SHPG_AGNT_NBR` | – | – | – | DROPPED | not used by the business code (function menu / reports / frame) |
| 379 | PARAMETER | `P_CTRL_LAST_EXEC_CD` | – | – | – | DROPPED | not used by the business code (function menu / reports / frame) |
| 380 | PARAMETER | `P_BANK_CD` | – | – | – | DROPPED | not used by the business code (function menu / reports / frame) |
| 381 | PARAMETER | `P_BANK_BRNCH_CD` | – | – | – | DROPPED | not used by the business code (function menu / reports / frame) |
| 382 | PARAMETER | `P_BRKR_PORT_CD` | – | – | – | DROPPED | not used by the business code (function menu / reports / frame) |
| 383 | PARAMETER | `P_LIC_TYPE` | – | – | – | DROPPED | not used by the business code (function menu / reports / frame) |
| 384 | PARAMETER | `P_BRKR_NBR` | – | – | – | DROPPED | not used by the business code (function menu / reports / frame) |
| 385 | PARAMETER | `P_CLASS_CD` | – | – | – | DROPPED | not used by the business code (function menu / reports / frame) |
| 386 | PARAMETER | `P_JOB_ID` | – | – | – | DROPPED | not used by the business code (function menu / reports / frame) |
| 387 | PARAMETER | `P_CURRENT_ITEM` | – | – | – | DROPPED | not used by the business code (function menu / reports / frame) |
| 388 | PARAMETER | `P_GROUP_CD` | – | – | – | DROPPED | not used by the business code (function menu / reports / frame) |
| 389 | PARAMETER | `P_USER_TYPE` | – | – | – | DROPPED | not used by the business code (function menu / reports / frame) |
| 390 | PARAMETER | `P_PORT_TYPE` | – | – | – | DROPPED | not used by the business code (function menu / reports / frame) |
| 391 | PARAMETER | `P_CURR_PORT_CD` | P_CURR_PORT_CD (f345) | – | – | MAPPED | NE_INTEGRATION setting, SMS port, activity log |
| 392 | PARAMETER | `P_MODULE_ID` | P1125_MODULE_ID | 1125 | – | MAPPED | FORMS_APX.GET_MODULE_ID |
| 393 | PARAMETER | `P_MODULE_NAME` | SYS_ANAME (f345 page title) | – | – | MAPPED | title bar only |
| 394 | PARAMETER | `P_APPLICATION_NAME` | – | – | – | DROPPED | not used by the business code (function menu / reports / frame) |
| 395 | PARAMETER | `P_USER_ID` | SSO_APP_USER (f345) | – | – | MAPPED | ACTIVITY_DB user |
| 396 | PARAMETER | `P_WS_ID` | P_GLOBAL_V_WS_ID (f345) | – | – | MAPPED | ACTIVITY_DB workstation |
| 397 | PARAMETER | `P_USER_NAME` | V_USR_NAME (f345 header) | – | – | MAPPED | title bar only |
| 398 | PARAMETER | `CG$STARTUP_MODE` | – | – | – | DROPPED | not used by the business code (function menu / reports / frame) |
| 399 | PARAMETER | `CURRENT_SIDE` | – | – | – | DROPPED | declared but read nowhere in IMPR1125 |
| 400 | LIBRARY | `OFGTEL` | – | – | – | TODO | MISSING SOURCE - constraint messages (CGTE$) |
| 401 | LIBRARY | `OFGMES` | – | – | – | DROPPED | not needed in the browser (help, DLL, window, tab, pick list) |
| 402 | LIBRARY | `OFGHPL` | – | – | – | DROPPED | not needed in the browser (help, DLL, window, tab, pick list) |
| 403 | LIBRARY | `CIC_AMSG` | – | – | – | MAPPED | Des$Form_errors messages -> FORMS_APX / APP_ERROR_HANDLER |
| 404 | LIBRARY | `SEC_LIB` | – | – | – | DROPPED | not needed in the browser (help, DLL, window, tab, pick list) |
| 405 | LIBRARY | `CAPTION` | – | – | – | DROPPED | not needed in the browser (help, DLL, window, tab, pick list) |
| 406 | LIBRARY | `OFGBSL` | – | – | – | MAPPED | CGBS$ master-detail -> native Form + IG |
| 407 | LIBRARY | `D2KWUTIL` | – | – | – | DROPPED | not needed in the browser (help, DLL, window, tab, pick list) |
| 408 | LIBRARY | `CUSTOMDLL` | – | – | – | DROPPED | not needed in the browser (help, DLL, window, tab, pick list) |
| 409 | LIBRARY | `D2KWUTIL_PDF` | – | – | – | DROPPED | not needed in the browser (help, DLL, window, tab, pick list) |
| 410 | LIBRARY | `GETCOMP` | – | – | – | DROPPED | not needed in the browser (help, DLL, window, tab, pick list) |
| 411 | LIBRARY | `OFGTAB` | – | – | – | DROPPED | not needed in the browser (help, DLL, window, tab, pick list) |
| 412 | LIBRARY | `PICKLIST` | – | – | – | DROPPED | not needed in the browser (help, DLL, window, tab, pick list) |
| 413 | LIBRARY | `POS` | – | – | – | DROPPED | not needed in the browser (help, DLL, window, tab, pick list) |
| 414 | LIBRARY | `SCDLL` | – | – | – | DROPPED | not needed in the browser (help, DLL, window, tab, pick list) |
| 415 | LIBRARY | `VCDLL` | – | – | – | DROPPED | not needed in the browser (help, DLL, window, tab, pick list) |
| 416 | LIBRARY | `CIC_LIB` | – | – | – | MAPPED | NIB / TMPLT -> f345; STR.DispAlert -> literal texts; HIJDATE -> FORMS_APX / HIJDATE_DB; ACTIVITY -> ACTIVITY_DB; INTRFACE -> date column |
| 417 | GLOBAL | `BUS_ID` | P0_PAGE_PK (search page link) | 1125 | – | MAPPED | no G_ application item needed |
| 418 | GLOBAL | `BUS_NBR` | P0_PAGE_PK (process BUS_ID EXECUTE-QUERY) | 1125 | – | MAPPED | no G_ application item needed |
| 419 | GLOBAL | `CG$HP_HFILE` | – | – | – | DROPPED | Designer internal / version stamp / frame - not needed |
| 420 | GLOBAL | `CG$HP_HPATH` | – | – | – | DROPPED | Designer internal / version stamp / frame - not needed |
| 421 | GLOBAL | `CG$QUERY_MODE` | – | – | – | DROPPED | Designer internal / version stamp / frame - not needed |
| 422 | GLOBAL | `CURRENT_VER` | – | – | – | DROPPED | Designer internal / version stamp / frame - not needed |
| 423 | GLOBAL | `EXIT` | – | – | – | DROPPED | Designer internal / version stamp / frame - not needed |
| 424 | GLOBAL | `HQ_IMPR_NBR` | P0_PAGE_PK (process HQ_IMPR_NBR EXECUTE-QUERY / search link) | 1125 | – | MAPPED | no G_ application item needed |
| 425 | GLOBAL | `SYSTEM_OBJ` | – | – | – | DROPPED | Designer internal / version stamp / frame - not needed |
| 426 | CALLED_FORM | `LOV_IMPORT_HQ_NBR` | 112501 IMPR1125_SEARCH | 112501 | – | MAPPED | SINGLE_IMP_LOV |
| 427 | CALLED_FORM | `LOV_DELETE_IMP_SUSP` | 112502 IMPR1125_DELETED_SUSPENSIONS | 112502 | IMPR1125.RELEASED_SUSPENSIONS_EXIST | MAPPED | DELETE_SUSPS_LOV (P_HQ_IMPR_NBR -> P112502_P_HQ_IMPR_NBR with checksum) |
| 428 | CALLED_FORM | `V_CALLED_FORM (dynamic, PU EXECUTE_FUNCTION)` | FUNCS (page 0, Page Functions list) | 0 | – | TODO | functions of the module in SC_SYSTEM_OBJECTS unknown (inventory §15 #8) |
| 429 | CALLED_FORM | `calendar forms (INTRFACE.DISP_CALENDAR / DISP_DATE_CON)` | hijri-date-default date columns | 1125 | – | MAPPED | date KEY-LISTVAL / KEY-F4 |
| 430 | PROGRAM_UNIT | `CHECK_TIMEOUT` | – | – | – | DROPPED | not called by active code (NIB wrapper / query-mode toggle) |
| 431 | PROGRAM_UNIT | `MOUSE_CLICK` | – | – | – | DROPPED | f345 Page Functions (FUNCS) |
| 432 | PROGRAM_UNIT | `TOGGEL_WND` | – | – | – | DROPPED | not called by active code (NIB wrapper / query-mode toggle) |
| 433 | PROGRAM_UNIT | `PRINT_REPORT` | – | – | – | DROPPED | not called by active code (NIB wrapper / query-mode toggle) |
| 434 | PROGRAM_UNIT | `EXECUTE_FUNCTION` | – | – | – | DROPPED | f345 Page Functions (FUNCS) |
| 435 | PROGRAM_UNIT | `TERMINATE_FUN` | – | – | – | DROPPED | not called by active code (NIB wrapper / query-mode toggle) |
| 436 | PROGRAM_UNIT | `CHECK_EDI_MSG_LOV` | – | – | – | DROPPED | not called by active code (NIB wrapper / query-mode toggle) |
| 437 | PROGRAM_UNIT | `CHECK_EDI_MSG_TIMER` | – | – | – | DROPPED | not called by active code (NIB wrapper / query-mode toggle) |
| 438 | PROGRAM_UNIT | `CHECK_EDI_ROLE_ID` | – | – | – | DROPPED | not called by active code (NIB wrapper / query-mode toggle) |
| 439 | PROGRAM_UNIT | `EDI_MSG_LOV` | – | – | – | DROPPED | not called by active code (NIB wrapper / query-mode toggle) |
| 440 | PROGRAM_UNIT | `FOR_EDI_MSG` | – | – | – | DROPPED | not called by active code (NIB wrapper / query-mode toggle) |
| 441 | PROGRAM_UNIT | `RETURN_MSG` | – | – | – | DROPPED | not called by active code (NIB wrapper / query-mode toggle) |
| 442 | PROGRAM_UNIT | `TURN_MSG` | – | – | – | DROPPED | not called by active code (NIB wrapper / query-mode toggle) |
| 443 | PROGRAM_UNIT | `WHEN_TIMER_EXPIRED_MSG` | – | – | – | DROPPED | not called by active code (NIB wrapper / query-mode toggle) |
| 444 | PROGRAM_UNIT | `CG$WHEN_NEW_FORM_INSTANCE` | – | – | – | DROPPED | lists + block-sync startup -> shared LOVs / native master-detail |
| 445 | PROGRAM_UNIT | `CGDV$POPULATE_DYNAMIC_LISTS` | – | – | – | DROPPED | shared LOVs on CG_REF_CODES |
| 446 | PROGRAM_UNIT | `CGUV$CHK_HI_PK` | – | – | – | DROPPED | not called; HQ_IMPR_NBR_VALIDATION does the same check |
| 447 | PROGRAM_UNIT | `CGFK$CHK_IMPR_CNTRL_SUSPNS_ICS` | – | – | – | DROPPED | not called; foreign key ICS_HI_FK in the database |
| 448 | PROGRAM_UNIT | `CGTE$CHECK_CONSTRAINT_VIO` | – | – | – | DROPPED | APP_ERROR_HANDLER |
| 449 | PROGRAM_UNIT | `CGBS$TOGGLE` | – | – | – | DROPPED | not called by active code (NIB wrapper / query-mode toggle) |
| 450 | PROGRAM_UNIT | `CGBS$SET_QUERY_MODE` | – | – | – | DROPPED | not called by active code (NIB wrapper / query-mode toggle) |
| 451 | PROGRAM_UNIT | `CGBS$MESSAGE_QUERY_MODE` | – | – | – | DROPPED | not called by active code (NIB wrapper / query-mode toggle) |
| 452 | PROGRAM_UNIT | `SINGLE_IMP_LOV` | 112501 IMPR1125_SEARCH | 112501 | – | MAPPED | CALL_FORM LOV_IMPORT_HQ_NBR |
| 453 | PROGRAM_UNIT | `EXEC_FUNS` | – | – | – | DROPPED | empty in Forms |
| 454 | PROGRAM_UNIT | `DELETE_SUSPS_LOV` | 112502 IMPR1125_DELETED_SUSPENSIONS | 112502 | – | MAPPED | CALL_FORM LOV_DELETE_IMP_SUSP |
| 455 | PROGRAM_UNIT | `ADJ_FUNS` | – | – | – | DROPPED | empty in Forms |


## 15. Registry script

`registry/IMPR1125_registry.sql` (generated with §14): the `MIG_FORM_REGISTRY` row (app 202530, pages 1125–1125, package `IMPR1125`, COMPLEX, status DESIGN) and one `MIG_OBJECT_MAP` row per object of §14. Re-runnable, ends with COMMIT. **Not executed** (CLAUDE.md §6.10).

## 16. Open items

| # | Item | Level |
|---|---|---|
| 1 | One-line JavaScript action in `HQ_IMPRS POST-QUERY` (§10): user approval | Medium |
| 2 | The released-suspensions question is asked on every load of an importer that has them (also after a save), as Forms asks after every query | Low |
| 3 | HIGH items carried over: COMMIT removed from POST-INSERT; notification errors hidden; NULL mobile in the `NE_INTEGRATION = 1` channel (extraction §8) | High |
| 4 | *Prevent Lost Updates* with IG Target Type PL/SQL Code (as IMPR1120 §16 #6) | Medium |
| 5 | `SINGLE_IMPORTERS` with several rows per unified number: POST-QUERY fails as in Forms; search page lists each row (inventory §15 #3) | Medium |
| 6 | Read-only `SUSPN_SIDE_CD` select list (Read Only = Always on an IG column) shows the meaning of 5 | Low |
