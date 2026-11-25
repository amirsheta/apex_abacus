# -*- coding: utf-8 -*-
"""
build_trace.py - IMPR1160 traceability: every Forms object of forms/IMPR/IMPR1160_fmb.xml -> APEX target or rationale.
Writes registry/IMPR1160_registry.sql and work/IMPR1160/step03/trace.md (section 14 of the page spec).
Usage (from forms_to_apex_toolkit): python3 -I work/IMPR1160/step03/build_trace.py
"""
import os, collections
import xml.etree.ElementTree as ET

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
XML = os.path.join(ROOT, 'forms', 'IMPR', 'IMPR1160_fmb.xml')
NS = '{http://xmlns.oracle.com/Forms}'
fm = ET.parse(XML).getroot().find(NS + 'FormModule')
PG = 1160
FRAME = ('TITLE', 'EDI_MSG', 'LSIDE', 'TOOLBAR')
rows = []

def add(t, name, comp=None, comp_name=None, page=None, member=None, status='MAPPED', notes=''):
    rows.append((t, name, comp, comp_name, page, member, status, notes))

# ---------------------------------------------------------------- blocks
BLOCKS = {
    'TITLE': ('REGION', 'IMPR_CAR_EXCEPTION_HERO', PG, None, 'MAPPED', 'OLB title bar -> f345 hero region (FORMS_APX.HEADER_TITLE)'),
    'EDI_MSG': (None, None, None, None, 'DROPPED', 'OLB EDI message ticker - dropped (timers, IMPR1110 decision 2026-11-19)'),
    'LSIDE': ('REGION', 'FUNCS (page 0 drawer)', 0, None, 'MAPPED', 'OLB side function menu -> page 0 FUNCS, f345 list Page Functions'),
    'TOOLBAR': ('REGION', 'P0_ACTIONS (page 0 toolbar, f345)', 0, None, 'MAPPED', 'OLB toolbar -> f345 page 0 toolbar'),
    'IMPR_CAR_EXCEPTION': ('REGION', 'IMPR_CAR_EXCEPTION (Form, i:u:d, key ROWID)', PG, None, 'MAPPED',
                           'PRE-QUERY MAKE_BLOCK_FULL_OPERATION(TRUE, TRUE, TRUE): queried record STATUS update + delete'),
}
for b in fm.findall(NS + 'Block'):
    add('BLOCK', b.get('Name'), *BLOCKS[b.get('Name')])

# ---------------------------------------------------------------- items
DROPPED_ITEMS = {
    'PORT_CD2': 'LOV button of PORT_CD, an item that is never enterable',
    'IMPR_BUT': 'LOV button -> the Popup LOV button of P1160_IMPR_NBR',
    'DCLTN_LOV': 'LOV button -> the Popup LOV button of P1160_DCLTN_NBR',
}
HIDDEN = ('ENTRY_DT', 'DCLTN_ISN', 'STATS_ISN', 'EXPTN_START_DT', 'EXPTN_END_DT')
for b in fm.findall(NS + 'Block'):
    bn = b.get('Name')
    for it in b.findall(NS + 'Item'):
        n = it.get('Name')
        full = '%s.%s' % (bn, n)
        if bn in FRAME:
            add('ITEM', full, None, None, None, None, 'DROPPED', 'OLB frame item -> f345 page template / page 0 toolbar / FUNCS')
        elif n in DROPPED_ITEMS:
            add('ITEM', full, None, None, None, None, 'DROPPED', DROPPED_ITEMS[n])
        else:
            add('ITEM', full, 'PAGE_ITEM', 'P1160_' + n, PG, None, 'MAPPED', 'not displayed' if n in HIDDEN else 'spec section 4')

# ---------------------------------------------------------------- triggers
B = 'IMPR_CAR_EXCEPTION'
BUSINESS = {
    ('FORM', 'WHEN-NEW-FORM-INSTANCE'): ('PROCESS', 'WHEN-NEW-FORM-INSTANCE', PG, 'IMPR1160.WHEN_NEW_FORM_INSTANCE', 'MAPPED',
                                         'defaults of a new record (PORT_CD, PORT_NAME, EXPTN_START_DT); NIB / versions dropped'),
    ('FORM', 'KEY-ENTQRY'): ('PAGE', 'IMPR1160_SEARCH', 116001, None, 'MAPPED', 'NIB.KEY_ENTQRY -> page 0 SEARCH'),
    ('FORM', 'KEY-EXEQRY'): ('PAGE', 'IMPR1160_SEARCH', 116001, None, 'MAPPED', 'NIB.KEY_EXEQRY -> search grid'),
    ('FORM', 'KEY-DELREC'): ('PROCESS', 'Process form - DELETE', PG, None, 'MAPPED', 'NIB.KEY_DELREC (confirmation) -> page 0 DELETE'),
    ('FORM', 'KEY-F5'): ('PROCESS', 'Process form', PG, None, 'MAPPED', 'NIB.KEY_F5 (commit) -> page 0 CREATE / SAVE'),
    ('FORM', 'KEY-CLRFRM'): ('BUTTON', 'CLEAR (page 0 toolbar)', 0, None, 'MAPPED', 'clear_form + CG$WHEN_NEW_FORM_INSTANCE (lists: shared LOVs)'),
    ('FORM', 'KEY-CLRBLK'): ('BUTTON', 'CLEAR (page 0 toolbar)', 0, None, 'MAPPED', 'NIB.KEY_CLRBLK'),
    ('FORM', 'KEY-EXIT'): ('BUTTON', 'BACK (page 0 toolbar)', 0, None, 'MAPPED', 'NIB.KEY_EXIT'),
    ('FORM', 'KEY-F9'): ('REGION', 'FUNCS (page 0)', 0, None, 'MAPPED', 'functions menu; ADJ_FUNS is empty'),
    (B, 'POST-QUERY'): ('PROCESS', 'POST-QUERY', PG, 'IMPR1160.POST_QUERY', 'MAPPED', 'Before Header after Initialize form; STATUS enterable'),
    (B, 'PRE-QUERY'): ('REGION', 'IMPR_CAR_EXCEPTION (i:u:d, STATUS enterable)', PG, None, 'MAPPED',
                       'MAKE_BLOCK_FULL_OPERATION + SET_ITEM_PROPERTY STATUS -> region edit operations / read-only rules'),
    (B, 'PRE-INSERT'): ('PROCESS', 'PRE-INSERT', PG, 'IMPR1160.PRE_INSERT', 'MAPPED', 'sequence, entry date, declaration ISN, duplicate check'),
    (B, 'PRE-UPDATE'): ('PROCESS', 'PRE-UPDATE', PG, 'IMPR1160.PRE_UPDATE', 'MAPPED', 'inactive exception cannot be changed'),
    (B, 'ON-ERROR'): ('TEXT_MESSAGE', 'ICE_PK, ICE_SD_FK, ICE_SDP_FK, ICE_IMP_FK, ICE_DCLTN_FK', None, None, 'MAPPED',
                      'constraint texts via the APEX error handler (FORMS_APX.apex_error_handler); ORA-01031 texts dropped'),
    (B, 'KEY-DUPREC'): (None, None, None, None, 'DROPPED', 'duplicate record (keep the UID) - no duplicate record in APEX'),
    (B + '.IMPR_NBR', 'WHEN-VALIDATE-ITEM'): ('VALIDATION', 'IMPR_NBR VALIDATION', PG, 'IMPR1160.IMPR_NBR_VALIDATION', 'MAPPED',
                                              'the Forms IF never raises; the validation runs the KEY-NEXT-ITEM check (spec 7)'),
    (B + '.IMPR_NBR', 'KEY-NEXT-ITEM'): ('DA', 'IMPR_NBR KEY-NEXT-ITEM', PG, 'IMPR1160.IMPR_NBR_KEY_NEXT_ITEM', 'MAPPED',
                                         'importer name, suspension check, Set Focus DCLTN_TYPE'),
    (B + '.IMPR_NBR', 'KEY-LISTVAL'): ('LOV', 'LOV_IMPR_P (Popup LOV)', PG, None, 'MAPPED', 'CALL_IMPR_LOV -> LOV form LOV_IMPR_P'),
    (B + '.IMPR_BUT', 'WHEN-BUTTON-PRESSED'): ('LOV', 'LOV_IMPR_P (Popup LOV button)', PG, None, 'MAPPED', 'go_item + do_key(List_values)'),
    (B + '.DCLTN_NBR', 'KEY-LISTVAL'): ('LOV', 'LOV_IMPR_DCLTN (Popup LOV)', PG, None, 'MAPPED', 'CALL_IMPR_DCLTN_LOV -> LOV form LOV_IMPR_DCLTN'),
    (B + '.DCLTN_NBR', 'POST-CHANGE'): ('DA', 'DCLTN_NBR POST-CHANGE', PG, 'IMPR1160.DCLTN_NBR_POST_CHANGE', 'MAPPED',
                                        'declaration ISN, date, number of cars'),
    (B + '.DCLTN_LOV', 'WHEN-BUTTON-PRESSED'): ('LOV', 'LOV_IMPR_DCLTN (Popup LOV button)', PG, None, 'MAPPED', 'go_item + do_key(List_values)'),
    (B + '.DCLTN_DT', 'KEY-NEXT-ITEM'): (None, None, None, None, 'DROPPED', 'NULL; (code commented out in Forms)'),
    (B + '.DCLTN_DT', 'WHEN-VALIDATE-ITEM'): (None, None, None, None, 'DROPPED', 'NULL; (code commented out in Forms)'),
    (B + '.AWARD_NBR', 'WHEN-VALIDATE-ITEM'): ('VALIDATION', 'AWARD_NBR VALIDATION + DA AWARD_NBR WHEN-VALIDATE-ITEM', PG,
                                               'IMPR1160.AWARD_NBR_VALIDATION', 'MAPPED', 'number <= 0 refused'),
    (B + '.AWARD_DATE', 'WHEN-VALIDATE-ITEM'): ('VALIDATION', 'AWARD_DATE VALIDATION + DA AWARD_DATE WHEN-VALIDATE-ITEM', PG,
                                                'FORMS_APX.HIJRI_DATE_ERROR', 'MAPPED', 'HIJDATE.VALID_HIJ_DATE'),
    (B + '.AWARD_DATE', 'KEY-F4'): ('PAGE_ITEM', 'P1160_AWARD_DATE (hijri-date-default)', PG, None, 'MAPPED', 'Hijri date picker (f345 app-wide)'),
    (B + '.AWARD_DATE', 'KEY-LISTVAL'): ('PAGE_ITEM', 'P1160_AWARD_DATE (hijri-date-default)', PG, None, 'MAPPED', 'Hijri calendar (f345 app-wide)'),
    (B + '.NO_OF_CARS', 'WHEN-VALIDATE-ITEM'): ('VALIDATION', 'NO_OF_CARS VALIDATION + DA NO_OF_CARS WHEN-VALIDATE-ITEM', PG,
                                                'IMPR1160.NO_OF_CARS_VALIDATION', 'MAPPED', 'number <= 0 refused'),
}
for dt in ('EXPTN_START_DT', 'EXPTN_END_DT'):
    for tn in ('WHEN-VALIDATE-ITEM', 'KEY-F4', 'KEY-LISTVAL'):
        BUSINESS[(B + '.' + dt, tn)] = (None, None, None, None, 'DROPPED', 'item not displayed (Visible = false): the trigger cannot fire')
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
            elif tn == 'WHEN-BUTTON-PRESSED' and it.get('Name') == 'PORT_CD2':
                add('TRIGGER', '%s.%s' % (full, tn), None, None, None, None, 'DROPPED', 'LOV of PORT_CD, never enterable')
            else:
                raise SystemExit('unclassified trigger %s %s' % (full, tn))

# ---------------------------------------------------------------- program units
PUS = {
    'EXECUTE_FUNCTION': ('REGION', 'FUNCS (page 0)', 0, None, 'MAPPED', 'f345 Page Functions (the form has no function of its own)'),
    'MOUSE_CLICK': ('REGION', 'FUNCS (page 0)', 0, None, 'MAPPED', 'function list click'),
    'EXEC_FUNS': (None, None, None, None, 'DROPPED', 'body NULL;'),
    'ADJ_FUNS': (None, None, None, None, 'DROPPED', 'body NULL;'),
    'POPULATE_DYNAMIC_LISTS': (None, None, None, None, 'DROPPED', 'body NULL; (code commented out)'),
    'DEV_VERSIONS': (None, None, None, None, 'DROPPED', 'version comment only'),
    'CG$WHEN_NEW_FORM_INSTANCE': (None, None, None, None, 'DROPPED', 'lists -> shared LOVs'),
    'CGDV$POPULATE_DYNAMIC_LISTS': ('LOV', 'LOV_DCL_STA_FLAG, LOV_REC_STATUS', PG, None, 'MAPPED',
                                    'LOV_APX.REFERENCE_CODES(DCL_STA_FLAG / REC_STATUS)'),
    'CGUI$GET_NEXT_IMPR_CAR_EXPTN_S': (None, None, None, None, 'DROPPED', 'not called (same code as GET_NEXT_IMPR_CAR_EXPTN_CNTRL)'),
    'GET_NEXT_IMPR_CAR_EXPTN_CNTRL': ('PROCESS', 'PRE-INSERT', PG, 'IMPR1160.GET_NEXT_IMPR_CAR_EXPTN_CNTRL', 'MAPPED', 'central sequence'),
    'CGTE$CHECK_CONSTRAINT_VIO': ('TEXT_MESSAGE', 'ICE_PK', None, None, 'MAPPED', 'APEX error handler; other tables\' constraints cannot occur'),
    'CALL_IMPR_LOV': ('LOV', 'LOV_IMPR_P', PG, None, 'MAPPED', 'LOV_APX.IMPORTERS (type 4, business id type 5) + DA IMPR_NBR KEY-NEXT-ITEM'),
    'CALL_IMPR_DCLTN_LOV': ('LOV', 'LOV_IMPR_DCLTN', PG, None, 'MAPPED', 'LOV_APX.LOV_IMPR_DCLTN + DA DCLTN_NBR POST-CHANGE'),
}
for pu in fm.findall(NS + 'ProgramUnit'):
    n = pu.get('Name')
    add('PROGRAM_UNIT', n, *PUS.get(n, (None, None, None, None, 'DROPPED',
                                        'NIB wrapper not called by active code (timers, EDI ticker, window, print)')))

# ---------------------------------------------------------------- LOVs, record groups, alerts, parameters, canvases, windows, libraries
for l in fm.findall(NS + 'LOV'):
    add('LOV', l.get('Name'), None, None, None, None, 'DROPPED', 'LOV of PORT_CD (ports from DECLARATIONS): PORT_CD is never enterable')
for g in fm.findall(NS + 'RecordGroup'):
    add('RECORD_GROUP', g.get('Name'), None, None, None, None, 'DROPPED', 'record group of the dropped PORT_CD LOV')
add('RECORD_GROUP', 'CGDV$DLRG (runtime, DCLTN_TYPE)', 'LOV', 'LOV_DCL_STA_FLAG', PG, None, 'MAPPED', 'CG_REF_CODES DCL_STA_FLAG')
add('RECORD_GROUP', 'CGDV$DLRG (runtime, STATUS)', 'LOV', 'LOV_REC_STATUS (IMPR1140)', PG, None, 'MAPPED', 'CG_REF_CODES REC_STATUS')
add('CALLED_FORM', 'LOV_IMPR_P', 'LOV', 'LOV_IMPR_P', PG, None, 'MAPPED', 'Popup LOV of P1160_IMPR_NBR')
add('CALLED_FORM', 'LOV_IMPR_DCLTN', 'LOV', 'LOV_IMPR_DCLTN', PG, None, 'MAPPED', 'Popup LOV of P1160_DCLTN_NBR')
for a in fm.findall(NS + 'Alert'):
    n = a.get('Name')
    if n in ('CFG_ERROR', 'CFG_INFORMATION'):
        add('ALERT', n, 'APP_ITEM', 'page messages (FORMS_APX.FORM_TRIGGER_FAILURE)', None, None, 'MAPPED', 'STR.DISPALERT')
    else:
        add('ALERT', n, None, None, None, None, 'DROPPED', 'OLB alert not referenced by this form')
for p in fm.findall(NS + 'ModuleParameter'):
    n = p.get('Name')
    if n == 'P_CURR_PORT_CD':
        add('PARAMETER', n, 'APP_ITEM', 'P_CURR_PORT_CD (f345)', None, None, 'MAPPED', 'port of the new record and of the look-ups')
    elif n == 'P_MODULE_ID':
        add('PARAMETER', n, 'PAGE_ITEM', 'P1160_MODULE_ID', PG, None, 'MAPPED', 'FORMS_APX.GET_MODULE_ID')
    else:
        add('PARAMETER', n, None, None, None, None, 'DROPPED', 'used only by the OLB frame (EXECUTE_FUNCTION parameter list, print, EDI)')
for c in fm.findall(NS + 'Canvas'):
    n = c.get('Name')
    add('CANVAS', n, *(('PAGE', 'IMPR1160', PG, None, 'MAPPED', 'region IMPR_CAR_EXCEPTION') if n == 'CG$PAGE_1'
                       else (None, None, None, None, 'DROPPED', 'OLB frame canvas')))
for w in fm.findall(NS + 'Window'):
    add('WINDOW', w.get('Name'), 'PAGE', 'IMPR1160', PG, None, 'MAPPED', 'one page')
for l in fm.findall(NS + 'AttachedLibrary'):
    n = l.get('Name')
    if n == 'CIC_LIB':
        add('LIBRARY', n, 'PACKAGE', 'FORMS_APX', None, None, 'MAPPED', 'STR -> FORMS_APX, HIJDATE -> FORMS_APX Hijri helpers, TMPLT -> FUNCS')
    else:
        add('LIBRARY', n, None, None, None, None, 'DROPPED', 'frame / client library (windows, timers, help, DLLs)')
add('GLOBAL', 'IMPR_NBR', 'LOV', 'LOV_IMPR_P', PG, None, 'MAPPED', 'value returned by the LOV form -> Popup LOV return value')
add('GLOBAL', 'DCLTN_NBR', 'LOV', 'LOV_IMPR_DCLTN', PG, None, 'MAPPED', 'value returned by the LOV form -> Popup LOV return value')
add('GLOBAL', 'DCLTN_DT', 'DA', 'DCLTN_NBR POST-CHANGE', PG, 'IMPR1160.DCLTN_NBR_POST_CHANGE', 'MAPPED', 'date re-read from the declaration')
for g in ('CG$HP_HFILE', 'CG$HP_HPATH', 'CG$TEMP_0', 'CURRENT_DT', 'CURRENT_VER', 'CURRENT_VERSION', 'EXIT', 'SYSTEM_OBJ'):
    add('GLOBAL', g, None, None, None, None, 'DROPPED', 'help / screen version / duplicate record / frame')

# ---------------------------------------------------------------- write
cnt = collections.Counter(r[6] for r in rows)
def s(v):
    return 'NULL' if v is None else str(v) if isinstance(v, int) else "'%s'" % str(v).replace("'", "''")
out = ['''-- =============================================================================
-- IMPR1160 - migration registry rows (scripts/create_migration_registry.sql)
-- Purpose : MIG_FORM_REGISTRY row for the form + one MIG_OBJECT_MAP row per Forms object
--           (traceability matrix, analysis/IMPR1160/IMPR1160_apex_page_spec.md section 14)
-- Form    : IMPR1160.fmb (title IMPR1160_ND_CNTRL)
-- Author  : Claude Code
-- Date    : 2026-11-25
-- Version : 1.0 (step 03, package IMPR1160 version 001)
-- Generated by work/IMPR1160/step03/build_trace.py - %d objects: %s.
-- app_id 202530 = the application installed from f345. Re-runnable: deletes the form's rows first.
-- NOT executed (CLAUDE.md 6.10).
-- =============================================================================
SET DEFINE OFF

DELETE FROM mig_object_map    WHERE form_name = 'IMPR1160';
DELETE FROM mig_form_registry WHERE form_name = 'IMPR1160';

INSERT INTO mig_form_registry
    (form_name, forms_app, subsystem, app_id, page_from, page_to, page_alias,
     package_name, complexity, status, owner, business_owner, notes)
VALUES
    ('IMPR1160', 'IMPR', 'IMPR', 202530, 1160, 1160, 'IMPR1160',
     'IMPR1160', 'COMPLEX', 'DESIGN', NULL, NULL,
     'استثناء المستوردين الافراد للسيارات (IMPR1160_ND_CNTRL) - pages 1160, 116001; package IMPR1160 001 and LOV_APX 004 not compiled; business logic simple');

DECLARE
    PROCEDURE m (p_type    VARCHAR2, p_name   VARCHAR2, p_comp  VARCHAR2, p_comp_name VARCHAR2,
                 p_page    NUMBER,   p_member VARCHAR2, p_status VARCHAR2, p_notes   VARCHAR2)
    IS
    BEGIN
        INSERT INTO mig_object_map
            (form_name, forms_object_type, forms_object_name, apex_comp_type,
             apex_comp_name, page_id, plsql_member, status, notes)
        VALUES ('IMPR1160', p_type, p_name, p_comp, p_comp_name, p_page, p_member, p_status, p_notes);
    END m;
BEGIN''' % (len(rows), ', '.join('%s %d' % kv for kv in sorted(cnt.items())))]
for r in rows:
    out.append('    m(%s);' % ', '.join(s(v) for v in r))
out.append('END;\n/\n\nCOMMIT;\n')
open(os.path.join(ROOT, 'registry', 'IMPR1160_registry.sql'), 'w', encoding='utf-8', newline='\n').write('\n'.join(out))
md = ['| # | Type | Forms object | APEX component | Page | Package member | Status | Notes |', '|---|---|---|---|---|---|---|---|']
for i, r in enumerate(rows, 1):
    md.append('| %d | %s |' % (i, ' | '.join(('`%s`' % r[1]) if j == 1 else ('-' if v is None else str(v).replace('|', '\\|'))
                                             for j, v in enumerate(r))))
open(os.path.join(ROOT, 'work', 'IMPR1160', 'step03', 'trace.md'), 'w', encoding='utf-8').write(
    '%d objects: %s.\n\n' % (len(rows), ', '.join('%s %d' % kv for kv in sorted(cnt.items()))) + '\n'.join(md) + '\n')
print(len(rows), dict(cnt))
