
## 1. Summary


## 2. Module header

| Property | Value |
|---|---|
| Form name | IMPR1130_PROD_CENTRL |
| Title | إضافة وتعديل بيانات مستورد |
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
  IMPR1130_PROD_CENTRL

MODIFIED
  APPDEV248       19/08/26  11:30 created by Form Generator for
                                  Form Builder Version 6.0.3.11.0

Repository APPLICATION SYSTEM
  IMPORTERS Version 1

PURPOSE
  إضافة مستورد (مساندة فنية

MODULE DESCRIPTION
.
The Module used to add new importer or modify an existed one.

MODULE NOTES
Developed by Application Design Transformer from Function IMPR10000
Candidate Module because it is an elementary Function
.
Identified as a screen because not overnight and not retrieval only
.



TABLE USAGES
  BASE   IMPORTERS                     SEL INS UPD DEL

REFERENTIAL INTEGRITY RULES
Block IMPORTERS
  Deletion of IMPORTERS prevented if MASS_DUTY_DEF_STLMNTS records exist
  Foreign key(s): MDDS_IMP_FK
  Deletion of IMPORTERS prevented if BA_WAREHOUSES records exist
  Foreign key(s): BW_IMP_FK
  Deletion of IMPORTERS prevented if BL_OWNERS records exist
  Foreign key(s): BO_IMP_FK
  Deletion of IMPORTERS prevented if VHCL_CAR_EXPTON records exist
  Foreign key(s): VCE_IMP_FK
  Deletion of IMPORTERS prevented if SANDY_EXPORTS records exist
  Foreign key(s): SE_IMP_FK
  Deletion of IMPORTERS prevented if ELIMINATE_REQUESTS records exist
  Foreign key(s): ER_IMP_FK
  Deletion of IMPORTERS prevented if EXMTN_A_FORMS records exist
  Foreign key(s): AFRM_IMP_FK
  Deletion of IMPORTERS prevented if WAIVERS records exist
  Foreign key(s): WVR_IMP_FK
  Deletion of IMPORTERS prevented if DECLARATIONS records exist
  Foreign key(s): DCLTN_AGNT_IMPR_FK
  Deletion of IMPORTERS prevented if MISSING_DCLTNS records exist
  Foreign key(s): MD_IMP_FK
  Deletion of IMPORTERS prevented if CREDIT_LETTERS records exist
  Foreign key(s): CL_IMP_FK
  Deletion of IMPORTERS prevented if DELAY_SEA_DLVY_ORDERS records exist
  Foreign key(s): DSD_IMP_FK
  Deletion of IMPORTERS prevented if DECLARATIONS records exist
  Foreign key(s): DCLTN_IMP_FK
  Deletion of IMPORTERS prevented if DCLTN_DOCS records exist
  Foreign key(s): DCL_DOC_IMP_FK
  Deletion of IMPORTERS prevented if CLIENT_PAY_ACCTS records exist
  Foreign key(s): CPAS_IMP_FK
  Deletion of IMPORTERS prevented if DECLARATIONS records exist
  Foreign key(s): DCLTN_MNFCT_IMPR_FK
  Deletion of IMPORTERS prevented if SMPL_20_DECLERATIONS records exist
  Foreign key(s): S2D_IMP_FK
  Deletion of IMPORTERS prevented if BRKIMPS records exist
  Foreign key(s): BI_IMP_FK
  Deletion of IMPORTERS prevented if VHCL_AUCTION records exist
  Foreign key(s): VAU_IMP_FK
  Deletion of IMPORTERS prevented if CSTMS_CLNTS records exist
  Foreign key(s): CSTMS_CLNT_IMP_FK
  Deletion of IMPORTERS prevented if DPLMTC_APLCTNS records exist
  Foreign key(s): DAP_IMP_FK
  Deletion of IMPORTERS prevented if LFT_SALES records exist
  Foreign key(s): LS_IMP_FK
  Deletion of IMPORTERS prevented if IMPR_UPDTS records exist
  Foreign key(s): IU_IMP_FK
  Deletion of IMPORTERS prevented if EXMTN_DECREES records exist
  Foreign key(s): XD_IMP_FK
  Deletion of IMPORTERS prevented if BRKR_MSTR records exist
  Foreign key(s): BKM_IMP_FK
  Deletion of IMPORTERS prevented if BA_OWNERSHIPS records exist
  Foreign key(s): BOW_IMP_FK
  Deletion of IMPORTERS prevented if BRKR_UPDTS records exist
  Foreign key(s): BU_IMP_FK
  Deletion of IMPORTERS prevented if IMPR_KNWNS records exist
  Foreign key(s): IK_IMP_FK
  Deletion of IMPORTERS prevented if SEA_DLVY_ORDERS records exist
  Foreign key(s): SDO_IMP_FK
  Deletion of IMPORTERS prevented if REV_SECTIONS_CASH_DTLS records exist
  Foreign key(s): RCDS_IMP_FK
  Deletion of IMPORTERS prevented if BL_OWNER_HIST records exist
  Foreign key(s): BLOH_IMP_FK
  Deletion of IMPORTERS prevented if IMPR_SUSPNS records exist
  Foreign key(s): IS_1_IMP_FK
  Deletion of IMPORTERS prevented if DELAY_AIR_DLVY_ORDERS records exist
  Foreign key(s): DA_IMP_FK
  Deletion of IMPORTERS prevented if PASSENGER_TRIPS records exist
  Foreign key(s): PT_IMP_FK
  Deletion of IMPORTERS prevented if AGNTS records exist
  Foreign key(s): AG_IMP_FK
  Deletion of IMPORTERS prevented if AGNTS records exist
  Foreign key(s): AG_IMP_AGENT_ID_FK

WARNINGS - 19/08/26  11:30
  01280: display length = 26, item length = 2;
  01280: display length = 11, item length = 2;
  01196: Column Usage IMPORTERS.BUS_ID_EXPRD_DT has display length
         12 but format of length 10
  01001: No PL/SQL block text for button item  IMPORTERS.BUTT;
         Button has no functionality.
  01280: display length = 30, item length = 20;
  01196: Column Usage IMPORTERS.BUS_ID_ISSUE_DT has display length
         12 but format of length 10
  01001: No PL/SQL block text for button item
         IMPORTERS.IMPR_NBR_PARENT2; Button has no functionality.
  01001: No PL/SQL block text for button item  IMPORTERS.CITY_CODE2;
          Button has no functionality.
  01280: display length = 30, item length = 20;
  01316: Foreign key constraint IMP_MB_FK in IMPORTERS has no
         enterable items or lookups
  01316: Foreign key constraint IMP_HI_FK in IMPORTERS has no
         enterable items or lookups

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
| IMPORTERS | IMPORTERS | same as query source (default) | base-table | default/OLB | 4 | WHERE   ( IMPORTERS.PORT_CD    = :PARAMETER.P_CURR_PORT_CD ) | ORDER BY IMPR_NBR DESC | default/OLB | default/OLB | default/OLB | default/OLB | CG$PAGE_1 | cic_olb.olb:CGSO$BLOCK |

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
  BASE   IMPORTERS                     SEL INS UPD DEL
  ...    PORT_CD                       SEL INS
  ...    HQ_IMPR_NBR                   SEL         NUL
  ...    IMPR_NBR                      SEL INS     NUL
  ...    BUS_ID_STATUS                 SEL INS UPD NUL
  ...    IMPR_TYPE_CD                  SEL INS
  ...    BUS_ID_EXPRD_DT               SEL INS UPD NUL
  ...    BUS_ID_TYPE_CD                SEL INS
  ...    COMM_RGSTRTN_TYPE             SEL INS UPD NUL
  ...    CTRY_CD                       SEL INS
  ...    CITY_CODE_OF_ID               SEL INS     NUL
  ...    IMPR_EXPR_TYPE                SEL INS UPD
  ...    NATIONAL_NBR                  SEL INS UPD
  ...    BUS_ID                        SEL INS
  ...    BUS_ID_BRNCH                  SEL INS     NUL
  ...    ARBC_IMPR_NAME                SEL INS UPD
  ...    IMPR_NAME_STD                 SEL INS UPD
  ...    LST_TRAN_DT                   SEL INS UPD NUL
  ...    IMPD_STMT_NBR                 SEL INS UPD NUL
  ...    IMPR_DATA_SRCE                SEL INS UPD NUL
  ...    ENG_IMPR_NAME                 SEL INS UPD NUL
  ...    IMPR_CNTCT_NAME               SEL INS UPD NUL
  ...    IMPR_ADDRESS                  SEL INS UPD NUL
  ...    BUS_ID_ISSUE_DT               SEL INS UPD NUL
  ...    IMPR_NBR_PARENT               SEL INS UPD NUL
  ...    ADD_CTRY_CD                   SEL INS UPD
  ...    CITY_CODE                     SEL INS UPD NUL
  ...    IMPR_POB_NBR                  SEL INS UPD NUL
  ...    IMPR_ZIP_CD                   SEL INS UPD NUL
  ...    IMPR_TEL_NBR                  SEL INS UPD NUL
  ...    IMPR_FAX_NBR                  SEL INS UPD NUL
  ...    IMPR_TELEX_NBR                SEL INS UPD NUL
  ...    EMAIL                         SEL INS UPD NUL
  ...    MOBILE_NO                         INS UPD NUL
  ...    CAR_AGENT_FLAG                SEL INS UPD
  ...    EXPRESS_POST                  SEL INS UPD NUL
  ...    CTRY_CD_OF_ID                 SEL INS UPD NUL
  ...    ID_NBR                        SEL INS UPD NUL
  ...    CUSTOMS_ENTERED                   INS UPD NUL
  ...    EXPD_STMT_NBR                 SEL INS UPD NUL
  ...    WVR_ENTRY_NBR                 SEL INS UPD NUL
  ...    ACTIVITY                      SEL INS UPD NUL
  ...    BANK_IBAN                     SEL INS UPD NUL
  ...    CREATION_FLAG                     INS UPD NUL
  ...    BIRTH_DT                      SEL INS UPD NUL

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

### 4.5 Block `IMPORTERS` (70 items)

| # | Item | Item type | Subclass (OLB) | Data type | Max len | Column name | DB item | Required | LOV | Default value | Format mask | Canvas / tab page | Visible | Insert / Update / Query allowed | Prompt / label | Copy-value-from / calc | List values / hint |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | L_CT_CITY_STATUS2 | – | CGSO$NUMBER_MD | – | 2 | – | false | false | – | – | – | – | false | false/false/false | Cty Status | – | – |
| 2 | L_CT_CITY_STATUS | – | CGSO$NUMBER_MD | – | 2 | – | false | false | – | – | – | – | false | false/false/false | – | – | – |
| 3 | PORT_CD | – | CGSO$CHAR_ARB | Number | 4 | PORT_CD | – | true | CGFK$IMPORTERS_PORT_CD | – | – | CG$PAGE_1 | – | ·/false/· | رمز الجمــــــــــــــرك | – | رمز الجمــــــــــــرك للمستورد - list of values available |
| 4 | PORT_CD2 | – | CGSO$LOV_BUT | – | – | – | – | – | – | – | – | CG$PAGE_1 | – | – | – | – | – |
| 5 | PORT_NAME | – | CGSO$CHAR_ARB_DO | – | 40 | – | false | false | – | – | – | CG$PAGE_1 | – | ·/·/true | – | – | اسم الميناء العربي |
| 6 | HQ_IMPR_NBR | – | CGSO$CHAR_ARB_DO | Number | 11 | HQ_IMPR_NBR | – | – | CGFK$IMPORTERS_HQ_IMPR_NBR | – | – | CG$PAGE_1 | – | ·/·/true | الرقم الموحد بالمصلحة | – | Enter value for الرقم الموحد بالمصلحة - list of values available |
| 7 | IMPR_NBR | – | CGSO$CHAR_ARB | Number | 11 | IMPR_NBR | – | – | – | – | – | CG$PAGE_1 | – | ·/false/· | الرقــــــم الجمركــــى | – | للإستعلام أدخل مسلسل المستورد بالحاسب الآلي - لإضافة مستورد جديد أترك الخانة بدون بيانات |
| 8 | SUSPN_STATUS | – | CGSO$CHAR_ARB_DO | – | – | – | false | – | – | – | – | CG$PAGE_1 | – | – | حالة المستورد بالمصلحة | – | Enter value for حالة المستورد بالمصلحة |
| 9 | STATUS_DESC | – | CGSO$CHAR_ARB_DO | – | – | – | false | false | – | – | – | CG$PAGE_1 | – | – | حالة المستورد بالوزارة | – | Enter value for حالة المستورد بالوزارة |
| 10 | BUS_ID_STATUS | – | CGSO$COMBO_DO | – | 2 | BUS_ID_STATUS | – | – | – | – | – | – | false | ·/·/false | حالة المستورد بالوزارة | – | حالة السجل التجاري بوزارة التجارة |
| 11 | IMPR_TYPE_CD | – | CGSO$CHAR_ARB | Number | 4 | IMPR_TYPE_CD | – | true | CGFK$IMPORTERS_IMPR_TYPE_CD | – | – | CG$PAGE_1 | – | ·/false/· | رمز النشاط التجارى | – | رمز النشاط التجارى - list of values available |
| 12 | IMPR_TYPE_CD2 | – | CGSO$LOV_BUT | – | – | – | – | – | – | – | – | CG$PAGE_1 | – | – | – | – | – |
| 13 | IMPR_TYPE_NAME | – | CGSO$CHAR_ARB_DO | – | 40 | – | false | false | – | – | – | CG$PAGE_1 | – | ·/·/true | – | – | مسمي نوع المستورد |
| 14 | BUS_ID_EXPRD_DT | – | CGSO$HDATE_ARB | – | – | BUS_ID_EXPRD_DT | – | – | – | – | – | CG$PAGE_1 | – | – | إنتهاء النشاط | – | تاريخ انتهاء سجل المستورد |
| 15 | BUS_ID_TYPE_CD | – | CGSO$CHAR_ARB_DO | Number | 4 | BUS_ID_TYPE_CD | – | true | – | – | – | CG$PAGE_1 | – | true/·/true | نوع الرقم الإستدلالي | – | رمز نوع الرقم  الاستدلالى |
| 16 | BUTT | – | CGSO$LOV_BUT | – | 2 | – | false | true | – | – | – | CG$PAGE_1 | – | – | – | – | – |
| 17 | BUS_ID_TYPE_NAME | – | CGSO$CHAR_ARB_DO | – | 40 | – | false | false | – | – | – | CG$PAGE_1 | – | – | – | – | مسمى  نوع الرقم الاستدلالى |
| 18 | COMM_RGSTRTN_TYPE | List Item | CGSO$CHAR_ARB | Number | 2 | COMM_RGSTRTN_TYPE | – | – | – | – | – | CG$PAGE_1 | – | – | نوع السجل التجاري | – | 1=رئيسي; 0=فرعي; 2=فرعي |
| 19 | CTRY_CD | – | CGSO$CHAR_ARB | Number | 4 | CTRY_CD | – | true | CGFK$IMPORTERS_CTRY_CD | – | – | CG$PAGE_1 | – | ·/false/· | دولة الرقم الإستدلالي | – | رمز الدولة - list of values available |
| 20 | CTRY_CD2 | – | CGSO$LOV_BUT | – | – | – | – | – | – | – | – | CG$PAGE_1 | – | – | – | – | – |
| 21 | CRTY_ARBC_NAME | – | CGSO$CHAR_ARB_DO | – | 50 | – | false | false | – | – | – | CG$PAGE_1 | – | – | – | – | اسم الدولة عربي |
| 22 | CITY_CODE_OF_ID | – | CGSO$CHAR_ARB | Number | 4 | CITY_CODE_OF_ID | – | – | CGFK$IMPORTERS_CITY_CODE_OF_ID | – | – | CG$PAGE_1 | – | ·/false/· | مصدررقم الإستدلالي | – | رمز المدينة السعودية - list of values available |
| 23 | CITY_CODE_OF_ID2 | – | CGSO$LOV_BUT | – | – | – | – | – | – | – | – | CG$PAGE_1 | – | – | – | – | – |
| 24 | ID_CITY_NAME | – | CGSO$CHAR_ARB_DO | – | 20 | – | false | false | – | – | – | CG$PAGE_1 | – | – | – | – | مسمى الدولة العربي |
| 25 | IMPR_EXPR_TYPE | – | CGSO$POP_MD | Number | 2 | IMPR_EXPR_TYPE | – | – | – | 0 | – | CG$PAGE_1 | – | – | النشاط الجمركي | – | 0=تصدير; 1=إستيراد; 2=إستيراد-تصدير |
| 26 | NATIONAL_NBR | – | CGSO$CHAR_ARB | – | 15 | NATIONAL_NBR | – | true | – | – | – | CG$PAGE_1 | – | – | رقم المنشأة | – | الرقم الوطنى للمنشأة 7 |
| 27 | BUS_ID | – | CGSO$CHAR_ARB_DO | – | 15 | BUS_ID | – | true | – | – | – | CG$PAGE_1 | – | true/·/true | الرقم الاستدلالـــــــى | – | الرقم الاستدلالى للمستورد الرئيسى |
| 28 | BUS_ID_BRNCH | – | CGSO$CHAR_ARB_DO | – | 10 | BUS_ID_BRNCH | – | – | – | – | – | CG$PAGE_1 | – | true/·/true | الفرع | – | رقم الفرع التابع للمستورد الرئيسى |
| 29 | CTRY_CTRY_STATUS | – | CGSO$NUMBER_MD | – | 2 | – | false | false | – | 1 | – | – | false | false/false/false | Ctry Status | – | – |
| 30 | ID_MINS_COMM_CD | – | CGSO$NUMBER_MD | – | 5 | – | false | false | – | – | – | – | false | false/false/false | Mins Comm Cd | – | – |
| 31 | ITIDT_NOTE | – | CGSO$CHAR_MD | – | 200 | – | false | false | – | – | – | – | false | false/false/false | ملاحظات | – | – |
| 32 | ARBC_IMPR_NAME | – | CGSO$CHAR_ARB | – | – | ARBC_IMPR_NAME | – | true | – | – | – | CG$PAGE_1 | – | – | الاســــم العربــــــــى | – | اسم المستورد |
| 33 | IMPR_NAME_STD | – | CGSO$CHAR_MD | – | 200 | IMPR_NAME_STD | – | false | – | – | – | – | false | false/false/false | Impr Name Std | – | اسم المستورد القياسى-للبحث |
| 34 | LST_TRAN_DT | – | CGSO$DATE | – | – | LST_TRAN_DT | – | – | – | – | – | – | false | false/false/false | Lst Tran Dt | – | – |
| 35 | IMPD_STMT_NBR | – | CGSO$NUMBER | – | 10 | IMPD_STMT_NBR | – | – | – | – | – | – | false | false/false/false | Impd Stmt Nbr | – | عدد بيانات الاستيراد الخاصه بالمستورد |
| 36 | IMPR_DATA_SRCE | – | CGSO$NUMBER | – | 7 | IMPR_DATA_SRCE | – | – | – | – | – | – | false | false/false/false | Impr Data Srce | – | – |
| 37 | STATUS | – | CGSO$CHECK_BOX_MD | Number | 2 | – | false | false | – | 1 | – | – | false | false/false/false | حالة سجل - نشط أو غير نشط | – | checked=1 unchecked=0 |
| 38 | ENG_IMPR_NAME | – | CGSO$CHAR_EN | – | – | ENG_IMPR_NAME | – | – | – | – | – | CG$PAGE_1 | – | – | الاســــم الأجنبـــــــي | – | الاسم الأجنبى للمستورد |
| 39 | IMPR_CNTCT_NAME | – | CGSO$CHAR_ARB | – | – | IMPR_CNTCT_NAME | – | – | – | – | – | CG$PAGE_1 | – | – | الوكيل المفوض | – | اسم الوكيل المفوض |
| 40 | IMPR_ADDRESS | – | CGSO$CHAR_ARB | – | 2000 | IMPR_ADDRESS | – | – | – | – | – | CG$PAGE_1 | – | – | الــعـــــــنـــــــوان | – | Enter value for الــعـــــــنـــــــوان |
| 41 | BUS_ID_ISSUE_DT | – | CGSO$HDATE_ARB | – | – | BUS_ID_ISSUE_DT | – | – | – | – | MI-MM-YYYY | CG$PAGE_1 | – | – | تاريخ انشاء النشاط | – | Enter value for تاريخ انشاء النشاط |
| 42 | IMPR_NBR_PARENT | – | CGSO$CHAR_ARB | Number | 11 | IMPR_NBR_PARENT | – | – | – | – | – | CG$PAGE_1 | – | – | تابــع الـــــــــــــــــى | – | مسلسل المستورد الأب |
| 43 | IMPR_NBR_PARENT2 | – | CGSO$LOV_BUT | – | 2 | – | false | true | – | – | – | CG$PAGE_1 | – | – | – | – | – |
| 44 | IMPR_NAME_PARENT | – | CGSO$CHAR_ARB_DO | – | – | – | false | – | – | – | – | CG$PAGE_1 | – | – | – | – | اسم المستورد الأب |
| 45 | ADD_CTRY_CD | – | CGSO$CHAR_ARB | Number | 4 | ADD_CTRY_CD | – | true | CGFK$IMPORTERS_ADD_CTRY_CD | – | – | CG$PAGE_1 | – | – | دولــــــــة الإقامـــــة | – | Enter value for دولــــــــة الإقامـــــة - list of values available |
| 46 | ADD_CTRY_CD2 | – | CGSO$LOV_BUT | – | – | – | – | – | – | – | – | CG$PAGE_1 | – | – | – | – | – |
| 47 | ADD_CRTY_ARBC_NAME | – | CGSO$CHAR_ARB_DO | – | 50 | – | false | false | – | – | – | CG$PAGE_1 | – | – | – | – | اسم الدولة عربي |
| 48 | CITY_CODE | – | CGSO$CHAR_ARB | Number | 4 | CITY_CODE | – | – | – | – | – | CG$PAGE_1 | – | – | المدينـــــــــــــــــــــة | – | رمز المدينة السعودية |
| 49 | CITY_CODE2 | – | CGSO$LOV_BUT | – | 2 | – | false | true | – | – | – | CG$PAGE_1 | – | – | – | – | – |
| 50 | CITY_NAME | – | CGSO$CHAR_ARB_DO | – | 20 | – | false | false | – | – | – | CG$PAGE_1 | – | – | – | – | مسمى الدولة العربي |
| 51 | IMPR_POB_NBR | – | CGSO$CHAR_ARB | Number | 9 | IMPR_POB_NBR | – | – | – | – | – | CG$PAGE_1 | – | – | صنــــدوق بريــــــــد | – | صندوق البريد |
| 52 | IMPR_ZIP_CD | – | CGSO$CHAR_ARB | Number | 11 | IMPR_ZIP_CD | – | – | – | – | – | CG$PAGE_1 | – | – | رمز بريدي | – | الرمز البريدى |
| 53 | IMPR_TEL_NBR | – | CGSO$CHAR_ARB | – | 15 | IMPR_TEL_NBR | – | – | – | – | – | CG$PAGE_1 | – | – | تليفـون | – | رقم تليفون المستورد |
| 54 | IMPR_FAX_NBR | – | CGSO$CHAR_ARB | – | 15 | IMPR_FAX_NBR | – | – | – | – | – | CG$PAGE_1 | – | – | فاكــس | – | رقم الفاكس |
| 55 | IMPR_TELEX_NBR | – | CGSO$CHAR_ARB | – | 16 | IMPR_TELEX_NBR | – | – | – | – | – | CG$PAGE_1 | – | – | تلكـــــــــــــــــــــــس | – | تلكس |
| 56 | EMAIL | – | CGSO$EMAIL | – | – | EMAIL | – | – | – | – | – | CG$PAGE_1 | – | – | بريــد إلكترونى | – | البريد الإلكتروني للمستورد |
| 57 | MOBILE_NO | – | CGSO$CHAR_EN | – | 30 | MOBILE_NO | – | – | – | – | – | CG$PAGE_1 | – | ·/·/false | رقم الجوال | – | Enter value for رقم الجوال |
| 58 | CAR_AGENT_FLAG | – | CGSO$POP_DO | Number | 2 | CAR_AGENT_FLAG | – | true | – | 0 | – | CG$PAGE_1 | – | true/true/· | وكيـــل سيـــارات؟ | – | 0=ليس وكيل سيارات; 1=وكيل سيارات |
| 59 | EXPRESS_POST | List Item | CGSO$CHAR_ARB | – | 1 | EXPRESS_POST | – | – | – | 0 | – | CG$PAGE_1 | – | – | بريد سريع | – | 0=لا; 1=نعم; 2=تم انشاءه بواسطة البريد السريع |
| 60 | CTRY_CD_OF_ID | – | CGSO$NUMBER | – | 4 | CTRY_CD_OF_ID | – | – | – | 100 | – | – | false | false/false/false | Ct Ctry Cd2 | – | – |
| 61 | ID_NBR | – | CGSO$CHAR | – | 15 | ID_NBR | – | – | – | – | – | – | false | false/false/false | رقم الهويه للمستورد | – | – |
| 62 | CUSTOMS_ENTERED | – | CGSO$NUMBER | – | 2 | CUSTOMS_ENTERED | – | – | CGDV$IMPORTERS_CUSTOMS_ENTERED | – | – | – | false | false/false/false | موجود أو غير موجود بملف وزارة التجارة | – | موجود أو غير موجود بملف وزارة التجارة - list of values available |
| 63 | CUSTOMS_ENTERED2 | – | CGSO$LOV_BUT | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| 64 | EXPD_STMT_NBR | – | CGSO$NUMBER | – | 11 | EXPD_STMT_NBR | – | – | – | – | – | – | false | false/false/false | عدد البيانات الجمركية لكل مستورد وتجمع من نظام البيان الجمركي | – | عدد البيانات الجمركية لكل مستورد وتجمع من نظام البيان الجمركي |
| 65 | WVR_ENTRY_NBR | – | CGSO$NUMBER | – | 8 | WVR_ENTRY_NBR | – | – | – | – | – | – | false | false/false/false | عدد بيانات التعهدات | – | عدد بيانات التعهدات |
| 66 | ACTIVITY | – | CGSO$CHAR | – | 1000 | ACTIVITY | – | – | – | – | – | – | false | false/false/false | نشاط المستورد | – | نشاط المستورد |
| 67 | BANK_IBAN | – | CGSO$CHAR | – | 60 | BANK_IBAN | – | – | – | – | – | – | false | false/false/false | Bank Iban | – | – |
| 68 | CREATION_FLAG | – | CGSO$NUMBER | – | 4 | CREATION_FLAG | – | – | CGDV$IMPORTERS_CREATION_FLAG | 1 | – | – | false | false/false/false | نوع تكوين السجل التجاري | – | نوع تكوين السجل التجاري - list of values available |
| 69 | CREATION_FLAG2 | – | CGSO$LOV_BUT | – | – | – | – | – | – | – | – | – | – | – | – | – | – |
| 70 | BIRTH_DT | – | CGSO$DATE | – | – | BIRTH_DT | – | – | – | – | – | – | false | false/false/false | تاريخ الميلاد | – | تاريخ الميلاد |


## 5. Relations (master–detail)

**None.** The XML contains 0 `<Relation>` elements. Base-table blocks: `IMPORTERS`; the other 4 are control blocks.

## 6. Triggers


### 6.0 Trigger index

| # | Level | Owner | Trigger | Lines (total / active) | Exec. hierarchy | Source | Program units called |
|---|---|---|---|---|---|---|---|
| 1 | Form | FORM | KEY-EDIT | 21 / 1 | default (Override) | XML | – |
| 2 | Form | FORM | KEY-DUPREC | 10 / 1 | default (Override) | XML | – |
| 3 | Form | FORM | PRE-FORM | 36 / 10 | default (Override) | XML | – |
| 4 | Form | FORM | WHEN-NEW-FORM-INSTANCE | 254 / 90 | default (Override) | XML | CG$WHEN_NEW_FORM_INSTANCE |
| 5 | Form | FORM | WHEN-WINDOW-ACTIVATED | 29 / 1 | default (Override) | XML | – |
| 6 | Form | FORM | KEY-ENTQRY | 44 / 1 | default (Override) | XML | – |
| 7 | Form | FORM | ON-ERROR | 39 / 1 | default (Override) | XML | – |
| 8 | Form | FORM | ON-MESSAGE | 34 / 1 | default (Override) | XML | – |
| 9 | Form | FORM | KEY-CLRBLK | 17 / 1 | default (Override) | XML | – |
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
| 22 | Form | FORM | KEY-EXEQRY | 12 / 1 | default (Override) | XML | – |
| 23 | Form | FORM | KEY-F9 | 26 / 23 | default (Override) | XML | ADJ_FUNS |
| 24 | Form | FORM | WHEN-TIMER-EXPIRED | 48 / 1 | default (Override) | XML | – |
| 25 | Form | FORM | KEY-HELP | 18 / 16 | default (Override) | XML | – |
| 26 | Form | FORM | KEY-CLRFRM | 19 / 14 | default (Override) | XML | CG$WHEN_NEW_FORM_INSTANCE |
| 27 | Item | TITLE.CGSO$CHAR_ARB_ED | KEY-LISTVAL | 0 / 0 | default (Override) | OLB code (1 lines): `NULL;` | – |
| 28 | Item | TITLE.CGSO$CHAR_ARB_DO_ENB_Y | KEY-LISTVAL | 0 / 0 | default (Override) | OLB code (1 lines): `NULL;` | – |
| 29 | Item | TITLE.CGSO$CHAR_ARB_MLINE | KEY-LISTVAL | 0 / 0 | default (Override) | OLB code (1 lines): `NULL;` | – |
| 30 | Item | TITLE.CGSO$CHAR_ARB | KEY-LISTVAL | 0 / 0 | default (Override) | OLB code (1 lines): `NULL;` | – |
| 31 | Item | TITLE.CGSO$CHAR_ARB_DO | KEY-LISTVAL | 0 / 0 | default (Override) | OLB code (1 lines): `NULL;` | – |
| 32 | Item | TITLE.SYSTEM_DATE | WHEN-VALIDATE-ITEM | 13 / 12 | default (Override) | XML | – |
| 33 | Item | EDI_MSG.EDI_MSG_LOVE_BUT | WHEN-BUTTON-PRESSED | 0 / 0 | default (Override) | OLB code (1 lines): `EDI_MSG_LOV;` | – |
| 34 | Item | LSIDE.FN1 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 35 | Item | LSIDE.FN1 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 36 | Item | LSIDE.FN1 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 37 | Item | LSIDE.FN50 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 38 | Item | LSIDE.FN50 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 39 | Item | LSIDE.FN50 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 40 | Item | LSIDE.FN2 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 41 | Item | LSIDE.FN2 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 42 | Item | LSIDE.FN2 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 43 | Item | LSIDE.FN49 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 44 | Item | LSIDE.FN49 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 45 | Item | LSIDE.FN49 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 46 | Item | LSIDE.FN3 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 47 | Item | LSIDE.FN3 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 48 | Item | LSIDE.FN3 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 49 | Item | LSIDE.FN48 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 50 | Item | LSIDE.FN48 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 51 | Item | LSIDE.FN48 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 52 | Item | LSIDE.FN4 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 53 | Item | LSIDE.FN4 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 54 | Item | LSIDE.FN4 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 55 | Item | LSIDE.FN47 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 56 | Item | LSIDE.FN47 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 57 | Item | LSIDE.FN47 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 58 | Item | LSIDE.FN5 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 59 | Item | LSIDE.FN5 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 60 | Item | LSIDE.FN5 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 61 | Item | LSIDE.FN46 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 62 | Item | LSIDE.FN46 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 63 | Item | LSIDE.FN46 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 64 | Item | LSIDE.FN6 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 65 | Item | LSIDE.FN6 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 66 | Item | LSIDE.FN6 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 67 | Item | LSIDE.FN45 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 68 | Item | LSIDE.FN45 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 69 | Item | LSIDE.FN45 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 70 | Item | LSIDE.FN7 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 71 | Item | LSIDE.FN7 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 72 | Item | LSIDE.FN7 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 73 | Item | LSIDE.FN44 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 74 | Item | LSIDE.FN44 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 75 | Item | LSIDE.FN44 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 76 | Item | LSIDE.FN8 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 77 | Item | LSIDE.FN8 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 78 | Item | LSIDE.FN8 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 79 | Item | LSIDE.FN43 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 80 | Item | LSIDE.FN43 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 81 | Item | LSIDE.FN43 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 82 | Item | LSIDE.FN9 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 83 | Item | LSIDE.FN9 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 84 | Item | LSIDE.FN9 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 85 | Item | LSIDE.FN42 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 86 | Item | LSIDE.FN42 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 87 | Item | LSIDE.FN42 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 88 | Item | LSIDE.FN10 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 89 | Item | LSIDE.FN10 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 90 | Item | LSIDE.FN10 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 91 | Item | LSIDE.FN41 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 92 | Item | LSIDE.FN41 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 93 | Item | LSIDE.FN41 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 94 | Item | LSIDE.FN11 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 95 | Item | LSIDE.FN11 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 96 | Item | LSIDE.FN11 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 97 | Item | LSIDE.FN40 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 98 | Item | LSIDE.FN40 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 99 | Item | LSIDE.FN40 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 100 | Item | LSIDE.FN12 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 101 | Item | LSIDE.FN12 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 102 | Item | LSIDE.FN12 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 103 | Item | LSIDE.FN39 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 104 | Item | LSIDE.FN39 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 105 | Item | LSIDE.FN39 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 106 | Item | LSIDE.FN13 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 107 | Item | LSIDE.FN13 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 108 | Item | LSIDE.FN13 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 109 | Item | LSIDE.FN38 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 110 | Item | LSIDE.FN38 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 111 | Item | LSIDE.FN38 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 112 | Item | LSIDE.FN14 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 113 | Item | LSIDE.FN14 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 114 | Item | LSIDE.FN14 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 115 | Item | LSIDE.FN37 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 116 | Item | LSIDE.FN37 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 117 | Item | LSIDE.FN37 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 118 | Item | LSIDE.FN15 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 119 | Item | LSIDE.FN15 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 120 | Item | LSIDE.FN15 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 121 | Item | LSIDE.FN36 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 122 | Item | LSIDE.FN36 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 123 | Item | LSIDE.FN36 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 124 | Item | LSIDE.FN16 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 125 | Item | LSIDE.FN16 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 126 | Item | LSIDE.FN16 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 127 | Item | LSIDE.FN17 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 128 | Item | LSIDE.FN17 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 129 | Item | LSIDE.FN17 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 130 | Item | LSIDE.FN34 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 131 | Item | LSIDE.FN34 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 132 | Item | LSIDE.FN34 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 133 | Item | LSIDE.FN35 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 134 | Item | LSIDE.FN35 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 135 | Item | LSIDE.FN35 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 136 | Item | LSIDE.FN18 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 137 | Item | LSIDE.FN18 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 138 | Item | LSIDE.FN18 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 139 | Item | LSIDE.FN33 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 140 | Item | LSIDE.FN33 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 141 | Item | LSIDE.FN33 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 142 | Item | LSIDE.FN19 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 143 | Item | LSIDE.FN19 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 144 | Item | LSIDE.FN19 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 145 | Item | LSIDE.FN32 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 146 | Item | LSIDE.FN32 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 147 | Item | LSIDE.FN32 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 148 | Item | LSIDE.FN20 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 149 | Item | LSIDE.FN20 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 150 | Item | LSIDE.FN20 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 151 | Item | LSIDE.FN31 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 152 | Item | LSIDE.FN31 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 153 | Item | LSIDE.FN31 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 154 | Item | LSIDE.FN21 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 155 | Item | LSIDE.FN21 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 156 | Item | LSIDE.FN21 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 157 | Item | LSIDE.FN30 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 158 | Item | LSIDE.FN30 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 159 | Item | LSIDE.FN30 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 160 | Item | LSIDE.FN22 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 161 | Item | LSIDE.FN22 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 162 | Item | LSIDE.FN22 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 163 | Item | LSIDE.FN29 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 164 | Item | LSIDE.FN29 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 165 | Item | LSIDE.FN29 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 166 | Item | LSIDE.FN23 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 167 | Item | LSIDE.FN23 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 168 | Item | LSIDE.FN23 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 169 | Item | LSIDE.FN28 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 170 | Item | LSIDE.FN28 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 171 | Item | LSIDE.FN28 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 172 | Item | LSIDE.FN24 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 173 | Item | LSIDE.FN24 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 174 | Item | LSIDE.FN24 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 175 | Item | LSIDE.FN27 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 176 | Item | LSIDE.FN27 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 177 | Item | LSIDE.FN27 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 178 | Item | LSIDE.FN25 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 179 | Item | LSIDE.FN25 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 180 | Item | LSIDE.FN25 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 181 | Item | LSIDE.FN26 | WHEN-MOUSE-ENTER | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_ENTER;` | – |
| 182 | Item | LSIDE.FN26 | WHEN-MOUSE-LEAVE | 0 / 0 | default (Override) | OLB code (1 lines): `TMPLT.MOUSE_LEAVE;` | – |
| 183 | Item | LSIDE.FN26 | WHEN-MOUSE-CLICK | 0 / 0 | default (Override) | OLB code (1 lines): `MOUSE_CLICK;` | – |
| 184 | Block | TOOLBAR | KEY-DOWN | 3 / 3 | default (Override) | XML | – |
| 185 | Block | TOOLBAR | KEY-UP | 3 / 3 | default (Override) | XML | – |
| 186 | Block | TOOLBAR | KEY-NEXT-ITEM | 10 / 10 | default (Override) | XML | EXECUTE_FUNCTION |
| 187 | Item | TOOLBAR.SAVE | WHEN-BUTTON-PRESSED | 15 / 12 | default (Override) | XML | – |
| 188 | Item | TOOLBAR.CLEAR_ALL | WHEN-BUTTON-PRESSED | 0 / 0 | default (Override) | OLB code (4 lines): `do_key('clear_BLOCK');` | – |
| 189 | Item | TOOLBAR.EXIT | WHEN-BUTTON-PRESSED | 19 / 15 | default (Override) | XML | – |
| 190 | Item | TOOLBAR.EXIT1 | WHEN-BUTTON-PRESSED | 42 / 38 | default (Override) | XML | – |
| 191 | Item | TOOLBAR.ENTER | WHEN-BUTTON-PRESSED | 0 / 0 | default (Override) | OLB code (26 lines): `SET_ITEM_PROPERTY('SAVE',VISIBLE,PROPERTY_FALSE);` | – |
| 192 | Item | TOOLBAR.EXECUTE | WHEN-BUTTON-PRESSED | 0 / 0 | default (Override) | OLB code (1 lines): `do_key('Execute_query');` | – |
| 193 | Item | TOOLBAR.REMOVE | WHEN-BUTTON-PRESSED | 0 / 0 | default (Override) | OLB code (1 lines): `do_key('Delete_record');` | – |
| 194 | Item | TOOLBAR.LIST_VALUE | WHEN-BUTTON-PRESSED | 0 / 0 | default (Override) | OLB code (1 lines): `do_key('LIST_VALUES');` | – |
| 195 | Item | TOOLBAR.HELP | WHEN-BUTTON-PRESSED | 0 / 0 | default (Override) | OLB code (10 lines): `DECLARE` | – |
| 196 | Item | TOOLBAR.LAST_REC | WHEN-BUTTON-PRESSED | 1 / 1 | default (Override) | XML | – |
| 197 | Item | TOOLBAR.RE_ENTER_QUERY | WHEN-BUTTON-PRESSED | 6 / 6 | default (Override) | XML | – |
| 198 | Item | TOOLBAR.FIRST_REC | WHEN-BUTTON-PRESSED | 0 / 0 | default (Override) | OLB code (1 lines): `do_key('Previous_Record');` | – |
| 199 | Item | TOOLBAR.PAGE_UP | WHEN-BUTTON-PRESSED | 0 / 0 | default (Override) | OLB code (1 lines): `do_key('Scroll_Up');` | – |
| 200 | Item | TOOLBAR.PAGE_DOWN | WHEN-BUTTON-PRESSED | 1 / 1 | default (Override) | XML | – |
| 201 | Item | TOOLBAR.FUN_BUT | WHEN-MOUSE-UP | 15 / 12 | default (Override) | XML | – |
| 202 | Item | TOOLBAR.FUN_BUT | WHEN-MOUSE-DOWN | 13 / 10 | default (Override) | XML | ADJ_FUNS |
| 203 | Block | IMPORTERS | ON-ERROR | 170 / 148 | default (Override) | XML | CGTE$CHECK_CONSTRAINT_VIO |
| 204 | Block | IMPORTERS | POST-QUERY | 177 / 162 | default (Override) | XML | CG$IMPR1130_PROD_CENTRL_GLOBAL, CGFK$QRY_IMPORTERS_IMP_ADD_CIT, CGFK$QRY_IMPORTERS_IMP_BUS_ID_, CGFK$QRY_IMPORTERS_IMP_CTRY_FK, CGFK$QRY_IMPORTERS_IMP_ITIDT_F, CGFK$QRY_IMPORTERS_IMP_SDP_FK |
| 205 | Block | IMPORTERS | PRE-QUERY | 77 / 63 | default (Override) | XML | CG$IMPR1130_PROD_CENTRL_GLOBAL |
| 206 | Block | IMPORTERS | PRE-INSERT | 171 / 115 | default (Override) | XML | CGSF$CLRLU_IMPORTERS_IMP_BUS_I, CHK_IMPR_DUPL |
| 207 | Block | IMPORTERS | PRE-DELETE | 20 / 16 | default (Override) | XML | CGRI$CHK_IMPORTERS |
| 208 | Block | IMPORTERS | KEY-DELREC | 65 / 52 | default (Override) | XML | CGRI$CHK_IMPORTERS |
| 209 | Block | IMPORTERS | KEY-HELP | 130 / 128 | default (Override) | XML | – |
| 210 | Block | IMPORTERS | POST-INSERT | 8 / 6 | default (Override) | XML | INSERT_AUDIT_RECORD |
| 211 | Block | IMPORTERS | PRE-RECORD | 19 / 17 | default (Override) | XML | – |
| 212 | Block | IMPORTERS | PRE-UPDATE | 51 / 44 | default (Override) | XML | INSERT_AUDIT_RECORD |
| 213 | Block | IMPORTERS | WHEN-CREATE-RECORD | 59 / 35 | default (Override) | XML | – |
| 214 | Block | IMPORTERS | WHEN-NEW-ITEM-INSTANCE | 7 / 7 | default (Override) | XML | – |
| 215 | Block | IMPORTERS | WHEN-NEW-RECORD-INSTANCE | 37 / 32 | default (Override) | XML | – |
| 216 | Item | IMPORTERS.L_CT_CITY_STATUS2 | KEY-LISTVAL | 34 / 32 | default (Override) | XML | – |
| 217 | Item | IMPORTERS.L_CT_CITY_STATUS | KEY-LISTVAL | 34 / 32 | default (Override) | XML | – |
| 218 | Item | IMPORTERS.PORT_CD | KEY-LISTVAL | 75 / 65 | default (Override) | XML | – |
| 219 | Item | IMPORTERS.PORT_CD | WHEN-VALIDATE-ITEM | 31 / 18 | default (Override) | XML | CGFK$CHK_IMPORTERS_IMP_SDP_FK |
| 220 | Item | IMPORTERS.PORT_CD2 | WHEN-BUTTON-PRESSED | 6 / 4 | default (Override) | XML | – |
| 221 | Item | IMPORTERS.PORT_NAME | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 222 | Item | IMPORTERS.HQ_IMPR_NBR | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 223 | Item | IMPORTERS.IMPR_NBR | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 224 | Item | IMPORTERS.IMPR_NBR | WHEN-VALIDATE-ITEM | 22 / 18 | default (Override) | XML | – |
| 225 | Item | IMPORTERS.SUSPN_STATUS | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 226 | Item | IMPORTERS.STATUS_DESC | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 227 | Item | IMPORTERS.IMPR_TYPE_CD | KEY-LISTVAL | 96 / 73 | default (Override) | XML | – |
| 228 | Item | IMPORTERS.IMPR_TYPE_CD | WHEN-VALIDATE-ITEM | 298 / 233 | default (Override) | XML | CGFK$CHK_IMPORTERS_IMP_ITIDT_F |
| 229 | Item | IMPORTERS.IMPR_TYPE_CD | KEY-NEXT-ITEM | 7 / 7 | default (Override) | XML | – |
| 230 | Item | IMPORTERS.IMPR_TYPE_CD | WHEN-NEW-ITEM-INSTANCE | 6 / 6 | default (Override) | XML | – |
| 231 | Item | IMPORTERS.IMPR_TYPE_CD2 | WHEN-BUTTON-PRESSED | 6 / 4 | default (Override) | XML | – |
| 232 | Item | IMPORTERS.IMPR_TYPE_NAME | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 233 | Item | IMPORTERS.BUS_ID_EXPRD_DT | KEY-LISTVAL | 26 / 25 | default (Override) | XML | – |
| 234 | Item | IMPORTERS.BUS_ID_EXPRD_DT | KEY-F4 | 26 / 25 | default (Override) | XML | – |
| 235 | Item | IMPORTERS.BUS_ID_EXPRD_DT | WHEN-VALIDATE-ITEM | 14 / 12 | default (Override) | XML | – |
| 236 | Item | IMPORTERS.BUS_ID_EXPRD_DT | WHEN-NEW-ITEM-INSTANCE | 6 / 6 | default (Override) | XML | – |
| 237 | Item | IMPORTERS.BUS_ID_TYPE_CD | KEY-LISTVAL | 82 / 63 | default (Override) | XML | – |
| 238 | Item | IMPORTERS.BUS_ID_TYPE_CD | WHEN-VALIDATE-ITEM | 15 / 13 | default (Override) | XML | – |
| 239 | Item | IMPORTERS.BUTT | WHEN-BUTTON-PRESSED | 7 / 5 | default (Override) | XML | – |
| 240 | Item | IMPORTERS.BUS_ID_TYPE_NAME | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 241 | Item | IMPORTERS.COMM_RGSTRTN_TYPE | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 242 | Item | IMPORTERS.COMM_RGSTRTN_TYPE | WHEN-LIST-CHANGED | 12 / 8 | default (Override) | XML | – |
| 243 | Item | IMPORTERS.CTRY_CD | KEY-LISTVAL | 45 / 39 | default (Override) | XML | CALL_LOV_COUNTRIES, CALL_LOV_COUN_GULF |
| 244 | Item | IMPORTERS.CTRY_CD | WHEN-VALIDATE-ITEM | 37 / 33 | default (Override) | XML | CGFK$CHK_IMPORTERS_IMP_CTRY_FK |
| 245 | Item | IMPORTERS.CTRY_CD2 | WHEN-BUTTON-PRESSED | 6 / 4 | default (Override) | XML | – |
| 246 | Item | IMPORTERS.CRTY_ARBC_NAME | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 247 | Item | IMPORTERS.CITY_CODE_OF_ID | KEY-LISTVAL | 81 / 67 | default (Override) | XML | – |
| 248 | Item | IMPORTERS.CITY_CODE_OF_ID | WHEN-VALIDATE-ITEM | 113 / 91 | default (Override) | XML | CGFK$CHK_IMPORTERS_IMP_BUS_ID_, CGSF$CLRLU_IMPORTERS_IMP_BUS_I |
| 249 | Item | IMPORTERS.CITY_CODE_OF_ID | WHEN-NEW-ITEM-INSTANCE | 10 / 9 | default (Override) | XML | – |
| 250 | Item | IMPORTERS.CITY_CODE_OF_ID2 | WHEN-BUTTON-PRESSED | 6 / 4 | default (Override) | XML | – |
| 251 | Item | IMPORTERS.ID_CITY_NAME | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 252 | Item | IMPORTERS.NATIONAL_NBR | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 253 | Item | IMPORTERS.NATIONAL_NBR | WHEN-VALIDATE-ITEM | 35 / 29 | default (Override) | XML | GET_BRANCH_CR_DATA, GET_MAIN_CR_DATA |
| 254 | Item | IMPORTERS.BUS_ID | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 255 | Item | IMPORTERS.BUS_ID | WHEN-VALIDATE-ITEM | 228 / 165 | default (Override) | XML | – |
| 256 | Item | IMPORTERS.BUS_ID_BRNCH | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 257 | Item | IMPORTERS.BUS_ID_BRNCH | KEY-NEXT-ITEM | 7 / 6 | default (Override) | XML | CHK_IMPR_DUPL |
| 258 | Item | IMPORTERS.BUS_ID_BRNCH | WHEN-VALIDATE-ITEM | 86 / 55 | default (Override) | XML | CHK_IMPR_DUPL |
| 259 | Item | IMPORTERS.CTRY_CTRY_STATUS | KEY-LISTVAL | 34 / 32 | default (Override) | XML | – |
| 260 | Item | IMPORTERS.ID_MINS_COMM_CD | KEY-LISTVAL | 34 / 32 | default (Override) | XML | – |
| 261 | Item | IMPORTERS.ARBC_IMPR_NAME | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 262 | Item | IMPORTERS.ARBC_IMPR_NAME | KEY-NEXT-ITEM | 34 / 30 | default (Override) | XML | – |
| 263 | Item | IMPORTERS.IMPD_STMT_NBR | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 264 | Item | IMPORTERS.IMPR_DATA_SRCE | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 265 | Item | IMPORTERS.ENG_IMPR_NAME | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 266 | Item | IMPORTERS.ENG_IMPR_NAME | WHEN-VALIDATE-ITEM | 30 / 21 | default (Override) | XML | – |
| 267 | Item | IMPORTERS.IMPR_CNTCT_NAME | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 268 | Item | IMPORTERS.IMPR_ADDRESS | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 269 | Item | IMPORTERS.BUS_ID_ISSUE_DT | KEY-LISTVAL | 26 / 25 | default (Override) | XML | – |
| 270 | Item | IMPORTERS.BUS_ID_ISSUE_DT | KEY-F4 | 26 / 25 | default (Override) | XML | – |
| 271 | Item | IMPORTERS.BUS_ID_ISSUE_DT | WHEN-VALIDATE-ITEM | 14 / 12 | default (Override) | XML | – |
| 272 | Item | IMPORTERS.IMPR_NBR_PARENT | KEY-LISTVAL | 71 / 62 | default (Override) | XML | – |
| 273 | Item | IMPORTERS.IMPR_NBR_PARENT | WHEN-VALIDATE-ITEM | 21 / 17 | default (Override) | XML | – |
| 274 | Item | IMPORTERS.IMPR_NBR_PARENT2 | WHEN-BUTTON-PRESSED | 7 / 5 | default (Override) | XML | – |
| 275 | Item | IMPORTERS.IMPR_NAME_PARENT | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 276 | Item | IMPORTERS.ADD_CTRY_CD | KEY-LISTVAL | 75 / 64 | default (Override) | XML | – |
| 277 | Item | IMPORTERS.ADD_CTRY_CD | WHEN-VALIDATE-ITEM | 19 / 17 | default (Override) | XML | CGFK$CHK_IMPORTERS_IMP_ADD_CIT |
| 278 | Item | IMPORTERS.ADD_CTRY_CD2 | WHEN-BUTTON-PRESSED | 6 / 4 | default (Override) | XML | – |
| 279 | Item | IMPORTERS.ADD_CRTY_ARBC_NAME | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 280 | Item | IMPORTERS.CITY_CODE | KEY-LISTVAL | 81 / 67 | default (Override) | XML | – |
| 281 | Item | IMPORTERS.CITY_CODE | WHEN-VALIDATE-ITEM | 38 / 33 | default (Override) | XML | CGFK$CHK_IMPORTERS_IMP_ADD_CIT |
| 282 | Item | IMPORTERS.CITY_CODE2 | WHEN-BUTTON-PRESSED | 7 / 5 | default (Override) | XML | – |
| 283 | Item | IMPORTERS.CITY_NAME | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 284 | Item | IMPORTERS.IMPR_POB_NBR | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 285 | Item | IMPORTERS.IMPR_ZIP_CD | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 286 | Item | IMPORTERS.IMPR_TEL_NBR | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 287 | Item | IMPORTERS.IMPR_TEL_NBR | WHEN-VALIDATE-ITEM | 39 / 26 | default (Override) | XML | – |
| 288 | Item | IMPORTERS.IMPR_FAX_NBR | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 289 | Item | IMPORTERS.IMPR_TELEX_NBR | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 290 | Item | IMPORTERS.EMAIL | WHEN-VALIDATE-ITEM | 29 / 20 | default (Override) | XML | – |
| 291 | Item | IMPORTERS.MOBILE_NO | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 292 | Item | IMPORTERS.MOBILE_NO | WHEN-VALIDATE-ITEM | 34 / 26 | default (Override) | XML | – |
| 293 | Item | IMPORTERS.EXPRESS_POST | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 294 | Item | IMPORTERS.CTRY_CD_OF_ID | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 295 | Item | IMPORTERS.CTRY_CD_OF_ID | WHEN-VALIDATE-ITEM | 15 / 13 | default (Override) | XML | CGSF$CLRLU_IMPORTERS_IMP_BUS_I |
| 296 | Item | IMPORTERS.CUSTOMS_ENTERED | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 297 | Item | IMPORTERS.CUSTOMS_ENTERED2 | WHEN-BUTTON-PRESSED | 6 / 4 | default (Override) | XML | – |
| 298 | Item | IMPORTERS.EXPD_STMT_NBR | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 299 | Item | IMPORTERS.WVR_ENTRY_NBR | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 300 | Item | IMPORTERS.CREATION_FLAG | KEY-LISTVAL | 33 / 32 | default (Override) | XML | – |
| 301 | Item | IMPORTERS.CREATION_FLAG2 | WHEN-BUTTON-PRESSED | 6 / 4 | default (Override) | XML | – |

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
- Lines: 254 total / 90 active (non-blank, non-comment)
- Built-ins: ADD_PARAMETER, CALL_FORM, CLOSE_FORM, CREATE_PARAMETER_LIST, DESTROY_PARAMETER_LIST, FIND_FORM, GET_PARAMETER_LIST, GO_BLOCK, GO_ITEM, ID_NULL, OPEN_FORM, SET_ITEM_PROPERTY, RAISE FORM_TRIGGER_FAILURE
- Program units (form): CG$WHEN_NEW_FORM_INSTANCE
- Library / DB package calls: CGTE$OTHER_EXCEPTIONS, INTRFACE.MAKE_FIELD_ENTRABLE, NIB.WHEN_NEW_FORM_INSTANCE, STR.DISPALERT, STR.DISPARBMSG

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
  BEGIN
    CG$WHEN_NEW_FORM_INSTANCE;
  EXCEPTION
    WHEN OTHERS THEN
      CGTE$OTHER_EXCEPTIONS;
  END;
END;

BEGIN
	:global.current_ver := 11;
	:global.current_DT := '12-12-2023' ;
	:global.current_version := '('||:global.current_ver||'-('||:global.current_DT||')' ;
END;

DECLARE
PL_ID PARAMLIST;

  RET NUMBER;

BEGIN


BEGIN
   :GLOBAL.allow_mci := 0;
    :GLOBAL.allow_moi := 0;
   BEGIN
      SELECT var_value
        INTO :GLOBAL.allow_mci
        FROM sc_port_setting
       WHERE sysobj_id = 24 AND var_name = 'ALLOW_MCI'
AND PORT_CD    = :PARAMETER.P_CURR_PORT_CD;
      SELECT var_value
        INTO :GLOBAL.allow_moi
        FROM sc_port_setting
       WHERE sysobj_id = 24 AND var_name = 'ALLOW_MOI'
AND PORT_CD    = :PARAMETER.P_CURR_PORT_CD;

   EXCEPTION
      WHEN OTHERS
      THEN
         NULL;
   END;

   :GLOBAL.allow_mci := NVL (:GLOBAL.allow_mci, 0);
    :GLOBAL.allow_moi := NVL (:GLOBAL.allow_moi, 0);

END;

--INTRFACE.Make_Field_Entrable('IMPORTERS.COMM_RGSTRTN_TYPE' , FALSE);
INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_EXPRD_DT' , FALSE);
INTRFACE.Make_Field_Entrable('IMPORTERS.CITY_CODE_OF_ID' , FALSE);

	:global.Exec_Query_Now := 0;
	:global.PORT_CD  := NULL;
	:global.IMPR_NBR  := NULL;

	:GLOBAL.VALID:=0;
-- NEW VER.
	--IF :PARAMETER.P_CURR_PORT_CD <> 99 THEN

	--END IF;
-------------------------------------------------------------

IF NOT ID_NULL(FIND_FORM('SUPPORT_ENTRY')) THEN
  CLOSE_FORM('SUPPORT_ENTRY');
END IF;
  PL_ID := GET_PARAMETER_LIST('SUPPORT_ENTRY');
IF ID_NULL(PL_ID) THEN
   PL_ID := CREATE_PARAMETER_LIST('SUPPORT_ENTRY');
 IF ID_NULL(PL_ID) THEN
   STR.DISPALERT('Error creating parameter list SUPPORT_ENTRY','SYSTEM_ERROR');
   RAISE FORM_TRIGGER_FAILURE;
 END IF;
   ADD_PARAMETER(PL_ID,'WINDOW_X_POS',TEXT_PARAMETER,1.5);
   ADD_PARAMETER(PL_ID,'WINDOW_Y_POS',TEXT_PARAMETER,2);
   ADD_PARAMETER(PL_ID,'P_MODE',TEXT_PARAMETER,0);
   ADD_PARAMETER(PL_ID,'P_CURR_PORT_CD',TEXT_PARAMETER,:IMPORTERS.PORT_CD);
   CALL_FORM('SUPPORT_ENTRY.FMX',NO_HIDE,NO_REPLACE,NO_QUERY_ONLY,PL_ID);
   DESTROY_PARAMETER_LIST(PL_ID);

  IF :GLOBAL.LETTER_NBR IS NOT NULL THEN
   :PARAMETER.LETTER_NBR:=:GLOBAL.LETTER_NBR;
   GO_BLOCK('IMPORTERS');
   GO_ITEM('IMPORTERS.IMPR_NBR');
   SET_ITEM_PROPERTY('IMPORTERS.PORT_CD', ENABLED, PROPERTY_FALSE);

   OPEN_FORM('SUPPORT_ENTRY.FMX');
END IF;
END IF;

BEGIN
IF :IMPR_TYPE_CD = 4  AND  :BUS_ID_TYPE_CD = 3
OR :IMPR_TYPE_CD = 4  AND  :BUS_ID_TYPE_CD = 5 THEN

:CTRY_CD := 100;
SET_ITEM_PROPERTY('CTRY_CD', ENABLED,PROPERTY_FALSE);
SELECT CRTY_ARBC_NAME INTO :CRTY_ARBC_NAME
 FROM   COUNTRIES
 WHERE  CTRY_CD = 100;
END IF;

:ADD_CTRY_CD := 100 ;
SET_ITEM_PROPERTY('ADD_CTRY_CD', ENABLED,PROPERTY_FALSE);
SELECT CRTY_ARBC_NAME INTO :ADD_CRTY_ARBC_NAME
 FROM   COUNTRIES
 WHERE  CTRY_CD = 100;


EXCEPTION
WHEN NO_DATA_FOUND THEN
  ret := Str.DispArbMsg(18, 15,'ERROR');
  RAISE FORM_TRIGGER_FAILURE;

END;




END ;
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
- Lines: 44 total / 1 active (non-blank, non-comment)
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
- Lines: 17 total / 1 active (non-blank, non-comment)
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
- Lines: 12 total / 1 active (non-blank, non-comment)
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
- Lines: 170 total / 148 active (non-blank, non-comment)
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
          Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(13, 'This <p1> does not exist', 'رمز الجمــــــــــــــرك' ), 'E', 'OFG', 13);
        ELSIF (constraint_name = 'IMP_NATIONALITY_FK') THEN
          Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(13, 'This <p1> does not exist', 'NATIONALITY' ), 'E', 'OFG', 13);
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

      /* FK - Child record found */
      IF (server_err = 2292) THEN
        IF (err_code = 40510) THEN
          IF (constraint_name = 'AG_IMP_AGENT_ID_FK') THEN
            Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(5, 'Cannot delete <p1> while dependent <p2> exists', 'IMPORTERS','AGNTS' ), 'E', 'OFG', 5);
          ELSIF (constraint_name = 'AG_IMP_FK') THEN
            Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(5, 'Cannot delete <p1> while dependent <p2> exists', 'IMPORTERS','AGNTS' ), 'E', 'OFG', 5);
          ELSIF (constraint_name = 'DA_IMP_FK') THEN
            Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(5, 'Cannot delete <p1> while dependent <p2> exists', 'IMPORTERS','DELAY_AIR_DLVY_ORDERS' ), 'E', 'OFG', 5);
          ELSIF (constraint_name = 'IS_1_IMP_FK') THEN
            Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(5, 'Cannot delete <p1> while dependent <p2> exists', 'جدول المستوردين','توقيفات المستوردين' ), 'E', 'OFG', 5);
          ELSIF (constraint_name = 'BLOH_IMP_FK') THEN
            Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(5, 'Cannot delete <p1> while dependent <p2> exists', 'جدول المستوردين','Bl Owner Hist' ), 'E', 'OFG', 5);
          ELSIF (constraint_name = 'RCDS_IMP_FK') THEN
            Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(5, 'Cannot delete <p1> while dependent <p2> exists', 'IMPORTERS','REV_SECTIONS_CASH_DTLS' ), 'E', 'OFG', 5);
          ELSIF (constraint_name = 'SDO_IMP_FK') THEN
            Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(5, 'Cannot delete <p1> while dependent <p2> exists', 'جدول المستوردين','اذن التسليم' ), 'E', 'OFG', 5);
          ELSIF (constraint_name = 'IK_IMP_FK') THEN
            Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(5, 'Cannot delete <p1> while dependent <p2> exists', 'جدول المستوردين','الكلمات المميزه' ), 'E', 'OFG', 5);
          ELSIF (constraint_name = 'BU_IMP_FK') THEN
            Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(5, 'Cannot delete <p1> while dependent <p2> exists', 'جدول المستوردين','ملف الأنشطة للمخلصين' ), 'E', 'OFG', 5);
          ELSIF (constraint_name = 'BOW_IMP_FK') THEN
            Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(5, 'Cannot delete <p1> while dependent <p2> exists', 'IMPORTERS','BA_OWNERSHIPS' ), 'E', 'OFG', 5);
          ELSIF (constraint_name = 'BKM_IMP_FK') THEN
            Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(5, 'Cannot delete <p1> while dependent <p2> exists', 'جدول المستوردين','المخلصين' ), 'E', 'OFG', 5);
          ELSIF (constraint_name = 'XD_IMP_FK') THEN
            Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(5, 'Cannot delete <p1> while dependent <p2> exists', 'جدول المستوردين','قرارات الإعفاء' ), 'E', 'OFG', 5);
          ELSIF (constraint_name = 'LS_IMP_FK') THEN
            Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(5, 'Cannot delete <p1> while dependent <p2> exists', 'IMPORTERS','LFT_SALES' ), 'E', 'OFG', 5);
          ELSIF (constraint_name = 'DAP_IMP_FK') THEN
            Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(5, 'Cannot delete <p1> while dependent <p2> exists', 'IMPORTERS','DPLMTC_APLCTNS' ), 'E', 'OFG', 5);
          ELSIF (constraint_name = 'CSTMS_CLNT_IMP_FK') THEN
            Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(5, 'Cannot delete <p1> while dependent <p2> exists', 'جدول المستوردين','Cstms Clnts' ), 'E', 'OFG', 5);
          ELSIF (constraint_name = 'BI_IMP_FK') THEN
            Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(5, 'Cannot delete <p1> while dependent <p2> exists', 'جدول المستوردين','تفاويض المخلصين' ), 'E', 'OFG', 5);
          ELSIF (constraint_name = 'S2D_IMP_FK') THEN
            Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(5, 'Cannot delete <p1> while dependent <p2> exists', 'IMPORTERS','SMPL_20_DECLERATIONS' ), 'E', 'OFG', 5);
          ELSIF (constraint_name = 'DCLTN_MNFCT_IMPR_FK') THEN
            Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(5, 'Cannot delete <p1> while dependent <p2> exists', 'IMPORTERS','DECLARATIONS' ), 'E', 'OFG', 5);
          ELSIF (constraint_name = 'CPAS_IMP_FK') THEN
            Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(5, 'Cannot delete <p1> while dependent <p2> exists', 'جدول المستوردين','Client pay accts' ), 'E', 'OFG', 5);
          ELSIF (constraint_name = 'DCL_DOC_IMP_FK') THEN
            Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(5, 'Cannot delete <p1> while dependent <p2> exists', 'جدول المستوردين','مرفقات البيان' ), 'E', 'OFG', 5);
          ELSIF (constraint_name = 'DCLTN_IMP_FK') THEN
            Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(5, 'Cannot delete <p1> while dependent <p2> exists', 'IMPORTERS','DECLARATIONS' ), 'E', 'OFG', 5);
          ELSIF (constraint_name = 'DSD_IMP_FK') THEN
            Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(5, 'Cannot delete <p1> while dependent <p2> exists', 'جدول المستوردين','اذن التسليم' ), 'E', 'OFG', 5);
          ELSIF (constraint_name = 'CL_IMP_FK') THEN
            Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(5, 'Cannot delete <p1> while dependent <p2> exists', 'جدول المستوردين','Credit Letters' ), 'E', 'OFG', 5);
          ELSIF (constraint_name = 'MD_IMP_FK') THEN
            Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(5, 'Cannot delete <p1> while dependent <p2> exists', 'IMPORTERS','MISSING_DCLTNS' ), 'E', 'OFG', 5);
          ELSIF (constraint_name = 'DCLTN_AGNT_IMPR_FK') THEN
            Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(5, 'Cannot delete <p1> while dependent <p2> exists', 'IMPORTERS','DECLARATIONS' ), 'E', 'OFG', 5);
          ELSIF (constraint_name = 'WVR_IMP_FK') THEN
            Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(5, 'Cannot delete <p1> while dependent <p2> exists', 'جدول المستوردين','التعهدات' ), 'E', 'OFG', 5);
          ELSIF (constraint_name = 'AFRM_IMP_FK') THEN
            Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(5, 'Cannot delete <p1> while dependent <p2> exists', 'IMPORTERS','EXMTN_A_FORMS' ), 'E', 'OFG', 5);
          ELSIF (constraint_name = 'ER_IMP_FK') THEN
            Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(5, 'Cannot delete <p1> while dependent <p2> exists', 'IMPORTERS','ELIMINATE_REQUESTS' ), 'E', 'OFG', 5);
          ELSIF (constraint_name = 'SE_IMP_FK') THEN
            Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(5, 'Cannot delete <p1> while dependent <p2> exists', 'جدول المستوردين','Sandy Exports' ), 'E', 'OFG', 5);
          ELSIF (constraint_name = 'VCE_IMP_FK') THEN
            Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(5, 'Cannot delete <p1> while dependent <p2> exists', 'جدول المستوردين','ملف استثناء السيارات' ), 'E', 'OFG', 5);
          ELSIF (constraint_name = 'BO_IMP_FK') THEN
            Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(5, 'Cannot delete <p1> while dependent <p2> exists', 'جدول المستوردين','مالك البوليصة' ), 'E', 'OFG', 5);
          ELSIF (constraint_name = 'BW_IMP_FK') THEN
            Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(5, 'Cannot delete <p1> while dependent <p2> exists', 'IMPORTERS','BA_WAREHOUSES' ), 'E', 'OFG', 5);
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

#### IMPORTERS · POST-QUERY

- Level: Block · Owner: `IMPORTERS` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 177 total / 162 active (non-blank, non-comment)
- Built-ins: NAME_IN, SET_BLOCK_PROPERTY, SET_RECORD_PROPERTY
- Program units (form): CG$IMPR1130_PROD_CENTRL_GLOBAL, CGFK$QRY_IMPORTERS_IMP_ADD_CIT, CGFK$QRY_IMPORTERS_IMP_BUS_ID_, CGFK$QRY_IMPORTERS_IMP_CTRY_FK, CGFK$QRY_IMPORTERS_IMP_ITIDT_F, CGFK$QRY_IMPORTERS_IMP_SDP_FK
- Library / DB package calls: CGTE$OTHER_EXCEPTIONS, DES$FORM_ERRORS.MSGGETTEXT, DES$FORM_ERRORS.PUSH, DES$FORM_ERRORS.RAISE_FAILURE, IMPR.IMPR_SUSPENDED, INTRFACE.MAKE_FIELD_ENTRABLE

```plsql
BEGIN
	IF :IMPORTERS.IMPR_NBR IS NOT NULL THEN
		IF IMPR.Impr_Suspended(:IMPORTERS.PORT_CD, :IMPORTERS.IMPR_NBR, HIJDATE.Cur_Hij_Date) = 1 THEN
			:IMPORTERS.SUSPN_STATUS := 'موقوف';

		ELSE
			:IMPORTERS.SUSPN_STATUS := 'غير موقوف';
		END IF;
	END IF;


	INTRFACE.Make_Field_Entrable('IMPORTERS.CTRY_CD' , TRUE);
	INTRFACE.Make_Field_Entrable('IMPORTERS.ADD_CTRY_CD' , TRUE);
	INTRFACE.Make_Field_Entrable('IMPORTERS.CITY_CODE_OF_ID' , TRUE);
	INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_BRNCH' , TRUE);
	INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID' , TRUE);
	--INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_TYPE_CD' , TRUE);
      --

	IF :IMPORTERS.IMPR_TYPE_CD = 1 THEN
		INTRFACE.Make_Field_Entrable('IMPORTERS.CTRY_CD' , FALSE);
		INTRFACE.Make_Field_Entrable('IMPORTERS.ADD_CTRY_CD' , FALSE);
	ELSIF :IMPORTERS.IMPR_TYPE_CD = 2 THEN
		INTRFACE.Make_Field_Entrable('IMPORTERS.CTRY_CD' , FALSE);
		INTRFACE.Make_Field_Entrable('IMPORTERS.ADD_CTRY_CD' , FALSE);
		INTRFACE.Make_Field_Entrable('IMPORTERS.CITY_CODE_OF_ID' , FALSE);
		INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_BRNCH' , FALSE);

	ELSIF :IMPORTERS.IMPR_TYPE_CD = 4 THEN
		INTRFACE.Make_Field_Entrable('IMPORTERS.CITY_CODE_OF_ID' , FALSE);
		INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_BRNCH' , FALSE);
	ELSIF :IMPORTERS.IMPR_TYPE_CD = 5 THEN
		INTRFACE.Make_Field_Entrable('IMPORTERS.CTRY_CD' , FALSE);
		INTRFACE.Make_Field_Entrable('IMPORTERS.ADD_CTRY_CD' , FALSE);
	ELSIF :IMPORTERS.IMPR_TYPE_CD = 7 THEN
		INTRFACE.Make_Field_Entrable('IMPORTERS.CITY_CODE_OF_ID' , FALSE);
		INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_BRNCH' , FALSE);
	ELSIF :IMPORTERS.IMPR_TYPE_CD = 8 THEN
		INTRFACE.Make_Field_Entrable('IMPORTERS.CTRY_CD' , FALSE);
		INTRFACE.Make_Field_Entrable('IMPORTERS.ADD_CTRY_CD' , FALSE);
	ELSIF :IMPORTERS.IMPR_TYPE_CD = 9 THEN
		IF :IMPORTERS.BUS_ID_TYPE_CD = 6 THEN
			INTRFACE.Make_Field_Entrable('IMPORTERS.CTRY_CD' , FALSE);
			INTRFACE.Make_Field_Entrable('IMPORTERS.ADD_CTRY_CD' , FALSE);
			INTRFACE.Make_Field_Entrable('IMPORTERS.CITY_CODE_OF_ID' , FALSE);
			INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_BRNCH' , FALSE);
			INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID' , FALSE);
		ELSE
			INTRFACE.Make_Field_Entrable('IMPORTERS.CTRY_CD' , TRUE);
			INTRFACE.Make_Field_Entrable('IMPORTERS.ADD_CTRY_CD' , TRUE);
			INTRFACE.Make_Field_Entrable('IMPORTERS.CITY_CODE_OF_ID' , TRUE);

			INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID' , TRUE);
			INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_BRNCH' , FALSE);
		END IF;
	ELSIF :IMPORTERS.IMPR_TYPE_CD = 10 THEN
			INTRFACE.Make_Field_Entrable('IMPORTERS.CITY_CODE_OF_ID' , FALSE);
			INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_BRNCH' , FALSE);
	ELSIF :IMPORTERS.IMPR_TYPE_CD = 11 THEN
			INTRFACE.Make_Field_Entrable('IMPORTERS.CTRY_CD' , FALSE);
			INTRFACE.Make_Field_Entrable('IMPORTERS.ADD_CTRY_CD' , FALSE);
			INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_BRNCH' , FALSE);
	ELSIF :IMPORTERS.IMPR_TYPE_CD = 12 THEN
			INTRFACE.Make_Field_Entrable('IMPORTERS.CITY_CODE_OF_ID' , FALSE);
	ELSIF :IMPORTERS.IMPR_TYPE_CD IN (13, 14) THEN
			INTRFACE.Make_Field_Entrable('IMPORTERS.CTRY_CD' , FALSE);
			INTRFACE.Make_Field_Entrable('IMPORTERS.ADD_CTRY_CD' , FALSE);
			INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID' , FALSE);
			INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_BRNCH' , FALSE);
			INTRFACE.Make_Field_Entrable('IMPORTERS.CITY_CODE_OF_ID' , FALSE);
	END IF;

END;

BEGIN
   SELECT status_desc
     INTO :importers.status_desc
     FROM mci_bus_id_status
    WHERE bus_id_status LIKE :importers.bus_id_status;
EXCEPTION
   WHEN OTHERS THEN NULL;
END;
/* CGFK$QRY_LOOKUP_DATA */
/* Query lookup data for the foreign key(s) */
BEGIN
  IF (name_in('IMPORTERS.PORT_CD') IS NOT NULL) THEN
    BEGIN
      CGFK$QRY_IMPORTERS_IMP_SDP_FK(
        :IMPORTERS.PORT_NAME    /* MOD: Value in Item :IMPORTERS.PORT_NAME.                                                                                                                                                                   */
       ,:IMPORTERS.PORT_CD  );  /* IN : Value in Item :IMPORTERS.PORT_CD.                                                                                                                                                                     */
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(13, 'This <p1> does not exist', 'رمز الجمــــــــــــــرك' ), 'E', 'OFG', 13);
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
       ,:IMPORTERS.ITIDT_NOTE          /* MOD: Value in Item :IMPORTERS.ITIDT_NOTE.                                                                                                                                                           */
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
  IF (name_in('IMPORTERS.CITY_CODE_OF_ID') IS NOT NULL OR name_in('IMPORTERS.CTRY_CD_OF_ID') IS NOT NULL) THEN
    BEGIN
      CGFK$QRY_IMPORTERS_IMP_BUS_ID_(
        :IMPORTERS.ID_MINS_COMM_CD      /* MOD: Value in Item :IMPORTERS.ID_MINS_COMM_CD.                                                                                                                                                     */
       ,:IMPORTERS.ID_CITY_NAME         /* MOD: Value in Item :IMPORTERS.ID_CITY_NAME.                                                                                                                                                        */
       ,:IMPORTERS.L_CT_CITY_STATUS2    /* MOD: Value in Item :IMPORTERS.L_CT_CITY_STATUS2.                                                                                                                                                   */
       ,:IMPORTERS.CTRY_CD_OF_ID        /* IN : Value in Item :IMPORTERS.CTRY_CD_OF_ID.                                                                                                                                                       */
       ,:IMPORTERS.CITY_CODE_OF_ID  );  /* IN : Value in Item :IMPORTERS.CITY_CODE_OF_ID.                                                                                                                                                     */
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        Des$Form_errors.PUSH('خطأ في رمز مدينة مصدر الرقم الإستدلالي', 'E', 'OFG', 0);
      WHEN OTHERS THEN
        CGTE$OTHER_EXCEPTIONS;
    END;
    SET_RECORD_PROPERTY(:SYSTEM.TRIGGER_RECORD, 'IMPORTERS', STATUS ,                 QUERY_STATUS);
  END IF;
  IF (name_in('IMPORTERS.ADD_CTRY_CD') IS NOT NULL OR name_in('IMPORTERS.CITY_CODE') IS NOT NULL) THEN
    BEGIN
      CGFK$QRY_IMPORTERS_IMP_ADD_CIT(
        :IMPORTERS.ADD_CRTY_ARBC_NAME    /* MOD: Value in Item :IMPORTERS.ADD_CRTY_ARBC_NAME.                                                                                                                                                 */
       ,:IMPORTERS.CITY_NAME             /* MOD: Value in Item :IMPORTERS.CITY_NAME.                                                                                                                                                          */
       ,:IMPORTERS.L_CT_CITY_STATUS      /* MOD: Value in Item :IMPORTERS.L_CT_CITY_STATUS.                                                                                                                                                   */
       ,:IMPORTERS.CITY_CODE             /* IN : Value in Item :IMPORTERS.CITY_CODE.                                                                                                                                                          */
       ,:IMPORTERS.ADD_CTRY_CD       );  /* IN : Value in Item :IMPORTERS.ADD_CTRY_CD.                                                                                                                                                        */
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        Des$Form_errors.PUSH('خطأ في رمز مدينة عنوان المستورد', 'E', 'OFG', 0);
      WHEN OTHERS THEN
        CGTE$OTHER_EXCEPTIONS;
    END;
    SET_RECORD_PROPERTY(:SYSTEM.TRIGGER_RECORD, 'IMPORTERS', STATUS ,                 QUERY_STATUS);
  ELSE
      Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(78, '<p1> must be entered', 'دولــــــــة الإقامـــــة,المدينـــــــــــــــــــــة' ), 'E', 'OFG', 78);
      Des$Form_errors.RAISE_FAILURE;
  END IF;
END;

/* CGFK$RESET_BLOCK_WHERE_CLAUSE */
/* Resets block where clause */
BEGIN
  IF (CG$IMPR1130_PROD_CENTRL_GLOBAL.IMPORTERS_WHERE <> 'first_time') THEN
    set_block_property('IMPORTERS', DEFAULT_WHERE, CG$IMPR1130_PROD_CENTRL_GLOBAL.IMPORTERS_WHERE);
    CG$IMPR1130_PROD_CENTRL_GLOBAL.IMPORTERS_WHERE := 'first_time';
  END IF;
END;
```

#### IMPORTERS · PRE-QUERY

- Level: Block · Owner: `IMPORTERS` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 77 total / 63 active (non-blank, non-comment)
- Built-ins: FIND_BLOCK, GET_BLOCK_PROPERTY, NAME_IN, SET_BLOCK_PROPERTY
- Program units (form): CG$IMPR1130_PROD_CENTRL_GLOBAL
- Library / DB package calls: CG$IMPR1130_PROD_CENTRL_GLOBAL.IMPORTERS_WHERE, DES$FORM_ERRORS.MSGGETTEXT, DES$FORM_ERRORS.PUSH, DES$FORM_ERRORS.RAISE_FAILURE, STR.STRFORMAT

```plsql
BEGIN

	IF :PARAMETER.PRSNL_IMPR = 1 THEN
		:IMPR_TYPE_CD := 4;
	END IF;

	IF (:global.Exec_Query_Now = 1) THEN
		IF (:global.IMPR_NBR  IS NOT NULL ) THEN
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
    IF ( CG$IMPR1130_PROD_CENTRL_GLOBAL.IMPORTERS_WHERE = 'first_time') THEN
      CG$IMPR1130_PROD_CENTRL_GLOBAL.IMPORTERS_WHERE := get_block_property(block_id, DEFAULT_WHERE);
    END IF;
    def_where := CG$IMPR1130_PROD_CENTRL_GLOBAL.IMPORTERS_WHERE;

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

#### IMPORTERS · PRE-INSERT

- Level: Block · Owner: `IMPORTERS` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 171 total / 115 active (non-blank, non-comment)
- Built-ins: NAME_IN, SET_BLOCK_PROPERTY, RAISE FORM_TRIGGER_FAILURE
- Program units (form): CGSF$CLRLU_IMPORTERS_IMP_BUS_I, CHK_IMPR_DUPL
- Library / DB package calls: ACTIVITY.ADD_ACTIVITY, CGTE$OTHER_EXCEPTIONS, DB_JOURNAL.JOURNALING_ON, INTRFACE.MAKE_FIELD_ENTRABLE, LIB_USR.IMPR_CENTRAL.CREATE_UNI_IMPR_NEBRAS, STR.DISPALERT, STR.DISPARBMSG

```plsql
DECLARE
/*
CURSOR c1_hq_nbr IS
	SELECT 	HQ_IMPR_NBR
	FROM 		HQ_IMPRS
	WHERE 	BUS_ID_TYPE_CD = :IMPORTERS.BUS_ID_TYPE_CD
	AND		BUS_ID = :IMPORTERS.BUS_ID
	AND		BUS_ID_BRNCH = :IMPORTERS.BUS_ID_BRNCH;

CURSOR c2_hq_nbr IS
	SELECT 	HQ_IMPR_NBR
	FROM 		HQ_IMPRS
	WHERE 	BUS_ID_TYPE_CD = :IMPORTERS.BUS_ID_TYPE_CD
	AND		BUS_ID = :IMPORTERS.BUS_ID
	AND		BUS_ID_BRNCH IS NULL;
*/
ret     NUMBER;
BEGIN
	SET_BLOCK_PROPERTY('IMPORTERS',UPDATE_ALLOWED,PROPERTY_FALSE);

	   IF :BUS_ID_EXPRD_DT IS NULL THEN
      INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_EXPRD_DT',TRUE);
  	ret := Str.DispArbMsg(9,220,'ERROR');
	RAISE FORM_TRIGGER_FAILURE;
   END IF;

  IF :IMPR_TEL_NBR IS NULL THEN
      INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_TEL_NBR',TRUE);
      RET := STR.DispALERT('يجب ادخال رقم الهاتف','ERROR');
      RAISE FORM_TRIGGER_FAILURE;
  END IF;

IF :MOBILE_NO IS NULL THEN
STR.DISPALERT('يجب إدخال رقم المحمول','ERROR');
RAISE FORM_TRIGGER_FAILURE;
END IF;

CHK_IMPR_DUPL;


--:IMPR_NAME_STD := STR.StrFormat(:ARBC_IMPR_NAME);
/*
IF :IMPORTERS.BUS_ID_BRNCH IS NULL THEN
	OPEN 	c2_hq_nbr;
	FETCH c2_hq_nbr INTO :IMPORTERS.hq_impr_nbr;
	CLOSE c2_hq_nbr;
ELSE
	OPEN 	c1_hq_nbr;
	FETCH c1_hq_nbr INTO :IMPORTERS.hq_impr_nbr;
	CLOSE c1_hq_nbr;
END IF;
*/
 IF :GLOBAL.LETTER_NBR IS NOT NULL THEN
  DB_JOURNAL.JOURNALING_ON(:GLOBAL.PORT_CD,:GLOBAL.SUPP_TITLE_CD,:GLOBAL.LETTER_NBR,:GLOBAL.LETTER_DT);

 END IF;
IF NOT ACTIVITY.ADD_ACTIVITY(9, 2, 1, :IMPORTERS.Port_Cd||'!'||:IMPORTERS.Impr_Nbr) THEN
	RAISE FORm_Trigger_Failure;
END IF;
END;


---------CREATED BY BASSAM MANSOUR --- 09/01/2019 -------
      /* RECORD IMPORTER IN HQ AND PORT */
---------------------------------------------------------
SET_BLOCK_PROPERTY('IMPORTERS',UPDATE_ALLOWED,PROPERTY_FALSE);
DECLARE
	V_IMPR_NBR        VARCHAR2(50);
  V_msg_txt         VARCHAR2(500);
  V_RESULT          NUMBER;
  V_IMPR_TEL_NBR    NUMBER;
BEGIN

IF :IMPR_TEL_NBR = 'NULL' THEN
   V_IMPR_TEL_NBR := 0 ;
ELSE
V_IMPR_TEL_NBR := NVL(:IMPR_TEL_NBR,0);
END IF;

	LIB_USR.IMPR_CENTRAL.Create_Uni_IMPR_NEBRAS ( :PORT_CD,
	                                              :BUS_ID,
	                                              :BUS_ID_BRNCH,
	                                              :BUS_ID_TYPE_CD,
	                                              :IMPR_TYPE_CD,
	                                              :CTRY_CD,
	                                              :CITY_CODE,
	                                              :IMPR_CNTCT_NAME,
	                                              V_IMPR_TEL_NBR ,
                                                    :EMAIL,
	                                              :BANK_IBAN,
						                NVL(:IMPR_POB_NBR,0),
	                                              TO_CHAR(:BUS_ID_EXPRD_DT,'MI-MM-YYYY'),
	                                              :ACTIVITY,
	                                              :ARBC_IMPR_NAME,
	                                              :ENG_IMPR_NAME,
			                                  NVL(:MOBILE_NO,0),
							          NVL(:IMPR_ZIP_CD,0),
	                                              0, --NVL(:BRNH_CITY_CD,0),
	                                              :IMPR_EXPR_TYPE,
	                                              :IMPR_ADDRESS,
	                                              TO_CHAR(:BUS_ID_ISSUE_DT,'MI-MM-YYYY'),
	                                              :ID_NBR,
	                                              NVL(:COMM_RGSTRTN_TYPE,0),
	                                              0,--NVL(:CTRY_CD_OF_ID,0),
	                                              NVL(:CITY_CODE_OF_ID,0),
	                                              NVL(:IMPR_NBR_PARENT,0),
	                                              NVL(:IMPR_FAX_NBR,0),
	                                              NVL(:IMPR_TELEX_NBR,0),
	                                              NVL(:ADD_CTRY_CD,0),
	                                              NVL(:IMPD_STMT_NBR,0),
	                                              NVL(:IMPR_DATA_SRCE,0),
	                                              0,--NVL(:CUSTOMS_ENTERED,0),
	                                              NVL(:EXPD_STMT_NBR,0),
	                                              NVL(:WVR_ENTRY_NBR,0),
	                                              NVL(:CAR_AGENT_FLAG,0),
	                                              NVL(:EXPRESS_POST,0),
	                                              V_IMPR_NBR,
	                                              V_msg_txt,
	                                              V_RESULT,
	                                              :PARAMETER.P_USER_ID,
	                                              :PARAMETER.P_WS_ID,
                                                     NULL , --birth date no need for commercial
                                                     :NATIONAL_NBR
	                                              );


     IF V_RESULT = 1 THEN
     		     STR.DISPALERT(V_msg_txt,'INFORMATION');--||' <=> '||V_RESULT,'ERROR') ;
             STR.DISPALERT('رقم المستورد'||' = '||V_IMPR_NBR,'INFORMATION') ;
:GLOBAL.SET :=  V_IMPR_NBR ;


IF :GLOBAL.SET IS NOT NULL THEN
 :HQ_IMPR_NBR := :GLOBAL.SET;
     INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID' , FALSE);
     INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_BRNCH', FALSE);
     INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_EXPRD_DT' , FALSE);
     INTRFACE.Make_Field_Entrable('IMPORTERS.ARBC_IMPR_NAME' , FALSE);
     INTRFACE.Make_Field_Entrable('IMPORTERS.COMM_RGSTRTN_TYPE' , FALSE);
     INTRFACE.Make_Field_Entrable('IMPORTERS.CITY_CODE_OF_ID',FALSE);
     INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_TYPE_CD' , FALSE);
     INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_EXPR_TYPE' , FALSE);
     INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_TYPE_CD' , FALSE);
     --INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_TEL_NBR', FALSE);
END IF;

	   ELSE

	           STR.DISPALERT(V_msg_txt,'INFORMATION');--||' <=> '||V_RESULT,'ERROR') ;
             --STR.DISPALERT('رقم المستورد'||'='||V_IMPR_NBR,'INFORMATION') ;
	     		RAISE FORm_Trigger_Failure;
	     		SET_BLOCK_PROPERTY('IMPORTERS',UPDATE_ALLOWED,PROPERTY_TRUE);

     END IF;

END ;
---------CREATED BY BASSAM MANSOUR --- 09/01/2019 -------
      /* RECORD IMPORTER IN HQ AND PORT */
---------------------------------------------------------
/* CGFK$CLR_FK_ON_INS */
/* Clear foreign key columns if any optional columns are null */
BEGIN
  IF (name_in('IMPORTERS.CITY_CODE_OF_ID') IS NULL AND name_in('IMPORTERS.CTRY_CD_OF_ID') IS NULL) THEN
    BEGIN
      CGSF$CLRLU_IMPORTERS_IMP_BUS_I;
    EXCEPTION
      WHEN OTHERS THEN
        CGTE$OTHER_EXCEPTIONS;
    END;
  END IF;
END;
```

#### IMPORTERS · PRE-DELETE

- Level: Block · Owner: `IMPORTERS` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 20 total / 16 active (non-blank, non-comment)
- Built-ins: RAISE FORM_TRIGGER_FAILURE
- Program units (form): CGRI$CHK_IMPORTERS
- Library / DB package calls: ACTIVITY.ADD_ACTIVITY, CGTE$OTHER_EXCEPTIONS

```plsql
BEGIN
	IF NOT ACTIVITY.ADD_ACTIVITY(9, 2, 5, :IMPORTERS.Port_Cd||'!'||:IMPORTERS.Impr_Nbr) THEN
		RAISE FORm_Trigger_Failure;
	END IF;
END;
/* CGRI$CASCADE_DELETE */
/* This performs referential integrity checks/updates prior to the  */
/* deletion of a row.  It first performs any block deletion checks, */
/* and then any database updates required due to the delete.        */
BEGIN
  BEGIN
    CGRI$CHK_IMPORTERS(
      FALSE                  /* IN : Check FKs validated in BOTH (client/server)?                                                                                                                                                             */
     ,:IMPORTERS.IMPR_NBR    /* IN : Item value                                                                                                                                                                                               */
     ,:IMPORTERS.PORT_CD );  /* IN : Item value                                                                                                                                                                                               */
  EXCEPTION
    WHEN OTHERS THEN
      CGTE$OTHER_EXCEPTIONS;
  END;
END;
```

#### IMPORTERS · KEY-DELREC

- Level: Block · Owner: `IMPORTERS` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 65 total / 52 active (non-blank, non-comment)
- Built-ins: DELETE_RECORD, FORMS_DDL, GET_ITEM_PROPERTY, NAME_IN, COMMIT (DB)
- Program units (form): CGRI$CHK_IMPORTERS
- Library / DB package calls: CG$CHK_PACKAGE_FAILURE, CGTE$OTHER_EXCEPTIONS, STR.DISPALERT

```plsql
DECLARE
	RET  NUMBER;
	PROP VARCHAR2(10);
	STAT VARCHAR2(10);
	PROP1 VARCHAR2(10);
BEGIN
  STAT := NAME_IN('SYSTEM.RECORD_STATUS');
  PROP1 := GET_ITEM_PROPERTY('REMOVE',VISIBLE);
  PROP  := GET_ITEM_PROPERTY('REMOVE',ENABLED);
  IF PROP = 'FALSE' AND PROP1 = 'FALSE' THEN
       NULL;
  ELSIF STAT !='NEW' AND PROP = 'TRUE' AND PROP1 = 'TRUE' THEN
    BEGIN
	    RET := STR.DispAlert('هل أنت متأكد من عملية الحذف','WARNING');
	    IF RET = ALERT_BUTTON1 THEN

		DELETE 	IMPR_KNWNS
		WHERE 	PORT_CD 	= :IMPORTERS.PORT_CD
		AND		IMPR_NBR 	= :IMPORTERS.IMPR_NBR
		;


		DELETE 	IMPR_UPDTS
		WHERE 	PORT_CD 	= :IMPORTERS.PORT_CD
		AND		IMPR_NBR 	= :IMPORTERS.IMPR_NBR
		;

		FORMS_DDL('COMMIT');

   	      Delete_record;
  	      COMMIT;
         ELSIF RET = ALERT_BUTTON2 THEN
           NULL;
       END IF;
    END;
END IF;

END;
/* CGRI$CHECK_ON_DELETE */
/* This checks that the user is allowed to delete the current row, */
/* prior to removing it,  according to any referential integrity   */
/* rules held in the database design.                              */
BEGIN
  BEGIN
    CGRI$CHK_IMPORTERS(
      TRUE                   /* IN : Check FKs validated in BOTH (client/server)?                                                                                                                                                             */
     ,:IMPORTERS.IMPR_NBR    /* IN : Item value                                                                                                                                                                                               */
     ,:IMPORTERS.PORT_CD );  /* IN : Item value                                                                                                                                                                                               */
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

#### IMPORTERS · KEY-HELP

- Level: Block · Owner: `IMPORTERS` · Execution hierarchy: default (Override) · Fire in query: true
- Lines: 130 total / 128 active (non-blank, non-comment)
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

#### IMPORTERS · POST-INSERT

- Level: Block · Owner: `IMPORTERS` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 8 total / 6 active (non-blank, non-comment)
- Built-ins: –
- Program units (form): INSERT_AUDIT_RECORD
- Library / DB package calls: DB_JOURNAL.JOURNALING_OFF

```plsql
BEGIN
Insert_Audit_Record ('I');

IF DB_JOURNAL.IS_JOURNALING_ON THEN
  DB_JOURNAL.JOURNALING_OFF;
 END IF;

END;
```

#### IMPORTERS · PRE-RECORD

- Level: Block · Owner: `IMPORTERS` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 19 total / 17 active (non-blank, non-comment)
- Built-ins: –
- Program units (form): –
- Library / DB package calls: STR.DISPARBMSG

```plsql
DECLARE
	ret NUMBER;
	CURSOR C_P_NAME IS
	    	SELECT ARBC_IMPR_NAME
		FROM IMPORTERS
		WHERE IMPR_NBR = :IMPR_NBR_PARENT
AND PORT_CD    = :PARAMETER.P_CURR_PORT_CD;

BEGIN
IF :IMPR_NBR_PARENT IS NOT NULL THEN
	OPEN C_P_NAME;
	FETCH C_P_NAME INTO :IMPR_NAME_PARENT;

	IF C_P_NAME%NOTFOUND THEN
		ret := Str.DispArbMsg(9, 150,'ERROR');
	END IF;
	CLOSE C_P_NAME;
END IF;
END;
```

#### IMPORTERS · PRE-UPDATE

- Level: Block · Owner: `IMPORTERS` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 51 total / 44 active (non-blank, non-comment)
- Built-ins: RAISE FORM_TRIGGER_FAILURE
- Program units (form): INSERT_AUDIT_RECORD
- Library / DB package calls: ACTIVITY.ADD_ACTIVITY, STR.STRFORMAT

```plsql
DECLARE

CURSOR c1_hq_nbr IS
	SELECT 	HQ_IMPR_NBR
	FROM 		HQ_IMPRS
	WHERE 	BUS_ID_TYPE_CD = :IMPORTERS.BUS_ID_TYPE_CD
	AND		BUS_ID = :IMPORTERS.BUS_ID
	AND		BUS_ID_BRNCH = :IMPORTERS.BUS_ID_BRNCH;

CURSOR c2_hq_nbr IS
	SELECT 	HQ_IMPR_NBR
	FROM 		HQ_IMPRS
	WHERE 	BUS_ID_TYPE_CD = :IMPORTERS.BUS_ID_TYPE_CD
	AND		BUS_ID = :IMPORTERS.BUS_ID
	AND		BUS_ID_BRNCH IS NULL;
V_HQ_NBR NUMBER := NULL;
BEGIN
:IMPR_NAME_STD := STR.StrFormat(:ARBC_IMPR_NAME);
Insert_Audit_Record ('U');

IF :IMPORTERS.BUS_ID_BRNCH IS NULL THEN
	OPEN 	c2_hq_nbr;
	FETCH c2_hq_nbr INTO V_HQ_NBR;
	:IMPORTERS.hq_impr_nbr := V_HQ_NBR;
	CLOSE c2_hq_nbr;
ELSE
	OPEN 	c1_hq_nbr;
	FETCH c1_hq_nbr INTO V_HQ_NBR;
	:IMPORTERS.hq_impr_nbr := V_HQ_NBR;
	CLOSE c1_hq_nbr;
END IF;

IF NOT ACTIVITY.ADD_ACTIVITY(9, 2, 2, :IMPORTERS.Port_Cd||'!'||:IMPORTERS.Impr_Nbr) THEN
	RAISE FORm_Trigger_Failure;
END IF;
END;

-----------------------------------
-------------anas-----------------
DECLARE
	V_ANAME VARCHAR2(200);
	V_ENAME VARCHAR2(200);
	V_CNAME VARCHAR2(200);
BEGIN
V_ANAME := LTRIM(RTRIM(:IMPORTERS.ARBC_IMPR_NAME));
V_ENAME := LTRIM(RTRIM(:IMPORTERS.ENG_IMPR_NAME));
V_CNAME := LTRIM(RTRIM(:IMPORTERS.IMPR_CNTCT_NAME));
:IMPORTERS.ARBC_IMPR_NAME:=V_ANAME;
:IMPORTERS.ENG_IMPR_NAME:=V_ENAME;
:IMPORTERS.IMPR_CNTCT_NAME:=V_CNAME;
END;
```

#### IMPORTERS · WHEN-CREATE-RECORD

- Level: Block · Owner: `IMPORTERS` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 59 total / 35 active (non-blank, non-comment)
- Built-ins: SET_ITEM_PROPERTY
- Program units (form): –
- Library / DB package calls: INTRFACE.MAKE_FIELD_ENTRABLE

```plsql
BEGIN
	-- NEW VER.
	--IF :PARAMETER.P_CURR_PORT_CD <> 99 THEN
		:IMPORTERS.PORT_CD := :PARAMETER.P_CURR_PORT_CD;

		SELECT PORT_NAME
		INTO:PORT_NAME
		FROM SD_PORTS
		WHERE	PORT_CD = :IMPORTERS.PORT_CD;
	--ELSE
	--	:IMPORTERS.PORT_CD := NULL;
	--END IF;


	IF :PARAMETER.PRSNL_IMPR = 1 THEN
		:IMPORTERS.IMPR_TYPE_CD := 4;

		SELECT 	IMPR_TYPE_NAME
		INTO		:IMPORTERS.IMPR_TYPE_NAME
		FROM		IMPR_TYPES
		WHERE		IMPR_TYPE_CD = :IMPORTERS.IMPR_TYPE_CD
		;

		INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_TYPE_CD' , FALSE);
		INTRFACE.Make_Field_Entrable('IMPORTERS.CITY_CODE_OF_ID' , FALSE);
		INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_BRNCH' , FALSE);

	ELSE
		INTRFACE.Make_Field_Entrable('IMPORTERS.CITY_CODE_OF_ID' , TRUE);
		INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_BRNCH' , TRUE);
	END IF;


	INTRFACE.Make_Field_Entrable('IMPORTERS.CTRY_CD' , TRUE);
	INTRFACE.Make_Field_Entrable('IMPORTERS.ADD_CTRY_CD' , TRUE);
	INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID' , TRUE);
	--INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_TYPE_CD' , TRUE);
      --

	:Global.Ins := 0;
------------------------------------------------
-- UPDATE BY ANAS --
-- 10-05-2005 --

    INTRFACE.Make_Field_Entrable('IMPORTERS.COMM_RGSTRTN_TYPE' , TRUE);
    INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_POB_NBR' , TRUE);
    INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_ZIP_CD' , TRUE);
    INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_TEL_NBR' , TRUE);
    INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_FAX_NBR' , TRUE);
    INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_TELEX_NBR' , TRUE);
    INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_EXPRD_DT' , TRUE);

    INTRFACE.Make_Field_Entrable('IMPORTERS.CITY_CODE_OF_ID' , TRUE);

    SET_ITEM_PROPERTY('IMPORTERS.CITY_CODE_OF_ID2' , ENABLED , PROPERTY_TRUE);

    INTRFACE.Make_Field_Entrable('IMPORTERS.ARBC_IMPR_NAME' , TRUE);
---------------------
END;
```

#### IMPORTERS · WHEN-NEW-ITEM-INSTANCE

- Level: Block · Owner: `IMPORTERS` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 7 total / 7 active (non-blank, non-comment)
- Built-ins: CLEAR_BLOCK, EXECUTE_QUERY
- Program units (form): –
- Library / DB package calls: –

```plsql
BEGIN
IF :global.Exec_Query_Now = 1 THEN
	Clear_Block(No_Validate);
	execute_query;
	:global.Exec_Query_Now := 0;
END IF;
END;
```

#### IMPORTERS · WHEN-NEW-RECORD-INSTANCE

- Level: Block · Owner: `IMPORTERS` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 37 total / 32 active (non-blank, non-comment)
- Built-ins: GO_ITEM, SET_ITEM_PROPERTY
- Program units (form): –
- Library / DB package calls: INTRFACE.MAKE_FIELD_ENTRABLE

```plsql
DECLARE
	V_COUNT NUMBER;
BEGIN
--INTRFACE.Make_Field_Entrable('IMPORTERS.COMM_RGSTRTN_TYPE' , FALSE);
INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_EXPRD_DT' , FALSE);
INTRFACE.Make_Field_Entrable('IMPORTERS.CITY_CODE_OF_ID' , FALSE);

IF :IMPORTERS.IMPR_NBR IS NOT NULL THEN
	SELECT COUNT(*)
	INTO	V_COUNT
	FROM 	DECLARATIONS
	WHERE PORT_CD    = :PARAMETER.P_CURR_PORT_CD AND (
		(AGENT_NBR = :IMPORTERS.IMPR_NBR)
		OR
		(IMPR_NBR IS NOT NULL AND IMPR_NBR = :IMPORTERS.IMPR_NBR)
		)
	AND	ROWNUM = 1
	;

	IF V_COUNT > 0 THEN
		INTRFACE.Make_Field_Entrable('ARBC_IMPR_NAME', FALSE);
		INTRFACE.Make_Field_Entrable('ENG_IMPR_NAME', FALSE);
	ELSIF V_COUNT = 0 THEN

		INTRFACE.Make_Field_Entrable('ARBC_IMPR_NAME', TRUE);
		INTRFACE.Make_Field_Entrable('ENG_IMPR_NAME', TRUE);
	END IF;

	IF :IMPORTERS.BUS_ID_TYPE_CD = 2 AND :IMPORTERS.IMPR_TYPE_CD = 1  THEN
		INTRFACE.Make_Field_Entrable('BUS_ID_BRNCH', TRUE);
	ELSE
		INTRFACE.Make_Field_Entrable('BUS_ID_BRNCH', FALSE);
	END IF;
END IF;
 GO_ITEM('IMPORTERS.IMPR_NBR');
		SET_ITEM_PROPERTY('IMPORTERS.CITY_CODE_OF_ID' ,REQUIRED,PROPERTY_FALSE);
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

#### IMPORTERS.L_CT_CITY_STATUS2 · KEY-LISTVAL

- Level: Item · Owner: `IMPORTERS.L_CT_CITY_STATUS2` · Execution hierarchy: default (Override)
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

#### IMPORTERS.L_CT_CITY_STATUS · KEY-LISTVAL

- Level: Item · Owner: `IMPORTERS.L_CT_CITY_STATUS` · Execution hierarchy: default (Override)
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

#### IMPORTERS.PORT_CD · WHEN-VALIDATE-ITEM

- Level: Item · Owner: `IMPORTERS.PORT_CD` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 31 total / 18 active (non-blank, non-comment)
- Built-ins: NAME_IN
- Program units (form): CGFK$CHK_IMPORTERS_IMP_SDP_FK
- Library / DB package calls: CGTE$OTHER_EXCEPTIONS, DES$FORM_ERRORS.MSGGETTEXT, DES$FORM_ERRORS.PUSH, DES$FORM_ERRORS.RAISE_FAILURE

```plsql
BEGIN
/*

-- NEW VER.

BEGIN
	IF :IMPORTERS.PORT_CD = 99 THEN
		STR.DISPALERT('لا يمكن إضافة مستورد لدي المصلحة - غير رمز الجمرك','ERROR');
		RAISE FORM_TRIGGER_FAILURE;
	END IF;
END;
*/
NULL;
END;
/* CGFK$VALDIDATE_FK_OVF */
/* Check that foreign key value exists in referenced table */
BEGIN
  IF (name_in('IMPORTERS.PORT_CD') IS NOT NULL) THEN
    BEGIN
      CGFK$CHK_IMPORTERS_IMP_SDP_FK(
        :IMPORTERS.PORT_NAME    /* MOD: Value in Item :IMPORTERS.PORT_NAME.                                                                                                                                                                   */
       ,:IMPORTERS.PORT_CD  );  /* IN : Value in Item :IMPORTERS.PORT_CD.                                                                                                                                                                     */
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(13, 'This <p1> does not exist', 'رمز الجمــــــــــــــرك' ), 'E', 'OFG', 13);
        Des$Form_errors.RAISE_FAILURE;
      WHEN OTHERS THEN
        CGTE$OTHER_EXCEPTIONS;
    END;
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

#### IMPORTERS.SUSPN_STATUS · KEY-LISTVAL

- Level: Item · Owner: `IMPORTERS.SUSPN_STATUS` · Execution hierarchy: default (Override)
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

#### IMPORTERS.STATUS_DESC · KEY-LISTVAL

- Level: Item · Owner: `IMPORTERS.STATUS_DESC` · Execution hierarchy: default (Override)
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

#### IMPORTERS.IMPR_TYPE_CD · KEY-LISTVAL

- Level: Item · Owner: `IMPORTERS.IMPR_TYPE_CD` · Execution hierarchy: default (Override)
- Lines: 96 total / 73 active (non-blank, non-comment)
- Built-ins: ADD_PARAMETER, CALL_FORM, CREATE_PARAMETER_LIST, DESTROY_PARAMETER_LIST, GET_BLOCK_PROPERTY, GET_ITEM_PROPERTY, GET_PARAMETER_LIST, GET_RECORD_PROPERTY, GO_ITEM, ID_NULL, RAISE FORM_TRIGGER_FAILURE
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
   pl_name VARCHAR2(100) := 'IMPR_TYPE_LOV';

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

  -- IF (:system.mode <> 'ENTER-QUERY'  ) THEN
	-- NEW VER.
	--IF :PARAMETER.P_CURR_PORT_CD = 99 THEN
	   --Add_Parameter(pl_id, 'STATUS', TEXT_PARAMETER, 0);
	--ELSE
	 --  Add_Parameter(pl_id, 'STATUS', TEXT_PARAMETER, 1);
	--END IF;
  -- END IF;


   CALL_FORM('LOV_Impr_Type.fmx',
              no_hide,
              no_replace,
              no_query_only,
              pl_id);

 	IF  :GLOBAL.IMPR_TYPE_CD IS NOT NULL THEN
		:IMPR_TYPE_CD := :GLOBAL.IMPR_TYPE_CD;
		:IMPR_TYPE_NAME := :GLOBAL.IMPR_TYPE_NAME;
		:BUS_ID_TYPE_CD := :GLOBAL.BUS_ID_TYPE_CD;
		:BUS_ID_TYPE_NAME := :GLOBAL.BUS_ID_TYPE_NAME;

:GLOBAL.VALID :=1;

IF :BUS_ID_TYPE_CD =2 THEN
GO_ITEM('COMM_RGSTRTN_TYPE');
ELSE
GO_ITEM('BUS_ID_EXPRD_DT');

END IF;
       ELSE
          :IMPR_TYPE_CD := NULL;
		:IMPR_TYPE_NAME := NULL;
		:BUS_ID_TYPE_CD := NULL;
		:BUS_ID_TYPE_NAME := NULL;


 	END IF;

   Destroy_Parameter_List(pl_id);
   ELSE
     ret := Str.DispAlert('Parameter list '||pl_name||' already EXISTS!','INFORMATION');
     RAISE Form_Trigger_Failure;
   END IF;
 END;
```

#### IMPORTERS.IMPR_TYPE_CD · WHEN-VALIDATE-ITEM

- Level: Item · Owner: `IMPORTERS.IMPR_TYPE_CD` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 298 total / 233 active (non-blank, non-comment)
- Built-ins: DO_KEY, NAME_IN, SET_ITEM_PROPERTY, RAISE FORM_TRIGGER_FAILURE
- Program units (form): CGFK$CHK_IMPORTERS_IMP_ITIDT_F
- Library / DB package calls: CGTE$OTHER_EXCEPTIONS, DES$FORM_ERRORS.PUSH, DES$FORM_ERRORS.RAISE_FAILURE, GNRL.GET_CUSTOMS_SETTING, GNRL.GET_SEQUENCE_VALUE, INTRFACE.MAKE_FIELD_ENTRABLE, STR.DISPALERT, STR.DISPARBMSG

```plsql
DECLARE
	IMPR_SEQ VARCHAR2(6);
	BUS_ID_COUNT NUMBER;
	V_COUNT NUMBER;
	RET NUMBER;
	V_COUNT_IMPR_TYPE_CD NUMBER;

BEGIN
	INTRFACE.Make_Field_Entrable('IMPORTERS.CTRY_CD' , TRUE);
	INTRFACE.Make_Field_Entrable('IMPORTERS.ADD_CTRY_CD' , FALSE);
	INTRFACE.Make_Field_Entrable('IMPORTERS.CITY_CODE_OF_ID' , FALSE);
	INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_BRNCH' , TRUE);
	INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID' , TRUE);
--	INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_TYPE_CD' , TRUE);
--




IF NVL(gnrl.get_customs_setting (:PARAMETER.P_CURR_PORT_CD,'STOP_IMPR_CR_TYPE',9),0) = 1 THEN

SELECT COUNT(*) INTO  V_COUNT_IMPR_TYPE_CD
FROM 	IMPR_TYPE_ID_TYPES
WHERE IMPR_TYPE_CD 	= :IMPORTERS.IMPR_TYPE_CD
AND   BUS_ID_TYPE_CD 	= 2
AND   STATUS 		= 1
;
	IF  V_COUNT_IMPR_TYPE_CD > 0  THEN
  		RET:=Str.DispArbMsg(9, 331,'INFORMATION');
  		RAISE FORM_TRIGGER_FAILURE;
	END IF;
END IF;

	IF :IMPORTERS.IMPR_TYPE_CD = 1 THEN
		:IMPORTERS.CTRY_CD := 100;
		:IMPORTERS.ADD_CTRY_CD := 100;
		INTRFACE.Make_Field_Entrable('IMPORTERS.CTRY_CD' , FALSE);
		INTRFACE.Make_Field_Entrable('IMPORTERS.ADD_CTRY_CD' , FALSE);
	ELSIF :IMPORTERS.IMPR_TYPE_CD = 2 THEN
		:IMPORTERS.CTRY_CD := 100;
		:IMPORTERS.ADD_CTRY_CD := 100;
		INTRFACE.Make_Field_Entrable('IMPORTERS.CTRY_CD' , FALSE);
		INTRFACE.Make_Field_Entrable('IMPORTERS.ADD_CTRY_CD' , FALSE);
		INTRFACE.Make_Field_Entrable('IMPORTERS.CITY_CODE_OF_ID' , FALSE);
		INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_BRNCH' , FALSE);

	ELSIF :IMPORTERS.IMPR_TYPE_CD = 4 THEN
		IF :IMPORTERS.BUS_ID_TYPE_CD = 5 THEN
			:IMPORTERS.CTRY_CD := 100;
			:IMPORTERS.ADD_CTRY_CD := 100;
		END IF;
		INTRFACE.Make_Field_Entrable('IMPORTERS.CITY_CODE_OF_ID' , FALSE);
		INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_BRNCH' , FALSE);

	ELSIF :IMPORTERS.IMPR_TYPE_CD = 5 THEN
		:IMPORTERS.CTRY_CD := 100;
		:IMPORTERS.ADD_CTRY_CD := 100;
		INTRFACE.Make_Field_Entrable('IMPORTERS.CTRY_CD' , FALSE);
		INTRFACE.Make_Field_Entrable('IMPORTERS.ADD_CTRY_CD' , FALSE);

	ELSIF :IMPORTERS.IMPR_TYPE_CD = 7 THEN
		INTRFACE.Make_Field_Entrable('IMPORTERS.CITY_CODE_OF_ID' , FALSE);
		INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_BRNCH' , FALSE);

	ELSIF :IMPORTERS.IMPR_TYPE_CD = 8 THEN
		:IMPORTERS.CTRY_CD := 100;
		:IMPORTERS.ADD_CTRY_CD := 100;
		INTRFACE.Make_Field_Entrable('IMPORTERS.CTRY_CD' , FALSE);
		INTRFACE.Make_Field_Entrable('IMPORTERS.ADD_CTRY_CD' , FALSE);

	ELSIF :IMPORTERS.IMPR_TYPE_CD = 9 THEN
		:IMPORTERS.CTRY_CD := 100;
		:IMPORTERS.ADD_CTRY_CD := 100;
		IF :IMPORTERS.BUS_ID_TYPE_CD IS NULL THEN
			:IMPORTERS.BUS_ID_TYPE_CD := 6;
		END IF;
		IF :IMPORTERS.BUS_ID_TYPE_CD = 6 THEN
			SELECT LPAD(--KING_IMPR_SEQ.NEXTVAL
			GNRL.GET_SEQUENCE_VALUE (:PARAMETER.P_CURR_PORT_CD,'KING_IMPR_SEQ')

			, 6,'0') INTO IMPR_SEQ FROM DUAL;
			:IMPORTERS.BUS_ID := 'ملكى'||IMPR_SEQ;
			INTRFACE.Make_Field_Entrable('IMPORTERS.CTRY_CD' , FALSE);
			INTRFACE.Make_Field_Entrable('IMPORTERS.ADD_CTRY_CD' , FALSE);
			INTRFACE.Make_Field_Entrable('IMPORTERS.CITY_CODE_OF_ID' , FALSE);
			INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_BRNCH' , FALSE);
			INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID' , FALSE);
		ELSE
			INTRFACE.Make_Field_Entrable('IMPORTERS.CTRY_CD' , TRUE);
			INTRFACE.Make_Field_Entrable('IMPORTERS.ADD_CTRY_CD' , TRUE);
			INTRFACE.Make_Field_Entrable('IMPORTERS.CITY_CODE_OF_ID' , TRUE);

			INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID' , TRUE);
			INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_BRNCH' , FALSE);
		END IF;
	ELSIF :IMPORTERS.IMPR_TYPE_CD = 10 THEN
			INTRFACE.Make_Field_Entrable('IMPORTERS.CITY_CODE_OF_ID' , FALSE);
			INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_BRNCH' , FALSE);
	ELSIF :IMPORTERS.IMPR_TYPE_CD = 11 THEN
			:IMPORTERS.CTRY_CD := 100;
			:IMPORTERS.ADD_CTRY_CD := 100;
			INTRFACE.Make_Field_Entrable('IMPORTERS.CTRY_CD' , FALSE);
			INTRFACE.Make_Field_Entrable('IMPORTERS.ADD_CTRY_CD' , FALSE);
			INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_BRNCH' , FALSE);
	ELSIF :IMPORTERS.IMPR_TYPE_CD = 12 THEN
			INTRFACE.Make_Field_Entrable('IMPORTERS.CITY_CODE_OF_ID' , FALSE);
			IF :CTRY_CD IS NOT NULL THEN
				SELECT COUNT(*)
				INTO	 V_COUNT
				FROM	 CTRY_GROUP_DETAILS
				WHERE  CTRY_CD = :CTRY_CD
				AND	 CTRY_GRP_STAT = 1
				AND	 CTRY_GRP_NBR = 1
				;

				IF V_COUNT = 0 THEN
					STR.DISPALERT('لابد أن تكون دولة المستورد الخليجي تابعة لدول مجلس التعاون','ERROR');
					RAISE FORM_TRIGGER_FAILURE;
				END IF;

			END IF;

/*
	ELSIF :IMPORTERS.IMPR_TYPE_CD IN (13, 14) THEN

			SELECT NVL((MAX(BUS_ID) + 1) , 1)
			INTO 	:IMPORTERS.BUS_ID
			FROM 	IMPORTERS
			WHERE PORT_CD = :IMPORTERS.PORT_CD
			AND		IMPR_TYPE_CD IN (13, 14)
			;
*/
	ELSIF :IMPORTERS.IMPR_TYPE_CD IN (16,17,18,20) THEN
--	 	:IMPORTERS.BUS_ID := gnrl.get_customs_seq ('IMPORTERS_SEQ');

   -- SELECT IMPORTERS_SEQ.NEXTVAL INTO :IMPORTERS.BUS_ID FROM DUAL;
 SELECT GNRL.GET_SEQUENCE_VALUE(:PARAMETER.P_CURR_PORT_CD,'IMPORTERS_SEQ') INTO :IMPORTERS.BUS_ID FROM DUAL;
			IF :IMPORTERS.BUS_ID IS NULL THEN
				:IMPORTERS.BUS_ID := 1;
			END IF;

			:IMPORTERS.CTRY_CD := 100;
			:IMPORTERS.ADD_CTRY_CD := 100;
			INTRFACE.Make_Field_Entrable('IMPORTERS.CTRY_CD' , FALSE);
			INTRFACE.Make_Field_Entrable('IMPORTERS.ADD_CTRY_CD' , FALSE);
			INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID' , FALSE);
			INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_BRNCH' , FALSE);
			INTRFACE.Make_Field_Entrable('IMPORTERS.CITY_CODE_OF_ID' , FALSE);
	END IF;

IF :IMPORTERS.IMPR_TYPE_CD = '14' THEN
:IMPORTERS.CTRY_CD := 100;
:IMPORTERS.ADD_CTRY_CD := 100;
   INTRFACE.Make_Field_Entrable('IMPORTERS.CTRY_CD' , FALSE);
   INTRFACE.Make_Field_Entrable('IMPORTERS.ADD_CTRY_CD' , FALSE);
END IF;

IF :IMPORTERS.CTRY_CD IS NOT NULL THEN
	SELECT CRTY_ARBC_NAME
	INTO :CRTY_ARBC_NAME
	FROM COUNTRIES
	WHERE CTRY_CD = :IMPORTERS.CTRY_CD;
END IF;

IF :IMPORTERS.ADD_CTRY_CD IS NOT NULL THEN
	SELECT CRTY_ARBC_NAME
	INTO :ADD_CRTY_ARBC_NAME
	FROM COUNTRIES
	WHERE CTRY_CD = :IMPORTERS.ADD_CTRY_CD;
END IF;



-----------------------------
-- UPDATE BY ANAS --
-- 25-5-2005 --
-- DECLARE THIS GLOBAL VARIABLE FOR I KNOW I USED LOV OR NOT IN THIS TEXT ITEM )
IF :GLOBAL.VALID  = 0 THEN
IF :IMPORTERS.IMPR_TYPE_CD IS NOT NULL THEN

SELECT COUNT(*)
INTO BUS_ID_COUNT
FROM IMPR_TYPE_ID_TYPES
WHERE IMPR_TYPE_CD = :IMPORTERS.IMPR_TYPE_CD;
 --AND  STATUS = 1 ;

IF BUS_ID_COUNT = 1 THEN
	SELECT IT.BUS_ID_TYPE_CD, IDT.BUS_ID_TYPE_NAME
	INTO :IMPORTERS.BUS_ID_TYPE_CD, :IMPORTERS.BUS_ID_TYPE_NAME
	FROM IMPR_TYPE_ID_TYPES IT, BUS_ID_TYPES IDT
	WHERE IT.IMPR_TYPE_CD = :IMPORTERS.IMPR_TYPE_CD
     --  AND IT.STATUS=1
	AND IT.BUS_ID_TYPE_CD = IDT.BUS_ID_TYPE_CD;
	INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_TYPE_CD' , FALSE);
ELSIF BUS_ID_COUNT > 1 THEN

 DO_KEY('LIST_VALUES ');
ELSE
  :IMPORTERS.IMPR_TYPE_CD:=NULL;
  RET:=Str.DispArbMsg(2, 170,'ERROR');
  RAISE FORM_TRIGGER_FAILURE;

END IF;
END IF;
END IF;
:GLOBAL.VALID:=0;

IF :IMPORTERS.IMPR_TYPE_CD IS NOT NULL THEN

	SELECT 	IMPR_TYPE_NAME
	INTO		:IMPORTERS.IMPR_TYPE_NAME
	FROM		IMPR_TYPES
	WHERE		IMPR_TYPE_CD = :IMPORTERS.IMPR_TYPE_CD
	;
END IF;

IF :IMPORTERS.BUS_ID_TYPE_CD  = 2  AND :IMPORTERS.IMPR_TYPE_CD !=12
	 AND :GLOBAL.ALLOW_MCI = 1 THEN

    INTRFACE.Make_Field_Entrable('IMPORTERS.COMM_RGSTRTN_TYPE' , TRUE);
    SET_ITEM_PROPERTY('IMPORTERS.COMM_RGSTRTN_TYPE',REQUIRED,PROPERTY_TRUE);
    INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_POB_NBR' , FALSE);
    INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_ZIP_CD' , FALSE);
   -- INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_TEL_NBR' , FALSE);--
    INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_FAX_NBR' , FALSE);
    INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_TELEX_NBR' , FALSE);
    --INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_EXPRD_DT' , FALSE);--
    --INTRFACE.Make_Field_Entrable('IMPORTERS.ARBC_IMPR_NAME' , FALSE);--

 ELSIF :IMPORTERS.BUS_ID_TYPE_CD  = 2  AND :IMPORTERS.IMPR_TYPE_CD !=12 THEN
    INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_EXPRD_DT' , TRUE);
    INTRFACE.Make_Field_Entrable('IMPORTERS.COMM_RGSTRTN_TYPE' , TRUE);
    SET_ITEM_PROPERTY('IMPORTERS.COMM_RGSTRTN_TYPE',REQUIRED,PROPERTY_TRUE);
    INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_POB_NBR' , TRUE);
    INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_ZIP_CD' , TRUE);
    INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_TEL_NBR' , TRUE);
    INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_FAX_NBR' , TRUE);
    INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_TELEX_NBR' , TRUE);
    INTRFACE.Make_Field_Entrable('IMPORTERS.ARBC_IMPR_NAME' , TRUE);
    INTRFACE.Make_Field_Entrable('IMPORTERS.COMM_RGSTRTN_TYPE' , TRUE);
    SET_ITEM_PROPERTY('IMPORTERS.COMM_RGSTRTN_TYPE',REQUIRED,PROPERTY_TRUE);

 ELSIF :IMPORTERS.BUS_ID_TYPE_CD  = 2  AND :IMPORTERS.IMPR_TYPE_CD =12 THEN
    INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_EXPRD_DT' , TRUE);
    INTRFACE.Make_Field_Entrable('IMPORTERS.COMM_RGSTRTN_TYPE' , TRUE);
    SET_ITEM_PROPERTY('IMPORTERS.COMM_RGSTRTN_TYPE',REQUIRED,PROPERTY_TRUE);
    INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_POB_NBR' , TRUE);
    INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_ZIP_CD' , TRUE);
    INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_TEL_NBR' , TRUE);
    INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_FAX_NBR' , TRUE);
    INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_TELEX_NBR' , TRUE);
    INTRFACE.Make_Field_Entrable('IMPORTERS.ARBC_IMPR_NAME' , TRUE);
    INTRFACE.Make_Field_Entrable('IMPORTERS.COMM_RGSTRTN_TYPE' , TRUE);
    SET_ITEM_PROPERTY('IMPORTERS.COMM_RGSTRTN_TYPE',REQUIRED,PROPERTY_TRUE);

 ELSE
    INTRFACE.Make_Field_Entrable('IMPORTERS.COMM_RGSTRTN_TYPE' , FALSE);
    SET_ITEM_PROPERTY('IMPORTERS.COMM_RGSTRTN_TYPE',REQUIRED,PROPERTY_FALSE);
    INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_EXPRD_DT' , TRUE);

    INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_POB_NBR' , TRUE);
    INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_ZIP_CD' , TRUE);
    INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_TEL_NBR' , TRUE);
    INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_FAX_NBR' , TRUE);
    INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_TELEX_NBR' , TRUE);
    INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_EXPRD_DT' , TRUE);
    INTRFACE.Make_Field_Entrable('IMPORTERS.ARBC_IMPR_NAME' , TRUE);
 END IF;
END;


 IF :IMPR_TYPE_CD = 21 AND :BUS_ID_TYPE_CD = 19 THEN

 	 INTRFACE.Make_Field_Entrable('IMPORTERS.ADD_CTRY_CD' , TRUE);
 ELSE
 	 INTRFACE.Make_Field_Entrable('IMPORTERS.ADD_CTRY_CD' , FALSE);
 END IF;
/* CGFK$VALDIDATE_FK_OVF */
/* Check that foreign key value exists in referenced table */
BEGIN
  IF (name_in('IMPORTERS.IMPR_TYPE_CD') IS NOT NULL AND name_in('IMPORTERS.BUS_ID_TYPE_CD') IS NOT NULL) THEN
    BEGIN
      CGFK$CHK_IMPORTERS_IMP_ITIDT_F(
        :IMPORTERS.BUS_ID_TYPE_NAME    /* MOD: Value in Item :IMPORTERS.BUS_ID_TYPE_NAME.                                                                                                                                                     */
       ,:IMPORTERS.IMPR_TYPE_NAME      /* MOD: Value in Item :IMPORTERS.IMPR_TYPE_NAME.                                                                                                                                                       */
       ,:IMPORTERS.STATUS              /* MOD: Value in Item :IMPORTERS.STATUS.                                                                                                                                                               */
       ,:IMPORTERS.ITIDT_NOTE          /* MOD: Value in Item :IMPORTERS.ITIDT_NOTE.                                                                                                                                                           */
       ,:IMPORTERS.IMPR_TYPE_CD        /* IN : Value in Item :IMPORTERS.IMPR_TYPE_CD.                                                                                                                                                         */
       ,:IMPORTERS.BUS_ID_TYPE_CD  );  /* IN : Value in Item :IMPORTERS.BUS_ID_TYPE_CD.                                                                                                                                                       */
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        Des$Form_errors.PUSH('رمز النشاط التجاري غير صحيح - أعد إدخال البيانات', 'E', 'OFG', 0);
        Des$Form_errors.RAISE_FAILURE;
      WHEN OTHERS THEN
        CGTE$OTHER_EXCEPTIONS;
    END;
  END IF;
END;
```

#### IMPORTERS.IMPR_TYPE_CD · KEY-NEXT-ITEM

- Level: Item · Owner: `IMPORTERS.IMPR_TYPE_CD` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 7 total / 7 active (non-blank, non-comment)
- Built-ins: GO_ITEM
- Program units (form): –
- Library / DB package calls: –

```plsql
BEGIN
	IF :BUS_ID_TYPE_CD =2 THEN
		GO_ITEM('COMM_RGSTRTN_TYPE');
	ELSE
		GO_ITEM('BUS_ID_EXPRD_DT');
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

#### IMPORTERS.BUS_ID_EXPRD_DT · KEY-LISTVAL

- Level: Item · Owner: `IMPORTERS.BUS_ID_EXPRD_DT` · Execution hierarchy: default (Override)
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

#### IMPORTERS.BUS_ID_EXPRD_DT · KEY-F4

- Level: Item · Owner: `IMPORTERS.BUS_ID_EXPRD_DT` · Execution hierarchy: default (Override)
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

#### IMPORTERS.BUS_ID_EXPRD_DT · WHEN-VALIDATE-ITEM

- Level: Item · Owner: `IMPORTERS.BUS_ID_EXPRD_DT` · Execution hierarchy: default (Override)
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

#### IMPORTERS.BUS_ID_EXPRD_DT · WHEN-NEW-ITEM-INSTANCE

- Level: Item · Owner: `IMPORTERS.BUS_ID_EXPRD_DT` · Execution hierarchy: default (Override) · Fire in query: false
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

#### IMPORTERS.BUS_ID_TYPE_CD · KEY-LISTVAL

- Level: Item · Owner: `IMPORTERS.BUS_ID_TYPE_CD` · Execution hierarchy: default (Override)
- Lines: 82 total / 63 active (non-blank, non-comment)
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

   Add_Parameter(pl_id, 'WINDOW_TITLE', TEXT_PARAMETER, 'المتاحة قائمة أنواع الأنشطة التجارية');
   Add_Parameter(pl_id, 'IMPR_TYPE_CD', TEXT_PARAMETER, :IMPORTERs.IMPR_TYPE_CD);

  -- IF (:system.mode <> 'ENTER-QUERY'  ) THEN
	-- NEW VER.
	--IF :PARAMETER.P_CURR_PORT_CD = 99 THEN
	 --  Add_Parameter(pl_id, 'STATUS', TEXT_PARAMETER, 0);
	--ELSE
	--   Add_Parameter(pl_id, 'STATUS', TEXT_PARAMETER, 1);
	--END IF;
  -- END IF;


   CALL_FORM('LOV_Impr_Type.fmx',
              no_hide,
              no_replace,
              no_query_only,
              pl_id);

 	IF  :GLOBAL.IMPR_TYPE_CD IS NOT NULL THEN
		:BUS_ID_TYPE_CD := :GLOBAL.BUS_ID_TYPE_CD;
		:BUS_ID_TYPE_NAME := :GLOBAL.BUS_ID_TYPE_NAME;
		:IMPR_TYPE_CD := :GLOBAL.IMPR_TYPE_CD;
		:IMPR_TYPE_NAME := :GLOBAL.IMPR_TYPE_NAME;

 	END IF;

   Destroy_Parameter_List(pl_id);
   ELSE
     ret := Str.DispAlert('Parameter list '||pl_name||' already EXISTS!','INFORMATION');
     RAISE Form_Trigger_Failure;
   END IF;
 END;
```

#### IMPORTERS.BUS_ID_TYPE_CD · WHEN-VALIDATE-ITEM

- Level: Item · Owner: `IMPORTERS.BUS_ID_TYPE_CD` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 15 total / 13 active (non-blank, non-comment)
- Built-ins: RAISE FORM_TRIGGER_FAILURE
- Program units (form): –
- Library / DB package calls: STR.DISPARBMSG

```plsql
DECLARE
	RET NUMBER;
	V_IMPR_NBR NUMBER;
	V_COUNT NUMBER;
BEGIN
	IF 	(:importers.impr_type_cd = 4  AND :importers.ctry_cd = 100 AND :importers.bus_id_type_cd <> 5)
		OR
		(:importers.impr_type_cd = 4  AND :importers.ctry_cd <> 100 AND :importers.bus_id_type_cd = 5)
	THEN
		ret := Str.DispArbMsg(9, 170,'ERROR');
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

#### IMPORTERS.COMM_RGSTRTN_TYPE · KEY-LISTVAL

- Level: Item · Owner: `IMPORTERS.COMM_RGSTRTN_TYPE` · Execution hierarchy: default (Override)
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

#### IMPORTERS.COMM_RGSTRTN_TYPE · WHEN-LIST-CHANGED

- Level: Item · Owner: `IMPORTERS.COMM_RGSTRTN_TYPE` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 12 total / 8 active (non-blank, non-comment)
- Built-ins: –
- Program units (form): –
- Library / DB package calls: INTRFACE.MAKE_FIELD_ENTRABLE

```plsql
-- UPDATE BY ANAS --
--    07-03-2006    --

BEGIN
IF :IMPORTERS.COMM_RGSTRTN_TYPE = 1 THEN
      :IMPORTERS.BUS_ID_BRNCH := NULL;
	INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_BRNCH' , FALSE);
ELSIF :IMPORTERS.COMM_RGSTRTN_TYPE = 2 THEN
	INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_BRNCH' , TRUE);

END IF;
END;
```

#### IMPORTERS.CTRY_CD · KEY-LISTVAL

- Level: Item · Owner: `IMPORTERS.CTRY_CD` · Execution hierarchy: default (Override)
- Lines: 45 total / 39 active (non-blank, non-comment)
- Built-ins: GET_BLOCK_PROPERTY, GET_ITEM_PROPERTY, GET_RECORD_PROPERTY, RAISE FORM_TRIGGER_FAILURE
- Program units (form): CALL_LOV_COUNTRIES, CALL_LOV_COUN_GULF
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
IF (:IMPR_TYPE_CD = 4 AND :BUS_ID_TYPE_CD = 16) OR :IMPR_TYPE_CD = 12 THEN

CALL_LOV_COUN_GULF ;

ELSE

CALL_LOV_COUNTRIES;
END IF;

END;
```

#### IMPORTERS.CTRY_CD · WHEN-VALIDATE-ITEM

- Level: Item · Owner: `IMPORTERS.CTRY_CD` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 37 total / 33 active (non-blank, non-comment)
- Built-ins: NAME_IN, RAISE FORM_TRIGGER_FAILURE
- Program units (form): CGFK$CHK_IMPORTERS_IMP_CTRY_FK
- Library / DB package calls: CGTE$OTHER_EXCEPTIONS, DES$FORM_ERRORS.PUSH, DES$FORM_ERRORS.RAISE_FAILURE, STR.DISPALERT

```plsql
DECLARE
	V_COUNT NUMBER;
BEGIN
IF :IMPR_TYPE_CD = 12 THEN
	SELECT COUNT(*)
	INTO	 V_COUNT
	FROM	 CTRY_GROUP_DETAILS
	WHERE  CTRY_CD = :CTRY_CD
	AND	 CTRY_GRP_STAT = 1
	AND	 CTRY_GRP_NBR = 1
	;


	IF V_COUNT = 0 THEN
		STR.DISPALERT('لابد أن تكون دولة المستورد الخليجي تابعة لدول مجلس التعاون','ERROR');
		RAISE FORM_TRIGGER_FAILURE;
	END IF;
END IF;
END;
/* CGFK$VALDIDATE_FK_OVF */
/* Check that foreign key value exists in referenced table */
BEGIN
  IF (name_in('IMPORTERS.CTRY_CD') IS NOT NULL) THEN
    BEGIN
      CGFK$CHK_IMPORTERS_IMP_CTRY_FK(
        :IMPORTERS.CTRY_CTRY_STATUS    /* MOD: Value in Item :IMPORTERS.CTRY_CTRY_STATUS.                                                                                                                                                     */
       ,:IMPORTERS.CRTY_ARBC_NAME      /* MOD: Value in Item :IMPORTERS.CRTY_ARBC_NAME.                                                                                                                                                       */
       ,:IMPORTERS.CTRY_CD         );  /* IN : Value in Item :IMPORTERS.CTRY_CD.                                                                                                                                                              */
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        Des$Form_errors.PUSH('رمز الدولة غير صحيح - أعد ادخال البيانات', 'E', 'OFG', 0);
        Des$Form_errors.RAISE_FAILURE;
      WHEN OTHERS THEN
        CGTE$OTHER_EXCEPTIONS;
    END;
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
   Add_Parameter(pl_id, 'CTRY_CD', TEXT_PARAMETER, :IMPORTERS.CTRY_CD);




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
     ret := Str.DispAlert('Parameter list '||'LOV_CITIES'||' already EXISTS!','INFORMATION');
     RAISE Form_Trigger_Failure;
   END IF;

 END;
```

#### IMPORTERS.CITY_CODE_OF_ID · WHEN-VALIDATE-ITEM

- Level: Item · Owner: `IMPORTERS.CITY_CODE_OF_ID` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 113 total / 91 active (non-blank, non-comment)
- Built-ins: NAME_IN, RAISE FORM_TRIGGER_FAILURE
- Program units (form): CGFK$CHK_IMPORTERS_IMP_BUS_ID_, CGSF$CLRLU_IMPORTERS_IMP_BUS_I
- Library / DB package calls: CGTE$OTHER_EXCEPTIONS, DES$FORM_ERRORS.PUSH, STR.DISPALERT, STR.DISPARBMSG, STR_DB.GETARBMSG

```plsql
DECLARE
V_BUS_ID VARCHAR2(6);
V_ALL_BUS_ID VARCHAR2(10);
V_ID_MINS_COMM_CD VARCHAR2(4);
V_USER_BUS_ID VARCHAR2(4);

Alert_txt   VARCHAR2(80);
al_button NUMBER;
SYS_ID NUMBER;
MSG_CD NUMBER;

BEGIN
IF :impr_type_cd <> 20 THEN
IF :IMPORTERS.CITY_CODE_OF_ID IS NOT NULL THEN
	:IMPORTERS.CTRY_CD_OF_ID := 100;
ELSE
	:IMPORTERS.CTRY_CD_OF_ID := NULL;
END IF;
END IF;
IF :System.TRIGGER_ITEM = :System.CURSOR_ITEM THEN

/*
   IF :CITY_CODE_OF_ID IS NULL THEN
	STR.DISPALERT('يجب تحديد مدينة مصدر الهوية','ERROR');
	RAISE FORM_TRIGGER_FAILURE;
   END IF;
*/

   IF :IMPORTERS.BUS_ID_TYPE_CD = 2 THEN
	IF LENGTH(:IMPORTERS.BUS_ID) <= 6 THEN
		SELECT LPAD(:IMPORTERS.BUS_ID, 6,'0') INTO V_BUS_ID FROM dual;

		SELECT MINS_COMM_CD
		INTO :IMPORTERS.ID_MINS_COMM_CD
		FROM CITIES
		WHERE  CITY_CD = :IMPORTERS.CITY_CODE_OF_ID
		AND	 CTRY_CD = :IMPORTERS.CTRY_CD_OF_ID;

		SELECT LPAD(TO_CHAR(:IMPORTERS.ID_MINS_COMM_CD), 4,'0') INTO V_ID_MINS_COMM_CD FROM dual;

		V_ALL_BUS_ID := CONCAT(V_ID_MINS_COMM_CD,V_BUS_ID);
		SYS_ID := 9;
		MSG_CD := 120;
		Alert_txt := STR_DB.GetArbMsg(SYS_ID, MSG_CD);
		IF Alert_txt = '-1' THEN
			Alert_txt :='خطأ فى رقم الرسالة '||sys_Id||'-'||Msg_Cd||'إتصل بالمسانده الفنيه';
			al_button := STR.DispAlert(Alert_Txt, 'ERROR');
		ELSE
			Alert_Txt :=sys_Id||'-'||Msg_Cd||' : '||Alert_Txt||' '||V_ALL_BUS_ID;
			al_button := STR.DispAlert(Alert_Txt, 'CONFIRM');
			IF al_button = alert_button1 THEN
				:importers.BUS_ID := V_ALL_BUS_ID;
			ELSIF al_button = alert_button2 THEN
					RAISE Form_trigger_failure;
			END IF;
		END IF;



	ELSIF LENGTH(:IMPORTERS.BUS_ID) = 10 THEN
		V_USER_BUS_ID := SUBSTR(:IMPORTERS.BUS_ID, 1, 4);
		IF TO_NUMBER(V_USER_BUS_ID) <> :IMPORTERS.ID_MINS_COMM_CD THEN
			al_button := STR.DispArbMsg(9, 130, 'ERROR');
			RAISE Form_trigger_failure;
		END IF;
	END IF;
   END IF;
END IF;
                    BEGIN
                       SELECT city_arb_name
                         INTO :importers.id_city_name
                         FROM cities
                        WHERE city_cd = :city_code_of_id AND ctry_cd = :CTRY_CD_OF_ID;
                    EXCEPTION
                       WHEN OTHERS THEN NULL;
                    END;

END;
/* CGFK$WVI_CLR_DEPS_OVF */
/* Clear dependent items, if this item is null. */
BEGIN
  IF (name_in('IMPORTERS.CITY_CODE_OF_ID') IS NULL AND name_in('IMPORTERS.CTRY_CD_OF_ID') IS NULL) THEN
    IF (:SYSTEM.RECORD_STATUS = 'NEW') THEN
      RETURN;
    END IF;
    BEGIN
      CGSF$CLRLU_IMPORTERS_IMP_BUS_I;
    EXCEPTION
      WHEN OTHERS THEN
        CGTE$OTHER_EXCEPTIONS;
    END;
  END IF;
END;

/* CGFK$VALDIDATE_FK_OVF */
/* Check that foreign key value exists in referenced table */
BEGIN
  IF (name_in('IMPORTERS.CITY_CODE_OF_ID') IS NOT NULL AND name_in('IMPORTERS.CTRY_CD_OF_ID') IS NOT NULL) THEN
    BEGIN
      CGFK$CHK_IMPORTERS_IMP_BUS_ID_(
        :IMPORTERS.ID_MINS_COMM_CD      /* MOD: Value in Item :IMPORTERS.ID_MINS_COMM_CD.                                                                                                                                                     */
       ,:IMPORTERS.ID_CITY_NAME         /* MOD: Value in Item :IMPORTERS.ID_CITY_NAME.                                                                                                                                                        */
       ,:IMPORTERS.L_CT_CITY_STATUS2    /* MOD: Value in Item :IMPORTERS.L_CT_CITY_STATUS2.                                                                                                                                                   */
       ,:IMPORTERS.CTRY_CD_OF_ID        /* IN : Value in Item :IMPORTERS.CTRY_CD_OF_ID.                                                                                                                                                       */
       ,:IMPORTERS.CITY_CODE_OF_ID  );  /* IN : Value in Item :IMPORTERS.CITY_CODE_OF_ID.                                                                                                                                                     */
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        Des$Form_errors.PUSH('خطأ في رمز مدينة مصدر الرقم الإستدلالي', 'W', 'OFG', 0);
      WHEN OTHERS THEN
        CGTE$OTHER_EXCEPTIONS;
    END;
  END IF;
END;
```

#### IMPORTERS.CITY_CODE_OF_ID · WHEN-NEW-ITEM-INSTANCE

- Level: Item · Owner: `IMPORTERS.CITY_CODE_OF_ID` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 10 total / 9 active (non-blank, non-comment)
- Built-ins: –
- Program units (form): –
- Library / DB package calls: –

```plsql
BEGIN

IF :IMPORTERS.CITY_CODE_OF_ID IS NULL THEN
IF :impr_type_cd = 20 THEN
	:IMPORTERS.CTRY_CD_OF_ID := :ctry_cd;
ELSE
	:IMPORTERS.CTRY_CD_OF_ID := 100;
END IF;
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

#### IMPORTERS.NATIONAL_NBR · KEY-LISTVAL

- Level: Item · Owner: `IMPORTERS.NATIONAL_NBR` · Execution hierarchy: default (Override)
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

#### IMPORTERS.NATIONAL_NBR · WHEN-VALIDATE-ITEM

- Level: Item · Owner: `IMPORTERS.NATIONAL_NBR` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 35 total / 29 active (non-blank, non-comment)
- Built-ins: GET_RECORD_PROPERTY, RAISE FORM_TRIGGER_FAILURE
- Program units (form): GET_BRANCH_CR_DATA, GET_MAIN_CR_DATA
- Library / DB package calls: STR.DISPALERT

```plsql
DECLARE
V_BUS_ID VARCHAR2(6);
V_ALL_BUS_ID VARCHAR2(10);
V_ID_MINS_COMM_CD VARCHAR2(4);
V_USER_BUS_ID VARCHAR2(4);
V_COUNT NUMBER;
Alert_txt   VARCHAR2(100);
al_button NUMBER;
SYS_ID NUMBER;
MSG_CD NUMBER;
V_IMPR_NBR NUMBER;
BEGIN


IF :NATIONAL_NBR IS NOT NULL THEN
      IF SUBSTR(:IMPORTERS.NATIONAL_NBR ,1,1) <> '7' THEN
        STR.DISPALERT ('يجب أن يبدأ رقم المنشأة برقم "7"','INFORMATION');
           	RAISE FORM_TRIGGER_FAILURE;
      END IF;


   IF GET_RECORD_PROPERTY (:SYSTEM.cursor_record,:SYSTEM.cursor_block,status) IN ('NEW', 'INSERT') AND
		:importers.IMPR_TYPE_CD IN ( 1,3,5,6,19 ) AND :importers.bus_id_type_cd = 2
		 AND :GLOBAL.ALLOW_MCI = 1
   THEN
      IF :importers.comm_rgstrtn_type = 1 THEN
         get_main_cr_data;
      ELSIF :importers.comm_rgstrtn_type = 2 THEN
         get_branch_cr_data;
      END IF;
   END IF;

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

#### IMPORTERS.BUS_ID · WHEN-VALIDATE-ITEM

- Level: Item · Owner: `IMPORTERS.BUS_ID` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 228 total / 165 active (non-blank, non-comment)
- Built-ins: SET_ITEM_PROPERTY, RAISE FORM_TRIGGER_FAILURE
- Program units (form): –
- Library / DB package calls: INTRFACE.MAKE_FIELD_ENTRABLE, LIB_USR.GNRL.GET_CUSTOMS_SETTING, STR.DISPALERT, STR.DISPARBMSG, STR_DB.GETARBMSG

```plsql
DECLARE
V_BUS_ID VARCHAR2(6);
V_ALL_BUS_ID VARCHAR2(10);
V_ID_MINS_COMM_CD VARCHAR2(4);
V_USER_BUS_ID VARCHAR2(4);
V_COUNT NUMBER;
Alert_txt   VARCHAR2(100);
al_button NUMBER;
SYS_ID NUMBER;
MSG_CD NUMBER;
V_IMPR_NBR NUMBER;
BEGIN

IF (:IMPR_TYPE_CD IN (1,3,5,6,8,19)  AND LENGTH(:IMPORTERS.BUS_ID) != 10)
	THEN
       	STR.DISPALERT(' يجب أن يكون الرقم الاستدلالي مكونا من عشرة ارقام ','ERROR');
           	RAISE FORM_TRIGGER_FAILURE;
      END IF;

IF :IMPR_TYPE_CD  in (13, 14) THEN
   IF SUBSTR(:IMPORTERS.BUS_ID,1,3) <> '700' THEN
    STR.DISPALERT ('يجب أن يبدأ الرقم الإستدلالي برقم "700"','INFORMATION');
           	RAISE FORM_TRIGGER_FAILURE;
      END IF;
END IF;

  IF :BUS_ID_TYPE_CD IN( 5,3) AND :IMPR_TYPE_CD = 4 THEN
  	:IMPORTERS.BUS_ID := LTRIM(RTRIM(:IMPORTERS.BUS_ID));
      IF LENGTH(:IMPORTERS.BUS_ID) != 10 THEN
       	STR.DISPALERT(' يجب أن يكون الرقم الاستدلالي مكونا من عشرة ارقام ','ERROR');
           	RAISE FORM_TRIGGER_FAILURE;
      END IF;
END IF;


IF :IMPORTERS.BUS_ID_TYPE_CD = 2 AND :IMPORTERS.IMPR_TYPE_CD != 12  THEN
	IF NOT (LENGTH(:IMPORTERS.BUS_ID) <= 6 OR LENGTH(:IMPORTERS.BUS_ID) = 10) THEN
		RAISE form_trigger_failure;
	END IF;


	IF :IMPORTERS.CITY_CODE_OF_ID IS NOT NULL THEN
		IF LENGTH(:IMPORTERS.BUS_ID) <= 6 THEN

			SELECT LPAD(:IMPORTERS.BUS_ID, 6,'0') INTO V_BUS_ID FROM dual;

			SELECT MINS_COMM_CD
			INTO :IMPORTERS.ID_MINS_COMM_CD
			FROM CITIES
			WHERE  CITY_CD = :IMPORTERS.CITY_CODE_OF_ID
			AND	 CTRY_CD = :IMPORTERS.CTRY_CD_OF_ID;

			SELECT LPAD(TO_CHAR(:IMPORTERS.ID_MINS_COMM_CD), 4,'0') INTO V_ID_MINS_COMM_CD FROM dual;

			V_ALL_BUS_ID := CONCAT(V_ID_MINS_COMM_CD,V_BUS_ID);
			SYS_ID := 9;
			MSG_CD := 120;
			Alert_txt := STR_DB.GetArbMsg(SYS_ID, MSG_CD);
			IF Alert_txt = '-1' THEN
  				Alert_txt :='خطأ فى رقم الرسالة '||sys_Id||'-'||Msg_Cd||'إتصل بالمسانده الفنيه';
				al_button := STR.DispAlert(Alert_Txt, 'ERROR');
			ELSE
				Alert_Txt :=sys_Id||'-'||Msg_Cd||' : '||Alert_Txt||' '||V_ALL_BUS_ID;
				al_button := STR.DispAlert(Alert_Txt, 'ERROR');
				IF al_button = alert_button1 THEN
					:importers.BUS_ID := V_ALL_BUS_ID;
				ELSIF al_button = alert_button2 THEN
					RAISE Form_trigger_failure;
				END IF;
			END IF;

		ELSIF LENGTH(:IMPORTERS.BUS_ID) = 10 THEN
			V_USER_BUS_ID := SUBSTR(:IMPORTERS.BUS_ID, 1, 4);
			IF TO_NUMBER(V_USER_BUS_ID) <> :IMPORTERS.ID_MINS_COMM_CD THEN
				al_button := STR.DispArbMsg(9, 130, 'ERROR');
				RAISE Form_trigger_failure;
			END IF;

		END IF;

	END IF;
ELSIF :IMPORTERS.BUS_ID_TYPE_CD <> 2 THEN
	IF :IMPORTERS.BUS_ID_TYPE_CD IS NOT NULL THEN
		SELECT COUNT(*)
		INTO	V_COUNT
		FROM IMPORTERS
		WHERE PORT_CD = :IMPORTERS.PORT_CD
		AND	BUS_ID_TYPE_CD = :IMPORTERS.BUS_ID_TYPE_CD
		AND 	BUS_ID  = :IMPORTERS.BUS_ID
		AND 	BUS_ID_BRNCH IS NULL
		AND		((:IMPORTERS.IMPR_NBR IS NULL) OR (:IMPORTERS.IMPR_NBR IS NOT NULL AND IMPR_NBR <> :IMPORTERS.IMPR_NBR))
		;
		IF V_COUNT > 0 THEN
			SELECT MAX(IMPR_NBR)
			INTO	V_IMPR_NBR
			FROM IMPORTERS
			WHERE PORT_CD = :IMPORTERS.PORT_CD
			AND	BUS_ID_TYPE_CD = :IMPORTERS.BUS_ID_TYPE_CD
			AND 	BUS_ID  = :IMPORTERS.BUS_ID
			AND 	BUS_ID_BRNCH IS NULL
			AND		((:IMPORTERS.IMPR_NBR IS NULL) OR (:IMPORTERS.IMPR_NBR IS NOT NULL AND IMPR_NBR <> :IMPORTERS.IMPR_NBR))
			;

			STR.DISPALERT(' لا يمكن تكرار الرقم الإستدلالي - الرقم الإستدلالي مستخدم لمستورد آخر مسلسله بالجمرك رقم : '||V_IMPR_NBR,'ERROR');
			RAISE FORM_TRIGGER_FAILURE;
		END IF;
	END IF;
END IF;

--UPDATE BY ANAS --
-- 70-03-2006 --

DECLARE
  V_CNT NUMBER;
  RET NUMBER;
  V_RET VARCHAR2(5);
BEGIN
 IF :BUS_ID_TYPE_CD = 2 AND :IMPR_TYPE_CD!=12 THEN


    IF :COMM_RGSTRTN_TYPE = 1 THEN

        IF :BUS_ID IS NOT NULL THEN

            SELECT COUNT(BUS_ID) INTO V_CNT FROM COMM_IMPR_RGSTR
            WHERE  BUS_ID=:BUS_ID
             AND   BRNCHREG=0;

            IF V_CNT >0 THEN

               SELECT  ARBC_IMPR_NAME,ARBC_NAME_STD,BUS_ID_EXPRD_DT,
                       IMPR_TEL_NBR,IMPR_POB_NBR,IMPR_ZIP_CD,IMPR_FAX_NBR,IMPR_TELEX_NBR
                INTO :ARBC_IMPR_NAME,:IMPR_NAME_STD,:BUS_ID_EXPRD_DT,:IMPR_TEL_NBR
                    ,:IMPR_POB_NBR,:IMPR_ZIP_CD,:IMPR_FAX_NBR,:IMPR_TELEX_NBR
               FROM  COMM_IMPR_RGSTR
               WHERE  BUS_ID=:BUS_ID
                AND   BRNCHREG=0;

            ELSE
              /* NOT CHECK IN COMM TABLE IF FUCTION VALUE <>0 */

               V_RET := LIB_USR.GNRL.GET_CUSTOMS_SETTING(:PARAMETER.P_CURR_PORT_CD,'COMM_TABLE_UNCHECK',9);
               IF NVL(V_RET,0) = 0 THEN
  	            ret := Str.DispArbMsg(9, 190,'ERROR');
	            RAISE FORM_TRIGGER_FAILURE;
  		    ELSE
			  INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_EXPRD_DT' , TRUE);

  			  INTRFACE.Make_Field_Entrable('IMPORTERS.COMM_RGSTRTN_TYPE' , TRUE);
			  INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_POB_NBR' , TRUE);
 			  INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_ZIP_CD' , TRUE);
			  INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_TEL_NBR' , TRUE);
			  INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_FAX_NBR' , TRUE);
			  INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_TELEX_NBR' , TRUE);
			  INTRFACE.Make_Field_Entrable('IMPORTERS.ARBC_IMPR_NAME' , TRUE);
			  SET_ITEM_PROPERTY('IMPORTERS.COMM_RGSTRTN_TYPE',REQUIRED,PROPERTY_TRUE);
                   -- :IMPORTERS.FILLER3:=1;
                END IF;

            END IF;

          END IF;

   ELSIF :COMM_RGSTRTN_TYPE = 2 THEN

     IF :BUS_ID IS NOT NULL AND :BUS_ID_BRNCH IS NOT NULL THEN
	  SELECT COUNT(BUS_ID)INTO V_CNT    FROM COMM_IMPR_RGSTR
	  WHERE  BUS_ID=:BUS_ID
	   AND   BRNCH_BUS_ID=:BUS_ID_BRNCH;

        IF V_CNT >0 THEN
 	     SELECT  ARBC_IMPR_NAME,ARBC_NAME_STD,BUS_ID_EXPRD_DT,
                   IMPR_TEL_NBR,IMPR_POB_NBR,IMPR_ZIP_CD,IMPR_FAX_NBR,IMPR_TELEX_NBR
  	      INTO   :ARBC_IMPR_NAME,:IMPR_NAME_STD,:BUS_ID_EXPRD_DT,:IMPR_TEL_NBR
   	            ,:IMPR_POB_NBR,:IMPR_ZIP_CD,:IMPR_FAX_NBR,:IMPR_TELEX_NBR
    	     FROM  COMM_IMPR_RGSTR
	     WHERE  BUS_ID=:BUS_ID
	      AND   BRNCH_BUS_ID=:BUS_ID_BRNCH;

        ELSE
            /* NOT CHECK IN COMM TABLE IF FUCTION VALUE <>0 */

               V_RET := LIB_USR.GNRL.GET_CUSTOMS_SETTING(:PARAMETER.P_CURR_PORT_CD,'COMM_TABLE_UNCHECK',9);

               IF NVL(V_RET,0) = 0 THEN

	           ret := Str.DispArbMsg(9, 190,'ERROR');
	           RAISE FORM_TRIGGER_FAILURE;
  		    ELSE
			  INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_EXPRD_DT' , TRUE);

  			  INTRFACE.Make_Field_Entrable('IMPORTERS.COMM_RGSTRTN_TYPE' , TRUE);
			  INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_POB_NBR' , TRUE);
 			  INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_ZIP_CD' , TRUE);
			  INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_TEL_NBR' , TRUE);
			  INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_FAX_NBR' , TRUE);
			  INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_TELEX_NBR' , TRUE);
			  INTRFACE.Make_Field_Entrable('IMPORTERS.ARBC_IMPR_NAME' , TRUE);
			  SET_ITEM_PROPERTY('IMPORTERS.COMM_RGSTRTN_TYPE',REQUIRED,PROPERTY_TRUE);

                --   :IMPORTERS.FILLER3:=1;

                END IF;

     	  END IF;

     END IF;

   END IF;

 END IF;

END;

END;

/*BEGIN
   IF     GET_RECORD_PROPERTY (:SYSTEM.cursor_record,:SYSTEM.cursor_block,status) IN ('NEW', 'INSERT') AND
		:importers.IMPR_TYPE_CD IN ( 1,3,5,6,19 ) AND :importers.bus_id_type_cd = 2
		 AND :GLOBAL.ALLOW_MCI = 1
   THEN
      IF :importers.comm_rgstrtn_type = 1 AND :importers.bus_id IS NOT NULL THEN
         get_main_cr_data;
      ELSIF :importers.comm_rgstrtn_type = 2 AND :importers.bus_id_brnch IS NOT NULL THEN
         get_branch_cr_data;
      END IF;
   END IF;
END;*/
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

#### IMPORTERS.BUS_ID_BRNCH · KEY-NEXT-ITEM

- Level: Item · Owner: `IMPORTERS.BUS_ID_BRNCH` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 7 total / 6 active (non-blank, non-comment)
- Built-ins: NEXT_ITEM
- Program units (form): CHK_IMPR_DUPL
- Library / DB package calls: –

```plsql
BEGIN
	IF :SYSTEM.RECORD_STATUS IN ('NEW','INSERT') THEN
		CHK_IMPR_DUPL;
	END IF;

	NEXT_ITEM;
END;
```

#### IMPORTERS.BUS_ID_BRNCH · WHEN-VALIDATE-ITEM

- Level: Item · Owner: `IMPORTERS.BUS_ID_BRNCH` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 86 total / 55 active (non-blank, non-comment)
- Built-ins: SET_ITEM_PROPERTY, RAISE FORM_TRIGGER_FAILURE
- Program units (form): CHK_IMPR_DUPL
- Library / DB package calls: INTRFACE.MAKE_FIELD_ENTRABLE, LIB_USR.GNRL.GET_CUSTOMS_SETTING, STR.DISPARBMSG

```plsql
BEGIN
	IF :System.TRIGGER_ITEM = :System.CURSOR_ITEM THEN
		CHK_IMPR_DUPL;
	END IF;
END;

--UPDATE BY ANAS- --
-- 07-03-2006 --

DECLARE
  V_CNT NUMBER;
  RET   NUMBER;
  V_RET VARCHAR2(5);
BEGIN
IF :BUS_ID_BRNCH = 0 THEN
    ret := Str.DispArbMsg(1, 220,'ERROR');
    RAISE FORM_TRIGGER_FAILURE;
ELSE

 IF :BUS_ID_TYPE_CD = 2 AND :IMPR_TYPE_CD!=12  THEN
  IF :COMM_RGSTRTN_TYPE = 2 THEN
     IF :BUS_ID IS NOT NULL AND :BUS_ID_BRNCH IS NOT NULL THEN
	  SELECT COUNT(BUS_ID)INTO V_CNT    FROM COMM_IMPR_RGSTR
	  WHERE  BUS_ID=:BUS_ID
	   AND   BRNCH_BUS_ID=:BUS_ID_BRNCH;

        IF V_CNT >0 THEN
 	     SELECT  ARBC_IMPR_NAME,ARBC_NAME_STD,BUS_ID_EXPRD_DT,
                   IMPR_TEL_NBR,IMPR_POB_NBR,IMPR_ZIP_CD,IMPR_FAX_NBR,IMPR_TELEX_NBR
  	      INTO   :ARBC_IMPR_NAME,:IMPR_NAME_STD,:BUS_ID_EXPRD_DT,:IMPR_TEL_NBR
   	            ,:IMPR_POB_NBR,:IMPR_ZIP_CD,:IMPR_FAX_NBR,:IMPR_TELEX_NBR
    	     FROM  COMM_IMPR_RGSTR
	     WHERE  BUS_ID=:BUS_ID
	      AND   BRNCH_BUS_ID=:BUS_ID_BRNCH;

        ELSE

              /* NOT CHECK IN COMM TABLE IF FUCTION VALUE <>0 */

               V_RET := LIB_USR.GNRL.GET_CUSTOMS_SETTING('COMM_TABLE_UNCHECK',9);

               IF NVL(V_RET,0) = 0 THEN

	           ret := Str.DispArbMsg(9, 190,'ERROR');
	           RAISE FORM_TRIGGER_FAILURE;
  		    ELSE
                  IF LENGTH(:IMPORTERS.BUS_ID_BRNCH) <> 10  THEN
		         ret := Str.DispArbMsg(9, 210,'ERROR');
           		   RAISE FORM_TRIGGER_FAILURE;

			ELSE

			  INTRFACE.Make_Field_Entrable('IMPORTERS.BUS_ID_EXPRD_DT' , TRUE);

  			  INTRFACE.Make_Field_Entrable('IMPORTERS.COMM_RGSTRTN_TYPE' , TRUE);
			  INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_POB_NBR' , TRUE);
 			  INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_ZIP_CD' , TRUE);
			  INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_TEL_NBR' , TRUE);
			  INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_FAX_NBR' , TRUE);
			  INTRFACE.Make_Field_Entrable('IMPORTERS.IMPR_TELEX_NBR' , TRUE);
			  INTRFACE.Make_Field_Entrable('IMPORTERS.ARBC_IMPR_NAME' , TRUE);
			  SET_ITEM_PROPERTY('IMPORTERS.COMM_RGSTRTN_TYPE',REQUIRED,PROPERTY_TRUE);

                  --  :IMPORTERS.FILLER3:=1;
                   END IF ;
                 END IF;

 	  END IF;
    END IF;
  END IF;
 END IF;
END IF;
END;

/*BEGIN
   IF     GET_RECORD_PROPERTY (:SYSTEM.cursor_record,:SYSTEM.cursor_block,status) IN ('NEW', 'INSERT') AND
		:importers.IMPR_TYPE_CD IN ( 1,3,5,6,19 ) AND :importers.bus_id_type_cd = 2
		AND :GLOBAL.ALLOW_MCI = 1
   THEN
      IF :importers.comm_rgstrtn_type = 1 AND :importers.bus_id IS NOT NULL THEN
         get_main_cr_data;
      ELSIF :importers.comm_rgstrtn_type = 2 AND :importers.bus_id_brnch IS NOT NULL THEN
         get_branch_cr_data;
      END IF;
   END IF;
END;*/
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

#### IMPORTERS.ID_MINS_COMM_CD · KEY-LISTVAL

- Level: Item · Owner: `IMPORTERS.ID_MINS_COMM_CD` · Execution hierarchy: default (Override)
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

#### IMPORTERS.ARBC_IMPR_NAME · KEY-NEXT-ITEM

- Level: Item · Owner: `IMPORTERS.ARBC_IMPR_NAME` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 34 total / 30 active (non-blank, non-comment)
- Built-ins: FIRST_RECORD, GO_ITEM
- Program units (form): –
- Library / DB package calls: –

```plsql
DECLARE
	CITY_DUMMY_VALUE NUMBER := 1;
	CTRY_DUMMY_VALUE NUMBER := 1;
BEGIN
	IF :ADD_CTRY_CD IS NULL THEN
		:ADD_CTRY_CD := :CTRY_CD;  -- only bcz CITY_CODE is Mandatory
	ELSE
		CTRY_DUMMY_VALUE := NULL;
	END IF;

	IF :CITY_CODE IS NULL THEN
		SELECT MIN(CITY_CD)
		INTO 	:CITY_CODE
		FROM 	CITIES
		WHERE CTRY_CD = :CTRY_CD
		AND	CITY_STATUS = 1
		;
	ELSE
		CITY_DUMMY_VALUE  := NULL;
	END IF;


	FIRST_RECORD;
	IF CITY_DUMMY_VALUE IS NOT NULL THEN
		:CITY_CODE 	 := NULL;
		:CITY_NAME	 := NULL;
	END IF;

	IF CTRY_DUMMY_VALUE IS NOT NULL THEN
		:ADD_CTRY_CD 	  := NULL;
		:ADD_CRTY_ARBC_NAME := NULL;
	END IF;
	go_Item('IMPORTERS.ENG_IMPR_NAME');
END;
```

#### IMPORTERS.IMPD_STMT_NBR · KEY-LISTVAL

- Level: Item · Owner: `IMPORTERS.IMPD_STMT_NBR` · Execution hierarchy: default (Override)
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

#### IMPORTERS.IMPR_DATA_SRCE · KEY-LISTVAL

- Level: Item · Owner: `IMPORTERS.IMPR_DATA_SRCE` · Execution hierarchy: default (Override)
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

#### IMPORTERS.ENG_IMPR_NAME · WHEN-VALIDATE-ITEM

- Level: Item · Owner: `IMPORTERS.ENG_IMPR_NAME` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 30 total / 21 active (non-blank, non-comment)
- Built-ins: RAISE FORM_TRIGGER_FAILURE
- Program units (form): –
- Library / DB package calls: STR.DISPALERT, STR_DB.REMOVEREPEAT

```plsql
DECLARE
	ENG_IMPR_NAME_length   NUMBER;
	V         VARCHAR2(1);
BEGIN

IF :ENG_IMPR_NAME IS NOT NULL THEN
  :ENG_IMPR_NAME := STR_db.RemoveRepeat(:ENG_IMPR_NAME);

	ENG_IMPR_NAME_length := LENGTH(:ENG_IMPR_NAME);

		FOR I IN  1 .. ENG_IMPR_NAME_length LOOP
		  V := SUBSTR(:ENG_IMPR_NAME,I,1);


		     IF ( V BETWEEN '0' AND '9' ) OR ( V BETWEEN 'A' AND 'Z' ) OR ( V BETWEEN 'a' AND 'z' )
		     	 OR ( V = ' ' ) THEN
				NULL;
		     ELSE

				STR.DISPALERT ('فضلا .. يجب إدخال اسم المستورد باللغة الانجليزية','information');
				RAISE FORM_TRIGGER_FAILURE;
                 END IF;
  	END LOOP;
ELSE
NULL;
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

#### IMPORTERS.IMPR_ADDRESS · KEY-LISTVAL

- Level: Item · Owner: `IMPORTERS.IMPR_ADDRESS` · Execution hierarchy: default (Override)
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

#### IMPORTERS.BUS_ID_ISSUE_DT · KEY-LISTVAL

- Level: Item · Owner: `IMPORTERS.BUS_ID_ISSUE_DT` · Execution hierarchy: default (Override)
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

#### IMPORTERS.BUS_ID_ISSUE_DT · KEY-F4

- Level: Item · Owner: `IMPORTERS.BUS_ID_ISSUE_DT` · Execution hierarchy: default (Override)
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

#### IMPORTERS.BUS_ID_ISSUE_DT · WHEN-VALIDATE-ITEM

- Level: Item · Owner: `IMPORTERS.BUS_ID_ISSUE_DT` · Execution hierarchy: default (Override)
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

#### IMPORTERS.IMPR_NBR_PARENT · KEY-LISTVAL

- Level: Item · Owner: `IMPORTERS.IMPR_NBR_PARENT` · Execution hierarchy: default (Override)
- Lines: 71 total / 62 active (non-blank, non-comment)
- Built-ins: ADD_PARAMETER, CALL_FORM, CREATE_PARAMETER_LIST, DESTROY_PARAMETER_LIST, GET_BLOCK_PROPERTY, GET_ITEM_PROPERTY, GET_PARAMETER_LIST, GET_RECORD_PROPERTY, GO_ITEM, ID_NULL, RAISE FORM_TRIGGER_FAILURE
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
   pl_name VARCHAR2(100) := 'IMPR_LOV';

   RET NUMBER;

 BEGIN
   pl_id := Get_Parameter_List(pl_name);
   IF Id_Null(pl_id) THEN
     pl_id := Create_Parameter_List(pl_name);
     IF Id_Null(pl_id) THEN
       ret := Str.Dispalert('Error creating parameter list '||pl_name, 'SYSTEM_ERROR');
       RAISE Form_Trigger_Failure;
     END IF;

   Add_Parameter(pl_id, 'PORT_CD', TEXT_PARAMETER, :PARAMETER.P_Curr_Port_CD);
   Add_Parameter(pl_id, 'WINDOW_TITLE', TEXT_PARAMETER, 'قائمة إختيار المستوردين');

   CALL_FORM('LOV_IMPR.fmx',
              no_hide,
              no_replace,
              no_query_only,
              pl_id);

 	IF  :GLOBAL.IMPR_NBR IS NOT NULL THEN
	:IMPR_NBR_PARENT := :GLOBAL.IMPR_NBR;
	:IMPR_NAME_PARENT := :GLOBAL.IMPR_NAME;
	go_item('CITY_CODE');
 	END IF;


   Destroy_Parameter_List(pl_id);
   ELSE
     ret := Str.DispAlert('Parameter list '||pl_name||' already EXISTS!','INFORMATION');
     RAISE Form_Trigger_Failure;
   END IF;
 END;
```

#### IMPORTERS.IMPR_NBR_PARENT · WHEN-VALIDATE-ITEM

- Level: Item · Owner: `IMPORTERS.IMPR_NBR_PARENT` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 21 total / 17 active (non-blank, non-comment)
- Built-ins: –
- Program units (form): –
- Library / DB package calls: STR.DISPARBMSG

```plsql
DECLARE
	ret NUMBER;
	CURSOR C_P_NAME IS
	    	SELECT ARBC_IMPR_NAME
		FROM IMPORTERS
		WHERE IMPR_NBR = :IMPR_NBR_PARENT
AND PORT_CD    = :PARAMETER.P_CURR_PORT_CD;

BEGIN
IF :IMPR_NBR_PARENT IS NOT NULL THEN
--IF :System.TRIGGER_ITEM = :System.CURSOR_ITEM THEN
	OPEN C_P_NAME;
	FETCH C_P_NAME INTO :IMPR_NAME_PARENT;

	IF C_P_NAME%NOTFOUND THEN
		ret := Str.DispArbMsg(9, 160,'ERROR');
	END IF;
	CLOSE C_P_NAME;
--END IF;
END IF;
END;
```

#### IMPORTERS.IMPR_NBR_PARENT2 · WHEN-BUTTON-PRESSED

- Level: Item · Owner: `IMPORTERS.IMPR_NBR_PARENT2` · Execution hierarchy: default (Override)
- Lines: 7 total / 5 active (non-blank, non-comment)
- Built-ins: DO_KEY, GO_ITEM
- Program units (form): –
- Library / DB package calls: –

```plsql
/* CGAP$OLES_SEQUENCE_BEFORE */
NULL;

BEGIN
  go_item('IMPORTERS.IMPR_NBR_PARENT');
  do_key('List_values');
  END;
```

#### IMPORTERS.IMPR_NAME_PARENT · KEY-LISTVAL

- Level: Item · Owner: `IMPORTERS.IMPR_NAME_PARENT` · Execution hierarchy: default (Override)
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

#### IMPORTERS.ADD_CTRY_CD · KEY-LISTVAL

- Level: Item · Owner: `IMPORTERS.ADD_CTRY_CD` · Execution hierarchy: default (Override)
- Lines: 75 total / 64 active (non-blank, non-comment)
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
   pl_name VARCHAR2(100) := 'ADD_CTRY_LOV';

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


   Add_Parameter(pl_id, 'WINDOW_WIDTH', TEXT_PARAMETER, 4.5);
   Add_Parameter(pl_id, 'WINDOW_TITLE', TEXT_PARAMETER, 'قائمة الدول');

   CALL_FORM('LOV_COUNTRIES.fmx',
              no_hide,
              no_replace,
              no_query_only,
              pl_id);

 	IF  :GLOBAL.CTRY_CD IS NOT NULL THEN
		:ADD_CTRY_CD := :GLOBAL.CTRY_CD;
		:ADD_CRTY_ARBC_NAME := :GLOBAL.CRTY_ARBC_NAME;
 	END IF;


   Destroy_Parameter_List(pl_id);
   ELSE
     ret := Str.DispAlert('Parameter list '||pl_name||' already exists!','INFORMATION');
     RAISE Form_Trigger_Failure;
   END IF;
 END;
```

#### IMPORTERS.ADD_CTRY_CD · WHEN-VALIDATE-ITEM

- Level: Item · Owner: `IMPORTERS.ADD_CTRY_CD` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 19 total / 17 active (non-blank, non-comment)
- Built-ins: NAME_IN
- Program units (form): CGFK$CHK_IMPORTERS_IMP_ADD_CIT
- Library / DB package calls: CGTE$OTHER_EXCEPTIONS, DES$FORM_ERRORS.PUSH

```plsql
/* CGFK$VALDIDATE_FK_OVF */
/* Check that foreign key value exists in referenced table */
BEGIN
  IF (name_in('IMPORTERS.ADD_CTRY_CD') IS NOT NULL AND name_in('IMPORTERS.CITY_CODE') IS NOT NULL) THEN
    BEGIN
      CGFK$CHK_IMPORTERS_IMP_ADD_CIT(
        :IMPORTERS.ADD_CRTY_ARBC_NAME    /* MOD: Value in Item :IMPORTERS.ADD_CRTY_ARBC_NAME.                                                                                                                                                 */
       ,:IMPORTERS.CITY_NAME             /* MOD: Value in Item :IMPORTERS.CITY_NAME.                                                                                                                                                          */
       ,:IMPORTERS.L_CT_CITY_STATUS      /* MOD: Value in Item :IMPORTERS.L_CT_CITY_STATUS.                                                                                                                                                   */
       ,:IMPORTERS.CITY_CODE             /* IN : Value in Item :IMPORTERS.CITY_CODE.                                                                                                                                                          */
       ,:IMPORTERS.ADD_CTRY_CD       );  /* IN : Value in Item :IMPORTERS.ADD_CTRY_CD.                                                                                                                                                        */
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        Des$Form_errors.PUSH('خطأ في رمز مدينة عنوان المستورد', 'W', 'OFG', 0);
      WHEN OTHERS THEN
        CGTE$OTHER_EXCEPTIONS;
    END;
  END IF;
END;
```

#### IMPORTERS.ADD_CTRY_CD2 · WHEN-BUTTON-PRESSED

- Level: Item · Owner: `IMPORTERS.ADD_CTRY_CD2` · Execution hierarchy: default (Override)
- Lines: 6 total / 4 active (non-blank, non-comment)
- Built-ins: DO_KEY, GO_ITEM
- Program units (form): –
- Library / DB package calls: –

```plsql
/* CGLY$WHEN_BUTTON_PRESSED */
/* Replicate default menu functionality */
BEGIN
  go_item('IMPORTERS.ADD_CTRY_CD');
  do_key('List_values');
END;
```

#### IMPORTERS.ADD_CRTY_ARBC_NAME · KEY-LISTVAL

- Level: Item · Owner: `IMPORTERS.ADD_CRTY_ARBC_NAME` · Execution hierarchy: default (Override)
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

#### IMPORTERS.CITY_CODE · KEY-LISTVAL

- Level: Item · Owner: `IMPORTERS.CITY_CODE` · Execution hierarchy: default (Override)
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

   Add_Parameter(pl_id, 'WINDOW_TITLE ', TEXT_PARAMETER,'قائمة المدن');
   Add_Parameter(pl_id, 'WINDOW_WIDTH ', TEXT_PARAMETER, 5);
   Add_Parameter(pl_id, 'WINDOW_X_POS', TEXT_PARAMETER, 1.5);
   Add_Parameter(pl_id, 'WINDOW_Y_POS', TEXT_PARAMETER, .8);
   Add_Parameter(pl_id, 'CTRY_CD', TEXT_PARAMETER, :ADD_CTRY_CD);




  IF (:SYSTEM.MODE <> 'ENTER_QUERY') THEN
      ADD_PARAMETER(PL_ID,'STATUS',TEXT_PARAMETER,1);
END IF;

   CALL_FORM('LOV_CITIES.fmx ',
              no_hide,
              no_replace,
              no_query_only,
              pl_id);


 	IF  :GLOBAL.CITY_CD IS NOT NULL THEN
	    :CITY_CODE :=:GLOBAL.CITY_CD ;
	    :ADD_CTRY_CD :=:GLOBAL.CTRY_CD ;
	    :CITY_NAME :=:GLOBAL.CITY_ARB_NAME ;
 	END IF;

   Destroy_Parameter_List(pl_id);
   ELSE
     ret := Str.DispAlert('Parameter list '||'LOV_CITIES'||' already EXISTS!','INFORMATION');
     RAISE Form_Trigger_Failure;
   END IF;

 END;
```

#### IMPORTERS.CITY_CODE · WHEN-VALIDATE-ITEM

- Level: Item · Owner: `IMPORTERS.CITY_CODE` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 38 total / 33 active (non-blank, non-comment)
- Built-ins: NAME_IN, RAISE FORM_TRIGGER_FAILURE
- Program units (form): CGFK$CHK_IMPORTERS_IMP_ADD_CIT
- Library / DB package calls: CGTE$OTHER_EXCEPTIONS, DES$FORM_ERRORS.PUSH, STR.DISPALERT, STR.DISPARBMSG

```plsql
DECLARE
 RET NUMBER;
BEGIN

IF :CITY_CODE  IS NULL THEN
STR.DISPALERT('يجب إدخال المدينة','INFORMATION');
  RAISE FORM_TRIGGER_FAILURE;
END IF;

 SELECT CITY_ARB_NAME INTO :CITY_NAME
 FROM   CITIES
 WHERE  CTRY_CD=:ADD_CTRY_CD
  AND   CITY_CD=:CITY_CODE;
EXCEPTION
WHEN NO_DATA_FOUND THEN
  ret := Str.DispArbMsg(18, 282,'ERROR');
  RAISE FORM_TRIGGER_FAILURE;

END;
/* CGFK$VALDIDATE_FK_OVF */
/* Check that foreign key value exists in referenced table */
BEGIN
  IF (name_in('IMPORTERS.ADD_CTRY_CD') IS NOT NULL AND name_in('IMPORTERS.CITY_CODE') IS NOT NULL) THEN
    BEGIN
      CGFK$CHK_IMPORTERS_IMP_ADD_CIT(
        :IMPORTERS.ADD_CRTY_ARBC_NAME    /* MOD: Value in Item :IMPORTERS.ADD_CRTY_ARBC_NAME.                                                                                                                                                 */
       ,:IMPORTERS.CITY_NAME             /* MOD: Value in Item :IMPORTERS.CITY_NAME.                                                                                                                                                          */
       ,:IMPORTERS.L_CT_CITY_STATUS      /* MOD: Value in Item :IMPORTERS.L_CT_CITY_STATUS.                                                                                                                                                   */
       ,:IMPORTERS.CITY_CODE             /* IN : Value in Item :IMPORTERS.CITY_CODE.                                                                                                                                                          */
       ,:IMPORTERS.ADD_CTRY_CD       );  /* IN : Value in Item :IMPORTERS.ADD_CTRY_CD.                                                                                                                                                        */
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        Des$Form_errors.PUSH('خطأ في رمز مدينة عنوان المستورد', 'W', 'OFG', 0);
      WHEN OTHERS THEN
        CGTE$OTHER_EXCEPTIONS;
    END;
  END IF;
END;
```

#### IMPORTERS.CITY_CODE2 · WHEN-BUTTON-PRESSED

- Level: Item · Owner: `IMPORTERS.CITY_CODE2` · Execution hierarchy: default (Override)
- Lines: 7 total / 5 active (non-blank, non-comment)
- Built-ins: DO_KEY, GO_ITEM
- Program units (form): –
- Library / DB package calls: –

```plsql
/* CGAP$OLES_SEQUENCE_BEFORE */
NULL;

BEGIN
  go_item('IMPORTERS.CITY_CODE');
  do_key('List_values');
  END;
```

#### IMPORTERS.CITY_NAME · KEY-LISTVAL

- Level: Item · Owner: `IMPORTERS.CITY_NAME` · Execution hierarchy: default (Override)
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

#### IMPORTERS.IMPR_POB_NBR · KEY-LISTVAL

- Level: Item · Owner: `IMPORTERS.IMPR_POB_NBR` · Execution hierarchy: default (Override)
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

#### IMPORTERS.IMPR_ZIP_CD · KEY-LISTVAL

- Level: Item · Owner: `IMPORTERS.IMPR_ZIP_CD` · Execution hierarchy: default (Override)
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

#### IMPORTERS.IMPR_TEL_NBR · KEY-LISTVAL

- Level: Item · Owner: `IMPORTERS.IMPR_TEL_NBR` · Execution hierarchy: default (Override)
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

#### IMPORTERS.IMPR_TEL_NBR · WHEN-VALIDATE-ITEM

- Level: Item · Owner: `IMPORTERS.IMPR_TEL_NBR` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 39 total / 26 active (non-blank, non-comment)
- Built-ins: RAISE FORM_TRIGGER_FAILURE
- Program units (form): –
- Library / DB package calls: STR.DISPALERT

```plsql
DECLARE
IMPR_TEL_NBR_length  NUMBER;
V    VARCHAR2(1);
BEGIN

IF :IMPR_TEL_NBR IS NULL THEN
  str.DISPALERT('يجب إدخال الهاتف','INFORMATION');
   RAISE FORM_TRIGGER_FAILURE ;
END IF;
/*
IF TO_NUMBER(:IMPR_TEL_NBR) = 0 THEN
 str.DISPALERT('يجب أن يكون رقم الهاتف المدخل أرقام','INFORMATION');
RAISE FORM_TRIGGER_FAILURE ;
END IF;
*/

IF LENGTH(:IMPR_TEL_NBR) < 10 OR LENGTH(:IMPR_TEL_NBR) > 10 THEN
   str.DISPALERT('رقم الهاتف يجب أن يتكون من 10 أرقام','INFORMATION');
RAISE FORM_TRIGGER_FAILURE ;
END IF;

BEGIN
IMPR_TEL_NBR_length := LENGTH(:IMPR_TEL_NBR);

		FOR I IN  1 .. IMPR_TEL_NBR_length LOOP
		  V := SUBSTR(:IMPR_TEL_NBR,I,1);

		     IF ( V BETWEEN '0' AND '9' )
		     	 THEN
				NULL;
		     ELSE

				STR.DISPALERT ('يجب أن يكون رقم الهاتف المدخل أرقام','information');
				RAISE FORM_TRIGGER_FAILURE;
                 END IF;
  	END LOOP;
END ;

END;
```

#### IMPORTERS.IMPR_FAX_NBR · KEY-LISTVAL

- Level: Item · Owner: `IMPORTERS.IMPR_FAX_NBR` · Execution hierarchy: default (Override)
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

#### IMPORTERS.IMPR_TELEX_NBR · KEY-LISTVAL

- Level: Item · Owner: `IMPORTERS.IMPR_TELEX_NBR` · Execution hierarchy: default (Override)
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

#### IMPORTERS.EMAIL · WHEN-VALIDATE-ITEM

- Level: Item · Owner: `IMPORTERS.EMAIL` · Execution hierarchy: default (Override)
- Lines: 29 total / 20 active (non-blank, non-comment)
- Built-ins: RAISE FORM_TRIGGER_FAILURE
- Program units (form): –
- Library / DB package calls: STR.DISPALERT

```plsql
/* CGAP$OLES_SEQUENCE_BEFORE */
DECLARE
	EMAIL VARCHAR2(200);
	At_Pos number;
	Dot_Pos number;
	EMAIL_LENGTH  number;
	RET NUMBER;

Begin

	IF :System.TRIGGER_ITEM = :System.CURSOR_ITEM THEN

		EMAIL := :System.Cursor_Value;
		EMAIL_LENGTH := LENGTH(EMAIL);
		IF (EMAIL_LENGTH > 0)	 THEN
			At_Pos := INSTR(EMAIL, '@');
			Dot_Pos := INSTR(EMAIL, '.');

			--IF (At_Pos  <= 0 OR Dot_Pos <= 0 or At_Pos = 1 or Dot_Pos = EMAIL_LENGTH or Dot_Pos  < At_Pos or Dot_Pos  = At_Pos+1  ) THEN
				IF (At_Pos  <= 0 OR At_Pos = 1 ) THEN

				RET := STR.DISPALERT('خطأ فى صيغة البريد الالكتروني','INFORMATION');
				RAISE FORM_TRIGGER_FAILURE;
			END IF;

		END IF;

	END IF;
End;
```

#### IMPORTERS.MOBILE_NO · KEY-LISTVAL

- Level: Item · Owner: `IMPORTERS.MOBILE_NO` · Execution hierarchy: default (Override)
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

#### IMPORTERS.MOBILE_NO · WHEN-VALIDATE-ITEM

- Level: Item · Owner: `IMPORTERS.MOBILE_NO` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 34 total / 26 active (non-blank, non-comment)
- Built-ins: RAISE FORM_TRIGGER_FAILURE
- Program units (form): –
- Library / DB package calls: STR.DISPALERT

```plsql
DECLARE
MOBILE_NO_length  NUMBER;
V    VARCHAR2(1);
BEGIN

IF :MOBILE_NO IS NULL THEN
STR.DISPALERT('يجب إدخال رقم المحمول','ERROR');
RAISE FORM_TRIGGER_FAILURE;
END IF;

BEGIN
MOBILE_NO_length := LENGTH (:MOBILE_NO);

		FOR I IN  1 .. MOBILE_NO_length LOOP
		  V := SUBSTR(:MOBILE_NO,I,1);

		     IF ( V BETWEEN '0' AND '9' )
		     	 THEN
				NULL;
		     ELSE

				STR.DISPALERT ('يجب أن يكون رقم الجوال المدخل أرقام','information');
				RAISE FORM_TRIGGER_FAILURE;
                 END IF;
  	END LOOP;
END ;



	IF :MOBILE_NO IS NOT NULL AND (LENGTH(:MOBILE_NO) != 9 OR SUBSTR(:MOBILE_NO,1,1) != 5 ) THEN
		STR.DISPALERT('رقم الجوال المدخل غير صحيح .. الرجاء اعادة الادخال ','ERROR');
		RAISE FORM_TRIGGER_FAILURE;
	END IF;
END;
```

#### IMPORTERS.EXPRESS_POST · KEY-LISTVAL

- Level: Item · Owner: `IMPORTERS.EXPRESS_POST` · Execution hierarchy: default (Override)
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

#### IMPORTERS.CTRY_CD_OF_ID · WHEN-VALIDATE-ITEM

- Level: Item · Owner: `IMPORTERS.CTRY_CD_OF_ID` · Execution hierarchy: default (Override) · Fire in query: false
- Lines: 15 total / 13 active (non-blank, non-comment)
- Built-ins: NAME_IN
- Program units (form): CGSF$CLRLU_IMPORTERS_IMP_BUS_I
- Library / DB package calls: CGTE$OTHER_EXCEPTIONS

```plsql
/* CGFK$WVI_CLR_DEPS_OVF */
/* Clear dependent items, if this item is null. */
BEGIN
  IF (name_in('IMPORTERS.CITY_CODE_OF_ID') IS NULL AND name_in('IMPORTERS.CTRY_CD_OF_ID') IS NULL) THEN
    IF (:SYSTEM.RECORD_STATUS = 'NEW') THEN
      RETURN;
    END IF;
    BEGIN
      CGSF$CLRLU_IMPORTERS_IMP_BUS_I;
    EXCEPTION
      WHEN OTHERS THEN
        CGTE$OTHER_EXCEPTIONS;
    END;
  END IF;
END;
```

#### IMPORTERS.CUSTOMS_ENTERED · KEY-LISTVAL

- Level: Item · Owner: `IMPORTERS.CUSTOMS_ENTERED` · Execution hierarchy: default (Override)
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

#### IMPORTERS.CUSTOMS_ENTERED2 · WHEN-BUTTON-PRESSED

- Level: Item · Owner: `IMPORTERS.CUSTOMS_ENTERED2` · Execution hierarchy: default (Override)
- Lines: 6 total / 4 active (non-blank, non-comment)
- Built-ins: DO_KEY, GO_ITEM
- Program units (form): –
- Library / DB package calls: –

```plsql
/* CGLY$WHEN_BUTTON_PRESSED */
/* Replicate default menu functionality */
BEGIN
  go_item('IMPORTERS.CUSTOMS_ENTERED');
  do_key('List_values');
END;
```

#### IMPORTERS.EXPD_STMT_NBR · KEY-LISTVAL

- Level: Item · Owner: `IMPORTERS.EXPD_STMT_NBR` · Execution hierarchy: default (Override)
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

#### IMPORTERS.WVR_ENTRY_NBR · KEY-LISTVAL

- Level: Item · Owner: `IMPORTERS.WVR_ENTRY_NBR` · Execution hierarchy: default (Override)
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

#### IMPORTERS.CREATION_FLAG · KEY-LISTVAL

- Level: Item · Owner: `IMPORTERS.CREATION_FLAG` · Execution hierarchy: default (Override)
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

#### IMPORTERS.CREATION_FLAG2 · WHEN-BUTTON-PRESSED

- Level: Item · Owner: `IMPORTERS.CREATION_FLAG2` · Execution hierarchy: default (Override)
- Lines: 6 total / 4 active (non-blank, non-comment)
- Built-ins: DO_KEY, GO_ITEM
- Program units (form): –
- Library / DB package calls: –

```plsql
/* CGLY$WHEN_BUTTON_PRESSED */
/* Replicate default menu functionality */
BEGIN
  go_item('IMPORTERS.CREATION_FLAG');
  do_key('List_values');
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
| CGDV$IMPORTERS_CREATION_FLAG | Valid values for نوع تكوين السجل التجاري | CGDV$CREATION_FLAG | RV_LOW_VALUE → IMPORTERS.CREATION_FLAG; RV_MEANING → (not returned) | IMPORTERS.CREATION_FLAG | not in XML (item property `ValidateFromList` absent → default/OLB) | default/OLB |
| CGFK$IMPORTERS_ADD_CTRY_CD | Valid values for دولــــــــة الإقامـــــة | CGFK$IMPORTERS_ADD_CTRY_CD | L_CT_CITY_STATUS → IMPORTERS.L_CT_CITY_STATUS; ADD_CTRY_CD → IMPORTERS.ADD_CTRY_CD; ADD_CRTY_ARBC_NAME → IMPORTERS.ADD_CRTY_ARBC_NAME | IMPORTERS.ADD_CTRY_CD | not in XML (item property `ValidateFromList` absent → default/OLB) | default/OLB |
| CGFK$IMPORTERS_CITY_CODE_OF_ID | Valid values for مصدررقم الإستدلالي | CGFK$IMPORTERS_CITY_CODE_OF_ID | L_CT_CITY_STATUS2 → IMPORTERS.L_CT_CITY_STATUS2; CITY_CODE_OF_ID → IMPORTERS.CITY_CODE_OF_ID; ID_CITY_NAME → IMPORTERS.ID_CITY_NAME; ID_MINS_COMM_CD → IMPORTERS.ID_MINS_COMM_CD | IMPORTERS.CITY_CODE_OF_ID | not in XML (item property `ValidateFromList` absent → default/OLB) | default/OLB |
| CGFK$IMPORTERS_CTRY_CD | Valid values for دولة الرقم الإستدلالي | CGFK$IMPORTERS_CTRY_CD | CTRY_CD → IMPORTERS.CTRY_CD; CRTY_ARBC_NAME → IMPORTERS.CRTY_ARBC_NAME; CTRY_CTRY_STATUS → IMPORTERS.CTRY_CTRY_STATUS | IMPORTERS.CTRY_CD | not in XML (item property `ValidateFromList` absent → default/OLB) | default/OLB |
| CGFK$IMPORTERS_HQ_IMPR_NBR | Valid values for الرقم الموحد بالمصلحة | CGFK$IMPORTERS_HQ_IMPR_NBR | HQ_IMPR_NBR → IMPORTERS.HQ_IMPR_NBR | IMPORTERS.HQ_IMPR_NBR | not in XML (item property `ValidateFromList` absent → default/OLB) | default/OLB |
| CGFK$IMPORTERS_IMPR_TYPE_CD | قائمة رموز الأنشطة التجارية أرقامها الإستدلالية | CGFK$IMPORTERS_IMPR_TYPE_CD | IMPR_TYPE_CD → IMPORTERS.IMPR_TYPE_CD | IMPORTERS.IMPR_TYPE_CD | not in XML (item property `ValidateFromList` absent → default/OLB) | default/OLB |
| CGFK$IMPORTERS_PORT_CD | Valid values for رمز الجمــــــــــــــرك | CGFK$IMPORTERS_PORT_CD | PORT_CD → IMPORTERS.PORT_CD; PORT_NAME → IMPORTERS.PORT_NAME | IMPORTERS.PORT_CD | not in XML (item property `ValidateFromList` absent → default/OLB) | default/OLB |
| CGDV$IMPORTERS_CUSTOMS_ENTERED | Valid values for موجود أو غير موجود بملف وزارة التجارة | CGDV$IMPORTERS_CUSTOMS_ENTERED | RV_LOW_VALUE → IMPORTERS.CUSTOMS_ENTERED; RV_MEANING → (not returned) | IMPORTERS.CUSTOMS_ENTERED | not in XML (item property `ValidateFromList` absent → default/OLB) | default/OLB |

### 7.1 Record groups

#### CGDV$CREATION_FLAG
- Type: Query · Attached to LOV: yes · Comment: CGDV.D.CREATION_FLAG.L.M
- Columns: RV_LOW_VALUE (2), RV_MEANING (38)

```sql
SELECT  substr(RV_LOW_VALUE,1,2)  RV_LOW_VALUE
      , substr(RV_MEANING,1,38)  RV_MEANING
FROM    CG_REF_CODES
WHERE   RV_DOMAIN = 'CREATION_FLAG'
ORDER BY  RV_LOW_VALUE
```


#### CGFK$IMPORTERS_ADD_CTRY_CD
- Type: Query · Attached to LOV: yes
- Columns: L_CT_CITY_STATUS Number(1), ADD_CTRY_CD Number(3), ADD_CRTY_ARBC_NAME (50)

```sql
SELECT ADD_CITY.CITY_STATUS  L_CT_CITY_STATUS  /* CG$FK */
      ,ADD_CITY.CTRY_CD  ADD_CTRY_CD
      ,L_CTRY.CRTY_ARBC_NAME  ADD_CRTY_ARBC_NAME
      ,ADD_CITY.CITY_CD  CITY_CODE
      ,ADD_CITY.CITY_ARB_NAME  CITY_NAME
FROM   CITIES ADD_CITY
      ,COUNTRIES L_CTRY
WHERE  ((
(:SYSTEM.MODE = 'ENTER-QUERY')
)
OR ((:SYSTEM.MODE = 'NORMAL')
AND    ADD_CITY.CITY_STATUS = 1
))
AND    L_CTRY.CTRY_CD = ADD_CITY.CTRY_CD
```


#### CGFK$IMPORTERS_CITY_CODE_OF_ID
- Type: Query · Attached to LOV: yes
- Columns: L_CT_CITY_STATUS2 Number(1), CITY_CODE_OF_ID Number(3), ID_CITY_NAME (20), ID_MINS_COMM_CD Number(4)

```sql
SELECT ID_CITY.CITY_STATUS  L_CT_CITY_STATUS2  /* CG$FK */
      ,ID_CITY.CITY_CD  CITY_CODE_OF_ID
      ,ID_CITY.CITY_ARB_NAME  ID_CITY_NAME
      ,ID_CITY.MINS_COMM_CD  ID_MINS_COMM_CD
      ,ID_CITY.CTRY_CD  CTRY_CD_OF_ID
FROM   CITIES ID_CITY
WHERE  ((
(:SYSTEM.MODE = 'ENTER-QUERY')
)
OR ((:SYSTEM.MODE = 'NORMAL')
AND    ID_CITY.CITY_STATUS = 1
))
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
- Columns: IMPR_TYPE_CD Number(3)

```sql
SELECT ITIDT.IMPR_TYPE_CD  IMPR_TYPE_CD  /* CG$FK */
      ,ITIDT.BUS_ID_TYPE_CD  BUS_ID_TYPE_CD
      ,IT.IMPR_TYPE_NAME  IMPR_TYPE_NAME
      ,BIT.BUS_ID_TYPE_NAME  BUS_ID_TYPE_NAME
      ,ITIDT.NOTE  ITIDT_NOTE
      ,ITIDT.STATUS  STATUS
FROM   IMPR_TYPE_ID_TYPES ITIDT
      ,IMPR_TYPES IT
      ,BUS_ID_TYPES BIT
WHERE  IT.IMPR_TYPE_CD = ITIDT.IMPR_TYPE_CD
AND    BIT.BUS_ID_TYPE_CD = ITIDT.BUS_ID_TYPE_CD
```


#### CGFK$IMPORTERS_PORT_CD
- Type: Query · Attached to LOV: yes
- Columns: PORT_CD Number(3), PORT_NAME (40)

```sql
SELECT L_SDP.PORT_CD  PORT_CD  /* CG$FK */
      ,L_SDP.PORT_NAME  PORT_NAME
FROM   SD_PORTS L_SDP
```


#### CGDV$IMPORTERS_CUSTOMS_ENTERED
- Type: Static · Attached to LOV: yes · Comment: CGDV.C.IMPORTERS.CUSTOMS_ENTERED
- Columns: RV_LOW_VALUE (1), RV_MEANING (80)
- Static values: {"Index": "1", "Value": "0"}; {"Index": "2", "Value": "1"}; {"Index": "1", "Value": "السجل تم تسجيله بالشكل الطبيعي سواء مستورد سجل تجاري أو غيره"}; {"Index": "2", "Value": "بيانات المستورد تخص سجل تجاري غير موجود في جدول وزارة التجارة ، وتم تسجيله يدويا"}



## 8. Canvases & Windows

| Canvas | Type | Window | Size (W×H) | Viewport | Tab pages | Items shown | Subclassed from |
|---|---|---|---|---|---|---|---|
| LSIDE | Content (default) / OLB | default/OLB | – | – | – | 0: – | CIC_OLB.olb:LSIDE |
| EDI_MSG | Content (default) / OLB | default/OLB | – | – | – | 0: – | CIC_OLB.olb:EDI_MSG |
| TITLE | Content (default) / OLB | default/OLB | – | – | – | 0: – | CIC_OLB.olb:TITLE |
| TOOLBAR | Content (default) / OLB | default/OLB | – | – | – | 0: – | CIC_OLB.olb:TOOLBAR |
| CG$PAGE_1 | Content (default) / OLB | CGSO$WINDOW_1 | 8300×8800 | 0×8800 | – | 48: PORT_CD, PORT_CD2, PORT_NAME, HQ_IMPR_NBR, IMPR_NBR, SUSPN_STATUS, STATUS_DESC, IMPR_TYPE_CD, IMPR_TYPE_CD2, IMPR_TYPE_NAME, BUS_ID_EXPRD_DT, BUS_ID_TYPE_CD, BUTT, BUS_ID_TYPE_NAME, COMM_RGSTRTN_TYPE, CTRY_CD, CTRY_CD2, CRTY_ARBC_NAME, CITY_CODE_OF_ID, CITY_CODE_OF_ID2, ID_CITY_NAME, IMPR_EXPR_TYPE, NATIONAL_NBR, BUS_ID, BUS_ID_BRNCH, ARBC_IMPR_NAME, ENG_IMPR_NAME, IMPR_CNTCT_NAME, IMPR_ADDRESS, BUS_ID_ISSUE_DT, IMPR_NBR_PARENT, IMPR_NBR_PARENT2, IMPR_NAME_PARENT, ADD_CTRY_CD, ADD_CTRY_CD2, ADD_CRTY_ARBC_NAME, CITY_CODE, CITY_CODE2, CITY_NAME, IMPR_POB_NBR, IMPR_ZIP_CD, IMPR_TEL_NBR, IMPR_FAX_NBR, IMPR_TELEX_NBR, EMAIL, MOBILE_NO, CAR_AGENT_FLAG, EXPRESS_POST | cic_olb.olb:CGSO$CANVAS |

| Window | Modal | Title | Size | Subclassed from |
|---|---|---|---|---|
| CGSO$WINDOW_1 | default/OLB | Importers | default/OLB | cic_olb.olb:CGSO$WINDOW_1 |

Graphics objects on canvases (boilerplate, from XML):

| Canvas | Name | Type | Subclassed from |
|---|---|---|---|
| LSIDE | LINE617 | not in XML (OLB sub-object) | – |
| TITLE | RECT9 | not in XML (OLB sub-object) | – |
| TITLE | RECT10 | not in XML (OLB sub-object) | – |
| CG$PAGE_1 | CG_BOILERPLATE_GROUP | Group | – |
| CG$PAGE_1 | CG_RECT_1 | not in XML (OLB sub-object) | CIC_OLB.OLB:CG_RECT |


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
| 15 | CG$WHEN_NEW_FORM_INSTANCE | Procedure | 12 / 9 | FORM.KEY-CLRFRM, FORM.WHEN-NEW-FORM-INSTANCE | – | CGDV$POPULATE_DYNAMIC_LISTS | CGTE$OTHER_EXCEPTIONS |
| 16 | CGDV$POPULATE_DYNAMIC_LISTS | Procedure | 25 / 21 | PU CG$WHEN_NEW_FORM_INSTANCE | CREATE_GROUP_FROM_QUERY, DELETE_GROUP, POPULATE_GROUP, POPULATE_LIST | – | – |
| 17 | CGFK$QRY_IMPORTERS_IMP_SDP_FK | Procedure | 22 / 20 | IMPORTERS.POST-QUERY | – | – | – |
| 18 | CGFK$CHK_IMPORTERS_IMP_SDP_FK | Procedure | 22 / 20 | IMPORTERS.PORT_CD.WHEN-VALIDATE-ITEM | – | – | – |
| 19 | CG$IMPR1130_PROD_CENTRL_GLOBAL | Package Spec | 4 / 3 | IMPORTERS.POST-QUERY, IMPORTERS.PRE-QUERY | – | – | – |
| 20 | CGFK$CHK_IMPORTERS_IMP_MB_FK | Procedure | 22 / 20 | not referenced in XML code | – | – | CG$DUMMY |
| 21 | CGFK$QRY_IMPORTERS_IMP_ITIDT_F | Procedure | 37 / 35 | IMPORTERS.POST-QUERY | – | – | – |
| 22 | CGFK$CHK_IMPORTERS_IMP_ITIDT_F | Procedure | 37 / 35 | IMPORTERS.IMPR_TYPE_CD.WHEN-VALIDATE-ITEM | – | – | – |
| 23 | CGFK$QRY_IMPORTERS_IMP_CTRY_FK | Procedure | 25 / 23 | IMPORTERS.POST-QUERY | – | – | – |
| 24 | CGFK$CHK_IMPORTERS_IMP_CTRY_FK | Procedure | 26 / 24 | IMPORTERS.CTRY_CD.WHEN-VALIDATE-ITEM | – | – | – |
| 25 | CGFK$QRY_IMPORTERS_IMP_BUS_ID_ | Procedure | 34 / 32 | IMPORTERS.POST-QUERY | – | – | – |
| 26 | CGFK$CHK_IMPORTERS_IMP_BUS_ID_ | Procedure | 35 / 33 | IMPORTERS.CITY_CODE_OF_ID.WHEN-VALIDATE-ITEM | – | – | – |
| 27 | CGSF$CLRLU_IMPORTERS_IMP_BUS_I | Procedure | 20 / 18 | IMPORTERS.CITY_CODE_OF_ID.WHEN-VALIDATE-ITEM, IMPORTERS.CTRY_CD_OF_ID.WHEN-VALIDATE-ITEM, IMPORTERS.PRE-INSERT | – | – | – |
| 28 | CGFK$QRY_IMPORTERS_IMP_ADD_CIT | Procedure | 34 / 32 | IMPORTERS.POST-QUERY | – | – | – |
| 29 | CGFK$CHK_IMPORTERS_IMP_ADD_CIT | Procedure | 35 / 33 | IMPORTERS.ADD_CTRY_CD.WHEN-VALIDATE-ITEM, IMPORTERS.CITY_CODE.WHEN-VALIDATE-ITEM | – | – | – |
| 30 | CGRI$CHK_IMPORTERS | Procedure | 779 / 669 | IMPORTERS.KEY-DELREC, IMPORTERS.PRE-DELETE | – | – | CG$DUMMY, DES$FORM_ERRORS.MSGGETTEXT, DES$FORM_ERRORS.PUSH, DES$FORM_ERRORS.RAISE_FAILURE |
| 31 | CGTE$CHECK_CONSTRAINT_VIO | Function | 53 / 45 | IMPORTERS.ON-ERROR | – | – | CGTE$STRIP_CONSTRAINT, CGTE$STRIP_FIRST_ERROR, DES$FORM_ERRORS.MSGGETTEXT, DES$FORM_ERRORS.PUSH |
| 32 | UPDATE_IMPORTER | Procedure | 97 / 64 | PU EXEC_FUNS | FORMS_DDL | – | LIB_USR.IMPR_UTILITIES.UPDATE_IMPORTERS_NAMES, STR.DISPALERT |
| 33 | INSERT_AUDIT_RECORD | Procedure | 32 / 23 | IMPORTERS.POST-INSERT, IMPORTERS.PRE-UPDATE | RAISE FORM_TRIGGER_FAILURE | – | STR.DISPARBMSG |
| 34 | GET_MAIN_CR_DATA | Procedure | 18 / 17 | IMPORTERS.NATIONAL_NBR.WHEN-VALIDATE-ITEM | – | GET_CR_DATA | MCISERVICE.GETMAINCRINFOCALL |
| 35 | GET_CR_DATA | Procedure | 182 / 165 | PU GET_BRANCH_CR_DATA, PU GET_MAIN_CR_DATA | SET_ITEM_PROPERTY, SYNCHRONIZE | – | STR.DISPALERT, STR_DB.STRFORMAT |
| 36 | GET_BRANCH_CR_DATA | Procedure | 19 / 17 | IMPORTERS.NATIONAL_NBR.WHEN-VALIDATE-ITEM | – | GET_CR_DATA | MCISERVICE.GETBRANCHCRINFOCALL |
| 37 | EXEC_FUNS | Procedure | 6 / 6 | PU EXECUTE_FUNCTION | – | UPDATE_IMPORTER | – |
| 38 | DEV_VERSIONS | Procedure | 16 / 4 | not referenced in XML code | – | – | – |
| 39 | CHK_IMPR_DUPL | Procedure | 66 / 58 | IMPORTERS.BUS_ID_BRNCH.KEY-NEXT-ITEM, IMPORTERS.BUS_ID_BRNCH.WHEN-VALIDATE-ITEM, IMPORTERS.PRE-INSERT | SYNCHRONIZE, RAISE FORM_TRIGGER_FAILURE | – | STR.DISPALERT |
| 40 | CALL_LOV_COUNTRIES | Procedure | 44 / 31 | IMPORTERS.CTRY_CD.KEY-LISTVAL | ADD_PARAMETER, CALL_FORM, CREATE_PARAMETER_LIST, DESTROY_PARAMETER_LIST, GET_PARAMETER_LIST, ID_NULL, RAISE FORM_TRIGGER_FAILURE | – | STR.DISPALERT |
| 41 | CALL_LOV_COUN_GULF | Procedure | 43 / 31 | IMPORTERS.CTRY_CD.KEY-LISTVAL | ADD_PARAMETER, CALL_FORM, CREATE_PARAMETER_LIST, DESTROY_PARAMETER_LIST, GET_PARAMETER_LIST, ID_NULL, RAISE FORM_TRIGGER_FAILURE | – | STR.DISPALERT |
| 42 | ADJ_FUNS | Procedure | 8 / 8 | FORM.KEY-F9, TOOLBAR.FUN_BUT.WHEN-MOUSE-DOWN | – | – | TMPLT.DISABLE_FUN, TMPLT.ENABLE_FUN |

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

### PU CG$WHEN_NEW_FORM_INSTANCE (Procedure, 12 lines)

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
END;
```

### PU CGDV$POPULATE_DYNAMIC_LISTS (Procedure, 25 lines)

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
  populate_list('IMPORTERS.COMM_RGSTRTN_TYPE', rg_id);
  delete_group(rg_id);

  rg_id := create_group_from_query('CGDV$DLRG',
    'SELECT RV_MEANING, RV_LOW_VALUE '||
    'FROM   CG_REF_CODES '||
    'WHERE  RV_DOMAIN = ''ALLOWED EXPORT'' '||
    'ORDER BY  2');
  temp := populate_group(rg_id);
  populate_list('IMPORTERS.IMPR_EXPR_TYPE', rg_id);
  delete_group(rg_id);

END;
```

### PU CGFK$QRY_IMPORTERS_IMP_SDP_FK (Procedure, 22 lines)

```plsql
/* CGFK$QRY_IMPORTERS_IMP_SDP_FK */
PROCEDURE CGFK$QRY_IMPORTERS_IMP_SDP_FK(
   P_PORT_NAME IN OUT VARCHAR2      /* Value in Item :IMPORTERS.PORT_NAME. */
  ,P_PORT_CD   IN     NUMBER  ) IS  /* Value in Item :IMPORTERS.PORT_CD.   */
/* Query foreign key value/query lookup data. */
BEGIN
  DECLARE
    CURSOR C IS
      SELECT L_SDP.PORT_NAME
      FROM   SD_PORTS L_SDP
      WHERE  L_SDP.PORT_CD = P_PORT_CD;
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

### PU CGFK$CHK_IMPORTERS_IMP_SDP_FK (Procedure, 22 lines)

```plsql
/* CGFK$CHK_IMPORTERS_IMP_SDP_FK */
PROCEDURE CGFK$CHK_IMPORTERS_IMP_SDP_FK(
   P_PORT_NAME IN OUT VARCHAR2      /* Value in Item :IMPORTERS.PORT_NAME. */
  ,P_PORT_CD   IN     NUMBER  ) IS  /* Value in Item :IMPORTERS.PORT_CD.   */
/* Validate foreign key value/query lookup data. */
BEGIN
  DECLARE
    CURSOR C IS
      SELECT L_SDP.PORT_NAME
      FROM   SD_PORTS L_SDP
      WHERE  L_SDP.PORT_CD = P_PORT_CD;
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

### PU CG$IMPR1130_PROD_CENTRL_GLOBAL (Package Spec, 4 lines)

```plsql
/* CG$IMPR1130_PROD_CENTRL_GLOBAL */
PACKAGE CG$IMPR1130_PROD_CENTRL_GLOBAL IS
IMPORTERS_WHERE VARCHAR2(2000) := 'first_time'; /* Block default where clause */
END;
```

### PU CGFK$CHK_IMPORTERS_IMP_MB_FK (Procedure, 22 lines)

```plsql
/* CGFK$CHK_IMPORTERS_IMP_MB_FK */
PROCEDURE CGFK$CHK_IMPORTERS_IMP_MB_FK(
   P_BUS_ID_STATUS IN VARCHAR2) IS  /* Value in Item :IMPORTERS.BUS_ID_STATUS. */
/* Validate foreign key value/query lookup data. */
  CG$DUMMY VARCHAR2(1);
BEGIN
  DECLARE
    CURSOR C IS
      SELECT  '1'
      FROM   MCI_BUS_ID_STATUS
      WHERE  BUS_ID_STATUS = P_BUS_ID_STATUS;
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

### PU CGFK$QRY_IMPORTERS_IMP_ITIDT_F (Procedure, 37 lines)

```plsql
/* CGFK$QRY_IMPORTERS_IMP_ITIDT_F */
PROCEDURE CGFK$QRY_IMPORTERS_IMP_ITIDT_F(
   P_BUS_ID_TYPE_NAME IN OUT VARCHAR2      /* Value in Item :IMPORTERS.BUS_ID_TYPE_NAME. */
  ,P_IMPR_TYPE_NAME   IN OUT VARCHAR2      /* Value in Item :IMPORTERS.IMPR_TYPE_NAME.   */
  ,P_STATUS           IN OUT NUMBER        /* Value in Item :IMPORTERS.STATUS.           */
  ,P_ITIDT_NOTE       IN OUT VARCHAR2      /* Value in Item :IMPORTERS.ITIDT_NOTE.       */
  ,P_IMPR_TYPE_CD     IN     NUMBER        /* Value in Item :IMPORTERS.IMPR_TYPE_CD.     */
  ,P_BUS_ID_TYPE_CD   IN     NUMBER  ) IS  /* Value in Item :IMPORTERS.BUS_ID_TYPE_CD.   */
/* Query foreign key value/query lookup data. */
BEGIN
  DECLARE
    CURSOR C IS
      SELECT ITIDT.NOTE
            ,ITIDT.STATUS
            ,IT.IMPR_TYPE_NAME
            ,BIT.BUS_ID_TYPE_NAME
      FROM   IMPR_TYPE_ID_TYPES ITIDT
            ,IMPR_TYPES IT
            ,BUS_ID_TYPES BIT
      WHERE  ITIDT.BUS_ID_TYPE_CD = P_BUS_ID_TYPE_CD
      AND    ITIDT.IMPR_TYPE_CD = P_IMPR_TYPE_CD
      AND    IT.IMPR_TYPE_CD = ITIDT.IMPR_TYPE_CD
      AND    BIT.BUS_ID_TYPE_CD = ITIDT.BUS_ID_TYPE_CD;
  BEGIN
    OPEN C;
    FETCH C
    INTO    P_ITIDT_NOTE
          , P_STATUS
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
  ,P_ITIDT_NOTE       IN OUT VARCHAR2      /* Value in Item :IMPORTERS.ITIDT_NOTE.       */
  ,P_IMPR_TYPE_CD     IN     NUMBER        /* Value in Item :IMPORTERS.IMPR_TYPE_CD.     */
  ,P_BUS_ID_TYPE_CD   IN     NUMBER  ) IS  /* Value in Item :IMPORTERS.BUS_ID_TYPE_CD.   */
/* Validate foreign key value/query lookup data. */
BEGIN
  DECLARE
    CURSOR C IS
      SELECT ITIDT.NOTE
            ,ITIDT.STATUS
            ,IT.IMPR_TYPE_NAME
            ,BIT.BUS_ID_TYPE_NAME
      FROM   IMPR_TYPE_ID_TYPES ITIDT
            ,IMPR_TYPES IT
            ,BUS_ID_TYPES BIT
      WHERE  ITIDT.BUS_ID_TYPE_CD = P_BUS_ID_TYPE_CD
      AND    ITIDT.IMPR_TYPE_CD = P_IMPR_TYPE_CD
      AND    IT.IMPR_TYPE_CD = ITIDT.IMPR_TYPE_CD
      AND    BIT.BUS_ID_TYPE_CD = ITIDT.BUS_ID_TYPE_CD;
  BEGIN
    OPEN C;
    FETCH C
    INTO    P_ITIDT_NOTE
          , P_STATUS
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

### PU CGFK$QRY_IMPORTERS_IMP_BUS_ID_ (Procedure, 34 lines)

```plsql
/* CGFK$QRY_IMPORTERS_IMP_BUS_ID_ */
PROCEDURE CGFK$QRY_IMPORTERS_IMP_BUS_ID_(
   P_ID_MINS_COMM_CD   IN OUT NUMBER        /* Value in Item :IMPORTERS.ID_MINS_COMM_CD.   */
  ,P_ID_CITY_NAME      IN OUT VARCHAR2      /* Value in Item :IMPORTERS.ID_CITY_NAME.      */
  ,P_L_CT_CITY_STATUS2 IN OUT NUMBER        /* Value in Item :IMPORTERS.L_CT_CITY_STATUS2. */
  ,P_CTRY_CD_OF_ID     IN     NUMBER        /* Value in Item :IMPORTERS.CTRY_CD_OF_ID.     */
  ,P_CITY_CODE_OF_ID   IN     NUMBER  ) IS  /* Value in Item :IMPORTERS.CITY_CODE_OF_ID.   */
/* Query foreign key value/query lookup data. */
BEGIN
  DECLARE
    CURSOR C IS
      SELECT ID_CITY.CITY_STATUS
            ,ID_CITY.CITY_ARB_NAME
            ,ID_CITY.MINS_COMM_CD
      FROM   CITIES ID_CITY
      WHERE  (ID_CITY.CITY_CD = P_CITY_CODE_OF_ID OR
             (ID_CITY.CITY_CD IS NULL AND
              P_CITY_CODE_OF_ID IS NULL ))
      AND    (ID_CITY.CTRY_CD = P_CTRY_CD_OF_ID OR
             (ID_CITY.CTRY_CD IS NULL AND
              P_CTRY_CD_OF_ID IS NULL ));
  BEGIN
    OPEN C;
    FETCH C
    INTO    P_L_CT_CITY_STATUS2
          , P_ID_CITY_NAME
          , P_ID_MINS_COMM_CD;
    IF C%NOTFOUND THEN
      CLOSE C;
      RAISE NO_DATA_FOUND;
    END IF;
    CLOSE C;
  END;
END;
```

### PU CGFK$CHK_IMPORTERS_IMP_BUS_ID_ (Procedure, 35 lines)

```plsql
/* CGFK$CHK_IMPORTERS_IMP_BUS_ID_ */
PROCEDURE CGFK$CHK_IMPORTERS_IMP_BUS_ID_(
   P_ID_MINS_COMM_CD   IN OUT NUMBER        /* Value in Item :IMPORTERS.ID_MINS_COMM_CD.   */
  ,P_ID_CITY_NAME      IN OUT VARCHAR2      /* Value in Item :IMPORTERS.ID_CITY_NAME.      */
  ,P_L_CT_CITY_STATUS2 IN OUT NUMBER        /* Value in Item :IMPORTERS.L_CT_CITY_STATUS2. */
  ,P_CTRY_CD_OF_ID     IN     NUMBER        /* Value in Item :IMPORTERS.CTRY_CD_OF_ID.     */
  ,P_CITY_CODE_OF_ID   IN     NUMBER  ) IS  /* Value in Item :IMPORTERS.CITY_CODE_OF_ID.   */
/* Validate foreign key value/query lookup data. */
BEGIN
  DECLARE
    CURSOR C IS
      SELECT ID_CITY.CITY_STATUS
            ,ID_CITY.CITY_ARB_NAME
            ,ID_CITY.MINS_COMM_CD
      FROM   CITIES ID_CITY
      WHERE  (ID_CITY.CITY_CD = P_CITY_CODE_OF_ID OR
             (ID_CITY.CITY_CD IS NULL AND
              P_CITY_CODE_OF_ID IS NULL ))
      AND    (ID_CITY.CTRY_CD = P_CTRY_CD_OF_ID OR
             (ID_CITY.CTRY_CD IS NULL AND
              P_CTRY_CD_OF_ID IS NULL ))
      AND    ID_CITY.CITY_STATUS = 1;
  BEGIN
    OPEN C;
    FETCH C
    INTO    P_L_CT_CITY_STATUS2
          , P_ID_CITY_NAME
          , P_ID_MINS_COMM_CD;
    IF C%NOTFOUND THEN
      CLOSE C;
      RAISE NO_DATA_FOUND;
    END IF;
    CLOSE C;
  END;
END;
```

### PU CGSF$CLRLU_IMPORTERS_IMP_BUS_I (Procedure, 20 lines)

```plsql
/* CGSF$CLRLU_IMPORTERS_IMP_BUS_I */
PROCEDURE CGSF$CLRLU_IMPORTERS_IMP_BUS_I IS
/* This clears all items associated with the given foreign key. */
BEGIN
  IF (:IMPORTERS.CITY_CODE_OF_ID IS NOT NULL) THEN
    :IMPORTERS.CITY_CODE_OF_ID := NULL;
  END IF;
  IF (:IMPORTERS.CTRY_CD_OF_ID IS NOT NULL) THEN
    :IMPORTERS.CTRY_CD_OF_ID := NULL;
  END IF;
  IF (:IMPORTERS.L_CT_CITY_STATUS2 IS NOT NULL) THEN
    :IMPORTERS.L_CT_CITY_STATUS2 := NULL;
  END IF;
  IF (:IMPORTERS.ID_CITY_NAME IS NOT NULL) THEN
    :IMPORTERS.ID_CITY_NAME := NULL;
  END IF;
  IF (:IMPORTERS.ID_MINS_COMM_CD IS NOT NULL) THEN
    :IMPORTERS.ID_MINS_COMM_CD := NULL;
  END IF;
END;
```

### PU CGFK$QRY_IMPORTERS_IMP_ADD_CIT (Procedure, 34 lines)

```plsql
/* CGFK$QRY_IMPORTERS_IMP_ADD_CIT */
PROCEDURE CGFK$QRY_IMPORTERS_IMP_ADD_CIT(
   P_ADD_CRTY_ARBC_NAME IN OUT VARCHAR2      /* Value in Item :IMPORTERS.ADD_CRTY_ARBC_NAME. */
  ,P_CITY_NAME          IN OUT VARCHAR2      /* Value in Item :IMPORTERS.CITY_NAME.          */
  ,P_L_CT_CITY_STATUS   IN OUT NUMBER        /* Value in Item :IMPORTERS.L_CT_CITY_STATUS.   */
  ,P_CITY_CODE          IN     NUMBER        /* Value in Item :IMPORTERS.CITY_CODE.          */
  ,P_ADD_CTRY_CD        IN     NUMBER  ) IS  /* Value in Item :IMPORTERS.ADD_CTRY_CD.        */
/* Query foreign key value/query lookup data. */
BEGIN
  DECLARE
    CURSOR C IS
      SELECT ADD_CITY.CITY_STATUS
            ,ADD_CITY.CITY_ARB_NAME
            ,L_CTRY.CRTY_ARBC_NAME
      FROM   CITIES ADD_CITY
            ,COUNTRIES L_CTRY
      WHERE  ADD_CITY.CTRY_CD = P_ADD_CTRY_CD
      AND    (ADD_CITY.CITY_CD = P_CITY_CODE OR
             (ADD_CITY.CITY_CD IS NULL AND
              P_CITY_CODE IS NULL ))
      AND    L_CTRY.CTRY_CD = ADD_CITY.CTRY_CD;
  BEGIN
    OPEN C;
    FETCH C
    INTO    P_L_CT_CITY_STATUS
          , P_CITY_NAME
          , P_ADD_CRTY_ARBC_NAME;
    IF C%NOTFOUND THEN
      CLOSE C;
      RAISE NO_DATA_FOUND;
    END IF;
    CLOSE C;
  END;
END;
```

### PU CGFK$CHK_IMPORTERS_IMP_ADD_CIT (Procedure, 35 lines)

```plsql
/* CGFK$CHK_IMPORTERS_IMP_ADD_CIT */
PROCEDURE CGFK$CHK_IMPORTERS_IMP_ADD_CIT(
   P_ADD_CRTY_ARBC_NAME IN OUT VARCHAR2      /* Value in Item :IMPORTERS.ADD_CRTY_ARBC_NAME. */
  ,P_CITY_NAME          IN OUT VARCHAR2      /* Value in Item :IMPORTERS.CITY_NAME.          */
  ,P_L_CT_CITY_STATUS   IN OUT NUMBER        /* Value in Item :IMPORTERS.L_CT_CITY_STATUS.   */
  ,P_CITY_CODE          IN     NUMBER        /* Value in Item :IMPORTERS.CITY_CODE.          */
  ,P_ADD_CTRY_CD        IN     NUMBER  ) IS  /* Value in Item :IMPORTERS.ADD_CTRY_CD.        */
/* Validate foreign key value/query lookup data. */
BEGIN
  DECLARE
    CURSOR C IS
      SELECT ADD_CITY.CITY_STATUS
            ,ADD_CITY.CITY_ARB_NAME
            ,L_CTRY.CRTY_ARBC_NAME
      FROM   CITIES ADD_CITY
            ,COUNTRIES L_CTRY
      WHERE  ADD_CITY.CTRY_CD = P_ADD_CTRY_CD
      AND    (ADD_CITY.CITY_CD = P_CITY_CODE OR
             (ADD_CITY.CITY_CD IS NULL AND
              P_CITY_CODE IS NULL ))
      AND    ADD_CITY.CITY_STATUS = 1
      AND    L_CTRY.CTRY_CD = ADD_CITY.CTRY_CD;
  BEGIN
    OPEN C;
    FETCH C
    INTO    P_L_CT_CITY_STATUS
          , P_CITY_NAME
          , P_ADD_CRTY_ARBC_NAME;
    IF C%NOTFOUND THEN
      CLOSE C;
      RAISE NO_DATA_FOUND;
    END IF;
    CLOSE C;
  END;
END;
```

### PU CGRI$CHK_IMPORTERS (Procedure, 779 lines)

```plsql
/* CGRI$CHK_IMPORTERS */
PROCEDURE CGRI$CHK_IMPORTERS(
   P_CHECK_BOTH IN BOOLEAN      /* Check FKs validated in BOTH (client/server)? */
  ,P_IMPR_NBR   IN NUMBER       /* Item value                                   */
  ,P_PORT_CD    IN NUMBER ) IS  /* Item value                                   */
/* Validate that the deletion of the record is permitted    */
/* by checking for the existence of rows in related tables. */
  CG$DUMMY VARCHAR2(1);  /* Dummy variable */
BEGIN
  /* Deletion of IMPORTERS prevented if AGNTS records exist */
  /* Foreign key(s): AG_IMP_AGENT_ID_FK                     */
  DECLARE
    CURSOR C IS
      SELECT  '1'
      FROM    AGNTS AG
      WHERE   AG.IMPR_NBR_AGENT_ID = P_IMPR_NBR
      AND     AG.PORT_CD = P_PORT_CD;
  BEGIN
    OPEN C;
    FETCH C
    INTO    CG$DUMMY;
    IF C%FOUND THEN
      CLOSE C;
      Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(5, 'Cannot delete <p1> while dependent <p2> exists', 'IMPORTERS','AGNTS' ), 'E', 'OFG', 5);
      Des$Form_errors.RAISE_FAILURE;
    END IF;
    CLOSE C;
  END;

  /* Deletion of IMPORTERS prevented if AGNTS records exist */
  /* Foreign key(s): AG_IMP_FK                              */
  DECLARE
    CURSOR C IS
      SELECT  '1'
      FROM    AGNTS AG
      WHERE   AG.IMPR_NBR = P_IMPR_NBR
      AND     AG.PORT_CD = P_PORT_CD;
  BEGIN
    OPEN C;
    FETCH C
    INTO    CG$DUMMY;
    IF C%FOUND THEN
      CLOSE C;
      Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(5, 'Cannot delete <p1> while dependent <p2> exists', 'IMPORTERS','AGNTS' ), 'E', 'OFG', 5);
      Des$Form_errors.RAISE_FAILURE;
    END IF;
    CLOSE C;
  END;

  /* Deletion of IMPORTERS prevented if PASSENGER_TRIPS records exist */
  /* Foreign key(s): PT_IMP_FK                                        */
  DECLARE
    CURSOR C IS
      SELECT  '1'
      FROM    PASSENGER_TRIPS PTR
      WHERE   (PTR.IMPR_NBR = P_IMPR_NBR OR
              (PTR.IMPR_NBR IS NULL AND
               P_IMPR_NBR IS NULL ))
      AND     PTR.PORT_CD = P_PORT_CD;
  BEGIN
    OPEN C;
    FETCH C
    INTO    CG$DUMMY;
    IF C%FOUND THEN
      CLOSE C;
      Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(5, 'Cannot delete <p1> while dependent <p2> exists', 'جدول المستوردين','جدول  رحلات الركاب' ), 'E', 'OFG', 5);
      Des$Form_errors.RAISE_FAILURE;
    END IF;
    CLOSE C;
  END;

  /* Deletion of IMPORTERS prevented if DELAY_AIR_DLVY_ORDERS records exist */
  /* Foreign key(s): DA_IMP_FK                                              */
  DECLARE
    CURSOR C IS
      SELECT  '1'
      FROM    DELAY_AIR_DLVY_ORDERS DA
      WHERE   (DA.IMPR_NBR = P_IMPR_NBR OR
              (DA.IMPR_NBR IS NULL AND
               P_IMPR_NBR IS NULL ))
      AND     DA.PORT_CD = P_PORT_CD;
  BEGIN
    OPEN C;
    FETCH C
    INTO    CG$DUMMY;
    IF C%FOUND THEN
      CLOSE C;
      Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(5, 'Cannot delete <p1> while dependent <p2> exists', 'IMPORTERS','DELAY_AIR_DLVY_ORDERS' ), 'E', 'OFG', 5);
      Des$Form_errors.RAISE_FAILURE;
    END IF;
    CLOSE C;
  END;

  /* Deletion of IMPORTERS prevented if IMPR_SUSPNS records exist */
  /* Foreign key(s): IS_1_IMP_FK                                  */
  DECLARE
    CURSOR C IS
      SELECT  '1'
      FROM    IMPR_SUSPNS IS_1
      WHERE   IS_1.PORT_CD = P_PORT_CD
      AND     IS_1.IMPR_NBR = P_IMPR_NBR;
  BEGIN
    OPEN C;
    FETCH C
    INTO    CG$DUMMY;
    IF C%FOUND THEN
      CLOSE C;
      Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(5, 'Cannot delete <p1> while dependent <p2> exists', 'جدول المستوردين','توقيفات المستوردين' ), 'E', 'OFG', 5);
      Des$Form_errors.RAISE_FAILURE;
    END IF;
    CLOSE C;
  END;

  /* Deletion of IMPORTERS prevented if BL_OWNER_HIST records exist */
  /* Foreign key(s): BLOH_IMP_FK                                    */
  DECLARE
    CURSOR C IS
      SELECT  '1'
      FROM    BL_OWNER_HIST BLOH
      WHERE   BLOH.PORT_CD = P_PORT_CD
      AND     (BLOH.IMPR_NBR = P_IMPR_NBR OR
              (BLOH.IMPR_NBR IS NULL AND
               P_IMPR_NBR IS NULL ));
  BEGIN
    OPEN C;
    FETCH C
    INTO    CG$DUMMY;
    IF C%FOUND THEN
      CLOSE C;
      Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(5, 'Cannot delete <p1> while dependent <p2> exists', 'جدول المستوردين','Bl Owner Hist' ), 'E', 'OFG', 5);
      Des$Form_errors.RAISE_FAILURE;
    END IF;
    CLOSE C;
  END;

  /* Deletion of IMPORTERS prevented if REV_SECTIONS_CASH_DTLS records exist */
  /* Foreign key(s): RCDS_IMP_FK                                             */
  DECLARE
    CURSOR C IS
      SELECT  '1'
      FROM    REV_SECTIONS_CASH_DTLS RSDC
      WHERE   RSDC.PORT_CD = P_PORT_CD
      AND     (RSDC.IMPR_NBR = P_IMPR_NBR OR
              (RSDC.IMPR_NBR IS NULL AND
               P_IMPR_NBR IS NULL ));
  BEGIN
    OPEN C;
    FETCH C
    INTO    CG$DUMMY;
    IF C%FOUND THEN
      CLOSE C;
      Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(5, 'Cannot delete <p1> while dependent <p2> exists', 'IMPORTERS','REV_SECTIONS_CASH_DTLS' ), 'E', 'OFG', 5);
      Des$Form_errors.RAISE_FAILURE;
    END IF;
    CLOSE C;
  END;

  /* Deletion of IMPORTERS prevented if SEA_DLVY_ORDERS records exist */
  /* Foreign key(s): SDO_IMP_FK                                       */
  DECLARE
    CURSOR C IS
      SELECT  '1'
      FROM    SEA_DLVY_ORDERS SDO
      WHERE   (SDO.IMPR_NBR = P_IMPR_NBR OR
              (SDO.IMPR_NBR IS NULL AND
               P_IMPR_NBR IS NULL ))
      AND     SDO.PORT_CD = P_PORT_CD;
  BEGIN
    OPEN C;
    FETCH C
    INTO    CG$DUMMY;
    IF C%FOUND THEN
      CLOSE C;
      Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(5, 'Cannot delete <p1> while dependent <p2> exists', 'جدول المستوردين','اذن التسليم' ), 'E', 'OFG', 5);
      Des$Form_errors.RAISE_FAILURE;
    END IF;
    CLOSE C;
  END;

  /* Deletion of IMPORTERS prevented if IMPR_KNWNS records exist */
  /* Foreign key(s): IK_IMP_FK                                   */
  DECLARE
    CURSOR C IS
      SELECT  '1'
      FROM    IMPR_KNWNS IK
      WHERE   IK.PORT_CD = P_PORT_CD
      AND     IK.IMPR_NBR = P_IMPR_NBR;
  BEGIN
    OPEN C;
    FETCH C
    INTO    CG$DUMMY;
    IF C%FOUND THEN
      CLOSE C;
      Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(5, 'Cannot delete <p1> while dependent <p2> exists', 'جدول المستوردين','الكلمات المميزه' ), 'E', 'OFG', 5);
      Des$Form_errors.RAISE_FAILURE;
    END IF;
    CLOSE C;
  END;

  /* Deletion of IMPORTERS prevented if BRKR_UPDTS records exist */
  /* Foreign key(s): BU_IMP_FK                                   */
  DECLARE
    CURSOR C IS
      SELECT  '1'
      FROM    BRKR_UPDTS BU
      WHERE   (BU.IMPR_NBR = P_IMPR_NBR OR
              (BU.IMPR_NBR IS NULL AND
               P_IMPR_NBR IS NULL ))
      AND     BU.PORT_CD = P_PORT_CD;
  BEGIN
    OPEN C;
    FETCH C
    INTO    CG$DUMMY;
    IF C%FOUND THEN
      CLOSE C;
      Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(5, 'Cannot delete <p1> while dependent <p2> exists', 'جدول المستوردين','ملف الأنشطة للمخلصين' ), 'E', 'OFG', 5);
      Des$Form_errors.RAISE_FAILURE;
    END IF;
    CLOSE C;
  END;

  /* Deletion of IMPORTERS prevented if BA_OWNERSHIPS records exist */
  /* Foreign key(s): BOW_IMP_FK                                     */
  DECLARE
    CURSOR C IS
      SELECT  '1'
      FROM    BA_OWNERSHIPS BOW
      WHERE   (BOW.IMPR_NBR = P_IMPR_NBR OR
              (BOW.IMPR_NBR IS NULL AND
               P_IMPR_NBR IS NULL ))
      AND     BOW.PORT_CD = P_PORT_CD;
  BEGIN
    OPEN C;
    FETCH C
    INTO    CG$DUMMY;
    IF C%FOUND THEN
      CLOSE C;
      Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(5, 'Cannot delete <p1> while dependent <p2> exists', 'IMPORTERS','BA_OWNERSHIPS' ), 'E', 'OFG', 5);
      Des$Form_errors.RAISE_FAILURE;
    END IF;
    CLOSE C;
  END;

  /* Deletion of IMPORTERS prevented if BRKR_MSTR records exist */
  /* Foreign key(s): BKM_IMP_FK                                 */
  DECLARE
    CURSOR C IS
      SELECT  '1'
      FROM    BRKR_MSTR BKM
      WHERE   BKM.IMPR_NBR = P_IMPR_NBR
      AND     BKM.PORT_CD = P_PORT_CD;
  BEGIN
    OPEN C;
    FETCH C
    INTO    CG$DUMMY;
    IF C%FOUND THEN
      CLOSE C;
      Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(5, 'Cannot delete <p1> while dependent <p2> exists', 'جدول المستوردين','المخلصين' ), 'E', 'OFG', 5);
      Des$Form_errors.RAISE_FAILURE;
    END IF;
    CLOSE C;
  END;

  /* Deletion of IMPORTERS prevented if EXMTN_DECREES records exist */
  /* Foreign key(s): XD_IMP_FK                                      */
  DECLARE
    CURSOR C IS
      SELECT  '1'
      FROM    EXMTN_DECREES XD
      WHERE   (XD.IMP_IMPR_NBR = P_IMPR_NBR OR
              (XD.IMP_IMPR_NBR IS NULL AND
               P_IMPR_NBR IS NULL ))
      AND     (XD.IMP_PORT_CD = P_PORT_CD OR
              (XD.IMP_PORT_CD IS NULL AND
               P_PORT_CD IS NULL ));
  BEGIN
    OPEN C;
    FETCH C
    INTO    CG$DUMMY;
    IF C%FOUND THEN
      CLOSE C;
      Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(5, 'Cannot delete <p1> while dependent <p2> exists', 'جدول المستوردين','قرارات الإعفاء' ), 'E', 'OFG', 5);
      Des$Form_errors.RAISE_FAILURE;
    END IF;
    CLOSE C;
  END;

  /* Deletion of IMPORTERS prevented if IMPR_UPDTS records exist */
  /* Foreign key(s): IU_IMP_FK                                   */
  DECLARE
    CURSOR C IS
      SELECT  '1'
      FROM    IMPR_UPDTS IU
      WHERE   IU.PORT_CD = P_PORT_CD
      AND     IU.IMPR_NBR = P_IMPR_NBR;
  BEGIN
    OPEN C;
    FETCH C
    INTO    CG$DUMMY;
    IF C%FOUND THEN
      CLOSE C;
      Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(5, 'Cannot delete <p1> while dependent <p2> exists', 'جدول المستوردين','تعديلات المستوردين' ), 'E', 'OFG', 5);
      Des$Form_errors.RAISE_FAILURE;
    END IF;
    CLOSE C;
  END;

  /* Deletion of IMPORTERS prevented if LFT_SALES records exist */
  /* Foreign key(s): LS_IMP_FK                                  */
  DECLARE
    CURSOR C IS
      SELECT  '1'
      FROM    LFT_SALES LS
      WHERE   (LS.IMPR_NBR = P_IMPR_NBR OR
              (LS.IMPR_NBR IS NULL AND
               P_IMPR_NBR IS NULL ))
      AND     LS.PORT_CD = P_PORT_CD;
  BEGIN
    OPEN C;
    FETCH C
    INTO    CG$DUMMY;
    IF C%FOUND THEN
      CLOSE C;
      Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(5, 'Cannot delete <p1> while dependent <p2> exists', 'IMPORTERS','LFT_SALES' ), 'E', 'OFG', 5);
      Des$Form_errors.RAISE_FAILURE;
    END IF;
    CLOSE C;
  END;

  /* Deletion of IMPORTERS prevented if DPLMTC_APLCTNS records exist */
  /* Foreign key(s): DAP_IMP_FK                                      */
  DECLARE
    CURSOR C IS
      SELECT  '1'
      FROM    DPLMTC_APLCTNS DAP
      WHERE   (DAP.IMP_IMPR_NBR = P_IMPR_NBR OR
              (DAP.IMP_IMPR_NBR IS NULL AND
               P_IMPR_NBR IS NULL ))
      AND     (DAP.IMP_PORT_CD = P_PORT_CD OR
              (DAP.IMP_PORT_CD IS NULL AND
               P_PORT_CD IS NULL ));
  BEGIN
    OPEN C;
    FETCH C
    INTO    CG$DUMMY;
    IF C%FOUND THEN
      CLOSE C;
      Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(5, 'Cannot delete <p1> while dependent <p2> exists', 'IMPORTERS','DPLMTC_APLCTNS' ), 'E', 'OFG', 5);
      Des$Form_errors.RAISE_FAILURE;
    END IF;
    CLOSE C;
  END;

  /* Deletion of IMPORTERS prevented if CSTMS_CLNTS records exist */
  /* Foreign key(s): CSTMS_CLNT_IMP_FK                            */
  DECLARE
    CURSOR C IS
      SELECT  '1'
      FROM    CSTMS_CLNTS CSTMS_CLNT
      WHERE   (CSTMS_CLNT.IMP_IMPR_NBR = P_IMPR_NBR OR
              (CSTMS_CLNT.IMP_IMPR_NBR IS NULL AND
               P_IMPR_NBR IS NULL ))
      AND     (CSTMS_CLNT.IMP_PORT_CD = P_PORT_CD OR
              (CSTMS_CLNT.IMP_PORT_CD IS NULL AND
               P_PORT_CD IS NULL ));
  BEGIN
    OPEN C;
    FETCH C
    INTO    CG$DUMMY;
    IF C%FOUND THEN
      CLOSE C;
      Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(5, 'Cannot delete <p1> while dependent <p2> exists', 'جدول المستوردين','Cstms Clnts' ), 'E', 'OFG', 5);
      Des$Form_errors.RAISE_FAILURE;
    END IF;
    CLOSE C;
  END;

  /* Deletion of IMPORTERS prevented if VHCL_AUCTION records exist */
  /* Foreign key(s): VAU_IMP_FK                                    */
  DECLARE
    CURSOR C IS
      SELECT  '1'
      FROM    VHCL_AUCTION VAU
      WHERE   VAU.PORT_CD = P_PORT_CD
      AND     VAU.IMPR_NBR = P_IMPR_NBR;
  BEGIN
    OPEN C;
    FETCH C
    INTO    CG$DUMMY;
    IF C%FOUND THEN
      CLOSE C;
      Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(5, 'Cannot delete <p1> while dependent <p2> exists', 'جدول المستوردين','ملف مزادات السيارات' ), 'E', 'OFG', 5);
      Des$Form_errors.RAISE_FAILURE;
    END IF;
    CLOSE C;
  END;

  /* Deletion of IMPORTERS prevented if BRKIMPS records exist */
  /* Foreign key(s): BI_IMP_FK                                */
  DECLARE
    CURSOR C IS
      SELECT  '1'
      FROM    BRKIMPS BI
      WHERE   BI.PORT_CD = P_PORT_CD
      AND     BI.IMPR_NBR = P_IMPR_NBR;
  BEGIN
    OPEN C;
    FETCH C
    INTO    CG$DUMMY;
    IF C%FOUND THEN
      CLOSE C;
      Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(5, 'Cannot delete <p1> while dependent <p2> exists', 'جدول المستوردين','تفاويض المخلصين' ), 'E', 'OFG', 5);
      Des$Form_errors.RAISE_FAILURE;
    END IF;
    CLOSE C;
  END;

  /* Deletion of IMPORTERS prevented if SMPL_20_DECLERATIONS records exist */
  /* Foreign key(s): S2D_IMP_FK                                            */
  DECLARE
    CURSOR C IS
      SELECT  '1'
      FROM    SMPL_20_DECLERATIONS S2D
      WHERE   S2D.IMPR_NBR = P_IMPR_NBR
      AND     S2D.PORT_CD = P_PORT_CD;
  BEGIN
    OPEN C;
    FETCH C
    INTO    CG$DUMMY;
    IF C%FOUND THEN
      CLOSE C;
      Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(5, 'Cannot delete <p1> while dependent <p2> exists', 'IMPORTERS','SMPL_20_DECLERATIONS' ), 'E', 'OFG', 5);
      Des$Form_errors.RAISE_FAILURE;
    END IF;
    CLOSE C;
  END;

  /* Deletion of IMPORTERS prevented if DECLARATIONS records exist */
  /* Foreign key(s): DCLTN_MNFCT_IMPR_FK                           */
  DECLARE
    CURSOR C IS
      SELECT  '1'
      FROM    DECLARATIONS DCLTN
      WHERE   DCLTN.PORT_CD = P_PORT_CD
      AND     (DCLTN.MNFCT_NBR = P_IMPR_NBR OR
              (DCLTN.MNFCT_NBR IS NULL AND
               P_IMPR_NBR IS NULL ));
  BEGIN
    OPEN C;
    FETCH C
    INTO    CG$DUMMY;
    IF C%FOUND THEN
      CLOSE C;
      Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(5, 'Cannot delete <p1> while dependent <p2> exists', 'IMPORTERS','DECLARATIONS' ), 'E', 'OFG', 5);
      Des$Form_errors.RAISE_FAILURE;
    END IF;
    CLOSE C;
  END;

  /* Deletion of IMPORTERS prevented if CLIENT_PAY_ACCTS records exist */
  /* Foreign key(s): CPAS_IMP_FK                                       */
  DECLARE
    CURSOR C IS
      SELECT  '1'
      FROM    CLIENT_PAY_ACCTS CPAS
      WHERE   (CPAS.IMPR_NBR = P_IMPR_NBR OR
              (CPAS.IMPR_NBR IS NULL AND
               P_IMPR_NBR IS NULL ))
      AND     CPAS.PORT_CD = P_PORT_CD;
  BEGIN
    OPEN C;
    FETCH C
    INTO    CG$DUMMY;
    IF C%FOUND THEN
      CLOSE C;
      Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(5, 'Cannot delete <p1> while dependent <p2> exists', 'جدول المستوردين','Client pay accts' ), 'E', 'OFG', 5);
      Des$Form_errors.RAISE_FAILURE;
    END IF;
    CLOSE C;
  END;

  /* Deletion of IMPORTERS prevented if DCLTN_DOCS records exist */
  /* Foreign key(s): DCL_DOC_IMP_FK                              */
  DECLARE
    CURSOR C IS
      SELECT  '1'
      FROM    DCLTN_DOCS DCL_DOC
      WHERE   (DCL_DOC.CARRIER_NBR = P_IMPR_NBR OR
              (DCL_DOC.CARRIER_NBR IS NULL AND
               P_IMPR_NBR IS NULL ))
      AND     DCL_DOC.PORT_CD = P_PORT_CD;
  BEGIN
    OPEN C;
    FETCH C
    INTO    CG$DUMMY;
    IF C%FOUND THEN
      CLOSE C;
      Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(5, 'Cannot delete <p1> while dependent <p2> exists', 'جدول المستوردين','مرفقات البيان' ), 'E', 'OFG', 5);
      Des$Form_errors.RAISE_FAILURE;
    END IF;
    CLOSE C;
  END;

  /* Deletion of IMPORTERS prevented if DECLARATIONS records exist */
  /* Foreign key(s): DCLTN_IMP_FK                                  */
  DECLARE
    CURSOR C IS
      SELECT  '1'
      FROM    DECLARATIONS DCLTN
      WHERE   DCLTN.PORT_CD = P_PORT_CD
      AND     (DCLTN.IMPR_NBR = P_IMPR_NBR OR
              (DCLTN.IMPR_NBR IS NULL AND
               P_IMPR_NBR IS NULL ));
  BEGIN
    OPEN C;
    FETCH C
    INTO    CG$DUMMY;
    IF C%FOUND THEN
      CLOSE C;
      Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(5, 'Cannot delete <p1> while dependent <p2> exists', 'IMPORTERS','DECLARATIONS' ), 'E', 'OFG', 5);
      Des$Form_errors.RAISE_FAILURE;
    END IF;
    CLOSE C;
  END;

  /* Deletion of IMPORTERS prevented if DELAY_SEA_DLVY_ORDERS records exist */
  /* Foreign key(s): DSD_IMP_FK                                             */
  DECLARE
    CURSOR C IS
      SELECT  '1'
      FROM    DELAY_SEA_DLVY_ORDERS DSD
      WHERE   (DSD.IMPR_NBR = P_IMPR_NBR OR
              (DSD.IMPR_NBR IS NULL AND
               P_IMPR_NBR IS NULL ))
      AND     DSD.PORT_CD = P_PORT_CD;
  BEGIN
    OPEN C;
    FETCH C
    INTO    CG$DUMMY;
    IF C%FOUND THEN
      CLOSE C;
      Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(5, 'Cannot delete <p1> while dependent <p2> exists', 'جدول المستوردين','اذن التسليم' ), 'E', 'OFG', 5);
      Des$Form_errors.RAISE_FAILURE;
    END IF;
    CLOSE C;
  END;

  /* Deletion of IMPORTERS prevented if CREDIT_LETTERS records exist */
  /* Foreign key(s): CL_IMP_FK                                       */
  DECLARE
    CURSOR C IS
      SELECT  '1'
      FROM    CREDIT_LETTERS CL
      WHERE   CL.PORT_CD = P_PORT_CD
      AND     (CL.IMPR_NBR = P_IMPR_NBR OR
              (CL.IMPR_NBR IS NULL AND
               P_IMPR_NBR IS NULL ));
  BEGIN
    OPEN C;
    FETCH C
    INTO    CG$DUMMY;
    IF C%FOUND THEN
      CLOSE C;
      Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(5, 'Cannot delete <p1> while dependent <p2> exists', 'جدول المستوردين','Credit Letters' ), 'E', 'OFG', 5);
      Des$Form_errors.RAISE_FAILURE;
    END IF;
    CLOSE C;
  END;

  /* Deletion of IMPORTERS prevented if MISSING_DCLTNS records exist */
  /* Foreign key(s): MD_IMP_FK                                       */
  DECLARE
    CURSOR C IS
      SELECT  '1'
      FROM    MISSING_DCLTNS MD
      WHERE   MD.IMPR_NBR = P_IMPR_NBR
      AND     MD.DCLTN_PORT_CD = P_PORT_CD;
  BEGIN
    OPEN C;
    FETCH C
    INTO    CG$DUMMY;
    IF C%FOUND THEN
      CLOSE C;
      Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(5, 'Cannot delete <p1> while dependent <p2> exists', 'IMPORTERS','MISSING_DCLTNS' ), 'E', 'OFG', 5);
      Des$Form_errors.RAISE_FAILURE;
    END IF;
    CLOSE C;
  END;

  /* Deletion of IMPORTERS prevented if DECLARATIONS records exist */
  /* Foreign key(s): DCLTN_AGNT_IMPR_FK                            */
  DECLARE
    CURSOR C IS
      SELECT  '1'
      FROM    DECLARATIONS DCLTN
      WHERE   DCLTN.PORT_CD = P_PORT_CD
      AND     DCLTN.AGENT_NBR = P_IMPR_NBR;
  BEGIN
    OPEN C;
    FETCH C
    INTO    CG$DUMMY;
    IF C%FOUND THEN
      CLOSE C;
      Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(5, 'Cannot delete <p1> while dependent <p2> exists', 'IMPORTERS','DECLARATIONS' ), 'E', 'OFG', 5);
      Des$Form_errors.RAISE_FAILURE;
    END IF;
    CLOSE C;
  END;

  /* Deletion of IMPORTERS prevented if WAIVERS records exist */
  /* Foreign key(s): WVR_IMP_FK                               */
  DECLARE
    CURSOR C IS
      SELECT  '1'
      FROM    WAIVERS WVR
      WHERE   (WVR.IMPR_NBR = P_IMPR_NBR OR
              (WVR.IMPR_NBR IS NULL AND
               P_IMPR_NBR IS NULL ))
      AND     WVR.WVR_PORT_CD = P_PORT_CD;
  BEGIN
    OPEN C;
    FETCH C
    INTO    CG$DUMMY;
    IF C%FOUND THEN
      CLOSE C;
      Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(5, 'Cannot delete <p1> while dependent <p2> exists', 'جدول المستوردين','التعهدات' ), 'E', 'OFG', 5);
      Des$Form_errors.RAISE_FAILURE;
    END IF;
    CLOSE C;
  END;

  /* Deletion of IMPORTERS prevented if EXMTN_A_FORMS records exist */
  /* Foreign key(s): AFRM_IMP_FK                                    */
  DECLARE
    CURSOR C IS
      SELECT  '1'
      FROM    EXMTN_A_FORMS AFRM
      WHERE   AFRM.PORT_CD = P_PORT_CD
      AND     AFRM.IMPR_NBR = P_IMPR_NBR;
  BEGIN
    OPEN C;
    FETCH C
    INTO    CG$DUMMY;
    IF C%FOUND THEN
      CLOSE C;
      Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(5, 'Cannot delete <p1> while dependent <p2> exists', 'IMPORTERS','EXMTN_A_FORMS' ), 'E', 'OFG', 5);
      Des$Form_errors.RAISE_FAILURE;
    END IF;
    CLOSE C;
  END;

  /* Deletion of IMPORTERS prevented if ELIMINATE_REQUESTS records exist */
  /* Foreign key(s): ER_IMP_FK                                           */
  DECLARE
    CURSOR C IS
      SELECT  '1'
      FROM    ELIMINATE_REQUESTS ER
      WHERE   (ER.IMPR_PORT_CD = P_PORT_CD OR
              (ER.IMPR_PORT_CD IS NULL AND
               P_PORT_CD IS NULL ))
      AND     (ER.IMPR_NBR = P_IMPR_NBR OR
              (ER.IMPR_NBR IS NULL AND
               P_IMPR_NBR IS NULL ));
  BEGIN
    OPEN C;
    FETCH C
    INTO    CG$DUMMY;
    IF C%FOUND THEN
      CLOSE C;
      Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(5, 'Cannot delete <p1> while dependent <p2> exists', 'IMPORTERS','ELIMINATE_REQUESTS' ), 'E', 'OFG', 5);
      Des$Form_errors.RAISE_FAILURE;
    END IF;
    CLOSE C;
  END;

  /* Deletion of IMPORTERS prevented if SANDY_EXPORTS records exist */
  /* Foreign key(s): SE_IMP_FK                                      */
  DECLARE
    CURSOR C IS
      SELECT  '1'
      FROM    SANDY_EXPORTS SE
      WHERE   SE.PORT_CD = P_PORT_CD
      AND     SE.EXPR_NBR = P_IMPR_NBR;
  BEGIN
    OPEN C;
    FETCH C
    INTO    CG$DUMMY;
    IF C%FOUND THEN
      CLOSE C;
      Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(5, 'Cannot delete <p1> while dependent <p2> exists', 'جدول المستوردين','Sandy Exports' ), 'E', 'OFG', 5);
      Des$Form_errors.RAISE_FAILURE;
    END IF;
    CLOSE C;
  END;

  /* Deletion of IMPORTERS prevented if VHCL_CAR_EXPTON records exist */
  /* Foreign key(s): VCE_IMP_FK                                       */
  DECLARE
    CURSOR C IS
      SELECT  '1'
      FROM    VHCL_CAR_EXPTON VCE
      WHERE   VCE.IMPR_NBR = P_IMPR_NBR
      AND     VCE.PORT_CD = P_PORT_CD;
  BEGIN
    OPEN C;
    FETCH C
    INTO    CG$DUMMY;
    IF C%FOUND THEN
      CLOSE C;
      Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(5, 'Cannot delete <p1> while dependent <p2> exists', 'جدول المستوردين','ملف استثناء السيارات' ), 'E', 'OFG', 5);
      Des$Form_errors.RAISE_FAILURE;
    END IF;
    CLOSE C;
  END;

  /* Deletion of IMPORTERS prevented if BL_OWNERS records exist */
  /* Foreign key(s): BO_IMP_FK                                  */
  DECLARE
    CURSOR C IS
      SELECT  '1'
      FROM    BL_OWNERS BO
      WHERE   BO.PORT_CD = P_PORT_CD
      AND     (BO.IMPR_NBR = P_IMPR_NBR OR
              (BO.IMPR_NBR IS NULL AND
               P_IMPR_NBR IS NULL ));
  BEGIN
    OPEN C;
    FETCH C
    INTO    CG$DUMMY;
    IF C%FOUND THEN
      CLOSE C;
      Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(5, 'Cannot delete <p1> while dependent <p2> exists', 'جدول المستوردين','مالك البوليصة' ), 'E', 'OFG', 5);
      Des$Form_errors.RAISE_FAILURE;
    END IF;
    CLOSE C;
  END;

  /* Deletion of IMPORTERS prevented if BA_WAREHOUSES records exist */
  /* Foreign key(s): BW_IMP_FK                                      */
  DECLARE
    CURSOR C IS
      SELECT  '1'
      FROM    BA_WAREHOUSES BW
      WHERE   (BW.IMPR_NBR = P_IMPR_NBR OR
              (BW.IMPR_NBR IS NULL AND
               P_IMPR_NBR IS NULL ))
      AND     BW.PORT_CD = P_PORT_CD;
  BEGIN
    OPEN C;
    FETCH C
    INTO    CG$DUMMY;
    IF C%FOUND THEN
      CLOSE C;
      Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(5, 'Cannot delete <p1> while dependent <p2> exists', 'IMPORTERS','BA_WAREHOUSES' ), 'E', 'OFG', 5);
      Des$Form_errors.RAISE_FAILURE;
    END IF;
    CLOSE C;
  END;

  /* Deletion of IMPORTERS prevented if MASS_DUTY_DEF_STLMNTS records exist */
  /* Foreign key(s): MDDS_IMP_FK                                            */
  DECLARE
    CURSOR C IS
      SELECT  '1'
      FROM    MASS_DUTY_DEF_STLMNTS MDDS
      WHERE   MDDS.IMPR_NBR = P_IMPR_NBR
      AND     MDDS.IMP_PORT_CD = P_PORT_CD;
  BEGIN
    OPEN C;
    FETCH C
    INTO    CG$DUMMY;
    IF C%FOUND THEN
      CLOSE C;
      Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(5, 'Cannot delete <p1> while dependent <p2> exists', 'IMPORTERS','MASS_DUTY_DEF_STLMNTS' ), 'E', 'OFG', 5);
      Des$Form_errors.RAISE_FAILURE;
    END IF;
    CLOSE C;
  END;
END;
```

### PU CGTE$CHECK_CONSTRAINT_VIO (Function, 53 lines)

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
    ELSIF (constraint_name = 'SDP_PK') THEN
      Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(6, 'Row exists already with same <p1>', 'رمز الجمرك' ), 'E', 'OFG', 6);
    ELSIF (constraint_name = 'ITIDT_PK') THEN
      Des$Form_errors.PUSH('هذا السجل مدخل سابقاً - أعد ادخال البيانات', 'E', 'OFG', 0);
    ELSIF (constraint_name = 'IT_PK') THEN
      Des$Form_errors.PUSH('هذا السجل مدخل سابقاً - أعد ادخال البيانات', 'E', 'OFG', 0);
    ELSIF (constraint_name = 'BIT_PK') THEN
      Des$Form_errors.PUSH('هذا السجل مدخل سابقاً - أعد ادخال البيانات', 'E', 'OFG', 0);
    ELSIF (constraint_name = 'CT_PK') THEN
      Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(6, 'Row exists already with same <p1>', 'City Cd,رمز الدولة' ), 'E', 'OFG', 6);
    ELSIF (constraint_name = 'CTRY_PK') THEN
      Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(6, 'Row exists already with same <p1>', 'رمز الدولة' ), 'E', 'OFG', 6);
    ELSIF (constraint_name = 'CTRY_PK') THEN
      Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(6, 'Row exists already with same <p1>', 'Ctry Cd' ), 'E', 'OFG', 6);
    ELSIF (constraint_name = 'CT_PK') THEN
      Des$Form_errors.PUSH(Des$Form_errors.MSGGETTEXT(6, 'Row exists already with same <p1>', 'City Cd,رمز الدولة' ), 'E', 'OFG', 6);
    ELSE
      Des$Form_errors.PUSH(P_SERVER_MSG, 'I', 'OFG', 0);
    END IF;
  ELSIF (P_SERVER_ERR = 2290) THEN
    Des$Form_errors.PUSH(P_SERVER_MSG, 'I', 'OFG', 0);
  END IF;
  RETURN( TRUE );
END;
```

### PU UPDATE_IMPORTER (Procedure, 97 lines)

```plsql
/* Formatted on 14/01/20 10:18:49 ? (QP5 v5.294) */
-- --> 23/08/2014 AHMED A-MONIM  consume service from Yesser Producion

PROCEDURE Update_Importer
IS
   RET         NUMBER;
   V_CHK_UPD   NUMBER;
   V_MSG       VARCHAR2 (500);
   MSG_LVL     VARCHAR2 (5);
   MSG_CD      NUMBER;
BEGIN
   ----------------------------------------------------------------------------------------------------
   BEGIN
      MSG_LVL := :SYSTEM.MESSAGE_LEVEL;
      :SYSTEM.MESSAGE_LEVEL := '25';
      FORMS_DDL ('COMMIT');
      :SYSTEM.MESSAGE_LEVEL := MSG_LVL;
   EXCEPTION
      WHEN OTHERS
      THEN
         NULL;
   END;

   ----------------------------------------------------------------------------------------------------
   IF :IMPORTERS.PORT_CD IS NOT NULL AND :IMPORTERS.IMPR_NBR IS NOT NULL
   THEN
IF :IMPORTERS.BUS_ID_TYPE_CD = 2 THEN
      V_MSG :=
            'السجل الرئيسي =  '
         || :IMPORTERS.BUS_ID
         || 'السجل الفرعي = '
         || :IMPORTERS.BUS_ID_BRNCH
         || ' تأكيد التحديث؟';
    END IF ;
    IF :IMPORTERS.IMPR_TYPE_CD = 4 AND :IMPORTERS.BUS_ID_TYPE_CD = 5 THEN
      V_MSG :=
            'رقم مدني =  '
         || :IMPORTERS.BUS_ID
         || ' تأكيد التحديث؟';
    END IF ;
     IF :IMPORTERS.IMPR_TYPE_CD = 4 AND :IMPORTERS.BUS_ID_TYPE_CD = 3 THEN
      V_MSG :=
            ' رقم الاقامة =  '
         || :IMPORTERS.BUS_ID
         || ' تأكيد التحديث؟';
     END IF ;

      RET := STR.DISPALERT (V_MSG, 'CONFIRM');

      IF RET = ALERT_BUTTON1
      THEN
         MSG_LVL := :SYSTEM.MESSAGE_LEVEL;
         :SYSTEM.MESSAGE_LEVEL := '25';

         BEGIN
            -- V_CHK_UPD := IMPR.UpdateImporter(:IMPORTERS.PORT_CD, :IMPORTERS.IMPR_NBR);
            LIB_USR.impr_utilities.UPDATE_IMPORTERS_NAMES (
               :importers.port_cd,
               :importers.impr_nbr,
               MSG_CD,
               v_msg);
            FORMS_DDL ('COMMIT');

            ret := str.dispalert (v_msg, 'INFORMATION');
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
         END;
      END IF;
   END IF;



   /*EXCEPTION
    WHEN OTHERS THEN NULL;
   END;

   :SYSTEM.MESSAGE_LEVEL := MSG_LVL;

    --IF V_CHK_UPD = 1 THEN
     FORMS_DDL('COMMIT');
      -- STR.DISPALERT(' تم تحديث بيانات المستورد من وزارة التجارة', 'ERROR');
   -- ELSE
      -- STR.DISPALERT('لا توجد بيانات بسجلات الوزارة للتحديث', 'ERROR');
     --TERMINATE_FUN;
   -- END IF;


     END IF;
   END IF;*/

   :global.PORT_CD := :IMPORTERS.PORT_CD;
   :global.IMPR_NBR := :IMPORTERS.IMPR_NBR;
   :global.Exec_Query_Now := 1;
END;
-- --< 23/08/2014 AHMED A-MONIM  consume service from Yesser Producion
```

### PU INSERT_AUDIT_RECORD (Procedure, 32 lines)

```plsql
--UPDATE BY ANAS --
-- 4-5-2005  --

PROCEDURE Insert_Audit_Record (V_ACT_TYPE VARCHAR2) IS
	Ret NUMBER;
	V_ACT_DT DATE;
 	V_USER_ID  VARCHAR2(11);
BEGIN
IF (:IMPORTERS.Impr_Nbr IS NOT NULL) THEN
SELECT SYSDATE INTO V_ACT_DT FROM dual;
V_USER_ID := :PARAMETER.P_USER_ID;

-- ADD COLUMN(FILLER1)INTO INSERT QUERY --

INSERT INTO IMPR_UPDTS(Port_Cd, IMPR_NBR, HQ_IMPR_NBR, IMPR_TYPE_CD, BUS_ID_TYPE_CD, BUS_ID , BUS_ID_BRNCH, BUS_ID_EXPRD_DT, CTRY_CD_OF_ID, CITY_CODE_OF_ID, IMPR_EXPR_TYPE, ARBC_IMPR_NAME, ENG_IMPR_NAME, IMPR_NAME_STD, IMPR_NBR_PARENT,  IMPR_CNTCT_NAME, IMPR_TEL_NBR, IMPR_POB_NBR, IMPR_ZIP_CD, IMPR_FAX_NBR, IMPR_TELEX_NBR,  EMAIL, CTRY_CD, ADD_CTRY_CD, CITY_CODE, LST_TRAN_DT, IMPD_STMT_NBR, IMPR_DATA_SRCE, ACT_DT, ACT_TYPE, USR_ID,COMM_RGSTRTN_TYPE
-- --> 23/08/2014 AHMED A-MONIM  consume service from Yesser Producion
			     ,ID_NBR
                       ,BUS_ID_ISSUE_DT,BUS_ID_STATUS,CREATION_FLAG
                       ,IMPR_ADDRESS
                                      )
	 VALUES(:IMPORTERS.Port_Cd, :IMPORTERS.IMPR_NBR, :IMPORTERS.HQ_IMPR_NBR, :IMPORTERS.IMPR_TYPE_CD, :IMPORTERS.BUS_ID_TYPE_CD,:IMPORTERS.BUS_ID , :IMPORTERS.BUS_ID_BRNCH, :IMPORTERS.BUS_ID_EXPRD_DT, :IMPORTERS.CTRY_CD_OF_ID, :IMPORTERS.CITY_CODE_OF_ID, :IMPORTERS.IMPR_EXPR_TYPE,:IMPORTERS.ARBC_IMPR_NAME, :IMPORTERS.ENG_IMPR_NAME, :IMPORTERS.IMPR_NAME_STD, :IMPORTERS.IMPR_NBR_PARENT, :IMPORTERS.IMPR_CNTCT_NAME, :IMPORTERS.IMPR_TEL_NBR, :IMPORTERS.IMPR_POB_NBR, :IMPORTERS.IMPR_ZIP_CD, :IMPORTERS.IMPR_FAX_NBR, :IMPORTERS.IMPR_TELEX_NBR, :IMPORTERS.EMAIL, :IMPORTERS.CTRY_CD, :IMPORTERS.ADD_CTRY_CD, :IMPORTERS.CITY_CODE, :IMPORTERS.LST_TRAN_DT, :IMPORTERS.IMPD_STMT_NBR, :IMPORTERS.IMPR_DATA_SRCE,  V_ACT_DT, V_ACT_TYPE, V_USER_ID,:IMPORTERS.COMM_RGSTRTN_TYPE
-- --> 23/08/2014 AHMED A-MONIM  consume service from Yesser Producion
		  ,:IMPORTERS.ID_NBR
              ,:IMPORTERS.BUS_ID_ISSUE_DT,:IMPORTERS.BUS_ID_STATUS,:IMPORTERS.CREATION_FLAG
              ,:IMPORTERS.IMPR_ADDRESS
                                        );

ELSE
	Ret := STR.DispArbMsg(9, 140,'ERROR');
	RAISE FORm_Trigger_Failure;
END IF;
END;
```

### PU GET_MAIN_CR_DATA (Procedure, 18 lines)

```plsql
PROCEDURE get_main_cr_data IS
STRING_RESULT VARCHAR2(5000);
BEGIN
IF SUBSTR(:IMPORTERS.NATIONAL_NBR,1,1) = '7' THEN
	SELECT MCISERVICE.getMainCRInfoCall ( :importers.NATIONAL_NBR, 'MCIService')
	INTO STRING_RESULT
	FROM DUAL;
	get_cr_data(STRING_RESULT);
ELSE
SELECT MCISERVICE.getMainCRInfoCall ( :importers.bus_id , 'MCIService')
	INTO STRING_RESULT
	FROM DUAL;
	get_cr_data(STRING_RESULT);
END IF;

EXCEPTION
	WHEN OTHERS THEN NULL;
END;
```

### PU GET_CR_DATA (Procedure, 182 lines)

```plsql
PROCEDURE get_cr_data(P_STRING_RESULT VARCHAR2) IS
        FOUND           NUMBER;
        STRING_RESULT   VARCHAR2 (5000);
        V_POS_1 NUMBER;
        V_POS_2 NUMBER;
        V_POS_3 NUMBER;
        V_POS_4 NUMBER;
        V_POS_5 NUMBER;
        V_POS_6 NUMBER;
        V_POS_7 NUMBER;
        V_POS_8 NUMBER;
        V_POS_9 NUMBER;
        V_POS_10 NUMBER;
        V_POS_11 NUMBER;
        V_POS_12 NUMBER;
        V_POS_13 NUMBER;
        V_POS_14 NUMBER;
        V_POS_15 NUMBER;
        V_POS_16 NUMBER;
        V_POS_17 NUMBER;
        V_POS_18 NUMBER;
        V_POS_19 NUMBER;
        V_POS_20 NUMBER;
        V_POS_21 NUMBER;

        V_TXT_1 VARCHAR2(500);
        V_TXT_2 VARCHAR2(500);
        V_TXT_3 VARCHAR2(500);
        V_TXT_4 VARCHAR2(500);
        V_TXT_5 VARCHAR2(500);
        V_TXT_6 VARCHAR2(500);
        V_TXT_7 VARCHAR2(500);
        V_TXT_8 VARCHAR2(500);
        V_TXT_9 VARCHAR2(500);
        V_TXT_10 VARCHAR2(500);
        V_TXT_11 VARCHAR2(500);
        V_TXT_12 VARCHAR2(500);
        V_TXT_13 VARCHAR2(500);
        V_TXT_14 VARCHAR2(500);
        V_TXT_15 VARCHAR2(500);
        V_TXT_16 VARCHAR2(500);
        V_TXT_17 VARCHAR2(500);
        V_TXT_18 VARCHAR2(500);
        V_TXT_19 VARCHAR2(500);
        V_TXT_20 VARCHAR2(500);
        V_TXT_21 VARCHAR2(500);

        V_BUS_ID_EXPRD_DT IMPORTERS.BUS_ID_EXPRD_DT%TYPE;
        V_BUS_ID_ISSUE_DT IMPORTERS.BUS_ID_ISSUE_DT%TYPE;
        V_ARBC_IMPR_NAME IMPORTERS.ARBC_IMPR_NAME%TYPE;
        V_IMPR_NAME_STD IMPORTERS.IMPR_NAME_STD%TYPE;
        V_IMPR_ADDRESS IMPORTERS.IMPR_ADDRESS%TYPE;
        V_IMPR_TEL_NBR IMPORTERS.IMPR_TEL_NBR%TYPE;
        V_IMPR_FAX_NBR IMPORTERS.IMPR_FAX_NBR%TYPE;
        V_IMPR_TELEX_NBR IMPORTERS.IMPR_TELEX_NBR%TYPE;
        V_ACTIVITY IMPORTERS.ACTIVITY%TYPE;
        V_BUS_ID_STATUS IMPORTERS.BUS_ID_STATUS%TYPE;
        V_CITY_CODE_OF_ID IMPORTERS.CITY_CODE_OF_ID%TYPE;
        V_PORT_CD IMPORTERS.PORT_CD%TYPE;
        V_IMPR_NBR IMPORTERS.IMPR_NBR%TYPE;
        V_HQ_IMPR_NBR IMPORTERS.HQ_IMPR_NBR%TYPE;
        V_bus_id IMPORTERS.bus_id%TYPE;
        V_bus_id_brnch IMPORTERS.bus_id_brnch%TYPE;
BEGIN
        STR.DISPALERT('سيتم الحصول على بيانات المستورد من وزارة التجارة.....الرجاء الإنتظار', 'ERROR');
	    STRING_RESULT := P_STRING_RESULT;

          IF STRING_RESULT IS NOT NULL
          THEN
            STRING_RESULT := LTRIM(RTRIM(STRING_RESULT))||' |'||' |'||' |'||' |'||' |'||' |'||' |'||' |'||' |'||' |'||' |'||' |'||' |'||' |'||' |'||' |'||' |'||' |'||' |'||' |'||' |'||' |';
            SELECT INSTR(STRING_RESULT,'|',1            ) INTO V_POS_1 FROM DUAL;
            SELECT INSTR(STRING_RESULT,'|',1 + V_POS_1  ) INTO V_POS_2 FROM DUAL;
            SELECT INSTR(STRING_RESULT,'|',1 + V_POS_2  ) INTO V_POS_3 FROM DUAL;
            SELECT INSTR(STRING_RESULT,'|',1 + V_POS_3  ) INTO V_POS_4 FROM DUAL;
            SELECT INSTR(STRING_RESULT,'|',1 + V_POS_4  ) INTO V_POS_5 FROM DUAL;
            SELECT INSTR(STRING_RESULT,'|',1 + V_POS_5  ) INTO V_POS_6 FROM DUAL;
            SELECT INSTR(STRING_RESULT,'|',1 + V_POS_6  ) INTO V_POS_7 FROM DUAL;
            SELECT INSTR(STRING_RESULT,'|',1 + V_POS_7  ) INTO V_POS_8 FROM DUAL;
            SELECT INSTR(STRING_RESULT,'|',1 + V_POS_8  ) INTO V_POS_9 FROM DUAL;
            SELECT INSTR(STRING_RESULT,'|',1 + V_POS_9  ) INTO V_POS_10 FROM DUAL;
            SELECT INSTR(STRING_RESULT,'|',1 + V_POS_10 ) INTO V_POS_11 FROM DUAL;
            SELECT INSTR(STRING_RESULT,'|',1 + V_POS_11 ) INTO V_POS_12 FROM DUAL;
            SELECT INSTR(STRING_RESULT,'|',1 + V_POS_12 ) INTO V_POS_13 FROM DUAL;
            SELECT INSTR(STRING_RESULT,'|',1 + V_POS_13 ) INTO V_POS_14 FROM DUAL;
            SELECT INSTR(STRING_RESULT,'|',1 + V_POS_14 ) INTO V_POS_15 FROM DUAL;
            SELECT INSTR(STRING_RESULT,'|',1 + V_POS_15 ) INTO V_POS_16 FROM DUAL;
            SELECT INSTR(STRING_RESULT,'|',1 + V_POS_16 ) INTO V_POS_17 FROM DUAL;
--            SELECT INSTR(STRING_RESULT,'|',1 + V_POS_17 ) INTO V_POS_18 FROM DUAL;
--            SELECT INSTR(STRING_RESULT,'|',1 + V_POS_18 ) INTO V_POS_19 FROM DUAL;
--            SELECT INSTR(STRING_RESULT,'|',1 + V_POS_19 ) INTO V_POS_20 FROM DUAL;
--            SELECT INSTR(STRING_RESULT,'|',1 + V_POS_20 ) INTO V_POS_21 FROM DUAL;
            V_TXT_1  := UPPER(LTRIM(RTRIM(SUBSTR( STRING_RESULT ,             1 , V_POS_1  - (           1 ) )))) ;
            V_TXT_2  := UPPER(LTRIM(RTRIM(SUBSTR( STRING_RESULT ,  V_POS_1  + 1 , V_POS_2  - (V_POS_1  + 1 ) )))) ;
            V_TXT_3  := UPPER(LTRIM(RTRIM(SUBSTR( STRING_RESULT ,  V_POS_2  + 1 , V_POS_3  - (V_POS_2  + 1 ) )))) ;
            V_TXT_4  := UPPER(LTRIM(RTRIM(SUBSTR( STRING_RESULT ,  V_POS_3  + 1 , V_POS_4  - (V_POS_3  + 1 ) )))) ;
            V_TXT_5  := UPPER(LTRIM(RTRIM(SUBSTR( STRING_RESULT ,  V_POS_4  + 1 , V_POS_5  - (V_POS_4  + 1 ) )))) ;
            V_TXT_6  := UPPER(LTRIM(RTRIM(SUBSTR( STRING_RESULT ,  V_POS_5  + 1 , V_POS_6  - (V_POS_5  + 1 ) )))) ;
            V_TXT_7  := UPPER(LTRIM(RTRIM(SUBSTR( STRING_RESULT ,  V_POS_6  + 1 , V_POS_7  - (V_POS_6  + 1 ) )))) ;
            V_TXT_8  := UPPER(LTRIM(RTRIM(SUBSTR( STRING_RESULT ,  V_POS_7  + 1 , V_POS_8  - (V_POS_7  + 1 ) )))) ;
            V_TXT_9  := UPPER(LTRIM(RTRIM(SUBSTR( STRING_RESULT ,  V_POS_8  + 1 , V_POS_9  - (V_POS_8  + 1 ) )))) ;
            V_TXT_10 := UPPER(LTRIM(RTRIM(SUBSTR( STRING_RESULT ,  V_POS_9  + 1 , V_POS_10 - (V_POS_9  + 1 ) )))) ;
            V_TXT_11 := UPPER(LTRIM(RTRIM(SUBSTR( STRING_RESULT ,  V_POS_10 + 1 , V_POS_11 - (V_POS_10 + 1 ) )))) ;
            V_TXT_12 := UPPER(LTRIM(RTRIM(SUBSTR( STRING_RESULT ,  V_POS_11 + 1 , V_POS_12 - (V_POS_11 + 1 ) )))) ;
            V_TXT_13 := UPPER(LTRIM(RTRIM(SUBSTR( STRING_RESULT ,  V_POS_12 + 1 , V_POS_13 - (V_POS_12 + 1 ) )))) ;
            V_TXT_14 := UPPER(LTRIM(RTRIM(SUBSTR( STRING_RESULT ,  V_POS_13 + 1 , V_POS_14 - (V_POS_13 + 1 ) )))) ;
            V_TXT_15 := UPPER(LTRIM(RTRIM(SUBSTR( STRING_RESULT ,  V_POS_14 + 1 , V_POS_15 - (V_POS_14 + 1 ) )))) ;
            V_TXT_16 := UPPER(LTRIM(RTRIM(SUBSTR( STRING_RESULT ,  V_POS_15 + 1 , V_POS_16 - (V_POS_15 + 1 ) )))) ;
--            V_TXT_17 := UPPER(LTRIM(RTRIM(SUBSTR( STRING_RESULT ,  V_POS_16 + 1 , V_POS_17 - (V_POS_16 + 1 ) )))) ;
--            V_TXT_18 := UPPER(LTRIM(RTRIM(SUBSTR( STRING_RESULT ,  V_POS_17 + 1 , V_POS_18 - (V_POS_17 + 1 ) )))) ;
--            V_TXT_19 := UPPER(LTRIM(RTRIM(SUBSTR( STRING_RESULT ,  V_POS_18 + 1 , V_POS_19 - (V_POS_18 + 1 ) )))) ;
--            V_TXT_20 := UPPER(LTRIM(RTRIM(SUBSTR( STRING_RESULT ,  V_POS_19 + 1 , V_POS_20 - (V_POS_19 + 1 ) )))) ;
--            V_TXT_21 := UPPER(LTRIM(RTRIM(SUBSTR( STRING_RESULT ,  V_POS_20 + 1 , V_POS_21 - (V_POS_20 + 1 ) )))) ;

            IF V_TXT_1 IS NOT NULL THEN
                 :BUS_ID       := V_TXT_1 ;
                :BUS_ID_BRNCH := V_TXT_2 ;
 IF :BUS_ID_BRNCH = 0 THEN
                 	:BUS_ID_BRNCH := NULL;
                 END IF;
                V_BUS_ID_EXPRD_DT := TO_DATE(V_TXT_3,'MI-MM-YYYY')  ;
                V_BUS_ID_ISSUE_DT := TO_DATE(V_TXT_4,'MI-MM-YYYY')  ;
                V_ARBC_IMPR_NAME := V_TXT_6  ;
                V_IMPR_ADDRESS := V_TXT_8  ;
                IF V_TXT_9 > '0000000' THEN
                    V_IMPR_TEL_NBR := V_TXT_9  ;
                ELSIF V_TXT_10 > '0000000' THEN
                    V_IMPR_TEL_NBR := V_TXT_10  ;
                END IF;
                IF V_TXT_11 > '0000000' THEN
                    V_IMPR_FAX_NBR := V_TXT_11  ;
                ELSIF V_TXT_12 > '0000000' THEN
                    V_IMPR_FAX_NBR := V_TXT_12  ;
                END IF;
                V_IMPR_TELEX_NBR := V_TXT_13  ;
                V_ACTIVITY := V_TXT_14  ;

                IF UPPER(V_TXT_15) =  'ACTIVE' THEN
                    V_BUS_ID_STATUS := 1  ;
                ELSIF UPPER(V_TXT_15) =  'EXPIRED' THEN
                    V_BUS_ID_STATUS := 2  ;
                ELSIF UPPER(V_TXT_15) =  'SUSPENDED' THEN
                    V_BUS_ID_STATUS := 3  ;
                ELSIF UPPER(V_TXT_15) LIKE 'WRITTEN%OFF' THEN
                    V_BUS_ID_STATUS := 4  ;
                ELSE
                    V_BUS_ID_STATUS := 5  ;
                END IF;

                BEGIN
                    SELECT CITY_CD
                    INTO V_CITY_CODE_OF_ID
                    FROM CITIES
                    WHERE MINS_COMM_CD = V_TXT_16  ;
                EXCEPTION
                  WHEN OTHERS THEN NULL;
                END;

                V_IMPR_NAME_STD :=  STR_DB.StrFormat(V_ARBC_IMPR_NAME);

                    :IMPORTERS.BUS_ID_EXPRD_DT := V_BUS_ID_EXPRD_DT;
                    :IMPORTERS.BUS_ID_ISSUE_DT := V_BUS_ID_ISSUE_DT;
                    :IMPORTERS.ARBC_IMPR_NAME := V_ARBC_IMPR_NAME;
                    :IMPORTERS.IMPR_NAME_STD := V_IMPR_NAME_STD;
                    :IMPORTERS.IMPR_ADDRESS := V_IMPR_ADDRESS;
                    :IMPORTERS.IMPR_TEL_NBR := V_IMPR_TEL_NBR;
                    :IMPORTERS.IMPR_FAX_NBR := V_IMPR_FAX_NBR;
                    :IMPORTERS.IMPR_TELEX_NBR := V_IMPR_TELEX_NBR;
                    :IMPORTERS.ACTIVITY := V_ACTIVITY;
                    :IMPORTERS.BUS_ID_STATUS := V_BUS_ID_STATUS;
                    :IMPORTERS.CITY_CODE_OF_ID := V_CITY_CODE_OF_ID;
                    :IMPORTERS.LST_TRAN_DT := SYSDATE;
                    :IMPORTERS.CREATION_FLAG := 3;
             SET_ITEM_PROPERTY('IMPORTERS.BUS_ID',INSERT_ALLOWED,PROPERTY_FALSE);
                    SET_ITEM_PROPERTY('IMPORTERS.BUS_ID',UPDATE_ALLOWED,PROPERTY_FALSE);
                    SET_ITEM_PROPERTY('IMPORTERS.BUS_ID_BRNCH',INSERT_ALLOWED,PROPERTY_FALSE);
                    SET_ITEM_PROPERTY('IMPORTERS.BUS_ID_BRNCH',UPDATE_ALLOWED,PROPERTY_FALSE);
            END IF;
       END IF;
SYNCHRONIZE;
EXCEPTION
	WHEN OTHERS THEN NULL;
END;
```

### PU GET_BRANCH_CR_DATA (Procedure, 19 lines)

```plsql
PROCEDURE get_branch_cr_data IS
STRING_RESULT VARCHAR2(5000);
BEGIN
IF SUBSTR(:IMPORTERS.NATIONAL_NBR,1,1) = '7' THEN

	SELECT MCISERVICE.getBranchCRInfoCall ( :importers.NATIONAL_NBR, 'MCIService')
	INTO STRING_RESULT
	FROM DUAL;
	get_cr_data(STRING_RESULT);
ELSE
SELECT MCISERVICE.getBranchCRInfoCall ( :importers.bus_id_brnch , 'MCIService')
	INTO STRING_RESULT
	FROM DUAL;
	get_cr_data(STRING_RESULT);
END IF;

EXCEPTION
	WHEN OTHERS THEN NULL;
END;
```

### PU EXEC_FUNS (Procedure, 6 lines)

```plsql
PROCEDURE EXEC_FUNS(CD VARCHAR2) IS
BEGIN
IF CD IN ('IMPR_MCI_SERVICE')   AND (:GLOBAL.ALLOW_MCI = 1 OR :GLOBAL.ALLOW_MOI = 1) THEN
	Update_Importer;
END IF;
END;
```

### PU DEV_VERSIONS (Procedure, 16 lines)

```plsql
PROCEDURE dev_versions IS
BEGIN
NULL ;
/*
developer : ahmed alwakeel
demand : dm_685
description : تحديث بيانات المستورد الشخصي بالربط مع مركز المعلومات الوطني
start_date :23/11/2020
end_date :23/11/2020
coped_screen : impr1130_dm_685
layout_changed :yes
version : 8
release_date :
--------------------------------------
*/
END;
```

### PU CHK_IMPR_DUPL (Procedure, 66 lines)

```plsql
PROCEDURE CHK_IMPR_DUPL IS
	V_COUNT NUMBER;
	V_IMPR_NBR NUMBER;
BEGIN
	IF :BUS_ID_BRNCH IS NOT NULL THEN
		:IMPORTERS.BUS_ID_BRNCH := TO_NUMBER(:IMPORTERS.BUS_ID_BRNCH);
		SYNCHRONIZE;

		SELECT COUNT(*)
		INTO	V_COUNT
		FROM  IMPORTERS
		WHERE PORT_CD = :IMPORTERS.PORT_CD
		AND	CTRY_CD = NVL(:IMPORTERS.CTRY_CD, CTRY_CD)
		AND	BUS_ID_TYPE_CD = :IMPORTERS.BUS_ID_TYPE_CD
		AND 	BUS_ID  = :IMPORTERS.BUS_ID
		AND 	BUS_ID_BRNCH = :IMPORTERS.BUS_ID_BRNCH
		AND		((:IMPORTERS.IMPR_NBR IS NULL) OR (:IMPORTERS.IMPR_NBR IS NOT NULL AND IMPR_NBR <> :IMPORTERS.IMPR_NBR))
		;

		IF V_COUNT > 0 THEN
			SELECT MAX(IMPR_NBR)
			INTO	V_IMPR_NBR
			FROM IMPORTERS
			WHERE PORT_CD = :IMPORTERS.PORT_CD
			AND	CTRY_CD = NVL(:IMPORTERS.CTRY_CD, CTRY_CD)
			AND	BUS_ID_TYPE_CD = :IMPORTERS.BUS_ID_TYPE_CD
			AND 	BUS_ID  = :IMPORTERS.BUS_ID
			AND 	BUS_ID_BRNCH = :IMPORTERS.BUS_ID_BRNCH
			AND		((:IMPORTERS.IMPR_NBR IS NULL) OR (:IMPORTERS.IMPR_NBR IS NOT NULL AND IMPR_NBR <> :IMPORTERS.IMPR_NBR))

			;


			STR.DISPALERT(' لا يمكن تكرار الرقم الإستدلالي - الرقم الإستدلالي مستخدم لمستورد آخر مسلسله بالجمرك رقم : '||V_IMPR_NBR,'ERROR');
			RAISE FORM_TRIGGER_FAILURE;
		END IF;
	ELSE
		SELECT COUNT(*)
		INTO	V_COUNT
		FROM IMPORTERS
		WHERE PORT_CD = :IMPORTERS.PORT_CD
		AND	CTRY_CD = NVL(:IMPORTERS.CTRY_CD, CTRY_CD)
		AND	BUS_ID_TYPE_CD = :IMPORTERS.BUS_ID_TYPE_CD
		AND 	BUS_ID  = :IMPORTERS.BUS_ID
		AND 	BUS_ID_BRNCH IS NULL
		AND		((:IMPORTERS.IMPR_NBR IS NULL) OR (:IMPORTERS.IMPR_NBR IS NOT NULL AND IMPR_NBR <> :IMPORTERS.IMPR_NBR))
		;

		IF V_COUNT > 0 THEN
			SELECT MAX(IMPR_NBR)
			INTO	V_IMPR_NBR
			FROM IMPORTERS
			WHERE PORT_CD = :IMPORTERS.PORT_CD
			AND	CTRY_CD = NVL(:IMPORTERS.CTRY_CD, CTRY_CD)
			AND	BUS_ID_TYPE_CD = :IMPORTERS.BUS_ID_TYPE_CD
			AND 	BUS_ID  = :IMPORTERS.BUS_ID
			AND 	BUS_ID_BRNCH IS NULL
			AND		((:IMPORTERS.IMPR_NBR IS NULL) OR (:IMPORTERS.IMPR_NBR IS NOT NULL AND IMPR_NBR <> :IMPORTERS.IMPR_NBR))
			;

			STR.DISPALERT(' لا يمكن تكرار الرقم الإستدلالي - الرقم الإستدلالي مستخدم لمستورد آخر مسلسله بالجمرك رقم : '||V_IMPR_NBR,'ERROR');
			RAISE FORM_TRIGGER_FAILURE;
		END IF;

	END IF;
END;
```

### PU CALL_LOV_COUNTRIES (Procedure, 44 lines)

```plsql
PROCEDURE CALL_LOV_COUNTRIES IS

   pl_id   ParamList;
   pl_name VARCHAR2(100) := 'COUNTRIES_LOV';

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


  -- Add_Parameter(pl_id, 'WINDOW_WIDTH', TEXT_PARAMETER, 4.5);  --
   Add_Parameter(pl_id, 'WINDOW_TITLE', TEXT_PARAMETER, 'قائمة الدول');

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
     ret := Str.DispAlert('Parameter list '||pl_name||' already EXISTS!','INFORMATION');
     RAISE Form_Trigger_Failure;
   END IF;
 END;
```

### PU CALL_LOV_COUN_GULF (Procedure, 43 lines)

```plsql
PROCEDURE CALL_LOV_COUN_GULF IS

   pl_id   ParamList;
   pl_name VARCHAR2(100) := 'COUNTRIES_GULF_LOV';

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
	--   Add_Parameter(pl_id, 'STATUS', TEXT_PARAMETER, 1);--
NULL;
   END IF;


  -- Add_Parameter(pl_id, 'WINDOW_WIDTH', TEXT_PARAMETER, 4.5); --
   Add_Parameter(pl_id, 'WINDOW_TITLE', TEXT_PARAMETER, 'قائمة الدول الخليجية');

   CALL_FORM('LOV_COUNTRIES_GULF.fmx',
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
     ret := Str.DispAlert('Parameter list '||pl_name||' already EXISTS!','INFORMATION');
     RAISE Form_Trigger_Failure;
   END IF;
 END;
```

### PU ADJ_FUNS (Procedure, 8 lines)

```plsql
PROCEDURE ADJ_FUNS IS
BEGIN
IF (NVL(:BUS_ID_TYPE_CD,0) = 2  AND :GLOBAL.ALLOW_MCI = 1) OR (:IMPR_TYPE_CD = 4 AND :BUS_ID_TYPE_CD IN (3, 5) AND :GLOBAL.ALLOW_MOI = 1  ) THEN
	TMPLT.ENABLE_FUN('IMPR_MCI_SERVICE');
ELSE
	TMPLT.DISABLE_FUN('IMPR_MCI_SERVICE');
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
| ACTIVITY.ADD_ACTIVITY | 3 | IMPORTERS.PRE-DELETE, IMPORTERS.PRE-INSERT, IMPORTERS.PRE-UPDATE |
| ADJ_PRN.ADJ_REPORT_PRINTER | 1 | PU EXECUTE_FUNCTION |
| CG$CHK_PACKAGE_FAILURE | 1 | IMPORTERS.KEY-DELREC |
| CG$DUMMY | 2 | PU CGFK$CHK_IMPORTERS_IMP_MB_FK, PU CGRI$CHK_IMPORTERS |
| CG$IMPR1130_PROD_CENTRL_GLOBAL.IMPORTERS_WHERE | 1 | IMPORTERS.PRE-QUERY |
| CGHP$CALL_MS_HELP | 2 | FORM.KEY-HELP, IMPORTERS.KEY-HELP |
| CGHP$PRE_FORM | 1 | FORM.PRE-FORM |
| CGTE$OTHER_EXCEPTIONS | 16 | FORM.KEY-CLRFRM, FORM.KEY-HELP, FORM.WHEN-NEW-FORM-INSTANCE, IMPORTERS.ADD_CTRY_CD.WHEN-VALIDATE-ITEM, IMPORTERS.CITY_CODE.WHEN-VALIDATE-ITEM, IMPORTERS.CITY_CODE_OF_ID.WHEN-VALIDATE-ITEM, IMPORTERS.CTRY_CD.WHEN-VALIDATE-ITEM, IMPORTERS.CTRY_CD_OF_ID.WHEN-VALIDATE-ITEM … (+8) |
| CGTE$POP_ERROR_STACK | 1 | IMPORTERS.ON-ERROR |
| CGTE$STRIP_CONSTRAINT | 2 | IMPORTERS.ON-ERROR, PU CGTE$CHECK_CONSTRAINT_VIO |
| CGTE$STRIP_FIRST_ERROR | 1 | PU CGTE$CHECK_CONSTRAINT_VIO |
| DB_JOURNAL.JOURNALING_OFF | 1 | IMPORTERS.POST-INSERT |
| DB_JOURNAL.JOURNALING_ON | 1 | IMPORTERS.PRE-INSERT |
| DES$FORM_ERRORS.MSGGETTEXT | 8 | FORM.KEY-HELP, IMPORTERS.KEY-HELP, IMPORTERS.ON-ERROR, IMPORTERS.PORT_CD.WHEN-VALIDATE-ITEM, IMPORTERS.POST-QUERY, IMPORTERS.PRE-QUERY, PU CGRI$CHK_IMPORTERS, PU CGTE$CHECK_CONSTRAINT_VIO |
| DES$FORM_ERRORS.PUSH | 13 | FORM.KEY-HELP, IMPORTERS.ADD_CTRY_CD.WHEN-VALIDATE-ITEM, IMPORTERS.CITY_CODE.WHEN-VALIDATE-ITEM, IMPORTERS.CITY_CODE_OF_ID.WHEN-VALIDATE-ITEM, IMPORTERS.CTRY_CD.WHEN-VALIDATE-ITEM, IMPORTERS.IMPR_TYPE_CD.WHEN-VALIDATE-ITEM, IMPORTERS.KEY-HELP, IMPORTERS.ON-ERROR … (+5) |
| DES$FORM_ERRORS.RAISE_FAILURE | 7 | IMPORTERS.CTRY_CD.WHEN-VALIDATE-ITEM, IMPORTERS.IMPR_TYPE_CD.WHEN-VALIDATE-ITEM, IMPORTERS.ON-ERROR, IMPORTERS.PORT_CD.WHEN-VALIDATE-ITEM, IMPORTERS.POST-QUERY, IMPORTERS.PRE-QUERY, PU CGRI$CHK_IMPORTERS |
| GNRL.GET_CUSTOMS_SETTING | 1 | IMPORTERS.IMPR_TYPE_CD.WHEN-VALIDATE-ITEM |
| GNRL.GET_SEQUENCE_VALUE | 1 | IMPORTERS.IMPR_TYPE_CD.WHEN-VALIDATE-ITEM |
| HIJDATE.CUR_HIJ_DATE | 3 | TOOLBAR.EXIT1.WHEN-BUTTON-PRESSED, TOOLBAR.RE_ENTER_QUERY.WHEN-BUTTON-PRESSED, TOOLBAR.SAVE.WHEN-BUTTON-PRESSED |
| HIJDATE.VALID_HIJ_DATE | 3 | IMPORTERS.BUS_ID_EXPRD_DT.WHEN-VALIDATE-ITEM, IMPORTERS.BUS_ID_ISSUE_DT.WHEN-VALIDATE-ITEM, TITLE.SYSTEM_DATE.WHEN-VALIDATE-ITEM |
| IMPR.IMPR_SUSPENDED | 1 | IMPORTERS.POST-QUERY |
| INTRFACE.DISP_CALENDAR | 2 | IMPORTERS.BUS_ID_EXPRD_DT.KEY-LISTVAL, IMPORTERS.BUS_ID_ISSUE_DT.KEY-LISTVAL |
| INTRFACE.DISP_DATE_CON | 2 | IMPORTERS.BUS_ID_EXPRD_DT.KEY-F4, IMPORTERS.BUS_ID_ISSUE_DT.KEY-F4 |
| INTRFACE.MAKE_FIELD_ENTRABLE | 9 | FORM.WHEN-NEW-FORM-INSTANCE, IMPORTERS.BUS_ID.WHEN-VALIDATE-ITEM, IMPORTERS.BUS_ID_BRNCH.WHEN-VALIDATE-ITEM, IMPORTERS.COMM_RGSTRTN_TYPE.WHEN-LIST-CHANGED, IMPORTERS.IMPR_TYPE_CD.WHEN-VALIDATE-ITEM, IMPORTERS.POST-QUERY, IMPORTERS.PRE-INSERT, IMPORTERS.WHEN-CREATE-RECORD … (+1) |
| KEY_CONTROL.FOUND_KEY | 1 | TOOLBAR.EXIT1.WHEN-BUTTON-PRESSED |
| LIB_USR.GNRL.GET_CUSTOMS_SETTING | 2 | IMPORTERS.BUS_ID.WHEN-VALIDATE-ITEM, IMPORTERS.BUS_ID_BRNCH.WHEN-VALIDATE-ITEM |
| LIB_USR.IMPR_CENTRAL.CREATE_UNI_IMPR_NEBRAS | 1 | IMPORTERS.PRE-INSERT |
| LIB_USR.IMPR_UTILITIES.UPDATE_IMPORTERS_NAMES | 1 | PU UPDATE_IMPORTER |
| MCISERVICE.GETBRANCHCRINFOCALL | 1 | PU GET_BRANCH_CR_DATA |
| MCISERVICE.GETMAINCRINFOCALL | 1 | PU GET_MAIN_CR_DATA |
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
| STR.DISPALERT | 27 | FORM.WHEN-NEW-FORM-INSTANCE, IMPORTERS.ADD_CTRY_CD.KEY-LISTVAL, IMPORTERS.BUS_ID.WHEN-VALIDATE-ITEM, IMPORTERS.BUS_ID_TYPE_CD.KEY-LISTVAL, IMPORTERS.CITY_CODE.KEY-LISTVAL, IMPORTERS.CITY_CODE.WHEN-VALIDATE-ITEM, IMPORTERS.CITY_CODE_OF_ID.KEY-LISTVAL, IMPORTERS.CITY_CODE_OF_ID.WHEN-VALIDATE-ITEM … (+19) |
| STR.DISPARBMSG | 12 | FORM.WHEN-NEW-FORM-INSTANCE, IMPORTERS.BUS_ID.WHEN-VALIDATE-ITEM, IMPORTERS.BUS_ID_BRNCH.WHEN-VALIDATE-ITEM, IMPORTERS.BUS_ID_TYPE_CD.WHEN-VALIDATE-ITEM, IMPORTERS.CITY_CODE.WHEN-VALIDATE-ITEM, IMPORTERS.CITY_CODE_OF_ID.WHEN-VALIDATE-ITEM, IMPORTERS.IMPR_NBR.WHEN-VALIDATE-ITEM, IMPORTERS.IMPR_NBR_PARENT.WHEN-VALIDATE-ITEM … (+4) |
| STR.STRFORMAT | 2 | IMPORTERS.PRE-QUERY, IMPORTERS.PRE-UPDATE |
| STR_DB.GETARBMSG | 2 | IMPORTERS.BUS_ID.WHEN-VALIDATE-ITEM, IMPORTERS.CITY_CODE_OF_ID.WHEN-VALIDATE-ITEM |
| STR_DB.REMOVEREPEAT | 1 | IMPORTERS.ENG_IMPR_NAME.WHEN-VALIDATE-ITEM |
| STR_DB.STRFORMAT | 1 | PU GET_CR_DATA |
| TMPLT.DISABLE_FUN | 1 | PU ADJ_FUNS |
| TMPLT.ENABLE_FUN | 1 | PU ADJ_FUNS |
| TMPLT.ENB_DIS_FUN_BUT | 1 | TOOLBAR.EXIT1.WHEN-BUTTON-PRESSED |
| TMPLT.FUN_ITEMS | 1 | PU EXECUTE_FUNCTION |
| TMPLT.KEYB_UP_DOWN | 3 | FORM.KEY-F9, TOOLBAR.KEY-DOWN, TOOLBAR.KEY-UP |
| TMPLT.POPULATE_FUNCTIONS | 2 | FORM.KEY-F9, TOOLBAR.FUN_BUT.WHEN-MOUSE-UP |


### 10.4 Called forms

| Caller | Built-in | Arguments (verbatim) | ADD_PARAMETER calls in the same unit (name, type, value) |
|---|---|---|---|
| FORM.WHEN-NEW-FORM-INSTANCE | CALL_FORM | `'SUPPORT_ENTRY.FMX',NO_HIDE,NO_REPLACE,NO_QUERY_ONLY,PL_ID` | WINDOW_X_POS TEXT_PARAMETER = 1.5; WINDOW_Y_POS TEXT_PARAMETER = 2; P_MODE TEXT_PARAMETER = 0; P_CURR_PORT_CD TEXT_PARAMETER = :IMPORTERS.PORT_CD |
| FORM.WHEN-NEW-FORM-INSTANCE | OPEN_FORM | `'SUPPORT_ENTRY.FMX'` | WINDOW_X_POS TEXT_PARAMETER = 1.5; WINDOW_Y_POS TEXT_PARAMETER = 2; P_MODE TEXT_PARAMETER = 0; P_CURR_PORT_CD TEXT_PARAMETER = :IMPORTERS.PORT_CD |
| IMPORTERS.PORT_CD.KEY-LISTVAL | CALL_FORM | `'LOV_SD_PORTS.fmx', no_hide, no_replace, no_query_only, pl_id` | PORT_TYPE TEXT_PARAMETER = :PARAMETER.P_PORT_TYPE; WINDOW_WIDTH TEXT_PARAMETER = 5.5; WINDOW_TITLE TEXT_PARAMETER = 'قائمة المنافذ الجمركية السعوديه'; STATUS TEXT_PARAMETER = 1 |
| IMPORTERS.IMPR_TYPE_CD.KEY-LISTVAL | CALL_FORM | `'LOV_Impr_Type.fmx', no_hide, no_replace, no_query_only, pl_id` | WINDOW_TITLE TEXT_PARAMETER = 'المتاحة قائمة أنواع الأنشطة التجارية' |
| IMPORTERS.BUS_ID_TYPE_CD.KEY-LISTVAL | CALL_FORM | `'LOV_Impr_Type.fmx', no_hide, no_replace, no_query_only, pl_id` | WINDOW_TITLE TEXT_PARAMETER = 'المتاحة قائمة أنواع الأنشطة التجارية'; IMPR_TYPE_CD TEXT_PARAMETER = :IMPORTERs.IMPR_TYPE_CD |
| IMPORTERS.CITY_CODE_OF_ID.KEY-LISTVAL | CALL_FORM | `'LOV_CITIES.fmx ', no_hide, no_replace, no_query_only, pl_id` | WINDOW_TITLE  TEXT_PARAMETER = 'قائمة المدن السعوديه'; WINDOW_WIDTH  TEXT_PARAMETER = 5; WINDOW_X_POS TEXT_PARAMETER = 1.5; WINDOW_Y_POS TEXT_PARAMETER = .8; CTRY_CD TEXT_PARAMETER = :IMPORTERS.CTRY_CD; STATUS TEXT_PARAMETER = 1 |
| IMPORTERS.IMPR_NBR_PARENT.KEY-LISTVAL | CALL_FORM | `'LOV_IMPR.fmx', no_hide, no_replace, no_query_only, pl_id` | PORT_CD TEXT_PARAMETER = :PARAMETER.P_Curr_Port_CD; WINDOW_TITLE TEXT_PARAMETER = 'قائمة إختيار المستوردين' |
| IMPORTERS.ADD_CTRY_CD.KEY-LISTVAL | CALL_FORM | `'LOV_COUNTRIES.fmx', no_hide, no_replace, no_query_only, pl_id` | STATUS TEXT_PARAMETER = 1; WINDOW_WIDTH TEXT_PARAMETER = 4.5; WINDOW_TITLE TEXT_PARAMETER = 'قائمة الدول' |
| IMPORTERS.CITY_CODE.KEY-LISTVAL | CALL_FORM | `'LOV_CITIES.fmx ', no_hide, no_replace, no_query_only, pl_id` | WINDOW_TITLE  TEXT_PARAMETER = 'قائمة المدن'; WINDOW_WIDTH  TEXT_PARAMETER = 5; WINDOW_X_POS TEXT_PARAMETER = 1.5; WINDOW_Y_POS TEXT_PARAMETER = .8; CTRY_CD TEXT_PARAMETER = :ADD_CTRY_CD; STATUS TEXT_PARAMETER = 1 |
| PU EXECUTE_FUNCTION | CALL_FORM | `V_CALLED_FORM, no_hide, no_replace, no_query_only, pl_id` | P_USER_ID TEXT_PARAMETER = :PARAMETER.P_USER_ID; P_USER_NAME TEXT_PARAMETER = :PARAMETER.P_USER_NAME; P_WS_ID TEXT_PARAMETER = :PARAMETER.P_WS_ID; P_CURR_PORT_CD TEXT_PARAMETER = :PARAMETER.P_CURR_PORT_CD; P_PORT_TYPE TEXT_PARAMETER = :PARAMETER.P_PORT_TYPE; P_GROUP_CD TEXT_PARAMETER = :PARAMETER.P_GROUP_CD; P_USER_TYPE TEXT_PARAMETER = :PARAMETER.P_USER_TYPE; P_JOB_ID TEXT_PARAMETER = :PARAMETER.P_JOB_ID; P_CLASS_CD TEXT_PARAMETER = :PARAMETER.P_CLASS_CD; P_MODULE_ID TEXT_PARAMETER = TMPLT.FUN_ITEMS(ROW_COUNT).MID; P_MODULE_NAME TEXT_PARAMETER = V_MOD_NAME; P_BRKR_PORT_CD TEXT_PARAMETER = :PARAMETER.P_BRKR_PORT_CD; P_SHPG_AGNT_NBR TEXT_PARAMETER = :PARAMETER.P_SHPG_AGNT_NBR; P_BRKR_NBR TEXT_PARAMETER = :PARAMETER.P_BRKR_NBR; P_LIC_TYPE TEXT_PARAMETER = :PARAMETER.P_LIC_TYPE; P_BANK_CD TEXT_PARAMETER = :PARAMETER.P_BANK_CD; P_BANK_BRNCH_CD TEXT_PARAMETER = :PARAMETER.P_BANK_BRNCH_CD; P_SYS_ID TEXT_PARAMETER = :GLOBAL.SYSTEM_OBJ; P_REP_NO TEXT_PARAMETER = V_SEQ_NO; P_REPORT_NO TEXT_PARAMETER = :GLOBAL.SYSTEM_OBJ \|\|'-'\|\|V_SEQ_NO; DESTYPE TEXT_PARAMETER = 'PRINTER'; PARAMFORM TEXT_PARAMETER = 'NO'; ORACLE_SHUTDOWN TEXT_PARAMETER = 'YES'; MAXIMIZE TEXT_PARAMETER = 'YES' |
| PU EXECUTE_FUNCTION | CALL_FORM | `V_CALLED_FORM, no_hide, no_replace, no_query_only, pl_id` | P_USER_ID TEXT_PARAMETER = :PARAMETER.P_USER_ID; P_USER_NAME TEXT_PARAMETER = :PARAMETER.P_USER_NAME; P_WS_ID TEXT_PARAMETER = :PARAMETER.P_WS_ID; P_CURR_PORT_CD TEXT_PARAMETER = :PARAMETER.P_CURR_PORT_CD; P_PORT_TYPE TEXT_PARAMETER = :PARAMETER.P_PORT_TYPE; P_GROUP_CD TEXT_PARAMETER = :PARAMETER.P_GROUP_CD; P_USER_TYPE TEXT_PARAMETER = :PARAMETER.P_USER_TYPE; P_JOB_ID TEXT_PARAMETER = :PARAMETER.P_JOB_ID; P_CLASS_CD TEXT_PARAMETER = :PARAMETER.P_CLASS_CD; P_MODULE_ID TEXT_PARAMETER = TMPLT.FUN_ITEMS(ROW_COUNT).MID; P_MODULE_NAME TEXT_PARAMETER = V_MOD_NAME; P_BRKR_PORT_CD TEXT_PARAMETER = :PARAMETER.P_BRKR_PORT_CD; P_SHPG_AGNT_NBR TEXT_PARAMETER = :PARAMETER.P_SHPG_AGNT_NBR; P_BRKR_NBR TEXT_PARAMETER = :PARAMETER.P_BRKR_NBR; P_LIC_TYPE TEXT_PARAMETER = :PARAMETER.P_LIC_TYPE; P_BANK_CD TEXT_PARAMETER = :PARAMETER.P_BANK_CD; P_BANK_BRNCH_CD TEXT_PARAMETER = :PARAMETER.P_BANK_BRNCH_CD; P_SYS_ID TEXT_PARAMETER = :GLOBAL.SYSTEM_OBJ; P_REP_NO TEXT_PARAMETER = V_SEQ_NO; P_REPORT_NO TEXT_PARAMETER = :GLOBAL.SYSTEM_OBJ \|\|'-'\|\|V_SEQ_NO; DESTYPE TEXT_PARAMETER = 'PRINTER'; PARAMFORM TEXT_PARAMETER = 'NO'; ORACLE_SHUTDOWN TEXT_PARAMETER = 'YES'; MAXIMIZE TEXT_PARAMETER = 'YES' |
| PU CALL_LOV_COUNTRIES | CALL_FORM | `'LOV_COUNTRIES.fmx', no_hide, no_replace, no_query_only, pl_id` | STATUS TEXT_PARAMETER = 1; WINDOW_TITLE TEXT_PARAMETER = 'قائمة الدول' |
| PU CALL_LOV_COUN_GULF | CALL_FORM | `'LOV_COUNTRIES_GULF.fmx', no_hide, no_replace, no_query_only, pl_id` | WINDOW_TITLE TEXT_PARAMETER = 'قائمة الدول الخليجية' |

### 10.5 Database tables / views referenced in SQL (47)

Extracted from active (non-comment) code. Record-group queries are listed in section 7.

| Object | DML used | Referenced in |
|---|---|---|
| AGNTS | SELECT | PU CGRI$CHK_IMPORTERS |
| BA_OWNERSHIPS | SELECT | PU CGRI$CHK_IMPORTERS |
| BA_WAREHOUSES | SELECT | PU CGRI$CHK_IMPORTERS |
| BL_OWNERS | SELECT | PU CGRI$CHK_IMPORTERS |
| BL_OWNER_HIST | SELECT | PU CGRI$CHK_IMPORTERS |
| BRKIMPS | SELECT | PU CGRI$CHK_IMPORTERS |
| BRKR_MSTR | SELECT | PU CGRI$CHK_IMPORTERS |
| BRKR_UPDTS | SELECT | PU CGRI$CHK_IMPORTERS |
| BUS_ID_TYPES | SELECT | IMPORTERS.IMPR_TYPE_CD.WHEN-VALIDATE-ITEM, PU CGFK$CHK_IMPORTERS_IMP_ITIDT_F, PU CGFK$QRY_IMPORTERS_IMP_ITIDT_F |
| CITIES | SELECT | IMPORTERS.ARBC_IMPR_NAME.KEY-NEXT-ITEM, IMPORTERS.BUS_ID.WHEN-VALIDATE-ITEM, IMPORTERS.CITY_CODE.WHEN-VALIDATE-ITEM, IMPORTERS.CITY_CODE_OF_ID.WHEN-VALIDATE-ITEM, PU CGFK$CHK_IMPORTERS_IMP_ADD_CIT, PU CGFK$CHK_IMPORTERS_IMP_BUS_ID_, PU CGFK$QRY_IMPORTERS_IMP_ADD_CIT, PU CGFK$QRY_IMPORTERS_IMP_BUS_ID_ … (+1) |
| CLIENT_PAY_ACCTS | SELECT | PU CGRI$CHK_IMPORTERS |
| COMM_IMPR_RGSTR | SELECT | IMPORTERS.BUS_ID.WHEN-VALIDATE-ITEM, IMPORTERS.BUS_ID_BRNCH.WHEN-VALIDATE-ITEM |
| COUNTRIES | SELECT | FORM.WHEN-NEW-FORM-INSTANCE, IMPORTERS.IMPR_TYPE_CD.WHEN-VALIDATE-ITEM, PU CGFK$CHK_IMPORTERS_IMP_ADD_CIT, PU CGFK$CHK_IMPORTERS_IMP_CTRY_FK, PU CGFK$QRY_IMPORTERS_IMP_ADD_CIT, PU CGFK$QRY_IMPORTERS_IMP_CTRY_FK |
| CREDIT_LETTERS | SELECT | PU CGRI$CHK_IMPORTERS |
| CSTMS_CLNTS | SELECT | PU CGRI$CHK_IMPORTERS |
| CTRY_GROUP_DETAILS | SELECT | IMPORTERS.CTRY_CD.WHEN-VALIDATE-ITEM, IMPORTERS.IMPR_TYPE_CD.WHEN-VALIDATE-ITEM |
| DCLTN_DOCS | SELECT | PU CGRI$CHK_IMPORTERS |
| DECLARATIONS | SELECT | IMPORTERS.WHEN-NEW-RECORD-INSTANCE, PU CGRI$CHK_IMPORTERS |
| DELAY_AIR_DLVY_ORDERS | SELECT | PU CGRI$CHK_IMPORTERS |
| DELAY_SEA_DLVY_ORDERS | SELECT | PU CGRI$CHK_IMPORTERS |
| DPLMTC_APLCTNS | SELECT | PU CGRI$CHK_IMPORTERS |
| DUAL | SELECT | IMPORTERS.BUS_ID.WHEN-VALIDATE-ITEM, IMPORTERS.CITY_CODE_OF_ID.WHEN-VALIDATE-ITEM, IMPORTERS.IMPR_TYPE_CD.WHEN-VALIDATE-ITEM, PU GET_BRANCH_CR_DATA, PU GET_CR_DATA, PU GET_MAIN_CR_DATA, PU INSERT_AUDIT_RECORD |
| ELIMINATE_REQUESTS | SELECT | PU CGRI$CHK_IMPORTERS |
| EXMTN_A_FORMS | SELECT | PU CGRI$CHK_IMPORTERS |
| EXMTN_DECREES | SELECT | PU CGRI$CHK_IMPORTERS |
| HQ_IMPRS | SELECT | IMPORTERS.PRE-UPDATE |
| IMPORTERS | SELECT | IMPORTERS.BUS_ID.WHEN-VALIDATE-ITEM, IMPORTERS.IMPR_NBR.WHEN-VALIDATE-ITEM, IMPORTERS.IMPR_NBR_PARENT.WHEN-VALIDATE-ITEM, IMPORTERS.PRE-RECORD, PU CHK_IMPR_DUPL |
| IMPR_KNWNS | DELETE, SELECT | IMPORTERS.KEY-DELREC, PU CGRI$CHK_IMPORTERS |
| IMPR_SUSPNS | SELECT | PU CGRI$CHK_IMPORTERS |
| IMPR_TYPES | SELECT | IMPORTERS.IMPR_TYPE_CD.WHEN-VALIDATE-ITEM, IMPORTERS.WHEN-CREATE-RECORD, PU CGFK$CHK_IMPORTERS_IMP_ITIDT_F, PU CGFK$QRY_IMPORTERS_IMP_ITIDT_F |
| IMPR_TYPE_ID_TYPES | SELECT | IMPORTERS.IMPR_TYPE_CD.WHEN-VALIDATE-ITEM, PU CGFK$CHK_IMPORTERS_IMP_ITIDT_F, PU CGFK$QRY_IMPORTERS_IMP_ITIDT_F |
| IMPR_UPDTS | DELETE, INSERT, SELECT | IMPORTERS.KEY-DELREC, PU CGRI$CHK_IMPORTERS, PU INSERT_AUDIT_RECORD |
| LFT_SALES | SELECT | PU CGRI$CHK_IMPORTERS |
| MASS_DUTY_DEF_STLMNTS | SELECT | PU CGRI$CHK_IMPORTERS |
| MCI_BUS_ID_STATUS | SELECT | IMPORTERS.POST-QUERY, PU CGFK$CHK_IMPORTERS_IMP_MB_FK |
| MISSING_DCLTNS | SELECT | PU CGRI$CHK_IMPORTERS |
| PASSENGER_TRIPS | SELECT | PU CGRI$CHK_IMPORTERS |
| REV_SECTIONS_CASH_DTLS | SELECT | PU CGRI$CHK_IMPORTERS |
| SANDY_EXPORTS | SELECT | PU CGRI$CHK_IMPORTERS |
| SC_PORT_SETTING | SELECT | FORM.WHEN-NEW-FORM-INSTANCE, PU EXECUTE_FUNCTION |
| SC_SYSTEM_OBJECTS | SELECT | PU EXECUTE_FUNCTION |
| SD_PORTS | SELECT | IMPORTERS.WHEN-CREATE-RECORD, PU CGFK$CHK_IMPORTERS_IMP_SDP_FK, PU CGFK$QRY_IMPORTERS_IMP_SDP_FK |
| SEA_DLVY_ORDERS | SELECT | PU CGRI$CHK_IMPORTERS |
| SMPL_20_DECLERATIONS | SELECT | PU CGRI$CHK_IMPORTERS |
| VHCL_AUCTION | SELECT | PU CGRI$CHK_IMPORTERS |
| VHCL_CAR_EXPTON | SELECT | PU CGRI$CHK_IMPORTERS |
| WAIVERS | SELECT | PU CGRI$CHK_IMPORTERS |


## 11. Alerts

| Alert | Style | Title | Message | Buttons | Where used (by literal name) | Source |
|---|---|---|---|---|---|---|
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
| P_PORT_TYPE | default (CHAR) / OLB | default/OLB | P_PORT_TYPE | IMPORTERS.PORT_CD.KEY-LISTVAL, PU EXECUTE_FUNCTION, PU PRINT_REPORT |
| P_CURR_PORT_CD | default (CHAR) / OLB | default/OLB | P_CURR_PORT_CD | FORM.WHEN-NEW-FORM-INSTANCE, IMPORTERS.BUS_ID.WHEN-VALIDATE-ITEM, IMPORTERS.BUS_ID_TYPE_CD.KEY-LISTVAL, IMPORTERS.IMPR_NBR_PARENT.KEY-LISTVAL, IMPORTERS.IMPR_NBR_PARENT.WHEN-VALIDATE-ITEM, IMPORTERS.IMPR_TYPE_CD.KEY-LISTVAL, IMPORTERS.IMPR_TYPE_CD.WHEN-VALIDATE-ITEM, IMPORTERS.PRE-RECORD, IMPORTERS.WHEN-CREATE-RECORD, IMPORTERS.WHEN-NEW-RECORD-INSTANCE … (+6) |
| P_MODULE_ID | default (CHAR) / OLB | default/OLB | P_MODULE_ID | FORM.WHEN-NEW-FORM-INSTANCE |
| P_MODULE_NAME | default (CHAR) / OLB | default/OLB | P_MODULE_NAME | FORM.KEY-DUPREC, FORM.KEY-EDIT, FORM.KEY-F5, FORM.WHEN-NEW-FORM-INSTANCE, FORM.WHEN-WINDOW-ACTIVATED, TOOLBAR.EXIT1.WHEN-BUTTON-PRESSED, TOOLBAR.RE_ENTER_QUERY.WHEN-BUTTON-PRESSED, TOOLBAR.SAVE.WHEN-BUTTON-PRESSED |
| P_APPLICATION_NAME | default (CHAR) / OLB | default/OLB | P_APPLICATION_NAME | – |
| P_USER_ID | default (CHAR) / OLB | default/OLB | P_USER_ID | FORM.WHEN-NEW-FORM-INSTANCE, IMPORTERS.PRE-INSERT, PU EDI_MSG_LOV, PU EXECUTE_FUNCTION, PU FOR_EDI_MSG, PU INSERT_AUDIT_RECORD, PU PRINT_REPORT |
| P_WS_ID | default (CHAR) / OLB | default/OLB | P_WS_ID | IMPORTERS.PRE-INSERT, PU EXECUTE_FUNCTION, PU PRINT_REPORT |
| P_USER_NAME | default (CHAR) / OLB | default/OLB | P_USER_NAME | FORM.KEY-DUPREC, FORM.KEY-EDIT, FORM.KEY-F5, FORM.WHEN-WINDOW-ACTIVATED, PU EDI_MSG_LOV, PU EXECUTE_FUNCTION, PU PRINT_REPORT, TOOLBAR.EXIT1.WHEN-BUTTON-PRESSED, TOOLBAR.RE_ENTER_QUERY.WHEN-BUTTON-PRESSED, TOOLBAR.SAVE.WHEN-BUTTON-PRESSED |
| CG$STARTUP_MODE | default (CHAR) / OLB | NORMAL | – | – |
| PRSNL_IMPR | default (CHAR) / OLB | 0 | – | IMPORTERS.PRE-QUERY, IMPORTERS.WHEN-CREATE-RECORD |
| LETTER_NBR | default (CHAR) / OLB | – | – | FORM.WHEN-NEW-FORM-INSTANCE |

### 12.1 :GLOBAL variables (28)

| Global | Read in | Written in |
|---|---|---|
| ALLOW_MCI | FORM.WHEN-NEW-FORM-INSTANCE, IMPORTERS.IMPR_TYPE_CD.WHEN-VALIDATE-ITEM, IMPORTERS.NATIONAL_NBR.WHEN-VALIDATE-ITEM, PU ADJ_FUNS, PU EXEC_FUNS | FORM.WHEN-NEW-FORM-INSTANCE |
| ALLOW_MOI | FORM.WHEN-NEW-FORM-INSTANCE, PU ADJ_FUNS, PU EXEC_FUNS | FORM.WHEN-NEW-FORM-INSTANCE |
| BUS_ID_TYPE_CD | IMPORTERS.BUS_ID_TYPE_CD.KEY-LISTVAL, IMPORTERS.IMPR_TYPE_CD.KEY-LISTVAL | – |
| BUS_ID_TYPE_NAME | IMPORTERS.BUS_ID_TYPE_CD.KEY-LISTVAL, IMPORTERS.IMPR_TYPE_CD.KEY-LISTVAL | – |
| CG$HP_HFILE | FORM.KEY-HELP, IMPORTERS.KEY-HELP | FORM.KEY-HELP, IMPORTERS.KEY-HELP |
| CG$HP_HPATH | FORM.KEY-HELP, IMPORTERS.KEY-HELP | FORM.PRE-FORM |
| CITY_ARB_NAME | IMPORTERS.CITY_CODE.KEY-LISTVAL, IMPORTERS.CITY_CODE_OF_ID.KEY-LISTVAL | – |
| CITY_CD | IMPORTERS.CITY_CODE.KEY-LISTVAL, IMPORTERS.CITY_CODE_OF_ID.KEY-LISTVAL | – |
| CRTY_ARBC_NAME | IMPORTERS.ADD_CTRY_CD.KEY-LISTVAL, PU CALL_LOV_COUNTRIES, PU CALL_LOV_COUN_GULF | – |
| CTRY_CD | IMPORTERS.ADD_CTRY_CD.KEY-LISTVAL, IMPORTERS.CITY_CODE.KEY-LISTVAL, IMPORTERS.CITY_CODE_OF_ID.KEY-LISTVAL, PU CALL_LOV_COUNTRIES, PU CALL_LOV_COUN_GULF | – |
| CURRENT_DT | FORM.WHEN-NEW-FORM-INSTANCE | FORM.WHEN-NEW-FORM-INSTANCE |
| CURRENT_VER | FORM.WHEN-NEW-FORM-INSTANCE | FORM.WHEN-NEW-FORM-INSTANCE |
| CURRENT_VERSION | – | FORM.WHEN-NEW-FORM-INSTANCE |
| EXEC_QUERY_NOW | IMPORTERS.BUS_ID_EXPRD_DT.WHEN-NEW-ITEM-INSTANCE, IMPORTERS.IMPR_TYPE_CD.WHEN-NEW-ITEM-INSTANCE, IMPORTERS.PRE-QUERY, IMPORTERS.WHEN-NEW-ITEM-INSTANCE | FORM.WHEN-NEW-FORM-INSTANCE, IMPORTERS.IMPR_NBR.WHEN-VALIDATE-ITEM, IMPORTERS.PRE-QUERY, IMPORTERS.WHEN-NEW-ITEM-INSTANCE, PU UPDATE_IMPORTER |
| EXIT | TOOLBAR.EXIT.WHEN-BUTTON-PRESSED | – |
| IMPR_NAME | IMPORTERS.IMPR_NBR_PARENT.KEY-LISTVAL | – |
| IMPR_NBR | IMPORTERS.IMPR_NBR_PARENT.KEY-LISTVAL, IMPORTERS.PRE-QUERY | FORM.WHEN-NEW-FORM-INSTANCE, IMPORTERS.IMPR_NBR.WHEN-VALIDATE-ITEM, IMPORTERS.PRE-QUERY, PU UPDATE_IMPORTER |
| IMPR_TYPE_CD | IMPORTERS.BUS_ID_TYPE_CD.KEY-LISTVAL, IMPORTERS.IMPR_TYPE_CD.KEY-LISTVAL | – |
| IMPR_TYPE_NAME | IMPORTERS.BUS_ID_TYPE_CD.KEY-LISTVAL, IMPORTERS.IMPR_TYPE_CD.KEY-LISTVAL | – |
| INS | – | IMPORTERS.WHEN-CREATE-RECORD |
| LETTER_DT | IMPORTERS.PRE-INSERT | – |
| LETTER_NBR | FORM.WHEN-NEW-FORM-INSTANCE, IMPORTERS.PRE-INSERT | – |
| PORT_CD | IMPORTERS.PORT_CD.KEY-LISTVAL, IMPORTERS.PRE-INSERT, IMPORTERS.PRE-QUERY | FORM.WHEN-NEW-FORM-INSTANCE, IMPORTERS.IMPR_NBR.WHEN-VALIDATE-ITEM, IMPORTERS.PRE-QUERY, PU UPDATE_IMPORTER |
| PORT_NAME | IMPORTERS.PORT_CD.KEY-LISTVAL | – |
| SET | IMPORTERS.PRE-INSERT | IMPORTERS.PRE-INSERT |
| SUPP_TITLE_CD | IMPORTERS.PRE-INSERT | – |
| SYSTEM_OBJ | PU EXECUTE_FUNCTION | PU EXECUTE_FUNCTION (DEFAULT_VALUE) |
| VALID | IMPORTERS.IMPR_TYPE_CD.WHEN-VALIDATE-ITEM | FORM.WHEN-NEW-FORM-INSTANCE, IMPORTERS.IMPR_TYPE_CD.KEY-LISTVAL, IMPORTERS.IMPR_TYPE_CD.WHEN-VALIDATE-ITEM |

### 12.2 :SYSTEM variables (11)

| Variable | Used in |
|---|---|
| CURRENT_FORM | TOOLBAR.EXIT1.WHEN-BUTTON-PRESSED |
| CURSOR_BLOCK | IMPORTERS.ADD_CRTY_ARBC_NAME.KEY-LISTVAL, IMPORTERS.ADD_CTRY_CD.KEY-LISTVAL, IMPORTERS.ARBC_IMPR_NAME.KEY-LISTVAL, IMPORTERS.BUS_ID.KEY-LISTVAL, IMPORTERS.BUS_ID_BRNCH.KEY-LISTVAL, IMPORTERS.BUS_ID_EXPRD_DT.KEY-F4 … (+45) |
| CURSOR_ITEM | IMPORTERS.ADD_CRTY_ARBC_NAME.KEY-LISTVAL, IMPORTERS.ADD_CTRY_CD.KEY-LISTVAL, IMPORTERS.ARBC_IMPR_NAME.KEY-LISTVAL, IMPORTERS.BUS_ID.KEY-LISTVAL, IMPORTERS.BUS_ID_BRNCH.KEY-LISTVAL, IMPORTERS.BUS_ID_BRNCH.WHEN-VALIDATE-ITEM … (+50) |
| CURSOR_RECORD | IMPORTERS.ADD_CRTY_ARBC_NAME.KEY-LISTVAL, IMPORTERS.ADD_CTRY_CD.KEY-LISTVAL, IMPORTERS.ARBC_IMPR_NAME.KEY-LISTVAL, IMPORTERS.BUS_ID.KEY-LISTVAL, IMPORTERS.BUS_ID_BRNCH.KEY-LISTVAL, IMPORTERS.BUS_ID_EXPRD_DT.KEY-F4 … (+45) |
| CURSOR_VALUE | IMPORTERS.BUS_ID_EXPRD_DT.WHEN-VALIDATE-ITEM, IMPORTERS.BUS_ID_ISSUE_DT.WHEN-VALIDATE-ITEM, IMPORTERS.EMAIL.WHEN-VALIDATE-ITEM, TITLE.SYSTEM_DATE.WHEN-VALIDATE-ITEM |
| FORM_STATUS | FORM.KEY-CLRFRM, TOOLBAR.SAVE.WHEN-BUTTON-PRESSED |
| MESSAGE_LEVEL | PU UPDATE_IMPORTER |
| MODE | IMPORTERS.ADD_CRTY_ARBC_NAME.KEY-LISTVAL, IMPORTERS.ADD_CTRY_CD.KEY-LISTVAL, IMPORTERS.ARBC_IMPR_NAME.KEY-LISTVAL, IMPORTERS.BUS_ID.KEY-LISTVAL, IMPORTERS.BUS_ID_BRNCH.KEY-LISTVAL, IMPORTERS.BUS_ID_EXPRD_DT.KEY-F4 … (+47) |
| RECORD_STATUS | IMPORTERS.BUS_ID_BRNCH.KEY-NEXT-ITEM, IMPORTERS.CITY_CODE_OF_ID.WHEN-VALIDATE-ITEM, IMPORTERS.CTRY_CD_OF_ID.WHEN-VALIDATE-ITEM |
| TRIGGER_ITEM | IMPORTERS.BUS_ID_BRNCH.WHEN-VALIDATE-ITEM, IMPORTERS.BUS_ID_EXPRD_DT.WHEN-VALIDATE-ITEM, IMPORTERS.BUS_ID_ISSUE_DT.WHEN-VALIDATE-ITEM, IMPORTERS.CITY_CODE_OF_ID.WHEN-VALIDATE-ITEM, IMPORTERS.EMAIL.WHEN-VALIDATE-ITEM, TITLE.SYSTEM_DATE.WHEN-VALIDATE-ITEM |
| TRIGGER_RECORD | IMPORTERS.POST-QUERY |


## 13. Menu & Security


## 14. Risk Assessment


## 15. Open Questions / Missing Sources

