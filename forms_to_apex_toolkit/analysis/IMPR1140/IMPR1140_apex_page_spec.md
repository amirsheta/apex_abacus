# IMPR1140 — APEX 21.2 page design (step 03)

| Item | Value |
|---|---|
| Form | `IMPR1140.fmb` — "قواعد التعامل مع المستوردين" |
| Date | 2026-11-24 |
| Inputs | [IMPR1140_inventory.md](IMPR1140_inventory.md), [IMPR1140_logic_extraction.md](IMPR1140_logic_extraction.md), [impr1140_spec.sql](../../plsql/IMPR1140/impr1140_spec.sql) (package `IMPR1140` 001), `apex/Reference/f345.sql`, `docs/f345_reference_standard.md` |
| Application | 202530 (installed from f345, already holding the IMPR1110 / IMPR1120 / SUPPORT_ENTRY exports) |
| Pages | main **1140** `IMPR1140`, search **114001** `IMPR1140_SEARCH` |
| Page group | IMPR (created by the IMPR1110 export) |
| Registry | [registry/IMPR1140_registry.sql](../../registry/IMPR1140_registry.sql) (generated with §14) |
| Status | design; the export of step 04 follows it exactly |

## 0. Decisions that shape the page

1. **Key.** `P0_PAGE_PK` = ROWID of the `IMPR_RULES` row, as IMPR1110 / IMPR1120. The search page passes it URL-safe (`TRANSLATE(ROWID, '+/', '-_')`); `IMPR1140.P0_PAGE_PK_CHECK` restores and checks it.
2. **Master DML is native.** `IMPR_RULES` is a normal editable block: Form region on table `IMPR_RULES`, `Process form` for CREATE / SAVE / DELETE, the Forms triggers around it as one-line processes (`PRE-INSERT`, `POST-INSERT`, `PRE-UPDATE`, `POST-UPDATE`, `KEY-DELREC`, `PRE-DELETE`).
3. **Details on tabs.** The tab canvas `CG$M_TAB_1` becomes a Tabs Container region (f345 template *Tabs Container*) holding the two IGs; tab labels = Forms tab page labels. The container is shown only when a rule is open (`P0_PAGE_PK` not null): details are added after the rule is saved (Forms: Prevent Masterless Operation = true).
4. **Detail DML is PL/SQL row DML** (as IMPR1120): `IMPR1140.IMPR_RULE_PORTS_SAVE_ROW` / `IMPR_RULE_TARIFF_SAVE_ROW` run the Forms PRE-* trigger code and then the row DML. Reasons: the grid column `EXEPTION_QTY` keeps the Forms item name but is the table column `EXCEPTED_QTY`; tariff rows may not be deleted; the ports insert rule depends on the master flag. The grid key is `ROW_ID` (ROWIDTOCHAR), returned for new rows.
5. **Server checks for block properties.** Forms blocked some rows through block properties; the server repeats them: ports insert while `ALL_BRNCH_FLAG = 1` (`IMPR_RULE_PORTS_PRE_INSERT`), tariff delete (`IMPR_RULE_TARIFF_SAVE_ROW`, grid edit operations `i:u` as well). Texts are placeholders to agree (inventory §15 #6).
6. **No JavaScript.** Every behaviour is FOS + native actions; JavaScript actions: 0.

## 1. Page type decision per block

| Block | Characteristics | APEX 21.2 choice | f345 template / classes |
|---|---|---|---|
| TITLE (OLB) | screen title | hero region `IMPR_RULES_HERO` | Blank with Attributes, `cg-hero` |
| EDI_MSG, LSIDE, TOOLBAR (OLB), CG$CTRL | frame / Designer | page 0 (toolbar, FUNCS drawer) / not migrated | — |
| IMPR_RULES | single record, base table, insert / update / delete | Form region `IMPR_RULES` | Interactive Report, `zatca-forms cg-form cg-card` |
| (tab canvas CG$M_TAB_1) | 2 tab pages | Tabs Container `CG$M_TAB_1` | Tabs Container (`11621923018393869712`) |
| IMPR_RULE_PORTS | multi record (8), insert / update / delete, port of the user | editable IG `IMPR_RULE_PORTS`, tab "جمارك الإستثناء" | Standard, `#DEFAULT#:t-Region--noPadding`, `cg-card cg-grid` |
| IMPR_RULE_TARIFF | multi record (8), insert / update, no delete | editable IG `IMPR_RULE_TARIFF` (`i:u`), tab "بنود التعريفة المستثاه" | Standard, `#DEFAULT#:t-Region--noPadding`, `cg-card cg-grid` |
| Enter / Execute Query of IMPR_RULES | | search page 114001 | Blank with Attributes `zatca-forms cg-form` + Standard IG |

## 2. Pages

| Page | Name / alias | Mode | Template | Source | Forms role | Navigation |
|---|---|---|---|---|---|---|
| 1140 | `IMPR1140` / `IMPR1140` | Normal | Zatca-Minimal_No_Navigation (`11622270914969205733`), CSS `zf`, protection C, title `&SYS_ANAME.` | window CGSO$WINDOW_1, canvases CG$PAGE_1 + CG$M_TAB_1 | application privileges (no scheme); role `IMP_EXCEPTION_FASH` checked in the package for rule types 13 / 14 | opened from the f345 menu (module of IMPR1140 in `SC_SYSTEM_OBJECTS`) |
| 114001 | `IMPR1140_SEARCH` / `IMPR1140-SEARCH` | Modal 1800 × 800 | theme default (Modal Dialog), CSS `zf`, protection C | Enter / Execute Query of IMPR_RULES | — | page 0 `SEARCH` |

No other modal page (no `G_LAST_PAGE KEEP` needed).

## 3. Regions

### Page 1140

| Seq | Region | Static ID | Type | Source | Key | Template / options / classes | Parent | Edit | Forms |
|---|---|---|---|---|---|---|---|---|---|
| 10 | الهيدر | `IMPR_RULES_HERO` | Static Content (HTML with `&P1140_HERO_TITLE.`) | — | — | Blank with Attributes, `#DEFAULT#`, `cg-hero` | — | — | TITLE |
| 20 | قواعد التعامل مع المستوردين | `IMPR_RULES` | Form (`NATIVE_FORM`) | table `IMPR_RULES`, ROWID column included | ROWID (`P1140_ROW_ID`) | Interactive Report, `#DEFAULT#`, `zatca-forms cg-form cg-card` | — | insert / update / delete | IMPR_RULES |
| 30 | تفاصيل الاستثناء | `CG$M_TAB_1` | Static Content | — | — | Tabs Container (`11621923018393869712`), `#DEFAULT#` | — | — | canvas CG$M_TAB_1; condition `P0_PAGE_PK` is not null |
| 40 | جمارك الإستثناء | `IMPR_RULE_PORTS` | IG (`NATIVE_IG`) | SQL below; Items to Submit `P1140_RULE_ISN` | `ROW_ID` | Standard, `#DEFAULT#:t-Region--noPadding`, `cg-card cg-grid` | `CG$M_TAB_1` | `i:u:d` | IMPR_RULE_PORTS (tab page 1) |
| 50 | بنود التعريفة المستثاه | `IMPR_RULE_TARIFF` | IG (`NATIVE_IG`) | SQL below; Items to Submit `P1140_RULE_ISN` | `ROW_ID` | as above | `CG$M_TAB_1` | `i:u` | IMPR_RULE_TARIFF (tab page 2) |

```sql
-- IMPR_RULE_PORTS: block WHERE PORT_CD = :PARAMETER.P_CURR_PORT_CD, relation CGFK$IRP_IR2_FK, POST-QUERY port name
SELECT ROWIDTOCHAR(p.ROWID) AS row_id, p.rule_isn, p.port_cd, s.port_name, p.rec_status
  FROM impr_rule_ports p, sd_ports s
 WHERE p.rule_isn = :P1140_RULE_ISN
   AND p.port_cd  = :P_CURR_PORT_CD
   AND s.port_cd (+) = p.port_cd

-- IMPR_RULE_TARIFF: relation CGFK$IRT_IR_FK, POST-QUERY international unit, HRMNZD_CODE POST-CHANGE description;
-- item EXEPTION_QTY is the column EXCEPTED_QTY. ORDER BY ITEM_SEQUENCE added (the block has none: insertion order).
SELECT ROWIDTOCHAR(t.ROWID) AS row_id, t.rule_isn, t.hrmnzd_code, ht.item_arbc_desc AS ht_item_arbc_desc,
       t.excepted_qty AS exeption_qty, t.remained_qty,
       (SELECT IMPR1140.IMPR_RULE_TARIFF_POST_QUERY(HRMNZD_CODE => t.hrmnzd_code) FROM dual) AS intl_unit,
       t.rec_status, t.item_sequence
  FROM impr_rule_tariff t, harmonized_tariff ht
 WHERE t.rule_isn = :P1140_RULE_ISN
   AND ht.hrmnzd_code (+) = t.hrmnzd_code
 ORDER BY t.item_sequence
```

IG settings (standard §8): `p_add_row_if_empty false`, `p_submit_checked_rows false`, `p_lazy_loading false`, toolbar `SEARCH_COLUMN:SEARCH_FIELD:ACTIONS_MENU:RESET`, no public reports, 8 rows per page (Forms Records Displayed = 8).

### Page 114001 – IMPR1140_SEARCH

| Seq | Region | Static ID | Type | Template | Source |
|---|---|---|---|---|---|
| 10 | بحث | `IMPR_RULES_SEARCH_CRITERIA` | Static Content: `P114001_SEARCH`, buttons SEARCH / CLEAR | Blank with Attributes, `zatca-forms cg-form` | IMPR_RULES query criteria |
| 20 | قواعد التعامل مع المستوردين | `IMPR_RULES_SEARCH` | IG read only | Standard, `#DEFAULT#:t-Region--noPadding`, `cg-card cg-grid`; lazy loading, no total row count, toolbar `ACTIONS_MENU:RESET` (as IMPR1120) | SQL below |

```sql
-- one search text over every shown column; every row while the search text is empty (user request 2026-11-26).
-- The PRE-QUERY BUS_ID_TYPE_NAME criterion is part of the text search. No ORDER BY (as IMPR1120).
SELECT TRANSLATE(ROWIDTOCHAR(r.ROWID), '+/', '-_') AS row_id,   -- URL-safe: a '+' in f?p arrives as a space
       r.rule_isn, r.rule_type, rt.rv_meaning AS rule_type_name,
       DECODE(r.all_brnch_flag, 1, 'جميع الجمارك', 0, 'جمرك محدد') AS all_brnch_flag_name,
       r.hq_impr_nbr,
       CASE WHEN r.rule_type = 12
            THEN (SELECT MAX(i.arbc_impr_name) FROM importers i
                   WHERE i.port_cd = :P_CURR_PORT_CD AND i.hq_impr_nbr = r.hq_impr_nbr)
            ELSE (SELECT MAX(s.arbc_impr_name) FROM single_importers s WHERE s.hq_impr_nbr = r.hq_impr_nbr)
       END AS l_si_arbc_impr_name,
       r.bus_id_type_cd, b.bus_id_type_name, r.bus_id, r.bus_id_brnch, rs.rv_meaning AS rec_status_name
  FROM impr_rules r, bus_id_types b, cg_ref_codes rt, cg_ref_codes rs
 WHERE b.bus_id_type_cd (+) = r.bus_id_type_cd
   AND rt.rv_domain (+) = 'RULE_TYPE'  AND rt.rv_low_value (+) = TO_CHAR(r.rule_type)
   AND rs.rv_domain (+) = 'REC_STATUS' AND rs.rv_low_value (+) = TO_CHAR(r.rec_status)
   AND (:P114001_SEARCH IS NULL OR INSTR(UPPER(r.rule_isn || '|' || r.rule_type || '|' || rt.rv_meaning || '|' || r.hq_impr_nbr || '|' ||
                   b.bus_id_type_name || '|' || r.bus_id || '|' || r.bus_id_brnch || '|' || rs.rv_meaning),
             UPPER(TRIM(:P114001_SEARCH))) > 0)
```

## 4. Items

### 4.1 Page 1140 – region `IMPR_RULES` (Forms tab order)

| Item | Column | Type | Label | Req. | Default | LOV | Max | Read only / notes | Forms item |
|---|---|---|---|---|---|---|---|---|---|
| `P1140_ROW_ID` | ROWID | Hidden (value protected) | — | — | — | — | — | Form region primary key = `P0_PAGE_PK` | key mode ROWID |
| `P1140_RULE_ISN` | RULE_ISN | Display Only | مسلسل الاستثناء | No | — | — | — | set by `PRE-INSERT` | RULE_ISN |
| `P1140_RULE_TYPE` | RULE_TYPE | Select List | نوع الاستثناء | No | 1 | `LOV_RULE_TYPE` | — | — | RULE_TYPE (pop list, CG_REF_CODES) |
| `P1140_ALL_BRNCH_FLAG` | ALL_BRNCH_FLAG | Select List | استخدام الاستثناء | No | 0 | `LOV_ALL_BRNCH_FLAG` (static) | — | — | ALL_BRNCH_FLAG |
| `P1140_HQ_IMPR_NBR` | HQ_IMPR_NBR | Popup LOV | رقم المستورد الموحد | No | — | `LOV_SINGLE_IMPORTERS`, Items to Submit `P1140_RULE_TYPE` | 11 | — | HQ_IMPR_NBR (+ button B_IMP) |
| `P1140_L_SI_ARBC_IMPR_NAME` | — | Display Only | — (same line) | — | — | — | — | filled by `POST-QUERY` / FOS | L_SI_ARBC_IMPR_NAME |
| `P1140_REC_STATUS` | REC_STATUS | Select List | حـالة السجل | No | 1 | `LOV_REC_STATUS` | — | — | REC_STATUS |
| `P1140_BUS_ID_TYPE_CD` | BUS_ID_TYPE_CD | Display Only | نوع الرقم الاستدلالى | **Yes** (Forms Required) | — | — | — | filled by FOS; saved | BUS_ID_TYPE_CD |
| `P1140_BUS_ID_TYPE_NAME` | — | Display Only | — (same line) | — | — | — | — | filled by `POST-QUERY` / FOS | BUS_ID_TYPE_NAME |
| `P1140_BUS_ID` | BUS_ID | Display Only | الرقم الاستدلالى | No | — | — | — | filled by FOS; saved | BUS_ID |
| `P1140_BUS_ID_BRNCH` | BUS_ID_BRNCH | Text Field | الفرع | No | — | — | 10 | enabled only while `ALL_BRNCH_FLAG` ≠ 1 (DA); cleared by `ALL_BRNCH_FLAG WHEN-VALIDATE-ITEM` | BUS_ID_BRNCH |

Item `D` (non-database, hidden in PRE-FORM) and button `B_IMP` (LOV button) are not created. Display Only items that are saved (`BUS_ID_TYPE_CD`, `BUS_ID`) keep *Send On Page Submit* = No: the FOS action returns them into session state and `Process form` writes the session values (as IMPR1110). Label templates Required - Above / Optional - Above with `t-Form-fieldContainer--stretchInputs`; icons from `scripts/item_icons.py`.

### 4.2 Page 1140 – other items

| Item | Region | Type | Note |
|---|---|---|---|
| `P1140_HERO_TITLE` | hero | Hidden | `HEADER TITLE` |
| `P1140_MODULE_ID` | hero | Hidden, protection S | kept by SCREEN ENTRY RESET |

No `P1140_REPORT` (the form has no report of its own).

### 4.3 Page 1140 – IG columns

`IMPR_RULE_PORTS` (Forms navigation order):

| Column | Type | Heading | Req. | Default | LOV | Read only | Forms |
|---|---|---|---|---|---|---|---|
| `ROW_ID` | Hidden, primary key | — | — | — | — | — | ROWID |
| `RULE_ISN` | Hidden | — | — | item `P1140_RULE_ISN` | — | — | RULE_ISN (CopyValueFrom IMPR_RULES.RULE_ISN) |
| `PORT_CD` | Popup LOV (number_only n/a) | رمز الجمرك | Yes | — | `LOV_SD_PORTS` | `:ROW_ID IS NOT NULL` (Update Allowed = false) | PORT_CD (+ button PORT_CD2) |
| `PORT_NAME` | Display Only, query only | اسم الجمرك | — | — | — | — | PORT_NAME |
| `REC_STATUS` | Select List | حالة السجل | Yes | 1 | `LOV_REC_STATUS` | — | REC_STATUS |

`IMPR_RULE_TARIFF`:

| Column | Type | Heading | Req. | Default | LOV | Read only | Forms |
|---|---|---|---|---|---|---|---|
| `ROW_ID` | Hidden, primary key | — | — | — | — | — | ROWID |
| `RULE_ISN` | Hidden | — | — | item `P1140_RULE_ISN` | — | — | RULE_ISN |
| `HRMNZD_CODE` | Popup LOV | رمز بند التعريفة | Yes | — | `LOV_HARMONIZED_TARIFF` | `:ROW_ID IS NOT NULL` | HRMNZD_CODE (+ button HRMNZD_CODE2) |
| `HT_ITEM_ARBC_DESC` | Display Only, query only | الوصــــــــــف | — | — | — | — | HT_ITEM_ARBC_DESC |
| `EXEPTION_QTY` | Number Field, `number_only` | الكمية المستثناة | Yes | — | — | — | EXEPTION_QTY (column EXCEPTED_QTY) |
| `REMAINED_QTY` | Display Only (saved) | الكمية المتبقية | — | — | — | — | REMAINED_QTY |
| `INTL_UNIT` | Display Only, query only | الوحدةالدوليه | — | — | — | — | INTL_UNIT |
| `REC_STATUS` | Select List | حالة السجل | Yes | 1 | `LOV_REC_STATUS` | — | REC_STATUS |
| `ITEM_SEQUENCE` | Hidden | — | — | — | — | — | ITEM_SEQUENCE (PRE-INSERT) |

### 4.4 Page 114001

| Item | Type | Label | Note |
|---|---|---|---|
| `P114001_SEARCH` | Text Field, max 200 | بحث في كل الأعمدة | one text over all result columns (as IMPR1120) |

Search grid columns: `ROW_ID` (hidden key), `RULE_ISN` (link → `f?p=&APP_ID.:1140:&SESSION.::&DEBUG.:1140:P0_PAGE_PK:&ROW_ID.`), `RULE_TYPE`, `RULE_TYPE_NAME`, `ALL_BRNCH_FLAG_NAME`, `HQ_IMPR_NBR`, `L_SI_ARBC_IMPR_NAME`, `BUS_ID_TYPE_CD`, `BUS_ID_TYPE_NAME`, `BUS_ID`, `BUS_ID_BRNCH`, `REC_STATUS_NAME` (Display Only).

## 5. Buttons

No page button on 1140: every Forms toolbar button maps to the page 0 toolbar (CREATE / SAVE / DELETE / SEARCH / CLEAR / FUNCS / BACK); the LOV buttons `B_IMP`, `PORT_CD2`, `HRMNZD_CODE2` are the Popup LOV icons.

| Button | Page / region | Action | Template | Source |
|---|---|---|---|---|
| `SEARCH` | 114001 / criteria | Defined by DA (Refresh) | Text with Icon, `#DEFAULT#:t-Button--iconLeft`, `fa-search`, `cg-b-search` | TOOLBAR.EXECUTE |
| `CLEAR` | 114001 / criteria | Defined by DA (Clear + Refresh) | same, `fa-eraser`, `cg-b-clear` | TOOLBAR.CLEAR_ALL |

## 6. LOVs

| Forms LOV / list | APEX LOV | Type | Function body / values | Used by | Item type |
|---|---|---|---|---|---|
| pop list RULE_TYPE (CGDV$DLRG, domain RULE_TYPE) | `LOV_RULE_TYPE` (new) | function body returning SQL | `return LOV_APX.REFERENCE_CODES(P_DOMAIN => 'RULE_TYPE');` | `P1140_RULE_TYPE` | Select List |
| pop lists REC_STATUS ×3 (domain REC_STATUS) | `LOV_REC_STATUS` (new) | function body returning SQL | `return LOV_APX.REFERENCE_CODES(P_DOMAIN => 'REC_STATUS');` | `P1140_REC_STATUS`, both grid `REC_STATUS` | Select List |
| pop list ALL_BRNCH_FLAG (static in the XML) | `LOV_ALL_BRNCH_FLAG` (new) | Static | 1 = جميع الجمارك, 0 = جمرك محدد | `P1140_ALL_BRNCH_FLAG` | Select List |
| LOV forms LOV_IMPORT_HQ_NBR / LOV_IMPORT_HQ_N12 (PU SINGLE_IMP_LOV) | `LOV_SINGLE_IMPORTERS` (new) | function body returning SQL | `return LOV_APX.SINGLE_IMPORTERS(P_RULE_TYPE_ITEM => 'P1140_RULE_TYPE');` columns D (الرقم الموحد), ARBC_IMPR_NAME, BUS_ID, R hidden | `P1140_HQ_IMPR_NBR` | Popup LOV (Items to Submit `P1140_RULE_TYPE`) |
| CGFK$IMPR_RULE_PORTS_PORT_CD / LOV form LOV_SD_PORTS | `LOV_SD_PORTS` (**reused**, IMPR1110) | function body | `LOV_APX.LOV_SD_PORTS(P_PORT_TYPE_ITEM => 'P_PORT_TYPE')` | grid `PORT_CD` | Popup LOV |
| CGFK$IMPR_RULE_TARIFF_HRMNZD_C / LOV form LOV_TRF_ITEMS | `LOV_HARMONIZED_TARIFF` (new) | function body returning SQL | `return LOV_APX.LOV_HARMONIZED_TARIFF;` columns D (رمز البند), ITEM_ARBC_DESC, R hidden | grid `HRMNZD_CODE` | Popup LOV |
| CGLT$CVS_DATA | — | — | Designer tab metadata, dropped | — | — |

Multi-column returns of the LOV forms (`BUS_ID`, `ARBC_IMPR_NAME`, `PORT_NAME`, `ITEM_ARBC_DESC`) come back through the WHEN-VALIDATE-ITEM DAs (FOS Items to Return), not through the LOV.

## 7. Validations

| Seq | Name | Level | Type | Code | Item / column | Condition | Source |
|---|---|---|---|---|---|---|---|
| 10 | `RULE_TYPE VALIDATION` | item | Function Body returning Error Text | `return IMPR1140.RULE_TYPE_VALIDATION(P_RULE_TYPE => :P1140_RULE_TYPE);` | `P1140_RULE_TYPE` | request CREATE, SAVE | RULE_TYPE WLC / WVI |
| 20 | `HQ_IMPR_NBR VALIDATION` | item | same | `return IMPR1140.HQ_IMPR_NBR_VALIDATION(P_HQ_IMPR_NBR => :P1140_HQ_IMPR_NBR, P_RULE_TYPE => :P1140_RULE_TYPE, P_CURR_PORT_CD => :P_CURR_PORT_CD);` | `P1140_HQ_IMPR_NBR` | CREATE, SAVE | HQ_IMPR_NBR WVI |
| 30 | `BUS_ID_TYPE_CD REQUIRED` | item | same | `return FORMS_APX.REQUIRED_VALIDATION(ITEM_VALUE => :P1140_BUS_ID_TYPE_CD, ITEM_LABEL => 'نوع الرقم الاستدلالى');` | `P1140_BUS_ID_TYPE_CD` | CREATE, SAVE | item Required = true |
| 110 | `IMPR_RULE_PORTS PORT_CD VALIDATION` | IG row | same | `return IMPR1140.PORT_CD_VALIDATION(PORT_CD => :PORT_CD);` | `PORT_CD` | `:APEX$ROW_STATUS = 'C'` (not updatable) | PORT_CD WVI |
| 210 | `IMPR_RULE_TARIFF HRMNZD_CODE VALIDATION` | IG row | same | `return IMPR1140.HRMNZD_CODE_VALIDATION(HRMNZD_CODE => :HRMNZD_CODE, P_RULE_ISN => :P1140_RULE_ISN, P_HQ_IMPR_NBR => :P1140_HQ_IMPR_NBR, P_BUS_ID_TYPE_CD => :P1140_BUS_ID_TYPE_CD, P_BUS_ID => :P1140_BUS_ID);` | `HRMNZD_CODE` | `:APEX$ROW_STATUS = 'C'` | HRMNZD_CODE WVI |

Error display: inline with field and in notification. Column required checks come from the IG column *Required* attribute.

## 8. Processes

### Page 1140

| Point | Seq | Name | Type | Code | Condition | Source |
|---|---|---|---|---|---|---|
| Before Header | 10 | `New` | PL/SQL | `NULL;` (f345 session setup, as AGR1100) | Never | f345 |
| | 20 | `P0_PAGE_PK CHECK` | PL/SQL | `IMPR1140.P0_PAGE_PK_CHECK(P_PAGE_PK => :P0_PAGE_PK);` | — | f345 |
| | 40 | `PARAMETERS` | PL/SQL | `:P1140_MODULE_ID := FORMS_APX.GET_MODULE_ID(P_MODULE_ID => :P1140_MODULE_ID, FORM_NAME => 'IMPR1140');` | — | f345 |
| | 70 | `P0_PAGE_PK` | PL/SQL | `:P1140_ROW_ID := :P0_PAGE_PK;` | — | f345 |
| | 80 | `Initialize form` | Form - Initialization | region `IMPR_RULES` | — | block query |
| | 82 | `POST-QUERY` | PL/SQL | `IMPR1140.POST_QUERY(P_HQ_IMPR_NBR => :P1140_HQ_IMPR_NBR, P_RULE_TYPE => :P1140_RULE_TYPE, P_BUS_ID_TYPE_CD => :P1140_BUS_ID_TYPE_CD, P_CURR_PORT_CD => :P_CURR_PORT_CD, P_L_SI_ARBC_IMPR_NAME => :P1140_L_SI_ARBC_IMPR_NAME, P_BUS_ID_TYPE_NAME => :P1140_BUS_ID_TYPE_NAME);` | `P1140_ROW_ID` not null | IMPR_RULES.POST-QUERY |
| | 100 | `HEADER TITLE` | PL/SQL | `FORMS_APX.HEADER_TITLE(P_MODULE_ID => :P1140_MODULE_ID, P_HERO_TITLE => :P1140_HERO_TITLE, DEFAULT_TITLE => 'قواعد التعامل مع المستوردين');` | — | TITLE |
| After Submit | 5 | `ALL_BRNCH_FLAG WHEN-VALIDATE-ITEM` | PL/SQL | `IMPR1140.ADJ_BRANCH(P_ALL_BRNCH_FLAG => :P1140_ALL_BRNCH_FLAG, P_BUS_ID_BRNCH => :P1140_BUS_ID_BRNCH);` | request CREATE, SAVE | PU ADJ_BRANCH |
| | 10 | `PRE-INSERT` | PL/SQL | `IMPR1140.PRE_INSERT(P_RULE_ISN => :P1140_RULE_ISN, P_RULE_TYPE => :P1140_RULE_TYPE, P_CURR_PORT_CD => :P_CURR_PORT_CD, SSO_APP_USER => :SSO_APP_USER, P_GLOBAL_V_WS_ID => :P_GLOBAL_V_WS_ID);` | `:P0_PAGE_PK IS NULL AND :REQUEST = 'CREATE'` | IMPR_RULES.PRE-INSERT |
| | 20 | `PRE-UPDATE` | PL/SQL | `IMPR1140.PRE_UPDATE(P_RULE_TYPE => :P1140_RULE_TYPE, P_CURR_PORT_CD => :P_CURR_PORT_CD, SSO_APP_USER => :SSO_APP_USER);` | `:P0_PAGE_PK IS NOT NULL AND :REQUEST = 'SAVE'` | IMPR_RULES.PRE-UPDATE |
| | 25 | `KEY-DELREC` | PL/SQL | `IMPR1140.KEY_DELREC(P_RULE_ISN => :P1140_RULE_ISN, P_CURR_PORT_CD => :P_CURR_PORT_CD);` | request DELETE | IMPR_RULES.KEY-DELREC |
| | 30 | `PRE-DELETE` | PL/SQL | `IMPR1140.PRE_DELETE(P_RULE_ISN => :P1140_RULE_ISN, P_CURR_PORT_CD => :P_CURR_PORT_CD, SSO_APP_USER => :SSO_APP_USER, P_GLOBAL_V_WS_ID => :P_GLOBAL_V_WS_ID);` | request DELETE | IMPR_RULES.PRE-DELETE |
| | 40 | `Process form` | Form - Automatic Row Processing (DML), region source | region `IMPR_RULES` | request CREATE, SAVE | block DML |
| | 41 | `Process form - DELETE` | same | region `IMPR_RULES` | request DELETE | block DML |
| | 50 | `POST-INSERT` | PL/SQL | `IMPR1140.POST_INSERT(P_RULE_ISN => :P1140_RULE_ISN, P_HQ_IMPR_NBR => :P1140_HQ_IMPR_NBR, P_RULE_TYPE => :P1140_RULE_TYPE, P_REC_STATUS => :P1140_REC_STATUS, P_CURR_PORT_CD => :P_CURR_PORT_CD);` | request CREATE | IMPR_RULES.POST-INSERT |
| | 60 | `POST-UPDATE` | PL/SQL | `IMPR1140.POST_UPDATE(P_RULE_ISN => :P1140_RULE_ISN, P_HQ_IMPR_NBR => :P1140_HQ_IMPR_NBR, P_RULE_TYPE => :P1140_RULE_TYPE, P_REC_STATUS => :P1140_REC_STATUS, P_CURR_PORT_CD => :P_CURR_PORT_CD, SSO_APP_USER => :SSO_APP_USER, P_GLOBAL_V_WS_ID => :P_GLOBAL_V_WS_ID);` | `:P0_PAGE_PK IS NOT NULL AND :REQUEST = 'SAVE'` | IMPR_RULES.POST-UPDATE |
| | 80 | `P0_PAGE_PK AFTER INSERT` | PL/SQL | `:P0_PAGE_PK := :P1140_ROW_ID;` | request CREATE | f345 |
| | 85 | `P0_PAGE_PK AFTER DELETE` | PL/SQL | `:P0_PAGE_PK := NULL;` | request DELETE | f345 |
| | 110 | `IMPR_RULE_PORTS - Save Interactive Grid Data` | IG DML, PL/SQL Code | `IMPR1140.IMPR_RULE_PORTS_SAVE_ROW(APEX$ROW_STATUS => :APEX$ROW_STATUS, ROW_ID => :ROW_ID, RULE_ISN => NVL(:RULE_ISN, :P1140_RULE_ISN), PORT_CD => :PORT_CD, REC_STATUS => :REC_STATUS, P_ALL_BRNCH_FLAG => :P1140_ALL_BRNCH_FLAG, P_CURR_PORT_CD => :P_CURR_PORT_CD, SSO_APP_USER => :SSO_APP_USER, P_GLOBAL_V_WS_ID => :P_GLOBAL_V_WS_ID);` | request SAVE | IMPR_RULE_PORTS PRE-INSERT / PRE-UPDATE / PRE-DELETE + DML |
| | 210 | `IMPR_RULE_TARIFF - Save Interactive Grid Data` | IG DML, PL/SQL Code | `IMPR1140.IMPR_RULE_TARIFF_SAVE_ROW(APEX$ROW_STATUS => :APEX$ROW_STATUS, ROW_ID => :ROW_ID, RULE_ISN => NVL(:RULE_ISN, :P1140_RULE_ISN), HRMNZD_CODE => :HRMNZD_CODE, EXEPTION_QTY => :EXEPTION_QTY, REMAINED_QTY => :REMAINED_QTY, REC_STATUS => :REC_STATUS, ITEM_SEQUENCE => :ITEM_SEQUENCE, P_CURR_PORT_CD => :P_CURR_PORT_CD, SSO_APP_USER => :SSO_APP_USER, P_GLOBAL_V_WS_ID => :P_GLOBAL_V_WS_ID);` | request SAVE | IMPR_RULE_TARIFF PRE-INSERT / PRE-UPDATE + DML |

Success message of `Process form` / grid DML: "تم الحفظ بنجاح". Every process: error display *inline in notification*, comment `Source: IMPR1140.<…>`. Order follows standard §6 (master 5–85, ports 1xx, tariff 2xx); the Forms order "master first, then details" is kept.

### Page 114001

No process (the grid reads the search text through Items to Submit).

## 9. Computations

None. Defaults are item / column defaults (§4); derived values come from FOS (§10) and `POST-QUERY` (§8).

## 10. Dynamic Actions

| Seq | DA | Event | Element | Condition | True actions | False actions | Submit / Return | Init | Source |
|---|---|---|---|---|---|---|---|---|---|
| 10 | `RULE_TYPE WHEN-LIST-CHANGED` | Change | `P1140_RULE_TYPE` | — | FOS `FORMS_APX.CHECK_ERROR(IMPR1140.RULE_TYPE_VALIDATION(P_RULE_TYPE => :P1140_RULE_TYPE));` | — | `P1140_RULE_TYPE` | N | RULE_TYPE WLC |
| 20 | `ALL_BRNCH_FLAG WHEN-VALIDATE-ITEM` | Change | `P1140_ALL_BRNCH_FLAG` | value = 1 | Clear `P1140_BUS_ID_BRNCH`, Disable `P1140_BUS_ID_BRNCH` | Enable `P1140_BUS_ID_BRNCH` | — | **Y** (= IMPR_RULES.WHEN-NEW-RECORD-INSTANCE) | ALL_BRNCH_FLAG WVI, ADJ_BRANCH |
| 30 | `HQ_IMPR_NBR WHEN-VALIDATE-ITEM` | Change | `P1140_HQ_IMPR_NBR` | not null | FOS `IMPR1140.HQ_IMPR_NBR_VALIDATE_ITEM(P_HQ_IMPR_NBR => :P1140_HQ_IMPR_NBR, P_RULE_TYPE => :P1140_RULE_TYPE, P_CURR_PORT_CD => :P_CURR_PORT_CD, P_BUS_ID => :P1140_BUS_ID, P_BUS_ID_BRNCH => :P1140_BUS_ID_BRNCH, P_BUS_ID_TYPE_CD => :P1140_BUS_ID_TYPE_CD, P_L_SI_ARBC_IMPR_NAME => :P1140_L_SI_ARBC_IMPR_NAME, P_BUS_ID_TYPE_NAME => :P1140_BUS_ID_TYPE_NAME);` | — | submit `P1140_HQ_IMPR_NBR, P1140_RULE_TYPE`; return `P1140_BUS_ID, P1140_BUS_ID_BRNCH, P1140_BUS_ID_TYPE_CD, P1140_L_SI_ARBC_IMPR_NAME, P1140_BUS_ID_TYPE_NAME` | N | HQ_IMPR_NBR WVI |
| 110 | `IMPR_RULE_PORTS PORT_CD WHEN-VALIDATE-ITEM` | Change | column `PORT_CD` of `IMPR_RULE_PORTS` | — | FOS `IMPR1140.PORT_CD_WHEN_VALIDATE_ITEM(PORT_CD => :PORT_CD, PORT_NAME => :PORT_NAME);` | — | submit `PORT_CD`; return `PORT_NAME` | N | PORT_CD WVI |
| 210 | `IMPR_RULE_TARIFF HRMNZD_CODE WHEN-VALIDATE-ITEM` | Change | column `HRMNZD_CODE` of `IMPR_RULE_TARIFF` | — | FOS `IMPR1140.HRMNZD_CODE_VALIDATE_ITEM(HRMNZD_CODE => :HRMNZD_CODE, P_RULE_ISN => :P1140_RULE_ISN, P_HQ_IMPR_NBR => :P1140_HQ_IMPR_NBR, P_BUS_ID_TYPE_CD => :P1140_BUS_ID_TYPE_CD, P_BUS_ID => :P1140_BUS_ID, HT_ITEM_ARBC_DESC => :HT_ITEM_ARBC_DESC, INTL_UNIT => :INTL_UNIT);` | — | submit `HRMNZD_CODE, P1140_RULE_ISN, P1140_HQ_IMPR_NBR, P1140_BUS_ID_TYPE_CD, P1140_BUS_ID`; return `HT_ITEM_ARBC_DESC, INTL_UNIT` | N | HRMNZD_CODE WVI + POST-CHANGE |
| 220 | `IMPR_RULE_TARIFF EXEPTION_QTY WHEN-VALIDATE-ITEM` | Change | column `EXEPTION_QTY` of `IMPR_RULE_TARIFF` | — | FOS `IMPR1140.EXEPTION_QTY_VALIDATE_ITEM(EXEPTION_QTY => :EXEPTION_QTY, REMAINED_QTY => :REMAINED_QTY);`; native Alert " تأكد من تطابق الوحده الدولية مع وحدة الكمية المستثناه " | — | submit `EXEPTION_QTY`; return `REMAINED_QTY` | N | EXEPTION_QTY WVI |

Page 114001: `SEARCH WHEN-BUTTON-PRESSED` (Refresh grid), `SEARCH KEY-ENTER` (keyup, Enter → Refresh), `CLEAR WHEN-BUTTON-PRESSED` (Clear + Refresh), `Hide` (page load: hide page 0 toolbar `P0_ACTIONS`, as AGR1100_SEARCH) — the IMPR1120 pattern.

**Execute JavaScript Code actions: 0.** The page 0 DA `NUMBER ONLY` handles the `number_only` class.

Note on DA 20: a NULL flag enables the branch in APEX while Forms disabled it (`NULL <> 1` is not true); the flag has default 0 and the server clears the branch for NULL in `ADJ_BRANCH`, so only the screen differs.

## 11. Alerts and messages

| Forms alert / text | Usage | APEX equivalent |
|---|---|---|
| CFG_ERROR via `STR.DispAlert(…,'ERROR')` + FTF | validations / DML checks | error text of `<ITEM> VALIDATION` / `FORMS_APX.FORM_TRIGGER_FAILURE` (texts in the extraction report §4) |
| CFG_INFORMATION `' تأكد من تطابق الوحده الدولية …'` | EXEPTION_QTY WVI | native Alert in DA 220 |
| `STR.DispAlert('رقم المستورد المدخل غير صحيح','ERROR')` without FTF | POST-QUERY | `FORMS_APX.MESSAGE` (page success message area) |
| `' الوحدة الدولية غير معرفة …'` without FTF | HRMNZD_CODE WVI | not shown (inventory §15 #7) |
| USR_WARNING (delete confirm, `TMPLT.KEY_DELETE_RECORD`) | KEY-DELREC | page 0 DELETE confirm |
| `STR.DispArbMsg(1, 270)` | KEY-DELREC | `FORMS_APX.ARABIC_MESSAGE(1, 270)` |
| other OLB alerts (USR_CONFIRM, USR_CONFIRM_B, USR_WARNING_B / C, CFG_WARNING_A, CFG_SYSTEM_ERROR, CFG_ASK_COMMIT), CG$ASK_COMMIT | not used by business code | dropped (APEX warn-on-unsaved-changes) |

Text Messages (constraint texts of the three ON-ERROR triggers, used by `APP_ERROR_HANDLER` by constraint name, as IMPR1120 `IS_1_IMP_FK`):

| Name | Text | Source |
|---|---|---|
| `IR_BIT_FK` | This Bus Id Type Name does not exist | IMPR_RULES.ON-ERROR |
| `IRP_IR2_FK` | Cannot delete استثناءات المستوردين while dependent جمارك الاستثناء exists | IMPR_RULES.ON-ERROR (40510; the child-side text "This Rule Isn does not exist" cannot occur: details are added to a saved rule only) |
| `IRP_SDP_FK` | This رمز الجمرك does not exist | IMPR_RULE_PORTS.ON-ERROR |
| `IRT_IR_FK` | This رقم مسلسل الإستثناء does not exist | IMPR_RULE_TARIFF.ON-ERROR |
| `IRT_HT_FK` | This رمز بند التعريفة does not exist | IMPR_RULE_TARIFF.ON-ERROR |

The FRM-40508 / 40509 / 40510 texts ("ليس لديك صلاحية الادخال / التعديل / الحذف") are Forms insert / update / delete errors without a DB equivalent: dropped.

## 12. Branches and navigation

| Branch | Point | Target | Condition | Source |
|---|---|---|---|---|
| `IMPR1140 - stay in the form` | After Processing, seq 20 | `f?p=&APP_ID.:1140:&SESSION.::&DEBUG.:::&success_msg=#SUCCESS_MSG#` | — | Forms stays in the form after COMMIT; `P0_PAGE_PK` keeps the record (or is null after DELETE) |
| search link | grid link | `f?p=&APP_ID.:1140:&SESSION.::&DEBUG.:1140:P0_PAGE_PK:&ROW_ID.` | — | Execute Query |

LOV forms (CALL_FORM) → Popup LOVs; no modal child page.

## 13. Shared components

### 13.1 Reused from f345 (do not create)

Theme 42 templates (IDs in §1–§5), page 0 toolbar `P0_ACTIONS` / `P0_PAGE_PK` / FUNCS drawer / DA `NUMBER ONLY`, application items `P_CURR_PORT_CD`, `SSO_APP_USER`, `P_GLOBAL_V_WS_ID`, `P_PORT_TYPE`, plug-in `COM.FOS.EXECUTE_PLSQL_CODE`, app process `SCREEN ENTRY RESET`, `APP_ERROR_HANDLER`.

### 13.2 Reused from the IMPR1110 export (already in application 202530)

Page group `IMPR` (`900001000010`), LOV `LOV_SD_PORTS`.

### 13.3 New

| Component | Name |
|---|---|
| LOVs | `LOV_RULE_TYPE`, `LOV_REC_STATUS`, `LOV_ALL_BRNCH_FLAG` (static), `LOV_SINGLE_IMPORTERS`, `LOV_HARMONIZED_TARIFF` |
| Text Messages | `IR_BIT_FK`, `IRP_IR2_FK`, `IRP_SDP_FK`, `IRT_IR_FK`, `IRT_HT_FK` |
| DB | package `IMPR1140` 001; `LOV_APX` 002 (`SINGLE_IMPORTERS`, `HARMONIZED_TARIFF`) |
| Application items | none |

## 14. Traceability matrix (every object of the XML)

Generated by `work/IMPR1140/step03/build_trace.py`: **558 objects** — DROPPED 369, MAPPED 187, TODO 2.

| # | Forms object type | Forms object | APEX component type | APEX component (f345 name) | Page | Package member | Status | Notes |
|---|---|---|---|---|---|---|---|---|
| 1 | BLOCK | TITLE | REGION | IMPR_RULES_HERO | 1140 | – | MAPPED | OLB title bar -> hero region (HEADER TITLE) |
| 2 | BLOCK | EDI_MSG | – | – | – | – | DROPPED | OLB EDI ticker - dropped (timers, IMPR1110 decision 2026-11-19) |
| 3 | BLOCK | LSIDE | REGION | FUNCS (page 0 side drawer) | 0 | – | MAPPED | OLB side function menu -> page 0 FUNCS, list Page Functions |
| 4 | BLOCK | TOOLBAR | REGION | P0_ACTIONS (page 0 toolbar, f345) | 0 | – | MAPPED | OLB toolbar -> f345 page 0 toolbar |
| 5 | BLOCK | IMPR_RULES | REGION | IMPR_RULES (Form region on IMPR_RULES, key ROWID) | 1140 | – | MAPPED | master; search page 114001 = Enter / Execute Query |
| 6 | BLOCK | IMPR_RULE_PORTS | REGION | IMPR_RULE_PORTS (editable IG in tab CG$M_TAB_1) | 1140 | IMPR1140.IMPR_RULE_PORTS_SAVE_ROW | MAPPED | detail; WHERE PORT_CD = :P_CURR_PORT_CD; PL/SQL row DML |
| 7 | BLOCK | IMPR_RULE_TARIFF | REGION | IMPR_RULE_TARIFF (editable IG i:u in tab CG$M_TAB_1) | 1140 | IMPR1140.IMPR_RULE_TARIFF_SAVE_ROW | MAPPED | detail; Delete Allowed = false; PL/SQL row DML |
| 8 | BLOCK | CG$CTRL | – | – | – | – | DROPPED | Designer control block (tab bookkeeping) |
| 9 | ITEM | TITLE.CGSO$CHECK_BOX_U | – | – | – | – | DROPPED | frame item (TITLE) |
| 10 | ITEM | TITLE.CGSO$CHAR_ARB_ED | – | – | – | – | DROPPED | frame item (TITLE) |
| 11 | ITEM | TITLE.CGSO$CHAR_ARB_DO_MLINE | – | – | – | – | DROPPED | frame item (TITLE) |
| 12 | ITEM | TITLE.CGSO$CHAR_ARB_ORA_LOV | – | – | – | – | DROPPED | frame item (TITLE) |
| 13 | ITEM | TITLE.CGSO$CHAR_ARB_DO_ENB_Y | – | – | – | – | DROPPED | frame item (TITLE) |
| 14 | ITEM | TITLE.CGSO$CHAR_ARB_MLINE | – | – | – | – | DROPPED | frame item (TITLE) |
| 15 | ITEM | TITLE.CGSO$CHAR_ARB | – | – | – | – | DROPPED | frame item (TITLE) |
| 16 | ITEM | TITLE.CGSO$CHAR_ARB_DO | – | – | – | – | DROPPED | frame item (TITLE) |
| 17 | ITEM | TITLE.SCREEN_NAME | – | – | – | – | DROPPED | frame item (TITLE) |
| 18 | ITEM | TITLE.USER_NAME | – | – | – | – | DROPPED | frame item (TITLE) |
| 19 | ITEM | TITLE.SYSTEM_DATE | – | – | – | – | DROPPED | frame item (TITLE) |
| 20 | ITEM | TITLE.VERSION | – | – | – | – | DROPPED | frame item (TITLE) |
| 21 | ITEM | EDI_MSG.EDI_MSG_TXT | – | – | – | – | DROPPED | frame item (EDI_MSG) |
| 22 | ITEM | EDI_MSG.EDI_MSG_LOVE_BUT | – | – | – | – | DROPPED | frame item (EDI_MSG) |
| 23 | ITEM | LSIDE.FN1 | – | – | – | – | DROPPED | frame item (LSIDE) |
| 24 | ITEM | LSIDE.FN50 | – | – | – | – | DROPPED | frame item (LSIDE) |
| 25 | ITEM | LSIDE.FN2 | – | – | – | – | DROPPED | frame item (LSIDE) |
| 26 | ITEM | LSIDE.FN49 | – | – | – | – | DROPPED | frame item (LSIDE) |
| 27 | ITEM | LSIDE.FN3 | – | – | – | – | DROPPED | frame item (LSIDE) |
| 28 | ITEM | LSIDE.FN48 | – | – | – | – | DROPPED | frame item (LSIDE) |
| 29 | ITEM | LSIDE.FN4 | – | – | – | – | DROPPED | frame item (LSIDE) |
| 30 | ITEM | LSIDE.FN47 | – | – | – | – | DROPPED | frame item (LSIDE) |
| 31 | ITEM | LSIDE.FN5 | – | – | – | – | DROPPED | frame item (LSIDE) |
| 32 | ITEM | LSIDE.FN46 | – | – | – | – | DROPPED | frame item (LSIDE) |
| 33 | ITEM | LSIDE.FN6 | – | – | – | – | DROPPED | frame item (LSIDE) |
| 34 | ITEM | LSIDE.FN45 | – | – | – | – | DROPPED | frame item (LSIDE) |
| 35 | ITEM | LSIDE.FN7 | – | – | – | – | DROPPED | frame item (LSIDE) |
| 36 | ITEM | LSIDE.FN44 | – | – | – | – | DROPPED | frame item (LSIDE) |
| 37 | ITEM | LSIDE.FN8 | – | – | – | – | DROPPED | frame item (LSIDE) |
| 38 | ITEM | LSIDE.FN43 | – | – | – | – | DROPPED | frame item (LSIDE) |
| 39 | ITEM | LSIDE.FN9 | – | – | – | – | DROPPED | frame item (LSIDE) |
| 40 | ITEM | LSIDE.FN42 | – | – | – | – | DROPPED | frame item (LSIDE) |
| 41 | ITEM | LSIDE.FN10 | – | – | – | – | DROPPED | frame item (LSIDE) |
| 42 | ITEM | LSIDE.FN41 | – | – | – | – | DROPPED | frame item (LSIDE) |
| 43 | ITEM | LSIDE.FN11 | – | – | – | – | DROPPED | frame item (LSIDE) |
| 44 | ITEM | LSIDE.FN40 | – | – | – | – | DROPPED | frame item (LSIDE) |
| 45 | ITEM | LSIDE.FN12 | – | – | – | – | DROPPED | frame item (LSIDE) |
| 46 | ITEM | LSIDE.FN39 | – | – | – | – | DROPPED | frame item (LSIDE) |
| 47 | ITEM | LSIDE.FN13 | – | – | – | – | DROPPED | frame item (LSIDE) |
| 48 | ITEM | LSIDE.FN38 | – | – | – | – | DROPPED | frame item (LSIDE) |
| 49 | ITEM | LSIDE.FN14 | – | – | – | – | DROPPED | frame item (LSIDE) |
| 50 | ITEM | LSIDE.FN37 | – | – | – | – | DROPPED | frame item (LSIDE) |
| 51 | ITEM | LSIDE.FN15 | – | – | – | – | DROPPED | frame item (LSIDE) |
| 52 | ITEM | LSIDE.FN36 | – | – | – | – | DROPPED | frame item (LSIDE) |
| 53 | ITEM | LSIDE.FN16 | – | – | – | – | DROPPED | frame item (LSIDE) |
| 54 | ITEM | LSIDE.FN17 | – | – | – | – | DROPPED | frame item (LSIDE) |
| 55 | ITEM | LSIDE.FN34 | – | – | – | – | DROPPED | frame item (LSIDE) |
| 56 | ITEM | LSIDE.FN35 | – | – | – | – | DROPPED | frame item (LSIDE) |
| 57 | ITEM | LSIDE.FN18 | – | – | – | – | DROPPED | frame item (LSIDE) |
| 58 | ITEM | LSIDE.FN33 | – | – | – | – | DROPPED | frame item (LSIDE) |
| 59 | ITEM | LSIDE.FN19 | – | – | – | – | DROPPED | frame item (LSIDE) |
| 60 | ITEM | LSIDE.FN32 | – | – | – | – | DROPPED | frame item (LSIDE) |
| 61 | ITEM | LSIDE.FN20 | – | – | – | – | DROPPED | frame item (LSIDE) |
| 62 | ITEM | LSIDE.FN31 | – | – | – | – | DROPPED | frame item (LSIDE) |
| 63 | ITEM | LSIDE.FN21 | – | – | – | – | DROPPED | frame item (LSIDE) |
| 64 | ITEM | LSIDE.FN30 | – | – | – | – | DROPPED | frame item (LSIDE) |
| 65 | ITEM | LSIDE.FN22 | – | – | – | – | DROPPED | frame item (LSIDE) |
| 66 | ITEM | LSIDE.FN29 | – | – | – | – | DROPPED | frame item (LSIDE) |
| 67 | ITEM | LSIDE.FN23 | – | – | – | – | DROPPED | frame item (LSIDE) |
| 68 | ITEM | LSIDE.FN28 | – | – | – | – | DROPPED | frame item (LSIDE) |
| 69 | ITEM | LSIDE.FN24 | – | – | – | – | DROPPED | frame item (LSIDE) |
| 70 | ITEM | LSIDE.FN27 | – | – | – | – | DROPPED | frame item (LSIDE) |
| 71 | ITEM | LSIDE.FN25 | – | – | – | – | DROPPED | frame item (LSIDE) |
| 72 | ITEM | LSIDE.FN26 | – | – | – | – | DROPPED | frame item (LSIDE) |
| 73 | ITEM | TOOLBAR.DUMMY | – | – | – | – | DROPPED | OLB toolbar navigation button (record / page scrolling: IG) |
| 74 | ITEM | TOOLBAR.SAVE | BUTTON | SAVE / CREATE (page 0 toolbar) | 0 | – | MAPPED | OLB toolbar button |
| 75 | ITEM | TOOLBAR.CLEAR_ALL | BUTTON | CLEAR (page 0 toolbar) | 0 | – | MAPPED | OLB toolbar button |
| 76 | ITEM | TOOLBAR.EXIT | BUTTON | BACK (page 0 toolbar) | 0 | – | MAPPED | OLB toolbar button |
| 77 | ITEM | TOOLBAR.EXIT1 | BUTTON | BACK (page 0 toolbar) | 0 | – | MAPPED | OLB toolbar button |
| 78 | ITEM | TOOLBAR.ENTER | – | – | – | – | DROPPED | OLB toolbar navigation button (record / page scrolling: IG) |
| 79 | ITEM | TOOLBAR.EXECUTE | BUTTON | SEARCH (page 114001) (page 0 toolbar) | 0 | – | MAPPED | OLB toolbar button |
| 80 | ITEM | TOOLBAR.REMOVE | BUTTON | DELETE (+ IG row delete) (page 0 toolbar) | 0 | – | MAPPED | OLB toolbar button |
| 81 | ITEM | TOOLBAR.LIST_VALUE | – | – | – | – | DROPPED | OLB toolbar navigation button (record / page scrolling: IG) |
| 82 | ITEM | TOOLBAR.HELP | – | – | – | – | DROPPED | OLB toolbar navigation button (record / page scrolling: IG) |
| 83 | ITEM | TOOLBAR.LAST_REC | – | – | – | – | DROPPED | OLB toolbar navigation button (record / page scrolling: IG) |
| 84 | ITEM | TOOLBAR.RE_ENTER_QUERY | BUTTON | SEARCH (page 0 toolbar) | 0 | – | MAPPED | OLB toolbar button |
| 85 | ITEM | TOOLBAR.FIRST_REC | – | – | – | – | DROPPED | OLB toolbar navigation button (record / page scrolling: IG) |
| 86 | ITEM | TOOLBAR.PAGE_UP | – | – | – | – | DROPPED | OLB toolbar navigation button (record / page scrolling: IG) |
| 87 | ITEM | TOOLBAR.PAGE_DOWN | – | – | – | – | DROPPED | OLB toolbar navigation button (record / page scrolling: IG) |
| 88 | ITEM | TOOLBAR.FUN_BUT | BUTTON | FUNCS (page 0 toolbar) | 0 | – | MAPPED | OLB toolbar button |
| 89 | ITEM | IMPR_RULES.RULE_ISN | PAGE ITEM | P1140_RULE_ISN | 1140 | – | MAPPED | spec 4.1 |
| 90 | ITEM | IMPR_RULES.D | – | – | – | – | DROPPED | non-database item made invisible in PRE-FORM |
| 91 | ITEM | IMPR_RULES.RULE_TYPE | PAGE ITEM | P1140_RULE_TYPE | 1140 | – | MAPPED | spec 4.1 |
| 92 | ITEM | IMPR_RULES.ALL_BRNCH_FLAG | PAGE ITEM | P1140_ALL_BRNCH_FLAG | 1140 | – | MAPPED | spec 4.1 |
| 93 | ITEM | IMPR_RULES.HQ_IMPR_NBR | PAGE ITEM | P1140_HQ_IMPR_NBR | 1140 | – | MAPPED | spec 4.1 |
| 94 | ITEM | IMPR_RULES.B_IMP | PAGE ITEM | P1140_HQ_IMPR_NBR (Popup LOV icon) | 1140 | – | MAPPED | LOV button |
| 95 | ITEM | IMPR_RULES.L_SI_ARBC_IMPR_NAME | PAGE ITEM | P1140_L_SI_ARBC_IMPR_NAME | 1140 | – | MAPPED | spec 4.1 |
| 96 | ITEM | IMPR_RULES.REC_STATUS | PAGE ITEM | P1140_REC_STATUS | 1140 | – | MAPPED | spec 4.1 |
| 97 | ITEM | IMPR_RULES.BUS_ID_TYPE_CD | PAGE ITEM | P1140_BUS_ID_TYPE_CD | 1140 | – | MAPPED | spec 4.1 |
| 98 | ITEM | IMPR_RULES.BUS_ID_TYPE_NAME | PAGE ITEM | P1140_BUS_ID_TYPE_NAME | 1140 | – | MAPPED | spec 4.1 |
| 99 | ITEM | IMPR_RULES.BUS_ID | PAGE ITEM | P1140_BUS_ID | 1140 | – | MAPPED | spec 4.1 |
| 100 | ITEM | IMPR_RULES.BUS_ID_BRNCH | PAGE ITEM | P1140_BUS_ID_BRNCH | 1140 | – | MAPPED | spec 4.1 |
| 101 | ITEM | IMPR_RULE_PORTS.RULE_ISN | IG COLUMN | IMPR_RULE_PORTS.RULE_ISN | 1140 | – | MAPPED | spec 4.3 |
| 102 | ITEM | IMPR_RULE_PORTS.PORT_CD | IG COLUMN | IMPR_RULE_PORTS.PORT_CD | 1140 | – | MAPPED | spec 4.3 |
| 103 | ITEM | IMPR_RULE_PORTS.PORT_CD2 | IG COLUMN | IMPR_RULE_PORTS.PORT_CD (Popup LOV icon) | 1140 | – | MAPPED | LOV button |
| 104 | ITEM | IMPR_RULE_PORTS.PORT_NAME | IG COLUMN | IMPR_RULE_PORTS.PORT_NAME | 1140 | – | MAPPED | spec 4.3 |
| 105 | ITEM | IMPR_RULE_PORTS.REC_STATUS | IG COLUMN | IMPR_RULE_PORTS.REC_STATUS | 1140 | – | MAPPED | spec 4.3 |
| 106 | ITEM | IMPR_RULE_TARIFF.RULE_ISN | IG COLUMN | IMPR_RULE_TARIFF.RULE_ISN | 1140 | – | MAPPED | spec 4.3 |
| 107 | ITEM | IMPR_RULE_TARIFF.HRMNZD_CODE | IG COLUMN | IMPR_RULE_TARIFF.HRMNZD_CODE | 1140 | – | MAPPED | spec 4.3 |
| 108 | ITEM | IMPR_RULE_TARIFF.HRMNZD_CODE2 | IG COLUMN | IMPR_RULE_TARIFF.HRMNZD_CODE (Popup LOV icon) | 1140 | – | MAPPED | LOV button |
| 109 | ITEM | IMPR_RULE_TARIFF.HT_ITEM_ARBC_DESC | IG COLUMN | IMPR_RULE_TARIFF.HT_ITEM_ARBC_DESC | 1140 | – | MAPPED | spec 4.3 |
| 110 | ITEM | IMPR_RULE_TARIFF.EXEPTION_QTY | IG COLUMN | IMPR_RULE_TARIFF.EXEPTION_QTY | 1140 | – | MAPPED | spec 4.3 (column EXCEPTED_QTY) |
| 111 | ITEM | IMPR_RULE_TARIFF.REMAINED_QTY | IG COLUMN | IMPR_RULE_TARIFF.REMAINED_QTY | 1140 | – | MAPPED | spec 4.3 |
| 112 | ITEM | IMPR_RULE_TARIFF.INTL_UNIT | IG COLUMN | IMPR_RULE_TARIFF.INTL_UNIT | 1140 | – | MAPPED | spec 4.3 |
| 113 | ITEM | IMPR_RULE_TARIFF.REC_STATUS | IG COLUMN | IMPR_RULE_TARIFF.REC_STATUS | 1140 | – | MAPPED | spec 4.3 |
| 114 | ITEM | IMPR_RULE_TARIFF.ITEM_SEQUENCE | IG COLUMN | IMPR_RULE_TARIFF.ITEM_SEQUENCE | 1140 | – | MAPPED | spec 4.3 |
| 115 | ITEM | CG$CTRL.CG$PAGE_1_LIST | – | – | – | – | DROPPED | frame item (CG$CTRL) |
| 116 | ITEM | CG$CTRL.CG$WINDOWCGSO$WINDOW_1_PAGE | – | – | – | – | DROPPED | frame item (CG$CTRL) |
| 117 | ITEM | CG$CTRL.CG$LAST_CANVAS | – | – | – | – | DROPPED | frame item (CG$CTRL) |
| 118 | RELATION | CGFK$IRP_IR2_FK | IG SQL | IMPR_RULE_PORTS WHERE rule_isn = :P1140_RULE_ISN | 1140 | – | MAPPED | master-detail on RULE_ISN; details shown when P0_PAGE_PK is not null |
| 119 | RELATION | CGFK$IRT_IR_FK | IG SQL | IMPR_RULE_TARIFF WHERE rule_isn = :P1140_RULE_ISN | 1140 | – | MAPPED | master-detail on RULE_ISN; details shown when P0_PAGE_PK is not null |
| 120 | TRIGGER | FORM.KEY-EDIT | – | – | – | – | DROPPED | Designer coordination / keyboard -> native APEX |
| 121 | TRIGGER | FORM.KEY-DUPREC | – | – | – | – | DROPPED | Designer coordination / keyboard -> native APEX |
| 122 | TRIGGER | FORM.PRE-FORM | – | – | – | – | DROPPED | NIB.PRE_FORM / version stamps / hide D / date format -> f345 shell |
| 123 | TRIGGER | FORM.WHEN-NEW-FORM-INSTANCE | – | – | – | – | DROPPED | NIB + Designer start-up -> f345 shell, shared LOVs, native master-detail |
| 124 | TRIGGER | FORM.WHEN-WINDOW-ACTIVATED | – | – | – | – | DROPPED | timers / window / mouse (IMPR1110 decision) |
| 125 | TRIGGER | FORM.KEY-ENTQRY | BUTTON | SEARCH (page 0 toolbar) | 0 | – | MAPPED | NIB key delegation |
| 126 | TRIGGER | FORM.ON-ERROR | APPLICATION | APP_ERROR_HANDLER + Text Messages | 0 | – | MAPPED | f345 error handling |
| 127 | TRIGGER | FORM.ON-MESSAGE | APPLICATION | APP_ERROR_HANDLER + Text Messages | 0 | – | MAPPED | f345 error handling |
| 128 | TRIGGER | FORM.KEY-CLRBLK | BUTTON | CLEAR (page 0 toolbar) | 0 | – | MAPPED | NIB key delegation |
| 129 | TRIGGER | FORM.KEY-DELREC | BUTTON | DELETE (page 0 toolbar) | 0 | – | MAPPED | NIB key delegation |
| 130 | TRIGGER | FORM.KEY-F5 | – | – | – | – | DROPPED | Designer coordination / keyboard -> native APEX |
| 131 | TRIGGER | FORM.KEY-F4 | – | – | – | – | DROPPED | frame / OLB trigger |
| 132 | TRIGGER | FORM.KEY-NXTREC | – | – | – | – | DROPPED | Designer coordination / keyboard -> native APEX |
| 133 | TRIGGER | FORM.KEY-PRVREC | – | – | – | – | DROPPED | Designer coordination / keyboard -> native APEX |
| 134 | TRIGGER | FORM.KEY-DOWN | – | – | – | – | DROPPED | Designer coordination / keyboard -> native APEX |
| 135 | TRIGGER | FORM.KEY-UP | – | – | – | – | DROPPED | Designer coordination / keyboard -> native APEX |
| 136 | TRIGGER | FORM.KEY-SCRUP | – | – | – | – | DROPPED | Designer coordination / keyboard -> native APEX |
| 137 | TRIGGER | FORM.KEY-SCRDOWN | – | – | – | – | DROPPED | Designer coordination / keyboard -> native APEX |
| 138 | TRIGGER | FORM.KEY-PRINT | BUTTON | FUNCS (page 0 toolbar) | 0 | – | MAPPED | NIB key delegation |
| 139 | TRIGGER | FORM.KEY-EXIT | BUTTON | BACK (page 0 toolbar) | 0 | – | MAPPED | NIB key delegation |
| 140 | TRIGGER | FORM.WHEN-MOUSE-DOWN | – | – | – | – | DROPPED | timers / window / mouse (IMPR1110 decision) |
| 141 | TRIGGER | FORM.KEY-EXEQRY | BUTTON | SEARCH (page 0 toolbar) | 0 | – | MAPPED | NIB key delegation |
| 142 | TRIGGER | FORM.KEY-F9 | BUTTON | FUNCS (page 0 toolbar) | 0 | – | MAPPED | NIB key delegation |
| 143 | TRIGGER | FORM.WHEN-TIMER-EXPIRED | – | – | – | – | DROPPED | timers / window / mouse (IMPR1110 decision) |
| 144 | TRIGGER | FORM.KEY-HELP | – | – | – | – | DROPPED | MS-Help (obsolete) |
| 145 | TRIGGER | FORM.WHEN-NEW-BLOCK-INSTANCE | – | – | – | – | DROPPED | Designer coordination / keyboard -> native APEX |
| 146 | TRIGGER | FORM.ON-CLEAR-DETAILS | – | – | – | – | DROPPED | Designer coordination / keyboard -> native APEX |
| 147 | TRIGGER | FORM.ON-POPULATE-DETAILS | – | – | – | – | DROPPED | Designer coordination / keyboard -> native APEX |
| 148 | TRIGGER | FORM.KEY-CQUERY | – | – | – | – | DROPPED | Designer coordination / keyboard -> native APEX |
| 149 | TRIGGER | FORM.KEY-CLRREC | BUTTON | CLEAR (page 0 toolbar) | 0 | – | MAPPED | NIB key delegation |
| 150 | TRIGGER | FORM.KEY-NXTKEY | – | – | – | – | DROPPED | Designer coordination / keyboard -> native APEX |
| 151 | TRIGGER | FORM.KEY-MENU | – | – | – | – | DROPPED | Designer coordination / keyboard -> native APEX |
| 152 | TRIGGER | FORM.KEY-CLRFRM | BUTTON | CLEAR (page 0 toolbar) | 0 | – | MAPPED | NIB key delegation |
| 153 | TRIGGER | FORM.WHEN-TAB-PAGE-CHANGED | REGION | CG$M_TAB_1 (Tabs Container) | 1140 | – | MAPPED | native tabs |
| 154 | TRIGGER | TITLE.CGSO$CHAR_ARB_ED.KEY-LISTVAL | – | – | – | – | DROPPED | frame / OLB trigger |
| 155 | TRIGGER | TITLE.CGSO$CHAR_ARB_DO_ENB_Y.KEY-LISTVAL | – | – | – | – | DROPPED | frame / OLB trigger |
| 156 | TRIGGER | TITLE.CGSO$CHAR_ARB_MLINE.KEY-LISTVAL | – | – | – | – | DROPPED | frame / OLB trigger |
| 157 | TRIGGER | TITLE.CGSO$CHAR_ARB.KEY-LISTVAL | – | – | – | – | DROPPED | frame / OLB trigger |
| 158 | TRIGGER | TITLE.CGSO$CHAR_ARB_DO.KEY-LISTVAL | – | – | – | – | DROPPED | frame / OLB trigger |
| 159 | TRIGGER | TITLE.SYSTEM_DATE.WHEN-VALIDATE-ITEM | – | – | – | – | DROPPED | frame / OLB trigger |
| 160 | TRIGGER | EDI_MSG.EDI_MSG_LOVE_BUT.WHEN-BUTTON-PRESSED | – | – | – | – | DROPPED | frame / OLB trigger |
| 161 | TRIGGER | LSIDE.FN1.WHEN-MOUSE-ENTER | – | – | – | – | DROPPED | frame / OLB trigger |
| 162 | TRIGGER | LSIDE.FN1.WHEN-MOUSE-LEAVE | – | – | – | – | DROPPED | frame / OLB trigger |
| 163 | TRIGGER | LSIDE.FN1.WHEN-MOUSE-CLICK | – | – | – | – | DROPPED | frame / OLB trigger |
| 164 | TRIGGER | LSIDE.FN50.WHEN-MOUSE-ENTER | – | – | – | – | DROPPED | frame / OLB trigger |
| 165 | TRIGGER | LSIDE.FN50.WHEN-MOUSE-LEAVE | – | – | – | – | DROPPED | frame / OLB trigger |
| 166 | TRIGGER | LSIDE.FN50.WHEN-MOUSE-CLICK | – | – | – | – | DROPPED | frame / OLB trigger |
| 167 | TRIGGER | LSIDE.FN2.WHEN-MOUSE-ENTER | – | – | – | – | DROPPED | frame / OLB trigger |
| 168 | TRIGGER | LSIDE.FN2.WHEN-MOUSE-LEAVE | – | – | – | – | DROPPED | frame / OLB trigger |
| 169 | TRIGGER | LSIDE.FN2.WHEN-MOUSE-CLICK | – | – | – | – | DROPPED | frame / OLB trigger |
| 170 | TRIGGER | LSIDE.FN49.WHEN-MOUSE-ENTER | – | – | – | – | DROPPED | frame / OLB trigger |
| 171 | TRIGGER | LSIDE.FN49.WHEN-MOUSE-LEAVE | – | – | – | – | DROPPED | frame / OLB trigger |
| 172 | TRIGGER | LSIDE.FN49.WHEN-MOUSE-CLICK | – | – | – | – | DROPPED | frame / OLB trigger |
| 173 | TRIGGER | LSIDE.FN3.WHEN-MOUSE-ENTER | – | – | – | – | DROPPED | frame / OLB trigger |
| 174 | TRIGGER | LSIDE.FN3.WHEN-MOUSE-LEAVE | – | – | – | – | DROPPED | frame / OLB trigger |
| 175 | TRIGGER | LSIDE.FN3.WHEN-MOUSE-CLICK | – | – | – | – | DROPPED | frame / OLB trigger |
| 176 | TRIGGER | LSIDE.FN48.WHEN-MOUSE-ENTER | – | – | – | – | DROPPED | frame / OLB trigger |
| 177 | TRIGGER | LSIDE.FN48.WHEN-MOUSE-LEAVE | – | – | – | – | DROPPED | frame / OLB trigger |
| 178 | TRIGGER | LSIDE.FN48.WHEN-MOUSE-CLICK | – | – | – | – | DROPPED | frame / OLB trigger |
| 179 | TRIGGER | LSIDE.FN4.WHEN-MOUSE-ENTER | – | – | – | – | DROPPED | frame / OLB trigger |
| 180 | TRIGGER | LSIDE.FN4.WHEN-MOUSE-LEAVE | – | – | – | – | DROPPED | frame / OLB trigger |
| 181 | TRIGGER | LSIDE.FN4.WHEN-MOUSE-CLICK | – | – | – | – | DROPPED | frame / OLB trigger |
| 182 | TRIGGER | LSIDE.FN47.WHEN-MOUSE-ENTER | – | – | – | – | DROPPED | frame / OLB trigger |
| 183 | TRIGGER | LSIDE.FN47.WHEN-MOUSE-LEAVE | – | – | – | – | DROPPED | frame / OLB trigger |
| 184 | TRIGGER | LSIDE.FN47.WHEN-MOUSE-CLICK | – | – | – | – | DROPPED | frame / OLB trigger |
| 185 | TRIGGER | LSIDE.FN5.WHEN-MOUSE-ENTER | – | – | – | – | DROPPED | frame / OLB trigger |
| 186 | TRIGGER | LSIDE.FN5.WHEN-MOUSE-LEAVE | – | – | – | – | DROPPED | frame / OLB trigger |
| 187 | TRIGGER | LSIDE.FN5.WHEN-MOUSE-CLICK | – | – | – | – | DROPPED | frame / OLB trigger |
| 188 | TRIGGER | LSIDE.FN46.WHEN-MOUSE-ENTER | – | – | – | – | DROPPED | frame / OLB trigger |
| 189 | TRIGGER | LSIDE.FN46.WHEN-MOUSE-LEAVE | – | – | – | – | DROPPED | frame / OLB trigger |
| 190 | TRIGGER | LSIDE.FN46.WHEN-MOUSE-CLICK | – | – | – | – | DROPPED | frame / OLB trigger |
| 191 | TRIGGER | LSIDE.FN6.WHEN-MOUSE-ENTER | – | – | – | – | DROPPED | frame / OLB trigger |
| 192 | TRIGGER | LSIDE.FN6.WHEN-MOUSE-LEAVE | – | – | – | – | DROPPED | frame / OLB trigger |
| 193 | TRIGGER | LSIDE.FN6.WHEN-MOUSE-CLICK | – | – | – | – | DROPPED | frame / OLB trigger |
| 194 | TRIGGER | LSIDE.FN45.WHEN-MOUSE-ENTER | – | – | – | – | DROPPED | frame / OLB trigger |
| 195 | TRIGGER | LSIDE.FN45.WHEN-MOUSE-LEAVE | – | – | – | – | DROPPED | frame / OLB trigger |
| 196 | TRIGGER | LSIDE.FN45.WHEN-MOUSE-CLICK | – | – | – | – | DROPPED | frame / OLB trigger |
| 197 | TRIGGER | LSIDE.FN7.WHEN-MOUSE-ENTER | – | – | – | – | DROPPED | frame / OLB trigger |
| 198 | TRIGGER | LSIDE.FN7.WHEN-MOUSE-LEAVE | – | – | – | – | DROPPED | frame / OLB trigger |
| 199 | TRIGGER | LSIDE.FN7.WHEN-MOUSE-CLICK | – | – | – | – | DROPPED | frame / OLB trigger |
| 200 | TRIGGER | LSIDE.FN44.WHEN-MOUSE-ENTER | – | – | – | – | DROPPED | frame / OLB trigger |
| 201 | TRIGGER | LSIDE.FN44.WHEN-MOUSE-LEAVE | – | – | – | – | DROPPED | frame / OLB trigger |
| 202 | TRIGGER | LSIDE.FN44.WHEN-MOUSE-CLICK | – | – | – | – | DROPPED | frame / OLB trigger |
| 203 | TRIGGER | LSIDE.FN8.WHEN-MOUSE-ENTER | – | – | – | – | DROPPED | frame / OLB trigger |
| 204 | TRIGGER | LSIDE.FN8.WHEN-MOUSE-LEAVE | – | – | – | – | DROPPED | frame / OLB trigger |
| 205 | TRIGGER | LSIDE.FN8.WHEN-MOUSE-CLICK | – | – | – | – | DROPPED | frame / OLB trigger |
| 206 | TRIGGER | LSIDE.FN43.WHEN-MOUSE-ENTER | – | – | – | – | DROPPED | frame / OLB trigger |
| 207 | TRIGGER | LSIDE.FN43.WHEN-MOUSE-LEAVE | – | – | – | – | DROPPED | frame / OLB trigger |
| 208 | TRIGGER | LSIDE.FN43.WHEN-MOUSE-CLICK | – | – | – | – | DROPPED | frame / OLB trigger |
| 209 | TRIGGER | LSIDE.FN9.WHEN-MOUSE-ENTER | – | – | – | – | DROPPED | frame / OLB trigger |
| 210 | TRIGGER | LSIDE.FN9.WHEN-MOUSE-LEAVE | – | – | – | – | DROPPED | frame / OLB trigger |
| 211 | TRIGGER | LSIDE.FN9.WHEN-MOUSE-CLICK | – | – | – | – | DROPPED | frame / OLB trigger |
| 212 | TRIGGER | LSIDE.FN42.WHEN-MOUSE-ENTER | – | – | – | – | DROPPED | frame / OLB trigger |
| 213 | TRIGGER | LSIDE.FN42.WHEN-MOUSE-LEAVE | – | – | – | – | DROPPED | frame / OLB trigger |
| 214 | TRIGGER | LSIDE.FN42.WHEN-MOUSE-CLICK | – | – | – | – | DROPPED | frame / OLB trigger |
| 215 | TRIGGER | LSIDE.FN10.WHEN-MOUSE-ENTER | – | – | – | – | DROPPED | frame / OLB trigger |
| 216 | TRIGGER | LSIDE.FN10.WHEN-MOUSE-LEAVE | – | – | – | – | DROPPED | frame / OLB trigger |
| 217 | TRIGGER | LSIDE.FN10.WHEN-MOUSE-CLICK | – | – | – | – | DROPPED | frame / OLB trigger |
| 218 | TRIGGER | LSIDE.FN41.WHEN-MOUSE-ENTER | – | – | – | – | DROPPED | frame / OLB trigger |
| 219 | TRIGGER | LSIDE.FN41.WHEN-MOUSE-LEAVE | – | – | – | – | DROPPED | frame / OLB trigger |
| 220 | TRIGGER | LSIDE.FN41.WHEN-MOUSE-CLICK | – | – | – | – | DROPPED | frame / OLB trigger |
| 221 | TRIGGER | LSIDE.FN11.WHEN-MOUSE-ENTER | – | – | – | – | DROPPED | frame / OLB trigger |
| 222 | TRIGGER | LSIDE.FN11.WHEN-MOUSE-LEAVE | – | – | – | – | DROPPED | frame / OLB trigger |
| 223 | TRIGGER | LSIDE.FN11.WHEN-MOUSE-CLICK | – | – | – | – | DROPPED | frame / OLB trigger |
| 224 | TRIGGER | LSIDE.FN40.WHEN-MOUSE-ENTER | – | – | – | – | DROPPED | frame / OLB trigger |
| 225 | TRIGGER | LSIDE.FN40.WHEN-MOUSE-LEAVE | – | – | – | – | DROPPED | frame / OLB trigger |
| 226 | TRIGGER | LSIDE.FN40.WHEN-MOUSE-CLICK | – | – | – | – | DROPPED | frame / OLB trigger |
| 227 | TRIGGER | LSIDE.FN12.WHEN-MOUSE-ENTER | – | – | – | – | DROPPED | frame / OLB trigger |
| 228 | TRIGGER | LSIDE.FN12.WHEN-MOUSE-LEAVE | – | – | – | – | DROPPED | frame / OLB trigger |
| 229 | TRIGGER | LSIDE.FN12.WHEN-MOUSE-CLICK | – | – | – | – | DROPPED | frame / OLB trigger |
| 230 | TRIGGER | LSIDE.FN39.WHEN-MOUSE-ENTER | – | – | – | – | DROPPED | frame / OLB trigger |
| 231 | TRIGGER | LSIDE.FN39.WHEN-MOUSE-LEAVE | – | – | – | – | DROPPED | frame / OLB trigger |
| 232 | TRIGGER | LSIDE.FN39.WHEN-MOUSE-CLICK | – | – | – | – | DROPPED | frame / OLB trigger |
| 233 | TRIGGER | LSIDE.FN13.WHEN-MOUSE-ENTER | – | – | – | – | DROPPED | frame / OLB trigger |
| 234 | TRIGGER | LSIDE.FN13.WHEN-MOUSE-LEAVE | – | – | – | – | DROPPED | frame / OLB trigger |
| 235 | TRIGGER | LSIDE.FN13.WHEN-MOUSE-CLICK | – | – | – | – | DROPPED | frame / OLB trigger |
| 236 | TRIGGER | LSIDE.FN38.WHEN-MOUSE-ENTER | – | – | – | – | DROPPED | frame / OLB trigger |
| 237 | TRIGGER | LSIDE.FN38.WHEN-MOUSE-LEAVE | – | – | – | – | DROPPED | frame / OLB trigger |
| 238 | TRIGGER | LSIDE.FN38.WHEN-MOUSE-CLICK | – | – | – | – | DROPPED | frame / OLB trigger |
| 239 | TRIGGER | LSIDE.FN14.WHEN-MOUSE-ENTER | – | – | – | – | DROPPED | frame / OLB trigger |
| 240 | TRIGGER | LSIDE.FN14.WHEN-MOUSE-LEAVE | – | – | – | – | DROPPED | frame / OLB trigger |
| 241 | TRIGGER | LSIDE.FN14.WHEN-MOUSE-CLICK | – | – | – | – | DROPPED | frame / OLB trigger |
| 242 | TRIGGER | LSIDE.FN37.WHEN-MOUSE-ENTER | – | – | – | – | DROPPED | frame / OLB trigger |
| 243 | TRIGGER | LSIDE.FN37.WHEN-MOUSE-LEAVE | – | – | – | – | DROPPED | frame / OLB trigger |
| 244 | TRIGGER | LSIDE.FN37.WHEN-MOUSE-CLICK | – | – | – | – | DROPPED | frame / OLB trigger |
| 245 | TRIGGER | LSIDE.FN15.WHEN-MOUSE-ENTER | – | – | – | – | DROPPED | frame / OLB trigger |
| 246 | TRIGGER | LSIDE.FN15.WHEN-MOUSE-LEAVE | – | – | – | – | DROPPED | frame / OLB trigger |
| 247 | TRIGGER | LSIDE.FN15.WHEN-MOUSE-CLICK | – | – | – | – | DROPPED | frame / OLB trigger |
| 248 | TRIGGER | LSIDE.FN36.WHEN-MOUSE-ENTER | – | – | – | – | DROPPED | frame / OLB trigger |
| 249 | TRIGGER | LSIDE.FN36.WHEN-MOUSE-LEAVE | – | – | – | – | DROPPED | frame / OLB trigger |
| 250 | TRIGGER | LSIDE.FN36.WHEN-MOUSE-CLICK | – | – | – | – | DROPPED | frame / OLB trigger |
| 251 | TRIGGER | LSIDE.FN16.WHEN-MOUSE-ENTER | – | – | – | – | DROPPED | frame / OLB trigger |
| 252 | TRIGGER | LSIDE.FN16.WHEN-MOUSE-LEAVE | – | – | – | – | DROPPED | frame / OLB trigger |
| 253 | TRIGGER | LSIDE.FN16.WHEN-MOUSE-CLICK | – | – | – | – | DROPPED | frame / OLB trigger |
| 254 | TRIGGER | LSIDE.FN17.WHEN-MOUSE-ENTER | – | – | – | – | DROPPED | frame / OLB trigger |
| 255 | TRIGGER | LSIDE.FN17.WHEN-MOUSE-LEAVE | – | – | – | – | DROPPED | frame / OLB trigger |
| 256 | TRIGGER | LSIDE.FN17.WHEN-MOUSE-CLICK | – | – | – | – | DROPPED | frame / OLB trigger |
| 257 | TRIGGER | LSIDE.FN34.WHEN-MOUSE-ENTER | – | – | – | – | DROPPED | frame / OLB trigger |
| 258 | TRIGGER | LSIDE.FN34.WHEN-MOUSE-LEAVE | – | – | – | – | DROPPED | frame / OLB trigger |
| 259 | TRIGGER | LSIDE.FN34.WHEN-MOUSE-CLICK | – | – | – | – | DROPPED | frame / OLB trigger |
| 260 | TRIGGER | LSIDE.FN35.WHEN-MOUSE-ENTER | – | – | – | – | DROPPED | frame / OLB trigger |
| 261 | TRIGGER | LSIDE.FN35.WHEN-MOUSE-LEAVE | – | – | – | – | DROPPED | frame / OLB trigger |
| 262 | TRIGGER | LSIDE.FN35.WHEN-MOUSE-CLICK | – | – | – | – | DROPPED | frame / OLB trigger |
| 263 | TRIGGER | LSIDE.FN18.WHEN-MOUSE-ENTER | – | – | – | – | DROPPED | frame / OLB trigger |
| 264 | TRIGGER | LSIDE.FN18.WHEN-MOUSE-LEAVE | – | – | – | – | DROPPED | frame / OLB trigger |
| 265 | TRIGGER | LSIDE.FN18.WHEN-MOUSE-CLICK | – | – | – | – | DROPPED | frame / OLB trigger |
| 266 | TRIGGER | LSIDE.FN33.WHEN-MOUSE-ENTER | – | – | – | – | DROPPED | frame / OLB trigger |
| 267 | TRIGGER | LSIDE.FN33.WHEN-MOUSE-LEAVE | – | – | – | – | DROPPED | frame / OLB trigger |
| 268 | TRIGGER | LSIDE.FN33.WHEN-MOUSE-CLICK | – | – | – | – | DROPPED | frame / OLB trigger |
| 269 | TRIGGER | LSIDE.FN19.WHEN-MOUSE-ENTER | – | – | – | – | DROPPED | frame / OLB trigger |
| 270 | TRIGGER | LSIDE.FN19.WHEN-MOUSE-LEAVE | – | – | – | – | DROPPED | frame / OLB trigger |
| 271 | TRIGGER | LSIDE.FN19.WHEN-MOUSE-CLICK | – | – | – | – | DROPPED | frame / OLB trigger |
| 272 | TRIGGER | LSIDE.FN32.WHEN-MOUSE-ENTER | – | – | – | – | DROPPED | frame / OLB trigger |
| 273 | TRIGGER | LSIDE.FN32.WHEN-MOUSE-LEAVE | – | – | – | – | DROPPED | frame / OLB trigger |
| 274 | TRIGGER | LSIDE.FN32.WHEN-MOUSE-CLICK | – | – | – | – | DROPPED | frame / OLB trigger |
| 275 | TRIGGER | LSIDE.FN20.WHEN-MOUSE-ENTER | – | – | – | – | DROPPED | frame / OLB trigger |
| 276 | TRIGGER | LSIDE.FN20.WHEN-MOUSE-LEAVE | – | – | – | – | DROPPED | frame / OLB trigger |
| 277 | TRIGGER | LSIDE.FN20.WHEN-MOUSE-CLICK | – | – | – | – | DROPPED | frame / OLB trigger |
| 278 | TRIGGER | LSIDE.FN31.WHEN-MOUSE-ENTER | – | – | – | – | DROPPED | frame / OLB trigger |
| 279 | TRIGGER | LSIDE.FN31.WHEN-MOUSE-LEAVE | – | – | – | – | DROPPED | frame / OLB trigger |
| 280 | TRIGGER | LSIDE.FN31.WHEN-MOUSE-CLICK | – | – | – | – | DROPPED | frame / OLB trigger |
| 281 | TRIGGER | LSIDE.FN21.WHEN-MOUSE-ENTER | – | – | – | – | DROPPED | frame / OLB trigger |
| 282 | TRIGGER | LSIDE.FN21.WHEN-MOUSE-LEAVE | – | – | – | – | DROPPED | frame / OLB trigger |
| 283 | TRIGGER | LSIDE.FN21.WHEN-MOUSE-CLICK | – | – | – | – | DROPPED | frame / OLB trigger |
| 284 | TRIGGER | LSIDE.FN30.WHEN-MOUSE-ENTER | – | – | – | – | DROPPED | frame / OLB trigger |
| 285 | TRIGGER | LSIDE.FN30.WHEN-MOUSE-LEAVE | – | – | – | – | DROPPED | frame / OLB trigger |
| 286 | TRIGGER | LSIDE.FN30.WHEN-MOUSE-CLICK | – | – | – | – | DROPPED | frame / OLB trigger |
| 287 | TRIGGER | LSIDE.FN22.WHEN-MOUSE-ENTER | – | – | – | – | DROPPED | frame / OLB trigger |
| 288 | TRIGGER | LSIDE.FN22.WHEN-MOUSE-LEAVE | – | – | – | – | DROPPED | frame / OLB trigger |
| 289 | TRIGGER | LSIDE.FN22.WHEN-MOUSE-CLICK | – | – | – | – | DROPPED | frame / OLB trigger |
| 290 | TRIGGER | LSIDE.FN29.WHEN-MOUSE-ENTER | – | – | – | – | DROPPED | frame / OLB trigger |
| 291 | TRIGGER | LSIDE.FN29.WHEN-MOUSE-LEAVE | – | – | – | – | DROPPED | frame / OLB trigger |
| 292 | TRIGGER | LSIDE.FN29.WHEN-MOUSE-CLICK | – | – | – | – | DROPPED | frame / OLB trigger |
| 293 | TRIGGER | LSIDE.FN23.WHEN-MOUSE-ENTER | – | – | – | – | DROPPED | frame / OLB trigger |
| 294 | TRIGGER | LSIDE.FN23.WHEN-MOUSE-LEAVE | – | – | – | – | DROPPED | frame / OLB trigger |
| 295 | TRIGGER | LSIDE.FN23.WHEN-MOUSE-CLICK | – | – | – | – | DROPPED | frame / OLB trigger |
| 296 | TRIGGER | LSIDE.FN28.WHEN-MOUSE-ENTER | – | – | – | – | DROPPED | frame / OLB trigger |
| 297 | TRIGGER | LSIDE.FN28.WHEN-MOUSE-LEAVE | – | – | – | – | DROPPED | frame / OLB trigger |
| 298 | TRIGGER | LSIDE.FN28.WHEN-MOUSE-CLICK | – | – | – | – | DROPPED | frame / OLB trigger |
| 299 | TRIGGER | LSIDE.FN24.WHEN-MOUSE-ENTER | – | – | – | – | DROPPED | frame / OLB trigger |
| 300 | TRIGGER | LSIDE.FN24.WHEN-MOUSE-LEAVE | – | – | – | – | DROPPED | frame / OLB trigger |
| 301 | TRIGGER | LSIDE.FN24.WHEN-MOUSE-CLICK | – | – | – | – | DROPPED | frame / OLB trigger |
| 302 | TRIGGER | LSIDE.FN27.WHEN-MOUSE-ENTER | – | – | – | – | DROPPED | frame / OLB trigger |
| 303 | TRIGGER | LSIDE.FN27.WHEN-MOUSE-LEAVE | – | – | – | – | DROPPED | frame / OLB trigger |
| 304 | TRIGGER | LSIDE.FN27.WHEN-MOUSE-CLICK | – | – | – | – | DROPPED | frame / OLB trigger |
| 305 | TRIGGER | LSIDE.FN25.WHEN-MOUSE-ENTER | – | – | – | – | DROPPED | frame / OLB trigger |
| 306 | TRIGGER | LSIDE.FN25.WHEN-MOUSE-LEAVE | – | – | – | – | DROPPED | frame / OLB trigger |
| 307 | TRIGGER | LSIDE.FN25.WHEN-MOUSE-CLICK | – | – | – | – | DROPPED | frame / OLB trigger |
| 308 | TRIGGER | LSIDE.FN26.WHEN-MOUSE-ENTER | – | – | – | – | DROPPED | frame / OLB trigger |
| 309 | TRIGGER | LSIDE.FN26.WHEN-MOUSE-LEAVE | – | – | – | – | DROPPED | frame / OLB trigger |
| 310 | TRIGGER | LSIDE.FN26.WHEN-MOUSE-CLICK | – | – | – | – | DROPPED | frame / OLB trigger |
| 311 | TRIGGER | TOOLBAR.KEY-DOWN | – | – | – | – | DROPPED | frame / OLB trigger |
| 312 | TRIGGER | TOOLBAR.KEY-UP | – | – | – | – | DROPPED | frame / OLB trigger |
| 313 | TRIGGER | TOOLBAR.KEY-NEXT-ITEM | – | – | – | – | DROPPED | frame / OLB trigger |
| 314 | TRIGGER | TOOLBAR.SAVE.WHEN-BUTTON-PRESSED | – | – | – | – | DROPPED | frame / OLB trigger |
| 315 | TRIGGER | TOOLBAR.CLEAR_ALL.WHEN-BUTTON-PRESSED | – | – | – | – | DROPPED | frame / OLB trigger |
| 316 | TRIGGER | TOOLBAR.EXIT.WHEN-BUTTON-PRESSED | – | – | – | – | DROPPED | frame / OLB trigger |
| 317 | TRIGGER | TOOLBAR.EXIT1.WHEN-BUTTON-PRESSED | – | – | – | – | DROPPED | frame / OLB trigger |
| 318 | TRIGGER | TOOLBAR.ENTER.WHEN-BUTTON-PRESSED | – | – | – | – | DROPPED | frame / OLB trigger |
| 319 | TRIGGER | TOOLBAR.EXECUTE.WHEN-BUTTON-PRESSED | – | – | – | – | DROPPED | frame / OLB trigger |
| 320 | TRIGGER | TOOLBAR.REMOVE.WHEN-BUTTON-PRESSED | – | – | – | – | DROPPED | frame / OLB trigger |
| 321 | TRIGGER | TOOLBAR.LIST_VALUE.WHEN-BUTTON-PRESSED | – | – | – | – | DROPPED | frame / OLB trigger |
| 322 | TRIGGER | TOOLBAR.HELP.WHEN-BUTTON-PRESSED | – | – | – | – | DROPPED | frame / OLB trigger |
| 323 | TRIGGER | TOOLBAR.LAST_REC.WHEN-BUTTON-PRESSED | – | – | – | – | DROPPED | frame / OLB trigger |
| 324 | TRIGGER | TOOLBAR.RE_ENTER_QUERY.WHEN-BUTTON-PRESSED | – | – | – | – | DROPPED | frame / OLB trigger |
| 325 | TRIGGER | TOOLBAR.FIRST_REC.WHEN-BUTTON-PRESSED | – | – | – | – | DROPPED | frame / OLB trigger |
| 326 | TRIGGER | TOOLBAR.PAGE_UP.WHEN-BUTTON-PRESSED | – | – | – | – | DROPPED | frame / OLB trigger |
| 327 | TRIGGER | TOOLBAR.PAGE_DOWN.WHEN-BUTTON-PRESSED | – | – | – | – | DROPPED | frame / OLB trigger |
| 328 | TRIGGER | TOOLBAR.FUN_BUT.WHEN-MOUSE-UP | – | – | – | – | DROPPED | frame / OLB trigger |
| 329 | TRIGGER | TOOLBAR.FUN_BUT.WHEN-MOUSE-DOWN | – | – | – | – | DROPPED | frame / OLB trigger |
| 330 | TRIGGER | IMPR_RULES.ON-ERROR | APPLICATION | APP_ERROR_HANDLER + Text Messages | 0 | – | MAPPED | f345 error handling |
| 331 | TRIGGER | IMPR_RULES.POST-QUERY | PROCESS | POST-QUERY | 1140 | IMPR1140.POST_QUERY | MAPPED | Before Header 82 |
| 332 | TRIGGER | IMPR_RULES.PRE-QUERY | REGION SQL | IMPR_RULES_SEARCH (page 114001) | 1140 | – | MAPPED | BUS_ID_TYPE_NAME criterion in the search text |
| 333 | TRIGGER | IMPR_RULES.KEY-DELREC | PROCESS | KEY-DELREC | 1140 | IMPR1140.KEY_DELREC | MAPPED | confirm = page 0 DELETE; delete = Process form - DELETE |
| 334 | TRIGGER | IMPR_RULES.KEY-HELP | – | – | – | – | DROPPED | MS-Help (obsolete) |
| 335 | TRIGGER | IMPR_RULES.POST-INSERT | PROCESS | POST-INSERT | 1140 | IMPR1140.POST_INSERT | MAPPED | SMS (LIB_USR.SMS_MESSAGE missing source) |
| 336 | TRIGGER | IMPR_RULES.POST-UPDATE | PROCESS | POST-UPDATE | 1140 | IMPR1140.POST_UPDATE | MAPPED | activity log + SMS |
| 337 | TRIGGER | IMPR_RULES.PRE-DELETE | PROCESS | PRE-DELETE | 1140 | IMPR1140.PRE_DELETE | MAPPED | – |
| 338 | TRIGGER | IMPR_RULES.PRE-INSERT | PROCESS | PRE-INSERT | 1140 | IMPR1140.PRE_INSERT | MAPPED | – |
| 339 | TRIGGER | IMPR_RULES.PRE-UPDATE | PROCESS | PRE-UPDATE | 1140 | IMPR1140.PRE_UPDATE | MAPPED | – |
| 340 | TRIGGER | IMPR_RULES.WHEN-NEW-RECORD-INSTANCE | DA | ALL_BRNCH_FLAG WHEN-VALIDATE-ITEM (fire on initialization) | 1140 | IMPR1140.ADJ_BRANCH | MAPPED | – |
| 341 | TRIGGER | IMPR_RULES.RULE_ISN.KEY-LISTVAL | – | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 342 | TRIGGER | IMPR_RULES.D.KEY-LISTVAL | – | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 343 | TRIGGER | IMPR_RULES.RULE_TYPE.WHEN-LIST-CHANGED | DA | RULE_TYPE WHEN-LIST-CHANGED | 1140 | IMPR1140.RULE_TYPE_VALIDATION | MAPPED | – |
| 344 | TRIGGER | IMPR_RULES.RULE_TYPE.WHEN-VALIDATE-ITEM | VALIDATION | RULE_TYPE VALIDATION | 1140 | IMPR1140.RULE_TYPE_VALIDATION | MAPPED | – |
| 345 | TRIGGER | IMPR_RULES.ALL_BRNCH_FLAG.WHEN-VALIDATE-ITEM | DA | ALL_BRNCH_FLAG WHEN-VALIDATE-ITEM + process of the same name | 1140 | IMPR1140.ADJ_BRANCH | MAPPED | – |
| 346 | TRIGGER | IMPR_RULES.HQ_IMPR_NBR.KEY-LISTVAL | LOV | LOV_SINGLE_IMPORTERS (Popup LOV) | 1140 | – | MAPPED | SINGLE_IMP_LOV |
| 347 | TRIGGER | IMPR_RULES.HQ_IMPR_NBR.WHEN-VALIDATE-ITEM | VALIDATION | HQ_IMPR_NBR VALIDATION + DA HQ_IMPR_NBR WHEN-VALIDATE-ITEM | 1140 | IMPR1140.HQ_IMPR_NBR_VALIDATE_ITEM | MAPPED | also HQ_IMPR_NBR_VALIDATION |
| 348 | TRIGGER | IMPR_RULES.B_IMP.WHEN-BUTTON-PRESSED | LOV | Popup LOV icon of P1140_HQ_IMPR_NBR | 1140 | – | MAPPED | – |
| 349 | TRIGGER | IMPR_RULES.L_SI_ARBC_IMPR_NAME.KEY-LISTVAL | – | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 350 | TRIGGER | IMPR_RULES.BUS_ID_TYPE_CD.KEY-LISTVAL | – | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 351 | TRIGGER | IMPR_RULES.BUS_ID_TYPE_NAME.KEY-LISTVAL | – | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 352 | TRIGGER | IMPR_RULES.BUS_ID.KEY-LISTVAL | – | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 353 | TRIGGER | IMPR_RULE_PORTS.POST-QUERY | IG SQL | IMPR_RULE_PORTS (join SD_PORTS) | 1140 | IMPR1140.IMPR_RULE_PORTS_INSERT_ALLOWED | MAPPED | insert-allowed part -> server check |
| 354 | TRIGGER | IMPR_RULE_PORTS.ON-ERROR | APPLICATION | APP_ERROR_HANDLER + Text Messages | 0 | – | MAPPED | f345 error handling |
| 355 | TRIGGER | IMPR_RULE_PORTS.KEY-HELP | – | – | – | – | DROPPED | MS-Help (obsolete) |
| 356 | TRIGGER | IMPR_RULE_PORTS.PRE-DELETE | PROCESS | IMPR_RULE_PORTS - Save Interactive Grid Data | 1140 | IMPR1140.IMPR_RULE_PORTS_PRE_DELETE | MAPPED | row status D |
| 357 | TRIGGER | IMPR_RULE_PORTS.PRE-INSERT | PROCESS | IMPR_RULE_PORTS - Save Interactive Grid Data | 1140 | IMPR1140.IMPR_RULE_PORTS_PRE_INSERT | MAPPED | row status C |
| 358 | TRIGGER | IMPR_RULE_PORTS.PRE-RECORD | PROCESS | IMPR_RULE_PORTS - Save Interactive Grid Data | 1140 | IMPR1140.IMPR_RULE_PORTS_INSERT_ALLOWED | MAPPED | server check in PRE-INSERT |
| 359 | TRIGGER | IMPR_RULE_PORTS.PRE-UPDATE | PROCESS | IMPR_RULE_PORTS - Save Interactive Grid Data | 1140 | IMPR1140.IMPR_RULE_PORTS_PRE_UPDATE | MAPPED | row status U |
| 360 | TRIGGER | IMPR_RULE_PORTS.WHEN-NEW-RECORD-INSTANCE | PROCESS | IMPR_RULE_PORTS - Save Interactive Grid Data | 1140 | IMPR1140.IMPR_RULE_PORTS_INSERT_ALLOWED | MAPPED | server check in PRE-INSERT |
| 361 | TRIGGER | IMPR_RULE_PORTS.PORT_CD.KEY-LISTVAL | LOV | LOV_SD_PORTS (Popup LOV column) | 1140 | – | MAPPED | CALL_SD_PORTS |
| 362 | TRIGGER | IMPR_RULE_PORTS.PORT_CD.WHEN-VALIDATE-ITEM | VALIDATION | IMPR_RULE_PORTS PORT_CD VALIDATION + DA IMPR_RULE_PORTS PORT_CD WHEN-VALIDATE-ITEM | 1140 | IMPR1140.PORT_CD_WHEN_VALIDATE_ITEM | MAPPED | also PORT_CD_VALIDATION |
| 363 | TRIGGER | IMPR_RULE_PORTS.PORT_CD2.WHEN-BUTTON-PRESSED | LOV | Popup LOV icon of PORT_CD | 1140 | – | MAPPED | – |
| 364 | TRIGGER | IMPR_RULE_PORTS.PORT_NAME.KEY-LISTVAL | – | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 365 | TRIGGER | IMPR_RULE_TARIFF.ON-ERROR | APPLICATION | APP_ERROR_HANDLER + Text Messages | 0 | – | MAPPED | f345 error handling |
| 366 | TRIGGER | IMPR_RULE_TARIFF.KEY-HELP | – | – | – | – | DROPPED | MS-Help (obsolete) |
| 367 | TRIGGER | IMPR_RULE_TARIFF.POST-QUERY | IG SQL | IMPR_RULE_TARIFF column INTL_UNIT | 1140 | IMPR1140.IMPR_RULE_TARIFF_POST_QUERY | MAPPED | – |
| 368 | TRIGGER | IMPR_RULE_TARIFF.PRE-DELETE | – | – | – | – | DROPPED | Delete Allowed = false: cannot fire; delete refused in IMPR_RULE_TARIFF_SAVE_ROW |
| 369 | TRIGGER | IMPR_RULE_TARIFF.PRE-INSERT | PROCESS | IMPR_RULE_TARIFF - Save Interactive Grid Data | 1140 | IMPR1140.IMPR_RULE_TARIFF_PRE_INSERT | MAPPED | row status C |
| 370 | TRIGGER | IMPR_RULE_TARIFF.PRE-UPDATE | PROCESS | IMPR_RULE_TARIFF - Save Interactive Grid Data | 1140 | IMPR1140.IMPR_RULE_TARIFF_PRE_UPDATE | MAPPED | row status U |
| 371 | TRIGGER | IMPR_RULE_TARIFF.HRMNZD_CODE.KEY-LISTVAL | LOV | LOV_HARMONIZED_TARIFF (Popup LOV column) | 1140 | – | MAPPED | DSP_TRF_ITEMS_LOV |
| 372 | TRIGGER | IMPR_RULE_TARIFF.HRMNZD_CODE.POST-CHANGE | DA | IMPR_RULE_TARIFF HRMNZD_CODE WHEN-VALIDATE-ITEM | 1140 | IMPR1140.HRMNZD_CODE_VALIDATE_ITEM | MAPPED | merged (same description lookup) |
| 373 | TRIGGER | IMPR_RULE_TARIFF.HRMNZD_CODE.WHEN-VALIDATE-ITEM | VALIDATION | IMPR_RULE_TARIFF HRMNZD_CODE VALIDATION + DA IMPR_RULE_TARIFF HRMNZD_CODE WHEN-VALIDATE-ITEM | 1140 | IMPR1140.HRMNZD_CODE_VALIDATE_ITEM | MAPPED | also HRMNZD_CODE_VALIDATION |
| 374 | TRIGGER | IMPR_RULE_TARIFF.HRMNZD_CODE2.WHEN-BUTTON-PRESSED | LOV | Popup LOV icon of HRMNZD_CODE | 1140 | – | MAPPED | – |
| 375 | TRIGGER | IMPR_RULE_TARIFF.HT_ITEM_ARBC_DESC.KEY-LISTVAL | – | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 376 | TRIGGER | IMPR_RULE_TARIFF.EXEPTION_QTY.WHEN-VALIDATE-ITEM | DA | IMPR_RULE_TARIFF EXEPTION_QTY WHEN-VALIDATE-ITEM | 1140 | IMPR1140.EXEPTION_QTY_VALIDATE_ITEM | MAPPED | FOS + native Alert |
| 377 | TRIGGER | IMPR_RULE_TARIFF.REMAINED_QTY.KEY-LISTVAL | – | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 378 | TRIGGER | IMPR_RULE_TARIFF.INTL_UNIT.KEY-LISTVAL | – | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 379 | TRIGGER | IMPR_RULE_TARIFF.ITEM_SEQUENCE.KEY-LISTVAL | – | – | – | – | DROPPED | Designer "may the LOV be shown" check -> item read-only state |
| 380 | LOV | CGFK$IMPR_RULE_PORTS_PORT_CD | LOV | LOV_SD_PORTS (reused, IMPR1110) | 1140 | – | MAPPED | – |
| 381 | LOV | CGFK$IMPR_RULE_TARIFF_HRMNZD_C | LOV | LOV_HARMONIZED_TARIFF (LOV_APX.LOV_HARMONIZED_TARIFF) | 1140 | – | MAPPED | – |
| 382 | RECORD_GROUP | CGFK$IMPR_RULE_PORTS_PORT_CD | LOV | LOV_SD_PORTS (reused, IMPR1110) | 1140 | – | MAPPED | query of the LOV |
| 383 | RECORD_GROUP | CGLT$CVS_DATA | – | – | – | – | DROPPED | Designer tab metadata |
| 384 | RECORD_GROUP | CGFK$IMPR_RULE_TARIFF_HRMNZD_C | LOV | LOV_HARMONIZED_TARIFF (LOV_APX.LOV_HARMONIZED_TARIFF) | 1140 | – | MAPPED | query of the LOV |
| 385 | RECORD_GROUP | CGDV$DLRG (runtime) | LOV | LOV_RULE_TYPE, LOV_REC_STATUS | 1140 | – | MAPPED | CG_REF_CODES lists |
| 386 | LIST | IMPR_RULES.ALL_BRNCH_FLAG (static pop list) | LOV | LOV_ALL_BRNCH_FLAG (static) | 1140 | – | MAPPED | – |
| 387 | CANVAS | LSIDE | – | – | – | – | DROPPED | OLB frame canvas |
| 388 | CANVAS | EDI_MSG | – | – | – | – | DROPPED | OLB frame canvas |
| 389 | CANVAS | TITLE | REGION | IMPR_RULES_HERO | 1140 | – | MAPPED | – |
| 390 | CANVAS | TOOLBAR | – | – | – | – | DROPPED | OLB frame canvas |
| 391 | CANVAS | CG$PAGE_1 | REGION | IMPR_RULES | 1140 | – | MAPPED | – |
| 392 | CANVAS | CG$M_TAB_1 | REGION | CG$M_TAB_1 (Tabs Container) | 1140 | – | MAPPED | – |
| 393 | TAB_PAGE | CG$M_TAB_1_PAGE_1 | REGION | IMPR_RULE_PORTS (tab "جمارك الإستثناء") | 1140 | – | MAPPED | – |
| 394 | TAB_PAGE | CG$M_TAB_1_PAGE_2 | REGION | IMPR_RULE_TARIFF (tab "بنود التعريفة المستثاه") | 1140 | – | MAPPED | – |
| 395 | WINDOW | CGSO$WINDOW_1 | PAGE | 1140 IMPR1140 | 1140 | – | MAPPED | title -> HEADER TITLE |
| 396 | ALERT | CG$ASK_COMMIT | – | – | – | – | DROPPED | not used by business code |
| 397 | ALERT | USR_CONFIRM_B | – | – | – | – | DROPPED | not used by business code |
| 398 | ALERT | USR_CONFIRM | – | – | – | – | DROPPED | not used by business code |
| 399 | ALERT | USR_WARNING_C | BUTTON | DELETE confirm (page 0) | 0 | – | MAPPED | TMPLT.KEY_DELETE_RECORD |
| 400 | ALERT | USR_WARNING_B | – | – | – | – | DROPPED | not used by business code |
| 401 | ALERT | CFG_WARNING_A | – | – | – | – | DROPPED | not used by business code |
| 402 | ALERT | CFG_INFORMATION | APEX | error text / FORMS_APX / native Alert | 1140 | – | MAPPED | spec 11 |
| 403 | ALERT | CFG_ERROR | APEX | error text / FORMS_APX / native Alert | 1140 | – | MAPPED | spec 11 |
| 404 | ALERT | CFG_SYSTEM_ERROR | – | – | – | – | DROPPED | not used by business code |
| 405 | ALERT | CFG_ASK_COMMIT | – | – | – | – | DROPPED | not used by business code |
| 406 | PARAMETER | P_SHPG_AGNT_NBR | – | – | – | – | DROPPED | not used by business code |
| 407 | PARAMETER | P_CTRL_LAST_EXEC_CD | – | – | – | – | DROPPED | not used by business code |
| 408 | PARAMETER | P_BANK_CD | – | – | – | – | DROPPED | not used by business code |
| 409 | PARAMETER | P_BANK_BRNCH_CD | – | – | – | – | DROPPED | not used by business code |
| 410 | PARAMETER | P_BRKR_PORT_CD | – | – | – | – | DROPPED | not used by business code |
| 411 | PARAMETER | P_LIC_TYPE | – | – | – | – | DROPPED | not used by business code |
| 412 | PARAMETER | P_BRKR_NBR | – | – | – | – | DROPPED | not used by business code |
| 413 | PARAMETER | P_CLASS_CD | ITEM | P_CLASS_CD | 0 | – | MAPPED | f345 item |
| 414 | PARAMETER | P_JOB_ID | – | – | – | – | DROPPED | not used by business code |
| 415 | PARAMETER | P_CURRENT_ITEM | – | – | – | – | DROPPED | not used by business code |
| 416 | PARAMETER | P_GROUP_CD | – | – | – | – | DROPPED | not used by business code |
| 417 | PARAMETER | P_USER_TYPE | ITEM | V_USR_TYPE | 0 | – | MAPPED | f345 item |
| 418 | PARAMETER | P_PORT_TYPE | ITEM | P_PORT_TYPE | 0 | – | MAPPED | f345 item |
| 419 | PARAMETER | P_CURR_PORT_CD | ITEM | P_CURR_PORT_CD | 0 | – | MAPPED | f345 item |
| 420 | PARAMETER | P_MODULE_ID | ITEM | P1140_MODULE_ID | 1140 | – | MAPPED | f345 item |
| 421 | PARAMETER | P_MODULE_NAME | – | – | – | – | DROPPED | not used by business code |
| 422 | PARAMETER | P_APPLICATION_NAME | – | – | – | – | DROPPED | not used by business code |
| 423 | PARAMETER | P_USER_ID | ITEM | SSO_APP_USER | 0 | – | MAPPED | f345 item |
| 424 | PARAMETER | P_WS_ID | ITEM | P_GLOBAL_V_WS_ID | 0 | – | MAPPED | f345 item |
| 425 | PARAMETER | P_USER_NAME | ITEM | V_USR_NAME | 0 | – | MAPPED | f345 item |
| 426 | PARAMETER | CG$STARTUP_MODE | – | – | – | – | DROPPED | not used by business code |
| 427 | LIBRARY | OFGTEL | – | – | – | – | DROPPED | calls replaced (inventory 10.3, 10.8) |
| 428 | LIBRARY | OFGMES | – | – | – | – | DROPPED | calls replaced (inventory 10.3, 10.8) |
| 429 | LIBRARY | OFGHPL | – | – | – | – | DROPPED | calls replaced (inventory 10.3, 10.8) |
| 430 | LIBRARY | CIC_AMSG | – | – | – | – | DROPPED | calls replaced (inventory 10.3, 10.8) |
| 431 | LIBRARY | SEC_LIB | – | – | – | – | DROPPED | calls replaced (inventory 10.3, 10.8) |
| 432 | LIBRARY | CAPTION | – | – | – | – | DROPPED | calls replaced (inventory 10.3, 10.8) |
| 433 | LIBRARY | OFGBSL | – | – | – | – | DROPPED | calls replaced (inventory 10.3, 10.8) |
| 434 | LIBRARY | D2KWUTIL | – | – | – | – | DROPPED | calls replaced (inventory 10.3, 10.8) |
| 435 | LIBRARY | CUSTOMDLL | – | – | – | – | DROPPED | calls replaced (inventory 10.3, 10.8) |
| 436 | LIBRARY | D2KWUTIL_PDF | – | – | – | – | DROPPED | calls replaced (inventory 10.3, 10.8) |
| 437 | LIBRARY | GETCOMP | – | – | – | – | DROPPED | calls replaced (inventory 10.3, 10.8) |
| 438 | LIBRARY | OFGTAB | – | – | – | – | DROPPED | calls replaced (inventory 10.3, 10.8) |
| 439 | LIBRARY | PICKLIST | – | – | – | – | DROPPED | calls replaced (inventory 10.3, 10.8) |
| 440 | LIBRARY | POS | – | – | – | – | DROPPED | calls replaced (inventory 10.3, 10.8) |
| 441 | LIBRARY | SCDLL | – | – | – | – | DROPPED | calls replaced (inventory 10.3, 10.8) |
| 442 | LIBRARY | VCDLL | – | – | – | – | DROPPED | calls replaced (inventory 10.3, 10.8) |
| 443 | LIBRARY | CIC_LIB | – | – | – | – | MAPPED | ACTIVITY -> ACTIVITY_DB; STR -> FORMS_APX |
| 444 | PROGRAM_UNIT | CHECK_TIMEOUT | – | – | – | – | DROPPED | extraction report 1.6 |
| 445 | PROGRAM_UNIT | MOUSE_CLICK | REGION | FUNCS (page 0) | 0 | – | MAPPED | Page Functions list |
| 446 | PROGRAM_UNIT | TOGGEL_WND | – | – | – | – | DROPPED | extraction report 1.6 |
| 447 | PROGRAM_UNIT | PRINT_REPORT | – | – | – | – | DROPPED | extraction report 1.6 |
| 448 | PROGRAM_UNIT | EXECUTE_FUNCTION | REGION | FUNCS (page 0) | 0 | – | MAPPED | Page Functions list |
| 449 | PROGRAM_UNIT | TERMINATE_FUN | – | – | – | – | DROPPED | extraction report 1.6 |
| 450 | PROGRAM_UNIT | CHECK_EDI_MSG_LOV | – | – | – | – | DROPPED | extraction report 1.6 |
| 451 | PROGRAM_UNIT | CHECK_EDI_MSG_TIMER | – | – | – | – | DROPPED | extraction report 1.6 |
| 452 | PROGRAM_UNIT | CHECK_EDI_ROLE_ID | – | – | – | – | DROPPED | extraction report 1.6 |
| 453 | PROGRAM_UNIT | EDI_MSG_LOV | – | – | – | – | DROPPED | extraction report 1.6 |
| 454 | PROGRAM_UNIT | FOR_EDI_MSG | – | – | – | – | DROPPED | extraction report 1.6 |
| 455 | PROGRAM_UNIT | RETURN_MSG | – | – | – | – | DROPPED | extraction report 1.6 |
| 456 | PROGRAM_UNIT | TURN_MSG | – | – | – | – | DROPPED | extraction report 1.6 |
| 457 | PROGRAM_UNIT | WHEN_TIMER_EXPIRED_MSG | – | – | – | – | DROPPED | extraction report 1.6 |
| 458 | PROGRAM_UNIT | CG$WHEN_NEW_FORM_INSTANCE | – | – | – | – | DROPPED | extraction report 1.6 |
| 459 | PROGRAM_UNIT | CGDV$POPULATE_DYNAMIC_LISTS | – | – | – | – | DROPPED | extraction report 1.6 |
| 460 | PROGRAM_UNIT | CGFK$QRY_IMPR_RULES_IR_BIT_FK | PACKAGE | IMPR1140.CGFK$QRY_IMPR_RULES_IR_BIT_FK | – | IMPR1140.CGFK$QRY_IMPR_RULES_IR_BIT_FK | MAPPED | same name |
| 461 | PROGRAM_UNIT | CGFK$CHK_IMPR_RULES_IR_BIT_FK | – | – | – | – | DROPPED | extraction report 1.6 |
| 462 | PROGRAM_UNIT | CG$IMPR1140_CNTRL_GLOBALS | – | – | – | – | DROPPED | extraction report 1.6 |
| 463 | PROGRAM_UNIT | CGFK$QRY_IMPR_RULE_PORTS_IRP_S | – | – | – | – | DROPPED | extraction report 1.6 |
| 464 | PROGRAM_UNIT | CGFK$CHK_IMPR_RULE_PORTS_IRP_S | PACKAGE | IMPR1140.CGFK$CHK_IMPR_RULE_PORTS_IRP_S | – | IMPR1140.CGFK$CHK_IMPR_RULE_PORTS_IRP_S | MAPPED | same name |
| 465 | PROGRAM_UNIT | CGFK$CHK_IMPR_RULE_PORTS_IRP_I | – | – | – | – | DROPPED | extraction report 1.6 |
| 466 | PROGRAM_UNIT | CGRI$CHK_IMPR_RULES | PACKAGE | IMPR1140.CGRI$CHK_IMPR_RULES | – | IMPR1140.CGRI$CHK_IMPR_RULES | MAPPED | same name |
| 467 | PROGRAM_UNIT | CGTE$CHECK_CONSTRAINT_VIO | – | – | – | – | DROPPED | extraction report 1.6 |
| 468 | PROGRAM_UNIT | CGLY$DISPLAY_CANVASES | – | – | – | – | DROPPED | extraction report 1.6 |
| 469 | PROGRAM_UNIT | CGLY$GET_RELATED_CANVASES | – | – | – | – | DROPPED | extraction report 1.6 |
| 470 | PROGRAM_UNIT | CGLY$RAISE_CANVAS | – | – | – | – | DROPPED | extraction report 1.6 |
| 471 | PROGRAM_UNIT | CGLY$CANVAS_MANAGEMENT | – | – | – | – | DROPPED | extraction report 1.6 |
| 472 | PROGRAM_UNIT | CGBS$TOGGLE | – | – | – | – | DROPPED | extraction report 1.6 |
| 473 | PROGRAM_UNIT | CGBS$SET_QUERY_MODE | – | – | – | – | DROPPED | extraction report 1.6 |
| 474 | PROGRAM_UNIT | CGBS$MESSAGE_QUERY_MODE | – | – | – | – | DROPPED | extraction report 1.6 |
| 475 | PROGRAM_UNIT | SINGLE_IMP_LOV | LOV | LOV_SINGLE_IMPORTERS | 1140 | – | MAPPED | LOV form -> Popup LOV |
| 476 | PROGRAM_UNIT | EXEC_FUNS | – | – | – | – | DROPPED | extraction report 1.6 |
| 477 | PROGRAM_UNIT | DSP_TRF_ITEMS_LOV | LOV | LOV_HARMONIZED_TARIFF | 1140 | – | MAPPED | LOV form -> Popup LOV |
| 478 | PROGRAM_UNIT | CHECK_FASH_ROLE_ID | PACKAGE | IMPR1140.CHECK_FASH_ROLE_ID | – | IMPR1140.CHECK_FASH_ROLE_ID | MAPPED | same name |
| 479 | PROGRAM_UNIT | CALL_SD_PORTS | LOV | LOV_SD_PORTS | 1140 | – | MAPPED | LOV form -> Popup LOV |
| 480 | PROGRAM_UNIT | CALL_IMPR_TYPE | – | – | – | – | DROPPED | extraction report 1.6 |
| 481 | PROGRAM_UNIT | ADJ_FUNS | – | – | – | – | DROPPED | extraction report 1.6 |
| 482 | PROGRAM_UNIT | ADJ_BRANCH | PACKAGE | IMPR1140.ADJ_BRANCH | – | IMPR1140.ADJ_BRANCH | MAPPED | same name |
| 483 | VISUAL_ATTRIBUTE | CG$MANDATORY_LIST_ITEM | THEME | Theme 42 / ZATCA Forms | – | – | MAPPED | OLB visual attribute -> theme style |
| 484 | VISUAL_ATTRIBUTE | CG$DISPLAY_LIST_ITEM | THEME | Theme 42 / ZATCA Forms | – | – | MAPPED | OLB visual attribute -> theme style |
| 485 | VISUAL_ATTRIBUTE | VA_FN | THEME | Theme 42 / ZATCA Forms | – | – | MAPPED | OLB visual attribute -> theme style |
| 486 | VISUAL_ATTRIBUTE | VA_EDI_MSG | THEME | Theme 42 / ZATCA Forms | – | – | MAPPED | OLB visual attribute -> theme style |
| 487 | VISUAL_ATTRIBUTE | VA_TITLE | THEME | Theme 42 / ZATCA Forms | – | – | MAPPED | OLB visual attribute -> theme style |
| 488 | VISUAL_ATTRIBUTE | VA_TOOLBAR | THEME | Theme 42 / ZATCA Forms | – | – | MAPPED | OLB visual attribute -> theme style |
| 489 | VISUAL_ATTRIBUTE | VA_LSIDE | THEME | Theme 42 / ZATCA Forms | – | – | MAPPED | OLB visual attribute -> theme style |
| 490 | VISUAL_ATTRIBUTE | VA_RED | THEME | Theme 42 / ZATCA Forms | – | – | MAPPED | OLB visual attribute -> theme style |
| 491 | VISUAL_ATTRIBUTE | VA_GRAY | THEME | Theme 42 / ZATCA Forms | – | – | MAPPED | OLB visual attribute -> theme style |
| 492 | VISUAL_ATTRIBUTE | VA_BLACK | THEME | Theme 42 / ZATCA Forms | – | – | MAPPED | OLB visual attribute -> theme style |
| 493 | VISUAL_ATTRIBUTE | VA_ORANGE | THEME | Theme 42 / ZATCA Forms | – | – | MAPPED | OLB visual attribute -> theme style |
| 494 | VISUAL_ATTRIBUTE | VA_GREEN | THEME | Theme 42 / ZATCA Forms | – | – | MAPPED | OLB visual attribute -> theme style |
| 495 | VISUAL_ATTRIBUTE | VA_YELLOW | THEME | Theme 42 / ZATCA Forms | – | – | MAPPED | OLB visual attribute -> theme style |
| 496 | VISUAL_ATTRIBUTE | CG$DISPLAY_ITEM_ARB | THEME | Theme 42 / ZATCA Forms | – | – | MAPPED | OLB visual attribute -> theme style |
| 497 | VISUAL_ATTRIBUTE | CG$ITEM_ARB | THEME | Theme 42 / ZATCA Forms | – | – | MAPPED | OLB visual attribute -> theme style |
| 498 | VISUAL_ATTRIBUTE | STD_CURRENT_FUNCTION | THEME | Theme 42 / ZATCA Forms | – | – | MAPPED | OLB visual attribute -> theme style |
| 499 | VISUAL_ATTRIBUTE | STD_NORMAL_FUNCTION | THEME | Theme 42 / ZATCA Forms | – | – | MAPPED | OLB visual attribute -> theme style |
| 500 | VISUAL_ATTRIBUTE | CG$BLOCK_TITLE | THEME | Theme 42 / ZATCA Forms | – | – | MAPPED | OLB visual attribute -> theme style |
| 501 | VISUAL_ATTRIBUTE | CG$BLOCK_DECORATION | THEME | Theme 42 / ZATCA Forms | – | – | MAPPED | OLB visual attribute -> theme style |
| 502 | VISUAL_ATTRIBUTE | CG$TITLE | THEME | Theme 42 / ZATCA Forms | – | – | MAPPED | OLB visual attribute -> theme style |
| 503 | VISUAL_ATTRIBUTE | CG$TREE | THEME | Theme 42 / ZATCA Forms | – | – | MAPPED | OLB visual attribute -> theme style |
| 504 | VISUAL_ATTRIBUTE | CG$ITEM | THEME | Theme 42 / ZATCA Forms | – | – | MAPPED | OLB visual attribute -> theme style |
| 505 | VISUAL_ATTRIBUTE | CG$PROMPT | THEME | Theme 42 / ZATCA Forms | – | – | MAPPED | OLB visual attribute -> theme style |
| 506 | VISUAL_ATTRIBUTE | CG$PROMPT_MD | THEME | Theme 42 / ZATCA Forms | – | – | MAPPED | OLB visual attribute -> theme style |
| 507 | VISUAL_ATTRIBUTE | CG$PROMPT_OP | THEME | Theme 42 / ZATCA Forms | – | – | MAPPED | OLB visual attribute -> theme style |
| 508 | VISUAL_ATTRIBUTE | CG$DISPLAY_ITEM | THEME | Theme 42 / ZATCA Forms | – | – | MAPPED | OLB visual attribute -> theme style |
| 509 | VISUAL_ATTRIBUTE | CG$CANVAS | THEME | Theme 42 / ZATCA Forms | – | – | MAPPED | OLB visual attribute -> theme style |
| 510 | VISUAL_ATTRIBUTE | CG$CURRENT_RECORD | THEME | Theme 42 / ZATCA Forms | – | – | MAPPED | OLB visual attribute -> theme style |
| 511 | VISUAL_ATTRIBUTE | CG$BUTTON_ICONIC | THEME | Theme 42 / ZATCA Forms | – | – | MAPPED | OLB visual attribute -> theme style |
| 512 | VISUAL_ATTRIBUTE | CG$RADIO_TITLE | THEME | Theme 42 / ZATCA Forms | – | – | MAPPED | OLB visual attribute -> theme style |
| 513 | VISUAL_ATTRIBUTE | CG$GROUP_TITLE | THEME | Theme 42 / ZATCA Forms | – | – | MAPPED | OLB visual attribute -> theme style |
| 514 | VISUAL_ATTRIBUTE | CG$GROUP_TITLE_ITEM | THEME | Theme 42 / ZATCA Forms | – | – | MAPPED | OLB visual attribute -> theme style |
| 515 | VISUAL_ATTRIBUTE | CG$PUSH_BUTTON | THEME | Theme 42 / ZATCA Forms | – | – | MAPPED | OLB visual attribute -> theme style |
| 516 | VISUAL_ATTRIBUTE | CG$MANDATORY_RADIO_BUTTON | THEME | Theme 42 / ZATCA Forms | – | – | MAPPED | OLB visual attribute -> theme style |
| 517 | VISUAL_ATTRIBUTE | CG$OPTIONAL_RADIO_BUTTON | THEME | Theme 42 / ZATCA Forms | – | – | MAPPED | OLB visual attribute -> theme style |
| 518 | VISUAL_ATTRIBUTE | CG$DISPLAY_RADIO_BUTTON | THEME | Theme 42 / ZATCA Forms | – | – | MAPPED | OLB visual attribute -> theme style |
| 519 | VISUAL_ATTRIBUTE | CG$MANDATORY_CHECK_BOX | THEME | Theme 42 / ZATCA Forms | – | – | MAPPED | OLB visual attribute -> theme style |
| 520 | VISUAL_ATTRIBUTE | CG$OPTIONAL_CHECK_BOX | THEME | Theme 42 / ZATCA Forms | – | – | MAPPED | OLB visual attribute -> theme style |
| 521 | VISUAL_ATTRIBUTE | CG$DISPLAY_CHECK_BOX | THEME | Theme 42 / ZATCA Forms | – | – | MAPPED | OLB visual attribute -> theme style |
| 522 | VISUAL_ATTRIBUTE | CG$OTHER_RECORD | THEME | Theme 42 / ZATCA Forms | – | – | MAPPED | OLB visual attribute -> theme style |
| 523 | VISUAL_ATTRIBUTE | CG$DRILLDOWN | THEME | Theme 42 / ZATCA Forms | – | – | MAPPED | OLB visual attribute -> theme style |
| 524 | VISUAL_ATTRIBUTE | NORMAL_VA | THEME | Theme 42 / ZATCA Forms | – | – | MAPPED | OLB visual attribute -> theme style |
| 525 | VISUAL_ATTRIBUTE | ACTIVE_VA | THEME | Theme 42 / ZATCA Forms | – | – | MAPPED | OLB visual attribute -> theme style |
| 526 | VISUAL_ATTRIBUTE | AUDIT_VA | THEME | Theme 42 / ZATCA Forms | – | – | MAPPED | OLB visual attribute -> theme style |
| 527 | VISUAL_ATTRIBUTE | PROMPT_VA | THEME | Theme 42 / ZATCA Forms | – | – | MAPPED | OLB visual attribute -> theme style |
| 528 | VISUAL_ATTRIBUTE | TOOLTIP_VA | THEME | Theme 42 / ZATCA Forms | – | – | MAPPED | OLB visual attribute -> theme style |
| 529 | VISUAL_ATTRIBUTE | VA_SELECTED_REC | THEME | Theme 42 / ZATCA Forms | – | – | MAPPED | OLB visual attribute -> theme style |
| 530 | VISUAL_ATTRIBUTE | VA_NORMAL_REC | THEME | Theme 42 / ZATCA Forms | – | – | MAPPED | OLB visual attribute -> theme style |
| 531 | VISUAL_ATTRIBUTE | VA_SENT_REC | THEME | Theme 42 / ZATCA Forms | – | – | MAPPED | OLB visual attribute -> theme style |
| 532 | VISUAL_ATTRIBUTE | VA_UNSENT_REC | THEME | Theme 42 / ZATCA Forms | – | – | MAPPED | OLB visual attribute -> theme style |
| 533 | VISUAL_ATTRIBUTE | VA_RECIEVED_REC | THEME | Theme 42 / ZATCA Forms | – | – | MAPPED | OLB visual attribute -> theme style |
| 534 | GLOBAL | ARBC_IMPR_NAME | DA | Popup LOV + FOS Items to Return | 1140 | – | MAPPED | LOV-form return channel |
| 535 | GLOBAL | BUS_ID | DA | Popup LOV + FOS Items to Return | 1140 | – | MAPPED | LOV-form return channel |
| 536 | GLOBAL | BUS_ID_TYPE_CD | DA | Popup LOV + FOS Items to Return | 1140 | – | MAPPED | LOV-form return channel |
| 537 | GLOBAL | BUS_ID_TYPE_NAME | DA | Popup LOV + FOS Items to Return | 1140 | – | MAPPED | LOV-form return channel |
| 538 | GLOBAL | HQ_IMPR_NBR | DA | Popup LOV + FOS Items to Return | 1140 | – | MAPPED | LOV-form return channel |
| 539 | GLOBAL | HRMNZD_CODE | DA | Popup LOV + FOS Items to Return | 1140 | – | MAPPED | LOV-form return channel |
| 540 | GLOBAL | IMPR_TYPE_CD | DA | Popup LOV + FOS Items to Return | 1140 | – | MAPPED | LOV-form return channel |
| 541 | GLOBAL | PORT_CD | DA | Popup LOV + FOS Items to Return | 1140 | – | MAPPED | LOV-form return channel |
| 542 | GLOBAL | PORT_NAME | DA | Popup LOV + FOS Items to Return | 1140 | – | MAPPED | LOV-form return channel |
| 543 | GLOBAL | CG$HP_HFILE | – | – | – | – | DROPPED | Designer / frame / version stamp |
| 544 | GLOBAL | CG$HP_HPATH | – | – | – | – | DROPPED | Designer / frame / version stamp |
| 545 | GLOBAL | CG$QUERY_MODE | – | – | – | – | DROPPED | Designer / frame / version stamp |
| 546 | GLOBAL | CURRENT_DT | – | – | – | – | DROPPED | Designer / frame / version stamp |
| 547 | GLOBAL | CURRENT_VER | – | – | – | – | DROPPED | Designer / frame / version stamp |
| 548 | GLOBAL | CURRENT_VERSION | – | – | – | – | DROPPED | Designer / frame / version stamp |
| 549 | GLOBAL | EXIT | – | – | – | – | DROPPED | Designer / frame / version stamp |
| 550 | GLOBAL | SYSTEM_OBJ | – | – | – | – | DROPPED | Designer / frame / version stamp |
| 551 | CALLED_FORM | LOV_IMPORT_HQ_NBR | LOV | LOV_SINGLE_IMPORTERS | 1140 | – | MAPPED | CALL_FORM LOV form |
| 552 | CALLED_FORM | LOV_IMPORT_HQ_N12 | LOV | LOV_SINGLE_IMPORTERS (rule type 12) | 1140 | – | MAPPED | CALL_FORM LOV form |
| 553 | CALLED_FORM | LOV_TRF_ITEMS | LOV | LOV_HARMONIZED_TARIFF | 1140 | – | MAPPED | CALL_FORM LOV form |
| 554 | CALLED_FORM | LOV_SD_PORTS | LOV | LOV_SD_PORTS | 1140 | – | MAPPED | CALL_FORM LOV form |
| 555 | CALLED_FORM | LOV_Impr_Type | – | – | – | – | DROPPED | PU CALL_IMPR_TYPE is not called |
| 556 | CALLED_FORM | V_CALLED_FORM (EXECUTE_FUNCTION) | REGION | FUNCS (page 0) | 0 | – | MAPPED | Page Functions list |
| 557 | EXTERNAL | LIB_USR.SMS_MESSAGE.SEND_SMS_MESSAGE | PACKAGE | IMPR1140 send_rule_sms | – | IMPR1140.POST_INSERT | TODO | MISSING SOURCE |
| 558 | EXTERNAL | STR_DB message 1-270 | PACKAGE | FORMS_APX.ARABIC_MESSAGE(1, 270) | – | IMPR1140.KEY_DELREC | TODO | text from the message table |


## 15. Registry script

[registry/IMPR1140_registry.sql](../../registry/IMPR1140_registry.sql): one `MIG_FORM_REGISTRY` row (pages 1140–1140, package `IMPR1140`, COMPLEX, status DESIGN) and one `MIG_OBJECT_MAP` row per line of §14, generated by `work/IMPR1140/step03/build_trace.py`. Re-runnable (deletes the form's rows first). Not executed (CLAUDE.md §6.10).

## 16. Open items of this step

1. Texts to agree: ports insert with all ports, tariff delete, rule with tariff rows (inventory §15 #6, #8).
2. `HQ_IMPR_NBR VALIDATION` also runs on SAVE of an unchanged rule (Forms only validated a changed item): a rule of type 12 whose importer is not in the user's port cannot be saved from another port. Confirm, or limit the validation to a changed value.
3. SMS timing and resend on update (inventory §15 #2).
4. Popup LOV `LOV_SINGLE_IMPORTERS` for rule type 12 lists the importers of the user's port (inventory §15 #13).
