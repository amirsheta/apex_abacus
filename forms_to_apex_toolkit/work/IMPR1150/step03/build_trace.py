# -*- coding: utf-8 -*-
"""
build_trace.py - IMPR1150 traceability: every Forms object of forms/IMPR/IMPR1150_fmb.xml -> APEX target or rationale.
Writes registry/IMPR1150_registry.sql and work/IMPR1150/step03/trace.md (section 14 of the page spec).
Usage (from forms_to_apex_toolkit): python3 -I work/IMPR1150/step03/build_trace.py
"""
import os, re, html, collections
import xml.etree.ElementTree as ET

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
XML = os.path.join(ROOT, 'forms', 'IMPR', 'IMPR1150_fmb.xml')
NS = '{http://xmlns.oracle.com/Forms}'
fm = ET.parse(XML).getroot().find(NS + 'FormModule')
PG = 1150
FRAME = ('TITLE', 'EDI_MSG', 'LSIDE', 'TOOLBAR')
rows = []

def add(t, name, comp=None, comp_name=None, page=None, member=None, status='MAPPED', notes=''):
    rows.append((t, name, comp, comp_name, page, member, status, notes))

# ---------------------------------------------------------------- blocks
BLOCKS = {
    'TITLE': ('REGION', 'IMPORTERS_CENTRAL_HERO', PG, None, 'MAPPED', 'OLB title bar -> f345 hero region (FORMS_APX.HEADER_TITLE)'),
    'EDI_MSG': (None, None, None, None, 'DROPPED', 'OLB EDI message ticker - dropped (timers, IMPR1110 decision 2026-11-19)'),
    'LSIDE': ('REGION', 'FUNCS (page 0 drawer)', 0, None, 'MAPPED', 'OLB side function menu -> page 0 FUNCS, f345 list Page Functions'),
    'TOOLBAR': ('REGION', 'P0_ACTIONS (page 0 toolbar, f345)', 0, None, 'MAPPED', 'OLB toolbar -> f345 page 0 toolbar'),
    'IMPORTERS_CENTRAL': ('REGION', 'IMPORTERS_CENTRAL (Form, read-only, HQ table over the database link)', PG, None, 'MAPPED',
                          'QUERY_DATA_SOURCE_NAME CUSTOMS.IMPORTERS_CENTRAL@HQPRD.HQ.CUSTOMS.GOV, key IMPR_NBR'),
    'IMPORTER_DOCS': ('REGION', 'IMPORTER_DOCS (read-only IG)', PG, None, 'MAPPED', 'IMPORTERS_DOCS WHERE IMPR_NBR = :P1150_IMPR_NBR'),
}
for b in fm.findall(NS + 'Block'):
    n = b.get('Name')
    add('BLOCK', n, *BLOCKS[n])

# ---------------------------------------------------------------- items
DOC_COLS = {'IMPR_NBR': 'IMPR_NBR (hidden)', 'IMPR_DOC_SEQ': 'IMPR_DOC_ISN (primary key, hidden)', 'DOC_NAME': 'DOC_NAME',
            'DOC_DESC': 'DOC_DESC', 'DOC_PATH': 'DOC_PATH'}
for b in fm.findall(NS + 'Block'):
    bn = b.get('Name')
    for it in b.findall(NS + 'Item'):
        n = it.get('Name')
        full = '%s.%s' % (bn, n)
        if bn in FRAME:
            add('ITEM', full, None, None, None, None, 'DROPPED', 'OLB frame item -> f345 page template / page 0 toolbar / FUNCS')
        elif bn == 'IMPORTERS_CENTRAL':
            if n == 'IMPR_REJCT_RESON2':
                add('ITEM', full, None, None, None, None, 'DROPPED', 'LOV button of IMPR_REJCT_RESON, an item that is never enterable')
            else:
                add('ITEM', full, 'PAGE_ITEM', 'P1150_' + n, PG, None, 'MAPPED',
                    'hidden' if n in ('PORT_CD', 'BIRTH_DT') else 'spec section 4')
        elif bn == 'IMPORTER_DOCS':
            if n == 'OPEN_DEC':
                add('ITEM', full, 'IG_COLUMN', 'DOC_FULL_NAME', PG, None, 'TODO',
                    'HOST(cmd /c START path\\name) on the client PC has no web equivalent: full name shown; how to open the file to agree')
            else:
                add('ITEM', full, 'IG_COLUMN', DOC_COLS[n], PG, None, 'MAPPED', 'IMPORTER_DOCS grid')

# ---------------------------------------------------------------- triggers
BUSINESS = {
    ('FORM', 'WHEN-NEW-FORM-INSTANCE'): ('REGION', 'IMPORTERS_CENTRAL region SQL (HQ table)', PG, None, 'MAPPED',
                                         'SET_BLOCK_PROPERTY(QUERY_DATA_SOURCE_NAME) -> region source; globals reset = new page; NIB / versions dropped'),
    ('FORM', 'PRE-FORM'): ('DA', 'PRE-FORM', PG, None, 'MAPPED', 'REJCT_RESON hidden on page load; NIB / NLS date formats dropped'),
    ('FORM', 'KEY-F9'): ('REGION', 'FUNCS (page 0)', 0, 'ADJ_FUNS', 'MAPPED', 'functions menu; ADJ_FUNS -> P1150_ADJ_FUNS'),
    ('FORM', 'KEY-EXEQRY'): ('REGION', 'IMPORTER_DOCS (query with the page)', PG, None, 'MAPPED', 'NIB.KEY_EXEQRY + DETIL_DATA'),
    ('FORM', 'KEY-DOWN'): ('REGION', 'IMPORTER_DOCS (query with the page)', PG, None, 'MAPPED', 'NIB.KEY_DOWN + DETIL_DATA: one record per page'),
    ('FORM', 'KEY-UP'): ('REGION', 'IMPORTER_DOCS (query with the page)', PG, None, 'MAPPED', 'NIB.KEY_UP + DETIL_DATA: one record per page'),
    ('FORM', 'KEY-ENTQRY'): ('PAGE', 'IMPR1150_SEARCH', 115001, None, 'MAPPED', 'NIB.KEY_ENTQRY -> page 0 SEARCH'),
    ('FORM', 'KEY-DELREC'): ('PROCESS', 'PRE-DELETE', PG, 'IMPR1150.PRE_DELETE', 'MAPPED', 'Delete Allowed = false: request DELETE refused'),
    ('FORM', 'KEY-CLRFRM'): ('BUTTON', 'CLEAR (page 0 toolbar)', 0, None, 'MAPPED', 'clear_form + CG$WHEN_NEW_FORM_INSTANCE (lists: shared LOVs)'),
    ('FORM', 'KEY-CLRBLK'): ('BUTTON', 'CLEAR (page 0 toolbar)', 0, None, 'MAPPED', 'NIB.KEY_CLRBLK'),
    ('FORM', 'KEY-EXIT'): ('BUTTON', 'BACK (page 0 toolbar)', 0, None, 'MAPPED', 'NIB.KEY_EXIT'),
    ('IMPORTERS_CENTRAL', 'POST-QUERY'): ('PROCESS', 'POST-QUERY', PG, 'IMPR1150.POST_QUERY', 'MAPPED', 'Before Header after Initialize form'),
    ('IMPORTERS_CENTRAL', 'PRE-QUERY'): ('PROCESS', 'EXECUTE-QUERY', PG, 'IMPR1150.IMPORTER_KEY', 'MAPPED', 'query key IMPR_NBR / BUS_ID, PORT_CD 99'),
    ('IMPORTERS_CENTRAL', 'PRE-UPDATE'): ('PROCESS', 'PRE-UPDATE', PG, 'IMPR1150.PRE_UPDATE', 'MAPPED', 'request SAVE: message only (no DML)'),
    ('IMPORTERS_CENTRAL', 'WHEN-NEW-ITEM-INSTANCE'): ('BRANCH', 'EXECUTE-QUERY', PG, None, 'MAPPED',
                                                      'EXEC_QUERY_NOW -> DA Submit Page EXECUTE_QUERY + branch; docs grid queried with the page'),
    ('IMPORTERS_CENTRAL', 'WHEN-NEW-RECORD-INSTANCE'): ('COMPUTATION', 'P1150_ADJ_FUNS', PG, 'IMPR1150.ADJ_FUNS', 'MAPPED', 'ADJ_FUNS'),
    ('IMPORTERS_CENTRAL', 'ON-ERROR'): ('APP_ITEM', 'APEX error handling (FORMS_APX / f345)', None, None, 'MAPPED',
                                        'no DML from the page: FRM-40508/9/10 messages and IC_NATIONALITY_FK cannot occur'),
    ('IMPORTER_DOCS', 'ON-ERROR'): ('APP_ITEM', 'APEX error handling (FORMS_APX / f345)', None, None, 'MAPPED', 'query only'),
    ('IMPORTERS_CENTRAL.IMPR_NBR', 'WHEN-VALIDATE-ITEM'): ('VALIDATION', 'IMPR_NBR VALIDATION + DA IMPR_NBR WHEN-VALIDATE-ITEM', PG,
                                                           'IMPR1150.IMPR_NBR_VALIDATION', 'MAPPED', 'message 9-150; CGUV$CHK_IMP_CNTRL_PK'),
    ('IMPORTERS_CENTRAL.BUS_ID', 'WHEN-VALIDATE-ITEM'): ('VALIDATION', 'BUS_ID VALIDATION + DA BUS_ID WHEN-VALIDATE-ITEM', PG,
                                                         'IMPR1150.BUS_ID_VALIDATION', 'MAPPED', 'message 9-150'),
    ('IMPORTERS_CENTRAL.BUS_ID_EXPRD_DT', 'WHEN-VALIDATE-ITEM'): (None, None, None, None, 'DROPPED',
                                                                  'item never enterable (Insert / Update Allowed = false): the check cannot fire'),
    ('IMPORTERS_CENTRAL.IMPR_REJCT_RESON2', 'WHEN-BUTTON-PRESSED'): (None, None, None, None, 'DROPPED',
                                                                     'LOV of a non-enterable item (do_key LIST_VALUES)'),
    ('IMPORTER_DOCS.OPEN_DEC', 'WHEN-BUTTON-PRESSED'): ('IG_COLUMN', 'DOC_FULL_NAME', PG, None, 'TODO',
                                                        'OPEN_FILE_DOS: HOST on the client PC; open the document - to agree'),
}
for owner_el, owner in [(fm, 'FORM')] + [(b, b.get('Name')) for b in fm.findall(NS + 'Block')]:
    for t in owner_el.findall(NS + 'Trigger'):
        tn = t.get('Name')
        key = (owner, tn)
        if key in BUSINESS:
            add('TRIGGER', '%s.%s' % key, *BUSINESS[key])
        elif owner in FRAME:
            add('TRIGGER', '%s.%s' % key, None, None, None, None, 'DROPPED', 'OLB frame block trigger (toolbar keys)')
        elif tn == 'KEY-HELP':
            add('TRIGGER', '%s.%s' % key, None, None, None, None, 'DROPPED', 'Designer help file (empty CG$HP_HFILE)')
        else:
            add('TRIGGER', '%s.%s' % key, None, None, None, None, 'DROPPED',
                'screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS)')
    if owner_el is fm:
        continue
    for it in owner_el.findall(NS + 'Item'):
        for t in it.findall(NS + 'Trigger'):
            full = '%s.%s' % (owner, it.get('Name'))
            tn = t.get('Name')
            if (full, tn) in BUSINESS:
                add('TRIGGER', '%s.%s' % (full, tn), *BUSINESS[(full, tn)])
            elif owner in FRAME:
                add('TRIGGER', '%s.%s' % (full, tn), None, None, None, None, 'DROPPED', 'OLB frame item trigger (mouse / toolbar)')
            elif tn == 'KEY-LISTVAL':
                add('TRIGGER', '%s.%s' % (full, tn), None, None, None, None, 'DROPPED',
                    'Designer "may the LOV be shown" check: APEX shows a list only on an enterable item')
            else:
                raise SystemExit('unclassified trigger %s %s' % (full, tn))

# ---------------------------------------------------------------- program units
PUS = {
    'EXECUTE_FUNCTION': ('REGION', 'FUNCS (page 0)', 0, None, 'MAPPED', 'f345 Page Functions -> custom events IMPR1150_ACTIVATE / IMPR1150_REJECT'),
    'MOUSE_CLICK': ('REGION', 'FUNCS (page 0)', 0, None, 'MAPPED', 'function list click'),
    'EXEC_FUNS': ('PROCESS', 'IMPR1150_ACTIVATE / IMPR1150_REJECT EXECUTE-FUNCTION', PG, 'IMPR1150.EXEC_FUNS', 'MAPPED',
                  'HQ UPDATE over the database link + ACTIVITY_DB; REJECT first press = DA'),
    'ADJ_FUNS': ('COMPUTATION', 'P1150_ADJ_FUNS', PG, 'IMPR1150.ADJ_FUNS', 'MAPPED', 'TMPLT.ENABLE_FUN / DISABLE_FUN'),
    'DETIL_DATA': ('REGION', 'IMPORTER_DOCS', PG, None, 'MAPPED', 'grid query WHERE IMPR_NBR = :P1150_IMPR_NBR (empty without importer)'),
    'OPEN_FILE_DOS': ('IG_COLUMN', 'DOC_FULL_NAME', PG, None, 'TODO', 'HOST on the client PC: to agree'),
    'CG$WHEN_NEW_FORM_INSTANCE': (None, None, None, None, 'DROPPED', 'lists -> shared LOVs'),
    'CGDV$POPULATE_DYNAMIC_LISTS': ('LOV', 'LOV_PENDING_ACTIVE', PG, None, 'MAPPED', 'LOV_APX.REFERENCE_CODES(PENDING_ACTIVE)'),
    'CGUV$CHK_IMP_CNTRL_PK': ('VALIDATION', 'IMPR_NBR VALIDATION', PG, 'IMPR1150.IMPR_NBR_VALIDATION', 'MAPPED', 'local key check'),
    'CGTE$CHECK_CONSTRAINT_VIO': ('APP_ITEM', 'APEX error handling (FORMS_APX / f345)', None, None, 'MAPPED', 'no DML from the page'),
}
for pu in fm.findall(NS + 'ProgramUnit'):
    n = pu.get('Name')
    add('PROGRAM_UNIT', n, *PUS.get(n, (None, None, None, None, 'DROPPED',
                                        'NIB wrapper not called by active code (timers, EDI ticker, window, print)')))

# ---------------------------------------------------------------- LOVs, record groups, alerts, parameters, canvases, windows, libraries
for l in fm.findall(NS + 'LOV'):
    add('LOV', l.get('Name'), 'LOV', 'LOV_IMPR_REJCT_RESON', PG, None, 'MAPPED', 'LOV_APX.REFERENCE_CODES(IMPR_REJCT_RESON)')
for g in fm.findall(NS + 'RecordGroup'):
    add('RECORD_GROUP', g.get('Name'), 'LOV', 'LOV_IMPR_REJCT_RESON', PG, None, 'MAPPED', 'CG_REF_CODES domain IMPR_REJCT_RESON')
add('RECORD_GROUP', 'CGDV$DLRG (runtime)', 'LOV', 'LOV_PENDING_ACTIVE', PG, None, 'MAPPED', 'CREATE_GROUP_FROM_QUERY CG_REF_CODES PENDING_ACTIVE')
for a in fm.findall(NS + 'Alert'):
    n = a.get('Name')
    if n in ('CFG_ERROR', 'CFG_INFORMATION'):
        add('ALERT', n, 'APP_ITEM', 'page messages (FORMS_APX.FORM_TRIGGER_FAILURE / MESSAGE)', None, None, 'MAPPED', 'STR.DISPALERT')
    else:
        add('ALERT', n, None, None, None, None, 'DROPPED', 'OLB alert not referenced by this form')
for p in fm.findall(NS + 'ModuleParameter'):
    n = p.get('Name')
    if n == 'P_CURR_PORT_CD':
        add('PARAMETER', n, 'APP_ITEM', 'P_CURR_PORT_CD (f345)', None, None, 'MAPPED', 'block WHERE clause, activity port')
    elif n == 'P_MODULE_ID':
        add('PARAMETER', n, 'PAGE_ITEM', 'P1150_MODULE_ID', PG, None, 'MAPPED', 'FORMS_APX.GET_MODULE_ID')
    elif n in ('P_USER_ID', 'P_WS_ID'):
        add('PARAMETER', n, 'APP_ITEM', {'P_USER_ID': 'SSO_APP_USER', 'P_WS_ID': 'P_GLOBAL_V_WS_ID'}[n] + ' (f345)', None, None,
            'MAPPED', 'activity log')
    else:
        add('PARAMETER', n, None, None, None, None, 'DROPPED', 'used only by the OLB frame (EXECUTE_FUNCTION parameter list, print, EDI)')
for c in fm.findall(NS + 'Canvas'):
    n = c.get('Name')
    add('CANVAS', n, *(('PAGE', 'IMPR1150', PG, None, 'MAPPED', 'regions IMPORTERS_CENTRAL, IMPORTER_DOCS') if n == 'CG$PAGE_1'
                       else (None, None, None, None, 'DROPPED', 'OLB frame canvas')))
for w in fm.findall(NS + 'Window'):
    add('WINDOW', w.get('Name'), 'PAGE', 'IMPR1150', PG, None, 'MAPPED', 'one page')
for l in fm.findall(NS + 'AttachedLibrary'):
    n = l.get('Name')
    if n == 'CIC_LIB':
        add('LIBRARY', n, 'PACKAGE', 'FORMS_APX / ACTIVITY_DB', None, None, 'MAPPED', 'STR -> FORMS_APX, ACTIVITY -> ACTIVITY_DB, TMPLT -> FUNCS')
    else:
        add('LIBRARY', n, None, None, None, None, 'DROPPED', 'frame / client library (windows, timers, help, DLLs)')
for g in ('BUS_ID', 'IMPR_NBR', 'PORT_CD', 'EXEC_QUERY_NOW'):
    add('GLOBAL', g, 'PROCESS', 'EXECUTE-QUERY', PG, 'IMPR1150.IMPORTER_KEY', 'MAPPED', 'query key passed by the request EXECUTE_QUERY')
for g in ('CG$HP_HFILE', 'CG$HP_HPATH', 'CURRENT_DT', 'CURRENT_VER', 'CURRENT_VERSION', 'EXIT', 'SYSTEM_OBJ'):
    add('GLOBAL', g, None, None, None, None, 'DROPPED', 'help / screen version / frame')

# ---------------------------------------------------------------- write
cnt = collections.Counter(r[6] for r in rows)
def s(v):
    return 'NULL' if v is None else str(v) if isinstance(v, int) else "'%s'" % str(v).replace("'", "''")
out = ['''-- =============================================================================
-- IMPR1150 - migration registry rows (scripts/create_migration_registry.sql)
-- Purpose : MIG_FORM_REGISTRY row for the form + one MIG_OBJECT_MAP row per Forms object
--           (traceability matrix, analysis/IMPR1150/IMPR1150_apex_page_spec.md section 14)
-- Form    : IMPR1150.fmb (module IMPR1150_PROD_CENTRL)
-- Author  : Claude Code
-- Date    : 2026-11-25
-- Version : 1.0 (step 03 revision 1, package IMPR1150 version 001)
-- Generated by work/IMPR1150/step03/build_trace.py - %d objects: %s.
-- app_id 202530 = the application installed from f345. Re-runnable: deletes the form's rows first.
-- NOT executed (CLAUDE.md 6.10).
-- =============================================================================
SET DEFINE OFF

DELETE FROM mig_object_map    WHERE form_name = 'IMPR1150';
DELETE FROM mig_form_registry WHERE form_name = 'IMPR1150';

INSERT INTO mig_form_registry
    (form_name, forms_app, subsystem, app_id, page_from, page_to, page_alias,
     package_name, complexity, status, owner, business_owner, notes)
VALUES
    ('IMPR1150', 'IMPR', 'IMPR', 202530, 1150, 1150, 'IMPR1150',
     'IMPR1150', 'COMPLEX', 'DESIGN', NULL, NULL,
     'تفعيل المستوردين من منصة فسح (IMPR1150_PROD_CENTRL) - pages 1150, 115001; HQ table over the database link; package IMPR1150 001 not compiled; business logic simple');

DECLARE
    PROCEDURE m (p_type    VARCHAR2, p_name   VARCHAR2, p_comp  VARCHAR2, p_comp_name VARCHAR2,
                 p_page    NUMBER,   p_member VARCHAR2, p_status VARCHAR2, p_notes   VARCHAR2)
    IS
    BEGIN
        INSERT INTO mig_object_map
            (form_name, forms_object_type, forms_object_name, apex_comp_type,
             apex_comp_name, page_id, plsql_member, status, notes)
        VALUES ('IMPR1150', p_type, p_name, p_comp, p_comp_name, p_page, p_member, p_status, p_notes);
    END m;
BEGIN''' % (len(rows), ', '.join('%s %d' % kv for kv in sorted(cnt.items())))]
for r in rows:
    out.append('    m(%s);' % ', '.join(s(v) for v in r))
out.append('END;\n/\n\nCOMMIT;\n')
open(os.path.join(ROOT, 'registry', 'IMPR1150_registry.sql'), 'w', encoding='utf-8', newline='\n').write('\n'.join(out))
md = ['| # | Type | Forms object | APEX component | Page | Package member | Status | Notes |', '|---|---|---|---|---|---|---|---|']
for i, r in enumerate(rows, 1):
    md.append('| %d | %s |' % (i, ' | '.join(('`%s`' % r[1]) if j == 1 else ('-' if v is None else str(v).replace('|', '\\|'))
                                             for j, v in enumerate(r))))
open(os.path.join(ROOT, 'work', 'IMPR1150', 'step03', 'trace.md'), 'w', encoding='utf-8').write(
    '%d objects: %s.\n\n' % (len(rows), ', '.join('%s %d' % kv for kv in sorted(cnt.items()))) + '\n'.join(md) + '\n')
print(len(rows), dict(cnt))
