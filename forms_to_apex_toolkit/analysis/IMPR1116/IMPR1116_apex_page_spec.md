# IMPR1116 — APEX 21.2 page design (step 03, revision 1)

| Item | Value |
|---|---|
| Form | `IMPR1116.fmb` — "شاشة استعراض بيانات رقم المنشأة 700 المدخلة من البوابة" |
| Date | 2026-11-24 |
| Input | [inventory](IMPR1116_inventory.md), [logic extraction](IMPR1116_logic_extraction.md), [package spec](../../plsql/IMPR1116/impr1116_spec.sql) (IMPR1116 **001**), `apex/Reference/f345.sql`, `docs/f345_reference_standard.md` |
| Application | 202530 (installed from f345; already holds the IMPR1110 export: page group `IMPR`) |
| Pages | **1116** `IMPR1116` (main), **111601** `IMPR1116_SEARCH` (modal search) |
| Page group | `IMPR` (from the IMPR1110 export, reused) |
| Registry | [registry/IMPR1116_registry.sql](../../registry/IMPR1116_registry.sql) (generated with §14 by `work/IMPR1116/step03/build_trace.py`) |
| Status | design; nothing generated or imported in this step |

## 0. Design decisions

| # | Decision | Reason |
|---|---|---|
| 1 | **The 5-row master block becomes one record per page.** The search page 111601 lists every pending portal row (Forms Execute Query on `IMPR_PRTL_NAT`); its link opens the row on page 1116 (`P0_PAGE_PK` = URL-safe ROWID). Page 1116 shows it in a Form region with `REVIEW_FLAG` as the only editable item, and the importers grid below it | f345 standard: the page 0 toolbar (CREATE / SAVE / DELETE / SEARCH) works on one record key in `P0_PAGE_PK`; a Form region + detail IG is the AGR1100 / IMPR1120 pattern. The importers grid in Forms also belongs to one portal row at a time. **To confirm with the user** (logic extraction §8 #1). Alternative: an editable IG of all pending rows with `IMPORTERS` as its detail IG; SAVE would then need `P0_PAGE_PK` set artificially |
| 2 | Search page **shows the pending rows at once** (no "search first" as in IMPR1120) and has one optional search text over every column | The list *is* the work queue (`REVIEW_FLAG = 0`); the Forms user runs Execute Query without criteria |
| 3 | A reviewed row stays open after SAVE | `P0_PAGE_PK_CHECK` accepts any `IMPR_PRTL_NAT` row; the search list no longer shows it (Forms: visible until the next query) |
| 4 | CREATE / DELETE of the page 0 toolbar are refused with a message (`PRE_INSERT` / `PRE_DELETE`) | block Insert / Delete Allowed = false; the toolbar buttons cannot be hidden per page without changing page 0 |
| 5 | `IMPORTERS` = read-only IG whose region SQL holds the Forms WHERE on the master page items, including `NVL(BUS_ID_BRNCH, 0)` | the native Master Region join compares with `=` only; the master is a Form region, not an IG |
| 6 | No dynamic action, no validation, no JavaScript | the form has no item trigger with business code |

## 1. Page type decision per block

| Forms block | Characteristics | APEX 21.2 | f345 template / classes |
|---|---|---|---|
| TITLE (OLB) | title bar | hero region `IMPR_PRTL_NAT_HERO` (HEADER TITLE) | Blank with Attributes `11621859120066869682`, `cg-hero` |
| TOOLBAR / LSIDE / EDI_MSG (OLB) | frame | page 0 toolbar `P0_ACTIONS`, page 0 `FUNCS`; EDI ticker dropped | – |
| IMPR_PRTL_NAT | multi-record (5), base table, update of one column, Enter / Execute Query | search page 111601 (list) + Form region on 1116 (one record, update only) — decision #1 | Interactive Report `11621909206693869707`, `zatca-forms cg-form cg-card` |
| IMPORTERS | multi-record (10), query only, coordinated by WHERE on the master | read-only Interactive Grid | Standard `11621913486616869708`, `#DEFAULT#:t-Region--noPadding`, `cg-card cg-grid` |

## 2. Pages

| Page No | Name / alias | Mode | Page template | Source | Forms menu role | Navigation menu entry |
|---|---|---|---|---|---|---|
| 1116 | `IMPR1116` / `IMPR1116` | Normal, CSS `zf`, protection C, title `&SYS_ANAME.` | Zatca-Minimal_No_Navigation `11622270914969205733` | window `CGSO$WINDOW_1`, canvas `CG$PAGE_1` | launcher `APPS` / `SC_SYSTEM_OBJECTS` (no menu role in the form) | none generated: the application opens screens from `SC_SYSTEM_OBJECTS` (inventory §15 #6) |
| 111601 | `IMPR1116_SEARCH` / `IMPR1116-SEARCH` | Modal Dialog 1800 × 800, CSS `zf`, protection C | theme default (as f345 search pages) | Enter / Execute Query of `IMPR_PRTL_NAT` | – | – (opened by page 0 `SEARCH`) |

No other modal page, so no `G_LAST_PAGE KEEP` process is needed.

## 3. Regions

### 3.1 Page 1116

| Region | Static ID | Type | Source | PK | Template / options / classes | Seq | Edit | Source Forms block |
|---|---|---|---|---|---|---|---|---|
| الهيدر | `IMPR_PRTL_NAT_HERO` | Static Content (HTML) | hero markup with `&P1116_HERO_TITLE.` | – | Blank with Attributes, `cg-hero` | 10 | – | TITLE (OLB) |
| بيانات رقم المنشأة 700 للمستورد | `IMPR_PRTL_NAT` | Form | table `IMPR_PRTL_NAT`, include ROWID | ROWID (`P1116_ROW_ID`) | Interactive Report, `zatca-forms cg-form cg-card` | 20 | Update only (`p_edit_operations => 'u'`), lost update check VALUES | IMPR_PRTL_NAT |
| المستوردين | `IMPORTERS` | Interactive Grid (read only) | SQL §3.3 | `ROW_ID` (hidden) | Standard, `#DEFAULT#:t-Region--noPadding`, `cg-card cg-grid`; 10 rows per page (Forms Records Displayed) | 30 | none | IMPORTERS |

`IMPORTERS` is displayed only when `P0_PAGE_PK` is not null; Page Items to Submit `P1116_IMPR_TYPE_CD,P1116_CTRY_CD,P1116_BUS_ID_TYPE_CD,P1116_BUS_ID,P1116_BUS_ID_BRNCH`.

### 3.2 Page 111601

| Region | Static ID | Type | Source | PK | Template / classes | Seq |
|---|---|---|---|---|---|---|
| بحث | `IMPR_PRTL_NAT_SEARCH_CRITERIA` | Static Content | item `P111601_SEARCH` + buttons SEARCH / CLEAR | – | Blank with Attributes, `zatca-forms cg-form` | 10 |
| بيانات البوابة غير المراجعة | `IMPR_PRTL_NAT_SEARCH` | Interactive Grid (read only) | SQL §3.4 | `ROW_ID` | Standard, `t-Region--noPadding`, `cg-card cg-grid` | 20 |

### 3.3 SQL of IG `IMPORTERS` (page 1116)

```sql
-- Forms block IMPORTERS: WHERE on the current IMPR_PRTL_NAT record + POST-QUERY lookup CGFK$QRY_IMPORTERS_IMP_ITIDT_F
SELECT ROWIDTOCHAR(i.ROWID) AS row_id,
       i.port_cd,
       i.impr_nbr,
       i.hq_impr_nbr,
       i.impr_type_cd,
       i.bus_id_type_cd,
       i.bus_id,
       i.bus_id_brnch,
       l_it1.impr_type_name   AS l_it1_impr_type_name,
       i.arbc_impr_name,
       l_bit.bus_id_type_name AS l_bit_bus_id_type_name
  FROM importers i,
       impr_type_id_types l_itidt,
       impr_types l_it1,
       bus_id_types l_bit
 WHERE i.impr_type_cd   = :P1116_IMPR_TYPE_CD
   AND i.ctry_cd        = :P1116_CTRY_CD
   AND i.bus_id_type_cd = :P1116_BUS_ID_TYPE_CD
   AND i.bus_id         = :P1116_BUS_ID
   AND NVL(i.bus_id_brnch, 0) = NVL(:P1116_BUS_ID_BRNCH, 0)
   AND l_itidt.impr_type_cd (+)   = i.impr_type_cd
   AND l_itidt.bus_id_type_cd (+) = i.bus_id_type_cd
   AND l_it1.impr_type_cd (+)     = l_itidt.impr_type_cd
   AND l_bit.bus_id_type_cd (+)   = l_itidt.bus_id_type_cd
```

The Forms block has no ORDER BY; none is added.

### 3.4 SQL of IG `IMPR_PRTL_NAT_SEARCH` (page 111601)

```sql
-- Forms block IMPR_PRTL_NAT query: WHERE REVIEW_FLAG = 0 AND GAZT_NAME IS NOT NULL (IMPR1116.IMPR_PRTL_NAT_IS_PENDING);
-- optional search text over every shown column. URL-safe ROWID: a '+' in f?p arrives as a space.
SELECT TRANSLATE(ROWIDTOCHAR(n.ROWID), '+/', '-_') AS row_id,
       n.prtl_nat_isn,
       n.id_type_gzt,
       (SELECT r.rv_meaning FROM cg_ref_codes r
         WHERE r.rv_domain = 'ID_TYPE_GZT' AND r.rv_low_value = n.id_type_gzt AND ROWNUM = 1) AS id_type_gzt_name,
       n.bus_id_new,
       n.gazt_name
  FROM impr_prtl_nat n
 WHERE (SELECT IMPR1116.IMPR_PRTL_NAT_IS_PENDING(REVIEW_FLAG => n.review_flag, GAZT_NAME => n.gazt_name) FROM dual) = 'Y'
   AND (:P111601_SEARCH IS NULL
        OR INSTR(UPPER(n.prtl_nat_isn || '|' || n.id_type_gzt || '|' || n.bus_id_new || '|' || n.gazt_name),
                 UPPER(TRIM(:P111601_SEARCH))) > 0)
```

## 4. Items

### 4.1 Page 1116, region `IMPR_PRTL_NAT` (Forms navigation order)

| Page item | Source column | Type | Label | Req | LOV | Read Only | Source Forms item |
|---|---|---|---|---|---|---|---|
| `P1116_ROW_ID` | ROWID (PK) | Hidden, value protected | – | – | – | – | key mode ROWID (= `P0_PAGE_PK`) |
| `P1116_PRTL_NAT_ISN` | PRTL_NAT_ISN (NUMBER) | Display Only, **sent on submit** (input of `PRE-UPDATE`) | مسلسل | – | – | always | IMPR_PRTL_NAT.PRTL_NAT_ISN |
| `P1116_IMPR_TYPE_CD` | IMPR_TYPE_CD (NUMBER) | Hidden, value protected | – | – | – | – | IMPR_PRTL_NAT.IMPR_TYPE_CD (Visible = No) |
| `P1116_CTRY_CD` | CTRY_CD (NUMBER) | Hidden, value protected | – | – | – | – | IMPR_PRTL_NAT.CTRY_CD |
| `P1116_BUS_ID_TYPE_CD` | BUS_ID_TYPE_CD (NUMBER) | Hidden, value protected | – | – | – | – | IMPR_PRTL_NAT.BUS_ID_TYPE_CD |
| `P1116_BUS_ID` | BUS_ID (VARCHAR2) | Hidden, value protected | – | – | – | – | IMPR_PRTL_NAT.BUS_ID |
| `P1116_BUS_ID_BRNCH` | BUS_ID_BRNCH (VARCHAR2) | Hidden, value protected | – | – | – | – | IMPR_PRTL_NAT.BUS_ID_BRNCH |
| `P1116_ID_TYPE_GZT` | ID_TYPE_GZT (VARCHAR2) | Display Only based on LOV | نوع السجل | – | `LOV_ID_TYPE_GZT` | always | IMPR_PRTL_NAT.ID_TYPE_GZT (list item) |
| `P1116_BUS_ID_NEW` | BUS_ID_NEW (VARCHAR2) | Display Only | رقم السجل | – | – | always | IMPR_PRTL_NAT.BUS_ID_NEW |
| `P1116_GAZT_NAME` | GAZT_NAME (VARCHAR2) | Display Only | الاسم | – | – | always | IMPR_PRTL_NAT.GAZT_NAME |
| `P1116_REVIEW_FLAG` | REVIEW_FLAG (NUMBER) | **Select List** | حالة المراجعة | – (Forms: not required) | `LOV_PRTL_NAT_FLAG`, null shown as `-` | when `P0_PAGE_PK` is null | IMPR_PRTL_NAT.REVIEW_FLAG (list item, default 0 = stored value) |

Not on the page (Forms `Visible = No`, not updatable, read by no trigger): `TIN_NBR`, `DOC_DT`, `ENTRY_DT`, `USER_ID`, `LST_TRAN_DT`, `UPDATE_DT`. `Process form` does not touch them. The hidden and Display Only key items are written back unchanged, with the values Initialize form fetched. Label templates: Optional - Above with `t-Form-fieldContainer--stretchInputs`.

### 4.2 Page 1116, hero region

| Item | Type | Purpose |
|---|---|---|
| `P1116_HERO_TITLE` | Hidden, value protected | set by `HEADER TITLE` |
| `P1116_MODULE_ID` | Hidden, value protected, protection S | `FORMS_APX.GET_MODULE_ID` (kept by SCREEN ENTRY RESET) |

### 4.3 Page 1116, IG `IMPORTERS` columns

| Column | Type | Heading | Visible | Source Forms item |
|---|---|---|---|---|
| `ROW_ID` | Hidden, PK | – | no | – |
| `PORT_CD` | Display Only | الجمرك | yes | IMPORTERS.PORT_CD |
| `IMPR_NBR` | Display Only | الرقم | yes | IMPORTERS.IMPR_NBR |
| `HQ_IMPR_NBR` | Hidden | – | no | IMPORTERS.HQ_IMPR_NBR (Visible = No) |
| `IMPR_TYPE_CD` | Hidden | – | no | IMPORTERS.IMPR_TYPE_CD |
| `BUS_ID_TYPE_CD` | Hidden | – | no | IMPORTERS.BUS_ID_TYPE_CD |
| `BUS_ID` | Hidden | – | no | IMPORTERS.BUS_ID |
| `BUS_ID_BRNCH` | Hidden | – | no | IMPORTERS.BUS_ID_BRNCH |
| `L_IT1_IMPR_TYPE_NAME` | Display Only | نوع المستورد | yes | IMPORTERS.L_IT1_IMPR_TYPE_NAME (POST-QUERY) |
| `ARBC_IMPR_NAME` | Display Only | اسم المستورد | yes | IMPORTERS.ARBC_IMPR_NAME |
| `L_BIT_BUS_ID_TYPE_NAME` | Display Only | مسمى الاستدلالى | yes | IMPORTERS.L_BIT_BUS_ID_TYPE_NAME (POST-QUERY) |

### 4.4 Page 111601

| Item / column | Type | Label / heading | Source |
|---|---|---|---|
| `P111601_SEARCH` | Text Field, max 200 (icon from `item_icons`) | بحث في كل الأعمدة | Enter Query criteria on PRTL_NAT_ISN, ID_TYPE_GZT, BUS_ID_NEW, GAZT_NAME |
| `ROW_ID` | Hidden, PK | – | – |
| `PRTL_NAT_ISN` | **Link** → `f?p=&APP_ID.:1116:&SESSION.::&DEBUG.:1116:P0_PAGE_PK:&ROW_ID.` | مسلسل | IMPR_PRTL_NAT.PRTL_NAT_ISN |
| `ID_TYPE_GZT` | Display Only | رمز نوع السجل | IMPR_PRTL_NAT.ID_TYPE_GZT |
| `ID_TYPE_GZT_NAME` | Display Only | نوع السجل | CG_REF_CODES meaning (list item label) |
| `BUS_ID_NEW` | Display Only | رقم السجل | IMPR_PRTL_NAT.BUS_ID_NEW |
| `GAZT_NAME` | Display Only | الاسم | IMPR_PRTL_NAT.GAZT_NAME |

`REVIEW_FLAG` is not shown on the search page, because every listed row is 0.

## 5. Buttons

Page 1116: none. The page 0 toolbar supplies everything:

| Forms | Page 0 |
|---|---|
| TOOLBAR.SAVE, KEY-COMMIT | `SAVE` (shown when `P0_PAGE_PK` is not null) |
| TOOLBAR.ENTER / EXECUTE / RE_ENTER_QUERY, KEY-ENTQRY / KEY-EXEQRY | `SEARCH` → 111601 |
| TOOLBAR.REMOVE, KEY-DELREC | `DELETE` → refused by `PRE-DELETE` |
| TOOLBAR.CLEAR_ALL, KEY-CLRBLK / KEY-CLRFRM | `CLEAR` |
| TOOLBAR.EXIT / EXIT1, KEY-EXIT | `BACK` |
| TOOLBAR.FUN_BUT, KEY-F9, LSIDE | `FUNCS` (page 0 drawer, Page Functions) |
| (none in Forms) | `CREATE` (shown when `P0_PAGE_PK` is null) → refused by `PRE-INSERT` |

Page 111601: `SEARCH` (fa-search, `cg-b-search`) and `CLEAR` (fa-eraser, `cg-b-clear`) in the criteria region, template Text with Icon, `#DEFAULT#:t-Button--iconLeft`, both Defined by DA. These are the same as IMPR1120's page 112001.

## 6. LOVs

| Forms | APEX LOV | Type | Source | Used by | Item type |
|---|---|---|---|---|---|
| runtime RG `CGDV$DLRG` → list `IMPR_PRTL_NAT.ID_TYPE_GZT` | **`LOV_ID_TYPE_GZT`** (new) | PL/SQL Function Body returning SQL | `return LOV_APX.REFERENCE_CODES(P_DOMAIN => 'ID_TYPE_GZT');` (D = RV_MEANING, R = RV_LOW_VALUE) | `P1116_ID_TYPE_GZT` | Display Only based on LOV |
| runtime RG `CGDV$DLRG` → list `IMPR_PRTL_NAT.REVIEW_FLAG` | **`LOV_PRTL_NAT_FLAG`** (new) | PL/SQL Function Body returning SQL | `return LOV_APX.REFERENCE_CODES(P_DOMAIN => 'PRTL_NAT_FLAG');` | `P1116_REVIEW_FLAG` | Select List |
| `CGFK$IMPORTERS_PORT_CD` (SD_PORTS) | – | – | **dropped**: item query only, button hidden | – | – |
| `CGFK$IMPORTERS_L_BIT_BUS_ID_TY` | – | – | **dropped**: query only; names from the region SQL | – | – |

Column definitions D (visible) and R (hidden), from `lov_apx.column_definitions()`. `LOV_APX` is unchanged (it already has `REFERENCE_CODES`).

## 7. Validations

None. The form has no WHEN-VALIDATE-ITEM / WHEN-VALIDATE-RECORD with code, and no required item. `REVIEW_FLAG` accepts only the LOV values (Select List).

## 8. Processes

### 8.1 Page 1116

| Seq | Point | Name | Type | Code | Condition | Source |
|---|---|---|---|---|---|---|
| 10 | Before Header | `New` | PL/SQL | `NULL;` (f345 session setup) | Never (as AGR1100 / IMPR1120) | f345 |
| 20 | Before Header | `P0_PAGE_PK CHECK` | PL/SQL | `IMPR1116.P0_PAGE_PK_CHECK(P_PAGE_PK => :P0_PAGE_PK);` | – | f345 |
| 40 | Before Header | `PARAMETERS` | PL/SQL | `:P1116_MODULE_ID := FORMS_APX.GET_MODULE_ID(P_MODULE_ID => :P1116_MODULE_ID, FORM_NAME => 'IMPR1116');` | – | f345 |
| 70 | Before Header | `P0_PAGE_PK` | PL/SQL | `:P1116_ROW_ID := :P0_PAGE_PK;` | – | f345 |
| 80 | Before Header | `Initialize form` | Form - Initialization (region `IMPR_PRTL_NAT`) | – | – | block fetch |
| 100 | Before Header | `HEADER TITLE` | PL/SQL | `FORMS_APX.HEADER_TITLE(P_MODULE_ID => :P1116_MODULE_ID, P_HERO_TITLE => :P1116_HERO_TITLE, DEFAULT_TITLE => 'استعراض بيانات رقم المنشأة 700 المدخلة من البوابة');` | – | TITLE (OLB) |
| 10 | After Submit | `PRE-INSERT` | PL/SQL | `IMPR1116.PRE_INSERT;` | `:P0_PAGE_PK IS NULL AND :REQUEST = 'CREATE'` | IMPR_PRTL_NAT.PRE-INSERT + Insert Allowed = false |
| 20 | After Submit | `PRE-UPDATE` | PL/SQL | `IMPR1116.PRE_UPDATE(P_PRTL_NAT_ISN => :P1116_PRTL_NAT_ISN, P_CURR_PORT_CD => :P_CURR_PORT_CD, SSO_APP_USER => :SSO_APP_USER, P_GLOBAL_V_WS_ID => :P_GLOBAL_V_WS_ID);` | `:P0_PAGE_PK IS NOT NULL AND :REQUEST = 'SAVE'` | IMPR_PRTL_NAT.PRE-UPDATE |
| 30 | After Submit | `PRE-DELETE` | PL/SQL | `IMPR1116.PRE_DELETE;` | request = DELETE | IMPR_PRTL_NAT.PRE-DELETE + Delete Allowed = false |
| 40 | After Submit | `Process form` | Form - Automatic Row Processing (DML), region `IMPR_PRTL_NAT`, REGION_SOURCE, lost update check, success message "تم الحفظ بنجاح" | – | request = SAVE | Forms default UPDATE |

No PARAMETERS ENTRY (the form has no own parameter), no WHEN-NEW-FORM-INSTANCE process (no business code), no PRE-FORM, no POST-* processes and no `P0_PAGE_PK AFTER INSERT / DELETE`, because insert and delete never succeed.

### 8.2 Page 111601

None.

## 9. Computations

None.

## 10. Dynamic Actions

| Page | DA | Event | Selection | Actions | Source |
|---|---|---|---|---|---|
| 111601 | `SEARCH WHEN-BUTTON-PRESSED` | Click | button SEARCH | Refresh region `IMPR_PRTL_NAT_SEARCH` | TOOLBAR.EXECUTE / KEY-EXEQRY |
| 111601 | `SEARCH KEY-ENTER` | Key Up, client condition `this.browserEvent.which === 13` | `P111601_SEARCH` | Refresh region | KEY-EXEQRY |
| 111601 | `CLEAR WHEN-BUTTON-PRESSED` | Click | button CLEAR | Clear `P111601_SEARCH`, Refresh region | TOOLBAR.CLEAR_ALL |
| 111601 | `Hide` | Page Load | – | Hide region `P0_ACTIONS` (page 0 toolbar in the dialog) | f345 AGR1100_SEARCH |

Page 1116 has none: the form has no UI trigger with business effect (logic extraction §6). **JavaScript actions: 0** (only the one-expression Enter condition, as IMPR1120).

## 11. Alerts and messages

| Forms alert | Usage | APEX | Text |
|---|---|---|---|
| CFG_SYSTEM_ERROR | `ACTIVITY.ADD_ACTIVITY` failure | `FORMS_APX.FORM_TRIGGER_FAILURE` in `IMPR1116.PRE_UPDATE` (inline notification) | text returned by `ACTIVITY_DB` |
| CFG_ERROR / CFG_INFORMATION | `NIB.ON_ERROR` / `ON_MESSAGE` | f345 `APP_ERROR_HANDLER` / process messages | – |
| CFG_ASK_COMMIT | Designer commit dialogue | page attribute *Warn on Unsaved Changes* = Yes | – |
| USR_CONFIRM_B, USR_CONFIRM, USR_WARNING_C, USR_WARNING_B, CFG_WARNING_A | not used by this form's code | dropped | – |
| (new) insert / delete refused | page 0 CREATE / DELETE | `PRE_INSERT` / `PRE_DELETE` | لا يمكن إضافة بيانات من هذه الشاشة / لا يمكن حذف بيانات من هذه الشاشة (to agree) |

No Text Message is created.

## 12. Branches and navigation

| Branch | Point | Target | Condition | Source |
|---|---|---|---|---|
| `IMPR1116 - stay in the form` | After Processing, seq 10 | `f?p=&APP_ID.:1116:&SESSION.::&DEBUG.:::&success_msg=#SUCCESS_MSG#` | always | Forms stays in the form after COMMIT |

Page 111601 → 1116 by the link column (`P0_PAGE_PK`). The f345 `SCREEN ENTRY RESET` keeps `P0_PAGE_PK` between 1116 and 111601.

## 13. Shared components

| Component | Action |
|---|---|
| LOV `LOV_ID_TYPE_GZT`, `LOV_PRTL_NAT_FLAG` | **new** (ids in the 9116 range) |
| Page group `IMPR` | reused (IMPR1110 export) |
| Application items `P_CURR_PORT_CD`, `SSO_APP_USER`, `P_GLOBAL_V_WS_ID`, page 0 items `P0_PAGE_PK`, region `P0_ACTIONS`, region `FUNCS`, list *Page Functions*, plug-in FOS (not used here) | reused (f345) |
| Application items / Text Messages / static files / Authorization Schemes | none |

Database prerequisites:
- `LIB_APX_USR.IMPR1116` 001, `FORMS_APX` 004 and `LOV_APX` (001 or later) must be compiled.
- `LIB_APX_USR` needs SELECT on `IMPR_PRTL_NAT` and EXECUTE on `ACTIVITY_DB`.
- `CUSTOMS` needs SELECT / UPDATE on `IMPR_PRTL_NAT` and SELECT on `IMPORTERS`, `IMPR_TYPE_ID_TYPES`, `IMPR_TYPES`, `BUS_ID_TYPES` and `CG_REF_CODES` (logic extraction §8 #5).

## 14. Traceability matrix

Generated by `work/IMPR1116/step03/build_trace.py` from `forms/IMPR/IMPR1116_fmb.xml`. Every Forms object of the XML has exactly one row.

427 objects: DROPPED 346, MAPPED 80, TODO 1. By type: ALERT 9, BLOCK 6, CALLED_FORM 1, CANVAS 5, GLOBAL 4, ITEM 108, LIBRARY 17, LOV 2, PARAMETER 21, PROGRAM_UNIT 20, RECORD_GROUP 3, TRIGGER 230, WINDOW 1.

| # | Type | Forms object | APEX component | Page | Package member | Status | Notes |
|---|---|---|---|---|---|---|---|
| 1 | BLOCK | `TITLE` | IMPR_PRTL_NAT_HERO | 1116 | – | MAPPED | OLB title bar -> hero region (FORMS_APX.HEADER_TITLE) |
| 2 | BLOCK | `EDI_MSG` | – | – | – | DROPPED | OLB EDI message ticker - dropped (timers, IMPR1110 decision 2026-11-19) |
| 3 | BLOCK | `LSIDE` | FUNCS (page 0 drawer) | 0 | – | MAPPED | OLB side function menu -> page 0 FUNCS, f345 list Page Functions |
| 4 | BLOCK | `TOOLBAR` | P0_ACTIONS (page 0 toolbar, f345) | 0 | – | MAPPED | OLB toolbar -> f345 page 0 toolbar |
| 5 | BLOCK | `IMPR_PRTL_NAT` | IMPR_PRTL_NAT (Form region, table IMPR_PRTL_NAT, ROWID, update only) + IMPR_PRTL_NAT_SEARCH (page 111601) | 1116 | – | MAPPED | master, 5 rows -> list on 111601 + one record on 1116 (spec decision 1); WHERE -> IMPR_PRTL_NAT_IS_PENDING |
| 6 | BLOCK | `IMPORTERS` | IMPORTERS (read-only Interactive Grid, SQL with the Forms WHERE on the master items) | 1116 | – | MAPPED | detail without relation; POST-QUERY lookup -> outer joins |
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
| 72 | ITEM | `TOOLBAR.SAVE` | SAVE (page 0 toolbar) | 0 | – | MAPPED | request SAVE -> PRE-UPDATE + Process form |
| 73 | ITEM | `TOOLBAR.CLEAR_ALL` | CLEAR (page 0 toolbar) | 0 | – | MAPPED | – |
| 74 | ITEM | `TOOLBAR.EXIT` | BACK (page 0 toolbar) | 0 | – | MAPPED | – |
| 75 | ITEM | `TOOLBAR.EXIT1` | BACK (page 0 toolbar) | 0 | – | MAPPED | leave Enter-Query mode -> no query mode in APEX |
| 76 | ITEM | `TOOLBAR.ENTER` | SEARCH (page 0 toolbar) | 0 | – | MAPPED | Enter Query -> search page 111601 |
| 77 | ITEM | `TOOLBAR.EXECUTE` | SEARCH (page 0 toolbar) | 0 | – | MAPPED | Execute Query -> search page 111601 |
| 78 | ITEM | `TOOLBAR.REMOVE` | DELETE (page 0 toolbar) | 0 | – | MAPPED | refused by PRE-DELETE (Delete Allowed = No) |
| 79 | ITEM | `TOOLBAR.LIST_VALUE` | – | – | – | DROPPED | no LOV is reachable on page 1116 (REVIEW_FLAG is a select list) |
| 80 | ITEM | `TOOLBAR.HELP` | – | – | – | DROPPED | MS-Help obsolete |
| 81 | ITEM | `TOOLBAR.LAST_REC` | – | – | – | DROPPED | OLB toolbar item (record navigation / frame) |
| 82 | ITEM | `TOOLBAR.RE_ENTER_QUERY` | SEARCH (page 0 toolbar) | 0 | – | MAPPED | – |
| 83 | ITEM | `TOOLBAR.FIRST_REC` | – | – | – | DROPPED | OLB toolbar item (record navigation / frame) |
| 84 | ITEM | `TOOLBAR.PAGE_UP` | – | – | – | DROPPED | OLB toolbar item (record navigation / frame) |
| 85 | ITEM | `TOOLBAR.PAGE_DOWN` | – | – | – | DROPPED | OLB toolbar item (record navigation / frame) |
| 86 | ITEM | `TOOLBAR.FUN_BUT` | FUNCS (page 0 toolbar) | 0 | – | MAPPED | – |
| 87 | ITEM | `IMPR_PRTL_NAT.PRTL_NAT_ISN` | P1116_PRTL_NAT_ISN | 1116 | – | MAPPED | Display Only, sent on submit (input of PRE-UPDATE); link column on 111601 |
| 88 | ITEM | `IMPR_PRTL_NAT.IMPR_TYPE_CD` | P1116_IMPR_TYPE_CD | 1116 | – | MAPPED | Hidden (value protected) - bind of the IMPORTERS grid |
| 89 | ITEM | `IMPR_PRTL_NAT.CTRY_CD` | P1116_CTRY_CD | 1116 | – | MAPPED | Hidden (value protected) - bind of the IMPORTERS grid |
| 90 | ITEM | `IMPR_PRTL_NAT.BUS_ID_TYPE_CD` | P1116_BUS_ID_TYPE_CD | 1116 | – | MAPPED | Hidden (value protected) - bind of the IMPORTERS grid |
| 91 | ITEM | `IMPR_PRTL_NAT.BUS_ID` | P1116_BUS_ID | 1116 | – | MAPPED | Hidden (value protected) - bind of the IMPORTERS grid |
| 92 | ITEM | `IMPR_PRTL_NAT.BUS_ID_BRNCH` | P1116_BUS_ID_BRNCH | 1116 | – | MAPPED | Hidden (value protected) - bind of the IMPORTERS grid (NVL ..., 0) |
| 93 | ITEM | `IMPR_PRTL_NAT.TIN_NBR` | – | – | – | DROPPED | Visible = No, not updatable, read by no trigger |
| 94 | ITEM | `IMPR_PRTL_NAT.ID_TYPE_GZT` | P1116_ID_TYPE_GZT | 1116 | – | MAPPED | Display Only based on LOV_ID_TYPE_GZT; columns ID_TYPE_GZT / ID_TYPE_GZT_NAME on 111601 |
| 95 | ITEM | `IMPR_PRTL_NAT.BUS_ID_NEW` | P1116_BUS_ID_NEW | 1116 | – | MAPPED | Display Only; column on 111601 |
| 96 | ITEM | `IMPR_PRTL_NAT.DOC_DT` | – | – | – | DROPPED | Visible = No, not updatable, read by no trigger |
| 97 | ITEM | `IMPR_PRTL_NAT.ENTRY_DT` | – | – | – | DROPPED | Visible = No, not updatable, read by no trigger |
| 98 | ITEM | `IMPR_PRTL_NAT.USER_ID` | – | – | – | DROPPED | Visible = No, not updatable (inventory 15 #2) |
| 99 | ITEM | `IMPR_PRTL_NAT.LST_TRAN_DT` | – | – | – | DROPPED | Visible = No, not updatable (inventory 15 #2) |
| 100 | ITEM | `IMPR_PRTL_NAT.GAZT_NAME` | P1116_GAZT_NAME | 1116 | – | MAPPED | Display Only; column on 111601 (search WHERE GAZT_NAME IS NOT NULL) |
| 101 | ITEM | `IMPR_PRTL_NAT.REVIEW_FLAG` | P1116_REVIEW_FLAG | 1116 | – | MAPPED | Select List LOV_PRTL_NAT_FLAG, the only editable item; read only while P0_PAGE_PK is null |
| 102 | ITEM | `IMPR_PRTL_NAT.UPDATE_DT` | – | – | – | DROPPED | Visible = No, not updatable (inventory 15 #2) |
| 103 | ITEM | `IMPORTERS.PORT_CD` | IMPORTERS.PORT_CD | 1116 | – | MAPPED | Display Only column |
| 104 | ITEM | `IMPORTERS.PORT_CD2` | – | – | – | DROPPED | LOV button, hidden by WHEN-NEW-FORM-INSTANCE |
| 105 | ITEM | `IMPORTERS.IMPR_NBR` | IMPORTERS.IMPR_NBR | 1116 | – | MAPPED | Display Only column |
| 106 | ITEM | `IMPORTERS.HQ_IMPR_NBR` | IMPORTERS.HQ_IMPR_NBR | 1116 | – | MAPPED | Hidden column |
| 107 | ITEM | `IMPORTERS.IMPR_TYPE_CD` | IMPORTERS.IMPR_TYPE_CD | 1116 | – | MAPPED | Hidden column |
| 108 | ITEM | `IMPORTERS.BUS_ID_TYPE_CD` | IMPORTERS.BUS_ID_TYPE_CD | 1116 | – | MAPPED | Hidden column |
| 109 | ITEM | `IMPORTERS.BUS_ID` | IMPORTERS.BUS_ID | 1116 | – | MAPPED | Hidden column |
| 110 | ITEM | `IMPORTERS.BUS_ID_BRNCH` | IMPORTERS.BUS_ID_BRNCH | 1116 | – | MAPPED | Hidden column |
| 111 | ITEM | `IMPORTERS.L_IT1_IMPR_TYPE_NAME` | IMPORTERS.L_IT1_IMPR_TYPE_NAME | 1116 | – | MAPPED | Display Only column (outer join IMPR_TYPES, POST-QUERY) |
| 112 | ITEM | `IMPORTERS.ARBC_IMPR_NAME` | IMPORTERS.ARBC_IMPR_NAME | 1116 | – | MAPPED | Display Only column |
| 113 | ITEM | `IMPORTERS.L_BIT_BUS_ID_TYPE_NAME` | IMPORTERS.L_BIT_BUS_ID_TYPE_NAME | 1116 | – | MAPPED | Display Only column (outer join BUS_ID_TYPES, POST-QUERY) |
| 114 | ITEM | `IMPORTERS.L_BIT_BUS_ID_TYPE_NAME2` | – | – | – | DROPPED | LOV button, hidden by WHEN-NEW-FORM-INSTANCE |
| 115 | TRIGGER | `FORM.KEY-EDIT` | – | – | – | DROPPED | NIB.KEY_EDIT -> page 0 toolbar / browser keyboard |
| 116 | TRIGGER | `FORM.KEY-DUPREC` | – | – | – | DROPPED | NIB.KEY_DUPREC -> page 0 toolbar / browser keyboard |
| 117 | TRIGGER | `FORM.PRE-FORM` | – | – | – | DROPPED | NIB.PRE_FORM, NLS date setting, help path -> f345 application |
| 118 | TRIGGER | `FORM.WHEN-NEW-FORM-INSTANCE` | – | – | – | DROPPED | NIB startup -> f345 shell; CG$WHEN_NEW_FORM_INSTANCE -> shared LOVs; hide LOV buttons / widths -> not created / IG widths |
| 119 | TRIGGER | `FORM.WHEN-WINDOW-ACTIVATED` | – | – | – | DROPPED | timers / window / frame (OLB, NIB) |
| 120 | TRIGGER | `FORM.KEY-ENTQRY` | SEARCH (page 0 toolbar) | 0 | – | MAPPED | NIB.KEY_ENTQRY -> search page 111601 |
| 121 | TRIGGER | `FORM.ON-ERROR` | APP_ERROR_HANDLER (f345) | – | – | MAPPED | NIB.ON_ERROR |
| 122 | TRIGGER | `FORM.ON-MESSAGE` | APP_ERROR_HANDLER (f345) / page messages | – | – | MAPPED | NIB.ON_MESSAGE |
| 123 | TRIGGER | `FORM.KEY-CLRBLK` | CLEAR (page 0 toolbar) | 0 | – | MAPPED | NIB.KEY_CLRBLK |
| 124 | TRIGGER | `FORM.KEY-DELREC` | DELETE (page 0 toolbar) | 0 | IMPR1116.PRE_DELETE | MAPPED | NIB.KEY_DELREC -> refused (Delete Allowed = No) |
| 125 | TRIGGER | `FORM.KEY-F5` | – | – | – | DROPPED | NIB.KEY_F5 -> page 0 toolbar / browser keyboard |
| 126 | TRIGGER | `FORM.KEY-F4` | – | – | – | DROPPED | timers / window / frame (OLB, NIB) |
| 127 | TRIGGER | `FORM.KEY-NXTREC` | – | – | – | DROPPED | NIB.KEY_NXTREC -> page 0 toolbar / browser keyboard |
| 128 | TRIGGER | `FORM.KEY-PRVREC` | – | – | – | DROPPED | NIB.KEY_PRVREC -> page 0 toolbar / browser keyboard |
| 129 | TRIGGER | `FORM.KEY-DOWN` | – | – | – | DROPPED | NIB.KEY_DOWN -> page 0 toolbar / browser keyboard |
| 130 | TRIGGER | `FORM.KEY-UP` | – | – | – | DROPPED | NIB.KEY_UP -> page 0 toolbar / browser keyboard |
| 131 | TRIGGER | `FORM.KEY-SCRUP` | – | – | – | DROPPED | NIB.KEY_SCRUP -> page 0 toolbar / browser keyboard |
| 132 | TRIGGER | `FORM.KEY-SCRDOWN` | – | – | – | DROPPED | NIB.KEY_SCRDOWN -> page 0 toolbar / browser keyboard |
| 133 | TRIGGER | `FORM.KEY-PRINT` | – | – | – | DROPPED | NIB.KEY_PRINT -> page 0 toolbar / browser keyboard |
| 134 | TRIGGER | `FORM.KEY-EXIT` | BACK (page 0 toolbar) | 0 | – | MAPPED | NIB.KEY_EXIT |
| 135 | TRIGGER | `FORM.WHEN-MOUSE-DOWN` | – | – | – | DROPPED | timers / window / frame (OLB, NIB) |
| 136 | TRIGGER | `FORM.KEY-EXEQRY` | SEARCH (page 0 toolbar) | 0 | – | MAPPED | NIB.KEY_EXEQRY -> search page 111601 |
| 137 | TRIGGER | `FORM.KEY-F9` | FUNCS (page 0 toolbar) | 0 | – | MAPPED | side-menu toggle -> FUNCS |
| 138 | TRIGGER | `FORM.WHEN-TIMER-EXPIRED` | – | – | – | DROPPED | timers / window / frame (OLB, NIB) |
| 139 | TRIGGER | `FORM.KEY-HELP` | – | – | – | DROPPED | MS-Help obsolete |
| 140 | TRIGGER | `FORM.KEY-CLRFRM` | CLEAR (page 0 toolbar) | 0 | – | MAPPED | Designer clear-form dialogue -> CLEAR + unsaved-changes warning |
| 141 | TRIGGER | `TITLE.CGSO$CHAR_ARB_ED.KEY-LISTVAL` | – | – | – | DROPPED | OLB frame (TITLE) |
| 142 | TRIGGER | `TITLE.CGSO$CHAR_ARB_DO_ENB_Y.KEY-LISTVAL` | – | – | – | DROPPED | OLB frame (TITLE) |
| 143 | TRIGGER | `TITLE.CGSO$CHAR_ARB_MLINE.KEY-LISTVAL` | – | – | – | DROPPED | OLB frame (TITLE) |
| 144 | TRIGGER | `TITLE.CGSO$CHAR_ARB.KEY-LISTVAL` | – | – | – | DROPPED | OLB frame (TITLE) |
| 145 | TRIGGER | `TITLE.CGSO$CHAR_ARB_DO.KEY-LISTVAL` | – | – | – | DROPPED | OLB frame (TITLE) |
| 146 | TRIGGER | `TITLE.SYSTEM_DATE.WHEN-VALIDATE-ITEM` | – | – | – | DROPPED | OLB frame (TITLE) |
| 147 | TRIGGER | `EDI_MSG.EDI_MSG_LOVE_BUT.WHEN-BUTTON-PRESSED` | – | – | – | DROPPED | OLB frame (EDI_MSG) |
| 148 | TRIGGER | `LSIDE.FN1.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 149 | TRIGGER | `LSIDE.FN1.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 150 | TRIGGER | `LSIDE.FN1.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 151 | TRIGGER | `LSIDE.FN50.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 152 | TRIGGER | `LSIDE.FN50.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 153 | TRIGGER | `LSIDE.FN50.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 154 | TRIGGER | `LSIDE.FN2.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 155 | TRIGGER | `LSIDE.FN2.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 156 | TRIGGER | `LSIDE.FN2.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 157 | TRIGGER | `LSIDE.FN49.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 158 | TRIGGER | `LSIDE.FN49.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 159 | TRIGGER | `LSIDE.FN49.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 160 | TRIGGER | `LSIDE.FN3.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 161 | TRIGGER | `LSIDE.FN3.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 162 | TRIGGER | `LSIDE.FN3.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 163 | TRIGGER | `LSIDE.FN48.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 164 | TRIGGER | `LSIDE.FN48.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 165 | TRIGGER | `LSIDE.FN48.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 166 | TRIGGER | `LSIDE.FN4.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 167 | TRIGGER | `LSIDE.FN4.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 168 | TRIGGER | `LSIDE.FN4.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 169 | TRIGGER | `LSIDE.FN47.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 170 | TRIGGER | `LSIDE.FN47.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 171 | TRIGGER | `LSIDE.FN47.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 172 | TRIGGER | `LSIDE.FN5.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 173 | TRIGGER | `LSIDE.FN5.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 174 | TRIGGER | `LSIDE.FN5.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 175 | TRIGGER | `LSIDE.FN46.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 176 | TRIGGER | `LSIDE.FN46.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 177 | TRIGGER | `LSIDE.FN46.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 178 | TRIGGER | `LSIDE.FN6.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 179 | TRIGGER | `LSIDE.FN6.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 180 | TRIGGER | `LSIDE.FN6.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 181 | TRIGGER | `LSIDE.FN45.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 182 | TRIGGER | `LSIDE.FN45.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 183 | TRIGGER | `LSIDE.FN45.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 184 | TRIGGER | `LSIDE.FN7.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 185 | TRIGGER | `LSIDE.FN7.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 186 | TRIGGER | `LSIDE.FN7.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 187 | TRIGGER | `LSIDE.FN44.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 188 | TRIGGER | `LSIDE.FN44.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 189 | TRIGGER | `LSIDE.FN44.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 190 | TRIGGER | `LSIDE.FN8.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 191 | TRIGGER | `LSIDE.FN8.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 192 | TRIGGER | `LSIDE.FN8.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 193 | TRIGGER | `LSIDE.FN43.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 194 | TRIGGER | `LSIDE.FN43.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 195 | TRIGGER | `LSIDE.FN43.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 196 | TRIGGER | `LSIDE.FN9.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 197 | TRIGGER | `LSIDE.FN9.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 198 | TRIGGER | `LSIDE.FN9.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 199 | TRIGGER | `LSIDE.FN42.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 200 | TRIGGER | `LSIDE.FN42.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 201 | TRIGGER | `LSIDE.FN42.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 202 | TRIGGER | `LSIDE.FN10.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 203 | TRIGGER | `LSIDE.FN10.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 204 | TRIGGER | `LSIDE.FN10.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 205 | TRIGGER | `LSIDE.FN41.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 206 | TRIGGER | `LSIDE.FN41.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 207 | TRIGGER | `LSIDE.FN41.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 208 | TRIGGER | `LSIDE.FN11.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 209 | TRIGGER | `LSIDE.FN11.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 210 | TRIGGER | `LSIDE.FN11.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 211 | TRIGGER | `LSIDE.FN40.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 212 | TRIGGER | `LSIDE.FN40.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 213 | TRIGGER | `LSIDE.FN40.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 214 | TRIGGER | `LSIDE.FN12.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 215 | TRIGGER | `LSIDE.FN12.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 216 | TRIGGER | `LSIDE.FN12.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 217 | TRIGGER | `LSIDE.FN39.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 218 | TRIGGER | `LSIDE.FN39.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 219 | TRIGGER | `LSIDE.FN39.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 220 | TRIGGER | `LSIDE.FN13.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 221 | TRIGGER | `LSIDE.FN13.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 222 | TRIGGER | `LSIDE.FN13.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 223 | TRIGGER | `LSIDE.FN38.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 224 | TRIGGER | `LSIDE.FN38.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 225 | TRIGGER | `LSIDE.FN38.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 226 | TRIGGER | `LSIDE.FN14.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 227 | TRIGGER | `LSIDE.FN14.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 228 | TRIGGER | `LSIDE.FN14.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 229 | TRIGGER | `LSIDE.FN37.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 230 | TRIGGER | `LSIDE.FN37.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 231 | TRIGGER | `LSIDE.FN37.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 232 | TRIGGER | `LSIDE.FN15.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 233 | TRIGGER | `LSIDE.FN15.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 234 | TRIGGER | `LSIDE.FN15.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 235 | TRIGGER | `LSIDE.FN36.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 236 | TRIGGER | `LSIDE.FN36.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 237 | TRIGGER | `LSIDE.FN36.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 238 | TRIGGER | `LSIDE.FN16.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 239 | TRIGGER | `LSIDE.FN16.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 240 | TRIGGER | `LSIDE.FN16.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 241 | TRIGGER | `LSIDE.FN17.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 242 | TRIGGER | `LSIDE.FN17.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 243 | TRIGGER | `LSIDE.FN17.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 244 | TRIGGER | `LSIDE.FN34.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 245 | TRIGGER | `LSIDE.FN34.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 246 | TRIGGER | `LSIDE.FN34.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 247 | TRIGGER | `LSIDE.FN35.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 248 | TRIGGER | `LSIDE.FN35.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 249 | TRIGGER | `LSIDE.FN35.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 250 | TRIGGER | `LSIDE.FN18.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 251 | TRIGGER | `LSIDE.FN18.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 252 | TRIGGER | `LSIDE.FN18.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 253 | TRIGGER | `LSIDE.FN33.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 254 | TRIGGER | `LSIDE.FN33.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 255 | TRIGGER | `LSIDE.FN33.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 256 | TRIGGER | `LSIDE.FN19.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 257 | TRIGGER | `LSIDE.FN19.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 258 | TRIGGER | `LSIDE.FN19.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 259 | TRIGGER | `LSIDE.FN32.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 260 | TRIGGER | `LSIDE.FN32.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 261 | TRIGGER | `LSIDE.FN32.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 262 | TRIGGER | `LSIDE.FN20.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 263 | TRIGGER | `LSIDE.FN20.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 264 | TRIGGER | `LSIDE.FN20.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 265 | TRIGGER | `LSIDE.FN31.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 266 | TRIGGER | `LSIDE.FN31.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 267 | TRIGGER | `LSIDE.FN31.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 268 | TRIGGER | `LSIDE.FN21.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 269 | TRIGGER | `LSIDE.FN21.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 270 | TRIGGER | `LSIDE.FN21.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 271 | TRIGGER | `LSIDE.FN30.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 272 | TRIGGER | `LSIDE.FN30.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 273 | TRIGGER | `LSIDE.FN30.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 274 | TRIGGER | `LSIDE.FN22.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 275 | TRIGGER | `LSIDE.FN22.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 276 | TRIGGER | `LSIDE.FN22.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 277 | TRIGGER | `LSIDE.FN29.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 278 | TRIGGER | `LSIDE.FN29.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 279 | TRIGGER | `LSIDE.FN29.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 280 | TRIGGER | `LSIDE.FN23.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 281 | TRIGGER | `LSIDE.FN23.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 282 | TRIGGER | `LSIDE.FN23.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 283 | TRIGGER | `LSIDE.FN28.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 284 | TRIGGER | `LSIDE.FN28.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 285 | TRIGGER | `LSIDE.FN28.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 286 | TRIGGER | `LSIDE.FN24.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 287 | TRIGGER | `LSIDE.FN24.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 288 | TRIGGER | `LSIDE.FN24.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 289 | TRIGGER | `LSIDE.FN27.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 290 | TRIGGER | `LSIDE.FN27.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 291 | TRIGGER | `LSIDE.FN27.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 292 | TRIGGER | `LSIDE.FN25.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 293 | TRIGGER | `LSIDE.FN25.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 294 | TRIGGER | `LSIDE.FN25.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 295 | TRIGGER | `LSIDE.FN26.WHEN-MOUSE-ENTER` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 296 | TRIGGER | `LSIDE.FN26.WHEN-MOUSE-LEAVE` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 297 | TRIGGER | `LSIDE.FN26.WHEN-MOUSE-CLICK` | – | – | – | DROPPED | OLB frame (LSIDE) |
| 298 | TRIGGER | `TOOLBAR.KEY-DOWN` | – | – | – | DROPPED | OLB toolbar / side-menu keyboard |
| 299 | TRIGGER | `TOOLBAR.KEY-UP` | – | – | – | DROPPED | OLB toolbar / side-menu keyboard |
| 300 | TRIGGER | `TOOLBAR.KEY-NEXT-ITEM` | – | – | – | DROPPED | OLB toolbar / side-menu keyboard |
| 301 | TRIGGER | `TOOLBAR.SAVE.WHEN-BUTTON-PRESSED` | SAVE (page 0 toolbar) | 0 | – | MAPPED | toolbar button |
| 302 | TRIGGER | `TOOLBAR.CLEAR_ALL.WHEN-BUTTON-PRESSED` | CLEAR (page 0 toolbar) | 0 | – | MAPPED | toolbar button |
| 303 | TRIGGER | `TOOLBAR.EXIT.WHEN-BUTTON-PRESSED` | BACK (page 0 toolbar) | 0 | – | MAPPED | toolbar button |
| 304 | TRIGGER | `TOOLBAR.EXIT1.WHEN-BUTTON-PRESSED` | BACK (page 0 toolbar) | 0 | – | MAPPED | toolbar button |
| 305 | TRIGGER | `TOOLBAR.ENTER.WHEN-BUTTON-PRESSED` | SEARCH (page 0 toolbar) | 0 | – | MAPPED | toolbar button |
| 306 | TRIGGER | `TOOLBAR.EXECUTE.WHEN-BUTTON-PRESSED` | SEARCH (page 0 toolbar) | 0 | – | MAPPED | toolbar button |
| 307 | TRIGGER | `TOOLBAR.REMOVE.WHEN-BUTTON-PRESSED` | DELETE (page 0 toolbar) | 0 | – | MAPPED | toolbar button |
| 308 | TRIGGER | `TOOLBAR.LIST_VALUE.WHEN-BUTTON-PRESSED` | – | – | – | DROPPED | OLB toolbar / side-menu keyboard |
| 309 | TRIGGER | `TOOLBAR.HELP.WHEN-BUTTON-PRESSED` | – | – | – | DROPPED | OLB toolbar / side-menu keyboard |
| 310 | TRIGGER | `TOOLBAR.LAST_REC.WHEN-BUTTON-PRESSED` | – | – | – | DROPPED | OLB toolbar / side-menu keyboard |
| 311 | TRIGGER | `TOOLBAR.RE_ENTER_QUERY.WHEN-BUTTON-PRESSED` | SEARCH (page 0 toolbar) | 0 | – | MAPPED | toolbar button |
| 312 | TRIGGER | `TOOLBAR.FIRST_REC.WHEN-BUTTON-PRESSED` | – | – | – | DROPPED | OLB toolbar / side-menu keyboard |
| 313 | TRIGGER | `TOOLBAR.PAGE_UP.WHEN-BUTTON-PRESSED` | – | – | – | DROPPED | OLB toolbar / side-menu keyboard |
| 314 | TRIGGER | `TOOLBAR.PAGE_DOWN.WHEN-BUTTON-PRESSED` | – | – | – | DROPPED | OLB toolbar / side-menu keyboard |
| 315 | TRIGGER | `TOOLBAR.FUN_BUT.WHEN-MOUSE-UP` | FUNCS (page 0 toolbar) | 0 | – | MAPPED | toolbar button |
| 316 | TRIGGER | `TOOLBAR.FUN_BUT.WHEN-MOUSE-DOWN` | FUNCS (page 0 toolbar) | 0 | – | MAPPED | toolbar button |
| 317 | TRIGGER | `IMPR_PRTL_NAT.ON-ERROR` | APP_ERROR_HANDLER (f345) | – | – | MAPPED | Designer CGTE$ trap, generic texts only |
| 318 | TRIGGER | `IMPR_PRTL_NAT.KEY-HELP` | – | – | – | DROPPED | MS-Help obsolete |
| 319 | TRIGGER | `IMPR_PRTL_NAT.PRE-DELETE` | PRE-DELETE | 1116 | IMPR1116.PRE_DELETE | MAPPED | request DELETE refused (Delete Allowed = No) |
| 320 | TRIGGER | `IMPR_PRTL_NAT.PRE-INSERT` | PRE-INSERT | 1116 | IMPR1116.PRE_INSERT | MAPPED | request CREATE refused (Insert Allowed = No); log type 1 cannot happen |
| 321 | TRIGGER | `IMPR_PRTL_NAT.PRE-UPDATE` | PRE-UPDATE | 1116 | IMPR1116.PRE_UPDATE | MAPPED | activity log ACTIVITY_DB (9, 8, 2, PRTL_NAT_ISN) |
| 322 | TRIGGER | `IMPR_PRTL_NAT.WHEN-NEW-RECORD-INSTANCE` | IMPORTERS region SQL (binds P1116_IMPR_TYPE_CD ... BUS_ID_BRNCH) | 1116 | – | MAPPED | GO_BLOCK / CLEAR_BLOCK / EXECUTE_QUERY -> grid queried with the open record |
| 323 | TRIGGER | `IMPR_PRTL_NAT.PRTL_NAT_ISN.KEY-LISTVAL` | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 324 | TRIGGER | `IMPR_PRTL_NAT.BUS_ID.KEY-LISTVAL` | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 325 | TRIGGER | `IMPR_PRTL_NAT.BUS_ID_BRNCH.KEY-LISTVAL` | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 326 | TRIGGER | `IMPR_PRTL_NAT.TIN_NBR.KEY-LISTVAL` | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 327 | TRIGGER | `IMPR_PRTL_NAT.ID_TYPE_GZT.KEY-LISTVAL` | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 328 | TRIGGER | `IMPR_PRTL_NAT.BUS_ID_NEW.KEY-LISTVAL` | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 329 | TRIGGER | `IMPR_PRTL_NAT.USER_ID.KEY-LISTVAL` | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 330 | TRIGGER | `IMPR_PRTL_NAT.GAZT_NAME.KEY-LISTVAL` | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 331 | TRIGGER | `IMPR_PRTL_NAT.REVIEW_FLAG.KEY-LISTVAL` | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 332 | TRIGGER | `IMPORTERS.POST-QUERY` | IMPORTERS region SQL (outer joins) | 1116 | – | MAPPED | CGFK$QRY_IMPORTERS_IMP_ITIDT_F; message on a missing type dropped |
| 333 | TRIGGER | `IMPORTERS.ON-ERROR` | APP_ERROR_HANDLER (f345) | – | – | MAPPED | Designer CGTE$ trap, generic texts only |
| 334 | TRIGGER | `IMPORTERS.KEY-HELP` | – | – | – | DROPPED | MS-Help obsolete |
| 335 | TRIGGER | `IMPORTERS.PORT_CD.KEY-LISTVAL` | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 336 | TRIGGER | `IMPORTERS.PORT_CD2.WHEN-BUTTON-PRESSED` | – | – | – | DROPPED | LOV button hidden by WHEN-NEW-FORM-INSTANCE |
| 337 | TRIGGER | `IMPORTERS.IMPR_NBR.KEY-LISTVAL` | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 338 | TRIGGER | `IMPORTERS.HQ_IMPR_NBR.KEY-LISTVAL` | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 339 | TRIGGER | `IMPORTERS.BUS_ID.KEY-LISTVAL` | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 340 | TRIGGER | `IMPORTERS.BUS_ID_BRNCH.KEY-LISTVAL` | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 341 | TRIGGER | `IMPORTERS.L_IT1_IMPR_TYPE_NAME.KEY-LISTVAL` | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 342 | TRIGGER | `IMPORTERS.ARBC_IMPR_NAME.KEY-LISTVAL` | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 343 | TRIGGER | `IMPORTERS.L_BIT_BUS_ID_TYPE_NAME.KEY-LISTVAL` | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 344 | TRIGGER | `IMPORTERS.L_BIT_BUS_ID_TYPE_NAME2.WHEN-BUTTON-PRESSED` | – | – | – | DROPPED | LOV button hidden by WHEN-NEW-FORM-INSTANCE |
| 345 | LOV | `CGFK$IMPORTERS_PORT_CD` | – | – | – | DROPPED | IMPORTERS.PORT_CD is query only, LOV button hidden |
| 346 | LOV | `CGFK$IMPORTERS_L_BIT_BUS_ID_TY` | – | – | – | DROPPED | query only, button hidden; names from the IMPORTERS region SQL |
| 347 | RECORD_GROUP | `CGFK$IMPORTERS_PORT_CD` | – | – | – | DROPPED | query of LOV CGFK$IMPORTERS_PORT_CD |
| 348 | RECORD_GROUP | `CGFK$IMPORTERS_L_BIT_BUS_ID_TY` | – | – | – | DROPPED | query of LOV CGFK$IMPORTERS_L_BIT_BUS_ID_TY |
| 349 | RECORD_GROUP | `CGDV$DLRG (runtime)` | LOV_ID_TYPE_GZT, LOV_PRTL_NAT_FLAG (LOV_APX.REFERENCE_CODES) | 1116 | – | MAPPED | CREATE_GROUP_FROM_QUERY on CG_REF_CODES (domains ID_TYPE_GZT, PRTL_NAT_FLAG) in CGDV$POPULATE_DYNAMIC_LISTS |
| 350 | CANVAS | `LSIDE` | – | – | – | DROPPED | OLB canvas LSIDE |
| 351 | CANVAS | `EDI_MSG` | – | – | – | DROPPED | OLB canvas EDI_MSG |
| 352 | CANVAS | `TITLE` | – | – | – | DROPPED | OLB canvas TITLE |
| 353 | CANVAS | `TOOLBAR` | – | – | – | DROPPED | OLB canvas TOOLBAR |
| 354 | CANVAS | `CG$PAGE_1` | 1116 IMPR1116 | 1116 | – | MAPPED | main content canvas |
| 355 | WINDOW | `CGSO$WINDOW_1` | 1116 IMPR1116 | 1116 | – | MAPPED | console window |
| 356 | ALERT | `USR_CONFIRM_B` | – | – | – | DROPPED | not used by IMPR1116 code |
| 357 | ALERT | `USR_CONFIRM` | – | – | – | DROPPED | not used by IMPR1116 code |
| 358 | ALERT | `USR_WARNING_C` | – | – | – | DROPPED | not used by IMPR1116 code |
| 359 | ALERT | `USR_WARNING_B` | – | – | – | DROPPED | not used by IMPR1116 code |
| 360 | ALERT | `CFG_WARNING_A` | – | – | – | DROPPED | not used by IMPR1116 code |
| 361 | ALERT | `CFG_INFORMATION` | APP_ERROR_HANDLER (f345) / process messages | 1116 | – | MAPPED | NIB.ON_MESSAGE |
| 362 | ALERT | `CFG_ERROR` | APP_ERROR_HANDLER (f345) | 1116 | – | MAPPED | NIB.ON_ERROR |
| 363 | ALERT | `CFG_SYSTEM_ERROR` | FORMS_APX.FORM_TRIGGER_FAILURE (activity log error, IMPR1116.PRE_UPDATE) | 1116 | – | MAPPED | ACTIVITY.ADD_ACTIVITY |
| 364 | ALERT | `CFG_ASK_COMMIT` | Warn on Unsaved Changes (page 1116) | 1116 | – | MAPPED | Designer commit dialogue |
| 365 | PARAMETER | `P_SHPG_AGNT_NBR` | – | – | – | DROPPED | not used by the business code (function menu / reports / frame) |
| 366 | PARAMETER | `P_CTRL_LAST_EXEC_CD` | – | – | – | DROPPED | not used by the business code (function menu / reports / frame) |
| 367 | PARAMETER | `P_BANK_CD` | – | – | – | DROPPED | not used by the business code (function menu / reports / frame) |
| 368 | PARAMETER | `P_BANK_BRNCH_CD` | – | – | – | DROPPED | not used by the business code (function menu / reports / frame) |
| 369 | PARAMETER | `P_BRKR_PORT_CD` | – | – | – | DROPPED | not used by the business code (function menu / reports / frame) |
| 370 | PARAMETER | `P_LIC_TYPE` | – | – | – | DROPPED | not used by the business code (function menu / reports / frame) |
| 371 | PARAMETER | `P_BRKR_NBR` | – | – | – | DROPPED | not used by the business code (function menu / reports / frame) |
| 372 | PARAMETER | `P_CLASS_CD` | – | – | – | DROPPED | not used by the business code (function menu / reports / frame) |
| 373 | PARAMETER | `P_JOB_ID` | – | – | – | DROPPED | not used by the business code (function menu / reports / frame) |
| 374 | PARAMETER | `P_CURRENT_ITEM` | – | – | – | DROPPED | not used by the business code (function menu / reports / frame) |
| 375 | PARAMETER | `P_GROUP_CD` | – | – | – | DROPPED | not used by the business code (function menu / reports / frame) |
| 376 | PARAMETER | `P_USER_TYPE` | – | – | – | DROPPED | not used by the business code (function menu / reports / frame) |
| 377 | PARAMETER | `P_PORT_TYPE` | – | – | – | DROPPED | not used by the business code (function menu / reports / frame) |
| 378 | PARAMETER | `P_CURR_PORT_CD` | P_CURR_PORT_CD (f345) | – | – | MAPPED | ACTIVITY_DB port (PRE-UPDATE) |
| 379 | PARAMETER | `P_MODULE_ID` | P1116_MODULE_ID | 1116 | – | MAPPED | FORMS_APX.GET_MODULE_ID |
| 380 | PARAMETER | `P_MODULE_NAME` | SYS_ANAME (f345 page title) | – | – | MAPPED | title bar only |
| 381 | PARAMETER | `P_APPLICATION_NAME` | – | – | – | DROPPED | not used by the business code (function menu / reports / frame) |
| 382 | PARAMETER | `P_USER_ID` | SSO_APP_USER (f345) | – | – | MAPPED | ACTIVITY_DB user |
| 383 | PARAMETER | `P_WS_ID` | P_GLOBAL_V_WS_ID (f345) | – | – | MAPPED | ACTIVITY_DB workstation |
| 384 | PARAMETER | `P_USER_NAME` | V_USR_NAME (f345 header) | – | – | MAPPED | title bar only |
| 385 | PARAMETER | `CG$STARTUP_MODE` | – | – | – | DROPPED | not used by the business code (function menu / reports / frame) |
| 386 | LIBRARY | `OFGTEL` | – | – | – | DROPPED | MISSING SOURCE - generic constraint messages of the dropped ON-ERROR triggers (APP_ERROR_HANDLER) |
| 387 | LIBRARY | `OFGMES` | – | – | – | DROPPED | not needed in the browser (help, DLL, window, tab, pick list, block sync) |
| 388 | LIBRARY | `OFGHPL` | – | – | – | DROPPED | not needed in the browser (help, DLL, window, tab, pick list, block sync) |
| 389 | LIBRARY | `CIC_AMSG` | – | – | – | MAPPED | Des$Form_errors messages -> FORMS_APX / APP_ERROR_HANDLER |
| 390 | LIBRARY | `SEC_LIB` | – | – | – | DROPPED | not needed in the browser (help, DLL, window, tab, pick list, block sync) |
| 391 | LIBRARY | `CAPTION` | – | – | – | DROPPED | not needed in the browser (help, DLL, window, tab, pick list, block sync) |
| 392 | LIBRARY | `OFGBSL` | – | – | – | DROPPED | not needed in the browser (help, DLL, window, tab, pick list, block sync) |
| 393 | LIBRARY | `D2KWUTIL` | – | – | – | DROPPED | not needed in the browser (help, DLL, window, tab, pick list, block sync) |
| 394 | LIBRARY | `CUSTOMDLL` | – | – | – | DROPPED | not needed in the browser (help, DLL, window, tab, pick list, block sync) |
| 395 | LIBRARY | `D2KWUTIL_PDF` | – | – | – | DROPPED | not needed in the browser (help, DLL, window, tab, pick list, block sync) |
| 396 | LIBRARY | `GETCOMP` | – | – | – | DROPPED | not needed in the browser (help, DLL, window, tab, pick list, block sync) |
| 397 | LIBRARY | `OFGTAB` | – | – | – | DROPPED | not needed in the browser (help, DLL, window, tab, pick list, block sync) |
| 398 | LIBRARY | `PICKLIST` | – | – | – | DROPPED | not needed in the browser (help, DLL, window, tab, pick list, block sync) |
| 399 | LIBRARY | `POS` | – | – | – | DROPPED | not needed in the browser (help, DLL, window, tab, pick list, block sync) |
| 400 | LIBRARY | `SCDLL` | – | – | – | DROPPED | not needed in the browser (help, DLL, window, tab, pick list, block sync) |
| 401 | LIBRARY | `VCDLL` | – | – | – | DROPPED | not needed in the browser (help, DLL, window, tab, pick list, block sync) |
| 402 | LIBRARY | `CIC_LIB` | – | – | – | MAPPED | NIB / TMPLT -> f345; ACTIVITY -> ACTIVITY_DB; HIJDATE (title date only) -> f345 header |
| 403 | GLOBAL | `CG$HP_HFILE` | – | – | – | DROPPED | Designer help / frame / function menu - not needed |
| 404 | GLOBAL | `CG$HP_HPATH` | – | – | – | DROPPED | Designer help / frame / function menu - not needed |
| 405 | GLOBAL | `EXIT` | – | – | – | DROPPED | Designer help / frame / function menu - not needed |
| 406 | GLOBAL | `SYSTEM_OBJ` | – | – | – | DROPPED | Designer help / frame / function menu - not needed |
| 407 | CALLED_FORM | `V_CALLED_FORM (dynamic, PU EXECUTE_FUNCTION)` | FUNCS (Page Functions list, page 0) | 0 | – | TODO | functions of the module in SC_SYSTEM_OBJECTS unknown (inventory 15 #6) |
| 408 | PROGRAM_UNIT | `CHECK_TIMEOUT` | – | – | – | DROPPED | NIB wrapper not called by active code (timers, EDI ticker, window, print) |
| 409 | PROGRAM_UNIT | `MOUSE_CLICK` | FUNCS (page 0) | 0 | – | MAPPED | f345 Page Functions |
| 410 | PROGRAM_UNIT | `TOGGEL_WND` | – | – | – | DROPPED | NIB wrapper not called by active code (timers, EDI ticker, window, print) |
| 411 | PROGRAM_UNIT | `PRINT_REPORT` | – | – | – | DROPPED | NIB wrapper not called by active code (timers, EDI ticker, window, print) |
| 412 | PROGRAM_UNIT | `EXECUTE_FUNCTION` | FUNCS (page 0) | 0 | – | MAPPED | f345 Page Functions |
| 413 | PROGRAM_UNIT | `TERMINATE_FUN` | – | – | – | DROPPED | NIB wrapper not called by active code (timers, EDI ticker, window, print) |
| 414 | PROGRAM_UNIT | `CHECK_EDI_MSG_LOV` | – | – | – | DROPPED | NIB wrapper not called by active code (timers, EDI ticker, window, print) |
| 415 | PROGRAM_UNIT | `CHECK_EDI_MSG_TIMER` | – | – | – | DROPPED | NIB wrapper not called by active code (timers, EDI ticker, window, print) |
| 416 | PROGRAM_UNIT | `CHECK_EDI_ROLE_ID` | – | – | – | DROPPED | NIB wrapper not called by active code (timers, EDI ticker, window, print) |
| 417 | PROGRAM_UNIT | `EDI_MSG_LOV` | – | – | – | DROPPED | NIB wrapper not called by active code (timers, EDI ticker, window, print) |
| 418 | PROGRAM_UNIT | `FOR_EDI_MSG` | – | – | – | DROPPED | NIB wrapper not called by active code (timers, EDI ticker, window, print) |
| 419 | PROGRAM_UNIT | `RETURN_MSG` | – | – | – | DROPPED | NIB wrapper not called by active code (timers, EDI ticker, window, print) |
| 420 | PROGRAM_UNIT | `TURN_MSG` | – | – | – | DROPPED | NIB wrapper not called by active code (timers, EDI ticker, window, print) |
| 421 | PROGRAM_UNIT | `WHEN_TIMER_EXPIRED_MSG` | – | – | – | DROPPED | NIB wrapper not called by active code (timers, EDI ticker, window, print) |
| 422 | PROGRAM_UNIT | `CG$WHEN_NEW_FORM_INSTANCE` | – | – | – | DROPPED | lists -> shared LOVs |
| 423 | PROGRAM_UNIT | `CGDV$POPULATE_DYNAMIC_LISTS` | LOV_ID_TYPE_GZT, LOV_PRTL_NAT_FLAG | 1116 | – | MAPPED | LOV_APX.REFERENCE_CODES |
| 424 | PROGRAM_UNIT | `CGFK$QRY_IMPORTERS_IMP_ITIDT_F` | IMPORTERS region SQL (outer joins) | 1116 | – | MAPPED | POST-QUERY lookup as SQL |
| 425 | PROGRAM_UNIT | `CGTE$CHECK_CONSTRAINT_VIO` | APP_ERROR_HANDLER (f345) | – | – | MAPPED | generic constraint text |
| 426 | PROGRAM_UNIT | `EXEC_FUNS` | – | – | – | DROPPED | empty in Forms |
| 427 | PROGRAM_UNIT | `ADJ_FUNS` | – | – | – | DROPPED | empty in Forms |


## 15. Open items (TODO)

| # | Item | Needed from |
|---|---|---|
| 1 | Confirm decision #1 (one record per page) or ask for the editable all-rows grid | user |
| 2 | Texts of the CREATE / DELETE refusals | business owner |
| 3 | `IMPR_PRTL_NAT` DDL and DB triggers (do `USER_ID` / `LST_TRAN_DT` / `UPDATE_DT` change on update?) | DBA |
| 4 | `CG_REF_CODES` rows of `ID_TYPE_GZT`, `PRTL_NAT_FLAG` | data owner |
| 5 | Module functions in `SC_SYSTEM_OBJECTS` and the launcher of IMPR1116 | data owner |
| 6 | Grants (§13) | DBA |
