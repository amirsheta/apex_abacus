# -*- coding: utf-8 -*-
"""
build_spec.py - renders analysis/IMPR1170/IMPR1170_apex_page_spec.md from the design data of
scripts/gen_apex_impr1170.py (ITEMS, HIDDEN, PROCESSES, COMPUTATIONS, DAS, OWNERS_*, SEARCH_*) and the
traceability of work/IMPR1170/step03/trace.md (run build_trace.py first).
Usage (from forms_to_apex_toolkit): python3 -I work/IMPR1170/step03/build_spec.py
"""
import os, sys, importlib.util

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
spec = importlib.util.spec_from_file_location('g', os.path.join(ROOT, 'scripts', 'gen_apex_impr1170.py'))
g = importlib.util.module_from_spec(spec)
sys.path.insert(0, os.path.join(ROOT, 'scripts'))
spec.loader.exec_module(g)

def c(v):
    return '–' if v in (None, '') else str(v).replace('|', '\\|').replace('\n', ' ')

L = []
w = L.append
w('''# IMPR1170 – APEX 21.2 Page Specification (step 03)

- **Form:** IMPR1170 (module `IMPR1170_CNTRL`) – %s (MCI_DATA + owners MCI_OWNERS, refreshed from the MCI web service)
- **Package:** `IMPR1170` version 001 (`plsql/IMPR1170/`), logic report `analysis/IMPR1170/IMPR1170_logic_extraction.md`;
  no change to `LOV_APX` / `FORMS_APX`
- **Standard:** f345 (`apex/Reference/f345.sql`), CLAUDE.md §4a–§4d, `docs/f345_reference_standard.md`
- **Design data:** `scripts/gen_apex_impr1170.py` (ITEMS, PROCESSES, DAS …); this file is rendered from it by
  `work/IMPR1170/step03/build_spec.py`, the traceability (§14) and `registry/IMPR1170_registry.sql` by `build_trace.py`.
- **Produced:** 2026-11-25 by Claude Code.

## 0. Decisions that shape the page

| # | Decision | Reason / source |
|---|---|---|
| 1 | Main page **1170** `IMPR1170`, search page **117001** `IMPR1170_SEARCH` (modal 1800×800), page group `IMPR` (IMPR1110 export) | f345 standard §3 |
| 2 | Block MCI_DATA = native **Form** region on the table, query only, key **CR_NBR** (= `P0_PAGE_PK`); block MCI_OWNERS = read-only **Interactive Grid** below it, `WHERE cr_nbr = :P1170_CR_NBR` | Update / Delete Allowed = false; relation `CGFK$MCI_OWNER_MCI_DATA_FK` |
| 3 | Page 0 **CREATE / SAVE / DELETE are refused** (processes PRE-INSERT / PRE-UPDATE / PRE-DELETE with a message) | Forms lets SAVE insert a bare row (CR_NBR, CR_TYPE 1) without the look-up – not kept (inventory §14 #2, §15 #1, **to confirm**) |
| 4 | `CR_NBR.KEY-NEXT-ITEM` = DA `CR_NBR KEY-NEXT-ITEM` (Change → Submit Page `EXECUTE_QUERY`) + After Submit process `CR_NBR KEY-NEXT-ITEM` → `IMPR1170.CR_NBR_KEY_NEXT_ITEM` (cache of today, else the MCI web service) which sets `P0_PAGE_PK`; branch `EXECUTE-QUERY` reloads the page and *Initialize form* shows the record | IMPR1150 pattern; a change event also fires with the mouse (inventory §14 #1) |
| 5 | A failed service call shows the Forms text as page error ("بيانات السجل التجارى رقم … غير متاحة …"); the typed number stays | STR.DISPALERT 'ERROR' |
| 6 | CR_NBR enterable only while no record is shown (`:P0_PAGE_PK IS NOT NULL` → read only); every other item is Display Only | Update Allowed = false on every item; Insert Allowed = false except CR_NBR |
| 7 | Hijri CR_ISSUE_DATE / CR_EXPIRY_DATE: Display Only with the mask `&P1170_HIJRI_DATE_FORMAT.` (Application Setting) | IMPR1150 decision; Forms mask MI-MM-YYYY |
| 8 | CR_TYPE: always read-only Select List on the reused LOV `LOV_COMM_RGSTRTN_TYPE` (IMPR1130) | CGSO$COMBO_DO, CGDV$POPULATE_DYNAMIC_LISTS |
| 9 | No functions (EXEC_FUNS / ADJ_FUNS are empty), no FOS, no JavaScript action, no shared component created | CLAUDE.md §4c |

## 1. Page type decision per block

| Block | Forms | APEX |
|---|---|---|
| MCI_DATA | base table, one record shown, query only (+ insert by default, not kept) | Form region on page 1170 + search IG on page 117001 |
| MCI_OWNERS | base table, 4 records shown, query only, detail of MCI_DATA | read-only IG on page 1170 |
| TITLE, EDI_MSG, LSIDE, TOOLBAR | OLB frame | f345 page template, hero region, page 0 toolbar, FUNCS drawer |

## 2. Pages

| Page | Name / alias | Mode | Template / class | Source |
|---|---|---|---|---|
| 1170 | IMPR1170 / IMPR1170 | Normal, protection C, Warn on Unsaved Changes = No | Zatca-Minimal_No_Navigation, `zf` | window CGSO$WINDOW_1, canvas CG$PAGE_1 |
| 117001 | IMPR1170_SEARCH / IMPR1170-SEARCH | Modal 1800×800, protection C | theme dialog, `zf` | Enter-Query / Execute-Query (page 0 SEARCH) |

## 3. Regions

| Page | Region (static id) | Type / template | Source |
|---|---|---|---|
| 1170 | الهيدر (`MCI_DATA_HERO`) | Static HTML, `cg-hero`, title `&P1170_HERO_TITLE.` | OLB block TITLE |
| 1170 | بيانات السجل التجارى (`MCI_DATA`) | Form, table `MCI_DATA`, key CR_NBR, not editable, Interactive Report template, `zatca-forms cg-form cg-card` | block MCI_DATA |
| 1170 | ملاك السجل التجارى (`MCI_OWNERS`) | read-only IG, Standard template, `cg-card cg-grid`, Page Items to Submit `P1170_CR_NBR` | block MCI_OWNERS + its POST-QUERY |
| 117001 | بحث (`MCI_DATA_SEARCH_CRITERIA`) | Static, text `P117001_SEARCH` + buttons SEARCH / CLEAR | Enter-Query criteria |
| 117001 | السجلات التجارية (`MCI_DATA_SEARCH`) | read-only IG, lazy loading, no rows until a search; link `CR_NBR` → page 1170 with `P0_PAGE_PK = CR_NBR` | block query (no WHERE clause) + POST-QUERY status |

### 3.1 Grid MCI_OWNERS

```sql
%s
```

| Column | Heading | Data type | Kind |
|---|---|---|---|''' % (g.TITLE, g.OWNERS_SQL))
for col, h, dt, kind in g.OWNERS_COLUMNS:
    w('| `%s` | %s | %s | %s |' % (col, c(h), dt, kind))
w('''
### 3.2 Search grid (page 117001)

```sql
%s
```

| Column | Heading | Data type | Kind |
|---|---|---|---|''' % g.SEARCH_SQL)
for col, h, dt, kind in g.SEARCH_COLUMNS:
    w('| `%s` | %s | %s | %s |' % (col, c(h), dt, kind))
w('''
## 4. Items (page 1170)

Canvas order (rows by Y, right to left by X); Display Only items are read only by type.

| Item | Type | Label | Column | Required | LOV / mask | Read only | Span | Source |
|---|---|---|---|---|---|---|---|---|''')
for name, col, kind, label, dt, newline, span, x in g.ITEMS:
    ro = x.get('read_only')
    ro = 'always' if ro == 'ALWAYS' or kind == 'NATIVE_DISPLAY_ONLY' else ('record' if ro else '–')
    w('| `%s%s` | %s | %s | %s | %s | %s | %s | %s%s | %s |' % (
        g.PI, name, kind.replace('NATIVE_', ''), c(label), c(col), 'Yes' if x.get('req') else '–',
        c(x.get('lov') or x.get('mask')), ro, span, ' (new row)' if newline else '', c(x['src'])))
w('\nNot displayed:\n\n| Item | Type | Column | Mask | Source |\n|---|---|---|---|---|')
for name, col, dt, kind, mask, vp, s in g.HIDDEN:
    w('| `%s%s` | %s | %s | %s | %s |' % (g.PI, name, kind.replace('NATIVE_', ''), c(col), c(mask), c(s)))
w('''
## 5. Buttons

None on page 1170: CREATE · SAVE · DELETE · SEARCH · CLEAR · FUNCS · BACK come from the f345 page 0 toolbar. CREATE / SAVE /
DELETE end in the refusing processes of §8 (decision 0 #3). Page 117001: SEARCH and CLEAR (Defined by Dynamic Action).

## 6. LOVs

| LOV | Created by | Used by | Source |
|---|---|---|---|
| `LOV_COMM_RGSTRTN_TYPE` | IMPR1130 export (`LOV_APX.REFERENCE_CODES(P_DOMAIN => 'COMM_RGSTRTN_TYPE')`) | `P1170_CR_TYPE` | CGDV$POPULATE_DYNAMIC_LISTS |

## 7. Validations

None: CR_NBR WHEN-VALIDATE-ITEM is `NULL;`; the Hijri checks of CR_ISSUE_DATE / CR_EXPIRY_DATE belong to items that are never
enterable. CR_NBR is Required (item attribute), as in Forms.

## 8. Processes (page 1170, f345 standard §6)

| Point | Seq | Name | Code | Condition | Source |
|---|---|---|---|---|---|''')
for point, seq, name, code, cond, s, msg in g.PROCESSES:
    code = {'Initialize form': 'NATIVE_FORM_INIT (region MCI_DATA)', 'New': 'NULL; (Never)'}.get(name, code)
    w('| %s | %d | %s | `%s` | %s | %s |' % (point, seq, name, c(code), c(cond), c(s)))
w('''
## 9. Computations

| Item | Point | Expression | Source |
|---|---|---|---|''')
for item, point, expr, s in g.COMPUTATIONS:
    w('| `%s%s` | %s | `%s` | %s |' % (g.PI, item, point, expr, c(s)))
w('''
## 10. Dynamic Actions (page 1170)

| Name | Event | Element | Client condition | Actions | Source |
|---|---|---|---|---|---|''')
for name, event, sel, cond, init, acts, s in g.DAS:
    a = ', '.join('Submit Page %s' % x['request'] if x['action'] == 'SUBMIT' else x['action'] for x in acts)
    w('| %s | %s | %s | %s | %s | %s |' % (name, event, c(sel and sel[1]), c(cond and cond[0]), a, c(s)))
w('''
Page 117001: `SEARCH` (click → Refresh grid), `SEARCH KEY-ENTER` (keyup Enter → Refresh), `CLEAR WHEN-BUTTON-PRESSED`
(Clear + Refresh), `Hide` (page 0 toolbar hidden in the dialog), as the other search pages.

## 11. Alerts and messages

| Forms | APEX |
|---|---|
| STR.DISPALERT('بيانات السجل التجارى رقم … حالتة غير فعال أو بياناتة غير متاحة فى الوقت الحالى من خدمة الربط مع وزارة التجارة', 'ERROR') | `FORMS_APX.FORM_TRIGGER_FAILURE` in `CR_NBR_KEY_NEXT_ITEM` (page error) |
| page 0 CREATE / SAVE / DELETE | 'لا يمكن إضافة / تعديل / حذف بيانات من هذه الشاشة' (texts to agree; insert / delete texts = IMPR1150) |
| ON-ERROR / CGTE$CHECK_CONSTRAINT_VIO (`MCI_DATA_PK`, ORA-01031) | dropped: no DML on the page |

## 12. Branches and navigation

| Branch | Seq | Condition | Target |
|---|---|---|---|
| EXECUTE-QUERY | 10 | request `EXECUTE_QUERY` | page 1170, clear cache 1170 (`P0_PAGE_PK` set by the process) |
| IMPR1170 - stay in the form | 20 | – | page 1170, clear cache 1170, success message |

The search grid link opens page 1170 with `P0_PAGE_PK = CR_NBR` (the record is shown from the cache, without the service:
as Forms Execute-Query). Page 0 CLEAR empties `P0_PAGE_PK` → a new look-up.

## 13. Shared components

None created. Reused: page group `IMPR` (IMPR1110), Application Setting `HIJRI_DATE_FORMAT` (IMPR1110),
LOV `LOV_COMM_RGSTRTN_TYPE` (IMPR1130), f345 page 0 toolbar, FUNCS drawer and `NUMBER ONLY` DA.
Database: package `IMPR1170` 001; `LIB_USR.PRTL_NEBRAS_SERVICES` (**MISSING SOURCE**, unchanged).

## 14. Traceability (every Forms object)
''')
w(open(os.path.join(ROOT, 'work', 'IMPR1170', 'step03', 'trace.md'), encoding='utf-8').read())
out = os.path.join(ROOT, 'analysis', 'IMPR1170', 'IMPR1170_apex_page_spec.md')
open(out, 'w', encoding='utf-8', newline='\n').write('\n'.join(L))
print('written', out, len(L))
