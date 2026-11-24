# SUPPORT_ENTRY – Inventory & Migration Risk Assessment

- **Form:** SUPPORT_ENTRY – window title "بيانات المساندة الفنية" (support letter that authorises a change in the calling form)
- **Source:** `forms/SC/Support_Entry_fmb.xml` (frmf2xml output, 76 lines, 17 KB), read in full
- **Target:** Oracle APEX 21.2 on Oracle Database 12.1.0.2, reference application f345 (CLAUDE.md §4b, §4c)
- **Produced:** 2026-11-24, Claude Code, step 01 (revision 2: user decisions on Q1 / Q3 and the `DB_JOURNAL` source added,
  §15.1). Input from the IMPR1110 session: `analysis/SUPPORT_ENTRY/SUPPORT_ENTRY_handoff_from_IMPR1110.md`.
- **Sources used besides the form XML:** the callers `forms/IMPR/IMPR1110_fmb.xml` (PU `EXEC_FUNS`, `IMPORTERS.PRE-UPDATE`) and
  `forms/IMPR/IMPR1130_fmb.xml` (`WHEN-NEW-FORM-INSTANCE`, `IMPORTERS.PRE-INSERT`), the object library
  `forms/COMMON/olb/CIC_OLB_OLB.xml` (toolbar `SAVE` / `CLEAR_ALL` / `EXIT` / `EXIT1`), the IMPR1110 APEX export
  (`apex/IMPR1110/f345_impr1110.sql`: LOV `LOV_SD_PORTS`, application items `G_*`), `plsql_templates/forms_apx.sql` (version 004),
  DB package `plsql/Shared/DB_JOURNAL.pks` / `.pkb` (owner `JOURNAL`, used by the callers with the values this form returns),
  IMPR1110 package `plsql/IMPR1110/impr1110_body.sql` (its `JOURNALING_ON` / `JOURNALING_OFF` calls).
- **Scope rule:** what is not available is marked **MISSING SOURCE** and not guessed: library `OFGTEL` (attached, not called),
  table definitions of `SD_PORTS`, `SUPP_TITLES`, `CG_REF_CODES`.

## 1. Summary

**Complexity: SIMPLE** · **Effort ESTIMATE: 1.5–2.5 developer-days** (page, small package, two LOVs, tests; plus the IMPR1110 TODOs of §10.4)

### 1.1 Counts

| Object | Count | Notes |
|---|---|---|
| Blocks | 1 | `RP`, control block (no base table), 1 record |
| Items | 10 | 4 entry items, 2 display items, 2 buttons (`AGREE`, `CANCEL`), 2 iconic LOV buttons |
| Triggers | 11 | Form 2 · Block 0 · Item 9. 8 contain code, 3 are empty (`LETTER_DT` KEY-LISTVAL, KEY-F4, WHEN-VALIDATE-ITEM) |
| Trigger PL/SQL lines | 144 total / 82 active | 62 lines are the commented-out LOV-form calls in the two LOV buttons |
| Program units | 0 | |
| Relations | 0 | |
| LOVs / Record groups | 2 / 2 | `LOV_SD_PORTS`, `LOV_SUPP_TITLES` (query record groups, no runtime RG) |
| Canvases / Windows | 1 / 1 | `CANVAS1` on `RP_WINDOW` (dialog style, not modal, fixed size) |
| Alerts | 10 | Designer / CIC defaults; **none is used** by active code |
| Module parameters | 4 | `P_MODE` (default **1**), `P_CURR_PORT_CD`, `WINDOW_X_POS`, `WINDOW_Y_POS` |
| Globals | 6 written, 4 read | `PORT_CD`, `PORT_NAME`, `SUPP_TITLE_CD`, `SUPP_TITLE_NAME`, `LETTER_NBR`, `LETTER_DT` (§12) |
| Attached libraries | 6 | OFGTEL, OFGMES, OFGHPL, CIC_LIB, D2KWUTIL, CAPTION – **no active call** into any of them |
| Called forms | 0 active | `REP_LOV_SD_PORTS`, `LOV_SUPP_TITLES` only in commented-out code |
| DML | none | no base table, no COMMIT; output goes back through globals only |

### 1.2 Complexity rubric

| Metric | Value | Simple | Medium | Complex | Category |
|---|---|---|---|---|---|
| Data blocks | 1 | 1–2 | 3–5 | > 5 | Simple |
| Triggers (total) | 11 | < 15 | 15–50 | > 50 | Simple |
| Lines of PL/SQL | 144 (82 active) | < 300 | 300–1500 | > 1500 | Simple |
| Master–detail relations | 0 | 0–1 | 2–3 | > 3 | Simple |
| Called forms / libraries | 0 forms + 6 libraries attached (0 used) | 0 | 1–3 | > 3 | Complex by count only |
| Special features | none | none | 1 | ≥ 2 | Simple |

**Result: SIMPLE** (only one metric reaches Complex; the rubric needs two).

**Justification.** One control block with four entry fields, two lookups and two buttons; no DML, no program units. The six
attached libraries are not called by active code, so they do not add work. The real effort is the **contract with the callers**
(globals in and out, `P_MODE`, the Hijri date that `DB_JOURNAL` receives as a DATE) and the edit mode, which IMPR1130 used as a
modeless companion window and which becomes the same dialog opened on demand (§14 R1, decision D1).

**Effort ESTIMATE: 1.5–2.5 developer-days.**

## 2. Module header

| Property | Value |
|---|---|
| Form name | SUPPORT_ENTRY |
| Title | – (empty; window title "بيانات المساندة الفنية") |
| Language direction | Right To Left |
| First navigation block | – (not set → first block `RP`) |
| Console window | – |
| Menu module | – (empty: no menu) |
| Validation unit | – (default) |
| Interaction mode | – (default) |
| Coordinate system | Real, Inch; character cell 100 × 200 |

## 3. Blocks

| Block | Base table / query source | Type | Records displayed | WHERE | ORDER BY | Insert / Update / Delete / Query | Canvas |
|---|---|---|---|---|---|---|---|
| RP | – (`DatabaseBlock="false"`) | control | 1 (default) | – | – | n/a (control block) | CANVAS1 |

## 4. Items – block RP

Listed in the block's item order (= Forms navigation order). Positions in 1/1000 inch, RTL canvas.

| # | Item | Item type | Data type | Max length | Column | DB item | Required | LOV | Default | Format mask | Canvas (X, Y) | Visible / enabled | Prompt / label | Notes |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | AGREE | Push Button | – | – | – | – | – | – | – | – | CANVAS1 (1450, 953) | yes | موافق (WNFI: موافق / تعديل by `P_MODE`) | WHEN-BUTTON-PRESSED |
| 2 | CANCEL | Push Button | – | – | – | – | – | – | – | – | CANVAS1 (2554, 953) | yes | تراجع (WNFI: تراجع / إغلاق by `P_MODE`) | WHEN-BUTTON-PRESSED |
| 3 | P_PORT_CD | Text Item | Char (default) | 30 (default) | – | No | No (checked by AGREE) | LOV_SD_PORTS | – (WNFI) | – | CANVAS1 (1007, 48) | yes | جمــرك الخطاب: | WHEN-VALIDATE-ITEM fills `P_PORT_NAME` |
| 4 | P_LOV_PORT | Push Button (iconic `aflist`) | – | – | – | – | – | – | – | – | CANVAS1 (1715, 59) | yes, not keyboard / mouse navigable | – | opens the LOV of `P_PORT_CD` |
| 5 | P_PORT_NAME | Text Item | Char | 100 | – | No | No | – | – | – | CANVAS1 (1960, 48) | visible, **disabled** (no insert / update) | – | display of the port name |
| 6 | SUPP_TITLE_CD | Text Item | Char (default) | 30 (default) | – | No | No (checked by AGREE) | LOV_SUPP_TITLES | – (WNFI) | – | CANVAS1 (1007, 339) | yes | جهــــة الخطاب: | WHEN-VALIDATE-ITEM fills `SUPP_TITLE_NM` |
| 7 | P_LOV_SUPP_TITLES | Push Button (iconic `aflist`) | – | – | – | – | – | – | – | – | CANVAS1 (1716, 349) | yes, not keyboard / mouse navigable | – | opens the LOV of `SUPP_TITLE_CD` |
| 8 | SUPP_TITLE_NM | Text Item | Char | 30 (default) | – | No | No | – | – | – | CANVAS1 (1960, 339) | visible, **disabled** | – | display of the title name; record group column is 40 long (§14 R6) |
| 9 | LETTER_NBR | Text Item | Char (default) | 50 | – | No | No (checked by AGREE) | – | – (WNFI) | – | CANVAS1 (1007, 630) | yes | رقــــــم الخطاب: | |
| 10 | LETTER_DT | Text Item | **Datetime** | 10 | – | No | No (checked by AGREE) | – | – (WNFI) | **`MI-MM-RRRR`** | CANVAS1 (3604, 627) | yes, auto-skip | تاريخ الخطاب: | Hijri date: day in the minutes (§14 R2); empty KEY-LISTVAL / KEY-F4 / WVI |

Layout: three rows (port, title, letter number + date on one row) and the button row. Code and name of a lookup sit side by side,
the LOV icon between them.

## 5. Relations

None.

## 6. Triggers

### 6.1 Form level

**WHEN-NEW-FORM-INSTANCE** (21 lines, all active)

```plsql
IF :PARAMETER.P_MODE = 0 THEN
	:GLOBAL.PORT_NAME := NULL;
	:GLOBAL.SUPP_TITLE_NAME := NULL;
	:GLOBAL.PORT_CD := NULL;
	:GLOBAL.SUPP_TITLE_CD := NULL;
	:GLOBAL.LETTER_NBR := NULL;
	:GLOBAL.LETTER_DT := NULL;
	SET_ITEM_PROPERTY('AGREE',LABEL,'موافق');
	SET_ITEM_PROPERTY('CANCEL',LABEL,'تراجع');
	:P_PORT_CD := :PARAMETER.P_CURR_PORT_CD;
	GO_ITEM('P_PORT_CD');
	VALIDATE(ITEM_SCOPE);
ELSE
	:P_PORT_CD := :GLOBAL.PORT_CD;
	:SUPP_TITLE_CD := :GLOBAL.SUPP_TITLE_CD;
	:LETTER_NBR := :GLOBAL.LETTER_NBR;
	:LETTER_DT := :GLOBAL.LETTER_DT;
	VALIDATE(FORM_SCOPE);
	SET_ITEM_PROPERTY('AGREE',LABEL,'تعديل');
	SET_ITEM_PROPERTY('CANCEL',LABEL,'إغلاق');
END IF;
```

- Built-ins: `SET_ITEM_PROPERTY(LABEL)`, `GO_ITEM`, `VALIDATE(ITEM_SCOPE / FORM_SCOPE)`.
- Mode 0 (new letter): clears all six globals **at start**, defaults the port from `P_CURR_PORT_CD`, validates it (fills `P_PORT_NAME`).
- Other mode (edit): loads the four values from the globals; `VALIDATE(FORM_SCOPE)` fires both WHEN-VALIDATE-ITEM triggers, which
  fill the two names (the globals `PORT_NAME` / `SUPP_TITLE_NAME` are not read). `:LETTER_DT := :GLOBAL.LETTER_DT` is a CHAR→DATE
  conversion (§14 R2).
- Because mode 0 clears the globals on entry, leaving the window by any other way than AGREE leaves them NULL; the callers then do
  nothing (§10.4).

**PRE-FORM** (1 line)

```plsql
SET_WINDOW_PROPERTY('RP_WINDOW',POSITION,:PARAMETER.WINDOW_X_POS,:PARAMETER.WINDOW_Y_POS);
```

- Built-in: `SET_WINDOW_PROPERTY(POSITION)`. Window position only → no APEX equivalent needed (modal dialog is centred).

### 6.2 Block level

None.

### 6.3 Item level

**RP.AGREE WHEN-BUTTON-PRESSED** (25 lines)

```plsql
IF :P_PORT_CD IS NULL THEN
	GO_ITEM('P_PORT_CD');
	RAISE FORM_TRIGGER_FAILURE; 
END IF;
IF :SUPP_TITLE_CD IS NULL THEN
	GO_ITEM('SUPP_TITLE_CD');
	RAISE FORM_TRIGGER_FAILURE; 
END IF;
IF :LETTER_NBR IS NULL THEN
	GO_ITEM('LETTER_NBR');
	RAISE FORM_TRIGGER_FAILURE; 
END IF;
IF :LETTER_DT IS NULL THEN
	GO_ITEM('LETTER_DT');
	RAISE FORM_TRIGGER_FAILURE; 
END IF;
:GLOBAL.PORT_CD := :P_PORT_CD;
:GLOBAL.PORT_NAME := :P_PORT_NAME;
:GLOBAL.SUPP_TITLE_CD := :SUPP_TITLE_CD;
:GLOBAL.SUPP_TITLE_NAME := :SUPP_TITLE_NM;
:GLOBAL.LETTER_NBR := :LETTER_NBR;
:GLOBAL.LETTER_DT := :LETTER_DT;
IF :PARAMETER.P_MODE = 0 THEN
	EXIT_FORM(NO_VALIDATE);
END IF;
```

- Built-ins: `GO_ITEM`, `RAISE FORM_TRIGGER_FAILURE`, `EXIT_FORM(NO_VALIDATE)`.
- The four "required" checks stop **without a message** (only the cursor moves). In APEX the user needs a message (§14 R4).
- Before the button trigger runs, Forms validates the current item, so an unknown code is already rejected by its WVI.
- Mode 0: sets the globals and closes. Edit mode: sets the globals and **stays open** (label "تعديل").
- `:GLOBAL.LETTER_DT := :LETTER_DT` is a DATE→CHAR conversion (§14 R2).

**RP.CANCEL WHEN-BUTTON-PRESSED** (9 lines)

```plsql
IF :PARAMETER.P_MODE = 0 THEN
	:GLOBAL.PORT_NAME := NULL;
	:GLOBAL.SUPP_TITLE_NAME := NULL;
	:GLOBAL.PORT_CD := NULL;
	:GLOBAL.SUPP_TITLE_CD := NULL;
	:GLOBAL.LETTER_NBR := NULL;
	:GLOBAL.LETTER_DT := NULL;
END IF;
EXIT_FORM(NO_VALIDATE);
```

- Mode 0: clears the globals (already NULL since WNFI unless AGREE failed half-way – it cannot: the globals are set only after
  all checks pass) and closes. Edit mode ("إغلاق"): closes and **keeps** the globals.

**RP.P_PORT_CD WHEN-VALIDATE-ITEM** (11 lines)

```plsql
BEGIN
 IF :P_PORT_CD IS NULL THEN
	RETURN;
 END IF;
 SELECT PORT_NAME INTO :P_PORT_NAME
 FROM SD_PORTS
 WHERE PORT_CD = :P_PORT_CD;
EXCEPTION 
 WHEN NO_DATA_FOUND THEN 
	RAISE FORM_TRIGGER_FAILURE;
END;
```

- Unknown port → silent failure (no message), the cursor stays in the item. A NULL code returns without clearing `P_PORT_NAME`
  (the old name stays on screen – Forms quirk, keep or fix: §14 R5).
- `RETURN` inside a trigger block is accepted by Forms; in the package it becomes a plain IF.

**RP.P_LOV_PORT WHEN-BUTTON-PRESSED** (35 lines, 2 active)

Active code:

```plsql
GO_ITEM('P_PORT_CD');
DO_KEY('LIST_VALUES');
```

The other 33 lines are a commented-out call of the LOV form `REP_LOV_SD_PORTS.FMX` (CALL_FORM in mode 0, OPEN_FORM otherwise,
result through `:GLOBAL.PORT_CD` / `PORT_NAME`). Not converted (inactive); recorded for traceability.

**RP.SUPP_TITLE_CD WHEN-VALIDATE-ITEM** (11 lines)

```plsql
BEGIN
 IF :SUPP_TITLE_CD IS NULL THEN
	RETURN;
 END IF;
 SELECT SUPP_TITLE_NM INTO :SUPP_TITLE_NM
 FROM SUPP_TITLES
 WHERE SUPP_TITLE_CD = :SUPP_TITLE_CD;
EXCEPTION 
 WHEN NO_DATA_FOUND THEN 
	RAISE FORM_TRIGGER_FAILURE;
END;
```

- Same pattern as `P_PORT_CD`. Note: the WVI does **not** check `TITLE_STATUS = 1`, while the LOV shows only active titles
  (typed code of an inactive title is accepted – keep as is, §14 R5).

**RP.P_LOV_SUPP_TITLES WHEN-BUTTON-PRESSED** (31 lines, 2 active)

```plsql
GO_ITEM('SUPP_TITLE_CD');
DO_KEY('LIST_VALUES');
```

The rest is a commented-out call of `LOV_SUPP_TITLES.FMX` (result through `:GLOBAL.SUPP_TITLE_CD` / `SUPP_TITLE_NM`).

**RP.LETTER_DT KEY-LISTVAL, KEY-F4, WHEN-VALIDATE-ITEM** – all three have no code. KEY-LISTVAL / KEY-F4 switch off any list or
calendar key on the date; the empty WVI does nothing (there is no block- or form-level WVI to override).

### 6.4 Built-ins used (active code)

`GO_ITEM`, `RAISE FORM_TRIGGER_FAILURE`, `EXIT_FORM(NO_VALIDATE)`, `SET_ITEM_PROPERTY(LABEL)`, `VALIDATE(ITEM_SCOPE / FORM_SCOPE)`,
`SET_WINDOW_PROPERTY(POSITION)`, `DO_KEY('LIST_VALUES')`. No library or program-unit calls.

## 7. LOVs & Record Groups

| LOV | Title | Record group | Query (decoded) | Columns → return items | Validate from list | Auto display |
|---|---|---|---|---|---|---|
| LOV_SD_PORTS | قائمة المنافذ الجمركية | LOV_SD_PORTS | `SELECT ALL SD_PORTS.PORT_CD, SD_PORTS.PORT_NAME, CG_REF_CODES.RV_MEANING FROM CG_REF_CODES, SD_PORTS WHERE (CG_REF_CODES.RV_LOW_VALUE = SD_PORTS.PORT_TYPE) AND CG_REF_CODES.RV_DOMAIN = 'PORT_TYPE_CD' ORDER BY PORT_CD` | PORT_CD "رمز الجمرك" → RP.P_PORT_CD; RV_MEANING "نوع الجمرك" → –; PORT_NAME "اسم الجمرك" → RP.P_PORT_NAME | No (default) | No (default) |
| LOV_SUPP_TITLES | قائمة معتمدي الخطابات | LOV_SUPP_TITLES | `SELECT ALL SUPP_TITLES.SUPP_TITLE_CD, SUPP_TITLES.SUPP_TITLE_NM FROM SUPP_TITLES WHERE TITLE_STATUS = 1` | SUPP_TITLE_CD "رمز معتمد الخطاب" → RP.SUPP_TITLE_CD; SUPP_TITLE_NM "معتمد الخطاب" → RP.SUPP_TITLE_NM | No (default) | No (default) |

Record-group column types: `PORT_CD` Number(23), `PORT_NAME` Char(30), `RV_MEANING` Char(240), `SUPP_TITLE_CD` Number(23),
`SUPP_TITLE_NM` Char(40). No record groups without an LOV, none created at runtime.

**Comparison with the existing APEX LOV `LOV_SD_PORTS`** (created by the IMPR1110 export, `apex/IMPR1110/f345_impr1110.sql` line 262):
`SELECT port_cd d, port_cd r, port_name FROM sd_ports WHERE port_status = 1 AND port_type = NVL(:P_PORT_TYPE, port_type) ORDER BY port_cd`.
It is **not the same** list: it filters active ports and a port type, has no port-type meaning column, and binds `:P_PORT_TYPE`.
SUPPORT_ENTRY shows every port that has a known port type. → A separate shared LOV is needed (name decided in step 03, §15 Q3).
`LOV_SUPP_TITLES` does not exist in APEX yet.

## 8. Canvases & Windows

| Canvas | Type | Window | Size | Items shown |
|---|---|---|---|---|
| CANVAS1 | Content | RP_WINDOW | 7500 × 4500 (viewport 7500 × 4500) | all 10 items |

| Window | Style | Modal | Title | Size | Other |
|---|---|---|---|---|---|
| RP_WINDOW | Dialog | **No** (modal behaviour comes from CALL_FORM in mode 0) | بيانات المساندة الفنية | 4979 × 1271 | not resizable, no minimise / maximise, hide on exit; position from `WINDOW_X_POS` / `WINDOW_Y_POS` |

No WHEN-WINDOW-CLOSED trigger: the window close box does nothing; the user leaves through AGREE or CANCEL.

## 9. Program Units

None.

## 10. External Dependencies

### 10.1 Attached libraries

| Library | Source available | Called by this form |
|---|---|---|
| OFGTEL | **MISSING SOURCE** | no |
| OFGMES | `forms/COMMON/libraries/OFGMES.pld` | no |
| OFGHPL | `forms/COMMON/libraries/OFGHPL.pld` | no |
| CIC_LIB | `forms/COMMON/libraries/CIC_LIB.pld` | no (`STR.DISPALERT` only in commented-out code) |
| D2KWUTIL | `forms/COMMON/libraries/d2kwutil.pld` | no |
| CAPTION | `forms/COMMON/libraries/caption.pld` | no |

None of them needs a database equivalent for this form.

### 10.2 Called forms, reports, HOST

No active call. Commented-out: `REP_LOV_SD_PORTS.FMX`, `LOV_SUPP_TITLES.FMX` (both available in `forms/COMMON/lov_forms/`, not needed).
No reports, HOST, TEXT_IO, WEB.SHOW_DOCUMENT.

### 10.3 Database objects

| Object | Type | Used in | Columns used |
|---|---|---|---|
| SD_PORTS | table | `P_PORT_CD` WVI, RG `LOV_SD_PORTS` | PORT_CD, PORT_NAME, PORT_TYPE |
| CG_REF_CODES | table | RG `LOV_SD_PORTS` | RV_LOW_VALUE, RV_DOMAIN (`'PORT_TYPE_CD'`), RV_MEANING |
| SUPP_TITLES | table | `SUPP_TITLE_CD` WVI, RG `LOV_SUPP_TITLES` | SUPP_TITLE_CD, SUPP_TITLE_NM, TITLE_STATUS |

Table DDL is not in the repository (**MISSING SOURCE**: column types assumed from the record groups: codes NUMBER, names VARCHAR2).
`LIB_APX_USR` needs SELECT grants on the three tables (step 02 grant list).

### 10.4 Callers and the contract (verified in the caller XML)

Of the 63 XML files that mention SUPPORT_ENTRY, **only two call it**. The other 61 (all SC forms, the other IMPR forms, the LOV forms)
carry the CIC_OLB toolbar, whose `SAVE`, `CLEAR_ALL`, `EXIT` and `EXIT1` buttons only close the form if it is open
(`IF NOT ID_NULL(FIND_FORM('SUPPORT_ENTRY')) THEN CLOSE_FORM('SUPPORT_ENTRY')`; SAVE only when `:SYSTEM.FORM_STATUS = 'QUERY'`
after its COMMIT).

| Caller | Where | Call | Then |
|---|---|---|---|
| IMPR1110 | PU `EXEC_FUNS`, functions IMPR1110F1, F2, F3, F5 | `CALL_FORM('SUPPORT_ENTRY.FMX', NO_HIDE, NO_REPLACE, NO_QUERY_ONLY, PL_ID)` with `WINDOW_X_POS = 1.5`, `WINDOW_Y_POS = 2`, `P_MODE = 0`, `P_CURR_PORT_CD = :IMPORTERS.PORT_CD` | if `:GLOBAL.LETTER_NBR IS NOT NULL`: `:PARAMETER.CODE := CD`, `:PARAMETER.LETTER_NBR := :GLOBAL.LETTER_NBR`, `GO_BLOCK('IMPORTERS')`. `OPEN_FORM('SUPPORT_ENTRY.FMX')` is commented out (`--`) |
| IMPR1130 | form-level `WHEN-NEW-FORM-INSTANCE` | the same CALL_FORM with `P_MODE = 0` | if `:GLOBAL.LETTER_NBR IS NOT NULL`: sets `:PARAMETER.LETTER_NBR`, goes to `IMPR_NBR`, disables `PORT_CD`, then **`OPEN_FORM('SUPPORT_ENTRY.FMX')` without a parameter list → edit mode (`P_MODE` default 1)**, a modeless window that shows the letter next to IMPR1130 until the toolbar closes it |

Globals read later by the callers: `IMPORTERS.PRE-UPDATE` (IMPR1110) and `IMPORTERS.PRE-INSERT` (IMPR1130) call
`DB_JOURNAL.JOURNALING_ON(:GLOBAL.PORT_CD, :GLOBAL.SUPP_TITLE_CD, :GLOBAL.LETTER_NBR, :GLOBAL.LETTER_DT)` when `:GLOBAL.LETTER_NBR`
is set; IMPR1110's `IMPORTERS.POST-UPDATE` calls `JOURNALING_OFF`. `GLOBAL.PORT_NAME` and `GLOBAL.SUPP_TITLE_NAME` are written by
this form but read by neither caller.

### 10.6 DB_JOURNAL (source `plsql/Shared/DB_JOURNAL.pks` / `.pkb`, owner `JOURNAL`, public synonym `DB_JOURNAL`)

SUPPORT_ENTRY does not call it; it collects the four values that the callers hand to it. What the source shows:

| Member | Signature | What it does |
|---|---|---|
| `JOURNALING_ON` | `(supp_srce_cd NUMBER, supp_title_cd NUMBER, supp_letr_no VARCHAR2, supp_letr_dt DATE)` | stores the four values in **package variables** (`suppSrceCd NUMBER(3)`, `suppTitleCd NUMBER(2)`, `suppLetrNo VARCHAR2(50)`, `suppLetrDt DATE`) and sets `journalingOn := TRUE` |
| `JOURNALING_OFF` | – | clears the variables, `journalingOn := FALSE` |
| `IS_JOURNALING_ON` | `RETURN BOOLEAN` | |
| `GET_JOURNALING_PARAMS` | `(IN OUT ×4, Old_Key IN OUT VARCHAR2)` | read by the generated table triggers `JOURNAL.<TABLE>_JN_TRG` |
| `SET_OLDKEY` / `CLEAR_OLDKEY` | | old key for the journal row |
| `CREATE_STUFF` | `(schemaName, tableName)` | DBA tool: creates `<TABLE>_JN`, synonym, columns, FKs, indexes and the `_JN_TRG` trigger (dynamic DDL; not used by forms) |

Consequences for this form and its callers:

1. **The date is a DATE.** `:GLOBAL.LETTER_DT` (text) is converted implicitly to DATE in the call. The value that must reach the
   journal is the DATE the Forms item held: year and month as given, the Hijri **day in the minutes** (mask `MI-MM-RRRR`).
   `FORMS_APX.HIJRI_TEXT_TO_DATE` (`TO_DATE(text, HIJRI_DATE_FORMAT)`, default `YYYY-MM-MI`) produces exactly that value, so
   `G_LETTER_DT` holds the `HIJRI_DATE_FORMAT` text and every caller converts it with `FORMS_APX.HIJRI_TEXT_TO_DATE` before
   `JOURNALING_ON`.
2. **All four values are mandatory for the journal.** `_JN_TRG` raises `ORA-20000 Cannot insert null into journal.<T>_JN.<col>`
   when any of them is NULL. AGREE's four required checks protect this; they must stay server-side validations.
3. **Sizes:** `PORT_CD` must fit `NUMBER(3)`, `SUPP_TITLE_CD` `NUMBER(2)`, `LETTER_NBR` `VARCHAR2(50)` (= the Forms item length).
4. **Package state in a pooled session.** Journaling stays on in the DB session until `JOURNALING_OFF`. In Forms that session
   belonged to one user; in APEX the DB session is pooled, so a request that fails between `JOURNALING_ON` (PRE-UPDATE /
   PRE-INSERT) and `JOURNALING_OFF` (POST-UPDATE) leaves journaling on for the next request of another user (§14 R10).
5. **Grants:** the callers' packages in `LIB_APX_USR` need `GRANT EXECUTE ON JOURNAL.DB_JOURNAL TO LIB_APX_USR` (the source grants
   only CUSTOMS, PP_CUSTOMS, QA_CUSTOMS, UAT_CUSTOMS). Not needed by the `SUPPORT_ENTRY` package itself.

Found in IMPR1110 (already converted, package 012), for the IMPR1110 session – **not changed here** (one form per session):
`IMPORTERS_PRE_UPDATE` (`plsql/IMPR1110/impr1110_body.sql` line 2160) passes `FORMS_APX.GET_GLOBAL('LETTER_DT')` as text, i.e.
an implicit `TO_DATE` with the session `NLS_DATE_FORMAT`; it must be `FORMS_APX.HIJRI_TEXT_TO_DATE(FORMS_APX.GET_GLOBAL('LETTER_DT'))`.
Codes are passed as text too (implicit TO_NUMBER, acceptable). IMPR1130 (not converted) has `JOURNALING_ON` in PRE-INSERT; check
there for a matching `JOURNALING_OFF` when that form is converted.

Already built in APEX on the IMPR1110 side (handoff §2, export `apex/IMPR1110/f345_impr1110.sql`): application items `G_LETTER_DT`,
`G_LETTER_NBR`, `G_PORT_CD`, `G_SUPP_TITLE_CD` (set / read with `FORMS_APX.SET_GLOBAL` / `GET_GLOBAL`), DA
`SUPPORT_ENTRY DIALOG CLOSED`, hidden item `P1110_SUPPORT_URL` (TODO). `G_PORT_NAME` / `G_SUPP_TITLE_NAME` do not exist.

### 10.5 Object library

No subclassed objects in this form (no `ParentModule` attribute). Visual attributes referenced by name only: `CG$BUTTON_ICONIC`,
`CG$PROMPT`, `CG$ITEM`, `CG$PROMPT_MD`, `DEFAULT` (replaced by the f345 theme).

## 11. Alerts

| Alert | Style | Title | Message | Buttons | Where used |
|---|---|---|---|---|---|
| CG$ASK_COMMIT | Caution | – | Do you wish to commit the changes you have made? | Yes / No / Cancel | not used |
| CFG_ASK_COMMIT | Caution | – | هل تريد حفظ التغييرات ؟ | نعم / لا / إلغاء | not used |
| CFG_SYSTEM_ERROR | Stop | رسالة خطــأ بالنظام | (runtime) | موافق | not used |
| CFG_ERROR | Stop | رسالة خطأ | (runtime) | موافق | not used |
| CFG_INFORMATION | Note | رسالة إرشاديه | (runtime) | موافق | not used |
| CFG_WARNING_A | Caution | رسالة تحذيريه | (runtime) | موافق | not used |
| USR_WARNING_B | Caution | رسالة تحذيرية | (runtime) | موافق / إلغاء | not used |
| USR_WARNING_C | Caution (red) | رسالة تحذيرية | (runtime) | موافق / إلغاء (default 2) | not used |
| USR_CONFIRM | Caution | تأكـــــــيد | (runtime) | نعم / لا | not used |
| USR_CONFIRM_B | Caution | تأكـــــــيد | (runtime) | نعم / لا (default 2) | not used |

No Text Messages are needed for alerts.

## 12. Parameters & Globals

### 12.1 Module parameters

| Parameter | Data type | Default | Where used | APEX |
|---|---|---|---|---|
| P_MODE | Number | **1** | WNFI (mode, labels, load), AGREE (close in mode 0), CANCEL (clear in mode 0) | page item `P<page>_P_MODE`, set in the URL by the caller |
| P_CURR_PORT_CD | Number | – | WNFI mode 0: default of `P_PORT_CD` | page item `P<page>_P_CURR_PORT_CD`, set in the URL |
| WINDOW_X_POS | Number | 0 | PRE-FORM | dropped (dialog position) |
| WINDOW_Y_POS | Number | 0 | PRE-FORM | dropped |

Note: the parameter default is 1, so a caller that passes no `P_MODE` gets **edit mode** (this is what IMPR1130's OPEN_FORM relies on).
APEX (decision D1): the caller passes `P_MODE` explicitly in the URL – `0` for a new letter, `1` to open the same dialog on demand
for editing the letter already in the `G_` items; the page default stays 1 as in Forms.

### 12.2 Globals

| Global | Written | Read | Existing APEX item |
|---|---|---|---|
| PORT_CD | WNFI (NULL, mode 0), AGREE, CANCEL (NULL, mode 0) | WNFI (edit) | `G_PORT_CD` |
| PORT_NAME | WNFI, AGREE, CANCEL | – (not read by the callers either) | – |
| SUPP_TITLE_CD | WNFI, AGREE, CANCEL | WNFI (edit) | `G_SUPP_TITLE_CD` |
| SUPP_TITLE_NAME | WNFI, AGREE, CANCEL | – (not read by the callers either) | – |
| LETTER_NBR | WNFI, AGREE, CANCEL | WNFI (edit) | `G_LETTER_NBR` |
| LETTER_DT | WNFI, AGREE, CANCEL | WNFI (edit) | `G_LETTER_DT` – text in `FORMS_APX.HIJRI_DATE_FORMAT`; callers convert with `FORMS_APX.HIJRI_TEXT_TO_DATE` for `DB_JOURNAL` (§10.6) |

`:SYSTEM.*` variables: none in this form (callers' toolbar uses `:SYSTEM.FORM_STATUS`).

## 13. Menu & Security

No menu module, no role checks, no `SET_MENU_ITEM_PROPERTY`. Access to the page follows the caller's privileges (no Authorization
Scheme, CLAUDE.md §8). The page is opened from other pages only (no navigation-menu entry).

## 14. Risk Assessment

| # | Risk item | Location | Level | Reason | Proposed APEX approach |
|---|---|---|---|---|---|
| R1 | Edit mode as a **modeless companion window** | IMPR1130 WNFI `OPEN_FORM` (P_MODE default 1); CIC_OLB toolbar CLOSE_FORM | Medium | APEX has no second modeless window beside a page; the edit mode also stays open after "تعديل" | **Decided (D1):** the same modal dialog page, opened by the caller on demand with `P_MODE = 1`; AGREE "تعديل" updates the `G_` items, CANCEL "إغلاق" keeps them. The "stays open after تعديل" and the toolbar CLOSE_FORM are not needed (step 03 decides whether "تعديل" also closes the dialog). IMPR1110 only uses mode 0 |
| R2 | Hijri date stored as DATE with the **day in the minutes** (`MI-MM-RRRR`), passed as **text** through `:GLOBAL.LETTER_DT`, received by `DB_JOURNAL.JOURNALING_ON` as **DATE** | LETTER_DT, AGREE, WNFI, callers' `JOURNALING_ON` | Medium | an implicit TO_DATE with the session format gives a wrong date or ORA-01861 | `G_LETTER_DT` holds `FORMS_APX.HIJRI_DATE_FORMAT` text (f345 Hijri picker), validated with `FORMS_APX.HIJRI_DATE_ERROR`; callers pass `FORMS_APX.HIJRI_TEXT_TO_DATE(G_LETTER_DT)` (§10.6). IMPR1110 line 2160 needs that fix |
| R3 | Contract with the callers through globals | AGREE / CANCEL / WNFI | Medium | Shared page for several callers; the caller must see NULL `G_LETTER_NBR` after cancel or the X close | Before Header process clears the `G_` items in mode 0 (as WNFI), AGREE sets them, then Close Dialog; X close leaves them NULL as in Forms |
| R4 | Required checks without a message | AGREE WBP | Low | APEX cannot "just move the cursor"; a silent failure looks broken | Validations `<ITEM> REQUIRED` with `FORMS_APX.REQUIRED_VALIDATION` (standard text). `-- SUGGESTION:` flagged, not a rule change |
| R5 | Lookup WVIs fail silently; NULL code keeps the old name; inactive title accepted by typing | P_PORT_CD / SUPP_TITLE_CD WVI | Low | behaviour to preserve vs. improve | `<ITEM> VALIDATION` returns an error text for an unknown code; name refreshed by DA `<ITEM> WHEN-VALIDATE-ITEM`; keep the missing `TITLE_STATUS` check (flag as `-- SUGGESTION:`) |
| R6 | `SUPP_TITLE_NM` item is 30 long, record-group column 40 | SUPP_TITLE_CD WVI | Low | a name longer than 30 would fail in Forms | APEX display item without the limit; note only |
| R7 | LOV name clash | `LOV_SD_PORTS` | Low | APEX `LOV_SD_PORTS` (IMPR1110) has another query | **Decided (D2):** new shared LOV `LOV_SD_PORTS_TYPES` with the SUPPORT_ENTRY record-group query; IMPR1110's `LOV_SD_PORTS` stays unchanged |
| R8 | Labels change by mode | WNFI `SET_ITEM_PROPERTY(LABEL)` | Low | | two buttons per action with server-side conditions on `P_MODE`, or label from a page item; decide in step 03 |
| R9 | Window position / non-modal dialog properties | PRE-FORM, RP_WINDOW | Low | | dropped: modal dialog page, size from the f345 child-page standard |
| R10 | `DB_JOURNAL` keeps journaling **on in package state** until `JOURNALING_OFF` | callers: IMPR1110 PRE-UPDATE / POST-UPDATE, IMPR1130 PRE-INSERT | Medium | APEX pools DB sessions: a failed request between ON and OFF leaves the next user's DML journaled with this letter (in Forms the session was the user's own) | caller-side, not in this form: switch off in an exception path too (e.g. `JOURNALING_OFF` before re-raising, or at the start of every DML request). Noted for IMPR1110 / IMPR1130 |

**High risks: 0.** (R10 is Medium because it only shows on an error path and belongs to the callers.)

## 15. Open Questions / Missing Sources

| # | Question / missing source | Needed for | Proposal |
|---|---|---|---|
| Q4 | **Page number** of SUPPORT_ENTRY in `MIG_FORM_REGISTRY` (SC subsystem, own number – not a `1110xx` child) | step 03, IMPR1110 TODOs (`P1110_SUPPORT_URL`, registry row, spec §12) | user to assign the number |
| Q5 | Keep `G_PORT_NAME` / `G_SUPP_TITLE_NAME`? Written by Forms, read by no caller | step 03 | keep them out (no reader); add only if a later caller reads them |
| Q6 | Table DDL of `SD_PORTS`, `SUPP_TITLES`, `CG_REF_CODES` – **MISSING SOURCE** | step 02 parameter types | assume NUMBER codes / VARCHAR2 names from the record groups; confirm in the DB |
| – | Library `OFGTEL` – **MISSING SOURCE** | – | not called; no action |

### 15.1 Decisions (user, 2026-11-24)

| # | Was | Decision |
|---|---|---|
| D1 | Q1 edit mode | the **same dialog page**, opened on demand with `P_MODE = 1` |
| D2 | Q3 port LOV | **new** shared LOV `LOV_SD_PORTS_TYPES` (SUPPORT_ENTRY record-group query: `SD_PORTS` + `CG_REF_CODES` `PORT_TYPE_CD`, columns port code, port type meaning, port name); IMPR1110's `LOV_SD_PORTS` unchanged |
| D3 | Q2 `DB_JOURNAL` source | found in `plsql/Shared/DB_JOURNAL.*`: the date parameter is a **DATE** → `G_LETTER_DT` = `HIJRI_DATE_FORMAT` text, callers convert with `FORMS_APX.HIJRI_TEXT_TO_DATE` (§10.6) |
| D4 | Q4 page number | **9001** (shared dialogs in a 9xxx range) |
