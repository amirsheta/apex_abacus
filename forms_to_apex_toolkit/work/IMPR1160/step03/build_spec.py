# -*- coding: utf-8 -*-
"""
build_spec.py - renders analysis/IMPR1160/IMPR1160_apex_page_spec.md from the design data of
scripts/gen_apex_impr1160.py (ITEMS, HIDDEN, LOVS, MESSAGES, VALIDATIONS, PROCESSES, COMPUTATIONS, DAS) and the
traceability of work/IMPR1160/step03/trace.md (run build_trace.py first).
Usage (from forms_to_apex_toolkit): python3 -I work/IMPR1160/step03/build_spec.py
"""
import os, sys, importlib.util

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
spec = importlib.util.spec_from_file_location('g', os.path.join(ROOT, 'scripts', 'gen_apex_impr1160.py'))
g = importlib.util.module_from_spec(spec)
sys.path.insert(0, os.path.join(ROOT, 'scripts'))
spec.loader.exec_module(g)

def c(v):
    return '–' if v in (None, '') else str(v).replace('|', '\\|').replace('\n', ' ')

L = []
w = L.append
w('''# IMPR1160 – APEX 21.2 Page Specification (step 03)

- **Form:** IMPR1160 (title `IMPR1160_ND_CNTRL`) – استثناء المستوردين الافراد للسيارات
- **Package:** `IMPR1160` version 001 (`plsql/IMPR1160/`), logic report `analysis/IMPR1160/IMPR1160_logic_extraction.md`;
  shared `LOV_APX` 004 (`plsql_templates/lov_apx.sql`)
- **Standard:** f345 (`apex/Reference/f345.sql`), CLAUDE.md §4a–§4d, `docs/f345_reference_standard.md`
- **Design data:** `scripts/gen_apex_impr1160.py` (ITEMS, PROCESSES, DAS …); this file is rendered from it by
  `work/IMPR1160/step03/build_spec.py`, the traceability (§14) and `registry/IMPR1160_registry.sql` by `build_trace.py`.
- **Produced:** 2026-11-25 by Claude Code.

## 0. Decisions that shape the page

| # | Decision | Reason / source |
|---|---|---|
| 1 | Main page **1160** `IMPR1160`, search page **116001** `IMPR1160_SEARCH` (modal 1800×800), page group `IMPR` (IMPR1110 export) | f345 standard §3 |
| 2 | Block IMPR_CAR_EXCEPTION = native **Form** region on the table, key **ROWID** (= `P0_PAGE_PK`, URL-safe from the search page), operations `i:u:d` | PRE-QUERY `MAKE_BLOCK_FULL_OPERATION(TRUE, TRUE, TRUE)` overrides the Designer Update / Delete = false |
| 3 | New record (`P0_PAGE_PK` null): IMPR_NBR, DCLTN_TYPE, DCLTN_NBR, DCLTN_DT, AWARD_*, NO_OF_CARS, STATUS enterable. Queried record: **only STATUS** (read-only condition `:P0_PAGE_PK IS NOT NULL` on every other item) | Update Allowed = false on every item; PRE-QUERY / POST-QUERY enable STATUS |
| 4 | The suspension check ("هذا المستورد موقوف") runs in the DA `IMPR_NBR KEY-NEXT-ITEM` (on change) **and** the validation `IMPR_NBR VALIDATION` (CREATE) | WHEN-VALIDATE-ITEM never raises; KEY-NEXT-ITEM holds the check (inventory §14 #1, §15 #1 to confirm) |
| 5 | LOV forms → Popup LOVs: `LOV_IMPR_P` (LOV_APX.IMPORTERS, port of the user, type 4, business id type 5) and `LOV_IMPR_DCLTN` (LOV_APX.LOV_IMPR_DCLTN, by DCLTN_TYPE and IMPR_NBR). The DAs on change do what the form did after the LOV (name; declaration date, ISN, cars) | PU CALL_IMPR_LOV / CALL_IMPR_DCLTN_LOV |
| 6 | Hijri dates as text in `FORMS_APX.HIJRI_DATE_FORMAT` (Application Setting, default YYYY-MM-MI), class `hijri-date-default` (f345 Hijri picker) | IMPR1110 / IMPR1120 decision; Forms mask MI-MM-RRRR |
| 7 | Defaults of the new record (PORT_CD / PORT_NAME, EXPTN_START_DT) by process `WHEN-NEW-FORM-INSTANCE` **after** `Initialize form` | WHEN-NEW-FORM-INSTANCE; Initialize form would clear them |
| 8 | Constraint errors → Text Messages named after the constraints (APEX error handler of FORMS_APX) | block ON-ERROR / CGTE$CHECK_CONSTRAINT_VIO |
| 9 | No functions (EXEC_FUNS / ADJ_FUNS are empty); no JavaScript action (Set Focus / Refresh / Clear are native) | CLAUDE.md §4c |

## 1. Page type decision per block

| Block | Forms | APEX |
|---|---|---|
| IMPR_CAR_EXCEPTION | base table, one record shown, insert (+ STATUS update, delete after a query) | Form region on page 1160 + search IG on page 116001 |
| TITLE, EDI_MSG, LSIDE, TOOLBAR | OLB frame | f345 page template, hero region, page 0 toolbar, FUNCS drawer |

## 2. Pages

| Page | Name / alias | Mode | Template / class | Source |
|---|---|---|---|---|
| 1160 | IMPR1160 / IMPR1160 | Normal, protection C, Warn on Unsaved Changes = Yes | Zatca-Minimal_No_Navigation, `zf` | window CGSO$WINDOW_1, canvas CG$PAGE_1 |
| 116001 | IMPR1160_SEARCH / IMPR1160-SEARCH | Modal 1800×800, protection C | theme dialog, `zf` | Enter-Query / Execute-Query (page 0 SEARCH) |

## 3. Regions

| Page | Region (static id) | Type / template | Source |
|---|---|---|---|
| 1160 | الهيدر (`IMPR_CAR_EXCEPTION_HERO`) | Static HTML, Blank with Attributes, `cg-hero`, title `&P1160_HERO_TITLE.` | OLB block TITLE |
| 1160 | استثناء المستوردين الافراد للسيارات (`IMPR_CAR_EXCEPTION`) | Form, table `IMPR_CAR_EXCEPTION`, ROWID, `i:u:d`, Interactive Report template, `zatca-forms cg-form cg-card` | block IMPR_CAR_EXCEPTION |
| 116001 | بحث (`IMPR_CAR_EXCEPTION_SEARCH_CRITERIA`) | Static, text `P116001_SEARCH` + buttons SEARCH / CLEAR | Enter-Query criteria |
| 116001 | استثناءات السيارات (`IMPR_CAR_EXCEPTION_SEARCH`) | read-only IG, lazy loading, no rows until a search; link `EXCPT_ISN` → page 1160 with `P0_PAGE_PK = ROW_ID` | block query (no WHERE clause: all ports) + POST-QUERY names |

## 4. Items (page 1160)

Canvas order (rows by Y, then X). Read only = `:P0_PAGE_PK IS NOT NULL` unless noted.

| Item | Type | Label | Column | Required | LOV / mask | Read only | Source |
|---|---|---|---|---|---|---|---|''')
for name, col, kind, label, dt, newline, span, x in g.ITEMS:
    w('| `P1160_%s` | %s | %s | %s | %s | %s | %s | %s |' % (
        name, kind.replace('NATIVE_', ''), c(label), c(col), 'Yes' if x.get('req') else '–',
        c(x.get('lov') or x.get('mask') or ('Hijri text' if x.get('hijri') else None)),
        'always' if kind == 'NATIVE_DISPLAY_ONLY' else ('record' if x.get('read_only') else 'no'), c(x['src'])))
w('''
Not displayed:

| Item | Type | Column | Mask | Source |
|---|---|---|---|---|''')
for name, col, dt, kind, mask, vp, s in g.HIDDEN:
    w('| `P1160_%s` | %s | %s | %s | %s |' % (name, kind.replace('NATIVE_', ''), c(col), c(mask), c(s)))
w('''
## 5. Buttons

Page 1160 has none: CREATE / SAVE / DELETE / SEARCH / CLEAR / BACK come from the page 0 toolbar (f345). Page 116001:
SEARCH and CLEAR (Text with Icon, `cg-b-search` / `cg-b-clear`, Defined by Dynamic Action).

## 6. LOVs (*PL/SQL Function Body returning SQL Query*, R / D)

| LOV | Function body | Popup columns | Source |
|---|---|---|---|''')
for name, sql, cols, s in g.LOVS:
    w('| `%s` | `return %s;` | %s | %s |' % (name, sql, c(', '.join('%s (%s)' % (a, b) for a, b, _ in cols) if cols else 'Select List'), c(s)))
w('| `LOV_REC_STATUS` | reused (IMPR1140 export) | Select List | STATUS list (CG_REF_CODES REC_STATUS) |')
w('''
## 7. Validations (page 1160)

| Validation | Item | Code | Condition | Source |
|---|---|---|---|---|''')
for name, item, code, cond, s in g.VALIDATIONS:
    w('| %s | `P1160_%s` | `%s` | `%s` | %s |' % (name, item, code, cond, c(s)))
w('| (native) Value Required | `P1160_IMPR_NBR`, `P1160_DCLTN_TYPE` | – | – | Required = true (CGSO$NUMBER_MD / list item) |')
w('''
## 8. Processes (page 1160, f345 standard §6)

| Point | Seq | Name | Code | Condition | Source |
|---|---|---|---|---|---|''')
for point, seq, name, code, cond, s, msg in g.PROCESSES:
    kind = 'NATIVE_FORM_DML' if code == g.FORM_DML else ('NATIVE_FORM_INIT' if name == 'Initialize form' else None)
    w('| %s | %d | %s | %s | %s | %s%s |' % (point, seq, name, kind or ('`%s`' % code if code else '–'), c(cond), c(s),
                                           (' – success "%s"' % msg) if msg else ''))
w('''
## 9. Computations

| Item | Point | Expression | Source |
|---|---|---|---|''')
for item, point, expr, s in g.COMPUTATIONS:
    w('| `P1160_%s` | %s | `%s` | %s |' % (item, point, expr, c(s)))
w('''
## 10. Dynamic Actions (page 1160)

| DA | Event | Element | Condition | Actions | Source |
|---|---|---|---|---|---|''')
for name, event, sel, cond, init, acts, s in g.DAS:
    a = '; '.join(('FOS `%s` (submit %s, return %s)' % (x['code'], ', '.join(x['submit']), ', '.join(x['ret']) or '–'))
                  if x['action'] == 'FOS' else '%s %s' % (x['action'], x.get('items', '')) for x in acts)
    w('| %s | %s | %s | %s | %s | %s |' % (name, event, sel[1], c(cond and cond[0]), c(a), c(s)))
w('''
JavaScript: none on page 1160; page 116001 only the f345 `this.browserEvent.which === 13` condition of SEARCH KEY-ENTER.

## 11. Alerts and messages

| Text Message / text | Where | Source |
|---|---|---|''')
for name, text, s in g.MESSAGES:
    w('| `%s` = "%s" | APEX error handler (constraint) | %s |' % (name, text, s))
w('''| "هذا المستورد موقوف " | `IMPR_NBR_VALIDATION`, `IMPR_NBR_KEY_NEXT_ITEM` | IMPR_NBR KEY-NEXT-ITEM |
| "رقم البيان او  تاريخه الذى تم ادخاله غير معرف فى انظمة البيان " | `DCLTN_NBR_POST_CHANGE`, `PRE_INSERT` | POST-CHANGE / PRE-INSERT |
| "لقد تم استثناء هذا البيان من قبل " | `PRE_INSERT` | PRE-INSERT |
| "لا يمكن ادخال رقم قرار اقل من او يساوي صفر" | `AWARD_NBR_VALIDATION` | AWARD_NBR WHEN-VALIDATE-ITEM |
| "لا يمكن ادخال عدد سيارات اقل من او يساوي صفر" | `NO_OF_CARS_VALIDATION` | NO_OF_CARS WHEN-VALIDATE-ITEM |
| "غير مسموح بتعديل الحالة من غير فعال الى فعال" | `PRE_UPDATE` | PRE-UPDATE |
| NIB.KEY_DELREC "هل أنت متأكد من عملية الحذف" | page 0 DELETE confirmation (f345 `ASK_DLG`) | KEY-DELREC |

## 12. Branches and navigation

| Branch | Point | Target | Source |
|---|---|---|---|
| IMPR1160 - stay in the form | After Processing | page 1160 with the success message (`P0_PAGE_PK` kept; after DELETE it is null = new record) | Forms stays on the record after COMMIT |
| search link | – | `f?p=&APP_ID.:1160:&SESSION.::&DEBUG.:1160:P0_PAGE_PK:&ROW_ID.` (ROW_ID URL-safe) | Execute-Query |

## 13. Shared components

Reused from f345: theme 42 / ZATCA Forms, page 0 (`P0_ACTIONS`, `P0_PAGE_PK`, `P0_SEARCH_URL`, `ASK_DLG`), application items
`P_CURR_PORT_CD`, `SSO_APP_USER`, `SYS_ANAME`, app process `SCREEN ENTRY RESET`, `APP_ERROR_HANDLER`, plug-in
`COM.FOS.EXECUTE_PLSQL_CODE`, the Hijri picker class `hijri-date-default`. From IMPR1110: page group `IMPR`, Application Setting
`HIJRI_DATE_FORMAT`. From IMPR1140: `LOV_REC_STATUS`. New: LOVs `LOV_DCL_STA_FLAG`, `LOV_IMPR_P`, `LOV_IMPR_DCLTN`; Text Messages
`ICE_PK`, `ICE_SD_FK`, `ICE_SDP_FK`, `ICE_IMP_FK`, `ICE_DCLTN_FK`. No application item, authorization scheme or page 0 change.

Security (CLAUDE.md §8): page access by the application's privileges; Forms used the table grants (ORA-01031 messages of ON-ERROR)
and the REMOVE toolbar button (TMPLT) – the privilege administrators decide who may delete.

## 14. Traceability (every Forms object)
''')
L.append(open(os.path.join(ROOT, 'work', 'IMPR1160', 'step03', 'trace.md'), encoding='utf-8').read())
os.makedirs(os.path.join(ROOT, 'analysis', 'IMPR1160'), exist_ok=True)
open(os.path.join(ROOT, 'analysis', 'IMPR1160', 'IMPR1160_apex_page_spec.md'), 'w', encoding='utf-8', newline='\n').write('\n'.join(L))
print('written analysis/IMPR1160/IMPR1160_apex_page_spec.md', sum(x.count('\n') + 1 for x in L), 'lines')
