# IMPR1170 – APEX 21.2 Page Specification (step 03)

- **Form:** IMPR1170 (module `IMPR1170_CNTRL`) – بيانات السجل التجارى من وزارة التجارة (MCI_DATA + owners MCI_OWNERS, refreshed from the MCI web service)
- **Package:** `IMPR1170` version 001 (`plsql/IMPR1170/`), logic report `analysis/IMPR1170/IMPR1170_logic_extraction.md`;
  no change to `LOV_APX` / `FORMS_APX`
- **Standard:** f345 (`apex/Reference/f345.sql`), CLAUDE.md §4a–§4d, `docs/f345_reference_standard.md`
- **Design data:** `scripts/gen_apex_impr1170.py` (ITEMS, PROCESSES, DAS …); this file is rendered from it by
  `work/IMPR1170/step03/build_spec.py`, the traceability (§14) and `registry/IMPR1170_registry.sql` by `build_trace.py`.
- **Produced:** 2026-11-25 by Claude Code.

## 0. Decisions that shape the page

| # | Decision | Reason / source |
|---|---|---|
| 1 | Main page **1170** `IMPR1170`, search page **117001** `IMPR1170_SEARCH` (modal 1800×800), page group `IMPR` (IMPR1110 export) | f345 standard §3 |
| 2 | Block MCI_DATA = native **Form** region on the table, query only, key **CR_NBR** (= `P0_PAGE_PK`); block MCI_OWNERS = read-only **Interactive Grid** below it, `WHERE cr_nbr = :P1170_CR_NBR` | Update / Delete Allowed = false; relation `CGFK$MCI_OWNER_MCI_DATA_FK` |
| 3 | Page 0 **CREATE / SAVE / DELETE are refused** (processes PRE-INSERT / PRE-UPDATE / PRE-DELETE with a message) | Forms lets SAVE insert a bare row (CR_NBR, CR_TYPE 1) without the look-up – not kept (inventory §14 #2, §15 #1, **to confirm**) |
| 4 | `CR_NBR.KEY-NEXT-ITEM` = DA `CR_NBR KEY-NEXT-ITEM` (Change → Submit Page `EXECUTE_QUERY`) + After Submit process `CR_NBR KEY-NEXT-ITEM` → `IMPR1170.CR_NBR_KEY_NEXT_ITEM` (cache of today, else the MCI web service) which sets `P0_PAGE_PK`; branch `EXECUTE-QUERY` reloads the page and *Initialize form* shows the record | IMPR1150 pattern; a change event also fires with the mouse (inventory §14 #1) |
| 5 | A failed service call shows the Forms text as page error ("بيانات السجل التجارى رقم … غير متاحة …"); the typed number stays | STR.DISPALERT 'ERROR' |
| 6 | CR_NBR enterable only while no record is shown (`:P0_PAGE_PK IS NOT NULL` → read only); every other item is Display Only | Update Allowed = false on every item; Insert Allowed = false except CR_NBR |
| 7 | Hijri CR_ISSUE_DATE / CR_EXPIRY_DATE: Display Only with the mask `&P1170_HIJRI_DATE_FORMAT.` (Application Setting) | IMPR1150 decision; Forms mask MI-MM-YYYY |
| 8 | CR_TYPE: always read-only Select List on the reused LOV `LOV_COMM_RGSTRTN_TYPE` (IMPR1130) | CGSO$COMBO_DO, CGDV$POPULATE_DYNAMIC_LISTS |
| 9 | No functions (EXEC_FUNS / ADJ_FUNS are empty), no FOS, no JavaScript action, no shared component created | CLAUDE.md §4c |

## 1. Page type decision per block

| Block | Forms | APEX |
|---|---|---|
| MCI_DATA | base table, one record shown, query only (+ insert by default, not kept) | Form region on page 1170 + search IG on page 117001 |
| MCI_OWNERS | base table, 4 records shown, query only, detail of MCI_DATA | read-only IG on page 1170 |
| TITLE, EDI_MSG, LSIDE, TOOLBAR | OLB frame | f345 page template, hero region, page 0 toolbar, FUNCS drawer |

## 2. Pages

| Page | Name / alias | Mode | Template / class | Source |
|---|---|---|---|---|
| 1170 | IMPR1170 / IMPR1170 | Normal, protection C, Warn on Unsaved Changes = No | Zatca-Minimal_No_Navigation, `zf` | window CGSO$WINDOW_1, canvas CG$PAGE_1 |
| 117001 | IMPR1170_SEARCH / IMPR1170-SEARCH | Modal 1800×800, protection C | theme dialog, `zf` | Enter-Query / Execute-Query (page 0 SEARCH) |

## 3. Regions

| Page | Region (static id) | Type / template | Source |
|---|---|---|---|
| 1170 | الهيدر (`MCI_DATA_HERO`) | Static HTML, `cg-hero`, title `&P1170_HERO_TITLE.` | OLB block TITLE |
| 1170 | بيانات السجل التجارى (`MCI_DATA`) | Form, table `MCI_DATA`, key CR_NBR, not editable, Interactive Report template, `zatca-forms cg-form cg-card` | block MCI_DATA |
| 1170 | ملاك السجل التجارى (`MCI_OWNERS`) | read-only IG, Standard template, `cg-card cg-grid`, Page Items to Submit `P1170_CR_NBR` | block MCI_OWNERS + its POST-QUERY |
| 117001 | بحث (`MCI_DATA_SEARCH_CRITERIA`) | Static, text `P117001_SEARCH` + buttons SEARCH / CLEAR | Enter-Query criteria |
| 117001 | السجلات التجارية (`MCI_DATA_SEARCH`) | read-only IG, lazy loading, every row on opening (search text optional, user request 2026-11-26); link `CR_NBR` → page 1170 with `P0_PAGE_PK = CR_NBR` | block query (no WHERE clause) + POST-QUERY status |

### 3.1 Grid MCI_OWNERS

```sql
-- block MCI_OWNERS: relation CGFK$MCI_OWNER_MCI_DATA_FK (MCI_DATA.CR_NBR = MCI_OWNERS.CR_NBR), query only;
-- MCI_OWNERS.POST-QUERY (RELATION_DESC from MCI_RELATION_TYPES, WHEN OTHERS -> NULL) as an outer join
SELECT o.owner_isn, o.cr_nbr, o.owner_name, o.national_id, o.owner_nationality_ar, o.owner_nationality_en,
       o.relation_type, rt.relation_name AS relation_desc
  FROM mci_owners o, mci_relation_types rt
 WHERE o.cr_nbr = :P1170_CR_NBR
   AND rt.relation_cd (+) = o.relation_type
```

| Column | Heading | Data type | Kind |
|---|---|---|---|
| `OWNER_ISN` | – | NUMBER | pk |
| `CR_NBR` | – | VARCHAR2 | hidden |
| `OWNER_NAME` | اسم المالك | VARCHAR2 | text |
| `NATIONAL_ID` | رقم الهوية | VARCHAR2 | text |
| `OWNER_NATIONALITY_AR` | جنسية المالك | VARCHAR2 | text |
| `OWNER_NATIONALITY_EN` | جنسية المالكEN | VARCHAR2 | text |
| `RELATION_TYPE` | – | NUMBER | hidden |
| `RELATION_DESC` | العلاقة | VARCHAR2 | text |

### 3.2 Search grid (page 117001)

```sql
-- one search text over every shown column; every row while the search text is empty (user request 2026-11-26). The block has no
-- WHERE clause: every cached registration (MCI_DATA is national, not per port). POST-QUERY status text as outer join.
SELECT x.*
  FROM (SELECT md.cr_nbr, md.cr_name_ar, ct.rv_meaning AS cr_type_name, md.main_cr_nbr,
               st.status_desc AS cr_stat_desc,
               TO_CHAR(md.cr_issue_date, (SELECT FORMS_APX.HIJRI_DATE_FORMAT FROM dual)) AS cr_issue_date,
               md.cr_city_ar, md.legal_type_a
          FROM mci_data md, cg_ref_codes ct, mci_bus_id_status st
         WHERE ct.rv_domain (+) = 'COMM_RGSTRTN_TYPE'
           AND ct.rv_low_value (+) = TO_CHAR(md.cr_type)
           AND st.bus_id_status (+) = md.cr_status) x
 WHERE (:P117001_SEARCH IS NULL OR INSTR(UPPER(x.cr_nbr || '|' || x.cr_name_ar || '|' || x.cr_type_name || '|' || x.main_cr_nbr || '|' ||
                   x.cr_stat_desc || '|' || x.cr_issue_date || '|' || x.cr_city_ar || '|' || x.legal_type_a),
             UPPER(TRIM(:P117001_SEARCH))) > 0)
```

| Column | Heading | Data type | Kind |
|---|---|---|---|
| `CR_NBR` | الرقم الموحد للسجل التجاري | VARCHAR2 | link |
| `CR_NAME_AR` | الاسم التجارى | VARCHAR2 | text |
| `CR_TYPE_NAME` | نوع السجل التجارى | VARCHAR2 | text |
| `MAIN_CR_NBR` | السجل التجارى الرئيسى | VARCHAR2 | text |
| `CR_STAT_DESC` | حالة السجل التجارى | VARCHAR2 | text |
| `CR_ISSUE_DATE` | تاريخ انشاء السجل التجارى | VARCHAR2 | text |
| `CR_CITY_AR` | اسم المدينة | VARCHAR2 | text |
| `LEGAL_TYPE_A` | نوع المنشأة | VARCHAR2 | text |

## 4. Items (page 1170)

Canvas order (rows by Y, right to left by X); Display Only items are read only by type.

| Item | Type | Label | Column | Required | LOV / mask | Read only | Span | Source |
|---|---|---|---|---|---|---|---|---|
| `P1170_CR_NBR` | TEXT_FIELD | الرقم الموحد للسجل التجاري | CR_NBR | Yes | – | record | 4 (new row) | MCI_DATA.CR_NBR (CGSO$CHAR_ARB, Required, Update Allowed = false; KEY-NEXT-ITEM look-up / web service; Form region primary key = P0_PAGE_PK) |
| `P1170_CR_TYPE` | SELECT_LIST | نوع السجل التجارى | CR_TYPE | – | LOV_COMM_RGSTRTN_TYPE | always | 4 | MCI_DATA.CR_TYPE (CGSO$COMBO_DO, not navigable, initial value 1; CGDV$POPULATE_DYNAMIC_LISTS CG_REF_CODES COMM_RGSTRTN_TYPE; XML values 1 رئيسي, 0 فرعي, 2 فرعي) |
| `P1170_MAIN_CR_NBR` | DISPLAY_ONLY | السجل التجارى الرئيسى | MAIN_CR_NBR | – | – | always | 4 (new row) | MCI_DATA.MAIN_CR_NBR |
| `P1170_CR_STATUS` | DISPLAY_ONLY | حالة السجل التجارى | CR_STATUS | – | – | always | 2 | MCI_DATA.CR_STATUS |
| `P1170_CR_STAT_DESC` | DISPLAY_ONLY | – | – | – | – | always | 2 | MCI_DATA.CR_STAT_DESC (non-database; POST-QUERY) |
| `P1170_CR_ISSUE_DATE` | DISPLAY_ONLY | تاريخ انشاء السجل التجارى | CR_ISSUE_DATE | – | &P1170_HIJRI_DATE_FORMAT. | always | 4 (new row) | MCI_DATA.CR_ISSUE_DATE (CGSO$HDATE_ARB_DO Hijri MI-MM-YYYY; WHEN-VALIDATE-ITEM unreachable) |
| `P1170_CR_CITY_AR` | DISPLAY_ONLY | اسم المدينة | CR_CITY_AR | – | – | always | 4 (new row) | MCI_DATA.CR_CITY_AR |
| `P1170_CR_CAPITAL` | DISPLAY_ONLY | رأس المال | CR_CAPITAL | – | – | always | 4 | MCI_DATA.CR_CAPITAL |
| `P1170_CR_NAME_AR` | DISPLAY_ONLY | الاسم التجارى | CR_NAME_AR | – | – | always | 8 (new row) | MCI_DATA.CR_NAME_AR |
| `P1170_LEGAL_TYPE_A` | DISPLAY_ONLY | نوع المنشأة | LEGAL_TYPE_A | – | – | always | 4 (new row) | MCI_DATA.LEGAL_TYPE_A |
| `P1170_LEGAL_TYPE_E` | DISPLAY_ONLY | نوع المنشأةEN | LEGAL_TYPE_E | – | – | always | 4 | MCI_DATA.LEGAL_TYPE_E |
| `P1170_CR_PHONE_NO` | DISPLAY_ONLY | التليفون | CR_PHONE_NO | – | – | always | 4 (new row) | MCI_DATA.CR_PHONE_NO |
| `P1170_CR_FAX_NO` | DISPLAY_ONLY | فاكس | CR_FAX_NO | – | – | always | 4 | MCI_DATA.CR_FAX_NO |
| `P1170_CR_ADDRESS` | DISPLAY_ONLY | العنوان | CR_ADDRESS | – | – | always | 8 (new row) | MCI_DATA.CR_ADDRESS |
| `P1170_CR_ACTIVITIES` | DISPLAY_ONLY | النشاط التجارى | CR_ACTIVITIES | – | – | always | 8 (new row) | MCI_DATA.CR_ACTIVITIES |

Not displayed:

| Item | Type | Column | Mask | Source |
|---|---|---|---|---|
| `P1170_CR_EXPIRY_DATE` | DISPLAY_ONLY | CR_EXPIRY_DATE | &P1170_HIJRI_DATE_FORMAT. | MCI_DATA.CR_EXPIRY_DATE (Hijri, Visible = false; WHEN-VALIDATE-ITEM unreachable) |
| `P1170_MODULE_ID` | HIDDEN | – | – | f345 Page Functions: P<page>_MODULE_ID |
| `P1170_HIJRI_DATE_FORMAT` | HIDDEN | – | – | FORMS_APX.HIJRI_DATE_FORMAT (format mask of the Hijri dates) |
| `P1170_HERO_TITLE` | HIDDEN | – | – | f345 hero title (FORMS_APX.HEADER_TITLE) |

## 5. Buttons

None on page 1170: CREATE · SAVE · DELETE · SEARCH · CLEAR · FUNCS · BACK come from the f345 page 0 toolbar. CREATE / SAVE /
DELETE end in the refusing processes of §8 (decision 0 #3). Page 117001: SEARCH and CLEAR (Defined by Dynamic Action).

## 6. LOVs

| LOV | Created by | Used by | Source |
|---|---|---|---|
| `LOV_COMM_RGSTRTN_TYPE` | IMPR1130 export (`LOV_APX.REFERENCE_CODES(P_DOMAIN => 'COMM_RGSTRTN_TYPE')`) | `P1170_CR_TYPE` | CGDV$POPULATE_DYNAMIC_LISTS |

## 7. Validations

None: CR_NBR WHEN-VALIDATE-ITEM is `NULL;`; the Hijri checks of CR_ISSUE_DATE / CR_EXPIRY_DATE belong to items that are never
enterable. CR_NBR is Required (item attribute), as in Forms.

## 8. Processes (page 1170, f345 standard §6)

| Point | Seq | Name | Code | Condition | Source |
|---|---|---|---|---|---|
| BEFORE_HEADER | 10 | New | `NULL; (Never)` | NEVER | f345 session setup copied from AGR1100 (condition Never) / standard 6 |
| BEFORE_HEADER | 20 | P0_PAGE_PK CHECK | `IMPR1170.P0_PAGE_PK_CHECK(P_PAGE_PK => :P0_PAGE_PK);` | – | f345 key (CR_NBR of a cached MCI_DATA row) |
| BEFORE_HEADER | 40 | PARAMETERS | `:P1170_MODULE_ID := FORMS_APX.GET_MODULE_ID(P_MODULE_ID => :P1170_MODULE_ID, FORM_NAME => 'IMPR1170');` | – | f345 module id of the Page Functions list |
| BEFORE_HEADER | 70 | P0_PAGE_PK | `:P1170_CR_NBR := :P0_PAGE_PK;` | – | f345 (key = CR_NBR) |
| BEFORE_HEADER | 80 | Initialize form | `NATIVE_FORM_INIT (region MCI_DATA)` | – | block MCI_DATA query (DEFAULT_WHERE CR_NBR = key) |
| BEFORE_HEADER | 82 | POST-QUERY | `IMPR1170.POST_QUERY(P_CR_STATUS => :P1170_CR_STATUS, P_CR_STAT_DESC => :P1170_CR_STAT_DESC);` | :P0_PAGE_PK IS NOT NULL | MCI_DATA.POST-QUERY |
| BEFORE_HEADER | 100 | HEADER TITLE | `FORMS_APX.HEADER_TITLE(P_MODULE_ID => :P1170_MODULE_ID, P_HERO_TITLE => :P1170_HERO_TITLE, DEFAULT_TITLE => 'بيانات السجل التجارى من وزارة التجارة');` | – | f345 hero title (OLB block TITLE) |
| AFTER_SUBMIT | 10 | CR_NBR KEY-NEXT-ITEM | `IMPR1170.CR_NBR_KEY_NEXT_ITEM(P_CR_NBR => :P1170_CR_NBR, P_PAGE_PK => :P0_PAGE_PK);` | :REQUEST = 'EXECUTE_QUERY' | MCI_DATA.CR_NBR.KEY-NEXT-ITEM (cache of today or MCI web service, then SET_BLOCK_PROPERTY DEFAULT_WHERE + EXECUTE_QUERY) |
| AFTER_SUBMIT | 20 | PRE-INSERT | `IMPR1170.PRE_INSERT;` | :REQUEST = 'CREATE' | block MCI_DATA: no insert from this page (page 0 CREATE refused, spec 0 #3) |
| AFTER_SUBMIT | 30 | PRE-UPDATE | `IMPR1170.PRE_UPDATE;` | :REQUEST = 'SAVE' | block MCI_DATA Update Allowed = false (page 0 SAVE refused) |
| AFTER_SUBMIT | 40 | PRE-DELETE | `IMPR1170.PRE_DELETE;` | :REQUEST = 'DELETE' | block MCI_DATA Delete Allowed = false (KEY-DELREC, page 0 DELETE refused) |

## 9. Computations

| Item | Point | Expression | Source |
|---|---|---|---|
| `P1170_HIJRI_DATE_FORMAT` | BEFORE_HEADER | `FORMS_APX.HIJRI_DATE_FORMAT` | Hijri date format from one place: Application Setting HIJRI_DATE_FORMAT (Forms mask MI-MM-YYYY) |

## 10. Dynamic Actions (page 1170)

| Name | Event | Element | Client condition | Actions | Source |
|---|---|---|---|---|---|
| CR_NBR KEY-NEXT-ITEM | change | P1170_CR_NBR | NOT_NULL | Submit Page EXECUTE_QUERY | MCI_DATA.CR_NBR.KEY-NEXT-ITEM (Submit Page EXECUTE_QUERY -> process CR_NBR KEY-NEXT-ITEM; a change also fires with the mouse) |

Page 117001: `SEARCH` (click → Refresh grid), `SEARCH KEY-ENTER` (keyup Enter → Refresh), `CLEAR WHEN-BUTTON-PRESSED`
(Clear + Refresh), `Hide` (page 0 toolbar hidden in the dialog), as the other search pages.

## 11. Alerts and messages

| Forms | APEX |
|---|---|
| STR.DISPALERT('بيانات السجل التجارى رقم … حالتة غير فعال أو بياناتة غير متاحة فى الوقت الحالى من خدمة الربط مع وزارة التجارة', 'ERROR') | `FORMS_APX.FORM_TRIGGER_FAILURE` in `CR_NBR_KEY_NEXT_ITEM` (page error) |
| page 0 CREATE / SAVE / DELETE | 'لا يمكن إضافة / تعديل / حذف بيانات من هذه الشاشة' (texts to agree; insert / delete texts = IMPR1150) |
| ON-ERROR / CGTE$CHECK_CONSTRAINT_VIO (`MCI_DATA_PK`, ORA-01031) | dropped: no DML on the page |

## 12. Branches and navigation

| Branch | Seq | Condition | Target |
|---|---|---|---|
| EXECUTE-QUERY | 10 | request `EXECUTE_QUERY` | page 1170, clear cache 1170 (`P0_PAGE_PK` set by the process) |
| IMPR1170 - stay in the form | 20 | – | page 1170, clear cache 1170, success message |

The search grid link opens page 1170 with `P0_PAGE_PK = CR_NBR` (the record is shown from the cache, without the service:
as Forms Execute-Query). Page 0 CLEAR empties `P0_PAGE_PK` → a new look-up.

## 13. Shared components

None created. Reused: page group `IMPR` (IMPR1110), Application Setting `HIJRI_DATE_FORMAT` (IMPR1110),
LOV `LOV_COMM_RGSTRTN_TYPE` (IMPR1130), f345 page 0 toolbar, FUNCS drawer and `NUMBER ONLY` DA.
Database: package `IMPR1170` 001; `LIB_USR.PRTL_NEBRAS_SERVICES` (**MISSING SOURCE**, unchanged).

## 14. Traceability (every Forms object)

437 objects: DROPPED 383, MAPPED 54.

| # | Type | Forms object | APEX component | Page | Package member | Status | Notes |
|---|---|---|---|---|---|---|---|
| 1 | BLOCK | `TITLE` | REGION | MCI_DATA_HERO | 1170 | - | MAPPED | OLB title bar -> f345 hero region (FORMS_APX.HEADER_TITLE) |
| 2 | BLOCK | `EDI_MSG` | - | - | - | - | DROPPED | OLB EDI message ticker - dropped (timers, IMPR1110 decision 2026-11-19) |
| 3 | BLOCK | `LSIDE` | REGION | FUNCS (page 0 drawer) | 0 | - | MAPPED | OLB side function menu -> page 0 FUNCS, f345 list Page Functions |
| 4 | BLOCK | `TOOLBAR` | REGION | P0_ACTIONS (page 0 toolbar, f345) | 0 | - | MAPPED | OLB toolbar -> f345 page 0 toolbar |
| 5 | BLOCK | `MCI_DATA` | REGION | MCI_DATA (Form, query only, key CR_NBR) | 1170 | - | MAPPED | Update / Delete Allowed = false; insert refused (spec 0 #3) |
| 6 | BLOCK | `MCI_OWNERS` | REGION | MCI_OWNERS (read-only Interactive Grid) | 1170 | - | MAPPED | detail of MCI_DATA by CR_NBR; 4 records shown, query only |
| 7 | ITEM | `TITLE.CGSO$CHECK_BOX_U` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 8 | ITEM | `TITLE.CGSO$CHAR_ARB_ED` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 9 | ITEM | `TITLE.CGSO$CHAR_ARB_DO_MLINE` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 10 | ITEM | `TITLE.CGSO$CHAR_ARB_ORA_LOV` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 11 | ITEM | `TITLE.CGSO$CHAR_ARB_DO_ENB_Y` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 12 | ITEM | `TITLE.CGSO$CHAR_ARB_MLINE` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 13 | ITEM | `TITLE.CGSO$CHAR_ARB` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 14 | ITEM | `TITLE.CGSO$CHAR_ARB_DO` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 15 | ITEM | `TITLE.SCREEN_NAME` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 16 | ITEM | `TITLE.USER_NAME` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 17 | ITEM | `TITLE.SYSTEM_DATE` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 18 | ITEM | `TITLE.VERSION` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 19 | ITEM | `EDI_MSG.EDI_MSG_TXT` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 20 | ITEM | `EDI_MSG.EDI_MSG_LOVE_BUT` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 21 | ITEM | `LSIDE.FN1` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 22 | ITEM | `LSIDE.FN50` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 23 | ITEM | `LSIDE.FN2` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 24 | ITEM | `LSIDE.FN49` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 25 | ITEM | `LSIDE.FN3` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 26 | ITEM | `LSIDE.FN48` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 27 | ITEM | `LSIDE.FN4` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 28 | ITEM | `LSIDE.FN47` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 29 | ITEM | `LSIDE.FN5` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 30 | ITEM | `LSIDE.FN46` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 31 | ITEM | `LSIDE.FN6` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 32 | ITEM | `LSIDE.FN45` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 33 | ITEM | `LSIDE.FN7` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 34 | ITEM | `LSIDE.FN44` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 35 | ITEM | `LSIDE.FN8` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 36 | ITEM | `LSIDE.FN43` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 37 | ITEM | `LSIDE.FN9` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 38 | ITEM | `LSIDE.FN42` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 39 | ITEM | `LSIDE.FN10` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 40 | ITEM | `LSIDE.FN41` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 41 | ITEM | `LSIDE.FN11` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 42 | ITEM | `LSIDE.FN40` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 43 | ITEM | `LSIDE.FN12` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 44 | ITEM | `LSIDE.FN39` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 45 | ITEM | `LSIDE.FN13` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 46 | ITEM | `LSIDE.FN38` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 47 | ITEM | `LSIDE.FN14` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 48 | ITEM | `LSIDE.FN37` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 49 | ITEM | `LSIDE.FN15` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 50 | ITEM | `LSIDE.FN36` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 51 | ITEM | `LSIDE.FN16` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 52 | ITEM | `LSIDE.FN17` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 53 | ITEM | `LSIDE.FN34` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 54 | ITEM | `LSIDE.FN35` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 55 | ITEM | `LSIDE.FN18` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 56 | ITEM | `LSIDE.FN33` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 57 | ITEM | `LSIDE.FN19` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 58 | ITEM | `LSIDE.FN32` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 59 | ITEM | `LSIDE.FN20` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 60 | ITEM | `LSIDE.FN31` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 61 | ITEM | `LSIDE.FN21` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 62 | ITEM | `LSIDE.FN30` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 63 | ITEM | `LSIDE.FN22` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 64 | ITEM | `LSIDE.FN29` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 65 | ITEM | `LSIDE.FN23` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 66 | ITEM | `LSIDE.FN28` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 67 | ITEM | `LSIDE.FN24` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 68 | ITEM | `LSIDE.FN27` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 69 | ITEM | `LSIDE.FN25` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 70 | ITEM | `LSIDE.FN26` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 71 | ITEM | `TOOLBAR.DUMMY` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 72 | ITEM | `TOOLBAR.SAVE` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 73 | ITEM | `TOOLBAR.CLEAR_ALL` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 74 | ITEM | `TOOLBAR.EXIT` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 75 | ITEM | `TOOLBAR.EXIT1` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 76 | ITEM | `TOOLBAR.ENTER` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 77 | ITEM | `TOOLBAR.EXECUTE` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 78 | ITEM | `TOOLBAR.REMOVE` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 79 | ITEM | `TOOLBAR.LIST_VALUE` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 80 | ITEM | `TOOLBAR.HELP` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 81 | ITEM | `TOOLBAR.LAST_REC` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 82 | ITEM | `TOOLBAR.RE_ENTER_QUERY` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 83 | ITEM | `TOOLBAR.FIRST_REC` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 84 | ITEM | `TOOLBAR.PAGE_UP` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 85 | ITEM | `TOOLBAR.PAGE_DOWN` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 86 | ITEM | `TOOLBAR.FUN_BUT` | - | - | - | - | DROPPED | OLB frame item -> f345 page template / page 0 toolbar / FUNCS |
| 87 | ITEM | `MCI_DATA.CR_NBR` | PAGE_ITEM | P1170_CR_NBR | 1170 | - | MAPPED | spec section 4 |
| 88 | ITEM | `MCI_DATA.CR_TYPE` | PAGE_ITEM | P1170_CR_TYPE | 1170 | - | MAPPED | spec section 4 |
| 89 | ITEM | `MCI_DATA.MAIN_CR_NBR` | PAGE_ITEM | P1170_MAIN_CR_NBR | 1170 | - | MAPPED | spec section 4 |
| 90 | ITEM | `MCI_DATA.CR_STATUS` | PAGE_ITEM | P1170_CR_STATUS | 1170 | - | MAPPED | spec section 4 |
| 91 | ITEM | `MCI_DATA.CR_STAT_DESC` | PAGE_ITEM | P1170_CR_STAT_DESC | 1170 | - | MAPPED | spec section 4 |
| 92 | ITEM | `MCI_DATA.CR_ISSUE_DATE` | PAGE_ITEM | P1170_CR_ISSUE_DATE | 1170 | - | MAPPED | spec section 4 |
| 93 | ITEM | `MCI_DATA.CR_EXPIRY_DATE` | PAGE_ITEM | P1170_CR_EXPIRY_DATE | 1170 | - | MAPPED | not displayed |
| 94 | ITEM | `MCI_DATA.CR_CITY_AR` | PAGE_ITEM | P1170_CR_CITY_AR | 1170 | - | MAPPED | spec section 4 |
| 95 | ITEM | `MCI_DATA.CR_CAPITAL` | PAGE_ITEM | P1170_CR_CAPITAL | 1170 | - | MAPPED | spec section 4 |
| 96 | ITEM | `MCI_DATA.CR_NAME_AR` | PAGE_ITEM | P1170_CR_NAME_AR | 1170 | - | MAPPED | spec section 4 |
| 97 | ITEM | `MCI_DATA.LEGAL_TYPE_A` | PAGE_ITEM | P1170_LEGAL_TYPE_A | 1170 | - | MAPPED | spec section 4 |
| 98 | ITEM | `MCI_DATA.LEGAL_TYPE_E` | PAGE_ITEM | P1170_LEGAL_TYPE_E | 1170 | - | MAPPED | spec section 4 |
| 99 | ITEM | `MCI_DATA.CR_PHONE_NO` | PAGE_ITEM | P1170_CR_PHONE_NO | 1170 | - | MAPPED | spec section 4 |
| 100 | ITEM | `MCI_DATA.CR_FAX_NO` | PAGE_ITEM | P1170_CR_FAX_NO | 1170 | - | MAPPED | spec section 4 |
| 101 | ITEM | `MCI_DATA.CR_ADDRESS` | PAGE_ITEM | P1170_CR_ADDRESS | 1170 | - | MAPPED | spec section 4 |
| 102 | ITEM | `MCI_DATA.CR_ACTIVITIES` | PAGE_ITEM | P1170_CR_ACTIVITIES | 1170 | - | MAPPED | spec section 4 |
| 103 | ITEM | `MCI_OWNERS.OWNER_NAME` | IG_COLUMN | MCI_OWNERS.OWNER_NAME | 1170 | - | MAPPED | spec section 3 |
| 104 | ITEM | `MCI_OWNERS.NATIONAL_ID` | IG_COLUMN | MCI_OWNERS.NATIONAL_ID | 1170 | - | MAPPED | spec section 3 |
| 105 | ITEM | `MCI_OWNERS.OWNER_NATIONALITY_AR` | IG_COLUMN | MCI_OWNERS.OWNER_NATIONALITY_AR | 1170 | - | MAPPED | spec section 3 |
| 106 | ITEM | `MCI_OWNERS.OWNER_NATIONALITY_EN` | IG_COLUMN | MCI_OWNERS.OWNER_NATIONALITY_EN | 1170 | - | MAPPED | spec section 3 |
| 107 | ITEM | `MCI_OWNERS.RELATION_TYPE` | IG_COLUMN | MCI_OWNERS.RELATION_TYPE | 1170 | - | MAPPED | hidden column |
| 108 | ITEM | `MCI_OWNERS.RELATION_DESC` | IG_COLUMN | MCI_OWNERS.RELATION_DESC | 1170 | - | MAPPED | spec section 3 |
| 109 | ITEM | `MCI_OWNERS.CR_NBR` | IG_COLUMN | MCI_OWNERS.CR_NBR | 1170 | - | MAPPED | hidden column |
| 110 | ITEM | `MCI_OWNERS.OWNER_ISN` | IG_COLUMN | MCI_OWNERS.OWNER_ISN | 1170 | - | MAPPED | hidden column |
| 111 | TRIGGER | `FORM.KEY-EDIT` | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / CGBS coordination / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| 112 | TRIGGER | `FORM.KEY-DUPREC` | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / CGBS coordination / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| 113 | TRIGGER | `FORM.PRE-FORM` | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / CGBS coordination / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| 114 | TRIGGER | `FORM.WHEN-NEW-FORM-INSTANCE` | PROCESS | PARAMETERS / HEADER TITLE | 1170 | - | MAPPED | NIB frame + CG$WHEN_NEW_FORM_INSTANCE (list, coordination); the globals it clears are unused |
| 115 | TRIGGER | `FORM.WHEN-WINDOW-ACTIVATED` | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / CGBS coordination / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| 116 | TRIGGER | `FORM.KEY-ENTQRY` | PAGE | IMPR1170_SEARCH | 117001 | - | MAPPED | NIB.KEY_ENTQRY -> page 0 SEARCH |
| 117 | TRIGGER | `FORM.ON-ERROR` | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / CGBS coordination / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| 118 | TRIGGER | `FORM.ON-MESSAGE` | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / CGBS coordination / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| 119 | TRIGGER | `FORM.KEY-CLRBLK` | BUTTON | CLEAR (page 0 toolbar) | 0 | - | MAPPED | NIB.KEY_CLRBLK |
| 120 | TRIGGER | `FORM.KEY-DELREC` | PROCESS | PRE-DELETE | 1170 | IMPR1170.PRE_DELETE | MAPPED | NIB.KEY_DELREC; block Delete Allowed = false -> refused |
| 121 | TRIGGER | `FORM.KEY-F5` | PROCESS | PRE-INSERT / PRE-UPDATE | 1170 | IMPR1170.PRE_INSERT | MAPPED | NIB.KEY_F5 (commit) -> page 0 CREATE / SAVE refused |
| 122 | TRIGGER | `FORM.KEY-F4` | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / CGBS coordination / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| 123 | TRIGGER | `FORM.KEY-NXTREC` | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / CGBS coordination / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| 124 | TRIGGER | `FORM.KEY-PRVREC` | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / CGBS coordination / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| 125 | TRIGGER | `FORM.KEY-DOWN` | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / CGBS coordination / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| 126 | TRIGGER | `FORM.KEY-UP` | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / CGBS coordination / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| 127 | TRIGGER | `FORM.KEY-SCRUP` | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / CGBS coordination / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| 128 | TRIGGER | `FORM.KEY-SCRDOWN` | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / CGBS coordination / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| 129 | TRIGGER | `FORM.KEY-PRINT` | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / CGBS coordination / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| 130 | TRIGGER | `FORM.KEY-EXIT` | BUTTON | BACK (page 0 toolbar) | 0 | - | MAPPED | NIB.KEY_EXIT |
| 131 | TRIGGER | `FORM.WHEN-MOUSE-DOWN` | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / CGBS coordination / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| 132 | TRIGGER | `FORM.KEY-EXEQRY` | PAGE | IMPR1170_SEARCH | 117001 | - | MAPPED | NIB.KEY_EXEQRY -> search grid |
| 133 | TRIGGER | `FORM.KEY-F9` | REGION | FUNCS (page 0) | 0 | - | MAPPED | functions menu; ADJ_FUNS is empty |
| 134 | TRIGGER | `FORM.WHEN-TIMER-EXPIRED` | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / CGBS coordination / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| 135 | TRIGGER | `FORM.KEY-HELP` | - | - | - | - | DROPPED | Designer help file (empty CG$HP_HFILE) |
| 136 | TRIGGER | `FORM.WHEN-NEW-BLOCK-INSTANCE` | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / CGBS coordination / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| 137 | TRIGGER | `FORM.ON-CLEAR-DETAILS` | REGION | MCI_OWNERS | 1170 | - | MAPPED | CGBS$.CLEAR_MASTER_DETAIL -> empty grid without a master |
| 138 | TRIGGER | `FORM.ON-POPULATE-DETAILS` | REGION | MCI_OWNERS (grid query WHERE cr_nbr = :P1170_CR_NBR) | 1170 | - | MAPPED | CGBS$.QUERY_DETAILS -> the grid query of the shown master |
| 139 | TRIGGER | `FORM.KEY-CQUERY` | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / CGBS coordination / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| 140 | TRIGGER | `FORM.KEY-CLRREC` | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / CGBS coordination / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| 141 | TRIGGER | `FORM.KEY-NXTKEY` | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / CGBS coordination / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| 142 | TRIGGER | `FORM.KEY-MENU` | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / CGBS coordination / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| 143 | TRIGGER | `FORM.KEY-CLRFRM` | BUTTON | CLEAR (page 0 toolbar) | 0 | - | MAPPED | clear_form + CG$WHEN_NEW_FORM_INSTANCE (list: shared LOV) |
| 144 | TRIGGER | `TITLE.CGSO$CHAR_ARB_ED.KEY-LISTVAL` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 145 | TRIGGER | `TITLE.CGSO$CHAR_ARB_DO_ENB_Y.KEY-LISTVAL` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 146 | TRIGGER | `TITLE.CGSO$CHAR_ARB_MLINE.KEY-LISTVAL` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 147 | TRIGGER | `TITLE.CGSO$CHAR_ARB.KEY-LISTVAL` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 148 | TRIGGER | `TITLE.CGSO$CHAR_ARB_DO.KEY-LISTVAL` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 149 | TRIGGER | `TITLE.SYSTEM_DATE.WHEN-VALIDATE-ITEM` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 150 | TRIGGER | `EDI_MSG.EDI_MSG_LOVE_BUT.WHEN-BUTTON-PRESSED` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 151 | TRIGGER | `LSIDE.FN1.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 152 | TRIGGER | `LSIDE.FN1.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 153 | TRIGGER | `LSIDE.FN1.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 154 | TRIGGER | `LSIDE.FN50.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 155 | TRIGGER | `LSIDE.FN50.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 156 | TRIGGER | `LSIDE.FN50.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 157 | TRIGGER | `LSIDE.FN2.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 158 | TRIGGER | `LSIDE.FN2.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 159 | TRIGGER | `LSIDE.FN2.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 160 | TRIGGER | `LSIDE.FN49.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 161 | TRIGGER | `LSIDE.FN49.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 162 | TRIGGER | `LSIDE.FN49.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 163 | TRIGGER | `LSIDE.FN3.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 164 | TRIGGER | `LSIDE.FN3.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 165 | TRIGGER | `LSIDE.FN3.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 166 | TRIGGER | `LSIDE.FN48.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 167 | TRIGGER | `LSIDE.FN48.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 168 | TRIGGER | `LSIDE.FN48.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 169 | TRIGGER | `LSIDE.FN4.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 170 | TRIGGER | `LSIDE.FN4.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 171 | TRIGGER | `LSIDE.FN4.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 172 | TRIGGER | `LSIDE.FN47.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 173 | TRIGGER | `LSIDE.FN47.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 174 | TRIGGER | `LSIDE.FN47.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 175 | TRIGGER | `LSIDE.FN5.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 176 | TRIGGER | `LSIDE.FN5.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 177 | TRIGGER | `LSIDE.FN5.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 178 | TRIGGER | `LSIDE.FN46.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 179 | TRIGGER | `LSIDE.FN46.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 180 | TRIGGER | `LSIDE.FN46.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 181 | TRIGGER | `LSIDE.FN6.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 182 | TRIGGER | `LSIDE.FN6.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 183 | TRIGGER | `LSIDE.FN6.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 184 | TRIGGER | `LSIDE.FN45.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 185 | TRIGGER | `LSIDE.FN45.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 186 | TRIGGER | `LSIDE.FN45.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 187 | TRIGGER | `LSIDE.FN7.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 188 | TRIGGER | `LSIDE.FN7.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 189 | TRIGGER | `LSIDE.FN7.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 190 | TRIGGER | `LSIDE.FN44.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 191 | TRIGGER | `LSIDE.FN44.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 192 | TRIGGER | `LSIDE.FN44.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 193 | TRIGGER | `LSIDE.FN8.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 194 | TRIGGER | `LSIDE.FN8.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 195 | TRIGGER | `LSIDE.FN8.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 196 | TRIGGER | `LSIDE.FN43.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 197 | TRIGGER | `LSIDE.FN43.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 198 | TRIGGER | `LSIDE.FN43.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 199 | TRIGGER | `LSIDE.FN9.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 200 | TRIGGER | `LSIDE.FN9.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 201 | TRIGGER | `LSIDE.FN9.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 202 | TRIGGER | `LSIDE.FN42.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 203 | TRIGGER | `LSIDE.FN42.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 204 | TRIGGER | `LSIDE.FN42.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 205 | TRIGGER | `LSIDE.FN10.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 206 | TRIGGER | `LSIDE.FN10.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 207 | TRIGGER | `LSIDE.FN10.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 208 | TRIGGER | `LSIDE.FN41.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 209 | TRIGGER | `LSIDE.FN41.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 210 | TRIGGER | `LSIDE.FN41.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 211 | TRIGGER | `LSIDE.FN11.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 212 | TRIGGER | `LSIDE.FN11.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 213 | TRIGGER | `LSIDE.FN11.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 214 | TRIGGER | `LSIDE.FN40.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 215 | TRIGGER | `LSIDE.FN40.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 216 | TRIGGER | `LSIDE.FN40.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 217 | TRIGGER | `LSIDE.FN12.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 218 | TRIGGER | `LSIDE.FN12.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 219 | TRIGGER | `LSIDE.FN12.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 220 | TRIGGER | `LSIDE.FN39.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 221 | TRIGGER | `LSIDE.FN39.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 222 | TRIGGER | `LSIDE.FN39.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 223 | TRIGGER | `LSIDE.FN13.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 224 | TRIGGER | `LSIDE.FN13.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 225 | TRIGGER | `LSIDE.FN13.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 226 | TRIGGER | `LSIDE.FN38.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 227 | TRIGGER | `LSIDE.FN38.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 228 | TRIGGER | `LSIDE.FN38.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 229 | TRIGGER | `LSIDE.FN14.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 230 | TRIGGER | `LSIDE.FN14.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 231 | TRIGGER | `LSIDE.FN14.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 232 | TRIGGER | `LSIDE.FN37.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 233 | TRIGGER | `LSIDE.FN37.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 234 | TRIGGER | `LSIDE.FN37.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 235 | TRIGGER | `LSIDE.FN15.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 236 | TRIGGER | `LSIDE.FN15.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 237 | TRIGGER | `LSIDE.FN15.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 238 | TRIGGER | `LSIDE.FN36.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 239 | TRIGGER | `LSIDE.FN36.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 240 | TRIGGER | `LSIDE.FN36.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 241 | TRIGGER | `LSIDE.FN16.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 242 | TRIGGER | `LSIDE.FN16.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 243 | TRIGGER | `LSIDE.FN16.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 244 | TRIGGER | `LSIDE.FN17.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 245 | TRIGGER | `LSIDE.FN17.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 246 | TRIGGER | `LSIDE.FN17.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 247 | TRIGGER | `LSIDE.FN34.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 248 | TRIGGER | `LSIDE.FN34.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 249 | TRIGGER | `LSIDE.FN34.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 250 | TRIGGER | `LSIDE.FN35.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 251 | TRIGGER | `LSIDE.FN35.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 252 | TRIGGER | `LSIDE.FN35.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 253 | TRIGGER | `LSIDE.FN18.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 254 | TRIGGER | `LSIDE.FN18.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 255 | TRIGGER | `LSIDE.FN18.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 256 | TRIGGER | `LSIDE.FN33.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 257 | TRIGGER | `LSIDE.FN33.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 258 | TRIGGER | `LSIDE.FN33.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 259 | TRIGGER | `LSIDE.FN19.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 260 | TRIGGER | `LSIDE.FN19.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 261 | TRIGGER | `LSIDE.FN19.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 262 | TRIGGER | `LSIDE.FN32.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 263 | TRIGGER | `LSIDE.FN32.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 264 | TRIGGER | `LSIDE.FN32.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 265 | TRIGGER | `LSIDE.FN20.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 266 | TRIGGER | `LSIDE.FN20.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 267 | TRIGGER | `LSIDE.FN20.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 268 | TRIGGER | `LSIDE.FN31.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 269 | TRIGGER | `LSIDE.FN31.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 270 | TRIGGER | `LSIDE.FN31.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 271 | TRIGGER | `LSIDE.FN21.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 272 | TRIGGER | `LSIDE.FN21.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 273 | TRIGGER | `LSIDE.FN21.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 274 | TRIGGER | `LSIDE.FN30.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 275 | TRIGGER | `LSIDE.FN30.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 276 | TRIGGER | `LSIDE.FN30.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 277 | TRIGGER | `LSIDE.FN22.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 278 | TRIGGER | `LSIDE.FN22.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 279 | TRIGGER | `LSIDE.FN22.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 280 | TRIGGER | `LSIDE.FN29.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 281 | TRIGGER | `LSIDE.FN29.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 282 | TRIGGER | `LSIDE.FN29.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 283 | TRIGGER | `LSIDE.FN23.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 284 | TRIGGER | `LSIDE.FN23.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 285 | TRIGGER | `LSIDE.FN23.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 286 | TRIGGER | `LSIDE.FN28.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 287 | TRIGGER | `LSIDE.FN28.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 288 | TRIGGER | `LSIDE.FN28.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 289 | TRIGGER | `LSIDE.FN24.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 290 | TRIGGER | `LSIDE.FN24.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 291 | TRIGGER | `LSIDE.FN24.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 292 | TRIGGER | `LSIDE.FN27.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 293 | TRIGGER | `LSIDE.FN27.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 294 | TRIGGER | `LSIDE.FN27.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 295 | TRIGGER | `LSIDE.FN25.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 296 | TRIGGER | `LSIDE.FN25.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 297 | TRIGGER | `LSIDE.FN25.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 298 | TRIGGER | `LSIDE.FN26.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 299 | TRIGGER | `LSIDE.FN26.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 300 | TRIGGER | `LSIDE.FN26.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 301 | TRIGGER | `TOOLBAR.KEY-DOWN` | - | - | - | - | DROPPED | OLB frame block trigger (toolbar keys) |
| 302 | TRIGGER | `TOOLBAR.KEY-UP` | - | - | - | - | DROPPED | OLB frame block trigger (toolbar keys) |
| 303 | TRIGGER | `TOOLBAR.KEY-NEXT-ITEM` | - | - | - | - | DROPPED | OLB frame block trigger (toolbar keys) |
| 304 | TRIGGER | `TOOLBAR.SAVE.WHEN-BUTTON-PRESSED` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 305 | TRIGGER | `TOOLBAR.CLEAR_ALL.WHEN-BUTTON-PRESSED` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 306 | TRIGGER | `TOOLBAR.EXIT.WHEN-BUTTON-PRESSED` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 307 | TRIGGER | `TOOLBAR.EXIT1.WHEN-BUTTON-PRESSED` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 308 | TRIGGER | `TOOLBAR.ENTER.WHEN-BUTTON-PRESSED` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 309 | TRIGGER | `TOOLBAR.EXECUTE.WHEN-BUTTON-PRESSED` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 310 | TRIGGER | `TOOLBAR.REMOVE.WHEN-BUTTON-PRESSED` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 311 | TRIGGER | `TOOLBAR.LIST_VALUE.WHEN-BUTTON-PRESSED` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 312 | TRIGGER | `TOOLBAR.HELP.WHEN-BUTTON-PRESSED` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 313 | TRIGGER | `TOOLBAR.LAST_REC.WHEN-BUTTON-PRESSED` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 314 | TRIGGER | `TOOLBAR.RE_ENTER_QUERY.WHEN-BUTTON-PRESSED` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 315 | TRIGGER | `TOOLBAR.FIRST_REC.WHEN-BUTTON-PRESSED` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 316 | TRIGGER | `TOOLBAR.PAGE_UP.WHEN-BUTTON-PRESSED` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 317 | TRIGGER | `TOOLBAR.PAGE_DOWN.WHEN-BUTTON-PRESSED` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 318 | TRIGGER | `TOOLBAR.FUN_BUT.WHEN-MOUSE-UP` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 319 | TRIGGER | `TOOLBAR.FUN_BUT.WHEN-MOUSE-DOWN` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 320 | TRIGGER | `MCI_DATA.ON-ERROR` | - | - | - | - | DROPPED | constraint / privilege messages: the page does no DML on MCI_DATA |
| 321 | TRIGGER | `MCI_DATA.KEY-HELP` | - | - | - | - | DROPPED | Designer help file (empty CG$HP_HFILE) |
| 322 | TRIGGER | `MCI_DATA.POST-QUERY` | PROCESS | POST-QUERY | 1170 | IMPR1170.POST_QUERY | MAPPED | Before Header after Initialize form (CR_STAT_DESC) |
| 323 | TRIGGER | `MCI_DATA.CR_NBR.KEY-LISTVAL` | - | - | - | - | DROPPED | Designer "may the LOV be shown" check: the form has no LOV |
| 324 | TRIGGER | `MCI_DATA.CR_NBR.KEY-NEXT-ITEM` | PROCESS | CR_NBR KEY-NEXT-ITEM (+ DA, branch EXECUTE-QUERY) | 1170 | IMPR1170.CR_NBR_KEY_NEXT_ITEM | MAPPED | cache of today or MCI web service, then the query |
| 325 | TRIGGER | `MCI_DATA.CR_NBR.WHEN-VALIDATE-ITEM` | - | - | - | - | DROPPED | NULL; |
| 326 | TRIGGER | `MCI_DATA.MAIN_CR_NBR.KEY-LISTVAL` | - | - | - | - | DROPPED | Designer "may the LOV be shown" check: the form has no LOV |
| 327 | TRIGGER | `MCI_DATA.CR_STATUS.KEY-LISTVAL` | - | - | - | - | DROPPED | Designer "may the LOV be shown" check: the form has no LOV |
| 328 | TRIGGER | `MCI_DATA.CR_STAT_DESC.KEY-LISTVAL` | - | - | - | - | DROPPED | Designer "may the LOV be shown" check: the form has no LOV |
| 329 | TRIGGER | `MCI_DATA.CR_ISSUE_DATE.WHEN-VALIDATE-ITEM` | - | - | - | - | DROPPED | Hijri check of an item that is never enterable (display only) |
| 330 | TRIGGER | `MCI_DATA.CR_EXPIRY_DATE.WHEN-VALIDATE-ITEM` | - | - | - | - | DROPPED | Hijri check of an item that is never enterable (display only) |
| 331 | TRIGGER | `MCI_DATA.CR_CITY_AR.KEY-LISTVAL` | - | - | - | - | DROPPED | Designer "may the LOV be shown" check: the form has no LOV |
| 332 | TRIGGER | `MCI_DATA.CR_CAPITAL.KEY-LISTVAL` | - | - | - | - | DROPPED | Designer "may the LOV be shown" check: the form has no LOV |
| 333 | TRIGGER | `MCI_DATA.CR_NAME_AR.KEY-LISTVAL` | - | - | - | - | DROPPED | Designer "may the LOV be shown" check: the form has no LOV |
| 334 | TRIGGER | `MCI_DATA.LEGAL_TYPE_A.KEY-LISTVAL` | - | - | - | - | DROPPED | Designer "may the LOV be shown" check: the form has no LOV |
| 335 | TRIGGER | `MCI_DATA.LEGAL_TYPE_E.KEY-LISTVAL` | - | - | - | - | DROPPED | Designer "may the LOV be shown" check: the form has no LOV |
| 336 | TRIGGER | `MCI_DATA.CR_PHONE_NO.KEY-LISTVAL` | - | - | - | - | DROPPED | Designer "may the LOV be shown" check: the form has no LOV |
| 337 | TRIGGER | `MCI_DATA.CR_FAX_NO.KEY-LISTVAL` | - | - | - | - | DROPPED | Designer "may the LOV be shown" check: the form has no LOV |
| 338 | TRIGGER | `MCI_DATA.CR_ADDRESS.KEY-LISTVAL` | - | - | - | - | DROPPED | Designer "may the LOV be shown" check: the form has no LOV |
| 339 | TRIGGER | `MCI_DATA.CR_ACTIVITIES.KEY-LISTVAL` | - | - | - | - | DROPPED | Designer "may the LOV be shown" check: the form has no LOV |
| 340 | TRIGGER | `MCI_OWNERS.ON-ERROR` | - | - | - | - | DROPPED | coordination / constraint messages: read-only grid |
| 341 | TRIGGER | `MCI_OWNERS.KEY-HELP` | - | - | - | - | DROPPED | Designer help file (empty CG$HP_HFILE) |
| 342 | TRIGGER | `MCI_OWNERS.POST-QUERY` | REGION | MCI_OWNERS (outer join MCI_RELATION_TYPES) | 1170 | - | MAPPED | RELATION_DESC in the grid query |
| 343 | TRIGGER | `MCI_OWNERS.OWNER_NAME.KEY-LISTVAL` | - | - | - | - | DROPPED | Designer "may the LOV be shown" check: the form has no LOV |
| 344 | TRIGGER | `MCI_OWNERS.NATIONAL_ID.KEY-LISTVAL` | - | - | - | - | DROPPED | Designer "may the LOV be shown" check: the form has no LOV |
| 345 | TRIGGER | `MCI_OWNERS.OWNER_NATIONALITY_AR.KEY-LISTVAL` | - | - | - | - | DROPPED | Designer "may the LOV be shown" check: the form has no LOV |
| 346 | TRIGGER | `MCI_OWNERS.OWNER_NATIONALITY_EN.KEY-LISTVAL` | - | - | - | - | DROPPED | Designer "may the LOV be shown" check: the form has no LOV |
| 347 | TRIGGER | `MCI_OWNERS.RELATION_TYPE.KEY-LISTVAL` | - | - | - | - | DROPPED | Designer "may the LOV be shown" check: the form has no LOV |
| 348 | TRIGGER | `MCI_OWNERS.RELATION_DESC.KEY-LISTVAL` | - | - | - | - | DROPPED | Designer "may the LOV be shown" check: the form has no LOV |
| 349 | TRIGGER | `MCI_OWNERS.CR_NBR.KEY-LISTVAL` | - | - | - | - | DROPPED | Designer "may the LOV be shown" check: the form has no LOV |
| 350 | PROGRAM_UNIT | `CHECK_TIMEOUT` | - | - | - | - | DROPPED | NIB wrapper not called by active code (timers, EDI ticker, window, print) |
| 351 | PROGRAM_UNIT | `MOUSE_CLICK` | REGION | FUNCS (page 0) | 0 | - | MAPPED | function list click |
| 352 | PROGRAM_UNIT | `TOGGEL_WND` | - | - | - | - | DROPPED | NIB wrapper not called by active code (timers, EDI ticker, window, print) |
| 353 | PROGRAM_UNIT | `PRINT_REPORT` | - | - | - | - | DROPPED | NIB wrapper not called by active code (timers, EDI ticker, window, print) |
| 354 | PROGRAM_UNIT | `EXECUTE_FUNCTION` | REGION | FUNCS (page 0) | 0 | - | MAPPED | f345 Page Functions (the form has no function of its own) |
| 355 | PROGRAM_UNIT | `TERMINATE_FUN` | - | - | - | - | DROPPED | NIB wrapper not called by active code (timers, EDI ticker, window, print) |
| 356 | PROGRAM_UNIT | `CHECK_EDI_MSG_LOV` | - | - | - | - | DROPPED | NIB wrapper not called by active code (timers, EDI ticker, window, print) |
| 357 | PROGRAM_UNIT | `CHECK_EDI_MSG_TIMER` | - | - | - | - | DROPPED | NIB wrapper not called by active code (timers, EDI ticker, window, print) |
| 358 | PROGRAM_UNIT | `CHECK_EDI_ROLE_ID` | - | - | - | - | DROPPED | NIB wrapper not called by active code (timers, EDI ticker, window, print) |
| 359 | PROGRAM_UNIT | `EDI_MSG_LOV` | - | - | - | - | DROPPED | NIB wrapper not called by active code (timers, EDI ticker, window, print) |
| 360 | PROGRAM_UNIT | `FOR_EDI_MSG` | - | - | - | - | DROPPED | NIB wrapper not called by active code (timers, EDI ticker, window, print) |
| 361 | PROGRAM_UNIT | `RETURN_MSG` | - | - | - | - | DROPPED | NIB wrapper not called by active code (timers, EDI ticker, window, print) |
| 362 | PROGRAM_UNIT | `TURN_MSG` | - | - | - | - | DROPPED | NIB wrapper not called by active code (timers, EDI ticker, window, print) |
| 363 | PROGRAM_UNIT | `WHEN_TIMER_EXPIRED_MSG` | - | - | - | - | DROPPED | NIB wrapper not called by active code (timers, EDI ticker, window, print) |
| 364 | PROGRAM_UNIT | `CG$WHEN_NEW_FORM_INSTANCE` | - | - | - | - | DROPPED | list -> shared LOV; CGBS coordination -> grid query |
| 365 | PROGRAM_UNIT | `CGDV$POPULATE_DYNAMIC_LISTS` | LOV | LOV_COMM_RGSTRTN_TYPE (IMPR1130) | 1170 | - | MAPPED | LOV_APX.REFERENCE_CODES(COMM_RGSTRTN_TYPE) on P1170_CR_TYPE |
| 366 | PROGRAM_UNIT | `CGTE$CHECK_CONSTRAINT_VIO` | - | - | - | - | DROPPED | MCI_DATA_PK message: the page does not insert |
| 367 | PROGRAM_UNIT | `CGBS$TOGGLE` | - | - | - | - | DROPPED | Designer block synchronisation (query mode toggle) |
| 368 | PROGRAM_UNIT | `CGBS$SET_QUERY_MODE` | - | - | - | - | DROPPED | Designer block synchronisation |
| 369 | PROGRAM_UNIT | `CGBS$MESSAGE_QUERY_MODE` | - | - | - | - | DROPPED | Designer block synchronisation |
| 370 | PROGRAM_UNIT | `EXEC_FUNS` | - | - | - | - | DROPPED | body NULL; (broker-authorization code commented out) |
| 371 | PROGRAM_UNIT | `ADJ_FUNS` | - | - | - | - | DROPPED | body NULL; |
| 372 | RELATION | `CGFK$MCI_OWNER_MCI_DATA_FK` | REGION | MCI_OWNERS (WHERE cr_nbr = :P1170_CR_NBR) | 1170 | - | MAPPED | MCI_DATA.CR_NBR = MCI_OWNERS.CR_NBR |
| 373 | RECORD_GROUP | `CGDV$DLRG (runtime, CR_TYPE)` | LOV | LOV_COMM_RGSTRTN_TYPE (IMPR1130) | 1170 | - | MAPPED | CG_REF_CODES COMM_RGSTRTN_TYPE |
| 374 | ALERT | `CG$ASK_COMMIT` | - | - | - | - | DROPPED | OLB alert not referenced by this form |
| 375 | ALERT | `USR_CONFIRM_B` | - | - | - | - | DROPPED | OLB alert not referenced by this form |
| 376 | ALERT | `USR_CONFIRM` | - | - | - | - | DROPPED | OLB alert not referenced by this form |
| 377 | ALERT | `USR_WARNING_C` | - | - | - | - | DROPPED | OLB alert not referenced by this form |
| 378 | ALERT | `USR_WARNING_B` | - | - | - | - | DROPPED | OLB alert not referenced by this form |
| 379 | ALERT | `CFG_WARNING_A` | - | - | - | - | DROPPED | OLB alert not referenced by this form |
| 380 | ALERT | `CFG_INFORMATION` | - | - | - | - | DROPPED | OLB alert not referenced by this form |
| 381 | ALERT | `CFG_ERROR` | APP_ITEM | page messages (FORMS_APX.FORM_TRIGGER_FAILURE) | - | - | MAPPED | STR.DISPALERT ERROR of KEY-NEXT-ITEM |
| 382 | ALERT | `CFG_SYSTEM_ERROR` | - | - | - | - | DROPPED | OLB alert not referenced by this form |
| 383 | ALERT | `CFG_ASK_COMMIT` | - | - | - | - | DROPPED | OLB alert not referenced by this form |
| 384 | PARAMETER | `P_SHPG_AGNT_NBR` | - | - | - | - | DROPPED | used only by the OLB frame (EXECUTE_FUNCTION parameter list, print, EDI, timers) |
| 385 | PARAMETER | `P_CTRL_LAST_EXEC_CD` | - | - | - | - | DROPPED | used only by the OLB frame (EXECUTE_FUNCTION parameter list, print, EDI, timers) |
| 386 | PARAMETER | `P_BANK_CD` | - | - | - | - | DROPPED | used only by the OLB frame (EXECUTE_FUNCTION parameter list, print, EDI, timers) |
| 387 | PARAMETER | `P_BANK_BRNCH_CD` | - | - | - | - | DROPPED | used only by the OLB frame (EXECUTE_FUNCTION parameter list, print, EDI, timers) |
| 388 | PARAMETER | `P_BRKR_PORT_CD` | - | - | - | - | DROPPED | used only by the OLB frame (EXECUTE_FUNCTION parameter list, print, EDI, timers) |
| 389 | PARAMETER | `P_LIC_TYPE` | - | - | - | - | DROPPED | used only by the OLB frame (EXECUTE_FUNCTION parameter list, print, EDI, timers) |
| 390 | PARAMETER | `P_BRKR_NBR` | - | - | - | - | DROPPED | used only by the OLB frame (EXECUTE_FUNCTION parameter list, print, EDI, timers) |
| 391 | PARAMETER | `P_CLASS_CD` | - | - | - | - | DROPPED | used only by the OLB frame (EXECUTE_FUNCTION parameter list, print, EDI, timers) |
| 392 | PARAMETER | `P_JOB_ID` | - | - | - | - | DROPPED | used only by the OLB frame (EXECUTE_FUNCTION parameter list, print, EDI, timers) |
| 393 | PARAMETER | `P_CURRENT_ITEM` | - | - | - | - | DROPPED | used only by the OLB frame (EXECUTE_FUNCTION parameter list, print, EDI, timers) |
| 394 | PARAMETER | `P_GROUP_CD` | - | - | - | - | DROPPED | used only by the OLB frame (EXECUTE_FUNCTION parameter list, print, EDI, timers) |
| 395 | PARAMETER | `P_USER_TYPE` | - | - | - | - | DROPPED | used only by the OLB frame (EXECUTE_FUNCTION parameter list, print, EDI, timers) |
| 396 | PARAMETER | `P_PORT_TYPE` | - | - | - | - | DROPPED | used only by the OLB frame (EXECUTE_FUNCTION parameter list, print, EDI, timers) |
| 397 | PARAMETER | `P_CURR_PORT_CD` | - | - | - | - | DROPPED | used only by the OLB frame (EXECUTE_FUNCTION parameter list, print, EDI, timers) |
| 398 | PARAMETER | `P_MODULE_ID` | PAGE_ITEM | P1170_MODULE_ID | 1170 | - | MAPPED | FORMS_APX.GET_MODULE_ID |
| 399 | PARAMETER | `P_MODULE_NAME` | - | - | - | - | DROPPED | used only by the OLB frame (EXECUTE_FUNCTION parameter list, print, EDI, timers) |
| 400 | PARAMETER | `P_APPLICATION_NAME` | - | - | - | - | DROPPED | used only by the OLB frame (EXECUTE_FUNCTION parameter list, print, EDI, timers) |
| 401 | PARAMETER | `P_USER_ID` | - | - | - | - | DROPPED | used only by the OLB frame (EXECUTE_FUNCTION parameter list, print, EDI, timers) |
| 402 | PARAMETER | `P_WS_ID` | - | - | - | - | DROPPED | used only by the OLB frame (EXECUTE_FUNCTION parameter list, print, EDI, timers) |
| 403 | PARAMETER | `P_USER_NAME` | - | - | - | - | DROPPED | used only by the OLB frame (EXECUTE_FUNCTION parameter list, print, EDI, timers) |
| 404 | PARAMETER | `CG$STARTUP_MODE` | - | - | - | - | DROPPED | used only by the OLB frame (EXECUTE_FUNCTION parameter list, print, EDI, timers) |
| 405 | CANVAS | `LSIDE` | - | - | - | - | DROPPED | OLB frame canvas |
| 406 | CANVAS | `EDI_MSG` | - | - | - | - | DROPPED | OLB frame canvas |
| 407 | CANVAS | `TITLE` | - | - | - | - | DROPPED | OLB frame canvas |
| 408 | CANVAS | `TOOLBAR` | - | - | - | - | DROPPED | OLB frame canvas |
| 409 | CANVAS | `CG$PAGE_1` | PAGE | IMPR1170 | 1170 | - | MAPPED | regions MCI_DATA, MCI_OWNERS |
| 410 | WINDOW | `CGSO$WINDOW_1` | PAGE | IMPR1170 | 1170 | - | MAPPED | one page |
| 411 | LIBRARY | `OFGTEL` | - | - | - | - | DROPPED | frame / client library (windows, timers, help, DLLs) |
| 412 | LIBRARY | `OFGMES` | - | - | - | - | DROPPED | frame / client library (windows, timers, help, DLLs) |
| 413 | LIBRARY | `OFGHPL` | - | - | - | - | DROPPED | frame / client library (windows, timers, help, DLLs) |
| 414 | LIBRARY | `CIC_AMSG` | - | - | - | - | DROPPED | frame / client library (windows, timers, help, DLLs) |
| 415 | LIBRARY | `SEC_LIB` | - | - | - | - | DROPPED | frame / client library (windows, timers, help, DLLs) |
| 416 | LIBRARY | `CAPTION` | - | - | - | - | DROPPED | frame / client library (windows, timers, help, DLLs) |
| 417 | LIBRARY | `OFGBSL` | - | - | - | - | DROPPED | frame / client library (windows, timers, help, DLLs) |
| 418 | LIBRARY | `D2KWUTIL` | - | - | - | - | DROPPED | frame / client library (windows, timers, help, DLLs) |
| 419 | LIBRARY | `CUSTOMDLL` | - | - | - | - | DROPPED | frame / client library (windows, timers, help, DLLs) |
| 420 | LIBRARY | `D2KWUTIL_PDF` | - | - | - | - | DROPPED | frame / client library (windows, timers, help, DLLs) |
| 421 | LIBRARY | `GETCOMP` | - | - | - | - | DROPPED | frame / client library (windows, timers, help, DLLs) |
| 422 | LIBRARY | `OFGTAB` | - | - | - | - | DROPPED | frame / client library (windows, timers, help, DLLs) |
| 423 | LIBRARY | `PICKLIST` | - | - | - | - | DROPPED | frame / client library (windows, timers, help, DLLs) |
| 424 | LIBRARY | `POS` | - | - | - | - | DROPPED | frame / client library (windows, timers, help, DLLs) |
| 425 | LIBRARY | `SCDLL` | - | - | - | - | DROPPED | frame / client library (windows, timers, help, DLLs) |
| 426 | LIBRARY | `VCDLL` | - | - | - | - | DROPPED | frame / client library (windows, timers, help, DLLs) |
| 427 | LIBRARY | `CIC_LIB` | PACKAGE | FORMS_APX | - | - | MAPPED | STR -> FORMS_APX, HIJDATE -> FORMS_APX Hijri format, TMPLT -> FUNCS |
| 428 | GLOBAL | `ATHRZTN_SEQ_NBR` | - | - | - | - | DROPPED | cleared by WHEN-NEW-FORM-INSTANCE, never read by this form |
| 429 | GLOBAL | `EXEC_QUERY` | - | - | - | - | DROPPED | cleared by WHEN-NEW-FORM-INSTANCE, never read by this form |
| 430 | GLOBAL | `EXEC_QUERY_NOW` | - | - | - | - | DROPPED | cleared by WHEN-NEW-FORM-INSTANCE, never read by this form |
| 431 | GLOBAL | `PORT_CD` | - | - | - | - | DROPPED | cleared by WHEN-NEW-FORM-INSTANCE, never read by this form |
| 432 | GLOBAL | `CG$QUERY_MODE` | - | - | - | - | DROPPED | Designer block synchronisation mode |
| 433 | GLOBAL | `CG$HP_HFILE` | - | - | - | - | DROPPED | help / frame |
| 434 | GLOBAL | `CG$HP_HPATH` | - | - | - | - | DROPPED | help / frame |
| 435 | GLOBAL | `EXIT` | - | - | - | - | DROPPED | help / frame |
| 436 | GLOBAL | `SYSTEM_OBJ` | - | - | - | - | DROPPED | help / frame |
| 437 | EXTERNAL | `LIB_USR.PRTL_NEBRAS_SERVICES.CALL_WEB_SERVICE` | PACKAGE | IMPR1170.CR_NBR_KEY_NEXT_ITEM | - | IMPR1170.CR_NBR_KEY_NEXT_ITEM | MAPPED | MCI web service, called unchanged (MISSING SOURCE) |
