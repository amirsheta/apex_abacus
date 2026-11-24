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

<!-- TRACE -->

## 15. Open items (TODO)

| # | Item | Needed from |
|---|---|---|
| 1 | Confirm decision #1 (one record per page) or ask for the editable all-rows grid | user |
| 2 | Texts of the CREATE / DELETE refusals | business owner |
| 3 | `IMPR_PRTL_NAT` DDL and DB triggers (do `USER_ID` / `LST_TRAN_DT` / `UPDATE_DT` change on update?) | DBA |
| 4 | `CG_REF_CODES` rows of `ID_TYPE_GZT`, `PRTL_NAT_FLAG` | data owner |
| 5 | Module functions in `SC_SYSTEM_OBJECTS` and the launcher of IMPR1116 | data owner |
| 6 | Grants (§13) | DBA |
