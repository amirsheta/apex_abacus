# -*- coding: utf-8 -*-
"""
build_trace.py - IMPR1210 traceability: every Forms object of forms/IMPR/IMPR1210_fmb.xml -> APEX target or rationale.
Writes registry/IMPR1210_registry.sql and work/IMPR1210/step03/trace.md (section 14 of the page spec).
Usage (from forms_to_apex_toolkit): python3 -I work/IMPR1210/step03/build_trace.py
"""
import os, collections
import xml.etree.ElementTree as ET

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
XML = os.path.join(ROOT, 'forms', 'IMPR', 'IMPR1210_fmb.xml')
NS = '{http://xmlns.oracle.com/Forms}'
fm = ET.parse(XML).getroot().find(NS + 'FormModule')
PG, PS = 1210, 121001
FRAME = ('TITLE', 'EDI_MSG', 'LSIDE', 'TOOLBAR')
rows = []

def add(t, name, comp=None, comp_name=None, page=None, member=None, status='MAPPED', notes=''):
    rows.append((t, name, comp, comp_name, page, member, status, notes))

# ---------------------------------------------------------------- blocks
BLOCKS = {
    'TITLE': ('REGION', 'AGNTS_HERO', PG, None, 'MAPPED', 'OLB title bar -> f345 hero region (FORMS_APX.HEADER_TITLE)'),
    'EDI_MSG': (None, None, None, None, 'DROPPED', 'OLB EDI message ticker - dropped (timers, IMPR1110 decision 2026-11-19)'),
    'LSIDE': ('REGION', 'FUNCS (page 0 drawer)', 0, None, 'MAPPED', 'OLB side function menu -> page 0 FUNCS, f345 list Page Functions'),
    'TOOLBAR': ('REGION', 'P0_ACTIONS (page 0 toolbar, f345)', 0, None, 'MAPPED', 'OLB toolbar -> f345 page 0 toolbar'),
    'AGNTS': ('REGION', 'AGNTS (Form, key ROWID, i:u)', PG, None, 'MAPPED',
              'single record, WHERE PORT_CD = P_CURR_PORT_CD; update rule AGNTS_IS_READ_ONLY; no delete'),
    'CGNV$CGSO$WINDOW_1_1': ('BUTTON', 'IMP_NEW', PG, None, 'MAPPED', 'Designer action-item block -> page button IMP_NEW'),
}
for b in fm.findall(NS + 'Block'):
    add('BLOCK', b.get('Name'), *BLOCKS[b.get('Name')])

# ---------------------------------------------------------------- items
ITEM_DROP = {
    'AGNTS.PORT_CD2': 'LOV button of PORT_CD: the item is never enterable',
    'AGNTS.IMP_LOV': 'LOV button of IMPR_NBR -> Popup LOV button of P1210_IMPR_NBR',
    'AGNTS.AGNT_LOV': 'LOV button of IMPR_NBR_AG -> Popup LOV button of P1210_IMPR_NBR_AG',
    'AGNTS.SDP_PORT_STATUS': 'not displayed, never read (CGFK$QRY_AGNTS_AG_SDP_FK output)',
}
for b in fm.findall(NS + 'Block'):
    bn = b.get('Name')
    for it in b.findall(NS + 'Item'):
        n = it.get('Name')
        full = '%s.%s' % (bn, n)
        if bn in FRAME:
            add('ITEM', full, None, None, None, None, 'DROPPED', 'OLB frame item -> f345 page template / page 0 toolbar / FUNCS')
        elif full in ITEM_DROP:
            add('ITEM', full, None, None, None, None, 'DROPPED', ITEM_DROP[full])
        elif bn == 'CGNV$CGSO$WINDOW_1_1':
            add('ITEM', full, 'BUTTON', 'IMP_NEW', PG, None, 'MAPPED', 'redirect to page 1130 (to confirm, inventory 15 #5)')
        else:
            add('ITEM', full, 'PAGE_ITEM', 'P1210_' + n, PG, None, 'MAPPED', 'spec section 4')

# ---------------------------------------------------------------- triggers
B = 'AGNTS'
BUSINESS = {
    ('FORM', 'KEY-ENTQRY'): ('PAGE', 'IMPR1210_SEARCH', PS, None, 'MAPPED', 'NIB.KEY_ENTQRY -> page 0 SEARCH'),
    ('FORM', 'KEY-EXEQRY'): ('PAGE', 'IMPR1210_SEARCH', PS, None, 'MAPPED', 'NIB.KEY_EXEQRY -> search grid'),
    ('FORM', 'KEY-DELREC'): ('PROCESS', 'PRE-DELETE', PG, 'IMPR1210.PRE_DELETE', 'MAPPED', 'NIB.KEY_DELREC; queried records never deletable -> refused'),
    ('FORM', 'KEY-F5'): ('PROCESS', 'Process form', PG, None, 'MAPPED', 'NIB.KEY_F5 (commit) -> page 0 CREATE / SAVE'),
    ('FORM', 'KEY-CLRFRM'): ('BUTTON', 'CLEAR (page 0 toolbar)', 0, None, 'MAPPED', 'clear_form + CG$WHEN_NEW_FORM_INSTANCE (lists: shared LOV)'),
    ('FORM', 'KEY-CLRBLK'): ('BUTTON', 'CLEAR (page 0 toolbar)', 0, None, 'MAPPED', 'NIB.KEY_CLRBLK'),
    ('FORM', 'KEY-EXIT'): ('BUTTON', 'BACK (page 0 toolbar)', 0, None, 'MAPPED', 'NIB.KEY_EXIT'),
    ('FORM', 'KEY-F9'): ('REGION', 'FUNCS (page 0)', 0, None, 'MAPPED', 'functions menu (CD1_STOPIMPRAUTH, CD2_REUSEIMPRAUTH)'),
    ('FORM', 'WHEN-NEW-FORM-INSTANCE'): ('PROCESS', 'PARAMETERS / HEADER TITLE', PG, None, 'MAPPED',
                                         'NIB frame + CG$WHEN_NEW_FORM_INSTANCE (lists); globals it clears are unused'),
    ('FORM', 'PRE-FORM'): (None, None, None, None, 'DROPPED', 'NIB.PRE_FORM, version globals (CR-5537), NLS date format, help globals'),
    (B, 'PRE-QUERY'): ('PROCESS', 'EXECUTE-QUERY', PG, 'IMPR1210.PRE_QUERY', 'MAPPED', 'globals of ATHRZTN_SEQ_NBR -> request EXECUTE_QUERY'),
    (B, 'POST-QUERY'): ('PROCESS', 'POST-QUERY', PG, 'IMPR1210.POST_QUERY', 'MAPPED', 'Before Header after Initialize form'),
    (B, 'PRE-INSERT'): ('PROCESS', 'PRE-INSERT', PG, 'IMPR1210.PRE_INSERT', 'MAPPED', 'MAX + 1, status 1, Hijri date, activity 1'),
    (B, 'PRE-UPDATE'): ('PROCESS', 'PRE-UPDATE', PG, 'IMPR1210.PRE_UPDATE', 'MAPPED', 'update rule + activity 2'),
    (B, 'WHEN-CREATE-RECORD'): ('PROCESS', 'WHEN-CREATE-RECORD', PG, 'IMPR1210.WHEN_CREATE_RECORD', 'MAPPED', 'PORT_CD, PORT_NAME'),
    (B, 'WHEN-NEW-RECORD-INSTANCE'): ('PROCESS', 'WHEN-NEW-RECORD-INSTANCE', PG, 'IMPR1210.WHEN_NEW_RECORD_INSTANCE', 'MAPPED',
                                      'UPDATE_STATUS; MAKE_BLOCK_FULL_OPERATION -> AGNTS_IS_READ_ONLY (item conditions)'),
    (B, 'ON-ERROR'): ('MESSAGE', 'AG_PK, AG_SDP_FK, AG_IMP_FK, AG_IMP_AGENT_ID_FK', None, None, 'MAPPED',
                      'constraint texts -> Text Messages (FORMS_APX.apex_error_handler); ORA-01031 texts dropped'),
    (B + '.ATHRZTN_SEQ_NBR', 'WHEN-VALIDATE-ITEM'): ('VALIDATION', 'ATHRZTN_SEQ_NBR VALIDATION + DA ATHRZTN_SEQ_NBR WHEN-VALIDATE-ITEM',
                                                     PG, 'IMPR1210.ATHRZTN_SEQ_NBR_VALIDATION', 'MAPPED', 'message 9-40, then EXECUTE_QUERY'),
    (B + '.IMPR_NBR', 'WHEN-VALIDATE-ITEM'): ('VALIDATION', 'IMPR_NBR VALIDATION + DA IMPR_NBR WHEN-VALIDATE-ITEM', PG,
                                              'IMPR1210.IMPR_NBR_WHEN_VALIDATE_ITEM', 'MAPPED',
                                              '9-20 / 9-70 / 9-10; CALL_FORM LOV_AGNT_ATHR_IMPR -> grid LOV_AGNT_ATHR_IMPR'),
    (B + '.IMPR_NBR', 'KEY-LISTVAL'): ('LOV', 'LOV_IMPR (IMPR1110)', PG, None, 'MAPPED', 'CALL_FORM LOV_IMPR -> Popup LOV'),
    (B + '.IMPR_NBR', 'WHEN-NEW-ITEM-INSTANCE'): ('BRANCH', 'IMPR1210 - stay in the form', PG, None, 'MAPPED',
                                                  'EXEC_QUERY_NOW -> CLEAR_BLOCK + EXECUTE_QUERY = page reload with P0_PAGE_PK'),
    (B + '.IMP_LOV', 'WHEN-BUTTON-PRESSED'): ('LOV', 'LOV_IMPR (Popup LOV button)', PG, None, 'MAPPED', 'GO_ITEM + LIST_VALUES'),
    (B + '.IMPR_NBR_AG', 'WHEN-VALIDATE-ITEM'): ('VALIDATION', 'IMPR_NBR_AG VALIDATION + DA IMPR_NBR_AG WHEN-VALIDATE-ITEM', PG,
                                                 'IMPR1210.IMPR_NBR_AG_WHEN_VALIDATE_ITEM', 'MAPPED', '9-20 / 9-70 / 9-10'),
    (B + '.IMPR_NBR_AG', 'KEY-LISTVAL'): ('LOV', 'LOV_IMPR (IMPR1110)', PG, None, 'MAPPED', 'CALL_FORM LOV_IMPR -> Popup LOV'),
    (B + '.IMPR_NBR_AG', 'WHEN-NEW-ITEM-INSTANCE'): (None, None, None, None, 'DROPPED',
                                                     ':GLOBAL.EXEC_QUERY only set after LOV_AGNT_ATHR_IMPR (inventory 14 #4)'),
    (B + '.AGNT_LOV', 'WHEN-BUTTON-PRESSED'): ('LOV', 'LOV_IMPR (Popup LOV button)', PG, None, 'MAPPED', 'GO_ITEM + LIST_VALUES'),
    (B + '.PORT_CD', 'KEY-LISTVAL'): (None, None, None, None, 'DROPPED', 'CALL_FORM LOV_SD_PORTS on an item that is never enterable'),
    (B + '.PORT_CD2', 'WHEN-BUTTON-PRESSED'): (None, None, None, None, 'DROPPED', 'LOV button of a non-enterable item'),
    ('CGNV$CGSO$WINDOW_1_1.CGSO$WINDOW_1_IMP_NEW', 'WHEN-BUTTON-PRESSED'): ('BUTTON', 'IMP_NEW', PG, None, 'MAPPED',
                                                                            'OPEN_FORM IMP_NEW -> page 1130 (to confirm)'),
}
for dt in ('ATHRZTN_CRET_DT', 'ATHRZTN_CNCLD_DT'):
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
                    'Designer "may the LOV be shown" check of an item without LOV')
            else:
                raise SystemExit('unclassified trigger %s %s' % (full, tn))

# ---------------------------------------------------------------- program units
PUS = {
    'EXECUTE_FUNCTION': ('REGION', 'FUNCS (page 0)', 0, None, 'MAPPED', 'f345 Page Functions -> custom events of the two functions'),
    'MOUSE_CLICK': ('REGION', 'FUNCS (page 0)', 0, None, 'MAPPED', 'function list click'),
    'EXEC_FUNS': ('PROCESS', 'CD1_STOPIMPRAUTH / CD2_REUSEIMPRAUTH EXECUTE-FUNCTION', PG, 'IMPR1210.EXEC_FUNS', 'MAPPED',
                  'confirmations = DA Confirm; UPDATE + activity 3 / 4 + COMMIT'),
    'ADJ_FUNS': (None, None, None, None, 'DROPPED', 'body NULL;'),
    'CHECK_SUSPENSION': ('PACKAGE', 'IMPR1210 private importer_suspended', None, 'IMPR1210.IMPR_NBR_VALIDATION', 'MAPPED',
                         'LIB_USR.IMPR.IMPR_SUSPENDED (MISSING SOURCE) -> message 9-70'),
    'CG$WHEN_NEW_FORM_INSTANCE': (None, None, None, None, 'DROPPED', 'lists -> shared LOV'),
    'CGDV$POPULATE_DYNAMIC_LISTS': ('LOV', 'LOV_ALLOWED_EXPORT (IMPR1110)', PG, None, 'MAPPED',
                                    'CG_REF_CODES ALLOWED EXPORT on ALLOW_EXPORT, IMPR_EXPR_TYPE, IMPR_EXPR_TYPE_AG'),
    'CGTE$CHECK_CONSTRAINT_VIO': ('MESSAGE', 'AG_PK', None, None, 'MAPPED', 'ORA-00001 text; SDP_PK / IMP_PK / IMP_BUSID_UK are other tables'),
    'CGFK$QRY_AGNTS_AG_SDP_FK': ('PACKAGE', 'IMPR1210.POST_QUERY', None, 'IMPR1210.POST_QUERY', 'MAPPED', 'port name'),
    'CGFK$QRY_AGNTS_AG_IMP_FK': ('PACKAGE', 'IMPR1210.POST_QUERY', None, 'IMPR1210.POST_QUERY', 'MAPPED', 'importer name / activity'),
    'CGFK$QRY_AGNTS_AG_IMP_AGENT_ID': ('PACKAGE', 'IMPR1210.POST_QUERY', None, 'IMPR1210.POST_QUERY', 'MAPPED', 'broker name / activity'),
    'CGFK$CHK_AGNTS_AG_SDP_FK': (None, None, None, None, 'DROPPED', 'not called (PORT_CD is never entered)'),
    'CGFK$CHK_AGNTS_AG_IMP_FK': ('PACKAGE', 'IMPR1210.IMPR_NBR_WHEN_VALIDATE_ITEM', None, 'IMPR1210.IMPR_NBR_WHEN_VALIDATE_ITEM', 'MAPPED',
                                 'private importer_row'),
    'CGFK$CHK_AGNTS_AG_IMP_AGENT_ID': ('PACKAGE', 'IMPR1210.IMPR_NBR_AG_WHEN_VALIDATE_ITEM', None,
                                       'IMPR1210.IMPR_NBR_AG_WHEN_VALIDATE_ITEM', 'MAPPED', 'private importer_row'),
    'CGNV$AI_CGSO$WINDOW_1_IMP_NEW': ('BUTTON', 'IMP_NEW', PG, None, 'MAPPED', 'OPEN_FORM IMP_NEW -> page 1130 (to confirm)'),
}
for pu in fm.findall(NS + 'ProgramUnit'):
    n = pu.get('Name')
    add('PROGRAM_UNIT', n, *PUS.get(n, (None, None, None, None, 'DROPPED',
                                        'NIB wrapper not called by active code (timers, EDI ticker, window, print)')))

# ---------------------------------------------------------------- LOVs, record groups, alerts, parameters, canvases, windows, libraries
for l in fm.findall(NS + 'LOV'):
    add('LOV', l.get('Name'), None, None, None, None, 'DROPPED', 'LOV of PORT_CD, never shown (item not enterable)')
for rg in fm.findall(NS + 'RecordGroup'):
    add('RECORD_GROUP', rg.get('Name'), None, None, None, None, 'DROPPED', 'record group of the PORT_CD LOV')
add('RECORD_GROUP', 'CGDV$DLRG (runtime, 3 lists)', 'LOV', 'LOV_ALLOWED_EXPORT (IMPR1110)', PG, None, 'MAPPED', 'CG_REF_CODES ALLOWED EXPORT')
add('LOV_FORM', 'LOV_IMPR', 'LOV', 'LOV_IMPR (IMPR1110, LOV_APX.IMPORTERS)', PG, None, 'MAPPED', 'IMPR_NBR, IMPR_NBR_AG')
add('LOV_FORM', 'LOV_AGNT_ATHR_IMPR', 'REGION', 'LOV_AGNT_ATHR_IMPR (read-only IG)', PG, None, 'MAPPED',
    'authorizations of the importer; rows open the authorization (to confirm, inventory 15 #4)')
add('LOV_FORM', 'LOV_SD_PORTS', None, None, None, None, 'DROPPED', 'PORT_CD is never enterable')
for a in fm.findall(NS + 'Alert'):
    n = a.get('Name')
    if n in ('CFG_ERROR', 'CFG_INFORMATION'):
        add('ALERT', n, 'APP_ITEM', 'page messages (validation texts / FORMS_APX.FORM_TRIGGER_FAILURE)', None, None, 'MAPPED',
            'STR.DispArbMsg ERROR / INFORMATION')
    elif n in ('USR_CONFIRM', 'USR_CONFIRM_B'):
        add('ALERT', n, 'DA', 'Confirm actions of CD1_STOPIMPRAUTH / CD2_REUSEIMPRAUTH EXECUTE-FUNCTION', PG, None, 'MAPPED',
            'STR.DispArbMsg / DispALERT CONFIRM of EXEC_FUNS')
    else:
        add('ALERT', n, None, None, None, None, 'DROPPED', 'OLB alert not used by the business code')
for p in fm.findall(NS + 'ModuleParameter'):
    n = p.get('Name')
    if n == 'P_MODULE_ID':
        add('PARAMETER', n, 'PAGE_ITEM', 'P1210_MODULE_ID', PG, None, 'MAPPED', 'FORMS_APX.GET_MODULE_ID')
    elif n in ('P_CURR_PORT_CD', 'P_USER_ID', 'P_WS_ID'):
        add('PARAMETER', n, 'APP_ITEM', {'P_CURR_PORT_CD': 'P_CURR_PORT_CD', 'P_USER_ID': 'SSO_APP_USER',
                                         'P_WS_ID': 'P_GLOBAL_V_WS_ID'}[n], None, None, 'MAPPED', 'f345 application item')
    elif n == 'P_FUNCTION_CD':
        add('PARAMETER', n, None, None, None, None, 'DROPPED', 'not needed: the functions never pass through SAVE')
    else:
        add('PARAMETER', n, None, None, None, None, 'DROPPED', 'used only by the OLB frame (EXECUTE_FUNCTION parameter list, print, EDI, timers)')
for c in fm.findall(NS + 'Canvas'):
    n = c.get('Name')
    add('CANVAS', n, *(('PAGE', 'IMPR1210', PG, None, 'MAPPED', 'regions AGNTS, LOV_AGNT_ATHR_IMPR, button IMP_NEW') if n == 'CG$PAGE_1'
                       else (None, None, None, None, 'DROPPED', 'OLB frame canvas')))
for w in fm.findall(NS + 'Window'):
    add('WINDOW', w.get('Name'), 'PAGE', 'IMPR1210', PG, None, 'MAPPED', 'one page')
for l in fm.findall(NS + 'AttachedLibrary'):
    n = l.get('Name')
    if n == 'CIC_LIB':
        add('LIBRARY', n, 'PACKAGE', 'FORMS_APX / ACTIVITY_DB', None, None, 'MAPPED',
            'STR -> FORMS_APX, HIJDATE -> FORMS_APX, ACTIVITY -> ACTIVITY_DB, INTRFACE -> AGNTS_IS_READ_ONLY, TMPLT -> FUNCS')
    else:
        add('LIBRARY', n, None, None, None, None, 'DROPPED', 'frame / client library (windows, timers, help, DLLs)')
for g in ('PORT_CD', 'ATHRZTN_SEQ_NBR', 'EXEC_QUERY_NOW', 'IMPR_NBR_AGENT_ID'):
    add('GLOBAL', g, 'PROCESS', 'EXECUTE-QUERY (request EXECUTE_QUERY, P0_PAGE_PK)', PG, 'IMPR1210.PRE_QUERY', 'MAPPED', 'query key')
for g in ('EXEC_QUERY', 'IMPR_NBR', 'IMPR_NAME', 'PORT_NAME'):
    add('GLOBAL', g, None, None, None, None, 'DROPPED', 'return values of the LOV forms -> Popup LOV / grid')
for g in ('CURRENT_VER', 'CURRENT_DT', 'CURRENT_VERSION', 'CG', 'EXIT', 'G_TIME_OUT', 'ITEM_NAME', 'SYSTEM_OBJ', 'TIMER'):
    add('GLOBAL', g, None, None, None, None, 'DROPPED', 'versions / help / frame / timers')
add('EXTERNAL', 'LIB_USR.IMPR.IMPR_SUSPENDED', 'PACKAGE', 'IMPR1210 importer_suspended', None, 'IMPR1210.IMPR_NBR_VALIDATION',
    'MAPPED', 'called unchanged (MISSING SOURCE)')
add('EXTERNAL', 'DCLTN.IMPR_IMPR_AUTH_USED', 'PACKAGE', 'IMPR1210 authorization_used', None, 'IMPR1210.AGNTS_IS_READ_ONLY',
    'MAPPED', 'called unchanged (MISSING SOURCE)')
add('EXTERNAL', 'FORM IMP_NEW', 'BUTTON', 'IMP_NEW -> page 1130', PG, None, 'TODO', 'target form to confirm (inventory 15 #5)')

# ---------------------------------------------------------------- write
cnt = collections.Counter(r[6] for r in rows)
def s(v):
    return 'NULL' if v is None else str(v) if isinstance(v, int) else "'%s'" % str(v).replace("'", "''")
out = ['''-- =============================================================================
-- IMPR1210 - migration registry rows (scripts/create_migration_registry.sql)
-- Purpose : MIG_FORM_REGISTRY row for the form + one MIG_OBJECT_MAP row per Forms object
--           (traceability matrix, analysis/IMPR1210/IMPR1210_apex_page_spec.md section 14)
-- Form    : IMPR1210.fmb (صيانة تفاويض الشركات الوسيطة)
-- Author  : Claude Code
-- Date    : 2026-11-25
-- Version : 1.0 (step 03, package IMPR1210 version 001)
-- Generated by work/IMPR1210/step03/build_trace.py - %d objects: %s.
-- app_id 202530 = the application installed from f345. Re-runnable: deletes the form's rows first.
-- NOT executed (CLAUDE.md 6.10).
-- =============================================================================
SET DEFINE OFF

DELETE FROM mig_object_map    WHERE form_name = 'IMPR1210';
DELETE FROM mig_form_registry WHERE form_name = 'IMPR1210';

INSERT INTO mig_form_registry
    (form_name, forms_app, subsystem, app_id, page_from, page_to, page_alias,
     package_name, complexity, status, owner, business_owner, notes)
VALUES
    ('IMPR1210', 'IMPR', 'IMPR', 202530, 1210, 1210, 'IMPR1210',
     'IMPR1210', 'COMPLEX', 'DESIGN', NULL, NULL,
     'صيانة تفاويض الشركات الوسيطة (AGNTS) - pages 1210, 121001; package IMPR1210 001 not compiled; LIB_USR.IMPR / DCLTN missing source; business logic medium');

DECLARE
    PROCEDURE m (p_type    VARCHAR2, p_name   VARCHAR2, p_comp  VARCHAR2, p_comp_name VARCHAR2,
                 p_page    NUMBER,   p_member VARCHAR2, p_status VARCHAR2, p_notes   VARCHAR2)
    IS
    BEGIN
        INSERT INTO mig_object_map
            (form_name, forms_object_type, forms_object_name, apex_comp_type,
             apex_comp_name, page_id, plsql_member, status, notes)
        VALUES ('IMPR1210', p_type, p_name, p_comp, p_comp_name, p_page, p_member, p_status, p_notes);
    END m;
BEGIN''' % (len(rows), ', '.join('%s %d' % kv for kv in sorted(cnt.items())))]
for r in rows:
    out.append('    m(%s);' % ', '.join(s(v) for v in r))
out.append('END;\n/\n\nCOMMIT;\n')
open(os.path.join(ROOT, 'registry', 'IMPR1210_registry.sql'), 'w', encoding='utf-8', newline='\n').write('\n'.join(out))
md = ['| # | Type | Forms object | APEX component | Page | Package member | Status | Notes |', '|---|---|---|---|---|---|---|---|']
for i, r in enumerate(rows, 1):
    md.append('| %d | %s |' % (i, ' | '.join(('`%s`' % r[1]) if j == 1 else ('-' if v is None else str(v).replace('|', '\\|'))
                                             for j, v in enumerate(r))))
open(os.path.join(ROOT, 'work', 'IMPR1210', 'step03', 'trace.md'), 'w', encoding='utf-8').write(
    '%d objects: %s.\n\n' % (len(rows), ', '.join('%s %d' % kv for kv in sorted(cnt.items()))) + '\n'.join(md) + '\n')
print(len(rows), dict(cnt))
