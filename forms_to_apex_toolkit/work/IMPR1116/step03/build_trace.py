"""build_trace.py - IMPR1116 step 03: traceability matrix (page spec section 14) and the registry script.

Every Forms object of forms/IMPR/IMPR1116_fmb.xml gets exactly one row: blocks, items, triggers,
LOVs, record groups, canvases, windows, alerts, parameters, libraries, globals, called forms and
program units. The mapping follows analysis/IMPR1116/IMPR1116_logic_extraction.md and the page
design in work/IMPR1116/step03/spec_manual.md (sections 0-13). Adapted from work/IMPR1120/step03/build_trace.py.

Usage (from forms_to_apex_toolkit/):
    python3 -I work/IMPR1116/step03/build_trace.py
Writes : work/IMPR1116/step03/trace.md, registry/IMPR1116_registry.sql,
         analysis/IMPR1116/IMPR1116_apex_page_spec.md (= spec_manual.md with the matrix inserted)
"""
import collections
import html
import re
import xml.etree.ElementTree as ET

NS = '{http://xmlns.oracle.com/Forms}'
FORM, PAGE, SEARCH = 'IMPR1116', 1116, 111601
fm = ET.parse('forms/IMPR/IMPR1116_fmb.xml').getroot().find(NS + 'FormModule')


def U(s):
    return html.unescape(html.unescape(s or ''))


rows = []          # (type, name, apex_type, apex_name, page, member, status, notes)


def add(t, name, apex_type=None, apex_name=None, page=None, member=None, status='MAPPED', notes=''):
    rows.append((t, name, apex_type, apex_name, page, member, status, notes))


def pk(m):
    return FORM + '.' + m if m else None


# ------------------------------------------------------------------ blocks
BLOCKS = {
    'TITLE': ('REGION', 'IMPR_PRTL_NAT_HERO', PAGE, None, 'MAPPED', 'OLB title bar -> hero region (FORMS_APX.HEADER_TITLE)'),
    'EDI_MSG': (None, None, None, None, 'DROPPED', 'OLB EDI message ticker - dropped (timers, IMPR1110 decision 2026-11-19)'),
    'LSIDE': ('REGION', 'FUNCS (page 0 drawer)', 0, None, 'MAPPED', 'OLB side function menu -> page 0 FUNCS, f345 list Page Functions'),
    'TOOLBAR': ('REGION', 'P0_ACTIONS (page 0 toolbar, f345)', 0, None, 'MAPPED', 'OLB toolbar -> f345 page 0 toolbar'),
    'IMPR_PRTL_NAT': ('REGION', 'IMPR_PRTL_NAT (Form region, table IMPR_PRTL_NAT, ROWID, update only) + IMPR_PRTL_NAT_SEARCH (page 111601)',
                      PAGE, None, 'MAPPED', 'master, 5 rows -> list on 111601 + one record on 1116 (spec decision 1); WHERE -> IMPR_PRTL_NAT_IS_PENDING'),
    'IMPORTERS': ('REGION', 'IMPORTERS (read-only Interactive Grid, SQL with the Forms WHERE on the master items)', PAGE, None, 'MAPPED',
                  'detail without relation; POST-QUERY lookup -> outer joins'),
}
blocks = fm.findall(NS + 'Block')
for b in blocks:
    a = BLOCKS[b.get('Name')]
    add('BLOCK', b.get('Name'), a[0], a[1], a[2], pk(a[3]), a[4], a[5])

# ------------------------------------------------------------------ items
TOOLBAR_ITEMS = {
    'SAVE': ('BUTTON', 'SAVE (page 0 toolbar)', 0, 'MAPPED', 'request SAVE -> PRE-UPDATE + Process form'),
    'EXIT': ('BUTTON', 'BACK (page 0 toolbar)', 0, 'MAPPED', ''),
    'EXIT1': ('BUTTON', 'BACK (page 0 toolbar)', 0, 'MAPPED', 'leave Enter-Query mode -> no query mode in APEX'),
    'CLEAR_ALL': ('BUTTON', 'CLEAR (page 0 toolbar)', 0, 'MAPPED', ''),
    'REMOVE': ('BUTTON', 'DELETE (page 0 toolbar)', 0, 'MAPPED', 'refused by PRE-DELETE (Delete Allowed = No)'),
    'ENTER': ('BUTTON', 'SEARCH (page 0 toolbar)', 0, 'MAPPED', 'Enter Query -> search page 111601'),
    'EXECUTE': ('BUTTON', 'SEARCH (page 0 toolbar)', 0, 'MAPPED', 'Execute Query -> search page 111601'),
    'RE_ENTER_QUERY': ('BUTTON', 'SEARCH (page 0 toolbar)', 0, 'MAPPED', ''),
    'FUN_BUT': ('BUTTON', 'FUNCS (page 0 toolbar)', 0, 'MAPPED', ''),
    'LIST_VALUE': (None, None, None, 'DROPPED', 'no LOV is reachable on page 1116 (REVIEW_FLAG is a select list)'),
    'HELP': (None, None, None, 'DROPPED', 'MS-Help obsolete'),
}
PRTL_ITEMS = {
    'PRTL_NAT_ISN': 'Display Only, sent on submit (input of PRE-UPDATE); link column on 111601',
    'IMPR_TYPE_CD': 'Hidden (value protected) - bind of the IMPORTERS grid',
    'CTRY_CD': 'Hidden (value protected) - bind of the IMPORTERS grid',
    'BUS_ID_TYPE_CD': 'Hidden (value protected) - bind of the IMPORTERS grid',
    'BUS_ID': 'Hidden (value protected) - bind of the IMPORTERS grid',
    'BUS_ID_BRNCH': 'Hidden (value protected) - bind of the IMPORTERS grid (NVL ..., 0)',
    'ID_TYPE_GZT': 'Display Only based on LOV_ID_TYPE_GZT; columns ID_TYPE_GZT / ID_TYPE_GZT_NAME on 111601',
    'BUS_ID_NEW': 'Display Only; column on 111601',
    'GAZT_NAME': 'Display Only; column on 111601 (search WHERE GAZT_NAME IS NOT NULL)',
    'REVIEW_FLAG': 'Select List LOV_PRTL_NAT_FLAG, the only editable item; read only while P0_PAGE_PK is null',
}
PRTL_DROPPED = {
    'TIN_NBR': 'Visible = No, not updatable, read by no trigger', 'DOC_DT': 'Visible = No, not updatable, read by no trigger',
    'ENTRY_DT': 'Visible = No, not updatable, read by no trigger', 'USER_ID': 'Visible = No, not updatable (inventory 15 #2)',
    'LST_TRAN_DT': 'Visible = No, not updatable (inventory 15 #2)', 'UPDATE_DT': 'Visible = No, not updatable (inventory 15 #2)',
}
IMPORTERS_ITEMS = {
    'PORT_CD': 'Display Only column', 'IMPR_NBR': 'Display Only column', 'HQ_IMPR_NBR': 'Hidden column',
    'IMPR_TYPE_CD': 'Hidden column', 'BUS_ID_TYPE_CD': 'Hidden column', 'BUS_ID': 'Hidden column', 'BUS_ID_BRNCH': 'Hidden column',
    'L_IT1_IMPR_TYPE_NAME': 'Display Only column (outer join IMPR_TYPES, POST-QUERY)', 'ARBC_IMPR_NAME': 'Display Only column',
    'L_BIT_BUS_ID_TYPE_NAME': 'Display Only column (outer join BUS_ID_TYPES, POST-QUERY)',
}
IMPORTERS_DROPPED = {
    'PORT_CD2': 'LOV button, hidden by WHEN-NEW-FORM-INSTANCE', 'L_BIT_BUS_ID_TYPE_NAME2': 'LOV button, hidden by WHEN-NEW-FORM-INSTANCE',
}
for b in blocks:
    bn = b.get('Name')
    for it in b.findall(NS + 'Item'):
        n = it.get('Name')
        full = bn + '.' + n
        if bn == 'TOOLBAR':
            a = TOOLBAR_ITEMS.get(n, (None, None, None, 'DROPPED', 'OLB toolbar item (record navigation / frame)'))
            add('ITEM', full, a[0], a[1], a[2], None, a[3], a[4])
        elif bn in ('TITLE', 'EDI_MSG', 'LSIDE'):
            add('ITEM', full, None, None, None, None, 'DROPPED', 'OLB block ' + bn)
        elif bn == 'IMPR_PRTL_NAT':
            if n in PRTL_ITEMS:
                add('ITEM', full, 'ITEM', 'P%d_%s' % (PAGE, n), PAGE, None, 'MAPPED', PRTL_ITEMS[n])
            else:
                add('ITEM', full, None, None, None, None, 'DROPPED', PRTL_DROPPED[n])
        elif bn == 'IMPORTERS':
            if n in IMPORTERS_ITEMS:
                add('ITEM', full, 'IG_COLUMN', 'IMPORTERS.' + n, PAGE, None, 'MAPPED', IMPORTERS_ITEMS[n])
            else:
                add('ITEM', full, None, None, None, None, 'DROPPED', IMPORTERS_DROPPED[n])

# ------------------------------------------------------------------ triggers
T = {}   # key OWNER.TRIGGER -> (apex_type, apex_name, page, member, status, notes)


def t(key, at, an, pg, mb, st, nt):
    T[key] = (at, an, pg, mb, st, nt)


t('FORM.WHEN-NEW-FORM-INSTANCE', None, None, None, None, 'DROPPED',
  'NIB startup -> f345 shell; CG$WHEN_NEW_FORM_INSTANCE -> shared LOVs; hide LOV buttons / widths -> not created / IG widths')
t('FORM.PRE-FORM', None, None, None, None, 'DROPPED', 'NIB.PRE_FORM, NLS date setting, help path -> f345 application')
t('FORM.KEY-CLRFRM', 'BUTTON', 'CLEAR (page 0 toolbar)', 0, None, 'MAPPED', 'Designer clear-form dialogue -> CLEAR + unsaved-changes warning')
t('FORM.KEY-ENTQRY', 'BUTTON', 'SEARCH (page 0 toolbar)', 0, None, 'MAPPED', 'NIB.KEY_ENTQRY -> search page 111601')
t('FORM.KEY-EXEQRY', 'BUTTON', 'SEARCH (page 0 toolbar)', 0, None, 'MAPPED', 'NIB.KEY_EXEQRY -> search page 111601')
t('FORM.KEY-DELREC', 'BUTTON', 'DELETE (page 0 toolbar)', 0, 'PRE_DELETE', 'MAPPED', 'NIB.KEY_DELREC -> refused (Delete Allowed = No)')
t('FORM.KEY-EXIT', 'BUTTON', 'BACK (page 0 toolbar)', 0, None, 'MAPPED', 'NIB.KEY_EXIT')
t('FORM.KEY-CLRBLK', 'BUTTON', 'CLEAR (page 0 toolbar)', 0, None, 'MAPPED', 'NIB.KEY_CLRBLK')
t('FORM.KEY-HELP', None, None, None, None, 'DROPPED', 'MS-Help obsolete')
t('FORM.KEY-F9', 'BUTTON', 'FUNCS (page 0 toolbar)', 0, None, 'MAPPED', 'side-menu toggle -> FUNCS')
t('FORM.ON-ERROR', 'APP_ITEM', 'APP_ERROR_HANDLER (f345)', None, None, 'MAPPED', 'NIB.ON_ERROR')
t('FORM.ON-MESSAGE', 'APP_ITEM', 'APP_ERROR_HANDLER (f345) / page messages', None, None, 'MAPPED', 'NIB.ON_MESSAGE')
for k in ('WHEN-TIMER-EXPIRED', 'WHEN-WINDOW-ACTIVATED', 'WHEN-MOUSE-DOWN', 'KEY-F4'):
    t('FORM.' + k, None, None, None, None, 'DROPPED', 'timers / window / frame (OLB, NIB)')
t('IMPR_PRTL_NAT.ON-ERROR', 'APP_ITEM', 'APP_ERROR_HANDLER (f345)', None, None, 'MAPPED', 'Designer CGTE$ trap, generic texts only')
t('IMPR_PRTL_NAT.KEY-HELP', None, None, None, None, 'DROPPED', 'MS-Help obsolete')
t('IMPR_PRTL_NAT.PRE-INSERT', 'PROCESS', 'PRE-INSERT', PAGE, 'PRE_INSERT', 'MAPPED', 'request CREATE refused (Insert Allowed = No); log type 1 cannot happen')
t('IMPR_PRTL_NAT.PRE-UPDATE', 'PROCESS', 'PRE-UPDATE', PAGE, 'PRE_UPDATE', 'MAPPED', 'activity log ACTIVITY_DB (9, 8, 2, PRTL_NAT_ISN)')
t('IMPR_PRTL_NAT.PRE-DELETE', 'PROCESS', 'PRE-DELETE', PAGE, 'PRE_DELETE', 'MAPPED', 'request DELETE refused (Delete Allowed = No)')
t('IMPR_PRTL_NAT.WHEN-NEW-RECORD-INSTANCE', 'REGION', 'IMPORTERS region SQL (binds P1116_IMPR_TYPE_CD ... BUS_ID_BRNCH)', PAGE, None,
  'MAPPED', 'GO_BLOCK / CLEAR_BLOCK / EXECUTE_QUERY -> grid queried with the open record')
t('IMPORTERS.POST-QUERY', 'REGION', 'IMPORTERS region SQL (outer joins)', PAGE, None, 'MAPPED',
  'CGFK$QRY_IMPORTERS_IMP_ITIDT_F; message on a missing type dropped')
t('IMPORTERS.ON-ERROR', 'APP_ITEM', 'APP_ERROR_HANDLER (f345)', None, None, 'MAPPED', 'Designer CGTE$ trap, generic texts only')
t('IMPORTERS.KEY-HELP', None, None, None, None, 'DROPPED', 'MS-Help obsolete')


def trigger_default(owner, name):
    parts = owner.split('.')
    blk = parts[0]
    if blk in ('LSIDE', 'TITLE', 'EDI_MSG'):
        return (None, None, None, None, 'DROPPED', 'OLB frame (' + blk + ')')
    if blk == 'TOOLBAR':
        if len(parts) == 2 and parts[1] in TOOLBAR_ITEMS and TOOLBAR_ITEMS[parts[1]][0]:
            a = TOOLBAR_ITEMS[parts[1]]
            return ('BUTTON', a[1], 0, None, 'MAPPED', 'toolbar button')
        return (None, None, None, None, 'DROPPED', 'OLB toolbar / side-menu keyboard')
    if owner == 'FORM' and name.startswith('KEY-'):
        return (None, None, None, None, 'DROPPED', 'NIB.' + name.replace('-', '_') + ' -> page 0 toolbar / browser keyboard')
    if name == 'KEY-LISTVAL' and blk in ('IMPR_PRTL_NAT', 'IMPORTERS'):
        return (None, None, None, None, 'DROPPED', 'Designer "may the LOV be shown" check -> item read-only state')
    if name == 'WHEN-BUTTON-PRESSED' and blk == 'IMPORTERS':
        return (None, None, None, None, 'DROPPED', 'LOV button hidden by WHEN-NEW-FORM-INSTANCE')
    return None


def walk_triggers():
    out = []
    for trg in fm.findall(NS + 'Trigger'):
        out.append(('FORM', trg))
    for b in blocks:
        for trg in b.findall(NS + 'Trigger'):
            out.append((b.get('Name'), trg))
        for it in b.findall(NS + 'Item'):
            for trg in it.findall(NS + 'Trigger'):
                out.append((b.get('Name') + '.' + it.get('Name'), trg))
    return out


seen = collections.Counter()
for owner, trg in walk_triggers():
    nm = trg.get('Name')
    key = owner + '.' + nm
    seen[key] += 1
    name = key if seen[key] == 1 else '%s (%d)' % (key, seen[key])
    if key in T:
        a = T[key]
    else:
        a = trigger_default(owner, nm)
        if a is None:
            raise SystemExit('no mapping for trigger ' + key)
    add('TRIGGER', name, a[0], a[1], a[2], pk(a[3]), a[4], a[5])

# ------------------------------------------------------------------ relations
for b in blocks:
    for r in b.findall(NS + 'Relation'):
        raise SystemExit('unexpected relation ' + r.get('Name'))

# ------------------------------------------------------------------ LOVs and record groups
LOVS = {
    'CGFK$IMPORTERS_PORT_CD': (None, None, None, 'DROPPED', 'IMPORTERS.PORT_CD is query only, LOV button hidden'),
    'CGFK$IMPORTERS_L_BIT_BUS_ID_TY': (None, None, None, 'DROPPED', 'query only, button hidden; names from the IMPORTERS region SQL'),
}
for lv in fm.findall(NS + 'LOV'):
    a = LOVS[lv.get('Name')]
    add('LOV', lv.get('Name'), a[0], a[1], a[2], None, a[3], a[4])
for rg in fm.findall(NS + 'RecordGroup'):
    a = LOVS[rg.get('Name')]
    add('RECORD_GROUP', rg.get('Name'), a[0], a[1], a[2], None, a[3], 'query of LOV ' + rg.get('Name'))
add('RECORD_GROUP', 'CGDV$DLRG (runtime)', 'LOV', 'LOV_ID_TYPE_GZT, LOV_PRTL_NAT_FLAG (LOV_APX.REFERENCE_CODES)', PAGE, None, 'MAPPED',
    'CREATE_GROUP_FROM_QUERY on CG_REF_CODES (domains ID_TYPE_GZT, PRTL_NAT_FLAG) in CGDV$POPULATE_DYNAMIC_LISTS')

# ------------------------------------------------------------------ canvases, windows
for c in fm.findall(NS + 'Canvas'):
    if c.get('Name') == 'CG$PAGE_1':
        add('CANVAS', 'CG$PAGE_1', 'PAGE', '1116 IMPR1116', PAGE, None, 'MAPPED', 'main content canvas')
    else:
        add('CANVAS', c.get('Name'), None, None, None, None, 'DROPPED', 'OLB canvas ' + c.get('Name'))
for w in fm.findall(NS + 'Window'):
    add('WINDOW', w.get('Name'), 'PAGE', '1116 IMPR1116', PAGE, None, 'MAPPED', 'console window')

# ------------------------------------------------------------------ alerts
ALERTS = {
    'CFG_SYSTEM_ERROR': ('TEXT_MESSAGE', 'FORMS_APX.FORM_TRIGGER_FAILURE (activity log error, IMPR1116.PRE_UPDATE)', 'MAPPED', 'ACTIVITY.ADD_ACTIVITY'),
    'CFG_ERROR': ('APP_ITEM', 'APP_ERROR_HANDLER (f345)', 'MAPPED', 'NIB.ON_ERROR'),
    'CFG_INFORMATION': ('APP_ITEM', 'APP_ERROR_HANDLER (f345) / process messages', 'MAPPED', 'NIB.ON_MESSAGE'),
    'CFG_ASK_COMMIT': ('PAGE', 'Warn on Unsaved Changes (page 1116)', 'MAPPED', 'Designer commit dialogue'),
}
for al in fm.findall(NS + 'Alert'):
    a = ALERTS.get(al.get('Name'))
    if a:
        add('ALERT', al.get('Name'), a[0], a[1], PAGE, None, a[2], a[3])
    else:
        add('ALERT', al.get('Name'), None, None, None, None, 'DROPPED', 'not used by IMPR1116 code')

# ------------------------------------------------------------------ parameters
PARAMS = {
    'P_CURR_PORT_CD': ('APP_ITEM', 'P_CURR_PORT_CD (f345)', None, None, 'MAPPED', 'ACTIVITY_DB port (PRE-UPDATE)'),
    'P_USER_ID': ('APP_ITEM', 'SSO_APP_USER (f345)', None, None, 'MAPPED', 'ACTIVITY_DB user'),
    'P_WS_ID': ('APP_ITEM', 'P_GLOBAL_V_WS_ID (f345)', None, None, 'MAPPED', 'ACTIVITY_DB workstation'),
    'P_MODULE_ID': ('ITEM', 'P1116_MODULE_ID', PAGE, None, 'MAPPED', 'FORMS_APX.GET_MODULE_ID'),
    'P_USER_NAME': ('APP_ITEM', 'V_USR_NAME (f345 header)', None, None, 'MAPPED', 'title bar only'),
    'P_MODULE_NAME': ('APP_ITEM', 'SYS_ANAME (f345 page title)', None, None, 'MAPPED', 'title bar only'),
}
for p in fm.findall(NS + 'ModuleParameter'):
    a = PARAMS.get(p.get('Name'))
    if a:
        add('PARAMETER', p.get('Name'), a[0], a[1], a[2], pk(a[3]), a[4], a[5])
    else:
        add('PARAMETER', p.get('Name'), None, None, None, None, 'DROPPED', 'not used by the business code (function menu / reports / frame)')

# ------------------------------------------------------------------ libraries
LIBS = {
    'CIC_LIB': ('MAPPED', 'NIB / TMPLT -> f345; ACTIVITY -> ACTIVITY_DB; HIJDATE (title date only) -> f345 header'),
    'CIC_AMSG': ('MAPPED', 'Des$Form_errors messages -> FORMS_APX / APP_ERROR_HANDLER'),
    'OFGTEL': ('DROPPED', 'MISSING SOURCE - generic constraint messages of the dropped ON-ERROR triggers (APP_ERROR_HANDLER)'),
}
for lb in fm.findall(NS + 'AttachedLibrary'):
    a = LIBS.get(lb.get('Name'), ('DROPPED', 'not needed in the browser (help, DLL, window, tab, pick list, block sync)'))
    add('LIBRARY', lb.get('Name'), None, None, None, None, a[0], a[1])

# ------------------------------------------------------------------ globals (from the decoded code)
code = ' '.join(U(x.get('TriggerText')) for x in fm.iter(NS + 'Trigger')) + ' ' + \
       ' '.join(U(x.get('ProgramUnitText')) for x in fm.iter(NS + 'ProgramUnit'))
code_nc = re.sub(r'--[^\n]*|/\*.*?\*/', ' ', code, flags=re.S)
for g in sorted(set(x.upper() for x in re.findall(r':GLOBAL\.(\w+[$\w]*)', code_nc, re.I))):
    add('GLOBAL', g, None, None, None, None, 'DROPPED', 'Designer help / frame / function menu - not needed')

# ------------------------------------------------------------------ called forms
add('CALLED_FORM', 'V_CALLED_FORM (dynamic, PU EXECUTE_FUNCTION)', 'REGION', 'FUNCS (Page Functions list, page 0)', 0, None, 'TODO',
    'functions of the module in SC_SYSTEM_OBJECTS unknown (inventory 15 #6)')

# ------------------------------------------------------------------ program units
PU_NOTE = {
    'CGFK$QRY_IMPORTERS_IMP_ITIDT_F': ('REGION', 'IMPORTERS region SQL (outer joins)', PAGE, 'MAPPED', 'POST-QUERY lookup as SQL'),
    'CG$WHEN_NEW_FORM_INSTANCE': (None, None, None, 'DROPPED', 'lists -> shared LOVs'),
    'CGDV$POPULATE_DYNAMIC_LISTS': ('LOV', 'LOV_ID_TYPE_GZT, LOV_PRTL_NAT_FLAG', PAGE, 'MAPPED', 'LOV_APX.REFERENCE_CODES'),
    'EXECUTE_FUNCTION': ('REGION', 'FUNCS (page 0)', 0, 'MAPPED', 'f345 Page Functions'),
    'MOUSE_CLICK': ('REGION', 'FUNCS (page 0)', 0, 'MAPPED', 'f345 Page Functions'),
    'ADJ_FUNS': (None, None, None, 'DROPPED', 'empty in Forms'), 'EXEC_FUNS': (None, None, None, 'DROPPED', 'empty in Forms'),
    'CGTE$CHECK_CONSTRAINT_VIO': ('APP_ITEM', 'APP_ERROR_HANDLER (f345)', None, 'MAPPED', 'generic constraint text'),
}
for p in fm.findall(NS + 'ProgramUnit'):
    n = p.get('Name')
    a = PU_NOTE.get(n, (None, None, None, 'DROPPED', 'NIB wrapper not called by active code (timers, EDI ticker, window, print)'))
    add('PROGRAM_UNIT', n, a[0], a[1], a[2], None, a[3], a[4])

# ------------------------------------------------------------------ output
cnt = collections.Counter(r[6] for r in rows)
names = collections.Counter((r[0], r[1]) for r in rows)
dup = [k for k, v in names.items() if v > 1]
assert not dup, dup


def md(v):
    return '–' if v in (None, '') else str(v).replace('|', '\\|')


out = ['| # | Type | Forms object | APEX component | Page | Package member | Status | Notes |', '|---|---|---|---|---|---|---|---|']
for i, r in enumerate(rows, 1):
    out.append('| %d | %s | `%s` | %s | %s | %s | %s | %s |' % (i, r[0], r[1], md(r[3]), md(r[4]), md(r[5]), r[6], md(r[7])))
summary = '%d objects: %s.' % (len(rows), ', '.join('%s %d' % kv for kv in sorted(cnt.items())))
by_type = ', '.join('%s %d' % kv for kv in sorted(collections.Counter(r[0] for r in rows).items()))
trace = summary + ' By type: ' + by_type + '.\n\n' + '\n'.join(out) + '\n'
open('work/IMPR1116/step03/trace.md', 'w', encoding='utf-8').write(trace)


def q(v):
    if v is None or v == '':
        return 'NULL'
    if isinstance(v, int):
        return str(v)
    return "'" + str(v).replace("'", "''") + "'"


reg = ["""-- =============================================================================
-- IMPR1116 - migration registry rows (scripts/create_migration_registry.sql)
-- Purpose : MIG_FORM_REGISTRY row for the form + one MIG_OBJECT_MAP row per Forms object
--           (traceability matrix, analysis/IMPR1116/IMPR1116_apex_page_spec.md section 14)
-- Form    : IMPR1116.fmb
-- Author  : Claude Code
-- Date    : 2026-11-24
-- Version : 1.0 (step 03 revision 1, package IMPR1116 version 001)
-- Generated by work/IMPR1116/step03/build_trace.py - %s
-- app_id 202530 = the application installed from f345. Re-runnable: deletes the form's rows first.
-- NOT executed (CLAUDE.md 6.10).
-- =============================================================================
SET DEFINE OFF

DELETE FROM mig_object_map    WHERE form_name = 'IMPR1116';
DELETE FROM mig_form_registry WHERE form_name = 'IMPR1116';

INSERT INTO mig_form_registry
    (form_name, forms_app, subsystem, app_id, page_from, page_to, page_alias,
     package_name, complexity, status, owner, business_owner, notes)
VALUES
    ('IMPR1116', 'IMPR', 'IMPR', 202530, 1116, 1116, 'IMPR1116',
     'IMPR1116', 'COMPLEX', 'DESIGN', NULL, NULL,
     'استعراض بيانات رقم المنشأة 700 المدخلة من البوابة - step 03 rev 1 page design (pages 1116, 111601); package IMPR1116 001 not compiled; business logic simple');

DECLARE
    PROCEDURE m (p_type    VARCHAR2, p_name   VARCHAR2, p_comp  VARCHAR2, p_comp_name VARCHAR2,
                 p_page    NUMBER,   p_member VARCHAR2, p_status VARCHAR2, p_notes   VARCHAR2)
    IS
    BEGIN
        INSERT INTO mig_object_map
            (form_name, forms_object_type, forms_object_name, apex_comp_type,
             apex_comp_name, page_id, plsql_member, status, notes)
        VALUES ('IMPR1116', p_type, p_name, p_comp, p_comp_name, p_page, p_member, p_status, p_notes);
    END m;
BEGIN""" % summary]
for r in rows:
    reg.append('    m(%s);' % ', '.join(q(x) for x in r))
reg.append('END;\n/\n\nCOMMIT;\n')
open('registry/IMPR1116_registry.sql', 'w', encoding='utf-8').write('\n'.join(reg))

spec = open('work/IMPR1116/step03/spec_manual.md', encoding='utf-8').read()
assert '<!-- TRACE -->' in spec
open('analysis/IMPR1116/IMPR1116_apex_page_spec.md', 'w', encoding='utf-8').write(spec.replace('<!-- TRACE -->', trace))
print(summary)
print('by type:', by_type)
