# -*- coding: utf-8 -*-
"""
build_spec.py - renders analysis/IMPR1150/IMPR1150_apex_page_spec.md from the design data of scripts/gen_apex_impr1150.py
(ITEMS, HIDDEN, LOVS, VALIDATIONS, PROCESSES, COMPUTATIONS, DAS) and work/IMPR1150/step03/trace.md.
Usage (from forms_to_apex_toolkit): python3 -I work/IMPR1150/step03/build_spec.py
"""
import os, sys, importlib.util
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
spec = importlib.util.spec_from_file_location('g', os.path.join(ROOT, 'scripts', 'gen_apex_impr1150.py'))
g = importlib.util.module_from_spec(spec)
sys.path.insert(0, os.path.join(ROOT, 'scripts'))
spec.loader.exec_module(g)

def c(v):
    return '-' if v in (None, '', False) else str(v).replace('|', '\\|').replace('\n', ' ')
def code(v):
    return '-' if not v else '`%s`' % str(v).replace('|', '\\|')

TYPES = {'NATIVE_SELECT_LIST': 'Select List', 'NATIVE_TEXT_FIELD': 'Text Field', 'NATIVE_NUMBER_FIELD': 'Number Field (number_only)',
         'NATIVE_DISPLAY_ONLY': 'Display Only (Send On Page Submit = No)', 'NATIVE_HIDDEN': 'Hidden'}
L = []
W = L.append
W('''# IMPR1150 – APEX 21.2 Page Specification (step 03, revision 1)

- **Form:** IMPR1150 (XML module `IMPR1150_PROD_CENTRL`) – تفعيل المستوردين من منصة فسح
- **Package:** `IMPR1150` version 001 (`plsql/IMPR1150/`), logic report `analysis/IMPR1150/IMPR1150_logic_extraction.md`
- **Standard:** f345 (`apex/Reference/f345.sql`), CLAUDE.md §4a–§4d, `docs/f345_reference_standard.md`
- **Design data:** `scripts/gen_apex_impr1150.py` (ITEMS, PROCESSES, DAS …); this file is rendered from it by
  `work/IMPR1150/step03/build_spec.py`, the traceability (§14) and `registry/IMPR1150_registry.sql` by `build_trace.py`.
- **Produced:** 2026-11-25 by Claude Code.

## 0. Decisions that shape the page

| # | Decision | Reason / source |
|---|---|---|
| 1 | Main page **1150** `IMPR1150`, search page **115001** `IMPR1150_SEARCH` (modal 1800×800), page group `IMPR` (IMPR1110 export) | f345 standard §3 |
| 2 | Block IMPORTERS_CENTRAL = native **Form** region, **read-only** (Editable = No), SQL source on `%s`, scope `PORT_CD = 99 AND PORT_CD = :P_CURR_PORT_CD`, key **IMPR_NBR** (= `P0_PAGE_PK`) | user decision 2026-11-25 (keep the database link); block Update / Delete Allowed = false; a remote ROWID is not used |
| 3 | A new page is the Forms "new record": only `IMPR_NBR` and `BUS_ID` are enterable (read-only once a record is shown). Their change runs the check (message 9-150) and submits `EXECUTE_QUERY`; process EXECUTE-QUERY sets `P0_PAGE_PK` | WHEN-VALIDATE-ITEM + :GLOBAL.EXEC_QUERY_NOW + WHEN-NEW-ITEM-INSTANCE EXECUTE_QUERY |
| 4 | Query by BUS_ID: one record per page, the pending one of that BUS_ID (else the first by IMPR_NBR); others through the search page | Forms scrolls several records (KEY-DOWN / UP) |
| 5 | Functions `IMPR1150_ACTIVATE` / `IMPR1150_REJECT` come from the f345 Page Functions list (page 0 FUNCS drawer), filtered by `P1150_ADJ_FUNS`; each raises its custom event; the DA submits the request of the same name; an After Submit process calls `EXEC_FUNS` and shows the Forms message as success message | PU EXECUTE_FUNCTION / EXEC_FUNS / ADJ_FUNS |
| 6 | REJECT without a reason (first press in Forms): client-side condition of the DA: REJCT_RESON shown, IMPR_REJCT_RESON hidden, alert "%s", focus. With a reason: request IMPR1150_REJECT | EXEC_FUNS CR-7234 (no server round trip needed; the server refuses an empty reason again) |
| 7 | CREATE / DELETE of page 0 are refused with a message (`PRE_INSERT` / `PRE_DELETE`); SAVE only gives PRE-UPDATE's message | as IMPR1116; no DML on this block |
| 8 | Documents: read-only IG `IMPORTER_DOCS` (local `IMPORTERS_DOCS`); the button OPEN_DEC (HOST START on the client PC) becomes the column `DOC_FULL_NAME`: **TODO** how to open the file | inventory §15 #1 |
| 9 | No JavaScript action at all (Hide / Show / Alert / Set Focus / Submit Page are native) | CLAUDE.md §4c |

## 1. Page type decision per block

| Block | Forms | APEX |
|---|---|---|
| IMPORTERS_CENTRAL | base table (query source = HQ table over the link), one record shown, query only | Form region (read-only) on page 1150 + search IG on page 115001 |
| IMPORTER_DOCS | base table, 6 records, query only, WHERE IMPR_NBR = master | read-only IG on page 1150 |
| TITLE, EDI_MSG, LSIDE, TOOLBAR | OLB frame | f345 page template, hero region, page 0 toolbar, FUNCS drawer |

## 2. Pages

| Page | Name / alias | Mode | Template / class | Source |
|---|---|---|---|---|
| 1150 | IMPR1150 / IMPR1150 | Normal, protection C, Warn on Unsaved Changes = No (nothing to save) | Zatca-Minimal_No_Navigation, `zf` | window CGSO$WINDOW_1, canvas CG$PAGE_1 |
| 115001 | IMPR1150_SEARCH / IMPR1150-SEARCH | Modal 1800×800, protection C | theme dialog, `zf` | Enter-Query / Execute-Query (page 0 SEARCH) |

## 3. Regions

| Page | Region (Static ID) | Type | Template / classes | Source |
|---|---|---|---|---|
| 1150 | `IMPORTERS_CENTRAL_HERO` "الهيدر" | Static HTML, `&P1150_HERO_TITLE.` | f345 hero, `cg-hero` | TITLE (OLB) |
| 1150 | `IMPORTERS_CENTRAL` "المستوردين من منصة فسح" | Form, SQL on the HQ table, read-only, key IMPR_NBR | Interactive Report, `zatca-forms cg-form cg-card` | block IMPORTERS_CENTRAL |
| 1150 | `IMPORTER_DOCS` "وثائق المستورد" | IG read-only, `WHERE impr_nbr = :P1150_IMPR_NBR` (Page Items to Submit P1150_IMPR_NBR) | Standard, `t-Region--noPadding`, `cg-card cg-grid` | block IMPORTER_DOCS + DETIL_DATA |
| 115001 | `IMPORTERS_CENTRAL_SEARCH_CRITERIA` "بحث" | Static, item `P115001_SEARCH`, buttons SEARCH / CLEAR | f345 hero | query criteria |
| 115001 | `IMPORTERS_CENTRAL_SEARCH` "المستوردون" | IG read-only, one search text over all columns, no rows before a search, all statuses, link IMPR_NBR → page 1150 (`P0_PAGE_PK`) | Standard | block query (HQ table) |

## 4. Items (page 1150)

Layout from canvas CG$PAGE_1 (rows by Y, right to left by X, 12 columns).

| Item | Column | Type | Label | LOV | New row / span | Read only | Source |
|---|---|---|---|---|---|---|---|''' % (g.HQ_TABLE, g.MSG_REASON))
for name, col, kind, label, dt, newline, span, x in g.ITEMS:
    ro = x.get('read_only')
    W('| P1150_%s | %s | %s | %s | %s | %s / %s | %s | %s |' % (
        name, c(col), TYPES[kind] + (' (PK)' if x.get('pk') else ''), c(label), c(x.get('lov')), 'Yes' if newline else 'No', span,
        'Always' if ro == 'ALWAYS' else code(ro) if ro else '-', c(x['src'])))
for name, col, dt, vp, s in g.HIDDEN:
    W('| P1150_%s | %s | Hidden (Value Protected = %s) | - | - | hidden | - | %s |' % (name, c(col), 'Yes' if vp == 'Y' else 'No', c(s)))
W('''
Every Text / Number Field has its `cg-ic` icon (`scripts/item_icons.py`). `REJCT_RESON` is not *Value Required* (it would block
every other submit); `EXEC_FUNS` refuses an empty reason. Its maximum length is not in the XML (TODO with inventory §15 #2).

## 5. Buttons

| Page | Button | Action | Source |
|---|---|---|---|
| 0 | CREATE / SAVE / DELETE / SEARCH / CLEAR / FUNCS / BACK | f345 page 0 toolbar: CREATE, SAVE, DELETE handled by processes §8; SEARCH opens 115001 | TOOLBAR (OLB), KEY-* |
| 115001 | `SEARCH`, `CLEAR` | refresh the grid / clear the text | EXECUTE_QUERY, CLEAR |

## 6. LOVs (new, *PL/SQL Function Body returning SQL Query*, R / D)

| LOV | Body | Source |
|---|---|---|''')
for name, sql, s in g.LOVS:
    W('| %s | `return %s;` | %s |' % (name, sql, c(s)))
W('''
## 7. Validations (page 1150, request EXECUTE_QUERY)

| Name | Item | PL/SQL Function Body returning Error Text | Source |
|---|---|---|---|''')
for name, item, cd, s in g.VALIDATIONS:
    W('| %s | P1150_%s | %s | %s |' % (name, item, code(cd), s))
W('''
## 8. Processes

| Point | Seq | Name | Code | Condition | Success message | Source |
|---|---|---|---|---|---|---|''')
for point, seq, name, cd, cond, s, msg in g.PROCESSES:
    if name == 'New':
        cd, cond = 'f345 session setup (AGR1100)', 'Never'
    if name.startswith('Initialize'):
        cd = 'NATIVE_FORM_INIT, region IMPORTERS_CENTRAL'
    W('| %s | %d | %s | %s | %s | %s | %s |' % (point.replace('_', ' ').title(), seq, name, code(cd) if not cd.startswith(('f345', 'NATIVE')) else cd,
                                              code(cond), c(msg), c(s)))
W('''
## 9. Computations

| Item | Point | Expression | Source |
|---|---|---|---|''')
for item, point, expr, s in g.COMPUTATIONS:
    W('| P1150_%s | %s | %s | %s |' % (item, point.replace('_', ' ').title(), code(expr), s))
W('''
## 10. Dynamic Actions (page 1150)

| DA | Event | Selection | Client condition | Fire on init | Actions (True / False) | Source |
|---|---|---|---|---|---|---|''')
for name, ev, sel, cond, init, acts, s in g.DAS:
    a = []
    for x in acts:
        t = x.get('result', 'TRUE')[0]
        if x['action'] == 'FOS':
            a.append('%s: FOS %s (submit %s)' % (t, code(x['code']), ', '.join(x['submit'])))
        elif x['action'] == 'SUBMIT':
            a.append('%s: Submit Page request %s' % (t, x['request']))
        elif x['action'] == 'NATIVE_ALERT':
            a.append('%s: Alert "%s"' % (t, x['text']))
        else:
            a.append('%s: %s %s' % (t, x['action'].replace('NATIVE_', '').replace('_', ' ').title(), x['items']))
    W('| %s | %s | %s | %s | %s | %s | %s |' % (name, ev.replace('custom:', 'Custom: ').replace('ready', 'Page Load').replace('change', 'Change'),
                                              '-' if not sel else 'document' if sel[0] == 'DOCUMENT' else 'Item ' + sel[1],
                                              '-' if not cond else 'not null' if cond[0] == 'NOT_NULL' else code(cond[1]),
                                              'Yes' if init else 'No', '<br>'.join(a), c(s)))
W('''
Page 115001: DAs `SEARCH` (click → Refresh), `SEARCH KEY-ENTER` (keyup Enter → Refresh), `CLEAR WHEN-BUTTON-PRESSED`
(Clear + Refresh) and `Hide` (page 0 toolbar hidden in the dialog), as the other search pages. JavaScript actions: **0**.

## 11. Alerts and messages

| Forms | APEX |
|---|---|
| `STR.DispArbMsg(9, 150)` + RAISE (IMPR_NBR / BUS_ID) | error text of the validation / FOS (`FORMS_APX.ARABIC_MESSAGE(9, 150)`) |
| 'هذا السجل مدخل سابقاً - أعد ادخال البيانات' (CGUV$CHK_IMP_CNTRL_PK) | `IMPR_NBR_VALIDATION` |
| 'تم تفعيل المستورد' / 'تم إيقاف تفعيل المستورد' (DISPALERT ERROR, no raise) | success message of the function processes |
| 'برجاء إدخال سبب الرفض' (DISPALERT INFORMATION) | native Alert of the REJECT DA; error of `EXEC_FUNS` when sent without reason |
| 'برجاء استخدام وظيفة رفض تفعيل المستورد' (PRE-UPDATE) | `FORMS_APX.MESSAGE` in process PRE-UPDATE |
| refused CREATE / DELETE, disabled function | `PRE_INSERT` / `PRE_DELETE` / `EXEC_FUNS` (texts to agree) |

## 12. Branches and navigation

| Branch | Condition | Target |
|---|---|---|
| `EXECUTE-QUERY` (seq 10) | request EXECUTE_QUERY | page 1150, clear cache 1150, `P0_PAGE_PK` kept (set by process EXECUTE-QUERY) |
| `IMPR1150 - stay in the form` (seq 20) | – | page 1150, clear cache 1150 (REJCT_RESON reset), success message; Forms re-queries the record after REJECT |
| search grid link | – | page 1150, `P0_PAGE_PK` = IMPR_NBR (`P0_PAGE_PK_CHECK` checks it) |

## 13. Shared components

Reused: f345 theme, templates, page 0 (toolbar, FUNCS, NUMBER ONLY), application items `SSO_APP_USER`, `P_CURR_PORT_CD`,
`P_GLOBAL_V_WS_ID`; IMPR1110 export: page group `IMPR`, Application Setting `HIJRI_DATE_FORMAT`. New: LOVs
`LOV_PENDING_ACTIVE`, `LOV_IMPR_REJCT_RESON` (`LOV_APX.REFERENCE_CODES`, no LOV_APX change). The functions
`IMPR1150_ACTIVATE` / `IMPR1150_REJECT` must exist in `SC_SYSTEM_OBJECTS` under the screen IMPR1150 with
`SYS_OS_FILE_NAME` = the event name (f345 Page Functions list).

## 14. Traceability (every Forms object)

''')
L.append(open(os.path.join(ROOT, 'work', 'IMPR1150', 'step03', 'trace.md'), encoding='utf-8').read())
open(os.path.join(ROOT, 'analysis', 'IMPR1150', 'IMPR1150_apex_page_spec.md'), 'w', encoding='utf-8', newline='\n').write('\n'.join(L))
print('written analysis/IMPR1150/IMPR1150_apex_page_spec.md')
