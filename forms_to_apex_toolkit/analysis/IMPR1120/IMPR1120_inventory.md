# IMPR1120 – Inventory & Migration Risk Assessment

- **Form:** IMPR1120 – "صيانة توقيفات المستوردين" (Importer Suspension Maintenance, Designer function IMPR40000)
- **Source:** `forms/IMPR/IMPR1120_fmb.xml` (frmf2xml output, 717 lines)
- **Target:** Oracle APEX 21.2 on Oracle Database 12.1.0.2, reference application f345 (CLAUDE.md §4b, §4c)
- **Produced:** 2026-11-23 (step 01, revision 1): mechanical sections by `scripts/gen_inv.py`; manual analysis in sections 1, 3–9 notes, 10.3, 10.6–10.8, 11–15 (sources in `work/IMPR1120/inv_man/`).
- **Sources used besides the form XML:** library texts `forms/COMMON/libraries/*.pld` (`CIC_LIB` for NIB, STR, INTRFACE, TMPLT, HIJDATE, ACTIVITY, KEY_CONTROL, REP; `OFGBSL` for the Designer master-detail package `CGBS$`), object library `forms/COMMON/olb/CIC_OLB_OLB.xml`, the LOV forms in `forms/COMMON/lov_forms/`, the launcher `forms/SC/APPS_fmb.xml`, DB packages `plsql/Shared/ACTIVITY_DB.*` and `HIJDATE_DB.*`. The IMPR1110 inventory was used for the shared library and OLB findings; they are repeated here only where IMPR1120 uses them.
- **Scope rule:** anything not available is marked **MISSING SOURCE** and is not guessed: the libraries OFGTEL, SEC_LIB, OFGTAB, PICKLIST, POS, SCDLL, VCDLL, and the DB packages `SMS_MESSAGE`, `LIB_APX_USR.APEX_NOTIFICATIONS`, `GNRL`, `STR_DB`.

## 1. Summary

**Complexity: COMPLEX by the rubric** (driven by Designer and library boilerplate) · **business logic: MEDIUM** · **Effort ESTIMATE: 8–12 developer-days**

### 1.1 Counts

| Object | Count | Notes |
|---|---|---|
| Blocks | 6 | 2 base-table: `IMPORTERS` (master, single record, query only in practice) and `IMPR_SUSPN` (detail, 5 records on `IMPR_SUSPNS`); 4 OLB control blocks (TITLE, EDI_MSG, LSIDE, TOOLBAR) |
| Items | 117 | IMPORTERS 28, IMPR_SUSPN 9, LSIDE 50, TOOLBAR 16, TITLE 12, EDI_MSG 2 |
| Triggers | 269 | Form 33 · Block 17 · Item 219. 104 contain code; 165 have no code in the form XML (inherited from the OLB) |
| Trigger PL/SQL lines | 2,820 total / 1,986 active | about 1,200 active lines are Designer boilerplate (22 copies of the KEY-LISTVAL "may the LOV be shown" check, ON-ERROR, KEY-HELP) |
| Program units | 33 | 1,042 total / 633 active lines. 14 are one-line wrappers of `NIB` and are not called by active code |
| **Total PL/SQL** | **3,862 total / 2,619 active** | Business rules (IMPR_SUSPN triggers, IMPORTERS PRE-QUERY / IMPR_NBR) are about 300 active lines |
| Relations (master–detail) | 1 | `CGFK$IS_1_IMP_FK`: IMPORTERS → IMPR_SUSPN on PORT_CD + IMPR_NBR. Coordination is run by the Designer library `CGBS$` (`OFGBSL.pld`) |
| LOVs / Record groups | 5 / 5 (+1 runtime RG `CGDV$DLRG` for 3 list items) | the LOVs are bypassed: KEY-LISTVAL calls 4 LOV forms (§10.4) |
| Canvases / Windows | 5 / 1 | all business items on `CG$PAGE_1` |
| Alerts | 10 | 9 from the OLB + `CG$ASK_COMMIT` (not referenced) |
| Module parameters | 22 | 20 `P_*` inherited from the OLB, `CG$STARTUP_MODE`, and the form's own **`CURRENT_SIDE`** (no default), which drives most of the business rules |
| Attached libraries | 17 | the same list as IMPR1110 |
| Called forms | 4 static LOV forms + 1 dynamic (`V_CALLED_FORM` in EXECUTE_FUNCTION) + the calendar form behind `INTRFACE.DISP_CALENDAR` | |
| :GLOBAL / :SYSTEM variables | 17 / 13 | |
| Visual attributes | 51 | OLB |
| Subclassed (OLB) objects | 161 | VA 51, items 37, triggers 24, parameters 20, alerts 9, blocks 6, canvases 5, LOVs 5, graphics 2, window 1, report 1 |

### 1.2 Complexity rubric

| Metric | Value | Simple | Medium | Complex | Category |
|---|---|---|---|---|---|
| Data blocks | 2 base-table (6 with the control blocks) | 1–2 | 3–5 | > 5 | Simple |
| Triggers (total) | 269 | < 15 | 15–50 | > 50 | **Complex** |
| Lines of PL/SQL (triggers + PUs) | 3,862 (2,619 active) | < 300 | 300–1500 | > 1500 | **Complex** |
| Master–detail relations | 1 | 0–1 | 2–3 | > 3 | Simple |
| Called forms / libraries | 5 forms + 17 libraries | 0 | 1–3 | > 3 | **Complex** |
| Special features | SMS / notification send, RUN_PRODUCT (EXECUTE_FUNCTION), timers (NIB), TEXT_IO (unused PU) | none | 1 | ≥ 2 | **Complex** |

**Result: COMPLEX** (4 metrics reach Complex).

**Justification.** The rubric is driven by size, and most of that size is generated code: Designer lookup and error procedures, 22 copies of the same KEY-LISTVAL check, and the OLB frame, which the f345 shell replaces. The real work is one master-detail page: a query-only importer header and an editable grid of suspensions. The grid rules are driven by the `CURRENT_SIDE` parameter (who may add which reason and side, which rows are skipped). It also has a soft delete, a `MAX+1` key, and an SMS / notification sent with a COMMIT inside POST-INSERT.

**Effort ESTIMATE: 8–12 developer-days** for the main page (Form + IG), the search page, the shared LOVs, package `IMPR1120` (side rules, validations, soft delete, key, notification, activity log), security mapping and testing. Not included: the DB packages without source (`SMS_MESSAGE`, `APEX_NOTIFICATIONS`, `GNRL`), any reports reached through EXECUTE_FUNCTION, and IMPR1125 if it turns out to be a variant of this screen (§15 #2).

## 2. Module header

| Property | Value |
|---|---|
| Form name | IMPR1120 |
| Title | صيانة توقيفات المستوردين |
| First navigation block | IMPORTERS |
| Console window | CGSO$WINDOW_1 |
| Menu module (MenuModule) | CIC_MENU |
| Initial menu | (empty) |
| Validation unit | Item |
| Interaction mode | not in XML → Forms default (Blocking) |
| Language direction | Right To Left |
| Runtime compatibility | 5.0 |
| Coordinate system | Real / unit Inch / char cell 100x200 |

Module comment (decoded, verbatim):

```text
*******************************************************************

FORMS MODULE NAME
  IMPR1120

MODIFIED
  APPDEV248       19/08/26  11:28 created by Form Generator for
                                  Form Builder Version 6.0.3.11.0

Repository APPLICATION SYSTEM
  IMPORTERS Version 1

PURPOSE
  توقيفات المستوردين (الرقابة والحاسب

MODULE DESCRIPTION
.
The deletion process is some kind of soft delete, i.e. there is a field called SUSPN_RLSE_DT used to determine the date at which this suspension was inactivated (deleted.)
The SUSPN_STRT_DT take a value greater than or equal the current data.
SUSPN_SIDE_CD take one of the following according to the current site using the module:
{ "التدقيق والفرو قات", 1 },
{ "الرقابة الجمركية", 2 },
{ "الحاسب الآلي", 3 },
{ "المدير العام", 4 },

There are two sites whose can use this module,The first site can add and modify any suspension of cause-type (field SUSPN_RSN_CD): { "فروق مالية", 1 }, and site of type (SUSPN_SIDE_CD) { "التدقيق والفرو قات", 1 }.
The Second site can add and modify any suspension of cause-type (field SUSPN_RSN_CD): { "استكمال أوراق", 2 }, { "أخري", 3 }, And Site of type (SUSPN_SIDE_CD) { "الرقابة الجمركية", 2 },{ "الحاسب الآلي", 3 },{ "المدير العام", 4 }. If
  the s
uspesion cause-type was {"أخري", 3 } then the user can change the text ' أخري' to be any descriptive reason with the same code 3, so that the field SUSPN_RSN_TEXT is used to hold the meaning of the field SUSPN_RSN_CD.
There is no any restriction about the suspension intervals overlapping. Only the start date (SUSPN_STRT_DT) must be greater or equal to the current date.


MODULE NOTES
Developed by Application Design Transformer from Function IMPR40000
Candidate Module because it is an elementary Function
Identified as a screen because not overnight and not retrieval only
.
.


BUSINESS FUNCTIONS IMPLEMENTED
  IMPR1120
  Importer Suspension
  Maintenance
  IMPR1120

TABLE USAGES
  BASE   IMPORTERS                     SEL INS
  BASE   IMPR_SUSPNS                   SEL INS UPD DEL

WARNINGS - 19/08/26  11:28
  01280: display length = 30, item length = 20;
  01001: No PL/SQL block text for button item  IMPORTERS.BUTT;
         Button has no functionality.
  01474: Combo-box list style invalid
  01474: Combo-box list style invalid
  01139: No validation generated on partially specified foreign key
         IMPORTERS.IMP_IMP_FK
  01316: Foreign key constraint IMP_HI_FK in IMPORTERS has no
         enterable items or lookups

*******************************************************************
```

> Notes: generated by **Oracle Designer Form Generator 6.0.3.11** (APPDEV248, 19/08/26) from Designer function IMPR40000, then hand-modified ("UPDATE BY ANAS 9-5-2005", "ADDED BY ABDALLAH", CR-8414 notification). The module comment states the business rules: delete is a soft delete through `SUSPN_RLSE_DT`; `SUSPN_STRT_DT` must be ≥ today; the allowed reasons and sides depend on the site using the screen (`CURRENT_SIDE`); overlapping suspension periods are allowed. The comment lists sides 1–4 and reasons 1–3; the XML list values and the code use more (reasons 1–6, sides 1–7, side 5 for HQ port 99), so the comment is out of date. Designer warnings: `IMPORTERS.BUTT` has no PL/SQL (code was added later), two combo-box list styles are invalid, and FK `IMP_HI_FK` has no enterable items.

## 3. Blocks

> Properties absent from the XML are Forms defaults **or inherited from the object library** (`ParentModule`/`ParentName`); such values are shown as `default/OLB` (OLB properties: `forms/COMMON/olb/CIC_OLB_OLB.xml`).

| Block | Base table / Query data source | DML target | Type | Records displayed | Records buffered | WHERE clause | ORDER BY | Insert | Update | Delete | Query | Canvas(es) | Subclassed from |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| TITLE | – | – | control (non-DB) | default/OLB | default/OLB | – | – | default/OLB | default/OLB | default/OLB | default/OLB | – | CIC_OLB.olb:TITLE |
| EDI_MSG | – | – | control (non-DB) | default/OLB | default/OLB | – | – | default/OLB | default/OLB | default/OLB | default/OLB | – | CIC_OLB.olb:EDI_MSG |
| LSIDE | – | – | control (non-DB) | default/OLB | default/OLB | – | – | default/OLB | default/OLB | default/OLB | default/OLB | – | CIC_OLB.olb:LSIDE |
| TOOLBAR | – | – | control (non-DB) | default/OLB | default/OLB | – | – | default/OLB | default/OLB | default/OLB | default/OLB | – | CIC_OLB.olb:TOOLBAR |
| IMPORTERS | IMPORTERS | same as query source (default) | base-table | default/OLB | 4 | – | order by port_cd desc | default/OLB | false | false | default/OLB | CG$PAGE_1 | cic_olb.olb:CGSO$BLOCK |
| IMPR_SUSPN | IMPR_SUSPNS | same as query source (default) | base-table | 5 | 8 | WHERE   ( IMPR_SUSPNS.SUSPN_RLSE_DT IS NULL ) | – | default/OLB | default/OLB | default/OLB | default/OLB | CG$PAGE_1 | cic_olb.olb:CGSO$BLOCK_MR |

Block `IMPORTERS` comment (decoded):

```text
*******************************************************************

BLOCK NAME
  IMPORTERS

TABLE COMMENT
  جدول المستوردين

TABLE USAGE COMMENT
  Autogenerated by App Des Transformer.

TABLE USAGES
  BASE   IMPORTERS                     SEL INS
  ...    PORT_CD                       SEL
  ...    HQ_IMPR_NBR                   SEL         NUL
  ...    IMPR_NBR                      SEL INS
  ...    IMPR_TYPE_CD                  SEL INS
  ...    CTRY_CD                       SEL
  ...    CITY_CODE_OF_ID               SEL
  ...    IMPR_EXPR_TYPE                SEL
  ...    BUS_ID                        SEL
  ...    BUS_ID_TYPE_CD                SEL
  ...    BUS_ID_BRNCH                  SEL
  ...    ARBC_IMPR_NAME                SEL
  ...    ENG_IMPR_NAME                 SEL
  ...    IMPR_CNTCT_NAME               SEL INS     NUL
  ...    IMPR_NAME_STD                 SEL
  ...    CTRY_CD_OF_ID                 SEL INS     NUL

TUI DESCRIPTION


*******************************************************************
```

Block `IMPR_SUSPN` comment (decoded):

```text
*******************************************************************

BLOCK NAME
  IMPR_SUSPN

TABLE COMMENT


TABLE USAGE COMMENT
  Autogenerated by App Des Transformer.

TABLE USAGES
  BASE   IMPR_SUSPNS                   SEL INS UPD DEL
  ...    SUSPN_STRT_DT                 SEL INS UPD
  ...    SUSPN_END_DT                  SEL INS UPD
  ...    SUSPN_SEQ                     SEL INS
  ...    SUSPN_RSN_CD                  SEL INS UPD NUL
  ...    SUSPN_RSN_TEXT                SEL INS UPD
  ...    SUSPN_SIDE_CD                 SEL INS UPD NUL
  ...    SUSPN_RLSE_DT                 SEL INS UPD NUL
  ...    IMPR_NBR                      SEL INS
  ...    PORT_CD                       SEL INS

JOIN CONDITION
  IMPR_SUSPN.IMPR_NBR = IMPORTERS.IMPR_NBR
  IMPR_SUSPN.PORT_CD = IMPORTERS.PORT_CD

TUI DESCRIPTION


*******************************************************************
```

> **Block notes**
> - `TITLE`, `EDI_MSG`, `LSIDE`, `TOOLBAR` are OLB control blocks (screen frame). They are replaced by the f345 page template, the page 0 toolbar and the `FUNCS` region.
> - `IMPORTERS` (master) has `UpdateAllowed=false`, `DeleteAllowed=false`, and Insert / Query at the default (true). Almost all items are `InsertAllowed=false`. In practice the block is a **search header**: the user types `IMPR_NBR` in the new record, `IMPR_NBR.WHEN-VALIDATE-ITEM` checks that the importer exists in the current port and sets `:GLOBAL.Exec_Query_Now := 1`, and `IMPR_TYPE_CD.WHEN-NEW-ITEM-INSTANCE` then runs `CLEAR_BLOCK` + `EXECUTE_QUERY`. Whether an importer may ever be inserted here is open (§15 #6).
> - `IMPORTERS` has `ORDER BY port_cd desc`. PRE-QUERY forces `PORT_CD := P_CURR_PORT_CD` unless the port is 99 (head office), converts the Arabic name criterion to `IMPR_NAME_STD := STR.StrFormat(ARBC_IMPR_NAME, TRUE)`, and adds a sub-query on `SD_PORTS` for a `PORT_NAME` criterion (Designer `CGFK$DEFAULT_WHERE`, built by string concatenation).
> - `IMPR_SUSPN` (detail, 5 rows shown, 8 buffered) has `WHERE IMPR_SUSPNS.SUSPN_RLSE_DT IS NULL`, so only active suspensions are shown. `IMPR_NBR` / `PORT_CD` are copied from the master (`CopyValueFromItem`).
> - Delete on `IMPR_SUSPN` is a **soft delete**: `KEY-DELREC` → `TMPLT.KEY_DELETE_RECORD` (WARNING confirm, `Delete_record`, `COMMIT`, and only when the toolbar `REMOVE` button is visible and enabled); `ON-DELETE` replaces the DELETE with `UPDATE IMPR_SUSPNS SET SUSPN_RLSE_DT = HIJDATE.CUR_HIJ_DATE` + activity log.

## 4. Items

> Legend: `–` = attribute not present in the XML (Forms default or inherited from the OLB property class named in "Subclass"). ItemType `–` therefore normally means *Text Item* unless the OLB class says otherwise (e.g. `CGSO$LOV_BUT` = button, `*_DO` = display-only text item).

### 4.1 Block `TITLE` (12 items)

| # | Item | Item type | Subclass (OLB) | Data type | Max len | Column name | DB item | Required | LOV | Default value | Format mask | Canvas / tab page | Visible | Insert / Update / Query allowed | Prompt / label | Copy-value-from / calc | List values / hint |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | CGSO$CHECK_BOX_U | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| 2 | CGSO$CHAR_ARB_ED | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| 3 | CGSO$CHAR_ARB_DO_MLINE | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| 4 | CGSO$CHAR_ARB_ORA_LOV | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| 5 | CGSO$CHAR_ARB_DO_ENB_Y | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| 6 | CGSO$CHAR_ARB_MLINE | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| 7 | CGSO$CHAR_ARB | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| 8 | CGSO$CHAR_ARB_DO | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| 9 | SCREEN_NAME | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| 10 | USER_NAME | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| 11 | SYSTEM_DATE | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| 12 | VERSION | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – |

### 4.2 Block `EDI_MSG` (2 items)

| # | Item | Item type | Subclass (OLB) | Data type | Max len | Column name | DB item | Required | LOV | Default value | Format mask | Canvas / tab page | Visible | Insert / Update / Query allowed | Prompt / label | Copy-value-from / calc | List values / hint |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | EDI_MSG_TXT | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| 2 | EDI_MSG_LOVE_BUT | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – |

### 4.3 Block `LSIDE` (50 items)

| # | Item | Item type | Subclass (OLB) | Data type | Max len | Column name | DB item | Required | LOV | Default value | Format mask | Canvas / tab page | Visible | Insert / Update / Query allowed | Prompt / label | Copy-value-from / calc | List values / hint |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | FN1 | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| 2 | FN50 | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| 3 | FN2 | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| 4 | FN49 | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| 5 | FN3 | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| 6 | FN48 | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| 7 | FN4 | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| 8 | FN47 | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| 9 | FN5 | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| 10 | FN46 | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| 11 | FN6 | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| 12 | FN45 | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| 13 | FN7 | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| 14 | FN44 | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| 15 | FN8 | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| 16 | FN43 | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| 17 | FN9 | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| 18 | FN42 | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| 19 | FN10 | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| 20 | FN41 | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| 21 | FN11 | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| 22 | FN40 | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| 23 | FN12 | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| 24 | FN39 | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| 25 | FN13 | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| 26 | FN38 | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| 27 | FN14 | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| 28 | FN37 | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| 29 | FN15 | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| 30 | FN36 | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| 31 | FN16 | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| 32 | FN17 | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| 33 | FN34 | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| 34 | FN35 | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| 35 | FN18 | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| 36 | FN33 | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| 37 | FN19 | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| 38 | FN32 | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| 39 | FN20 | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| 40 | FN31 | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| 41 | FN21 | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| 42 | FN30 | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| 43 | FN22 | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| 44 | FN29 | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| 45 | FN23 | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| 46 | FN28 | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| 47 | FN24 | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| 48 | FN27 | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| 49 | FN25 | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| 50 | FN26 | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – |

### 4.4 Block `TOOLBAR` (16 items)

| # | Item | Item type | Subclass (OLB) | Data type | Max len | Column name | DB item | Required | LOV | Default value | Format mask | Canvas / tab page | Visible | Insert / Update / Query allowed | Prompt / label | Copy-value-from / calc | List values / hint |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | DUMMY | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| 2 | SAVE | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| 3 | CLEAR_ALL | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| 4 | EXIT | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| 5 | EXIT1 | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| 6 | ENTER | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| 7 | EXECUTE | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| 8 | REMOVE | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| 9 | LIST_VALUE | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| 10 | HELP | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| 11 | LAST_REC | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| 12 | RE_ENTER_QUERY | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| 13 | FIRST_REC | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| 14 | PAGE_UP | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| 15 | PAGE_DOWN | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| 16 | FUN_BUT | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – | – |

### 4.5 Block `IMPORTERS` (28 items)

| # | Item | Item type | Subclass (OLB) | Data type | Max len | Column name | DB item | Required | LOV | Default value | Format mask | Canvas / tab page | Visible | Insert / Update / Query allowed | Prompt / label | Copy-value-from / calc | List values / hint |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | PORT_CD | – | CGSO$CHAR_ARB | Number | 4 | PORT_CD | – | true | CGFK$IMPORTERS_PORT_CD | – | – | CG$PAGE_1 | – | false/false/· | رمز الجمــــــــــــــرك | – | رمز الجمرك للمستورد - list of values available |
| 2 | PORT_CD2 | – | CGSO$LOV_BUT | – | – | – | – | – | – | – | – | CG$PAGE_1 | – | – | – | – | – |
| 3 | PORT_NAME | – | CGSO$CHAR_ARB_DO | – | 40 | – | false | false | – | – | – | CG$PAGE_1 | – | ·/·/true | – | – | اسم الميناء العربي |
| 4 | HQ_IMPR_NBR | – | CGSO$CHAR_ARB_DO | Number | 11 | HQ_IMPR_NBR | – | – | CGFK$IMPORTERS_HQ_IMPR_NBR | – | – | CG$PAGE_1 | – | ·/·/true | الرقم الموحد بالمصلحة | – | Enter value for الرقم الموحد بالمصلحة - list of values available |
| 5 | IMPR_NBR | – | CGSO$CHAR_ARB | Number | 11 | IMPR_NBR | – | true | – | – | – | CG$PAGE_1 | – | ·/false/· | الرقــــــم الجمركــــى | – | مسلسل المستورد |
| 6 | SDP_PORT_STATUS | – | CGSO$NUMBER_MD | – | 2 | – | false | false | – | 1 | – | – | false | false/false/false | الحالة | – | – |
| 7 | IMPR_TYPE_CD | – | CGSO$CHAR_ARB | Number | 4 | IMPR_TYPE_CD | – | true | CGFK$IMPORTERS_IMPR_TYPE_CD | – | – | CG$PAGE_1 | – | ·/false/· | رمز النشاط التجارى | – | رمز النشاط التجارى - list of values available |
| 8 | IMPR_TYPE_CD2 | – | CGSO$LOV_BUT | – | – | – | – | – | – | – | – | CG$PAGE_1 | – | – | – | – | – |
| 9 | IMPR_TYPE_NAME | – | CGSO$CHAR_ARB_DO | – | 40 | – | false | false | – | – | – | CG$PAGE_1 | – | – | – | – | مسمي نوع المستورد |
| 10 | CTRY_CD | – | CGSO$CHAR_ARB | Number | 4 | CTRY_CD | – | true | CGFK$IMPORTERS_CTRY_CD | – | – | CG$PAGE_1 | – | false/false/· | الجنسيــــــــــــــــــــه | – | رمز الدولة - list of values available |
| 11 | CTRY_CD2 | – | CGSO$LOV_BUT | – | – | – | – | – | – | – | – | CG$PAGE_1 | – | – | – | – | – |
| 12 | CRTY_ARBC_NAME | – | CGSO$CHAR_ARB_DO | – | 50 | – | false | false | – | – | – | CG$PAGE_1 | – | – | – | – | اسم الدولة عربي |
| 13 | CITY_CODE_OF_ID | – | CGSO$CHAR_ARB | Number | 4 | CITY_CODE_OF_ID | – | false | CGFK$IMPORTERS_CITY_CODE_OF_ID | – | – | CG$PAGE_1 | – | false/false/· | مصدر الرقم الإستدلالي | – | رمز المدينة السعودية - list of values available |
| 14 | CITY_CODE_OF_ID2 | – | CGSO$LOV_BUT | – | – | – | – | – | – | – | – | CG$PAGE_1 | – | – | – | – | – |
| 15 | ID_CITY_NAME | – | CGSO$CHAR_ARB_DO | – | 20 | – | false | false | – | – | – | CG$PAGE_1 | – | – | – | – | مسمى الدولة العربي |
| 16 | IMPR_EXPR_TYPE | – | CGSO$POP_DO | Number | 2 | IMPR_EXPR_TYPE | – | false | – | 0 | – | CG$PAGE_1 | – | – | النشاط الجمركي | – | 0=تصدير; 1=إستيراد; 2=إستيراد-تصدير |
| 17 | BUS_ID | – | CGSO$CHAR_ARB | – | 15 | BUS_ID | – | false | – | – | – | CG$PAGE_1 | – | false/false/· | الرقم الاستدلالـــــــى | – | الرقم الاستدلالى للمستورد الرئيسى |
| 18 | BUS_ID_TYPE_CD | – | CGSO$CHAR_ARB | Number | 4 | BUS_ID_TYPE_CD | – | false | – | – | – | CG$PAGE_1 | – | false/false/· | نوعه | – | رمز نوع الرقم  الاستدلالى |
| 19 | BUTT | – | CGSO$LOV_BUT | – | 2 | – | false | true | – | – | – | CG$PAGE_1 | – | – | – | – | – |
| 20 | BUS_ID_TYPE_NAME | – | CGSO$CHAR_ARB_DO | – | 40 | – | false | false | – | – | – | CG$PAGE_1 | – | – | – | – | مسمى  نوع الرقم الاستدلالى |
| 21 | BUS_ID_BRNCH | – | CGSO$CHAR_ARB | – | 10 | BUS_ID_BRNCH | – | false | – | – | – | CG$PAGE_1 | – | false/false/· | الفرع | – | رقم الفرع التابع للمستورد الرئيسى |
| 22 | CTRY_CTRY_STATUS | – | CGSO$NUMBER_MD | – | 2 | – | false | false | – | 1 | – | – | false | false/false/false | Ctry Status | – | – |
| 23 | STATUS | – | CGSO$CHECK_BOX_MD | Number | 2 | – | false | false | – | 1 | – | – | false | false/false/false | حالة سجل - نشط أو غير نشط | – | checked=1 unchecked=0 |
| 24 | ARBC_IMPR_NAME | – | CGSO$CHAR_ARB | – | – | ARBC_IMPR_NAME | – | false | – | – | – | CG$PAGE_1 | – | false/false/· | الاســــم العربــــــــى | – | اسم المستورد |
| 25 | ENG_IMPR_NAME | – | CGSO$CHAR_EN | – | – | ENG_IMPR_NAME | – | false | – | – | – | CG$PAGE_1 | – | false/false/· | الاســــم الأجنبـــــــي | – | الاسم الأجنبى للمستورد |
| 26 | IMPR_CNTCT_NAME | – | CGSO$CHAR_ARB | – | – | IMPR_CNTCT_NAME | – | – | – | – | – | CG$PAGE_1 | – | ·/false/· | الوكيـــل المفــــوض | – | اسم الوكيل المفوض |
| 27 | IMPR_NAME_STD | – | CGSO$CHAR_MD | – | 200 | IMPR_NAME_STD | – | false | – | – | – | – | false | false/false/false | Impr Name Std | – | اسم المستورد القياسى-للبحث |
| 28 | CTRY_CD_OF_ID | – | CGSO$NUMBER | – | 4 | CTRY_CD_OF_ID | – | – | – | 100 | – | – | false | false/false/false | Ct Ctry Cd2 | – | – |

### 4.6 Block `IMPR_SUSPN` (9 items)

| # | Item | Item type | Subclass (OLB) | Data type | Max len | Column name | DB item | Required | LOV | Default value | Format mask | Canvas / tab page | Visible | Insert / Update / Query allowed | Prompt / label | Copy-value-from / calc | List values / hint |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | SUSPN_STRT_DT | – | CGSO$HDATE_ARB | – | – | SUSPN_STRT_DT | – | true | – | – | – | CG$PAGE_1 | – | – | بداية الإيقاف | – | تاريخ بدايه التوقيف |
| 2 | SUSPN_END_DT | – | CGSO$HDATE_ARB | – | – | SUSPN_END_DT | – | true | – | – | – | CG$PAGE_1 | – | – | نهاية الإيقاف | – | تاريخ نهايه التوقيف |
| 3 | SUSPN_SEQ | – | CGSO$NUMBER_MR_MD | – | 11 | SUSPN_SEQ | – | false | – | – | – | – | false | false/false/false | Suspn Seq | – | مسلسل التوقيف |
| 4 | SUSPN_RSN_CD | List Item | CGSO$CHAR_ARB | Number | – | SUSPN_RSN_CD | – | – | – | – | – | CG$PAGE_1 | – | – | السبب | – | 1=فروق مالية; 2=استكمال أوراق; 3=أخري; 4=السجل التجاري مشطوب بوزارة التجارة; 5=غرامات بوحدة الغرامات بالمصلحة ولم تسدد; 6=رقم الهوية أو رقم الاقامة غير صحيح |
| 5 | SUSPN_RSN_TEXT | – | CGSO$CHAR_ARB | – | 100 | SUSPN_RSN_TEXT | – | true | – | – | – | CG$PAGE_1 | – | – | ملاحظات | – | توصيف سبب التوقيف |
| 6 | SUSPN_SIDE_CD | – | CGSO$POP_MR | Number | – | SUSPN_SIDE_CD | – | – | – | – | – | CG$PAGE_1 | – | – | الجهة | – | 1=التدقيق والفرو قات; 2=الرقابة الجمركيه; 3=الحاسب الألي; 4=المدير العام; 5=هيئة الزكاة و الضريبة و الجمارك  - إدارة القيود; 6=وزارة التجارة; 7=وحدة الغرامات - هيئة الزكاة و الضريبة و الجمارك |
| 7 | SUSPN_RLSE_DT | – | CGSO$HDATE_ARB | – | – | SUSPN_RLSE_DT | – | – | – | – | – | – | false | false/false/false | Suspn Rlse Dt | – | تاريخ حذف التوقيف |
| 8 | IMPR_NBR | – | CGSO$NUMBER_MR_MD | – | 11 | IMPR_NBR | – | false | – | – | – | – | false | false/false/false | Impr Nbr | IMPORTERS.IMPR_NBR | مسلسل المستورد |
| 9 | PORT_CD | – | CGSO$NUMBER_MR_MD | – | 4 | PORT_CD | – | false | – | – | – | – | false | false/false/false | Port Cd | IMPORTERS.PORT_CD | رمز الجمرك |

> **Item notes**
> - Items of the 4 OLB control blocks have no attributes in the form XML; they come from `CIC_OLB_OLB.xml` and are not migrated.
> - `IMPORTERS` items are display / query criteria (`Insert/Update allowed = false`); `*_NAME` items are filled by the POST-QUERY lookups (Designer `CGFK$QRY_*`). `PORT_CD2`, `IMPR_TYPE_CD2`, `CTRY_CD2`, `CITY_CODE_OF_ID2`, `BUTT` are LOV buttons (`GO_ITEM` + `DO_KEY('LIST_VALUES')`).
> - `IMPORTERS.IMPR_EXPR_TYPE`, `IMPR_SUSPN.SUSPN_RSN_CD` and `IMPR_SUSPN.SUSPN_SIDE_CD` are list items. The static values in the XML are overwritten at startup by `CGDV$POPULATE_DYNAMIC_LISTS` from `CG_REF_CODES` (domains `ALLOWED EXPORT`, `IMPR_SUSPN_RSN_CD`, `SUSPN SIDE CD`).
> - `SUSPN_STRT_DT`, `SUSPN_END_DT`, `SUSPN_RLSE_DT` are Hijri dates (OLB class `CGSO$HDATE_ARB`), validated by `HIJDATE.VALID_HIJ_DATE` (→ `HIJDATE_DB`), with a calendar on KEY-LISTVAL (`INTRFACE.DISP_CALENDAR`) and KEY-F4 (`INTRFACE.DISP_DATE_CON`).
> - `SUSPN_SEQ`, `SUSPN_RLSE_DT`, `IMPR_NBR`, `PORT_CD` of `IMPR_SUSPN` are hidden. `SUSPN_SEQ` is set in PRE-INSERT (`MAX(SUSPN_SEQ)+1` over the **whole** table) and `SUSPN_RLSE_DT` in PRE-UPDATE / ON-DELETE.
> - Item rules by `:PARAMETER.CURRENT_SIDE` (with `P_CURR_PORT_CD` = 99 or not):
>
> | CURRENT_SIDE / port | Default `SUSPN_RSN_CD` (WNII) | Rejected `SUSPN_RSN_CD` (WVI) | Default `SUSPN_SIDE_CD` (WNII) | Rejected `SUSPN_SIDE_CD` (WLC) | Rows skipped (WNRI `NEXT_RECORD`) |
> |---|---|---|---|---|---|
> | 1, port ≠ 99 | 1 | 2 → reset to 1 | 1 | ≠ 1 → reset to 1 | side ≠ 1 |
> | 2, port ≠ 99 | 2 | 1 → reset to 2 | 2 | 1 or 5 → reset to 2 | side 1 or 5 |
> | 3, port = 99 | 3 | 1, 2 → reset to 3 | 5 | ≠ 5 → reset to 5 | side ≠ 5 |
> | 3, port ≠ 99 | – | 1, 2 → reset to 3 | – | – | – (WNFI exits the form: "ليس لديك الصلاحية للدخول على الشاشة") |
>
> The rejections raise `FORM_TRIGGER_FAILURE` **without a message**. `SUSPN_RSN_CD.WHEN-VALIDATE-ITEM` then copies the `CG_REF_CODES` meaning into `SUSPN_RSN_TEXT` (the user may change it).
> - `SUSPN_SIDE_CD` is enabled only while it is empty (new row); once set (POST-QUERY, POST-INSERT, WNRI) it is disabled.

## 5. Relations (master–detail)

| Relation | Master block | Detail block | Join condition | Delete behaviour | Deferred / Auto-query | Prevent masterless operations | Subclassed from |
|---|---|---|---|---|---|---|---|
| CGFK$IS_1_IMP_FK | IMPORTERS | IMPR_SUSPN | IMPORTERS.PORT_CD = IMPR_SUSPN.PORT_CD AND     IMPORTERS.IMPR_NBR = IMPR_SUSPN.IMPR_NBR | not in XML → Forms default (Non-Isolated) | default (false)/default (false) | true | – |

## 6. Triggers

> **Trigger notes**
> - 269 triggers: Form 33, Block 17, Item 219. 104 contain code in the form XML; the 165 without code are inherited from `CIC_OLB_OLB.xml` (LSIDE 150 mouse triggers, TOOLBAR 13 buttons, TITLE 5 / EDI_MSG 1 item triggers, form KEY-F4). This is the standard screen frame, as in IMPR1110.
> - Form-level triggers are either `NIB.*` delegations (`CIC_LIB.pld`), Designer block-synchronisation (`CGBS$` / `CGBS2$` in `OFGBSL.pld`: ON-POPULATE-DETAILS, ON-CLEAR-DETAILS, WHEN-NEW-BLOCK-INSTANCE, KEY-CQUERY, KEY-CLRREC, KEY-MENU), or Designer help / messages (`CGHP$`, `DES$FORM_ERRORS`). The business code at form level is in WHEN-NEW-FORM-INSTANCE (port 99 may edit `PORT_CD`; `CURRENT_SIDE = 3` outside port 99 exits the form).
> - All 20 KEY-LISTVAL triggers on IMPORTERS items (and 2 on IMPR_SUSPN) start with the same 32-line Designer check (`CGAP$OLES_SEQUENCE_BEFORE`: is the item insertable / updatable / queryable now). Only 4 then call an LOV form (PORT_CD, IMPR_TYPE_CD, CTRY_CD, CITY_CODE_OF_ID). In APEX the check becomes the item's read-only state.
> - The business rules are in the `IMPR_SUSPN` block triggers (PRE-INSERT, PRE-UPDATE, ON-DELETE, POST-INSERT, WHEN-NEW-RECORD-INSTANCE, POST-QUERY) and its item triggers; see the rule table in §4 notes and the risks in §14.

### 6.0 Trigger index

| # | Level | Owner | Trigger | Lines (total / active) | Exec. hierarchy | Source | Program units called |
|---|---|---|---|---|---|---|---|
| 1 | Form | FORM | KEY-EDIT | 21 / 1 | default (Override) | XML | – |
| 2 | Form | FORM | KEY-DUPREC | 10 / 1 | default (Override) | XML | – |
| 3 | Form | FORM | PRE-FORM | 36 / 10 | default (Override) | XML | – |
| 4 | Form | FORM | WHEN-NEW-FORM-INSTANCE | 173 / 31 | default (Override) | XML | CG$WHEN_NEW_FORM_INSTANCE |
| 5 | Form | FORM | WHEN-WINDOW-ACTIVATED | 29 / 1 | default (Override) | XML | – |
| 6 | Form | FORM | KEY-ENTQRY | 49 / 4 | default (Override) | XML | – |
| 7 | Form | FORM | ON-ERROR | 39 / 1 | default (Override) | XML | – |
| 8 | Form | FORM | ON-MESSAGE | 34 / 1 | default (Override) | XML | – |
| 9 | Form | FORM | KEY-CLRBLK | 22 / 4 | default (Override) | XML | – |
| 10 | Form | FORM | KEY-DELREC | 25 / 1 | default (Override) | XML | – |
| 11 | Form | FORM | KEY-F5 | 22 / 1 | default (Override) | XML | – |
| 12 | Form | FORM | KEY-F4 | 0 / 0 | default (Override) | OLB code (26 lines): `IF :SYSTEM.MODE <> 'ENTER-QUERY' THEN` | – |
| 13 | Form | FORM | KEY-NXTREC | 15 / 1 | default (Override) | XML | – |
| 14 | Form | FORM | KEY-PRVREC | 13 / 1 | default (Override) | XML | – |
| 15 | Form | FORM | KEY-DOWN | 17 / 1 | default (Override) | XML | – |
| 16 | Form | FORM | KEY-UP | 3 / 1 | default (Override) | XML | – |
| 17 | Form | FORM | KEY-SCRUP | 3 / 1 | default (Override) | XML | – |
| 18 | Form | FORM | KEY-SCRDOWN | 3 / 1 | default (Override) | XML | – |
| 19 | Form | FORM | KEY-PRINT | 13 / 1 | default (Override) | XML | – |
| 20 | Form | FORM | KEY-EXIT | 50 / 1 | default (Override) | XML | – |
| 21 | Form | FORM | WHEN-MOUSE-DOWN | 3 / 1 | default (Override) | XML | – |
| 22 | Form | FORM | KEY-EXEQRY | 17 / 4 | default (Override) | XML | – |
| 23 | Form | FORM | KEY-F9 | 26 / 23 | default (Override) | XML | ADJ_FUNS |
| 24 | Form | FORM | WHEN-TIMER-EXPIRED | 48 / 1 | default (Override) | XML | – |
| 25 | Form | FORM | KEY-HELP | 18 / 16 | default (Override) | XML | – |
| 26 | Form | FORM | WHEN-NEW-BLOCK-INSTANCE | 5 / 3 | default (Override) | XML | – |
| 27 | Form | FORM | ON-CLEAR-DETAILS | 10 / 8 | default (Override) | XML | – |
| 28 | Form | FORM | ON-POPULATE-DETAILS | 5 / 3 | default (Override) | XML | – |
| 29 | Form | FORM | KEY-CQUERY | 9 / 7 | default (Override) | XML | – |
| 30 | Form | FORM | KEY-CLRREC | 11 / 9 | default (Override) | XML | – |
| 31 | Form | FORM | KEY-NXTKEY | 6 / 4 | default (Override) | XML | – |
| 32 | Form | FORM | KEY-MENU | 8 / 3 | default (Override) | XML | CGBS$TOGGLE |
| 33 | Form | FORM | KEY-CLRFRM | 19 / 14 | default (Override) | XML | CG$WHEN_NEW_FORM_INSTANCE |
| 34 | Item | TITLE.CGSO$CHAR_ARB_ED | KEY-LISTVAL | 0 / 0 | default (Override) | OLB code (1 lines): `NULL;` | – |
| 35 | Item | TITLE.CGSO$CHAR_ARB_DO_ENB_Y | KEY-LISTVAL | 0 / 0 | default (Override) | OLB code (1 lines): `NULL;` | – |
| 36 | Item | TITLE.CGSO$CHAR_ARB_MLINE | KEY-LISTVAL | 0 / 0 | default (Override) | OLB code (1 lines): `NULL;` | – |
| 37 | Item | TITLE.CGSO$CHAR_ARB | KEY-LISTVAL | 0 / 0 | default (Override) | OLB code (1 lines): `NULL;` | – |
| 38 | Item | TITLE.CGSO$CHAR_ARB_DO | KEY-LISTVAL | 0 / 0 | default (Override) | OLB code (1 lines): `NULL;` | – |
| 39 | Item | TITLE.SYSTEM_DATE | WHEN-VALIDATE-ITEM | 13 / 12 | default (Override) | XML | – |
| 40 | Item | EDI_MSG.EDI_MSG_LOVE_BUT | WHEN-BUTTON-PRESSED | 0 / 0 | default (Override) | OLB code (1 lines): `EDI_MSG_LOV;` | – |
| 41 | Item | LSIDE.FN1 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 42 | Item | LSIDE.FN1 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 43 | Item | LSIDE.FN1 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 44 | Item | LSIDE.FN50 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 45 | Item | LSIDE.FN50 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 46 | Item | LSIDE.FN50 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 47 | Item | LSIDE.FN2 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 48 | Item | LSIDE.FN2 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 49 | Item | LSIDE.FN2 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 50 | Item | LSIDE.FN49 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 51 | Item | LSIDE.FN49 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 52 | Item | LSIDE.FN49 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 53 | Item | LSIDE.FN3 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 54 | Item | LSIDE.FN3 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 55 | Item | LSIDE.FN3 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 56 | Item | LSIDE.FN48 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 57 | Item | LSIDE.FN48 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 58 | Item | LSIDE.FN48 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 59 | Item | LSIDE.FN4 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 60 | Item | LSIDE.FN4 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 61 | Item | LSIDE.FN4 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 62 | Item | LSIDE.FN47 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 63 | Item | LSIDE.FN47 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 64 | Item | LSIDE.FN47 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 65 | Item | LSIDE.FN5 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 66 | Item | LSIDE.FN5 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 67 | Item | LSIDE.FN5 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 68 | Item | LSIDE.FN46 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 69 | Item | LSIDE.FN46 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 70 | Item | LSIDE.FN46 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 71 | Item | LSIDE.FN6 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 72 | Item | LSIDE.FN6 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 73 | Item | LSIDE.FN6 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 74 | Item | LSIDE.FN45 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 75 | Item | LSIDE.FN45 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 76 | Item | LSIDE.FN45 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 77 | Item | LSIDE.FN7 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 78 | Item | LSIDE.FN7 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 79 | Item | LSIDE.FN7 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 80 | Item | LSIDE.FN44 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 81 | Item | LSIDE.FN44 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 82 | Item | LSIDE.FN44 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 83 | Item | LSIDE.FN8 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 84 | Item | LSIDE.FN8 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 85 | Item | LSIDE.FN8 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 86 | Item | LSIDE.FN43 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 87 | Item | LSIDE.FN43 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 88 | Item | LSIDE.FN43 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 89 | Item | LSIDE.FN9 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 90 | Item | LSIDE.FN9 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 91 | Item | LSIDE.FN9 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 92 | Item | LSIDE.FN42 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 93 | Item | LSIDE.FN42 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 94 | Item | LSIDE.FN42 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 95 | Item | LSIDE.FN10 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 96 | Item | LSIDE.FN10 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 97 | Item | LSIDE.FN10 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 98 | Item | LSIDE.FN41 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 99 | Item | LSIDE.FN41 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 100 | Item | LSIDE.FN41 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 101 | Item | LSIDE.FN11 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 102 | Item | LSIDE.FN11 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 103 | Item | LSIDE.FN11 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 104 | Item | LSIDE.FN40 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 105 | Item | LSIDE.FN40 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 106 | Item | LSIDE.FN40 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 107 | Item | LSIDE.FN12 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 108 | Item | LSIDE.FN12 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 109 | Item | LSIDE.FN12 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 110 | Item | LSIDE.FN39 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 111 | Item | LSIDE.FN39 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 112 | Item | LSIDE.FN39 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 113 | Item | LSIDE.FN13 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 114 | Item | LSIDE.FN13 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 115 | Item | LSIDE.FN13 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 116 | Item | LSIDE.FN38 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 117 | Item | LSIDE.FN38 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 118 | Item | LSIDE.FN38 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 119 | Item | LSIDE.FN14 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 120 | Item | LSIDE.FN14 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 121 | Item | LSIDE.FN14 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 122 | Item | LSIDE.FN37 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 123 | Item | LSIDE.FN37 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 124 | Item | LSIDE.FN37 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 125 | Item | LSIDE.FN15 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 126 | Item | LSIDE.FN15 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 127 | Item | LSIDE.FN15 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 128 | Item | LSIDE.FN36 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 129 | Item | LSIDE.FN36 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 130 | Item | LSIDE.FN36 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 131 | Item | LSIDE.FN16 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 132 | Item | LSIDE.FN16 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 133 | Item | LSIDE.FN16 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 134 | Item | LSIDE.FN17 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 135 | Item | LSIDE.FN17 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 136 | Item | LSIDE.FN17 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 137 | Item | LSIDE.FN34 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 138 | Item | LSIDE.FN34 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 139 | Item | LSIDE.FN34 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 140 | Item | LSIDE.FN35 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 141 | Item | LSIDE.FN35 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 142 | Item | LSIDE.FN35 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 143 | Item | LSIDE.FN18 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 144 | Item | LSIDE.FN18 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 145 | Item | LSIDE.FN18 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 146 | Item | LSIDE.FN33 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 147 | Item | LSIDE.FN33 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 148 | Item | LSIDE.FN33 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 149 | Item | LSIDE.FN19 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 150 | Item | LSIDE.FN19 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 151 | Item | LSIDE.FN19 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 152 | Item | LSIDE.FN32 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 153 | Item | LSIDE.FN32 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 154 | Item | LSIDE.FN32 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 155 | Item | LSIDE.FN20 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 156 | Item | LSIDE.FN20 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 157 | Item | LSIDE.FN20 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 158 | Item | LSIDE.FN31 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 159 | Item | LSIDE.FN31 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 160 | Item | LSIDE.FN31 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 161 | Item | LSIDE.FN21 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 162 | Item | LSIDE.FN21 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 163 | Item | LSIDE.FN21 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 164 | Item | LSIDE.FN30 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 165 | Item | LSIDE.FN30 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 166 | Item | LSIDE.FN30 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 167 | Item | LSIDE.FN22 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 168 | Item | LSIDE.FN22 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 169 | Item | LSIDE.FN22 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 170 | Item | LSIDE.FN29 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 171 | Item | LSIDE.FN29 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 172 | Item | LSIDE.FN29 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 173 | Item | LSIDE.FN23 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 174 | Item | LSIDE.FN23 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 175 | Item | LSIDE.FN23 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 176 | Item | LSIDE.FN28 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 177 | Item | LSIDE.FN28 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 178 | Item | LSIDE.FN28 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 179 | Item | LSIDE.FN24 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 180 | Item | LSIDE.FN24 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 181 | Item | LSIDE.FN24 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 182 | Item | LSIDE.FN27 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 183 | Item | LSIDE.FN27 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 184 | Item | LSIDE.FN27 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 185 | Item | LSIDE.FN25 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 186 | Item | LSIDE.FN25 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 187 | Item | LSIDE.FN25 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 188 | Item | LSIDE.FN26 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 189 | Item | LSIDE.FN26 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 190 | Item | LSIDE.FN26 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 191 | Block | TOOLBAR | KEY-DOWN | 3 / 3 | default (Override) | XML | – |
| 192 | Block | TOOLBAR | KEY-UP | 3 / 3 | default (Override) | XML | – |
| 193 | Block | TOOLBAR | KEY-NEXT-ITEM | 10 / 10 | default (Override) | XML | EXECUTE_FUNCTION |
| 194 | Item | TOOLBAR.SAVE | WHEN-BUTTON-PRESSED | 15 / 12 | default (Override) | XML | – |
| 195 | Item | TOOLBAR.CLEAR_ALL | WHEN-BUTTON-PRESSED | 0 / 0 | default (Override) | OLB code (4 lines): `do_key('clear_BLOCK');` | – |
| 196 | Item | TOOLBAR.EXIT | WHEN-BUTTON-PRESSED | 19 / 15 | default (Override) | XML | – |
| 197 | Item | TOOLBAR.EXIT1 | WHEN-BUTTON-PRESSED | 42 / 38 | default (Override) | XML | – |
| 198 | Item | TOOLBAR.ENTER | WHEN-BUTTON-PRESSED | 0 / 0 | default (Override) | OLB code (26 lines): `SET_ITEM_PROPERTY('SAVE',VISIBLE,PROPERTY_FALSE);` | – |
| 199 | Item | TOOLBAR.EXECUTE | WHEN-BUTTON-PRESSED | 0 / 0 | default (Override) | OLB code (1 lines): `do_key('Execute_query');` | – |
| 200 | Item | TOOLBAR.REMOVE | WHEN-BUTTON-PRESSED | 0 / 0 | default (Override) | OLB code (1 lines): `do_key('Delete_record');` | – |
| 201 | Item | TOOLBAR.LIST_VALUE | WHEN-BUTTON-PRESSED | 0 / 0 | default (Override) | OLB code (1 lines): `do_key('LIST_VALUES');` | – |
| 202 | Item | TOOLBAR.HELP | WHEN-BUTTON-PRESSED | 0 / 0 | default (Override) | OLB code (10 lines): `DECLARE` | – |
| 203 | Item | TOOLBAR.LAST_REC | WHEN-BUTTON-PRESSED | 1 / 1 | default (Override) | XML | – |
| 204 | Item | TOOLBAR.RE_ENTER_QUERY | WHEN-BUTTON-PRESSED | 6 / 6 | default (Override) | XML | – |
| 205 | Item | TOOLBAR.FIRST_REC | WHEN-BUTTON-PRESSED | 0 / 0 | default (Override) | OLB code (1 lines): `do_key('Previous_Record');` | – |
| 206 | Item | TOOLBAR.PAGE_UP | WHEN-BUTTON-PRESSED | 0 / 0 | default (Override) | OLB code (1 lines): `do_key('Scroll_Up');` | – |
| 207 | Item | TOOLBAR.PAGE_DOWN | WHEN-BUTTON-PRESSED | 1 / 1 | default (Override) | XML | – |
| 208 | Item | TOOLBAR.FUN_BUT | WHEN-MOUSE-UP | 15 / 12 | default (Override) | XML | – |
| 209 | Item | TOOLBAR.FUN_BUT | WHEN-MOUSE-DOWN | 13 / 10 | default (Override) | XML | ADJ_FUNS |
| 210 | Block | IMPORTERS | ON-ERROR | 96 / 76 | default (Override) | XML | CGTE$CHECK_CONSTRAINT_VIO |
| 211 | Block | IMPORTERS | POST-QUERY | 73 / 69 | default (Override) | XML | CG$IMPR1120_GLOBALS, CGFK$QRY_IMPORTERS_IMP_BUS_ID_, CGFK$QRY_IMPORTERS_IMP_CTRY_FK, CGFK$QRY_IMPORTERS_IMP_ITIDT_F, CGFK$QRY_IMPORTERS_IMP_SDP_FK |
| 212 | Block | IMPORTERS | PRE-QUERY | 78 / 63 | default (Override) | XML | CG$IMPR1120_GLOBALS |
| 213 | Block | IMPORTERS | KEY-HELP | 102 / 100 | default (Override) | XML | – |
| 214 | Block | IMPORTERS | WHEN-CREATE-RECORD | 10 / 7 | default (Override) | XML | – |
| 215 | Item | IMPORTERS.PORT_CD | KEY-LISTVAL | 75 / 65 | default (Override) | XML | – |
| 216 | Item | IMPORTERS.PORT_CD2 | WHEN-BUTTON-PRESSED | 6 / 4 | default (Override) | XML | – |
| 217 | Item | IMPORTERS.PORT_NAME | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 218 | Item | IMPORTERS.HQ_IMPR_NBR | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 219 | Item | IMPORTERS.IMPR_NBR | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 220 | Item | IMPORTERS.IMPR_NBR | WHEN-VALIDATE-ITEM | 22 / 18 | default (Override) | XML | – |
| 221 | Item | IMPORTERS.SDP_PORT_STATUS | KEY-LISTVAL | 34 / 32 | default (Override) | XML | – |
| 222 | Item | IMPORTERS.IMPR_TYPE_CD | KEY-LISTVAL | 73 / 63 | default (Override) | XML | – |
| 223 | Item | IMPORTERS.IMPR_TYPE_CD | WHEN-VALIDATE-ITEM | 19 / 17 | default (Override) | XML | CGFK$CHK_IMPORTERS_IMP_ITIDT_F |
| 224 | Item | IMPORTERS.IMPR_TYPE_CD | WHEN-NEW-ITEM-INSTANCE | 6 / 6 | default (Override) | XML | – |
| 225 | Item | IMPORTERS.IMPR_TYPE_CD2 | WHEN-BUTTON-PRESSED | 6 / 4 | default (Override) | XML | – |
| 226 | Item | IMPORTERS.IMPR_TYPE_NAME | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 227 | Item | IMPORTERS.CTRY_CD | KEY-LISTVAL | 74 / 64 | default (Override) | XML | – |
| 228 | Item | IMPORTERS.CTRY_CD2 | WHEN-BUTTON-PRESSED | 6 / 4 | default (Override) | XML | – |
| 229 | Item | IMPORTERS.CRTY_ARBC_NAME | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 230 | Item | IMPORTERS.CITY_CODE_OF_ID | KEY-LISTVAL | 81 / 67 | default (Override) | XML | – |
| 231 | Item | IMPORTERS.CITY_CODE_OF_ID2 | WHEN-BUTTON-PRESSED | 6 / 4 | default (Override) | XML | – |
| 232 | Item | IMPORTERS.ID_CITY_NAME | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 233 | Item | IMPORTERS.BUS_ID | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 234 | Item | IMPORTERS.BUS_ID_TYPE_CD | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 235 | Item | IMPORTERS.BUTT | WHEN-BUTTON-PRESSED | 7 / 5 | default (Override) | XML | – |
| 236 | Item | IMPORTERS.BUS_ID_TYPE_NAME | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 237 | Item | IMPORTERS.BUS_ID_BRNCH | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 238 | Item | IMPORTERS.CTRY_CTRY_STATUS | KEY-LISTVAL | 34 / 32 | default (Override) | XML | – |
| 239 | Item | IMPORTERS.ARBC_IMPR_NAME | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 240 | Item | IMPORTERS.ENG_IMPR_NAME | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 241 | Item | IMPORTERS.IMPR_CNTCT_NAME | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 242 | Item | IMPORTERS.CTRY_CD_OF_ID | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 243 | Block | IMPR_SUSPN | ON-ERROR | 78 / 56 | default (Override) | XML | CGTE$CHECK_CONSTRAINT_VIO |
| 244 | Block | IMPR_SUSPN | KEY-HELP | 18 / 16 | default (Override) | XML | – |
| 245 | Block | IMPR_SUSPN | KEY-DELREC | 3 / 3 | default (Override) | XML | – |
| 246 | Block | IMPR_SUSPN | ON-DELETE | 13 / 11 | default (Override) | XML | – |
| 247 | Block | IMPR_SUSPN | POST-INSERT | 68 / 58 | default (Override) | XML | – |
| 248 | Block | IMPR_SUSPN | POST-QUERY | 9 / 8 | default (Override) | XML | – |
| 249 | Block | IMPR_SUSPN | PRE-INSERT | 14 / 13 | default (Override) | XML | – |
| 250 | Block | IMPR_SUSPN | PRE-UPDATE | 27 / 22 | default (Override) | XML | – |
| 251 | Block | IMPR_SUSPN | WHEN-NEW-RECORD-INSTANCE | 41 / 31 | default (Override) | XML | – |
| 252 | Item | IMPR_SUSPN.SUSPN_STRT_DT | KEY-LISTVAL | 26 / 25 | default (Override) | XML | – |
| 253 | Item | IMPR_SUSPN.SUSPN_STRT_DT | KEY-F4 | 26 / 25 | default (Override) | XML | – |
| 254 | Item | IMPR_SUSPN.SUSPN_STRT_DT | WHEN-VALIDATE-ITEM | 25 / 21 | default (Override) | XML | – |
| 255 | Item | IMPR_SUSPN.SUSPN_STRT_DT | WHEN-NEW-ITEM-INSTANCE | 5 / 5 | default (Override) | XML | – |
| 256 | Item | IMPR_SUSPN.SUSPN_END_DT | KEY-LISTVAL | 26 / 25 | default (Override) | XML | – |
| 257 | Item | IMPR_SUSPN.SUSPN_END_DT | KEY-F4 | 26 / 25 | default (Override) | XML | – |
| 258 | Item | IMPR_SUSPN.SUSPN_END_DT | WHEN-VALIDATE-ITEM | 24 / 20 | default (Override) | XML | – |
| 259 | Item | IMPR_SUSPN.SUSPN_RSN_CD | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 260 | Item | IMPR_SUSPN.SUSPN_RSN_CD | WHEN-NEW-ITEM-INSTANCE | 21 / 11 | default (Override) | XML | – |
| 261 | Item | IMPR_SUSPN.SUSPN_RSN_CD | WHEN-VALIDATE-ITEM | 25 / 21 | default (Override) | XML | – |
| 262 | Item | IMPR_SUSPN.SUSPN_RSN_TEXT | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 263 | Item | IMPR_SUSPN.SUSPN_RSN_TEXT | WHEN-NEW-ITEM-INSTANCE | 6 / 5 | default (Override) | XML | – |
| 264 | Item | IMPR_SUSPN.SUSPN_SIDE_CD | WHEN-LIST-CHANGED | 13 / 12 | default (Override) | XML | – |
| 265 | Item | IMPR_SUSPN.SUSPN_SIDE_CD | WHEN-NEW-ITEM-INSTANCE | 16 / 11 | default (Override) | XML | – |
| 266 | Item | IMPR_SUSPN.SUSPN_SIDE_CD | WHEN-VALIDATE-ITEM | 5 / 5 | default (Override) | XML | – |
| 267 | Item | IMPR_SUSPN.SUSPN_RLSE_DT | KEY-LISTVAL | 26 / 25 | default (Override) | XML | – |
| 268 | Item | IMPR_SUSPN.SUSPN_RLSE_DT | KEY-F4 | 26 / 25 | default (Override) | XML | – |
| 269 | Item | IMPR_SUSPN.SUSPN_RLSE_DT | WHEN-VALIDATE-ITEM | 14 / 12 | default (Override) | XML | – |

### 6.1 Form-level triggers

#### FORM · KEY-EDIT

- Level: Form · Owner: `FORM` · Execution hierarchy: default (Override) · Subclassed from CIC_OLB.olb:KEY-EDIT
- Lines: 21 total / 1 active (non-blank, non-comment)
- Built-ins: –
- Program units (form): –
- Library / DB package calls: NIB.KEY_EDIT

```plsql
/* CGAP$TES_SEQUENCE_BEFORE */
/*IF (:SYSTEM.MODE = 'NORMAL' ) THEN
	do_key('clear_form');
	SET_FORM_PROPERTY(:SYSTEM.CURRENT_FORM , VALIDATION_UNIT , FORM_SCOPE);
	Clear_form(NO_VALIDATE);
	SET_FORM_PROPERTY(:SYSTEM.CURRENT_FORM , VALIDATION_UNIT , DEFAULT_SCOPE);
	Clear_form(NO_VALIDATE);
ELSE
	EXIT_FORM(NO_VALIDATE);
END IF;

begin
 	:title.user_name := :PARAMETER.P_USER_NAME;
	:title.SCREEN_NAME :=:PARAMETER.P_MODULE_NAME;
	:title.SYSTEM_DATE := HIJDATE.Cur_Hij_Date;
--	SELECT TO_CHAR(SYSDATE, 'HH24:MI:SS') INTO :TITLE.CLOCK FROM DUAL;

end;
*/

NIB.KEY_EDIT;
```

#### FORM · KEY-DUPREC

- Level: Form · Owner: `FORM` · Execution hierarchy: default (Override) · Subclassed from CIC_OLB.olb:KEY-DUPREC
- Lines: 10 total / 1 active (non-blank, non-comment)
- Built-ins: –
- Program units (form): –
- Library / DB package calls: NIB.KEY_DUPREC

```plsql
/* CGAP$TES_SEQUENCE_BEFORE */
/*do_key('Create_record');
begin
 	:title.user_name := :PARAMETER.P_USER_NAME;
	:title.SCREEN_NAME :=:PARAMETER.P_MODULE_NAME;
	:title.SYSTEM_DATE := HIJDATE.Cur_Hij_Date;
end;*/

NIB.KEY_DUPREC;
```

#### FORM · PRE-FORM

- Level: Form · Owner: `FORM` · Execution hierarchy: default (Override) · Subclassed from CIC_OLB.olb:PRE-FORM
- Lines: 36 total / 10 active (non-blank, non-comment)
- Built-ins: FORMS_DDL, SET_APPLICATION_PROPERTY
- Program units (form): –
- Library / DB package calls: CGHP$PRE_FORM, NIB.PRE_FORM

```plsql
/* CGAP$TES_SEQUENCE_BEFORE */
/*declare
	ix 							pls_integer ;

BEGIN
	:GLOBAL.current_ver := null ;
	ix := win_api_utility.get_active_window;
	win_api_session.change_mdi_icon(ix,'gamarek.ico',0);
  set_window_property('CGSO$WINDOW_1',TITLE,'');
  set_window_property(FORMS_MDI_WINDOW,TITLE,'                                                                   [ ] - بسم الله الرحمن الرحيم');


	:GLOBAL.EXIT := NULL;


	KEY_CONTROL.FOUND_KEY;
END;

	Win_API_Session.Timeout_Delete_Timer;
	*/

	NIB.PRE_FORM;
/* CGYR$SET_DATE_FORMAT */
/* Establish Single Standard Format Mask with 4-digit-year element */
BEGIN
  set_application_property(DATE_FORMAT_COMPATIBILITY_MODE, '5.0');
  set_application_property(PLSQL_DATE_FORMAT, 'YYYY/MM/DD HH24:MI:SS');
  set_application_property(BUILTIN_DATE_FORMAT, 'YYYY/MM/DD HH24:MI:SS');
  forms_ddl('ALTER SESSION SET NLS_DATE_FORMAT = ''YYYY/MM/DD HH24:MI:SS''');
END;

/* CGHP$SET_MOD_GLOBALS */
/* Set up globals that are used by the user help form. */
BEGIN
  :GLOBAL.CG$HP_HPATH := CGHP$PRE_FORM;
END;
```

#### FORM · WHEN-NEW-FORM-INSTANCE

- Level: Form · Owner: `FORM` · Execution hierarchy: default (Override) · Subclassed from CIC_OLB.olb:WHEN-NEW-FORM-INSTANCE
- Lines: 173 total / 31 active (non-blank, non-comment)
- Built-ins: EXIT_FORM, MESSAGE, SET_ITEM_PROPERTY
- Program units (form): CG$WHEN_NEW_FORM_INSTANCE
- Library / DB package calls: CGBS2$.SET_COORD_STYLE, CGBS2$.SET_QRY_ON_ENTRY, CGTE$OTHER_EXCEPTIONS, NIB.WHEN_NEW_FORM_INSTANCE

```plsql
/* CGAP$TES_SEQUENCE_BEFORE */
/*DECLARE
	cust_clk Timer;
  SYSTEM_DATE   VARCHAR2(20);
  SDATE1  DATE;
	V_FUN_ITEM_REC 	LIB_APX_USR.TMPLT.CUR_Fun_Items%ROWTYPE;
	x number := 0.0;
--	y number := 5.25;
	y number := 5.17;
	RET 		PLS_INTEGER;
	WND 		PLS_INTEGER;
	ENAB    VARCHAR2(100);

begin
	SET_WINDOW_PROPERTY(FORMS_MDI_WINDOW,WINDOW_STATE,MAXIMIZE);
	SET_WINDOW_PROPERTY('CGSO$WINDOW_1',WINDOW_STATE,MAXIMIZE);

	WND     := WIN_API_UTILITY.GET_ACTIVE_WINDOW();
	RET     := SEC_DLL.IsWndCaptionDisplayed(WND);
	IF RET = 1 THEN
			TOGGEL_WND;
	END IF;

	Set_View_Property('EDI_MSG', VISIBLE, PROPERTY_FALSE);
	TMPLT.FUN_ITEMS_Y_POS := GET_VIEW_PROPERTY('LSIDE', VIEWPORT_Y_POS );
	TMPLT.FUN_ITEMS_VIEW_Y_POS := GET_VIEW_PROPERTY('LSIDE', VIEWPORT_Y_POS_ON_CANVAS );
	TMPLT.HEIGHT := GET_VIEW_PROPERTY('LSIDE', HEIGHT);


	TMPLT.LOAD_FUNCTIONS(:PARAMETER.P_USER_ID, :PARAMETER.P_MODULE_ID);
	TMPLT.ENB_DIS_FUN_BUT;


	 SET_VIEW_PROPERTY('TOOLBAR', visible, property_true);
 	 SET_VIEW_PROPERTY('TOOLBAR', display_position, x,y);
	 SET_VIEW_PROPERTY ('TITLE', visible, property_true);

	SET_ITEM_PROPERTY('EXIT1',VISIBLE,PROPERTY_FALSE);
	SET_ITEM_PROPERTY('RE_ENTER_QUERY',VISIBLE,PROPERTY_FALSE);
	SET_ITEM_PROPERTY('LAST_REC',VISIBLE,PROPERTY_FALSE);
	SET_ITEM_PROPERTY('FIRST_REC',VISIBLE,PROPERTY_FALSE);
	SET_ITEM_PROPERTY('PAGE_UP',VISIBLE,PROPERTY_FALSE);
	SET_ITEM_PROPERTY('PAGE_DOWN',VISIBLE,PROPERTY_FALSE);
	SET_ITEM_PROPERTY('EXECUTE',VISIBLE,PROPERTY_FALSE);
	:GLOBAL.EXIT := 0;

	IF CHECK_TIMEOUT = TRUE THEN
		DECLARE
			hWind		PLS_INTEGER;
			CheckTimer	TIMER;
		BEGIN
			hWind := get_window_property(FORMS_MDI_WINDOW,WINDOW_HANDLE);
			Win_API_Session.Timeout_Start_Timer(hWind);
			CheckTimer := Create_Timer('CheckTimeout',120000,repeat);
		END;
	END IF;
-- -----------------------------------------------------------------------------------------------------------
IF CHECK_EDI_ROLE_ID(:PARAMETER.P_CURR_PORT_CD,:PARAMETER.P_USER_ID) = TRUE THEN
IF CHECK_EDI_MSG_TIMER = TRUE THEN
	DECLARE
			TIMER_ID  TIMER;
			V_VAR_VALUE					VARCHAR2(200);
			V_VAR_VALUE_RETURN	VARCHAR2(200);
	BEGIN
		V_VAR_VALUE 				:= GNRL.GET_CUSTOMS_SETTING(:PARAMETER.P_CURR_PORT_CD,'EDI_MSG_TIMER',30);
		V_VAR_VALUE_RETURN 	:= GNRL.GET_CUSTOMS_SETTING(:PARAMETER.P_CURR_PORT_CD,'MSG_DISPLAY_PERIOD',30);

		IF (V_VAR_VALUE IS NOT NULL AND V_VAR_VALUE_RETURN IS NOT NULL) AND
			 (V_VAR_VALUE > 0 AND V_VAR_VALUE_RETURN > 0) THEN

		TIMER_ID := Find_Timer('EDI_MSG');
	  IF Id_Null(TIMER_ID) THEN
	   		TIMER_ID := CREATE_TIMER('EDI_MSG',V_VAR_VALUE, REPEAT);
	 	ELSE
	   		Set_Timer(TIMER_ID,1, REPEAT);
	 	END IF;

	 	TIMER_ID := Find_Timer('RETURN_EDI_MSG');
	  IF Id_Null(TIMER_ID) THEN
	   		TIMER_ID := CREATE_TIMER('RETURN_EDI_MSG',V_VAR_VALUE_RETURN, REPEAT);
	 	ELSE
	   		Set_Timer(TIMER_ID,1, REPEAT);
	 	END IF;
		END IF;
	END;
END IF;
END IF;
	:GLOBAL.G_TIME_OUT := 0;
	:GLOBAL.TIMER 		 :=	0;
	:global.item_name		:= NULL;


BEGIN
SYS.DBMS_APPLICATION_INFO.set_module (NVL(:PARAMETER.P_MODULE_NAME,'NEBRAS')||'  '||nvl(:GLOBAL.current_ver,' '), NULL);
EXCEPTION
		WHEN OTHERS THEN
		NULL;
END;
END;
--------------------------------------------------------------------
--------------------- MAIH 17-01-2016-------------------------------
-------------------------VERSIONING---------------------------------
--------------------------------------------------------------------
DECLARE
   v_obj_version   NUMBER;
   v_obj_status    NUMBER;
BEGIN
   SELECT obj_version, obj_status
     INTO v_obj_version, v_obj_status
     FROM sc_sys_obj_ver
    WHERE sysobj_id = :parameter.p_module_id
    AND PORT_CD = :PARAMETER.P_CURR_PORT_CD

   IF v_obj_version > nvl(:GLOBAL.current_ver,1)
   THEN
      IF v_obj_status IN (1, 2)
      THEN
         str.dispalert ('إصدار الشاشة الحالي ( '||nvl(:GLOBAL.current_ver,1) || ' ) قديم , من فضلك قم بالتحديث ', 'ERROR');

         IF v_obj_status = 1
         THEN
            EXIT_FORM ;
         END IF;
      END IF;
   END IF;
 EXCEPTION
 		WHEN OTHERS THEN
 				NULL;
 END;
 */

 NIB.WHEN_NEW_FORM_INSTANCE;
/* CGGN$CALL_GENERATOR_CODE */
/* execute the when-new-form-instance code that was created by forms generator */
BEGIN
  CGBS2$.SET_COORD_STYLE( 'F' );
  CGBS2$.SET_QRY_ON_ENTRY( 'Y' );
  BEGIN
    CG$WHEN_NEW_FORM_INSTANCE;
  EXCEPTION
    WHEN OTHERS THEN
      CGTE$OTHER_EXCEPTIONS;
  END;
END;

BEGIN
:global.current_ver := 2 ;   -- DAHAB SMS
:global.current_DT := '05-08-2026';

	:global.Exec_Query_Now := 0;
	:global.PORT_CD  := NULL;
	:global.IMPR_NBR  := NULL;
--UPDATE BY ANAS --
  --12-5-2005 --
IF :PARAMETER.P_CURR_PORT_CD = 99 THEN

 SET_ITEM_PROPERTY('IMPORTERS.PORT_CD',INSERT_ALLOWED,PROPERTY_TRUE);
 SET_ITEM_PROPERTY('IMPORTERS.PORT_CD',UPDATE_ALLOWED,PROPERTY_TRUE);
END IF;

IF :PARAMETER.P_CURR_PORT_CD = 99 THEN
   :IMPORTERS.PORT_CD:=NVL(:IMPORTERS.PORT_CD,:PARAMETER.P_CURR_PORT_CD);
ELSE
:IMPORTERS.PORT_CD:=:PARAMETER.P_CURR_PORT_CD;

END IF;

IF :PARAMETER.Current_Side = 3 AND :PARAMETER.P_CURR_PORT_CD != 99 THEN
  MESSAGE('ليس لديك الصلاحية للدخول على الشاشة');
  EXIT_FORM(NO_VALIDATE);

END IF;
END;
```

#### FORM · WHEN-WINDOW-ACTIVATED

- Level: Form · Owner: `FORM` · Execution hierarchy: default (Override) · Subclassed from CIC_OLB.olb:WHEN-WINDOW-ACTIVATED
- Lines: 29 total / 1 active (non-blank, non-comment)
- Built-ins: –
- Program units (form): –
- Library / DB package calls: NIB.WHEN_WINDOW_ACTIVATED

```plsql
/* CGAP$TES_SEQUENCE_BEFORE */
/*declare
		x number := 0.0;
		--y number := 5.25;
		y number := 5.17;
begin
	SET_WINDOW_PROPERTY('CGSO$WINDOW_1',WINDOW_STATE,MAXIMIZE);

 	:title.user_name 		:= :PARAMETER.P_USER_NAME;
	:title.SCREEN_NAME 	:= :PARAMETER.P_MODULE_NAME;
	:title.SYSTEM_DATE 	:= HIJDATE.Cur_Hij_Date;
	begin
  	if nvl(:global.current_ver,0)  = 0 then
	  	:global.current_ver := 1;
	  end if;

    :title.VERSION 	    := :global.current_ver ;
	exception
			when others then
						null;
	end ;

	SET_VIEW_PROPERTY('TOOLBAR', visible, property_true);
	SET_VIEW_PROPERTY('TOOLBAR', display_position, x,y);
	SET_VIEW_PROPERTY ('TITLE', visible, property_true);
	TMPLT.ENB_DIS_FUN_BUT;

end;*/
NIB.WHEN_WINDOW_ACTIVATED;
```

#### FORM · KEY-ENTQRY

- Level: Form · Owner: `FORM` · Execution hierarchy: default (Override) · Subclassed from CIC_OLB.olb:KEY-ENTQRY
- Lines: 49 total / 4 active (non-blank, non-comment)
- Built-ins: –
- Program units (form): –
- Library / DB package calls: NIB.KEY_ENTQRY

```plsql
/* CGAP$TES_SEQUENCE_BEFORE */
/*DECLARE
	PROP VARCHAR2(10);
	PROP2 VARCHAR2(10);
	PROP3 VARCHAR2(10);

BEGIN
	PROP  := GET_ITEM_PROPERTY('SAVE',VISIBLE);
	PROP2 := GET_ITEM_PROPERTY('ENTER',ENABLED);
	PROP3 := GET_ITEM_PROPERTY('EXECUTE',VISIBLE);
IF PROP = 'TRUE' AND PROP2 = 'TRUE' THEN

SET_ITEM_PROPERTY('SAVE',VISIBLE,PROPERTY_FALSE);
SET_ITEM_PROPERTY('ENTER',VISIBLE,PROPERTY_FALSE);
SET_ITEM_PROPERTY('EXIT',VISIBLE,PROPERTY_FALSE);
SET_ITEM_PROPERTY('CLEAR_ALL',VISIBLE,PROPERTY_FALSE);
SET_ITEM_PROPERTY('REMOVE',VISIBLE,PROPERTY_FALSE);
SET_ITEM_PROPERTY('LIST_VALUE',VISIBLE,PROPERTY_FALSE);
SET_ITEM_PROPERTY('HELP',VISIBLE,PROPERTY_FALSE);
SET_ITEM_PROPERTY('FUN_BUT',VISIBLE,PROPERTY_FALSE);
SET_ITEM_PROPERTY('EXIT1',VISIBLE,PROPERTY_TRUE);
SET_ITEM_PROPERTY('RE_ENTER_QUERY',VISIBLE,PROPERTY_TRUE);
SET_ITEM_PROPERTY('LAST_REC',VISIBLE,PROPERTY_TRUE);
SET_ITEM_PROPERTY('FIRST_REC',VISIBLE,PROPERTY_TRUE);
SET_ITEM_PROPERTY('PAGE_UP',VISIBLE,PROPERTY_TRUE);
SET_ITEM_PROPERTY('PAGE_DOWN',VISIBLE,PROPERTY_TRUE);
SET_ITEM_PROPERTY('EXECUTE',VISIBLE,PROPERTY_TRUE);
SET_ITEM_PROPERTY('HELP',ENABLED,PROPERTY_FALSE);
SET_ITEM_PROPERTY('EXIT1',ENABLED,PROPERTY_TRUE);
SET_ITEM_PROPERTY('LAST_REC',ENABLED,PROPERTY_TRUE);
SET_ITEM_PROPERTY('FIRST_REC',ENABLED,PROPERTY_TRUE);
SET_ITEM_PROPERTY('PAGE_UP',ENABLED,PROPERTY_TRUE);
SET_ITEM_PROPERTY('PAGE_DOWN',ENABLED,PROPERTY_TRUE);
SET_ITEM_PROPERTY('EXECUTE',ENABLED,PROPERTY_TRUE);
SET_ITEM_PROPERTY('RE_ENTER_QUERY',ENABLED,PROPERTY_TRUE);
ENTER_QUERY ( NO_VALIDATE );
ELSIF PROP = 'FALSE' AND PROP3 = 'TRUE' THEN
EXECUTE_QUERY (NO_VALIDATE);
END IF;
END;

*/

NIB.KEY_ENTQRY;
/* CGBS$KEY_ENTQRY_FRM_MODIFIED */
/* Check if query is allowed to avoid unnecessary coordination */
BEGIN
NULL;
END;
```

#### FORM · ON-ERROR

- Level: Form · Owner: `FORM` · Execution hierarchy: default (Override) · Subclassed from CIC_OLB.olb:ON-ERROR
- Lines: 39 total / 1 active (non-blank, non-comment)
- Built-ins: –
- Program units (form): –
- Library / DB package calls: NIB.ON_ERROR

```plsql
/* CGAP$TES_SEQUENCE_BEFORE */
 /*DECLARE
   errnum NUMBER       := ERROR_CODE;
   errtxt VARCHAR2(2000) := ERROR_TEXT;
   errtyp VARCHAR2(2000)  := ERROR_TYPE;
   alert_is     alert;
   alert_button number;
   MsgTxt VARCHAR2(2000);
	 TIMER_ID TIMER;
 BEGIN
 	 IF errtyp = 'FRM' THEN
	 	errtyp := 'خطأ : ش';
	 ELSIF errtyp = 'ORA' THEN
	 	errtyp := 'خطأ : ق';
	 END IF;

	 IF DBMS_ERROR_CODE = ERR_DB.GET_DB_ERR_CD THEN
		MsgTxt := ERR_DB.GET_LAST_ERROR;
	 ELSE
		MsgTxt := errtyp||'-'||TO_CHAR(errnum)||': '||errtxt;
	 END IF;
   alert_is := find_alert('CFG_ERROR');

	 if  (not id_null(alert_is)) then
  		set_alert_property(alert_is, ALERT_MESSAGE_TEXT, MsgTxt );
  		alert_button := show_alert(alert_is);
	 else
     Message(MsgTxt);
	 end if;
 		TIMER_ID := FIND_TIMER('ON_ERROR_TIMER');
		IF NOT ID_NULL(TIMER_ID) THEN
			 DELETE_TIMER(TIMER_ID);
		END IF;

	  TIMER_ID := CREATE_TIMER('ON_ERROR_TIMER', 1, REPEAT);
 END;
 */

 NIB.ON_ERROR;
```

#### FORM · ON-MESSAGE

- Level: Form · Owner: `FORM` · Execution hierarchy: default (Override) · Subclassed from CIC_OLB.olb:ON-MESSAGE
- Lines: 34 total / 1 active (non-blank, non-comment)
- Built-ins: –
- Program units (form): –
- Library / DB package calls: NIB.ON_MESSAGE

```plsql
/* CGAP$TES_SEQUENCE_BEFORE */
 /*DECLARE
   msgnum NUMBER         := MESSAGE_CODE;
   msgtxt VARCHAR2(2000) := MESSAGE_TEXT;
   msgtyp VARCHAR2(2000)   := MESSAGE_TYPE;
   alert_is	ALERT;
   alert_button NUMBER;
 	 TIMER_ID TIMER;
 BEGIN
	 IF msgtyp = 'FRM' THEN
	 	msgtyp := 'معلومه : ش';
	 ELSIF msgtyp = 'ORA' THEN
	 	msgtyp := 'معلومه : ق';
	 END IF;


	 MsgTxt := msgtyp||'-'||TO_CHAR(msgnum)||': '||msgtxt;
   alert_is := find_alert('CFG_INFORMATION');

	 if  (not id_null(alert_is)) then
  		set_alert_property(alert_is, ALERT_MESSAGE_TEXT, MsgTxt );
  		alert_button := show_alert(alert_is);
	 else
     Message(MsgTxt);
	 end if;
 		TIMER_ID := FIND_TIMER('ON_MESSAGE_TIMER');
		IF NOT ID_NULL(TIMER_ID) THEN
			 DELETE_TIMER(TIMER_ID);
		END IF;

	  TIMER_ID := CREATE_TIMER('ON_MESSAGE_TIMER', 1, REPEAT);
 END;
*/
NIB.ON_MESSAGE;
```

#### FORM · KEY-CLRBLK

- Level: Form · Owner: `FORM` · Execution hierarchy: default (Override) · Subclassed from CIC_OLB.olb:KEY-CLRBLK
- Lines: 22 total / 4 active (non-blank, non-comment)
- Built-ins: –
- Program units (form): –
- Library / DB package calls: NIB.KEY_CLRBLK

```plsql
/* CGAP$TES_SEQUENCE_BEFORE */
/*DECLARE
	PROP VARCHAR2(10);
	RET NUMBER;
BEGIN

PROP := GET_ITEM_PROPERTY('SAVE',VISIBLE);
IF PROP = 'FALSE' THEN
     ENTER_QUERY (NO_VALIDATE);
    ELSE
     CLEAR_BLOCK(NO_VALIDATE);

END IF;

END;*/

NIB.KEY_CLRBLK;
/* CGBS$KEY_CLRBLK_FRM_MODIFIED */
/* Perform checks prior to clearing block */
BEGIN
NULL;
END;
```

#### FORM · KEY-DELREC

- Level: Form · Owner: `FORM` · Execution hierarchy: default (Override) · Subclassed from CIC_OLB.olb:KEY-DELREC
- Lines: 25 total / 1 active (non-blank, non-comment)
- Built-ins: –
- Program units (form): –
- Library / DB package calls: NIB.KEY_DELREC

```plsql
/* CGAP$TES_SEQUENCE_BEFORE */
/*DECLARE
	RET NUMBER;
	PROP VARCHAR2(10);
	PROP1 VARCHAR2(10);
BEGIN
	PROP1 := GET_ITEM_PROPERTY('REMOVE',ENABLED);
  PROP  := GET_ITEM_PROPERTY('REMOVE',VISIBLE);
IF PROP = 'FALSE' THEN
       NULL;
  ELSIF :SYSTEM.FORM_STATUS !='NEW' AND PROP = 'TRUE' AND PROP1 = 'TRUE' THEN
    BEGIN
	    RET := STR.DispAlert('هل أنت متأكد من عملية الحذف','WARNING');
       IF RET = ALERT_BUTTON1 THEN
   	       Delete_record;
  	       COMMIT;
         ELSIF RET = ALERT_BUTTON2 THEN
           NULL;
       END IF;
    END;
END IF;

end;*/

NIB.KEY_DELREC;
```

#### FORM · KEY-F5

- Level: Form · Owner: `FORM` · Execution hierarchy: default (Override) · Subclassed from CIC_OLB.olb:KEY-F5
- Lines: 22 total / 1 active (non-blank, non-comment)
- Built-ins: –
- Program units (form): –
- Library / DB package calls: NIB.KEY_F5

```plsql
/* CGAP$TES_SEQUENCE_BEFORE */
/*DECLARE
	RET NUMBER;
	PROP VARCHAR2(10);
	PROP1 VARCHAR2(10);

BEGIN
	PROP1 := GET_ITEM_PROPERTY('SAVE',ENABLED);
  PROP  := GET_ITEM_PROPERTY('SAVE',VISIBLE);
   IF PROP = 'FALSE' OR PROP1 = 'FALSE' THEN
       NULL;
   ELSE
           	   BELL;
               COMMIT;
    END IF;


 	:title.user_name   := :PARAMETER.P_USER_NAME;
  :title.SCREEN_NAME := :PARAMETER.P_MODULE_NAME;
	:title.SYSTEM_DATE := HIJDATE.Cur_Hij_Date;
end;*/
NIB.KEY_F5;
```

#### FORM · KEY-NXTREC

- Level: Form · Owner: `FORM` · Execution hierarchy: default (Override) · Subclassed from CIC_OLB.olb:KEY-NXTREC
- Lines: 15 total / 1 active (non-blank, non-comment)
- Built-ins: –
- Program units (form): –
- Library / DB package calls: NIB.KEY_NXTREC

```plsql
/* CGAP$TES_SEQUENCE_BEFORE */
/*DECLARE

	PROP VARCHAR2(10);
BEGIN
  PROP := GET_ITEM_PROPERTY('SAVE',VISIBLE);
    IF PROP = 'TRUE' THEN
         NULL;
    ELSE
         last_record;
    END IF;
end;
*/

NIB.KEY_NXTREC;
```

#### FORM · KEY-PRVREC

- Level: Form · Owner: `FORM` · Execution hierarchy: default (Override) · Subclassed from CIC_OLB.olb:KEY-PRVREC
- Lines: 13 total / 1 active (non-blank, non-comment)
- Built-ins: –
- Program units (form): –
- Library / DB package calls: NIB.KEY_PRVREC

```plsql
/* CGAP$TES_SEQUENCE_BEFORE */
/*DECLARE

	PROP VARCHAR2(10);
BEGIN
  PROP := GET_ITEM_PROPERTY('SAVE',VISIBLE);
    IF PROP = 'TRUE' THEN
         NULL;
           ELSE
            first_record;
    END IF;
end;*/
NIB.KEY_PRVREC;
```

#### FORM · KEY-DOWN

- Level: Form · Owner: `FORM` · Execution hierarchy: default (Override) · Subclassed from CIC_OLB.olb:KEY-DOWN
- Lines: 17 total / 1 active (non-blank, non-comment)
- Built-ins: –
- Program units (form): –
- Library / DB package calls: NIB.KEY_DOWN

```plsql
/* CGAP$TES_SEQUENCE_BEFORE */
/*DECLARE
	RET NUMBER;
	PROP VARCHAR2(10);
BEGIN
  PROP := GET_ITEM_PROPERTY('SAVE',VISIBLE);
   IF PROP = 'FALSE' THEN
   	 IF :System.Last_Record = 'FALSE' THEN
        DOWN;
   	    ELSE
   	 	    NULL;
   	    END IF;
      ELSE
     DOWN;
   END IF;
 END;*/
 NIB.KEY_DOWN;
```

#### FORM · KEY-UP

- Level: Form · Owner: `FORM` · Execution hierarchy: default (Override) · Subclassed from CIC_OLB.olb:KEY-UP
- Lines: 3 total / 1 active (non-blank, non-comment)
- Built-ins: –
- Program units (form): –
- Library / DB package calls: NIB.KEY_UP

```plsql
/* CGAP$TES_SEQUENCE_BEFORE */
--Up;
NIB.KEY_UP;
```

#### FORM · KEY-SCRUP

- Level: Form · Owner: `FORM` · Execution hierarchy: default (Override) · Subclassed from CIC_OLB.olb:KEY-SCRUP
- Lines: 3 total / 1 active (non-blank, non-comment)
- Built-ins: –
- Program units (form): –
- Library / DB package calls: NIB.KEY_SCRUP

```plsql
/* CGAP$TES_SEQUENCE_BEFORE */
--Scroll_up;
NIB.KEY_SCRUP;
```

#### FORM · KEY-SCRDOWN

- Level: Form · Owner: `FORM` · Execution hierarchy: default (Override) · Subclassed from CIC_OLB.olb:KEY-SCRDOWN
- Lines: 3 total / 1 active (non-blank, non-comment)
- Built-ins: –
- Program units (form): –
- Library / DB package calls: NIB.KEY_SCRDOWN

```plsql
/* CGAP$TES_SEQUENCE_BEFORE */
-- Scroll_Down;
NIB.KEY_SCRDOWN;
```

#### FORM · KEY-PRINT

- Level: Form · Owner: `FORM` · Execution hierarchy: default (Override) · Subclassed from CIC_OLB.olb:KEY-PRINT
- Lines: 13 total / 1 active (non-blank, non-comment)
- Built-ins: –
- Program units (form): –
- Library / DB package calls: NIB.KEY_PRINT

```plsql
/* CGAP$TES_SEQUENCE_BEFORE */
/*DECLARE
	PROP VARCHAR2(10);
BEGIN
	  PROP := GET_ITEM_PROPERTY('SAVE',VISIBLE);
	    IF PROP = 'TRUE' THEN
  	      PRINT;
	      ELSE
	    	  NULL;
	    END IF;
	  END;
*/
NIB.KEY_PRINT;
```

#### FORM · KEY-EXIT

- Level: Form · Owner: `FORM` · Execution hierarchy: default (Override) · Subclassed from CIC_OLB.olb:KEY-EXIT
- Lines: 50 total / 1 active (non-blank, non-comment)
- Built-ins: –
- Program units (form): –
- Library / DB package calls: NIB.KEY_EXIT

```plsql
/* CGAP$TES_SEQUENCE_BEFORE */
/*DECLARE
	PROP VARCHAR2(10);
	RET  VARCHAR2(50);
BEGIN
	  PROP := GET_ITEM_PROPERTY('SAVE',VISIBLE);

	    IF PROP = 'TRUE' AND :GLOBAL.EXIT = 0 THEN
	    	  	 EXIT_FORM(NO_VALIDATE);

      ELSIF PROP = 'TRUE' AND :GLOBAL.EXIT = 0 AND :SYSTEM.FORM_STATUS IN ('QUERY','NEW','CHANGED') AND :SYSTEM.RECORD_STATUS != 'CHANGED' THEN
         EXIT_FORM(NO_VALIDATE);

	   ELSE
		SET_ITEM_PROPERTY('SAVE',VISIBLE,PROPERTY_TRUE);
    SET_ITEM_PROPERTY('EXIT',VISIBLE,PROPERTY_TRUE);
    SET_ITEM_PROPERTY('CLEAR_ALL',VISIBLE,PROPERTY_TRUE);
    SET_ITEM_PROPERTY('REMOVE',VISIBLE,PROPERTY_TRUE);
    SET_ITEM_PROPERTY('LIST_VALUE',VISIBLE,PROPERTY_TRUE);
    SET_ITEM_PROPERTY('HELP',VISIBLE,PROPERTY_TRUE);
    SET_ITEM_PROPERTY('ENTER',VISIBLE,PROPERTY_TRUE);
    SET_ITEM_PROPERTY('FUN_BUT',VISIBLE,PROPERTY_TRUE);
    SET_ITEM_PROPERTY('EXIT1',VISIBLE,PROPERTY_FALSE);
    SET_ITEM_PROPERTY('LAST_REC',VISIBLE,PROPERTY_FALSE);
    SET_ITEM_PROPERTY('FIRST_REC',VISIBLE,PROPERTY_FALSE);
    SET_ITEM_PROPERTY('RE_ENTER_QUERY',VISIBLE,PROPERTY_FALSE);
    SET_ITEM_PROPERTY('PAGE_UP',VISIBLE,PROPERTY_FALSE);
    SET_ITEM_PROPERTY('PAGE_DOWN',VISIBLE,PROPERTY_FALSE);
    SET_ITEM_PROPERTY('EXECUTE',VISIBLE,PROPERTY_FALSE);
    SET_ITEM_PROPERTY('SAVE',ENABLED,PROPERTY_TRUE);
    SET_ITEM_PROPERTY('EXIT',ENABLED,PROPERTY_TRUE);
    SET_ITEM_PROPERTY('CLEAR_ALL',ENABLED,PROPERTY_TRUE);
    SET_ITEM_PROPERTY('REMOVE',ENABLED,PROPERTY_TRUE);
    SET_ITEM_PROPERTY('LIST_VALUE',ENABLED,PROPERTY_TRUE);
    SET_ITEM_PROPERTY('HELP',ENABLED,PROPERTY_TRUE);
    SET_ITEM_PROPERTY('ENTER',ENABLED,PROPERTY_TRUE);
    TMPLT.ENB_DIS_FUN_BUT;
    KEY_CONTROL.FOUND_KEY;

    IF (:SYSTEM.MODE = 'NORMAL' ) THEN

      	SET_FORM_PROPERTY(:SYSTEM.CURRENT_FORM , VALIDATION_UNIT , FORM_SCOPE);
      	SET_FORM_PROPERTY(:SYSTEM.CURRENT_FORM , VALIDATION_UNIT , DEFAULT_SCOPE);
    ELSE
	      EXIT_FORM(NO_VALIDATE);
    END IF;
END IF;
END;
*/
NIB.KEY_EXIT;
```

#### FORM · WHEN-MOUSE-DOWN

- Level: Form · Owner: `FORM` · Execution hierarchy: default (Override) · Subclassed from CIC_OLB.olb:WHEN-MOUSE-DOWN
- Lines: 3 total / 1 active (non-blank, non-comment)
- Built-ins: –
- Program units (form): –
- Library / DB package calls: NIB.WHEN_MOUSE_DOWN

```plsql
/* CGAP$TES_SEQUENCE_BEFORE */
--TMPLT.MOUSE_DOWN;
NIB.WHEN_MOUSE_DOWN;
```

#### FORM · KEY-EXEQRY

- Level: Form · Owner: `FORM` · Execution hierarchy: default (Override) · Subclassed from CIC_OLB.olb:KEY-EXEQRY
- Lines: 17 total / 4 active (non-blank, non-comment)
- Built-ins: –
- Program units (form): –
- Library / DB package calls: NIB.KEY_EXEQRY

```plsql
/* CGAP$TES_SEQUENCE_BEFORE */
/*DECLARE
	PROP VARCHAR2(10);
BEGIN

	PROP := GET_ITEM_PROPERTY('SAVE',VISIBLE);
	IF PROP = 'FALSE' THEN
  	EXECUTE_QUERY(NO_VALIDATE);
	END IF;
END;
*/
NIB.KEY_EXEQRY;
/* CGBS$KEY_EXEQRY_FRM_MODIFIED */
/* Check if query is allowed to avoid unnecessary coordination */
BEGIN
NULL;
END;
```

#### FORM · KEY-F9

- Level: Form · Owner: `FORM` · Execution hierarchy: default (Override) · Subclassed from CIC_OLB.olb:KEY-F9
- Lines: 26 total / 23 active (non-blank, non-comment)
- Built-ins: COPY, GET_ITEM_PROPERTY, GET_VIEW_PROPERTY, GO_ITEM, NAME_IN, SET_VIEW_PROPERTY
- Program units (form): ADJ_FUNS
- Library / DB package calls: TMPLT.KEYB_UP_DOWN, TMPLT.POPULATE_FUNCTIONS

```plsql
/* CGAP$TES_SEQUENCE_BEFORE */
DECLARE
	PROP VARCHAR2(10);
	VIS VARCHAR2(200);
	V_FUN VARCHAR2(200);
BEGIN
		VIS    :=  GET_VIEW_PROPERTY('LSIDE', VISIBLE);
	  V_FUN  :=  GET_ITEM_PROPERTY('FUN_BUT',VISIBLE);

		IF VIS = 'TRUE' THEN
			SET_VIEW_PROPERTY('LSIDE', VISIBLE, PROPERTY_FALSE);
			GO_ITEM(NAME_IN('PARAMETER.P_CURRENT_ITEM'));
			COPY('', 'PARAMETER.P_CURRENT_ITEM');
		ELSE
			IF V_FUN = 'TRUE' THEN
	  	COPY(NAME_IN('SYSTEM.CURSOR_ITEM'), 'PARAMETER.P_CURRENT_ITEM');
			ADJ_FUNS;
	  	GO_ITEM('DUMMY');

			TMPLT.Populate_Functions;
			TMPLT.USING_KEYB := TRUE;
			TMPLT.CURSOR_AT := 1;
			TMPLT.KEYB_UP_DOWN(0);
			END IF;
		END IF;
END;
```

#### FORM · WHEN-TIMER-EXPIRED

- Level: Form · Owner: `FORM` · Execution hierarchy: default (Override) · Subclassed from CIC_OLB.olb:WHEN-TIMER-EXPIRED
- Lines: 48 total / 1 active (non-blank, non-comment)
- Built-ins: –
- Program units (form): –
- Library / DB package calls: NIB.WHEN_TIMER_EXPIRED

```plsql
/* CGAP$TES_SEQUENCE_BEFORE */
/*DECLARE
	THE_TIMER VARCHAR2(40) := GET_APPLICATION_PROPERTY(TIMER_NAME);
	TIMER_ID TIMER;
	v_inactive_time NUMBER;
	V_msg_count			NUMBER;
	RET							NUMBER;

BEGIN
  IF THE_TIMER = 'CHECKTIMEOUT' THEN
  	v_inactive_time := Win_API_Session.Timeout_get_inactive_time;
		IF v_inactive_time >= 600 then
			Win_API_Session.Timeout_Delete_Timer;
			:GLOBAL.G_TIME_OUT := 1;
			BELL;
			EXIT_FORM (NO_VALIDATE);
		ELSIF v_inactive_time >= 360 then
			BELL;
		END IF;
	ELSIF THE_TIMER = 'ON_ERROR_TIMER' THEN
		IF :PARAMETER.P_CURRENT_ITEM IS NOT NULL THEN
			GO_ITEM(NAME_IN('PARAMETER.P_CURRENT_ITEM'));
			COPY ('' , 'PARAMETER.P_CURRENT_ITEM');
		END IF;
		TIMER_ID := FIND_TIMER(THE_TIMER);
		DELETE_TIMER(TIMER_ID);
	  RAISE Form_Trigger_Failure;
	ELSIF THE_TIMER = 'ON_MESSAGE_TIMER' THEN
		IF :PARAMETER.P_CURRENT_ITEM IS NOT NULL THEN
			GO_ITEM(NAME_IN('PARAMETER.P_CURRENT_ITEM'));
			COPY ('' , 'PARAMETER.P_CURRENT_ITEM');
		END IF;

		TIMER_ID := FIND_TIMER(THE_TIMER);
		DELETE_TIMER(TIMER_ID);
	ELSIF THE_TIMER = 'EDI_MSG' THEN
			for_edi_msg(V_msg_count);
			IF V_msg_count > 0 THEN
					BELL;BELL;BELL;BELL;
					:EDI_MSG.EDI_MSG_TXT := 'توجد رسائل بعدد '|| V_msg_count ||' مطلوب اتخاذ اجراءات عليها';
					TURN_MSG;
				end if;
	ELSIF THE_TIMER = 'RETURN_EDI_MSG' THEN
					RETURN_MSG;
	END IF;
		WHEN_TIMER_EXPIRED_MSG;
END;*/
NIB.WHEN_TIMER_EXPIRED;
```

#### FORM · KEY-HELP

- Level: Form · Owner: `FORM` · Execution hierarchy: default (Override) · Fire in query: true
- Lines: 18 total / 16 active (non-blank, non-comment)
- Built-ins: –
- Program units (form): –
- Library / DB package calls: CGHP$CALL_MS_HELP, CGTE$OTHER_EXCEPTIONS, DES$FORM_ERRORS.MSGGETTEXT, DES$FORM_ERRORS.PUSH

```plsql
/* CGHP$CALL_HELP_FORM */
/* Call the help system after setting globals with current block and item */
BEGIN
  :GLOBAL.CG$HP_HFILE := '';
  IF (:GLOBAL.CG$HP_HFILE IS NULL) THEN
    Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(23, 'Help file is missing or incorrect'), 'W', 'OFG', 23);
  ELSE
    :GLOBAL.CG$HP_HFILE := :GLOBAL.CG$HP_HPATH || '';
    BEGIN
      CGHP$CALL_MS_HELP(
        0                      /* IN : Help Context Id                                                                                                                                                                                        */
       ,:GLOBAL.CG$HP_HFILE);  /* IN : Help Resource File                                                                                                                                                                                     */
    EXCEPTION
      WHEN OTHERS THEN
        CGTE$OTHER_EXCEPTIONS;
    END;
  END IF;
END;
```

#### FORM · WHEN-NEW-BLOCK-INSTANCE

- Level: Form · Owner: `FORM` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 5 total / 3 active (non-blank, non-comment)
- Built-ins: –
- Program units (form): –
- Library / DB package calls: CGBS$.NEW_BLOCK

```plsql
/* CGBS$WHEN_NEW_BLOCK_INSTANCE */
/* ensure the current canvas is correctly coordinated */
BEGIN
  CGBS$.NEW_BLOCK( :SYSTEM.CURSOR_BLOCK, :GLOBAL.CG$QUERY_MODE);
END;
```

#### FORM · ON-CLEAR-DETAILS

- Level: Form · Owner: `FORM` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 10 total / 8 active (non-blank, non-comment)
- Built-ins: FORM_FAILURE, RAISE FORM_TRIGGER_FAILURE
- Program units (form): –
- Library / DB package calls: CGBS$.CLEAR_MASTER_DETAIL

```plsql
/* CGBS$ON_CLEAR_DETAILS */
/* clear all detail blocks for the given master block */
BEGIN
  IF (FORM_FAILURE AND :SYSTEM.COORDINATION_OPERATION IN ('MOUSE', 'DUPLICATE_RECORD')) THEN
    RAISE FORM_TRIGGER_FAILURE;
  END IF;
  IF (:SYSTEM.MASTER_BLOCK = :SYSTEM.TRIGGER_BLOCK) THEN
    CGBS$.CLEAR_MASTER_DETAIL( :SYSTEM.MASTER_BLOCK, :SYSTEM.COORDINATION_OPERATION );
  END IF;
END;
```

#### FORM · ON-POPULATE-DETAILS

- Level: Form · Owner: `FORM` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 5 total / 3 active (non-blank, non-comment)
- Built-ins: –
- Program units (form): –
- Library / DB package calls: CGBS$.QUERY_DETAILS

```plsql
/* CGBS$ON_POPULATE_DETAILS */
/* query all detail blocks for the given master block */
BEGIN
  CGBS$.QUERY_DETAILS( :SYSTEM.CURSOR_BLOCK, :GLOBAL.CG$QUERY_MODE );
END;
```

#### FORM · KEY-CQUERY

- Level: Form · Owner: `FORM` · Execution hierarchy: default (Override) · Fire in query: true
- Lines: 9 total / 7 active (non-blank, non-comment)
- Built-ins: GET_BLOCK_PROPERTY
- Program units (form): –
- Library / DB package calls: CGBS$.DO_KEYQRY, DES$FORM_ERRORS.MSGGETTEXT, DES$FORM_ERRORS.PUSH, DES$FORM_ERRORS.RAISE_FAILURE

```plsql
/* CGBS$KEY_CQUERY_FRM */
/* Check if query is allowed to avoid unnecessary coordination */
BEGIN
  IF (get_block_property( :SYSTEM.TRIGGER_BLOCK, QUERY_ALLOWED) = 'FALSE') THEN
    Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(37, 'Query not allowed in this block'), 'E', 'OFG', 37);
    Des$Form_errors.RAISE_FAILURE;
  END IF;
  CGBS$.DO_KEYQRY( :SYSTEM.TRIGGER_BLOCK, 'COUNT_QUERY', :SYSTEM.MODE);
END;
```

#### FORM · KEY-CLRREC

- Level: Form · Owner: `FORM` · Execution hierarchy: default (Override) · Fire in query: true
- Lines: 11 total / 9 active (non-blank, non-comment)
- Built-ins: CLEAR_RECORD, RAISE FORM_TRIGGER_FAILURE
- Program units (form): –
- Library / DB package calls: CGBS2$.DO_COMMIT_DIALOGUE, CGBS2$.IS_COMMIT_NEEDED, CGBS2$.IS_RECORD_DIRTY

```plsql
/* CGBS$KEY_CLRREC */
/* Avoid clearing details if current row is new and invalid */
BEGIN
  IF ( CGBS2$.IS_RECORD_DIRTY(:SYSTEM.TRIGGER_BLOCK) ) THEN
    RAISE FORM_TRIGGER_FAILURE;
  END IF;
  IF (:SYSTEM.BLOCK_STATUS = 'CHANGED' OR CGBS2$.IS_COMMIT_NEEDED( :SYSTEM.TRIGGER_BLOCK ) ) THEN
    CGBS2$.DO_COMMIT_DIALOGUE;
  END IF;
  clear_record;
END;
```

#### FORM · KEY-NXTKEY

- Level: Form · Owner: `FORM` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 6 total / 4 active (non-blank, non-comment)
- Built-ins: –
- Program units (form): –
- Library / DB package calls: DES$FORM_ERRORS.MSGGETTEXT, DES$FORM_ERRORS.PUSH, DES$FORM_ERRORS.RAISE_FAILURE

```plsql
/* CGBS$DISABLE_NXTKEY */
/* Disable KEY-NXTKEY for the whole form */
BEGIN
  Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(30, 'Key not valid in this context'), 'E', 'OFG', 30);
  Des$Form_errors.RAISE_FAILURE;
END;
```

#### FORM · KEY-MENU

- Level: Form · Owner: `FORM` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 8 total / 3 active (non-blank, non-comment)
- Built-ins: –
- Program units (form): CGBS$TOGGLE
- Library / DB package calls: –

```plsql
/* CGBS$TOGGLE_QUERY_MODE */
/* This changes the mode of block synchronization so that if it is */
/* currently ON, then it is changed to OFF, and vice-versa.        */
/* It also queries the dependent blocks as appropriate for the     */
/* new mode.                                                       */
BEGIN
  CGBS$TOGGLE( :GLOBAL.CG$QUERY_MODE );
END;
```

#### FORM · KEY-CLRFRM

- Level: Form · Owner: `FORM` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 19 total / 14 active (non-blank, non-comment)
- Built-ins: CLEAR_FORM, RAISE FORM_TRIGGER_FAILURE
- Program units (form): CG$WHEN_NEW_FORM_INSTANCE
- Library / DB package calls: CGTE$OTHER_EXCEPTIONS

```plsql
/* CGGN$KEY_CLRFRM */
/* Perform the key's standard functionality */
BEGIN
  clear_form;
  IF :SYSTEM.FORM_STATUS = 'CHANGED' THEN
    RAISE FORM_TRIGGER_FAILURE;
  END IF;
END;

/* CGCF$PERFORM_STARTUP */
/* execute the when-new-form-instance code that was created by forms generator */
BEGIN
  BEGIN
    CG$WHEN_NEW_FORM_INSTANCE;
  EXCEPTION
    WHEN OTHERS THEN
      CGTE$OTHER_EXCEPTIONS;
  END;
END;
```

Triggers of this level without code in the XML (1):

| Block | Trigger | Count | Source status | Owners |
|---|---|---|---|---|
| FORM | KEY-F4 | 1 | OLB code (26 lines): `IF :SYSTEM.MODE <> 'ENTER-QUERY' THEN` | FORM |

### 6.2 Block-level triggers

#### TOOLBAR · KEY-DOWN

- Level: Block · Owner: `TOOLBAR` · Execution hierarchy: default (Override)
- Lines: 3 total / 3 active (non-blank, non-comment)
- Built-ins: –
- Program units (form): –
- Library / DB package calls: TMPLT.KEYB_UP_DOWN

```plsql
IF TMPLT.USING_KEYB = TRUE THEN
	TMPLT.KEYB_UP_DOWN(-1);
END IF;
```

#### TOOLBAR · KEY-UP

- Level: Block · Owner: `TOOLBAR` · Execution hierarchy: default (Override)
- Lines: 3 total / 3 active (non-blank, non-comment)
- Built-ins: –
- Program units (form): –
- Library / DB package calls: TMPLT.KEYB_UP_DOWN

```plsql
IF TMPLT.USING_KEYB = TRUE THEN
  TMPLT.KEYB_UP_DOWN(1);
END IF;
```

#### TOOLBAR · KEY-NEXT-ITEM

- Level: Block · Owner: `TOOLBAR` · Execution hierarchy: default (Override)
- Lines: 10 total / 10 active (non-blank, non-comment)
- Built-ins: COPY, GO_ITEM, NAME_IN, SET_ITEM_PROPERTY
- Program units (form): EXECUTE_FUNCTION
- Library / DB package calls: –

```plsql
BEGIN
IF TMPLT.USING_KEYB = TRUE THEN
		Set_Item_Property('LSIDE.FN'||TMPLT.CURSOR_AT, VISUAL_ATTRIBUTE, 'STD_NORMAL_FUNCTION');
		Execute_Function('LSIDE.FN'||TMPLT.CURSOR_AT);
		GO_ITEM(NAME_IN('PARAMETER.P_CURRENT_ITEM'));
		COPY ('', 'PARAMETER.P_CURRENT_ITEM');
		TMPLT.USING_KEYB := FALSE;
		TMPLT.CURSOR_AT := 0;
END IF;
END;
```

#### IMPORTERS · ON-ERROR

- Level: Block · Owner: `IMPORTERS` · Execution hierarchy: default (Override)
- Lines: 96 total / 76 active (non-blank, non-comment)
- Built-ins: DBMS_ERROR_CODE, DBMS_ERROR_TEXT, ERROR_CODE, ERROR_TEXT, ERROR_TYPE
- Program units (form): CGTE$CHECK_CONSTRAINT_VIO
- Library / DB package calls: CGTE$POP_ERROR_STACK, CGTE$STRIP_CONSTRAINT, DES$FORM_ERRORS.MSGGETTEXT, DES$FORM_ERRORS.PUSH, DES$FORM_ERRORS.RAISE_FAILURE

```plsql
/* CGAP$OLES_SEQUENCE_BEFORE */
BEGIN
  DECLARE
    err_code        CONSTANT NUMBER         := ERROR_CODE;
    err_type        CONSTANT VARCHAR2(3)    := ERROR_TYPE;
    server_err               NUMBER         := abs(DBMS_ERROR_CODE);
    server_msg               VARCHAR2(2000) := DBMS_ERROR_TEXT;
    constraint_name          VARCHAR2(61);
  BEGIN
  	IF server_err = 1031 THEN
IF (err_type = 'FRM' AND
        err_code = 40508 ) THEN
Des$Form_errors.PUSH('ليس لديك صلاحية الادخال ' ,'E', 'OFG',0);
END IF;
IF (err_type = 'FRM' AND
        err_code = 40509 ) THEN
Des$Form_errors.PUSH('ليس لديك صلاحية التعديل' ,'E', 'OFG',0);
END IF;
IF (err_type = 'FRM' AND
        err_code = 40510 ) THEN
Des$Form_errors.PUSH('ليس لديك صلاحية الحذف' ,'E', 'OFG',0);
END IF;
END IF;
  END;
  END;
/* CGTE$BLK_LEVEL_ERROR_TRAP */
/* Trap errors returning from the server and report in a user friendly manner */
BEGIN
  DECLARE
    err_code        CONSTANT NUMBER         := ERROR_CODE;
    err_type        CONSTANT VARCHAR2(3)    := ERROR_TYPE;
    server_err               NUMBER         := abs(DBMS_ERROR_CODE);
    server_msg               VARCHAR2(2000) := DBMS_ERROR_TEXT;
    constraint_name          VARCHAR2(61);
  BEGIN
    IF (err_type = 'FRM' AND
        err_code IN (40506, 40508, 40509, 40510) ) THEN

      /* Remove recursive errors from the top of the stack */
      WHILE (server_err = 604) LOOP
        CGTE$POP_ERROR_STACK(server_err, server_msg);
      END LOOP;

      /* Check and report the generic constraint violations */
      IF ( CGTE$CHECK_CONSTRAINT_VIO(server_err, server_msg) ) THEN
        Des$Form_errors.RAISE_FAILURE;
      END IF;

      /* Check and report the constraint violations specific to this block */
      constraint_name := CGTE$STRIP_CONSTRAINT(server_msg);

      /* FK - Parent key not found */
      IF (server_err = 2291) THEN
        IF (constraint_name = 'IMP_SDP_FK') THEN
          Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(13, 'This <p1> does not exist', 'Port Name' ), 'E', 'OFG', 13);
        ELSIF (constraint_name = 'IMP_NATIONALITY_FK') THEN
          Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(13, 'This <p1> does not exist', 'NATIONALITY' ), 'E', 'OFG', 13);
        ELSIF (constraint_name = 'IMP_MB_FK') THEN
          Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(13, 'This <p1> does not exist', 'BUS_ID_STATUS' ), 'E', 'OFG', 13);
        ELSIF (constraint_name = 'IMP_ITIDT_FK') THEN
          Des$Form_errors.PUSH('رمز النشاط التجاري غير صحيح - أعد إدخال البيانات', 'E', 'OFG', 0);
        ELSIF (constraint_name = 'IMP_IMP_FK') THEN
          Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(13, 'This <p1> does not exist', 'IMPR_NBR_PARENT,PORT_CD' ), 'E', 'OFG', 13);
        ELSIF (constraint_name = 'IMP_CTRY_FK') THEN
          Des$Form_errors.PUSH('رمز الدولة غير صحيح - أعد ادخال البيانات', 'E', 'OFG', 0);
        ELSIF (constraint_name = 'IMP_BUS_ID_CITY_FK') THEN
          Des$Form_errors.PUSH('خطأ في رمز مدينة مصدر الرقم الإستدلالي', 'E', 'OFG', 0);
        ELSIF (constraint_name = 'IMP_ADD_CITY_FK') THEN
          Des$Form_errors.PUSH('خطأ في رمز مدينة عنوان المستورد', 'E', 'OFG', 0);
        ELSE
          Des$Form_errors.PUSH(server_msg, 'I', 'OFG', 0);
        END IF;
        Des$Form_errors.RAISE_FAILURE;
      END IF;
    END IF;

    IF (err_type = 'FRM' AND
        err_code = 40735 ) THEN


      /* Remove recursive errors from the top of the stack */
      WHILE (server_err = 604) LOOP
        CGTE$POP_ERROR_STACK(server_err, server_msg);
      END LOOP;

      /* If error not found, issue default message */
      Des$Form_errors.PUSH(err_type||'-'||to_char(server_err)||': '||server_msg, 'I', 'OFG', 0);
      Des$Form_errors.RAISE_FAILURE;
    END IF;

    /* If error not found, issue default message */
    Des$Form_errors.PUSH(err_type||'-'||to_char(err_code)||': '||ERROR_TEXT, 'I', 'OFG', 0);
    Des$Form_errors.RAISE_FAILURE;

  END;
END;
```

#### IMPORTERS · POST-QUERY

- Level: Block · Owner: `IMPORTERS` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 73 total / 69 active (non-blank, non-comment)
- Built-ins: NAME_IN, SET_BLOCK_PROPERTY, SET_RECORD_PROPERTY
- Program units (form): CG$IMPR1120_GLOBALS, CGFK$QRY_IMPORTERS_IMP_BUS_ID_, CGFK$QRY_IMPORTERS_IMP_CTRY_FK, CGFK$QRY_IMPORTERS_IMP_ITIDT_F, CGFK$QRY_IMPORTERS_IMP_SDP_FK
- Library / DB package calls: CGTE$OTHER_EXCEPTIONS, DES$FORM_ERRORS.MSGGETTEXT, DES$FORM_ERRORS.PUSH, DES$FORM_ERRORS.RAISE_FAILURE

```plsql
/* CGFK$QRY_LOOKUP_DATA */
/* Query lookup data for the foreign key(s) */
BEGIN
  IF (name_in('IMPORTERS.PORT_CD') IS NOT NULL) THEN
    BEGIN
      CGFK$QRY_IMPORTERS_IMP_SDP_FK(
        :IMPORTERS.SDP_PORT_STATUS    /* MOD: Value in Item :IMPORTERS.SDP_PORT_STATUS.                                                                                                                                                       */
       ,:IMPORTERS.PORT_NAME          /* MOD: Value in Item :IMPORTERS.PORT_NAME.                                                                                                                                                             */
       ,:IMPORTERS.PORT_CD        );  /* IN : Value in Item :IMPORTERS.PORT_CD.                                                                                                                                                               */
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        Des$Form_errors.PUSH('رمز الجمرك غير صحيح - أعد إدخال البيانات', 'E', 'OFG', 0);
      WHEN OTHERS THEN
        CGTE$OTHER_EXCEPTIONS;
    END;
    SET_RECORD_PROPERTY(:SYSTEM.TRIGGER_RECORD, 'IMPORTERS', STATUS ,                 QUERY_STATUS);
  END IF;
  IF (name_in('IMPORTERS.IMPR_TYPE_CD') IS NOT NULL OR name_in('IMPORTERS.BUS_ID_TYPE_CD') IS NOT NULL) THEN
    BEGIN
      CGFK$QRY_IMPORTERS_IMP_ITIDT_F(
        :IMPORTERS.BUS_ID_TYPE_NAME    /* MOD: Value in Item :IMPORTERS.BUS_ID_TYPE_NAME.                                                                                                                                                     */
       ,:IMPORTERS.IMPR_TYPE_NAME      /* MOD: Value in Item :IMPORTERS.IMPR_TYPE_NAME.                                                                                                                                                       */
       ,:IMPORTERS.STATUS              /* MOD: Value in Item :IMPORTERS.STATUS.                                                                                                                                                               */
       ,:IMPORTERS.IMPR_TYPE_CD        /* IN : Value in Item :IMPORTERS.IMPR_TYPE_CD.                                                                                                                                                         */
       ,:IMPORTERS.BUS_ID_TYPE_CD  );  /* IN : Value in Item :IMPORTERS.BUS_ID_TYPE_CD.                                                                                                                                                       */
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        Des$Form_errors.PUSH('رمز النشاط التجاري غير صحيح - أعد إدخال البيانات', 'E', 'OFG', 0);
      WHEN OTHERS THEN
        CGTE$OTHER_EXCEPTIONS;
    END;
    SET_RECORD_PROPERTY(:SYSTEM.TRIGGER_RECORD, 'IMPORTERS', STATUS ,                 QUERY_STATUS);
  ELSE
      Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(78, '<p1> must be entered', 'رمز النشاط التجارى' ), 'E', 'OFG', 78);
      Des$Form_errors.RAISE_FAILURE;
  END IF;
  IF (name_in('IMPORTERS.CTRY_CD') IS NOT NULL) THEN
    BEGIN
      CGFK$QRY_IMPORTERS_IMP_CTRY_FK(
        :IMPORTERS.CTRY_CTRY_STATUS    /* MOD: Value in Item :IMPORTERS.CTRY_CTRY_STATUS.                                                                                                                                                     */
       ,:IMPORTERS.CRTY_ARBC_NAME      /* MOD: Value in Item :IMPORTERS.CRTY_ARBC_NAME.                                                                                                                                                       */
       ,:IMPORTERS.CTRY_CD         );  /* IN : Value in Item :IMPORTERS.CTRY_CD.                                                                                                                                                              */
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        Des$Form_errors.PUSH('رمز الدولة غير صحيح - أعد ادخال البيانات', 'E', 'OFG', 0);
      WHEN OTHERS THEN
        CGTE$OTHER_EXCEPTIONS;
    END;
    SET_RECORD_PROPERTY(:SYSTEM.TRIGGER_RECORD, 'IMPORTERS', STATUS ,                 QUERY_STATUS);
  END IF;
  IF (name_in('IMPORTERS.CITY_CODE_OF_ID') IS NOT NULL and name_in('IMPORTERS.CTRY_CD_OF_ID') IS NOT NULL) THEN
    BEGIN
      CGFK$QRY_IMPORTERS_IMP_BUS_ID_(
        :IMPORTERS.ID_CITY_NAME     /* MOD: Value in Item :IMPORTERS.ID_CITY_NAME.                                                                                                                                                          */
       ,:IMPORTERS.CTRY_CD_OF_ID    /* IN : Value in Item :IMPORTERS.CTRY_CD_OF_ID.                                                                                                                                                         */
       ,:IMPORTERS.CITY_CODE_OF_ID);/* IN : Value in Item :IMPORTERS.CITY_CODE_OF_ID.                                                                                                                                                       */
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        Des$Form_errors.PUSH('خطأ في رمز مدينة مصدر الرقم الإستدلالي', 'E', 'OFG', 0);
      WHEN OTHERS THEN
        CGTE$OTHER_EXCEPTIONS;
    END;
    SET_RECORD_PROPERTY(:SYSTEM.TRIGGER_RECORD, 'IMPORTERS', STATUS ,                 QUERY_STATUS);
  END IF;
END;
/* CGFK$RESET_BLOCK_WHERE_CLAUSE */
/* Resets block where clause */
BEGIN
  IF (CG$IMPR1120_GLOBALS.IMPORTERS_WHERE <> 'first_time') THEN
    set_block_property('IMPORTERS', DEFAULT_WHERE, CG$IMPR1120_GLOBALS.IMPORTERS_WHERE);
    CG$IMPR1120_GLOBALS.IMPORTERS_WHERE := 'first_time';
  END IF;
END;
```

#### IMPORTERS · PRE-QUERY

- Level: Block · Owner: `IMPORTERS` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 78 total / 63 active (non-blank, non-comment)
- Built-ins: FIND_BLOCK, GET_BLOCK_PROPERTY, NAME_IN, SET_BLOCK_PROPERTY
- Program units (form): CG$IMPR1120_GLOBALS
- Library / DB package calls: CG$IMPR1120_GLOBALS.IMPORTERS_WHERE, DES$FORM_ERRORS.MSGGETTEXT, DES$FORM_ERRORS.PUSH, DES$FORM_ERRORS.RAISE_FAILURE, STR.STRFORMAT

```plsql
BEGIN
	IF (:global.Exec_Query_Now = 1) THEN

		IF (:global.IMPR_NBR IS NOT NULL ) THEN
			:IMPORTERS.PORT_CD  := :global.PORT_CD;
			:IMPORTERS.IMPR_NBR  := :global.IMPR_NBR;
		END IF;

		:global.Exec_Query_Now := 0;
		:global.PORT_CD  := NULL;
		:global.IMPR_NBR  := NULL;
	ELSE

		:IMPR_NAME_STD := STR.StrFormat(:ARBC_IMPR_NAME, TRUE);
		:ARBC_IMPR_NAME := '';
	END IF;

END;


IF :PARAMETER.P_CURR_PORT_CD != 99 THEN
 :IMPORTERS.PORT_CD := :PARAMETER.P_CURR_PORT_CD;
END IF;
/* CGFK$DEFAULT_WHERE */
/* Add restrictive query on FK items if value(s) entered in non-table items    */
/* and/or if there are items which may contain nulls as valid values.  Code to */
/* restrict the query is added to the default where clause of the block.       */
BEGIN
  DECLARE
    block_id   Block := find_block('IMPORTERS');
    sub_where  VARCHAR2(4000) := NULL;
    def_where  VARCHAR2(4000) := NULL;
    r_string   VARCHAR2(512) := NULL;

    FUNCTION add_and(
      P_WHERE IN VARCHAR2
    ) RETURN VARCHAR2 IS
    BEGIN
      IF (nvl( length(P_WHERE), 0) != 0) THEN
        RETURN( P_WHERE || ' AND ');
      ELSE
        RETURN( P_WHERE );
      END IF;
    END;

  BEGIN
    IF ( CG$IMPR1120_GLOBALS.IMPORTERS_WHERE = 'first_time') THEN
      CG$IMPR1120_GLOBALS.IMPORTERS_WHERE := get_block_property(block_id, DEFAULT_WHERE);
    END IF;
    def_where := CG$IMPR1120_GLOBALS.IMPORTERS_WHERE;

    sub_where := NULL;
    r_string := NAME_IN('IMPORTERS.PORT_NAME');
    IF (r_string IS NOT NULL) THEN
      BEGIN
        IF substr(r_string, 1,1) IN ('<','>','=') THEN
          sub_where := add_and( sub_where ) || '(PORT_NAME '|| r_string || ')';
        ELSIF substr(r_string, 1,1) ='#' THEN
          sub_where := add_and( sub_where ) || '(PORT_NAME '|| substr(r_string,2) || ')';
        ELSIF instr(r_string, '%') <> 0 THEN
          sub_where := add_and( sub_where ) || '(PORT_NAME LIKE '''|| replace(r_string,'''','''''') || ''')';
        ELSE
          sub_where := add_and( sub_where ) || '(PORT_NAME ='''|| replace(r_string,'''','''''') || ''')';
        END IF;
      END;
    END IF;
    IF (sub_where IS NOT NULL) THEN
      def_where := add_and( def_where ) || '((PORT_CD) IN '||'(SELECT PORT_CD '||'FROM SD_PORTS WHERE '|| sub_where || '))';
    END IF;

    set_block_property(block_id, DEFAULT_WHERE, def_where);

  EXCEPTION
    WHEN VALUE_ERROR THEN
      Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(33, 'Query criteria too complex - simplify and re-query'), 'E', 'OFG', 33);
      Des$Form_errors.RAISE_FAILURE;
  END;
END;
```

#### IMPORTERS · KEY-HELP

- Level: Block · Owner: `IMPORTERS` · Execution hierarchy: default (Override) · Fire in query: true
- Lines: 102 total / 100 active (non-blank, non-comment)
- Built-ins: –
- Program units (form): –
- Library / DB package calls: CGHP$CALL_MS_HELP, CGTE$OTHER_EXCEPTIONS, DES$FORM_ERRORS.MSGGETTEXT, DES$FORM_ERRORS.PUSH

```plsql
/* CGHP$CALL_HELP_FORM */
/* Call the help system after setting globals with current block and item */
BEGIN
  :GLOBAL.CG$HP_HFILE := '';
  IF (:GLOBAL.CG$HP_HFILE IS NULL) THEN
    Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(23, 'Help file is missing or incorrect'), 'W', 'OFG', 23);
  ELSE
    :GLOBAL.CG$HP_HFILE := :GLOBAL.CG$HP_HPATH || '';
    BEGIN
      CGHP$CALL_MS_HELP(
        0                      /* IN : Help Context Id                                                                                                                                                                                        */
       ,:GLOBAL.CG$HP_HFILE);  /* IN : Help Resource File                                                                                                                                                                                     */
    EXCEPTION
      WHEN OTHERS THEN
        CGTE$OTHER_EXCEPTIONS;
    END;
  END IF;
  :GLOBAL.CG$HP_HFILE := '';
  IF (:GLOBAL.CG$HP_HFILE IS NULL) THEN
    Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(23, 'Help file is missing or incorrect'), 'W', 'OFG', 23);
  ELSE
    :GLOBAL.CG$HP_HFILE := :GLOBAL.CG$HP_HPATH || '';
    BEGIN
      CGHP$CALL_MS_HELP(
        0                      /* IN : Help Context Id                                                                                                                                                                                        */
       ,:GLOBAL.CG$HP_HFILE);  /* IN : Help Resource File                                                                                                                                                                                     */
    EXCEPTION
      WHEN OTHERS THEN
        CGTE$OTHER_EXCEPTIONS;
    END;
  END IF;
  :GLOBAL.CG$HP_HFILE := '';
  IF (:GLOBAL.CG$HP_HFILE IS NULL) THEN
    Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(23, 'Help file is missing or incorrect'), 'W', 'OFG', 23);
  ELSE
    :GLOBAL.CG$HP_HFILE := :GLOBAL.CG$HP_HPATH || '';
    BEGIN
      CGHP$CALL_MS_HELP(
        0                      /* IN : Help Context Id                                                                                                                                                                                        */
       ,:GLOBAL.CG$HP_HFILE);  /* IN : Help Resource File                                                                                                                                                                                     */
    EXCEPTION
      WHEN OTHERS THEN
        CGTE$OTHER_EXCEPTIONS;
    END;
  END IF;
  :GLOBAL.CG$HP_HFILE := '';
  IF (:GLOBAL.CG$HP_HFILE IS NULL) THEN
    Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(23, 'Help file is missing or incorrect'), 'W', 'OFG', 23);
  ELSE
    :GLOBAL.CG$HP_HFILE := :GLOBAL.CG$HP_HPATH || '';
    BEGIN
      CGHP$CALL_MS_HELP(
        0                      /* IN : Help Context Id                                                                                                                                                                                        */
       ,:GLOBAL.CG$HP_HFILE);  /* IN : Help Resource File                                                                                                                                                                                     */
    EXCEPTION
      WHEN OTHERS THEN
        CGTE$OTHER_EXCEPTIONS;
    END;
  END IF;
  :GLOBAL.CG$HP_HFILE := '';
  IF (:GLOBAL.CG$HP_HFILE IS NULL) THEN
    Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(23, 'Help file is missing or incorrect'), 'W', 'OFG', 23);
  ELSE
    :GLOBAL.CG$HP_HFILE := :GLOBAL.CG$HP_HPATH || '';
    BEGIN
      CGHP$CALL_MS_HELP(
        0                      /* IN : Help Context Id                                                                                                                                                                                        */
       ,:GLOBAL.CG$HP_HFILE);  /* IN : Help Resource File                                                                                                                                                                                     */
    EXCEPTION
      WHEN OTHERS THEN
        CGTE$OTHER_EXCEPTIONS;
    END;
  END IF;
  :GLOBAL.CG$HP_HFILE := '';
  IF (:GLOBAL.CG$HP_HFILE IS NULL) THEN
    Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(23, 'Help file is missing or incorrect'), 'W', 'OFG', 23);
  ELSE
    :GLOBAL.CG$HP_HFILE := :GLOBAL.CG$HP_HPATH || '';
    BEGIN
      CGHP$CALL_MS_HELP(
        0                      /* IN : Help Context Id                                                                                                                                                                                        */
       ,:GLOBAL.CG$HP_HFILE);  /* IN : Help Resource File                                                                                                                                                                                     */
    EXCEPTION
      WHEN OTHERS THEN
        CGTE$OTHER_EXCEPTIONS;
    END;
  END IF;
  :GLOBAL.CG$HP_HFILE := '';
  IF (:GLOBAL.CG$HP_HFILE IS NULL) THEN
    Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(23, 'Help file is missing or incorrect'), 'W', 'OFG', 23);
  ELSE
    :GLOBAL.CG$HP_HFILE := :GLOBAL.CG$HP_HPATH || '';
    BEGIN
      CGHP$CALL_MS_HELP(
        0                      /* IN : Help Context Id                                                                                                                                                                                        */
       ,:GLOBAL.CG$HP_HFILE);  /* IN : Help Resource File                                                                                                                                                                                     */
    EXCEPTION
      WHEN OTHERS THEN
        CGTE$OTHER_EXCEPTIONS;
    END;
  END IF;
END;
```

#### IMPORTERS · WHEN-CREATE-RECORD

- Level: Block · Owner: `IMPORTERS` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 10 total / 7 active (non-blank, non-comment)
- Built-ins: –
- Program units (form): –
- Library / DB package calls: –

```plsql
BEGIN
	:IMPORTERS.PORT_CD := :PARAMETER.P_CURR_PORT_CD;


	SELECT PORT_NAME
	INTO :IMPORTERS.PORT_NAME
	FROM SD_PORTS
	WHERE PORT_CD = :IMPORTERS.PORT_CD;

END;
```

#### IMPR_SUSPN · ON-ERROR

- Level: Block · Owner: `IMPR_SUSPN` · Execution hierarchy: default (Override) · Fire in query: true
- Lines: 78 total / 56 active (non-blank, non-comment)
- Built-ins: DBMS_ERROR_CODE, DBMS_ERROR_TEXT, ERROR_CODE, ERROR_TEXT, ERROR_TYPE
- Program units (form): CGTE$CHECK_CONSTRAINT_VIO
- Library / DB package calls: CGTE$POP_ERROR_STACK, CGTE$STRIP_CONSTRAINT, DES$FORM_ERRORS.MSGGETTEXT, DES$FORM_ERRORS.PUSH, DES$FORM_ERRORS.RAISE_FAILURE

```plsql
/* CGTE$BLK_LEVEL_ERROR_TRAP */
/* Trap errors returning from the server and report in a user friendly manner */
BEGIN
  DECLARE
    err_code        CONSTANT NUMBER         := ERROR_CODE;
    err_type        CONSTANT VARCHAR2(3)    := ERROR_TYPE;
    server_err               NUMBER         := abs(DBMS_ERROR_CODE);
    server_msg               VARCHAR2(2000) := DBMS_ERROR_TEXT;
    constraint_name          VARCHAR2(61);
  BEGIN
    IF (err_type = 'FRM' AND
        err_code IN (40506, 40508, 40509, 40510) ) THEN

      /* Remove recursive errors from the top of the stack */
      WHILE (server_err = 604) LOOP
        CGTE$POP_ERROR_STACK(server_err, server_msg);
      END LOOP;

      /* Check and report the generic constraint violations */
      IF ( CGTE$CHECK_CONSTRAINT_VIO(server_err, server_msg) ) THEN
        Des$Form_errors.RAISE_FAILURE;
      END IF;

      /* Check and report the constraint violations specific to this block */
      constraint_name := CGTE$STRIP_CONSTRAINT(server_msg);

      /* FK - Parent key not found */
      IF (server_err = 2291) THEN
        IF (constraint_name = 'IS_1_IMP_FK') THEN
          Des$Form_errors.PUSH('بيانات الربط مع ملف المستوردين غير صحيحة - أعد إدخال البيانات', 'E', 'OFG', 0);
        ELSE
          Des$Form_errors.PUSH(server_msg, 'I', 'OFG', 0);
        END IF;
        Des$Form_errors.RAISE_FAILURE;
      END IF;

      /* FK - Child record found */
      IF (server_err = 2292) THEN
        IF (err_code = 40510) THEN
          Des$Form_errors.PUSH(server_msg, 'I', 'OFG', 0);
        ELSIF (err_code = 40509) THEN
          Des$Form_errors.PUSH(server_msg, 'I', 'OFG', 0);
        END IF;
        Des$Form_errors.RAISE_FAILURE;
      END IF;
    END IF;

    IF (err_type = 'FRM' AND
        err_code IN (41105, 41106) ) THEN
      IF (err_code = 41105) THEN
      Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(35, 'Query of <p1> must be in context of <p2>', 'توقيفات المستوردين','جدول المستوردين' ), 'E', 'OFG', 35);
      Des$Form_errors.RAISE_FAILURE;
    ELSIF (err_code = 41106) THEN
      Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(36, 'Insert of <p1> must be in context of <p2>', 'توقيفات المستوردين','جدول المستوردين' ), 'E', 'OFG', 36);
      Des$Form_errors.RAISE_FAILURE;
      END IF;
    END IF;

    IF (err_type = 'FRM' AND
        err_code = 40735 ) THEN


      /* Remove recursive errors from the top of the stack */
      WHILE (server_err = 604) LOOP
        CGTE$POP_ERROR_STACK(server_err, server_msg);
      END LOOP;

      /* If error not found, issue default message */
      Des$Form_errors.PUSH(err_type||'-'||to_char(server_err)||': '||server_msg, 'I', 'OFG', 0);
      Des$Form_errors.RAISE_FAILURE;
    END IF;

    /* If error not found, issue default message */
    Des$Form_errors.PUSH(err_type||'-'||to_char(err_code)||': '||ERROR_TEXT, 'I', 'OFG', 0);
    Des$Form_errors.RAISE_FAILURE;

  END;
END;
```

#### IMPR_SUSPN · KEY-HELP

- Level: Block · Owner: `IMPR_SUSPN` · Execution hierarchy: default (Override) · Fire in query: true
- Lines: 18 total / 16 active (non-blank, non-comment)
- Built-ins: –
- Program units (form): –
- Library / DB package calls: CGHP$CALL_MS_HELP, CGTE$OTHER_EXCEPTIONS, DES$FORM_ERRORS.MSGGETTEXT, DES$FORM_ERRORS.PUSH

```plsql
/* CGHP$CALL_HELP_FORM */
/* Call the help system after setting globals with current block and item */
BEGIN
  :GLOBAL.CG$HP_HFILE := '';
  IF (:GLOBAL.CG$HP_HFILE IS NULL) THEN
    Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(23, 'Help file is missing or incorrect'), 'W', 'OFG', 23);
  ELSE
    :GLOBAL.CG$HP_HFILE := :GLOBAL.CG$HP_HPATH || '';
    BEGIN
      CGHP$CALL_MS_HELP(
        0                      /* IN : Help Context Id                                                                                                                                                                                        */
       ,:GLOBAL.CG$HP_HFILE);  /* IN : Help Resource File                                                                                                                                                                                     */
    EXCEPTION
      WHEN OTHERS THEN
        CGTE$OTHER_EXCEPTIONS;
    END;
  END IF;
END;
```

#### IMPR_SUSPN · KEY-DELREC

- Level: Block · Owner: `IMPR_SUSPN` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 3 total / 3 active (non-blank, non-comment)
- Built-ins: –
- Program units (form): –
- Library / DB package calls: TMPLT.KEY_DELETE_RECORD

```plsql
BEGIN
	TMPLT.KEY_DELETE_RECORD;
END;
```

#### IMPR_SUSPN · ON-DELETE

- Level: Block · Owner: `IMPR_SUSPN` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 13 total / 11 active (non-blank, non-comment)
- Built-ins: RAISE FORM_TRIGGER_FAILURE
- Program units (form): –
- Library / DB package calls: ACTIVITY.ADD_ACTIVITY, HIJDATE.CUR_HIJ_DATE

```plsql
DECLARE
	HDATE DATE;
BEGIN
	HDATE := HIJDATE.CUR_HIJ_DATE;
	UPDATE IMPR_SUSPNS SET IMPR_SUSPNS.SUSPN_RLSE_DT = HDATE
		WHERE IMPR_SUSPNS.IMPR_NBR = :IMPR_SUSPN.IMPR_NBR
		AND   IMPR_SUSPNS.SUSPN_SEQ =:IMPR_SUSPN.SUSPN_SEQ;

IF NOT ACTIVITY.ADD_ACTIVITY(9, 3, 3, :IMPR_SUSPN.PORT_CD||'!'||:IMPR_SUSPN.IMPR_NBR||'!'||:IMPR_SUSPN.SUSPN_SEQ) THEN
	RAISE FORm_Trigger_Failure;
END IF;

END;
```

#### IMPR_SUSPN · POST-INSERT

- Level: Block · Owner: `IMPR_SUSPN` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 68 total / 58 active (non-blank, non-comment)
- Built-ins: SET_ITEM_PROPERTY, COMMIT (DB)
- Program units (form): –
- Library / DB package calls: GNRL.GET_CUSTOMS_SETTING, LIB_APX_USR.APEX_NOTIFICATIONS.SEND_SMS_EMAIL_NOTIFY, SMS_MESSAGE.SEND_SMS_MESSAGE

```plsql
DECLARE
V_MOBILE_NBR NUMBER;
V_SMS_MSG_BODY VARCHAR2(2000);
Var_Recipient_Type     NUMBER; -- CR-8414
Var_Note_Priority      VARCHAR2 (32767); -- CR-8414
Var_Status             NUMBER; -- CR-8414
Var_P_Message          VARCHAR2 (32767); -- CR-8414
V_Ne_In_Send      VARCHAR2 (4000);  --CR8414  NE_INTEGRATION
V_Bus_Id        VARCHAR2(15) ; -- CR-8414
V_Org_Hotline   NUMBER;                                     -- CR-8414
V_Org_Name      VARCHAR2 (500);  -- CR-8414
BEGIN
	-- CR-8414
   V_ORG_HOTLINE   := 19993;
  V_ORG_NAME      := 'https://zatca.gov.sa';
  SELECT MOBILE_NO INTO V_MOBILE_NBR FROM IMPORTER_BASIC_DATA
WHERE HQ_IMPR_NBR = :HQ_IMPR_NBR AND ROWNUM=1 AND MOBILE_NO IS NOT NULL;

 IF NVL (gnrl.get_customs_setting (:IMPR_SUSPN.PORT_CD ,'NE_INTEGRATION', 21), 0)= 1    THEN   --CR-8414 5 accept message diffrent

                        V_NE_IN_SEND :='P_PORT_NAME=' ||:PORT_NAME
                        					   ||',P_BUS_ID=' || :BUS_ID
                        					   ||',P_SUSPN_STRT_DT=' || TO_CHAR(:SUSPN_STRT_DT,'MI-MM-YYYY')
                        					   ||',P_SUSPN_END_DT=' || TO_CHAR(:SUSPN_END_DT,'MI-MM-YYYY')
                        					   ||',P_SUSPN_RSN_TEXT=' || :SUSPN_RSN_TEXT
                       							 ||',ORG_HOTLINE=' ||V_ORG_HOTLINE
                                     ||',ORG_NAME=' ||V_ORG_NAME                          ;
    -- Call
   LIB_APX_USR.APEX_NOTIFICATIONS.SEND_SMS_EMAIL_NOTIFY (
      PORT_CODE          => :PARAMETER.P_CURR_PORT_CD,
      EVENT_CODE         => 'IMPR_010',
      TO_EMAIL           => NULL,
      TO_MOBILE_NO       =>V_MOBILE_NBR ,
      TO_ID_NO           =>:BUS_ID,
      RECIPIENT_TYPE     => var_RECIPIENT_TYPE,
      NOTE_PRIORITY      => var_NOTE_PRIORITY,
      MESSAGE_LANGUAGE   => NULL,
      VARIABLES          => V_NE_IN_SEND,
      JSON_ATTACH        => NULL,
      ATTACH_TYPE        => NULL,
      ATTACH_NAME        => NULL,
      ATTACH_CATEGORY    => NULL,
      STATUS             => var_STATUS,
      P_MESSAGE          => var_P_MESSAGE);
ELSE


V_SMS_MSG_BODY:=' تم الايقاف من قبل '||:PORT_NAME||' للسجل التجاري '||:BUS_ID||
' من تاريخ '||TO_CHAR(:SUSPN_STRT_DT,'MI-MM-YYYY')||' الى تاريخ '||TO_CHAR(:SUSPN_END_DT,'MI-MM-YYYY')||
' بسبب '||:SUSPN_RSN_TEXT;

SMS_MESSAGE.SEND_SMS_MESSAGE(9,3,1,:PARAMETER.P_CURR_PORT_CD,NULL,V_MOBILE_NBR,
V_SMS_MSG_BODY,:IMPR_SUSPN.PORT_CD||'|'||:IMPR_SUSPN.IMPR_NBR||'|'||:IMPR_SUSPN.SUSPN_SEQ);
END IF ;

STANDARD.COMMIT;
EXCEPTION WHEN OTHERS THEN NULL;
END;

--ADDED BY ABDALLAH
BEGIN
  IF :IMPR_SUSPN.SUSPN_SIDE_CD IS NOT NULL THEN
    SET_ITEM_PROPERTY('IMPR_SUSPN.SUSPN_SIDE_CD', ENABLED, PROPERTY_FALSE);
  ELSE
    SET_ITEM_PROPERTY('IMPR_SUSPN.SUSPN_SIDE_CD', ENABLED,   PROPERTY_TRUE);
    SET_ITEM_PROPERTY('IMPR_SUSPN.SUSPN_SIDE_CD', NAVIGABLE, PROPERTY_TRUE);
  END IF;
END;
```

#### IMPR_SUSPN · POST-QUERY

- Level: Block · Owner: `IMPR_SUSPN` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 9 total / 8 active (non-blank, non-comment)
- Built-ins: SET_ITEM_PROPERTY
- Program units (form): –
- Library / DB package calls: –

```plsql
--ADDED BY ABDALLAH
BEGIN
  IF :IMPR_SUSPN.SUSPN_SIDE_CD IS NOT NULL THEN
    SET_ITEM_PROPERTY('IMPR_SUSPN.SUSPN_SIDE_CD', ENABLED,   PROPERTY_FALSE);
  ELSE
    SET_ITEM_PROPERTY('IMPR_SUSPN.SUSPN_SIDE_CD', ENABLED,   PROPERTY_TRUE);
    SET_ITEM_PROPERTY('IMPR_SUSPN.SUSPN_SIDE_CD', NAVIGABLE, PROPERTY_TRUE);
  END IF;
END;
```

#### IMPR_SUSPN · PRE-INSERT

- Level: Block · Owner: `IMPR_SUSPN` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 14 total / 13 active (non-blank, non-comment)
- Built-ins: RAISE FORM_TRIGGER_FAILURE
- Program units (form): –
- Library / DB package calls: ACTIVITY.ADD_ACTIVITY

```plsql
BEGIN
	IF (:IMPR_SUSPN.SUSPN_SEQ)IS NULL THEN
		SELECT MAX(IMPR_SUSPNS.SUSPN_SEQ) + 1
		INTO :IMPR_SUSPN.SUSPN_SEQ
		FROM IMPR_SUSPNS;
		IF :IMPR_SUSPN.SUSPN_SEQ IS NULL THEN
			:IMPR_SUSPN.SUSPN_SEQ := 1;
		END IF;
	END IF;
IF NOT ACTIVITY.ADD_ACTIVITY(9, 3, 1, :IMPR_SUSPN.PORT_CD||'!'||:IMPR_SUSPN.IMPR_NBR||'!'||:IMPR_SUSPN.SUSPN_SEQ) THEN
	RAISE FORm_Trigger_Failure;
END IF;

END;
```

#### IMPR_SUSPN · PRE-UPDATE

- Level: Block · Owner: `IMPR_SUSPN` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 27 total / 22 active (non-blank, non-comment)
- Built-ins: RAISE FORM_TRIGGER_FAILURE
- Program units (form): –
- Library / DB package calls: ACTIVITY.ADD_ACTIVITY, HIJDATE_DB.CUR_HIJ_DATE

```plsql
BEGIN
IF NOT ACTIVITY.ADD_ACTIVITY(9, 3, 2, :IMPR_SUSPN.PORT_CD||'!'||:IMPR_SUSPN.IMPR_NBR||'!'||:IMPR_SUSPN.SUSPN_SEQ) THEN
	RAISE FORm_Trigger_Failure;
END IF;

END;


DECLARE
   h_date   DATE;
BEGIN
   h_date := hijdate_db.cur_hij_date;

   IF :impr_suspn.suspn_end_dt <= h_date
   THEN
      :impr_suspn.suspn_rlse_dt := :impr_suspn.suspn_end_dt;
   END IF;

   IF :impr_suspn.suspn_end_dt > h_date
   THEN
      :impr_suspn.suspn_rlse_dt := NULL;
   END IF;
EXCEPTION
   WHEN OTHERS
   THEN
      NULL;
END;
```

#### IMPR_SUSPN · WHEN-NEW-RECORD-INSTANCE

- Level: Block · Owner: `IMPR_SUSPN` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 41 total / 31 active (non-blank, non-comment)
- Built-ins: GO_ITEM, NEXT_RECORD, SET_ITEM_PROPERTY
- Program units (form): –
- Library / DB package calls: –

```plsql
--UPDATE BY ANAS --
-- 9-5-2005 --


BEGIN
      IF     :PARAMETER.Current_Side = 1 AND :PARAMETER.P_CURR_PORT_CD!=99  AND :IMPR_SUSPN.SUSPN_SIDE_CD <> 1 THEN
		   NEXT_RECORD;
	ELSIF  :PARAMETER.Current_Side = 2  AND :PARAMETER.P_CURR_PORT_CD!=99 AND :IMPR_SUSPN.SUSPN_SIDE_CD IN(1,5) THEN
		   NEXT_RECORD;
      ELSIF  :PARAMETER.Current_Side  =3 AND :PARAMETER.P_CURR_PORT_CD=99 AND :IMPR_SUSPN.SUSPN_SIDE_CD !=5 THEN
            NEXT_RECORD;

	END IF;

END;


--ADDED BY ABDALLAH
DECLARE
  V_SUSPN_SIDE_CD   NUMBER;
BEGIN
  BEGIN
    SELECT SUSPN_SIDE_CD
	INTO V_SUSPN_SIDE_CD
	FROM IMPR_SUSPNS
     WHERE PORT_CD   = :IMPR_SUSPN.PORT_CD
	 AND IMPR_NBR  = :IMPR_SUSPN.IMPR_NBR
	 AND SUSPN_SEQ = :IMPR_SUSPN.SUSPN_SEQ;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
    V_SUSPN_SIDE_CD := NULL;
  END;
  --
  IF V_SUSPN_SIDE_CD IS NOT NULL THEN
    GO_ITEM('IMPR_SUSPN.SUSPN_STRT_DT');
    SET_ITEM_PROPERTY('IMPR_SUSPN.SUSPN_SIDE_CD', ENABLED,   PROPERTY_FALSE);
  ELSE
    SET_ITEM_PROPERTY('IMPR_SUSPN.SUSPN_SIDE_CD', ENABLED,   PROPERTY_TRUE);
    SET_ITEM_PROPERTY('IMPR_SUSPN.SUSPN_SIDE_CD', NAVIGABLE, PROPERTY_TRUE);
  END IF;
END;
```

### 6.3 Item-level triggers

#### TITLE.SYSTEM_DATE · WHEN-VALIDATE-ITEM

- Level: Item · Owner: `TITLE.SYSTEM_DATE` · Execution hierarchy: default (Override)
- Lines: 13 total / 12 active (non-blank, non-comment)
- Built-ins: RAISE FORM_TRIGGER_FAILURE
- Program units (form): –
- Library / DB package calls: HIJDATE.VALID_HIJ_DATE

```plsql
DECLARE
	HDATE DATE;
BEGIN
	IF :System.TRIGGER_ITEM = :System.CURSOR_ITEM THEN
		IF :System.Cursor_Value IS NOT NULL THEN
			HDATE := TO_DATE(:System.Cursor_Value);

			IF NOT HIJDATE.VALID_HIJ_DATE(HDATE) THEN
				RAISE FORM_TRIGGER_FAILURE;
			END IF;
		END IF;
	END IF;
END;
```

#### TOOLBAR.SAVE · WHEN-BUTTON-PRESSED

- Level: Item · Owner: `TOOLBAR.SAVE` · Execution hierarchy: default (Override)
- Lines: 15 total / 12 active (non-blank, non-comment)
- Built-ins: BELL, CLOSE_FORM, FIND_FORM, ID_NULL, COMMIT (DB)
- Program units (form): –
- Library / DB package calls: HIJDATE.CUR_HIJ_DATE

```plsql
DECLARE
	RET NUMBER;

BEGIN
   BELL;
   COMMIT;

	IF NOT ID_NULL(FIND_FORM('SUPPORT_ENTRY')) AND :SYSTEM.FORM_STATUS = 'QUERY' THEN
   CLOSE_FORM('SUPPORT_ENTRY');
  END IF;

 	:title.user_name   := :PARAMETER.P_USER_NAME;
  :title.SCREEN_NAME := :PARAMETER.P_MODULE_NAME;
	:title.SYSTEM_DATE := HIJDATE.Cur_Hij_Date;
end;
```

#### TOOLBAR.EXIT · WHEN-BUTTON-PRESSED

- Level: Item · Owner: `TOOLBAR.EXIT` · Execution hierarchy: default (Override)
- Lines: 19 total / 15 active (non-blank, non-comment)
- Built-ins: CLOSE_FORM, EXIT_FORM, FIND_FORM, GET_ITEM_PROPERTY, ID_NULL, RAISE FORM_TRIGGER_FAILURE
- Program units (form): –
- Library / DB package calls: STR.DISPALERT

```plsql
DECLARE
	RET  VARCHAR2(10);
	PROP VARCHAR2(10);
BEGIN
	IF NOT ID_NULL(FIND_FORM('SUPPORT_ENTRY')) THEN
   CLOSE_FORM('SUPPORT_ENTRY');
  END IF;

IF :GLOBAL.EXIT = 2 THEN
 RET := STR.DISPAlert('يجب ادخال بنود للتعهد او حذف التعهد','INFORMATION');
  	  RAISE FORM_TRIGGER_FAILURE;

ELSIF :GLOBAL.EXIT = 0 THEN
 PROP := GET_ITEM_PROPERTY('SAVE',VISIBLE);

       EXIT_FORM(NO_VALIDATE);

END IF;
END;
```

#### TOOLBAR.EXIT1 · WHEN-BUTTON-PRESSED

- Level: Item · Owner: `TOOLBAR.EXIT1` · Execution hierarchy: default (Override)
- Lines: 42 total / 38 active (non-blank, non-comment)
- Built-ins: CLOSE_FORM, EXIT_FORM, FIND_FORM, ID_NULL, SET_FORM_PROPERTY, SET_ITEM_PROPERTY
- Program units (form): –
- Library / DB package calls: HIJDATE.CUR_HIJ_DATE, KEY_CONTROL.FOUND_KEY, TMPLT.ENB_DIS_FUN_BUT

```plsql
SET_ITEM_PROPERTY('SAVE',VISIBLE,PROPERTY_TRUE);
SET_ITEM_PROPERTY('EXIT',VISIBLE,PROPERTY_TRUE);
SET_ITEM_PROPERTY('CLEAR_ALL',VISIBLE,PROPERTY_TRUE);
SET_ITEM_PROPERTY('REMOVE',VISIBLE,PROPERTY_TRUE);
SET_ITEM_PROPERTY('LIST_VALUE',VISIBLE,PROPERTY_TRUE);
SET_ITEM_PROPERTY('HELP',VISIBLE,PROPERTY_TRUE);
SET_ITEM_PROPERTY('ENTER',VISIBLE,PROPERTY_TRUE);
SET_ITEM_PROPERTY('FUN_BUT',VISIBLE,PROPERTY_TRUE);
SET_ITEM_PROPERTY('EXIT1',VISIBLE,PROPERTY_FALSE);
SET_ITEM_PROPERTY('LAST_REC',VISIBLE,PROPERTY_FALSE);
SET_ITEM_PROPERTY('FIRST_REC',VISIBLE,PROPERTY_FALSE);
SET_ITEM_PROPERTY('RE_ENTER_QUERY',VISIBLE,PROPERTY_FALSE);
SET_ITEM_PROPERTY('PAGE_UP',VISIBLE,PROPERTY_FALSE);
SET_ITEM_PROPERTY('PAGE_DOWN',VISIBLE,PROPERTY_FALSE);
SET_ITEM_PROPERTY('EXECUTE',VISIBLE,PROPERTY_FALSE);
SET_ITEM_PROPERTY('SAVE',ENABLED,PROPERTY_TRUE);
SET_ITEM_PROPERTY('EXIT',ENABLED,PROPERTY_TRUE);
SET_ITEM_PROPERTY('CLEAR_ALL',ENABLED,PROPERTY_TRUE);
SET_ITEM_PROPERTY('REMOVE',ENABLED,PROPERTY_TRUE);
SET_ITEM_PROPERTY('LIST_VALUE',ENABLED,PROPERTY_TRUE);
SET_ITEM_PROPERTY('HELP',ENABLED,PROPERTY_TRUE);
SET_ITEM_PROPERTY('ENTER',ENABLED,PROPERTY_TRUE);
KEY_CONTROL.FOUND_KEY;
TMPLT.ENB_DIS_FUN_BUT;

	IF NOT ID_NULL(FIND_FORM('SUPPORT_ENTRY')) THEN
   CLOSE_FORM('SUPPORT_ENTRY');
  END IF;

IF (:SYSTEM.MODE = 'NORMAL' ) THEN

  	SET_FORM_PROPERTY(:SYSTEM.CURRENT_FORM , VALIDATION_UNIT , FORM_SCOPE);
  	SET_FORM_PROPERTY(:SYSTEM.CURRENT_FORM , VALIDATION_UNIT , DEFAULT_SCOPE);
  ELSE
  	EXIT_FORM(NO_VALIDATE);
  END IF;

begin
 	:title.user_name := :PARAMETER.P_USER_NAME;
	:title.SCREEN_NAME :=:PARAMETER.P_MODULE_NAME;
	:title.SYSTEM_DATE := HIJDATE.Cur_Hij_Date;
end;
```

#### TOOLBAR.LAST_REC · WHEN-BUTTON-PRESSED

- Level: Item · Owner: `TOOLBAR.LAST_REC` · Execution hierarchy: default (Override)
- Lines: 1 total / 1 active (non-blank, non-comment)
- Built-ins: DO_KEY
- Program units (form): –
- Library / DB package calls: –

```plsql
do_key('Next_Record');
```

#### TOOLBAR.RE_ENTER_QUERY · WHEN-BUTTON-PRESSED

- Level: Item · Owner: `TOOLBAR.RE_ENTER_QUERY` · Execution hierarchy: default (Override)
- Lines: 6 total / 6 active (non-blank, non-comment)
- Built-ins: ENTER_QUERY
- Program units (form): –
- Library / DB package calls: HIJDATE.CUR_HIJ_DATE

```plsql
ENTER_QUERY ( NO_VALIDATE );
begin
 	:title.user_name := :PARAMETER.P_USER_NAME;
	:title.SCREEN_NAME :=:PARAMETER.P_MODULE_NAME;
	:title.SYSTEM_DATE := HIJDATE.Cur_Hij_Date;
end;
```

#### TOOLBAR.PAGE_DOWN · WHEN-BUTTON-PRESSED

- Level: Item · Owner: `TOOLBAR.PAGE_DOWN` · Execution hierarchy: default (Override)
- Lines: 1 total / 1 active (non-blank, non-comment)
- Built-ins: DO_KEY
- Program units (form): –
- Library / DB package calls: –

```plsql
  do_key('Scroll_Down');
```

#### TOOLBAR.FUN_BUT · WHEN-MOUSE-UP

- Level: Item · Owner: `TOOLBAR.FUN_BUT` · Execution hierarchy: default (Override)
- Lines: 15 total / 12 active (non-blank, non-comment)
- Built-ins: COPY, GET_VIEW_PROPERTY, GO_ITEM, NAME_IN, SET_VIEW_PROPERTY
- Program units (form): –
- Library / DB package calls: TMPLT.POPULATE_FUNCTIONS

```plsql
DECLARE
	vis varchar2(200);
BEGIN

	vis :=  GET_VIEW_PROPERTY('LSIDE', visible);

	if vis = 'TRUE' then
		SET_VIEW_PROPERTY('LSIDE', visible, property_false);
		GO_ITEM(NAME_IN('PARAMETER.P_CURRENT_ITEM'));
		COPY('', 'PARAMETER.P_CURRENT_ITEM');
	else
		TMPLT.Populate_Functions ;
	end if;

END;
```

#### TOOLBAR.FUN_BUT · WHEN-MOUSE-DOWN

- Level: Item · Owner: `TOOLBAR.FUN_BUT` · Execution hierarchy: default (Override)
- Lines: 13 total / 10 active (non-blank, non-comment)
- Built-ins: COPY, GET_VIEW_PROPERTY, GO_ITEM, NAME_IN
- Program units (form): ADJ_FUNS
- Library / DB package calls: –

```plsql
DECLARE
	vis varchar2(200);
BEGIN

	vis :=  GET_VIEW_PROPERTY('LSIDE', visible);

	IF vis = 'FALSE' THEN
		COPY(NAME_IN('SYSTEM.CURSOR_ITEM'), 'PARAMETER.P_CURRENT_ITEM');
    ADJ_FUNS;
		GO_ITEM('DUMMY');
	END IF;

END;
```

#### IMPORTERS.PORT_CD · KEY-LISTVAL

- Level: Item · Owner: `IMPORTERS.PORT_CD` · Execution hierarchy: default (Override)
- Lines: 75 total / 65 active (non-blank, non-comment)
- Built-ins: ADD_PARAMETER, CALL_FORM, CREATE_PARAMETER_LIST, DESTROY_PARAMETER_LIST, GET_BLOCK_PROPERTY, GET_ITEM_PROPERTY, GET_PARAMETER_LIST, GET_RECORD_PROPERTY, ID_NULL, RAISE FORM_TRIGGER_FAILURE
- Program units (form): –
- Library / DB package calls: STR.DISPALERT

```plsql
/* CGAP$OLES_SEQUENCE_BEFORE */
DECLARE
	V_DISP_LOV BOOLEAN := FALSE;
BEGIN
IF :SYSTEM.MODE <> 'ENTER-QUERY' THEN
	IF Get_Record_Property(:SYSTEM.CURSOR_RECORD,:SYSTEM.CURSOR_BLOCK,STATUS) IN ('NEW', 'INSERT') THEN
		IF GET_BLOCK_PROPERTY(:SYSTEM.CURSOR_BLOCK, INSERT_ALLOWED) = 'TRUE' THEN
				IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, ENABLED) = 'TRUE' THEN
					IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, INSERT_ALLOWED) = 'TRUE' THEN
								V_DISP_LOV := TRUE;
					END IF;
				END IF;
		END IF;
	ELSE
		IF GET_BLOCK_PROPERTY(:SYSTEM.CURSOR_BLOCK, UPDATE_ALLOWED) = 'TRUE'	THEN
				IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, ENABLED) = 'TRUE' THEN
					IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, UPDATE_ALLOWED) = 'TRUE' THEN
								V_DISP_LOV := TRUE;
					END IF;
				END IF;
		END IF;
	END IF;
ELSE
	IF GET_BLOCK_PROPERTY(:SYSTEM.CURSOR_BLOCK, QUERY_ALLOWED) = 'TRUE' THEN
		IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, QUERYABLE) = 'TRUE' THEN
					V_DISP_LOV := TRUE;
		END IF;
	END IF;
END IF;
IF NOT V_DISP_LOV THEN
	RAISE FORM_TRIGGER_FAILURE;
END IF;
END;

DECLARE
   pl_id   ParamList;
   pl_name VARCHAR2(100) := 'BUS_ID_LOV';

   RET NUMBER;

 BEGIN
   pl_id := Get_Parameter_List(pl_name);
   IF Id_Null(pl_id) THEN
     pl_id := Create_Parameter_List(pl_name);
     IF Id_Null(pl_id) THEN
       ret := Str.Dispalert('Error creating parameter list '||pl_name, 'SYSTEM_ERROR');
       RAISE Form_Trigger_Failure;
     END IF;

   Add_Parameter(pl_id, 'PORT_TYPE', TEXT_PARAMETER, :PARAMETER.P_PORT_TYPE);
   Add_Parameter(pl_id, 'WINDOW_WIDTH', TEXT_PARAMETER, 5.5);
   Add_Parameter(pl_id, 'WINDOW_TITLE', TEXT_PARAMETER, 'قائمة المنافذ الجمركية السعوديه');

   IF (:system.mode <> 'ENTER-QUERY'  ) THEN
	   Add_Parameter(pl_id, 'STATUS', TEXT_PARAMETER, 1);
   END IF;

   CALL_FORM('LOV_SD_PORTS.fmx',
              no_hide,
              no_replace,
              no_query_only,
              pl_id);

 	IF  :GLOBAL.PORT_CD IS NOT NULL THEN
	:IMPORTERS.PORT_CD := :GLOBAL.PORT_CD;
	:IMPORTERS.PORT_NAME := :GLOBAL.PORT_NAME;
 	END IF;


   Destroy_Parameter_List(pl_id);
   ELSE
     ret := Str.DispAlert('Parameter list '||pl_name||' already exists!','INFORMATION');
     RAISE Form_Trigger_Failure;
   END IF;
 END;
```

#### IMPORTERS.PORT_CD2 · WHEN-BUTTON-PRESSED

- Level: Item · Owner: `IMPORTERS.PORT_CD2` · Execution hierarchy: default (Override)
- Lines: 6 total / 4 active (non-blank, non-comment)
- Built-ins: DO_KEY, GO_ITEM
- Program units (form): –
- Library / DB package calls: –

```plsql
/* CGLY$WHEN_BUTTON_PRESSED */
/* Replicate default menu functionality */
BEGIN
  go_item('IMPORTERS.PORT_CD');
  do_key('List_values');
END;
```

#### IMPORTERS.PORT_NAME · KEY-LISTVAL

- Level: Item · Owner: `IMPORTERS.PORT_NAME` · Execution hierarchy: default (Override)
- Lines: 33 total / 32 active (non-blank, non-comment)
- Built-ins: GET_BLOCK_PROPERTY, GET_ITEM_PROPERTY, GET_RECORD_PROPERTY, RAISE FORM_TRIGGER_FAILURE
- Program units (form): –
- Library / DB package calls: –

```plsql
/* CGAP$OLES_SEQUENCE_BEFORE */
DECLARE
	V_DISP_LOV BOOLEAN := FALSE;
BEGIN
IF :SYSTEM.MODE <> 'ENTER-QUERY' THEN
	IF Get_Record_Property(:SYSTEM.CURSOR_RECORD,:SYSTEM.CURSOR_BLOCK,STATUS) IN ('NEW', 'INSERT') THEN
		IF GET_BLOCK_PROPERTY(:SYSTEM.CURSOR_BLOCK, INSERT_ALLOWED) = 'TRUE' THEN
				IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, ENABLED) = 'TRUE' THEN
					IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, INSERT_ALLOWED) = 'TRUE' THEN
								V_DISP_LOV := TRUE;
					END IF;
				END IF;
		END IF;
	ELSE
		IF GET_BLOCK_PROPERTY(:SYSTEM.CURSOR_BLOCK, UPDATE_ALLOWED) = 'TRUE'	THEN
				IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, ENABLED) = 'TRUE' THEN
					IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, UPDATE_ALLOWED) = 'TRUE' THEN
								V_DISP_LOV := TRUE;
					END IF;
				END IF;
		END IF;
	END IF;
ELSE
	IF GET_BLOCK_PROPERTY(:SYSTEM.CURSOR_BLOCK, QUERY_ALLOWED) = 'TRUE' THEN
		IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, QUERYABLE) = 'TRUE' THEN
					V_DISP_LOV := TRUE;
		END IF;
	END IF;
END IF;
IF NOT V_DISP_LOV THEN
	RAISE FORM_TRIGGER_FAILURE;
END IF;
END;
```

#### IMPORTERS.HQ_IMPR_NBR · KEY-LISTVAL

- Level: Item · Owner: `IMPORTERS.HQ_IMPR_NBR` · Execution hierarchy: default (Override)
- Lines: 33 total / 32 active (non-blank, non-comment)
- Built-ins: GET_BLOCK_PROPERTY, GET_ITEM_PROPERTY, GET_RECORD_PROPERTY, RAISE FORM_TRIGGER_FAILURE
- Program units (form): –
- Library / DB package calls: –

```plsql
/* CGAP$OLES_SEQUENCE_BEFORE */
DECLARE
	V_DISP_LOV BOOLEAN := FALSE;
BEGIN
IF :SYSTEM.MODE <> 'ENTER-QUERY' THEN
	IF Get_Record_Property(:SYSTEM.CURSOR_RECORD,:SYSTEM.CURSOR_BLOCK,STATUS) IN ('NEW', 'INSERT') THEN
		IF GET_BLOCK_PROPERTY(:SYSTEM.CURSOR_BLOCK, INSERT_ALLOWED) = 'TRUE' THEN
				IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, ENABLED) = 'TRUE' THEN
					IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, INSERT_ALLOWED) = 'TRUE' THEN
								V_DISP_LOV := TRUE;
					END IF;
				END IF;
		END IF;
	ELSE
		IF GET_BLOCK_PROPERTY(:SYSTEM.CURSOR_BLOCK, UPDATE_ALLOWED) = 'TRUE'	THEN
				IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, ENABLED) = 'TRUE' THEN
					IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, UPDATE_ALLOWED) = 'TRUE' THEN
								V_DISP_LOV := TRUE;
					END IF;
				END IF;
		END IF;
	END IF;
ELSE
	IF GET_BLOCK_PROPERTY(:SYSTEM.CURSOR_BLOCK, QUERY_ALLOWED) = 'TRUE' THEN
		IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, QUERYABLE) = 'TRUE' THEN
					V_DISP_LOV := TRUE;
		END IF;
	END IF;
END IF;
IF NOT V_DISP_LOV THEN
	RAISE FORM_TRIGGER_FAILURE;
END IF;
END;
```

#### IMPORTERS.IMPR_NBR · KEY-LISTVAL

- Level: Item · Owner: `IMPORTERS.IMPR_NBR` · Execution hierarchy: default (Override)
- Lines: 33 total / 32 active (non-blank, non-comment)
- Built-ins: GET_BLOCK_PROPERTY, GET_ITEM_PROPERTY, GET_RECORD_PROPERTY, RAISE FORM_TRIGGER_FAILURE
- Program units (form): –
- Library / DB package calls: –

```plsql
/* CGAP$OLES_SEQUENCE_BEFORE */
DECLARE
	V_DISP_LOV BOOLEAN := FALSE;
BEGIN
IF :SYSTEM.MODE <> 'ENTER-QUERY' THEN
	IF Get_Record_Property(:SYSTEM.CURSOR_RECORD,:SYSTEM.CURSOR_BLOCK,STATUS) IN ('NEW', 'INSERT') THEN
		IF GET_BLOCK_PROPERTY(:SYSTEM.CURSOR_BLOCK, INSERT_ALLOWED) = 'TRUE' THEN
				IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, ENABLED) = 'TRUE' THEN
					IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, INSERT_ALLOWED) = 'TRUE' THEN
								V_DISP_LOV := TRUE;
					END IF;
				END IF;
		END IF;
	ELSE
		IF GET_BLOCK_PROPERTY(:SYSTEM.CURSOR_BLOCK, UPDATE_ALLOWED) = 'TRUE'	THEN
				IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, ENABLED) = 'TRUE' THEN
					IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, UPDATE_ALLOWED) = 'TRUE' THEN
								V_DISP_LOV := TRUE;
					END IF;
				END IF;
		END IF;
	END IF;
ELSE
	IF GET_BLOCK_PROPERTY(:SYSTEM.CURSOR_BLOCK, QUERY_ALLOWED) = 'TRUE' THEN
		IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, QUERYABLE) = 'TRUE' THEN
					V_DISP_LOV := TRUE;
		END IF;
	END IF;
END IF;
IF NOT V_DISP_LOV THEN
	RAISE FORM_TRIGGER_FAILURE;
END IF;
END;
```

#### IMPORTERS.IMPR_NBR · WHEN-VALIDATE-ITEM

- Level: Item · Owner: `IMPORTERS.IMPR_NBR` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 22 total / 18 active (non-blank, non-comment)
- Built-ins: RAISE FORM_TRIGGER_FAILURE
- Program units (form): –
- Library / DB package calls: STR.DISPARBMSG

```plsql
DECLARE
	rec_count NUMBER;
BEGIN
IF (:IMPORTERS.IMPR_NBR IS NOT NULL) THEN

	SELECT COUNT(*) INTO Rec_Count
	FROM IMPORTERS
	WHERE PORT_CD = :IMPORTERS.PORT_CD
	AND IMPR_NBR = :IMPORTERS.IMPR_NBR;

	IF Rec_Count <> 0 THEN
		:global.PORT_CD	:= :IMPORTERS.PORT_CD;
		:global.IMPR_NBR	:= :IMPORTERS.IMPR_NBR;
		:global.Exec_Query_Now := 1;

	ELSE
		rec_count := STR.DispArbMsg(9, 150,'INFORMATION');
		RAISE FORm_Trigger_Failure;
	END IF;

END IF;
END;
```

#### IMPORTERS.SDP_PORT_STATUS · KEY-LISTVAL

- Level: Item · Owner: `IMPORTERS.SDP_PORT_STATUS` · Execution hierarchy: default (Override)
- Lines: 34 total / 32 active (non-blank, non-comment)
- Built-ins: GET_BLOCK_PROPERTY, GET_ITEM_PROPERTY, GET_RECORD_PROPERTY, RAISE FORM_TRIGGER_FAILURE
- Program units (form): –
- Library / DB package calls: –

```plsql
/* CGAP$OLES_SEQUENCE_BEFORE */
DECLARE
	V_DISP_LOV BOOLEAN := FALSE;
BEGIN
IF :SYSTEM.MODE <> 'ENTER-QUERY' THEN
	IF Get_Record_Property(:SYSTEM.CURSOR_RECORD,:SYSTEM.CURSOR_BLOCK,STATUS) IN ('NEW', 'INSERT') THEN
		IF GET_BLOCK_PROPERTY(:SYSTEM.CURSOR_BLOCK, INSERT_ALLOWED) = 'TRUE' THEN
				IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, ENABLED) = 'TRUE' THEN
					IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, INSERT_ALLOWED) = 'TRUE' THEN
								V_DISP_LOV := TRUE;
					END IF;
				END IF;
		END IF;
	ELSE
		IF GET_BLOCK_PROPERTY(:SYSTEM.CURSOR_BLOCK, UPDATE_ALLOWED) = 'TRUE'	THEN
				IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, ENABLED) = 'TRUE' THEN
					IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, UPDATE_ALLOWED) = 'TRUE' THEN
								V_DISP_LOV := TRUE;
					END IF;
				END IF;
		END IF;
	END IF;
ELSE
	IF GET_BLOCK_PROPERTY(:SYSTEM.CURSOR_BLOCK, QUERY_ALLOWED) = 'TRUE' THEN
		IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, QUERYABLE) = 'TRUE' THEN
					V_DISP_LOV := TRUE;
		END IF;
	END IF;
END IF;
IF NOT V_DISP_LOV THEN
	RAISE FORM_TRIGGER_FAILURE;
END IF;

END;
```

#### IMPORTERS.IMPR_TYPE_CD · KEY-LISTVAL

- Level: Item · Owner: `IMPORTERS.IMPR_TYPE_CD` · Execution hierarchy: default (Override)
- Lines: 73 total / 63 active (non-blank, non-comment)
- Built-ins: ADD_PARAMETER, CALL_FORM, CREATE_PARAMETER_LIST, DESTROY_PARAMETER_LIST, GET_BLOCK_PROPERTY, GET_ITEM_PROPERTY, GET_PARAMETER_LIST, GET_RECORD_PROPERTY, ID_NULL, RAISE FORM_TRIGGER_FAILURE
- Program units (form): –
- Library / DB package calls: STR.DISPALERT

```plsql
/* CGAP$OLES_SEQUENCE_BEFORE */
DECLARE
	V_DISP_LOV BOOLEAN := FALSE;
BEGIN
IF :SYSTEM.MODE <> 'ENTER-QUERY' THEN
	IF Get_Record_Property(:SYSTEM.CURSOR_RECORD,:SYSTEM.CURSOR_BLOCK,STATUS) IN ('NEW', 'INSERT') THEN
		IF GET_BLOCK_PROPERTY(:SYSTEM.CURSOR_BLOCK, INSERT_ALLOWED) = 'TRUE' THEN
				IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, ENABLED) = 'TRUE' THEN
					IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, INSERT_ALLOWED) = 'TRUE' THEN
								V_DISP_LOV := TRUE;
					END IF;
				END IF;
		END IF;
	ELSE
		IF GET_BLOCK_PROPERTY(:SYSTEM.CURSOR_BLOCK, UPDATE_ALLOWED) = 'TRUE'	THEN
				IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, ENABLED) = 'TRUE' THEN
					IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, UPDATE_ALLOWED) = 'TRUE' THEN
								V_DISP_LOV := TRUE;
					END IF;
				END IF;
		END IF;
	END IF;
ELSE
	IF GET_BLOCK_PROPERTY(:SYSTEM.CURSOR_BLOCK, QUERY_ALLOWED) = 'TRUE' THEN
		IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, QUERYABLE) = 'TRUE' THEN
					V_DISP_LOV := TRUE;
		END IF;
	END IF;
END IF;
IF NOT V_DISP_LOV THEN
	RAISE FORM_TRIGGER_FAILURE;
END IF;
END;

DECLARE
   pl_id   ParamList;
   pl_name VARCHAR2(100) := 'BUS_ID_LOV';

   RET NUMBER;

 BEGIN
   pl_id := Get_Parameter_List(pl_name);
   IF Id_Null(pl_id) THEN
     pl_id := Create_Parameter_List(pl_name);
     IF Id_Null(pl_id) THEN
       ret := Str.Dispalert('Error creating parameter list '||pl_name, 'SYSTEM_ERROR');
       RAISE Form_Trigger_Failure;
     END IF;

   IF (:system.mode <> 'ENTER-QUERY'  ) THEN
	   Add_Parameter(pl_id, 'STATUS', TEXT_PARAMETER, 1);
   END IF;
   Add_Parameter(pl_id, 'WINDOW_TITLE', TEXT_PARAMETER, 'قائمة أنواع الأنشطة التجاريه');

   CALL_FORM('LOV_Impr_Type.fmx',
              no_hide,
              no_replace,
              no_query_only,
              pl_id);

 	IF  :GLOBAL.IMPR_TYPE_CD IS NOT NULL THEN
	:IMPR_TYPE_CD := :GLOBAL.IMPR_TYPE_CD;
	:IMPR_TYPE_NAME := :GLOBAL.IMPR_TYPE_NAME;
--	:BUS_ID_TYPE_CD := :GLOBAL.BUS_ID_TYPE_CD;
--	:BUS_ID_TYPE_NAME := :GLOBAL.BUS_ID_TYPE_NAME;
 	END IF;

   Destroy_Parameter_List(pl_id);
   ELSE
     ret := Str.DispAlert('Parameter list '||pl_name||' already exists!','INFORMATION');
     RAISE Form_Trigger_Failure;
   END IF;
 END;
```

#### IMPORTERS.IMPR_TYPE_CD · WHEN-VALIDATE-ITEM

- Level: Item · Owner: `IMPORTERS.IMPR_TYPE_CD` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 19 total / 17 active (non-blank, non-comment)
- Built-ins: NAME_IN
- Program units (form): CGFK$CHK_IMPORTERS_IMP_ITIDT_F
- Library / DB package calls: CGTE$OTHER_EXCEPTIONS, DES$FORM_ERRORS.PUSH

```plsql
/* CGFK$VALDIDATE_FK_OVF */
/* Check that foreign key value exists in referenced table */
BEGIN
  IF (name_in('IMPORTERS.IMPR_TYPE_CD') IS NOT NULL AND name_in('IMPORTERS.BUS_ID_TYPE_CD') IS NOT NULL) THEN
    BEGIN
      CGFK$CHK_IMPORTERS_IMP_ITIDT_F(
        :IMPORTERS.BUS_ID_TYPE_NAME    /* MOD: Value in Item :IMPORTERS.BUS_ID_TYPE_NAME.                                                                                                                                                     */
       ,:IMPORTERS.IMPR_TYPE_NAME      /* MOD: Value in Item :IMPORTERS.IMPR_TYPE_NAME.                                                                                                                                                       */
       ,:IMPORTERS.STATUS              /* MOD: Value in Item :IMPORTERS.STATUS.                                                                                                                                                               */
       ,:IMPORTERS.IMPR_TYPE_CD        /* IN : Value in Item :IMPORTERS.IMPR_TYPE_CD.                                                                                                                                                         */
       ,:IMPORTERS.BUS_ID_TYPE_CD  );  /* IN : Value in Item :IMPORTERS.BUS_ID_TYPE_CD.                                                                                                                                                       */
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        Des$Form_errors.PUSH('رمز النشاط التجاري غير صحيح - أعد إدخال البيانات', 'W', 'OFG', 0);
      WHEN OTHERS THEN
        CGTE$OTHER_EXCEPTIONS;
    END;
  END IF;
END;
```

#### IMPORTERS.IMPR_TYPE_CD · WHEN-NEW-ITEM-INSTANCE

- Level: Item · Owner: `IMPORTERS.IMPR_TYPE_CD` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 6 total / 6 active (non-blank, non-comment)
- Built-ins: CLEAR_BLOCK, EXECUTE_QUERY
- Program units (form): –
- Library / DB package calls: –

```plsql
BEGIN
IF :global.Exec_Query_Now = 1 THEN
	Clear_Block(No_Validate);
	execute_query;
END IF;
END;
```

#### IMPORTERS.IMPR_TYPE_CD2 · WHEN-BUTTON-PRESSED

- Level: Item · Owner: `IMPORTERS.IMPR_TYPE_CD2` · Execution hierarchy: default (Override)
- Lines: 6 total / 4 active (non-blank, non-comment)
- Built-ins: DO_KEY, GO_ITEM
- Program units (form): –
- Library / DB package calls: –

```plsql
/* CGLY$WHEN_BUTTON_PRESSED */
/* Replicate default menu functionality */
BEGIN
  go_item('IMPORTERS.IMPR_TYPE_CD');
  do_key('List_values');
END;
```

#### IMPORTERS.IMPR_TYPE_NAME · KEY-LISTVAL

- Level: Item · Owner: `IMPORTERS.IMPR_TYPE_NAME` · Execution hierarchy: default (Override)
- Lines: 33 total / 32 active (non-blank, non-comment)
- Built-ins: GET_BLOCK_PROPERTY, GET_ITEM_PROPERTY, GET_RECORD_PROPERTY, RAISE FORM_TRIGGER_FAILURE
- Program units (form): –
- Library / DB package calls: –

```plsql
/* CGAP$OLES_SEQUENCE_BEFORE */
DECLARE
	V_DISP_LOV BOOLEAN := FALSE;
BEGIN
IF :SYSTEM.MODE <> 'ENTER-QUERY' THEN
	IF Get_Record_Property(:SYSTEM.CURSOR_RECORD,:SYSTEM.CURSOR_BLOCK,STATUS) IN ('NEW', 'INSERT') THEN
		IF GET_BLOCK_PROPERTY(:SYSTEM.CURSOR_BLOCK, INSERT_ALLOWED) = 'TRUE' THEN
				IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, ENABLED) = 'TRUE' THEN
					IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, INSERT_ALLOWED) = 'TRUE' THEN
								V_DISP_LOV := TRUE;
					END IF;
				END IF;
		END IF;
	ELSE
		IF GET_BLOCK_PROPERTY(:SYSTEM.CURSOR_BLOCK, UPDATE_ALLOWED) = 'TRUE'	THEN
				IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, ENABLED) = 'TRUE' THEN
					IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, UPDATE_ALLOWED) = 'TRUE' THEN
								V_DISP_LOV := TRUE;
					END IF;
				END IF;
		END IF;
	END IF;
ELSE
	IF GET_BLOCK_PROPERTY(:SYSTEM.CURSOR_BLOCK, QUERY_ALLOWED) = 'TRUE' THEN
		IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, QUERYABLE) = 'TRUE' THEN
					V_DISP_LOV := TRUE;
		END IF;
	END IF;
END IF;
IF NOT V_DISP_LOV THEN
	RAISE FORM_TRIGGER_FAILURE;
END IF;
END;
```

#### IMPORTERS.CTRY_CD · KEY-LISTVAL

- Level: Item · Owner: `IMPORTERS.CTRY_CD` · Execution hierarchy: default (Override)
- Lines: 74 total / 64 active (non-blank, non-comment)
- Built-ins: ADD_PARAMETER, CALL_FORM, CREATE_PARAMETER_LIST, DESTROY_PARAMETER_LIST, GET_BLOCK_PROPERTY, GET_ITEM_PROPERTY, GET_PARAMETER_LIST, GET_RECORD_PROPERTY, ID_NULL, RAISE FORM_TRIGGER_FAILURE
- Program units (form): –
- Library / DB package calls: STR.DISPALERT

```plsql
/* CGAP$OLES_SEQUENCE_BEFORE */
DECLARE
	V_DISP_LOV BOOLEAN := FALSE;
BEGIN
IF :SYSTEM.MODE <> 'ENTER-QUERY' THEN
	IF Get_Record_Property(:SYSTEM.CURSOR_RECORD,:SYSTEM.CURSOR_BLOCK,STATUS) IN ('NEW', 'INSERT') THEN
		IF GET_BLOCK_PROPERTY(:SYSTEM.CURSOR_BLOCK, INSERT_ALLOWED) = 'TRUE' THEN
				IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, ENABLED) = 'TRUE' THEN
					IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, INSERT_ALLOWED) = 'TRUE' THEN
								V_DISP_LOV := TRUE;
					END IF;
				END IF;
		END IF;
	ELSE
		IF GET_BLOCK_PROPERTY(:SYSTEM.CURSOR_BLOCK, UPDATE_ALLOWED) = 'TRUE'	THEN
				IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, ENABLED) = 'TRUE' THEN
					IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, UPDATE_ALLOWED) = 'TRUE' THEN
								V_DISP_LOV := TRUE;
					END IF;
				END IF;
		END IF;
	END IF;
ELSE
	IF GET_BLOCK_PROPERTY(:SYSTEM.CURSOR_BLOCK, QUERY_ALLOWED) = 'TRUE' THEN
		IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, QUERYABLE) = 'TRUE' THEN
					V_DISP_LOV := TRUE;
		END IF;
	END IF;
END IF;
IF NOT V_DISP_LOV THEN
	RAISE FORM_TRIGGER_FAILURE;
END IF;
END;

DECLARE
   pl_id   ParamList;
   pl_name VARCHAR2(100) := 'BUS_ID_LOV';

   RET NUMBER;

 BEGIN
   pl_id := Get_Parameter_List(pl_name);
   IF Id_Null(pl_id) THEN
     pl_id := Create_Parameter_List(pl_name);
     IF Id_Null(pl_id) THEN
       ret := Str.Dispalert('Error creating parameter list '||pl_name, 'SYSTEM_ERROR');
       RAISE Form_Trigger_Failure;
     END IF;

   Add_Parameter(pl_id, 'WINDOW_TITLE', TEXT_PARAMETER, 'قائمة رموز الدول');

   Add_Parameter(pl_id, 'WINDOW_WIDTH', TEXT_PARAMETER, 4.5);
   IF (:system.mode <> 'ENTER-QUERY'  ) THEN
	   Add_Parameter(pl_id, 'STATUS', TEXT_PARAMETER, 1);
   END IF;

   CALL_FORM('LOV_COUNTRIES.fmx',
              no_hide,
              no_replace,
              no_query_only,
              pl_id);

 	IF  :GLOBAL.CTRY_CD IS NOT NULL THEN
	:CTRY_CD := :GLOBAL.CTRY_CD;
	:CRTY_ARBC_NAME := :GLOBAL.CRTY_ARBC_NAME;
 	END IF;


   Destroy_Parameter_List(pl_id);
   ELSE
     ret := Str.DispAlert('Parameter list '||pl_name||' already exists!','INFORMATION');
     RAISE Form_Trigger_Failure;
   END IF;
 END;
```

#### IMPORTERS.CTRY_CD2 · WHEN-BUTTON-PRESSED

- Level: Item · Owner: `IMPORTERS.CTRY_CD2` · Execution hierarchy: default (Override)
- Lines: 6 total / 4 active (non-blank, non-comment)
- Built-ins: DO_KEY, GO_ITEM
- Program units (form): –
- Library / DB package calls: –

```plsql
/* CGLY$WHEN_BUTTON_PRESSED */
/* Replicate default menu functionality */
BEGIN
  go_item('IMPORTERS.CTRY_CD');
  do_key('List_values');
END;
```

#### IMPORTERS.CRTY_ARBC_NAME · KEY-LISTVAL

- Level: Item · Owner: `IMPORTERS.CRTY_ARBC_NAME` · Execution hierarchy: default (Override)
- Lines: 33 total / 32 active (non-blank, non-comment)
- Built-ins: GET_BLOCK_PROPERTY, GET_ITEM_PROPERTY, GET_RECORD_PROPERTY, RAISE FORM_TRIGGER_FAILURE
- Program units (form): –
- Library / DB package calls: –

```plsql
/* CGAP$OLES_SEQUENCE_BEFORE */
DECLARE
	V_DISP_LOV BOOLEAN := FALSE;
BEGIN
IF :SYSTEM.MODE <> 'ENTER-QUERY' THEN
	IF Get_Record_Property(:SYSTEM.CURSOR_RECORD,:SYSTEM.CURSOR_BLOCK,STATUS) IN ('NEW', 'INSERT') THEN
		IF GET_BLOCK_PROPERTY(:SYSTEM.CURSOR_BLOCK, INSERT_ALLOWED) = 'TRUE' THEN
				IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, ENABLED) = 'TRUE' THEN
					IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, INSERT_ALLOWED) = 'TRUE' THEN
								V_DISP_LOV := TRUE;
					END IF;
				END IF;
		END IF;
	ELSE
		IF GET_BLOCK_PROPERTY(:SYSTEM.CURSOR_BLOCK, UPDATE_ALLOWED) = 'TRUE'	THEN
				IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, ENABLED) = 'TRUE' THEN
					IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, UPDATE_ALLOWED) = 'TRUE' THEN
								V_DISP_LOV := TRUE;
					END IF;
				END IF;
		END IF;
	END IF;
ELSE
	IF GET_BLOCK_PROPERTY(:SYSTEM.CURSOR_BLOCK, QUERY_ALLOWED) = 'TRUE' THEN
		IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, QUERYABLE) = 'TRUE' THEN
					V_DISP_LOV := TRUE;
		END IF;
	END IF;
END IF;
IF NOT V_DISP_LOV THEN
	RAISE FORM_TRIGGER_FAILURE;
END IF;
END;
```

#### IMPORTERS.CITY_CODE_OF_ID · KEY-LISTVAL

- Level: Item · Owner: `IMPORTERS.CITY_CODE_OF_ID` · Execution hierarchy: default (Override)
- Lines: 81 total / 67 active (non-blank, non-comment)
- Built-ins: ADD_PARAMETER, CALL_FORM, CREATE_PARAMETER_LIST, DESTROY_PARAMETER_LIST, GET_BLOCK_PROPERTY, GET_ITEM_PROPERTY, GET_PARAMETER_LIST, GET_RECORD_PROPERTY, ID_NULL, RAISE FORM_TRIGGER_FAILURE
- Program units (form): –
- Library / DB package calls: STR.DISPALERT

```plsql
/* CGAP$OLES_SEQUENCE_BEFORE */
DECLARE
	V_DISP_LOV BOOLEAN := FALSE;
BEGIN
IF :SYSTEM.MODE <> 'ENTER-QUERY' THEN
	IF Get_Record_Property(:SYSTEM.CURSOR_RECORD,:SYSTEM.CURSOR_BLOCK,STATUS) IN ('NEW', 'INSERT') THEN
		IF GET_BLOCK_PROPERTY(:SYSTEM.CURSOR_BLOCK, INSERT_ALLOWED) = 'TRUE' THEN
				IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, ENABLED) = 'TRUE' THEN
					IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, INSERT_ALLOWED) = 'TRUE' THEN
								V_DISP_LOV := TRUE;
					END IF;
				END IF;
		END IF;
	ELSE
		IF GET_BLOCK_PROPERTY(:SYSTEM.CURSOR_BLOCK, UPDATE_ALLOWED) = 'TRUE'	THEN
				IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, ENABLED) = 'TRUE' THEN
					IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, UPDATE_ALLOWED) = 'TRUE' THEN
								V_DISP_LOV := TRUE;
					END IF;
				END IF;
		END IF;
	END IF;
ELSE
	IF GET_BLOCK_PROPERTY(:SYSTEM.CURSOR_BLOCK, QUERY_ALLOWED) = 'TRUE' THEN
		IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, QUERYABLE) = 'TRUE' THEN
					V_DISP_LOV := TRUE;
		END IF;
	END IF;
END IF;
IF NOT V_DISP_LOV THEN
	RAISE FORM_TRIGGER_FAILURE;
END IF;
END;


DECLARE
 RET NUMBER;
 pl_id   ParamList;

 BEGIN
   pl_id := Get_Parameter_List('LOV_CITIES');
   IF Id_Null(pl_id) THEN
     pl_id := Create_Parameter_List('LOV_CITIES');
     IF Id_Null(pl_id) THEN
       ret := Str.Dispalert('Error creating parameter list LOV_CITIES ', 'SYSTEM_ERROR');
       RAISE Form_Trigger_Failure;
     END IF;

   Add_Parameter(pl_id, 'WINDOW_TITLE ', TEXT_PARAMETER,'قائمة المدن السعوديه');
   Add_Parameter(pl_id, 'WINDOW_WIDTH ', TEXT_PARAMETER, 5);
   Add_Parameter(pl_id, 'WINDOW_X_POS', TEXT_PARAMETER, 1.5);
   Add_Parameter(pl_id, 'WINDOW_Y_POS', TEXT_PARAMETER, .8);
   Add_Parameter(pl_id, 'CTRY_CD', TEXT_PARAMETER, 100);




  IF (:SYSTEM.MODE <> 'ENTER_QUERY') THEN
      ADD_PARAMETER(PL_ID,'STATUS',TEXT_PARAMETER,1);
END IF;

   CALL_FORM('LOV_CITIES.fmx ',
              no_hide,
              no_replace,
              no_query_only,
              pl_id);


 	IF  :GLOBAL.CITY_CD IS NOT NULL THEN
	    :CITY_CODE_OF_ID :=:GLOBAL.CITY_CD ;
	    :CTRY_CD_OF_ID :=:GLOBAL.CTRY_CD ;
	    :ID_CITY_NAME :=:GLOBAL.CITY_ARB_NAME ;
 	END IF;

   Destroy_Parameter_List(pl_id);
   ELSE
     ret := Str.DispAlert('Parameter list '||'LOV_CITIES'||' already exists!','INFORMATION');
     RAISE Form_Trigger_Failure;
   END IF;

 END;
```

#### IMPORTERS.CITY_CODE_OF_ID2 · WHEN-BUTTON-PRESSED

- Level: Item · Owner: `IMPORTERS.CITY_CODE_OF_ID2` · Execution hierarchy: default (Override)
- Lines: 6 total / 4 active (non-blank, non-comment)
- Built-ins: DO_KEY, GO_ITEM
- Program units (form): –
- Library / DB package calls: –

```plsql
/* CGLY$WHEN_BUTTON_PRESSED */
/* Replicate default menu functionality */
BEGIN
  go_item('IMPORTERS.CITY_CODE_OF_ID');
  do_key('List_values');
END;
```

#### IMPORTERS.ID_CITY_NAME · KEY-LISTVAL

- Level: Item · Owner: `IMPORTERS.ID_CITY_NAME` · Execution hierarchy: default (Override)
- Lines: 33 total / 32 active (non-blank, non-comment)
- Built-ins: GET_BLOCK_PROPERTY, GET_ITEM_PROPERTY, GET_RECORD_PROPERTY, RAISE FORM_TRIGGER_FAILURE
- Program units (form): –
- Library / DB package calls: –

```plsql
/* CGAP$OLES_SEQUENCE_BEFORE */
DECLARE
	V_DISP_LOV BOOLEAN := FALSE;
BEGIN
IF :SYSTEM.MODE <> 'ENTER-QUERY' THEN
	IF Get_Record_Property(:SYSTEM.CURSOR_RECORD,:SYSTEM.CURSOR_BLOCK,STATUS) IN ('NEW', 'INSERT') THEN
		IF GET_BLOCK_PROPERTY(:SYSTEM.CURSOR_BLOCK, INSERT_ALLOWED) = 'TRUE' THEN
				IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, ENABLED) = 'TRUE' THEN
					IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, INSERT_ALLOWED) = 'TRUE' THEN
								V_DISP_LOV := TRUE;
					END IF;
				END IF;
		END IF;
	ELSE
		IF GET_BLOCK_PROPERTY(:SYSTEM.CURSOR_BLOCK, UPDATE_ALLOWED) = 'TRUE'	THEN
				IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, ENABLED) = 'TRUE' THEN
					IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, UPDATE_ALLOWED) = 'TRUE' THEN
								V_DISP_LOV := TRUE;
					END IF;
				END IF;
		END IF;
	END IF;
ELSE
	IF GET_BLOCK_PROPERTY(:SYSTEM.CURSOR_BLOCK, QUERY_ALLOWED) = 'TRUE' THEN
		IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, QUERYABLE) = 'TRUE' THEN
					V_DISP_LOV := TRUE;
		END IF;
	END IF;
END IF;
IF NOT V_DISP_LOV THEN
	RAISE FORM_TRIGGER_FAILURE;
END IF;
END;
```

#### IMPORTERS.BUS_ID · KEY-LISTVAL

- Level: Item · Owner: `IMPORTERS.BUS_ID` · Execution hierarchy: default (Override)
- Lines: 33 total / 32 active (non-blank, non-comment)
- Built-ins: GET_BLOCK_PROPERTY, GET_ITEM_PROPERTY, GET_RECORD_PROPERTY, RAISE FORM_TRIGGER_FAILURE
- Program units (form): –
- Library / DB package calls: –

```plsql
/* CGAP$OLES_SEQUENCE_BEFORE */
DECLARE
	V_DISP_LOV BOOLEAN := FALSE;
BEGIN
IF :SYSTEM.MODE <> 'ENTER-QUERY' THEN
	IF Get_Record_Property(:SYSTEM.CURSOR_RECORD,:SYSTEM.CURSOR_BLOCK,STATUS) IN ('NEW', 'INSERT') THEN
		IF GET_BLOCK_PROPERTY(:SYSTEM.CURSOR_BLOCK, INSERT_ALLOWED) = 'TRUE' THEN
				IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, ENABLED) = 'TRUE' THEN
					IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, INSERT_ALLOWED) = 'TRUE' THEN
								V_DISP_LOV := TRUE;
					END IF;
				END IF;
		END IF;
	ELSE
		IF GET_BLOCK_PROPERTY(:SYSTEM.CURSOR_BLOCK, UPDATE_ALLOWED) = 'TRUE'	THEN
				IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, ENABLED) = 'TRUE' THEN
					IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, UPDATE_ALLOWED) = 'TRUE' THEN
								V_DISP_LOV := TRUE;
					END IF;
				END IF;
		END IF;
	END IF;
ELSE
	IF GET_BLOCK_PROPERTY(:SYSTEM.CURSOR_BLOCK, QUERY_ALLOWED) = 'TRUE' THEN
		IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, QUERYABLE) = 'TRUE' THEN
					V_DISP_LOV := TRUE;
		END IF;
	END IF;
END IF;
IF NOT V_DISP_LOV THEN
	RAISE FORM_TRIGGER_FAILURE;
END IF;
END;
```

#### IMPORTERS.BUS_ID_TYPE_CD · KEY-LISTVAL

- Level: Item · Owner: `IMPORTERS.BUS_ID_TYPE_CD` · Execution hierarchy: default (Override)
- Lines: 33 total / 32 active (non-blank, non-comment)
- Built-ins: GET_BLOCK_PROPERTY, GET_ITEM_PROPERTY, GET_RECORD_PROPERTY, RAISE FORM_TRIGGER_FAILURE
- Program units (form): –
- Library / DB package calls: –

```plsql
/* CGAP$OLES_SEQUENCE_BEFORE */
DECLARE
	V_DISP_LOV BOOLEAN := FALSE;
BEGIN
IF :SYSTEM.MODE <> 'ENTER-QUERY' THEN
	IF Get_Record_Property(:SYSTEM.CURSOR_RECORD,:SYSTEM.CURSOR_BLOCK,STATUS) IN ('NEW', 'INSERT') THEN
		IF GET_BLOCK_PROPERTY(:SYSTEM.CURSOR_BLOCK, INSERT_ALLOWED) = 'TRUE' THEN
				IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, ENABLED) = 'TRUE' THEN
					IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, INSERT_ALLOWED) = 'TRUE' THEN
								V_DISP_LOV := TRUE;
					END IF;
				END IF;
		END IF;
	ELSE
		IF GET_BLOCK_PROPERTY(:SYSTEM.CURSOR_BLOCK, UPDATE_ALLOWED) = 'TRUE'	THEN
				IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, ENABLED) = 'TRUE' THEN
					IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, UPDATE_ALLOWED) = 'TRUE' THEN
								V_DISP_LOV := TRUE;
					END IF;
				END IF;
		END IF;
	END IF;
ELSE
	IF GET_BLOCK_PROPERTY(:SYSTEM.CURSOR_BLOCK, QUERY_ALLOWED) = 'TRUE' THEN
		IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, QUERYABLE) = 'TRUE' THEN
					V_DISP_LOV := TRUE;
		END IF;
	END IF;
END IF;
IF NOT V_DISP_LOV THEN
	RAISE FORM_TRIGGER_FAILURE;
END IF;
END;
```

#### IMPORTERS.BUTT · WHEN-BUTTON-PRESSED

- Level: Item · Owner: `IMPORTERS.BUTT` · Execution hierarchy: default (Override)
- Lines: 7 total / 5 active (non-blank, non-comment)
- Built-ins: DO_KEY, GO_ITEM
- Program units (form): –
- Library / DB package calls: –

```plsql
/* CGAP$OLES_SEQUENCE_BEFORE */
NULL;

BEGIN
	go_item('IMPORTERS.BUS_ID_TYPE_CD');
  do_key('List_values');
  END;
```

#### IMPORTERS.BUS_ID_TYPE_NAME · KEY-LISTVAL

- Level: Item · Owner: `IMPORTERS.BUS_ID_TYPE_NAME` · Execution hierarchy: default (Override)
- Lines: 33 total / 32 active (non-blank, non-comment)
- Built-ins: GET_BLOCK_PROPERTY, GET_ITEM_PROPERTY, GET_RECORD_PROPERTY, RAISE FORM_TRIGGER_FAILURE
- Program units (form): –
- Library / DB package calls: –

```plsql
/* CGAP$OLES_SEQUENCE_BEFORE */
DECLARE
	V_DISP_LOV BOOLEAN := FALSE;
BEGIN
IF :SYSTEM.MODE <> 'ENTER-QUERY' THEN
	IF Get_Record_Property(:SYSTEM.CURSOR_RECORD,:SYSTEM.CURSOR_BLOCK,STATUS) IN ('NEW', 'INSERT') THEN
		IF GET_BLOCK_PROPERTY(:SYSTEM.CURSOR_BLOCK, INSERT_ALLOWED) = 'TRUE' THEN
				IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, ENABLED) = 'TRUE' THEN
					IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, INSERT_ALLOWED) = 'TRUE' THEN
								V_DISP_LOV := TRUE;
					END IF;
				END IF;
		END IF;
	ELSE
		IF GET_BLOCK_PROPERTY(:SYSTEM.CURSOR_BLOCK, UPDATE_ALLOWED) = 'TRUE'	THEN
				IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, ENABLED) = 'TRUE' THEN
					IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, UPDATE_ALLOWED) = 'TRUE' THEN
								V_DISP_LOV := TRUE;
					END IF;
				END IF;
		END IF;
	END IF;
ELSE
	IF GET_BLOCK_PROPERTY(:SYSTEM.CURSOR_BLOCK, QUERY_ALLOWED) = 'TRUE' THEN
		IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, QUERYABLE) = 'TRUE' THEN
					V_DISP_LOV := TRUE;
		END IF;
	END IF;
END IF;
IF NOT V_DISP_LOV THEN
	RAISE FORM_TRIGGER_FAILURE;
END IF;
END;
```

#### IMPORTERS.BUS_ID_BRNCH · KEY-LISTVAL

- Level: Item · Owner: `IMPORTERS.BUS_ID_BRNCH` · Execution hierarchy: default (Override)
- Lines: 33 total / 32 active (non-blank, non-comment)
- Built-ins: GET_BLOCK_PROPERTY, GET_ITEM_PROPERTY, GET_RECORD_PROPERTY, RAISE FORM_TRIGGER_FAILURE
- Program units (form): –
- Library / DB package calls: –

```plsql
/* CGAP$OLES_SEQUENCE_BEFORE */
DECLARE
	V_DISP_LOV BOOLEAN := FALSE;
BEGIN
IF :SYSTEM.MODE <> 'ENTER-QUERY' THEN
	IF Get_Record_Property(:SYSTEM.CURSOR_RECORD,:SYSTEM.CURSOR_BLOCK,STATUS) IN ('NEW', 'INSERT') THEN
		IF GET_BLOCK_PROPERTY(:SYSTEM.CURSOR_BLOCK, INSERT_ALLOWED) = 'TRUE' THEN
				IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, ENABLED) = 'TRUE' THEN
					IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, INSERT_ALLOWED) = 'TRUE' THEN
								V_DISP_LOV := TRUE;
					END IF;
				END IF;
		END IF;
	ELSE
		IF GET_BLOCK_PROPERTY(:SYSTEM.CURSOR_BLOCK, UPDATE_ALLOWED) = 'TRUE'	THEN
				IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, ENABLED) = 'TRUE' THEN
					IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, UPDATE_ALLOWED) = 'TRUE' THEN
								V_DISP_LOV := TRUE;
					END IF;
				END IF;
		END IF;
	END IF;
ELSE
	IF GET_BLOCK_PROPERTY(:SYSTEM.CURSOR_BLOCK, QUERY_ALLOWED) = 'TRUE' THEN
		IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, QUERYABLE) = 'TRUE' THEN
					V_DISP_LOV := TRUE;
		END IF;
	END IF;
END IF;
IF NOT V_DISP_LOV THEN
	RAISE FORM_TRIGGER_FAILURE;
END IF;
END;
```

#### IMPORTERS.CTRY_CTRY_STATUS · KEY-LISTVAL

- Level: Item · Owner: `IMPORTERS.CTRY_CTRY_STATUS` · Execution hierarchy: default (Override)
- Lines: 34 total / 32 active (non-blank, non-comment)
- Built-ins: GET_BLOCK_PROPERTY, GET_ITEM_PROPERTY, GET_RECORD_PROPERTY, RAISE FORM_TRIGGER_FAILURE
- Program units (form): –
- Library / DB package calls: –

```plsql
/* CGAP$OLES_SEQUENCE_BEFORE */
DECLARE
	V_DISP_LOV BOOLEAN := FALSE;
BEGIN
IF :SYSTEM.MODE <> 'ENTER-QUERY' THEN
	IF Get_Record_Property(:SYSTEM.CURSOR_RECORD,:SYSTEM.CURSOR_BLOCK,STATUS) IN ('NEW', 'INSERT') THEN
		IF GET_BLOCK_PROPERTY(:SYSTEM.CURSOR_BLOCK, INSERT_ALLOWED) = 'TRUE' THEN
				IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, ENABLED) = 'TRUE' THEN
					IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, INSERT_ALLOWED) = 'TRUE' THEN
								V_DISP_LOV := TRUE;
					END IF;
				END IF;
		END IF;
	ELSE
		IF GET_BLOCK_PROPERTY(:SYSTEM.CURSOR_BLOCK, UPDATE_ALLOWED) = 'TRUE'	THEN
				IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, ENABLED) = 'TRUE' THEN
					IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, UPDATE_ALLOWED) = 'TRUE' THEN
								V_DISP_LOV := TRUE;
					END IF;
				END IF;
		END IF;
	END IF;
ELSE
	IF GET_BLOCK_PROPERTY(:SYSTEM.CURSOR_BLOCK, QUERY_ALLOWED) = 'TRUE' THEN
		IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, QUERYABLE) = 'TRUE' THEN
					V_DISP_LOV := TRUE;
		END IF;
	END IF;
END IF;
IF NOT V_DISP_LOV THEN
	RAISE FORM_TRIGGER_FAILURE;
END IF;

END;
```

#### IMPORTERS.ARBC_IMPR_NAME · KEY-LISTVAL

- Level: Item · Owner: `IMPORTERS.ARBC_IMPR_NAME` · Execution hierarchy: default (Override)
- Lines: 33 total / 32 active (non-blank, non-comment)
- Built-ins: GET_BLOCK_PROPERTY, GET_ITEM_PROPERTY, GET_RECORD_PROPERTY, RAISE FORM_TRIGGER_FAILURE
- Program units (form): –
- Library / DB package calls: –

```plsql
/* CGAP$OLES_SEQUENCE_BEFORE */
DECLARE
	V_DISP_LOV BOOLEAN := FALSE;
BEGIN
IF :SYSTEM.MODE <> 'ENTER-QUERY' THEN
	IF Get_Record_Property(:SYSTEM.CURSOR_RECORD,:SYSTEM.CURSOR_BLOCK,STATUS) IN ('NEW', 'INSERT') THEN
		IF GET_BLOCK_PROPERTY(:SYSTEM.CURSOR_BLOCK, INSERT_ALLOWED) = 'TRUE' THEN
				IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, ENABLED) = 'TRUE' THEN
					IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, INSERT_ALLOWED) = 'TRUE' THEN
								V_DISP_LOV := TRUE;
					END IF;
				END IF;
		END IF;
	ELSE
		IF GET_BLOCK_PROPERTY(:SYSTEM.CURSOR_BLOCK, UPDATE_ALLOWED) = 'TRUE'	THEN
				IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, ENABLED) = 'TRUE' THEN
					IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, UPDATE_ALLOWED) = 'TRUE' THEN
								V_DISP_LOV := TRUE;
					END IF;
				END IF;
		END IF;
	END IF;
ELSE
	IF GET_BLOCK_PROPERTY(:SYSTEM.CURSOR_BLOCK, QUERY_ALLOWED) = 'TRUE' THEN
		IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, QUERYABLE) = 'TRUE' THEN
					V_DISP_LOV := TRUE;
		END IF;
	END IF;
END IF;
IF NOT V_DISP_LOV THEN
	RAISE FORM_TRIGGER_FAILURE;
END IF;
END;
```

#### IMPORTERS.ENG_IMPR_NAME · KEY-LISTVAL

- Level: Item · Owner: `IMPORTERS.ENG_IMPR_NAME` · Execution hierarchy: default (Override)
- Lines: 33 total / 32 active (non-blank, non-comment)
- Built-ins: GET_BLOCK_PROPERTY, GET_ITEM_PROPERTY, GET_RECORD_PROPERTY, RAISE FORM_TRIGGER_FAILURE
- Program units (form): –
- Library / DB package calls: –

```plsql
/* CGAP$OLES_SEQUENCE_BEFORE */
DECLARE
	V_DISP_LOV BOOLEAN := FALSE;
BEGIN
IF :SYSTEM.MODE <> 'ENTER-QUERY' THEN
	IF Get_Record_Property(:SYSTEM.CURSOR_RECORD,:SYSTEM.CURSOR_BLOCK,STATUS) IN ('NEW', 'INSERT') THEN
		IF GET_BLOCK_PROPERTY(:SYSTEM.CURSOR_BLOCK, INSERT_ALLOWED) = 'TRUE' THEN
				IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, ENABLED) = 'TRUE' THEN
					IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, INSERT_ALLOWED) = 'TRUE' THEN
								V_DISP_LOV := TRUE;
					END IF;
				END IF;
		END IF;
	ELSE
		IF GET_BLOCK_PROPERTY(:SYSTEM.CURSOR_BLOCK, UPDATE_ALLOWED) = 'TRUE'	THEN
				IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, ENABLED) = 'TRUE' THEN
					IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, UPDATE_ALLOWED) = 'TRUE' THEN
								V_DISP_LOV := TRUE;
					END IF;
				END IF;
		END IF;
	END IF;
ELSE
	IF GET_BLOCK_PROPERTY(:SYSTEM.CURSOR_BLOCK, QUERY_ALLOWED) = 'TRUE' THEN
		IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, QUERYABLE) = 'TRUE' THEN
					V_DISP_LOV := TRUE;
		END IF;
	END IF;
END IF;
IF NOT V_DISP_LOV THEN
	RAISE FORM_TRIGGER_FAILURE;
END IF;
END;
```

#### IMPORTERS.IMPR_CNTCT_NAME · KEY-LISTVAL

- Level: Item · Owner: `IMPORTERS.IMPR_CNTCT_NAME` · Execution hierarchy: default (Override)
- Lines: 33 total / 32 active (non-blank, non-comment)
- Built-ins: GET_BLOCK_PROPERTY, GET_ITEM_PROPERTY, GET_RECORD_PROPERTY, RAISE FORM_TRIGGER_FAILURE
- Program units (form): –
- Library / DB package calls: –

```plsql
/* CGAP$OLES_SEQUENCE_BEFORE */
DECLARE
	V_DISP_LOV BOOLEAN := FALSE;
BEGIN
IF :SYSTEM.MODE <> 'ENTER-QUERY' THEN
	IF Get_Record_Property(:SYSTEM.CURSOR_RECORD,:SYSTEM.CURSOR_BLOCK,STATUS) IN ('NEW', 'INSERT') THEN
		IF GET_BLOCK_PROPERTY(:SYSTEM.CURSOR_BLOCK, INSERT_ALLOWED) = 'TRUE' THEN
				IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, ENABLED) = 'TRUE' THEN
					IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, INSERT_ALLOWED) = 'TRUE' THEN
								V_DISP_LOV := TRUE;
					END IF;
				END IF;
		END IF;
	ELSE
		IF GET_BLOCK_PROPERTY(:SYSTEM.CURSOR_BLOCK, UPDATE_ALLOWED) = 'TRUE'	THEN
				IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, ENABLED) = 'TRUE' THEN
					IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, UPDATE_ALLOWED) = 'TRUE' THEN
								V_DISP_LOV := TRUE;
					END IF;
				END IF;
		END IF;
	END IF;
ELSE
	IF GET_BLOCK_PROPERTY(:SYSTEM.CURSOR_BLOCK, QUERY_ALLOWED) = 'TRUE' THEN
		IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, QUERYABLE) = 'TRUE' THEN
					V_DISP_LOV := TRUE;
		END IF;
	END IF;
END IF;
IF NOT V_DISP_LOV THEN
	RAISE FORM_TRIGGER_FAILURE;
END IF;
END;
```

#### IMPORTERS.CTRY_CD_OF_ID · KEY-LISTVAL

- Level: Item · Owner: `IMPORTERS.CTRY_CD_OF_ID` · Execution hierarchy: default (Override)
- Lines: 33 total / 32 active (non-blank, non-comment)
- Built-ins: GET_BLOCK_PROPERTY, GET_ITEM_PROPERTY, GET_RECORD_PROPERTY, RAISE FORM_TRIGGER_FAILURE
- Program units (form): –
- Library / DB package calls: –

```plsql
/* CGAP$OLES_SEQUENCE_BEFORE */
DECLARE
	V_DISP_LOV BOOLEAN := FALSE;
BEGIN
IF :SYSTEM.MODE <> 'ENTER-QUERY' THEN
	IF Get_Record_Property(:SYSTEM.CURSOR_RECORD,:SYSTEM.CURSOR_BLOCK,STATUS) IN ('NEW', 'INSERT') THEN
		IF GET_BLOCK_PROPERTY(:SYSTEM.CURSOR_BLOCK, INSERT_ALLOWED) = 'TRUE' THEN
				IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, ENABLED) = 'TRUE' THEN
					IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, INSERT_ALLOWED) = 'TRUE' THEN
								V_DISP_LOV := TRUE;
					END IF;
				END IF;
		END IF;
	ELSE
		IF GET_BLOCK_PROPERTY(:SYSTEM.CURSOR_BLOCK, UPDATE_ALLOWED) = 'TRUE'	THEN
				IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, ENABLED) = 'TRUE' THEN
					IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, UPDATE_ALLOWED) = 'TRUE' THEN
								V_DISP_LOV := TRUE;
					END IF;
				END IF;
		END IF;
	END IF;
ELSE
	IF GET_BLOCK_PROPERTY(:SYSTEM.CURSOR_BLOCK, QUERY_ALLOWED) = 'TRUE' THEN
		IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, QUERYABLE) = 'TRUE' THEN
					V_DISP_LOV := TRUE;
		END IF;
	END IF;
END IF;
IF NOT V_DISP_LOV THEN
	RAISE FORM_TRIGGER_FAILURE;
END IF;
END;
```

#### IMPR_SUSPN.SUSPN_STRT_DT · KEY-LISTVAL

- Level: Item · Owner: `IMPR_SUSPN.SUSPN_STRT_DT` · Execution hierarchy: default (Override)
- Lines: 26 total / 25 active (non-blank, non-comment)
- Built-ins: GET_BLOCK_PROPERTY, GET_ITEM_PROPERTY, GET_RECORD_PROPERTY
- Program units (form): –
- Library / DB package calls: INTRFACE.DISP_CALENDAR

```plsql
/* CGAP$OLES_SEQUENCE_BEFORE */
IF :SYSTEM.MODE <> 'ENTER-QUERY' THEN
	IF Get_Record_Property(:SYSTEM.CURSOR_RECORD,:SYSTEM.CURSOR_BLOCK,STATUS) IN ('NEW', 'INSERT') THEN
		IF GET_BLOCK_PROPERTY(:SYSTEM.CURSOR_BLOCK, INSERT_ALLOWED) = 'TRUE' THEN
				IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, ENABLED) = 'TRUE' THEN
					IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, INSERT_ALLOWED) = 'TRUE' THEN
								intrface.Disp_Calendar('H', 3, 2, FALSE);
					END IF;
				END IF;
		END IF;
	ELSE
		IF GET_BLOCK_PROPERTY(:SYSTEM.CURSOR_BLOCK, UPDATE_ALLOWED) = 'TRUE'	THEN
				IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, ENABLED) = 'TRUE' THEN
					IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, UPDATE_ALLOWED) = 'TRUE' THEN
								intrface.Disp_Calendar('H', 3, 2, FALSE);
					END IF;
				END IF;
		END IF;
	END IF;
ELSE
	IF GET_BLOCK_PROPERTY(:SYSTEM.CURSOR_BLOCK, QUERY_ALLOWED) = 'TRUE' THEN
		IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, QUERYABLE) = 'TRUE' THEN
				intrface.Disp_Calendar('H', 3, 2, FALSE);
		END IF;
	END IF;
END IF;
```

#### IMPR_SUSPN.SUSPN_STRT_DT · KEY-F4

- Level: Item · Owner: `IMPR_SUSPN.SUSPN_STRT_DT` · Execution hierarchy: default (Override)
- Lines: 26 total / 25 active (non-blank, non-comment)
- Built-ins: GET_BLOCK_PROPERTY, GET_ITEM_PROPERTY, GET_RECORD_PROPERTY
- Program units (form): –
- Library / DB package calls: INTRFACE.DISP_DATE_CON

```plsql
/* CGAP$OLES_SEQUENCE_BEFORE */
IF :SYSTEM.MODE <> 'ENTER-QUERY' THEN
	IF Get_Record_Property(:SYSTEM.CURSOR_RECORD,:SYSTEM.CURSOR_BLOCK,STATUS) IN ('NEW', 'INSERT') THEN
		IF GET_BLOCK_PROPERTY(:SYSTEM.CURSOR_BLOCK, INSERT_ALLOWED) = 'TRUE' THEN
				IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, ENABLED) = 'TRUE' THEN
					IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, INSERT_ALLOWED) = 'TRUE' THEN
								intrface.Disp_date_con('H', 2, 1);
					END IF;
				END IF;
		END IF;
	ELSE
		IF GET_BLOCK_PROPERTY(:SYSTEM.CURSOR_BLOCK, UPDATE_ALLOWED) = 'TRUE'	THEN
				IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, ENABLED) = 'TRUE' THEN
					IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, UPDATE_ALLOWED) = 'TRUE' THEN
								intrface.Disp_date_con('H', 2, 1);
					END IF;
				END IF;
		END IF;
	END IF;
ELSE
	IF GET_BLOCK_PROPERTY(:SYSTEM.CURSOR_BLOCK, QUERY_ALLOWED) = 'TRUE' THEN
		IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, QUERYABLE) = 'TRUE' THEN
				intrface.Disp_date_con('H', 2, 1);
		END IF;
	END IF;
END IF;
```

#### IMPR_SUSPN.SUSPN_STRT_DT · WHEN-VALIDATE-ITEM

- Level: Item · Owner: `IMPR_SUSPN.SUSPN_STRT_DT` · Execution hierarchy: default (Override)
- Lines: 25 total / 21 active (non-blank, non-comment)
- Built-ins: RAISE FORM_TRIGGER_FAILURE
- Program units (form): –
- Library / DB package calls: HIJDATE.COMPARE_HIJ_DATES, HIJDATE.CUR_HIJ_DATE, HIJDATE.VALID_HIJ_DATE, STR.DISPARBMSG

```plsql
/* CGAP$OLES_SEQUENCE_BEFORE */
DECLARE
	HDATE DATE;
BEGIN
	IF :System.TRIGGER_ITEM = :System.CURSOR_ITEM THEN
		IF :System.Cursor_Value IS NOT NULL THEN
			HDATE := TO_DATE(:System.Cursor_Value);

			IF NOT HIJDATE.VALID_HIJ_DATE(HDATE) THEN
				RAISE FORM_TRIGGER_FAILURE;
			END IF;
		END IF;
	END IF;
END;

DECLARE
Ret NUMBER;

BEGIN
IF HIJDATE.COMPARE_HIJ_DATES(:SUSPN_STRT_DT, HIJDATE.Cur_Hij_Date) = -1  THEN
	Ret := STR.DispArbMsg(9, 100,'ERROR');
	:SUSPN_STRT_DT := HIJDATE.Cur_Hij_Date;
	RAISE Form_trigger_failure;
END IF;
END;
```

#### IMPR_SUSPN.SUSPN_STRT_DT · WHEN-NEW-ITEM-INSTANCE

- Level: Item · Owner: `IMPR_SUSPN.SUSPN_STRT_DT` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 5 total / 5 active (non-blank, non-comment)
- Built-ins: –
- Program units (form): –
- Library / DB package calls: HIJDATE.CUR_HIJ_DATE

```plsql
BEGIN
IF :SUSPN_STRT_DT IS NULL THEN
	:SUSPN_STRT_DT := HIJDATE.Cur_Hij_date;
END IF;
END;
```

#### IMPR_SUSPN.SUSPN_END_DT · KEY-LISTVAL

- Level: Item · Owner: `IMPR_SUSPN.SUSPN_END_DT` · Execution hierarchy: default (Override)
- Lines: 26 total / 25 active (non-blank, non-comment)
- Built-ins: GET_BLOCK_PROPERTY, GET_ITEM_PROPERTY, GET_RECORD_PROPERTY
- Program units (form): –
- Library / DB package calls: INTRFACE.DISP_CALENDAR

```plsql
/* CGAP$OLES_SEQUENCE_BEFORE */
IF :SYSTEM.MODE <> 'ENTER-QUERY' THEN
	IF Get_Record_Property(:SYSTEM.CURSOR_RECORD,:SYSTEM.CURSOR_BLOCK,STATUS) IN ('NEW', 'INSERT') THEN
		IF GET_BLOCK_PROPERTY(:SYSTEM.CURSOR_BLOCK, INSERT_ALLOWED) = 'TRUE' THEN
				IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, ENABLED) = 'TRUE' THEN
					IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, INSERT_ALLOWED) = 'TRUE' THEN
								intrface.Disp_Calendar('H', 3, 2, FALSE);
					END IF;
				END IF;
		END IF;
	ELSE
		IF GET_BLOCK_PROPERTY(:SYSTEM.CURSOR_BLOCK, UPDATE_ALLOWED) = 'TRUE'	THEN
				IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, ENABLED) = 'TRUE' THEN
					IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, UPDATE_ALLOWED) = 'TRUE' THEN
								intrface.Disp_Calendar('H', 3, 2, FALSE);
					END IF;
				END IF;
		END IF;
	END IF;
ELSE
	IF GET_BLOCK_PROPERTY(:SYSTEM.CURSOR_BLOCK, QUERY_ALLOWED) = 'TRUE' THEN
		IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, QUERYABLE) = 'TRUE' THEN
				intrface.Disp_Calendar('H', 3, 2, FALSE);
		END IF;
	END IF;
END IF;
```

#### IMPR_SUSPN.SUSPN_END_DT · KEY-F4

- Level: Item · Owner: `IMPR_SUSPN.SUSPN_END_DT` · Execution hierarchy: default (Override)
- Lines: 26 total / 25 active (non-blank, non-comment)
- Built-ins: GET_BLOCK_PROPERTY, GET_ITEM_PROPERTY, GET_RECORD_PROPERTY
- Program units (form): –
- Library / DB package calls: INTRFACE.DISP_DATE_CON

```plsql
/* CGAP$OLES_SEQUENCE_BEFORE */
IF :SYSTEM.MODE <> 'ENTER-QUERY' THEN
	IF Get_Record_Property(:SYSTEM.CURSOR_RECORD,:SYSTEM.CURSOR_BLOCK,STATUS) IN ('NEW', 'INSERT') THEN
		IF GET_BLOCK_PROPERTY(:SYSTEM.CURSOR_BLOCK, INSERT_ALLOWED) = 'TRUE' THEN
				IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, ENABLED) = 'TRUE' THEN
					IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, INSERT_ALLOWED) = 'TRUE' THEN
								intrface.Disp_date_con('H', 2, 1);
					END IF;
				END IF;
		END IF;
	ELSE
		IF GET_BLOCK_PROPERTY(:SYSTEM.CURSOR_BLOCK, UPDATE_ALLOWED) = 'TRUE'	THEN
				IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, ENABLED) = 'TRUE' THEN
					IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, UPDATE_ALLOWED) = 'TRUE' THEN
								intrface.Disp_date_con('H', 2, 1);
					END IF;
				END IF;
		END IF;
	END IF;
ELSE
	IF GET_BLOCK_PROPERTY(:SYSTEM.CURSOR_BLOCK, QUERY_ALLOWED) = 'TRUE' THEN
		IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, QUERYABLE) = 'TRUE' THEN
				intrface.Disp_date_con('H', 2, 1);
		END IF;
	END IF;
END IF;
```

#### IMPR_SUSPN.SUSPN_END_DT · WHEN-VALIDATE-ITEM

- Level: Item · Owner: `IMPR_SUSPN.SUSPN_END_DT` · Execution hierarchy: default (Override)
- Lines: 24 total / 20 active (non-blank, non-comment)
- Built-ins: RAISE FORM_TRIGGER_FAILURE
- Program units (form): –
- Library / DB package calls: HIJDATE.COMPARE_HIJ_DATES, HIJDATE.VALID_HIJ_DATE, STR.DISPARBMSG

```plsql
/* CGAP$OLES_SEQUENCE_BEFORE */
DECLARE
	HDATE DATE;
BEGIN
	IF :System.TRIGGER_ITEM = :System.CURSOR_ITEM THEN
		IF :System.Cursor_Value IS NOT NULL THEN
			HDATE := TO_DATE(:System.Cursor_Value);

			IF NOT HIJDATE.VALID_HIJ_DATE(HDATE) THEN
				RAISE FORM_TRIGGER_FAILURE;
			END IF;
		END IF;
	END IF;
END;

DECLARE
Ret NUMBER;

BEGIN
IF HIJDATE.COMPARE_HIJ_DATES(:SUSPN_END_DT, :SUSPN_STRT_DT) = -1  THEN
	Ret := STR.DispArbMsg(9, 110,'ERROR');
	RAISE Form_trigger_failure;
END IF;
END;
```

#### IMPR_SUSPN.SUSPN_RSN_CD · KEY-LISTVAL

- Level: Item · Owner: `IMPR_SUSPN.SUSPN_RSN_CD` · Execution hierarchy: default (Override)
- Lines: 33 total / 32 active (non-blank, non-comment)
- Built-ins: GET_BLOCK_PROPERTY, GET_ITEM_PROPERTY, GET_RECORD_PROPERTY, RAISE FORM_TRIGGER_FAILURE
- Program units (form): –
- Library / DB package calls: –

```plsql
/* CGAP$OLES_SEQUENCE_BEFORE */
DECLARE
	V_DISP_LOV BOOLEAN := FALSE;
BEGIN
IF :SYSTEM.MODE <> 'ENTER-QUERY' THEN
	IF Get_Record_Property(:SYSTEM.CURSOR_RECORD,:SYSTEM.CURSOR_BLOCK,STATUS) IN ('NEW', 'INSERT') THEN
		IF GET_BLOCK_PROPERTY(:SYSTEM.CURSOR_BLOCK, INSERT_ALLOWED) = 'TRUE' THEN
				IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, ENABLED) = 'TRUE' THEN
					IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, INSERT_ALLOWED) = 'TRUE' THEN
								V_DISP_LOV := TRUE;
					END IF;
				END IF;
		END IF;
	ELSE
		IF GET_BLOCK_PROPERTY(:SYSTEM.CURSOR_BLOCK, UPDATE_ALLOWED) = 'TRUE'	THEN
				IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, ENABLED) = 'TRUE' THEN
					IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, UPDATE_ALLOWED) = 'TRUE' THEN
								V_DISP_LOV := TRUE;
					END IF;
				END IF;
		END IF;
	END IF;
ELSE
	IF GET_BLOCK_PROPERTY(:SYSTEM.CURSOR_BLOCK, QUERY_ALLOWED) = 'TRUE' THEN
		IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, QUERYABLE) = 'TRUE' THEN
					V_DISP_LOV := TRUE;
		END IF;
	END IF;
END IF;
IF NOT V_DISP_LOV THEN
	RAISE FORM_TRIGGER_FAILURE;
END IF;
END;
```

#### IMPR_SUSPN.SUSPN_RSN_CD · WHEN-NEW-ITEM-INSTANCE

- Level: Item · Owner: `IMPR_SUSPN.SUSPN_RSN_CD` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 21 total / 11 active (non-blank, non-comment)
- Built-ins: –
- Program units (form): –
- Library / DB package calls: –

```plsql
BEGIN
IF :IMPR_SUSPN.SUSPN_RSN_CD IS NULL THEN
	IF :PARAMETER.Current_Side = 1 AND :PARAMETER.P_CURR_PORT_CD!=99 THEN
		:IMPR_SUSPN.SUSPN_RSN_CD := 1;
	ELSIF :PARAMETER.Current_Side = 2 AND :PARAMETER.P_CURR_PORT_CD!=99 THEN
		:IMPR_SUSPN.SUSPN_RSN_CD := 2;
	ELSIF :PARAMETER.Current_Side = 3 AND :PARAMETER.P_CURR_PORT_CD=99 THEN
		:IMPR_SUSPN.SUSPN_RSN_CD := 3;

	END IF;

	/*
        SELECT 	RV_MEANING
	INTO		:IMPR_SUSPN.SUSPN_RSN_TEXT
	FROM 		CG_REF_CODES
	WHERE 	RV_DOMAIN = 'SUSPN RSN CD'
	AND		RV_LOW_VALUE = TO_CHAR(:IMPR_SUSPN.SUSPN_RSN_CD);
     */

END IF;
END;
```

#### IMPR_SUSPN.SUSPN_RSN_CD · WHEN-VALIDATE-ITEM

- Level: Item · Owner: `IMPR_SUSPN.SUSPN_RSN_CD` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 25 total / 21 active (non-blank, non-comment)
- Built-ins: RAISE FORM_TRIGGER_FAILURE
- Program units (form): –
- Library / DB package calls: –

```plsql
BEGIN
IF :IMPR_SUSPN.SUSPN_RSN_CD IS NOT NULL THEN
	IF :PARAMETER.Current_Side = 1 AND :IMPR_SUSPN.SUSPN_RSN_CD = 2 THEN
		:IMPR_SUSPN.SUSPN_RSN_CD := 1;
		RAISE Form_Trigger_Failure;
	ELSIF :PARAMETER.Current_Side = 2 AND :IMPR_SUSPN.SUSPN_RSN_CD =1 THEN
		:IMPR_SUSPN.SUSPN_RSN_CD := 2;
		RAISE Form_Trigger_Failure;
      ELSIF  :PARAMETER.Current_Side =3 AND :IMPR_SUSPN.SUSPN_RSN_CD IN(1,2) THEN
            :IMPR_SUSPN.SUSPN_RSN_CD := 3;
		RAISE Form_Trigger_Failure;

      END IF;

	SELECT 	RV_MEANING
	INTO		:IMPR_SUSPN.SUSPN_RSN_TEXT
	FROM 		CG_REF_CODES
	WHERE 	RV_DOMAIN = 'IMPR_SUSPN_RSN_CD'
	AND		RV_LOW_VALUE = TO_CHAR(:IMPR_SUSPN.SUSPN_RSN_CD);

ELSE
	RAISE FORM_TRIGGER_FAILURE;
END IF;

END;
```

#### IMPR_SUSPN.SUSPN_RSN_TEXT · KEY-LISTVAL

- Level: Item · Owner: `IMPR_SUSPN.SUSPN_RSN_TEXT` · Execution hierarchy: default (Override)
- Lines: 33 total / 32 active (non-blank, non-comment)
- Built-ins: GET_BLOCK_PROPERTY, GET_ITEM_PROPERTY, GET_RECORD_PROPERTY, RAISE FORM_TRIGGER_FAILURE
- Program units (form): –
- Library / DB package calls: –

```plsql
/* CGAP$OLES_SEQUENCE_BEFORE */
DECLARE
	V_DISP_LOV BOOLEAN := FALSE;
BEGIN
IF :SYSTEM.MODE <> 'ENTER-QUERY' THEN
	IF Get_Record_Property(:SYSTEM.CURSOR_RECORD,:SYSTEM.CURSOR_BLOCK,STATUS) IN ('NEW', 'INSERT') THEN
		IF GET_BLOCK_PROPERTY(:SYSTEM.CURSOR_BLOCK, INSERT_ALLOWED) = 'TRUE' THEN
				IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, ENABLED) = 'TRUE' THEN
					IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, INSERT_ALLOWED) = 'TRUE' THEN
								V_DISP_LOV := TRUE;
					END IF;
				END IF;
		END IF;
	ELSE
		IF GET_BLOCK_PROPERTY(:SYSTEM.CURSOR_BLOCK, UPDATE_ALLOWED) = 'TRUE'	THEN
				IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, ENABLED) = 'TRUE' THEN
					IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, UPDATE_ALLOWED) = 'TRUE' THEN
								V_DISP_LOV := TRUE;
					END IF;
				END IF;
		END IF;
	END IF;
ELSE
	IF GET_BLOCK_PROPERTY(:SYSTEM.CURSOR_BLOCK, QUERY_ALLOWED) = 'TRUE' THEN
		IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, QUERYABLE) = 'TRUE' THEN
					V_DISP_LOV := TRUE;
		END IF;
	END IF;
END IF;
IF NOT V_DISP_LOV THEN
	RAISE FORM_TRIGGER_FAILURE;
END IF;
END;
```

#### IMPR_SUSPN.SUSPN_RSN_TEXT · WHEN-NEW-ITEM-INSTANCE

- Level: Item · Owner: `IMPR_SUSPN.SUSPN_RSN_TEXT` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 6 total / 5 active (non-blank, non-comment)
- Built-ins: –
- Program units (form): –
- Library / DB package calls: –

```plsql
BEGIN
IF :IMPR_SUSPN.SUSPN_RSN_CD <> 3 THEN
	--go_item('IMPR_SUSPN.SUSPN_SIDE_CD');
	NULL;
END IF;
END;
```

#### IMPR_SUSPN.SUSPN_SIDE_CD · WHEN-LIST-CHANGED

- Level: Item · Owner: `IMPR_SUSPN.SUSPN_SIDE_CD` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 13 total / 12 active (non-blank, non-comment)
- Built-ins: RAISE FORM_TRIGGER_FAILURE
- Program units (form): –
- Library / DB package calls: –

```plsql
BEGIN
      IF :PARAMETER.Current_Side = 1 AND :PARAMETER.P_CURR_PORT_CD!=99 AND  :IMPR_SUSPN.SUSPN_SIDE_CD <> 1 THEN
		:IMPR_SUSPN.SUSPN_SIDE_CD := 1;
		RAISE Form_Trigger_Failure;
	ELSIF :PARAMETER.Current_Side = 2 AND :PARAMETER.P_CURR_PORT_CD!=99 AND :IMPR_SUSPN.SUSPN_SIDE_CD IN (1,5)THEN
		:IMPR_SUSPN.SUSPN_SIDE_CD := 2;
		RAISE Form_Trigger_Failure;
      ELSIF :PARAMETER.Current_Side = 3 AND :PARAMETER.P_CURR_PORT_CD=99 AND :IMPR_SUSPN.SUSPN_SIDE_CD !=5 THEN
		:IMPR_SUSPN.SUSPN_SIDE_CD := 5;
		RAISE Form_Trigger_Failure;

      END IF;
END;
```

#### IMPR_SUSPN.SUSPN_SIDE_CD · WHEN-NEW-ITEM-INSTANCE

- Level: Item · Owner: `IMPR_SUSPN.SUSPN_SIDE_CD` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 16 total / 11 active (non-blank, non-comment)
- Built-ins: –
- Program units (form): –
- Library / DB package calls: –

```plsql
BEGIN
IF :IMPR_SUSPN.SUSPN_SIDE_CD IS NULL THEN

      IF :PARAMETER.Current_Side = 1 AND :PARAMETER.P_CURR_PORT_CD!=99  THEN
		:IMPR_SUSPN.SUSPN_SIDE_CD := 1;

	ELSIF :PARAMETER.Current_Side = 2 AND :PARAMETER.P_CURR_PORT_CD!=99  THEN
		:IMPR_SUSPN.SUSPN_SIDE_CD := 2;

	ELSIF :PARAMETER.Current_Side = 3 AND :PARAMETER.P_CURR_PORT_CD=99  THEN
            :IMPR_SUSPN.SUSPN_SIDE_CD := 5;

      END IF;
END IF;

END;
```

#### IMPR_SUSPN.SUSPN_SIDE_CD · WHEN-VALIDATE-ITEM

- Level: Item · Owner: `IMPR_SUSPN.SUSPN_SIDE_CD` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 5 total / 5 active (non-blank, non-comment)
- Built-ins: RAISE FORM_TRIGGER_FAILURE
- Program units (form): –
- Library / DB package calls: –

```plsql
BEGIN
IF :IMPR_SUSPN.SUSPN_SIDE_CD IS NULL THEN
	RAISE FORM_TRIGGER_FAILURE;
END IF;
END;
```

#### IMPR_SUSPN.SUSPN_RLSE_DT · KEY-LISTVAL

- Level: Item · Owner: `IMPR_SUSPN.SUSPN_RLSE_DT` · Execution hierarchy: default (Override)
- Lines: 26 total / 25 active (non-blank, non-comment)
- Built-ins: GET_BLOCK_PROPERTY, GET_ITEM_PROPERTY, GET_RECORD_PROPERTY
- Program units (form): –
- Library / DB package calls: INTRFACE.DISP_CALENDAR

```plsql
/* CGAP$OLES_SEQUENCE_BEFORE */
IF :SYSTEM.MODE <> 'ENTER-QUERY' THEN
	IF Get_Record_Property(:SYSTEM.CURSOR_RECORD,:SYSTEM.CURSOR_BLOCK,STATUS) IN ('NEW', 'INSERT') THEN
		IF GET_BLOCK_PROPERTY(:SYSTEM.CURSOR_BLOCK, INSERT_ALLOWED) = 'TRUE' THEN
				IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, ENABLED) = 'TRUE' THEN
					IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, INSERT_ALLOWED) = 'TRUE' THEN
								intrface.Disp_Calendar('H', 3, 2, FALSE);
					END IF;
				END IF;
		END IF;
	ELSE
		IF GET_BLOCK_PROPERTY(:SYSTEM.CURSOR_BLOCK, UPDATE_ALLOWED) = 'TRUE'	THEN
				IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, ENABLED) = 'TRUE' THEN
					IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, UPDATE_ALLOWED) = 'TRUE' THEN
								intrface.Disp_Calendar('H', 3, 2, FALSE);
					END IF;
				END IF;
		END IF;
	END IF;
ELSE
	IF GET_BLOCK_PROPERTY(:SYSTEM.CURSOR_BLOCK, QUERY_ALLOWED) = 'TRUE' THEN
		IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, QUERYABLE) = 'TRUE' THEN
				intrface.Disp_Calendar('H', 3, 2, FALSE);
		END IF;
	END IF;
END IF;
```

#### IMPR_SUSPN.SUSPN_RLSE_DT · KEY-F4

- Level: Item · Owner: `IMPR_SUSPN.SUSPN_RLSE_DT` · Execution hierarchy: default (Override)
- Lines: 26 total / 25 active (non-blank, non-comment)
- Built-ins: GET_BLOCK_PROPERTY, GET_ITEM_PROPERTY, GET_RECORD_PROPERTY
- Program units (form): –
- Library / DB package calls: INTRFACE.DISP_DATE_CON

```plsql
/* CGAP$OLES_SEQUENCE_BEFORE */
IF :SYSTEM.MODE <> 'ENTER-QUERY' THEN
	IF Get_Record_Property(:SYSTEM.CURSOR_RECORD,:SYSTEM.CURSOR_BLOCK,STATUS) IN ('NEW', 'INSERT') THEN
		IF GET_BLOCK_PROPERTY(:SYSTEM.CURSOR_BLOCK, INSERT_ALLOWED) = 'TRUE' THEN
				IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, ENABLED) = 'TRUE' THEN
					IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, INSERT_ALLOWED) = 'TRUE' THEN
								intrface.Disp_date_con('H', 2, 1);
					END IF;
				END IF;
		END IF;
	ELSE
		IF GET_BLOCK_PROPERTY(:SYSTEM.CURSOR_BLOCK, UPDATE_ALLOWED) = 'TRUE'	THEN
				IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, ENABLED) = 'TRUE' THEN
					IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, UPDATE_ALLOWED) = 'TRUE' THEN
								intrface.Disp_date_con('H', 2, 1);
					END IF;
				END IF;
		END IF;
	END IF;
ELSE
	IF GET_BLOCK_PROPERTY(:SYSTEM.CURSOR_BLOCK, QUERY_ALLOWED) = 'TRUE' THEN
		IF GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, QUERYABLE) = 'TRUE' THEN
				intrface.Disp_date_con('H', 2, 1);
		END IF;
	END IF;
END IF;
```

#### IMPR_SUSPN.SUSPN_RLSE_DT · WHEN-VALIDATE-ITEM

- Level: Item · Owner: `IMPR_SUSPN.SUSPN_RLSE_DT` · Execution hierarchy: default (Override)
- Lines: 14 total / 12 active (non-blank, non-comment)
- Built-ins: RAISE FORM_TRIGGER_FAILURE
- Program units (form): –
- Library / DB package calls: HIJDATE.VALID_HIJ_DATE

```plsql
/* CGAP$OLES_SEQUENCE_BEFORE */
DECLARE
	HDATE DATE;
BEGIN
	IF :System.TRIGGER_ITEM = :System.CURSOR_ITEM THEN
		IF :System.Cursor_Value IS NOT NULL THEN
			HDATE := TO_DATE(:System.Cursor_Value);

			IF NOT HIJDATE.VALID_HIJ_DATE(HDATE) THEN
				RAISE FORM_TRIGGER_FAILURE;
			END IF;
		END IF;
	END IF;
END;
```

Triggers of this level without code in the XML (164):

| Block | Trigger | Count | Source status | Owners |
|---|---|---|---|---|
| TITLE | KEY-LISTVAL | 5 | OLB code (1 lines): `NULL;` | TITLE.CGSO$CHAR_ARB_ED, TITLE.CGSO$CHAR_ARB_DO_ENB_Y, TITLE.CGSO$CHAR_ARB_MLINE, TITLE.CGSO$CHAR_ARB, TITLE.CGSO$CHAR_ARB_DO |
| EDI_MSG | WHEN-BUTTON-PRESSED | 1 | OLB code (1 lines): `EDI_MSG_LOV;` | EDI_MSG.EDI_MSG_LOVE_BUT |
| LSIDE | WHEN-MOUSE-ENTER | 50 | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | LSIDE.FN1 … LSIDE.FN26 |
| LSIDE | WHEN-MOUSE-LEAVE | 50 | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | LSIDE.FN1 … LSIDE.FN26 |
| LSIDE | WHEN-MOUSE-CLICK | 50 | OLB code (1 lines): `MOUSE_CLICK;` | LSIDE.FN1 … LSIDE.FN26 |
| TOOLBAR | WHEN-BUTTON-PRESSED | 1 | OLB code (4 lines): `do_key('clear_BLOCK');` | TOOLBAR.CLEAR_ALL |
| TOOLBAR | WHEN-BUTTON-PRESSED | 1 | OLB code (26 lines): `SET_ITEM_PROPERTY('SAVE',VISIBLE,PROPERTY_FALSE);` | TOOLBAR.ENTER |
| TOOLBAR | WHEN-BUTTON-PRESSED | 1 | OLB code (1 lines): `do_key('Execute_query');` | TOOLBAR.EXECUTE |
| TOOLBAR | WHEN-BUTTON-PRESSED | 1 | OLB code (1 lines): `do_key('Delete_record');` | TOOLBAR.REMOVE |
| TOOLBAR | WHEN-BUTTON-PRESSED | 1 | OLB code (1 lines): `do_key('LIST_VALUES');` | TOOLBAR.LIST_VALUE |
| TOOLBAR | WHEN-BUTTON-PRESSED | 1 | OLB code (10 lines): `DECLARE` | TOOLBAR.HELP |
| TOOLBAR | WHEN-BUTTON-PRESSED | 1 | OLB code (1 lines): `do_key('Previous_Record');` | TOOLBAR.FIRST_REC |
| TOOLBAR | WHEN-BUTTON-PRESSED | 1 | OLB code (1 lines): `do_key('Scroll_Up');` | TOOLBAR.PAGE_UP |

## 7. LOVs & Record Groups

| LOV | Title | Record group | Return items (column → item) | Attached to items | Validate from list | Auto-display |
|---|---|---|---|---|---|---|
| CGFK$IMPORTERS_PORT_CD | Valid values for رمز الجمــــــــــــــرك | CGFK$IMPORTERS_PORT_CD | PORT_CD → IMPORTERS.PORT_CD; PORT_NAME → IMPORTERS.PORT_NAME; SDP_PORT_STATUS → IMPORTERS.SDP_PORT_STATUS | IMPORTERS.PORT_CD | not in XML (item property `ValidateFromList` absent → default/OLB) | default/OLB |
| CGFK$IMPORTERS_CITY_CODE_OF_ID | Valid values for مصدر الرقم الإستدلالي | CGFK$IMPORTERS_CITY_CODE_OF_ID | CITY_CODE_OF_ID → IMPORTERS.CITY_CODE_OF_ID; ID_CITY_NAME → IMPORTERS.ID_CITY_NAME | IMPORTERS.CITY_CODE_OF_ID | not in XML (item property `ValidateFromList` absent → default/OLB) | default/OLB |
| CGFK$IMPORTERS_CTRY_CD | Valid values for الجنسيــــــــــــــــــــه | CGFK$IMPORTERS_CTRY_CD | CTRY_CD → IMPORTERS.CTRY_CD; CRTY_ARBC_NAME → IMPORTERS.CRTY_ARBC_NAME; CTRY_CTRY_STATUS → IMPORTERS.CTRY_CTRY_STATUS | IMPORTERS.CTRY_CD | not in XML (item property `ValidateFromList` absent → default/OLB) | default/OLB |
| CGFK$IMPORTERS_HQ_IMPR_NBR | Valid values for الرقم الموحد بالمصلحة | CGFK$IMPORTERS_HQ_IMPR_NBR | HQ_IMPR_NBR → IMPORTERS.HQ_IMPR_NBR | IMPORTERS.HQ_IMPR_NBR | not in XML (item property `ValidateFromList` absent → default/OLB) | default/OLB |
| CGFK$IMPORTERS_IMPR_TYPE_CD | قائمة رموز الأنشطة التجاريه | CGFK$IMPORTERS_IMPR_TYPE_CD | IMPR_TYPE_CD → IMPORTERS.IMPR_TYPE_CD; IMPR_TYPE_NAME → IMPORTERS.IMPR_TYPE_NAME | IMPORTERS.IMPR_TYPE_CD | not in XML (item property `ValidateFromList` absent → default/OLB) | default/OLB |

### 7.1 Record groups

#### CGFK$IMPORTERS_PORT_CD
- Type: Query · Attached to LOV: yes
- Columns: PORT_CD Number(3), PORT_NAME (40), SDP_PORT_STATUS Number(1)

```sql
SELECT SDP.PORT_CD  PORT_CD  /* CG$FK */
      ,SDP.PORT_NAME  PORT_NAME
      ,SDP.PORT_STATUS  SDP_PORT_STATUS
FROM   SD_PORTS SDP
```


#### CGFK$IMPORTERS_CITY_CODE_OF_ID
- Type: Query · Attached to LOV: yes
- Columns: CITY_CODE_OF_ID Number(3), ID_CITY_NAME (20)

```sql
SELECT L_CT.CITY_CD  CITY_CODE_OF_ID  /* CG$FK */
      ,L_CT.CITY_ARB_NAME  ID_CITY_NAME
      ,L_CT.CTRY_CD  CTRY_CD_OF_ID
FROM   CITIES L_CT
```


#### CGFK$IMPORTERS_CTRY_CD
- Type: Query · Attached to LOV: yes
- Columns: CTRY_CD Number(3), CRTY_ARBC_NAME (50), CTRY_CTRY_STATUS Number(1)

```sql
SELECT CTRY.CTRY_CD  CTRY_CD  /* CG$FK */
      ,CTRY.CRTY_ARBC_NAME  CRTY_ARBC_NAME
      ,CTRY.CTRY_STATUS  CTRY_CTRY_STATUS
FROM   COUNTRIES CTRY
WHERE  ((
(:SYSTEM.MODE = 'ENTER-QUERY')
)
OR ((:SYSTEM.MODE = 'NORMAL')
AND    CTRY.CTRY_STATUS = 1
))
```


#### CGFK$IMPORTERS_HQ_IMPR_NBR
- Type: Query · Attached to LOV: yes
- Columns: HQ_IMPR_NBR Number(10)

```sql
SELECT HQ_IMPR_NBR  HQ_IMPR_NBR  /* CG$FK */
FROM   HQ_IMPRS
```


#### CGFK$IMPORTERS_IMPR_TYPE_CD
- Type: Query · Attached to LOV: yes
- Columns: IMPR_TYPE_CD Number(3), IMPR_TYPE_NAME (40)

```sql
SELECT ITIDT.IMPR_TYPE_CD  IMPR_TYPE_CD  /* CG$FK */
      ,IT.IMPR_TYPE_NAME  IMPR_TYPE_NAME
      ,ITIDT.BUS_ID_TYPE_CD  BUS_ID_TYPE_CD
      ,ITIDT.STATUS  STATUS
      ,BIT.BUS_ID_TYPE_NAME  BUS_ID_TYPE_NAME
FROM   IMPR_TYPE_ID_TYPES ITIDT
      ,IMPR_TYPES IT
      ,BUS_ID_TYPES BIT
WHERE  ((
(:SYSTEM.MODE = 'ENTER-QUERY')
)
OR ((:SYSTEM.MODE = 'NORMAL')
AND    ITIDT.STATUS = 1
))
AND    IT.IMPR_TYPE_CD = ITIDT.IMPR_TYPE_CD
AND    BIT.BUS_ID_TYPE_CD = ITIDT.BUS_ID_TYPE_CD
```


> **LOV notes**
> - All 5 record groups are Designer FK lookups attached to an LOV; none is orphaned. `CGFK$IMPORTERS_CTRY_CD` and `CGFK$IMPORTERS_IMPR_TYPE_CD` filter on `STATUS = 1` only in NORMAL mode (all rows in ENTER-QUERY).
> - The LOVs are bypassed: KEY-LISTVAL on PORT_CD, IMPR_TYPE_CD, CTRY_CD and CITY_CODE_OF_ID calls the LOV forms `LOV_SD_PORTS`, `LOV_Impr_Type`, `LOV_COUNTRIES`, `LOV_CITIES` (all available in `forms/COMMON/lov_forms/`), which return values through `:GLOBAL.*`. Because the master items are not insertable or updatable, these LOVs are only usable as **query criteria**. In APEX they become filters on the search page.
> - Runtime record group `CGDV$DLRG` (`CREATE_GROUP_FROM_QUERY` / `POPULATE_LIST`) fills 3 list items from `CG_REF_CODES` → shared LOVs on `CG_REF_CODES`.
> - Domain names differ: the list uses `IMPR_SUSPN_RSN_CD`, and the commented-out code in `SUSPN_RSN_CD.WHEN-NEW-ITEM-INSTANCE` used `SUSPN RSN CD`. Only `IMPR_SUSPN_RSN_CD` is active.

## 8. Canvases & Windows

| Canvas | Type | Window | Size (W×H) | Viewport | Tab pages | Items shown | Subclassed from |
|---|---|---|---|---|---|---|---|
| LSIDE | Content (default) / OLB | default/OLB | – | – | – | 0: – | CIC_OLB.olb:LSIDE |
| EDI_MSG | Content (default) / OLB | default/OLB | – | – | – | 0: – | CIC_OLB.olb:EDI_MSG |
| TITLE | Content (default) / OLB | default/OLB | – | – | – | 0: – | CIC_OLB.olb:TITLE |
| TOOLBAR | Content (default) / OLB | default/OLB | – | – | – | 0: – | CIC_OLB.olb:TOOLBAR |
| CG$PAGE_1 | Content (default) / OLB | CGSO$WINDOW_1 | 8300×7200 | 0×7200 | – | 28: PORT_CD, PORT_CD2, PORT_NAME, HQ_IMPR_NBR, IMPR_NBR, IMPR_TYPE_CD, IMPR_TYPE_CD2, IMPR_TYPE_NAME, CTRY_CD, CTRY_CD2, CRTY_ARBC_NAME, CITY_CODE_OF_ID, CITY_CODE_OF_ID2, ID_CITY_NAME, IMPR_EXPR_TYPE, BUS_ID, BUS_ID_TYPE_CD, BUTT, BUS_ID_TYPE_NAME, BUS_ID_BRNCH, ARBC_IMPR_NAME, ENG_IMPR_NAME, IMPR_CNTCT_NAME, SUSPN_STRT_DT, SUSPN_END_DT, SUSPN_RSN_CD, SUSPN_RSN_TEXT, SUSPN_SIDE_CD | cic_olb.olb:CGSO$CANVAS |

| Window | Modal | Title | Size | Subclassed from |
|---|---|---|---|---|
| CGSO$WINDOW_1 | default/OLB | بيانات المستورد | default/OLB | cic_olb.olb:CGSO$WINDOW_1 |

Graphics objects on canvases (boilerplate, from XML):

| Canvas | Name | Type | Subclassed from |
|---|---|---|---|
| LSIDE | LINE617 | not in XML (OLB sub-object) | – |
| TITLE | RECT9 | not in XML (OLB sub-object) | – |
| TITLE | RECT10 | not in XML (OLB sub-object) | – |
| CG$PAGE_1 | CG_BOILERPLATE_GROUP | Group | – |
| CG$PAGE_1 | CG_RECT_1 | not in XML (OLB sub-object) | CIC_OLB.OLB:CG_RECT |
| CG$PAGE_1 | CG_RECT_2 | not in XML (OLB sub-object) | CIC_OLB.OLB:CG_RECT |

> **Canvas/Window notes**
> - `LSIDE`, `EDI_MSG`, `TITLE`, `TOOLBAR` and window `CGSO$WINDOW_1` (title "بيانات المستورد") come from `CIC_OLB.olb`: the screen frame, not migrated.
> - One content canvas `CG$PAGE_1` (no tab pages) holds the importer header (23 items) and the suspension grid (5 columns × 5 rows). In APEX: one main page with a Form region `IMPORTERS` and an IG `IMPR_SUSPN`.

## 9. Program Units

| # | Name | Type | Lines (total / active) | Called by | Uses built-ins | Calls (form PUs) | Library / DB calls |
|---|---|---|---|---|---|---|---|
| 1 | CHECK_TIMEOUT | Function | 34 / 10 | not referenced in XML code | TEXT_IO | – | NIB.CHECK_TIMEOUT |
| 2 | MOUSE_CLICK | Procedure | 10 / 7 | not referenced in XML code | COPY, GO_ITEM, NAME_IN, SET_ITEM_PROPERTY | EXECUTE_FUNCTION | – |
| 3 | TOGGEL_WND | Procedure | 27 / 5 | not referenced in XML code | – | – | NIB.TOGGEL_WND |
| 4 | PRINT_REPORT | Procedure | 121 / 14 | not referenced in XML code | – | – | NIB.PRINT_REPORT |
| 5 | EXECUTE_FUNCTION | Procedure | 160 / 144 | PU MOUSE_CLICK, TOOLBAR.KEY-NEXT-ITEM | ADD_PARAMETER, CALL_FORM, CREATE_PARAMETER_LIST, DEFAULT_VALUE, DESTROY_PARAMETER_LIST, GET_PARAMETER_LIST, ID_NULL, NAME_IN, SET_VIEW_PROPERTY, RAISE FORM_TRIGGER_FAILURE | EXEC_FUNS | ADJ_PRN.ADJ_REPORT_PRINTER, REP.RUN_PRODUCT, STR.DISPALERT, TMPLT.FUN_ITEMS |
| 6 | TERMINATE_FUN | Procedure | 17 / 7 | not referenced in XML code | – | – | NIB.TERMINATE_FUN |
| 7 | CHECK_EDI_MSG_LOV | Function | 26 / 9 | not referenced in XML code | – | – | NIB.CHECK_EDI_MSG_LOV |
| 8 | CHECK_EDI_MSG_TIMER | Function | 26 / 9 | not referenced in XML code | – | – | NIB.CHECK_EDI_MSG_TIMER |
| 9 | CHECK_EDI_ROLE_ID | Function | 42 / 9 | not referenced in XML code | – | – | NIB.CHECK_EDI_ROLE_ID |
| 10 | EDI_MSG_LOV | Procedure | 40 / 8 | not referenced in XML code | – | – | NIB.EDI_MSG_LOV |
| 11 | FOR_EDI_MSG | Procedure | 26 / 5 | not referenced in XML code | – | – | NIB.FOR_EDI_MSG |
| 12 | RETURN_MSG | Procedure | 19 / 6 | not referenced in XML code | – | – | NIB.RETURN_MSG |
| 13 | TURN_MSG | Procedure | 19 / 6 | not referenced in XML code | – | – | NIB.TURN_MSG |
| 14 | WHEN_TIMER_EXPIRED_MSG | Procedure | 32 / 8 | not referenced in XML code | – | – | NIB.WHEN_TIMER_EXPIRED_MSG |
| 15 | CG$WHEN_NEW_FORM_INSTANCE | Procedure | 23 / 14 | FORM.KEY-CLRFRM, FORM.WHEN-NEW-FORM-INSTANCE | – | CGBS$SET_QUERY_MODE, CGDV$POPULATE_DYNAMIC_LISTS | CGBS$.SET_RELATIONS, CGTE$OTHER_EXCEPTIONS |
| 16 | CGDV$POPULATE_DYNAMIC_LISTS | Procedure | 34 / 29 | PU CG$WHEN_NEW_FORM_INSTANCE | CREATE_GROUP_FROM_QUERY, DELETE_GROUP, POPULATE_GROUP, POPULATE_LIST | – | – |
| 17 | CGFK$QRY_IMPORTERS_IMP_SDP_FK | Procedure | 25 / 23 | IMPORTERS.POST-QUERY | – | – | – |
| 18 | CGFK$CHK_IMPORTERS_IMP_SDP_FK | Procedure | 25 / 23 | not referenced in XML code | – | – | – |
| 19 | CG$IMPR1120_GLOBALS | Package Spec | 4 / 3 | IMPORTERS.POST-QUERY, IMPORTERS.PRE-QUERY | – | – | – |
| 20 | CGFK$QRY_IMPORTERS_IMP_ITIDT_F | Procedure | 36 / 34 | IMPORTERS.POST-QUERY | – | – | – |
| 21 | CGFK$CHK_IMPORTERS_IMP_ITIDT_F | Procedure | 37 / 35 | IMPORTERS.IMPR_TYPE_CD.WHEN-VALIDATE-ITEM | – | – | – |
| 22 | CGFK$QRY_IMPORTERS_IMP_CTRY_FK | Procedure | 25 / 23 | IMPORTERS.POST-QUERY | – | – | – |
| 23 | CGFK$CHK_IMPORTERS_IMP_CTRY_FK | Procedure | 26 / 24 | not referenced in XML code | – | – | – |
| 24 | CGFK$QRY_IMPORTERS_IMP_BUS_ID_ | Procedure | 28 / 26 | IMPORTERS.POST-QUERY | – | – | – |
| 25 | CGFK$CHK_IMPORTERS_IMP_BUS_ID_ | Procedure | 28 / 26 | not referenced in XML code | – | – | – |
| 26 | CGFK$CHK_IMPR_SUSPN_IS_1_IMP_F | Procedure | 24 / 22 | not referenced in XML code | – | – | CG$DUMMY |
| 27 | CGUV$CHK_IS_1_PK | Procedure | 27 / 24 | not referenced in XML code | – | – | CG$DUMMY |
| 28 | CGTE$CHECK_CONSTRAINT_VIO | Function | 51 / 43 | IMPORTERS.ON-ERROR, IMPR_SUSPN.ON-ERROR | – | – | CGTE$STRIP_CONSTRAINT, CGTE$STRIP_FIRST_ERROR, DES$FORM_ERRORS.MSGGETTEXT, DES$FORM_ERRORS.PUSH |
| 29 | CGBS$TOGGLE | Procedure | 24 / 15 | FORM.KEY-MENU | – | CGBS$MESSAGE_QUERY_MODE, CGBS$SET_QUERY_MODE | CGBS$.COORD_VISIBLE_BLKS, CGBS$.SET_RELATIONS |
| 30 | CGBS$SET_QUERY_MODE | Procedure | 7 / 5 | PU CG$WHEN_NEW_FORM_INSTANCE, PU CGBS$TOGGLE | – | – | – |
| 31 | CGBS$MESSAGE_QUERY_MODE | Procedure | 11 / 9 | PU CGBS$TOGGLE | – | – | DES$FORM_ERRORS.PUSH |
| 32 | EXEC_FUNS | Procedure | 4 / 4 | PU EXECUTE_FUNCTION | – | – | – |
| 33 | ADJ_FUNS | Procedure | 4 / 4 | FORM.KEY-F9, TOOLBAR.FUN_BUT.WHEN-MOUSE-DOWN | – | – | – |

### PU CHECK_TIMEOUT (Function, 34 lines)

```plsql
/* Formatted on 14/05/2026 03:56:14 ? (QP5 v5.287) */
FUNCTION CHECK_TIMEOUT
   RETURN BOOLEAN
IS
   HFILE        TEXT_IO.FILE_TYPE;
   V_FILENAME   VARCHAR2 (2000);
   V_RETURN     BOOLEAN;
BEGIN
   /*BEGIN
    SELECT VAR_VALUE
    INTO V_FILENAME
    FROM SC_PORT_SETTING
    WHERE PORT_CD = :PARAMETER.P_CURR_PORT_CD -- NALSALEH CENTRALIZED PROJECT
    AND SYSOBJ_ID = 999
    AND VAR_NAME = 'NO_TIMEOUT_FILENAME'
    ;
   EXCEPTION
   WHEN NO_DATA_FOUND THEN
    RETURN TRUE;
   END;

   HFILE := TEXT_IO.FOPEN(V_FILENAME, 'R');
   TEXT_IO.FCLOSE(HFILE);
   RETURN(FALSE);

  EXCEPTION
    WHEN OTHERS THEN
     RETURN(TRUE);*/



   V_RETURN := NIB.CHECK_TIMEOUT;
   RETURN V_RETURN;
END;
```

### PU MOUSE_CLICK (Procedure, 10 lines)

```plsql
------------------------------------------------------------------------------
	PROCEDURE MOUSE_CLICK IS
------------------------------------------------------------------------------
	BEGIN
		Set_Item_Property(NAME_IN('SYSTEM.TRIGGER_ITEM'), VISUAL_ATTRIBUTE, 'STD_NORMAL_FUNCTION');
		Execute_Function(NAME_IN('SYSTEM.TRIGGER_ITEM'));
		GO_ITEM(NAME_IN('PARAMETER.P_CURRENT_ITEM'));
		COPY ('', 'PARAMETER.P_CURRENT_ITEM');

	END MOUSE_CLICK ;
```

### PU TOGGEL_WND (Procedure, 27 lines)

```plsql
/* Formatted on 14/05/2026 03:58:00 ? (QP5 v5.287) */
PROCEDURE TOGGEL_WND
IS
BEGIN
   /*DECLARE
    RET   PLS_INTEGER;
    WND   PLS_INTEGER;
    WND_TXT VARCHAR2(100);
   BEGIN
    WND_TXT := GET_WINDOW_PROPERTY('CGSO$WINDOW_1', WINDOW_HANDLE);
    WND     := TO_NUMBER(WND_TXT);
    RET     := SEC_DLL.ToggleWndCaption(WND);
   END;*/

   /*

     DECLARE
    RET   PLS_INTEGER;
    WND   PLS_INTEGER;
   BEGIN
    WND     := WIN_API_UTILITY.GET_ACTIVE_WINDOW();
    RET     := SEC_DLL.ToggleWndCaption(WND);
   END;
   */

   NIB.TOGGEL_WND;
END;
```

### PU PRINT_REPORT (Procedure, 121 lines)

```plsql
------------------------------------------------------------------------------
	PROCEDURE PRINT_REPORT(FN In VARCHAR2, PL_ID PARAMLIST, V_REP_FRM_FLG NUMBER, V_REP_PRNT_FLG NUMBER) IS
------------------------------------------------------------------------------
	FOUND_CD BOOLEAN := FALSE;
	ROW_COUNT NUMBER := 1;


	V_MOD_ID NUMBER;
	V_MSG VARCHAR2(500);
	V_PATH VARCHAR2(200);
	V_CALLED_FORM VARCHAR2(200);
	V_MOD_NAME VARCHAR2(200);
	V_SEQ_NO NUMBER;
	V_SYS_TYPE	NUMBER;
	V_FILE_NAME VARCHAR2(200);
/*
	cursor c_modudle_parameter(p_mid 	NUMBER)
	is select VAR_NAME ,VAR_VALUE
	from sc_port_setting
	where PORT_CD = :PARAMETER.P_CURR_PORT_CD
	AND	sysobj_id = p_mid;
*/
	BEGIN
/*	  IF FN IS NOT NULL THEN
	  	WHILE ROW_COUNT <= TMPLT.FUN_ITEMS_COUNT AND NOT FOUND_CD LOOP
	  		IF TMPLT.FUN_ITEMS(ROW_COUNT).CD LIKE FN THEN
	  			FOUND_CD := TRUE;
	  		ELSE
		  		ROW_COUNT := ROW_COUNT + 1;
	  		END IF;
	  	END LOOP;

	  	IF FOUND_CD THEN
					IF TMPLT.FUN_ITEMS(ROW_COUNT).MID IS NOT NULL THEN
							BEGIN
						  	SELECT SYS_OS_FILE_NAME, SYS_ANAME, SYS_TYPE, SEQ_NO
					  		INTO V_FILE_NAME, V_MOD_NAME, V_SYS_TYPE, V_SEQ_NO
					  		FROM sc_system_objects
					  		WHERE SYS_TYPE = 6
					  		AND SYS_STATUS = 1
					  		AND SYSOBJ_ID = TMPLT.FUN_ITEMS(ROW_COUNT).MID;
							EXCEPTION
									WHEN NO_DATA_FOUND THEN
					  			STR.DISPALERT('الشاشة المطلوبة غير معرفة داخل نظام الأمن' ,'ERROR');
							END;

							IF V_FILE_NAME IS NOT NULL THEN
					      ADD_PARAMETER(pl_id ,'P_USER_ID',TEXT_PARAMETER,:PARAMETER.P_USER_ID);
					      ADD_PARAMETER(pl_id ,'P_USER_NAME',TEXT_PARAMETER,:PARAMETER.P_USER_NAME);
					      ADD_PARAMETER(pl_id ,'P_WS_ID',TEXT_PARAMETER,:PARAMETER.P_WS_ID);
					      ADD_PARAMETER(pl_id ,'P_CURR_PORT_CD',TEXT_PARAMETER,:PARAMETER.P_CURR_PORT_CD);
					      ADD_PARAMETER(pl_id ,'P_PORT_TYPE',TEXT_PARAMETER,:PARAMETER.P_PORT_TYPE);
							  Add_Parameter(pl_id ,'P_GROUP_CD', TEXT_PARAMETER,:PARAMETER.P_GROUP_CD);
							  Add_Parameter(pl_id ,'P_USER_TYPE', TEXT_PARAMETER, :PARAMETER.P_USER_TYPE);
							  Add_Parameter(pl_id ,'P_JOB_ID', TEXT_PARAMETER, :PARAMETER.P_JOB_ID);
							  Add_Parameter(pl_id, 'P_CLASS_CD', TEXT_PARAMETER, :PARAMETER.P_CLASS_CD);
					      ADD_PARAMETER(pl_id ,'P_MODULE_ID',TEXT_PARAMETER,TMPLT.FUN_ITEMS(ROW_COUNT).MID);
					      ADD_PARAMETER(pl_id ,'P_MODULE_NAME',TEXT_PARAMETER,V_MOD_NAME);
						    ADD_PARAMETER(pl_id,'P_BRKR_PORT_CD' ,TEXT_PARAMETER,:PARAMETER.P_BRKR_PORT_CD);
		     				ADD_PARAMETER(pl_id,'P_SHPG_AGNT_NBR',TEXT_PARAMETER,:PARAMETER.P_SHPG_AGNT_NBR);
		     				ADD_PARAMETER(pl_id,'P_BRKR_NBR'      ,TEXT_PARAMETER,:PARAMETER.P_BRKR_NBR);
		     				ADD_PARAMETER(pl_id,'P_LIC_TYPE'     ,TEXT_PARAMETER,:PARAMETER.P_LIC_TYPE);
		     				ADD_PARAMETER(pl_id,'P_BANK_CD'      ,TEXT_PARAMETER,:PARAMETER.P_BANK_CD);
		     				ADD_PARAMETER(pl_id,'P_BANK_BRNCH_CD',TEXT_PARAMETER,:PARAMETER.P_BANK_BRNCH_CD);

								DEFAULT_VALUE('0', 'GLOBAL.SYSTEM_OBJ');
	     					ADD_PARAMETER(pl_id,'P_SYS_ID',TEXT_PARAMETER,:GLOBAL.SYSTEM_OBJ);
	     					ADD_PARAMETER(pl_id,'P_REP_NO',TEXT_PARAMETER,V_SEQ_NO);

						    for i in c_modudle_parameter(TMPLT.FUN_ITEMS(ROW_COUNT).MID)
				  			loop
				  				ADD_PARAMETER(pl_id ,i.VAR_NAME,TEXT_PARAMETER,i.VAR_VALUE);
				  			end loop;

								V_CALLED_FORM := TMPLT.FUN_ITEMS(ROW_COUNT).PATH;
								IF SUBSTR(V_CALLED_FORM, LENGTH(V_CALLED_FORM), 1) <> '\' THEN
								  		V_CALLED_FORM := V_CALLED_FORM||'\';
								END IF;


								V_CALLED_FORM := V_CALLED_FORM||V_FILE_NAME;
					      IF V_REP_FRM_FLG = 1 THEN
									CALL_FORM(V_CALLED_FORM,
								          no_hide,
								          no_replace,
								          no_query_only,
								          pl_id);
								ELSIF V_REP_PRNT_FLG = 1 THEN
	      					ADD_PARAMETER(pl_id,'DESTYPE',TEXT_PARAMETER,'PRINTER');
	      					Add_Parameter(pl_id,'PARAMFORM',TEXT_PARAMETER,'NO');
	      					ADD_PARAMETER(pl_id,'ORACLE_SHUTDOWN',TEXT_PARAMETER,'YES');
 									IF ADJ_PRN.ADJ_REPORT_PRINTER(TMPLT.FUN_ITEMS(ROW_COUNT).MID, V_MSG) = TRUE THEN
										rep.Run_Product(REPORTS,V_CALLED_FORM,SYNCHRONOUS,BATCH,FILESYSTEM,pl_id,NULL);
 									ELSIF V_MSG IS NOT NULL THEN
 										STR.DISPALERT(V_MSG, 'ERROR');
 									ELSE
 										STR.DISPALERT('لا يمكن ضبط الطابعة للتقرير', 'ERROR');
 									END IF;
								ELSE
	      					Add_Parameter(pl_id,'PARAMFORM',TEXT_PARAMETER,'NO');
	      					ADD_PARAMETER(pl_id,'ORACLE_SHUTDOWN',TEXT_PARAMETER,'YES');
	      					ADD_PARAMETER(pl_id,'MAXIMIZE',TEXT_PARAMETER,'YES');
 									IF ADJ_PRN.ADJ_REPORT_PRINTER(TMPLT.FUN_ITEMS(ROW_COUNT).MID, V_MSG) = TRUE THEN
										rep.Run_Product(REPORTS,V_CALLED_FORM,SYNCHRONOUS,RUNTIME,FILESYSTEM,pl_id,NULL);
 									ELSIF V_MSG IS NOT NULL THEN
 										STR.DISPALERT(V_MSG, 'ERROR');
 									ELSE
 										STR.DISPALERT('لا يمكن ضبط الطابعة للتقرير', 'ERROR');
 									END IF;
	     					END IF;
						  ELSE
				  			STR.DISPALERT('مسار ملف التقرير غير معرفة داخل نظام الأمن' ,'ERROR');
						  END IF;
				ELSE
				  			STR.DISPALERT('ملف التقرير غير معرف داخل نظام الأمن' ,'ERROR');
				END IF;
	  	END IF;
	  END IF;*/

	  NIB.PRINT_REPORT(FN,PL_ID,V_REP_FRM_FLG,V_REP_PRNT_FLG);
	END PRINT_REPORT;
```

### PU EXECUTE_FUNCTION (Procedure, 160 lines)

```plsql
------------------------------------------------------------------------------
	PROCEDURE Execute_Function(FN In VARCHAR2) IS
------------------------------------------------------------------------------
	FOUND_CD BOOLEAN := FALSE;
	ROW_COUNT NUMBER := 1;
	CD_TITLE VARCHAR2(200);
	RET NUMBER;
	V_MSG VARCHAR2(2000);

	V_MOD_ID NUMBER;
	V_PATH VARCHAR2(200);
	pl_id   ParamList;
	V_CALLED_FORM VARCHAR2(200);
	V_MOD_NAME VARCHAR2(200);
	V_SEQ_NO NUMBER;
	V_SYS_TYPE	NUMBER;
	V_FILE_NAME VARCHAR2(200);

	cursor c_modudle_parameter(p_mid 	NUMBER)
	is select VAR_NAME ,VAR_VALUE
	from sc_port_setting
	where PORT_CD = :PARAMETER.P_CURR_PORT_CD -- NALSALEH CENTRALIZED PROJECT
	AND sysobj_id = p_mid;

	BEGIN
	  IF FN IS NOT NULL THEN
			SET_VIEW_PROPERTY('LSIDE', VISIBLE, PROPERTY_FALSE);
			CD_TITLE := NAME_IN(FN);

	  	WHILE ROW_COUNT <= TMPLT.FUN_ITEMS_COUNT AND NOT FOUND_CD LOOP
	  		IF TMPLT.FUN_ITEMS(ROW_COUNT).TITLE LIKE CD_TITLE AND TMPLT.FUN_ITEMS(ROW_COUNT).ACT = 1 THEN
	  			FOUND_CD := TRUE;
	  		ELSE
		  		ROW_COUNT := ROW_COUNT + 1;
	  		END IF;

	  	END LOOP;

	  	IF FOUND_CD THEN
					IF TMPLT.FUN_ITEMS(ROW_COUNT).MID IS NOT NULL THEN
							BEGIN
						  	SELECT SYS_OS_FILE_NAME, SYS_ANAME, SYS_TYPE, SEQ_NO
					  		INTO V_FILE_NAME, V_MOD_NAME, V_SYS_TYPE, V_SEQ_NO
					  		FROM sc_system_objects
					  		WHERE SYS_TYPE IN (5,6)
					  		AND SYS_STATUS = 1
					  		AND SYSOBJ_ID = TMPLT.FUN_ITEMS(ROW_COUNT).MID;
							EXCEPTION
									WHEN NO_DATA_FOUND THEN
					  			STR.DISPALERT('الشاشة المطلوبة غير معرفة داخل نظام الأمن او انها غير فعالة' ,'ERROR');
							END;

							IF V_FILE_NAME IS NOT NULL THEN
						   pl_id := Get_Parameter_List('TMPLT_MOD_CALL');
						   IF Id_Null(pl_id) THEN
						     pl_id := Create_Parameter_List('TMPLT_MOD_CALL');
						     IF Id_Null(pl_id) THEN
						       ret := Str.Dispalert('Error creating parameter list TMPLT_MOD_CALL IN TEMPLATE ', 'SYSTEM_ERROR');
						       RAISE Form_Trigger_Failure;
						     END IF;

					      ADD_PARAMETER(pl_id ,'P_USER_ID',TEXT_PARAMETER,:PARAMETER.P_USER_ID);
					      ADD_PARAMETER(pl_id ,'P_USER_NAME',TEXT_PARAMETER,:PARAMETER.P_USER_NAME);
					      ADD_PARAMETER(pl_id ,'P_WS_ID',TEXT_PARAMETER,:PARAMETER.P_WS_ID);
					      ADD_PARAMETER(pl_id ,'P_CURR_PORT_CD',TEXT_PARAMETER,:PARAMETER.P_CURR_PORT_CD);
					      ADD_PARAMETER(pl_id ,'P_PORT_TYPE',TEXT_PARAMETER,:PARAMETER.P_PORT_TYPE);
							  Add_Parameter(pl_id ,'P_GROUP_CD', TEXT_PARAMETER,:PARAMETER.P_GROUP_CD);
							  Add_Parameter(pl_id ,'P_USER_TYPE', TEXT_PARAMETER, :PARAMETER.P_USER_TYPE);
							  Add_Parameter(pl_id ,'P_JOB_ID', TEXT_PARAMETER, :PARAMETER.P_JOB_ID);
							  Add_Parameter(pl_id, 'P_CLASS_CD', TEXT_PARAMETER, :PARAMETER.P_CLASS_CD);
					      ADD_PARAMETER(pl_id ,'P_MODULE_ID',TEXT_PARAMETER,TMPLT.FUN_ITEMS(ROW_COUNT).MID);
					      ADD_PARAMETER(pl_id ,'P_MODULE_NAME',TEXT_PARAMETER,V_MOD_NAME);
						    ADD_PARAMETER(pl_id,'P_BRKR_PORT_CD' ,TEXT_PARAMETER,:PARAMETER.P_BRKR_PORT_CD);
		     				ADD_PARAMETER(pl_id,'P_SHPG_AGNT_NBR',TEXT_PARAMETER,:PARAMETER.P_SHPG_AGNT_NBR);
		     				ADD_PARAMETER(pl_id,'P_BRKR_NBR'      ,TEXT_PARAMETER,:PARAMETER.P_BRKR_NBR);
		     				ADD_PARAMETER(pl_id,'P_LIC_TYPE'     ,TEXT_PARAMETER,:PARAMETER.P_LIC_TYPE);
		     				ADD_PARAMETER(pl_id,'P_BANK_CD'      ,TEXT_PARAMETER,:PARAMETER.P_BANK_CD);
		     				ADD_PARAMETER(pl_id,'P_BANK_BRNCH_CD',TEXT_PARAMETER,:PARAMETER.P_BANK_BRNCH_CD);
						    for i in c_modudle_parameter(TMPLT.FUN_ITEMS(ROW_COUNT).MID)
				  			loop
				  				ADD_PARAMETER(pl_id ,i.VAR_NAME,TEXT_PARAMETER,i.VAR_VALUE);
				  			end loop;

								EXEC_FUNS(TMPLT.FUN_ITEMS(ROW_COUNT).CD);
						    pl_id := Get_Parameter_List('TMPLT_MOD_CALL');
					   		IF NOT Id_Null(pl_id) THEN
								  	V_CALLED_FORM := TMPLT.FUN_ITEMS(ROW_COUNT).PATH;
								  	IF SUBSTR(V_CALLED_FORM, LENGTH(V_CALLED_FORM), 1) <> '\' THEN
								  		V_CALLED_FORM := V_CALLED_FORM||'\';
								  	END IF;


								  	V_CALLED_FORM := V_CALLED_FORM||V_FILE_NAME;
										IF V_SYS_TYPE = 5 THEN
											  CALL_FORM(V_CALLED_FORM,
										              no_hide,
										              no_replace,
										              no_query_only,
										              pl_id);
										ELSE
												DEFAULT_VALUE('0', 'GLOBAL.SYSTEM_OBJ');
						     				ADD_PARAMETER(pl_id,'P_SYS_ID',TEXT_PARAMETER,:GLOBAL.SYSTEM_OBJ);
	  	   								ADD_PARAMETER(pl_id,'P_REP_NO',TEXT_PARAMETER,V_SEQ_NO);
                        ADD_PARAMETER(pl_id,'P_REPORT_NO',TEXT_PARAMETER,:GLOBAL.SYSTEM_OBJ ||'-'||V_SEQ_NO);
									     IF TMPLT.FUN_ITEMS(ROW_COUNT).FORM_FLAG = 1 THEN
												  CALL_FORM(V_CALLED_FORM,
											              no_hide,
											              no_replace,
											              no_query_only,
											              pl_id);
									     ELSIF TMPLT.FUN_ITEMS(ROW_COUNT).PRNT_FLAG = 1 THEN
	      									ADD_PARAMETER(pl_id,'DESTYPE',TEXT_PARAMETER,'PRINTER');
	      									Add_Parameter(pl_id,'PARAMFORM',TEXT_PARAMETER,'NO');
	      									ADD_PARAMETER(pl_id,'ORACLE_SHUTDOWN',TEXT_PARAMETER,'YES');

	      									IF ADJ_PRN.ADJ_REPORT_PRINTER(TMPLT.FUN_ITEMS(ROW_COUNT).MID, V_MSG) = TRUE THEN
									  				REP.Run_Product(REPORTS,V_CALLED_FORM,SYNCHRONOUS,BATCH,FILESYSTEM,pl_id,NULL);
	      									ELSIF V_MSG IS NOT NULL THEN
	      										STR.DISPALERT(V_MSG, 'ERROR');
	      									ELSE
	      										STR.DISPALERT('لا يمكن ضبط الطابعة للتقرير', 'ERROR');
	      									END IF;
									     ELSE
	      									Add_Parameter(pl_id,'PARAMFORM',TEXT_PARAMETER,'NO');
	      									ADD_PARAMETER(pl_id,'ORACLE_SHUTDOWN',TEXT_PARAMETER,'YES');
	      									ADD_PARAMETER(pl_id,'MAXIMIZE',TEXT_PARAMETER,'YES');
	      									IF ADJ_PRN.ADJ_REPORT_PRINTER(TMPLT.FUN_ITEMS(ROW_COUNT).MID, V_MSG) = TRUE THEN
										  			REP.Run_Product(REPORTS,V_CALLED_FORM,SYNCHRONOUS,RUNTIME,FILESYSTEM,pl_id,NULL);
	      									ELSIF V_MSG IS NOT NULL THEN
	      										STR.DISPALERT(V_MSG, 'ERROR');
	      									ELSE
	      										STR.DISPALERT('لا يمكن ضبط الطابعة للتقرير', 'ERROR');
	      									END IF;

	     								 END IF;
										END IF;

										:PARAMETER.P_CTRL_LAST_EXEC_CD := TMPLT.FUN_ITEMS(ROW_COUNT).CD;
									  EXEC_FUNS('MOD_CALL_BACK');
									  :PARAMETER.P_CTRL_LAST_EXEC_CD := NULL;
	  						    Destroy_Parameter_List(pl_id);
					   		END IF;
							 ELSE
							   ret := Str.DispAlert('Parameter list '||'TMPLT_MOD_CALL'||' already exists!','INFORMATION');
							   RAISE Form_Trigger_Failure;
							 END IF;
						  ELSE
				  			RET := STR.DISPALERT('الشاشة المطلوبة غير معرفة داخل نظام الأمن او انها غير فعالة' ,'ERROR');
						  END IF;
				ELSE
						EXEC_FUNS(TMPLT.FUN_ITEMS(ROW_COUNT).CD);
						:PARAMETER.P_CTRL_LAST_EXEC_CD := TMPLT.FUN_ITEMS(ROW_COUNT).CD;
					  EXEC_FUNS('MOD_CALL_BACK');
					  :PARAMETER.P_CTRL_LAST_EXEC_CD := NULL;
				END IF;
	  	ELSE
	  		RET := STR.DISPALERT('خطأ داخلي في أكواد الوظائف - إتصل بالمساندة الفنية' ,'ERROR');
	  	END IF;
	  END IF;
	END Execute_Function;
```

### PU TERMINATE_FUN (Procedure, 17 lines)

```plsql
/* Formatted on 14/05/2026 03:57:49 ? (QP5 v5.287) */
PROCEDURE TERMINATE_FUN
IS
   PL_ID     PARAMLIST;
   PL_NAME   VARCHAR2 (100) := 'TMPLT_MOD_CALL';
BEGIN
   /* pl_id := Get_Parameter_List(pl_name);
   IF NOT Id_Null(pl_id) THEN
      Destroy_Parameter_List(pl_id);
   END IF;
   -- BY SHERIFT @29/01/2007
     ISSUE_ROLLBACK(null);
  -- ROLLBACK;
   --
   RAISE FORM_TRIGGER_FAILURE;*/
   NIB.TERMINATE_FUN;
END;
```

### PU CHECK_EDI_MSG_LOV (Function, 26 lines)

```plsql
/* Formatted on 14/05/2026 03:54:50 ? (QP5 v5.287) */
FUNCTION CHECK_EDI_MSG_LOV
   RETURN BOOLEAN
IS
   V_COUNT    NUMBER;
   V_RETURN   BOOLEAN;
BEGIN
   /*
     SELECT COUNT(*) INTO V_COUNT
    FROM SC_PORT_SETTING
    WHERE PORT_CD = :PARAMETER.P_CURR_PORT_CD -- NALSALEH CENTRALIZED PROJECT
    AND SYSOBJ_ID = 30
    AND VAR_NAME   = 'EDIMSG1220_LOV'
    AND VAR_VALUE > 0
    ;

  IF V_COUNT > 0 THEN
   RETURN(TRUE);
  ELSE
   RETURN(FALSE);
  END IF;
   */

   V_RETURN := NIB.CHECK_EDI_MSG_LOV;
   RETURN V_RETURN;
END;
```

### PU CHECK_EDI_MSG_TIMER (Function, 26 lines)

```plsql
/* Formatted on 14/05/2026 03:55:00 ? (QP5 v5.287) */
FUNCTION CHECK_EDI_MSG_TIMER
   RETURN BOOLEAN
IS
   V_COUNT    NUMBER;
   V_RETURN   BOOLEAN;
BEGIN
   /*  SELECT COUNT(*) INTO V_COUNT
     FROM SC_PORT_SETTING
     WHERE PORT_CD = :PARAMETER.P_CURR_PORT_CD -- NALSALEH CENTRALIZED PROJECT
     AND SYSOBJ_ID = 30
     AND VAR_NAME   = 'EDI_MSG_TIMERS'
     AND VAR_VALUE > 0
     ;

   IF V_COUNT > 0 THEN
    RETURN(TRUE);
   ELSE
    RETURN(FALSE);
   END IF; */



   V_RETURN := NIB.CHECK_EDI_MSG_TIMER;
   RETURN V_RETURN;
END;
```

### PU CHECK_EDI_ROLE_ID (Function, 42 lines)

```plsql
/* Formatted on 14/05/2026 03:55:11 ? (QP5 v5.287) */
FUNCTION CHECK_EDI_ROLE_ID (V_PORT_CD NUMBER, V_USER_ID VARCHAR2)
   RETURN BOOLEAN
IS
   V_ROLE_ID   VARCHAR2 (30);
   V_RETURN    BOOLEAN;
BEGIN
   /*BEGIN
     SELECT UR.ROLE_ID INTO V_ROLE_ID
     FROM SC_USER_ROLES UR
     WHERE  UR.USER_ID  = V_USER_ID
     AND  UR.PORT_CD   = V_PORT_CD
     AND   UR.UR_ACTIVE  = 1
     AND  UR.ROLE_ID   = 'EDIMSG_ALL'
    UNION
     SELECT  GR.ROLE_ID
     FROM   SC_GROUP_ROLES GR, SC_USER_GROUPS UG
     WHERE   UG.PORT_CD   = V_PORT_CD
     AND   UG.USER_ID   = V_USER_ID
     AND   GR.ROLE_ID   = 'EDIMSG_ALL'
     AND   GR.GROUP_ID   = UG.GROUP_ID
     AND   GR.GR_ACTIVE  = 1
    MINUS
     SELECT ROLE_ID  FROM SC_USER_EXCLUDED_ROLES UER
     WHERE  UER.USER_ID = V_USER_ID
     AND   UER.PORT_CD = V_PORT_CD
     AND   UER.ROLE_ID = 'EDIMSG_ALL'
     AND   UER.UER_ACTIVE =1
     ;

      EXCEPTION WHEN NO_DATA_FOUND THEN RETURN(FALSE);
   END;
     IF V_ROLE_ID = 'EDIMSG_ALL' THEN
      RETURN(TRUE);
     ELSE
      RETURN(FALSE);
     END IF; */


   V_RETURN := NIB.CHECK_EDI_ROLE_ID (V_PORT_CD, V_USER_ID);
   RETURN V_RETURN;
END;
```

### PU EDI_MSG_LOV (Procedure, 40 lines)

```plsql
/* Formatted on 14/05/2026 03:56:27 ? (QP5 v5.287) */
PROCEDURE EDI_MSG_LOV
IS
   pl_id     ParamList;
   pl_name   VARCHAR2 (100) := 'EDI_MSG_PARAM';
   RET       NUMBER;
BEGIN
   /* pl_id := Get_Parameter_List(pl_name);
    IF Id_Null(pl_id) THEN
      pl_id := Create_Parameter_List(pl_name);
      IF Id_Null(pl_id) THEN
        ret := Str.Dispalert('Error creating parameter list '||pl_name, 'SYSTEM_ERROR');
        RAISE Form_Trigger_Failure;
      END IF;

    Add_Parameter(pl_id, 'WINDOW_TITLE', TEXT_PARAMETER, 'EDI MESSAGES');
    Add_Parameter(pl_id, 'ROW_COUNT'  , TEXT_PARAMETER,12);
    Add_Parameter(pl_id, 'P_USER_NAME' , TEXT_PARAMETER, :PARAMETER.P_USER_NAME);
    Add_Parameter(pl_id, 'P_JOB_ID'   , TEXT_PARAMETER, :PARAMETER.P_JOB_ID);
    Add_Parameter(pl_id, 'P_CLASS_CD'  , TEXT_PARAMETER, :PARAMETER.P_CLASS_CD);
    Add_Parameter(pl_id, 'P_USER_TYPE' , TEXT_PARAMETER, :PARAMETER.P_USER_TYPE);
    Add_Parameter(pl_id, 'P_USER_ID'   , TEXT_PARAMETER, :PARAMETER.P_USER_ID);

    CALL_FORM('EDIMSG1220.fmx',
               no_hide,
               no_replace,
               no_query_only,
               pl_id);


    Destroy_Parameter_List(pl_id);
    ELSE
      ret := Str.DispAlert('Parameter list '||pl_name||' already EXISTS!','INFORMATION');
      RAISE Form_Trigger_Failure;
    END IF;*/



   NIB.EDI_MSG_LOV;
END;
```

### PU FOR_EDI_MSG (Procedure, 26 lines)

```plsql
/* Formatted on 14/05/2026 03:56:47 ? (QP5 v5.287) */
PROCEDURE FOR_EDI_MSG (MSG_COUNT OUT NUMBER)
IS
BEGIN
   /* ----OLD STATEMENT------
    select count(*) into msg_count
    from  MSG_HDRS mh
    where msg_for_user.is_msg_for_usr(mh.MSG_ID,:parameter.p_user_id,:parameter.p_class_cd,:parameter.p_user_type) = 1
    AND  MSG_DIRECTION = 1
    ;
    */
   /*
   SELECT COUNT(*)
   into   msg_count
   FROM  (
         SELECT
         FROM   MSG_HDRS mh
         WHERE  port_cd = :PARAMETER.P_CURR_PORT_CD -- NALSALEH CENTRALIZED PROJECT
         and (MSG_DIRECTION = 1 AND  MH.MSG_STAT =1)  OR  (MSG_DIRECTION = 1 AND  MH.MSG_STAT =2)
       ) MSG_DATA
   WHERE lib_usr.msg_for_user.is_msg_for_usr(MSG_DATA.MSG_ID,:parameter.p_user_id,:parameter.p_class_cd,:parameter.p_user_type) = 1;

 */

   NIB.FOR_EDI_MSG (MSG_COUNT);
END;
```

### PU RETURN_MSG (Procedure, 19 lines)

```plsql
/* Formatted on 14/05/2026 03:57:34 ? (QP5 v5.287) */
PROCEDURE RETURN_MSG
IS
   TIM   TIMER;
BEGIN
   /* if Id_Null(Find_Timer('RETURN')) then

 --Stop the Turn timer
       if not Id_Null(Find_Timer('TURN')) then
          Delete_Timer('TURN');
       end if;

       Tim := Create_Timer('RETURN', 10, REPEAT);
    end if;*/



   NIB.RETURN_MSG;
END;
```

### PU TURN_MSG (Procedure, 19 lines)

```plsql
/* Formatted on 14/05/2026 03:58:25 ? (QP5 v5.287) */
PROCEDURE TURN_MSG
IS
   TIM   TIMER;
BEGIN
   /*  if Id_Null(Find_Timer('TURN')) then

  --Stop the Return timer
        if not Id_Null(Find_Timer('RETURN')) then
           Delete_Timer('RETURN');
        end if;
        Synchronize;
     Set_View_Property('EDI_MSG', VISIBLE, PROPERTY_TRUE);
        tim := Create_Timer('TURN', 10, REPEAT);
     end if;
    */

   NIB.TURN_MSG;
END;
```

### PU WHEN_TIMER_EXPIRED_MSG (Procedure, 32 lines)

```plsql
PROCEDURE WHEN_TIMER_EXPIRED_MSG
IS
   TIMER_EXPIRED   VARCHAR2 (30);
   TIM             TIMER;
   DUMMY           VARCHAR2 (32);
BEGIN
   /*  Timer_Expired := Get_Application_Property(TIMER_NAME);
     if Timer_Expired = 'TURN' then
        dummy := To_Number(Get_View_Property('EDI_MSG', DISPLAY_X_POS));
        if dummy <= 5.5 then
           Set_View_Property('EDI_MSG', DISPLAY_X_POS, 5.5);
           Delete_Timer('TURN');
        else
           Set_View_Property('EDI_MSG', DISPLAY_X_POS,
              To_Number(Get_View_Property('EDI_MSG', DISPLAY_X_POS))-0.006);
        end if;

    :global.timer := 1;
     elsif Timer_Expired = 'RETURN' then
        if To_Number(Get_View_Property('EDI_MSG', DISPLAY_X_POS)) >= 8.5 then
  --Stop this timer
           Delete_Timer('RETURN');
           Set_View_Property('EDI_MSG', DISPLAY_X_POS, 8.5);
       else
           Set_View_Property('EDI_MSG', DISPLAY_X_POS,
              To_Number(Get_View_Property('EDI_MSG', DISPLAY_X_POS))+0.006);
        end if;
     :global.timer := 2;
    END IF;*/

   NIB.WHEN_TIMER_EXPIRED_MSG;
END;
```

### PU CG$WHEN_NEW_FORM_INSTANCE (Procedure, 23 lines)

```plsql
/* CG$WHEN_NEW_FORM_INSTANCE */
PROCEDURE CG$WHEN_NEW_FORM_INSTANCE IS
BEGIN
/* CGDV$POPULATE_DYNAMIC_LISTS */
/* Read the values for dynamic lists from the CG_REF_CODES table */
BEGIN
  CGDV$POPULATE_DYNAMIC_LISTS;
EXCEPTION
  WHEN OTHERS THEN
    CGTE$OTHER_EXCEPTIONS;
END;

/* CGBS$STARTUP */
/* Perform start-up processing for Block Synchronization */
BEGIN
  /* Set the defaults for the globals */
  :GLOBAL.CG$QUERY_MODE := 'A';
  /* Set the relations to the default query mode */
  CGBS$.SET_RELATIONS( :GLOBAL.CG$QUERY_MODE );
  /* Set the query mode items */
  CGBS$SET_QUERY_MODE( :GLOBAL.CG$QUERY_MODE );
END;
END;
```

### PU CGDV$POPULATE_DYNAMIC_LISTS (Procedure, 34 lines)

```plsql
/* CGDV$POPULATE_DYNAMIC_LISTS */
PROCEDURE CGDV$POPULATE_DYNAMIC_LISTS IS
/* Read each lists values from its record group and populate the list */
  temp NUMBER;  /* Return value of populate_group call */
  rg_id RECORDGROUP;  /* Return value of populate_group call */
BEGIN
  rg_id := create_group_from_query('CGDV$DLRG',
    'SELECT RV_MEANING, RV_LOW_VALUE '||
    'FROM   CG_REF_CODES '||
    'WHERE  RV_DOMAIN = ''ALLOWED EXPORT'' '||
    'ORDER BY  2');
  temp := populate_group(rg_id);
  populate_list('IMPORTERS.IMPR_EXPR_TYPE', rg_id);
  delete_group(rg_id);

  rg_id := create_group_from_query('CGDV$DLRG',
    'SELECT RV_MEANING, RV_LOW_VALUE '||
    'FROM   CG_REF_CODES '||
    'WHERE  RV_DOMAIN = ''IMPR_SUSPN_RSN_CD'' '||
    'ORDER BY  2');
  temp := populate_group(rg_id);
  populate_list('IMPR_SUSPN.SUSPN_RSN_CD', rg_id);
  delete_group(rg_id);

  rg_id := create_group_from_query('CGDV$DLRG',
    'SELECT RV_MEANING, RV_LOW_VALUE '||
    'FROM   CG_REF_CODES '||
    'WHERE  RV_DOMAIN = ''SUSPN SIDE CD'' '||
    'ORDER BY  2');
  temp := populate_group(rg_id);
  populate_list('IMPR_SUSPN.SUSPN_SIDE_CD', rg_id);
  delete_group(rg_id);

END;
```

### PU CGFK$QRY_IMPORTERS_IMP_SDP_FK (Procedure, 25 lines)

```plsql
/* CGFK$QRY_IMPORTERS_IMP_SDP_FK */
PROCEDURE CGFK$QRY_IMPORTERS_IMP_SDP_FK(
   P_SDP_PORT_STATUS IN OUT NUMBER        /* Value in Item :IMPORTERS.SDP_PORT_STATUS. */
  ,P_PORT_NAME       IN OUT VARCHAR2      /* Value in Item :IMPORTERS.PORT_NAME.       */
  ,P_PORT_CD         IN     NUMBER  ) IS  /* Value in Item :IMPORTERS.PORT_CD.         */
/* Query foreign key value/query lookup data. */
BEGIN
  DECLARE
    CURSOR C IS
      SELECT SDP.PORT_NAME
            ,SDP.PORT_STATUS
      FROM   SD_PORTS SDP
      WHERE  SDP.PORT_CD = P_PORT_CD;
  BEGIN
    OPEN C;
    FETCH C
    INTO    P_PORT_NAME
          , P_SDP_PORT_STATUS;
    IF C%NOTFOUND THEN
      CLOSE C;
      RAISE NO_DATA_FOUND;
    END IF;
    CLOSE C;
  END;
END;
```

### PU CGFK$CHK_IMPORTERS_IMP_SDP_FK (Procedure, 25 lines)

```plsql
/* CGFK$CHK_IMPORTERS_IMP_SDP_FK */
PROCEDURE CGFK$CHK_IMPORTERS_IMP_SDP_FK(
   P_SDP_PORT_STATUS IN OUT NUMBER        /* Value in Item :IMPORTERS.SDP_PORT_STATUS. */
  ,P_PORT_NAME       IN OUT VARCHAR2      /* Value in Item :IMPORTERS.PORT_NAME.       */
  ,P_PORT_CD         IN     NUMBER  ) IS  /* Value in Item :IMPORTERS.PORT_CD.         */
/* Validate foreign key value/query lookup data. */
BEGIN
  DECLARE
    CURSOR C IS
      SELECT SDP.PORT_NAME
            ,SDP.PORT_STATUS
      FROM   SD_PORTS SDP
      WHERE  SDP.PORT_CD = P_PORT_CD;
  BEGIN
    OPEN C;
    FETCH C
    INTO    P_PORT_NAME
          , P_SDP_PORT_STATUS;
    IF C%NOTFOUND THEN
      CLOSE C;
      RAISE NO_DATA_FOUND;
    END IF;
    CLOSE C;
  END;
END;
```

### PU CG$IMPR1120_GLOBALS (Package Spec, 4 lines)

```plsql
/* CG$IMPR1120_GLOBALS */
PACKAGE CG$IMPR1120_GLOBALS IS
IMPORTERS_WHERE VARCHAR2(2000) := 'first_time'; /* Block default where clause */
END;
```

### PU CGFK$QRY_IMPORTERS_IMP_ITIDT_F (Procedure, 36 lines)

```plsql
/* CGFK$QRY_IMPORTERS_IMP_ITIDT_F */
PROCEDURE CGFK$QRY_IMPORTERS_IMP_ITIDT_F(
   P_BUS_ID_TYPE_NAME IN OUT VARCHAR2      /* Value in Item :IMPORTERS.BUS_ID_TYPE_NAME. */
  ,P_IMPR_TYPE_NAME   IN OUT VARCHAR2      /* Value in Item :IMPORTERS.IMPR_TYPE_NAME.   */
  ,P_STATUS           IN OUT NUMBER        /* Value in Item :IMPORTERS.STATUS.           */
  ,P_IMPR_TYPE_CD     IN     NUMBER        /* Value in Item :IMPORTERS.IMPR_TYPE_CD.     */
  ,P_BUS_ID_TYPE_CD   IN     NUMBER  ) IS  /* Value in Item :IMPORTERS.BUS_ID_TYPE_CD.   */
/* Query foreign key value/query lookup data. */
BEGIN
  DECLARE
    CURSOR C IS
      SELECT ITIDT.STATUS
            ,IT.IMPR_TYPE_NAME
            ,BIT.BUS_ID_TYPE_NAME
      FROM   IMPR_TYPE_ID_TYPES ITIDT
            ,IMPR_TYPES IT
            ,BUS_ID_TYPES BIT
      WHERE  (ITIDT.BUS_ID_TYPE_CD = P_BUS_ID_TYPE_CD OR
             (ITIDT.BUS_ID_TYPE_CD IS NULL AND
              P_BUS_ID_TYPE_CD IS NULL ))
      AND    ITIDT.IMPR_TYPE_CD = P_IMPR_TYPE_CD
      AND    IT.IMPR_TYPE_CD = ITIDT.IMPR_TYPE_CD
      AND    BIT.BUS_ID_TYPE_CD = ITIDT.BUS_ID_TYPE_CD;
  BEGIN
    OPEN C;
    FETCH C
    INTO    P_STATUS
          , P_IMPR_TYPE_NAME
          , P_BUS_ID_TYPE_NAME;
    IF C%NOTFOUND THEN
      CLOSE C;
      RAISE NO_DATA_FOUND;
    END IF;
    CLOSE C;
  END;
END;
```

### PU CGFK$CHK_IMPORTERS_IMP_ITIDT_F (Procedure, 37 lines)

```plsql
/* CGFK$CHK_IMPORTERS_IMP_ITIDT_F */
PROCEDURE CGFK$CHK_IMPORTERS_IMP_ITIDT_F(
   P_BUS_ID_TYPE_NAME IN OUT VARCHAR2      /* Value in Item :IMPORTERS.BUS_ID_TYPE_NAME. */
  ,P_IMPR_TYPE_NAME   IN OUT VARCHAR2      /* Value in Item :IMPORTERS.IMPR_TYPE_NAME.   */
  ,P_STATUS           IN OUT NUMBER        /* Value in Item :IMPORTERS.STATUS.           */
  ,P_IMPR_TYPE_CD     IN     NUMBER        /* Value in Item :IMPORTERS.IMPR_TYPE_CD.     */
  ,P_BUS_ID_TYPE_CD   IN     NUMBER  ) IS  /* Value in Item :IMPORTERS.BUS_ID_TYPE_CD.   */
/* Validate foreign key value/query lookup data. */
BEGIN
  DECLARE
    CURSOR C IS
      SELECT ITIDT.STATUS
            ,IT.IMPR_TYPE_NAME
            ,BIT.BUS_ID_TYPE_NAME
      FROM   IMPR_TYPE_ID_TYPES ITIDT
            ,IMPR_TYPES IT
            ,BUS_ID_TYPES BIT
      WHERE  (ITIDT.BUS_ID_TYPE_CD = P_BUS_ID_TYPE_CD OR
             (ITIDT.BUS_ID_TYPE_CD IS NULL AND
              P_BUS_ID_TYPE_CD IS NULL ))
      AND    ITIDT.IMPR_TYPE_CD = P_IMPR_TYPE_CD
      AND    ITIDT.STATUS = 1
      AND    IT.IMPR_TYPE_CD = ITIDT.IMPR_TYPE_CD
      AND    BIT.BUS_ID_TYPE_CD = ITIDT.BUS_ID_TYPE_CD;
  BEGIN
    OPEN C;
    FETCH C
    INTO    P_STATUS
          , P_IMPR_TYPE_NAME
          , P_BUS_ID_TYPE_NAME;
    IF C%NOTFOUND THEN
      CLOSE C;
      RAISE NO_DATA_FOUND;
    END IF;
    CLOSE C;
  END;
END;
```

### PU CGFK$QRY_IMPORTERS_IMP_CTRY_FK (Procedure, 25 lines)

```plsql
/* CGFK$QRY_IMPORTERS_IMP_CTRY_FK */
PROCEDURE CGFK$QRY_IMPORTERS_IMP_CTRY_FK(
   P_CTRY_CTRY_STATUS IN OUT NUMBER        /* Value in Item :IMPORTERS.CTRY_CTRY_STATUS. */
  ,P_CRTY_ARBC_NAME   IN OUT VARCHAR2      /* Value in Item :IMPORTERS.CRTY_ARBC_NAME.   */
  ,P_CTRY_CD          IN     NUMBER  ) IS  /* Value in Item :IMPORTERS.CTRY_CD.          */
/* Query foreign key value/query lookup data. */
BEGIN
  DECLARE
    CURSOR C IS
      SELECT CTRY.CRTY_ARBC_NAME
            ,CTRY.CTRY_STATUS
      FROM   COUNTRIES CTRY
      WHERE  CTRY.CTRY_CD = P_CTRY_CD;
  BEGIN
    OPEN C;
    FETCH C
    INTO    P_CRTY_ARBC_NAME
          , P_CTRY_CTRY_STATUS;
    IF C%NOTFOUND THEN
      CLOSE C;
      RAISE NO_DATA_FOUND;
    END IF;
    CLOSE C;
  END;
END;
```

### PU CGFK$CHK_IMPORTERS_IMP_CTRY_FK (Procedure, 26 lines)

```plsql
/* CGFK$CHK_IMPORTERS_IMP_CTRY_FK */
PROCEDURE CGFK$CHK_IMPORTERS_IMP_CTRY_FK(
   P_CTRY_CTRY_STATUS IN OUT NUMBER        /* Value in Item :IMPORTERS.CTRY_CTRY_STATUS. */
  ,P_CRTY_ARBC_NAME   IN OUT VARCHAR2      /* Value in Item :IMPORTERS.CRTY_ARBC_NAME.   */
  ,P_CTRY_CD          IN     NUMBER  ) IS  /* Value in Item :IMPORTERS.CTRY_CD.          */
/* Validate foreign key value/query lookup data. */
BEGIN
  DECLARE
    CURSOR C IS
      SELECT CTRY.CRTY_ARBC_NAME
            ,CTRY.CTRY_STATUS
      FROM   COUNTRIES CTRY
      WHERE  CTRY.CTRY_CD = P_CTRY_CD
      AND    CTRY.CTRY_STATUS = 1;
  BEGIN
    OPEN C;
    FETCH C
    INTO    P_CRTY_ARBC_NAME
          , P_CTRY_CTRY_STATUS;
    IF C%NOTFOUND THEN
      CLOSE C;
      RAISE NO_DATA_FOUND;
    END IF;
    CLOSE C;
  END;
END;
```

### PU CGFK$QRY_IMPORTERS_IMP_BUS_ID_ (Procedure, 28 lines)

```plsql
/* CGFK$QRY_IMPORTERS_IMP_BUS_ID_ */
PROCEDURE CGFK$QRY_IMPORTERS_IMP_BUS_ID_(
   P_ID_CITY_NAME    IN OUT VARCHAR2      /* Value in Item :IMPORTERS.ID_CITY_NAME.    */
  ,P_CTRY_CD_OF_ID   IN     NUMBER        /* Value in Item :IMPORTERS.CTRY_CD_OF_ID.   */
  ,P_CITY_CODE_OF_ID IN     NUMBER  ) IS  /* Value in Item :IMPORTERS.CITY_CODE_OF_ID. */
/* Query foreign key value/query lookup data. */
BEGIN
  DECLARE
    CURSOR C IS
      SELECT L_CT.CITY_ARB_NAME
      FROM   CITIES L_CT
      WHERE  (L_CT.CITY_CD = P_CITY_CODE_OF_ID OR
             (L_CT.CITY_CD IS NULL AND
              P_CITY_CODE_OF_ID IS NULL ))
      AND    (L_CT.CTRY_CD = P_CTRY_CD_OF_ID OR
             (L_CT.CTRY_CD IS NULL AND
              P_CTRY_CD_OF_ID IS NULL ));
  BEGIN
    OPEN C;
    FETCH C
    INTO    P_ID_CITY_NAME;
    IF C%NOTFOUND THEN
      CLOSE C;
      RAISE NO_DATA_FOUND;
    END IF;
    CLOSE C;
  END;
END;
```

### PU CGFK$CHK_IMPORTERS_IMP_BUS_ID_ (Procedure, 28 lines)

```plsql
/* CGFK$CHK_IMPORTERS_IMP_BUS_ID_ */
PROCEDURE CGFK$CHK_IMPORTERS_IMP_BUS_ID_(
   P_ID_CITY_NAME    IN OUT VARCHAR2      /* Value in Item :IMPORTERS.ID_CITY_NAME.    */
  ,P_CTRY_CD_OF_ID   IN     NUMBER        /* Value in Item :IMPORTERS.CTRY_CD_OF_ID.   */
  ,P_CITY_CODE_OF_ID IN     NUMBER  ) IS  /* Value in Item :IMPORTERS.CITY_CODE_OF_ID. */
/* Validate foreign key value/query lookup data. */
BEGIN
  DECLARE
    CURSOR C IS
      SELECT L_CT.CITY_ARB_NAME
      FROM   CITIES L_CT
      WHERE  (L_CT.CITY_CD = P_CITY_CODE_OF_ID OR
             (L_CT.CITY_CD IS NULL AND
              P_CITY_CODE_OF_ID IS NULL ))
      AND    (L_CT.CTRY_CD = P_CTRY_CD_OF_ID OR
             (L_CT.CTRY_CD IS NULL AND
              P_CTRY_CD_OF_ID IS NULL ));
  BEGIN
    OPEN C;
    FETCH C
    INTO    P_ID_CITY_NAME;
    IF C%NOTFOUND THEN
      CLOSE C;
      RAISE NO_DATA_FOUND;
    END IF;
    CLOSE C;
  END;
END;
```

### PU CGFK$CHK_IMPR_SUSPN_IS_1_IMP_F (Procedure, 24 lines)

```plsql
/* CGFK$CHK_IMPR_SUSPN_IS_1_IMP_F */
PROCEDURE CGFK$CHK_IMPR_SUSPN_IS_1_IMP_F(
   P_IMPR_NBR IN NUMBER      /* Value in Item :IMPR_SUSPN.IMPR_NBR. */
  ,P_PORT_CD  IN NUMBER) IS  /* Value in Item :IMPR_SUSPN.PORT_CD.  */
/* Validate foreign key value/query lookup data. */
  CG$DUMMY VARCHAR2(1);
BEGIN
  DECLARE
    CURSOR C IS
      SELECT  '1'
      FROM   IMPORTERS
      WHERE  PORT_CD = P_PORT_CD
      AND    IMPR_NBR = P_IMPR_NBR;
  BEGIN
    OPEN C;
    FETCH C
    INTO    CG$DUMMY;
    IF C%NOTFOUND THEN
      CLOSE C;
      RAISE NO_DATA_FOUND;
    END IF;
    CLOSE C;
  END;
END;
```

### PU CGUV$CHK_IS_1_PK (Procedure, 27 lines)

```plsql
/* CGUV$CHK_IS_1_PK */
PROCEDURE CGUV$CHK_IS_1_PK(
   P_IMPR_NBR  IN NUMBER      /* Item value */
  ,P_PORT_CD   IN NUMBER      /* Item value */
  ,P_SUSPN_SEQ IN NUMBER) IS  /* Item value */
/* Check uniqueness against primary/unique constraint        */
/* Note : NO_DATA_FOUND exception handled by calling trigger */
  CG$DUMMY VARCHAR2(1);
BEGIN
    DECLARE
      CURSOR C IS
        SELECT  '1'
        FROM    IMPR_SUSPNS
        WHERE   SUSPN_SEQ = P_SUSPN_SEQ
        AND     PORT_CD = P_PORT_CD
        AND     IMPR_NBR = P_IMPR_NBR;
    BEGIN
      OPEN C;
      FETCH C
      INTO    CG$DUMMY;
      IF C%NOTFOUND THEN
        CLOSE C;
        RAISE NO_DATA_FOUND;
      END IF;
      CLOSE C;
    END;
END;
```

### PU CGTE$CHECK_CONSTRAINT_VIO (Function, 51 lines)

```plsql
/* CGTE$CHECK_CONSTRAINT_VIO */
FUNCTION CGTE$CHECK_CONSTRAINT_VIO(
   P_SERVER_ERR IN NUMBER        /* Server error message */
  ,P_SERVER_MSG IN VARCHAR2)     /* Server error number  */
RETURN BOOLEAN IS
/* Check and report Primary/Unique Key, Check Constraint and User */
/* Defined Constraint violations                                  */
  constraint_name VARCHAR2(61);  /* Violated constraint */
BEGIN
  /* Check if the error code is one we are interested in */
  IF ( NOT (P_SERVER_ERR IN  (1, 2290) OR
           (P_SERVER_ERR >= 20000 AND P_SERVER_ERR <= 20999) ) )
  THEN
    RETURN( FALSE );
  END IF;

  /* Deal with user defined errors */
  IF (P_SERVER_ERR >= 20000 AND P_SERVER_ERR <= 20999) THEN
    Des$Form_errors.PUSH(''||CGTE$STRIP_FIRST_ERROR(P_SERVER_MSG), 'E', 'OFG', 0);
    RETURN( TRUE );
  END IF;

  /* Deal with Primary/Unique Key and Check Constraint violations */
  constraint_name := CGTE$STRIP_CONSTRAINT(P_SERVER_MSG);
  IF (P_SERVER_ERR = 1) THEN
    IF (constraint_name = 'IMP_PK') THEN
      Des$Form_errors.PUSH('هذا السجل مدخل سابقاً - أعد ادخال البيانات', 'E', 'OFG', 0);
    ELSIF (constraint_name = 'IMP_BUSID_UK') THEN
      Des$Form_errors.PUSH('هذا السجل مدخل سابقاً - أعد ادخال البيانات', 'E', 'OFG', 0);
    ELSIF (constraint_name = 'ITIDT_PK') THEN
      Des$Form_errors.PUSH('هذا السجل مدخل سابقاً - أعد ادخال البيانات', 'E', 'OFG', 0);
    ELSIF (constraint_name = 'IT_PK') THEN
      Des$Form_errors.PUSH('هذا السجل مدخل سابقاً - أعد ادخال البيانات', 'E', 'OFG', 0);
    ELSIF (constraint_name = 'BIT_PK') THEN
      Des$Form_errors.PUSH('هذا السجل مدخل سابقاً - أعد ادخال البيانات', 'E', 'OFG', 0);
    ELSIF (constraint_name = 'SDP_PK') THEN
      Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(6, 'Row exists already with same <p1>', 'رمز الجمرك' ), 'E', 'OFG', 6);
    ELSIF (constraint_name = 'CTRY_PK') THEN
      Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(6, 'Row exists already with same <p1>', 'Ctry Cd' ), 'E', 'OFG', 6);
    ELSIF (constraint_name = 'CT_PK') THEN
      Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(6, 'Row exists already with same <p1>', 'City Cd,رمز الدولة' ), 'E', 'OFG', 6);
    ELSIF (constraint_name = 'IS_1_PK') THEN
      Des$Form_errors.PUSH('هذا السجل مدخل سابقاً - أعد ادخال البيانات', 'E', 'OFG', 0);
    ELSE
      Des$Form_errors.PUSH(P_SERVER_MSG, 'I', 'OFG', 0);
    END IF;
  ELSIF (P_SERVER_ERR = 2290) THEN
    Des$Form_errors.PUSH(P_SERVER_MSG, 'I', 'OFG', 0);
  END IF;
  RETURN( TRUE );
END;
```

### PU CGBS$TOGGLE (Procedure, 24 lines)

```plsql
/* CGBS$TOGGLE */
PROCEDURE CGBS$TOGGLE(
   P_QUERY_MODE IN OUT VARCHAR2) IS  /* Query Mode */
/* Toggle query mode between BSMON and BSMOFF, set all query mode items, */
/* display query mode message, set the relations and ensure that the     */
/* canvas is coordinated.                                                */
BEGIN
  /* Toggle the mode */
  IF (P_QUERY_MODE != 'A') THEN
    P_QUERY_MODE := 'A';
  ELSE
    P_QUERY_MODE := 'A';
  END IF;
  /* Set all the items */
  CGBS$SET_QUERY_MODE( P_QUERY_MODE );
  /* Display query mode messages */
  CGBS$MESSAGE_QUERY_MODE( P_QUERY_MODE );
  /* Set the relations */
  CGBS$.SET_RELATIONS( P_QUERY_MODE );
  /* If the query mode is AutoQuery, coordinate outstanding blocks */
  IF (P_QUERY_MODE = 'A') THEN
    CGBS$.COORD_VISIBLE_BLKS( :SYSTEM.CURSOR_BLOCK );
  END IF;
END;
```

### PU CGBS$SET_QUERY_MODE (Procedure, 7 lines)

```plsql
/* CGBS$SET_QUERY_MODE */
PROCEDURE CGBS$SET_QUERY_MODE(
   P_QUERY_MODE IN VARCHAR2) IS  /* Query Mode */
/* Set all query items to the current query mode */
BEGIN
  NULL;
END;
```

### PU CGBS$MESSAGE_QUERY_MODE (Procedure, 11 lines)

```plsql
/* CGBS$MESSAGE_QUERY_MODE */
PROCEDURE CGBS$MESSAGE_QUERY_MODE(
   P_QUERY_MODE IN VARCHAR2) IS  /* Query Mode */
/* Send a message to the status line indicating the current query mode */
BEGIN
  IF (P_QUERY_MODE = 'A') THEN
    Des$Form_errors.PUSH('Auto-query mode on', 'I', 'OFG', 0);
  ELSE
    Des$Form_errors.PUSH('Auto-query mode off', 'I', 'OFG', 0);
  END IF;
END;
```

### PU EXEC_FUNS (Procedure, 4 lines)

```plsql
PROCEDURE EXEC_FUNS(CD VARCHAR2) IS
BEGIN
NULL;
END;
```

### PU ADJ_FUNS (Procedure, 4 lines)

```plsql
PROCEDURE ADJ_FUNS IS
BEGIN
NULL;
END;
```

## 10. External Dependencies

### 10.1 Attached libraries

| Library | Location | Source |
|---|---|---|
| OFGTEL | OFGTEL | File |
| OFGMES | Ofgmes | File |
| OFGHPL | OFGHPL | File |
| CIC_AMSG | CIC_AMSG | File |
| SEC_LIB | SEC_LIB | File |
| CAPTION | caption | File |
| OFGBSL | OFGBSL | File |
| D2KWUTIL | d2kwutil | File |
| CUSTOMDLL | CUSTOMDLL | File |
| D2KWUTIL_PDF | D2kwutil_PDF | File |
| GETCOMP | getcomp | File |
| OFGTAB | OFGTAB | File |
| PICKLIST | picklist | File |
| POS | POS | File |
| SCDLL | SCDLL | File |
| VCDLL | VCDLL | File |
| CIC_LIB | CIC_LIB | File |

### 10.2 Package-qualified calls found in the code (library or database — classification in 10.3)

| Call | Count of callers | Callers |
|---|---|---|
| ACTIVITY.ADD_ACTIVITY | 3 | IMPR_SUSPN.ON-DELETE, IMPR_SUSPN.PRE-INSERT, IMPR_SUSPN.PRE-UPDATE |
| ADJ_PRN.ADJ_REPORT_PRINTER | 1 | PU EXECUTE_FUNCTION |
| CG$DUMMY | 2 | PU CGFK$CHK_IMPR_SUSPN_IS_1_IMP_F, PU CGUV$CHK_IS_1_PK |
| CG$IMPR1120_GLOBALS.IMPORTERS_WHERE | 1 | IMPORTERS.PRE-QUERY |
| CGBS$.CLEAR_MASTER_DETAIL | 1 | FORM.ON-CLEAR-DETAILS |
| CGBS$.COORD_VISIBLE_BLKS | 1 | PU CGBS$TOGGLE |
| CGBS$.DO_KEYQRY | 1 | FORM.KEY-CQUERY |
| CGBS$.NEW_BLOCK | 1 | FORM.WHEN-NEW-BLOCK-INSTANCE |
| CGBS$.QUERY_DETAILS | 1 | FORM.ON-POPULATE-DETAILS |
| CGBS$.SET_RELATIONS | 2 | PU CG$WHEN_NEW_FORM_INSTANCE, PU CGBS$TOGGLE |
| CGBS2$.DO_COMMIT_DIALOGUE | 1 | FORM.KEY-CLRREC |
| CGBS2$.IS_COMMIT_NEEDED | 1 | FORM.KEY-CLRREC |
| CGBS2$.IS_RECORD_DIRTY | 1 | FORM.KEY-CLRREC |
| CGBS2$.SET_COORD_STYLE | 1 | FORM.WHEN-NEW-FORM-INSTANCE |
| CGBS2$.SET_QRY_ON_ENTRY | 1 | FORM.WHEN-NEW-FORM-INSTANCE |
| CGHP$CALL_MS_HELP | 3 | FORM.KEY-HELP, IMPORTERS.KEY-HELP, IMPR_SUSPN.KEY-HELP |
| CGHP$PRE_FORM | 1 | FORM.PRE-FORM |
| CGTE$OTHER_EXCEPTIONS | 8 | FORM.KEY-CLRFRM, FORM.KEY-HELP, FORM.WHEN-NEW-FORM-INSTANCE, IMPORTERS.IMPR_TYPE_CD.WHEN-VALIDATE-ITEM, IMPORTERS.KEY-HELP, IMPORTERS.POST-QUERY, IMPR_SUSPN.KEY-HELP, PU CG$WHEN_NEW_FORM_INSTANCE |
| CGTE$POP_ERROR_STACK | 2 | IMPORTERS.ON-ERROR, IMPR_SUSPN.ON-ERROR |
| CGTE$STRIP_CONSTRAINT | 3 | IMPORTERS.ON-ERROR, IMPR_SUSPN.ON-ERROR, PU CGTE$CHECK_CONSTRAINT_VIO |
| CGTE$STRIP_FIRST_ERROR | 1 | PU CGTE$CHECK_CONSTRAINT_VIO |
| DES$FORM_ERRORS.MSGGETTEXT | 10 | FORM.KEY-CQUERY, FORM.KEY-HELP, FORM.KEY-NXTKEY, IMPORTERS.KEY-HELP, IMPORTERS.ON-ERROR, IMPORTERS.POST-QUERY, IMPORTERS.PRE-QUERY, IMPR_SUSPN.KEY-HELP … (+2) |
| DES$FORM_ERRORS.PUSH | 12 | FORM.KEY-CQUERY, FORM.KEY-HELP, FORM.KEY-NXTKEY, IMPORTERS.IMPR_TYPE_CD.WHEN-VALIDATE-ITEM, IMPORTERS.KEY-HELP, IMPORTERS.ON-ERROR, IMPORTERS.POST-QUERY, IMPORTERS.PRE-QUERY … (+4) |
| DES$FORM_ERRORS.RAISE_FAILURE | 6 | FORM.KEY-CQUERY, FORM.KEY-NXTKEY, IMPORTERS.ON-ERROR, IMPORTERS.POST-QUERY, IMPORTERS.PRE-QUERY, IMPR_SUSPN.ON-ERROR |
| GNRL.GET_CUSTOMS_SETTING | 1 | IMPR_SUSPN.POST-INSERT |
| HIJDATE.COMPARE_HIJ_DATES | 2 | IMPR_SUSPN.SUSPN_END_DT.WHEN-VALIDATE-ITEM, IMPR_SUSPN.SUSPN_STRT_DT.WHEN-VALIDATE-ITEM |
| HIJDATE.CUR_HIJ_DATE | 6 | IMPR_SUSPN.ON-DELETE, IMPR_SUSPN.SUSPN_STRT_DT.WHEN-NEW-ITEM-INSTANCE, IMPR_SUSPN.SUSPN_STRT_DT.WHEN-VALIDATE-ITEM, TOOLBAR.EXIT1.WHEN-BUTTON-PRESSED, TOOLBAR.RE_ENTER_QUERY.WHEN-BUTTON-PRESSED, TOOLBAR.SAVE.WHEN-BUTTON-PRESSED |
| HIJDATE.VALID_HIJ_DATE | 4 | IMPR_SUSPN.SUSPN_END_DT.WHEN-VALIDATE-ITEM, IMPR_SUSPN.SUSPN_RLSE_DT.WHEN-VALIDATE-ITEM, IMPR_SUSPN.SUSPN_STRT_DT.WHEN-VALIDATE-ITEM, TITLE.SYSTEM_DATE.WHEN-VALIDATE-ITEM |
| HIJDATE_DB.CUR_HIJ_DATE | 1 | IMPR_SUSPN.PRE-UPDATE |
| INTRFACE.DISP_CALENDAR | 3 | IMPR_SUSPN.SUSPN_END_DT.KEY-LISTVAL, IMPR_SUSPN.SUSPN_RLSE_DT.KEY-LISTVAL, IMPR_SUSPN.SUSPN_STRT_DT.KEY-LISTVAL |
| INTRFACE.DISP_DATE_CON | 3 | IMPR_SUSPN.SUSPN_END_DT.KEY-F4, IMPR_SUSPN.SUSPN_RLSE_DT.KEY-F4, IMPR_SUSPN.SUSPN_STRT_DT.KEY-F4 |
| KEY_CONTROL.FOUND_KEY | 1 | TOOLBAR.EXIT1.WHEN-BUTTON-PRESSED |
| LIB_APX_USR.APEX_NOTIFICATIONS.SEND_SMS_EMAIL_NOTIFY | 1 | IMPR_SUSPN.POST-INSERT |
| NIB.CHECK_EDI_MSG_LOV | 1 | PU CHECK_EDI_MSG_LOV |
| NIB.CHECK_EDI_MSG_TIMER | 1 | PU CHECK_EDI_MSG_TIMER |
| NIB.CHECK_EDI_ROLE_ID | 1 | PU CHECK_EDI_ROLE_ID |
| NIB.CHECK_TIMEOUT | 1 | PU CHECK_TIMEOUT |
| NIB.EDI_MSG_LOV | 1 | PU EDI_MSG_LOV |
| NIB.FOR_EDI_MSG | 1 | PU FOR_EDI_MSG |
| NIB.KEY_CLRBLK | 1 | FORM.KEY-CLRBLK |
| NIB.KEY_DELREC | 1 | FORM.KEY-DELREC |
| NIB.KEY_DOWN | 1 | FORM.KEY-DOWN |
| NIB.KEY_DUPREC | 1 | FORM.KEY-DUPREC |
| NIB.KEY_EDIT | 1 | FORM.KEY-EDIT |
| NIB.KEY_ENTQRY | 1 | FORM.KEY-ENTQRY |
| NIB.KEY_EXEQRY | 1 | FORM.KEY-EXEQRY |
| NIB.KEY_EXIT | 1 | FORM.KEY-EXIT |
| NIB.KEY_F5 | 1 | FORM.KEY-F5 |
| NIB.KEY_NXTREC | 1 | FORM.KEY-NXTREC |
| NIB.KEY_PRINT | 1 | FORM.KEY-PRINT |
| NIB.KEY_PRVREC | 1 | FORM.KEY-PRVREC |
| NIB.KEY_SCRDOWN | 1 | FORM.KEY-SCRDOWN |
| NIB.KEY_SCRUP | 1 | FORM.KEY-SCRUP |
| NIB.KEY_UP | 1 | FORM.KEY-UP |
| NIB.ON_ERROR | 1 | FORM.ON-ERROR |
| NIB.ON_MESSAGE | 1 | FORM.ON-MESSAGE |
| NIB.PRE_FORM | 1 | FORM.PRE-FORM |
| NIB.PRINT_REPORT | 1 | PU PRINT_REPORT |
| NIB.RETURN_MSG | 1 | PU RETURN_MSG |
| NIB.TERMINATE_FUN | 1 | PU TERMINATE_FUN |
| NIB.TOGGEL_WND | 1 | PU TOGGEL_WND |
| NIB.TURN_MSG | 1 | PU TURN_MSG |
| NIB.WHEN_MOUSE_DOWN | 1 | FORM.WHEN-MOUSE-DOWN |
| NIB.WHEN_NEW_FORM_INSTANCE | 1 | FORM.WHEN-NEW-FORM-INSTANCE |
| NIB.WHEN_TIMER_EXPIRED | 1 | FORM.WHEN-TIMER-EXPIRED |
| NIB.WHEN_TIMER_EXPIRED_MSG | 1 | PU WHEN_TIMER_EXPIRED_MSG |
| NIB.WHEN_WINDOW_ACTIVATED | 1 | FORM.WHEN-WINDOW-ACTIVATED |
| REP.RUN_PRODUCT | 1 | PU EXECUTE_FUNCTION |
| SMS_MESSAGE.SEND_SMS_MESSAGE | 1 | IMPR_SUSPN.POST-INSERT |
| STR.DISPALERT | 6 | IMPORTERS.CITY_CODE_OF_ID.KEY-LISTVAL, IMPORTERS.CTRY_CD.KEY-LISTVAL, IMPORTERS.IMPR_TYPE_CD.KEY-LISTVAL, IMPORTERS.PORT_CD.KEY-LISTVAL, PU EXECUTE_FUNCTION, TOOLBAR.EXIT.WHEN-BUTTON-PRESSED |
| STR.DISPARBMSG | 3 | IMPORTERS.IMPR_NBR.WHEN-VALIDATE-ITEM, IMPR_SUSPN.SUSPN_END_DT.WHEN-VALIDATE-ITEM, IMPR_SUSPN.SUSPN_STRT_DT.WHEN-VALIDATE-ITEM |
| STR.STRFORMAT | 1 | IMPORTERS.PRE-QUERY |
| TMPLT.ENB_DIS_FUN_BUT | 1 | TOOLBAR.EXIT1.WHEN-BUTTON-PRESSED |
| TMPLT.FUN_ITEMS | 1 | PU EXECUTE_FUNCTION |
| TMPLT.KEYB_UP_DOWN | 3 | FORM.KEY-F9, TOOLBAR.KEY-DOWN, TOOLBAR.KEY-UP |
| TMPLT.KEY_DELETE_RECORD | 1 | IMPR_SUSPN.KEY-DELREC |
| TMPLT.POPULATE_FUNCTIONS | 2 | FORM.KEY-F9, TOOLBAR.FUN_BUT.WHEN-MOUSE-UP |

### 10.3 Classification of package-qualified calls (library vs database)

> The library texts in `forms/COMMON/libraries/` were searched for every package the form calls.

| Package / prefix | Origin | Library file / source | Used for (active calls in IMPR1120) |
|---|---|---|---|
| `NIB.*` | Forms library | `CIC_LIB.pld` | form startup, ON-ERROR / ON-MESSAGE, timers, 16 KEY-* handlers, window handling (same as IMPR1110 §10.8) |
| `STR.*` | Forms library | `CIC_LIB.pld` (→ DB `STR_DB`, **MISSING SOURCE**) | `DispAlert` (6), `DispArbMsg` (3: messages 9-100, 9-110, 9-150), `StrFormat` (PRE-QUERY, Arabic name standardisation) |
| `INTRFACE.*` | Forms library | `CIC_LIB.pld` | `DISP_CALENDAR` (3, KEY-LISTVAL on the date items) and `DISP_DATE_CON` (3, KEY-F4): calendar / date-conversion forms called through CALL_FORM |
| `TMPLT.*` | Forms library | `CIC_LIB.pld` | `KEY_DELETE_RECORD` (IMPR_SUSPN.KEY-DELREC: confirm + `Delete_record` + COMMIT), `POPULATE_FUNCTIONS`, `KEYB_UP_DOWN`, `ENB_DIS_FUN_BUT`, `FUN_ITEMS` |
| `HIJDATE.*` | Forms library → DB | `CIC_LIB.pld` → `HIJDATE_DB` (`plsql/Shared/HIJDATE_DB.*`) | `CUR_HIJ_DATE` (6), `VALID_HIJ_DATE` (4), `COMPARE_HIJ_DATES` (2) |
| `HIJDATE_DB.*` | Database package | `plsql/Shared/HIJDATE_DB.*` | `CUR_HIJ_DATE` called directly in IMPR_SUSPN.PRE-UPDATE |
| `ACTIVITY.*` | Forms library → DB | `CIC_LIB.pld` → `ACTIVITY_DB` (`plsql/Shared/ACTIVITY_DB.*`) | `ADD_ACTIVITY(9, 3, 1 / 2 / 3, port!impr!seq)` on insert / update / delete of a suspension |
| `KEY_CONTROL.*` | Forms library | `CIC_LIB.pld` | `FOUND_KEY` (TOOLBAR.EXIT1) |
| `REP.*`, `ADJ_PRN.*` | Forms library | `CIC_LIB.pld` | `RUN_PRODUCT` / `ADJ_REPORT_PRINTER` in PU EXECUTE_FUNCTION (function menu) |
| `CGBS$.*`, `CGBS2$.*` | Designer block-synchronisation library | `OFGBSL.pld` | master-detail coordination (`SET_RELATIONS`, `QUERY_DETAILS`, `CLEAR_MASTER_DETAIL`, `NEW_BLOCK`, `DO_KEYQRY`), commit dialogue (`IS_RECORD_DIRTY`, `DO_COMMIT_DIALOGUE`) |
| `DES$FORM_ERRORS` | Designer message library | `CIC_AMSG.pld` | error stack / messages |
| `CGTE$*` | Designer table-error library | `OFGTEL`: **MISSING SOURCE** | constraint-violation text in the two block ON-ERROR triggers |
| `CGHP$*` | Designer help library | `OFGHPL.pld` | MS-Help (obsolete) |
| `GNRL` | Database package | **MISSING SOURCE** | `GET_CUSTOMS_SETTING(port, 'NE_INTEGRATION', 21)`: chooses the notification channel |
| `LIB_APX_USR.APEX_NOTIFICATIONS` | Database package (owner `LIB_APX_USR`) | **MISSING SOURCE** | `SEND_SMS_EMAIL_NOTIFY(..., EVENT_CODE => 'IMPR_010', ...)` (CR-8414) |
| `SMS_MESSAGE` | Database package | **MISSING SOURCE** | `SEND_SMS_MESSAGE(9, 3, 1, port, NULL, mobile, body, key)`: older SMS path |
| `CG$IMPR1120_GLOBALS` | Form program unit (package spec) | in the XML (§9) | `IMPORTERS_WHERE` variable (Designer dynamic WHERE) |

### 10.4 Called forms

| Caller | Built-in | Arguments (verbatim) | ADD_PARAMETER calls in the same unit (name, type, value) |
|---|---|---|---|
| IMPORTERS.PORT_CD.KEY-LISTVAL | CALL_FORM | `'LOV_SD_PORTS.fmx', no_hide, no_replace, no_query_only, pl_id` | PORT_TYPE TEXT_PARAMETER = :PARAMETER.P_PORT_TYPE; WINDOW_WIDTH TEXT_PARAMETER = 5.5; WINDOW_TITLE TEXT_PARAMETER = 'قائمة المنافذ الجمركية السعوديه'; STATUS TEXT_PARAMETER = 1 |
| IMPORTERS.IMPR_TYPE_CD.KEY-LISTVAL | CALL_FORM | `'LOV_Impr_Type.fmx', no_hide, no_replace, no_query_only, pl_id` | STATUS TEXT_PARAMETER = 1; WINDOW_TITLE TEXT_PARAMETER = 'قائمة أنواع الأنشطة التجاريه' |
| IMPORTERS.CTRY_CD.KEY-LISTVAL | CALL_FORM | `'LOV_COUNTRIES.fmx', no_hide, no_replace, no_query_only, pl_id` | WINDOW_TITLE TEXT_PARAMETER = 'قائمة رموز الدول'; WINDOW_WIDTH TEXT_PARAMETER = 4.5; STATUS TEXT_PARAMETER = 1 |
| IMPORTERS.CITY_CODE_OF_ID.KEY-LISTVAL | CALL_FORM | `'LOV_CITIES.fmx ', no_hide, no_replace, no_query_only, pl_id` | WINDOW_TITLE  TEXT_PARAMETER = 'قائمة المدن السعوديه'; WINDOW_WIDTH  TEXT_PARAMETER = 5; WINDOW_X_POS TEXT_PARAMETER = 1.5; WINDOW_Y_POS TEXT_PARAMETER = .8; CTRY_CD TEXT_PARAMETER = 100; STATUS TEXT_PARAMETER = 1 |
| PU EXECUTE_FUNCTION | CALL_FORM | `V_CALLED_FORM, no_hide, no_replace, no_query_only, pl_id` | P_USER_ID TEXT_PARAMETER = :PARAMETER.P_USER_ID; P_USER_NAME TEXT_PARAMETER = :PARAMETER.P_USER_NAME; P_WS_ID TEXT_PARAMETER = :PARAMETER.P_WS_ID; P_CURR_PORT_CD TEXT_PARAMETER = :PARAMETER.P_CURR_PORT_CD; P_PORT_TYPE TEXT_PARAMETER = :PARAMETER.P_PORT_TYPE; P_GROUP_CD TEXT_PARAMETER = :PARAMETER.P_GROUP_CD; P_USER_TYPE TEXT_PARAMETER = :PARAMETER.P_USER_TYPE; P_JOB_ID TEXT_PARAMETER = :PARAMETER.P_JOB_ID; P_CLASS_CD TEXT_PARAMETER = :PARAMETER.P_CLASS_CD; P_MODULE_ID TEXT_PARAMETER = TMPLT.FUN_ITEMS(ROW_COUNT).MID; P_MODULE_NAME TEXT_PARAMETER = V_MOD_NAME; P_BRKR_PORT_CD TEXT_PARAMETER = :PARAMETER.P_BRKR_PORT_CD; P_SHPG_AGNT_NBR TEXT_PARAMETER = :PARAMETER.P_SHPG_AGNT_NBR; P_BRKR_NBR TEXT_PARAMETER = :PARAMETER.P_BRKR_NBR; P_LIC_TYPE TEXT_PARAMETER = :PARAMETER.P_LIC_TYPE; P_BANK_CD TEXT_PARAMETER = :PARAMETER.P_BANK_CD; P_BANK_BRNCH_CD TEXT_PARAMETER = :PARAMETER.P_BANK_BRNCH_CD; P_SYS_ID TEXT_PARAMETER = :GLOBAL.SYSTEM_OBJ; P_REP_NO TEXT_PARAMETER = V_SEQ_NO; P_REPORT_NO TEXT_PARAMETER = :GLOBAL.SYSTEM_OBJ \|\|'-'\|\|V_SEQ_NO; DESTYPE TEXT_PARAMETER = 'PRINTER'; PARAMFORM TEXT_PARAMETER = 'NO'; ORACLE_SHUTDOWN TEXT_PARAMETER = 'YES'; MAXIMIZE TEXT_PARAMETER = 'YES' |
| PU EXECUTE_FUNCTION | CALL_FORM | `V_CALLED_FORM, no_hide, no_replace, no_query_only, pl_id` | P_USER_ID TEXT_PARAMETER = :PARAMETER.P_USER_ID; P_USER_NAME TEXT_PARAMETER = :PARAMETER.P_USER_NAME; P_WS_ID TEXT_PARAMETER = :PARAMETER.P_WS_ID; P_CURR_PORT_CD TEXT_PARAMETER = :PARAMETER.P_CURR_PORT_CD; P_PORT_TYPE TEXT_PARAMETER = :PARAMETER.P_PORT_TYPE; P_GROUP_CD TEXT_PARAMETER = :PARAMETER.P_GROUP_CD; P_USER_TYPE TEXT_PARAMETER = :PARAMETER.P_USER_TYPE; P_JOB_ID TEXT_PARAMETER = :PARAMETER.P_JOB_ID; P_CLASS_CD TEXT_PARAMETER = :PARAMETER.P_CLASS_CD; P_MODULE_ID TEXT_PARAMETER = TMPLT.FUN_ITEMS(ROW_COUNT).MID; P_MODULE_NAME TEXT_PARAMETER = V_MOD_NAME; P_BRKR_PORT_CD TEXT_PARAMETER = :PARAMETER.P_BRKR_PORT_CD; P_SHPG_AGNT_NBR TEXT_PARAMETER = :PARAMETER.P_SHPG_AGNT_NBR; P_BRKR_NBR TEXT_PARAMETER = :PARAMETER.P_BRKR_NBR; P_LIC_TYPE TEXT_PARAMETER = :PARAMETER.P_LIC_TYPE; P_BANK_CD TEXT_PARAMETER = :PARAMETER.P_BANK_CD; P_BANK_BRNCH_CD TEXT_PARAMETER = :PARAMETER.P_BANK_BRNCH_CD; P_SYS_ID TEXT_PARAMETER = :GLOBAL.SYSTEM_OBJ; P_REP_NO TEXT_PARAMETER = V_SEQ_NO; P_REPORT_NO TEXT_PARAMETER = :GLOBAL.SYSTEM_OBJ \|\|'-'\|\|V_SEQ_NO; DESTYPE TEXT_PARAMETER = 'PRINTER'; PARAMFORM TEXT_PARAMETER = 'NO'; ORACLE_SHUTDOWN TEXT_PARAMETER = 'YES'; MAXIMIZE TEXT_PARAMETER = 'YES' |

### 10.5 Database tables / views referenced in SQL (12)

Extracted from active (non-comment) code. Record-group queries are listed in section 7.

| Object | DML used | Referenced in |
|---|---|---|
| BUS_ID_TYPES | SELECT | PU CGFK$CHK_IMPORTERS_IMP_ITIDT_F, PU CGFK$QRY_IMPORTERS_IMP_ITIDT_F |
| CG_REF_CODES | SELECT | IMPR_SUSPN.SUSPN_RSN_CD.WHEN-VALIDATE-ITEM |
| CITIES | SELECT | PU CGFK$CHK_IMPORTERS_IMP_BUS_ID_, PU CGFK$QRY_IMPORTERS_IMP_BUS_ID_ |
| COUNTRIES | SELECT | PU CGFK$CHK_IMPORTERS_IMP_CTRY_FK, PU CGFK$QRY_IMPORTERS_IMP_CTRY_FK |
| IMPORTERS | SELECT | IMPORTERS.IMPR_NBR.WHEN-VALIDATE-ITEM, PU CGFK$CHK_IMPR_SUSPN_IS_1_IMP_F |
| IMPORTER_BASIC_DATA | SELECT | IMPR_SUSPN.POST-INSERT |
| IMPR_SUSPNS | SELECT, UPDATE | IMPR_SUSPN.ON-DELETE, IMPR_SUSPN.PRE-INSERT, IMPR_SUSPN.WHEN-NEW-RECORD-INSTANCE, PU CGUV$CHK_IS_1_PK |
| IMPR_TYPES | SELECT | PU CGFK$CHK_IMPORTERS_IMP_ITIDT_F, PU CGFK$QRY_IMPORTERS_IMP_ITIDT_F |
| IMPR_TYPE_ID_TYPES | SELECT | PU CGFK$CHK_IMPORTERS_IMP_ITIDT_F, PU CGFK$QRY_IMPORTERS_IMP_ITIDT_F |
| SC_PORT_SETTING | SELECT | PU EXECUTE_FUNCTION |
| SC_SYSTEM_OBJECTS | SELECT | PU EXECUTE_FUNCTION |
| SD_PORTS | SELECT | IMPORTERS.WHEN-CREATE-RECORD, PU CGFK$CHK_IMPORTERS_IMP_SDP_FK, PU CGFK$QRY_IMPORTERS_IMP_SDP_FK |

### 10.6 Reports, HOST, notifications, file and OS access

| Feature | Location | Active? | Notes |
|---|---|---|---|
| SMS / e-mail notification | IMPR_SUSPN.POST-INSERT | yes | `GNRL.GET_CUSTOMS_SETTING(port, 'NE_INTEGRATION', 21) = 1` → `LIB_APX_USR.APEX_NOTIFICATIONS.SEND_SMS_EMAIL_NOTIFY` (event `IMPR_010`, variables `P_PORT_NAME`, `P_BUS_ID`, `P_SUSPN_STRT_DT`, `P_SUSPN_END_DT`, `P_SUSPN_RSN_TEXT`, `ORG_HOTLINE=19993`, `ORG_NAME=https://zatca.gov.sa`), otherwise `SMS_MESSAGE.SEND_SMS_MESSAGE` with an Arabic text built in the trigger. The mobile number comes from `IMPORTER_BASIC_DATA.MOBILE_NO` by `HQ_IMPR_NBR`. It is followed by `STANDARD.COMMIT`, and `WHEN OTHERS THEN NULL` hides every error |
| `REP.RUN_PRODUCT` (BATCH / RUNTIME) ×2 | PU EXECUTE_FUNCTION | yes, only if the module has report functions in `SC_SYSTEM_OBJECTS` | same generic code as IMPR1110; `ADJ_FUNS` / `EXEC_FUNS` are empty in this form |
| Calendar / date-conversion forms | `INTRFACE.DISP_CALENDAR` / `DISP_DATE_CON` (CALL_FORM inside `CIC_LIB.pld`) | yes | replaced by the APEX date item (§15 #8) |
| `TEXT_IO` | PU CHECK_TIMEOUT | no: the PU is not called; the active path is `NIB.CHECK_TIMEOUT` | session timeout |
| `CREATE_TIMER` / WHEN-TIMER-EXPIRED | `NIB.WHEN_NEW_FORM_INSTANCE` / `NIB.WHEN_TIMER_EXPIRED` | yes, via the library | EDI ticker + session timeout |
| Windows API / DLL | PUs TOGGEL_WND, CHECK_TIMEOUT (via NIB) | indirect | client side only |
| `FORMS_DDL` | PRE-FORM (`ALTER SESSION SET NLS_DATE_FORMAT`) | yes | |
| DB COMMIT | IMPR_SUSPN.POST-INSERT (`STANDARD.COMMIT`), `TMPLT.KEY_DELETE_RECORD` (COMMIT), TOOLBAR.SAVE (COMMIT) | yes | |
| HOST, WEB.SHOW_DOCUMENT, OLE2, Java bean / PJC, CLIENT_*, EXEC_SQL, ON-LOCK | – | **not found** | |
| Sequences | none: `SUSPN_SEQ` = `MAX(SUSPN_SEQ) + 1` from `IMPR_SUSPNS` (whole table) in PRE-INSERT | yes | |
| DB links | – | not found | |

### 10.7 Object library / subclassed objects

- Object library: **`CIC_OLB.olb`**, available as `forms/COMMON/olb/CIC_OLB_OLB.xml`.
- 161 subclassed objects: 51 visual attributes, 37 items, 24 triggers, 20 module parameters, 9 alerts, 6 blocks (the 4 frame blocks plus `CGSO$BLOCK` / `CGSO$BLOCK_MR` for IMPORTERS / IMPR_SUSPN), 5 canvases, 5 LOVs, 2 graphics, 1 window, 1 report object.
- The frame blocks are replaced by the f345 page template, page 0 toolbar and FUNCS region (same as IMPR1110 §10.7).

### 10.8 What the library calls used here do, and their APEX equivalent (f345 standard)

| Library call | What it does | APEX 21.2 / f345 equivalent |
|---|---|---|
| `CGBS$.SET_RELATIONS` / `QUERY_DETAILS` / `CLEAR_MASTER_DETAIL` (`OFGBSL.pld`) | Designer master-detail coordination over the form's relations (here only `CGFK$IS_1_IMP_FK`) | IG `IMPR_SUSPN` with master key `PORT_CD` + `IMPR_NBR` taken from the Form region `IMPORTERS` (native master-detail) |
| `TMPLT.KEY_DELETE_RECORD` | if toolbar `REMOVE` is visible + enabled and the record is not new: WARNING confirm → `Delete_record` + COMMIT | IG row delete (native confirm). The DELETE is replaced by the soft-delete procedure of `ON-DELETE` (custom DML for the delete row status). No COMMIT |
| `STR.DispArbMsg(9, n, type)` | message n of system 9 from the message table, shown in an alert | `IMPR1120` function returning the text (`STR_DB` / message table) + `CHECK_ERROR` |
| `STR.StrFormat(name, TRUE)` | standardised Arabic name for search (via `STR_DB`) | the same DB function in the search page SQL |
| `HIJDATE.VALID_HIJ_DATE` / `COMPARE_HIJ_DATES` / `CUR_HIJ_DATE` | call `HIJDATE_DB` | call `HIJDATE_DB` from the package validations |
| `INTRFACE.DISP_CALENDAR` / `DISP_DATE_CON` | CALL_FORM to a Hijri calendar / date-conversion form | APEX date item with the Forms format mask; Hijri picker per the IMPR1110 decision (§15 #8) |
| `ACTIVITY.ADD_ACTIVITY` | `ACTIVITY_DB.ADD_ACTIVITY` with port, user, workstation | call `ACTIVITY_DB` inside the DML procedures with `P_CURR_PORT_CD`, `SSO_APP_USER`, `P_GLOBAL_V_WS_ID` |
| `NIB.*`, `TMPLT` function menu, `KEY_CONTROL`, `REP` | as IMPR1110 §10.8 | as IMPR1110 §10.8 (f345 shell, Page Functions list) |

## 11. Alerts

| Alert | Style | Title | Message | Buttons | Where used (by literal name) | Source |
|---|---|---|---|---|---|---|
| CG$ASK_COMMIT | Caution | MISSING SOURCE | Do you wish to commit the changes you have made? | Yes/No/Cancel | not referenced by literal name | None:None |
| USR_CONFIRM_B | Caution | تأكـــــــيد | (set at runtime) | نعم/لا | not referenced by literal name | CIC_OLB.olb:USR_CONFIRM_B (resolved from the OLB XML) |
| USR_CONFIRM | Caution | تأكـــــــيد | (set at runtime) | نعم/لا | not referenced by literal name | CIC_OLB.olb:USR_CONFIRM (resolved from the OLB XML) |
| USR_WARNING_C | Caution | رسالة تحذيرية | (set at runtime) | موافق/إلغاء | not referenced by literal name | CIC_OLB.olb:USR_WARNING_C (resolved from the OLB XML) |
| USR_WARNING_B | Caution | رسالة تحذيرية | (set at runtime) | موافق/إلغاء | not referenced by literal name | CIC_OLB.olb:USR_WARNING_B (resolved from the OLB XML) |
| CFG_WARNING_A | Caution | رسالة تحذيريه | (set at runtime) | موافق | not referenced by literal name | CIC_OLB.olb:CFG_WARNING_A (resolved from the OLB XML) |
| CFG_INFORMATION | Note | رسالة إرشاديه | (set at runtime) | موافق | FORM.ON-MESSAGE | CIC_OLB.olb:CFG_INFORMATION (resolved from the OLB XML) |
| CFG_ERROR | Stop | رسالة خطأ | (set at runtime) | موافق | FORM.ON-ERROR | CIC_OLB.olb:CFG_ERROR (resolved from the OLB XML) |
| CFG_SYSTEM_ERROR | Stop | رسالة خطــأ بالنظام | (set at runtime) | موافق | not referenced by literal name | CIC_OLB.olb:CFG_SYSTEM_ERROR (resolved from the OLB XML) |
| CFG_ASK_COMMIT | Caution | – | هل تريد حفظ التغييرات ؟ | نعم/لا/إلغاء | not referenced by literal name | CIC_OLB.olb:CFG_ASK_COMMIT (resolved from the OLB XML) |

> **Alert notes**
> - 9 alerts come from `CIC_OLB.olb` (style, title and buttons resolved from `CIC_OLB_OLB.xml`); `STR.DispAlert` / `STR.DispArbMsg` set the text at runtime. `CG$ASK_COMMIT` is the form's own Designer alert; it has no title in the XML and is not referenced.
> - Messages used: `STR.DispArbMsg(9, 100, 'ERROR')` (start date before today), `(9, 110, 'ERROR')` (end date before start date), `(9, 150, 'INFORMATION')` (importer not found in this port). Their text is in the message table read by `STR_DB`: **MISSING SOURCE** (§15 #11). Delete confirmation: WARNING alert in `TMPLT.KEY_DELETE_RECORD` (`CIC_LIB.pld`; the Arabic literal is stored in Windows-1256 and shows as mojibake in the .pld text).
> - APEX mapping (f345 standard §9): ERROR → `CHECK_ERROR` / `FORMS_APX.FORM_TRIGGER_FAILURE`; INFORMATION → page message; WARNING (delete) → the native confirm of the page 0 / IG delete.

## 12. Parameters & Globals

| Parameter | Data type | Default | Subclassed from | Where used |
|---|---|---|---|---|
| P_SHPG_AGNT_NBR | default (CHAR) / OLB | default/OLB | P_SHPG_AGNT_NBR | PU EXECUTE_FUNCTION, PU PRINT_REPORT |
| P_CTRL_LAST_EXEC_CD | default (CHAR) / OLB | default/OLB | P_CTRL_LAST_EXEC_CD | PU EXECUTE_FUNCTION |
| P_BANK_CD | default (CHAR) / OLB | default/OLB | P_BANK_CD | PU EXECUTE_FUNCTION, PU PRINT_REPORT |
| P_BANK_BRNCH_CD | default (CHAR) / OLB | default/OLB | P_BANK_BRNCH_CD | PU EXECUTE_FUNCTION, PU PRINT_REPORT |
| P_BRKR_PORT_CD | default (CHAR) / OLB | default/OLB | P_BRKR_PORT_CD | PU EXECUTE_FUNCTION, PU PRINT_REPORT |
| P_LIC_TYPE | default (CHAR) / OLB | default/OLB | P_LIC_TYPE | PU EXECUTE_FUNCTION, PU PRINT_REPORT |
| P_BRKR_NBR | default (CHAR) / OLB | default/OLB | P_BRKR_NBR | PU EXECUTE_FUNCTION, PU PRINT_REPORT |
| P_CLASS_CD | default (CHAR) / OLB | default/OLB | P_CLASS_CD | PU EDI_MSG_LOV, PU EXECUTE_FUNCTION, PU FOR_EDI_MSG, PU PRINT_REPORT |
| P_JOB_ID | default (CHAR) / OLB | default/OLB | P_JOB_ID | PU EDI_MSG_LOV, PU EXECUTE_FUNCTION, PU PRINT_REPORT |
| P_CURRENT_ITEM | default (CHAR) / OLB | default/OLB | P_CURRENT_ITEM | FORM.WHEN-TIMER-EXPIRED |
| P_GROUP_CD | default (CHAR) / OLB | default/OLB | P_GROUP_CD | PU EXECUTE_FUNCTION, PU PRINT_REPORT |
| P_USER_TYPE | default (CHAR) / OLB | default/OLB | P_USER_TYPE | PU EDI_MSG_LOV, PU EXECUTE_FUNCTION, PU FOR_EDI_MSG, PU PRINT_REPORT |
| P_PORT_TYPE | default (CHAR) / OLB | default/OLB | P_PORT_TYPE | IMPORTERS.PORT_CD.KEY-LISTVAL, PU EXECUTE_FUNCTION, PU PRINT_REPORT |
| P_CURR_PORT_CD | default (CHAR) / OLB | default/OLB | P_CURR_PORT_CD | FORM.WHEN-NEW-FORM-INSTANCE, IMPORTERS.PRE-QUERY, IMPORTERS.WHEN-CREATE-RECORD, IMPR_SUSPN.POST-INSERT, IMPR_SUSPN.SUSPN_RSN_CD.WHEN-NEW-ITEM-INSTANCE, IMPR_SUSPN.SUSPN_SIDE_CD.WHEN-LIST-CHANGED, IMPR_SUSPN.SUSPN_SIDE_CD.WHEN-NEW-ITEM-INSTANCE, IMPR_SUSPN.WHEN-NEW-RECORD-INSTANCE, PU CHECK_EDI_MSG_LOV, PU CHECK_EDI_MSG_TIMER … (+4) |
| P_MODULE_ID | default (CHAR) / OLB | default/OLB | P_MODULE_ID | FORM.WHEN-NEW-FORM-INSTANCE |
| P_MODULE_NAME | default (CHAR) / OLB | default/OLB | P_MODULE_NAME | FORM.KEY-DUPREC, FORM.KEY-EDIT, FORM.KEY-F5, FORM.WHEN-NEW-FORM-INSTANCE, FORM.WHEN-WINDOW-ACTIVATED, TOOLBAR.EXIT1.WHEN-BUTTON-PRESSED, TOOLBAR.RE_ENTER_QUERY.WHEN-BUTTON-PRESSED, TOOLBAR.SAVE.WHEN-BUTTON-PRESSED |
| P_APPLICATION_NAME | default (CHAR) / OLB | default/OLB | P_APPLICATION_NAME | – |
| P_USER_ID | default (CHAR) / OLB | default/OLB | P_USER_ID | FORM.WHEN-NEW-FORM-INSTANCE, PU EDI_MSG_LOV, PU EXECUTE_FUNCTION, PU FOR_EDI_MSG, PU PRINT_REPORT |
| P_WS_ID | default (CHAR) / OLB | default/OLB | P_WS_ID | PU EXECUTE_FUNCTION, PU PRINT_REPORT |
| P_USER_NAME | default (CHAR) / OLB | default/OLB | P_USER_NAME | FORM.KEY-DUPREC, FORM.KEY-EDIT, FORM.KEY-F5, FORM.WHEN-WINDOW-ACTIVATED, PU EDI_MSG_LOV, PU EXECUTE_FUNCTION, PU PRINT_REPORT, TOOLBAR.EXIT1.WHEN-BUTTON-PRESSED, TOOLBAR.RE_ENTER_QUERY.WHEN-BUTTON-PRESSED, TOOLBAR.SAVE.WHEN-BUTTON-PRESSED |
| CG$STARTUP_MODE | default (CHAR) / OLB | NORMAL | – | – |
| CURRENT_SIDE | default (CHAR) / OLB | – | – | FORM.WHEN-NEW-FORM-INSTANCE, IMPR_SUSPN.SUSPN_RSN_CD.WHEN-NEW-ITEM-INSTANCE, IMPR_SUSPN.SUSPN_RSN_CD.WHEN-VALIDATE-ITEM, IMPR_SUSPN.SUSPN_SIDE_CD.WHEN-LIST-CHANGED, IMPR_SUSPN.SUSPN_SIDE_CD.WHEN-NEW-ITEM-INSTANCE, IMPR_SUSPN.WHEN-NEW-RECORD-INSTANCE |

### 12.1 :GLOBAL variables (17)

| Global | Read in | Written in |
|---|---|---|
| CG$HP_HFILE | FORM.KEY-HELP, IMPORTERS.KEY-HELP, IMPR_SUSPN.KEY-HELP | FORM.KEY-HELP, IMPORTERS.KEY-HELP, IMPR_SUSPN.KEY-HELP |
| CG$HP_HPATH | FORM.KEY-HELP, IMPORTERS.KEY-HELP, IMPR_SUSPN.KEY-HELP | FORM.PRE-FORM |
| CG$QUERY_MODE | FORM.KEY-MENU, FORM.ON-POPULATE-DETAILS, FORM.WHEN-NEW-BLOCK-INSTANCE, PU CG$WHEN_NEW_FORM_INSTANCE | PU CG$WHEN_NEW_FORM_INSTANCE |
| CITY_ARB_NAME | IMPORTERS.CITY_CODE_OF_ID.KEY-LISTVAL | – |
| CITY_CD | IMPORTERS.CITY_CODE_OF_ID.KEY-LISTVAL | – |
| CRTY_ARBC_NAME | IMPORTERS.CTRY_CD.KEY-LISTVAL | – |
| CTRY_CD | IMPORTERS.CITY_CODE_OF_ID.KEY-LISTVAL, IMPORTERS.CTRY_CD.KEY-LISTVAL | – |
| CURRENT_DT | – | FORM.WHEN-NEW-FORM-INSTANCE |
| CURRENT_VER | – | FORM.WHEN-NEW-FORM-INSTANCE |
| EXEC_QUERY_NOW | IMPORTERS.IMPR_TYPE_CD.WHEN-NEW-ITEM-INSTANCE, IMPORTERS.PRE-QUERY | FORM.WHEN-NEW-FORM-INSTANCE, IMPORTERS.IMPR_NBR.WHEN-VALIDATE-ITEM, IMPORTERS.PRE-QUERY |
| EXIT | TOOLBAR.EXIT.WHEN-BUTTON-PRESSED | – |
| IMPR_NBR | IMPORTERS.PRE-QUERY | FORM.WHEN-NEW-FORM-INSTANCE, IMPORTERS.IMPR_NBR.WHEN-VALIDATE-ITEM, IMPORTERS.PRE-QUERY |
| IMPR_TYPE_CD | IMPORTERS.IMPR_TYPE_CD.KEY-LISTVAL | – |
| IMPR_TYPE_NAME | IMPORTERS.IMPR_TYPE_CD.KEY-LISTVAL | – |
| PORT_CD | IMPORTERS.PORT_CD.KEY-LISTVAL, IMPORTERS.PRE-QUERY | FORM.WHEN-NEW-FORM-INSTANCE, IMPORTERS.IMPR_NBR.WHEN-VALIDATE-ITEM, IMPORTERS.PRE-QUERY |
| PORT_NAME | IMPORTERS.PORT_CD.KEY-LISTVAL | – |
| SYSTEM_OBJ | PU EXECUTE_FUNCTION | PU EXECUTE_FUNCTION (DEFAULT_VALUE) |

### 12.2 :SYSTEM variables (13)

| Variable | Used in |
|---|---|
| BLOCK_STATUS | FORM.KEY-CLRREC |
| COORDINATION_OPERATION | FORM.ON-CLEAR-DETAILS |
| CURRENT_FORM | TOOLBAR.EXIT1.WHEN-BUTTON-PRESSED |
| CURSOR_BLOCK | FORM.ON-POPULATE-DETAILS, FORM.WHEN-NEW-BLOCK-INSTANCE, IMPORTERS.ARBC_IMPR_NAME.KEY-LISTVAL, IMPORTERS.BUS_ID.KEY-LISTVAL, IMPORTERS.BUS_ID_BRNCH.KEY-LISTVAL, IMPORTERS.BUS_ID_TYPE_CD.KEY-LISTVAL … (+25) |
| CURSOR_ITEM | IMPORTERS.ARBC_IMPR_NAME.KEY-LISTVAL, IMPORTERS.BUS_ID.KEY-LISTVAL, IMPORTERS.BUS_ID_BRNCH.KEY-LISTVAL, IMPORTERS.BUS_ID_TYPE_CD.KEY-LISTVAL, IMPORTERS.BUS_ID_TYPE_NAME.KEY-LISTVAL, IMPORTERS.CITY_CODE_OF_ID.KEY-LISTVAL … (+26) |
| CURSOR_RECORD | IMPORTERS.ARBC_IMPR_NAME.KEY-LISTVAL, IMPORTERS.BUS_ID.KEY-LISTVAL, IMPORTERS.BUS_ID_BRNCH.KEY-LISTVAL, IMPORTERS.BUS_ID_TYPE_CD.KEY-LISTVAL, IMPORTERS.BUS_ID_TYPE_NAME.KEY-LISTVAL, IMPORTERS.CITY_CODE_OF_ID.KEY-LISTVAL … (+22) |
| CURSOR_VALUE | IMPR_SUSPN.SUSPN_END_DT.WHEN-VALIDATE-ITEM, IMPR_SUSPN.SUSPN_RLSE_DT.WHEN-VALIDATE-ITEM, IMPR_SUSPN.SUSPN_STRT_DT.WHEN-VALIDATE-ITEM, TITLE.SYSTEM_DATE.WHEN-VALIDATE-ITEM |
| FORM_STATUS | FORM.KEY-CLRFRM, TOOLBAR.SAVE.WHEN-BUTTON-PRESSED |
| MASTER_BLOCK | FORM.ON-CLEAR-DETAILS |
| MODE | FORM.KEY-CQUERY, IMPORTERS.ARBC_IMPR_NAME.KEY-LISTVAL, IMPORTERS.BUS_ID.KEY-LISTVAL, IMPORTERS.BUS_ID_BRNCH.KEY-LISTVAL, IMPORTERS.BUS_ID_TYPE_CD.KEY-LISTVAL, IMPORTERS.BUS_ID_TYPE_NAME.KEY-LISTVAL … (+24) |
| TRIGGER_BLOCK | FORM.KEY-CLRREC, FORM.KEY-CQUERY, FORM.ON-CLEAR-DETAILS |
| TRIGGER_ITEM | IMPR_SUSPN.SUSPN_END_DT.WHEN-VALIDATE-ITEM, IMPR_SUSPN.SUSPN_RLSE_DT.WHEN-VALIDATE-ITEM, IMPR_SUSPN.SUSPN_STRT_DT.WHEN-VALIDATE-ITEM, TITLE.SYSTEM_DATE.WHEN-VALIDATE-ITEM |
| TRIGGER_RECORD | IMPORTERS.POST-QUERY |

> **Parameter/global notes**
> - The 20 `P_*` parameters are inherited from the OLB and passed on by the launchers `APPS` / `BUTTON_LAST_TREE`. They map to the f345 items as in IMPR1110 §12 (`P_USER_ID` → `SSO_APP_USER`, `P_CURR_PORT_CD`, `P_PORT_TYPE`, `P_CLASS_CD`, `P_USER_TYPE` → `V_USR_TYPE`, `P_WS_ID` → `P_GLOBAL_V_WS_ID`). The login forms are now available (`forms/SC/user_login_fmb.xml` and its variants); this step does not analyse them.
> - **`CURRENT_SIDE`** is the form's own parameter (no default). No static `ADD_PARAMETER('CURRENT_SIDE', …)` exists in the launchers. `APPS` adds per-module parameters in a loop over `SC_PORT_SETTING (VAR_NAME, VAR_VALUE)` filtered by `PORT_CD = P_CURR_PORT_CD` and `SYSOBJ_ID = <module>` (cursor `c_modudle_parameter`), so the value most likely comes from that table per port. The same cursor and loop are active in this form's own PU `EXECUTE_FUNCTION` (the standard way a module starts another one with its parameters). The data still has to be confirmed (§15 #1). Values used: 1 (audit / differences), 2 (customs control), 3 (head office, only with port 99). The only other form using it is IMPR1125.
> - `P_CURR_PORT_CD = 99` (head office) may choose any port (`PORT_CD` becomes insertable / updatable in WNFI and is not forced in PRE-QUERY).
> - Globals: `PORT_CD`, `IMPR_NBR`, `Exec_Query_Now` drive the "type the importer number → query" flow; `PORT_NAME`, `CTRY_CD`, `CRTY_ARBC_NAME`, `CITY_CD`, `CITY_ARB_NAME`, `IMPR_TYPE_CD`, `IMPR_TYPE_NAME` are return channels of the LOV forms; `CG$*` are Designer internals; `CURRENT_VER=2` / `CURRENT_DT='05-08-2026'` are version stamps. None needs an application item except where the step 03 design keeps the search flow.

## 13. Menu & Security

### 13.1 Menu

| Property | Value |
|---|---|
| Menu module | `CIC_MENU` (`forms/COMMON/menus/CIC_MENU_MMB.xml`); it does not open IMPR1120 or pass parameters. Screens are opened by `APPS` / `BUTTON_LAST_TREE` |
| SET_MENU_ITEM_PROPERTY | **not used** |
| In-form "menu" | `LSIDE` side menu (`TMPLT.POPULATE_FUNCTIONS`), `TOOLBAR.FUN_BUT`, `KEY-F9`. `ADJ_FUNS` and `EXEC_FUNS` are empty (`NULL;`), so the form switches no function on or off itself |

### 13.2 Function-level and data security

| Mechanism | Location | Details |
|---|---|---|
| Screen access by site | WHEN-NEW-FORM-INSTANCE | `CURRENT_SIDE = 3` and `P_CURR_PORT_CD ≠ 99` → message "ليس لديك الصلاحية للدخول على الشاشة" + `EXIT_FORM` |
| Port scope | WHEN-NEW-FORM-INSTANCE, PRE-QUERY, WHEN-CREATE-RECORD | outside port 99, `IMPORTERS.PORT_CD` is forced to `P_CURR_PORT_CD`; port 99 may choose any port |
| Allowed reason / side per site | SUSPN_RSN_CD / SUSPN_SIDE_CD WNII, WVI, WHEN-LIST-CHANGED | rule table in §4 notes |
| Rows of another side | IMPR_SUSPN.WHEN-NEW-RECORD-INSTANCE | `NEXT_RECORD` skips rows whose `SUSPN_SIDE_CD` belongs to another site, so they cannot be edited or deleted (they are still displayed) |
| Delete permission | `TMPLT.KEY_DELETE_RECORD` | only when toolbar `REMOVE` is visible and enabled (function security of the frame) |
| Function menu | PU EXECUTE_FUNCTION | `SC_SYSTEM_OBJECTS`, `SC_PORT_SETTING`, role tables through `TMPLT` / `KEY_CONTROL` |

### 13.3 APEX mapping notes (f345 standard; no code in this step)

- **Page access:** the application's existing privileges (CLAUDE.md §8); no authorization schemes are generated. The site check (`CURRENT_SIDE = 3` outside port 99) is a business rule: a Before Header check calling `IMPR1120` that stops the page with the same message.
- **Site value:** `CURRENT_SIDE` → page item `P<page>_P_CURRENT_SIDE`, filled at page load from its source (§15 #1).
- **Rows of another side:** IG row read-only (and no delete) through a BOOLEAN function `IMPR_SUSPN_IS_READ_ONLY(I_SUSPN_SIDE_CD, I_CURRENT_SIDE, I_CURR_PORT_CD)` instead of `NEXT_RECORD`.
- **Functions:** f345 *Page Functions* list in region `FUNCS`.

## 14. Risk Assessment

> The "Proposed APEX approach" follows the f345 standard (CLAUDE.md §4b, §4c; `docs/f345_reference_standard.md` §9–§10). Nothing is generated in this step.

| # | Risk item | Location (trigger/object) | Level | Reason | Proposed APEX approach |
|---|---|---|---|---|---|
| 1 | DB COMMIT inside POST-INSERT, plus COMMIT in the delete and save paths | IMPR_SUSPN.POST-INSERT (`STANDARD.COMMIT`, per inserted row), `TMPLT.KEY_DELETE_RECORD`, TOOLBAR.SAVE | High | A COMMIT in POST-INSERT commits half-processed rows: with several new rows, the first is committed before the rest are validated | No COMMIT in the package; APEX commits at the end of the request. Notification handled as in #2 |
| 2 | SMS / notification sent from POST-INSERT, every error hidden | IMPR_SUSPN.POST-INSERT → `GNRL.GET_CUSTOMS_SETTING`, `LIB_APX_USR.APEX_NOTIFICATIONS.SEND_SMS_EMAIL_NOTIFY`, `SMS_MESSAGE.SEND_SMS_MESSAGE` (all **MISSING SOURCE**) | High | External side effect inside the transaction; signatures unknown; `WHEN OTHERS THEN NULL` | Procedure `IMPR_SUSPN_POST_INSERT` called by the IG process `IMPR_SUSPN POST-INSERT`, keeping the two channels and the swallowed errors (preserve behaviour). `-- SUGGESTION:` log the failure. Timing relative to the commit: §15 #4 |
| 3 | Business rules driven by the `CURRENT_SIDE` parameter, whose source is unconfirmed | WNFI, SUSPN_RSN_CD / SUSPN_SIDE_CD WNII / WVI / WLC, IMPR_SUSPN.WNRI | High | Without the right value, defaults, allowed reasons / sides, editable rows and screen access are all wrong | Page item `P<page>_P_CURRENT_SIDE` filled from the confirmed source (§15 #1); rules in `IMPR1120` functions: defaults → item default / DA Set Value, rejections → `<ITEM>_VALIDATION`, other-side rows → row read-only (§13.3) |
| 4 | Rows of other sides skipped with `NEXT_RECORD` in WHEN-NEW-RECORD-INSTANCE | IMPR_SUSPN.WNRI | Medium | Navigation trick, no APEX equivalent; at the last row Forms moves on to a new record | IG row-level read-only and no delete for those rows (BOOLEAN function); rows stay visible as in Forms |
| 5 | `SUSPN_SEQ = MAX(SUSPN_SEQ) + 1` over the whole table, no lock | IMPR_SUSPN.PRE-INSERT | Medium | Two users saving at the same time get the same number → PK violation | Keep the rule in `IMPR_SUSPN_PRE_INSERT` (preserve behaviour); `-- SUGGESTION:` a DB sequence (needs a migration script and a decision, §15 #5) |
| 6 | Soft delete replacing the DELETE | IMPR_SUSPN.ON-DELETE (UPDATE `SUSPN_RLSE_DT` = current Hijri date + activity log), block WHERE `SUSPN_RLSE_DT IS NULL` | Medium | The automatic IG DML would really delete the row | IG custom DML: for row status D, call `IMPR_SUSPN_ON_DELETE`; region SQL keeps `SUSPN_RLSE_DT IS NULL` |
| 7 | Query started by validation + navigation (`Exec_Query_Now` globals) | IMPORTERS.IMPR_NBR.WVI → IMPR_TYPE_CD.WNII (`CLEAR_BLOCK` + `EXECUTE_QUERY`), PRE-QUERY | Medium | Navigation-driven query | Search page `<page>01` (port, importer number, names, type, country, city) returning `PORT_CD` + `IMPR_NBR`; the main page loads the importer. `IMPR_NBR VALIDATION` keeps message 9-150 |
| 8 | Dynamic DEFAULT_WHERE by string concatenation | IMPORTERS.PRE-QUERY (`CGFK$DEFAULT_WHERE` on PORT_NAME, `STR.StrFormat` on the Arabic name), POST-QUERY reset | Medium | Concatenated SQL from user input (injection risk in Forms) | Search page SQL with bind variables only (CLAUDE.md §6 #9); `STR_DB.StrFormat` applied to the bind |
| 9 | Rejections without a message | SUSPN_RSN_CD.WVI, SUSPN_SIDE_CD.WLC, SUSPN_SIDE_CD.WVI (value reset + `FORM_TRIGGER_FAILURE`) | Medium | APEX validations need an error text | `<ITEM>_VALIDATION` returning an error; text to agree (§15 #12). The silent value reset becomes the item default plus a restricted LOV |
| 10 | Hijri dates with validation and calendar forms | SUSPN_STRT_DT (≥ today), SUSPN_END_DT (≥ start), SUSPN_RLSE_DT; `INTRFACE.DISP_CALENDAR` / `DISP_DATE_CON` | Medium | APEX 21.2's date picker is Gregorian | DATE items with the Forms mask and validation through `HIJDATE_DB` (as decided for IMPR1110, to confirm, §15 #8) |
| 11 | PRE-UPDATE changes the release date, errors hidden | IMPR_SUSPN.PRE-UPDATE (`SUSPN_RLSE_DT := SUSPN_END_DT` when the end date ≤ today, else NULL; `WHEN OTHERS THEN NULL`) | Medium | A hidden rule: editing an expired suspension releases it | Keep in `IMPR_SUSPN_PRE_UPDATE` together with the activity log; documented in the page spec |
| 12 | Master block: insert allowed by default but used only as a search header | IMPORTERS (Insert default, items not insertable, WHEN-CREATE-RECORD) | Medium | Unclear whether importers may be created here | Form region read only, no CREATE for the master (§15 #6) |
| 13 | Attached libraries without source (OFGTEL …) | IMPORTERS / IMPR_SUSPN ON-ERROR (`CGTE$*`) | Medium | Constraint messages, e.g. `IS_1_IMP_FK`, FRM-41105 / 41106 | f345 `APP_ERROR_HANDLER` + Text Messages by constraint name; the texts in the two ON-ERROR triggers are known |
| 14 | `FORMS_DDL('ALTER SESSION SET NLS_DATE_FORMAT …')` + SET_APPLICATION_PROPERTY | FORM.PRE-FORM | Medium | Session-level NLS change | f345 Globalization attributes; no ALTER SESSION |
| 15 | Reports / dynamic CALL_FORM via the function menu | PU EXECUTE_FUNCTION (`REP.RUN_PRODUCT`, `V_CALLED_FORM`) | Medium | Depends on the module's entries in `SC_SYSTEM_OBJECTS` (unknown) | f345 *Page Functions* list; report technology only if the module has reports (§15 #9) |
| 16 | LOV forms via CALL_FORM with :GLOBAL return values | PORT_CD, IMPR_TYPE_CD, CTRY_CD, CITY_CODE_OF_ID KEY-LISTVAL | Low | Used only as query criteria | Popup LOVs (shared `LOV_*`) on the search page filters |
| 17 | Runtime list population from CG_REF_CODES | PU CGDV$POPULATE_DYNAMIC_LISTS (3 lists) | Low | Lists built at startup | Shared LOVs on `CG_REF_CODES` (domains `ALLOWED EXPORT`, `IMPR_SUSPN_RSN_CD`, `SUSPN SIDE CD`) |
| 18 | `SUSPN_SIDE_CD` enabled only while empty | IMPR_SUSPN.POST-QUERY, POST-INSERT, WNRI | Low | Field enabling by record state | IG column read-only for existing rows (`SUSPN_SIDE_CD_IS_READ_ONLY`) |
| 19 | POST-QUERY lookups | IMPORTERS.POST-QUERY (4 `CGFK$QRY_*`) | Low | One master row, no N+1 problem | Joins in the master region SQL |
| 20 | Designer master-detail coordination | ON-POPULATE-DETAILS / ON-CLEAR-DETAILS / CGBS$ | Low | Standard pattern | Native Form + IG master-detail |
| 21 | Activity log around DML | IMPR_SUSPN PRE-INSERT / PRE-UPDATE / ON-DELETE (`ACTIVITY.ADD_ACTIVITY(9,3,1/2/3)`) | Low | Source available (`ACTIVITY_DB`) | Same calls inside the DML procedures with the f345 items |
| 22 | Timers, EDI ticker, session timeout, Windows DLL, TEXT_IO | NIB library, unused PUs | Low | Frame behaviour | Dropped, as decided for IMPR1110 (§15 #10) |
| 23 | KEY-* overrides and the 19 Designer KEY-LISTVAL checks | form / block / item KEY-* | Low | Keyboard behaviour | Page 0 toolbar, popup LOVs, item read-only state |
| 24 | Designer MS-Help | KEY-HELP (form, IMPORTERS, IMPR_SUSPN) | Low | Obsolete | Dropped |
| 25 | Simple validations and defaults | `SUSPN_RSN_TEXT` required, `SUSPN_STRT_DT` default today (WNII), `SUSPN_RSN_TEXT` from the CG_REF_CODES meaning | Low | Straightforward | Item defaults, `<ITEM> VALIDATION`, DA with FOS |

**High risks: 3** (#1, #2, #3) · Medium: 12 (#4–#15) · Low: 10 (#16–#25)

## 15. Open Questions / Missing Sources

| # | Open question / missing source | Status (2026-11-23) | Why it matters | Needed from |
|---|---|---|---|---|
| 1 | Where does `:PARAMETER.CURRENT_SIDE` come from, and what do 1 / 2 / 3 mean? | Open. Most likely `SC_PORT_SETTING (VAR_NAME = 'CURRENT_SIDE', VAR_VALUE)` per port and module, passed by the launcher loop `c_modudle_parameter` (§12 notes). Meanings from the code / module comment: 1 = audit and differences, 2 = customs control, 3 = head office (port 99 only) | Every side rule (risk #3) | Data owner: `SELECT * FROM SC_PORT_SETTING WHERE VAR_NAME = 'CURRENT_SIDE'` |
| 2 | How is IMPR1125 related? It has the same title, uses `CURRENT_SIDE` and sends the same SMS | Open, not analysed (one form per session) | One page or two in APEX | Business owner, then the IMPR1125 step 01 |
| 3 | Sources / signatures of `SMS_MESSAGE`, `LIB_APX_USR.APEX_NOTIFICATIONS`, `GNRL.GET_CUSTOMS_SETTING`, and setting `NE_INTEGRATION` | Open: **MISSING SOURCE** | Compilation of `IMPR1120`, notification path (risk #2) | DBA |
| 4 | When may the notification be sent: before the commit (as now, then COMMIT) or only after a successful save? Should its errors stay hidden? | Open | Behaviour if the save fails after the SMS | Business owner |
| 5 | `SUSPN_SEQ`: keep `MAX+1` over the whole table, or use a DB sequence (migration script)? | Open: preserved for now (`-- SUGGESTION:`) | Concurrent saves (risk #5) | Business owner / DBA |
| 6 | May an importer be inserted from this screen (master Insert at the default, table usage `IMPORTERS SEL INS`)? | Open: assumed **no** (query-only header) | CREATE on the master region | Business owner |
| 7 | List contents: the XML static values (6 reasons, 7 sides) differ from the module comment (3 / 4) and are overwritten from `CG_REF_CODES` at runtime | Open | LOV definitions and side rules | Data owner: `CG_REF_CODES` rows of the 3 domains |
| 8 | Hijri date handling (stored as DATE, Forms mask, `HIJDATE_DB` validation): does the IMPR1110 decision of 2026-11-19 apply here too? | Assumed yes, to confirm | Date items | Business owner |
| 9 | Which functions / reports does the module have in `SC_SYSTEM_OBJECTS`? | Open (`ADJ_FUNS` / `EXEC_FUNS` are empty here) | Page Functions list, reports | Data owner |
| 10 | Timers / EDI ticker / custom session timeout dropped: does the IMPR1110 decision of 2026-11-19 apply? | Assumed yes | – | Business owner |
| 11 | Texts of messages 9-100, 9-110, 9-150 (`STR.DispArbMsg`, read through `STR_DB`) | Open: **MISSING SOURCE** | Validation messages | Data owner / DBA |
| 12 | The reason / side rejections give no message: keep them silent (not possible in APEX) or add a text? | Open: a text is needed | Validation messages (risk #9) | Business owner |
| 13 | Library `OFGTEL` (Designer constraint messages) | Open: **MISSING SOURCE**; the block-specific texts are in the XML | Generic constraint messages | Forms team (optional) |
| 14 | Grants to `LIB_APX_USR` on `IMPR_SUSPNS`, `IMPORTERS`, `IMPORTER_BASIC_DATA`, `SD_PORTS`, `CG_REF_CODES`, `COUNTRIES`, `CITIES`, `IMPR_TYPES`, `IMPR_TYPE_ID_TYPES`, `BUS_ID_TYPES`, and on `ACTIVITY_DB`, `HIJDATE_DB`, `GNRL`, `SMS_MESSAGE`, `STR_DB` | Open | Compilation of `IMPR1120` | DBA |
| 15 | Is `IMPORTER_BASIC_DATA.MOBILE_NO` by `HQ_IMPR_NBR` still the right mobile source (IMPR1110 updates mobile numbers through `IMPR_UTILITIES`)? | Open | Notification recipient | Business owner |
