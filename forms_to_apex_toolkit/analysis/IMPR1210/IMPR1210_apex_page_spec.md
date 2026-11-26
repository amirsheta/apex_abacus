# IMPR1210 – APEX 21.2 Page Specification (step 03)

- **Form:** IMPR1210 (module `IMPR1210`) – صيانة تفاويض الشركات الوسيطة (table `AGNTS`)
- **Package:** `IMPR1210` version 001 (`plsql/IMPR1210/`), logic report `analysis/IMPR1210/IMPR1210_logic_extraction.md`;
  no change to `LOV_APX` / `FORMS_APX`
- **Standard:** f345 (`apex/Reference/f345.sql`), CLAUDE.md §4a–§4d, `docs/f345_reference_standard.md`
- **Design data:** `scripts/gen_apex_impr1210.py` (ITEMS, PROCESSES, DAS …); this file is rendered from it by
  `work/IMPR1210/step03/build_spec.py`, the traceability (§14) and `registry/IMPR1210_registry.sql` by `build_trace.py`.
- **Produced:** 2026-11-25 by Claude Code.

## 0. Decisions that shape the page

| # | Decision | Reason / source |
|---|---|---|
| 1 | Main page **1210** `IMPR1210`, search page **121001** `IMPR1210_SEARCH` (modal 1800×800), page group `IMPR` (IMPR1110 export) | f345 standard §3 |
| 2 | Block AGNTS = native **Form** region on the table, key **ROWID** (= `P0_PAGE_PK`, URL-safe from the search page and the authorizations grid), operations `i:u` | WHEN-NEW-RECORD-INSTANCE: insert always, update by rule, delete never |
| 3 | Read only: ATHRZTN_SEQ_NBR on a queried record (`record`); ALLOW_EXPORT, IMPR_NBR, IMPR_NBR_AG, ATHRZTN_NOTE, ATHRZTN_STA_CD when `IMPR1210.AGNTS_IS_READ_ONLY` (`locked`: used in a declaration or cancelled); PRE_UPDATE checks the same rule on the server | `INTRFACE.MAKE_BLOCK_FULL_OPERATION('AGNTS', TRUE, FALSE, FALSE)` |
| 4 | Typing an existing ATHRZTN_SEQ_NBR on a new record: DA check (9-40) + Submit `EXECUTE_QUERY`; process `EXECUTE-QUERY` sets `P0_PAGE_PK` | ATHRZTN_SEQ_NBR.WHEN-VALIDATE-ITEM + PRE-QUERY + IMPR_NBR.WHEN-NEW-ITEM-INSTANCE |
| 5 | LOV form `LOV_IMPR` → Popup LOV `LOV_IMPR` (IMPR1110) on IMPR_NBR and IMPR_NBR_AG; DAs on change do the WHEN-VALIDATE-ITEM (name, activity, suspension, importer ≠ broker) | KEY-LISTVAL, buttons IMP_LOV / AGNT_LOV |
| 6 | LOV form `LOV_AGNT_ATHR_IMPR` → read-only grid "تفاويض المستورد" (static ID `LOV_AGNT_ATHR_IMPR`) of the importer's authorizations, refreshed after IMPR_NBR; a row opens that authorization | IMPR_NBR.WHEN-VALIDATE-ITEM CALL_FORM (to confirm, inventory §15 #4) |
| 7 | The functions `CD1_STOPIMPRAUTH` / `CD2_REUSEIMPRAUTH` = DAs on the page 0 FUNCS custom events: client condition (number shown, status 1 / 2), native **Confirm**, Submit; processes call `IMPR1210.EXEC_FUNS` (COMMIT as Forms) | PU EXEC_FUNS (IMPR1150 pattern) |
| 8 | Hijri dates display only with the mask `&P1210_HIJRI_DATE_FORMAT.` (`FORMS_APX.HIJRI_DATE_FORMAT`) | Forms mask MI-MM-RRRR; never enterable |
| 9 | Defaults of the new record (PORT_CD / PORT_NAME) by process `WHEN-CREATE-RECORD` **after** `Initialize form`; UPDATE_STATUS by `WHEN-NEW-RECORD-INSTANCE` | Initialize form would clear them |
| 10 | Constraint errors → Text Messages `AG_PK`, `AG_SDP_FK`, `AG_IMP_FK`, `AG_IMP_AGENT_ID_FK` (APEX error handler of FORMS_APX) | AGNTS.ON-ERROR / CGTE$CHECK_CONSTRAINT_VIO |
| 11 | Button `IMP_NEW` → page 1130 (IMPR1130 "إضافة وتعديل بيانات مستورد") | OPEN_FORM('IMP_NEW') (to confirm, inventory §15 #5) |
| 12 | No JavaScript action (Confirm / Refresh / Set Focus / Submit are native); the two function DAs use a JavaScript client-side condition (one line each) | CLAUDE.md §4c |

## 1. Page type decision per block

| Block | Forms | APEX |
|---|---|---|
| AGNTS | base table, one record shown, insert; update by rule; no delete | Form region on page 1210 + search IG on page 121001 |
| CGNV$CGSO$WINDOW_1_1 | Designer action item IMP_NEW | page button IMP_NEW |
| TITLE, EDI_MSG, LSIDE, TOOLBAR | OLB frame | f345 page template, hero region, page 0 toolbar, FUNCS drawer |

## 2. Pages

| Page | Name / alias | Mode | Template / class | Source |
|---|---|---|---|---|
| 1210 | IMPR1210 / IMPR1210 | Normal, protection C, Warn on Unsaved Changes = Yes | Zatca-Minimal_No_Navigation, `zf` | window CGSO$WINDOW_1, canvas CG$PAGE_1 |
| 121001 | IMPR1210_SEARCH / IMPR1210-SEARCH | Modal 1800×800, protection C | theme dialog, `zf` | Enter-Query / Execute-Query (page 0 SEARCH) |

## 3. Regions

| Page | Region (static id) | Type / template | Source |
|---|---|---|---|
| 1210 | الهيدر (`AGNTS_HERO`) | Static HTML, Blank with Attributes, `cg-hero`, title `&P1210_HERO_TITLE.` | OLB block TITLE |
| 1210 | تفاويض الشركات الوسيطة (`AGNTS`) | Form, table `AGNTS`, ROWID, `i:u`, Interactive Report template, `zatca-forms cg-form cg-card` | block AGNTS |
| 1210 | تفاويض المستورد (`LOV_AGNT_ATHR_IMPR`) | read-only IG, Standard, `cg-card cg-grid`, Page Items to Submit `P1210_PORT_CD, P1210_IMPR_NBR`; link `ATHRZTN_SEQ_NBR` → page 1210 with `P0_PAGE_PK = ROW_ID` | LOV form LOV_AGNT_ATHR_IMPR |
| 121001 | بحث (`AGNTS_SEARCH_CRITERIA`) | Static, text `P121001_SEARCH` + buttons SEARCH / CLEAR | Enter-Query criteria |
| 121001 | تفاويض الشركات الوسيطة (`AGNTS_SEARCH`) | read-only IG, lazy loading, every row on opening (search text optional, user request 2026-11-26); link `ATHRZTN_SEQ_NBR` → page 1210 | block query (WHERE PORT_CD = P_CURR_PORT_CD) + POST-QUERY names |

Grid query of `LOV_AGNT_ATHR_IMPR`:

```sql
-- LOV form LOV_AGNT_ATHR_IMPR (CALL_FORM from IMPR_NBR.WHEN-VALIDATE-ITEM, parameters PORT_CD, IMPR_NBR): the
-- authorizations of the importer in the port, ORDER BY IMPR_NBR, ATHRZTN_SEQ_NBR (block WHERE / ORDER BY clauses).
-- No rows until an importer is chosen (Forms calls the form only for a typed importer with authorizations).
SELECT TRANSLATE(ROWIDTOCHAR(a.ROWID), '+/', '-_') AS row_id,   -- URL-safe: a '+' in f?p arrives as a space
       a.athrztn_seq_nbr, a.impr_nbr_agent_id, i.arbc_impr_name, ae.rv_meaning AS allow_export_name,
       TO_CHAR(a.athrztn_cret_dt, (SELECT FORMS_APX.HIJRI_DATE_FORMAT FROM dual)) AS athrztn_cret_dt,
       DECODE(a.athrztn_sta_cd, 1, 'ساري', 2, 'غير ساري') AS athrztn_sta_name
  FROM agnts a, importers i, cg_ref_codes ae
 WHERE a.port_cd = :P1210_PORT_CD
   AND a.impr_nbr = :P1210_IMPR_NBR
   AND i.port_cd (+) = a.port_cd
   AND i.impr_nbr (+) = a.impr_nbr_agent_id
   AND ae.rv_domain (+) = 'ALLOWED EXPORT' AND ae.rv_low_value (+) = TO_CHAR(a.allow_export)
 ORDER BY a.impr_nbr, a.athrztn_seq_nbr
```

## 4. Items (page 1210)

Canvas order (rows by Y, then X). Read only: `always` (display), `record` = `:P0_PAGE_PK IS NOT NULL`,
`locked` = `IMPR1210.AGNTS_IS_READ_ONLY(P_PORT_CD => :P1210_PORT_CD, P_ATHRZTN_SEQ_NBR => :P1210_ATHRZTN_SEQ_NBR)`.

| Item | Type | Label | Column | Required | LOV / mask / default | Read only | Source |
|---|---|---|---|---|---|---|---|
| `P1210_PORT_CD` | DISPLAY_ONLY | رمز الجمرك | PORT_CD | – | – | always | AGNTS.PORT_CD (CGSO$CHAR_ARB Required, Insert / Update Allowed = false; WHEN-CREATE-RECORD := P_CURR_PORT_CD; LOV CGFK$AGNTS_PORT_CD / KEY-LISTVAL LOV_SD_PORTS / button PORT_CD2 unreachable) |
| `P1210_PORT_NAME` | DISPLAY_ONLY | اسم الجمرك | – | – | – | always | AGNTS.PORT_NAME (non-database CGSO$CHAR_ARB_DO; WHEN-CREATE-RECORD / POST-QUERY) |
| `P1210_ATHRZTN_SEQ_NBR` | NUMBER_FIELD | مسلسل التفويض | ATHRZTN_SEQ_NBR | – | – | record | AGNTS.ATHRZTN_SEQ_NBR (Update Allowed = false; hint "للإستعلام أدخل مسلسل التفويض - لإدخال تفويض جديد اترك الخانة بدون بيانات"; PRE-INSERT MAX + 1) |
| `P1210_ALLOW_EXPORT` | SELECT_LIST | إستخدام التفويض | ALLOW_EXPORT | Yes | LOV_ALLOWED_EXPORT, default 0 | locked | AGNTS.ALLOW_EXPORT (CGSO$POP_MD Required, default 0; CGDV$POPULATE_DYNAMIC_LISTS CG_REF_CODES ALLOWED EXPORT) |
| `P1210_IMPR_NBR` | POPUP_LOV | رقم المستورد | IMPR_NBR | Yes | LOV_IMPR | locked | AGNTS.IMPR_NBR (Required; KEY-LISTVAL / button IMP_LOV -> LOV form LOV_IMPR, PORT_CD = P_CURR_PORT_CD) |
| `P1210_IMPR_EXPR_TYPE` | DISPLAY_ONLY | نشاط المستورد | – | – | LOV_ALLOWED_EXPORT | always | AGNTS.IMPR_EXPR_TYPE (non-database CGSO$POP_DO, list ALLOWED EXPORT; CGFK$CHK_AGNTS_AG_IMP_FK / POST-QUERY) |
| `P1210_IMPR_NAME` | DISPLAY_ONLY | اسم المستورد | – | – | – | always | AGNTS.IMPR_NAME (non-database; IMPR_NBR WHEN-VALIDATE-ITEM / POST-QUERY) |
| `P1210_IMPR_NBR_AG` | POPUP_LOV | رقم الشركة الوسيطة | IMPR_NBR_AGENT_ID | Yes | LOV_IMPR | locked | AGNTS.IMPR_NBR_AG (column IMPR_NBR_AGENT_ID, Required; KEY-LISTVAL / button AGNT_LOV -> LOV form LOV_IMPR) |
| `P1210_IMPR_EXPR_TYPE_AG` | DISPLAY_ONLY | نشاط الشركة الوسيطة | – | – | LOV_ALLOWED_EXPORT | always | AGNTS.IMPR_EXPR_TYPE_AG (non-database CGSO$POP_DO; CGFK$CHK_AGNTS_AG_IMP_AGENT_ID / POST-QUERY) |
| `P1210_IMPR_NAME_AG` | DISPLAY_ONLY | اسم الشركة الوسيطة | – | – | – | always | AGNTS.IMPR_NAME_AG (non-database; IMPR_NBR_AG WHEN-VALIDATE-ITEM / POST-QUERY) |
| `P1210_ATHRZTN_NOTE` | TEXT_FIELD | ملاحظات | ATHRZTN_NOTE | – | – | locked | AGNTS.ATHRZTN_NOTE (CGSO$CHAR_ARB, 51 characters) |
| `P1210_ATHRZTN_CRET_DT` | DISPLAY_ONLY | تاريخ التفويض | ATHRZTN_CRET_DT | – | &P1210_HIJRI_DATE_FORMAT. | always | AGNTS.ATHRZTN_CRET_DT (CGSO$HDATE_ARB_DO Hijri MI-MM-RRRR, never enterable; PRE-INSERT current Hijri date; WHEN-VALIDATE-ITEM HIJDATE.VALID_HIJ_DATE dropped) |
| `P1210_UPDATE_STATUS` | DISPLAY_ONLY | حالة التعديل | – | – | – | always | AGNTS.UPDATE_STATUS (non-database CGSO$CHAR_ARB_DO; WHEN-NEW-RECORD-INSTANCE message 8-30 / 8-80 / "يمكن التعديل") |
| `P1210_ATHRZTN_STA_CD` | RADIOGROUP | وضع التفويض | ATHRZTN_STA_CD | Yes | STATIC2:ساري;1,غير ساري;2, default 1 | locked | AGNTS.ATHRZTN_STA_CD (CGSO$RADIO_MD Required, default 1, radio B_1 ساري = 1 / B_2 غير ساري = 2; PRE-INSERT := 1; EXEC_FUNS; enterable as in Forms, inventory 15 #3) |
| `P1210_ATHRZTN_CNCLD_DT` | DISPLAY_ONLY | تاريخ الغاء التفويض | ATHRZTN_CNCLD_DT | – | &P1210_HIJRI_DATE_FORMAT. | always | AGNTS.ATHRZTN_CNCLD_DT (CGSO$HDATE_ARB_DO Hijri, never enterable; EXEC_FUNS CD1_STOPIMPRAUTH; WHEN-VALIDATE-ITEM dropped) |

Not displayed:

| Item | Type | Column | Source |
|---|---|---|---|
| `P1210_ROW_ID` | HIDDEN | ROWID | AGNTS ROWID (Form region primary key, = P0_PAGE_PK) |
| `P1210_MODULE_ID` | HIDDEN | – | f345 Page Functions: P<page>_MODULE_ID |
| `P1210_HIJRI_DATE_FORMAT` | HIDDEN | – | FORMS_APX.HIJRI_DATE_FORMAT (format mask of the Hijri dates) |
| `P1210_HERO_TITLE` | HIDDEN | – | f345 hero title (FORMS_APX.HEADER_TITLE) |
| `P1210_CONFIRM_STOP` | HIDDEN | – | PU EXEC_FUNS STR.DispArbMsg(9, 50, CONFIRM): text of the cancel confirmation (FORMS_APX.ARABIC_MESSAGE) |

## 5. Buttons

| Button | Region | Action | Source |
|---|---|---|---|
| `IMP_NEW` (إضافة وتعديل بيانات مستورد, `fa-user-plus`, `cg-b-new`) | AGNTS (body) | Redirect `f?p=&APP_ID.:1130:&SESSION.::&DEBUG.:::` | CGSO$WINDOW_1_IMP_NEW / OPEN_FORM('IMP_NEW') |
| SEARCH, CLEAR | 121001 criteria | Defined by Dynamic Action | Execute-Query / CLEAR_ALL |

CREATE / SAVE / DELETE / SEARCH / CLEAR / FUNCS / BACK come from the page 0 toolbar (f345).

## 6. LOVs

| LOV | Used by | Source |
|---|---|---|
| `LOV_IMPR` (reused, IMPR1110 export: `LOV_APX.IMPORTERS(P_PORT_ITEM => 'P_CURR_PORT_CD')`) | Popup LOV `P1210_IMPR_NBR`, `P1210_IMPR_NBR_AG` | LOV form LOV_IMPR (PORT_CD = P_CURR_PORT_CD) |
| `LOV_ALLOWED_EXPORT` (reused, IMPR1110 export: `LOV_APX.REFERENCE_CODES(P_DOMAIN => 'ALLOWED EXPORT')`) | `P1210_ALLOW_EXPORT`, `P1210_IMPR_EXPR_TYPE`, `P1210_IMPR_EXPR_TYPE_AG` | CGDV$POPULATE_DYNAMIC_LISTS |
| inline static `STATIC2:ساري;1,غير ساري;2` | radio `P1210_ATHRZTN_STA_CD` | radio buttons B_1 / B_2 |

## 7. Validations (page 1210)

| Validation | Item | Code | Condition | Source |
|---|---|---|---|---|
| ATHRZTN_SEQ_NBR VALIDATION | `P1210_ATHRZTN_SEQ_NBR` | `RETURN IMPR1210.ATHRZTN_SEQ_NBR_VALIDATION(P_PORT_CD => :P1210_PORT_CD, P_ATHRZTN_SEQ_NBR => :P1210_ATHRZTN_SEQ_NBR);` | `:REQUEST = 'CREATE'` | AGNTS.ATHRZTN_SEQ_NBR.WHEN-VALIDATE-ITEM |
| IMPR_NBR VALIDATION | `P1210_IMPR_NBR` | `RETURN IMPR1210.IMPR_NBR_VALIDATION(P_PORT_CD => :P1210_PORT_CD, P_IMPR_NBR => :P1210_IMPR_NBR, P_IMPR_NBR_AG => :P1210_IMPR_NBR_AG);` | `:REQUEST IN ('CREATE', 'SAVE')` | AGNTS.IMPR_NBR.WHEN-VALIDATE-ITEM (+ PU CHECK_SUSPENSION) |
| IMPR_NBR_AG VALIDATION | `P1210_IMPR_NBR_AG` | `RETURN IMPR1210.IMPR_NBR_AG_VALIDATION(P_PORT_CD => :P1210_PORT_CD, P_IMPR_NBR => :P1210_IMPR_NBR, P_IMPR_NBR_AG => :P1210_IMPR_NBR_AG);` | `:REQUEST IN ('CREATE', 'SAVE')` | AGNTS.IMPR_NBR_AG.WHEN-VALIDATE-ITEM (+ PU CHECK_SUSPENSION) |
| (native) Value Required | `P1210_ALLOW_EXPORT`, `P1210_IMPR_NBR`, `P1210_IMPR_NBR_AG`, `P1210_ATHRZTN_STA_CD` | – | – | Required = true |

## 8. Processes (page 1210, f345 standard §6)

| Point | Seq | Name | Code | Condition | Source |
|---|---|---|---|---|---|
| BEFORE_HEADER | 10 | New | – | NEVER | f345 session setup copied from AGR1100 (condition Never) / standard 6 |
| BEFORE_HEADER | 20 | P0_PAGE_PK CHECK | `IMPR1210.P0_PAGE_PK_CHECK(P_PAGE_PK => :P0_PAGE_PK, P_CURR_PORT_CD => :P_CURR_PORT_CD);` | – | f345 key (ROWID of AGNTS in the user's port, URL-safe from page 121001) |
| BEFORE_HEADER | 40 | PARAMETERS | `:P1210_MODULE_ID := FORMS_APX.GET_MODULE_ID(P_MODULE_ID => :P1210_MODULE_ID, FORM_NAME => 'IMPR1210');` | – | f345 module id of the Page Functions list |
| BEFORE_HEADER | 70 | P0_PAGE_PK | `:P1210_ROW_ID := :P0_PAGE_PK;` | – | f345 (key = ROWID) |
| BEFORE_HEADER | 80 | Initialize form | NATIVE_FORM_INIT | – | block AGNTS fetch |
| BEFORE_HEADER | 82 | POST-QUERY | `IMPR1210.POST_QUERY(P_PORT_CD => :P1210_PORT_CD, P_IMPR_NBR => :P1210_IMPR_NBR, P_IMPR_NBR_AG => :P1210_IMPR_NBR_AG, P_PORT_NAME => :P1210_PORT_NAME, P_IMPR_NAME => :P1210_IMPR_NAME, P_IMPR_EXPR_TYPE => :P1210_IMPR_EXPR_TYPE, P_IMPR_NAME_AG => :P1210_IMPR_NAME_AG, P_IMPR_EXPR_TYPE_AG => :P1210_IMPR_EXPR_TYPE_AG);` | :P1210_ROW_ID IS NOT NULL | AGNTS.POST-QUERY |
| BEFORE_HEADER | 84 | WHEN-CREATE-RECORD | `IMPR1210.WHEN_CREATE_RECORD(P_CURR_PORT_CD => :P_CURR_PORT_CD, P_PORT_CD => :P1210_PORT_CD, P_PORT_NAME => :P1210_PORT_NAME);` | :P1210_ROW_ID IS NULL | AGNTS.WHEN-CREATE-RECORD (PORT_CD, PORT_NAME of a new record; after Initialize form, which would clear them) |
| BEFORE_HEADER | 86 | WHEN-NEW-RECORD-INSTANCE | `IMPR1210.WHEN_NEW_RECORD_INSTANCE(P_PORT_CD => :P1210_PORT_CD, P_ATHRZTN_SEQ_NBR => :P1210_ATHRZTN_SEQ_NBR, P_UPDATE_STATUS => :P1210_UPDATE_STATUS);` | – | AGNTS.WHEN-NEW-RECORD-INSTANCE (UPDATE_STATUS) |
| BEFORE_HEADER | 100 | HEADER TITLE | `FORMS_APX.HEADER_TITLE(P_MODULE_ID => :P1210_MODULE_ID, P_HERO_TITLE => :P1210_HERO_TITLE, DEFAULT_TITLE => 'صيانة تفاويض الشركات الوسيطة');` | – | f345 hero title (module title) |
| AFTER_SUBMIT | 5 | EXECUTE-QUERY | `:P0_PAGE_PK := IMPR1210.PRE_QUERY(P_PORT_CD => :P1210_PORT_CD, P_ATHRZTN_SEQ_NBR => :P1210_ATHRZTN_SEQ_NBR);` | :REQUEST = 'EXECUTE_QUERY' | AGNTS.PRE-QUERY + IMPR_NBR.WHEN-NEW-ITEM-INSTANCE (EXEC_QUERY_NOW -> EXECUTE_QUERY) |
| AFTER_SUBMIT | 10 | PRE-INSERT | `IMPR1210.PRE_INSERT(P_PORT_CD => :P1210_PORT_CD, P_CURR_PORT_CD => :P_CURR_PORT_CD, SSO_APP_USER => :SSO_APP_USER, P_GLOBAL_V_WS_ID => :P_GLOBAL_V_WS_ID, P_ATHRZTN_SEQ_NBR => :P1210_ATHRZTN_SEQ_NBR, P_ATHRZTN_STA_CD => :P1210_ATHRZTN_STA_CD, P_ATHRZTN_CRET_DT => :P1210_ATHRZTN_CRET_DT);` | :P0_PAGE_PK IS NULL AND :REQUEST = 'CREATE' | AGNTS.PRE-INSERT |
| AFTER_SUBMIT | 20 | PRE-UPDATE | `IMPR1210.PRE_UPDATE(P_PORT_CD => :P1210_PORT_CD, P_ATHRZTN_SEQ_NBR => :P1210_ATHRZTN_SEQ_NBR, P_CURR_PORT_CD => :P_CURR_PORT_CD, SSO_APP_USER => :SSO_APP_USER, P_GLOBAL_V_WS_ID => :P_GLOBAL_V_WS_ID);` | :P0_PAGE_PK IS NOT NULL AND :REQUEST = 'SAVE' | AGNTS.PRE-UPDATE (+ WHEN-NEW-RECORD-INSTANCE update rule) |
| AFTER_SUBMIT | 30 | PRE-DELETE | `IMPR1210.PRE_DELETE;` | :REQUEST = 'DELETE' | FORM.KEY-DELREC (NIB) + WHEN-NEW-RECORD-INSTANCE: a queried authorization is never deletable |
| AFTER_SUBMIT | 40 | Process form | NATIVE_FORM_DML | :REQUEST IN ('CREATE', 'SAVE') | block AGNTS DML (insert / update) – success "تم الحفظ بنجاح" |
| AFTER_SUBMIT | 50 | CD1_STOPIMPRAUTH EXECUTE-FUNCTION | `IMPR1210.EXEC_FUNS(P_FUNCTION_CODE => 'CD1_STOPIMPRAUTH', P_PORT_CD => :P1210_PORT_CD, P_ATHRZTN_SEQ_NBR => :P1210_ATHRZTN_SEQ_NBR, P_CURR_PORT_CD => :P_CURR_PORT_CD, SSO_APP_USER => :SSO_APP_USER, P_GLOBAL_V_WS_ID => :P_GLOBAL_V_WS_ID);` | :REQUEST = 'CD1_STOPIMPRAUTH' | PU EXECUTE_FUNCTION -> EXEC_FUNS(CD1_STOPIMPRAUTH) (no message in Forms) |
| AFTER_SUBMIT | 60 | CD2_REUSEIMPRAUTH EXECUTE-FUNCTION | `IMPR1210.EXEC_FUNS(P_FUNCTION_CODE => 'CD2_REUSEIMPRAUTH', P_PORT_CD => :P1210_PORT_CD, P_ATHRZTN_SEQ_NBR => :P1210_ATHRZTN_SEQ_NBR, P_CURR_PORT_CD => :P_CURR_PORT_CD, SSO_APP_USER => :SSO_APP_USER, P_GLOBAL_V_WS_ID => :P_GLOBAL_V_WS_ID);` | :REQUEST = 'CD2_REUSEIMPRAUTH' | PU EXECUTE_FUNCTION -> EXEC_FUNS(CD2_REUSEIMPRAUTH) (no message in Forms) |
| AFTER_SUBMIT | 80 | P0_PAGE_PK AFTER INSERT | `:P0_PAGE_PK := :P1210_ROW_ID;` | :REQUEST = 'CREATE' | f345 |

## 9. Computations

| Item | Point | Expression | Source |
|---|---|---|---|
| `P1210_HIJRI_DATE_FORMAT` | BEFORE_HEADER | `FORMS_APX.HIJRI_DATE_FORMAT` | Hijri date format from one place: Application Setting HIJRI_DATE_FORMAT (Forms mask MI-MM-RRRR) |
| `P1210_CONFIRM_STOP` | BEFORE_HEADER | `FORMS_APX.ARABIC_MESSAGE(9, 50)` | PU EXEC_FUNS STR.DispArbMsg(9, 50, CONFIRM): text of the confirmation of CD1_STOPIMPRAUTH |

## 10. Dynamic Actions (page 1210)

| DA | Event | Element | Condition | Actions | Source |
|---|---|---|---|---|---|
| ATHRZTN_SEQ_NBR WHEN-VALIDATE-ITEM | change | P1210_ATHRZTN_SEQ_NBR | NOT_NULL | FOS `FORMS_APX.CHECK_ERROR(IMPR1210.ATHRZTN_SEQ_NBR_VALIDATION(P_PORT_CD => :P1210_PORT_CD, P_ATHRZTN_SEQ_NBR => :P1210_ATHRZTN_SEQ_NBR));` (submit P1210_PORT_CD, P1210_ATHRZTN_SEQ_NBR, return –); Submit Page `EXECUTE_QUERY` | AGNTS.ATHRZTN_SEQ_NBR.WHEN-VALIDATE-ITEM (message 9-40; :GLOBAL.EXEC_QUERY_NOW -> IMPR_NBR.WHEN-NEW-ITEM-INSTANCE EXECUTE_QUERY) |
| IMPR_NBR WHEN-VALIDATE-ITEM | change | P1210_IMPR_NBR | NOT_NULL | FOS `IMPR1210.IMPR_NBR_WHEN_VALIDATE_ITEM(P_PORT_CD => :P1210_PORT_CD, P_IMPR_NBR => :P1210_IMPR_NBR, P_IMPR_NBR_AG => :P1210_IMPR_NBR_AG, P_IMPR_NAME => :P1210_IMPR_NAME, P_IMPR_EXPR_TYPE => :P1210_IMPR_EXPR_TYPE);` (submit P1210_PORT_CD, P1210_IMPR_NBR, P1210_IMPR_NBR_AG, return P1210_IMPR_NAME, P1210_IMPR_EXPR_TYPE); Refresh region LOV_AGNT_ATHR_IMPR; NATIVE_SET_FOCUS P1210_IMPR_NBR_AG | AGNTS.IMPR_NBR.WHEN-VALIDATE-ITEM (name, CHECK_SUSPENSION, CALL_FORM LOV_AGNT_ATHR_IMPR -> grid of the importer's authorizations) + KEY-LISTVAL GO_ITEM; also after the Popup LOV LOV_IMPR |
| IMPR_NBR_AG WHEN-VALIDATE-ITEM | change | P1210_IMPR_NBR_AG | NOT_NULL | FOS `IMPR1210.IMPR_NBR_AG_WHEN_VALIDATE_ITEM(P_PORT_CD => :P1210_PORT_CD, P_IMPR_NBR => :P1210_IMPR_NBR, P_IMPR_NBR_AG => :P1210_IMPR_NBR_AG, P_IMPR_NAME_AG => :P1210_IMPR_NAME_AG, P_IMPR_EXPR_TYPE_AG => :P1210_IMPR_EXPR_TYPE_AG);` (submit P1210_PORT_CD, P1210_IMPR_NBR, P1210_IMPR_NBR_AG, return P1210_IMPR_NAME_AG, P1210_IMPR_EXPR_TYPE_AG); NATIVE_SET_FOCUS P1210_ATHRZTN_NOTE | AGNTS.IMPR_NBR_AG.WHEN-VALIDATE-ITEM (name, CHECK_SUSPENSION, <> IMPR_NBR) + KEY-LISTVAL GO_ITEM('ATHRZTN_NOTE') |
| CD1_STOPIMPRAUTH EXECUTE-FUNCTION | custom:CD1_STOPIMPRAUTH | document | JAVASCRIPT_EXPRESSION `$v('P1210_ATHRZTN_SEQ_NBR') !== '' && $v('P1210_ATHRZTN_STA_CD') === '1'` | Confirm "&P1210_CONFIRM_STOP."; Submit Page `CD1_STOPIMPRAUTH` | PU EXEC_FUNS(CD1_STOPIMPRAUTH): ATHRZTN_SEQ_NBR shown and status 1 -> STR.DispArbMsg(9, 50, CONFIRM) -> request (event of the f345 Page Functions list) |
| CD2_REUSEIMPRAUTH EXECUTE-FUNCTION | custom:CD2_REUSEIMPRAUTH | document | JAVASCRIPT_EXPRESSION `$v('P1210_ATHRZTN_SEQ_NBR') !== '' && $v('P1210_ATHRZTN_STA_CD') === '2'` | Confirm "سيتم إسترجاع التفويض - هل ترغب في إستكمال الإسترجاع"; Submit Page `CD2_REUSEIMPRAUTH` | PU EXEC_FUNS(CD2_REUSEIMPRAUTH): ATHRZTN_SEQ_NBR shown and status 2 -> STR.DispALERT(... CONFIRM) -> request |

JavaScript actions: **none**. Client-side conditions in JavaScript: the two function DAs (one expression each, the Forms
`IF :ATHRZTN_SEQ_NBR IS NOT NULL AND :ATHRZTN_STA_CD = 1 / 2` before the confirmation; `EXEC_FUNS` checks the stored status
again) and the f345 `this.browserEvent.which === 13` condition of SEARCH KEY-ENTER on page 121001.

## 11. Alerts and messages

| Text Message / text | Where | Source |
|---|---|---|
| `AG_PK` = "هذا السجل مدخل سابقاً - أعد ادخال البيانات" | APEX error handler (constraint) | CGTE$CHECK_CONSTRAINT_VIO (ORA-00001) |
| `AG_SDP_FK` = "رمز الجمرك غير صحيح - أعد إدخال رمز الجمرك" | APEX error handler (constraint) | AGNTS.ON-ERROR (ORA-02291) |
| `AG_IMP_FK` = "بيانات المستورد غير صحيحة - أعد إدخال البيانات" | APEX error handler (constraint) | AGNTS.ON-ERROR (ORA-02291) |
| `AG_IMP_AGENT_ID_FK` = "بيانات الشركة الوسيطة غير صحيحة - أعد إدخال البيانات" | APEX error handler (constraint) | AGNTS.ON-ERROR (ORA-02291) |
| 9-10, 9-20, 9-70 (`FORMS_APX.ARABIC_MESSAGE`) | `IMPR_NBR_VALIDATION`, `IMPR_NBR_AG_VALIDATION` | IMPR_NBR / IMPR_NBR_AG WHEN-VALIDATE-ITEM, CHECK_SUSPENSION |
| 9-40 | `ATHRZTN_SEQ_NBR_VALIDATION` | ATHRZTN_SEQ_NBR WHEN-VALIDATE-ITEM |
| 9-50 (confirm, item `P1210_CONFIRM_STOP`) | DA CD1_STOPIMPRAUTH EXECUTE-FUNCTION | EXEC_FUNS |
| "سيتم إسترجاع التفويض - هل ترغب في إستكمال الإسترجاع" (confirm) | DA CD2_REUSEIMPRAUTH EXECUTE-FUNCTION | EXEC_FUNS |
| 8-30 / 8-80 / " يمكن التعديل" | `P1210_UPDATE_STATUS`; `PRE_UPDATE` error | WHEN-NEW-RECORD-INSTANCE |
| "لا يمكن حذف بيانات من هذه الشاشة" | `PRE_DELETE` | KEY-DELREC |

## 12. Branches and navigation

| Branch | Point | Target | Source |
|---|---|---|---|
| IMPR1210 - stay in the form | After Processing | page 1210 with the success message (`P0_PAGE_PK` kept, or set by EXECUTE-QUERY / AFTER INSERT) | Forms stays on the record after COMMIT / EXECUTE_QUERY |
| search link / grid link | – | `f?p=&APP_ID.:1210:&SESSION.::&DEBUG.:1210:P0_PAGE_PK:&ROW_ID.` (ROW_ID URL-safe) | Execute-Query / LOV_AGNT_ATHR_IMPR |
| button IMP_NEW | – | page 1130 | OPEN_FORM('IMP_NEW') |

## 13. Shared components

Reused from f345: theme 42 / ZATCA Forms, page 0 (`P0_ACTIONS`, `P0_PAGE_PK`, `P0_SEARCH_URL`, `ASK_DLG`, FUNCS drawer),
application items `P_CURR_PORT_CD`, `SSO_APP_USER`, `P_GLOBAL_V_WS_ID`, `SYS_ANAME`, app process `SCREEN ENTRY RESET`,
`APP_ERROR_HANDLER`, plug-in `COM.FOS.EXECUTE_PLSQL_CODE`. From IMPR1110: page group `IMPR`, Application Setting
`HIJRI_DATE_FORMAT`, LOVs `LOV_IMPR`, `LOV_ALLOWED_EXPORT`. New: Text Messages `AG_PK`, `AG_SDP_FK`, `AG_IMP_FK`,
`AG_IMP_AGENT_ID_FK`. No application item, LOV, authorization scheme or page 0 change. The Page Functions list must hold the
two functions of the module (SC_SYSTEM_OBJECTS `CD1_STOPIMPRAUTH`, `CD2_REUSEIMPRAUTH`): data of the f345 list, not of this export.

Security (CLAUDE.md §8): page access and the two functions by the application's privileges; Forms used the table grants
(ORA-01031 messages of ON-ERROR) – the privilege administrators decide who may cancel / restore an authorization.

## 14. Traceability (every Forms object)

444 objects: DROPPED 365, MAPPED 78, TODO 1.

| # | Type | Forms object | APEX component | Page | Package member | Status | Notes |
|---|---|---|---|---|---|---|---|
| 1 | BLOCK | `TITLE` | REGION | AGNTS_HERO | 1210 | - | MAPPED | OLB title bar -> f345 hero region (FORMS_APX.HEADER_TITLE) |
| 2 | BLOCK | `EDI_MSG` | - | - | - | - | DROPPED | OLB EDI message ticker - dropped (timers, IMPR1110 decision 2026-11-19) |
| 3 | BLOCK | `LSIDE` | REGION | FUNCS (page 0 drawer) | 0 | - | MAPPED | OLB side function menu -> page 0 FUNCS, f345 list Page Functions |
| 4 | BLOCK | `TOOLBAR` | REGION | P0_ACTIONS (page 0 toolbar, f345) | 0 | - | MAPPED | OLB toolbar -> f345 page 0 toolbar |
| 5 | BLOCK | `AGNTS` | REGION | AGNTS (Form, key ROWID, i:u) | 1210 | - | MAPPED | single record, WHERE PORT_CD = P_CURR_PORT_CD; update rule AGNTS_IS_READ_ONLY; no delete |
| 6 | BLOCK | `CGNV$CGSO$WINDOW_1_1` | BUTTON | IMP_NEW | 1210 | - | MAPPED | Designer action-item block -> page button IMP_NEW |
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
| 87 | ITEM | `AGNTS.PORT_CD` | PAGE_ITEM | P1210_PORT_CD | 1210 | - | MAPPED | spec section 4 |
| 88 | ITEM | `AGNTS.PORT_CD2` | - | - | - | - | DROPPED | LOV button of PORT_CD: the item is never enterable |
| 89 | ITEM | `AGNTS.PORT_NAME` | PAGE_ITEM | P1210_PORT_NAME | 1210 | - | MAPPED | spec section 4 |
| 90 | ITEM | `AGNTS.ATHRZTN_SEQ_NBR` | PAGE_ITEM | P1210_ATHRZTN_SEQ_NBR | 1210 | - | MAPPED | spec section 4 |
| 91 | ITEM | `AGNTS.ALLOW_EXPORT` | PAGE_ITEM | P1210_ALLOW_EXPORT | 1210 | - | MAPPED | spec section 4 |
| 92 | ITEM | `AGNTS.IMPR_NBR` | PAGE_ITEM | P1210_IMPR_NBR | 1210 | - | MAPPED | spec section 4 |
| 93 | ITEM | `AGNTS.IMP_LOV` | - | - | - | - | DROPPED | LOV button of IMPR_NBR -> Popup LOV button of P1210_IMPR_NBR |
| 94 | ITEM | `AGNTS.IMPR_EXPR_TYPE` | PAGE_ITEM | P1210_IMPR_EXPR_TYPE | 1210 | - | MAPPED | spec section 4 |
| 95 | ITEM | `AGNTS.IMPR_NAME` | PAGE_ITEM | P1210_IMPR_NAME | 1210 | - | MAPPED | spec section 4 |
| 96 | ITEM | `AGNTS.IMPR_NBR_AG` | PAGE_ITEM | P1210_IMPR_NBR_AG | 1210 | - | MAPPED | spec section 4 |
| 97 | ITEM | `AGNTS.AGNT_LOV` | - | - | - | - | DROPPED | LOV button of IMPR_NBR_AG -> Popup LOV button of P1210_IMPR_NBR_AG |
| 98 | ITEM | `AGNTS.IMPR_EXPR_TYPE_AG` | PAGE_ITEM | P1210_IMPR_EXPR_TYPE_AG | 1210 | - | MAPPED | spec section 4 |
| 99 | ITEM | `AGNTS.IMPR_NAME_AG` | PAGE_ITEM | P1210_IMPR_NAME_AG | 1210 | - | MAPPED | spec section 4 |
| 100 | ITEM | `AGNTS.ATHRZTN_NOTE` | PAGE_ITEM | P1210_ATHRZTN_NOTE | 1210 | - | MAPPED | spec section 4 |
| 101 | ITEM | `AGNTS.ATHRZTN_CRET_DT` | PAGE_ITEM | P1210_ATHRZTN_CRET_DT | 1210 | - | MAPPED | spec section 4 |
| 102 | ITEM | `AGNTS.UPDATE_STATUS` | PAGE_ITEM | P1210_UPDATE_STATUS | 1210 | - | MAPPED | spec section 4 |
| 103 | ITEM | `AGNTS.SDP_PORT_STATUS` | - | - | - | - | DROPPED | not displayed, never read (CGFK$QRY_AGNTS_AG_SDP_FK output) |
| 104 | ITEM | `AGNTS.ATHRZTN_STA_CD` | PAGE_ITEM | P1210_ATHRZTN_STA_CD | 1210 | - | MAPPED | spec section 4 |
| 105 | ITEM | `AGNTS.ATHRZTN_CNCLD_DT` | PAGE_ITEM | P1210_ATHRZTN_CNCLD_DT | 1210 | - | MAPPED | spec section 4 |
| 106 | ITEM | `CGNV$CGSO$WINDOW_1_1.CGSO$WINDOW_1_IMP_NEW` | BUTTON | IMP_NEW | 1210 | - | MAPPED | redirect to page 1130 (to confirm, inventory 15 #5) |
| 107 | TRIGGER | `FORM.KEY-EDIT` | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| 108 | TRIGGER | `FORM.KEY-DUPREC` | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| 109 | TRIGGER | `FORM.PRE-FORM` | - | - | - | - | DROPPED | NIB.PRE_FORM, version globals (CR-5537), NLS date format, help globals |
| 110 | TRIGGER | `FORM.WHEN-NEW-FORM-INSTANCE` | PROCESS | PARAMETERS / HEADER TITLE | 1210 | - | MAPPED | NIB frame + CG$WHEN_NEW_FORM_INSTANCE (lists); globals it clears are unused |
| 111 | TRIGGER | `FORM.WHEN-WINDOW-ACTIVATED` | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| 112 | TRIGGER | `FORM.KEY-ENTQRY` | PAGE | IMPR1210_SEARCH | 121001 | - | MAPPED | NIB.KEY_ENTQRY -> page 0 SEARCH |
| 113 | TRIGGER | `FORM.ON-ERROR` | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| 114 | TRIGGER | `FORM.ON-MESSAGE` | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| 115 | TRIGGER | `FORM.KEY-CLRBLK` | BUTTON | CLEAR (page 0 toolbar) | 0 | - | MAPPED | NIB.KEY_CLRBLK |
| 116 | TRIGGER | `FORM.KEY-DELREC` | PROCESS | PRE-DELETE | 1210 | IMPR1210.PRE_DELETE | MAPPED | NIB.KEY_DELREC; queried records never deletable -> refused |
| 117 | TRIGGER | `FORM.KEY-F5` | PROCESS | Process form | 1210 | - | MAPPED | NIB.KEY_F5 (commit) -> page 0 CREATE / SAVE |
| 118 | TRIGGER | `FORM.KEY-F4` | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| 119 | TRIGGER | `FORM.KEY-NXTREC` | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| 120 | TRIGGER | `FORM.KEY-PRVREC` | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| 121 | TRIGGER | `FORM.KEY-DOWN` | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| 122 | TRIGGER | `FORM.KEY-UP` | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| 123 | TRIGGER | `FORM.KEY-SCRUP` | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| 124 | TRIGGER | `FORM.KEY-SCRDOWN` | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| 125 | TRIGGER | `FORM.KEY-PRINT` | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| 126 | TRIGGER | `FORM.KEY-EXIT` | BUTTON | BACK (page 0 toolbar) | 0 | - | MAPPED | NIB.KEY_EXIT |
| 127 | TRIGGER | `FORM.WHEN-MOUSE-DOWN` | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| 128 | TRIGGER | `FORM.KEY-EXEQRY` | PAGE | IMPR1210_SEARCH | 121001 | - | MAPPED | NIB.KEY_EXEQRY -> search grid |
| 129 | TRIGGER | `FORM.KEY-F9` | REGION | FUNCS (page 0) | 0 | - | MAPPED | functions menu (CD1_STOPIMPRAUTH, CD2_REUSEIMPRAUTH) |
| 130 | TRIGGER | `FORM.WHEN-TIMER-EXPIRED` | - | - | - | - | DROPPED | screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS) |
| 131 | TRIGGER | `FORM.KEY-HELP` | - | - | - | - | DROPPED | Designer help file (empty CG$HP_HFILE) |
| 132 | TRIGGER | `FORM.KEY-CLRFRM` | BUTTON | CLEAR (page 0 toolbar) | 0 | - | MAPPED | clear_form + CG$WHEN_NEW_FORM_INSTANCE (lists: shared LOV) |
| 133 | TRIGGER | `TITLE.CGSO$CHAR_ARB_ED.KEY-LISTVAL` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 134 | TRIGGER | `TITLE.CGSO$CHAR_ARB_DO_ENB_Y.KEY-LISTVAL` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 135 | TRIGGER | `TITLE.CGSO$CHAR_ARB_MLINE.KEY-LISTVAL` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 136 | TRIGGER | `TITLE.CGSO$CHAR_ARB.KEY-LISTVAL` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 137 | TRIGGER | `TITLE.CGSO$CHAR_ARB_DO.KEY-LISTVAL` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 138 | TRIGGER | `TITLE.SYSTEM_DATE.WHEN-VALIDATE-ITEM` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 139 | TRIGGER | `EDI_MSG.EDI_MSG_LOVE_BUT.WHEN-BUTTON-PRESSED` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 140 | TRIGGER | `LSIDE.FN1.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 141 | TRIGGER | `LSIDE.FN1.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 142 | TRIGGER | `LSIDE.FN1.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 143 | TRIGGER | `LSIDE.FN50.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 144 | TRIGGER | `LSIDE.FN50.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 145 | TRIGGER | `LSIDE.FN50.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 146 | TRIGGER | `LSIDE.FN2.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 147 | TRIGGER | `LSIDE.FN2.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 148 | TRIGGER | `LSIDE.FN2.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 149 | TRIGGER | `LSIDE.FN49.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 150 | TRIGGER | `LSIDE.FN49.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 151 | TRIGGER | `LSIDE.FN49.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 152 | TRIGGER | `LSIDE.FN3.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 153 | TRIGGER | `LSIDE.FN3.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 154 | TRIGGER | `LSIDE.FN3.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 155 | TRIGGER | `LSIDE.FN48.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 156 | TRIGGER | `LSIDE.FN48.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 157 | TRIGGER | `LSIDE.FN48.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 158 | TRIGGER | `LSIDE.FN4.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 159 | TRIGGER | `LSIDE.FN4.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 160 | TRIGGER | `LSIDE.FN4.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 161 | TRIGGER | `LSIDE.FN47.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 162 | TRIGGER | `LSIDE.FN47.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 163 | TRIGGER | `LSIDE.FN47.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 164 | TRIGGER | `LSIDE.FN5.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 165 | TRIGGER | `LSIDE.FN5.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 166 | TRIGGER | `LSIDE.FN5.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 167 | TRIGGER | `LSIDE.FN46.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 168 | TRIGGER | `LSIDE.FN46.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 169 | TRIGGER | `LSIDE.FN46.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 170 | TRIGGER | `LSIDE.FN6.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 171 | TRIGGER | `LSIDE.FN6.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 172 | TRIGGER | `LSIDE.FN6.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 173 | TRIGGER | `LSIDE.FN45.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 174 | TRIGGER | `LSIDE.FN45.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 175 | TRIGGER | `LSIDE.FN45.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 176 | TRIGGER | `LSIDE.FN7.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 177 | TRIGGER | `LSIDE.FN7.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 178 | TRIGGER | `LSIDE.FN7.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 179 | TRIGGER | `LSIDE.FN44.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 180 | TRIGGER | `LSIDE.FN44.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 181 | TRIGGER | `LSIDE.FN44.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 182 | TRIGGER | `LSIDE.FN8.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 183 | TRIGGER | `LSIDE.FN8.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 184 | TRIGGER | `LSIDE.FN8.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 185 | TRIGGER | `LSIDE.FN43.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 186 | TRIGGER | `LSIDE.FN43.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 187 | TRIGGER | `LSIDE.FN43.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 188 | TRIGGER | `LSIDE.FN9.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 189 | TRIGGER | `LSIDE.FN9.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 190 | TRIGGER | `LSIDE.FN9.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 191 | TRIGGER | `LSIDE.FN42.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 192 | TRIGGER | `LSIDE.FN42.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 193 | TRIGGER | `LSIDE.FN42.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 194 | TRIGGER | `LSIDE.FN10.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 195 | TRIGGER | `LSIDE.FN10.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 196 | TRIGGER | `LSIDE.FN10.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 197 | TRIGGER | `LSIDE.FN41.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 198 | TRIGGER | `LSIDE.FN41.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 199 | TRIGGER | `LSIDE.FN41.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 200 | TRIGGER | `LSIDE.FN11.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 201 | TRIGGER | `LSIDE.FN11.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 202 | TRIGGER | `LSIDE.FN11.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 203 | TRIGGER | `LSIDE.FN40.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 204 | TRIGGER | `LSIDE.FN40.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 205 | TRIGGER | `LSIDE.FN40.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 206 | TRIGGER | `LSIDE.FN12.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 207 | TRIGGER | `LSIDE.FN12.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 208 | TRIGGER | `LSIDE.FN12.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 209 | TRIGGER | `LSIDE.FN39.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 210 | TRIGGER | `LSIDE.FN39.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 211 | TRIGGER | `LSIDE.FN39.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 212 | TRIGGER | `LSIDE.FN13.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 213 | TRIGGER | `LSIDE.FN13.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 214 | TRIGGER | `LSIDE.FN13.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 215 | TRIGGER | `LSIDE.FN38.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 216 | TRIGGER | `LSIDE.FN38.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 217 | TRIGGER | `LSIDE.FN38.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 218 | TRIGGER | `LSIDE.FN14.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 219 | TRIGGER | `LSIDE.FN14.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 220 | TRIGGER | `LSIDE.FN14.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 221 | TRIGGER | `LSIDE.FN37.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 222 | TRIGGER | `LSIDE.FN37.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 223 | TRIGGER | `LSIDE.FN37.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 224 | TRIGGER | `LSIDE.FN15.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 225 | TRIGGER | `LSIDE.FN15.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 226 | TRIGGER | `LSIDE.FN15.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 227 | TRIGGER | `LSIDE.FN36.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 228 | TRIGGER | `LSIDE.FN36.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 229 | TRIGGER | `LSIDE.FN36.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 230 | TRIGGER | `LSIDE.FN16.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 231 | TRIGGER | `LSIDE.FN16.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 232 | TRIGGER | `LSIDE.FN16.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 233 | TRIGGER | `LSIDE.FN17.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 234 | TRIGGER | `LSIDE.FN17.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 235 | TRIGGER | `LSIDE.FN17.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 236 | TRIGGER | `LSIDE.FN34.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 237 | TRIGGER | `LSIDE.FN34.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 238 | TRIGGER | `LSIDE.FN34.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 239 | TRIGGER | `LSIDE.FN35.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 240 | TRIGGER | `LSIDE.FN35.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 241 | TRIGGER | `LSIDE.FN35.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 242 | TRIGGER | `LSIDE.FN18.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 243 | TRIGGER | `LSIDE.FN18.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 244 | TRIGGER | `LSIDE.FN18.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 245 | TRIGGER | `LSIDE.FN33.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 246 | TRIGGER | `LSIDE.FN33.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 247 | TRIGGER | `LSIDE.FN33.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 248 | TRIGGER | `LSIDE.FN19.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 249 | TRIGGER | `LSIDE.FN19.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 250 | TRIGGER | `LSIDE.FN19.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 251 | TRIGGER | `LSIDE.FN32.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 252 | TRIGGER | `LSIDE.FN32.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 253 | TRIGGER | `LSIDE.FN32.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 254 | TRIGGER | `LSIDE.FN20.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 255 | TRIGGER | `LSIDE.FN20.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 256 | TRIGGER | `LSIDE.FN20.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 257 | TRIGGER | `LSIDE.FN31.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 258 | TRIGGER | `LSIDE.FN31.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 259 | TRIGGER | `LSIDE.FN31.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 260 | TRIGGER | `LSIDE.FN21.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 261 | TRIGGER | `LSIDE.FN21.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 262 | TRIGGER | `LSIDE.FN21.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 263 | TRIGGER | `LSIDE.FN30.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 264 | TRIGGER | `LSIDE.FN30.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 265 | TRIGGER | `LSIDE.FN30.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 266 | TRIGGER | `LSIDE.FN22.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 267 | TRIGGER | `LSIDE.FN22.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 268 | TRIGGER | `LSIDE.FN22.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 269 | TRIGGER | `LSIDE.FN29.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 270 | TRIGGER | `LSIDE.FN29.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 271 | TRIGGER | `LSIDE.FN29.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 272 | TRIGGER | `LSIDE.FN23.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 273 | TRIGGER | `LSIDE.FN23.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 274 | TRIGGER | `LSIDE.FN23.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 275 | TRIGGER | `LSIDE.FN28.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 276 | TRIGGER | `LSIDE.FN28.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 277 | TRIGGER | `LSIDE.FN28.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 278 | TRIGGER | `LSIDE.FN24.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 279 | TRIGGER | `LSIDE.FN24.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 280 | TRIGGER | `LSIDE.FN24.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 281 | TRIGGER | `LSIDE.FN27.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 282 | TRIGGER | `LSIDE.FN27.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 283 | TRIGGER | `LSIDE.FN27.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 284 | TRIGGER | `LSIDE.FN25.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 285 | TRIGGER | `LSIDE.FN25.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 286 | TRIGGER | `LSIDE.FN25.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 287 | TRIGGER | `LSIDE.FN26.WHEN-MOUSE-ENTER` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 288 | TRIGGER | `LSIDE.FN26.WHEN-MOUSE-LEAVE` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 289 | TRIGGER | `LSIDE.FN26.WHEN-MOUSE-CLICK` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 290 | TRIGGER | `TOOLBAR.KEY-DOWN` | - | - | - | - | DROPPED | OLB frame block trigger (toolbar keys) |
| 291 | TRIGGER | `TOOLBAR.KEY-UP` | - | - | - | - | DROPPED | OLB frame block trigger (toolbar keys) |
| 292 | TRIGGER | `TOOLBAR.KEY-NEXT-ITEM` | - | - | - | - | DROPPED | OLB frame block trigger (toolbar keys) |
| 293 | TRIGGER | `TOOLBAR.SAVE.WHEN-BUTTON-PRESSED` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 294 | TRIGGER | `TOOLBAR.CLEAR_ALL.WHEN-BUTTON-PRESSED` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 295 | TRIGGER | `TOOLBAR.EXIT.WHEN-BUTTON-PRESSED` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 296 | TRIGGER | `TOOLBAR.EXIT1.WHEN-BUTTON-PRESSED` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 297 | TRIGGER | `TOOLBAR.ENTER.WHEN-BUTTON-PRESSED` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 298 | TRIGGER | `TOOLBAR.EXECUTE.WHEN-BUTTON-PRESSED` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 299 | TRIGGER | `TOOLBAR.REMOVE.WHEN-BUTTON-PRESSED` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 300 | TRIGGER | `TOOLBAR.LIST_VALUE.WHEN-BUTTON-PRESSED` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 301 | TRIGGER | `TOOLBAR.HELP.WHEN-BUTTON-PRESSED` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 302 | TRIGGER | `TOOLBAR.LAST_REC.WHEN-BUTTON-PRESSED` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 303 | TRIGGER | `TOOLBAR.RE_ENTER_QUERY.WHEN-BUTTON-PRESSED` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 304 | TRIGGER | `TOOLBAR.FIRST_REC.WHEN-BUTTON-PRESSED` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 305 | TRIGGER | `TOOLBAR.PAGE_UP.WHEN-BUTTON-PRESSED` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 306 | TRIGGER | `TOOLBAR.PAGE_DOWN.WHEN-BUTTON-PRESSED` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 307 | TRIGGER | `TOOLBAR.FUN_BUT.WHEN-MOUSE-UP` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 308 | TRIGGER | `TOOLBAR.FUN_BUT.WHEN-MOUSE-DOWN` | - | - | - | - | DROPPED | OLB frame item trigger (mouse / toolbar) |
| 309 | TRIGGER | `AGNTS.ON-ERROR` | MESSAGE | AG_PK, AG_SDP_FK, AG_IMP_FK, AG_IMP_AGENT_ID_FK | - | - | MAPPED | constraint texts -> Text Messages (FORMS_APX.apex_error_handler); ORA-01031 texts dropped |
| 310 | TRIGGER | `AGNTS.POST-QUERY` | PROCESS | POST-QUERY | 1210 | IMPR1210.POST_QUERY | MAPPED | Before Header after Initialize form |
| 311 | TRIGGER | `AGNTS.KEY-HELP` | - | - | - | - | DROPPED | Designer help file (empty CG$HP_HFILE) |
| 312 | TRIGGER | `AGNTS.PRE-INSERT` | PROCESS | PRE-INSERT | 1210 | IMPR1210.PRE_INSERT | MAPPED | MAX + 1, status 1, Hijri date, activity 1 |
| 313 | TRIGGER | `AGNTS.PRE-QUERY` | PROCESS | EXECUTE-QUERY | 1210 | IMPR1210.PRE_QUERY | MAPPED | globals of ATHRZTN_SEQ_NBR -> request EXECUTE_QUERY |
| 314 | TRIGGER | `AGNTS.PRE-UPDATE` | PROCESS | PRE-UPDATE | 1210 | IMPR1210.PRE_UPDATE | MAPPED | update rule + activity 2 |
| 315 | TRIGGER | `AGNTS.WHEN-CREATE-RECORD` | PROCESS | WHEN-CREATE-RECORD | 1210 | IMPR1210.WHEN_CREATE_RECORD | MAPPED | PORT_CD, PORT_NAME |
| 316 | TRIGGER | `AGNTS.WHEN-NEW-RECORD-INSTANCE` | PROCESS | WHEN-NEW-RECORD-INSTANCE | 1210 | IMPR1210.WHEN_NEW_RECORD_INSTANCE | MAPPED | UPDATE_STATUS; MAKE_BLOCK_FULL_OPERATION -> AGNTS_IS_READ_ONLY (item conditions) |
| 317 | TRIGGER | `AGNTS.PORT_CD.KEY-LISTVAL` | - | - | - | - | DROPPED | CALL_FORM LOV_SD_PORTS on an item that is never enterable |
| 318 | TRIGGER | `AGNTS.PORT_CD2.WHEN-BUTTON-PRESSED` | - | - | - | - | DROPPED | LOV button of a non-enterable item |
| 319 | TRIGGER | `AGNTS.PORT_NAME.KEY-LISTVAL` | - | - | - | - | DROPPED | Designer "may the LOV be shown" check of an item without LOV |
| 320 | TRIGGER | `AGNTS.ATHRZTN_SEQ_NBR.KEY-LISTVAL` | - | - | - | - | DROPPED | Designer "may the LOV be shown" check of an item without LOV |
| 321 | TRIGGER | `AGNTS.ATHRZTN_SEQ_NBR.WHEN-VALIDATE-ITEM` | VALIDATION | ATHRZTN_SEQ_NBR VALIDATION + DA ATHRZTN_SEQ_NBR WHEN-VALIDATE-ITEM | 1210 | IMPR1210.ATHRZTN_SEQ_NBR_VALIDATION | MAPPED | message 9-40, then EXECUTE_QUERY |
| 322 | TRIGGER | `AGNTS.IMPR_NBR.KEY-LISTVAL` | LOV | LOV_IMPR (IMPR1110) | 1210 | - | MAPPED | CALL_FORM LOV_IMPR -> Popup LOV |
| 323 | TRIGGER | `AGNTS.IMPR_NBR.WHEN-VALIDATE-ITEM` | VALIDATION | IMPR_NBR VALIDATION + DA IMPR_NBR WHEN-VALIDATE-ITEM | 1210 | IMPR1210.IMPR_NBR_WHEN_VALIDATE_ITEM | MAPPED | 9-20 / 9-70 / 9-10; CALL_FORM LOV_AGNT_ATHR_IMPR -> grid LOV_AGNT_ATHR_IMPR |
| 324 | TRIGGER | `AGNTS.IMPR_NBR.WHEN-NEW-ITEM-INSTANCE` | BRANCH | IMPR1210 - stay in the form | 1210 | - | MAPPED | EXEC_QUERY_NOW -> CLEAR_BLOCK + EXECUTE_QUERY = page reload with P0_PAGE_PK |
| 325 | TRIGGER | `AGNTS.IMP_LOV.WHEN-BUTTON-PRESSED` | LOV | LOV_IMPR (Popup LOV button) | 1210 | - | MAPPED | GO_ITEM + LIST_VALUES |
| 326 | TRIGGER | `AGNTS.IMPR_NAME.KEY-LISTVAL` | - | - | - | - | DROPPED | Designer "may the LOV be shown" check of an item without LOV |
| 327 | TRIGGER | `AGNTS.IMPR_NBR_AG.KEY-LISTVAL` | LOV | LOV_IMPR (IMPR1110) | 1210 | - | MAPPED | CALL_FORM LOV_IMPR -> Popup LOV |
| 328 | TRIGGER | `AGNTS.IMPR_NBR_AG.WHEN-VALIDATE-ITEM` | VALIDATION | IMPR_NBR_AG VALIDATION + DA IMPR_NBR_AG WHEN-VALIDATE-ITEM | 1210 | IMPR1210.IMPR_NBR_AG_WHEN_VALIDATE_ITEM | MAPPED | 9-20 / 9-70 / 9-10 |
| 329 | TRIGGER | `AGNTS.IMPR_NBR_AG.WHEN-NEW-ITEM-INSTANCE` | - | - | - | - | DROPPED | :GLOBAL.EXEC_QUERY only set after LOV_AGNT_ATHR_IMPR (inventory 14 #4) |
| 330 | TRIGGER | `AGNTS.AGNT_LOV.WHEN-BUTTON-PRESSED` | LOV | LOV_IMPR (Popup LOV button) | 1210 | - | MAPPED | GO_ITEM + LIST_VALUES |
| 331 | TRIGGER | `AGNTS.IMPR_NAME_AG.KEY-LISTVAL` | - | - | - | - | DROPPED | Designer "may the LOV be shown" check of an item without LOV |
| 332 | TRIGGER | `AGNTS.ATHRZTN_NOTE.KEY-LISTVAL` | - | - | - | - | DROPPED | Designer "may the LOV be shown" check of an item without LOV |
| 333 | TRIGGER | `AGNTS.ATHRZTN_CRET_DT.WHEN-VALIDATE-ITEM` | - | - | - | - | DROPPED | Hijri check of an item that is never enterable (display only) |
| 334 | TRIGGER | `AGNTS.UPDATE_STATUS.KEY-LISTVAL` | - | - | - | - | DROPPED | Designer "may the LOV be shown" check of an item without LOV |
| 335 | TRIGGER | `AGNTS.SDP_PORT_STATUS.KEY-LISTVAL` | - | - | - | - | DROPPED | Designer "may the LOV be shown" check of an item without LOV |
| 336 | TRIGGER | `AGNTS.ATHRZTN_CNCLD_DT.WHEN-VALIDATE-ITEM` | - | - | - | - | DROPPED | Hijri check of an item that is never enterable (display only) |
| 337 | TRIGGER | `CGNV$CGSO$WINDOW_1_1.CGSO$WINDOW_1_IMP_NEW.WHEN-BUTTON-PRESSED` | BUTTON | IMP_NEW | 1210 | - | MAPPED | OPEN_FORM IMP_NEW -> page 1130 (to confirm) |
| 338 | PROGRAM_UNIT | `CHECK_TIMEOUT` | - | - | - | - | DROPPED | NIB wrapper not called by active code (timers, EDI ticker, window, print) |
| 339 | PROGRAM_UNIT | `MOUSE_CLICK` | REGION | FUNCS (page 0) | 0 | - | MAPPED | function list click |
| 340 | PROGRAM_UNIT | `TOGGEL_WND` | - | - | - | - | DROPPED | NIB wrapper not called by active code (timers, EDI ticker, window, print) |
| 341 | PROGRAM_UNIT | `PRINT_REPORT` | - | - | - | - | DROPPED | NIB wrapper not called by active code (timers, EDI ticker, window, print) |
| 342 | PROGRAM_UNIT | `EXECUTE_FUNCTION` | REGION | FUNCS (page 0) | 0 | - | MAPPED | f345 Page Functions -> custom events of the two functions |
| 343 | PROGRAM_UNIT | `TERMINATE_FUN` | - | - | - | - | DROPPED | NIB wrapper not called by active code (timers, EDI ticker, window, print) |
| 344 | PROGRAM_UNIT | `CHECK_EDI_MSG_LOV` | - | - | - | - | DROPPED | NIB wrapper not called by active code (timers, EDI ticker, window, print) |
| 345 | PROGRAM_UNIT | `CHECK_EDI_MSG_TIMER` | - | - | - | - | DROPPED | NIB wrapper not called by active code (timers, EDI ticker, window, print) |
| 346 | PROGRAM_UNIT | `CHECK_EDI_ROLE_ID` | - | - | - | - | DROPPED | NIB wrapper not called by active code (timers, EDI ticker, window, print) |
| 347 | PROGRAM_UNIT | `EDI_MSG_LOV` | - | - | - | - | DROPPED | NIB wrapper not called by active code (timers, EDI ticker, window, print) |
| 348 | PROGRAM_UNIT | `FOR_EDI_MSG` | - | - | - | - | DROPPED | NIB wrapper not called by active code (timers, EDI ticker, window, print) |
| 349 | PROGRAM_UNIT | `RETURN_MSG` | - | - | - | - | DROPPED | NIB wrapper not called by active code (timers, EDI ticker, window, print) |
| 350 | PROGRAM_UNIT | `TURN_MSG` | - | - | - | - | DROPPED | NIB wrapper not called by active code (timers, EDI ticker, window, print) |
| 351 | PROGRAM_UNIT | `WHEN_TIMER_EXPIRED_MSG` | - | - | - | - | DROPPED | NIB wrapper not called by active code (timers, EDI ticker, window, print) |
| 352 | PROGRAM_UNIT | `CG$WHEN_NEW_FORM_INSTANCE` | - | - | - | - | DROPPED | lists -> shared LOV |
| 353 | PROGRAM_UNIT | `CGDV$POPULATE_DYNAMIC_LISTS` | LOV | LOV_ALLOWED_EXPORT (IMPR1110) | 1210 | - | MAPPED | CG_REF_CODES ALLOWED EXPORT on ALLOW_EXPORT, IMPR_EXPR_TYPE, IMPR_EXPR_TYPE_AG |
| 354 | PROGRAM_UNIT | `CGFK$QRY_AGNTS_AG_SDP_FK` | PACKAGE | IMPR1210.POST_QUERY | - | IMPR1210.POST_QUERY | MAPPED | port name |
| 355 | PROGRAM_UNIT | `CGFK$CHK_AGNTS_AG_SDP_FK` | - | - | - | - | DROPPED | not called (PORT_CD is never entered) |
| 356 | PROGRAM_UNIT | `CGFK$QRY_AGNTS_AG_IMP_FK` | PACKAGE | IMPR1210.POST_QUERY | - | IMPR1210.POST_QUERY | MAPPED | importer name / activity |
| 357 | PROGRAM_UNIT | `CGFK$CHK_AGNTS_AG_IMP_FK` | PACKAGE | IMPR1210.IMPR_NBR_WHEN_VALIDATE_ITEM | - | IMPR1210.IMPR_NBR_WHEN_VALIDATE_ITEM | MAPPED | private importer_row |
| 358 | PROGRAM_UNIT | `CGFK$QRY_AGNTS_AG_IMP_AGENT_ID` | PACKAGE | IMPR1210.POST_QUERY | - | IMPR1210.POST_QUERY | MAPPED | broker name / activity |
| 359 | PROGRAM_UNIT | `CGFK$CHK_AGNTS_AG_IMP_AGENT_ID` | PACKAGE | IMPR1210.IMPR_NBR_AG_WHEN_VALIDATE_ITEM | - | IMPR1210.IMPR_NBR_AG_WHEN_VALIDATE_ITEM | MAPPED | private importer_row |
| 360 | PROGRAM_UNIT | `CGTE$CHECK_CONSTRAINT_VIO` | MESSAGE | AG_PK | - | - | MAPPED | ORA-00001 text; SDP_PK / IMP_PK / IMP_BUSID_UK are other tables |
| 361 | PROGRAM_UNIT | `CGNV$AI_CGSO$WINDOW_1_IMP_NEW` | BUTTON | IMP_NEW | 1210 | - | MAPPED | OPEN_FORM IMP_NEW -> page 1130 (to confirm) |
| 362 | PROGRAM_UNIT | `EXEC_FUNS` | PROCESS | CD1_STOPIMPRAUTH / CD2_REUSEIMPRAUTH EXECUTE-FUNCTION | 1210 | IMPR1210.EXEC_FUNS | MAPPED | confirmations = DA Confirm; UPDATE + activity 3 / 4 + COMMIT |
| 363 | PROGRAM_UNIT | `ADJ_FUNS` | - | - | - | - | DROPPED | body NULL; |
| 364 | PROGRAM_UNIT | `CHECK_SUSPENSION` | PACKAGE | IMPR1210 private importer_suspended | - | IMPR1210.IMPR_NBR_VALIDATION | MAPPED | LIB_USR.IMPR.IMPR_SUSPENDED (MISSING SOURCE) -> message 9-70 |
| 365 | LOV | `CGFK$AGNTS_PORT_CD` | - | - | - | - | DROPPED | LOV of PORT_CD, never shown (item not enterable) |
| 366 | RECORD_GROUP | `CGFK$AGNTS_PORT_CD` | - | - | - | - | DROPPED | record group of the PORT_CD LOV |
| 367 | RECORD_GROUP | `CGDV$DLRG (runtime, 3 lists)` | LOV | LOV_ALLOWED_EXPORT (IMPR1110) | 1210 | - | MAPPED | CG_REF_CODES ALLOWED EXPORT |
| 368 | LOV_FORM | `LOV_IMPR` | LOV | LOV_IMPR (IMPR1110, LOV_APX.IMPORTERS) | 1210 | - | MAPPED | IMPR_NBR, IMPR_NBR_AG |
| 369 | LOV_FORM | `LOV_AGNT_ATHR_IMPR` | REGION | LOV_AGNT_ATHR_IMPR (read-only IG) | 1210 | - | MAPPED | authorizations of the importer; rows open the authorization (to confirm, inventory 15 #4) |
| 370 | LOV_FORM | `LOV_SD_PORTS` | - | - | - | - | DROPPED | PORT_CD is never enterable |
| 371 | ALERT | `USR_CONFIRM_B` | DA | Confirm actions of CD1_STOPIMPRAUTH / CD2_REUSEIMPRAUTH EXECUTE-FUNCTION | 1210 | - | MAPPED | STR.DispArbMsg / DispALERT CONFIRM of EXEC_FUNS |
| 372 | ALERT | `USR_CONFIRM` | DA | Confirm actions of CD1_STOPIMPRAUTH / CD2_REUSEIMPRAUTH EXECUTE-FUNCTION | 1210 | - | MAPPED | STR.DispArbMsg / DispALERT CONFIRM of EXEC_FUNS |
| 373 | ALERT | `USR_WARNING_C` | - | - | - | - | DROPPED | OLB alert not used by the business code |
| 374 | ALERT | `USR_WARNING_B` | - | - | - | - | DROPPED | OLB alert not used by the business code |
| 375 | ALERT | `CFG_WARNING_A` | - | - | - | - | DROPPED | OLB alert not used by the business code |
| 376 | ALERT | `CFG_INFORMATION` | APP_ITEM | page messages (validation texts / FORMS_APX.FORM_TRIGGER_FAILURE) | - | - | MAPPED | STR.DispArbMsg ERROR / INFORMATION |
| 377 | ALERT | `CFG_ERROR` | APP_ITEM | page messages (validation texts / FORMS_APX.FORM_TRIGGER_FAILURE) | - | - | MAPPED | STR.DispArbMsg ERROR / INFORMATION |
| 378 | ALERT | `CFG_SYSTEM_ERROR` | - | - | - | - | DROPPED | OLB alert not used by the business code |
| 379 | ALERT | `CFG_ASK_COMMIT` | - | - | - | - | DROPPED | OLB alert not used by the business code |
| 380 | PARAMETER | `P_SHPG_AGNT_NBR` | - | - | - | - | DROPPED | used only by the OLB frame (EXECUTE_FUNCTION parameter list, print, EDI, timers) |
| 381 | PARAMETER | `P_CTRL_LAST_EXEC_CD` | - | - | - | - | DROPPED | used only by the OLB frame (EXECUTE_FUNCTION parameter list, print, EDI, timers) |
| 382 | PARAMETER | `P_BANK_CD` | - | - | - | - | DROPPED | used only by the OLB frame (EXECUTE_FUNCTION parameter list, print, EDI, timers) |
| 383 | PARAMETER | `P_BANK_BRNCH_CD` | - | - | - | - | DROPPED | used only by the OLB frame (EXECUTE_FUNCTION parameter list, print, EDI, timers) |
| 384 | PARAMETER | `P_BRKR_PORT_CD` | - | - | - | - | DROPPED | used only by the OLB frame (EXECUTE_FUNCTION parameter list, print, EDI, timers) |
| 385 | PARAMETER | `P_LIC_TYPE` | - | - | - | - | DROPPED | used only by the OLB frame (EXECUTE_FUNCTION parameter list, print, EDI, timers) |
| 386 | PARAMETER | `P_BRKR_NBR` | - | - | - | - | DROPPED | used only by the OLB frame (EXECUTE_FUNCTION parameter list, print, EDI, timers) |
| 387 | PARAMETER | `P_CLASS_CD` | - | - | - | - | DROPPED | used only by the OLB frame (EXECUTE_FUNCTION parameter list, print, EDI, timers) |
| 388 | PARAMETER | `P_JOB_ID` | - | - | - | - | DROPPED | used only by the OLB frame (EXECUTE_FUNCTION parameter list, print, EDI, timers) |
| 389 | PARAMETER | `P_CURRENT_ITEM` | - | - | - | - | DROPPED | used only by the OLB frame (EXECUTE_FUNCTION parameter list, print, EDI, timers) |
| 390 | PARAMETER | `P_GROUP_CD` | - | - | - | - | DROPPED | used only by the OLB frame (EXECUTE_FUNCTION parameter list, print, EDI, timers) |
| 391 | PARAMETER | `P_USER_TYPE` | - | - | - | - | DROPPED | used only by the OLB frame (EXECUTE_FUNCTION parameter list, print, EDI, timers) |
| 392 | PARAMETER | `P_PORT_TYPE` | - | - | - | - | DROPPED | used only by the OLB frame (EXECUTE_FUNCTION parameter list, print, EDI, timers) |
| 393 | PARAMETER | `P_CURR_PORT_CD` | APP_ITEM | P_CURR_PORT_CD | - | - | MAPPED | f345 application item |
| 394 | PARAMETER | `P_MODULE_ID` | PAGE_ITEM | P1210_MODULE_ID | 1210 | - | MAPPED | FORMS_APX.GET_MODULE_ID |
| 395 | PARAMETER | `P_MODULE_NAME` | - | - | - | - | DROPPED | used only by the OLB frame (EXECUTE_FUNCTION parameter list, print, EDI, timers) |
| 396 | PARAMETER | `P_APPLICATION_NAME` | - | - | - | - | DROPPED | used only by the OLB frame (EXECUTE_FUNCTION parameter list, print, EDI, timers) |
| 397 | PARAMETER | `P_USER_ID` | APP_ITEM | SSO_APP_USER | - | - | MAPPED | f345 application item |
| 398 | PARAMETER | `P_WS_ID` | APP_ITEM | P_GLOBAL_V_WS_ID | - | - | MAPPED | f345 application item |
| 399 | PARAMETER | `P_USER_NAME` | - | - | - | - | DROPPED | used only by the OLB frame (EXECUTE_FUNCTION parameter list, print, EDI, timers) |
| 400 | PARAMETER | `CG$STARTUP_MODE` | - | - | - | - | DROPPED | used only by the OLB frame (EXECUTE_FUNCTION parameter list, print, EDI, timers) |
| 401 | PARAMETER | `P_FUNCTION_CD` | - | - | - | - | DROPPED | not needed: the functions never pass through SAVE |
| 402 | CANVAS | `LSIDE` | - | - | - | - | DROPPED | OLB frame canvas |
| 403 | CANVAS | `EDI_MSG` | - | - | - | - | DROPPED | OLB frame canvas |
| 404 | CANVAS | `TITLE` | - | - | - | - | DROPPED | OLB frame canvas |
| 405 | CANVAS | `TOOLBAR` | - | - | - | - | DROPPED | OLB frame canvas |
| 406 | CANVAS | `CG$PAGE_1` | PAGE | IMPR1210 | 1210 | - | MAPPED | regions AGNTS, LOV_AGNT_ATHR_IMPR, button IMP_NEW |
| 407 | WINDOW | `CGSO$WINDOW_1` | PAGE | IMPR1210 | 1210 | - | MAPPED | one page |
| 408 | LIBRARY | `OFGTEL` | - | - | - | - | DROPPED | frame / client library (windows, timers, help, DLLs) |
| 409 | LIBRARY | `OFGMES` | - | - | - | - | DROPPED | frame / client library (windows, timers, help, DLLs) |
| 410 | LIBRARY | `OFGHPL` | - | - | - | - | DROPPED | frame / client library (windows, timers, help, DLLs) |
| 411 | LIBRARY | `CIC_AMSG` | - | - | - | - | DROPPED | frame / client library (windows, timers, help, DLLs) |
| 412 | LIBRARY | `SEC_LIB` | - | - | - | - | DROPPED | frame / client library (windows, timers, help, DLLs) |
| 413 | LIBRARY | `CAPTION` | - | - | - | - | DROPPED | frame / client library (windows, timers, help, DLLs) |
| 414 | LIBRARY | `OFGBSL` | - | - | - | - | DROPPED | frame / client library (windows, timers, help, DLLs) |
| 415 | LIBRARY | `D2KWUTIL` | - | - | - | - | DROPPED | frame / client library (windows, timers, help, DLLs) |
| 416 | LIBRARY | `CUSTOMDLL` | - | - | - | - | DROPPED | frame / client library (windows, timers, help, DLLs) |
| 417 | LIBRARY | `D2KWUTIL_PDF` | - | - | - | - | DROPPED | frame / client library (windows, timers, help, DLLs) |
| 418 | LIBRARY | `GETCOMP` | - | - | - | - | DROPPED | frame / client library (windows, timers, help, DLLs) |
| 419 | LIBRARY | `OFGTAB` | - | - | - | - | DROPPED | frame / client library (windows, timers, help, DLLs) |
| 420 | LIBRARY | `PICKLIST` | - | - | - | - | DROPPED | frame / client library (windows, timers, help, DLLs) |
| 421 | LIBRARY | `POS` | - | - | - | - | DROPPED | frame / client library (windows, timers, help, DLLs) |
| 422 | LIBRARY | `SCDLL` | - | - | - | - | DROPPED | frame / client library (windows, timers, help, DLLs) |
| 423 | LIBRARY | `VCDLL` | - | - | - | - | DROPPED | frame / client library (windows, timers, help, DLLs) |
| 424 | LIBRARY | `CIC_LIB` | PACKAGE | FORMS_APX / ACTIVITY_DB | - | - | MAPPED | STR -> FORMS_APX, HIJDATE -> FORMS_APX, ACTIVITY -> ACTIVITY_DB, INTRFACE -> AGNTS_IS_READ_ONLY, TMPLT -> FUNCS |
| 425 | GLOBAL | `PORT_CD` | PROCESS | EXECUTE-QUERY (request EXECUTE_QUERY, P0_PAGE_PK) | 1210 | IMPR1210.PRE_QUERY | MAPPED | query key |
| 426 | GLOBAL | `ATHRZTN_SEQ_NBR` | PROCESS | EXECUTE-QUERY (request EXECUTE_QUERY, P0_PAGE_PK) | 1210 | IMPR1210.PRE_QUERY | MAPPED | query key |
| 427 | GLOBAL | `EXEC_QUERY_NOW` | PROCESS | EXECUTE-QUERY (request EXECUTE_QUERY, P0_PAGE_PK) | 1210 | IMPR1210.PRE_QUERY | MAPPED | query key |
| 428 | GLOBAL | `IMPR_NBR_AGENT_ID` | PROCESS | EXECUTE-QUERY (request EXECUTE_QUERY, P0_PAGE_PK) | 1210 | IMPR1210.PRE_QUERY | MAPPED | query key |
| 429 | GLOBAL | `EXEC_QUERY` | - | - | - | - | DROPPED | return values of the LOV forms -> Popup LOV / grid |
| 430 | GLOBAL | `IMPR_NBR` | - | - | - | - | DROPPED | return values of the LOV forms -> Popup LOV / grid |
| 431 | GLOBAL | `IMPR_NAME` | - | - | - | - | DROPPED | return values of the LOV forms -> Popup LOV / grid |
| 432 | GLOBAL | `PORT_NAME` | - | - | - | - | DROPPED | return values of the LOV forms -> Popup LOV / grid |
| 433 | GLOBAL | `CURRENT_VER` | - | - | - | - | DROPPED | versions / help / frame / timers |
| 434 | GLOBAL | `CURRENT_DT` | - | - | - | - | DROPPED | versions / help / frame / timers |
| 435 | GLOBAL | `CURRENT_VERSION` | - | - | - | - | DROPPED | versions / help / frame / timers |
| 436 | GLOBAL | `CG` | - | - | - | - | DROPPED | versions / help / frame / timers |
| 437 | GLOBAL | `EXIT` | - | - | - | - | DROPPED | versions / help / frame / timers |
| 438 | GLOBAL | `G_TIME_OUT` | - | - | - | - | DROPPED | versions / help / frame / timers |
| 439 | GLOBAL | `ITEM_NAME` | - | - | - | - | DROPPED | versions / help / frame / timers |
| 440 | GLOBAL | `SYSTEM_OBJ` | - | - | - | - | DROPPED | versions / help / frame / timers |
| 441 | GLOBAL | `TIMER` | - | - | - | - | DROPPED | versions / help / frame / timers |
| 442 | EXTERNAL | `LIB_USR.IMPR.IMPR_SUSPENDED` | PACKAGE | IMPR1210 importer_suspended | - | IMPR1210.IMPR_NBR_VALIDATION | MAPPED | called unchanged (MISSING SOURCE) |
| 443 | EXTERNAL | `DCLTN.IMPR_IMPR_AUTH_USED` | PACKAGE | IMPR1210 authorization_used | - | IMPR1210.AGNTS_IS_READ_ONLY | MAPPED | called unchanged (MISSING SOURCE) |
| 444 | EXTERNAL | `FORM IMP_NEW` | BUTTON | IMP_NEW -> page 1130 | 1210 | - | TODO | target form to confirm (inventory 15 #5) |
