# -*- coding: utf-8 -*-
"""
build_trace.py - IMPR1170 traceability: every Forms object of forms/IMPR/IMPR1170_fmb.xml -> APEX target or rationale.
Writes registry/IMPR1170_registry.sql and work/IMPR1170/step03/trace.md (section 14 of the page spec).
Usage (from forms_to_apex_toolkit): python3 -I work/IMPR1170/step03/build_trace.py
"""
import os, collections
import xml.etree.ElementTree as ET

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
XML = os.path.join(ROOT, 'forms', 'IMPR', 'IMPR1170_fmb.xml')
NS = '{http://xmlns.oracle.com/Forms}'
fm = ET.parse(XML).getroot().find(NS + 'FormModule')
PG, PS = 1170, 117001
FRAME = ('TITLE', 'EDI_MSG', 'LSIDE', 'TOOLBAR')
rows = []

def add(t, name, comp=None, comp_name=None, page=None, member=None, status='MAPPED', notes=''):
    rows.append((t, name, comp, comp_name, page, member, status, notes))

# ---------------------------------------------------------------- blocks
BLOCKS = {
    'TITLE': ('REGION', 'MCI_DATA_HERO', PG, None, 'MAPPED', 'OLB title bar -> f345 hero region (FORMS_APX.HEADER_TITLE)'),
    'EDI_MSG': (None, None, None, None, 'DROPPED', 'OLB EDI message ticker - dropped (timers, IMPR1110 decision 2026-11-19)'),
    'LSIDE': ('REGION', 'FUNCS (page 0 drawer)', 0, None, 'MAPPED', 'OLB side function menu -> page 0 FUNCS, f345 list Page Functions'),
    'TOOLBAR': ('REGION', 'P0_ACTIONS (page 0 toolbar, f345)', 0, None, 'MAPPED', 'OLB toolbar -> f345 page 0 toolbar'),
    'MCI_DATA': ('REGION', 'MCI_DATA (Form, query only, key CR_NBR)', PG, None, 'MAPPED',
                 'Update / Delete Allowed = false; insert refused (spec 0 #3)'),
    'MCI_OWNERS': ('REGION', 'MCI_OWNERS (read-only Interactive Grid)', PG, None, 'MAPPED',
                   'detail of MCI_DATA by CR_NBR; 4 records shown, query only'),
}
for b in fm.findall(NS + 'Block'):
    add('BLOCK', b.get('Name'), *BLOCKS[b.get('Name')])

# ---------------------------------------------------------------- items
HIDDEN = ('MCI_DATA.CR_EXPIRY_DATE',)
for b in fm.findall(NS + 'Block'):
    bn = b.get('Name')
    for it in b.findall(NS + 'Item'):
        n = it.get('Name')
        full = '%s.%s' % (bn, n)
        if bn in FRAME:
            add('ITEM', full, None, None, None, None, 'DROPPED', 'OLB frame item -> f345 page template / page 0 toolbar / FUNCS')
        elif bn == 'MCI_OWNERS':
            add('ITEM', full, 'IG_COLUMN', 'MCI_OWNERS.' + n, PG, None, 'MAPPED',
                'hidden column' if it.get('Visible') == 'false' else 'spec section 3')
        else:
            add('ITEM', full, 'PAGE_ITEM', 'P1170_' + n, PG, None, 'MAPPED', 'not displayed' if full in HIDDEN else 'spec section 4')

# ---------------------------------------------------------------- triggers
B = 'MCI_DATA'
BUSINESS = {
    ('FORM', 'KEY-ENTQRY'): ('PAGE', 'IMPR1170_SEARCH', PS, None, 'MAPPED', 'NIB.KEY_ENTQRY -> page 0 SEARCH'),
    ('FORM', 'KEY-EXEQRY'): ('PAGE', 'IMPR1170_SEARCH', PS, None, 'MAPPED', 'NIB.KEY_EXEQRY -> search grid'),
    ('FORM', 'KEY-DELREC'): ('PROCESS', 'PRE-DELETE', PG, 'IMPR1170.PRE_DELETE', 'MAPPED', 'NIB.KEY_DELREC; block Delete Allowed = false -> refused'),
    ('FORM', 'KEY-F5'): ('PROCESS', 'PRE-INSERT / PRE-UPDATE', PG, 'IMPR1170.PRE_INSERT', 'MAPPED', 'NIB.KEY_F5 (commit) -> page 0 CREATE / SAVE refused'),
    ('FORM', 'KEY-CLRFRM'): ('BUTTON', 'CLEAR (page 0 toolbar)', 0, None, 'MAPPED', 'clear_form + CG$WHEN_NEW_FORM_INSTANCE (list: shared LOV)'),
    ('FORM', 'KEY-CLRBLK'): ('BUTTON', 'CLEAR (page 0 toolbar)', 0, None, 'MAPPED', 'NIB.KEY_CLRBLK'),
    ('FORM', 'KEY-EXIT'): ('BUTTON', 'BACK (page 0 toolbar)', 0, None, 'MAPPED', 'NIB.KEY_EXIT'),
    ('FORM', 'KEY-F9'): ('REGION', 'FUNCS (page 0)', 0, None, 'MAPPED', 'functions menu; ADJ_FUNS is empty'),
    ('FORM', 'ON-POPULATE-DETAILS'): ('REGION', 'MCI_OWNERS (grid query WHERE cr_nbr = :P1170_CR_NBR)', PG, None, 'MAPPED',
                                      'CGBS$.QUERY_DETAILS -> the grid query of the shown master'),
    ('FORM', 'ON-CLEAR-DETAILS'): ('REGION', 'MCI_OWNERS', PG, None, 'MAPPED', 'CGBS$.CLEAR_MASTER_DETAIL -> empty grid without a master'),
    ('FORM', 'WHEN-NEW-FORM-INSTANCE'): ('PROCESS', 'PARAMETERS / HEADER TITLE', PG, None, 'MAPPED',
                                         'NIB frame + CG$WHEN_NEW_FORM_INSTANCE (list, coordination); the globals it clears are unused'),
    (B, 'POST-QUERY'): ('PROCESS', 'POST-QUERY', PG, 'IMPR1170.POST_QUERY', 'MAPPED', 'Before Header after Initialize form (CR_STAT_DESC)'),
    ('MCI_OWNERS', 'POST-QUERY'): ('REGION', 'MCI_OWNERS (outer join MCI_RELATION_TYPES)', PG, None, 'MAPPED',
                                   'RELATION_DESC in the grid query'),
    (B, 'ON-ERROR'): (None, None, None, None, 'DROPPED', 'constraint / privilege messages: the page does no DML on MCI_DATA'),
    ('MCI_OWNERS', 'ON-ERROR'): (None, None, None, None, 'DROPPED', 'coordination / constraint messages: read-only grid'),
    (B + '.CR_NBR', 'KEY-NEXT-ITEM'): ('PROCESS', 'CR_NBR KEY-NEXT-ITEM (+ DA, branch EXECUTE-QUERY)', PG,
                                       'IMPR1170.CR_NBR_KEY_NEXT_ITEM', 'MAPPED', 'cache of today or MCI web service, then the query'),
    (B + '.CR_NBR', 'WHEN-VALIDATE-ITEM'): (None, None, None, None, 'DROPPED', 'NULL;'),
}
for dt in ('CR_ISSUE_DATE', 'CR_EXPIRY_DATE'):
    BUSINESS[(B + '.' + dt, 'WHEN-VALIDATE-ITEM')] = (None, None, None, None, 'DROPPED',
                                                     'Hijri check of an item that is never enterable (display only)')
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
                'screen frame: NIB / TMPLT / CGBS coordination / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS)')
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
                    'Designer "may the LOV be shown" check: the form has no LOV')
            else:
                raise SystemExit('unclassified trigger %s %s' % (full, tn))

# ---------------------------------------------------------------- program units
PUS = {
    'EXECUTE_FUNCTION': ('REGION', 'FUNCS (page 0)', 0, None, 'MAPPED', 'f345 Page Functions (the form has no function of its own)'),
    'MOUSE_CLICK': ('REGION', 'FUNCS (page 0)', 0, None, 'MAPPED', 'function list click'),
    'EXEC_FUNS': (None, None, None, None, 'DROPPED', 'body NULL; (broker-authorization code commented out)'),
    'ADJ_FUNS': (None, None, None, None, 'DROPPED', 'body NULL;'),
    'CG$WHEN_NEW_FORM_INSTANCE': (None, None, None, None, 'DROPPED', 'list -> shared LOV; CGBS coordination -> grid query'),
    'CGDV$POPULATE_DYNAMIC_LISTS': ('LOV', 'LOV_COMM_RGSTRTN_TYPE (IMPR1130)', PG, None, 'MAPPED',
                                    'LOV_APX.REFERENCE_CODES(COMM_RGSTRTN_TYPE) on P1170_CR_TYPE'),
    'CGTE$CHECK_CONSTRAINT_VIO': (None, None, None, None, 'DROPPED', 'MCI_DATA_PK message: the page does not insert'),
    'CGBS$TOGGLE': (None, None, None, None, 'DROPPED', 'Designer block synchronisation (query mode toggle)'),
    'CGBS$SET_QUERY_MODE': (None, None, None, None, 'DROPPED', 'Designer block synchronisation'),
    'CGBS$MESSAGE_QUERY_MODE': (None, None, None, None, 'DROPPED', 'Designer block synchronisation'),
}
for pu in fm.findall(NS + 'ProgramUnit'):
    n = pu.get('Name')
    add('PROGRAM_UNIT', n, *PUS.get(n, (None, None, None, None, 'DROPPED',
                                        'NIB wrapper not called by active code (timers, EDI ticker, window, print)')))

# ---------------------------------------------------------------- relations, record groups, alerts, parameters, canvases, windows, libraries
for b in fm.findall(NS + 'Block'):
    for r in b.findall(NS + 'Relation'):
        add('RELATION', r.get('Name'), 'REGION', 'MCI_OWNERS (WHERE cr_nbr = :P1170_CR_NBR)', PG, None, 'MAPPED',
            'MCI_DATA.CR_NBR = MCI_OWNERS.CR_NBR')
add('RECORD_GROUP', 'CGDV$DLRG (runtime, CR_TYPE)', 'LOV', 'LOV_COMM_RGSTRTN_TYPE (IMPR1130)', PG, None, 'MAPPED', 'CG_REF_CODES COMM_RGSTRTN_TYPE')
for a in fm.findall(NS + 'Alert'):
    n = a.get('Name')
    if n == 'CFG_ERROR':
        add('ALERT', n, 'APP_ITEM', 'page messages (FORMS_APX.FORM_TRIGGER_FAILURE)', None, None, 'MAPPED', 'STR.DISPALERT ERROR of KEY-NEXT-ITEM')
    else:
        add('ALERT', n, None, None, None, None, 'DROPPED', 'OLB alert not referenced by this form')
for p in fm.findall(NS + 'ModuleParameter'):
    n = p.get('Name')
    if n == 'P_MODULE_ID':
        add('PARAMETER', n, 'PAGE_ITEM', 'P1170_MODULE_ID', PG, None, 'MAPPED', 'FORMS_APX.GET_MODULE_ID')
    else:
        add('PARAMETER', n, None, None, None, None, 'DROPPED', 'used only by the OLB frame (EXECUTE_FUNCTION parameter list, print, EDI, timers)')
for c in fm.findall(NS + 'Canvas'):
    n = c.get('Name')
    add('CANVAS', n, *(('PAGE', 'IMPR1170', PG, None, 'MAPPED', 'regions MCI_DATA, MCI_OWNERS') if n == 'CG$PAGE_1'
                       else (None, None, None, None, 'DROPPED', 'OLB frame canvas')))
for w in fm.findall(NS + 'Window'):
    add('WINDOW', w.get('Name'), 'PAGE', 'IMPR1170', PG, None, 'MAPPED', 'one page')
for l in fm.findall(NS + 'AttachedLibrary'):
    n = l.get('Name')
    if n == 'CIC_LIB':
        add('LIBRARY', n, 'PACKAGE', 'FORMS_APX', None, None, 'MAPPED', 'STR -> FORMS_APX, HIJDATE -> FORMS_APX Hijri format, TMPLT -> FUNCS')
    else:
        add('LIBRARY', n, None, None, None, None, 'DROPPED', 'frame / client library (windows, timers, help, DLLs)')
for g in ('ATHRZTN_SEQ_NBR', 'EXEC_QUERY', 'EXEC_QUERY_NOW', 'PORT_CD'):
    add('GLOBAL', g, None, None, None, None, 'DROPPED', 'cleared by WHEN-NEW-FORM-INSTANCE, never read by this form')
add('GLOBAL', 'CG$QUERY_MODE', None, None, None, None, 'DROPPED', 'Designer block synchronisation mode')
for g in ('CG$HP_HFILE', 'CG$HP_HPATH', 'EXIT', 'SYSTEM_OBJ'):
    add('GLOBAL', g, None, None, None, None, 'DROPPED', 'help / frame')
add('EXTERNAL', 'LIB_USR.PRTL_NEBRAS_SERVICES.CALL_WEB_SERVICE', 'PACKAGE', 'IMPR1170.CR_NBR_KEY_NEXT_ITEM', None,
    'IMPR1170.CR_NBR_KEY_NEXT_ITEM', 'MAPPED', 'MCI web service, called unchanged (MISSING SOURCE)')

# ---------------------------------------------------------------- write
cnt = collections.Counter(r[6] for r in rows)
def s(v):
    return 'NULL' if v is None else str(v) if isinstance(v, int) else "'%s'" % str(v).replace("'", "''")
out = ['''-- =============================================================================
-- IMPR1170 - migration registry rows (scripts/create_migration_registry.sql)
-- Purpose : MIG_FORM_REGISTRY row for the form + one MIG_OBJECT_MAP row per Forms object
--           (traceability matrix, analysis/IMPR1170/IMPR1170_apex_page_spec.md section 14)
-- Form    : IMPR1170.fmb (title IMPR1170_CNTRL)
-- Author  : Claude Code
-- Date    : 2026-11-25
-- Version : 1.0 (step 03, package IMPR1170 version 001)
-- Generated by work/IMPR1170/step03/build_trace.py - %d objects: %s.
-- app_id 202530 = the application installed from f345. Re-runnable: deletes the form's rows first.
-- NOT executed (CLAUDE.md 6.10).
-- =============================================================================
SET DEFINE OFF

DELETE FROM mig_object_map    WHERE form_name = 'IMPR1170';
DELETE FROM mig_form_registry WHERE form_name = 'IMPR1170';

INSERT INTO mig_form_registry
    (form_name, forms_app, subsystem, app_id, page_from, page_to, page_alias,
     package_name, complexity, status, owner, business_owner, notes)
VALUES
    ('IMPR1170', 'IMPR', 'IMPR', 202530, 1170, 1170, 'IMPR1170',
     'IMPR1170', 'COMPLEX', 'DESIGN', NULL, NULL,
     'بيانات السجل التجارى من وزارة التجارة (IMPR1170_CNTRL) - pages 1170, 117001; package IMPR1170 001 not compiled; web service LIB_USR.PRTL_NEBRAS_SERVICES missing source; business logic simple');

DECLARE
    PROCEDURE m (p_type    VARCHAR2, p_name   VARCHAR2, p_comp  VARCHAR2, p_comp_name VARCHAR2,
                 p_page    NUMBER,   p_member VARCHAR2, p_status VARCHAR2, p_notes   VARCHAR2)
    IS
    BEGIN
        INSERT INTO mig_object_map
            (form_name, forms_object_type, forms_object_name, apex_comp_type,
             apex_comp_name, page_id, plsql_member, status, notes)
        VALUES ('IMPR1170', p_type, p_name, p_comp, p_comp_name, p_page, p_member, p_status, p_notes);
    END m;
BEGIN''' % (len(rows), ', '.join('%s %d' % kv for kv in sorted(cnt.items())))]
for r in rows:
    out.append('    m(%s);' % ', '.join(s(v) for v in r))
out.append('END;\n/\n\nCOMMIT;\n')
open(os.path.join(ROOT, 'registry', 'IMPR1170_registry.sql'), 'w', encoding='utf-8', newline='\n').write('\n'.join(out))
md = ['| # | Type | Forms object | APEX component | Page | Package member | Status | Notes |', '|---|---|---|---|---|---|---|---|']
for i, r in enumerate(rows, 1):
    md.append('| %d | %s |' % (i, ' | '.join(('`%s`' % r[1]) if j == 1 else ('-' if v is None else str(v).replace('|', '\\|'))
                                             for j, v in enumerate(r))))
open(os.path.join(ROOT, 'work', 'IMPR1170', 'step03', 'trace.md'), 'w', encoding='utf-8').write(
    '%d objects: %s.\n\n' % (len(rows), ', '.join('%s %d' % kv for kv in sorted(cnt.items()))) + '\n'.join(md) + '\n')
print(len(rows), dict(cnt))
