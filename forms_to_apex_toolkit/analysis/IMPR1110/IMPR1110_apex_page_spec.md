# IMPR1110 – APEX 21.2 Page Specification (Step 03)

| Item | Value |
|---|---|
| Form | IMPR1110 (module `IMPR1110_PROD_CENTRL`) – "إضافة وتعديل بيانات مستورد" |
| Inputs | `analysis/IMPR1110/IMPR1110_inventory.md`, `analysis/IMPR1110/IMPR1110_logic_extraction.md`, `plsql/IMPR1110/pkg_impr1110_spec.sql`, `plsql/IMPR1110/pkg_impr1110_apx_spec.sql`, LOV forms in `forms/COMMON/lov_forms/` |
| Application ID | **2000 – PLACEHOLDER** (the real IMPR application id is not known; see §16 Q1) |
| Page range | 1110–1119 (`MIG_FORM_REGISTRY`), main page alias `IMPR1110` |
| Page group | `IMPR` (Forms application IMPR / subsystem IMPORTERS) |
| Theme | Universal Theme 42, Right-to-Left (application language Arabic) |
| Authorization | Page: `IMPR1110_ACCESS`; function menu: `FUN_<CODE>` (§13.3) |
| Outputs | this file + `registry/IMPR1110_registry.sql` |
| Replaces | `apex/IMPR1110/IMPR1110_page_spec.md` (v0, written against the summary-based package) → `rollback/IMPR1110/IMPR1110_page_spec_v0.md` |
| Status | Design only. **No APEX export generated** (step 04). Packages written, **not compiled**. |
| Date | 2026-11-18 – Claude Code |

---

## 0. Forms-mirror decisions that shape the whole page

1. **One base-table block, single record.** `IMPORTERS` is the only data block, with no
   relations and no tab canvas. Everything sits on canvas `CG$PAGE_1` of window `CGSO$WINDOW_1`.
   → One Normal page **1110**. Region Static ID `IMPORTERS`. Items keep the Forms names
   `P1110_<ITEM>` and the Forms canvas layout (rows/columns derived from X/Y of the XML, §4).
2. **Region type = Static Content with page items, not a native Form region with Automatic Row
   Processing.** The template allows this when justified ("Target Type = PL/SQL Code"). Reasons:
   * The Forms trigger order PRE-INSERT → default INSERT → POST-INSERT (and UPDATE) must run in
     `pkg_impr1110`, including the `Create_Uni_IMPR_NEBRAS` call before the INSERT.
   * The key is the **ROWID**, because `PORT_CD` itself changes (B_EMAIL/B_MOBILE_NO/B_ID_NBR
     POST-CHANGE). ARP would update by `(PORT_CD, IMPR_NBR)`.
   * 25 non-database items and 3 "screen copies" (`B_EMAIL`, `B_MOBILE_NO`, `B_ID_NBR`) are
     written to other columns or tables.
   * Fetch is POST-QUERY logic (suspension status, CGFK lookups), not a plain row fetch.
   All DML goes through `pkg_impr1110_apx.page_dml`.
3. **Item-level validation like Forms.** Forms validates an item when the user leaves it, then
   re-validates changed items when the record is committed. APEX does the same:
   * An AJAX call on change runs POST-CHANGE + WHEN-VALIDATE-ITEM.
   * At SAVE, one APEX Validation per item calls `pkg_impr1110_apx.validate_on_submit`.
     This re-runs the trigger **only if the value differs from the last value the server
     validated**. Several validations consume sequences, so they must not run twice.
   * The server keeps this state in collection `COL_IMPR1110_STATE`. The browser cannot skip
     validation, because the server checks again at SAVE.
4. **Who can change what.** Only items the user can type into are submitted. Every display item,
   hidden item and control item is *Display Only, Send On Page Submit = No*. Its value lives only
   in session state, written by the server, so it cannot be tampered with and stale page values
   never overwrite server values.
5. **UI state.** `Make_Field_Entrable` / `SET_ITEM_PROPERTY` / `GO_ITEM` are recorded by the
   package (`ui_json`) and applied by **one** JavaScript function. The server also keeps
   ENTRABLE/REQUIRED, which is used for the required check at SAVE and for
   `GET_ITEM_PROPERTY(…, ENABLED)`.
6. **LOV forms → Shared LOVs.** The form's own CGFK record-group LOVs are bypassed by KEY-LISTVAL
   triggers that call LOV *forms*. The APEX LOVs are therefore built from the LOV forms'
   block query (`forms/COMMON/lov_forms/*.xml`), with the parameters IMPR1110 passes.

---

## 1. Page type decision per block

| Forms block | Characteristics (XML) | APEX 21.2 choice | Reasoning |
|---|---|---|---|
| `IMPORTERS` | base table `IMPORTERS`, single record on screen (canvas CG$PAGE_1), Insert/Update/Query, `DeleteAllowed=false` but KEY-DELREC deletes, WHERE `PORT_CD = :PARAMETER.P_CURR_PORT_CD`, ORDER BY `IMPR_NBR DESC` | Static Content region `IMPORTERS` + PL/SQL DML (page 1110); search = Interactive Report on modal page 1111 | §0 items 2–4. Enter-Query/Execute-Query of a single-record block → search dialog that returns the importer number |
| `TOOLBAR` (OLB) | control block, toolbar buttons | Buttons Container region `TOOLBAR` | Standard buttons SAVE · CREATE · DELETE · QUERY · CLEAR · EXIT + FUNCTIONS menu |
| `LSIDE` (OLB) | 50 side-menu buttons (TMPLT function menu) | List region `IMPORTERS_FUNS` (template *Menu Popup*) opened by button `FUNCTIONS` | KEY-F9 / FUN_BUT toggled the side menu |
| `TITLE` (OLB) | title bar (user, screen, Hijri date) | dropped – APEX page title + navigation bar | no business logic |
| `EDI_MSG` (OLB) | EDI message ticker (units not called) | dropped | timers/EDI units are not called (step 02 §7.1) |

Called forms used as dialogs → modal pages (§2).

---

## 2. Pages

| Page | Name / title | Alias | Mode | Source (Forms) | Authorization | Navigation menu |
|---|---|---|---|---|---|---|
| 1110 | إضافة وتعديل بيانات مستورد | `IMPR1110` | Normal | IMPR1110.fmb – window `CGSO$WINDOW_1` (title "Importers"), canvas `CG$PAGE_1` | `IMPR1110_ACCESS` | Yes – under the IMPR menu group, same position as in `CIC_MENU` (**MISSING SOURCE**, §16 Q4). Link clears cache of page 1110 (= open the form) |
| 1111 | بحث عن مستورد | `IMPR1110_QUERY` | Modal Dialog | Enter-Query / Execute-Query of block IMPORTERS (TOOLBAR.RE_ENTER_QUERY / ENTER / EXECUTE) | `IMPR1110_ACCESS` | No |
| 1112 | تعديل رقم الجوال | `IMPR1110_MOBILE` | Modal Dialog | called form `LOV_UPDATE_IMPR_MOBILE` (function `IMPR1110_MOB`) | `FUN_IMPR1110_MOB` | No |
| 1113 | (support letter) | `IMPR1110_SUPPORT` | Modal Dialog | called form `SUPPORT_ENTRY` (functions IMPR1110F1/F2/F3/F5) – **MISSING SOURCE**, page reserved | `IMPR1110_ACCESS` | No |
| 1114–1119 | – | – | reserved | – | – | – |

Page properties of 1110: Comments `Source: IMPR1110.fmb (window CGSO$WINDOW_1, canvas CG$PAGE_1)`.
"Warn on Unsaved Changes" = Yes. Page Template *Standard*. Text direction is RTL from the
application language. Session State Protection: *Arguments Must Have Checksum*.
JavaScript file: `#APP_FILES#impr1110#MIN#.js` (step 04, behaviour in §10).

---

## 3. Regions

### Page 1110

| Seq | Region (Static ID) | Type | Source | Primary key | Template | Position / parent | Edit | Source Forms block |
|---|---|---|---|---|---|---|---|---|
| 10 | `TOOLBAR` | Static Content (buttons only) | – | – | Buttons Container | Body, top (Forms toolbar) | – | `TOOLBAR` |
| 20 | `IMPORTERS` | Static Content with page items | none – session state is managed by `pkg_impr1110_apx` | `P1110_ROW_ID` (ROWID, server only) | Standard; title "إضافة وتعديل بيانات مستورد" (frame title not in XML) | Body | Insert / Update / Delete via `page_dml` | `IMPORTERS` |
| 30 | `IMPORTERS_FUNS` | List (`LIST_IMPR1110_FUNS`) | Static list, §13.4 | – | Menu Popup (opened by button `FUNCTIONS`) | Body, after TOOLBAR | – | `LSIDE` (TMPLT side menu) |

The block's WHERE clause is applied in `pkg_impr1110_apx.load_row`
(`WHERE port_cd = :AI_P_CURR_PORT_CD`), never in the browser.

### Page 1111 – IMPR1110_QUERY

| Seq | Region | Type | Source | Template | Notes |
|---|---|---|---|---|---|
| 10 | `IMPORTERS_QRY` | Static Content | items `P1111_ARBC_IMPR_NAME` (search by name) | Standard | PRE-QUERY name criterion |
| 20 | `IMPORTERS` | Interactive Report | SQL below | Standard | IR search/filters = Forms query-by-example on the other items |

```sql
SELECT i.impr_nbr, i.arbc_impr_name, i.eng_impr_name, i.bus_id, i.bus_id_brnch,
       i.impr_type_cd, it.impr_type_name, i.bus_id_type_cd, i.ctry_cd, i.hq_impr_nbr
  FROM importers i, impr_types it
 WHERE i.port_cd = :AI_P_CURR_PORT_CD                               -- block WHERE clause
   AND it.impr_type_cd (+) = i.impr_type_cd
   AND (:P1111_PRSNL_IMPR IS NULL OR :P1111_PRSNL_IMPR <> 1 OR i.impr_type_cd = 4)   -- PRE-QUERY
   AND (:P1111_ARBC_IMPR_NAME IS NULL
        OR i.impr_name_std LIKE (SELECT str_db.strformat(:P1111_ARBC_IMPR_NAME, TRUE) FROM dual))  -- PRE-QUERY
 ORDER BY i.impr_nbr DESC                                           -- block ORDER BY
```

* `P1111_PRSNL_IMPR` is passed from `P1110_PRSNL_IMPR` in the link (checksum).
* Forms QBE uses `=` unless the value contains `%`. `LIKE` gives the same result, except that
  `_` is also a wildcard – accepted.
* `str_db.strformat(…, TRUE)` – 2-argument overload to verify (step 02 TODO 8).
* Link column `IMPR_NBR` → JavaScript `apex.navigation.dialog.close(true, {IMPR_NBR: #IMPR_NBR#})`.
  The parent DA (§10, DA 13) puts it into `P1110_IMPR_NBR` and submits `QUERY_NBR`.

### Page 1112 – IMPR1110_MOBILE (LOV_UPDATE_IMPR_MOBILE)

| Seq | Region | Type | Items | Notes |
|---|---|---|---|---|
| 10 | `BLK` | Static Content | `P1112_MOBILE_NO` (Text Field, label "رقم الجوال"), `P1112_IMPR_NBR` (Hidden, value protected, from link) | `BLK.WHEN-NEW-BLOCK-INSTANCE`: `MOBILE_NO := :PARAMETER.P_CENTRAL_MOBILE` → Before Header computation `P1112_MOBILE_NO := pkg_impr1110_apx.central_mobile(:P1112_IMPR_NBR)` (when null) |
| 20 | `CTRL_BLK` | Buttons Container | `PB_OK` (Submit `OK`), `PB_CANCEL` (Cancel Dialog) | `PB_OK`: `:GLOBAL.OK := 1; COPY_SELECTED_VALUES` → process `CTRL_BLK.PB_OK.WHEN-BUTTON-PRESSED`: `pkg_forms_compat.set_global('MOBILE_NO', :P1112_MOBILE_NO)` + Close Dialog. `PB_CANCEL` → `pkg_forms_compat.set_global('MOBILE_NO', NULL)` + Close Dialog (Forms CANCEL_LOV_FORM – MISSING SOURCE; clearing avoids a stale `:GLOBAL.MOBILE_NO`) |

### Page 1113 – IMPR1110_SUPPORT (SUPPORT_ENTRY)

Reserved. The form `SUPPORT_ENTRY` is **MISSING SOURCE**. Contract known from IMPR1110:
* Input: `P_MODE = 0`, `P_CURR_PORT_CD = :IMPORTERS.PORT_CD`.
* On OK it must set `AI_LETTER_NBR`, `AI_SUPP_TITLE_CD`, `AI_LETTER_DT` and `AI_PORT_CD`, then
  close. These are read by `exec_funs` and by the PRE-UPDATE journaling.

Design it when `SUPPORT_ENTRY.fmb` is available (§16 Q3).

---

## 4. Items (page 1110, region `IMPORTERS`)

Generated from the XML (item order, prompts, max length, required, defaults, masks, canvas X/Y).
*Seq / layout* = sequence, "Start New Row", column and column span on the 12-column grid. These
are taken from the Forms canvas: items on the same Forms line form one row, ordered by X. In RTL
the first column is on the right, as in the form.
Rules applied:
* Every item the user can type into is submitted.
* Every other item is *Display Only, Send On Page Submit = No* (§0.4).
* Items not on the canvas get the CSS class `u-hidden`.
* The 11 LOV buttons (`…2`, `BUTT`, `BRNH_CITY_CD_LOV`) are not items: the Popup LOV / Select
  List has its own control.
* Value Required = Yes only for Forms *Required* items. The required state that changes at runtime
  is applied by the UI-state DA and checked at SAVE by `IMPORTERS.REQUIRED-ITEMS`.
* Hijri dates stay **Text Fields** holding a `DATE` with mask `MI-MM-YYYY`, exactly as in Forms
  (minutes used as day – kept, step 02 §7.4 Q4). The Hijri calendar of KEY-F4 is open (§16 Q5).

| Page item | Column | Type | Label (Forms prompt) | Value required | Format mask | Default | LOV | Cascading parent(s) | Max length | Seq / layout | Session State Protection | Source Forms item (OLB subclass) | Notes |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `P1110_SDP_PORT_STATUS` | - | Display Only, CSS u-hidden (Send On Page Submit = No) | - | No | - | Static: 1 | - | - | 2 | 1010 / hidden | n/a (not submitted, server value only) | `IMPORTERS.SDP_PORT_STATUS` (CGSO$NUMBER_MD) |  |
| `P1110_L_CT_CITY_STATUS2` | - | Display Only, CSS u-hidden (Send On Page Submit = No) | - | No | - | - | - | - | 2 | 1020 / hidden | n/a (not submitted, server value only) | `IMPORTERS.L_CT_CITY_STATUS2` (CGSO$NUMBER_MD) |  |
| `P1110_L_CT_CITY_STATUS` | - | Display Only, CSS u-hidden (Send On Page Submit = No) | - | No | - | - | - | - | 2 | 1030 / hidden | n/a (not submitted, server value only) | `IMPORTERS.L_CT_CITY_STATUS` (CGSO$NUMBER_MD) |  |
| `P1110_PORT_CD` | PORT_CD | Popup LOV (manual entry allowed, display = code) | رمز الجمــــــــــــــرك | Yes (Forms Required) | - | - | LOV_SD_PORTS | - | 4 | 10 / row Yes / col 1 span 1 | Unrestricted | `IMPORTERS.PORT_CD` (CGSO$CHAR_ARB) | disabled by WHEN-NEW-FORM-INSTANCE |
| `P1110_PORT_NAME` | - | Display Only (Send On Page Submit = No) | - | No | - | - | - | - | 40 | 20 / row No / col 2 span 5 | n/a (not submitted) | `IMPORTERS.PORT_NAME` (CGSO$CHAR_EN_DO_MLINE) |  |
| `P1110_HQ_IMPR_NBR` | HQ_IMPR_NBR | Display Only (Send On Page Submit = No) | الرقم الموحد بالمصلحة | No | - | - | - | - | 11 | 30 / row No / col 10 span 1 | n/a (not submitted) | `IMPORTERS.HQ_IMPR_NBR` (CGSO$CHAR_ARB_DO) |  |
| `P1110_IMPR_NBR` | IMPR_NBR | Number Field | الرقــــــم الجمركــــى | No | - | - | - | - | 11 | 40 / row Yes / col 1 span 1 | Unrestricted | `IMPORTERS.IMPR_NBR` (CGSO$CHAR_ARB) |  |
| `P1110_SUSPN_STATUS` | - | Display Only (Send On Page Submit = No) | حالة المستورد بالمصلحة | No | - | - | - | - | - | 50 / row No / col 5 span 2 | n/a (not submitted) | `IMPORTERS.SUSPN_STATUS` (CGSO$CHAR_ARB) |  |
| `P1110_STATUS_DESC` | - | Display Only (Send On Page Submit = No) | حالة المستورد بالوزارة | No | - | - | - | - | - | 60 / row No / col 9 span 2 | n/a (not submitted) | `IMPORTERS.STATUS_DESC` (CGSO$CHAR_ARB_DO) |  |
| `P1110_BUS_ID_STATUS` | BUS_ID_STATUS | Display Only, CSS u-hidden (Send On Page Submit = No) | - | No | - | - | - | - | 2 | 1040 / hidden | n/a (not submitted, server value only) | `IMPORTERS.BUS_ID_STATUS` (CGSO$COMBO_DO) |  |
| `P1110_IMPR_TYPE_CD` | IMPR_TYPE_CD | Popup LOV (manual entry allowed, display = code) | رمز النشاط التجارى | Yes (Forms Required) | - | - | LOV_IMPR_TYPE | - | 4 | 70 / row Yes / col 1 span 1 | Unrestricted | `IMPORTERS.IMPR_TYPE_CD` (CGSO$CHAR_ARB) | LOV form LOV_Impr_Type (type part) |
| `P1110_IMPR_TYPE_NAME` | - | Display Only (Send On Page Submit = No) | - | No | - | - | - | - | 40 | 80 / row No / col 2 span 5 | n/a (not submitted) | `IMPORTERS.IMPR_TYPE_NAME` (CGSO$CHAR_ARB_DO) |  |
| `P1110_BUS_ID_EXPRD_DT` | BUS_ID_EXPRD_DT | Text Field (Hijri) | إنـتهـاء الـنشاط | No | MI-MM-YYYY | - | - | - | 10 | 90 / row No / col 9 span 2 | Unrestricted | `IMPORTERS.BUS_ID_EXPRD_DT` (CGSO$HDATE_ARB) | Hijri DATE, mask MI-MM-YYYY as in Forms (placeholder "يوم-شهر-سنة") |
| `P1110_BUS_ID_TYPE_CD` | BUS_ID_TYPE_CD | Select List | نوع الرقم الإستدلالي | Yes (Forms Required) | - | - | LOV_IMPR_TYPE_BUS_ID | P1110_IMPR_TYPE_CD | 4 | 100 / row Yes / col 1 span 1 | Unrestricted | `IMPORTERS.BUS_ID_TYPE_CD` (CGSO$CHAR_ARB_DO) | bus-id-type part of LOV_Impr_Type (Forms: display item + LOV button BUTT) |
| `P1110_BUS_ID_TYPE_NAME` | - | Display Only (Send On Page Submit = No) | - | No | - | - | - | - | 40 | 110 / row No / col 2 span 3 | n/a (not submitted) | `IMPORTERS.BUS_ID_TYPE_NAME` (CGSO$CHAR_ARB_DO) |  |
| `P1110_COMM_RGSTRTN_TYPE` | COMM_RGSTRTN_TYPE | Select List | نوع السجل التجاري | No | - | - | LOV_COMM_RGSTRTN_TYPE | - | 2 | 120 / row No / col 9 span 2 | Unrestricted | `IMPORTERS.COMM_RGSTRTN_TYPE` (CGSO$CHAR_ARB) | list item, CG_REF_CODES |
| `P1110_CITY_CODE_OF_ID` | CITY_CODE_OF_ID | Popup LOV (manual entry allowed, display = code) | مصدررقم الإستدلالي | No | - | - | LOV_CITIES_IMP_ID | P1110_IMPR_TYPE_CD, P1110_BUS_ID_TYPE_CD, P1110_CTRY_CD | 4 | 130 / row Yes / col 1 span 1 | Unrestricted | `IMPORTERS.CITY_CODE_OF_ID` (CGSO$CHAR_ARB) | LOV form LOV_CITIES_IMP |
| `P1110_ID_CITY_NAME` | - | Display Only (Send On Page Submit = No) | - | No | - | - | - | - | 20 | 140 / row No / col 2 span 3 | n/a (not submitted) | `IMPORTERS.ID_CITY_NAME` (CGSO$CHAR_ARB_DO) |  |
| `P1110_BUS_ID` | BUS_ID | Text Field | الـرقم الإستدلالي | Yes (Forms Required) | - | - | - | - | 15 | 150 / row No / col 9 span 2 | Unrestricted | `IMPORTERS.BUS_ID` (CGSO$CHAR_ARB) | REQUIRED switched off by BUS_ID.WHEN-NEW-ITEM-INSTANCE |
| `P1110_BRNH_ID_MINS_COMM_CD` | - | Display Only, CSS u-hidden (Send On Page Submit = No) | - | No | - | - | - | - | - | 1050 / hidden | n/a (not submitted, server value only) | `IMPORTERS.BRNH_ID_MINS_COMM_CD` (CGSO$CHAR) |  |
| `P1110_BRNH_CITY_CD` | - | Popup LOV (manual entry allowed, display = code) | مصدر الرقم الفرعي | No | - | - | LOV_CITIES_IMP_BRNH | P1110_CTRY_CD | - | 160 / row Yes / col 1 span 1 | Unrestricted | `IMPORTERS.BRNH_CITY_CD` (CGSO$CHAR_ARB_DO) | LOV form LOV_CITIES_IMP |
| `P1110_BRNH_CITY_NAME` | - | Display Only (Send On Page Submit = No) | - | No | - | - | - | - | - | 170 / row No / col 2 span 3 | n/a (not submitted) | `IMPORTERS.BRNH_CITY_NAME` (CGSO$CHAR_ARB_DO) |  |
| `P1110_BUS_ID_BRNCH` | BUS_ID_BRNCH | Text Field | الـرقم الــفــرعي | No | - | - | - | - | 10 | 180 / row No / col 9 span 2 | Unrestricted | `IMPORTERS.BUS_ID_BRNCH` (CGSO$CHAR_ARB_DO) |  |
| `P1110_CTRY_CD` | CTRY_CD | Popup LOV (manual entry allowed, display = code) | دولة الرقم الإستدلالي | Yes (Forms Required) | - | - | LOV_CTRY_CD (inline) | P1110_IMPR_TYPE_CD, P1110_BUS_ID_TYPE_CD | 4 | 190 / row Yes / col 1 span 1 | Unrestricted | `IMPORTERS.CTRY_CD` (CGSO$CHAR_ARB) | LOV_COUNTRIES or LOV_COUNTRIES_GULF |
| `P1110_CRTY_ARBC_NAME` | - | Display Only (Send On Page Submit = No) | - | No | - | - | - | - | 50 | 200 / row No / col 2 span 3 | n/a (not submitted) | `IMPORTERS.CRTY_ARBC_NAME` (CGSO$CHAR_ARB_DO) |  |
| `P1110_IMPR_EXPR_TYPE` | IMPR_EXPR_TYPE | Select List | النشاط الجمركي | Yes (Forms Required) | - | Static: 2 | LOV_ALLOWED_EXPORT | - | - | 210 / row No / col 9 span 2 | Unrestricted | `IMPORTERS.IMPR_EXPR_TYPE` (CGSO$CHAR_ARB) | list item, CG_REF_CODES |
| `P1110_CTRY_CTRY_STATUS` | - | Display Only, CSS u-hidden (Send On Page Submit = No) | - | No | - | Static: 1 | - | - | 2 | 1060 / hidden | n/a (not submitted, server value only) | `IMPORTERS.CTRY_CTRY_STATUS` (CGSO$NUMBER_MD) |  |
| `P1110_ID_MINS_COMM_CD` | - | Display Only, CSS u-hidden (Send On Page Submit = No) | - | No | - | - | - | - | 5 | 1070 / hidden | n/a (not submitted, server value only) | `IMPORTERS.ID_MINS_COMM_CD` (CGSO$NUMBER_MD) |  |
| `P1110_ITIDT_NOTE` | - | Display Only, CSS u-hidden (Send On Page Submit = No) | - | No | - | - | - | - | 200 | 1080 / hidden | n/a (not submitted, server value only) | `IMPORTERS.ITIDT_NOTE` (CGSO$CHAR_MD) |  |
| `P1110_ARBC_IMPR_NAME` | ARBC_IMPR_NAME | Text Field | الاســــم العربــــــــى | Yes (Forms Required) | - | - | - | - | 200 | 220 / row Yes / col 1 span 10 | Unrestricted | `IMPORTERS.ARBC_IMPR_NAME` (CGSO$CHAR_ARB) |  |
| `P1110_IMPR_NAME_STD` | IMPR_NAME_STD | Display Only, CSS u-hidden (Send On Page Submit = No) | - | No | - | - | - | - | 200 | 1090 / hidden | n/a (not submitted, server value only) | `IMPORTERS.IMPR_NAME_STD` (CGSO$CHAR_MD) |  |
| `P1110_LST_TRAN_DT` | LST_TRAN_DT | Display Only, CSS u-hidden (Send On Page Submit = No) | - | No | - | - | - | - | - | 1100 / hidden | n/a (not submitted, server value only) | `IMPORTERS.LST_TRAN_DT` (CGSO$DATE) |  |
| `P1110_IMPD_STMT_NBR` | IMPD_STMT_NBR | Display Only, CSS u-hidden (Send On Page Submit = No) | - | No | - | - | - | - | 10 | 1110 / hidden | n/a (not submitted, server value only) | `IMPORTERS.IMPD_STMT_NBR` (CGSO$NUMBER) |  |
| `P1110_IMPR_DATA_SRCE` | IMPR_DATA_SRCE | Display Only, CSS u-hidden (Send On Page Submit = No) | - | No | - | - | - | - | 7 | 1120 / hidden | n/a (not submitted, server value only) | `IMPORTERS.IMPR_DATA_SRCE` (CGSO$NUMBER) |  |
| `P1110_ENG_IMPR_NAME` | ENG_IMPR_NAME | Text Field (dir=ltr) | الاســــم الأجنبـــــــي | No | - | - | - | - | 200 | 230 / row Yes / col 1 span 5 | Unrestricted | `IMPORTERS.ENG_IMPR_NAME` (CGSO$CHAR_EN) |  |
| `P1110_IMPR_CNTCT_NAME` | IMPR_CNTCT_NAME | Text Field | الوكيل المفوض | No | - | - | - | - | 200 | 240 / row No / col 7 span 4 | Unrestricted | `IMPORTERS.IMPR_CNTCT_NAME` (CGSO$CHAR_ARB) |  |
| `P1110_IMPR_ADDRESS` | IMPR_ADDRESS | Text Field | الــعـــــــنـــــــوان | No | - | - | - | - | 2000 | 250 / row Yes / col 1 span 6 | Unrestricted | `IMPORTERS.IMPR_ADDRESS` (CGSO$CHAR_ARB) |  |
| `P1110_BUS_ID_ISSUE_DT` | BUS_ID_ISSUE_DT | Display Only (Send On Page Submit = No) | تاريخ انشاء النشاط | No | MI-MM-YYYY | - | - | - | 10 | 260 / row No / col 9 span 2 | n/a (not submitted) | `IMPORTERS.BUS_ID_ISSUE_DT` (CGSO$HDATE_ARB_DO) | Hijri DATE, mask MI-MM-YYYY as in Forms (placeholder "يوم-شهر-سنة") |
| `P1110_STATUS` | - | Display Only, CSS u-hidden (Send On Page Submit = No) | - | No | - | Static: 1 | - | - | 2 | 1130 / hidden | n/a (not submitted, server value only) | `IMPORTERS.STATUS` (CGSO$CHECK_BOX_MD) |  |
| `P1110_IMPR_NBR_PARENT` | IMPR_NBR_PARENT | Popup LOV (manual entry allowed, display = code) | تابــع الـــــــــــــــــى | No | - | - | LOV_IMPR | - | 11 | 270 / row Yes / col 1 span 2 | Unrestricted | `IMPORTERS.IMPR_NBR_PARENT` (CGSO$CHAR_ARB) | LOV form LOV_IMPR |
| `P1110_IMPR_NAME_PARENT` | - | Display Only (Send On Page Submit = No) | - | No | - | - | - | - | - | 280 / row No / col 3 span 3 | n/a (not submitted) | `IMPORTERS.IMPR_NAME_PARENT` (CGSO$CHAR_ARB_DO) |  |
| `P1110_WASL_CITY_NAME` | - | Display Only (Send On Page Submit = No) | المدينة | No | - | - | - | - | - | 290 / row No / col 9 span 3 | n/a (not submitted) | `IMPORTERS.WASL_CITY_NAME` (CGSO$CHAR_ARB_DO) |  |
| `P1110_ADD_CTRY_CD` | ADD_CTRY_CD | Popup LOV (manual entry allowed, display = code) | دولــــــــة الإقامـــــة | Yes (Forms Required) | - | - | LOV_COUNTRIES | - | 4 | 300 / row Yes / col 1 span 1 | Unrestricted | `IMPORTERS.ADD_CTRY_CD` (CGSO$CHAR_ARB) | LOV form LOV_COUNTRIES |
| `P1110_ADD_CRTY_ARBC_NAME` | - | Display Only (Send On Page Submit = No) | - | No | - | - | - | - | 50 | 310 / row No / col 2 span 3 | n/a (not submitted) | `IMPORTERS.ADD_CRTY_ARBC_NAME` (CGSO$CHAR_ARB_DO) |  |
| `P1110_CITY_CODE` | CITY_CODE | Popup LOV (manual entry allowed, display = code) | المدينـة | No | - | - | LOV_CITIES | P1110_ADD_CTRY_CD | 4 | 320 / row No / col 7 span 1 | Unrestricted | `IMPORTERS.CITY_CODE` (CGSO$CHAR_ARB) | LOV form LOV_CITIES |
| `P1110_CITY_NAME` | - | Display Only (Send On Page Submit = No) | - | No | - | - | - | - | 20 | 330 / row No / col 8 span 3 | n/a (not submitted) | `IMPORTERS.CITY_NAME` (CGSO$CHAR_ARB_DO) |  |
| `P1110_IMPR_POB_NBR` | IMPR_POB_NBR | Number Field | صنــــدوق بريــــــــد | No | - | - | - | - | 9 | 340 / row Yes / col 1 span 2 | Unrestricted | `IMPORTERS.IMPR_POB_NBR` (CGSO$CHAR_ARB) |  |
| `P1110_IMPR_ZIP_CD` | IMPR_ZIP_CD | Number Field | رمز بريدي | No | - | - | - | - | 11 | 350 / row No / col 4 span 2 | Unrestricted | `IMPORTERS.IMPR_ZIP_CD` (CGSO$CHAR_ARB) |  |
| `P1110_IMPR_TEL_NBR` | IMPR_TEL_NBR | Text Field | تليفـون | No | - | - | - | - | 15 | 360 / row No / col 7 span 2 | Unrestricted | `IMPORTERS.IMPR_TEL_NBR` (CGSO$CHAR_ARB) |  |
| `P1110_IMPR_FAX_NBR` | IMPR_FAX_NBR | Text Field | فاكــس | No | - | - | - | - | 15 | 370 / row No / col 10 span 2 | Unrestricted | `IMPORTERS.IMPR_FAX_NBR` (CGSO$CHAR_ARB) |  |
| `P1110_IMPR_TELEX_NBR` | IMPR_TELEX_NBR | Text Field | تلكـــــــــــــــــــــــس | No | - | - | - | - | 16 | 380 / row Yes / col 1 span 3 | Unrestricted | `IMPORTERS.IMPR_TELEX_NBR` (CGSO$CHAR_ARB) |  |
| `P1110_B_EMAIL` | - | Text Field (subtype E-Mail, dir=ltr) | بريــد إلكترونى | No | - | - | - | - | 200 | 390 / row No / col 6 span 6 | Unrestricted | `IMPORTERS.B_EMAIL` (CGSO$EMAIL) |  |
| `P1110_EMAIL` | EMAIL | Display Only, CSS u-hidden (Send On Page Submit = No) | - | No | - | - | - | - | - | 1140 / hidden | n/a (not submitted, server value only) | `IMPORTERS.EMAIL` (CGSO$EMAIL) |  |
| `P1110_B_MOBILE_NO` | - | Text Field (subtype Phone) | رقم الجوال | No | - | - | - | - | 31 | 400 / row Yes / col 1 span 3 | Unrestricted | `IMPORTERS.B_MOBILE_NO` (CGSO$CHAR_EN) |  |
| `P1110_MOBILE_NO` | MOBILE_NO | Display Only, CSS u-hidden (Send On Page Submit = No) | - | No | - | - | - | - | 31 | 1150 / hidden | n/a (not submitted, server value only) | `IMPORTERS.MOBILE_NO` (CGSO$NUMBER) |  |
| `P1110_BANK_IBAN` | BANK_IBAN | Text Field (dir=ltr, upper case) | رقم حسـاب آيبان | No | - | - | - | - | 60 | 410 / row No / col 6 span 6 | Unrestricted | `IMPORTERS.BANK_IBAN` (CGSO$CHAR) |  |
| `P1110_B_ID_NBR` | - | Text Field | رقم هويه المستورد | No | - | - | - | - | 15 | 420 / row Yes / col 1 span 3 | Unrestricted | `IMPORTERS.B_ID_NBR` (CGSO$CHAR) |  |
| `P1110_ID_NBR` | ID_NBR | Display Only, CSS u-hidden (Send On Page Submit = No) | - | No | - | - | - | - | 15 | 1160 / hidden | n/a (not submitted, server value only) | `IMPORTERS.ID_NBR` (CGSO$CHAR) |  |
| `P1110_CAR_AGENT_FLAG` | CAR_AGENT_FLAG | Select List | وكيـــل سيـــارات؟ | No | - | Static: 0 | LOV_CAR_AGENT_FLAG | - | 2 | 430 / row No / col 6 span 3 | Unrestricted | `IMPORTERS.CAR_AGENT_FLAG` (CGSO$POP_DO) | pop list, static values |
| `P1110_EXPRESS_POST` | EXPRESS_POST | Select List | بريد سريع | No | - | Static: 0 | LOV_EXPRESS_POST | - | 1 | 440 / row No / col 10 span 1 | Unrestricted | `IMPORTERS.EXPRESS_POST` (CGSO$CHAR_ARB) | list item, static values |
| `P1110_IMPR_ID_TYPE` | - | Display Only (Send On Page Submit = No) | نوع الاقامة | No | - | - | - | - | - | 450 / row Yes / col 1 span 6 | n/a (not submitted) | `IMPORTERS.IMPR_ID_TYPE` (CGSO$CHAR_ARB_DO) |  |
| `P1110_CTRY_CD_OF_ID` | CTRY_CD_OF_ID | Display Only, CSS u-hidden (Send On Page Submit = No) | - | No | - | Static: 100 | - | - | 4 | 1170 / hidden | n/a (not submitted, server value only) | `IMPORTERS.CTRY_CD_OF_ID` (CGSO$NUMBER) |  |
| `P1110_EXPD_STMT_NBR` | EXPD_STMT_NBR | Display Only, CSS u-hidden (Send On Page Submit = No) | - | No | - | - | - | - | 11 | 1180 / hidden | n/a (not submitted, server value only) | `IMPORTERS.EXPD_STMT_NBR` (CGSO$NUMBER) |  |
| `P1110_WVR_ENTRY_NBR` | WVR_ENTRY_NBR | Display Only, CSS u-hidden (Send On Page Submit = No) | - | No | - | - | - | - | 8 | 1190 / hidden | n/a (not submitted, server value only) | `IMPORTERS.WVR_ENTRY_NBR` (CGSO$NUMBER) |  |
| `P1110_ACTIVITY` | ACTIVITY | Textarea | نشاط المستورد | No | - | - | - | - | 1000 | 460 / row Yes / col 1 span 11 | Unrestricted | `IMPORTERS.ACTIVITY` (CGSO$CHAR_ARB_MLINE) |  |
| `P1110_CUSTOMS_ENTERED` | CUSTOMS_ENTERED | Display Only, CSS u-hidden (Send On Page Submit = No) | - | No | - | - | - | - | 2 | 1200 / hidden | n/a (not submitted, server value only) | `IMPORTERS.CUSTOMS_ENTERED` (CGSO$NUMBER) | Forms LOV CGDV$IMPORTERS_CUSTOMS_ENTERED not needed (item hidden) |
| `P1110_CREATION_FLAG` | CREATION_FLAG | Display Only, CSS u-hidden (Send On Page Submit = No) | - | No | - | Static: 1 | - | - | 4 | 1210 / hidden | n/a (not submitted, server value only) | `IMPORTERS.CREATION_FLAG` (CGSO$NUMBER) | Forms LOV CGDV$IMPORTERS_CREATION_FLAG not needed (item hidden) |
| `P1110_ROW_ID` | - | Display Only, CSS u-hidden (Send On Page Submit = No) | - | No | - | - | - | - | - | 1220 / hidden | n/a (server only) | - | ROWID of the row (Forms key mode ROWID) |
| `P1110_REC_STATUS` | - | Display Only, CSS u-hidden (Send On Page Submit = No) | - | No | - | - | - | - | - | 1230 / hidden | n/a (server only) | - | :SYSTEM.RECORD_STATUS (NEW/INSERT/QUERY/CHANGED) |
| `P1110_FORM_OPEN` | - | Display Only, CSS u-hidden (Send On Page Submit = No) | - | No | - | - | - | - | - | 1240 / hidden | n/a (server only) | - | Y after WHEN-NEW-FORM-INSTANCE ran |
| `P1110_NEED_FETCH` | - | Display Only, CSS u-hidden (Send On Page Submit = No) | - | No | - | - | - | - | - | 1250 / hidden | n/a (server only) | - | Y = next page show runs IMPORTERS.POST-QUERY |
| `P1110_UI_STATE` | - | Display Only, CSS u-hidden (Send On Page Submit = No) | - | No | - | - | - | - | - | 1260 / hidden | n/a (server only) | - | JSON of pkg_impr1110.ui_json for the page-load DA |
| `P1110_CODE` | - | Display Only, CSS u-hidden (Send On Page Submit = No) | - | No | - | - | - | - | - | 1270 / hidden | n/a (server only) | - | :PARAMETER.CODE (function code) |
| `P1110_LETTER_NBR` | - | Display Only, CSS u-hidden (Send On Page Submit = No) | - | No | - | - | - | - | - | 1280 / hidden | Checksum required (URL) | - | :PARAMETER.LETTER_NBR (URL / SUPPORT_ENTRY) |
| `P1110_PRSNL_IMPR` | - | Display Only, CSS u-hidden (Send On Page Submit = No) | - | No | - | Static: 0 | - | - | - | 1290 / hidden | Checksum required (URL) | - | :PARAMETER.PRSNL_IMPR (URL, default 0) |
| `P1110_NEXT_FUN` | - | Hidden (Value Protected = No) | - | No | - | - | - | - | 30 | 1300 / hidden | Unrestricted | - | function code to start after a SAVE (client-only helper, no business meaning) |

Pages 1111/1112 items are listed in §3.

---

## 5. Buttons

| Button (static ID) | Region | Position | Action | DB action | Server-side condition | Authorization | Confirm | Source |
|---|---|---|---|---|---|---|---|---|
| `SAVE` | TOOLBAR | Create (first) | Submit, request `SAVE` | INSERT / UPDATE via `page_dml` | – | `IMPR1110_ACCESS` | when new row **and** `AI_P_CLASS_CD = 1` **and** `AI_P_USER_TYPE = 3`: "يجب مراجعة البيانات والتأكد من صحتها قبل التخزين، لايمكن التعديل إلا من قبل شئون المستوردين! هل ترغب بالاستمرار؟" (DA 9) | `TOOLBAR.SAVE.WHEN-BUTTON-PRESSED` (COMMIT) + PRE-INSERT CONFIRM |
| `CREATE` | TOOLBAR | after SAVE | Submit, request `CREATE` → `page_clear` → new record | – | – | `IMPR1110_ACCESS` | "Warn on unsaved changes" | Forms CREATE-RECORD (toolbar, OLB) |
| `DELETE` | TOOLBAR | after CREATE | Submit, request `DELETE` | `IMPR_UPDTS` + `IMPORTERS` via `page_dml('DELETE')` | `P1110_ROW_ID IS NOT NULL` | `FUN_REMOVE` (TOOLBAR.REMOVE visible+enabled; §16 Q2) | "هل أنت متأكد من عملية الحذف" | `IMPORTERS.KEY-DELREC` |
| `QUERY` | TOOLBAR | after DELETE | Redirect to page 1111 (dialog), `P1111_PRSNL_IMPR = &P1110_PRSNL_IMPR.` | – | – | `IMPR1110_ACCESS` | – | `TOOLBAR.RE_ENTER_QUERY`, `ENTER`, `EXECUTE` |
| `CLEAR` | TOOLBAR | after QUERY | Submit, request `CLEAR` → `page_clear` | – | – | – | "Warn on unsaved changes" | `FORM.KEY-CLRFRM` / `TOOLBAR.CLEAR_ALL` |
| `EXIT` | TOOLBAR | last | Redirect to the IMPR menu page (home) | – | – | – | "Warn on unsaved changes" | `TOOLBAR.EXIT.WHEN-BUTTON-PRESSED` (`EXIT_FORM`) |
| `FUNCTIONS` | TOOLBAR | Next | Defined by DA – opens menu `IMPORTERS_FUNS` (`data-menu`) | – | at least one entry visible | – | – | `FORM.KEY-F9`, `TOOLBAR.FUN_BUT` |

Function entries are in §13.4. The SUPPORT_ENTRY check `IF FIND_FORM('SUPPORT_ENTRY') … CLOSE_FORM` in SAVE/EXIT is not needed (modal page 1113 is closed before).

---

## 6. LOVs

All SQL is taken from the LOV form's block (`QueryDataSourceName`, `WhereClause`, `OrderByClause`)
with the parameters IMPR1110 passes. *Display = code*: the Popup LOV shows the code in the field
(the name is shown in the separate display item, as in Forms) and the name as a search column.

| Forms LOV | APEX LOV (Shared Component) | Type | SQL (display, return, …) | Used by | Item type | Cascading parents | Notes |
|---|---|---|---|---|---|---|---|
| `LOV_SD_PORTS` (form) / `CGFK$IMPORTERS_PORT_CD` | `LOV_SD_PORTS` | SQL | `SELECT port_cd d, port_cd r, port_name FROM sd_ports WHERE port_status = 1 AND port_type = NVL(:AI_P_PORT_TYPE, port_type) ORDER BY port_cd` | P1110_PORT_CD | Popup LOV | – | params STATUS=1, PORT_TYPE=:PARAMETER.P_PORT_TYPE. The committee filter for user class 55 (`P_CC_USER_CLASS_CD`) is not passed by IMPR1110 → not used |
| `LOV_Impr_Type` (form) – type part / `CGFK$IMPORTERS_IMPR_TYPE_CD` | `LOV_IMPR_TYPE` | SQL | `SELECT DISTINCT itidt.impr_type_cd d, itidt.impr_type_cd r, it.impr_type_name FROM impr_type_id_types itidt, impr_types it WHERE it.impr_type_cd = itidt.impr_type_cd AND itidt.impr_type_cd > 0 AND (:AI_CHK_IMP_TYP = '1' OR itidt.status = 1) ORDER BY 2` | P1110_IMPR_TYPE_CD | Popup LOV | – | Forms passes STATUS=1 and the current IMPR_TYPE_CD only when `:GLOBAL.CHK_IMP_TYP != 1`. The "current type" filter becomes the cascade of the next row |
| `LOV_Impr_Type` (form) – bus-id-type part | `LOV_IMPR_TYPE_BUS_ID` | SQL | `SELECT bit.bus_id_type_name d, itidt.bus_id_type_cd r FROM impr_type_id_types itidt, bus_id_types bit WHERE bit.bus_id_type_cd = itidt.bus_id_type_cd AND itidt.impr_type_cd = :P1110_IMPR_TYPE_CD AND itidt.impr_type_cd > 0 AND (:AI_CHK_IMP_TYP = '1' OR itidt.status = 1) ORDER BY itidt.bus_id_type_cd` | P1110_BUS_ID_TYPE_CD | Select List (null = "-") | P1110_IMPR_TYPE_CD | The LOV form returns the pair IMPR_TYPE_CD/BUS_ID_TYPE_CD. In APEX: choose type, then bus-id type. Selection = LOV return → DA 5 (`LOV_RET`) |
| `LOV_CITIES_IMP` (form) for CITY_CODE_OF_ID / `CGFK$IMPORTERS_CITY_CODE_OF_ID` | `LOV_CITIES_IMP_ID` | SQL | `SELECT city_cd d, city_cd r, city_arb_name, mins_comm_cd FROM cities WHERE city_status = 1 AND ctry_cd = NVL(CASE WHEN :P1110_IMPR_TYPE_CD = 3 AND :P1110_BUS_ID_TYPE_CD = 2 THEN 100 ELSE :P1110_CTRY_CD END, ctry_cd) ORDER BY ctry_cd, city_cd` | P1110_CITY_CODE_OF_ID | Popup LOV | IMPR_TYPE_CD, BUS_ID_TYPE_CD, CTRY_CD | Forms also returns `CTRY_CD_OF_ID` and `:GLOBAL.MINS_COMM_CD`. CTRY_CD_OF_ID already equals the LOV country (CTRY_CD WVI); MINS_COMM_CD is set by `ajax_item` (x05 = `LOV`) |
| `LOV_CITIES_IMP` (form) for BRNH_CITY_CD | `LOV_CITIES_IMP_BRNH` | SQL | `SELECT city_cd d, city_cd r, city_arb_name, mins_comm_cd FROM cities WHERE city_status = 1 AND ctry_cd = NVL(:P1110_CTRY_CD, ctry_cd) ORDER BY ctry_cd, city_cd` | P1110_BRNH_CITY_CD | Popup LOV | CTRY_CD | returns BRNH_CITY_CD/NAME |
| `LOV_CITIES` (form) / `CGFK$IMPORTERS_ADD_CTRY_CD` (city part) | `LOV_CITIES` | SQL | `SELECT city_cd d, city_cd r, city_arb_name FROM cities WHERE city_status = 1 AND ctry_cd = NVL(:P1110_ADD_CTRY_CD, ctry_cd) ORDER BY ctry_cd, city_cd` | P1110_CITY_CODE | Popup LOV | ADD_CTRY_CD | Forms also returns ADD_CTRY_CD (= the LOV country) |
| `LOV_COUNTRIES` (form) / `CGFK$IMPORTERS_ADD_CTRY_CD`, `CGFK$IMPORTERS_CTRY_CD` | `LOV_COUNTRIES` | SQL | `SELECT ctry_cd d, ctry_cd r, crty_arbc_name FROM countries WHERE ctry_status = 1 AND ctry_cd NOT IN (-1) ORDER BY ctry_cd` | P1110_ADD_CTRY_CD | Popup LOV | – | `P_CTRY_EXC` not passed → `-1` |
| `LOV_COUNTRIES` / `LOV_COUNTRIES_GULF` (PU CALL_LOV_COUNTRIES / CALL_LOV_COUN_GULF) | inline LOV of `P1110_CTRY_CD` | SQL | `SELECT ctry_cd d, ctry_cd r, crty_arbc_name FROM countries WHERE (:P1110_IMPR_TYPE_CD = 4 AND :P1110_BUS_ID_TYPE_CD = 16 AND ctry_cd IN (113,116,117,119,120,100)) OR (NOT (NVL(:P1110_IMPR_TYPE_CD,0) = 4 AND NVL(:P1110_BUS_ID_TYPE_CD,0) = 16) AND ctry_status = 1) ORDER BY ctry_cd` | P1110_CTRY_CD | Popup LOV | IMPR_TYPE_CD, BUS_ID_TYPE_CD | Gulf list is hard-coded in LOV_COUNTRIES_GULF (not CTRY_GROUP_DETAILS as the v0 LOV file assumed) |
| `LOV_IMPR` (form) | `LOV_IMPR` | SQL | `SELECT impr_nbr d, impr_nbr r, arbc_impr_name, bus_id, bus_id_brnch, impr_tel_nbr FROM importers WHERE port_cd = :AI_P_CURR_PORT_CD` | P1110_IMPR_NBR_PARENT | Popup LOV | – | params PORT_CD = current port, MAIN_IMPR = 0, others NULL → their conditions are always true; no ORDER BY in the LOV form |
| list item COMM_RGSTRTN_TYPE (`CGDV$POPULATE_DYNAMIC_LISTS`) | `LOV_COMM_RGSTRTN_TYPE` | SQL | `SELECT rv_meaning d, rv_low_value r FROM cg_ref_codes WHERE rv_domain = 'COMM_RGSTRTN_TYPE' ORDER BY 2` | P1110_COMM_RGSTRTN_TYPE | Select List | – | design-time values 1=رئيسي, 0=فرعي, 2=فرعي are replaced at runtime by CG_REF_CODES |
| list item IMPR_EXPR_TYPE (`CGDV$POPULATE_DYNAMIC_LISTS`) | `LOV_ALLOWED_EXPORT` | SQL | `SELECT rv_meaning d, rv_low_value r FROM cg_ref_codes WHERE rv_domain = 'ALLOWED EXPORT' ORDER BY 2` | P1110_IMPR_EXPR_TYPE | Select List | – | design-time 0=تصدير, 1=إستيراد, 2=إستيراد-تصدير |
| list item EXPRESS_POST | `LOV_EXPRESS_POST` | Static | `0` لا · `1` نعم · `2` تم انشاءه بواسطة البريد السريع | P1110_EXPRESS_POST | Select List | – | values from the XML |
| pop list CAR_AGENT_FLAG | `LOV_CAR_AGENT_FLAG` | Static | `0` ليس وكيل سيارات · `1` وكيل سيارات | P1110_CAR_AGENT_FLAG | Select List | – | values from the XML |
| `CGFK$IMPORTERS_HQ_IMPR_NBR`, `CGDV$IMPORTERS_CREATION_FLAG`, `CGDV$IMPORTERS_CUSTOMS_ENTERED` | – | – | – | – | – | – | not needed: the items are display-only / hidden |

`plsql/IMPR1110/impr1110_shared_lovs.sql` (v0) is superseded by this table. It had the
LOV_CITIES / LOV_CITIES_IMP sources swapped and guessed the Gulf-countries source.

**LOV return note (Forms bug kept out):** the LOV forms copy the selected row into `:GLOBAL.<ITEM>`
(`COPY_SELECTED_VALUES`, MISSING SOURCE). Their city-name column is spelled `CTIY_ARB_NAME`, while
IMPR1110 reads `:GLOBAL.CITY_ARB_NAME`, so in Forms the name after the LOV can be stale until the
item validation fills it. In APEX the name comes from the item validation only, which gives the
same end state without the stale value.

---

## 7. Validations (page 1110, condition: Request = `SAVE`)

| Seq | Validation name | Level | Type | Code | Associated item | Error display | Source trigger |
|---|---|---|---|---|---|---|---|
| 10 | `IMPORTERS.PORT_CD.WHEN-VALIDATE-ITEM` | item | PL/SQL Function Body returning Error Text | `RETURN pkg_impr1110_apx.validate_on_submit('PORT_CD');` | P1110_PORT_CD | Inline with Field and in Notification | IMPORTERS.PORT_CD.WHEN-VALIDATE-ITEM |
| 20 | `IMPORTERS.HQ_IMPR_NBR.POST-CHANGE` | item | PL/SQL Function Body returning Error Text | `RETURN pkg_impr1110_apx.validate_on_submit('HQ_IMPR_NBR');` | P1110_HQ_IMPR_NBR | Inline with Field and in Notification | IMPORTERS.HQ_IMPR_NBR.POST-CHANGE |
| 30 | `IMPORTERS.IMPR_NBR.WHEN-VALIDATE-ITEM` | item | PL/SQL Function Body returning Error Text | `RETURN pkg_impr1110_apx.validate_on_submit('IMPR_NBR');` | P1110_IMPR_NBR | Inline with Field and in Notification | IMPORTERS.IMPR_NBR.WHEN-VALIDATE-ITEM |
| 40 | `IMPORTERS.IMPR_TYPE_CD.WHEN-VALIDATE-ITEM` | item | PL/SQL Function Body returning Error Text | `RETURN pkg_impr1110_apx.validate_on_submit('IMPR_TYPE_CD');` | P1110_IMPR_TYPE_CD | Inline with Field and in Notification | IMPORTERS.IMPR_TYPE_CD.POST-CHANGE + IMPORTERS.IMPR_TYPE_CD.WHEN-VALIDATE-ITEM |
| 50 | `IMPORTERS.BUS_ID_EXPRD_DT.WHEN-VALIDATE-ITEM` | item | PL/SQL Function Body returning Error Text | `RETURN pkg_impr1110_apx.validate_on_submit('BUS_ID_EXPRD_DT');` | P1110_BUS_ID_EXPRD_DT | Inline with Field and in Notification | IMPORTERS.BUS_ID_EXPRD_DT.WHEN-VALIDATE-ITEM |
| 60 | `IMPORTERS.BUS_ID_TYPE_CD.POST-CHANGE` | item | PL/SQL Function Body returning Error Text | `RETURN pkg_impr1110_apx.validate_on_submit('BUS_ID_TYPE_CD');` | P1110_BUS_ID_TYPE_CD | Inline with Field and in Notification | IMPORTERS.BUS_ID_TYPE_CD.POST-CHANGE |
| 70 | `IMPORTERS.CITY_CODE_OF_ID.WHEN-VALIDATE-ITEM` | item | PL/SQL Function Body returning Error Text | `RETURN pkg_impr1110_apx.validate_on_submit('CITY_CODE_OF_ID');` | P1110_CITY_CODE_OF_ID | Inline with Field and in Notification | IMPORTERS.CITY_CODE_OF_ID.WHEN-VALIDATE-ITEM |
| 80 | `IMPORTERS.BUS_ID.WHEN-VALIDATE-ITEM` | item | PL/SQL Function Body returning Error Text | `RETURN pkg_impr1110_apx.validate_on_submit('BUS_ID');` | P1110_BUS_ID | Inline with Field and in Notification | IMPORTERS.BUS_ID.POST-CHANGE + IMPORTERS.BUS_ID.WHEN-VALIDATE-ITEM |
| 90 | `IMPORTERS.BRNH_CITY_CD.WHEN-VALIDATE-ITEM` | item | PL/SQL Function Body returning Error Text | `RETURN pkg_impr1110_apx.validate_on_submit('BRNH_CITY_CD');` | P1110_BRNH_CITY_CD | Inline with Field and in Notification | IMPORTERS.BRNH_CITY_CD.WHEN-VALIDATE-ITEM |
| 100 | `IMPORTERS.BUS_ID_BRNCH.WHEN-VALIDATE-ITEM` | item | PL/SQL Function Body returning Error Text | `RETURN pkg_impr1110_apx.validate_on_submit('BUS_ID_BRNCH');` | P1110_BUS_ID_BRNCH | Inline with Field and in Notification | IMPORTERS.BUS_ID_BRNCH.POST-CHANGE + IMPORTERS.BUS_ID_BRNCH.WHEN-VALIDATE-ITEM |
| 110 | `IMPORTERS.CTRY_CD.WHEN-VALIDATE-ITEM` | item | PL/SQL Function Body returning Error Text | `RETURN pkg_impr1110_apx.validate_on_submit('CTRY_CD');` | P1110_CTRY_CD | Inline with Field and in Notification | IMPORTERS.CTRY_CD.WHEN-VALIDATE-ITEM |
| 120 | `IMPORTERS.IMPR_EXPR_TYPE.POST-CHANGE` | item | PL/SQL Function Body returning Error Text | `RETURN pkg_impr1110_apx.validate_on_submit('IMPR_EXPR_TYPE');` | P1110_IMPR_EXPR_TYPE | Inline with Field and in Notification | IMPORTERS.IMPR_EXPR_TYPE.POST-CHANGE |
| 130 | `IMPORTERS.ARBC_IMPR_NAME.WHEN-VALIDATE-ITEM` | item | PL/SQL Function Body returning Error Text | `RETURN pkg_impr1110_apx.validate_on_submit('ARBC_IMPR_NAME');` | P1110_ARBC_IMPR_NAME | Inline with Field and in Notification | IMPORTERS.ARBC_IMPR_NAME.WHEN-VALIDATE-ITEM |
| 140 | `IMPORTERS.ENG_IMPR_NAME.WHEN-VALIDATE-ITEM` | item | PL/SQL Function Body returning Error Text | `RETURN pkg_impr1110_apx.validate_on_submit('ENG_IMPR_NAME');` | P1110_ENG_IMPR_NAME | Inline with Field and in Notification | IMPORTERS.ENG_IMPR_NAME.WHEN-VALIDATE-ITEM |
| 150 | `IMPORTERS.BUS_ID_ISSUE_DT.WHEN-VALIDATE-ITEM` | item | PL/SQL Function Body returning Error Text | `RETURN pkg_impr1110_apx.validate_on_submit('BUS_ID_ISSUE_DT');` | P1110_BUS_ID_ISSUE_DT | Inline with Field and in Notification | IMPORTERS.BUS_ID_ISSUE_DT.WHEN-VALIDATE-ITEM |
| 160 | `IMPORTERS.IMPR_NBR_PARENT.WHEN-VALIDATE-ITEM` | item | PL/SQL Function Body returning Error Text | `RETURN pkg_impr1110_apx.validate_on_submit('IMPR_NBR_PARENT');` | P1110_IMPR_NBR_PARENT | Inline with Field and in Notification | IMPORTERS.IMPR_NBR_PARENT.WHEN-VALIDATE-ITEM |
| 170 | `IMPORTERS.ADD_CTRY_CD.WHEN-VALIDATE-ITEM` | item | PL/SQL Function Body returning Error Text | `RETURN pkg_impr1110_apx.validate_on_submit('ADD_CTRY_CD');` | P1110_ADD_CTRY_CD | Inline with Field and in Notification | IMPORTERS.ADD_CTRY_CD.WHEN-VALIDATE-ITEM |
| 180 | `IMPORTERS.CITY_CODE.WHEN-VALIDATE-ITEM` | item | PL/SQL Function Body returning Error Text | `RETURN pkg_impr1110_apx.validate_on_submit('CITY_CODE');` | P1110_CITY_CODE | Inline with Field and in Notification | IMPORTERS.CITY_CODE.WHEN-VALIDATE-ITEM |
| 190 | `IMPORTERS.IMPR_TEL_NBR.WHEN-VALIDATE-ITEM` | item | PL/SQL Function Body returning Error Text | `RETURN pkg_impr1110_apx.validate_on_submit('IMPR_TEL_NBR');` | P1110_IMPR_TEL_NBR | Inline with Field and in Notification | IMPORTERS.IMPR_TEL_NBR.WHEN-VALIDATE-ITEM |
| 200 | `IMPORTERS.B_EMAIL.WHEN-VALIDATE-ITEM` | item | PL/SQL Function Body returning Error Text | `RETURN pkg_impr1110_apx.validate_on_submit('B_EMAIL');` | P1110_B_EMAIL | Inline with Field and in Notification | IMPORTERS.B_EMAIL.POST-CHANGE + IMPORTERS.B_EMAIL.WHEN-VALIDATE-ITEM |
| 210 | `IMPORTERS.EMAIL.WHEN-VALIDATE-ITEM` | item | PL/SQL Function Body returning Error Text | `RETURN pkg_impr1110_apx.validate_on_submit('EMAIL');` | P1110_EMAIL | Inline with Field and in Notification | IMPORTERS.EMAIL.WHEN-VALIDATE-ITEM |
| 220 | `IMPORTERS.B_MOBILE_NO.WHEN-VALIDATE-ITEM` | item | PL/SQL Function Body returning Error Text | `RETURN pkg_impr1110_apx.validate_on_submit('B_MOBILE_NO');` | P1110_B_MOBILE_NO | Inline with Field and in Notification | IMPORTERS.B_MOBILE_NO.POST-CHANGE + IMPORTERS.B_MOBILE_NO.WHEN-VALIDATE-ITEM |
| 230 | `IMPORTERS.BANK_IBAN.WHEN-VALIDATE-ITEM` | item | PL/SQL Function Body returning Error Text | `RETURN pkg_impr1110_apx.validate_on_submit('BANK_IBAN');` | P1110_BANK_IBAN | Inline with Field and in Notification | IMPORTERS.BANK_IBAN.WHEN-VALIDATE-ITEM |
| 240 | `IMPORTERS.B_ID_NBR.WHEN-VALIDATE-ITEM` | item | PL/SQL Function Body returning Error Text | `RETURN pkg_impr1110_apx.validate_on_submit('B_ID_NBR');` | P1110_B_ID_NBR | Inline with Field and in Notification | IMPORTERS.B_ID_NBR.POST-CHANGE + IMPORTERS.B_ID_NBR.WHEN-VALIDATE-ITEM |
| 250 | `IMPORTERS.CTRY_CD_OF_ID.WHEN-VALIDATE-ITEM` | item | PL/SQL Function Body returning Error Text | `RETURN pkg_impr1110_apx.validate_on_submit('CTRY_CD_OF_ID');` | P1110_CTRY_CD_OF_ID | Inline with Field and in Notification | IMPORTERS.CTRY_CD_OF_ID.WHEN-VALIDATE-ITEM |
| 1000 | `IMPORTERS.REQUIRED-ITEMS` | page | PL/SQL Function Body returning Error Text | `RETURN pkg_impr1110_apx.required_items;` | – | Inline in Notification | Forms FRM-40202 at commit (static Required + `SET_ITEM_PROPERTY(…, REQUIRED, …)`) |

* Validations run in Forms item order (XML order). Each one calls the package only for an item
  whose value changed since the server last validated it (§0.3), with `p_from_item = FALSE`
  (Forms: `:SYSTEM.TRIGGER_ITEM <> :SYSTEM.CURSOR_ITEM` at commit). Alert answers default to
  button 1, as when Forms validates at commit without asking again.
* "Always Execute" = No. Error text = the Forms text (business error) or the ON-ERROR text.
* Item-level checks while typing come from the AJAX DAs (§10, DA 2). These validations are the
  server-side guarantee.

---

## 8. Processes

### Page 1110

| Point | Seq | Process | Type | Code | Condition | Messages | Source trigger |
|---|---|---|---|---|---|---|---|
| Before Header | 10 | `WHEN-NEW-FORM-INSTANCE` | Execute Code | `pkg_impr1110_apx.page_wnfi;` | `P1110_FORM_OPEN` is null (first entry; the menu link clears cache 1110) | messages in `P1110_UI_STATE` | `FORM.WHEN-NEW-FORM-INSTANCE` |
| Before Header | 20 | `IMPORTERS.POST-QUERY` | Execute Code | `pkg_impr1110_apx.page_fetch;` | `P1110_NEED_FETCH = 'Y'` | FRM-40350 if not found | `IMPORTERS.PRE-QUERY`, `POST-QUERY`, `PRE-RECORD`, `WHEN-NEW-RECORD-INSTANCE` |
| Before Header | 30 | `IMPORTERS.WHEN-CREATE-RECORD` | Execute Code | `pkg_impr1110_apx.page_new_record;` | `P1110_ROW_ID` is null **and** `P1110_REC_STATUS` is null | – | `IMPORTERS.WHEN-CREATE-RECORD`, `PRE-RECORD`, `WHEN-NEW-RECORD-INSTANCE` |
| Processing | 10 | `IMPORTERS.PRE-INSERT…POST-UPDATE` | Execute Code | `pkg_impr1110_apx.page_dml('SAVE');` | Request = `SAVE` | success: messages of the package (e.g. "رقم المستورد = …") via `P1110_UI_STATE`; error = Forms text | `PRE-INSERT`, default INSERT, `POST-INSERT`, `PRE-UPDATE`, default UPDATE, `POST-UPDATE` |
| Processing | 20 | `IMPORTERS.KEY-DELREC` | Execute Code | `pkg_impr1110_apx.page_dml('DELETE');` | Request = `DELETE` | – | `KEY-DELREC`, `PRE-DELETE` |
| Processing | 30 | `IMPORTERS.KEY-CLRBLK` | Execute Code | `pkg_impr1110_apx.page_clear;` | Request in (`CLEAR`, `CREATE`) | – | `KEY-CLRFRM`, `WHEN-CLEAR-BLOCK`, CREATE-RECORD |
| Processing | 40 | `IMPORTERS.EXECUTE-QUERY` | Execute Code | `pkg_impr1110_apx.page_query(CASE :REQUEST WHEN 'QUERY_NBR' THEN TO_NUMBER(:P1110_IMPR_NBR) END);` | Request in (`QUERY`, `QUERY_NBR`) | – | `IMPR_NBR.WHEN-VALIDATE-ITEM` + WNII re-query (`QUERY`, uses `:GLOBAL.PORT_CD/IMPR_NBR`), search dialog (`QUERY_NBR`) |
| Ajax Callback | – | `IMPR1110_ITEM` | Execute Code | `pkg_impr1110_apx.ajax_item;` | – | JSON | all item triggers (§10) |
| Ajax Callback | – | `IMPR1110_CONFIRM` | Execute Code | `pkg_impr1110_apx.ajax_confirm;` | – | JSON | Confirm texts |
| Ajax Callback | – | `IMPR1110_FUN` | Execute Code | `pkg_impr1110_apx.ajax_fun;` | – | JSON | `EXEC_FUNS` |

Branch (After Processing): page 1110, no clear cache, for all requests (Forms stays on the record
after COMMIT; no re-query). There is no COMMIT in the packages; APEX commits after processing and
rolls back on error. The 6 COMMITs removed from the Forms code are HIGH H2 of step 02.

### Page 1112

| Point | Process | Code | Condition | Source |
|---|---|---|---|---|
| Before Header | computation `P1112_MOBILE_NO` | `RETURN pkg_impr1110_apx.central_mobile(:P1112_IMPR_NBR);` | `P1112_MOBILE_NO` is null | `BLK.WHEN-NEW-BLOCK-INSTANCE` |
| Processing | `CTRL_BLK.PB_OK.WHEN-BUTTON-PRESSED` | `pkg_forms_compat.set_global('MOBILE_NO', :P1112_MOBILE_NO);` + process *Close Dialog* | Request = `OK` | `PB_OK` + `COPY_SELECTED_VALUES` |
| Processing | `CTRL_BLK.PB_CANCEL.WHEN-BUTTON-PRESSED` | `pkg_forms_compat.set_global('MOBILE_NO', NULL);` | Request = `CANCEL` | `PB_CANCEL` |

---

## 9. Computations

| Item | Point | Type | Expression | Condition | Source |
|---|---|---|---|---|---|
| – (page 1110) | – | – | – | – | Defaults and lookups come from the package (`wnfi`, `importers_wcr`, `post_qry`). Item "Default" values in §4 are the Forms *Initial Value* and only matter before WHEN-CREATE-RECORD runs |
| `P1112_MOBILE_NO` | Before Header | PL/SQL Function | `pkg_impr1110_apx.central_mobile(:P1112_IMPR_NBR)` | item is null | `LOV_UPDATE_IMPR_MOBILE` WNBI |

---

## 10. Dynamic Actions (page 1110)

All DAs call one static file `impr1110.js` (namespace `impr1110`, step 04), so the behaviour sits
in one place, like a Forms library. Helper calls:
* `impr1110.run(item, event, a1, a2, x05)` = `apex.server.process('IMPR1110_ITEM', {x01..x05, pageItems: '#IMPORTERS :input'})`.
  It then writes `reply.items` into the page items (skipping `P1110_ROW_ID`) and calls
  `impr1110.applyUi(reply.ui)`. On `reply.error` it shows the error inline at the item, sets the
  focus back to the item and blocks SAVE until the item is valid (Forms keeps the cursor in an
  invalid item).
* `impr1110.applyUi(json)` applies `items[]` (ENTRABLE/ENABLED → enable/disable,
  REQUIRED → `setRequired`, VISIBLE → show/hide, VALID false → mark for re-validation,
  OPEN_LOV → open the Popup LOV / focus the select list, REQUERY → submit `QUERY`,
  BLOCK_UPDATE_ONLY → hide CREATE/DELETE, DO_COMMIT → submit `SAVE`), then `focus`, `messages`
  (page notification) and `funs` (show/hide `IMPORTERS_FUNS` entries).

| # | DA name | Event | Selection | Client condition | True actions | Items to submit / return | Fire on init | Source trigger |
|---|---|---|---|---|---|---|---|---|
| 1 | `IMPORTERS.UI-STATE` | Page Load | – | – | JS `impr1110.applyUi(JSON.parse($v('P1110_UI_STATE')||'{}'))`; then if `P1110_NEXT_FUN` not null → `impr1110.fun($v('P1110_NEXT_FUN'))` and clear it | – | – | all `Make_Field_Entrable` / `SET_ITEM_PROPERTY` / `GO_ITEM` of WNFI, WCR, POST-QUERY, WNRI, DML triggers |
| 2 | `IMPORTERS.<ITEM>.WHEN-VALIDATE-ITEM` – one DA per item: PORT_CD, HQ_IMPR_NBR¹, IMPR_NBR, IMPR_TYPE_CD, BUS_ID_EXPRD_DT, CITY_CODE_OF_ID, BUS_ID, BRNH_CITY_CD, BUS_ID_BRNCH, CTRY_CD, IMPR_EXPR_TYPE¹, ARBC_IMPR_NAME, ENG_IMPR_NAME, BUS_ID_ISSUE_DT, IMPR_NBR_PARENT, ADD_CTRY_CD, CITY_CODE, IMPR_TEL_NBR, B_EMAIL, B_MOBILE_NO, BANK_IBAN, B_ID_NBR | Change | item | – | JS `impr1110.run('<ITEM>','VALIDATE', …)` (x05 = `LOV` when the value came from the Popup LOV: CITY_CODE_OF_ID, BRNH_CITY_CD) | `#IMPORTERS :input` / all items | No | POST-CHANGE + WHEN-VALIDATE-ITEM of the item (¹ POST-CHANGE only) |
| 3 | `IMPORTERS.BUS_ID.WHEN-VALIDATE-ITEM` (confirm part) | before DA 2 on BUS_ID | P1110_BUS_ID | – | `apex.server.process('IMPR1110_CONFIRM',{x01:'SUSP'})` → if text: `apex.message.confirm(text)` → answer as x04 (1/2) of DA 2 | page items | No | WARNING "يوجد مستورد … موقوف …" |
| 4 | `IMPORTERS.IMPR_NBR` re-query | after DA 2 on IMPR_NBR without error | – | the number exists (`impr_nbr_wvi` set EXEC_QUERY_NOW) | Submit request `QUERY` | – | No | `IMPR_NBR.WHEN-VALIDATE-ITEM` + `IMPORTERS.WHEN-NEW-ITEM-INSTANCE` (Clear_Block + EXECUTE_QUERY) |
| 5 | `IMPORTERS.IMPR_TYPE_CD.KEY-LISTVAL` (return) | Change | P1110_BUS_ID_TYPE_CD | – | `impr1110.run('BUS_ID_TYPE_CD','LOV_RET')` | page items | No | IMPR_TYPE_CD.KEY-LISTVAL after LOV_Impr_Type + BUS_ID_TYPE_CD.POST-CHANGE |
| 6 | `IMPORTERS.<ITEM>.WHEN-NEW-ITEM-INSTANCE` for IMPR_TYPE_CD, CITY_CODE_OF_ID, BUS_ID, BRNH_CITY_CD, BUS_ID_BRNCH, BANK_IBAN | Get Focus | item | – | `impr1110.run('<ITEM>','WNII')` | page items | No | WHEN-NEW-ITEM-INSTANCE |
| 7 | `IMPORTERS.COMM_RGSTRTN_TYPE.WHEN-LIST-CHANGED` | Change | P1110_COMM_RGSTRTN_TYPE | – | `impr1110.run('COMM_RGSTRTN_TYPE','WLC')` | page items | No | WHEN-LIST-CHANGED |
| 8 | `IMPORTERS.ARBC_IMPR_NAME.KEY-NEXT-ITEM` | Key Down (Tab/Enter) | P1110_ARBC_IMPR_NAME | – | Set Focus `P1110_ENG_IMPR_NAME` (net effect of the trigger; record unchanged) | – | No | KEY-NEXT-ITEM |
| 9 | `IMPORTERS.PRE-INSERT` (confirm) | Click | button SAVE | `P1110_ROW_ID` empty and `&AI_P_CLASS_CD.` = 1 and `&AI_P_USER_TYPE.` = 3 | Confirm (text in §5), then Submit `SAVE` | – | No | PRE-INSERT CONFIRM |
| 10 | `IMPORTERS.KEY-DELREC` (confirm) | Click | button DELETE | – | Confirm "هل أنت متأكد من عملية الحذف", then Submit `DELETE` | – | No | KEY-DELREC WARNING |
| 11 | `FUNCTIONS` | Click | entries of `IMPORTERS_FUNS` | – | `impr1110.fun(code)` – §13.4 | – | No | EXECUTE_FUNCTION / EXEC_FUNS |
| 12 | `IMPORTERS.WHEN-NEW-RECORD-INSTANCE` (function code) | custom event after `impr1110.fun` when the reply sets `P1110_CODE` | – | `P1110_CODE` not empty | `IMPR1110_CONFIRM` x01=`WNRI` → if text Confirm → `impr1110.run(null,'WNRI', answer)` | page items | No | WNRI branches IMPR1110F1–F5, SF6 |
| 13 | `IMPR1110_QUERY` dialog closed | Dialog Closed | button QUERY | `this.data.IMPR_NBR` | Set Value `P1110_IMPR_NBR` = returned number; Submit `QUERY_NBR` | – | No | Enter/Execute Query |
| 14 | `IMPR1110_MOBILE` dialog closed | Dialog Closed | entry `IMPR1110_MOB` | – | `apex.server.process('IMPR1110_FUN',{x01:'IMPR1110_MOB_RET'})` | page items | No | `LOV_UPDATE_MOBLIE` after CALL_FORM |
| 15 | `IMPR1110_SUPPORT` dialog closed | Dialog Closed | entries F1/F2/F3/F5 | – | `apex.server.process('IMPR1110_FUN',{x01: code})` → DA 12 | page items | No | `EXEC_FUNS` after CALL_FORM SUPPORT_ENTRY |
| 16 | Hijri calendar | Click / F4 | P1110_BUS_ID_EXPRD_DT | – | **open (§16 Q5)** – plain text with mask until decided | – | – | KEY-F4 / KEY-LISTVAL (`INTRFACE.Disp_date_con('H',2,1)`) |
| 17 | `IMPORTERS.BANK_IBAN` upper case | Key Up | P1110_BANK_IBAN | – | none (server `bank_iban_wvi` does `UPPER`); optional CSS `text-transform` only | – | – | – |

Patterns: `plsql_templates/dynamic_action_patterns.sql` (Execute Server-side Code + Confirm).
APEX 21.2 features used: Dynamic Actions, `apex.server.process`, `apex.message.confirm`,
`apex.item().setRequired/enable/disable/setFocus`, Popup LOV, Dialog Closed event,
`apex.navigation.dialog.close`. No feature newer than 21.2 is used. **Popup LOV "Additional
Outputs" is deliberately not used:** I am not sure it exists in 21.2, and the extra
return values are set by the server instead (§6).

---

## 11. Alerts and messages

| Forms alert / message | Usage | APEX equivalent | Text |
|---|---|---|---|
| `USR_CONFIRM_B`, `USR_CONFIRM`, `USR_WARNING_C`, `USR_WARNING_B`, `CFG_WARNING_A`, `CFG_INFORMATION`, `CFG_ERROR`, `CFG_SYSTEM_ERROR`, `CFG_ASK_COMMIT` (CIC_OLB) | only through `STR.DispAlert` / `STR.DispArbMsg` | not created – texts are inline in the package | MISSING SOURCE (OLB) |
| `STR.DispAlert(text,'ERROR'/'INFORMATION')` + FTF (91 texts, step 02 §4) | stop | `pkg_forms_compat.ftf` → validation error / AJAX `error` / process error | verbatim from the form |
| `STR.DispAlert` without failure | note | page notification from `ui_json.messages` / `P1110_UI_STATE` | verbatim |
| CONFIRM / WARNING with Yes/No (5) | caution | Confirm DAs 3, 9, 10, 12 and the MCI flow (§13.4) | verbatim (step 02 §5.4) |
| FRM-40202 / 40350 / 40654 | Forms runtime | `required_items`, `page_fetch`, `importers_upd` | **TODO** Arabic texts of `NIB.ON_ERROR` (MISSING SOURCE) |

Error handling function (Application Attributes): `pkg_forms_compat.apex_error_handler`.
It shows `-20000` business errors without the `ORA-` prefix.

---

## 12. Branches and navigation

| Branch / link | Point | Target | Condition | Items set | Source |
|---|---|---|---|---|---|
| After processing | After Processing | 1110 | always | – | Forms stays in the form after COMMIT / CLEAR |
| Button QUERY | – | 1111 (dialog) | – | `P1111_PRSNL_IMPR` (checksum) | ENTER_QUERY / EXECUTE_QUERY |
| Function `IMPR1110_MOB` | – | 1112 (dialog) | `P1110_IMPR_NBR > 3000000` (checked by `exec_funs`) | `P1112_IMPR_NBR` (checksum) | `CALL_FORM('LOV_UPDATE_IMPR_MOBILE.fmx')` |
| Functions IMPR1110F1/F2/F3/F5 | – | 1113 (dialog) | – | `P1113_P_MODE = 0`, `P1113_PORT_CD` (checksum) | `CALL_FORM('SUPPORT_ENTRY.FMX')` |
| Function `IMPR1115_SCR` | – | IMPR1115 page (when converted) | – | `P_IMPR_NO = P1110_IMPR_NBR` | TMPLT `CALL_FORM` with parameter list |
| Button EXIT | – | IMPR menu / home | – | – | `EXIT_FORM` |
| Calls into 1110 | – | 1110 | – | `P1110_PRSNL_IMPR`, `P1110_LETTER_NBR` (checksum) | other forms that open IMPR1110 with PRSNL_IMPR / LETTER_NBR |

---

## 13. Shared components required

### 13.1 Application items (Session State Protection: Restricted – may not be set from browser)

`AI_P_CURR_PORT_CD`, `AI_P_USER_ID`, `AI_P_WS_ID`, `AI_P_CLASS_CD`, `AI_P_USER_TYPE`,
`AI_P_BRKR_PORT_CD`, `AI_P_LIC_TYPE`, `AI_P_BRKR_NBR`, `AI_P_PORT_TYPE` – set after login from the
user's session (the `:PARAMETER.P_*` of the menu; source = `CIC_MENU` / security, §16 Q4).

From `:GLOBAL.*` (`pkg_forms_compat.get/set_global`, prefix `AI_`): `AI_FLAGUPDATE`,
`AI_EXEC_QUERY_NOW`, `AI_PORT_CD`, `AI_IMPR_NBR`, `AI_VALID`, `AI_FUNS_IMP`, `AI_FUNS_BUSID`,
`AI_CHK_IMP_TYP`, `AI_CHK_DUP_BUSID`, `AI_OLD_IMPR_TYPE_CD`, `AI_OLD_PORT_CD`, `AI_ALLOW_MCI`,
`AI_ALLOW_MOI`, `AI_SET`, `AI_MINS_COMM_CD`, `AI_LETTER_NBR`, `AI_SUPP_TITLE_CD`, `AI_LETTER_DT`,
`AI_MOBILE_NO`, `AI_IMPR_NBR_B`, `AI_IMPR_NAME_B`, `AI_BRKR_ATHRZTN_NBR_B`, `AI_CHEK`,
`AI_STAT_QUE`, `AI_STAT_CLR`, `AI_IMP0F4`, `AI_EXE_DETAIL_QUERY`, `AI_INS`.
The last five are written but never read by IMPR1110. Keep them until the other IMPR forms are
analysed (step 02 §6.2).

### 13.2 Application process / computation

`IMPR_SET_SESSION_PARAMS` (After Authentication) – fills `AI_P_*` from the user/port tables used by
the Forms login. **MISSING SOURCE** (CIC_MENU / SEC library) → TODO in the IMPR application design,
not per form.

### 13.3 Authorization schemes

| Scheme | Type | Rule | Source |
|---|---|---|---|
| `IMPR1110_ACCESS` | PL/SQL Function Returning Boolean | user may open module IMPR1110 (module security table of the menu) | **TODO** – CIC_MENU / SEC_LIB missing |
| `FUN_IMPR1110F1` … `FUN_IMPR1110F5`, `FUN_IMPR_CAR_AGENT`, `FUN_IMPR_MCI_SERVICE`, `FUN_CREATE_BRKR_IMPR_AUTH`, `FUN_IMPR1115_GZT`, `FUN_IMPR1115_SCR`, `FUN_IMPR1110_MOB`, `FUN_REMOVE` | PL/SQL Function Returning Boolean (evaluated once per page view) | function code is in the user's function list `TMPLT.LOAD_FUNCTIONS(P_USER_ID, P_MODULE_ID)` | **TODO** – TMPLT source missing (step 02 §7.3 #2). `ADJ_FUNS` switches entries off **on top of** this (`ui_json.funs`) |

### 13.4 List `LIST_IMPR1110_FUNS` (function menu = LSIDE / TMPLT)

Labels: the Forms titles come from `SC_SYSTEM_OBJECTS` / TMPLT (MISSING). The labels below are
**proposed** from what each function does and must be replaced by the real titles.

| Seq | Entry (code) | Proposed label | Authorization | Action (`impr1110.fun(code)`) |
|---|---|---|---|---|
| 10 | `IMPR1110F1` | تعديل الاسم من السجل التجاري | `FUN_IMPR1110F1` | open 1113 → DA 15 → DA 12 (Confirm WNRI) |
| 20 | `IMPR1110F2` | تعديل الرقم الإستدلالي / نوع السجل | `FUN_IMPR1110F2` | open 1113 → DA 15 → DA 12 (ADJ_FUNS always disables it) |
| 30 | `IMPR1110F3` | تعديل النشاط التجاري | `FUN_IMPR1110F3` | open 1113 → DA 15 → DA 12; may return `DO_COMMIT` |
| 40 | `IMPR1110F4` | تعديل تاريخ انتهاء النشاط | `FUN_IMPR1110F4` | `IMPR1110_FUN` → DA 12 |
| 50 | `IMPR1110F5` | تعديل الاسم | `FUN_IMPR1110F5` | open 1113 → DA 15 → DA 12 (Confirm WNRI) |
| 60 | `IMPR_CAR_AGENT` | وكيل سيارات | `FUN_IMPR_CAR_AGENT` | `IMPR1110_FUN` → DA 12 (code `IMPR1110SF6`) |
| 70 | `IMPR_MCI_SERVICE` | تحديث البيانات من وزارة التجارة | `FUN_IMPR_MCI_SERVICE` | if `apex.page.isChanged()`: set `P1110_NEXT_FUN`, Submit `SAVE` (Forms commits first); else `IMPR1110_CONFIRM` x01=`UPD_IMPR` → Confirm → `IMPR1110_FUN` x01 code, x02 answer |
| 80 | `CREATE_BRKR_IMPR_AUTH` | إنشاء تفويض مخلص | `FUN_CREATE_BRKR_IMPR_AUTH` | `IMPR1110_FUN` |
| 90 | `IMPR1115_GZT` | شهادة الزكاة | `FUN_IMPR1115_GZT` | `IMPR1110_FUN` |
| 100 | `IMPR1115_SCR` | IMPR1115 | `FUN_IMPR1115_SCR` | link (§12) – TODO when IMPR1115 is converted |
| 110 | `IMPR1110_MOB` | تعديل رقم الجوال | `FUN_IMPR1110_MOB` | `IMPR1110_FUN` (checks `IMPR_NBR > 3000000`) → open 1112 → DA 14 |

### 13.5 Other

* LOVs: §6 (11 shared + 1 inline).
* Static application file: `impr1110.js` (step 04).
* Text messages: none required by the package (§11). TODO: Arabic texts for FRM-40202/40350/40654.
* Collection: `COL_IMPR1110_STATE` (created by `pkg_impr1110_apx`).
* Navigation menu entry for page 1110 (§2).

---

## 14. Traceability matrix (every object of the XML)

Generated from the XML and the step 02 classification: 5 blocks, 158 items, 323 triggers,
53 program units, 8 LOVs, 9 record groups (+ runtime CGDV$DLRG), 9 alerts, 5 canvases, 1 window,
24 parameters, 45 globals, 17 libraries and the called forms.
`DROPPED` = no APEX component, reason in *Notes*. `TODO` = depends on a missing source.

| # | Forms object type | Forms object | APEX component type | APEX component | Page | PL/SQL member | Status | Notes |
|---|---|---|---|---|---|---|---|---|
| 1 | BLOCK | TITLE | REGION | - | - | - | DROPPED | title bar -> APEX page title / header |
| 2 | ITEM | TITLE.CGSO$CHECK_BOX_U | ITEM | - | - | - | DROPPED | OLB block TITLE |
| 3 | ITEM | TITLE.CGSO$CHAR_ARB_ED | ITEM | - | - | - | DROPPED | OLB block TITLE |
| 4 | ITEM | TITLE.CGSO$CHAR_ARB_DO_MLINE | ITEM | - | - | - | DROPPED | OLB block TITLE |
| 5 | ITEM | TITLE.CGSO$CHAR_ARB_ORA_LOV | ITEM | - | - | - | DROPPED | OLB block TITLE |
| 6 | ITEM | TITLE.CGSO$CHAR_ARB_DO_ENB_Y | ITEM | - | - | - | DROPPED | OLB block TITLE |
| 7 | ITEM | TITLE.CGSO$CHAR_ARB_MLINE | ITEM | - | - | - | DROPPED | OLB block TITLE |
| 8 | ITEM | TITLE.CGSO$CHAR_ARB | ITEM | - | - | - | DROPPED | OLB block TITLE |
| 9 | ITEM | TITLE.CGSO$CHAR_ARB_DO | ITEM | - | - | - | DROPPED | OLB block TITLE |
| 10 | ITEM | TITLE.SCREEN_NAME | ITEM | - | - | - | DROPPED | OLB block TITLE |
| 11 | ITEM | TITLE.USER_NAME | ITEM | - | - | - | DROPPED | OLB block TITLE |
| 12 | ITEM | TITLE.SYSTEM_DATE | ITEM | - | - | - | DROPPED | OLB block TITLE |
| 13 | ITEM | TITLE.VERSION | ITEM | - | - | - | DROPPED | OLB block TITLE |
| 14 | BLOCK | EDI_MSG | REGION | - | - | - | DROPPED | EDI message ticker (units not called) |
| 15 | ITEM | EDI_MSG.EDI_MSG_TXT | ITEM | - | - | - | DROPPED | OLB block EDI_MSG |
| 16 | ITEM | EDI_MSG.EDI_MSG_LOVE_BUT | ITEM | - | - | - | DROPPED | OLB block EDI_MSG |
| 17 | BLOCK | LSIDE | REGION | - | - | - | DROPPED | side function menu -> FUNCTIONS menu button |
| 18 | ITEM | LSIDE.FN1 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 19 | ITEM | LSIDE.FN50 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 20 | ITEM | LSIDE.FN2 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 21 | ITEM | LSIDE.FN49 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 22 | ITEM | LSIDE.FN3 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 23 | ITEM | LSIDE.FN48 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 24 | ITEM | LSIDE.FN4 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 25 | ITEM | LSIDE.FN47 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 26 | ITEM | LSIDE.FN5 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 27 | ITEM | LSIDE.FN46 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 28 | ITEM | LSIDE.FN6 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 29 | ITEM | LSIDE.FN45 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 30 | ITEM | LSIDE.FN7 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 31 | ITEM | LSIDE.FN44 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 32 | ITEM | LSIDE.FN8 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 33 | ITEM | LSIDE.FN43 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 34 | ITEM | LSIDE.FN9 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 35 | ITEM | LSIDE.FN42 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 36 | ITEM | LSIDE.FN10 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 37 | ITEM | LSIDE.FN41 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 38 | ITEM | LSIDE.FN11 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 39 | ITEM | LSIDE.FN40 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 40 | ITEM | LSIDE.FN12 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 41 | ITEM | LSIDE.FN39 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 42 | ITEM | LSIDE.FN13 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 43 | ITEM | LSIDE.FN38 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 44 | ITEM | LSIDE.FN14 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 45 | ITEM | LSIDE.FN37 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 46 | ITEM | LSIDE.FN15 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 47 | ITEM | LSIDE.FN36 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 48 | ITEM | LSIDE.FN16 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 49 | ITEM | LSIDE.FN17 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 50 | ITEM | LSIDE.FN34 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 51 | ITEM | LSIDE.FN35 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 52 | ITEM | LSIDE.FN18 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 53 | ITEM | LSIDE.FN33 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 54 | ITEM | LSIDE.FN19 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 55 | ITEM | LSIDE.FN32 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 56 | ITEM | LSIDE.FN20 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 57 | ITEM | LSIDE.FN31 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 58 | ITEM | LSIDE.FN21 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 59 | ITEM | LSIDE.FN30 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 60 | ITEM | LSIDE.FN22 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 61 | ITEM | LSIDE.FN29 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 62 | ITEM | LSIDE.FN23 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 63 | ITEM | LSIDE.FN28 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 64 | ITEM | LSIDE.FN24 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 65 | ITEM | LSIDE.FN27 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 66 | ITEM | LSIDE.FN25 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 67 | ITEM | LSIDE.FN26 | ITEM | - | - | - | DROPPED | OLB block LSIDE |
| 68 | BLOCK | TOOLBAR | REGION | TOOLBAR (Buttons Container, page 1110) | 1110 | - | MAPPED | OLB toolbar -> SAVE/CREATE/DELETE/QUERY/CLEAR/EXIT + FUNCTIONS menu |
| 69 | ITEM | TOOLBAR.DUMMY | ITEM | - | - | - | DROPPED | OLB block TOOLBAR |
| 70 | ITEM | TOOLBAR.SAVE | BUTTON | SAVE | 1110 | - | MAPPED | toolbar button |
| 71 | ITEM | TOOLBAR.CLEAR_ALL | BUTTON | CLEAR | 1110 | - | MAPPED | toolbar button |
| 72 | ITEM | TOOLBAR.EXIT | BUTTON | EXIT | 1110 | - | MAPPED | toolbar button |
| 73 | ITEM | TOOLBAR.EXIT1 | ITEM | - | - | - | DROPPED | OLB block TOOLBAR |
| 74 | ITEM | TOOLBAR.ENTER | BUTTON | QUERY | 1110 | - | MAPPED | toolbar button |
| 75 | ITEM | TOOLBAR.EXECUTE | BUTTON | QUERY | 1110 | - | MAPPED | toolbar button |
| 76 | ITEM | TOOLBAR.REMOVE | BUTTON | DELETE | 1110 | - | MAPPED | toolbar button |
| 77 | ITEM | TOOLBAR.LIST_VALUE | BUTTON | - | - | - | DROPPED | Popup LOV icon replaces the LOV toolbar button |
| 78 | ITEM | TOOLBAR.HELP | ITEM | - | - | - | DROPPED | OLB block TOOLBAR |
| 79 | ITEM | TOOLBAR.LAST_REC | ITEM | - | - | - | DROPPED | OLB block TOOLBAR |
| 80 | ITEM | TOOLBAR.RE_ENTER_QUERY | BUTTON | QUERY | 1110 | - | MAPPED | toolbar button |
| 81 | ITEM | TOOLBAR.FIRST_REC | ITEM | - | - | - | DROPPED | OLB block TOOLBAR |
| 82 | ITEM | TOOLBAR.PAGE_UP | ITEM | - | - | - | DROPPED | OLB block TOOLBAR |
| 83 | ITEM | TOOLBAR.PAGE_DOWN | ITEM | - | - | - | DROPPED | OLB block TOOLBAR |
| 84 | ITEM | TOOLBAR.FUN_BUT | BUTTON | FUNCTIONS | 1110 | - | MAPPED | toolbar button |
| 85 | BLOCK | IMPORTERS | REGION | IMPORTERS (Static Content, page 1110) | 1110 | PKG_IMPR1110 | MAPPED | single-record base-table block; DML via pkg_impr1110_apx.page_dml |
| 86 | ITEM | IMPORTERS.SDP_PORT_STATUS | ITEM | P1110_SDP_PORT_STATUS | 1110 | - | MAPPED | - |
| 87 | ITEM | IMPORTERS.L_CT_CITY_STATUS2 | ITEM | P1110_L_CT_CITY_STATUS2 | 1110 | - | MAPPED | - |
| 88 | ITEM | IMPORTERS.L_CT_CITY_STATUS | ITEM | P1110_L_CT_CITY_STATUS | 1110 | - | MAPPED | - |
| 89 | ITEM | IMPORTERS.PORT_CD | ITEM | P1110_PORT_CD | 1110 | - | MAPPED | - |
| 90 | ITEM | IMPORTERS.PORT_CD2 | ITEM | - | - | - | DROPPED | LOV button - Popup LOV / select list has its own control |
| 91 | ITEM | IMPORTERS.PORT_NAME | ITEM | P1110_PORT_NAME | 1110 | - | MAPPED | - |
| 92 | ITEM | IMPORTERS.HQ_IMPR_NBR | ITEM | P1110_HQ_IMPR_NBR | 1110 | - | MAPPED | - |
| 93 | ITEM | IMPORTERS.IMPR_NBR | ITEM | P1110_IMPR_NBR | 1110 | - | MAPPED | - |
| 94 | ITEM | IMPORTERS.SUSPN_STATUS | ITEM | P1110_SUSPN_STATUS | 1110 | - | MAPPED | - |
| 95 | ITEM | IMPORTERS.STATUS_DESC | ITEM | P1110_STATUS_DESC | 1110 | - | MAPPED | - |
| 96 | ITEM | IMPORTERS.BUS_ID_STATUS | ITEM | P1110_BUS_ID_STATUS | 1110 | - | MAPPED | - |
| 97 | ITEM | IMPORTERS.IMPR_TYPE_CD | ITEM | P1110_IMPR_TYPE_CD | 1110 | - | MAPPED | - |
| 98 | ITEM | IMPORTERS.IMPR_TYPE_CD2 | ITEM | - | - | - | DROPPED | LOV button - Popup LOV / select list has its own control |
| 99 | ITEM | IMPORTERS.IMPR_TYPE_NAME | ITEM | P1110_IMPR_TYPE_NAME | 1110 | - | MAPPED | - |
| 100 | ITEM | IMPORTERS.BUS_ID_EXPRD_DT | ITEM | P1110_BUS_ID_EXPRD_DT | 1110 | - | MAPPED | - |
| 101 | ITEM | IMPORTERS.BUS_ID_TYPE_CD | ITEM | P1110_BUS_ID_TYPE_CD | 1110 | - | MAPPED | - |
| 102 | ITEM | IMPORTERS.BUTT | ITEM | - | - | - | DROPPED | LOV button - Popup LOV / select list has its own control |
| 103 | ITEM | IMPORTERS.BUS_ID_TYPE_NAME | ITEM | P1110_BUS_ID_TYPE_NAME | 1110 | - | MAPPED | - |
| 104 | ITEM | IMPORTERS.COMM_RGSTRTN_TYPE | ITEM | P1110_COMM_RGSTRTN_TYPE | 1110 | - | MAPPED | - |
| 105 | ITEM | IMPORTERS.CITY_CODE_OF_ID | ITEM | P1110_CITY_CODE_OF_ID | 1110 | - | MAPPED | - |
| 106 | ITEM | IMPORTERS.CITY_CODE_OF_ID2 | ITEM | - | - | - | DROPPED | LOV button - Popup LOV / select list has its own control |
| 107 | ITEM | IMPORTERS.ID_CITY_NAME | ITEM | P1110_ID_CITY_NAME | 1110 | - | MAPPED | - |
| 108 | ITEM | IMPORTERS.BUS_ID | ITEM | P1110_BUS_ID | 1110 | - | MAPPED | - |
| 109 | ITEM | IMPORTERS.BRNH_ID_MINS_COMM_CD | ITEM | P1110_BRNH_ID_MINS_COMM_CD | 1110 | - | MAPPED | - |
| 110 | ITEM | IMPORTERS.BRNH_CITY_CD | ITEM | P1110_BRNH_CITY_CD | 1110 | - | MAPPED | - |
| 111 | ITEM | IMPORTERS.BRNH_CITY_CD_LOV | ITEM | - | - | - | DROPPED | LOV button - Popup LOV / select list has its own control |
| 112 | ITEM | IMPORTERS.BRNH_CITY_NAME | ITEM | P1110_BRNH_CITY_NAME | 1110 | - | MAPPED | - |
| 113 | ITEM | IMPORTERS.BUS_ID_BRNCH | ITEM | P1110_BUS_ID_BRNCH | 1110 | - | MAPPED | - |
| 114 | ITEM | IMPORTERS.CTRY_CD | ITEM | P1110_CTRY_CD | 1110 | - | MAPPED | - |
| 115 | ITEM | IMPORTERS.CTRY_CD2 | ITEM | - | - | - | DROPPED | LOV button - Popup LOV / select list has its own control |
| 116 | ITEM | IMPORTERS.CRTY_ARBC_NAME | ITEM | P1110_CRTY_ARBC_NAME | 1110 | - | MAPPED | - |
| 117 | ITEM | IMPORTERS.IMPR_EXPR_TYPE | ITEM | P1110_IMPR_EXPR_TYPE | 1110 | - | MAPPED | - |
| 118 | ITEM | IMPORTERS.CTRY_CTRY_STATUS | ITEM | P1110_CTRY_CTRY_STATUS | 1110 | - | MAPPED | - |
| 119 | ITEM | IMPORTERS.ID_MINS_COMM_CD | ITEM | P1110_ID_MINS_COMM_CD | 1110 | - | MAPPED | - |
| 120 | ITEM | IMPORTERS.ITIDT_NOTE | ITEM | P1110_ITIDT_NOTE | 1110 | - | MAPPED | - |
| 121 | ITEM | IMPORTERS.ARBC_IMPR_NAME | ITEM | P1110_ARBC_IMPR_NAME | 1110 | - | MAPPED | - |
| 122 | ITEM | IMPORTERS.IMPR_NAME_STD | ITEM | P1110_IMPR_NAME_STD | 1110 | - | MAPPED | - |
| 123 | ITEM | IMPORTERS.LST_TRAN_DT | ITEM | P1110_LST_TRAN_DT | 1110 | - | MAPPED | - |
| 124 | ITEM | IMPORTERS.IMPD_STMT_NBR | ITEM | P1110_IMPD_STMT_NBR | 1110 | - | MAPPED | - |
| 125 | ITEM | IMPORTERS.IMPR_DATA_SRCE | ITEM | P1110_IMPR_DATA_SRCE | 1110 | - | MAPPED | - |
| 126 | ITEM | IMPORTERS.ENG_IMPR_NAME | ITEM | P1110_ENG_IMPR_NAME | 1110 | - | MAPPED | - |
| 127 | ITEM | IMPORTERS.IMPR_CNTCT_NAME | ITEM | P1110_IMPR_CNTCT_NAME | 1110 | - | MAPPED | - |
| 128 | ITEM | IMPORTERS.IMPR_ADDRESS | ITEM | P1110_IMPR_ADDRESS | 1110 | - | MAPPED | - |
| 129 | ITEM | IMPORTERS.BUS_ID_ISSUE_DT | ITEM | P1110_BUS_ID_ISSUE_DT | 1110 | - | MAPPED | - |
| 130 | ITEM | IMPORTERS.STATUS | ITEM | P1110_STATUS | 1110 | - | MAPPED | - |
| 131 | ITEM | IMPORTERS.IMPR_NBR_PARENT | ITEM | P1110_IMPR_NBR_PARENT | 1110 | - | MAPPED | - |
| 132 | ITEM | IMPORTERS.IMPR_NBR_PARENT2 | ITEM | - | - | - | DROPPED | LOV button - Popup LOV / select list has its own control |
| 133 | ITEM | IMPORTERS.IMPR_NAME_PARENT | ITEM | P1110_IMPR_NAME_PARENT | 1110 | - | MAPPED | - |
| 134 | ITEM | IMPORTERS.WASL_CITY_NAME | ITEM | P1110_WASL_CITY_NAME | 1110 | - | MAPPED | - |
| 135 | ITEM | IMPORTERS.ADD_CTRY_CD | ITEM | P1110_ADD_CTRY_CD | 1110 | - | MAPPED | - |
| 136 | ITEM | IMPORTERS.ADD_CTRY_CD2 | ITEM | - | - | - | DROPPED | LOV button - Popup LOV / select list has its own control |
| 137 | ITEM | IMPORTERS.ADD_CRTY_ARBC_NAME | ITEM | P1110_ADD_CRTY_ARBC_NAME | 1110 | - | MAPPED | - |
| 138 | ITEM | IMPORTERS.CITY_CODE | ITEM | P1110_CITY_CODE | 1110 | - | MAPPED | - |
| 139 | ITEM | IMPORTERS.CITY_CODE2 | ITEM | - | - | - | DROPPED | LOV button - Popup LOV / select list has its own control |
| 140 | ITEM | IMPORTERS.CITY_NAME | ITEM | P1110_CITY_NAME | 1110 | - | MAPPED | - |
| 141 | ITEM | IMPORTERS.IMPR_POB_NBR | ITEM | P1110_IMPR_POB_NBR | 1110 | - | MAPPED | - |
| 142 | ITEM | IMPORTERS.IMPR_ZIP_CD | ITEM | P1110_IMPR_ZIP_CD | 1110 | - | MAPPED | - |
| 143 | ITEM | IMPORTERS.IMPR_TEL_NBR | ITEM | P1110_IMPR_TEL_NBR | 1110 | - | MAPPED | - |
| 144 | ITEM | IMPORTERS.IMPR_FAX_NBR | ITEM | P1110_IMPR_FAX_NBR | 1110 | - | MAPPED | - |
| 145 | ITEM | IMPORTERS.IMPR_TELEX_NBR | ITEM | P1110_IMPR_TELEX_NBR | 1110 | - | MAPPED | - |
| 146 | ITEM | IMPORTERS.B_EMAIL | ITEM | P1110_B_EMAIL | 1110 | - | MAPPED | - |
| 147 | ITEM | IMPORTERS.EMAIL | ITEM | P1110_EMAIL | 1110 | - | MAPPED | - |
| 148 | ITEM | IMPORTERS.B_MOBILE_NO | ITEM | P1110_B_MOBILE_NO | 1110 | - | MAPPED | - |
| 149 | ITEM | IMPORTERS.MOBILE_NO | ITEM | P1110_MOBILE_NO | 1110 | - | MAPPED | - |
| 150 | ITEM | IMPORTERS.BANK_IBAN | ITEM | P1110_BANK_IBAN | 1110 | - | MAPPED | - |
| 151 | ITEM | IMPORTERS.B_ID_NBR | ITEM | P1110_B_ID_NBR | 1110 | - | MAPPED | - |
| 152 | ITEM | IMPORTERS.ID_NBR | ITEM | P1110_ID_NBR | 1110 | - | MAPPED | - |
| 153 | ITEM | IMPORTERS.CAR_AGENT_FLAG | ITEM | P1110_CAR_AGENT_FLAG | 1110 | - | MAPPED | - |
| 154 | ITEM | IMPORTERS.EXPRESS_POST | ITEM | P1110_EXPRESS_POST | 1110 | - | MAPPED | - |
| 155 | ITEM | IMPORTERS.IMPR_ID_TYPE | ITEM | P1110_IMPR_ID_TYPE | 1110 | - | MAPPED | - |
| 156 | ITEM | IMPORTERS.CTRY_CD_OF_ID | ITEM | P1110_CTRY_CD_OF_ID | 1110 | - | MAPPED | - |
| 157 | ITEM | IMPORTERS.EXPD_STMT_NBR | ITEM | P1110_EXPD_STMT_NBR | 1110 | - | MAPPED | - |
| 158 | ITEM | IMPORTERS.WVR_ENTRY_NBR | ITEM | P1110_WVR_ENTRY_NBR | 1110 | - | MAPPED | - |
| 159 | ITEM | IMPORTERS.ACTIVITY | ITEM | P1110_ACTIVITY | 1110 | - | MAPPED | - |
| 160 | ITEM | IMPORTERS.CUSTOMS_ENTERED | ITEM | P1110_CUSTOMS_ENTERED | 1110 | - | MAPPED | - |
| 161 | ITEM | IMPORTERS.CUSTOMS_ENTERED2 | ITEM | - | - | - | DROPPED | LOV button - Popup LOV / select list has its own control |
| 162 | ITEM | IMPORTERS.CREATION_FLAG | ITEM | P1110_CREATION_FLAG | 1110 | - | MAPPED | - |
| 163 | ITEM | IMPORTERS.CREATION_FLAG2 | ITEM | - | - | - | DROPPED | LOV button - Popup LOV / select list has its own control |
| 164 | TRIGGER | FORM.KEY-EDIT | - | - | - | - | DROPPED | NIB.KEY_EDIT (MISSING SOURCE, toolbar key library) - APEX buttons/keys |
| 165 | TRIGGER | FORM.KEY-DUPREC | - | - | - | - | DROPPED | NIB.KEY_DUPREC (MISSING SOURCE, toolbar key library) - APEX buttons/keys |
| 166 | TRIGGER | FORM.PRE-FORM | - | - | - | - | DROPPED | NIB.PRE_FORM (MISSING SOURCE), version globals, NLS date compat, help path - not needed in APEX; date masks set per item |
| 167 | TRIGGER | FORM.WHEN-NEW-FORM-INSTANCE | PROCESS | WHEN-NEW-FORM-INSTANCE (Before Header) | 1110 | PKG_IMPR1110.WNFI | MAPPED | Process "WHEN-NEW-FORM-INSTANCE" (Before Header). NIB.WHEN_NEW_FORM_INSTANCE + CG$WHEN_NEW_FORM_INSTANCE dropped (toolbar library / list population) |
| 168 | TRIGGER | FORM.WHEN-WINDOW-ACTIVATED | - | - | - | - | DROPPED | NIB.WHEN_WINDOW_ACTIVATED (MISSING SOURCE, toolbar key library) - APEX buttons/keys |
| 169 | TRIGGER | FORM.KEY-ENTQRY | - | - | - | - | DROPPED | NIB.KEY_ENTQRY (MISSING SOURCE, toolbar key library) - APEX buttons/keys |
| 170 | TRIGGER | FORM.ON-ERROR | - | - | - | - | DROPPED | NIB.ON_ERROR (MISSING SOURCE, toolbar key library) - APEX buttons/keys |
| 171 | TRIGGER | FORM.ON-MESSAGE | - | - | - | - | DROPPED | NIB.ON_MESSAGE (MISSING SOURCE, toolbar key library) - APEX buttons/keys |
| 172 | TRIGGER | FORM.KEY-CLRBLK | - | - | - | - | DROPPED | NIB.KEY_CLRBLK (MISSING SOURCE, toolbar key library) - APEX buttons/keys |
| 173 | TRIGGER | FORM.KEY-DELREC | - | - | - | - | DROPPED | NIB.KEY_DELREC (MISSING SOURCE, toolbar key library) - APEX buttons/keys |
| 174 | TRIGGER | FORM.KEY-F5 | - | - | - | - | DROPPED | NIB.KEY_F5 (MISSING SOURCE, toolbar key library) - APEX buttons/keys |
| 175 | TRIGGER | FORM.KEY-F4 | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 176 | TRIGGER | FORM.KEY-NXTREC | - | - | - | - | DROPPED | NIB.KEY_NXTREC (MISSING SOURCE, toolbar key library) - APEX buttons/keys |
| 177 | TRIGGER | FORM.KEY-PRVREC | - | - | - | - | DROPPED | NIB.KEY_PRVREC (MISSING SOURCE, toolbar key library) - APEX buttons/keys |
| 178 | TRIGGER | FORM.KEY-DOWN | - | - | - | - | DROPPED | NIB.KEY_DOWN (MISSING SOURCE, toolbar key library) - APEX buttons/keys |
| 179 | TRIGGER | FORM.KEY-UP | - | - | - | - | DROPPED | NIB.KEY_UP (MISSING SOURCE, toolbar key library) - APEX buttons/keys |
| 180 | TRIGGER | FORM.KEY-SCRUP | - | - | - | - | DROPPED | NIB.KEY_SCRUP (MISSING SOURCE, toolbar key library) - APEX buttons/keys |
| 181 | TRIGGER | FORM.KEY-SCRDOWN | - | - | - | - | DROPPED | NIB.KEY_SCRDOWN (MISSING SOURCE, toolbar key library) - APEX buttons/keys |
| 182 | TRIGGER | FORM.KEY-PRINT | - | - | - | - | DROPPED | NIB.KEY_PRINT (MISSING SOURCE, toolbar key library) - APEX buttons/keys |
| 183 | TRIGGER | FORM.KEY-EXIT | - | - | - | - | DROPPED | NIB.KEY_EXIT (MISSING SOURCE, toolbar key library) - APEX buttons/keys |
| 184 | TRIGGER | FORM.WHEN-MOUSE-DOWN | - | - | - | - | DROPPED | NIB.WHEN_MOUSE_DOWN (MISSING SOURCE, toolbar key library) - APEX buttons/keys |
| 185 | TRIGGER | FORM.KEY-EXEQRY | - | - | - | - | DROPPED | NIB.KEY_EXEQRY (MISSING SOURCE, toolbar key library) - APEX buttons/keys |
| 186 | TRIGGER | FORM.KEY-F9 | DYNAMIC_ACTION | FORM.KEY-F9 | 1110 | - | MAPPED | Function side menu (LSIDE) toggle -> APEX "Functions" menu; calls ADJ_FUNS -> pkg_impr1110.adj_funs |
| 187 | TRIGGER | FORM.WHEN-TIMER-EXPIRED | - | - | - | - | DROPPED | NIB.WHEN_TIMER_EXPIRED (MISSING SOURCE, toolbar key library) - APEX buttons/keys |
| 188 | TRIGGER | FORM.KEY-HELP | - | - | - | - | DROPPED | CG help call; help file is empty in the form |
| 189 | TRIGGER | FORM.KEY-CLRFRM | DYNAMIC_ACTION | FORM.KEY-CLRFRM | 1110 | - | MAPPED | CLEAR button (clear cache of page 1110); list population dropped |
| 190 | TRIGGER | TITLE.CGSO$CHAR_ARB_ED.KEY-LISTVAL | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 191 | TRIGGER | TITLE.CGSO$CHAR_ARB_DO_ENB_Y.KEY-LISTVAL | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 192 | TRIGGER | TITLE.CGSO$CHAR_ARB_MLINE.KEY-LISTVAL | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 193 | TRIGGER | TITLE.CGSO$CHAR_ARB.KEY-LISTVAL | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 194 | TRIGGER | TITLE.CGSO$CHAR_ARB_DO.KEY-LISTVAL | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 195 | TRIGGER | TITLE.SYSTEM_DATE.WHEN-VALIDATE-ITEM | - | - | - | - | DROPPED | Title bar date (OLB block TITLE) |
| 196 | TRIGGER | EDI_MSG.EDI_MSG_LOVE_BUT.WHEN-BUTTON-PRESSED | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 197 | TRIGGER | LSIDE.FN1.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 198 | TRIGGER | LSIDE.FN1.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 199 | TRIGGER | LSIDE.FN1.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 200 | TRIGGER | LSIDE.FN50.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 201 | TRIGGER | LSIDE.FN50.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 202 | TRIGGER | LSIDE.FN50.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 203 | TRIGGER | LSIDE.FN2.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 204 | TRIGGER | LSIDE.FN2.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 205 | TRIGGER | LSIDE.FN2.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 206 | TRIGGER | LSIDE.FN49.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 207 | TRIGGER | LSIDE.FN49.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 208 | TRIGGER | LSIDE.FN49.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 209 | TRIGGER | LSIDE.FN3.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 210 | TRIGGER | LSIDE.FN3.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 211 | TRIGGER | LSIDE.FN3.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 212 | TRIGGER | LSIDE.FN48.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 213 | TRIGGER | LSIDE.FN48.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 214 | TRIGGER | LSIDE.FN48.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 215 | TRIGGER | LSIDE.FN4.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 216 | TRIGGER | LSIDE.FN4.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 217 | TRIGGER | LSIDE.FN4.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 218 | TRIGGER | LSIDE.FN47.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 219 | TRIGGER | LSIDE.FN47.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 220 | TRIGGER | LSIDE.FN47.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 221 | TRIGGER | LSIDE.FN5.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 222 | TRIGGER | LSIDE.FN5.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 223 | TRIGGER | LSIDE.FN5.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 224 | TRIGGER | LSIDE.FN46.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 225 | TRIGGER | LSIDE.FN46.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 226 | TRIGGER | LSIDE.FN46.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 227 | TRIGGER | LSIDE.FN6.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 228 | TRIGGER | LSIDE.FN6.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 229 | TRIGGER | LSIDE.FN6.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 230 | TRIGGER | LSIDE.FN45.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 231 | TRIGGER | LSIDE.FN45.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 232 | TRIGGER | LSIDE.FN45.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 233 | TRIGGER | LSIDE.FN7.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 234 | TRIGGER | LSIDE.FN7.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 235 | TRIGGER | LSIDE.FN7.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 236 | TRIGGER | LSIDE.FN44.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 237 | TRIGGER | LSIDE.FN44.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 238 | TRIGGER | LSIDE.FN44.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 239 | TRIGGER | LSIDE.FN8.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 240 | TRIGGER | LSIDE.FN8.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 241 | TRIGGER | LSIDE.FN8.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 242 | TRIGGER | LSIDE.FN43.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 243 | TRIGGER | LSIDE.FN43.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 244 | TRIGGER | LSIDE.FN43.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 245 | TRIGGER | LSIDE.FN9.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 246 | TRIGGER | LSIDE.FN9.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 247 | TRIGGER | LSIDE.FN9.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 248 | TRIGGER | LSIDE.FN42.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 249 | TRIGGER | LSIDE.FN42.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 250 | TRIGGER | LSIDE.FN42.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 251 | TRIGGER | LSIDE.FN10.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 252 | TRIGGER | LSIDE.FN10.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 253 | TRIGGER | LSIDE.FN10.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 254 | TRIGGER | LSIDE.FN41.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 255 | TRIGGER | LSIDE.FN41.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 256 | TRIGGER | LSIDE.FN41.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 257 | TRIGGER | LSIDE.FN11.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 258 | TRIGGER | LSIDE.FN11.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 259 | TRIGGER | LSIDE.FN11.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 260 | TRIGGER | LSIDE.FN40.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 261 | TRIGGER | LSIDE.FN40.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 262 | TRIGGER | LSIDE.FN40.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 263 | TRIGGER | LSIDE.FN12.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 264 | TRIGGER | LSIDE.FN12.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 265 | TRIGGER | LSIDE.FN12.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 266 | TRIGGER | LSIDE.FN39.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 267 | TRIGGER | LSIDE.FN39.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 268 | TRIGGER | LSIDE.FN39.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 269 | TRIGGER | LSIDE.FN13.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 270 | TRIGGER | LSIDE.FN13.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 271 | TRIGGER | LSIDE.FN13.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 272 | TRIGGER | LSIDE.FN38.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 273 | TRIGGER | LSIDE.FN38.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 274 | TRIGGER | LSIDE.FN38.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 275 | TRIGGER | LSIDE.FN14.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 276 | TRIGGER | LSIDE.FN14.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 277 | TRIGGER | LSIDE.FN14.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 278 | TRIGGER | LSIDE.FN37.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 279 | TRIGGER | LSIDE.FN37.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 280 | TRIGGER | LSIDE.FN37.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 281 | TRIGGER | LSIDE.FN15.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 282 | TRIGGER | LSIDE.FN15.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 283 | TRIGGER | LSIDE.FN15.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 284 | TRIGGER | LSIDE.FN36.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 285 | TRIGGER | LSIDE.FN36.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 286 | TRIGGER | LSIDE.FN36.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 287 | TRIGGER | LSIDE.FN16.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 288 | TRIGGER | LSIDE.FN16.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 289 | TRIGGER | LSIDE.FN16.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 290 | TRIGGER | LSIDE.FN17.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 291 | TRIGGER | LSIDE.FN17.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 292 | TRIGGER | LSIDE.FN17.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 293 | TRIGGER | LSIDE.FN34.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 294 | TRIGGER | LSIDE.FN34.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 295 | TRIGGER | LSIDE.FN34.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 296 | TRIGGER | LSIDE.FN35.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 297 | TRIGGER | LSIDE.FN35.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 298 | TRIGGER | LSIDE.FN35.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 299 | TRIGGER | LSIDE.FN18.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 300 | TRIGGER | LSIDE.FN18.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 301 | TRIGGER | LSIDE.FN18.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 302 | TRIGGER | LSIDE.FN33.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 303 | TRIGGER | LSIDE.FN33.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 304 | TRIGGER | LSIDE.FN33.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 305 | TRIGGER | LSIDE.FN19.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 306 | TRIGGER | LSIDE.FN19.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 307 | TRIGGER | LSIDE.FN19.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 308 | TRIGGER | LSIDE.FN32.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 309 | TRIGGER | LSIDE.FN32.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 310 | TRIGGER | LSIDE.FN32.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 311 | TRIGGER | LSIDE.FN20.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 312 | TRIGGER | LSIDE.FN20.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 313 | TRIGGER | LSIDE.FN20.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 314 | TRIGGER | LSIDE.FN31.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 315 | TRIGGER | LSIDE.FN31.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 316 | TRIGGER | LSIDE.FN31.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 317 | TRIGGER | LSIDE.FN21.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 318 | TRIGGER | LSIDE.FN21.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 319 | TRIGGER | LSIDE.FN21.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 320 | TRIGGER | LSIDE.FN30.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 321 | TRIGGER | LSIDE.FN30.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 322 | TRIGGER | LSIDE.FN30.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 323 | TRIGGER | LSIDE.FN22.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 324 | TRIGGER | LSIDE.FN22.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 325 | TRIGGER | LSIDE.FN22.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 326 | TRIGGER | LSIDE.FN29.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 327 | TRIGGER | LSIDE.FN29.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 328 | TRIGGER | LSIDE.FN29.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 329 | TRIGGER | LSIDE.FN23.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 330 | TRIGGER | LSIDE.FN23.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 331 | TRIGGER | LSIDE.FN23.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 332 | TRIGGER | LSIDE.FN28.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 333 | TRIGGER | LSIDE.FN28.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 334 | TRIGGER | LSIDE.FN28.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 335 | TRIGGER | LSIDE.FN24.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 336 | TRIGGER | LSIDE.FN24.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 337 | TRIGGER | LSIDE.FN24.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 338 | TRIGGER | LSIDE.FN27.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 339 | TRIGGER | LSIDE.FN27.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 340 | TRIGGER | LSIDE.FN27.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 341 | TRIGGER | LSIDE.FN25.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 342 | TRIGGER | LSIDE.FN25.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 343 | TRIGGER | LSIDE.FN25.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 344 | TRIGGER | LSIDE.FN26.WHEN-MOUSE-ENTER | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 345 | TRIGGER | LSIDE.FN26.WHEN-MOUSE-LEAVE | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 346 | TRIGGER | LSIDE.FN26.WHEN-MOUSE-CLICK | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 347 | TRIGGER | TOOLBAR.KEY-DOWN | - | - | - | - | DROPPED | Function menu keyboard |
| 348 | TRIGGER | TOOLBAR.KEY-UP | - | - | - | - | DROPPED | Function menu keyboard |
| 349 | TRIGGER | TOOLBAR.KEY-NEXT-ITEM | - | - | - | - | DROPPED | Keyboard navigation of the function menu |
| 350 | TRIGGER | TOOLBAR.SAVE.WHEN-BUTTON-PRESSED | BUTTON | SAVE | 1110 | - | MAPPED | SAVE button -> page_dml(SAVE); title refresh dropped |
| 351 | TRIGGER | TOOLBAR.CLEAR_ALL.WHEN-BUTTON-PRESSED | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 352 | TRIGGER | TOOLBAR.EXIT.WHEN-BUTTON-PRESSED | BUTTON | EXIT | 1110 | - | MAPPED | EXIT button -> branch to menu; :GLOBAL.EXIT=2 is set by other forms only |
| 353 | TRIGGER | TOOLBAR.EXIT1.WHEN-BUTTON-PRESSED | - | - | - | - | DROPPED | Toolbar button visibility (OLB) |
| 354 | TRIGGER | TOOLBAR.ENTER.WHEN-BUTTON-PRESSED | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 355 | TRIGGER | TOOLBAR.EXECUTE.WHEN-BUTTON-PRESSED | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 356 | TRIGGER | TOOLBAR.REMOVE.WHEN-BUTTON-PRESSED | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 357 | TRIGGER | TOOLBAR.LIST_VALUE.WHEN-BUTTON-PRESSED | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 358 | TRIGGER | TOOLBAR.HELP.WHEN-BUTTON-PRESSED | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 359 | TRIGGER | TOOLBAR.LAST_REC.WHEN-BUTTON-PRESSED | - | - | - | - | DROPPED | Single-record form region |
| 360 | TRIGGER | TOOLBAR.RE_ENTER_QUERY.WHEN-BUTTON-PRESSED | DYNAMIC_ACTION | TOOLBAR.RE_ENTER_QUERY.WHEN-BUTTON-PRESSED | 1110 | - | MAPPED | QUERY button -> search region |
| 361 | TRIGGER | TOOLBAR.FIRST_REC.WHEN-BUTTON-PRESSED | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 362 | TRIGGER | TOOLBAR.PAGE_UP.WHEN-BUTTON-PRESSED | - | - | - | - | DROPPED | no active code (OLB-inherited or fully commented out) |
| 363 | TRIGGER | TOOLBAR.PAGE_DOWN.WHEN-BUTTON-PRESSED | - | - | - | - | DROPPED | Single-record form region |
| 364 | TRIGGER | TOOLBAR.FUN_BUT.WHEN-MOUSE-UP | - | - | - | - | DROPPED | Side function menu (TMPLT) |
| 365 | TRIGGER | TOOLBAR.FUN_BUT.WHEN-MOUSE-DOWN | DYNAMIC_ACTION | TOOLBAR.FUN_BUT.WHEN-MOUSE-DOWN | 1110 | - | MAPPED | Opens function menu; calls ADJ_FUNS -> pkg_impr1110.adj_funs |
| 366 | TRIGGER | IMPORTERS.ON-ERROR | PROCESS | error text via pkg_impr1110_apx.err_text | 1110 | PKG_IMPR1110.IMPORTERS_ON_ERROR | MAPPED | Used by pkg_impr1110_apx.err_text for DB errors |
| 367 | TRIGGER | IMPORTERS.POST-QUERY | PROCESS | IMPORTERS.POST-QUERY (Before Header, page_fetch) | 1110 | PKG_IMPR1110.IMPORTERS_POST_QRY | MAPPED | Process "IMPORTERS.POST-QUERY" via pkg_impr1110_apx.page_fetch |
| 368 | TRIGGER | IMPORTERS.PRE-QUERY | PROCESS | IMPORTERS.POST-QUERY (Before Header, page_fetch) | 1110 | PKG_IMPR1110.IMPORTERS_PRE_QRY | MAPPED | EXEC_QUERY_NOW / PRSNL_IMPR / name criterion; PORT_NAME criterion -> region SQL |
| 369 | TRIGGER | IMPORTERS.PRE-INSERT | PROCESS | IMPORTERS.PRE-INSERT…POST-UPDATE (page_dml SAVE) | 1110 | PKG_IMPR1110.IMPORTERS_PRE_INS | MAPPED | Process "IMPORTERS.PRE-INSERT"; CONFIRM for class 1/type 3 -> Confirm DA on SAVE |
| 370 | TRIGGER | IMPORTERS.KEY-HELP | - | - | - | - | DROPPED | 9 copies of the CG help call; help file is empty |
| 371 | TRIGGER | IMPORTERS.KEY-DELREC | PROCESS | IMPORTERS.KEY-DELREC (page_dml DELETE) | 1110 | PKG_IMPR1110.IMPORTERS_KEY_DELREC | MAPPED | DELETE button + Confirm DA; REMOVE visible/enabled -> button condition |
| 372 | TRIGGER | IMPORTERS.POST-INSERT | PROCESS | IMPORTERS.PRE-INSERT…POST-UPDATE (page_dml SAVE) | 1110 | PKG_IMPR1110.IMPORTERS_POST_INS | MAPPED | Process "IMPORTERS.POST-INSERT" |
| 373 | TRIGGER | IMPORTERS.POST-UPDATE | PROCESS | IMPORTERS.PRE-INSERT…POST-UPDATE (page_dml SAVE) | 1110 | PKG_IMPR1110.IMPORTERS_POST_UPD | MAPPED | Process "IMPORTERS.POST-UPDATE" |
| 374 | TRIGGER | IMPORTERS.PRE-DELETE | PROCESS | IMPORTERS.KEY-DELREC (page_dml DELETE) | 1110 | PKG_IMPR1110.IMPORTERS_PRE_DEL | MAPPED | Called by importers_key_delrec |
| 375 | TRIGGER | IMPORTERS.PRE-RECORD | PROCESS | IMPORTERS.WHEN-CREATE-RECORD (Before Header) | 1110 | PKG_IMPR1110.IMPORTERS_PRE_REC | MAPPED | Parent importer name on record entry |
| 376 | TRIGGER | IMPORTERS.PRE-UPDATE | PROCESS | IMPORTERS.PRE-INSERT…POST-UPDATE (page_dml SAVE) | 1110 | PKG_IMPR1110.IMPORTERS_PRE_UPD | MAPPED | Process "IMPORTERS.PRE-UPDATE" |
| 377 | TRIGGER | IMPORTERS.WHEN-CLEAR-BLOCK | DYNAMIC_ACTION | IMPORTERS.WHEN-CLEAR-BLOCK | 1110 | PKG_IMPR1110.IMPORTERS_WCB | MAPPED | Sets :GLOBAL.STAT_CLR (never read in this form) |
| 378 | TRIGGER | IMPORTERS.WHEN-CREATE-RECORD | PROCESS | IMPORTERS.WHEN-CREATE-RECORD (Before Header) | 1110 | PKG_IMPR1110.IMPORTERS_WCR | MAPPED | Process "IMPORTERS.WHEN-CREATE-RECORD" (page_new_record) |
| 379 | TRIGGER | IMPORTERS.WHEN-NEW-ITEM-INSTANCE | DYNAMIC_ACTION | IMPORTERS.WHEN-NEW-ITEM-INSTANCE | 1110 | - | MAPPED | EXEC_QUERY_NOW=1 -> re-query (page reload) |
| 380 | TRIGGER | IMPORTERS.WHEN-NEW-RECORD-INSTANCE | DYNAMIC_ACTION | IMPORTERS.WHEN-NEW-RECORD-INSTANCE (+ Before Header processes) | 1110 | PKG_IMPR1110.IMPORTERS_WNRI | MAPPED | Entrable state + function codes F1..F5/SF6; CONFIRM F1/F5 -> wnri_confirm_text + Confirm DA |
| 381 | TRIGGER | IMPORTERS.SDP_PORT_STATUS.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 382 | TRIGGER | IMPORTERS.L_CT_CITY_STATUS2.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 383 | TRIGGER | IMPORTERS.L_CT_CITY_STATUS.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 384 | TRIGGER | IMPORTERS.PORT_CD.KEY-LISTVAL | LOV | Popup LOV (item is disabled) | - | - | MAPPED | LOV form LOV_SD_PORTS (PORT_TYPE, STATUS=1) -> Popup LOV (item is disabled) |
| 385 | TRIGGER | IMPORTERS.PORT_CD.WHEN-VALIDATE-ITEM | VALIDATION | IMPORTERS.PORT_CD.WHEN-VALIDATE-ITEM + DA IMPORTERS.PORT_CD.WHEN-VALIDATE-ITEM | 1110 | PKG_IMPR1110.PORT_CD_WVI | MAPPED | PORT_CD is disabled (WNFI) - kept for completeness |
| 386 | TRIGGER | IMPORTERS.PORT_CD2.WHEN-BUTTON-PRESSED | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV button (GO_ITEM + LIST_VALUES) - Popup LOV has its own button |
| 387 | TRIGGER | IMPORTERS.PORT_NAME.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 388 | TRIGGER | IMPORTERS.HQ_IMPR_NBR.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 389 | TRIGGER | IMPORTERS.HQ_IMPR_NBR.POST-CHANGE | VALIDATION | IMPORTERS.HQ_IMPR_NBR.POST-CHANGE (runs before WHEN-VALIDATE-ITEM) | 1110 | PKG_IMPR1110.HQ_IMPR_NBR_POST_CHG | MAPPED | :GLOBAL.FLAGUPDATE := 1 |
| 390 | TRIGGER | IMPORTERS.IMPR_NBR.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 391 | TRIGGER | IMPORTERS.IMPR_NBR.WHEN-VALIDATE-ITEM | VALIDATION | IMPORTERS.IMPR_NBR.WHEN-VALIDATE-ITEM + DA IMPORTERS.IMPR_NBR.WHEN-VALIDATE-ITEM | 1110 | PKG_IMPR1110.IMPR_NBR_WVI | MAPPED | Existing number -> re-query that importer |
| 392 | TRIGGER | IMPORTERS.SUSPN_STATUS.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 393 | TRIGGER | IMPORTERS.STATUS_DESC.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 394 | TRIGGER | IMPORTERS.IMPR_TYPE_CD.KEY-LISTVAL | LOV | Popup LOV returning 4 columns; post-select logic in package | - | PKG_IMPR1110.IMPR_TYPE_CD_LOV_RET | MAPPED | LOV form LOV_IMPR_TYPE -> Popup LOV returning 4 columns; post-select logic in package |
| 395 | TRIGGER | IMPORTERS.IMPR_TYPE_CD.WHEN-VALIDATE-ITEM | VALIDATION | IMPORTERS.IMPR_TYPE_CD.WHEN-VALIDATE-ITEM + DA IMPORTERS.IMPR_TYPE_CD.WHEN-VALIDATE-ITEM | 1110 | PKG_IMPR1110.IMPR_TYPE_CD_WVI | MAPPED | Includes CGFK ITIDT check; DO_KEY LIST_VALUES -> ui OPEN_LOV |
| 396 | TRIGGER | IMPORTERS.IMPR_TYPE_CD.POST-CHANGE | VALIDATION | IMPORTERS.IMPR_TYPE_CD.POST-CHANGE (runs before WHEN-VALIDATE-ITEM) | 1110 | PKG_IMPR1110.IMPR_TYPE_CD_POST_CHG | MAPPED | - |
| 397 | TRIGGER | IMPORTERS.IMPR_TYPE_CD.WHEN-NEW-ITEM-INSTANCE | DYNAMIC_ACTION | IMPORTERS.IMPR_TYPE_CD.WHEN-NEW-ITEM-INSTANCE | 1110 | PKG_IMPR1110.IMPR_TYPE_CD_WNII | MAPPED | Re-query part -> ui REQUERY; country 100 defaults |
| 398 | TRIGGER | IMPORTERS.IMPR_TYPE_CD2.WHEN-BUTTON-PRESSED | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV button (GO_ITEM + LIST_VALUES) - Popup LOV has its own button |
| 399 | TRIGGER | IMPORTERS.IMPR_TYPE_NAME.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 400 | TRIGGER | IMPORTERS.BUS_ID_EXPRD_DT.KEY-LISTVAL | LOV | Popup LOV | - | - | MAPPED | Same Hijri calendar as KEY-F4 |
| 401 | TRIGGER | IMPORTERS.BUS_ID_EXPRD_DT.KEY-F4 | DYNAMIC_ACTION | IMPORTERS.BUS_ID_EXPRD_DT.KEY-F4 | 1110 | - | MAPPED | INTRFACE.Disp_date_con Hijri calendar -> Hijri date picker (decision needed) |
| 402 | TRIGGER | IMPORTERS.BUS_ID_EXPRD_DT.WHEN-VALIDATE-ITEM | VALIDATION | IMPORTERS.BUS_ID_EXPRD_DT.WHEN-VALIDATE-ITEM + DA IMPORTERS.BUS_ID_EXPRD_DT.WHEN-VALIDATE-ITEM | 1110 | PKG_IMPR1110.BUS_ID_EXPRD_DT_WVI | MAPPED | p_from_item = (:SYSTEM.TRIGGER_ITEM = :SYSTEM.CURSOR_ITEM) |
| 403 | TRIGGER | IMPORTERS.BUS_ID_EXPRD_DT.WHEN-NEW-ITEM-INSTANCE | DYNAMIC_ACTION | IMPORTERS.BUS_ID_EXPRD_DT.WHEN-NEW-ITEM-INSTANCE | 1110 | - | MAPPED | EXEC_QUERY_NOW=1 -> re-query |
| 404 | TRIGGER | IMPORTERS.BUS_ID_TYPE_CD.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 405 | TRIGGER | IMPORTERS.BUS_ID_TYPE_CD.POST-CHANGE | VALIDATION | IMPORTERS.BUS_ID_TYPE_CD.POST-CHANGE (runs before WHEN-VALIDATE-ITEM) | 1110 | PKG_IMPR1110.BUS_ID_TYPE_POST_CHG | MAPPED | Swapped country-name assignment kept (SUGGESTION) |
| 406 | TRIGGER | IMPORTERS.BUTT.WHEN-BUTTON-PRESSED | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV button (GO_ITEM + LIST_VALUES) - Popup LOV has its own button |
| 407 | TRIGGER | IMPORTERS.BUS_ID_TYPE_NAME.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 408 | TRIGGER | IMPORTERS.COMM_RGSTRTN_TYPE.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 409 | TRIGGER | IMPORTERS.COMM_RGSTRTN_TYPE.WHEN-LIST-CHANGED | DYNAMIC_ACTION | IMPORTERS.COMM_RGSTRTN_TYPE.WHEN-LIST-CHANGED | 1110 | PKG_IMPR1110.COMM_RGSTRTN_WLC | MAPPED | Clears BUS_ID_BRNCH (server) + entrable/required (ui) |
| 410 | TRIGGER | IMPORTERS.CITY_CODE_OF_ID.KEY-LISTVAL | LOV | Popup LOV; returns CTRY_CD_OF_ID too | - | - | MAPPED | LOV form LOV_CITIES_IMP (CTRY 100 for type 3/bus 2, else CTRY_CD) -> Popup LOV; returns CTRY_CD_OF_ID too |
| 411 | TRIGGER | IMPORTERS.CITY_CODE_OF_ID.WHEN-VALIDATE-ITEM | VALIDATION | IMPORTERS.CITY_CODE_OF_ID.WHEN-VALIDATE-ITEM + DA IMPORTERS.CITY_CODE_OF_ID.WHEN-VALIDATE-ITEM | 1110 | PKG_IMPR1110.CITY_CODE_OF_ID_WVI | MAPPED | FK message is a warning (no failure) |
| 412 | TRIGGER | IMPORTERS.CITY_CODE_OF_ID.WHEN-NEW-ITEM-INSTANCE | DYNAMIC_ACTION | IMPORTERS.CITY_CODE_OF_ID.WHEN-NEW-ITEM-INSTANCE | 1110 | PKG_IMPR1110.CITY_CODE_OF_ID_WNII | MAPPED | REQUIRED BRNH_CITY_CD |
| 413 | TRIGGER | IMPORTERS.CITY_CODE_OF_ID2.WHEN-BUTTON-PRESSED | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV button (GO_ITEM + LIST_VALUES) - Popup LOV has its own button |
| 414 | TRIGGER | IMPORTERS.ID_CITY_NAME.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 415 | TRIGGER | IMPORTERS.BUS_ID.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 416 | TRIGGER | IMPORTERS.BUS_ID.POST-CHANGE | VALIDATION | IMPORTERS.BUS_ID.POST-CHANGE (runs before WHEN-VALIDATE-ITEM) | 1110 | PKG_IMPR1110.BUS_ID_POST_CHG | MAPPED | - |
| 417 | TRIGGER | IMPORTERS.BUS_ID.WHEN-NEW-ITEM-INSTANCE | DYNAMIC_ACTION | IMPORTERS.BUS_ID.WHEN-NEW-ITEM-INSTANCE | 1110 | PKG_IMPR1110.BUS_ID_WNII | MAPPED | Message 9-240 + GO_ITEM; city commercial code hint |
| 418 | TRIGGER | IMPORTERS.BUS_ID.WHEN-VALIDATE-ITEM | VALIDATION | IMPORTERS.BUS_ID.WHEN-VALIDATE-ITEM + DA IMPORTERS.BUS_ID.WHEN-VALIDATE-ITEM | 1110 | PKG_IMPR1110.BUS_ID_WVI | MAPPED | 2 alerts -> p_cr_answer / p_susp_answer; MCI service; entrable state |
| 419 | TRIGGER | IMPORTERS.BRNH_CITY_CD.KEY-LISTVAL | LOV | Popup LOV; returns BRNH_CITY_CD/NAME | - | - | MAPPED | LOV form LOV_CITIES_IMP (CTRY_CD = :CTRY_CD) -> Popup LOV; returns BRNH_CITY_CD/NAME |
| 420 | TRIGGER | IMPORTERS.BRNH_CITY_CD.WHEN-NEW-ITEM-INSTANCE | DYNAMIC_ACTION | IMPORTERS.BRNH_CITY_CD.WHEN-NEW-ITEM-INSTANCE | 1110 | PKG_IMPR1110.BRNH_CITY_CD_WNII | MAPPED | REQUIRED flags |
| 421 | TRIGGER | IMPORTERS.BRNH_CITY_CD.WHEN-VALIDATE-ITEM | VALIDATION | IMPORTERS.BRNH_CITY_CD.WHEN-VALIDATE-ITEM + DA IMPORTERS.BRNH_CITY_CD.WHEN-VALIDATE-ITEM | 1110 | PKG_IMPR1110.BRNH_CITY_CD_WVI | MAPPED | - |
| 422 | TRIGGER | IMPORTERS.BRNH_CITY_CD_LOV.WHEN-BUTTON-PRESSED | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV button (GO_ITEM + LIST_VALUES) - Popup LOV has its own button |
| 423 | TRIGGER | IMPORTERS.BRNH_CITY_NAME.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 424 | TRIGGER | IMPORTERS.BUS_ID_BRNCH.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 425 | TRIGGER | IMPORTERS.BUS_ID_BRNCH.POST-CHANGE | VALIDATION | IMPORTERS.BUS_ID_BRNCH.POST-CHANGE (runs before WHEN-VALIDATE-ITEM) | 1110 | PKG_IMPR1110.BUS_ID_BRNCH_POST_CHG | MAPPED | - |
| 426 | TRIGGER | IMPORTERS.BUS_ID_BRNCH.WHEN-NEW-ITEM-INSTANCE | DYNAMIC_ACTION | IMPORTERS.BUS_ID_BRNCH.WHEN-NEW-ITEM-INSTANCE | 1110 | PKG_IMPR1110.BUS_ID_BRNCH_WNII | MAPPED | REQUIRED flag + hint message |
| 427 | TRIGGER | IMPORTERS.BUS_ID_BRNCH.WHEN-VALIDATE-ITEM | VALIDATION | IMPORTERS.BUS_ID_BRNCH.WHEN-VALIDATE-ITEM + DA IMPORTERS.BUS_ID_BRNCH.WHEN-VALIDATE-ITEM | 1110 | PKG_IMPR1110.BUS_ID_BRNCH_WVI | MAPPED | Alert 9-120 -> p_cr_answer |
| 428 | TRIGGER | IMPORTERS.CTRY_CD.KEY-LISTVAL | LOV | Popup LOV with conditional query | - | - | MAPPED | LOV_COUNTRIES_GULF when type 4 / bus id type 16, else LOV_COUNTRIES -> Popup LOV with conditional query |
| 429 | TRIGGER | IMPORTERS.CTRY_CD.WHEN-VALIDATE-ITEM | VALIDATION | IMPORTERS.CTRY_CD.WHEN-VALIDATE-ITEM + DA IMPORTERS.CTRY_CD.WHEN-VALIDATE-ITEM | 1110 | PKG_IMPR1110.CTRY_CD_WVI | MAPPED | Includes CGFK CTRY check |
| 430 | TRIGGER | IMPORTERS.CTRY_CD2.WHEN-BUTTON-PRESSED | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV button (GO_ITEM + LIST_VALUES) - Popup LOV has its own button |
| 431 | TRIGGER | IMPORTERS.CRTY_ARBC_NAME.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 432 | TRIGGER | IMPORTERS.IMPR_EXPR_TYPE.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 433 | TRIGGER | IMPORTERS.IMPR_EXPR_TYPE.POST-CHANGE | VALIDATION | IMPORTERS.IMPR_EXPR_TYPE.POST-CHANGE (runs before WHEN-VALIDATE-ITEM) | 1110 | PKG_IMPR1110.IMPR_EXPR_TYPE_POST_CHG | MAPPED | - |
| 434 | TRIGGER | IMPORTERS.CTRY_CTRY_STATUS.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 435 | TRIGGER | IMPORTERS.ID_MINS_COMM_CD.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 436 | TRIGGER | IMPORTERS.ARBC_IMPR_NAME.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 437 | TRIGGER | IMPORTERS.ARBC_IMPR_NAME.KEY-NEXT-ITEM | DYNAMIC_ACTION | IMPORTERS.ARBC_IMPR_NAME.KEY-NEXT-ITEM | 1110 | PKG_IMPR1110.ARBC_IMPR_NAME_KEY_NXT | MAPPED | Net effect: focus ENG_IMPR_NAME (dummy values are reset) |
| 438 | TRIGGER | IMPORTERS.ARBC_IMPR_NAME.WHEN-VALIDATE-ITEM | VALIDATION | IMPORTERS.ARBC_IMPR_NAME.WHEN-VALIDATE-ITEM + DA IMPORTERS.ARBC_IMPR_NAME.WHEN-VALIDATE-ITEM | 1110 | PKG_IMPR1110.ARBC_IMPR_NAME_WVI | MAPPED | - |
| 439 | TRIGGER | IMPORTERS.IMPD_STMT_NBR.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 440 | TRIGGER | IMPORTERS.IMPR_DATA_SRCE.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 441 | TRIGGER | IMPORTERS.ENG_IMPR_NAME.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 442 | TRIGGER | IMPORTERS.ENG_IMPR_NAME.WHEN-VALIDATE-ITEM | VALIDATION | IMPORTERS.ENG_IMPR_NAME.WHEN-VALIDATE-ITEM + DA IMPORTERS.ENG_IMPR_NAME.WHEN-VALIDATE-ITEM | 1110 | PKG_IMPR1110.ENG_IMPR_NAME_WVI | MAPPED | - |
| 443 | TRIGGER | IMPORTERS.IMPR_CNTCT_NAME.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 444 | TRIGGER | IMPORTERS.IMPR_ADDRESS.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 445 | TRIGGER | IMPORTERS.BUS_ID_ISSUE_DT.WHEN-VALIDATE-ITEM | VALIDATION | IMPORTERS.BUS_ID_ISSUE_DT.WHEN-VALIDATE-ITEM + DA IMPORTERS.BUS_ID_ISSUE_DT.WHEN-VALIDATE-ITEM | 1110 | PKG_IMPR1110.BUS_ID_ISSUE_DT_WVI | MAPPED | - |
| 446 | TRIGGER | IMPORTERS.IMPR_NBR_PARENT.KEY-LISTVAL | LOV | Popup LOV; then focus CITY_CODE | - | - | MAPPED | LOV form LOV_IMPR (PORT_CD = current port) -> Popup LOV; then focus CITY_CODE |
| 447 | TRIGGER | IMPORTERS.IMPR_NBR_PARENT.WHEN-VALIDATE-ITEM | VALIDATION | IMPORTERS.IMPR_NBR_PARENT.WHEN-VALIDATE-ITEM + DA IMPORTERS.IMPR_NBR_PARENT.WHEN-VALIDATE-ITEM | 1110 | PKG_IMPR1110.IMPR_NBR_PARENT_WVI | MAPPED | 9-160 is a message, not a failure |
| 448 | TRIGGER | IMPORTERS.IMPR_NBR_PARENT2.WHEN-BUTTON-PRESSED | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV button (GO_ITEM + LIST_VALUES) - Popup LOV has its own button |
| 449 | TRIGGER | IMPORTERS.IMPR_NAME_PARENT.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 450 | TRIGGER | IMPORTERS.WASL_CITY_NAME.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 451 | TRIGGER | IMPORTERS.ADD_CTRY_CD.KEY-LISTVAL | LOV | Popup LOV | - | - | MAPPED | LOV form LOV_COUNTRIES (STATUS=1) -> Popup LOV |
| 452 | TRIGGER | IMPORTERS.ADD_CTRY_CD.WHEN-VALIDATE-ITEM | VALIDATION | IMPORTERS.ADD_CTRY_CD.WHEN-VALIDATE-ITEM + DA IMPORTERS.ADD_CTRY_CD.WHEN-VALIDATE-ITEM | 1110 | PKG_IMPR1110.ADD_CTRY_CD_WVI | MAPPED | - |
| 453 | TRIGGER | IMPORTERS.ADD_CTRY_CD2.WHEN-BUTTON-PRESSED | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV button (GO_ITEM + LIST_VALUES) - Popup LOV has its own button |
| 454 | TRIGGER | IMPORTERS.ADD_CRTY_ARBC_NAME.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 455 | TRIGGER | IMPORTERS.CITY_CODE.KEY-LISTVAL | LOV | Popup LOV; also returns ADD_CTRY_CD | - | - | MAPPED | LOV form LOV_CITIES (CTRY_CD = ADD_CTRY_CD) -> Popup LOV; also returns ADD_CTRY_CD |
| 456 | TRIGGER | IMPORTERS.CITY_CODE.WHEN-VALIDATE-ITEM | VALIDATION | IMPORTERS.CITY_CODE.WHEN-VALIDATE-ITEM + DA IMPORTERS.CITY_CODE.WHEN-VALIDATE-ITEM | 1110 | PKG_IMPR1110.CITY_CODE_WVI | MAPPED | - |
| 457 | TRIGGER | IMPORTERS.CITY_CODE2.WHEN-BUTTON-PRESSED | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV button (GO_ITEM + LIST_VALUES) - Popup LOV has its own button |
| 458 | TRIGGER | IMPORTERS.CITY_NAME.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 459 | TRIGGER | IMPORTERS.IMPR_POB_NBR.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 460 | TRIGGER | IMPORTERS.IMPR_ZIP_CD.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 461 | TRIGGER | IMPORTERS.IMPR_TEL_NBR.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 462 | TRIGGER | IMPORTERS.IMPR_TEL_NBR.WHEN-VALIDATE-ITEM | VALIDATION | IMPORTERS.IMPR_TEL_NBR.WHEN-VALIDATE-ITEM + DA IMPORTERS.IMPR_TEL_NBR.WHEN-VALIDATE-ITEM | 1110 | PKG_IMPR1110.IMPR_TEL_NBR_WVI | MAPPED | - |
| 463 | TRIGGER | IMPORTERS.IMPR_FAX_NBR.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 464 | TRIGGER | IMPORTERS.IMPR_TELEX_NBR.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 465 | TRIGGER | IMPORTERS.B_EMAIL.WHEN-VALIDATE-ITEM | VALIDATION | IMPORTERS.B_EMAIL.WHEN-VALIDATE-ITEM + DA IMPORTERS.B_EMAIL.WHEN-VALIDATE-ITEM | 1110 | PKG_IMPR1110.B_EMAIL_WVI | MAPPED | - |
| 466 | TRIGGER | IMPORTERS.B_EMAIL.POST-CHANGE | VALIDATION | IMPORTERS.B_EMAIL.POST-CHANGE (runs before WHEN-VALIDATE-ITEM) | 1110 | PKG_IMPR1110.B_EMAIL_POST_CHG | MAPPED | Moves the row to the current port |
| 467 | TRIGGER | IMPORTERS.EMAIL.WHEN-VALIDATE-ITEM | VALIDATION | IMPORTERS.EMAIL.WHEN-VALIDATE-ITEM + DA IMPORTERS.EMAIL.WHEN-VALIDATE-ITEM | 1110 | PKG_IMPR1110.EMAIL_WVI | MAPPED | EMAIL is hidden |
| 468 | TRIGGER | IMPORTERS.B_MOBILE_NO.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 469 | TRIGGER | IMPORTERS.B_MOBILE_NO.POST-CHANGE | VALIDATION | IMPORTERS.B_MOBILE_NO.POST-CHANGE (runs before WHEN-VALIDATE-ITEM) | 1110 | PKG_IMPR1110.B_MOBILE_NO_POST_CHG | MAPPED | Moves the row to the current port |
| 470 | TRIGGER | IMPORTERS.B_MOBILE_NO.WHEN-VALIDATE-ITEM | VALIDATION | IMPORTERS.B_MOBILE_NO.WHEN-VALIDATE-ITEM + DA IMPORTERS.B_MOBILE_NO.WHEN-VALIDATE-ITEM | 1110 | PKG_IMPR1110.B_MOBILE_NO_WVI | MAPPED | - |
| 471 | TRIGGER | IMPORTERS.MOBILE_NO.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 472 | TRIGGER | IMPORTERS.BANK_IBAN.WHEN-NEW-ITEM-INSTANCE | DYNAMIC_ACTION | IMPORTERS.BANK_IBAN.WHEN-NEW-ITEM-INSTANCE | 1110 | PKG_IMPR1110.BANK_IBAN_WNII | MAPPED | Default "SA" on focus |
| 473 | TRIGGER | IMPORTERS.BANK_IBAN.WHEN-VALIDATE-ITEM | VALIDATION | IMPORTERS.BANK_IBAN.WHEN-VALIDATE-ITEM + DA IMPORTERS.BANK_IBAN.WHEN-VALIDATE-ITEM | 1110 | PKG_IMPR1110.BANK_IBAN_WVI | MAPPED | - |
| 474 | TRIGGER | IMPORTERS.B_ID_NBR.POST-CHANGE | VALIDATION | IMPORTERS.B_ID_NBR.POST-CHANGE (runs before WHEN-VALIDATE-ITEM) | 1110 | PKG_IMPR1110.B_ID_NBR_POST_CHG | MAPPED | Moves the row to the current port |
| 475 | TRIGGER | IMPORTERS.B_ID_NBR.WHEN-VALIDATE-ITEM | VALIDATION | IMPORTERS.B_ID_NBR.WHEN-VALIDATE-ITEM + DA IMPORTERS.B_ID_NBR.WHEN-VALIDATE-ITEM | 1110 | PKG_IMPR1110.B_ID_NBR_WVI | MAPPED | - |
| 476 | TRIGGER | IMPORTERS.EXPRESS_POST.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 477 | TRIGGER | IMPORTERS.IMPR_ID_TYPE.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 478 | TRIGGER | IMPORTERS.CTRY_CD_OF_ID.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 479 | TRIGGER | IMPORTERS.CTRY_CD_OF_ID.WHEN-VALIDATE-ITEM | VALIDATION | IMPORTERS.CTRY_CD_OF_ID.WHEN-VALIDATE-ITEM + DA IMPORTERS.CTRY_CD_OF_ID.WHEN-VALIDATE-ITEM | 1110 | PKG_IMPR1110.CTRY_CD_OF_ID_WVI | MAPPED | CTRY_CD_OF_ID is hidden |
| 480 | TRIGGER | IMPORTERS.EXPD_STMT_NBR.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 481 | TRIGGER | IMPORTERS.WVR_ENTRY_NBR.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 482 | TRIGGER | IMPORTERS.ACTIVITY.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 483 | TRIGGER | IMPORTERS.CUSTOMS_ENTERED.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 484 | TRIGGER | IMPORTERS.CUSTOMS_ENTERED2.WHEN-BUTTON-PRESSED | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV button (GO_ITEM + LIST_VALUES) - Popup LOV has its own button |
| 485 | TRIGGER | IMPORTERS.CREATION_FLAG.KEY-LISTVAL | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV guard (LOV only if item enabled / insert / update allowed) - APEX does this natively |
| 486 | TRIGGER | IMPORTERS.CREATION_FLAG2.WHEN-BUTTON-PRESSED | ITEM | native APEX behaviour | 1110 | - | DROPPED | LOV button (GO_ITEM + LIST_VALUES) - Popup LOV has its own button |
| 487 | PROGRAM_UNIT | CHECK_TIMEOUT | - | - | - | - | DROPPED | not called; NIB library |
| 488 | PROGRAM_UNIT | MOUSE_CLICK | - | - | - | - | DROPPED | not called |
| 489 | PROGRAM_UNIT | TOGGEL_WND | - | - | - | - | DROPPED | not called; window API |
| 490 | PROGRAM_UNIT | PRINT_REPORT | - | - | - | - | DROPPED | not called; NIB library |
| 491 | PROGRAM_UNIT | EXECUTE_FUNCTION | PLSQL | - | - | - | MAPPED | TMPLT side-menu dispatcher -> APEX menu calls pkg_impr1110_apx.ajax_fun(code) -> exec_funs |
| 492 | PROGRAM_UNIT | TERMINATE_FUN | - | - | - | - | DROPPED | not called; NIB library |
| 493 | PROGRAM_UNIT | CHECK_EDI_MSG_LOV | - | - | - | - | DROPPED | not called (EDI messages) |
| 494 | PROGRAM_UNIT | CHECK_EDI_MSG_TIMER | - | - | - | - | DROPPED | not called |
| 495 | PROGRAM_UNIT | CHECK_EDI_ROLE_ID | - | - | - | - | DROPPED | not called |
| 496 | PROGRAM_UNIT | EDI_MSG_LOV | - | - | - | - | DROPPED | not called |
| 497 | PROGRAM_UNIT | FOR_EDI_MSG | - | - | - | - | DROPPED | not called |
| 498 | PROGRAM_UNIT | RETURN_MSG | - | - | - | - | DROPPED | not called; NIB timers |
| 499 | PROGRAM_UNIT | TURN_MSG | - | - | - | - | DROPPED | not called; NIB timers |
| 500 | PROGRAM_UNIT | WHEN_TIMER_EXPIRED_MSG | - | - | - | - | DROPPED | not called |
| 501 | PROGRAM_UNIT | CG$WHEN_NEW_FORM_INSTANCE | PLSQL | - | - | - | MAPPED | only calls CGDV$POPULATE_DYNAMIC_LISTS -> shared LOVs |
| 502 | PROGRAM_UNIT | CGDV$POPULATE_DYNAMIC_LISTS | PLSQL | - | - | - | MAPPED | list items from CG_REF_CODES -> shared LOVs (domains COMM_RGSTRTN_TYPE, ALLOWED EXPORT) |
| 503 | PROGRAM_UNIT | CGFK$QRY_IMPORTERS_IMP_SDP_FK | - | - | - | - | DROPPED | not called |
| 504 | PROGRAM_UNIT | CGFK$CHK_IMPORTERS_IMP_SDP_FK | PLSQL | - | - | - | MAPPED | - |
| 505 | PROGRAM_UNIT | CG$IMPR1110_PROD_CENTRL_GLOBAL | - | - | - | - | DROPPED | holds DEFAULT_WHERE between PRE/POST-QUERY - not needed |
| 506 | PROGRAM_UNIT | CGFK$CHK_IMPORTERS_IMP_MB_FK | - | - | - | - | DROPPED | not called |
| 507 | PROGRAM_UNIT | CGFK$QRY_IMPORTERS_IMP_ITIDT_F | PLSQL | - | - | - | MAPPED | - |
| 508 | PROGRAM_UNIT | CGFK$CHK_IMPORTERS_IMP_ITIDT_F | PLSQL | - | - | - | MAPPED | - |
| 509 | PROGRAM_UNIT | CGFK$QRY_IMPORTERS_IMP_CTRY_FK | PLSQL | - | - | - | MAPPED | - |
| 510 | PROGRAM_UNIT | CGFK$CHK_IMPORTERS_IMP_CTRY_FK | PLSQL | - | - | - | MAPPED | - |
| 511 | PROGRAM_UNIT | CGFK$QRY_IMPORTERS_IMP_BUS_ID_ | PLSQL | - | - | - | MAPPED | - |
| 512 | PROGRAM_UNIT | CGFK$CHK_IMPORTERS_IMP_BUS_ID_ | PLSQL | - | - | - | MAPPED | - |
| 513 | PROGRAM_UNIT | CGSF$CLRLU_IMPORTERS_IMP_BUS_I | PLSQL | - | - | - | MAPPED | - |
| 514 | PROGRAM_UNIT | CGFK$QRY_IMPORTERS_IMP_ADD_CIT | PLSQL | - | - | - | MAPPED | - |
| 515 | PROGRAM_UNIT | CGFK$CHK_IMPORTERS_IMP_ADD_CIT | PLSQL | - | - | - | MAPPED | - |
| 516 | PROGRAM_UNIT | CGTE$CHECK_CONSTRAINT_VIO | PLSQL | - | - | - | MAPPED | - |
| 517 | PROGRAM_UNIT | UPDATE_IMPORTER | PLSQL | - | - | PKG_IMPR1110.UPDATE_IMPORTER_MSG | MAPPED | - |
| 518 | PROGRAM_UNIT | UPDATE_BASIC_IMPORTER | PLSQL | - | - | PKG_IMPR1110.UPDATE_BASIC_IMPORTER | MAPPED | - |
| 519 | PROGRAM_UNIT | RETURN_IMPR_ID | PLSQL | - | - | PKG_IMPR1110.RETURN_IMPR_ID | MAPPED | - |
| 520 | PROGRAM_UNIT | LOV_UPDATE_MOBLIE | PLSQL | - | - | PKG_IMPR1110.CENTRAL_MOBILE | MAPPED | - |
| 521 | PROGRAM_UNIT | IS_DIGIT | PLSQL | - | - | PKG_IMPR1110.IS_DIGIT | MAPPED | - |
| 522 | PROGRAM_UNIT | INSERT_AUDIT_RECORD | PLSQL | - | - | PKG_IMPR1110.INSERT_AUDIT_RECORD | MAPPED | - |
| 523 | PROGRAM_UNIT | GET_MAIN_CR_DATA | PLSQL | - | - | PKG_IMPR1110.GET_MAIN_CR_DATA | MAPPED | - |
| 524 | PROGRAM_UNIT | GET_CR_DATA | PLSQL | - | - | PKG_IMPR1110.GET_CR_DATA | MAPPED | - |
| 525 | PROGRAM_UNIT | GET_BRANCH_CR_DATA | PLSQL | - | - | PKG_IMPR1110.GET_BRANCH_CR_DATA | MAPPED | - |
| 526 | PROGRAM_UNIT | EXEC_FUNS | PLSQL | - | - | PKG_IMPR1110.EXEC_FUNS | MAPPED | - |
| 527 | PROGRAM_UNIT | DEV_VERSIONS | - | - | - | - | DROPPED | change log only (NULL) |
| 528 | PROGRAM_UNIT | CREATE_BRKR_IMPR_AUTH | PLSQL | - | - | PKG_IMPR1110.CREATE_BRKR_IMPR_AUTH | MAPPED | - |
| 529 | PROGRAM_UNIT | CHK_PERSONAL | PLSQL | - | - | PKG_IMPR1110.CHK_PERSONAL | MAPPED | - |
| 530 | PROGRAM_UNIT | CHK_IMPR_DUPL | PLSQL | - | - | PKG_IMPR1110.CHK_IMPR_DUPL | MAPPED | - |
| 531 | PROGRAM_UNIT | CHK_DUPL_IMP_BRKR | PLSQL | - | - | PKG_IMPR1110.CHK_DUPL_IMP_BRKR | MAPPED | - |
| 532 | PROGRAM_UNIT | CHECK_IDNO | PLSQL | - | - | PKG_IMPR1110.CHECK_IDNO | MAPPED | - |
| 533 | PROGRAM_UNIT | CHECK_BUS_ID | PLSQL | - | - | PKG_IMPR1110.CHECK_BUS_ID | MAPPED | - |
| 534 | PROGRAM_UNIT | CALL_LOV_COUNTRIES | LOV | Popup LOV | - | - | MAPPED | LOV form LOV_COUNTRIES -> Popup LOV |
| 535 | PROGRAM_UNIT | CALL_LOV_COUN_GULF | LOV | Popup LOV | - | - | MAPPED | LOV form LOV_COUNTRIES_GULF -> Popup LOV |
| 536 | PROGRAM_UNIT | BROKER_INT | PLSQL | - | - | PKG_IMPR1110.BROKER_INT | MAPPED | - |
| 537 | PROGRAM_UNIT | ADJ_FUNS | PLSQL | - | - | PKG_IMPR1110.ADJ_FUNS | MAPPED | - |
| 538 | PROGRAM_UNIT | VIEW_SAME_BUSID | - | - | - | - | DROPPED | not called (only setter of :GLOBAL.CHK_DUP_BUSID = 1) |
| 539 | PROGRAM_UNIT | CHK_BUS_ID_BRNCH | PLSQL | - | - | PKG_IMPR1110.CHK_BUS_ID_BRNCH | MAPPED | - |
| 540 | LOV | CGDV$IMPORTERS_CREATION_FLAG | - | - | - | - | DROPPED | item is display-only / hidden - no LOV needed |
| 541 | LOV | CGFK$IMPORTERS_ADD_CTRY_CD | LOV | LOV_COUNTRIES | - | - | MAPPED | Forms KEY-LISTVAL calls an LOV form instead; APEX LOV built from that LOV form |
| 542 | LOV | CGFK$IMPORTERS_CITY_CODE_OF_ID | LOV | LOV_CITIES_IMP_ID | - | - | MAPPED | Forms KEY-LISTVAL calls an LOV form instead; APEX LOV built from that LOV form |
| 543 | LOV | CGFK$IMPORTERS_CTRY_CD | LOV | inline LOV of P1110_CTRY_CD | - | - | MAPPED | Forms KEY-LISTVAL calls an LOV form instead; APEX LOV built from that LOV form |
| 544 | LOV | CGFK$IMPORTERS_HQ_IMPR_NBR | - | - | - | - | DROPPED | item is display-only / hidden - no LOV needed |
| 545 | LOV | CGFK$IMPORTERS_IMPR_TYPE_CD | LOV | LOV_IMPR_TYPE + LOV_IMPR_TYPE_BUS_ID | - | - | MAPPED | Forms KEY-LISTVAL calls an LOV form instead; APEX LOV built from that LOV form |
| 546 | LOV | CGFK$IMPORTERS_PORT_CD | LOV | LOV_SD_PORTS | - | - | MAPPED | Forms KEY-LISTVAL calls an LOV form instead; APEX LOV built from that LOV form |
| 547 | LOV | CGDV$IMPORTERS_CUSTOMS_ENTERED | - | - | - | - | DROPPED | item is display-only / hidden - no LOV needed |
| 548 | RECORD_GROUP | CGDV$CREATION_FLAG | - | - | - | - | DROPPED | record group of the LOV with the same name |
| 549 | RECORD_GROUP | CGFK$IMPORTERS_ADD_CTRY_CD | LOV | LOV_COUNTRIES | - | - | MAPPED | record group of the LOV with the same name |
| 550 | RECORD_GROUP | CGFK$IMPORTERS_CITY_CODE_OF_ID | LOV | LOV_CITIES_IMP_ID | - | - | MAPPED | record group of the LOV with the same name |
| 551 | RECORD_GROUP | CGFK$IMPORTERS_CTRY_CD | LOV | inline LOV of P1110_CTRY_CD | - | - | MAPPED | record group of the LOV with the same name |
| 552 | RECORD_GROUP | CGFK$IMPORTERS_HQ_IMPR_NBR | - | - | - | - | DROPPED | record group of the LOV with the same name |
| 553 | RECORD_GROUP | CGFK$IMPORTERS_IMPR_TYPE_CD | LOV | LOV_IMPR_TYPE + LOV_IMPR_TYPE_BUS_ID | - | - | MAPPED | record group of the LOV with the same name |
| 554 | RECORD_GROUP | CGFK$IMPORTERS_PORT_CD | LOV | LOV_SD_PORTS | - | - | MAPPED | record group of the LOV with the same name |
| 555 | RECORD_GROUP | CGDV$IMPORTERS_CUSTOMS_ENTERED | - | - | - | - | DROPPED | record group of the LOV with the same name |
| 556 | RECORD_GROUP | CGDV$DLRG | LOV | LOV_COMM_RGSTRTN_TYPE / LOV_ALLOWED_EXPORT | - | - | MAPPED | runtime group of CGDV$POPULATE_DYNAMIC_LISTS |
| 557 | CALLED_FORM | LOV_SD_PORTS | LOV | LOV_SD_PORTS | - | - | MAPPED | LOV form (forms/COMMON/lov_forms) |
| 558 | CALLED_FORM | LOV_IMPR_TYPE | LOV | LOV_IMPR_TYPE + LOV_IMPR_TYPE_BUS_ID | - | - | MAPPED | LOV form (forms/COMMON/lov_forms) |
| 559 | CALLED_FORM | LOV_CITIES_IMP | LOV | LOV_CITIES_IMP_ID / LOV_CITIES_IMP_BRNH | - | - | MAPPED | LOV form (forms/COMMON/lov_forms) |
| 560 | CALLED_FORM | LOV_CITIES | LOV | LOV_CITIES | - | - | MAPPED | LOV form (forms/COMMON/lov_forms) |
| 561 | CALLED_FORM | LOV_COUNTRIES | LOV | LOV_COUNTRIES | - | - | MAPPED | LOV form (forms/COMMON/lov_forms) |
| 562 | CALLED_FORM | LOV_COUNTRIES_GULF | LOV | inline LOV of P1110_CTRY_CD | - | - | MAPPED | LOV form (forms/COMMON/lov_forms) |
| 563 | CALLED_FORM | LOV_IMPR | LOV | LOV_IMPR | - | - | MAPPED | LOV form (forms/COMMON/lov_forms) |
| 564 | CALLED_FORM | LOV_UPDATE_IMPR_MOBILE | PAGE | 1112 IMPR1110_MOBILE (Modal Dialog) | 1112 | PKG_IMPR1110_APX.CENTRAL_MOBILE | MAPPED | dialog of function IMPR1110_MOB |
| 565 | CALLED_FORM | SUPPORT_ENTRY | PAGE | 1113 IMPR1110_SUPPORT (Modal Dialog) | 1113 | - | TODO | MISSING SOURCE - support-letter entry, sets :GLOBAL.LETTER_NBR/SUPP_TITLE_CD/LETTER_DT/PORT_CD |
| 566 | CALLED_FORM | IMPR1115 | PAGE | link to the IMPR1115 page | - | - | TODO | function IMPR1115_SCR - when IMPR1115 is converted |
| 567 | CALLED_FORM | V_CALLED_FORM (TMPLT menu) | PAGE | - | - | - | TODO | screens of SC_SYSTEM_OBJECTS called by EXECUTE_FUNCTION -> navigation menu |
| 568 | ALERT | USR_CONFIRM_B | - | - | - | - | DROPPED | OLB alert used only through STR.DispAlert; texts are inline in the code (MISSING SOURCE CIC_OLB) |
| 569 | ALERT | USR_CONFIRM | - | - | - | - | DROPPED | OLB alert used only through STR.DispAlert; texts are inline in the code (MISSING SOURCE CIC_OLB) |
| 570 | ALERT | USR_WARNING_C | - | - | - | - | DROPPED | OLB alert used only through STR.DispAlert; texts are inline in the code (MISSING SOURCE CIC_OLB) |
| 571 | ALERT | USR_WARNING_B | - | - | - | - | DROPPED | OLB alert used only through STR.DispAlert; texts are inline in the code (MISSING SOURCE CIC_OLB) |
| 572 | ALERT | CFG_WARNING_A | - | - | - | - | DROPPED | OLB alert used only through STR.DispAlert; texts are inline in the code (MISSING SOURCE CIC_OLB) |
| 573 | ALERT | CFG_INFORMATION | - | - | - | - | DROPPED | OLB alert used only through STR.DispAlert; texts are inline in the code (MISSING SOURCE CIC_OLB) |
| 574 | ALERT | CFG_ERROR | - | - | - | - | DROPPED | OLB alert used only through STR.DispAlert; texts are inline in the code (MISSING SOURCE CIC_OLB) |
| 575 | ALERT | CFG_SYSTEM_ERROR | - | - | - | - | DROPPED | OLB alert used only through STR.DispAlert; texts are inline in the code (MISSING SOURCE CIC_OLB) |
| 576 | ALERT | CFG_ASK_COMMIT | - | - | - | - | DROPPED | OLB alert used only through STR.DispAlert; texts are inline in the code (MISSING SOURCE CIC_OLB) |
| 577 | CANVAS | LSIDE | - | - | - | - | DROPPED | OLB canvas LSIDE |
| 578 | CANVAS | EDI_MSG | - | - | - | - | DROPPED | OLB canvas EDI_MSG |
| 579 | CANVAS | TITLE | - | - | - | - | DROPPED | OLB canvas TITLE |
| 580 | CANVAS | TOOLBAR | - | - | - | - | DROPPED | OLB canvas TOOLBAR |
| 581 | CANVAS | CG$PAGE_1 | PAGE | 1110 IMPR1110 | 1110 | - | MAPPED | main content canvas |
| 582 | WINDOW | CGSO$WINDOW_1 | PAGE | 1110 IMPR1110 | 1110 | - | MAPPED | console window |
| 583 | PARAMETER | P_SHPG_AGNT_NBR | - | - | - | - | DROPPED | used only by dropped code (title, menu, help, reports) |
| 584 | PARAMETER | P_CTRL_LAST_EXEC_CD | - | - | - | - | DROPPED | used only by dropped code (title, menu, help, reports) |
| 585 | PARAMETER | P_BANK_CD | - | - | - | - | DROPPED | used only by dropped code (title, menu, help, reports) |
| 586 | PARAMETER | P_BANK_BRNCH_CD | - | - | - | - | DROPPED | used only by dropped code (title, menu, help, reports) |
| 587 | PARAMETER | P_BRKR_PORT_CD | APP_ITEM | AI_P_BRKR_PORT_CD | - | - | MAPPED | session parameter of the menu |
| 588 | PARAMETER | P_LIC_TYPE | APP_ITEM | AI_P_LIC_TYPE | - | - | MAPPED | session parameter of the menu |
| 589 | PARAMETER | P_BRKR_NBR | APP_ITEM | AI_P_BRKR_NBR | - | - | MAPPED | session parameter of the menu |
| 590 | PARAMETER | P_CLASS_CD | APP_ITEM | AI_P_CLASS_CD | - | - | MAPPED | session parameter of the menu |
| 591 | PARAMETER | P_JOB_ID | - | - | - | - | DROPPED | used only by dropped code (title, menu, help, reports) |
| 592 | PARAMETER | P_CURRENT_ITEM | - | - | - | - | DROPPED | used only by dropped code (title, menu, help, reports) |
| 593 | PARAMETER | P_GROUP_CD | - | - | - | - | DROPPED | used only by dropped code (title, menu, help, reports) |
| 594 | PARAMETER | P_USER_TYPE | APP_ITEM | AI_P_USER_TYPE | - | - | MAPPED | session parameter of the menu |
| 595 | PARAMETER | P_PORT_TYPE | APP_ITEM | AI_P_PORT_TYPE | - | - | MAPPED | session parameter of the menu |
| 596 | PARAMETER | P_CURR_PORT_CD | APP_ITEM | AI_P_CURR_PORT_CD | - | - | MAPPED | session parameter of the menu |
| 597 | PARAMETER | P_MODULE_ID | - | - | - | - | DROPPED | used only by dropped code (title, menu, help, reports) |
| 598 | PARAMETER | P_MODULE_NAME | - | - | - | - | DROPPED | used only by dropped code (title, menu, help, reports) |
| 599 | PARAMETER | P_APPLICATION_NAME | - | - | - | - | DROPPED | used only by dropped code (title, menu, help, reports) |
| 600 | PARAMETER | P_USER_ID | APP_ITEM | AI_P_USER_ID | - | - | MAPPED | session parameter of the menu |
| 601 | PARAMETER | P_WS_ID | APP_ITEM | AI_P_WS_ID | - | - | MAPPED | session parameter of the menu |
| 602 | PARAMETER | P_USER_NAME | - | - | - | - | DROPPED | used only by dropped code (title, menu, help, reports) |
| 603 | PARAMETER | CG$STARTUP_MODE | - | - | - | - | DROPPED | used only by dropped code (title, menu, help, reports) |
| 604 | PARAMETER | LETTER_NBR | ITEM | P1110_LETTER_NBR | 1110 | - | MAPPED | page parameter |
| 605 | PARAMETER | CODE | ITEM | P1110_CODE | 1110 | - | MAPPED | page parameter |
| 606 | PARAMETER | PRSNL_IMPR | ITEM | P1110_PRSNL_IMPR | 1110 | - | MAPPED | page parameter |
| 607 | GLOBAL | FLAGUPDATE | APP_ITEM | AI_FLAGUPDATE | - | - | MAPPED | pkg_forms_compat.get/set_global |
| 608 | GLOBAL | EXEC_QUERY_NOW | APP_ITEM | AI_EXEC_QUERY_NOW | - | - | MAPPED | pkg_forms_compat.get/set_global |
| 609 | GLOBAL | PORT_CD | APP_ITEM | AI_PORT_CD | - | - | MAPPED | pkg_forms_compat.get/set_global |
| 610 | GLOBAL | IMPR_NBR | APP_ITEM | AI_IMPR_NBR | - | - | MAPPED | pkg_forms_compat.get/set_global |
| 611 | GLOBAL | VALID | APP_ITEM | AI_VALID | - | - | MAPPED | pkg_forms_compat.get/set_global |
| 612 | GLOBAL | FUNS_IMP | APP_ITEM | AI_FUNS_IMP | - | - | MAPPED | pkg_forms_compat.get/set_global |
| 613 | GLOBAL | FUNS_BUSID | APP_ITEM | AI_FUNS_BUSID | - | - | MAPPED | pkg_forms_compat.get/set_global |
| 614 | GLOBAL | CHK_IMP_TYP | APP_ITEM | AI_CHK_IMP_TYP | - | - | MAPPED | pkg_forms_compat.get/set_global |
| 615 | GLOBAL | CHK_DUP_BUSID | APP_ITEM | AI_CHK_DUP_BUSID | - | - | MAPPED | pkg_forms_compat.get/set_global |
| 616 | GLOBAL | OLD_IMPR_TYPE_CD | APP_ITEM | AI_OLD_IMPR_TYPE_CD | - | - | MAPPED | pkg_forms_compat.get/set_global |
| 617 | GLOBAL | OLD_PORT_CD | APP_ITEM | AI_OLD_PORT_CD | - | - | MAPPED | pkg_forms_compat.get/set_global |
| 618 | GLOBAL | ALLOW_MCI | APP_ITEM | AI_ALLOW_MCI | - | - | MAPPED | pkg_forms_compat.get/set_global |
| 619 | GLOBAL | ALLOW_MOI | APP_ITEM | AI_ALLOW_MOI | - | - | MAPPED | pkg_forms_compat.get/set_global |
| 620 | GLOBAL | SET | APP_ITEM | AI_SET | - | - | MAPPED | pkg_forms_compat.get/set_global |
| 621 | GLOBAL | MINS_COMM_CD | APP_ITEM | AI_MINS_COMM_CD | - | - | MAPPED | pkg_forms_compat.get/set_global |
| 622 | GLOBAL | LETTER_NBR | APP_ITEM | AI_LETTER_NBR | - | - | MAPPED | pkg_forms_compat.get/set_global |
| 623 | GLOBAL | SUPP_TITLE_CD | APP_ITEM | AI_SUPP_TITLE_CD | - | - | MAPPED | pkg_forms_compat.get/set_global |
| 624 | GLOBAL | LETTER_DT | APP_ITEM | AI_LETTER_DT | - | - | MAPPED | pkg_forms_compat.get/set_global |
| 625 | GLOBAL | MOBILE_NO | APP_ITEM | AI_MOBILE_NO | - | - | MAPPED | pkg_forms_compat.get/set_global |
| 626 | GLOBAL | IMPR_NBR_B | APP_ITEM | AI_IMPR_NBR_B | - | - | MAPPED | pkg_forms_compat.get/set_global |
| 627 | GLOBAL | IMPR_NAME_B | APP_ITEM | AI_IMPR_NAME_B | - | - | MAPPED | pkg_forms_compat.get/set_global |
| 628 | GLOBAL | BRKR_ATHRZTN_NBR_B | APP_ITEM | AI_BRKR_ATHRZTN_NBR_B | - | - | MAPPED | pkg_forms_compat.get/set_global |
| 629 | GLOBAL | CHEK | APP_ITEM | AI_CHEK | - | - | MAPPED | pkg_forms_compat.get/set_global |
| 630 | GLOBAL | STAT_QUE | APP_ITEM | AI_STAT_QUE | - | - | MAPPED | pkg_forms_compat.get/set_global |
| 631 | GLOBAL | STAT_CLR | APP_ITEM | AI_STAT_CLR | - | - | MAPPED | pkg_forms_compat.get/set_global |
| 632 | GLOBAL | IMP0F4 | APP_ITEM | AI_IMP0F4 | - | - | MAPPED | pkg_forms_compat.get/set_global |
| 633 | GLOBAL | EXE_DETAIL_QUERY | APP_ITEM | AI_EXE_DETAIL_QUERY | - | - | MAPPED | pkg_forms_compat.get/set_global |
| 634 | GLOBAL | INS | APP_ITEM | AI_INS | - | - | MAPPED | pkg_forms_compat.get/set_global |
| 635 | GLOBAL | IMPR_TYPE_CD | LOV | Popup LOV return value | - | - | MAPPED | LOV-form return global |
| 636 | GLOBAL | IMPR_TYPE_NAME | LOV | Popup LOV return value | - | - | MAPPED | LOV-form return global |
| 637 | GLOBAL | BUS_ID_TYPE_CD | LOV | Popup LOV return value | - | - | MAPPED | LOV-form return global |
| 638 | GLOBAL | BUS_ID_TYPE_NAME | LOV | Popup LOV return value | - | - | MAPPED | LOV-form return global |
| 639 | GLOBAL | CTRY_CD | LOV | Popup LOV return value | - | - | MAPPED | LOV-form return global |
| 640 | GLOBAL | CRTY_ARBC_NAME | LOV | Popup LOV return value | - | - | MAPPED | LOV-form return global |
| 641 | GLOBAL | CITY_CD | LOV | Popup LOV return value | - | - | MAPPED | LOV-form return global |
| 642 | GLOBAL | CITY_ARB_NAME | LOV | Popup LOV return value | - | - | MAPPED | LOV-form return global |
| 643 | GLOBAL | PORT_NAME | LOV | Popup LOV return value | - | - | MAPPED | LOV-form return global |
| 644 | GLOBAL | IMPR_NAME | LOV | Popup LOV return value | - | - | MAPPED | LOV-form return global |
| 645 | GLOBAL | EXIT | - | - | - | - | DROPPED | toolbar / version / help |
| 646 | GLOBAL | CURRENT_VER | - | - | - | - | DROPPED | toolbar / version / help |
| 647 | GLOBAL | CURRENT_DT | - | - | - | - | DROPPED | toolbar / version / help |
| 648 | GLOBAL | CURRENT_VERSION | - | - | - | - | DROPPED | toolbar / version / help |
| 649 | GLOBAL | CG$HP_HPATH | - | - | - | - | DROPPED | toolbar / version / help |
| 650 | GLOBAL | CG$HP_HFILE | - | - | - | - | DROPPED | toolbar / version / help |
| 651 | GLOBAL | SYSTEM_OBJ | - | - | - | - | DROPPED | toolbar / version / help |
| 652 | LIBRARY | OFGTEL | - | - | - | - | TODO | MISSING SOURCE .pll - used calls re-implemented or mapped (extraction report §7.3) |
| 653 | LIBRARY | OFGMES | - | - | - | - | TODO | MISSING SOURCE .pll - used calls re-implemented or mapped (extraction report §7.3) |
| 654 | LIBRARY | OFGHPL | - | - | - | - | TODO | MISSING SOURCE .pll - used calls re-implemented or mapped (extraction report §7.3) |
| 655 | LIBRARY | CIC_AMSG | - | - | - | - | TODO | MISSING SOURCE .pll - used calls re-implemented or mapped (extraction report §7.3) |
| 656 | LIBRARY | SEC_LIB | - | - | - | - | TODO | MISSING SOURCE .pll - used calls re-implemented or mapped (extraction report §7.3) |
| 657 | LIBRARY | CAPTION | - | - | - | - | TODO | MISSING SOURCE .pll - used calls re-implemented or mapped (extraction report §7.3) |
| 658 | LIBRARY | OFGBSL | - | - | - | - | TODO | MISSING SOURCE .pll - used calls re-implemented or mapped (extraction report §7.3) |
| 659 | LIBRARY | D2KWUTIL | - | - | - | - | TODO | MISSING SOURCE .pll - used calls re-implemented or mapped (extraction report §7.3) |
| 660 | LIBRARY | CUSTOMDLL | - | - | - | - | TODO | MISSING SOURCE .pll - used calls re-implemented or mapped (extraction report §7.3) |
| 661 | LIBRARY | D2KWUTIL_PDF | - | - | - | - | TODO | MISSING SOURCE .pll - used calls re-implemented or mapped (extraction report §7.3) |
| 662 | LIBRARY | GETCOMP | - | - | - | - | TODO | MISSING SOURCE .pll - used calls re-implemented or mapped (extraction report §7.3) |
| 663 | LIBRARY | OFGTAB | - | - | - | - | TODO | MISSING SOURCE .pll - used calls re-implemented or mapped (extraction report §7.3) |
| 664 | LIBRARY | PICKLIST | - | - | - | - | TODO | MISSING SOURCE .pll - used calls re-implemented or mapped (extraction report §7.3) |
| 665 | LIBRARY | POS | - | - | - | - | TODO | MISSING SOURCE .pll - used calls re-implemented or mapped (extraction report §7.3) |
| 666 | LIBRARY | SCDLL | - | - | - | - | TODO | MISSING SOURCE .pll - used calls re-implemented or mapped (extraction report §7.3) |
| 667 | LIBRARY | VCDLL | - | - | - | - | TODO | MISSING SOURCE .pll - used calls re-implemented or mapped (extraction report §7.3) |
| 668 | LIBRARY | CIC_LIB | - | - | - | - | TODO | MISSING SOURCE .pll - used calls re-implemented or mapped (extraction report §7.3) |

---

## 15. Registry script

`registry/IMPR1110_registry.sql` – one `MIG_FORM_REGISTRY` row (status `DESIGN`, app_id 2000
placeholder) and one `MIG_OBJECT_MAP` row per line of §14. Re-runnable: it deletes the form's
rows first. Ends with COMMIT. **Not executed** – CLAUDE.md §6.10: no DML without an explicit
request.

---

## 16. Open questions / TODO for step 04

| # | Question | Blocks |
|---|---|---|
| 1 | Real APEX application id of IMPR (2000 is a placeholder in registry and spec) | export (step 04) |
| 2 | Keep DELETE? Which rule makes TOOLBAR.REMOVE visible/enabled (`FUN_REMOVE`)? (step 02 H6) | button DELETE |
| 3 | `SUPPORT_ENTRY.fmb` source – page 1113 | functions F1/F2/F3/F5 |
| 4 | `CIC_MENU.mmb` + security library: menu position, `IMPR1110_ACCESS`, how `AI_P_*` are filled | navigation, authorization |
| 5 | Hijri date entry for BUS_ID_EXPRD_DT (F4 calendar `INTRFACE.Disp_date_con`) – plug-in or masked text | DA 16 |
| 6 | `TMPLT.LOAD_FUNCTIONS` – function list per user and the function titles | `FUN_*` schemes, labels §13.4 |
| 7 | Arabic texts of FRM-40202 / 40350 / 40654 (NIB.ON_ERROR / ON_MESSAGE) | §11 |
| 8 | Step 02 HIGH H1 (insert path) and H3 (POST-CHANGE on fetch) – Forms trace | save, fetch |
| 9 | Region title of IMPORTERS (frame title not in the XML; module title used) | cosmetic |

### Changes made to step-02 code during this step

`pkg_impr1110_apx` 1.1.0:
* Server-side item state (`COL_IMPR1110_STATE`), `validate_on_submit`, `required_items`.
* `page_clear`, `page_query`, `central_mobile`, and the `P1110_NEED_FETCH` flag (no re-query
  after SAVE, as in Forms).
* Block WHERE (`port_cd = current port`) in `load_row`.
* `ajax_fun` no longer runs WNRI before the Confirm.
* MINS_COMM_CD from the city LOV.

`pkg_impr1110`: new read accessors `ui_count` / `ui_entry`. Self-check `scripts/expand_orig.py`:
0 problems.
