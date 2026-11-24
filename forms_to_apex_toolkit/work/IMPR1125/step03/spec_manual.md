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

<!-- TRACE -->

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
