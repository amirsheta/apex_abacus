"""build_trace.py - IMPR1125 step 03: traceability matrix (page spec section 14) and the registry script.

Every Forms object of forms/IMPR/IMPR1125_fmb.xml gets exactly one row: blocks, items, triggers, relations,
LOVs, record groups, canvases, windows, alerts, parameters, libraries, globals, called forms and program units.
The mapping follows analysis/IMPR1125/IMPR1125_logic_extraction.md and the page design (spec sections 0-13).
Same structure as work/IMPR1120/step03/build_trace.py.

Usage (from forms_to_apex_toolkit/):
    python3 -I work/IMPR1125/step03/build_trace.py
Writes : work/IMPR1125/step03/trace.md, registry/IMPR1125_registry.sql,
         analysis/IMPR1125/IMPR1125_apex_page_spec.md (= spec_manual.md with the matrix inserted)
"""
import collections
import html
import re
import xml.etree.ElementTree as ET

NS = '{http://xmlns.oracle.com/Forms}'
FORM, PAGE, SEARCH, DELETED = 'IMPR1125', 1125, 112501, 112502
fm = ET.parse('forms/IMPR/IMPR1125_fmb.xml').getroot().find(NS + 'FormModule')


def U(s):
    return html.unescape(html.unescape(s or ''))


rows = []          # (type, name, apex_type, apex_name, page, member, status, notes)


def add(t, name, apex_type=None, apex_name=None, page=None, member=None, status='MAPPED', notes=''):
    rows.append((t, name, apex_type, apex_name, page, member, status, notes))


def pk(m):
    return FORM + '.' + m if m else None


# ------------------------------------------------------------------ blocks
BLOCKS = {
    'TITLE': ('REGION', 'HQ_IMPRS_HERO', PAGE, None, 'MAPPED', 'OLB title bar -> hero region (HEADER TITLE, FORMS_APX)'),
    'EDI_MSG': (None, None, None, None, 'DROPPED', 'OLB EDI message ticker - dropped (timers, IMPR1110 decision 2026-11-19)'),
    'LSIDE': ('REGION', 'FUNCS (page 0 drawer, f345 Page Functions)', 0, None, 'MAPPED', 'OLB side function menu'),
    'TOOLBAR': ('REGION', 'P0_ACTIONS (page 0 toolbar, f345)', 0, None, 'MAPPED', 'OLB toolbar -> f345 page 0 toolbar'),
    'HQ_IMPRS': ('REGION', 'HQ_IMPRS (Form region, table HQ_IMPRS, primary key ROWID, no Process form)', PAGE, None, 'MAPPED',
                 'master search header; ON-INSERT / ON-UPDATE / ON-DELETE NULL -> never written; search page 112501'),
    'IMPR_CNTRL_SUSPNS': ('REGION', 'IMPR_CNTRL_SUSPNS (editable Interactive Grid)', PAGE, 'IMPR_CNTRL_SUSPNS_SAVE_ROW', 'MAPPED',
                          'detail; WHERE SUSPN_RLSE_DT IS NULL; DML through IMPR_CNTRL_SUSPNS_SAVE_ROW (soft delete)'),
}
blocks = fm.findall(NS + 'Block')
for b in blocks:
    a = BLOCKS[b.get('Name')]
    add('BLOCK', b.get('Name'), a[0], a[1], a[2], pk(a[3]), a[4], a[5])

# ------------------------------------------------------------------ items
TOOLBAR_ITEMS = {
    'SAVE': ('BUTTON', 'SAVE (page 0 toolbar)', 0, 'MAPPED', 'saves the grid (request SAVE)'),
    'EXIT': ('BUTTON', 'BACK (page 0 toolbar)', 0, 'MAPPED', ''),
    'EXIT1': ('BUTTON', 'BACK (page 0 toolbar)', 0, 'MAPPED', 'leave Enter-Query mode -> no query mode in APEX'),
    'CLEAR_ALL': ('BUTTON', 'CLEAR (page 0 toolbar)', 0, 'MAPPED', ''),
    'REMOVE': ('BUTTON', 'DELETE (page 0 toolbar) / IG row delete', 0, 'MAPPED',
               'importer: refused by PRE-DELETE (Delete Allowed = No); suspension: IG row delete'),
    'ENTER': ('BUTTON', 'SEARCH (page 0 toolbar)', 0, 'MAPPED', 'Enter Query -> search page 112501'),
    'EXECUTE': ('BUTTON', 'SEARCH (page 0 toolbar)', 0, 'MAPPED', 'Execute Query -> search page 112501'),
    'RE_ENTER_QUERY': ('BUTTON', 'SEARCH (page 0 toolbar)', 0, 'MAPPED', ''),
    'FUN_BUT': ('BUTTON', 'FUNCS (page 0 toolbar)', 0, 'MAPPED', ''),
    'LIST_VALUE': (None, None, None, 'DROPPED', 'LOV key -> page 0 SEARCH'),
    'HELP': (None, None, None, 'DROPPED', 'MS-Help obsolete'),
}
HQ_ITEMS = {
    'BUS_ID': 'Text Field, editable only while P0_PAGE_PK is null (search key); sent to the save (SMS text)',
    'BUS_ID_TYPE_CD': 'Display Only', 'BUS_ID_TYPE_NAME': 'Display Only (POST-QUERY)', 'BUS_ID_BRNCH': 'Display Only',
    'HQ_IMPR_NBR': 'Number Field, editable only while P0_PAGE_PK is null (search key, Update Allowed = No)',
    'CITY_CODE_OF_ID': 'Display Only (POST-QUERY)', 'CITY_CODE_OF_NAME': 'Display Only (POST-QUERY)',
    'IMPR_TYPE_CD': 'Display Only (POST-QUERY)', 'IMPR_TYPE_NAME': 'Display Only (POST-QUERY)',
    'IMPR_EXPR_TYPE': 'Display Only based on LOV_ALLOWED_EXPORT (POST-QUERY)', 'CTRY_CD': 'Display Only (POST-QUERY)',
    'CRTY_ARBC_NAME': 'Display Only (POST-QUERY)', 'ARBC_IMPR_NAME': 'Display Only (POST-QUERY)',
    'ENG_IMPR_NAME': 'Display Only (POST-QUERY)',
}
SUSPN_COLUMNS = {
    'SUSPN_STRT_DT': 'Text Field (HIJRI_DATE_FORMAT, hijri-date-default), required',
    'SUSPN_END_DT': 'Text Field (HIJRI_DATE_FORMAT, hijri-date-default)',
    'HQ_IMPR_NBR': 'Hidden, primary key (default = master item P1125_HQ_IMPR_NBR; save call NVL)',
    'SUSPN_SEQ': 'Hidden, primary key (set by IMPR_CNTRL_SUSPNS_PRE_INSERT)',
    'SUSPN_RSN_CD': 'Hidden, default 1 (no canvas in Forms)',
    'SUSPN_RSN_TEXT': 'Text Field, required, max 50',
    'SUSPN_SIDE_CD': 'Select List LOV_SUSPN_SIDE_CD, Read Only always, default 5 (CGSO$COMBO_DO)',
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
        elif bn == 'HQ_IMPRS':
            if n == 'BUT_SH_HQNUM':
                add('ITEM', full, 'BUTTON', 'SEARCH (page 0 toolbar) -> 112501', 0, None, 'MAPPED', 'LOV button of BUS_ID (SINGLE_IMP_LOV)')
            else:
                add('ITEM', full, 'ITEM', 'P%d_%s' % (PAGE, n), PAGE, None, 'MAPPED', HQ_ITEMS[n])
        elif bn == 'IMPR_CNTRL_SUSPNS':
            if n == 'SUSPN_RLSE_DT':
                add('ITEM', full, 'IG_COLUMN', 'IMPR_CNTRL_SUSPNS_DELETED.SUSPN_RLSE_DT (page 112502)', DELETED,
                    pk('IMPR_CNTRL_SUSPNS_ON_DELETE'), 'MAPPED', 'not a grid column on 1125: set by ON_DELETE; region WHERE SUSPN_RLSE_DT IS NULL')
            else:
                add('ITEM', full, 'IG_COLUMN', 'IMPR_CNTRL_SUSPNS.' + n, PAGE, None, 'MAPPED', SUSPN_COLUMNS[n])

# ------------------------------------------------------------------ triggers
T = {}


def t(key, at, an, pg, mb, st, nt):
    T[key] = (at, an, pg, mb, st, nt)


t('FORM.WHEN-NEW-FORM-INSTANCE', None, None, None, None, 'DROPPED',
  'NIB / CGBS2$ / CG$WHEN_NEW_FORM_INSTANCE -> f345, LOVs, native master-detail; globals := NULL -> P0_PAGE_PK')
t('FORM.PRE-FORM', None, None, None, None, 'DROPPED', 'NIB.PRE_FORM, NLS date setting, help path -> f345 application')
for k in ('ON-CLEAR-DETAILS', 'ON-POPULATE-DETAILS', 'WHEN-NEW-BLOCK-INSTANCE'):
    t('FORM.' + k, None, None, None, None, 'DROPPED', 'Designer master-detail coordination (CGBS$) -> native Form + IG')
for k in ('KEY-CQUERY', 'KEY-CLRREC', 'KEY-NXTKEY', 'KEY-MENU', 'KEY-CLRFRM'):
    t('FORM.' + k, None, None, None, None, 'DROPPED', 'Designer key handler -> page 0 toolbar / IG')
t('FORM.KEY-HELP', None, None, None, None, 'DROPPED', 'MS-Help obsolete')
t('FORM.KEY-F9', 'BUTTON', 'FUNCS (page 0 toolbar)', 0, None, 'MAPPED', 'side-menu toggle -> FUNCS')
t('FORM.ON-ERROR', 'APP_ITEM', 'APP_ERROR_HANDLER (f345)', None, None, 'MAPPED', 'NIB.ON_ERROR')
t('FORM.ON-MESSAGE', 'APP_ITEM', 'APP_ERROR_HANDLER (f345) / page messages', None, None, 'MAPPED', 'NIB.ON_MESSAGE')
for k in ('WHEN-TIMER-EXPIRED', 'WHEN-WINDOW-ACTIVATED', 'WHEN-MOUSE-DOWN', 'KEY-F4'):
    t('FORM.' + k, None, None, None, None, 'DROPPED', 'timers / window / frame (OLB, NIB)')
t('HQ_IMPRS.PRE-QUERY', 'PROCESS', 'HQ_IMPR_NBR EXECUTE-QUERY / BUS_ID EXECUTE-QUERY (P0_PAGE_PK)', PAGE, None, 'MAPPED',
  ':GLOBAL.HQ_IMPR_NBR / BUS_NBR criteria -> ROWID of the first matching HQ_IMPRS row')
t('HQ_IMPRS.POST-QUERY', 'PROCESS', 'POST-QUERY + DA HQ_IMPRS POST-QUERY (Confirm -> dialog 112502)', PAGE, 'HQ_IMPRS_POST_QUERY', 'MAPPED',
  'lookups; released-suspension count -> RELEASED_SUSPENSIONS_EXIST; CONFIRM + DELETE_SUSPS_LOV -> DA')
t('HQ_IMPRS.WHEN-NEW-ITEM-INSTANCE', 'DYNAMIC_ACTION', 'HQ_IMPR_NBR / BUS_ID WHEN-VALIDATE-ITEM (Submit EXECUTE_QUERY)', PAGE, None,
  'MAPPED', 'CLEAR_BLOCK + GO_BLOCK + EXECUTE_QUERY -> page submit + branch')
for k in ('ON-INSERT', 'ON-UPDATE', 'ON-DELETE'):
    t('HQ_IMPRS.' + k, None, None, None, None, 'DROPPED', 'body NULL: the master is never written (Form region without Process form)')
t('HQ_IMPRS.ON-ERROR', 'TEXT_MESSAGE', 'APP_ERROR_HANDLER (f345)', None, None, 'MAPPED', 'Designer constraint messages')
t('HQ_IMPRS.KEY-HELP', None, None, None, None, 'DROPPED', 'MS-Help obsolete')
t('HQ_IMPRS.BUS_ID.WHEN-VALIDATE-ITEM', 'VALIDATION', 'BUS_ID VALIDATION + DA BUS_ID WHEN-VALIDATE-ITEM + process BUS_ID EXECUTE-QUERY',
  PAGE, 'BUS_ID_VALIDATION', 'MAPPED', 'also IMPR1125.BUS_ID_WHEN_VALIDATE_ITEM; SINGLE_IMP_LOV on error -> page 0 SEARCH')
t('HQ_IMPRS.HQ_IMPR_NBR.WHEN-VALIDATE-ITEM', 'VALIDATION',
  'HQ_IMPR_NBR VALIDATION + DA HQ_IMPR_NBR WHEN-VALIDATE-ITEM + process HQ_IMPR_NBR EXECUTE-QUERY', PAGE, 'HQ_IMPR_NBR_VALIDATION',
  'MAPPED', 'also IMPR1125.HQ_IMPR_NBR_WHEN_VALIDATE_ITEM')
t('HQ_IMPRS.BUS_ID.KEY-LISTVAL', 'PAGE', '112501 IMPR1125_SEARCH (page 0 SEARCH)', SEARCH, None, 'MAPPED', 'SINGLE_IMP_LOV')
t('HQ_IMPRS.BUT_SH_HQNUM.WHEN-BUTTON-PRESSED', 'PAGE', '112501 IMPR1125_SEARCH (page 0 SEARCH)', SEARCH, None, 'MAPPED',
  'GO_ITEM BUS_ID + DO_KEY LIST_VALUES')
t('IMPR_CNTRL_SUSPNS.PRE-INSERT', 'PROCESS', 'IMPR_CNTRL_SUSPNS - Save Interactive Grid Data', PAGE, 'IMPR_CNTRL_SUSPNS_PRE_INSERT',
  'MAPPED', 'called by IMPR_CNTRL_SUSPNS_SAVE_ROW (row status C)')
t('IMPR_CNTRL_SUSPNS.POST-INSERT', 'PROCESS', 'IMPR_CNTRL_SUSPNS - Save Interactive Grid Data', PAGE, 'IMPR_CNTRL_SUSPNS_POST_INSERT',
  'MAPPED', 'called by IMPR_CNTRL_SUSPNS_SAVE_ROW; COMMIT removed (HIGH)')
t('IMPR_CNTRL_SUSPNS.PRE-UPDATE', 'PROCESS', 'IMPR_CNTRL_SUSPNS - Save Interactive Grid Data', PAGE, 'IMPR_CNTRL_SUSPNS_PRE_UPDATE',
  'MAPPED', 'called by IMPR_CNTRL_SUSPNS_SAVE_ROW (row status U)')
t('IMPR_CNTRL_SUSPNS.ON-DELETE', 'PROCESS', 'IMPR_CNTRL_SUSPNS - Save Interactive Grid Data', PAGE, 'IMPR_CNTRL_SUSPNS_ON_DELETE',
  'MAPPED', 'soft delete, called by IMPR_CNTRL_SUSPNS_SAVE_ROW (row status D)')
t('IMPR_CNTRL_SUSPNS.KEY-DELREC', 'IG_COLUMN', 'IMPR_CNTRL_SUSPNS row delete', PAGE, None, 'MAPPED',
  'TMPLT.KEY_DELETE_RECORD: confirm + delete + COMMIT -> IG delete, APEX commit')
t('IMPR_CNTRL_SUSPNS.ON-ERROR', 'TEXT_MESSAGE', 'APP_ERROR_HANDLER (f345)', None, None, 'MAPPED', 'Designer constraint messages')
t('IMPR_CNTRL_SUSPNS.KEY-HELP', None, None, None, None, 'DROPPED', 'MS-Help obsolete')
t('IMPR_CNTRL_SUSPNS.SUSPN_STRT_DT.WHEN-VALIDATE-ITEM', 'VALIDATION',
  'IMPR_CNTRL_SUSPNS SUSPN_STRT_DT VALIDATION + DA IMPR_CNTRL_SUSPNS SUSPN_STRT_DT WHEN-VALIDATE-ITEM', PAGE,
  'SUSPN_STRT_DT_VALIDATION', 'MAPPED', '')
t('IMPR_CNTRL_SUSPNS.SUSPN_END_DT.WHEN-VALIDATE-ITEM', 'VALIDATION',
  'IMPR_CNTRL_SUSPNS SUSPN_END_DT VALIDATION + DA IMPR_CNTRL_SUSPNS SUSPN_END_DT WHEN-VALIDATE-ITEM', PAGE,
  'SUSPN_END_DT_VALIDATION', 'MAPPED', '')


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
        return (None, None, None, None, 'DROPPED', 'NIB.' + name.replace('-', '_') + ' -> page 0 toolbar / IG keyboard')
    if name == 'KEY-LISTVAL' and blk in ('HQ_IMPRS', 'IMPR_CNTRL_SUSPNS'):
        if parts[-1] in ('SUSPN_STRT_DT', 'SUSPN_END_DT'):
            return (None, None, None, None, 'DROPPED', 'INTRFACE.DISP_CALENDAR -> Hijri date column (hijri-date-default)')
        return (None, None, None, None, 'DROPPED', 'Designer "may the LOV be shown" check -> item read-only state')
    if name == 'KEY-F4' and blk == 'IMPR_CNTRL_SUSPNS':
        return (None, None, None, None, 'DROPPED', 'INTRFACE.DISP_DATE_CON -> Hijri date column')
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
    a = T.get(key) or trigger_default(owner, nm)
    if a is None:
        raise SystemExit('no mapping for trigger ' + key)
    add('TRIGGER', name, a[0], a[1], a[2], pk(a[3]), a[4], a[5])
unused = set(T) - set(o + '.' + tr.get('Name') for o, tr in walk_triggers())
assert not unused, unused

# ------------------------------------------------------------------ relations
for b in blocks:
    for r in b.findall(NS + 'Relation'):
        add('RELATION', r.get('Name'), 'REGION', 'IMPR_CNTRL_SUSPNS (IG WHERE hq_impr_nbr = :P1125_HQ_IMPR_NBR)',
            PAGE, None, 'MAPPED', '%s -> %s; master key from the master form (column default + NVL in the save call)'
            % (b.get('Name'), r.get('DetailBlock')))

# ------------------------------------------------------------------ LOVs and record groups
for lv in fm.findall(NS + 'LOV'):
    add('LOV', lv.get('Name'), None, None, None, None, 'DROPPED', 'item BUS_ID_TYPE_CD is display only; name from HQ_IMPRS_POST_QUERY')
for rg in fm.findall(NS + 'RecordGroup'):
    add('RECORD_GROUP', rg.get('Name'), None, None, None, None, 'DROPPED', 'query of LOV ' + rg.get('Name'))
add('RECORD_GROUP', 'CGDV$DLRG (runtime)', 'LOV', 'LOV_ALLOWED_EXPORT (IMPR1110), LOV_SUSPN_SIDE_CD (IMPR1120)', PAGE, None, 'MAPPED',
    'CREATE_GROUP_FROM_QUERY on CG_REF_CODES; IMPR_SUSPN_RSN_CD list not needed (column hidden, meaning joined on 112502)')

# ------------------------------------------------------------------ canvases, windows
for c in fm.findall(NS + 'Canvas'):
    if c.get('Name') == 'CG$PAGE_1':
        add('CANVAS', 'CG$PAGE_1', 'PAGE', '1125 IMPR1125', PAGE, None, 'MAPPED', 'main content canvas')
    else:
        add('CANVAS', c.get('Name'), None, None, None, None, 'DROPPED', 'OLB canvas ' + c.get('Name'))
for w in fm.findall(NS + 'Window'):
    add('WINDOW', w.get('Name'), 'PAGE', '1125 IMPR1125', PAGE, None, 'MAPPED', 'console window')

# ------------------------------------------------------------------ alerts
ALERTS = {
    'CFG_ERROR': ('TEXT_MESSAGE', 'validation error texts / FORMS_APX.FORM_TRIGGER_FAILURE', 'MAPPED', 'STR.DISPALERT ERROR (literal texts)'),
    'CFG_SYSTEM_ERROR': ('TEXT_MESSAGE', 'FORMS_APX.FORM_TRIGGER_FAILURE (activity log / Hijri date errors)', 'MAPPED', ''),
    'CFG_INFORMATION': ('TEXT_MESSAGE', 'page messages (f345)', 'MAPPED', 'NIB.ON_MESSAGE'),
    'USR_CONFIRM': ('DYNAMIC_ACTION', 'HQ_IMPRS POST-QUERY native Confirm', 'MAPPED', 'STR.DispALERT CONFIRM (released suspensions)'),
    'USR_WARNING_B': ('DYNAMIC_ACTION', 'IG row delete (restorable until SAVE)', 'MAPPED', 'TMPLT.KEY_DELETE_RECORD'),
}
for al in fm.findall(NS + 'Alert'):
    a = ALERTS.get(al.get('Name'))
    if a:
        add('ALERT', al.get('Name'), a[0], a[1], PAGE, None, a[2], a[3])
    else:
        add('ALERT', al.get('Name'), None, None, None, None, 'DROPPED', 'not used by IMPR1125 code')

# ------------------------------------------------------------------ parameters
PARAMS = {
    'CURRENT_SIDE': (None, None, None, None, 'DROPPED', 'declared but read nowhere in IMPR1125'),
    'P_CURR_PORT_CD': ('APP_ITEM', 'P_CURR_PORT_CD (f345)', None, None, 'MAPPED', 'NE_INTEGRATION setting, SMS port, activity log'),
    'P_USER_ID': ('APP_ITEM', 'SSO_APP_USER (f345)', None, None, 'MAPPED', 'ACTIVITY_DB user'),
    'P_WS_ID': ('APP_ITEM', 'P_GLOBAL_V_WS_ID (f345)', None, None, 'MAPPED', 'ACTIVITY_DB workstation'),
    'P_MODULE_ID': ('ITEM', 'P1125_MODULE_ID', PAGE, None, 'MAPPED', 'FORMS_APX.GET_MODULE_ID'),
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
    'CIC_LIB': ('MAPPED', 'NIB / TMPLT -> f345; STR.DispAlert -> literal texts; HIJDATE -> FORMS_APX / HIJDATE_DB; ACTIVITY -> ACTIVITY_DB; INTRFACE -> date column'),
    'OFGBSL': ('MAPPED', 'CGBS$ master-detail -> native Form + IG'),
    'CIC_AMSG': ('MAPPED', 'Des$Form_errors messages -> FORMS_APX / APP_ERROR_HANDLER'),
    'OFGTEL': ('TODO', 'MISSING SOURCE - constraint messages (CGTE$)'),
}
for lb in fm.findall(NS + 'AttachedLibrary'):
    a = LIBS.get(lb.get('Name'), ('DROPPED', 'not needed in the browser (help, DLL, window, tab, pick list)'))
    add('LIBRARY', lb.get('Name'), None, None, None, None, a[0], a[1])

# ------------------------------------------------------------------ globals
GLOBALS = {'HQ_IMPR_NBR': 'P0_PAGE_PK (process HQ_IMPR_NBR EXECUTE-QUERY / search link)',
           'BUS_NBR': 'P0_PAGE_PK (process BUS_ID EXECUTE-QUERY)', 'BUS_ID': 'P0_PAGE_PK (search page link)'}
code = ' '.join(U(x.get('TriggerText')) for x in fm.iter(NS + 'Trigger')) + ' ' + \
       ' '.join(U(x.get('ProgramUnitText')) for x in fm.iter(NS + 'ProgramUnit'))
code_nc = re.sub(r'--[^\n]*|/\*.*?\*/', ' ', code, flags=re.S)
for g in sorted(set(x.upper() for x in re.findall(r':GLOBAL\.(\w+[$\w]*)', code_nc, re.I))):
    if g in GLOBALS:
        add('GLOBAL', g, 'ITEM', GLOBALS[g], PAGE, None, 'MAPPED', 'no G_ application item needed')
    else:
        add('GLOBAL', g, None, None, None, None, 'DROPPED', 'Designer internal / version stamp / frame - not needed')

# ------------------------------------------------------------------ called forms
add('CALLED_FORM', 'LOV_IMPORT_HQ_NBR', 'PAGE', '112501 IMPR1125_SEARCH', SEARCH, None, 'MAPPED', 'SINGLE_IMP_LOV')
add('CALLED_FORM', 'LOV_DELETE_IMP_SUSP', 'PAGE', '112502 IMPR1125_DELETED_SUSPENSIONS', DELETED, pk('RELEASED_SUSPENSIONS_EXIST'),
    'MAPPED', 'DELETE_SUSPS_LOV (P_HQ_IMPR_NBR -> P112502_P_HQ_IMPR_NBR with checksum)')
add('CALLED_FORM', 'V_CALLED_FORM (dynamic, PU EXECUTE_FUNCTION)', 'REGION', 'FUNCS (page 0, Page Functions list)', 0, None, 'TODO',
    'functions of the module in SC_SYSTEM_OBJECTS unknown (inventory §15 #8)')
add('CALLED_FORM', 'calendar forms (INTRFACE.DISP_CALENDAR / DISP_DATE_CON)', 'IG_COLUMN', 'hijri-date-default date columns', PAGE, None,
    'MAPPED', 'date KEY-LISTVAL / KEY-F4')

# ------------------------------------------------------------------ program units
PU_MAP = {
    'SINGLE_IMP_LOV': ('PAGE', '112501 IMPR1125_SEARCH', SEARCH, 'MAPPED', 'CALL_FORM LOV_IMPORT_HQ_NBR'),
    'DELETE_SUSPS_LOV': ('PAGE', '112502 IMPR1125_DELETED_SUSPENSIONS', DELETED, 'MAPPED', 'CALL_FORM LOV_DELETE_IMP_SUSP'),
}
PU_NOTE = {
    'CG$WHEN_NEW_FORM_INSTANCE': 'lists + block-sync startup -> shared LOVs / native master-detail',
    'CGDV$POPULATE_DYNAMIC_LISTS': 'shared LOVs on CG_REF_CODES',
    'EXECUTE_FUNCTION': 'f345 Page Functions (FUNCS)', 'MOUSE_CLICK': 'f345 Page Functions (FUNCS)',
    'ADJ_FUNS': 'empty in Forms', 'EXEC_FUNS': 'empty in Forms', 'CGTE$CHECK_CONSTRAINT_VIO': 'APP_ERROR_HANDLER',
    'CGUV$CHK_HI_PK': 'not called; HQ_IMPR_NBR_VALIDATION does the same check',
    'CGFK$CHK_IMPR_CNTRL_SUSPNS_ICS': 'not called; foreign key ICS_HI_FK in the database',
}
for p in fm.findall(NS + 'ProgramUnit'):
    n = p.get('Name')
    if n in PU_MAP:
        a = PU_MAP[n]
        add('PROGRAM_UNIT', n, a[0], a[1], a[2], None, a[3], a[4])
    else:
        add('PROGRAM_UNIT', n, None, None, None, None, 'DROPPED',
            PU_NOTE.get(n, 'not called by active code (NIB wrapper / query-mode toggle)'))

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
open('work/IMPR1125/step03/trace.md', 'w', encoding='utf-8').write(trace)


def q(v):
    if v is None or v == '':
        return 'NULL'
    if isinstance(v, int):
        return str(v)
    return "'" + str(v).replace("'", "''") + "'"


reg = ["""-- =============================================================================
-- IMPR1125 - migration registry rows (scripts/create_migration_registry.sql)
-- Purpose : MIG_FORM_REGISTRY row for the form + one MIG_OBJECT_MAP row per Forms object
--           (traceability matrix, analysis/IMPR1125/IMPR1125_apex_page_spec.md section 14)
-- Form    : IMPR1125.fmb (IMPR1125_CENTRAL)
-- Author  : Claude Code
-- Date    : 2026-11-24
-- Version : 1.0 (step 03 revision 1, package IMPR1125 version 001)
-- Generated by work/IMPR1125/step03/build_trace.py - %s
-- app_id 202530 = the application installed from f345. Re-runnable: deletes the form's rows first.
-- NOT executed (CLAUDE.md 6.10).
-- =============================================================================
SET DEFINE OFF

DELETE FROM mig_object_map    WHERE form_name = 'IMPR1125';
DELETE FROM mig_form_registry WHERE form_name = 'IMPR1125';

INSERT INTO mig_form_registry
    (form_name, forms_app, subsystem, app_id, page_from, page_to, page_alias,
     package_name, complexity, status, owner, business_owner, notes)
VALUES
    ('IMPR1125', 'IMPR', 'IMPR', 202530, 1125, 1125, 'IMPR1125',
     'IMPR1125', 'COMPLEX', 'DESIGN', NULL, NULL,
     'صيانة توقيفات المستوردين (المركزية) - step 03 rev 1 page design (pages 1125, 112501, 112502); package IMPR1125 001 not compiled');

DECLARE
    PROCEDURE m (p_type    VARCHAR2, p_name   VARCHAR2, p_comp  VARCHAR2, p_comp_name VARCHAR2,
                 p_page    NUMBER,   p_member VARCHAR2, p_status VARCHAR2, p_notes   VARCHAR2)
    IS
    BEGIN
        INSERT INTO mig_object_map
            (form_name, forms_object_type, forms_object_name, apex_comp_type,
             apex_comp_name, page_id, plsql_member, status, notes)
        VALUES ('IMPR1125', p_type, p_name, p_comp, p_comp_name, p_page, p_member, p_status, p_notes);
    END m;
BEGIN""" % summary]
for r in rows:
    reg.append('    m(%s);' % ', '.join(q(x) for x in r))
reg.append('END;\n/\n\nCOMMIT;\n')
open('registry/IMPR1125_registry.sql', 'w', encoding='utf-8').write('\n'.join(reg))

spec = open('work/IMPR1125/step03/spec_manual.md', encoding='utf-8').read()
assert '<!-- TRACE -->' in spec
open('analysis/IMPR1125/IMPR1125_apex_page_spec.md', 'w', encoding='utf-8').write(spec.replace('<!-- TRACE -->', trace))
print(summary)
print('by type:', by_type)
