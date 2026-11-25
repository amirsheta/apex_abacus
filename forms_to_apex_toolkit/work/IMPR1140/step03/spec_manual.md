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
-- one search text over every shown column; no rows until a search is made (Forms opens in Enter-Query);
-- the PRE-QUERY BUS_ID_TYPE_NAME criterion is part of the text search (join, no concatenated SQL).
-- No ORDER BY (as IMPR1120, user request 2026-11-23); the grid columns can be sorted.
SELECT TRANSLATE(ROWIDTOCHAR(r.ROWID), '+/', '-_') AS row_id,
       r.rule_isn, r.rule_type, rt.rv_meaning AS rule_type_name,
       r.all_brnch_flag, DECODE(r.all_brnch_flag, 1, 'جميع الجمارك', 0, 'جمرك محدد') AS all_brnch_flag_name,
       r.hq_impr_nbr,
       CASE WHEN r.rule_type = 12
            THEN (SELECT MAX(i.arbc_impr_name) FROM importers i
                   WHERE i.port_cd = :P_CURR_PORT_CD AND i.hq_impr_nbr = r.hq_impr_nbr)
            ELSE (SELECT MAX(s.arbc_impr_name) FROM single_importers s WHERE s.hq_impr_nbr = r.hq_impr_nbr)
       END AS l_si_arbc_impr_name,
       r.bus_id_type_cd, b.bus_id_type_name, r.bus_id, r.bus_id_brnch,
       r.rec_status, rs.rv_meaning AS rec_status_name
  FROM impr_rules r, bus_id_types b, cg_ref_codes rt, cg_ref_codes rs
 WHERE :P114001_SEARCH IS NOT NULL
   AND b.bus_id_type_cd (+) = r.bus_id_type_cd
   AND rt.rv_domain (+) = 'RULE_TYPE'  AND rt.rv_low_value (+) = TO_CHAR(r.rule_type)
   AND rs.rv_domain (+) = 'REC_STATUS' AND rs.rv_low_value (+) = TO_CHAR(r.rec_status)
   AND INSTR(UPPER(r.rule_isn || '|' || r.rule_type || '|' || rt.rv_meaning || '|' || r.hq_impr_nbr || '|' ||
                   b.bus_id_type_name || '|' || r.bus_id || '|' || r.bus_id_brnch || '|' || rs.rv_meaning),
             UPPER(TRIM(:P114001_SEARCH))) > 0
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

<!-- TRACE -->

## 15. Registry script

[registry/IMPR1140_registry.sql](../../registry/IMPR1140_registry.sql): one `MIG_FORM_REGISTRY` row (pages 1140–1140, package `IMPR1140`, COMPLEX, status DESIGN) and one `MIG_OBJECT_MAP` row per line of §14, generated by `work/IMPR1140/step03/build_trace.py`. Re-runnable (deletes the form's rows first). Not executed (CLAUDE.md §6.10).

## 16. Open items of this step

1. Texts to agree: ports insert with all ports, tariff delete, rule with tariff rows (inventory §15 #6, #8).
2. `HQ_IMPR_NBR VALIDATION` also runs on SAVE of an unchanged rule (Forms only validated a changed item): a rule of type 12 whose importer is not in the user's port cannot be saved from another port. Confirm, or limit the validation to a changed value.
3. SMS timing and resend on update (inventory §15 #2).
4. Popup LOV `LOV_SINGLE_IMPORTERS` for rule type 12 lists the importers of the user's port (inventory §15 #13).
