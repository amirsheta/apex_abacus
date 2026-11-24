# IMPR1140 – Inventory & Migration Risk Assessment

- **Form:** IMPR1140 – "قواعد التعامل مع المستوردين" (Importer Handling Rules / exceptions: "استثناءات التعامل مع المستوردين (جمارك - بنود تعرفة)", Designer function IMPR1140)
- **Source:** `forms/IMPR/IMPR1140_fmb.xml` (frmf2xml output, 729 lines)
- **Target:** Oracle APEX 21.2 on Oracle Database 12.1.0.2, reference application f345 (CLAUDE.md §4b, §4c)
- **Produced:** 2026-11-24 (step 01): mechanical sections by `scripts/gen_inv.py`; manual analysis in sections 1, 3–9 notes, 10.3, 10.6–10.8, 11–15 (sources in `work/IMPR1140/inv_man/`).
- **Sources used besides the form XML:** library texts `forms/COMMON/libraries/*.pld` (`CIC_LIB` for NIB, STR, INTRFACE, TMPLT, ACTIVITY, KEY_CONTROL, REP; `OFGBSL` for `CGBS$`), object library `forms/COMMON/olb/CIC_OLB_OLB.xml`, the LOV forms `forms/COMMON/lov_forms/LOV_IMPORT_HQ_NBR`, `LOV_IMPORT_HQ_N12`, `LOV_TRF_ITEMS`, `LOV_SD_PORTS`, DB package `plsql/Shared/ACTIVITY_DB.*`. The IMPR1110 / IMPR1120 inventories were used for the shared library, OLB and frame findings; they are repeated here only where IMPR1140 uses them.
- **Scope rule:** anything not available is marked **MISSING SOURCE** and is not guessed: the libraries OFGTEL, SEC_LIB, OFGTAB, PICKLIST, POS, SCDLL, VCDLL, and the DB packages `LIB_USR.SMS_MESSAGE`, `STR_DB` (message 1-270).

## 1. Summary

**Complexity: COMPLEX by the rubric** (driven by Designer and library boilerplate) · **business logic: MEDIUM** · **Effort ESTIMATE: 7–10 developer-days**

### 1.1 Counts

| Object | Count | Notes |
|---|---|---|
| Blocks | 8 | 3 base-table: `IMPR_RULES` (master, single record, insert / update / delete), `IMPR_RULE_PORTS` (detail, 8 rows, ports of the rule in the user's port) and `IMPR_RULE_TARIFF` (detail, 8 rows, tariff items, **Delete Allowed = false**); 4 OLB frame blocks (TITLE, EDI_MSG, LSIDE, TOOLBAR) and the Designer control block `CG$CTRL` |
| Items | 109 | IMPR_RULES 12, IMPR_RULE_PORTS 5, IMPR_RULE_TARIFF 9, CG$CTRL 3, LSIDE 50, TOOLBAR 16, TITLE 12, EDI_MSG 2 |
| Triggers | 260 | Form 34 · Block 28 · Item 198. 95 contain code; the others are inherited from the OLB (LSIDE mouse triggers, toolbar buttons, frame items) |
| Trigger PL/SQL lines | 2,435 total / 1,509 active | about 1,000 active lines are Designer boilerplate (14 copies of the KEY-LISTVAL "may the LOV be shown" check, 3 ON-ERROR, 4 KEY-HELP, NIB delegations) |
| Program units | 39 | 1,212 total / 751 active lines. 14 are one-line `NIB` wrappers not called by active code; 7 are Designer FK / RI checks |
| **Total PL/SQL** | **3,647 total / 2,260 active** | Business rules (IMPR_RULES DML triggers, HQ_IMPR_NBR, the tariff checks) are about 350 active lines |
| Relations (master–detail) | 2 | `CGFK$IRP_IR2_FK` IMPR_RULES → IMPR_RULE_PORTS and `CGFK$IRT_IR_FK` IMPR_RULES → IMPR_RULE_TARIFF, both on RULE_ISN, delete behaviour Non-Isolated (default), Prevent Masterless = true. Coordination by `CGBS$` (`OFGBSL.pld`) |
| LOVs / Record groups | 2 / 3 (+1 runtime RG `CGDV$DLRG` for 4 list items) | the 2 LOVs are bypassed: KEY-LISTVAL calls the LOV forms `LOV_SD_PORTS` and `LOV_TRF_ITEMS` (§10.4); `CGLT$CVS_DATA` is the Designer tab-canvas table |
| Canvases / Windows | 6 / 1 | `CG$PAGE_1` (rule) and the tab canvas `CG$M_TAB_1` with 2 tab pages (ports, tariff items) |
| Alerts | 10 | 9 from the OLB + `CG$ASK_COMMIT` (not referenced) |
| Module parameters | 21 | 20 `P_*` inherited from the OLB and `CG$STARTUP_MODE`; no parameter of the form's own |
| Attached libraries | 17 | the same list as IMPR1110 / IMPR1120 |
| Called forms | 4 static LOV forms (`LOV_IMPORT_HQ_NBR`, `LOV_IMPORT_HQ_N12`, `LOV_TRF_ITEMS`, `LOV_SD_PORTS`) + `LOV_Impr_Type` in an uncalled PU + 1 dynamic (`V_CALLED_FORM` in EXECUTE_FUNCTION) | |
| :GLOBAL / :SYSTEM variables | 17 / 14 | |
| Visual attributes | 51 | OLB |
| Subclassed (OLB) objects | 156 | |

### 1.2 Complexity rubric

| Metric | Value | Simple | Medium | Complex | Category |
|---|---|---|---|---|---|
| Data blocks | 3 base-table (8 with the control blocks) | 1–2 | 3–5 | > 5 | Medium |
| Triggers (total) | 260 | < 15 | 15–50 | > 50 | **Complex** |
| Lines of PL/SQL (triggers + PUs) | 3,647 (2,260 active) | < 300 | 300–1500 | > 1500 | **Complex** |
| Master–detail relations | 2 | 0–1 | 2–3 | > 3 | Medium |
| Called forms / libraries | 5 forms + 17 libraries | 0 | 1–3 | > 3 | **Complex** |
| Special features | SMS send (POST-INSERT / POST-UPDATE), RUN_PRODUCT (EXECUTE_FUNCTION), timers (NIB), TEXT_IO (unused PU) | none | 1 | ≥ 2 | **Complex** |

**Result: COMPLEX** (4 metrics reach Complex).

**Justification.** As in IMPR1120 the size comes from generated code: Designer lookups, error and help handlers, 14 copies of the KEY-LISTVAL check, and the OLB frame that the f345 shell replaces. The real work is one master-detail page: an editable rule (type, all ports or one port, unified importer number with the importer's data), a grid of ports and a grid of tariff items on two tabs. The rules: `MAX + 1` keys, a role check for rule types 13 / 14, an SMS for rule type 14, the activity log on every DML, the tariff-item checks (exists, effective, not already excepted for the importer) and the delete check on the ports.

**Effort ESTIMATE: 7–10 developer-days** for the main page (Form + 2 IGs in tabs), the search page, the shared LOVs, package `IMPR1140`, security mapping and testing. Not included: the DB package without source (`SMS_MESSAGE`) and any reports reached through EXECUTE_FUNCTION.

## 2. Module header

| Property | Value |
|---|---|
| Form name | IMPR1140 |
| Title | قواعد التعامل مع المستوردين |
| First navigation block | IMPR_RULES |
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
  IMPR1140

MODIFIED
  APPDEV248       19/08/26  11:26 created by Form Generator for
                                  Form Builder Version 6.0.3.11.0

Repository APPLICATION SYSTEM
  IMPORTERS Version 1

PURPOSE
  استثناءات التعامل مع المستوردين (جمارك - بنود تعرفة

MODULE DESCRIPTION
.
قواعد التعامل مع المستوردين

MODULE NOTES
Developed by Application Design Transformer from Function IMPR1140
Identified as a screen because not overnight and not retrieval only
Candidate Module because it is an elementary Function
.
.



TABLE USAGES
  BASE   IMPR_RULES                    SEL INS UPD DEL
  BASE   IMPR_RULE_PORTS               SEL INS UPD DEL
  BASE   IMPR_RULE_TARIFF              SEL INS UPD

REFERENTIAL INTEGRITY RULES
Block IMPR_RULES
  Deletion of IMPR_RULES prevented if IMPR_RULE_PORTS records exist
  Foreign key(s): IRP_IR2_FK

WARNINGS - 19/08/26  11:26
  01362: Popup list has too many values; 15 valid values (maximum
         is 5)
  01280: display length = 5, item length = 4;
  01280: display length = 10, item length = 4;
  01280: display length = 50, item length = 40;
  01157: Foreign key item(s) in IMPR_RULES not enterable; those in
         lookup not a unique key  (BUS_ID_TYPE_NAME - Bus Id Type
         Name)
  01140: Column IMPR_RULE_PORTS.RULE_ISN used in link to previous
         block changed to non-display
  01316: Foreign key constraint IRP_IR2_FK in IMPR_RULE_PORTS has
         no enterable items or lookups
  01140: Column IMPR_RULE_TARIFF.RULE_ISN used in link to previous
         block changed to non-display
  01316: Foreign key constraint IRT_IR_FK in IMPR_RULE_TARIFF has
         no enterable items or lookups

*******************************************************************
```

> Notes: generated by **Oracle Designer Form Generator** (APPDEV248, 19/08/26) from Designer function IMPR1140, then hand-modified ("NALSALEH CENTRALIZED PROJECT", CR-5537 version stamp `current_ver := 1`, `current_DT := '13-11-2024'`, commented "AAA" / "tabbaa" / "current" blocks). Table usages: `IMPR_RULES` SEL INS UPD DEL, `IMPR_RULE_PORTS` SEL INS UPD DEL, `IMPR_RULE_TARIFF` SEL INS UPD (no delete). RI rule: deletion of IMPR_RULES prevented if IMPR_RULE_PORTS records exist (FK `IRP_IR2_FK`). Designer warnings: the RULE_TYPE pop list has 15 values (maximum 5), display lengths differ from item lengths, FK items of IMPR_RULES are not enterable, and FKs `IRP_IR2_FK` / `IRT_IR_FK` have no enterable items.

## 3. Blocks

> Properties absent from the XML are Forms defaults **or inherited from the object library** (`ParentModule`/`ParentName`); such values are shown as `default/OLB` (OLB properties: `forms/COMMON/olb/CIC_OLB_OLB.xml`).

| Block | Base table / Query data source | DML target | Type | Records displayed | Records buffered | WHERE clause | ORDER BY | Insert | Update | Delete | Query | Canvas(es) | Subclassed from |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| TITLE | – | – | control (non-DB) | default/OLB | default/OLB | – | – | default/OLB | default/OLB | default/OLB | default/OLB | – | CIC_OLB.olb:TITLE |
| EDI_MSG | – | – | control (non-DB) | default/OLB | default/OLB | – | – | default/OLB | default/OLB | default/OLB | default/OLB | – | CIC_OLB.olb:EDI_MSG |
| LSIDE | – | – | control (non-DB) | default/OLB | default/OLB | – | – | default/OLB | default/OLB | default/OLB | default/OLB | – | CIC_OLB.olb:LSIDE |
| TOOLBAR | – | – | control (non-DB) | default/OLB | default/OLB | – | – | default/OLB | default/OLB | default/OLB | default/OLB | – | CIC_OLB.olb:TOOLBAR |
| IMPR_RULES | IMPR_RULES | same as query source (default) | base-table | default/OLB | 4 | – | ORDER BY RULE_ISN | default/OLB | default/OLB | default/OLB | default/OLB | CG$PAGE_1 | cic_olb.olb:CGSO$BLOCK |
| IMPR_RULE_PORTS | IMPR_RULE_PORTS | same as query source (default) | base-table | 8 | 11 | WHERE   ( IMPR_RULE_PORTS.PORT_CD = :PARAMETER.P_CURR_PORT_CD ) | – | default/OLB | default/OLB | default/OLB | default/OLB | CG$M_TAB_1 | cic_olb.olb:CGSO$BLOCK_MR |
| IMPR_RULE_TARIFF | IMPR_RULE_TARIFF | same as query source (default) | base-table | 8 | 11 | – | – | default/OLB | default/OLB | false | default/OLB | CG$M_TAB_1 | cic_olb.olb:CGSO$BLOCK_MR |
| CG$CTRL | – | – | control (non-DB) | default/OLB | default/OLB | – | – | default/OLB | default/OLB | default/OLB | default/OLB | – | cic_olb.olb:CGSO$BLOCK_CT |

Block `IMPR_RULES` comment (decoded):

```text
*******************************************************************

BLOCK NAME
  IMPR_RULES

TABLE COMMENT
  استثناءات المستوردين

TABLE USAGES
  BASE   IMPR_RULES                    SEL INS UPD DEL
  ...    RULE_ISN                      SEL INS     NUL
  ...    RULE_TYPE                     SEL INS UPD
  ...    ALL_BRNCH_FLAG                SEL INS UPD
  ...    HQ_IMPR_NBR                   SEL INS UPD NUL
  ...    REC_STATUS                    SEL INS UPD
  ...    BUS_ID_TYPE_CD                SEL
  ...    BUS_ID                        SEL
  ...    BUS_ID_BRNCH                  SEL         NUL

TUI DESCRIPTION


*******************************************************************
```

Block `IMPR_RULE_PORTS` comment (decoded):

```text
CG$LAYOUT_NEW_TAB_PAGE
*******************************************************************

BLOCK NAME
  IMPR_RULE_PORTS

TABLE COMMENT
  جمارك الاستثناء

TABLE USAGE COMMENT
  Autogenerated by App Des Transformer.

TABLE USAGES
  BASE   IMPR_RULE_PORTS               SEL INS UPD DEL
  ...    RULE_ISN
  ...    PORT_CD                       SEL INS
  ...    REC_STATUS                    SEL INS UPD

JOIN CONDITION
  IMPR_RULE_PORTS.RULE_ISN = IMPR_RULES.RULE_ISN

TUI DESCRIPTION


*******************************************************************
```

Block `IMPR_RULE_TARIFF` comment (decoded):

```text
CG$LAYOUT_NEW_TAB_PAGE
*******************************************************************

BLOCK NAME
  IMPR_RULE_TARIFF

TABLE COMMENT
  بنود التعرفة المستثناة

TABLE USAGES
  BASE   IMPR_RULE_TARIFF              SEL INS UPD
  ...    RULE_ISN
  ...    HRMNZD_CODE                   SEL INS
  ...    EXCEPTED_QTY                  SEL INS UPD
  ...    REMAINED_QTY                  SEL
  ...    REC_STATUS                    SEL INS UPD
  ...    ITEM_SEQUENCE                 SEL INS UPD NUL

JOIN CONDITION
  IMPR_RULE_TARIFF.RULE_ISN = IMPR_RULES.RULE_ISN

TUI DESCRIPTION


*******************************************************************
```

Block `CG$CTRL` comment (decoded):

```text
*******************************************************************

BLOCK NAME
  CG$CTRL

control block generated by Form Generator to hold items used to
display content canvas and block header information

*******************************************************************
```

> **Block notes**
> - `TITLE`, `EDI_MSG`, `LSIDE`, `TOOLBAR` are OLB frame blocks, `CG$CTRL` is the Designer control block (tab-canvas bookkeeping). They are replaced by the f345 page template, the page 0 toolbar and the page 0 `FUNCS` drawer.
> - `IMPR_RULES` (master, `CGSO$BLOCK`: one record displayed, 4 buffered) is a normal editable block: Insert / Update / Delete / Query at the default (true), `ORDER BY RULE_ISN`. PRE-QUERY only adds the Designer sub-query for a `BUS_ID_TYPE_NAME` criterion (`CGFK$DEFAULT_WHERE`, string concatenation).
> - `IMPR_RULE_PORTS` (detail, 8 rows displayed, 11 buffered) has `WHERE IMPR_RULE_PORTS.PORT_CD = :PARAMETER.P_CURR_PORT_CD` ("NALSALEH CENTRALIZED PROJECT"): a user sees only the row of his own port. Insert is switched off while `IMPR_RULES.ALL_BRNCH_FLAG = 1` (POST-QUERY, PRE-RECORD, WHEN-NEW-RECORD-INSTANCE: `SET_BLOCK_PROPERTY(INSERT_ALLOWED)`).
> - `IMPR_RULE_TARIFF` (detail, 8 rows displayed) has **DeleteAllowed = false**, so its PRE-DELETE can never fire. It has no WHERE clause.
> - The master key `RULE_ISN` is copied into both details (`CopyValueFromItem IMPR_RULES.RULE_ISN`); it is set in `IMPR_RULES.PRE-INSERT` as `MAX(RULE_ISN) + 1` of the whole table.
> - Master delete (`IMPR_RULES.KEY-DELREC`) is refused when the rule has a port row in the user's port (message `STR.DispArbMsg(1, 270)`); then `TMPLT.KEY_DELETE_RECORD` asks for confirmation, deletes and **commits**; the Designer RI check `CGRI$CHK_IMPR_RULES` (any port row of the rule) and a second `delete_record` follow in the same trigger (generated code appended after the hand-written part).

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

### 4.5 Block `IMPR_RULES` (12 items)

| # | Item | Item type | Subclass (OLB) | Data type | Max len | Column name | DB item | Required | LOV | Default value | Format mask | Canvas / tab page | Visible | Insert / Update / Query allowed | Prompt / label | Copy-value-from / calc | List values / hint |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | RULE_ISN | – | CGSO$CHAR_ARB_DO | Number | 11 | RULE_ISN | – | – | – | – | – | CG$PAGE_1 | – | true/·/true | مسلسل الاستثناء | – | مسلسل داخلي لقواعد المستوردين |
| 2 | D | – | CGSO$CHAR_EN_DO_MLINE | – | – | – | false | false | – | – | – | CG$PAGE_1 | – | – | – | – | Enter value for |
| 3 | RULE_TYPE | – | CGSO$POP_MD | Number | 4 | RULE_TYPE | – | – | – | 1 | – | CG$PAGE_1 | – | – | نوع الاستثناء | – | 1=تسديد بتأمين سندي; 2=إعفاء أرامكو; 3=إعفاء الحمالة البرية; 4=إعفاء صادر سلع مقيدة; 5=إستثناء حظر تصدير البترول; 6=إستثناء دفع رسوم المعاملة بالمثل التونسية; 7=استثناء فسح استيراد مواد تحتاج إلى خطاب فسح بدون خطاب فسح; 8=منع مصدرين محددين من تصدير أصناف محددة مسموح تصديرها; 9=استثناء مستورد/مصدر  بالسماح له باستيراد أو تصدير  كميات محددة من بنود ممنوع استيرادها أو تصديرها; 10=استثناء مستورد بالسماح له باستيراد بنود ممنوع استيرادها; 11=استثناء مصدر بالسماح له بتصدير بنود ممنوع تصديرها; 12=أستثناء فرق الدعم للصادرات البترولية; 13=أستثناء منع ميزة الفسح المباشر; 14=أستثناء منع ميزة الفسح بتعهد; 15=استثناء مستورد من إنشاء  طلب تحليل هيئة الغذاء والدواء آليا |
| 4 | ALL_BRNCH_FLAG | – | CGSO$POP_MD | Number | 2 | ALL_BRNCH_FLAG | – | – | – | 0 | – | CG$PAGE_1 | – | – | استخدام الاستثناء | – | 1=جميع الجمارك; 0=جمرك محدد |
| 5 | HQ_IMPR_NBR | – | CGSO$NUMBER | – | 11 | HQ_IMPR_NBR | – | – | – | – | – | CG$PAGE_1 | – | – | رقم المستورد الموحد | – | Enter value for رقم المستورد الموحد |
| 6 | B_IMP | – | CGSO$LOV_BUT | – | – | – | false | false | – | – | – | CG$PAGE_1 | – | false/false/false | – | – | Enter value for |
| 7 | L_SI_ARBC_IMPR_NAME | – | CGSO$CHAR_ARB_DO | – | – | – | false | false | – | – | – | CG$PAGE_1 | – | – | – | – | Enter value for |
| 8 | REC_STATUS | – | CGSO$POP_MD | Number | 2 | REC_STATUS | – | – | – | 1 | – | CG$PAGE_1 | – | – | حـالة السجل | – | 1=فعال; 0=غير فعال |
| 9 | BUS_ID_TYPE_CD | – | CGSO$NUMBER_ARB_WT_DO | – | 4 | BUS_ID_TYPE_CD | – | true | – | – | – | CG$PAGE_1 | – | ·/·/true | نوع الرقم الاستدلالى | – | رمز نوع الرقم  الاستدلالى |
| 10 | BUS_ID_TYPE_NAME | – | CGSO$CHAR_EN_DO_MLINE | – | 40 | – | false | false | – | – | – | CG$PAGE_1 | – | ·/·/true | – | – | مسمى  نوع الرقم الاستدلالى |
| 11 | BUS_ID | – | CGSO$CHAR_EN_DO_MLINE | – | 15 | BUS_ID | – | false | – | – | – | CG$PAGE_1 | – | ·/·/true | الرقم الاستدلالى | – | الرقم الاستدلالى للمستورد |
| 12 | BUS_ID_BRNCH | – | CGSO$CHAR_DO | – | 10 | BUS_ID_BRNCH | – | – | – | – | – | CG$PAGE_1 | – | ·/·/true | الفرع | – | رقم الفرع للمستورد |

### 4.6 Block `IMPR_RULE_PORTS` (5 items)

| # | Item | Item type | Subclass (OLB) | Data type | Max len | Column name | DB item | Required | LOV | Default value | Format mask | Canvas / tab page | Visible | Insert / Update / Query allowed | Prompt / label | Copy-value-from / calc | List values / hint |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | RULE_ISN | – | CGSO$NUMBER_MR_MD | – | 11 | RULE_ISN | – | false | – | – | – | – | false | false/false/false | Rule Isn | IMPR_RULES.RULE_ISN | مسلسل داخلي لقواعد المستوردين |
| 2 | PORT_CD | – | CGSO$CHAR_ARB | Number | 4 | PORT_CD | – | true | CGFK$IMPR_RULE_PORTS_PORT_CD | – | – | CG$M_TAB_1/CG$M_TAB_1_PAGE_1 | – | ·/false/· | رمز الجمرك | – | رمز الميناء - list of values available |
| 3 | PORT_CD2 | – | CGSO$LOV_BUT_MR | – | – | – | – | – | – | – | – | CG$M_TAB_1/CG$M_TAB_1_PAGE_1 | – | – | – | – | – |
| 4 | PORT_NAME | – | CGSO$CHAR_ARB_DO | – | 40 | – | false | false | – | – | – | CG$M_TAB_1/CG$M_TAB_1_PAGE_1 | – | ·/·/true | اسم الجمرك | – | اسم الميناء العربي |
| 5 | REC_STATUS | – | CGSO$POP_MR | Number | 2 | REC_STATUS | – | true | – | 1 | – | CG$M_TAB_1/CG$M_TAB_1_PAGE_1 | – | – | حالة السجل | – | 1=فعال; 0=غير فعال |

### 4.7 Block `IMPR_RULE_TARIFF` (9 items)

| # | Item | Item type | Subclass (OLB) | Data type | Max len | Column name | DB item | Required | LOV | Default value | Format mask | Canvas / tab page | Visible | Insert / Update / Query allowed | Prompt / label | Copy-value-from / calc | List values / hint |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | RULE_ISN | – | CGSO$NUMBER_MR_MD | – | 11 | RULE_ISN | – | false | – | – | – | – | false | false/false/false | رقم مسلسل الإستثناء | IMPR_RULES.RULE_ISN | Enter value for رقم مسلسل الإستثناء |
| 2 | HRMNZD_CODE | – | CGSO$CHAR_MR_MD | – | 16 | HRMNZD_CODE | – | true | CGFK$IMPR_RULE_TARIFF_HRMNZD_C | – | – | CG$M_TAB_1/CG$M_TAB_1_PAGE_2 | – | ·/false/· | رمز بند التعريفة | – | Enter value for رمز بند التعريفة - list of values available |
| 3 | HRMNZD_CODE2 | – | CGSO$LOV_BUT_MR | – | – | – | – | – | – | – | – | CG$M_TAB_1/CG$M_TAB_1_PAGE_2 | – | – | – | – | – |
| 4 | HT_ITEM_ARBC_DESC | – | CGSO$CHAR_ARB_DO | – | 1000 | – | false | false | – | – | – | CG$M_TAB_1/CG$M_TAB_1_PAGE_2 | – | – | الوصــــــــــف | – | وصف الصنف بالعربية |
| 5 | EXEPTION_QTY | – | CGSO$NUMBER_MR_MD | – | 14 | EXCEPTED_QTY | – | true | – | – | – | CG$M_TAB_1/CG$M_TAB_1_PAGE_2 | – | – | الكمية المستثناة | – | Enter value for الكمية المستثناة |
| 6 | REMAINED_QTY | – | CGSO$CHAR_ARB_DO | Number | 14 | REMAINED_QTY | – | false | – | – | – | CG$M_TAB_1/CG$M_TAB_1_PAGE_2 | – | ·/·/true | الكمية المتبقية | – | Enter value for الكمية المتبقية |
| 7 | INTL_UNIT | – | CGSO$CHAR_ARB_DO | – | – | – | false | false | – | – | – | CG$M_TAB_1/CG$M_TAB_1_PAGE_2 | – | – | الوحدةالدوليه | – | Enter value for الوحدةالدوليه |
| 8 | REC_STATUS | – | CGSO$POP_MR | Number | 2 | REC_STATUS | – | true | – | 1 | – | CG$M_TAB_1/CG$M_TAB_1_PAGE_2 | – | – | حالة السجل | – | 1=فعال; 0=غير فعال |
| 9 | ITEM_SEQUENCE | – | CGSO$NUMBER_MR | – | 6 | ITEM_SEQUENCE | – | – | – | – | – | – | false | false/false/false | رقم تسلسلي لبنود التعرفة | – | رقم تسلسلي لبنود التعرفة |

### 4.8 Block `CG$CTRL` (3 items)

| # | Item | Item type | Subclass (OLB) | Data type | Max len | Column name | DB item | Required | LOV | Default value | Format mask | Canvas / tab page | Visible | Insert / Update / Query allowed | Prompt / label | Copy-value-from / calc | List values / hint |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | CG$PAGE_1_LIST | – | CGSO$DEFAULT_ITEM_CT | – | 2000 | – | – | – | – | – | – | – | false | – | – | – | – |
| 2 | CG$WINDOWCGSO$WINDOW_1_PAGE | – | CGSO$DEFAULT_ITEM_CT | – | – | – | – | – | – | – | – | – | false | – | – | – | – |
| 3 | CG$LAST_CANVAS | – | CGSO$DEFAULT_ITEM_CT | – | – | – | – | – | – | – | – | – | false | – | – | – | – |

> **Item notes**
> - Items of the 4 OLB frame blocks and `CG$CTRL` have no business attributes in the form XML; they are not migrated.
> - `IMPR_RULES.RULE_ISN` is display only (set by PRE-INSERT). `IMPR_RULES.D` is a non-database multi-line item made invisible in PRE-FORM (`SET_ITEM_PROPERTY('D', VISIBLE, FALSE)`).
> - `RULE_TYPE` (15 values, default 1) and `REC_STATUS` (default 1) are pop lists whose static values are replaced at startup by `CGDV$POPULATE_DYNAMIC_LISTS` from `CG_REF_CODES` (domains `RULE_TYPE` and `REC_STATUS`; `REC_STATUS` also fills the two detail `REC_STATUS` lists). `ALL_BRNCH_FLAG` is a static pop list (1 = جميع الجمارك, 0 = جمرك محدد, default 0).
> - `RULE_TYPE = 9` is refused at once ("هذا النوع غير مستخدم", WHEN-LIST-CHANGED and WHEN-VALIDATE-ITEM).
> - `HQ_IMPR_NBR` (unified importer number) is the only entered importer item. Its WHEN-VALIDATE-ITEM fills `BUS_ID`, `BUS_ID_BRNCH`, `BUS_ID_TYPE_CD`, `L_SI_ARBC_IMPR_NAME` (and `BUS_ID_TYPE_NAME`) from `IMPORTERS` of the user's port when `RULE_TYPE = 12`, otherwise from `SINGLE_IMPORTERS`. KEY-LISTVAL / button `B_IMP` open `LOV_IMPORT_HQ_N12` (rule type 12) or `LOV_IMPORT_HQ_NBR`. `BUS_ID_TYPE_CD`, `BUS_ID`, `BUS_ID_BRNCH` are database items that the user does not type; Forms saves the values the trigger sets.
> - `BUS_ID_BRNCH` is enterable only while `ALL_BRNCH_FLAG <> 1`; when the flag becomes 1 it is cleared (`ADJ_BRANCH`, from WHEN-NEW-RECORD-INSTANCE and ALL_BRNCH_FLAG WHEN-VALIDATE-ITEM).
> - `IMPR_RULE_PORTS.PORT_CD` (required, LOV `LOV_SD_PORTS` form, not updatable) is checked against `SD_PORTS` and fills `PORT_NAME`; `PORT_CD2` is its LOV button.
> - `IMPR_RULE_TARIFF.HRMNZD_CODE` (required, not updatable, LOV form `LOV_TRF_ITEMS`) fills `HT_ITEM_ARBC_DESC` and `INTL_UNIT`; `HRMNZD_CODE2` is its LOV button. The item `EXEPTION_QTY` is on the column **`EXCEPTED_QTY`** (item and column names differ); its WHEN-VALIDATE-ITEM copies the value into `REMAINED_QTY` and shows an information alert. `REMAINED_QTY` is display only. `ITEM_SEQUENCE` is hidden (PRE-INSERT `MAX + 1` within the rule). `INTL_UNIT` is non-database (POST-QUERY lookup).

## 5. Relations (master–detail)

| Relation | Master block | Detail block | Join condition | Delete behaviour | Deferred / Auto-query | Prevent masterless operations | Subclassed from |
|---|---|---|---|---|---|---|---|
| CGFK$IRP_IR2_FK | IMPR_RULES | IMPR_RULE_PORTS | IMPR_RULES.RULE_ISN = IMPR_RULE_PORTS.RULE_ISN | not in XML → Forms default (Non-Isolated) | default (false)/default (false) | true | – |
| CGFK$IRT_IR_FK | IMPR_RULES | IMPR_RULE_TARIFF | IMPR_RULES.RULE_ISN = IMPR_RULE_TARIFF.RULE_ISN | not in XML → Forms default (Non-Isolated) | default (false)/default (false) | true | – |

## 6. Triggers

> **Trigger notes**
> - 260 triggers: Form 34, Block 28, Item 198. The ones without code are inherited from `CIC_OLB_OLB.xml` (LSIDE mouse triggers, TOOLBAR buttons, frame items), as in IMPR1110 / IMPR1120.
> - Form-level triggers are `NIB.*` delegations (`CIC_LIB.pld`), Designer block synchronisation (`CGBS$` / `CGBS2$`: ON-POPULATE-DETAILS, ON-CLEAR-DETAILS, WHEN-NEW-BLOCK-INSTANCE, KEY-CQUERY, KEY-CLRREC, KEY-MENU, KEY-CLRFRM), the Designer tab handling (`CGLT$TAB_BLOCKS` in WHEN-TAB-PAGE-CHANGED / WHEN-NEW-BLOCK-INSTANCE), help and messages. The form level has **no business code** (PRE-FORM: version stamp, hide `D`, date format).
> - 14 KEY-LISTVAL triggers start with the same Designer check (`CGAP$OLES_SEQUENCE_BEFORE`); only 3 then call an LOV (HQ_IMPR_NBR → `SINGLE_IMP_LOV`, PORT_CD → `CALL_SD_PORTS`, HRMNZD_CODE → `DSP_TRF_ITEMS_LOV`). In APEX the check is the item's read-only state.
> - The business rules are in the IMPR_RULES DML triggers (PRE-INSERT key + role check, POST-INSERT / POST-UPDATE SMS, activity log), IMPR_RULES.KEY-DELREC, HQ_IMPR_NBR, RULE_TYPE, ALL_BRNCH_FLAG, the detail DML triggers (activity log, `ITEM_SEQUENCE`) and `HRMNZD_CODE.WHEN-VALIDATE-ITEM`.
> - The activity log calls differ by block: `ACTIVITY.ADD_ACTIVITY(9, 4, 1/2/3, RULE_ISN)` for IMPR_RULES — the update log is in **POST-UPDATE**, insert / delete in PRE-INSERT / PRE-DELETE —, `(9, 5, 1/2/3, RULE_ISN!PORT_CD)` for ports and `(9, 6, 1/2/3, RULE_ISN!HRMNZD_CODE)` for tariff items.

### 6.0 Trigger index

| # | Level | Owner | Trigger | Lines (total / active) | Exec. hierarchy | Source | Program units called |
|---|---|---|---|---|---|---|---|
| 1 | Form | FORM | KEY-EDIT | 21 / 1 | default (Override) | XML | – |
| 2 | Form | FORM | KEY-DUPREC | 10 / 1 | default (Override) | XML | – |
| 3 | Form | FORM | PRE-FORM | 44 / 16 | default (Override) | XML | – |
| 4 | Form | FORM | WHEN-NEW-FORM-INSTANCE | 144 / 11 | default (Override) | XML | CG$WHEN_NEW_FORM_INSTANCE |
| 5 | Form | FORM | WHEN-WINDOW-ACTIVATED | 29 / 1 | default (Override) | XML | – |
| 6 | Form | FORM | KEY-ENTQRY | 49 / 4 | default (Override) | XML | – |
| 7 | Form | FORM | ON-ERROR | 39 / 1 | default (Override) | XML | – |
| 8 | Form | FORM | ON-MESSAGE | 34 / 1 | default (Override) | XML | – |
| 9 | Form | FORM | KEY-CLRBLK | 28 / 10 | default (Override) | XML | – |
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
| 26 | Form | FORM | WHEN-NEW-BLOCK-INSTANCE | 33 / 22 | default (Override) | XML | CGLY$CANVAS_MANAGEMENT, CGLY$GET_RELATED_CANVASES |
| 27 | Form | FORM | ON-CLEAR-DETAILS | 10 / 8 | default (Override) | XML | – |
| 28 | Form | FORM | ON-POPULATE-DETAILS | 5 / 3 | default (Override) | XML | – |
| 29 | Form | FORM | KEY-CQUERY | 9 / 7 | default (Override) | XML | – |
| 30 | Form | FORM | KEY-CLRREC | 11 / 9 | default (Override) | XML | – |
| 31 | Form | FORM | KEY-NXTKEY | 6 / 4 | default (Override) | XML | – |
| 32 | Form | FORM | KEY-MENU | 8 / 3 | default (Override) | XML | CGBS$TOGGLE |
| 33 | Form | FORM | KEY-CLRFRM | 19 / 14 | default (Override) | XML | CG$WHEN_NEW_FORM_INSTANCE |
| 34 | Form | FORM | WHEN-TAB-PAGE-CHANGED | 8 / 6 | default (Override) | XML | – |
| 35 | Item | TITLE.CGSO$CHAR_ARB_ED | KEY-LISTVAL | 0 / 0 | default (Override) | OLB code (1 lines): `NULL;` | – |
| 36 | Item | TITLE.CGSO$CHAR_ARB_DO_ENB_Y | KEY-LISTVAL | 0 / 0 | default (Override) | OLB code (1 lines): `NULL;` | – |
| 37 | Item | TITLE.CGSO$CHAR_ARB_MLINE | KEY-LISTVAL | 0 / 0 | default (Override) | OLB code (1 lines): `NULL;` | – |
| 38 | Item | TITLE.CGSO$CHAR_ARB | KEY-LISTVAL | 0 / 0 | default (Override) | OLB code (1 lines): `NULL;` | – |
| 39 | Item | TITLE.CGSO$CHAR_ARB_DO | KEY-LISTVAL | 0 / 0 | default (Override) | OLB code (1 lines): `NULL;` | – |
| 40 | Item | TITLE.SYSTEM_DATE | WHEN-VALIDATE-ITEM | 13 / 12 | default (Override) | XML | – |
| 41 | Item | EDI_MSG.EDI_MSG_LOVE_BUT | WHEN-BUTTON-PRESSED | 0 / 0 | default (Override) | OLB code (1 lines): `EDI_MSG_LOV;` | – |
| 42 | Item | LSIDE.FN1 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 43 | Item | LSIDE.FN1 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 44 | Item | LSIDE.FN1 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 45 | Item | LSIDE.FN50 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 46 | Item | LSIDE.FN50 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 47 | Item | LSIDE.FN50 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 48 | Item | LSIDE.FN2 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 49 | Item | LSIDE.FN2 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 50 | Item | LSIDE.FN2 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 51 | Item | LSIDE.FN49 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 52 | Item | LSIDE.FN49 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 53 | Item | LSIDE.FN49 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 54 | Item | LSIDE.FN3 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 55 | Item | LSIDE.FN3 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 56 | Item | LSIDE.FN3 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 57 | Item | LSIDE.FN48 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 58 | Item | LSIDE.FN48 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 59 | Item | LSIDE.FN48 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 60 | Item | LSIDE.FN4 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 61 | Item | LSIDE.FN4 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 62 | Item | LSIDE.FN4 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 63 | Item | LSIDE.FN47 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 64 | Item | LSIDE.FN47 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 65 | Item | LSIDE.FN47 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 66 | Item | LSIDE.FN5 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 67 | Item | LSIDE.FN5 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 68 | Item | LSIDE.FN5 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 69 | Item | LSIDE.FN46 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 70 | Item | LSIDE.FN46 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 71 | Item | LSIDE.FN46 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 72 | Item | LSIDE.FN6 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 73 | Item | LSIDE.FN6 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 74 | Item | LSIDE.FN6 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 75 | Item | LSIDE.FN45 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 76 | Item | LSIDE.FN45 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 77 | Item | LSIDE.FN45 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 78 | Item | LSIDE.FN7 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 79 | Item | LSIDE.FN7 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 80 | Item | LSIDE.FN7 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 81 | Item | LSIDE.FN44 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 82 | Item | LSIDE.FN44 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 83 | Item | LSIDE.FN44 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 84 | Item | LSIDE.FN8 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 85 | Item | LSIDE.FN8 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 86 | Item | LSIDE.FN8 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 87 | Item | LSIDE.FN43 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 88 | Item | LSIDE.FN43 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 89 | Item | LSIDE.FN43 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 90 | Item | LSIDE.FN9 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 91 | Item | LSIDE.FN9 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 92 | Item | LSIDE.FN9 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 93 | Item | LSIDE.FN42 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 94 | Item | LSIDE.FN42 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 95 | Item | LSIDE.FN42 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 96 | Item | LSIDE.FN10 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 97 | Item | LSIDE.FN10 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 98 | Item | LSIDE.FN10 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 99 | Item | LSIDE.FN41 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 100 | Item | LSIDE.FN41 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 101 | Item | LSIDE.FN41 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 102 | Item | LSIDE.FN11 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 103 | Item | LSIDE.FN11 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 104 | Item | LSIDE.FN11 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 105 | Item | LSIDE.FN40 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 106 | Item | LSIDE.FN40 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 107 | Item | LSIDE.FN40 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 108 | Item | LSIDE.FN12 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 109 | Item | LSIDE.FN12 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 110 | Item | LSIDE.FN12 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 111 | Item | LSIDE.FN39 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 112 | Item | LSIDE.FN39 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 113 | Item | LSIDE.FN39 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 114 | Item | LSIDE.FN13 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 115 | Item | LSIDE.FN13 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 116 | Item | LSIDE.FN13 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 117 | Item | LSIDE.FN38 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 118 | Item | LSIDE.FN38 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 119 | Item | LSIDE.FN38 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 120 | Item | LSIDE.FN14 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 121 | Item | LSIDE.FN14 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 122 | Item | LSIDE.FN14 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 123 | Item | LSIDE.FN37 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 124 | Item | LSIDE.FN37 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 125 | Item | LSIDE.FN37 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 126 | Item | LSIDE.FN15 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 127 | Item | LSIDE.FN15 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 128 | Item | LSIDE.FN15 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 129 | Item | LSIDE.FN36 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 130 | Item | LSIDE.FN36 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 131 | Item | LSIDE.FN36 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 132 | Item | LSIDE.FN16 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 133 | Item | LSIDE.FN16 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 134 | Item | LSIDE.FN16 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 135 | Item | LSIDE.FN17 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 136 | Item | LSIDE.FN17 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 137 | Item | LSIDE.FN17 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 138 | Item | LSIDE.FN34 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 139 | Item | LSIDE.FN34 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 140 | Item | LSIDE.FN34 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 141 | Item | LSIDE.FN35 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 142 | Item | LSIDE.FN35 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 143 | Item | LSIDE.FN35 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 144 | Item | LSIDE.FN18 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 145 | Item | LSIDE.FN18 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 146 | Item | LSIDE.FN18 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 147 | Item | LSIDE.FN33 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 148 | Item | LSIDE.FN33 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 149 | Item | LSIDE.FN33 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 150 | Item | LSIDE.FN19 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 151 | Item | LSIDE.FN19 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 152 | Item | LSIDE.FN19 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 153 | Item | LSIDE.FN32 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 154 | Item | LSIDE.FN32 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 155 | Item | LSIDE.FN32 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 156 | Item | LSIDE.FN20 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 157 | Item | LSIDE.FN20 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 158 | Item | LSIDE.FN20 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 159 | Item | LSIDE.FN31 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 160 | Item | LSIDE.FN31 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 161 | Item | LSIDE.FN31 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 162 | Item | LSIDE.FN21 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 163 | Item | LSIDE.FN21 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 164 | Item | LSIDE.FN21 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 165 | Item | LSIDE.FN30 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 166 | Item | LSIDE.FN30 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 167 | Item | LSIDE.FN30 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 168 | Item | LSIDE.FN22 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 169 | Item | LSIDE.FN22 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 170 | Item | LSIDE.FN22 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 171 | Item | LSIDE.FN29 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 172 | Item | LSIDE.FN29 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 173 | Item | LSIDE.FN29 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 174 | Item | LSIDE.FN23 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 175 | Item | LSIDE.FN23 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 176 | Item | LSIDE.FN23 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 177 | Item | LSIDE.FN28 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 178 | Item | LSIDE.FN28 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 179 | Item | LSIDE.FN28 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 180 | Item | LSIDE.FN24 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 181 | Item | LSIDE.FN24 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 182 | Item | LSIDE.FN24 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 183 | Item | LSIDE.FN27 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 184 | Item | LSIDE.FN27 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 185 | Item | LSIDE.FN27 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 186 | Item | LSIDE.FN25 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 187 | Item | LSIDE.FN25 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 188 | Item | LSIDE.FN25 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 189 | Item | LSIDE.FN26 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 190 | Item | LSIDE.FN26 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 191 | Item | LSIDE.FN26 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 192 | Block | TOOLBAR | KEY-DOWN | 3 / 3 | default (Override) | XML | – |
| 193 | Block | TOOLBAR | KEY-UP | 3 / 3 | default (Override) | XML | – |
| 194 | Block | TOOLBAR | KEY-NEXT-ITEM | 10 / 10 | default (Override) | XML | EXECUTE_FUNCTION |
| 195 | Item | TOOLBAR.SAVE | WHEN-BUTTON-PRESSED | 15 / 12 | default (Override) | XML | – |
| 196 | Item | TOOLBAR.CLEAR_ALL | WHEN-BUTTON-PRESSED | 0 / 0 | default (Override) | OLB code (4 lines): `do_key('clear_BLOCK');` | – |
| 197 | Item | TOOLBAR.EXIT | WHEN-BUTTON-PRESSED | 19 / 15 | default (Override) | XML | – |
| 198 | Item | TOOLBAR.EXIT1 | WHEN-BUTTON-PRESSED | 42 / 38 | default (Override) | XML | – |
| 199 | Item | TOOLBAR.ENTER | WHEN-BUTTON-PRESSED | 0 / 0 | default (Override) | OLB code (26 lines): `SET_ITEM_PROPERTY('SAVE',VISIBLE,PROPERTY_FALSE);` | – |
| 200 | Item | TOOLBAR.EXECUTE | WHEN-BUTTON-PRESSED | 0 / 0 | default (Override) | OLB code (1 lines): `do_key('Execute_query');` | – |
| 201 | Item | TOOLBAR.REMOVE | WHEN-BUTTON-PRESSED | 0 / 0 | default (Override) | OLB code (1 lines): `do_key('Delete_record');` | – |
| 202 | Item | TOOLBAR.LIST_VALUE | WHEN-BUTTON-PRESSED | 0 / 0 | default (Override) | OLB code (1 lines): `do_key('LIST_VALUES');` | – |
| 203 | Item | TOOLBAR.HELP | WHEN-BUTTON-PRESSED | 0 / 0 | default (Override) | OLB code (10 lines): `DECLARE` | – |
| 204 | Item | TOOLBAR.LAST_REC | WHEN-BUTTON-PRESSED | 1 / 1 | default (Override) | XML | – |
| 205 | Item | TOOLBAR.RE_ENTER_QUERY | WHEN-BUTTON-PRESSED | 6 / 6 | default (Override) | XML | – |
| 206 | Item | TOOLBAR.FIRST_REC | WHEN-BUTTON-PRESSED | 0 / 0 | default (Override) | OLB code (1 lines): `do_key('Previous_Record');` | – |
| 207 | Item | TOOLBAR.PAGE_UP | WHEN-BUTTON-PRESSED | 0 / 0 | default (Override) | OLB code (1 lines): `do_key('Scroll_Up');` | – |
| 208 | Item | TOOLBAR.PAGE_DOWN | WHEN-BUTTON-PRESSED | 1 / 1 | default (Override) | XML | – |
| 209 | Item | TOOLBAR.FUN_BUT | WHEN-MOUSE-UP | 15 / 12 | default (Override) | XML | – |
| 210 | Item | TOOLBAR.FUN_BUT | WHEN-MOUSE-DOWN | 13 / 10 | default (Override) | XML | ADJ_FUNS |
| 211 | Block | IMPR_RULES | ON-ERROR | 96 / 74 | default (Override) | XML | CGTE$CHECK_CONSTRAINT_VIO |
| 212 | Block | IMPR_RULES | POST-QUERY | 68 / 47 | default (Override) | XML | CG$IMPR1140_CNTRL_GLOBALS, CGFK$QRY_IMPR_RULES_IR_BIT_FK |
| 213 | Block | IMPR_RULES | PRE-QUERY | 55 / 46 | default (Override) | XML | CG$IMPR1140_CNTRL_GLOBALS |
| 214 | Block | IMPR_RULES | KEY-DELREC | 43 / 32 | default (Override) | XML | CGRI$CHK_IMPR_RULES |
| 215 | Block | IMPR_RULES | KEY-HELP | 32 / 30 | default (Override) | XML | – |
| 216 | Block | IMPR_RULES | POST-INSERT | 48 / 34 | default (Override) | XML | – |
| 217 | Block | IMPR_RULES | POST-UPDATE | 52 / 37 | default (Override) | XML | – |
| 218 | Block | IMPR_RULES | PRE-DELETE | 6 / 5 | default (Override) | XML | – |
| 219 | Block | IMPR_RULES | PRE-INSERT | 46 / 16 | default (Override) | XML | CHECK_FASH_ROLE_ID |
| 220 | Block | IMPR_RULES | PRE-UPDATE | 35 / 11 | default (Override) | XML | CHECK_FASH_ROLE_ID |
| 221 | Block | IMPR_RULES | WHEN-NEW-RECORD-INSTANCE | 4 / 3 | default (Override) | XML | ADJ_BRANCH |
| 222 | Item | IMPR_RULES.RULE_ISN | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 223 | Item | IMPR_RULES.D | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 224 | Item | IMPR_RULES.RULE_TYPE | WHEN-LIST-CHANGED | 6 / 6 | default (Override) | XML | – |
| 225 | Item | IMPR_RULES.RULE_TYPE | WHEN-VALIDATE-ITEM | 6 / 6 | default (Override) | XML | – |
| 226 | Item | IMPR_RULES.ALL_BRNCH_FLAG | WHEN-VALIDATE-ITEM | 4 / 3 | default (Override) | XML | ADJ_BRANCH |
| 227 | Item | IMPR_RULES.HQ_IMPR_NBR | KEY-LISTVAL | 37 / 35 | default (Override) | XML | SINGLE_IMP_LOV |
| 228 | Item | IMPR_RULES.HQ_IMPR_NBR | WHEN-VALIDATE-ITEM | 50 / 30 | default (Override) | XML | – |
| 229 | Item | IMPR_RULES.B_IMP | WHEN-BUTTON-PRESSED | 7 / 5 | default (Override) | XML | – |
| 230 | Item | IMPR_RULES.L_SI_ARBC_IMPR_NAME | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 231 | Item | IMPR_RULES.BUS_ID_TYPE_CD | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 232 | Item | IMPR_RULES.BUS_ID_TYPE_NAME | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 233 | Item | IMPR_RULES.BUS_ID | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 234 | Block | IMPR_RULE_PORTS | POST-QUERY | 25 / 22 | default (Override) | XML | CGFK$QRY_IMPR_RULE_PORTS_IRP_S |
| 235 | Block | IMPR_RULE_PORTS | ON-ERROR | 80 / 58 | default (Override) | XML | CGTE$CHECK_CONSTRAINT_VIO |
| 236 | Block | IMPR_RULE_PORTS | KEY-HELP | 32 / 30 | default (Override) | XML | – |
| 237 | Block | IMPR_RULE_PORTS | PRE-DELETE | 6 / 5 | default (Override) | XML | – |
| 238 | Block | IMPR_RULE_PORTS | PRE-INSERT | 7 / 5 | default (Override) | XML | – |
| 239 | Block | IMPR_RULE_PORTS | PRE-RECORD | 8 / 7 | default (Override) | XML | – |
| 240 | Block | IMPR_RULE_PORTS | PRE-UPDATE | 5 / 5 | default (Override) | XML | – |
| 241 | Block | IMPR_RULE_PORTS | WHEN-NEW-RECORD-INSTANCE | 8 / 7 | default (Override) | XML | – |
| 242 | Item | IMPR_RULE_PORTS.PORT_CD | KEY-LISTVAL | 37 / 35 | default (Override) | XML | CALL_SD_PORTS |
| 243 | Item | IMPR_RULE_PORTS.PORT_CD | WHEN-VALIDATE-ITEM | 17 / 15 | default (Override) | XML | CGFK$CHK_IMPR_RULE_PORTS_IRP_S |
| 244 | Item | IMPR_RULE_PORTS.PORT_CD2 | WHEN-BUTTON-PRESSED | 6 / 4 | default (Override) | XML | – |
| 245 | Item | IMPR_RULE_PORTS.PORT_NAME | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 246 | Block | IMPR_RULE_TARIFF | ON-ERROR | 78 / 56 | default (Override) | XML | CGTE$CHECK_CONSTRAINT_VIO |
| 247 | Block | IMPR_RULE_TARIFF | KEY-HELP | 32 / 30 | default (Override) | XML | – |
| 248 | Block | IMPR_RULE_TARIFF | POST-QUERY | 18 / 17 | default (Override) | XML | – |
| 249 | Block | IMPR_RULE_TARIFF | PRE-DELETE | 5 / 5 | default (Override) | XML | – |
| 250 | Block | IMPR_RULE_TARIFF | PRE-INSERT | 19 / 13 | default (Override) | XML | – |
| 251 | Block | IMPR_RULE_TARIFF | PRE-UPDATE | 5 / 5 | default (Override) | XML | – |
| 252 | Item | IMPR_RULE_TARIFF.HRMNZD_CODE | KEY-LISTVAL | 38 / 35 | default (Override) | XML | DSP_TRF_ITEMS_LOV |
| 253 | Item | IMPR_RULE_TARIFF.HRMNZD_CODE | POST-CHANGE | 9 / 9 | default (Override) | XML | – |
| 254 | Item | IMPR_RULE_TARIFF.HRMNZD_CODE | WHEN-VALIDATE-ITEM | 107 / 66 | default (Override) | XML | – |
| 255 | Item | IMPR_RULE_TARIFF.HRMNZD_CODE2 | WHEN-BUTTON-PRESSED | 6 / 4 | default (Override) | XML | – |
| 256 | Item | IMPR_RULE_TARIFF.HT_ITEM_ARBC_DESC | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 257 | Item | IMPR_RULE_TARIFF.EXEPTION_QTY | WHEN-VALIDATE-ITEM | 4 / 4 | default (Override) | XML | – |
| 258 | Item | IMPR_RULE_TARIFF.REMAINED_QTY | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 259 | Item | IMPR_RULE_TARIFF.INTL_UNIT | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 260 | Item | IMPR_RULE_TARIFF.ITEM_SEQUENCE | KEY-LISTVAL | 34 / 32 | default (Override) | XML | – |

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
- Lines: 44 total / 16 active (non-blank, non-comment)
- Built-ins: FORMS_DDL, SET_APPLICATION_PROPERTY, SET_ITEM_PROPERTY
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

BEGIN
	:global.current_ver := 1; -- NALSALEH CENTRALIZED PROJECT -- CR-5537
	:global.current_DT := '13-11-2024' ;
	:global.current_version := '('||:global.current_ver||'-('||:global.current_DT||')' ;

	SET_ITEM_PROPERTY('D',VISIBLE,PROPERTY_FALSE);
END;
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
- Lines: 144 total / 11 active (non-blank, non-comment)
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
- Lines: 28 total / 10 active (non-blank, non-comment)
- Built-ins: CLEAR_BLOCK, RAISE FORM_TRIGGER_FAILURE
- Program units (form): –
- Library / DB package calls: CGBS2$.DO_COMMIT_DIALOGUE, CGBS2$.IS_COMMIT_NEEDED, CGBS2$.IS_RECORD_DIRTY, NIB.KEY_CLRBLK

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
/* CGBS$KEY_CLRBLK_FRM */
/* Perform checks prior to clearing block */
BEGIN
  IF ( CGBS2$.IS_RECORD_DIRTY(:SYSTEM.TRIGGER_BLOCK) ) THEN
    RAISE FORM_TRIGGER_FAILURE;
  END IF;
  IF (:SYSTEM.BLOCK_STATUS = 'CHANGED' OR CGBS2$.IS_COMMIT_NEEDED( :SYSTEM.TRIGGER_BLOCK ) ) THEN
    CGBS2$.DO_COMMIT_DIALOGUE;
  END IF;
  clear_block( NO_VALIDATE );
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
- Lines: 33 total / 22 active (non-blank, non-comment)
- Built-ins: GET_ITEM_PROPERTY
- Program units (form): CGLY$CANVAS_MANAGEMENT, CGLY$GET_RELATED_CANVASES
- Library / DB package calls: CGBS$.NEW_BLOCK, CGLT$TAB_BLOCKS.CGLT$NEW_BLOCK

```plsql
/* CGLT$TAB_BLOCK_MANAGEMENT                */
/* Switch tab management code on/off        */
DECLARE
   current_canvas VARCHAR2(61) := GET_ITEM_PROPERTY(:SYSTEM.CURSOR_ITEM, ITEM_CANVAS);
   base_canvas VARCHAR2(61);
BEGIN
   CGLY$GET_RELATED_CANVASES(current_canvas, base_canvas);
   IF( base_canvas IN ( 'CG$PAGE_1' ) ) THEN
      CGLT$TAB_BLOCKS.ACTIVATE := TRUE;
   ELSE
      CGLT$TAB_BLOCKS.ACTIVATE := FALSE;
   END IF;
END;
/* CGLY$MANAGE_CANVASES */
/* Call procedure to ensure correct canvases are visible */
BEGIN
  CGLY$CANVAS_MANAGEMENT;
END;


/* CGLT$TAB_NEW_BLOCK                      */
/* Show canvases for this block            */
BEGIN
   IF CGLT$TAB_BLOCKS.ACTIVATE = TRUE THEN
      CGLT$TAB_BLOCKS.CGLT$NEW_BLOCK;
   END IF;
END;

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

#### FORM · WHEN-TAB-PAGE-CHANGED

- Level: Form · Owner: `FORM` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 8 total / 6 active (non-blank, non-comment)
- Built-ins: –
- Program units (form): –
- Library / DB package calls: CGLT$TAB_BLOCKS.CGLT$TAB_CHANGED

```plsql
/* CGLT$NEW_TAB_PAGE                  */
/* Show related canvases for this tab */
BEGIN
   IF( :SYSTEM.TAB_NEW_PAGE IN ( 'CG$M_TAB_1_PAGE_1', 'CG$M_TAB_1_PAGE_2' ) ) THEN
      CGLT$TAB_BLOCKS.ACTIVATE := TRUE;
      CGLT$TAB_BLOCKS.CGLT$TAB_CHANGED;
   END IF;
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

#### IMPR_RULES · ON-ERROR

- Level: Block · Owner: `IMPR_RULES` · Execution hierarchy: default (Override)
- Lines: 96 total / 74 active (non-blank, non-comment)
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
        IF (constraint_name = 'IR_BIT_FK') THEN
          Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(13, 'This <p1> does not exist', 'Bus Id Type Name' ), 'E', 'OFG', 13);
        ELSE
          Des$Form_errors.PUSH(server_msg, 'I', 'OFG', 0);
        END IF;
        Des$Form_errors.RAISE_FAILURE;
      END IF;

      /* FK - Child record found */
      IF (server_err = 2292) THEN
        IF (err_code = 40510) THEN
          IF (constraint_name = 'IRP_IR2_FK') THEN
            Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(5, 'Cannot delete <p1> while dependent <p2> exists', 'استثناءات المستوردين','جمارك الاستثناء' ), 'E', 'OFG', 5);
          ELSE
            Des$Form_errors.PUSH(server_msg, 'I', 'OFG', 0);
          END IF;
        ELSIF (err_code = 40509) THEN
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

#### IMPR_RULES · POST-QUERY

- Level: Block · Owner: `IMPR_RULES` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 68 total / 47 active (non-blank, non-comment)
- Built-ins: NAME_IN, SET_BLOCK_PROPERTY, SET_RECORD_PROPERTY
- Program units (form): CG$IMPR1140_CNTRL_GLOBALS, CGFK$QRY_IMPR_RULES_IR_BIT_FK
- Library / DB package calls: CGTE$OTHER_EXCEPTIONS, DES$FORM_ERRORS.MSGGETTEXT, DES$FORM_ERRORS.PUSH, STR.DISPALERT

```plsql
/*
BEGIN
	IF :HQ_IMPR_NBR IS NOT NULL THEN
		SELECT ARBC_IMPR_NAME
		INTO   :L_SI_ARBC_IMPR_NAME
		FROM   SINGLE_IMPORTERS
		WHERE  HQ_IMPR_NBR = :HQ_IMPR_NBR;

		SELECT BUS_ID_TYPE_NAME INTO :BUS_ID_TYPE_NAME FROM BUS_ID_TYPES WHERE BUS_ID_TYPE_CD = :BUS_ID_TYPE_CD;
	END IF;
EXCEPTION
	WHEN OTHERS THEN
		STR.DISPALERT('رقم المستورد المدخل غير صحيح','ERROR');
END;
*/
BEGIN
   IF :hq_impr_nbr IS NOT NULL
   THEN
      IF :impr_rules.rule_type = 12
      THEN
         SELECT arbc_impr_name
           INTO :l_si_arbc_impr_name
           FROM importers
          WHERE PORT_CD = :PARAMETER.P_CURR_PORT_CD -- NALSALEH CENTRALIZED PROJECT
	    AND hq_impr_nbr = :hq_impr_nbr AND ROWNUM = 1;
      ELSE
         SELECT arbc_impr_name
           INTO :l_si_arbc_impr_name
           FROM single_importers
          WHERE hq_impr_nbr = :hq_impr_nbr;
      END IF;

      SELECT bus_id_type_name
        INTO :bus_id_type_name
        FROM bus_id_types
       WHERE bus_id_type_cd = :bus_id_type_cd;
   END IF;
EXCEPTION
   WHEN OTHERS
   THEN
      str.dispalert ('رقم المستورد المدخل غير صحيح', 'ERROR');
END;
/* CGFK$QRY_LOOKUP_DATA */
/* Query lookup data for the foreign key(s) */
BEGIN
  IF (name_in('IMPR_RULES.BUS_ID_TYPE_CD') IS NOT NULL) THEN
    BEGIN
      CGFK$QRY_IMPR_RULES_IR_BIT_FK(
        :IMPR_RULES.BUS_ID_TYPE_NAME    /* MOD: Value in Item :IMPR_RULES.BUS_ID_TYPE_NAME.                                                                                                                                                   */
       ,:IMPR_RULES.BUS_ID_TYPE_CD  );  /* IN : Value in Item :IMPR_RULES.BUS_ID_TYPE_CD.                                                                                                                                                     */
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(13, 'This <p1> does not exist', 'Bus Id Type Name' ), 'E', 'OFG', 13);
      WHEN OTHERS THEN
        CGTE$OTHER_EXCEPTIONS;
    END;
    SET_RECORD_PROPERTY(:SYSTEM.TRIGGER_RECORD, 'IMPR_RULES', STATUS ,                 QUERY_STATUS);
  END IF;
END;

/* CGFK$RESET_BLOCK_WHERE_CLAUSE */
/* Resets block where clause */
BEGIN
  IF (CG$IMPR1140_CNTRL_GLOBALS.IMPR_RULES_WHERE <> 'first_time') THEN
    set_block_property('IMPR_RULES', DEFAULT_WHERE, CG$IMPR1140_CNTRL_GLOBALS.IMPR_RULES_WHERE);
    CG$IMPR1140_CNTRL_GLOBALS.IMPR_RULES_WHERE := 'first_time';
  END IF;
END;
```

#### IMPR_RULES · PRE-QUERY

- Level: Block · Owner: `IMPR_RULES` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 55 total / 46 active (non-blank, non-comment)
- Built-ins: FIND_BLOCK, GET_BLOCK_PROPERTY, NAME_IN, SET_BLOCK_PROPERTY
- Program units (form): CG$IMPR1140_CNTRL_GLOBALS
- Library / DB package calls: CG$IMPR1140_CNTRL_GLOBALS.IMPR_RULES_WHERE, DES$FORM_ERRORS.MSGGETTEXT, DES$FORM_ERRORS.PUSH, DES$FORM_ERRORS.RAISE_FAILURE

```plsql
/* CGFK$DEFAULT_WHERE */
/* Add restrictive query on FK items if value(s) entered in non-table items    */
/* and/or if there are items which may contain nulls as valid values.  Code to */
/* restrict the query is added to the default where clause of the block.       */
BEGIN
  DECLARE
    block_id   Block := find_block('IMPR_RULES');
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
    IF ( CG$IMPR1140_CNTRL_GLOBALS.IMPR_RULES_WHERE = 'first_time') THEN
      CG$IMPR1140_CNTRL_GLOBALS.IMPR_RULES_WHERE := get_block_property(block_id, DEFAULT_WHERE);
    END IF;
    def_where := CG$IMPR1140_CNTRL_GLOBALS.IMPR_RULES_WHERE;

    sub_where := NULL;
    r_string := NAME_IN('IMPR_RULES.BUS_ID_TYPE_NAME');
    IF (r_string IS NOT NULL) THEN
      BEGIN
        IF substr(r_string, 1,1) IN ('<','>','=') THEN
          sub_where := add_and( sub_where ) || '(BUS_ID_TYPE_NAME '|| r_string || ')';
        ELSIF substr(r_string, 1,1) ='#' THEN
          sub_where := add_and( sub_where ) || '(BUS_ID_TYPE_NAME '|| substr(r_string,2) || ')';
        ELSIF instr(r_string, '%') <> 0 THEN
          sub_where := add_and( sub_where ) || '(BUS_ID_TYPE_NAME LIKE '''|| replace(r_string,'''','''''') || ''')';
        ELSE
          sub_where := add_and( sub_where ) || '(BUS_ID_TYPE_NAME ='''|| replace(r_string,'''','''''') || ''')';
        END IF;
      END;
    END IF;
    IF (sub_where IS NOT NULL) THEN
      def_where := add_and( def_where ) || '((BUS_ID_TYPE_CD) IN '||'(SELECT BUS_ID_TYPE_CD '||'FROM BUS_ID_TYPES WHERE '|| sub_where || '))';
    END IF;

    set_block_property(block_id, DEFAULT_WHERE, def_where);

  EXCEPTION
    WHEN VALUE_ERROR THEN
      Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(33, 'Query criteria too complex - simplify and re-query'), 'E', 'OFG', 33);
      Des$Form_errors.RAISE_FAILURE;
  END;
END;
```

#### IMPR_RULES · KEY-DELREC

- Level: Block · Owner: `IMPR_RULES` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 43 total / 32 active (non-blank, non-comment)
- Built-ins: DELETE_RECORD, RAISE FORM_TRIGGER_FAILURE
- Program units (form): CGRI$CHK_IMPR_RULES
- Library / DB package calls: CG$CHK_PACKAGE_FAILURE, CGTE$OTHER_EXCEPTIONS, STR.DISPARBMSG, TMPLT.KEY_DELETE_RECORD

```plsql
DECLARE
	V_COUNT NUMBER;
BEGIN

	--CHECK IF THERE IS REC ON IMPR_RULE_PORTS OR NOT
	SELECT COUNT INTO V_COUNT
	FROM IMPR_RULE_PORTS
	WHERE PORT_CD = :PARAMETER.P_CURR_PORT_CD -- NALSALEH CENTRALIZED PROJECT
	AND RULE_ISN = :IMPR_RULES.RULE_ISN;

	IF V_COUNT >0 THEN
		STR.DISPARBMSG(1,270,'ERROR');
		RAISE form_trigger_failure;
	END IF;

	TMPLT.KEY_DELETE_RECORD;
END;
/* CGRI$CHECK_ON_DELETE */
/* This checks that the user is allowed to delete the current row, */
/* prior to removing it,  according to any referential integrity   */
/* rules held in the database design.                              */
BEGIN
  BEGIN
    CGRI$CHK_IMPR_RULES(
      TRUE                    /* IN : Check FKs validated in BOTH (client/server)?                                                                                                                                                            */
     ,:IMPR_RULES.RULE_ISN);  /* IN : Item value                                                                                                                                                                                              */
  EXCEPTION
    WHEN OTHERS THEN
      CGTE$OTHER_EXCEPTIONS;
  END;
END;

/* CGGN$KEY_DELREC */
/* Perform the key's standard functionality */
BEGIN
  delete_record;
  BEGIN
    CG$CHK_PACKAGE_FAILURE;
  EXCEPTION
    WHEN OTHERS THEN
      CGTE$OTHER_EXCEPTIONS;
  END;
END;
```

#### IMPR_RULES · KEY-HELP

- Level: Block · Owner: `IMPR_RULES` · Execution hierarchy: default (Override) · Fire in query: true
- Lines: 32 total / 30 active (non-blank, non-comment)
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
END;
```

#### IMPR_RULES · POST-INSERT

- Level: Block · Owner: `IMPR_RULES` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 48 total / 34 active (non-blank, non-comment)
- Built-ins: –
- Program units (form): –
- Library / DB package calls: LIB_USR.SMS_MESSAGE.SEND_SMS_MESSAGE

```plsql
DECLARE
	v_msg  	VARCHAR2(500);
	V_MOBILE_NO  NUMBER;
BEGIN



  BEGIN

   SELECT DISTINCT MOBILE_NO
      INTO V_MOBILE_NO
     FROM IMPORTER_BASIC_DATA
    WHERE HQ_IMPR_NBR    = :HQ_IMPR_NBR
     AND  MOBILE_NO IS NOT NULL;

    IF V_MOBILE_NO IS NULL THEN

      SELECT DISTINCT MOBILE_NO
        INTO V_MOBILE_NO
       FROM importers
      WHERE PORT_CD = :PARAMETER.P_CURR_PORT_CD -- NALSALEH CENTRALIZED PROJECT
	 AND HQ_IMPR_NBR    = :HQ_IMPR_NBR
       AND  MOBILE_NO IS NOT NULL;

    END IF;

	EXCEPTION WHEN OTHERS THEN
		NULL;

   END ;

	 v_msg := 'تم منع ميزة الفسح بتعهد للمستورد من إدارة المخاطر - الجمارك السعودية' ;

	IF V_MOBILE_NO IS NOT NULL AND :IMPR_RULES.RULE_TYPE	 = 14 AND :IMPR_RULES.REC_STATUS = 1 THEN

	 lib_usr.sms_message.send_sms_message (9,
                                            6,
                                            1,
                                            :PARAMETER.P_CURR_PORT_CD,
                                            NULL,
                                            V_MOBILE_NO,
                                            v_msg,
                                            :IMPR_RULES.RULE_ISN || '|' || :IMPR_RULES.HQ_IMPR_NBR
                                           );

	END IF;

	END ;
```

#### IMPR_RULES · POST-UPDATE

- Level: Block · Owner: `IMPR_RULES` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 52 total / 37 active (non-blank, non-comment)
- Built-ins: RAISE FORM_TRIGGER_FAILURE
- Program units (form): –
- Library / DB package calls: ACTIVITY.ADD_ACTIVITY, LIB_USR.SMS_MESSAGE.SEND_SMS_MESSAGE

```plsql
DECLARE
V_MOBILE_NO NUMBER;
v_msg VARCHAR2(500);
BEGIN

	IF NOT ACTIVITY.ADD_ACTIVITY(9, 4, 2, :IMPR_RULES.RULE_ISN)	THEN
		RAISE FORM_TRIGGER_FAILURE;
	END IF;

	BEGIN

   SELECT DISTINCT MOBILE_NO
      INTO V_MOBILE_NO
     FROM IMPORTER_BASIC_DATA
    WHERE HQ_IMPR_NBR    = :HQ_IMPR_NBR
     AND  MOBILE_NO IS NOT NULL;

    IF V_MOBILE_NO IS NULL THEN

      SELECT DISTINCT MOBILE_NO
        INTO V_MOBILE_NO
       FROM importers
      WHERE PORT_CD = :PARAMETER.P_CURR_PORT_CD -- NALSALEH CENTRALIZED PROJECT
	 AND HQ_IMPR_NBR    = :HQ_IMPR_NBR
       AND  MOBILE_NO IS NOT NULL;

    END IF;

	EXCEPTION WHEN OTHERS THEN
		NULL;

   END ;

	 v_msg := 'تم منع ميزة الفسح بتعهد للمستورد من إدارة المخاطر - الجمارك السعودية' ;

	IF V_MOBILE_NO IS NOT NULL AND :IMPR_RULES.RULE_TYPE	 = 14 AND :IMPR_RULES.REC_STATUS = 1 THEN

	 	lib_usr.sms_message.send_sms_message (9,
                                            6,
                                            1,
                                            :PARAMETER.P_CURR_PORT_CD,
                                            NULL,
                                            V_MOBILE_NO,
                                            v_msg,
                                            :IMPR_RULES.RULE_ISN || '|' || :IMPR_RULES.HQ_IMPR_NBR
                                           );

	END IF;



END;
```

#### IMPR_RULES · PRE-DELETE

- Level: Block · Owner: `IMPR_RULES` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 6 total / 5 active (non-blank, non-comment)
- Built-ins: RAISE FORM_TRIGGER_FAILURE
- Program units (form): –
- Library / DB package calls: ACTIVITY.ADD_ACTIVITY

```plsql
BEGIN

	IF NOT ACTIVITY.ADD_ACTIVITY(9, 4, 3, :IMPR_RULES.RULE_ISN)	THEN
		RAISE FORM_TRIGGER_FAILURE;
	END IF;
END;
```

#### IMPR_RULES · PRE-INSERT

- Level: Block · Owner: `IMPR_RULES` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 46 total / 16 active (non-blank, non-comment)
- Built-ins: RAISE FORM_TRIGGER_FAILURE
- Program units (form): CHECK_FASH_ROLE_ID
- Library / DB package calls: ACTIVITY.ADD_ACTIVITY, STR.DISPALERT

```plsql
DECLARE

	V_COUNT	NUMBER;


BEGIN
/*----AAA
	SELECT COUNT(*)
	INTO   V_COUNT
	FROM   IMPR_RULES
	WHERE  HQ_IMPR_NBR = :HQ_IMPR_NBR
	  AND  RULE_TYPE   = :RULE_TYPE;

	IF V_COUNT > 0 THEN
		STR.DISPALERT('نوع الاستثناء مدخل من قبل لنفس المستورد','ERROR');
		RAISE FORM_TRIGGER_FAILURE;
	END IF;

*/----AAA

/*
	IF :ALL_BRNCH_FLAG = 0 AND :BUS_ID_BRNCH IS NULL THEN
		STR.DISPALERT('يجب تحديد الفرع أولاً','ERROR');
		RAISE FORM_TRIGGER_FAILURE;
	END IF;

*/

	SELECT NVL(MAX(RULE_ISN),0) + 1
	INTO   :IMPR_RULES.RULE_ISN
	FROM   IMPR_RULES;

	IF NOT ACTIVITY.ADD_ACTIVITY(9, 4, 1, :IMPR_RULES.RULE_ISN)	THEN
		RAISE FORM_TRIGGER_FAILURE;
	END IF;

IF :IMPR_RULES.RULE_TYPE IN (13,14)	 THEN

  IF CHECK_FASH_ROLE_ID(:PARAMETER.P_CURR_PORT_CD,:PARAMETER.P_USER_ID) = FALSE THEN

  	STR.DISPALERT(' لا يوجد صلاحيات كافية للمستخدم'|| :PARAMETER.P_USER_ID ||'لإنشاء هذا النوع من الاستثناءات ','ERROR');
		RAISE FORM_TRIGGER_FAILURE;
	END IF;
END IF;

END;
```

#### IMPR_RULES · PRE-UPDATE

- Level: Block · Owner: `IMPR_RULES` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 35 total / 11 active (non-blank, non-comment)
- Built-ins: RAISE FORM_TRIGGER_FAILURE
- Program units (form): CHECK_FASH_ROLE_ID
- Library / DB package calls: STR.DISPALERT

```plsql
DECLARE

	V_COUNT	NUMBER;
      V_CNT NUMBER;
BEGIN
/*----AAA
SELECT COUNT(*)
	INTO   V_COUNT
	FROM   IMPR_RULES
	WHERE  HQ_IMPR_NBR = :HQ_IMPR_NBR
	  AND  RULE_TYPE   = :RULE_TYPE
	  AND  RULE_ISN   <> :IMPR_RULES.RULE_ISN;

	IF V_COUNT > 0 THEN
		STR.DISPALERT('نوع الاستثناء مدخل من قبل لنفس المستورد','ERROR');
		RAISE FORM_TRIGGER_FAILURE;
	END IF;
*/----AAA

/*
	IF :ALL_BRNCH_FLAG = 0 AND :BUS_ID_BRNCH IS NULL THEN
		STR.DISPALERT('يجب تحديد الفرع أولاً','ERROR');
		RAISE FORM_TRIGGER_FAILURE;
	END IF;
*/
IF :IMPR_RULES.RULE_TYPE IN (13,14)	 THEN

  IF CHECK_FASH_ROLE_ID(:PARAMETER.P_CURR_PORT_CD,:PARAMETER.P_USER_ID) = FALSE THEN

  	STR.DISPALERT(' لا يوجد صلاحيات كافية للمستخدم' || :PARAMETER.P_USER_ID || 'لإنشاء هذا النوع من الاستثناءات ','ERROR');

		RAISE FORM_TRIGGER_FAILURE;
	END IF;
END IF;
END;
```

#### IMPR_RULES · WHEN-NEW-RECORD-INSTANCE

- Level: Block · Owner: `IMPR_RULES` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 4 total / 3 active (non-blank, non-comment)
- Built-ins: –
- Program units (form): ADJ_BRANCH
- Library / DB package calls: –

```plsql
BEGIN
	ADJ_BRANCH;

END;
```

#### IMPR_RULE_PORTS · POST-QUERY

- Level: Block · Owner: `IMPR_RULE_PORTS` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 25 total / 22 active (non-blank, non-comment)
- Built-ins: NAME_IN, SET_BLOCK_PROPERTY, SET_RECORD_PROPERTY
- Program units (form): CGFK$QRY_IMPR_RULE_PORTS_IRP_S
- Library / DB package calls: CGTE$OTHER_EXCEPTIONS, DES$FORM_ERRORS.MSGGETTEXT, DES$FORM_ERRORS.PUSH

```plsql
BEGIN
IF :IMPR_RULES.ALL_BRNCH_FLAG = 1  THEN
	SET_BLOCK_PROPERTY('IMPR_RULE_PORTS', INSERT_ALLOWED, PROPERTY_FALSE);
ELSE
	SET_BLOCK_PROPERTY('IMPR_RULE_PORTS', INSERT_ALLOWED, PROPERTY_TRUE);
END IF;

END;
/* CGFK$QRY_LOOKUP_DATA */
/* Query lookup data for the foreign key(s) */
BEGIN
  IF (name_in('IMPR_RULE_PORTS.PORT_CD') IS NOT NULL) THEN
    BEGIN
      CGFK$QRY_IMPR_RULE_PORTS_IRP_S(
        :IMPR_RULE_PORTS.PORT_NAME    /* MOD: Value in Item :IMPR_RULE_PORTS.PORT_NAME.                                                                                                                                                       */
       ,:IMPR_RULE_PORTS.PORT_CD  );  /* IN : Value in Item :IMPR_RULE_PORTS.PORT_CD.                                                                                                                                                         */
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(13, 'This <p1> does not exist', 'رمز الجمرك' ), 'E', 'OFG', 13);
      WHEN OTHERS THEN
        CGTE$OTHER_EXCEPTIONS;
    END;
    SET_RECORD_PROPERTY(:SYSTEM.TRIGGER_RECORD, 'IMPR_RULE_PORTS', STATUS ,                 QUERY_STATUS);
  END IF;
END;
```

#### IMPR_RULE_PORTS · ON-ERROR

- Level: Block · Owner: `IMPR_RULE_PORTS` · Execution hierarchy: default (Override) · Fire in query: true
- Lines: 80 total / 58 active (non-blank, non-comment)
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
        IF (constraint_name = 'IRP_SDP_FK') THEN
          Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(13, 'This <p1> does not exist', 'رمز الجمرك' ), 'E', 'OFG', 13);
        ELSIF (constraint_name = 'IRP_IR2_FK') THEN
          Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(13, 'This <p1> does not exist', 'Rule Isn' ), 'E', 'OFG', 13);
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
      Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(35, 'Query of <p1> must be in context of <p2>', 'جمارك الاستثناء','استثناءات المستوردين' ), 'E', 'OFG', 35);
      Des$Form_errors.RAISE_FAILURE;
    ELSIF (err_code = 41106) THEN
      Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(36, 'Insert of <p1> must be in context of <p2>', 'جمارك الاستثناء','استثناءات المستوردين' ), 'E', 'OFG', 36);
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

#### IMPR_RULE_PORTS · KEY-HELP

- Level: Block · Owner: `IMPR_RULE_PORTS` · Execution hierarchy: default (Override) · Fire in query: true
- Lines: 32 total / 30 active (non-blank, non-comment)
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
END;
```

#### IMPR_RULE_PORTS · PRE-DELETE

- Level: Block · Owner: `IMPR_RULE_PORTS` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 6 total / 5 active (non-blank, non-comment)
- Built-ins: RAISE FORM_TRIGGER_FAILURE
- Program units (form): –
- Library / DB package calls: ACTIVITY.ADD_ACTIVITY

```plsql
BEGIN
	IF NOT ACTIVITY.ADD_ACTIVITY(9, 5, 3, :IMPR_RULE_PORTS.RULE_ISN||'!'||:IMPR_RULE_PORTS.PORT_CD)	THEN
		RAISE FORM_TRIGGER_FAILURE;
	END IF;

END;
```

#### IMPR_RULE_PORTS · PRE-INSERT

- Level: Block · Owner: `IMPR_RULE_PORTS` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 7 total / 5 active (non-blank, non-comment)
- Built-ins: RAISE FORM_TRIGGER_FAILURE
- Program units (form): –
- Library / DB package calls: ACTIVITY.ADD_ACTIVITY

```plsql
BEGIN

	IF NOT ACTIVITY.ADD_ACTIVITY(9, 5, 1, :IMPR_RULE_PORTS.RULE_ISN||'!'||:IMPR_RULE_PORTS.PORT_CD)	 THEN
		RAISE FORM_TRIGGER_FAILURE;
	END IF;

END;
```

#### IMPR_RULE_PORTS · PRE-RECORD

- Level: Block · Owner: `IMPR_RULE_PORTS` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 8 total / 7 active (non-blank, non-comment)
- Built-ins: SET_BLOCK_PROPERTY
- Program units (form): –
- Library / DB package calls: –

```plsql
BEGIN
IF :IMPR_RULES.ALL_BRNCH_FLAG = 1  THEN
	SET_BLOCK_PROPERTY('IMPR_RULE_PORTS', INSERT_ALLOWED, PROPERTY_FALSE);
ELSE
	SET_BLOCK_PROPERTY('IMPR_RULE_PORTS', INSERT_ALLOWED, PROPERTY_TRUE);
END IF;

END;
```

#### IMPR_RULE_PORTS · PRE-UPDATE

- Level: Block · Owner: `IMPR_RULE_PORTS` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 5 total / 5 active (non-blank, non-comment)
- Built-ins: RAISE FORM_TRIGGER_FAILURE
- Program units (form): –
- Library / DB package calls: ACTIVITY.ADD_ACTIVITY

```plsql
BEGIN
	IF NOT ACTIVITY.ADD_ACTIVITY(9, 5, 2, :IMPR_RULE_PORTS.RULE_ISN||'!'||:IMPR_RULE_PORTS.PORT_CD)	THEN
		RAISE FORM_TRIGGER_FAILURE;
	END IF;
END;
```

#### IMPR_RULE_PORTS · WHEN-NEW-RECORD-INSTANCE

- Level: Block · Owner: `IMPR_RULE_PORTS` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 8 total / 7 active (non-blank, non-comment)
- Built-ins: SET_BLOCK_PROPERTY
- Program units (form): –
- Library / DB package calls: –

```plsql
BEGIN
IF :IMPR_RULES.ALL_BRNCH_FLAG = 1  THEN
	SET_BLOCK_PROPERTY('IMPR_RULE_PORTS', INSERT_ALLOWED, PROPERTY_FALSE);
ELSE
	SET_BLOCK_PROPERTY('IMPR_RULE_PORTS', INSERT_ALLOWED, PROPERTY_TRUE);
END IF;

END;
```

#### IMPR_RULE_TARIFF · ON-ERROR

- Level: Block · Owner: `IMPR_RULE_TARIFF` · Execution hierarchy: default (Override) · Fire in query: true
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
        IF (constraint_name = 'IRT_IR_FK') THEN
          Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(13, 'This <p1> does not exist', 'رقم مسلسل الإستثناء' ), 'E', 'OFG', 13);
        ELSIF (constraint_name = 'IRT_HT_FK') THEN
          Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(13, 'This <p1> does not exist', 'رمز بند التعريفة' ), 'E', 'OFG', 13);
        ELSE
          Des$Form_errors.PUSH(server_msg, 'I', 'OFG', 0);
        END IF;
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
        err_code IN (41105, 41106) ) THEN
      IF (err_code = 41105) THEN
      Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(35, 'Query of <p1> must be in context of <p2>', 'Impr Rule Tariff','استثناءات المستوردين' ), 'E', 'OFG', 35);
      Des$Form_errors.RAISE_FAILURE;
    ELSIF (err_code = 41106) THEN
      Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(36, 'Insert of <p1> must be in context of <p2>', 'Impr Rule Tariff','استثناءات المستوردين' ), 'E', 'OFG', 36);
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

#### IMPR_RULE_TARIFF · KEY-HELP

- Level: Block · Owner: `IMPR_RULE_TARIFF` · Execution hierarchy: default (Override) · Fire in query: true
- Lines: 32 total / 30 active (non-blank, non-comment)
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
END;
```

#### IMPR_RULE_TARIFF · POST-QUERY

- Level: Block · Owner: `IMPR_RULE_TARIFF` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 18 total / 17 active (non-blank, non-comment)
- Built-ins: –
- Program units (form): –
- Library / DB package calls: –

```plsql
DECLARE
	V_INTL_UNIT NUMBER;
BEGIN
	SELECT TRF_INTL_UNIT INTO V_INTL_UNIT
	FROM   TARIFF_DETAILS
	WHERE  HRMNZD_CODE = :IMPR_RULE_TARIFF.HRMNZD_CODE
	AND    EFF_DATE 	 =  (SELECT MAX(EFF_DATE) FROM TARIFF_DETAILS
				     WHERE HRMNZD_CODE = :IMPR_RULE_TARIFF.HRMNZD_CODE
				    )
	;

	SELECT IMSR_ARBC_NAME INTO :INTL_UNIT
	FROM   INTL_MSR_UNITS
	WHERE  INTL_MSR_UNIT = 	V_INTL_UNIT
	AND    IMSR_STATUS   =  1
	;
EXCEPTION WHEN NO_DATA_FOUND THEN NULL;
END;
```

#### IMPR_RULE_TARIFF · PRE-DELETE

- Level: Block · Owner: `IMPR_RULE_TARIFF` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 5 total / 5 active (non-blank, non-comment)
- Built-ins: RAISE FORM_TRIGGER_FAILURE
- Program units (form): –
- Library / DB package calls: ACTIVITY.ADD_ACTIVITY

```plsql
BEGIN
	IF NOT ACTIVITY.ADD_ACTIVITY(9, 6, 3, :IMPR_RULES.RULE_ISN||'!'||:IMPR_RULE_TARIFF.HRMNZD_CODE)	THEN
		RAISE FORM_TRIGGER_FAILURE;
	END IF;
END;
```

#### IMPR_RULE_TARIFF · PRE-INSERT

- Level: Block · Owner: `IMPR_RULE_TARIFF` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 19 total / 13 active (non-blank, non-comment)
- Built-ins: RAISE FORM_TRIGGER_FAILURE
- Program units (form): –
- Library / DB package calls: ACTIVITY.ADD_ACTIVITY

```plsql
DECLARE
	MAX_ITEM_SEQUENCE   NUMBER;
BEGIN
	SELECT NVL(MAX(ITEM_SEQUENCE),0)  INTO MAX_ITEM_SEQUENCE FROM IMPR_RULE_TARIFF
      WHERE RULE_ISN=:IMPR_RULE_TARIFF.RULE_ISN;

	:IMPR_RULE_TARIFF.ITEM_SEQUENCE := MAX_ITEM_SEQUENCE+1 ;

IF :IMPR_RULE_TARIFF.REC_STATUS  IS NULL THEN

--
:IMPR_RULE_TARIFF.REC_STATUS := 1;

END IF;
----
	IF NOT ACTIVITY.ADD_ACTIVITY(9, 6, 1, :IMPR_RULES.RULE_ISN||'!'||:IMPR_RULE_TARIFF.HRMNZD_CODE)	THEN
		RAISE FORM_TRIGGER_FAILURE;
	END IF;
END;
```

#### IMPR_RULE_TARIFF · PRE-UPDATE

- Level: Block · Owner: `IMPR_RULE_TARIFF` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 5 total / 5 active (non-blank, non-comment)
- Built-ins: RAISE FORM_TRIGGER_FAILURE
- Program units (form): –
- Library / DB package calls: ACTIVITY.ADD_ACTIVITY

```plsql
BEGIN
	IF NOT ACTIVITY.ADD_ACTIVITY(9, 6, 2, :IMPR_RULES.RULE_ISN||'!'||:IMPR_RULE_TARIFF.HRMNZD_CODE)	THEN
		RAISE FORM_TRIGGER_FAILURE;
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

#### IMPR_RULES.RULE_ISN · KEY-LISTVAL

- Level: Item · Owner: `IMPR_RULES.RULE_ISN` · Execution hierarchy: default (Override)
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

#### IMPR_RULES.D · KEY-LISTVAL

- Level: Item · Owner: `IMPR_RULES.D` · Execution hierarchy: default (Override)
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

#### IMPR_RULES.RULE_TYPE · WHEN-LIST-CHANGED

- Level: Item · Owner: `IMPR_RULES.RULE_TYPE` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 6 total / 6 active (non-blank, non-comment)
- Built-ins: RAISE FORM_TRIGGER_FAILURE
- Program units (form): –
- Library / DB package calls: STR.DISPALERT

```plsql
BEGIN
IF :IMPR_RULES.RULE_TYPE = 9 THEN
STR.DISPALERT('هذا النوع غير مستخدم','ERROR');
RAISE FORM_TRIGGER_FAILURE;
END IF;
END;
```

#### IMPR_RULES.RULE_TYPE · WHEN-VALIDATE-ITEM

- Level: Item · Owner: `IMPR_RULES.RULE_TYPE` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 6 total / 6 active (non-blank, non-comment)
- Built-ins: RAISE FORM_TRIGGER_FAILURE
- Program units (form): –
- Library / DB package calls: STR.DISPALERT

```plsql
BEGIN
IF :IMPR_RULES.RULE_TYPE = 9 THEN
STR.DISPALERT('هذا النوع غير مستخدم','ERROR');
RAISE FORM_TRIGGER_FAILURE;
END IF;
END;
```

#### IMPR_RULES.ALL_BRNCH_FLAG · WHEN-VALIDATE-ITEM

- Level: Item · Owner: `IMPR_RULES.ALL_BRNCH_FLAG` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 4 total / 3 active (non-blank, non-comment)
- Built-ins: –
- Program units (form): ADJ_BRANCH
- Library / DB package calls: –

```plsql
BEGIN
	ADJ_BRANCH;

END;
```

#### IMPR_RULES.HQ_IMPR_NBR · KEY-LISTVAL

- Level: Item · Owner: `IMPR_RULES.HQ_IMPR_NBR` · Execution hierarchy: default (Override)
- Lines: 37 total / 35 active (non-blank, non-comment)
- Built-ins: GET_BLOCK_PROPERTY, GET_ITEM_PROPERTY, GET_RECORD_PROPERTY, RAISE FORM_TRIGGER_FAILURE
- Program units (form): SINGLE_IMP_LOV
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

BEGIN
	SINGLE_IMP_LOV;
END;
```

#### IMPR_RULES.HQ_IMPR_NBR · WHEN-VALIDATE-ITEM

- Level: Item · Owner: `IMPR_RULES.HQ_IMPR_NBR` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 50 total / 30 active (non-blank, non-comment)
- Built-ins: RAISE FORM_TRIGGER_FAILURE
- Program units (form): –
- Library / DB package calls: STR.DISPALERT

```plsql
/*
BEGIN
	IF :HQ_IMPR_NBR IS NOT NULL THEN
		SELECT BUS_ID, BUS_ID_BRNCH, BUS_ID_TYPE_CD, ARBC_IMPR_NAME
		INTO   :BUS_ID, :BUS_ID_BRNCH, :BUS_ID_TYPE_CD, :L_SI_ARBC_IMPR_NAME
		FROM   SINGLE_IMPORTERS
		WHERE  HQ_IMPR_NBR = :HQ_IMPR_NBR;


		SELECT BUS_ID_TYPE_NAME INTO :BUS_ID_TYPE_NAME FROM BUS_ID_TYPES WHERE BUS_ID_TYPE_CD = :BUS_ID_TYPE_CD;
	END IF;
EXCEPTION
	WHEN OTHERS THEN
		STR.DISPALERT('رقم المستورد المدخل غير صحيح، أدخل الرقم الصحيح أو استخدم القائمة المرفقة','ERROR');
		RAISE FORM_TRIGGER_FAILURE;
END;
*/


BEGIN
   IF :hq_impr_nbr IS NOT NULL
   THEN
      IF :impr_rules.rule_type = 12
      THEN
         SELECT bus_id, bus_id_brnch, bus_id_type_cd, arbc_impr_name
           INTO :bus_id, :bus_id_brnch, :bus_id_type_cd, :l_si_arbc_impr_name
           FROM importers
          WHERE PORT_CD = :PARAMETER.P_CURR_PORT_CD -- NALSALEH CENTRALIZED PROJECT
	    AND hq_impr_nbr = :hq_impr_nbr AND ROWNUM = 1;
      ELSE
         SELECT bus_id, bus_id_brnch, bus_id_type_cd, arbc_impr_name
           INTO :bus_id, :bus_id_brnch, :bus_id_type_cd, :l_si_arbc_impr_name
           FROM single_importers
          WHERE hq_impr_nbr = :hq_impr_nbr;
      END IF;

      SELECT bus_id_type_name
        INTO :bus_id_type_name
        FROM bus_id_types
       WHERE bus_id_type_cd = :bus_id_type_cd;
   END IF;
EXCEPTION
   WHEN OTHERS
   THEN
      str.dispalert
         ('رقم المستورد المدخل غير صحيح، أدخل الرقم الصحيح أو استخدم القائمة المرفقة',
          'ERROR'
         );
      RAISE form_trigger_failure;
END;
```

#### IMPR_RULES.B_IMP · WHEN-BUTTON-PRESSED

- Level: Item · Owner: `IMPR_RULES.B_IMP` · Execution hierarchy: default (Override)
- Lines: 7 total / 5 active (non-blank, non-comment)
- Built-ins: DO_KEY, GO_ITEM
- Program units (form): –
- Library / DB package calls: –

```plsql
/* CGAP$OLES_SEQUENCE_BEFORE */
NULL;

BEGIN
	GO_ITEM('HQ_IMPR_NBR');
	DO_KEY('LIST_VALUES');
END;
```

#### IMPR_RULES.L_SI_ARBC_IMPR_NAME · KEY-LISTVAL

- Level: Item · Owner: `IMPR_RULES.L_SI_ARBC_IMPR_NAME` · Execution hierarchy: default (Override)
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

#### IMPR_RULES.BUS_ID_TYPE_CD · KEY-LISTVAL

- Level: Item · Owner: `IMPR_RULES.BUS_ID_TYPE_CD` · Execution hierarchy: default (Override)
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

#### IMPR_RULES.BUS_ID_TYPE_NAME · KEY-LISTVAL

- Level: Item · Owner: `IMPR_RULES.BUS_ID_TYPE_NAME` · Execution hierarchy: default (Override)
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

#### IMPR_RULES.BUS_ID · KEY-LISTVAL

- Level: Item · Owner: `IMPR_RULES.BUS_ID` · Execution hierarchy: default (Override)
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

#### IMPR_RULE_PORTS.PORT_CD · KEY-LISTVAL

- Level: Item · Owner: `IMPR_RULE_PORTS.PORT_CD` · Execution hierarchy: default (Override)
- Lines: 37 total / 35 active (non-blank, non-comment)
- Built-ins: GET_BLOCK_PROPERTY, GET_ITEM_PROPERTY, GET_RECORD_PROPERTY, RAISE FORM_TRIGGER_FAILURE
- Program units (form): CALL_SD_PORTS
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

BEGIN
	CALL_SD_PORTS ;
END;
```

#### IMPR_RULE_PORTS.PORT_CD · WHEN-VALIDATE-ITEM

- Level: Item · Owner: `IMPR_RULE_PORTS.PORT_CD` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 17 total / 15 active (non-blank, non-comment)
- Built-ins: NAME_IN
- Program units (form): CGFK$CHK_IMPR_RULE_PORTS_IRP_S
- Library / DB package calls: CGTE$OTHER_EXCEPTIONS, DES$FORM_ERRORS.MSGGETTEXT, DES$FORM_ERRORS.PUSH, DES$FORM_ERRORS.RAISE_FAILURE

```plsql
/* CGFK$VALDIDATE_FK_OVF */
/* Check that foreign key value exists in referenced table */
BEGIN
  IF (name_in('IMPR_RULE_PORTS.PORT_CD') IS NOT NULL) THEN
    BEGIN
      CGFK$CHK_IMPR_RULE_PORTS_IRP_S(
        :IMPR_RULE_PORTS.PORT_NAME    /* MOD: Value in Item :IMPR_RULE_PORTS.PORT_NAME.                                                                                                                                                       */
       ,:IMPR_RULE_PORTS.PORT_CD  );  /* IN : Value in Item :IMPR_RULE_PORTS.PORT_CD.                                                                                                                                                         */
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(13, 'This <p1> does not exist', 'رمز الجمرك' ), 'E', 'OFG', 13);
        Des$Form_errors.RAISE_FAILURE;
      WHEN OTHERS THEN
        CGTE$OTHER_EXCEPTIONS;
    END;
  END IF;
END;
```

#### IMPR_RULE_PORTS.PORT_CD2 · WHEN-BUTTON-PRESSED

- Level: Item · Owner: `IMPR_RULE_PORTS.PORT_CD2` · Execution hierarchy: default (Override) · Fire in query: true
- Lines: 6 total / 4 active (non-blank, non-comment)
- Built-ins: DO_KEY, GO_ITEM
- Program units (form): –
- Library / DB package calls: –

```plsql
/* CGLY$WHEN_BUTTON_PRESSED */
/* Replicate default menu functionality */
BEGIN
  go_item('IMPR_RULE_PORTS.PORT_CD');
  do_key('List_values');
END;
```

#### IMPR_RULE_PORTS.PORT_NAME · KEY-LISTVAL

- Level: Item · Owner: `IMPR_RULE_PORTS.PORT_NAME` · Execution hierarchy: default (Override)
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

#### IMPR_RULE_TARIFF.HRMNZD_CODE · KEY-LISTVAL

- Level: Item · Owner: `IMPR_RULE_TARIFF.HRMNZD_CODE` · Execution hierarchy: default (Override)
- Lines: 38 total / 35 active (non-blank, non-comment)
- Built-ins: GET_BLOCK_PROPERTY, GET_ITEM_PROPERTY, GET_RECORD_PROPERTY, RAISE FORM_TRIGGER_FAILURE
- Program units (form): DSP_TRF_ITEMS_LOV
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

BEGIN
dsp_trf_items_lov;
END;
```

#### IMPR_RULE_TARIFF.HRMNZD_CODE · POST-CHANGE

- Level: Item · Owner: `IMPR_RULE_TARIFF.HRMNZD_CODE` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 9 total / 9 active (non-blank, non-comment)
- Built-ins: –
- Program units (form): –
- Library / DB package calls: –

```plsql
BEGIN
SELECT item_arbc_desc
INTO :HT_ITEM_ARBC_DESC
FROM   harmonized_tariff
 WHERE hrmnzd_code = :IMPR_RULE_TARIFF.HRMNZD_CODE;
exception
	WHEN OTHERS THEN
		NULL;
END;
```

#### IMPR_RULE_TARIFF.HRMNZD_CODE · WHEN-VALIDATE-ITEM

- Level: Item · Owner: `IMPR_RULE_TARIFF.HRMNZD_CODE` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 107 total / 66 active (non-blank, non-comment)
- Built-ins: RAISE FORM_TRIGGER_FAILURE
- Program units (form): –
- Library / DB package calls: STR.DISPALERT

```plsql
DECLARE
    CURSOR C IS
      SELECT HT.ITEM_ARBC_DESC,TARIFF_DETAILS.FILLER1,TARIFF_DETAILS.FILLER2,TARIFF_DETAILS.STA_CODE
      FROM   HARMONIZED_TARIFF HT,TARIFF_DETAILS
      WHERE  HT.HRMNZD_CODE = :IMPR_RULE_TARIFF.HRMNZD_CODE
		AND
		HT.HRMNZD_CODE=TARIFF_DETAILS.HRMNZD_CODE AND TARIFF_DETAILS.STA_CODE=0;

 V_FILLER1 		VARCHAR2(10);
 V_FILLER2 		VARCHAR2(10);
 V_STA_CODE 	NUMBER;
 V_INTL_UNIT 	NUMBER;
  BEGIN
    OPEN C;
    FETCH C
    INTO    :HT_ITEM_ARBC_DESC,V_FILLER1,V_FILLER2, V_STA_CODE;
    IF C%NOTFOUND THEN
      CLOSE C;
      STR.DISPALERT ('رمز بند التعرفة غير موجود ','ERROR');
      RAISE NO_DATA_FOUND;
    ELSE
--,TARIFF_DETAILS.TRF_INTL_UNIT ,,V_INTL_UNIT
--====================================================================================
/*-----tabbaa
	IF V_FILLER1 IN ('2','4') AND :IMPR_RULES.RULE_TYPE = 10 THEN
		      STR.DISPALERT ('هذا البند لايسمح ادخاله ضمن بنود الاستثناء','ERROR');
    			RAISE FORM_TRIGGER_FAILURE;
 	ELSIF  V_FILLER1 IN ('3','4') AND :IMPR_RULES.RULE_TYPE = 11 THEN
		      STR.DISPALERT ('هذا البند لايسمح ادخاله ضمن بنود الاستثناء','ERROR');
    			RAISE FORM_TRIGGER_FAILURE;
      ELSIF  V_FILLER1 NOT IN ('2','3','4') AND :IMPR_RULES.RULE_TYPE NOT IN (10,11) THEN
		      STR.DISPALERT ('هذا البند لايسمح ادخاله ضمن بنود الاستثناء','ERROR');
    			RAISE FORM_TRIGGER_FAILURE;
	ELSIF V_FILLER2!='1'THEN
			STR.DISPALERT ('هذا البند غير ساري','ERROR');
    			RAISE FORM_TRIGGER_FAILURE;
	END IF;
*/
--====================================================================================

/*-----current
	IF V_FILLER1 NOT IN ('2','4') AND :IMPR_RULES.RULE_TYPE = 10 THEN
		      STR.DISPALERT ('هذا البند لايسمح ادخاله ضمن بنود الاستثناء','ERROR');
    			RAISE FORM_TRIGGER_FAILURE;
 	ELSIF  V_FILLER1 NOT IN ('3','4') AND :IMPR_RULES.RULE_TYPE = 11 THEN
		      STR.DISPALERT ('هذا البند لايسمح ادخاله ضمن بنود الاستثناء','ERROR');
    			RAISE FORM_TRIGGER_FAILURE;
      ELSIF  V_FILLER1 NOT IN ('2','3','4') AND :IMPR_RULES.RULE_TYPE NOT IN (10,11) THEN
		      STR.DISPALERT ('هذا البند لايسمح ادخاله ضمن بنود الاستثناء','ERROR');
    			RAISE FORM_TRIGGER_FAILURE;
	ELSIF V_FILLER2!='1'THEN
			STR.DISPALERT ('هذا البند غير ساري','ERROR');
    			RAISE FORM_TRIGGER_FAILURE;
	END IF;
*/
--====================================================================================
     BEGIN
		SELECT TRF_INTL_UNIT INTO V_INTL_UNIT
		FROM   TARIFF_DETAILS
		WHERE  HRMNZD_CODE = :IMPR_RULE_TARIFF.HRMNZD_CODE
		AND    EFF_DATE 	 =  (SELECT MAX(EFF_DATE) FROM TARIFF_DETAILS
					     WHERE HRMNZD_CODE = :IMPR_RULE_TARIFF.HRMNZD_CODE
					    )
		;

		SELECT IMSR_ARBC_NAME INTO :INTL_UNIT
		FROM   INTL_MSR_UNITS
		WHERE  INTL_MSR_UNIT = 	V_INTL_UNIT
		AND    IMSR_STATUS   =  1
		;
     EXCEPTION WHEN NO_DATA_FOUND THEN
		STR.DISPALERT(' الوحدة الدولية غير معرفة .. راجع الدعم الفني ','ERROR');
     END;

     END IF;
    CLOSE C;
  END;

DECLARE
   v_count   NUMBER;
BEGIN
   BEGIN
      SELECT COUNT (1)
        INTO v_count
        FROM DUAL
       WHERE EXISTS (
                SELECT 1
                  FROM impr_rules, impr_rule_tariff
                 WHERE impr_rules.rule_isn = impr_rule_tariff.rule_isn
                   AND impr_rules.hq_impr_nbr = :impr_rules.hq_impr_nbr
                   AND impr_rules.bus_id_type_cd = :impr_rules.bus_id_type_cd
                   AND impr_rules.bus_id = :impr_rules.bus_id
                   AND impr_rule_tariff.hrmnzd_code = :impr_rule_tariff.hrmnzd_code
                   AND impr_rule_tariff.remained_qty > 0
                   AND impr_rule_tariff.rec_status = 1
                   AND (:impr_rules.rule_isn IS NULL OR impr_rules.rule_isn <> :impr_rules.rule_isn));
   EXCEPTION
      WHEN OTHERS THEN
         v_count := 0;
   END;

   IF NVL (v_count, 0) > 0 THEN
      STR.DISPALERT ('هذا البند تم ادخاله من قبل لنفس المستورد','ERROR');
			RAISE FORM_TRIGGER_FAILURE;
   END IF;
END;
```

#### IMPR_RULE_TARIFF.HRMNZD_CODE2 · WHEN-BUTTON-PRESSED

- Level: Item · Owner: `IMPR_RULE_TARIFF.HRMNZD_CODE2` · Execution hierarchy: default (Override) · Fire in query: true
- Lines: 6 total / 4 active (non-blank, non-comment)
- Built-ins: DO_KEY, GO_ITEM
- Program units (form): –
- Library / DB package calls: –

```plsql
/* CGLY$WHEN_BUTTON_PRESSED */
/* Replicate default menu functionality */
BEGIN
  go_item('IMPR_RULE_TARIFF.HRMNZD_CODE');
  do_key('List_values');
END;
```

#### IMPR_RULE_TARIFF.HT_ITEM_ARBC_DESC · KEY-LISTVAL

- Level: Item · Owner: `IMPR_RULE_TARIFF.HT_ITEM_ARBC_DESC` · Execution hierarchy: default (Override)
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

#### IMPR_RULE_TARIFF.EXEPTION_QTY · WHEN-VALIDATE-ITEM

- Level: Item · Owner: `IMPR_RULE_TARIFF.EXEPTION_QTY` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 4 total / 4 active (non-blank, non-comment)
- Built-ins: –
- Program units (form): –
- Library / DB package calls: STR.DISPALERT

```plsql
BEGIN
:REMAINED_QTY:=:EXEPTION_QTY;
	STR.DISPALERT(' تأكد من تطابق الوحده الدولية مع وحدة الكمية المستثناه ','INFORMATION');
END;
```

#### IMPR_RULE_TARIFF.REMAINED_QTY · KEY-LISTVAL

- Level: Item · Owner: `IMPR_RULE_TARIFF.REMAINED_QTY` · Execution hierarchy: default (Override)
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

#### IMPR_RULE_TARIFF.INTL_UNIT · KEY-LISTVAL

- Level: Item · Owner: `IMPR_RULE_TARIFF.INTL_UNIT` · Execution hierarchy: default (Override)
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

#### IMPR_RULE_TARIFF.ITEM_SEQUENCE · KEY-LISTVAL

- Level: Item · Owner: `IMPR_RULE_TARIFF.ITEM_SEQUENCE` · Execution hierarchy: default (Override)
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
| CGFK$IMPR_RULE_PORTS_PORT_CD | Valid values for رمز الجمرك | CGFK$IMPR_RULE_PORTS_PORT_CD | PORT_CD → IMPR_RULE_PORTS.PORT_CD; PORT_NAME → IMPR_RULE_PORTS.PORT_NAME; PORT_STATUS → (not returned) | IMPR_RULE_PORTS.PORT_CD | not in XML (item property `ValidateFromList` absent → default/OLB) | default/OLB |
| CGFK$IMPR_RULE_TARIFF_HRMNZD_C | Valid values for رمز بند التعريفة | CGFK$IMPR_RULE_TARIFF_HRMNZD_C | HRMNZD_CODE → IMPR_RULE_TARIFF.HRMNZD_CODE; HT_ITEM_ARBC_DESC → IMPR_RULE_TARIFF.HT_ITEM_ARBC_DESC | IMPR_RULE_TARIFF.HRMNZD_CODE | not in XML (item property `ValidateFromList` absent → default/OLB) | default/OLB |

### 7.1 Record groups

#### CGFK$IMPR_RULE_PORTS_PORT_CD
- Type: Query · Attached to LOV: yes
- Columns: PORT_CD Number(3), PORT_NAME (40), PORT_STATUS Number(1)

```sql
SELECT SDP.PORT_CD  PORT_CD  /* CG$FK */
      ,SDP.PORT_NAME  PORT_NAME
      ,SDP.PORT_STATUS  PORT_STATUS
FROM   SD_PORTS SDP
```


#### CGLT$CVS_DATA
- Type: Static · Attached to LOV: NO
- Columns: NAME (50), MASTER_TAB (50), PAGE (50), WINDOW (50), STACK_CANVAS (2000), BLOCKS (2000), NAV_ITEM (100), EXTRA_TEXT (500)
- Static values: {"Index": "1", "Value": "CG$M_TAB_1_PAGE_1"}; {"Index": "2", "Value": "CG$M_TAB_1_PAGE_2"}; {"Index": "1", "Value": "CG$M_TAB_1"}; {"Index": "2", "Value": "CG$M_TAB_1"}; {"Index": "1", "Value": "CG$PAGE_1"}; {"Index": "2", "Value": "CG$PAGE_1"}; {"Index": "1", "Value": "CGSO$WINDOW_1"}; {"Index": "2", "Value": "CGSO$WINDOW_1"}; {"Index": "1", "Value": ""}; {"Index": "2", "Value": ""}; {"Index": "1", "Value": "IMPR_RULE_PORTS"}; {"Index": "2", "Value": "IMPR_RULE_TARIFF"}; {"Index": "1", "Value": "IMPR_RULE_PORTS.PORT_CD"}; {"Index": "2", "Value": "IMPR_RULE_TARIFF.HRMNZD_CODE"}; {"Index": "1", "Value": ""}; {"Index": "2", "Value": ""}


#### CGFK$IMPR_RULE_TARIFF_HRMNZD_C
- Type: Query · Attached to LOV: yes
- Columns: HRMNZD_CODE (16), HT_ITEM_ARBC_DESC (1000)

```sql
SELECT HT.HRMNZD_CODE  HRMNZD_CODE  /* CG$FK */
      ,HT.ITEM_ARBC_DESC  HT_ITEM_ARBC_DESC
FROM   HARMONIZED_TARIFF HT
```


> **LOV notes**
> - `CGFK$IMPR_RULE_PORTS_PORT_CD` (SD_PORTS) and `CGFK$IMPR_RULE_TARIFF_HRMNZD_C` (HARMONIZED_TARIFF) are Designer FK lookups attached to their items, but KEY-LISTVAL replaces them with the LOV forms `LOV_SD_PORTS` (active ports, `PORT_TYPE = :P_PORT_TYPE`, `STATUS = 1`) and `LOV_TRF_ITEMS` (tariff dictionary search, returns `:GLOBAL.HRMNZD_CODE`).
> - `HQ_IMPR_NBR` has no Forms LOV; `SINGLE_IMP_LOV` calls `LOV_IMPORT_HQ_NBR` (block on `SINGLE_IMPORTERS`) or, for rule type 12, `LOV_IMPORT_HQ_N12` (block on `IMPORTERS`); both return `HQ_IMPR_NBR`, `BUS_ID`, `ARBC_IMPR_NAME` through globals.
> - `CALL_IMPR_TYPE` (`LOV_Impr_Type`) is defined but called by no trigger.
> - Runtime record group `CGDV$DLRG` fills 4 list items from `CG_REF_CODES` (`RULE_TYPE`, and `REC_STATUS` three times) → shared LOVs on `CG_REF_CODES`. `CGLT$CVS_DATA` is Designer tab metadata, not a list.

## 8. Canvases & Windows

| Canvas | Type | Window | Size (W×H) | Viewport | Tab pages | Items shown | Subclassed from |
|---|---|---|---|---|---|---|---|
| LSIDE | Content (default) / OLB | default/OLB | – | – | – | 0: – | CIC_OLB.olb:LSIDE |
| EDI_MSG | Content (default) / OLB | default/OLB | – | – | – | 0: – | CIC_OLB.olb:EDI_MSG |
| TITLE | Content (default) / OLB | default/OLB | – | – | – | 0: – | CIC_OLB.olb:TITLE |
| TOOLBAR | Content (default) / OLB | default/OLB | – | – | – | 0: – | CIC_OLB.olb:TOOLBAR |
| CG$PAGE_1 | Content (default) / OLB | CGSO$WINDOW_1 | 8510×4974 | 0×5531 | – | 12: RULE_ISN, D, RULE_TYPE, ALL_BRNCH_FLAG, HQ_IMPR_NBR, B_IMP, L_SI_ARBC_IMPR_NAME, REC_STATUS, BUS_ID_TYPE_CD, BUS_ID_TYPE_NAME, BUS_ID, BUS_ID_BRNCH | cic_olb.olb:CGSO$CANVAS |
| CG$M_TAB_1 | Content (default) / OLB | default/OLB | 8593×3197 | 8593×3197 | CG$M_TAB_1_PAGE_1, CG$M_TAB_1_PAGE_2 | 11: PORT_CD, PORT_CD2, PORT_NAME, REC_STATUS, HRMNZD_CODE, HRMNZD_CODE2, HT_ITEM_ARBC_DESC, EXEPTION_QTY, REMAINED_QTY, INTL_UNIT, REC_STATUS | cic_olb.olb:CGSO$CANVAS_TAB |

| Window | Modal | Title | Size | Subclassed from |
|---|---|---|---|---|
| CGSO$WINDOW_1 | default/OLB | قواعد التعامل مع المستوردين | default/OLB | cic_olb.olb:CGSO$WINDOW_1 |

Graphics objects on canvases (boilerplate, from XML):

| Canvas | Name | Type | Subclassed from |
|---|---|---|---|
| LSIDE | LINE617 | not in XML (OLB sub-object) | – |
| TITLE | RECT9 | not in XML (OLB sub-object) | – |
| TITLE | RECT10 | not in XML (OLB sub-object) | – |
| CG$PAGE_1 | CG_BOILERPLATE_GROUP | Group | – |
| CG$PAGE_1 | CG_RECT_1 | not in XML (OLB sub-object) | CIC_OLB.OLB:CG_RECT |
| CG$M_TAB_1 | CG_BOILERPLATE_GROUP | Group | – |
| CG$M_TAB_1 | CG_RECT_1 | not in XML (OLB sub-object) | CIC_OLB.OLB:CG_RECT |
| CG$M_TAB_1 | CG_BOILERPLATE_GROUP | Group | – |
| CG$M_TAB_1 | CG_RECT_1 | not in XML (OLB sub-object) | CIC_OLB.OLB:CG_RECT |

> **Canvas/Window notes**
> - `LSIDE`, `EDI_MSG`, `TITLE`, `TOOLBAR` and window `CGSO$WINDOW_1` (title "قواعد التعامل مع المستوردين") come from `CIC_OLB.olb`: the screen frame, not migrated.
> - `CG$PAGE_1` holds the rule (12 items). The tab canvas `CG$M_TAB_1` has the tab pages `CG$M_TAB_1_PAGE_1` "جمارك الإستثناء" (block IMPR_RULE_PORTS) and `CG$M_TAB_1_PAGE_2` "بنود التعريفة المستثاه" (block IMPR_RULE_TARIFF). In APEX: one main page, a Form region `IMPR_RULES` and a Tabs Container with the two IGs.

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
| 15 | CG$WHEN_NEW_FORM_INSTANCE | Procedure | 37 / 21 | FORM.KEY-CLRFRM, FORM.WHEN-NEW-FORM-INSTANCE | – | CGBS$SET_QUERY_MODE, CGDV$POPULATE_DYNAMIC_LISTS, CGLY$CANVAS_MANAGEMENT | CGBS$.SET_RELATIONS, CGLT$TAB_BLOCKS.CGLT$NEW_BLOCK, CGTE$OTHER_EXCEPTIONS |
| 16 | CGDV$POPULATE_DYNAMIC_LISTS | Procedure | 43 / 37 | PU CG$WHEN_NEW_FORM_INSTANCE | CREATE_GROUP_FROM_QUERY, DELETE_GROUP, POPULATE_GROUP, POPULATE_LIST | – | – |
| 17 | CGFK$QRY_IMPR_RULES_IR_BIT_FK | Procedure | 22 / 20 | IMPR_RULES.POST-QUERY | – | – | – |
| 18 | CGFK$CHK_IMPR_RULES_IR_BIT_FK | Procedure | 22 / 20 | not referenced in XML code | – | – | – |
| 19 | CG$IMPR1140_CNTRL_GLOBALS | Package Spec | 4 / 3 | IMPR_RULES.POST-QUERY, IMPR_RULES.PRE-QUERY | – | – | – |
| 20 | CGFK$QRY_IMPR_RULE_PORTS_IRP_S | Procedure | 22 / 20 | IMPR_RULE_PORTS.POST-QUERY | – | – | – |
| 21 | CGFK$CHK_IMPR_RULE_PORTS_IRP_S | Procedure | 22 / 20 | IMPR_RULE_PORTS.PORT_CD.WHEN-VALIDATE-ITEM | – | – | – |
| 22 | CGFK$CHK_IMPR_RULE_PORTS_IRP_I | Procedure | 22 / 20 | not referenced in XML code | – | – | CG$DUMMY |
| 23 | CGRI$CHK_IMPR_RULES | Procedure | 27 / 22 | IMPR_RULES.KEY-DELREC | – | – | CG$DUMMY, DES$FORM_ERRORS.MSGGETTEXT, DES$FORM_ERRORS.PUSH, DES$FORM_ERRORS.RAISE_FAILURE |
| 24 | CGTE$CHECK_CONSTRAINT_VIO | Function | 45 / 37 | IMPR_RULES.ON-ERROR, IMPR_RULE_PORTS.ON-ERROR, IMPR_RULE_TARIFF.ON-ERROR | – | – | CGTE$STRIP_CONSTRAINT, CGTE$STRIP_FIRST_ERROR, DES$FORM_ERRORS.MSGGETTEXT, DES$FORM_ERRORS.PUSH |
| 25 | CGLY$DISPLAY_CANVASES | Procedure | 25 / 23 | PU CGLY$CANVAS_MANAGEMENT | GET_VIEW_PROPERTY | CGLY$RAISE_CANVAS | – |
| 26 | CGLY$GET_RELATED_CANVASES | Procedure | 16 / 13 | FORM.WHEN-NEW-BLOCK-INSTANCE, PU CGLY$CANVAS_MANAGEMENT | GET_VIEW_PROPERTY | – | – |
| 27 | CGLY$RAISE_CANVAS | Procedure | 10 / 8 | PU CGLY$DISPLAY_CANVASES | SET_VIEW_PROPERTY | – | – |
| 28 | CGLY$CANVAS_MANAGEMENT | Procedure | 20 / 18 | FORM.WHEN-NEW-BLOCK-INSTANCE, PU CG$WHEN_NEW_FORM_INSTANCE | GET_ITEM_PROPERTY, GET_VIEW_PROPERTY, SET_WINDOW_PROPERTY | CGLY$DISPLAY_CANVASES, CGLY$GET_RELATED_CANVASES | – |
| 29 | CGBS$TOGGLE | Procedure | 24 / 15 | FORM.KEY-MENU | – | CGBS$MESSAGE_QUERY_MODE, CGBS$SET_QUERY_MODE | CGBS$.COORD_VISIBLE_BLKS, CGBS$.SET_RELATIONS |
| 30 | CGBS$SET_QUERY_MODE | Procedure | 7 / 5 | PU CG$WHEN_NEW_FORM_INSTANCE, PU CGBS$TOGGLE | – | – | – |
| 31 | CGBS$MESSAGE_QUERY_MODE | Procedure | 11 / 9 | PU CGBS$TOGGLE | – | – | DES$FORM_ERRORS.PUSH |
| 32 | SINGLE_IMP_LOV | Procedure | 46 / 37 | IMPR_RULES.HQ_IMPR_NBR.KEY-LISTVAL | ADD_PARAMETER, CALL_FORM, CREATE_PARAMETER_LIST, DESTROY_PARAMETER_LIST, GET_PARAMETER_LIST, ID_NULL, RAISE FORM_TRIGGER_FAILURE | – | STR.DISPALERT |
| 33 | EXEC_FUNS | Procedure | 4 / 4 | PU EXECUTE_FUNCTION | – | – | – |
| 34 | DSP_TRF_ITEMS_LOV | Procedure | 50 / 42 | IMPR_RULE_TARIFF.HRMNZD_CODE.KEY-LISTVAL | ADD_PARAMETER, CALL_FORM, CREATE_PARAMETER_LIST, DESTROY_PARAMETER_LIST, GET_PARAMETER_LIST, ID_NULL, RAISE FORM_TRIGGER_FAILURE | – | STR.DISPALERT |
| 35 | CHECK_FASH_ROLE_ID | Function | 34 / 33 | IMPR_RULES.PRE-INSERT, IMPR_RULES.PRE-UPDATE | – | – | – |
| 36 | CALL_SD_PORTS | Procedure | 41 / 33 | IMPR_RULE_PORTS.PORT_CD.KEY-LISTVAL | ADD_PARAMETER, CALL_FORM, CREATE_PARAMETER_LIST, DESTROY_PARAMETER_LIST, GET_PARAMETER_LIST, ID_NULL, RAISE FORM_TRIGGER_FAILURE | – | STR.DISPALERT |
| 37 | CALL_IMPR_TYPE | Procedure | 45 / 31 | not referenced in XML code | ADD_PARAMETER, CALL_FORM, CREATE_PARAMETER_LIST, DESTROY_PARAMETER_LIST, GET_PARAMETER_LIST, ID_NULL, RAISE FORM_TRIGGER_FAILURE | – | STR.DISPALERT |
| 38 | ADJ_FUNS | Procedure | 4 / 4 | FORM.KEY-F9, TOOLBAR.FUN_BUT.WHEN-MOUSE-DOWN | – | – | – |
| 39 | ADJ_BRANCH | Procedure | 10 / 9 | IMPR_RULES.ALL_BRNCH_FLAG.WHEN-VALIDATE-ITEM, IMPR_RULES.WHEN-NEW-RECORD-INSTANCE | – | – | INTRFACE.MAKE_FIELD_ENTRABLE |

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

### PU CG$WHEN_NEW_FORM_INSTANCE (Procedure, 37 lines)

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

/* CGLY$INIT_CANVASES */
/* Call procedure to ensure correct canvases are visible */
BEGIN
  CGLY$CANVAS_MANAGEMENT;
END;


/* CGLT$INIT_TAB_BLOCKS                     */
/* Initialise tabbed canvases               */
BEGIN
   CGLT$TAB_BLOCKS.ACTIVATE := TRUE;
   CGLT$TAB_BLOCKS.CGLT$NEW_BLOCK;
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

### PU CGDV$POPULATE_DYNAMIC_LISTS (Procedure, 43 lines)

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
    'WHERE  RV_DOMAIN = ''RULE_TYPE'' '||
    'ORDER BY  2');
  temp := populate_group(rg_id);
  populate_list('IMPR_RULES.RULE_TYPE', rg_id);
  delete_group(rg_id);

  rg_id := create_group_from_query('CGDV$DLRG',
    'SELECT RV_MEANING, RV_LOW_VALUE '||
    'FROM   CG_REF_CODES '||
    'WHERE  RV_DOMAIN = ''REC_STATUS'' '||
    'ORDER BY  2');
  temp := populate_group(rg_id);
  populate_list('IMPR_RULES.REC_STATUS', rg_id);
  delete_group(rg_id);

  rg_id := create_group_from_query('CGDV$DLRG',
    'SELECT RV_MEANING, RV_LOW_VALUE '||
    'FROM   CG_REF_CODES '||
    'WHERE  RV_DOMAIN = ''REC_STATUS'' '||
    'ORDER BY  2');
  temp := populate_group(rg_id);
  populate_list('IMPR_RULE_PORTS.REC_STATUS', rg_id);
  delete_group(rg_id);

  rg_id := create_group_from_query('CGDV$DLRG',
    'SELECT RV_MEANING, RV_LOW_VALUE '||
    'FROM   CG_REF_CODES '||
    'WHERE  RV_DOMAIN = ''REC_STATUS'' '||
    'ORDER BY  2');
  temp := populate_group(rg_id);
  populate_list('IMPR_RULE_TARIFF.REC_STATUS', rg_id);
  delete_group(rg_id);

END;
```

### PU CGFK$QRY_IMPR_RULES_IR_BIT_FK (Procedure, 22 lines)

```plsql
/* CGFK$QRY_IMPR_RULES_IR_BIT_FK */
PROCEDURE CGFK$QRY_IMPR_RULES_IR_BIT_FK(
   P_BUS_ID_TYPE_NAME IN OUT VARCHAR2      /* Value in Item :IMPR_RULES.BUS_ID_TYPE_NAME. */
  ,P_BUS_ID_TYPE_CD   IN     NUMBER  ) IS  /* Value in Item :IMPR_RULES.BUS_ID_TYPE_CD.   */
/* Query foreign key value/query lookup data. */
BEGIN
  DECLARE
    CURSOR C IS
      SELECT L_BIT.BUS_ID_TYPE_NAME
      FROM   BUS_ID_TYPES L_BIT
      WHERE  L_BIT.BUS_ID_TYPE_CD = P_BUS_ID_TYPE_CD;
  BEGIN
    OPEN C;
    FETCH C
    INTO    P_BUS_ID_TYPE_NAME;
    IF C%NOTFOUND THEN
      CLOSE C;
      RAISE NO_DATA_FOUND;
    END IF;
    CLOSE C;
  END;
END;
```

### PU CGFK$CHK_IMPR_RULES_IR_BIT_FK (Procedure, 22 lines)

```plsql
/* CGFK$CHK_IMPR_RULES_IR_BIT_FK */
PROCEDURE CGFK$CHK_IMPR_RULES_IR_BIT_FK(
   P_BUS_ID_TYPE_NAME IN OUT VARCHAR2      /* Value in Item :IMPR_RULES.BUS_ID_TYPE_NAME. */
  ,P_BUS_ID_TYPE_CD   IN     NUMBER  ) IS  /* Value in Item :IMPR_RULES.BUS_ID_TYPE_CD.   */
/* Validate foreign key value/query lookup data. */
BEGIN
  DECLARE
    CURSOR C IS
      SELECT L_BIT.BUS_ID_TYPE_NAME
      FROM   BUS_ID_TYPES L_BIT
      WHERE  L_BIT.BUS_ID_TYPE_CD = P_BUS_ID_TYPE_CD;
  BEGIN
    OPEN C;
    FETCH C
    INTO    P_BUS_ID_TYPE_NAME;
    IF C%NOTFOUND THEN
      CLOSE C;
      RAISE NO_DATA_FOUND;
    END IF;
    CLOSE C;
  END;
END;
```

### PU CG$IMPR1140_CNTRL_GLOBALS (Package Spec, 4 lines)

```plsql
/* CG$IMPR1140_CNTRL_GLOBALS */
PACKAGE CG$IMPR1140_CNTRL_GLOBALS IS
IMPR_RULES_WHERE VARCHAR2(2000) := 'first_time'; /* Block default where clause */
END;
```

### PU CGFK$QRY_IMPR_RULE_PORTS_IRP_S (Procedure, 22 lines)

```plsql
/* CGFK$QRY_IMPR_RULE_PORTS_IRP_S */
PROCEDURE CGFK$QRY_IMPR_RULE_PORTS_IRP_S(
   P_PORT_NAME IN OUT VARCHAR2      /* Value in Item :IMPR_RULE_PORTS.PORT_NAME. */
  ,P_PORT_CD   IN     NUMBER  ) IS  /* Value in Item :IMPR_RULE_PORTS.PORT_CD.   */
/* Query foreign key value/query lookup data. */
BEGIN
  DECLARE
    CURSOR C IS
      SELECT SDP.PORT_NAME
      FROM   SD_PORTS SDP
      WHERE  SDP.PORT_CD = P_PORT_CD;
  BEGIN
    OPEN C;
    FETCH C
    INTO    P_PORT_NAME;
    IF C%NOTFOUND THEN
      CLOSE C;
      RAISE NO_DATA_FOUND;
    END IF;
    CLOSE C;
  END;
END;
```

### PU CGFK$CHK_IMPR_RULE_PORTS_IRP_S (Procedure, 22 lines)

```plsql
/* CGFK$CHK_IMPR_RULE_PORTS_IRP_S */
PROCEDURE CGFK$CHK_IMPR_RULE_PORTS_IRP_S(
   P_PORT_NAME IN OUT VARCHAR2      /* Value in Item :IMPR_RULE_PORTS.PORT_NAME. */
  ,P_PORT_CD   IN     NUMBER  ) IS  /* Value in Item :IMPR_RULE_PORTS.PORT_CD.   */
/* Validate foreign key value/query lookup data. */
BEGIN
  DECLARE
    CURSOR C IS
      SELECT SDP.PORT_NAME
      FROM   SD_PORTS SDP
      WHERE  SDP.PORT_CD = P_PORT_CD;
  BEGIN
    OPEN C;
    FETCH C
    INTO    P_PORT_NAME;
    IF C%NOTFOUND THEN
      CLOSE C;
      RAISE NO_DATA_FOUND;
    END IF;
    CLOSE C;
  END;
END;
```

### PU CGFK$CHK_IMPR_RULE_PORTS_IRP_I (Procedure, 22 lines)

```plsql
/* CGFK$CHK_IMPR_RULE_PORTS_IRP_I */
PROCEDURE CGFK$CHK_IMPR_RULE_PORTS_IRP_I(
   P_RULE_ISN IN NUMBER) IS  /* Value in Item :IMPR_RULE_PORTS.RULE_ISN. */
/* Validate foreign key value/query lookup data. */
  CG$DUMMY VARCHAR2(1);
BEGIN
  DECLARE
    CURSOR C IS
      SELECT  '1'
      FROM   IMPR_RULES
      WHERE  RULE_ISN = P_RULE_ISN;
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

### PU CGRI$CHK_IMPR_RULES (Procedure, 27 lines)

```plsql
/* CGRI$CHK_IMPR_RULES */
PROCEDURE CGRI$CHK_IMPR_RULES(
   P_CHECK_BOTH IN BOOLEAN      /* Check FKs validated in BOTH (client/server)? */
  ,P_RULE_ISN   IN NUMBER ) IS  /* Item value                                   */
/* Validate that the deletion of the record is permitted    */
/* by checking for the existence of rows in related tables. */
  CG$DUMMY VARCHAR2(1);  /* Dummy variable */
BEGIN
  /* Deletion of IMPR_RULES prevented if IMPR_RULE_PORTS records exist */
  /* Foreign key(s): IRP_IR2_FK                                        */
  DECLARE
    CURSOR C IS
      SELECT  '1'
      FROM    IMPR_RULE_PORTS IRP
      WHERE   IRP.RULE_ISN = P_RULE_ISN;
  BEGIN
    OPEN C;
    FETCH C
    INTO    CG$DUMMY;
    IF C%FOUND THEN
      CLOSE C;
      Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(5, 'Cannot delete <p1> while dependent <p2> exists', 'استثناءات المستوردين','جمارك الاستثناء' ), 'E', 'OFG', 5);
      Des$Form_errors.RAISE_FAILURE;
    END IF;
    CLOSE C;
  END;
END;
```

### PU CGTE$CHECK_CONSTRAINT_VIO (Function, 45 lines)

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
    IF (constraint_name = 'IMR_PK') THEN
      Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(6, 'Row exists already with same <p1>', 'مسلسل الاستثناء' ), 'E', 'OFG', 6);
    ELSIF (constraint_name = 'BIT_PK') THEN
      Des$Form_errors.PUSH('هذا السجل مدخل سابقاً - أعد ادخال البيانات', 'E', 'OFG', 0);
    ELSIF (constraint_name = 'IRP_PK') THEN
      Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(6, 'Row exists already with same <p1>', 'Rule Isn,رمز الجمرك' ), 'E', 'OFG', 6);
    ELSIF (constraint_name = 'SDP_PK') THEN
      Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(6, 'Row exists already with same <p1>', 'رمز الجمرك' ), 'E', 'OFG', 6);
    ELSIF (constraint_name = 'IRT_PK') THEN
      Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(6, 'Row exists already with same <p1>', 'رمز بند التعريفة,رقم مسلسل الإستثناء' ), 'E', 'OFG', 6);
    ELSIF (constraint_name = 'HT_PK') THEN
      Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(6, 'Row exists already with same <p1>', 'البند المنسق' ), 'E', 'OFG', 6);
    ELSE
      Des$Form_errors.PUSH(P_SERVER_MSG, 'I', 'OFG', 0);
    END IF;
  ELSIF (P_SERVER_ERR = 2290) THEN
    Des$Form_errors.PUSH(P_SERVER_MSG, 'I', 'OFG', 0);
  END IF;
  RETURN( TRUE );
END;
```

### PU CGLY$DISPLAY_CANVASES (Procedure, 25 lines)

```plsql
/* CGLY$DISPLAY_CANVASES */
PROCEDURE CGLY$DISPLAY_CANVASES(
   P_CANVAS_LIST    IN OUT VARCHAR2      /* List of displayed canvases */
  ,P_CURRENT_CANVAS IN     VARCHAR2      /* Current canvas             */
  ,P_BASE_CANVAS    IN     VARCHAR2) IS  /* Base canvas                */
/* Display the current canvas plus any others in the canvas list */
  canvas_list VARCHAR2(255);  /* List of displayed canvases */
  canvas_to_raise VARCHAR2(255);  /* Canvas to raise to the top */
BEGIN
  IF ( P_CURRENT_CANVAS = P_BASE_CANVAS) THEN
    P_CANVAS_LIST := P_CURRENT_CANVAS || ',';
  ELSE
    P_CANVAS_LIST := replace(P_CANVAS_LIST, P_CURRENT_CANVAS || ',');
    IF ( get_view_property(P_BASE_CANVAS, VISIBLE) = 'FALSE') THEN
      canvas_list := P_CANVAS_LIST;
      WHILE (canvas_list IS NOT NULL) LOOP
        canvas_to_raise := substr(canvas_list, 1, instr(canvas_list, ','));
        canvas_list := replace(canvas_list, canvas_to_raise);
        CGLY$RAISE_CANVAS(rtrim(canvas_to_raise, ','));
      END LOOP;
    END IF;
    P_CANVAS_LIST := P_CANVAS_LIST || P_CURRENT_CANVAS || ',';
  END IF;
  CGLY$RAISE_CANVAS(P_CURRENT_CANVAS);
END;
```

### PU CGLY$GET_RELATED_CANVASES (Procedure, 16 lines)

```plsql
/* CGLY$GET_RELATED_CANVASES */
PROCEDURE CGLY$GET_RELATED_CANVASES(
   P_CURRENT_CANVAS IN OUT VARCHAR2      /* Current canvas */
  ,P_BASE_CANVAS    IN OUT VARCHAR2) IS  /* Base canvas    */
/* Find the canvases associated with the current canvas and record which */
/* base canvas is displayed in each window                               */
BEGIN
  IF ( P_current_canvas = 'CG$M_TAB_1') THEN
    P_base_canvas := 'CG$PAGE_1';
  ELSE
  P_BASE_CANVAS := P_CURRENT_CANVAS;
  END IF;
  IF (get_view_property(P_CURRENT_CANVAS, WINDOW_NAME) = 'CGSO$WINDOW_1') THEN
    :CG$CTRL.CG$WINDOWCGSO$WINDOW_1_PAGE := P_BASE_CANVAS;
  END IF;
END;
```

### PU CGLY$RAISE_CANVAS (Procedure, 10 lines)

```plsql
/* CGLY$RAISE_CANVAS */
PROCEDURE CGLY$RAISE_CANVAS(
   P_CANVAS IN VARCHAR2) IS  /* Current canvas */
/* Raise the current canvas, plus any dependant canvases to the top */
BEGIN
  set_view_property(P_CANVAS, VISIBLE, PROPERTY_ON);
  IF ( P_canvas = 'CG$PAGE_1') THEN
    set_view_property('CG$M_TAB_1', VISIBLE, PROPERTY_ON);
  END IF;
END;
```

### PU CGLY$CANVAS_MANAGEMENT (Procedure, 20 lines)

```plsql
/* CGLY$CANVAS_MANAGEMENT */
PROCEDURE CGLY$CANVAS_MANAGEMENT IS
/* Top level canvas management procedure */
  current_canvas VARCHAR2(61) := get_item_property(:SYSTEM.CURSOR_ITEM, ITEM_CANVAS);
  base_canvas VARCHAR2(61);
  canvas_list VARCHAR2(255);
BEGIN
  IF ( (:CG$CTRL.CG$LAST_CANVAS IS NULL) OR (:CG$CTRL.CG$LAST_CANVAS != current_canvas) ) THEN
    :CG$CTRL.CG$LAST_CANVAS := current_canvas;
    set_window_property( get_view_property( current_canvas, WINDOW_NAME ), VISIBLE, PROPERTY_ON);
    CGLY$GET_RELATED_CANVASES(current_canvas, base_canvas);
    IF ( base_canvas = 'CG$PAGE_1') THEN
      canvas_list := :CG$CTRL.CG$PAGE_1_LIST;
    END IF;
    CGLY$DISPLAY_CANVASES(canvas_list, current_canvas, base_canvas);
    IF ( base_canvas = 'CG$PAGE_1') THEN
      :CG$CTRL.CG$PAGE_1_LIST := canvas_list;
    END IF;
  END IF;
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
   --Add_Parameter(pl_id, 'IMPR_TYPE_CD', TEXT_PARAMETER, :IMPR_RULES.IMPR_TYPE_CD);  --

  IF :impr_rules.rule_type = 12 THEN
    CALL_FORM('LOV_IMPORT_HQ_N12.fmx',
              no_hide,
              no_replace,
              no_query_only,
              pl_id);

  ELSE
    CALL_FORM('LOV_IMPORT_HQ_NBR.fmx',
              no_hide,
              no_replace,
              no_query_only,
              pl_id);

  END IF;

 	IF  :GLOBAL.HQ_IMPR_NBR IS NOT NULL THEN
		:HQ_IMPR_NBR         := :GLOBAL.HQ_IMPR_NBR;
		:BUS_ID              := :GLOBAL.BUS_ID;
		:L_SI_ARBC_IMPR_NAME := :GLOBAL.ARBC_IMPR_NAME;
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
PROCEDURE EXEC_FUNS(cd VARCHAR2) IS
BEGIN
	NULL;
END;
```

### PU DSP_TRF_ITEMS_LOV (Procedure, 50 lines)

```plsql
PROCEDURE dsp_trf_items_lov IS
   pl_id   ParamList;
   pl_name VARCHAR2(100) := 'ITEM_LOV';
   RET NUMBER;

BEGIN

   pl_id := Get_Parameter_List(pl_name);
   IF Id_Null(pl_id) THEN
     pl_id := Create_Parameter_List(pl_name);
     IF Id_Null(pl_id) THEN
       ret := Str.Dispalert('Error creating parameter list '||pl_name, 'SYSTEM_ERROR');
       RAISE Form_Trigger_Failure;
     END IF;
      Add_Parameter(pl_id, 'WINDOW_X_POS', TEXT_PARAMETER, 0.4);
      Add_Parameter(pl_id, 'WINDOW_Y_POS', TEXT_PARAMETER, .5);
     Add_Parameter(pl_id, 'WINDOW_TITLE', TEXT_PARAMETER, 'الأستعلام و البحث في قاموس التعرفة');
     Add_Parameter(pl_id, 'ROW_COUNT', TEXT_PARAMETER, 15);
     Add_Parameter(pl_id, 'TARIFF_LOV', TEXT_PARAMETER, 1);

     CALL_FORM('LOV_TRF_ITEMS',NO_HIDE,NO_REPLACE,QUERY_ONLY,pl_id);

 	IF :GLOBAL.HRMNZD_CODE IS NOT NULL THEN
		:IMPR_RULE_TARIFF.HRMNZD_CODE:=:GLOBAL.HRMNZD_CODE ;


DECLARE
    CURSOR C IS
      SELECT HT.ITEM_ARBC_DESC
      FROM   HARMONIZED_TARIFF HT
      WHERE  HT.HRMNZD_CODE = :IMPR_RULE_TARIFF.HRMNZD_CODE;
  BEGIN
    OPEN C;
    FETCH C
    INTO    :HT_ITEM_ARBC_DESC;
    IF C%NOTFOUND THEN
      CLOSE C;
      RAISE NO_DATA_FOUND;
    END IF;
    CLOSE C;
  END;

	END IF;

   Destroy_Parameter_List(pl_id);
   ELSE
     ret := Str.DispAlert('Parameter list '||pl_name||' already EXISTS!','INFORMATION');
     RAISE Form_Trigger_Failure;
   END IF;
END;
```

### PU CHECK_FASH_ROLE_ID (Function, 34 lines)

```plsql
FUNCTION CHECK_FASH_ROLE_ID(V_PORT_CD NUMBER,V_USER_ID VARCHAR2) RETURN BOOLEAN IS
V_ROLE_ID VARCHAR2(30);
BEGIN
BEGIN
		SELECT UR.ROLE_ID INTO V_ROLE_ID
		FROM SC_USER_ROLES UR
		WHERE  UR.USER_ID 	= V_USER_ID
		AND		UR.PORT_CD 		= V_PORT_CD
		AND  	UR.UR_ACTIVE 	= 1
		AND		UR.ROLE_ID 		= 'IMP_EXCEPTION_FASH'
	UNION
		SELECT  GR.ROLE_ID
		FROM 		SC_GROUP_ROLES GR, SC_USER_GROUPS UG
		WHERE  	UG.PORT_CD 		=	V_PORT_CD
		AND			UG.USER_ID 		= V_USER_ID
		AND			GR.ROLE_ID 		= 'IMP_EXCEPTION_FASH'
		AND 		GR.GROUP_ID   = UG.GROUP_ID
		AND 		GR.GR_ACTIVE 	= 1
	MINUS
		SELECT ROLE_ID  FROM SC_USER_EXCLUDED_ROLES UER
		WHERE 	UER.USER_ID = V_USER_ID
		AND 		UER.PORT_CD = V_PORT_CD
		AND			UER.ROLE_ID = 'IMP_EXCEPTION_FASH'
		AND 		UER.UER_ACTIVE =1
		;

  	EXCEPTION WHEN NO_DATA_FOUND THEN RETURN(FALSE);
END;
  IF V_ROLE_ID = 'IMP_EXCEPTION_FASH' THEN
  	RETURN(TRUE);
  ELSE
  	RETURN(FALSE);
  END IF;
END;
```

### PU CALL_SD_PORTS (Procedure, 41 lines)

```plsql
PROCEDURE CALL_SD_PORTS IS
   pl_id   ParamList;
   pl_name VARCHAR2(100) := 'PORT_CD';

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
	:IMPR_RULE_PORTS.PORT_CD := :GLOBAL.PORT_CD;
	:IMPR_RULE_PORTS.PORT_NAME := :GLOBAL.PORT_NAME;
 	END IF;


   Destroy_Parameter_List(pl_id);
   ELSE
     ret := Str.DispAlert('Parameter list '||pl_name||' already EXISTS!','INFORMATION');
     RAISE Form_Trigger_Failure;
   END IF;
 END;
```

### PU CALL_IMPR_TYPE (Procedure, 45 lines)

```plsql
PROCEDURE CALL_IMPR_TYPE IS
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

   Add_Parameter(pl_id, 'WINDOW_TITLE', TEXT_PARAMETER, 'المتاحة قائمة أنواع الأنشطة التجارية');
   --Add_Parameter(pl_id, 'IMPR_TYPE_CD', TEXT_PARAMETER, :IMPR_RULES.IMPR_TYPE_CD);  --

   IF (:system.mode <> 'ENTER-QUERY'  ) THEN
	-- NEW VER.
	--IF :PARAMETER.P_CURR_PORT_CD = 99 THEN
	--   Add_Parameter(pl_id, 'STATUS', TEXT_PARAMETER, 0);
	--ELSE
	   Add_Parameter(pl_id, 'STATUS', TEXT_PARAMETER, 1);
	--END IF;
   END IF;


   CALL_FORM('LOV_Impr_Type.fmx',
              no_hide,
              no_replace,
              no_query_only,
              pl_id);

 	IF  :GLOBAL.IMPR_TYPE_CD IS NOT NULL THEN
		:BUS_ID_TYPE_CD := :GLOBAL.BUS_ID_TYPE_CD;
		:IMPR_RULES.BUS_ID_TYPE_NAME := :GLOBAL.BUS_ID_TYPE_NAME;
 	END IF;

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

### PU ADJ_BRANCH (Procedure, 10 lines)

```plsql
PROCEDURE ADJ_BRANCH IS
BEGIN
	IF :IMPR_RULES.ALL_BRNCH_FLAG <>1 THEN
		INTRFACE.MAKE_FIELD_ENTRABLE('IMPR_RULES.BUS_ID_BRNCH',TRUE);
	ELSE
		:IMPR_RULES.BUS_ID_BRNCH :=NULL;
		INTRFACE.MAKE_FIELD_ENTRABLE('IMPR_RULES.BUS_ID_BRNCH',FALSE);
	END IF;

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
| ACTIVITY.ADD_ACTIVITY | 9 | IMPR_RULES.POST-UPDATE, IMPR_RULES.PRE-DELETE, IMPR_RULES.PRE-INSERT, IMPR_RULE_PORTS.PRE-DELETE, IMPR_RULE_PORTS.PRE-INSERT, IMPR_RULE_PORTS.PRE-UPDATE, IMPR_RULE_TARIFF.PRE-DELETE, IMPR_RULE_TARIFF.PRE-INSERT … (+1) |
| ADJ_PRN.ADJ_REPORT_PRINTER | 1 | PU EXECUTE_FUNCTION |
| CG$CHK_PACKAGE_FAILURE | 1 | IMPR_RULES.KEY-DELREC |
| CG$DUMMY | 2 | PU CGFK$CHK_IMPR_RULE_PORTS_IRP_I, PU CGRI$CHK_IMPR_RULES |
| CG$IMPR1140_CNTRL_GLOBALS.IMPR_RULES_WHERE | 1 | IMPR_RULES.PRE-QUERY |
| CGBS$.CLEAR_MASTER_DETAIL | 1 | FORM.ON-CLEAR-DETAILS |
| CGBS$.COORD_VISIBLE_BLKS | 1 | PU CGBS$TOGGLE |
| CGBS$.DO_KEYQRY | 1 | FORM.KEY-CQUERY |
| CGBS$.NEW_BLOCK | 1 | FORM.WHEN-NEW-BLOCK-INSTANCE |
| CGBS$.QUERY_DETAILS | 1 | FORM.ON-POPULATE-DETAILS |
| CGBS$.SET_RELATIONS | 2 | PU CG$WHEN_NEW_FORM_INSTANCE, PU CGBS$TOGGLE |
| CGBS2$.DO_COMMIT_DIALOGUE | 2 | FORM.KEY-CLRBLK, FORM.KEY-CLRREC |
| CGBS2$.IS_COMMIT_NEEDED | 2 | FORM.KEY-CLRBLK, FORM.KEY-CLRREC |
| CGBS2$.IS_RECORD_DIRTY | 2 | FORM.KEY-CLRBLK, FORM.KEY-CLRREC |
| CGBS2$.SET_COORD_STYLE | 1 | FORM.WHEN-NEW-FORM-INSTANCE |
| CGBS2$.SET_QRY_ON_ENTRY | 1 | FORM.WHEN-NEW-FORM-INSTANCE |
| CGHP$CALL_MS_HELP | 4 | FORM.KEY-HELP, IMPR_RULES.KEY-HELP, IMPR_RULE_PORTS.KEY-HELP, IMPR_RULE_TARIFF.KEY-HELP |
| CGHP$PRE_FORM | 1 | FORM.PRE-FORM |
| CGLT$TAB_BLOCKS.CGLT$NEW_BLOCK | 2 | FORM.WHEN-NEW-BLOCK-INSTANCE, PU CG$WHEN_NEW_FORM_INSTANCE |
| CGLT$TAB_BLOCKS.CGLT$TAB_CHANGED | 1 | FORM.WHEN-TAB-PAGE-CHANGED |
| CGTE$OTHER_EXCEPTIONS | 11 | FORM.KEY-CLRFRM, FORM.KEY-HELP, FORM.WHEN-NEW-FORM-INSTANCE, IMPR_RULES.KEY-DELREC, IMPR_RULES.KEY-HELP, IMPR_RULES.POST-QUERY, IMPR_RULE_PORTS.KEY-HELP, IMPR_RULE_PORTS.PORT_CD.WHEN-VALIDATE-ITEM … (+3) |
| CGTE$POP_ERROR_STACK | 3 | IMPR_RULES.ON-ERROR, IMPR_RULE_PORTS.ON-ERROR, IMPR_RULE_TARIFF.ON-ERROR |
| CGTE$STRIP_CONSTRAINT | 4 | IMPR_RULES.ON-ERROR, IMPR_RULE_PORTS.ON-ERROR, IMPR_RULE_TARIFF.ON-ERROR, PU CGTE$CHECK_CONSTRAINT_VIO |
| CGTE$STRIP_FIRST_ERROR | 1 | PU CGTE$CHECK_CONSTRAINT_VIO |
| DES$FORM_ERRORS.MSGGETTEXT | 15 | FORM.KEY-CQUERY, FORM.KEY-HELP, FORM.KEY-NXTKEY, IMPR_RULES.KEY-HELP, IMPR_RULES.ON-ERROR, IMPR_RULES.POST-QUERY, IMPR_RULES.PRE-QUERY, IMPR_RULE_PORTS.KEY-HELP … (+7) |
| DES$FORM_ERRORS.PUSH | 16 | FORM.KEY-CQUERY, FORM.KEY-HELP, FORM.KEY-NXTKEY, IMPR_RULES.KEY-HELP, IMPR_RULES.ON-ERROR, IMPR_RULES.POST-QUERY, IMPR_RULES.PRE-QUERY, IMPR_RULE_PORTS.KEY-HELP … (+8) |
| DES$FORM_ERRORS.RAISE_FAILURE | 8 | FORM.KEY-CQUERY, FORM.KEY-NXTKEY, IMPR_RULES.ON-ERROR, IMPR_RULES.PRE-QUERY, IMPR_RULE_PORTS.ON-ERROR, IMPR_RULE_PORTS.PORT_CD.WHEN-VALIDATE-ITEM, IMPR_RULE_TARIFF.ON-ERROR, PU CGRI$CHK_IMPR_RULES |
| HIJDATE.CUR_HIJ_DATE | 3 | TOOLBAR.EXIT1.WHEN-BUTTON-PRESSED, TOOLBAR.RE_ENTER_QUERY.WHEN-BUTTON-PRESSED, TOOLBAR.SAVE.WHEN-BUTTON-PRESSED |
| HIJDATE.VALID_HIJ_DATE | 1 | TITLE.SYSTEM_DATE.WHEN-VALIDATE-ITEM |
| INTRFACE.MAKE_FIELD_ENTRABLE | 1 | PU ADJ_BRANCH |
| KEY_CONTROL.FOUND_KEY | 1 | TOOLBAR.EXIT1.WHEN-BUTTON-PRESSED |
| LIB_USR.SMS_MESSAGE.SEND_SMS_MESSAGE | 2 | IMPR_RULES.POST-INSERT, IMPR_RULES.POST-UPDATE |
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
| STR.DISPALERT | 14 | IMPR_RULES.HQ_IMPR_NBR.WHEN-VALIDATE-ITEM, IMPR_RULES.POST-QUERY, IMPR_RULES.PRE-INSERT, IMPR_RULES.PRE-UPDATE, IMPR_RULES.RULE_TYPE.WHEN-LIST-CHANGED, IMPR_RULES.RULE_TYPE.WHEN-VALIDATE-ITEM, IMPR_RULE_TARIFF.EXEPTION_QTY.WHEN-VALIDATE-ITEM, IMPR_RULE_TARIFF.HRMNZD_CODE.WHEN-VALIDATE-ITEM … (+6) |
| STR.DISPARBMSG | 1 | IMPR_RULES.KEY-DELREC |
| TMPLT.ENB_DIS_FUN_BUT | 1 | TOOLBAR.EXIT1.WHEN-BUTTON-PRESSED |
| TMPLT.FUN_ITEMS | 1 | PU EXECUTE_FUNCTION |
| TMPLT.KEYB_UP_DOWN | 3 | FORM.KEY-F9, TOOLBAR.KEY-DOWN, TOOLBAR.KEY-UP |
| TMPLT.KEY_DELETE_RECORD | 1 | IMPR_RULES.KEY-DELREC |
| TMPLT.POPULATE_FUNCTIONS | 2 | FORM.KEY-F9, TOOLBAR.FUN_BUT.WHEN-MOUSE-UP |

### 10.3 Classification of package-qualified calls (library vs database)

> The library texts in `forms/COMMON/libraries/` were searched for every package the form calls (same results as IMPR1120 §10.3 where the call is shared).

| Package / prefix | Origin | Library file / source | Used for (active calls in IMPR1140) |
|---|---|---|---|
| `NIB.*` | Forms library | `CIC_LIB.pld` | form startup, ON-ERROR / ON-MESSAGE, timers, 15 KEY-* handlers, window handling |
| `STR.*` | Forms library | `CIC_LIB.pld` (→ DB `STR_DB`, **MISSING SOURCE**) | `DispAlert` (14: texts in §11 notes), `DispArbMsg(1, 270, 'ERROR')` (IMPR_RULES.KEY-DELREC) |
| `INTRFACE.*` | Forms library | `CIC_LIB.pld` | `MAKE_FIELD_ENTRABLE('IMPR_RULES.BUS_ID_BRNCH', TRUE / FALSE)` in PU ADJ_BRANCH |
| `TMPLT.*` | Forms library | `CIC_LIB.pld` | `KEY_DELETE_RECORD` (IMPR_RULES.KEY-DELREC: confirm + `Delete_record` + COMMIT), `POPULATE_FUNCTIONS`, `KEYB_UP_DOWN`, `ENB_DIS_FUN_BUT`, `FUN_ITEMS` |
| `HIJDATE.*` | Forms library → DB | `CIC_LIB.pld` → `HIJDATE_DB` | only in the frame (TITLE.SYSTEM_DATE, TOOLBAR buttons) |
| `ACTIVITY.*` | Forms library → DB | `CIC_LIB.pld` → `ACTIVITY_DB` (`plsql/Shared/ACTIVITY_DB.*`) | `ADD_ACTIVITY(9, 4 / 5 / 6, 1 / 2 / 3, key)` in 9 DML triggers (§6 notes) |
| `KEY_CONTROL.*` | Forms library | `CIC_LIB.pld` | `FOUND_KEY` (TOOLBAR.EXIT1) |
| `REP.*`, `ADJ_PRN.*` | Forms library | `CIC_LIB.pld` | `RUN_PRODUCT` / `ADJ_REPORT_PRINTER` in PU EXECUTE_FUNCTION (function menu) |
| `CGBS$.*`, `CGBS2$.*` | Designer block-synchronisation library | `OFGBSL.pld` | master-detail coordination, commit dialogue |
| `CGLT$TAB_BLOCKS` | Designer tab-layout code | `OFGTAB`: **MISSING SOURCE** | tab page ↔ block navigation (WHEN-TAB-PAGE-CHANGED, WHEN-NEW-BLOCK-INSTANCE) |
| `DES$FORM_ERRORS` | Designer message library | `CIC_AMSG.pld` | error stack / messages |
| `CGTE$*` | Designer table-error library | `OFGTEL`: **MISSING SOURCE** | constraint-violation text in the three block ON-ERROR triggers |
| `CGHP$*` | Designer help library | `OFGHPL.pld` | MS-Help (obsolete) |
| `LIB_USR.SMS_MESSAGE` | Database package | **MISSING SOURCE** | `SEND_SMS_MESSAGE(9, 6, 1, port, NULL, mobile, text, RULE_ISN|HQ_IMPR_NBR)` in IMPR_RULES.POST-INSERT and POST-UPDATE (rule type 14, active) |
| `CG$IMPR1140_CNTRL_GLOBALS` | Form program unit (package spec) | in the XML (§9) | `IMPR_RULES_WHERE` variable (Designer dynamic WHERE) |

### 10.4 Called forms

| Caller | Built-in | Arguments (verbatim) | ADD_PARAMETER calls in the same unit (name, type, value) |
|---|---|---|---|
| PU EXECUTE_FUNCTION | CALL_FORM | `V_CALLED_FORM, no_hide, no_replace, no_query_only, pl_id` | P_USER_ID TEXT_PARAMETER = :PARAMETER.P_USER_ID; P_USER_NAME TEXT_PARAMETER = :PARAMETER.P_USER_NAME; P_WS_ID TEXT_PARAMETER = :PARAMETER.P_WS_ID; P_CURR_PORT_CD TEXT_PARAMETER = :PARAMETER.P_CURR_PORT_CD; P_PORT_TYPE TEXT_PARAMETER = :PARAMETER.P_PORT_TYPE; P_GROUP_CD TEXT_PARAMETER = :PARAMETER.P_GROUP_CD; P_USER_TYPE TEXT_PARAMETER = :PARAMETER.P_USER_TYPE; P_JOB_ID TEXT_PARAMETER = :PARAMETER.P_JOB_ID; P_CLASS_CD TEXT_PARAMETER = :PARAMETER.P_CLASS_CD; P_MODULE_ID TEXT_PARAMETER = TMPLT.FUN_ITEMS(ROW_COUNT).MID; P_MODULE_NAME TEXT_PARAMETER = V_MOD_NAME; P_BRKR_PORT_CD TEXT_PARAMETER = :PARAMETER.P_BRKR_PORT_CD; P_SHPG_AGNT_NBR TEXT_PARAMETER = :PARAMETER.P_SHPG_AGNT_NBR; P_BRKR_NBR TEXT_PARAMETER = :PARAMETER.P_BRKR_NBR; P_LIC_TYPE TEXT_PARAMETER = :PARAMETER.P_LIC_TYPE; P_BANK_CD TEXT_PARAMETER = :PARAMETER.P_BANK_CD; P_BANK_BRNCH_CD TEXT_PARAMETER = :PARAMETER.P_BANK_BRNCH_CD; P_SYS_ID TEXT_PARAMETER = :GLOBAL.SYSTEM_OBJ; P_REP_NO TEXT_PARAMETER = V_SEQ_NO; P_REPORT_NO TEXT_PARAMETER = :GLOBAL.SYSTEM_OBJ \|\|'-'\|\|V_SEQ_NO; DESTYPE TEXT_PARAMETER = 'PRINTER'; PARAMFORM TEXT_PARAMETER = 'NO'; ORACLE_SHUTDOWN TEXT_PARAMETER = 'YES'; MAXIMIZE TEXT_PARAMETER = 'YES' |
| PU EXECUTE_FUNCTION | CALL_FORM | `V_CALLED_FORM, no_hide, no_replace, no_query_only, pl_id` | P_USER_ID TEXT_PARAMETER = :PARAMETER.P_USER_ID; P_USER_NAME TEXT_PARAMETER = :PARAMETER.P_USER_NAME; P_WS_ID TEXT_PARAMETER = :PARAMETER.P_WS_ID; P_CURR_PORT_CD TEXT_PARAMETER = :PARAMETER.P_CURR_PORT_CD; P_PORT_TYPE TEXT_PARAMETER = :PARAMETER.P_PORT_TYPE; P_GROUP_CD TEXT_PARAMETER = :PARAMETER.P_GROUP_CD; P_USER_TYPE TEXT_PARAMETER = :PARAMETER.P_USER_TYPE; P_JOB_ID TEXT_PARAMETER = :PARAMETER.P_JOB_ID; P_CLASS_CD TEXT_PARAMETER = :PARAMETER.P_CLASS_CD; P_MODULE_ID TEXT_PARAMETER = TMPLT.FUN_ITEMS(ROW_COUNT).MID; P_MODULE_NAME TEXT_PARAMETER = V_MOD_NAME; P_BRKR_PORT_CD TEXT_PARAMETER = :PARAMETER.P_BRKR_PORT_CD; P_SHPG_AGNT_NBR TEXT_PARAMETER = :PARAMETER.P_SHPG_AGNT_NBR; P_BRKR_NBR TEXT_PARAMETER = :PARAMETER.P_BRKR_NBR; P_LIC_TYPE TEXT_PARAMETER = :PARAMETER.P_LIC_TYPE; P_BANK_CD TEXT_PARAMETER = :PARAMETER.P_BANK_CD; P_BANK_BRNCH_CD TEXT_PARAMETER = :PARAMETER.P_BANK_BRNCH_CD; P_SYS_ID TEXT_PARAMETER = :GLOBAL.SYSTEM_OBJ; P_REP_NO TEXT_PARAMETER = V_SEQ_NO; P_REPORT_NO TEXT_PARAMETER = :GLOBAL.SYSTEM_OBJ \|\|'-'\|\|V_SEQ_NO; DESTYPE TEXT_PARAMETER = 'PRINTER'; PARAMFORM TEXT_PARAMETER = 'NO'; ORACLE_SHUTDOWN TEXT_PARAMETER = 'YES'; MAXIMIZE TEXT_PARAMETER = 'YES' |
| PU SINGLE_IMP_LOV | CALL_FORM | `'LOV_IMPORT_HQ_N12.fmx', no_hide, no_replace, no_query_only, pl_id` | WINDOW_TITLE TEXT_PARAMETER = 'قائمة المستوردين' |
| PU SINGLE_IMP_LOV | CALL_FORM | `'LOV_IMPORT_HQ_NBR.fmx', no_hide, no_replace, no_query_only, pl_id` | WINDOW_TITLE TEXT_PARAMETER = 'قائمة المستوردين' |
| PU DSP_TRF_ITEMS_LOV | CALL_FORM | `'LOV_TRF_ITEMS',NO_HIDE,NO_REPLACE,QUERY_ONLY,pl_id` | WINDOW_X_POS TEXT_PARAMETER = 0.4; WINDOW_Y_POS TEXT_PARAMETER = .5; WINDOW_TITLE TEXT_PARAMETER = 'الأستعلام و البحث في قاموس التعرفة'; ROW_COUNT TEXT_PARAMETER = 15; TARIFF_LOV TEXT_PARAMETER = 1 |
| PU CALL_SD_PORTS | CALL_FORM | `'LOV_SD_PORTS.fmx', no_hide, no_replace, no_query_only, pl_id` | PORT_TYPE TEXT_PARAMETER = :PARAMETER.P_PORT_TYPE; WINDOW_WIDTH TEXT_PARAMETER = 5.5; WINDOW_TITLE TEXT_PARAMETER = 'قائمة المنافذ الجمركية السعوديه'; STATUS TEXT_PARAMETER = 1 |
| PU CALL_IMPR_TYPE | CALL_FORM | `'LOV_Impr_Type.fmx', no_hide, no_replace, no_query_only, pl_id` | WINDOW_TITLE TEXT_PARAMETER = 'المتاحة قائمة أنواع الأنشطة التجارية'; STATUS TEXT_PARAMETER = 1 |

### 10.5 Database tables / views referenced in SQL (18)

Extracted from active (non-comment) code. Record-group queries are listed in section 7.

| Object | DML used | Referenced in |
|---|---|---|
| BUS_ID_TYPES | SELECT | IMPR_RULES.HQ_IMPR_NBR.WHEN-VALIDATE-ITEM, IMPR_RULES.POST-QUERY, PU CGFK$CHK_IMPR_RULES_IR_BIT_FK, PU CGFK$QRY_IMPR_RULES_IR_BIT_FK |
| DUAL | SELECT | IMPR_RULE_TARIFF.HRMNZD_CODE.WHEN-VALIDATE-ITEM |
| HARMONIZED_TARIFF | SELECT | IMPR_RULE_TARIFF.HRMNZD_CODE.POST-CHANGE, IMPR_RULE_TARIFF.HRMNZD_CODE.WHEN-VALIDATE-ITEM, PU DSP_TRF_ITEMS_LOV |
| IMPORTERS | SELECT | IMPR_RULES.HQ_IMPR_NBR.WHEN-VALIDATE-ITEM, IMPR_RULES.POST-INSERT, IMPR_RULES.POST-QUERY, IMPR_RULES.POST-UPDATE |
| IMPORTER_BASIC_DATA | SELECT | IMPR_RULES.POST-INSERT, IMPR_RULES.POST-UPDATE |
| IMPR_RULES | SELECT | IMPR_RULES.PRE-INSERT, IMPR_RULE_TARIFF.HRMNZD_CODE.WHEN-VALIDATE-ITEM, PU CGFK$CHK_IMPR_RULE_PORTS_IRP_I |
| IMPR_RULE_PORTS | SELECT | IMPR_RULES.KEY-DELREC, PU CGRI$CHK_IMPR_RULES |
| IMPR_RULE_TARIFF | SELECT | IMPR_RULE_TARIFF.HRMNZD_CODE.WHEN-VALIDATE-ITEM, IMPR_RULE_TARIFF.PRE-INSERT |
| INTL_MSR_UNITS | SELECT | IMPR_RULE_TARIFF.HRMNZD_CODE.WHEN-VALIDATE-ITEM, IMPR_RULE_TARIFF.POST-QUERY |
| SC_GROUP_ROLES | SELECT | PU CHECK_FASH_ROLE_ID |
| SC_PORT_SETTING | SELECT | PU EXECUTE_FUNCTION |
| SC_SYSTEM_OBJECTS | SELECT | PU EXECUTE_FUNCTION |
| SC_USER_EXCLUDED_ROLES | SELECT | PU CHECK_FASH_ROLE_ID |
| SC_USER_GROUPS | SELECT | PU CHECK_FASH_ROLE_ID |
| SC_USER_ROLES | SELECT | PU CHECK_FASH_ROLE_ID |
| SD_PORTS | SELECT | PU CGFK$CHK_IMPR_RULE_PORTS_IRP_S, PU CGFK$QRY_IMPR_RULE_PORTS_IRP_S |
| SINGLE_IMPORTERS | SELECT | IMPR_RULES.HQ_IMPR_NBR.WHEN-VALIDATE-ITEM, IMPR_RULES.POST-QUERY |
| TARIFF_DETAILS | SELECT | IMPR_RULE_TARIFF.HRMNZD_CODE.WHEN-VALIDATE-ITEM, IMPR_RULE_TARIFF.POST-QUERY |

### 10.6 Reports, HOST, notifications, file and OS access

| Feature | Location | Active? | Notes |
|---|---|---|---|
| SMS | IMPR_RULES.POST-INSERT, POST-UPDATE | yes | when `RULE_TYPE = 14` and `REC_STATUS = 1` and a mobile is found: `LIB_USR.SMS_MESSAGE.SEND_SMS_MESSAGE(9, 6, 1, :P_CURR_PORT_CD, NULL, mobile, 'تم منع ميزة الفسح بتعهد للمستورد من إدارة المخاطر - الجمارك السعودية', RULE_ISN || '|' || HQ_IMPR_NBR)`. Mobile: `IMPORTER_BASIC_DATA.MOBILE_NO` by `HQ_IMPR_NBR`, else `IMPORTERS.MOBILE_NO` of the port; lookup errors are swallowed (`WHEN OTHERS THEN NULL`), a send error is not. POST-UPDATE sends again on every update of such a rule. No COMMIT in these triggers |
| `REP.RUN_PRODUCT` ×2 | PU EXECUTE_FUNCTION | only if the module has report functions in `SC_SYSTEM_OBJECTS` | generic frame code; `ADJ_FUNS` / `EXEC_FUNS` are empty |
| `TEXT_IO` | PU CHECK_TIMEOUT | no: PU not called | session timeout |
| `CREATE_TIMER` / WHEN-TIMER-EXPIRED | `NIB` library | yes, via the library | EDI ticker + session timeout |
| Windows API / DLL | PUs TOGGEL_WND, CHECK_TIMEOUT | indirect | client side only |
| `FORMS_DDL` | PRE-FORM (`ALTER SESSION SET NLS_DATE_FORMAT`) | yes | |
| DB COMMIT | `TMPLT.KEY_DELETE_RECORD` (master delete), TOOLBAR.SAVE | yes | |
| HOST, WEB.SHOW_DOCUMENT, OLE2, Java bean / PJC, CLIENT_*, EXEC_SQL, ON-LOCK | – | **not found** | |
| Sequences | none: `RULE_ISN = MAX(RULE_ISN) + 1` (whole table), `ITEM_SEQUENCE = MAX(ITEM_SEQUENCE) + 1` (within the rule) | yes | |
| DB links | – | not found | |

### 10.7 Object library / subclassed objects

- Object library: **`CIC_OLB.olb`** (`forms/COMMON/olb/CIC_OLB_OLB.xml`); 156 subclassed objects (visual attributes, items, triggers, parameters, alerts, blocks `CGSO$BLOCK` / `CGSO$BLOCK_MR` / `CGSO$BLOCK_CT`, canvases incl. `CGSO$CANVAS_TAB`, tab pages, window).
- The frame blocks are replaced by the f345 page template, page 0 toolbar and page 0 FUNCS drawer (as IMPR1110 §10.7).

### 10.8 What the library calls used here do, and their APEX equivalent (f345 standard)

| Library call | What it does | APEX 21.2 / f345 equivalent |
|---|---|---|
| `CGBS$.*` (`OFGBSL.pld`) | master-detail coordination over the two relations | Form region `IMPR_RULES` + two IGs whose SQL binds `:P1140_RULE_ISN` |
| `CGLT$TAB_BLOCKS` | tab page follows the current block | Tabs Container region with the two IGs |
| `TMPLT.KEY_DELETE_RECORD` | confirm → `Delete_record` + COMMIT | page 0 `DELETE` (native confirm) → process `KEY-DELREC` check + `PRE-DELETE` + `Process form`; no COMMIT |
| `STR.DispArbMsg(1, 270, type)` | message 270 of system 1 from the message table | `FORMS_APX.ARABIC_MESSAGE(1, 270)` returned as error text |
| `STR.DispAlert(text, 'ERROR')` + FTF | stop alert | `FORMS_APX.FORM_TRIGGER_FAILURE(text)` / validation error text |
| `INTRFACE.MAKE_FIELD_ENTRABLE` | enable / disable an item | native Enable / Disable in the DA `ALL_BRNCH_FLAG WHEN-VALIDATE-ITEM` (fires on page load too) |
| `ACTIVITY.ADD_ACTIVITY` | `ACTIVITY_DB.ADD_ACTIVITY` with port, user, workstation | `ACTIVITY_DB` inside the DML procedures with `P_CURR_PORT_CD`, `SSO_APP_USER`, `P_GLOBAL_V_WS_ID` (as IMPR1120) |
| `NIB.*`, `TMPLT` function menu, `KEY_CONTROL`, `REP` | as IMPR1110 §10.8 | f345 shell, Page Functions list |

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
> - 9 alerts come from `CIC_OLB.olb`; `STR.DispAlert` / `STR.DispArbMsg` set the text at runtime. `CG$ASK_COMMIT` is not referenced.
> - Texts used (all in the code): "هذا النوع غير مستخدم", "رقم المستورد المدخل غير صحيح، أدخل الرقم الصحيح أو استخدم القائمة المرفقة", "رقم المستورد المدخل غير صحيح" (POST-QUERY, no failure), " لا يوجد صلاحيات كافية للمستخدم<user>لإنشاء هذا النوع من الاستثناءات ", "رمز بند التعرفة غير موجود ", " الوحدة الدولية غير معرفة .. راجع الدعم الفني " (no failure), "هذا البند تم ادخاله من قبل لنفس المستورد", " تأكد من تطابق الوحده الدولية مع وحدة الكمية المستثناه " (INFORMATION). Only `STR.DispArbMsg(1, 270, 'ERROR')` (rule still has ports) is read from the message table through `STR_DB`: **MISSING SOURCE** text. Designer texts: "This <p1> does not exist" (رمز الجمرك, Bus Id Type Name), "Cannot delete استثناءات المستوردين while dependent جمارك الاستثناء exists".
> - APEX mapping (f345 standard §9): ERROR → `FORMS_APX.CHECK_ERROR` / `FORMS_APX.FORM_TRIGGER_FAILURE`; INFORMATION → native Alert action; WARNING (delete confirm in `TMPLT.KEY_DELETE_RECORD`) → page 0 DELETE confirm / IG delete.

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
| P_PORT_TYPE | default (CHAR) / OLB | default/OLB | P_PORT_TYPE | PU CALL_SD_PORTS, PU EXECUTE_FUNCTION, PU PRINT_REPORT |
| P_CURR_PORT_CD | default (CHAR) / OLB | default/OLB | P_CURR_PORT_CD | FORM.WHEN-NEW-FORM-INSTANCE, IMPR_RULES.HQ_IMPR_NBR.WHEN-VALIDATE-ITEM, IMPR_RULES.KEY-DELREC, IMPR_RULES.POST-INSERT, IMPR_RULES.POST-QUERY, IMPR_RULES.POST-UPDATE, IMPR_RULES.PRE-INSERT, IMPR_RULES.PRE-UPDATE, PU CALL_IMPR_TYPE, PU CHECK_EDI_MSG_LOV … (+5) |
| P_MODULE_ID | default (CHAR) / OLB | default/OLB | P_MODULE_ID | FORM.WHEN-NEW-FORM-INSTANCE |
| P_MODULE_NAME | default (CHAR) / OLB | default/OLB | P_MODULE_NAME | FORM.KEY-DUPREC, FORM.KEY-EDIT, FORM.KEY-F5, FORM.WHEN-NEW-FORM-INSTANCE, FORM.WHEN-WINDOW-ACTIVATED, TOOLBAR.EXIT1.WHEN-BUTTON-PRESSED, TOOLBAR.RE_ENTER_QUERY.WHEN-BUTTON-PRESSED, TOOLBAR.SAVE.WHEN-BUTTON-PRESSED |
| P_APPLICATION_NAME | default (CHAR) / OLB | default/OLB | P_APPLICATION_NAME | – |
| P_USER_ID | default (CHAR) / OLB | default/OLB | P_USER_ID | FORM.WHEN-NEW-FORM-INSTANCE, IMPR_RULES.PRE-INSERT, IMPR_RULES.PRE-UPDATE, PU EDI_MSG_LOV, PU EXECUTE_FUNCTION, PU FOR_EDI_MSG, PU PRINT_REPORT |
| P_WS_ID | default (CHAR) / OLB | default/OLB | P_WS_ID | PU EXECUTE_FUNCTION, PU PRINT_REPORT |
| P_USER_NAME | default (CHAR) / OLB | default/OLB | P_USER_NAME | FORM.KEY-DUPREC, FORM.KEY-EDIT, FORM.KEY-F5, FORM.WHEN-WINDOW-ACTIVATED, PU EDI_MSG_LOV, PU EXECUTE_FUNCTION, PU PRINT_REPORT, TOOLBAR.EXIT1.WHEN-BUTTON-PRESSED, TOOLBAR.RE_ENTER_QUERY.WHEN-BUTTON-PRESSED, TOOLBAR.SAVE.WHEN-BUTTON-PRESSED |
| CG$STARTUP_MODE | default (CHAR) / OLB | NORMAL | – | – |

### 12.1 :GLOBAL variables (17)

| Global | Read in | Written in |
|---|---|---|
| ARBC_IMPR_NAME | PU SINGLE_IMP_LOV | – |
| BUS_ID | PU SINGLE_IMP_LOV | – |
| BUS_ID_TYPE_CD | PU CALL_IMPR_TYPE | – |
| BUS_ID_TYPE_NAME | PU CALL_IMPR_TYPE | – |
| CG$HP_HFILE | FORM.KEY-HELP, IMPR_RULES.KEY-HELP, IMPR_RULE_PORTS.KEY-HELP, IMPR_RULE_TARIFF.KEY-HELP | FORM.KEY-HELP, IMPR_RULES.KEY-HELP, IMPR_RULE_PORTS.KEY-HELP, IMPR_RULE_TARIFF.KEY-HELP |
| CG$HP_HPATH | FORM.KEY-HELP, IMPR_RULES.KEY-HELP, IMPR_RULE_PORTS.KEY-HELP, IMPR_RULE_TARIFF.KEY-HELP | FORM.PRE-FORM |
| CG$QUERY_MODE | FORM.KEY-MENU, FORM.ON-POPULATE-DETAILS, FORM.WHEN-NEW-BLOCK-INSTANCE, PU CG$WHEN_NEW_FORM_INSTANCE | PU CG$WHEN_NEW_FORM_INSTANCE |
| CURRENT_DT | FORM.PRE-FORM | FORM.PRE-FORM |
| CURRENT_VER | FORM.PRE-FORM | FORM.PRE-FORM |
| CURRENT_VERSION | – | FORM.PRE-FORM |
| EXIT | TOOLBAR.EXIT.WHEN-BUTTON-PRESSED | – |
| HQ_IMPR_NBR | PU SINGLE_IMP_LOV | – |
| HRMNZD_CODE | PU DSP_TRF_ITEMS_LOV | – |
| IMPR_TYPE_CD | PU CALL_IMPR_TYPE | – |
| PORT_CD | PU CALL_SD_PORTS | – |
| PORT_NAME | PU CALL_SD_PORTS | – |
| SYSTEM_OBJ | PU EXECUTE_FUNCTION | PU EXECUTE_FUNCTION (DEFAULT_VALUE) |

### 12.2 :SYSTEM variables (14)

| Variable | Used in |
|---|---|
| BLOCK_STATUS | FORM.KEY-CLRBLK, FORM.KEY-CLRREC |
| COORDINATION_OPERATION | FORM.ON-CLEAR-DETAILS |
| CURRENT_FORM | TOOLBAR.EXIT1.WHEN-BUTTON-PRESSED |
| CURSOR_BLOCK | FORM.ON-POPULATE-DETAILS, FORM.WHEN-NEW-BLOCK-INSTANCE, IMPR_RULES.BUS_ID.KEY-LISTVAL, IMPR_RULES.BUS_ID_TYPE_CD.KEY-LISTVAL, IMPR_RULES.BUS_ID_TYPE_NAME.KEY-LISTVAL, IMPR_RULES.D.KEY-LISTVAL … (+11) |
| CURSOR_ITEM | FORM.WHEN-NEW-BLOCK-INSTANCE, IMPR_RULES.BUS_ID.KEY-LISTVAL, IMPR_RULES.BUS_ID_TYPE_CD.KEY-LISTVAL, IMPR_RULES.BUS_ID_TYPE_NAME.KEY-LISTVAL, IMPR_RULES.D.KEY-LISTVAL, IMPR_RULES.HQ_IMPR_NBR.KEY-LISTVAL … (+11) |
| CURSOR_RECORD | IMPR_RULES.BUS_ID.KEY-LISTVAL, IMPR_RULES.BUS_ID_TYPE_CD.KEY-LISTVAL, IMPR_RULES.BUS_ID_TYPE_NAME.KEY-LISTVAL, IMPR_RULES.D.KEY-LISTVAL, IMPR_RULES.HQ_IMPR_NBR.KEY-LISTVAL, IMPR_RULES.L_SI_ARBC_IMPR_NAME.KEY-LISTVAL … (+8) |
| CURSOR_VALUE | TITLE.SYSTEM_DATE.WHEN-VALIDATE-ITEM |
| FORM_STATUS | FORM.KEY-CLRFRM, TOOLBAR.SAVE.WHEN-BUTTON-PRESSED |
| MASTER_BLOCK | FORM.ON-CLEAR-DETAILS |
| MODE | FORM.KEY-CQUERY, IMPR_RULES.BUS_ID.KEY-LISTVAL, IMPR_RULES.BUS_ID_TYPE_CD.KEY-LISTVAL, IMPR_RULES.BUS_ID_TYPE_NAME.KEY-LISTVAL, IMPR_RULES.D.KEY-LISTVAL, IMPR_RULES.HQ_IMPR_NBR.KEY-LISTVAL … (+12) |
| TAB_NEW_PAGE | FORM.WHEN-TAB-PAGE-CHANGED |
| TRIGGER_BLOCK | FORM.KEY-CLRBLK, FORM.KEY-CLRREC, FORM.KEY-CQUERY, FORM.ON-CLEAR-DETAILS |
| TRIGGER_ITEM | TITLE.SYSTEM_DATE.WHEN-VALIDATE-ITEM |
| TRIGGER_RECORD | IMPR_RULES.POST-QUERY, IMPR_RULE_PORTS.POST-QUERY |

> **Parameter/global notes**
> - The 20 `P_*` parameters are inherited from the OLB and map to the f345 items as in IMPR1110 §12 (`P_USER_ID` → `SSO_APP_USER`, `P_CURR_PORT_CD`, `P_PORT_TYPE`, `P_WS_ID` → `P_GLOBAL_V_WS_ID`, `P_MODULE_ID` → `P1140_MODULE_ID`). The business code uses only `P_CURR_PORT_CD` (port filter, delete check, SMS, rule type 12 importer lookup, role check), `P_USER_ID` (role check, activity log) and `P_PORT_TYPE` (LOV_SD_PORTS). The form has no parameter of its own.
> - Globals: `HQ_IMPR_NBR`, `BUS_ID`, `ARBC_IMPR_NAME`, `PORT_CD`, `PORT_NAME`, `HRMNZD_CODE`, `IMPR_TYPE_CD`, `BUS_ID_TYPE_CD`, `BUS_ID_TYPE_NAME` are return channels of the LOV forms; `CG$*` are Designer internals; `CURRENT_VER=1` / `CURRENT_DT='13-11-2024'` / `CURRENT_VERSION` are version stamps; `EXIT`, `SYSTEM_OBJ` belong to the frame. None needs an application item.

## 13. Menu & Security

### 13.1 Menu

| Property | Value |
|---|---|
| Menu module | `CIC_MENU`; it does not open IMPR1140. Screens are opened by `APPS` / `BUTTON_LAST_TREE` |
| SET_MENU_ITEM_PROPERTY | **not used** |
| In-form "menu" | `LSIDE` side menu, `TOOLBAR.FUN_BUT`, `KEY-F9`. `ADJ_FUNS` / `EXEC_FUNS` are empty |

### 13.2 Function-level and data security

| Mechanism | Location | Details |
|---|---|---|
| Role for rule types 13 / 14 | IMPR_RULES.PRE-INSERT, PRE-UPDATE → PU `CHECK_FASH_ROLE_ID(P_CURR_PORT_CD, P_USER_ID)` | the user must hold role **`IMP_EXCEPTION_FASH`** in the port (`SC_USER_ROLES` active, or through `SC_USER_GROUPS` / `SC_GROUP_ROLES` active, minus `SC_USER_EXCLUDED_ROLES` active); otherwise " لا يوجد صلاحيات كافية للمستخدم<user>لإنشاء هذا النوع من الاستثناءات " |
| Port scope of the ports grid | block WHERE `PORT_CD = :PARAMETER.P_CURR_PORT_CD`, KEY-DELREC count | a user sees and maintains only the port row of his own port; other ports' rows of the same rule stay hidden |
| Delete permission | `TMPLT.KEY_DELETE_RECORD` | only when toolbar `REMOVE` is visible and enabled (frame function security) |
| Function menu | PU EXECUTE_FUNCTION | `SC_SYSTEM_OBJECTS`, `SC_PORT_SETTING`, role tables through `TMPLT` / `KEY_CONTROL` |

### 13.3 APEX mapping notes (f345 standard; no code in this step)

- **Page access:** the application's existing privileges (CLAUDE.md §8); no authorization schemes.
- **Role `IMP_EXCEPTION_FASH`:** a business check in the package (`CHECK_FASH_ROLE_ID` with `SSO_APP_USER`), called by PRE-INSERT / PRE-UPDATE; it stays a data rule, not an APEX authorization. Privilege administrators must keep granting this role in `SC_USER_ROLES` / groups.
- **Port scope:** the ports IG SQL keeps `port_cd = :P_CURR_PORT_CD`.
- **Functions:** f345 *Page Functions* list (page 0 `FUNCS`).

## 14. Risk Assessment

> The "Proposed APEX approach" follows the f345 standard (CLAUDE.md §4b, §4c; `docs/f345_reference_standard.md` §9–§10). Nothing is generated in this step.

| # | Risk item | Location (trigger/object) | Level | Reason | Proposed APEX approach |
|---|---|---|---|---|---|
| 1 | SMS sent from POST-INSERT / POST-UPDATE inside the transaction, package without source | IMPR_RULES.POST-INSERT / POST-UPDATE → `LIB_USR.SMS_MESSAGE.SEND_SMS_MESSAGE` (**MISSING SOURCE**) | High | External side effect before the commit; signature unknown; POST-UPDATE resends on every save of a type-14 rule | Procedures `POST_INSERT` / `POST_UPDATE` called by processes `POST-INSERT` / `POST-UPDATE`, keeping the call and the swallowed lookup errors (preserve behaviour); timing and resend to confirm (§15 #2) |
| 2 | `RULE_ISN = MAX(RULE_ISN) + 1` over the whole table, no lock | IMPR_RULES.PRE-INSERT | Medium | Two users saving at the same time get the same key → PK violation | Keep in `PRE_INSERT` (preserve behaviour); `-- SUGGESTION:` a DB sequence (migration script + decision, §15 #3) |
| 3 | `ITEM_SEQUENCE = MAX + 1` within the rule | IMPR_RULE_TARIFF.PRE-INSERT | Low | Same race, limited to one rule | Keep in `IMPR_RULE_TARIFF_PRE_INSERT`; rows of one save are numbered one by one |
| 4 | Master delete commits inside `TMPLT.KEY_DELETE_RECORD`, double delete code | IMPR_RULES.KEY-DELREC | Medium | COMMIT in the trigger; checks before the delete | Page 0 DELETE → process `KEY-DELREC` (port-row check 1-270 + RI check) → `PRE-DELETE` (activity log) → `Process form - DELETE`; APEX commits |
| 5 | Non-isolated relation to IMPR_RULE_TARIFF | relation CGFK$IRT_IR_FK | Medium | Forms refuses deleting a rule that still has tariff rows (FRM-40202); a native Form delete would hit the DB FK `IRT_IR_FK` instead | Same check in `KEY_DELREC` with the Designer message text (§15 #8) |
| 6 | Insert on the ports grid depends on the master value `ALL_BRNCH_FLAG` | IMPR_RULE_PORTS.POST-QUERY / PRE-RECORD / WHEN-NEW-RECORD-INSTANCE (`SET_BLOCK_PROPERTY(INSERT_ALLOWED)`) | Medium | IG insert cannot be switched per master value declaratively | Server check in `IMPR_RULE_PORTS_PRE_INSERT` (error text to agree, §15 #6) |
| 7 | Role check for rule types 13 / 14 | IMPR_RULES.PRE-INSERT / PRE-UPDATE, PU CHECK_FASH_ROLE_ID | Medium | Security rule in data tables | Kept in the package (§13.3), user = `SSO_APP_USER` |
| 8 | Importer lookup depends on RULE_TYPE (12 → IMPORTERS of the port, else SINGLE_IMPORTERS) | HQ_IMPR_NBR WHEN-VALIDATE-ITEM / KEY-LISTVAL, IMPR_RULES.POST-QUERY | Medium | Two sources, two LOV forms | `HQ_IMPR_NBR_WHEN_VALIDATE_ITEM` (FOS, Items to Return) + `HQ_IMPR_NBR VALIDATION`; one shared Popup LOV whose query depends on the rule type item |
| 9 | Tariff-item checks with cursor + `RAISE NO_DATA_FOUND` after the alert, and a non-blocking alert | IMPR_RULE_TARIFF.HRMNZD_CODE.WHEN-VALIDATE-ITEM | Medium | Mixed blocking / non-blocking messages | `IMPR_RULE_TARIFF_HRMNZD_CODE_VALIDATION` (blocking: not found, already excepted) + `..._WHEN_VALIDATE_ITEM` (description, international unit); the non-blocking "unit not defined" message needs a decision (§15 #7) |
| 10 | Item name ≠ column name | IMPR_RULE_TARIFF.EXEPTION_QTY on column EXCEPTED_QTY | Low | Easy to map wrongly | IG column `EXEPTION_QTY` = `excepted_qty AS exeption_qty` (Forms name kept, CLAUDE.md §4a) |
| 11 | Dynamic DEFAULT_WHERE by string concatenation | IMPR_RULES.PRE-QUERY (`CGFK$DEFAULT_WHERE` on BUS_ID_TYPE_NAME), POST-QUERY reset | Medium | Concatenated SQL from user input | Search page SQL with bind variables only (CLAUDE.md §6 #9) |
| 12 | Hidden port rows of other ports | IMPR_RULE_PORTS block WHERE | Low | A rule may have rows for several ports; each port sees only its own | IG SQL keeps `port_cd = :P_CURR_PORT_CD` |
| 13 | Attached libraries without source (OFGTEL, OFGTAB) | ON-ERROR (×3), WHEN-TAB-PAGE-CHANGED | Medium | Constraint messages / tab code | f345 `APP_ERROR_HANDLER` + Text Messages by constraint name (texts in the ON-ERROR triggers); native tabs |
| 14 | `FORMS_DDL('ALTER SESSION SET NLS_DATE_FORMAT …')` + SET_APPLICATION_PROPERTY | FORM.PRE-FORM | Low | Session NLS change; the form has no date item | f345 Globalization attributes; dropped |
| 15 | Reports / dynamic CALL_FORM via the function menu | PU EXECUTE_FUNCTION | Medium | Depends on `SC_SYSTEM_OBJECTS` (unknown) | f345 *Page Functions* list (§15 #9) |
| 16 | LOV forms via CALL_FORM with :GLOBAL return values | HQ_IMPR_NBR, PORT_CD, HRMNZD_CODE KEY-LISTVAL and buttons B_IMP, PORT_CD2, HRMNZD_CODE2 | Low | Standard LOV pattern | Popup LOVs on shared LOVs (`LOV_APX`) |
| 17 | Runtime list population from CG_REF_CODES | PU CGDV$POPULATE_DYNAMIC_LISTS (4 lists) | Low | Lists built at startup | Shared LOVs on `CG_REF_CODES` (`RULE_TYPE`, `REC_STATUS`) |
| 18 | `BUS_ID_BRNCH` enterable by the flag | PU ADJ_BRANCH | Low | Make_Field_Entrable | Native Enable / Disable + Clear in a DA, server clears the value when the flag is 1 |
| 19 | POST-QUERY lookups (importer name, bus id type name, port name, tariff description, international unit) | 3 POST-QUERY triggers | Low | One master row; detail lookups per row (N+1 in Forms) | Joins / scalar sub-queries in the region SQL; the international unit through a package function used in SQL |
| 20 | Designer master-detail and tab coordination | ON-POPULATE-DETAILS, ON-CLEAR-DETAILS, WHEN-NEW-BLOCK-INSTANCE, WHEN-TAB-PAGE-CHANGED | Low | Standard pattern | Native |
| 21 | Activity log around DML (POST-UPDATE for the master) | 9 DML triggers | Low | Source available (`ACTIVITY_DB`) | Same calls inside the DML procedures |
| 22 | Timers, EDI ticker, session timeout, Windows DLL, TEXT_IO | NIB library, unused PUs | Low | Frame behaviour | Dropped, as decided for IMPR1110 (§15 #10) |
| 23 | KEY-* overrides and the 14 Designer KEY-LISTVAL checks | form / block / item KEY-* | Low | Keyboard behaviour | Page 0 toolbar, popup LOVs, item read-only state |
| 24 | Designer MS-Help | KEY-HELP (form + 3 blocks) | Low | Obsolete | Dropped |
| 25 | Simple validations and defaults | RULE_TYPE ≠ 9, RULE_TYPE default 1, ALL_BRNCH_FLAG default 0, REC_STATUS default 1, PORT_CD exists, EXEPTION_QTY → REMAINED_QTY | Low | Straightforward | Item / column defaults, `<ITEM> VALIDATION`, DAs with FOS |

**High risks: 1** (#1) · Medium: 10 (#2, #4–#9, #11, #13, #15) · Low: 14 (#3, #10, #12, #14, #16–#25)

## 15. Open Questions / Missing Sources

| # | Open question / missing source | Status (2026-11-24) | Why it matters | Needed from |
|---|---|---|---|---|
| 1 | Source / signature of `LIB_USR.SMS_MESSAGE.SEND_SMS_MESSAGE` | Open: **MISSING SOURCE** (call copied from the Forms code, as IMPR1120) | Compilation of `IMPR1140` | DBA |
| 2 | SMS timing: before the commit (as now) or after a successful save? Resend on every update of a type-14 rule (POST-UPDATE) — intended? | Open: preserved as in Forms | Duplicate SMS, SMS for a failed save | Business owner |
| 3 | `RULE_ISN`: keep `MAX + 1` over the whole table or use a DB sequence (migration script)? | Open: preserved (`-- SUGGESTION:`) | Concurrent saves (risk #2) | Business owner / DBA |
| 4 | Text of message 1-270 (`STR.DispArbMsg(1, 270)`) | Open: **MISSING SOURCE** (read at run time by `FORMS_APX.ARABIC_MESSAGE`) | Delete check message | Data owner |
| 5 | The CGRI check in KEY-DELREC runs after `TMPLT.KEY_DELETE_RECORD` has already deleted and committed: is "any port row of the rule" (all ports) meant to block the delete, or only the row of the user's port? | Open: APEX runs both checks **before** the delete (the Forms order cannot be kept without a commit) | Rules with port rows of other ports | Business owner |
| 6 | Ports grid insert while `ALL_BRNCH_FLAG = 1`: Forms gives FRM-40602 ("cannot insert into …"); the APEX error text has to be agreed | Open: placeholder text | Validation message | Business owner |
| 7 | Non-blocking message " الوحدة الدولية غير معرفة .. راجع الدعم الفني " (no failure): APEX FOS shows only errors | Open: proposed: no message, the empty `INTL_UNIT` shows it | Behaviour change | Business owner |
| 8 | Deleting a rule that still has tariff rows: Forms (Non-Isolated) refuses; which text? (Forms default FRM-40202 "لا يمكن حذف السجل الرئيسي لوجود سجلات تفصيلية") | Open: Designer-style text proposed | Delete check | Business owner |
| 9 | Which functions / reports does the module have in `SC_SYSTEM_OBJECTS`? | Open | Page Functions list | Data owner |
| 10 | Timers / EDI ticker / custom session timeout dropped (IMPR1110 decision of 2026-11-19) | Assumed yes | – | Business owner |
| 11 | Library `OFGTEL` (constraint messages) / `OFGTAB` (tabs) | Open: **MISSING SOURCE**; block-specific texts are in the XML | Generic constraint messages | Forms team (optional) |
| 12 | Grants to `LIB_APX_USR` on `IMPR_RULES`, `IMPR_RULE_PORTS`, `IMPR_RULE_TARIFF`, `IMPORTERS`, `SINGLE_IMPORTERS`, `IMPORTER_BASIC_DATA`, `BUS_ID_TYPES`, `SD_PORTS`, `HARMONIZED_TARIFF`, `TARIFF_DETAILS`, `INTL_MSR_UNITS`, `SC_USER_ROLES`, `SC_USER_GROUPS`, `SC_GROUP_ROLES`, `SC_USER_EXCLUDED_ROLES`, and on `ACTIVITY_DB`, `LIB_USR.SMS_MESSAGE` | Open | Compilation | DBA |
| 13 | `LOV_IMPORT_HQ_N12` (rule type 12) lists `IMPORTERS`: of the user's port only, or all ports? The WHEN-VALIDATE-ITEM checks the user's port | Assumed: the user's port (same as the validation) | LOV contents | Business owner |
