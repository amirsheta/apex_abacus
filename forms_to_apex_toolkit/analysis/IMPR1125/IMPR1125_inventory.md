# IMPR1125 – Inventory & Migration Risk Assessment

- **Form:** IMPR1125 (module name in the XML: `IMPR1125_CENTRAL`) – "صيانة توقيفات المستوردين", purpose "توقيفات المستوردين المركزية" (central importer suspensions, by unified importer number `HQ_IMPR_NBR`)
- **Source:** `forms/IMPR/IMPR1125_fmb.xml` (frmf2xml output, 628 lines)
- **Target:** Oracle APEX 21.2 on Oracle Database 12.1.0.2, reference application f345 (CLAUDE.md §4b, §4c)
- **Produced:** 2026-11-24 (step 01, revision 1): mechanical sections by `scripts/gen_inv.py`; manual analysis in sections 1, 2 notes, 3–9 notes, 10.3, 10.6–10.8, 11–15 (sources in `work/IMPR1125/inv_man/`).
- **Sources used besides the form XML:** library texts `forms/COMMON/libraries/*.pld` (`CIC_LIB`, `OFGBSL`), object library `forms/COMMON/olb/CIC_OLB_OLB.xml`, the LOV forms `forms/COMMON/lov_forms/LOV_IMPORT_HQ_NBR_fmb.xml` and `LOV_DELETE_IMP_SUSP_fmb.xml`, DB packages `plsql/Shared/ACTIVITY_DB.*` and `HIJDATE_DB.*`. The IMPR1110 / IMPR1120 inventories were used for the shared library and OLB findings; they are repeated here only where IMPR1125 uses them.
- **Relation to IMPR1120:** same title and frame, same SMS / notification pattern, but a **different data model**: IMPR1120 maintains port-level suspensions (`IMPORTERS` → `IMPR_SUSPNS`, by port + importer number); IMPR1125 maintains **central** suspensions (`HQ_IMPRS` → `IMPR_CNTRL_SUSPNS`, by unified number). It answers IMPR1120 §15 #2: two separate pages.
- **Scope rule:** anything not available is marked **MISSING SOURCE** and is not guessed: the libraries OFGTEL, SEC_LIB, OFGTAB, PICKLIST, POS, SCDLL, VCDLL, and the DB packages `SMS_MESSAGE`, `LIB_APX_USR.APEX_NOTIFICATIONS`, `GNRL`, `STR_DB`.

## 1. Summary

**Complexity: COMPLEX by the rubric** (driven by Designer and library boilerplate) · **business logic: SIMPLE–MEDIUM** · **Effort ESTIMATE: 5–7 developer-days**

### 1.1 Counts

| Object | Count | Notes |
|---|---|---|
| Blocks | 6 | 2 base-table: `HQ_IMPRS` (master, single record, never written: ON-INSERT / ON-UPDATE / ON-DELETE are `NULL`) and `IMPR_CNTRL_SUSPNS` (detail, 9 records on `IMPR_CNTRL_SUSPNS`); 4 OLB control blocks (TITLE, EDI_MSG, LSIDE, TOOLBAR) |
| Items | 103 | HQ_IMPRS 15, IMPR_CNTRL_SUSPNS 8, LSIDE 50, TOOLBAR 16, TITLE 12, EDI_MSG 2 |
| Triggers | 248 | Form 33 · Block 18 · Item 197. 83 contain code; 165 have no code in the form XML (inherited from the OLB) |
| Trigger PL/SQL lines | 1,969 total / 1,207 active | about 800 active lines are Designer boilerplate (14 copies of the KEY-LISTVAL "may the LOV be shown" check, ON-ERROR, KEY-HELP) |
| Program units | 26 | 872 total / 450 active lines. 12 are one-line wrappers of `NIB` and are not called by active code |
| **Total PL/SQL** | **2,841 total / 1,657 active** | Business rules (IMPR_CNTRL_SUSPNS triggers, HQ_IMPRS POST-QUERY / BUS_ID / HQ_IMPR_NBR, 2 LOV-form PUs) are about 230 active lines |
| Relations (master–detail) | 1 | `CGFK$ICS_HI_FK`: HQ_IMPRS → IMPR_CNTRL_SUSPNS on HQ_IMPR_NBR (Designer `CGBS$` coordination) |
| LOVs / Record groups | 1 / 1 (+1 runtime RG `CGDV$DLRG` for 3 list items) | `CGFK$HQ_IMPRS_BUS_ID_TYPE_CD` is attached to a display-only item and is not usable; importer selection is by the LOV form `LOV_IMPORT_HQ_NBR` |
| Canvases / Windows | 5 / 1 | all business items on `CG$PAGE_1` |
| Alerts | 10 | 9 from the OLB + `CG$ASK_COMMIT` (not referenced) |
| Module parameters | 22 | 20 `P_*` inherited from the OLB, `CG$STARTUP_MODE`, and **`CURRENT_SIDE`** (declared, **not used** by any code in this form) |
| Attached libraries | 17 | the same list as IMPR1110 / IMPR1120 |
| Called forms | 2 static LOV forms (`LOV_IMPORT_HQ_NBR`, `LOV_DELETE_IMP_SUSP`, both available) + 1 dynamic (`V_CALLED_FORM` in EXECUTE_FUNCTION) + the calendar form behind `INTRFACE.DISP_CALENDAR` | |
| :GLOBAL / :SYSTEM variables | 9 / 12 | |
| Visual attributes | 51 | OLB |
| Subclassed (OLB) objects | 143 | VA 51, items, triggers, parameters 20, alerts 9, blocks 6, canvases 5, window 1 |

### 1.2 Complexity rubric

| Metric | Value | Simple | Medium | Complex | Category |
|---|---|---|---|---|---|
| Data blocks | 2 base-table (6 with the control blocks) | 1–2 | 3–5 | > 5 | Simple |
| Triggers (total) | 248 | < 15 | 15–50 | > 50 | **Complex** |
| Lines of PL/SQL (triggers + PUs) | 2,841 (1,657 active) | < 300 | 300–1500 | > 1500 | **Complex** |
| Master–detail relations | 1 | 0–1 | 2–3 | > 3 | Simple |
| Called forms / libraries | 3 forms + 17 libraries | 0 | 1–3 | > 3 | **Complex** |
| Special features | SMS / notification send, RUN_PRODUCT (EXECUTE_FUNCTION), timers (NIB), TEXT_IO (unused PU) | none | 1 | ≥ 2 | **Complex** |

**Result: COMPLEX** (4 metrics reach Complex).

**Justification.** As in IMPR1120, the rubric is driven by generated code and the OLB frame, which the f345 shell replaces. The real work is smaller than IMPR1120: a read-only header that finds a unified importer (`HQ_IMPRS` + `SINGLE_IMPORTERS` lookups) and an editable grid of central suspensions with no side rules. The grid has a soft delete, a `MAX+1` key, an activity log, an SMS / notification with a COMMIT inside POST-INSERT, and a "show deleted suspensions" list.

**Effort ESTIMATE: 5–7 developer-days** for the main page (Form + IG), the search page, the deleted-suspensions dialog, package `IMPR1125` (validations, soft delete, key, notification, activity log), registry and testing. Not included: the DB packages without source (`SMS_MESSAGE`, `APEX_NOTIFICATIONS`, `GNRL`).

## 2. Module header

| Property | Value |
|---|---|
| Form name | IMPR1125_CENTRAL |
| Title | صيانة توقيفات المستوردين |
| First navigation block | HQ_IMPRS |
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
  IMPR1125_CENTRAL

MODIFIED
  APPDEV248       19/08/26  11:34 created by Form Generator for
                                  Form Builder Version 6.0.3.11.0

Repository APPLICATION SYSTEM
  IMPORTERS Version 1

PURPOSE
  - توقيفات المستوردين المركزية -

MODULE DESCRIPTION


MODULE NOTES



TABLE USAGES
  BASE   HQ_IMPRS                      SEL INS UPD
  BASE   IMPR_CNTRL_SUSPNS             SEL INS UPD DEL

WARNINGS - 19/08/26  11:34
  01001: No PL/SQL block text for button item
         HQ_IMPRS.BUT_SH_HQNUM; Button has no functionality.
  01280: display length = 11, item length = 10;
  01280: display length = 14, item length = 11;
  01280: display length = 34, item length = 30;
  01362: Popup list has too many values; 6 valid values (maximum is
         5)
  01362: Popup list has too many values; 7 valid values (maximum is
         5)
  01316: Foreign key constraint HI_BIT_FK in HQ_IMPRS has no
         enterable items or lookups

*******************************************************************
```

> Notes: generated by **Oracle Designer Form Generator 6.0.3.11** (APPDEV248, 19/08/26) and hand-modified (CR-8414 notification, "central by Nasser 29-06-2025", "NOUH" version stamp). Designer warnings in the module comment: `HQ_IMPRS.BUT_SH_HQNUM` had no PL/SQL (code was added later: `GO_ITEM('BUS_ID')` + `DO_KEY('LIST_VALUES')`), two combo-box list styles are invalid (6 and 7 values), and FK `HI_BIT_FK` (BUS_ID_TYPE_CD) has no enterable items. Table usage: `HQ_IMPRS SEL INS UPD`, `IMPR_CNTRL_SUSPNS SEL INS UPD DEL`, but the block ON-INSERT / ON-UPDATE / ON-DELETE of `HQ_IMPRS` are `NULL`, so the master is never written.

## 3. Blocks

> Properties absent from the XML are Forms defaults **or inherited from the object library** (`ParentModule`/`ParentName`); such values are shown as `default/OLB` (OLB properties: `forms/COMMON/olb/CIC_OLB_OLB.xml`).

| Block | Base table / Query data source | DML target | Type | Records displayed | Records buffered | WHERE clause | ORDER BY | Insert | Update | Delete | Query | Canvas(es) | Subclassed from |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| TITLE | – | – | control (non-DB) | default/OLB | default/OLB | – | – | default/OLB | default/OLB | default/OLB | default/OLB | – | CIC_OLB.olb:TITLE |
| EDI_MSG | – | – | control (non-DB) | default/OLB | default/OLB | – | – | default/OLB | default/OLB | default/OLB | default/OLB | – | CIC_OLB.olb:EDI_MSG |
| LSIDE | – | – | control (non-DB) | default/OLB | default/OLB | – | – | default/OLB | default/OLB | default/OLB | default/OLB | – | CIC_OLB.olb:LSIDE |
| TOOLBAR | – | – | control (non-DB) | default/OLB | default/OLB | – | – | default/OLB | default/OLB | default/OLB | default/OLB | – | CIC_OLB.olb:TOOLBAR |
| HQ_IMPRS | HQ_IMPRS | same as query source (default) | base-table | default/OLB | 4 | – | – | default/OLB | default/OLB | false | default/OLB | CG$PAGE_1 | cic_olb.olb:CGSO$BLOCK |
| IMPR_CNTRL_SUSPNS | IMPR_CNTRL_SUSPNS | same as query source (default) | base-table | 9 | 12 | WHERE   ( IMPR_CNTRL_SUSPNS.SUSPN_RLSE_DT is null ) | – | default/OLB | default/OLB | default/OLB | default/OLB | CG$PAGE_1 | cic_olb.olb:CGSO$BLOCK_MR |

Block `HQ_IMPRS` comment (decoded):

```text
*******************************************************************

BLOCK NAME
  HQ_IMPRS

TABLE COMMENT
  جدول الارقام الموحدة للمستوردين

TABLE USAGES
  BASE   HQ_IMPRS                      SEL INS UPD
  ...    BUS_ID                        SEL INS UPD NUL
  ...    BUS_ID_TYPE_CD                SEL         NUL
  ...    BUS_ID_BRNCH                  SEL         NUL
  ...    HQ_IMPR_NBR                   SEL INS     NUL

TUI DESCRIPTION


*******************************************************************
```

Block `IMPR_CNTRL_SUSPNS` comment (decoded):

```text
*******************************************************************

BLOCK NAME
  IMPR_CNTRL_SUSPNS

TABLE COMMENT
  جدول توقيفات المستوردين

TABLE USAGES
  BASE   IMPR_CNTRL_SUSPNS             SEL INS UPD DEL
  ...    SUSPN_STRT_DT                 SEL INS UPD
  ...    SUSPN_END_DT                  SEL INS UPD NUL
  ...    HQ_IMPR_NBR                   SEL INS
  ...    SUSPN_SEQ                     SEL INS     NUL
  ...    SUSPN_RSN_CD                  SEL INS UPD
  ...    SUSPN_RSN_TEXT                SEL INS UPD
  ...    SUSPN_SIDE_CD                 SEL INS UPD
  ...    SUSPN_RLSE_DT                 SEL INS UPD NUL

JOIN CONDITION
  IMPR_CNTRL_SUSPNS.HQ_IMPR_NBR = HQ_IMPRS.HQ_IMPR_NBR

TUI DESCRIPTION


*******************************************************************
```

> **Block notes**
> - `TITLE`, `EDI_MSG`, `LSIDE`, `TOOLBAR` are OLB control blocks (screen frame). They are replaced by the f345 page template, the page 0 toolbar and the page 0 `FUNCS` drawer.
> - `HQ_IMPRS` (master) is a **search header**. Delete is not allowed; ON-INSERT, ON-UPDATE, ON-DELETE are `BEGIN NULL; END;`, so nothing typed in it is saved. The user types `BUS_ID` or `HQ_IMPR_NBR` (or picks from the LOV form `LOV_IMPORT_HQ_NBR`); the item WHEN-VALIDATE-ITEM checks that the number exists in `HQ_IMPRS` and puts it in `:GLOBAL.BUS_NBR` / `:GLOBAL.HQ_IMPR_NBR`; the **block-level** WHEN-NEW-ITEM-INSTANCE then runs `CLEAR_BLOCK` + `EXECUTE_QUERY`, and PRE-QUERY copies the globals into the query criteria.
> - `HQ_IMPRS.POST-QUERY` fills the display items from `BUS_ID_TYPES`, **`SINGLE_IMPORTERS`** (Arabic / English name, country, importer type, export type, city of ID, by `HQ_IMPR_NBR`), `COUNTRIES`, `CITIES`, `IMPR_TYPES`, then counts released suspensions (`SUSPN_RLSE_DT IS NOT NULL`) and, if there are any, asks "توجد إيقافات محذوفة من على هذا المستورد , هل تود أستعراضها ؟" and opens `LOV_DELETE_IMP_SUSP` (read-only list).
> - The `SINGLE_IMPORTERS` and `BUS_ID_TYPES` SELECT ... INTO have no exception handler: TOO_MANY_ROWS (more than one single importer per unified number) or NO_DATA_FOUND (empty `BUS_ID_TYPE_CD`) stop POST-QUERY with an ON-ERROR message (§15 #3).
> - `IMPR_CNTRL_SUSPNS` (detail, 9 rows shown, 12 buffered) has `WHERE IMPR_CNTRL_SUSPNS.SUSPN_RLSE_DT IS NULL`, so only active suspensions are shown. `HQ_IMPR_NBR` is copied from the master (`CopyValueFromItem`).
> - Delete on `IMPR_CNTRL_SUSPNS` is a **soft delete**: `KEY-DELREC` → `TMPLT.KEY_DELETE_RECORD` (WARNING confirm, `Delete_record`, COMMIT); `ON-DELETE` replaces the DELETE with `UPDATE IMPR_CNTRL_SUSPNS SET SUSPN_RLSE_DT = HIJDATE.CUR_HIJ_DATE` + activity log `(9, 7, 3)`.

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

### 4.5 Block `HQ_IMPRS` (15 items)

| # | Item | Item type | Subclass (OLB) | Data type | Max len | Column name | DB item | Required | LOV | Default value | Format mask | Canvas / tab page | Visible | Insert / Update / Query allowed | Prompt / label | Copy-value-from / calc | List values / hint |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | BUS_ID | – | CGSO$CHAR | – | 15 | BUS_ID | – | – | – | – | – | CG$PAGE_1 | – | – | الرقم الاستدلالـــــــى | – | الرقم الاستدلالى للمستورد الرئيسى |
| 2 | BUT_SH_HQNUM | – | CGSO$LOV_BUT | – | 2 | – | false | true | – | – | – | CG$PAGE_1 | – | – | – | – | – |
| 3 | BUS_ID_TYPE_CD | – | CGSO$CHAR_ARB_DO | Number | 4 | BUS_ID_TYPE_CD | – | – | CGFK$HQ_IMPRS_BUS_ID_TYPE_CD | – | – | CG$PAGE_1 | – | ·/·/true | نوعه | – | نوع الرقم الإستدلالي - list of values available |
| 4 | BUS_ID_TYPE_NAME | – | CGSO$CHAR_ARB_DO | – | – | – | false | – | – | – | – | CG$PAGE_1 | – | true/true/· | – | – | Enter value for |
| 5 | BUS_ID_BRNCH | – | CGSO$CHAR_ARB | – | 10 | BUS_ID_BRNCH | – | – | – | – | – | CG$PAGE_1 | – | false/false/· | الرقم الاستدلالي الفرعي | – | رقم الفرع التابع للمستورد الرئيسى |
| 6 | HQ_IMPR_NBR | – | CGSO$NUMBER | – | 11 | HQ_IMPR_NBR | – | true | – | – | – | CG$PAGE_1 | – | ·/false/· | الــرقــــم الــمــوحـد | – | رقم الحاسب الآلى للمستورد في المصلحة |
| 7 | CITY_CODE_OF_ID | – | CGSO$CHAR_ARB | – | – | – | false | false | – | – | – | CG$PAGE_1 | – | false/false/false | مصدر الرقم الإستدلالي | – | Enter value for مصدر الرقم الإستدلالي |
| 8 | CITY_CODE_OF_NAME | – | CGSO$CHAR_ARB_DO | – | – | – | false | false | – | – | – | CG$PAGE_1 | – | – | – | – | Enter value for |
| 9 | IMPR_TYPE_CD | – | CGSO$CHAR_ARB_DO | – | – | – | false | – | – | – | – | CG$PAGE_1 | – | – | رمز النشاط التجاري | – | Enter value for رمز النشاط التجاري |
| 10 | IMPR_TYPE_NAME | – | CGSO$CHAR_ARB_DO | – | – | – | false | false | – | – | – | CG$PAGE_1 | – | – | – | – | Enter value for |
| 11 | IMPR_EXPR_TYPE | – | CGSO$COMBO_DO | – | – | – | false | false | – | 0 | – | CG$PAGE_1 | – | ·/·/false | النشاط الجمركي | – | 0=تصدير; 1=إستيراد; 2=إستيراد-تصدير |
| 12 | CTRY_CD | – | CGSO$CHAR_ARB_DO | – | – | – | false | false | – | – | – | CG$PAGE_1 | – | – | الجنسيــــــــــــــــــــه | – | Enter value for الجنسيــــــــــــــــــــه |
| 13 | CRTY_ARBC_NAME | – | CGSO$CHAR_ARB_DO | – | – | – | false | false | – | – | – | CG$PAGE_1 | – | – | – | – | Enter value for |
| 14 | ARBC_IMPR_NAME | – | CGSO$CHAR_ARB_DO | – | – | – | false | false | – | – | – | CG$PAGE_1 | – | – | الاســــم العربــــــــى | – | Enter value for الاســــم العربــــــــى |
| 15 | ENG_IMPR_NAME | – | CGSO$CHAR_EN_DO | – | – | – | false | false | – | – | – | CG$PAGE_1 | – | – | الاســــم الأجنبـــــــي | – | Enter value for الاســــم الأجنبـــــــي |

### 4.6 Block `IMPR_CNTRL_SUSPNS` (8 items)

| # | Item | Item type | Subclass (OLB) | Data type | Max len | Column name | DB item | Required | LOV | Default value | Format mask | Canvas / tab page | Visible | Insert / Update / Query allowed | Prompt / label | Copy-value-from / calc | List values / hint |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | SUSPN_STRT_DT | – | CGSO$HDATE_ARB | Date | – | SUSPN_STRT_DT | – | true | – | – | – | CG$PAGE_1 | – | – | بداية الإيقاف | – | تاريخ بدايه التوقيف |
| 2 | SUSPN_END_DT | – | CGSO$HDATE_ARB | Date | – | SUSPN_END_DT | – | – | – | – | – | CG$PAGE_1 | – | – | نهاية الإيقاف | – | تاريخ نهايه التوقيف |
| 3 | HQ_IMPR_NBR | – | CGSO$NUMBER_MR_MD | – | 11 | HQ_IMPR_NBR | – | false | – | – | – | – | false | false/false/false | رقم المستورد الموحد | HQ_IMPRS.HQ_IMPR_NBR | رقم المستورد الموحد |
| 4 | SUSPN_SEQ | – | CGSO$NUMBER_MR | – | 11 | SUSPN_SEQ | – | – | – | – | – | – | false | false/false/false | مسلسل التوقيف | – | مسلسل التوقيف |
| 5 | SUSPN_RSN_CD | – | CGSO$COMBO | Number | 2 | SUSPN_RSN_CD | – | true | – | 1 | – | – | – | – | السبب | – | 1=فروق مالية; 2=استكمال أوراق; 3=أخري; 4=السجل التجاري مشطوب بوزارة التجارة; 5=غرامات بوحدة الغرامات بالمصلحة ولم تسدد; 6=رقم الهوية أو رقم الاقامة غير صحيح |
| 6 | SUSPN_RSN_TEXT | – | CGSO$CHAR_ARB | – | 50 | SUSPN_RSN_TEXT | – | true | – | – | – | CG$PAGE_1 | – | – | ملاحظات | – | توصيف سبب التوقيف |
| 7 | SUSPN_SIDE_CD | – | CGSO$COMBO_DO | Number | 2 | SUSPN_SIDE_CD | – | true | – | 5 | – | CG$PAGE_1 | – | true/true/· | الجهة | – | 1=التدقيق والفرو قات; 2=الرقابة الجمركيه; 3=الحاسب الألي; 4=المدير العام; 5=هيئة الزكاة و الضريبة و الجمارك  - إدارة القيود; 6=وزارة التجارة; 7=وحدة الغرامات - هيئة الزكاة و الضريبة و الجمارك |
| 8 | SUSPN_RLSE_DT | – | CGSO$DATE_MR | – | – | SUSPN_RLSE_DT | – | – | – | – | – | – | false | false/false/false | تاريخ حذف التوقيف | – | تاريخ حذف التوقيف |

> **Item notes**
> - Items of the 4 OLB control blocks have no attributes in the form XML; they come from `CIC_OLB_OLB.xml` and are not migrated.
> - `HQ_IMPRS`: only `BUS_ID` (class `CGSO$CHAR`) and `HQ_IMPR_NBR` (`CGSO$NUMBER`, required, update not allowed, range ±9,999,999,999) are enterable; they are the search keys. Every other item is display only (OLB class `CGSO$CHAR_ARB_DO` / `CGSO$COMBO_DO`: `Enabled=false`) or not enterable (`BUS_ID_BRNCH`, `CITY_CODE_OF_ID`: insert / update false). `BUT_SH_HQNUM` is the LOV button of `BUS_ID`.
> - `IMPR_EXPR_TYPE` (master), `SUSPN_RSN_CD` and `SUSPN_SIDE_CD` (detail) are list items. The static values in the XML are overwritten at startup by `CGDV$POPULATE_DYNAMIC_LISTS` from `CG_REF_CODES` (domains `ALLOWED EXPORT`, `IMPR_SUSPN_RSN_CD`, `SUSPN SIDE CD`).
> - **`SUSPN_RSN_CD` has no canvas** (no `CanvasName`): it is not shown and always keeps its default **1** ("فروق مالية"). The user types the reason only as free text in `SUSPN_RSN_TEXT` (required, 50 chars).
> - **`SUSPN_SIDE_CD`** is shown but its OLB class `CGSO$COMBO_DO` has `Enabled=false` (the item's own `InsertAllowed/UpdateAllowed=true` do not enable it): it is display only and always keeps its default **5** ("هيئة الزكاة و الضريبة و الجمارك - إدارة القيود"). Unlike IMPR1120 there are no side rules.
> - `SUSPN_STRT_DT` (required) and `SUSPN_END_DT` are Hijri dates (OLB class `CGSO$HDATE_ARB`, mask `MI-MM-RRRR`), validated by `HIJDATE.VALID_HIJ_DATE`; the end date must not be before the start date (alert text in the trigger). No "start ≥ today" rule here (IMPR1120 has one). Calendar on KEY-LISTVAL (`INTRFACE.DISP_CALENDAR`) and KEY-F4 (`INTRFACE.DISP_DATE_CON`).
> - `HQ_IMPR_NBR`, `SUSPN_SEQ`, `SUSPN_RLSE_DT` of the detail are hidden. `SUSPN_SEQ` is set in PRE-INSERT (`MAX(SUSPN_SEQ)+1` over the **whole** table); `SUSPN_RLSE_DT` only in ON-DELETE.

## 5. Relations (master–detail)

| Relation | Master block | Detail block | Join condition | Delete behaviour | Deferred / Auto-query | Prevent masterless operations | Subclassed from |
|---|---|---|---|---|---|---|---|
| CGFK$ICS_HI_FK | HQ_IMPRS | IMPR_CNTRL_SUSPNS | HQ_IMPRS.HQ_IMPR_NBR = IMPR_CNTRL_SUSPNS.HQ_IMPR_NBR | not in XML → Forms default (Non-Isolated) | default (false)/default (false) | true | – |

## 6. Triggers

> **Trigger notes**
> - 248 triggers: Form 33, Block 18, Item 197. 83 contain code in the form XML; the 165 without code are inherited from `CIC_OLB_OLB.xml` (LSIDE 150 mouse triggers, TOOLBAR buttons, TITLE / EDI_MSG item triggers, form KEY-F4). This is the standard screen frame, as in IMPR1110 / IMPR1120.
> - Form-level triggers are `NIB.*` delegations (`CIC_LIB.pld`), Designer block synchronisation (`CGBS$` / `CGBS2$`), or Designer help / messages. The only business code at form level is in WHEN-NEW-FORM-INSTANCE: it clears `:GLOBAL.HQ_IMPR_NBR` / `:GLOBAL.BUS_NBR` and sets `:GLOBAL.current_ver := 2`. The commented-out block in WNFI (timers, versioning) is not active.
> - 12 KEY-LISTVAL triggers on HQ_IMPRS items and 2 on IMPR_CNTRL_SUSPNS start with the 32-line Designer check (`CGAP$OLES_SEQUENCE_BEFORE`). Only `BUS_ID` calls an LOV form (`SINGLE_IMP_LOV`); the date items call the calendar. In APEX the check becomes the item's read-only state.
> - The business rules are in the `IMPR_CNTRL_SUSPNS` block triggers (PRE-INSERT, PRE-UPDATE, ON-DELETE, POST-INSERT), the two date WHEN-VALIDATE-ITEM triggers, and the HQ_IMPRS search flow (BUS_ID / HQ_IMPR_NBR WHEN-VALIDATE-ITEM, PRE-QUERY, POST-QUERY, WHEN-NEW-ITEM-INSTANCE).

### 6.0 Trigger index

| # | Level | Owner | Trigger | Lines (total / active) | Exec. hierarchy | Source | Program units called |
|---|---|---|---|---|---|---|---|
| 1 | Form | FORM | KEY-EDIT | 21 / 1 | default (Override) | XML | – |
| 2 | Form | FORM | KEY-DUPREC | 10 / 1 | default (Override) | XML | – |
| 3 | Form | FORM | PRE-FORM | 36 / 10 | default (Override) | XML | – |
| 4 | Form | FORM | WHEN-NEW-FORM-INSTANCE | 151 / 16 | default (Override) | XML | CG$WHEN_NEW_FORM_INSTANCE |
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
| 210 | Block | HQ_IMPRS | ON-ERROR | 86 / 64 | default (Override) | XML | CGTE$CHECK_CONSTRAINT_VIO |
| 211 | Block | HQ_IMPRS | KEY-HELP | 18 / 16 | default (Override) | XML | – |
| 212 | Block | HQ_IMPRS | ON-DELETE | 3 / 3 | default (Override) | XML | – |
| 213 | Block | HQ_IMPRS | ON-INSERT | 3 / 3 | default (Override) | XML | – |
| 214 | Block | HQ_IMPRS | ON-UPDATE | 3 / 3 | default (Override) | XML | – |
| 215 | Block | HQ_IMPRS | POST-QUERY | 79 / 56 | default (Override) | XML | DELETE_SUSPS_LOV |
| 216 | Block | HQ_IMPRS | PRE-QUERY | 14 / 8 | default (Override) | XML | – |
| 217 | Block | HQ_IMPRS | WHEN-NEW-ITEM-INSTANCE | 15 / 11 | default (Override) | XML | – |
| 218 | Item | HQ_IMPRS.BUS_ID | KEY-LISTVAL | 3 / 3 | default (Override) | XML | SINGLE_IMP_LOV |
| 219 | Item | HQ_IMPRS.BUS_ID | WHEN-VALIDATE-ITEM | 23 / 17 | default (Override) | XML | SINGLE_IMP_LOV |
| 220 | Item | HQ_IMPRS.BUT_SH_HQNUM | WHEN-BUTTON-PRESSED | 7 / 5 | default (Override) | XML | – |
| 221 | Item | HQ_IMPRS.BUS_ID_TYPE_CD | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 222 | Item | HQ_IMPRS.BUS_ID_TYPE_NAME | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 223 | Item | HQ_IMPRS.BUS_ID_BRNCH | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 224 | Item | HQ_IMPRS.HQ_IMPR_NBR | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 225 | Item | HQ_IMPRS.HQ_IMPR_NBR | WHEN-VALIDATE-ITEM | 24 / 16 | default (Override) | XML | SINGLE_IMP_LOV |
| 226 | Item | HQ_IMPRS.CITY_CODE_OF_ID | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 227 | Item | HQ_IMPRS.CITY_CODE_OF_NAME | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 228 | Item | HQ_IMPRS.IMPR_TYPE_CD | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 229 | Item | HQ_IMPRS.IMPR_TYPE_NAME | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 230 | Item | HQ_IMPRS.CTRY_CD | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 231 | Item | HQ_IMPRS.CRTY_ARBC_NAME | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 232 | Item | HQ_IMPRS.ARBC_IMPR_NAME | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 233 | Item | HQ_IMPRS.ENG_IMPR_NAME | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 234 | Block | IMPR_CNTRL_SUSPNS | ON-ERROR | 78 / 56 | default (Override) | XML | CGTE$CHECK_CONSTRAINT_VIO |
| 235 | Block | IMPR_CNTRL_SUSPNS | KEY-HELP | 18 / 16 | default (Override) | XML | – |
| 236 | Block | IMPR_CNTRL_SUSPNS | KEY-DELREC | 3 / 3 | default (Override) | XML | – |
| 237 | Block | IMPR_CNTRL_SUSPNS | ON-DELETE | 21 / 13 | default (Override) | XML | – |
| 238 | Block | IMPR_CNTRL_SUSPNS | POST-INSERT | 57 / 53 | default (Override) | XML | – |
| 239 | Block | IMPR_CNTRL_SUSPNS | PRE-INSERT | 15 / 9 | default (Override) | XML | – |
| 240 | Block | IMPR_CNTRL_SUSPNS | PRE-UPDATE | 10 / 6 | default (Override) | XML | – |
| 241 | Item | IMPR_CNTRL_SUSPNS.SUSPN_STRT_DT | KEY-LISTVAL | 26 / 25 | default (Override) | XML | – |
| 242 | Item | IMPR_CNTRL_SUSPNS.SUSPN_STRT_DT | KEY-F4 | 26 / 25 | default (Override) | XML | – |
| 243 | Item | IMPR_CNTRL_SUSPNS.SUSPN_STRT_DT | WHEN-VALIDATE-ITEM | 14 / 12 | default (Override) | XML | – |
| 244 | Item | IMPR_CNTRL_SUSPNS.SUSPN_END_DT | KEY-LISTVAL | 26 / 25 | default (Override) | XML | – |
| 245 | Item | IMPR_CNTRL_SUSPNS.SUSPN_END_DT | KEY-F4 | 26 / 25 | default (Override) | XML | – |
| 246 | Item | IMPR_CNTRL_SUSPNS.SUSPN_END_DT | WHEN-VALIDATE-ITEM | 27 / 18 | default (Override) | XML | – |
| 247 | Item | IMPR_CNTRL_SUSPNS.SUSPN_SEQ | KEY-LISTVAL | 34 / 32 | default (Override) | XML | – |
| 248 | Item | IMPR_CNTRL_SUSPNS.SUSPN_RSN_TEXT | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |

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
- Lines: 151 total / 16 active (non-blank, non-comment)
- Built-ins: –
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

:GLOBAL.HQ_IMPR_NBR := NULL ;
:GLOBAL.BUS_NBR := NULL ;
:GLOBAL.current_ver := 2 ; --NOUH
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

#### HQ_IMPRS · ON-ERROR

- Level: Block · Owner: `HQ_IMPRS` · Execution hierarchy: default (Override)
- Lines: 86 total / 64 active (non-blank, non-comment)
- Built-ins: DBMS_ERROR_CODE, DBMS_ERROR_TEXT, ERROR_CODE, ERROR_TEXT, ERROR_TYPE
- Program units (form): CGTE$CHECK_CONSTRAINT_VIO
- Library / DB package calls: CGTE$POP_ERROR_STACK, CGTE$STRIP_CONSTRAINT, DES$FORM_ERRORS.PUSH, DES$FORM_ERRORS.RAISE_FAILURE

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
        Des$Form_errors.PUSH(server_msg, 'I', 'OFG', 0);
        Des$Form_errors.RAISE_FAILURE;
      END IF;

      /* FK - Child record found */
      IF (server_err = 2292) THEN
        IF (err_code = 40509) THEN
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

#### HQ_IMPRS · KEY-HELP

- Level: Block · Owner: `HQ_IMPRS` · Execution hierarchy: default (Override) · Fire in query: true
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

#### HQ_IMPRS · ON-DELETE

- Level: Block · Owner: `HQ_IMPRS` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 3 total / 3 active (non-blank, non-comment)
- Built-ins: –
- Program units (form): –
- Library / DB package calls: –

```plsql
BEGIN
NULL;
END;
```

#### HQ_IMPRS · ON-INSERT

- Level: Block · Owner: `HQ_IMPRS` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 3 total / 3 active (non-blank, non-comment)
- Built-ins: –
- Program units (form): –
- Library / DB package calls: –

```plsql
BEGIN
NULL;
END;
```

#### HQ_IMPRS · ON-UPDATE

- Level: Block · Owner: `HQ_IMPRS` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 3 total / 3 active (non-blank, non-comment)
- Built-ins: –
- Program units (form): –
- Library / DB package calls: –

```plsql
BEGIN
NULL;
END;
```

#### HQ_IMPRS · POST-QUERY

- Level: Block · Owner: `HQ_IMPRS` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 79 total / 56 active (non-blank, non-comment)
- Built-ins: –
- Program units (form): DELETE_SUSPS_LOV
- Library / DB package calls: STR.DISPALERT

```plsql
BEGIN
:GLOBAL.HQ_IMPR_NBR := NULL  ;
:GLOBAL.BUS_NBR := NULL  ;
END;



BEGIN

SELECT BUS_ID_TYPE_NAME
INTO :BUS_ID_TYPE_NAME
FROM BUS_ID_TYPES
WHERE BUS_ID_TYPE_CD = :BUS_ID_TYPE_CD;

SELECT
		ARBC_IMPR_NAME , ENG_IMPR_NAME ,
		CTRY_CD  , IMPR_TYPE_CD , IMPR_EXPR_TYPE,
		CITY_CODE_OF_ID
INTO
		:ARBC_IMPR_NAME , :ENG_IMPR_NAME ,
		:CTRY_CD  , :IMPR_TYPE_CD , :IMPR_EXPR_TYPE ,
		:CITY_CODE_OF_ID
FROM SINGLE_IMPORTERS
WHERE HQ_IMPR_NBR = :HQ_IMPRS.HQ_IMPR_NBR ;


IF :CTRY_CD IS NOT NULL THEN
	SELECT CRTY_ARBC_NAME
	INTO :CRTY_ARBC_NAME
	FROM 	COUNTRIES
	WHERE CTRY_CD = :CTRY_CD ;
END IF;


IF :CITY_CODE_OF_ID IS NOT NULL THEN
	SELECT CITY_ARB_NAME
	INTO :CITY_CODE_OF_NAME
	FROM 	CITIES
	WHERE CTRY_CD = :CTRY_CD
	AND CITY_CD = :CITY_CODE_OF_ID ;
END IF;

IF :IMPR_TYPE_CD IS NOT NULL THEN
	SELECT IMPR_TYPE_NAME
	INTO :IMPR_TYPE_NAME
	FROM 	IMPR_TYPES
	WHERE IMPR_TYPE_CD  = :IMPR_TYPE_CD  ;
END IF;




END;

DECLARE


V_COUNT NUMBER ;
RET NUMBER ;
BEGIN
SELECT COUNT(*)
INTO
V_COUNT
FROM IMPR_CNTRL_SUSPNS
WHERE HQ_IMPR_NBR = :HQ_IMPRS.HQ_IMPR_NBR

AND SUSPN_RLSE_DT IS NOT NULL ;

IF V_COUNT > 0 THEN


	RET := STR.DispALERT(' توجد إيقافات محذوفة من على هذا المستورد , هل تود أستعراضها ؟ ','CONFIRM');
	IF Ret = alert_button1 THEN
		DELETE_SUSPS_LOV ;
	END IF ;

END IF ;

END;
```

#### HQ_IMPRS · PRE-QUERY

- Level: Block · Owner: `HQ_IMPRS` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 14 total / 8 active (non-blank, non-comment)
- Built-ins: –
- Program units (form): –
- Library / DB package calls: –

```plsql
BEGIN
IF :GLOBAL.HQ_IMPR_NBR IS NOT NULL THEN

	--SET_BLOCK_PROPERTY('HQ_IMPRS',DEFAULT_WHERE,'HQ_IMPR_NBR = '||:GLOBAL.HQ_IMPR_NBR);
:HQ_IMPRS.HQ_IMPR_NBR := :GLOBAL.HQ_IMPR_NBR ;

END IF;
 IF :GLOBAL.BUS_NBR IS NOT NULL THEN
 	:HQ_IMPRS.BUS_ID := :GLOBAL.BUS_NBR ;
 END IF;



END;
```

#### HQ_IMPRS · WHEN-NEW-ITEM-INSTANCE

- Level: Block · Owner: `HQ_IMPRS` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 15 total / 11 active (non-blank, non-comment)
- Built-ins: CLEAR_BLOCK, EXECUTE_QUERY, GO_BLOCK
- Program units (form): –
- Library / DB package calls: –

```plsql
DECLARE
V_MSG_LEVEL  VARCHAR2(2000);
BEGIN


IF :GLOBAL.HQ_IMPR_NBR IS NOT NULL  OR  :GLOBAL.BUS_NBR IS NOT NULL  THEN
CLEAR_BLOCK(NO_VALIDATE);
GO_BLOCK('HQ_IMPRS');
EXECUTE_QUERY;

:GLOBAL.HQ_IMPR_NBR := NULL  ;
:GLOBAL.BUS_NBR := NULL  ;

END IF;
END;
```

#### IMPR_CNTRL_SUSPNS · ON-ERROR

- Level: Block · Owner: `IMPR_CNTRL_SUSPNS` · Execution hierarchy: default (Override) · Fire in query: true
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
        IF (constraint_name = 'ICS_HI_FK') THEN
          Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(13, 'This <p1> does not exist', 'رقم المستورد الموحد' ), 'E', 'OFG', 13);
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
      Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(35, 'Query of <p1> must be in context of <p2>', 'توقيفات المستور','الأرقام الموحدة للمستوردين' ), 'E', 'OFG', 35);
      Des$Form_errors.RAISE_FAILURE;
    ELSIF (err_code = 41106) THEN
      Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(36, 'Insert of <p1> must be in context of <p2>', 'توقيفات المستو','الأرقام الموحدة للمستوردين' ), 'E', 'OFG', 36);
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

#### IMPR_CNTRL_SUSPNS · KEY-HELP

- Level: Block · Owner: `IMPR_CNTRL_SUSPNS` · Execution hierarchy: default (Override) · Fire in query: true
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

#### IMPR_CNTRL_SUSPNS · KEY-DELREC

- Level: Block · Owner: `IMPR_CNTRL_SUSPNS` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 3 total / 3 active (non-blank, non-comment)
- Built-ins: –
- Program units (form): –
- Library / DB package calls: TMPLT.KEY_DELETE_RECORD

```plsql
BEGIN
	TMPLT.KEY_DELETE_RECORD;
END;
```

#### IMPR_CNTRL_SUSPNS · ON-DELETE

- Level: Block · Owner: `IMPR_CNTRL_SUSPNS` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 21 total / 13 active (non-blank, non-comment)
- Built-ins: RAISE FORM_TRIGGER_FAILURE
- Program units (form): –
- Library / DB package calls: ACTIVITY.ADD_ACTIVITY, HIJDATE.CUR_HIJ_DATE

```plsql
DECLARE
	HDATE DATE;
BEGIN
	HDATE := HIJDATE.CUR_HIJ_DATE;

	UPDATE IMPR_CNTRL_SUSPNS
      SET IMPR_CNTRL_SUSPNS.SUSPN_RLSE_DT = HDATE
	WHERE IMPR_CNTRL_SUSPNS.HQ_IMPR_NBR = :IMPR_CNTRL_SUSPNS.HQ_IMPR_NBR
	AND   IMPR_CNTRL_SUSPNS.SUSPN_SEQ   =:IMPR_CNTRL_SUSPNS.SUSPN_SEQ;

	--COMMIT ;



IF NOT ACTIVITY.ADD_ACTIVITY(9, 7, 3, :IMPR_CNTRL_SUSPNS.HQ_IMPR_NBR||'!'||
						  :IMPR_CNTRL_SUSPNS.SUSPN_SEQ) THEN
	RAISE FORm_Trigger_Failure;
END IF;


END;
```

#### IMPR_CNTRL_SUSPNS · POST-INSERT

- Level: Block · Owner: `IMPR_CNTRL_SUSPNS` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 57 total / 53 active (non-blank, non-comment)
- Built-ins: COMMIT (DB)
- Program units (form): –
- Library / DB package calls: GNRL.GET_CUSTOMS_SETTING, LIB_APX_USR.APEX_NOTIFICATIONS.SEND_SMS_EMAIL_NOTIFY, SMS_MESSAGE.SEND_SMS_MESSAGE

```plsql
DECLARE
V_MOBILE_NBR NUMBER;
V_SMS_MSG_BODY VARCHAR2(2000);
V_RV_MEANING VARCHAR2(200);
Var_Recipient_Type     NUMBER; -- CR-8414
Var_Note_Priority      VARCHAR2 (32767); -- CR-8414
Var_Status             NUMBER; -- CR-8414
Var_P_Message          VARCHAR2 (32767); -- CR-8414
V_Ne_In_Send      VARCHAR2 (4000);  --CR8414  NE_INTEGRATION
V_Bus_Id        VARCHAR2(15) ; -- CR-8414
V_Org_Hotline   NUMBER;                                     -- CR-8414
V_Org_Name      VARCHAR2 (500);  -- CR-8414
BEGIN
SELECT RV_MEANING INTO V_RV_MEANING FROM CG_REF_CODES
WHERE RV_DOMAIN = 'SUSPN SIDE CD' AND RV_LOW_VALUE = :SUSPN_SIDE_CD;
	-- CR-8414
   V_ORG_HOTLINE   := 19993;
  V_ORG_NAME      := 'https://zatca.gov.sa';
 IF NVL (gnrl.get_customs_setting (:PARAMETER.P_CURR_PORT_CD ,'NE_INTEGRATION', 21), 0)= 1    THEN   --CR-8414 5 accept message diffrent /*central by Nasser 29-06-2025*/

                        V_NE_IN_SEND :='P_RV_MEANING=' ||V_RV_MEANING
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
      TO_ID_NO           => NULL,
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

V_SMS_MSG_BODY:=' تم ايقاف مركزي من قبل '||V_RV_MEANING||' للسجل التجاري '||:BUS_ID||
' من تاريخ '||TO_CHAR(:SUSPN_STRT_DT,'MI-MM-YYYY')||' الى تاريخ '||TO_CHAR(:SUSPN_END_DT,'MI-MM-YYYY')||
' بسبب '||:SUSPN_RSN_TEXT;
SELECT MOBILE_NO INTO V_MOBILE_NBR FROM IMPORTER_BASIC_DATA
WHERE HQ_IMPR_NBR = :IMPR_CNTRL_SUSPNS.HQ_IMPR_NBR AND ROWNUM=1 AND MOBILE_NO IS NOT NULL;
SMS_MESSAGE.SEND_SMS_MESSAGE(9,2,1,:PARAMETER.P_CURR_PORT_CD,NULL,V_MOBILE_NBR,
V_SMS_MSG_BODY,:IMPR_CNTRL_SUSPNS.HQ_IMPR_NBR||'|'||:SUSPN_SEQ);
END IF;
STANDARD.COMMIT;
EXCEPTION WHEN OTHERS THEN NULL;
END;
```

#### IMPR_CNTRL_SUSPNS · PRE-INSERT

- Level: Block · Owner: `IMPR_CNTRL_SUSPNS` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 15 total / 9 active (non-blank, non-comment)
- Built-ins: RAISE FORM_TRIGGER_FAILURE
- Program units (form): –
- Library / DB package calls: ACTIVITY.ADD_ACTIVITY

```plsql
BEGIN

SELECT NVL(MAX(SUSPN_SEQ),0)+1
INTO :IMPR_CNTRL_SUSPNS.SUSPN_SEQ
FROM IMPR_CNTRL_SUSPNS;



IF NOT ACTIVITY.ADD_ACTIVITY(9, 7, 1, :IMPR_CNTRL_SUSPNS.HQ_IMPR_NBR||'!'||
						  :IMPR_CNTRL_SUSPNS.SUSPN_SEQ) THEN
	RAISE FORm_Trigger_Failure;
END IF;


END;
```

#### IMPR_CNTRL_SUSPNS · PRE-UPDATE

- Level: Block · Owner: `IMPR_CNTRL_SUSPNS` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 10 total / 6 active (non-blank, non-comment)
- Built-ins: RAISE FORM_TRIGGER_FAILURE
- Program units (form): –
- Library / DB package calls: ACTIVITY.ADD_ACTIVITY

```plsql
BEGIN


IF NOT ACTIVITY.ADD_ACTIVITY(9, 7, 2, :IMPR_CNTRL_SUSPNS.HQ_IMPR_NBR||'!'||
						  :IMPR_CNTRL_SUSPNS.SUSPN_SEQ) THEN
	RAISE FORm_Trigger_Failure;
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

#### HQ_IMPRS.BUS_ID · KEY-LISTVAL

- Level: Item · Owner: `HQ_IMPRS.BUS_ID` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 3 total / 3 active (non-blank, non-comment)
- Built-ins: –
- Program units (form): SINGLE_IMP_LOV
- Library / DB package calls: –

```plsql
BEGIN
	SINGLE_IMP_LOV;
END;
```

#### HQ_IMPRS.BUS_ID · WHEN-VALIDATE-ITEM

- Level: Item · Owner: `HQ_IMPRS.BUS_ID` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 23 total / 17 active (non-blank, non-comment)
- Built-ins: –
- Program units (form): SINGLE_IMP_LOV
- Library / DB package calls: STR.DISPALERT

```plsql
DECLARE
	V_HQ_IMP_NBR VARCHAR2(1000);
	V_COUNT NUMBER ;
BEGIN

IF :HQ_IMPRS.BUS_ID IS NOT NULL THEN

SELECT COUNT(*)
INTO V_COUNT
FROM HQ_IMPRS
WHERE BUS_ID = :HQ_IMPRS.BUS_ID ;

IF V_COUNT > 0 THEN

:GLOBAL.BUS_NBR := :HQ_IMPRS.BUS_ID ;

ELSE
	 STR.DISPALERT('رقم الاستدلالي للمستورد المدخل غير صحيح، أدخل الرقم الصحيح أو استخدم القائمة المرفقة','ERROR');
   SINGLE_IMP_LOV ;
END IF ;
END IF ;

END;
```

#### HQ_IMPRS.BUT_SH_HQNUM · WHEN-BUTTON-PRESSED

- Level: Item · Owner: `HQ_IMPRS.BUT_SH_HQNUM` · Execution hierarchy: default (Override)
- Lines: 7 total / 5 active (non-blank, non-comment)
- Built-ins: DO_KEY, GO_ITEM
- Program units (form): –
- Library / DB package calls: –

```plsql
/* CGAP$OLES_SEQUENCE_BEFORE */
NULL;

BEGIN
	GO_ITEM('BUS_ID');
	DO_KEY('LIST_VALUES');
END;
```

#### HQ_IMPRS.BUS_ID_TYPE_CD · KEY-LISTVAL

- Level: Item · Owner: `HQ_IMPRS.BUS_ID_TYPE_CD` · Execution hierarchy: default (Override)
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

#### HQ_IMPRS.BUS_ID_TYPE_NAME · KEY-LISTVAL

- Level: Item · Owner: `HQ_IMPRS.BUS_ID_TYPE_NAME` · Execution hierarchy: default (Override)
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

#### HQ_IMPRS.BUS_ID_BRNCH · KEY-LISTVAL

- Level: Item · Owner: `HQ_IMPRS.BUS_ID_BRNCH` · Execution hierarchy: default (Override)
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

#### HQ_IMPRS.HQ_IMPR_NBR · KEY-LISTVAL

- Level: Item · Owner: `HQ_IMPRS.HQ_IMPR_NBR` · Execution hierarchy: default (Override)
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

#### HQ_IMPRS.HQ_IMPR_NBR · WHEN-VALIDATE-ITEM

- Level: Item · Owner: `HQ_IMPRS.HQ_IMPR_NBR` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 24 total / 16 active (non-blank, non-comment)
- Built-ins: –
- Program units (form): SINGLE_IMP_LOV
- Library / DB package calls: STR.DISPALERT

```plsql
DECLARE
	V_COUNT NUMBER ;
BEGIN

IF :HQ_IMPRS.HQ_IMPR_NBR IS NOT NULL THEN

SELECT COUNT(*)
INTO V_COUNT
FROM HQ_IMPRS
WHERE HQ_IMPR_NBR = :HQ_IMPRS.HQ_IMPR_NBR;

IF V_COUNT > 0 THEN

:GLOBAL.HQ_IMPR_NBR  := :HQ_IMPRS.HQ_IMPR_NBR;

ELSE
   STR.DISPALERT('الرقم الموحد للمستورد المدخل غير صحيح، أدخل الرقم الصحيح أو استخدم القائمة المرفقة','ERROR');
   SINGLE_IMP_LOV ;
END IF ;
END IF ;

END;
/* CGUV$CHK_KEYS_ON_VAL_FLD_MODIFIED */
/* Check item value against unique or primary key */
```

#### HQ_IMPRS.CITY_CODE_OF_ID · KEY-LISTVAL

- Level: Item · Owner: `HQ_IMPRS.CITY_CODE_OF_ID` · Execution hierarchy: default (Override)
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

#### HQ_IMPRS.CITY_CODE_OF_NAME · KEY-LISTVAL

- Level: Item · Owner: `HQ_IMPRS.CITY_CODE_OF_NAME` · Execution hierarchy: default (Override)
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

#### HQ_IMPRS.IMPR_TYPE_CD · KEY-LISTVAL

- Level: Item · Owner: `HQ_IMPRS.IMPR_TYPE_CD` · Execution hierarchy: default (Override)
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

#### HQ_IMPRS.IMPR_TYPE_NAME · KEY-LISTVAL

- Level: Item · Owner: `HQ_IMPRS.IMPR_TYPE_NAME` · Execution hierarchy: default (Override)
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

#### HQ_IMPRS.CTRY_CD · KEY-LISTVAL

- Level: Item · Owner: `HQ_IMPRS.CTRY_CD` · Execution hierarchy: default (Override)
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

#### HQ_IMPRS.CRTY_ARBC_NAME · KEY-LISTVAL

- Level: Item · Owner: `HQ_IMPRS.CRTY_ARBC_NAME` · Execution hierarchy: default (Override)
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

#### HQ_IMPRS.ARBC_IMPR_NAME · KEY-LISTVAL

- Level: Item · Owner: `HQ_IMPRS.ARBC_IMPR_NAME` · Execution hierarchy: default (Override)
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

#### HQ_IMPRS.ENG_IMPR_NAME · KEY-LISTVAL

- Level: Item · Owner: `HQ_IMPRS.ENG_IMPR_NAME` · Execution hierarchy: default (Override)
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

#### IMPR_CNTRL_SUSPNS.SUSPN_STRT_DT · KEY-LISTVAL

- Level: Item · Owner: `IMPR_CNTRL_SUSPNS.SUSPN_STRT_DT` · Execution hierarchy: default (Override)
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

#### IMPR_CNTRL_SUSPNS.SUSPN_STRT_DT · KEY-F4

- Level: Item · Owner: `IMPR_CNTRL_SUSPNS.SUSPN_STRT_DT` · Execution hierarchy: default (Override)
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

#### IMPR_CNTRL_SUSPNS.SUSPN_STRT_DT · WHEN-VALIDATE-ITEM

- Level: Item · Owner: `IMPR_CNTRL_SUSPNS.SUSPN_STRT_DT` · Execution hierarchy: default (Override)
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

#### IMPR_CNTRL_SUSPNS.SUSPN_END_DT · KEY-LISTVAL

- Level: Item · Owner: `IMPR_CNTRL_SUSPNS.SUSPN_END_DT` · Execution hierarchy: default (Override)
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

#### IMPR_CNTRL_SUSPNS.SUSPN_END_DT · KEY-F4

- Level: Item · Owner: `IMPR_CNTRL_SUSPNS.SUSPN_END_DT` · Execution hierarchy: default (Override)
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

#### IMPR_CNTRL_SUSPNS.SUSPN_END_DT · WHEN-VALIDATE-ITEM

- Level: Item · Owner: `IMPR_CNTRL_SUSPNS.SUSPN_END_DT` · Execution hierarchy: default (Override)
- Lines: 27 total / 18 active (non-blank, non-comment)
- Built-ins: RAISE FORM_TRIGGER_FAILURE
- Program units (form): –
- Library / DB package calls: HIJDATE.VALID_HIJ_DATE, STR.DISPALERT

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

BEGIN


IF :SUSPN_END_DT < :SUSPN_STRT_DT THEN

	STR.DISPALERT(' لا يمكن ان يكون تاريخ نهاية الأيقاف أصغر من تاريخ بداية الأيقاف', 'ERROR');
	RAISE FORM_TRIGGER_FAILURE;
END IF;



END;
```

#### IMPR_CNTRL_SUSPNS.SUSPN_SEQ · KEY-LISTVAL

- Level: Item · Owner: `IMPR_CNTRL_SUSPNS.SUSPN_SEQ` · Execution hierarchy: default (Override)
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

#### IMPR_CNTRL_SUSPNS.SUSPN_RSN_TEXT · KEY-LISTVAL

- Level: Item · Owner: `IMPR_CNTRL_SUSPNS.SUSPN_RSN_TEXT` · Execution hierarchy: default (Override)
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
| CGFK$HQ_IMPRS_BUS_ID_TYPE_CD | Valid values for نوعه | CGFK$HQ_IMPRS_BUS_ID_TYPE_CD | BUS_ID_TYPE_CD → HQ_IMPRS.BUS_ID_TYPE_CD | HQ_IMPRS.BUS_ID_TYPE_CD | not in XML (item property `ValidateFromList` absent → default/OLB) | default/OLB |

### 7.1 Record groups

#### CGFK$HQ_IMPRS_BUS_ID_TYPE_CD
- Type: Query · Attached to LOV: yes
- Columns: BUS_ID_TYPE_CD Number(3)

```sql
SELECT BUS_ID_TYPE_CD  BUS_ID_TYPE_CD  /* CG$FK */
FROM   BUS_ID_TYPES
```


> **LOV notes**
> - `CGFK$HQ_IMPRS_BUS_ID_TYPE_CD` (all `BUS_ID_TYPES`) is attached to `BUS_ID_TYPE_CD`, which is display only: it cannot be used. Not migrated as an LOV; the type name is a lookup in the master region SQL.
> - Importer selection: `BUS_ID.KEY-LISTVAL`, `BUT_SH_HQNUM` and the two "number not found" paths call PU `SINGLE_IMP_LOV` → LOV form **`LOV_IMPORT_HQ_NBR`** (block `SING_IMP` on `SINGLE_IMPORTERS`: Arabic name, `HQ_IMPR_NBR`, `BUS_ID`, `BUS_ID_BRNCH`; no WHERE unless `P_GNRL_AUDIT = 1`, which this form does not pass). It returns `HQ_IMPR_NBR`, `ARBC_IMPR_NAME`, `BUS_ID` through `:GLOBAL.*`. In APEX this becomes the search page `112501` (filters on the same columns, returns `HQ_IMPR_NBR`).
> - Deleted suspensions: PU `DELETE_SUSPS_LOV` → LOV form **`LOV_DELETE_IMP_SUSP`** (block on `IMPR_CNTRL_SUSPNS` WHERE `SUSPN_RLSE_DT IS NOT NULL AND HQ_IMPR_NBR = :PARAMETER.P_HQ_IMPR_NBR`; columns start / end / release date, side, reason, notes). It returns nothing (display only). In APEX: a read-only report in a modal dialog page `112502`.
> - Runtime record group `CGDV$DLRG` fills 3 list items from `CG_REF_CODES` → shared LOVs through `LOV_APX` (CG_REF_CODES domains `ALLOWED EXPORT`, `IMPR_SUSPN_RSN_CD`, `SUSPN SIDE CD`), the same domains as IMPR1120.

## 8. Canvases & Windows

| Canvas | Type | Window | Size (W×H) | Viewport | Tab pages | Items shown | Subclassed from |
|---|---|---|---|---|---|---|---|
| LSIDE | Content (default) / OLB | default/OLB | – | – | – | 0: – | CIC_OLB.olb:LSIDE |
| EDI_MSG | Content (default) / OLB | default/OLB | – | – | – | 0: – | CIC_OLB.olb:EDI_MSG |
| TITLE | Content (default) / OLB | default/OLB | – | – | – | 0: – | CIC_OLB.olb:TITLE |
| TOOLBAR | Content (default) / OLB | default/OLB | – | – | – | 0: – | CIC_OLB.olb:TOOLBAR |
| CG$PAGE_1 | Content (default) / OLB | CGSO$WINDOW_1 | – | 0×5600 | – | 19: BUS_ID, BUT_SH_HQNUM, BUS_ID_TYPE_CD, BUS_ID_TYPE_NAME, BUS_ID_BRNCH, HQ_IMPR_NBR, CITY_CODE_OF_ID, CITY_CODE_OF_NAME, IMPR_TYPE_CD, IMPR_TYPE_NAME, IMPR_EXPR_TYPE, CTRY_CD, CRTY_ARBC_NAME, ARBC_IMPR_NAME, ENG_IMPR_NAME, SUSPN_STRT_DT, SUSPN_END_DT, SUSPN_RSN_TEXT, SUSPN_SIDE_CD | cic_olb.olb:CGSO$CANVAS |

| Window | Modal | Title | Size | Subclassed from |
|---|---|---|---|---|
| CGSO$WINDOW_1 | default/OLB | صيانة توقيفات المستوردين | default/OLB | cic_olb.olb:CGSO$WINDOW_1 |

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
> - `LSIDE`, `EDI_MSG`, `TITLE`, `TOOLBAR` and window `CGSO$WINDOW_1` (title "صيانة توقيفات المستوردين") come from `CIC_OLB.olb`: the screen frame, not migrated.
> - One content canvas `CG$PAGE_1` (no tab pages) holds the importer header (15 items) and the suspension grid (4 visible columns × 9 rows: start, end, notes, side). In APEX: one main page with a Form region `HQ_IMPRS` and an IG `IMPR_CNTRL_SUSPNS`.

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
| 17 | CGUV$CHK_HI_PK | Procedure | 23 / 20 | not referenced in XML code | – | – | CG$DUMMY |
| 18 | CGFK$CHK_IMPR_CNTRL_SUSPNS_ICS | Procedure | 22 / 20 | not referenced in XML code | – | – | CG$DUMMY |
| 19 | CGTE$CHECK_CONSTRAINT_VIO | Function | 39 / 31 | HQ_IMPRS.ON-ERROR, IMPR_CNTRL_SUSPNS.ON-ERROR | – | – | CGTE$STRIP_CONSTRAINT, CGTE$STRIP_FIRST_ERROR, DES$FORM_ERRORS.MSGGETTEXT, DES$FORM_ERRORS.PUSH |
| 20 | CGBS$TOGGLE | Procedure | 24 / 15 | FORM.KEY-MENU | – | CGBS$MESSAGE_QUERY_MODE, CGBS$SET_QUERY_MODE | CGBS$.COORD_VISIBLE_BLKS, CGBS$.SET_RELATIONS |
| 21 | CGBS$SET_QUERY_MODE | Procedure | 7 / 5 | PU CG$WHEN_NEW_FORM_INSTANCE, PU CGBS$TOGGLE | – | – | – |
| 22 | CGBS$MESSAGE_QUERY_MODE | Procedure | 11 / 9 | PU CGBS$TOGGLE | – | – | DES$FORM_ERRORS.PUSH |
| 23 | SINGLE_IMP_LOV | Procedure | 46 / 27 | HQ_IMPRS.BUS_ID.KEY-LISTVAL, HQ_IMPRS.BUS_ID.WHEN-VALIDATE-ITEM, HQ_IMPRS.HQ_IMPR_NBR.WHEN-VALIDATE-ITEM | ADD_PARAMETER, CALL_FORM, CREATE_PARAMETER_LIST, DESTROY_PARAMETER_LIST, GET_PARAMETER_LIST, ID_NULL, RAISE FORM_TRIGGER_FAILURE | – | STR.DISPALERT |
| 24 | EXEC_FUNS | Procedure | 4 / 4 | PU EXECUTE_FUNCTION | – | – | – |
| 25 | DELETE_SUSPS_LOV | Procedure | 36 / 25 | HQ_IMPRS.POST-QUERY | ADD_PARAMETER, CALL_FORM, CREATE_PARAMETER_LIST, DESTROY_PARAMETER_LIST, GET_PARAMETER_LIST, ID_NULL, RAISE FORM_TRIGGER_FAILURE | – | STR.DISPALERT |
| 26 | ADJ_FUNS | Procedure | 4 / 4 | FORM.KEY-F9, TOOLBAR.FUN_BUT.WHEN-MOUSE-DOWN | – | – | – |

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
  populate_list('HQ_IMPRS.IMPR_EXPR_TYPE', rg_id);
  delete_group(rg_id);

  rg_id := create_group_from_query('CGDV$DLRG',
    'SELECT RV_MEANING, RV_LOW_VALUE '||
    'FROM   CG_REF_CODES '||
    'WHERE  RV_DOMAIN = ''IMPR_SUSPN_RSN_CD'' '||
    'ORDER BY  2');
  temp := populate_group(rg_id);
  populate_list('IMPR_CNTRL_SUSPNS.SUSPN_RSN_CD', rg_id);
  delete_group(rg_id);

  rg_id := create_group_from_query('CGDV$DLRG',
    'SELECT RV_MEANING, RV_LOW_VALUE '||
    'FROM   CG_REF_CODES '||
    'WHERE  RV_DOMAIN = ''SUSPN SIDE CD'' '||
    'ORDER BY  2');
  temp := populate_group(rg_id);
  populate_list('IMPR_CNTRL_SUSPNS.SUSPN_SIDE_CD', rg_id);
  delete_group(rg_id);

END;
```

### PU CGUV$CHK_HI_PK (Procedure, 23 lines)

```plsql
/* CGUV$CHK_HI_PK */
PROCEDURE CGUV$CHK_HI_PK(
   P_HQ_IMPR_NBR IN NUMBER) IS  /* Item value */
/* Check uniqueness against primary/unique constraint        */
/* Note : NO_DATA_FOUND exception handled by calling trigger */
  CG$DUMMY VARCHAR2(1);
BEGIN
    DECLARE
      CURSOR C IS
        SELECT  '1'
        FROM    HQ_IMPRS
        WHERE   HQ_IMPR_NBR = P_HQ_IMPR_NBR;
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

### PU CGFK$CHK_IMPR_CNTRL_SUSPNS_ICS (Procedure, 22 lines)

```plsql
/* CGFK$CHK_IMPR_CNTRL_SUSPNS_ICS */
PROCEDURE CGFK$CHK_IMPR_CNTRL_SUSPNS_ICS(
   P_HQ_IMPR_NBR IN NUMBER) IS  /* Value in Item :IMPR_CNTRL_SUSPNS.HQ_IMPR_NBR. */
/* Validate foreign key value/query lookup data. */
  CG$DUMMY VARCHAR2(1);
BEGIN
  DECLARE
    CURSOR C IS
      SELECT  '1'
      FROM   HQ_IMPRS
      WHERE  HQ_IMPR_NBR = P_HQ_IMPR_NBR;
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

### PU CGTE$CHECK_CONSTRAINT_VIO (Function, 39 lines)

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
    IF (constraint_name = 'HI_PK') THEN
      Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(6, 'Row exists already with same <p1>', 'الــرقــــم الــمــوحـد' ), 'E', 'OFG', 6);
    ELSIF (constraint_name = 'HI_BUSID_UK') THEN
      Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(6, 'Row exists already with same <p1>', 'BUS_ID_TYPE_CD,BUS_ID,BUS_ID_BRNCH' ), 'E', 'OFG', 6);
    ELSIF (constraint_name = 'ICRLS_PK') THEN
      Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(6, 'Row exists already with same <p1>', 'رقم المستورد الموحد,مسلسل التوقيف' ), 'E', 'OFG', 6);
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

### PU SINGLE_IMP_LOV (Procedure, 46 lines)

```plsql
PROCEDURE SINGLE_IMP_LOV IS
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

   Add_Parameter(pl_id, 'WINDOW_TITLE', TEXT_PARAMETER, 'قائمة المستوردين');
   CALL_FORM('LOV_IMPORT_HQ_NBR.fmx',
              no_hide,
              no_replace,
              no_query_only,
              pl_id);

 	IF  :GLOBAL.HQ_IMPR_NBR IS NOT NULL THEN
		:BUS_ID := :GLOBAL.BUS_ID;
/*
CLEAR_BLOCK(NO_VALIDATE);
GO_BLOCK('HQ_IMPRS');
EXECUTE_QUERY;

:GLOBAL.HQ_IMPR_NBR := NULL  ;
:GLOBAL.BUS_NBR := NULL  ;
*/

		--execute_query;
	END IF;



    Destroy_Parameter_List(pl_id);


 	ELSE
     ret := Str.DispAlert('Parameter list '||pl_name||' already EXISTS!','INFORMATION');
     RAISE Form_Trigger_Failure;
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

### PU DELETE_SUSPS_LOV (Procedure, 36 lines)

```plsql
PROCEDURE DELETE_SUSPS_LOV IS

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
--P_HQ_IMPR_NBR

   Add_Parameter(pl_id, 'WINDOW_TITLE', TEXT_PARAMETER, 'قائمة الأيقافات المحذوفة');
Add_Parameter(pl_id, 'P_HQ_IMPR_NBR', TEXT_PARAMETER, :HQ_IMPRS.HQ_IMPR_NBR);

   CALL_FORM('LOV_DELETE_IMP_SUSP.fmx',
              no_hide,
              no_replace,
              no_query_only,
              pl_id);



    Destroy_Parameter_List(pl_id);


 	ELSE
     ret := Str.DispAlert('Parameter list '||pl_name||' already EXISTS!','INFORMATION');
     RAISE Form_Trigger_Failure;
   END IF;
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
| ACTIVITY.ADD_ACTIVITY | 3 | IMPR_CNTRL_SUSPNS.ON-DELETE, IMPR_CNTRL_SUSPNS.PRE-INSERT, IMPR_CNTRL_SUSPNS.PRE-UPDATE |
| ADJ_PRN.ADJ_REPORT_PRINTER | 1 | PU EXECUTE_FUNCTION |
| CG$DUMMY | 2 | PU CGFK$CHK_IMPR_CNTRL_SUSPNS_ICS, PU CGUV$CHK_HI_PK |
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
| CGHP$CALL_MS_HELP | 3 | FORM.KEY-HELP, HQ_IMPRS.KEY-HELP, IMPR_CNTRL_SUSPNS.KEY-HELP |
| CGHP$PRE_FORM | 1 | FORM.PRE-FORM |
| CGTE$OTHER_EXCEPTIONS | 6 | FORM.KEY-CLRFRM, FORM.KEY-HELP, FORM.WHEN-NEW-FORM-INSTANCE, HQ_IMPRS.KEY-HELP, IMPR_CNTRL_SUSPNS.KEY-HELP, PU CG$WHEN_NEW_FORM_INSTANCE |
| CGTE$POP_ERROR_STACK | 2 | HQ_IMPRS.ON-ERROR, IMPR_CNTRL_SUSPNS.ON-ERROR |
| CGTE$STRIP_CONSTRAINT | 3 | HQ_IMPRS.ON-ERROR, IMPR_CNTRL_SUSPNS.ON-ERROR, PU CGTE$CHECK_CONSTRAINT_VIO |
| CGTE$STRIP_FIRST_ERROR | 1 | PU CGTE$CHECK_CONSTRAINT_VIO |
| DES$FORM_ERRORS.MSGGETTEXT | 7 | FORM.KEY-CQUERY, FORM.KEY-HELP, FORM.KEY-NXTKEY, HQ_IMPRS.KEY-HELP, IMPR_CNTRL_SUSPNS.KEY-HELP, IMPR_CNTRL_SUSPNS.ON-ERROR, PU CGTE$CHECK_CONSTRAINT_VIO |
| DES$FORM_ERRORS.PUSH | 9 | FORM.KEY-CQUERY, FORM.KEY-HELP, FORM.KEY-NXTKEY, HQ_IMPRS.KEY-HELP, HQ_IMPRS.ON-ERROR, IMPR_CNTRL_SUSPNS.KEY-HELP, IMPR_CNTRL_SUSPNS.ON-ERROR, PU CGBS$MESSAGE_QUERY_MODE … (+1) |
| DES$FORM_ERRORS.RAISE_FAILURE | 4 | FORM.KEY-CQUERY, FORM.KEY-NXTKEY, HQ_IMPRS.ON-ERROR, IMPR_CNTRL_SUSPNS.ON-ERROR |
| GNRL.GET_CUSTOMS_SETTING | 1 | IMPR_CNTRL_SUSPNS.POST-INSERT |
| HIJDATE.CUR_HIJ_DATE | 4 | IMPR_CNTRL_SUSPNS.ON-DELETE, TOOLBAR.EXIT1.WHEN-BUTTON-PRESSED, TOOLBAR.RE_ENTER_QUERY.WHEN-BUTTON-PRESSED, TOOLBAR.SAVE.WHEN-BUTTON-PRESSED |
| HIJDATE.VALID_HIJ_DATE | 3 | IMPR_CNTRL_SUSPNS.SUSPN_END_DT.WHEN-VALIDATE-ITEM, IMPR_CNTRL_SUSPNS.SUSPN_STRT_DT.WHEN-VALIDATE-ITEM, TITLE.SYSTEM_DATE.WHEN-VALIDATE-ITEM |
| INTRFACE.DISP_CALENDAR | 2 | IMPR_CNTRL_SUSPNS.SUSPN_END_DT.KEY-LISTVAL, IMPR_CNTRL_SUSPNS.SUSPN_STRT_DT.KEY-LISTVAL |
| INTRFACE.DISP_DATE_CON | 2 | IMPR_CNTRL_SUSPNS.SUSPN_END_DT.KEY-F4, IMPR_CNTRL_SUSPNS.SUSPN_STRT_DT.KEY-F4 |
| KEY_CONTROL.FOUND_KEY | 1 | TOOLBAR.EXIT1.WHEN-BUTTON-PRESSED |
| LIB_APX_USR.APEX_NOTIFICATIONS.SEND_SMS_EMAIL_NOTIFY | 1 | IMPR_CNTRL_SUSPNS.POST-INSERT |
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
| SMS_MESSAGE.SEND_SMS_MESSAGE | 1 | IMPR_CNTRL_SUSPNS.POST-INSERT |
| STR.DISPALERT | 8 | HQ_IMPRS.BUS_ID.WHEN-VALIDATE-ITEM, HQ_IMPRS.HQ_IMPR_NBR.WHEN-VALIDATE-ITEM, HQ_IMPRS.POST-QUERY, IMPR_CNTRL_SUSPNS.SUSPN_END_DT.WHEN-VALIDATE-ITEM, PU DELETE_SUSPS_LOV, PU EXECUTE_FUNCTION, PU SINGLE_IMP_LOV, TOOLBAR.EXIT.WHEN-BUTTON-PRESSED |
| TMPLT.ENB_DIS_FUN_BUT | 1 | TOOLBAR.EXIT1.WHEN-BUTTON-PRESSED |
| TMPLT.FUN_ITEMS | 1 | PU EXECUTE_FUNCTION |
| TMPLT.KEYB_UP_DOWN | 3 | FORM.KEY-F9, TOOLBAR.KEY-DOWN, TOOLBAR.KEY-UP |
| TMPLT.KEY_DELETE_RECORD | 1 | IMPR_CNTRL_SUSPNS.KEY-DELREC |
| TMPLT.POPULATE_FUNCTIONS | 2 | FORM.KEY-F9, TOOLBAR.FUN_BUT.WHEN-MOUSE-UP |

### 10.3 Classification of package-qualified calls (library vs database)

> The library texts in `forms/COMMON/libraries/` were searched for every package the form calls (same result as IMPR1120 §10.3).

| Package / prefix | Origin | Library file / source | Used for (active calls in IMPR1125) |
|---|---|---|---|
| `NIB.*` | Forms library | `CIC_LIB.pld` | form startup, ON-ERROR / ON-MESSAGE, timers, KEY-* handlers, window handling |
| `STR.*` | Forms library | `CIC_LIB.pld` (→ DB `STR_DB`, **MISSING SOURCE**) | `DispAlert` only (8 callers, literal texts); no `DispArbMsg`, no `StrFormat` |
| `INTRFACE.*` | Forms library | `CIC_LIB.pld` | `DISP_CALENDAR` (2) and `DISP_DATE_CON` (2) on the date items |
| `TMPLT.*` | Forms library | `CIC_LIB.pld` | `KEY_DELETE_RECORD` (IMPR_CNTRL_SUSPNS.KEY-DELREC), `POPULATE_FUNCTIONS`, `KEYB_UP_DOWN`, `ENB_DIS_FUN_BUT`, `FUN_ITEMS` |
| `HIJDATE.*` | Forms library → DB | `CIC_LIB.pld` → `HIJDATE_DB` (`plsql/Shared/HIJDATE_DB.*`) | `CUR_HIJ_DATE` (ON-DELETE, toolbar), `VALID_HIJ_DATE` (2 date items) |
| `ACTIVITY.*` | Forms library → DB | `CIC_LIB.pld` → `ACTIVITY_DB` (`plsql/Shared/ACTIVITY_DB.*`) | `ADD_ACTIVITY(9, 7, 1 / 2 / 3, hq_impr_nbr!seq)` on insert / update / delete of a central suspension |
| `KEY_CONTROL.*` | Forms library | `CIC_LIB.pld` | `FOUND_KEY` (TOOLBAR.EXIT1) |
| `REP.*`, `ADJ_PRN.*` | Forms library | `CIC_LIB.pld` | `RUN_PRODUCT` / `ADJ_REPORT_PRINTER` in PU EXECUTE_FUNCTION (function menu) |
| `CGBS$.*`, `CGBS2$.*` | Designer block-synchronisation library | `OFGBSL.pld` | master-detail coordination and commit dialogue |
| `DES$FORM_ERRORS` | Designer message library | `CIC_AMSG.pld` | error stack / messages |
| `CGTE$*` | Designer table-error library | `OFGTEL`: **MISSING SOURCE** | constraint-violation text in the two block ON-ERROR triggers |
| `CGHP$*` | Designer help library | `OFGHPL.pld` | MS-Help (obsolete) |
| `GNRL` | Database package | **MISSING SOURCE** | `GET_CUSTOMS_SETTING(port, 'NE_INTEGRATION', 21)`: chooses the notification channel |
| `LIB_APX_USR.APEX_NOTIFICATIONS` | Database package | **MISSING SOURCE** | `SEND_SMS_EMAIL_NOTIFY(..., EVENT_CODE => 'IMPR_010', ...)` (CR-8414) |
| `SMS_MESSAGE` | Database package | **MISSING SOURCE** | `SEND_SMS_MESSAGE(9, 2, 1, port, NULL, mobile, body, hq!seq)`: older SMS path |

### 10.4 Called forms

| Caller | Built-in | Arguments (verbatim) | ADD_PARAMETER calls in the same unit (name, type, value) |
|---|---|---|---|
| PU EXECUTE_FUNCTION | CALL_FORM | `V_CALLED_FORM, no_hide, no_replace, no_query_only, pl_id` | P_USER_ID TEXT_PARAMETER = :PARAMETER.P_USER_ID; P_USER_NAME TEXT_PARAMETER = :PARAMETER.P_USER_NAME; P_WS_ID TEXT_PARAMETER = :PARAMETER.P_WS_ID; P_CURR_PORT_CD TEXT_PARAMETER = :PARAMETER.P_CURR_PORT_CD; P_PORT_TYPE TEXT_PARAMETER = :PARAMETER.P_PORT_TYPE; P_GROUP_CD TEXT_PARAMETER = :PARAMETER.P_GROUP_CD; P_USER_TYPE TEXT_PARAMETER = :PARAMETER.P_USER_TYPE; P_JOB_ID TEXT_PARAMETER = :PARAMETER.P_JOB_ID; P_CLASS_CD TEXT_PARAMETER = :PARAMETER.P_CLASS_CD; P_MODULE_ID TEXT_PARAMETER = TMPLT.FUN_ITEMS(ROW_COUNT).MID; P_MODULE_NAME TEXT_PARAMETER = V_MOD_NAME; P_BRKR_PORT_CD TEXT_PARAMETER = :PARAMETER.P_BRKR_PORT_CD; P_SHPG_AGNT_NBR TEXT_PARAMETER = :PARAMETER.P_SHPG_AGNT_NBR; P_BRKR_NBR TEXT_PARAMETER = :PARAMETER.P_BRKR_NBR; P_LIC_TYPE TEXT_PARAMETER = :PARAMETER.P_LIC_TYPE; P_BANK_CD TEXT_PARAMETER = :PARAMETER.P_BANK_CD; P_BANK_BRNCH_CD TEXT_PARAMETER = :PARAMETER.P_BANK_BRNCH_CD; P_SYS_ID TEXT_PARAMETER = :GLOBAL.SYSTEM_OBJ; P_REP_NO TEXT_PARAMETER = V_SEQ_NO; P_REPORT_NO TEXT_PARAMETER = :GLOBAL.SYSTEM_OBJ \|\|'-'\|\|V_SEQ_NO; DESTYPE TEXT_PARAMETER = 'PRINTER'; PARAMFORM TEXT_PARAMETER = 'NO'; ORACLE_SHUTDOWN TEXT_PARAMETER = 'YES'; MAXIMIZE TEXT_PARAMETER = 'YES' |
| PU EXECUTE_FUNCTION | CALL_FORM | `V_CALLED_FORM, no_hide, no_replace, no_query_only, pl_id` | P_USER_ID TEXT_PARAMETER = :PARAMETER.P_USER_ID; P_USER_NAME TEXT_PARAMETER = :PARAMETER.P_USER_NAME; P_WS_ID TEXT_PARAMETER = :PARAMETER.P_WS_ID; P_CURR_PORT_CD TEXT_PARAMETER = :PARAMETER.P_CURR_PORT_CD; P_PORT_TYPE TEXT_PARAMETER = :PARAMETER.P_PORT_TYPE; P_GROUP_CD TEXT_PARAMETER = :PARAMETER.P_GROUP_CD; P_USER_TYPE TEXT_PARAMETER = :PARAMETER.P_USER_TYPE; P_JOB_ID TEXT_PARAMETER = :PARAMETER.P_JOB_ID; P_CLASS_CD TEXT_PARAMETER = :PARAMETER.P_CLASS_CD; P_MODULE_ID TEXT_PARAMETER = TMPLT.FUN_ITEMS(ROW_COUNT).MID; P_MODULE_NAME TEXT_PARAMETER = V_MOD_NAME; P_BRKR_PORT_CD TEXT_PARAMETER = :PARAMETER.P_BRKR_PORT_CD; P_SHPG_AGNT_NBR TEXT_PARAMETER = :PARAMETER.P_SHPG_AGNT_NBR; P_BRKR_NBR TEXT_PARAMETER = :PARAMETER.P_BRKR_NBR; P_LIC_TYPE TEXT_PARAMETER = :PARAMETER.P_LIC_TYPE; P_BANK_CD TEXT_PARAMETER = :PARAMETER.P_BANK_CD; P_BANK_BRNCH_CD TEXT_PARAMETER = :PARAMETER.P_BANK_BRNCH_CD; P_SYS_ID TEXT_PARAMETER = :GLOBAL.SYSTEM_OBJ; P_REP_NO TEXT_PARAMETER = V_SEQ_NO; P_REPORT_NO TEXT_PARAMETER = :GLOBAL.SYSTEM_OBJ \|\|'-'\|\|V_SEQ_NO; DESTYPE TEXT_PARAMETER = 'PRINTER'; PARAMFORM TEXT_PARAMETER = 'NO'; ORACLE_SHUTDOWN TEXT_PARAMETER = 'YES'; MAXIMIZE TEXT_PARAMETER = 'YES' |
| PU SINGLE_IMP_LOV | CALL_FORM | `'LOV_IMPORT_HQ_NBR.fmx', no_hide, no_replace, no_query_only, pl_id` | WINDOW_TITLE TEXT_PARAMETER = 'قائمة المستوردين' |
| PU DELETE_SUSPS_LOV | CALL_FORM | `'LOV_DELETE_IMP_SUSP.fmx', no_hide, no_replace, no_query_only, pl_id` | WINDOW_TITLE TEXT_PARAMETER = 'قائمة الأيقافات المحذوفة'; P_HQ_IMPR_NBR TEXT_PARAMETER = :HQ_IMPRS.HQ_IMPR_NBR |

### 10.5 Database tables / views referenced in SQL (11)

Extracted from active (non-comment) code. Record-group queries are listed in section 7.

| Object | DML used | Referenced in |
|---|---|---|
| BUS_ID_TYPES | SELECT | HQ_IMPRS.POST-QUERY |
| CG_REF_CODES | SELECT | IMPR_CNTRL_SUSPNS.POST-INSERT |
| CITIES | SELECT | HQ_IMPRS.POST-QUERY |
| COUNTRIES | SELECT | HQ_IMPRS.POST-QUERY |
| HQ_IMPRS | SELECT | HQ_IMPRS.BUS_ID.WHEN-VALIDATE-ITEM, HQ_IMPRS.HQ_IMPR_NBR.WHEN-VALIDATE-ITEM, PU CGFK$CHK_IMPR_CNTRL_SUSPNS_ICS, PU CGUV$CHK_HI_PK |
| IMPORTER_BASIC_DATA | SELECT | IMPR_CNTRL_SUSPNS.POST-INSERT |
| IMPR_CNTRL_SUSPNS | SELECT, UPDATE | HQ_IMPRS.POST-QUERY, IMPR_CNTRL_SUSPNS.ON-DELETE, IMPR_CNTRL_SUSPNS.PRE-INSERT |
| IMPR_TYPES | SELECT | HQ_IMPRS.POST-QUERY |
| SC_PORT_SETTING | SELECT | PU EXECUTE_FUNCTION |
| SC_SYSTEM_OBJECTS | SELECT | PU EXECUTE_FUNCTION |
| SINGLE_IMPORTERS | SELECT | HQ_IMPRS.POST-QUERY |

### 10.6 Reports, HOST, notifications, file and OS access

| Feature | Location | Active? | Notes |
|---|---|---|---|
| SMS / e-mail notification | IMPR_CNTRL_SUSPNS.POST-INSERT | yes | Reads the side meaning (`CG_REF_CODES`, domain `SUSPN SIDE CD`). If `GNRL.GET_CUSTOMS_SETTING(P_CURR_PORT_CD, 'NE_INTEGRATION', 21) = 1` → `LIB_APX_USR.APEX_NOTIFICATIONS.SEND_SMS_EMAIL_NOTIFY` (event `IMPR_010`, variables `P_RV_MEANING`, `P_BUS_ID`, `P_SUSPN_STRT_DT`, `P_SUSPN_END_DT`, `P_SUSPN_RSN_TEXT`, `ORG_HOTLINE=19993`, `ORG_NAME=https://zatca.gov.sa`) **with `TO_MOBILE_NO => V_MOBILE_NBR`, which is still NULL in this branch** (the mobile is only read in the ELSE branch, §15 #4); otherwise `SMS_MESSAGE.SEND_SMS_MESSAGE(9, 2, 1, …)` with the Arabic text "تم ايقاف مركزي من قبل …" and the mobile from `IMPORTER_BASIC_DATA.MOBILE_NO` by `HQ_IMPR_NBR`. Followed by `STANDARD.COMMIT`; `WHEN OTHERS THEN NULL` hides every error |
| `REP.RUN_PRODUCT` (BATCH / RUNTIME) ×2 | PU EXECUTE_FUNCTION | only if the module has report functions in `SC_SYSTEM_OBJECTS` | same generic code as IMPR1110; `ADJ_FUNS` / `EXEC_FUNS` are empty |
| LOV forms | `LOV_IMPORT_HQ_NBR`, `LOV_DELETE_IMP_SUSP` (CALL_FORM) | yes | search page / deleted-suspensions dialog |
| Calendar / date-conversion forms | `INTRFACE.DISP_CALENDAR` / `DISP_DATE_CON` | yes | replaced by the APEX date item |
| `TEXT_IO` | PU CHECK_TIMEOUT | no: the PU is not called | session timeout |
| `CREATE_TIMER` / WHEN-TIMER-EXPIRED | `NIB.WHEN_NEW_FORM_INSTANCE` / `NIB.WHEN_TIMER_EXPIRED` | yes, via the library | EDI ticker + session timeout |
| `FORMS_DDL` | PRE-FORM (`ALTER SESSION SET NLS_DATE_FORMAT`) | yes | |
| DB COMMIT | IMPR_CNTRL_SUSPNS.POST-INSERT (`STANDARD.COMMIT`), `TMPLT.KEY_DELETE_RECORD`, TOOLBAR.SAVE | yes | |
| HOST, WEB.SHOW_DOCUMENT, OLE2, Java bean / PJC, CLIENT_*, EXEC_SQL, ON-LOCK | – | **not found** | |
| Sequences | none: `SUSPN_SEQ` = `MAX(SUSPN_SEQ) + 1` from `IMPR_CNTRL_SUSPNS` (whole table) in PRE-INSERT | yes | |
| DB links | – | not found | |

### 10.7 Object library / subclassed objects

- Object library: **`CIC_OLB.olb`**, available as `forms/COMMON/olb/CIC_OLB_OLB.xml`.
- 143 subclassed objects (51 visual attributes, items, triggers, 20 module parameters, 9 alerts, 6 blocks, 5 canvases, 1 window). The item classes decide which items are enterable (`CGSO$CHAR_ARB_DO`, `CGSO$COMBO_DO`: `Enabled=false`).
- The frame blocks are replaced by the f345 page template, page 0 toolbar and FUNCS drawer (same as IMPR1110 §10.7).

### 10.8 What the library calls used here do, and their APEX equivalent (f345 standard)

| Library call | What it does | APEX 21.2 / f345 equivalent |
|---|---|---|
| `CGBS$.SET_RELATIONS` / `QUERY_DETAILS` / `CLEAR_MASTER_DETAIL` | Designer master-detail coordination over `CGFK$ICS_HI_FK` | IG `IMPR_CNTRL_SUSPNS` with master key `HQ_IMPR_NBR` from the Form region `HQ_IMPRS` |
| `TMPLT.KEY_DELETE_RECORD` | WARNING confirm → `Delete_record` + COMMIT | IG row delete (native confirm); the DELETE is replaced by the soft-delete procedure of `ON-DELETE`. No COMMIT |
| `STR.DispAlert(text, 'ERROR')` | literal message in an alert | `<ITEM>_VALIDATION` returning the same text + `FORMS_APX.CHECK_ERROR` |
| `STR.DispAlert(text, 'CONFIRM')` | Yes / No question | native Confirm action, then open the dialog page |
| `HIJDATE.VALID_HIJ_DATE` / `CUR_HIJ_DATE` | call `HIJDATE_DB` | `FORMS_APX` Hijri helpers / `HIJDATE_DB` from the package |
| `INTRFACE.DISP_CALENDAR` / `DISP_DATE_CON` | CALL_FORM to a Hijri calendar / date-conversion form | APEX date item with the Hijri handling of IMPR1110 / IMPR1120 |
| `ACTIVITY.ADD_ACTIVITY` | `ACTIVITY_DB.ADD_ACTIVITY` with port, user, workstation | call `ACTIVITY_DB` inside the DML procedures with `P_CURR_PORT_CD`, `SSO_APP_USER`, `P_GLOBAL_V_WS_ID` |
| `NIB.*`, `TMPLT` function menu, `KEY_CONTROL`, `REP` | as IMPR1110 §10.8 | f345 shell, page 0 FUNCS drawer |

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
> - 9 alerts come from `CIC_OLB.olb`; `STR.DispAlert` sets the text at runtime. `CG$ASK_COMMIT` is not referenced.
> - Texts used (all literal in the form, no message-table lookup): "رقم الاستدلالي للمستورد المدخل غير صحيح، أدخل الرقم الصحيح أو استخدم القائمة المرفقة" (BUS_ID, ERROR), "الرقم الموحد للمستورد المدخل غير صحيح، أدخل الرقم الصحيح أو استخدم القائمة المرفقة" (HQ_IMPR_NBR, ERROR), " لا يمكن ان يكون تاريخ نهاية الأيقاف أصغر من تاريخ بداية الأيقاف" (SUSPN_END_DT, ERROR), " توجد إيقافات محذوفة من على هذا المستورد , هل تود أستعراضها ؟" (POST-QUERY, CONFIRM). Delete confirmation: WARNING alert in `TMPLT.KEY_DELETE_RECORD`.
> - APEX mapping (f345 standard §9): ERROR → `<ITEM>_VALIDATION` + `FORMS_APX.CHECK_ERROR`; CONFIRM → native Confirm action before opening the dialog; WARNING (delete) → the native confirm of the IG delete.

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
| P_PORT_TYPE | default (CHAR) / OLB | default/OLB | P_PORT_TYPE | PU EXECUTE_FUNCTION, PU PRINT_REPORT |
| P_CURR_PORT_CD | default (CHAR) / OLB | default/OLB | P_CURR_PORT_CD | FORM.WHEN-NEW-FORM-INSTANCE, IMPR_CNTRL_SUSPNS.POST-INSERT, PU CHECK_EDI_MSG_LOV, PU CHECK_EDI_MSG_TIMER, PU CHECK_TIMEOUT, PU EXECUTE_FUNCTION, PU FOR_EDI_MSG, PU PRINT_REPORT |
| P_MODULE_ID | default (CHAR) / OLB | default/OLB | P_MODULE_ID | FORM.WHEN-NEW-FORM-INSTANCE |
| P_MODULE_NAME | default (CHAR) / OLB | default/OLB | P_MODULE_NAME | FORM.KEY-DUPREC, FORM.KEY-EDIT, FORM.KEY-F5, FORM.WHEN-NEW-FORM-INSTANCE, FORM.WHEN-WINDOW-ACTIVATED, TOOLBAR.EXIT1.WHEN-BUTTON-PRESSED, TOOLBAR.RE_ENTER_QUERY.WHEN-BUTTON-PRESSED, TOOLBAR.SAVE.WHEN-BUTTON-PRESSED |
| P_APPLICATION_NAME | default (CHAR) / OLB | default/OLB | P_APPLICATION_NAME | – |
| P_USER_ID | default (CHAR) / OLB | default/OLB | P_USER_ID | FORM.WHEN-NEW-FORM-INSTANCE, PU EDI_MSG_LOV, PU EXECUTE_FUNCTION, PU FOR_EDI_MSG, PU PRINT_REPORT |
| P_WS_ID | default (CHAR) / OLB | default/OLB | P_WS_ID | PU EXECUTE_FUNCTION, PU PRINT_REPORT |
| P_USER_NAME | default (CHAR) / OLB | default/OLB | P_USER_NAME | FORM.KEY-DUPREC, FORM.KEY-EDIT, FORM.KEY-F5, FORM.WHEN-WINDOW-ACTIVATED, PU EDI_MSG_LOV, PU EXECUTE_FUNCTION, PU PRINT_REPORT, TOOLBAR.EXIT1.WHEN-BUTTON-PRESSED, TOOLBAR.RE_ENTER_QUERY.WHEN-BUTTON-PRESSED, TOOLBAR.SAVE.WHEN-BUTTON-PRESSED |
| CG$STARTUP_MODE | default (CHAR) / OLB | NORMAL | – | – |
| CURRENT_SIDE | default (CHAR) / OLB | – | – | – |

### 12.1 :GLOBAL variables (9)

| Global | Read in | Written in |
|---|---|---|
| BUS_ID | PU SINGLE_IMP_LOV | – |
| BUS_NBR | HQ_IMPRS.PRE-QUERY, HQ_IMPRS.WHEN-NEW-ITEM-INSTANCE | FORM.WHEN-NEW-FORM-INSTANCE, HQ_IMPRS.BUS_ID.WHEN-VALIDATE-ITEM, HQ_IMPRS.POST-QUERY, HQ_IMPRS.WHEN-NEW-ITEM-INSTANCE |
| CG$HP_HFILE | FORM.KEY-HELP, HQ_IMPRS.KEY-HELP, IMPR_CNTRL_SUSPNS.KEY-HELP | FORM.KEY-HELP, HQ_IMPRS.KEY-HELP, IMPR_CNTRL_SUSPNS.KEY-HELP |
| CG$HP_HPATH | FORM.KEY-HELP, HQ_IMPRS.KEY-HELP, IMPR_CNTRL_SUSPNS.KEY-HELP | FORM.PRE-FORM |
| CG$QUERY_MODE | FORM.KEY-MENU, FORM.ON-POPULATE-DETAILS, FORM.WHEN-NEW-BLOCK-INSTANCE, PU CG$WHEN_NEW_FORM_INSTANCE | PU CG$WHEN_NEW_FORM_INSTANCE |
| CURRENT_VER | – | FORM.WHEN-NEW-FORM-INSTANCE |
| EXIT | TOOLBAR.EXIT.WHEN-BUTTON-PRESSED | – |
| HQ_IMPR_NBR | HQ_IMPRS.PRE-QUERY, HQ_IMPRS.WHEN-NEW-ITEM-INSTANCE, PU SINGLE_IMP_LOV | FORM.WHEN-NEW-FORM-INSTANCE, HQ_IMPRS.HQ_IMPR_NBR.WHEN-VALIDATE-ITEM, HQ_IMPRS.POST-QUERY, HQ_IMPRS.WHEN-NEW-ITEM-INSTANCE |
| SYSTEM_OBJ | PU EXECUTE_FUNCTION | PU EXECUTE_FUNCTION (DEFAULT_VALUE) |

### 12.2 :SYSTEM variables (12)

| Variable | Used in |
|---|---|
| BLOCK_STATUS | FORM.KEY-CLRREC |
| COORDINATION_OPERATION | FORM.ON-CLEAR-DETAILS |
| CURRENT_FORM | TOOLBAR.EXIT1.WHEN-BUTTON-PRESSED |
| CURSOR_BLOCK | FORM.ON-POPULATE-DETAILS, FORM.WHEN-NEW-BLOCK-INSTANCE, HQ_IMPRS.ARBC_IMPR_NAME.KEY-LISTVAL, HQ_IMPRS.BUS_ID_BRNCH.KEY-LISTVAL, HQ_IMPRS.BUS_ID_TYPE_CD.KEY-LISTVAL, HQ_IMPRS.BUS_ID_TYPE_NAME.KEY-LISTVAL … (+15) |
| CURSOR_ITEM | HQ_IMPRS.ARBC_IMPR_NAME.KEY-LISTVAL, HQ_IMPRS.BUS_ID_BRNCH.KEY-LISTVAL, HQ_IMPRS.BUS_ID_TYPE_CD.KEY-LISTVAL, HQ_IMPRS.BUS_ID_TYPE_NAME.KEY-LISTVAL, HQ_IMPRS.CITY_CODE_OF_ID.KEY-LISTVAL, HQ_IMPRS.CITY_CODE_OF_NAME.KEY-LISTVAL … (+15) |
| CURSOR_RECORD | HQ_IMPRS.ARBC_IMPR_NAME.KEY-LISTVAL, HQ_IMPRS.BUS_ID_BRNCH.KEY-LISTVAL, HQ_IMPRS.BUS_ID_TYPE_CD.KEY-LISTVAL, HQ_IMPRS.BUS_ID_TYPE_NAME.KEY-LISTVAL, HQ_IMPRS.CITY_CODE_OF_ID.KEY-LISTVAL, HQ_IMPRS.CITY_CODE_OF_NAME.KEY-LISTVAL … (+12) |
| CURSOR_VALUE | IMPR_CNTRL_SUSPNS.SUSPN_END_DT.WHEN-VALIDATE-ITEM, IMPR_CNTRL_SUSPNS.SUSPN_STRT_DT.WHEN-VALIDATE-ITEM, TITLE.SYSTEM_DATE.WHEN-VALIDATE-ITEM |
| FORM_STATUS | FORM.KEY-CLRFRM, TOOLBAR.SAVE.WHEN-BUTTON-PRESSED |
| MASTER_BLOCK | FORM.ON-CLEAR-DETAILS |
| MODE | FORM.KEY-CQUERY, HQ_IMPRS.ARBC_IMPR_NAME.KEY-LISTVAL, HQ_IMPRS.BUS_ID_BRNCH.KEY-LISTVAL, HQ_IMPRS.BUS_ID_TYPE_CD.KEY-LISTVAL, HQ_IMPRS.BUS_ID_TYPE_NAME.KEY-LISTVAL, HQ_IMPRS.CITY_CODE_OF_ID.KEY-LISTVAL … (+14) |
| TRIGGER_BLOCK | FORM.KEY-CLRREC, FORM.KEY-CQUERY, FORM.ON-CLEAR-DETAILS |
| TRIGGER_ITEM | IMPR_CNTRL_SUSPNS.SUSPN_END_DT.WHEN-VALIDATE-ITEM, IMPR_CNTRL_SUSPNS.SUSPN_STRT_DT.WHEN-VALIDATE-ITEM, TITLE.SYSTEM_DATE.WHEN-VALIDATE-ITEM |

> **Parameter/global notes**
> - The 20 `P_*` parameters are inherited from the OLB; they map to the f345 items as in IMPR1110 §12 (`P_USER_ID` → `SSO_APP_USER`, `P_CURR_PORT_CD`, `P_WS_ID` → `P_GLOBAL_V_WS_ID`, …). `P_CURR_PORT_CD` is used for the notification channel setting and as the port of the SMS.
> - **`CURRENT_SIDE`** is declared but **no code reads it** (no side rules in this form; the side is fixed to 5). Not migrated.
> - Globals: `HQ_IMPR_NBR`, `BUS_NBR` drive the "type the number → query" flow; `BUS_ID` (and `ARBC_IMPR_NAME`, not read) are return channels of `LOV_IMPORT_HQ_NBR`; `CG$*` are Designer internals; `CURRENT_VER = 2` is a version stamp; `EXIT`, `SYSTEM_OBJ` belong to the frame. None needs an application item.

## 13. Menu & Security

### 13.1 Menu

| Property | Value |
|---|---|
| Menu module | `CIC_MENU`; it does not open IMPR1125. Screens are opened by `APPS` / `BUTTON_LAST_TREE` |
| SET_MENU_ITEM_PROPERTY | **not used** |
| In-form "menu" | `LSIDE` side menu (`TMPLT.POPULATE_FUNCTIONS`), `TOOLBAR.FUN_BUT`, `KEY-F9`. `ADJ_FUNS` and `EXEC_FUNS` are empty |

### 13.2 Function-level and data security

| Mechanism | Location | Details |
|---|---|---|
| Screen access | – | no check in the form (no `CURRENT_SIDE`, no port check): access comes only from the user's privileges on the module |
| Data scope | – | none: any unified importer can be searched; suspensions are central (no port column) |
| Delete permission | `TMPLT.KEY_DELETE_RECORD` | only when toolbar `REMOVE` is visible and enabled (function security of the frame) |
| Function menu | PU EXECUTE_FUNCTION | `SC_SYSTEM_OBJECTS`, `SC_PORT_SETTING`, role tables through `TMPLT` / `KEY_CONTROL` |

### 13.3 APEX mapping notes (f345 standard; no code in this step)

- **Page access:** the application's existing privileges (CLAUDE.md §8); no authorization schemes are generated.
- **Functions:** f345 *Page Functions* list in the page 0 `FUNCS` drawer.

## 14. Risk Assessment

> The "Proposed APEX approach" follows the f345 standard (CLAUDE.md §4b, §4c; `docs/f345_reference_standard.md` §9–§10). Nothing is generated in this step.

| # | Risk item | Location (trigger/object) | Level | Reason | Proposed APEX approach |
|---|---|---|---|---|---|
| 1 | DB COMMIT inside POST-INSERT, plus COMMIT in the delete and save paths | IMPR_CNTRL_SUSPNS.POST-INSERT (`STANDARD.COMMIT`, per inserted row), `TMPLT.KEY_DELETE_RECORD`, TOOLBAR.SAVE | High | A COMMIT in POST-INSERT commits half-processed rows | No COMMIT in the package; APEX commits at the end of the request |
| 2 | SMS / notification sent from POST-INSERT, every error hidden, NULL mobile in the new channel | IMPR_CNTRL_SUSPNS.POST-INSERT → `GNRL`, `APEX_NOTIFICATIONS`, `SMS_MESSAGE` (all **MISSING SOURCE**) | High | External side effect inside the transaction; signatures unknown; `WHEN OTHERS THEN NULL`; `TO_MOBILE_NO` is NULL in the `NE_INTEGRATION = 1` branch | Procedure `IMPR_CNTRL_SUSPNS_POST_INSERT` called by the IG process, keeping both channels and the swallowed errors (preserve behaviour). `-- SUGGESTION:` read the mobile before the branch, log failures (§15 #4) |
| 3 | `SUSPN_SEQ = MAX(SUSPN_SEQ) + 1` over the whole table, no lock | IMPR_CNTRL_SUSPNS.PRE-INSERT | Medium | Concurrent saves → PK violation | Keep in `IMPR_CNTRL_SUSPNS_PRE_INSERT`; `-- SUGGESTION:` DB sequence (§15 #5) |
| 4 | Soft delete replacing the DELETE | IMPR_CNTRL_SUSPNS.ON-DELETE (UPDATE `SUSPN_RLSE_DT` = current Hijri date + activity log), block WHERE `SUSPN_RLSE_DT IS NULL` | Medium | Automatic IG DML would really delete the row | IG custom DML (PL/SQL Code) calling `IMPR_CNTRL_SUSPNS_SAVE_ROW`; for status D → `IMPR_CNTRL_SUSPNS_ON_DELETE` |
| 5 | Query started by validation + navigation (`:GLOBAL.HQ_IMPR_NBR` / `BUS_NBR`) | BUS_ID / HQ_IMPR_NBR WVI → block WHEN-NEW-ITEM-INSTANCE (`CLEAR_BLOCK` + `EXECUTE_QUERY`), PRE-QUERY | Medium | Navigation-driven query | Search page `112501` (unified number, BUS_ID, branch, Arabic name) returning `HQ_IMPR_NBR`; the main page loads the importer. `HQ_IMPR_NBR VALIDATION` / `BUS_ID VALIDATION` keep the two "not found" texts |
| 6 | POST-QUERY SELECT INTO without handler on `SINGLE_IMPORTERS` / `BUS_ID_TYPES` | HQ_IMPRS.POST-QUERY | Medium | TOO_MANY_ROWS / NO_DATA_FOUND break the query in Forms | Lookups in process `POST-QUERY` (`HQ_IMPRS_POST_QUERY`), Forms error behaviour kept; `-- SUGGESTION:` first row (§15 #3) |
| 7 | Confirm + LOV form for released suspensions | HQ_IMPRS.POST-QUERY → DELETE_SUSPS_LOV (`LOV_DELETE_IMP_SUSP`) | Medium | Modal question after the query | Server function `RELEASED_SUSPENSIONS_EXIST`; page-load DA: native Confirm with the same text → open modal page `112502` (read-only report, `SUSPN_RLSE_DT IS NOT NULL`) |
| 8 | Hijri dates with validation and calendar forms | SUSPN_STRT_DT, SUSPN_END_DT (end ≥ start); `INTRFACE.DISP_CALENDAR` / `DISP_DATE_CON` | Medium | APEX 21.2's date picker is Gregorian | Same handling as IMPR1120 (DATE items, Forms mask, `FORMS_APX` Hijri helpers) |
| 9 | Hidden fixed values: reason always 1, side always 5 | SUSPN_RSN_CD (no canvas, default 1), SUSPN_SIDE_CD (display only, default 5) | Medium | Easy to "improve" by making them editable, which changes the rule | IG column `SUSPN_RSN_CD` hidden with default 1; `SUSPN_SIDE_CD` display only with default 5 (§15 #2) |
| 10 | Attached libraries without source (OFGTEL …) | HQ_IMPRS / IMPR_CNTRL_SUSPNS ON-ERROR (`CGTE$*`) | Medium | Constraint messages | f345 error handler + texts by constraint name where known |
| 11 | `FORMS_DDL('ALTER SESSION SET NLS_DATE_FORMAT …')` + SET_APPLICATION_PROPERTY | FORM.PRE-FORM | Medium | Session-level NLS change | f345 Globalization attributes; no ALTER SESSION |
| 12 | Reports / dynamic CALL_FORM via the function menu | PU EXECUTE_FUNCTION | Medium | Depends on `SC_SYSTEM_OBJECTS` (unknown) | f345 *Page Functions* list (page 0 FUNCS drawer) |
| 13 | Runtime list population from CG_REF_CODES | PU CGDV$POPULATE_DYNAMIC_LISTS (3 lists) | Low | Lists built at startup | Shared LOVs through `LOV_APX` (CG_REF_CODES domains) |
| 14 | Master block "insert / update allowed" but never written | HQ_IMPRS ON-INSERT / ON-UPDATE / ON-DELETE = NULL | Low | Could be mistaken for an editable header | Form region read only except the search keys; no DML on `HQ_IMPRS` |
| 15 | Activity log around DML | PRE-INSERT / PRE-UPDATE / ON-DELETE (`ACTIVITY.ADD_ACTIVITY(9,7,1/2/3)`) | Low | Source available (`ACTIVITY_DB`) | Same calls inside the DML procedures |
| 16 | Timers, EDI ticker, session timeout, Windows DLL, TEXT_IO | NIB library, unused PUs | Low | Frame behaviour | Dropped (IMPR1110 decision 2026-11-19) |
| 17 | KEY-* overrides and the 14 Designer KEY-LISTVAL checks | form / block / item KEY-* | Low | Keyboard behaviour | Page 0 toolbar, item read-only state |
| 18 | Designer MS-Help | KEY-HELP (form, both blocks) | Low | Obsolete | Dropped |
| 19 | Unused declared parameter `CURRENT_SIDE` | module parameter | Low | Looks like IMPR1120's side rules but nothing reads it | Not migrated |

**High risks: 2** (#1, #2) · Medium: 10 (#3–#12) · Low: 7 (#13–#19)

## 15. Open Questions / Missing Sources

| # | Open question / missing source | Status (2026-11-24) | Why it matters | Needed from |
|---|---|---|---|---|
| 1 | Relation to IMPR1120 (IMPR1120 §15 #2) | **Answered by the analysis:** different tables (central `IMPR_CNTRL_SUSPNS` by unified number vs port `IMPR_SUSPNS`), no side rules → two separate pages | Page design | – |
| 2 | Reason always 1 ("فروق مالية") and side always 5 (head-office restrictions): intended, or should the user choose them? | Open: **preserved** as in Forms | IG columns | Business owner |
| 3 | `SINGLE_IMPORTERS` may hold several rows per `HQ_IMPR_NBR`: which row gives the name / country / type (Forms fails with TOO_MANY_ROWS)? | Open: Forms behaviour kept (error); `ROWNUM = 1` proposed as `-- SUGGESTION:` | Master region SQL | Data owner |
| 4 | Notification: in the `NE_INTEGRATION = 1` branch the mobile number is never read (`TO_MOBILE_NO => NULL`); intended? When may it be sent (before / after the commit), and should errors stay hidden? | Open: preserved as written | Notification recipient / behaviour | Business owner |
| 5 | `SUSPN_SEQ`: keep `MAX+1` over the whole table, or use a DB sequence? | Open: preserved (`-- SUGGESTION:`) | Concurrent saves | Business owner / DBA |
| 6 | Sources / signatures of `SMS_MESSAGE`, `LIB_APX_USR.APEX_NOTIFICATIONS`, `GNRL.GET_CUSTOMS_SETTING` | Open: **MISSING SOURCE** (same as IMPR1120) | Compilation of `IMPR1125` | DBA |
| 7 | Hijri date handling: does the IMPR1110 / IMPR1120 decision apply? | Assumed yes | Date items | Business owner |
| 8 | Which functions / reports does the module have in `SC_SYSTEM_OBJECTS`? | Open | Page Functions list | Data owner |
| 9 | Grants to `LIB_APX_USR` on `IMPR_CNTRL_SUSPNS`, `HQ_IMPRS`, `SINGLE_IMPORTERS`, `IMPORTER_BASIC_DATA`, `BUS_ID_TYPES`, `COUNTRIES`, `CITIES`, `IMPR_TYPES`, `CG_REF_CODES`, and on `ACTIVITY_DB`, `HIJDATE_DB`, `GNRL`, `SMS_MESSAGE` | Open | Compilation | DBA |
| 10 | Library `OFGTEL` (Designer constraint messages) | Open: **MISSING SOURCE** | Generic constraint messages | Forms team (optional) |
| 11 | Timers / EDI ticker / custom session timeout dropped (IMPR1110 decision 2026-11-19) | Assumed yes | – | – |
