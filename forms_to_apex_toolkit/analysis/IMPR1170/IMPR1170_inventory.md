# IMPR1170 – Inventory & Migration Risk Assessment

- **Form:** IMPR1170 (module name in the XML: `IMPR1170_CNTRL`, module title "صيانة تفاويض الشركات الوسيطة", window title `Agnts` – both left over from the template form; the screen itself is the commercial-registration look-up "جدول بيانات السجل التجارى من وزارة التجارة"): the clerk types a unified commercial-registration number (CR_NBR); when the record was not refreshed today the form calls the Ministry of Commerce (MCI) web service, which loads `MCI_DATA` / `MCI_OWNERS`, and then shows the registration and its owners (query only)
- **Source:** `forms/IMPR/IMPR1170_fmb.xml` (frmf2xml output)
- **Target:** Oracle APEX 21.2 on Oracle Database 12.1.0.2, reference application f345 (CLAUDE.md §4b, §4c)
- **Produced:** 2026-11-25 (step 01): mechanical sections by `scripts/gen_inv.py`; manual analysis in sections 1, 13–15 (sources in `work/IMPR1170/inv_man/`).
- **Sources used besides the form XML:** library text `forms/COMMON/libraries/CIC_LIB.pld` (NIB, STR, HIJDATE), OLB `forms/COMMON/olb/CIC_OLB_OLB.xml` (item classes `CGSO$CHAR_ARB`, `CGSO$HDATE_ARB_DO`, `CGSO$COMBO_DO`); the IMPR1140 / IMPR1150 / IMPR1160 inventories for the shared OLB frame findings.
- **Scope rule:** anything not available is marked **MISSING SOURCE** and is not guessed: the libraries OFGTEL, SEC_LIB, OFGTAB, PICKLIST, POS, SCDLL, VCDLL; DB package `LIB_USR.PRTL_NEBRAS_SERVICES` (`CALL_WEB_SERVICE`, called unchanged) and the MCI web service behind it; the DDL of `MCI_DATA`, `MCI_OWNERS`, `MCI_BUS_ID_STATUS`, `MCI_RELATION_TYPES` (column types taken from the Forms items).

## 1. Summary

**Complexity: COMPLEX by the rubric** (driven by Designer and OLB frame boilerplate) · **business logic: SIMPLE** · **Effort ESTIMATE: 1.5–2 developer-days**

### 1.1 Counts

| Object | Count | Notes |
|---|---|---|
| Blocks | 6 | 2 base-table: `MCI_DATA` (single record shown; Update / Delete Allowed = false, Insert Allowed by default) and its detail `MCI_OWNERS` (4 records shown, query only); 4 OLB frame blocks (TITLE, EDI_MSG, LSIDE, TOOLBAR) |
| Items | 104 | MCI_DATA 16 (1 hidden), MCI_OWNERS 8 (3 hidden), LSIDE 50, TOOLBAR 16, TITLE 12, EDI_MSG 2 |
| Triggers | 239 | Form 33 · Block 9 · Item 197; 74 contain code; 22 of the business-block item triggers are the Designer KEY-LISTVAL "may the LOV be shown" check (no LOV exists) |
| Trigger PL/SQL lines | 1,813 total / 1,114 active | business code ≈ 70 active lines (CR_NBR KEY-NEXT-ITEM, two POST-QUERY) |
| Program units | 22 | 759 total / 340 active lines; none is business code: `EXEC_FUNS` / `ADJ_FUNS` are empty (`NULL;`, the old broker-authorization code is commented out) |
| Relations (master–detail) | 1 | `CGFK$MCI_OWNER_MCI_DATA_FK`: `MCI_DATA.CR_NBR = MCI_OWNERS.CR_NBR` |
| LOVs / Record groups | 0 / 0 (+1 runtime group `CGDV$DLRG` for the list item CR_TYPE, CG_REF_CODES domain `COMM_RGSTRTN_TYPE`) | – |
| Canvases / Windows | 5 / 1 | `CG$PAGE_1` holds both blocks |
| Alerts | 10 | OLB alerts; only CFG_ERROR is used (STR.DISPALERT 'ERROR' of KEY-NEXT-ITEM) |
| Module parameters | 21 | all inherited from the OLB; the business code uses none (the frame uses `P_MODULE_ID`, `P_CURR_PORT_CD`) |
| Attached libraries | 17 | the same list as IMPR1140 / IMPR1150 / IMPR1160 |
| Called forms | 0 (+1 dynamic, EXECUTE_FUNCTION frame) | – |

### 1.2 Complexity rubric

| Metric | Value | Category |
|---|---|---|
| Data blocks | 2 base-table (6 with the frame) | Simple |
| Triggers (total) | 239 | **Complex** |
| Lines of PL/SQL | 2,572 total / 1,454 active | **Complex** |
| Master–detail relations | 1 | Medium |
| Called forms / libraries | 1 dynamic (EXECUTE_FUNCTION) + 17 libraries | **Complex** |
| Special features | web service through a DB package (`LIB_USR.PRTL_NEBRAS_SERVICES.CALL_WEB_SERVICE`, URL with a fixed internal address), Hijri date (`MI-MM-YYYY`), timers (NIB) | Medium |

**Justification.** The size is the OLB frame and Designer boilerplate. The real screen has one trigger with logic:
`MCI_DATA.CR_NBR.KEY-NEXT-ITEM`. It looks for the registration in the local cache `MCI_DATA`; when it is there and
`LST_TRAN_DT` is today the block is queried at once; otherwise the MCI web service is called with
`.../mciImp/99/<CR_NBR>` (99 = head-office port) and on `'success'` the block is queried (the service has written
MCI_DATA / MCI_OWNERS), else the error "بيانات السجل التجارى رقم ... حالتة غير فعال أو بياناتة غير متاحة ..." is shown.
The two POST-QUERY triggers fill the descriptions of the status (`MCI_BUS_ID_STATUS`) and of the owner relation
(`MCI_RELATION_TYPES`). Nothing is changed by the user: all items except CR_NBR are not enterable.

## 2. Module header

| Property | Value |
|---|---|
| Form name | IMPR1170_CNTRL |
| Title | صيانة تفاويض الشركات الوسيطة |
| First navigation block | MCI_DATA |
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
  IMPR1170_CNTRL

MODIFIED
  APPDEV248       19/08/26  11:24 created by Form Generator for
                                  Form Builder Version 6.0.3.11.0

Repository APPLICATION SYSTEM
  IMPORTERS Version 1

PURPOSE
  تفاويض الشركات الوسيطة

MODULE DESCRIPTION
.
There are three basic tasks:
1- At the start, The user select an existed importer at the filed IMPR_NBR, then, a check about the importer suspension is done, if suspended then an error message is displayed and the program wait for new selection.
At the IMPR_NBR_AGENT_ID field, the user input an importer number or selects an existing one by using a list. Also, a check about the importer suspension is done, if suspended then an error message is displayed and the program wait
  for n
ew selection.
Also the IMPR_NBR_AGENT_ID must not equal to the IMPR_NBR, if the user select an equal values then the system display error message and wait for a new selection.
When insert new record, the h_create take the Current Date, and the field ATHRZTN_STA_CD take the default value 1 ساري =, and the ATHRZTN_CNCLD_DTstill null.
2- To modify an old authorization: The user can modify a valid Authorization record's fields (IMPR_NBR, IMPR_NBR_AGENT_ID,  ATHRZTN_NOTE). The Authorization record is valid if ATHRZTN_STA_CD = 1 and ATHRZTN_CNCLD_DT still = null, and
  not
 used at the Imphdr file (importer statement).
3- At all cases, if ATHRZTN_STA_CD = 1 and ATHRZTN_CNCLD_DT = null, then the user can soft delete an Authorization record (Set ATHRZTN_STA_CD = 2 and ATHRZTN_CNCLD_DT = current system date).


MODULE NOTES
Developed by Application Design Transformer from Function AGNT_AUTH10000
Candidate Module because it is an elementary Function
Identified as a screen because not overnight and not retrieval only
.
.



TABLE USAGES
  BASE   MCI_DATA                      SEL INS
  BASE   MCI_OWNERS                    SEL

WARNINGS - 19/08/26  11:24
  01280: display length = 12, item length = 10;
  01474: Combo-box list style invalid
  01280: display length = 12, item length = 10;
  01196: Column Usage MCI_DATA.CR_ISSUE_DATE has display length 12
         but format of length 10
  01196: Column Usage MCI_DATA.CR_EXPIRY_DATE has display length 12
         but format of length 10
  01242: MCI_OWNERS.OWNER_NAME enabled and navigable to allow
         scrolling on queried values
  01242: MCI_OWNERS.NATIONAL_ID enabled and navigable to allow
         scrolling on queried values
  01242: MCI_OWNERS.OWNER_NATIONALITY_AR enabled and navigable to
         allow scrolling on queried values
  01242: MCI_OWNERS.OWNER_NATIONALITY_EN enabled and navigable to
         allow scrolling on queried values
  01242: MCI_OWNERS. enabled and navigable to allow scrolling on
         queried values

*******************************************************************
```


## 3. Blocks

> Properties absent from the XML are Forms defaults **or inherited from the object library** (`ParentModule`/`ParentName`); such values are shown as `default/OLB` (OLB properties: `forms/COMMON/olb/CIC_OLB_OLB.xml`).

| Block | Base table / Query data source | DML target | Type | Records displayed | Records buffered | WHERE clause | ORDER BY | Insert | Update | Delete | Query | Canvas(es) | Subclassed from |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| TITLE | – | – | control (non-DB) | default/OLB | default/OLB | – | – | default/OLB | default/OLB | default/OLB | default/OLB | – | CIC_OLB.olb:TITLE |
| EDI_MSG | – | – | control (non-DB) | default/OLB | default/OLB | – | – | default/OLB | default/OLB | default/OLB | default/OLB | – | CIC_OLB.olb:EDI_MSG |
| LSIDE | – | – | control (non-DB) | default/OLB | default/OLB | – | – | default/OLB | default/OLB | default/OLB | default/OLB | – | CIC_OLB.olb:LSIDE |
| TOOLBAR | – | – | control (non-DB) | default/OLB | default/OLB | – | – | default/OLB | default/OLB | default/OLB | default/OLB | – | CIC_OLB.olb:TOOLBAR |
| MCI_DATA | MCI_DATA | same as query source (default) | base-table | default/OLB | 4 | – | – | default/OLB | false | false | default/OLB | CG$PAGE_1 | cic_olb.olb:CGSO$BLOCK |
| MCI_OWNERS | MCI_OWNERS | same as query source (default) | base-table | 4 | 7 | – | – | false | false | false | default/OLB | CG$PAGE_1 | cic_olb.olb:CGSO$BLOCK_MR |

Block `MCI_DATA` comment (decoded):

```text
*******************************************************************

BLOCK NAME
  MCI_DATA

TABLE COMMENT
  جدول بيانات السجل التجارى من وزارة التجارة

TABLE USAGES
  BASE   MCI_DATA                      SEL INS
  ...    CR_NBR                        SEL INS
  ...    CR_TYPE                       SEL
  ...    MAIN_CR_NBR                   SEL
  ...    CR_STATUS                     SEL
  ...    CR_ISSUE_DATE                 SEL         NUL
  ...    CR_EXPIRY_DATE                SEL         NUL
  ...    CR_CITY_AR                    SEL         NUL
  ...    CR_CAPITAL                    SEL         NUL
  ...    CR_NAME_AR                    SEL         NUL
  ...    LEGAL_TYPE_A                  SEL         NUL
  ...    LEGAL_TYPE_E                  SEL         NUL
  ...    CR_PHONE_NO                   SEL         NUL
  ...    CR_FAX_NO                     SEL         NUL
  ...    CR_ADDRESS                    SEL         NUL
  ...    CR_ACTIVITIES                 SEL         NUL

TUI DESCRIPTION


*******************************************************************
```

Block `MCI_OWNERS` comment (decoded):

```text
*******************************************************************

BLOCK NAME
  MCI_OWNERS

TABLE COMMENT
  جدول بيانات ملاك السجل التجارى مصدر المعلومة خدمة الربط مع وزارة التجارة

TABLE USAGES
  BASE   MCI_OWNERS                    SEL
  ...    OWNER_NAME                    SEL
  ...    NATIONAL_ID                   SEL
  ...    OWNER_NATIONALITY_AR          SEL
  ...    OWNER_NATIONALITY_EN          SEL
  ...    RELATION_TYPE                 SEL
  ...    CR_NBR
  ...    OWNER_ISN

JOIN CONDITION
  MCI_OWNERS.CR_NBR = MCI_DATA.CR_NBR

TUI DESCRIPTION


*******************************************************************
```


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

### 4.5 Block `MCI_DATA` (16 items)

| # | Item | Item type | Subclass (OLB) | Data type | Max len | Column name | DB item | Required | LOV | Default value | Format mask | Canvas / tab page | Visible | Insert / Update / Query allowed | Prompt / label | Copy-value-from / calc | List values / hint |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | CR_NBR | – | CGSO$CHAR_ARB | – | 10 | CR_NBR | – | true | – | – | – | CG$PAGE_1 | – | ·/false/· | الرقم الموحد للسجل التجاري | – | رقم السجل التجارى (رئيسى / فرعى) |
| 2 | CR_TYPE | – | CGSO$COMBO_DO | – | – | CR_TYPE | – | false | – | 1 | – | CG$PAGE_1 | – | – | نوع السجل التجارى | – | 1=رئيسي; 0=فرعي; 2=فرعي |
| 3 | MAIN_CR_NBR | – | CGSO$CHAR_ARB | – | 10 | MAIN_CR_NBR | – | false | – | – | – | CG$PAGE_1 | – | false/false/· | السجل التجارى الرئيسى | – | السجل التجارى الرئيسى |
| 4 | CR_STATUS | – | CGSO$CHAR_ARB | – | 2 | CR_STATUS | – | false | – | – | – | CG$PAGE_1 | – | false/false/· | حالة السجل التجارى | – | حالة السجل التجارى |
| 5 | CR_STAT_DESC | – | CGSO$CHAR_ARB_DO | – | – | – | false | false | – | – | – | CG$PAGE_1 | – | ·/·/true | – | – | Enter value for |
| 6 | CR_ISSUE_DATE | – | CGSO$HDATE_ARB_DO | – | – | CR_ISSUE_DATE | – | – | – | – | MI-MM-YYYY | CG$PAGE_1 | – | false/false/· | تاريخ انشاء السجل التجارى | – | تاريخ انشاء السجل التجارى |
| 7 | CR_EXPIRY_DATE | – | CGSO$HDATE_ARB_DO | – | – | CR_EXPIRY_DATE | – | – | – | – | MI-MM-YYYY | – | false | false/false/false | تاريخ انتهاء السجل التجارى | – | تاريخ انتهاء صلاحية السجل التجارى |
| 8 | CR_CITY_AR | – | CGSO$CHAR_ARB | – | 100 | CR_CITY_AR | – | – | – | – | – | CG$PAGE_1 | – | false/false/· | اسم المدينة | – | اسم المدينة |
| 9 | CR_CAPITAL | – | CGSO$CHAR_ARB | Number | 17 | CR_CAPITAL | – | – | – | – | – | CG$PAGE_1 | – | false/false/· | رأس المال | – | رأس المال |
| 10 | CR_NAME_AR | – | CGSO$CHAR_ARB | – | 240 | CR_NAME_AR | – | – | – | – | – | CG$PAGE_1 | – | false/false/· | الاسم التجارى | – | الاسم التجارى |
| 11 | LEGAL_TYPE_A | – | CGSO$CHAR_ARB | – | 100 | LEGAL_TYPE_A | – | – | – | – | – | CG$PAGE_1 | – | false/false/· | نوع المنشأة | – | نوع المنشأة |
| 12 | LEGAL_TYPE_E | – | CGSO$CHAR_ARB | – | 100 | LEGAL_TYPE_E | – | – | – | – | – | CG$PAGE_1 | – | false/false/· | نوع المنشأةEN | – | نوع المنشأة بالانجليزية |
| 13 | CR_PHONE_NO | – | CGSO$CHAR_ARB | – | 15 | CR_PHONE_NO | – | – | – | – | – | CG$PAGE_1 | – | false/false/· | التليفون | – | التليفون |
| 14 | CR_FAX_NO | – | CGSO$CHAR_ARB | – | 15 | CR_FAX_NO | – | – | – | – | – | CG$PAGE_1 | – | false/false/· | فاكس | – | فاكس |
| 15 | CR_ADDRESS | – | CGSO$CHAR_ARB | – | – | CR_ADDRESS | – | – | – | – | – | CG$PAGE_1 | – | false/false/· | العنوان | – | العنوان |
| 16 | CR_ACTIVITIES | – | CGSO$CHAR_ARB | – | 1000 | CR_ACTIVITIES | – | – | – | – | – | CG$PAGE_1 | – | false/false/· | النشاط التجارى | – | النشاط التجارى |

### 4.6 Block `MCI_OWNERS` (8 items)

| # | Item | Item type | Subclass (OLB) | Data type | Max len | Column name | DB item | Required | LOV | Default value | Format mask | Canvas / tab page | Visible | Insert / Update / Query allowed | Prompt / label | Copy-value-from / calc | List values / hint |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | OWNER_NAME | – | CGSO$CHAR_ARB | – | – | OWNER_NAME | – | false | – | – | – | CG$PAGE_1 | – | false/false/· | اسم المالك | – | اسم المالك |
| 2 | NATIONAL_ID | – | CGSO$CHAR_ARB | – | 15 | NATIONAL_ID | – | false | – | – | – | CG$PAGE_1 | – | false/false/· | رقم الهوية | – | رقم الهوية |
| 3 | OWNER_NATIONALITY_AR | – | CGSO$CHAR_ARB | – | – | OWNER_NATIONALITY_AR | – | false | – | – | – | CG$PAGE_1 | – | false/false/· | جنسية المالك | – | جنسية المالك |
| 4 | OWNER_NATIONALITY_EN | – | CGSO$CHAR_ARB | – | – | OWNER_NATIONALITY_EN | – | false | – | – | – | CG$PAGE_1 | – | false/false/· | جنسية المالكEN | – | جنسية المالك بالانجليزية |
| 5 | RELATION_TYPE | – | CGSO$CHAR_ARB_DO | Number | 4 | RELATION_TYPE | – | false | – | – | – | – | false | – | نوع العلاقة | – | نوع العلاقة |
| 6 | RELATION_DESC | – | CGSO$CHAR_ARB_DO | – | – | – | false | false | – | – | – | CG$PAGE_1 | – | – | العلاقة | – | Enter value for العلاقة |
| 7 | CR_NBR | – | CGSO$CHAR_MR_MD | – | 10 | CR_NBR | – | false | – | – | – | – | false | false/false/false | رقم السجل التجارى | MCI_DATA.CR_NBR | – |
| 8 | OWNER_ISN | – | CGSO$NUMBER_MR_MD | – | 11 | OWNER_ISN | – | false | – | – | – | – | false | false/false/false | رقم مسلسل | – | – |


## 5. Relations (master–detail)

| Relation | Master block | Detail block | Join condition | Delete behaviour | Deferred / Auto-query | Prevent masterless operations | Subclassed from |
|---|---|---|---|---|---|---|---|
| CGFK$MCI_OWNER_MCI_DATA_FK | MCI_DATA | MCI_OWNERS | MCI_DATA.CR_NBR = MCI_OWNERS.CR_NBR | not in XML → Forms default (Non-Isolated) | default (false)/default (false) | true | – |

## 6. Triggers


### 6.0 Trigger index

| # | Level | Owner | Trigger | Lines (total / active) | Exec. hierarchy | Source | Program units called |
|---|---|---|---|---|---|---|---|
| 1 | Form | FORM | KEY-EDIT | 21 / 1 | default (Override) | XML | – |
| 2 | Form | FORM | KEY-DUPREC | 10 / 1 | default (Override) | XML | – |
| 3 | Form | FORM | PRE-FORM | 36 / 10 | default (Override) | XML | – |
| 4 | Form | FORM | WHEN-NEW-FORM-INSTANCE | 153 / 17 | default (Override) | XML | CG$WHEN_NEW_FORM_INSTANCE |
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
| 210 | Block | MCI_DATA | ON-ERROR | 78 / 58 | default (Override) | XML | CGTE$CHECK_CONSTRAINT_VIO |
| 211 | Block | MCI_DATA | KEY-HELP | 18 / 16 | default (Override) | XML | – |
| 212 | Block | MCI_DATA | POST-QUERY | 8 / 8 | default (Override) | XML | – |
| 213 | Item | MCI_DATA.CR_NBR | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 214 | Item | MCI_DATA.CR_NBR | KEY-NEXT-ITEM | 47 / 32 | default (Override) | XML | – |
| 215 | Item | MCI_DATA.CR_NBR | WHEN-VALIDATE-ITEM | 3 / 3 | default (Override) | XML | – |
| 216 | Item | MCI_DATA.MAIN_CR_NBR | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 217 | Item | MCI_DATA.CR_STATUS | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 218 | Item | MCI_DATA.CR_STAT_DESC | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 219 | Item | MCI_DATA.CR_ISSUE_DATE | WHEN-VALIDATE-ITEM | 14 / 12 | default (Override) | XML | – |
| 220 | Item | MCI_DATA.CR_EXPIRY_DATE | WHEN-VALIDATE-ITEM | 14 / 12 | default (Override) | XML | – |
| 221 | Item | MCI_DATA.CR_CITY_AR | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 222 | Item | MCI_DATA.CR_CAPITAL | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 223 | Item | MCI_DATA.CR_NAME_AR | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 224 | Item | MCI_DATA.LEGAL_TYPE_A | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 225 | Item | MCI_DATA.LEGAL_TYPE_E | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 226 | Item | MCI_DATA.CR_PHONE_NO | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 227 | Item | MCI_DATA.CR_FAX_NO | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 228 | Item | MCI_DATA.CR_ADDRESS | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 229 | Item | MCI_DATA.CR_ACTIVITIES | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 230 | Block | MCI_OWNERS | ON-ERROR | 59 / 40 | default (Override) | XML | CGTE$CHECK_CONSTRAINT_VIO |
| 231 | Block | MCI_OWNERS | KEY-HELP | 18 / 16 | default (Override) | XML | – |
| 232 | Block | MCI_OWNERS | POST-QUERY | 10 / 8 | default (Override) | XML | – |
| 233 | Item | MCI_OWNERS.OWNER_NAME | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 234 | Item | MCI_OWNERS.NATIONAL_ID | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 235 | Item | MCI_OWNERS.OWNER_NATIONALITY_AR | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 236 | Item | MCI_OWNERS.OWNER_NATIONALITY_EN | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 237 | Item | MCI_OWNERS.RELATION_TYPE | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 238 | Item | MCI_OWNERS.RELATION_DESC | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 239 | Item | MCI_OWNERS.CR_NBR | KEY-LISTVAL | 34 / 32 | default (Override) | XML | – |

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
- Lines: 153 total / 17 active (non-blank, non-comment)
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
	:global.Port_CD 	:= NULL;
	:global.ATHRZTN_SEQ_NBR :=NULL;

	:global.Exec_Query_Now := 0;

        :GLOBAL.EXEC_QUERY:=0;
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

#### MCI_DATA · ON-ERROR

- Level: Block · Owner: `MCI_DATA` · Execution hierarchy: default (Override)
- Lines: 78 total / 58 active (non-blank, non-comment)
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

#### MCI_DATA · KEY-HELP

- Level: Block · Owner: `MCI_DATA` · Execution hierarchy: default (Override) · Fire in query: true
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

#### MCI_DATA · POST-QUERY

- Level: Block · Owner: `MCI_DATA` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 8 total / 8 active (non-blank, non-comment)
- Built-ins: –
- Program units (form): –
- Library / DB package calls: –

```plsql
BEGIN
SELECT MC.STATUS_DESC
INTO :CR_STAT_DESC
FROM MCI_BUS_ID_STATUS MC
WHERE MC.BUS_ID_STATUS = :MCI_DATA.CR_STATUS;
EXCEPTION WHEN OTHERS THEN
:CR_STAT_DESC:=NULL;
END;
```

#### MCI_OWNERS · ON-ERROR

- Level: Block · Owner: `MCI_OWNERS` · Execution hierarchy: default (Override) · Fire in query: true
- Lines: 59 total / 40 active (non-blank, non-comment)
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

    END IF;

    IF (err_type = 'FRM' AND
        err_code IN (41105, 41106) ) THEN
      IF (err_code = 41105) THEN
      Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(35, 'Query of <p1> must be in context of <p2>', 'جدول بيانات ملاك السجل التجارى','Mci Data' ), 'E', 'OFG', 35);
      Des$Form_errors.RAISE_FAILURE;
    ELSIF (err_code = 41106) THEN
      Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(36, 'Insert of <p1> must be in context of <p2>', 'جدول بيانات ملاك السجل التجارى','Mci Data' ), 'E', 'OFG', 36);
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

#### MCI_OWNERS · KEY-HELP

- Level: Block · Owner: `MCI_OWNERS` · Execution hierarchy: default (Override) · Fire in query: true
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

#### MCI_OWNERS · POST-QUERY

- Level: Block · Owner: `MCI_OWNERS` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 10 total / 8 active (non-blank, non-comment)
- Built-ins: –
- Program units (form): –
- Library / DB package calls: –

```plsql
BEGIN

SELECT MC.RELATION_NAME
INTO :RELATION_DESC
FROM MCI_RELATION_TYPES MC
WHERE MC.RELATION_CD = :MCI_OWNERS.RELATION_TYPE ;

EXCEPTION WHEN OTHERS THEN
NULL;
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

#### MCI_DATA.CR_NBR · KEY-LISTVAL

- Level: Item · Owner: `MCI_DATA.CR_NBR` · Execution hierarchy: default (Override)
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

#### MCI_DATA.CR_NBR · KEY-NEXT-ITEM

- Level: Item · Owner: `MCI_DATA.CR_NBR` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 47 total / 32 active (non-blank, non-comment)
- Built-ins: EXECUTE_QUERY, SET_BLOCK_PROPERTY
- Program units (form): –
- Library / DB package calls: LIB_USR.PRTL_NEBRAS_SERVICES.CALL_WEB_SERVICE, STR.DISPALERT

```plsql
DECLARE
	V_CR_NBR  NUMBER ;
  V_LST_DT  DATE;
  url_strg VARCHAR2(1000);
  V_respond VARCHAR2(1000);

BEGIN

	IF :MCI_DATA.CR_NBR IS NOT NULL THEN
	 BEGIN
	  SELECT CR_NBR , LST_TRAN_DT
	    INTO V_CR_NBR , V_LST_DT
	    FROM MCI_DATA
	     WHERE CR_NBR = :MCI_DATA.CR_NBR;

	 EXCEPTION WHEN OTHERS THEN
	 	V_CR_NBR  :=NULL;
	  V_LST_DT  :=NULL;
	 END;

	END IF;

 IF V_CR_NBR IS NOT NULL AND TO_CHAR(V_LST_DT,'DDMMYYYY') = TO_CHAR(SYSDATE,'DDMMYYYY')  THEN

  SET_BLOCK_PROPERTY('MCI_DATA',DEFAULT_WHERE,'CR_NBR='||V_CR_NBR);
     EXECUTE_QUERY (NO_VALIDATE);

 END IF;

 IF :MCI_DATA.CR_NBR IS NOT NULL AND ((TO_CHAR(V_LST_DT,'DDMMYYYY') <> TO_CHAR(SYSDATE,'DDMMYYYY')OR V_CR_NBR IS NULL )) THEN

    url_strg:='http://10.0.0.214:8080/MciDataWebSrvcs/webresources/mciImp/'||99||'/'||:MCI_DATA.CR_NBR ;

    V_respond := LIB_USR.prtl_nebras_services.call_web_service (url_strg);

    IF V_respond = 'success' THEN
      SET_BLOCK_PROPERTY('MCI_DATA',DEFAULT_WHERE,'CR_NBR='||:MCI_DATA.CR_NBR);
         EXECUTE_QUERY (NO_VALIDATE);
    ELSE

    	STR.DISPALERT('	بيانات السجل التجارى رقم '||:MCI_DATA.CR_NBR||' حالتة غير فعال أو بياناتة غير متاحة فى الوقت الحالى من خدمة الربط مع وزارة التجارة', 'ERROR');

    END IF;

 END IF;

END;
```

#### MCI_DATA.CR_NBR · WHEN-VALIDATE-ITEM

- Level: Item · Owner: `MCI_DATA.CR_NBR` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 3 total / 3 active (non-blank, non-comment)
- Built-ins: –
- Program units (form): –
- Library / DB package calls: –

```plsql
BEGIN
NULL;
END;
```

#### MCI_DATA.MAIN_CR_NBR · KEY-LISTVAL

- Level: Item · Owner: `MCI_DATA.MAIN_CR_NBR` · Execution hierarchy: default (Override)
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

#### MCI_DATA.CR_STATUS · KEY-LISTVAL

- Level: Item · Owner: `MCI_DATA.CR_STATUS` · Execution hierarchy: default (Override)
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

#### MCI_DATA.CR_STAT_DESC · KEY-LISTVAL

- Level: Item · Owner: `MCI_DATA.CR_STAT_DESC` · Execution hierarchy: default (Override)
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

#### MCI_DATA.CR_ISSUE_DATE · WHEN-VALIDATE-ITEM

- Level: Item · Owner: `MCI_DATA.CR_ISSUE_DATE` · Execution hierarchy: default (Override)
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

#### MCI_DATA.CR_EXPIRY_DATE · WHEN-VALIDATE-ITEM

- Level: Item · Owner: `MCI_DATA.CR_EXPIRY_DATE` · Execution hierarchy: default (Override)
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

#### MCI_DATA.CR_CITY_AR · KEY-LISTVAL

- Level: Item · Owner: `MCI_DATA.CR_CITY_AR` · Execution hierarchy: default (Override)
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

#### MCI_DATA.CR_CAPITAL · KEY-LISTVAL

- Level: Item · Owner: `MCI_DATA.CR_CAPITAL` · Execution hierarchy: default (Override)
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

#### MCI_DATA.CR_NAME_AR · KEY-LISTVAL

- Level: Item · Owner: `MCI_DATA.CR_NAME_AR` · Execution hierarchy: default (Override)
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

#### MCI_DATA.LEGAL_TYPE_A · KEY-LISTVAL

- Level: Item · Owner: `MCI_DATA.LEGAL_TYPE_A` · Execution hierarchy: default (Override)
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

#### MCI_DATA.LEGAL_TYPE_E · KEY-LISTVAL

- Level: Item · Owner: `MCI_DATA.LEGAL_TYPE_E` · Execution hierarchy: default (Override)
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

#### MCI_DATA.CR_PHONE_NO · KEY-LISTVAL

- Level: Item · Owner: `MCI_DATA.CR_PHONE_NO` · Execution hierarchy: default (Override)
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

#### MCI_DATA.CR_FAX_NO · KEY-LISTVAL

- Level: Item · Owner: `MCI_DATA.CR_FAX_NO` · Execution hierarchy: default (Override)
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

#### MCI_DATA.CR_ADDRESS · KEY-LISTVAL

- Level: Item · Owner: `MCI_DATA.CR_ADDRESS` · Execution hierarchy: default (Override)
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

#### MCI_DATA.CR_ACTIVITIES · KEY-LISTVAL

- Level: Item · Owner: `MCI_DATA.CR_ACTIVITIES` · Execution hierarchy: default (Override)
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

#### MCI_OWNERS.OWNER_NAME · KEY-LISTVAL

- Level: Item · Owner: `MCI_OWNERS.OWNER_NAME` · Execution hierarchy: default (Override)
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

#### MCI_OWNERS.NATIONAL_ID · KEY-LISTVAL

- Level: Item · Owner: `MCI_OWNERS.NATIONAL_ID` · Execution hierarchy: default (Override)
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

#### MCI_OWNERS.OWNER_NATIONALITY_AR · KEY-LISTVAL

- Level: Item · Owner: `MCI_OWNERS.OWNER_NATIONALITY_AR` · Execution hierarchy: default (Override)
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

#### MCI_OWNERS.OWNER_NATIONALITY_EN · KEY-LISTVAL

- Level: Item · Owner: `MCI_OWNERS.OWNER_NATIONALITY_EN` · Execution hierarchy: default (Override)
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

#### MCI_OWNERS.RELATION_TYPE · KEY-LISTVAL

- Level: Item · Owner: `MCI_OWNERS.RELATION_TYPE` · Execution hierarchy: default (Override)
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

#### MCI_OWNERS.RELATION_DESC · KEY-LISTVAL

- Level: Item · Owner: `MCI_OWNERS.RELATION_DESC` · Execution hierarchy: default (Override)
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

#### MCI_OWNERS.CR_NBR · KEY-LISTVAL

- Level: Item · Owner: `MCI_OWNERS.CR_NBR` · Execution hierarchy: default (Override)
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

### 7.1 Record groups


## 8. Canvases & Windows

| Canvas | Type | Window | Size (W×H) | Viewport | Tab pages | Items shown | Subclassed from |
|---|---|---|---|---|---|---|---|
| LSIDE | Content (default) / OLB | default/OLB | – | – | – | 0: – | CIC_OLB.olb:LSIDE |
| EDI_MSG | Content (default) / OLB | default/OLB | – | – | – | 0: – | CIC_OLB.olb:EDI_MSG |
| TITLE | Content (default) / OLB | default/OLB | – | – | – | 0: – | CIC_OLB.olb:TITLE |
| TOOLBAR | Content (default) / OLB | default/OLB | – | – | – | 0: – | CIC_OLB.olb:TOOLBAR |
| CG$PAGE_1 | Content (default) / OLB | CGSO$WINDOW_1 | 8510×5531 | 0×5531 | – | 20: CR_NBR, CR_TYPE, MAIN_CR_NBR, CR_STATUS, CR_STAT_DESC, CR_ISSUE_DATE, CR_CITY_AR, CR_CAPITAL, CR_NAME_AR, LEGAL_TYPE_A, LEGAL_TYPE_E, CR_PHONE_NO, CR_FAX_NO, CR_ADDRESS, CR_ACTIVITIES, OWNER_NAME, NATIONAL_ID, OWNER_NATIONALITY_AR, OWNER_NATIONALITY_EN, RELATION_DESC | cic_olb.olb:CGSO$CANVAS |

| Window | Modal | Title | Size | Subclassed from |
|---|---|---|---|---|
| CGSO$WINDOW_1 | default/OLB | Agnts | default/OLB | cic_olb.olb:CGSO$WINDOW_1 |

Graphics objects on canvases (boilerplate, from XML):

| Canvas | Name | Type | Subclassed from |
|---|---|---|---|
| LSIDE | LINE617 | not in XML (OLB sub-object) | – |
| TITLE | RECT9 | not in XML (OLB sub-object) | – |
| TITLE | RECT10 | not in XML (OLB sub-object) | – |
| CG$PAGE_1 | CG_BOILERPLATE_GROUP | Group | – |
| CG$PAGE_1 | CG_RECT_1 | not in XML (OLB sub-object) | CIC_OLB.OLB:CG_RECT |
| CG$PAGE_1 | CG_RECT_2 | not in XML (OLB sub-object) | CIC_OLB.OLB:CG_RECT |


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
| 16 | CGDV$POPULATE_DYNAMIC_LISTS | Procedure | 16 / 13 | PU CG$WHEN_NEW_FORM_INSTANCE | CREATE_GROUP_FROM_QUERY, DELETE_GROUP, POPULATE_GROUP, POPULATE_LIST | – | – |
| 17 | CGTE$CHECK_CONSTRAINT_VIO | Function | 35 / 27 | MCI_DATA.ON-ERROR, MCI_OWNERS.ON-ERROR | – | – | CGTE$STRIP_CONSTRAINT, CGTE$STRIP_FIRST_ERROR, DES$FORM_ERRORS.MSGGETTEXT, DES$FORM_ERRORS.PUSH |
| 18 | CGBS$TOGGLE | Procedure | 24 / 15 | FORM.KEY-MENU | – | CGBS$MESSAGE_QUERY_MODE, CGBS$SET_QUERY_MODE | CGBS$.COORD_VISIBLE_BLKS, CGBS$.SET_RELATIONS |
| 19 | CGBS$SET_QUERY_MODE | Procedure | 7 / 5 | PU CG$WHEN_NEW_FORM_INSTANCE, PU CGBS$TOGGLE | – | – | – |
| 20 | CGBS$MESSAGE_QUERY_MODE | Procedure | 11 / 9 | PU CGBS$TOGGLE | – | – | DES$FORM_ERRORS.PUSH |
| 21 | EXEC_FUNS | Procedure | 40 / 6 | PU EXECUTE_FUNCTION | – | – | – |
| 22 | ADJ_FUNS | Procedure | 4 / 4 | FORM.KEY-F9, TOOLBAR.FUN_BUT.WHEN-MOUSE-DOWN | – | – | – |

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

### PU CGDV$POPULATE_DYNAMIC_LISTS (Procedure, 16 lines)

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
    'WHERE  RV_DOMAIN = ''COMM_RGSTRTN_TYPE'' '||
    'ORDER BY  2');
  temp := populate_group(rg_id);
  populate_list('MCI_DATA.CR_TYPE', rg_id);
  delete_group(rg_id);

END;
```

### PU CGTE$CHECK_CONSTRAINT_VIO (Function, 35 lines)

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
    IF (constraint_name = 'MCI_DATA_PK') THEN
      Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(6, 'Row exists already with same <p1>', 'الرقم الموحد للسجل التجاري' ), 'E', 'OFG', 6);
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

### PU EXEC_FUNS (Procedure, 40 lines)

```plsql
PROCEDURE EXEC_FUNS(CD VARCHAR2) IS
		HDate DATE ;
		RET NUMBER;
BEGIN
/*
IF CD LIKE 'CD1_STOPIMPRAUTH' THEN
	HDate := HIJDATE.Cur_Hij_Date;
	IF :ATHRZTN_SEQ_NBR IS NOT NULL AND :ATHRZTN_STA_CD = 1 THEN
		RET := STR.DispArbMsg(9, 50,'CONFIRM');
		IF Ret = alert_button1 THEN
			:PARAMETER.P_FUNCTION_CD := 1;
 			:ATHRZTN_STA_CD := 2;
			:ATHRZTN_CNCLD_DT := HDate;
			IF NOT ACTIVITY.ADD_ACTIVITY(9, 1, 3, :PORT_CD||'!'||:ATHRZTN_SEQ_NBR) THEN
				RAISE FORm_Trigger_Failure;
			END IF;
			COMMIT;
		END IF;
	END IF;
	:PARAMETER.P_FUNCTION_CD := 0;

ELSIF CD LIKE 'CD2_REUSEIMPRAUTH' THEN
	IF :ATHRZTN_SEQ_NBR IS NOT NULL AND :ATHRZTN_STA_CD = 2 THEN
		RET := STR.DispALERT('سيتم إسترجاع التفويض - هل ترغب في إستكمال الإسترجاع','CONFIRM');
		IF Ret = alert_button1 THEN

			:PARAMETER.P_FUNCTION_CD := 1;
			INTRFACE.Make_Block_Full_Operation( 'AGNTS', TRUE, TRUE, FALSE );
 			:ATHRZTN_STA_CD := 1;
			:ATHRZTN_CNCLD_DT := NULL;
			IF NOT ACTIVITY.ADD_ACTIVITY(9, 1, 4, :PORT_CD||'!'||:ATHRZTN_SEQ_NBR) THEN
				RAISE FORm_Trigger_Failure;
			END IF;
			COMMIT;
		END IF;
	END IF;
	:PARAMETER.P_FUNCTION_CD := 0;
END IF;*/
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
| ADJ_PRN.ADJ_REPORT_PRINTER | 1 | PU EXECUTE_FUNCTION |
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
| CGHP$CALL_MS_HELP | 3 | FORM.KEY-HELP, MCI_DATA.KEY-HELP, MCI_OWNERS.KEY-HELP |
| CGHP$PRE_FORM | 1 | FORM.PRE-FORM |
| CGTE$OTHER_EXCEPTIONS | 6 | FORM.KEY-CLRFRM, FORM.KEY-HELP, FORM.WHEN-NEW-FORM-INSTANCE, MCI_DATA.KEY-HELP, MCI_OWNERS.KEY-HELP, PU CG$WHEN_NEW_FORM_INSTANCE |
| CGTE$POP_ERROR_STACK | 2 | MCI_DATA.ON-ERROR, MCI_OWNERS.ON-ERROR |
| CGTE$STRIP_CONSTRAINT | 3 | MCI_DATA.ON-ERROR, MCI_OWNERS.ON-ERROR, PU CGTE$CHECK_CONSTRAINT_VIO |
| CGTE$STRIP_FIRST_ERROR | 1 | PU CGTE$CHECK_CONSTRAINT_VIO |
| DES$FORM_ERRORS.MSGGETTEXT | 7 | FORM.KEY-CQUERY, FORM.KEY-HELP, FORM.KEY-NXTKEY, MCI_DATA.KEY-HELP, MCI_OWNERS.KEY-HELP, MCI_OWNERS.ON-ERROR, PU CGTE$CHECK_CONSTRAINT_VIO |
| DES$FORM_ERRORS.PUSH | 9 | FORM.KEY-CQUERY, FORM.KEY-HELP, FORM.KEY-NXTKEY, MCI_DATA.KEY-HELP, MCI_DATA.ON-ERROR, MCI_OWNERS.KEY-HELP, MCI_OWNERS.ON-ERROR, PU CGBS$MESSAGE_QUERY_MODE … (+1) |
| DES$FORM_ERRORS.RAISE_FAILURE | 4 | FORM.KEY-CQUERY, FORM.KEY-NXTKEY, MCI_DATA.ON-ERROR, MCI_OWNERS.ON-ERROR |
| HIJDATE.CUR_HIJ_DATE | 3 | TOOLBAR.EXIT1.WHEN-BUTTON-PRESSED, TOOLBAR.RE_ENTER_QUERY.WHEN-BUTTON-PRESSED, TOOLBAR.SAVE.WHEN-BUTTON-PRESSED |
| HIJDATE.VALID_HIJ_DATE | 3 | MCI_DATA.CR_EXPIRY_DATE.WHEN-VALIDATE-ITEM, MCI_DATA.CR_ISSUE_DATE.WHEN-VALIDATE-ITEM, TITLE.SYSTEM_DATE.WHEN-VALIDATE-ITEM |
| KEY_CONTROL.FOUND_KEY | 1 | TOOLBAR.EXIT1.WHEN-BUTTON-PRESSED |
| LIB_USR.PRTL_NEBRAS_SERVICES.CALL_WEB_SERVICE | 1 | MCI_DATA.CR_NBR.KEY-NEXT-ITEM |
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
| STR.DISPALERT | 3 | MCI_DATA.CR_NBR.KEY-NEXT-ITEM, PU EXECUTE_FUNCTION, TOOLBAR.EXIT.WHEN-BUTTON-PRESSED |
| TMPLT.ENB_DIS_FUN_BUT | 1 | TOOLBAR.EXIT1.WHEN-BUTTON-PRESSED |
| TMPLT.FUN_ITEMS | 1 | PU EXECUTE_FUNCTION |
| TMPLT.KEYB_UP_DOWN | 3 | FORM.KEY-F9, TOOLBAR.KEY-DOWN, TOOLBAR.KEY-UP |
| TMPLT.POPULATE_FUNCTIONS | 2 | FORM.KEY-F9, TOOLBAR.FUN_BUT.WHEN-MOUSE-UP |


### 10.4 Called forms

| Caller | Built-in | Arguments (verbatim) | ADD_PARAMETER calls in the same unit (name, type, value) |
|---|---|---|---|
| PU EXECUTE_FUNCTION | CALL_FORM | `V_CALLED_FORM, no_hide, no_replace, no_query_only, pl_id` | P_USER_ID TEXT_PARAMETER = :PARAMETER.P_USER_ID; P_USER_NAME TEXT_PARAMETER = :PARAMETER.P_USER_NAME; P_WS_ID TEXT_PARAMETER = :PARAMETER.P_WS_ID; P_CURR_PORT_CD TEXT_PARAMETER = :PARAMETER.P_CURR_PORT_CD; P_PORT_TYPE TEXT_PARAMETER = :PARAMETER.P_PORT_TYPE; P_GROUP_CD TEXT_PARAMETER = :PARAMETER.P_GROUP_CD; P_USER_TYPE TEXT_PARAMETER = :PARAMETER.P_USER_TYPE; P_JOB_ID TEXT_PARAMETER = :PARAMETER.P_JOB_ID; P_CLASS_CD TEXT_PARAMETER = :PARAMETER.P_CLASS_CD; P_MODULE_ID TEXT_PARAMETER = TMPLT.FUN_ITEMS(ROW_COUNT).MID; P_MODULE_NAME TEXT_PARAMETER = V_MOD_NAME; P_BRKR_PORT_CD TEXT_PARAMETER = :PARAMETER.P_BRKR_PORT_CD; P_SHPG_AGNT_NBR TEXT_PARAMETER = :PARAMETER.P_SHPG_AGNT_NBR; P_BRKR_NBR TEXT_PARAMETER = :PARAMETER.P_BRKR_NBR; P_LIC_TYPE TEXT_PARAMETER = :PARAMETER.P_LIC_TYPE; P_BANK_CD TEXT_PARAMETER = :PARAMETER.P_BANK_CD; P_BANK_BRNCH_CD TEXT_PARAMETER = :PARAMETER.P_BANK_BRNCH_CD; P_SYS_ID TEXT_PARAMETER = :GLOBAL.SYSTEM_OBJ; P_REP_NO TEXT_PARAMETER = V_SEQ_NO; P_REPORT_NO TEXT_PARAMETER = :GLOBAL.SYSTEM_OBJ \|\|'-'\|\|V_SEQ_NO; DESTYPE TEXT_PARAMETER = 'PRINTER'; PARAMFORM TEXT_PARAMETER = 'NO'; ORACLE_SHUTDOWN TEXT_PARAMETER = 'YES'; MAXIMIZE TEXT_PARAMETER = 'YES' |
| PU EXECUTE_FUNCTION | CALL_FORM | `V_CALLED_FORM, no_hide, no_replace, no_query_only, pl_id` | P_USER_ID TEXT_PARAMETER = :PARAMETER.P_USER_ID; P_USER_NAME TEXT_PARAMETER = :PARAMETER.P_USER_NAME; P_WS_ID TEXT_PARAMETER = :PARAMETER.P_WS_ID; P_CURR_PORT_CD TEXT_PARAMETER = :PARAMETER.P_CURR_PORT_CD; P_PORT_TYPE TEXT_PARAMETER = :PARAMETER.P_PORT_TYPE; P_GROUP_CD TEXT_PARAMETER = :PARAMETER.P_GROUP_CD; P_USER_TYPE TEXT_PARAMETER = :PARAMETER.P_USER_TYPE; P_JOB_ID TEXT_PARAMETER = :PARAMETER.P_JOB_ID; P_CLASS_CD TEXT_PARAMETER = :PARAMETER.P_CLASS_CD; P_MODULE_ID TEXT_PARAMETER = TMPLT.FUN_ITEMS(ROW_COUNT).MID; P_MODULE_NAME TEXT_PARAMETER = V_MOD_NAME; P_BRKR_PORT_CD TEXT_PARAMETER = :PARAMETER.P_BRKR_PORT_CD; P_SHPG_AGNT_NBR TEXT_PARAMETER = :PARAMETER.P_SHPG_AGNT_NBR; P_BRKR_NBR TEXT_PARAMETER = :PARAMETER.P_BRKR_NBR; P_LIC_TYPE TEXT_PARAMETER = :PARAMETER.P_LIC_TYPE; P_BANK_CD TEXT_PARAMETER = :PARAMETER.P_BANK_CD; P_BANK_BRNCH_CD TEXT_PARAMETER = :PARAMETER.P_BANK_BRNCH_CD; P_SYS_ID TEXT_PARAMETER = :GLOBAL.SYSTEM_OBJ; P_REP_NO TEXT_PARAMETER = V_SEQ_NO; P_REPORT_NO TEXT_PARAMETER = :GLOBAL.SYSTEM_OBJ \|\|'-'\|\|V_SEQ_NO; DESTYPE TEXT_PARAMETER = 'PRINTER'; PARAMFORM TEXT_PARAMETER = 'NO'; ORACLE_SHUTDOWN TEXT_PARAMETER = 'YES'; MAXIMIZE TEXT_PARAMETER = 'YES' |

### 10.5 Database tables / views referenced in SQL (5)

Extracted from active (non-comment) code. Record-group queries are listed in section 7.

| Object | DML used | Referenced in |
|---|---|---|
| MCI_BUS_ID_STATUS | SELECT | MCI_DATA.POST-QUERY |
| MCI_DATA | SELECT | MCI_DATA.CR_NBR.KEY-NEXT-ITEM |
| MCI_RELATION_TYPES | SELECT | MCI_OWNERS.POST-QUERY |
| SC_PORT_SETTING | SELECT | PU EXECUTE_FUNCTION |
| SC_SYSTEM_OBJECTS | SELECT | PU EXECUTE_FUNCTION |


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
| P_CURR_PORT_CD | default (CHAR) / OLB | default/OLB | P_CURR_PORT_CD | FORM.WHEN-NEW-FORM-INSTANCE, PU CHECK_EDI_MSG_LOV, PU CHECK_EDI_MSG_TIMER, PU CHECK_TIMEOUT, PU EXECUTE_FUNCTION, PU FOR_EDI_MSG, PU PRINT_REPORT |
| P_MODULE_ID | default (CHAR) / OLB | default/OLB | P_MODULE_ID | FORM.WHEN-NEW-FORM-INSTANCE |
| P_MODULE_NAME | default (CHAR) / OLB | default/OLB | P_MODULE_NAME | FORM.KEY-DUPREC, FORM.KEY-EDIT, FORM.KEY-F5, FORM.WHEN-NEW-FORM-INSTANCE, FORM.WHEN-WINDOW-ACTIVATED, TOOLBAR.EXIT1.WHEN-BUTTON-PRESSED, TOOLBAR.RE_ENTER_QUERY.WHEN-BUTTON-PRESSED, TOOLBAR.SAVE.WHEN-BUTTON-PRESSED |
| P_APPLICATION_NAME | default (CHAR) / OLB | default/OLB | P_APPLICATION_NAME | – |
| P_USER_ID | default (CHAR) / OLB | default/OLB | P_USER_ID | FORM.WHEN-NEW-FORM-INSTANCE, PU EDI_MSG_LOV, PU EXECUTE_FUNCTION, PU FOR_EDI_MSG, PU PRINT_REPORT |
| P_WS_ID | default (CHAR) / OLB | default/OLB | P_WS_ID | PU EXECUTE_FUNCTION, PU PRINT_REPORT |
| P_USER_NAME | default (CHAR) / OLB | default/OLB | P_USER_NAME | FORM.KEY-DUPREC, FORM.KEY-EDIT, FORM.KEY-F5, FORM.WHEN-WINDOW-ACTIVATED, PU EDI_MSG_LOV, PU EXECUTE_FUNCTION, PU PRINT_REPORT, TOOLBAR.EXIT1.WHEN-BUTTON-PRESSED, TOOLBAR.RE_ENTER_QUERY.WHEN-BUTTON-PRESSED, TOOLBAR.SAVE.WHEN-BUTTON-PRESSED |
| CG$STARTUP_MODE | default (CHAR) / OLB | NORMAL | – | – |

### 12.1 :GLOBAL variables (9)

| Global | Read in | Written in |
|---|---|---|
| ATHRZTN_SEQ_NBR | – | FORM.WHEN-NEW-FORM-INSTANCE |
| CG$HP_HFILE | FORM.KEY-HELP, MCI_DATA.KEY-HELP, MCI_OWNERS.KEY-HELP | FORM.KEY-HELP, MCI_DATA.KEY-HELP, MCI_OWNERS.KEY-HELP |
| CG$HP_HPATH | FORM.KEY-HELP, MCI_DATA.KEY-HELP, MCI_OWNERS.KEY-HELP | FORM.PRE-FORM |
| CG$QUERY_MODE | FORM.KEY-MENU, FORM.ON-POPULATE-DETAILS, FORM.WHEN-NEW-BLOCK-INSTANCE, PU CG$WHEN_NEW_FORM_INSTANCE | PU CG$WHEN_NEW_FORM_INSTANCE |
| EXEC_QUERY | – | FORM.WHEN-NEW-FORM-INSTANCE |
| EXEC_QUERY_NOW | – | FORM.WHEN-NEW-FORM-INSTANCE |
| EXIT | TOOLBAR.EXIT.WHEN-BUTTON-PRESSED | – |
| PORT_CD | – | FORM.WHEN-NEW-FORM-INSTANCE |
| SYSTEM_OBJ | PU EXECUTE_FUNCTION | PU EXECUTE_FUNCTION (DEFAULT_VALUE) |

### 12.2 :SYSTEM variables (12)

| Variable | Used in |
|---|---|
| BLOCK_STATUS | FORM.KEY-CLRREC |
| COORDINATION_OPERATION | FORM.ON-CLEAR-DETAILS |
| CURRENT_FORM | TOOLBAR.EXIT1.WHEN-BUTTON-PRESSED |
| CURSOR_BLOCK | FORM.ON-POPULATE-DETAILS, FORM.WHEN-NEW-BLOCK-INSTANCE, MCI_DATA.CR_ACTIVITIES.KEY-LISTVAL, MCI_DATA.CR_ADDRESS.KEY-LISTVAL, MCI_DATA.CR_CAPITAL.KEY-LISTVAL, MCI_DATA.CR_CITY_AR.KEY-LISTVAL … (+17) |
| CURSOR_ITEM | MCI_DATA.CR_ACTIVITIES.KEY-LISTVAL, MCI_DATA.CR_ADDRESS.KEY-LISTVAL, MCI_DATA.CR_CAPITAL.KEY-LISTVAL, MCI_DATA.CR_CITY_AR.KEY-LISTVAL, MCI_DATA.CR_EXPIRY_DATE.WHEN-VALIDATE-ITEM, MCI_DATA.CR_FAX_NO.KEY-LISTVAL … (+17) |
| CURSOR_RECORD | MCI_DATA.CR_ACTIVITIES.KEY-LISTVAL, MCI_DATA.CR_ADDRESS.KEY-LISTVAL, MCI_DATA.CR_CAPITAL.KEY-LISTVAL, MCI_DATA.CR_CITY_AR.KEY-LISTVAL, MCI_DATA.CR_FAX_NO.KEY-LISTVAL, MCI_DATA.CR_NAME_AR.KEY-LISTVAL … (+14) |
| CURSOR_VALUE | MCI_DATA.CR_EXPIRY_DATE.WHEN-VALIDATE-ITEM, MCI_DATA.CR_ISSUE_DATE.WHEN-VALIDATE-ITEM, TITLE.SYSTEM_DATE.WHEN-VALIDATE-ITEM |
| FORM_STATUS | FORM.KEY-CLRFRM, TOOLBAR.SAVE.WHEN-BUTTON-PRESSED |
| MASTER_BLOCK | FORM.ON-CLEAR-DETAILS |
| MODE | FORM.KEY-CQUERY, MCI_DATA.CR_ACTIVITIES.KEY-LISTVAL, MCI_DATA.CR_ADDRESS.KEY-LISTVAL, MCI_DATA.CR_CAPITAL.KEY-LISTVAL, MCI_DATA.CR_CITY_AR.KEY-LISTVAL, MCI_DATA.CR_FAX_NO.KEY-LISTVAL … (+16) |
| TRIGGER_BLOCK | FORM.KEY-CLRREC, FORM.KEY-CQUERY, FORM.ON-CLEAR-DETAILS |
| TRIGGER_ITEM | MCI_DATA.CR_EXPIRY_DATE.WHEN-VALIDATE-ITEM, MCI_DATA.CR_ISSUE_DATE.WHEN-VALIDATE-ITEM, TITLE.SYSTEM_DATE.WHEN-VALIDATE-ITEM |


## 13. Menu & Security

### 13.1 Menu and functions

| Property | Value |
|---|---|
| Menu module | `CIC_MENU`; SET_MENU_ITEM_PROPERTY not used |
| In-form "menu" | `LSIDE` side menu / `KEY-F9`: the module functions from `SC_SYSTEM_OBJECTS` (TMPLT). `ADJ_FUNS` and `EXEC_FUNS` are empty: the form defines no function of its own |

### 13.2 Data security

| Mechanism | Location | Details |
|---|---|---|
| Query scope | blocks have no WHERE clause | MCI_DATA is the national registration cache (not per port); every user who can open the form sees every cached registration |
| Web service | CR_NBR.KEY-NEXT-ITEM | called with port 99 and the typed CR_NBR; the DB package `LIB_USR.PRTL_NEBRAS_SERVICES` does the HTTP call and the inserts (MISSING SOURCE) |
| Insert | block Insert Allowed (Designer default), table usage `MCI_DATA SEL INS` | the clerk could press SAVE on the new record (CR_NBR + CR_TYPE 1) without KEY-NEXT-ITEM and insert a bare row – see §14 #2 |
| Privilege errors | MCI_DATA.ON-ERROR (ORA-01031 + FRM-40508/9/10) | "ليس لديك صلاحية الادخال / التعديل / الحذف": table grants of the user |

### 13.3 APEX mapping notes

- Page access: the application's existing privileges (CLAUDE.md §8); no authorization schemes.
- The ORA-01031 messages are not needed: APEX runs as the parsing schema.
- No Page Functions of its own (ADJ_FUNS / EXEC_FUNS are empty); the page 0 FUNCS drawer shows the module list as for every page.

## 14. Risk Assessment

| # | Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|---|
| 1 | The look-up runs only in KEY-NEXT-ITEM (Tab / Enter); with the mouse the form shows nothing | Certain | UI | APEX: DA on change of CR_NBR (always fires) submits the request EXECUTE_QUERY |
| 2 | The block allows insert: SAVE on a new record writes a bare MCI_DATA row (CR_NBR, CR_TYPE 1) that the service never filled | Low | Data quality | APEX refuses CREATE / SAVE / DELETE with a message (as IMPR1150); decision in the page spec, open question §15 #1 |
| 3 | The web-service URL has a fixed internal address `http://10.0.0.214:8080/MciDataWebSrvcs/...` | Certain | Environment move | Kept in one package constant; `-- SUGGESTION:` move it to a customs setting / Application Setting |
| 4 | `V_CR_NBR` is NUMBER while CR_NBR is a VARCHAR2(10) item: a non-numeric number raises ORA-06502 inside the `WHEN OTHERS` handler path and is treated as "not cached" | Low | The service is called with the text | Kept as Forms (the variable is a NUMBER in the package too) |
| 5 | The cache test compares days (`TO_CHAR(LST_TRAN_DT, 'DDMMYYYY') = TO_CHAR(SYSDATE, 'DDMMYYYY')`): a record loaded yesterday is reloaded today | Certain | One service call per CR per day | Kept |
| 6 | `LIB_USR.PRTL_NEBRAS_SERVICES.CALL_WEB_SERVICE`: DB package without source; it does the HTTP call (UTL_HTTP / ACL) and the inserts | Certain | Compilation / grants / network ACL | Called unchanged; LIB_APX_USR needs EXECUTE on it (MISSING SOURCE) |
| 7 | Hijri dates stored as DATE with the day in the minutes (`MI-MM-YYYY`) | Certain | Display | Display only with the format mask `FORMS_APX.HIJRI_DATE_FORMAT` (Application Setting, as IMPR1150) |
| 8 | The two POST-QUERY triggers swallow every error (`WHEN OTHERS`) | Low | Empty description | Kept: outer join / NO_DATA_FOUND + TOO_MANY_ROWS → NULL |

## 15. Open Questions / Missing Sources

| # | Open question / missing source | Status (2026-11-25) | Why it matters | Needed from |
|---|---|---|---|---|
| 1 | Insert from the form (SAVE on the new record without the look-up): keep it? | Decided in the spec: refused (no DML on the page, as IMPR1150), to confirm | Data quality | Business owner |
| 2 | Package `LIB_USR.PRTL_NEBRAS_SERVICES` (`CALL_WEB_SERVICE`) and the MCI service contract (`'success'` answer, tables it writes) | **MISSING SOURCE** – call copied unchanged | Compilation / grants / ACL | DBA / integration team |
| 3 | Web-service address `10.0.0.214:8080` per environment | Open: kept as in Forms (package constant) | Environment move | Integration team |
| 4 | DDL of `MCI_DATA` (key `MCI_DATA_PK` on CR_NBR, LST_TRAN_DT), `MCI_OWNERS` (key OWNER_ISN), `MCI_BUS_ID_STATUS`, `MCI_RELATION_TYPES` | **MISSING SOURCE** – taken from the Forms items | Package types / region keys | DBA |
| 5 | Module title "صيانة تفاويض الشركات الوسيطة" and window title "Agnts" do not describe the screen | Open: page title from the f345 module list, fallback "بيانات السجل التجارى من وزارة التجارة" | Labels | Business owner |
| 6 | CR_TYPE list values: XML has 1 رئيسي, 0 فرعي, 2 فرعي; the runtime list comes from CG_REF_CODES `COMM_RGSTRTN_TYPE` | Preserved (LOV `LOV_COMM_RGSTRTN_TYPE`, IMPR1130) | Display | – |
