"""Step 03 - write analysis/IMPR1130/IMPR1130_apex_page_spec.md and registry/IMPR1130_registry.sql from
work/IMPR1130/step03/page_design.json (build_design.py). The decisions (section 0) are written here.
Usage: python3 -I work/IMPR1130/step03/build_design.py && python3 -I work/IMPR1130/step03/build_spec.py
"""
import json, collections

D = json.load(open('work/IMPR1130/step03/page_design.json', encoding='utf-8'))
PI = 'P1130_'


def cell(v):
    v = '-' if v in (None, '') else str(v)
    return v.replace('|', '\\|').replace('\n', ' ')


def table(head, rows):
    out = ['| ' + ' | '.join(head) + ' |', '|' + '---|' * len(head)]
    out += ['| ' + ' | '.join(cell(x) for x in r) + ' |' for r in rows]
    return '\n'.join(out) + '\n'


S = []
W = S.append
W('''# IMPR1130 – APEX 21.2 Page Specification (step 03, revision 1)

- **Form:** IMPR1130 (XML module `IMPR1110_PROD_CENTRL`) – "إضافة وتعديل بيانات مستورد"
- **Package:** `IMPR1130` version 001 (`plsql/IMPR1130/`), logic report `analysis/IMPR1130/IMPR1130_logic_extraction.md`
- **Standard:** f345 (`apex/Reference/f345.sql`), CLAUDE.md §4a–§4d, `docs/f345_reference_standard.md`
- **Design data:** `work/IMPR1130/step03/page_design.json` (`build_design.py`); this file and `registry/IMPR1130_registry.sql`
  are rendered from it by `build_spec.py`; the export of step 04 (`scripts/gen_apex_impr1130.py`) reads the same data.
- **Produced:** 2026-11-24 by Claude Code. Same page design as IMPR1110 (revision 2) wherever the forms agree.

## 0. Decisions that shape the page

| # | Decision | Reason / source |
|---|---|---|
| 1 | Main page **1130** `IMPR1130`, search page **113001** `IMPR1130_SEARCH` (modal 1800×800), page group `IMPR` (reused from the IMPR1110 export) | f345 standard §3; registry page plan (SUPPORT_ENTRY already names 1130 as a caller) |
| 2 | Block IMPORTERS = native **Form** region on `IMPORTERS`, key **ROWID** (Forms key mode), `WHERE PORT_CD = :P_CURR_PORT_CD`, operations insert / update; delete by process `KEY-DELREC` | as IMPR1110; IMPR1130 allows delete (inventory §3 notes) |
| 3 | One validation + one DA per Forms WHEN-VALIDATE-ITEM; validation functions never change values or read sequences | CLAUDE.md §4c; package design §1 |
| 4 | Read-only rules: 8 flag items `P1130_<ITEM>_LOCKED` set by `READ_ONLY_FLAGS` (rules that change while the page is open) and Read Only conditions for IMPR_NBR, IMPR_TYPE_CD, BUS_ID_TYPE_CD, ARBC_IMPR_NAME, ENG_IMPR_NAME | IMPR1130's own rules: `work/IMPR1130/step02/read_only_rules.md` |
| 5 | Questions computed on the server (9-120 of CITY_CODE_OF_ID, UPDATE_IMPORTER): FOS returns `P1130_CONFIRM_TEXT`, a 2-line `apex.message.confirm` sets `P1130_ANSWER` and raises a custom event for the second FOS | IMPR1110 pattern (21.2 native Confirm cannot show server text); 2 JavaScript actions of 2 lines |
| 6 | SUPPORT_ENTRY: page 9001 opened on the **first view** of the form with `P_MODE 0` (Forms CALL_FORM in WNFI); button "بيانات المساندة الفنية" opens it again on demand (edit mode `P_MODE 1` when a letter exists) | SUPPORT_ENTRY contract §0.4 / D1; inventory §15 #3 |
| 7 | Shared components of the IMPR1110 export are **reused**: page group, application items (`G_ALLOW_MCI`, `G_ALLOW_MOI`, `G_LETTER_*`, `G_PORT_CD`, `G_SUPP_TITLE_CD`, `G_CHK_IMP_TYP`, `P_PRSNL_IMPR`, `P_LETTER_NBR`), Application Setting `HIJRI_DATE_FORMAT`, 8 LOVs. Four LOVs whose query names a page item are new (`LOV_IMPR1130_*`) | CLAUDE.md §4b.1; §4d (same LOV_APX functions) |
| 8 | Country LOV of CTRY_CD: IMPR1130 also shows the Gulf list for activity type 12; `LOV_APX.GULF_COUNTRIES` has no such option yet → **change request** `work/IMPR1130/step03/lov_apx_change_request.md` (not applied: LOV_APX is being changed by another session). Until then type 12 gets all active countries; `CTRY_CD VALIDATION` still refuses a non-Gulf country | CLAUDE.md §4d.2 (add a parameter, no copy) |
| 9 | Toolbar: page 0 (CREATE / SAVE / DELETE / SEARCH / CLEAR / FUNCS); the functions drawer shows `IMPR_MCI_SERVICE` when `P1130_ADJ_FUNS` contains it | CLAUDE.md §4a.5 |
| 10 | Navigation keys (KEY-NEXT-ITEM, GO_ITEM after the LOVs, KEY-F4 / KEY-LISTVAL calendars) are not converted: normal tab order, popup LOVs and the Hijri picker | CLAUDE.md §4c (no client UI state) |

## 1. Page type decision per block

''')
W(table(['Block', 'Forms', 'APEX'], [
    ['IMPORTERS', 'base table, single record in use, query + insert + update + delete', 'Form region (page 1130) + search IG (page 113001)'],
    ['TITLE, EDI_MSG, LSIDE, TOOLBAR', 'OLB control blocks (frame)', 'f345 page template, hero region, page 0 toolbar, FUNCS drawer']]))
W('\n## 2. Pages\n\n')
W(table(['Page', 'Name / alias', 'Title', 'Mode', 'Template / class', 'Source'], [
    ['1130', 'IMPR1130 / IMPR1130', '&SYS_ANAME. (hero: module title)', 'Normal, Warn on Unsaved Changes, protection C',
     'Zatca-Minimal_No_Navigation (11622270914969205733), `zf`', 'window CGSO$WINDOW_1, canvas CG$PAGE_1'],
    ['113001', 'IMPR1130_SEARCH / IMPR1130-SEARCH', '&SYS_ANAME.', 'Modal 1800×800, protection C', 'theme dialog, `zf`',
     'Enter-Query / Execute-Query of IMPORTERS (page 0 SEARCH)']]))
W('''
## 3. Regions

| Page | Region (Static ID) | Type | Template / classes | Source |
|---|---|---|---|---|
| 1130 | `IMPORTERS_HERO` "الهيدر" | Static HTML with `&P1130_HERO_TITLE.`; button `SUPPORT_ENTRY` | f345 hero (11621859120066869682), `cg-hero` | TITLE (OLB) |
| 1130 | `IMPORTERS` "إضافة وتعديل بيانات مستورد" | Form, table IMPORTERS, ROWID, WHERE `PORT_CD = :P_CURR_PORT_CD`, insert / update | Interactive Report (11621909206693869707), `zatca-forms cg-form cg-card` | block IMPORTERS |
| 113001 | `IMPORTERS_SEARCH_CRITERIA` "بحث" | Static, item `P113001_SEARCH`, buttons SEARCH / CLEAR | f345 hero | PRE-QUERY criteria |
| 113001 | `IMPORTERS_SEARCH` "المستوردون" | Interactive Grid (read-only), one search text over all columns, no rows before a search, `PRSNL_IMPR` → type 4 only, link IMPR_NBR → page 1130 with the URL-safe ROWID | Standard (11621913486616869708), `t-Region--noPadding`, `cg-card cg-grid` | block query + PRE-QUERY |

## 4. Items (page 1130)

Layout from the canvas CG$PAGE_1 (rows by Y, right to left by X, 12 columns). Read-only rule: §0 #4.

''')
W(table(['Item', 'Column', 'Type', 'Label', 'Required', 'Mask', 'Default', 'LOV', 'Parents', 'Max', 'Layout', 'Read only', 'Source', 'Notes', 'Submit'],
        [[i['name'], i['column'], i['type'], i['label'], i['required'], i['mask'], i['default'], i['lov'], i['parents'],
          i['maxlen'], i['layout'], i['read_only'], i['source'], i['notes'], i['submit']] for i in D['items']]))
W('''
## 5. Buttons

| Page | Button | Label | Action | Source |
|---|---|---|---|---|
| 0 | CREATE / SAVE / DELETE / SEARCH / CLEAR / FUNCS | f345 page 0 toolbar | requests CREATE, SAVE, DELETE; SEARCH opens 113001 | TOOLBAR (OLB), KEY-COMMIT, KEY-DELREC, KEY-ENTQRY |
| 1130 | `SUPPORT_ENTRY` (hero region) | بيانات المساندة الفنية | DA → `SUPPORT_ENTRY.OPEN_DIALOG` (P_MODE 0 / 1) | WNFI OPEN_FORM(SUPPORT_ENTRY) |
| 113001 | `SEARCH`, `CLEAR` | بحث / مسح البحث | refresh the grid / clear the text | EXECUTE_QUERY, CLEAR |

## 6. LOVs

All SQL LOVs: *PL/SQL Function Body returning SQL Query* calling one `LOV_APX` function, return column `R`, display `D`.

''')
W(table(['LOV', 'Status', 'LOV_APX call / source'],
        [[l['name'], 'reused (IMPR1110 export)', l['source']] for l in D['lovs']['reused']]
        + [[l['name'], 'new', '`return %s;` – %s' % (l['call'], l['source'])] for l in D['lovs']['new']]))
W('\n## 7. Validations (page 1130, request CREATE / SAVE)\n\n')
W(table(['#', 'Name', 'Item', 'PL/SQL Function Body returning Error Text', 'Extra condition', 'Source'],
        [[n, v['name'], v['item'], '`%s`' % v['code'], v.get('condition', '-'), v['source']]
         for n, v in enumerate(D['validations'], 1)]))
W('\nNo page validation for EMAIL (Forms checks it only when the user leaves the item: DA only).\n\n## 8. Processes\n\n')
W(table(['Point', 'Seq', 'Name', 'Code', 'Condition', 'Source'],
        [[p['point'], p['seq'], p['name'], '`%s`' % p['code'] if 'IMPR1130.' in p['code'] or ':=' in p['code'] or 'FORMS_APX' in p['code'] else p['code'],
          p['condition'], p['source']] for p in D['processes']]))
W('\n## 9. Computations\n\n')
W(table(['Item', 'Point', 'Expression', 'Condition', 'Source'],
        [[c['item'], c['point'], '`%s`' % c['expression'], c['condition'], c['source']] for c in D['computations']]))
W('\n## 10. Dynamic Actions (page 1130)\n\n')
rows = []
for d in D['das']:
    for k, a in enumerate(d['actions']):
        rows.append([d['name'] if k == 0 else '', d['event'] if k == 0 else '', d['selection'] if k == 0 else '',
                     d['condition'] if k == 0 else '', d['fire_init'] if k == 0 else '', k + 1, a['action'],
                     '`%s`' % a['code'].replace('\n', ' ') if a['action'].startswith(('FOS', 'Execute')) else a['code'],
                     ', '.join(a['submit']) or '-', ', '.join(a['ret']) or '-', a['note'] or '-', d['source'] if k == 0 else ''])
W(table(['DA', 'Event', 'Selection', 'Client condition', 'Fire on init', '#', 'Action', 'Code', 'Items to Submit',
         'Items to Return', 'Note', 'Source'], rows))
W('''
JavaScript actions: 4, each 1–2 lines (two confirms, two `apex.navigation.redirect` to page 9001).

## 11. Alerts and messages

| Forms | APEX |
|---|---|
| `STR.DispAlert` / `DispArbMsg` ERROR, INFORMATION + RAISE | error text of the validation / FOS (`FORMS_APX.CHECK_ERROR`, `FORM_TRIGGER_FAILURE`) |
| `STR.DispAlert` / `DispArbMsg` without RAISE, Designer warnings | `FORMS_APX.MESSAGE` (page message) |
| CONFIRM 9-120 (CITY_CODE_OF_ID), CONFIRM of UPDATE_IMPORTER | §0 #5 |
| KEY-DELREC 'هل أنت متأكد من عملية الحذف' | confirm of the page 0 DELETE button |
| ON-ERROR constraint messages, delete check messages | `IMPR1130.KEY_DELREC` / validations (package `importers_on_error`) |

## 12. Branches and navigation

| Branch | Condition | Target |
|---|---|---|
| `EXECUTE-QUERY` (seq 10) | request EXECUTE_QUERY | page 1130, clear cache 1130, `P0_PAGE_PK` kept (set by process EXECUTE-QUERY) |
| `IMPR1130 - stay in the form` (seq 20) | – | page 1130 with the success message (Forms stays on the record after COMMIT) |
| search grid link | – | page 1130, `P0_PAGE_PK` = URL-safe ROWID (`P0_PAGE_PK_CHECK` translates it back) |
| page 9001 | DAs §10 | `SUPPORT_ENTRY.OPEN_DIALOG` URL; its own `G_LAST_PAGE KEEP` returns to 1130 |

## 13. Shared components

### 13.1 Reused (do not create)
f345: theme 42, templates, page 0 (toolbar, FUNCS, `NUMBER ONLY`), application items `SSO_APP_USER`, `P_CURR_PORT_CD`,
`P_GLOBAL_V_WS_ID`, `P_CLASS_CD`, `V_USR_TYPE`, `G_LAST_PAGE`. IMPR1110 export: page group `IMPR`, the items of §0 #7,
Application Setting `HIJRI_DATE_FORMAT`, LOVs of §6 marked reused. SUPPORT_ENTRY export: page 9001, `G_SUPPORT_ENTRY_CALLER`.

### 13.2 New
LOVs `LOV_IMPR1130_IMPR_TYPE_BUS_ID`, `LOV_IMPR1130_COUNTRIES_GULF`, `LOV_IMPR1130_CITIES_OF_ID`, `LOV_IMPR1130_CITIES`
(ids base 9130). No new application item, message or authorization scheme (CLAUDE.md §8).

## 14. Traceability matrix (every object of the XML)

''')
st = collections.Counter(r[6] for r in D['trace'])
W('%d rows: %s.\n\n' % (len(D['trace']), ', '.join('%s %d' % kv for kv in sorted(st.items()))))
W(table(['Forms type', 'Forms object', 'APEX type', 'APEX component', 'Page', 'Package member', 'Status', 'Notes'], D['trace']))
W('''
## 15. Registry script

`registry/IMPR1130_registry.sql`: one MIG_FORM_REGISTRY row and the %d MIG_OBJECT_MAP rows of §14 (not executed).

## 16. Open items

| # | Item | Owner |
|---|---|---|
| 1 | LOV_APX change request: Gulf list for activity type 12 (§0 #8) | next LOV_APX change (coordinate with the IMPR1140 session) |
| 2 | Read-only interpretations (`read_only_rules.md` "Interpretations") | business owner |
| 3 | SUPPORT_ENTRY shown on every first view (inventory §15 #3) | business owner |
| 4 | Package `IMPR1130` 001 and `LOV_APX` / `FORMS_APX` compiled before the import | DBA |
| 5 | Open questions of the inventory §15 (#1, #4, #5, #15, #16) | business owner / DBA |
''' % len(D['trace']))
open('analysis/IMPR1130/IMPR1130_apex_page_spec.md', 'w', encoding='utf-8').write(''.join(S))

# ----------------------------------------------------------------------------- registry
q = lambda v: 'NULL' if v in (None, '') else "'%s'" % str(v).replace("'", "''")
cnt = collections.Counter(r[6] for r in D['trace'])
R = ['''-- =============================================================================
-- IMPR1130 - migration registry rows (scripts/create_migration_registry.sql)
-- Purpose : MIG_FORM_REGISTRY row for the form + one MIG_OBJECT_MAP row per Forms object
--           (traceability matrix, analysis/IMPR1130/IMPR1130_apex_page_spec.md section 14)
-- Form    : IMPR1130.fmb
-- Author  : Claude Code
-- Date    : 2026-11-24
-- Version : 1.0 (step 03 revision 1)
-- Generated by work/IMPR1130/step03/build_spec.py - %d object rows (%s).
-- app_id 202530 = the application installed from f345. Re-runnable: deletes the form's rows first.
-- NOT executed (CLAUDE.md 6.10).
-- =============================================================================
SET DEFINE OFF

DELETE FROM mig_object_map    WHERE form_name = 'IMPR1130';
DELETE FROM mig_form_registry WHERE form_name = 'IMPR1130';

INSERT INTO mig_form_registry
    (form_name, forms_app, subsystem, app_id, page_from, page_to, page_alias,
     package_name, complexity, status, owner, business_owner, notes)
VALUES
    ('IMPR1130', 'IMPR', 'IMPR', 202530, 1130, 1130, 'IMPR1130',
     'IMPR1130', 'COMPLEX', 'DESIGN', NULL, NULL,
     'إضافة وتعديل بيانات مستورد (older copy of IMPR1110) - step 03 page design (pages 1130, 113001); package IMPR1130 001 not compiled');

DECLARE
    PROCEDURE m (p_type    VARCHAR2, p_name   VARCHAR2, p_comp  VARCHAR2, p_comp_name VARCHAR2,
                 p_page    NUMBER,   p_member VARCHAR2, p_status VARCHAR2, p_notes   VARCHAR2)
    IS
    BEGIN
        INSERT INTO mig_object_map
            (form_name, forms_object_type, forms_object_name, apex_comp_type,
             apex_comp_name, page_id, plsql_member, status, notes)
        VALUES ('IMPR1130', p_type, p_name, p_comp, p_comp_name, p_page, p_member, p_status, p_notes);
    END m;
BEGIN
''' % (len(D['trace']), ', '.join('%s %d' % kv for kv in sorted(cnt.items())))]
for r in D['trace']:
    R.append("    m(%s, %s, %s, %s, %s, %s, %s, %s);\n" % (q(r[0]), q(r[1]), q(r[2]), q(r[3][:200] if r[3] else r[3]),
                                                      r[4] or 'NULL', q(r[5]), q(r[6]), q(r[7][:400] if r[7] else r[7])))
R.append('END;\n/\n\nCOMMIT;\n')
open('registry/IMPR1130_registry.sql', 'w', encoding='utf-8').write(''.join(R))
print('spec and registry written:', len(D['trace']), 'trace rows', dict(cnt))
