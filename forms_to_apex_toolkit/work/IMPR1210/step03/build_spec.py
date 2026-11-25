# -*- coding: utf-8 -*-
"""
build_spec.py - renders analysis/IMPR1210/IMPR1210_apex_page_spec.md from the design data of
scripts/gen_apex_impr1210.py (ITEMS, HIDDEN, MESSAGES, VALIDATIONS, PROCESSES, COMPUTATIONS, DAS, AUTH_SQL) and the
traceability of work/IMPR1210/step03/trace.md (run build_trace.py first).
Usage (from forms_to_apex_toolkit): python3 -I work/IMPR1210/step03/build_spec.py
"""
import os, sys, importlib.util

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
spec = importlib.util.spec_from_file_location('g', os.path.join(ROOT, 'scripts', 'gen_apex_impr1210.py'))
g = importlib.util.module_from_spec(spec)
sys.path.insert(0, os.path.join(ROOT, 'scripts'))
spec.loader.exec_module(g)

def c(v):
    return '–' if v in (None, '') else str(v).replace('|', '\\|').replace('\n', ' ')

def read_only(kind, x):
    if kind == 'NATIVE_DISPLAY_ONLY':
        return 'always'
    ro = x.get('read_only')
    return 'record' if ro == g.RECORD else ('locked' if ro == g.LOCKED else 'no')

L = []
w = L.append
w('''# IMPR1210 – APEX 21.2 Page Specification (step 03)

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
| 121001 | تفاويض الشركات الوسيطة (`AGNTS_SEARCH`) | read-only IG, lazy loading, no rows until a search; link `ATHRZTN_SEQ_NBR` → page 1210 | block query (WHERE PORT_CD = P_CURR_PORT_CD) + POST-QUERY names |

Grid query of `LOV_AGNT_ATHR_IMPR`:

```sql''')
w(g.AUTH_SQL)
w('''```

## 4. Items (page 1210)

Canvas order (rows by Y, then X). Read only: `always` (display), `record` = `:P0_PAGE_PK IS NOT NULL`,
`locked` = `IMPR1210.AGNTS_IS_READ_ONLY(P_PORT_CD => :P1210_PORT_CD, P_ATHRZTN_SEQ_NBR => :P1210_ATHRZTN_SEQ_NBR)`.

| Item | Type | Label | Column | Required | LOV / mask / default | Read only | Source |
|---|---|---|---|---|---|---|---|''')
for name, col, kind, label, dt, newline, span, x in g.ITEMS:
    lov = x.get('lov') or x.get('static') or x.get('mask')
    if x.get('default'):
        lov = '%s, default %s' % (lov, x['default'])
    w('| `P1210_%s` | %s | %s | %s | %s | %s | %s | %s |' % (
        name, kind.replace('NATIVE_', ''), c(label), c(col), 'Yes' if x.get('req') else '–', c(lov), read_only(kind, x), c(x['src'])))
w('''
Not displayed:

| Item | Type | Column | Source |
|---|---|---|---|''')
for name, col, dt, kind, mask, vp, s in g.HIDDEN:
    w('| `P1210_%s` | %s | %s | %s |' % (name, kind.replace('NATIVE_', ''), c(col), c(s)))
w('''
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
|---|---|---|---|---|''')
for name, item, code, cond, s in g.VALIDATIONS:
    w('| %s | `P1210_%s` | `%s` | `%s` | %s |' % (name, item, code, cond, c(s)))
w('| (native) Value Required | `P1210_ALLOW_EXPORT`, `P1210_IMPR_NBR`, `P1210_IMPR_NBR_AG`, `P1210_ATHRZTN_STA_CD` | – | – | Required = true |')
w('''
## 8. Processes (page 1210, f345 standard §6)

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
    w('| `P1210_%s` | %s | `%s` | %s |' % (item, point, expr, c(s)))
w('''
## 10. Dynamic Actions (page 1210)

| DA | Event | Element | Condition | Actions | Source |
|---|---|---|---|---|---|''')
def act(x):
    if x['action'] == 'FOS':
        return 'FOS `%s` (submit %s, return %s)' % (x['code'], ', '.join(x['submit']), ', '.join(x['ret']) or '–')
    if x['action'] == 'SUBMIT':
        return 'Submit Page `%s`' % x['request']
    if x['action'] == 'NATIVE_CONFIRM':
        return 'Confirm "%s"' % x['text']
    if x['action'] == 'NATIVE_REFRESH':
        return 'Refresh region LOV_AGNT_ATHR_IMPR'
    return '%s %s' % (x['action'], x.get('items', ''))
for name, event, sel, cond, init, acts, s in g.DAS:
    cnd = cond and (cond[0] + ((' `%s`' % cond[1]) if cond[1] else ''))
    w('| %s | %s | %s | %s | %s | %s |' % (name, event, sel[1] or 'document', c(cnd), c('; '.join(act(x) for x in acts)), c(s)))
w('''
JavaScript actions: **none**. Client-side conditions in JavaScript: the two function DAs (one expression each, the Forms
`IF :ATHRZTN_SEQ_NBR IS NOT NULL AND :ATHRZTN_STA_CD = 1 / 2` before the confirmation; `EXEC_FUNS` checks the stored status
again) and the f345 `this.browserEvent.which === 13` condition of SEARCH KEY-ENTER on page 121001.

## 11. Alerts and messages

| Text Message / text | Where | Source |
|---|---|---|''')
for name, text, s in g.MESSAGES:
    w('| `%s` = "%s" | APEX error handler (constraint) | %s |' % (name, text, s))
w('''| 9-10, 9-20, 9-70 (`FORMS_APX.ARABIC_MESSAGE`) | `IMPR_NBR_VALIDATION`, `IMPR_NBR_AG_VALIDATION` | IMPR_NBR / IMPR_NBR_AG WHEN-VALIDATE-ITEM, CHECK_SUSPENSION |
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
''')
L.append(open(os.path.join(ROOT, 'work', 'IMPR1210', 'step03', 'trace.md'), encoding='utf-8').read())
os.makedirs(os.path.join(ROOT, 'analysis', 'IMPR1210'), exist_ok=True)
open(os.path.join(ROOT, 'analysis', 'IMPR1210', 'IMPR1210_apex_page_spec.md'), 'w', encoding='utf-8', newline='\n').write('\n'.join(L))
print('written analysis/IMPR1210/IMPR1210_apex_page_spec.md', sum(x.count('\n') + 1 for x in L), 'lines')
